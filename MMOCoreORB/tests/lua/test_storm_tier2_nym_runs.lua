-- Storm tier 2, the Nym technicians: the Kimogila's Claw run for real (granted by the Zabrak, failed, aborted, retried, won) and the whole chain from
-- Oberhaur's Morv briefing to his payment.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-8, AC-9; Conversation flow 4; Q-2 = A; R-4; D-3, D-4).
--
-- The quest runs through the harness fakes (real SpaceAssassinateScreenplay, real SpaceHelpers journal): the pilot sits in a fake ship in space_lok, so the
-- grant on "long gone" begins the run at once (outside the zone it starts on arrival, see the ground test). Each step pumps the event clock inside pcall first,
-- so a Lua error inside an event shows up as "no Lua error".

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local CS = require("harness.client_strings")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local MORV, DECOY, ZABRAK = 1, 2, 3
local GRANT = { "s_7002e5c4", "s_4d5276b" }
local RETRY = { "s_248faf8a" }
local TIP_WALK = { "s_67a590c3", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9", "s_b8779a78" }

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function setUp()
	H.reset()
	N.load()
	N.requireAll(lu)
end

local function claw() return T.quest(T.M3) end

-- A Storm pilot in a ship in space_lok at the given stage; the quest table is started (patrol points, observers) first
local function inLok(stage, extra)
	local q = claw()

	q:start()

	local o = { stage = stage, inShip = true, zone = "space_lok" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return N.pilot(o), q
end

local function isActive(player) return SpaceHelpers:isSpaceQuestActive(player, "assassinate", "imperial_ss_3") end
local function isComplete(player) return SpaceHelpers:isSpaceQuestComplete(player, "assassinate", "imperial_ss_3") end

-- Grants the Claw at the Zabrak, deploys the target and lets the 20-minute timer run out: the run fails
local function grantAndFail(player, q)
	N.talk(ZABRAK, player, GRANT)
	pump(0, "start")
	pump(35000, "deployTargets")
	lu.assertEquals(#H.spawnedShips(), 4, "precondition: the target and three escorts spawned")
	pump(q.failTimer * 60 * 1000 + 5000, "the timer runs out")
end

local function pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { N.optionSids(step)[i], o.link }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-8: active
---------------------------------------------------------------------------------------------

TestStormNymRunActive = {}

TestStormNymRunActive.setUp = setUp
TestStormNymRunActive.tearDown = function() AC.tearDown() end

-- AC-8: an active Claw: where did you say -> long gone again starts no second run
function TestStormNymRunActive:test_asking_the_zabrak_again_during_a_run_starts_no_second_run()
	local player, q = inLok("tipped")

	N.talk(ZABRAK, player, GRANT)
	pump(0, "start")
	lu.assertEquals(N.claw(player), "active", "precondition: the run is active")

	local starts = H.spyOn(q, "startQuest")
	local datapad = #player.datapad.items
	local before = N.snapshot(player)
	local t = N.talk(ZABRAK, player, RETRY)

	lu.assertEquals(N.ids(t), { "you_again", "long_gone" }, "screens shown")
	lu.assertEquals(#starts, 0, "no second startQuest")
	lu.assertEquals(N.snapshot(player), before, "no state change")
	lu.assertEquals(#player.datapad.items, datapad, "still one mission in the datapad")
	lu.assertEquals(N.attempted(player), "1", "attempted unchanged")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "active", "stage")
end

-- AC-8: Morv during a run
function TestStormNymRunActive:test_morv_during_a_run_offers_the_pair_and_the_tip_changes_nothing()
	local player = inLok("tipped")

	N.talk(ZABRAK, player, GRANT)

	local before = N.snapshot(player)
	local t = N.talk(MORV, player, { "s_81e175a9", "s_b8779a78" })

	lu.assertEquals(N.ids(t), { "back_again", "find_zabrak", "take_off" }, "screens shown")
	lu.assertEquals(pairsOf(t[1]), { { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } }, "back_again options")
	lu.assertEquals(N.snapshot(player), before, "no state change")
end

-- AC-7, AC-8: granted on the ground, the run begins on arriving in Lok (the observer the real startQuest creates)
function TestStormNymRunActive:test_granted_on_the_ground_the_run_begins_when_the_pilot_arrives_in_lok()
	local q = claw()

	q:start()

	local player = N.pilot({ stage = "tipped" })

	N.talk(ZABRAK, player, GRANT)
	pump(0, "start")
	lu.assertEquals(N.claw(player), "active", "the journal entry is active on the ground")
	pump(60000, "a minute on the ground")
	lu.assertEquals(#H.spawnedShips(), 0, "nothing spawns before the pilot is in Lok")

	H.zoneSwitch(player, "space_lok", { ship = true })
	pump(35000, "arrival and deployTargets")
	lu.assertEquals(#H.spawnedShips(), 4, "the target and three escorts spawn after the arrival delay")
end

---------------------------------------------------------------------------------------------
-- AC-8: failed and aborted
---------------------------------------------------------------------------------------------

TestStormNymRunFailed = {}

TestStormNymRunFailed.setUp = setUp
TestStormNymRunFailed.tearDown = function() AC.tearDown() end

-- AC-8, R-4: a run that times out is stage failed (attempted, no journal entry), Oberhaur still says find_morv
function TestStormNymRunFailed:test_a_run_that_times_out_leaves_stage_failed_and_oberhaur_at_find_morv()
	local player, q = inLok("tipped")

	grantAndFail(player, q)
	lu.assertFalse(isActive(player), "the run is over")
	lu.assertFalse(isComplete(player), "a failed run is not a win")
	lu.assertEquals(N.attempted(player), "1", "attempted stays")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "failed", "getClawStage after the failure")
	lu.assertEquals(T.firstScreen(player), "find_morv", "Oberhaur still asks for Morv (the finding key stays)")
end

-- AC-8: Morv then offers the failure report first; the walk ends without a grant
function TestStormNymRunFailed:test_morv_offers_the_failure_report_and_does_not_restart_the_claw()
	local player, q = inLok("tipped")

	grantAndFail(player, q)

	local starts = H.spyOn(q, "startQuest")
	local t = N.talk(MORV, player, { "s_7d114e8" })

	lu.assertEquals(pairsOf(t[1]), { { "s_7d114e8", "keep_trying" }, { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } }, "back_again options")
	lu.assertEquals(N.ids(t), { "back_again", "keep_trying" }, "screens shown")
	lu.assertTrue(N.last(t).stop, "keep_trying ends")
	lu.assertEquals(#starts, 0, "Morv does not restart the Claw (Q-2 = A)")
	lu.assertEquals(N.claw(player), "none", "no run")
end

-- AC-8, Q-2 = A: the Zabrak's "Where did you say" starts the Claw again, with a clean journal entry
function TestStormNymRunFailed:test_the_zabrak_starts_the_claw_again_after_a_failed_run()
	local player, q = inLok("tipped")

	grantAndFail(player, q)

	local t = N.talk(ZABRAK, player, RETRY)

	lu.assertEquals(pairsOf(N.talk(ZABRAK, N.pilot({ stage = "failed" }))[1]), { { "s_248faf8a", "long_gone" }, { "s_52fbe706", "clear_out" } }, "precondition: you_again offers the retry line")
	lu.assertEquals(N.ids(t), { "you_again", "long_gone" }, "screens shown")
	lu.assertTrue(isActive(player), "the Claw is active again")
	lu.assertFalse(isComplete(player), "the old entry is cleared")
	lu.assertEquals(N.attempted(player), "1", "attempted stays set")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "active", "stage")
	lu.assertEquals(T.firstScreen(player), "on_mission", "Oberhaur shows on_mission again")
end

-- AC-8: the retried run can be flown to the end
function TestStormNymRunFailed:test_the_retried_run_spawns_its_ships_and_can_be_won()
	local player, q = inLok("tipped")

	grantAndFail(player, q)
	H.reset()
	N.load()

	-- the failed run's ships are gone with the reset above; build the failed pilot again and fly the retry
	local q2 = claw()

	q2:start()

	local again = N.pilot({ stage = "failed", inShip = true, zone = "space_lok" })

	N.talk(ZABRAK, again, RETRY)
	pump(0, "retry start")
	pump(35000, "retry deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 4, "the retry spawns the target and three escorts")

	for i = 1, 4 do
		H.destroyShip(ships[i], again.rootParent)
		pump(1500, "kill " .. i)
	end

	pump(3000, "after the last kill")
	lu.assertTrue(isComplete(again), "the retried Claw is complete")
	lu.assertEquals(N.squadron(lu):getClawStage(again), "won", "stage after the win")
end

-- AC-8: an abort (datapad) is a failure too: stage failed, Oberhaur at find_morv, the retry works
function TestStormNymRunFailed:test_an_aborted_run_is_stage_failed_and_can_be_retried()
	local player, q = inLok("tipped")

	N.talk(ZABRAK, player, GRANT)
	pump(0, "start")
	lu.assertTrue(isActive(player), "precondition: the Claw runs")
	H.abortMission(player, "assassinate", "imperial_ss_3")
	pump(0, "after the abort")
	lu.assertFalse(isActive(player), "the abort ended the run")
	lu.assertEquals(N.attempted(player), "1", "attempted stays")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "failed", "stage after the abort")
	lu.assertEquals(T.firstScreen(player), "find_morv", "Oberhaur still asks for Morv")

	local t = N.talk(ZABRAK, player, RETRY)

	lu.assertEquals(N.ids(t), { "you_again", "long_gone" }, "the retry")
	lu.assertTrue(isActive(player), "the Claw is active again")
end

---------------------------------------------------------------------------------------------
-- AC-8: won
---------------------------------------------------------------------------------------------

TestStormNymRunWon = {}

TestStormNymRunWon.setUp = setUp

-- AC-8: Oberhaur opens claw_won and after claw_pay all three technicians are ambient again
function TestStormNymRunWon:test_after_the_claw_is_paid_all_three_technicians_are_ambient_again()
	local player = N.pilot({ stage = "won" })

	lu.assertEquals(T.firstScreen(player), "claw_won", "Oberhaur once the Claw is won")

	local before = { "back_again", "greeting_agent", "you_again" }

	for n = 1, 3 do
		lu.assertEquals(N.firstScreen(n, player), before[n], N.CONVOS[n].role .. " before the payment")
	end

	T.talk(player, { "s_e44ffcd2", "s_198d54a6" })
	lu.assertEquals(H.getQuestStatus(player, T.STATUS[3] .. ":reward"), "1", "the :reward key")

	for n = 1, 3 do
		lu.assertEquals(N.firstScreen(n, player), "greeting", N.CONVOS[n].role .. " after claw_pay")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: end to end
---------------------------------------------------------------------------------------------

TestStormNymEndToEnd = {}

TestStormNymEndToEnd.setUp = setUp
TestStormNymEndToEnd.tearDown = function() AC.tearDown() end

-- AC-9: Oberhaur's m3_offer -> m3_codephrase, Morv's briefing, the Zabrak's grant, the run, Oberhaur's payment
function TestStormNymEndToEnd:test_a_storm_pilot_walks_from_oberhaur_to_morv_to_the_zabrak_flies_the_claw_and_is_paid()
	local player = inLok("none")

	-- 1. before the briefing every technician is ambient
	for n = 1, 3 do
		lu.assertEquals(N.firstScreen(n, player), "greeting", N.CONVOS[n].role .. " before Oberhaur's briefing")
	end

	-- 2. Oberhaur: m3_offer -> m3_codephrase sets the finding key
	local t = T.talk(player, { "s_6abf6436", "s_fb7f6474", "s_edeedb42", "s_746fbd0c" })

	lu.assertEquals(T.ids(t), { "m3_offer", "m3_agent_report", "m3_find_out", "m3_codephrase", "m3_good_luck" }, "Oberhaur's briefing")
	lu.assertEquals(H.getQuestStatus(player, T.FINDING_SUFFIX), "1", "the finding key")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "briefed", "stage after the briefing")
	lu.assertEquals(T.firstScreen(player), "find_morv", "Oberhaur now says find Morv")

	-- 3. the decoy and the Zabrak (untipped) give nothing; Morv briefs
	lu.assertEquals(pairsOf(N.talk(DECOY, player)[1])[1], { "s_67a590c3", "snaff_grease" }, "the decoy offers the phrases")
	lu.assertEquals(N.talk(ZABRAK, player)[1].id, "greeting_agent", "the Zabrak (untipped)")
	lu.assertEquals(N.optionSids(N.talk(ZABRAK, player)[1]), { "s_67a590c3", "s_62f865dd", "s_f49a789f", "s_88d98675" }, "no fuel-balance line yet")

	local morv = N.talk(MORV, player, TIP_WALK)

	lu.assertEquals(N.last(morv).id, "take_off", "Morv's briefing ends")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "tipped", "stage after Morv's tip")

	-- 4. the Zabrak grants the Claw
	local zabrak = N.talk(ZABRAK, player, GRANT)

	lu.assertEquals(N.ids(zabrak), { "greeting_agent", "balance_perfect", "long_gone" }, "the Zabrak's grant walk")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "active", "stage after the grant")
	lu.assertEquals(T.firstScreen(player), "on_mission", "Oberhaur during the run")

	-- 5. the run, in space_lok, without a Lua error
	pump(0, "the Claw's start")
	pump(29000, "before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, "nothing spawns before the 30 s arrival delay")
	pump(5000, "deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 4, "the capo ship and three enforcers")

	for i = 1, 4 do
		lu.assertFalse(isComplete(player), "not complete before kill " .. i)
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, "after kill " .. i)
	end

	pump(3000, "after the last kill")
	lu.assertTrue(isComplete(player), "the Claw is complete")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "won", "stage after the win")

	-- 6. Oberhaur pays 5000, the ion booster and +75 standing once, and the walk goes on to claw_next_step
	local pay = T.talk(player, { "s_e44ffcd2", "s_198d54a6", "s_94999d7b" })

	lu.assertEquals(T.ids(pay), { "claw_won", "claw_impressive", "claw_pay", "claw_next_step" }, "Oberhaur's report")
	lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits")
	lu.assertEquals(T.items(player), { T.ITEMS[T.M3] }, "the ion booster")
	lu.assertEquals(player.ghost.factionStanding.imperial, T.STANDING, "standing")
	lu.assertEquals(CS.transcriptUnresolved(pay), {}, "client strings")

	T.drive(player, "claw_pay")
	lu.assertEquals(player.bankCredits, T.CREDITS, "a second report pays nothing")

	-- 7. all three technicians are ambient again
	for n = 1, 3 do
		lu.assertEquals(N.firstScreen(n, player), "greeting", N.CONVOS[n].role .. " after claw_pay")
	end
end
