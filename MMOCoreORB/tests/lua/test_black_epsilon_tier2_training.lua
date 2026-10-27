-- Prisk Kith'Vys: one-click, free-choice tier 2 training (FP-1, D-2): a topic reply on `training_menu` buys the skill at once and leads into that
-- skill's mission briefing.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-9, AC-5, I-10; Conversation flow 1 (P22) and 3.3; FP-1, FP-2, FP-5; D-2, D-3, D-6, D-12).
--
-- The menu lists one topic reply per missing tier 2 skill, in table order (starships, weapons, procedures, droid). The skill is bought through
-- skillManagerAwardSkill (the XP is charged) in getNextConversationScreen when the chosen link is a trained screen. Guards are tested through hooks,
-- functions between two choices that change the pilot while a screen is shown. The fake charges XP only with H.Engine.config.skillXpCosts, set from
-- fixtures/skill/skills.pilot_imperial_navy_02.tab (60000 each).

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local CS = require("harness.client_strings")

P.load()

local TRAIN = P.TRAIN
local COST = P.TRAINING_COST

local function setUp()
	H.reset()
	P.requireConversation(lu)
	P.useSkillCosts()
end

local function exp(player) return player.ghost.experience.space_combat_general end

-- missions (1..4) of the tier 2 skills in `have` (TRAIN indexes)
local function missionsOf(have)
	local out = {}

	for _, i in ipairs(have) do
		out[#out + 1] = TRAIN[i].mission
	end

	table.sort(out)
	return out
end

-- a pilot with the opening won, the tier 2 skills `have` (TRAIN indexes) with their missions flown and paid, and `xp`
local function pilot(have, xp, extra)
	local o = { opening = "won", t2 = have or {}, paid = missionsOf(have or {}), xp = xp or COST }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return P.pilot(o)
end

local function bought(player)
	local out = {}

	for _, call in ipairs(P.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function free(player)
	local out = {}

	for _, call in ipairs(P.free()) do
		if call[1] == player and call[2]:find("^pilot_imperial_navy_%a+_02$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(bought(player), {}, label .. ": bought grants")
	lu.assertEquals(free(player), {}, label .. ": free grants")
end

-- all proper subsets of the four skills (indexes in table order), the empty one included
local function subsets()
	local out = {}

	for mask = 0, 14 do
		local s = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				s[#s + 1] = i
			end
		end

		out[#out + 1] = s
	end

	return out
end

local function missing(have)
	local held = {}

	for _, i in ipairs(have) do
		held[i] = true
	end

	local out = {}

	for i = 1, 4 do
		if not held[i] then
			out[#out + 1] = i
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2TrainingMenu = {}

TestBlackEpsilonT2TrainingMenu.setUp = setUp

-- AC-9, FP-1: no skill yet, the menu with the four topics
function TestBlackEpsilonT2TrainingMenu:test_a_pilot_with_the_opening_won_and_the_xp_gets_a_menu_of_four_topics()
	local t = P.talk(pilot({}, COST))

	lu.assertEquals(P.ids(t), { "training_menu" }, "screens shown")
	lu.assertEquals(t[1].text, P.PREFIX .. "s_584a90f8", "the menu line")
	lu.assertEquals(P.optionSids(t[1]), { "s_be505897", "s_82fd8660", "s_a872e9f9", "s_9b4e084a" }, "menu replies, in table order")
	lu.assertEquals(P.linksOf(t[1]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid" }, "menu links")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: the menu lists exactly the missing skills, in table order
function TestBlackEpsilonT2TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].trained
		end

		local t = P.talk(pilot(have, COST))

		lu.assertEquals(P.ids(t), { "training_menu" }, label .. ": screens shown")
		lu.assertEquals(P.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertEquals(P.linksOf(t[1]), links, label .. ": menu links")
	end
end

-- AC-9: showing the menu grants nothing
function TestBlackEpsilonT2TrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({}, COST)

	P.talk(player)
	noGrant(player, "menu shown")

	for _, x in ipairs(TRAIN) do
		P.drive(player, x.trained)
		noGrant(player, x.trained .. " displayed alone")
	end

	lu.assertEquals(exp(player), COST, "no XP charged")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2TrainingGrant = {}

TestBlackEpsilonT2TrainingGrant.setUp = setUp

-- AC-9, FP-1, FP-2: the topic buys the skill and shows the after-training line, whose one reply leads into the briefing
for _, x in ipairs(TRAIN) do
	TestBlackEpsilonT2TrainingGrant["test_choosing_" .. x.x .. "_buys_the_skill_charges_the_xp_and_shows_" .. x.trained] = function()
		local player = pilot({}, COST)
		local t = P.talk(player, { x.reply })

		lu.assertEquals(P.ids(t), { "training_menu", x.trained }, "screens shown")
		lu.assertEquals(t[2].text, P.PREFIX .. x.trainedSid, x.trained .. ": the after-training line")
		lu.assertFalse(t[2].stop, x.trained .. " continues into the briefing")
		lu.assertEquals(P.optionSids(t[2]), { x.afterReply }, x.trained .. ": the one reply")
		lu.assertEquals(P.linksOf(t[2]), { x.brief }, x.trained .. ": leads to the briefing")
		lu.assertEquals(bought(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(free(player), {}, "free grants (every tier 2 skill is bought)")
		lu.assertEquals(P.held(player), { x.skill }, "tier 2 skills held")
		lu.assertEquals(exp(player), 0, "space XP after the purchase")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: each skill is charged 60000 whatever is held
function TestBlackEpsilonT2TrainingGrant:test_each_purchase_charges_60000_xp_from_the_pilots_balance()
	for _, have in ipairs({ {}, { 1 }, { 2, 3 }, { 1, 3, 4 } }) do
		for _, i in ipairs(missing(have)) do
			H.reset()
			P.useSkillCosts()

			local player = pilot(have, 150000)
			local t = P.talk(player, { TRAIN[i].reply })

			lu.assertEquals(P.ids(t), { "training_menu", TRAIN[i].trained }, "holding " .. table.concat(have, ",") .. " buying " .. TRAIN[i].x .. ": screens shown")
			lu.assertEquals(bought(player), { TRAIN[i].skill }, "skillManagerAwardSkill calls")
			lu.assertEquals(exp(player), 150000 - COST, "space XP after the purchase")
			lu.assertTrue(CreatureObject(player):hasSkill(TRAIN[i].skill), "the skill is held")
		end
	end
end

-- AC-9, I-10: one reply buys one skill and the briefing follows
function TestBlackEpsilonT2TrainingGrant:test_one_choice_buys_one_skill_and_the_conversation_goes_on_to_that_skills_briefing()
	local player = pilot({}, 3 * COST)
	local t = P.talk(player, { "s_82fd8660", "s_ceafaf0b" })

	lu.assertEquals(P.ids(t), { "training_menu", "trained_weapons", "m14_brief_trained" }, "screens shown")
	lu.assertEquals(bought(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-9: the next talk without accepting the mission opens assignment_waiting, not training
function TestBlackEpsilonT2TrainingGrant:test_leaving_after_the_purchase_opens_assignment_waiting_next_time_and_not_training()
	for _, x in ipairs(TRAIN) do
		H.reset()
		P.useSkillCosts()

		local player = pilot({}, 3 * COST)

		P.talk(player, { x.reply })

		local again = P.talk(player, { "s_6d3be6aa" })

		lu.assertEquals(P.ids(again), { "assignment_waiting", (x.brief:gsub("_trained", "")) }, x.x .. ": the next talk")
		lu.assertEquals(#bought(player), 1, x.x .. ": no second skill bought")
	end
end

-- AC-9, I-10: no second skill while a mission is waiting, whatever the XP; once it is flown and paid the menu lists the other three
function TestBlackEpsilonT2TrainingGrant:test_no_second_skill_is_offered_until_the_bought_skills_mission_is_attempted()
	local player = pilot({}, 5 * COST)

	P.talk(player, { "s_be505897" })
	lu.assertEquals(P.firstScreen(player), "assignment_waiting", "the mission is waiting")
	lu.assertFalse(rawget(_G, P.HANDLER):isReadyForTraining(player), "isReadyForTraining while the mission is waiting")

	-- the mission is accepted, flown and paid
	H.setQuestStatus(player, "corellia_imperial_12:attempted", "1")
	H.setQuestStatus(player, "corellia_imperial_12:reward", "1")
	P.setState(player, P.A12, "complete")

	local t = P.talk(player)

	lu.assertEquals(P.ids(t), { "training_menu" }, "after the mission")
	lu.assertEquals(P.optionSids(t[1]), { "s_82fd8660", "s_a872e9f9", "s_9b4e084a" }, "the other three skills")
end

-- AC-9, D-12: the fourth skill raises the pilot tier 2 to 3, and only then
function TestBlackEpsilonT2TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_2_to_3()
	local player = pilot({ 1, 2, 3 }, COST)

	lu.assertEquals(player.ghost.pilotTier, 2, "precondition: pilot tier 2")
	P.talk(player, { "s_9b4e084a" })
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the fourth skill")
end

-- AC-9
function TestBlackEpsilonT2TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	local player = pilot({ 1, 2 }, COST)

	P.talk(player, { "s_a872e9f9" })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the third skill")
end

-- AC-9: a pilot already at tier 3 keeps it
function TestBlackEpsilonT2TrainingGrant:test_a_pilot_at_tier_3_is_not_raised_again()
	local player = pilot({ 1, 2, 3 }, COST, { pilotTier = 3 })

	P.talk(player, { "s_9b4e084a" })
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
end

-- AC-9: the skills can be taken in any order, one per visit, each mission flown in between
function TestBlackEpsilonT2TrainingGrant:test_the_four_skills_can_be_trained_in_a_reversed_order_over_four_visits()
	local player = pilot({}, 4 * COST)
	local spies = P.spyStarts()

	for step, i in ipairs({ 4, 3, 2, 1 }) do
		local t = P.talk(player, { TRAIN[i].reply })

		lu.assertEquals(t[#t].id, TRAIN[i].trained, "visit " .. step .. ": last screen")

		-- the mission of the skill is flown and paid before the next visit
		local m = TRAIN[i].mission
		local chain = P.CHAINS[m]

		H.setQuestStatus(player, P.STATUS[m] .. ":attempted", "1")
		H.setQuestStatus(player, P.STATUS[m] .. ":reward", "1")

		for _, g in ipairs(chain) do
			P.setState(player, g, "complete")
		end
	end

	lu.assertEquals(bought(player), { TRAIN[4].skill, TRAIN[3].skill, TRAIN[2].skill, TRAIN[1].skill }, "skills bought in the order chosen")
	lu.assertEquals(exp(player), 0, "four prices paid")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the fourth skill")
	lu.assertEquals(P.firstScreen(player), "final_offer", "all four skills and four rewards: the final")
	lu.assertEquals(P.started(spies), {}, "training starts no quest")
end

-- AC-9: with too little XP the pilot is not offered training
function TestBlackEpsilonT2TrainingGrant:test_with_too_little_xp_the_first_screen_is_opening_done()
	for _, have in ipairs(subsets()) do
		H.reset()

		lu.assertEquals(P.firstScreen(pilot(have, COST - 1)), "opening_done", "holding " .. table.concat(have, ",") .. " with 59999 XP")
	end
end

---------------------------------------------------------------------------------------------
-- Guards that fail while the menu is shown (hooks)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2TrainingGuards = {}

TestBlackEpsilonT2TrainingGuards.setUp = setUp

-- AC-9
function TestBlackEpsilonT2TrainingGuards:test_xp_that_is_gone_before_the_choice_buys_nothing_and_the_gates_route_the_pilot()
	local player = pilot({}, COST)
	local t = P.talk(player, { function(p) p.ghost.experience.space_combat_general = 0 end, "s_82fd8660" })

	lu.assertEquals(t[#t].id, "opening_done", "routed by the gates: the opening won, no XP")
	noGrant(player, "xp gone")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
end

-- AC-9
function TestBlackEpsilonT2TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_granted_again()
	local player = pilot({}, COST)
	local t = P.talk(player, { function(p) p.skills[TRAIN[2].skill] = true end, "s_82fd8660" })

	lu.assertEquals(t[#t].id, "assignment_waiting", "routed by the gates: the skill is held and its mission waits")
	noGrant(player, "skill already held")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

-- AC-9, I-10: another skill appearing meanwhile makes its mission ready, so no skill is bought
function TestBlackEpsilonT2TrainingGuards:test_a_mission_that_became_ready_meanwhile_blocks_the_purchase()
	local player = pilot({}, 2 * COST)
	local t = P.talk(player, { function(p) p.skills[TRAIN[1].skill] = true end, "s_82fd8660" })

	lu.assertEquals(t[#t].id, "assignment_waiting", "routed by the gates")
	noGrant(player, "a mission is ready")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the weapons skill is not held")
end

-- AC-9
function TestBlackEpsilonT2TrainingGuards:test_the_opening_taken_away_meanwhile_grants_nothing()
	local player = pilot({}, COST)
	local t = P.talk(player, { function(p) P.setState(p, P.OPENING, "none") end, "s_be505897" })

	lu.assertEquals(t[#t].id, "opening_failed", "routed by the gates: the opening attempted, not won")
	noGrant(player, "opening gone")
end

-- AC-9: a tier 1 skill lost meanwhile
function TestBlackEpsilonT2TrainingGuards:test_a_tier_1_skill_lost_meanwhile_grants_nothing()
	local player = pilot({}, COST)
	local t = P.talk(player, { function(p) p.skills[P.TIER1_SKILLS[1]] = nil end, "s_be505897" })

	lu.assertEquals(t[#t].id, "opening_done", "routed by the gates: three tier 1 skills")
	noGrant(player, "tier 1 skill lost")
end

-- AC-9: the engine refuses the purchase when the prerequisites are not met
function TestBlackEpsilonT2TrainingGuards:test_when_the_engine_refuses_the_purchase_the_pilot_gets_no_trained_screen()
	local real = LuaSkillManager

	LuaSkillManager = function()
		return { fulfillsSkillPrerequisitesAndXp = function() return false end, awardSkill = real().awardSkill }
	end

	local player = pilot({}, COST)
	local ok, t = pcall(P.talk, player, { "s_82fd8660" })

	LuaSkillManager = real
	lu.assertTrue(ok, "talking raised a Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "training_menu", "routed by the gates: still ready for training")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
	lu.assertEquals(bought(player), {}, "no purchase attempted")
end

-- AC-9: a trained screen reached from another screen never buys
function TestBlackEpsilonT2TrainingGuards:test_a_trained_screen_reached_from_another_screen_buys_nothing()
	local player = pilot({}, COST)
	local t = P.drive(player, "trained_starships", { "s_116d8b3b" })

	lu.assertEquals(P.ids(t), { "trained_starships", "m12_brief_trained" }, "the pilot walks on from a trained screen shown alone")
	noGrant(player, "no purchase outside the menu")
end

-- AC-9: the purchase needs no mission waiting; a pilot with a waiting mission never sees the menu
function TestBlackEpsilonT2TrainingGuards:test_the_menu_is_not_reachable_while_a_mission_waits()
	local player = pilot({}, COST, { t2 = { 1 }, paid = {} })

	lu.assertEquals(P.firstScreen(player), "assignment_waiting", "first screen")
end

---------------------------------------------------------------------------------------------
-- Handler rule helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2TrainingRule = {}

TestBlackEpsilonT2TrainingRule.setUp = setUp

-- AC-9
function TestBlackEpsilonT2TrainingRule:test_isReadyForTraining_is_false_with_a_waiting_mission_for_every_skill()
	for i = 1, 4 do
		H.reset()
		P.useSkillCosts()

		lu.assertFalse(rawget(_G, P.HANDLER):isReadyForTraining(pilot({ i }, 2 * COST, { paid = {} })), "holding " .. TRAIN[i].x .. " with its mission unattempted")
	end
end

-- AC-9: free choice means the order of purchase is not fixed (J ties the mission to the skill)
function TestBlackEpsilonT2TrainingRule:test_the_missions_follow_the_skills_not_a_fixed_order()
	local h = rawget(_G, P.HANDLER)

	for i = 1, 4 do
		H.reset()

		lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { i } })), TRAIN[i].mission, TRAIN[i].x .. " -> mission " .. TRAIN[i].mission)
	end

end
