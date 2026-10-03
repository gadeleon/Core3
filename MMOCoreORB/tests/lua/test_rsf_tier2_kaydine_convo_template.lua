-- Captain Kaydine (RSF tier 2): the SWG story-mission dialogue as data. Template shape, SWG conformance and the handler/template
-- agreement (static part).
-- Spec: .claude/work/rsf-tier2-kaydine-convo/01-spec.md (AC-1, AC-2, AC-10, invariants I-1, I-2, I-3, I-6, I-7).
-- Answer keys: spec Appendix A (rsf_tier2_kaydine_convo_data.lua, copied from the spec) and the SWG java
-- fixtures/script/conversation/naboo_privateer_trainer_2.java parsed by harness/swgjava.lua. Actions are NOT taken from the
-- parser (it misattributes actions on shared lines); payments and grants are behavior, see test_rsf_tier2_kaydine_convo_flow.lua.
-- The training dialogue and the duties are out of scope (D-13, F5): their screens are only checked as unchanged.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_convo_data")
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")

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
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_trainer_2:(s_[%w_]+)$") or nil
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

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
		options[i] = { D.PREFIX .. o[1], o[2] }
	end

	return {
		leftDialog = D.PREFIX .. row.sid,
		stopConversation = row.stop and "true" or "false",
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

local function inScopeSids()
	local set = {}

	for _, row in ipairs(D.ROWS) do
		set[row.sid] = true
	end

	return set
end

---------------------------------------------------------------------------------------------
-- AC-1: template shape
---------------------------------------------------------------------------------------------

TestKaydineConvoTemplate = {}

function TestKaydineConvoTemplate:setUp() H.reset() end

-- AC-1 (sanity of the answer key copied from the spec)
function TestKaydineConvoTemplate:test_appendix_a_has_46_rows_43_new_2_changed_1_kept_and_42_npc_sids()
	local count = { new = 0, chg = 0, kept = 0 }

	for _, row in ipairs(D.ROWS) do
		count[row.status] = count[row.status] + 1
	end

	lu.assertEquals(count, { new = 43, chg = 2, kept = 1 }, "Appendix A rows by status")
	lu.assertEquals(#sortedKeys(inScopeSids()), 42, "distinct NPC sids in Appendix A")
	lu.assertEquals(#sortedKeys(D.KEPT), 32, "kept screens")
	lu.assertEquals(#D.DELETED, 36, "deleted screens")
end

-- AC-1
function TestKaydineConvoTemplate:test_the_template_keeps_its_name_and_handler_and_has_77_screens()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "kaydineConvoHandler", "kaydine_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "kaydine_convo_template: templateType")
	lu.assertEquals(#t.screens, D.SCREEN_COUNT, "kaydine_convo_template: number of screens (70 - 36 + 43)")
end

-- AC-1
function TestKaydineConvoTemplate:test_the_36_story_screens_of_f4_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "kaydine_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1
function TestKaydineConvoTemplate:test_every_new_screen_of_appendix_a_exists_with_its_row()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.status == "new" then
			local screen = byId[row.id]

			lu.assertNotNil(screen, "kaydine_convo_template: missing new screen '" .. row.id .. "'")
			lu.assertEquals(shape(screen), expectedShape(row), "kaydine_convo_template: screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
		end
	end
end

-- AC-1: the static links of the lossy rows (E-1, E-2, E-3, E-5) are the ones in the Appendix
function TestKaydineConvoTemplate:test_the_static_links_of_the_exception_rows_are_the_appendix_links()
	local byId = screensById()
	local expected = {
		{ "mission1_ready", 1, "mission1_offer" }, { "mission2_ready", 1, "mission2_offer" }, { "mission3_ready", 1, "mission3_offer" },
		{ "mission1_brief", 1, "mission1_accept" },
		{ "mission3_reward", 2, "ready_train_pilot" }, { "mission3_reward", 3, "mission3_reward_duty" },
		{ "mission3_reward_duty", 1, "accept_duty_escort" }, { "mission3_reward_duty", 2, "accept_duty_recovery" }, { "mission3_reward_duty", 3, "accept_duty_destroy1" },
	}

	for _, e in ipairs(expected) do
		local screen = byId[e[1]]

		lu.assertNotNil(screen, "screen '" .. e[1] .. "'")
		lu.assertNotNil(screen.options[e[2]], "screen '" .. e[1] .. "': option " .. e[2])
		lu.assertEquals(screen.options[e[2]][2], e[3], "screen '" .. e[1] .. "': link of option " .. e[2])
	end
end

-- AC-1: no screen carries an animation field that Appendix A does not list
function TestKaydineConvoTemplate:test_screens_without_an_appendix_animation_have_no_animation_field()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.animation == "" and byId[row.id] and row.status ~= "kept" then
			lu.assertNil(byId[row.id].animation, "screen '" .. row.id .. "': animation")
		end
	end
end

-- AC-1
function TestKaydineConvoTemplate:test_completed_kaydine_and_finished_tier3_have_the_tier_done_line_and_follow_up()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.status == "chg" then
			lu.assertNotNil(byId[row.id], "screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), expectedShape(row), "screen '" .. row.id .. "'")
		end
	end

	lu.assertEquals(byId.completed_kaydine.options, { { D.PREFIX .. "s_32c46e00", "completed_kaydine_end" } }, "completed_kaydine: options")
	lu.assertEquals(byId.finished_tier3.options, { { D.PREFIX .. "s_32c46e00", "completed_kaydine_end" } }, "finished_tier3: options")
	lu.assertEquals(byId.finished_tier3.leftDialog, D.PREFIX .. "s_2d86b58b", "finished_tier3: leftDialog (unchanged)")
end

-- AC-1, I-7: the gate, duty and training screens equal their definitions at 74247cbede
function TestKaydineConvoTemplate:test_the_32_kept_screens_equal_their_definitions_at_74247cbede()
	local byId = screensById()

	for _, id in ipairs(sortedKeys(D.KEPT)) do
		local screen = byId[id]
		local want = D.KEPT[id]

		lu.assertNotNil(screen, "kept screen '" .. id .. "' is missing")
		lu.assertEquals(shape(screen), { leftDialog = want.leftDialog, stopConversation = want.stopConversation, options = want.options }, "kept screen '" .. id .. "' changed")
	end
end

-- AC-1, I-1
function TestKaydineConvoTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

-- AC-1, I-6: KH's skill branch matches the substring "_train_", so no screen outside the kept training ones may contain it
function TestKaydineConvoTemplate:test_no_new_screen_id_contains_train()
	for _, s in ipairs(template().screens) do
		if D.KEPT[s.id] == nil then
			lu.assertNil(s.id:find("_train_", 1, true), "screen '" .. s.id .. "' contains _train_ (KH treats it as a skill purchase)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: SWG conformance against the parsed java
---------------------------------------------------------------------------------------------

TestKaydineConvoConformance = {}

function TestKaydineConvoConformance:setUp() H.reset() end

-- AC-2 (sanity of the answer key itself)
function TestKaydineConvoConformance:test_answer_key_has_99_npc_lines_and_59_distinct_response_sids()
	lu.assertEquals(#GRAPH.order, 99, "NPC lines parsed from naboo_privateer_trainer_2.java")

	local n = 0

	for _ in pairs(GRAPH.responses) do
		n = n + 1
	end

	lu.assertEquals(n, 59, "distinct response sids in naboo_privateer_trainer_2.java")
end

-- AC-2
function TestKaydineConvoConformance:test_each_of_the_42_appendix_npc_sids_has_at_least_one_screen()
	local seen = {}

	for _, s in ipairs(template().screens) do
		seen[sidOf(s.leftDialog) or ""] = true
	end

	for _, sid in ipairs(sortedKeys(inScopeSids())) do
		lu.assertNotNil(GRAPH.nodes[sid], "answer key: " .. sid .. " is an NPC line of the java")
		lu.assertTrue(seen[sid] == true, "no screen of kaydine_convo_template has NPC line " .. sid)
	end
end

-- The (screen id, option sid) pairs whose static link is an adapted one: E-1, E-3, E-5 (E-2 equals the java default)
local function isException(row, optionSid)
	local e = row.exceptions[optionSid]

	return e ~= nil and e ~= "E-2"
end

-- AC-2, I-2: option sids in order, successor line, end flag and animation of every screen showing an Appendix A line
function TestKaydineConvoConformance:test_every_screen_showing_an_in_scope_line_matches_the_java_graph()
	local byId = screensById()
	local rows = D.rowsById()
	local scope = inScopeSids()
	local checked = 0

	for _, screen in ipairs(template().screens) do
		local sid = sidOf(screen.leftDialog)

		if sid and scope[sid] then
			checked = checked + 1

			local node = GRAPH.nodes[sid]
			-- accept_duty_destroy1 shows s_bb291959 too (I-2 names it); it is a kept screen without an Appendix A row
			local row = rows[screen.id] or (screen.id == "accept_duty_destroy1" and { status = "kept", exceptions = {} } or nil)

			lu.assertNotNil(row, "screen '" .. screen.id .. "' shows in-scope line " .. sid .. " but is not in Appendix A")
			lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. screen.id .. "' (" .. sid .. "): stopConversation == \"true\" iff the java ends the conversation")

			-- new and changed screens carry exactly the java animation; kept duty screens may omit it (F5)
			if row.status ~= "kept" and screen.id ~= "accept_duty_destroy1" then
				lu.assertEquals(screen.animation or "", node.animation, "screen '" .. screen.id .. "' (" .. sid .. "): animation")
			else
				lu.assertTrue(screen.animation == nil or screen.animation == node.animation, "screen '" .. screen.id .. "' (" .. sid .. "): animation is absent or the java one")
			end

			local got = {}

			for i, option in ipairs(screen.options or {}) do
				got[i] = sidOf(option[1])
			end

			lu.assertEquals(got, node.options, "screen '" .. screen.id .. "' (" .. sid .. "): option sids in order")

			for i, optionSid in ipairs(node.options) do
				local target = byId[screen.options[i][2]]

				lu.assertNotNil(target, "screen '" .. screen.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

				local successors = GRAPH.successorsOf(sid, optionSid)

				lu.assertNotNil(successors, "answer key: no successor for " .. sid .. " -> " .. optionSid)

				if not isException(row, optionSid) then
					lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. screen.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
				end
			end
		end
	end

	lu.assertTrue(checked >= 46, "screens showing an in-scope line: " .. checked .. " (Appendix A has 46 rows)")
end

-- AC-2: E-1 still links to a line the java really offers after s_1b428a9f
function TestKaydineConvoConformance:test_the_e1_links_lead_to_successors_the_java_offers_for_that_option()
	local byId = screensById()

	for n = 1, 4 do
		local ready = byId["mission" .. n .. "_ready"]

		lu.assertNotNil(ready, "mission" .. n .. "_ready")

		local successors = GRAPH.successorsOf("s_8b529447", "s_1b428a9f")
		local linked = byId[ready.options[1][2]]
		local offered = {}

		lu.assertNotNil(linked, "mission" .. n .. "_ready: option 1 link")

		for _, s in ipairs(successors) do
			offered[s] = true
		end

		lu.assertTrue(offered[sidOf(linked.leftDialog)] == true, "mission" .. n .. "_ready: option 1 leads to " .. tostring(linked.leftDialog) .. ", not one of the java successors of s_1b428a9f")
	end
end

-- AC-2, I-3
function TestKaydineConvoConformance:test_every_string_of_kaydine_convo_is_in_the_java_except_the_known_foreign_ones()
	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_trainer_2:<sid>")

		if not D.KC_FOREIGN[sid] then
			lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")
		end

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_trainer_2:<sid>")

			if not D.KC_FOREIGN[osid] then
				lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
			end
		end
	end
end

-- AC-2, I-3: every string id KH adds is a response of the java, except the four training options
function TestKaydineConvoConformance:test_every_string_kaydine_convo_handler_adds_is_a_java_response_except_the_training_options()
	local text = readFile(H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua")
	local seen = 0

	for sid in text:gmatch("naboo_privateer_trainer_2:(s_[%w_]+)") do
		seen = seen + 1

		if not D.KH_FOREIGN[sid] then
			lu.assertTrue(GRAPH.responses[sid] == true, "kaydineConvoHandler adds " .. sid .. ", which is not a response of the java")
		end
	end

	-- the handler must still add the M1 gender option and the M3 reward options (Content contract 2)
	lu.assertTrue(seen >= 7, "string ids in kaydineConvoHandler.lua: " .. seen .. " (4 training options + s_242 + s_78 + s_45d20070 + s_6114e8b7)")
end

-- AC-2, I-3: the eight story strings of F4 that are not in the java are gone from both files
function TestKaydineConvoConformance:test_the_eight_f4_story_strings_are_in_neither_file()
	local kc = readFile(H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua")
	local kh = readFile(H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua")

	for _, sid in ipairs(D.F4_STORY_STRINGS) do
		lu.assertNil(kc:find(sid .. '"', 1, true), "kaydine_convo.lua still carries " .. sid)
		lu.assertNil(kh:find(sid .. '"', 1, true), "kaydineConvoHandler.lua still carries " .. sid)
	end
end

---------------------------------------------------------------------------------------------
-- AC-10 (static part), I-6: the handler only names screens of the template
---------------------------------------------------------------------------------------------

TestKaydineHandlerAgreement = {}

function TestKaydineHandlerAgreement:setUp() H.reset() end

local function handlerText()
	return readFile(H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua")
end

-- AC-10, I-6
function TestKaydineHandlerAgreement:test_every_screen_the_handler_returns_or_links_is_a_screen_of_the_template()
	local byId = screensById()
	local text = handlerText()
	local found = 0

	for id in text:gmatch('getScreen%("([%w_]+)"%)') do
		found = found + 1
		lu.assertNotNil(byId[id], "kaydineConvoHandler: getScreen(\"" .. id .. "\") names a screen that is not in kaydine_convo_template")
	end

	for id in text:gmatch('addOption%([^,]+,%s*"([%w_]+)"%)') do
		found = found + 1
		lu.assertNotNil(byId[id], "kaydineConvoHandler: addOption(..., \"" .. id .. "\") links a screen that is not in kaydine_convo_template")
	end

	lu.assertTrue(found >= 20, "screen literals found in kaydineConvoHandler.lua: " .. found)
end

-- AC-10, I-6: every screen id the handler tests exists, except the known accept_duty_destroy2 (F5)
function TestKaydineHandlerAgreement:test_every_screen_id_the_handler_tests_exists_except_accept_duty_destroy2()
	local byId = screensById()

	for id in handlerText():gmatch('screenID == "([%w_]+)"') do
		if id ~= "accept_duty_destroy2" then
			lu.assertNotNil(byId[id], "kaydineConvoHandler tests screenID == \"" .. id .. "\", which is not a screen of kaydine_convo_template")
		end
	end
end

-- AC-10, I-6: none of the 36 deleted ids is left in the handler
function TestKaydineHandlerAgreement:test_no_deleted_screen_id_appears_in_the_handler()
	local text = handlerText()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(text:find('"' .. id .. '"', 1, true), "kaydineConvoHandler still names the deleted screen \"" .. id .. "\"")
	end
end

-- AC-10, I-6: the handler returns each routing screen of Content contract 2 (the first-screen table)
function TestKaydineHandlerAgreement:test_the_handler_returns_the_new_routing_screens()
	local text = handlerText()
	local returned = {}

	for id in text:gmatch('getScreen%("([%w_]+)"%)') do
		returned[id] = true
	end

	for _, id in ipairs({
		"mission4_complete", "mission3_complete", "mission2_reward", "mission1_complete",
		"mission4_failed", "mission4_ready", "mission3_failed", "mission3_ready",
		"mission2_failed", "mission2_ready", "mission1_failed", "mission1_ready", "completed_kaydine", "finished_tier3",
	}) do
		lu.assertTrue(returned[id] == true, "kaydineConvoHandler:getInitialScreen never returns \"" .. id .. "\"")
	end
end

