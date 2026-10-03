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

-- AC-1; pilot-training-free-choice: first_training_done is deleted, 72 screens
function TestDingeTrainingTemplate:test_the_template_has_72_screens_and_keeps_its_name_handler_and_initial_screen()
	local t = template()

	lu.assertEquals(t.luaClassHandler, "dingeConvoHandler", "dinge_convo_template: luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", "dinge_convo_template: templateType")
	lu.assertEquals(t.initialScreen, "", "dinge_convo_template: initialScreen")
	lu.assertEquals(#t.screens, D.SCREENS_AFTER_CHOICE, "dinge_convo_template: number of screens (67 - 6 + 11, + non_rsf_duty_offer from rsf-gate-screens, - first_training_done)")
end

-- AC-1
function TestDingeTrainingTemplate:test_the_6_old_training_screens_are_deleted()
	local byId = screensById()

	for _, id in ipairs(D.DELETED) do
		lu.assertNil(byId[id], "dinge_convo_template: deleted screen '" .. id .. "' is still defined")
	end
end

-- AC-1; pilot-training-free-choice: more_training and the 10 new screens equal Appendix A, static links included, except E-PN2 / E-PN3 (empty static
-- options on more_training and first_training_lesson) and the deleted first_training_done
function TestDingeTrainingTemplate:test_more_training_and_the_10_new_screens_equal_appendix_a_with_e_pn2_and_e_pn3()
	local byId = screensById()
	local checked = 0
	local deleted = {}

	for _, id in ipairs(D.DELETED_NOW) do
		deleted[id] = true
	end

	for _, row in ipairs(D.ROWS) do
		if deleted[row.id] then
			lu.assertNil(byId[row.id], "dinge_convo_template: screen '" .. row.id .. "' must be deleted (D-6)")
		else
			local want = expectedShape(row)

			if D.E_PN[row.id] then
				want.options = {}
			end

			lu.assertNotNil(byId[row.id], "dinge_convo_template: missing training screen '" .. row.id .. "'")
			lu.assertEquals(shape(byId[row.id]), want, "dinge_convo_template: training screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 11, "training screens checked (12 - first_training_done)")
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

-- AC-2; pilot-training-free-choice: s_142 (first_training_done) is deleted, so 11 of the 12 sids have exactly one screen and s_142 has none
function TestDingeTrainingConformance:test_each_of_the_11_training_npc_sids_has_exactly_one_screen_and_s_142_has_none()
	local count = {}

	for _, s in ipairs(template().screens) do
		local sid = sidOf(s.leftDialog)

		if sid then
			count[sid] = (count[sid] or 0) + 1
		end
	end

	for _, row in ipairs(D.ROWS) do
		lu.assertEquals(count[row.sid] or 0, row.sid == "s_142" and 0 or 1, "number of screens showing " .. row.sid .. " (appendix row '" .. row.id .. "')")
	end
end

-- AC-2, I-2: option sids in order, successor line, end flag and animation of every training screen, against the java graph
function TestDingeTrainingConformance:test_every_training_screen_matches_the_java_graph()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(D.ROWS) do
		local screen = byId[row.id]
		local node = GRAPH.nodes[row.sid]

		if row.id == "first_training_done" then
			-- E-PN3: deleted (D-6)
			lu.assertNil(screen, "screen 'first_training_done' must be deleted")
			goto continue
		end

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

		-- E-PN2 / E-PN3: the single java reply is replaced by the choice the handler adds
		local replaced = D.E_PN[row.id]

		if replaced ~= nil then
			lu.assertEquals(node.options, { replaced }, "answer key: " .. row.sid .. " has the one reply " .. replaced)
			lu.assertEquals(got, {}, "screen '" .. row.id .. "' (" .. row.sid .. "): static options (E-PN2 / E-PN3)")
		else
			lu.assertEquals(got, node.options, "screen '" .. row.id .. "' (" .. row.sid .. "): option sids in order")
		end

		for i, optionSid in ipairs(replaced ~= nil and {} or node.options) do
			local target = byId[screen.options[i][2]]

			lu.assertNotNil(target, "screen '" .. row.id .. "' option " .. optionSid .. ": link '" .. tostring(screen.options[i][2]) .. "' is a screen")

			local successors = GRAPH.successorsOf(row.sid, optionSid)

			lu.assertNotNil(successors, "answer key: no successor for " .. row.sid .. " -> " .. optionSid)

			-- E-T1 (more_training, s_143): the static link is the java's unconditional default; the handler re-points it
			lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. row.id .. "' option " .. optionSid .. " -> successor NPC line (java default)")
		end

		::continue::
	end

	lu.assertEquals(checked, 11, "training screens checked against the java (12 - first_training_done)")
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

-- AC-2, I-3; pilot-training-free-choice: the old foreign NPC line s_cd72f93 stays in neither file (the four old option sids are the choice replies again)
function TestDingeTrainingConformance:test_the_old_foreign_npc_line_s_cd72f93_is_in_neither_file()
	local dc, dh = readFile(DC_PATH), readFile(DH_PATH)

	for _, sid in ipairs(D.OLD_FOREIGN) do
		lu.assertNil(dc:find(sid, 1, true), "dinge_convo.lua still carries " .. sid)
		lu.assertNil(dh:find(sid, 1, true), "dingeConvoHandler.lua still carries " .. sid)
	end
end

-- AC-2, I-3; pilot-training-free-choice: the 72 screens show 72 distinct NPC lines
function TestDingeTrainingConformance:test_the_72_screens_have_72_distinct_left_dialogs()
	local seen, n = {}, 0

	for _, s in ipairs(template().screens) do
		n = n + 1
		lu.assertNil(seen[s.leftDialog], "screens '" .. tostring(seen[s.leftDialog]) .. "' and '" .. s.id .. "' show the same line " .. tostring(s.leftDialog))
		seen[s.leftDialog] = s.id
	end

	lu.assertEquals(n, 72, "screens")
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

-- AC-2, I-3; pilot-training-free-choice: DC + DH use 117 of the java's 120 strings (72 of 73 NPC lines + 45 of 47 responses); s_142, s_141 and s_143 are unused
function TestDingeTrainingConformance:test_the_two_files_use_117_java_strings_all_but_s_141_s_142_and_s_143()
	local used = usedSids()
	local n, npc, resp = 0, 0, 0

	for sid in pairs(used) do
		n = n + 1

		if GRAPH.nodes[sid] then npc = npc + 1 else resp = resp + 1 end
	end

	lu.assertEquals({ n, npc, resp }, { 117, 72, 45 }, "java strings used (total, NPC lines, responses)")

	local unused = {}

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	for sid in pairs(GRAPH.responses) do
		if not used[sid] then unused[#unused + 1] = sid end
	end

	table.sort(unused)
	lu.assertEquals(unused, D.NOW_UNUSED_SIDS, "java strings no file uses")
end

-- AC-2; pilot-training-free-choice: 15 of the 18 newly used sids are used; s_141, s_142, s_143 are not
function TestDingeTrainingConformance:test_15_of_the_18_newly_used_sids_are_used_and_s_141_s_142_s_143_are_not()
	local used = usedSids()
	local gone = {}

	for _, sid in ipairs(D.NOW_UNUSED_SIDS) do
		gone[sid] = true
	end

	for _, sid in ipairs(D.NEW_SIDS) do
		if gone[sid] then
			lu.assertNil(used[sid], sid .. " is still used by dinge_convo.lua / dingeConvoHandler.lua")
		else
			lu.assertTrue(used[sid] == true, sid .. " is not used by dinge_convo.lua / dingeConvoHandler.lua")
		end
	end
end
