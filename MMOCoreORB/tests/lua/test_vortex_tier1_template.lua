-- V3-FX: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FI-2, FI-3; D-2, D-3, D-4).
--
-- Answer keys: vortex_tier1_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/naboo_rebel_trainer_1.java (harness/swgjava.lua), and the generated client id list
-- fixtures/string/en/conversation/naboo_rebel_trainer_1.sids.

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")
local CS = require("harness.client_strings")
local TEXT = require("vortex_tier1_client_text")
local Swgjava = require("harness.swgjava")

I.load()

local PATHS = { I.TEMPLATE_FILE, I.HANDLER_FILE }
local PREFIX = I.PREFIX

local function template() return H.conversationTemplateTable(I.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

TestVortexT1Oracle = {}

function TestVortexT1Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 137 screens, ids unique, and it uses all 234 client lines (the other two entries are do_not_edit and s_0)
function TestVortexT1Oracle:test_appendix_a_has_137_screens_and_uses_every_client_line()
	lu.assertEquals(#I.SCREENS, 137, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(I.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(I.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. I.STF .. ".sids")

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
end

-- AC-5 (the oracle itself): the generated client id list holds the 236 entries the spec names (234 lines plus do_not_edit and s_0)
function TestVortexT1Oracle:test_the_client_id_fixture_holds_236_ids()
	local ids = CS.sids(I.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 236, "ids in fixtures/string/en/" .. I.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FI-2, FI-3), so a wrong sid fails with the words
function TestVortexT1Oracle:test_the_pre_nge_only_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_60c2803a, "Greetings... %TU?", "grounded line 1")
	lu.assertEquals(TEXT.s_10581a3e, "That's right", "grounded reply 1")
	lu.assertStrContains(TEXT.s_3fc246bd, "You have been grounded by Alliance HQ.")
	lu.assertEquals(TEXT.s_7426e000, "No!", "grounded reply 2")
	lu.assertStrContains(TEXT.s_de748105, "Bad news, %TU.")
	lu.assertEquals(TEXT.s_f8b02865, "What do I do?", "grounded reply 3")
	lu.assertStrContains(TEXT.s_da1db2a5, "Improve your faction standing with the Rebel Alliance.")
	lu.assertEquals(TEXT.s_6576f571, "How?!", "grounded reply 4")
	lu.assertStrContains(TEXT.s_692451bc, "I'm terribly sorry, %TU.")
	lu.assertEquals(TEXT.s_26970ef, "I am interested in basic starfighter training.", "starships topic")
	lu.assertEquals(TEXT.s_3fa70900, "I am interested in basic starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_8c272224, "I am interested in starfighter survival tactics.", "procedures topic")
	lu.assertEquals(TEXT.s_9480f430, "I am interested in droid interface basics.", "droid topic")
	lu.assertStrContains(TEXT.s_d671116a, "Good work, sir!")
	lu.assertStrContains(TEXT.s_593caccf, "Excellent work, ma'am.")
	lu.assertStrContains(TEXT.s_8062b983, "How noble of you, sir!")
	lu.assertStrContains(TEXT.s_b0d2b96b, "How noble of you, ma'am!")
	lu.assertStrContains(TEXT.s_6f3e9d4b, "Which do you prefer?")
	lu.assertStrContains(TEXT.s_838cca30, "What area interests you the most?")
	lu.assertStrContains(TEXT.s_eedd7284, "I cannot help you with that.  *bzzt*")
end

-- AC-5 (the oracle itself): exactly four client lines carry a %-token (%TU), the ones the spec names, so exactly four screens need setDialogTextTU
function TestVortexT1Oracle:test_exactly_four_client_lines_carry_the_tu_token()
	local tokens = {}

	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" and text:find("%%[A-Z][A-Z]") then
			tokens[#tokens + 1] = id
			lu.assertNotNil(text:find("%%TU"), id .. ": carries a token that is not %TU")
		end
	end

	table.sort(tokens)
	lu.assertEquals(tokens, { "s_60c2803a", "s_692451bc", "s_de748105", "s_fb2ee4e7" }, "client lines with a % token")
end

TestVortexT1Template = {}

function TestVortexT1Template:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5, I-8
function TestVortexT1Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, I.screenIds(), I.TEMPLATE .. ": screen ids (137, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestVortexT1Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, I.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-2)")
	end
end

-- AC-5, I-8: the static options in order (the training menus and the C-n screens hold the default links)
function TestVortexT1Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
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

-- AC-5, I-8
function TestVortexT1Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(I.TEMPLATE), {}, I.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestVortexT1Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, I.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestVortexT1Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(I.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_rebel_trainer_1:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_rebel_trainer_1", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 137, "leftDialog lines with a comment")
end

-- Content contract 3: the four screens whose line carries %TU set the first name; no other screen sets a parameter
function TestVortexT1Template:test_the_four_tu_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local tu = {}

	for _, row in ipairs(I.SCREENS) do
		if TEXT[row.sid]:find("%%TU") then
			tu[#tu + 1] = row.id
		end
	end

	table.sort(tu)
	lu.assertEquals(tu, { "grounded", "grounded_bad_news", "grounded_missions", "m2_not_so_fast" }, "screens whose line carries %TU")

	for _, row in ipairs(I.SCREENS) do
		for _, g in ipairs(I.GLOBALS) do
			H.spyOn(I.quest(g), "startQuest")
		end

		local t = I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id)

		if TEXT[row.sid]:find("%%TU") then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %TU parameter is the pilot's first name")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no %TU parameter")
		end

		H.reset()
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, FI-2)
---------------------------------------------------------------------------------------------

TestVortexT1ClientStrings = {}

function TestVortexT1ClientStrings:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks
function TestVortexT1ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, FI-2: the port uses all 234 client lines and no other id
function TestVortexT1ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(I.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == I.STF then
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
	lu.assertEquals(missing, {}, "client lines of naboo_rebel_trainer_1 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 234, "distinct ids used")
end

-- AC-5, I-8: no NGE editor number (s_<decimal>) in either source
function TestVortexT1ClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('naboo_rebel_trainer_1:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestVortexT1ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the V3-FX sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestVortexT1ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(I.HANDLER_FILE)

	for _, t in ipairs(I.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "v3fxConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "v3fxConvoHandler.lua: no stringFile prefix local")
end

-- AC-5: the training menus and the trained screens show the pre-NGE client lines
function TestVortexT1ClientStrings:test_the_training_menus_and_trained_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_first.leftDialog, PREFIX .. I.MENU_FIRST, "training_first shows s_6f3e9d4b")
	lu.assertEquals(byId.training_more.leftDialog, PREFIX .. I.MENU_MORE, "training_more shows s_838cca30")

	for _, t in ipairs(I.TRAIN) do
		lu.assertEquals(byId[t.male].leftDialog, PREFIX .. t.maleSid, t.male .. " shows its line")
		lu.assertEquals(byId[t.female].leftDialog, PREFIX .. t.femaleSid, t.female .. " shows its line")
		lu.assertEquals(byId[t.male].animation, "salute1", t.male .. ": salute1 (D-2)")
		lu.assertEquals(byId[t.male].stopConversation, "true", t.male .. " ends")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A (I-8, D-2)
---------------------------------------------------------------------------------------------

TestVortexT1JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_rebel_trainer_1.java")

function TestVortexT1JavaGraph:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5 (the oracle itself)
function TestVortexT1Oracle:test_the_answer_key_parses_158_npc_lines()
	lu.assertEquals(#GRAPH.order, 158, "NPC lines parsed from naboo_rebel_trainer_1.java")
end

-- AC-5, I-8 (the oracle itself; spec: "all 201 J (NPC line, reply) pairs whose two ids are client ids are kept"): every such pair is a (dialog, reply) of a screen
function TestVortexT1Oracle:test_every_java_pair_of_client_lines_is_kept_by_some_screen_of_appendix_a()
	local CLIENT = CS.sids(I.STF)
	local kept = {}

	for _, row in ipairs(I.SCREENS) do
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
	lu.assertEquals(pairsN, 201, "(NPC line, reply) pairs of client ids in the java")
	lu.assertEquals(missing, {}, "java pairs of client lines that no Appendix A screen keeps")
end

-- AC-5, I-8: the built template keeps those pairs too (the screens by dialog line, in the template, not only in the data file)
function TestVortexT1JavaGraph:test_the_template_keeps_every_java_pair_of_client_lines()
	local CLIENT = CS.sids(I.STF)
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

-- AC-5, D-2: a screen whose dialog line is an NPC line of the java ends iff the java line ends and plays the java line's animation
-- (refinements: the two screens that share a line show it alike; the trained screens and the grounded chain are pre-NGE-only and not in the java)
function TestVortexT1JavaGraph:test_every_screen_with_a_java_line_ends_and_animates_like_it()
	local byId = screensById()
	local compared = 0

	for _, row in ipairs(I.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			compared = compared + 1
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. row.sid .. "): the java's doAnimationAction")
		end
	end

	lu.assertEquals(compared, 126, "screens whose dialog line is a java NPC line")
end

---------------------------------------------------------------------------------------------
-- The client-strings ratchet (AC-5): V3-FX's file is already counted (Kreezo's handler references it), so the counts stay
---------------------------------------------------------------------------------------------

TestVortexT1Ratchet = {}

local KD = require("space_convo_client_strings_data")

function TestVortexT1Ratchet:setUp() H.reset() end

-- AC-5 (pre-existing entry, kept): the ratchet holds the file with its 236 ids
function TestVortexT1Ratchet:test_fixture_counts_holds_naboo_rebel_trainer_1_with_236_ids()
	lu.assertEquals(KD.FIXTURE_COUNTS[I.STF], 236, "FIXTURE_COUNTS[" .. I.STF .. "]")
end

-- AC-5: nothing is allowed to be unresolved
function TestVortexT1Ratchet:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- AC-5: the fixture is 236 sorted unique lines, including do_not_edit and s_0
function TestVortexT1Ratchet:test_the_sids_fixture_has_236_sorted_unique_lines()
	local text = readFile("../../tests/lua/fixtures/string/en/" .. I.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 236, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end
