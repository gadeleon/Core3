-- Brother Ezkiel: the conversation template (Appendix A, 131 screens), its client strings, the SWG java answer key and the client-strings ratchet.
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-1 last bullet of the template, AC-2, I-1, I-2; Content contract 2 and 4; Data mapping 2; FV-1; D-1, D-2).
--
-- Answer keys: vortex_tier3_ezkiel_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of fixtures/script/conversation/naboo_rebel_tier3.java
-- (harness/swgjava.lua), the generated client id list fixtures/string/en/conversation/naboo_rebel_tier3.sids and the client text vortex_tier3_ezkiel_client_text.lua.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local CS = require("harness.client_strings")
local TEXT = require("vortex_tier3_ezkiel_client_text")
local KD = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")

W.loadConversation()

local PATHS = { W.TEMPLATE_FILE, W.HANDLER_FILE }
local PREFIX = W.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
local JAVA = "script/conversation/naboo_rebel_tier3.java"

local function template() return H.conversationTemplateTable(W.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path, mode)
	local f = assert(io.open(path, mode or "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function readScript(path) return readFile(H.SCRIPTS .. path) end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function requireClone()
	local f = io.open(GAME .. JAVA, "rb")

	if f == nil then
		lu.skip("SWG-Source research tree not present")
	end

	f:close()
end

local function requireTre()
	local f = io.open("/tre/patch_12_00.tre", "rb")

	if f == nil then
		lu.skip("/tre/patch_12_00.tre is not readable: the archive checks need the client files")
	end

	f:close()
end

local function count(t)
	local n = 0

	for _ in pairs(t) do
		n = n + 1
	end

	return n
end

-- The J3 slot an Appendix A row fills when its dialog is an NGE slot ([T s_x], [R s_13], "(slot s_x)"), else nil
local function slotOf(row)
	return row.note:match("%[T (s_%d+)%]") or row.note:match("%(slot (s_%d+)%)") or (row.note:find("[R s_13]", 1, true) and "s_13") or nil
end

local GRAPH = Swgjava.read(H.FIXTURES .. JAVA)
local CLIENT = CS.sids(W.STF)

---------------------------------------------------------------------------------------------
-- The oracle itself (Appendix A, the fixtures, the client text)
---------------------------------------------------------------------------------------------

TestEzkielOracle = {}

function TestEzkielOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 131 screens, ids unique, and uses all 224 client lines (the other two entries are do_not_edit and s_0)
function TestEzkielOracle:test_appendix_a_has_131_screens_and_uses_every_one_of_the_224_client_lines()
	lu.assertEquals(#W.SCREENS, 131, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(W.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	lu.assertNotNil(CLIENT, "fixtures/string/en/" .. W.STF .. ".sids")

	local missing, extra = {}, {}

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(used) do
		if not CLIENT[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(missing)
	table.sort(extra)
	lu.assertEquals(missing, {}, "client lines Appendix A never uses")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(count(used), 224, "distinct client ids Appendix A uses")
end

-- AC-2 (the oracle itself): the client text table and the id fixture hold the 226 entries of the spec
function TestEzkielOracle:test_the_client_id_fixture_and_the_text_table_hold_226_entries()
	lu.assertEquals(count(CLIENT), 226, "ids in fixtures/string/en/" .. W.STF .. ".sids")
	lu.assertEquals(count(TEXT), 226, "entries of vortex_tier3_ezkiel_client_text.lua")

	for id in pairs(CLIENT) do
		lu.assertNotNil(TEXT[id], "client text of " .. id)
	end
end

-- AC-2 (the oracle itself): NAME_SCREENS (8) is exactly the screens whose line has a %TU or %NU token
function TestEzkielOracle:test_name_screens_are_exactly_the_screens_whose_line_has_a_name_token()
	local derived = {}

	for _, row in ipairs(W.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			derived[#derived + 1] = row.id
		end
	end

	local listed = {}

	for i, id in ipairs(W.NAME_SCREENS) do
		listed[i] = id
	end

	table.sort(derived)
	table.sort(listed)
	lu.assertEquals(#listed, 8, "NAME_SCREENS entries")
	lu.assertEquals(derived, listed, "screens whose line carries %TU or %NU")
end

-- AC-2 (the oracle itself): J3 uses 264 ids, 219 of them in the client file and 45 NGE editor numbers; the 5 unused client lines are the pre-NGE training (FV-1)
function TestEzkielOracle:test_j3_uses_264_ids_of_which_45_are_nge_numbers_and_5_client_lines_are_unused()
	local used = {}

	for id in readFile(H.FIXTURES .. JAVA):gmatch('"(s_[%w]+)"') do
		used[id] = true
	end

	local nge, stf, unusedClient = {}, 0, {}

	for id in pairs(used) do
		if CLIENT[id] then
			stf = stf + 1
		else
			nge[#nge + 1] = id
		end
	end

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			unusedClient[#unusedClient + 1] = id
		end
	end

	local want = {}

	for i, id in ipairs(W.NGE_IDS) do
		want[i] = id
	end

	table.sort(nge)
	table.sort(want)
	table.sort(unusedClient)
	lu.assertEquals(count(used), 264, "distinct ids J3 uses")
	lu.assertEquals(stf, 219, "of them client ids")
	lu.assertEquals(nge, want, "the NGE editor numbers J3 uses (Source inventory 7)")
	lu.assertEquals(unusedClient, { "s_5a7254ca", "s_879249ea", "s_a436613b", "s_ccecab6a", "s_e6be1367" }, "client lines J3 never uses: the pre-NGE training dialogue (FV-1)")
end

-- AC-2 (the oracle itself): the four topic replies and the grant line are the words of the client; each topic matches its skill's client name (skl_n)
function TestEzkielOracle:test_the_pre_nge_training_lines_are_the_words_of_the_client_and_match_the_skill_names()
	lu.assertEquals(TEXT.s_5a7254ca, "One of our pilots will teach you that skill. When you're done, I will have another mission for you.", "the one grant line")

	for _, t in ipairs(W.TRAIN) do
		lu.assertStrContains(TEXT[t.reply]:lower(), t.words, false, t.x .. " topic reply " .. t.reply .. " says what skl_n '" .. t.skl .. "' teaches")
	end

	lu.assertEquals(TEXT.s_879249ea, "I'm interested in space superiority fighters.")
	lu.assertEquals(TEXT.s_a436613b, "I'm interested in advanced starship component use.")
	lu.assertEquals(TEXT.s_e6be1367, "I'm interested in advanced space combat.")
	lu.assertEquals(TEXT.s_ccecab6a, "I'm interested in system balance programming.")
end

-- AC-2 (the oracle itself): the answer key parses the 143 NPC lines of J3, a byte copy of the clone
function TestEzkielOracle:test_the_java_answer_key_parses_143_npc_lines()
	lu.assertEquals(#GRAPH.order, 143, "NPC lines parsed from naboo_rebel_tier3.java")
end

-- AC-2 (the oracle itself; FV: every J3 (NPC line, reply) pair whose two ids are client ids is kept): 96 such pairs, each a (dialog, reply) of a row
function TestEzkielOracle:test_every_java_pair_of_client_lines_is_kept_by_some_screen_of_appendix_a()
	local kept = {}

	for _, row in ipairs(W.SCREENS) do
		for _, o in ipairs(row.options) do
			kept[row.sid .. "|" .. o[1]] = true
		end
	end

	local seen, pairsN, missing = {}, 0, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				local key = sid .. "|" .. reply

				if CLIENT[reply] and not seen[key] then
					seen[key] = true
					pairsN = pairsN + 1

					if not kept[key] then
						missing[#missing + 1] = key
					end
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(pairsN, 96, "(NPC line, reply) pairs of client ids in the java")
	lu.assertEquals(missing, {}, "java pairs of client lines that no Appendix A screen keeps")
end

-- Content contract 2 (the oracle itself): START_SCREENS is exactly the 17 client NPC lines that carry a grantQuestN action (J3), REWARD_SCREENS the four rewardForQuestN
function TestEzkielOracle:test_start_and_reward_screens_are_the_screens_of_the_java_grant_and_reward_actions()
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }
	local wantStart, wantReward = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, action in ipairs(GRAPH.nodes[sid].actions) do
				local grant = action:match("^grantQuest(%a+)$")
				local reward = action:match("^rewardForQuest(%a+)$")

				for _, row in ipairs(W.SCREENS) do
					if row.sid == sid and grant then
						wantStart[row.id] = words[grant]
					elseif row.sid == sid and reward then
						wantReward[row.id] = words[reward]
					end
				end
			end
		end
	end

	lu.assertEquals(count(wantStart), 17, "screens whose J3 line grants a quest")
	lu.assertEquals(W.START_SCREENS, wantStart, "START_SCREENS (the J3 grantQuestN carriers)")
	lu.assertEquals(W.REWARD_SCREENS, wantReward, "REWARD_SCREENS (the J3 rewardForQuestN carriers)")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestEzkielTemplate = {}

function TestEzkielTemplate:setUp()
	H.reset()
	W.requireConversation(lu)
end

-- AC-2, I-1: ids and their order are Appendix A's (the spec: "one ConvoScreen per Appendix A row, in Appendix A order")
function TestEzkielTemplate:test_the_template_has_exactly_the_131_screens_of_appendix_a_in_order()
	local got, want = {}, {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	for i, row in ipairs(W.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(got, want, W.TEMPLATE .. ": screen ids in order (131, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestEzkielTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(W.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, W.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only)")
	end
end

-- AC-2, I-1: the static options in order (the four reward screens hold all four topics; C-1 rebuilds the list)
function TestEzkielTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(W.SCREENS) do
		local want = {}

		for i, o in ipairs(row.options) do
			want[i] = { PREFIX .. o[1], o[2] }
		end

		local got = {}

		for i, o in ipairs(byId[row.id].options or {}) do
			got[i] = { o[1], o[2] }
		end

		lu.assertEquals(got, want, "screen '" .. row.id .. "': options (reply text, link)")
	end
end

-- AC-2, I-1
function TestEzkielTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(W.TEMPLATE), {}, W.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestEzkielTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, W.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestEzkielTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(W.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_rebel_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_rebel_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 131, "leftDialog lines with a comment")
end

-- Content contract 2: the file ends with the registration of the template under its name
function TestEzkielTemplate:test_the_template_is_registered_under_its_name_at_the_end_of_the_file()
	local source = readScript(W.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate%("ezkiel_convo_template",%s*ezkiel_convo_template%)%s*$'), "the file ends with addConversationTemplate(\"ezkiel_convo_template\", ezkiel_convo_template)")
end

-- Content contract 2 (NAME_SCREENS): every screen whose line carries %TU / %NU shows the first name; no other screen sets a parameter (the pilot's name is "Ace")
function TestEzkielTemplate:test_the_8_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local names = {}

	for _, id in ipairs(W.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(W.SCREENS) do
		H.reset()
		W.spyStarts()

		local player = W.pilot({ missions = 3, t3 = 3, state = "won" })
		local t = W.drive(player, row.id)

		lu.assertEquals(#t >= 1, true, "screen '" .. row.id .. "': shown")

		if names[row.id] then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the first name is the text parameter")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no text parameter")
		end
	end
end

-- Data mapping 2: the screens that fill an NGE NPC slot take the slot's J3 animation and end like the slot; every other screen with a J3 line plays that line's
function TestEzkielTemplate:test_every_screen_animates_and_ends_like_its_j3_line_or_slot()
	local byId = screensById()
	local compared, slots = 0, 0

	for _, row in ipairs(W.SCREENS) do
		local slot = slotOf(row)
		local node = GRAPH.nodes[slot or row.sid]

		if node ~= nil then
			if slot then
				slots = slots + 1
			else
				compared = compared + 1
			end

			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. (slot or row.sid) .. "): ends the conversation iff the java does")
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. (slot or row.sid) .. "): the java's doAnimationAction")
		end
	end

	lu.assertEquals(slots, 11, "screens that fill an NGE NPC slot (s_13, six m1 twins, four trained screens)")
	lu.assertEquals(compared, 120, "screens whose dialog line is a java NPC line")
end

-- Data mapping 2 (D-9): wrong_faction is its own screen with the non-pilot line; the four trained screens show the one client grant line and end
function TestEzkielTemplate:test_wrong_faction_and_the_trained_screens_show_the_lines_the_spec_maps()
	local byId = screensById()

	lu.assertEquals(byId.wrong_faction.leftDialog, PREFIX .. "s_8a226979", "wrong_faction shows the non-pilot line (R s_13)")
	lu.assertEquals(byId.not_pilot.leftDialog, PREFIX .. "s_8a226979", "not_pilot")
	lu.assertEquals(byId.wrong_faction.stopConversation, "true", "wrong_faction ends")

	for _, t in ipairs(W.TRAIN) do
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. W.TRAINED_SID, t.trained .. " shows the grant line")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends")
		lu.assertEquals(byId[t.trained].animation, nil, t.trained .. ": no animation (the slot s_313..s_316 has none)")
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2)
---------------------------------------------------------------------------------------------

TestEzkielClientStrings = {}

function TestEzkielClientStrings:setUp()
	H.reset()
	W.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestEzkielClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 224 client lines and no other id
function TestEzkielClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == W.STF then
			used[lit.id] = true
		end
	end

	local missing = {}

	for id in pairs(CLIENT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of naboo_rebel_tier3 the template and handler never show")
	lu.assertEquals(count(used), 224, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestEzkielClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('naboo_rebel_tier3:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-2: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestEzkielClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Ezkiel sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler names the four topic replies as complete literals (Content contract 2)
function TestEzkielClientStrings:test_the_handler_names_the_topic_replies_as_complete_literals()
	local source = readScript(W.HANDLER_FILE)

	for _, t in ipairs(W.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "ezkielConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "ezkielConvoHandler.lua: no stringFile prefix local")
end

-- AC-2: every reward screen offers the four topics by default, in TRAIN_CHOICES order (the static list C-1 rebuilds)
function TestEzkielClientStrings:test_the_four_reward_screens_list_the_four_topics_in_menu_order()
	local byId = screensById()

	for _, id in ipairs({ "m1_reward", "m2_reward", "m3_reward", "m4_reward" }) do
		local got = {}

		for i, o in ipairs(byId[id].options) do
			got[i] = { o[1], o[2] }
		end

		local want = {}

		for i, t in ipairs(W.TRAIN) do
			want[i] = { PREFIX .. t.reply, t.trained }
		end

		lu.assertEquals(got, want, id .. ": the topics and the trained screens they link to")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A and the built template (I-1)
---------------------------------------------------------------------------------------------

TestEzkielJavaGraph = {}

function TestEzkielJavaGraph:setUp()
	H.reset()
	W.requireConversation(lu)
end

-- AC-2, I-1: the built template keeps those 96 pairs too
function TestEzkielJavaGraph:test_the_template_keeps_every_java_pair_of_client_lines()
	local kept = {}

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			kept[s.leftDialog .. "|" .. o[1]] = true
		end
	end

	local missing = {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] and not kept[PREFIX .. sid .. "|" .. PREFIX .. reply] then
					missing[#missing + 1] = sid .. "|" .. reply
				end
			end
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "java pairs of client lines the template lacks")
end

-- AC-2, I-1: every link of the built template that the spec does not mark [R]/[T]/[b]/[P]/C-1 is J3's: the target's dialog is a successor of (line, reply) in the
-- java graph (a link into an NGE slot twin is checked against the slot)
function TestEzkielJavaGraph:test_every_unmarked_link_is_a_link_of_the_java()
	local byId = screensById()
	local checked = 0

	for _, row in ipairs(W.SCREENS) do
		if slotOf(row) == nil and GRAPH.nodes[row.sid] ~= nil and row.cond ~= "C-1" then
			local marked = {}

			for _, m in ipairs(row.marks) do
				marked[m] = true
			end

			for _, o in ipairs(byId[row.id].options or {}) do
				local reply = o[1]:sub(#PREFIX + 1)

				if not marked[reply] then
					checked = checked + 1

					local target = W.screenRow(o[2])
					local key = slotOf(target) or target.sid
					local successors = GRAPH.successorsOf(row.sid, reply) or {}
					local ok = false

					for _, succ in ipairs(successors) do
						ok = ok or succ == key
					end

					lu.assertTrue(ok, "screen '" .. row.id .. "' reply " .. reply .. " -> '" .. o[2] .. "' (" .. key .. "): J3 leads to {" .. table.concat(successors, ",") .. "}")
				end
			end
		end
	end

	lu.assertEquals(checked, 95, "unmarked links compared with the java")
end

---------------------------------------------------------------------------------------------
-- Fixtures and the client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestEzkielFixtures = {}

function TestEzkielFixtures:setUp() H.reset() end

-- AC-2: the ratchet entry and the count (70 files)
function TestEzkielFixtures:test_fixture_counts_holds_ezkiels_file_with_226_ids_as_the_70th_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[W.STF], 226, "FIXTURE_COUNTS[" .. W.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 79, "FIXTURE_COUNTS entries") -- 70 since vortex-tier3-ezkiel, 71 since vortex-tier4-extok-evin-convo, 72 since crimson-phoenix-tier1-da-la-socuna, 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop, 75 since crimson-phoenix-tier4-ufwol, 78 since battlefield-entry-stations
end

-- AC-2: nothing is allowed to be unresolved
function TestEzkielFixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestEzkielFixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- vortex-tier3-ezkiel: Brother Ezkiel's conversation/naboo_rebel_tier3 (226 ids, served from patch_12_00.tre) is new and fully resolved (the 70th file); KNOWN_GAPS stays {}.", false)
end

-- AC-2: the referenced string files of the space conversation sources include Ezkiel's file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestEzkielFixtures:test_the_space_conversation_sources_reference_ezkiels_string_file()
	W.requireConversation(lu)

	local found = false

	for _, file in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		found = found or file == W.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. W.STF)
end

-- AC-2: the fixture is 226 sorted unique lines, including do_not_edit and s_0
function TestEzkielFixtures:test_the_sids_fixture_has_226_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. W.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 226, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- Content contract 4: J3 is a byte copy of the clone
function TestEzkielFixtures:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. JAVA, "rb") == readFile(GAME .. JAVA, "rb"), "fixtures/" .. JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: J3 is the 5,563 line script of the spec (the line numbers of the spec's citations hold)
function TestEzkielFixtures:test_the_java_fixture_is_the_5563_line_script_of_the_spec()
	local lines = 0

	for _ in readFile(H.FIXTURES .. JAVA, "rb"):gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 5562 and lines <= 5564, "lines in naboo_rebel_tier3.java: " .. lines)
end

-- AC-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestEzkielFixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. W.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. W.STF .. ": " .. out)
end

-- AC-2: no bytecode left behind by the checks
function TestEzkielFixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
