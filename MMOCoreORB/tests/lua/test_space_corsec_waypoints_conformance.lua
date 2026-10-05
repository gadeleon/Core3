-- Quest points of every non-assassinate quest table match SWG-Source: names and order, coordinates, spawners, numbering, zone
-- (space-corsec-waypoints). Spec: .claude/work/space-corsec-waypoints/01-spec.md (I-1 to I-6, D-7, AC-4 to AC-7).
--
-- Table-driven over every quest global of the CorSec, RSF and Havoc squadrons whose type carries quest points (discovered at run time),
-- with NO exception list. Expected values come from the SWG-Source fixtures: spacequest/<type>/<name>.tab, the buildout extracts
-- fixtures/space_zones/buildout/<zone>.quest_points.tab (truncated toward zero) and, for I-6, the full buildout in the research clone.

local lu = require("luaunit")
local H = require("harness")
local W = require("space_corsec_waypoints_data")

local GLOBALS, NAMES = W.globals()

local function tableOf(name) return GLOBALS[name] end

---------------------------------------------------------------------------------------------
-- Discovery: the walk must cover the tables the spec counts
---------------------------------------------------------------------------------------------

TestCorsecWaypointsDiscovery = {}

function TestCorsecWaypointsDiscovery:setUp() H.reset() end

-- type -> number of tables (spec "Clean by type", after the edits)
local TYPE_COUNTS = {
	delivery = 5, delivery_no_pickup = 3, destroy = 6, escort = 15, escort_duty = 9, inspect = 7, patrol = 14,
	recovery = 6, recovery_duty = 6, rescue = 3, rescue_duty = 3, space_battle = 16, survival = 8,
}

-- AC-4, AC-5
function TestCorsecWaypointsDiscovery:test_the_walk_covers_the_tables_of_every_point_type()
	local counts = {}

	for _, name in ipairs(NAMES) do
		local t = tableOf(name).questType

		counts[t] = (counts[t] or 0) + 1
	end

	lu.assertEquals(counts, TYPE_COUNTS, "non-assassinate quest tables by questType")
	lu.assertEquals(#NAMES, 101, "quest tables walked")
end

-- AC-5: 100 tables have a SWG table, 75 with fixtures from earlier features and 25 with the new ones
function TestCorsecWaypointsDiscovery:test_only_destroy_corellia_rebel_master_has_no_swg_table()
	local without, with = {}, 0

	for _, name in ipairs(NAMES) do
		if W.swg(tableOf(name)) == nil then
			without[#without + 1] = name
		else
			with = with + 1
		end
	end

	lu.assertEquals(without, { "destroy_corellia_rebel_master" }, "tables without a SWG-Source .tab")
	lu.assertEquals(with, 100, "tables compared with their SWG table")
end

-- AC-4: enough points are walked for the pin to mean something (spec: 334 named points plus 16 spawner references, before the edits)
function TestCorsecWaypointsDiscovery:test_the_walk_checks_more_than_300_points()
	local n = 0

	for _, name in ipairs(NAMES) do
		local q = tableOf(name)

		for _, f in ipairs(W.fields(q)) do
			n = n + #W.points(q, f)
		end
	end

	lu.assertTrue(n >= 300, "points walked: " .. n)
end

---------------------------------------------------------------------------------------------
-- AC-5: I-1 names and order (no exception list)
---------------------------------------------------------------------------------------------

TestCorsecWaypointsNames = {}

function TestCorsecWaypointsNames:setUp() H.reset() end

for _, name in ipairs(NAMES) do
	local q = tableOf(name)

	if W.swg(q) ~= nil then
		-- AC-5, I-1
		TestCorsecWaypointsNames["test_" .. name .. "_points_match_the_swg_names_in_order_and_zone"] = function()
			local rec = W.swg(q)
			local label = q.questType .. "/" .. q.questName

			lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")

			for _, f in ipairs(W.fields(q)) do
				local want, zones = W.swgNames(rec, f.col)
				local have = {}

				for i, p in ipairs(W.points(q, f)) do
					have[i] = W.pointName(p)
				end

				lu.assertEquals(have, want, label .. ": " .. f.field .. " names in order (" .. f.col .. ")")

				for i, zone in ipairs(zones) do
					lu.assertEquals(zone, q.questZone, label .. ": " .. f.col .. "[" .. i .. "] zone prefix")
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: I-2, I-3 coordinates and I-5 in-zone (no exception list)
---------------------------------------------------------------------------------------------

TestCorsecWaypointsCoordinates = {}

function TestCorsecWaypointsCoordinates:setUp() H.reset() end

local function extractFor(zone)
	for _, z in ipairs(W.EXTRACT_ZONES) do
		if z == zone then
			return W.extract(zone)
		end
	end

	return nil
end

for _, name in ipairs(NAMES) do
	local q = tableOf(name)

	-- AC-4, I-2, I-3, I-5
	TestCorsecWaypointsCoordinates["test_" .. name .. "_points_equal_the_patrol_point_file_and_the_swg_buildout_row"] = function()
		local label = q.questType .. "/" .. q.questName

		for _, f in ipairs(W.fields(q)) do
			for i, p in ipairs(W.points(q, f)) do
				local pointName = W.pointName(p)
				local where = label .. ": " .. f.field .. "[" .. i .. "] " .. tostring(pointName)
				local zone = p.zoneName or q.questZone

				lu.assertEquals(type(p.x), "number", where .. ": x")
				lu.assertEquals(type(p.z), "number", where .. ": z")
				lu.assertEquals(type(p.y), "number", where .. ": y")

				local extract = extractFor(zone)

				lu.assertNotNil(extract, where .. ": a quest_points extract exists for " .. tostring(zone))

				if f.kind == "nav" then
					local patrol = H.patrolPoints(zone)[pointName]
					local row = extract.nav[pointName]

					lu.assertNotNil(patrol, where .. ": exists in ship_mobile/patrol_points/" .. zone .. ".lua")
					lu.assertNotNil(row, where .. ": exists in the buildout extract of " .. zone)
					lu.assertEquals(W.xzy(p), W.xzy(patrol), where .. ": {x, z, y} against the patrol point file")
					lu.assertEquals(W.xzy(p), row, where .. ": {x, z, y} against the SWG buildout row truncated toward zero")
				else
					local row = extract.spawner[pointName]

					lu.assertNotNil(row, where .. ": a strSpawnerName row exists in the buildout extract of " .. zone)
					lu.assertEquals(W.xzy(p), row, where .. ": {x, z, y} against the first SWG spawner row truncated toward zero")
				end
			end
		end
	end
end

TestCorsecWaypointsInZone = {}

function TestCorsecWaypointsInZone:setUp() H.reset() end

for _, name in ipairs(NAMES) do
	local q = tableOf(name)

	-- AC-4, I-5
	TestCorsecWaypointsInZone["test_" .. name .. "_points_are_inside_the_16_km_zone"] = function()
		local label = q.questType .. "/" .. q.questName

		for _, f in ipairs(W.fields(q)) do
			for i, p in ipairs(W.points(q, f)) do
				for _, axis in ipairs({ "x", "z", "y" }) do
					lu.assertEquals(type(p[axis]), "number", label .. ": " .. f.field .. "[" .. i .. "] " .. tostring(W.pointName(p)) .. ": " .. axis)
					lu.assertTrue(p[axis] >= -8192 and p[axis] < 8192, label .. ": " .. f.field .. "[" .. i .. "] " .. tostring(W.pointName(p)) .. ": " .. axis .. " = " .. tostring(p[axis]) .. " is inside [-8192, 8192)")
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: I-4 numbering and zone
---------------------------------------------------------------------------------------------

TestCorsecWaypointsNumbering = {}

function TestCorsecWaypointsNumbering:setUp() H.reset() end

for _, name in ipairs(NAMES) do
	local q = tableOf(name)

	-- AC-6, I-4
	TestCorsecWaypointsNumbering["test_" .. name .. "_points_are_numbered_by_list_index_and_in_the_quest_zone"] = function()
		local label = q.questType .. "/" .. q.questName

		for _, f in ipairs(W.fields(q)) do
			for i, p in ipairs(W.points(q, f)) do
				local where = label .. ": " .. f.field .. "[" .. i .. "] " .. tostring(W.pointName(p))

				if f.number ~= nil then
					lu.assertEquals(p[f.number], i, where .. ": " .. f.number)
				end

				if f.zoneRequired then
					lu.assertEquals(p.zoneName, q.questZone, where .. ": zoneName")
				elseif p.zoneName ~= nil then
					lu.assertEquals(p.zoneName, q.questZone, where .. ": zoneName")
				end

				for key in pairs(p) do
					lu.assertEquals(type(key), "string", where .. ": no positional key (" .. tostring(key) .. ")")
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: I-6 the patrol point files against the full buildout (clone-gated, D-14)
---------------------------------------------------------------------------------------------

TestCorsecWaypointsPatrolPointFiles = {}

function TestCorsecWaypointsPatrolPointFiles:setUp() H.reset() end

-- name .. " " .. x .. " " .. z .. " " .. y of every `nav_name` row of quest_nav_point.iff and `strName` row of basic_patrol_point.iff
local function buildoutEntries(zone)
	local path = W.SWG_BUILDOUT .. zone .. ".tab"
	local f = io.open(path, "rb")

	if f == nil then
		lu.skip("the SWG-Source clone is not at " .. W.SWG_GAME .. " (needed for the full buildout " .. path .. ")")
	end

	local out = {}

	for line in f:lines() do
		local cols = {}

		for c in (line:gsub("\r$", "") .. "\t"):gmatch("([^\t]*)\t") do
			cols[#cols + 1] = c
		end

		local name

		if cols[1] and cols[1]:find("quest_nav_point.iff", 1, true) then
			name = (cols[11] or ""):match("nav_name|4|([^|]+)|")
		elseif cols[1] and cols[1]:find("basic_patrol_point.iff", 1, true) then
			name = (cols[11] or ""):match("strName|4|([^|]+)|")
		end

		if name ~= nil then
			out[#out + 1] = string.format("%s %d %d %d", name, W.trunc(tonumber(cols[8])), W.trunc(tonumber(cols[9])), W.trunc(tonumber(cols[10])))
		end
	end

	f:close()

	return out
end

local function ppEntries(zone)
	H.patrolPoints(zone) -- loads the files

	local out = {}

	for _, p in ipairs(H.Engine.patrolPoints[zone]) do
		out[#out + 1] = string.format("%s %d %d %d", p.patrolPointName, p.x, p.z, p.y)
	end

	return out
end

local function multiset(list)
	local m = {}

	for _, v in ipairs(list) do
		m[v] = (m[v] or 0) + 1
	end

	return m
end

-- entries of `a` that `b` does not have (as many times), sorted
local function minus(a, b)
	local have, out = multiset(b), {}

	for _, v in ipairs(a) do
		if (have[v] or 0) > 0 then
			have[v] = have[v] - 1
		else
			out[#out + 1] = v
		end
	end

	table.sort(out)

	return out
end

for _, zone in ipairs(W.PP_ZONES) do
	-- AC-7, I-6
	TestCorsecWaypointsPatrolPointFiles["test_patrol_points_of_" .. zone .. "_equal_the_truncated_buildout_rows"] = function()
		local bo = buildoutEntries(zone)
		local pp = ppEntries(zone)

		lu.assertEquals(minus(bo, pp), {}, zone .. ": buildout nav/patrol rows (name x z y, truncated) missing from ship_mobile/patrol_points/" .. zone .. ".lua")
		lu.assertEquals(minus(pp, bo), {}, zone .. ": patrol point entries with no matching buildout row")
		lu.assertEquals(#pp, #bo, zone .. ": number of entries")
	end
end

-- AC-7: 5995 entries in 10 zones
function TestCorsecWaypointsPatrolPointFiles:test_the_ten_patrol_point_files_hold_5995_entries()
	local total = 0

	for _, zone in ipairs(W.PP_ZONES) do
		total = total + #ppEntries(zone)
	end

	lu.assertEquals(#W.PP_ZONES, 10, "zones with a patrol point file")
	lu.assertEquals(total, 5995, "entries in the patrol point files")
end
