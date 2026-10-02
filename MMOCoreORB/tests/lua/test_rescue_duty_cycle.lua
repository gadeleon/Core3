-- Duty rescue: the first rescue (rotated route, random ship), the dock phrase, arrival and pay, the next
-- rescue and the kill bonus (space-quest-rescue-duty).
-- Spec: .claude/work/space-quest-rescue-duty/01-spec.md (AC-2, AC-3, AC-4, AC-5, I-4, I-6, I-7, Behavior 1 to 4).
-- Times are milliseconds on the harness clock. Every expected value comes from the SWG-Source .tab fixtures.

local lu = require("luaunit")
local H = require("harness")
local DR = require("rescue_duty_scenario")

DR.load()
DR.snapshotVm()

local function secs(n) return n * 1000 end

local REP = DR.REP
local STAGE = { WARP = 1, DOCK = 2, DOCKED = 3, ESCORT = 4, ARRIVED = 5 }

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

-- x, z, y of the nth spawnSpaceActiveArea call
local function areaAt(n)
	local a = areaCalls()[n]

	lu.assertNotNil(a, "spawnSpaceActiveArea call " .. n)
	return { zone = a[1], template = a[2], x = a[3], z = a[4], y = a[5], radius = a[6] }
end

local function point(p)
	return { x = p.x, z = p.z, y = p.y }
end

local function areaPoint(n)
	local a = areaAt(n)
	return { x = a.x, z = a.z, y = a.y }
end

local function progressMessages(sc) return DR.only(sc:events(), "title", "progress") end

local function sorted(list)
	table.sort(list)
	return list
end

local function setOf(list)
	local s = {}

	for _, v in ipairs(list) do
		s[v] = true
	end

	return s
end

TestDutyFirstRescue = {}

function TestDutyFirstRescue:setUp() H.reset() end

-- AC-2
function TestDutyFirstRescue:test_default_draws_put_the_area_at_the_last_point_and_the_first_ship_near_the_first_point()
	local sc = DR.fresh(REP):toWaiting()
	local o = sc.o

	lu.assertEquals(#areaCalls(), 1, "one destination area")
	lu.assertEquals(areaAt(1).zone, "space_dantooine", "area zone")
	lu.assertEquals(areaPoint(1), point(o.path[5]), "default rotation start 1: the area is at the last point, " .. o.pathNames[5])

	local targets = DR.targetSpawns(sc)

	lu.assertEquals(#targets, 1, "one target spawned")
	lu.assertEquals(targets[1].name, "reb_xwing_tier4", "default ship index 1")
	lu.assertEquals(targets[1].t, sc.tStart + secs(o.arrivalDelay), "spawned targetArrivalDelay after setup")
	lu.assertEquals(targets[1].zone, "space_dantooine", "spawn zone")

	local d = DR.distance(targets[1], o.path[1])

	lu.assertTrue(d >= 100 - 1e-6 and d <= 200 + 1e-6, "3D distance from " .. o.pathNames[1] .. " is 100 to 200, got " .. d)
end

-- AC-2
function TestDutyFirstRescue:test_one_in_progress_message_and_one_arrival_phase_1_for_the_first_rescue()
	local sc = DR.fresh(REP):toWaiting()
	local progress = progressMessages(sc)

	lu.assertEquals(#progress, 1, "exactly one quest_in_progress")
	lu.assertEquals(progress[1].TO, DR.title(REP), "quest_in_progress carries the duty title")
	lu.assertEquals(DR.count(sc:events(), "arrival_phase_1", "update"), 1, "arrival_phase_1 once")
	lu.assertEquals(sc:data("cycle"), 0, "cycle 0 (first rescue)")
end

-- AC-2
function TestDutyFirstRescue:test_rotation_start_3_and_ship_4_move_the_area_the_spawn_and_the_escort_route()
	local sc = DR.fresh(REP)
	local o = sc.o

	DR.draws(sc, 3, 4)
	sc:toWaiting()

	lu.assertEquals(areaPoint(1), point(o.path[2]), "area at the rotated last point " .. o.pathNames[2])

	local targets = DR.targetSpawns(sc)

	lu.assertEquals(#targets, 1, "one target")
	lu.assertEquals(targets[1].name, "reb_ykl37r_tier4", "ship index 4")

	local d = DR.distance(targets[1], o.path[3])

	lu.assertTrue(d >= 100 - 1e-6 and d <= 200 + 1e-6, "spawned 100-200 m from the rotated first point " .. o.pathNames[3] .. ", got " .. d)

	H.advance(5000)
	sc:dock():escort()

	lu.assertEquals(sc:target().patrolPointTables, { { o.pathNames[3], o.pathNames[4], o.pathNames[5], o.pathNames[1], o.pathNames[2] } },
		"assignFixedPatrolPointsTable gets the rotated names")
end

-- AC-2, I-7
function TestDutyFirstRescue:test_the_choices_are_stored_and_do_not_change_between_calls_or_vms()
	local sc = DR.fresh(REP)
	local o = sc.o
	local pid = sc.player.objectID

	DR.draws(sc, 3, 4)
	sc:toWaiting()

	lu.assertEquals(sc:data("pathStart"), 3, "stored pathStart")
	lu.assertEquals(sc:data("shipIndex"), 4, "stored shipIndex")

	-- later draws must not be consumed by repeated calls
	H.Engine.queueRandom(1, 5, 5, 5)
	H.Engine.queueRandom(1, 7, 6, 6)

	local want = DR.rotated(o.pathNames, 3)

	for round = 1, 3 do
		if round == 3 then
			DR.resetVm()
		end

		local names = {}

		for i, p in ipairs(sc.quest:pathPoints(pid)) do
			names[i] = p.patrolPointName
		end

		lu.assertEquals(names, want, "pathPoints, call " .. round)
		lu.assertEquals(sc.quest:pickTargetShip(pid), "reb_ykl37r_tier4", "pickTargetShip, call " .. round)
	end

	lu.assertEquals(sc:data("pathStart"), 3, "pathStart unchanged")
	lu.assertEquals(sc:data("shipIndex"), 4, "shipIndex unchanged")
end

-- AC-2
function TestDutyFirstRescue:test_path_points_returns_a_rotated_copy_and_leaves_the_quest_table_alone()
	local sc = DR.fresh(REP)
	local o = sc.o
	local before = {}

	for i, p in ipairs(sc.quest.recoveryPath) do
		before[i] = p.patrolPointName
	end

	DR.draws(sc, 2, 1)
	sc:start()

	local path = sc.quest:pathPoints(sc.player.objectID)

	lu.assertEquals(#path, 5, "5 points")
	lu.assertEquals(path[1].patrolPointName, o.pathNames[2], "starts at the rotation start")
	lu.assertEquals({ path[1].x, path[1].z, path[1].y }, { o.path[2].x, o.path[2].z, o.path[2].y }, "points keep their coordinates")

	local after = {}

	for i, p in ipairs(sc.quest.recoveryPath) do
		after[i] = p.patrolPointName
	end

	lu.assertEquals(after, before, "the quest's own recoveryPath is not rotated in place")
end

-- AC-2: the single ship quest and a different zone path
function TestDutyFirstRescue:test_corsec_duty_spawns_its_one_heavy_freighter_near_a_rotated_first_point()
	local sc = DR.fresh(DR.CORSEC)
	local o = sc.o

	DR.draws(sc, 2, nil)
	sc:toWaiting()

	lu.assertEquals(areaPoint(1), point(o.path[1]), "rotation start 2: the area is at the last rotated point, " .. o.pathNames[1])

	local targets = DR.targetSpawns(sc)

	lu.assertEquals(#targets, 1, "one target")
	lu.assertEquals(targets[1].name, "freighterheavy_tier4", "the only target ship")
	lu.assertEquals(targets[1].t, sc.tStart + secs(10), "the CorSec arrival delay is 10 s")
	lu.assertTrue(DR.distance(targets[1], o.path[2]) <= 200 + 1e-6, "spawned near " .. o.pathNames[2])
end

-- AC-2, edge: empty and single-element lists
function TestDutyFirstRescue:test_empty_lists_return_nothing_and_write_nothing()
	local quest = SpaceDutyRescueScreenplay:new {
		className = "test_duty_empty", questName = "corellia_rebel_tier4_1", questType = "rescue_duty", questZone = "space_dantooine",
		recoveryPath = {}, targetShipTypes = {},
	}

	rawset(_G, quest.className, quest)

	lu.assertEquals(quest:pathPoints(42), {}, "empty recoveryPath")
	lu.assertEquals(quest:pickTargetShip(42), "", "empty targetShipTypes")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "nothing written for empty lists")
	rawset(_G, quest.className, nil)
end

-- AC-2, edge
function TestDutyFirstRescue:test_single_element_lists_always_return_that_element()
	local quest = SpaceDutyRescueScreenplay:new {
		className = "test_duty_single", questName = "corellia_rebel_tier4_1", questType = "rescue_duty", questZone = "space_dantooine",
		recoveryPath = { { patrolPointName = "only_point", x = 1, z = 2, y = 3 } }, targetShipTypes = { "reb_xwing_tier4" },
	}

	rawset(_G, quest.className, quest)
	H.Engine.nextRandom = 1

	local path = quest:pathPoints(43)

	lu.assertEquals(#path, 1, "one point")
	lu.assertEquals(path[1].patrolPointName, "only_point", "the only point")
	lu.assertEquals(quest:pickTargetShip(43), "reb_xwing_tier4", "the only ship")
	rawset(_G, quest.className, nil)
end

-- AC-2: a degenerate duty fails cleanly like a rescue with no data
function TestDutyFirstRescue:test_a_duty_with_no_path_or_no_ship_fails_cleanly_at_setup()
	for variant, mutate in pairs({ emptyPath = function(q) q.recoveryPath = {} end, emptyShips = function(q) q.targetShipTypes = {} end }) do
		H.reset()

		local quest = SpaceDutyRescueScreenplay:new {
			className = "test_duty_" .. variant, questName = "corellia_rebel_tier4_1", questType = "rescue_duty", questZone = "space_dantooine",
			recoveryPath = { { patrolPointName = "p1", x = 1, z = 2, y = 3 } }, targetShipTypes = { "reb_xwing_tier4" },
			attackShipLists = {}, attackPeriod = 60, attackListType = 1, numResponses = 5,
		}

		mutate(quest)
		rawset(_G, quest.className, quest)

		local player = H.newPlayer({ zone = "space_dantooine", ship = {}, pilot = "rebel" })
		local ok, err = pcall(function()
			quest:startQuest(player, "")
			H.advance(secs(60))
		end)

		lu.assertTrue(ok, variant .. ": no Lua error, got " .. tostring(err))
		lu.assertTrue(#DR.errorLogs() >= 1, variant .. ": an LT_ERROR line was logged")
		lu.assertEquals(#H.spawnedShips(), 0, variant .. ": nothing spawned")
		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "rescue_duty", "corellia_rebel_tier4_1"), variant .. ": the quest ends not active")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, variant .. ": no shared-memory key left behind")
		rawset(_G, quest.className, nil)
	end
end

TestDutyDock = {}

function TestDutyDock:setUp() H.reset() end

-- AC-3
function TestDutyDock:test_docking_taunts_rescue_phase_2_n_with_n_from_the_response_count()
	local sc = DR.fresh(REP)

	sc:toWaiting()
	H.advance(5000)
	H.Engine.queueRandom(1, 5, 4)
	sc:dock()

	lu.assertEquals(DR.count(sc:events(), "docking_complete", "update"), 1, "docking_complete update")
	lu.assertEquals(DR.tauntTimes(sc:taunts(), "rescue_phase_2_4"), { sc.tDock }, "taunt rescue_phase_2_4 at the dock")
	lu.assertEquals(#sc:taunts(), 1, "no other taunt yet")
	lu.assertTrue(sc:taskComplete(1), "task 1 complete")
	lu.assertTrue(sc:taskActive(2), "task 2 active")
	lu.assertEquals(sc:data("stage"), STAGE.DOCKED, "stage DOCKED")
end

-- AC-3
function TestDutyDock:test_the_dock_phrase_range_follows_num_responses_of_each_quest()
	for _, name in ipairs(DR.NAMES) do
		H.reset()

		local sc = DR.fresh(name)

		sc:toWaiting()
		H.advance(5000)
		H.Engine.queueRandom(1, sc.o.responses, sc.o.responses)
		sc:dock()

		lu.assertEquals(DR.tauntTimes(sc:taunts(), "rescue_phase_2_" .. sc.o.responses), { sc.tDock }, name .. ": taunt rescue_phase_2_" .. sc.o.responses)
	end
end

-- AC-3
function TestDutyDock:test_default_draws_give_rescue_phase_2_1()
	local sc = DR.fresh(REP):toDocked()

	lu.assertEquals(DR.tauntTimes(sc:taunts(), "rescue_phase_2_1"), { sc.tDock }, "the minimum draw gives phrase 1")
end

-- AC-3
function TestDutyDock:test_the_escort_starts_ten_seconds_after_the_dock_with_the_rotated_route_and_the_first_wave_is_a_list_aimed_at_the_target()
	local sc = DR.fresh(REP)
	local o = sc.o

	DR.draws(sc, 3, 4)
	sc:toDocked()

	lu.assertTrue(#sc:target().patrolPointTables == 0, "no escort route before the escort start")
	H.Engine.queueRandom(1, 3, 2)
	sc:escort()
	lu.assertEquals(sc:data("stage"), STAGE.ESCORT, "stage ESCORT")

	local target = sc:target()

	lu.assertEquals(target.escortCalls, 1, "setEscort once")
	lu.assertEquals(target.escortSpeeds, { 50 }, "escort speed 50")
	lu.assertEquals(target.patrolPointTables, { DR.rotated(o.pathNames, 3) }, "the rotated names")
	lu.assertEquals(target.dockableCalls[#target.dockableCalls], false, "released last")

	sc:atEscort(secs(o.period) - 1)
	lu.assertEquals(#sc:attackSpawns(), 0, "no wave before attackPeriod")

	sc:atEscort(secs(o.period))

	local wave = sc:wave(1)

	lu.assertEquals(wave.t, sc.tEscort + secs(o.period), "first wave attackPeriod after the escort start")
	lu.assertEquals(DR.names(wave), o.lists[2], "the wave is attackShipLists[getRandomNumber(1, 3)]")

	for _, s in ipairs(wave.spawns) do
		lu.assertEquals(s.target, target, "the wave is aimed at the rescue target")
	end
end

TestDutyArrival = {}

function TestDutyArrival:setUp() H.reset() end

-- A Havoc duty in the escort with one wave alive when the target arrives.
local function arrivalWithLiveWave()
	local sc = DR.fresh(REP):toEscort()

	sc:atEscort(secs(sc.o.period))

	local wave = sc:wave(1)

	sc:atEscort(secs(sc.o.period) + secs(10))
	sc.liveWave = wave
	return sc
end

-- AC-4
function TestDutyArrival:test_arrival_pays_the_reward_tells_the_player_and_keeps_the_journal_active_at_t0()
	local sc = arrivalWithLiveWave()
	local completion = sc:spyCompletion()
	local failCalls = H.spyOn(sc.quest, "failQuest")

	sc:arrive()

	lu.assertEquals(#sc:payments(), 0, "nothing is paid inside the ENTEREDAREA observer")
	H.advance(0)

	local t0 = sc.tArrive

	lu.assertEquals(DR.times(sc:events(), "recovery_success", "update"), { t0 }, "recovery_success update at arrival")
	lu.assertEquals(DR.tauntTimes(sc:taunts(), "complete"), { t0 }, "taunt 'complete' (not complete_n)")

	for _, taunt in ipairs(sc:taunts()) do
		lu.assertNil(taunt.key:match("^complete_"), "no complete_<n> taunt, got " .. taunt.key)
	end

	local rewards = DR.only(sc:events(), "rescue_reward", "reward")

	lu.assertEquals(#rewards, 1, "one rescue_reward system message")
	lu.assertEquals(rewards[1].DI, sc.o.reward, "@space/quest:rescue_reward carries DI = reward (5000)")
	lu.assertEquals(rewards[1].t, t0, "sent at arrival")
	lu.assertEquals(sc:payments(), { { t = t0, amount = 5000, notify = true } }, "addBankCredits(5000, true)")
	lu.assertTrue(sc:active(), "the journal quest is still active")
	lu.assertFalse(sc:complete(), "and not complete")
	lu.assertEquals(#completion.space, 0, "SpaceHelpers:completeSpaceQuest never called")
	lu.assertEquals(#completion.quest, 0, "completeQuest never called")
	lu.assertEquals(#failCalls, 0, "failQuest never called")
	lu.assertEquals(#DR.createEvents("finishQuest"), 0, "finishQuest is never scheduled")
	lu.assertEquals(#DR.createEvents("startQuest"), 0, "no split or follow-up quest started")
	lu.assertEquals(sc:data("rewardShips"), 0, "rewardShips is 0 after the payment")
	lu.assertEquals(sc:data("stage"), STAGE.ARRIVED, "stage ARRIVED")
	lu.assertTrue(sc:taskComplete(2), "the inherited arrival completes task 2")
end

-- AC-4
function TestDutyArrival:test_both_duties_pay_their_tab_reward()
	for _, name in ipairs(DR.NAMES) do
		H.reset()

		local sc = DR.fresh(name):toEscort()

		sc:arrived()
		lu.assertEquals(DR.amounts(sc.player), { sc.o.reward }, name .. ": paid .tab reward")
		lu.assertEquals(DR.rewardMessages(sc.player), { sc.o.reward }, name .. ": rescue_reward DI")
	end
end

-- AC-4
function TestDutyArrival:test_two_seconds_later_the_target_attackers_area_and_waypoint_are_released()
	local sc = arrivalWithLiveWave()
	local live = sc.liveWave.agents

	lu.assertEquals(#live, 4, "the first wave has 4 ships")
	sc:arrived()

	local target = sc:target()
	local area = sc:area()
	local t0 = sc.tArrive

	sc:atArrival(DR.CLEANUP_DELAY - 1)
	lu.assertFalse(target.hyperspacing, "the target is still there at t=1.999")
	lu.assertFalse(area.destroyed == true, "the area is still there at t=1.999")
	lu.assertEquals(#sc:waypoints(), 1, "the waypoint is still there at t=1.999")

	sc:atArrival(DR.CLEANUP_DELAY)

	lu.assertTrue(target.hyperspacing, "the target gets setHyperspacing(true)")
	lu.assertEquals(DR.destroyEvents(target), { { t = t0 + DR.CLEANUP_DELAY, delay = 2000 } }, "delayedDestroyShipAgent for the target, once")
	lu.assertFalse(target.dockable, "no longer dockable")

	for i, agent in ipairs(live) do
		lu.assertTrue(agent.hyperspacing, "live attack ship " .. i .. " is hyperspacing")
		lu.assertEquals(#DR.destroyEvents(agent), 1, "live attack ship " .. i .. " has a delayed destroy")
	end

	lu.assertTrue(area.destroyed == true, "the area is destroyed")
	lu.assertEquals(#sc:waypoints(), 0, "the waypoint is cleared")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), "the waypointID quest status is removed")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "SHIPDOCKED dropped")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED stays registered")
	lu.assertTrue(sc:active(), "still active")
end

-- AC-4, I-4
function TestDutyArrival:test_between_the_cleanup_and_the_next_rescue_only_the_run_markers_remain()
	local sc = arrivalWithLiveWave()

	sc:arrived()
	sc:atArrival(secs(5))

	local allowed = setOf(DR.BETWEEN_KEYS)

	for _, key in ipairs(sc:keyNames()) do
		lu.assertTrue(allowed[key], "unexpected key between rescues: " .. key .. " (all: " .. table.concat(sc:keyNames(), ", ") .. ")")
	end

	lu.assertEquals(sc:strayKeys(), {}, "no key outside <playerID>:<className>:")
	lu.assertEquals(sc:data("areaID"), 0, "areaID deleted")
	lu.assertEquals(sc:data("targetID"), 0, "targetID deleted")
	lu.assertNotEquals(sc:data("runID"), 0, "runID kept until the next rescue")
	lu.assertEquals(sc:data("stage"), STAGE.ARRIVED, "stage kept")
	lu.assertEquals(sc:data("waveCount"), 0, "no wave data")
end

-- AC-4
function TestDutyArrival:test_ten_seconds_later_the_next_rescue_is_set_up_without_a_second_in_progress_message()
	local sc = arrivalWithLiveWave()

	sc:arrived()

	local firstRun = sc:runID()
	local firstArea = sc:area()

	sc:atArrival(DR.NEXT_DELAY - 1)
	lu.assertEquals(#areaCalls(), 1, "no new area before t=10")
	sc:atArrival(DR.NEXT_DELAY)

	lu.assertEquals(#areaCalls(), 2, "a new destination area at t=10")
	lu.assertNotEquals(sc:area(), firstArea, "a different area object")
	lu.assertNotEquals(sc:runID(), firstRun, "a new run token")
	lu.assertNotEquals(sc:runID(), 0, "the new run token is set")
	lu.assertEquals(sc:data("areaID"), sc:runID(), "areaID is the new run's token")
	lu.assertEquals(sc:data("stage"), STAGE.WARP, "stage WARP")
	lu.assertEquals(sc:data("cycle"), 1, "cycle 1")
	lu.assertEquals(DR.times(sc:events(), "arrival_phase_1", "update"), { sc.tStart, sc.tArrive + DR.NEXT_DELAY }, "arrival_phase_1 again at t=10")
	lu.assertEquals(#progressMessages(sc), 1, "no second quest_in_progress")
	lu.assertTrue(sc:taskActive(1), "task 1 is active")
	lu.assertFalse(sc:taskComplete(1), "task 1 is not complete")
	lu.assertFalse(sc:taskActive(2), "task 2 is cleared (not active)")
	lu.assertFalse(sc:taskComplete(2), "task 2 is cleared (not complete)")
	lu.assertTrue(sc:active(), "the journal quest is still active")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED stays registered")
end

-- AC-4, I-4
function TestDutyArrival:test_after_the_next_cycle_only_cycle_and_the_new_runs_keys_exist()
	local sc = arrivalWithLiveWave()

	sc:arrived()
	sc:nextRescue()

	local allowed = setOf({ "cycle", "runID", "areaID", "stage", "pathStart", "shipIndex" })

	for _, key in ipairs(sc:keyNames()) do
		lu.assertTrue(allowed[key], "unexpected key after nextCycle: " .. key .. " (all: " .. table.concat(sc:keyNames(), ", ") .. ")")
	end

	lu.assertEquals(sc:strayKeys(), {}, "no key outside <playerID>:<className>:")
	lu.assertEquals(sc:data("targetID"), 0, "no target yet")
	lu.assertEquals(sc:data("killsPending"), 0, "killsPending reset")
end

-- AC-4
function TestDutyArrival:test_three_seconds_after_that_the_second_target_spawns_and_a_second_full_rescue_pays_again()
	local sc = arrivalWithLiveWave()

	sc:arrived()

	local firstArrival = sc.tArrive

	sc:nextRescue()

	lu.assertEquals(#sc:targets(), 1, "only the first target before the warp-in")
	sc:atArrival(DR.NEXT_DELAY + secs(sc.o.arrivalDelay) - 1)
	lu.assertEquals(#sc:targets(), 1, "still one target at t=12.999")
	sc:warp()

	lu.assertEquals(#sc:targets(), 2, "the second target spawns at t=13")
	lu.assertEquals(DR.targetSpawns(sc)[2].t, sc.tArrive + DR.NEXT_DELAY + secs(sc.o.arrivalDelay), "second target spawn time")

	H.advance(5000)
	sc:dock():escort():arrived()

	lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 }, "the second rescue pays again")
	lu.assertEquals(DR.rewardMessages(sc.player), { 5000, 5000 }, "and tells the player again")
	lu.assertEquals(DR.count(sc:events(), "recovery_success", "update"), 2, "recovery_success twice")
	lu.assertEquals(DR.tauntTimes(sc:taunts(), "complete"), { firstArrival, sc.tArrive }, "complete taunted at both arrivals")
	lu.assertTrue(sc:active(), "still active after the second rescue")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED stays registered")
end

-- AC-4
function TestDutyArrival:test_the_next_rescue_gets_its_own_random_route_and_ship()
	local sc = DR.fresh(REP):toEscort()
	local o = sc.o

	sc:arrived()
	DR.draws(sc, 4, 7)
	sc:nextRescue()
	sc:warp()

	lu.assertEquals(areaPoint(2), point(o.path[3]), "second area at the rotated last point (start 4: {4,5,1,2,3})")
	lu.assertEquals(sc:target().shipName, "reb_freighterlight_tier4", "second target is ship 7")
	lu.assertEquals(sc:data("pathStart"), 4, "pathStart replaced")
	lu.assertEquals(sc:data("shipIndex"), 7, "shipIndex replaced")

	H.advance(5000)
	sc:dock():escort()

	lu.assertEquals(sc:target().patrolPointTables, { DR.rotated(o.pathNames, 4) }, "second escort route")
end

-- AC-4
function TestDutyArrival:test_a_stale_old_target_cannot_be_docked_in_the_next_rescue()
	local sc = DR.fresh(REP):toEscort()

	sc:arrived()

	local old = sc:target()

	sc:nextRescue()
	sc:warp()

	local fresh = sc:target()

	lu.assertNotEquals(fresh, old, "a new target")

	local before = DR.count(sc:events(), "docking_complete", "update")

	H.dock(sc.player, old)
	H.advance(0)
	lu.assertEquals(DR.count(sc:events(), "docking_complete", "update"), before, "docking the old target does nothing")
	lu.assertEquals(sc:data("stage"), STAGE.DOCK, "still waiting for the dock")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, old, 0), 0, "SHIPDOCKED for the old target returns 0 (not removed)")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, fresh, 0), 1, "SHIPDOCKED for the own target returns 1")
end

TestDutyKillBonus = {}

function TestDutyKillBonus:setUp() H.reset() end

-- AC-5, Behavior 4
function TestDutyKillBonus:test_killing_the_whole_wave_then_arriving_pays_the_bonus_for_each_ship()
	for _, name in ipairs(DR.NAMES) do
		H.reset()

		local sc = DR.fresh(name)

		DR.alwaysFirstList(sc)
		sc:toEscort()
		sc:atEscort(secs(sc.o.period))

		local wave = sc:wave(1)
		local ships = #wave.agents

		lu.assertEquals(ships, 4, name .. ": list 1 has 4 ships")
		DR.killWave(sc, wave)
		H.advance(0)
		lu.assertEquals(sc:data("rewardShips"), ships, name .. ": the cleared set's kills are rewardShips")
		lu.assertEquals(sc:data("killsPending"), 0, name .. ": killsPending reset on the last kill")

		sc:arrived()
		lu.assertEquals(DR.amounts(sc.player), { sc.o.reward + ships * sc.o.killReward }, name .. ": 5000 + 4 x 300 = 6200")
		lu.assertEquals(DR.amounts(sc.player), { 6200 }, name .. ": 6200 literally")
		lu.assertEquals(DR.rewardMessages(sc.player), { 6200 }, name .. ": the reward message carries 6200")
		lu.assertEquals(sc:data("rewardShips"), 0, name .. ": rewardShips is 0 after the payment")
	end
end

-- AC-5
function TestDutyKillBonus:test_kills_in_a_set_that_is_not_cleared_are_counted_aside_until_it_is()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period))

	local wave = sc:wave(1)

	DR.killSome(sc, wave, 2)
	H.advance(0)
	lu.assertEquals(sc:data("killsPending"), 2, "two kills pending")
	lu.assertEquals(sc:data("rewardShips"), 0, "nothing rewarded yet")
end

-- AC-5
function TestDutyKillBonus:test_two_kills_with_two_ships_alive_at_arrival_pay_nothing_extra_and_are_not_carried_over()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period))

	local wave = sc:wave(1)

	DR.killSome(sc, wave, 2)
	sc:arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "only the base reward")

	sc:nextRescue()
	lu.assertEquals(sc:data("killsPending"), 0, "the pending kills are dropped at nextCycle")
	sc:warp()
	H.advance(5000)
	sc:dock():escort()
	sc:atEscort(secs(sc.o.period))

	local wave2 = DR.attackWaves(sc)[2]

	lu.assertNotNil(wave2, "the second rescue launches its own wave")
	DR.killWave(sc, wave2)
	sc:arrived()

	lu.assertEquals(DR.amounts(sc.player), { 5000, 6200 }, "the second rescue pays 5000 + 4 x 300; the two old kills are not carried")
end

-- AC-5
function TestDutyKillBonus:test_two_waves_cleared_together_pay_for_every_ship()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period) * 2)

	local w1, w2 = sc:wave(1), sc:wave(2)

	DR.killWave(sc, w1)
	lu.assertEquals(sc:data("rewardShips"), 0, "the first wave's kills are pending, the second wave is still alive")
	DR.killWave(sc, w2)
	H.advance(0)
	lu.assertEquals(sc:data("rewardShips"), #w1.agents + #w2.agents, "both waves' kills are rewarded when the live set empties")

	sc:arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000 + 8 * 300 }, "5000 + 8 x 300")
end

-- AC-5
function TestDutyKillBonus:test_a_pending_launch_does_not_lose_the_last_kill_of_the_first_wave()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period) * 3)

	local w1, w2 = sc:wave(1), sc:wave(2)

	lu.assertEquals(#DR.attackWaves(sc), 2, "two live waves, the third is pending (cap of 2)")
	lu.assertEquals(sc:data("wavePending"), 1, "the third launch is pending")

	DR.killWave(sc, w1)
	H.advance(0)

	local w3 = sc:wave(3)

	lu.assertEquals(#DR.attackWaves(sc), 3, "the pending wave launched when wave 1 was cleared")
	local stopped = 0

	for _, e in ipairs(H.messageLog(sc.player)) do
		if e.id == "@spacequest/rescue_duty/" .. REP .. ":attack_stopped" then
			stopped = stopped + 1
		end
	end

	lu.assertEquals(stopped, 0, "no attack_stopped message while the third wave is alive")

	DR.killWave(sc, w2)
	DR.killWave(sc, w3)
	H.advance(0)

	local killed = #w1.agents + #w2.agents + #w3.agents

	lu.assertEquals(sc:data("rewardShips"), killed, "every ship killed while the live set emptied counts (" .. killed .. ")")

	sc:arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000 + killed * 300 }, "5000 + killed x 300")
	lu.assertEquals(sc:data("rewardShips"), 0, "rewardShips is 0 after the payment")
end

-- AC-5, edge: no kills at all
function TestDutyKillBonus:test_arriving_without_any_wave_pays_only_the_base_reward()
	local sc = DR.fresh(REP):toEscort()

	sc:atEscort(secs(30))
	sc:arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "5000, no bonus")
end

-- AC-5, I-4: pending kills never leak past the end of the duty
function TestDutyKillBonus:test_counters_are_gone_when_the_duty_is_taken_again()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period))
	DR.killWave(sc, sc:wave(1))
	H.advance(0)
	lu.assertEquals(sc:data("rewardShips"), 4, "four kills rewarded so far")

	sc.quest:resetQuest(sc.player)
	lu.assertEquals(sc:keyNames(), {}, "the reset removes every duty key, including rewardShips")

	sc:start()
	sc:warp()
	H.advance(5000)
	sc:dock():escort():arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "the new duty pays 5000, not 6200")
end

TestDutyPostArrivalKills = {}

function TestDutyPostArrivalKills:setUp() H.reset() end

-- R-1 (04-review.md), SWG-Source rescue_duty.java:
--   recoveryComplete (RD:147-182) pays reward + rewardships x killReward, then removeObjVar(self, "rewardships") (RD:169-171)
--   and later initializedQuestPlayer (10 s) -- but "deadships" is NOT cleared at payment; it is cleared by the next init
--   (RD:44-104). recovery.java (RV:817-847) still adds deadships to rewardships when the live set empties, in the 2 s
--   between the payment and the cleanup. So a set completed in the post-arrival window is paid at the NEXT arrival.
-- Core3 counting rule (spec Behavior 4): killsPending counts every kill of the current set, a cleared set moves
-- killsPending into rewardShips, nextCycle drops killsPending only. Kills before arrival that did not clear the set
-- therefore still count when the rest of the set dies in the window.

-- Escort with a 4-ship wave alive, arrival right now; `before` ships of it are killed before the arrival.
local function arrivalWithWave(before)
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period))

	local wave = sc:wave(1)

	DR.killSome(sc, wave, before)
	sc:arrived()
	return sc, wave
end

-- Kills agents first+1 .. last of the wave (the ones still alive), as the player's weapons would.
local function killRange(sc, wave, first, last)
	for i = first, last do
		H.destroyShip(wave.agents[i], sc.ship)
	end

	H.advance(0)
end

-- A whole second rescue with no kills, from the state "next rescue set up" to its arrival.
local function plainNextRescue(sc)
	sc:nextRescue()
	sc:rescue()
end

-- R-1
function TestDutyPostArrivalKills:test_a_set_cleared_after_the_payment_is_not_paid_now_but_at_the_next_arrival()
	local sc, wave = arrivalWithWave(0)

	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "the arrival pays the base reward")
	sc:atArrival(1000)
	killRange(sc, wave, 1, 4)

	lu.assertEquals(sc:data("rewardShips"), 4, "the cleared set's four kills are carried as rewardShips")
	sc:atArrival(secs(5))
	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "nothing more is paid for the rescue that already paid")
	lu.assertEquals(sc:data("rewardShips"), 4, "the carry-over survives the cleanup")

	plainNextRescue(sc)
	lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 + 4 * 300 }, "the next arrival pays 5000 + 4 x 300 = 6200")
	lu.assertEquals(DR.rewardMessages(sc.player), { 5000, 6200 }, "and tells the player 6200")
	lu.assertEquals(sc:data("rewardShips"), 0, "rewardShips is 0 after that payment")
end

-- R-1: kills before the arrival that did not clear the set still count (SWG deadships persists)
function TestDutyPostArrivalKills:test_kills_before_the_arrival_count_when_the_rest_of_the_set_dies_in_the_window()
	local sc, wave = arrivalWithWave(2)

	lu.assertEquals(DR.amounts(sc.player), { 5000 }, "two kills of four: base reward only")
	sc:atArrival(1000)
	killRange(sc, wave, 3, 4)
	lu.assertEquals(sc:data("rewardShips"), 4, "2 + 2 kills count once the set is cleared")

	plainNextRescue(sc)
	lu.assertEquals(DR.amounts(sc.player), { 5000, 6200 }, "paid at the next arrival, 4 ships")
end

-- R-1: a window kill that does not clear the set is dropped at nextCycle, like any pending kill
function TestDutyPostArrivalKills:test_a_partly_killed_set_in_the_window_pays_nothing_later()
	local sc, wave = arrivalWithWave(0)

	sc:atArrival(1000)
	killRange(sc, wave, 1, 2)
	lu.assertEquals(sc:data("rewardShips"), 0, "nothing rewarded: two ships are still alive")

	plainNextRescue(sc)
	lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 }, "the second rescue pays only the base reward")
end

-- R-1: no double counting
function TestDutyPostArrivalKills:test_the_carry_over_is_paid_once_and_adds_to_the_next_rescues_own_kills()
	local sc, wave = arrivalWithWave(0)

	sc:atArrival(1000)
	killRange(sc, wave, 1, 4)
	sc:nextRescue()
	sc:warp()
	H.advance(5000)
	sc:dock():escort()
	sc:atEscort(secs(sc.o.period))

	local wave2 = DR.attackWaves(sc)[2]

	lu.assertNotNil(wave2, "the second rescue launches its own wave")
	DR.killWave(sc, wave2)
	sc:arrived()
	lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 + 8 * 300 }, "carried 4 + own 4 = 8 ships, 7400")

	plainNextRescue(sc)
	lu.assertEquals(DR.amounts(sc.player), { 5000, 7400, 5000 }, "the third rescue pays the base reward only")
end

-- R-1: the same window kills in the other quest (CorSec has the same kill reward)
function TestDutyPostArrivalKills:test_the_carry_over_works_for_both_duties()
	for _, name in ipairs(DR.NAMES) do
		H.reset()

		local sc = DR.fresh(name)

		DR.alwaysFirstList(sc)
		sc:toEscort()
		sc:atEscort(secs(sc.o.period))

		local wave = sc:wave(1)

		sc:arrived()
		sc:atArrival(1000)
		killRange(sc, wave, 1, #wave.agents)
		plainNextRescue(sc)
		lu.assertEquals(DR.amounts(sc.player), { sc.o.reward, sc.o.reward + #wave.agents * sc.o.killReward }, name .. ": carried kills paid at the next arrival")
	end
end

-- R-1: ending the duty before the next arrival pays nothing and leaves nothing
function TestDutyPostArrivalKills:test_leaving_before_the_next_arrival_pays_nothing_and_leaves_no_key()
	for _, ending in ipairs({ "leave", "respawn", "reset" }) do
		H.reset()

		local sc, wave = arrivalWithWave(0)

		sc:atArrival(1000)
		killRange(sc, wave, 1, 4)
		lu.assertEquals(sc:data("rewardShips"), 4, ending .. ": kills carried")
		sc:atArrival(secs(5))

		if ending == "leave" then
			H.zoneSwitch(sc.player, DR.ELSEWHERE)
			H.advance(0)
		elseif ending == "respawn" then
			H.zoneSwitch(sc.player, DR.ZONE)
			H.advance(0)
		else
			sc.quest:resetQuest(sc.player)
		end

		lu.assertEquals(sc:keyNames(), {}, ending .. ": no duty key remains (rewardShips included)")
		lu.assertEquals(sc:strayKeys(), {}, ending .. ": no stray key")
		lu.assertEquals(DR.amounts(sc.player), { 5000 }, ending .. ": nothing extra was paid")
		H.advance(secs(7200))
		lu.assertEquals(DR.amounts(sc.player), { 5000 }, ending .. ": nothing is paid later either")

		-- the duty taken again starts clean: no stale carry-over
		H.zoneSwitch(sc.player, DR.ZONE)
		sc:start()
		sc:warp()
		H.advance(5000)
		sc:dock():escort():arrived()
		lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 }, ending .. ": the new duty pays 5000, not 6200")
	end
end

-- R-1: only the window counts, not the time after the cleanup
function TestDutyPostArrivalKills:test_attackers_destroyed_after_the_cleanup_earn_nothing()
	local sc, wave = arrivalWithWave(0)

	sc:atArrival(DR.CLEANUP_DELAY)
	killRange(sc, wave, 1, 4)
	lu.assertEquals(sc:data("rewardShips"), 0, "the attackers were already released at 2 s")
	plainNextRescue(sc)
	lu.assertEquals(DR.amounts(sc.player), { 5000, 5000 }, "no bonus")
end
