-- Prisk Kith'Vys: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FP-1, FP-2).
--
-- Answer keys: black_epsilon_tier2_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/corellia_imperial_trainer_2.java (harness/swgjava.lua) for every link that is not a twin, rejoin or pre-NGE-only
-- line, and the generated client id list fixtures/string/en/conversation/corellia_imperial_trainer_2.sids.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local CS = require("harness.client_strings")
local TEXT = require("black_epsilon_tier2_client_text")
local Swgjava = require("harness.swgjava")

P.load()

local PATHS = { P.TEMPLATE_FILE, P.HANDLER_FILE }
local PREFIX = P.PREFIX

local function template() return H.conversationTemplateTable(P.TEMPLATE) end

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

TestBlackEpsilonT2Oracle = {}

function TestBlackEpsilonT2Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 85 screens, ids unique, and with the four topic replies it uses all 140 client lines
function TestBlackEpsilonT2Oracle:test_appendix_a_has_85_screens_and_uses_every_client_line()
	lu.assertEquals(#P.SCREENS, 85, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(P.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	for _, t in ipairs(P.TRAIN) do
		used[t.reply] = true
	end

	local ids = CS.sids(P.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. P.STF .. ".sids")

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

-- AC-5 (the oracle itself): the generated client id list holds the 142 lines the spec names
function TestBlackEpsilonT2Oracle:test_the_client_id_fixture_holds_142_ids()
	local ids = CS.sids(P.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 142, "ids in fixtures/string/en/" .. P.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FP-1, FP-2, Data mapping 3), so a wrong sid fails with the words
function TestBlackEpsilonT2Oracle:test_the_pre_nge_only_lines_are_the_words_of_the_client()
	lu.assertNotNil(TEXT.s_584a90f8:find("What are you interested in learning%?"), "training menu asks what the pilot wants to learn")
	lu.assertEquals(TEXT.s_116d8b3b, "What sort of task.", "after-training reply (starships, procedures)")
	lu.assertEquals(TEXT.s_ceafaf0b, "Do you have a task for me?", "after-training reply (weapons)")
	lu.assertEquals(TEXT.s_b51a649, "Do I get to baby-sit another freighter?", "after-training reply (droid)")
	lu.assertEquals(TEXT.s_2c4789b, "Understood.", "M12 and M15 acknowledgement")
	lu.assertEquals(TEXT.s_1ff4247a, "I will not fail.", "M14 acknowledgement")
	lu.assertEquals(TEXT.s_d335136f, "Yes I am.", "opening_done reply")
end

-- AC-5 (the oracle itself): the %TU lines (D: setDialogTextTU)
function TestBlackEpsilonT2Oracle:test_the_wanted_lines_carry_the_player_name_token()
	lu.assertNotNil(TEXT.s_f7df921b:find("%TU", 1, true), "s_f7df921b has %TU")
	lu.assertNotNil(TEXT.s_9d62faa2:find("%TU", 1, true), "s_9d62faa2 has %TU")
end

TestBlackEpsilonT2Template = {}

function TestBlackEpsilonT2Template:setUp()
	H.reset()
	P.requireConversation(lu)
end

-- AC-5, I-8
function TestBlackEpsilonT2Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, P.screenIds(), P.TEMPLATE .. ": screen ids (85, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestBlackEpsilonT2Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(P.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, P.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-10)")
	end
end

-- AC-5, I-8: the static options in order (training_menu is built at run time and has none in the template)
function TestBlackEpsilonT2Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(P.SCREENS) do
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
function TestBlackEpsilonT2Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(P.TEMPLATE), {}, P.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestBlackEpsilonT2Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, P.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestBlackEpsilonT2Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(P.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/corellia_imperial_trainer_2:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/corellia_imperial_trainer_2", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 85, "leftDialog lines with a comment")
end

-- Content contract 3: option ids are complete literals, one per static link
function TestBlackEpsilonT2Template:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(P.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/corellia_imperial_trainer_2:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(P.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/corellia_imperial_trainer_2:s_... literals in the template (one per leftDialog and static option)")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2ClientStrings = {}

function TestBlackEpsilonT2ClientStrings:setUp()
	H.reset()
	P.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestBlackEpsilonT2ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: the port uses all 140 client lines and no other id
function TestBlackEpsilonT2ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(P.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == P.STF then
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
	lu.assertEquals(missing, {}, "client lines of corellia_imperial_trainer_2 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 140, "distinct ids used")
end

-- AC-5: the handler uses complete literals
function TestBlackEpsilonT2ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Prisk sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the handler names the four topic replies as complete literals (Content contract 3)
function TestBlackEpsilonT2ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(P.HANDLER_FILE)

	for _, t in ipairs(P.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "priskConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "priskConvoHandler.lua: no stringFile prefix local")
end

-- AC-5, FP-1: the training menu and the after-training lines show the pre-NGE client lines
function TestBlackEpsilonT2ClientStrings:test_the_training_menu_and_after_training_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. "s_584a90f8", "training_menu shows the menu line")

	for _, t in ipairs(P.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows its after-training line")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][1], PREFIX .. t.afterReply, t.trained .. ": the one player reply")
		lu.assertEquals(byId[t.trained].options[1] and byId[t.trained].options[1][2], t.brief, t.trained .. ": leads to the skill's briefing")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_trainer_2.java")

function TestBlackEpsilonT2JavaGraph:setUp()
	H.reset()
	P.requireConversation(lu)
end

-- AC-5, I-8: every untagged screen ends exactly where the java ends, and every original reply leads where the java leads
function TestBlackEpsilonT2JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(P.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked = 0

	for _, row in ipairs(P.SCREENS) do
		if row.tag == "" then
			local node = GRAPH.nodes[row.sid]

			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

			local have = {}

			for _, o in ipairs(node.options) do
				have[o] = true
			end

			for _, o in ipairs(row.options) do
				if o[3] == "" then
					checked = checked + 1
					lu.assertTrue(have[o[1]] == true, "screen '" .. row.id .. "': the java line " .. row.sid .. " has no reply " .. o[1])

					local ok = false

					for _, succ in ipairs(GRAPH.successorsOf(row.sid, o[1]) or {}) do
						if succ == dialogOf[o[2]] then
							ok = true
						end
					end

					lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. o[1] .. ": the java leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
				end
			end
		end
	end

	lu.assertEquals(checked, 63, "original (non-twin, non-rejoin, non-pre-NGE, non-conditional) replies checked against the java")
end

---------------------------------------------------------------------------------------------
-- The %TU lines
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Names = {}

function TestBlackEpsilonT2Names:setUp()
	H.reset()
	P.requireConversation(lu)
end

-- AC-5 (Content contract 3): lines with %TU get the pilot's first name
function TestBlackEpsilonT2Names:test_the_wanted_lines_get_the_first_name()
	for _, id in ipairs({ "wanted_male", "wanted_female" }) do
		local t = P.drive(P.pilot({ standing = -1 }), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the %TU parameter")
	end
end
