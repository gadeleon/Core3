-- Shamdon Kree: the one-click tier 2 training (free choice), the hand-off to the mission the skill belongs to, and ready_mission.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-8; Conversation flow 2 (C-6, C-7), 4; FS-1, FS-2; D-3, D-4, D-5; I-10; Q1 = A).
--
-- The pilot picks a topic on `training`; the purchase happens when the choice is made (getNextConversationScreen), the trained screen shows the closing line,
-- "Yes, I am." opens that skill's briefing (the mission starts there), "No, not yet." ends on not_yet and the next talk opens ready_mission.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.
-- The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_neutral_02.tab (60000 each).

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local CS = require("harness.client_strings")

M.load()

local TRAIN = M.TRAIN
local REAL_SKILL_MANAGER = LuaSkillManager
local spies

local function setUp()
	H.reset()
	M.requireConversation(lu)
	spies = {}

	for _, g in ipairs(M.questTables()) do
		spies[g] = H.spyOn(rawget(_G, g), "startQuest")
	end

	M.useSkillCosts()
end

local function tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local function exp(player) return player.ghost.experience.space_combat_general end

-- a pilot with the tier 2 skills `have` (indexes into TRAIN) done and paid, and `xp`
local function pilot(have, xp, extra)
	local names, missions = {}, {}

	for _, i in ipairs(have or {}) do
		names[#names + 1] = TRAIN[i].x
		missions[TRAIN[i].mission] = "paid"
	end

	local o = { skills2 = names, missions = missions, xp = xp or 0 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

local function bought(player)
	local out = {}

	for _, call in ipairs(M.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(bought(player), {}, label .. ": bought grants")
	lu.assertEquals(#M.free(), 0, label .. ": free grants")
end

local function startsOf(global) return #spies[global] end

-- all non-empty proper subsets of the four skills (indexes in table order)
local function subsets()
	local out = {}

	for mask = 0, 14 do
		local list = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				list[#list + 1] = i
			end
		end

		out[#out + 1] = list
	end

	return out
end

local function label(list)
	local out = {}

	for i, x in ipairs(list) do
		out[i] = TRAIN[x].x
	end

	return #out == 0 and "none" or table.concat(out, "_")
end

-- the training options a pilot holding `have` is shown, in table order: { reply sids }, { links }
local function missing(have)
	local held = {}

	for _, x in ipairs(have) do
		held[x] = true
	end

	local replies, links = {}, {}

	for i, t in ipairs(TRAIN) do
		if not held[i] then
			replies[#replies + 1] = t.reply
			links[#links + 1] = t.trained
		end
	end

	return replies, links
end

---------------------------------------------------------------------------------------------
-- AC-8: the training screen
---------------------------------------------------------------------------------------------

TestSmugglerT2Training = {}

TestSmugglerT2Training.setUp = setUp
TestSmugglerT2Training.tearDown = tearDown

-- AC-8, C-7: the topics are the missing skills in table order, for every subset of held skills
for _, have in ipairs(subsets()) do
	TestSmugglerT2Training["test_training_lists_exactly_the_missing_skills_in_table_order_holding_" .. label(have)] = function()
		local player = pilot(have, 60000)
		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "training" }, "first screen")

		local replies, links = missing(have)

		lu.assertEquals(M.optionSids(t[1]), replies, "training replies")
		lu.assertEquals(M.linksOf(t[1]), links, "training links")
		noGrant(player, "display of training")
		lu.assertEquals(exp(player), 60000, "XP after the display")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8: the pilot who holds all four is not trained
function TestSmugglerT2Training:test_a_pilot_with_all_four_skills_is_not_shown_the_training()
	lu.assertEquals(M.firstScreen(pilot({ 1, 2, 3, 4 }, 600000)), "bad_news", "all four skills")
end

---------------------------------------------------------------------------------------------
-- AC-8: each topic buys its skill and shows its trained screen
---------------------------------------------------------------------------------------------

for i, t in ipairs(TRAIN) do
	-- AC-8, FS-1, D-5
	TestSmugglerT2Training["test_the_" .. t.x .. "_topic_buys_" .. t.skill .. "_for_60000_xp_and_shows_" .. t.trained] = function()
		local player = pilot({}, 120000)
		local tr = M.talk(player, { t.reply })

		lu.assertEquals(M.ids(tr), { "training", t.trained }, "walk")
		lu.assertEquals(bought(player), { t.skill }, "XP-deducting grants (skillManagerAwardSkill)")
		lu.assertEquals(#M.free(), 0, "free grants")
		lu.assertTrue(CreatureObject(player):hasSkill(t.skill), "the skill is held")
		lu.assertEquals(exp(player), 60000, "XP after the purchase (60000 deducted, fixtures/skill/skills.pilot_neutral_02.tab)")
		lu.assertEquals(M.optionSids(tr[2]), { M.YES, M.NO }, t.trained .. ": Yes / No")
		lu.assertEquals(M.linksOf(tr[2]), { t.brief, "not_yet" }, t.trained .. ": links")
		lu.assertEquals(CS.transcriptUnresolved(tr), {}, "client strings")
	end

	-- AC-8: the closing line (D-5)
	TestSmugglerT2Training["test_the_" .. t.x .. "_closing_line_is_" .. t.closing] = function()
		local tr = M.talk(pilot({}, 60000), { t.reply })

		lu.assertEquals(M.screenRow(t.trained).sid, t.closing, "Appendix A closing line of " .. t.trained)
		lu.assertEquals(tr[2].text, M.PREFIX .. t.closing, "dialog of " .. t.trained)
	end

	-- AC-8: "Yes, I am." opens the briefing of the skill's mission and starts it once
	TestSmugglerT2Training["test_yes_after_" .. t.x .. "_opens_" .. t.brief .. "_and_starts_mission_" .. t.mission .. "_once"] = function()
		local player = pilot({}, 60000)
		local tr = M.talk(player, { t.reply, M.YES })

		lu.assertEquals(M.ids(tr), { "training", t.trained, t.brief }, "walk")
		lu.assertTrue(tr[3].stop, t.brief .. " ends the conversation")
		lu.assertEquals(H.getQuestStatus(player, M.STATUS_NAMES[t.mission] .. ":attempted"), "1", "the :attempted key of mission " .. t.mission)

		for n, head in ipairs(M.HEADS) do
			lu.assertEquals(startsOf(head), n == t.mission and 1 or 0, head .. ":startQuest calls")
		end

		lu.assertEquals(spies[M.HEADS[t.mission]][1].args[1], player, "the quest starts for the pilot")
		lu.assertEquals(CS.transcriptUnresolved(tr), {}, "client strings")
	end

	-- AC-8: "No, not yet." leaves the mission unstarted, the next talk opens ready_mission whose yes leads to the same briefing
	TestSmugglerT2Training["test_no_after_" .. t.x .. "_ends_on_not_yet_and_ready_mission_offers_the_same_briefing"] = function()
		local player = pilot({}, 60000)
		local tr = M.talk(player, { t.reply, M.NO })

		lu.assertEquals(M.ids(tr), { "training", t.trained, "not_yet" }, "walk")
		lu.assertTrue(tr[3].stop, "not_yet ends the conversation")
		lu.assertNil(H.getQuestStatus(player, M.STATUS_NAMES[t.mission] .. ":attempted"), "no :attempted key")

		for _, head in ipairs(M.HEADS) do
			lu.assertEquals(startsOf(head), 0, head .. ":startQuest calls")
		end

		local again = M.talk(player, { "s_5c522568" })

		lu.assertEquals(M.ids(again), { "ready_mission", t.brief }, "the next talk")
		lu.assertEquals(startsOf(M.HEADS[t.mission]), 1, M.HEADS[t.mission] .. ":startQuest calls after the second talk")
		lu.assertEquals(H.getQuestStatus(player, M.STATUS_NAMES[t.mission] .. ":attempted"), "1", "the :attempted key")
	end
end

-- AC-8: the three closing lines for four skills (D-5): two screens share a dialog id
function TestSmugglerT2Training:test_the_closing_lines_follow_d5()
	lu.assertEquals({ TRAIN[1].closing, TRAIN[2].closing, TRAIN[3].closing, TRAIN[4].closing }, { "s_dfd3392c", "s_2fef6afd", "s_d5a42663", "s_d5a42663" }, "closing ids of starships, weapons, procedures, droid")
end

-- AC-8: "Not yet" on ready_mission ends on not_yet
function TestSmugglerT2Training:test_ready_mission_not_yet_ends_on_not_yet_and_starts_nothing()
	local player = M.pilot({ skills2 = { "weapons" } })
	local t = M.talk(player, { "s_f3d46f0b" })

	lu.assertEquals(M.ids(t), { "ready_mission", "not_yet" }, "walk")
	lu.assertTrue(t[2].stop, "not_yet ends the conversation")

	for _, head in ipairs(M.HEADS) do
		lu.assertEquals(startsOf(head), 0, head .. ":startQuest calls")
	end

	lu.assertEquals(M.firstScreen(player), "ready_mission", "still waiting at the next talk")
end

-- AC-8, C-6: with several skills waiting, the link goes to the smallest mission's briefing
function TestSmugglerT2Training:test_ready_mission_links_to_the_briefing_of_the_smallest_waiting_mission()
	local cases = {
		{ { "procedures", "weapons", "droid" }, "m2_brief" },
		{ { "procedures", "weapons" }, "m3_brief" },
		{ { "procedures" }, "m4_brief" },
		{ { "starships", "procedures" }, "m1_brief" },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local t = M.talk(M.pilot({ skills2 = c[1] }))

		lu.assertEquals(t[1].id, "ready_mission", "first screen with " .. table.concat(c[1], ","))
		lu.assertEquals(M.optionSids(t[1]), { "s_5c522568", "s_f3d46f0b" }, "ready_mission replies")
		lu.assertEquals(M.linksOf(t[1]), { c[2], "not_yet" }, "ready_mission links with " .. table.concat(c[1], ","))
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: the guards
---------------------------------------------------------------------------------------------

-- AC-8: a skill the pilot holds by the time the choice is made buys nothing; the next screen is the gate result
function TestSmugglerT2Training:test_choosing_a_skill_the_pilot_now_holds_buys_nothing_and_routes_by_the_gates()
	local player = pilot({}, 60000)
	local t = M.talk(player, {
		function(p) p.skills[TRAIN[1].skill] = true end,
		TRAIN[1].reply,
	})

	lu.assertEquals(M.ids(t), { "training", "ready_mission" }, "a held skill whose mission is unattempted opens ready_mission")
	noGrant(player, "held skill")
	lu.assertEquals(exp(player), 60000, "XP untouched")
end

-- AC-8: too little XP at the moment of the choice buys nothing
function TestSmugglerT2Training:test_choosing_with_too_little_xp_buys_nothing_and_routes_by_the_gates()
	local player = pilot({}, 60000)
	local t = M.talk(player, {
		function(p) p.ghost.experience.space_combat_general = 59999 end,
		TRAIN[2].reply,
	})

	lu.assertEquals(M.ids(t), { "training", "work" }, "59999 XP: the gates open the default work screen")
	noGrant(player, "59999 XP")
	lu.assertEquals(exp(player), 59999, "XP untouched")
end

-- AC-8: the engine refuses the purchase (prerequisites or XP): nothing is granted and the talk routes by the gates
function TestSmugglerT2Training:test_an_engine_refusal_grants_nothing()
	local player = pilot({}, 60000)

	LuaSkillManager = function()
		return { fulfillsSkillPrerequisitesAndXp = function() return false end, awardSkill = function() error("awardSkill must not be called after a refusal") end }
	end

	local t = M.talk(player, { TRAIN[3].reply })

	lu.assertEquals(M.ids(t), { "training", "training" }, "the refusal routes by the gates: still ready for training")
	noGrant(player, "engine refusal")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[3].skill), "the skill is not held")
end

-- AC-8: the engine accepts the check but the grant leaves the skill missing (the XP model)
function TestSmugglerT2Training:test_a_grant_that_leaves_the_skill_missing_shows_no_trained_screen()
	local player = pilot({}, 60000)
	local t = M.talk(player, {
		function(p) H.Engine.config.skillXpCosts = { [TRAIN[4].skill] = 90000 } end, -- the engine's price is above the pilot's XP
		TRAIN[4].reply,
	})

	lu.assertEquals(t[2].id, "training", "routes by the gates, not to trained_droid")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[4].skill), "the skill is not held")
	lu.assertEquals(exp(player), 60000, "XP untouched")
end

-- AC-8: step 2 of the purchase: a skill is now waiting for its mission, so the pilot is not ready for training
function TestSmugglerT2Training:test_a_skill_waiting_for_its_mission_at_the_moment_of_the_choice_blocks_another_purchase()
	local player = pilot({}, 120000)
	local t = M.talk(player, {
		function(p)
			p.skills[TRAIN[2].skill] = true
		end,
		TRAIN[1].reply,
	})

	lu.assertEquals(t[2].id, "ready_mission", "a skill is now waiting for its mission: not another purchase")
	noGrant(player, "waiting mission")
end

---------------------------------------------------------------------------------------------
-- Q1 = A: pilot tier 3 is not set by the fourth purchase
---------------------------------------------------------------------------------------------

-- Q1 = A, D-10: the fourth purchase leaves the pilot tier at 2
function TestSmugglerT2Training:test_the_fourth_purchase_does_not_set_pilot_tier_3()
	local player = pilot({ 1, 2, 3 }, 60000)

	lu.assertEquals(player.ghost.pilotTier, 2, "precondition: pilot tier 2")

	local t = M.talk(player, { TRAIN[4].reply })

	lu.assertEquals(t[2].id, "trained_droid", "the fourth skill is bought")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the fourth purchase (set later, on the bad news)")
	lu.assertEquals(#M.held2(player), 4, "four tier 2 skills held")
end

-- Q1 = A: no purchase changes the tier
function TestSmugglerT2Training:test_no_purchase_changes_the_pilot_tier()
	for i, t in ipairs(TRAIN) do
		H.reset()
		M.useSkillCosts()

		local player = pilot({}, 60000)

		M.talk(player, { t.reply })
		lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after buying " .. t.x)
	end
end

---------------------------------------------------------------------------------------------
-- I-10: order independence over all 24 orders
---------------------------------------------------------------------------------------------

local function permutations(list)
	local out = {}

	local function go(prefix, rest)
		if #rest == 0 then
			out[#out + 1] = prefix
			return
		end

		for i = 1, #rest do
			local p, r = { table.unpack(prefix) }, { table.unpack(rest) }

			p[#p + 1] = table.remove(r, i)
			go(p, r)
		end
	end

	go({}, list)
	return out
end

-- AC-8, I-10, D-4: whatever the order of purchase, each skill leads to its own mission, and the pilot ends a graduate
for _, order in ipairs(permutations({ 1, 2, 3, 4 })) do
	TestSmugglerT2Training["test_buying_in_the_order_" .. label(order) .. "_starts_each_skills_own_mission"] = function()
		local player = pilot({}, 240000)

		local started = {}

		for step, i in ipairs(order) do
			local t = TRAIN[i]
			local tr = M.talk(player, { t.reply, M.YES })

			started[t.mission] = true
			lu.assertEquals(M.ids(tr), { "training", t.trained, t.brief }, "step " .. step .. " (" .. t.x .. ")")

			for n, head in ipairs(M.HEADS) do
				lu.assertEquals(startsOf(head), started[n] and 1 or 0, "step " .. step .. ": " .. head .. ":startQuest calls (only the missions of the skills bought so far)")
			end

			-- the pilot flies and is paid for the mission before the next visit
			M.setMission(player, t.mission, "paid")
		end

		lu.assertEquals(#M.held2(player), 4, "all four skills")
		lu.assertEquals(exp(player), 0, "240000 XP spent")
		lu.assertEquals(M.firstScreen(player), "bad_news", "the graduate")
	end
end
