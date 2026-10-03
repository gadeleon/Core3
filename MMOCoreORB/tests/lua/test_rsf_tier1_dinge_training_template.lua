-- Dinge (RSF tier 1) SWG training: template shape and SWG conformance of the 12 training screens, the 60 screens that must not move,
-- and the string coverage of both files.
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (AC-1, AC-2, invariants I-1, I-2, I-3, I-7; Appendix A).
-- Answer keys: rsf_tier1_dinge_training_data.lua (Appendix A, copied from the spec), rsf_tier1_dinge_convo_data.lua (the 60 F7 rows) and the
-- SWG java fixtures/script/conversation/naboo_privateer_trainer_1.java parsed by harness/swgjava.lua. Behavior is in
-- test_rsf_tier1_dinge_training_routing.lua, _purchase.lua and _handler.lua.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")
local C = require("rsf_tier1_dinge_convo_data")
local G = require("rsf_gate_screens_data")
local Swgjava = require("harness.swgjava")

T.load()

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_1.java")

local DC_PATH = H.SCRIPTS .. "mobile/conversations/space/neutral/rsf_squadron/dinge_convo.lua"
local DH_PATH = H.SCRIPTS .. "screenplays/space/conversations/neutral/rsf_squadron/dingeConvoHandler.lua"

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
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
	return type(text) == "string" and text:match("^@conversation/naboo_privateer_trainer_1:(s_[%w_]+)$") or nil
end

local function sortedKeys(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

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

local function trainingRows()
	local byId = {}

	for _, row in ipairs(D.ROWS) do
		byId[row.id] = row
	end

	return byId
end

---------------------------------------------------------------------------------------------
-- The answer key itself
---------------------------------------------------------------------------------------------

TestDingeTrainingAnswerKey = {}

function TestDingeTrainingAnswerKey:setUp() H.reset() end

-- AC-1, AC-2 (sanity of the key copied from the spec)
function TestDingeTrainingAnswerKey:test_appendix_a_has_12_rows_11_new_1_changed_and_12_distinct_npc_sids()
	local count, sids = { new = 0, chg = 0 }, {}

	for _, row in ipairs(D.ROWS) do
		count[row.status] = count[row.status] + 1
		sids[row.sid] = true
	end

	lu.assertEquals(count, { new = 11, chg = 1 }, "Appendix A rows by status")
	lu.assertEquals(#sortedKeys(sids), 12, "distinct NPC sids in Appendix A")
	lu.assertEquals(#D.DELETED, 6, "deleted screens")
	lu.assertEquals(#C.ROWS, 60, "convo Appendix A rows")
	lu.assertEquals(D.SCREEN_COUNT, #C.ROWS + #D.ROWS, "60 story screens + 12 training screens")
end

-- AC-2: the answer key agrees with the java (independent of the production files), except the documented E-T1
function TestDingeTrainingAnswerKey:test_appendix_a_agrees_with_the_java_except_e_t1()
	local rows = trainingRows()

	for _, row in ipairs(D.ROWS) do
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "appendix row '" .. row.id .. "': " .. row.sid .. " is an NPC line of the java")
		lu.assertEquals(row.stop, node.isEnd, "appendix row '" .. row.id .. "': end flag")
		lu.assertEquals(row.animation, node.animation, "appendix row '" .. row.id .. "': animation")

		local got = {}

		for i, o in ipairs(row.options) do
			got[i] = o[1]
		end

		lu.assertEquals(got, node.options, "appendix row '" .. row.id .. "': option sids in order")

		for _, o in ipairs(row.options) do
			local successors = GRAPH.successorsOf(row.sid, o[1])

			lu.assertNotNil(successors, "appendix row '" .. row.id .. "': java successor of " .. o[1])
			lu.assertNotNil(rows[o[2]], "appendix row '" .. row.id .. "': link '" .. o[2] .. "' is an appendix row")
			lu.assertEquals(rows[o[2]].sid, successors[#successors], "appendix row '" .. row.id .. "' option " .. o[1] .. " -> java default successor")

			if D.EXCEPT[row.id .. "|" .. o[1]] then
				-- E-T1: the java successor is conditional: the first missing skill, in this order
				lu.assertEquals(successors, { "s_144", "s_145", "s_146", "s_147" }, "E-T1: java successors of s_143")
			else
				lu.assertEquals(#successors, 1, "appendix row '" .. row.id .. "' option " .. o[1] .. ": one successor")
			end
		end
	end
end

-- AC-2: the 18 newly used sids exist in the java and are not in the 60 story rows
function TestDingeTrainingAnswerKey:test_the_18_new_sids_are_java_strings_no_story_screen_uses()
	local story = {}

	for _, row in ipairs(C.ROWS) do
		story[row.sid] = true

		for _, o in ipairs(row.options) do
			story[o[1]] = true
		end
	end

	lu.assertEquals(#D.NEW_SIDS, 18, "newly used sids")

	for _, sid in ipairs(D.NEW_SIDS) do
		lu.assertTrue(GRAPH.nodes[sid] ~= nil or GRAPH.responses[sid] == true, sid .. " is a string of the java")
		lu.assertNil(story[sid], sid .. " is already used by a story screen")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: template shape
---------------------------------------------------------------------------------------------

TestDingeTrainingTemplate = {}

function TestDingeTrainingTemplate:setUp() H.reset() end

-- AC-1
function TestDingeTrainingTemplate:test_the_template_has_73_screens_and_keeps_its_name_handler_and_initial_screen()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "dingeConvoHandler", "dinge_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "dinge_convo_template: templateType")
	lu.assertEquals(t.initialScreen, "", "dinge_convo_template: initialScreen")
	lu.assertEquals(#t.screens, 73, "dinge_convo_template: number of screens (67 - 6 + 11, + non_rsf_duty_offer from rsf-gate-screens)")
end

-- AC-1
function TestDingeTrainingTemplate:test_the_6_old_training_screens_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "dinge_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1: more_training and the 11 new screens equal Appendix A, static links included
function TestDingeTrainingTemplate:test_more_training_and_the_11_new_screens_equal_appendix_a()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		lu.assertNotNil(byId[row.id], "dinge_convo_template: missing training screen '" .. row.id .. "'")
		lu.assertEquals(shape(byId[row.id]), expectedShape(row), "dinge_convo_template: training screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
	end
end

-- AC-1: no training screen carries an animation field that Appendix A does not list
function TestDingeTrainingTemplate:test_training_screens_without_an_appendix_animation_have_no_animation_field()
	local byId = screensById()

	for _, row in ipairs(D.ROWS) do
		if row.animation == "" and byId[row.id] then
			lu.assertNil(byId[row.id].animation, "screen '" .. row.id .. "': animation")
		end
	end
end

-- AC-1, I-7: the 60 story screens still match the convo Appendix A rows
function TestDingeTrainingTemplate:test_the_60_story_screens_still_match_the_convo_appendix_a_rows()
	local byId = screensById()

	for _, row in ipairs(C.ROWS) do
		local want = {
			leftDialog = C.PREFIX .. row.sid,
			stopConversation = row.stop and "true" or "false",
			animation = row.animation ~= "" and row.animation or nil,
			options = {},
		}

		for i, o in ipairs(row.options) do
			want.options[i] = { C.PREFIX .. o[1], o[2] }
		end

		lu.assertNotNil(byId[row.id], "story screen '" .. row.id .. "' is missing")

		if row.id ~= "yes_enlist" then -- E-2: the handler builds this screen's option
			lu.assertEquals(shape(byId[row.id]), want, "story screen '" .. row.id .. "' changed")
		end
	end
end

-- AC-1, I-7: the 9 kept literals (rebel_pilot and imperial_pilot as rsf-gate-screens defined them, AC-5: 7 literally unchanged)
function TestDingeTrainingTemplate:test_the_9_kept_screens_equal_their_literals_after_rsf_gate_screens()
	local byId = screensById()
	local n = 0

	for _, id in ipairs(sortedKeys(C.KEPT)) do
		local want = C.KEPT[id]

		n = n + 1
		lu.assertNotNil(byId[id], "kept screen '" .. id .. "' is missing")
		lu.assertEquals(shape(byId[id]), { leftDialog = want.leftDialog, stopConversation = want.stopConversation, animation = want.animation, options = want.options }, "kept screen '" .. id .. "' changed")
	end

	lu.assertEquals(n, 9, "kept screens")
end

-- AC-1: the template has exactly the 60 story screens, the 12 training screens and (rsf-gate-screens) non_rsf_duty_offer
function TestDingeTrainingTemplate:test_the_template_has_exactly_the_60_story_12_training_and_the_gate_screen()
	local known = {}

	for _, row in ipairs(C.ROWS) do
		known[row.id] = true
	end

	for _, row in ipairs(D.ROWS) do
		known[row.id] = true
	end

	for _, id in ipairs(G.DINGE_NEW) do
		known[id] = true
	end

	local extra = {}

	for _, s in ipairs(template().screens) do
		if not known[s.id] then
			extra[#extra + 1] = s.id
		end
	end

	table.sort(extra)
	lu.assertEquals(extra, {}, "template screens that are in neither Appendix A")
end

-- AC-1, I-1
function TestDingeTrainingTemplate:test_the_template_has_no_dead_links_or_duplicate_ids()
	template()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {})
end

---------------------------------------------------------------------------------------------
-- AC-2: SWG conformance
---------------------------------------------------------------------------------------------

TestDingeTrainingConformance = {}

function TestDingeTrainingConformance:setUp() H.reset() end

-- AC-2: each of the 12 sids has exactly one screen
function TestDingeTrainingConformance:test_each_of_the_12_training_npc_sids_has_exactly_one_screen()
	local count = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid then
			count[sid] = (count[sid] or 0) + 1
		end
	end

	for _, row in ipairs(D.ROWS) do
		lu.assertEquals(count[row.sid] or 0, 1, "number of screens showing " .. row.sid .. " (appendix row '" .. row.id .. "')")
	end
end

-- AC-2, I-2: option sids in order, successor line, end flag and animation of every training screen, against the java graph
function TestDingeTrainingConformance:test_every_training_screen_matches_the_java_graph()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(screen, "screen '" .. row.id .. "' is missing")
		lu.assertNotNil(node, "answer key: " .. row.sid)
		checked = checked + 1

		lu.assertEquals(sidOf(screen.leftDialog), row.sid, "screen '" .. row.id .. "': NPC line")
		lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")
		lu.assertEquals(screen.animation or "", node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")

		local got = {}

		for i, option in ipairs(screen.options or {}) do
			got[i] = sidOf(option[1])
		end

		lu.assertEquals(got, node.options, "screen '" .. row.id .. "' (" .. row.sid .. "): option sids in order")

		for i, optionSid in ipairs(node.options) do
			local target = byId[screen.options[i][2]]

			lu.assertNotNil(target, "screen '" .. row.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

			local successors = GRAPH.successorsOf(row.sid, optionSid)

			lu.assertNotNil(successors, "answer key: no successor for " .. row.sid .. " -> " .. optionSid)

			-- E-T1 (more_training, s_143): the static link is the java's unconditional default; the handler re-points it
			lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. row.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
		end
	end

	lu.assertEquals(checked, 12, "training screens checked against the java")
end

-- AC-2, I-3: every leftDialog and option text of dinge_convo.lua is a java NPC line / response
function TestDingeTrainingConformance:test_every_string_of_dinge_convo_is_in_the_java()
	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")
		lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
		end
	end
end

-- AC-2, I-3: every string literal DH carries is a java response
function TestDingeTrainingConformance:test_every_string_literal_in_dinge_convo_handler_is_a_java_response()
	local seen = 0

	for sid in readFile(DH_PATH):gmatch("naboo_privateer_trainer_1:(s_[%w_]+)") do
		seen = seen + 1
		lu.assertTrue(GRAPH.responses[sid] == true, "dingeConvoHandler carries " .. sid .. ", which is not a response of the java")
	end

	lu.assertTrue(seen >= 2, "string ids in dingeConvoHandler.lua: " .. seen)
end

-- AC-2, I-3: the 5 old foreign sids are in neither file
function TestDingeTrainingConformance:test_the_5_old_foreign_sids_are_in_neither_file()
	local dc, dh = readFile(DC_PATH), readFile(DH_PATH)

	for _, sid in ipairs(D.OLD_FOREIGN) do
		lu.assertNil(dc:find(sid, 1, true), "dinge_convo.lua still carries " .. sid)
		lu.assertNil(dh:find(sid, 1, true), "dingeConvoHandler.lua still carries " .. sid)
	end
end

-- AC-2, I-3: the 73 screens (rsf-gate-screens) show 73 distinct NPC lines
function TestDingeTrainingConformance:test_the_73_screens_have_73_distinct_left_dialogs()
	local seen, n = {}, 0

	for _, s in ipairs(template().screens) do
		n = n + 1
		lu.assertNil(seen[s.leftDialog], "screens '" .. tostring(seen[s.leftDialog]) .. "' and '" .. s.id .. "' show the same line " .. tostring(s.leftDialog))
		seen[s.leftDialog] = s.id
	end

	lu.assertEquals(n, 73, "screens")
end

-- Every java string DC and DH use (NPC lines as leftDialog, responses as option text or DH literal)
local function usedSids()
	local used = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid and GRAPH.nodes[sid] then
			used[sid] = true
		end

		for _, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			if osid and GRAPH.responses[osid] then
				used[osid] = true
			end
		end
	end

	for sid in readFile(DH_PATH):gmatch("naboo_privateer_trainer_1:(s_[%w_]+)") do
		if GRAPH.responses[sid] then
			used[sid] = true
		end
	end

	return used
end

-- AC-2, I-3: DC + DH use all 120 of the java's strings (73 NPC lines + 47 responses): rsf-gate-screens uses s_1e029d90
function TestDingeTrainingConformance:test_the_two_files_use_all_120_java_strings()
	local used = usedSids()
	local n, npc, resp = 0, 0, 0

	for sid in pairs(used) do
		n = n + 1

		if GRAPH.nodes[sid] then npc = npc + 1 else resp = resp + 1 end
	end

	lu.assertEquals({ n, npc, resp }, { 120, 73, 47 }, "java strings used (total, NPC lines, responses)")

	local unused = {}

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	for sid in pairs(GRAPH.responses) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	table.sort(unused)
	lu.assertEquals(unused, {}, "java strings no file uses")
end

-- AC-2: each of the 18 newly used sids is used now
function TestDingeTrainingConformance:test_the_18_newly_used_sids_are_all_used()
	local used = usedSids()

	for _, sid in ipairs(D.NEW_SIDS) do
		lu.assertTrue(used[sid] == true, sid .. " is not used by dinge_convo.lua / dingeConvoHandler.lua")
	end
end
