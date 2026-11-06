-- Lt. Colonel Barlow: the client-strings ratchet and the fixture's provenance.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-4; Content contract 4; FB-1, FB-2; D-10).
--
-- The ratchet counts themselves (59 files since inquisition-tier4-jace-yiaso) are asserted by the five existing ratchet tests; this file pins the new entry, the fixture and the archive choice.

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")
local CS = require("harness.client_strings")
local KD = require("space_convo_client_strings_data")

B.load()

local FILE = "conversation/naboo_imperial_tier3_barlow"

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
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

TestBarlowStrings = {}

function TestBarlowStrings:setUp() H.reset() end

-- AC-4: the ratchet entry
function TestBarlowStrings:test_fixture_counts_has_barlows_file_with_172_ids_and_60_entries_in_all()
	local n = 0

	for _ in pairs(KD.FIXTURE_COUNTS) do
		n = n + 1
	end

	lu.assertEquals(KD.FIXTURE_COUNTS[FILE], 172, "FIXTURE_COUNTS[" .. FILE .. "]")
	lu.assertEquals(n, 60, "FIXTURE_COUNTS entries") -- 60 since storm-tier1-akal-colzet
end

-- AC-4: nothing is allowed to be unresolved
function TestBarlowStrings:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- AC-4: the header line of the data file
function TestBarlowStrings:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- inquisition-tier3-barlow: Lt. Colonel Barlow's conversation/naboo_imperial_tier3_barlow (172 ids, served from patch_12_00.tre) is new and fully resolved; KNOWN_GAPS stays {}.", false)
end

-- AC-4: the fixture is 172 sorted unique lines, including do_not_edit and s_0
function TestBarlowStrings:test_the_sids_fixture_has_172_sorted_unique_lines()
	local lines = {}

	for line in readFile(CS.FIXTURE_DIR .. FILE .. ".sids"):gmatch("[^\n]+") do
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 172, "lines in the fixture")

	for i = 2, #lines do
		lu.assertTrue(lines[i - 1] < lines[i], "line " .. i .. " (" .. lines[i] .. ") sorts after " .. lines[i - 1] .. " (sorted, unique)")
	end

	lu.assertEquals(lines[1], "do_not_edit", "first id")
	lu.assertTrue(CS.sids(FILE)["s_0"], "s_0 is in the fixture")
end

-- AC-4: the J3B fixture is the byte copy of the SWG-Source file when the research tree is present
function TestBarlowStrings:test_the_java_fixture_is_a_byte_copy_of_swg_source()
	local source = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/script/conversation/naboo_imperial_tier3_barlow.java"
	local f = io.open(source, "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	local original = f:read("a")

	f:close()
	lu.assertEquals(readFile(B.J3B_FILE) == original, true, "fixtures/script/conversation/naboo_imperial_tier3_barlow.java differs from the SWG-Source file")
end

-- AC-4, FB-1, D-10: the generator picks patch_12_00.tre for this file (the first holder in the TreFiles order)
function TestBarlowStrings:test_the_generator_serves_the_barlow_table_from_patch_12_00()
	requireTre()

	local code = 'import sys; sys.dont_write_bytecode = True; sys.path.insert(0, "tests/lua/tools"); import gen_client_sids as g; '
		.. 'a = g.Archives("/tre"); t = b"string/en/conversation/naboo_imperial_tier3_barlow.stf"; '
		.. 'print([n for n in g.tre_order() if a.open(n) is not None and t in a.open(n).entries][0])'
	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I -c '" .. code .. "'")

	lu.assertEquals(rc, 0, "python failed: " .. out)
	lu.assertEquals(out:gsub("%s+", ""), "patch_12_00.tre", "first archive of the TreFiles order that holds the Barlow table")
end

-- AC-4: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestBarlowStrings:test_the_generator_check_passes_for_the_barlow_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. FILE)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. FILE .. ": " .. out)
end

-- AC-4: no bytecode left behind by the checks
function TestBarlowStrings:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end

return nil
