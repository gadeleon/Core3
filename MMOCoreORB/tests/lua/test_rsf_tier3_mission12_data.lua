-- RSF Squadron tier 3 (Commander Dulios) missions 1 and 2: the payload of recovery 1a, patrol 1b, the surprise
-- attacks 1c and 2c, assassinate 1d and escort 2a against SWG-Source, the 35 invented patrol points gone, and
-- the 18 real SWG points against the buildout.
-- Spec: .claude/work/rsf-tier3-mission1-2-data/01-spec.md (AC-1 .. AC-8, Content contract 1-3, Data mapping,
-- invariants I-2 .. I-5). AC-9 is the existing suites (unmodified) plus the engine load gate.
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the buildout extracts
-- fixtures/space_zones/buildout/space_{dantooine,naboo}.rsf_tier3_points.tab. The literals of the spec's
-- Content contract are repeated as anchors so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local R = require("surprise_replay")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local function quest(global) return H.expectGlobal(global, "RSF tier 3 quest table") end

local function fixtureOf(global)
	local q = quest(global)

	return H.questFixture(q.questType, q.questName)
end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- Truncation toward zero, as Core3's coordinates truncate the buildout floats.
local function trunc(n)
	if n >= 0 then
		return math.floor(n)
	end

	return math.ceil(n)
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	table.sort(keys)
	return keys
end

-- "object/mobile/<f>.iff" -> "object/mobile/shared_<f>.iff" (D-3)
local function sharedAppearance(path)
	return (path:gsub("([^/]+)$", "shared_%1"))
end

---------------------------------------------------------------------------------------------
-- Oracle sanity: the fixtures carry the values the spec lists
---------------------------------------------------------------------------------------------

TestRsfTier3Mission12Fixtures = {}

function TestRsfTier3Mission12Fixtures:setUp() H.reset() end

-- AC-1 .. AC-6 (the oracle itself)
function TestRsfTier3Mission12Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local a = fixtureOf(g("recovery", "1a"))

	lu.assertEquals({ a:get("questZone"), a:get("targetShipType"), a:num("targetArrivalDelay"), a:num("targetRecoverTime"), a:get("recoveryAppearance"), a:num("numAttackShipLists"), a:num("numResponses") },
		{ "space_dantooine", "dru_mdar_tier3", 0, 21, "object/mobile/dressed_mercenary_elite_rod_m.iff", 0, 2 }, "recovery 1a")
	lu.assertEquals({ #a:list("targetEscort"), #a:list("escortPath"), #a:list("recoveryPath") }, { 2, 5, 2 }, "recovery 1a: list sizes")

	local b = fixtureOf(g("patrol", "1b"))

	lu.assertEquals({ b:get("questZone"), #b:list("navPoints") }, { "space_dantooine", 4 }, "patrol 1b")

	local c, c2 = fixtureOf(g("destroy_surpriseattack", "1c")), fixtureOf(g("destroy_surpriseattack", "2c"))

	lu.assertEquals({ c:get("questZone"), c:get("shipType"), c:num("shipCount") }, { "space_dantooine", "blacksun_aggressor_tier2", 4 }, "surprise attack 1c")
	lu.assertEquals({ c2:get("questZone"), c2:get("shipType"), c2:num("shipCount") }, { "space_naboo", "aynat_intimidator_tier3", 5 }, "surprise attack 2c")

	local d = fixtureOf(g("assassinate", "1d"))

	lu.assertEquals({ d:get("questZone"), d:get("targetShipType"), d:num("targetArrivalDelay"), #d:list("targetEscort"), #d:list("escortPath") }, { "space_naboo", "saysmond_varg_tier3", 12, 2, 4 }, "assassinate 1d")

	local e = fixtureOf(g("escort", "2a"))

	lu.assertEquals({ e:get("questZone"), e:get("escortShipType"), e:num("attackPeriod"), e:num("numResponses"), e:num("numAttackShipLists"), #e:list("escortPath") }, { "space_naboo", "cadamo_sun_tier3", 175, 5, 8, 4 }, "escort 2a")
end

---------------------------------------------------------------------------------------------
-- AC-1: 1a payload
---------------------------------------------------------------------------------------------

TestRsfTier3Recovery1a = {}

function TestRsfTier3Recovery1a:setUp() H.reset() end

local function checkRecoveryPath(q, rec, field, column, label)
	local rows = rec:list(column)

	lu.assertEquals(#q[field], #rows, label .. ": number of " .. field)

	for i, value in ipairs(rows) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		lu.assertEquals(zone, q.questZone, label .. ": " .. column .. " zone equals questZone")
		lu.assertEquals(q[field][i], { patrolPointName = name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 },
			label .. ": " .. field .. "[" .. i .. "] (" .. name .. "), no zoneName")
	end
end

-- AC-1
function TestRsfTier3Recovery1a:test_1a_payload_equals_the_fixture()
	local name = g("recovery", "1a")
	local q = quest(name)
	local rec = fixtureOf(name)

	lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), name .. ": recoverShip")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), name .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), name .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.recoveryConversationMobile, sharedAppearance(rec:get("recoveryAppearance")), name .. ": recoveryConversationMobile (recoveryAppearance, shared_ prefix)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), name .. ": escortShips (targetEscort, in order)")
	checkRecoveryPath(q, rec, "preRecoveryPoints", "escortPath", name)
	checkRecoveryPath(q, rec, "recoveryPoints", "recoveryPath", name)

	lu.assertEquals(rec:num("numAttackShipLists"), 0, name .. ": oracle has no attack lists")
	lu.assertEquals(q.attackDelay, 0, name .. ": attackDelay")
	lu.assertEquals(#q.attackShips, 0, name .. ": #attackShips")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, name .. ": tauntData (max(numResponses, 1))")
end

-- AC-1
function TestRsfTier3Recovery1a:test_1a_literal_payload()
	local q = quest(g("recovery", "1a"))

	lu.assertEquals(q.arrivalDelay, 0, "1a: arrivalDelay")
	lu.assertEquals(q.recoveryDelay, 21, "1a: recoveryDelay")
	lu.assertEquals(q.recoverShip, "dru_mdar_tier3", "1a: recoverShip")
	lu.assertEquals(q.recoveryConversationMobile, "object/mobile/shared_dressed_mercenary_elite_rod_m.iff", "1a: recoveryConversationMobile")
	lu.assertEquals(q.escortShips, { "blacksun_fighter_s02_tier2", "blacksun_fighter_s01_tier1" }, "1a: escortShips")
	lu.assertEquals(q.preRecoveryPoints, {
		{ patrolPointName = "naboo_privateer_tier3_pirate_interdiction_1", x = -54, z = 635, y = 574, escortNumber = 1, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier3_pirate_interdiction_2", x = -18, z = 1905, y = 2123, escortNumber = 2, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier3_pirate_interdiction_3", x = -803, z = 2809, y = 3358, escortNumber = 3, radius = 250 },
		{ patrolPointName = "naboo_imperial_tier2_survival1", x = 4000, z = -2500, y = -5600, escortNumber = 4, radius = 250 },
		{ patrolPointName = "corellia_rebel_tier4_4_recovery_4", x = -5049, z = 6532, y = 4746, escortNumber = 5, radius = 250 },
	}, "1a: preRecoveryPoints")
	lu.assertEquals(q.recoveryPoints, {
		{ patrolPointName = "naboo_privateer_tier3_pirate_decession_1", x = -756, z = 1762, y = 3480, escortNumber = 1, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier3_pirate_decession_2", x = -1193, z = -959, y = 2238, escortNumber = 2, radius = 250 },
	}, "1a: recoveryPoints")
	lu.assertEquals(q.attackDelay, 0, "1a: attackDelay")
	lu.assertEquals(q.attackShips, {}, "1a: attackShips")
	lu.assertEquals(q.tauntData, { panicCount = 2, thanksCount = 2 }, "1a: tauntData")
end

---------------------------------------------------------------------------------------------
-- AC-2: 1a runtime, no attack waves
---------------------------------------------------------------------------------------------

TestRsfTier3Recovery1aRuntime = {}

function TestRsfTier3Recovery1aRuntime:setUp()
	H.reset()
	AC.tearDown()
end

function TestRsfTier3Recovery1aRuntime:tearDown() AC.tearDown() end

local function pendingFor(q, method)
	local out = {}

	for _, e in ipairs(H.pendingEvents()) do
		if e.screenplay == q.className and e.method == method then
			out[#out + 1] = e
		end
	end

	return out
end

local function spawnedNames()
	local out = {}

	for i, call in ipairs(H.Engine.callsTo("spawnShipAgent")) do
		out[i] = call[1]
	end

	return out
end

-- Starts 1a for a pilot in Dantooine space and runs the (0 s) arrival events.
local function start1a()
	local q = quest(g("recovery", "1a"))

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q)

	q:startQuest(player, "")
	H.advance(0)
	H.advance(0)

	return q, player
end

-- AC-2
function TestRsfTier3Recovery1aRuntime:test_1a_spawns_the_dru_mdar_and_its_two_escorts_at_once_each_on_the_5_point_path()
	local q, player = start1a()
	local rec = fixtureOf(g("recovery", "1a"))

	lu.assertEquals(spawnedNames(), { "dru_mdar_tier3", "blacksun_fighter_s02_tier2", "blacksun_fighter_s01_tier1" }, "1a: ships spawned after the 0 s arrival events, in order")

	local path = {}

	for i, value in ipairs(rec:list("escortPath")) do
		local _, name = H.Tab.splitNavPoint(value)

		path[i] = name
	end

	lu.assertEquals(#path, 5, "oracle: escortPath rows")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 3, "1a: spawned ships")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.patrolPointTables, { path }, "1a: ship " .. i .. " assignFixedPatrolPointsTable (escortPath names in order)")
	end

	local waypoints = player.ghost.waypoints

	lu.assertEquals(#waypoints, 1, "1a: one quest waypoint")

	local p = point("space_dantooine", "naboo_privateer_tier3_pirate_interdiction_1")

	lu.assertEquals({ waypoints[1].x, waypoints[1].z, waypoints[1].y }, { p.x, p.z, p.y }, "1a: waypoint at naboo_privateer_tier3_pirate_interdiction_1")
end

-- AC-2
function TestRsfTier3Recovery1aRuntime:test_1a_recovered_ship_gets_the_two_recovery_points_and_no_attack_wave_is_ever_queued()
	local q, player = start1a()
	local rec = fixtureOf(g("recovery", "1a"))
	local shipID = readData(player.objectID .. q.className .. ":recoveryShip:")
	local target = getSceneObject(shipID)

	lu.assertNotNil(target, "1a: the recovery ship was spawned")
	lu.assertEquals(#pendingFor(q, "spawnAttackWave"), 0, "1a: no spawnAttackWave queued after arrival")

	H.fireObservers(SHIPDISABLED, target, player)

	lu.assertEquals(#pendingFor(q, "startRecovery"), 1, "1a: the disable queued the capture")

	H.advance(21000) -- startRecovery (recoveryDelay)
	H.advance(21000) -- continueRecovery (recoveryDelay)
	H.advance(2000) -- assignRecoveryPoints

	local names = {}

	for i, value in ipairs(rec:list("recoveryPath")) do
		local _, name = H.Tab.splitNavPoint(value)

		names[i] = name
	end

	lu.assertEquals(#names, 2, "oracle: recoveryPath rows")
	lu.assertEquals(target.patrolPointTables[#target.patrolPointTables], names, "1a: recovered ship's last assignFixedPatrolPointsTable (recoveryPath names in order)")
	lu.assertEquals(#pendingFor(q, "spawnAttackWave"), 0, "1a: no spawnAttackWave queued after capture")

	H.advance(600000)

	lu.assertEquals(#H.spawnedShips(), 3, "1a: no further ship is spawned (no waves)")
end

---------------------------------------------------------------------------------------------
-- AC-3: 1b points
---------------------------------------------------------------------------------------------

TestRsfTier3Patrol1b = {}

function TestRsfTier3Patrol1b:setUp() H.reset() end

-- AC-3
function TestRsfTier3Patrol1b:test_1b_patrol_points_equal_the_fixture_nav_points()
	local name = g("patrol", "1b")
	local q = quest(name)
	local rec = fixtureOf(name)
	local rows = rec:list("navPoints")

	lu.assertEquals(#q.patrolPoints, #rows, name .. ": number of patrolPoints")

	for i, value in ipairs(rows) do
		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = point(zone, pointName)

		lu.assertEquals(zone, q.questZone, name .. ": navPoints zone equals questZone")
		lu.assertEquals(q.patrolPoints[i], { patrolPointName = pointName, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }, name .. ": patrolPoints[" .. i .. "] (" .. pointName .. ")")
	end
end

-- AC-3
function TestRsfTier3Patrol1b:test_1b_literal_patrol_points()
	lu.assertEquals(quest(g("patrol", "1b")).patrolPoints, {
		{ patrolPointName = "naboo_privateer_tier3_leg_1_patrol_1", x = 1556, z = -1288, y = 3150, patrolNumber = 1, radius = 150 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_patrol_2", x = 2393, z = -206, y = 3190, patrolNumber = 2, radius = 150 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_patrol_3", x = 4816, z = 81, y = 1973, patrolNumber = 3, radius = 150 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_patrol_4", x = 2399, z = 1749, y = 3160, patrolNumber = 4, radius = 150 },
	}, "1b: patrolPoints")
end

---------------------------------------------------------------------------------------------
-- AC-4: 1c and 2c ships
---------------------------------------------------------------------------------------------

TestRsfTier3SurpriseAttacks12 = {}

function TestRsfTier3SurpriseAttacks12:setUp() H.reset() end

-- AC-4
function TestRsfTier3SurpriseAttacks12:test_1c_and_2c_spawn_what_the_swg_spawn_loop_spawns_for_their_fixtures()
	for _, suffix in ipairs({ "1c", "2c" }) do
		local name = g("destroy_surpriseattack", suffix)
		local q = quest(name)
		local rec = fixtureOf(name)

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = R.runs(R.replay("naboo_privateer_tier3_" .. suffix)) }, name .. ": surpriseAttackShips")
	end
end

-- AC-4
function TestRsfTier3SurpriseAttacks12:test_1c_and_2c_literal_ships()
	lu.assertEquals(quest(g("destroy_surpriseattack", "1c")).surpriseAttackShips, { zone = "space_dantooine", spawns = { { count = 4, shipName = "blacksun_aggressor_tier2" } } }, "1c: surpriseAttackShips")
	lu.assertEquals(quest(g("destroy_surpriseattack", "2c")).surpriseAttackShips, { zone = "space_naboo", spawns = { { count = 5, shipName = "aynat_intimidator_tier3" } } }, "2c: surpriseAttackShips")
end

---------------------------------------------------------------------------------------------
-- AC-5: 1d payload
---------------------------------------------------------------------------------------------

TestRsfTier3Assassinate1d = {}

function TestRsfTier3Assassinate1d:setUp() H.reset() end

-- AC-5
function TestRsfTier3Assassinate1d:test_1d_payload_equals_the_fixture()
	local name = g("assassinate", "1d")
	local q = quest(name)
	local rec = fixtureOf(name)

	lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), name .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.assassinateSpawns.target, rec:get("targetShipType"), name .. ": assassinateSpawns.target")
	lu.assertEquals(q.assassinateSpawns.escorts, rec:list("targetEscort"), name .. ": assassinateSpawns.escorts (in order)")
	lu.assertEquals(q.failTimer, 20, name .. ": failTimer (Core3 choice, no SWG column)")

	local points = rec:list("escortPath")

	lu.assertEquals(#q.targetPatrols, #points, name .. ": number of targetPatrols")

	for i, value in ipairs(points) do
		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = point(zone, pointName)

		lu.assertEquals(q.targetPatrols[i], { patrolPointName = pointName, x = p.x, z = p.z, y = p.y }, name .. ": targetPatrols[" .. i .. "] (" .. pointName .. ")")
		lu.assertEquals(zone, q.questZone, name .. ": escortPath zone equals questZone")
	end
end

-- AC-5
function TestRsfTier3Assassinate1d:test_1d_literal_payload()
	local q = quest(g("assassinate", "1d"))

	lu.assertEquals(q.arrivalDelay, 12, "1d: arrivalDelay")
	lu.assertEquals(q.failTimer, 20, "1d: failTimer")
	lu.assertEquals(q.assassinateSpawns, { target = "saysmond_varg_tier3", escorts = { "blacksun_fighter_s01_tier3", "blacksun_fighter_s01_tier3" } }, "1d: assassinateSpawns")
	lu.assertEquals(q.targetPatrols, {
		{ patrolPointName = "naboo_privateer_tier3_leg_1_assassinate_1", x = 1407, z = -1329, y = 1377 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_assassinate_2", x = 2236, z = -2336, y = 2872 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_assassinate_3", x = 3453, z = -4084, y = 1842 },
		{ patrolPointName = "privateer_tier2_recovery_4", x = 480, z = -2264, y = -3435 },
	}, "1d: targetPatrols")
end

---------------------------------------------------------------------------------------------
-- AC-6: 2a payload
---------------------------------------------------------------------------------------------

TestRsfTier3Escort2a = {}

function TestRsfTier3Escort2a:setUp() H.reset() end

-- AC-6
function TestRsfTier3Escort2a:test_2a_payload_equals_the_fixture()
	local name = g("escort", "2a")
	local q = quest(name)
	local rec = fixtureOf(name)

	lu.assertEquals(rec:num("numAttackShipLists"), 8, name .. ": oracle attack list count")
	lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
	lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, name .. ": escortShips (escortShipType)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), name .. ": attackDelay (attackPeriod)")

	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	lu.assertEquals(q.attackShips, lists, name .. ": attackShips (column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, name .. ": tauntData (max(numResponses, 1))")

	local rows = rec:list("escortPath")

	lu.assertEquals(#q.escortPoints, #rows, name .. ": number of escortPoints")

	for i, value in ipairs(rows) do
		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = point(zone, pointName)

		lu.assertEquals(q.escortPoints[i], { patrolPointName = pointName, zoneName = q.questZone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }, name .. ": escortPoints[" .. i .. "] (" .. pointName .. ")")
		lu.assertEquals(zone, q.questZone, name .. ": escortPath zone equals questZone")
	end
end

-- AC-6
function TestRsfTier3Escort2a:test_2a_literal_payload()
	local q = quest(g("escort", "2a"))

	lu.assertEquals(q.escortShips, { "cadamo_sun_tier3" }, "2a: escortShips")
	lu.assertEquals(q.escortPoints, {
		{ patrolPointName = "corellia_imperial_tier3_leg_4_assassinate_one_2", zoneName = "space_naboo", x = -1972, z = -1677, y = -2951, escortNumber = 1, radius = 250 },
		{ patrolPointName = "naboo_imperial_patrol_1", zoneName = "space_naboo", x = -2455, z = 2645, y = -3905, escortNumber = 2, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier3_leg_1_assassinate_3", zoneName = "space_naboo", x = 3453, z = -4084, y = 1842, escortNumber = 3, radius = 250 },
		{ patrolPointName = "privateer_patrol_1", zoneName = "space_naboo", x = 752, z = 659, y = -2444, escortNumber = 4, radius = 250 },
	}, "2a: escortPoints")
	lu.assertEquals(q.attackDelay, 175, "2a: attackDelay")
	lu.assertEquals(q.attackShips, {
		{ "aynat_enforcer_tier3", "aynat_enforcer_tier3", "aynat_ghost_tier3" },
		{ "aynat_ghost_tier3", "aynat_intimidator_tier3", "aynat_intimidator_tier3" },
		{ "aynat_outlaw_tier3", "aynat_outlaw_tier3", "aynat_vaporizer_tier3" },
		{ "aynat_enforcer_tier3", "aynat_enforcer_tier3", "aynat_enforcer_tier3" },
		{ "aynat_vaporizer_tier3", "aynat_vaporizer_tier3" },
		{ "aynat_vaporizer_tier3", "aynat_vaporizer_tier3", "aynat_viggo_tier3" },
		{ "aynat_enforcer_tier3", "aynat_enforcer_tier3", "aynat_intimidator_tier3", "aynat_intimidator_tier3" },
		{ "aynat_outlaw_tier3", "aynat_outlaw_tier3", "aynat_outlaw_tier3", "aynat_vaporizer_tier3", "aynat_vaporizer_tier3" },
	}, "2a: attackShips")

	local sizes = {}

	for i, list in ipairs(q.attackShips) do
		sizes[i] = #list
	end

	lu.assertEquals(sizes, { 3, 3, 3, 3, 2, 3, 4, 5 }, "2a: attack list sizes")
	lu.assertEquals(q.tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, "2a: tauntData")
end

---------------------------------------------------------------------------------------------
-- AC-7: the 18 SWG points in Core3 equal the buildout
---------------------------------------------------------------------------------------------

TestRsfTier3Mission12SwgPoints = {}

function TestRsfTier3Mission12SwgPoints:setUp() H.reset() end

local EXTRACTS = {
	space_dantooine = { file = "space_zones/buildout/space_dantooine.rsf_tier3_points.tab", count = 11 },
	space_naboo = { file = "space_zones/buildout/space_naboo.rsf_tier3_points.tab", count = 7 },
}

-- The 18 points of the spec's Source inventory ("Real SWG points"), by zone.
local SWG_POINTS = {
	space_dantooine = {
		"naboo_privateer_tier3_pirate_interdiction_1", "naboo_privateer_tier3_pirate_interdiction_2", "naboo_privateer_tier3_pirate_interdiction_3",
		"naboo_imperial_tier2_survival1", "corellia_rebel_tier4_4_recovery_4", "naboo_privateer_tier3_pirate_decession_1", "naboo_privateer_tier3_pirate_decession_2",
		"naboo_privateer_tier3_leg_1_patrol_1", "naboo_privateer_tier3_leg_1_patrol_2", "naboo_privateer_tier3_leg_1_patrol_3", "naboo_privateer_tier3_leg_1_patrol_4",
	},
	space_naboo = {
		"naboo_privateer_tier3_leg_1_assassinate_1", "naboo_privateer_tier3_leg_1_assassinate_2", "naboo_privateer_tier3_leg_1_assassinate_3",
		"privateer_tier2_recovery_4", "corellia_imperial_tier3_leg_4_assassinate_one_2", "naboo_imperial_patrol_1", "privateer_patrol_1",
	},
}

-- name -> { x, z, y } truncated, from the nav_name rows of an extract; also the number of nav_name rows
local function buildoutPoints(zone)
	local tab = H.fixture(EXTRACTS[zone].file)
	local out, n = {}, 0

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars")
		local name = vars and vars:match("nav_name|4|([^|]+)|")

		if name ~= nil then
			n = n + 1
			out[name] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		end
	end

	return out, n
end

-- AC-7
function TestRsfTier3Mission12SwgPoints:test_each_buildout_extract_holds_exactly_its_nav_name_rows()
	for zone, extract in pairs(EXTRACTS) do
		local _, n = buildoutPoints(zone)

		lu.assertEquals(n, extract.count, zone .. ": nav_name rows in " .. extract.file)
		lu.assertEquals(#SWG_POINTS[zone], extract.count, zone .. ": points listed by the spec")
	end
end

-- AC-7
function TestRsfTier3Mission12SwgPoints:test_the_18_swg_points_in_core3_equal_the_truncated_buildout_values()
	for zone, names in pairs(SWG_POINTS) do
		local swg = buildoutPoints(zone)

		for _, name in ipairs(names) do
			lu.assertNotNil(swg[name], zone .. ": " .. name .. " is in the buildout extract")

			local p = point(zone, name)

			lu.assertEquals({ p.x, p.z, p.y }, swg[name], zone .. ": " .. name .. " x/z/y equal the truncated buildout fltPX/fltPY/fltPZ")
		end
	end
end

-- AC-7 (spec table: the 18 coordinates)
function TestRsfTier3Mission12SwgPoints:test_the_spec_coordinates_of_the_18_points()
	local expected = {
		space_dantooine = {
			naboo_privateer_tier3_pirate_interdiction_1 = { -54, 635, 574 }, naboo_privateer_tier3_pirate_interdiction_2 = { -18, 1905, 2123 },
			naboo_privateer_tier3_pirate_interdiction_3 = { -803, 2809, 3358 }, naboo_imperial_tier2_survival1 = { 4000, -2500, -5600 },
			corellia_rebel_tier4_4_recovery_4 = { -5049, 6532, 4746 }, naboo_privateer_tier3_pirate_decession_1 = { -756, 1762, 3480 },
			naboo_privateer_tier3_pirate_decession_2 = { -1193, -959, 2238 }, naboo_privateer_tier3_leg_1_patrol_1 = { 1556, -1288, 3150 },
			naboo_privateer_tier3_leg_1_patrol_2 = { 2393, -206, 3190 }, naboo_privateer_tier3_leg_1_patrol_3 = { 4816, 81, 1973 },
			naboo_privateer_tier3_leg_1_patrol_4 = { 2399, 1749, 3160 },
		},
		space_naboo = {
			naboo_privateer_tier3_leg_1_assassinate_1 = { 1407, -1329, 1377 }, naboo_privateer_tier3_leg_1_assassinate_2 = { 2236, -2336, 2872 },
			naboo_privateer_tier3_leg_1_assassinate_3 = { 3453, -4084, 1842 }, privateer_tier2_recovery_4 = { 480, -2264, -3435 },
			corellia_imperial_tier3_leg_4_assassinate_one_2 = { -1972, -1677, -2951 }, naboo_imperial_patrol_1 = { -2455, 2645, -3905 },
			privateer_patrol_1 = { 752, 659, -2444 },
		},
	}

	for zone, byName in pairs(expected) do
		for _, name in ipairs(sortedKeys(byName)) do
			local p = point(zone, name)

			lu.assertEquals({ p.x, p.z, p.y }, byName[name], zone .. ": " .. name)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: the invented points are gone and unused
---------------------------------------------------------------------------------------------

TestRsfTier3InventedPointsGone = {}

function TestRsfTier3InventedPointsGone:setUp() H.reset() end

local function numbered(prefix, from, to)
	local out = {}

	for i = from, to do
		out[#out + 1] = prefix .. i
	end

	return out
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- The 35 names of the spec's "Invented points" table (16 + 10 + 5 + 4), by patrol point file.
local INVENTED = {
	space_dantooine = concat(numbered("dantooine_privateer_tier3_recovery_point_", 1, 8), numbered("dantooine_privateer_tier3_patrol_", 1, 4), numbered("dantooine_privateer_tier3_beldini_", 1, 4)),
	space_naboo = concat(numbered("naboo_privateer_tier3_escort_", 1, 4), numbered("naboo_privateer_tier3_assassinate_", 1, 2), numbered("naboo_privateer_tier3_beldini_", 1, 4)),
	space_lok = concat({ "lok_privateer_tier3_crystal_snake_battle" }, numbered("lok_privateer_tier3_krayt_bane_", 1, 4)),
	space_corellia = concat(numbered("corellia_privateer_tier3_rescue_escort_", 1, 3), { "corellia_privateer_tier3_space_battle_1" }),
}

local function inventedSet()
	local set, n = {}, 0

	for _, names in pairs(INVENTED) do
		for _, name in ipairs(names) do
			set[name] = true
			n = n + 1
		end
	end

	return set, n
end

-- AC-8 (the list itself)
function TestRsfTier3InventedPointsGone:test_the_list_holds_the_35_names_of_the_spec()
	local _, n = inventedSet()

	lu.assertEquals({ #INVENTED.space_dantooine, #INVENTED.space_naboo, #INVENTED.space_lok, #INVENTED.space_corellia }, { 16, 10, 5, 4 }, "names per file")
	lu.assertEquals(n, 35, "distinct names")
end

-- AC-8 (supersedes test_rsf_tier3_quest_data.lua:400, F1 D-9: "F3 deletes them together")
function TestRsfTier3InventedPointsGone:test_none_of_the_35_invented_points_is_defined_in_any_patrol_point_file()
	for zone, names in pairs(INVENTED) do
		local points = H.patrolPoints(zone)

		for _, name in ipairs(names) do
			lu.assertNil(points[name], zone .. ": " .. name .. " is still defined")
		end
	end
end

-- AC-8 (supersedes the orphan pin of test_rsf_tier3_quest_data.lua:400-406)
function TestRsfTier3InventedPointsGone:test_the_orphaned_beldini_and_krayt_bane_points_are_deleted_with_the_rest()
	for i = 1, 4 do
		lu.assertNil(H.patrolPoints("space_dantooine")["dantooine_privateer_tier3_beldini_" .. i], "dantooine_privateer_tier3_beldini_" .. i)
		lu.assertNil(H.patrolPoints("space_naboo")["naboo_privateer_tier3_beldini_" .. i], "naboo_privateer_tier3_beldini_" .. i)
		lu.assertNil(H.patrolPoints("space_lok")["lok_privateer_tier3_krayt_bane_" .. i], "lok_privateer_tier3_krayt_bane_" .. i)
	end
end

-- AC-8
function TestRsfTier3InventedPointsGone:test_no_script_under_bin_scripts_mentions_an_invented_point()
	local args = {}

	for _, names in pairs(INVENTED) do
		for _, name in ipairs(names) do
			args[#args + 1] = "-e " .. name
		end
	end

	table.sort(args)

	local cmd = "grep -rnwF --include='*.lua' " .. table.concat(args, " ") .. " " .. H.SCRIPTS .. " 2>&1"
	local pipe = io.popen(cmd)
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out, "", "bin/scripts still mentions invented points")
end

-- AC-8 (I-4): the loaded quest globals
function TestRsfTier3InventedPointsGone:test_no_loaded_quest_global_contains_an_invented_point_name_at_any_depth()
	local set = inventedSet()
	local hits = {}

	local function walk(value, path, seen)
		if type(value) == "string" then
			if set[value] then
				hits[#hits + 1] = path .. " = " .. value
			end
		elseif type(value) == "table" and not seen[value] then
			seen[value] = true

			for k, v in pairs(value) do
				if type(k) == "string" and set[k] then
					hits[#hits + 1] = path .. " key " .. k
				end

				walk(v, path .. "." .. tostring(k), seen)
			end
		end
	end

	for _, name in ipairs(H.questGlobals()) do
		walk(rawget(_G, name), name, {})
	end

	table.sort(hits)
	lu.assertEquals(hits, {}, "invented point names in loaded quest globals")
end

-- AC-8 (I-3): every RSF tier 3 table's points still resolve with the inlined coordinates
-- (patrol points in the zone's patrol point file; the 3a validSpawns use spawnName, a spawner name)
function TestRsfTier3InventedPointsGone:test_every_point_the_rsf_tier3_tables_use_still_resolves_with_its_inlined_coordinates()
	local checked = 0

	local function walk(global, q, value, path, seen)
		if type(value) ~= "table" or seen[value] then
			return
		end

		seen[value] = true

		local name = value.patrolPointName
		local known

		if name ~= nil then
			known = point(value.zoneName or q.questZone, name)
		elseif value.spawnName ~= nil then
			known = H.spawners(q.questZone)[value.spawnName]
			lu.assertNotNil(known, global .. ": " .. path .. " spawner " .. value.spawnName .. " in " .. q.questZone)
			name = value.spawnName
		end

		if known ~= nil then
			lu.assertEquals({ value.x, value.z, value.y }, { known.x, known.z, known.y }, global .. ": " .. path .. " (" .. name .. ") coordinates")
			checked = checked + 1
		end

		for k, v in pairs(value) do
			walk(global, q, v, path .. "." .. tostring(k), seen)
		end
	end

	for _, global in ipairs(H.questGlobals()) do
		if global:find("_naboo_privateer_tier3_", 1, true) then
			walk(global, rawget(_G, global), rawget(_G, global), "", {})
		end
	end

	lu.assertTrue(checked >= 30, "checked the points of the RSF tier 3 tables, got " .. checked)
end

-- AC-8
function TestRsfTier3InventedPointsGone:test_the_neighbours_and_the_points_that_must_stay_are_still_defined()
	local stay = {
		space_dantooine = { "mining_route_1_09" },
		space_naboo = { "commerce_route_1_04" }, -- privateer_escort_1..4 went with rsf-tier1-dinge-data
		-- the spec names these "leg_3_deliver_pickup" and "leg_3_delivery"; the file has leg_3_deliver_delivery, in space_lok
		space_lok = { "trade_fed_station_patrol_14", "naboo_privateer_tier3_leg_3_deliver_pickup", "naboo_privateer_tier3_leg_3_deliver_delivery", "naboo_privateer_tier3_leg_3_survival" },
		space_corellia = { "rebel_gunboat_patrol_03_05" },
	}

	for zone, names in pairs(stay) do
		for _, name in ipairs(names) do
			lu.assertNotNil(H.patrolPoints(zone)[name], zone .. ": " .. name .. " must stay")
		end
	end
end

-- AC-8: the files lose their comment lines too and keep closing brace and registration call
function TestRsfTier3InventedPointsGone:test_the_four_files_keep_their_registration_and_lose_the_rsf_tier3_comments()
	local dir = H.SCRIPTS .. "ship_mobile/patrol_points/"

	for _, zone in ipairs({ "space_dantooine", "space_naboo", "space_lok", "space_corellia" }) do
		local text = readFile(dir .. zone .. ".lua")

		lu.assertNotNil(text:find("SpacePatrolPoints:addSpacePatrolPoints(" .. zone .. ", \"" .. zone .. "\")", 1, true), zone .. ": addSpacePatrolPoints call")
		lu.assertNil(text:find("RSF Tier 3", 1, true), zone .. ": no 'RSF Tier 3' comment line is left")
	end

	lu.assertNil(readFile(dir .. "space_naboo.lua"):find("-- RSF Tier 1 Mission 3: Escort Freighter", 1, true), "space_naboo: the RSF Tier 1 comment is gone (rsf-tier1-dinge-data)")
end

---------------------------------------------------------------------------------------------
-- AC-9 (I-1): identity of the six tables
---------------------------------------------------------------------------------------------

TestRsfTier3Mission12Identity = {}

function TestRsfTier3Mission12Identity:setUp() H.reset() end

-- AC-9 (I-1): the fields F3 must not touch, for the six edited tables
function TestRsfTier3Mission12Identity:test_the_six_tables_keep_their_identity_zone_and_rewards()
	local expected = {
		{ g("recovery", "1a"), "recovery", "space_dantooine" },
		{ g("patrol", "1b"), "patrol", "space_dantooine" },
		{ g("destroy_surpriseattack", "1c"), "destroy_surpriseattack", "space_dantooine" },
		{ g("assassinate", "1d"), "assassinate", "space_naboo" },
		{ g("escort", "2a"), "escort", "space_naboo" },
		{ g("destroy_surpriseattack", "2c"), "destroy_surpriseattack", "space_naboo" },
	}

	for _, row in ipairs(expected) do
		local q = quest(row[1])

		lu.assertEquals(q.className, row[1], row[1] .. ": className")
		lu.assertEquals(q.questType, row[2], row[1] .. ": questType")
		lu.assertEquals(q.questName, row[1]:gsub("^" .. row[2] .. "_", ""), row[1] .. ": questName")
		lu.assertEquals(q.questZone, row[3], row[1] .. ": questZone")
	end

	lu.assertEquals(quest(g("recovery", "1a")).recoverShip, "dru_mdar_tier3", "1a: recoverShip")
	lu.assertEquals(quest(g("recovery", "1a")).creditReward, 25000, "1a: creditReward")
	lu.assertEquals(quest(g("escort", "2a")).creditReward, 25000, "2a: creditReward")
end
