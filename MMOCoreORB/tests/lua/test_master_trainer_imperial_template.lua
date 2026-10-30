-- Imperial master trainer: the conversation template (Appendix A), the client strings, the SWG java answer key and the routes.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-4; invariants I-6 and I-9; Content contract 2; Data mapping "NGE slots"; Appendix A, B, D).
--
-- The oracle is Appendix A (master_trainer_imperial_screens_data.lua, generated from the spec table) and the client text of the 204 pre-NGE entries
-- (master_trainer_imperial_client_text.lua). The java answer key is read through harness/swgjava.lua.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local CS = require("harness.client_strings")
local TEXT = require("master_trainer_imperial_client_text")
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
	"default", "working_for_rebellion", "rebel_pilot", "smuggler", "not_ready", "privateer_not_ready", "other_master", "master_done", "on_master_mission",
	"on_quest", "m2_failed", "m1_failed", "m2_won", "m1_won", "m2_brief", "intro", "privateer_ready",
}

TestMasterTrainerImperialOracle = {}

function TestMasterTrainerImperialOracle:setUp() H.reset() end

-- AC-4 (the oracle itself): 69 screens, unique ids; with the replies it uses 121 of the 202 client lines, Appendix B is the rest
function TestMasterTrainerImperialOracle:test_appendix_a_has_69_screens_and_uses_121_client_lines_leaving_exactly_appendix_b()
	lu.assertEquals(#M.SCREENS, 69, "Appendix A rows")

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
	lu.assertEquals(n, 121, "distinct client lines used")
	lu.assertEquals(#M.UNUSED, 81, "Appendix B size")
	lu.assertEquals(unused, M.UNUSED, "client lines Appendix A never uses (Appendix B)")
end

-- AC-4 (the oracle itself): every link resolves, every screen is reachable from a gate screen
function TestMasterTrainerImperialOracle:test_appendix_a_links_resolve_and_every_screen_is_reachable_from_a_gate_screen()
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

-- AC-4 (the oracle itself): the generated client id list holds the 204 entries the spec names
function TestMasterTrainerImperialOracle:test_the_client_id_fixture_holds_204_ids()
	local n = 0

	for _ in pairs(CS.sids(M.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 204, "ids in fixtures/string/en/" .. M.STF .. ".sids")
end

-- AC-4 (the oracle itself): the exact client text of the pool lines placed in the NGE slots (Data mapping), so a wrong sid fails with the words
function TestMasterTrainerImperialOracle:test_the_pool_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_eb02d65, "I am a good pilot, sir.", "m2_failed reply (J s_275)")
	lu.assertEquals(TEXT.s_c13f9a11, "I am sorry, sir. Give me another chance. I will succeed.", "m2_failed_skills reply (J s_278)")
	lu.assertEquals(TEXT.s_b6b25f13, "Yes, sir!", "m2_retry_b / good_pilot reply (J s_281, s_416)")
	lu.assertEquals(TEXT.s_3924b90e, "Good. Now get to your ship before I change my mind.", "m2_retry_b_end (J s_283)")
	lu.assertEquals(TEXT.s_c788dadf, "No, sir. Of course not, sir.", "m1_failed_stronger / intro_permission reply (J s_294, s_401)")
	lu.assertEquals(TEXT.s_87d4bfc2, "Crystal.", "m1_retry_b reply (J s_297)")
	lu.assertEquals(TEXT.s_1ffdcc4b, "Are we clear?", "m1_retry_b_clear (J s_299)")
	lu.assertEquals(TEXT.s_f799f9ec, "Perfectly clear, sir!", "m1_retry_b_clear reply (J s_301)")
	lu.assertEquals(TEXT.s_377d1a96, "Thank you, sir. It has been an honor to be allowed to serve under you.", "m2_rewarded reply (J s_323)")
	lu.assertEquals(TEXT.s_f2ba71dd, "Sir, will I be supplied support?", "m2_unwise / m2_fiscal reply (J s_392, s_396)")
	lu.assertEquals(TEXT.s_78edd4f, "What is the assignment, sir?", "intro_best reply (J s_431)")
	lu.assertNotNil(TEXT.s_fbe23895:find("token of my appreciation", 1, true), "m1_reward line: the only pre-NGE reward line (J:1226)")
end

TestMasterTrainerImperialTemplate = {}

function TestMasterTrainerImperialTemplate:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4, I-6
function TestMasterTrainerImperialTemplate:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	table.sort(got)

	-- space-master-trainer-privateer: Appendix A plus Appendix P-D (44 screens)
	local want = M.screenIds()

	for _, row in ipairs(require("master_trainer_privateer_screens_data").declann) do
		want[#want + 1] = row.id
	end

	table.sort(want)
	lu.assertEquals(got, want, M.TEMPLATE .. ": screen ids (113, no duplicates)")
end

-- AC-4, I-6: dialog, end flag, animation per screen
function TestMasterTrainerImperialTemplate:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
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
function TestMasterTrainerImperialTemplate:test_every_screen_has_the_options_of_its_row_in_order()
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
function TestMasterTrainerImperialTemplate:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(M.TEMPLATE), {}, M.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the template shape
function TestMasterTrainerImperialTemplate:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, M.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestMasterTrainerImperialTemplate:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = readFile(M.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/imperial_master_trainer:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, (TEXT[sid]:gsub("%s+$", "")), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/imperial_master_trainer", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	-- space-master-trainer-privateer: Appendix A (69) plus Appendix P-D (44)
	lu.assertEquals(checked, 69 + #require("master_trainer_privateer_screens_data").declann, "leftDialog lines with a comment")
end

-- Content contract 2: option ids are complete literals, one per static link
function TestMasterTrainerImperialTemplate:test_every_option_id_is_a_complete_string_literal()
	local source = readFile(M.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/imperial_master_trainer:s_[%w_]+"') do
		count = count + 1
	end

	local want = 0

	for _, row in ipairs(M.SCREENS) do
		want = want + 1 + #row.options
	end

	-- space-master-trainer-privateer: and the rows of Appendix P-D
	for _, row in ipairs(require("master_trainer_privateer_screens_data").declann) do
		want = want + 1 + #row.options
	end

	lu.assertEquals(count, want, "complete @conversation/imperial_master_trainer:s_... literals in the template (one per leftDialog and option)")
end

-- Content contract 2: the file ends by registering the template under its name
function TestMasterTrainerImperialTemplate:test_the_template_is_added_under_its_own_name()
	local source = readFile(M.TEMPLATE_FILE)

	lu.assertNotNil(source:find('addConversationTemplate("nial_declann_convo_template", nial_declann_convo_template)', 1, true), "addConversationTemplate line")
	lu.assertNotNil(source:find('luaClassHandler = "nialDeclannConvoHandler"', 1, true), "luaClassHandler line")
end

---------------------------------------------------------------------------------------------
-- Client strings (AC-4, I-6)
---------------------------------------------------------------------------------------------

TestMasterTrainerImperialClientStrings = {}

function TestMasterTrainerImperialClientStrings:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4, I-6: no id the pre-NGE client lacks
function TestMasterTrainerImperialClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- AC-4, I-6
-- Superseded by space-master-trainer-privateer: with the privateer screens the sources use all 202 client lines and Appendix B is empty.
function TestMasterTrainerImperialClientStrings:test_the_two_sources_use_all_202_client_lines_and_leave_none_unused()
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
	lu.assertEquals(unused, {}, "client lines of imperial_master_trainer the template and handler never show")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 202, "distinct ids used")
end

-- AC-4: complete literals only
function TestMasterTrainerImperialClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Declann's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
	lu.assertNil(readFile(M.HANDLER_FILE):find("local%s+stringFile%s*="), "nialDeclannConvoHandler.lua: no stringFile prefix local")
end

-- AC-4: every screen of the template resolves in the client (the whole template, as a transcript of drives)
function TestMasterTrainerImperialClientStrings:test_every_screen_text_and_option_resolves_in_the_client()
	local bad = {}

	for _, row in ipairs(M.SCREENS) do
		local player = M.pilot({ paid = { 1 }, mission = { [2] = "won" }, otherMaster = nil })
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

TestMasterTrainerImperialJavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/imperial_master_trainer.java")

function TestMasterTrainerImperialJavaGraph:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- the edges of Appendix A that are not J's: the NGE slots replaced by pool lines or rejoined (Data mapping "NGE slots"), "screen reply"
local NOT_J = {
	"m2_failed s_eb02d65", "m2_failed_skills s_c13f9a11", "m2_retry_b s_b6b25f13", "m1_failed_stronger s_c788dadf", "m1_retry_b s_87d4bfc2",
	"m2_rewarded s_377d1a96", "m2_unwise s_f2ba71dd", "m2_fiscal s_f2ba71dd", "intro_permission s_c788dadf", "intro_best s_78edd4f", "good_pilot s_b6b25f13",
}

-- AC-4: every J-row screen ends where the java ends and every reply leads where the java leads, except the listed slot edges
function TestMasterTrainerImperialJavaGraph:test_every_original_reply_and_end_flag_agrees_with_the_swg_script_except_the_listed_edges()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(M.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens, disagree, endDiffers = 0, 0, {}, {}

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil then
			screens = screens + 1

			if (byId[row.id].stopConversation == "true") ~= node.isEnd then
				endDiffers[#endDiffers + 1] = row.id
			end

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
	table.sort(endDiffers)
	lu.assertEquals(disagree, want, "replies of J-row screens the java does not lead to the template's link")
	lu.assertEquals(endDiffers, { "privateer_ready" }, "screens whose end flag differs from the java (privateer_ready has no replies, D-4)")
	lu.assertEquals(screens, 67, "Appendix A screens built from J lines (69 less the two pool-line screens)")
	lu.assertEquals(checked, 49, "original replies checked against the java")
end

-- AC-4: the slot edges lead where the Data mapping table says
function TestMasterTrainerImperialJavaGraph:test_the_slot_replies_lead_where_the_nge_slot_table_says()
	local byId = screensById()

	local function link(screen, sid)
		for _, o in ipairs(byId[screen].options) do
			if o[1] == PREFIX .. sid then
				return o[2]
			end
		end
	end

	lu.assertEquals(link("m2_failed", "s_eb02d65"), "m2_failed_skills", "s_eb02d65 on m2_failed")
	lu.assertEquals(link("m2_failed_skills", "s_c13f9a11"), "m2_retry_b", "s_c13f9a11 on m2_failed_skills")
	lu.assertEquals(link("m2_retry_b", "s_b6b25f13"), "m2_retry_b_end", "s_b6b25f13 on m2_retry_b")
	lu.assertEquals(link("m1_failed_stronger", "s_c788dadf"), "m1_retry_b", "s_c788dadf on m1_failed_stronger")
	lu.assertEquals(link("m1_retry_b", "s_87d4bfc2"), "m1_retry_b_clear", "s_87d4bfc2 on m1_retry_b")
	lu.assertEquals(link("m1_retry_b_clear", "s_f799f9ec"), "m1_retry_b_end", "s_f799f9ec on m1_retry_b_clear")
	lu.assertEquals(link("m2_rewarded", "s_377d1a96"), "master_grant", "s_377d1a96 on m2_rewarded")
	lu.assertEquals(link("m2_unwise", "s_f2ba71dd"), "m2_accept", "s_f2ba71dd on m2_unwise")
	lu.assertEquals(link("m2_expendable", "s_f2ba71dd"), "m2_accept", "s_f2ba71dd on m2_expendable")
	lu.assertEquals(link("m2_fiscal", "s_f2ba71dd"), "m2_accept", "s_f2ba71dd on m2_fiscal")
	lu.assertEquals(link("intro_permission", "s_c788dadf"), "intro_record", "s_c788dadf on intro_permission")
	lu.assertEquals(link("good_pilot", "s_b6b25f13"), "battlegroup_b", "s_b6b25f13 on good_pilot")
	lu.assertEquals(link("intro_best", "s_78edd4f"), "kessel_training", "s_78edd4f on intro_best")
end

-- AC-4, D-12: the screens take J's animation, except the reward screen (the slot of s_336 keeps its snap_finger1)
function TestMasterTrainerImperialJavaGraph:test_screens_take_the_animation_of_their_java_line_except_the_reward_slot()
	local byId = screensById()
	local differs = {}

	for _, row in ipairs(M.SCREENS) do
		local node = GRAPH.nodes[row.sid]

		if node ~= nil and (byId[row.id].animation or "") ~= (node.animation or "") then
			differs[#differs + 1] = row.id
		end
	end

	table.sort(differs)
	lu.assertEquals(differs, { "m1_reward" }, "screens whose animation is not their java line's")
	lu.assertEquals(byId.m1_reward.animation, "snap_finger1", "m1_reward keeps the animation of the replaced s_336")
end

-- AC-4, D-9: J's pay point for mission 2 is one line after the grant; the port pays on master_grant
function TestMasterTrainerImperialJavaGraph:test_the_swg_script_grants_the_skill_one_line_before_it_pays_mission_2()
	local grants, pays = {}, {}

	for sid, node in pairs(GRAPH.nodes) do
		local acts = node.actions

		if type(acts) == "string" then
			acts = { acts }
		end

		for _, a in ipairs(acts or {}) do
			if a:find("grantMasterSkillBoxImperial", 1, true) then
				grants[#grants + 1] = sid
			elseif a:find("giveRewardTwoImp", 1, true) then
				pays[#pays + 1] = sid
			end
		end
	end

	table.sort(grants)
	table.sort(pays)
	lu.assertEquals(grants, { "s_c6be1c53" }, "J screen that grants the imperial master skill (J:930)")
	lu.assertEquals(pays, { "s_6276e267" }, "J screen that pays mission 2 (J:983)")

	for _, g in ipairs(grants) do
		for _, p in ipairs(pays) do
			lu.assertNotEquals(g, p, "J grants and pays on different lines (D-9 pays where it grants)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The routes (I-9): a walk of the loaded template
---------------------------------------------------------------------------------------------

TestMasterTrainerImperialRoutes = {}

function TestMasterTrainerImperialRoutes:setUp()
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

-- AC-4, I-9: from intro every path passes m1_accept and ends on m1_accept_end
function TestMasterTrainerImperialRoutes:test_every_route_from_intro_passes_m1_accept_and_ends_on_m1_accept_end()
	local g = graph()
	local w = walk(g, "intro")

	lu.assertEquals(sortedSet(w.ends), { "m1_accept_end" }, "intro: the screens a route can end on")

	for _, p in ipairs(M.paths("intro")) do
		local hits = 0

		for _, id in ipairs(p.ids) do
			if id == "m1_accept" then
				hits = hits + 1
			end
		end

		lu.assertEquals(hits, 1, "intro route " .. table.concat(p.ids, " > ") .. ": passes m1_accept once")
	end

	lu.assertNil(w.cycle, "intro: a cycle through this screen")
end

-- AC-4, I-9: from m2_brief every path passes m2_accept
function TestMasterTrainerImperialRoutes:test_every_route_from_m2_brief_passes_m2_accept_and_ends_on_m2_accept_end()
	local g = graph()
	local w = walk(g, "m2_brief")

	lu.assertEquals(sortedSet(w.ends), { "m2_accept_end" }, "m2_brief: the screens a route can end on")
	lu.assertEquals(#M.paths("m2_brief"), 3, "m2_brief: three routes")

	for _, p in ipairs(M.paths("m2_brief")) do
		local hits = 0

		for _, id in ipairs(p.ids) do
			if id == "m2_accept" then
				hits = hits + 1
			end
		end

		lu.assertEquals(hits, 1, "m2_brief route " .. table.concat(p.ids, " > ") .. ": passes m2_accept once")
	end

	lu.assertNil(w.cycle, "m2_brief: a cycle through this screen")
end

-- AC-4, I-9: failure dialogues end on a retry of their mission or on their _quit screen
function TestMasterTrainerImperialRoutes:test_every_route_from_a_failure_line_ends_on_a_retry_of_its_mission_or_its_quit_screen()
	local g = graph()

	local want = {
		m1_failed = { "m1_failed_quit", "m1_retry_a_end", "m1_retry_b_end" },
		m2_failed = { "m2_failed_quit", "m2_retry_a_end", "m2_retry_b_end" },
	}

	for from, ends in pairs(want) do
		local w = walk(g, from)

		lu.assertEquals(sortedSet(w.ends), ends, from .. ": the screens a route can end on")
		lu.assertNil(w.cycle, from .. ": a cycle")
	end

	-- the retry screens of mission n start mission n only
	for _, p in ipairs(M.paths("m1_failed")) do
		for _, id in ipairs(p.ids) do
			lu.assertNotEquals(M.STARTS[id], 2, "m1_failed route " .. table.concat(p.ids, " > ") .. " reaches a mission 2 start: " .. id)
		end
	end

	for _, p in ipairs(M.paths("m2_failed")) do
		for _, id in ipairs(p.ids) do
			lu.assertNotEquals(M.STARTS[id], 1, "m2_failed route " .. table.concat(p.ids, " > ") .. " reaches a mission 1 start: " .. id)
		end
	end
end

-- AC-4, I-9: from m1_won every path passes m1_reward; from m2_won every path passes master_grant
function TestMasterTrainerImperialRoutes:test_every_route_from_the_won_lines_passes_the_reward_screen()
	for from, reward in pairs({ m1_won = "m1_reward", m2_won = "master_grant" }) do
		lu.assertTrue(#M.paths(from) >= 2, from .. ": at least two routes")

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

	lu.assertEquals(sortedSet(walk(graph(), "m1_won").ends), { "m1_dismissed" }, "m1_won: the screens a route can end on")
	lu.assertEquals(sortedSet(walk(graph(), "m2_won").ends), { "master_end" }, "m2_won: the screens a route can end on")
end

-- AC-4, I-9: no route starts the other mission or pays a reward it should not, and the graph has no cycle
function TestMasterTrainerImperialRoutes:test_no_route_starts_the_other_mission_or_reaches_the_wrong_reward_and_the_graph_has_no_cycle()
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

TestMasterTrainerImperialNames = {}

function TestMasterTrainerImperialNames:setUp()
	H.reset()
	M.requireConversation(lu)
end

-- AC-4 (Content contract 2): the handler fills the participant token with the pilot's first name on every screen
function TestMasterTrainerImperialNames:test_every_screen_gets_the_first_name_in_the_tu_parameter()
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
