-- Surprise attacks (all 19 of CorSec, RSF and Havoc): the run is "in progress" once the attackers spawned (SC-1), leaving the
-- zone during the run fails it (SC-2), and ships of an earlier run do not count against a new one (SC-3).
-- Spec: .claude/work/space-surprise-attack-fixes/01-spec.md (AC-1 to AC-6, AC-8, invariants I-3 to I-7, decisions D-9 to D-11).
--
-- SWG: script/space/quest_logic/destroy_surpriseattack.java:51-77, 139 (initializedQuestPlayer, _setQuestInProgress).
--
--   * spawn           -> journal task 0 complete and task 1 active, `<pid><className>:spawned` and `:runID` written
--   * leave the zone  -> only when `:spawned` is set and task 0 is complete: failQuest 2000 ms later, no parent fail, no split
--   * restart         -> shared memory is gone (no `:spawned`), the journal is kept: leaving does not fail, re-entry respawns
--   * run guard       -> a kill of a previous run's ship removes the mission object and counts nothing
--
-- Every quest is discovered at run time (questType == "destroy_surpriseattack") and gets its own test, named after the global.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local Engine = H.Engine

local E3 = "destroy_surpriseattack_naboo_privateer_tier3_3e"
local CS1 = "destroy_surpriseattack_corellia_privateer_1"
local FAIL_MUSIC = "sound/music_themequest_fail_criminal.snd"

local function quest(global) return H.expectGlobal(global, "surprise attack quest table") end

local function surpriseAttacks()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		if rawget(_G, name).questType == "destroy_surpriseattack" then
			out[#out + 1] = name
		end
	end

	return out
end

local GLOBALS = surpriseAttacks()

local function totalShips(q)
	local n = 0

	for _, entry in ipairs(q.surpriseAttackShips.spawns) do
		n = n + entry.count
	end

	return n
end

local function spawnCalls() return Engine.callsTo("spawnShipAgent") end

local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end
local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function task0Complete(player, q) return SpaceHelpers:isSpaceQuestTaskComplete(player, q.questType, q.questName, 0) end
local function task0Active(player, q) return SpaceHelpers:isSpaceQuestTaskActive(player, q.questType, q.questName, 0) end
local function task1Active(player, q) return SpaceHelpers:isSpaceQuestTaskActive(player, q.questType, q.questName, 1) end

-- A space zone the quest is not in
local function otherZone(q)
	if q.questZone == "space_naboo" then
		return "space_lok"
	end

	return "space_naboo"
end

-- Does the shared memory hold the key <pid><className><suffix>?
local function hasKey(player, q, suffix)
	local want = "|" .. player.objectID .. q.className .. suffix

	for _, key in ipairs(Engine.sharedMemoryKeys()) do
		if key == want then
			return true
		end
	end

	return false
end

-- A pilot in a ship in `zone` who starts `global` (the quest's own startQuest, as a split or trainer does).
local function started(global, zone)
	H.reset()

	local q = quest(global)
	local player = H.newPlayer({ name = "Ace", zone = zone or q.questZone, ship = true, pilot = "neutral" })

	q:startQuest(player, "")

	return q, player
end

local function copyShips()
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		out[i] = ship
	end

	return out
end

local function messagesSince(player, n)
	local out = {}

	for i, m in ipairs(H.messageLog(player)) do
		if i > n then
			out[#out + 1] = m
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Discovery
---------------------------------------------------------------------------------------------

TestSurpriseAttackFixesDiscovery = {}

-- Invariants: table-driven over the 19 globals
function TestSurpriseAttackFixesDiscovery:test_the_three_squadrons_define_19_surprise_attacks()
	lu.assertEquals(#GLOBALS, 19, "destroy_surpriseattack quest tables of CorSec, Havoc and RSF")
end

---------------------------------------------------------------------------------------------
-- AC-1 (SC-1, D-11): the spawn switches the journal tasks
---------------------------------------------------------------------------------------------

TestSurpriseAttackInProgress = {}

function TestSurpriseAttackInProgress:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-1
	TestSurpriseAttackInProgress["test_" .. global .. "_has_task_0_complete_and_task_1_active_once_the_attackers_spawned"] = function()
		local q, player = started(global)

		lu.assertEquals(#spawnCalls(), totalShips(q), global .. ": precondition: the attackers spawned in startQuest")
		lu.assertTrue(isActive(player, q), global .. ": active")
		lu.assertTrue(task0Complete(player, q), global .. ": journal task 0 complete")
		lu.assertFalse(task0Active(player, q), global .. ": journal task 0 no longer active")
		lu.assertTrue(task1Active(player, q), global .. ": journal task 1 active")
		lu.assertEquals(readData(player.objectID .. q.className .. ":spawned"), 1, global .. ": :spawned")
		lu.assertTrue(hasKey(player, q, ":runID"), global .. ": <pid><className>:runID written at the spawn")
	end
end

-- AC-1: I-3, the run is pending until the pilot is in the zone
function TestSurpriseAttackInProgress:test_a_run_started_in_lok_keeps_task_0_active_until_the_attackers_spawn_in_naboo()
	local q, player = started(E3, "space_lok")

	lu.assertTrue(isActive(player, q), "3e is active")
	lu.assertTrue(task0Active(player, q), "pending: journal task 0 active")
	lu.assertFalse(task0Complete(player, q), "pending: journal task 0 not complete")
	lu.assertFalse(task1Active(player, q), "pending: journal task 1 not active")
	H.advance(10000)
	lu.assertTrue(task0Active(player, q) and not task0Complete(player, q), "still pending after 10 s in Lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(999)
	lu.assertFalse(task0Complete(player, q), "task 0 not complete 999 ms after the switch (nothing spawned yet)")
	H.advance(1)

	lu.assertEquals(#spawnCalls(), 5, "precondition: the ambush spawned")
	lu.assertTrue(task0Complete(player, q), "task 0 complete after the spawn")
	lu.assertTrue(task1Active(player, q), "task 1 active after the spawn")
end

---------------------------------------------------------------------------------------------
-- AC-2 (SC-2): leaving the zone during the run fails it 2000 ms later
---------------------------------------------------------------------------------------------

TestSurpriseAttackLeaveZoneFails = {}

function TestSurpriseAttackLeaveZoneFails:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-2
	TestSurpriseAttackLeaveZoneFails["test_" .. global .. "_fails_2000_ms_after_the_pilot_leaves_the_zone_with_the_abandoned_messages"] = function()
		local q, player = started(global)

		lu.assertTrue(hasKey(player, q, ":spawned") and hasKey(player, q, ":Count") and hasKey(player, q, ":runID"),
			global .. ": precondition: :spawned, :Count and :runID are set")

		local messages, music = #H.messageLog(player), #player.music

		H.zoneSwitch(player, otherZone(q), { ship = true })
		H.advance(1999)
		lu.assertTrue(isActive(player, q), global .. ": still active 1999 ms after the switch")
		lu.assertEquals(#messagesSince(player, messages), 0, global .. ": no message before the delay is over")
		H.advance(1)

		lu.assertFalse(isActive(player, q), global .. ": not active 2000 ms after the switch")
		lu.assertFalse(isComplete(player, q), global .. ": not complete")

		local sent = messagesSince(player, messages)
		local got = {}

		for i, m in ipairs(sent) do
			got[i] = { m.id, m.TO }
		end

		lu.assertEquals(got, {
			{ "@space/quest:quest_update_s", "@space/quest:destroy_surprise_abandoned" },
			{ "@space/quest:quest_failed", "@spacequest/destroy_surpriseattack/" .. q.questName .. ":title" },
		}, global .. ": messages after the switch")

		local played = {}

		for i = music + 1, #player.music do
			played[#played + 1] = player.music[i]
		end

		lu.assertEquals(played, { FAIL_MUSIC }, global .. ": music after the switch")

		lu.assertFalse(hasKey(player, q, ":spawned"), global .. ": :spawned key left")
		lu.assertFalse(hasKey(player, q, ":Count"), global .. ": :Count key left")
		lu.assertFalse(hasKey(player, q, ":runID"), global .. ": <pid><className>:runID key left")
		lu.assertFalse(H.hasObserver(ZONESWITCHED, q.className, "enteredZone", player), global .. ": zone observer dropped")

		H.advance(30000)
		lu.assertEquals(H.pendingEvents(), {}, global .. ": events pending after the fail")
		lu.assertEquals(#messagesSince(player, messages), 2, global .. ": nothing more is sent later")
	end
end

-- AC-2: a landing (a switch to a ground zone) fails the same way
function TestSurpriseAttackLeaveZoneFails:test_landing_on_corellia_fails_the_run_2000_ms_later()
	local q, player = started(CS1)

	H.zoneSwitch(player, "corellia")
	H.advance(1999)
	lu.assertTrue(isActive(player, q), "active 1999 ms after the landing")
	H.advance(1)

	lu.assertFalse(isActive(player, q), "not active 2000 ms after the landing")
	lu.assertFalse(isComplete(player, q), "not complete")
	lu.assertFalse(hasKey(player, q, ":spawned"), ":spawned key left")
end

-- AC-2: the Naboo ambush started in Lok: leaving Naboo after the spawn fails it
function TestSurpriseAttackLeaveZoneFails:test_the_naboo_ambush_started_in_lok_fails_2000_ms_after_the_pilot_leaves_naboo()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "precondition: the ambush spawned in Naboo")

	H.zoneSwitch(player, "space_lok", { ship = true })
	H.advance(1999)
	lu.assertTrue(isActive(player, q), "3e active 1999 ms after leaving Naboo")
	H.advance(1)
	lu.assertFalse(isActive(player, q), "3e failed 2000 ms after leaving Naboo")
	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls: nothing more spawned")
end

---------------------------------------------------------------------------------------------
-- AC-3: no fail without a run
---------------------------------------------------------------------------------------------

TestSurpriseAttackNoFailWithoutRun = {}

function TestSurpriseAttackNoFailWithoutRun:setUp() H.reset() end

-- AC-3 (leaving before the spawn does nothing)
function TestSurpriseAttackNoFailWithoutRun:test_switching_between_other_zones_while_the_run_is_pending_fails_nothing_and_spawns_nothing()
	local q, player = started(E3, "space_lok")
	local messages = #H.messageLog(player)

	for _, zone in ipairs({ "space_corellia", "space_dantooine", "space_lok", "space_tatooine" }) do
		H.zoneSwitch(player, zone, { ship = true })
		H.advance(10000)
	end

	H.zoneSwitch(player, "tatooine")
	H.advance(10000)

	lu.assertTrue(isActive(player, q), "3e stays active")
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls")
	lu.assertEquals(#messagesSince(player, messages), 0, "no message after the start")
	lu.assertFalse(task0Complete(player, q), "task 0 stays incomplete")
end

for _, global in ipairs(GLOBALS) do
	-- AC-3
	TestSurpriseAttackNoFailWithoutRun["test_" .. global .. "_started_outside_its_zone_is_not_failed_by_zone_switches"] = function()
		local q, player = started(global, otherZone(quest(global)))
		local others = {}

		for _, zone in ipairs({ "space_corellia", "space_tatooine", "space_dantooine", "space_naboo", "space_lok" }) do
			if zone ~= q.questZone then
				others[#others + 1] = zone
			end
		end

		for _, zone in ipairs(others) do
			H.zoneSwitch(player, zone, { ship = true })
			H.advance(10000)
		end

		lu.assertTrue(isActive(player, q), global .. ": still active")
		lu.assertFalse(task0Complete(player, q), global .. ": task 0 stays incomplete")
		lu.assertEquals(#spawnCalls(), 0, global .. ": spawnShipAgent calls")
	end
end

-- AC-3: a switch to the quest's own zone after the spawn is a respawn in the zone
function TestSurpriseAttackNoFailWithoutRun:test_a_same_zone_switch_after_the_spawn_keeps_the_run_and_adds_no_ships()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "precondition: the ambush spawned")

	H.zoneSwitch(player, "space_naboo")
	H.advance(10000)

	lu.assertTrue(isActive(player, q), "3e stays active")
	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls")
	lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), 5, "kill count")
end

---------------------------------------------------------------------------------------------
-- AC-4 (I-2, I-5): the fail touches nothing else
---------------------------------------------------------------------------------------------

TestSurpriseAttackLeaveZoneTouchesNothingElse = {}

function TestSurpriseAttackLeaveZoneTouchesNothingElse:setUp() H.reset() end

local function journalState(player)
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		out[name] = { SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) == true,
			SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) == true }
	end

	return out
end

for _, global in ipairs(GLOBALS) do
	-- AC-4
	TestSurpriseAttackLeaveZoneTouchesNothingElse["test_" .. global .. "_failing_by_leaving_keeps_the_parent_complete_and_starts_nothing"] = function()
		H.reset()

		local q = quest(global)
		local player = H.newPlayer({ name = "Ace", zone = q.questZone, ship = true, pilot = "neutral" })

		local hasParent = q.parentQuestType ~= "" -- naboo_privateer_tier4_2c is unreachable and has none (rsf-tier4 D-6)

		if hasParent then
			-- the parent as its split leaves it: activated, then completed
			lu.assertTrue(SpaceHelpers:activateSpaceQuest(player, nil, q.parentQuestType, q.parentQuestName, false), global .. ": setup: parent activates")
			SpaceHelpers:completeSpaceQuest(player, q.parentQuestType, q.parentQuestName, false)
		end

		local starts = {}

		for _, name in ipairs(H.questGlobals()) do
			if name ~= global then
				starts[name] = H.spyOn(rawget(_G, name), "startQuest")
			end
		end

		q:startQuest(player, "")
		lu.assertEquals(#spawnCalls(), totalShips(q), global .. ": precondition: the attackers spawned")

		local before = journalState(player)

		H.zoneSwitch(player, otherZone(q), { ship = true })
		H.advance(30000)

		local after = journalState(player)

		lu.assertEquals(before[global], { true, false }, global .. ": precondition: the child was active")
		lu.assertEquals(after[global], { false, false }, global .. ": the child is neither active nor complete")

		before[global], after[global] = nil, nil
		lu.assertEquals(after, before, global .. ": journal state of every other quest")

		if hasParent then
			local parent = q.parentQuestType .. "_" .. q.parentQuestName

			lu.assertEquals(after[parent], { false, true }, global .. ": the parent " .. parent .. " is still complete and not active")
		end

		for name, calls in pairs(starts) do
			lu.assertEquals(#calls, 0, global .. ": " .. name .. ":startQuest calls")
		end

		for _, e in ipairs(H.pendingEvents()) do
			lu.assertNotEquals(e.method, "startQuest", global .. ": startQuest queued for " .. tostring(e.screenplay))
		end
	end
end

-- AC-4: I-2, a leave-zone fail can never start a failure split
function TestSurpriseAttackLeaveZoneTouchesNothingElse:test_no_surprise_attack_has_a_failure_or_bidirectional_split()
	for _, global in ipairs(GLOBALS) do
		local q = quest(global)

		lu.assertNotEquals(q.sideQuestSplitType, q.SIDE_QUEST_SPLIT_TYPES.FAILURE, global .. ": sideQuestSplitType")
		lu.assertNotEquals(q.sideQuestSplitType, q.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, global .. ": sideQuestSplitType")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5 (D-9): after a restart the journal is kept but shared memory is gone
---------------------------------------------------------------------------------------------

TestSurpriseAttackRestart = {}

function TestSurpriseAttackRestart:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-5
	TestSurpriseAttackRestart["test_" .. global .. "_after_a_restart_leaving_does_not_fail_and_reentering_respawns_the_full_set"] = function()
		local q, player = started(global)
		local n = totalShips(q)

		lu.assertEquals(#spawnCalls(), n, global .. ": precondition: the attackers spawned")
		lu.assertTrue(task0Complete(player, q), global .. ": precondition: task 0 complete")

		deleteData(player.objectID .. q.className .. ":spawned") -- the server restart: shared memory is gone, the journal stays

		H.zoneSwitch(player, otherZone(q), { ship = true })
		H.advance(10000)

		lu.assertTrue(isActive(player, q), global .. ": still active 10 s after leaving")
		lu.assertEquals(#spawnCalls(), n, global .. ": nothing spawned while away")

		H.zoneSwitch(player, q.questZone, { ship = true })
		H.advance(999)
		lu.assertEquals(#spawnCalls(), n, global .. ": spawnShipAgent calls 999 ms after re-entering")
		H.advance(1)
		lu.assertEquals(#spawnCalls(), 2 * n, global .. ": the full set spawned again 1000 ms after re-entering")
		lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), n, global .. ": kill count of the new set")
		lu.assertTrue(isActive(player, q), global .. ": active")

		H.zoneSwitch(player, otherZone(q), { ship = true })
		H.advance(1999)
		lu.assertTrue(isActive(player, q), global .. ": active 1999 ms after the second leave")
		H.advance(1)
		lu.assertFalse(isActive(player, q), global .. ": failed 2000 ms after the second leave")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6 (SC-3, D-10): ships of an earlier run do not count
---------------------------------------------------------------------------------------------

TestSurpriseAttackRunGuard = {}

function TestSurpriseAttackRunGuard:setUp() H.reset() end

-- Run A spawned and ended by `endRun(q, player)`, then run B started in the zone. Returns q, player, shipsA, shipsB.
local function twoRuns(global, endRun)
	local q, player = started(global)
	local n = totalShips(q)
	local shipsA = copyShips()

	lu.assertEquals(#shipsA, n, global .. ": precondition: run A spawned")
	endRun(q, player)

	for i, ship in ipairs(shipsA) do
		lu.assertFalse(ship.destroyed == true, global .. ": run A ship #" .. i .. " stays in the world")
	end

	H.zoneSwitch(player, q.questZone, { ship = true })
	q:startQuest(player, "")

	local all = copyShips()

	lu.assertEquals(#all, 2 * n, global .. ": precondition: run B spawned")
	lu.assertTrue(isActive(player, q), global .. ": precondition: run B is active")

	local shipsB = {}

	for i = n + 1, 2 * n do
		shipsB[#shipsB + 1] = all[i]
	end

	return q, player, shipsA, shipsB
end

local function leaveAndFail(q, player)
	H.zoneSwitch(player, otherZone(q), { ship = true })
	H.advance(2000)
	lu.assertFalse(isActive(player, q), q.questName .. ": precondition: run A failed by leaving")
end

local function abortRun(q, player)
	H.abortMission(player, q.questType, q.questName)
	H.advance(2000)
end

local function assertOldKillsCountNothing(global, q, player, shipsA, shipsB)
	local n = #shipsB
	local countKey = player.objectID .. q.className .. ":Count"

	lu.assertEquals(readData(countKey), n, global .. ": run B's :Count")

	local messages = #H.messageLog(player)

	for i, ship in ipairs(shipsA) do
		lu.assertEquals(q:notifyShipDestroyed(ship, player.rootParent), 1, global .. ": run A ship #" .. i .. ": notifyShipDestroyed return")

		local removed = false

		for _, id in ipairs(player.removedMissionObjects) do
			if id == ship.objectID then
				removed = true
			end
		end

		lu.assertTrue(removed, global .. ": run A ship #" .. i .. " removed from the player's mission objects")
		lu.assertEquals(readData(countKey), n, global .. ": run B's :Count after run A ship #" .. i .. " died")
		lu.assertTrue(isActive(player, q), global .. ": run B still active after run A ship #" .. i .. " died")
	end

	lu.assertEquals(#messagesSince(player, messages), 0, global .. ": no update sent for run A kills")

	for i, ship in ipairs(shipsB) do
		lu.assertTrue(isActive(player, q), global .. ": run B active before kill #" .. i)
		H.destroyShip(ship, player.rootParent)
	end

	lu.assertTrue(isComplete(player, q), global .. ": run B completed by its own " .. n .. " kills")
end

for _, global in ipairs(GLOBALS) do
	-- AC-6
	TestSurpriseAttackRunGuard["test_" .. global .. "_ships_of_a_run_failed_by_leaving_do_not_count_for_the_next_run"] = function()
		local q, player, shipsA, shipsB = twoRuns(global, leaveAndFail)

		assertOldKillsCountNothing(global, q, player, shipsA, shipsB)
	end
end

-- AC-6: the same after a datapad abort
function TestSurpriseAttackRunGuard:test_ships_of_an_aborted_run_do_not_count_for_the_next_run()
	local q, player, shipsA, shipsB = twoRuns(CS1, abortRun)

	assertOldKillsCountNothing(CS1, q, player, shipsA, shipsB)
end

-- AC-6: through the real kill path (SHIPDESTROYED observers), run A's ships first
function TestSurpriseAttackRunGuard:test_destroying_run_a_ships_through_the_observers_leaves_run_b_untouched()
	local q, player, shipsA, shipsB = twoRuns(CS1, leaveAndFail)
	local countKey = player.objectID .. q.className .. ":Count"

	for _, ship in ipairs(shipsA) do
		H.destroyShip(ship, player.rootParent)
	end

	lu.assertEquals(readData(countKey), #shipsB, "run B's :Count")
	lu.assertTrue(isActive(player, q), "run B still active")

	for _, ship in ipairs(shipsB) do
		H.destroyShip(ship, player.rootParent)
	end

	lu.assertTrue(isComplete(player, q), "run B completes")
end

-- AC-6: kills in the middle of run B mix with run A kills
function TestSurpriseAttackRunGuard:test_run_a_kills_between_run_b_kills_change_nothing()
	local q, player, shipsA, shipsB = twoRuns(CS1, leaveAndFail)
	local countKey = player.objectID .. q.className .. ":Count"

	H.destroyShip(shipsB[1], player.rootParent)
	lu.assertEquals(readData(countKey), 2, "Count after one run B kill")
	H.destroyShip(shipsA[1], player.rootParent)
	lu.assertEquals(readData(countKey), 2, "Count after a run A kill")
	H.destroyShip(shipsB[2], player.rootParent)
	lu.assertEquals(readData(countKey), 1, "Count after two run B kills")
	H.destroyShip(shipsA[2], player.rootParent)
	lu.assertTrue(isActive(player, q), "still active after a run A kill")
	H.destroyShip(shipsB[3], player.rootParent)
	lu.assertTrue(isComplete(player, q), "completed by the third run B kill")
end

-- SC-3: the run id is the id of the run's first ship, on the pilot and on every ship; a kill takes the ship's key away
function TestSurpriseAttackRunGuard:test_the_run_id_is_the_first_ships_object_id_on_the_pilot_and_every_ship()
	local q, player = started(CS1)
	local ships = copyShips()
	local runKey = player.objectID .. q.className .. ":runID"

	lu.assertEquals(tonumber(readData(runKey)), ships[1].objectID, "<pid><className>:runID")

	for i, ship in ipairs(ships) do
		lu.assertEquals(tonumber(readData(ship.objectID .. q.className .. ":runID")), ships[1].objectID, "ship #" .. i .. ": <agentID><className>:runID")
	end

	H.destroyShip(ships[2], player.rootParent)
	lu.assertEquals(readData(ships[2].objectID .. q.className .. ":runID"), 0, "a dead ship's runID key is deleted (readData of an absent key is 0)")
	lu.assertEquals(tonumber(readData(runKey)), ships[1].objectID, "the pilot's runID stays while the run is on")
end

-- SC-3: every end of a run deletes the pilot's run id
local ENDS = {
	complete = function(q, player) q:completeQuest(player, "false") end,
	fail = function(q, player) q:failQuest(player, "false") end,
	reset = function(q, player) q:resetQuest(player) end,
}

for _, method in ipairs({ "complete", "fail", "reset" }) do
	TestSurpriseAttackRunGuard["test_" .. method .. "Quest_deletes_the_pilots_run_id"] = function()
		local q, player = started("destroy_surpriseattack_naboo_privateer_tier4_2b")

		lu.assertTrue(hasKey(player, q, ":runID"), method .. ": precondition: the spawn wrote the pilot's runID")
		ENDS[method](q, player)
		H.advance(1000)
		lu.assertFalse(hasKey(player, q, ":runID"), method .. "Quest: <pid><className>:runID left")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8 (I-7): every string id the quest type sends resolves in the pre-NGE client
---------------------------------------------------------------------------------------------

TestSurpriseAttackClientStrings = {}

function TestSurpriseAttackClientStrings:setUp() H.reset() end

-- "@file:id" -> file, id (raw English text returns nil)
local function splitSid(text)
	if type(text) ~= "string" then
		return nil
	end

	return text:match("^@([%w_/]+):([%w_]+)$")
end

local function unresolved(messages)
	local out = {}

	for _, m in ipairs(messages) do
		for _, text in ipairs({ m.id, m.TO or "" }) do
			local file, id = splitSid(text)

			if file ~= nil then
				local set = CS.sids(file)

				if set == nil or not set[id] then
					out[#out + 1] = text
				end
			end
		end
	end

	table.sort(out)

	return out
end

for _, global in ipairs(GLOBALS) do
	-- AC-8
	TestSurpriseAttackClientStrings["test_" .. global .. "_sends_only_ids_the_client_has_when_it_is_won_and_when_it_is_abandoned"] = function()
		local q, player = started(global)

		for _, ship in ipairs(copyShips()) do
			H.destroyShip(ship, player.rootParent)
		end

		lu.assertTrue(isComplete(player, q), global .. ": precondition: won")

		local won = H.messageLog(player)

		lu.assertTrue(#won >= 3, global .. ": precondition: the run sent messages")
		lu.assertEquals(unresolved(won), {}, global .. ": ids of the win path the client lacks")

		local q2, player2 = started(global)

		H.zoneSwitch(player2, otherZone(q2), { ship = true })
		H.advance(2000)

		local lost = H.messageLog(player2)
		local ids = {}

		for i, m in ipairs(lost) do
			ids[i] = m.id
		end

		lu.assertEquals(ids[#ids], "@space/quest:quest_failed", global .. ": the abandoned run ends with quest_failed")
		lu.assertEquals(unresolved(lost), {}, global .. ": ids of the abandon path the client lacks")
	end
end

-- AC-8: the ids the quest type sends are in the fixtures generated from /tre
function TestSurpriseAttackClientStrings:test_the_shared_quest_ids_and_every_quests_title_and_complete_resolve()
	local shared = CS.sids("space/quest")

	lu.assertNotNil(shared, "fixtures/string/en/space/quest.sids")

	for _, id in ipairs({ "quest_received", "quest_in_progress", "quest_update_s", "quest_won", "quest_failed", "destroy_surprise_abandoned" }) do
		lu.assertTrue(shared[id], "space/quest:" .. id)
	end

	for _, global in ipairs(GLOBALS) do
		local q = quest(global)
		local set, err = CS.sids("spacequest/destroy_surpriseattack/" .. q.questName)

		lu.assertNotNil(set, global .. ": " .. tostring(err))
		lu.assertTrue(set.title, global .. ": :title")
		lu.assertTrue(set.complete, global .. ": :complete")
	end
end
