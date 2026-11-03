-- Beissa: the conversation template (Appendix A, 142 screens) and its client strings.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-5, invariant I-8; Content contract 3; Data mapping 3; FB-1 .. FB-5).
--
-- Answer keys: smuggler_tier3_screens_data.lua (Appendix A, generated from the spec table), the SWG java graph of
-- fixtures/script/conversation/tatooine_privateer_tier3.java (harness/swgjava.lua) with the three Data mapping 3 maps applied, and the generated client
-- id list fixtures/string/en/conversation/tatooine_privateer_tier3.sids. The first two classes need no production code and are green from the start.

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local CS = require("harness.client_strings")
local Swgjava = require("harness.swgjava")

B.load()

local TEXT = B.TEXT
local PATHS = { B.TEMPLATE_FILE, B.HANDLER_FILE }
local PREFIX = B.PREFIX

local function template() return H.conversationTemplateTable(B.TEMPLATE) end

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

-- SWG's string id is the CRC-32 (MSB first, polynomial 0x04C11DB7, init and xorout 0xFFFFFFFF) of the UTF-8 text (FB-1), written in unpadded hex
local function crc32(s)
	local c = 0xFFFFFFFF

	for i = 1, #s do
		c = c ~ (s:byte(i) << 24)

		for _ = 1, 8 do
			if c & 0x80000000 ~= 0 then
				c = ((c << 1) ~ 0x04C11DB7) & 0xFFFFFFFF
			else
				c = (c << 1) & 0xFFFFFFFF
			end
		end
	end

	return c ~ 0xFFFFFFFF
end

local function stfIds()
	local out = {}

	for id in pairs(CS.sids(B.STF)) do
		if id ~= "do_not_edit" and id ~= "s_0" then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

local GRAPH = Swgjava.read(B.BJ)

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestSmugglerT3Oracle2 = {}

function TestSmugglerT3Oracle2:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 142 screens with unique ids, and with the four topic replies it uses all 247 client lines and no other id
function TestSmugglerT3Oracle2:test_appendix_a_has_142_screens_and_uses_every_client_line()
	lu.assertEquals(#B.SCREENS, 142, "Appendix A rows")

	local seen = {}

	for _, row in ipairs(B.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
	end

	for _, row in ipairs(B.SCREENS) do
		for _, o in ipairs(row.options) do
			lu.assertNotNil(seen[o[2]], "screen '" .. row.id .. "' links to '" .. o[2] .. "', which is not an Appendix A screen")
		end
	end

	local all = stfIds()

	lu.assertEquals(#all, 247, "client lines (249 entries without do_not_edit and s_0... see the .sids count test)")
	lu.assertEquals(B.usedIds(), all, "ids Appendix A + the four topic replies use versus the client lines of tatooine_privateer_tier3")
end

-- AC-5 (the oracle itself): the generated client id list holds the 249 entries the spec names, and the text file the same ids
function TestSmugglerT3Oracle2:test_the_client_id_fixture_holds_249_ids_and_the_text_file_the_same()
	local n = 0
	local ids = CS.sids(B.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. B.STF .. ".sids")

	for id in pairs(ids) do
		n = n + 1
		lu.assertNotNil(TEXT[id], "smuggler_tier3_client_text.lua has no text for " .. id)
	end

	lu.assertEquals(n, 249, "ids in fixtures/string/en/" .. B.STF .. ".sids")

	local m = 0

	for _ in pairs(TEXT) do
		m = m + 1
	end

	lu.assertEquals(m, 249, "entries in smuggler_tier3_client_text.lua")
end

-- AC-5, FB-1 (the oracle itself): every client id is the CRC of its text, so two nodes with the same text share one id
function TestSmugglerT3Oracle2:test_every_client_id_is_the_crc_of_its_english_text()
	lu.assertEquals(string.format("s_%x", crc32("Sure.")), "s_8be640b8", "'Sure.'")
	lu.assertEquals(string.format("s_%x", crc32("No.")), "s_4c695dbd", "'No.'")
	lu.assertEquals(string.format("s_%x", crc32("[no answer]")), "s_1110a04b", "'[no answer]'")

	local bad = {}

	for _, id in ipairs(stfIds()) do
		local want = string.format("s_%x", crc32(TEXT[id]))

		if want ~= id then
			bad[#bad + 1] = id .. " (text hashes to " .. want .. ")"
		end
	end

	lu.assertEquals(bad, {}, "client ids that are not the CRC of their text")
end

-- AC-5 (the oracle itself): the generated fixture is what the generator makes from /tre now (skipped without /tre and python3)
function TestSmugglerT3Oracle2:test_the_sids_fixture_passes_the_generators_check()
	local tre = io.open("/tre/patch_12_00.tre", "rb")

	if tre == nil then
		lu.skip("/tre/patch_12_00.tre is absent")
	end

	tre:close()

	local pipe = io.popen("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check " .. B.STF .. " 2>&1; echo rc=$?")
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out:match("rc=(%d+)"), "0", "gen_client_sids.py --check " .. B.STF .. ": " .. out)
end

-- AC-5, FB-3 (the oracle itself): the two single-reply placements say what FB-3 says, so the twin ids are the words
function TestSmugglerT3Oracle2:test_the_reply_twins_resolve_to_client_texts_that_fit_their_slots()
	lu.assertEquals(TEXT.s_4c695dbd, "No.", "s_74 -> s_4c695dbd")
	lu.assertEquals(TEXT.s_bc375f79, "Got it.", "s_482 -> s_bc375f79")

	for nge, client in pairs(B.TWIN_REPLY) do
		lu.assertNotNil(TEXT[client], nge .. " -> " .. client .. ": the twin is not a client line")
		lu.assertTrue(GRAPH.responses[nge] == true, nge .. " is not a reply of the SWG script")
	end

	for nge, twin in pairs(B.TWIN_NPC) do
		lu.assertNotNil(TEXT[twin[1]], nge .. " -> " .. twin[1] .. ": the twin is not a client line")
		lu.assertNotNil(GRAPH.nodes[nge], nge .. " is not an NPC line of the SWG script")
		lu.assertNotNil(GRAPH.nodes[twin[1]], twin[1] .. " is not an NPC line of the SWG script")
	end
end

-- AC-5 (the oracle itself): the exact client text of the placed topic and answer lines (FB-5, Data mapping 3), so a wrong sid fails with the words
function TestSmugglerT3Oracle2:test_the_placed_pre_nge_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_c634ffcd, "Teach me about special warships.", "starships topic")
	lu.assertEquals(TEXT.s_a9aeb386, "Teach me about advanced starship component use.", "weapons topic")
	lu.assertEquals(TEXT.s_523a54d5, "Teach me about advanced techniques.", "procedures topic")
	lu.assertEquals(TEXT.s_473d09d8, "Teach me about system balance programming.", "droid topic")
	lu.assertNotNil(TEXT.s_e413d452:find("If you say so!", 1, true), "m1_trained: 'If you say so!'")
	lu.assertNotNil(TEXT.s_999144d9:find("Tut, tut!", 1, true), "m2_trained: 'Tut, tut!'")
	lu.assertNotNil(TEXT.s_32376199:find("Now who's giving the orders", 1, true), "m3_trained: 'Now who's giving the orders'")
	lu.assertNotNil(TEXT.s_f2593c16:find("Next time, say Please.", 1, true), "m4_trained: 'Next time, say Please.'")
end

-- AC-5 (the oracle itself): the %TU lines (setDialogTextTU)
function TestSmugglerT3Oracle2:test_the_seven_name_token_lines_carry_the_player_name_token()
	for _, sid in ipairs({ "s_38d9a05a", "s_e2e25101", "s_ea4e584a", "s_f840ac8a", "s_c9979b12", "s_5d667e15", "s_82751e5b" }) do
		lu.assertNotNil(TEXT[sid]:find("%TU", 1, true), sid .. " has %TU")
	end

	local n = 0

	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" and text:find("%TU", 1, true) then
			n = n + 1
		end
	end

	lu.assertEquals(n, 7, "client lines with %TU")
end

-- AC-5, Data mapping 3 (the oracle itself): the [R] flags of Appendix A are exactly the REJOIN table, the [T of s_n] tags exactly TWIN_NPC, and every [T] reply is a TWIN_REPLY value
function TestSmugglerT3Oracle2:test_the_flags_of_appendix_a_are_the_three_maps_of_data_mapping_3()
	local rejoins, twinNpc, twinReplies = {}, {}, 0

	for _, row in ipairs(B.SCREENS) do
		local n = row.tag:match("^T of (s_%d+)$")

		if n ~= nil then
			twinNpc[n] = { row.sid, row.id }
		end

		for _, o in ipairs(row.options) do
			if o[3]:find("[R]", 1, true) then
				rejoins[#rejoins + 1] = { row.id, o[1], o[2] }
			end

			if o[3]:find("[T]", 1, true) then
				twinReplies = twinReplies + 1

				local ok = false

				for _, client in pairs(B.TWIN_REPLY) do
					if client == o[1] then
						ok = true
					end
				end

				lu.assertTrue(ok, "screen '" .. row.id .. "': [T] reply " .. o[1] .. " is not a TWIN_REPLY value")
			end
		end
	end

	lu.assertEquals(twinNpc, B.TWIN_NPC, "NPC twin screens")

	local want = {}

	for i, r in ipairs(B.REJOIN) do
		want[i] = { r[1], r[2], r[5] }
	end

	lu.assertEquals(rejoins, want, "rejoin options (screen, reply, target)")
	lu.assertEquals(#B.REJOIN, 9, "rejoins")
end

-- AC-5, I-8 (the oracle itself): every Appendix A screen is reachable from a gate screen
function TestSmugglerT3Oracle2:test_every_appendix_a_screen_is_reachable_from_the_gate_screens()
	local gates = { "not_neutral", "off_track", "not_ready", "busy", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward", "m3_reward", "m4_reward",
		"m1_offer", "m2_offer", "m3_offer", "m4_offer", "tier_done" }
	local seen, queue = {}, {}

	for _, g in ipairs(gates) do
		seen[g] = true
		queue[#queue + 1] = g
	end

	-- the C-1 options of the reward screens lead to their trained screen
	local extra = { m1_reward = "m1_trained", m2_reward = "m2_trained", m3_reward = "m3_trained", m4_reward = "m4_trained" }

	local i = 1

	while i <= #queue do
		local row = B.screenRow(queue[i])

		i = i + 1

		local nexts = {}

		for _, o in ipairs(row.options) do
			nexts[#nexts + 1] = o[2]
		end

		if extra[row.id] then
			nexts[#nexts + 1] = extra[row.id]
		end

		for _, n in ipairs(nexts) do
			if not seen[n] then
				seen[n] = true
				queue[#queue + 1] = n
			end
		end
	end

	local missing = {}

	for _, row in ipairs(B.SCREENS) do
		if not seen[row.id] then
			missing[#missing + 1] = row.id
		end
	end

	lu.assertEquals(missing, {}, "Appendix A screens no gate screen leads to")
end

-- AC-5, I-8 (the oracle itself): every original link of Appendix A leads where the SWG script leads, after the twin and rejoin maps are applied
function TestSmugglerT3Oracle2:test_every_original_reply_end_flag_and_animation_agrees_with_the_swg_script()
	local javaNode = {}

	for _, row in ipairs(B.SCREENS) do
		local n = row.tag:match("^T of (s_%d+)$")

		javaNode[row.id] = n or row.sid
	end

	local screens, replies, rejoined = 0, 0, 0
	local rejoinSet = {}

	for _, r in ipairs(B.REJOIN) do
		rejoinSet[r[1] .. "/" .. r[2]] = r
	end

	for _, row in ipairs(B.SCREENS) do
		if row.tag ~= "P" then
			local node = GRAPH.nodes[javaNode[row.id]]

			screens = screens + 1
			lu.assertNotNil(node, "screen '" .. row.id .. "': the java has no NPC line " .. javaNode[row.id])
			lu.assertEquals(node.animation, row.animation, "screen '" .. row.id .. "' (" .. javaNode[row.id] .. "): animation")

			if row.cond == "" then
				lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. javaNode[row.id] .. "): ends the conversation iff the java does")
				lu.assertEquals(#row.options, #node.options, "screen '" .. row.id .. "' (" .. javaNode[row.id] .. "): number of replies")
			end

			for _, o in ipairs(row.options) do
				replies = replies + 1

				-- the java reply: the sid itself, or an NGE twin of it ([T])
				local candidates = { o[1] }

				for nge, client in pairs(B.TWIN_REPLY) do
					if client == o[1] then
						candidates[#candidates + 1] = nge
					end
				end

				local jr
				local have = {}

				for _, jo in ipairs(node.options) do
					have[jo] = true
				end

				for _, c in ipairs(candidates) do
					if have[c] then
						jr = jr or c

						if not o[3]:find("[T]", 1, true) and c == o[1] then
							jr = c
						end
					end
				end

				lu.assertNotNil(jr, "screen '" .. row.id .. "': the java line " .. javaNode[row.id] .. " has no reply " .. o[1] .. " (or a twin of it)")

				local succ = GRAPH.successorsOf(javaNode[row.id], jr) or {}
				local want = javaNode[o[2]]
				local ok = false

				for _, s in ipairs(succ) do
					if s == want then
						ok = true
					end
				end

				if o[3]:find("[R]", 1, true) then
					local r = rejoinSet[row.id .. "/" .. o[1]]

					rejoined = rejoined + 1
					lu.assertNotNil(r, "screen '" .. row.id .. "': [R] reply " .. o[1] .. " is not in REJOIN")
					lu.assertEquals(jr, r[3], "screen '" .. row.id .. "', reply " .. o[1] .. ": the java reply of the rejoin entry")

					local hit = false

					for _, s in ipairs(succ) do
						if s == r[4] then
							hit = true
						end
					end

					lu.assertTrue(hit, "screen '" .. row.id .. "', reply " .. jr .. ": the java successor " .. r[4] .. " (the NGE chain that is not ported) is not among " .. table.concat(succ, ","))
				else
					lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. jr .. ": the java leads to " .. table.concat(succ, ",") .. ", not to '" .. o[2] .. "' (" .. tostring(want) .. ")")
				end
			end
		end
	end

	lu.assertEquals(screens, 142 - 4, "Appendix A screens checked against the java (all but the four [P] answers)")
	lu.assertEquals(rejoined, 9, "rejoin links checked")
	lu.assertTrue(replies >= 100, "replies checked: " .. replies)
end

-- AC-5, D-6 (the oracle itself): the placed answer lines sit in the slot of BJ's four grant lines s_530 .. s_533
function TestSmugglerT3Oracle2:test_the_reward_screens_are_the_java_nodes_with_the_single_s_529_reply()
	for _, id in ipairs({ "m1_reward", "m2_reward", "m3_reward", "m4_reward" }) do
		local row = B.screenRow(id)
		local node = GRAPH.nodes[row.sid]

		lu.assertNotNil(node, id .. ": the java line " .. row.sid)
		lu.assertEquals(node.options, { "s_529" }, id .. ": the java reply (the NGE single reply that grants)")
		lu.assertEquals(row.options, {}, id .. ": Appendix A has no static option")
		lu.assertEquals(row.cond, "C-1", id .. ": handler-built options")
	end
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestSmugglerT3Template = {}

function TestSmugglerT3Template:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- AC-5, I-8
function TestSmugglerT3Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, B.screenIds(), B.TEMPLATE .. ": screen ids (142, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestSmugglerT3Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(B.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, B.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-11)")
	end
end

-- AC-5, I-8: the static options in order (the four reward screens are built at run time and have none in the template)
function TestSmugglerT3Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(B.SCREENS) do
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
function TestSmugglerT3Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(B.TEMPLATE), {}, B.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestSmugglerT3Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, B.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the first line is a header comment naming the feature; the file registers the template
function TestSmugglerT3Template:test_the_template_file_starts_with_a_header_comment_and_registers_through_add_conversation_template()
	local source = readFile(B.TEMPLATE_FILE)
	local first = source:match("^([^\n]*)")

	lu.assertNotNil(first:find("^%-%- Beissa"), "first line is a '-- Beissa' header comment: " .. first)
	lu.assertNotNil(source:find("smuggler-tier3-beissa", 1, true), "the header names the feature smuggler-tier3-beissa")
	lu.assertNotNil(source:find("conversation/tatooine_privateer_tier3", 1, true), "the header names the string file")
	lu.assertNotNil(source:find('addConversationTemplate("beissa_convo_template", beissa_convo_template)', 1, true), "addConversationTemplate call")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog and option lines
function TestSmugglerT3Template:test_every_dialog_and_option_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(B.TEMPLATE_FILE)
	local dialogs, replies = 0, 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_tier3:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			dialogs = dialogs + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_privateer_tier3", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end

		local osid, ocomment = line:match('{%s*"@conversation/tatooine_privateer_tier3:(s_[%w_]+)"%s*,[^}]*}%s*,?%s*%-%-%s*(.-)%s*$')

		if osid ~= nil then
			replies = replies + 1
			lu.assertEquals(ocomment, (TEXT[osid]:gsub("%s+$", "")), "trailing comment of the option line for " .. osid)
		elseif line:find('{%s*"@conversation/tatooine_privateer_tier3') then
			lu.fail("option line without the trailing client text: " .. line)
		end
	end

	local want = 0

	for _, row in ipairs(B.SCREENS) do
		want = want + #row.options
	end

	lu.assertEquals(dialogs, 142, "leftDialog lines with a comment")
	lu.assertEquals(replies, want, "option lines with a comment")
end

-- Content contract 3: complete literals, one per leftDialog and static option
function TestSmugglerT3Template:test_every_id_is_a_complete_string_literal()
	local source = readFile(B.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/tatooine_privateer_tier3:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(B.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/tatooine_privateer_tier3:s_... literals in the template (one per leftDialog and static option)")
end

-- AC-5: the four reward screens have no static option, and the trained screens end with their answer line and no reply
function TestSmugglerT3Template:test_the_reward_screens_have_no_static_option_and_the_trained_screens_show_the_answers_and_end()
	local byId = screensById()

	for n = 1, 4 do
		lu.assertEquals(#byId["m" .. n .. "_reward"].options, 0, "m" .. n .. "_reward: static options")
		lu.assertEquals(byId["m" .. n .. "_trained"].leftDialog, PREFIX .. B.TRAINED_SID[n], "m" .. n .. "_trained: the answer line")
		lu.assertEquals(byId["m" .. n .. "_trained"].stopConversation, "true", "m" .. n .. "_trained ends the conversation")
		lu.assertEquals(#byId["m" .. n .. "_trained"].options, 0, "m" .. n .. "_trained: replies")
		lu.assertEquals(byId["m" .. n .. "_trained"].animation or "", "", "m" .. n .. "_trained: animation (none, D-11)")
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestSmugglerT3ClientStrings = {}

function TestSmugglerT3ClientStrings:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks (in particular no NGE decimal id)
function TestSmugglerT3ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: the port uses all 247 client lines and no other id
function TestSmugglerT3ClientStrings:test_the_two_sources_use_every_client_line_of_the_file_and_no_decimal_id()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == B.STF then
			used[lit.id] = true
		end
	end

	local got = {}

	for id in pairs(used) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, stfIds(), "distinct tatooine_privateer_tier3 ids used by the template and handler (exactly the 247 client lines: no NGE editor number such as s_74 or s_529)")
end

-- AC-5: complete literals only
function TestSmugglerT3ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Beissa sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the handler names the four topic replies as complete literals (Content contract 3)
function TestSmugglerT3ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(B.HANDLER_FILE)

	for _, t in ipairs(B.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "beissaConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "beissaConvoHandler.lua: no stringFile prefix local")
end

---------------------------------------------------------------------------------------------
-- The %TU lines
---------------------------------------------------------------------------------------------

TestSmugglerT3Names = {}

function TestSmugglerT3Names:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- AC-5 (Content contract 3): the seven lines with %TU get the pilot's first name
function TestSmugglerT3Names:test_the_seven_name_token_screens_get_the_first_name()
	local ids = { "off_track", "m1_friendly", "m1_failed", "m1_accept", "m1b_accept", "tier_done" }

	for _, id in ipairs(ids) do
		local t = B.drive(B.pilot({ mission = { [1] = "attempted" } }), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the %TU parameter")
	end

	local t = B.drive(B.pilot({ mission = { [1] = "won" } }), "m1_reward")

	lu.assertEquals(t[1].params.TU, "Ace", "screen 'm1_reward': the %TU parameter")
end
