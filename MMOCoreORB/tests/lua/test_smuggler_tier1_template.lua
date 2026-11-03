-- Dravis: the conversation template (Appendix A), its client strings and the SWG java graph.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FS-3, FS-4; Q1 = A).
--
-- Answer keys: smuggler_tier1_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_privateer_trainer_1.java (harness/swgjava.lua) for every link that is not a twin, rejoin, handler-set or
-- pre-NGE-only line, and the generated client id list fixtures/string/en/conversation/tatooine_privateer_trainer_1.sids.
-- TestSmugglerT1Oracle* classes need no production code and are green from the start; they prove the spec's Appendix A against J and the client.

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")
local TEXT = require("smuggler_tier1_client_text")
local Swgjava = require("harness.swgjava")

S.load()

local PATHS = { S.TEMPLATE_FILE, S.HANDLER_FILE }
local PREFIX = S.PREFIX

-- the two lines the handler adds through conditional links (C-2 without a ship, C-4 the "I got a ship." reply); no static option has them
local HANDLER_ONLY = { "s_fc0b7ade", "s_2268b9e0" }

local function template() return H.conversationTemplateTable(S.TEMPLATE) end

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

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_1.java")

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT1Oracle2 = {}

function TestSmugglerT1Oracle2:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 81 screens, ids unique, and with the two handler lines it uses all 150 client lines and no other
function TestSmugglerT1Oracle2:test_appendix_a_has_81_screens_and_uses_every_client_line()
	lu.assertEquals(#S.SCREENS, 81, "Appendix A rows (Q1 = A)")

	local seen, used = {}, {}

	for _, row in ipairs(S.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	for _, sid in ipairs(HANDLER_ONLY) do
		used[sid] = true
	end

	for _, t in ipairs(S.TRAIN) do
		used[t.reply] = true
		used[t.closing] = true
	end

	local ids = CS.sids(S.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. S.STF .. ".sids")

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

-- AC-5 (the oracle itself): the generated client id list holds the 152 entries the spec names
function TestSmugglerT1Oracle2:test_the_client_id_fixture_holds_152_ids()
	local ids = CS.sids(S.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 152, "ids in fixtures/string/en/" .. S.STF .. ".sids (150 lines plus do_not_edit and s_0)")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FS-3, FS-4) and the %TU / %NU lines, so a wrong sid fails with the words
function TestSmugglerT1Oracle2:test_the_pre_nge_only_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_2268b9e0, "I got a ship.", "Q1 reply")
	lu.assertEquals(TEXT.s_140229b8:sub(1, 25), "Oh yeah? That was fast. M", "Q1 line")
	lu.assertEquals(TEXT.s_d335136f, "Yes I am.", "Q1 sign up")
	lu.assertEquals(TEXT.s_4440ce87, "I changed my mind.", "Q1 refuse")
	lu.assertEquals(TEXT.s_31fc5801, "Well then go away and stop bothering me. I'm a busy man!", "Q1 go away")
	lu.assertEquals(TEXT.s_3818dc2a, "I am interested in basic fighters.", "starships topic")
	lu.assertEquals(TEXT.s_3fa70900, "I am interested in basic starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_7d57477f, "I am interested in basic training.", "procedures topic")
	lu.assertEquals(TEXT.s_9480f430, "I am interested in droid interface basics.", "droid topic")
	lu.assertEquals(TEXT.s_d3d66c68, "Excellent! Now talk to Talon Karrde.", "tier_done_talk")
	lu.assertEquals(TEXT.s_110c7bdd:find("%TU", 1, true) ~= nil, true, "s_110c7bdd carries %TU")
	lu.assertEquals(TEXT.s_f17c03b4:find("%TU", 1, true) ~= nil, true, "s_f17c03b4 carries %TU")
	lu.assertEquals(TEXT.s_85355c2f:find("%NU", 1, true) ~= nil, true, "s_85355c2f carries %NU")
end

-- AC-5 (the oracle itself): the answer key parses
function TestSmugglerT1Oracle2:test_the_answer_key_parses_88_npc_lines()
	lu.assertEquals(#GRAPH.order, 88, "NPC lines parsed from tatooine_privateer_trainer_1.java")
end

-- AC-5, I-8 (the oracle itself): Appendix A agrees with the java: every line that is in the java ends where it ends and every original reply leads where the java leads
function TestSmugglerT1Oracle2:test_every_original_reply_and_end_flag_of_appendix_a_agrees_with_the_swg_script()
	local dialogOf = {}

	for _, row in ipairs(S.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked = 0

	for _, row in ipairs(S.SCREENS) do
		-- the pre-NGE training lines are not in the java (FS-3), and the mission 1 offer is the rejoin of the NGE-numbered s_113 (Data mapping 3)
		if row.tag ~= "P" and row.id ~= "mission1_offer" then
			local node = GRAPH.nodes[row.sid]

			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

			local have = {}

			for _, o in ipairs(node.options) do
				have[o] = true
			end

			for _, o in ipairs(row.options) do
				if o[3] == "" then
					checked = checked + 1
					lu.assertTrue(have[o[1]] == true, "screen '" .. row.id .. "': the java line " .. row.sid .. " has no reply " .. o[1])

					local ok = false

					for _, succ in ipairs(GRAPH.successorsOf(row.sid, o[1])) do
						if succ == dialogOf[o[2]] then
							ok = true
						end
					end

					lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. o[1] .. ": the java leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
				end
			end
		end
	end

	lu.assertEquals(checked, 89, "original (non-twin, non-rejoin) replies checked against the java")
end

-- Data mapping 3 (the oracle itself): each twin reply is a client reply of the same slot, each rejoin is the java's action line
function TestSmugglerT1Oracle2:test_the_twin_and_rejoin_slots_are_replies_the_client_has()
	local ids = CS.sids(S.STF)

	for _, row in ipairs(S.SCREENS) do
		for _, o in ipairs(row.options) do
			if o[3] ~= "" then
				lu.assertTrue(ids[o[1]] == true, "screen '" .. row.id .. "': twin/rejoin reply " .. o[1] .. " is not a client line")
			end
		end
	end

	-- the rejoin of s_95 is the client's only M1 brief, the same action (grantQuestOne) as the java's s_95
	lu.assertEquals(S.screenRow("recruit_loan_ship").options[1], { "s_1adbadc4", "mission1_brief", "R" }, "recruit_loan_ship: the rejoin")
	lu.assertEquals(S.screenRow("mission1_brief").sid, "s_95df6b05", "mission1_brief: the client's only M1 brief")
	lu.assertEquals(S.screenRow("mission1_offer").sid, "s_95df6b05", "mission1_offer: the same brief text, without the grant")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestSmugglerT1Template = {}

function TestSmugglerT1Template:setUp()
	H.reset()
	S.requireConversation(lu)
end

-- AC-5, I-8
function TestSmugglerT1Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, S.screenIds(), S.TEMPLATE .. ": screen ids (81, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestSmugglerT1Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(S.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, S.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-13)")
	end
end

-- AC-5, I-8: the static options in order (the recruitment row lacks the C-4 reply; first_training and more_training carry the four topics)
function TestSmugglerT1Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(S.SCREENS) do
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
function TestSmugglerT1Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(S.TEMPLATE), {}, S.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestSmugglerT1Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, S.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestSmugglerT1Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(S.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_trainer_1:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_privateer_trainer_1", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 81, "leftDialog lines with a comment")
end

-- AC-5, I-8: the template is the include target; the first screen is chosen by the handler
function TestSmugglerT1Template:test_the_template_file_registers_through_add_conversation_template()
	local source = readFile(S.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate("dravis_convo_template", dravis_convo_template)', 1, true), "dravis_convo.lua ends with addConversationTemplate")
	lu.assertNotNil(source:find('luaClassHandler = "dravisConvoHandler"', 1, true), "dravis_convo.lua names its handler")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestSmugglerT1ClientStrings = {}

function TestSmugglerT1ClientStrings:setUp()
	H.reset()
	S.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestSmugglerT1ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: none of the 26 NGE editor numbers of the java script (s_31 s_47 s_77 s_82 s_95 s_97 s_113 s_121 s_128 s_186 .. s_210) appears in either file.
-- (A plain "s_<digits>" pattern would also match real client ids that happen to be all digits, e.g. s_70421509.)
function TestSmugglerT1ClientStrings:test_neither_source_uses_an_nge_numbered_id()
	local nge = { s_31 = true, s_47 = true, s_77 = true, s_82 = true, s_95 = true, s_97 = true, s_113 = true, s_121 = true, s_128 = true }

	for n = 186, 210 do
		nge["s_" .. n] = true
	end

	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if nge[lit.id] then
			used[#used + 1] = lit.path .. ":" .. lit.line .. " " .. lit.id
		end
	end

	lu.assertEquals(used, {}, "NGE editor numbers in the Dravis sources")
end

-- AC-5 (Q1 = A): the port uses all 150 client lines and no other id
function TestSmugglerT1ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(S.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == S.STF then
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
	lu.assertEquals(missing, {}, "client lines of tatooine_privateer_trainer_1 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 150, "distinct ids used")
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestSmugglerT1ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Dravis sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestSmugglerT1ClientStrings:test_the_handler_names_the_four_topic_replies_and_the_two_handler_lines_as_complete_literals()
	local source = readFile(S.HANDLER_FILE)

	for _, t in ipairs(S.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "dravisConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	for _, sid in ipairs(HANDLER_ONLY) do
		lu.assertNotNil(source:find('"' .. PREFIX .. sid .. '"', 1, true), "dravisConvoHandler.lua: complete literal for the conditional reply " .. sid)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "dravisConvoHandler.lua: no stringFile prefix local")
end

-- AC-5, FS-3: the closing line of each topic is the pre-NGE line, on a screen that ends the conversation
function TestSmugglerT1ClientStrings:test_the_trained_screens_show_the_pre_nge_closing_lines_and_end_the_conversation()
	local byId = screensById()

	for _, t in ipairs(S.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.closing, t.trained .. " shows its closing line")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends the conversation")
	end
end

---------------------------------------------------------------------------------------------
-- The player's first name (%TU / %NU)
---------------------------------------------------------------------------------------------

TestSmugglerT1Names = {}

function TestSmugglerT1Names:setUp()
	H.reset()
	S.requireConversation(lu)
end

-- AC-5 (Content contract 3): lines with %TU or %NU get the pilot's first name through setDialogTextTU
function TestSmugglerT1Names:test_lines_with_the_player_name_get_the_first_name()
	for _, head in ipairs(S.HEADS) do
		H.spyOn(S.quest(head), "startQuest") -- the accept screens start their mission; only the dialog parameter is under test here
	end

	for _, id in ipairs({ "mission3_accept", "tier_done_oh_and", "mission4_accept" }) do
		local t = S.drive(S.pilot({ paid = 1 }), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the name parameter")
	end
end
