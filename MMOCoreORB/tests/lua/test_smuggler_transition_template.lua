-- Karrde: the conversation template (Appendix A), its client strings and the SWG java script.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-5, invariant I-8; Content contract 3; FK-1, FK-8; D-2, D-10).
--
-- Answer keys: smuggler_transition_screens_data.lua (Appendix A, copied from the spec), the SWG java script
-- fixtures/script/conversation/tatooine_privateer_trainer_2.java (harness/swgjava.lua for lines, replies, end flags and links; a small scan here for
-- the NPC animations, because K calls doAnimationAction(self, ...) where the parser looks for npc), and the generated client id list
-- fixtures/string/en/conversation/tatooine_privateer_trainer_2.sids. TestSmugglerTransOracle2 needs no production code and is green from the start.

local lu = require("luaunit")
local H = require("harness")
local T = require("smuggler_transition_data")
local CS = require("harness.client_strings")
local TEXT = require("smuggler_transition_client_text")
local Swgjava = require("harness.swgjava")

T.load()

local PATHS = { T.TEMPLATE_FILE, T.HANDLER_FILE }
local PREFIX = T.PREFIX

local function template() return H.conversationTemplateTable(T.TEMPLATE) end

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

local K_PATH = H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java"
local GRAPH = Swgjava.read(K_PATH)

-- K is generated with objvar branches (not the handleBranch shape harness/swgjava.lua links): a reply handler is
--   if (branchId == B && response.equals("R")) { ... string_id message = new string_id(c_stringFile, "S"); ... setObjVar(player, "...branchId", N); ... }
-- so S follows R on branch B, and the replies of S belong to branch N. Returns { edges[B][R] = {S...}, branchesOf[S] = {N = true} }.
local function linksOfScript()
	local f = assert(io.open(K_PATH, "r"))
	local edges, branchesOf = {}, {}
	local branch, reply, message

	for line in f:lines() do
		local b, r = line:match('if %(branchId == (%d+) && response%.equals%("([%w_]+)"%)%)')

		if b ~= nil then
			branch, reply, message = tonumber(b), r, nil
			edges[branch] = edges[branch] or {}
			edges[branch][reply] = edges[branch][reply] or {}
		elseif line:find("OnStartNpcConversation", 1, true) then
			branch, reply, message = nil, nil, nil
		end

		local sid = line:match('string_id message = new string_id%(c_stringFile, "([%w_]+)"%)')

		if sid ~= nil then
			message = sid

			if reply ~= nil then
				local list = edges[branch][reply]

				list[#list + 1] = sid
			end
		end

		local n = line:match('setObjVar%(player, "conversation%.tatooine_privateer_trainer_2%.branchId", (%d+)%)')

		if n ~= nil and message ~= nil then
			branchesOf[message] = branchesOf[message] or {}
			branchesOf[message][tonumber(n)] = true
		end
	end

	f:close()
	return edges, branchesOf
end

-- sid -> set of the NPC's own animations in front of that line (doAnimationAction(self, ...) in the same block; the player's are ignored)
local function animationsOf()
	local f = assert(io.open(K_PATH, "r"))
	local out = {}
	local pending

	for line in f:lines() do
		local anim = line:match('doAnimationAction%(self, "([%w_]+)"%)')

		if anim ~= nil then
			pending = anim
		end

		local sid = line:match('string_id message = new string_id%(c_stringFile, "([%w_]+)"%)')

		if sid ~= nil then
			out[sid] = out[sid] or {}
			out[sid][pending or ""] = true
			pending = nil
		end

		if line:find("return SCRIPT_CONTINUE", 1, true) or line:find("branchId ==", 1, true) then
			pending = nil
		end
	end

	f:close()
	return out
end

local function setOf(list)
	local set = {}

	for _, v in ipairs(list) do
		set[v] = true
	end

	return set
end

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerTransOracle2 = {}

function TestSmugglerTransOracle2:setUp() H.reset() end

-- AC-5 (the oracle itself): 21 screens, ids unique, 35 ids used + 18 deferred = the 53 client lines of the file, disjoint (FK-1)
function TestSmugglerTransOracle2:test_appendix_a_has_21_screens_and_35_used_ids_and_the_18_deferred_ones_complete_the_client_file()
	lu.assertEquals(#T.SCREENS, 21, "Appendix A rows")

	local seen = {}

	for _, row in ipairs(T.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
	end

	local used = T.usedIds()

	lu.assertEquals(#used, 35, "ids Appendix A uses (21 dialog + 14 reply)")
	lu.assertEquals(#T.DEFERRED_IDS, 18, "deferred ids")

	local ids = CS.sids(T.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. T.STF .. ".sids")

	local all = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" then
			all[#all + 1] = id
		end
	end

	table.sort(all)

	local both = {}

	for _, id in ipairs(used) do
		lu.assertFalse(setOf(T.DEFERRED_IDS)[id] == true, id .. " is both used and deferred")
		both[#both + 1] = id
	end

	for _, id in ipairs(T.DEFERRED_IDS) do
		both[#both + 1] = id
	end

	table.sort(both)
	lu.assertEquals(both, all, "used + deferred ids versus the client lines of tatooine_privateer_trainer_2 (53)")
end

-- AC-5 (the oracle itself): the generated client id list holds the 55 entries the spec names, and the text file the same ids
function TestSmugglerTransOracle2:test_the_client_id_fixture_and_text_hold_55_ids()
	local ids = CS.sids(T.STF)
	local n = 0

	for id in pairs(ids) do
		n = n + 1
		lu.assertNotNil(TEXT[id], "smuggler_transition_client_text.lua has no text for " .. id)
	end

	lu.assertEquals(n, 55, "ids in fixtures/string/en/" .. T.STF .. ".sids (53 lines plus do_not_edit and s_0)")
end

-- AC-5 (the oracle itself): the answer key parses all 32 NPC lines of the script
function TestSmugglerTransOracle2:test_the_answer_key_parses_32_npc_lines()
	lu.assertEquals(#GRAPH.order, 32, "NPC lines parsed from tatooine_privateer_trainer_2.java")
end

-- AC-5, I-8 (the oracle itself): Appendix A agrees with the script. Every dialog is an NPC line, ends where the script ends, offers the script's replies in
-- its order and every reply leads where the script leads (the live branches; the dead copies 22, 26, 29, 30 say the same).
function TestSmugglerTransOracle2:test_every_screen_of_appendix_a_agrees_with_the_swg_script()
	local dialogOf = {}

	for _, row in ipairs(T.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local replies = 0
	local edges, branchesOf = linksOfScript()

	for _, row in ipairs(T.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "the script has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
		lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the script does")

		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = o[1]
		end

		lu.assertEquals(node.options, want, "screen '" .. row.id .. "': the replies of " .. row.sid .. " in script order")

		for _, o in ipairs(row.options) do
			replies = replies + 1

			local ok = false

			for b in pairs(branchesOf[row.sid] or {}) do
				for _, succ in ipairs((edges[b] or {})[o[1]] or {}) do
					if succ == dialogOf[o[2]] then
						ok = true
					end
				end
			end

			lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. o[1] .. ": the script leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
		end
	end

	lu.assertEquals(replies, 18, "replies checked against the script")
end

-- AC-5, D-10 (the oracle itself): the NPC animation of every line is the script's doAnimationAction(self, ...) (none for nym_say_no_more, branch 25)
function TestSmugglerTransOracle2:test_every_animation_of_appendix_a_is_the_one_the_script_plays()
	local anims = animationsOf()

	for _, row in ipairs(T.SCREENS) do
		lu.assertNotNil(anims[row.sid], "the script has no line " .. row.sid)
		lu.assertTrue(anims[row.sid][row.animation] == true, "screen '" .. row.id .. "' (" .. row.sid .. "): animation '" .. row.animation .. "' is not among the script's " ..
			table.concat((function() local l = {} for a in pairs(anims[row.sid]) do l[#l + 1] = "'" .. a .. "'" end table.sort(l) return l end)(), ", "))
	end
end

-- AC-5 (the oracle itself): the deferred hub lines are the script's tier 2 / tier 3 / tier 4 branches, and the used ones are not
function TestSmugglerTransOracle2:test_the_deferred_lines_are_the_script_lines_no_appendix_a_screen_uses()
	local dialogs = {}

	for _, row in ipairs(T.SCREENS) do
		dialogs[row.sid] = true
	end

	-- every NPC line of the script is either a screen dialog or a deferred dialog line
	local deferred = setOf(T.DEFERRED_IDS)

	for _, sid in ipairs(GRAPH.order) do
		lu.assertTrue(dialogs[sid] == true or deferred[sid] == true, "script NPC line " .. sid .. " is neither an Appendix A screen nor deferred")
	end

	for _, sid in ipairs({ "s_74bf2381", "s_697e04cf", "s_2d0c7400" }) do
		lu.assertNotNil(GRAPH.nodes[sid], "script entry of the hub line " .. sid)
		lu.assertNil(dialogs[sid], sid .. " is a hub line and must not be a screen of this feature")
	end
end

-- AC-5 (the oracle itself): the text of the %TU / %NU lines (FK-8)
function TestSmugglerTransOracle2:test_the_name_token_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_3ff6efdd:find("%TU", 1, true) ~= nil, true, "s_3ff6efdd carries %TU")

	for _, sid in ipairs({ "s_89b061e3", "s_2a5548e1", "s_ff6979b6" }) do
		lu.assertEquals(TEXT[sid]:find("%NU", 1, true) ~= nil, true, sid .. " carries %NU")
	end

	lu.assertEquals(TEXT.s_a60a995b, "I ran into a problem.", "retry reply")
	lu.assertEquals(TEXT.s_983a902c, "What are you doing here? Didn't I tell you to go to Lok?", "trans_failed")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestSmugglerTransTemplate = {}

function TestSmugglerTransTemplate:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8
function TestSmugglerTransTemplate:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, T.screenIds(), T.TEMPLATE .. ": screen ids (21, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestSmugglerTransTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation (a string, as the other templates)")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-10)")
	end
end

-- AC-5, I-8: the static options in order; there are no conditional links
function TestSmugglerTransTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = { PREFIX .. o[1], o[2] }
		end

		local got = {}

		for i, o in ipairs(byId[row.id].options) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-5, I-8
function TestSmugglerTransTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestSmugglerTransTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, T.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line and reply is a trailing comment
function TestSmugglerTransTemplate:test_every_dialog_line_and_reply_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(T.TEMPLATE_FILE)
	local dialogs, replies = 0, 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			dialogs = dialogs + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_privateer_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		else
			local osid, ocomment = line:match('{%s*"@conversation/tatooine_privateer_trainer_2:(s_[%w_]+)"%s*,%s*"[%w_]+"%s*}%s*,?%s*%-%-%s*(.-)%s*$')

			if osid ~= nil then
				replies = replies + 1
				lu.assertEquals(ocomment, (TEXT[osid]:gsub("%s+$", "")), "trailing comment of the option line for " .. osid)
			elseif line:find("{%s*\"@conversation/tatooine_privateer_trainer_2") then
				lu.fail("option line without the trailing client text: " .. line)
			end
		end
	end

	lu.assertEquals(dialogs, 21, "leftDialog lines with a comment")
	lu.assertEquals(replies, 18, "option lines with a comment")
end

-- Content contract 3: the first line is a header comment, the file registers the template
function TestSmugglerTransTemplate:test_the_template_file_starts_with_a_header_comment_and_registers_through_add_conversation_template()
	local source = readFile(T.TEMPLATE_FILE)
	local first = source:match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "first line of talon_karrde_convo.lua is a header comment (Dravis style)")
	lu.assertNotNil(source:find('addConversationTemplate("talon_karrde_convo_template", talon_karrde_convo_template)', 1, true), "talon_karrde_convo.lua ends with addConversationTemplate")
	lu.assertNotNil(source:find('luaClassHandler = "talonKarrdeConvoHandler"', 1, true), "talon_karrde_convo.lua names its handler")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, I-8)
---------------------------------------------------------------------------------------------

TestSmugglerTransClientStrings = {}

function TestSmugglerTransClientStrings:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestSmugglerTransClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: exactly the 35 used ids, none of the 18 deferred ones
function TestSmugglerTransClientStrings:test_the_sources_use_exactly_the_35_ids_of_appendix_a_and_none_of_the_deferred_ones()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == T.STF then
			used[lit.id] = true
		end
	end

	local got = {}

	for id in pairs(used) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, T.usedIds(), "distinct tatooine_privateer_trainer_2 ids used by the template and handler")

	local hit = {}

	for _, id in ipairs(T.DEFERRED_IDS) do
		if used[id] then
			hit[#hit + 1] = id
		end
	end

	lu.assertEquals(hit, {}, "deferred hub ids that appear in the sources")
end

-- AC-5, I-8: the handler holds no string id literal of its own (it sets no option); the template holds only the file this feature ports
function TestSmugglerTransClientStrings:test_the_handler_holds_no_conversation_string_literal_and_the_template_only_the_karrde_file()
	local handler = readFile(T.HANDLER_FILE)

	lu.assertNil(handler:find("@conversation/", 1, true), "talonKarrdeConvoHandler.lua holds a @conversation/ literal")

	for _, lit in ipairs(CS.literals({ T.TEMPLATE_FILE })) do
		lu.assertEquals(lit.file, T.STF, T.TEMPLATE_FILE .. ":" .. lit.line .. " names another string file")
	end
end

-- AC-5: complete literals only (the ratchet's KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestSmugglerTransClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Karrde sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the ratchet's referenced files include the new file, with the count of the generated fixture
function TestSmugglerTransClientStrings:test_the_ratchet_references_the_karrde_file_with_55_ids()
	local KD = require("space_convo_client_strings_data")

	lu.assertEquals(KD.FIXTURE_COUNTS[T.STF], 55, "FIXTURE_COUNTS[" .. T.STF .. "]")
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")

	local referenced = CS.referencedFiles(CS.spaceConversationSources())
	local found = false

	for _, f in ipairs(referenced) do
		found = found or f == T.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. T.STF)
end

---------------------------------------------------------------------------------------------
-- The player's first name (%TU / %NU)
---------------------------------------------------------------------------------------------

TestSmugglerTransNames = {}

function TestSmugglerTransNames:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5 (Content contract 3, FK-8): lines with %TU or %NU get the pilot's first name through setDialogTextTU
function TestSmugglerTransNames:test_lines_with_the_player_name_get_the_first_name()
	for _, g in ipairs(T.GLOBALS) do
		H.spyOn(T.quest(g), "startQuest") -- the grant screens start the chain; only the dialog parameter is under test here
	end

	for _, id in ipairs({ "dravis_employee", "employee_keep_up", "employee_not_ready", "summons" }) do
		local t = T.drive(T.pilot({}), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the name parameter")
	end
end

-- AC-5: the handler fills the name on every screen it shows (it is harmless on a line without a token)
function TestSmugglerTransNames:test_every_screen_is_shown_with_the_first_name_set()
	for _, g in ipairs(T.GLOBALS) do
		H.spyOn(T.quest(g), "startQuest")
	end

	for _, row in ipairs(T.SCREENS) do
		local t = T.drive(T.pilot({}), row.id)

		lu.assertEquals(t[1].id, row.id, "screen shown")
		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the name parameter")
	end
end

-- AC-5: the shown dialog keeps the template untouched (the handler works on a clone)
function TestSmugglerTransNames:test_showing_a_screen_does_not_change_the_template_screen()
	local before = {}

	for _, s in ipairs(template().screens) do
		before[s.id] = s.leftDialog
	end

	T.drive(T.pilot({}), "dravis_employee")

	for _, s in ipairs(template().screens) do
		lu.assertEquals(s.leftDialog, before[s.id], "screen '" .. s.id .. "': leftDialog in the template")
	end
end
