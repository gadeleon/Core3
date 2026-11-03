-- Nirame Sakute: the conversation template (Appendix A, 135 screens), its routes and its client strings.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-6, invariants I-8 and I-12; Content contract 3; Data mapping 3 and 4; FN-1 .. FN-5; Appendix A, D and E).
--
-- Answer keys: smuggler_tier4_screens_data.lua (Appendix A, generated from the spec table), the SWG java graph of
-- fixtures/script/conversation/tatooine_privateer_tier4.java (harness/swgjava.lua) with the Data mapping 3 slots applied, and the generated client id list
-- fixtures/string/en/conversation/tatooine_privateer_tier4.sids. The first two classes need no production code and are green from the start.

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local CS = require("harness.client_strings")
local Swgjava = require("harness.swgjava")

N.load()

local TEXT = N.TEXT
local PATHS = { N.TEMPLATE_FILE, N.HANDLER_FILE }
local PREFIX = N.PREFIX

local function template() return H.conversationTemplateTable(N.TEMPLATE) end

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

-- SWG's string id is the CRC-32 (MSB first, polynomial 0x04C11DB7, init and xorout 0xFFFFFFFF) of the UTF-8 text (BS FB-1), written in unpadded hex
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

	for id in pairs(CS.sids(N.STF)) do
		if id ~= "do_not_edit" and id ~= "s_0" then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

local GRAPH = Swgjava.read(N.NJ)

local BRIEF_HEADS = { m1_brief = true, m2_brief = true, m3_brief = true, m4_brief = true }

-- The gate screens (Conversation flow 1) and what the handler's C-1 .. C-3 and training add to the static links
local GATES = { "not_neutral", "off_track", "not_ready", "busy", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward", "m3_reward", "m4_reward",
	"ready", "ready_train", "intro", "tier4_incomplete", "transfer", "here_for_work" }

local EXTRA_LINKS = {
	off_track = { "off_track_refused" },
	ready = { "m1_brief", "m2_brief", "m3_brief", "m4_brief" },
	ready_train = { "m1_trained_starships", "m1_trained_weapons", "m1_trained_procedures", "m1_trained_droid", "m2_brief_trained", "m3_brief", "m4_brief_trained" },
}

-- adjacency { id = { link ids } } of a list of { id, links }
local function adjacencyOfRows()
	local adj = {}

	for _, row in ipairs(N.SCREENS) do
		adj[row.id] = {}

		for _, o in ipairs(row.options) do
			adj[row.id][#adj[row.id] + 1] = o[2]
		end
	end

	return adj
end

local function adjacencyOfTemplate()
	local adj = {}

	for _, s in ipairs(template().screens) do
		adj[s.id] = {}

		for _, o in ipairs(s.options) do
			adj[s.id][#adj[s.id] + 1] = o[2]
		end
	end

	return adj
end

-- Number of option paths from `from` to a stop in `adj` (every route), the set of end screens it reaches, and whether a cycle is on a route
local function routes(adj, ends, from)
	local count, reached, cyclic = 0, {}, false

	local function walk(id, onPath)
		if onPath[id] then
			cyclic = true
			return
		end

		local nexts = adj[id] or {}

		if #nexts == 0 then
			count = count + 1
			reached[id] = true
			return
		end

		onPath[id] = true

		for _, n in ipairs(nexts) do
			walk(n, onPath)
		end

		onPath[id] = nil
	end

	walk(from, {})

	return count, reached, cyclic
end

-- Strongly connected components with more than one screen (Tarjan), sorted member lists
local function cycles(adj)
	local index, stack, onStack, low, idx, out = 0, {}, {}, {}, {}, {}

	local function connect(v)
		index = index + 1
		idx[v], low[v] = index, index
		stack[#stack + 1] = v
		onStack[v] = true

		for _, w in ipairs(adj[v] or {}) do
			if idx[w] == nil then
				connect(w)
				low[v] = math.min(low[v], low[w])
			elseif onStack[w] then
				low[v] = math.min(low[v], idx[w])
			end
		end

		if low[v] == idx[v] then
			local comp = {}

			while true do
				local w = table.remove(stack)

				onStack[w] = nil
				comp[#comp + 1] = w

				if w == v then
					break
				end
			end

			if #comp > 1 then
				table.sort(comp)
				out[#out + 1] = comp
			end
		end
	end

	local ids = {}

	for id in pairs(adj) do
		ids[#ids + 1] = id
	end

	table.sort(ids)

	for _, id in ipairs(ids) do
		if idx[id] == nil then
			connect(id)
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestSmugglerT4Oracle2 = {}

function TestSmugglerT4Oracle2:setUp() H.reset() end

-- AC-6 (the oracle itself): Appendix A has 135 screens with unique ids, and with the four topic replies it uses all 245 client lines and no other id
function TestSmugglerT4Oracle2:test_appendix_a_has_135_screens_and_uses_every_client_line()
	lu.assertEquals(#N.SCREENS, 135, "Appendix A rows")

	local seen = {}

	for _, row in ipairs(N.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
	end

	for _, row in ipairs(N.SCREENS) do
		for _, o in ipairs(row.options) do
			lu.assertNotNil(seen[o[2]], "screen '" .. row.id .. "' links to '" .. o[2] .. "', which is not an Appendix A screen")
		end
	end

	local all = stfIds()

	lu.assertEquals(#all, 245, "client lines (247 entries without do_not_edit and s_0)")
	lu.assertEquals(N.usedIds(), all, "ids Appendix A + the four topic replies use versus the client lines of tatooine_privateer_tier4")
end

-- AC-6 (the oracle itself): the generated client id list holds the 247 entries the spec names, and the text file the same ids
function TestSmugglerT4Oracle2:test_the_client_id_fixture_holds_247_ids_and_the_text_file_the_same()
	local n = 0
	local ids = CS.sids(N.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. N.STF .. ".sids")

	for id in pairs(ids) do
		n = n + 1
		lu.assertNotNil(TEXT[id], "smuggler_tier4_client_text.lua has no text for " .. id)
	end

	lu.assertEquals(n, 247, "ids in fixtures/string/en/" .. N.STF .. ".sids")

	local m = 0

	for _ in pairs(TEXT) do
		m = m + 1
	end

	lu.assertEquals(m, 247, "entries in smuggler_tier4_client_text.lua")
end

-- AC-6, BS FB-1 (the oracle itself): every client id is the CRC of its text, so two nodes with the same text share one id
function TestSmugglerT4Oracle2:test_every_client_id_is_the_crc_of_its_english_text()
	lu.assertEquals(string.format("s_%x", crc32("Sure.")), "s_8be640b8", "'Sure.'")
	lu.assertEquals(string.format("s_%x", crc32("Okay.")), "s_67e6df55", "'Okay.'")
	lu.assertEquals(string.format("s_%x", crc32("Thanks.")), "s_fc27931b", "'Thanks.'")

	local bad = {}

	for _, id in ipairs(stfIds()) do
		local want = string.format("s_%x", crc32(TEXT[id]))

		if want ~= id then
			bad[#bad + 1] = id .. " (text hashes to " .. want .. ")"
		end
	end

	lu.assertEquals(bad, {}, "client ids that are not the CRC of their text")
end

-- AC-6 (the oracle itself): the generated fixture is what the generator makes from /tre now (skipped without /tre and python3)
function TestSmugglerT4Oracle2:test_the_sids_fixture_passes_the_generators_check()
	local tre = io.open("/tre/patch_12_00.tre", "rb")

	if tre == nil then
		lu.skip("/tre/patch_12_00.tre is absent")
	end

	tre:close()

	local pipe = io.popen("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check " .. N.STF .. " 2>&1; echo rc=$?")
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out:match("rc=(%d+)"), "0", "gen_client_sids.py --check " .. N.STF .. ": " .. out)
end

-- AC-6, Data mapping 3 (the oracle itself): the placed pre-NGE lines say what FN-1, FN-4 and FN-5 say, so the ids are the words
function TestSmugglerT4Oracle2:test_the_placed_lines_are_the_words_of_the_client()
	lu.assertEquals((TEXT.s_593a67cd:gsub("%s+$", "")), "Talon says you're a good worker. But I'll believe it when I see it!", "intro (slot s_350)")
	lu.assertEquals(TEXT.s_5866c569, "I follow you.", "reply for slot s_364")
	lu.assertEquals(TEXT.s_fc27931b, "Thanks.", "reply for slot s_69")
	lu.assertEquals(TEXT.s_71d95498, "So you want me to join the Rebellion?", "reply for slot s_403")
	lu.assertEquals(TEXT.s_67e6df55, "Okay.", "reply for slot s_378")
	lu.assertEquals(TEXT.s_842279cd, "How about exotic vessels?", "starships topic")
	lu.assertEquals(TEXT.s_dbb3b0b0, "How about heavy starship component use?", "weapons topic")
	lu.assertEquals(TEXT.s_ee28691a, "How about expert techniques?", "procedures topic")
	lu.assertEquals(TEXT.s_71d852f5, "How about droid intelligence theory?", "droid topic")

	for _, t in ipairs(N.TRAIN) do
		lu.assertNotNil(TEXT[t.answer]:find("Done! Now then. You did good work with Jabba.", 1, true), t.x .. " answer: 'Done! Now then. You did good work with Jabba.'")
	end

	lu.assertEquals(TEXT.s_bdae1e2f:match("^(%S+)"), "Vessels!", "starships answer")
	lu.assertEquals(TEXT.s_c40a86d2:match("^(%S+)"), "Components!", "weapons answer")
	lu.assertEquals(TEXT.s_e3cee4d9:match("^(%S+)"), "Techniques!", "procedures answer")
	lu.assertEquals(TEXT.s_b00344d:match("^(%S+)"), "Droids!", "droid answer")
	lu.assertNotNil(TEXT.s_da0b2b1e:find("^Now then%. You did good work with Jabba%."), "the M1 head")
	lu.assertEquals(TEXT.s_10c507d9, "Now that Jabba's content, we can go about our business.", "m2_brief_trained")
	lu.assertNotNil(TEXT.s_1bfa482b:find("Good job with those Valarian fighters!", 1, true), "m4_brief_trained")
end

-- AC-6 (the oracle itself): the %TU lines (setDialogTextTU)
function TestSmugglerT4Oracle2:test_the_four_name_token_lines_carry_the_player_name_token()
	for _, sid in ipairs({ "s_38a1649f", "s_62b0748", "s_a6359b23", "s_b1d60b3e" }) do
		lu.assertNotNil(TEXT[sid]:find("%TU", 1, true), sid .. " has %TU")
	end

	local n = 0

	for id, text in pairs(TEXT) do
		if id ~= "do_not_edit" and text:find("%TU", 1, true) then
			n = n + 1
		end
	end

	lu.assertEquals(n, 4, "client lines with %TU")
end

-- AC-6, FN-4 (the oracle itself): the NGE slots the spec fills are replies/NPC lines of the SWG script
function TestSmugglerT4Oracle2:test_the_slots_are_nodes_of_the_swg_script()
	for slot, client in pairs(N.SLOT_REPLY) do
		lu.assertNotNil(TEXT[client], slot .. " -> " .. client .. ": not a client line")
		lu.assertTrue(GRAPH.responses[slot] == true, slot .. " is not a reply of the SWG script")
	end

	for slot, twin in pairs(N.SLOT_NPC) do
		lu.assertNotNil(TEXT[twin[1]], slot .. " -> " .. twin[1] .. ": not a client line")
		lu.assertNotNil(GRAPH.nodes[slot], slot .. " is not an NPC line of the SWG script")
	end
end

-- AC-6, I-8 (the oracle itself): every Appendix A screen is reachable from a gate screen (with the conditional links)
function TestSmugglerT4Oracle2:test_every_appendix_a_screen_is_reachable_from_the_gate_screens()
	local adj = adjacencyOfRows()
	local seen, queue = {}, {}

	for _, g in ipairs(GATES) do
		seen[g] = true
		queue[#queue + 1] = g
	end

	local i = 1

	while i <= #queue do
		local id = queue[i]

		i = i + 1

		local nexts = {}

		for _, n in ipairs(adj[id]) do
			nexts[#nexts + 1] = n
		end

		for _, n in ipairs(EXTRA_LINKS[id] or {}) do
			nexts[#nexts + 1] = n
		end

		for _, n in ipairs(nexts) do
			if not seen[n] then
				seen[n] = true
				queue[#queue + 1] = n
			end
		end
	end

	local missing = {}

	for _, row in ipairs(N.SCREENS) do
		if not seen[row.id] then
			missing[#missing + 1] = row.id
		end
	end

	lu.assertEquals(missing, {}, "Appendix A screens no gate screen leads to")
end

-- AC-6, I-8 (the oracle itself): every row marked J leads where the SWG script leads (animation, end flag, replies, successors), except the Data mapping 3 edges
function TestSmugglerT4Oracle2:test_every_j_row_agrees_with_the_swg_script()
	local byId = {}

	for _, row in ipairs(N.SCREENS) do
		byId[row.id] = row
	end

	local screens, replies = 0, 0

	for _, row in ipairs(N.SCREENS) do
		if row.tag == "" then
			local node = GRAPH.nodes[row.sid]

			screens = screens + 1
			lu.assertNotNil(node, "screen '" .. row.id .. "': the java has no NPC line " .. row.sid)
			lu.assertEquals(node.animation or "", row.animation, "screen '" .. row.id .. "' (" .. row.sid .. "): animation")

			if row.cond == "" then
				lu.assertEquals(row.stop, node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
				lu.assertEquals(#row.options, #node.options, "screen '" .. row.id .. "' (" .. row.sid .. "): number of replies")
			end

			-- the four heads keep the java's reply COUNT, but their replies are the pre-NGE pool lines that replace the NGE subtrees (Data mapping 4)
			local options = row.options

			if BRIEF_HEADS[row.id] then
				options = {}
			end

			for _, o in ipairs(options) do
				replies = replies + 1

				local slot = o[3]:match("^%[T:(s_%d+)%]$")
				local jr = slot or o[1]
				local have = {}

				for _, jo in ipairs(node.options) do
					have[jo] = true
				end

				lu.assertTrue(have[jr] == true, "screen '" .. row.id .. "': the java line " .. row.sid .. " has no reply " .. jr .. " (" .. o[1] .. ")")

				local target = byId[o[2]]

				-- s_378 starts the NGE copy chain that ends on 'Okay.' (FN-4): not ported, rejoined at duty_escort_info
				if slot ~= "s_378" and target.tag == "" then
					local succ = GRAPH.successorsOf(row.sid, jr) or {}
					local ok = false

					for _, s in ipairs(succ) do
						if s == target.sid then
							ok = true
						end
					end

					lu.assertTrue(ok, "screen '" .. row.id .. "', reply " .. jr .. ": the java leads to " .. table.concat(succ, ",") .. ", not to '" .. o[2] .. "' (" .. target.sid .. ")")
				end
			end
		end
	end

	lu.assertTrue(screens >= 60, "J screens checked: " .. screens)
	lu.assertTrue(replies >= 60, "replies checked: " .. replies)
end

-- AC-6, Data mapping 3 (the oracle itself): the P rows sit in the NGE slots the spec names and are not nodes of the java
function TestSmugglerT4Oracle2:test_the_p_rows_are_the_pre_nge_lines_of_the_slots()
	local want = {
		intro = "s_593a67cd", m1_trained_starships = "s_bdae1e2f", m1_trained_weapons = "s_c40a86d2", m1_trained_procedures = "s_e3cee4d9", m1_trained_droid = "s_b00344d",
		m2_brief_trained = "s_10c507d9", m4_brief_trained = "s_1bfa482b",
	}
	local got = {}

	for _, row in ipairs(N.SCREENS) do
		if row.tag == "P" then
			got[row.id] = row.sid
			lu.assertNil(GRAPH.nodes[row.sid], "screen '" .. row.id .. "': " .. row.sid .. " is a pre-NGE line, not a node of the java")
		end
	end

	lu.assertEquals(got, want, "the P rows")

	local r = 0

	for _, row in ipairs(N.SCREENS) do
		if row.tag == "R" then
			r = r + 1
		end
	end

	lu.assertEquals(r, 52, "reconstructed (R) screens")
end

-- AC-6, I-12 (the oracle itself): the routes of Appendix A: every route from a brief or trained screen ends on a grant of ITS mission; counts of FN / Data mapping 4
function TestSmugglerT4Oracle2:test_the_appendix_a_routes_end_on_grants_of_their_mission()
	local adj = adjacencyOfRows()
	local mission = {}

	for screen, n in pairs(N.START_SCREENS) do
		mission[screen] = n
	end

	local cases = {
		{ "m1_brief", 1, 20 }, { "m1_trained_starships", 1, 20 }, { "m1_trained_weapons", 1, 20 }, { "m1_trained_procedures", 1, 20 }, { "m1_trained_droid", 1, 20 },
		{ "m2_brief", 2, 3 }, { "m2_brief_trained", 2, 1 }, { "m3_brief", 3, 3 }, { "m4_brief", 4, 4 }, { "m4_brief_trained", 4, 2 },
	}

	for _, c in ipairs(cases) do
		local count, reached, cyclic = routes(adj, mission, c[1])

		lu.assertFalse(cyclic, c[1] .. ": a route has a cycle")
		lu.assertEquals(count, c[3], c[1] .. ": routes")

		for id in pairs(reached) do
			lu.assertEquals(mission[id], c[2], c[1] .. ": route ends on '" .. id .. "', which is not a grant of mission " .. c[2])
		end
	end
end

-- AC-6, I-12 (the oracle itself): the only cycle is the duty menu's "explain again" loop
function TestSmugglerT4Oracle2:test_the_only_cycle_of_appendix_a_is_the_duty_explain_loop()
	lu.assertEquals(cycles(adjacencyOfRows()), { { "duty_escort_info", "duty_explain", "duty_freighter_info", "duty_menu" } }, "strongly connected screen groups")
end

---------------------------------------------------------------------------------------------
-- The template
---------------------------------------------------------------------------------------------

TestSmugglerT4Template = {}

function TestSmugglerT4Template:setUp()
	H.reset()
	N.requireConversation(lu)
end

-- AC-6, I-8
function TestSmugglerT4Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, N.screenIds(), N.TEMPLATE .. ": screen ids (135, no duplicates)")
end

-- AC-6, I-8: dialog, end flag, animation per screen
function TestSmugglerT4Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(N.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, N.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation, row.stop and "true" or "false", "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-11)")
	end
end

-- AC-6, I-8: the static options in order (ready_train has none: C-1)
function TestSmugglerT4Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(N.SCREENS) do
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

	lu.assertEquals(#byId.ready_train.options, 0, "ready_train: options = {} (C-1)")
end

-- AC-6, I-8
function TestSmugglerT4Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(N.TEMPLATE), {}, N.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestSmugglerT4Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, N.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the first line is the header comment; the file registers the template
function TestSmugglerT4Template:test_the_template_file_starts_with_the_header_comment_and_registers_through_add_conversation_template()
	local source = readFile(N.TEMPLATE_FILE)
	local first = source:match("^([^\n]*)")

	lu.assertEquals(first, "-- Nirame Sakute (Smuggler tier 4, Dathomir Trade Outpost) conversation screens; ported from SWG-Source tatooine_privateer_tier4 "
		.. "(STF conversation/tatooine_privateer_tier4). Handler: nirameSakuteConvoHandler.lua (feature smuggler-tier4-nirame).", "the header line")
	lu.assertNotNil(source:find('addConversationTemplate("nirame_sakute_convo_template", nirame_sakute_convo_template)', 1, true), "addConversationTemplate call")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog and option lines
function TestSmugglerT4Template:test_every_dialog_and_option_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(N.TEMPLATE_FILE)
	local dialogs, replies = 0, 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_privateer_tier4:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			dialogs = dialogs + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_privateer_tier4", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end

		local osid, ocomment = line:match('{%s*"@conversation/tatooine_privateer_tier4:(s_[%w_]+)"%s*,[^}]*}%s*,?%s*%-%-%s*(.-)%s*$')

		if osid ~= nil then
			replies = replies + 1
			lu.assertEquals(ocomment, (TEXT[osid]:gsub("%s+$", "")), "trailing comment of the option line for " .. osid)
		elseif line:find('{%s*"@conversation/tatooine_privateer_tier4') then
			lu.fail("option line without the trailing client text: " .. line)
		end
	end

	local want = 0

	for _, row in ipairs(N.SCREENS) do
		want = want + #row.options
	end

	lu.assertEquals(dialogs, 135, "leftDialog lines with a comment")
	lu.assertEquals(replies, want, "option lines with a comment")
end

-- Content contract 3: complete literals, one per leftDialog and static option
function TestSmugglerT4Template:test_every_id_is_a_complete_string_literal()
	local source = readFile(N.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/tatooine_privateer_tier4:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(N.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/tatooine_privateer_tier4:s_... literals in the template (one per leftDialog and static option)")
end

-- AC-6, I-12: the production template has the routes of Appendix A: the same route counts, every route ends on a grant of its mission
function TestSmugglerT4Template:test_the_production_routes_end_on_grants_of_their_mission_with_no_cycle()
	local adj = adjacencyOfTemplate()
	local cases = {
		{ "m1_brief", 1, 20 }, { "m1_trained_starships", 1, 20 }, { "m1_trained_weapons", 1, 20 }, { "m1_trained_procedures", 1, 20 }, { "m1_trained_droid", 1, 20 },
		{ "m2_brief", 2, 3 }, { "m2_brief_trained", 2, 1 }, { "m3_brief", 3, 3 }, { "m4_brief", 4, 4 }, { "m4_brief_trained", 4, 2 },
	}

	for _, c in ipairs(cases) do
		local count, reached, cyclic = routes(adj, N.START_SCREENS, c[1])

		lu.assertFalse(cyclic, c[1] .. ": a route has a cycle")
		lu.assertEquals(count, c[3], c[1] .. ": routes")

		for id in pairs(reached) do
			lu.assertEquals(N.START_SCREENS[id], c[2], c[1] .. ": route ends on '" .. id .. "', which is not a grant of mission " .. c[2])
		end
	end

	lu.assertEquals(cycles(adj), { { "duty_escort_info", "duty_explain", "duty_freighter_info", "duty_menu" } }, "the only cycle of the template is the duty menu's explain loop")
end

-- AC-6, I-12: a grant screen ends the conversation; the 14 START_SCREENS are exactly the grant screens of Appendix A
function TestSmugglerT4Template:test_the_grant_screens_end_the_conversation_and_are_the_14_start_screens()
	local byId = screensById()
	local seen = 0

	for _, row in ipairs(N.SCREENS) do
		local n = row.action:match("^start (%d)$")

		if n ~= nil then
			seen = seen + 1
			lu.assertEquals(N.START_SCREENS[row.id], tonumber(n), "screen '" .. row.id .. "' is a START_SCREEN of mission " .. n)
			lu.assertEquals(byId[row.id].stopConversation, "true", "screen '" .. row.id .. "' ends the conversation")
		end
	end

	lu.assertEquals(seen, 14, "Appendix A rows with 'start n'")
end

-- AC-6: no brief screen but the grants carries an action; the reward screens pay on display and the trained screens carry no animation
function TestSmugglerT4Template:test_the_reconstructed_screens_have_no_animation()
	local byId = screensById()

	for _, row in ipairs(N.SCREENS) do
		if row.tag == "R" then
			lu.assertEquals(byId[row.id].animation or "", "", "screen '" .. row.id .. "': reconstructed screens have no animation (D-11)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-6)
---------------------------------------------------------------------------------------------

TestSmugglerT4ClientStrings = {}

function TestSmugglerT4ClientStrings:setUp()
	H.reset()
	N.requireConversation(lu)
end

-- AC-6, I-8: no id the pre-NGE client lacks (in particular no NGE decimal id)
function TestSmugglerT4ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-6, I-8: the port uses all 245 client lines and no other id
function TestSmugglerT4ClientStrings:test_the_two_sources_use_every_client_line_of_the_file_and_no_decimal_id()
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == N.STF then
			used[lit.id] = true
		end
	end

	local got = {}

	for id in pairs(used) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, stfIds(), "distinct tatooine_privateer_tier4 ids used by the template and handler (exactly the 245 client lines)")
end

-- AC-6: complete literals only
function TestSmugglerT4ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Nirame sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-6: the handler names the topic replies and the two conditional replies as complete literals (Content contract 3)
function TestSmugglerT4ClientStrings:test_the_handler_names_the_topics_and_the_conditional_replies_as_complete_literals()
	local source = readFile(N.HANDLER_FILE)

	for _, t in ipairs(N.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "nirameSakuteConvoHandler.lua: complete literal for the " .. t.x .. " topic " .. t.reply)
	end

	for _, sid in ipairs({ "s_c1ff5062", "s_8be640b8" }) do
		lu.assertNotNil(source:find('"' .. PREFIX .. sid .. '"', 1, true), "nirameSakuteConvoHandler.lua: complete literal for the conditional reply " .. sid)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "nirameSakuteConvoHandler.lua: no stringFile prefix local")
end

-- AC-6: the ratchet counts the new fixture (the 54th entry) and leaves no gap
function TestSmugglerT4ClientStrings:test_the_ratchet_lists_the_fixture_and_has_no_known_gap()
	local R = require("space_convo_client_strings_data")

	lu.assertEquals(R.FIXTURE_COUNTS["conversation/tatooine_privateer_tier4"], 247, "FIXTURE_COUNTS entry")
	lu.assertEquals(R.KNOWN_GAPS, {}, "KNOWN_GAPS stays empty")
end

---------------------------------------------------------------------------------------------
-- The %TU lines
---------------------------------------------------------------------------------------------

TestSmugglerT4Names = {}

function TestSmugglerT4Names:setUp()
	H.reset()
	N.requireConversation(lu)
end

-- AC-6 (Content contract 3): the four lines with %TU get the pilot's first name
function TestSmugglerT4Names:test_the_four_name_token_screens_get_the_first_name()
	local all4 = { 1, 2, 3, 4 }

	N.spyStarts() -- duty_escort starts a duty on display

	for _, id in ipairs({ "duty_escort", "m1_smell", "transfer_where" }) do
		local t = N.drive(N.pilot({ t4 = all4, paid = all4 }), id)

		lu.assertEquals(t[1].params.TU, "Ace", "screen '" .. id .. "': the %TU parameter")
	end

	local t = N.drive(N.pilot({ mission = { [3] = "won" } }), "m3_reward")

	lu.assertEquals(t[1].params.TU, "Ace", "screen 'm3_reward': the %TU parameter")
end
