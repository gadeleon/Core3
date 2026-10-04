-- Events and observers that are already queued when a datapad abort lands must not act on the gone quest.
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md (AC-6, AC-7, I-4)
--
-- Each test gets the event queued while the quest is active (by driving the real trigger), aborts through
-- H.abortMission, pumps the clock past the delay and diffs what the event could have created. Each guard also has a
-- live case: the same event on an active quest still does its job.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")

AC.load()

local C_ABORTED = "@space/quest:quest_aborted"
local PAST = 60 * 1000 -- past every delay these events have (escort 11 s, recovery 2 x arrivalDelay = 26 s)

-- Runs the clock. A queued event that raises on the gone quest is a late action too, so it fails the test with its message
local function late(ms)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, "a queued event acted on the aborted quest and raised: " .. tostring(err))
end

local function pendingFor(q, method)
	local out = {}

	for _, e in ipairs(H.pendingEvents()) do
		if e.screenplay == q.className and e.method == method then
			out[#out + 1] = e
		end
	end

	return out
end

-- The messages after the abort are only the C++-modeled one
local function onlyAbortedMessage(p, from, label)
	local ids = {}

	for _, m in ipairs(AC.messagesSince(p, from)) do
		ids[#ids + 1] = m.id
	end

	lu.assertEquals(ids, { C_ABORTED }, label .. ": messages")
end

---------------------------------------------------------------------------------------------
-- AC-6: surprise attack kills after the abort
---------------------------------------------------------------------------------------------

TestSurpriseAttackAfterAbort = {}

local PARENT = "patrol_corellia_privateer_1"
local CHILD = "destroy_surpriseattack_corellia_privateer_1"

-- The patrol is active with its waypoint; the surprise attack runs on top of it and is then aborted
function TestSurpriseAttackAfterAbort:setUp()
	H.reset()

	self.patrol = H.expectGlobal(PARENT, "patrol quest table")
	self.q = H.expectGlobal(CHILD, "surprise attack quest table")

	local p, spies = AC.started(self.patrol, { isolate = { [CHILD] = true } })

	self.p, self.spies = p, spies
	self.waypointKey = p.objectID .. ":" .. PARENT .. ":waypointID"
	self.countKey = p.objectID .. CHILD .. ":Count"

	H.advance(5000) -- the patrol's own waypoint alert (4 s) is behind us, so it cannot pass for a late message

	self.q:startQuest(p, "")
	H.advance(0)

	self.ships = {}

	for i, ship in ipairs(H.spawnedShips()) do
		self.ships[i] = ship
	end

	lu.assertEquals(#self.ships, 3, "precondition: three attackers")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, self.patrol.questType, self.patrol.questName), "precondition: the parent patrol is active")
	lu.assertNotNil(getQuestStatus(self.waypointKey), "precondition: the parent waypoint status")
	lu.assertEquals(readData(self.countKey), 3, "precondition: the kill count")

	H.abortMission(p, self.q.questType, self.q.questName)
	self.afterAbort = { events = #H.Engine.callsTo("createEvent"), messages = #p.messageLog }
end

function TestSurpriseAttackAfterAbort:tearDown() AC.tearDown() end

-- AC-6
function TestSurpriseAttackAfterAbort:test_each_kill_after_the_abort_returns_1_so_the_observer_is_removed()
	for i, ship in ipairs(self.ships) do
		lu.assertEquals(self.q:notifyShipDestroyed(ship, self.p.rootParent), 1, "attacker #" .. i .. ": notifyShipDestroyed return")
	end
end

-- AC-6
function TestSurpriseAttackAfterAbort:test_killing_the_attackers_after_the_abort_leaves_the_parent_waypoint_alone()
	for _, ship in ipairs(self.ships) do
		H.destroyShip(ship, self.p.rootParent)
	end

	late(PAST)

	lu.assertNotNil(getQuestStatus(self.waypointKey), "the parent :waypointID status")
	lu.assertEquals(#self.p.ghost.waypoints, 1, "the parent waypoint on the player")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(self.p, self.patrol.questType, self.patrol.questName), "the parent patrol is still active")
end

-- AC-6
function TestSurpriseAttackAfterAbort:test_killing_the_attackers_after_the_abort_starts_nothing_and_sends_no_update()
	for _, ship in ipairs(self.ships) do
		H.destroyShip(ship, self.p.rootParent)
	end

	late(PAST)

	for _, e in ipairs(AC.eventsSince(self.afterAbort.events)) do
		lu.assertNotEquals(e.method, "startQuest", "a kill after the abort queued startQuest for " .. tostring(e.screenplay))
	end

	for name, calls in pairs(self.spies.start) do
		lu.assertEquals(#calls, 0, name .. ":startQuest calls")
	end

	onlyAbortedMessage(self.p, self.afterAbort.messages - 1, "after the kills") -- the abort's own message is the first one counted
end

-- AC-6: no :complete update, no remaining-targets update, no count key
function TestSurpriseAttackAfterAbort:test_killing_the_attackers_after_the_abort_writes_no_count_key_and_sends_no_update_message()
	local updates = #H.messageLog(self.p)

	for _, ship in ipairs(self.ships) do
		H.destroyShip(ship, self.p.rootParent)
	end

	lu.assertEquals(readData(self.countKey), 0, "the :Count key " .. self.countKey)
	lu.assertEquals(#H.messageLog(self.p), updates, "messages sent by the kills")

	for _, m in ipairs(H.messageLog(self.p)) do
		lu.assertFalse((m.TO or ""):find(":complete$") ~= nil, "a :complete update was sent: " .. tostring(m.TO))
	end
end

-- AC-6 (D-7): the ships stay in the world but are no longer mission objects once they die
function TestSurpriseAttackAfterAbort:test_killed_attackers_are_removed_from_the_player_mission_objects()
	for i, ship in ipairs(self.ships) do
		lu.assertTrue(#self.p.missionObjects >= 1, "precondition: attacker #" .. i .. " is still a mission object")

		local id = ship.objectID

		H.destroyShip(ship, self.p.rootParent)

		local removed = false

		for _, r in ipairs(self.p.removedMissionObjects) do
			if r == id then
				removed = true
			end
		end

		lu.assertTrue(removed, "removeSpaceMissionObject was called for attacker #" .. i)

		for _, m in ipairs(self.p.missionObjects) do
			lu.assertNotEquals(m, id, "attacker #" .. i .. " is still in the player's space mission objects")
		end
	end

	lu.assertEquals(self.p.missionObjects, {}, "space mission objects after all three kills")
end

---------------------------------------------------------------------------------------------
-- AC-6 live case: the guard does not block a running surprise attack
---------------------------------------------------------------------------------------------

TestSurpriseAttackLive = {}

function TestSurpriseAttackLive:setUp() H.reset() end

-- AC-6: with the quest active the same kills count down and complete it
function TestSurpriseAttackLive:test_the_same_kills_on_a_live_run_count_down_and_complete_the_quest()
	local q = H.expectGlobal(CHILD, "surprise attack quest table")
	local p = AC.started(q)
	local ships = {}

	for i, ship in ipairs(H.spawnedShips()) do
		ships[i] = ship
	end

	local key = p.objectID .. CHILD .. ":Count"

	H.destroyShip(ships[1], p.rootParent)
	lu.assertEquals(readData(key), 2, "Count after one kill")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, q.questType, q.questName), "still active")

	for i = 2, 3 do
		H.destroyShip(ships[i], p.rootParent)
	end

	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(p, q.questType, q.questName), "completed by the third kill")
	lu.assertEquals(readData(key), 0, "Count key deleted")
end

---------------------------------------------------------------------------------------------
-- AC-6: destroy duty events
---------------------------------------------------------------------------------------------

TestDestroyDutyAfterAbort = {}

local DUTY = "destroy_duty_corellia_rebel_6"

function TestDestroyDutyAfterAbort:setUp() H.reset() end

-- AC-6: getTargetLocation queued by enteredZone
function TestDestroyDutyAfterAbort:test_a_target_location_event_queued_by_entering_the_zone_spawns_nothing_after_the_abort()
	local q = H.expectGlobal(DUTY, "destroy duty quest table")
	local p = AC.started(q, { zone = "space_tatooine" })

	H.zoneSwitch(p, q.questZone) -- ZONESWITCHED -> enteredZone -> getTargetLocation in 2 s

	lu.assertEquals(#pendingFor(q, "getTargetLocation"), 1, "precondition: getTargetLocation is queued")

	local m0 = #p.messageLog

	H.abortMission(p, q.questType, q.questName)

	local before = AC.snapshot(p)

	late(PAST)

	local after = AC.snapshot(p)

	lu.assertEquals(after.areas, before.areas, "areas spawned")
	lu.assertEquals(after.spawnSpaceActiveArea, before.spawnSpaceActiveArea, "spawnSpaceActiveArea calls")
	lu.assertEquals(after.addWaypoint, before.addWaypoint, "addWaypoint calls")
	lu.assertEquals(after.waypoints, 0, "waypoints on the player")
	lu.assertNil(getQuestStatus(p.objectID .. ":" .. q.className .. ":waypointID"), "waypointID status")
	lu.assertEquals(readData(p.objectID .. ":" .. q.className .. ":targetArea:"), 0, "targetArea key")
	onlyAbortedMessage(p, m0, "after the abort")
end

-- AC-6: getTargetLocation queued by the end of a round
function TestDestroyDutyAfterAbort:test_a_target_location_event_queued_by_a_round_end_spawns_nothing_after_the_abort()
	local q = H.expectGlobal(DUTY, "destroy duty quest table")
	local p = AC.started(q)
	local area = getSceneObject(readData(p.objectID .. ":" .. q.className .. ":targetArea:"))
	local prefix = p.objectID .. ":" .. q.className .. ":"

	H.enterArea(area, p.rootParent)
	H.advance(4500)
	writeData(prefix .. "CurrentWave:", q.totalWaves)
	writeData(prefix .. "CurrentRound:", q.totalRounds - 1)
	H.destroyShip(H.spawnedShips()[1], p.rootParent)

	lu.assertEquals(#pendingFor(q, "getTargetLocation"), 1, "precondition: the round end queued getTargetLocation")

	H.abortMission(p, q.questType, q.questName)

	local before = AC.snapshot(p)

	late(PAST)

	local after = AC.snapshot(p)

	lu.assertEquals(after.areas, before.areas, "areas spawned")
	lu.assertEquals(after.addWaypoint, before.addWaypoint, "addWaypoint calls")
	lu.assertEquals(after.waypoints, 0, "waypoints on the player")
	lu.assertEquals(readData(prefix .. "targetArea:"), 0, "targetArea key")
end

-- AC-6: with the duty active the queued getTargetLocation gives the next area and a waypoint
function TestDestroyDutyAfterAbort:test_the_same_target_location_event_on_a_live_duty_spawns_the_next_area_and_waypoint()
	local q = H.expectGlobal(DUTY, "destroy duty quest table")
	local p = AC.started(q, { zone = "space_tatooine" })

	H.zoneSwitch(p, q.questZone)
	H.advance(2500)

	lu.assertEquals(#H.spawnedAreas(), 1, "areas")
	lu.assertEquals(#p.ghost.waypoints, 1, "waypoints")
	lu.assertNotNil(getQuestStatus(p.objectID .. ":" .. q.className .. ":waypointID"), "waypointID status")
end

-- AC-6: spawnAttackWave queued by notifyEnteredQuestArea
function TestDestroyDutyAfterAbort:test_an_attack_wave_queued_by_entering_the_area_spawns_no_ship_after_the_abort()
	local q = H.expectGlobal(DUTY, "destroy duty quest table")
	local p = AC.started(q)
	local area = getSceneObject(readData(p.objectID .. ":" .. q.className .. ":targetArea:"))

	H.enterArea(area, p.rootParent)

	lu.assertEquals(#pendingFor(q, "spawnAttackWave"), 1, "precondition: spawnAttackWave is queued")

	local m0 = #p.messageLog

	H.abortMission(p, q.questType, q.questName)

	local before = AC.snapshot(p)

	late(PAST)

	local after = AC.snapshot(p)

	lu.assertEquals(after.ships, 0, "ships spawned")
	lu.assertEquals(after.spawnShipAgent, before.spawnShipAgent, "spawnShipAgent calls")
	lu.assertEquals(p.missionObjects, {}, "mission objects")
	onlyAbortedMessage(p, m0, "after the abort")
end

-- AC-6: live case
function TestDestroyDutyAfterAbort:test_the_same_attack_wave_on_a_live_duty_spawns_a_ship()
	local q = H.expectGlobal(DUTY, "destroy duty quest table")
	local p = AC.started(q)
	local area = getSceneObject(readData(p.objectID .. ":" .. q.className .. ":targetArea:"))

	H.enterArea(area, p.rootParent)
	late(PAST)

	lu.assertEquals(#H.spawnedShips(), 1, "ships spawned by the wave")
end

---------------------------------------------------------------------------------------------
-- AC-6: escort duty resetDutyMission queued after a success
---------------------------------------------------------------------------------------------

TestEscortDutyResetAfterAbort = {}

function TestEscortDutyResetAfterAbort:setUp() H.reset() end
function TestEscortDutyResetAfterAbort:tearDown() AC.tearDown() end

-- The escort ship passes every escort point: the duty pays out and queues resetDutyMission (10 s)
local function successfulEscort()
	local run = AC.escortRun("escort_duty_corellia_privateer_7")
	local q, p = run.q, run.player

	lu.assertNotNil(run.escortAgent, "precondition: the escort ship is out")

	for i = 1, #q.escortPoints do
		H.enterArea(AC.areaByNumber(q, i), run.escortAgent)
	end

	lu.assertEquals(#pendingFor(q, "resetDutyMission"), 1, "precondition: resetDutyMission is queued after the success")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, q.questType, q.questName), "precondition: the duty is still active until the reset")

	return run
end

-- AC-6
function TestEscortDutyResetAfterAbort:test_a_reset_queued_after_a_success_adds_nothing_after_the_abort()
	local run = successfulEscort()
	local q, p = run.q, run.player
	local prefix = p.objectID .. q.className .. ":startPoint:"

	AC.abort(run)

	local before = AC.snapshot(p)
	local crc = AC.crc(run)

	late(PAST)

	local after = AC.snapshot(p)

	lu.assertEquals(after.addWaypoint, before.addWaypoint, "addWaypoint calls")
	lu.assertEquals(after.waypoints, 0, "waypoints on the player")
	lu.assertEquals(readData(prefix), 0, "the :startPoint: key " .. prefix)
	lu.assertFalse(p.ghost:isJournalQuestTaskActive(crc, 1), "quest task 1 was activated again")
	lu.assertNil(getQuestStatus(p.objectID .. ":" .. q.className .. ":waypointID"), "waypointID status")
	lu.assertEquals(#AC.messagesSince(p, before.messages), 0, "messages sent by the late event")
end

-- AC-6: live case
function TestEscortDutyResetAfterAbort:test_the_same_reset_on_a_live_duty_sets_up_the_next_escort()
	local run = successfulEscort()
	local q, p = run.q, run.player

	late(PAST)

	lu.assertEquals(#p.ghost.waypoints, 1, "the next rendezvous waypoint")
	lu.assertEquals(readData(p.objectID .. q.className .. ":startPoint:"), 1, "the next start point")
	lu.assertTrue(p.ghost:isJournalQuestTaskActive(AC.crc(run), 1), "quest task 1 is active again")
end

---------------------------------------------------------------------------------------------
-- AC-7: setup and spawn windows of escort, escort duty, recovery, recovery duty and assassinate
---------------------------------------------------------------------------------------------

TestSetupWindowsAfterAbort = {}

function TestSetupWindowsAfterAbort:setUp() H.reset() end
function TestSetupWindowsAfterAbort:tearDown() AC.tearDown() end

local ESCORTS = { "escort_corellia_privateer_3", "escort_duty_corellia_privateer_7" }
local RECOVERIES = { "recovery_corellia_privateer_tier3_1", "recovery_duty_corellia_rebel_tier4_1" }
local ASSASSINATE = "assassinate_corellia_privateer_tier1_4a"

-- setupEscort (2 s after startQuest)
for _, global in ipairs(ESCORTS) do
	-- AC-7
	TestSetupWindowsAfterAbort["test_setup_escort_of_" .. global .. "_adds_no_waypoint_after_the_abort"] = function()
		local q = H.expectGlobal(global, "escort quest table")
		local p = AC.started(q)

		lu.assertEquals(#pendingFor(q, "setupEscort"), 1, "precondition: setupEscort is queued")

		local m0 = #p.messageLog

		H.abortMission(p, q.questType, q.questName)

		local before = AC.snapshot(p)

		late(PAST)

		local after = AC.snapshot(p)

		lu.assertEquals(after.addWaypoint, before.addWaypoint, global .. ": addWaypoint calls")
		lu.assertEquals(after.waypoints, 0, global .. ": waypoints on the player")
		lu.assertEquals(readData(p.objectID .. q.className .. ":startPoint:"), 0, global .. ": the :startPoint: key")
		onlyAbortedMessage(p, m0, global)
	end

	-- AC-7 live case
	TestSetupWindowsAfterAbort["test_setup_escort_of_" .. global .. "_adds_the_waypoint_on_a_live_quest"] = function()
		local q = H.expectGlobal(global, "escort quest table")
		local p = AC.started(q)

		late(PAST)

		lu.assertEquals(#p.ghost.waypoints, 1, global .. ": the rendezvous waypoint")
		lu.assertEquals(readData(p.objectID .. q.className .. ":startPoint:"), 1, global .. ": the :startPoint: key")
	end

	-- AC-7: the player reaches the rendezvous (spawnEscortShip queued 5-11 s), then the abort lands
	TestSetupWindowsAfterAbort["test_spawn_escort_ship_of_" .. global .. "_spawns_no_ship_after_the_abort"] = function()
		local q = H.expectGlobal(global, "escort quest table")
		local p = AC.started(q)

		H.advance(2500)
		H.enterArea(AC.areaByNumber(q, readData(p.objectID .. q.className .. ":startPoint:")), p.rootParent)

		lu.assertEquals(#pendingFor(q, "spawnEscortShip"), 1, "precondition: spawnEscortShip is queued")

		H.abortMission(p, q.questType, q.questName)

		local before = AC.snapshot(p)

		late(PAST)

		local after = AC.snapshot(p)

		lu.assertEquals(after.ships, 0, global .. ": ships")
		lu.assertEquals(after.spawnShipAgent, before.spawnShipAgent, global .. ": spawnShipAgent calls")
		lu.assertEquals(after.addWaypoint, before.addWaypoint, global .. ": addWaypoint calls")
		lu.assertEquals(readData(p.objectID .. ":" .. q.className .. ":escortID:"), 0, global .. ": escortID key")
	end

	-- AC-7 live case
	TestSetupWindowsAfterAbort["test_spawn_escort_ship_of_" .. global .. "_spawns_the_escort_on_a_live_quest"] = function()
		local run = AC.escortRun(global)

		lu.assertNotNil(run.escortAgent, global .. ": the escort ship")
		lu.assertEquals(#H.spawnedShips(), 1, global .. ": ships")
	end
end

-- setupRecover (arrivalDelay s after startQuest) and spawnRecoveryShip (arrivalDelay s after that)
for _, global in ipairs(RECOVERIES) do
	local function recovery()
		local q = H.expectGlobal(global, "recovery quest table")

		AC.resolveRecoveryPoints(q)

		return q, (AC.started(q))
	end

	-- AC-7
	TestSetupWindowsAfterAbort["test_setup_recover_of_" .. global .. "_sends_no_arrival_message_after_the_abort"] = function()
		local q, p = recovery()

		lu.assertEquals(#pendingFor(q, "setupRecover"), 1, "precondition: setupRecover is queued")

		local m0 = #p.messageLog

		H.abortMission(p, q.questType, q.questName)

		local before = AC.snapshot(p)
		local events = #H.Engine.callsTo("createEvent")

		late(PAST)

		onlyAbortedMessage(p, m0, global .. " (no arrival_phase_1)")
		lu.assertEquals(#AC.eventsSince(events, "spawnRecoveryShip"), 0, global .. ": spawnRecoveryShip events queued after the abort")
		lu.assertEquals(AC.snapshot(p).ships, before.ships, global .. ": ships")
	end

	-- AC-7 live case
	TestSetupWindowsAfterAbort["test_setup_recover_of_" .. global .. "_sends_the_arrival_message_and_queues_the_ship_on_a_live_quest"] = function()
		local q, p = recovery()

		H.advance(q.arrivalDelay * 1000)

		local arrival = 0

		for _, m in ipairs(H.messageLog(p)) do
			if m.id == "@spacequest/" .. q.questType .. "/" .. q.questName .. ":arrival_phase_1" then
				arrival = arrival + 1
			end
		end

		lu.assertEquals(arrival, 1, global .. ": arrival_phase_1 messages")
		lu.assertEquals(#pendingFor(q, "spawnRecoveryShip"), 1, global .. ": spawnRecoveryShip is queued")
	end

	-- AC-7: setupRecover ran, spawnRecoveryShip is still queued
	TestSetupWindowsAfterAbort["test_spawn_recovery_ship_of_" .. global .. "_spawns_no_ship_after_the_abort"] = function()
		local q, p = recovery()

		H.advance(q.arrivalDelay * 1000)

		lu.assertEquals(#pendingFor(q, "spawnRecoveryShip"), 1, "precondition: spawnRecoveryShip is queued")

		H.abortMission(p, q.questType, q.questName)

		local before = AC.snapshot(p)

		late(PAST)

		local after = AC.snapshot(p)

		lu.assertEquals(after.ships, 0, global .. ": ships")
		lu.assertEquals(after.spawnShipAgent, before.spawnShipAgent, global .. ": spawnShipAgent calls")
		lu.assertEquals(after.addWaypoint, before.addWaypoint, global .. ": addWaypoint calls")
		lu.assertEquals(after.waypoints, 0, global .. ": waypoints on the player")
		lu.assertEquals(readData(p.objectID .. q.className .. ":recoveryShip:"), 0, global .. ": recoveryShip key")
	end

	-- AC-7 live case
	TestSetupWindowsAfterAbort["test_spawn_recovery_ship_of_" .. global .. "_spawns_the_ship_and_escorts_on_a_live_quest"] = function()
		local q, p = recovery()

		late(PAST)

		lu.assertTrue(#H.spawnedShips() >= 1, global .. ": the recovery ship spawned")
		lu.assertNotEquals(readData(p.objectID .. q.className .. ":recoveryShip:"), 0, global .. ": recoveryShip key")
	end
end

-- deployTargets (2 s after startQuest)
-- AC-7
function TestSetupWindowsAfterAbort:test_deploy_targets_of_assassinate_spawns_no_ship_after_the_abort()
	local q = H.expectGlobal(ASSASSINATE, "assassinate quest table")
	local p = AC.started(q)

	lu.assertEquals(#pendingFor(q, "deployTargets"), 1, "precondition: deployTargets is queued")

	local m0 = #p.messageLog

	H.abortMission(p, q.questType, q.questName)

	local before = AC.snapshot(p)

	late(PAST)

	local after = AC.snapshot(p)

	lu.assertEquals(after.ships, 0, "ships")
	lu.assertEquals(after.spawnShipAgent, before.spawnShipAgent, "spawnShipAgent calls")
	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. q.className .. ":targetShips:"), {}, "targetShips vector")
	lu.assertEquals(p.missionObjects, {}, "mission objects")

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.method, "failAssassination", "the fail timer was queued by the late deployTargets")
	end

	onlyAbortedMessage(p, m0, "assassinate")
end

-- AC-7 live case
function TestSetupWindowsAfterAbort:test_deploy_targets_of_assassinate_spawns_the_targets_on_a_live_quest()
	local q = H.expectGlobal(ASSASSINATE, "assassinate quest table")

	AC.started(q)
	H.advance(6500) -- space-assassinate-escort-fix SC-5: the in-zone deploy waits arrivalDelay (6 s for corellia_privateer_tier1_4a)

	lu.assertTrue(#H.spawnedShips() >= 1, "target ships spawned")
end
