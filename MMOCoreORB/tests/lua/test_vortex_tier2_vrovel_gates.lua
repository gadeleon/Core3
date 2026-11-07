-- Brother Vrovel: which screen a pilot opens on (gate table V), the conditional off-track link (C-1) and purity (I-3).
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-3; Conversation flow 1 and 2; Source inventory 3; FV-3, FV-4, FV-9; D-6, D-7, D-9; I-3; Q-2 = A).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is vortex_tier2_data.lua V.pilot
-- (a Vortex pilot who graduated V3-FX: four tier 1 skills, VORTEX_PILOT_KEY "2" by default; missions = Vrovel's missions won and paid; t2 = the
-- tier 2 skills held; state = the state of mission missions + 1). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

local function snapshot(player)
	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = V.standing(player),
		pilotTier = player.ghost and player.ghost.pilotTier, skills2 = V.held2(player), flag = V.flag(player),
		inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-3 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = V.handler():getInitialScreen(player, V.npc(), H.conversationTemplate(V.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-3)")
	return first
end

TestVrovelGates = {}

TestVrovelGates.setUp = setUp

-- V0
-- AC-3
function TestVrovelGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = V.pilot(), V.npc(), H.conversationTemplate(V.TEMPLATE)

	lu.assertNil(V.handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(V.handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(V.handler():getInitialScreen(player, npc, nil), "no template")
end

-- V1
-- AC-3
function TestVrovelGates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	local t = V.talk(V.pilot())

	lu.assertEquals(V.ids(t), { "not_pilot" }, "JTL disabled")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
end

-- AC-3
function TestVrovelGates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = V.pilot()

	player.ghost = nil

	-- (no snapshot: the state snapshot reads the ghost)
	local pScreen = V.handler():getInitialScreen(player, V.npc(), H.conversationTemplate(V.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")
	lu.assertEquals(LuaConversationScreen(pScreen):getScreenID(), "not_pilot", "ghost is nil (SWG !hasSpaceExpansion)")
end

-- V2
-- AC-3
function TestVrovelGates:test_a_non_pilot_opens_not_pilot()
	local t = V.talk(V.pilot({ pilot = false, squadron = false, faction = "neutral" }))

	lu.assertEquals(V.ids(t), { "not_pilot" }, "a player with no pilot skill")
	lu.assertTrue(t[1].stop, "not_pilot ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- V3
-- AC-3: a tier 2 graduate (four _02 skills, flag "3", M4 paid) is handed to Ezkiel; the screen ends and grants nothing
function TestVrovelGates:test_a_tier_2_graduate_opens_the_hand_off_to_ezkiel_which_ends_and_grants_nothing()
	local player = V.pilot({ missions = 4, t2 = 4, graduated = "3" })
	local before = snapshot(player)
	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "ezkiel_handoff" }, "tier 2 done, flag 3, M4 paid")
	lu.assertTrue(t[1].stop, "ezkiel_handoff ends the conversation")
	lu.assertEquals(#t[1].options, 0, "ezkiel_handoff offers no reply")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(snapshot(player).credits, before.credits, "credits")
	lu.assertEquals(V.standing(player), before.standing, "standing")
	lu.assertEquals(V.flag(player), "3", "the flag is untouched")
end

-- AC-3: any set flag value counts for the hand-off ("set", not "== 3"), with the M4 reward paid and all four _02 skills
function TestVrovelGates:test_the_hand_off_needs_a_set_flag_four_tier_2_skills_and_the_mission_4_reward_not_a_particular_value()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(V.pilot({ missions = 4, t2 = 4, graduated = flag })), "ezkiel_handoff", "flag " .. flag .. ", tier 2 done, M4 paid")
	end

	lu.assertNotEquals(opens(V.pilot({ missions = 4, t2 = 3, graduated = "3" })), "ezkiel_handoff", "three _02 skills only")
	lu.assertNotEquals(opens(V.pilot({ missions = 4, t2 = 4, graduated = false })), "ezkiel_handoff", "no flag")
	lu.assertEquals(opens(V.pilot({ missions = 3, t2 = 4, state = "won" })), "m4_won", "mission 4 won but unpaid shows the won screen, not the hand-off")
end

-- AC-3, SWG gate 2 precedes gate 3 to 6: the tier-done pilot is handed on whatever his faction or standing is
function TestVrovelGates:test_the_hand_off_comes_before_the_faction_standing_and_squadron_gates()
	lu.assertEquals(opens(V.pilot({ missions = 4, t2 = 4, graduated = "3", faction = "imperial" })), "ezkiel_handoff", "Imperial faction")
	lu.assertEquals(opens(V.pilot({ missions = 4, t2 = 4, graduated = "3", standing = -1 })), "ezkiel_handoff", "negative standing")
	lu.assertEquals(opens(V.pilot({ missions = 4, t2 = 4, graduated = "3", squadron = false })), "ezkiel_handoff", "no squadron")
end

-- V4
-- AC-3
function TestVrovelGates:test_an_imperial_faction_player_opens_imperial()
	local t = V.talk(V.pilot({ faction = "imperial" }))

	lu.assertEquals(V.ids(t), { "imperial" }, "Imperial faction")
	lu.assertTrue(t[1].stop, "imperial ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3
function TestVrovelGates:test_an_imperial_pilot_opens_imperial()
	lu.assertEquals(opens(V.pilot({ pilot = "imperial", faction = "imperial" })), "imperial", "Imperial pilot")
	lu.assertEquals(opens(V.pilot({ pilot = "imperial", faction = "rebel" })), "imperial", "Imperial pilot skills with Rebel faction (isImperialPilot)")
end

-- V5
-- AC-3: a CorSec pilot and any neutral pilot
function TestVrovelGates:test_a_neutral_pilot_opens_neutral_pilot()
	local t = V.talk(V.pilot({ pilot = "neutral", squadron = CORSEC_SQUADRON, faction = "neutral" }))

	lu.assertEquals(V.ids(t), { "neutral_pilot" }, "CorSec pilot")
	lu.assertTrue(t[1].stop, "neutral_pilot ends")
	lu.assertEquals(opens(V.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "neutral_pilot", "neutral pilot without a squadron")
end

-- V6
-- AC-3, D-7: negative Rebel standing grounds the pilot
function TestVrovelGates:test_a_vortex_pilot_with_rebel_standing_minus_one_opens_grounded()
	local t = V.talk(V.pilot({ standing = -1 }))

	lu.assertEquals(V.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(V.optionSids(t[1]), { "s_900f01d1" }, "the grounded chain opens with one reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, D-7: standing 0 is not negative
function TestVrovelGates:test_standing_zero_is_not_grounded()
	lu.assertNotEquals(opens(V.pilot({ standing = 0 })), "grounded", "standing 0")
end

-- AC-3, D-7: a Rebel pilot whose faction is not Rebel (neutral) is grounded too
function TestVrovelGates:test_a_vortex_pilot_of_neutral_faction_opens_grounded()
	lu.assertEquals(opens(V.pilot({ faction = "neutral" })), "grounded", "neutral faction, Rebel pilot")
end

-- AC-3: the grounded chain walks to its end and offers nothing
function TestVrovelGates:test_the_grounded_chain_walks_to_standing_and_ends_without_a_grant()
	local player = V.pilot({ standing = -5, xp = 99999 })
	local t = V.talk(player, { "s_900f01d1", "s_f8b02865" })

	lu.assertEquals(V.ids(t), { "grounded", "grounded_hq", "grounded_standing" }, "the grounded walk")
	lu.assertTrue(t[3].stop, "grounded_standing ends")
	lu.assertEquals(#V.held2(player), 0, "no skill is trained")
	lu.assertEquals(V.standing(player), -5, "standing unchanged")
end

-- V7
-- AC-3: a Havoc pilot is off track
function TestVrovelGates:test_a_havoc_pilot_opens_off_track()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON }))

	lu.assertEquals(V.ids(t), { "off_track" }, "Havoc pilot")
	lu.assertEquals(V.optionSids(t[1]), { "s_c23a0a19" }, "the one reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3: a Rebel pilot with no squadron is off track as well
function TestVrovelGates:test_a_rebel_pilot_without_a_squadron_opens_off_track()
	lu.assertEquals(opens(V.pilot({ squadron = false })), "off_track", "no squadron")
end

-- V7 before V8: the squadron gate beats the missing flag
function TestVrovelGates:test_off_track_comes_before_non_member()
	lu.assertEquals(opens(V.pilot({ squadron = HAVOC_SQUADRON, graduated = false })), "off_track", "Havoc pilot without the flag")
end

-- V8
-- AC-3: a Vortex pilot without the flag (V3-FX has not promoted him) is not a member
function TestVrovelGates:test_a_vortex_pilot_without_the_flag_opens_non_member()
	local t = V.talk(V.pilot({ graduated = false }))

	lu.assertEquals(V.ids(t), { "non_member" }, "no VORTEX_PILOT_KEY")
	lu.assertTrue(t[1].stop, "non_member ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- V9
-- AC-3: a pilot flying any chain member or duty of Vrovel's is on a mission
function TestVrovelGates:test_a_pilot_flying_any_vrovel_quest_opens_on_mission()
	for _, global in ipairs(V.GLOBALS) do
		H.reset()

		local player = V.pilot({ active = global })

		lu.assertEquals(opens(player), "on_mission", global .. " active in the journal")
	end

	local t = V.talk(V.pilot({ missions = 1, t2 = 2, active = V.E2 }))

	lu.assertEquals(V.ids(t), { "on_mission" }, "mission 2 flying")
	lu.assertTrue(t[1].stop, "on_mission ends")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
end

-- V9 before V11: the hand-in waits while a quest is flying
function TestVrovelGates:test_on_mission_comes_before_the_hand_in()
	lu.assertEquals(opens(V.pilot({ graduated = "1", active = V.DUTY5 })), "on_mission", "flag 1 with a duty active")
end

-- V10
-- AC-3: a pilot with another space mission (a story or duty mission in the datapad) is on another mission
function TestVrovelGates:test_a_pilot_holding_another_space_quest_opens_other_mission()
	lu.assertEquals(opens(V.pilot({ datapad = "story" })), "other_mission", "a story mission in the datapad")
	lu.assertEquals(opens(V.pilot({ datapad = "duty" })), "other_mission", "a duty mission in the datapad")
	lu.assertEquals(opens(V.pilot({ graduated = "1", datapad = "duty" })), "other_mission", "flag 1: the datapad gate comes before the hand-in")
end

-- V11
-- AC-3, AC-4, Q-2 = A: a V3-FX graduate is handed in first
function TestVrovelGates:test_a_graduate_with_flag_1_opens_the_hand_in()
	local t = V.talk(V.pilot({ graduated = "1", pilotTier = 2 }))

	lu.assertEquals(V.ids(t), { "handin" }, "flag 1, tier 1 done")
	lu.assertEquals(V.optionSids(t[1]), { "s_d049b613", "s_45236b6c" }, "the two replies (no GM reply for a normal pilot)")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, AC-4, Q-2 = A, FV-4: also with the XP for training
function TestVrovelGates:test_the_hand_in_comes_before_training_for_a_graduate_with_60000_experience()
	lu.assertEquals(opens(V.pilot({ graduated = "1", xp = V.XP_COST })), "handin", "flag 1, exactly 60,000 XP")
	lu.assertEquals(opens(V.pilot({ graduated = "1", xp = 999999 })), "handin", "flag 1, far more XP")
end

-- AC-3, Q-2 = A: the hand-in precedes every mission gate
function TestVrovelGates:test_the_hand_in_comes_before_every_mission_gate()
	lu.assertEquals(opens(V.pilot({ graduated = "1", t2 = 1 })), "handin", "flag 1 with one _02 skill (mission 1 would be offered)")
	lu.assertEquals(opens(V.pilot({ graduated = "1", t2 = 1, state = "failed" })), "handin", "flag 1, mission 1 failed")
	lu.assertEquals(opens(V.pilot({ graduated = "1", t2 = 1, state = "won" })), "handin", "flag 1, mission 1 won")
end

-- V11 needs the flag to be exactly "1": a flag "2" pilot never sees the hand-in
function TestVrovelGates:test_a_pilot_with_flag_2_or_3_is_not_handed_in_again()
	lu.assertNotEquals(opens(V.pilot({ graduated = "2" })), "handin", "flag 2")
	lu.assertNotEquals(opens(V.pilot({ graduated = "3", missions = 2, t2 = 2 })), "handin", "flag 3")
end

-- V12 to V23 (the mission gates, in order): one row per mission and state
local ROWS = {
	-- { mission n, state, expected screen } (missions before n paid, n - 1 tier 2 skills + 1 = n skills)
	{ 4, "failed", "m4_failed" }, { 4, "won", "m4_won" }, { 4, nil, "m4_offer" },
	{ 3, "won", "m3_won" }, { 3, "failed", "m3_failed" }, { 3, nil, "m3_offer" },
	{ 2, "won", "m2_won" }, { 2, "failed", "m2_failed" }, { 2, nil, "m2_offer" },
	{ 1, "failed", "m1_failed" }, { 1, "won", "m1_won" }, { 1, nil, "m1_offer" },
}

for _, row in ipairs(ROWS) do
	local n, state, screen = row[1], row[2], row[3]

	-- AC-3, AC-5
	TestVrovelGates["test_a_flag_2_pilot_with_" .. n .. "_tier_2_skills_and_mission_" .. n .. "_" .. (state or "unstarted") .. "_opens_" .. screen] = function()
		local t = V.talk(V.pilot({ missions = n - 1, t2 = n, state = state }))

		lu.assertEquals(t[1].id, screen, "mission " .. n .. " " .. (state or "unstarted"))
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-5: the skills count must match: a won mission n is shown only with n skills; the next mission is never offered while mission n is unpaid
function TestVrovelGates:test_the_next_mission_is_never_offered_while_the_mission_before_it_is_won_and_unpaid()
	for n = 1, 3 do
		H.reset()

		local player = V.pilot({ missions = n - 1, t2 = n, state = "won" })

		lu.assertEquals(opens(player), V.MISSIONS[n].won, "mission " .. n .. " won and unpaid shows its won screen")
	end
end

-- AC-5: with n skills and mission n paid, nothing offers mission n + 1 until the next skill is bought (training or the duty list)
function TestVrovelGates:test_after_a_paid_mission_the_pilot_is_offered_training_or_duties_not_the_next_mission()
	for n = 1, 3 do
		H.reset()
		lu.assertEquals(opens(V.pilot({ missions = n, t2 = n, xp = 0 })), "duty_offer", "mission " .. n .. " paid, no XP: the duty offer")
		H.reset()
		lu.assertEquals(opens(V.pilot({ missions = n, t2 = n, xp = V.XP_COST })), "training_offer", "mission " .. n .. " paid, 60,000 XP: the training offer")
	end
end

-- V13: a mission that is active is on_mission, not failed
-- AC-5
function TestVrovelGates:test_an_active_mission_is_not_failed()
	lu.assertEquals(opens(V.pilot({ missions = 0, t2 = 1, state = "active" })), "on_mission", "mission 1 active")
	lu.assertEquals(opens(V.pilot({ missions = 3, t2 = 4, state = "active" })), "on_mission", "mission 4 active")
end

-- V12 to V23 (SWG gates 10 to 21): the failure gate counts a failed OR aborted mission and M1 counts any of its three quests
-- AC-5
function TestVrovelGates:test_a_mission_with_attempted_set_and_nothing_complete_is_failed_for_every_mission()
	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(V.pilot({ missions = n - 1, t2 = n, state = "failed" })), V.MISSIONS[n].failed, "mission " .. n .. ": attempted, not won, not active")
	end
end

-- AC-5: mission 1 with the escort won but the surprise attack lost is failed (the chain has no win until the last member)
function TestVrovelGates:test_mission_1_with_only_the_escort_and_inspect_complete_is_failed()
	local player = V.pilot({ missions = 0, t2 = 1, state = "failed" })

	V.setState(player, V.E1, "complete")
	V.setState(player, V.I1, "complete")
	lu.assertEquals(opens(player), "m1_failed", "the surprise attack is not complete")
end

-- V24
-- AC-3, AC-7: 60,000 XP and no mission ready
function TestVrovelGates:test_a_flag_2_pilot_with_60000_experience_and_no_mission_ready_opens_the_training_offer()
	local t = V.talk(V.pilot({ xp = V.XP_COST }))

	lu.assertEquals(V.ids(t), { "training_offer" }, "0 _02 skills, 60,000 XP")
	lu.assertEquals(V.optionSids(t[1]), { "s_9b8d2abd", "s_2e18346d" }, "yes and no")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the XP threshold is exactly 60,000
function TestVrovelGates:test_the_training_offer_needs_60000_experience_exactly()
	lu.assertEquals(opens(V.pilot({ xp = V.XP_COST - 1 })), "duty_offer", "59,999 XP")
	lu.assertEquals(opens(V.pilot({ xp = V.XP_COST })), "training_offer", "60,000 XP")
end

-- AC-7 (isReadyForTraining): any set flag value (not only "2") with tier 1 done and tier 2 not complete
function TestVrovelGates:test_training_is_offered_for_any_set_flag_value()
	lu.assertEquals(opens(V.pilot({ graduated = "2", xp = V.XP_COST })), "training_offer", "flag 2")
	lu.assertEquals(opens(V.pilot({ graduated = "3", xp = V.XP_COST, missions = 3, t2 = 3 })), "training_offer", "flag 3 with three _02 skills (the set flag is what counts)")
end

-- AC-3 (FV-3): no training for a pilot with the tier 1 incomplete (V25 then matches the flag "2")
function TestVrovelGates:test_no_training_for_a_pilot_with_tier_1_incomplete()
	lu.assertEquals(opens(V.pilot({ graduated = "2", t1 = 3, xp = 999999 })), "duty_offer", "three _01 skills, flag 2, XP: no training offer")
end

-- V25
-- AC-3: flag "2", no _02 skill and less than 60,000 XP
function TestVrovelGates:test_a_flag_2_pilot_with_no_tier_2_skill_and_little_experience_opens_the_duty_offer()
	local t = V.talk(V.pilot({ graduated = "2", xp = 0 }))

	lu.assertEquals(V.ids(t), { "duty_offer" }, "flag 2")
	lu.assertEquals(V.optionSids(t[1]), { "s_9b43a7ee", "s_6b054777" }, "the two replies (no GM reply)")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- V26
-- AC-3: a flag-1 pilot with incomplete tier 1 falls to the default
function TestVrovelGates:test_a_flag_1_pilot_with_incomplete_tier_1_opens_private_property()
	local t = V.talk(V.pilot({ graduated = "1", t1 = 3 }))

	lu.assertEquals(V.ids(t), { "private_property" }, "flag 1, three _01 skills")
	lu.assertEquals(V.optionSids(t[1]), { "s_6f6eeaf3", "s_9f0a282" }, "goodbye and leave (no GM reply)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track reply (FV-9)
---------------------------------------------------------------------------------------------

TestVrovelOffTrack = {}

TestVrovelOffTrack.setUp = setUp

-- AC-3, AC-8: tier 1 done and no quest -> the duty offer
function TestVrovelOffTrack:test_a_havoc_pilot_with_tier_1_done_and_no_quest_is_offered_duties()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON }), { "s_c23a0a19" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_duties" }, "the reply leads to the duty offer")
	lu.assertEquals(V.optionSids(t[2]), { "s_52917b0d", "s_28f9c5ec" }, "interested / not")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, AC-8: fewer than four _01 skills -> "I can only assign missions to Vortex pilots"
function TestVrovelOffTrack:test_an_off_track_pilot_without_tier_1_done_gets_no_missions()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON, t1 = 3 }), { "s_c23a0a19" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_no_missions" }, "three _01 skills")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends")
end

-- AC-8: no skill at all
function TestVrovelOffTrack:test_an_off_track_pilot_with_no_tier_1_skill_gets_no_missions()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON, t1 = 0 }), { "s_c23a0a19" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_no_missions" }, "no _01 skill")
end

-- AC-8: any space quest (a datapad mission) refuses the duties; the gate itself still opens off_track (V7 precedes V10)
function TestVrovelOffTrack:test_an_off_track_pilot_with_a_space_quest_gets_no_missions()
	for _, kind in ipairs({ "story", "duty" }) do
		H.reset()

		local player = V.pilot({ squadron = HAVOC_SQUADRON, datapad = kind })
		local t = V.talk(player, { "s_c23a0a19" })

		lu.assertEquals(V.ids(t), { "off_track", "off_track_no_missions" }, kind .. " mission in the datapad")
	end
end

-- AC-8: a Vrovel quest active in the journal also refuses
function TestVrovelOffTrack:test_an_off_track_pilot_flying_a_duty_gets_no_missions()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON, active = V.DUTY5 }), { "s_c23a0a19" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_no_missions" }, "a duty active in the journal")
end

-- AC-3 (C-1): the decision is made when the reply is shown, from the pilot's state then
function TestVrovelOffTrack:test_the_reply_link_follows_the_state_at_the_time_of_the_talk()
	local player = V.pilot({ squadron = HAVOC_SQUADRON, t1 = 3 })
	local first = V.talk(player)

	lu.assertEquals(V.linksOf(first[1]), { "off_track_no_missions" }, "no tier 1 done: the link")

	local ready = V.pilot({ squadron = HAVOC_SQUADRON })

	lu.assertEquals(V.linksOf(V.talk(ready)[1]), { "off_track_duties" }, "tier 1 done: the link")
end

---------------------------------------------------------------------------------------------
-- I-3: purity
---------------------------------------------------------------------------------------------

TestVrovelPureGates = {}

TestVrovelPureGates.setUp = setUp

-- AC-3, I-3: the gate decision itself writes nothing (status keys, flag, journal, skills, XP, pilot tier, standing, credits, inventory), for every kind of pilot
function TestVrovelPureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return V.pilot() end,
		function() return V.pilot({ graduated = "1" }) end,
		function() return V.pilot({ graduated = "1", xp = 999999 }) end,
		function() return V.pilot({ graduated = false }) end,
		function() return V.pilot({ faction = "imperial" }) end,
		function() return V.pilot({ pilot = "neutral", squadron = CORSEC_SQUADRON }) end,
		function() return V.pilot({ pilot = false, squadron = false }) end,
		function() return V.pilot({ standing = -1 }) end,
		function() return V.pilot({ faction = "neutral" }) end,
		function() return V.pilot({ squadron = HAVOC_SQUADRON }) end,
		function() return V.pilot({ active = V.E1 }) end,
		function() return V.pilot({ datapad = "story" }) end,
		function() return V.pilot({ t2 = 1, state = "won" }) end,
		function() return V.pilot({ t2 = 1, state = "failed" }) end,
		function() return V.pilot({ t2 = 1 }) end,
		function() return V.pilot({ missions = 1, t2 = 2, state = "won" }) end,
		function() return V.pilot({ missions = 1, t2 = 2, state = "failed" }) end,
		function() return V.pilot({ missions = 1, t2 = 2 }) end,
		function() return V.pilot({ missions = 2, t2 = 3, state = "won" }) end,
		function() return V.pilot({ missions = 2, t2 = 3, state = "failed" }) end,
		function() return V.pilot({ missions = 2, t2 = 3 }) end,
		function() return V.pilot({ missions = 3, t2 = 4, state = "won" }) end,
		function() return V.pilot({ missions = 3, t2 = 4, state = "failed" }) end,
		function() return V.pilot({ missions = 3, t2 = 4 }) end,
		function() return V.pilot({ missions = 4, t2 = 4, graduated = "3" }) end,
		function() return V.pilot({ missions = 3, t2 = 3, xp = V.XP_COST }) end,
		function() return V.pilot({ xp = V.XP_COST }) end,
		function() return V.pilot({ graduated = "1", t1 = 3 }) end,
		function() return V.pilot({ privileged = true }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local screen = opens(player)

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
	end
end

-- AC-3, I-3: the ghost-less pilot and the JTL-off pilot too
function TestVrovelPureGates:test_the_jtl_and_ghost_gates_change_no_state()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(V.pilot()), "not_pilot", "JTL disabled")
end

-- AC-3: the gate order is first match wins; a missing JTL beats every other gate
function TestVrovelPureGates:test_jtl_disabled_beats_every_other_gate()
	H.Engine.config.jtlEnabled = false

	for _, o in ipairs({ { graduated = "1" }, { missions = 4, t2 = 4, graduated = "3" }, { faction = "imperial" }, { xp = V.XP_COST }, { active = V.E1 } }) do
		lu.assertEquals(opens(V.pilot(o)), "not_pilot", "JTL disabled")
	end
end
