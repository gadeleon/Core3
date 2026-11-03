-- Dravis: the one-click tier 1 training (free choice), the pilot tier 2 step and the hand-off to Talon Karrde.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-9, AC-10, AC-5; Conversation flow 3.4; FS-3, FS-5; D-10; R-3).
--
-- The pilot picks a topic on first_training (free) or more_training (bought); the topic grants at once and shows its closing line, which ends the talk.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.
-- The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_neutral_01.tab (7500 each).

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

S.load()

local TRAIN = S.TRAIN
local REAL_SKILL_MANAGER = LuaSkillManager

local function setUp()
	H.reset()
	S.requireConversation(lu)
end

local function tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local function exp(player) return player.ghost.experience.space_combat_general end

local function skillsOf(list)
	local out = {}

	for i, x in ipairs(list) do
		out[i] = TRAIN[x].skill
	end

	return out
end

-- a pilot with mission 4 paid, the tier 1 skills `have` (indexes into TRAIN) and `xp`
local function pilot(have, xp, extra)
	local o = { paid = 4, skills = skillsOf(have or {}), xp = xp or 0 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return S.pilot(o)
end

local function grantedFree(player)
	local out = {}

	for _, call in ipairs(S.free()) do
		if call[1] == player and call[2]:find("^pilot_neutral_%a+_01$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function grantedBought(player)
	local out = {}

	for _, call in ipairs(S.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(grantedFree(player), {}, label .. ": free grants")
	lu.assertEquals(grantedBought(player), {}, label .. ": bought grants")
end

-- all non-empty proper subsets of the four skills (indexes in table order)
local function subsets()
	local out = {}

	for mask = 1, 14 do
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

	return table.concat(out, "_")
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
-- AC-9: first_training
---------------------------------------------------------------------------------------------

TestSmugglerT1FirstTraining = {}

TestSmugglerT1FirstTraining.setUp = setUp
TestSmugglerT1FirstTraining.tearDown = tearDown

-- AC-9: the four topics in table order, nothing granted on display
function TestSmugglerT1FirstTraining:test_first_training_lists_exactly_the_four_topics_in_table_order_and_grants_nothing_by_itself()
	local player = pilot({})
	local t = S.talk(player)

	lu.assertEquals(S.ids(t), { "first_training" }, "first screen")
	lu.assertEquals(t[1].text, S.PREFIX .. "s_605d90db", "the NPC line")
	lu.assertEquals(S.optionSids(t[1]), { "s_3818dc2a", "s_3fa70900", "s_7d57477f", "s_9480f430" }, "topics")
	lu.assertEquals(S.linksOf(t[1]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid" }, "links")
	lu.assertFalse(t[1].stop, "first_training waits for the choice")
	noGrant(player, "on display")
	lu.assertEquals(#S.held(player), 0, "tier 1 skills held")
end

-- AC-9: each topic grants its skill free and shows its own closing line
for i, tr in ipairs(TRAIN) do
	TestSmugglerT1FirstTraining["test_the_" .. tr.x .. "_topic_grants_" .. tr.skill .. "_free_and_shows_its_closing_line"] = function()
		local player = pilot({})
		local t = S.talk(player, { tr.reply })

		lu.assertEquals(S.ids(t), { "first_training", tr.trained }, "screens shown")
		lu.assertEquals(t[2].text, S.PREFIX .. tr.closing, tr.trained .. ": the pre-NGE closing line")
		lu.assertTrue(t[2].stop, tr.trained .. " ends the conversation")
		lu.assertEquals(grantedFree(player), { tr.skill }, "free grants (awardSkill)")
		lu.assertEquals(grantedBought(player), {}, "bought grants")
		lu.assertEquals(S.held(player), { tr.skill }, "tier 1 skills held")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: the first skill is free whatever the XP
function TestSmugglerT1FirstTraining:test_the_first_skill_costs_no_experience()
	S.useSkillCosts()

	local player = pilot({}, 100)

	S.talk(player, { TRAIN[2].reply })
	lu.assertEquals(exp(player), 100, "space_combat_general untouched")
	lu.assertEquals(grantedFree(player), { TRAIN[2].skill }, "free grant")
end

-- AC-9: the next visit after the first skill
function TestSmugglerT1FirstTraining:test_after_the_first_skill_the_next_visit_depends_on_the_experience()
	local rich, poor = pilot({}, 7500), pilot({}, 0)

	S.talk(rich, { TRAIN[1].reply })
	S.talk(poor, { TRAIN[1].reply })
	lu.assertEquals(S.firstScreen(rich), "more_training", "one skill, 7500 XP")
	lu.assertEquals(S.firstScreen(poor), "duty_missions", "one skill, no XP")
end

-- AC-9: a skill gained while the menu is shown is not granted twice, and the talk is routed by the gates
function TestSmugglerT1FirstTraining:test_a_guard_that_fails_while_the_menu_is_shown_grants_nothing_and_routes_by_the_gates()
	local player = pilot({})
	local t = S.talk(player, {
		function(p) awardSkill(p, TRAIN[1].skill) end, -- the pilot gets a tier 1 skill elsewhere while the menu is shown
		TRAIN[2].reply,
	})

	lu.assertEquals(S.ids(t), { "first_training", "duty_missions" }, "no trained_x: the gates decide (one skill, no XP)")
	lu.assertEquals(grantedFree(player), { TRAIN[1].skill }, "only the hook's grant: nothing more was granted")
	lu.assertEquals(grantedBought(player), {}, "nothing bought")
end

-- AC-9: the same, with the XP to spare
function TestSmugglerT1FirstTraining:test_the_gates_route_to_more_training_when_the_pilot_has_the_experience()
	local player = pilot({}, 7500)
	local t = S.talk(player, {
		function(p) awardSkill(p, TRAIN[1].skill) end,
		TRAIN[2].reply,
	})

	lu.assertEquals(S.ids(t), { "first_training", "more_training" }, "the gates decide (one skill, 7500 XP)")
	lu.assertEquals(grantedBought(player), {}, "nothing bought on the way")
end

-- AC-9: the pilot who picks the first reply grants only that one skill, whichever reply
function TestSmugglerT1FirstTraining:test_one_click_grants_exactly_one_skill()
	for i, tr in ipairs(TRAIN) do
		H.reset()

		local player = pilot({}, 99999)

		S.talk(player, { tr.reply })
		lu.assertEquals(#S.held(player), 1, tr.x .. ": one skill held after one click")
		lu.assertEquals(#S.free() + #S.bought() >= 1, true, tr.x .. ": a grant call")
		lu.assertEquals(#grantedFree(player) + #grantedBought(player), 1, tr.x .. ": exactly one tier 1 grant")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: more_training
---------------------------------------------------------------------------------------------

TestSmugglerT1MoreTraining = {}

TestSmugglerT1MoreTraining.setUp = setUp
TestSmugglerT1MoreTraining.tearDown = tearDown

-- AC-9: the 14 subsets of 1 to 3 skills (and the 4 single-skill complements)
for _, list in ipairs(subsets()) do
	if #list <= 3 then
		TestSmugglerT1MoreTraining["test_more_training_for_a_pilot_holding_" .. label(list) .. "_lists_exactly_the_missing_skills_in_table_order"] = function()
			S.useSkillCosts()

			local player = pilot(list, 7500 * 3)
			local t = S.talk(player)
			local replies, links = missing(list)

			lu.assertEquals(t[1].id, "more_training", "first screen")
			lu.assertEquals(t[1].text, S.PREFIX .. "s_ae220ebc", "more_training: NPC line")
			lu.assertFalse(t[1].stop, "more_training waits for the choice")
			lu.assertEquals(S.optionSids(t[1]), replies, "more_training: topics")
			lu.assertEquals(S.linksOf(t[1]), links, "more_training: links")
			noGrant(player, "on display")
			lu.assertEquals(exp(player), 7500 * 3, "space_combat_general untouched on display")
		end
	end
end

-- AC-9: the choice buys the skill through the XP-deducting grant
for i, tr in ipairs(TRAIN) do
	TestSmugglerT1MoreTraining["test_choosing_" .. tr.x .. "_buys_it_with_the_tier_1_price_and_shows_its_closing_line"] = function()
		S.useSkillCosts()

		local have = { 1, 2, 3, 4 }

		table.remove(have, i)

		-- hold two others, so the purchase does not complete the tier
		local others = {}

		for _, x in ipairs(have) do
			if #others < 2 then
				others[#others + 1] = x
			end
		end

		local player = pilot(others, 7500 + 123)
		local t = S.talk(player, { tr.reply })

		lu.assertEquals(S.ids(t), { "more_training", tr.trained }, "screens shown")
		lu.assertEquals(t[2].text, S.PREFIX .. tr.closing, tr.trained .. ": the pre-NGE closing line")
		lu.assertTrue(t[2].stop, tr.trained .. " ends the conversation")
		lu.assertEquals(grantedBought(player), { tr.skill }, "bought grants (skillManagerAwardSkill)")
		lu.assertEquals(grantedFree(player), {}, "free grants")
		lu.assertEquals(exp(player), 123, "space_combat_general after the 7500 XP price")
		lu.assertTrue(CreatureObject(player):hasSkill(tr.skill), "the skill is held")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: too little XP: the gates say duty_missions, no purchase is offered
function TestSmugglerT1MoreTraining:test_with_too_little_experience_the_pilot_opens_duty_missions_and_nothing_is_offered()
	S.useSkillCosts()

	local player = pilot({ 1 }, 7499)
	local t = S.talk(player)

	lu.assertEquals(S.ids(t), { "duty_missions" }, "first screen")
	noGrant(player, "no training")
end

-- AC-9: the guard: the experience is gone while the menu is shown
function TestSmugglerT1MoreTraining:test_experience_spent_while_the_menu_is_shown_grants_nothing_and_routes_by_the_gates()
	S.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = S.talk(player, {
		function(p) p.ghost.experience.space_combat_general = 0 end,
		TRAIN[2].reply,
	})

	lu.assertEquals(S.ids(t), { "more_training", "duty_missions" }, "no trained_x: the gates decide (one skill, no XP)")
	noGrant(player, "after the hook")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the weapons skill is not held")
end

-- AC-9: the skill was gained while the menu is shown
function TestSmugglerT1MoreTraining:test_a_skill_gained_while_the_menu_is_shown_is_not_bought_again()
	S.useSkillCosts()

	local player = pilot({ 1 }, 7500 * 2)
	local t = S.talk(player, {
		function(p) awardSkill(p, TRAIN[2].skill) end,
		TRAIN[2].reply,
	})

	lu.assertEquals(t[#t].id ~= TRAIN[2].trained, true, "no trained_weapons: the pilot already holds it")
	lu.assertEquals(grantedBought(player), {}, "not bought")
	lu.assertEquals(exp(player), 7500 * 2, "no XP charged")
end

-- AC-9: the engine refuses (prerequisites or XP): nothing is granted and the pilot is routed by the gates
function TestSmugglerT1MoreTraining:test_an_engine_refusal_grants_nothing_and_shows_no_closing_line()
	LuaSkillManager = function()
		local real = REAL_SKILL_MANAGER()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = real })
	end

	local player = pilot({ 1 }, 7500)
	local t = S.talk(player, { TRAIN[2].reply })

	lu.assertEquals(t[#t].id ~= TRAIN[2].trained, true, "no trained_weapons")
	noGrant(player, "refused")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the weapons skill is not held")
end

-- AC-9: the fourth skill raises the pilot tier 1 -> 2, the third does not
function TestSmugglerT1MoreTraining:test_the_fourth_skill_raises_the_pilot_tier_to_2_and_the_third_does_not()
	S.useSkillCosts()

	local third = pilot({ 1, 2 }, 7500, { pilotTier = 1 })

	S.talk(third, { TRAIN[3].reply })
	lu.assertEquals(#S.held(third), 3, "three skills")
	lu.assertEquals(third.ghost.pilotTier, 1, "the third skill leaves the pilot tier at 1")

	H.reset()
	S.useSkillCosts()

	local fourth = pilot({ 1, 2, 3 }, 7500, { pilotTier = 1 })
	local t = S.talk(fourth, { TRAIN[4].reply })

	lu.assertEquals(S.ids(t), { "more_training", "trained_droid" }, "screens shown")
	lu.assertEquals(#S.held(fourth), 4, "four skills")
	lu.assertEquals(fourth.ghost.pilotTier, 2, "the fourth skill raises the pilot tier from 1 to 2")
end

-- AC-9: the tier is raised only from 1
function TestSmugglerT1MoreTraining:test_the_fourth_skill_does_not_touch_a_pilot_tier_other_than_1()
	S.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500, { pilotTier = 3 })

	S.talk(player, { TRAIN[4].reply })
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier stays 3")
end

-- AC-9: the order of the skills does not matter: buying in any order ends in tier 2
function TestSmugglerT1MoreTraining:test_buying_the_four_skills_in_any_order_ends_with_pilot_tier_2()
	S.useSkillCosts()

	local orders = { { 4, 3, 2, 1 }, { 2, 4, 1, 3 } }

	for _, order in ipairs(orders) do
		H.reset()
		S.useSkillCosts()

		local player = pilot({}, 7500 * 4, { pilotTier = 1 })

		S.talk(player, { TRAIN[order[1]].reply })

		for k = 2, 4 do
			S.talk(player, { TRAIN[order[k]].reply })
		end

		lu.assertEquals(#S.held(player), 4, table.concat(order, ",") .. ": four skills")
		lu.assertEquals(player.ghost.pilotTier, 2, table.concat(order, ",") .. ": pilot tier")
		lu.assertEquals(exp(player), 7500, table.concat(order, ",") .. ": three purchases of 7500, the first one free")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: tier done
---------------------------------------------------------------------------------------------

TestSmugglerT1TierDone = {}

TestSmugglerT1TierDone.setUp = setUp

local WALK = { "s_8467c710", "s_9fdd7cf3", "s_370822d1" }

-- AC-10: the pilot with all four skills and mission 4 paid opens tier_done and walks to the hand-off
function TestSmugglerT1TierDone:test_the_walk_reaches_the_karrde_hand_off_and_ends()
	local player = pilot({ 1, 2, 3, 4 }, 0, { pilotTier = 1 })
	local t = S.talk(player, WALK)

	lu.assertEquals(S.ids(t), { "tier_done", "tier_done_oh_and", "tier_done_hyperdrive", "tier_done_talk" }, "screens shown")
	lu.assertEquals(t[1].text, S.PREFIX .. "s_be1beb37", "tier_done: the Karrde line")
	lu.assertEquals(t[4].text, S.PREFIX .. "s_d3d66c68", "tier_done_talk: Now talk to Talon Karrde.")
	lu.assertTrue(t[4].stop, "tier_done_talk ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10 (D-10): tier_done sets pilot tier 2 if it was 1
function TestSmugglerT1TierDone:test_tier_done_raises_pilot_tier_1_to_2_and_leaves_other_tiers_alone()
	for from, to in pairs({ [1] = 2, [0] = 0, [2] = 2, [3] = 3 }) do
		H.reset()

		local player = pilot({ 1, 2, 3, 4 }, 0, { pilotTier = from })

		S.talk(player)
		lu.assertEquals(player.ghost.pilotTier, to, "pilot tier " .. from .. " after tier_done")
	end
end

-- AC-10: the screen does the same when reached by drive (the safety net runs on display)
function TestSmugglerT1TierDone:test_tier_done_raises_the_tier_on_display_whoever_opened_it()
	local player = pilot({ 1, 2, 3, 4 }, 0, { pilotTier = 1 })

	S.drive(player, "tier_done")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
end

-- AC-10: the next talk opens tier_done again; no duty or training is offered
function TestSmugglerT1TierDone:test_the_next_talk_opens_tier_done_again_and_offers_no_duty_or_training()
	local player = pilot({ 1, 2, 3, 4 }, 99999, { pilotTier = 1 })
	local spies = {}

	for _, g in ipairs(S.GLOBALS) do
		spies[g] = H.spyOn(S.quest(g), "startQuest")
	end

	S.talk(player, WALK)

	local again = S.talk(player)

	lu.assertEquals(S.ids(again), { "tier_done" }, "the next talk")
	lu.assertEquals(S.optionSids(again[1]), { "s_8467c710" }, "tier_done: only the Ok reply")

	for _, g in ipairs(S.GLOBALS) do
		lu.assertEquals(#spies[g], 0, g .. ": not started")
	end

	lu.assertEquals(#S.free() + #S.bought(), 0, "no skill granted")
end

-- AC-10: tier_done shows the player's name where the client line has %TU (screen tier_done_oh_and)
function TestSmugglerT1TierDone:test_the_oh_and_line_carries_the_first_name()
	local player = pilot({ 1, 2, 3, 4 }, 0)
	local t = S.talk(player, { "s_8467c710" })

	lu.assertEquals(t[2].id, "tier_done_oh_and", "screen")
	lu.assertEquals(t[2].params.TU, "Ace", "the %TU parameter")
end
