-- Admiral Imler (RSF tier 4): the pilot chooses which missing tier 4 skill to train (pre-NGE free choice).
-- Spec: .claude/work/pilot-training-free-choice/01-spec.md (AC-8; Content contract 3; invariants I-2 .. I-5; D-2, D-5, D-10).
--
-- space-convo-client-strings-imler-a (.claude/work/space-convo-client-strings-imler-a/01-spec.md, Appendix C; D-3, D-4, D-6, D-14): the 23 tests listed there are updated.
-- The choice replies are Imler's own "Teach me about ..." lines (they replace Turoldine's, D-10 of the earlier spec), and training is one click: the reply buys the skill when
-- chosen (the handler tells the skill by the reply text on the live screen) and lands on mission<k>_brief (k = the tier 4 skill count after the grant), which sets the ready flag.
-- The train_<x> prompts and their buy replies are gone, so a guard hook goes BEFORE the reply sid (it runs once ready_train is shown). The replies are copied from the spec into
-- pilot_training_free_choice_data.lua. The mission table and the pilot builder come from rsf_tier4_data.lua. The fake charges XP only with H.Engine.config.skillXpCosts set (see costs()); the
-- tier 4 threshold of SpaceHelpers:hasExperienceForTraining (1000000) is the cost, as no tier 4 skills.tab excerpt is in the fixtures.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier4_data")
local C = require("pilot_training_free_choice_data")

H.loadSquadron("RsfSquadronScreenplay")
H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua")
H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua")

local CHOICES = C.IMLER
local COST = 1000000
local REAL_SKILL_MANAGER = LuaSkillManager

local function costs()
	local out = {}

	for _, c in ipairs(CHOICES) do
		out[c.skill] = COST
	end

	H.Engine.config.skillXpCosts = out
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function converse(player, choices)
	return H.converse({ template = "imler_convo_template", player = player, npc = H.newNpc({ name = "Admiral Diness Imler" }), choices = choices })
end

-- skill names ("starships") of a list of skill ids
local function names(held)
	local out = {}

	for i, skill in ipairs(held) do
		out[i] = skill:match("^pilot_neutral_(%a+)_04$")
	end

	return out
end

-- A met pilot who won and was paid missions 1..#held, holds `held` (skill ids) and has `amount` space XP: ready_train is the first screen
local function trainee(held, amount)
	local n = #held
	local rewards, attempted, completed = {}, {}, {}

	for i = 1, n do
		rewards[i] = i
		attempted[i] = i
		completed[i] = D.MISSION[i].wins[1]
	end

	return D.rsf({ tier4 = names(held), rewards = rewards, attempted = attempted, completed = completed, xp = amount or 2 * COST, met = true })
end

-- Missions 1..n won and paid (state a real run of the missions leaves behind)
local function finishMission(player, n)
	removeQuestStatus(player.objectID .. D.READY_SUFFIX)
	H.setQuestStatus(player, D.MISSION[n].statusName .. ":attempted", 1)
	H.setQuestStatus(player, D.MISSION[n].statusName .. ":reward", 1)

	local key = D.MISSION[n].wins[1]

	player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
end

---------------------------------------------------------------------------------------------
-- AC-8: the choice
---------------------------------------------------------------------------------------------

TestImlerFreeChoice = {}

function TestImlerFreeChoice:setUp() H.reset() end
function TestImlerFreeChoice:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-8: the template carries no static option and keeps its line and animation
function TestImlerFreeChoice:test_the_static_ready_train_screen_has_no_options_and_keeps_its_line_and_animation()
	local screen

	for _, s in ipairs(H.conversationTemplateTable("imler_convo_template").screens) do
		if s.id == "ready_train" then
			screen = s
		end
	end

	lu.assertNotNil(screen, "imler_convo_template: screen ready_train")
	lu.assertEquals(screen.options, {}, "ready_train: static options")
	lu.assertEquals(screen.leftDialog, D.PREFIX .. "s_d91c04b2", "ready_train: leftDialog")
	lu.assertEquals(screen.animation, "check_wrist_device", "ready_train: animation")
end

-- AC-8, I-2: each proper subset
for _, held in ipairs(C.properSubsets(CHOICES)) do
	TestImlerFreeChoice["test_ready_train_offers_exactly_the_choice_replies_of_the_missing_skills_in_order_when_holding_" .. C.label(held):gsub("[^%w]+", "_")] = function()
		costs()

		local player = trainee(held)
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, "ready_train", C.label(held) .. ": first screen")
		lu.assertEquals(transcript[1].text, D.PREFIX .. "s_d91c04b2", C.label(held) .. ": NPC line")
		lu.assertFalse(transcript[1].stop, C.label(held) .. ": ready_train does not end the conversation")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, C.set(held)), C.label(held) .. ": options (reply, link)")
		lu.assertEquals(#transcript[1].options, 4 - #held, C.label(held) .. ": number of options")

		-- I-5: nothing is granted, paid, started or written while it is shown
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, C.label(held) .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, C.label(held) .. ": awardSkill calls")
		lu.assertEquals(exp(player), 2 * COST, C.label(held) .. ": space_combat_general")
		lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), C.label(held) .. ": readyForTier4Mission")
	end
end

-- AC-8: the retired reply is never offered and a held skill is never offered
function TestImlerFreeChoice:test_the_retired_single_reply_s_438_is_never_offered()
	for _, held in ipairs(C.properSubsets(CHOICES)) do
		for _, o in ipairs(converse(trainee(held))[1].options) do
			lu.assertNotEquals(o.text, D.PREFIX .. "s_438", C.label(held) .. ": the fixed-order reply")
		end
	end
end

-- AC-8: every reply buys its skill once and lands on the brief of the new skill count (one click: there is no prompt or buy reply any more)
function TestImlerFreeChoice:test_every_reply_buys_its_skill_once_and_lands_on_the_brief_of_the_new_count()
	for _, c in ipairs(CHOICES) do
		H.reset()
		costs()

		local player = trainee({})
		local transcript = converse(player, { c.sid })

		lu.assertEquals(ids(transcript), { "ready_train", "mission1_brief" }, c.x .. ": screens")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, c.x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[1][2], c.skill, c.x .. ": skill bought")
		lu.assertEquals(exp(player), COST, c.x .. ": XP after one purchase")
	end
end

-- AC-8, I-3, I-4: for every missing skill and every proper subset the other skills could be, the pick buys that skill once and shows the brief of the new skill count
for _, c in ipairs(CHOICES) do
	TestImlerFreeChoice["test_picking_" .. c.x .. "_04_buys_it_once_through_the_xp_deducting_grant_and_shows_the_brief_of_the_skill_count_whatever_else_is_held"] = function()
		for mask = 0, 7 do
			H.reset()
			costs()

			local held = {}

			for i, other in ipairs(CHOICES) do
				if other.x ~= c.x and mask & (1 << (i - 1)) ~= 0 then
					held[#held + 1] = other.skill
				end
			end

			if #held <= 3 then
				local player = trainee(held)
				local count = #held + 1
				local transcript = converse(player, { c.sid })
				local label = c.x .. " holding " .. C.label(held)

				lu.assertEquals(ids(transcript), { "ready_train", "mission" .. count .. "_brief" }, label .. ": screens (K = skill count after the purchase)")

				local paid = H.Engine.callsTo("skillManagerAwardSkill")

				lu.assertEquals(#paid, 1, label .. ": skillManagerAwardSkill calls")
				lu.assertTrue(paid[1][1] == player, label .. ": skillManagerAwardSkill player")
				lu.assertEquals(paid[1][2], c.skill, label .. ": skill bought")
				lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, label .. ": awardSkill (free grant) calls")
				lu.assertEquals(exp(player), COST, label .. ": space_combat_general after one purchase")
				lu.assertTrue(CreatureObject(player):hasSkill(c.skill), label .. ": " .. c.skill .. " held")
				lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", label .. ": readyForTier4Mission")
			end
		end
	end
end

-- AC-8: the fourth skill raises the pilot tier 4 -> 5, whichever skill it is
function TestImlerFreeChoice:test_the_fourth_skill_raises_the_pilot_tier_to_5_whichever_skill_it_is()
	for _, last in ipairs(CHOICES) do
		H.reset()
		costs()

		local held = {}

		for _, c in ipairs(CHOICES) do
			if c.x ~= last.x then
				held[#held + 1] = c.skill
			end
		end

		local player = trainee(held)

		lu.assertEquals(player.ghost:getPilotTier(), 4, last.x .. ": setup, pilot tier")
		converse(player, { last.sid })
		lu.assertEquals(player.ghost:getPilotTier(), 5, last.x .. ": pilot tier after the fourth tier 4 skill")
	end
end

-- AC-8: the guards hold for a pick that is not the first missing skill (the hook runs once ready_train is shown, before the click)
function TestImlerFreeChoice:test_the_guards_hold_for_a_droid_first_pick()
	local droid = CHOICES[4]

	-- the skill arrives while ready_train is shown
	costs()

	local player = trainee({})
	local transcript = converse(player, { function(p) p.skills[droid.skill] = true end, droid.sid })

	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "skill already held: skillManagerAwardSkill calls")
	lu.assertEquals(transcript[#transcript].id, "mission1_brief", "skill already held: the screen follows the count")
	lu.assertEquals(exp(player), 2 * COST, "skill already held: XP")

	-- the XP is gone at the moment of buying
	H.reset()
	costs()
	player = trainee({}, COST)
	transcript = converse(player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, droid.sid })
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP gone: skillManagerAwardSkill calls")
	lu.assertFalse(CreatureObject(player):hasSkill(droid.skill), "XP gone: droid held")
	lu.assertEquals(transcript[#transcript].id, "mission1_brief", "XP gone: the screen follows the unchanged count")
end

---------------------------------------------------------------------------------------------
-- AC-8: a droid-first career
---------------------------------------------------------------------------------------------

TestImlerFreeChoiceCareer = {}

function TestImlerFreeChoiceCareer:setUp() H.reset() end
function TestImlerFreeChoiceCareer:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-8
function TestImlerFreeChoiceCareer:test_picking_the_last_reply_every_visit_walks_mission_1_to_4_briefs_in_order_and_raises_the_tier_with_the_fourth_skill()
	costs()

	local player = trainee({}, 4 * COST)
	local order = { 4, 3, 2, 1 } -- droid, procedures, weapons, starships

	for k, idx in ipairs(order) do
		local pick = CHOICES[idx]
		local greeting = converse(player)

		lu.assertEquals(greeting[1].id, "ready_train", "visit " .. k .. ": first screen")
		lu.assertEquals(greeting[1].options[#greeting[1].options].text, pick.reply, "visit " .. k .. ": the last reply offered")
		lu.assertEquals(#greeting[1].options, 5 - k, "visit " .. k .. ": number of replies offered")

		local before = #H.Engine.callsTo("skillManagerAwardSkill")
		local transcript = converse(player, { pick.sid })

		lu.assertEquals(ids(transcript), { "ready_train", "mission" .. k .. "_brief" }, "visit " .. k .. ": screens")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill") - before, 1, "visit " .. k .. ": skills bought")
		lu.assertEquals(H.Engine.callsTo("skillManagerAwardSkill")[before + 1][2], pick.skill, "visit " .. k .. ": skill bought")
		lu.assertEquals(exp(player), (4 - k) * COST, "visit " .. k .. ": space_combat_general")
		lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", "visit " .. k .. ": readyForTier4Mission")
		lu.assertEquals(converse(player)[1].id, "ready_mission", "visit " .. k .. ": the next talk starts on ready_mission")

		finishMission(player, k)
	end

	lu.assertEquals(player.ghost:getPilotTier(), 5, "pilot tier after the fourth skill")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 4, "total skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "total awardSkill calls")

	for _, c in ipairs(CHOICES) do
		lu.assertTrue(CreatureObject(player):hasSkill(c.skill), c.skill .. " held")
	end
end
