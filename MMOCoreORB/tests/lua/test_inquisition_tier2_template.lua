-- Inquisitor Fa'Zoll: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FF-1, FF-2, FF-6; D-2, D-4).
--
-- Answer keys: inquisition_tier2_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/naboo_imperial_trainer_2.java (harness/swgjava.lua) for every link that is not a rejoin, a pre-NGE-only line or
-- a handler-built link, and the generated client id list fixtures/string/en/conversation/naboo_imperial_trainer_2.sids (177 ids).

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")
local TEXT = require("inquisition_tier2_client_text")
local Swgjava = require("harness.swgjava")

I.load()

local PATHS = { I.TEMPLATE_FILE, I.HANDLER_FILE }
local PREFIX = I.PREFIX

-- screens whose options the handler builds from TRAIN_CHOICES (C-5): the template may hold them or not, so only the displayed options are pinned
local BUILT_MENUS = { training_menu = true, m4_more_training = true }

local function template() return H.conversationTemplateTable(I.TEMPLATE) end

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

TestInquisitionT2Oracle = {}

function TestInquisitionT2Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 103 screens, ids unique, and uses all 175 client lines and no other id
function TestInquisitionT2Oracle:test_appendix_a_has_103_screens_and_uses_every_client_line()
	lu.assertEquals(#I.SCREENS, 103, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(I.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	-- the one reply only the handler adds: m4_won / s_c104d444 -> m4_more_training (C-3)
	used[I.M4_MORE_TRAINING_REPLY] = true

	local ids = CS.sids(I.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. I.STF .. ".sids")

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

-- AC-5 (the oracle itself): the TRAIN table's replies and trained screens are Appendix A rows
function TestInquisitionT2Oracle:test_the_train_table_matches_appendix_a()
	local menu = I.screenRow("training_menu")

	for i, t in ipairs(I.TRAIN) do
		lu.assertEquals(menu.options[i], { t.reply, t.trained }, "training_menu option " .. i)
		lu.assertEquals(I.screenRow(t.trained).sid, t.trainedSid, t.trained .. ": dialog")
	end

	lu.assertEquals(menu.options[5], { I.LATER, "training_later" }, "training_menu last option")
end

-- AC-5 (the oracle itself): the generated client id list holds the 177 lines the spec names
function TestInquisitionT2Oracle:test_the_client_id_fixture_holds_177_ids()
	local ids = CS.sids(I.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 177, "ids in fixtures/string/en/" .. I.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only and rejoined lines (FF-1, FF-6, Data mapping 3), so a wrong sid fails with the words
function TestInquisitionT2Oracle:test_the_pre_nge_and_rejoin_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_21772e5a, "I'm sorry, I can't help you.", "not-pilot gate")
	lu.assertEquals(TEXT.s_987445c9, "Thank you, sir.", "thank you")
	lu.assertEquals(TEXT.s_89bc583c, "Very well, sir.", "very well")
	lu.assertEquals(TEXT.s_8efde2ae, "Yes, sir.", "yes sir")
	lu.assertEquals(TEXT.s_b6b25f13, "Yes, sir!", "yes sir!")
	lu.assertEquals(TEXT.s_846f2737, "Yes, sir! I will not fail you again.", "will not fail")
	lu.assertEquals(TEXT.s_9ac35c60:sub(-37), "What area would you like to train in?", "training menu")
	lu.assertEquals(TEXT.s_ae26c22, "Let me think about this for a bit.", "think about it")
	lu.assertEquals(TEXT.s_594a07fa, "I want to study advanced TIE combat operations.", "starships topic")
	lu.assertEquals(TEXT.s_be30f309, "I want to study advanced equipment technology.", "weapons topic")
	lu.assertEquals(TEXT.s_e73e5d21, "I want to study pilot combat training.", "procedures topic")
	lu.assertEquals(TEXT.s_c76594d7, "I want to study advanced reactor engineering algorithms.", "droid topic")
	lu.assertStrContains(TEXT.s_8e4bd7c1, "Report back to me when you are ready for a new assignment.")
	lu.assertStrContains(TEXT.s_486da900, "Use these study programs and destroy them when you have internalized the information.")
end

TestInquisitionT2Template = {}

function TestInquisitionT2Template:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5, I-8
function TestInquisitionT2Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, I.screenIds(), I.TEMPLATE .. ": screen ids (103, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestInquisitionT2Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, I.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-17)")
	end
end

-- AC-5, I-8: the static options in order (the training menus are built at run time; their template options are not pinned)
function TestInquisitionT2Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
		if not BUILT_MENUS[row.id] then
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
end

-- AC-5
function TestInquisitionT2Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(I.TEMPLATE), {}, I.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestInquisitionT2Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, I.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestInquisitionT2Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(I.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_imperial_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_imperial_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 103, "leftDialog lines with a comment")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, FF-6)
---------------------------------------------------------------------------------------------

TestInquisitionT2ClientStrings = {}

function TestInquisitionT2ClientStrings:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks, in particular no NGE editor number
function TestInquisitionT2ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5: none of the 32 NGE editor numbers of J2 (Source inventory) is used by either file
function TestInquisitionT2ClientStrings:test_neither_source_uses_an_nge_editor_number()
	local nge = { 4, 6, 89, 100, 130, 133, 143, 147, 150, 168, 174 }

	for n = 213, 248 do
		nge[#nge + 1] = n
	end

	local ids = CS.sids(I.STF)

	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		for _, n in ipairs(nge) do
			lu.assertNil(ids["s_" .. n], "precondition: the client has no s_" .. n)
			lu.assertNil(source:find('@conversation/naboo_imperial_trainer_2:s_' .. n .. '"', 1, true), path .. " uses the NGE editor id s_" .. n .. " that the pre-NGE client lacks")
		end
	end
end

-- AC-5: the port uses all 175 client lines and no other id
function TestInquisitionT2ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(I.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == I.STF then
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
	lu.assertEquals(missing, {}, "client lines of naboo_imperial_trainer_2 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 175, "distinct ids used")
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestInquisitionT2ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Fa'Zoll sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestInquisitionT2ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(I.HANDLER_FILE)

	for _, t in ipairs(I.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "faZollConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "faZollConvoHandler.lua: no stringFile prefix local")
end

-- FF-1, FF-2: the training menu shows the pre-NGE menu line and each trained screen its topic description, and all four close with the report line
function TestInquisitionT2ClientStrings:test_the_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. I.MENU_LINE, "training_menu shows the menu line")
	lu.assertEquals(byId.m4_more_training.leftDialog, PREFIX .. "s_7be3e248", "m4_more_training shows its own line")

	for _, t in ipairs(I.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows the topic description")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][1], PREFIX .. I.THANK_YOU, t.trained .. ": the one reply")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][2], "trained_report", t.trained .. ": leads to trained_report")
	end

	lu.assertEquals(byId.trained_report.leftDialog, PREFIX .. "s_8e4bd7c1", "trained_report")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8, D-2)
---------------------------------------------------------------------------------------------

TestInquisitionT2JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_imperial_trainer_2.java")

-- The replies of Appendix A the java does not have, or leads elsewhere: Data mapping 3 (screen, reply, link)
local NOT_IN_JAVA = {
	{ "m1_another_meeting", "s_846f2737", "m1_retry" },    -- s_174
	{ "m1_pay", "s_987445c9", "m1_bite_to_eat" },           -- s_168
	{ "m2_offer", "s_b6b25f13", "m2_decrypted" },           -- s_147
	{ "m2_decrypted", "s_8efde2ae", "m2_encryption" },      -- s_150
	{ "m2_failed", "s_8efde2ae", "m2_retry" },              -- s_143
	{ "m2_promotion", "s_987445c9", "m2_pay" },             -- s_130
	{ "m2_pay", "s_89bc583c", "m2_local_command" },         -- s_133
	{ "duty_escort", "s_8efde2ae", "duty_escort_warned" },  -- s_89
	{ "training_menu", "s_594a07fa", "trained_starships" },
	{ "training_menu", "s_be30f309", "trained_weapons" },
	{ "training_menu", "s_e73e5d21", "trained_procedures" },
	{ "training_menu", "s_c76594d7", "trained_droid" },
	{ "m4_more_training", "s_594a07fa", "trained_starships" },
	{ "m4_more_training", "s_be30f309", "trained_weapons" },
	{ "m4_more_training", "s_e73e5d21", "trained_procedures" },
	{ "m4_more_training", "s_c76594d7", "trained_droid" },
}

-- The screens that have no NPC line in the java: the pre-NGE lines in the NGE training slots (Data mapping 3, class P)
local NOT_IN_JAVA_SCREENS = { trained_starships = true, trained_weapons = true, trained_procedures = true, trained_droid = true, trained_report = true }

function TestInquisitionT2JavaGraph:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5 (the oracle itself)
function TestInquisitionT2Oracle:test_the_answer_key_parses_113_npc_lines()
	lu.assertEquals(#GRAPH.order, 113, "NPC lines parsed from naboo_imperial_trainer_2.java")
end

-- AC-5, I-8: every screen that exists in the java ends exactly where the java ends, and every original reply leads where the java leads
function TestInquisitionT2JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}
	local skip = {}

	for _, row in ipairs(I.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	for _, d in ipairs(NOT_IN_JAVA) do
		skip[d[1] .. "|" .. d[2] .. "|" .. d[3]] = true
	end

	local checked = 0

	for _, row in ipairs(I.SCREENS) do
		if not NOT_IN_JAVA_SCREENS[row.id] then
			local node = GRAPH.nodes[row.sid]

			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

			local have = {}

			for _, o in ipairs(node.options) do
				have[o] = true
			end

			for _, o in ipairs(row.options) do
				if not skip[row.id .. "|" .. o[1] .. "|" .. o[2]] then
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

	lu.assertEquals(checked, 82, "original replies checked against the java (102 static replies less the 16 rejoined or built and the 4 replies of the pre-NGE trained screens)")
end

-- AC-5: the deviation list is exact: each listed reply really is a row of Appendix A and absent from the java
function TestInquisitionT2JavaGraph:test_the_listed_rejoins_are_appendix_a_rows_the_java_does_not_have()
	for _, d in ipairs(NOT_IN_JAVA) do
		local row = I.screenRow(d[1])

		lu.assertNotNil(row, "Appendix A row " .. d[1])

		local found = false

		for _, o in ipairs(row.options) do
			if o[1] == d[2] and o[2] == d[3] then
				found = true
			end
		end

		lu.assertTrue(found, d[1] .. " has the reply " .. d[2] .. " -> " .. d[3] .. " in Appendix A")

		local node = GRAPH.nodes[row.sid]
		local javaHas = false

		for _, o in ipairs(node.options) do
			if o == d[2] then
				javaHas = true
			end
		end

		lu.assertFalse(javaHas, d[1] .. ": the java line " .. row.sid .. " does not have the reply " .. d[2] .. " (a rejoin, Data mapping 3)")
	end
end

---------------------------------------------------------------------------------------------
-- The %TU / %NU lines
---------------------------------------------------------------------------------------------

TestInquisitionT2Names = {}

function TestInquisitionT2Names:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5 (Content contract 3): lines with %TU / %NU get the pilot's first name, and only those
function TestInquisitionT2Names:test_lines_with_the_player_name_get_the_first_name()
	local n = 0

	for _, row in ipairs(I.SCREENS) do
		if row.token ~= "" then
			n = n + 1

			local t = I.drive(I.pilot({ paid = 1 }), row.id)

			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %" .. row.token .. " parameter")
		end
	end

	lu.assertEquals(n, 6, "screens with a name token in Appendix A")
end

-- AC-5: the token screens of Appendix A really are the client lines that carry a token
function TestInquisitionT2Names:test_the_name_token_screens_are_exactly_the_client_lines_with_a_token()
	local fromText, fromRows = {}, {}

	for _, row in ipairs(I.SCREENS) do
		local text = TEXT[row.sid]

		if text:find("%%[TN]U") then
			fromText[row.id] = true
		end

		if row.token ~= "" then
			fromRows[row.id] = true
		end
	end

	lu.assertEquals(fromRows, fromText, "Appendix A token screens vs client lines with %TU/%NU")
end
