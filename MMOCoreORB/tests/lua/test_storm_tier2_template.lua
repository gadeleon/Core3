-- Commander Oberhaur: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-7, invariant I-8; Content contract 4; Data mapping 3; FI-2, FI-6; D-3, D-5).
--
-- Answer keys: storm_tier2_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_imperial_trainer_2.java (harness/swgjava.lua) for every link that is not a rejoin, a pre-NGE-only line or
-- a handler-built link, and the generated client id list fixtures/string/en/conversation/tatooine_imperial_trainer_2.sids (190 ids).

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")
local TEXT = require("storm_tier2_client_text")
local Swgjava = require("harness.swgjava")

T.load()

local PATHS = { T.TEMPLATE_FILE, T.HANDLER_FILE }
local PREFIX = T.PREFIX

-- screens whose options the handler builds from TRAIN_CHOICES (C-4): the template may hold the topic replies or not, so only the displayed options are pinned
local BUILT_MENUS = { training_menu = true }

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

local function exists(path)
	local f = io.open(H.SCRIPTS .. path, "r")

	if f then
		f:close()
		return true
	end

	return false
end

TestStormT2Oracle = {}

function TestStormT2Oracle:setUp() H.reset() end

-- AC-7 (the oracle itself): Appendix A has 113 screens, ids unique, and uses all 188 client lines and no other id
function TestStormT2Oracle:test_appendix_a_has_113_screens_and_uses_every_client_line()
	lu.assertEquals(#T.SCREENS, 113, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(T.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	-- the four topic replies only the handler adds (C-4)
	for _, t in ipairs(T.TRAIN) do
		used[t.reply] = true
	end

	local ids = CS.sids(T.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. T.STF .. ".sids")

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

-- AC-7 (the oracle itself): the TRAIN table's trained screens are Appendix A rows and the topic replies appear nowhere else
function TestStormT2Oracle:test_the_train_table_matches_appendix_a()
	local menu = T.screenRow("training_menu")

	lu.assertEquals(menu.options, { { T.LATER, "training_later" } }, "training_menu static options (the topics come in through C-4)")

	for _, t in ipairs(T.TRAIN) do
		local row = T.screenRow(t.trained)

		lu.assertEquals(row.sid, t.trainedSid, t.trained .. ": dialog")
		lu.assertEquals(row.options, { { T.THANK_YOU, "trained_report" } }, t.trained .. ": its one reply")

		for _, r in ipairs(T.SCREENS) do
			for _, o in ipairs(r.options) do
				lu.assertNotEquals(o[1], t.reply, "topic reply " .. t.reply .. " must not be a static option of '" .. r.id .. "'")
			end
		end
	end
end

-- AC-7 (the oracle itself): the generated client id list holds the 190 entries the spec names
function TestStormT2Oracle:test_the_client_id_fixture_holds_190_ids()
	local ids = CS.sids(T.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 190, "ids in fixtures/string/en/" .. T.STF .. ".sids")
end

-- AC-7 (the oracle itself): the exact client text of the pre-NGE-only and rejoined lines (FI-2, Data mapping 3), so a wrong sid fails with the words
function TestStormT2Oracle:test_the_pre_nge_and_rejoin_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_21772e5a, "I'm sorry, I can't help you.", "not-pilot gate")
	lu.assertEquals(TEXT.s_987445c9, "Thank you, sir.", "thank you")
	lu.assertEquals(TEXT.s_89bc583c, "Very well, sir.", "very well")
	lu.assertEquals(TEXT.s_8efde2ae, "Yes, sir.", "yes sir")
	lu.assertEquals(TEXT.s_b6b25f13, "Yes, sir!", "yes sir!")
	lu.assertEquals(TEXT.s_61657d0f, "I see.", "I see")
	lu.assertEquals(TEXT.s_2c4789b, "Understood.", "understood")
	lu.assertEquals(TEXT.s_9288900f, "I understand.", "I understand")
	lu.assertEquals(TEXT.s_5102164f, "(Nod and listen.)", "nod and listen")
	lu.assertEquals(TEXT.s_ac71da57, "I'm ready to take an assignment.", "duty menu reply")
	lu.assertEquals(TEXT.s_b0d3b474, "I'm ready for training.", "training reply")
	lu.assertEquals(TEXT.s_ae26c22, "Let me think about this for a bit.", "think about it")
	lu.assertStrContains(TEXT.s_44d66989, "What area would you like to train in?")
	lu.assertEquals(TEXT.s_594a07fa, "I want to study advanced TIE combat operations.", "starships topic")
	lu.assertEquals(TEXT.s_dbb5bf46, "I want to study advanced weapons technology.", "weapons topic")
	lu.assertEquals(TEXT.s_e73e5d21, "I want to study pilot combat training.", "procedures topic")
	lu.assertEquals(TEXT.s_c76594d7, "I want to study advanced reactor engineering algorithms.", "droid topic")
	lu.assertEquals(TEXT.s_9c0c10ef, "Report back to me when you are ready for a new assignment.", "trained report")

	for _, id in ipairs({ "s_486da900", "s_8bd72bb5", "s_c4880407", "s_31804e15" }) do
		lu.assertStrContains(TEXT[id], "Use these study programs and destroy them when you have internalized the information.")
	end
end

TestStormT2Template = {}

function TestStormT2Template:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-7, I-8
function TestStormT2Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, T.screenIds(), T.TEMPLATE .. ": screen ids (113, no duplicates)")
end

-- AC-7, I-8: dialog, end flag, animation per screen
function TestStormT2Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-3)")
	end
end

-- AC-7, I-8: the static options in order (the training menu is built at run time; its template options are not pinned)
function TestStormT2Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
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

-- AC-7, I-8
function TestStormT2Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 4: the template shape
function TestStormT2Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, T.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 4: the English text of every line is a trailing comment on the leftDialog line
function TestStormT2Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(T.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_imperial_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_imperial_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 113, "leftDialog lines with a comment")
end

-- Content contract 4: the include lines wire the file in (also covers a template that is registered under another name)
function TestStormT2Template:test_the_template_and_handler_files_exist_at_the_contract_paths()
	lu.assertTrue(exists(T.TEMPLATE_FILE), T.TEMPLATE_FILE)
	lu.assertTrue(exists(T.HANDLER_FILE), T.HANDLER_FILE)
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-7)
---------------------------------------------------------------------------------------------

TestStormT2ClientStrings = {}

function TestStormT2ClientStrings:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-7: no id the pre-NGE client lacks, in particular no NGE editor number
function TestStormT2ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-7: no s_<decimal> id (the NGE editor numbers have one to three digits; the all-digit hash id s_1524504 is a real client line) in either file
function TestStormT2ClientStrings:test_neither_source_uses_a_decimal_nge_editor_number()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		for n in source:gmatch('@conversation/tatooine_imperial_trainer_2:s_(%d%d?%d?)"') do
			lu.fail(path .. " uses the NGE editor id s_" .. n .. " that the pre-NGE client lacks")
		end
	end
end

-- AC-7: the port uses all 188 client lines and no other id
function TestStormT2ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(T.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == T.STF then
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
	lu.assertEquals(missing, {}, "client lines of tatooine_imperial_trainer_2 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 188, "distinct ids used")
end

-- AC-7: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestStormT2ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Oberhaur sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-7: TRAIN_CHOICES holds complete literals (Content contract 4)
function TestStormT2ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(T.HANDLER_FILE)

	for _, t in ipairs(T.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "oberhaurConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "oberhaurConvoHandler.lua: no stringFile prefix local")
end

-- FI-2: the training menu shows the pre-NGE menu line and each trained screen its topic description, and all four close with the report line
function TestStormT2ClientStrings:test_the_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. "s_44d66989", "training_menu shows the menu line")

	for _, t in ipairs(T.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows the topic description")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][1], PREFIX .. T.THANK_YOU, t.trained .. ": the one reply")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][2], "trained_report", t.trained .. ": leads to trained_report")
	end

	lu.assertEquals(byId.trained_report.leftDialog, PREFIX .. "s_9c0c10ef", "trained_report")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8, D-3)
---------------------------------------------------------------------------------------------

TestStormT2JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_imperial_trainer_2.java")

-- The replies of Appendix A the java does not have, or leads elsewhere: Data mapping 3 (screen, reply, link)
local NOT_IN_JAVA = {
	{ "travel_need_ship", "s_dcf3ae18", "travel_carry_on" },        -- s_238
	{ "travel_handle", "s_9288900f", "travel_launch" },             -- s_203
	{ "travel_not_nice", "s_c64c7c75", "travel_launch" },           -- s_213, s_215, s_217
	{ "travel_planetary_map", "s_c64c7c75", "travel_launch" },      -- s_221 .. s_227
	{ "off_track_duties", "s_ac71da57", "duty_menu" },              -- s_71
	{ "duty_fleet", "s_b6b25f13", "duty_fleet_aces" },              -- s_76
	{ "duty_smugglers", "s_b6b25f13", "duty_smugglers_guard" },     -- s_81
	{ "claw_duties", "s_ac71da57", "duty_menu" },                   -- s_71
	{ "claw_next_step", "s_ac71da57", "duty_menu" },                -- s_71
	{ "duty_after_m2", "s_ac71da57", "duty_menu" },                 -- s_71
	{ "m2_outstanding", "s_987445c9", "m2_promotion" },             -- s_121
	{ "m2_promotion", "s_b6b25f13", "m2_pay_increase" },            -- s_124
	{ "m2_pay_increase", "s_89bc583c", "m2_lok_ops" },              -- s_127
	{ "m2_same_page", "s_91223b5c", "duty_after_m2" },              -- s_135
	{ "m2_failed", "s_8efde2ae", "m2_retry" },                      -- s_138
	{ "m2_offer", "s_b6b25f13", "m2_decrypted" },                   -- s_142
	{ "m2_decrypted", "s_61657d0f", "m2_ransom" },                  -- s_145
	{ "m2_protect", "s_8efde2ae", "m2_accept" },                    -- s_154
	{ "m1_pay", "s_987445c9", "m1_bite_to_eat" },                   -- s_163
	{ "m1_retry", "s_8efde2ae", "m1_retry_luck" },                  -- s_169
	{ "m1_lok_operation", "s_5102164f", "m1_rebel_link" },          -- s_175
	{ "m1_plan", "s_8efde2ae", "m1_accept" },                       -- s_186
	{ "m1_accept", "s_2c4789b", "m1_return" },                      -- s_189
	{ "form_wrong_name", "s_b2ef8844", "form_sign_it" },            -- s_257
	{ "form_accepted", "s_987445c9", "join_storm" },                -- s_260
	{ "initiate", "s_89bc583c", "initiate_rest" },                  -- s_265
	{ "no_form", "s_9288900f", "come_back_with_form" },             -- s_278
}

-- The screens that have no NPC line in the java: the pre-NGE lines in the NGE training slots (Data mapping 3, class P)
local NOT_IN_JAVA_SCREENS = { trained_starships = true, trained_weapons = true, trained_procedures = true, trained_droid = true, trained_report = true }

function TestStormT2JavaGraph:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-7 (the oracle itself)
function TestStormT2Oracle:test_the_answer_key_parses_128_npc_lines()
	lu.assertEquals(#GRAPH.order, 128, "NPC lines parsed from tatooine_imperial_trainer_2.java")
end

-- AC-7, I-8: every screen that exists in the java ends exactly where the java ends, and every original reply leads where the java leads
function TestStormT2JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}
	local skip = {}

	for _, row in ipairs(T.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	for _, d in ipairs(NOT_IN_JAVA) do
		skip[d[1] .. "|" .. d[2] .. "|" .. d[3]] = true
	end

	local checked = 0

	for _, row in ipairs(T.SCREENS) do
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

	lu.assertEquals(checked, 81, "original replies checked against the java (112 static replies less the 27 rejoined and the 4 replies of the pre-NGE trained screens)")
end

-- AC-7: the deviation list is exact: each listed reply really is a row of Appendix A and absent from the java (or leads elsewhere there)
function TestStormT2JavaGraph:test_the_listed_rejoins_are_appendix_a_rows_the_java_does_not_have()
	for _, d in ipairs(NOT_IN_JAVA) do
		local row = T.screenRow(d[1])

		lu.assertNotNil(row, "Appendix A row " .. d[1])

		local found = false

		for _, o in ipairs(row.options) do
			if o[1] == d[2] and o[2] == d[3] then
				found = true
			end
		end

		lu.assertTrue(found, d[1] .. " has the reply " .. d[2] .. " -> " .. d[3] .. " in Appendix A")

		local node = GRAPH.nodes[row.sid]
		local sameLink = false

		for _, o in ipairs(node.options) do
			if o == d[2] then
				for _, succ in ipairs(GRAPH.successorsOf(row.sid, o)) do
					for _, target in ipairs(T.SCREENS) do
						if target.id == d[3] and target.sid == succ then
							sameLink = true
						end
					end
				end
			end
		end

		lu.assertFalse(sameLink, d[1] .. ": the java line " .. row.sid .. " already has the reply " .. d[2] .. " leading to " .. d[3] .. " (not a rejoin, Data mapping 3)")
	end
end

---------------------------------------------------------------------------------------------
-- The %TU / %NU lines
---------------------------------------------------------------------------------------------

TestStormT2Names = {}

function TestStormT2Names:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-7 (Content contract 4): lines with %TU / %NU get the pilot's first name, and only those
function TestStormT2Names:test_lines_with_the_player_name_get_the_first_name()
	local n = 0

	for _, row in ipairs(T.SCREENS) do
		if row.token ~= "" then
			n = n + 1

			local t = T.drive(T.pilot({ paid = 1 }), row.id)

			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %" .. row.token .. " parameter (the first name, not the full name)")
		end
	end

	lu.assertEquals(n, 7, "screens with a name token in Appendix A")
end

-- AC-7: the token screens of Appendix A really are the client lines that carry a token
function TestStormT2Names:test_the_name_token_screens_are_exactly_the_client_lines_with_a_token()
	local fromText, fromRows = {}, {}

	for _, row in ipairs(T.SCREENS) do
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
