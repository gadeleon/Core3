-- Dinge (RSF tier 1) SWG training: template shape and SWG conformance of the 12 training screens, the 60 screens that must not move,
-- and the string coverage of both files.
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (AC-1, AC-2, invariants I-1, I-2, I-3, I-7; Appendix A).
-- Answer keys: rsf_tier1_dinge_training_data.lua (Appendix A, copied from the spec), rsf_tier1_dinge_convo_data.lua (the 60 F7 rows) and the
-- SWG java fixtures/script/conversation/naboo_privateer_trainer_1.java parsed by harness/swgjava.lua. Behavior is in
-- test_rsf_tier1_dinge_training_routing.lua, _purchase.lua and _handler.lua.
-- space-convo-client-strings-dinge (.claude/work/space-convo-client-strings-dinge/01-spec.md, AC-2, D-4, D-9, Appendix A) re-pins ten tests of this file:
-- the template has 64 screens, only first_training and more_training of the 12 training rows keep their NPC line (static options empty), the four trained_<x>
-- screens show "Good choice." (s_cd72f93), and DC + DH use 93 java strings, leaving every NGE-numbered id of the java unused (D.F2_UNUSED_SIDS).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")
local C = require("rsf_tier1_dinge_convo_data")
local G = require("rsf_gate_screens_data")
local P = require("pilot_training_free_choice_data") -- pilot-training-free-choice
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

-- AC-1; space-convo-client-strings-dinge AC-2: 64 screens
function TestDingeTrainingTemplate:test_the_template_has_64_screens_and_keeps_its_name_handler_and_initial_screen()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "dingeConvoHandler", "dinge_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "dinge_convo_template: templateType")
	lu.assertEquals(t.initialScreen, "", "dinge_convo_template: initialScreen")
	lu.assertEquals(#t.screens, D.SCREEN_COUNT_F2, "dinge_convo_template: number of screens (72 - 8 deleted by space-convo-client-strings-dinge)")
end

-- AC-1
function TestDingeTrainingTemplate:test_the_6_old_training_screens_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "dinge_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1; space-convo-client-strings-dinge Content contract 1: first_training and more_training keep their Appendix A line, animation and end flag with empty
-- static options (the handler adds the four choices); the four trained_<x> screens keep their id, animation and end flag but show "Good choice." (D-9); the
-- other six training screens are deleted
function TestDingeTrainingTemplate:test_first_training_more_training_and_the_four_trained_screens_equal_appendix_a_with_the_f2_changes_and_the_other_six_are_deleted()
	local byId = screensById()
	local checked = 0

	for _, id in ipairs(D.F2_GONE) do
		lu.assertNil(byId[id], "dinge_convo_template: screen '" .. id .. "' must be deleted")
	end

	for _, row in ipairs(D.ROWS) do
		if D.F2_KEPT[row.id] then
			local want = expectedShape(row)

			want.options = {}
			lu.assertNotNil(byId[row.id], "dinge_convo_template: missing training screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), want, "dinge_convo_template: training screen '" .. row.id .. "' (empty static options)")
			checked = checked + 1
		elseif row.id:find("^trained_") then
			local want = expectedShape(row)

			want.leftDialog = D.PREFIX .. D.F2_CLOSING_SID
			lu.assertNotNil(byId[row.id], "dinge_convo_template: missing training screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), want, "dinge_convo_template: closing screen '" .. row.id .. "' (Good choice., ends, no options)")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 6, "training screens checked (first_training, more_training, trained_<x> x4)")
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

-- AC-1, I-7; space-convo-client-strings-dinge: the 57 story screens that remain match the convo Appendix A rows after the F2 overlay (C.current())
function TestDingeTrainingTemplate:test_the_57_story_screens_still_match_the_convo_appendix_a_rows_after_the_f2_overlay()
	local byId = screensById()

	for _, row in ipairs(C.current()) do
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

-- AC-2; space-convo-client-strings-dinge: of the 12 training NPC sids only first_training's (s_5e36283d) and more_training's (s_122b0165) are still shown, by
-- one screen each; the other ten (s_140, s_142, s_144 .. s_147, s_149, s_153, s_157, s_161) are shown by none
function TestDingeTrainingConformance:test_only_the_npc_sids_of_first_training_and_more_training_have_a_screen_the_other_ten_have_none()
	local count = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid then
			count[sid] = (count[sid] or 0) + 1
		end
	end

	for _, row in ipairs(D.ROWS) do
		lu.assertEquals(count[row.sid] or 0, D.F2_KEPT[row.id] and 1 or 0, "number of screens showing " .. row.sid .. " (appendix row '" .. row.id .. "')")
	end

	lu.assertEquals(count[D.F2_CLOSING_SID], 4, "number of screens showing " .. D.F2_CLOSING_SID .. " (Good choice.)")
end

-- AC-2, I-2; space-convo-client-strings-dinge: first_training and more_training keep the java node's NPC line, end flag and animation; their single NGE reply
-- (s_139, s_143) is replaced by the choices the handler adds, so the static options are empty. The trained_<x> screens keep the java node's end flag and
-- animation of s_149 .. s_161 (none, ends); only their NPC line is the client's "Good choice." (D-9)
function TestDingeTrainingConformance:test_every_training_screen_matches_the_java_graph()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, "answer key: " .. row.sid)

		if D.F2_KEPT[row.id] then
			lu.assertNotNil(screen, "screen '" .. row.id .. "' is missing")
			checked = checked + 1
			lu.assertEquals(sidOf(screen.leftDialog), row.sid, "screen '" .. row.id .. "': NPC line")
			lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")
			lu.assertEquals(screen.animation or "", node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")
			lu.assertEquals(node.options, { D.F2_KEPT[row.id] }, "answer key: " .. row.sid .. " has the one reply " .. D.F2_KEPT[row.id])
			lu.assertEquals(screen.options or {}, {}, "screen '" .. row.id .. "' (" .. row.sid .. "): static options")
		elseif row.id:find("^trained_") then
			lu.assertNotNil(screen, "screen '" .. row.id .. "' is missing")
			checked = checked + 1
			lu.assertEquals(sidOf(screen.leftDialog), D.F2_CLOSING_SID, "screen '" .. row.id .. "': NPC line")
			lu.assertEquals(screen.stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): stopConversation == \"true\" iff the java ends the conversation")
			lu.assertEquals(screen.animation or "", node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")
			lu.assertEquals(screen.options or {}, {}, "screen '" .. row.id .. "': options")
		else
			lu.assertNil(screen, "screen '" .. row.id .. "' must be deleted")
		end
	end

	lu.assertEquals(checked, 6, "training screens checked against the java (first_training, more_training, trained_<x> x4)")
end

-- AC-2, I-3; space-convo-client-strings-dinge D-9: every leftDialog and option text of dinge_convo.lua is a java NPC line / response, except "Good choice."
-- (s_cd72f93), which only the four trained_<x> screens show
function TestDingeTrainingConformance:test_every_string_of_dinge_convo_is_in_the_java()
	local foreign = 0

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		lu.assertNotNil(sid, "screen '" .. s.id .. "': leftDialog '" .. tostring(s.leftDialog) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")

		if C.DC_FOREIGN[sid] then
			lu.assertTrue(s.id:find("^trained_") ~= nil, "screen '" .. s.id .. "' shows the foreign line " .. sid .. " but is not a trained_<x> screen")
		else
			lu.assertNotNil(GRAPH.nodes[sid], "screen '" .. s.id .. "': leftDialog " .. sid .. " is not an NPC line of the java")
		end

		foreign = foreign + (C.DC_FOREIGN[sid] and 1 or 0)

		for i, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			lu.assertNotNil(osid, "screen '" .. s.id .. "' option " .. i .. ": text '" .. tostring(option[1]) .. "' is not @conversation/naboo_privateer_trainer_1:<sid>")
			lu.assertTrue(GRAPH.responses[osid] == true, "screen '" .. s.id .. "' option " .. i .. ": " .. osid .. " is not a response of the java")
		end
	end

	lu.assertEquals(foreign, 4, "screens showing the foreign line s_cd72f93 (the four trained_<x> screens, D-9)")
end

-- AC-2, I-3; pilot-training-free-choice I-6: every string literal DH carries is a java response, except the four choice replies (D-4)
function TestDingeTrainingConformance:test_every_string_literal_in_dinge_convo_handler_is_a_java_response_except_the_four_choice_replies()
	local seen, choice = {}, {}

	for _, row in ipairs(P.DINGE) do
		choice[row.sid] = true
	end

	for sid in readFile(DH_PATH):gmatch("naboo_privateer_trainer_1:(s_[%w_]+)") do
		seen[sid] = true
		lu.assertTrue(GRAPH.responses[sid] == true or choice[sid] == true, "dingeConvoHandler carries " .. sid .. ", which is neither a response of the java nor one of the four choice replies")
	end

	for sid in pairs(choice) do
		lu.assertTrue(seen[sid] == true, "dingeConvoHandler never carries the choice reply " .. sid)
		lu.assertFalse(GRAPH.responses[sid] == true, "choice reply " .. sid .. " is a java response; the spec lists it as foreign")
	end

	lu.assertTrue(#sortedKeys(seen) >= 6, "string ids in dingeConvoHandler.lua: " .. #sortedKeys(seen))
	lu.assertNil(seen.s_143, "dingeConvoHandler still carries the retired single reply s_143")
	lu.assertNil(seen.s_141, "dingeConvoHandler still carries the retired reply s_141")
end

-- AC-2, I-3; space-convo-client-strings-dinge D-9, I-6: the foreign NPC line s_cd72f93 ("Good choice.") is on exactly the four trained_<x> screens of dinge_convo.lua
-- and nowhere in dingeConvoHandler.lua
function TestDingeTrainingConformance:test_the_foreign_npc_line_s_cd72f93_is_only_on_the_four_trained_screens_and_not_in_the_handler()
	local on = {}

	for _, s in ipairs(template().screens) do
		if sidOf(s.leftDialog) == D.F2_CLOSING_SID then
			on[#on + 1] = s.id
		end
	end

	table.sort(on)
	lu.assertEquals(on, { "trained_droid", "trained_procedures", "trained_starships", "trained_weapons" }, "screens showing s_cd72f93")
	lu.assertNil(readFile(DH_PATH):find(D.F2_CLOSING_SID, 1, true), "dingeConvoHandler.lua carries " .. D.F2_CLOSING_SID)

	for _, sid in ipairs({ "s_e9c7c6bb", "s_52917b0d", "s_8179979d" }) do
		lu.assertNil(readFile(DC_PATH):find(sid, 1, true), "dinge_convo.lua carries the unused client line " .. sid)
		lu.assertNil(readFile(DH_PATH):find(sid, 1, true), "dingeConvoHandler.lua carries the unused client line " .. sid)
	end
end

-- (Retired by space-convo-client-strings-dinge, R-3: the screens no longer show distinct NPC lines. The repeated lines are pinned by
-- test_pilot_training_free_choice_conformance.lua TestFreeChoiceGraph.)

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

-- AC-2, I-3; space-convo-client-strings-dinge AC-2: DC + DH use 93 of the java's 120 strings (58 of 73 NPC lines + 35 of 47 responses); the 27 unused are exactly
-- the NGE-numbered ids of the java
function TestDingeTrainingConformance:test_the_two_files_use_93_java_strings_all_but_the_27_nge_numbered_ones()
	local used = usedSids()
	local n, npc, resp = 0, 0, 0

	for sid in pairs(used) do
		n = n + 1

		if GRAPH.nodes[sid] then npc = npc + 1 else resp = resp + 1 end
	end

	lu.assertEquals({ n, npc, resp }, { 93, 58, 35 }, "java strings used (total, NPC lines, responses)")

	local unused = {}

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	for sid in pairs(GRAPH.responses) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	table.sort(unused)

	local want = {}

	for i, sid in ipairs(D.F2_UNUSED_SIDS) do want[i] = sid end

	table.sort(want)
	lu.assertEquals(unused, want, "java strings no file uses")
end

-- AC-2; space-convo-client-strings-dinge: of the 18 sids rsf-tier1-dinge-training first used, only s_5e36283d (first_training's line) is still used
function TestDingeTrainingConformance:test_only_s_5e36283d_of_the_18_newly_used_sids_is_still_used()
	local used = usedSids()

	for _, sid in ipairs(D.NEW_SIDS) do
		if sid == "s_5e36283d" then
			lu.assertTrue(used[sid] == true, sid .. " is not used by dinge_convo.lua / dingeConvoHandler.lua")
		else
			lu.assertNil(used[sid], sid .. " is still used by dinge_convo.lua / dingeConvoHandler.lua")
		end
	end
end
