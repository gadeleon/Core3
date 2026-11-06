-- Lt. Akal Colzet: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FI-2, FI-3; D-2, D-3, D-4).
--
-- Answer keys: storm_tier1_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_imperial_trainer_1.java (harness/swgjava.lua) for every link that is not a twin, rejoin or pre-NGE-only
-- line, and the generated client id list fixtures/string/en/conversation/tatooine_imperial_trainer_1.sids.

local lu = require("luaunit")
local H = require("harness")
local I = require("storm_tier1_data")
local CS = require("harness.client_strings")
local TEXT = require("storm_tier1_client_text")
local Swgjava = require("harness.swgjava")

I.load()

local PATHS = { I.TEMPLATE_FILE, I.HANDLER_FILE }
local PREFIX = I.PREFIX

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

TestStormT1Oracle = {}

function TestStormT1Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 199 screens, ids unique, and with the training menu replies it uses all 345 client lines
function TestStormT1Oracle:test_appendix_a_has_199_screens_and_uses_every_client_line()
	lu.assertEquals(#I.SCREENS, 199, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(I.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	for _, t in ipairs(I.TRAIN) do
		used[t.reply] = true
	end

	used[I.NEVER_MIND] = true

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

-- AC-5 (the oracle itself): the generated client id list holds the 347 entries the spec names (345 lines plus do_not_edit and s_0)
function TestStormT1Oracle:test_the_client_id_fixture_holds_347_ids()
	local ids = CS.sids(I.STF)
	local n = 0

	for _ in pairs(ids) do
		n = n + 1
	end

	lu.assertEquals(n, 347, "ids in fixtures/string/en/" .. I.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FI-2, FI-3), so a wrong sid fails with the words
function TestStormT1Oracle:test_the_pre_nge_only_lines_are_the_words_of_the_client()
	lu.assertStrContains(TEXT.s_2844cc74, "Pilot, you are a disgrace.")
	lu.assertStrContains(TEXT.s_2844cc74, "You are grounded until further notice!")
	lu.assertEquals(TEXT.s_7090182, "What?!", "grounded reply 1")
	lu.assertStrContains(TEXT.s_49af5773, "you'd better improve your standing with the Empire!")
	lu.assertEquals(TEXT.s_fcf4d778, "How?", "grounded reply 2")
	lu.assertStrContains(TEXT.s_eb1ee299, "You brought this on yourself.")
	lu.assertEquals(TEXT.s_bb6caa54, "You can learn about Imperial technology, weapons, standard Imperial training, or astromech management.", "training menu")
	lu.assertEquals(TEXT.s_5e3cf461, "I'm interested in Imperial technology.", "technology topic")
	lu.assertEquals(TEXT.s_577aca95, "I'm interested in weapons.", "weapons topic")
	lu.assertEquals(TEXT.s_40f3848e, "I'm interested in space combat training.", "combat training topic")
	lu.assertEquals(TEXT.s_a57e647c, "I'm interested in astromech management.", "astromech topic")
	lu.assertEquals(TEXT.s_cdbce743, "I want to enlist in the ground forces.", "ground forces reply")
	lu.assertEquals(TEXT.s_d825aeb0, "Very well, good day Pilot.", "never mind answer")
	lu.assertEquals(TEXT.s_c6d9f61, "I'd like to study that in detail.", "confirm")
	lu.assertEquals(TEXT.s_786f3cf7, "I want to study something else.", "back")
	lu.assertEquals(TEXT.s_7c8aca1b, "Good choice.  Report back when you are ready for an assignment.", "closing")
end

-- AC-5 (the oracle itself): no client line carries a %-token, so no screen needs setDialogText* parameters
function TestStormT1Oracle:test_no_client_line_carries_a_token()
	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" then
			lu.assertNil(text:find("%%[A-Z][A-Z]"), id .. ": carries a % token")
		end
	end
end

TestStormT1Template = {}

function TestStormT1Template:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5, I-8
function TestStormT1Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, I.screenIds(), I.TEMPLATE .. ": screen ids (199, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestStormT1Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, I.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-12)")
	end
end

-- AC-5, I-8: the static options in order (training_menu is built at run time and has none in the template)
function TestStormT1Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
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
function TestStormT1Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(I.TEMPLATE), {}, I.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestStormT1Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, I.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestStormT1Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(I.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_imperial_trainer_1:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_imperial_trainer_1", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 199, "leftDialog lines with a comment")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, FI-2)
---------------------------------------------------------------------------------------------

TestStormT1ClientStrings = {}

function TestStormT1ClientStrings:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks
function TestStormT1ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, FI-2: the port uses all 345 client lines and no other id
function TestStormT1ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
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
	lu.assertEquals(missing, {}, "client lines of tatooine_imperial_trainer_1 the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 345, "distinct ids used")
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestStormT1ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Colzet sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestStormT1ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(I.HANDLER_FILE)

	for _, t in ipairs(I.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "akalColzetConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. I.NEVER_MIND .. '"', 1, true), "akalColzetConvoHandler.lua: complete literal for 'Never mind' " .. I.NEVER_MIND)
	lu.assertNil(source:find("local%s+stringFile%s*="), "akalColzetConvoHandler.lua: no stringFile prefix local")
end

-- AC-5: the training menu and its closing line show the pre-NGE client lines
function TestStormT1ClientStrings:test_the_training_menu_and_closing_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_menu.leftDialog, PREFIX .. I.MENU_LINE, "training_menu shows the menu line")

	for _, t in ipairs(I.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. "s_7c8aca1b", t.trained .. " shows 'Good choice.'")
		lu.assertEquals(byId[t.desc].leftDialog, PREFIX .. t.descSid, t.desc .. " shows the topic description")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-8, D-2)
---------------------------------------------------------------------------------------------

TestStormT1JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_imperial_trainer_1.java")

function TestStormT1JavaGraph:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5 (the oracle itself)
function TestStormT1Oracle:test_the_answer_key_parses_212_npc_lines()
	lu.assertEquals(#GRAPH.order, 212, "NPC lines parsed from tatooine_imperial_trainer_1.java")
end

-- AC-5, I-8: every screen that exists in the java ends exactly where the java ends, and every original reply leads where the java leads
function TestStormT1JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(I.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, compared = 0, 0
	local CLIENT = CS.sids(I.STF)

	for _, row in ipairs(I.SCREENS) do
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

					local ok, anyClient = false, false

					for _, succ in ipairs(GRAPH.successorsOf(row.sid, o[1])) do
						if succ == dialogOf[o[2]] then
							ok = true
						end

						if CLIENT[succ] then
							anyClient = true
						end
					end

					-- a reply whose java successors are all NGE editor lines (s_<decimal>) leads to a rejoin (Data mapping 3, class b)
					if anyClient then
						compared = compared + 1
						lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. o[1] .. ": the java leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
					end
				end
			end
		end
	end

	lu.assertEquals(checked, 152, "original (non-twin, non-rejoin) replies the java has")
	lu.assertEquals(compared, 144, "of them, replies whose java successor is a client line and so compared with the screen link (the other 8 lead to rejoined NGE lines)")
end
