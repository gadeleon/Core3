-- Shamdon Kree: the conversation template (Appendix A), its client strings and the SWG java script.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; D-2, D-5, D-14).
--
-- Answer keys: smuggler_tier2_screens_data.lua (Appendix A, copied from the spec), the SWG java script
-- fixtures/script/conversation/tatooine_privateer_trainer_shamdon.java (harness/swgjava.lua for lines, replies, end flags, animations and links), the
-- generated client id list fixtures/string/en/conversation/tatooine_privateer_trainer_shamdon.sids and the client text smuggler_tier2_client_text.lua.
-- TestSmugglerT2TemplateOracle needs no production code and is green from the start.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local CS = require("harness.client_strings")
local TEXT = M.TEXT
local Swgjava = require("harness.swgjava")

M.load()

local PATHS = { M.TEMPLATE_FILE, M.HANDLER_FILE }

local function template() return H.conversationTemplateTable(M.TEMPLATE) end

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

local GRAPH = Swgjava.read(M.SHJ)

local function setOf(list)
	local set = {}

	for _, v in ipairs(list) do
		set[v] = true
	end

	return set
end

-- the rows whose replies are NGE-numbered in the script and rebuilt from client lines (Data mapping 3): the option check against the script does not apply
local REBUILT = setOf({ "m1_reward_doubt", "m2_paid", "m3_paid_naturally", "m3_paid_yes", "m4_paid_fine", "m4_paid_handle", "naive", "training" })

-- the six "Ready for another assignment?" screens (C-5) and the third reply of each (the "no" reply) with its target
local ANOTHER = {
	m1_reward_nothing = { "s_d6695e83", "come_back" }, m1_reward_doubt = { "s_d6695e83", "come_back" }, m2_paid = { "s_d6695e83", "come_back" },
	m3_paid_naturally = { "s_d6695e83", "come_back_soon" }, m3_paid_yes = { "s_d6695e83", "come_back_soon" },
	m4_paid_fine = { "s_360d8728", "come_back" }, m4_paid_handle = { "s_360d8728", "come_back" },
}

local function dialogMap()
	local dialogOf = {}

	for _, row in ipairs(M.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	return dialogOf
end

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT2TemplateOracle = {}

function TestSmugglerT2TemplateOracle:setUp() H.reset() end

-- AC-5 (the oracle itself): 59 screens, ids unique, 100 ids used = the 100 client lines of the file (102 entries with do_not_edit and s_0)
function TestSmugglerT2TemplateOracle:test_appendix_a_has_59_screens_and_uses_exactly_the_100_client_lines()
	lu.assertEquals(#M.SCREENS, 59, "Appendix A rows")

	local seen = {}

	for _, row in ipairs(M.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
	end

	local ids = CS.sids(M.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. M.STF .. ".sids")

	local all = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" then
			all[#all + 1] = id
		end
	end

	table.sort(all)
	lu.assertEquals(#all, 100, "client lines")
	lu.assertEquals(M.usedIds(), all, "ids Appendix A uses versus the client lines of tatooine_privateer_trainer_shamdon")
end

-- AC-5 (the oracle itself): the generated client id list holds the 102 entries the spec names, and the text file the same ids
function TestSmugglerT2TemplateOracle:test_the_client_id_fixture_and_text_hold_102_ids()
	local ids = CS.sids(M.STF)
	local n = 0

	for id in pairs(ids) do
		n = n + 1
		lu.assertNotNil(TEXT[id], "smuggler_tier2_client_text.lua has no text for " .. id)
	end

	lu.assertEquals(n, 102, "ids in fixtures/string/en/" .. M.STF .. ".sids (100 lines plus do_not_edit and s_0)")
end

-- AC-5 (the oracle itself): the answer key parses the script's 99 NPC lines; 55 are Appendix A dialogs (58 ids, 59 screens), 44 are NGE editor numbers
function TestSmugglerT2TemplateOracle:test_the_answer_key_parses_99_npc_lines_and_the_44_unused_ones_are_nge_numbers()
	lu.assertEquals(#GRAPH.order, 99, "NPC lines parsed from tatooine_privateer_trainer_shamdon.java")

	local used = {}

	for _, row in ipairs(M.SCREENS) do
		used[row.sid] = true
	end

	local unused = {}

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then
			unused[#unused + 1] = sid
			lu.assertNotNil(sid:match("^s_%d+$"), "script NPC line " .. sid .. " is not used by a screen and is not an NGE editor number")
		end
	end

	lu.assertEquals(#unused, 44, "script NPC lines no screen uses (all NGE)")
end

-- AC-5, I-8 (the oracle itself): Appendix A agrees with the script. Every script-backed dialog ends where the script ends, plays its animation, offers the
-- script's replies in its order and each reply leads where the script leads; the rows Data mapping 3 rebuilds are checked against their rule below.
function TestSmugglerT2TemplateOracle:test_every_screen_of_appendix_a_agrees_with_the_swg_script_except_the_rebuilt_ones()
	local dialogOf = dialogMap()
	local checked = 0

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node == nil then
			lu.assertTrue(row.id:find("^trained_") ~= nil, "screen '" .. row.id .. "' (" .. row.sid .. ") is not a script NPC line and is not a pre-NGE trained_ screen")
		else
			lu.assertEquals(row.animation, node.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): the animation of the script line")
			lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the script does")

			if not REBUILT[row.id] then
				local want = {}

				for i, o in ipairs(row.options) do
					want[i] = o[1]
				end

				lu.assertEquals(node.options, want, "screen '" .. row.id .. "': the replies of " .. row.sid .. " in script order")

				for _, o in ipairs(row.options) do
					local ok = false

					for _, succ in ipairs(GRAPH.successorsOf(row.sid, o[1]) or {}) do
						if succ == dialogOf[o[2]] then
							ok = true
						end
					end

					-- m2_reward: the second and third replies are NGE variants whose successors are NGE lines; Data mapping 3 rejoins them to m2_paid
					if not ok and row.id == "m2_reward" and (o[1] == "s_43f63a81" or o[1] == "s_9f5f269") then
						ok = o[2] == "m2_paid"
					end

					lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. o[1] .. ": the script leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
					checked = checked + 1
				end
			end
		end
	end

	lu.assertEquals(checked, 44, "replies checked against the script (the rebuilt rows and m2_reward's NGE variants excepted)")
end

-- AC-5, D-2, Data mapping 3 (the oracle itself): the rebuilt "another assignment?" screens offer the sibling's replies (class a, twin) and the training and
-- naive rows the client lines (class P and b)
function TestSmugglerT2TemplateOracle:test_the_rebuilt_rows_follow_the_twin_and_rejoin_rules_of_data_mapping_3()
	local dialogOf = dialogMap()

	-- the sibling that the script itself defines with client ids: m1_reward_nothing (s_f1bbe36f)
	local sibling = GRAPH.nodes["s_f1bbe36f"]

	lu.assertEquals(sibling.options, { "s_8be640b8", "s_895d093", "s_d6695e83" }, "script: the replies of the sibling m1_reward_nothing")

	for id, no in pairs(ANOTHER) do
		local row = M.screenRow(id)
		local replies, links = {}, {}

		for i, o in ipairs(row.options) do
			replies[i], links[i] = o[1], o[2]
		end

		lu.assertEquals(replies, { "s_8be640b8", "s_895d093", no[1] }, "screen '" .. id .. "': Sure / Ok / the no reply")
		lu.assertEquals(links, { "training", "duty_menu", no[2] }, "screen '" .. id .. "': links")
		lu.assertEquals(row.cond, "C-5", "screen '" .. id .. "': the options are conditional (C-5)")
	end

	-- the M4 client reply s_360d8728 is the script's own "no" reply of m4_paid_handle (s_360d8728 -> s_154 in NGE, s_5ad49b89 by the twin rule)
	lu.assertEquals(GRAPH.nodes["s_d4079379"].options[2], "s_360d8728", "script: the second reply of m4_paid_handle is the client's own 'no'")

	-- naive: the script's s_179 / s_181 tail rejoins the only exit of the Jabba chain
	lu.assertEquals(M.screenRow("naive").options, { { "s_725573da", "see_karrde", "" } }, "naive: 'What now?' rejoins see_karrde")
	lu.assertEquals(GRAPH.nodes["s_5f96d75a"].options, { "s_179" }, "script: naive has the NGE reply s_179")
	lu.assertEquals(GRAPH.nodes["s_181"].animation, GRAPH.nodes["s_52e7e5e"].animation, "script: s_181 plays the animation of see_karrde (shrug_hands)")

	-- training: the four pre-NGE topics, the script has one NGE reply
	lu.assertEquals(GRAPH.nodes["s_383435"].options, { "s_236" }, "script: training has the NGE reply s_236")

	local replies = {}

	for i, o in ipairs(M.screenRow("training").options) do
		replies[i] = o[1]
	end

	lu.assertEquals(replies, { "s_45b71b4d", "s_197f4f94", "s_8f5942fa", "s_eff66f4d" }, "training: the four pre-NGE topics")

	-- trained_*: three closing lines for four skills (D-5), then Yes / No
	for _, t in ipairs(M.TRAIN) do
		local row = M.screenRow(t.trained)

		lu.assertEquals(row.sid, t.closing, t.trained .. ": the closing line (D-5)")
		lu.assertEquals({ row.options[1][1], row.options[1][2], row.options[2][1], row.options[2][2] }, { M.YES, t.brief, M.NO, "not_yet" }, t.trained .. ": Yes -> the briefing, No -> not_yet")
	end

	lu.assertEquals(dialogOf.trained_procedures, dialogOf.trained_droid, "procedures and droid share the plain 'Good choice.' line (D-5)")
end

-- AC-5 (the oracle itself): the text of the %TU / %NU lines and the pre-NGE-only lines
function TestSmugglerT2TemplateOracle:test_the_name_token_lines_and_the_pre_nge_lines_are_the_words_of_the_client()
	for _, sid in ipairs({ "s_1f4922ce", "s_57adb96", "s_5f96d75a", "s_650a0c35", "s_c29ec5c2", "s_d6924ee9", "s_383435", "s_dffe951a" }) do
		lu.assertEquals(TEXT[sid]:find("%NU", 1, true) ~= nil, true, sid .. " carries %NU")
	end

	lu.assertEquals(TEXT.s_45b71b4d, "I am interested in advanced fighters.", "starships topic")
	lu.assertEquals(TEXT.s_197f4f94, "I am interested in intermediate starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_8f5942fa, "I am interested in starship defense training.", "procedures topic")
	lu.assertEquals(TEXT.s_eff66f4d, "I am interested in reactor engineering algorithms.", "droid topic")
	lu.assertEquals(TEXT.s_36a4e374, "Yes, I am.", "yes")
	lu.assertEquals(TEXT.s_da9a29e9, "No, not yet.", "no")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestSmugglerT2Template = {}

function TestSmugglerT2Template:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-5, I-8
function TestSmugglerT2Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(#got, 59, M.TEMPLATE .. ": number of screens")
	lu.assertEquals(got, M.screenIds(), M.TEMPLATE .. ": screen ids (59, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestSmugglerT2Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(M.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, M.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, M.PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation (a string, as the other templates)")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-14)")
	end
end

-- AC-5, I-8: the static options in order (the template defaults of the conditional links, Conversation flow 2)
function TestSmugglerT2Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(M.SCREENS) do
		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = { M.PREFIX .. o[1], o[2] }
		end

		local got = {}

		for i, o in ipairs(byId[row.id].options) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-5, I-8
function TestSmugglerT2Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(M.TEMPLATE), {}, M.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestSmugglerT2Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, M.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line and reply is a trailing comment
function TestSmugglerT2Template:test_every_dialog_line_and_reply_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(M.TEMPLATE_FILE)
	local dialogs, replies = 0, 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_trainer_shamdon:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			dialogs = dialogs + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_privateer_trainer_shamdon", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		else
			local osid, ocomment = line:match('{%s*"@conversation/tatooine_privateer_trainer_shamdon:(s_[%w_]+)"%s*,%s*"[%w_]+"%s*}%s*,?%s*%-%-%s*(.-)%s*$')

			if osid ~= nil then
				replies = replies + 1
				lu.assertEquals(ocomment, (TEXT[osid]:gsub("%s+$", "")), "trailing comment of the option line for " .. osid)
			elseif line:find("{%s*\"@conversation/tatooine_privateer_trainer_shamdon") then
				lu.fail("option line without the trailing client text: " .. line)
			end
		end
	end

	local want = 0

	for _, row in ipairs(M.SCREENS) do
		want = want + #row.options
	end

	lu.assertEquals(dialogs, 59, "leftDialog lines with a comment")
	lu.assertEquals(replies, want, "option lines with a comment")
end

-- Content contract 3: the first line is a header comment, the file registers the template
function TestSmugglerT2Template:test_the_template_file_starts_with_a_header_comment_and_registers_through_add_conversation_template()
	local source = readFile(M.TEMPLATE_FILE)
	local first = source:match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "first line of shamdon_kree_convo.lua is a header comment (Karrde style)")
	lu.assertNotNil(source:find('addConversationTemplate("shamdon_kree_convo_template", shamdon_kree_convo_template)', 1, true), "shamdon_kree_convo.lua ends with addConversationTemplate")
	lu.assertNotNil(source:find('luaClassHandler = "shamdonKreeConvoHandler"', 1, true), "shamdon_kree_convo.lua names its handler")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, I-8)
---------------------------------------------------------------------------------------------

TestSmugglerT2ClientStrings = {}

function TestSmugglerT2ClientStrings:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestSmugglerT2ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: exactly the 100 STF lines, no NGE editor number
function TestSmugglerT2ClientStrings:test_the_sources_use_exactly_the_100_client_lines_and_no_decimal_id()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == M.STF then
			used[lit.id] = true
		else
			lu.fail(lit.path .. ":" .. lit.line .. " names another string file: " .. lit.file)
		end
	end

	local got = {}

	for id in pairs(used) do
		got[#got + 1] = id
	end

	-- the NGE editor numbers: the string ids the SWG script uses that the pre-NGE client file lacks (81). Note that a few real client ids are all digits (s_383435)
	local ids = CS.sids(M.STF)
	local nge, n = {}, 0
	local java = assert(io.open(M.SHJ, "r")):read("a")

	for id in java:gmatch('string_id%(c_stringFile, "([%w_]+)"%)') do
		if not ids[id] and not nge[id] then
			nge[id] = true
			n = n + 1
		end
	end

	lu.assertEquals(n, 81, "string ids of the SWG script the pre-NGE client file lacks (the NGE editor numbers)")

	for id in pairs(used) do
		lu.assertNil(nge[id], "NGE editor number " .. id .. " in the sources")
	end

	table.sort(got)
	lu.assertEquals(got, M.usedIds(), "distinct tatooine_privateer_trainer_shamdon ids used by the template and handler")
end

-- AC-5: complete literals only
function TestSmugglerT2ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Shamdon sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the ratchet's referenced files include the new file, with the count of the generated fixture
function TestSmugglerT2ClientStrings:test_the_ratchet_references_the_shamdon_file_with_102_ids()
	local KD = require("space_convo_client_strings_data")

	lu.assertEquals(KD.FIXTURE_COUNTS[M.STF], 102, "FIXTURE_COUNTS[" .. M.STF .. "]")
	lu.assertEquals(KD.KNOWN_GAPS, {}, "KNOWN_GAPS")

	local found = false

	for _, f in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		found = found or f == M.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. M.STF)
end

-- AC-5: the fixture is the client's list (the maintenance tool's --check, only where /tre and python exist)
function TestSmugglerT2ClientStrings:test_the_sids_fixture_equals_the_client_file()
	local f = io.open("/tre/patch_12_00.tre", "rb")

	if f == nil then
		lu.skip("/tre/patch_12_00.tre is not available")
	end

	f:close()

	local pipe = io.popen("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check conversation/tatooine_privateer_trainer_shamdon 2>&1; echo \"rc=$?\"")
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out:match("rc=(%d+)"), "0", "gen_client_sids.py --check conversation/tatooine_privateer_trainer_shamdon: " .. out)
end

---------------------------------------------------------------------------------------------
-- The player's first name (%TU / %NU)
---------------------------------------------------------------------------------------------

TestSmugglerT2Names = {}

function TestSmugglerT2Names:setUp()
	H.reset()
	M.requireConversation(lu)

	for _, g in ipairs(M.questTables()) do
		H.spyOn(rawget(_G, g), "startQuest") -- the briefing and duty screens start quests; only the dialog parameter is under test here
	end
end

-- AC-5: the %NU lines get the pilot's first name through setDialogTextTU
function TestSmugglerT2Names:test_lines_with_the_player_name_get_the_first_name()
	for _, id in ipairs({ "m3_paid_naturally", "m3_paid_yes", "naive", "bad_news", "bad_news_reply", "ready_mission", "training", "m2_paid" }) do
		local t = M.drive(M.pilot({ tier2 = 4, all4 = true }), id)

		lu.assertEquals(t[1].id, id, "screen shown")
		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the name parameter")
	end
end

-- AC-5: the handler fills the name on every screen it shows (it is harmless on a line without a token)
function TestSmugglerT2Names:test_every_screen_is_shown_with_the_first_name_set()
	for _, row in ipairs(M.SCREENS) do
		local t = M.drive(M.pilot({}), row.id)

		lu.assertEquals(t[1].id, row.id, "screen shown")
		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the name parameter")
	end
end

-- AC-5: the shown dialog keeps the template untouched (the handler works on a clone)
function TestSmugglerT2Names:test_showing_a_screen_does_not_change_the_template_screen()
	local before = {}

	for _, s in ipairs(template().screens) do
		before[s.id] = { s.leftDialog, #s.options }

		for i, o in ipairs(s.options) do
			before[s.id][#before[s.id] + 1] = o[1] .. ">" .. o[2]
		end
	end

	for _, id in ipairs({ "off_track", "talon_only", "package", "m1_reward", "m2_paid", "ready_mission", "training" }) do
		M.drive(M.pilot({ tier2 = 1 }), id)
	end

	for _, s in ipairs(template().screens) do
		local now = { s.leftDialog, #s.options }

		for i, o in ipairs(s.options) do
			now[#now + 1] = o[1] .. ">" .. o[2]
		end

		lu.assertEquals(now, before[s.id], "screen '" .. s.id .. "' in the template after the conditional links were built")
	end
end
