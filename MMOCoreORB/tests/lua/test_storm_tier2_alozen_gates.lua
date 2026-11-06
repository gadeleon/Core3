-- Field Commander Alozen: which screen a pilot opens on (gate table A), the conditional links C-1 .. C-3, and the off-track closure.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-6, AC-7 (greeting); Conversation flow 1 and 2; FA-3, FA-4, FA-5; D-5, D-7, D-8, D-11; I-11, I-12; Q-1 = A).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is storm_tier2_alozen_data.lua A.pilot
-- (a Storm pilot as Oberhaur sends him; m = Alozen's missions paid, state = the state of the next one). getInitialScreen is side-effect free (I-11): every
-- pilot built here is also checked against a before/after snapshot.

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

A.load()

local COST = A.TRAINING_COST

local function handler() return rawget(_G, A.HANDLER) end

local BLACK_EPSILON = function() return rawget(_G, "BLACK_EPSILON_SQUADRON") end

local function snapshot(player)
	local skills = {}

	for _, t in ipairs(A.TRAIN) do
		skills[#skills + 1] = CreatureObject(player):hasSkill(t.skill)
	end

	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = player.ghost.factionStanding.imperial,
		pilotTier = player.ghost.pilotTier, skills = skills, inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-11 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = handler():getInitialScreen(player, A.npc(), H.conversationTemplate(A.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-11)")
	return first
end

local function setUp()
	H.reset()
	A.requireConversation(lu)
end

TestAlozenGates = {}

TestAlozenGates.setUp = setUp

-- A0
-- AC-6
function TestAlozenGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = A.pilot(), A.npc(), H.conversationTemplate(A.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- A1
-- AC-6
function TestAlozenGates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(A.pilot()), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = A.pilot()

	player.ghost = nil
	lu.assertEquals(A.firstScreen(player), "not_pilot", "ghost is nil")
end

-- A2
-- AC-6
function TestAlozenGates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = A.talk(A.pilot({ pilot = false, squadron = false, t1 = false, t2 = {} }))

	lu.assertEquals(A.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, A.PREFIX .. "s_21772e5a", "'I'm sorry, I can't help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- A3
-- AC-6
function TestAlozenGates:test_rebel_faction_or_a_rebel_pilot_opens_not_pilot()
	lu.assertEquals(opens(A.pilot({ pilot = false, faction = "rebel", squadron = false, t1 = false, t2 = {} })), "not_pilot", "Rebel-faction non-pilot")
	lu.assertEquals(opens(A.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "not_pilot", "Rebel pilot")
	lu.assertEquals(opens(A.pilot({ faction = "rebel" })), "not_pilot", "Storm pilot with Rebel faction")
	lu.assertEquals(opens(A.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "not_pilot", "Rebel pilot with Rebel faction")
end

-- A4
-- AC-6
function TestAlozenGates:test_a_privateer_opens_not_pilot()
	lu.assertEquals(opens(A.pilot({ pilot = "neutral", squadron = false })), "not_pilot", "privateer, Imperial faction")
	lu.assertEquals(opens(A.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "not_pilot", "privateer, no faction")
end

-- A5 (Q-1 = A)
-- AC-6
function TestAlozenGates:test_negative_imperial_standing_opens_not_pilot()
	lu.assertEquals(opens(A.pilot({ standing = -1 })), "not_pilot", "Storm pilot, standing -1")
	lu.assertEquals(opens(A.pilot({ standing = -50, m = 1 })), "not_pilot", "standing -50 mid-chain")
	lu.assertEquals(opens(A.pilot({ standing = 0 })), "greeting", "standing 0 is served normally")
end

-- A5 (Q-1 = A)
-- AC-6
function TestAlozenGates:test_an_imperial_pilot_with_no_faction_opens_not_pilot()
	lu.assertEquals(opens(A.pilot({ faction = "neutral" })), "not_pilot", "Storm pilot, standing 0, neutral faction")
	lu.assertEquals(opens(A.pilot({ faction = "neutral", squadron = false })), "not_pilot", "A5 precedes the track check")
end

-- A5 precedes the later gates (Q-1: "before the on-mission check")
-- AC-6
function TestAlozenGates:test_the_standing_gate_precedes_on_mission_and_every_later_gate()
	lu.assertEquals(opens(A.pilot({ standing = -1, state = "active" })), "not_pilot", "A5 precedes on_mission (mission 1 active)")
	lu.assertEquals(opens(A.pilot({ standing = -1, datapad = "story" })), "not_pilot", "A5 precedes on_mission (datapad quest)")
	lu.assertEquals(opens(A.pilot({ standing = -1, squadron = false })), "not_pilot", "A5 precedes off_track")
	lu.assertEquals(opens(A.pilot({ standing = -1, m = 3 })), "not_pilot", "A5 precedes denner_transfer")
	lu.assertEquals(opens(A.pilot({ faction = "neutral", m = 1, state = "won" })), "not_pilot", "A5 precedes m2_won")
end

-- A6
-- AC-6
function TestAlozenGates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	local t = A.talk(A.pilot({ state = "active" }))

	lu.assertEquals(A.ids(t), { "on_mission" }, "mission 1 active")
	lu.assertTrue(t[1].stop, "on_mission ends the conversation")
	lu.assertEquals(#t[1].options, 0, "on_mission offers no reply")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(A.pilot({ m = 2, state = "active" })), "on_mission", "mission 3 active")
	-- a running Oberhaur duty is in the journal and in the datapad (the mission object); Alozen's own check sees the datapad (SpaceHelpers:hasSpaceQuest)
	lu.assertEquals(opens(A.pilot({ m = 2, duty = T.DUTY1, datapad = "duty" })), "on_mission", "an Oberhaur duty running (journal entry and datapad mission)")
	lu.assertEquals(opens(A.pilot({ m = 2, datapad = "story" })), "on_mission", "a story mission in the datapad")
	lu.assertEquals(opens(A.pilot({ m = 2, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	for _, duty in ipairs(A.DUTIES) do
		local player = A.pilot({ m = 2 })

		A.setState(player, duty, "active")
		lu.assertEquals(opens(player), "on_mission", duty .. " active")
	end

	lu.assertEquals(opens(A.pilot({ squadron = BLACK_EPSILON(), datapad = "story" })), "on_mission", "Black Epsilon pilot with a story mission")
	lu.assertEquals(opens(A.pilot({ squadron = BLACK_EPSILON(), datapad = "duty" })), "on_mission", "Black Epsilon pilot with a duty")
end

-- A6 precedes the later gates
-- AC-6
function TestAlozenGates:test_on_mission_precedes_the_track_check_and_every_state_screen()
	lu.assertEquals(opens(A.pilot({ squadron = false, datapad = "story" })), "on_mission", "A6 precedes off_track")
	lu.assertEquals(opens(A.pilot({ m = 3, datapad = "story" })), "on_mission", "A6 precedes denner_transfer")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "won", datapad = "duty" })), "on_mission", "A6 precedes m2_won")
end

-- A7
-- AC-6
function TestAlozenGates:test_a_pilot_of_another_squadron_without_a_quest_opens_off_track()
	lu.assertEquals(opens(A.pilot({ squadron = BLACK_EPSILON() })), "off_track", "Black Epsilon pilot")
	lu.assertEquals(opens(A.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })), "off_track", "Inquisition pilot")
	lu.assertEquals(opens(A.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(A.pilot({ squadron = false, m = 3 })), "off_track", "A7 precedes denner_transfer")
	lu.assertEquals(opens(A.pilot({ squadron = false, m = 1, state = "won" })), "off_track", "A7 precedes m2_won")
end

-- A8
-- AC-6, AC-10
function TestAlozenGates:test_mission_3_paid_opens_denner_transfer_before_anything_else()
	local t = A.talk(A.pilot({ m = 3 }))

	lu.assertEquals(A.ids(t), { "denner_transfer" }, "M3 paid")
	lu.assertTrue(t[1].stop, "denner_transfer ends the conversation")
	lu.assertEquals(t[1].text, A.PREFIX .. "s_10ee338d", "the Denner line")
	lu.assertEquals(opens(A.pilot({ m = 3, t2 = { 1, 2, 3, 4 }, xp = COST })), "denner_transfer", "A8 precedes the offer, the training and the duties")
	lu.assertEquals(opens(A.pilot({ m = 3, xp = COST })), "denner_transfer", "A8 precedes the training offer")
end

-- A9
-- AC-6
function TestAlozenGates:test_mission_3_won_and_unpaid_opens_m3_won()
	lu.assertEquals(opens(A.pilot({ m = 2, state = "won" })), "m3_won", "M3 won")
	lu.assertEquals(opens(A.pilot({ m = 2, state = "won", t2 = { 1, 2, 3, 4 }, xp = COST })), "m3_won", "A9 precedes the M3 offer and the training")
end

-- A10
-- AC-6
function TestAlozenGates:test_a_failed_or_aborted_mission_3_opens_m3_failed()
	lu.assertEquals(opens(A.pilot({ m = 2, state = "failed" })), "m3_failed", "M3 failed or aborted")
	lu.assertEquals(opens(A.pilot({ m = 2, state = "failed", t2 = { 1, 2, 3, 4 } })), "m3_failed", "A10 precedes the M3 offer")
	lu.assertEquals(opens(A.pilot({ m = 2, state = "failed", xp = COST })), "m3_failed", "A10 precedes the training offer")
end

-- A11 (D-7)
-- AC-6
function TestAlozenGates:test_four_tier_2_skills_with_mission_2_paid_open_m3_offer()
	local t = A.talk(A.pilot({ m = 2, t2 = { 1, 2, 3, 4 } }))

	lu.assertEquals(A.ids(t), { "m3_offer" }, "four skills, M2 paid")
	lu.assertEquals(t[1].params.TU, "Ace", "m3_offer: %NU")
	lu.assertEquals(opens(A.pilot({ m = 2, t2 = { 1, 2, 3, 4 }, xp = COST })), "m3_offer", "A11 precedes the training offer")
	lu.assertEquals(opens(A.pilot({ m = 2, t2 = { 1, 2, 3 } })), "duty_block", "three skills are not enough")
end

-- A11 (D-7, FA-3): the NGE slip is fixed
-- AC-6
function TestAlozenGates:test_four_tier_2_skills_with_mission_2_unpaid_do_not_open_m3_offer()
	lu.assertEquals(opens(A.pilot({ m = 1, t2 = { 1, 2, 3, 4 } })), "m2_start", "M1 paid, M2 never started")
	lu.assertEquals(opens(A.pilot({ m = 0, t2 = { 1, 2, 3, 4 } })), "greeting", "nothing paid")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "won", t2 = { 1, 2, 3, 4 } })), "m2_won", "M2 won and unpaid: A14 before the M3 offer")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "failed", t2 = { 1, 2, 3, 4 } })), "m2_failed", "M2 failed")
	lu.assertEquals(opens(A.pilot({ m = 0, state = "won", t2 = { 1, 2, 3, 4 } })), "m1_won", "M1 won and unpaid")
end

-- A12
-- AC-6
function TestAlozenGates:test_m2_paid_with_the_xp_and_fewer_than_four_skills_opens_training_offer()
	local t = A.talk(A.pilot({ m = 2, xp = COST }))

	lu.assertEquals(A.ids(t), { "training_offer" }, "two skills, enough XP")
	lu.assertFalse(t[1].stop, "training_offer waits for a reply")
	lu.assertEquals(opens(A.pilot({ m = 2, xp = COST, t2 = { 1, 2, 3 } })), "training_offer", "three skills")
	lu.assertEquals(opens(A.pilot({ m = 2, xp = COST, t2 = { 3 } })), "training_offer", "one skill")
	lu.assertEquals(opens(A.pilot({ m = 2, xp = COST, t2 = {} })), "training_offer", "no tier 2 skill")
end

-- A12: training needs the XP, tier 1 and M2 paid
-- AC-6
function TestAlozenGates:test_training_offer_needs_the_xp_and_all_four_tier_1_skills()
	lu.assertEquals(opens(A.pilot({ m = 2, xp = COST - 1 })), "duty_block", "one XP short")
	lu.assertEquals(opens(A.pilot({ m = 2, xp = COST, t1 = false })), "duty_block", "no tier 1 skill")
	lu.assertEquals(opens(A.pilot({ m = 1, xp = COST })), "m2_start", "M2 unpaid: the offer is closed")
end

-- A13
-- AC-6
function TestAlozenGates:test_m2_paid_without_the_xp_opens_the_duty_block()
	local t = A.talk(A.pilot({ m = 2 }))

	lu.assertEquals(A.ids(t), { "duty_block" }, "M2 paid, no XP")
	lu.assertEquals(A.optionSids(t[1]), { "s_5a7ec1e4" }, "duty_block replies")
	lu.assertEquals(A.linksOf(t[1]), { "duty_menu" }, "duty_block links")
end

-- A14, A15
-- AC-6
function TestAlozenGates:test_mission_2_won_or_failed_opens_its_screen()
	lu.assertEquals(opens(A.pilot({ m = 1, state = "won" })), "m2_won", "M2 won")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "failed" })), "m2_failed", "M2 failed or aborted")
	lu.assertEquals(opens(A.pilot({ m = 1, state = "won", xp = COST })), "m2_won", "A14 precedes the training offer")
end

-- A16
-- AC-6, AC-8
function TestAlozenGates:test_mission_1_paid_and_mission_2_never_started_opens_m2_start()
	local t = A.talk(A.pilot({ m = 1 }))

	lu.assertEquals(A.ids(t), { "m2_start" }, "M1 paid, M2 never started")
	lu.assertTrue(t[1].stop, "m2_start ends the conversation")
end

-- A17, A18
-- AC-6
function TestAlozenGates:test_mission_1_won_or_failed_opens_its_screen()
	lu.assertEquals(opens(A.pilot({ state = "won" })), "m1_won", "M1 won")
	lu.assertEquals(opens(A.pilot({ state = "failed" })), "m1_failed", "M1 failed or aborted")
	lu.assertEquals(opens(A.pilot({ state = "won", alozen = false, initiate = false })), "m1_won", "A17 precedes the greeting, without any key")
end

-- A19
-- AC-6
function TestAlozenGates:test_a_fresh_storm_pilot_opens_the_greeting()
	local t = A.talk(A.pilot())

	lu.assertEquals(A.ids(t), { "greeting" }, "fresh pilot")
	lu.assertEquals(t[1].text, A.PREFIX .. "s_128d62a", "the greeting line")
	lu.assertFalse(t[1].stop, "the greeting waits for a reply")
end

-- A pilot with no key whatsoever reaches the greeting too
-- AC-6
function TestAlozenGates:test_a_pilot_with_no_alozen_or_initiate_key_opens_the_greeting()
	lu.assertEquals(opens(A.pilot({ alozen = false, initiate = false })), "greeting", "no key")
end

-- AC-6 (the helpers the spec names)
function TestAlozenGates:test_the_helpers_agree_with_the_rules()
	local h = handler()

	lu.assertFalse(h:isOnMission(A.pilot()), "isOnMission: nothing running")
	lu.assertTrue(h:isOnMission(A.pilot({ state = "active" })), "isOnMission: mission 1")
	lu.assertTrue(h:isOnMission(A.pilot({ m = 1, state = "active" })), "isOnMission: mission 2")

	for _, duty in ipairs(A.DUTIES) do
		local player = A.pilot({ m = 2 })

		A.setState(player, duty, "active")
		lu.assertTrue(h:isOnMission(player), "isOnMission: " .. duty)
	end

	lu.assertEquals(h:tier2Count(A.pilot({ t2 = { 1, 3, 4 } })), 3, "tier2Count")
	lu.assertTrue(h:isPaid(A.pilot({ m = 2 }), 2), "isPaid(2) with M2 paid")
	lu.assertFalse(h:isPaid(A.pilot({ m = 1 }), 2), "isPaid(2) with M2 unpaid")
	lu.assertFalse(h:isPaid(A.pilot({ m = 1, state = "won" }), 2), "isPaid(2) with M2 won and unpaid")

	lu.assertTrue(h:isReadyForTraining(A.pilot({ m = 2, xp = COST })) == true, "isReadyForTraining: M2 paid, XP")
	lu.assertFalse(h:isReadyForTraining(A.pilot({ m = 2, xp = COST - 1 })), "isReadyForTraining: one XP short")
	lu.assertFalse(h:isReadyForTraining(A.pilot({ m = 1, xp = COST })), "isReadyForTraining: M2 unpaid")
	lu.assertFalse(h:isReadyForTraining(A.pilot({ m = 2, xp = COST, t2 = { 1, 2, 3, 4 } })), "isReadyForTraining: four skills")
	lu.assertFalse(h:isReadyForTraining(A.pilot({ m = 2, xp = COST, t1 = false })), "isReadyForTraining: no tier 1 skills")

	lu.assertTrue(h:canFlyNonTrackDuty(A.pilot({ squadron = BLACK_EPSILON() })), "canFlyNonTrackDuty: all four tier 1 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(A.pilot({ squadron = BLACK_EPSILON(), t1 = false, t2 = {} })), "canFlyNonTrackDuty: no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(A.pilot({ squadron = BLACK_EPSILON(), datapad = "story" })), "canFlyNonTrackDuty: datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(A.pilot({ squadron = BLACK_EPSILON(), state = "active" })), "canFlyNonTrackDuty: mission 1 running")
end

---------------------------------------------------------------------------------------------
-- The greeting (C-1, AC-7)
---------------------------------------------------------------------------------------------

TestAlozenGreeting = {}

TestAlozenGreeting.setUp = setUp

-- AC-7, C-1, D-11
function TestAlozenGreeting:test_the_greeting_offers_the_replies_its_keys_allow_in_order()
	local cases = {
		{ "both keys", { alozen = true, initiate = true }, { "s_2eaae5bc", "s_53b0407b", "s_a73dd488" }, { "m1_late", "not_expected", "leave_alone" } },
		{ "initiate only", { alozen = false, initiate = true }, { "s_53b0407b", "s_a73dd488" }, { "not_expected", "leave_alone" } },
		{ "alozen only", { alozen = true, initiate = false }, { "s_2eaae5bc", "s_a73dd488" }, { "m1_late", "leave_alone" } },
		{ "neither", { alozen = false, initiate = false }, { "s_a73dd488" }, { "leave_alone" } },
	}

	for _, c in ipairs(cases) do
		local t = A.talk(A.pilot(c[2]))

		lu.assertEquals(A.ids(t), { "greeting" }, c[1] .. ": screens shown")
		lu.assertEquals(A.optionSids(t[1]), c[3], c[1] .. ": replies")
		lu.assertEquals(A.linksOf(t[1]), c[4], c[1] .. ": links")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[1] .. ": client strings")
	end
end

-- AC-7: the two side replies grant nothing and end
function TestAlozenGreeting:test_not_expected_and_leave_alone_grant_nothing_and_end()
	for _, c in ipairs({ { "s_53b0407b", "not_expected" }, { "s_a73dd488", "leave_alone" } }) do
		H.reset()

		local starts = A.spyStarts()
		local player = A.pilot()
		local before = snapshot(player)
		local t = A.talk(player, { c[1] })

		lu.assertEquals(A.ids(t), { "greeting", c[2] }, c[2] .. ": screens shown")
		lu.assertTrue(t[2].stop, c[2] .. " ends the conversation")
		lu.assertEquals(A.startedGlobals(starts), {}, c[2] .. ": nothing started")
		lu.assertEquals(player.bankCredits, 0, c[2] .. ": no credits")
		lu.assertEquals(A.items(player), {}, c[2] .. ": no item")
		lu.assertEquals(snapshot(player).state, before.state, c[2] .. ": no state change")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end
end

---------------------------------------------------------------------------------------------
-- Off track (C-2, C-3, I-12)
---------------------------------------------------------------------------------------------

TestAlozenOffTrack = {}

TestAlozenOffTrack.setUp = setUp

local ASK = "s_4854758d"

local function offTrack(o)
	local build = { squadron = BLACK_EPSILON(), m = 0 }

	for k, v in pairs(o or {}) do
		build[k] = v
	end

	return A.pilot(build)
end

local CLOSURE = {
	off_track = true, off_track_duties = true, off_track_never_mind = true, off_track_no_missions = true, duty_menu = true, duty_raiders = true, duty_escort = true,
	duty_salvage = true,
}

-- C-2
-- AC-6
function TestAlozenOffTrack:test_off_track_offers_the_duties_to_a_pilot_with_all_tier_1_skills_and_no_quest()
	local t = A.talk(offTrack(), { ASK })

	lu.assertEquals(A.ids(t), { "off_track", "off_track_duties" }, "all four tier 1 skills, empty datapad")
	lu.assertEquals(A.optionSids(t[2]), { "s_b84b366c", "s_aec16b0a" }, "off_track_duties replies")
	lu.assertEquals(A.linksOf(t[2]), { "duty_menu", "off_track_never_mind" }, "off_track_duties links")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-2
-- AC-6
function TestAlozenOffTrack:test_off_track_refuses_a_pilot_without_all_tier_1_skills()
	local t = A.talk(offTrack({ t1 = false, t2 = {} }), { ASK })

	lu.assertEquals(A.ids(t), { "off_track", "off_track_no_missions" }, "no tier 1 skill")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends the conversation")
	lu.assertEquals(A.ids(A.talk(offTrack({ t1 = false, t2 = {}, skills = { T.TIER1_SKILLS[1] } }), { ASK })), { "off_track", "off_track_no_missions" }, "one tier 1 skill")
	lu.assertEquals(A.ids(A.talk(offTrack({ t1 = false, t2 = {}, skills = { T.TIER1_SKILLS[1], T.TIER1_SKILLS[2], T.TIER1_SKILLS[3] } }), { ASK })), { "off_track", "off_track_no_missions" }, "three tier 1 skills")
end

-- C-2: off track and a duty running (not a datapad quest): A6 catches Alozen's own duties, so the link is the only guard for a duty of a squadron she does not know
-- AC-6
function TestAlozenOffTrack:test_off_track_refuses_while_an_alozen_duty_is_running_through_the_link_rule()
	local h = handler()
	local player = offTrack()

	A.setState(player, A.DUTY3, "active")
	lu.assertFalse(h:canFlyNonTrackDuty(player), "canFlyNonTrackDuty with her escort duty active")
end

-- AC-6: the duty menu off track starts exactly its duty
function TestAlozenOffTrack:test_the_off_track_duty_menu_offers_the_three_duties_only_and_starts_them()
	local t = A.talk(offTrack(), { ASK, "s_b84b366c" })

	lu.assertEquals(A.ids(t), { "off_track", "off_track_duties", "duty_menu" }, "screens shown")
	lu.assertEquals(A.optionSids(t[3]), { "s_8a202d7b", "s_d5ee9adc", "s_5950b85e" }, "duty_menu replies off track (no training, D-8)")
	lu.assertEquals(A.linksOf(t[3]), { "duty_raiders", "duty_escort", "duty_salvage" }, "duty_menu links off track")

	local cases = { { "s_8a202d7b", "duty_raiders", A.DUTY1 }, { "s_d5ee9adc", "duty_escort", A.DUTY3 }, { "s_5950b85e", "duty_salvage", A.DUTY2 } }

	for _, c in ipairs(cases) do
		H.reset()

		local starts = A.spyStarts()
		local player = offTrack()
		local run = A.talk(player, { ASK, "s_b84b366c", c[1] })

		lu.assertEquals(A.ids(run), { "off_track", "off_track_duties", "duty_menu", c[2] }, c[2] .. ": screens shown")
		lu.assertEquals(A.startedGlobals(starts), { c[3] .. " x1" }, c[2] .. ": exactly that duty starts")
		lu.assertEquals(starts[c[3]][1].args[1], player, c[2] .. ": startQuest got the pilot")
	end
end

-- AC-6, I-12: "Never mind" ends
function TestAlozenOffTrack:test_never_mind_ends_the_conversation()
	local t = A.talk(offTrack(), { ASK, "s_aec16b0a" })

	lu.assertEquals(A.ids(t), { "off_track", "off_track_duties", "off_track_never_mind" }, "screens shown")
	lu.assertTrue(t[3].stop, "off_track_never_mind ends the conversation")
end

-- I-12: everything reachable from off_track (a pilot with all tier 1 skills reaches the duties, one without reaches the refusal)
local function closureOf(build)
	local queue, visited = { {} }, {}

	while #queue > 0 do
		local path = table.remove(queue, 1)

		H.reset()

		local starts = A.spyStarts()
		local t = A.talk(build(), path)
		local last = t[#t]

		lu.assertTrue(CLOSURE[last.id] == true, "screen '" .. last.id .. "' reached from off_track along " .. table.concat(path, ","))

		for _, g in ipairs(A.GLOBALS) do
			if g ~= A.DUTY1 and g ~= A.DUTY2 and g ~= A.DUTY3 then
				lu.assertEquals(#starts[g], 0, g .. " started along " .. table.concat(path, ","))
			end
		end

		if not visited[last.id] then
			visited[last.id] = true

			for k = 0, #last.options - 1 do
				local nextPath = { table.unpack(path) }

				nextPath[#nextPath + 1] = k
				queue[#queue + 1] = nextPath
			end
		end
	end

	return visited
end

function TestAlozenOffTrack:test_every_screen_reachable_from_off_track_is_in_the_closure_and_only_the_duties_start()
	local seen = closureOf(function() return offTrack() end)

	for id in pairs(closureOf(function() return offTrack({ t1 = false, t2 = {} }) end)) do
		seen[id] = true
	end

	lu.assertEquals(seen, CLOSURE, "screens reachable from off_track")
end
