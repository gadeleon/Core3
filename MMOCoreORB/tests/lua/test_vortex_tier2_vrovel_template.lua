-- Brother Vrovel: the conversation template (Appendix A, 131 screens), its client strings, the SWG java answer key and the client-strings ratchet.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-2, I-1, I-2; Content contract 2 and 4; Data mapping 2; FV-1, FV-2; D-1, D-2).
--
-- Answer keys: vortex_tier2_vrovel_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/dantooine_rebel_trainer_2.java (harness/swgjava.lua), the generated client id list
-- fixtures/string/en/conversation/dantooine_rebel_trainer_2.sids and the client text vortex_tier2_vrovel_client_text.lua.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local CS = require("harness.client_strings")
local TEXT = require("vortex_tier2_vrovel_client_text")
local KD = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")

V.loadConversation()

local PATHS = { V.TEMPLATE_FILE, V.HANDLER_FILE }
local PREFIX = V.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
local JAVA = "script/conversation/dantooine_rebel_trainer_2.java"

local function template() return H.conversationTemplateTable(V.TEMPLATE) end

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
	local f = io.open(GAME .. JAVA, "rb")

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

TestVrovelOracle = {}

function TestVrovelOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 131 screens, ids unique, and uses all 245 client lines (the other two entries are do_not_edit and s_0)
function TestVrovelOracle:test_appendix_a_has_131_screens_and_uses_every_one_of_the_245_client_lines()
	lu.assertEquals(#V.SCREENS, 131, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(V.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(V.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. V.STF .. ".sids")

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
	lu.assertEquals(count(used), 245, "distinct client ids Appendix A uses")
end

-- AC-2 (the oracle itself): the client text table and the id fixture hold the 247 entries of the spec
function TestVrovelOracle:test_the_client_id_fixture_and_the_text_table_hold_247_entries()
	lu.assertEquals(count(CS.sids(V.STF)), 247, "ids in fixtures/string/en/" .. V.STF .. ".sids")
	lu.assertEquals(count(TEXT), 247, "entries of vortex_tier2_vrovel_client_text.lua")

	for id in pairs(CS.sids(V.STF)) do
		lu.assertNotNil(TEXT[id], "client text of " .. id)
	end
end

-- AC-2 (the oracle itself): NAME_SCREENS (54) is exactly the screens whose line has a %TU or %NU token
function TestVrovelOracle:test_name_screens_are_exactly_the_screens_whose_line_has_a_name_token()
	local derived = {}

	for _, row in ipairs(V.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			derived[#derived + 1] = row.id
		end
	end

	local listed = {}

	for i, id in ipairs(V.NAME_SCREENS) do
		listed[i] = id
	end

	table.sort(derived)
	table.sort(listed)
	lu.assertEquals(#listed, 54, "NAME_SCREENS entries")
	lu.assertEquals(derived, listed, "screens whose line carries %TU or %NU")
end

-- AC-2 (the oracle itself): the exact client text of the pre-NGE-only lines (FV-2) so a wrong sid fails with the words
function TestVrovelOracle:test_the_pre_nge_training_lines_are_the_words_of_the_client()
	lu.assertStrContains(TEXT.s_c5b76777, "You have earned enough experience to advance to the next level in one of the following fields.")
	lu.assertEquals(TEXT.s_c6c91897, "Multi-Role Craft", "starships topic")
	lu.assertStrContains(TEXT.s_98d991e7, "Weapons B, Intermediate Alliance Starship Ordnance")
	lu.assertEquals(TEXT.s_73ccefde, "Space Combat Techniques", "procedures topic")
	lu.assertEquals(TEXT.s_3c4ff185, "Reactor Engineering Algorithms", "droid topic")
	lu.assertStrContains(TEXT.s_75a6ca67, "None right now, thank you.")
	lu.assertEquals(TEXT.s_4b9a2c6f, "This is what you want us to teach you?", "starships confirm")
	lu.assertEquals(TEXT.s_80f24a30, "This is the one? You're sure?", "weapons confirm")
	lu.assertEquals(TEXT.s_92ddd562, "You are sure of this?", "procedures confirm")
	lu.assertEquals(TEXT.s_d88c653e, "Are you sure?", "droid confirm")
	lu.assertEquals(TEXT.s_6bb0cb94, "Correct.", "starships yes")
	lu.assertEquals(TEXT.s_bb87cc7c, "One hundred percent, sir.", "weapons yes")
	lu.assertEquals(TEXT.s_d5ff7cb2, "Yes, definitely.", "procedures yes")
	lu.assertEquals(TEXT.s_98bb41ea, "Indeed.", "droid yes")
	lu.assertEquals(TEXT.s_4c1dac60, "Hold on, what choices did I have again?", "starships no")
	lu.assertEquals(TEXT.s_65c36194, "On second thought, no.", "weapons no")
	lu.assertEquals(TEXT.s_d8fef41, "Perhaps not...", "procedures no")
	lu.assertEquals(TEXT.s_ef759e6d, "No wait, let me reconsider.", "droid no")
	lu.assertStrContains(TEXT.s_1b8807cc, "I will have one of the pilots instruct you.")
	lu.assertStrContains(TEXT.s_820a0ee7, "I will have one of the pilots teach you.")
	lu.assertStrContains(TEXT.s_d8841255, "Very well. But hurry back.")
	lu.assertEquals(TEXT.s_6b158a0e, "I'm a Developer/Tester and want missions.", "the GM reply")
end

-- AC-2 (the oracle itself): the answer key parses the 144 NPC lines of J2, a byte copy of the clone
function TestVrovelOracle:test_the_java_answer_key_parses_144_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. JAVA)

	lu.assertEquals(#graph.order, 144, "NPC lines parsed from dantooine_rebel_trainer_2.java")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestVrovelTemplate = {}

function TestVrovelTemplate:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-2, I-1: ids and their order are Appendix A's (the spec: "one ConvoScreen per Appendix A row, in Appendix A order")
function TestVrovelTemplate:test_the_template_has_exactly_the_131_screens_of_appendix_a_in_order()
	local got, want = {}, {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	for i, row in ipairs(V.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(got, want, V.TEMPLATE .. ": screen ids in order (131, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestVrovelTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(V.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, V.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-1)")
	end
end

-- AC-2, I-1: the static options in order (training_menu, off_track and the C-n screens hold the default links)
function TestVrovelTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(V.SCREENS) do
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
function TestVrovelTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(V.TEMPLATE), {}, V.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestVrovelTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, V.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestVrovelTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(V.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/dantooine_rebel_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/dantooine_rebel_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 131, "leftDialog lines with a comment")
end

-- Content contract 2: the file ends with the registration of the template under its name
function TestVrovelTemplate:test_the_template_is_registered_under_its_name_at_the_end_of_the_file()
	local source = readScript(V.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate%("vrovel_convo_template",%s*vrovel_convo_template%)%s*$'), "the file ends with addConversationTemplate(\"vrovel_convo_template\", vrovel_convo_template)")
end

-- Content contract 3 (NAME_SCREENS): every screen whose line carries %TU / %NU shows the first name; no other screen sets a parameter (the pilot's name is "Ace")
function TestVrovelTemplate:test_the_54_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local names = {}

	for _, id in ipairs(V.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(V.SCREENS) do
		H.reset()
		V.spyStarts()

		-- a pilot for whom every screen can be shown: a tester with a flag-"2" graduate who has the XP
		local player = V.pilot({ missions = 1, t2 = 1, xp = 99999, privileged = true })
		local t = V.drive(player, row.id)

		lu.assertEquals(#t >= 1, true, "screen '" .. row.id .. "': shown")

		if names[row.id] then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the first name is the text parameter")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no text parameter")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2, FV-1, FV-2)
---------------------------------------------------------------------------------------------

TestVrovelClientStrings = {}

function TestVrovelClientStrings:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestVrovelClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 245 client lines and no other id (Q-1 = A keeps the 14 GM lines)
function TestVrovelClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(V.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == V.STF then
			used[lit.id] = true
		end
	end

	local missing = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of dantooine_rebel_trainer_2 the template and handler never show")
	lu.assertEquals(count(used), 245, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestVrovelClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('dantooine_rebel_trainer_2:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-2: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestVrovelClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Vrovel sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler names the four topic replies and the leave reply as complete literals (Content contract 3)
function TestVrovelClientStrings:test_the_handler_names_the_topic_replies_as_complete_literals()
	local source = readScript(V.HANDLER_FILE)

	for _, t in ipairs(V.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "vrovelConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. V.LEAVE_REPLY .. '"', 1, true), "vrovelConvoHandler.lua: complete literal for the leave reply " .. V.LEAVE_REPLY)
	lu.assertNotNil(source:find('"' .. PREFIX .. V.GM_REPLY .. '"', 1, true), "vrovelConvoHandler.lua: complete literal for the GM reply " .. V.GM_REPLY)
	lu.assertNil(source:find("local%s+stringFile%s*="), "vrovelConvoHandler.lua: no stringFile prefix local")
end

-- AC-2: the pre-NGE training screens show the client lines (FV-2): menu, four confirms, leave and the trained lines with nod_head_once
function TestVrovelClientStrings:test_the_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. "s_c5b76777", "training_menu shows s_c5b76777")
	lu.assertEquals(byId.training_later.leftDialog, PREFIX .. "s_d8841255", "training_later shows s_d8841255")
	lu.assertEquals(byId.training_later.stopConversation, "true", "training_later ends")

	for _, t in ipairs(V.TRAIN) do
		lu.assertEquals(byId[t.confirm].leftDialog, PREFIX .. t.confirmSid, t.confirm .. " shows its line")
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows its line")
		lu.assertEquals(byId[t.trained].animation, "nod_head_once", t.trained .. ": nod_head_once (D-1)")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends (one skill per visit)")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A (I-1, D-1)
---------------------------------------------------------------------------------------------

TestVrovelJavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. JAVA)

function TestVrovelJavaGraph:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-2 (the oracle itself; spec FV-1: every J2 (NPC line, reply) pair whose two ids are client ids is kept): 107 such pairs, each a (dialog, reply) of a row
function TestVrovelOracle:test_every_java_pair_of_client_lines_is_kept_by_some_screen_of_appendix_a()
	local CLIENT = CS.sids(V.STF)
	local kept = {}

	for _, row in ipairs(V.SCREENS) do
		for _, o in ipairs(row.options) do
			kept[row.sid .. "|" .. o[1]] = true
		end
	end

	local seen, pairsN, missing = {}, 0, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				local key = sid .. "|" .. reply

				if CLIENT[reply] and not seen[key] then
					seen[key] = true
					pairsN = pairsN + 1

					if not kept[key] then
						missing[#missing + 1] = key
					end
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(pairsN, 107, "(NPC line, reply) pairs of client ids in the java")
	lu.assertEquals(missing, {}, "java pairs of client lines that no Appendix A screen keeps")
end

-- AC-2, I-1: the built template keeps those pairs too
function TestVrovelJavaGraph:test_the_template_keeps_every_java_pair_of_client_lines()
	local CLIENT = CS.sids(V.STF)
	local kept = {}

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			kept[s.leftDialog .. "|" .. o[1]] = true
		end
	end

	local missing = {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] and not kept[PREFIX .. sid .. "|" .. PREFIX .. reply] then
					missing[#missing + 1] = sid .. "|" .. reply
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "java pairs of client lines the template lacks")
end

-- AC-2, D-1: a screen whose dialog line is an NPC line of the java ends iff the java line ends and plays the java line's animation
-- (the pre-NGE training screens and the grounded and GM-only lines that are not java NPC lines are not compared)
function TestVrovelJavaGraph:test_every_screen_with_a_java_line_ends_and_animates_like_it()
	local byId = screensById()
	local compared = 0

	for _, row in ipairs(V.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			compared = compared + 1
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. row.sid .. "): the java's doAnimationAction")
		end
	end

	lu.assertEquals(compared, 121, "screens whose dialog line is a java NPC line")
end

---------------------------------------------------------------------------------------------
-- Fixtures and the client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestVrovelFixtures = {}

function TestVrovelFixtures:setUp() H.reset() end

-- AC-2: the ratchet entry and the count (69 files)
function TestVrovelFixtures:test_fixture_counts_holds_vrovels_file_with_247_ids_as_the_69th_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[V.STF], 247, "FIXTURE_COUNTS[" .. V.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 74, "FIXTURE_COUNTS entries") -- 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop
end

-- AC-2: nothing is allowed to be unresolved
function TestVrovelFixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestVrovelFixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- vortex-tier2-vrovel: Brother Vrovel's conversation/dantooine_rebel_trainer_2 (247 ids, served from patch_12_00.tre) is new and fully resolved (the 69th file); KNOWN_GAPS stays {}.", false)
end

-- AC-2: the referenced string files of the space conversation sources include Vrovel's file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestVrovelFixtures:test_the_space_conversation_sources_reference_vrovels_string_file()
	V.requireConversation(lu)

	local referenced = CS.referencedFiles(CS.spaceConversationSources())

	local found = false

	for _, file in ipairs(referenced) do
		found = found or file == V.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. V.STF)
end

-- AC-2: the fixture is 247 sorted unique lines, including do_not_edit and s_0
function TestVrovelFixtures:test_the_sids_fixture_has_247_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. V.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 247, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- Content contract 4: J2 is a byte copy of the clone
function TestVrovelFixtures:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. JAVA, "rb") == readFile(GAME .. JAVA, "rb"), "fixtures/" .. JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: J2 is the 6,363 line script of the spec (the line numbers of the spec's citations hold)
function TestVrovelFixtures:test_the_java_fixture_is_the_6363_line_script_of_the_spec()
	local text = readFile(H.FIXTURES .. JAVA, "rb")
	local lines = 0

	for _ in text:gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 6362 and lines <= 6364, "lines in dantooine_rebel_trainer_2.java: " .. lines)
end

-- Content contract 4: the skills excerpt is header rows 1-2 plus rows 606, 610, 614 and 618 of SWG's skills.tab (byte copy)
function TestVrovelFixtures:test_the_skills_excerpt_is_the_header_and_the_four_tier_2_rows_of_swg_source()
	local excerpt = readFile(H.FIXTURES .. "skill/skills.pilot_rebel_navy_02.tab", "rb")
	local names = {}

	for line in excerpt:gmatch("[^\n]+") do
		names[#names + 1] = line:match("^([^\t]*)")
	end

	lu.assertEquals(names, { "NAME", "s", "pilot_rebel_navy_starships_02", "pilot_rebel_navy_weapons_02", "pilot_rebel_navy_procedures_02", "pilot_rebel_navy_droid_02" }, "first column of the excerpt rows")

	local clone = GAME .. "../../../sys.shared/compiled/game/datatables/skill/skills.tab"
	local f = io.open(clone, "rb")

	if f == nil then
		return
	end

	f:close()

	local rc, out = shell("sed -n '1p;2p;606p;610p;614p;618p' " .. clone .. " | cmp - " .. H.FIXTURES .. "skill/skills.pilot_rebel_navy_02.tab")

	lu.assertEquals(rc, 0, "the excerpt differs from rows 1, 2, 606, 610, 614, 618 of skills.tab: " .. out)
end

-- Content contract 4: the XP price of every tier 2 skill is 60,000 (SKT rows) and no credits are charged by the engine price table
function TestVrovelFixtures:test_every_tier_2_skill_costs_60000_experience_in_the_excerpt()
	local costs = V.useSkillCosts()

	for _, t in ipairs(V.TRAIN) do
		lu.assertEquals(costs[t.skill], V.XP_COST, t.skill .. ": XP_COST")
	end
end

-- AC-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestVrovelFixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. V.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. V.STF .. ": " .. out)
end

-- AC-2: no bytecode left behind by the checks
function TestVrovelFixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
