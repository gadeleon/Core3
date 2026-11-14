-- Survival failure paths and teardown (space-quest-stub-survival).
-- Spec: .claude/work/space-quest-stub-survival/01-spec.md (AC-8, AC-9, AC-10, I-4, I-5,
-- Behavior 7 to 9, decisions D-5 and D-6). Times are milliseconds after arrival unless named.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

S.load()
S.snapshotVm()

local function secs(n) return n * 1000 end

local ELSEWHERE = "space_tatooine"
local TIER41 = "corellia_rebel_tier4_1"

local function arrived(name)
	return S.fresh(name or TIER41):start():arrive()
end

TestSurvivalDistance = {}

function TestSurvivalDistance:setUp()
	H.reset()
end

-- AC-8
function TestSurvivalDistance:test_exactly_2000_m_away_is_in_range()
	local sc = arrived()

	sc:placeShip(2000, 0, 0)
	sc:at(secs(95))

	lu.assertEquals(S.count(sc:events(), "outofrange"), 0, "no warning at 2000 m (the limit is strictly greater)")
	lu.assertEquals(S.count(sc:events(), "outofrange_failed"), 0, "no failure either")
	lu.assertTrue(sc:active(), "still active")
end

-- AC-8
function TestSurvivalDistance:test_distances_are_3d_so_diagonal_offsets_inside_2000_are_in_range()
	local offsets = { { 1200, 1600, 0 }, { 0, 1200, 1600 }, { 1600, 0, 1200 }, { 1000, 1000, 1000 } }

	for _, d in ipairs(offsets) do
		local sc = arrived()

		sc:placeShip(d[1], d[2], d[3])
		sc:at(secs(95))

		lu.assertEquals(S.count(sc:events(), "outofrange"), 0, string.format("offset (%d, %d, %d) is within 2000 m", d[1], d[2], d[3]))
		lu.assertTrue(sc:active(), string.format("offset (%d, %d, %d): still active", d[1], d[2], d[3]))

		H.reset()
	end
end

-- AC-8
function TestSurvivalDistance:test_2001_m_on_any_single_axis_is_out_of_range_including_the_vertical_one()
	local axes = { x = { 2001, 0, 0 }, z = { 0, 2001, 0 }, y = { 0, 0, 2001 }, diagonal = { 1200, 1601, 0 } }

	for axis, d in pairs(axes) do
		local sc = arrived()

		sc:placeShip(d[1], d[2], d[3])
		sc:at(secs(30))

		lu.assertEquals(S.times(sc:events(), "outofrange", "message"), { sc.t0 + secs(30) }, axis .. ": outofrange warning at 30 s")

		H.reset()
	end
end

-- AC-8
function TestSurvivalDistance:test_first_check_is_at_30_seconds_warning_then_failure_at_60()
	local sc = arrived()

	sc:placeShip(2001, 0, 0)

	sc:at(secs(30) - 1)
	lu.assertEquals(S.count(sc:events(), "outofrange"), 0, "no warning before 30 s")

	sc:at(secs(30))
	lu.assertEquals(S.times(sc:events(), "outofrange", "message"), { sc.t0 + secs(30) }, "warning at 30 s")
	lu.assertEquals(S.count(sc:events(), "outofrange_failed"), 0, "not failed yet")
	lu.assertTrue(sc:active(), "quest still active after the first warning")

	sc:at(secs(60) - 1)
	lu.assertTrue(sc:active(), "still active just before the second check")

	sc:at(secs(60))
	lu.assertEquals(S.times(sc:events(), "outofrange_failed", "message"), { sc.t0 + secs(60) }, "outofrange_failed at 60 s")
	lu.assertEquals(S.count(sc:events(), "outofrange"), 1, "only one plain warning")
	lu.assertFalse(sc:active(), "the journal quest is cleared")
	lu.assertFalse(sc:complete(), "and not completed")
end

-- AC-8
function TestSurvivalDistance:test_failure_by_distance_goes_through_the_existing_failure_split()
	local sc = arrived()

	sc:placeShip(0, 0, 2500)
	sc:at(secs(60))
	H.advance(secs(10))

	lu.assertEquals(S.called(sc.spies.start), { "space_battle_corellia_rebel_tier4_1_b" }, "failure split starts battle 1_b")
	lu.assertEquals(S.called(sc.spies.fail), {}, "no parent or side quest to fail")
end

-- AC-8
function TestSurvivalDistance:test_back_in_range_clears_the_warning_and_a_later_excursion_only_warns_again()
	local sc = arrived()

	sc:placeShip(2001, 0, 0)
	sc:at(secs(45))
	sc:placeShip(0, 0, 0)
	sc:at(secs(75))
	sc:placeShip(2001, 0, 0)
	sc:at(secs(100))

	lu.assertEquals(S.times(sc:events(), "outofrange", "message"), { sc.t0 + secs(30), sc.t0 + secs(90) }, "warnings at 30 and 90 s")
	lu.assertEquals(S.count(sc:events(), "outofrange_failed"), 0, "never failed")
	lu.assertTrue(sc:active(), "still active")
end

-- AC-8
function TestSurvivalDistance:test_checks_keep_running_every_30_seconds()
	local sc = arrived()

	sc:placeShip(2001, 0, 0)
	sc:at(secs(35))
	sc:placeShip(0, 0, 0)
	sc:at(secs(65))
	sc:placeShip(2001, 0, 0)
	sc:at(secs(95))
	sc:placeShip(0, 0, 0)
	sc:at(secs(125))
	sc:placeShip(2001, 0, 0)
	sc:at(secs(155))

	lu.assertEquals(S.times(sc:events(), "outofrange", "message"), { sc.t0 + secs(30), sc.t0 + secs(90), sc.t0 + secs(150) }, "a warning at 30, 90 and 150 s")
	lu.assertTrue(sc:active(), "never two out-of-range checks in a row")
end

-- AC-8
function TestSurvivalDistance:test_no_checks_before_arrival()
	local sc = S.fresh(TIER41):start()

	sc:placeShip(5000, 0, 0)
	H.advance(secs(600))

	lu.assertEquals(S.count(sc:events(), "outofrange"), 0, "no range check before the player arrived")
	lu.assertTrue(sc:active(), "quest still active")
end

-- AC-8
function TestSurvivalDistance:test_no_checks_after_completion()
	local sc = arrived()

	sc:at(secs(316))
	lu.assertTrue(sc:complete(), "completed")

	sc:placeShip(9000, 0, 0)
	H.advance(secs(600))

	lu.assertEquals(S.count(sc:events(), "outofrange"), 0, "no warning after the quest is complete")
	lu.assertEquals(S.count(sc:events(), "outofrange_failed"), 0)
	lu.assertTrue(sc:complete(), "stays complete")
end

-- AC-8
function TestSurvivalDistance:test_the_distance_is_measured_to_the_transmission_point_of_each_quest()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name):start():arrive()

		sc:placeShip(0, 0, 0)
		sc:at(secs(95))
		lu.assertEquals(S.count(sc:events(), "outofrange"), 0, name .. ": at the point is in range")

		sc:placeShip(2001, 0, 0)
		sc:at(secs(125))
		lu.assertEquals(S.count(sc:events(), "outofrange", "message"), 1, name .. ": 2001 m from its own point is out of range")
	end
end

TestSurvivalAbandon = {}

function TestSurvivalAbandon:setUp()
	H.reset()
end

-- AC-9
function TestSurvivalAbandon:test_leaving_for_another_zone_after_arrival_fails_the_quest()
	local sc = arrived()

	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(5))

	lu.assertEquals(S.count(sc:events(), "survival_abandoned", "update"), 1, "@space/quest:survival_abandoned update sent once")
	lu.assertFalse(sc:active(), "journal quest no longer active")
	lu.assertFalse(sc:complete(), "and not complete")
end

-- AC-8 (space-quest-player-ship-destroyed, D-14): the respawn after a ship death is a same-zone switch; it is inert
function TestSurvivalAbandon:test_a_same_zone_switch_after_arrival_leaves_the_run_alone()
	local sc = arrived()

	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(secs(5))

	lu.assertEquals(S.count(sc:events(), "survival_abandoned", "update"), 0, "no survival_abandoned update")
	lu.assertTrue(sc:active(), "journal quest still active")
	lu.assertEquals(#S.createEvents("failQuest"), 0, "no failQuest event")
end

-- AC-9
function TestSurvivalAbandon:test_abandoning_goes_through_the_existing_failure_split()
	local sc = arrived()

	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(10))

	lu.assertEquals(S.called(sc.spies.start), { "space_battle_corellia_rebel_tier4_1_b" }, "the failure split is triggered like any failQuest")
end

-- AC-9
function TestSurvivalAbandon:test_abandoning_stops_the_timeline_and_the_waves()
	local sc = arrived()

	sc:at(secs(20))
	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(5))

	local before = #S.spawns()
	local eventsBefore = #sc:events()

	H.advance(secs(3600))

	lu.assertEquals(#S.spawns(), before, "no ship spawns after the quest was abandoned")
	lu.assertEquals(#sc:events(), eventsBefore, "no survival message after the quest was abandoned")
	lu.assertFalse(sc:active(), "still not active")
end

-- AC-9
function TestSurvivalAbandon:test_leaving_before_arrival_keeps_the_quest_and_its_waypoint()
	local sc = S.fresh(TIER41):start()

	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "quest still active")
	lu.assertEquals(#sc.player.ghost.waypoints, 1, "waypoint kept")
	lu.assertEquals(S.count(sc:events(), "survival_abandoned"), 0, "no abandon message before arrival")
	lu.assertEquals(#S.createEvents("failQuest", sc.className), 0, "no failQuest event for the quest")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "still waiting for the player to come back")
end

-- AC-9
function TestSurvivalAbandon:test_after_completion_changing_zone_does_nothing()
	local sc = arrived()

	sc:at(secs(316))
	lu.assertTrue(sc:complete(), "completed")
	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(10))

	lu.assertEquals(S.count(sc:events(), "survival_abandoned"), 0, "no abandon message")
	lu.assertTrue(sc:complete(), "still complete")
end

-- AC-9
function TestSurvivalAbandon:test_enteredZone_is_safe_for_a_player_without_the_quest_and_returns_a_number()
	S.fresh(TIER41)

	local quest = H.expectGlobal("survival_corellia_rebel_tier4_1")
	local stranger = H.newPlayer({ zone = ELSEWHERE, ship = {} })
	local ret = quest:enteredZone(stranger, nil, getHashCode("space_dathomir"))

	lu.assertEquals(type(ret), "number", "observer handlers must return a number")
	lu.assertEquals(#stranger.ghost.waypoints, 0, "nothing set up for a player without the quest")
	lu.assertEquals(quest:enteredZone(nil, nil, 0), 0, "a nil player is ignored")
end

-- AC-9 (relocation by a second quest instance of the same type)
function TestSurvivalAbandon:test_abandoning_one_survival_quest_does_not_touch_another_players_run()
	local first = S.fresh(TIER41):start()
	local second = S.new(TIER41, { spies = first.spies }):start()
	local areas = H.spawnedAreas()

	first:arrive(areas[1])
	second:arrive(areas[2])

	H.zoneSwitch(first.player, ELSEWHERE)
	H.advance(secs(5))

	lu.assertFalse(first:active(), "first player's quest failed")
	lu.assertTrue(second:active(), "second player's quest is untouched")
	lu.assertFalse(areas[2].destroyed == true, "second player's area is untouched")

	H.advance(secs(400))
	lu.assertEquals(S.count(second:events(), "mission_complete"), 1, "second player still completes")
end

TestSurvivalTeardown = {}

function TestSurvivalTeardown:setUp()
	H.reset()
end

local ENDINGS = {
	complete = function(sc) sc.quest:completeQuest(sc.player, "true") end,
	fail = function(sc) sc.quest:failQuest(sc.player, "true") end,
	reset = function(sc) sc.quest:resetQuest(sc.player) end,
}

local ENDING_NAMES = { "complete", "fail", "reset" }

-- Arrived at tier4_1 with two live waves (8 ships), one of which was already shot down.
local function midRun()
	local sc = arrived()

	sc:at(secs(70))

	local waves = S.waves()

	lu.assertEquals(#waves, 2, "precondition: two waves launched")
	H.destroyShip(waves[1].agents[1], sc.ship)

	local live = {}

	for w = 1, 2 do
		for _, agent in ipairs(waves[w].agents) do
			if not agent.destroyed then
				live[#live + 1] = agent
			end
		end
	end

	lu.assertEquals(#live, 7, "precondition: seven live ships")
	return sc, live, waves[1].agents[1]
end

local function hasDelayedDestroy(agent)
	for _, args in ipairs(H.Engine.callsTo("createEvent")) do
		if args[2] == "SpaceHelpers" and args[3] == "delayedDestroyShipAgent" and args[4] == agent then
			return args[1]
		end
	end

	return nil
end

-- AC-10
function TestSurvivalTeardown:test_ending_an_arrived_run_removes_ships_area_observers_waypoint_and_data()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc, live, dead = midRun()
		local area = sc:area()
		local label = ending .. ": "

		ENDINGS[ending](sc)

		for i, agent in ipairs(live) do
			lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), label .. "live ship " .. i .. ": SHIPDESTROYED observer dropped")
			lu.assertTrue(agent.hyperspacing, label .. "live ship " .. i .. ": made to hyperspace away")
			lu.assertEquals(hasDelayedDestroy(agent), 2000, label .. "live ship " .. i .. ": delayedDestroyShipAgent event 2000 ms out")

			for _, id in ipairs(sc.player.missionObjects) do
				lu.assertNotEquals(id, agent.objectID, label .. "live ship " .. i .. ": no longer a mission object")
			end
		end

		lu.assertEquals(#sc.player.missionObjects, 0, label .. "no mission objects left")
		lu.assertNil(hasDelayedDestroy(dead), label .. "the ship that was already destroyed gets no destroy event")

		lu.assertEquals(H.Engine.observersOn(area, ENTEREDAREA), {}, label .. "area observer dropped")
		lu.assertTrue(area.destroyed, label .. "area destroyed")
		lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), label .. "ZONESWITCHED observer dropped")
		lu.assertEquals(#sc.player.ghost.waypoints, 0, label .. "waypoint removed")
		lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), label .. "waypointID quest status removed")
		lu.assertEquals(S.memoryKeys(), {}, label .. "no shared-memory key left behind (I-4)")

		H.advance(secs(5))

		for i, agent in ipairs(live) do
			lu.assertTrue(agent.destroyed, label .. "live ship " .. i .. ": removed from the world after the delay")
		end
	end
end

-- AC-10
function TestSurvivalTeardown:test_ending_a_run_that_never_arrived_still_removes_area_waypoint_and_observers()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc = S.new(TIER41):start()
		local area = sc:area()
		local label = ending .. " before arrival: "

		ENDINGS[ending](sc)

		lu.assertEquals(H.Engine.observersOn(area, ENTEREDAREA), {}, label .. "area observer dropped")
		lu.assertTrue(area.destroyed, label .. "area destroyed")
		lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), label .. "ZONESWITCHED observer dropped")
		lu.assertEquals(#sc.player.ghost.waypoints, 0, label .. "waypoint removed")
		lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), label .. "waypointID quest status removed")
		lu.assertEquals(S.memoryKeys(), {}, label .. "no shared-memory key left behind")
	end
end

-- AC-10
function TestSurvivalTeardown:test_after_ending_the_pending_events_do_nothing()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc = midRun()
		local label = ending .. ": "

		ENDINGS[ending](sc)
		H.advance(secs(5)) -- let split and cleanup events run

		local spawns, areas, events = #S.spawns(), #H.spawnedAreas(), #sc:events()

		H.advance(secs(3600))

		lu.assertEquals(#S.spawns(), spawns, label .. "no ship spawned by a stale timer")
		lu.assertEquals(#H.spawnedAreas(), areas, label .. "no area spawned by a stale timer")
		lu.assertEquals(#sc:events(), events, label .. "no survival message from a stale timer")
	end
end

-- AC-10
function TestSurvivalTeardown:test_a_ship_destroyed_after_the_run_ended_is_ignored()
	local sc, live = midRun()

	sc.quest:failQuest(sc.player, "false")

	local before = #sc:events()

	for _, agent in ipairs(live) do
		H.destroyShip(agent, sc.ship)
	end

	H.advance(secs(10))
	lu.assertEquals(#sc:events(), before, "no attack_stopped or other message from a late kill")
end

-- AC-10
function TestSurvivalTeardown:test_start_arrive_fail_start_arrive_runs_a_clean_second_timeline()
	local sc = S.fresh(TIER41):start():arrive()
	local firstT0 = sc.t0

	sc:at(secs(20))
	lu.assertEquals(#S.waves(), 1, "precondition: the first run launched a wave")
	sc.quest:failQuest(sc.player, "true")
	lu.assertFalse(sc:active(), "first run failed")

	local failedAt = H.now()

	sc:start()
	lu.assertTrue(sc:active(), "second run active")
	lu.assertEquals(#H.spawnedAreas(), 2, "second run set up its own area")

	sc:arrive()

	local secondT0 = sc.t0
	local o = sc.o
	local step = o.total // o.updates
	local doneAt = secondT0 + secs(o.transStart + o.updates * step + 5)

	H.advance(doneAt - H.now() + secs(5))

	local events = sc:events()

	lu.assertEquals(S.times(events, "transmission_start", "message"), { firstT0 + secs(10), secondT0 + secs(10) }, "one transmission_start per arrival, none from stale timers")
	lu.assertEquals(S.count(events, "mission_complete"), 1, "the second run completes exactly once")
	lu.assertEquals(S.count(events, "transmission_received"), 1, "and receives exactly once")
	lu.assertEquals(#S.only(events, "trans_update"), o.updates - 1, "progress updates come from the second run only")
	lu.assertTrue(sc:complete(), "second run completed")

	local launchTimes = {}

	for _, w in ipairs(S.waves()) do
		launchTimes[#launchTimes + 1] = w.t
	end

	lu.assertEquals(launchTimes, { firstT0 + secs(10), secondT0 + secs(10), secondT0 + secs(10 + 60) },
		"first run: one wave; second run: two waves (cap of two live waves), none from the first run's timers")
	lu.assertEquals(failedAt >= secs(20), true, "sanity: the first run failed after its first wave")
end

-- I-4
function TestSurvivalTeardown:test_every_shared_memory_key_during_a_run_belongs_to_the_player_and_quest()
	local sc = arrived()

	lu.assertEquals(S.strayKeys(sc.player, sc.className), {}, "after arrival")

	sc:at(secs(70))
	lu.assertEquals(#S.waves(), 2, "precondition: two waves")
	lu.assertEquals(S.strayKeys(sc.player, sc.className), {}, "with two live waves")

	H.destroyShip(S.waves()[1].agents[1], sc.ship)
	lu.assertEquals(S.strayKeys(sc.player, sc.className), {}, "after a kill")
end

-- I-4
function TestSurvivalTeardown:test_a_completed_run_leaves_no_shared_memory_and_no_waypoint_status()
	local sc = arrived()

	sc:at(secs(320))

	lu.assertTrue(sc:complete(), "precondition: completed through the transmission")
	lu.assertEquals(S.memoryKeys(), {}, "no shared-memory key left")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), "no waypointID quest status left")
	lu.assertEquals(#sc.player.ghost.waypoints, 0, "no waypoint left")
end

-- I-4
function TestSurvivalTeardown:test_a_failed_run_leaves_no_shared_memory()
	local sc = arrived()

	sc:placeShip(3000, 0, 0)
	sc:at(secs(61))

	lu.assertFalse(sc:active(), "precondition: failed by distance")
	lu.assertEquals(S.memoryKeys(), {}, "no shared-memory key left")
end

TestSurvivalSecondVm = {}

function TestSurvivalSecondVm:setUp()
	H.reset()
	S.resetVm()
end

-- Fails run 1 at `failAt` seconds after its arrival, idles `idle` seconds, then starts and arrives
-- run 2 as if the next events were handled by a different Lua VM, and runs it to the end.
local function failThenRestartOnAnotherVm(failAt, idle)
	local sc = S.fresh(TIER41):start():arrive()
	local firstT0 = sc.t0

	sc:at(secs(failAt))
	sc.quest:failQuest(sc.player, "true")
	lu.assertFalse(sc:active(), "precondition: run 1 failed")

	H.advance(secs(idle))
	S.resetVm()
	sc:start()
	sc:arrive()

	local secondT0 = sc.t0

	H.advance(secs(400))

	return sc, firstT0, secondT0
end

-- AC-10, R-1: run identity must not depend on per-VM Lua state
function TestSurvivalSecondVm:test_events_of_a_failed_run_do_nothing_to_a_restart_handled_by_another_vm()
	local sc, firstT0, secondT0 = failThenRestartOnAnotherVm(20, 2)
	local events = sc:events()
	local o = sc.o

	lu.assertEquals(S.times(events, "transmission_start", "message"), { firstT0 + secs(10), secondT0 + secs(10) }, "one transmission_start per arrival")
	lu.assertEquals(#S.only(events, "trans_update"), o.updates - 1, "progress updates come from the second run only (4 of them), none from run 1's timers")
	lu.assertEquals(S.times(events, "mission_complete", "update"), { secondT0 + secs(315) }, "the second run completes 315 s after its own arrival, not earlier")
	lu.assertTrue(sc:complete(), "second run completed")

	local launches = {}

	for _, w in ipairs(S.waves()) do
		launches[#launches + 1] = w.t
	end

	lu.assertEquals(launches, { firstT0 + secs(10), secondT0 + secs(10), secondT0 + secs(70) }, "no second wave chain from run 1's launch timer")
end

-- AC-10, R-1: the later the restart, the earlier a stale end-of-mission timer would complete it
function TestSurvivalSecondVm:test_a_restart_long_after_the_failure_still_runs_a_full_transmission()
	local sc, firstT0, secondT0 = failThenRestartOnAnotherVm(60, 140)

	lu.assertEquals(S.times(sc:events(), "mission_complete", "update"), { secondT0 + secs(315) }, "completion exactly 315 s after the second arrival")
	lu.assertEquals(#S.only(sc:events(), "trans_update"), 4 + 0, "four progress updates in total")

	for _, t in ipairs(S.times(sc:events(), "trans_update")) do
		lu.assertTrue(t >= secondT0 + secs(70), "no progress update before the second run's own first one at +70 s (saw one at " .. (t - secondT0) .. " ms)")
	end
end

-- AC-10, R-1: the same holds for a run ended by abandoning and restarted in the zone
function TestSurvivalSecondVm:test_a_restart_after_abandoning_on_another_vm_also_starts_clean()
	local sc = S.fresh(TIER41):start():arrive()

	sc:at(secs(20))
	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(5))
	lu.assertFalse(sc:active(), "precondition: abandoned")

	S.resetVm()
	H.zoneSwitch(sc.player, sc.o.zone)
	sc:start()
	sc:arrive()

	local t0 = sc.t0

	H.advance(secs(400))

	lu.assertEquals(S.times(sc:events(), "mission_complete", "update"), { t0 + secs(315) }, "completion 315 s after the second arrival")
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 2, "one transmission_start per arrival")
end

TestSurvivalSafeTeardown = {}

function TestSurvivalSafeTeardown:setUp()
	H.reset()
end

-- I-5
function TestSurvivalSafeTeardown:test_ending_a_quest_that_never_started_raises_no_error()
	for _, name in ipairs(S.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local sc = S.new(name)

			ENDINGS[ending](sc)
			ENDINGS[ending](sc)
			H.advance(secs(60))

			lu.assertEquals(S.memoryKeys(), {}, name .. " " .. ending .. ": nothing written for a player who never started")
			lu.assertEquals(#H.spawnedAreas(), 0, name .. " " .. ending .. ": no area created by ending a quest")
			lu.assertEquals(#S.spawns(), 0, name .. " " .. ending .. ": no ship created by ending a quest")
		end
	end
end

-- I-5
function TestSurvivalSafeTeardown:test_ending_a_quest_that_was_started_but_never_arrived_raises_no_error_for_every_quest()
	for _, name in ipairs(S.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local sc = S.new(name):start()

			ENDINGS[ending](sc)
			ENDINGS[ending](sc)
			H.advance(secs(60))

			lu.assertEquals(S.memoryKeys(), {}, name .. " " .. ending .. ": no key left")
			lu.assertEquals(#sc.player.ghost.waypoints, 0, name .. " " .. ending .. ": no waypoint left")
		end
	end
end

-- I-5
function TestSurvivalSafeTeardown:test_ending_a_quest_that_started_in_another_zone_raises_no_error()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc = S.new(TIER41, { zone = ELSEWHERE })

		sc.quest:startQuest(sc.player, "")
		ENDINGS[ending](sc)
		H.advance(secs(60))

		lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), ending .. ": ZONESWITCHED observer dropped")
		lu.assertEquals(S.memoryKeys(), {}, ending .. ": no key left")
	end
end

-- I-5
function TestSurvivalSafeTeardown:test_cleanUpQuestData_takes_the_player_and_is_safe_without_a_run()
	local sc = S.fresh(TIER41)

	sc.quest:cleanUpQuestData(sc.player)
	sc:start()
	sc.quest:cleanUpQuestData(sc.player)

	lu.assertEquals(S.memoryKeys(), {}, "cleanup leaves no key")
end
