-- Kiizete: which screen a player opens on (gate table G1-G8) and mission 1's state as she reads it.
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (AC-3, AC-6; Content contract 3; Conversation flow 1; FK-7; D-6, D-7).
--
-- One test per gate row: a player built to meet that row and none above it opens on the listed screen. K.gate asks getInitialScreen (which
-- must be side-effect free, I-3); K.opens talks, running the on-display actions. The builder is vortex_tier1_data.lua V.pilot (via K.player).
-- Mission 1 failures are made through the real quest tables (failQuest / abortQuest / the datapad abort), as test_vortex_tier1_signup_missions.lua.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("vortex_tier1_data")
local K = require("vortex_tier1_kiizete_data")
local CS = require("harness.client_strings")

K.load()

local function setUp()
	H.reset()
	K.requireConversation(lu)
end

local function gate(player) return K.gate(player) end

TestVortexKiizeteGates = {}

TestVortexKiizeteGates.setUp = setUp

-- G0
-- AC-3
function TestVortexKiizeteGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = K.player(), K.npc(), H.conversationTemplate(K.TEMPLATE)
	local h = K.handler()

	lu.assertNil(h:getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(h:getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(h:getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-3
function TestVortexKiizeteGates:test_jtl_disabled_opens_no_jtl()
	H.Engine.config.jtlEnabled = false

	local t = K.talk(K.player())

	lu.assertEquals(K.ids(t), { "no_jtl" }, "JTL disabled")
	lu.assertEquals(K.optionSids(t[1]), { "s_ee55c9ed", "s_7fa15433" }, "the two questions")
	lu.assertFalse(t[1].stop, "no_jtl offers replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3
function TestVortexKiizeteGates:test_a_player_without_a_player_object_opens_no_jtl()
	local player = K.player()

	player.ghost = nil
	lu.assertEquals(gate(player), "no_jtl", "ghost is nil (SWG !hasSpaceExpansion)")
end

-- AC-3: the JTL gate comes before everything (G1 precedes G2-G8)
function TestVortexKiizeteGates:test_jtl_disabled_beats_every_other_gate()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(gate(K.player({ pilot = false, faction = "imperial", squadron = false })), "no_jtl", "an Imperial non-pilot")
	lu.assertEquals(gate(K.player({ state = "active" })), "no_jtl", "mission 1 active")
	lu.assertEquals(gate(K.player({ state = "failed" })), "no_jtl", "mission 1 failed")
	lu.assertEquals(gate(K.player({ paid = 1 })), "no_jtl", "mission 1 won")

	local flagged = K.player({ faction = "imperial" })

	K.squadron():setKiizeteFlag(flagged, K.IMP_KEY)
	lu.assertEquals(gate(flagged), "no_jtl", "the Imperial flag is set: G1 precedes G2")
end

-- G2
-- AC-3
function TestVortexKiizeteGates:test_the_imperial_flag_opens_imperial_again_before_the_faction_gate()
	local imperial = K.player({ faction = "imperial" })

	K.squadron():setKiizeteFlag(imperial, K.IMP_KEY)
	lu.assertEquals(gate(imperial), "imperial_again", "an Imperial with the flag")

	local onMission = K.player({ state = "active" })

	K.squadron():setKiizeteFlag(onMission, K.IMP_KEY)
	lu.assertEquals(gate(onMission), "imperial_again", "a first-mission pilot with the Imperial flag: G2 precedes G4 and G5")
end

-- G3
-- AC-3
function TestVortexKiizeteGates:test_an_imperial_faction_non_pilot_opens_imperial_pilot()
	local t = K.talk(K.player({ pilot = false, faction = "imperial", squadron = false }))

	lu.assertEquals(K.ids(t), { "imperial_pilot" }, "an Imperial-faction non-pilot")
	lu.assertEquals(K.optionSids(t[1]), { "s_9ddf5e8a", "s_7fa15433", "s_5e15545" }, "the three questions")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3
function TestVortexKiizeteGates:test_a_neutral_faction_imperial_novice_opens_imperial_pilot()
	lu.assertEquals(gate(K.player({ pilot = "imperial", faction = "neutral", squadron = false })), "imperial_pilot", "an Imperial novice with no faction")
	lu.assertEquals(gate(K.player({ pilot = "imperial", faction = "rebel", squadron = false })), "imperial_pilot", "an Imperial novice with Rebel faction")
end

-- AC-3: G3 precedes G5-G7 (an Imperial who is also a Vortex pilot)
function TestVortexKiizeteGates:test_the_imperial_gate_precedes_the_mission_1_gates()
	lu.assertEquals(gate(K.player({ faction = "imperial", state = "active" })), "imperial_pilot", "Imperial faction, mission 1 active")
	lu.assertEquals(gate(K.player({ faction = "imperial", state = "failed" })), "imperial_pilot", "Imperial faction, mission 1 failed")
	lu.assertEquals(gate(K.player({ faction = "imperial", paid = 1 })), "imperial_pilot", "Imperial faction, mission 1 won")
end

-- G4
-- AC-3
function TestVortexKiizeteGates:test_the_first_mission_flag_opens_first_mission_again_before_the_mission_gates()
	local function flagged(o)
		local p = K.player(o)

		K.squadron():setKiizeteFlag(p, K.Q1_KEY)
		return p
	end

	lu.assertEquals(gate(flagged({ state = "active" })), "first_mission_again", "flag and mission 1 active: G4 precedes G5")
	lu.assertEquals(gate(flagged({ state = "failed" })), "first_mission_again", "flag and mission 1 failed: G4 precedes G6")
	lu.assertEquals(gate(flagged({ paid = 1 })), "first_mission_again", "flag and mission 1 won: G4 precedes G7")
	lu.assertEquals(gate(flagged({ pilot = false, squadron = false, faction = "neutral" })), "first_mission_again", "flag on a stranger: G4 precedes G8")
end

-- G5
-- AC-3
function TestVortexKiizeteGates:test_a_vortex_pilot_with_mission_1_active_and_a_ship_opens_first_mission()
	local t = K.talk(K.player({ state = "active" }))

	lu.assertEquals(K.ids(t), { "first_mission" }, "mission 1 patrol active, a certified ship")
	lu.assertEquals(K.optionSids(t[1]), { "s_b41e5c00", "s_8bf64edf", "s_1162efff" }, "the three replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3: the surprise attack being active counts as mission 1 being active (SWG hasQuest on either quest)
function TestVortexKiizeteGates:test_the_surprise_attack_being_active_also_opens_first_mission()
	local player = K.player({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "active")
	lu.assertEquals(gate(player), "first_mission", "patrol complete, surprise attack active")
end

-- AC-3: without a certified ship the active mission does not open it
function TestVortexKiizeteGates:test_mission_1_active_without_a_certified_ship_opens_stranger()
	lu.assertEquals(gate(K.player({ state = "active", ship = false })), "stranger", "no certified ship")
end

-- AC-3: first_mission is not squadron-gated (SWG checks the quest and the ship only)
function TestVortexKiizeteGates:test_first_mission_is_open_to_any_faction_that_is_not_imperial()
	lu.assertEquals(gate(K.player({ state = "active", faction = "neutral" })), "first_mission", "no faction, mission 1 active")
	lu.assertEquals(gate(K.player({ state = "active", squadron = false })), "first_mission", "no squadron, mission 1 active")
end

-- G6
-- AC-3, AC-6
function TestVortexKiizeteGates:test_mission_1_attempted_and_not_won_opens_mission1_failed()
	local t = K.talk(K.player({ state = "failed" }))

	lu.assertEquals(K.ids(t), { "mission1_failed" }, "mission 1 attempted, nothing active, nothing complete")
	lu.assertEquals(K.optionSids(t[1]), { "s_77e48d5b", "s_5df1433d" }, "the two replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G7
-- AC-3, AC-6
function TestVortexKiizeteGates:test_both_mission_1_quests_complete_opens_mission1_won()
	local t = K.talk(K.player({ paid = 1 }))

	lu.assertEquals(K.ids(t), { "mission1_won" }, "mission 1 won and paid")
	lu.assertEquals(K.optionSids(t[1]), { "s_4bd66142", "s_ce894b84", "s_93f420a0" }, "the three replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(gate(K.player({ state = "won" })), "mission1_won", "mission 1 won, reward not paid yet")
end

-- AC-3, Conversation flow 1: winners get G7 at every later tier
function TestVortexKiizeteGates:test_a_mission_1_winner_opens_mission1_won_at_every_later_tier()
	lu.assertEquals(gate(K.player({ paid = 2 })), "mission1_won", "two missions paid")
	lu.assertEquals(gate(K.player({ paid = 4, tier = 4, graduated = true })), "mission1_won", "a graduate")
	lu.assertEquals(gate(K.player({ paid = 4, tier = 4, graduated = true, ship = false })), "mission1_won", "a graduate without a ship")
end

-- G8
-- AC-3
function TestVortexKiizeteGates:test_a_neutral_non_pilot_opens_stranger()
	local t = K.talk(K.player({ pilot = false, faction = "neutral", squadron = false }))

	lu.assertEquals(K.ids(t), { "stranger" }, "a non-pilot without faction")
	lu.assertEquals(K.optionSids(t[1]), { "s_e518378e", "s_17edec66" }, "the two replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3: everyone else is a stranger: a neutral pilot, a Havoc pilot, a Corsec pilot, a Vortex pilot who has not started mission 1
function TestVortexKiizeteGates:test_everyone_else_opens_stranger()
	lu.assertNotNil(rawget(_G, "HAVOC_SQUADRON"), "the HAVOC_SQUADRON constant")
	lu.assertEquals(gate(K.player({ pilot = "neutral", squadron = false })), "stranger", "a neutral pilot")
	lu.assertEquals(gate(K.player({ squadron = rawget(_G, "HAVOC_SQUADRON") })), "stranger", "a Havoc pilot")
	lu.assertEquals(gate(K.player({ pilot = "neutral", squadron = rawget(_G, "CORSEC_SQUADRON") })), "stranger", "a CorSec pilot")
	lu.assertEquals(gate(K.player({})), "stranger", "a Vortex pilot who has not started mission 1")
	lu.assertEquals(gate(K.player({ ship = false })), "stranger", "a Vortex pilot without a ship and without a mission")
	lu.assertEquals(gate(K.player({ pilot = false, faction = "rebel", squadron = false })), "stranger", "a Rebel non-pilot")
end

-- AC-3: each gate row is reached by a player that meets no row above it (the ids of all eight rows)
function TestVortexKiizeteGates:test_the_eight_gate_rows_open_eight_different_screens()
	H.Engine.config.jtlEnabled = false

	local seen = { gate(K.player()) }

	H.Engine.config.jtlEnabled = true

	local imperial = K.player({ faction = "imperial" })

	K.squadron():setKiizeteFlag(imperial, K.IMP_KEY)
	seen[#seen + 1] = gate(imperial)
	seen[#seen + 1] = gate(K.player({ faction = "imperial" }))

	local q1 = K.player({ state = "active" })

	K.squadron():setKiizeteFlag(q1, K.Q1_KEY)
	seen[#seen + 1] = gate(q1)
	seen[#seen + 1] = gate(K.player({ state = "active" }))
	seen[#seen + 1] = gate(K.player({ state = "failed" }))
	seen[#seen + 1] = gate(K.player({ paid = 1 }))
	seen[#seen + 1] = gate(K.player({}))

	lu.assertEquals(seen, { "no_jtl", "imperial_again", "imperial_pilot", "first_mission_again", "first_mission", "mission1_failed", "mission1_won", "stranger" }, "G1..G8")
end

---------------------------------------------------------------------------------------------
-- The handler's helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestVortexKiizeteHelpers = {}

TestVortexKiizeteHelpers.setUp = setUp

-- Content contract 3 (JK:16-27, D-7)
function TestVortexKiizeteHelpers:test_is_imperial_is_the_imperial_faction_or_an_imperial_novice()
	local h = K.handler()

	lu.assertTrue(h:isImperial(K.player({ pilot = false, faction = "imperial", squadron = false })), "Imperial faction, not a pilot")
	lu.assertTrue(h:isImperial(K.player({ pilot = "imperial", faction = "neutral", squadron = false })), "Imperial novice, no faction")
	lu.assertTrue(h:isImperial(K.player({ pilot = "imperial", faction = "rebel", squadron = false })), "Imperial novice, Rebel faction")
	lu.assertFalse(h:isImperial(K.player({})), "a Rebel Vortex pilot")
	lu.assertFalse(h:isImperial(K.player({ pilot = false, faction = "neutral", squadron = false })), "a neutral non-pilot")
	lu.assertFalse(h:isImperial(K.player({ pilot = "neutral", squadron = false })), "a neutral pilot")
end

-- Content contract 3 (JK:40-50): a certified ship and an active mission 1 chain
function TestVortexKiizeteHelpers:test_is_on_first_mission_needs_a_ship_and_an_active_mission_1_chain()
	local h = K.handler()

	lu.assertTrue(h:isOnFirstMission(K.player({ state = "active" })), "patrol active, ship")
	lu.assertFalse(h:isOnFirstMission(K.player({ state = "active", ship = false })), "patrol active, no ship")
	lu.assertFalse(h:isOnFirstMission(K.player({})), "no mission")
	lu.assertFalse(h:isOnFirstMission(K.player({ state = "failed" })), "mission 1 failed")
	lu.assertFalse(h:isOnFirstMission(K.player({ paid = 1 })), "mission 1 won")

	local player = K.player({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "active")
	lu.assertTrue(h:isOnFirstMission(player), "surprise attack active")
end

-- Content contract 3 (V3H won[1]): both quests complete
function TestVortexKiizeteHelpers:test_has_won_mission_one_needs_both_quests_complete()
	local h = K.handler()

	lu.assertTrue(h:hasWonMissionOne(K.player({ paid = 1 })), "both complete")
	lu.assertTrue(h:hasWonMissionOne(K.player({ state = "won" })), "both complete, unpaid")
	lu.assertFalse(h:hasWonMissionOne(K.player({})), "nothing")

	local patrolOnly = K.player({ state = "failed" })

	I.setState(patrolOnly, I.P1, "complete")
	lu.assertFalse(h:hasWonMissionOne(patrolOnly), "only the patrol complete")

	local surpriseOnly = K.player({ state = "failed" })

	I.setState(surpriseOnly, I.S1, "complete")
	lu.assertFalse(h:hasWonMissionOne(surpriseOnly), "only the surprise attack complete")
end

-- Content contract 3 (V3H failed[1], FK-7): attempted, not won, not active
function TestVortexKiizeteHelpers:test_has_failed_mission_one_is_attempted_and_neither_won_nor_active()
	local h = K.handler()

	lu.assertTrue(h:hasFailedMissionOne(K.player({ state = "failed" })), "attempted, nothing else")
	lu.assertFalse(h:hasFailedMissionOne(K.player({})), "never attempted")
	lu.assertFalse(h:hasFailedMissionOne(K.player({ state = "active" })), "attempted and active")
	lu.assertFalse(h:hasFailedMissionOne(K.player({ state = "won" })), "attempted and won")
	lu.assertFalse(h:hasFailedMissionOne(K.player({ paid = 1 })), "attempted, won and paid")

	local patrolWon = K.player({ state = "failed" })

	I.setState(patrolWon, I.P1, "complete")
	lu.assertTrue(h:hasFailedMissionOne(patrolWon), "patrol complete, surprise attack never won (D-6, FK-7)")
end

---------------------------------------------------------------------------------------------
-- AC-6: mission 1 failed, aborted or lost through the real quests; V3-FX and Kiizete agree
---------------------------------------------------------------------------------------------

TestVortexKiizeteMission1 = {}

TestVortexKiizeteMission1.setUp = setUp

function TestVortexKiizeteMission1:tearDown() AC.tearDown() end

-- AC-6: the player ended the run and nothing is active, won, rewarded or restarted by Kiizete
local function assertFailedState(player, label)
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_1:attempted"), "1", label .. ": :attempted")
	lu.assertEquals(I.state(player, I.P1), "none", label .. ": patrol 1 is neither active nor complete")
	lu.assertEquals(I.state(player, I.S1), "none", label .. ": the surprise attack is neither active nor complete")
end

-- AC-6
function TestVortexKiizeteMission1:test_a_failed_patrol_opens_mission1_failed_and_changes_nothing()
	local q, player = K.runningMission1()

	q:failQuest(player, true)
	assertFailedState(player, "patrol failed")

	local before = K.snapshot(player)

	lu.assertEquals(K.gate(player), "mission1_failed", "getInitialScreen")
	lu.assertEquals(K.opens(player), "mission1_failed", "the talk")
	lu.assertEquals(K.snapshot(player), before, "a talk to Kiizete changes nothing (:attempted, :reward, journal, skills, calls)")
	lu.assertEquals(I.state(player, I.P1), "none", "Kiizete does not restart the mission")
end

-- AC-6: the datapad abort
function TestVortexKiizeteMission1:test_an_aborted_patrol_opens_mission1_failed()
	local _, player = K.runningMission1()

	H.abortMission(player, "patrol", "naboo_rebel_1")
	assertFailedState(player, "patrol aborted from the datapad")
	lu.assertEquals(K.opens(player), "mission1_failed", "the talk")
	lu.assertNil(H.getQuestStatus(player, "naboo_rebel_1:reward"), ":reward is not set by an abort or by the talk")
end

-- AC-6: the quest's own abort
function TestVortexKiizeteMission1:test_a_patrol_aborted_through_the_quest_opens_mission1_failed()
	local q, player = K.runningMission1()

	q:abortQuest(player)
	assertFailedState(player, "patrol aborted")
	lu.assertEquals(K.opens(player), "mission1_failed", "the talk")
end

-- AC-6, FK-7: the patrol is won, the surprise attack starts and is lost: SWG's check named a missing quest, Core3 counts it as failed (T1 D-6)
function TestVortexKiizeteMission1:test_a_lost_surprise_attack_opens_mission1_failed()
	local q, player = K.runningMission1()
	local s1 = I.quest(I.S1)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	H.advance(14000)
	lu.assertEquals(I.state(player, I.S1), "active", "precondition: the surprise attack started after point 2 and 13 s")
	lu.assertEquals(K.gate(player), "first_mission", "while the surprise attack runs")

	s1:failQuest(player, true)
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack run ended")
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_1:attempted"), "1", ":attempted")

	local before = K.snapshot(player)

	lu.assertEquals(K.opens(player), "mission1_failed", "the next talk: the failure line")
	lu.assertEquals(K.snapshot(player), before, "a talk to Kiizete changes nothing")
end

-- AC-6: both quests complete, through the completion path
function TestVortexKiizeteMission1:test_both_quests_complete_open_mission1_won()
	local _, player = K.runningMission1()

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "complete")
	lu.assertEquals(K.gate(player), "mission1_won", "patrol and surprise attack complete")
end

-- AC-6: attempted, the chain active, but no certified ship: G5 needs the ship, G6 needs nothing active, so she is a stranger
function TestVortexKiizeteMission1:test_attempted_with_the_chain_active_and_no_ship_opens_stranger()
	local _, player = K.runningMission1()

	player.certifiedShip = false
	lu.assertEquals(I.state(player, I.P1), "active", "precondition: the chain is active")
	lu.assertEquals(K.gate(player), "stranger", "active, no ship, attempted")
end

-- I-5, D-6: V3-FX opens the same screen for the same failed pilot, before and after a talk to Kiizete (her talk never touches mission 1)
function TestVortexKiizeteMission1:test_v3_fx_and_kiizete_agree_about_a_failed_pilot_and_her_talk_does_not_move_v3_fx()
	local q, player = K.runningMission1()

	q:failQuest(player, true)

	local function v3fxGate() return rawget(_G, I.HANDLER):getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE)).id end

	lu.assertEquals(v3fxGate(), "mission1_failed", "V3-FX's gate for the failed pilot")
	lu.assertEquals(K.opens(player), "mission1_failed", "Kiizete's gate for the same pilot")
	lu.assertEquals(v3fxGate(), "mission1_failed", "V3-FX's gate after Kiizete's talk")
end
