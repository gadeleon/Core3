-- Storm tier 3 part A: the escort wave split (SC-1, Q-2 = A) and the regression tests that every other escort is unchanged.
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (A-3, I-9; Shared code changes SC-1; FD-3, FD-4; D-A3, D-A4; R-4).
--
-- escort_tatooine_imperial_tier3_3_a is an ATTACK_WAVE escort: when the player has destroyed all ships of the 3rd attack wave the escort hands off
-- 10 s later (the escort and attack ships leave, the journal entry completes without a client notification, the surprise attack 3_d starts); reaching
-- the last point first FAILS the escort (SWG destroyIsSuccess); reaching it while the split is pending neither fails nor completes it (D-A3).
-- Every other escort (COMPLETION / none / the escort duties) keeps completing at its last point, however many waves were cleared (I-9).
--
-- The runs are driven through the fakes: the event clock, ENTEREDAREA for the escort, SHIPDESTROYED for each attack ship. The wave counter's shared-memory
-- key `<playerID>:<className>:wavesCleared:` is pinned by the spec (D-A4, SC-1 point 4); two tests seed and read it.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local D = require("storm_tier3_data")
local I2 = require("storm_tier1_data")

D.load()

local ESCORT_3A = D.M3[3]
local SURPRISE_3D = D.M3[4]
local ESCORT_1 = D.M1[1]
local RECOVERY_1A = D.M1[2]

local function quest(global) return D.quest(global) end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end
local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end

local function failedCrcs(player)
	local out = {}

	for _, crc in ipairs(player.failedMissions) do
		out[crc] = true
	end

	return out
end

local function hasFailed(player, q) return failedCrcs(player)[H.questCrc(q.questType, q.questName)] == true end

-- the ships of `list` that are still in the world
local function liveAmong(list)
	local out = {}

	for _, ship in ipairs(list) do
		if not ship.destroyed then
			out[#out + 1] = ship
		end
	end

	return out
end

-- a copy of the ships spawned so far (the escort and every attack wave of a run)
local function shipsSoFar()
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		out[i] = ship
	end

	return out
end

local function wavesKey(run) return run.player.objectID .. ":" .. run.q.className .. ":wavesCleared:" end

-- The escort run: startQuest in the quest zone, setupEscort (2 s), the pilot reaches the rendezvous, the escort ship spawns (5 s) and is given its points
-- (5 s later). `player` is optional (a restart for the same pilot). Returns the run.
local function fly(q, player)
	player = player or D.flyer(q.questZone)

	q:startQuest(player, "")
	pump(2500, q.className .. " setup")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertTrue(start >= 1, q.className .. ": setupEscort chose a start point")
	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, q.className .. " escort spawn and points")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, q.className .. ": the escort ship spawned")

	return { q = q, player = player, escort = escort }
end

-- A fresh world with the escort's static areas and the pilot flying the escort
local function escortRun(global)
	local q = quest(global)

	H.reset()
	q:start()

	return fly(q)
end

-- Waits for the next attack wave and returns its ships (the ships spawned since the call, the escort excluded)
local function nextWave(run)
	local before = #H.spawnedShips()

	for _ = 1, 130 do
		pump(1000, run.q.className .. " waiting for an attack wave")

		if #H.spawnedShips() > before then
			break
		end
	end

	local ships = {}

	for i = before + 1, #H.spawnedShips() do
		ships[#ships + 1] = H.spawnedShips()[i]
	end

	lu.assertTrue(#ships > 0, run.q.className .. ": an attack wave spawned within 130 s")

	return ships
end

local function clear(run, ships)
	for _, ship in ipairs(ships) do
		H.destroyShip(ship, run.player.ship)
	end

	pump(0, run.q.className .. " wave cleared")
end

-- Waits for a wave and destroys all its ships; returns the ships
local function clearWave(run)
	local ships = nextWave(run)

	clear(run, ships)

	return ships
end

-- The escort flies through the last area(s) of its path (one ENTEREDAREA per remaining point), like the server does at the end of the route
local function arrive(run)
	local progress = readData(run.escort.objectID .. ":" .. run.q.className .. ":escortShipProgress:")

	lu.assertTrue(progress >= 1, run.q.className .. ": the escort still has points to fly (progress " .. progress .. ")")

	for _ = 1, progress do
		H.enterArea(H.spawnedAreas()[1], run.escort)
	end
end

local function hasTauntContaining(player, text)
	for _, t in ipairs(H.tauntLog(player)) do
		if tostring(t.msg):find(text, 1, true) then
			return true
		end
	end

	return false
end

-- What the client sees when a quest is won: the "Mission Successful" system message of this quest and the victory music
local function victoryFor(player, q)
	local messages = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_won" and m.TO == "@spacequest/" .. q.questType .. "/" .. q.questName .. ":title" then
			messages[#messages + 1] = m.TO
		end
	end

	local music = 0

	for _, file in ipairs(player.music) do
		if file == "sound/music_themequest_victory_rebel.snd" then
			music = music + 1
		end
	end

	return messages, music
end

local function crcOf(q) return H.questCrc(q.questType, q.questName) end

---------------------------------------------------------------------------------------------
-- A-3: the ATTACK_WAVE escort
---------------------------------------------------------------------------------------------

TestStormT3EscortWave = {}

function TestStormT3EscortWave:setUp() H.reset() end

function TestStormT3EscortWave:tearDown() AC.tearDown() end

-- A-3 (setup): the run reaches the spawned escort and the first attack wave of three ships
function TestStormT3EscortWave:test_the_run_spawns_the_decoy_shuttle_and_a_first_wave_of_bwing_and_two_xwings()
	local run = escortRun(ESCORT_3A)
	local wave = nextWave(run)
	local names = {}

	for i, ship in ipairs(wave) do
		names[i] = ship.shipName
	end

	lu.assertEquals(run.escort.shipName, "imp_lambda_decoy_shuttle_tier3", ESCORT_3A .. ": the escort ship")
	lu.assertEquals(names, { "reb_bwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3" }, ESCORT_3A .. ": the attack wave")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": active")
end

-- A-3: clearing waves 1 and 2 starts nothing
function TestStormT3EscortWave:test_clearing_waves_1_and_2_starts_nothing()
	local run = escortRun(ESCORT_3A)

	clearWave(run)
	pump(20000, "after wave 1")
	clearWave(run)
	pump(20000, "after wave 2")

	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": still active after two cleared waves")
	lu.assertFalse(isActive(run.player, quest(SURPRISE_3D)), SURPRISE_3D .. ": not started after two cleared waves")
	lu.assertFalse(run.escort.destroyed == true, "the escort is still flying")
	lu.assertEquals(#H.pendingEvents() > 0, true, "the run is still going (events pending)")
end

-- A-3: clearing wave 3 schedules the split; 10 s later the escort leaves, the entry completes silently, the surprise attack is active
function TestStormT3EscortWave:test_clearing_wave_3_hands_off_10_seconds_later_to_the_surprise_attack_without_a_client_notification()
	local run = escortRun(ESCORT_3A)
	local surprise = quest(SURPRISE_3D)

	clearWave(run)
	pump(20000, "after wave 1")
	clearWave(run)
	pump(20000, "after wave 2")

	local wave3 = clearWave(run)
	local flying = shipsSoFar() -- the escort and the attack ships of the run (the surprise attack's ships come later)

	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": right after the third cleared wave the escort is still running (10 s delay)")
	pump(9000, "9 s after wave 3")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": still active 9 s after the third cleared wave")
	lu.assertFalse(isActive(run.player, surprise), SURPRISE_3D .. ": not started 9 s after the third cleared wave")
	lu.assertFalse(run.escort.destroyed == true, "the escort is still there 9 s after the third cleared wave")
	pump(3000, "12 s after wave 3")

	lu.assertTrue(isComplete(run.player, run.q), ESCORT_3A .. ": complete 12 s after the third cleared wave")
	lu.assertTrue(isActive(run.player, surprise), SURPRISE_3D .. ": active 12 s after the third cleared wave")
	lu.assertFalse(hasFailed(run.player, run.q), ESCORT_3A .. ": not failed")

	local messages, music = victoryFor(run.player, run.q)

	lu.assertEquals(messages, {}, ESCORT_3A .. ": no 'Mission Successful' message (completeQuest(pPlayer, \"false\"): the split completes the entry silently)")
	lu.assertEquals(music, 0, ESCORT_3A .. ": no victory music")

	pump(4000, "the ships leave")
	lu.assertEquals(#wave3, 3, "precondition: wave 3 had three ships")
	lu.assertEquals(#liveAmong(flying), 0, "the escort and the attack ships are gone (despawnShips) after the hand-off")
	lu.assertTrue(#H.spawnedShips() > #flying, "the surprise attack spawned its own ships")
end

-- A-3: the split alert
function TestStormT3EscortWave:test_the_split_sends_the_escorts_split_quest_alert()
	local run = escortRun(ESCORT_3A)

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(12000, "the split")

	local alerts = {}

	for _, m in ipairs(H.messageLog(run.player)) do
		if m.id == "@space/quest:quest_alert_s" then
			alerts[#alerts + 1] = m.TO
		end
	end

	lu.assertEquals(alerts, { "@spacequest/escort/tatooine_imperial_tier3_3_a:split_quest_alert" }, "the Mission Alert the split sends")
end

-- A-3: the surprise attack is started once, by the split
function TestStormT3EscortWave:test_the_surprise_attack_is_started_exactly_once_and_the_escort_run_is_over()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(12000, "the split")
	pump(200000, "long after")
	lu.assertEquals(#starts, 1, SURPRISE_3D .. ": startQuest calls")
	lu.assertEquals(starts[1].args[1], run.player, SURPRISE_3D .. ": started for the pilot")
	lu.assertFalse(isActive(run.player, run.q), ESCORT_3A .. ": no longer active (no second split, no new attack wave)")
end

-- A-3: a fourth clear does nothing (the counter is past 3)
function TestStormT3EscortWave:test_a_fourth_cleared_wave_does_not_split()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	writeData(wavesKey(run), 3) -- three waves were cleared earlier (D-A4: <playerID>:<className>:wavesCleared:)
	clearWave(run)
	pump(30000, "after the fourth cleared wave")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": startQuest calls after a fourth cleared wave")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": still active")
	lu.assertEquals(readData(wavesKey(run)), 4, "the counter counts on")
end

-- A-3: the count is the number of cleared waves, one per wave (a partly cleared wave counts nothing)
function TestStormT3EscortWave:test_a_wave_counts_only_when_every_one_of_its_ships_is_destroyed()
	local run = escortRun(ESCORT_3A)
	local wave = nextWave(run)

	H.destroyShip(wave[1], run.player.ship)
	H.destroyShip(wave[2], run.player.ship)
	pump(0, "two of three ships down")
	lu.assertEquals(readData(wavesKey(run)), 0, "two of three ships destroyed: no wave cleared yet")
	H.destroyShip(wave[3], run.player.ship)
	pump(0, "the wave is down")
	lu.assertEquals(readData(wavesKey(run)), 1, "all three ships destroyed: one wave cleared")
end

-- A-3: wave ships removed by the quest itself (not killed) do not count
function TestStormT3EscortWave:test_two_cleared_waves_and_then_wave_ships_leaving_without_a_kill_do_not_count_as_a_third()
	local run = escortRun(ESCORT_3A)

	clearWave(run)
	clearWave(run)
	nextWave(run) -- the third wave spawns and is left alone
	lu.assertEquals(readData(wavesKey(run)), 2, "two cleared waves")
	pump(8000, "the third wave is flying")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": active")
	lu.assertFalse(isActive(run.player, quest(SURPRISE_3D)), SURPRISE_3D .. ": not started")
end

-- A-3: the escort arrives before wave 3 is cleared: the escort fails, the surprise attack does not start
function TestStormT3EscortWave:test_reaching_the_last_point_with_no_wave_cleared_fails_the_escort_and_starts_nothing()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	arrive(run)
	pump(4000, "after the arrival")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": not complete (SWG destroyIsSuccess: arrival is a failure)")
	lu.assertFalse(isActive(run.player, run.q), ESCORT_3A .. ": no longer active")
	lu.assertTrue(hasFailed(run.player, run.q), ESCORT_3A .. ": failed (the datapad mission was failed)")
	pump(30000, "long after")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": startQuest calls")
	lu.assertTrue(hasTauntContaining(run.player, "tatooine_imperial_tier3_3_a:goodbye_"), "the escort's goodbye line (the client's failure line) is played")
end

-- A-3: ... also with two waves cleared
function TestStormT3EscortWave:test_reaching_the_last_point_after_two_cleared_waves_still_fails()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	clearWave(run)
	clearWave(run)
	arrive(run)
	pump(4000, "after the arrival")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": not complete")
	lu.assertTrue(hasFailed(run.player, run.q), ESCORT_3A .. ": failed")
	pump(30000, "long after")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": startQuest calls")
end

-- A-3, D-A3: the escort arrives while the split is pending: neither failed nor completed before the split, which then ends the run
function TestStormT3EscortWave:test_reaching_the_last_point_while_the_split_is_pending_neither_fails_nor_completes_it_before_the_split()
	local run = escortRun(ESCORT_3A)
	local surprise = quest(SURPRISE_3D)

	for _ = 1, 3 do
		clearWave(run)
		pump(1000, "between waves")
	end

	-- wave 3 was cleared about a second ago; the split fires in about 9 s
	local flying = shipsSoFar()

	arrive(run)
	pump(3000, "after the arrival")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": still active after arriving while the split is pending")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": not completed by the arrival")
	lu.assertFalse(hasFailed(run.player, run.q), ESCORT_3A .. ": not failed by the arrival (D-A3)")
	lu.assertFalse(isActive(run.player, surprise), SURPRISE_3D .. ": not started before the split")

	pump(10000, "the split")
	lu.assertTrue(isComplete(run.player, run.q), ESCORT_3A .. ": the split completes it")
	lu.assertTrue(isActive(run.player, surprise), SURPRISE_3D .. ": the split starts the surprise attack")
	lu.assertFalse(hasFailed(run.player, run.q), ESCORT_3A .. ": never failed")
	pump(10000, "afterwards")
	lu.assertEquals(#liveAmong(flying), 0, "no escort or attack ship is left after the split")
end

-- A-3: the escort ship destroyed fails the escort as for every escort
function TestStormT3EscortWave:test_the_escort_ship_destroyed_fails_the_escort_as_before()
	local run = escortRun(ESCORT_3A)

	clearWave(run)
	H.destroyShip(run.escort, nil)
	pump(3000, "after the loss")
	lu.assertTrue(hasFailed(run.player, run.q), ESCORT_3A .. ": failed when the decoy shuttle is destroyed")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": not complete")
	pump(30000, "long after")
	lu.assertFalse(isActive(run.player, quest(SURPRISE_3D)), SURPRISE_3D .. ": not started")
end

-- A-3: an abort clears the counter; the restarted run needs three new clears
function TestStormT3EscortWave:test_an_abort_clears_the_wave_counter_and_the_restarted_run_needs_three_new_clears()
	local run = escortRun(ESCORT_3A)
	local surprise = quest(SURPRISE_3D)

	clearWave(run)
	clearWave(run)
	lu.assertEquals(readData(wavesKey(run)), 2, "two cleared waves before the abort")
	H.abortMission(run.player, run.q.questType, run.q.questName)
	pump(3000, "after the abort")
	lu.assertEquals(readData(wavesKey(run)), 0, "the abort deletes the wave counter")

	-- the same pilot flies it again
	local again = fly(run.q, run.player)

	clearWave(again)
	pump(20000, "after the first new wave")
	clearWave(again)
	pump(20000, "after the second new wave")
	lu.assertTrue(isActive(again.player, again.q), ESCORT_3A .. ": two new clears do not split the restarted run")
	lu.assertFalse(isActive(again.player, surprise), SURPRISE_3D .. ": not started after two new clears")
	clearWave(again)
	pump(12000, "the split")
	lu.assertTrue(isComplete(again.player, again.q), ESCORT_3A .. ": the third new clear splits it")
	lu.assertTrue(isActive(again.player, surprise), SURPRISE_3D .. ": started")
end

-- A-3: a reset clears the counter too (the squadron surrender resets every table)
function TestStormT3EscortWave:test_a_reset_clears_the_wave_counter()
	local run = escortRun(ESCORT_3A)

	clearWave(run)
	lu.assertEquals(readData(wavesKey(run)), 1, "one cleared wave")
	run.q:resetQuest(run.player)
	pump(3000, "after the reset")
	lu.assertEquals(readData(wavesKey(run)), 0, "the reset deletes the wave counter")
	lu.assertFalse(isActive(run.player, run.q), ESCORT_3A .. ": not active after the reset")
end

-- A-3: a failed run clears the counter too
function TestStormT3EscortWave:test_a_failed_run_clears_the_wave_counter()
	local run = escortRun(ESCORT_3A)

	clearWave(run)
	arrive(run)
	pump(4000, "after the failing arrival")
	lu.assertTrue(hasFailed(run.player, run.q), ESCORT_3A .. ": failed")
	lu.assertEquals(readData(wavesKey(run)), 0, "failure deletes the wave counter")
end

-- A-3: an abort in the window between the third clear and the split stops the split
function TestStormT3EscortWave:test_an_abort_while_the_split_is_pending_cancels_the_hand_off()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(2000, "inside the window")
	H.abortMission(run.player, run.q.questType, run.q.questName)
	pump(30000, "after the window")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": startQuest calls after an abort inside the window")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": an aborted escort is not completed by the stale split")
	lu.assertEquals(readData(wavesKey(run)), 0, "the counter stays cleared")
end

-- R-3: a split event of an earlier run (abort inside the 10 s window, restart) must not hand off the new run
function TestStormT3EscortWave:test_a_stale_split_event_does_not_hand_off_a_restarted_run()
	local run = escortRun(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(2000, "inside the window")
	H.abortMission(run.player, run.q.questType, run.q.questName)
	pump(500, "after the abort")

	local stale = 0

	for _, e in ipairs(H.pendingEvents()) do
		if e.method == "triggerAttackWaveSplit" then stale = stale + 1 end
	end

	lu.assertEquals(stale, 1, "precondition: the split event of the aborted run is still pending")

	-- the same pilot starts the escort again; the old event is still due about 8 s later, while the new run is active with no wave cleared
	run.q:startQuest(run.player, "")
	pump(12000, "the stale split event fires")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_3A .. ": the restarted run is still active after the stale split event")
	lu.assertFalse(isComplete(run.player, run.q), ESCORT_3A .. ": the restarted run is not completed by the stale split event")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": startQuest calls (the stale event must not hand off the new run)")
	lu.assertEquals(readData(wavesKey(run)), 0, "the new run has cleared no wave")
end

-- A-3: the split handler is safe to call at any time
function TestStormT3EscortWave:test_the_split_handler_ignores_a_nil_player_and_a_quest_that_is_not_active()
	local q = quest(ESCORT_3A)
	local starts = H.spyOn(quest(SURPRISE_3D), "startQuest")
	local player = D.flyer()

	lu.assertEquals(pcall(q.triggerAttackWaveSplit, q, nil), true, "triggerAttackWaveSplit(nil) returns")
	lu.assertEquals(pcall(q.triggerAttackWaveSplit, q, player), true, "triggerAttackWaveSplit on an inactive quest returns")
	pump(5000, "afterwards")
	lu.assertEquals(#starts, 0, SURPRISE_3D .. ": nothing started")
	lu.assertFalse(isComplete(player, q), ESCORT_3A .. ": an inactive escort is not completed")
end

-- A-3, R-4: overlapping waves (a new wave spawns before the previous one is cleared) count once per full clear of the merged ship list
function TestStormT3EscortWave:test_overlapping_waves_count_as_one_clear_when_the_whole_merged_list_is_destroyed()
	local run = escortRun(ESCORT_3A)
	local first = nextWave(run)
	local second = nextWave(run) -- the second wave spawns while the first is still alive

	clear(run, first)
	lu.assertEquals(readData(wavesKey(run)), 0, "the second wave is still alive: no wave cleared yet (R-4)")
	clear(run, second)
	lu.assertEquals(readData(wavesKey(run)), 1, "both waves down: one clear (R-4: a pilot may need to destroy more than three waves of ships)")
end

---------------------------------------------------------------------------------------------
-- I-9: every other escort is unchanged
---------------------------------------------------------------------------------------------

TestStormT3EscortRegression = {}

function TestStormT3EscortRegression:setUp() H.reset() end

function TestStormT3EscortRegression:tearDown() AC.tearDown() end

-- I-9 (static): every escort table in bin/scripts other than 3_a keeps a non-ATTACK_WAVE split and the default count
function TestStormT3EscortRegression:test_no_other_escort_table_uses_the_attack_wave_split()
	AC.load()

	local ATTACK_WAVE = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.ATTACK_WAVE
	local escorts, seen = {}, {}

	lu.assertNotNil(ATTACK_WAVE, "SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.ATTACK_WAVE")

	for _, entry in ipairs(DRS.quests()) do
		local q = entry.quest

		if q.startQuest == SpaceEscortScreenplay.startQuest or q.questType == "escort" or q.questType == "escort_duty" then
			escorts[#escorts + 1] = entry
		end
	end

	for _, entry in ipairs(escorts) do
		local q = entry.quest

		seen[#seen + 1] = entry.global

		if entry.global == ESCORT_3A then
			lu.assertEquals({ q.sideQuestSplitType, q.sideQuestAttackWave }, { ATTACK_WAVE, 3 }, entry.global)
		else
			lu.assertNotEquals(q.sideQuestSplitType, ATTACK_WAVE, entry.global .. ": sideQuestSplitType")
			lu.assertEquals(q.sideQuestAttackWave, 0, entry.global .. ": sideQuestAttackWave is the default 0")
		end
	end

	lu.assertTrue(#seen >= 30, "found the escort and escort duty tables of every squadron: " .. #seen)
end

-- I-9: the COMPLETION escort of the same mission set (escort 1) completes at its last point and starts recovery 1_a after the 20 s split delay (R-1), however many waves were cleared
function TestStormT3EscortRegression:test_escort_1_still_completes_at_its_last_point_after_three_cleared_waves_and_splits_to_recovery_1_a()
	local run = escortRun(ESCORT_1)
	local starts = H.spyOn(quest(RECOVERY_1A), "startQuest")

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(30000, "three cleared waves")
	lu.assertTrue(isActive(run.player, run.q), ESCORT_1 .. ": three cleared waves split nothing")
	lu.assertEquals(#starts, 0, RECOVERY_1A .. ": not started by wave clears")
	arrive(run)
	pump(1100, "the escort arrived")
	lu.assertTrue(isComplete(run.player, run.q), ESCORT_1 .. ": completes at its last point")
	lu.assertFalse(hasFailed(run.player, run.q), ESCORT_1 .. ": not failed")
	pump(10000, "before the split delay")
	lu.assertEquals(#starts, 0, RECOVERY_1A .. ": not started 11 s after the arrival (sideQuestDelay 20)")
	pump(15000, "the split")
	lu.assertEquals(#starts, 1, RECOVERY_1A .. ": started once, after the 20 s delay")
	lu.assertEquals(readData(wavesKey(run)), 0, "completion deletes the wave counter")
end

-- I-9: the same with no wave cleared
function TestStormT3EscortRegression:test_escort_1_completes_at_its_last_point_with_no_wave_cleared()
	local run = escortRun(ESCORT_1)

	arrive(run)
	pump(3000, "the escort arrived")
	lu.assertTrue(isComplete(run.player, run.q), ESCORT_1 .. ": completes at its last point")
	lu.assertFalse(hasFailed(run.player, run.q), ESCORT_1 .. ": not failed")
end

-- I-9: an existing squadron escort without any split (Alozen's escort_imperial_ss_5) completes at its last point after any number of cleared waves
function TestStormT3EscortRegression:test_an_existing_escort_without_a_split_completes_at_its_last_point_whatever_the_waves()
	for _, waves in ipairs({ 0, 1, 3 }) do
		local run = escortRun("escort_imperial_ss_5")

		for _ = 1, waves do
			clearWave(run)
		end

		pump(5000, "waves cleared: " .. waves)
		arrive(run)
		pump(3000, "the escort arrived")
		lu.assertTrue(isComplete(run.player, run.q), "escort_imperial_ss_5 with " .. waves .. " cleared waves: completes at its last point")
		lu.assertFalse(hasFailed(run.player, run.q), "escort_imperial_ss_5 with " .. waves .. " cleared waves: not failed")
	end
end

-- I-9: Colzet's escort_tatooine_imperial_3 (a COMPLETION escort of another squadron file) behaves the same
function TestStormT3EscortRegression:test_tier_1_escort_3_still_completes_at_its_last_point_after_three_cleared_waves()
	local run = escortRun(I2.E3)

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(30000, "three cleared waves")
	lu.assertTrue(isActive(run.player, run.q), I2.E3 .. ": three cleared waves end nothing")
	arrive(run)
	pump(3000, "the escort arrived")
	lu.assertTrue(isComplete(run.player, run.q), I2.E3 .. ": completes at its last point")
end

-- I-9: an escort that is not ATTACK_WAVE still fails when its ship is destroyed
function TestStormT3EscortRegression:test_an_existing_escort_still_fails_when_the_escort_ship_is_destroyed()
	local run = escortRun("escort_imperial_ss_5")

	H.destroyShip(run.escort, nil)
	pump(3000, "after the loss")
	lu.assertTrue(hasFailed(run.player, run.q), "escort_imperial_ss_5: failed when the escort ship is destroyed")
end

-- I-9: wave clears of an escort duty are counted harmlessly and never split (escort duties share SpaceEscortScreenplay.notifyAttackShipDestroyed)
function TestStormT3EscortRegression:test_an_escort_duty_clearing_waves_splits_nothing_and_raises_no_error()
	local run = escortRun(I2.DUTY7)

	for _ = 1, 3 do
		clearWave(run)
	end

	pump(30000, "three cleared waves")
	lu.assertTrue(isActive(run.player, run.q), I2.DUTY7 .. ": still running after three cleared waves")

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.method, "triggerAttackWaveSplit", I2.DUTY7 .. ": no wave split is ever scheduled for a duty")
	end
end

-- R-2: the escort duty's own reset clears the wave counter too
function TestStormT3EscortRegression:test_an_escort_duty_reset_clears_the_wave_counter()
	local run = escortRun(I2.DUTY7)

	clearWave(run)
	clearWave(run)
	lu.assertEquals(readData(wavesKey(run)), 2, I2.DUTY7 .. ": two cleared waves before the reset")
	run.q:resetDutyMission(run.player)
	pump(1000, "after the duty reset")
	lu.assertEquals(readData(wavesKey(run)), 0, I2.DUTY7 .. ": resetDutyMission deletes the wave counter")
end

return nil
