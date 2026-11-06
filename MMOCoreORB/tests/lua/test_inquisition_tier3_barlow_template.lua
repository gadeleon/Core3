-- Lt. Colonel Barlow: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-2, invariants I-1, I-2; Content contract 1 and 2; FB-2; D-1).
--
-- Answer keys: inquisition_tier3_barlow_screens_data.lua (Appendix A, copied from the spec), the generated client id list
-- fixtures/string/en/conversation/naboo_imperial_tier3_barlow.sids (172 ids, served from patch_12_00.tre; FB-1) and
-- inquisition_tier3_barlow_client_text.lua (the English text of the served table). The J3B state graph is test_inquisition_tier3_barlow_conformance.lua.

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")
local CS = require("harness.client_strings")
local TEXT = require("inquisition_tier3_barlow_client_text")

B.load()

local PATHS = { B.TEMPLATE_FILE, B.HANDLER_FILE }
local PREFIX = B.PREFIX

local function template() return H.conversationTemplateTable(B.TEMPLATE) end

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

local function normalise(text) return (text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")) end

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestBarlowTemplateOracle = {}

function TestBarlowTemplateOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 82 screens, ids unique, and uses all 170 client lines and no other id
function TestBarlowTemplateOracle:test_appendix_a_has_82_screens_and_uses_every_client_line()
	lu.assertEquals(#B.SCREENS, 82, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(B.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(B.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. B.STF .. ".sids")

	local missing, extra, n = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		n = n + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(n, 170, "distinct ids used")
end

-- AC-2 (the oracle itself): the client text file has the 172 entries of the served table
function TestBarlowTemplateOracle:test_the_client_text_and_id_fixture_hold_172_entries()
	local n, m = 0, 0

	for id in pairs(TEXT) do
		n = n + 1
		lu.assertTrue(CS.sids(B.STF)[id] == true, id .. " is in the .sids fixture")
	end

	for _ in pairs(CS.sids(B.STF)) do
		m = m + 1
	end

	lu.assertEquals(n, 172, "entries in inquisition_tier3_barlow_client_text.lua")
	lu.assertEquals(m, 172, "ids in fixtures/string/en/" .. B.STF .. ".sids")
end

-- AC-2 (the oracle itself): the English of the lines the spec quotes
function TestBarlowTemplateOracle:test_the_gate_and_end_lines_are_the_words_of_the_client()
	lu.assertStrContains(TEXT.s_127f71ad, "This is a restricted area.", false, "restricted")
	lu.assertEquals(TEXT.s_a72db7d9, "Yes? What do you want? I am extremely busy.", "interview")
	lu.assertStrContains(TEXT.s_f813490a, "You again? I don't know anything else.", false, "already_spoke")
	lu.assertStrContains(TEXT.s_4355764f, "I do not recall requesting your presence?", false, "not_requested")
	lu.assertEquals(TEXT.s_65ec117a, "Good! Now I can get back to work.", "end_65ec117a")
	lu.assertEquals(TEXT.s_c3c8f385, "[silence]", "the silence line")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestBarlowTemplate = {}

function TestBarlowTemplate:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- AC-2, I-1: the screen ids are Appendix A's 82, in order
function TestBarlowTemplate:test_the_template_has_exactly_the_screens_of_appendix_a_in_order()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	lu.assertEquals(got, B.orderedIds(), B.TEMPLATE .. ": screen ids in order (82, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestBarlowTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(B.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, B.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-7)")

		if row.animation == "" then
			lu.assertNil(s.animation, "screen '" .. row.id .. "': no animation field where Appendix A shows none")
		end
	end
end

-- AC-2, I-1: the static options in order
function TestBarlowTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(B.SCREENS) do
		local want, got = {}, {}

		for i, o in ipairs(row.options) do
			want[i] = { PREFIX .. o[1], o[2] }
		end

		for i, o in ipairs(byId[row.id].options or {}) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-2, I-1
function TestBarlowTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(B.TEMPLATE), {}, B.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 1: the template shape
function TestBarlowTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, B.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 1: line 1 is a header comment naming Barlow, tier 3, the java, the slug and the handler
function TestBarlowTemplate:test_line_1_is_a_header_comment_naming_barlow_the_java_the_slug_and_the_handler()
	local first = readFile(B.TEMPLATE_FILE):match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "line 1 is a comment")

	for _, word in ipairs({ "Barlow", "naboo_imperial_tier3_barlow.java", "inquisition-tier3-barlow", "barlowConvoHandler" }) do
		lu.assertStrContains(first, word, false, "line 1 of barlow_convo.lua names " .. word)
	end
end

-- Content contract 1: each screen is a global barlow_convo_<id> followed by addScreen, and the file ends by registering the template
function TestBarlowTemplate:test_each_screen_is_a_named_global_added_in_appendix_order_and_the_file_registers_the_template_last()
	local source = readFile(B.TEMPLATE_FILE)
	local at = 0

	for _, row in ipairs(B.SCREENS) do
		local decl = source:find("\nbarlow_convo_" .. row.id .. " = ConvoScreen:new", at, true)

		lu.assertNotNil(decl, "barlow_convo.lua: global barlow_convo_" .. row.id .. " declared after the previous screen")

		local add = source:find("barlow_convo_template:addScreen(barlow_convo_" .. row.id .. ")", decl, true)

		lu.assertNotNil(add, "barlow_convo.lua: barlow_convo_template:addScreen(barlow_convo_" .. row.id .. ") after its declaration")
		at = add
	end

	lu.assertNotNil(source:find('addConversationTemplate("barlow_convo_template", barlow_convo_template)', at, true), "barlow_convo.lua: addConversationTemplate after the last screen")
end

-- Content contract 1: the English of every line is a trailing comment on the leftDialog line and on each option line
function TestBarlowTemplate:test_every_dialog_and_reply_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(B.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		if line:find("@conversation/", 1, true) then
			local sid = line:match('@conversation/naboo_imperial_tier3_barlow:(s_[%w_]+)"')
			local comment = line:match('"%s*[,}%s]*%-%-%s*(.-)%s*$')

			if sid == nil then
				lu.fail("a string id outside conversation/naboo_imperial_tier3_barlow: " .. line)
			end

			checked = checked + 1
			lu.assertNotNil(comment, "no trailing client text on: " .. line)
			lu.assertNotNil(TEXT[sid], sid .. " is not in the served table")
			lu.assertEquals(normalise(comment), normalise(TEXT[sid]), "trailing comment for " .. sid)
		end
	end

	-- 82 leftDialog lines; 91 distinct replies appear on 91 + (shared replies) option lines
	local replies = 0

	for _, row in ipairs(B.SCREENS) do
		replies = replies + #row.options
	end

	lu.assertEquals(checked, 82 + replies, "leftDialog lines plus option lines with a comment")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2, FB-2)
---------------------------------------------------------------------------------------------

TestBarlowClientStrings = {}

function TestBarlowClientStrings:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- AC-2, I-2: every @conversation literal names Barlow's file
function TestBarlowClientStrings:test_every_conversation_literal_names_barlows_string_file()
	local n = 0

	for _, lit in ipairs(CS.literals(PATHS)) do
		n = n + 1
		lu.assertEquals(lit.file, B.STF, lit.path .. ":" .. lit.line .. " (" .. lit.id .. "): string file")
	end

	lu.assertTrue(n >= 170, "at least the 170 ids are literals (got " .. n .. ")")
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestBarlowClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2, FB-2: no NGE editor number (one to three digits; the all-digit hash ids are client ids)
function TestBarlowClientStrings:test_neither_source_uses_a_decimal_editor_number()
	for _, path in ipairs(PATHS) do
		for id in readFile(path):gmatch('@conversation/naboo_imperial_tier3_barlow:(s_%d%d?%d?)"') do
			lu.fail(path .. " uses the NGE editor id " .. id .. " that the pre-NGE client lacks")
		end
	end
end

-- AC-2, I-2: the port uses all 170 client lines and no other id
function TestBarlowClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(B.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		used[lit.id] = true
	end

	local missing, extra, n = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		n = n + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines of naboo_imperial_tier3_barlow the template and handler never show")
	lu.assertEquals(extra, {}, "ids the template and handler use that the client does not have")
	lu.assertEquals(n, 170, "distinct ids used")
end

-- Content contract 1 and 2: complete literals, no stored string-file prefix, no built id
function TestBarlowClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Barlow's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
	lu.assertNil(readFile(B.HANDLER_FILE):find("local%s+stringFile%s*="), "barlowConvoHandler.lua: no stringFile prefix local")
end

-- Content contract 2: Barlow's conversation sets no name token (no line has %TU / %NU)
function TestBarlowClientStrings:test_no_client_line_has_a_name_token_and_no_screen_sets_a_parameter()
	for id, text in pairs(TEXT) do
		lu.assertNil(text:find("%%[TN]U"), id .. " has a name token")
	end

	for _, walk in pairs(B.WALKS) do
		local t = B.talk(B.pilot({ question = true }), walk)

		for _, step in ipairs(t) do
			lu.assertNil(step.params and next(step.params), "screen '" .. step.id .. "' sets a text parameter")
		end
	end
end

return nil
