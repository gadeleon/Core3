-- Major Eker: the conversation template (Appendix A, 161 screens), its client strings, the SWG java answer key and the client-strings ratchet.
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-2, I-1, I-2; Content contract 2 and 4; Data mapping 2; FE-1, FE-2; D-1, D-2).
--
-- Answer keys: crimson_tier2_eker_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/yavin_rebel_trainer_2.java (harness/swgjava.lua), the generated client id list
-- fixtures/string/en/conversation/yavin_rebel_trainer_2.sids and the client text crimson_tier2_eker_client_text.lua.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local CS = require("harness.client_strings")
local TEXT = require("crimson_tier2_eker_client_text")
local KD = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")

E.loadConversation()

local PATHS = { E.TEMPLATE_FILE, E.HANDLER_FILE }
local PREFIX = E.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

local function template() return H.conversationTemplateTable(E.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path, mode)
	local f = assert(io.open(path, mode or "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function readScript(path) return readFile(H.SCRIPTS .. path) end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function requireClone()
	local f = io.open(GAME .. E.JAVA, "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	f:close()
end

local function requireTre()
	local f = io.open("/tre/patch_12_00.tre", "rb")

	if f == nil then
		lu.skip("/tre/patch_12_00.tre is not readable: the archive checks need the client files")
	end

	f:close()
end

local function count(t)
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end

	return n
end

---------------------------------------------------------------------------------------------
-- The oracle itself (Appendix A, the fixtures, the client text)
---------------------------------------------------------------------------------------------

TestEkerOracle = {}

function TestEkerOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 161 screens, ids unique, and uses all 302 client lines (the other two entries are do_not_edit and s_0)
function TestEkerOracle:test_appendix_a_has_161_screens_and_uses_every_one_of_the_302_client_lines()
	lu.assertEquals(#E.SCREENS, 161, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(E.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(E.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. E.STF .. ".sids")

	local missing, extra = {}, {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(count(used), 302, "distinct client ids Appendix A uses")
end

-- AC-2 (the oracle itself): every link target of Appendix A exists
function TestEkerOracle:test_every_appendix_a_link_target_exists()
	for _, row in ipairs(E.SCREENS) do
		for _, o in ipairs(row.options) do
			lu.assertNotNil(E.screenRow(o[2]), "screen '" .. row.id .. "': link target '" .. o[2] .. "'")
		end
	end
end

-- AC-2 (the oracle itself): the client text table and the id fixture hold the 304 entries of the spec
function TestEkerOracle:test_the_client_id_fixture_and_the_text_table_hold_304_entries()
	lu.assertEquals(count(CS.sids(E.STF)), 304, "ids in fixtures/string/en/" .. E.STF .. ".sids")
	lu.assertEquals(count(TEXT), 304, "entries of crimson_tier2_eker_client_text.lua")

	for id in pairs(CS.sids(E.STF)) do
		lu.assertNotNil(TEXT[id], "client text of " .. id)
	end
end

-- AC-2 (the oracle itself): NAME_SCREENS (11) is exactly the screens whose line has a %TU or %NU token
function TestEkerOracle:test_name_screens_are_exactly_the_screens_whose_line_has_a_name_token()
	local derived = {}

	for _, row in ipairs(E.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			derived[#derived + 1] = row.id
		end
	end

	local listed = {}

	for i, id in ipairs(E.NAME_SCREENS) do
		listed[i] = id
	end

	table.sort(derived)
	table.sort(listed)
	lu.assertEquals(#listed, 11, "NAME_SCREENS entries")
	lu.assertEquals(derived, listed, "screens whose line carries %TU or %NU")
end

-- AC-2 (the oracle itself): the exact client text of the pre-NGE-only lines (FE-2) so a wrong sid fails with the words
function TestEkerOracle:test_the_pre_nge_training_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_27b3d1b3, "Plenty. Take a look.", "training_menu line")
	lu.assertEquals(TEXT.s_c6c91897, "Multi-Role Craft", "starships topic")
	lu.assertStrContains(TEXT.s_98d991e7, "Weapons B, Intermediate Alliance Starship Ordnance")
	lu.assertEquals(TEXT.s_73ccefde, "Space Combat Techniques", "procedures topic")
	lu.assertEquals(TEXT.s_3c4ff185, "Reactor Engineering Algorithms", "droid topic")
	lu.assertEquals(TEXT.s_fabecb04, "I appreciate the offer, but some other time.", "leave reply")
	lu.assertEquals(TEXT.s_8f4bcc2b, "You're passing up a good offer here.", "training_passing_up line")
	lu.assertEquals(TEXT.s_3f00169, "That's the one?", "starships / droid confirm")
	lu.assertEquals(TEXT.s_45b2289f, "That's your choice?", "weapons confirm")
	lu.assertEquals(TEXT.s_82b46acf, "You sure you can handle it?", "procedures confirm")
	lu.assertEquals(TEXT.s_6bb0cb94, "Correct.", "starships / weapons yes")
	lu.assertEquals(TEXT.s_d9cced1f, "Absolutely.", "procedures / droid yes")
	lu.assertEquals(TEXT.s_f39da193, "Wait.", "starships no")
	lu.assertEquals(TEXT.s_9b34069d, "No wait, let me think about this.", "droid no")
	lu.assertEquals(TEXT.s_65c36194, "On second thought, no.", "weapons no")
	lu.assertEquals(TEXT.s_d8fef41, "Perhaps not...", "procedures no")
	lu.assertEquals(TEXT.s_895e16f4, "Good choice. Come back when you're done. We've got work to do.", "trained line")
	lu.assertEquals(TEXT.s_6b158a0e, "I'm a Developer/Tester and want missions.", "the GM reply")
	lu.assertEquals(TEXT.s_f2142cc7, "It's free, soldier. An Alliance perk.", "training_free line")
end

-- AC-2 (the oracle itself): the answer key parses the 179 NPC lines of JE, a byte copy of the clone
function TestEkerOracle:test_the_java_answer_key_parses_179_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. E.JAVA)

	lu.assertEquals(#graph.order, 179, "NPC lines parsed from yavin_rebel_trainer_2.java")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestEkerTemplate = {}

function TestEkerTemplate:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2, I-1: ids and their order are Appendix A's
function TestEkerTemplate:test_the_template_has_exactly_the_161_screens_of_appendix_a_in_order()
	local got, want = {}, {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	for i, row in ipairs(E.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(got, want, E.TEMPLATE .. ": screen ids in order (161, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestEkerTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(E.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, E.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-1)")
	end
end

-- AC-2, I-1: the static options in order (training_menu, off_track and the C-n screens hold the default links)
function TestEkerTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(E.SCREENS) do
		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = { PREFIX .. o[1], o[2] }
		end

		local got = {}

		for i, o in ipairs(byId[row.id].options or {}) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-2, I-1
function TestEkerTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(E.TEMPLATE), {}, E.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestEkerTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, E.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the complete English text of every line is a trailing comment on the leftDialog line
function TestEkerTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(E.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/yavin_rebel_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/yavin_rebel_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 161, "leftDialog lines with a comment")
end

-- Content contract 2: the file ends with the registration of the template under its name
function TestEkerTemplate:test_the_template_is_registered_under_its_name_at_the_end_of_the_file()
	local source = readScript(E.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate%("eker_convo_template",%s*eker_convo_template%)%s*$'), "the file ends with addConversationTemplate(\"eker_convo_template\", eker_convo_template)")
end

-- Content contract 3 (NAME_SCREENS): every screen whose line carries %TU / %NU shows the first name; no other screen sets a parameter (the pilot's name is "Ace")
function TestEkerTemplate:test_the_11_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local names = {}

	for _, id in ipairs(E.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(E.SCREENS) do
		H.reset()
		E.spyStarts()

		-- a pilot for whom every screen can be shown: a tester with a flag-"2" graduate who has the XP
		local player = E.pilot({ missions = 1, t2 = 1, xp = 99999, graduated = "2", privileged = true })
		local t = E.drive(player, row.id)

		lu.assertEquals(#t >= 1, true, "screen '" .. row.id .. "': shown")

		if names[row.id] then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the first name is the text parameter")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no text parameter")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2, FE-1, FE-2)
---------------------------------------------------------------------------------------------

TestEkerClientStrings = {}

function TestEkerClientStrings:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestEkerClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 302 client lines and no other id
function TestEkerClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(E.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == E.STF then
			used[lit.id] = true
		end
	end

	local missing, extra = {}, {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines of yavin_rebel_trainer_2 the template and handler never show")
	lu.assertEquals(extra, {}, "ids the sources use that the client file lacks")
	lu.assertEquals(count(used), 302, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestEkerClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('yavin_rebel_trainer_2:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-2: the sources use complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestEkerClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Eker sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler names the four topic replies, the leave reply, the GM reply and the off-track reply as complete literals (Content contract 3)
function TestEkerClientStrings:test_the_handler_names_the_replies_it_builds_as_complete_literals()
	local source = readScript(E.HANDLER_FILE)

	for _, t in ipairs(E.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "ekerConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. E.LEAVE_REPLY .. '"', 1, true), "ekerConvoHandler.lua: complete literal for the leave reply " .. E.LEAVE_REPLY)
	lu.assertNotNil(source:find('"' .. PREFIX .. E.GM_REPLY .. '"', 1, true), "ekerConvoHandler.lua: complete literal for the GM reply " .. E.GM_REPLY)
	lu.assertNotNil(source:find('"' .. PREFIX .. E.OFF_TRACK_REPLY .. '"', 1, true), "ekerConvoHandler.lua: complete literal for the off-track reply " .. E.OFF_TRACK_REPLY)
	lu.assertNil(source:find("local%s+stringFile%s*="), "ekerConvoHandler.lua: no stringFile prefix local")
end

-- AC-2: the pre-NGE training screens show the client lines (FE-2): menu, four confirms, the leave answer and the trained lines with nod_head_once
function TestEkerClientStrings:test_the_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. "s_27b3d1b3", "training_menu shows s_27b3d1b3")
	lu.assertEquals(byId.training_passing_up.leftDialog, PREFIX .. "s_8f4bcc2b", "training_passing_up shows s_8f4bcc2b")
	lu.assertEquals(byId.training_passing_up.stopConversation, "true", "training_passing_up ends")

	for _, t in ipairs(E.TRAIN) do
		lu.assertEquals(byId[t.confirm].leftDialog, PREFIX .. t.confirmSid, t.confirm .. " shows its line")
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. E.TRAINED_SID, t.trained .. " shows its line")
		lu.assertEquals(byId[t.trained].animation, "nod_head_once", t.trained .. ": nod_head_once (D-1)")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends (one skill per visit)")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A (I-1, D-1)
---------------------------------------------------------------------------------------------

TestEkerJavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. E.JAVA)

local function javaTriples()
	local CLIENT = CS.sids(E.STF)
	local out, seen = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] then
					for _, nxt in ipairs(GRAPH.successorsOf(sid, reply) or {}) do
						local key = sid .. "|" .. reply .. "|" .. nxt

						if CLIENT[nxt] and not seen[key] then
							seen[key] = true
							out[#out + 1] = key
						end
					end
				end
			end
		end
	end

	return out
end

-- Appendix A: the (dialog sid | reply sid | next dialog sid) triples the rows keep
local function appendixTriples()
	local kept = {}

	for _, row in ipairs(E.SCREENS) do
		for _, o in ipairs(row.options) do
			kept[row.sid .. "|" .. o[1] .. "|" .. E.screenRow(o[2]).sid] = true
		end
	end

	return kept
end

function TestEkerJavaGraph:setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-2 (the oracle itself; spec: every JE (NPC line, reply, next line) triple whose three ids are client ids is kept, 129): 129 (line, reply) pairs with a
-- client first successor, 130 triples because the off-track reply has two successors (JE:633). Each is a triple of some row; the one that depends on the
-- pilot (off track, duties) is the handler's C-1 link, so no static row holds it.
function TestEkerOracle:test_every_java_triple_of_client_lines_is_kept_by_appendix_a_except_the_c1_off_track_link()
	local pairsN, seen = 0, {}

	for _, sid in ipairs(GRAPH.order) do
		for _, reply in ipairs(GRAPH.nodes[sid].options) do
			local first = (GRAPH.successorsOf(sid, reply) or {})[1]

			if CS.sids(E.STF)[sid] and CS.sids(E.STF)[reply] and first ~= nil and CS.sids(E.STF)[first] and not seen[sid .. "|" .. reply] then
				seen[sid .. "|" .. reply] = true
				pairsN = pairsN + 1
			end
		end
	end

	local kept, missing = appendixTriples(), {}
	local triples = javaTriples()

	for _, key in ipairs(triples) do
		if not kept[key] then
			missing[#missing + 1] = key
		end
	end

	lu.assertEquals(pairsN, 129, "(NPC line, reply) pairs of client ids in the java")
	lu.assertEquals(#triples, 130, "(NPC line, reply, next line) triples of client ids in the java")
	lu.assertEquals(missing, { "s_56b0632|s_1583743c|s_cc00d56b" }, "java triples no static Appendix A row keeps (the off-track duty link of C-1)")
end

-- AC-2, I-1: the built template keeps those triples too
function TestEkerJavaGraph:test_the_template_keeps_every_java_triple_of_client_lines()
	local kept = {}
	local byId = screensById()

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			local target = byId[o[2]]

			if target ~= nil then
				kept[s.leftDialog .. "|" .. o[1] .. "|" .. target.leftDialog] = true
			end
		end
	end

	local missing = {}

	for _, key in ipairs(javaTriples()) do
		local a, b, c = key:match("^(.-)|(.-)|(.*)$")

		if not kept[PREFIX .. a .. "|" .. PREFIX .. b .. "|" .. PREFIX .. c] then
			missing[#missing + 1] = key
		end
	end

	lu.assertEquals(missing, { "s_56b0632|s_1583743c|s_cc00d56b" }, "java triples of client lines the static template lacks (only the C-1 off-track duty link)")
end

-- AC-2, D-1: a screen whose dialog line is an NPC line of the java ends iff the java line ends and plays the java line's animation
-- (the pre-NGE training screens that are not java NPC lines are not compared)
function TestEkerJavaGraph:test_every_screen_with_a_java_line_plays_the_java_animation_and_ends_like_it()
	local byId = screensById()
	local compared = 0

	for _, row in ipairs(E.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			compared = compared + 1
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. row.sid .. "): the java's doAnimationAction")

			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
		end
	end

	lu.assertEquals(compared, 151, "screens whose dialog line is a java NPC line")
end

-- AC-2 (the oracle itself): the same comparison holds for the Appendix A rows, whatever the production template says
function TestEkerOracle:test_appendix_a_animations_are_the_java_animations()
	local graph = GRAPH

	for _, row in ipairs(E.SCREENS) do
		local node = graph.nodes[row.sid]

		if node ~= nil then
			lu.assertEquals(row.animation, node.animation or "", "Appendix A row '" .. row.id .. "' (" .. row.sid .. "): animation")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Fixtures and the client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestEkerFixtures = {}

function TestEkerFixtures:setUp() H.reset() end

-- AC-2: the ratchet entry and the count (73 files)
function TestEkerFixtures:test_fixture_counts_holds_ekers_file_with_304_ids_as_the_73rd_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[E.STF], 304, "FIXTURE_COUNTS[" .. E.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 74, "FIXTURE_COUNTS entries") -- 74 since crimson-phoenix-tier3-ulvawop
end

-- AC-2: nothing is allowed to be unresolved
function TestEkerFixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestEkerFixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- crimson-phoenix-tier2-eker-convo: Major Eker's conversation/yavin_rebel_trainer_2 (304 ids, served from patch_12_00.tre) is new and fully resolved (the 73rd file); KNOWN_GAPS stays {}.", false)
end

-- AC-2: the referenced string files of the space conversation sources include Eker's file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestEkerFixtures:test_the_space_conversation_sources_reference_ekers_string_file()
	E.requireConversation(lu)

	local referenced = CS.referencedFiles(CS.spaceConversationSources())
	local found = false

	for _, file in ipairs(referenced) do
		found = found or file == E.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. E.STF)
end

-- AC-2: the fixture is 304 sorted unique lines, including do_not_edit and s_0
function TestEkerFixtures:test_the_sids_fixture_has_304_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. E.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 304, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- Content contract 4: JE is a byte copy of the clone
function TestEkerFixtures:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. E.JAVA, "rb") == readFile(GAME .. E.JAVA, "rb"), "fixtures/" .. E.JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: JE is the 7,177 line script of the spec (the line numbers of the spec's citations hold)
function TestEkerFixtures:test_the_java_fixture_is_the_7177_line_script_of_the_spec()
	local text = readFile(H.FIXTURES .. E.JAVA, "rb")
	local lines = 0

	for _ in text:gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 7176 and lines <= 7178, "lines in yavin_rebel_trainer_2.java: " .. lines)
end

-- Content contract 4: every tier 2 skill costs 60,000 XP in the skills excerpt (the engine price the training tests charge)
function TestEkerFixtures:test_every_tier_2_skill_costs_60000_experience_in_the_excerpt()
	local costs = E.useSkillCosts()

	for _, t in ipairs(E.TRAIN) do
		lu.assertEquals(costs[t.skill], E.XP_COST, t.skill .. ": XP_COST")
	end
end

-- AC-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestEkerFixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. E.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. E.STF .. ": " .. out)
end

-- AC-2: no bytecode left behind by the checks
function TestEkerFixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
