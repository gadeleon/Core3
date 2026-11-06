-- Inquisitor Vrke: the conversation template (Appendix A) and its client strings.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-5, invariant I-9; Content contract 3; Data mapping 3; FV-1, FV-5, FV-6; D-2, D-14).
--
-- Answer keys: inquisition_tier3_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/naboo_imperial_tier3.java (harness/swgjava.lua) for every link that is not a rejoin, a pre-NGE-only line or a
-- handler-built link, and the generated client id list fixtures/string/en/conversation/naboo_imperial_tier3.sids (324 ids, served from
-- patch_13_00.tre; FV-6).

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")
local TEXT = require("inquisition_tier3_client_text")
local Swgjava = require("harness.swgjava")

V.load()

local PATHS = { V.TEMPLATE_FILE, V.HANDLER_FILE }
local PREFIX = V.PREFIX

local function template() return H.conversationTemplateTable(V.TEMPLATE) end

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

local function isTrained(id) return id:match("^m%d_trained_%a+$") ~= nil end

TestInquisitionT3Oracle = {}

function TestInquisitionT3Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 173 screens, ids unique, and uses all 322 client lines and no other id
function TestInquisitionT3Oracle:test_appendix_a_has_173_screens_and_uses_every_client_line()
	lu.assertEquals(#V.SCREENS, 173, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(V.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(V.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. V.STF .. ".sids")

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

-- AC-5 (the oracle itself): the generated client id list holds the 324 lines the spec names (322 lines + do_not_edit + s_0)
function TestInquisitionT3Oracle:test_the_client_id_fixture_holds_324_ids()
	local n = 0

	for _ in pairs(CS.sids(V.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 324, "ids in fixtures/string/en/" .. V.STF .. ".sids")
end

-- AC-5 (the oracle itself): the TRAIN table's topic replies and trained screens are Appendix A rows, the training screens list all four topics in order
function TestInquisitionT3Oracle:test_the_train_table_matches_appendix_a()
	for screen, n in pairs(V.TRAINING_SCREENS) do
		local row = V.screenRow(screen)

		lu.assertNotNil(row, "Appendix A row " .. screen)
		lu.assertEquals(row.cond, "C-1", screen .. ": handler-built options")

		for i, t in ipairs(V.TRAIN) do
			lu.assertEquals(row.options[i], { t.reply, V.trained(n, i) }, screen .. " option " .. i)
		end

		lu.assertEquals(#row.options, 4, screen .. ": four static options")
	end

	for n = 1, 4 do
		for i, t in ipairs(V.TRAIN) do
			local row = V.screenRow(V.trained(n, i))

			lu.assertNotNil(row, "Appendix A row " .. V.trained(n, i))
			lu.assertEquals(row.sid, t.trainedSid[n], V.trained(n, i) .. ": dialog")
			lu.assertTrue(row.stop, V.trained(n, i) .. " ends the conversation")
			lu.assertEquals(row.tag, "P", V.trained(n, i) .. " is a pre-NGE line in an NGE slot")
		end
	end
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FV-1), so a wrong sid fails with the words
function TestInquisitionT3Oracle:test_the_pre_nge_topic_and_grant_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_40cda759, "Teach me about advanced capability TIE vessels.", "starships topic")
	lu.assertEquals(TEXT.s_a9aeb386, "Teach me about advanced starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_ef7a2df5, "Teach me about special forces training.", "procedures topic")
	lu.assertEquals(TEXT.s_473d09d8, "Teach me about system balance programming.", "droid topic")

	for i, t in ipairs(V.TRAIN) do
		lu.assertStrContains(TEXT[t.trainedSid[1]], "Go question Lieutenant Colonel Barlow", false, "M1 " .. t.x .. " grant line sends the pilot to Barlow")
		lu.assertStrContains(TEXT[t.trainedSid[2]], "my discussion with the doctor", false, "M2 " .. t.x .. " grant line")
		lu.assertStrContains(TEXT[t.trainedSid[3]], "this Dathomir lead", false, "M3 " .. t.x .. " grant line")
		lu.assertStrContains(TEXT[t.trainedSid[4]], "your next assignment", false, "M4 " .. t.x .. " grant line")
	end

	lu.assertStrContains(TEXT.s_5a27cd7a, "Imperial technology", false, "M1 starships")
	lu.assertStrContains(TEXT.s_a3dbeea3, "Imperial equipment", false, "M1 weapons")
	lu.assertStrContains(TEXT.s_96871003, "Imperial training", false, "M1 procedures")
	lu.assertStrContains(TEXT.s_eb077a31, "droid management", false, "M1 droid")
end

-- AC-5 (the oracle itself): the NGE-slot stand-ins of Data mapping 3 are the words of the client (class a / b / P rejoins)
function TestInquisitionT3Oracle:test_the_rejoined_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_421e1b5d, "Who is Lieutenant Colonel Barlow?", "s_97 / s_93")
	lu.assertEquals(TEXT.s_b3b2214d, "Why do I need to speak with him?", "s_74")
	lu.assertEquals(TEXT.s_383b4c1a, "You would allow a traitor to work for the Empire again?", "s_137")
	lu.assertEquals(TEXT.s_b9c39774, "Where should I start looking?", "s_268 / s_272")
	lu.assertEquals(TEXT.s_4c5e3fb9, "I believe that Colonel Hend's accomplice was a Doctor Shinss.", "s_279")
	lu.assertEquals(TEXT.s_75c4b8b4, "And then the enemy will attack?", "s_294")
	lu.assertEquals(TEXT.s_1c8bddbb, "What is it?", "s_300")
	lu.assertEquals(TEXT.s_1d1e30b6, "So I'm the bait.", "s_303")
	lu.assertEquals(TEXT.s_f8e71988, "I'm ready for my mission.", "s_317")
	lu.assertEquals(TEXT.s_dbd88d67, "Who, me?", "s_338")
	lu.assertEquals(TEXT.s_7426e000, "No!", "s_341")
	lu.assertEquals(TEXT.s_6c186cde, "What? Why?", "s_383")
end

TestInquisitionT3Template = {}

function TestInquisitionT3Template:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-5, I-9
function TestInquisitionT3Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, V.screenIds(), V.TEMPLATE .. ": screen ids (173, no duplicates)")
end

-- AC-5, I-9: dialog, end flag, animation per screen
function TestInquisitionT3Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(V.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, V.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, J3's, D-14)")
	end
end

-- AC-5, I-9: the static options in order (for the six training screens the full four-topic list is the default)
function TestInquisitionT3Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(V.SCREENS) do
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

-- AC-5
function TestInquisitionT3Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(V.TEMPLATE), {}, V.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestInquisitionT3Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, V.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestInquisitionT3Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(V.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_imperial_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_imperial_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 173, "leftDialog lines with a comment")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, FV-1, FV-5, FV-6)
---------------------------------------------------------------------------------------------

TestInquisitionT3ClientStrings = {}

function TestInquisitionT3ClientStrings:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks, in particular no NGE editor number
function TestInquisitionT3ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-9: no s_<decimal> id appears in either file (the 42 NGE editor numbers of J3 are all gone)
function TestInquisitionT3ClientStrings:test_neither_source_uses_a_decimal_editor_number()
	for _, path in ipairs(PATHS) do
		local source = readFile(path)

		-- an editor number has one to three digits (J3 goes up to s_434); the client ids are CRC hex of up to eight digits
		for id in source:gmatch('@conversation/naboo_imperial_tier3:(s_%d%d?%d?)"') do
			lu.fail(path .. " uses the NGE editor id " .. id .. " that the pre-NGE client lacks")
		end
	end

	-- the oracle: the 42 NGE ids of Data mapping 3 are not client lines
	local nge = { 74, 93, 97, 137, 268, 272, 279, 294, 300, 303, 317, 338, 341, 383, 223, 228, 296, 305, 321, 353, 366, 375, 426, 416, 406, 392 }

	for n = 398, 434, 2 do
		nge[#nge + 1] = n
	end

	local ids = CS.sids(V.STF)

	for _, n in ipairs(nge) do
		lu.assertNil(ids["s_" .. n], "precondition: the client has no s_" .. n)
	end
end

-- AC-5, I-9: the port uses all 322 client lines and no other id
function TestInquisitionT3ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local ids = CS.sids(V.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == V.STF then
			used[lit.id] = true
		end
	end

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
	lu.assertEquals(missing, {}, "client lines of naboo_imperial_tier3 the template and handler never show")
	lu.assertEquals(extra, {}, "ids the template and handler use that the client does not have")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 322, "distinct ids used")
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestInquisitionT3ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Vrke's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestInquisitionT3ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(V.HANDLER_FILE)

	for _, t in ipairs(V.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "vrkeConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "vrkeConvoHandler.lua: no stringFile prefix local")
end

-- FV-1: each trained screen shows its own grant line, one per mission and skill
function TestInquisitionT3ClientStrings:test_the_sixteen_trained_screens_show_the_pre_nge_grant_lines()
	local byId = screensById()

	for n = 1, 4 do
		for i, t in ipairs(V.TRAIN) do
			local id = V.trained(n, i)

			lu.assertEquals(byId[id].leftDialog, PREFIX .. t.trainedSid[n], id .. ": leftDialog")
			lu.assertEquals(#byId[id].options, 0, id .. ": no reply")
			lu.assertEquals(byId[id].stopConversation, "true", id .. " ends the conversation")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (I-9, D-2)
---------------------------------------------------------------------------------------------

TestInquisitionT3JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_imperial_tier3.java")

-- Data mapping 3: the 14 replies whose NGE editor number the port replaces by a client reply.
-- { screen, NGE reply of the java, client reply of the port, link of the port }
local REPLY_REJOINS = {
	{ "m1_reward_9df61e25", "s_97", "s_421e1b5d", "m1_reward_e8f655d8" },
	{ "m1_reward_47424e40", "s_93", "s_421e1b5d", "m1_reward_e8f655d8" },
	{ "m1_reward_e8f655d8", "s_74", "s_b3b2214d", "m1_reward_b49d8273" },
	{ "m2_reward_b61f3237", "s_137", "s_383b4c1a", "m2_reward_10a23848" },
	{ "m2_offer_7579d1ec", "s_268", "s_b9c39774", "m2_offer_a0c5cad7" },
	{ "m2_offer_120e3960", "s_272", "s_b9c39774", "m2_offer_a0c5cad7" },
	{ "m2_offer_bf06e3a1", "s_279", "s_4c5e3fb9", "m2_offer_76cdb911" },
	{ "m3_offer_31d4944f", "s_294", "s_75c4b8b4", "m3_accept_dathomir", "s_296" },
	{ "m3_offer_1d79fda2", "s_300", "s_1c8bddbb", "m3_offer_28876e4d" },
	{ "m3_offer_28876e4d", "s_303", "s_1d1e30b6", "m3_accept_bait", "s_305" },
	{ "m3_offer_679b150d", "s_317", "s_f8e71988", "m3_offer_39dfc6b4" },
	{ "m4_offer", "s_338", "s_dbd88d67", "m4_offer_7df37f4b" },
	{ "m4_offer_7df37f4b", "s_341", "s_7426e000", "m4_offer_1e10a6ef" },
	{ "m4_offer_7f3265a7", "s_383", "s_6c186cde", "m4_offer_e1a23a44" },
}

-- Data mapping 3: the 6 original replies whose NPC answer is an NGE line the port replaces.
-- { screen, reply (client and java), NGE successor of the java, link of the port }
local LINK_REJOINS = {
	{ "m1_offer_a16f3f3d", "s_d70dba34", "s_223", "m1_offer_d2a2c5a9" },
	{ "m1_offer_d1f39329", "s_4c695dbd", "s_228", "m1_offer_2fe1cf2f" },
	{ "m3_offer_39dfc6b4", "s_5188aced", "s_321", "m3_accept_dathomir" },
	{ "m4_offer_b374861b", "s_14ea12c8", "s_353", "m4_accept_accident_2" },
	{ "m4_offer_b333ecf9", "s_1ee84e30", "s_366", "m4_offer_b374861b" },
	{ "m4_offer_6905c6b2", "s_33c41dc", "s_375", "m4_accept_accident" },
}

function TestInquisitionT3JavaGraph:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-5 (the oracle itself)
function TestInquisitionT3Oracle:test_the_answer_key_parses_181_npc_lines()
	lu.assertEquals(#GRAPH.order, 181, "NPC lines parsed from naboo_imperial_tier3.java")
end

-- AC-5 (the oracle itself): 157 of the 173 screens are J3 NPC lines; the 24 J3 lines the port does not show are exactly the NGE ids
function TestInquisitionT3Oracle:test_the_java_lines_not_used_are_exactly_the_24_nge_numbered_lines()
	local used = {}

	for _, row in ipairs(V.SCREENS) do
		used[row.sid] = true
	end

	local unused, inJava = {}, 0

	for _, sid in ipairs(GRAPH.order) do
		if not used[sid] then
			unused[#unused + 1] = sid
		end
	end

	for _, row in ipairs(V.SCREENS) do
		if GRAPH.nodes[row.sid] then
			inJava = inJava + 1
		end
	end

	local want = { "s_223", "s_228", "s_296", "s_305", "s_321", "s_353", "s_366", "s_375" }

	for n = 398, 434, 2 do
		if n ~= 406 and n ~= 416 and n ~= 426 then
			want[#want + 1] = "s_" .. n
		end
	end

	table.sort(unused)
	table.sort(want)
	lu.assertEquals(unused, want, "J3 NPC lines Appendix A does not show")
	lu.assertEquals(inJava, 157, "Appendix A screens whose dialog is a J3 NPC line (173 less the 16 pre-NGE trained screens)")
end

-- AC-5, I-9: every screen that exists in the java ends exactly where the java ends, and every original reply leads where the java leads
function TestInquisitionT3JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script()
	local byId = screensById()
	local dialogOf = {}
	local skip = {}

	for _, row in ipairs(V.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	for _, d in ipairs(REPLY_REJOINS) do
		skip[d[1] .. "|" .. d[3] .. "|" .. d[4]] = true
	end

	for _, d in ipairs(LINK_REJOINS) do
		skip[d[1] .. "|" .. d[2] .. "|" .. d[4]] = true
	end

	local checked = 0

	for _, row in ipairs(V.SCREENS) do
		if not isTrained(row.id) then
			local node = GRAPH.nodes[row.sid]

			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")

			if row.cond ~= "C-1" then
				local have = {}

				for _, o in ipairs(node.options) do
					have[o] = true
				end

				for _, o in ipairs(row.options) do
					if not skip[row.id .. "|" .. o[1] .. "|" .. o[2]] then
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
	end

	lu.assertEquals(checked, 150, "original replies checked against the java (194 static replies less the 24 on the six training screens, which the handler builds, and the 20 rejoined: 14 replies, 6 answers)")
end

-- AC-5: each reply rejoin of Data mapping 3 is a row of Appendix A and the java has the NGE reply there instead
function TestInquisitionT3JavaGraph:test_the_listed_reply_rejoins_are_appendix_a_rows_where_the_java_has_an_nge_reply()
	lu.assertEquals(#REPLY_REJOINS, 14, "reply rejoins (Data mapping 3)")

	local ids = CS.sids(V.STF)

	for _, d in ipairs(REPLY_REJOINS) do
		local row = V.screenRow(d[1])

		lu.assertNotNil(row, "Appendix A row " .. d[1])

		local found = false

		for _, o in ipairs(row.options) do
			if o[1] == d[3] and o[2] == d[4] then
				found = true
			end
		end

		lu.assertTrue(found, d[1] .. " has the reply " .. d[3] .. " -> " .. d[4] .. " in Appendix A")
		lu.assertTrue(ids[d[3]] == true, d[3] .. " is a client line")
		lu.assertNil(ids[d[2]], d[2] .. " is an NGE editor number")

		local node = GRAPH.nodes[row.sid]
		local javaHas, clientHas = false, false

		for _, o in ipairs(node.options) do
			javaHas = javaHas or o == d[2]
			clientHas = clientHas or o == d[3]
		end

		lu.assertTrue(javaHas, d[1] .. ": the java line " .. row.sid .. " has the NGE reply " .. d[2])

		if d[5] then
			lu.assertEquals(GRAPH.successorsOf(row.sid, d[2]), { d[5] }, d[1] .. ": the java answers " .. d[2] .. " with the NGE line " .. d[5])
			lu.assertNil(ids[d[5]], d[5] .. " is an NGE editor number")
		end
	end
end

-- AC-5: each link rejoin keeps the client reply of the java and replaces its NGE answer line
function TestInquisitionT3JavaGraph:test_the_listed_link_rejoins_are_appendix_a_rows_where_the_java_answers_with_an_nge_line()
	lu.assertEquals(#LINK_REJOINS, 6, "link rejoins (Data mapping 3)")

	local ids = CS.sids(V.STF)

	for _, d in ipairs(LINK_REJOINS) do
		local row = V.screenRow(d[1])

		lu.assertNotNil(row, "Appendix A row " .. d[1])

		local found = false

		for _, o in ipairs(row.options) do
			if o[1] == d[2] and o[2] == d[4] then
				found = true
			end
		end

		lu.assertTrue(found, d[1] .. " has the reply " .. d[2] .. " -> " .. d[4] .. " in Appendix A")
		lu.assertEquals(GRAPH.successorsOf(row.sid, d[2]), { d[3] }, d[1] .. ": the java answers " .. d[2] .. " with the NGE line " .. d[3])
		lu.assertNil(ids[d[3]], d[3] .. " is an NGE editor number")
	end
end

---------------------------------------------------------------------------------------------
-- The %TU / %NU lines
---------------------------------------------------------------------------------------------

TestInquisitionT3Names = {}

function TestInquisitionT3Names:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- AC-5 (Content contract 3): lines with %TU / %NU get the pilot's first name, and only those
function TestInquisitionT3Names:test_lines_with_the_player_name_get_the_first_name()
	local n = 0

	for _, row in ipairs(V.SCREENS) do
		if row.token ~= "" then
			n = n + 1

			local t = V.drive(V.pilot({}), row.id)

			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %" .. row.token .. " parameter")
		end
	end

	lu.assertEquals(n, 4, "screens with a name token in Appendix A")
end

-- AC-5: the token screens of Appendix A really are the client lines that carry a token
function TestInquisitionT3Names:test_the_name_token_screens_are_exactly_the_client_lines_with_a_token()
	local fromText, fromRows = {}, {}

	for _, row in ipairs(V.SCREENS) do
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
