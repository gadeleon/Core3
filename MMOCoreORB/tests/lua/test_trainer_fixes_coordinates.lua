-- Coordinates of the Havoc quests whose points had none (recovery duty tier 4, escort duty tier 4, the two
-- Dathomir assassinations), against the SWG tables, the buildout extracts and the patrol point files.
-- Spec: .claude/work/space-trainer-fixes/01-spec.md (AC-10, I-6)
--
-- Fixtures: spacequest/{recovery_duty,escort_duty,assassinate}/*.tab are SWG-Source copies;
-- space_zones/buildout/space_endor.recovery_duty_points.tab and space_dathomir.havoc_points.tab are
-- cut-down extracts of the buildout files (header rows plus the `nav_name|4|<point>|` rows).

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")

DR.loadSquadrons()

local QUESTS = {
	{
		global = "recovery_duty_corellia_rebel_tier4_1", zone = "space_endor",
		fixtureType = "recovery_duty", fixtureName = "corellia_rebel_tier4_1",
		buildout = "space_endor.recovery_duty_points.tab",
		tables = { { field = "preRecoveryPoints", column = "escortPath" }, { field = "recoveryPoints", column = "recoveryPath" } },
		numbered = true,
	},
	{
		global = "escort_duty_corellia_rebel_tier4_1", zone = "space_dathomir",
		fixtureType = "escort_duty", fixtureName = "corellia_rebel_tier4_1",
		buildout = "space_dathomir.havoc_points.tab",
		tables = { { field = "escortPoints", column = "escortPoints" } },
		numbered = true,
	},
	{
		global = "assassinate_corellia_rebel_tier3_4", zone = "space_dathomir",
		fixtureType = "assassinate", fixtureName = "corellia_rebel_tier3_4",
		buildout = "space_dathomir.havoc_points.tab",
		tables = { { field = "targetPatrols", column = "escortPath" } },
	},
	{
		global = "assassinate_corellia_rebel_tier4_2", zone = "space_dathomir",
		fixtureType = "assassinate", fixtureName = "corellia_rebel_tier4_2",
		buildout = "space_dathomir.havoc_points.tab",
		tables = { { field = "targetPatrols", column = "escortPath" } },
	},
}

-- Table "Coordinates" of the spec: space_endor.tab line, PX, PY, PZ (SWG) and the Core3 x, z, y
local ENDOR = {
	{ name = "corellia_rebel_tier4_1_recovery_duty_1", x = -3500, z = 800, y = -4700 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_2", x = -3484, z = 1675, y = -4689 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_3", x = -3482, z = 2680, y = -4693 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_4", x = -3510, z = 3821, y = -4710 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_5", x = -4308, z = 2410, y = -4170 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_6", x = -5138, z = 2114, y = -3706 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_7", x = -6299, z = 1699, y = -3069 },
	{ name = "corellia_rebel_tier4_1_recovery_duty_8", x = -7338, z = 1328, y = -2499 },
}

local function quest(def)
	return H.expectGlobal(def.global, "Havoc quest table")
end

-- The buildout record of a nav point: fltPX, fltPY, fltPZ as Core3 x, z, y
local function buildoutPosition(def, pointName)
	local tab = H.Tab.read(H.FIXTURES .. "space_zones/buildout/" .. def.buildout)
	local needle = "nav_name|4|" .. pointName .. "|"

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars")

		if vars ~= nil and vars:find(needle, 1, true) then
			return { x = rec:num("fltPX"), z = rec:num("fltPY"), y = rec:num("fltPZ") }
		end
	end

	error("buildout extract " .. def.buildout .. " has no record for nav point " .. pointName, 0)
end

-- { zone, name } pairs of a column of the SWG quest table, file order
local function swgPath(def, column)
	local rec = H.questFixture(def.fixtureType, def.fixtureName)
	local out = {}

	for _, v in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(v)

		out[#out + 1] = { zone = zone, name = name }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-10, I-6: the point tables
---------------------------------------------------------------------------------------------

TestHavocPointCoordinates = {}

function TestHavocPointCoordinates:setUp()
	H.reset()
end

for _, def in ipairs(QUESTS) do
	for _, tbl in ipairs(def.tables) do
		local label = def.global .. "." .. tbl.field

		-- AC-10, I-6
		TestHavocPointCoordinates["test_" .. def.global .. "_" .. tbl.field .. "_name_the_points_of_the_swg_path_in_order"] = function()
			local q = quest(def)
			local expected = swgPath(def, tbl.column)
			local names, zones = {}, {}

			for i, point in ipairs(q[tbl.field]) do
				names[i] = point.patrolPointName
				zones[i] = point.zoneName
			end

			local expectedNames, expectedZones = {}, {}

			for i, e in ipairs(expected) do
				expectedNames[i] = e.name
				expectedZones[i] = e.zone
			end

			lu.assertEquals(names, expectedNames, label .. ": patrolPointName")
			lu.assertEquals(zones, expectedZones, label .. ": zoneName")
		end

		-- AC-10, I-6
		TestHavocPointCoordinates["test_" .. def.global .. "_" .. tbl.field .. "_have_the_coordinates_of_the_patrol_point_file"] = function()
			local q = quest(def)
			local points = H.patrolPoints(def.zone)

			for i, point in ipairs(q[tbl.field]) do
				local expected = points[point.patrolPointName]
				local where = label .. "[" .. i .. "] " .. point.patrolPointName

				lu.assertNotNil(expected, where .. ": not in ship_mobile/patrol_points/" .. def.zone .. ".lua")
				lu.assertEquals(type(point.x), "number", where .. ": x")
				lu.assertEquals(type(point.z), "number", where .. ": z")
				lu.assertEquals(type(point.y), "number", where .. ": y")
				lu.assertEquals(point.x, expected.x, where .. ": x")
				lu.assertEquals(point.z, expected.z, where .. ": z")
				lu.assertEquals(point.y, expected.y, where .. ": y")
			end
		end

		-- AC-10
		TestHavocPointCoordinates["test_" .. def.global .. "_" .. tbl.field .. "_are_within_one_unit_of_the_swg_buildout"] = function()
			local q = quest(def)

			for i, point in ipairs(q[tbl.field]) do
				local swg = buildoutPosition(def, point.patrolPointName)
				local where = label .. "[" .. i .. "] " .. point.patrolPointName

				lu.assertEquals(type(point.x), "number", where .. ": x")
				lu.assertEquals(type(point.z), "number", where .. ": z")
				lu.assertEquals(type(point.y), "number", where .. ": y")
				lu.assertAlmostEquals(point.x, swg.x, 1.0, where .. ": x (buildout fltPX)")
				lu.assertAlmostEquals(point.z, swg.z, 1.0, where .. ": z (buildout fltPY)")
				lu.assertAlmostEquals(point.y, swg.y, 1.0, where .. ": y (buildout fltPZ)")
			end
		end
	end
end

-- AC-10: escortNumber, radius and order of the duty point tables are unchanged
function TestHavocPointCoordinates:test_the_duty_point_tables_keep_their_escort_numbers_and_radius()
	local recovery = quest(QUESTS[1])

	for _, field in ipairs({ "preRecoveryPoints", "recoveryPoints" }) do
		for i, point in ipairs(recovery[field]) do
			lu.assertEquals(point.escortNumber, i, "recovery_duty_corellia_rebel_tier4_1." .. field .. "[" .. i .. "]: escortNumber")
			lu.assertEquals(point.radius, 250, "recovery_duty_corellia_rebel_tier4_1." .. field .. "[" .. i .. "]: radius")
			lu.assertEquals(point.zoneName, "space_endor", "recovery_duty_corellia_rebel_tier4_1." .. field .. "[" .. i .. "]: zoneName")
		end
	end

	for i, point in ipairs(quest(QUESTS[2]).escortPoints) do
		lu.assertEquals(point.escortNumber, i, "escort_duty_corellia_rebel_tier4_1.escortPoints[" .. i .. "]: escortNumber")
		lu.assertEquals(point.radius, 250, "escort_duty_corellia_rebel_tier4_1.escortPoints[" .. i .. "]: radius")
	end
end

-- AC-10: the values the spec lists for the eight recovery duty points (SWG buildout truncated toward zero)
function TestHavocPointCoordinates:test_the_recovery_duty_points_have_the_values_of_the_spec_table()
	local q = quest(QUESTS[1])
	local points = {}

	for _, field in ipairs({ "preRecoveryPoints", "recoveryPoints" }) do
		for _, p in ipairs(q[field]) do
			points[#points + 1] = p
		end
	end

	lu.assertEquals(#points, #ENDOR, "recovery_duty_corellia_rebel_tier4_1: number of points")

	for i, expected in ipairs(ENDOR) do
		lu.assertEquals(points[i].patrolPointName, expected.name, "point " .. i .. ": name")
		lu.assertEquals({ points[i].x, points[i].z, points[i].y }, { expected.x, expected.z, expected.y }, expected.name .. ": x, z, y")
	end
end

-- AC-10: the dathomir points the spec names
function TestHavocPointCoordinates:test_two_dathomir_points_have_the_values_the_spec_names()
	local escort = quest(QUESTS[2]).escortPoints[1]
	local assassin = quest(QUESTS[3]).targetPatrols[1]

	lu.assertEquals({ escort.x, escort.z, escort.y }, { 3237, -1676, -4704 }, "corellia_rebel_tier4_1_escort_duty_1: x, z, y")
	lu.assertEquals({ assassin.x, assassin.z, assassin.y }, { 1450, -6280, -4250 }, "corellia_rebel_tier3_4_assassin_1: x, z, y")
end

---------------------------------------------------------------------------------------------
-- AC-10: the quests use the coordinates when they run
---------------------------------------------------------------------------------------------

TestHavocPointScenarios = {}

local savedConversationMobile

function TestHavocPointScenarios:setUp()
	H.reset()
	savedConversationMobile = nil
end

function TestHavocPointScenarios:tearDown()
	if savedConversationMobile ~= nil then
		quest(QUESTS[1]).recoveryConversationMobile = savedConversationMobile
	end
end

local function requireCoordinates(q, field, label)
	for i, p in ipairs(q[field]) do
		lu.assertEquals(type(p.x), "number", label .. "." .. field .. "[" .. i .. "].x: the quest table has no coordinate for " .. p.patrolPointName)
	end
end

local function distance(a, b)
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2 + (a.y - b.y) ^ 2)
end

local function waypointNamed(player, name)
	for _, wp in ipairs(player.ghost.waypoints) do
		if wp.name == name then
			return wp
		end
	end

	return nil
end

-- AC-10
function TestHavocPointScenarios:test_the_recovery_duty_waypoint_and_target_ship_are_at_the_first_point_in_endor()
	local q = quest(QUESTS[1])

	requireCoordinates(q, "preRecoveryPoints", q.className)
	requireCoordinates(q, "recoveryPoints", q.className)

	-- the fake ship agent has no setConversationMobile
	savedConversationMobile = q.recoveryConversationMobile
	q.recoveryConversationMobile = ""

	q:start()

	local player = DR.player(q)

	q:startQuest(player, "")
	H.advance(0)
	H.advance((q.arrivalDelay + 20) * 1000)

	local waypoint = waypointNamed(player, "Mission Target")

	lu.assertNotNil(waypoint, "recovery_duty_corellia_rebel_tier4_1: no 'Mission Target' waypoint")
	lu.assertEquals({ waypoint.x, waypoint.z, waypoint.y }, { -3500, 800, -4700 }, "Mission Target waypoint x, z, y")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, "the recovery ship was spawned")
	lu.assertTrue(distance(ship, { x = -3500, z = 800, y = -4700 }) <= 200.5, "the recovery ship spawns within 200 of the first point, at " .. ship.x .. ", " .. ship.z .. ", " .. ship.y)
end

-- AC-10
function TestHavocPointScenarios:test_the_escort_duty_rendezvous_waypoint_is_at_the_start_point_in_dathomir()
	local q = quest(QUESTS[2])

	requireCoordinates(q, "escortPoints", q.className)

	q:start()

	local player = DR.player(q)

	q:startQuest(player, "")
	H.advance(0)
	H.advance(2500) -- setupEscort

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertNotNil(start, "escort_duty_corellia_rebel_tier4_1: no start point was chosen")

	local expected = H.patrolPoints("space_dathomir")[q.escortPoints[start].patrolPointName]
	local waypoint = waypointNamed(player, "Escort Rendevous")

	lu.assertNotNil(waypoint, "escort_duty_corellia_rebel_tier4_1: no 'Escort Rendevous' waypoint")
	lu.assertEquals({ waypoint.x, waypoint.z, waypoint.y }, { expected.x, expected.z, expected.y }, "Escort Rendevous waypoint x, z, y (point " .. start .. ")")
	lu.assertEquals(waypoint.planet, "space_dathomir", "Escort Rendevous waypoint zone")
end

local function assassinationSpawnsAtFirstPoint(def)
	local q = quest(def)

	requireCoordinates(q, "targetPatrols", q.className)

	q:start()

	local player = DR.player(q)

	q:startQuest(player, "")
	H.advance(0)
	H.advance(3500) -- deployTargets (2 s)

	local first = q.targetPatrols[1]
	local target

	for _, ship in ipairs(H.spawnedShips()) do
		if ship.shipName == q.assassinateSpawns.target then
			target = ship
			break
		end
	end

	lu.assertNotNil(target, q.className .. ": the target ship " .. q.assassinateSpawns.target .. " was not spawned")
	lu.assertEquals({ target.x, target.z, target.y }, { first.x, first.z, first.y }, q.className .. ": target spawn x, z, y")
end

-- AC-10
function TestHavocPointScenarios:test_the_tier3_assassination_target_spawns_at_the_first_patrol_point()
	assassinationSpawnsAtFirstPoint(QUESTS[3])
end

-- AC-10
function TestHavocPointScenarios:test_the_tier4_assassination_target_spawns_at_the_first_patrol_point()
	assassinationSpawnsAtFirstPoint(QUESTS[4])
end
