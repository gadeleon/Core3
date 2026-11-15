-- space-ai-swg-behaviour F1: pilot data conformance against SWG-Source
--   ship_pilot.lua      vs datatables/ship/ship_debug.tab   (I-3, pins the existing port)
--   ship_pilot_type.lua vs datatables/ship/pilottype.tab    (I-4, new file)
-- Spec: .claude/work/space-ai-swg-behaviour/01-spec.md (AC-7)

local lu = require("luaunit")
local H = require("harness")

local PILOT_FILE = H.SCRIPTS .. "managers/space/ship_pilot.lua"
local TYPE_FILE = os.getenv("SPACE_AI_PILOT_TYPE_FILE") or (H.SCRIPTS .. "managers/space/ship_pilot_type.lua") -- env override: validate the test against a scratch reference

-- Core3 columns 4..16 = ship_debug.tab columns 5..17
local DEBUG_COLUMNS = {
	"speed_rotation_factor_min", "speed_rotation_factor_optimal", "speed_rotation_factor_max", "slideDamp",
	"engine_speed", "engine_accel", "engine_decel", "engine_yaw", "engine_yaw_accel",
	"engine_pitch", "engine_pitch_accel", "engine_roll", "engine_roll_accel",
}

-- Known data typo (spec Risks); fixing it later is a one-line change here.
local KNOWN_UNRESOLVED_PILOT_TEMPLATES = {
	anthropology_collector = "light_fighter_light_fighter_tier3",
}

local function loadData(path, global)
	local env = setmetatable({}, { __index = _G })
	local chunk, err = loadfile(path, "t", env)
	lu.assertNotNil(chunk, "expected script " .. path .. " to exist and compile: " .. tostring(err))
	chunk()
	local data = env[global]
	lu.assertIsTable(data, "expected " .. path .. " to define global " .. global)
	return data
end

local function fileText(path)
	local f = io.open(path, "r")
	if not f then return nil end
	local s = f:read("a")
	f:close()
	return s
end

TestSpaceAiPilotType = {}

function TestSpaceAiPilotType:setUp()
	H.reset()
end

-- AC-7 (I-3)
function TestSpaceAiPilotType:test_ship_pilot_has_the_30_rows_of_ship_debug_tab()
	local chassis = loadData(PILOT_FILE, "pilotChassisData")
	local debug = H.fixture("ship/ship_debug.tab")
	local skipped = { fast = true, testing1 = true, testing2 = true, demoer = true }
	local expected = {}

	for _, rec in ipairs(debug.records) do
		if not skipped[rec:get("z")] then expected[#expected + 1] = rec:get("z") end
	end

	local actual = {}
	for _, row in ipairs(chassis) do actual[#actual + 1] = row[1] end

	lu.assertEquals(#expected, 30, "fixture sanity: ship_debug.tab rows used")
	lu.assertEquals(actual, expected, "ship_pilot.lua pilot names vs ship_debug.tab")
end

-- AC-7 (I-3)
function TestSpaceAiPilotType:test_ship_pilot_values_equal_ship_debug_tab_for_every_row()
	local chassis = loadData(PILOT_FILE, "pilotChassisData")
	local debug = H.fixture("ship/ship_debug.tab")
	local byName = {}
	for _, rec in ipairs(debug.records) do byName[rec:get("z")] = rec end

	for _, row in ipairs(chassis) do
		local rec = byName[row[1]]
		lu.assertNotNil(rec, row[1] .. ": row missing from ship_debug.tab")
		lu.assertEquals(row[2], rec:get("strPilotType"), row[1] .. ": pilotType")
		lu.assertEquals(row[3], rec:num("intHoldFire"), row[1] .. ": holdFire")

		for i, column in ipairs(DEBUG_COLUMNS) do
			lu.assertAlmostEquals(row[3 + i], rec:num(column), 1e-6, row[1] .. ": " .. column)
		end
	end
end

-- AC-7 (I-4)
function TestSpaceAiPilotType:test_ship_pilot_type_file_has_a_header_comment_naming_pilottype_tab()
	local text = fileText(TYPE_FILE)
	lu.assertNotNil(text, "expected script managers/space/ship_pilot_type.lua to exist")
	local first = text:match("^[^\n]*")
	lu.assertStrContains(first, "-- Port of SWG datatables/ship/pilottype.tab", "ship_pilot_type.lua header comment")
	lu.assertStrContains(text:sub(1, 400), "fighterChaseMinThrottle", "header names the ported columns")
	lu.assertStrContains(text:sub(1, 400), "fighterChaseSeperationTime", "header keeps SWG's spelling")
end

-- AC-7 (I-4)
function TestSpaceAiPilotType:test_ship_pilot_type_values_equal_pilottype_tab_for_every_row()
	local types = loadData(TYPE_FILE, "pilotTypeData")
	local tab = H.fixture("ship/pilottype.tab")
	local byName = {}
	for _, rec in ipairs(tab.records) do byName[rec:get("name")] = rec end

	for _, row in ipairs(types) do
		local rec = byName[row[1]]
		lu.assertNotNil(rec, tostring(row[1]) .. ": no such row in pilottype.tab")
		lu.assertAlmostEquals(row[2], rec:num("fighterChaseMinThrottle"), 1e-6, row[1] .. ": fighterChaseMinThrottle")
		lu.assertAlmostEquals(row[3], rec:num("fighterChaseSeperationTime"), 1e-6, row[1] .. ": fighterChaseSeperationTime")
	end
end

-- AC-7 (I-4)
function TestSpaceAiPilotType:test_ship_pilot_type_rows_are_the_distinct_pilot_types_plus_default()
	local types = loadData(TYPE_FILE, "pilotTypeData")
	local chassis = loadData(PILOT_FILE, "pilotChassisData")
	local expected, seen = { "default" }, { default = true }

	for _, row in ipairs(chassis) do
		if not seen[row[2]] then seen[row[2]] = true; expected[#expected + 1] = row[2] end
	end

	local actual = {}
	for _, row in ipairs(types) do actual[#actual + 1] = row[1] end

	table.sort(expected)
	table.sort(actual)
	lu.assertEquals(#actual, 31, "ship_pilot_type.lua row count (30 pilot types + default)")
	lu.assertEquals(actual, expected, "ship_pilot_type.lua row set")
end

-- AC-7
function TestSpaceAiPilotType:test_ship_pilot_type_spot_values()
	local types = loadData(TYPE_FILE, "pilotTypeData")
	local byName = {}
	for _, row in ipairs(types) do byName[row[1]] = row end

	local spots = {
		light_fighter_tier5 = { 0.3, 2 }, bomber_tier3 = { 0.4, 3 }, heavy_tier1 = { 0.1, 2 },
		slow_tier4 = { 0.8, 2 }, default = { 0.5, 2 },
	}

	for name, want in pairs(spots) do
		lu.assertNotNil(byName[name], name .. ": row missing")
		lu.assertAlmostEquals(byName[name][2], want[1], 1e-6, name .. ": fighterChaseMinThrottle")
		lu.assertAlmostEquals(byName[name][3], want[2], 1e-6, name .. ": fighterChaseSeperationTime")
	end
end

-- AC-7
function TestSpaceAiPilotType:test_every_ship_mobile_pilot_template_resolves_except_the_known_typo()
	local chassis = loadData(PILOT_FILE, "pilotChassisData")
	local names = {}
	for _, row in ipairs(chassis) do names[row[1]] = true end

	local dir = H.SCRIPTS .. "ship_mobile/ships/"
	local p = io.popen("ls '" .. dir .. "'")
	local unresolved, checked = {}, 0

	for file in p:lines() do
		local ship = file:match("^(.+)%.lua$")
		local text = ship and fileText(dir .. file)
		local template = text and text:match('pilotTemplate%s*=%s*"([^"]*)"')

		if template and template ~= "" then
			checked = checked + 1
			if not names[template] and KNOWN_UNRESOLVED_PILOT_TEMPLATES[ship] ~= template then
				unresolved[#unresolved + 1] = ship .. " -> " .. template
			end
		end
	end
	p:close()

	table.sort(unresolved)
	lu.assertTrue(checked > 100, "scanned ship_mobile/ships pilotTemplate lines: " .. checked)
	lu.assertEquals(unresolved, {}, "ship_mobile ships whose pilotTemplate has no pilotChassisData row")
end

