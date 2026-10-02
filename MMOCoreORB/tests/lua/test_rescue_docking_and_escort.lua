-- Rescue docking, escort start and arrival (space-quest-rescue-docking).
-- Spec: .claude/work/space-quest-rescue-docking/01-spec.md (AC-4, AC-5, AC-6, I-6, Behavior 6, 7, 9).
-- The docking event is the engine's SHIPDOCKED notify on the player creature, fired with
-- (target ship, cargo hash) by H.dock, followed by the 0 ms events. Times are milliseconds.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")

R.load()

local function secs(n) return n * 1000 end

local REP = R.REP

-- Another ship that is not the rescue target: an attack-style agent owned by the player.
local function strayShip(sc)
	local agent = spawnShipAgent("imp_tie_fighter_tier3", sc.o.zone, 1, 2, 3, sc.ship)

	ShipAiAgent(agent):setMissionOwner(sc.player)
	return agent
end

TestRescueDockEvent = {}

function TestRescueDockEvent:setUp() H.reset() end

-- AC-4
function TestRescueDockEvent:test_not_docking_changes_nothing_for_ten_minutes()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.advance(secs(600))

	lu.assertEquals(t.dockableCalls, { true }, "the target is still dockable")
	lu.assertTrue(sc:taskActive(1), "task 1 is still active")
	lu.assertFalse(sc:taskComplete(1), "task 1 is not complete")
	lu.assertEquals(#sc:taunts(), 0, "no taunt")
	lu.assertTrue(sc:active(), "the quest is active")
end

-- AC-4
function TestRescueDockEvent:test_docking_changes_nothing_inside_the_observer_and_the_observer_returns_1()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "notifyDocked returns 1 for the waiting target")
	lu.assertEquals(#sc:taunts(), 0, "no taunt inside the observer")
	lu.assertTrue(sc:taskActive(1), "task 1 still active inside the observer")
	lu.assertEquals(t.dockableCalls, { true }, "the target is still dockable inside the observer (setDockable takes the agent lock)")
	lu.assertEquals(R.count(sc:events(), "docking_complete"), 0, "no docking_complete inside the observer")
end

-- AC-4
function TestRescueDockEvent:test_the_engine_removes_the_docking_observer_and_the_work_runs_in_the_0_ms_event()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.dock(sc.player, t)

	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "SHIPDOCKED observer is gone after the dock")
	lu.assertEquals(#sc:taunts(), 0, "nothing happened before the 0 ms events")
	lu.assertTrue(sc:taskActive(1), "task 1 still active before the 0 ms events")

	H.advance(0)

	lu.assertEquals(R.count(sc:events(), "docking_complete", "update"), 1, "docking_complete update after the events")
end

-- AC-4
function TestRescueDockEvent:test_docking_with_the_target_sends_the_messages_and_advances_the_tasks_but_keeps_it_dockable()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toWaiting()
		local t = sc:target()

		sc:dock(t)

		lu.assertEquals(R.count(sc:events(), "docking_complete", "update"), 1, name .. ": docking_complete update")
		lu.assertEquals(R.tauntTimes(sc:taunts(), "rescue_phase_2"), { sc.tDock }, name .. ": rescue_phase_2 taunt at dock completion")
		lu.assertEquals(sc:taunts()[#sc:taunts()].ship, t, name .. ": taunted by the rescue target")
		lu.assertTrue(sc:taskComplete(1), name .. ": task 1 complete")
		lu.assertTrue(sc:taskActive(2), name .. ": task 2 active")
		lu.assertEquals(t.dockableCalls, { true }, name .. ": still dockable until the escort starts (D-3)")
		lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), name .. ": no SHIPDOCKED observer of this class remains")
		lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "stage")), SpaceRescueScreenplay.STAGES.DOCKED, name .. ": stage = DOCKED")
	end
end

-- AC-4
function TestRescueDockEvent:test_the_cargo_hash_is_ignored()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.dock(sc.player, t, 123456)
	H.advance(0)

	lu.assertTrue(sc:taskComplete(1), "a dock with any cargo hash completes the dock task")
end

-- AC-4
function TestRescueDockEvent:test_docking_with_another_ship_changes_nothing_returns_0_and_keeps_the_observer()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()
	local stray = strayShip(sc)

	lu.assertEquals(sc.quest:notifyDocked(sc.player, stray, 0), 0, "notifyDocked returns 0 for another ship")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, nil, 0), 0, "notifyDocked returns 0 for no ship")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, sc.ship, 0), 0, "notifyDocked returns 0 for the player's own ship")

	H.dock(sc.player, stray)
	H.advance(0)

	lu.assertEquals(#sc:taunts(), 0, "no taunt")
	lu.assertTrue(sc:taskActive(1), "task 1 still active")
	lu.assertEquals(t.dockableCalls, { true }, "the target still dockable")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "the observer stays")

	H.advance(secs(10))
	sc:dock(t)

	lu.assertTrue(sc:taskComplete(1), "docking with the real target afterwards still works")
end

-- AC-4
function TestRescueDockEvent:test_docking_with_the_target_of_another_players_run_changes_nothing()
	local first = R.fresh(REP):toWaiting()
	local second = R.new(REP, { spies = first.spies })

	second:toWaiting()

	local theirs = second:target()

	lu.assertNotEquals(theirs, first:target(), "precondition: two different targets")

	H.dock(first.player, theirs)
	H.advance(0)

	lu.assertEquals(R.tauntTimes(first:taunts(), "rescue_phase_2"), {}, "no rescue_phase_2 taunt for the first player")
	lu.assertTrue(first:taskActive(1), "first player's task 1 still active")
	lu.assertEquals(theirs.dockableCalls, { true }, "the other player's target stays dockable")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, first.className, "notifyDocked", first.player), "first player's observer stays")
	lu.assertTrue(second:taskActive(1), "second player's quest is untouched")
end

-- AC-4
function TestRescueDockEvent:test_docking_twice_before_the_events_run_completes_once()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	sc.quest:notifyDocked(sc.player, t, 0)
	sc.quest:notifyDocked(sc.player, t, 0)
	sc.tDock = H.now()
	H.advance(0)

	lu.assertEquals(#R.tauntTimes(sc:taunts(), "rescue_phase_2"), 1, "one rescue_phase_2 taunt")
	lu.assertEquals(R.count(sc:events(), "docking_complete", "update"), 1, "one docking_complete update")
	lu.assertEquals(#R.createEvents("startEscort", sc.className), 1, "one startEscort scheduled")

	sc:escort()

	lu.assertEquals(#t.patrolPointTables, 1, "the escort was configured once")
end

-- AC-4: a dock after the dock task is done is not a second completion
function TestRescueDockEvent:test_a_dock_after_the_dock_task_is_done_changes_nothing()
	local sc = R.fresh(REP):toDocked()
	local t = sc:target()
	local taunts = #sc:taunts()

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 0, "notifyDocked returns 0 once the stage is past DOCK")
	H.dock(sc.player, t)
	H.advance(0)

	lu.assertEquals(#sc:taunts(), taunts, "no second taunt")
end

TestRescueEscortStart = {}

function TestRescueEscortStart:setUp() H.reset() end

-- AC-5
function TestRescueEscortStart:test_nothing_changes_on_the_target_until_ten_seconds_after_the_dock()
	local sc = R.fresh(REP):toDocked()
	local t = sc:target()

	sc:atDock(secs(10) - 1)

	lu.assertEquals(R.callNames(t), { "setDockable" }, "no escort configuration one ms early")
	lu.assertEquals(t.dockableCalls, { true }, "still dockable")
end

-- AC-5
function TestRescueEscortStart:test_ten_seconds_after_the_dock_the_target_is_repaired_and_given_the_escort_route_then_released()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toDocked():escort()
		local t = sc:target()

		lu.assertEquals(R.callNames(t), { "setDockable", "repairShipAgent", "setFixedPatrol", "setEscort", "setEscortSpeed", "assignFixedPatrolPointsTable", "setDockable" },
			name .. ": escort calls in order, setDockable(false) last")
		lu.assertEquals(t.repairs, { 1 }, name .. ": repairShipAgent(1)")
		lu.assertEquals(t.fixedPatrolCalls, 1, name .. ": setFixedPatrol()")
		lu.assertEquals(t.escortCalls, 1, name .. ": setEscort()")
		lu.assertEquals(t.escortSpeeds, { R.ESCORT_SPEED }, name .. ": setEscortSpeed(50)")
		lu.assertEquals(t.patrolPointTables, { sc.o.pathNames }, name .. ": assignFixedPatrolPointsTable called with the single table of the path's point names in order, first point included")
		lu.assertEquals(#t.callLog[6].args, 1, name .. ": assignFixedPatrolPointsTable got exactly one argument")
		lu.assertEquals(t.dockableCalls, { true, false }, name .. ": dockableCalls == {true, false} (I-6)")
		lu.assertFalse(ShipAiAgent(t):isDockable(), name .. ": no longer dockable")
		lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "stage")), SpaceRescueScreenplay.STAGES.ESCORT, name .. ": stage = ESCORT")
		lu.assertTrue(sc:active(), name .. ": the quest is still active")
	end
end

-- AC-5
function TestRescueEscortStart:test_the_next_waypoint_refresh_uses_the_escort_details()
	local sc = R.fresh(REP):toEscort()

	H.advance(R.WAYPOINT_PERIOD)

	local wps = sc:waypoints()

	lu.assertEquals(#wps, 1, "still exactly one waypoint")
	lu.assertNotNil(tostring(wps[1].questDetails):find("quest_escort_d", 1, true), "details mention quest_escort_d, got " .. tostring(wps[1].questDetails))
end

-- AC-5
function TestRescueEscortStart:test_no_attack_ship_exists_before_the_first_period_after_the_escort_start()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toEscort()

		sc:atEscort(secs(sc.o.period) - 1)
		lu.assertEquals(#sc:attackSpawns(), 0, name .. ": no attack ship before escort + attackPeriod")
	end
end

-- AC-5, Behavior 7: an escort start for an ended run does nothing
function TestRescueEscortStart:test_the_escort_does_not_start_for_a_run_that_ended_after_the_dock()
	local sc = R.fresh(REP):toDocked()
	local t = sc:target()

	sc.quest:failQuest(sc.player, "true")
	sc:atDock(secs(60))

	lu.assertEquals(R.callNames(t), { "setDockable", "setDockable" }, "only the dockable true and the cleanup's false, no escort configuration")
	lu.assertEquals(#sc:attackSpawns(), 0, "no attack ship")
end

TestRescueArrival = {}

function TestRescueArrival:setUp() H.reset() end

local function completionEvents(sc) return R.createEvents("startQuest") end

-- AC-6
function TestRescueArrival:test_the_target_entering_the_destination_area_ends_the_escort()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toEscort()
		local t = sc:target()

		sc:atEscort(secs(5))
		sc:arrive()
		H.advance(0)

		lu.assertEquals(R.count(sc:events(), "recovery_success", "update"), 1, name .. ": recovery_success update after 0 ms")
		lu.assertTrue(sc:taskComplete(2), name .. ": task 2 complete")
		lu.assertEquals(R.tauntTimes(sc:taunts(), "complete"), { sc.tArrive }, name .. ": the 'complete' taunt at arrival")
		lu.assertEquals(sc:taunts()[#sc:taunts()].ship, t, name .. ": taunted by the target")
		lu.assertTrue(sc:active(), name .. ": the quest is not complete yet")
		lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "stage")), SpaceRescueScreenplay.STAGES.ARRIVED, name .. ": stage = ARRIVED")
	end
end

-- AC-6
function TestRescueArrival:test_the_quest_completes_three_seconds_after_arrival_and_the_target_leaves()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toEscort()
		local t = sc:target()

		sc:atEscort(secs(5))
		sc:arrive()
		H.advance(R.FINISH_DELAY - 1)

		lu.assertFalse(sc:complete(), name .. ": not complete 1 ms before the finish delay")

		H.advance(1)

		lu.assertTrue(sc:complete(), name .. ": the journal quest is complete at +3 s")
		lu.assertFalse(sc:active(), name .. ": and no longer active")
		lu.assertTrue(t.hyperspacing, name .. ": setHyperspacing(true) on the target")
		lu.assertEquals(#R.destroyEvents(t), 1, name .. ": one delayedDestroyShipAgent event")
		lu.assertEquals(R.destroyEvents(t)[1].delay, 2000, name .. ": destroyed 2 s later")
		lu.assertEquals(R.count(sc:events(), "complete", "update"), 0, name .. ": completeQuest sends no 'complete' update (D-9)")
	end
end

-- AC-6
function TestRescueArrival:test_completion_triggers_the_split_quest_only_for_4_b()
	local split = R.fresh(R.SPLIT):toEscort()

	split:arrive()
	H.advance(secs(10))

	lu.assertEquals(#R.createEvents("startQuest", "assassinate_corellia_rebel_tier4_4_a"), 1, "4_b: assassinate_corellia_rebel_tier4_4_a:startQuest event")

	local alerts = R.createEvents("sendQuestAlert", "SpaceHelpers")

	lu.assertEquals(#alerts, 1, "4_b: one split alert")
	lu.assertEquals(alerts[1][5], "@spacequest/rescue/corellia_rebel_tier4_4_b:split_quest_alert", "4_b: split_quest_alert message")

	for _, name in ipairs({ REP, R.RSF }) do
		local sc = R.fresh(name):toEscort()

		sc:arrive()
		H.advance(secs(10))

		lu.assertTrue(sc:complete(), name .. ": completed")
		lu.assertEquals(#completionEvents(sc), 0, name .. ": no startQuest event")
		lu.assertEquals(#R.createEvents("sendQuestAlert", "SpaceHelpers"), 0, name .. ": no split alert")
	end
end

-- AC-6
function TestRescueArrival:test_entering_the_area_twice_before_the_events_run_completes_once()
	local sc = R.fresh(R.SPLIT):toEscort()
	local t = sc:target()
	local area = sc:area()

	H.enterArea(area, t)
	H.enterArea(area, t)
	H.advance(secs(10))

	lu.assertEquals(#R.tauntTimes(sc:taunts(), "complete"), 1, "one 'complete' taunt")
	lu.assertEquals(R.count(sc:events(), "recovery_success", "update"), 1, "one recovery_success update")
	lu.assertEquals(#R.createEvents("startQuest", "assassinate_corellia_rebel_tier4_4_a"), 1, "the completion split fired once")
end

-- AC-6
function TestRescueArrival:test_the_observer_always_returns_0_and_acts_only_through_a_0_ms_event()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()
	local area = sc:area()

	lu.assertEquals(sc.quest:notifyEnteredQuestArea(area, nil), 0, "no ship")
	lu.assertEquals(sc.quest:notifyEnteredQuestArea(area, sc.ship), 0, "the player's ship")
	lu.assertEquals(sc.quest:notifyEnteredQuestArea(area, t), 0, "the target")
	lu.assertEquals(#sc:taunts(), 1, "no taunt inside the observer (only the dock's rescue_phase_2)")
	lu.assertEquals(R.count(sc:events(), "recovery_success"), 0, "nothing inside the observer")
	lu.assertTrue(H.hasObserver(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", area), "the observer stays on the area")
end

-- AC-6
function TestRescueArrival:test_entry_by_other_ships_changes_nothing()
	local sc = R.fresh(REP):toEscort()
	local area = sc:area()
	local t = sc:target()

	sc:atEscort(secs(sc.o.period))

	local attacker = R.wave(sc, 1).agents[1]
	local before = #sc:taunts()

	H.enterArea(area, sc.ship)
	H.enterArea(area, attacker)
	H.advance(secs(5))

	lu.assertEquals(R.count(sc:events(), "recovery_success"), 0, "no recovery_success for the player's ship or an attack ship")
	lu.assertEquals(#sc:taunts(), before, "no taunt")
	lu.assertTrue(sc:active(), "still active")
	lu.assertEquals(t.dockableCalls, { true, false }, "target untouched")
end

-- AC-6
function TestRescueArrival:test_the_target_entering_the_area_before_the_escort_stage_changes_nothing()
	local waiting = R.fresh(REP):toWaiting()

	H.enterArea(waiting:area(), waiting:target())
	H.advance(secs(5))
	lu.assertEquals(R.count(waiting:events(), "recovery_success"), 0, "stage DOCK: no recovery_success")
	lu.assertTrue(waiting:active(), "stage DOCK: still active")
	lu.assertFalse(waiting:taskComplete(2), "stage DOCK: task 2 not complete")

	local docked = R.fresh(REP):toDocked()

	H.enterArea(docked:area(), docked:target())
	H.advance(secs(5))
	lu.assertEquals(R.count(docked:events(), "recovery_success"), 0, "stage DOCKED: no recovery_success")
	lu.assertTrue(docked:active(), "stage DOCKED: still active")

	docked:escort()
	H.advance(secs(60))
	lu.assertEquals(R.count(docked:events(), "recovery_success"), 0, "an earlier entry does not complete the escort later")
	lu.assertTrue(docked:active(), "still active in the escort")
end

-- AC-6
function TestRescueArrival:test_entering_another_runs_area_changes_nothing()
	local first = R.fresh(REP):toEscort()
	local second = R.new(REP, { spies = first.spies })

	second:start()

	H.enterArea(second:area(), first:target())
	H.advance(secs(10))

	lu.assertEquals(R.count(first:events(), "recovery_success"), 0, "the first player's escort did not arrive in the second player's area")
	lu.assertTrue(first:active(), "first player's quest still active")
	lu.assertTrue(second:active(), "second player's quest untouched")
end

-- AC-6, Behavior 9: a target that is dead when the arrival event runs
function TestRescueArrival:test_the_escort_does_not_finish_twice_when_the_quest_is_failed_in_the_arrival_window()
	local sc = R.fresh(REP):toEscort()

	sc:arrive()
	H.advance(secs(1))
	sc.quest:failQuest(sc.player, "true")
	H.advance(secs(10))

	lu.assertFalse(sc:complete(), "the failed run is not completed by the stale finish event")
	lu.assertFalse(sc:active(), "and stays failed")
end

-- I-4: keys during the escort
function TestRescueArrival:test_every_shared_memory_key_during_the_escort_is_under_player_and_class()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(sc.o.period))

	lu.assertEquals(R.strayKeys(sc.player, sc.className), {}, "every key starts with <playerID>:<className>:")
end
