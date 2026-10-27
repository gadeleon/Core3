-- Haymir Rendundi: one-click, free-choice, free tier 3 training (FH-1, D-2): a topic reply on a training screen grants the skill at once and shows
-- the answer line. One skill per won mission (I-10); the fourth skill raises pilot tier 3 to 4 (D-10); the hand-off.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-9, AC-10, AC-5, I-10; Conversation flow 2 (C-1), 3 (table H) and 3.3; FH-1; D-2, D-5, D-10).
--
-- A training screen lists one topic reply per missing tier 3 skill, in table order (starships, weapons, procedures, droid). The grant is
-- SpaceHelpers:grantSpaceSkill(player, skill, false) (J's noisyGrantSkill: no XP check, no XP charge), made in getNextConversationScreen. Guards
-- are tested through hooks, functions between two choices that change the pilot while a screen is shown.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local CS = require("harness.client_strings")

T.load()

local TRAIN = T.TRAIN
local XP = "space_combat_general"

-- the training screens of each mission (Appendix A)
local SCREENS = {
	{ n = 1, id = "m1_training" },
	{ n = 2, id = "m2_training" },
	{ n = 3, id = "m3_training" },
	{ n = 4, id = "m4_training" },
	{ n = 4, id = "m4_training_philosophy" },
}

local restore = {}

local function setUp()
	H.reset()
	T.requireConversation(lu)

	-- the real engine would charge XP for a skill box; the free grant must not (these costs make a charge visible)
	local costs = {}

	for _, t in ipairs(TRAIN) do
		costs[t.skill] = 200000
	end

	H.Engine.config.skillXpCosts = costs
end

local function tearDown()
	for _, fn in ipairs(restore) do
		fn()
	end

	restore = {}
end

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original
local function recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restore[#restore + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

local function noPurchase()
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
end

local function exp(player) return player.ghost.experience[XP] end

-- the first `count` TRAIN indexes that are not `except`
local function others(count, except)
	local out = {}

	for i = 1, 4 do
		if i ~= except and #out < count then
			out[#out + 1] = i
		end
	end

	return out
end

-- a pilot who won mission n (unpaid unless `paid`) and holds the tier 3 skills `have` (TRAIN indexes)
local function pilot(n, have, extra)
	local paid = {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t3 = have or {}, paid = paid, mission = { [n] = "won" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

-- all 16 subsets of the four skills (indexes in table order)
local function subsets()
	local out = {}

	for mask = 0, 15 do
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
-- The training screens (C-1)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3TrainingMenu = {}

TestBlackEpsilonT3TrainingMenu.setUp = setUp
TestBlackEpsilonT3TrainingMenu.tearDown = tearDown

-- AC-9, FH-1: each training screen lists exactly the missing skills, in table order
function TestBlackEpsilonT3TrainingMenu:test_every_training_screen_lists_exactly_the_missing_skills_in_table_order()
	for _, s in ipairs(SCREENS) do
		for _, have in ipairs(subsets()) do
			H.reset()

			local want, links, label = {}, {}, s.id .. " holding " .. table.concat(have, ",")

			for _, i in ipairs(missing(have)) do
				want[#want + 1] = TRAIN[i].reply
				links[#links + 1] = TRAIN[i].trained
			end

			local t = T.drive(T.pilot({ t3 = have, mission = { [s.n] = "won" } }), s.id)

			lu.assertEquals(T.ids(t), { s.id }, label .. ": screens shown")
			lu.assertEquals(T.optionSids(t[1]), want, label .. ": topic replies")
			lu.assertEquals(T.linksOf(t[1]), links, label .. ": topic links")
			lu.assertEquals(t[1].stop and true or false, #want == 0, label .. ": ends the conversation only when no topic is left (D-5)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
		end
	end
end

-- AC-9: the lead-in lines
function TestBlackEpsilonT3TrainingMenu:test_the_lead_in_lines_are_the_training_screens_of_appendix_a()
	local want = { m1_training = "s_8dcf50f", m2_training = "s_47132c0f", m3_training = "s_847e468b", m4_training = "s_726bfa38", m4_training_philosophy = "s_1dab174a" }

	for id, sid in pairs(want) do
		lu.assertEquals(T.drive(T.pilot({}), id)[1].text, T.PREFIX .. sid, id .. ": the lead-in line")
	end
end

-- AC-9: showing a training screen or a trained screen alone grants nothing
function TestBlackEpsilonT3TrainingMenu:test_showing_a_training_or_trained_screen_alone_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})

	for _, s in ipairs(SCREENS) do
		T.drive(player, s.id)
	end

	for _, x in ipairs(TRAIN) do
		T.drive(player, x.trained)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 0, "tier 3 skills held")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3TrainingGrant = {}

TestBlackEpsilonT3TrainingGrant.setUp = setUp
TestBlackEpsilonT3TrainingGrant.tearDown = tearDown

for _, s in ipairs(SCREENS) do
	for i, x in ipairs(TRAIN) do
		-- AC-9, FH-1, D-2, I-10: the topic grants the skill through grantSpaceSkill(p, skill, false) and shows the answer line, which ends
		TestBlackEpsilonT3TrainingGrant["test_choosing_" .. x.x .. "_on_" .. s.id .. "_grants_the_skill_for_free_and_shows_" .. x.trained] = function()
			local grants = recordGrants()
			local player = pilot(s.n, others(s.n - 1, i))
			local before = #T.held(player)
			local t = T.drive(player, s.id, { x.reply })

			lu.assertEquals(T.ids(t), { s.id, x.trained }, "screens shown")
			lu.assertEquals(t[2].text, T.PREFIX .. x.trainedSid, x.trained .. ": the answer line")
			lu.assertTrue(t[2].stop, x.trained .. " ends the conversation")
			lu.assertEquals(grants, { { skill = x.skill, deduct = false } }, "grantSpaceSkill(player, skill, false) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#T.held(player), before + 1, "tier 3 skills held")
			noPurchase()
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-9: the engine's XP is neither checked nor charged: 0 and 200000 XP, the same result
function TestBlackEpsilonT3TrainingGrant:test_the_grant_checks_and_charges_no_xp()
	for _, xp in ipairs({ 0, 200000 }) do
		for i, x in ipairs(TRAIN) do
			H.reset()
			setUp()

			local player = pilot(1, {}, { xp = xp })

			T.drive(player, "m1_training", { x.reply })
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), xp .. " XP: the pilot holds " .. x.skill)
			lu.assertEquals(exp(player), xp, xp .. " XP: space XP after the choice")
			noPurchase()
		end
	end
end

-- AC-9: through the whole talk: the reward walk, the training screen, the topic
function TestBlackEpsilonT3TrainingGrant:test_the_whole_talk_from_the_first_screen_grants_one_skill_and_pays_once()
	local player = pilot(1, {})
	local t = T.talk(player, { "s_b200234c", "s_2c7b60e", "s_72418db3", "s_8c751827", "s_8efde2ae", "s_77f35957" })

	lu.assertEquals(T.ids(t), { "m1_reward", "m1_debrief", "m1_need_to_know", "m1_storm", "m1_why_not_assault", "m1_training", "trained_weapons" }, "screens shown")
	lu.assertEquals(T.held(player), { TRAIN[2].skill }, "tier 3 skills held")
	lu.assertEquals(player.bankCredits, T.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9, I-10: one skill per won mission: after the grant the reward screen is gone and the next offer follows
function TestBlackEpsilonT3TrainingGrant:test_the_next_visit_shows_the_next_mission_offer_and_the_tier_stays_3()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(n, others(n - 1, 4))

		T.drive(player, SCREENS[n].id, { TRAIN[4].reply })
		lu.assertEquals(T.firstScreen(player), T.MISSIONS[n + 1].offer, "mission " .. n .. " done: the next visit")
		lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after skill " .. n)
	end
end

-- AC-9, I-10: a second choice after the grant grants nothing
function TestBlackEpsilonT3TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})

	T.drive(player, "m1_training", { TRAIN[1].reply })
	T.drive(player, "m1_training", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(T.held(player), { TRAIN[1].skill }, "tier 3 skills held")
end

-- AC-9: the fourth skill raises the pilot tier 3 to 4, and only then
function TestBlackEpsilonT3TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_3_to_4()
	for i, x in ipairs(TRAIN) do
		for _, id in ipairs({ "m4_training", "m4_training_philosophy" }) do
			H.reset()
			setUp()

			local player = pilot(4, others(3, i))

			lu.assertEquals(player.ghost.pilotTier, 3, "precondition: pilot tier 3")
			T.drive(player, id, { x.reply })
			lu.assertEquals(player.ghost.pilotTier, 4, id .. " " .. x.x .. ": pilot tier after the fourth skill")
		end
	end
end

-- AC-9
function TestBlackEpsilonT3TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	local player = pilot(3, { 1, 2 })

	T.drive(player, "m3_training", { TRAIN[3].reply })
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the third skill")
end

-- AC-9: a pilot already at tier 4 keeps it
function TestBlackEpsilonT3TrainingGrant:test_a_pilot_at_tier_4_is_not_changed()
	local player = pilot(4, { 1, 2, 3 }, { pilotTier = 4 })

	T.drive(player, "m4_training", { TRAIN[4].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
end

-- AC-9: after the fourth skill the next visit is the hand-off
function TestBlackEpsilonT3TrainingGrant:test_after_the_fourth_skill_the_next_visit_is_tour_complete()
	local player = pilot(4, { 1, 2, 3 }, { mission = { [4] = "paid" } })

	T.drive(player, "m4_training", { TRAIN[4].reply })
	lu.assertEquals(T.firstScreen(player), "tour_complete", "next visit")
end

-- AC-9: the skills can be chosen in any order, one per mission
function TestBlackEpsilonT3TrainingGrant:test_the_four_skills_can_be_chosen_in_a_reversed_order_over_four_missions()
	local grants = recordGrants()
	local player = T.pilot({})

	for step, i in ipairs({ 4, 3, 2, 1 }) do
		-- mission `step` is flown and won, then talked about
		local m = T.MISSIONS[step]

		H.setQuestStatus(player, m.status .. ":attempted", "1")

		for _, g in ipairs(m.chain) do
			T.setState(player, g, "complete")
		end

		local t = T.talk(player)

		lu.assertEquals(t[1].id, m.reward, "visit " .. step .. ": the reward screen")

		T.drive(player, SCREENS[step].id, { TRAIN[i].reply })
	end

	lu.assertEquals(#grants, 4, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 4, "tier 3 skills held")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the fourth skill")
	noPurchase()
end

---------------------------------------------------------------------------------------------
-- Guards that fail while the training screen is shown (hooks)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3TrainingGuards = {}

TestBlackEpsilonT3TrainingGuards.setUp = setUp
TestBlackEpsilonT3TrainingGuards.tearDown = tearDown

-- AC-9
function TestBlackEpsilonT3TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_granted_again()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = T.drive(player, "m1_training", { function(p) p.skills[TRAIN[2].skill] = true end, TRAIN[2].reply })

	lu.assertNotEquals(t[#t].id, "trained_weapons", "no trained screen for a skill already held")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end

-- AC-9, I-10: the won mission taken away meanwhile: no reward mission, no grant, the gates route the pilot
function TestBlackEpsilonT3TrainingGuards:test_a_mission_that_is_no_longer_won_grants_nothing_and_routes_by_the_gates()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = T.drive(player, "m1_training", { function(p) T.setState(p, T.M1[4], "none") end, TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "m1_failed", "routed by the gates: mission 1 attempted, not won")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 0, "tier 3 skills held")
end

-- AC-9, I-10: the training screen reached with no reward pending grants nothing
function TestBlackEpsilonT3TrainingGuards:test_a_topic_chosen_with_no_reward_pending_grants_nothing()
	local grants = recordGrants()
	local player = T.pilot({ t3 = { 1 }, paid = { 1 } })
	local t = T.drive(player, "m2_training", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "m2_offer", "routed by the gates: mission 2 is the next offer")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 1, "tier 3 skills held")
end

-- AC-9: a trained screen reached from another screen never grants
function TestBlackEpsilonT3TrainingGuards:test_a_trained_screen_shown_alone_ends_and_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = T.drive(player, "trained_starships")

	lu.assertEquals(T.ids(t), { "trained_starships" }, "screens shown")
	lu.assertTrue(t[1].stop, "ends the conversation")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end

---------------------------------------------------------------------------------------------
-- The fourth reward before the hand-off (D-5, AC-10)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3HandOff = {}

TestBlackEpsilonT3HandOff.setUp = setUp
TestBlackEpsilonT3HandOff.tearDown = tearDown

-- AC-10, D-5: all four skills held but mission 4 unpaid: the reward comes first, pays, and its training screens stop with no options
function TestBlackEpsilonT3HandOff:test_mission_4_unpaid_with_four_skills_shows_the_reward_then_a_training_screen_with_no_option()
	local grants = recordGrants()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })
	local t = T.talk(player, { "s_84bc2cb6" })

	lu.assertEquals(T.ids(t), { "m4_reward", "m4_training" }, "screens shown")
	lu.assertEquals(player.bankCredits, T.CREDITS, "mission 4 is paid")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier3_4:reward"), "1", "the :reward key")
	lu.assertEquals(#t[2].options, 0, "m4_training has no option")
	lu.assertTrue(t[2].stop, "m4_training ends the conversation")
	lu.assertEquals(grants, {}, "no skill granted")
	lu.assertEquals(T.firstScreen(player), "tour_complete", "the next visit is the hand-off")
end

-- AC-10, D-5: the other way round to the philosophy screen
function TestBlackEpsilonT3HandOff:test_the_philosophy_branch_of_an_unpaid_mission_4_also_ends_without_options()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })
	local t = T.talk(player, { "s_1d2c73ce", "s_d9391333" })

	lu.assertEquals(T.ids(t), { "m4_reward", "m4_revenge", "m4_training_philosophy" }, "screens shown")
	lu.assertEquals(#t[3].options, 0, "m4_training_philosophy has no option")
	lu.assertTrue(t[3].stop, "m4_training_philosophy ends the conversation")
end

-- AC-10: the hand-off walk
function TestBlackEpsilonT3HandOff:test_tour_complete_leads_to_the_dantooine_outpost_and_ends()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })
	local t = T.talk(player, { "s_d2e23af2", "s_24a3fa0c", "s_1474f13c", "s_9b5a6b23" })

	lu.assertEquals(T.ids(t), { "tour_complete", "insurgent", "insurgent_who", "insurgent_order", "insurgent_dantooine" }, "screens shown")
	lu.assertTrue(t[#t].stop, "insurgent_dantooine ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "tour_complete carries the pilot's first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10, D-10: tour_complete raises a tier 3 pilot to tier 4 (and leaves a tier 4 pilot alone)
function TestBlackEpsilonT3HandOff:test_tour_complete_raises_pilot_tier_3_to_4()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, pilotTier = 3 })

	T.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after tour_complete")

	local again = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, pilotTier = 4 })

	T.talk(again)
	lu.assertEquals(again.ghost.pilotTier, 4, "a tier 4 pilot stays at 4")
end

-- AC-10: the hand-off grants and starts nothing; Nin Gursawe has no conversation yet (R-7)
function TestBlackEpsilonT3HandOff:test_the_hand_off_starts_and_grants_nothing()
	local spies = T.spyStarts()
	local grants = recordGrants()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })

	T.talk(player, { "s_d2e23af2", "s_24a3fa0c", "s_1474f13c", "s_9b5a6b23" })
	lu.assertEquals(T.started(spies), {}, "no quest started")
	lu.assertEquals(grants, {}, "no skill granted")
	lu.assertEquals(player.bankCredits, 0, "no credits")
end
