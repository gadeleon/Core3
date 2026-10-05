-- The corrected CorSec and Havoc points work at run time: escorts get a route in their own zone and can complete, the patrol and
-- the Kreezo mission put their waypoints on SWG's points (space-corsec-waypoints).
-- Spec: .claude/work/space-corsec-waypoints/01-spec.md (AC-8, W-1, W-3 to W-8).
--
-- Driven through the harness fakes (event clock, areas, agents). The expected values are the spec's literals
-- (space_corsec_waypoints_data.lua) and the patrol point files, never read back from the table under test.
-- "Reaches the area": the escort ship follows the names handed to assignFixedPatrolPointsTable, so it enters the active area that sits at
-- the patrol point file's coordinates of each name. An area that is somewhere else (x = 23729) is never entered.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local W = require("space_corsec_waypoints_data")

AC.load()

local function quest(global) return H.expectGlobal(global, "CorSec/Havoc quest table of the squadron screenplay") end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

-- the area spawned at exactly {x, z, y}, or nil
local function areaAt(x, z, y)
	for _, area in ipairs(H.spawnedAreas()) do
		if area.x == x and area.z == z and area.y == y then
			return area
		end
	end

	return nil
end

local function messageTo(player, id)
	for _, m in ipairs(H.messageLog(player)) do
		if m.TO == id then
			return m
		end
	end

	return nil
end

local function lastWaypoint(player)
	local list = player.ghost.waypoints

	return list[#list]
end

---------------------------------------------------------------------------------------------
-- AC-8 (1, 2, 3): the escort legs, one run per start index
---------------------------------------------------------------------------------------------

TestCorsecWaypointsEscortRuns = {}

function TestCorsecWaypointsEscortRuns:setUp() H.reset() end

function TestCorsecWaypointsEscortRuns:tearDown() AC.tearDown() end

-- Starts the quest, forces the rendezvous draw to `start`, and plays: waypoint, arrival, escort spawn, route, every area of the route.
-- `expected` = the spec's point list { { name, x, z, y, number }, ... }. Returns a table with what the run left.
local function playEscort(global, expected, start)
	local q = quest(global)
	local player = AC.started(q) -- resets the harness, starts the quest in its zone, 0 ms events
	local label = global .. " (rendezvous " .. start .. ")"

	H.Engine.queueRandom(1, #q.escortPoints, start)
	pump(2500, label .. " setupEscort")

	local point = expected[start]
	local waypoint = lastWaypoint(player)

	lu.assertNotNil(waypoint, label .. ": a rendezvous waypoint was added")
	lu.assertEquals({ waypoint.planet, waypoint.x, waypoint.z, waypoint.y }, { q.questZone, point[2], point[3], point[4] }, label .. ": rendezvous waypoint {zone, x, z, y} (" .. point[1] .. ")")

	local area = areaAt(point[2], point[3], point[4])

	lu.assertNotNil(area, label .. ": an active area sits at the rendezvous " .. point[1])
	H.enterArea(area, player.rootParent)

	lu.assertNotNil(messageTo(player, "@spacequest/" .. q.questType .. "/" .. q.questName .. ":arrived_at_loc"), label .. ": arrived_at_loc was sent")

	pump(6000, label .. " spawnEscortShip")

	local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(agent, label .. ": the escorted ship spawned")
	pump(5000, label .. " assignEscortPoints")

	return { q = q, player = player, agent = agent, label = label }
end

-- AC-8 (3): the route handed to the escort agent exists in the quest zone; (1, 2) every area of it can be entered; the escort completes
local function flyRoute(run)
	local q, player, agent, label = run.q, run.player, run.agent, run.label
	local tables = agent.patrolPointTables

	lu.assertEquals(#tables, 1, label .. ": assignFixedPatrolPointsTable was called once")

	local names = tables[1]
	local patrol = H.patrolPoints(q.questZone)

	lu.assertTrue(#names >= 1, label .. ": the escort ship got a non-empty route")

	for i, name in ipairs(names) do
		lu.assertNotNil(patrol[name], label .. ": route[" .. i .. "] " .. name .. " exists in ship_mobile/patrol_points/" .. q.questZone .. ".lua")
	end

	for i, name in ipairs(names) do
		local p = patrol[name]
		local area = areaAt(p.x, p.z, p.y)

		lu.assertNotNil(area, label .. ": route[" .. i .. "] " .. name .. ": an active area sits at its patrol point (" .. p.x .. ", " .. p.z .. ", " .. p.y .. ")")
		H.enterArea(area, agent)
	end

	lu.assertNotNil(messageTo(player, "@spacequest/" .. q.questType .. "/" .. q.questName .. ":complete"), label .. ": the escort reached its last area and the quest sent :complete")

	return names
end

local function finish(run, isDuty)
	local q, player = run.q, run.player

	pump(1500, run.label .. " completeQuest")

	if isDuty then
		lu.assertTrue(player.bankCredits > 0, run.label .. ": the duty paid the pilot")
	else
		local ghost = CreatureObject(player):getPlayerObject()

		lu.assertTrue(PlayerObject(ghost):isJournalQuestComplete(H.questCrc(q.questType, q.questName)), run.label .. ": the journal quest is complete")
	end
end

local RUNS = {
	{ W.TUROLDINE_DUTY, W.TUROLDINE_DUTY_POINTS, true, "turoldine_escort_duty" },
	{ W.RIKKH_M2, W.RIKKH_M2_POINTS, false, "rikkh_mission_2_escort" },
	{ W.RIKKH_DUTY, W.RIKKH_DUTY_POINTS, true, "rikkh_escort_duty" },
}

for _, run in ipairs(RUNS) do
	local global, points, isDuty, short = run[1], run[2], run[3], run[4]

	for start = 1, #points do
		-- AC-8 (1, 3)
		TestCorsecWaypointsEscortRuns["test_" .. short .. "_with_rendezvous_" .. start .. "_arrives_flies_its_route_and_completes"] = function()
			local r = playEscort(global, points, start)

			flyRoute(r)
			finish(r, isDuty)
		end
	end
end

-- AC-8 (2): Turoldine mission 2's escort has five points and the fifth start used to begin nothing
for start = 1, 5 do
	-- the five SWG points (T/escort/corellia_privateer_tier4_2b.tab), their values from the buildout extract
	local points = {}

	for i = 1, 5 do
		local name = "corellia_privateer_tier4_leg_2_escort_" .. i
		local row = W.extract("space_dathomir").nav[name]

		points[i] = { name, row and row.x, row and row.z, row and row.y, i }
	end

	TestCorsecWaypointsEscortRuns["test_turoldine_mission_2_escort_with_rendezvous_" .. start .. "_arrives_flies_its_route_and_completes"] = function()
		local r = playEscort(W.TUROLDINE_M2_ESCORT, points, start)

		flyRoute(r)
		finish(r, false)
	end
end

-- AC-8 (3): the route is the other points of the table, never the start (Rikkh mission 2)
function TestCorsecWaypointsEscortRuns:test_rikkh_mission_2_route_is_the_three_other_yavin4_points()
	local r = playEscort(W.RIKKH_M2, W.RIKKH_M2_POINTS, 2)
	local names = r.agent.patrolPointTables[1]
	local sorted = {}

	for i, name in ipairs(names) do
		sorted[i] = name
	end

	table.sort(sorted)

	lu.assertEquals(sorted, { "yavin4_privateer_escort_1", "yavin4_privateer_escort_3", "yavin4_privateer_escort_4" }, W.RIKKH_M2 .. ": route names (start 2 excluded)")
end

-- AC-8 (3): Rikkh's duty flies the Lok points
function TestCorsecWaypointsEscortRuns:test_rikkh_escort_duty_route_is_the_three_other_lok_points()
	local r = playEscort(W.RIKKH_DUTY, W.RIKKH_DUTY_POINTS, 3)
	local sorted = {}

	for i, name in ipairs(r.agent.patrolPointTables[1]) do
		sorted[i] = name
	end

	table.sort(sorted)

	lu.assertEquals(sorted, { "lok_privateer_escort_1", "lok_privateer_escort_2", "lok_privateer_escort_4" }, W.RIKKH_DUTY .. ": route names (start 3 excluded)")
end

---------------------------------------------------------------------------------------------
-- AC-8 (1, 2, 5): the active areas of start()
---------------------------------------------------------------------------------------------

TestCorsecWaypointsAreas = {}

function TestCorsecWaypointsAreas:setUp() H.reset() end

local function startAreas(global)
	local q = quest(global)

	H.reset()
	q:start()

	return q, areaCalls()
end

-- AC-8 (1)
function TestCorsecWaypointsAreas:test_turoldine_escort_duty_start_spawns_four_areas_all_inside_the_zone()
	local q, calls = startAreas(W.TUROLDINE_DUTY)

	lu.assertEquals(#calls, 4, W.TUROLDINE_DUTY .. ": spawnSpaceActiveArea calls")

	local seen = {}

	for i, args in ipairs(calls) do
		lu.assertEquals(args[1], "space_dathomir", W.TUROLDINE_DUTY .. ": area " .. i .. " zone")

		for k = 3, 5 do
			lu.assertTrue(args[k] >= -8192 and args[k] < 8192, W.TUROLDINE_DUTY .. ": area " .. i .. " coordinate " .. (k - 2) .. " = " .. tostring(args[k]) .. " is inside the zone")
		end

		seen[#seen + 1] = { args[3], args[4], args[5] }
	end

	local want = {}

	for i, row in ipairs(W.TUROLDINE_DUTY_POINTS) do
		want[i] = { row[2], row[3], row[4] }
	end

	lu.assertEquals(seen, want, W.TUROLDINE_DUTY .. ": area positions in order (one at 2372, 7391, -1995)")
end

-- AC-8 (2)
function TestCorsecWaypointsAreas:test_turoldine_mission_2_escort_start_spawns_five_areas_numbered_1_to_5()
	local q, calls = startAreas(W.TUROLDINE_M2_ESCORT)

	lu.assertEquals(#calls, 5, W.TUROLDINE_M2_ESCORT .. ": spawnSpaceActiveArea calls")

	local numbers = {}

	for i, area in ipairs(H.spawnedAreas()) do
		numbers[i] = readData(area.objectID .. ":" .. q.className)
	end

	lu.assertEquals(numbers, { 1, 2, 3, 4, 5 }, W.TUROLDINE_M2_ESCORT .. ": the escort number stored on each area")
end

-- AC-8 (1): the area numbers of the duty match the draw
function TestCorsecWaypointsAreas:test_turoldine_escort_duty_areas_are_numbered_1_to_4()
	local q = startAreas(W.TUROLDINE_DUTY)
	local numbers = {}

	for i, area in ipairs(H.spawnedAreas()) do
		numbers[i] = readData(area.objectID .. ":" .. q.className)
	end

	lu.assertEquals(numbers, { 1, 2, 3, 4 }, W.TUROLDINE_DUTY .. ": the escort number stored on each area")
end

-- AC-8 (5)
function TestCorsecWaypointsAreas:test_ramna_mission_3_patrol_start_spawns_its_four_areas_at_the_swg_points()
	local q, calls = startAreas(W.RAMNA_M3_PATROL)

	lu.assertEquals(#calls, 4, W.RAMNA_M3_PATROL .. ": spawnSpaceActiveArea calls")

	local seen, want = {}, {}

	for i, args in ipairs(calls) do
		lu.assertEquals(args[1], "space_dantooine", W.RAMNA_M3_PATROL .. ": area " .. i .. " zone")
		seen[i] = { args[3], args[4], args[5] }
	end

	for i, row in ipairs(W.RAMNA_M3_PATROL_POINTS) do
		want[i] = { row[2], row[3], row[4] }
	end

	lu.assertEquals(seen, want, W.RAMNA_M3_PATROL .. ": area positions in order")

	local distinct = {}

	for _, pos in ipairs(seen) do
		distinct[table.concat(pos, ",")] = true
	end

	local n = 0

	for _ in pairs(distinct) do n = n + 1 end

	lu.assertEquals(n, 4, W.RAMNA_M3_PATROL .. ": four distinct positions")
end

-- AC-8 (5): Rikkh's two escorts spawn their four areas at the new points
function TestCorsecWaypointsAreas:test_rikkh_mission_2_escort_start_spawns_four_areas_in_yavin4()
	local q, calls = startAreas(W.RIKKH_M2)
	local seen, want = {}, {}

	lu.assertEquals(#calls, 4, W.RIKKH_M2 .. ": spawnSpaceActiveArea calls")

	for i, args in ipairs(calls) do
		lu.assertEquals(args[1], "space_yavin4", W.RIKKH_M2 .. ": area " .. i .. " zone")
		seen[i] = { args[3], args[4], args[5] }
	end

	for i, row in ipairs(W.RIKKH_M2_POINTS) do
		want[i] = { row[2], row[3], row[4] }
	end

	lu.assertEquals(seen, want, W.RIKKH_M2 .. ": area positions in order")
end

-- AC-8 (5)
function TestCorsecWaypointsAreas:test_rikkh_escort_duty_start_spawns_four_areas_in_lok()
	local q, calls = startAreas(W.RIKKH_DUTY)
	local seen, want = {}, {}

	lu.assertEquals(#calls, 4, W.RIKKH_DUTY .. ": spawnSpaceActiveArea calls")

	for i, args in ipairs(calls) do
		lu.assertEquals(args[1], "space_lok", W.RIKKH_DUTY .. ": area " .. i .. " zone")
		seen[i] = { args[3], args[4], args[5] }
	end

	for i, row in ipairs(W.RIKKH_DUTY_POINTS) do
		want[i] = { row[2], row[3], row[4] }
	end

	lu.assertEquals(seen, want, W.RIKKH_DUTY .. ": area positions in order")
end

---------------------------------------------------------------------------------------------
-- AC-8 (4): Kreezo mission 2
---------------------------------------------------------------------------------------------

TestCorsecWaypointsKreezo = {}

function TestCorsecWaypointsKreezo:setUp() H.reset() end

function TestCorsecWaypointsKreezo:tearDown() AC.tearDown() end

-- AC-8 (4)
function TestCorsecWaypointsKreezo:test_a_pilot_entering_space_corellia_gets_four_waypoints_on_the_swg_tie_spawners()
	local q = quest(W.KREEZO_M2)
	local player = AC.started(q, { zone = "space_naboo" }) -- the pilot takes the mission elsewhere, then enters the system

	lu.assertEquals(#player.ghost.waypoints, 0, W.KREEZO_M2 .. ": no waypoint before entering " .. q.questZone)
	H.zoneSwitch(player, "space_corellia")

	local have = {}

	for i, wp in ipairs(player.ghost.waypoints) do
		have[i] = { x = wp.x, z = wp.z, y = wp.y }
	end

	local want = {}

	for i, p in ipairs(W.KREEZO_M2_LOCATIONS) do
		want[i] = { x = p.x, z = p.z, y = p.y }
	end

	lu.assertEquals(have, want, W.KREEZO_M2 .. ": waypoint positions in order (imperial_fighter_five/one/seven/three_spawner)")
end

-- AC-8 (4): every waypoint is on a spawner the Core3 space spawner file defines
function TestCorsecWaypointsKreezo:test_each_waypoint_is_at_a_core3_space_spawner()
	local spawners = H.spawners("space_corellia")

	for i, p in ipairs(W.KREEZO_M2_LOCATIONS) do
		local s = spawners[p.patrolPointName]

		lu.assertNotNil(s, W.KREEZO_M2 .. ": the Core3 space_corellia spawner " .. p.patrolPointName)
		lu.assertEquals({ x = W.trunc(s.x), z = W.trunc(s.z), y = W.trunc(s.y) }, { x = p.x, z = p.z, y = p.y }, W.KREEZO_M2 .. ": spawner " .. i .. " " .. p.patrolPointName .. " {x, z, y}")
	end
end
