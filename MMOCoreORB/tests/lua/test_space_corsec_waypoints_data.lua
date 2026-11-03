-- Quest waypoints and patrol coordinates match the SWG buildout (CorSec, Havoc): literals, fixtures and file pins
-- (space-corsec-waypoints). Spec: .claude/work/space-corsec-waypoints/01-spec.md (W-1 to W-8, R, AC-1 to AC-3, AC-9, AC-10).
--
-- The expected values are the spec's literals (space_corsec_waypoints_data.lua) and the SWG-Source fixtures, never the Core3 tables under test.
-- The file pins read the base side from `git show 97a8c4aed7` and skip when git cannot show it.

local lu = require("luaunit")
local H = require("harness")
local W = require("space_corsec_waypoints_data")
local D = require("space_convo_client_strings_data")

local GLOBALS = W.globals()

local function quest(name) return H.expectGlobal(name, "quest table of the CorSec/Havoc squadron screenplay") end

-- an expected escort/patrol point as the table holds it, from { name, x, z, y, number }
local function escortEntry(row, zone)
	return { patrolPointName = row[1], zoneName = zone, x = row[2], z = row[3], y = row[4], escortNumber = row[5], radius = 250 }
end

local function patrolEntry(row, zone)
	return { patrolPointName = row[1], zoneName = zone, x = row[2], z = row[3], y = row[4], patrolNumber = row[5], radius = 150 }
end

-- every point of the table (any field) with this name: list of { field, point }
local function occurrences(q, fieldNames, name)
	local out = {}

	for _, field in ipairs(fieldNames) do
		for _, p in ipairs(rawget(q, field) or {}) do
			if p.patrolPointName == name then
				out[#out + 1] = { field = field, point = p }
			end
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-1, AC-2: the literals of the spec
---------------------------------------------------------------------------------------------

TestCorsecWaypointsLiterals = {}

function TestCorsecWaypointsLiterals:setUp() H.reset() end

-- AC-1 (W-1, W-7)
function TestCorsecWaypointsLiterals:test_turoldine_escort_duty_has_exactly_the_four_swg_points_in_the_zone()
	local q = quest(W.TUROLDINE_DUTY)
	local want = {}

	for i, row in ipairs(W.TUROLDINE_DUTY_POINTS) do
		want[i] = escortEntry(row, "space_dathomir")
	end

	lu.assertEquals(q.escortPoints, want, W.TUROLDINE_DUTY .. ": escortPoints (names, zone, x z y, escortNumber 1..4, radius 250; no _2, no x = 23729)")
end

-- AC-1 (W-1)
function TestCorsecWaypointsLiterals:test_turoldine_escort_duty_last_point_is_at_x_2372_inside_the_zone()
	local q = quest(W.TUROLDINE_DUTY)
	local last = q.escortPoints[#q.escortPoints]

	lu.assertEquals(W.xzy(last), { x = 2372, z = 7391, y = -1995 }, W.TUROLDINE_DUTY .. ": last point {x, z, y}")
	lu.assertEquals(last.patrolPointName, "corellia_privateer_tier4_escort_duty_5", W.TUROLDINE_DUTY .. ": last point name")
end

-- AC-1 (W-7)
function TestCorsecWaypointsLiterals:test_turoldine_escort_duty_has_no_escort_duty_2_point()
	local q = quest(W.TUROLDINE_DUTY)

	for _, p in ipairs(q.escortPoints) do
		lu.assertNotEquals(p.patrolPointName, "corellia_privateer_tier4_escort_duty_2", W.TUROLDINE_DUTY .. ": SWG has no escort_duty_2")
	end
end

-- AC-1 (W-4)
function TestCorsecWaypointsLiterals:test_rikkh_mission_2_escort_uses_the_yavin4_privateer_escort_points()
	local q = quest(W.RIKKH_M2)
	local want = {}

	for i, row in ipairs(W.RIKKH_M2_POINTS) do
		want[i] = escortEntry(row, "space_yavin4")
	end

	lu.assertEquals(q.escortPoints, want, W.RIKKH_M2 .. ": escortPoints (yavin4_privateer_escort_1..4, truncated buildout values)")
end

-- AC-1 (W-5)
function TestCorsecWaypointsLiterals:test_rikkh_escort_duty_uses_the_lok_privateer_escort_points()
	local q = quest(W.RIKKH_DUTY)
	local want = {}

	for i, row in ipairs(W.RIKKH_DUTY_POINTS) do
		want[i] = escortEntry(row, "space_lok")
	end

	lu.assertEquals(q.questZone, "space_lok", W.RIKKH_DUTY .. ": questZone stays space_lok (D-3)")
	lu.assertEquals(q.escortPoints, want, W.RIKKH_DUTY .. ": escortPoints (lok_privateer_escort_1..4)")
end

-- AC-1 (W-3)
function TestCorsecWaypointsLiterals:test_ramna_mission_3_patrol_leg_has_the_swg_patrol_points()
	local q = quest(W.RAMNA_M3_PATROL)
	local want = {}

	for i, row in ipairs(W.RAMNA_M3_PATROL_POINTS) do
		want[i] = patrolEntry(row, "space_dantooine")
	end

	lu.assertEquals(q.patrolPoints, want, W.RAMNA_M3_PATROL .. ": patrolPoints (four distinct points)")
end

-- AC-1 (W-2, R)
for name, c in pairs(W.RAMNA_M1_RECOVERY_POINTS) do
	TestCorsecWaypointsLiterals["test_ramna_mission_1_recovery_point_" .. name .. "_has_the_truncated_buildout_value"] = function()
		local q = quest(W.RAMNA_M1_RECOVERY)
		local found = occurrences(q, { "preRecoveryPoints", "recoveryPoints" }, name)

		lu.assertTrue(#found >= 1, W.RAMNA_M1_RECOVERY .. ": has point " .. name)

		for _, f in ipairs(found) do
			lu.assertEquals(W.xzy(f.point), { x = c[1], z = c[2], y = c[3] }, W.RAMNA_M1_RECOVERY .. "." .. f.field .. ": " .. name .. " {x, z, y}")
		end
	end
end

-- AC-1 (W-2)
function TestCorsecWaypointsLiterals:test_imperial_ss_interception_1_has_a_positive_y()
	local q = quest(W.RAMNA_M1_RECOVERY)
	local found = occurrences(q, { "preRecoveryPoints", "recoveryPoints" }, "imperial_ss_interception_1")

	lu.assertEquals(#found, 1, W.RAMNA_M1_RECOVERY .. ": imperial_ss_interception_1 occurrences")
	lu.assertEquals(found[1].point.y, 7336, W.RAMNA_M1_RECOVERY .. ": imperial_ss_interception_1 y (sign error W-2)")
end

-- AC-1 (R)
for name, c in pairs(W.SUPPLY_ESCORT_POINTS) do
	TestCorsecWaypointsLiterals["test_supply_escort_leg_point_" .. name .. "_has_the_truncated_buildout_value"] = function()
		local q = quest(W.SUPPLY_ESCORT)
		local found = occurrences(q, { "escortPoints" }, name)

		lu.assertEquals(#found, 1, W.SUPPLY_ESCORT .. ": occurrences of " .. name)
		lu.assertEquals(W.xzy(found[1].point), { x = c[1], z = c[2], y = c[3] }, W.SUPPLY_ESCORT .. ": " .. name .. " {x, z, y}")
	end
end

-- AC-1 (W-8)
function TestCorsecWaypointsLiterals:test_turoldine_mission_2_escort_fifth_point_is_numbered_5()
	local q = quest(W.TUROLDINE_M2_ESCORT)

	lu.assertEquals(#q.escortPoints, 5, W.TUROLDINE_M2_ESCORT .. ": number of escort points")
	lu.assertEquals(q.escortPoints[5].escortNumber, 5, W.TUROLDINE_M2_ESCORT .. ": escortPoints[5].escortNumber")
	lu.assertEquals(q.escortPoints[5].patrolPointName, "corellia_privateer_tier4_leg_2_escort_5", W.TUROLDINE_M2_ESCORT .. ": escortPoints[5] name")
end

-- AC-2 (W-6)
function TestCorsecWaypointsLiterals:test_kreezo_mission_2_marks_the_four_swg_tie_spawners_in_order()
	local q = quest(W.KREEZO_M2)

	lu.assertEquals(q.shipLocations, W.KREEZO_M2_LOCATIONS, W.KREEZO_M2 .. ": shipLocations (imperial_fighter_five/one/seven/three_spawner, no positional keys)")
end

-- AC-2 (W-6): the invented points are gone
function TestCorsecWaypointsLiterals:test_kreezo_mission_2_has_no_invented_imperial_patrol_point()
	local q = quest(W.KREEZO_M2)

	for i, p in ipairs(q.shipLocations) do
		lu.assertNil(p.patrolPointName:find("^imperial_patrol_"), W.KREEZO_M2 .. ": shipLocations[" .. i .. "] " .. p.patrolPointName .. " is invented")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: the buildout extracts and the SWG fixtures
---------------------------------------------------------------------------------------------

TestCorsecWaypointsExtracts = {}

function TestCorsecWaypointsExtracts:setUp() H.reset() end

local function swgBuildoutLines(zone)
	local text = W.readFile(W.SWG_BUILDOUT .. zone .. ".tab")

	if text == nil then
		lu.skip("the SWG-Source clone is not at " .. W.SWG_GAME)
	end

	return text
end

for _, zone in ipairs(W.EXTRACT_ZONES) do
	-- AC-3
	TestCorsecWaypointsExtracts["test_the_" .. zone .. "_quest_points_extract_is_crlf"] = function()
		local text = W.readFile(W.extractPath(zone))

		lu.assertNotNil(text, zone .. ".quest_points.tab: missing fixture")
		lu.assertTrue(W.count(text, "\n") > 2, zone .. ": has data rows")
		lu.assertEquals(W.count(text, "\r\n"), W.count(text, "\n"), zone .. ": every line ends CRLF, as in SWG-Source")
		lu.assertEquals(W.count(text, "\r"), W.count(text, "\r\n"), zone .. ": no stray CR")
	end

	-- AC-3
	TestCorsecWaypointsExtracts["test_the_" .. zone .. "_quest_points_extract_is_a_byte_cut_of_the_swg_buildout"] = function()
		local text = W.readFile(W.extractPath(zone))

		lu.assertNotNil(text, zone .. ".quest_points.tab: missing fixture")

		local swg = swgBuildoutLines(zone)
		local swgLines, header = {}, {}

		for line in swg:gmatch("[^\n]*\n") do
			swgLines[line] = true
			header[#header + 1] = line

			if #header == 2 then
				break
			end
		end

		for line in swg:gmatch("[^\n]*\n") do
			swgLines[line] = true
		end

		local rows = {}

		for line in text:gmatch("[^\n]*\n") do
			rows[#rows + 1] = line
		end

		lu.assertEquals(rows[1], header[1], zone .. ": row 1 (column names) equals the SWG table")
		lu.assertEquals(rows[2], header[2], zone .. ": row 2 (column types) equals the SWG table")

		for i = 3, #rows do
			lu.assertTrue(swgLines[rows[i]], zone .. ": row " .. i .. " is a byte-identical line of the SWG table")
		end
	end

	-- AC-3: the extract holds exactly the rows the recipe's patterns match in the full table
	TestCorsecWaypointsExtracts["test_the_" .. zone .. "_quest_points_extract_holds_every_row_the_recipe_patterns_match"] = function()
		local text = W.readFile(W.extractPath(zone))

		lu.assertNotNil(text, zone .. ".quest_points.tab: missing fixture")

		local swg = swgBuildoutLines(zone)
		local want = {}
		local navPatterns, spawnerPatterns = {}, {}
		local extract = W.extract(zone)

		for name in pairs(extract.nav) do
			navPatterns[#navPatterns + 1] = "nav_name|4|" .. name .. "|"
		end

		for name in pairs(extract.spawner) do
			spawnerPatterns[#spawnerPatterns + 1] = "strSpawnerName|4|" .. name .. "|"
		end

		local patterns = {}

		for _, p in ipairs(navPatterns) do patterns[#patterns + 1] = p end
		for _, p in ipairs(spawnerPatterns) do patterns[#patterns + 1] = p end

		local skipped, n = 0, 0

		for line in swg:gmatch("[^\n]*\n") do
			n = n + 1

			if n > 2 then
				for _, pattern in ipairs(patterns) do
					if line:find(pattern, 1, true) then
						want[#want + 1] = line
						break
					end
				end
			else
				skipped = skipped + 1
			end
		end

		local have = {}
		n = 0

		for line in text:gmatch("[^\n]*\n") do
			n = n + 1

			if n > 2 then
				have[#have + 1] = line
			end
		end

		lu.assertEquals(#have, #want, zone .. ": data rows in the extract against the rows the patterns select from the full table")
		lu.assertEquals(have, want, zone .. ": the extract rows, in file order")
	end

	-- AC-3: row counts of the Content contract
	TestCorsecWaypointsExtracts["test_the_" .. zone .. "_quest_points_extract_has_the_contract_row_counts"] = function()
		local x = W.extract(zone)
		local want = W.EXTRACTS[zone]

		lu.assertEquals(x.rows, want.rows, zone .. ": data rows")

		local nav, spawner = 0, 0

		for _ in pairs(x.nav) do nav = nav + 1 end
		for _ in pairs(x.spawner) do spawner = spawner + 1 end

		lu.assertEquals(nav, want.nav, zone .. ": distinct nav points")
		lu.assertEquals(spawner, want.spawner, zone .. ": distinct spawners")
		lu.assertEquals(x.navRows + x.spawnerRows, x.rows, zone .. ": every row is a nav point row or a spawner row")
	end

	-- AC-3: exactly the points the quest tables need (names from the SWG tables, never from Core3)
	TestCorsecWaypointsExtracts["test_the_" .. zone .. "_quest_points_extract_holds_exactly_the_points_the_swg_tables_use"] = function()
		local nav, spawner = {}, {}

		for _, q in pairs(GLOBALS) do
			local rec = W.swg(q)

			if rec ~= nil then
				for _, f in ipairs(W.fields(q)) do
					local names, zones = W.swgNames(rec, f.col)

					for i, name in ipairs(names) do
						if zones[i] == zone then
							(f.kind == "spawner" and spawner or nav)[name] = true
						end
					end
				end
			end
		end

		local x = W.extract(zone)
		local haveNav, haveSpawner, wantNav, wantSpawner = {}, {}, {}, {}

		for name in pairs(x.nav) do haveNav[#haveNav + 1] = name end
		for name in pairs(x.spawner) do haveSpawner[#haveSpawner + 1] = name end
		for name in pairs(nav) do wantNav[#wantNav + 1] = name end
		for name in pairs(spawner) do wantSpawner[#wantSpawner + 1] = name end

		table.sort(haveNav)
		table.sort(haveSpawner)
		table.sort(wantNav)
		table.sort(wantSpawner)

		lu.assertEquals(haveNav, wantNav, zone .. ": nav points in the extract against the nav points of the SWG quest tables")
		lu.assertEquals(haveSpawner, wantSpawner, zone .. ": spawners in the extract against the spawners of the SWG quest tables")
	end
end

-- AC-3: 323 rows in all
function TestCorsecWaypointsExtracts:test_the_seven_extracts_hold_323_rows()
	local total = 0

	for _, zone in ipairs(W.EXTRACT_ZONES) do
		total = total + W.extract(zone).rows
	end

	lu.assertEquals(#W.EXTRACT_ZONES, 7, "zones with a quest_points extract")
	lu.assertEquals(total, 323, "data rows in the seven extracts")
end

-- AC-3 (W-7): the point SWG does not have is not extracted
function TestCorsecWaypointsExtracts:test_the_dathomir_extract_has_no_escort_duty_2_row()
	lu.assertNil(W.extract("space_dathomir").nav.corellia_privateer_tier4_escort_duty_2, "space_dathomir: corellia_privateer_tier4_escort_duty_2")
end

for _, rel in ipairs(W.NEW_FIXTURES) do
	-- AC-3
	TestCorsecWaypointsExtracts["test_new_fixture_" .. rel:gsub("/", "_") .. "_is_a_crlf_copy_of_the_swg_table"] = function()
		local path = H.FIXTURES .. "spacequest/" .. rel .. ".tab"
		local text = W.readFile(path)

		lu.assertNotNil(text, "fixtures/spacequest/" .. rel .. ".tab: missing fixture")
		lu.assertEquals(W.count(text, "\r\n"), W.count(text, "\n"), rel .. ": CRLF line endings, as in SWG-Source")

		local swg = W.readFile(W.SWG_SPACEQUEST .. rel .. ".tab")

		if swg == nil then
			lu.skip("the SWG-Source clone is not at " .. W.SWG_GAME)
		end

		lu.assertTrue(text == swg, rel .. ": byte-identical to the SWG-Source table")
	end
end

-- AC-3
function TestCorsecWaypointsExtracts:test_there_are_25_new_fixtures()
	lu.assertEquals(#W.NEW_FIXTURES, 25, "new SWG-Source fixtures")
end

---------------------------------------------------------------------------------------------
-- AC-9: the working-tree files against commit 97a8c4aed7
---------------------------------------------------------------------------------------------

TestCorsecWaypointsFilePins = {}

function TestCorsecWaypointsFilePins:setUp() H.reset() end

local function base(path)
	local text, why = W.baseText(path)

	if text == nil then
		lu.skip("git show " .. W.FEATURE_COMMIT .. " is unavailable: " .. tostring(why))
	end

	return text
end

local HAVOC_NOW_COMMIT = "28bcf23cd8"

local function firstDifference(label, got, want)
	for i = 1, math.max(#got, #want) do
		if got[i] ~= want[i] then
			lu.fail(string.format("%s:%d: expected `%s` but found `%s`", label, i, tostring(want[i]), tostring(got[i])))
		end
	end
end

-- AC-9
function TestCorsecWaypointsFilePins:test_CorsecSquadronScreenplay_differs_from_the_base_only_by_the_data_edits()
	local lines = W.linesOf(base(W.CSP))
	local edits = W.corsecEdits()
	local want, changed, deleted = {}, 0, 0

	for i, line in ipairs(lines) do
		local e = edits[i]

		if e == false then
			deleted = deleted + 1
		elseif e ~= nil then
			changed = changed + 1
			want[#want + 1] = e
		else
			want[#want + 1] = line
		end
	end

	lu.assertEquals(#lines, 2180, "base line count of the CorSec file")
	lu.assertEquals(deleted, 1, "lines the spec deletes (W-7)")
	lu.assertEquals(changed, 27, "lines the spec changes (W-1..W-5, W-8, R; the escort duty keeps four of its five lines)")
	lu.assertEquals(#want, 2179, "expected line count of the CorSec file")

	local text = W.readFile(W.CSP)

	lu.assertNotNil(text, W.CSP)
	lu.assertEquals(W.count(text, "\r"), 0, "CorsecSquadronScreenplay.lua stays LF")

	local got = W.linesOf(text)

	lu.assertEquals(#got, 2179, "CorsecSquadronScreenplay.lua line count")
	firstDifference("CorsecSquadronScreenplay.lua", got, want)
end

-- AC-9
function TestCorsecWaypointsFilePins:test_HavocSquadronScreenplay_differs_from_the_base_only_by_the_four_tie_spawner_lines()
	local lines = W.linesOf(base(W.HSP))
	local want = {}

	for i, line in ipairs(lines) do
		if i == 82 then
			for _, new in ipairs(W.havocReplacement()) do
				want[#want + 1] = new
			end
		elseif i ~= 83 and i ~= 84 then
			want[#want + 1] = line
		end
	end

	lu.assertEquals(#lines, 2306, "base line count of the Havoc file")
	lu.assertEquals(#want, 2307, "expected line count of the Havoc file")

	-- havoc-tier3-quest-name-case (D-6): the "now" side is the waypoints commit itself, read with git show; the working tree
	-- Havoc file is edited again by later features. The claim "the waypoints commit changed only these lines" stays true forever.
	local text = W.baseText(W.HSP, HAVOC_NOW_COMMIT)

	if text == nil then
		lu.skip("git show " .. HAVOC_NOW_COMMIT .. " is unavailable")
	end

	lu.assertEquals(W.count(text, "\r"), 0, "HavocSquadronScreenplay.lua at " .. HAVOC_NOW_COMMIT .. " stays LF")

	local got = W.linesOf(text)

	lu.assertEquals(#got, 2307, "HavocSquadronScreenplay.lua line count")
	firstDifference("HavocSquadronScreenplay.lua", got, want)
end

-- AC-9
function TestCorsecWaypointsFilePins:test_RsfSquadronScreenplay_is_byte_identical_to_the_base_and_lf()
	local text = W.readFile(W.RSP)

	lu.assertNotNil(text, W.RSP)
	lu.assertTrue(text == base(W.RSP), W.RSP .. " differs from " .. W.FEATURE_COMMIT)
	lu.assertEquals(W.count(text, "\r"), 0, "RsfSquadronScreenplay.lua stays LF")
end

local function listLua(dir)
	local rc, out = W.shell("ls " .. dir)

	assert(rc == 0, "ls " .. dir .. ": " .. out)

	local names = {}

	for name in out:gmatch("[^\n]+") do
		if name:match("%.lua$") then
			names[#names + 1] = name
		end
	end

	return names
end

-- AC-9 (D-14): the patrol point files are untouched
for _, name in ipairs(listLua("bin/scripts/ship_mobile/patrol_points")) do
	TestCorsecWaypointsFilePins["test_patrol_point_file_" .. name:gsub("%.lua$", "") .. "_is_byte_identical_to_the_base"] = function()
		local path = W.PP_DIR .. name
		local text = W.readFile(path)

		lu.assertNotNil(text, path)
		lu.assertTrue(text == base(path), path .. " differs from " .. W.FEATURE_COMMIT)
	end
end

-- AC-9, Content contract: no quest type or helper changes
for _, name in ipairs(listLua("bin/scripts/screenplays/space")) do
	-- space-master-mission-quest-type: SpaceDestroyScreenplay is identical to 97a8c4aed7 again (the A-1 hunks are reverted), so no exclusion.
	-- SpaceMasterDestroyScreenplay.lua is new: base() has no such file, so its pin test skips.
	-- smuggler-transition-karrde SC-1: SpacePatrolScreenplay completes a non-PATROL_POINT patrol at its last point (test_smuggler_transition_pins.lua pins that hunk).
	-- smuggler-tier2-shamdon SC-1/SC-2: the escort and recovery attack waves read the player's ship faction (test_smuggler_tier2_pins.lua pins those two hunks).
	if name:match("^Space.*Screenplay%.lua$") and name ~= "SpacePatrolScreenplay.lua" and name ~= "SpaceEscortScreenplay.lua" and name ~= "SpaceRecoveryScreenplay.lua" then
		TestCorsecWaypointsFilePins["test_" .. name:gsub("%.lua$", "") .. "_is_byte_identical_to_the_base"] = function()
			local path = W.SPACE_DIR .. name
			local text = W.readFile(path)

			lu.assertNotNil(text, path)
			lu.assertTrue(text == base(path), path .. " differs from " .. W.FEATURE_COMMIT)
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-10
---------------------------------------------------------------------------------------------

TestCorsecWaypointsGate = {}

-- AC-10
function TestCorsecWaypointsGate:test_the_client_string_gaps_stay_closed()
	lu.assertEquals(D.KNOWN_GAPS, {}, "KNOWN_GAPS")
end
