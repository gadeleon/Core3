-- Ja'ce Yiaso: the client-strings ratchet, the fixtures' provenance and the byte copies of SWG-Source.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-5, AC-2; Content contract 5; FJ-2; D-7).
--
-- The ratchet counts themselves (59 files) are asserted by the existing ratchet tests; this file pins the new entry, the fixture and the archive choice.
-- The byte-copy checks compare against the research clone and skip when it is not present.

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")
local KD = require("space_convo_client_strings_data")

J4.load()

local FILE = "conversation/naboo_imperial_tier4"
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function readFile(path, mode)
	local f = assert(io.open(path, mode or "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function requireTre()
	local f = io.open("/tre/patch_12_00.tre", "rb")

	if f == nil then
		lu.skip("/tre/patch_12_00.tre is not readable: the archive checks need the client files")
	end

	f:close()
end

local function requireClone()
	local f = io.open(GAME .. "script/conversation/naboo_imperial_tier4.java", "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	f:close()
end

TestInquisitionT4Strings = {}

function TestInquisitionT4Strings:setUp() H.reset() end

-- AC-5: the ratchet entry
function TestInquisitionT4Strings:test_fixture_counts_has_ja_ces_file_with_279_ids_as_the_59th_entry()
	local n = 0

	for _ in pairs(KD.FIXTURE_COUNTS) do
		n = n + 1
	end

	lu.assertEquals(KD.FIXTURE_COUNTS[FILE], 279, "FIXTURE_COUNTS[" .. FILE .. "]")
	lu.assertEquals(n, 73, "FIXTURE_COUNTS entries") -- 60 since storm-tier1-akal-colzet, 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen, 66 since storm-tier3-denner, 67 since storm-tier4-kilnstrider, 68 since vortex-tier1-kiizete, 69 since vortex-tier2-vrovel, 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo
end

-- AC-5: nothing is allowed to be unresolved
function TestInquisitionT4Strings:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 5: the header line of the data file
function TestInquisitionT4Strings:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- inquisition-tier4-jace-yiaso: Grand Inquisitor Ja'ce Yiaso's conversation/naboo_imperial_tier4 (279 ids, served from patch_12_00.tre) is new and fully resolved; KNOWN_GAPS stays {}.", false)
end

-- AC-5: the fixture is 279 sorted unique lines, including do_not_edit and s_0
function TestInquisitionT4Strings:test_the_sids_fixture_has_279_sorted_unique_lines()
	local lines = {}

	for line in readFile(CS.FIXTURE_DIR .. FILE .. ".sids"):gmatch("[^\n]+") do
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 279, "lines in the fixture")

	for i = 2, #lines do
		lu.assertTrue(lines[i - 1] < lines[i], "line " .. i .. " (" .. lines[i] .. ") sorts after " .. lines[i - 1] .. " (sorted, unique)")
	end

	lu.assertEquals(lines[1], "do_not_edit", "first id")
	lu.assertTrue(CS.sids(FILE)["s_0"], "s_0 is in the fixture")
end

-- AC-5, FJ-2: the generator picks patch_12_00.tre for this file (the first holder in the TreFiles order)
function TestInquisitionT4Strings:test_the_generator_serves_the_table_from_patch_12_00()
	requireTre()

	local code = 'import sys; sys.dont_write_bytecode = True; sys.path.insert(0, "tests/lua/tools"); import gen_client_sids as g; '
		.. 'a = g.Archives("/tre"); t = b"string/en/conversation/naboo_imperial_tier4.stf"; '
		.. 'print([n for n in g.tre_order() if a.open(n) is not None and t in a.open(n).entries][0])'
	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I -c '" .. code .. "'")

	lu.assertEquals(rc, 0, "python failed: " .. out)
	lu.assertEquals(out:gsub("%s+", ""), "patch_12_00.tre", "first archive of the TreFiles order that holds the Ja'ce table")
end

-- AC-5: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestInquisitionT4Strings:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. FILE)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. FILE .. ": " .. out)
end

-- AC-5: no bytecode left behind by the checks
function TestInquisitionT4Strings:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end

-- AC-2, Content contract 5: the 20 quest tables, the cargo table and the java script are byte copies of the research clone
function TestInquisitionT4Strings:test_the_twenty_tab_fixtures_the_cargo_table_and_the_java_script_are_byte_copies_of_swg_source()
	requireClone()

	for _, global in ipairs(J4.GLOBALS) do
		local id = J4.IDENTITY[global]
		local rel = "spacequest/" .. id.type .. "/" .. id.name .. ".tab"

		lu.assertTrue(readFile(H.FIXTURES .. rel, "rb") == readFile(GAME .. "datatables/" .. rel, "rb"), "fixtures/" .. rel .. " differs from the SWG-Source file")
	end

	local cargo = "spacequest/inspect_cargo/glowing_crystals.tab"

	lu.assertTrue(readFile(H.FIXTURES .. cargo, "rb") == readFile(GAME .. "datatables/" .. cargo, "rb"), "fixtures/" .. cargo .. " differs from the SWG-Source file")

	local java = "script/conversation/naboo_imperial_tier4.java"

	lu.assertTrue(readFile(H.FIXTURES .. java, "rb") == readFile(GAME .. java, "rb"), "fixtures/" .. java .. " differs from the SWG-Source file")
end

-- AC-2: the 20 fixtures exist (also without the clone)
function TestInquisitionT4Strings:test_the_twenty_tab_fixtures_exist_and_parse()
	for _, global in ipairs(J4.GLOBALS) do
		local rec = J4.fixtureOf(global)

		lu.assertEquals(rec:get("questZone"), "space_dathomir", global .. ": questZone of the fixture")
	end

	lu.assertEquals(#J4.GLOBALS, 20, "fixtures")
end

-- AC-2: the buildout excerpt is the two header rows plus 62 rows of the clone, each present in space_dathomir.tab
function TestInquisitionT4Strings:test_the_buildout_excerpt_rows_are_rows_of_the_clone()
	requireClone()

	local clone = {}

	for line in readFile(GAME .. "datatables/space_zones/buildout/space_dathomir.tab", "rb"):gmatch("[^\n]*\n?") do
		clone[#clone + 1] = line
	end

	local set = {}

	for _, l in ipairs(clone) do
		set[l] = true
	end

	local excerpt = {}

	for line in readFile(H.FIXTURES .. "space_zones/buildout/space_dathomir.inquisition_tier4_points.tab", "rb"):gmatch("[^\n]*\n?") do
		if line ~= "" then
			excerpt[#excerpt + 1] = line
		end
	end

	lu.assertEquals(#excerpt, 64, "lines of the excerpt (2 header rows and 62 data rows)")
	lu.assertEquals(excerpt[1], clone[1], "header row 1")
	lu.assertEquals(excerpt[2], clone[2], "header row 2")

	for i = 3, #excerpt do
		lu.assertTrue(set[excerpt[i]] == true, "excerpt line " .. i .. " is not a line of the clone")
	end
end

-- AC-2: the space_mobile excerpt is header rows 1-2 plus row 436
function TestInquisitionT4Strings:test_the_space_mobile_excerpt_is_the_header_and_row_436_of_the_clone()
	requireClone()

	local clone = {}

	for line in readFile(GAME .. "datatables/space_mobile/space_mobile.tab", "rb"):gmatch("[^\n]*\n?") do
		clone[#clone + 1] = line
	end

	local excerpt = {}

	for line in readFile(H.FIXTURES .. "space_mobile/space_mobile.inquisition_tier4_inspect.tab", "rb"):gmatch("[^\n]*\n?") do
		if line ~= "" then
			excerpt[#excerpt + 1] = line
		end
	end

	lu.assertEquals(excerpt, { clone[1], clone[2], clone[436] }, "excerpt lines (CRLF kept)")
end
