-- Ja'ce Yiaso: the conversation template (Appendix A), its client strings and the briefing routes.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-5, invariants I-8 and I-12; Content contract 3; Data mapping 3 and 4; Appendix A and E).
--
-- Answer keys: inquisition_tier4_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/naboo_imperial_tier4.java (harness/swgjava.lua) for every link of a row that is not a placement or a
-- reconstruction, and the generated client id list fixtures/string/en/conversation/naboo_imperial_tier4.sids (279 ids, patch_12_00.tre).

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")
local TEXT = require("inquisition_tier4_client_text")
local Swgjava = require("harness.swgjava")

J4.load()

local PATHS = { J4.TEMPLATE_FILE, J4.HANDLER_FILE }
local PREFIX = J4.PREFIX

local function template() return H.conversationTemplateTable(J4.TEMPLATE) end

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

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestInquisitionT4Oracle = {}

function TestInquisitionT4Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 150 screens, ids unique, and with the topic replies it uses all 277 client lines and no other id
function TestInquisitionT4Oracle:test_appendix_a_has_150_screens_and_uses_exactly_the_277_client_lines()
	lu.assertEquals(#J4.SCREENS, 150, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(J4.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local n, missing, unused = 0, {}, {}

	for id in pairs(used) do
		n = n + 1

		if TEXT[id] == nil then
			missing[#missing + 1] = id
		end
	end

	for id in pairs(TEXT) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			unused[#unused + 1] = id
		end
	end

	table.sort(missing)
	table.sort(unused)
	lu.assertEquals(missing, {}, "Appendix A ids that are not client lines")
	lu.assertEquals(unused, {}, "client lines Appendix A never uses (D-7: none stays unused)")
	lu.assertEquals(n, 277, "distinct ids used")
end

-- AC-5 (the oracle itself): links resolve and every screen is reachable from a gate screen
function TestInquisitionT4Oracle:test_appendix_a_links_resolve_and_every_screen_is_reachable()
	local rows = {}

	for _, row in ipairs(J4.SCREENS) do
		rows[row.id] = row
	end

	-- the gate screens, plus the targets the handler picks at run time (C-1 .. C-3: off_track_refused, the briefs and trained openings of missions 2 to 4)
	local roots = { "not_pilot", "wrong_faction", "wanted", "off_track", "not_ready", "on_mission", "intro", "ready", "ready_train", "tier4_incomplete", "transfer", "here_for_work",
		"off_track_refused", "m1_brief", "m2_brief", "m3_brief", "m4_brief", "m1_brief_trained", "m2_brief_trained", "m3_brief_trained", "m4_brief_trained" }

	for n = 1, 4 do
		roots[#roots + 1] = J4.MISSIONS[n].failed
		roots[#roots + 1] = J4.MISSIONS[n].reward
	end

	local reached, queue = {}, {}

	for _, id in ipairs(roots) do
		lu.assertNotNil(rows[id], "root screen " .. id .. " is in Appendix A")
		reached[id] = true
		queue[#queue + 1] = id
	end

	while #queue > 0 do
		local id = table.remove(queue)

		for _, o in ipairs(rows[id].options) do
			lu.assertNotNil(rows[o[2]], "screen '" .. id .. "', reply " .. o[1] .. ": the link '" .. o[2] .. "' is in Appendix A")

			if not reached[o[2]] then
				reached[o[2]] = true
				queue[#queue + 1] = o[2]
			end
		end
	end

	local unreached = {}

	for _, row in ipairs(J4.SCREENS) do
		if not reached[row.id] then
			unreached[#unreached + 1] = row.id
		end
	end

	lu.assertEquals(unreached, {}, "Appendix A screens no route reaches from a gate screen")

	local starts, pays = 0, 0

	for _ in pairs(J4.STARTS) do
		starts = starts + 1
	end

	for _ in pairs(J4.PAYS) do
		pays = pays + 1
	end

	lu.assertEquals({ starts, pays }, { 26, 10 }, "start screens (8 retries + 9 + 2 + 3 + 4 grants), pay screens (5 + 1 + 1 + 3)")
	lu.assertEquals(#J4.PATHS, 36, "Appendix D paths (26 start + 10 pay)")
end

-- AC-5 (the oracle itself): the generated client id list holds the 279 entries the spec names
function TestInquisitionT4Oracle:test_the_client_id_fixture_holds_279_ids()
	local n = 0

	for _ in pairs(CS.sids(J4.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 279, "ids in fixtures/string/en/" .. J4.STF .. ".sids (277 lines + do_not_edit + s_0)")
	lu.assertEquals(CS.sids(J4.STF).do_not_edit, true, "do_not_edit")
	lu.assertEquals(CS.sids(J4.STF).s_0, true, "s_0")
end

-- AC-5 (the oracle itself): the training topics and the placed pre-NGE lines are the words of the client (Data mapping 3)
function TestInquisitionT4Oracle:test_the_topic_and_placed_pre_nge_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_d8355c02, "I'll take experimental TIE vessels.", "starships_04 topic")
	lu.assertEquals(TEXT.s_96a0374a, "I'll take heavy starship component use.", "weapons_04 topic")
	lu.assertEquals(TEXT.s_d8efd03b, "I'll take elite TIE guard training.", "procedures_04 topic")
	lu.assertEquals(TEXT.s_7e1308bc, "I'll take droid intelligence theory.", "droid_04 topic")
	lu.assertEquals(TEXT.s_a3958e6a, "Ready to serve, sir.", "the reply that fills J's NGE s_277 on intro")
	lu.assertEquals(TEXT.s_b3a26c61, "I am ready to test out my new ability.", "the trained M1 reply")
	lu.assertEquals(TEXT.s_2a5728d1, "That joke, and I use that term loosely, was terrible.", "the trained M2 reply")
end

-- AC-5 (the oracle itself): the five name lines
function TestInquisitionT4Oracle:test_only_five_lines_carry_a_name_token()
	local with = {}

	for id, text in pairs(TEXT) do
		if text:find("%%[TN]U") then
			with[#with + 1] = id
		end
	end

	table.sort(with)
	lu.assertEquals(with, { "s_c2c13cf7", "s_c4f0640e", "s_cfb7c310", "s_e3ea301", "s_f82c2226" }, "client lines with %TU / %NU")
end

---------------------------------------------------------------------------------------------
-- The template (AC-5, I-8)
---------------------------------------------------------------------------------------------

TestInquisitionT4Template = {}

function TestInquisitionT4Template:setUp()
	H.reset()
	J4.requireConversation(lu)
end

-- AC-5, I-8
function TestInquisitionT4Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	local inOrder = {}

	for i, row in ipairs(J4.SCREENS) do
		inOrder[i] = row.id
	end

	lu.assertEquals(got, inOrder, J4.TEMPLATE .. ": screen ids, in Appendix A row order (150, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestInquisitionT4Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(J4.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, J4.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only from J; none on rebuilt screens, D-11)")
	end
end

-- AC-5, I-8: the static options in order (ready_train's four topics all link m1_brief_trained)
function TestInquisitionT4Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(J4.SCREENS) do
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
function TestInquisitionT4Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(J4.TEMPLATE), {}, J4.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape and the first line
function TestInquisitionT4Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, J4.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")

	local first = readFile(J4.TEMPLATE_FILE):match("^([^\n]*)")

	lu.assertEquals(first, "-- Grand Inquisitor Ja'ce Yiaso (Inquisition tier 4, Emperor's Retreat) conversation screens; ported from SWG-Source naboo_imperial_tier4 (STF conversation/naboo_imperial_tier4). Handler: jaceYiasoConvoHandler.lua (feature inquisition-tier4-jace-yiaso).",
		"line 1 of the template")
	lu.assertNotNil(readFile(J4.TEMPLATE_FILE):find('addConversationTemplate("jace_yiaso_convo_template", jace_yiaso_convo_template)', 1, true), "addConversationTemplate line")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestInquisitionT4Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(J4.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/naboo_imperial_tier4:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/naboo_imperial_tier4", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 150, "leftDialog lines with a comment")
end

-- Content contract 3: option ids are complete literals, one per static link
function TestInquisitionT4Template:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(J4.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/naboo_imperial_tier4:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(J4.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/naboo_imperial_tier4:s_... literals in the template (one per leftDialog and static option)")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5, I-8)
---------------------------------------------------------------------------------------------

TestInquisitionT4ClientStrings = {}

function TestInquisitionT4ClientStrings:setUp()
	H.reset()
	J4.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestInquisitionT4ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: the two sources use all 277 client lines and no NGE editor number (s_277 ... s_578)
function TestInquisitionT4ClientStrings:test_the_two_sources_use_exactly_the_277_client_lines()
	local ids = CS.sids(J4.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == J4.STF then
			used[lit.id] = true
			lu.assertNil(lit.id:match("^s_%d%d?%d?%d?$"), "NGE editor id " .. lit.id .. " at " .. lit.path .. ":" .. lit.line)
		end
	end

	local missing = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of naboo_imperial_tier4 the template and handler never show (D-7)")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 277, "distinct ids used")
end

-- AC-5: complete literals only
function TestInquisitionT4ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Ja'ce's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the handler names the four topic replies, the off-track reply and the ready reply as complete literals (Content contract 3, Conversation flow 2)
function TestInquisitionT4ClientStrings:test_the_handler_names_the_conditional_replies_as_complete_literals()
	local source = readFile(J4.HANDLER_FILE)

	for _, t in ipairs(J4.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "jaceYiasoConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. J4.OFF_TRACK_REPLY .. '"', 1, true), "jaceYiasoConvoHandler.lua: complete literal for the off-track reply")
	lu.assertNotNil(source:find('"' .. PREFIX .. J4.READY_REPLY .. '"', 1, true), "jaceYiasoConvoHandler.lua: complete literal for the ready reply")
	lu.assertNil(source:find("local%s+stringFile%s*="), "jaceYiasoConvoHandler.lua: no stringFile prefix local")
	lu.assertEquals(source:match("^([^\n]*)"), "-- Grand Inquisitor Ja'ce Yiaso (Inquisition tier 4) conversation handler; ported from SWG-Source naboo_imperial_tier4.java. One-click, free-choice training bought with XP, the grounded gate, duties and the hand-off to Grand Admiral Declann: pre-NGE client lines (feature inquisition-tier4-jace-yiaso).",
		"line 1 of the handler")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (AC-5)
---------------------------------------------------------------------------------------------

TestInquisitionT4JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_imperial_tier4.java")

function TestInquisitionT4JavaGraph:setUp()
	H.reset()
	J4.requireConversation(lu)
end

-- the replies of J-row screens whose edge is not J's: the intro reply (NGE s_277, Data mapping 3), the four topics (NGE training chain), and the replies
-- of the four briefs (the briefings are rebuilt, Data mapping 4)
local NOT_J = {
	"intro s_a3958e6a",
	"ready_train s_d8355c02", "ready_train s_96a0374a", "ready_train s_d8efd03b", "ready_train s_7e1308bc",
	"m1_brief s_a3958e6a", "m1_brief s_adb2030c", "m1_brief s_c4bc5314",
	"m2_brief s_ed8a35fe", "m2_brief s_c6f1b86f",
	"m3_brief s_231ed37", "m3_brief s_e977b428", "m3_brief s_6c2a8e60",
	"m4_brief s_898acaac", "m4_brief s_f7053b89", "m4_brief s_a6ef12b5",
}

-- AC-5: every J-row screen ends exactly where the java ends, and every reply leads where the java leads, except the listed edges
function TestInquisitionT4JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script_except_the_listed_edges()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(J4.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens, disagree = 0, 0, {}

	for _, row in ipairs(J4.SCREENS) do
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
				local ok = false

				if have[o[1]] then
					for _, succ in ipairs(GRAPH.successorsOf(row.sid, o[1]) or {}) do
						if succ == dialogOf[o[2]] then
							ok = true
						end
					end
				end

				if ok then
					checked = checked + 1
				else
					disagree[#disagree + 1] = row.id .. " " .. o[1]
				end
			end
		end
	end

	local want = {}

	for i, x in ipairs(NOT_J) do
		want[i] = x
	end

	table.sort(want)
	table.sort(disagree)
	lu.assertEquals(disagree, want, "replies of J-row screens the java does not lead to the template's link")
	lu.assertEquals(screens, 90, "Appendix A screens built from J lines")
	lu.assertEquals(checked, 81, "original replies checked against the java")
end

-- AC-5, FJ-9: intro_briefing and duty_briefing carry the same line and link; only the first sets the key
function TestInquisitionT4JavaGraph:test_intro_briefing_and_duty_briefing_share_the_line_and_the_link()
	local byId = screensById()

	lu.assertEquals(byId.intro_briefing.leftDialog, PREFIX .. "s_85c9e37e", "intro_briefing line")
	lu.assertEquals(byId.duty_briefing.leftDialog, PREFIX .. "s_85c9e37e", "duty_briefing line")
	lu.assertEquals(byId.intro_briefing.options, byId.duty_briefing.options, "same options")
	lu.assertEquals(byId.duty_briefing.options[1][2], "duty_escort_info", "the briefing continues with the escort info")
end

---------------------------------------------------------------------------------------------
-- The routes (I-12): a walk of the loaded template, not a conversation per path
---------------------------------------------------------------------------------------------

TestInquisitionT4Routes = {}

function TestInquisitionT4Routes:setUp()
	H.reset()
	J4.requireConversation(lu)
end

-- link table of the loaded template: id -> { link, ... } (static options), and the screens' end flag
local function graph()
	local g = {}

	for id, s in pairs(screensById()) do
		g[id] = { links = {}, stop = s.stopConversation == "true" }

		for i, o in ipairs(s.options) do
			g[id].links[i] = o[2]
		end
	end

	return g
end

-- Visits everything reachable from `from`: reached set, option-less screens (ends), a screen on a cycle or nil, and the option path count
local function walk(g, from)
	local state, reached, ends, cycle, paths = {}, {}, {}, nil, {}

	local function visit(id)
		if state[id] == 2 then
			return paths[id]
		end

		if state[id] == 1 then
			cycle = cycle or id
			return 0
		end

		state[id] = 1
		reached[id] = true

		local node = g[id]
		local n = 0

		if node == nil or #node.links == 0 then
			ends[id] = true
			n = 1
		else
			for _, link in ipairs(node.links) do
				n = n + visit(link)
			end
		end

		state[id] = 2
		paths[id] = n
		return n
	end

	local total = visit(from)

	return { reached = reached, ends = ends, cycle = cycle, total = total }
end

-- AC-5, I-12: from every brief and trained opening, every option path ends on a grant of that mission; no route reaches another grant, a reward or a duty screen
function TestInquisitionT4Routes:test_every_route_from_a_brief_ends_on_a_grant_of_its_own_mission_and_reaches_nothing_else()
	local g = graph()
	local foreign = {}

	for id in pairs(J4.PAYS) do
		foreign[id] = true
	end

	for _, id in ipairs({ "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "m1_reward", "m2_reward", "m3_reward", "m4_reward" }) do
		foreign[id] = true
	end

	for _, m in ipairs(J4.MISSIONS) do
		for _, brief in ipairs({ m.brief, m.briefTrained }) do
			local w = walk(g, brief)

			lu.assertNil(w.cycle, brief .. ": a cycle through this screen")

			for id in pairs(w.ends) do
				lu.assertEquals(J4.STARTS[id], m.n, brief .. ": the route ends on '" .. id .. "', which is not a grant of mission " .. m.n)
				lu.assertTrue(g[id].stop, brief .. ": the grant '" .. id .. "' ends the conversation")
			end

			for id in pairs(w.reached) do
				lu.assertTrue(J4.STARTS[id] == nil or J4.STARTS[id] == m.n, brief .. ": reaches the grant '" .. id .. "' of another mission")
				lu.assertNil(foreign[id], brief .. ": reaches the reward or duty screen '" .. id .. "'")
			end
		end
	end
end

-- AC-5, I-12: the grants reachable from the briefs are the accept screens: 9, 2, 3, 4 (retries are not)
function TestInquisitionT4Routes:test_the_briefs_reach_exactly_the_accept_screens_of_their_mission()
	local g = graph()
	local want = { [1] = 9, [2] = 2, [3] = 3, [4] = 4 }

	for _, m in ipairs(J4.MISSIONS) do
		for _, brief in ipairs({ m.brief, m.briefTrained }) do
			local w = walk(g, brief)
			local grants = {}

			for id in pairs(w.ends) do
				grants[#grants + 1] = id
			end

			table.sort(grants)

			local expected = {}

			for id, n in pairs(J4.STARTS) do
				if n == m.n and not id:find("retry", 1, true) then
					expected[#expected + 1] = id
				end
			end

			table.sort(expected)
			lu.assertEquals(grants, expected, brief .. ": grant screens reached")
			lu.assertEquals(#grants, want[m.n], brief .. ": grant screens of mission " .. m.n)
		end
	end
end

-- AC-5: the spec's route counts (Data mapping 4: 49 / 12 and 30 / 14 / 6 option paths from each head)
function TestInquisitionT4Routes:test_the_heads_have_the_route_counts_of_data_mapping_4()
	local g = graph()

	lu.assertEquals({ walk(g, "m1_brief").total, walk(g, "m1_brief_trained").total }, { 49, 49 }, "mission 1: option paths from the head and the trained opening")
	lu.assertEquals({ walk(g, "m2_brief").total, walk(g, "m2_brief_trained").total }, { 12, 30 }, "mission 2: option paths (the trained opening adds the joke branch)")
	lu.assertEquals({ walk(g, "m3_brief").total, walk(g, "m3_brief_trained").total }, { 14, 14 }, "mission 3: option paths")
	lu.assertEquals({ walk(g, "m4_brief").total, walk(g, "m4_brief_trained").total }, { 6, 6 }, "mission 4: option paths")
end

-- AC-5, Data mapping 4: the trained openings carry the head replies, with the two named exceptions
function TestInquisitionT4Routes:test_the_trained_openings_carry_the_head_replies_with_the_two_exceptions()
	local byId = screensById()

	local function replies(id)
		local out = {}

		for i, o in ipairs(byId[id].options) do
			out[i] = o[1]:match(":(s_[%w_]+)$") .. ">" .. o[2]
		end

		return out
	end

	local m1, m1t = replies("m1_brief"), replies("m1_brief_trained")

	lu.assertEquals(m1t[1], "s_b3a26c61>m1_eager", "M1 trained: 'I am ready to test out my new ability.' replaces 'Ready to serve, sir.'")
	lu.assertEquals({ m1t[2], m1t[3] }, { m1[2], m1[3] }, "M1 trained: the other replies")
	lu.assertEquals(m1[1], "s_a3958e6a>m1_eager", "M1 head: 'Ready to serve, sir.'")

	local m2, m2t = replies("m2_brief"), replies("m2_brief_trained")

	lu.assertEquals({ m2t[1], m2t[2] }, { m2[1], m2[2] }, "M2 trained: the head replies")
	lu.assertEquals(m2t[3], "s_2a5728d1>m2_joviality", "M2 trained: the joke reply is added")

	for _, n in ipairs({ 3, 4 }) do
		lu.assertEquals(replies("m" .. n .. "_brief_trained"), replies("m" .. n .. "_brief"), "mission " .. n .. ": the trained opening has the head's replies")
	end
end

-- AC-5: the failure dialogues: every route from a failure line reaches a retry of its mission
function TestInquisitionT4Routes:test_every_route_from_a_failure_line_ends_on_a_retry_of_its_mission()
	local g = graph()

	for _, m in ipairs(J4.MISSIONS) do
		local w = walk(g, m.failed)

		lu.assertNil(w.cycle, m.failed .. ": a cycle")

		for id in pairs(w.ends) do
			lu.assertEquals(J4.STARTS[id], m.n, m.failed .. ": the route ends on '" .. id .. "', which is not a retry of mission " .. m.n)
			lu.assertTrue(id:find("retry", 1, true) ~= nil, m.failed .. ": '" .. id .. "' is a retry screen")
		end
	end
end

-- AC-5, I-12: every route from a reward screen reaches exactly one pay screen of its mission (M1, M4) or the screen pays on display (M2, M3)
function TestInquisitionT4Routes:test_every_route_from_a_reward_screen_reaches_one_pay_screen_of_its_mission()
	local g = graph()

	for _, n in ipairs({ 1, 4 }) do
		local m = J4.MISSIONS[n]
		local w = walk(g, m.reward)

		lu.assertNil(w.cycle, m.reward .. ": a cycle")

		for id in pairs(w.ends) do
			-- walk every route: count pay screens on it
			lu.assertTrue(g[id].stop, m.reward .. ": the route ends on '" .. id .. "', which ends the conversation")
		end

		local function pays(id, count)
			local c = count + (J4.PAYS[id] == n and 1 or 0)

			lu.assertTrue(J4.PAYS[id] == nil or J4.PAYS[id] == n, m.reward .. ": '" .. id .. "' pays another mission")
			lu.assertTrue(c <= 1, m.reward .. ": a route passes more than one pay screen (at '" .. id .. "')")

			if #g[id].links == 0 then
				lu.assertEquals(c, 1, m.reward .. ": the route ending on '" .. id .. "' passed exactly one pay screen")
			end

			for _, link in ipairs(g[id].links) do
				pays(link, c)
			end
		end

		pays(m.reward, 0)
	end

	lu.assertEquals(J4.PAYS.m2_reward, 2, "m2_reward pays on display")
	lu.assertEquals(J4.PAYS.m3_reward, 3, "m3_reward pays on display")
end

-- AC-5, I-12: the only cycle in the template is the duty briefing loop
function TestInquisitionT4Routes:test_the_only_cycle_is_the_duty_briefing_loop()
	local g = graph()
	local state, cyclic = {}, {}

	local function visit(id, stack)
		if state[id] == 2 then
			return
		end

		if state[id] == 1 then
			for i = #stack, 1, -1 do
				cyclic[stack[i]] = true

				if stack[i] == id then
					break
				end
			end

			return
		end

		state[id] = 1
		stack[#stack + 1] = id

		for _, link in ipairs(g[id].links) do
			visit(link, stack)
		end

		stack[#stack] = nil
		state[id] = 2
	end

	for id in pairs(g) do
		visit(id, {})
	end

	local got = {}

	for id in pairs(cyclic) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, { "duty_briefing", "duty_escort_info", "duty_recovery_info", "duty_rescue_info" }, "screens on a cycle (duty_briefing -> duty_escort_info -> duty_recovery_info -> duty_rescue_info -> duty_briefing)")
end

---------------------------------------------------------------------------------------------
-- The name tokens (AC-5)
---------------------------------------------------------------------------------------------

TestInquisitionT4Names = {}

function TestInquisitionT4Names:setUp()
	H.reset()
	J4.requireConversation(lu)
end

-- AC-5 (Content contract 3): the handler fills the participant token with the pilot's first name on the five name screens
function TestInquisitionT4Names:test_the_five_name_screens_get_the_first_name_in_the_tu_parameter()
	for _, id in ipairs({ "wanted", "m2_failed", "m4_reward_alone", "m1_accept_blessing", "m4_accept_blessing" }) do
		local t = J4.drive(J4.pilot({ xp = J4.TRAIN_COST }), id)

		lu.assertNotNil(t[1].params, id .. ": params")
		lu.assertEquals(t[1].params.TU, "Ace", id .. ": the %TU / %NU parameter is the pilot's first name")
	end
end
