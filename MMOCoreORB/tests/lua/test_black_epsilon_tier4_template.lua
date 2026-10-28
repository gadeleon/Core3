-- Nin Gursawe: the conversation template (Appendix A), its client strings and the briefing routes.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-5, invariants I-8 and I-12; Content contract 3; Data mapping 3 and 4; Appendix A and C).
--
-- Answer keys: black_epsilon_tier4_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of
-- fixtures/script/conversation/corellia_imperial_tier4.java (harness/swgjava.lua) for every link of a row that is not a placement or a
-- reconstruction, and the generated client id list fixtures/string/en/conversation/corellia_imperial_tier4.sids.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")
local TEXT = require("black_epsilon_tier4_client_text")
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

-- the three STF lines the port leaves unused (D-7)
local UNUSED = { "s_361de446", "s_5f1f6bbe", "s_dd67013" }

TestBlackEpsilonT4Oracle = {}

function TestBlackEpsilonT4Oracle:setUp() H.reset() end

-- AC-5 (the oracle itself): Appendix A has 158 screens, ids unique, and with the four topic replies it uses 302 client lines, all but three
function TestBlackEpsilonT4Oracle:test_appendix_a_has_158_screens_and_uses_302_of_the_307_client_entries()
	lu.assertEquals(#T.SCREENS, 158, "Appendix A rows")

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
	lu.assertEquals(missing, UNUSED, "client lines Appendix A never uses (D-7)")
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(n, 302, "distinct client lines used")
end

-- AC-5 (the oracle itself): every link of Appendix A resolves, every screen is reachable (statically or by C-1..C-3), 24 start screens, 4 reward screens
function TestBlackEpsilonT4Oracle:test_appendix_a_links_resolve_and_every_screen_is_reachable()
	local rows = {}

	for _, row in ipairs(T.SCREENS) do
		rows[row.id] = row
	end

	local roots = { "not_pilot", "wrong_faction", "wanted", "off_track", "not_ready", "on_mission", "intro", "ready", "ready_train", "expecting", "tier4_incomplete", "transfer",
		"here_for_work", "off_track_duties", "off_track_no_duty", "m1_brief", "m2_brief", "m3_brief", "m4_brief", "m1_brief_trained", "m2_brief_trained", "m4_brief_trained" }

	for n = 1, 4 do
		roots[#roots + 1] = T.MISSIONS[n].failed
		roots[#roots + 1] = T.MISSIONS[n].reward
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

	for _, row in ipairs(T.SCREENS) do
		if not reached[row.id] then
			unreached[#unreached + 1] = row.id
		end
	end

	lu.assertEquals(unreached, {}, "Appendix A screens no route reaches")

	local starts, rewards = 0, 0

	for _, row in ipairs(T.SCREENS) do
		if row.action:match("^start %d$") then
			starts = starts + 1
		elseif row.action:match("^pay %d$") then
			rewards = rewards + 1
		end
	end

	lu.assertEquals({ starts, rewards }, { 24, 4 }, "start screens (8 + 9 + 3 + 4), reward screens")
	lu.assertEquals(#T.PATHS, 17, "Appendix D grant paths from the briefs (6 + 7 + 1 + 3)")
end

-- AC-5 (the oracle itself): the generated client id list holds the 307 entries the spec names
function TestBlackEpsilonT4Oracle:test_the_client_id_fixture_holds_307_ids()
	local n = 0

	for _ in pairs(CS.sids(T.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 307, "ids in fixtures/string/en/" .. T.STF .. ".sids")
end

-- AC-5 (the oracle itself): the exact client text of the topic and placed answer lines (FN-1, Data mapping 3), so a wrong sid fails with the words
function TestBlackEpsilonT4Oracle:test_the_topic_and_placed_pre_nge_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_c17d1a82, "I would like to learn about experimental TIE vessels.", "starships topic")
	lu.assertEquals(TEXT.s_6560cc1a, "I would like to learn about heavy starship components.", "weapons topic")
	lu.assertEquals(TEXT.s_bfe54df0, "I would like elite TIE guard training.", "procedures topic")
	lu.assertEquals(TEXT.s_588da3c3, "I would like to learn about droid intelligence theory.", "droid topic")
	lu.assertEquals(TEXT.s_83502a2, "The enemy of the Emperor must be destroyed!", "m4_failed reply (J s_49)")
	lu.assertEquals(TEXT.s_c1ece7d0, "Yes, Lord Insurgent. I will not fail you.", "m4_failed_succeed reply (J s_52)")
	lu.assertEquals(TEXT.s_37e2608d, "I do not fear danger.", "m4_failed_guts reply (J s_59)")
	lu.assertNotNil(TEXT.s_8ba804b8:find("Very well; here is your skill", 1, true), "m2_brief_trained: the skill acknowledgement")
end

-- AC-5 (the oracle itself): the %NU / %TU tokens: only s_b66c783f and s_81b729d2 use %TU, the lines with a name use %NU (R-6)
function TestBlackEpsilonT4Oracle:test_only_two_lines_carry_tu_and_the_intro_line_carries_nu()
	local tu = {}

	for sid, text in pairs(TEXT) do
		if text:find("%TU", 1, true) then
			tu[#tu + 1] = sid
		end
	end

	table.sort(tu)
	lu.assertEquals(tu, { "s_81b729d2", "s_b66c783f" }, "client lines with %TU")
	lu.assertNotNil(TEXT.s_735e94f9:find("%NU", 1, true), "intro line has %NU")
end

TestBlackEpsilonT4Template = {}

function TestBlackEpsilonT4Template:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8
function TestBlackEpsilonT4Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)
	lu.assertEquals(got, T.screenIds(), T.TEMPLATE .. ": screen ids (158, no duplicates)")
end

-- AC-5, I-8: dialog, end flag, animation per screen
function TestBlackEpsilonT4Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(T.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, T.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-13; none on reconstructed screens)")
	end
end

-- AC-5, I-8: the static options in order (ready_train's are built at run time and have none in the template)
function TestBlackEpsilonT4Template:test_every_screen_has_the_static_options_of_its_row_in_order()
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
function TestBlackEpsilonT4Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(T.TEMPLATE), {}, T.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 3: the template shape
function TestBlackEpsilonT4Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, T.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 3: the English text of every line is a trailing comment on the leftDialog line
function TestBlackEpsilonT4Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(T.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/corellia_imperial_tier4:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/corellia_imperial_tier4", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 158, "leftDialog lines with a comment")
end

-- Content contract 3: option ids are complete literals, one per static link
function TestBlackEpsilonT4Template:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(T.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/corellia_imperial_tier4:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(T.SCREENS) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/corellia_imperial_tier4:s_... literals in the template (one per leftDialog and static option)")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-5)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4ClientStrings = {}

function TestBlackEpsilonT4ClientStrings:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5, I-8: no id the pre-NGE client lacks
function TestBlackEpsilonT4ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-5, I-8: the port uses 302 client lines and no other id; exactly the three D-7 lines stay unused
function TestBlackEpsilonT4ClientStrings:test_the_two_sources_use_302_client_lines_and_leave_only_the_three_unused_ones()
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
	lu.assertEquals(missing, UNUSED, "client lines of corellia_imperial_tier4 the template and handler never show (D-7)")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 302, "distinct ids used")
end

-- AC-5: complete literals only
function TestBlackEpsilonT4ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in the Nin Gursawe sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- AC-5: the handler names the four topic replies as complete literals (Content contract 3)
function TestBlackEpsilonT4ClientStrings:test_the_handler_names_the_four_topic_replies_as_complete_literals()
	local source = readFile(T.HANDLER_FILE)

	for _, t in ipairs(T.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "ninGursaweConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNil(source:find("local%s+stringFile%s*="), "ninGursaweConvoHandler.lua: no stringFile prefix local")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (AC-5)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_tier4.java")

function TestBlackEpsilonT4JavaGraph:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- the replies of J rows whose edge is not J's: the three NGE slots replaced (Data mapping 3), the five rejoined edges, the duty menu on here_for_work,
-- and the options of the four briefs (the briefings are reconstructed, Data mapping 4)
local NOT_J = {
	"m4_failed s_83502a2", "m4_failed_succeed s_c1ece7d0", "m4_failed_guts s_37e2608d",
	"m1_theories s_79d6c690", "m1_theories s_493aef07", "m2_better s_e3d62b89", "m3_reward s_14c473a", "m4_figured s_8778fe46",
	"here_for_work s_99bb69ca", "here_for_work s_4349156c", "here_for_work s_b881db2e", "here_for_work s_98338b18", "here_for_work s_49805f81",
	"m1_brief s_f1d64636", "m1_brief s_993596a8", "m1_brief s_b2f1386a", "m1_brief s_a476ea3d",
	"m2_brief s_596bf3ab", "m2_brief s_5a23ab6f", "m2_brief s_3bdff7cb",
	"m3_brief s_b4876691", "m3_brief s_dbfcbbf", "m3_brief s_3e9d32e0",
	"m4_brief s_fc7e0cf7", "m4_brief s_630c41d4", "m4_brief s_ea248fbf",
}

-- AC-5: every J-row screen ends exactly where the java ends, and every reply leads where the java leads, except the listed edges
function TestBlackEpsilonT4JavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script_except_the_listed_edges()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(T.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens, disagree = 0, 0, {}

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
	lu.assertEquals(screens, 95, "Appendix A screens built from J lines")
	lu.assertEquals(checked, 76, "original replies checked against the java")
end

-- AC-5: the template's J-row edges that are not J's are exactly the ones Data mapping 3 names, and each lands where the spec says
function TestBlackEpsilonT4JavaGraph:test_the_placed_replies_lead_where_data_mapping_3_says()
	local byId = screensById()

	local function link(screen, sid)
		for _, o in ipairs(byId[screen].options) do
			if o[1] == PREFIX .. sid then
				return o[2]
			end
		end
	end

	lu.assertEquals(link("m4_failed", "s_83502a2"), "m4_failed_succeed", "s_83502a2 on m4_failed")
	lu.assertEquals(link("m4_failed_succeed", "s_c1ece7d0"), "m4_retry", "s_c1ece7d0 on m4_failed_succeed")
	lu.assertEquals(link("m4_failed_guts", "s_37e2608d"), "m4_retry", "s_37e2608d on m4_failed_guts (J's salute1 grant line moves with the rejoin)")
	lu.assertEquals(link("m1_theories", "s_79d6c690"), "m1_origin", "s_79d6c690")
	lu.assertEquals(link("m1_theories", "s_493aef07"), "m1_direction", "s_493aef07")
	lu.assertEquals(link("m2_better", "s_e3d62b89"), "m2_standby", "s_e3d62b89")
	lu.assertEquals(link("m3_reward", "s_14c473a"), "m3_decoding", "s_14c473a")
	lu.assertEquals(link("m4_figured", "s_8778fe46"), "m4_goodbye", "s_8778fe46")

	for _, d in ipairs(T.DUTY_MENU) do
		lu.assertEquals(link("here_for_work", d.reply), d.screen, "here_for_work duty menu: " .. d.reply)
	end

	lu.assertEquals(link("here_for_work", T.BRIEFING_AGAIN_REPLY), "briefing", "here_for_work: the briefing again")
end

---------------------------------------------------------------------------------------------
-- The briefing routes (I-12): a walk of the loaded template, not a conversation per path
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Routes = {}

function TestBlackEpsilonT4Routes:setUp()
	H.reset()
	T.requireConversation(lu)
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

-- Visits everything reachable from `from`: returns { reached = set, ends = set of option-less screens, cycle = a screen on a cycle or nil, paths = option paths }
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

local function starts(g)
	local out = {}

	for id, n in pairs(T.STARTS) do
		out[id] = n
	end

	return out
end

-- AC-5, I-12: from every brief, every option path ends on a grant screen of that brief's mission, and no route reaches another grant or a reward
function TestBlackEpsilonT4Routes:test_every_route_from_a_brief_ends_on_a_grant_of_its_own_mission_and_reaches_no_other_grant_or_reward()
	local g = graph()
	local startOf = starts(g)
	local rewardOf = {}

	for _, m in ipairs(T.MISSIONS) do
		rewardOf[m.reward] = true
	end

	for _, m in ipairs(T.MISSIONS) do
		for _, brief in ipairs(m.briefTrained == m.brief and { m.brief } or { m.brief, m.briefTrained }) do
			local w = walk(g, brief)

			for id in pairs(w.ends) do
				lu.assertEquals(startOf[id], m.n, brief .. ": the route ends on '" .. id .. "', which is not a grant of mission " .. m.n)
				lu.assertTrue(g[id].stop, brief .. ": the grant '" .. id .. "' ends the conversation")
			end

			for id in pairs(w.reached) do
				lu.assertTrue(startOf[id] == nil or startOf[id] == m.n, brief .. ": reaches the grant '" .. id .. "' of another mission")
				lu.assertNil(rewardOf[id], brief .. ": reaches the reward screen '" .. id .. "'")
			end
		end
	end
end

-- AC-5, I-12: no reconstructed screen is on a cycle, and the routes from the briefs are finite
function TestBlackEpsilonT4Routes:test_no_route_from_a_brief_has_a_cycle()
	local g = graph()

	for _, m in ipairs(T.MISSIONS) do
		lu.assertNil(walk(g, m.brief).cycle, m.brief .. ": a cycle through this screen")
		lu.assertNil(walk(g, m.briefTrained).cycle, m.briefTrained .. ": a cycle through this screen")
	end
end

-- AC-5, I-12: the grants reachable from the briefs are the accept screens (6 + 7 + 1 + 3 = 17), every one of them reachable, and the retries are not
function TestBlackEpsilonT4Routes:test_the_briefs_reach_exactly_the_accept_screens_of_their_mission()
	local g = graph()
	local want = { [1] = 6, [2] = 7, [3] = 1, [4] = 3 }

	for _, m in ipairs(T.MISSIONS) do
		local w = walk(g, m.brief)
		local grants = {}

		for id in pairs(w.ends) do
			grants[#grants + 1] = id
		end

		table.sort(grants)

		local expected = {}

		for id, n in pairs(T.STARTS) do
			if n == m.n and not id:find("retry", 1, true) then
				expected[#expected + 1] = id
			end
		end

		table.sort(expected)
		lu.assertEquals(grants, expected, m.brief .. ": grant screens reached")
		lu.assertEquals(#grants, want[m.n], m.brief .. ": grant screens of mission " .. m.n)
	end
end

-- AC-5, I-12: the post-training briefs lead to the same routes as the plain briefs (M1, M2, M4; M3 has no variant, D-6)
function TestBlackEpsilonT4Routes:test_the_post_training_briefs_have_the_options_of_the_plain_briefs()
	local byId = screensById()

	for _, n in ipairs({ 1, 2, 4 }) do
		local m = T.MISSIONS[n]
		local a, b = byId[m.brief].options, byId[m.briefTrained].options

		lu.assertEquals(#a, #b, m.briefTrained .. ": option count")

		for i = 1, #a do
			lu.assertEquals({ b[i][1], b[i][2] }, { a[i][1], a[i][2] }, m.briefTrained .. ": option " .. i)
		end
	end

	lu.assertEquals(T.MISSIONS[3].briefTrained, "m3_brief", "mission 3's post-training brief is m3_brief itself (D-6)")
end

-- AC-5: the spec's own count: mission 3's brief has 1080 option paths (the spec calls for a table walk, not a conversation per path)
function TestBlackEpsilonT4Routes:test_mission_3_has_1080_option_paths_from_its_brief()
	lu.assertEquals(walk(graph(), "m3_brief").total, 1080, "option paths from m3_brief")
end

-- AC-5: the failure dialogues: every route from a failure line reaches a retry of its mission
function TestBlackEpsilonT4Routes:test_every_route_from_a_failure_line_ends_on_a_retry_of_its_mission()
	local g = graph()

	for _, m in ipairs(T.MISSIONS) do
		local w = walk(g, m.failed)

		lu.assertNil(w.cycle, m.failed .. ": a cycle")

		for id in pairs(w.ends) do
			lu.assertEquals(T.STARTS[id], m.n, m.failed .. ": the route ends on '" .. id .. "', which is not a retry of mission " .. m.n)
			lu.assertTrue(id:find("retry", 1, true) ~= nil, m.failed .. ": '" .. id .. "' is a retry screen")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The name tokens
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Names = {}

function TestBlackEpsilonT4Names:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- AC-5 (Content contract 3): the handler fills the participant token with the pilot's first name on every screen
function TestBlackEpsilonT4Names:test_every_screen_gets_the_first_name_in_the_tu_parameter()
	local spies = T.spyStarts()
	local bad = {}

	for _, row in ipairs(T.SCREENS) do
		local t = T.drive(T.pilot({ xp = T.TRAIN_COST }), row.id)

		if t[1].params == nil or t[1].params.TU ~= "Ace" then
			bad[#bad + 1] = row.id
		end
	end

	lu.assertEquals(bad, {}, "screens whose %TU parameter is not the pilot's first name (setDialogTextTU on every screen)")
	lu.assertTrue(#T.started(spies) > 0, "precondition: the start screens ran")
end
