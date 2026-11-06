-- Captain Denner: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-2, invariant I-10; Content contract 2; Data mapping 2; FD-1, FD-2, D-2, D-4, D-14).
--
-- Answer keys: storm_tier3_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_imperial_tier3.java (harness/swgjava.lua) for every link that is not a rejoin, a pre-NGE-only line or a
-- handler-built link, and the generated client id list fixtures/string/en/conversation/tatooine_imperial_tier3.sids (281 ids, served from patch_12_00.tre).
--
-- TestStormT3Oracle checks the answer key against its own sources (Appendix A vs the .sids, the client text and the java graph); it needs no production
-- file and is green before the implementation. TestStormT3Template, ...ClientStrings and ...Names are red until Denner's template and handler exist.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local CS = require("harness.client_strings")
local TEXT = require("storm_tier3_client_text")
local Swgjava = require("harness.swgjava")

D.loadConversation()

local PATHS = { D.TEMPLATE_FILE, D.HANDLER_FILE }
local PREFIX = D.PREFIX

local function template() return H.conversationTemplateTable(D.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path)
	local f = io.open(H.SCRIPTS .. path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/tatooine_imperial_tier3.java")

-- NGE editor numbers have one to three digits (J3 goes up to s_331); client ids are CRC hex of up to eight digits, a few of them all digits
-- (s_24315068, s_52651592 are real client lines), so "no s_<decimal>" is tested on short numbers only
local function isNgeId(id) return id:match("^s_%d%d?%d?$") ~= nil end

-- The 28 NGE ids of Data mapping 2
local NGE = {
	"s_129", "s_138", "s_141", "s_151", "s_155", "s_157", "s_162", "s_164", "s_167", "s_169", "s_175", "s_180", "s_194", "s_210", "s_217", "s_220",
	"s_229", "s_232", "s_234", "s_243", "s_275", "s_299", "s_316", "s_327", "s_328", "s_329", "s_330", "s_331",
}

-- Data mapping 2: the J3 NPC lines (NGE ids) the port does not show
local NGE_NPC_LINES = { "s_129", "s_138", "s_141", "s_151", "s_157", "s_162", "s_217", "s_220", "s_229", "s_232", "s_243", "s_316", "s_328", "s_329", "s_330", "s_331" }

-- Data mapping 2: the screens whose J3 slot is an NGE line (the new screens D-14): screen -> the NGE line whose replies they carry
local JSLOT = { m1_offer_ego = "s_162", m2_offer_report = "s_217", m2_offer_leak = "s_243" }

-- Data mapping 2, class (a)/(b): the 10 replies whose NGE reply the port replaces by a client reply. "screen|reply" -> the NGE reply of the java
local REPLY_REJOINS = {
	["m1_offer_ego|s_e374b3bf"] = "s_164",
	["m1_offer_4ca34e11|s_dd4be05c"] = "s_180",
	["m1_offer_666d4e98|s_b16490f1"] = "s_167",
	["m1_offer_666d4e98|s_c118c966"] = "s_169",
	["m1_offer_b6b37d2c|s_b16490f1"] = "s_175",
	["m1_offer_8ace66c8|s_996c6fd3"] = "s_155",
	["m2_offer_f51fd3ee|s_bb9e4a63"] = "s_194",
	["m2_offer_4b2d23bc|s_5bd69df6"] = "s_210",
	["m3_offer_d8c02b03|s_a950fa1d"] = "s_275",
	["m4_offer_b196e01f|s_afdf6d6"] = "s_299",
}

TestStormT3Oracle = {}

function TestStormT3Oracle:setUp() H.reset() end

-- B-2 (the oracle itself): Appendix A has 146 screens, ids unique, and uses all 279 client lines and no other id
function TestStormT3Oracle:test_appendix_a_has_146_screens_and_uses_every_client_line()
	lu.assertEquals(#D.SCREENS, 146, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(D.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(D.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. D.STF .. ".sids")

	local missing, extra, n = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		n = n + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(n, 279, "distinct ids Appendix A uses")
end

-- B-2 (the oracle itself): every Appendix A link resolves to a screen
function TestStormT3Oracle:test_every_appendix_a_link_resolves()
	local ids = {}

	for _, row in ipairs(D.SCREENS) do
		ids[row.id] = true
	end

	for _, row in ipairs(D.SCREENS) do
		for _, o in ipairs(row.options) do
			lu.assertTrue(ids[o[2]] == true, row.id .. ": option " .. o[1] .. " links to the missing screen " .. o[2])
		end
	end
end

-- B-2 (the oracle itself): the generated client id list holds the 281 lines the spec names (279 lines + do_not_edit + s_0)
function TestStormT3Oracle:test_the_client_id_fixture_holds_281_ids()
	local n = 0

	for _ in pairs(CS.sids(D.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 281, "ids in fixtures/string/en/" .. D.STF .. ".sids")
end

-- B-2 (the oracle itself): the 28 NGE editor numbers are not client lines
function TestStormT3Oracle:test_the_28_nge_ids_are_not_client_lines()
	local ids = CS.sids(D.STF)

	lu.assertEquals(#NGE, 28, "NGE ids of Data mapping 2")

	for _, id in ipairs(NGE) do
		lu.assertNil(ids[id], "precondition: the client has no " .. id)
	end
end

-- B-2 (the oracle itself): the four training screens of each mission list all four topics in TRAIN order; the four trained screens are the P rows
function TestStormT3Oracle:test_the_train_table_matches_appendix_a()
	local n = 0

	for screen, mission in pairs(D.TRAINING_SCREENS) do
		n = n + 1

		local row = D.screenRow(screen)

		lu.assertNotNil(row, "Appendix A row " .. screen)
		lu.assertEquals(row.cond, "C-1", screen .. ": handler-built options")
		lu.assertTrue(row.id:match("^m" .. mission .. "_training_") ~= nil, screen .. " belongs to mission " .. mission)
		lu.assertEquals(#row.options, 4, screen .. ": four static options")

		for i, t in ipairs(D.TRAIN) do
			lu.assertEquals(row.options[i], { t.reply, t.trained }, screen .. " option " .. i)
		end
	end

	lu.assertEquals(n, 12, "training screens (three per mission)")

	for _, t in ipairs(D.TRAIN) do
		local row = D.screenRow(t.trained)

		lu.assertNotNil(row, "Appendix A row " .. t.trained)
		lu.assertEquals(row.sid, t.trainedSid, t.trained .. ": dialog")
		lu.assertTrue(row.stop, t.trained .. " ends the conversation")
		lu.assertEquals(row.tag, "P", t.trained .. " is a pre-NGE line in an NGE slot")
	end
end

-- B-2 (the oracle itself): the exact client text of the pre-NGE-only lines (FD-1, FD-2), so a wrong sid fails with the words
function TestStormT3Oracle:test_the_pre_nge_topic_and_grant_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_40cda759, "Teach me about advanced capability TIE vessels.", "starships topic")
	lu.assertEquals(TEXT.s_a9aeb386, "Teach me about advanced starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_ef7a2df5, "Teach me about special forces training.", "procedures topic")
	lu.assertEquals(TEXT.s_473d09d8, "Teach me about system balance programming.", "droid topic")
	lu.assertEquals(TEXT.s_3ec1a288, "Of course. we'll begin now. Report back to me as soon as possible. The Empire needs all hands on deck.", "droid grant (FD-2)")
	lu.assertEquals(TEXT.s_5f736ba3, "Very well. Let's begin. And later, report to me for your next mission.", "starships grant (FD-2)")
	lu.assertEquals(TEXT.s_645af1cb, "I'll train you now. Afterwards, report to me when you're ready for the next step.", "weapons grant (FD-2)")
	lu.assertEquals(TEXT.s_c4f3b92c, "Let's begin your training. When you're done, you'll be ready for a new mission.", "procedures grant (FD-2)")
end

-- B-2 (the oracle itself): the NGE-slot stand-ins of Data mapping 2 are the words of the client
function TestStormT3Oracle:test_the_rejoined_lines_are_the_words_of_the_client()
	lu.assertStrContains(TEXT.s_704da203, "Your time with me is over", false, "tour_complete (s_316)")
	lu.assertEquals(TEXT.s_996c6fd3, "What's Storm Squadron's assignment?", "s_155")
	lu.assertEquals(TEXT.s_e374b3bf, "I will remember that, sir.", "s_164")
	lu.assertEquals(TEXT.s_b16490f1, "Secret project? Sounds interesting.", "s_167 / s_175")
	lu.assertEquals(TEXT.s_c118c966, "I am honored to serve under the Emperor's Hand.", "s_169")
	lu.assertEquals(TEXT.s_dd4be05c, "What is my first assignment?", "s_180")
	lu.assertEquals(TEXT.s_bb9e4a63, "Understood, sir.", "s_194")
	lu.assertEquals(TEXT.s_5bd69df6, "What do you need me to do?", "s_210")
	lu.assertEquals(TEXT.s_39538c2a, "What did they find out?", "s_234")
	lu.assertEquals(TEXT.s_a950fa1d, "What is the plan, sir?", "s_275")
	lu.assertEquals(TEXT.s_afdf6d6, "What is it you want me to do, sir?", "s_299")
	lu.assertStrContains(TEXT.s_5e3cc3ae, "slight ego", false, "m1_offer_ego (s_162)")
	lu.assertStrContains(TEXT.s_2800345f, "decrypting the data", false, "m2_offer_report / m2_intel (s_217, s_232)")
	lu.assertStrContains(TEXT.s_abcfd5a5, "leaked it to them", false, "m2_offer_leak (s_243)")
end

-- B-2 (the oracle itself): the answer key parses 155 NPC lines; the 16 the port does not show are exactly the NGE-numbered NPC lines of Data mapping 2
function TestStormT3Oracle:test_the_java_lines_not_shown_are_exactly_the_16_nge_numbered_npc_lines()
	lu.assertEquals(#GRAPH.order, 155, "NPC lines parsed from tatooine_imperial_tier3.java")

	local used = {}

	for _, row in ipairs(D.SCREENS) do
		used[row.sid] = true
	end

	local unused = {}

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then
			unused[#unused + 1] = sid
		end
	end

	local want = { table.unpack(NGE_NPC_LINES) }

	table.sort(unused)
	table.sort(want)
	lu.assertEquals(unused, want, "J3 NPC lines Appendix A does not show")
end

-- B-2, I-10 (the oracle itself): every end flag and every original reply of Appendix A agrees with the SWG script. Replies replaced by Data mapping 2
-- are the only differences, and the checker counts them: 10 replaces of an NGE reply, 11 links whose java answer is an NGE line.
function TestStormT3Oracle:test_every_original_reply_and_end_flag_agrees_with_the_swg_script_but_for_the_listed_rejoins()
	local dialogOf = {}

	for _, row in ipairs(D.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local replaced, nge, checked = 0, 0, 0

	for _, row in ipairs(D.SCREENS) do
		if row.tag ~= "P" then
			local slot = JSLOT[row.id] or row.sid
			local node = GRAPH.nodes[slot]

			lu.assertNotNil(node, "java has no NPC line " .. slot .. " (screen '" .. row.id .. "')")
			lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. slot .. "): ends the conversation iff the java does")

			if row.cond ~= "C-1" then
				lu.assertEquals(#row.options, #node.options, "screen '" .. row.id .. "': reply count equals the java line's")

				local have = {}

				for _, o in ipairs(node.options) do
					have[o] = true
				end

				for _, o in ipairs(row.options) do
					local javaReply = o[1]
					local key = row.id .. "|" .. o[1]

					if REPLY_REJOINS[key] then
						javaReply = REPLY_REJOINS[key]
						replaced = replaced + 1
						lu.assertTrue(have[javaReply] == true, "screen '" .. row.id .. "': the java line " .. slot .. " has no NGE reply " .. javaReply)
						lu.assertNil(CS.sids(D.STF)[javaReply], javaReply .. " is an NGE editor number")
					else
						lu.assertTrue(have[javaReply] == true, "screen '" .. row.id .. "': the java line " .. slot .. " has no reply " .. javaReply)
					end

					local ok, javaNge = false, false

					for _, succ in ipairs(GRAPH.successorsOf(slot, javaReply) or {}) do
						ok = ok or succ == dialogOf[o[2]]
						javaNge = javaNge or isNgeId(succ)
					end

					if ok then
						checked = checked + 1
					else
						lu.assertTrue(javaNge, "screen '" .. row.id .. "', reply " .. o[1] .. ": the java leads elsewhere than '" .. o[2] .. "' (" .. tostring(dialogOf[o[2]]) .. ")")
						nge = nge + 1
					end
				end
			end
		end
	end

	lu.assertEquals(replaced, 10, "replies replaced by a client reply (Data mapping 2)")
	lu.assertEquals(nge, 11, "links whose java answer is a replaced NGE line (Data mapping 2)")
	lu.assertTrue(checked > 100, "original links checked against the java: " .. checked)
end

TestStormT3Template = {}

function TestStormT3Template:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- B-2, I-10
function TestStormT3Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, D.screenIds(), D.TEMPLATE .. ": screen ids (146, no duplicates)")
end

-- B-2, I-10: dialog, end flag, animation per screen
function TestStormT3Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, D.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, J3's)")
	end
end

-- B-2, I-10: the static options in order (on the C-1 screens the full four-topic list is the static list)
function TestStormT3Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
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

-- B-2
function TestStormT3Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {}, D.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestStormT3Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, D.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the first line names Captain Denner, tier 3, J3, the pre-NGE client lines, the feature and the handler
function TestStormT3Template:test_the_first_line_is_the_header_comment()
	local source = readFile(D.TEMPLATE_FILE)

	lu.assertNotNil(source, D.TEMPLATE_FILE)

	local first = source:match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "the first line is a comment")

	for _, word in ipairs({ "Denner", "tier 3", "tatooine_imperial_tier3", "storm-tier3-denner", "dennerConvoHandler" }) do
		lu.assertStrContains(first, word, false, "header comment names '" .. word .. "'")
	end
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestStormT3Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(D.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_imperial_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("^%s+", ""):gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_imperial_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 146, "leftDialog lines with a comment")
end

-- Content contract 2: each screen is a global denner_convo_<id> added with denner_convo_template:addScreen
function TestStormT3Template:test_every_screen_is_a_global_denner_convo_id_added_to_the_template()
	local source = readFile(D.TEMPLATE_FILE)

	for _, row in ipairs(D.SCREENS) do
		lu.assertNotNil(source:find("denner_convo_" .. row.id .. " = ConvoScreen:new", 1, true), "denner_convo_" .. row.id .. " is defined")
		lu.assertNotNil(source:find("denner_convo_template:addScreen(denner_convo_" .. row.id .. ")", 1, true), "denner_convo_" .. row.id .. " is added to the template")
	end

	lu.assertNotNil(source:find('addConversationTemplate("denner_convo_template", denner_convo_template)', 1, true), "the template is registered")
end

---------------------------------------------------------------------------------------------
-- Client strings (B-2, I-10)
---------------------------------------------------------------------------------------------

TestStormT3ClientStrings = {}

function TestStormT3ClientStrings:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- B-2: no id the pre-NGE client lacks, in particular no NGE editor number
function TestStormT3ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- B-2, I-10: no NGE editor number appears in either file
function TestStormT3ClientStrings:test_neither_source_uses_an_nge_editor_number()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		lu.assertNotNil(source, path)

		for id in source:gmatch('@conversation/tatooine_imperial_tier3:(s_%d+)"') do
			lu.assertFalse(isNgeId(id), path .. " uses the NGE editor id " .. id .. " that the pre-NGE client lacks")
		end
	end
end

-- B-2, I-10: the ids the two files use equal the 279 client lines
function TestStormT3ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(D.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == D.STF then
			used[lit.id] = true
		end
	end

	local missing, extra, n = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		n = n + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines of tatooine_imperial_tier3 the template and handler never show")
	lu.assertEquals(extra, {}, "ids the template and handler use that the client does not have")
	lu.assertEquals(n, 279, "distinct ids used")
end

-- B-2: complete literals only (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestStormT3ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Denner's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- Content contract 2: TRAIN_CHOICES holds complete literals
function TestStormT3ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(D.HANDLER_FILE)

	lu.assertNotNil(source, D.HANDLER_FILE)

	for _, t in ipairs(D.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "dennerConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "dennerConvoHandler.lua: no stringFile prefix local")
end

-- FD-2: the four trained screens show their own pre-NGE grant lines and end
function TestStormT3ClientStrings:test_the_four_trained_screens_show_the_pre_nge_grant_lines()
	local byId = screensById()

	for _, t in ipairs(D.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. ": leftDialog")
		lu.assertEquals(#byId[t.trained].options, 0, t.trained .. ": no reply")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends the conversation")
	end
end

-- Data mapping 2: the three new-text screens and the shared sids (D-14) have their own shapes
function TestStormT3ClientStrings:test_the_screens_that_share_a_line_have_their_own_replies()
	local byId = screensById()

	lu.assertEquals(byId.m1_offer_ego.leftDialog, byId.m1_offer_5e3cc3ae.leftDialog, "m1_offer_ego and m1_offer_5e3cc3ae share s_5e3cc3ae")
	lu.assertEquals(byId.m2_offer_report.leftDialog, byId.m2_intel.leftDialog, "m2_offer_report and m2_intel share s_2800345f")
	lu.assertEquals(byId.m2_offer_leak.leftDialog, byId.m2_offer_abcfd5a5.leftDialog, "m2_offer_leak and m2_offer_abcfd5a5 share s_abcfd5a5")
	lu.assertNotEquals(byId.m1_offer_ego.options[1][2], byId.m1_offer_5e3cc3ae.options[1][2], "the ego line leads elsewhere than its twin")
	lu.assertEquals(byId.m2_offer_report.options[2][2], "m2_offer_9a5c94ec", "the report line rejoins 'You did very well in capturing that Rebel scout'")
end

---------------------------------------------------------------------------------------------
-- The template against the SWG java graph, for the screens the template defines (I-10)
---------------------------------------------------------------------------------------------

TestStormT3JavaGraph = {}

TestStormT3JavaGraph.setUp = TestStormT3Template.setUp

-- B-2, I-10: every link the template holds that is not a rejoin, a pre-NGE line or a C-1 list leads where the java leads
function TestStormT3JavaGraph:test_every_template_link_agrees_with_the_swg_script_but_for_the_listed_rejoins()
	local byId = screensById()
	local dialogOf = {}

	for id, s in pairs(byId) do
		dialogOf[id] = (s.leftDialog:gsub("^.*:", ""))
	end

	local checked = 0

	for _, row in ipairs(D.SCREENS) do
		if row.tag ~= "P" then
			local slot = JSLOT[row.id] or (byId[row.id].leftDialog:gsub("^.*:", ""))
			local node = GRAPH.nodes[slot]

			lu.assertNotNil(node, "java has no NPC line " .. slot .. " (template screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "template screen '" .. row.id .. "': ends iff the java line does")

			if row.cond ~= "C-1" then
				for _, o in ipairs(byId[row.id].options) do
					local reply = (o[1]:gsub("^.*:", ""))
					local javaReply = REPLY_REJOINS[row.id .. "|" .. reply] or reply
					local ok, javaNge = false, false

					for _, succ in ipairs(GRAPH.successorsOf(slot, javaReply) or {}) do
						ok = ok or succ == dialogOf[o[2]]
						javaNge = javaNge or isNgeId(succ)
					end

					lu.assertTrue(ok or javaNge, "template screen '" .. row.id .. "', reply " .. reply .. ": the java leads elsewhere than '" .. o[2] .. "'")
					checked = checked + 1
				end
			end
		end
	end

	lu.assertTrue(checked > 100, "template links checked against the java: " .. checked)
end

---------------------------------------------------------------------------------------------
-- The %TU / %NU lines
---------------------------------------------------------------------------------------------

TestStormT3Names = {}

TestStormT3Names.setUp = TestStormT3Template.setUp

-- B-2 (Content contract 2): lines with %TU / %NU get the pilot's first name, and only those
function TestStormT3Names:test_lines_with_the_player_name_get_the_first_name()
	local n = 0

	for _, row in ipairs(D.SCREENS) do
		if row.token ~= "" then
			n = n + 1

			local t = D.drive(D.pilot({}), row.id)

			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %" .. row.token .. " parameter")
		end
	end

	lu.assertEquals(n, 13, "screens with a name token in Appendix A")
end

-- B-2: the token screens of Appendix A really are the client lines that carry a token
function TestStormT3Oracle:test_the_name_token_screens_are_exactly_the_client_lines_with_a_token()
	local fromText, fromRows = {}, {}

	for _, row in ipairs(D.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			fromText[row.id] = true
		end

		if row.token ~= "" then
			fromRows[row.id] = true
		end
	end

	lu.assertEquals(fromRows, fromText, "Appendix A token screens vs client lines with %TU/%NU")
end
