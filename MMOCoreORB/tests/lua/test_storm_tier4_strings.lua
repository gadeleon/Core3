-- Admiral Kilnstrider: the client-strings ratchet, the fixtures' provenance and the byte copies of SWG-Source.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-1, B-2; Content contract 4; Source inventory 5; FK-2, FK-8; D-18).
--
-- The ratchet counts themselves (67 files) are asserted by the existing ratchet tests; this file pins the new entry, the fixture and the archive choice.
-- The byte-copy checks compare against the research clone and skip when it is not present.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")
local KD = require("space_convo_client_strings_data")

local FILE = D.STF
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
	local f = io.open(GAME .. D.JAVA, "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	f:close()
end

local function linesWithEndings(text)
	local out = {}

	for line in text:gmatch("[^\n]*\n?") do
		if line ~= "" then
			out[#out + 1] = line
		end
	end

	return out
end

TestStormT4Strings = {}

function TestStormT4Strings:setUp() H.reset() end

-- B-2: the ratchet entry
function TestStormT4Strings:test_fixture_counts_has_kilnstriders_file_with_176_ids_as_the_67th_entry()
	local n = 0

	for _ in pairs(KD.FIXTURE_COUNTS) do
		n = n + 1
	end

	lu.assertEquals(KD.FIXTURE_COUNTS[FILE], 176, "FIXTURE_COUNTS[" .. FILE .. "]")
	lu.assertEquals(n, 79, "FIXTURE_COUNTS entries") -- 68 since vortex-tier1-kiizete, 69 since vortex-tier2-vrovel, 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop, 75 since crimson-phoenix-tier4-ufwol, 78 since battlefield-entry-stations
end

-- B-2: nothing is allowed to be unresolved
function TestStormT4Strings:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestStormT4Strings:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- storm-tier4-kilnstrider: Admiral Kilnstrider's conversation/tatooine_imperial_tier4 (176 ids, served from patch_12_00.tre) is new and fully resolved (the 67th file); KNOWN_GAPS stays {}.", false)
end

-- B-2: the fixture is 176 sorted unique lines, including do_not_edit and s_0
function TestStormT4Strings:test_the_sids_fixture_has_176_sorted_unique_lines()
	local lines = {}

	for line in readFile(CS.FIXTURE_DIR .. FILE .. ".sids"):gmatch("[^\n]+") do
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 176, "lines in the fixture")

	for i = 2, #lines do
		lu.assertTrue(lines[i - 1] < lines[i], "line " .. i .. " (" .. lines[i] .. ") sorts after " .. lines[i - 1] .. " (sorted, unique)")
	end

	lu.assertEquals(lines[1], "do_not_edit", "first id")
	lu.assertTrue(CS.sids(FILE)["s_0"], "s_0 is in the fixture")
end

-- B-2, FK-2: the generator picks patch_12_00.tre for this file (the first holder in the TreFiles order)
function TestStormT4Strings:test_the_generator_serves_the_table_from_patch_12_00()
	requireTre()

	local code = 'import sys; sys.dont_write_bytecode = True; sys.path.insert(0, "tests/lua/tools"); import gen_client_sids as g; '
		.. 'a = g.Archives("/tre"); t = b"string/en/conversation/tatooine_imperial_tier4.stf"; '
		.. 'print([n for n in g.tre_order() if a.open(n) is not None and t in a.open(n).entries][0])'
	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -B -c '" .. code .. "'")

	lu.assertEquals(rc, 0, "python failed: " .. out)
	lu.assertEquals(out:gsub("%s+", ""), "patch_12_00.tre", "first archive of the TreFiles order that holds the Kilnstrider table")
end

-- B-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestStormT4Strings:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("python3 -B tests/lua/tools/gen_client_sids.py --check " .. FILE)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. FILE .. ": " .. out)
end

-- B-2, R-8: no bytecode left behind by the generator (a stray __pycache__ breaks five tests)
function TestStormT4Strings:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end

-- Content contract 4: the java script is a byte copy of the research clone
function TestStormT4Strings:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. D.JAVA, "rb") == readFile(GAME .. D.JAVA, "rb"), "fixtures/" .. D.JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: the java script is the file the spec names (md5 of the copy)
function TestStormT4Strings:test_the_java_fixture_is_the_5021_line_script_of_the_spec()
	local text = readFile(H.FIXTURES .. D.JAVA, "rb")
	local lines = 0

	for _ in text:gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 5020 and lines <= 5022, "lines in tatooine_imperial_tier4.java: " .. lines)

	local rc, out = shell("md5sum " .. H.FIXTURES .. D.JAVA)

	lu.assertEquals(rc, 0, "md5sum failed: " .. out)
	lu.assertEquals(out:match("^(%x+)"), "426a15fdbd9aa377b1c8309cbc1e2bcf", "md5 of the J fixture (the spec's J)")
end

-- Content contract 4: the NPCS excerpt is header rows 1-2 plus row 85 of the clone (CRLF kept)
function TestStormT4Strings:test_the_npc_spawner_excerpt_is_the_header_and_row_85_of_the_clone()
	requireClone()

	local clone = linesWithEndings(readFile(GAME .. "datatables/space_content/npc_spawners.tab", "rb"))
	local excerpt = linesWithEndings(readFile(H.FIXTURES .. "space_content/npc_spawners.storm_tier4_kilnstrider.tab", "rb"))

	lu.assertEquals(excerpt, { clone[1], clone[2], clone[85] }, "excerpt lines (CRLF kept)")
end

-- Content contract 4: the buildout excerpt is header rows 1-2 plus rows 158, 161 and 163 of the clone (CRLF kept)
function TestStormT4Strings:test_the_buildout_excerpt_is_the_header_and_rows_158_161_163_of_the_clone()
	requireClone()

	local clone = linesWithEndings(readFile(GAME .. "datatables/buildout/endor/endor_6_3_ws.tab", "rb"))
	local excerpt = linesWithEndings(readFile(H.FIXTURES .. "buildout/endor/endor_6_3_ws.storm_tier4_kilnstrider.tab", "rb"))

	lu.assertEquals(excerpt, { clone[1], clone[2], clone[158], clone[161], clone[163] }, "excerpt lines (CRLF kept)")
end

-- Content contract 4: the excerpts exist (also without the clone) and carry the Kilnstrider rows
function TestStormT4Strings:test_the_excerpts_exist_without_the_clone()
	lu.assertStrContains(readFile(H.FIXTURES .. "space_content/npc_spawners.storm_tier4_kilnstrider.tab", "rb"), "8466084\t", false)
	lu.assertStrContains(readFile(H.FIXTURES .. "buildout/endor/endor_6_3_ws.storm_tier4_kilnstrider.tab", "rb"), "9925367\t9925364\tobject/cell/cell.iff\t3\t", false)
end
