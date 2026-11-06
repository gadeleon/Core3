-- Client string ids of the space conversations: fixtures, helper, generator, ratchet, completeness.
-- Spec: .claude/work/space-convo-client-strings/01-spec.md (AC-1 .. AC-3, AC-8, AC-9; invariants I-1 .. I-3, I-5).
--
-- The fixtures fixtures/string/en/<file>.sids are generated read-only from /tre by tools/gen_client_sids.py; this
-- file reads only the committed fixtures (the generator test below skips when /tre or python3 is absent).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local D = require("space_convo_client_strings_data")

local function contains(str, sub, msg)
	lu.assertTrue(str:find(sub, 1, true) ~= nil, msg .. ": expected to contain '" .. sub .. "' in: " .. str)
end

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)

	return out
end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	local rc = tonumber(out:match("rc=(%d+)%s*$"))

	return rc, (out:gsub("rc=%d+%s*$", ""))
end

local function readLines(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local out = {}

	for line in f:lines() do
		out[#out + 1] = line
	end

	f:close()

	return out
end

local function listDiff(actual, expected)
	local a, e = {}, {}

	for _, v in ipairs(actual) do a[v] = true end
	for _, v in ipairs(expected) do e[v] = true end

	local extra, missing = {}, {}

	for _, v in ipairs(actual) do
		if not e[v] then extra[#extra + 1] = v end
	end

	for _, v in ipairs(expected) do
		if not a[v] then missing[#missing + 1] = v end
	end

	return extra, missing
end

---------------------------------------------------------------------------------------------
-- AC-1: fixtures
---------------------------------------------------------------------------------------------

TestClientStringFixtures = {}

-- AC-1; AC-1 of space-convo-client-strings-arkon (01-spec.md, D-10, Appendix C): Arkon's skill-name replies (@skl_n) are gone, so skl_n.sids and its entry are deleted (44 -> 43)
-- black-epsilon-tier1-hakassha: Hakassha's conversation/corellia_imperial_trainer_1 is the 44th file (red until her template and handler exist)
-- black-epsilon-tier2-prisk: Prisk's conversation/corellia_imperial_trainer_2 is the 45th file (red until his template and handler exist)
-- black-epsilon-tier3-haymir: Haymir's conversation/corellia_imperial_tier3 is the 46th file (red until his template and handler exist)
-- black-epsilon-tier4-nin-gursawe: Nin Gursawe's conversation/corellia_imperial_tier4 is the 47th file
-- space-master-trainer-imperial: Declann's conversation/imperial_master_trainer is the 48th file
-- space-master-trainer-rebel: Burke's conversation/rebel_master_trainer is the 49th file (red until his template and handler exist)
-- smuggler-tier1-dravis: Dravis' conversation/tatooine_privateer_trainer_1 is the 50th file (red until his template and handler exist)
-- smuggler-transition-karrde: Talon Karrde's conversation/tatooine_privateer_trainer_2 is the 51st file (red until his template and handler exist)
-- smuggler-tier2-shamdon: Shamdon Kree's conversation/tatooine_privateer_trainer_shamdon is the 52nd file; smuggler-tier3-beissa: Beissa's conversation/tatooine_privateer_tier3 is the 53rd; smuggler-tier4-nirame: Nirame Sakute's conversation/tatooine_privateer_tier4 is the 54th; inquisition-tier1-barn-sinkko: Barn Sinkko's conversation/naboo_imperial_trainer_1 is the 55th; inquisition-tier2-fa-zoll: Fa'Zoll's conversation/naboo_imperial_trainer_2 is the 56th; inquisition-tier3-vrke: Vrke's conversation/naboo_imperial_tier3 is the 57th; inquisition-tier3-barlow: Barlow's conversation/naboo_imperial_tier3_barlow is the 58th; inquisition-tier4-jace-yiaso: Ja'ce Yiaso's conversation/naboo_imperial_tier4 is the 59th; storm-tier1-akal-colzet: Akal Colzet's conversation/tatooine_imperial_trainer_1 is the 60th; storm-tier2-oberhaur: Oberhaur's conversation/tatooine_imperial_trainer_2 is the 61st (red until his template and handler exist); storm-tier2-nym-technicians: the Nym technicians' conversation/nym_technician_1, _2 and _3 are the 62nd to 64th (red until their templates and handlers exist); storm-tier2-alozen: Alozen's conversation/tatooine_imperial_trainer_2b is the 65th (red until her template and handler exist)
function TestClientStringFixtures:test_the_space_conversation_sources_reference_exactly_the_65_files_of_appendix_a()
	local referenced = CS.referencedFiles(CS.spaceConversationSources())

	lu.assertEquals(#sortedKeys(D.FIXTURE_COUNTS), 65, "FIXTURE_COUNTS entries") -- 61 since storm-tier2-oberhaur, 64 since storm-tier2-nym-technicians, 65 since storm-tier2-alozen
	lu.assertNil(D.FIXTURE_COUNTS["skl_n"], "FIXTURE_COUNTS entry of skl_n")
	lu.assertNil(io.open(CS.FIXTURE_DIR .. "skl_n.sids", "r"), "fixture skl_n.sids must be deleted")
	lu.assertEquals(referenced, sortedKeys(D.FIXTURE_COUNTS), "string files referenced by the space conversation sources")
end

-- AC-1
function TestClientStringFixtures:test_every_referenced_file_has_a_sorted_unique_non_empty_fixture_with_the_expected_count()
	for _, file in ipairs(sortedKeys(D.FIXTURE_COUNTS)) do
		local path = CS.FIXTURE_DIR .. file .. ".sids"
		local f = io.open(path, "r")

		lu.assertNotNil(f, file .. ": missing fixture " .. path .. " (run tools/gen_client_sids.py)")

		f:close()

		local lines = readLines(path)

		lu.assertEquals(#lines, D.FIXTURE_COUNTS[file], file .. ": id count")

		for i, line in ipairs(lines) do
			lu.assertNotEquals(line, "", file .. ": empty line " .. i)

			if i > 1 then
				lu.assertTrue(lines[i - 1] < line, file .. ": line " .. i .. " ('" .. line .. "') is not byte-sorted/unique after '" .. lines[i - 1] .. "'")
			end
		end
	end
end

-- AC-1 (I-1)
function TestClientStringFixtures:test_every_literal_in_the_space_conversation_sources_has_a_fixture()
	local missing = {}

	for _, file in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		if CS.sids(file) == nil then
			missing[#missing + 1] = file
		end
	end

	lu.assertEquals(missing, {}, "referenced string files without a .sids fixture")
end

---------------------------------------------------------------------------------------------
-- AC-2: generator (gate command, outside run.sh's dependencies)
---------------------------------------------------------------------------------------------

TestClientStringGenerator = {}

local GEN = "PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py"

local function generatorUsable()
	if not H.fileExists("/tre/patch_12_00.tre") then
		return false, "/tre/patch_12_00.tre is absent"
	end

	local rc = shell("command -v python3 >/dev/null")

	if rc ~= 0 then
		return false, "python3 is not on PATH"
	end

	return true
end

-- AC-2
function TestClientStringGenerator:test_the_generator_is_committed_with_a_read_only_header()
	lu.assertTrue(H.fileExists("tests/lua/tools/gen_client_sids.py"), "tests/lua/tools/gen_client_sids.py")

	local text = assert(io.open("tests/lua/tools/gen_client_sids.py", "r")):read("a")

	contains(text, "--check", "documents --check")
	contains(text, "rb", "opens TRE archives in binary read mode")
	contains(text:lower(), "read-only", "states the read-only guarantee")
	contains(text:lower(), "never edit", "states regenerate-never-edit")
end

-- AC-2
function TestClientStringGenerator:test_check_passes_against_the_committed_fixtures()
	local ok, why = generatorUsable()

	if not ok then
		lu.skip("generator check needs /tre and python3: " .. why)
	end

	local rc, out = shell(GEN .. " --check")

	lu.assertEquals(rc, 0, "gen_client_sids.py --check exit code; output: " .. out)
end

-- AC-2
function TestClientStringGenerator:test_check_fails_and_names_a_fixture_with_a_deleted_line_in_a_scratch_copy()
	local ok, why = generatorUsable()

	if not ok then
		lu.skip("generator check needs /tre and python3: " .. why)
	end

	local tmp = os.tmpname()

	os.remove(tmp)
	assert(shell("mkdir -p " .. tmp) == 0)

	local function cleanup() shell("rm -rf " .. tmp) end

	local copied = shell("cp -r tests/lua/fixtures/string/en " .. tmp .. "/en")

	if copied ~= 0 then
		cleanup()
		lu.fail("could not copy the fixture directory to " .. tmp)
	end

	local victim = tmp .. "/en/conversation/naboo_privateer_trainer_1.sids"
	local lines = readLines(victim)
	local f = assert(io.open(victim, "w"))

	for i = 2, #lines do
		f:write(lines[i], "\n")
	end

	f:close()

	local rc, out = shell(GEN .. " --check --fixture-dir " .. tmp .. "/en")

	cleanup()

	lu.assertEquals(rc, 1, "--check exit code on a scratch copy with a deleted line; output: " .. out)
	contains(out, "conversation/naboo_privateer_trainer_1", "--check names the differing fixture")
	contains(out, "DIFFERS", "--check says it differs")
end

-- AC-2
function TestClientStringGenerator:test_a_zero_length_newest_entry_is_an_error_naming_the_archive()
	local ok, why = generatorUsable()

	if not ok then
		lu.skip("generator check needs /tre and python3: " .. why)
	end

	local rc, out = shell(GEN .. " --check spacequest/destroy/naboo_privateer_tier3_2b")

	lu.assertNotEquals(rc, 0, "exit code for a deleted (zero-length) string file; output: " .. out)
	contains(out, "patch_11_02.tre", "names the archive that holds the zero-length entry")
end

-- AC-2 (review R-4): an archive of the load order missing from --tre-dir is an error in write and check mode, and writes nothing
function TestClientStringGenerator:test_a_missing_archive_in_the_load_order_is_an_error_in_write_and_check_mode_and_writes_nothing()
	local ok, why = generatorUsable()

	if not ok then
		lu.skip("generator check needs /tre and python3: " .. why)
	end

	local tmp = os.tmpname()

	os.remove(tmp)
	assert(shell("mkdir -p " .. tmp .. "/tre " .. tmp .. "/en") == 0)

	-- every archive but patch_13_00.tre (the newest copy of conversation/station_rori), linked read-only
	assert(shell("for f in /tre/*.tre; do [ \"$(basename $f)\" = patch_13_00.tre ] || ln -s $f " .. tmp .. "/tre/; done") == 0)

	local wrc, wout = shell(GEN .. " --tre-dir " .. tmp .. "/tre --fixture-dir " .. tmp .. "/en conversation/station_rori")
	local _, written = shell("ls -A " .. tmp .. "/en | wc -l")
	local crc, cout = shell(GEN .. " --check --tre-dir " .. tmp .. "/tre --fixture-dir " .. tmp .. "/en conversation/station_rori")

	shell("rm -rf " .. tmp)

	lu.assertNotEquals(wrc, 0, "write mode exit code with a missing archive; output: " .. wout)
	contains(wout, "patch_13_00.tre", "write mode names the missing archive")
	lu.assertEquals(tonumber(written), 0, "write mode must not write a (stale) fixture")
	lu.assertNotEquals(crc, 0, "--check exit code with a missing archive; output: " .. cout)
	contains(cout, "patch_13_00.tre", "--check names the missing archive")
end

-- AC-2 (review): running the generator tests leaves no __pycache__ behind
function TestClientStringGenerator:test_the_generator_leaves_no_pycache_in_the_tools_directory()
	lu.assertFalse(H.fileExists("tests/lua/tools/__pycache__"), "tests/lua/tools/__pycache__ must not exist (delete it; the tool sets sys.dont_write_bytecode)")
end

---------------------------------------------------------------------------------------------
-- AC-3: helper module
---------------------------------------------------------------------------------------------

TestClientStringsHelper = {}

local SAMPLE = { "./tests/lua/fixtures/client_strings/sample_convo.lua" }

-- AC-3
function TestClientStringsHelper:test_literals_lists_each_at_literal_with_file_id_path_and_line()
	local lits = CS.literals(SAMPLE)

	lu.assertEquals(#lits, 3, "literals found in the sample (the dynamic line has none)")
	lu.assertEquals({ lits[1].file, lits[1].id, lits[1].line }, { "conversation/corellia_privateer_trainer", "s_e107077e", 4 }, "first literal")
	lu.assertEquals({ lits[2].file, lits[2].id, lits[2].line }, { "conversation/corellia_privateer_trainer", "s_108", 5 }, "second literal")
	lu.assertEquals({ lits[3].file, lits[3].id, lits[3].line }, { "conversation/no_such_file", "s_1", 6 }, "third literal")
	lu.assertEquals(lits[1].path, SAMPLE[1], "path as passed")
end

-- AC-3
function TestClientStringsHelper:test_unresolved_returns_the_nge_id_and_the_unknown_file_but_not_the_client_id()
	lu.assertEquals(CS.unresolved(SAMPLE), { "conversation/corellia_privateer_trainer:s_108", "conversation/no_such_file:s_1" }, "unresolved ids")
end

-- AC-3
function TestClientStringsHelper:test_unresolved_by_file_groups_the_same_set()
	lu.assertEquals(CS.unresolvedByFile(SAMPLE), {
		["conversation/corellia_privateer_trainer"] = { "s_108" },
		["conversation/no_such_file"] = { "s_1" },
	}, "unresolvedByFile")
end

-- AC-3
function TestClientStringsHelper:test_dynamic_ids_returns_the_line_that_builds_an_id()
	lu.assertEquals(CS.dynamicIds(SAMPLE), { SAMPLE[1] .. ":7" }, "dynamicIds")
end

-- AC-3
function TestClientStringsHelper:test_referenced_files_is_sorted_and_unique()
	lu.assertEquals(CS.referencedFiles(SAMPLE), { "conversation/corellia_privateer_trainer", "conversation/no_such_file" }, "referencedFiles")
end

-- AC-3
function TestClientStringsHelper:test_sids_of_an_unknown_file_is_nil_with_a_message_and_never_errors()
	local set, err = CS.sids("conversation/no_such_file")

	lu.assertNil(set, "sids of a missing fixture")
	contains(err, "missing fixture", "message")
	contains(err, "conversation/no_such_file", "message names the file")
end

-- AC-3
function TestClientStringsHelper:test_sids_of_a_known_file_is_a_set_of_its_ids()
	local set = CS.sids("conversation/corellia_privateer_trainer")

	lu.assertNotNil(set, "fixture for conversation/corellia_privateer_trainer")
	lu.assertTrue(set["s_e107077e"], "s_e107077e is a pre-NGE id")
	lu.assertNil(set["s_108"], "s_108 is an NGE id")
end

-- AC-3
function TestClientStringsHelper:test_a_missing_source_path_is_an_error_naming_it()
	local ok, err = pcall(CS.literals, { "mobile/conversations/space/no_such_convo.lua" })

	lu.assertFalse(ok, "literals of a missing path must error")
	contains(tostring(err), "no_such_convo.lua", "error names the path")
end

-- AC-3
function TestClientStringsHelper:test_transcript_unresolved_checks_screen_and_option_texts_and_ignores_plain_text()
	local transcript = {
		{ id = "a", text = "@conversation/corellia_privateer_trainer:s_e0dfe067", options = {
			{ text = "@conversation/corellia_privateer_trainer:s_108", link = "b" },
			{ text = "plain reply", link = "c" },
		} },
		{ id = "b", text = "Plain NPC line", options = {
			{ text = "@conversation/no_such_file:s_1", link = "d" },
			{ text = "@conversation/corellia_privateer_trainer:s_108", link = "e" },
		} },
	}

	lu.assertEquals(CS.transcriptUnresolved(transcript), { "conversation/corellia_privateer_trainer:s_108", "conversation/no_such_file:s_1" }, "transcriptUnresolved")
	lu.assertEquals(CS.transcriptUnresolved({}), {}, "empty transcript")
end

---------------------------------------------------------------------------------------------
-- AC-8, AC-9: ratchet and completeness over every space conversation source
---------------------------------------------------------------------------------------------

TestClientStringRatchet = {}

-- AC-8 (the ratchet data itself, Appendix B); AC-1 of space-convo-client-strings-dinge (01-spec.md): Dinge's file left the list (470 -> 446);
-- AC-1 of space-convo-client-strings-kaydine (01-spec.md): Kaydine's file left it too (446 -> 381);
-- AC-1 of space-convo-client-strings-dulios (01-spec.md, Appendix C): Dulios' file left it (381 -> 305), two files remain;
-- AC-1 of space-convo-client-strings-arkon (01-spec.md, Appendix C): Arkon's file left it too (305 -> 211), one file remains (Imler's, F6);
-- AC-1 of space-convo-client-strings-imler-a (01-spec.md, Appendix C): Imler's entry lost its 15 gate, duty-briefing and training ids (211 -> 196); the 196 left are F6b's
-- space-convo-client-strings-imler-b (F6b, 01-spec.md Appendix C, AC-1): Imler's file left the ratchet too (196 -> 0), so KNOWN_GAPS is empty. Renamed from test_known_gaps_hold_the_1_file_and_196_ids_left_after_imler_a.
function TestClientStringRatchet:test_known_gaps_is_empty_after_imler_b()
	lu.assertEquals(D.KNOWN_GAPS, {}, "KNOWN_GAPS")
	lu.assertEquals(sortedKeys(D.KNOWN_GAPS), {}, "KNOWN_GAPS files")
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "live scan: unresolved ids of all space conversation sources")
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_tier4"], "Imler's file is fixed and must not be listed")
	lu.assertNil(D.KNOWN_GAPS["conversation/corellia_rebel_tier4"], "Arkon's file is fixed and must not be listed")
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_trainer_1"], "Dinge's file is fixed and must not be listed")
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_trainer_2"], "Kaydine's file is fixed and must not be listed")
	lu.assertNil(D.KNOWN_GAPS["conversation/naboo_privateer_tier3"], "Dulios' file is fixed and must not be listed")
end

-- AC-8 (I-3): new gaps fail, and fixed gaps must be removed from the list
function TestClientStringRatchet:test_the_unresolved_ids_equal_known_gaps_exactly()
	local actual = CS.unresolvedByFile(CS.spaceConversationSources())
	local problems = {}

	for _, file in ipairs(sortedKeys(actual)) do
		local extra = listDiff(actual[file], D.KNOWN_GAPS[file] or {})

		if #extra > 0 then
			problems[#problems + 1] = file .. ": NEW unresolved ids (fix the source): " .. table.concat(extra, ", ")
		end
	end

	for _, file in ipairs(sortedKeys(D.KNOWN_GAPS)) do
		local _, fixed = listDiff(actual[file] or {}, D.KNOWN_GAPS[file])

		if #fixed > 0 then
			problems[#problems + 1] = file .. ": FIXED, remove from KNOWN_GAPS: " .. table.concat(fixed, ", ")
		end
	end

	lu.assertEquals(problems, {}, "unresolved ids versus KNOWN_GAPS")
	lu.assertEquals(actual, D.KNOWN_GAPS, "unresolvedByFile versus KNOWN_GAPS")
end

-- AC-9 (I-2). The spec expected {}, but 14 handlers keep a "@conversation/<file>" prefix in a local that nothing uses (the `stringFile`s;
-- Dulios' PT, once joined with the ids of TRAIN_CHOICES, is gone since space-convo-client-strings-dulios). The scan catches prefixes with or without the colon; every one is pinned
-- by "<path>: <line text>" (stable when lines above move), so a new prefix fails until it is listed.
function TestClientStringRatchet:test_the_only_stored_prefix_sites_in_the_space_conversation_sources_are_the_listed_ones()
	local src = CS.spaceConversationSources()

	lu.assertEquals(CS.dynamicSites(src), D.KNOWN_DYNAMIC, "lines that hold a string-file prefix instead of a complete id")
	lu.assertEquals(#CS.dynamicIds(src), #D.KNOWN_DYNAMIC, "dynamicIds count")
end

-- AC-9 (R-2): where a stored prefix is USED matters more than where it is declared; `PT .. "s_999999"` or `stringFile .. ":s_7"` must fail
function TestClientStringRatchet:test_the_only_line_that_uses_a_stored_prefix_is_the_listed_one()
	lu.assertEquals(CS.prefixUses(CS.spaceConversationSources()), D.KNOWN_PREFIX_USES, "lines that use a stored string-file prefix")
end

-- AC-9: unused prefix locals are reported, not silently passed
function TestClientStringRatchet:test_the_unused_stored_prefixes_are_exactly_the_listed_ones()
	lu.assertEquals(CS.unusedPrefixes(CS.spaceConversationSources()), D.KNOWN_UNUSED_PREFIXES, "stored string-file prefixes nothing uses")
end

-- AC-9: the helper itself sees prefixes with and without the colon, and ignores the standalone SUI labels
function TestClientStringsHelper:test_dynamic_scan_catches_prefixes_with_and_without_the_colon_and_their_use_sites()
	local sample = { "./tests/lua/fixtures/client_strings/sample_prefix.lua" }

	lu.assertEquals(CS.dynamicIds(sample), { sample[1] .. ":3", sample[1] .. ":4", sample[1] .. ":5" }, "dynamic lines (declarations and the inline join)")
	lu.assertEquals(CS.prefixUses(sample), { sample[1] .. ': function f() return stringFile .. ":s_7" end' }, "use sites")
	lu.assertEquals(CS.unusedPrefixes(sample), { sample[1] .. ': local lonely = "@conversation/other"' }, "unused declarations")
end

-- AC-9 / AC-2 of space-convo-client-strings-dulios (Appendix C): no id is joined at run time any more; the four TRAIN_CHOICES options are
-- complete literals and each resolves in the client file
function TestClientStringRatchet:test_the_dulios_train_choice_ids_are_complete_literals_that_resolve()
	local T = require("trainer_fixes_data")

	T.load()

	local choices = H.expectGlobal("duliosConvoHandler", "Dulios handler").TRAIN_CHOICES
	local sids = assert(CS.sids("conversation/naboo_privateer_tier3"))
	local prefix = "@conversation/naboo_privateer_tier3:"

	lu.assertEquals(#choices, 4, "Dulios TRAIN_CHOICES entries")

	for _, c in ipairs(choices) do
		lu.assertEquals(c[2]:sub(1, #prefix), prefix, "duliosConvoHandler.TRAIN_CHOICES option " .. tostring(c[2]) .. " (" .. c[1] .. ") is a complete string id")
		lu.assertTrue(sids[c[2]:sub(#prefix + 1)] == true, "duliosConvoHandler.TRAIN_CHOICES option " .. tostring(c[2]) .. " (" .. c[1] .. ") is not in the client file naboo_privateer_tier3")
	end
end
