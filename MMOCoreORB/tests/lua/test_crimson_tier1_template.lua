-- Da'la Socuna: the conversation template (Appendix A), its client strings and the fixtures that carry them.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-5, invariant I-8; Content contract 3 and 5; Data mapping 3; FI-2, FI-3; D-2, D-3, D-4).
--
-- Answer keys: crimson_tier1_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_rebel_trainer_1.java (harness/swgjava.lua), and the generated client id list
-- fixtures/string/en/conversation/tatooine_rebel_trainer_1.sids (generated read-only from /tre by tools/gen_client_sids.py).

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")
local TEXT = require("crimson_tier1_client_text")
local Swgjava = require("harness.swgjava")
local KD = require("space_convo_client_strings_data")

I.load()

local PATHS = { I.TEMPLATE_FILE, I.HANDLER_FILE }
local PREFIX = I.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
local JAVA = "script/conversation/tatooine_rebel_trainer_1.java"

local function template() return H.conversationTemplateTable(I.TEMPLATE) end

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

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestCrimsonT1Oracle = {}

function TestCrimsonT1Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 181 screens, ids unique, and it uses all 327 client lines (the other two entries are do_not_edit and s_0)
function TestCrimsonT1Oracle:test_appendix_a_has_181_screens_and_uses_every_client_line()
	lu.assertEquals(#I.SCREENS, 181, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(I.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	-- the two with-ship replies of C-2 ("It's about time.", "Thank you very much.") are set by the handler, not in a static row
	used.s_c5cc6139 = true
	used.s_4136c2df = true

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
	lu.assertEquals(count(used), 327, "distinct client lines Appendix A uses")
end

-- AC-5 (the oracle itself): the generated client id list holds the 329 entries the spec names (327 lines plus do_not_edit and s_0)
function TestCrimsonT1Oracle:test_the_client_id_fixture_holds_329_ids()
	local ids = CS.sids(I.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. I.STF .. ".sids")
	lu.assertEquals(count(ids), 329, "ids in fixtures/string/en/" .. I.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the pre-NGE-only lines (FI-2, FI-3), so a wrong sid fails with the words
function TestCrimsonT1Oracle:test_the_pre_nge_only_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_eff4eef6, "%TU, isn't it?", "grounded line 1")
	lu.assertEquals(TEXT.s_370822d1, "Yes", "grounded reply 1")
	lu.assertStrContains(TEXT.s_90087734, "Bad news for you, %NU.  Alliance command has grounded you.")
	lu.assertEquals(TEXT.s_841d27db, "Why?", "grounded reply 2")
	lu.assertStrContains(TEXT.s_4c85e14a, "You don't seem very dedicated to the cause.")
	lu.assertEquals(TEXT.s_4d2987d3, "No I haven't!", "grounded reply 3")
	lu.assertStrContains(TEXT.s_4dd4aa17, "Then you've been framed, %TU.")
	lu.assertEquals(TEXT.s_26970ef, "I am interested in basic starfighter training.", "starships topic")
	lu.assertEquals(TEXT.s_d912490, "I am interested in basic Alliance component use.", "weapons topic")
	lu.assertEquals(TEXT.s_8c272224, "I am interested in starfighter survival tactics.", "procedures topic")
	lu.assertEquals(TEXT.s_9480f430, "I am interested in droid interface basics.", "droid topic")
	lu.assertStrContains(TEXT.s_c7afc225, "Let's upgrade your starship license then, shall we?")
	lu.assertStrContains(TEXT.s_d5bc59d9, "I have adjusted your pilot certification to handle more intricate components.")
	lu.assertStrContains(TEXT.s_96e50d8, "Here is an update to your procedures manual.")
	lu.assertStrContains(TEXT.s_c93f1cdc, "Here are some new droid programs. Use them wisely.")
	lu.assertStrContains(TEXT.s_6221bd32, "What areas of Alliance piloting interest you the most?")
	lu.assertStrContains(TEXT.s_2c8ee9d, "What areas interest you at the moment?")
	lu.assertStrContains(TEXT.s_1d3d8b65, "You don't look like any sort of pilot to me.")
	lu.assertStrContains(TEXT.s_1622e456, "My name is Da'la Socuna")
end

-- AC-5 (the oracle itself): exactly nine client lines carry a %TU or %NU token, the ones of NAME_SCREENS
function TestCrimsonT1Oracle:test_exactly_nine_screens_show_a_name_token()
	local tokens = {}

	for _, row in ipairs(I.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			tokens[#tokens + 1] = row.id
			lu.assertTrue(row.name, row.id .. ": Appendix A marks it NAME")
		else
			lu.assertFalse(row.name, row.id .. ": Appendix A marks it NAME but its line has no token")
		end
	end

	table.sort(tokens)
	lu.assertEquals(tokens, { "eker_great_things", "eker_respect", "eker_with_you", "enlist_ground", "enlist_recruiter", "grounded", "grounded_bad_news", "grounded_framed", "m3_impatient" },
		"screens whose line carries %TU or %NU")

	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" then
			local token = text:match("%%([A-Z][A-Z])")

			lu.assertTrue(token == nil or token == "TU" or token == "NU", id .. ": a token other than %TU and %NU: " .. tostring(token))
		end
	end
end

-- AC-5 (the oracle itself): the fixtures that carry the answer are byte copies of SWG-Source and of the client list
function TestCrimsonT1Oracle:test_the_swg_fixtures_are_byte_copies_of_the_clone()
	requireClone()

	for _, name in ipairs({ "patrol/tatooine_rebel_1", "destroy_surpriseattack/tatooine_rebel_1", "destroy/tatooine_rebel_3", "patrol/tatooine_rebel_2", "escort/tatooine_rebel_2",
		"assassinate/tatooine_rebel_4", "destroy_duty/tatooine_rebel_6", "escort_duty/tatooine_rebel_7" }) do
		lu.assertTrue(readFile(H.FIXTURES .. "spacequest/" .. name .. ".tab", "rb") == readFile(GAME .. "datatables/spacequest/" .. name .. ".tab", "rb"), "fixtures/spacequest/" .. name .. ".tab differs from the SWG-Source file")
	end

	lu.assertTrue(readFile(H.FIXTURES .. JAVA, "rb") == readFile(GAME .. JAVA, "rb"), "fixtures/" .. JAVA .. " differs from the SWG-Source file")

	-- the buildout excerpt: BO rows 1-2 (header), the 4 spawners and the 13 nav points, in BO order
	local rows = {}
	local n = 0

	for line in readFile(GAME .. "datatables/space_zones/buildout/space_tatooine.tab", "rb"):gmatch("([^\n]*\n?)") do
		n = n + 1
		rows[n] = line
	end

	local want = {}

	for _, k in ipairs({ 1, 2, 47, 50, 115, 142, 159, 160, 161, 162, 163, 164, 165, 166, 167, 171, 173, 175, 177 }) do
		want[#want + 1] = rows[k]
	end

	lu.assertTrue(readFile(H.FIXTURES .. "space_zones/buildout/space_tatooine.crimson_phoenix_tier1_points.tab", "rb") == table.concat(want),
		"the buildout excerpt differs from BO rows 1-2, 47, 50, 115, 142, 159-167, 171, 173, 175, 177")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestCrimsonT1Template = {}

function TestCrimsonT1Template:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5, I-8
function TestCrimsonT1Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, I.screenIds(), I.TEMPLATE .. ": screen ids (181, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestCrimsonT1Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, I.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-2)")
	end
end

-- AC-5, I-8: the static options in order (the training menus, the oath screens, the M3 pay screens and non_member hold the default links)
function TestCrimsonT1Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(I.SCREENS) do
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

-- AC-5, I-8
function TestCrimsonT1Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(I.TEMPLATE), {}, I.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestCrimsonT1Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, I.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestCrimsonT1Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(H.SCRIPTS .. I.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_rebel_trainer_1:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_rebel_trainer_1", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 181, "leftDialog lines with a comment")
end

-- Content contract 3: the nine NAME screens show the first name; no other screen sets a parameter
function TestCrimsonT1Template:test_the_nine_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	for _, row in ipairs(I.SCREENS) do
		for _, g in ipairs(I.GLOBALS) do
			H.spyOn(I.quest(g), "startQuest")
		end

		local t = I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id)

		if row.name then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the %TU parameter is the pilot's first name")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no %TU parameter")
		end

		H.reset()
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, FI-2)
---------------------------------------------------------------------------------------------

TestCrimsonT1ClientStrings = {}

function TestCrimsonT1ClientStrings:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5: no id the pre-NGE client lacks
function TestCrimsonT1ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, FI-2: the port uses all 327 client lines and no other id
function TestCrimsonT1ClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
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
	lu.assertEquals(missing, {}, "client lines of tatooine_rebel_trainer_1 the template and handler never show")
	lu.assertEquals(count(used), 327, "distinct ids used")
end

-- AC-5, I-8: no NGE editor number (s_<decimal>) in either source
function TestCrimsonT1ClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('tatooine_rebel_trainer_1:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-5: the handler uses complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestCrimsonT1ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Socuna sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: TRAIN_CHOICES holds complete literals (Content contract 3)
function TestCrimsonT1ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readScript(I.HANDLER_FILE)

	for _, t in ipairs(I.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "socunaConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "socunaConvoHandler.lua: no stringFile prefix local")
end

-- AC-5: the training menus and the trained screens show the pre-NGE client lines (FI-2); the topics are in table order
function TestCrimsonT1ClientStrings:test_the_training_menus_and_trained_screens_show_the_pre_nge_lines()
	local byId = screensById()

	lu.assertEquals(byId.training_first.leftDialog, PREFIX .. I.MENU_FIRST, "training_first shows s_6221bd32")
	lu.assertEquals(byId.training_more.leftDialog, PREFIX .. I.MENU_MORE, "training_more shows s_2c8ee9d")

	for _, t in ipairs(I.TRAIN) do
		lu.assertEquals(byId[t.screen].leftDialog, PREFIX .. t.sid, t.screen .. " shows its line")
		lu.assertEquals(byId[t.screen].animation, "salute1", t.screen .. ": salute1 (D-2)")
		lu.assertEquals(byId[t.screen].stopConversation, "true", t.screen .. " ends")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A (I-8, D-2)
---------------------------------------------------------------------------------------------

TestCrimsonT1JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. JAVA)

-- the (NPC line, reply, next line) triples whose reply or next line the handler chooses at run time (C-1, C-2, C-3), kept by the handler's links and not by static options
local CONDITIONAL = {
	["s_16949037|s_8be95ab4|s_f4642ca3"] = "C-3 m3r_outstanding to m3r_bandolier",
	["s_4c1acfbf|s_8be95ab4|s_f4642ca3"] = "C-3 m3r_beautifully to m3r_bandolier",
	["s_f2ef125b|s_8be95ab4|s_f4642ca3"] = "C-3 m3r_lucky to m3r_bandolier",
	["s_57c3f83e|s_1583743c|s_c5ac7e76"] = "C-1 non_member to non_member_duty_offer",
	["s_a13bb0b0|s_c5cc6139|s_b3408be1"] = "C-2 oath_regret to first_assignment (with a ship)",
}

function TestCrimsonT1JavaGraph:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-5 (the oracle itself)
function TestCrimsonT1Oracle:test_the_answer_key_parses_198_npc_lines()
	lu.assertEquals(#GRAPH.order, 198, "NPC lines parsed from tatooine_rebel_trainer_1.java")
end

-- The triples of J whose three ids are client ids
local function clientTriples()
	local CLIENT = CS.sids(I.STF)
	local out, seen = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] and not seen[sid .. "|" .. reply] then
					seen[sid .. "|" .. reply] = true

					for _, nxt in ipairs(GRAPH.successorsOf(sid, reply)) do
						if CLIENT[nxt] then
							out[#out + 1] = { sid, reply, nxt }
						end
					end
				end
			end
		end
	end

	return out
end

-- AC-5, I-8 (the oracle itself; spec: "all 263 J (NPC line, reply, next line) triples whose three ids are client ids are kept"): every such triple is a
-- (dialog, reply, target dialog) of a screen of Appendix A, except the five whose link the handler chooses (C-1, C-2, C-3)
function TestCrimsonT1Oracle:test_every_java_triple_of_client_lines_is_kept_by_appendix_a()
	local byId, kept = {}, {}

	for _, row in ipairs(I.SCREENS) do
		byId[row.id] = row
	end

	for _, row in ipairs(I.SCREENS) do
		for _, o in ipairs(row.options) do
			kept[row.sid .. "|" .. o[1] .. "|" .. byId[o[2]].sid] = true
		end
	end

	local triples, missing = clientTriples(), {}

	for _, t in ipairs(triples) do
		local key = table.concat(t, "|")

		if not kept[key] and CONDITIONAL[key] == nil then
			missing[#missing + 1] = key
		end
	end

	table.sort(missing)
	lu.assertEquals(#triples, 263, "(NPC line, reply, next line) triples of client ids in the java")
	lu.assertEquals(missing, {}, "java triples of client lines that no Appendix A screen keeps")

	local conditional = 0

	for _, t in ipairs(triples) do
		if CONDITIONAL[table.concat(t, "|")] ~= nil then
			conditional = conditional + 1
		end
	end

	lu.assertEquals(conditional, 5, "triples kept by a handler-set link")
end

-- AC-5, I-8: the built template keeps those triples too (by dialog line, in the template, not only in the data file)
function TestCrimsonT1JavaGraph:test_the_template_keeps_every_java_triple_of_client_lines()
	local byId, kept = screensById(), {}

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			local target = byId[o[2]]

			if target ~= nil then
				kept[s.leftDialog .. "|" .. o[1] .. "|" .. target.leftDialog] = true
			end
		end
	end

	local missing = {}

	for _, t in ipairs(clientTriples()) do
		local key = table.concat(t, "|")

		if not kept[PREFIX .. t[1] .. "|" .. PREFIX .. t[2] .. "|" .. PREFIX .. t[3]] and CONDITIONAL[key] == nil then
			missing[#missing + 1] = key
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "java triples of client lines the template lacks")
end

-- AC-5, D-2: a screen whose dialog line is an NPC line of the java ends iff the java line ends and plays the java line's animation;
-- two reasons for a difference (both in the spec): the NGE dead end of grounded (J s_eff4eef6 ends, the pre-NGE chain goes on, FI-3) and the
-- pound_fist_palm of recruit_fun (D-2: J's anim_poundFist action on that line)
function TestCrimsonT1JavaGraph:test_every_screen_with_a_java_line_ends_and_animates_like_it()
	local byId = screensById()
	local compared, differing = 0, {}

	for _, row in ipairs(I.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			compared = compared + 1

			local s = byId[row.id]

			if (s.stopConversation == "true") ~= node.isEnd or (s.animation or "") ~= (node.animation or "") then
				differing[#differing + 1] = row.id
			end
		end
	end

	table.sort(differing)
	lu.assertEquals(compared, 174, "screens whose dialog line is a java NPC line")
	lu.assertEquals(differing, { "grounded", "recruit_fun" }, "screens that differ from the java line in end flag or animation (grounded: FI-3; recruit_fun: D-2)")
end

---------------------------------------------------------------------------------------------
-- The client-strings ratchet and the fixture (AC-5)
---------------------------------------------------------------------------------------------

TestCrimsonT1Fixtures = TestCrimsonT1Fixtures or {}

function TestCrimsonT1Fixtures:setUp() H.reset() end

-- AC-5: the ratchet entry and the count (72 files)
function TestCrimsonT1Fixtures:test_fixture_counts_holds_socunas_file_with_329_ids_as_the_72nd_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[I.STF], 329, "FIXTURE_COUNTS[" .. I.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 79, "FIXTURE_COUNTS entries") -- 73 since crimson-phoenix-tier2-eker-convo, 74 since crimson-phoenix-tier3-ulvawop, 75 since crimson-phoenix-tier4-ufwol, 78 since battlefield-entry-stations
end

-- AC-5: nothing is allowed to be unresolved
function TestCrimsonT1Fixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- AC-5: the feature's header line in the ratchet data file and the entry's place
function TestCrimsonT1Fixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertNotNil(text:find("-- crimson-phoenix-tier1-da-la-socuna: Commander Da'la Socuna's conversation/tatooine_rebel_trainer_1 (329 ids, served from patch_12_00.tre) is new and fully resolved (the 72nd file); KNOWN_GAPS stays {}.", 1, true),
		"the header comment line of the feature in space_convo_client_strings_data.lua")
	lu.assertNotNil(text:find('["conversation/tatooine_rebel_trainer_1"] = 329,', 1, true), "the FIXTURE_COUNTS entry text")
end

-- AC-5: the space conversation sources reference Socuna's string file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestCrimsonT1Fixtures:test_the_space_conversation_sources_reference_socunas_string_file()
	I.requireConversation(lu)

	local found = false

	for _, file in ipairs(CS.referencedFiles(CS.spaceConversationSources())) do
		found = found or file == I.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. I.STF)
end

-- AC-5: the fixture is 329 sorted unique lines, including do_not_edit and s_0
function TestCrimsonT1Fixtures:test_the_sids_fixture_has_329_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. I.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 329, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- AC-5: gen_client_sids.py --check passes for the file (the fixture is what the client serves); -B keeps the run from leaving bytecode
function TestCrimsonT1Fixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -B -I tests/lua/tools/gen_client_sids.py --check " .. I.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. I.STF .. ": " .. out)
end

-- AC-5: the first holder of the string file in the TreFiles order is patch_12_00.tre (the fixture is read from it)
function TestCrimsonT1Fixtures:test_the_first_holder_of_the_string_file_is_patch_12_00()
	requireTre()

	local script = "import sys; sys.dont_write_bytecode = True; sys.path.insert(0, 'tests/lua/tools'); import gen_client_sids as g; a = g.Archives('/tre'); "
		.. "t = b'string/en/conversation/tatooine_rebel_trainer_1.stf'; "
		.. "print(next((n for n in g.tre_order() if (a.open(n) is not None and t in a.open(n).entries)), 'none'))"
	local rc, out = shell("python3 -B -I -c \"" .. script .. "\"")

	lu.assertEquals(rc, 0, "first holder lookup: " .. out)
	lu.assertStrContains(out, "patch_12_00.tre", false, "the first holder of " .. I.STF)
end

-- AC-5: no bytecode left behind by the checks
function TestCrimsonT1Fixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
