-- Kiizete: the conversation template (Appendix A) and its client strings, against the SWG java graph.
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (AC-2, AC-8; invariants I-1, I-2; Content contract 2 and 5; FK-1, FK-2, FK-5; D-2).
--
-- Answer keys: vortex_tier1_kiizete_screens_data.lua (Appendix A), the SWG java graph of fixtures/script/conversation/naboo_rebel_tier1_kiizete.java
-- (harness/swgjava.lua, 61 NPC lines), the generated client id list fixtures/string/en/conversation/naboo_rebel_tier1_kiizete.sids (114 lines)
-- and the client text dump vortex_tier1_kiizete_client_text.lua.

local lu = require("luaunit")
local H = require("harness")
local K = require("vortex_tier1_kiizete_data")
local CS = require("harness.client_strings")
local TEXT = require("vortex_tier1_kiizete_client_text")
local Swgjava = require("harness.swgjava")

K.load()

local PATHS = { K.TEMPLATE_FILE, K.HANDLER_FILE }
local PREFIX = K.PREFIX

local function template() return H.conversationTemplateTable(K.TEMPLATE) end

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

local function count(t)
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end

	return n
end

---------------------------------------------------------------------------------------------
-- The oracles themselves (these pass on the red run: they check the fixtures and the answer key, not the port)
---------------------------------------------------------------------------------------------

TestVortexKiizeteOracle = {}

function TestVortexKiizeteOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 61 screens, ids unique, and uses all 112 client lines (the other two entries are do_not_edit and s_0)
function TestVortexKiizeteOracle:test_appendix_a_has_61_screens_and_uses_every_client_line()
	lu.assertEquals(#K.SCREENS, 61, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(K.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	lu.assertEquals(count(used), 112, "distinct ids Appendix A uses (61 NPC lines and 51 replies)")

	local ids = CS.sids(K.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. K.STF .. ".sids")

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

-- AC-2 (the oracle itself): the generated client id list holds the 114 entries the spec names (112 lines plus do_not_edit and s_0)
function TestVortexKiizeteOracle:test_the_client_id_fixture_holds_114_ids()
	lu.assertEquals(count(CS.sids(K.STF)), 114, "ids in fixtures/string/en/" .. K.STF .. ".sids")
	lu.assertEquals(count(TEXT), 114, "entries of vortex_tier1_kiizete_client_text.lua")

	for id in pairs(CS.sids(K.STF)) do
		lu.assertNotNil(TEXT[id], "client text dump has no entry for " .. id)
	end
end

-- AC-2 (the oracle itself): the java parses to exactly the 61 NPC lines, and Appendix A is that graph (first-appearance animation, options, ends)
local GRAPH = Swgjava.read(H.FIXTURES .. K.JAVA)

function TestVortexKiizeteOracle:test_the_answer_key_parses_61_npc_lines()
	lu.assertEquals(#GRAPH.order, 61, "NPC lines parsed from naboo_rebel_tier1_kiizete.java")
end

function TestVortexKiizeteOracle:test_appendix_a_agrees_with_the_java_graph_line_by_line()
	for _, row in ipairs(K.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (" .. row.id .. ")")
		lu.assertEquals(row.stop, node.isEnd, row.id .. " (" .. row.sid .. "): ends iff the java line has no replies")
		lu.assertEquals(row.animation, node.animation or "", row.id .. " (" .. row.sid .. "): first-appearance animation (D-2)")

		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = o[1]
		end

		lu.assertEquals(node.options, want, row.id .. " (" .. row.sid .. "): reply sids in order (FK-1)")
	end
end

-- AC-2, FK-2 (the oracle itself): every Appendix A link is a java edge of the line that offers the reply
function TestVortexKiizeteOracle:test_every_appendix_a_link_is_a_java_edge_of_its_own_line()
	local sidOf = {}

	for _, row in ipairs(K.SCREENS) do
		sidOf[row.id] = row.sid
	end

	for _, row in ipairs(K.SCREENS) do
		for _, o in ipairs(row.options) do
			local successors = GRAPH.successorsOf(row.sid, o[1]) or {}
			local found = false

			for _, s in ipairs(successors) do
				if s == sidOf[o[2]] then
					found = true
				end
			end

			lu.assertTrue(found, row.id .. ": reply " .. o[1] .. " -> " .. o[2] .. " (" .. tostring(sidOf[o[2]]) .. ") is not a java edge of " .. row.sid .. " (java: " .. table.concat(successors, ",") .. ")")
		end
	end
end

-- AC-2, FK-5 (the oracle itself): exactly two client lines carry a %-token (%NU)
function TestVortexKiizeteOracle:test_exactly_two_client_lines_carry_the_nu_token()
	local tokens = {}

	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" and text:find("%%[A-Z][A-Z]") then
			tokens[#tokens + 1] = id
			lu.assertNotNil(text:find("%%NU"), id .. ": carries a token that is not %NU")
		end
	end

	table.sort(tokens)
	lu.assertEquals(tokens, { "s_46dcc469", "s_9d788910" }, "client lines with a % token")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestVortexKiizeteTemplate = {}

function TestVortexKiizeteTemplate:setUp()
	H.reset()
	K.requireConversation(lu)
end

-- AC-2, I-1
function TestVortexKiizeteTemplate:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, K.screenIds(), K.TEMPLATE .. ": screen ids (61, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestVortexKiizeteTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(K.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, K.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (none where Appendix A shows a dash)")
	end
end

-- AC-2, I-1: the options in order
function TestVortexKiizeteTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(K.SCREENS) do
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
function TestVortexKiizeteTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(K.TEMPLATE), {}, K.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestVortexKiizeteTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, K.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the file's header comment and the closing registration
function TestVortexKiizeteTemplate:test_the_template_file_has_the_header_comment_and_registers_itself()
	local source = readFile(K.TEMPLATE_FILE)

	lu.assertEquals(source:match("^([^\n]*)"), "-- Kiizete (Vortex Squadron tier 1 side NPC, Moenia gazebo); ported from SWG-Source naboo_rebel_tier1_kiizete.java with the pre-NGE client lines (feature vortex-tier1-kiizete)", "line 1")
	lu.assertNotNil(source:find('addConversationTemplate("kiizete_convo_template", kiizete_convo_template)', 1, true), "the closing addConversationTemplate")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestVortexKiizeteTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(K.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_rebel_tier1_kiizete:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_rebel_tier1_kiizete", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 61, "leftDialog lines with a comment")
end

-- AC-8, Content contract 2: the template itself carries no parameter (the handler fills %NU on a clone)
function TestVortexKiizeteTemplate:test_no_template_screen_carries_a_dialog_parameter()
	for _, row in ipairs(K.SCREENS) do
		local s = LuaConversationTemplate(H.conversationTemplate(K.TEMPLATE)):getScreen(row.id)

		lu.assertNotNil(s, "screen '" .. row.id .. "'")
		lu.assertNil(s.params.NU, "screen '" .. row.id .. "': template screen has a NU parameter")
		lu.assertNil(s.params.TU, "screen '" .. row.id .. "': template screen has a TU parameter")
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2)
---------------------------------------------------------------------------------------------

TestVortexKiizeteClientStrings = {}

function TestVortexKiizeteClientStrings:setUp()
	H.reset()
	K.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestVortexKiizeteClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 112 client lines and no other id
function TestVortexKiizeteClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(K.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == K.STF then
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
	lu.assertEquals(missing, {}, "client lines of naboo_rebel_tier1_kiizete the template and handler never show")
	lu.assertEquals(count(used), 112, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestVortexKiizeteClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('naboo_rebel_tier1_kiizete:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-2: complete literals only (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestVortexKiizeteClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Kiizete sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler file's first line
function TestVortexKiizeteClientStrings:test_the_handler_file_starts_with_the_header_comment()
	local first = readFile(K.HANDLER_FILE):match("^([^\n]*)")

	lu.assertNotNil(first:find("naboo_rebel_tier1_kiizete.java", 1, true), "line 1 names naboo_rebel_tier1_kiizete.java: " .. first)
	lu.assertNotNil(first:find("vortex-tier1-kiizete", 1, true), "line 1 names vortex-tier1-kiizete: " .. first)
	lu.assertEquals(first:sub(1, 2), "--", "line 1 is a comment")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with the built template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestVortexKiizeteJavaGraph = {}

function TestVortexKiizeteJavaGraph:setUp()
	H.reset()
	K.requireConversation(lu)
end

-- AC-2, I-1: each screen is the java node of its dialog line (the template, not only the data file)
function TestVortexKiizeteJavaGraph:test_every_screen_ends_animates_and_offers_like_its_java_line()
	local compared = 0

	for _, s in ipairs(template().screens) do
		local sid = s.leftDialog:match(":(s_[%w_]+)$")
		local node = GRAPH.nodes[sid]

		lu.assertNotNil(node, "screen '" .. s.id .. "' (" .. tostring(s.leftDialog) .. "): not a java NPC line")
		compared = compared + 1
		lu.assertEquals(s.stopConversation == "true", node.isEnd, "screen '" .. s.id .. "': ends the conversation iff the java does")
		lu.assertEquals(s.animation or "", node.animation or "", "screen '" .. s.id .. "': the java's first doAnimationAction")

		local replies = {}

		for i, o in ipairs(s.options or {}) do
			replies[i] = o[1]:match(":(s_[%w_]+)$")
		end

		lu.assertEquals(replies, node.options, "screen '" .. s.id .. "': reply sids in the java's order")
	end

	lu.assertEquals(compared, 61, "screens compared")
end

-- AC-2, I-1, FK-2: each link of the template goes to a screen whose line is a java successor of that very line and reply
function TestVortexKiizeteJavaGraph:test_every_link_follows_the_java_edge_of_the_line_that_offers_the_reply()
	local sidOfScreen = {}

	for _, s in ipairs(template().screens) do
		sidOfScreen[s.id] = s.leftDialog:match(":(s_[%w_]+)$")
	end

	for _, s in ipairs(template().screens) do
		local from = sidOfScreen[s.id]

		for _, o in ipairs(s.options or {}) do
			local reply = o[1]:match(":(s_[%w_]+)$")
			local target = sidOfScreen[o[2]]
			local found = false

			for _, successor in ipairs(GRAPH.successorsOf(from, reply) or {}) do
				if successor == target then
					found = true
				end
			end

			lu.assertTrue(found, "screen '" .. s.id .. "': reply " .. reply .. " links to '" .. o[2] .. "' (" .. tostring(target) .. "), not a java successor of " .. from)
		end
	end
end

---------------------------------------------------------------------------------------------
-- The client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestVortexKiizeteRatchet = {}

local KD = require("space_convo_client_strings_data")

function TestVortexKiizeteRatchet:setUp() H.reset() end

-- AC-2: the new entry with its 114 ids
function TestVortexKiizeteRatchet:test_fixture_counts_holds_kiizetes_file_with_114_ids_in_the_69_entry_table()
	lu.assertEquals(KD.FIXTURE_COUNTS[K.STF], 114, "FIXTURE_COUNTS[" .. K.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 79, "FIXTURE_COUNTS entries") -- 69 since vortex-tier2-vrovel, 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop, 75 since crimson-phoenix-tier4-ufwol, 78 since battlefield-entry-stations
end

-- AC-2: the sources that reference string files include Kiizete's file, so the ratchet's referenced == FIXTURE_COUNTS check can hold
function TestVortexKiizeteRatchet:test_the_space_conversation_sources_reference_kiizetes_file()
	K.requireConversation(lu)

	local referenced = {}

	for _, file in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		referenced[file] = true
	end

	lu.assertTrue(referenced[K.STF] == true, "space conversation sources reference " .. K.STF)
end

-- AC-2: nothing is allowed to be unresolved
function TestVortexKiizeteRatchet:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- AC-2: the fixture is 114 sorted unique lines, including do_not_edit and s_0
function TestVortexKiizeteRatchet:test_the_sids_fixture_has_114_sorted_unique_lines()
	local text = readFile("../../tests/lua/fixtures/string/en/" .. K.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 114, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- AC-2: the java fixture is the SWG-Source file byte for byte (3,314 lines, so the line numbers of the spec hold)
function TestVortexKiizeteRatchet:test_the_java_fixture_has_3314_lines()
	local text = readFile("../../tests/lua/fixtures/" .. K.JAVA)
	local n = 0

	for _ in text:gmatch("\n") do
		n = n + 1
	end

	lu.assertEquals(n, 3314, "lines of the java fixture")
end
