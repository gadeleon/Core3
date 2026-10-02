-- Rescue setup, zone entry, target warp-in and the Mission Target waypoint (space-quest-rescue-docking).
-- Spec: .claude/work/space-quest-rescue-docking/01-spec.md (AC-2, AC-3, I-4, I-6, Behavior 1 to 5).
-- Times are milliseconds on the harness clock. Expected numbers come from the SWG-Source fixtures
-- through rescue_scenario.lua.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")

R.load()

local function secs(n) return n * 1000 end

local REP = R.REP
local ELSEWHERE = "space_tatooine"

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

local function shipCalls() return H.Engine.callsTo("spawnShipAgent") end

TestRescueSetup = {}

function TestRescueSetup:setUp() H.reset() end

-- AC-2
function TestRescueSetup:test_start_in_the_quest_zone_spawns_one_destination_area_at_the_last_path_point()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):start()
		local o = sc.o
		local calls = areaCalls()

		lu.assertEquals(#calls, 1, name .. ": one spawnSpaceActiveArea call")
		lu.assertEquals({ calls[1][1], calls[1][2], calls[1][3], calls[1][4], calls[1][5], calls[1][6] },
			{ o.zone, R.AREA_TEMPLATE, o.last.x, o.last.z, o.last.y, R.AREA_RADIUS }, name .. ": area zone, template, last path point, radius 300")
		lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", sc:area()), 1, name .. ": exactly one ENTEREDAREA observer on the area")
	end
end

-- AC-2
function TestRescueSetup:test_setup_completes_task_0_activates_task_1_and_sends_the_progress_and_arrival_messages()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):start()
		local events = sc:events()

		lu.assertTrue(sc:active(), name .. ": journal quest active")
		lu.assertTrue(sc:taskComplete(0), name .. ": task 0 complete")
		lu.assertTrue(sc:taskActive(1), name .. ": task 1 active")
		lu.assertEquals(R.count(events, "title", "progress"), 1, name .. ": one in-progress message with the title")
		lu.assertEquals(R.count(events, "arrival_phase_1", "update"), 1, name .. ": one arrival_phase_1 update")
	end
end

-- AC-2
function TestRescueSetup:test_the_run_token_is_the_destination_area_id_and_the_stage_starts_at_warp()
	local sc = R.fresh(REP):start()
	local pid = sc.player.objectID
	local q = sc.quest

	lu.assertEquals(readData(q:dataKey(pid, "runID")), sc:area().objectID, "runID is the area's object id")
	lu.assertEquals(readData(q:dataKey(pid, "areaID")), sc:area().objectID, "areaID is the area's object id")
	lu.assertEquals(readData(q:dataKey(pid, "stage")), SpaceRescueScreenplay.STAGES.WARP, "stage = WARP")
	lu.assertEquals(q:getRunToken(pid), string.format("%d", sc:area().objectID), "getRunToken is the run id as a string")
	lu.assertTrue(q:isCurrentRun(sc.player, q:getRunToken(pid)), "isCurrentRun accepts the token")
	lu.assertFalse(q:isCurrentRun(sc.player, "1"), "isCurrentRun refuses another token")
end

-- AC-2
function TestRescueSetup:test_no_ship_spawns_before_the_arrival_delay_and_one_does_at_it()
	for _, name in ipairs({ REP, R.SPLIT }) do
		local sc = R.fresh(name):start()
		local delay = secs(sc.o.arrivalDelay)

		lu.assertEquals(delay > 0, true, name .. ": precondition, a positive arrival delay")

		H.advance(delay - 1)
		lu.assertEquals(#shipCalls(), 0, name .. ": no ship one ms before targetArrivalDelay")

		H.advance(1)
		lu.assertEquals(#shipCalls(), 1, name .. ": the target spawns at targetArrivalDelay")
	end
end

-- AC-2
function TestRescueSetup:test_start_while_on_the_ground_does_nothing_until_a_zone_switch_into_the_quest_zone_in_a_ship_plus_1_s()
	H.reset()

	local o = R.oracle(REP)
	local player = H.newPlayer({ zone = "", parent = "starport", pilot = "rebel" })
	local sc = R.new(REP, { player = player, ship = false })

	sc.quest:startQuest(player, "")
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "the journal quest is active")
	lu.assertEquals(#areaCalls(), 0, "no area on the ground")
	lu.assertFalse(sc:taskComplete(0), "task 0 not complete yet")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", player), "ZONESWITCHED observer registered")

	H.zoneSwitch(player, o.zone, { ship = { x = o.first.x, z = o.first.z, y = o.first.y } })
	lu.assertEquals(#areaCalls(), 0, "nothing inside the observer")

	H.advance(secs(1) - 1)
	lu.assertEquals(#areaCalls(), 0, "nothing one ms before the 1 s check")

	H.advance(1)
	lu.assertEquals(#areaCalls(), 1, "set up 1 s after the zone switch")
	lu.assertTrue(sc:taskComplete(0), "task 0 complete")
	lu.assertTrue(sc:taskActive(1), "task 1 active")
end

-- AC-2
function TestRescueSetup:test_start_in_another_zone_waits_for_the_quest_zone_and_a_second_entry_does_not_set_up_twice()
	local o = R.oracle(REP)
	local sc = R.fresh(REP, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 0, "no area in another zone")

	H.zoneSwitch(sc.player, o.zone)
	H.advance(300)
	H.zoneSwitch(sc.player, o.zone)
	H.advance(secs(5))

	lu.assertEquals(#areaCalls(), 1, "two entries before setup produce one setup")
	lu.assertEquals(R.count(sc:events(), "title", "progress"), 1, "one in-progress message")
	lu.assertEquals(R.count(sc:events(), "arrival_phase_1", "update"), 1, "one arrival_phase_1 update")

	H.advance(secs(10))
	lu.assertEquals(#shipCalls(), 1, "one target in the end")
end

-- AC-2
function TestRescueSetup:test_the_yacht_never_sets_up_but_a_ship_after_the_switch_does()
	local o = R.oracle(REP)
	local sc = R.fresh(REP, { ship = { objectName = "player_sorosuub_space_yacht" } })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 0, "no setup in the yacht at start")

	H.zoneSwitch(sc.player, o.zone)
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 0, "no setup after a zone switch that keeps the yacht")

	H.zoneSwitch(sc.player, o.zone, { ship = { x = o.first.x, z = o.first.z, y = o.first.y } })
	H.advance(secs(1))
	lu.assertEquals(#areaCalls(), 1, "set up once the player flies a ship")
end

-- AC-2
function TestRescueSetup:test_check_setup_does_nothing_for_an_inactive_quest_or_a_run_that_is_already_set_up()
	local sc = R.fresh(REP, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	sc.quest:failQuest(sc.player, "false")

	sc.player.zone = sc.o.zone
	sc.quest:checkSetup(sc.player)
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 0, "an inactive quest is not set up")

	local running = R.fresh(REP):start()

	running.quest:checkSetup(running.player)
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 1, "a run that is already set up is not set up again")
end

-- AC-2
function TestRescueSetup:test_starting_with_an_empty_string_npc_works_like_no_npc()
	local sc = R.fresh(REP)

	lu.assertTrue(pcall(function() sc.quest:startQuest(sc.player, "") end), "startQuest(player, \"\") raises no error")
	lu.assertTrue(sc:active(), "active")
end

-- Behavior 3: not active
function TestRescueSetup:test_zone_switch_events_for_an_inactive_quest_are_ignored_and_remove_the_observer()
	local sc = R.fresh(REP):start()

	sc.quest:failQuest(sc.player, "false")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "observer dropped by failQuest")

	lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(ELSEWHERE)), 1, "enteredZone returns 1 for an inactive quest")
end

TestRescueWarp = {}

function TestRescueWarp:setUp() H.reset() end

-- AC-3
function TestRescueWarp:test_the_target_spawns_100_to_200_m_from_the_first_path_point_with_the_player_ship_as_target()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toWaiting()
		local o = sc.o
		local spawns = R.spawns()

		lu.assertEquals(#spawns, 1, name .. ": exactly one spawnShipAgent call")
		lu.assertEquals(spawns[1].t, sc.tStart + secs(o.arrivalDelay), name .. ": spawn time = start + targetArrivalDelay")
		lu.assertEquals({ spawns[1].name, spawns[1].zone }, { o.targetShip, o.zone }, name .. ": ship template and zone")
		lu.assertEquals(spawns[1].target, sc.ship, name .. ": last argument is the player's ship")

		local d = R.distance(spawns[1], o.first)

		lu.assertTrue(d >= 100 - 1e-6 and d <= 200 + 1e-6, name .. ": 3D distance from the first recovery point is 100 to 200, got " .. d)
	end
end

-- AC-3
function TestRescueWarp:test_the_target_is_owned_allied_dockable_and_a_mission_object()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toWaiting()
		local t = sc:target()
		local hash = sc.ship.factionHash

		lu.assertEquals(t.missionOwner, sc.player, name .. ": mission owner is the player")
		lu.assertEquals(t.factionAllies, { hash }, name .. ": addSpaceFactionAlly(player's faction hash)")
		lu.assertEquals(t.removedFactionEnemies, { hash }, name .. ": removeSpaceFactionEnemy(player's faction hash)")
		lu.assertTrue(ShipAiAgent(t):isDockable(), name .. ": isDockable()")
		lu.assertEquals(t.dockableCalls, { true }, name .. ": dockableCalls == {true} while it waits (I-6)")
		lu.assertEquals(sc.player.missionObjectLog, { { id = t.objectID, last = true } }, name .. ": added as a mission object with notify true")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTargetDestroyed", t), name .. ": SHIPDESTROYED observer -> notifyTargetDestroyed")
		lu.assertEquals(t.engaged, {}, name .. ": the target engages nothing")
	end
end

-- AC-3
function TestRescueWarp:test_one_ship_docked_observer_is_on_the_player_and_arrival_phase_2_is_sent()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toWaiting()

		lu.assertEquals(H.Engine.observerCount(SHIPDOCKED, sc.className, "notifyDocked", sc.player), 1, name .. ": exactly one SHIPDOCKED observer on the player creature")
		lu.assertEquals(R.count(sc:events(), "arrival_phase_2", "update"), 1, name .. ": one arrival_phase_2 update")
		lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "stage")), SpaceRescueScreenplay.STAGES.DOCK, name .. ": stage = DOCK")
		lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "targetID")), sc:target().objectID, name .. ": targetID stored")
	end
end

-- AC-3, Behavior 4
function TestRescueWarp:test_a_target_with_arrival_delay_0_spawns_on_the_first_event_and_not_inside_start_quest()
	local sc = R.fresh(R.RSF)

	sc.tStart = H.now()
	sc.quest:startQuest(sc.player, "")
	lu.assertEquals(#shipCalls(), 0, "nothing spawned synchronously inside startQuest")
	lu.assertEquals(#areaCalls(), 1, "the area is made when startQuest runs")

	H.advance(0)

	lu.assertEquals(#shipCalls(), 1, "madersim_tier3 spawned after H.advance(0)")
	lu.assertEquals(shipCalls()[1][1], "madersim_tier3", "ship template")
	lu.assertEquals(H.Engine.timedCallsTo("spawnShipAgent")[1].t, 0, "at t = 0")
end

-- AC-3
function TestRescueWarp:test_there_is_exactly_one_mission_target_waypoint_with_the_dock_details_at_the_target()
	for _, name in ipairs(R.NAMES) do
		local sc = R.fresh(name):toWaiting()
		local t = sc:target()

		H.advance(R.WAYPOINT_FIRST_DELAY)

		local wps = sc:waypoints()

		lu.assertEquals(#wps, 1, name .. ": exactly one waypoint one second after the warp-in")
		lu.assertEquals(wps[1].name, "Mission Target", name .. ": waypoint name")
		lu.assertEquals(wps[1].planet, sc.o.zone, name .. ": waypoint planet")
		lu.assertEquals(wps[1].color, WAYPOINT_SPACE, name .. ": WAYPOINT_SPACE")
		lu.assertEquals(wps[1].special, WAYPOINTQUESTTASK, name .. ": WAYPOINTQUESTTASK")
		lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { t.x, t.z, t.y }, name .. ": waypoint at the target's position")
		lu.assertNotNil(wps[1].questDetails, name .. ": quest details set")
		lu.assertNotNil(tostring(wps[1].questDetails):find("quest_dock_d", 1, true), name .. ": details mention quest_dock_d, got " .. tostring(wps[1].questDetails))
		lu.assertEquals(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), tostring(wps[1].objectID), name .. ": waypointID quest status")
	end
end

-- AC-3
function TestRescueWarp:test_the_waypoint_follows_the_target_every_30_seconds_and_stays_single()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.advance(R.WAYPOINT_FIRST_DELAY)

	local first = sc:waypoints()[1]
	local tFirst = H.now()

	t:setPosition(t.x + 500, t.z + 40, t.y - 300)
	H.advance(R.WAYPOINT_PERIOD - 1)

	lu.assertEquals({ sc:waypoints()[1].x, sc:waypoints()[1].z, sc:waypoints()[1].y }, { first.x, first.z, first.y }, "not refreshed 1 ms early")

	H.advance(1)

	local wps = sc:waypoints()

	lu.assertEquals(H.now() - tFirst, R.WAYPOINT_PERIOD, "30 s after the first waypoint")
	lu.assertEquals(#wps, 1, "still exactly one waypoint")
	lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { t.x, t.z, t.y }, "now at the new position")
	lu.assertEquals(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), tostring(wps[1].objectID), "waypointID quest status follows the new waypoint")
	lu.assertTrue(first.destroyed, "the old waypoint object is gone")
end

-- AC-3, I-6: a target that waits is dockable and keeps its single dockable call
function TestRescueWarp:test_a_waiting_target_stays_dockable_and_untouched_for_ten_minutes()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.advance(secs(600))

	lu.assertEquals(t.dockableCalls, { true }, "dockableCalls == {true} (I-6)")
	lu.assertEquals(R.callNames(t), { "setDockable" }, "no escort configuration before the dock")
	lu.assertTrue(sc:active(), "the quest is still active")
	lu.assertEquals(#R.attackSpawns(sc), 0, "no attack ship before the escort stage")
end

-- I-4
function TestRescueWarp:test_every_shared_memory_key_of_a_run_is_under_player_and_class()
	local sc = R.fresh(REP):toWaiting()

	H.advance(secs(40))

	lu.assertTrue(#R.memoryKeys() > 0, "precondition: the run keeps some state")
	lu.assertEquals(R.strayKeys(sc.player, sc.className), {}, "every key starts with <playerID>:<className>:")
end

TestRescueSpawnFailure = {}

function TestRescueSpawnFailure:setUp() H.reset() end

-- Behavior 2 (area spawn failure)
function TestRescueSpawnFailure:test_an_area_that_cannot_be_created_logs_an_error_and_fails_the_quest()
	local sc = R.fresh(REP)

	H.Engine.config.areaFails = true
	sc:start()
	H.advance(secs(10))

	lu.assertTrue(#R.errorLogs() >= 1, "an LT_ERROR line was logged")
	lu.assertFalse(sc:active(), "the quest is failed")
	lu.assertEquals(#shipCalls(), 0, "no ship spawned")
	lu.assertEquals(R.memoryKeys(), {}, "nothing left behind")
end
