-- Dulios (RSF tier 3): the SWG dialogue as data. Template shape, SWG conformance, string coverage, the handler tables and the
-- handler/template agreement (static part: text of duliosConvoHandler.lua), CRLF preserved.
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (AC-1, AC-2, AC-9 static scan, invariants I-1, I-2, I-3, I-7, D-4, D-10, E-1).
-- Answer keys: spec Appendix A (rsf_tier3_dulios_convo_data.lua, copied from the spec; the 9 kept screens copied from commit 09ac145b8e)
-- and the SWG java fixtures/script/conversation/naboo_privateer_tier3.java parsed by harness/swgjava.lua. The parser's action attribution
-- is not used: payments, starts and grants are behavior, see the flow and sweep test files.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier3_dulios_convo_data")
local DS = require("rsf_tier3_dulios_client_strings_data") -- space-convo-client-strings-dulios: D.TWIN, Appendix D (the tests it supersedes say so below)
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier3.java")

local DC_PATH = H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/dulios_convo.lua"
local DH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/duliosConvoHandler.lua"

local function readFile(path)
	local f = assert(io.open(path, "rb"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function template()
	local t = H.conversationTemplateTable(D.TEMPLATE)

	lu.assertNotNil(t, D.TEMPLATE .. " is not registered via addConversationTemplate")
	return t
end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = s
	end

	return byId
end

local function sidOf(text)
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_tier3:(s_[%w_]+)$") or nil
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

local function count(set)
	local n = 0

	for _ in pairs(set) do
		n = n + 1
	end

	return n
end

local function rowsById()
	local byId = {}

	for _, row in ipairs(D.ROWS) do
		byId[row.id] = row
	end

	return byId
end

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

-- The pre-NGE id a T3 sid is shown as (space-convo-client-strings-dulios I-4): the twin of an NGE-numbered sid, every other sid itself
local function twin(sid) return DS.TWIN[sid] or sid end

-- The fields a screen definition is compared on
local function shape(screen)
	local options = {}

	for i, o in ipairs(screen.options or {}) do
		options[i] = { o[1], o[2] }
	end

	return { leftDialog = screen.leftDialog, stopConversation = screen.stopConversation, animation = screen.animation, options = options }
end

local function expectedShape(row)
	local options = {}

	for i, o in ipairs(row.options) do
		options[i] = { D.PREFIX .. twin(o[1]), o[2] }
	end

	return {
		leftDialog = D.PREFIX .. twin(row.sid),
		stopConversation = row.stop and "true" or "false",
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

local function handlerText() return readFile(DH_PATH) end

local function handler()
	return H.expectGlobal("duliosConvoHandler", "Dulios conversation handler (duliosConvoHandler.lua)")
end

---------------------------------------------------------------------------------------------
-- The answer key itself
---------------------------------------------------------------------------------------------

TestDuliosConvoAnswerKey = {}

function TestDuliosConvoAnswerKey:setUp() H.reset() end

-- AC-1, AC-2 (sanity of the key copied from the spec)
function TestDuliosConvoAnswerKey:test_appendix_a_has_150_t3_rows_134_new_15_changed_1_kept_and_150_distinct_npc_sids()
	local status, sids = { new = 0, chg = 0, kept = 0 }, {}

	for _, row in ipairs(D.ROWS) do
		status[row.status] = status[row.status] + 1
		sids[row.sid] = true
	end

	lu.assertEquals(status, { new = 134, chg = 15, kept = 1 }, "Appendix A rows by status")
	lu.assertEquals(count(sids), 150, "distinct NPC sids in Appendix A")
	lu.assertEquals(count(D.KEPT), 9, "kept screens")
	lu.assertEquals(#D.DELETED, 28, "deleted screens")
	lu.assertEquals(D.SCREEN_COUNT, 158, "screen count")
	lu.assertEquals(150 + 8, D.SCREEN_COUNT, "150 java rows + the 8 Core3 training screens")
end

-- AC-2: the java fixture is the file the spec cites
function TestDuliosConvoAnswerKey:test_the_java_fixture_parses_into_154_npc_lines_and_133_response_sids()
	lu.assertEquals(#GRAPH.order, 154, "NPC lines parsed from naboo_privateer_tier3.java")
	lu.assertEquals(count(GRAPH.responses), 133, "distinct response sids in naboo_privateer_tier3.java")
end

-- AC-2: the sids the port leaves out are exactly the four training lines (D-4)
function TestDuliosConvoAnswerKey:test_the_java_npc_lines_not_in_appendix_a_are_exactly_s_369_to_s_372()
	local inRows, missing = {}, {}

	for _, row in ipairs(D.ROWS) do
		inRows[row.sid] = true
	end

	for _, sid in ipairs(GRAPH.order) do
		if not inRows[sid] then
			missing[#missing + 1] = sid
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, D.UNUSED_NPC, "java NPC lines that have no Appendix A row")
end

-- AC-2 (key against the java, independent of the production files): the spec table is what the java says except E-1
function TestDuliosConvoAnswerKey:test_appendix_a_agrees_with_the_java_except_e1()
	local byId = rowsById()

	for _, row in ipairs(D.ROWS) do
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "appendix row '" .. row.id .. "': " .. row.sid .. " is an NPC line of the java")
		lu.assertEquals(row.animation, node.animation, "appendix row '" .. row.id .. "': animation")

		if D.EXCEPTIONS[row.id] == "E-1" then
			lu.assertEquals(node.options, { "s_368" }, "appendix row '" .. row.id .. "': java offers the one reply s_368 (E-1)")
			lu.assertEquals(row.options, {}, "appendix row '" .. row.id .. "': template options are empty (E-1)")
			lu.assertFalse(row.stop, "appendix row '" .. row.id .. "': the reward line does not end the conversation")
		else
			lu.assertEquals(row.stop, node.isEnd, "appendix row '" .. row.id .. "': end flag")

			local got = {}

			for i, o in ipairs(row.options) do
				got[i] = o[1]
			end

			lu.assertEquals(got, node.options, "appendix row '" .. row.id .. "': option sids in order")

			for _, o in ipairs(row.options) do
				local successors = GRAPH.successorsOf(row.sid, o[1])

				lu.assertNotNil(successors, "appendix row '" .. row.id .. "': java successor of " .. o[1])

				local target = byId[o[2]]

				lu.assertNotNil(target, "appendix row '" .. row.id .. "': link '" .. o[2] .. "' is an appendix row")
				lu.assertEquals(target.sid, successors[#successors], "appendix row '" .. row.id .. "' option " .. o[1] .. " -> java default successor")
			end
		end
	end
end

-- Content contract 2: the handler tables are derived from the rows' actions
function TestDuliosConvoAnswerKey:test_the_start_and_pay_rows_are_the_handler_tables()
	local starts, pays = {}, {}

	for _, row in ipairs(D.ROWS) do
		if row.start then
			starts[row.id] = row.start
		end

		if row.pay then
			pays[row.id] = row.pay
		end
	end

	lu.assertEquals(starts, D.START_SCREENS, "rows marked start vs START_SCREENS")
	lu.assertEquals(pays, D.REWARD_SCREENS, "rows marked pay vs REWARD_SCREENS")
	lu.assertEquals(count(D.START_SCREENS), 26, "start screens")

	for n = 1, 4 do
		local ids = {}

		for id, m in pairs(D.START_SCREENS) do
			if m == n then
				ids[#ids + 1] = id
			end
		end

		table.sort(ids)

		local want = {}

		for _, id in ipairs(D.OFFER_STARTS[n]) do want[#want + 1] = id end
		for _, id in ipairs(D.RETRY_STARTS[n]) do want[#want + 1] = id end

		table.sort(want)
		lu.assertEquals(ids, want, "start screens of mission " .. n)
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: template shape
---------------------------------------------------------------------------------------------

TestDuliosConvoTemplate = {}

function TestDuliosConvoTemplate:setUp() H.reset() end

-- AC-1
function TestDuliosConvoTemplate:test_the_template_keeps_its_name_handler_and_initial_screen_and_has_158_screens()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "duliosConvoHandler", "dulios_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "dulios_convo_template: templateType")
	lu.assertEquals(t.initialScreen, "", "dulios_convo_template: initialScreen")
	lu.assertEquals(#t.screens, D.SCREEN_COUNT, "dulios_convo_template: number of screens (52 - 28 + 134)")
end

-- AC-1
function TestDuliosConvoTemplate:test_the_28_screens_of_the_old_arrangement_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "dulios_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1
function TestDuliosConvoTemplate:test_every_new_screen_of_appendix_a_exists_with_its_row()
	local byId = screensById()
	local seen = 0

	for _, row in ipairs(D.ROWS) do
		if row.status == "new" then
			seen = seen + 1
			lu.assertNotNil(byId[row.id], "dulios_convo_template: missing new screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), expectedShape(row), "dulios_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
		end
	end

	lu.assertEquals(seen, 134, "new screens checked")
end

-- AC-1
function TestDuliosConvoTemplate:test_every_changed_screen_of_appendix_a_equals_its_row()
	local byId = screensById()
	local seen = 0

	for _, row in ipairs(D.ROWS) do
		if row.status == "chg" then
			seen = seen + 1
			lu.assertNotNil(byId[row.id], "dulios_convo_template: missing changed screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), expectedShape(row), "dulios_convo_template: changed screen '" .. row.id .. "'")
		end
	end

	lu.assertEquals(seen, 15, "changed screens checked")
end

-- AC-1, E-1: the four reward screens have empty template options and do not end the conversation (DuH builds the options)
function TestDuliosConvoTemplate:test_the_four_reward_screens_have_empty_template_options_and_stop_false()
	local byId = screensById()

	for id in pairs(D.REWARD_SCREENS) do
		lu.assertNotNil(byId[id], "dulios_convo_template: missing reward screen '" .. id .. "'")
		lu.assertEquals(byId[id].options, {}, id .. ": template options (E-1)")
		lu.assertEquals(byId[id].stopConversation, "false", id .. ": stopConversation")
	end
end

-- AC-1: the 9 screens listed as kept equal their definitions at 09ac145b8e (fields, not text: the file is CRLF)
function TestDuliosConvoTemplate:test_the_9_kept_screens_equal_their_definitions_at_09ac145b8e()
	local byId = screensById()

	for _, id in ipairs(sortedKeys(D.KEPT)) do
		local want = D.KEPT[id]

		lu.assertNotNil(byId[id], "kept screen '" .. id .. "' is missing")
		lu.assertEquals(shape(byId[id]), { leftDialog = want.leftDialog, stopConversation = want.stopConversation, animation = nil, options = want.options }, "kept screen '" .. id .. "' changed")
	end
end

-- AC-1: no screen carries an animation field that Appendix A does not list
function TestDuliosConvoTemplate:test_screens_without_an_appendix_animation_have_no_animation_field()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.animation == "" and byId[row.id] then
			lu.assertNil(byId[row.id].animation, "screen '" .. row.id .. "': animation")
		end
	end

	for id in pairs(D.KEPT) do
		if byId[id] then
			lu.assertNil(byId[id].animation, "kept screen '" .. id .. "': animation")
		end
	end
end

-- AC-1, I-1
function TestDuliosConvoTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

-- AC-1, I-1, superseded by space-convo-client-strings-dulios (Appendix C, AC-3, Appendix D): a pre-NGE line may stand on several screens (the CRC id of a text
-- is shared by every copy, FD-2); the multiplicities are exactly Appendix D's, every other leftDialog is on one screen
function TestDuliosConvoTemplate:test_left_dialogs_repeat_exactly_as_appendix_d_says_and_nowhere_else()
	local owners = {}

	for _, s in ipairs(template().screens) do
		owners[s.leftDialog] = owners[s.leftDialog] or {}
		table.insert(owners[s.leftDialog], s.id)
	end

	for dialog, ids in pairs(owners) do
		table.sort(ids)

		local sid = sidOf(dialog)

		lu.assertEquals(#ids, DS.LEFT_COUNTS[sid] or 1, "number of screens showing " .. dialog .. ": " .. table.concat(ids, ","))

		if sid == "s_4fc6a099" then
			lu.assertEquals(ids, { "completed_dulios", "train_components_final", "train_programming_final", "train_techniques_final", "train_warships_final" }, "screens showing s_4fc6a099")
		elseif sid == "s_e1e07205" then
			lu.assertEquals(ids, { "m1_100", "m1_118", "m1_139", "m1_165", "m1_182", "m1_70", "m1_78", "m1_e1e07205" }, "screens showing s_e1e07205")
		end
	end

	for sid in pairs(DS.LEFT_COUNTS) do
		lu.assertNotNil(owners[D.PREFIX .. sid], "Appendix D id " .. sid .. " is shown on no screen")
	end
end

-- AC-1: every template screen is an Appendix A row or one of the 8 kept training screens, nothing else
function TestDuliosConvoTemplate:test_the_template_has_exactly_the_appendix_screens_and_the_training_screens()
	local rows = rowsById()
	local extra = {}

	for _, s in ipairs(template().screens) do
		if rows[s.id] == nil and D.TRAIN_KEPT[s.id] == nil then
			extra[#extra + 1] = s.id
		end
	end

	table.sort(extra)
	lu.assertEquals(extra, {}, "template screens that are neither an Appendix A row nor a kept training screen")
end

-- AC-1 / Content contract 1: DuC keeps CRLF line endings (D-10), DuH too
function TestDuliosConvoTemplate:test_dulios_convo_and_its_handler_keep_crlf_line_endings()
	for name, path in pairs({ ["dulios_convo.lua"] = DC_PATH, ["duliosConvoHandler.lua"] = DH_PATH }) do
		local text = readFile(path)
		local bare = select(2, text:gsub("[^\r]\n", ""))
		local crlf = select(2, text:gsub("\r\n", ""))

		lu.assertTrue(crlf > 100, name .. ": CRLF line ends: " .. crlf)
		lu.assertEquals(bare, 0, name .. ": lines ending in a bare LF")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: SWG conformance against the parsed java
---------------------------------------------------------------------------------------------

TestDuliosConvoConformance = {}

function TestDuliosConvoConformance:setUp() H.reset() end

-- AC-2, superseded by space-convo-client-strings-dulios (Appendix C, I-4): each of the 150 Appendix A rows has exactly one screen by id, and the line it
-- shows (the twin of its sid) is on 1 + (number of NGE-numbered rows mapped onto it) screens other than the 8 training screens (Appendix D)
function TestDuliosConvoConformance:test_each_of_the_150_appendix_rows_has_exactly_one_screen_and_each_line_is_shown_on_one_screen_per_row_mapped_onto_it()
	local shown, byId = {}, {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = (byId[s.id] or 0) + 1

		local sid = sidOf(s.leftDialog)

		if sid and D.TRAIN_KEPT[s.id] == nil then
			shown[sid] = (shown[sid] or 0) + 1
		end
	end

	local want = {}

	for _, row in ipairs(D.ROWS) do
		want[twin(row.sid)] = (want[twin(row.sid)] or 0) + 1
	end

	for _, row in ipairs(D.ROWS) do
		lu.assertEquals(byId[row.id], 1, "number of screens with id '" .. row.id .. "'")
		lu.assertEquals(shown[twin(row.sid)] or 0, want[twin(row.sid)], "number of screens (other than the 8 training screens) showing " .. twin(row.sid) .. " (appendix row '" .. row.id .. "', key " .. row.sid .. ")")
	end
end

-- AC-2, I-2, superseded by space-convo-client-strings-dulios (Appendix C, I-4, AC-6): option sids in order, successor line, end flag and animation of every
-- Appendix A screen, against the java graph with every sid mapped through the twin table
function TestDuliosConvoConformance:test_every_appendix_screen_matches_the_java_graph_modulo_the_twin_table_except_e1()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(screen, "screen '" .. row.id .. "' is missing")
		lu.assertNotNil(node, "answer key: " .. row.sid)
		checked = checked + 1

		lu.assertEquals(sidOf(screen.leftDialog), twin(row.sid), "screen '" .. row.id .. "': NPC line (twin of " .. row.sid .. ")")
		lu.assertEquals(screen.animation or "", node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation (java)")

		if D.EXCEPTIONS[row.id] == nil then
			lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")

			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			local wantOptions = {}

			for i, osid in ipairs(node.options) do
				wantOptions[i] = twin(osid)
			end

			lu.assertEquals(got, wantOptions, "screen '" .. row.id .. "' (" .. row.sid .. "): option sids in order (twins)")

			for i, optionSid in ipairs(node.options) do
				local target = byId[screen.options[i][2]]

				lu.assertNotNil(target, "screen '" .. row.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

				local successors = GRAPH.successorsOf(row.sid, optionSid)

				lu.assertNotNil(successors, "answer key: no successor for " .. row.sid .. " -> " .. optionSid)
				lu.assertEquals(sidOf(target.leftDialog), twin(successors[#successors]), "screen '" .. row.id .. "' option " .. optionSid .. " -> successor NPC line (java default, twin)")
			end
		else
			-- E-1: the java's one reply s_368 is not ported; the template options are empty and the line does not end the conversation
			lu.assertEquals(screen.options, {}, "screen '" .. row.id .. "': template options (E-1)")
			lu.assertFalse(node.isEnd, "answer key: " .. row.sid .. " offers a reply in the java")
		end
	end

	lu.assertEquals(checked, 150, "screens checked against the java")
end

-- AC-2: s_368 and s_369-s_372 appear nowhere (template, handler)
function TestDuliosConvoConformance:test_the_unported_training_strings_s_368_to_s_372_appear_nowhere()
	local files = { ["dulios_convo.lua"] = readFile(DC_PATH), ["duliosConvoHandler.lua"] = handlerText() }

	for name, text in pairs(files) do
		for _, sid in ipairs({ "s_368", "s_369", "s_370", "s_371", "s_372" }) do
			lu.assertNil(text:find("tier3:" .. sid .. "%f[^%w_]"), name .. " carries the unported " .. sid)
		end
	end
end

-- AC-2, I-3: every string of dulios_convo.lua is a java line or response, except the 8 Core3 training sids
function TestDuliosConvoConformance:test_every_string_of_dulios_convo_is_in_the_java_except_the_8_core3_training_sids()
	local foreignOpt, foreignLeft = {}, {}

	for _, sid in ipairs(D.FOREIGN_OPTION_SIDS) do foreignOpt[sid] = true end
	for _, sid in ipairs(D.FOREIGN_LEFT_SIDS) do foreignLeft[sid] = true end

	local sawLeft = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_tier3:<sid>")

		if foreignLeft[sid] then
			sawLeft[sid] = true
		else
			lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")
		end

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_tier3:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
		end
	end

	lu.assertEquals(sortedKeys(sawLeft), D.FOREIGN_LEFT_SIDS, "Core3 training leftDialog sids kept in the template")
end

-- AC-2, I-3: every string id the handler names (bare, as in TRAIN_CHOICES, or with the conversation prefix) is a java response
-- or one of the 4 Core3 training choice options, and all four of those are kept
function TestDuliosConvoConformance:test_every_string_the_handler_names_is_a_java_response_or_a_core3_training_choice()
	local foreign, seenForeign = {}, {}
	local text = handlerText()

	for _, sid in ipairs(D.FOREIGN_OPTION_SIDS) do foreign[sid] = true end

	local sids = {}

	for sid in text:gmatch("naboo_privateer_tier3:(s_[%w_]+)") do sids[#sids + 1] = sid end
	for sid in text:gmatch('"(s_[%w_]+)"') do sids[#sids + 1] = sid end

	for _, sid in ipairs(sids) do
		if foreign[sid] then
			seenForeign[sid] = true
		else
			lu.assertTrue(GRAPH.responses[sid] == true, "duliosConvoHandler carries " .. sid .. ", which is neither a response of the java nor a Core3 training choice")
		end
	end

	lu.assertEquals(sortedKeys(seenForeign), D.FOREIGN_OPTION_SIDS, "Core3 training choice sids kept in the handler")
end

-- AC-2, I-3, superseded by space-convo-client-strings-dulios (Appendix C, AC-6): 111 of 154 NPC lines and 95 of 133 responses are used; the unused are the
-- 39 NPC and 37 reply keys of the twin table, plus s_369-s_372 and s_368
function TestDuliosConvoConformance:test_the_files_use_111_of_154_java_npc_lines_and_95_of_133_responses()
	local usedNpc, usedResp = {}, {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid and GRAPH.nodes[sid] then
			usedNpc[sid] = true
		end

		for _, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			if osid and GRAPH.responses[osid] then
				usedResp[osid] = true
			end
		end
	end

	for sid in handlerText():gmatch("naboo_privateer_tier3:(s_[%w_]+)") do
		if GRAPH.responses[sid] then
			usedResp[sid] = true
		end
	end

	local unusedNpc, unusedResp = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if not usedNpc[sid] then
			unusedNpc[#unusedNpc + 1] = sid
		end
	end

	for sid in pairs(GRAPH.responses) do
		if not usedResp[sid] then
			unusedResp[#unusedResp + 1] = sid
		end
	end

	table.sort(unusedNpc)
	table.sort(unusedResp)

	local wantNpc, wantResp = {}, {}

	for _, sid in ipairs(D.UNUSED_NPC) do wantNpc[#wantNpc + 1] = sid end
	for _, sid in ipairs(D.UNUSED_RESP) do wantResp[#wantResp + 1] = sid end

	for nge in pairs(DS.TWIN) do
		if GRAPH.nodes[nge] then
			wantNpc[#wantNpc + 1] = nge
		elseif GRAPH.responses[nge] then
			wantResp[#wantResp + 1] = nge
		else
			lu.fail("twin key " .. nge .. " is neither an NPC line nor a response of the java")
		end
	end

	table.sort(wantNpc)
	table.sort(wantResp)
	lu.assertEquals(#wantNpc, 43, "answer key: unused NPC lines (39 twin keys + s_369-s_372)")
	lu.assertEquals(#wantResp, 38, "answer key: unused responses (37 twin keys + s_368)")
	lu.assertEquals(unusedNpc, wantNpc, "java NPC lines used by neither file: unused ones")
	lu.assertEquals(unusedResp, wantResp, "java responses used by neither file: unused ones")
	lu.assertEquals(count(usedNpc), 111, "java NPC lines used")
	lu.assertEquals(count(usedResp), 95, "java responses used")
end

---------------------------------------------------------------------------------------------
-- AC-9 (static part): the handler tables and the handler/template agreement
---------------------------------------------------------------------------------------------

TestDuliosConvoHandlerAgreement = {}

function TestDuliosConvoHandlerAgreement:setUp() H.reset() end

-- Content contract 2 / AC-9, superseded by space-convo-client-strings-dulios (Appendix C, AC-2): the binding handler fields; TRAIN_CHOICES holds complete literals
function TestDuliosConvoHandlerAgreement:test_the_handler_defines_reward_screens_start_screens_and_train_choices_as_specified()
	local dh = handler()
	local choices = {}

	for i, c in ipairs(D.TRAIN_CHOICES) do
		choices[i] = { c[1], D.PREFIX .. c[2], c[3] }
	end

	lu.assertEquals(dh.REWARD_SCREENS, D.REWARD_SCREENS, "duliosConvoHandler.REWARD_SCREENS")
	lu.assertEquals(dh.START_SCREENS, D.START_SCREENS, "duliosConvoHandler.START_SCREENS")
	lu.assertEquals(dh.TRAIN_CHOICES, choices, "duliosConvoHandler.TRAIN_CHOICES (complete string ids)")
end

-- AC-9, I-7: every id the handler returns, links, lists or compares is a template screen
function TestDuliosConvoHandlerAgreement:test_every_screen_id_the_handler_names_is_a_template_screen_and_no_deleted_id_remains()
	local byId = screensById()
	local text = handlerText()
	local seen = 0

	for id in text:gmatch('getScreen%("([%w_]+)"%)') do
		seen = seen + 1
		lu.assertNotNil(byId[id], "duliosConvoHandler returns getScreen(\"" .. id .. "\"), which is not in dulios_convo_template")
	end

	for id in text:gmatch('addOption%([^,]+,%s*"([%w_]+)"%)') do
		seen = seen + 1
		lu.assertNotNil(byId[id], "duliosConvoHandler links addOption(..., \"" .. id .. "\"), which is not in dulios_convo_template")
	end

	for id in text:gmatch('screenID == "([%w_]+)"') do
		seen = seen + 1
		lu.assertNotNil(byId[id], "duliosConvoHandler compares screenID == \"" .. id .. "\", which is not in dulios_convo_template")
	end

	lu.assertTrue(seen >= 9, "screen id literals found in duliosConvoHandler.lua: " .. seen)

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(text:find('"' .. id .. '"', 1, true), "duliosConvoHandler.lua still names the deleted screen \"" .. id .. "\"")
	end
end

-- AC-9, I-7: the three handler tables only name template screens (and the _final forms)
function TestDuliosConvoHandlerAgreement:test_the_handler_tables_only_name_template_screens()
	local byId = screensById()
	local dh = handler()

	for id, n in pairs(dh.REWARD_SCREENS or {}) do
		lu.assertNotNil(byId[id], "REWARD_SCREENS key '" .. id .. "' is not a template screen")
		lu.assertTrue(n >= 1 and n <= 4, "REWARD_SCREENS['" .. id .. "'] = " .. tostring(n))
	end

	for id, n in pairs(dh.START_SCREENS or {}) do
		lu.assertNotNil(byId[id], "START_SCREENS key '" .. id .. "' is not a template screen")
		lu.assertTrue(n >= 1 and n <= 4, "START_SCREENS['" .. id .. "'] = " .. tostring(n))
	end

	lu.assertEquals(#(dh.TRAIN_CHOICES or {}), 4, "TRAIN_CHOICES entries")

	for _, entry in ipairs(dh.TRAIN_CHOICES or {}) do
		lu.assertNotNil(byId[entry[3]], "TRAIN_CHOICES screen '" .. tostring(entry[3]) .. "' is not a template screen")
		lu.assertNotNil(byId[tostring(entry[3]) .. "_final"], "TRAIN_CHOICES screen '" .. tostring(entry[3]) .. "_final' is not a template screen")
	end
end

-- AC-9, I-4, I-5, I-6: getInitialScreen neither grants, pays nor starts anything
function TestDuliosConvoHandlerAgreement:test_get_initial_screen_does_not_pay_start_or_grant()
	local text = handlerText()
	local first = text:find("function duliosConvoHandler:getInitialScreen", 1, true)
	local second = text:find("function duliosConvoHandler:runScreenHandlers", 1, true)

	lu.assertNotNil(first, "duliosConvoHandler:getInitialScreen is defined")
	lu.assertNotNil(second, "duliosConvoHandler:runScreenHandlers is defined")

	local fn = text:sub(first, second - 1)

	for _, needle in ipairs({ "grantSpaceSkill", "awardSkill", "rewardPlayer", "startQuest", "startSpaceQuestChain", "setQuestStatus" }) do
		lu.assertNil(fn:find(needle, 1, true), "duliosConvoHandler:getInitialScreen contains '" .. needle .. "'")
	end
end
