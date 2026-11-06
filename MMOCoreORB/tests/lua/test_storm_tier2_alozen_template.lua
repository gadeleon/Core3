-- Field Commander Alozen: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FA-1, D-3, D-12).
--
-- Answer keys: storm_tier2_alozen_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_imperial_trainer_2b.java (harness/swgjava.lua) for every link that is not a rejoin, a pre-NGE-only line or a
-- handler-built link, and the generated client id list fixtures/string/en/conversation/tatooine_imperial_trainer_2b.sids (124 ids).

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local CS = require("harness.client_strings")
local TEXT = require("storm_tier2_alozen_client_text")
local Swgjava = require("harness.swgjava")

A.load()

local PATHS = { A.TEMPLATE_FILE, A.HANDLER_FILE }
local PREFIX = A.PREFIX

-- the topics come in through C-4 (the template may hold them or not), so only the displayed options of training_menu are pinned
local BUILT_MENUS = { training_menu = true }

local function template() return H.conversationTemplateTable(A.TEMPLATE) end

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

TestAlozenOracle = {}

function TestAlozenOracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 71 screens, ids unique, and uses all 122 client lines and no other id
function TestAlozenOracle:test_appendix_a_has_71_screens_and_uses_every_client_line()
	lu.assertEquals(#A.SCREENS, 71, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(A.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	for _, t in ipairs(A.TRAIN) do
		used[t.reply] = true
	end

	local ids = CS.sids(A.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. A.STF .. ".sids")

	local missing, extra, distinct = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		distinct = distinct + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(distinct, 122, "distinct ids Appendix A uses")
end

-- AC-5 (the oracle itself): the TRAIN table's trained screens are Appendix A rows and the topic replies appear nowhere else
function TestAlozenOracle:test_the_train_table_matches_appendix_a()
	lu.assertEquals(A.screenRow("training_menu").options, { { A.LATER, "training_later" } }, "training_menu static options (the topics come in through C-4)")

	for _, t in ipairs(A.TRAIN) do
		local row = A.screenRow(t.trained)

		lu.assertEquals(row.sid, t.trainedSid, t.trained .. ": dialog")
		lu.assertEquals(row.options, { { A.TRAINED_REPLY, "trained_report" } }, t.trained .. ": its one reply")

		for _, r in ipairs(A.SCREENS) do
			for _, o in ipairs(r.options) do
				lu.assertNotEquals(o[1], t.reply, "topic reply " .. t.reply .. " must not be a static option of '" .. r.id .. "'")
			end
		end
	end
end

-- AC-5 (the oracle itself): the generated client id list holds the 124 entries the spec names
function TestAlozenOracle:test_the_client_id_fixture_holds_124_ids()
	local n = 0

	for _ in pairs(CS.sids(A.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 124, "ids in fixtures/string/en/" .. A.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only and rejoined lines (Data mapping 3), so a wrong sid fails with the words
function TestAlozenOracle:test_the_pre_nge_and_rejoin_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_21772e5a, "I'm sorry, I can't help you.", "not-pilot gate")
	lu.assertEquals(TEXT.s_8efde2ae, "Yes, sir.", "yes sir")
	lu.assertEquals(TEXT.s_b6b25f13, "Yes, sir!", "yes sir!")
	lu.assertEquals(TEXT.s_7a761694, "(Continue to listen.)", "continue to listen")
	lu.assertEquals(TEXT.s_5a7ec1e4, "What kind of operations can I help with?", "duty menu reply")
	lu.assertEquals(TEXT.s_b0d3b474, "I'm ready for training.", "training reply")
	lu.assertEquals(TEXT.s_ae26c22, "Let me think about this for a bit.", "think about it")
	lu.assertEquals(TEXT.s_2eaae5bc, "Commander Oberhaur told me to contact you.", "the Oberhaur reply")
	lu.assertEquals(TEXT.s_a73dd488, "I'm sorry, I'll leave you alone.", "leave alone")
	lu.assertEquals(TEXT.s_594a07fa, "I want to study advanced TIE combat operations.", "starships topic")
	lu.assertEquals(TEXT.s_dbb5bf46, "I want to study advanced weapons technology.", "weapons topic")
	lu.assertEquals(TEXT.s_e73e5d21, "I want to study pilot combat training.", "procedures topic")
	lu.assertEquals(TEXT.s_c76594d7, "I want to study advanced reactor engineering algorithms.", "droid topic")
	lu.assertEquals(TEXT.s_9c0c10ef, "Report back to me when you are ready for a new assignment.", "trained report")
	lu.assertStrContains(TEXT.s_2172d08a, "What area would you like to train in?")

	for _, id in ipairs({ "s_486da900", "s_8bd72bb5", "s_c4880407", "s_31804e15" }) do
		lu.assertStrContains(TEXT[id], "Use these study programs and destroy them when you have internalized the information.")
	end
end

TestAlozenTemplate = {}

function TestAlozenTemplate:setUp()
	H.reset()
	A.requireConversation(lu)
end

-- AC-5, I-8
function TestAlozenTemplate:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, A.screenIds(), A.TEMPLATE .. ": screen ids (71, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestAlozenTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(A.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, A.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-3)")
	end
end

-- AC-5, I-8: the static options in order (the training menu is built at run time; its template options are not pinned)
function TestAlozenTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(A.SCREENS) do
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

-- AC-5, I-8
function TestAlozenTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(A.TEMPLATE), {}, A.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestAlozenTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, A.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestAlozenTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(A.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_imperial_trainer_2b:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_imperial_trainer_2b", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 71, "leftDialog lines with a comment")
end

-- Content contract 3: the template and handler files exist at the contract paths
function TestAlozenTemplate:test_the_template_and_handler_files_exist_at_the_contract_paths()
	lu.assertTrue(exists(A.TEMPLATE_FILE), A.TEMPLATE_FILE)
	lu.assertTrue(exists(A.HANDLER_FILE), A.HANDLER_FILE)
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestAlozenClientStrings = {}

function TestAlozenClientStrings:setUp()
	H.reset()
	A.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks, in particular no NGE editor number
function TestAlozenClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5: no s_<decimal> id (the NGE editor numbers have one to three digits) in either file
function TestAlozenClientStrings:test_neither_source_uses_a_decimal_nge_editor_number()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		for n in source:gmatch('@conversation/tatooine_imperial_trainer_2b:s_(%d%d?%d?)"') do
			lu.fail(path .. " uses the NGE editor id s_" .. n .. " that the pre-NGE client lacks")
		end
	end
end

-- AC-5, I-8: the port uses all 122 client lines and no other id
function TestAlozenClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(A.STF)
	local used, n = {}, 0

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == A.STF then
			used[lit.id] = true
		end
	end

	local missing = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for _ in pairs(used) do
		n = n + 1
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of tatooine_imperial_trainer_2b the template and handler never show")
	lu.assertEquals(n, 122, "distinct ids used")
end

-- AC-5: complete literals, no stored prefix, no built id
function TestAlozenClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Alozen sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals
function TestAlozenClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(A.HANDLER_FILE)

	for _, t in ipairs(A.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "alozenConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "alozenConvoHandler.lua: no stringFile prefix local")
end

-- Data mapping 3: the training menu shows the pre-NGE menu line and each trained screen its topic description, all four close with the report line
function TestAlozenClientStrings:test_the_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. "s_2172d08a", "training_menu shows the menu line")

	for _, t in ipairs(A.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows the topic description")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][1], PREFIX .. A.TRAINED_REPLY, t.trained .. ": the one reply")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][2], "trained_report", t.trained .. ": leads to trained_report")
	end

	lu.assertEquals(byId.trained_report.leftDialog, PREFIX .. "s_9c0c10ef", "trained_report")
end

-- D-12: the duplicate-text slots are separate screens with J2b's shapes
function TestAlozenClientStrings:test_the_two_screens_that_share_s_95549379_have_their_own_shapes()
	local byId = screensById()

	lu.assertEquals(byId.duty_block.leftDialog, PREFIX .. "s_95549379", "duty_block line")
	lu.assertEquals(byId.m2_buy_time.leftDialog, PREFIX .. "s_95549379", "m2_buy_time line")
	lu.assertEquals(#byId.duty_block.options, 1, "duty_block has one reply")
	lu.assertEquals(#byId.m2_buy_time.options, 2, "m2_buy_time has two replies (the relic briefing and the duty menu)")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8, D-3)
---------------------------------------------------------------------------------------------

TestAlozenJavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_imperial_trainer_2b.java")

-- The replies of Appendix A the java does not have, or leads elsewhere: Data mapping 3 (screen, reply, link, the NGE ids behind it)
local NOT_IN_JAVA = {
	{ "m2_processing", "s_57c8489e", "m2_buy_time" },   -- java leads to the NGE s_52 line; the twin is s_95549379 (class a)
	{ "m2_buy_time", "s_3cbda2cf", "relic_core" },      -- s_52's first option on the twin line (class a)
	{ "m2_only_pilot", "s_b6b25f13", "m2_my_way" },     -- s_102 (class a)
	{ "m1_region", "s_fe624ae0", "m2_start" },          -- java leads to the NGE s_116 line; the twin is s_bf7cf7b8 (class a)
	{ "m1_supervision", "s_b6b25f13", "m1_respect" },   -- s_130 (class a)
	{ "m1_respect", "s_8efde2ae", "m1_situation" },     -- s_133 (class b)
	{ "m1_bravo_zeta", "s_7a761694", "m1_search_teams" }, -- s_146 (class b)
}

-- The screens that have no NPC line in the java: the pre-NGE lines in the NGE training slots (Data mapping 3, class P)
local NOT_IN_JAVA_SCREENS = { trained_starships = true, trained_weapons = true, trained_procedures = true, trained_droid = true, trained_report = true }

TestAlozenJavaGraph.setUp = TestAlozenTemplate.setUp

-- AC-5 (the oracle itself)
function TestAlozenOracle:test_the_answer_key_parses_77_npc_lines()
	lu.assertEquals(#GRAPH.order, 77, "NPC lines parsed from tatooine_imperial_trainer_2b.java")
end

-- AC-5, I-8: every screen that exists in the java ends exactly where the java ends, and every original reply leads where the java leads
function TestAlozenJavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf, skip = {}, {}

	for _, row in ipairs(A.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	for _, d in ipairs(NOT_IN_JAVA) do
		skip[d[1] .. "|" .. d[2] .. "|" .. d[3]] = true
	end

	local checked = 0

	for _, row in ipairs(A.SCREENS) do
		if not NOT_IN_JAVA_SCREENS[row.id] then
			local node = GRAPH.nodes[row.sid]

			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd and true or false, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

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

	lu.assertEquals(checked, 46, "original replies checked against the java (53 static replies less the 7 rejoined)")
end

-- AC-5: the deviation list is exact: each listed reply really is a row of Appendix A and absent from the java (or leads elsewhere there)
function TestAlozenJavaGraph:test_the_listed_rejoins_are_appendix_a_rows_the_java_does_not_have()
	for _, d in ipairs(NOT_IN_JAVA) do
		local row = A.screenRow(d[1])

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
					for _, target in ipairs(A.SCREENS) do
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
-- The %NU lines
---------------------------------------------------------------------------------------------

TestAlozenNames = {}

TestAlozenNames.setUp = TestAlozenTemplate.setUp

-- AC-5 (Content contract 3): lines with %NU get the pilot's first name, and only those
function TestAlozenNames:test_lines_with_the_player_name_get_the_first_name()
	local n = 0

	for _, row in ipairs(A.SCREENS) do
		if row.token ~= "" then
			n = n + 1

			local t = A.drive(A.pilot({ m = 1 }), row.id)

			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %" .. row.token .. " parameter (the first name, not the full name)")
		end
	end

	lu.assertEquals(n, 2, "screens with a name token in Appendix A (m3_offer, m2_won)")
end

-- AC-5: the token screens of Appendix A really are the client lines that carry a token
function TestAlozenNames:test_the_name_token_screens_are_exactly_the_client_lines_with_a_token()
	local fromText, fromRows = {}, {}

	for _, row in ipairs(A.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			fromText[row.id] = true
		end

		if row.token ~= "" then
			fromRows[row.id] = true
		end
	end

	lu.assertEquals(fromRows, fromText, "Appendix A token screens vs client lines with %TU/%NU")
end

return nil
