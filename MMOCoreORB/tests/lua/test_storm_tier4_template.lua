-- Admiral Kilnstrider: the conversation template (Appendix A), its client strings and the briefing routes.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-2; invariants I-8 and I-12; Content contract 2; Data mapping 1 and 2; Appendix A and E).
--
-- Answer keys: storm_tier4_screens_data.lua (Appendix A, copied from the spec), the SWG java graph of fixtures/script/conversation/tatooine_imperial_tier4.java
-- (harness/swgjava.lua) for every link of a row that is not a placement or a reconstruction, and the generated client id list
-- fixtures/string/en/conversation/tatooine_imperial_tier4.sids (176 ids, patch_12_00.tre).

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")
local TEXT = require("storm_tier4_client_text")
local Swgjava = require("harness.swgjava")

D.loadConversation()

local PATHS = { D.TEMPLATE_FILE, D.HANDLER_FILE }
local PREFIX = D.PREFIX

local function template() return H.conversationTemplateTable(D.TEMPLATE) end

local function screensById()
	local byId = {}

	for _, s in ipairs(template().screens) do
		byId[s.id] = byId[s.id] or s
	end

	return byId
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestStormT4Oracle = {}

function TestStormT4Oracle:setUp() H.reset() end

-- B-2 (the oracle itself): Appendix A has 98 screens, ids unique, 109 links, and it uses all 174 client lines and no other id
function TestStormT4Oracle:test_appendix_a_has_98_screens_109_links_and_uses_exactly_the_174_client_lines()
	lu.assertEquals(#D.SCREENS, 98, "Appendix A rows")

	local seen, used, links = {}, {}, 0

	for _, row in ipairs(D.SCREENS) do
		lu.assertNil(seen[row.id], "duplicate Appendix A id " .. row.id)
		seen[row.id] = true
		used[row.sid] = true

		for _, o in ipairs(row.options) do
			used[o[1]] = true
			links = links + 1
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
	lu.assertEquals(unused, {}, "client lines Appendix A never uses (D-18: none stays unused)")
	lu.assertEquals(n, 174, "distinct ids used")
	lu.assertEquals(links, 109, "static links")
end

-- B-2 (the oracle itself): links resolve and every screen is reachable from a gate screen or a screen the handler picks
function TestStormT4Oracle:test_appendix_a_links_resolve_and_every_screen_is_reachable()
	local rows = {}

	for _, row in ipairs(D.SCREENS) do
		rows[row.id] = row
	end

	local roots = { "not_pilot", "wrong_faction", "off_track", "off_track_refused", "wanted", "not_ready", "on_mission", "ready", "ready_train", "intro", "tier4_incomplete",
		"transfer", "here_for_work", "m1_brief", "m2_brief", "m2_brief_trained", "m3_brief", "m4_brief" }

	for n = 1, 4 do
		roots[#roots + 1] = D.MISSIONS[n].failed
		roots[#roots + 1] = D.MISSIONS[n].reward
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

	for _, row in ipairs(D.SCREENS) do
		if not reached[row.id] then
			unreached[#unreached + 1] = row.id
		end
	end

	lu.assertEquals(unreached, {}, "Appendix A screens no route reaches from a gate screen")

	local starts, pays = 0, 0

	for _ in pairs(D.STARTS) do
		starts = starts + 1
	end

	for _ in pairs(D.PAYS) do
		pays = pays + 1
	end

	lu.assertEquals({ starts, pays }, { 14, 4 }, "start screens (4 gates + 10 accepts), pay screens")
end

-- B-2 (the oracle itself): Appendix D's paths end on the grant screens they name
function TestStormT4Oracle:test_appendix_d_paths_follow_the_links_of_appendix_a_to_their_grant_screen()
	lu.assertEquals(#D.PATHS, 10, "Appendix D paths (the 10 accept screens)")

	for _, p in ipairs(D.PATHS) do
		local id = p.from

		for _, reply in ipairs(p.replies) do
			local row = D.screenRow(id)
			local nextId

			for _, o in ipairs(row.options) do
				if o[1] == reply then
					nextId = o[2]
				end
			end

			lu.assertNotNil(nextId, p.grant .. ": screen '" .. id .. "' has no reply " .. reply)
			id = nextId
		end

		lu.assertEquals(id, p.grant, "Appendix D path of " .. p.grant .. " ends here")
		lu.assertEquals(D.STARTS[p.grant], p.mission, p.grant .. ": a start screen of mission " .. p.mission)
	end
end

-- B-2 (the oracle itself): the generated client id list holds the 176 entries the spec names
function TestStormT4Oracle:test_the_client_id_fixture_holds_176_ids()
	local n = 0

	for _ in pairs(CS.sids(D.STF)) do
		n = n + 1
	end

	lu.assertEquals(n, 176, "ids in fixtures/string/en/" .. D.STF .. ".sids (174 lines + do_not_edit + s_0)")
	lu.assertEquals(CS.sids(D.STF).do_not_edit, true, "do_not_edit")
	lu.assertEquals(CS.sids(D.STF).s_0, true, "s_0")
end

-- B-2 (the oracle itself): the placed pre-NGE lines and the topics are the words of the client (Data mapping 1, FK-1)
function TestStormT4Oracle:test_the_topic_and_placed_pre_nge_lines_are_the_words_of_the_client()
	lu.assertEquals(TEXT.s_a50d5eb4, "I want to learn about experimental TIE vessels.", "starships_04 topic")
	lu.assertEquals(TEXT.s_2c2ce09e, "I want to learn about heavy starship component use.", "weapons_04 topic")
	lu.assertEquals(TEXT.s_a5d7d28d, "I want to learn about elite TIE guard training.", "procedures_04 topic")
	lu.assertEquals(TEXT.s_97682588, "I want to learn about droid intelligence theory.", "droid_04 topic")
	lu.assertEquals(TEXT.s_49425c4b, "I'd like to do more than talk.", "the reply that fills J's NGE s_178 on intro")
	lu.assertEquals(TEXT.s_469b88eb, "I wish only to serve.", "the reply that fills J's NGE s_56 on m3_reward")
	lu.assertEquals(TEXT.s_71874e85, "You have earned some of my trust, %NU. Not all, but some.", "the trained M2 head (FK-2)")
end

-- B-2 (the oracle itself): the ten name lines
function TestStormT4Oracle:test_exactly_ten_screens_carry_a_name_token()
	local with = {}

	for _, row in ipairs(D.SCREENS) do
		if TEXT[row.sid]:find("%%[TN]U") then
			with[#with + 1] = row.id
		end
	end

	table.sort(with)

	local want = {}

	for i, id in ipairs(D.NAME_SCREENS) do
		want[i] = id
	end

	table.sort(want)
	lu.assertEquals(with, want, "screens whose client line has %TU / %NU (NAME_SCREENS)")

	for _, row in ipairs(D.SCREENS) do
		lu.assertEquals(row.token ~= "", TEXT[row.sid]:find("%%[TN]U") ~= nil, row.id .. ": the oracle's token flag agrees with the client line")
	end

	for id, text in pairs(TEXT) do
		if text:find("%%[TN]U") then
			local used = false

			for _, row in ipairs(D.SCREENS) do
				if row.sid == id then
					used = true
				end
			end

			lu.assertTrue(used, "the %TU/%NU line " .. id .. " is the dialog of a screen, not only a reply")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The template (B-2, I-8)
---------------------------------------------------------------------------------------------

TestStormT4Template = {}

function TestStormT4Template:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- B-2, I-8
function TestStormT4Template:test_the_template_has_exactly_the_screens_of_appendix_a()
	local got = {}

	for i, s in ipairs(template().screens) do
		got[i] = s.id
	end

	local inOrder = {}

	for i, row in ipairs(D.SCREENS) do
		inOrder[i] = row.id
	end

	lu.assertEquals(got, inOrder, D.TEMPLATE .. ": screen ids, in Appendix A row order (98, no duplicates)")
end

-- B-2, I-8: dialog, end flag, animation per screen
function TestStormT4Template:test_every_screen_has_the_dialog_end_flag_and_animation_of_its_row()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
		local s = byId[row.id]

		lu.assertNotNil(s, D.TEMPLATE .. ": missing screen '" .. row.id .. "'")
		lu.assertEquals(s.leftDialog, PREFIX .. row.sid, "screen '" .. row.id .. "': leftDialog")
		lu.assertEquals(s.stopConversation == "true", row.stop, "screen '" .. row.id .. "': stopConversation")
		lu.assertEquals(s.animation or "", row.animation, "screen '" .. row.id .. "': animation (NPC-only from J; none on rebuilt screens, D-11)")
	end
end

-- B-2, I-8: the static options in order (ready_train's four topics all link m1_brief)
function TestStormT4Template:test_every_screen_has_the_static_options_of_its_row_in_order()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
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

-- B-2, I-8
function TestStormT4Template:test_the_template_has_no_dead_links_or_duplicate_screens()
	lu.assertEquals(H.conversationProblems(D.TEMPLATE), {}, D.TEMPLATE .. ": dead links, duplicate or missing ids")
end

-- Content contract 2: the globals kilnstrider_convo_<id>
function TestStormT4Template:test_every_screen_is_a_global_named_kilnstrider_convo_and_its_id()
	local byId = screensById()

	for _, row in ipairs(D.SCREENS) do
		local g = rawget(_G, "kilnstrider_convo_" .. row.id)

		lu.assertNotNil(g, "global kilnstrider_convo_" .. row.id)
		lu.assertTrue(g == byId[row.id], "kilnstrider_convo_" .. row.id .. " is the screen added to the template")
	end
end

-- Content contract 2: the template shape and the first line
function TestStormT4Template:test_the_template_header_is_the_lua_handler_template()
	local t = template()

	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, D.HANDLER, "luaClassHandler")
	lu.assertEquals(t.initialScreen, "", "initialScreen (the handler picks the first screen)")

	local source = D.readFile(H.SCRIPTS .. D.TEMPLATE_FILE)

	lu.assertEquals(source:match("^([^\n]*)"),
		"-- Admiral Kilnstrider (Storm Squadron tier 4, Endor research outpost) conversation screens; ported from SWG-Source tatooine_imperial_tier4 (STF conversation/tatooine_imperial_tier4, pre-NGE client lines). Handler: kilnstriderConvoHandler.lua (feature storm-tier4-kilnstrider).",
		"line 1 of the template")
	lu.assertNotNil(source:find('addConversationTemplate("kilnstrider_convo_template", kilnstrider_convo_template)', 1, true), "addConversationTemplate line")
end

-- Content contract 2: the English text of every line is a trailing comment on the leftDialog line
function TestStormT4Template:test_every_dialog_line_carries_the_client_text_as_a_trailing_comment()
	local source = D.readFile(H.SCRIPTS .. D.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		local sid, comment = line:match('leftDialog%s*=%s*"@conversation/tatooine_imperial_tier4:(s_[%w_]+)"%s*,?%s*%-%-%s*(.-)%s*$')

		if sid ~= nil then
			checked = checked + 1
			lu.assertEquals(comment, trim(TEXT[sid]), "trailing comment of the leftDialog line for " .. sid)
		elseif line:find("leftDialog", 1, true) and line:find("@conversation/tatooine_imperial_tier4", 1, true) then
			lu.fail("leftDialog line without the trailing client text: " .. line)
		end
	end

	lu.assertEquals(checked, 98, "leftDialog lines with a comment")
end

-- Content contract 2: every static option carries its text as a trailing comment
function TestStormT4Template:test_every_static_option_line_carries_the_reply_text_as_a_trailing_comment()
	local source = D.readFile(H.SCRIPTS .. D.TEMPLATE_FILE)
	local checked = 0

	for line in (source .. "\n"):gmatch("([^\n]*)\n") do
		if not line:find("leftDialog", 1, true) then
			local sid, comment = line:match('{%s*"@conversation/tatooine_imperial_tier4:(s_[%w_]+)"%s*,%s*"[%w_]+"%s*}%s*,?%s*%-%-%s*(.-)%s*$')

			if sid ~= nil then
				checked = checked + 1
				lu.assertEquals(comment, trim(TEXT[sid]), "trailing comment of the option line for " .. sid)
			elseif line:find('{%s*"@conversation/tatooine_imperial_tier4:') then
				lu.fail("option line without the trailing client text: " .. line)
			end
		end
	end

	lu.assertEquals(checked, 109, "option lines with a comment")
end

-- Content contract 2: option ids are complete literals, one per static link
function TestStormT4Template:test_every_option_id_is_a_complete_string_literal()
	local source = D.readFile(H.SCRIPTS .. D.TEMPLATE_FILE)
	local count = 0

	for _ in source:gmatch('"@conversation/tatooine_imperial_tier4:s_[%w_]+"') do
		count = count + 1
	end

	lu.assertEquals(count, 98 + 109, "complete @conversation/tatooine_imperial_tier4:s_... literals in the template (one per leftDialog and static option)")
end

---------------------------------------------------------------------------------------------
-- Client strings (B-2, I-8)
---------------------------------------------------------------------------------------------

TestStormT4ClientStrings = {}

function TestStormT4ClientStrings:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- B-2, I-8: no id the pre-NGE client lacks
function TestStormT4ClientStrings:test_template_and_handler_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(PATHS), {}, "string ids of the template and handler the pre-NGE client cannot resolve")
end

-- B-2, I-8: the two sources use all 174 client lines and no NGE editor number
function TestStormT4ClientStrings:test_the_two_sources_use_exactly_the_174_client_lines()
	local ids = CS.sids(D.STF)
	local used = {}

	for _, lit in ipairs(CS.literals(PATHS)) do
		if lit.file == D.STF then
			used[lit.id] = true
			-- the NGE editor numbers are s_56 .. s_371 (at most three digits); a client id such as s_7090182 only happens to have decimal digits only
			lu.assertNil(lit.id:match("^s_%d%d?%d?$"), "NGE editor id " .. lit.id .. " at " .. lit.path .. ":" .. lit.line)
		end
	end

	for id in pairs(ids) do
		if id ~= "s_0" then
			lu.assertNil(id:match("^s_%d%d?%d?$"), "the client table holds no NGE-style editor number, so the rule above is exact: " .. id)
		end
	end

	local missing = {}

	for id in pairs(ids) do
		if id ~= "do_not_edit" and id ~= "s_0" and not used[id] then
			missing[#missing + 1] = id
		end
	end

	table.sort(missing)
	lu.assertEquals(missing, {}, "client lines of tatooine_imperial_tier4 the template and handler never show (D-18)")

	local n = 0

	for _ in pairs(used) do
		n = n + 1
	end

	lu.assertEquals(n, 174, "distinct ids used")
end

-- B-2: every screen of the template, shown through the handler, resolves in the client (the transcript of each screen alone)
function TestStormT4ClientStrings:test_every_screen_shown_through_the_handler_resolves_in_the_client()
	for _, row in ipairs(D.SCREENS) do
		H.reset()

		local t = D.drive(D.pilot({ met = true, t4 = { 1 }, xp = D.TRAIN_COST }), row.id)

		lu.assertEquals(CS.transcriptUnresolved(t), {}, row.id .. ": client strings of the screen as shown")
	end
end

-- B-2: complete literals only
function TestStormT4ClientStrings:test_the_sources_store_no_string_file_prefix_and_build_no_id()
	lu.assertEquals(CS.dynamicSites(PATHS), {}, "stored string-file prefixes in Kilnstrider's sources")
	lu.assertEquals(CS.prefixUses(PATHS), {}, "lines that use a stored prefix")
	lu.assertEquals(CS.unusedPrefixes(PATHS), {}, "unused stored prefixes")
end

-- B-2: the handler names the four topic replies, the off-track reply and the ready reply as complete literals (Content contract 2, Conversation flow 2)
function TestStormT4ClientStrings:test_the_handler_names_the_conditional_replies_as_complete_literals()
	local source = D.readFile(H.SCRIPTS .. D.HANDLER_FILE)

	for _, t in ipairs(D.TRAIN) do
		lu.assertNotNil(source:find('"' .. PREFIX .. t.reply .. '"', 1, true), "kilnstriderConvoHandler.lua: complete literal for the " .. t.x .. " topic reply " .. t.reply)
	end

	lu.assertNotNil(source:find('"' .. PREFIX .. D.OFF_TRACK_REPLY .. '"', 1, true), "kilnstriderConvoHandler.lua: complete literal for the off-track reply")
	lu.assertNotNil(source:find('"' .. PREFIX .. D.READY_REPLY .. '"', 1, true), "kilnstriderConvoHandler.lua: complete literal for the ready reply")
	lu.assertNil(source:find("local%s+stringFile%s*="), "kilnstriderConvoHandler.lua: no stringFile prefix local")
	lu.assertEquals(source:match("^([^\n]*)"),
		"-- Admiral Kilnstrider (Storm Squadron tier 4) conversation handler; ported from SWG-Source tatooine_imperial_tier4.java. One-click, free-choice training bought with XP, the grounded gate, duties and the hand-off to Grand Admiral Declann: pre-NGE client lines (feature storm-tier4-kilnstrider).",
		"line 1 of the handler")
end

---------------------------------------------------------------------------------------------
-- The SWG java graph agrees with every original link of Appendix A (B-2)
---------------------------------------------------------------------------------------------

TestStormT4JavaGraph = {}

local GRAPH = Swgjava.read(H.FIXTURES .. D.JAVA)

function TestStormT4JavaGraph:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- the replies of J-row screens whose edge is not J's (Data mapping 1): the intro reply (NGE s_178), m3_reward's second reply (NGE s_56), the four topics
-- (the NGE training chain s_212 ..), and the replies of the four heads (the NGE briefing subtrees)
local NOT_J = {
	"intro s_49425c4b", "m3_reward s_469b88eb",
	"ready_train s_a50d5eb4", "ready_train s_2c2ce09e", "ready_train s_a5d7d28d", "ready_train s_97682588",
	"m1_brief s_469b88eb", "m1_brief s_9cc5ad7c",
	"m2_brief s_c782ced7", "m2_brief s_dd2ae025",
	"m3_brief s_643d24c8", "m3_brief s_34f8d771", "m3_brief s_ad56e0fd",
	"m4_brief s_2f748550", "m4_brief s_a1586753",
}

-- the NGE editor replies those rows carry in J that the pre-NGE tree does not (Data mapping 1)
local J_ONLY = {
	"intro s_178", "m3_reward s_56", "ready_train s_212",
	"m1_brief s_337", "m1_brief s_349", "m2_brief s_295", "m2_brief s_319", "m3_brief s_261", "m3_brief s_285", "m4_brief s_227", "m4_brief s_243",
}

-- B-2: every J-row screen ends exactly where the java ends, has J's animation, and every reply leads where the java leads, except the listed edges
function TestStormT4JavaGraph:test_every_original_reply_end_flag_and_animation_agrees_with_the_swg_script_except_the_listed_edges()
	local byId = screensById()
	local dialogOf = {}

	for _, row in ipairs(D.SCREENS) do
		dialogOf[row.id] = row.sid
	end

	local checked, screens, disagree, javaOnly = 0, 0, {}, {}

	for _, row in ipairs(D.SCREENS) do
		if row.java ~= "" then
			local node = GRAPH.nodes[row.sid]

			screens = screens + 1
			lu.assertNotNil(node, "java has no NPC line " .. row.sid .. " (screen '" .. row.id .. "')")
			lu.assertEquals(byId[row.id].stopConversation == "true", node.isEnd, "screen '" .. row.id .. "' (" .. row.sid .. "): ends the conversation iff the java does")
			lu.assertEquals(byId[row.id].animation or "", node.animation or "", "screen '" .. row.id .. "' (" .. row.sid .. "): the java's animation")

			local have, inRow = {}, {}

			for _, o in ipairs(node.options) do
				have[o] = true
			end

			for _, o in ipairs(row.options) do
				inRow[o[1]] = true

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

			for _, o in ipairs(node.options) do
				if not inRow[o] then
					javaOnly[#javaOnly + 1] = row.id .. " " .. o
				end
			end
		end
	end

	local want, wantJavaOnly = {}, {}

	for i, x in ipairs(NOT_J) do
		want[i] = x
	end

	for i, x in ipairs(J_ONLY) do
		wantJavaOnly[i] = x
	end

	table.sort(want)
	table.sort(wantJavaOnly)
	table.sort(disagree)
	table.sort(javaOnly)
	lu.assertEquals(disagree, want, "replies of J-row screens the java does not lead to the template's link")
	lu.assertEquals(javaOnly, wantJavaOnly, "replies the java offers on a J-row screen that the template does not")
	lu.assertEquals(screens, 63, "Appendix A screens built from J lines")
	lu.assertEquals(checked, 49, "original replies checked against the java")
end

-- B-2, D-8: intro_briefing and duty_briefing carry the same line and link; only the first sets the key
function TestStormT4JavaGraph:test_intro_briefing_and_duty_briefing_share_the_line_and_the_link()
	local byId = screensById()

	lu.assertEquals(byId.intro_briefing.leftDialog, PREFIX .. "s_3e6a4237", "intro_briefing line")
	lu.assertEquals(byId.duty_briefing.leftDialog, PREFIX .. "s_3e6a4237", "duty_briefing line")
	lu.assertEquals(byId.intro_briefing.options, byId.duty_briefing.options, "same options")
	lu.assertEquals(byId.duty_briefing.options[1][2], "duty_freighters", "the briefing continues with the freighters")
end

---------------------------------------------------------------------------------------------
-- The routes (I-12): a walk of the loaded template, not a conversation per path
---------------------------------------------------------------------------------------------

TestStormT4Routes = {}

function TestStormT4Routes:setUp()
	H.reset()
	D.requireConversation(lu)
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

-- B-2, I-12: from every head (and m2_brief_trained), every option path ends on a grant of that mission; no route reaches another grant, a reward or a duty screen
function TestStormT4Routes:test_every_route_from_a_brief_ends_on_a_grant_of_its_own_mission_and_reaches_nothing_else()
	local g = graph()
	local foreign = {}

	for id in pairs(D.PAYS) do
		foreign[id] = true
	end

	for _, id in ipairs({ "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue" }) do
		foreign[id] = true
	end

	for _, m in ipairs(D.MISSIONS) do
		for _, brief in ipairs({ m.brief, m.trained }) do
			local w = walk(g, brief)

			lu.assertNil(w.cycle, brief .. ": a cycle through this screen")

			for id in pairs(w.ends) do
				lu.assertEquals(D.STARTS[id], m.n, brief .. ": the route ends on '" .. id .. "', which is not a grant of mission " .. m.n)
				lu.assertTrue(g[id].stop, brief .. ": the grant '" .. id .. "' ends the conversation")
			end

			for id in pairs(w.reached) do
				lu.assertTrue(D.STARTS[id] == nil or D.STARTS[id] == m.n, brief .. ": reaches the grant '" .. id .. "' of another mission")
				lu.assertNil(foreign[id], brief .. ": reaches the reward or duty screen '" .. id .. "'")
			end
		end
	end
end

-- B-2, I-12: the grants reachable from the heads are the accept screens: 2, 3, 2, 3 (the failure gates are not)
function TestStormT4Routes:test_the_briefs_reach_exactly_the_accept_screens_of_their_mission()
	local g = graph()
	local want = { [1] = 2, [2] = 3, [3] = 2, [4] = 3 }

	for _, m in ipairs(D.MISSIONS) do
		for _, brief in ipairs({ m.brief, m.trained }) do
			local w = walk(g, brief)
			local grants = {}

			for id in pairs(w.ends) do
				grants[#grants + 1] = id
			end

			table.sort(grants)

			local expected = {}

			for id, n in pairs(D.STARTS) do
				if n == m.n and id:find("_accept_", 1, true) then
					expected[#expected + 1] = id
				end
			end

			table.sort(expected)
			lu.assertEquals(grants, expected, brief .. ": grant screens reached")
			lu.assertEquals(#grants, want[m.n], brief .. ": grant screens of mission " .. m.n)
		end
	end
end

-- B-2: the spec's sizes (Data mapping 2: routes per head 14 / 10 / 8 / 12, inner screens 7 / 6 / 3 / 8)
function TestStormT4Routes:test_the_heads_have_the_route_counts_and_inner_screens_of_data_mapping_2()
	local g = graph()

	lu.assertEquals({ walk(g, "m1_brief").total, walk(g, "m2_brief").total, walk(g, "m2_brief_trained").total, walk(g, "m3_brief").total, walk(g, "m4_brief").total },
		{ 14, 10, 10, 8, 12 }, "option paths from m1_brief, m2_brief, m2_brief_trained, m3_brief, m4_brief")

	local inner = {}

	for n, m in ipairs(D.MISSIONS) do
		local w = walk(g, m.brief)
		local count = 0

		for id in pairs(w.reached) do
			if id ~= m.brief and D.STARTS[id] == nil then
				count = count + 1
			end
		end

		inner[n] = count
	end

	lu.assertEquals(inner, { 7, 6, 3, 8 }, "inner screens between a head and its grants")
end

-- B-2: the two M2 heads carry the same replies
function TestStormT4Routes:test_the_trained_m2_head_has_the_replies_of_the_m2_head()
	local byId = screensById()

	lu.assertEquals(byId.m2_brief_trained.options, byId.m2_brief.options, "m2_brief_trained: the replies and links of m2_brief")
	lu.assertNotEquals(byId.m2_brief_trained.leftDialog, byId.m2_brief.leftDialog, "the trained head is the twin line (FK-2)")
end

-- B-2: the failure dialogues: every route from a failure line ends on a closing line that starts nothing (the mission restarts on display)
function TestStormT4Routes:test_every_route_from_a_failure_line_ends_on_a_closing_line_of_the_table()
	local g = graph()

	for _, m in ipairs(D.MISSIONS) do
		local w = walk(g, m.failed)

		lu.assertNil(w.cycle, m.failed .. ": a cycle")

		for id in pairs(w.ends) do
			lu.assertTrue(g[id].stop, m.failed .. ": the route ends on '" .. id .. "', which ends the conversation")
			lu.assertNil(D.STARTS[id], m.failed .. ": '" .. id .. "' is a closing line, not a second start")
			lu.assertNil(D.PAYS[id], m.failed .. ": '" .. id .. "' pays nothing")
		end

		for id in pairs(w.reached) do
			lu.assertTrue(D.STARTS[id] == nil or id == m.failed, m.failed .. ": reaches the start screen '" .. id .. "'")
		end
	end
end

-- B-2, I-12: the only cycle in the template is the duty briefing loop
function TestStormT4Routes:test_the_only_cycle_is_the_duty_briefing_loop()
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
	lu.assertEquals(got, { "duty_briefing", "duty_freighters", "duty_menu", "duty_pirates" }, "screens on a cycle (duty_briefing -> duty_freighters -> duty_pirates -> duty_menu -> duty_briefing)")
end

---------------------------------------------------------------------------------------------
-- The name tokens (B-2)
---------------------------------------------------------------------------------------------

TestStormT4Names = {}

function TestStormT4Names:setUp()
	H.reset()
	D.requireConversation(lu)
end

-- B-2 (Content contract 2): the handler fills the participant token with the pilot's first name on the ten name screens
function TestStormT4Names:test_the_ten_name_screens_get_the_first_name_in_the_tu_parameter()
	for _, id in ipairs(D.NAME_SCREENS) do
		local t = D.drive(D.pilot({ met = true }), id)

		lu.assertNotNil(t[1].params, id .. ": params")
		lu.assertEquals(t[1].params.TU, "Ace", id .. ": the %TU / %NU parameter is the pilot's first name")
	end
end

-- B-2: no other screen gets a name parameter
function TestStormT4Names:test_the_other_screens_get_no_name_parameter()
	local names = {}

	for _, id in ipairs(D.NAME_SCREENS) do
		names[id] = true
	end

	for _, row in ipairs(D.SCREENS) do
		if not names[row.id] then
			local t = D.drive(D.pilot({ met = true }), row.id)

			lu.assertTrue(t[1].params == nil or t[1].params.TU == nil, row.id .. ": no %TU parameter")
		end
	end
end
