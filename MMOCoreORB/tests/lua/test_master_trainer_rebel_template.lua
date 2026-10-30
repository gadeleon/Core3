-- Rebel master trainer: the conversation template (Appendix A), the client strings, the SWG java answer key and the routes.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (AC-4; invariants I-6 and I-9; Content contract 2; Data mapping "NGE slot"; Appendix A, B, D).
--
-- The oracle is Appendix A (master_trainer_rebel_screens_data.lua, generated from the spec table) and the client text of the 156 pre-NGE entries
-- (master_trainer_rebel_client_text.lua). The java answer key is read through harness/swgjava.lua.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")
local TEXT = require("master_trainer_rebel_client_text")
local Swgjava = require("harness.swgjava")

M.load()

local PATHS = { M.TEMPLATE_FILE, M.HANDLER_FILE }
local PREFIX = M.PREFIX

local function template() return H.conversationTemplateTable(M.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function readFile(path)
	local f = assert(io.open(H.SCRIPTS .. path, "r"), "cannot open bin/scripts/" .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- the gate screens of Gate table P: where every conversation starts
local GATE_SCREENS = {
	"default", "working_for_empire", "imperial_pilot", "rsf_pilot", "not_ready", "privateer_not_ready", "other_master", "master_done", "on_master_mission",
	"on_quest", "m2_failed", "m1_failed", "m2_won", "m1_won", "m2_brief", "intro", "privateer_ready",
}

TestMasterTrainerRebelOracle = {}

function TestMasterTrainerRebelOracle:setUp() H.reset() end

-- AC-4 (the oracle itself): 62 screens, unique ids; with the replies it uses 108 of the 154 client lines, Appendix B is the rest
function TestMasterTrainerRebelOracle:test_appendix_a_has_62_screens_and_uses_108_client_lines_leaving_exactly_appendix_b()
	lu.assertEquals(#M.SCREENS, 62, "Appendix A rows")

	local seen, used = {}, {}

	for _, row in ipairs(M.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
		end
	end

	local ids = CS.sids(M.STF)

	lu.assertNotNil(ids, "fixtures/string/en/" .. M.STF .. ".sids")

	local unused, extra, n = {}, {}, 0

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			unused[#unused + 1] = id
		end
	end

	for id in pairs(used) do
		n = n + 1

		if not ids[id] then
			extra[#extra + 1] = id
		end
	end

	table.sort(unused)
	table.sort(extra)
	lu.assertEquals(extra, {}, "Appendix A ids the client does not have")
	lu.assertEquals(n, 108, "distinct client lines used")
	lu.assertEquals(#M.UNUSED, 46, "Appendix B size")
	lu.assertEquals(unused, M.UNUSED, "client lines Appendix A never uses (Appendix B)")
end

-- AC-4 (the oracle itself): every link resolves, every screen is reachable from a gate screen
function TestMasterTrainerRebelOracle:test_appendix_a_links_resolve_and_every_screen_is_reachable_from_a_gate_screen()
	local reached, queue = {}, {}

	for _, id in ipairs(GATE_SCREENS) do
		lu.assertNotNil(M.ROWS[id], "gate screen " .. id .. " is in Appendix A")
		reached[id] = true
		queue[#queue + 1] = id
	end

	while #queue > 0 do
		local id = table.remove(queue)

		for _, o in ipairs(M.ROWS[id].options) do
			lu.assertNotNil(M.ROWS[o[2]], "screen '" .. id .. "', reply " .. o[1] .. ": the link '" .. o[2] .. "' is in Appendix A")

			if not reached[o[2]] then
				reached[o[2]] = true
				queue[#queue + 1] = o[2]
			end
		end
	end

	local unreached = {}

	for _, row in ipairs(M.SCREENS) do
		if not reached[row.id] then
			unreached[#unreached + 1] = row.id
		end
	end

	lu.assertEquals(unreached, {}, "Appendix A screens no route reaches")
end

-- AC-4 (the oracle itself): the generated client id list holds the 156 entries the spec names
function TestMasterTrainerRebelOracle:test_the_client_id_fixture_holds_156_ids()
	local n = 0

	for _ in pairs(CS.sids(M.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 156, "ids in fixtures/string/en/" .. M.STF .. ".sids")
end

-- AC-4 (the oracle itself): the client text of the lines the spec's NGE-slot decision and its notes rely on, so a wrong sid fails with the words
function TestMasterTrainerRebelOracle:test_the_slot_and_pool_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_44bd3318, "What is it you need me to do?", "intro_impression / intro_humor reply (the rejoin of the NGE slot s_559, D-15)")
	lu.assertEquals(TEXT.s_eb02d65, "I am a good pilot, sir.", "m2_failed reply")
	lu.assertEquals(TEXT.s_c788dadf, "No, sir. Of course not, sir.", "m1_failed_planning reply")
	lu.assertEquals(TEXT.s_87d4bfc2, "Crystal.", "m1_retry_b reply")
	lu.assertEquals(TEXT.s_1ffdcc4b, "Are we clear?", "m1_retry_b_clear")
	lu.assertEquals(TEXT.s_c13f9a11, "I am sorry, sir. Give me another chance. I will succeed.", "m2_failed_skills reply")
	lu.assertEquals(TEXT.s_0, "", "the empty entry")
end

TestMasterTrainerRebelTemplate = {}

function TestMasterTrainerRebelTemplate:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4, I-6
function TestMasterTrainerRebelTemplate:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)

	-- space-master-trainer-privateer: Appendix A plus Appendix P-B (28 screens)
	local want = M.screenIds()

	for _, row in ipairs(require("master_trainer_privateer_screens_data").burke) do
		want[#want + 1] = row.id
	end

	table.sort(want)
	lu.assertEquals(got, want, M.TEMPLATE .. ": screen ids (90, no duplicates)")
end

-- AC-4, I-6: dialog, end flag, animation per screen
function TestMasterTrainerRebelTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(M.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, M.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only, D-12; none where Appendix A shows a dash)")
	end
end

-- AC-4, I-6: the options in order
function TestMasterTrainerRebelTemplate:test_every_screen_has_the_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(M.SCREENS) do
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

-- AC-4, I-6
function TestMasterTrainerRebelTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(M.TEMPLATE), {}, M.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestMasterTrainerRebelTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, M.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestMasterTrainerRebelTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(M.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/rebel_master_trainer:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/rebel_master_trainer", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	-- space-master-trainer-privateer: Appendix A (62) plus Appendix P-B (28)
	lu.assertEquals(checked, 62 + #require("master_trainer_privateer_screens_data").burke, "leftDialog lines with a comment")
end

-- Content contract 2: option ids are complete literals, one per static link
function TestMasterTrainerRebelTemplate:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(M.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/rebel_master_trainer:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(M.SCREENS) do
		want = want + 1 + #row.options
	end

	-- space-master-trainer-privateer: and the rows of Appendix P-B
	for _, row in ipairs(require("master_trainer_privateer_screens_data").burke) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/rebel_master_trainer:s_... literals in the template (one per leftDialog and option)")
end

-- Content contract 2: the file ends by registering the template under its name
function TestMasterTrainerRebelTemplate:test_the_template_is_added_under_its_own_name()
	local source = readFile(M.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate("willham_burke_convo_template", willham_burke_convo_template)', 1, true), "addConversationTemplate line")
	lu.assertNotNil(source:find('luaClassHandler = "willhamBurkeConvoHandler"', 1, true), "luaClassHandler line")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-4, I-6)
---------------------------------------------------------------------------------------------

TestMasterTrainerRebelClientStrings = {}

function TestMasterTrainerRebelClientStrings:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4, I-6: no id the pre-NGE client lacks
function TestMasterTrainerRebelClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-4, I-6
-- Superseded by space-master-trainer-privateer: with the privateer screens the sources use all 154 client lines and Appendix B is empty.
function TestMasterTrainerRebelClientStrings:test_the_two_sources_use_all_154_client_lines_and_leave_none_unused()
	local ids = CS.sids(M.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == M.STF then
			used[lit.id] = true
		end
	end

	local unused = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			unused[#unused + 1] = id
		end
	end

	table.sort(unused)
	lu.assertEquals(unused, {}, "client lines of rebel_master_trainer the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 154, "distinct ids used")
end

-- AC-4: complete literals only
function TestMasterTrainerRebelClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Burke's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
	lu.assertNil(readFile(M.HANDLER_FILE):find("local%s+stringFile%s*="), "willhamBurkeConvoHandler.lua: no stringFile prefix local")
end

-- AC-4: every screen of the template resolves in the client (the whole template, as a transcript of drives)
function TestMasterTrainerRebelClientStrings:test_every_screen_text_and_option_resolves_in_the_client()
	local bad = {}

	for _, row in ipairs(M.SCREENS) do
		local player = M.pilot({ paid = { 1 }, mission = { [2] = "won" } })
		local t = M.drive(player, row.id)
		local unresolved = CS.transcriptUnresolved(t)

		if #unresolved > 0 then
			bad[#bad + 1] = row.id .. ": " .. table.concat(unresolved, " ")
		end
	end

	lu.assertEquals(bad, {}, "screens whose text or options the client cannot resolve")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (AC-4)
---------------------------------------------------------------------------------------------

TestMasterTrainerRebelJavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/rebel_master_trainer.java")

function TestMasterTrainerRebelJavaGraph:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- the edges of Appendix A that are not RJ's: the one NGE slot (s_559) rejoined to RJ's own reply s_44bd3318 (Data mapping, D-15), "screen reply"
local NOT_J = { "intro_humor s_44bd3318" }

-- AC-4: every RJ-row screen leads where the java leads, except the rejoined slot edge
function TestMasterTrainerRebelJavaGraph:test_every_original_reply_agrees_with_the_swg_script_except_the_rejoined_slot()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(M.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens, disagree, missing = 0, 0, {}, {}

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node == nil then
			missing[#missing + 1] = row.id
		else
			screens = screens + 1

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

	table.sort(disagree)
	lu.assertEquals(missing, {}, "Appendix A screens whose NPC line is not in the java")
	lu.assertEquals(disagree, NOT_J, "replies of RJ-row screens the java does not lead to the template's link")
	lu.assertEquals(screens, 62, "Appendix A screens built from RJ lines (all of them; the pool is empty)")
	lu.assertEquals(checked, 49, "original replies checked against the java (Appendix A carries 50 option edges, less the rejoined one)")
	lu.assertNil(byId.privateer_ready.options[1], "privateer_ready offers no reply (D-4)")
end

-- AC-4: the end flags agree with the java except where Burke's privateer branch is cut away
function TestMasterTrainerRebelJavaGraph:test_the_end_flags_agree_with_the_swg_script_except_privateer_ready()
	local byId = screensById()
	local differs = {}

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil and (byId[row.id].stopConversation == "true") ~= node.isEnd then
			differs[#differs + 1] = row.id
		end
	end

	table.sort(differs)
	lu.assertEquals(differs, { "privateer_ready" }, "screens whose end flag differs from the java (privateer_ready has no replies, D-4)")
end

-- AC-4: the rejoin leads where the Data mapping says
function TestMasterTrainerRebelJavaGraph:test_the_rejoined_reply_leads_to_volunteers_like_the_slot_it_replaces()
	local byId = screensById()

	local function link(screen, sid)
		for _, o in ipairs(byId[screen].options) do
			if o[1] == PREFIX .. sid then
				return o[2]
			end
		end
	end

	lu.assertEquals(link("intro_humor", "s_44bd3318"), "volunteers", "s_44bd3318 on intro_humor")
	lu.assertEquals(link("intro_impression", "s_44bd3318"), "volunteers", "s_44bd3318 on intro_impression")
	lu.assertEquals(GRAPH.nodes.s_6f27454c.options, { "s_559" }, "RJ: the humor line offers the NGE slot s_559")
	lu.assertEquals(GRAPH.successorsOf("s_6f27454c", "s_559"), { "s_7bf46fb2" }, "RJ: s_559 leads to the volunteer line")
end

-- AC-4, D-12: every screen takes the animation of its java line
function TestMasterTrainerRebelJavaGraph:test_every_screen_takes_the_animation_of_its_java_line()
	local byId = screensById()
	local differs = {}

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil and (byId[row.id].animation or "") ~= (node.animation or "") then
			differs[#differs + 1] = row.id
		end
	end

	table.sort(differs)
	lu.assertEquals(differs, {}, "screens whose animation is not their java line's")
end

local function actionsOf(sid)
	local acts = GRAPH.nodes[sid] and GRAPH.nodes[sid].actions or {}

	if type(acts) == "string" then
		acts = { acts }
	end

	return table.concat(acts, " ")
end

-- AC-4, Table H: each action screen's java line carries the action the table names
function TestMasterTrainerRebelJavaGraph:test_the_action_screens_carry_the_java_actions_of_table_h()
	for _, row in ipairs(M.SCREENS) do
		local acts = actionsOf(row.sid)

		if row.action == "start 1" then
			lu.assertNotNil(acts:find("grantMissionOne", 1, true), row.id .. ": RJ grants mission 1 here (" .. acts .. ")")
		elseif row.action == "start 2" then
			lu.assertNotNil(acts:find("grantMissionTwo", 1, true), row.id .. ": RJ grants mission 2 here (" .. acts .. ")")
		elseif row.action == "pay 1" then
			lu.assertNotNil(acts:find("giveRewardOneRebel", 1, true), row.id .. ": RJ pays mission 1 here (" .. acts .. ")")
		elseif row.action == "pay 2; master" then
			lu.assertNotNil(acts:find("giveRewardTwoRebel", 1, true), row.id .. ": RJ pays mission 2 here (" .. acts .. ")")
			lu.assertNotNil(acts:find("grantMasterSkillBoxRebel", 1, true), row.id .. ": RJ grants the master box here (" .. acts .. ")")
		else
			lu.assertNil(acts:find("grantMission", 1, true), row.id .. ": no mission grant in RJ (" .. acts .. ")")
			lu.assertNil(acts:find("giveReward", 1, true), row.id .. ": no reward in RJ (" .. acts .. ")")
			lu.assertNil(acts:find("grantMasterSkillBox", 1, true), row.id .. ": no master grant in RJ (" .. acts .. ")")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The routes (I-9): a walk of the loaded template
---------------------------------------------------------------------------------------------

TestMasterTrainerRebelRoutes = {}

function TestMasterTrainerRebelRoutes:setUp()
	H.reset()
	M.requireConversation(lu)
end

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

-- Visits everything reachable from `from`: { reached = set, ends = set of option-less screens, cycle = a screen on a cycle or nil, total = path count }
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

local function sortedSet(set)
	local out = {}

	for k in pairs(set) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

-- AC-4, I-9: from intro every path ends on m1_accept or decline, and passes m1_accept at most once
function TestMasterTrainerRebelRoutes:test_every_route_from_intro_ends_on_m1_accept_or_decline()
	local g = graph()
	local w = walk(g, "intro")

	lu.assertEquals(sortedSet(w.ends), { "decline", "m1_accept" }, "intro: the screens a route can end on")
	lu.assertEquals(#M.paths("intro"), 9, "intro: nine routes")

	for _, p in ipairs(M.paths("intro")) do
		local hits = 0

		for _, id in ipairs(p.ids) do
			if M.STARTS[id] ~= nil then
				hits = hits + 1
			end
		end

		lu.assertEquals(hits, p.ids[#p.ids] == "m1_accept" and 1 or 0, "intro route " .. table.concat(p.ids, " > ") .. ": start screens passed")
	end

	lu.assertNil(w.cycle, "intro: a cycle through this screen")
end

-- AC-4, I-9: from m2_brief every path ends on m2_accept
function TestMasterTrainerRebelRoutes:test_every_route_from_m2_brief_ends_on_m2_accept()
	local g = graph()
	local w = walk(g, "m2_brief")

	lu.assertEquals(sortedSet(w.ends), { "m2_accept" }, "m2_brief: the screens a route can end on")
	lu.assertEquals(#M.paths("m2_brief"), 4, "m2_brief: four routes")
	lu.assertNil(w.cycle, "m2_brief: a cycle through this screen")
end

-- AC-4, I-9: failure dialogues pass a retry screen of their mission (RJ offers no quit)
function TestMasterTrainerRebelRoutes:test_every_route_from_a_failure_line_passes_a_retry_of_its_mission()
	local g = graph()

	local want = {
		m1_failed = { "m1_retry_a", "m1_retry_b_end" },
		m2_failed = { "m2_retry_a_end", "m2_retry_b_end" },
	}

	for from, ends in pairs(want) do
		local w = walk(g, from)

		lu.assertEquals(sortedSet(w.ends), ends, from .. ": the screens a route can end on")
		lu.assertNil(w.cycle, from .. ": a cycle")
	end

	local mission = { m1_failed = 1, m2_failed = 2 }

	for from, n in pairs(mission) do
		for _, p in ipairs(M.paths(from)) do
			local starts = 0

			for _, id in ipairs(p.ids) do
				if M.STARTS[id] ~= nil then
					lu.assertEquals(M.STARTS[id], n, from .. " route " .. table.concat(p.ids, " > ") .. " reaches the start screen of the other mission: " .. id)
					starts = starts + 1
				end
			end

			lu.assertEquals(starts, 1, from .. " route " .. table.concat(p.ids, " > ") .. ": passes one retry (start) screen")
		end
	end
end

-- AC-4, I-9: from m1_won every path passes m1_reward; from m2_won every path passes master_grant
function TestMasterTrainerRebelRoutes:test_every_route_from_the_won_lines_passes_the_reward_screen()
	for from, reward in pairs({ m1_won = "m1_reward", m2_won = "master_grant" }) do
		lu.assertTrue(#M.paths(from) >= 1, from .. ": at least one route")

		for _, p in ipairs(M.paths(from)) do
			local hits = 0

			for _, id in ipairs(p.ids) do
				if id == reward then
					hits = hits + 1
				end
			end

			lu.assertEquals(hits, 1, from .. " route " .. table.concat(p.ids, " > ") .. ": passes " .. reward .. " once")
		end
	end

	lu.assertEquals(sortedSet(walk(graph(), "m1_won").ends), { "m1_reward" }, "m1_won: the screens a route can end on")
	lu.assertEquals(sortedSet(walk(graph(), "m2_won").ends), { "master_end" }, "m2_won: the screens a route can end on")
end

-- AC-4, I-9: no route starts the other mission or pays a reward it should not, and the graph has no cycle
function TestMasterTrainerRebelRoutes:test_no_route_starts_the_other_mission_or_reaches_the_wrong_reward_and_the_graph_has_no_cycle()
	local g = graph()

	for from, allowed in pairs({
		intro = { start = 1, reward = {} },
		m2_brief = { start = 2, reward = {} },
		m1_failed = { start = 1, reward = {} },
		m2_failed = { start = 2, reward = {} },
		m1_won = { start = nil, reward = { m1_reward = true } },
		m2_won = { start = nil, reward = { master_grant = true } },
	}) do
		local w = walk(g, from)

		lu.assertNil(w.cycle, from .. ": a cycle")

		for id in pairs(w.reached) do
			if M.STARTS[id] ~= nil then
				lu.assertEquals(M.STARTS[id], allowed.start, from .. ": reaches the start screen '" .. id .. "' of the wrong mission")
			end

			if id == "m1_reward" or id == "master_grant" then
				lu.assertTrue(allowed.reward[id] == true, from .. ": reaches the reward screen '" .. id .. "'")
			end
		end
	end

	-- no cycle anywhere in the graph
	for id in pairs(g) do
		lu.assertNil(walk(g, id).cycle, id .. ": a cycle through this screen")
	end
end

---------------------------------------------------------------------------------------------
-- The name tokens (R-3)
---------------------------------------------------------------------------------------------

TestMasterTrainerRebelNames = {}

function TestMasterTrainerRebelNames:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4 (Content contract 2): the handler fills the participant token with the pilot's first name on every screen
function TestMasterTrainerRebelNames:test_every_screen_gets_the_first_name_in_the_tu_parameter()
	local spies = M.spyStarts()
	local bad = {}

	for _, row in ipairs(M.SCREENS) do
		local t = M.drive(M.pilot({ paid = { 1 }, mission = { [2] = "won" } }), row.id)

		if t[1].params == nil or t[1].params.TU ~= "Ace" then
			bad[#bad + 1] = row.id
		end
	end

	lu.assertEquals(bad, {}, "screens whose %TU parameter is not the pilot's first name (setDialogTextTU on every screen)")
	lu.assertTrue(#M.started(spies) > 0, "precondition: the start screens ran")
end
