-- Arnecio Ulvaw'op: the conversation template (Appendix A, 144 screens), its client strings, the SWG java answer key and the client-strings ratchet.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-2, I-1, I-2; Content contract 2 and 4; Data mapping 2; FU-1 to FU-6; D-1, D-2).
--
-- Answer keys: crimson_tier3_ulvawop_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/tatooine_rebel_tier3.java (harness/swgjava.lua), the generated client id list
-- fixtures/string/en/conversation/tatooine_rebel_tier3.sids and the client text crimson_tier3_ulvawop_client_text.lua.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local CS = require("harness.client_strings")
local TEXT = require("crimson_tier3_ulvawop_client_text")
local KD = require("space_convo_client_strings_data")
local Swgjava = require("harness.swgjava")

T.loadConversation()

local PATHS = { T.TEMPLATE_FILE, T.HANDLER_FILE }
local PREFIX = T.PREFIX
local GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

local function template() return H.conversationTemplateTable(T.TEMPLATE) end

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
	local f = io.open(GAME .. T.JAVA, "rb")

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

local GRAPH = Swgjava.read(H.FIXTURES .. T.JAVA)
local CLIENT = CS.sids(T.STF)

---------------------------------------------------------------------------------------------
-- The oracle itself (Appendix A, the fixtures, the client text)
---------------------------------------------------------------------------------------------

TestUlvawopOracle = {}

function TestUlvawopOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): Appendix A has 144 screens, ids unique, and uses all 261 client lines (the other two entries are do_not_edit and s_0)
function TestUlvawopOracle:test_appendix_a_has_144_screens_and_uses_every_one_of_the_261_client_lines()
	lu.assertEquals(#T.SCREENS, 144, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(T.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	lu.assertNotNil(CLIENT, "fixtures/string/en/" .. T.STF .. ".sids")

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
	lu.assertEquals(count(used), 261, "distinct client ids Appendix A uses")
end

-- AC-2 (the oracle itself): every link target of Appendix A exists
function TestUlvawopOracle:test_every_appendix_a_link_target_exists()
	for _, row in ipairs(T.SCREENS) do
		for _, o in ipairs(row.options) do
			lu.assertNotNil(T.screenRow(o[2]), "screen '" .. row.id .. "': link target '" .. o[2] .. "'")
		end
	end
end

-- AC-2 (the oracle itself): the client text table and the id fixture hold the 263 entries of the spec
function TestUlvawopOracle:test_the_client_id_fixture_and_the_text_table_hold_263_entries()
	lu.assertEquals(count(CLIENT), 263, "ids in fixtures/string/en/" .. T.STF .. ".sids")
	lu.assertEquals(count(TEXT), 263, "entries of crimson_tier3_ulvawop_client_text.lua")

	for id in pairs(CLIENT) do
		lu.assertNotNil(TEXT[id], "client text of " .. id)
	end
end

-- AC-2 (the oracle itself): NAME_SCREENS (4) is exactly the screens whose line has a %TU or %NU token
function TestUlvawopOracle:test_name_screens_are_exactly_the_screens_whose_line_has_a_name_token()
	local derived = {}

	for _, row in ipairs(T.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			derived[#derived + 1] = row.id
		end
	end

	local listed = {}

	for i, id in ipairs(T.NAME_SCREENS) do
		listed[i] = id
	end

	table.sort(derived)
	table.sort(listed)
	lu.assertEquals(#listed, 4, "NAME_SCREENS entries")
	lu.assertEquals(derived, listed, "screens whose line carries %TU or %NU")
end

-- AC-2 (the oracle itself, FU-1): the exact client text of the pre-NGE training lines, so a wrong sid fails with the words
function TestUlvawopOracle:test_the_pre_nge_training_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_c43eb58, "Teach me about space superiority fighters.", "starships topic")
	lu.assertEquals(TEXT.s_9b989e16, "Teach me about advanced Alliance component use.", "weapons topic")
	lu.assertEquals(TEXT.s_3a9f883c, "Teach me about advanced space combat.", "procedures topic")
	lu.assertEquals(TEXT.s_473d09d8, "Teach me about system balance programming.", "droid topic")
	lu.assertEquals(TEXT.s_337aea88, "I am not in need of training.", "decline reply")
	lu.assertEquals(TEXT.s_3b851af5, "I'll teach you what I know. If you want another mission later, ask me.", "starships answer")
	lu.assertEquals(TEXT.s_738d24fd, "Very well, let's begin. Talk to me again when you are ready for a mission.", "weapons answer")
	lu.assertEquals(TEXT.s_7da64d88, "Ah, that will be very useful.  Let's begin, and later I'll be ready to give you a mission.", "procedures answer")
	lu.assertEquals(TEXT.s_aa4f6738, "I can and I will. Find me later, when you are ready for another mission.", "droid answer")
	lu.assertEquals(TEXT.s_329414b2, "Please, do not waste your time talking to me. You are needed elsewhere.", "on_mission: the decline's target line (D-6)")
end

-- AC-2 (the oracle itself): the answer key parses the 140 client NPC lines among JU's NPC lines (every client line occurs once as an NPC line, FU-2)
function TestUlvawopOracle:test_the_java_answer_key_has_140_client_npc_lines_each_once()
	local n = 0

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			n = n + 1
		end
	end

	lu.assertEquals(n, 140, "client ids among the NPC lines of tatooine_rebel_tier3.java")
end

-- AC-2 (the oracle itself): Appendix A's animations and end flags are JU's for every row whose line is a JU NPC line (all but the four trained lines)
function TestUlvawopOracle:test_appendix_a_animations_and_ends_are_the_java_ones()
	local compared = 0

	for _, row in ipairs(T.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if row.tag == "P" and row.id:find("^trained_") then
			lu.assertNil(node, "Appendix A row '" .. row.id .. "': a pre-NGE-only line is no JU NPC line")
			lu.assertEquals(row.animation, "", "Appendix A row '" .. row.id .. "': no animation (JU's s_662..s_665 have none)")
		else
			compared = compared + 1
			lu.assertNotNil(node, "Appendix A row '" .. row.id .. "' (" .. row.sid .. "): a JU NPC line")
			lu.assertEquals(row.animation, node.animation or "", "Appendix A row '" .. row.id .. "' (" .. row.sid .. "): animation")
			lu.assertEquals(row.stop, node.isEnd, "Appendix A row '" .. row.id .. "' (" .. row.sid .. "): ends iff the java line ends")
		end
	end

	lu.assertEquals(compared, 140, "Appendix A rows whose line is a JU NPC line")
end

-- AC-2, I-1 (the oracle itself): every Appendix A link not marked [R]/[T]/[b] on a row that is neither a C-1 screen nor a trained line is a JU triple (109 of 109); the 28
-- marked links are not JU triples (they replace an NGE slot, Data mapping 2)
function TestUlvawopOracle:test_every_unmarked_appendix_a_link_is_a_ju_triple_and_the_marked_ones_are_not()
	local unmarked, marked = 0, 0

	for _, row in ipairs(T.SCREENS) do
		if row.cond ~= "C-1" and row.tag ~= "P" then
			for _, o in ipairs(row.options) do
				local want, isJu = T.screenRow(o[2]).sid, false

				for _, nxt in ipairs(GRAPH.successorsOf(row.sid, o[1]) or {}) do
					isJu = isJu or nxt == want
				end

				if o[3] == "" then
					unmarked = unmarked + 1
					lu.assertTrue(isJu, "row '" .. row.id .. "': link " .. o[1] .. " -> " .. o[2] .. " is not a JU triple")
				else
					marked = marked + 1
					lu.assertFalse(isJu, "row '" .. row.id .. "': marked link " .. o[1] .. " -> " .. o[2] .. " [" .. o[3] .. "] is a JU triple after all")
				end
			end
		end
	end

	lu.assertEquals(unmarked, 109, "unmarked links (the client triples of JU, spec Source inventory 7)")
	lu.assertEquals(marked, 28, "marked [R]/[T]/[b] links")
end

---------------------------------------------------------------------------------------------
-- The template (AC-2, I-1)
---------------------------------------------------------------------------------------------

TestUlvawopTemplate = {}

function TestUlvawopTemplate:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-2, I-1: ids and their order are Appendix A's
function TestUlvawopTemplate:test_the_template_has_exactly_the_144_screens_of_appendix_a_in_order()
	local got, want = {}, {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	for i, row in ipairs(T.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(got, want, T.TEMPLATE .. ": screen ids in order (144, no duplicates)")
end

-- AC-2, I-1: dialog, end flag, animation per screen
function TestUlvawopTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only)")
	end
end

-- AC-2, I-1: the static options in order (the four reward screens hold the default links C-1 rebuilds)
function TestUlvawopTemplate:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
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
function TestUlvawopTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- AC-2, I-1: every screen of the template is reachable from a gate screen, the handler's links or another screen (no orphan): the gates open on these screens
function TestUlvawopTemplate:test_every_screen_is_reachable_from_a_gate_or_a_link()
	local roots = {
		"not_pilot", "wrong_faction", "off_track", "grounded", "not_ready", "on_mission", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward",
		"m3_reward", "m4_reward", "m1_offer", "m2_offer", "m3_offer", "m4_offer", "handoff",
	}
	local seen = {}

	for _, root in ipairs(roots) do
		for id in pairs(T.reach(root)) do
			seen[id] = true
		end
	end

	-- the C-1 links: the four trained screens and the decline target
	for _, t in ipairs(T.TRAIN) do
		seen[t.trained] = true
	end

	local orphans = {}

	for _, row in ipairs(T.SCREENS) do
		if not seen[row.id] then
			orphans[#orphans + 1] = row.id
		end
	end

	lu.assertEquals(orphans, {}, "screens no gate, link or C-1 option reaches")
end

-- Content contract 2: the template shape
function TestUlvawopTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, T.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: line 1 is a header comment naming the trainer, the tier, the source script, the feature and the handler
function TestUlvawopTemplate:test_line_1_is_a_header_comment_naming_the_trainer_the_source_the_feature_and_the_handler()
	local first = readScript(T.TEMPLATE_FILE):match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "line 1 is a comment")

	for _, word in ipairs({ "Arnecio Ulvaw'op", "tier 3", "tatooine_rebel_tier3.java", "crimson-phoenix-tier3-ulvawop", "ulvawopConvoHandler" }) do
		lu.assertTrue(first:find(word, 1, true) ~= nil, "line 1 of " .. T.TEMPLATE_FILE .. " names '" .. word .. "': " .. first)
	end
end

-- Content contract 2: the complete English text of every line is a trailing comment on the leftDialog line
function TestUlvawopTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readScript(T.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_rebel_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_rebel_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 144, "leftDialog lines with a comment")
end

-- Content contract 2: each screen is a global ulvawop_convo_<id> added with ulvawop_convo_template:addScreen, in Appendix A order
function TestUlvawopTemplate:test_the_screens_are_globals_named_after_their_ids_added_in_order()
	local source = readScript(T.TEMPLATE_FILE)
	local added = {}

	for id in source:gmatch("ulvawop_convo_template:addScreen%(ulvawop_convo_([%w_]+)%)") do
		added[#added + 1] = id
	end

	local want = {}

	for i, row in ipairs(T.SCREENS) do
		want[i] = row.id
	end

	lu.assertEquals(added, want, "ulvawop_convo_template:addScreen(ulvawop_convo_<id>) calls in order")
end

-- Content contract 2: the file ends with the registration of the template under its name
function TestUlvawopTemplate:test_the_template_is_registered_under_its_name_at_the_end_of_the_file()
	local source = readScript(T.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate%("ulvawop_convo_template",%s*ulvawop_convo_template%)%s*$'),
		"the file ends with addConversationTemplate(\"ulvawop_convo_template\", ulvawop_convo_template)")
end

-- Content contract 2 (NAME_SCREENS): every screen whose line carries %TU / %NU shows the first name; no other screen sets a parameter (the pilot's name is "Ace")
function TestUlvawopTemplate:test_the_4_name_screens_show_the_first_name_and_no_other_screen_sets_a_parameter()
	local names = {}

	for _, id in ipairs(T.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(T.SCREENS) do
		H.reset()
		T.spyStarts()

		local player = T.pilot({ missions = 1, t3 = 1 })
		local t = T.drive(player, row.id)

		lu.assertEquals(#t >= 1, true, "screen '" .. row.id .. "': shown")

		if names[row.id] then
			lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. row.id .. "': the first name is the text parameter")
		else
			lu.assertNil(t[1].params.TU, "screen '" .. row.id .. "': no text parameter")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-2, I-2, FU-1, FU-2)
---------------------------------------------------------------------------------------------

TestUlvawopClientStrings = {}

function TestUlvawopClientStrings:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-2, I-2: no id the pre-NGE client lacks
function TestUlvawopClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-2, I-2: the port uses all 261 client lines and no other id
function TestUlvawopClientStrings:test_the_two_sources_use_every_client_line_of_the_file()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == T.STF then
			used[lit.id] = true
		end
	end

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
	lu.assertEquals(missing, {}, "client lines of tatooine_rebel_tier3 the template and handler never show")
	lu.assertEquals(extra, {}, "ids the sources use that the client file lacks")
	lu.assertEquals(count(used), 261, "distinct ids used")
end

-- AC-2, I-2: no NGE editor number (s_<decimal>) in either source
function TestUlvawopClientStrings:test_no_nge_editor_id_appears_in_either_source()
	for _, path in ipairs(PATHS) do
		local source = readScript(path)

		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			lu.assertNil(line:find('tatooine_rebel_tier3:s_%d%d?%d?"'), path .. ": an NGE-only id (s_<decimal>): " .. line)
		end
	end
end

-- AC-2: the sources use complete literals (KNOWN_DYNAMIC and KNOWN_PREFIX_USES stay as they are)
function TestUlvawopClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Ulvaw'op sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-2: the handler names the four topic replies and the decline reply as complete literals (Content contract 2)
function TestUlvawopClientStrings:test_the_handler_names_the_replies_it_builds_as_complete_literals()
	local source = readScript(T.HANDLER_FILE)

	for _, t in ipairs(T.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "ulvawopConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. T.DECLINE_REPLY .. '"', 1, true), "ulvawopConvoHandler.lua: complete literal for the decline reply " .. T.DECLINE_REPLY)
	lu.assertNil(source:find("local%s+stringFile%s*="), "ulvawopConvoHandler.lua: no stringFile prefix local")
end

-- AC-2: the TRAIN_CHOICES topic for each skill is the one FU-1 maps (the client skill names), and the four trained lines are the four FU-1 answers
function TestUlvawopClientStrings:test_the_topics_and_trained_lines_are_the_fu_1_lines()
	local byId = screensById()
	local words = { starships = "space superiority fighters", weapons = "advanced alliance component use", procedures = "advanced space combat", droid = "system balance programming" }

	for _, t in ipairs(T.TRAIN) do
		lu.assertTrue(TEXT[t.reply]:lower():find(words[t.x], 1, true) ~= nil, t.x .. " topic reply " .. t.reply .. " says '" .. words[t.x] .. "': " .. TEXT[t.reply])
		lu.assertEquals(byId[t.trained].leftDialog, PREFIX .. t.trainedSid, t.trained .. " shows its FU-1 answer line")
		lu.assertEquals(byId[t.trained].animation or "", "", t.trained .. ": no animation (JU's s_662..s_665 have none)")
		lu.assertEquals(byId[t.trained].stopConversation, "true", t.trained .. " ends (one skill per visit)")
		lu.assertEquals(#(byId[t.trained].options or {}), 0, t.trained .. " offers no reply")
	end

	lu.assertEquals(byId.on_mission.leftDialog, PREFIX .. "s_329414b2", "on_mission is the decline's target line (D-6)")
end

-- AC-2: the four reward screens list all four topics and then the decline as their static links (C-1 rebuilds them), the decline linking to on_mission
function TestUlvawopClientStrings:test_the_reward_screens_hold_the_four_topics_and_the_decline_as_static_links()
	local byId = screensById()

	for n = 1, 4 do
		local got = {}

		for i, o in ipairs(byId[T.MISSIONS[n].reward].options) do
			got[i] = { o[1], o[2] }
		end

		local want = {}

		for i, t in ipairs(T.TRAIN) do
			want[i] = { PREFIX .. t.reply, t.trained }
		end

		want[5] = { PREFIX .. T.DECLINE_REPLY, "on_mission" }
		lu.assertEquals(got, want, T.MISSIONS[n].reward .. ": static options")
	end
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with Appendix A (I-1, D-1)
---------------------------------------------------------------------------------------------

TestUlvawopJavaGraph = {}

function TestUlvawopJavaGraph:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- The (NPC line | reply | next line) triples of JU whose three ids are client ids
local function javaTriples()
	local out, seen = {}, {}

	for _, sid in ipairs(GRAPH.order) do
		if CLIENT[sid] then
			for _, reply in ipairs(GRAPH.nodes[sid].options) do
				if CLIENT[reply] then
					for _, nxt in ipairs(GRAPH.successorsOf(sid, reply) or {}) do
						local key = sid .. "|" .. reply .. "|" .. nxt

						if CLIENT[nxt] and not seen[key] then
							seen[key] = true
							out[#out + 1] = key
						end
					end
				end
			end
		end
	end

	return out
end

-- AC-2, I-1: the built template keeps every one of the 109 JU triples of client lines
function TestUlvawopJavaGraph:test_the_template_keeps_every_java_triple_of_client_lines()
	local kept = {}
	local byId = screensById()

	for _, s in ipairs(template().screens) do
		for _, o in ipairs(s.options or {}) do
			local target = byId[o[2]]

			if target ~= nil then
				kept[s.leftDialog .. "|" .. o[1] .. "|" .. target.leftDialog] = true
			end
		end
	end

	local triples, missing = javaTriples(), {}

	for _, key in ipairs(triples) do
		local a, b, c = key:match("^(.-)|(.-)|(.*)$")

		if not kept[PREFIX .. a .. "|" .. PREFIX .. b .. "|" .. PREFIX .. c] then
			missing[#missing + 1] = key
		end
	end

	lu.assertEquals(#triples, 109, "(NPC line, reply, next line) triples of client ids in the java")
	lu.assertEquals(missing, {}, "java triples of client lines the template lacks")
end

-- AC-2, I-1: a screen whose dialog line is an NPC line of the java ends iff the java line ends and plays the java line's animation (140 screens; the four trained
-- lines are no java lines)
function TestUlvawopJavaGraph:test_every_screen_with_a_java_line_plays_the_java_animation_and_ends_like_it()
	local byId = screensById()
	local compared = 0

	for _, row in ipairs(T.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			compared = compared + 1
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. row.sid .. "): the java's doAnimationAction")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
		end
	end

	lu.assertEquals(compared, 140, "screens whose dialog line is a java NPC line")
end

---------------------------------------------------------------------------------------------
-- Fixtures and the client-strings ratchet (AC-2)
---------------------------------------------------------------------------------------------

TestUlvawopFixtures = {}

function TestUlvawopFixtures:setUp() H.reset() end

-- AC-2: the ratchet entry and the count (74 files)
function TestUlvawopFixtures:test_fixture_counts_holds_ulvawops_file_with_263_ids_as_the_74th_entry()
	lu.assertEquals(KD.FIXTURE_COUNTS[T.STF], 263, "FIXTURE_COUNTS[" .. T.STF .. "]")
	lu.assertEquals(count(KD.FIXTURE_COUNTS), 75, "FIXTURE_COUNTS entries") -- 75 since crimson-phoenix-tier4-ufwol
end

-- AC-2: nothing is allowed to be unresolved
function TestUlvawopFixtures:test_known_gaps_stays_empty()
	lu.assertEquals(next(KD.KNOWN_GAPS), nil, "KNOWN_GAPS entries")
end

-- Content contract 4: the header line of the data file
function TestUlvawopFixtures:test_the_ratchet_data_file_carries_the_feature_header_line()
	local text = readFile("tests/lua/space_convo_client_strings_data.lua")

	lu.assertStrContains(text, "-- crimson-phoenix-tier3-ulvawop: Arnecio Ulvaw'op's conversation/tatooine_rebel_tier3 (263 ids, served from patch_12_00.tre) is new and fully resolved (the 74th file); KNOWN_GAPS stays {}.", false)
end

-- AC-2: the referenced string files of the space conversation sources include Ulvaw'op's file (the ratchet's referenced == FIXTURE_COUNTS check)
function TestUlvawopFixtures:test_the_space_conversation_sources_reference_ulvawops_string_file()
	T.requireConversation(lu)

	local referenced = CS.referencedFiles(CS.spaceConversationSources())
	local found = false

	for _, file in ipairs(referenced) do
		found = found or file == T.STF
	end

	lu.assertTrue(found, "the space conversation sources reference " .. T.STF)
end

-- AC-2: the fixture is 263 sorted unique lines, including do_not_edit and s_0
function TestUlvawopFixtures:test_the_sids_fixture_has_263_sorted_unique_lines()
	local text = readFile("tests/lua/fixtures/string/en/" .. T.STF .. ".sids")
	local lines, prev = {}, nil

	for line in text:gmatch("[^\n]+") do
		lu.assertTrue(prev == nil or prev < line, "sorted and unique at " .. line)
		prev = line
		lines[#lines + 1] = line
	end

	lu.assertEquals(#lines, 263, "lines")
	lu.assertEquals(lines[1], "do_not_edit", "first line")
	lu.assertEquals(lines[2], "s_0", "second line")
end

-- Content contract 4: JU is a byte copy of the clone
function TestUlvawopFixtures:test_the_java_script_is_a_byte_copy_of_swg_source()
	requireClone()

	lu.assertTrue(readFile(H.FIXTURES .. T.JAVA, "rb") == readFile(GAME .. T.JAVA, "rb"), "fixtures/" .. T.JAVA .. " differs from the SWG-Source file")
end

-- Content contract 4: JU is the 9,437 line script of the spec (the line numbers of the spec's citations hold)
function TestUlvawopFixtures:test_the_java_fixture_is_the_9437_line_script_of_the_spec()
	local text = readFile(H.FIXTURES .. T.JAVA, "rb")
	local lines = 0

	for _ in text:gmatch("\n") do
		lines = lines + 1
	end

	lu.assertTrue(lines >= 9436 and lines <= 9438, "lines in tatooine_rebel_tier3.java: " .. lines)
end

-- AC-2: gen_client_sids.py --check passes for the file (the fixture is what the client serves)
function TestUlvawopFixtures:test_the_generator_check_passes_for_the_fixture()
	requireTre()

	local rc, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 -I tests/lua/tools/gen_client_sids.py --check " .. T.STF)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check " .. T.STF .. ": " .. out)
end

-- AC-2: no bytecode left behind by the checks
function TestUlvawopFixtures:test_the_tools_directory_holds_no_pycache()
	local rc = shell("test ! -e tests/lua/tools/__pycache__")

	lu.assertEquals(rc, 0, "tests/lua/tools/__pycache__ exists")
end
