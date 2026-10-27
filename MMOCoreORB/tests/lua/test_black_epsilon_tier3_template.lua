-- Haymir Rendundi: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FH-1).
--
-- Answer keys: black_epsilon_tier3_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/corellia_imperial_tier3.java (harness/swgjava.lua) for every link of a row that is not a pre-NGE placement, and the
-- generated client id list fixtures/string/en/conversation/corellia_imperial_tier3.sids.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local CS = require("harness.client_strings")
local TEXT = require("black_epsilon_tier3_client_text")
local Swgjava = require("harness.swgjava")

T.load()

local PATHS = { T.TEMPLATE_FILE, T.HANDLER_FILE }
local PREFIX = T.PREFIX

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

TestBlackEpsilonT3Oracle = {}

function TestBlackEpsilonT3Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 74 screens, ids unique, and with the four topic replies it uses all 130 client lines
function TestBlackEpsilonT3Oracle:test_appendix_a_has_74_screens_and_uses_every_client_line()
	lu.assertEquals(#T.SCREENS, 74, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(T.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

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

-- AC-5 (the oracle itself): the generated client id list holds the 132 entries the spec names
function TestBlackEpsilonT3Oracle:test_the_client_id_fixture_holds_132_ids()
	local n = 0

	for _ in pairs(CS.sids(T.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 132, "ids in fixtures/string/en/" .. T.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the placed topic and answer lines (FH-1, Data mapping 3), so a wrong sid fails with the words
function TestBlackEpsilonT3Oracle:test_the_placed_pre_nge_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_adc23ed9, "How about advanced capability TIE vessels?", "starships topic")
	lu.assertEquals(TEXT.s_77f35957, "Know anything about advanced starship components?", "weapons topic")
	lu.assertEquals(TEXT.s_3f4fdcbd, "I'd like to learn about special forces training.", "procedures topic")
	lu.assertEquals(TEXT.s_2dd8b42, "System balance programming sounds cool.", "droid topic")
	lu.assertNotNil(TEXT.s_7fe8c9bb:find("how ABOUT those vessels", 1, true), "starships answer: 'how ABOUT those vessels' (answers the TIE vessels topic)")
	lu.assertNotNil(TEXT.s_84ce496b:find("I wrote the book", 1, true), "weapons answer: 'I wrote the book'")
	lu.assertNotNil(TEXT.s_9d2d47d4:find("intel", 1, true), "procedures answer gives the intel")
	lu.assertNotNil(TEXT.s_f00894a4:find("Your opinion matters", 1, true), "droid answer: 'Your opinion matters to me'")
end

-- AC-5 (the oracle itself): the %TU lines (setDialogTextTU)
function TestBlackEpsilonT3Oracle:test_the_offer_and_hand_off_lines_carry_the_player_name_token()
	for _, sid in ipairs({ "s_1c0f4063", "s_424f249d", "s_daaff7a" }) do
		lu.assertNotNil(TEXT[sid]:find("%TU", 1, true), sid .. " has %TU")
	end
end

TestBlackEpsilonT3Template = {}

function TestBlackEpsilonT3Template:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8
function TestBlackEpsilonT3Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, T.screenIds(), T.TEMPLATE .. ": screen ids (74, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestBlackEpsilonT3Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-8)")
	end
end

-- AC-5, I-8: the static options in order (the training screens are built at run time and have none in the template)
function TestBlackEpsilonT3Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
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
function TestBlackEpsilonT3Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestBlackEpsilonT3Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, T.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestBlackEpsilonT3Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(T.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/corellia_imperial_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/corellia_imperial_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 74, "leftDialog lines with a comment")
end

-- Content contract 3: option ids are complete literals, one per static link
function TestBlackEpsilonT3Template:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(T.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/corellia_imperial_tier3:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(T.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/corellia_imperial_tier3:s_... literals in the template (one per leftDialog and static option)")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3ClientStrings = {}

function TestBlackEpsilonT3ClientStrings:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestBlackEpsilonT3ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: the port uses all 130 client lines and no other id
function TestBlackEpsilonT3ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
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
	lu.assertEquals(missing, {}, "client lines of corellia_imperial_tier3 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 130, "distinct ids used")
end

-- AC-5: complete literals only
function TestBlackEpsilonT3ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Haymir sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the handler names the four topic replies as complete literals (Content contract 3)
function TestBlackEpsilonT3ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(T.HANDLER_FILE)

	for _, t in ipairs(T.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "haymirConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "haymirConvoHandler.lua: no stringFile prefix local")
end

-- AC-5, FH-1: the answer screens show the placed lines and end
function TestBlackEpsilonT3ClientStrings:test_the_trained_screens_show_the_four_answer_lines_and_end()
	local byId = screensById()

	for _, t in ipairs(T.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows its answer line")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends the conversation")
		lu.assertEquals(#byId[t.trained].options, 0, t.trained .. " has no reply")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_tier3.java")

function TestBlackEpsilonT3JavaGraph:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8: every untagged screen ends exactly where the java ends, and every reply leads where the java leads
function TestBlackEpsilonT3JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(T.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens = 0, 0

	for _, row in ipairs(T.SCREENS) do
		if row.tag == "" then
			local node = GRAPH.nodes[row.sid]

			screens = screens + 1
			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

			local have = {}

			for _, o in ipairs(node.options) do
				have[o] = true
			end

			for _, o in ipairs(row.options) do
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

	lu.assertEquals(screens, 65, "untagged Appendix A screens checked against the java")
	lu.assertEquals(checked, 53, "original (non-placed) replies checked against the java")
end

---------------------------------------------------------------------------------------------
-- The %TU lines
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Names = {}

function TestBlackEpsilonT3Names:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5 (Content contract 3): lines with %TU get the pilot's first name
function TestBlackEpsilonT3Names:test_the_offer_and_hand_off_lines_get_the_first_name()
	for _, id in ipairs({ "m1_offer", "m3_offer", "tour_complete" }) do
		local t = T.drive(T.pilot(), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the %TU parameter")
	end
end
