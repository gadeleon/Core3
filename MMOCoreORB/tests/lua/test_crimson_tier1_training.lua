-- Da'la Socuna: the one-click free-choice training of the four tier 1 skills and the pilot tier 1 -> 2 step.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-9; Conversation flow 2 (C-4) and 3.4; FI-2, FI-7; D-8; I-10).
--
-- The menu lists one topic reply per missing tier 1 skill, in table order (starships, weapons, procedures, droid); there is no "never mind" line. The skill
-- is granted in getNextConversationScreen when the chosen link is a trained screen of training_first / training_more: free when the pilot holds no tier 1
-- skill (awardSkill), bought with the 7500 XP price otherwise (skillManagerAwardSkill). The fourth skill raises the pilot tier from 1 to 2.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown. The fake charges XP only with
-- H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_rebel_navy_01.tab (7500 each).

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

I.load()

local TRAIN = I.TRAIN
local COST = I.TRAINING_COST

local savedSkillManager

local function setUp()
	H.reset()
	I.requireConversation(lu)
	I.useSkillCosts()
	savedSkillManager = rawget(_G, "LuaSkillManager")
end

local function tearDown()
	rawset(_G, "LuaSkillManager", savedSkillManager)
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function boughtBy(player)
	local out = {}

	for _, call in ipairs(I.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function freeBy(player)
	local out = {}

	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2]:find("^pilot_rebel_navy_%a+_01$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(boughtBy(player), {}, label .. ": bought grants")
	lu.assertEquals(freeBy(player), {}, label .. ": free grants")
end

-- the TRAIN indexes not in `have`
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

-- a pilot with mission 4 paid, the tier 1 skills of the TRAIN indexes `have`, the XP
local function pilot(have, xp, extra)
	local o = { paid = 4, skills = {}, xp = xp or 0 }

	for _, i in ipairs(have or {}) do
		o.skills[#o.skills + 1] = TRAIN[i].skill
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

local function screenFor(have) return #have == 0 and "training_first" or "training_more" end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestCrimsonT1TrainingMenu = {}

TestCrimsonT1TrainingMenu.setUp = setUp
TestCrimsonT1TrainingMenu.tearDown = tearDown

-- AC-9: a pilot with no tier 1 skill gets the four topics in table order, whatever the XP
function TestCrimsonT1TrainingMenu:test_a_pilot_with_no_tier_1_skill_gets_training_first_with_the_four_topics_in_table_order()
	local t = I.talk(pilot({}))

	lu.assertEquals(I.ids(t), { "training_first" }, "screens shown")
	lu.assertEquals(t[1].text, I.PREFIX .. I.MENU_FIRST, "the menu line")
	lu.assertEquals(I.optionSids(t[1]), { "s_26970ef", "s_d912490", "s_8c272224", "s_9480f430" }, "menu replies, in table order")
	lu.assertEquals(I.linksOf(t[1]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid" }, "menu links")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(#t[1].options, 4, "no 'never mind' line: the pilot closes the window to leave")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: with 1 to 3 skills and the XP the menu lists exactly the missing ones in table order
function TestCrimsonT1TrainingMenu:test_training_more_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs({ { 1 }, { 2 }, { 3 }, { 4 }, { 1, 2 }, { 3, 4 }, { 2, 4 }, { 1, 3 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
		H.reset()
		I.useSkillCosts()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].screen
		end

		local t = I.talk(pilot(have, COST))

		lu.assertEquals(I.ids(t), { "training_more" }, label .. ": screens shown")
		lu.assertEquals(t[1].text, I.PREFIX .. I.MENU_MORE, label .. ": the menu line")
		lu.assertEquals(I.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertEquals(I.linksOf(t[1]), links, label .. ": menu links")
	end
end

-- AC-9: the first menu shrinks the same way when it is reached with skills held (the menu is rebuilt on display)
function TestCrimsonT1TrainingMenu:test_the_menu_shrinks_as_skills_are_learned_in_both_screens()
	for _, screen in ipairs({ "training_first", "training_more" }) do
		H.reset()

		local t = I.drive(pilot({ 2, 4 }, COST), screen)

		lu.assertEquals(I.optionSids(t[1]), { TRAIN[1].reply, TRAIN[3].reply }, screen .. ": the two missing topics")
	end
end

-- AC-9: with too little XP the pilot is not offered training: duty_missions
function TestCrimsonT1TrainingMenu:test_with_some_skills_and_too_little_xp_the_pilot_opens_duty_missions()
	local player = pilot({ 1 }, COST - 1)
	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "duty_missions" }, "screens shown")
	noGrant(player, "duty_missions")
end

-- AC-9: showing a menu or a trained screen alone grants nothing
function TestCrimsonT1TrainingMenu:test_showing_a_menu_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({ 1, 2 }, COST)

	I.talk(player)
	noGrant(player, "menu shown")

	for _, x in ipairs(TRAIN) do
		I.drive(player, x.screen)
		noGrant(player, x.screen .. " displayed alone")
	end

	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(player.ghost.pilotTier, 1, "the pilot tier is untouched")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestCrimsonT1TrainingGrant = {}

TestCrimsonT1TrainingGrant.setUp = setUp
TestCrimsonT1TrainingGrant.tearDown = tearDown

-- AC-9, FI-2: with no tier 1 skill every topic grants its skill free and shows the trained line
for idx, x in ipairs(TRAIN) do
	TestCrimsonT1TrainingGrant["test_the_first_choice_of_" .. x.x .. "_grants_the_skill_free_and_shows_the_trained_line"] = function()
		local player = pilot({}, 0)
		local t = I.talk(player, { x.reply })

		lu.assertEquals(I.ids(t), { "training_first", x.screen }, "screens shown")
		lu.assertEquals(t[2].text, I.PREFIX .. x.sid, x.screen .. ": the trained line")
		lu.assertTrue(t[2].stop, x.screen .. " ends the conversation")
		lu.assertEquals(freeBy(player), { x.skill }, "awardSkill calls")
		lu.assertEquals(boughtBy(player), {}, "bought grants (the first skill is free)")
		lu.assertEquals(#I.held(player), 1, "tier 1 skills held")
		lu.assertEquals(exp(player), 0, "no XP charged")
		lu.assertEquals(player.ghost.pilotTier, 1, "the pilot tier stays 1 on the first skill")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9, FI-2: with 1 to 3 skills and the XP every missing topic buys its skill, charges 7500 XP and shows the trained line
for idx, x in ipairs(TRAIN) do
	TestCrimsonT1TrainingGrant["test_choosing_" .. x.x .. "_with_two_other_skills_buys_it_charges_the_xp_and_shows_the_trained_line"] = function()
		local others = missing({ idx })
		local have = { others[1], others[2] }
		local player = pilot(have, COST)
		local t = I.talk(player, { x.reply })

		lu.assertEquals(I.ids(t), { "training_more", x.screen }, "screens shown")
		lu.assertEquals(t[2].text, I.PREFIX .. x.sid, "the trained line")
		lu.assertTrue(t[2].stop, x.screen .. " ends the conversation")
		lu.assertEquals(boughtBy(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(freeBy(player), {}, "free grants (only the first skill is free)")
		lu.assertEquals(#I.held(player), 3, "tier 1 skills held")
		lu.assertEquals(exp(player), 0, "space XP after the purchase")
		lu.assertEquals(player.ghost.pilotTier, 1, "the pilot tier stays 1 on the third skill")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: four purchases in a row complete tier 1 in every order of the first picks and raise the pilot tier only on the fourth skill
function TestCrimsonT1TrainingGrant:test_the_four_skills_in_the_menu_order_complete_tier_1_and_raise_the_pilot_tier_only_on_the_fourth()
	local player = pilot({}, 3 * COST)

	for k = 1, 4 do
		local first = k == 1
		local t = I.talk(player, { TRAIN[k].reply })

		lu.assertEquals(t[#t].id, TRAIN[k].screen, "skill " .. k .. ": the trained screen")
		lu.assertEquals(#I.held(player), k, "skill " .. k .. ": skills held")
		lu.assertEquals(player.ghost.pilotTier, k == 4 and 2 or 1, "skill " .. k .. ": the pilot tier")

		if first then
			lu.assertEquals(exp(player), 3 * COST, "the first skill costs nothing")
		end
	end

	lu.assertEquals(freeBy(player), { TRAIN[1].skill }, "the free grant")
	lu.assertEquals(boughtBy(player), { TRAIN[2].skill, TRAIN[3].skill, TRAIN[4].skill }, "the purchases")
	lu.assertEquals(exp(player), 0, "three prices paid")
	lu.assertEquals(I.firstScreen(player), "tier_done", "the next talk opens tier_done")
	lu.assertEquals(player.ghost.pilotTier, 2, "talking again changes nothing")
end

-- AC-9: a pilot who holds one to three skills reaches four the same way, whatever the starting set
function TestCrimsonT1TrainingGrant:test_the_pilot_tier_rises_on_the_fourth_skill_from_any_starting_set()
	for _, have in ipairs({ { 1, 2, 3 }, { 2, 3, 4 }, { 1, 3, 4 }, { 1, 2, 4 } }) do
		H.reset()
		I.useSkillCosts()

		local i = missing(have)[1]
		local player = pilot(have, COST)
		local t = I.talk(player, { TRAIN[i].reply })

		lu.assertEquals(t[#t].id, TRAIN[i].screen, "holding " .. table.concat(have, ",") .. ": the trained screen")
		lu.assertEquals(player.ghost.pilotTier, 2, "holding " .. table.concat(have, ",") .. ": the pilot tier")
		lu.assertEquals(I.firstScreen(player), "tier_done", "holding " .. table.concat(have, ",") .. ": the next talk")
	end
end

-- AC-9: one reply buys one skill
function TestCrimsonT1TrainingGrant:test_one_choice_buys_exactly_one_skill()
	local player = pilot({ 1 }, 3 * COST)

	I.talk(player, { TRAIN[2].reply })
	lu.assertEquals(boughtBy(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-9, I-10: the oracle table. A topic is granted iff mission 4 is paid, tier 1 is not complete, the pilot lacks the skill, and (no tier 1 skill is held
-- or the XP is there). Everything else leaves the pilot as he was and opens his first screen. The pilot tier changes only on the grant that makes the
-- fourth skill, only from 1 to 2.
function TestCrimsonT1TrainingGrant:test_the_grant_follows_the_training_limits_for_every_state()
	local states = {}

	for _, paid in ipairs({ 3, 4 }) do
		for _, have in ipairs({ {}, { 1, 2 }, { 3 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
			for _, xp in ipairs({ 0, COST - 1, COST }) do
				states[#states + 1] = { paid = paid, have = have, xp = xp }
			end
		end
	end

	local granted, refused = 0, 0

	for _, s in ipairs(states) do
		for _, i in ipairs(missing(s.have)) do
			H.reset()
			I.useSkillCosts()

			local expect = s.paid >= 4 and (#s.have == 0 or s.xp >= COST)
			local player = pilot(s.have, s.xp, { paid = s.paid })
			local label = "M4 " .. (s.paid >= 4 and "paid" or "unpaid") .. ", holding " .. table.concat(s.have, ",") .. ", xp " .. s.xp .. ", topic " .. TRAIN[i].x
			local pilotTier = player.ghost.pilotTier
			local firstScreen = LuaConversationScreen(rawget(_G, I.HANDLER):getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE))):getScreenID()
			local t = I.drive(player, screenFor(s.have), { TRAIN[i].reply })

			if expect then
				granted = granted + 1
				lu.assertEquals(t[#t].id, TRAIN[i].screen, label .. ": the trained screen")
				lu.assertEquals(#s.have == 0 and freeBy(player) or boughtBy(player), { TRAIN[i].skill }, label .. ": the skill is granted, free only for the first")
				lu.assertEquals(#s.have == 0 and boughtBy(player) or freeBy(player), {}, label .. ": no grant of the other kind")
				lu.assertEquals(exp(player), #s.have == 0 and s.xp or s.xp - COST, label .. ": XP charged")
				lu.assertEquals(player.ghost.pilotTier, #s.have == 3 and 2 or pilotTier, label .. ": the pilot tier")
			else
				refused = refused + 1
				noGrant(player, label)
				lu.assertEquals(exp(player), s.xp, label .. ": no XP charged")
				lu.assertEquals(#I.held(player), #s.have, label .. ": tier 1 skills held")
				lu.assertNotEquals(t[#t].id, TRAIN[i].screen, label .. ": the trained screen is not shown")
				lu.assertEquals(t[#t].id, firstScreen, label .. ": the pilot's first screen follows")
				lu.assertEquals(player.ghost.pilotTier, pilotTier, label .. ": the pilot tier is unchanged")
			end
		end
	end

	lu.assertTrue(granted > 0 and refused > 0, "the table covers grants (" .. granted .. ") and refusals (" .. refused .. ")")
end

-- I-10: the pilot tier changes only from 1 to 2
function TestCrimsonT1TrainingGrant:test_the_pilot_tier_is_raised_only_from_1_to_2()
	for _, tier in ipairs({ 0, 2, 3, 4 }) do
		H.reset()
		I.useSkillCosts()

		local player = pilot({ 1, 2, 3 }, COST, { pilotTier = tier })

		I.drive(player, "training_more", { TRAIN[4].reply })
		lu.assertEquals(boughtBy(player), { TRAIN[4].skill }, "pilot tier " .. tier .. ": the skill is bought")
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. ": unchanged by the fourth skill")
	end
end

-- AC-9: a guard that fails while the menu is shown grants nothing and is routed by the gate table
function TestCrimsonT1TrainingGrant:test_losing_the_xp_while_the_menu_is_shown_grants_nothing_and_opens_duty_missions()
	local player = pilot({ 1, 2 }, COST)
	local t = I.talk(player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, TRAIN[3].reply })

	noGrant(player, "xp lost")
	lu.assertEquals(exp(player), COST - 1, "no XP charged")
	lu.assertEquals(t[#t].id, "duty_missions", "routed by G: too little XP")
end

-- AC-9: the mission 4 reward key vanishes while the menu is shown: the pilot is no longer ready, nothing is granted, the gate table decides
function TestCrimsonT1TrainingGrant:test_losing_the_mission_4_reward_while_the_menu_is_shown_grants_nothing()
	local player = pilot({}, 0)
	local t = I.talk(player, { function(p) removeQuestStatus(p.objectID .. "tatooine_rebel_4:reward") end, TRAIN[1].reply })

	noGrant(player, "reward key gone")
	lu.assertEquals(#I.held(player), 0, "no tier 1 skill held")
	lu.assertEquals(t[#t].id, "mission4_report", "routed by G: mission 4 won and unpaid (mission4_report)")
end

-- AC-9: the engine refuses (prerequisites or XP): nothing is granted and no trained line is shown
function TestCrimsonT1TrainingGrant:test_an_engine_refusal_grants_nothing_and_shows_no_trained_screen()
	local player = pilot({ 1, 2 }, COST)
	local t = I.talk(player, { function()
		rawset(_G, "LuaSkillManager", function()
			return {
				fulfillsSkillPrerequisitesAndXp = function() return false end,
				awardSkill = function() error("awardSkill must not be called when the engine refuses") end,
			}
		end)
	end, TRAIN[3].reply })

	noGrant(player, "engine refusal")
	lu.assertEquals(#I.held(player), 2, "no new tier 1 skill held")
	lu.assertNotEquals(t[#t].id, TRAIN[3].screen, "the trained screen is not shown")
	lu.assertEquals(player.ghost.pilotTier, 1, "the pilot tier is unchanged")
end

-- AC-9: a skill already held is not granted again (the menu is stale)
function TestCrimsonT1TrainingGrant:test_a_skill_that_becomes_held_while_the_menu_is_shown_is_not_granted_again()
	local player = pilot({ 1, 2 }, COST)
	local t = I.talk(player, { function(p) p.skills[TRAIN[3].skill] = true end, TRAIN[3].reply })

	lu.assertEquals(boughtBy(player), {}, "nothing is bought for a skill the pilot already holds")
	lu.assertEquals(freeBy(player), {}, "nothing is granted free")
	lu.assertEquals(exp(player), COST, "no price paid")
	lu.assertNotNil(t[#t].id, "a screen follows")
end

-- AC-9: the free first grant is a plain awardSkill, never the XP-deducting manager
function TestCrimsonT1TrainingGrant:test_the_free_first_grant_does_not_touch_the_xp_manager()
	rawset(_G, "LuaSkillManager", function() error("the free first skill must not go through LuaSkillManager") end)

	local player = pilot({}, 0)

	I.talk(player, { TRAIN[3].reply })
	lu.assertEquals(freeBy(player), { TRAIN[3].skill }, "the first skill is an awardSkill")
end

