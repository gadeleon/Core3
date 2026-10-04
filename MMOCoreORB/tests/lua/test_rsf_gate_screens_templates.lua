-- Kaydine and Dinge gate screens as data: template shape, SWG conformance (naboo_privateer_trainer_2.java / _1.java), string coverage,
-- handler/template agreement and "everything else is unchanged since 0a76b16b5b".
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-2, AC-5, invariants I-1, I-2, I-3, I-6, I-7; Appendix A, Exceptions E-G1..E-G2).
--
-- Answer key: rsf_gate_screens_data.lua (copied from the spec) and the SWG java fixtures parsed by harness/swgjava.lua. The kept-screen
-- comparison reads the template files of commit 0a76b16b5b through `git show` and compares screen definition blocks as text.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")
local SU = require("rsf_tier2_kaydine_signup_data") -- rsf-tier2-kaydine-signup: the nine new Kaydine screens
local P = require("pilot_training_free_choice_data") -- pilot-training-free-choice (spec: .claude/work/pilot-training-free-choice/01-spec.md)
local Swgjava = require("harness.swgjava")

T.load()

local BASE = "0a76b16b5b"

local KJAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java")
local DJAVA = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_1.java")

local DIR_C = "bin/scripts/mobile/conversations/space/neutral/rsf_squadron/"
local DIR_H = "bin/scripts/screenplays/space/conversations/neutral/rsf_squadron/"
local FILES = {
	kaydine = { convo = DIR_C .. "kaydine_convo.lua", handler = DIR_H .. "kaydineConvoHandler.lua", template = G.KAYDINE_TEMPLATE, prefix = G.PK, java = KJAVA, handlerName = "kaydineConvoHandler" },
	dinge = { convo = DIR_C .. "dinge_convo.lua", handler = DIR_H .. "dingeConvoHandler.lua", template = G.DINGE_TEMPLATE, prefix = G.PJ, java = DJAVA, handlerName = "dingeConvoHandler" },
}

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path:gsub("^bin/scripts/", ""), "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()

	return text
end

-- The file as it is at commit 0a76b16b5b (spec: all screens not in Appendix A are byte-identical to it)
local function baseFile(path)
	local pipe = io.popen("git show " .. BASE .. ":MMOCoreORB/" .. path .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil,
		"git show " .. BASE .. ":MMOCoreORB/" .. path .. " did not return the file: " .. text:sub(1, 120))

	return text
end

-- screen id -> the text of its definition (from "<var> = ConvoScreen:new {" to "<template>:addScreen(<var>);")
local function screenBlocks(text)
	local blocks, current = {}, nil

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if current == nil and line:match("^[%w_]+ = ConvoScreen:new {") then
			current = { line }
		elseif current ~= nil then
			current[#current + 1] = line

			if line:match("^[%w_]+:addScreen%(") then
				local body = table.concat(current, "\n")
				local id = body:match('\n%s*id = "([^"]+)"')

				blocks[id] = body
				current = nil
			end
		end
	end

	return blocks
end

local function template(trainer)
	local t = H.conversationTemplateTable(FILES[trainer].template)

	lu.assertNotNil(t, FILES[trainer].template .. " is not registered via addConversationTemplate")

	return t
end

local function screensById(trainer)
	local byId = {}

	for _, s in ipairs(template(trainer).screens) do
		byId[s.id] = s
	end

	return byId
end

local function sidOf(text)
	return text and text:match(":(s_[%w_]+)$")
end

local function shape(screen)
	local options = {}

	for i, o in ipairs(screen.options or {}) do
		options[i] = { o[1], o[2] }
	end

	return { leftDialog = screen.leftDialog, stopConversation = screen.stopConversation, animation = screen.animation, options = options }
end

local function expectedShape(prefix, row)
	local options = {}

	for i, o in ipairs(row.options) do
		options[i] = { prefix .. o[1], o[2] }
	end

	return {
		leftDialog = prefix .. row.sid,
		stopConversation = row.stop and "true" or "false",
		animation = row.animation ~= "" and row.animation or nil,
		options = options,
	}
end

local ROWS = { kaydine = G.KAYDINE_ROWS, dinge = G.DINGE_ROWS }
local SCREEN_COUNT = { kaydine = G.KAYDINE_SCREEN_COUNT, dinge = G.DINGE_SCREEN_COUNT }
local CHANGED = { kaydine = G.KAYDINE_CHANGED, dinge = G.DINGE_CHANGED }
local NEW = { kaydine = G.KAYDINE_NEW, dinge = G.DINGE_NEW }
local DELETED = { kaydine = G.KAYDINE_DELETED, dinge = G.DINGE_DELETED } -- pilot-training-free-choice: first_training_done
local CHOICE = { kaydine = P.KAYDINE, dinge = P.DINGE } -- the choice replies each handler adds (D-4); not java responses
local OLD_COUNT = { kaydine = 87, dinge = 72 }

---------------------------------------------------------------------------------------------
-- The answer key itself (sanity of the spec tables)
---------------------------------------------------------------------------------------------

TestGateAnswerKey = {}

function TestGateAnswerKey:setUp() H.reset() end

-- AC-2, AC-5
function TestGateAnswerKey:test_appendix_a_rows_are_12_kaydine_and_6_dinge_with_the_listed_new_and_changed_screens()
	local function count(rows)
		local c = { new = 0, chg = 0, kept = 0 }

		for _, row in ipairs(rows) do
			c[row.status] = c[row.status] + 1
		end

		return c
	end

	lu.assertEquals(count(G.KAYDINE_ROWS), { new = 4, chg = 3, kept = 5 }, "Appendix A-K rows by status")
	lu.assertEquals(count(G.DINGE_ROWS), { new = 1, chg = 2, kept = 3 }, "Appendix A-D rows by status")
end

-- AC-2, AC-5 (answer key against the java, independent of the production files)
function TestGateAnswerKey:test_appendix_a_agrees_with_the_java_nodes()
	for trainer, rows in pairs(ROWS) do
		local java = FILES[trainer].java

		for _, row in ipairs(rows) do
			local node = java.nodes[row.sid]

			lu.assertNotNil(node, trainer .. " appendix row '" .. row.id .. "': " .. row.sid .. " is an NPC line of the java")
			lu.assertEquals(row.stop, node.isEnd, trainer .. " appendix row '" .. row.id .. "': end flag")
			lu.assertEquals(row.animation, node.animation, trainer .. " appendix row '" .. row.id .. "': animation")

			local sids = {}

			for i, o in ipairs(row.options) do
				sids[i] = o[1]
			end

			lu.assertEquals(sids, node.options, trainer .. " appendix row '" .. row.id .. "': option sids in order")
		end
	end
end

-- E-G1 / E-G2: the static link is the java's unconditional last successor, the conditional first successor is the duty line
function TestGateAnswerKey:test_the_exceptions_e_g1_and_e_g2_are_the_java_default_successors_and_the_first_one_is_the_duty_line()
	local k = KJAVA.successorsOf("s_c89c3456", "s_c1ff5062")
	local d = DJAVA.successorsOf("s_6b25cc31", "s_c1ff5062")

	lu.assertNotNil(k, "java successors of s_c89c3456 -> s_c1ff5062")
	lu.assertNotNil(d, "java successors of s_6b25cc31 -> s_c1ff5062")
	lu.assertEquals(k[1], "s_8a84109d", "E-G1: the first (conditional) successor is the off-track duty line")
	lu.assertEquals(k[#k], "s_7458c693", "E-G1: the unconditional last successor is the refusal")
	lu.assertEquals(d[1], "s_1e029d90", "E-G2: the first (conditional) successor is the off-track duty line")
	lu.assertEquals(d[#d], "s_38d8b2c4", "E-G2: the unconditional last successor is the refusal")
	lu.assertEquals(G.sortedKeys(G.EXCEPTIONS), { "dinge|non_rsf_pilot|s_c1ff5062", "kaydine|pilot_not_rsf|s_c1ff5062" }, "documented exceptions")
end

---------------------------------------------------------------------------------------------
-- AC-2 / AC-5: template shape
---------------------------------------------------------------------------------------------

TestGateTemplates = {}

function TestGateTemplates:setUp() H.reset() end

for _, trainer in ipairs({ "kaydine", "dinge" }) do
	local files = FILES[trainer]

	-- AC-2, AC-5
	TestGateTemplates["test_" .. trainer .. "_template_keeps_its_name_and_handler_and_has_" .. SCREEN_COUNT[trainer] .. "_screens"] = function()
		local t = template(trainer)

		lu.assertEquals(t.luaClassHandler, files.handlerName, files.template .. ": luaClassHandler")
		lu.assertEquals(t.templateType, "Lua", files.template .. ": templateType")
		lu.assertEquals(t.initialScreen, "", files.template .. ": initialScreen")
		lu.assertEquals(#t.screens, SCREEN_COUNT[trainer], files.template .. ": number of screens")
	end

	-- AC-2, AC-5: every Appendix A row (new, changed and kept) is exactly the spec's
	TestGateTemplates["test_" .. trainer .. "_appendix_a_rows_equal_the_spec"] = function()
		local byId = screensById(trainer)

		for _, row in ipairs(ROWS[trainer]) do
			lu.assertNotNil(byId[row.id], files.template .. ": missing screen '" .. row.id .. "' (" .. row.status .. ")")
			lu.assertEquals(shape(byId[row.id]), expectedShape(files.prefix, row), files.template .. ": screen '" .. row.id .. "' (leftDialog, stopConversation, animation, options in order)")
		end
	end

	-- AC-2, AC-5, I-1
	TestGateTemplates["test_" .. trainer .. "_template_has_no_dead_links_or_duplicate_ids"] = function()
		template(trainer)
		lu.assertEquals(H.conversationProblems(files.template), {})
	end

	-- AC-2, AC-5, I-7: every screen outside Appendix A's new and changed rows is the very text of commit 0a76b16b5b
	TestGateTemplates["test_" .. trainer .. "_screens_outside_the_new_and_changed_rows_equal_commit_" .. BASE] = function()
		local old = screenBlocks(baseFile(files.convo))
		local new = screenBlocks(readFile(files.convo))
		local touched = {}

		for _, id in ipairs(CHANGED[trainer]) do touched[id] = true end
		for _, id in ipairs(NEW[trainer]) do touched[id] = true end
		for _, id in ipairs(DELETED[trainer]) do touched[id] = true end

		-- a deleted screen must be gone
		local newBlocks = screenBlocks(readFile(files.convo))

		for _, id in ipairs(DELETED[trainer]) do
			lu.assertNil(newBlocks[id], files.template .. ": screen '" .. id .. "' must be deleted")
		end

		local oldCount, checked = 0, 0

		for _ in pairs(old) do oldCount = oldCount + 1 end

		lu.assertEquals(oldCount, OLD_COUNT[trainer], "screen definitions parsed from " .. files.convo .. " at " .. BASE)

		for id, body in pairs(old) do
			if not touched[id] then
				lu.assertNotNil(new[id], files.template .. ": screen '" .. id .. "' of " .. BASE .. " is missing")
				lu.assertEquals(new[id], body, files.template .. ": screen '" .. id .. "' changed since " .. BASE)
				checked = checked + 1
			end
		end

		lu.assertEquals(checked, OLD_COUNT[trainer] - #CHANGED[trainer] - #DELETED[trainer], "screens compared with " .. BASE)

		local signup = {}

		for _, id in ipairs(trainer == "kaydine" and SU.IDS or {}) do signup[id] = true end

		for id in pairs(new) do
			if old[id] == nil then
				lu.assertTrue(touched[id] == true or signup[id] == true, files.template .. ": unexpected new screen '" .. id .. "'")
			end
		end
	end
end

-- AC-5; pilot-training-free-choice: Dinge's 72 screens show 72 distinct NPC lines
function TestGateTemplates:test_dinge_screens_show_72_distinct_left_dialogs()
	local seen, n = {}, 0

	for _, s in ipairs(template("dinge").screens) do
		n = n + 1
		lu.assertNil(seen[s.leftDialog], "screens '" .. tostring(seen[s.leftDialog]) .. "' and '" .. s.id .. "' show the same line " .. tostring(s.leftDialog))
		seen[s.leftDialog] = s.id
	end

	lu.assertEquals(n, G.DINGE_SCREEN_COUNT, "dinge_convo_template screens")
end

-- AC-5: DH getInitialScreen and getNextConversationScreen are textually unchanged (D-7, I-7)
local function functionText(text, name)
	local out, inside = {}, false

	for line in (text .. "\n"):gmatch("(.-)\n") do
		if not inside and line:find("^function " .. name .. "%(") then
			inside = true
		end

		if inside then
			out[#out + 1] = line

			if line == "end" then
				break
			end
		end
	end

	return table.concat(out, "\n")
end

-- AC-5, I-7: getInitialScreen is still the text of the base commit.
-- pilot-training-free-choice: getNextConversationScreen is re-pinned in two parts: the paid purchase branch (from "elseif (skill ~= nil) then" to the
-- delegation to conv_handler) is still the text of the base commit; the first_training_lesson branch above it is the one the feature rewrites (D-9).
TestGateTemplates["test_dinge_handler_getInitialScreen_is_byte_identical_to_commit_" .. BASE] = function()
	local name = "dingeConvoHandler:getInitialScreen"
	local old = functionText(baseFile(FILES.dinge.handler), name)

	lu.assertTrue(#old > 100, "setup: " .. name .. " found at " .. BASE)
	lu.assertEquals(functionText(readFile(FILES.dinge.handler), name), old, name .. " changed since " .. BASE)
end

TestGateTemplates["test_dinge_handler_getNextConversationScreen_paid_purchase_branch_is_byte_identical_to_commit_" .. BASE] = function()
	local name = "dingeConvoHandler:getNextConversationScreen"
	local function purchase(text)
		local fn = functionText(text, name)
		local a = fn:find("\telseif (skill ~= nil) then", 1, true)

		lu.assertNotNil(a, name .. ": the 'elseif (skill ~= nil) then' branch")

		return fn:sub(a)
	end

	local old = purchase(baseFile(FILES.dinge.handler))

	lu.assertTrue(#old > 300, "setup: the paid purchase branch found at " .. BASE)
	lu.assertEquals(purchase(readFile(FILES.dinge.handler)), old, name .. ": the paid purchase branch changed since " .. BASE)
end

-- AC-2, I-7: Kaydine's getInitialScreen keeps its head (migration first, JTL check) and the lines after the pilot gates
function TestGateTemplates:test_kaydine_get_initial_screen_keeps_migration_as_its_first_statement_and_the_jtl_check()
	local text = functionText(readFile(FILES.kaydine.handler), "kaydineConvoHandler:getInitialScreen")
	local migrate = text:find("RsfSquadronScreenplay:migrateLegacyProgress(pPlayer)", 1, true)
	local jtl = text:find("if (not isJtlEnabled()) then\n\t\treturn convoTemplate:getScreen(\"not_pilot\")", 1, true)

	lu.assertNotNil(migrate, "migrateLegacyProgress is called by getInitialScreen")
	lu.assertNotNil(jtl, "the JTL check still returns not_pilot")
	lu.assertTrue(migrate < jtl, "migrateLegacyProgress comes before the JTL check")
	lu.assertNil(text:sub(1, migrate - 1):find("getScreen(", 1, true), "no screen is returned before migrateLegacyProgress")
end

---------------------------------------------------------------------------------------------
-- AC-2 / AC-5: SWG conformance against the parsed java (I-2, I-3)
---------------------------------------------------------------------------------------------

TestGateConformance = {}

function TestGateConformance:setUp() H.reset() end

for _, trainer in ipairs({ "kaydine", "dinge" }) do
	local files = FILES[trainer]

	-- AC-2, AC-5, I-2: end flag, animation, option sids in order and the successor line of each option, from the java, for the gate screens
	TestGateConformance["test_every_" .. trainer .. "_appendix_screen_matches_the_java_node"] = function()
		local byId = screensById(trainer)
		local java = files.java
		local checked = 0

		for _, row in ipairs(ROWS[trainer]) do
			local screen = byId[row.id]
			local node = java.nodes[row.sid]

			lu.assertNotNil(screen, files.template .. ": screen '" .. row.id .. "' is missing")
			lu.assertNotNil(node, "java: " .. row.sid)
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

				local successors = java.successorsOf(row.sid, optionSid)

				lu.assertNotNil(successors, "java: no successor for " .. row.sid .. " -> " .. optionSid)

				-- E-G1 / E-G2 need no special case: the static link is the java's unconditional (last) successor, which the
				-- handler re-points at display time (TestGateAnswerKey checks that the first successor is the duty line)
				lu.assertEquals(sidOf(target.leftDialog), successors[#successors], "screen '" .. row.id .. "' option " .. optionSid .. " -> java default successor")
			end
		end

		lu.assertEquals(checked, #ROWS[trainer], "appendix rows checked")
	end

	-- AC-2, AC-5, I-3; pilot-training-free-choice I-6: every PJ/PK sid in the four files is a node or a response of the java, except the four choice
	-- replies of the trainer's handler (D-4), which must all be there
	TestGateConformance["test_every_" .. trainer .. "_string_id_is_in_the_java_except_the_four_choice_replies"] = function()
		local java = files.java
		local foreign = {}
		local choice, seenChoice = {}, {}

		for _, row in ipairs(CHOICE[trainer]) do
			choice[row.sid] = true
		end

		for _, path in ipairs({ files.convo, files.handler }) do
			for sid in readFile(path):gmatch(files.prefix:gsub("%p", "%%%0") .. "(s_[%w_]+)") do
				if choice[sid] then
					seenChoice[sid] = path:match("[^/]+$")
				elseif java.nodes[sid] == nil and java.responses[sid] == nil then
					foreign[#foreign + 1] = path:match("[^/]+$") .. ": " .. sid
				end
			end
		end

		table.sort(foreign)
		lu.assertEquals(foreign, {}, "string ids that are not in the java")

		for sid in pairs(choice) do
			lu.assertEquals(seenChoice[sid], files.handler:match("[^/]+$"), "choice reply " .. sid .. " must be carried by the handler (and only by the handler)")
		end
	end
end

-- The java strings the template (NPC lines, options) and the handler (option literals) use
local function used(trainer)
	local java, files = FILES[trainer].java, FILES[trainer]
	local set = {}

	for _, s in ipairs(template(trainer).screens) do
		local sid = sidOf(s.leftDialog)

		if sid and java.nodes[sid] then
			set[sid] = true
		end

		for _, option in ipairs(s.options or {}) do
			local osid = sidOf(option[1])

			if osid and java.responses[osid] then
				set[osid] = true
			end
		end
	end

	for sid in readFile(files.handler):gmatch(files.prefix:gsub("%p", "%%%0") .. "(s_[%w_]+)") do
		if java.responses[sid] or java.nodes[sid] then
			set[sid] = true
		end
	end

	local npc, resp = 0, 0

	for sid in pairs(set) do
		if java.nodes[sid] then npc = npc + 1 else resp = resp + 1 end
	end

	return set, npc, resp
end

-- AC-5, I-3; pilot-training-free-choice: Dinge uses 72 of 73 NPC lines and 45 of 47 replies (s_142, s_141 and s_143 are unused)
function TestGateConformance:test_dinge_uses_72_of_73_npc_lines_and_45_of_47_replies()
	local set, npc, resp = used("dinge")

	lu.assertEquals({ npc, resp }, { 72, 45 }, "java strings used by dinge_convo.lua and dingeConvoHandler.lua (NPC lines, replies)")

	for _, sid in ipairs({ "s_142", "s_141", "s_143" }) do
		lu.assertNil(set[sid], sid .. " must be unused now")
	end

	lu.assertTrue(set["s_1e029d90"] == true, "s_1e029d90 (the off-track duty line) is used")
end

-- AC-2, I-3; pilot-training-free-choice, rsf-tier2-kaydine-signup (I-6): Kaydine uses 96 of 99 NPC lines and 55 of 59 replies; the unused ones are the NGE-only
-- branch B lines (s_29 .. s_39, D-8) and the retired single reply s_187
function TestGateConformance:test_kaydine_uses_96_of_99_npc_lines_and_55_of_59_replies_and_the_unused_ones_are_the_nge_only_signup_lines_and_s_187()
	local set, npc, resp = used("kaydine")

	lu.assertEquals({ npc, resp }, { 96, 55 }, "java strings used by kaydine_convo.lua and kaydineConvoHandler.lua (NPC lines, replies)")

	local unusedNpc, unusedResp = {}, {}

	for _, sid in ipairs(KJAVA.order) do
		if not set[sid] then unusedNpc[#unusedNpc + 1] = sid end
	end

	for sid in pairs(KJAVA.responses) do
		if not set[sid] then unusedResp[#unusedResp + 1] = sid end
	end

	table.sort(unusedNpc)
	table.sort(unusedResp)

	local wantNpc, wantResp = {}, {}

	for i, sid in ipairs(G.KAYDINE_UNUSED_NPC) do wantNpc[i] = sid end
	for i, sid in ipairs(G.KAYDINE_UNUSED_RESP) do wantResp[i] = sid end

	table.sort(wantNpc)
	table.sort(wantResp)

	lu.assertEquals(unusedNpc, wantNpc, "NPC lines of the java that Kaydine does not use")
	lu.assertEquals(unusedResp, wantResp, "replies of the java that Kaydine does not use")

	for _, sid in ipairs({ "s_6c6f3940", "s_c89c3456", "s_8a84109d", "s_394f0902", "s_b0704da1" }) do
		lu.assertTrue(set[sid] == true, sid .. " is used now")
	end
end

---------------------------------------------------------------------------------------------
-- I-6: the handlers only name screens of their template
---------------------------------------------------------------------------------------------

TestGateHandlerAgreement = {}

function TestGateHandlerAgreement:setUp() H.reset() end

for _, trainer in ipairs({ "kaydine", "dinge" }) do
	-- AC-2, AC-5, I-6: every screen id the handler returns, links or tests exists in the template
	TestGateHandlerAgreement["test_every_screen_id_the_" .. trainer .. "_handler_names_is_in_the_template"] = function()
		local text = readFile(FILES[trainer].handler)
		local byId = screensById(trainer)
		local named = {}

		for id in text:gmatch('getScreen%("([^"]+)"%)') do named[id] = "getScreen" end
		for id in text:gmatch('screenID == "([^"]+)"') do named[id] = "screenID test" end

		for line in text:gmatch("[^\n]*addOption%b()[^\n]*") do
			for id in line:gmatch('"([%w_]+)"') do
				if not id:find("^@") and not id:find("^s_") then
					named[id] = "addOption link"
				end
			end
		end

		local missing = {}

		for id, how in pairs(named) do
			if byId[id] == nil then
				missing[#missing + 1] = id .. " (" .. how .. ")"
			end
		end

		table.sort(missing)
		lu.assertEquals(missing, {}, FILES[trainer].handlerName .. ": screen ids that are not in " .. FILES[trainer].template)

		-- the new screens the handler must reach by name (the others are only linked by the template)
		local reachedByName = { kaydine = { "rebel_pilot", "imperial_pilot", "non_rsf_duty_options" }, dinge = { "non_rsf_duty_offer" } }

		for _, id in ipairs(reachedByName[trainer]) do
			lu.assertNotNil(named[id], FILES[trainer].handlerName .. " never names the new screen '" .. id .. "'")
		end
	end
end
