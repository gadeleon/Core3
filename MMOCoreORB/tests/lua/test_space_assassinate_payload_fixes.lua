-- Assassinate payloads match their SWG .tab files (CorSec, Havoc): data and conformance (space-assassinate-payload-fixes).
-- Spec: .claude/work/space-assassinate-payload-fixes/01-spec.md (I-1 to I-3, AC-1 to AC-9, D-8 to D-10).
--
-- SWG: datatables/spacequest/assassinate/<quest>.tab (fixtures/spacequest/assassinate), datatables/space_zones/buildout/<zone>.tab
-- (cut-down extracts fixtures/space_zones/buildout/<zone>.assassinate_points.tab).
-- The expected values come from the fixtures and the spec's literals, never from the Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local S = require("space_assassinate_escort_fix_scenario")
local D = require("space_convo_client_strings_data")

S.load()

local SWG_GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
local FEATURE_COMMIT = "3330e0d8e9"
local SQUADRON_DIR = "bin/scripts/screenplays/space/squadrons/"

local GLOBALS = S.globals()

local function readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")
	f:close()

	return text
end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function linesOf(text)
	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	return lines
end

local function count(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

local function fixtureOf(q) return H.questFixture("assassinate", q.questName) end

local function extractPath(zone) return H.FIXTURES .. "space_zones/buildout/" .. zone .. ".assassinate_points.tab" end

-- name -> { x, z, y } (truncated toward zero) from the buildout extract of `zone`: SWG fltPX, fltPY, fltPZ are Core3 x, z, y
local extractCache = {}

local function extractPoints(zone)
	if extractCache[zone] == nil then
		local tab = H.Tab.read(extractPath(zone))
		local out = {}

		for _, rec in ipairs(tab.records) do
			local vars = rec:get("strObjVars")
			local name = vars and vars:match("nav_name|4|([^|]+)|")

			if name ~= nil then
				out[name] = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")) }
			end
		end

		extractCache[zone] = out
	end

	return extractCache[zone]
end

local function pointNames(q)
	local out = {}

	for i, p in ipairs(q.targetPatrols) do
		out[i] = p.patrolPointName
	end

	return out
end

local function xzy(p) return { x = p.x, z = p.z, y = p.y } end

local function spawnCalls() return H.Engine.timedCallsTo("spawnShipAgent") end

---------------------------------------------------------------------------------------------
-- Discovery
---------------------------------------------------------------------------------------------

TestAssassinatePayloadDiscovery = {}

function TestAssassinatePayloadDiscovery:setUp() H.reset() end

-- AC-6
function TestAssassinatePayloadDiscovery:test_the_three_squadrons_define_24_assassinations()
	lu.assertEquals(#GLOBALS, 24, "assassinate quest tables of CorSec, RSF and Havoc")
end

---------------------------------------------------------------------------------------------
-- AC-1 to AC-4: the literals of the spec
---------------------------------------------------------------------------------------------

TestAssassinatePayloadLiterals = {}

function TestAssassinatePayloadLiterals:setUp() H.reset() end

local ENFORCER = "hidden_daggers_enforcer_tier4"

-- AC-1
function TestAssassinatePayloadLiterals:test_tier4_4a_arrives_after_15_seconds_and_keeps_its_ships_and_path()
	local q = S.quest("assassinate_corellia_privateer_tier4_4a")

	lu.assertEquals(q.arrivalDelay, 15, "tier4_4a: arrivalDelay")
	lu.assertEquals(q.assassinateSpawns.target, "hidden_daggers_nebula_stalker_tier5", "tier4_4a: target")
	lu.assertEquals(q.assassinateSpawns.escorts, { ENFORCER, ENFORCER }, "tier4_4a: escorts")
	lu.assertEquals(pointNames(q), {
		"corellia_privateer_tier4_leg_4_assassin_one_1", "corellia_privateer_tier4_leg_4_assassin_one_2",
		"corellia_privateer_tier4_leg_4_assassin_one_3", "corellia_privateer_tier4_leg_4_assassin_one_4",
	}, "tier4_4a: path")
end

-- AC-2
function TestAssassinatePayloadLiterals:test_tier4_4b_sends_the_executioner_with_four_enforcers_after_15_seconds()
	local q = S.quest("assassinate_corellia_privateer_tier4_4b")

	lu.assertEquals(q.questZone, "space_dathomir", "tier4_4b: questZone")
	lu.assertEquals(q.assassinateSpawns.target, "hidden_daggers_executioner_tier5", "tier4_4b: target")
	lu.assertEquals(q.assassinateSpawns.escorts, { ENFORCER, ENFORCER, ENFORCER, ENFORCER }, "tier4_4b: escorts")
	lu.assertEquals(q.arrivalDelay, 15, "tier4_4b: arrivalDelay")
end

-- AC-2
function TestAssassinatePayloadLiterals:test_tier4_4b_starts_on_assassin_two_1_and_then_follows_the_swg_order()
	local q = S.quest("assassinate_corellia_privateer_tier4_4b")

	lu.assertEquals(pointNames(q), {
		"corellia_privateer_tier4_leg_4_assassin_two_1", "corellia_privateer_tier4_leg_4_assassin_two_2",
		"corellia_privateer_tier4_leg_4_assassin_two_3", "corellia_privateer_tier4_leg_4_assassin_two_4",
	}, "tier4_4b: path order")
	lu.assertEquals(xzy(q.targetPatrols[1]), { x = -7303, z = -6224, y = -2668 }, "tier4_4b: first point coordinates")
	lu.assertEquals(xzy(q.targetPatrols[2]), { x = -6427, z = -5576, y = -4129 }, "tier4_4b: second point coordinates")
end

-- AC-3
function TestAssassinatePayloadLiterals:test_corellia_rebel_4_sends_three_tie_fighters_after_10_seconds()
	local q = S.quest("assassinate_corellia_rebel_4")
	local tie = "imp_tie_fighter_tier1"

	lu.assertEquals(q.assassinateSpawns.escorts, { tie, tie, tie }, "corellia_rebel_4: escorts")
	lu.assertEquals(q.assassinateSpawns.target, "imp_tie_fighter_veteran_tier2", "corellia_rebel_4: target")
	lu.assertEquals(q.arrivalDelay, 10, "corellia_rebel_4: arrivalDelay")
end

-- AC-4
function TestAssassinatePayloadLiterals:test_tier4_2a_first_point_has_its_y()
	local q = S.quest("assassinate_corellia_privateer_tier4_2a")
	local first = q.targetPatrols[1]

	lu.assertEquals(first.patrolPointName, "bh_path_alpha_04", "tier4_2a: first point")
	lu.assertEquals(first.x, 520, "tier4_2a: bh_path_alpha_04 x")
	lu.assertEquals(first.z, 765, "tier4_2a: bh_path_alpha_04 z")
	lu.assertEquals(first.y, -5177, "tier4_2a: bh_path_alpha_04 y")
	lu.assertNil(first[1], "tier4_2a: bh_path_alpha_04 has no positional value")
end

-- AC-4, I-2
for _, global in ipairs(GLOBALS) do
	TestAssassinatePayloadLiterals["test_" .. global .. "_patrol_points_have_exactly_the_known_keys_and_number_coordinates"] = function()
		local q = S.quest(global)

		lu.assertTrue(#q.targetPatrols >= 1, global .. ": targetPatrols is not empty")

		for i, point in ipairs(q.targetPatrols) do
			local where = global .. ": targetPatrols[" .. i .. "] (" .. tostring(point.patrolPointName) .. ")"

			for key in pairs(point) do
				lu.assertEquals(type(key), "string", where .. ": no positional key (" .. tostring(key) .. ")")
				lu.assertTrue(key == "patrolPointName" or key == "x" or key == "z" or key == "y" or key == "zoneName", where .. ": unknown key " .. key)
			end

			lu.assertEquals(type(point.patrolPointName), "string", where .. ": patrolPointName")
			lu.assertEquals(type(point.x), "number", where .. ": x")
			lu.assertEquals(type(point.z), "number", where .. ": z")
			lu.assertEquals(type(point.y), "number", where .. ": y")

			if point.zoneName ~= nil then
				lu.assertEquals(point.zoneName, q.questZone, where .. ": zoneName")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: I-1 payload conformance over the 24 tables (no exception list)
---------------------------------------------------------------------------------------------

TestAssassinatePayloadConformance = {}

function TestAssassinatePayloadConformance:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-6, I-1
	TestAssassinatePayloadConformance["test_" .. global .. "_matches_its_swg_table_on_zone_ships_path_and_delay"] = function()
		local q = S.quest(global)
		local rec = fixtureOf(q)
		local name = "assassinate/" .. q.questName

		lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
		lu.assertEquals(q.assassinateSpawns.target, rec:get("targetShipType"), name .. ": target (targetShipType)")
		lu.assertEquals(q.assassinateSpawns.escorts, rec:list("targetEscort"), name .. ": escorts (targetEscort)")

		local want = {}

		for i, ref in ipairs(rec:list("escortPath")) do
			local zone, pointName = H.Tab.splitNavPoint(ref)

			lu.assertEquals(zone, q.questZone, name .. ": escortPath[" .. i .. "] zone prefix")
			want[i] = pointName
		end

		lu.assertEquals(pointNames(q), want, name .. ": patrol point names in order (escortPath)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), name .. ": arrivalDelay (targetArrivalDelay)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: the buildout extracts
---------------------------------------------------------------------------------------------

TestAssassinatePayloadExtracts = {}

function TestAssassinatePayloadExtracts:setUp() H.reset() end

-- zone -> point count (spec, content contract)
local EXTRACT_ROWS = {
	space_corellia = 9, space_dantooine = 18, space_dathomir = 22, space_endor = 16, space_lok = 9, space_naboo = 18, space_yavin4 = 4,
}

local EXTRACT_ZONES = {}

for zone in pairs(EXTRACT_ROWS) do
	EXTRACT_ZONES[#EXTRACT_ZONES + 1] = zone
end

table.sort(EXTRACT_ZONES)

-- The distinct points of one zone that the 24 SWG tables use
local function swgPointsOf(zone)
	local set = {}

	for _, global in ipairs(GLOBALS) do
		local q = S.quest(global)

		for _, ref in ipairs(fixtureOf(q):list("escortPath")) do
			local z, pointName = H.Tab.splitNavPoint(ref)

			if z == zone then
				set[pointName] = true
			end
		end
	end

	return set
end

for _, zone in ipairs(EXTRACT_ZONES) do
	-- AC-5
	TestAssassinatePayloadExtracts["test_the_" .. zone .. "_extract_is_a_crlf_cut_of_the_swg_buildout_table"] = function()
		local text = readFile(extractPath(zone))

		lu.assertNotNil(text, zone .. ".assassinate_points.tab: missing fixture")
		lu.assertTrue(count(text, "\n") > 2 and count(text, "\n") == count(text, "\r\n") and count(text, "\r") == count(text, "\r\n"), zone .. ": CRLF line endings, as in SWG-Source")

		local swg = readFile(SWG_GAME .. "datatables/space_zones/buildout/" .. zone .. ".tab")

		if swg == nil then
			lu.skip("the SWG-Source clone is not at " .. SWG_GAME)
		end

		local swgLines = {}

		for line in swg:gmatch("[^\n]*\n") do
			swgLines[line] = true
		end

		local first = {}

		for line in swg:gmatch("[^\n]*\n") do
			first[#first + 1] = line

			if #first == 2 then
				break
			end
		end

		local rows = {}

		for line in text:gmatch("[^\n]*\n") do
			rows[#rows + 1] = line
		end

		lu.assertEquals(rows[1], first[1], zone .. ": row 1 (column names) equals the SWG table")
		lu.assertEquals(rows[2], first[2], zone .. ": row 2 (column types) equals the SWG table")

		for i = 3, #rows do
			lu.assertTrue(swgLines[rows[i]], zone .. ": row " .. i .. " is a byte-identical line of the SWG table")
		end
	end

	-- AC-5
	TestAssassinatePayloadExtracts["test_the_" .. zone .. "_extract_holds_exactly_the_points_the_assassinate_tables_use"] = function()
		local points = extractPoints(zone)
		local have, want = {}, {}

		for pointName in pairs(points) do
			have[#have + 1] = pointName
		end

		for pointName in pairs(swgPointsOf(zone)) do
			want[#want + 1] = pointName
		end

		table.sort(have)
		table.sort(want)

		lu.assertEquals(have, want, zone .. ": nav points in the extract")
		lu.assertEquals(#have, EXTRACT_ROWS[zone], zone .. ": number of points")

		local tab = H.Tab.read(extractPath(zone))

		lu.assertEquals(#tab.records, EXTRACT_ROWS[zone], zone .. ": number of data rows")
	end
end

-- AC-5: the 96 rows
function TestAssassinatePayloadExtracts:test_the_seven_extracts_hold_96_points()
	local total = 0

	for _, zone in ipairs(EXTRACT_ZONES) do
		total = total + EXTRACT_ROWS[zone]
	end

	lu.assertEquals(#EXTRACT_ZONES, 7, "zones with an extract")
	lu.assertEquals(total, 96, "points in the extracts")
end

---------------------------------------------------------------------------------------------
-- AC-5: I-3 coordinates over the 24 tables
---------------------------------------------------------------------------------------------

TestAssassinatePayloadCoordinates = {}

function TestAssassinatePayloadCoordinates:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-5, I-3
	TestAssassinatePayloadCoordinates["test_" .. global .. "_points_equal_the_patrol_point_file_and_the_swg_buildout_row"] = function()
		local q = S.quest(global)
		local patrol = H.patrolPoints(q.questZone)
		local extract = extractPoints(q.questZone)

		for i, point in ipairs(q.targetPatrols) do
			local where = global .. ": targetPatrols[" .. i .. "] " .. point.patrolPointName

			lu.assertNotNil(patrol[point.patrolPointName], where .. ": exists in ship_mobile/patrol_points/" .. q.questZone .. ".lua")
			lu.assertNotNil(extract[point.patrolPointName], where .. ": exists in the buildout extract of " .. q.questZone)
			lu.assertEquals(xzy(point), xzy(patrol[point.patrolPointName]), where .. ": {x, z, y} against the patrol point file")
			lu.assertEquals(xzy(point), extract[point.patrolPointName], where .. ": {x, z, y} against the SWG buildout row truncated toward zero")
		end
	end
end

-- The 10 corrected values (spec C-1..C-10): the points whose old values were wrong. `from` is the old line, `to` the SWG value.
local COORDINATE_FIXES = {
	{ "C-1", "assassinate_corellia_privateer_tier1_4a", "assassinate_4", { 2650, -1672, -105 }, { 2650, -1671, -104 } },
	{ "C-2", "assassinate_corellia_privateer_tier1_4a", "assassinate_5", { 4431, -1858, 2196 }, { 4431, -1857, 2196 } },
	{ "C-3", "assassinate_corellia_privateer_tier1_4a", "corellia_imperial_tier2_assassinate_2", { -5276, -1117, -6270 }, { -5275, -1116, -6269 } },
	{ "C-4", "assassinate_corellia_privateer_tier2_4a", "corellia_imperial_tier3_leg_4_assassinate_three_1", { -137, -1281, 2629 }, { -136, 1280, 2628 } },
	{ "C-5", "assassinate_corellia_privateer_tier2_4a", "corellia_imperial_tier4_recovery1_2", { 1014, -432, 1398 }, { 1014, -431, 1398 } },
	{ "C-6", "assassinate_corellia_privateer_tier3_4", "corellia_privateer_tier3_assassin_1", { 5978, 1103, -3021 }, { 5978, 1102, -3020 } },
	{ "C-7", "assassinate_corellia_privateer_tier3_4", "corellia_privateer_tier3_assassin_2", { 1503, 857, -4461 }, { 1503, 856, -4460 } },
	{ "C-8", "assassinate_corellia_privateer_tier3_4", "corellia_privateer_tier3_assassin_3", { -1962, 658, -3496 }, { -1961, 658, -3496 } },
	{ "C-9", "assassinate_corellia_privateer_tier3_4", "corellia_privateer_tier3_assassin_4", { -5906, 487, -2508 }, { -5905, 486, -2508 } },
	{ "C-10", "assassinate_corellia_privateer_tier4_2a", "corellia_imperial_tier4_escort1_2", { -7504, -314, -4018 }, { -7504, -313, -4018 } },
}

for _, row in ipairs(COORDINATE_FIXES) do
	local ref, global, pointName, from, to = row[1], row[2], row[3], row[4], row[5]

	-- AC-5
	TestAssassinatePayloadCoordinates["test_" .. ref:gsub("-", "") .. "_" .. global .. "_" .. pointName .. "_has_the_swg_coordinates"] = function()
		local q = S.quest(global)
		local point

		for _, p in ipairs(q.targetPatrols) do
			if p.patrolPointName == pointName then
				point = p
			end
		end

		lu.assertNotNil(point, ref .. " " .. global .. ": has point " .. pointName)
		lu.assertEquals({ point.x, point.z, point.y }, to, ref .. " " .. global .. " " .. pointName .. ": {x, z, y}")
		lu.assertNotEquals(from, to, ref .. ": the old value differs from the SWG value (guards this table)")
		lu.assertEquals({ extractPoints(q.questZone)[pointName].x, extractPoints(q.questZone)[pointName].z, extractPoints(q.questZone)[pointName].y }, to, ref .. ": the SWG buildout row")
		lu.assertEquals(xzy(H.patrolPoints(q.questZone)[pointName]), { x = to[1], z = to[2], y = to[3] }, ref .. ": the patrol point file")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: runtime (I-4)
---------------------------------------------------------------------------------------------

TestAssassinatePayloadRuntime = {}

function TestAssassinatePayloadRuntime:setUp() H.reset() end

-- global, arrivalDelay s, expected spawn count, target template, first point {x, z, y} (nil = the patrol point file)
local RUNTIME = {
	{ "assassinate_corellia_privateer_tier4_4a", 15, 3, "hidden_daggers_nebula_stalker_tier5", nil },
	{ "assassinate_corellia_privateer_tier4_4b", 15, 5, "hidden_daggers_executioner_tier5", { -7303, -6224, -2668 } },
	{ "assassinate_corellia_rebel_4", 10, 4, "imp_tie_fighter_veteran_tier2", nil },
	{ "assassinate_corellia_privateer_tier4_2a", nil, 5, nil, { 520, 765, -5177 } },
}

for _, row in ipairs(RUNTIME) do
	local global, delay, want, targetTemplate, firstPoint = row[1], row[2], row[3], row[4], row[5]

	-- AC-7
	TestAssassinatePayloadRuntime["test_" .. global .. "_deploys_target_and_escorts_at_the_first_point_after_its_swg_delay"] = function()
		local q = S.quest(global)
		local rec = fixtureOf(q)
		local escorts = rec:list("targetEscort")

		lu.assertEquals(1 + #escorts, want, global .. ": precondition: the SWG table has " .. (want - 1) .. " escorts")

		delay = delay or rec:num("targetArrivalDelay")

		for i, point in ipairs(q.targetPatrols) do
			lu.assertEquals(type(point.y), "number", global .. ": precondition: targetPatrols[" .. i .. "] (" .. point.patrolPointName .. ") has a number y")
		end

		local run = S.started(global)

		H.advance(delay * 1000 - 1)
		lu.assertEquals(#spawnCalls(), 0, global .. ": spawnShipAgent calls 1 ms before " .. delay .. " s")
		H.advance(1)

		local calls = spawnCalls()

		lu.assertEquals(#calls, want, global .. ": spawnShipAgent calls at " .. delay .. " s")
		lu.assertEquals(calls[1].t, delay * 1000, global .. ": time of the spawn")

		local x, z, y
		local _, firstName = H.Tab.splitNavPoint(rec:list("escortPath")[1])
		local patrolPoint = H.patrolPoints(q.questZone)[firstName]

		if firstPoint then
			x, z, y = firstPoint[1], firstPoint[2], firstPoint[3]
		else
			x, z, y = patrolPoint.x, patrolPoint.z, patrolPoint.y
		end

		lu.assertEquals(calls[1].args[1], targetTemplate or rec:get("targetShipType"), global .. ": target template")
		lu.assertEquals(calls[1].args[2], q.questZone, global .. ": zone")
		lu.assertEquals({ calls[1].args[3], calls[1].args[4], calls[1].args[5] }, { x, z, y }, global .. ": target position (x, z, y)")

		for i, escort in ipairs(escorts) do
			lu.assertEquals(calls[i + 1].args[1], escort, global .. ": escort " .. i .. " template")
		end

		lu.assertNotNil(run.player, global .. ": the pilot")
	end
end

-- AC-7: 4_4b plays to a win with all four escorts counted
function TestAssassinatePayloadRuntime:test_tier4_4b_is_won_by_four_escort_kills_and_then_the_target()
	local run = S.deployed("assassinate_corellia_privateer_tier4_4b")
	local q = run.q

	lu.assertEquals(#run.escorts, 4, "tier4_4b: escorts deployed")
	lu.assertEquals(run.target ~= nil, true, "tier4_4b: target deployed")

	for i = 1, 3 do
		S.kill(run, run.escorts[i])
		lu.assertEquals(S.take(run), { { id = S.sid(q, "escort_remaining"), DI = 4 - i } }, "tier4_4b: messages at escort kill " .. i .. " of 4")
	end

	S.kill(run, run.escorts[4])
	lu.assertEquals(S.ids(S.take(run)), { S.sid(q, "escort_wiped_out") }, "tier4_4b: messages at the last escort kill")

	S.kill(run, run.target)
	lu.assertEquals(S.ids(S.take(run)), { S.sid(q, "assassinate_success") }, "tier4_4b: messages at the target kill")
end

-- AC-7: rebel_4 needs only the target, and counts its three escorts
function TestAssassinatePayloadRuntime:test_corellia_rebel_4_counts_three_escorts_down_from_two()
	local run = S.deployed("assassinate_corellia_rebel_4")
	local q = run.q

	lu.assertEquals(#run.escorts, 3, "corellia_rebel_4: escorts deployed")
	S.kill(run, run.escorts[1])
	lu.assertEquals(S.take(run), { { id = S.sid(q, "escort_remaining"), DI = 2 } }, "corellia_rebel_4: escort_remaining after the first kill")
	S.kill(run, run.escorts[2])
	lu.assertEquals(S.take(run), { { id = S.sid(q, "escort_remaining"), DI = 1 } }, "corellia_rebel_4: escort_remaining after the second kill")
end

---------------------------------------------------------------------------------------------
-- AC-8: the workaround is gone
---------------------------------------------------------------------------------------------

TestAssassinatePayloadWorkaround = {}

function TestAssassinatePayloadWorkaround:setUp() H.reset() end

-- AC-8
function TestAssassinatePayloadWorkaround:test_the_escort_fix_scenario_no_longer_writes_to_a_patrol_point()
	local text = readFile("tests/lua/space_assassinate_escort_fix_scenario.lua")

	lu.assertNotNil(text, "space_assassinate_escort_fix_scenario.lua")
	lu.assertNil(text:find("point%.y%s*="), "the scenario writes point.y")
	lu.assertNil(text:find("point%[1%]"), "the scenario reads point[1]")
	lu.assertNil(text:find("targetPatrols", 1, true), "the scenario touches targetPatrols")
end

-- AC-8
function TestAssassinatePayloadWorkaround:test_isolate_leaves_every_patrol_point_as_loaded()
	local q = S.quest("assassinate_corellia_privateer_tier4_2a")
	local before = {}

	for i, p in ipairs(q.targetPatrols) do
		before[i] = { p.patrolPointName, p.x, p.z, p.y, p[1] }
	end

	S.isolate(q)

	for i, p in ipairs(q.targetPatrols) do
		lu.assertEquals({ p.patrolPointName, p.x, p.z, p.y, p[1] }, before[i], "tier4_2a: point " .. i .. " after S.isolate")
	end
end

-- AC-8: README
function TestAssassinatePayloadWorkaround:test_the_readme_no_longer_documents_the_y_patch()
	local text = readFile("tests/lua/README.md")

	lu.assertNotNil(text, "README.md")
	lu.assertNil(text:find("the `y` its line lacks", 1, true), "README still documents the S.isolate y patch")
end

---------------------------------------------------------------------------------------------
-- AC-9: the working-tree squadron files against the escort-fix commit
---------------------------------------------------------------------------------------------

TestAssassinatePayloadFilePins = {}

function TestAssassinatePayloadFilePins:setUp() H.reset() end

local T = "\t"

local function coordLine(name, x, z, y)
	return T .. T .. string.format('{patrolPointName = "%s", x = %d, z = %d, y = %d},', name, x, z, y)
end

local ENF = '"hidden_daggers_enforcer_tier4"'
local TWO = "corellia_privateer_tier4_leg_4_assassin_two_"

-- line number at FEATURE_COMMIT -> exact new text
local EDITS = {
	["CorsecSquadronScreenplay.lua"] = {
		[209] = coordLine("assassinate_4", 2650, -1671, -104),
		[210] = coordLine("assassinate_5", 4431, -1857, 2196),
		[212] = coordLine("corellia_imperial_tier2_assassinate_2", -5275, -1116, -6269),
		[415] = coordLine("corellia_imperial_tier3_leg_4_assassinate_three_1", -136, 1280, 2628),
		[416] = coordLine("corellia_imperial_tier4_recovery1_2", 1014, -431, 1398),
		[1059] = coordLine("corellia_privateer_tier3_assassin_1", 5978, 1102, -3020),
		[1060] = coordLine("corellia_privateer_tier3_assassin_2", 1503, 856, -4460),
		[1061] = coordLine("corellia_privateer_tier3_assassin_3", -1961, 658, -3496),
		[1062] = coordLine("corellia_privateer_tier3_assassin_4", -5905, 486, -2508),
		[1319] = T .. T .. '{patrolPointName = "bh_path_alpha_04", x = 520, z = 765, y = -5177},',
		[1321] = coordLine("corellia_imperial_tier4_escort1_2", -7504, -313, -4018),
		[1577] = T .. "arrivalDelay = 15, -- Seconds",
		[1619] = T .. "arrivalDelay = 15, -- Seconds",
		[1624] = T .. T .. 'target = "hidden_daggers_executioner_tier5",',
		[1625] = T .. T .. "escorts = {" .. ENF .. ", " .. ENF .. ", " .. ENF .. ", " .. ENF .. "},",
		[1629] = coordLine(TWO .. "1", -7303, -6224, -2668),
		[1630] = coordLine(TWO .. "2", -6427, -5576, -4129),
	},
	["HavocSquadronScreenplay.lua"] = {
		[180] = T .. "arrivalDelay = 10,",
		[186] = T .. T .. 'escorts = {"imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1"},',
	},
	["RsfSquadronScreenplay.lua"] = {},
}

for _, short in ipairs({ "CorsecSquadronScreenplay.lua", "HavocSquadronScreenplay.lua", "RsfSquadronScreenplay.lua" }) do
	local path = SQUADRON_DIR .. short
	local edits = EDITS[short]
	local n = 0

	for _ in pairs(edits) do
		n = n + 1
	end

	-- AC-9
	TestAssassinatePayloadFilePins["test_" .. short:gsub("%.lua$", "") .. "_differs_from_the_escort_fix_commit_only_on_the_" .. n .. "_spec_lines"] = function()
		local rc, base = shell("git show " .. FEATURE_COMMIT .. ":MMOCoreORB/" .. path)

		if rc ~= 0 then
			lu.skip("git show " .. FEATURE_COMMIT .. " is unavailable: " .. base)
		end

		local now = readFile(path)

		lu.assertNotNil(now, path)
		lu.assertEquals(count(now, "\r"), 0, short .. ": stays LF")

		local nowLines, baseLines = linesOf(now), linesOf(base)

		lu.assertEquals(#nowLines, #baseLines, short .. ": line count against " .. FEATURE_COMMIT)

		for i = 1, #baseLines do
			local want = edits[i] or baseLines[i]

			if nowLines[i] ~= want then
				lu.fail(short .. ":" .. i .. ": expected `" .. want .. "` but found `" .. tostring(nowLines[i]) .. "`")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- D-9 and D-10: no reward and no split delay changes
---------------------------------------------------------------------------------------------

TestAssassinatePayloadNoRewardOrDelayChange = {}

function TestAssassinatePayloadNoRewardOrDelayChange:setUp() H.reset() end

-- global -> the lines of its table before "-- Screenplay Specific Variables" / arrivalDelay (rewards, split wiring and delay)
local function headerLines(text)
	local out, current, collecting = {}, nil, false

	for _, line in ipairs(linesOf(text)) do
		local global = line:match("^(assassinate_[%w_]+) = SpaceAssassinateScreenplay:new")

		if global then
			current, collecting = global, true
			out[current] = {}
		elseif current and line:match("^%s*arrivalDelay%s*=") then
			collecting = false
		elseif current and collecting then
			out[current][#out[current] + 1] = line
		end
	end

	return out
end

for _, short in ipairs({ "CorsecSquadronScreenplay.lua", "HavocSquadronScreenplay.lua", "RsfSquadronScreenplay.lua" }) do
	local path = SQUADRON_DIR .. short

	-- AC-9, D-9, D-10
	TestAssassinatePayloadNoRewardOrDelayChange["test_" .. short:gsub("%.lua$", "") .. "_keeps_every_reward_and_split_field_of_every_table"] = function()
		local rc, base = shell("git show " .. FEATURE_COMMIT .. ":MMOCoreORB/" .. path)

		if rc ~= 0 then
			lu.skip("git show " .. FEATURE_COMMIT .. " is unavailable: " .. base)
		end

		local now = readFile(path)
		local before, after = headerLines(base), headerLines(now)
		local tables = 0

		for global, lines in pairs(before) do
			tables = tables + 1
			lu.assertEquals(after[global], lines, global .. ": creditReward, itemReward and split fields (sideQuestDelay)")
		end

		lu.assertTrue(tables >= 7, short .. ": assassinate tables parsed (" .. tables .. ")")
	end
end

-- D-9: the five tables that pay nothing today still pay nothing
for _, global in ipairs({
	"assassinate_corellia_privateer_tier2_4a", "assassinate_corellia_privateer_tier4_2a", "assassinate_corellia_privateer_tier4_4a",
	"assassinate_viopa_rebel_4", "assassinate_corellia_rebel_tier3_4",
}) do
	-- D-9
	TestAssassinatePayloadNoRewardOrDelayChange["test_" .. global .. "_still_pays_no_credits"] = function()
		lu.assertEquals(S.quest(global).creditReward or 0, 0, global .. ": creditReward")
	end
end

-- D-10: the split delays stay (SWG uses 5)
local DELAYS = {
	assassinate_corellia_privateer_tier3_4 = 1, assassinate_corellia_privateer_tier4_1b = 2, assassinate_corellia_privateer_tier4_2a = 2,
	assassinate_corellia_privateer_tier4_3b = 1, assassinate_corellia_privateer_tier4_4a = 1, assassinate_corellia_privateer_tier4_4b = 1,
	assassinate_corellia_rebel_tier3_1_c = 0, assassinate_corellia_rebel_tier3_3_a = 0, assassinate_corellia_rebel_tier3_4 = 2,
	assassinate_corellia_rebel_tier4_2 = 2, assassinate_corellia_rebel_tier4_4_a = 0,
}

for global, delay in pairs(DELAYS) do
	-- D-10
	TestAssassinatePayloadNoRewardOrDelayChange["test_" .. global .. "_keeps_its_split_delay_of_" .. delay] = function()
		lu.assertEquals(S.quest(global).sideQuestDelay, delay, global .. ": sideQuestDelay")
	end
end

-- AC-10
function TestAssassinatePayloadNoRewardOrDelayChange:test_the_client_string_gaps_stay_closed()
	lu.assertEquals(D.KNOWN_GAPS, {}, "KNOWN_GAPS")
end
