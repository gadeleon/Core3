-- Dead links, client strings, trailing comments, SWG answer keys, unchanged routes and file hygiene for the off-track duty gates.
-- Spec: .claude/work/space-offtrack-duty-gates/01-spec.md (AC-9, AC-10; invariants I-1, I-2, I-6).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local Swgjava = require("harness.swgjava")
local KG = require("space_convo_client_strings_data")
local O = require("space_offtrack_duty_gates_data")
local DE = require("space_trainer_dead_ends_data")

O.load()

local BASE = "8989b6d9b0" -- the commit the spec was measured on (I-6)
local RESEARCH = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/script/conversation/"

local function templateScreens(name)
	local ids = {}

	for _, s in ipairs(H.conversationTemplateTable(name).screens) do
		ids[#ids + 1] = s.id
	end

	return ids
end

local function indexOf(list, value)
	for i, v in ipairs(list) do
		if v == value then
			return i
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-9, I-2: no dead links
---------------------------------------------------------------------------------------------

TestOffTrackGatesNoDeadLinks = {}

function TestOffTrackGatesNoDeadLinks:setUp() H.reset() end

-- AC-9, I-2
function TestOffTrackGatesNoDeadLinks:test_the_three_templates_have_no_problems()
	for _, name in ipairs({ O.KREEZO, O.VIOPA, O.TUROLDINE }) do
		lu.assertEquals(H.conversationProblems(name), {}, name)
	end
end

-- AC-9: C-1, C-3, C-5 "add after ..., in this order"
function TestOffTrackGatesNoDeadLinks:test_the_new_screens_follow_the_gate_screen_in_the_spec_order()
	local cases = {
		{ O.KREEZO, "non_havoc_pilot", { "non_havoc_no_missions", "non_havoc_duty_options", "non_havoc_destroy_duty", "non_havoc_escort_duty" } },
		{ O.VIOPA, "non_havoc_pilot", { "non_havoc_no_missions", "non_havoc_duty_offer", "non_havoc_duty_options", "non_havoc_duty_decline" } },
		{ O.TUROLDINE, "pilot_not_corsec", { "non_corsec_no_missions" } },
	}

	for _, c in ipairs(cases) do
		local ids = templateScreens(c[1])
		local at = indexOf(ids, c[2])

		lu.assertNotNil(at, c[1] .. ": " .. c[2])

		for i, id in ipairs(c[3]) do
			lu.assertEquals(ids[at + i], id, c[1] .. ": screen after " .. c[2] .. " #" .. i)
		end
	end
end

-- D-2: Turoldine's templates define bare globals, so the new name must not collide with another trainer's
function TestOffTrackGatesNoDeadLinks:test_turoldines_refusal_global_is_not_overwritten_by_another_template()
	local screen = rawget(_G, "non_corsec_no_missions")

	lu.assertNotNil(screen, "global non_corsec_no_missions")
	lu.assertEquals(screen.id, "non_corsec_no_missions", "non_corsec_no_missions: id")
	lu.assertEquals(screen.leftDialog, O.TU .. "s_784ca15", "non_corsec_no_missions: leftDialog")
end

---------------------------------------------------------------------------------------------
-- AC-10, I-1: client strings
---------------------------------------------------------------------------------------------

TestOffTrackGatesClientStrings = {}

function TestOffTrackGatesClientStrings:setUp() H.reset() end

-- AC-10, I-1
function TestOffTrackGatesClientStrings:test_the_six_touched_files_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(O.ALL_SOURCES), {}, "ids the pre-NGE client cannot resolve")
end

-- AC-10, I-1: the ratchet stays empty and keeps its counts
function TestOffTrackGatesClientStrings:test_the_ratchet_known_gaps_stay_empty()
	lu.assertEquals(next(KG.KNOWN_GAPS), nil, "KNOWN_GAPS must stay {}")
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "unresolved ids of all space conversation sources")

	for _, file in ipairs(CS.referencedFiles(O.ALL_SOURCES)) do
		lu.assertNotNil(KG.FIXTURE_COUNTS[file], file .. ": a string file the ratchet does not know (a new fixture would change FIXTURE_COUNTS)")
	end
end

-- AC-10, I-1: every id of the spec is in the committed client fixture
function TestOffTrackGatesClientStrings:test_every_id_of_the_spec_is_in_the_client_fixtures()
	for _, row in ipairs(O.TEXT) do
		local ids = CS.sids("conversation/" .. row[1])

		lu.assertNotNil(ids, row[1] .. ": fixture")
		lu.assertTrue(ids[row[2]] == true, row[1] .. ":" .. row[2] .. " is in the client string table")
	end
end

-- AC-10, D-8: the NGE-only ids are not in the client and are not used
function TestOffTrackGatesClientStrings:test_the_nge_only_kreezo_ids_are_not_used()
	local source = ""

	for _, f in ipairs(O.ALL_SOURCES) do
		source = source .. O.readFile(f)
	end

	for _, id in ipairs(O.NGE_ONLY) do
		local file, sid = id:match("^(.-):(.*)$")

		lu.assertNotEquals(CS.sids("conversation/" .. file)[sid], true, id .. " is expected to be absent from the client table")
		lu.assertNil(source:find('"@conversation/' .. id .. '"', 1, true), id .. " is NGE-only and must not be used")
	end
end

-- AC-10, I-1: the new screens use string ids, never raw text
function TestOffTrackGatesClientStrings:test_the_new_screens_use_string_ids_only()
	local rows = {}

	for _, r in ipairs(O.KREEZO_SCREENS) do rows[#rows + 1] = { O.KREEZO, r.id, "^@conversation/corellia_rebel_trainer_1:s_%w+$" } end
	for _, r in ipairs(O.VIOPA_SCREENS) do rows[#rows + 1] = { O.VIOPA, r.id, "^@conversation/lok_rebel_trainer_2:s_%w+$" } end
	for _, r in ipairs(O.TUROLDINE_SCREENS) do rows[#rows + 1] = { O.TUROLDINE, r.id, "^@conversation/corellia_privateer_tier4:s_%w+$" } end
	rows[#rows + 1] = { O.KREEZO, "non_havoc_pilot", "^@conversation/corellia_rebel_trainer_1:s_%w+$" }
	rows[#rows + 1] = { O.VIOPA, "non_havoc_pilot", "^@conversation/lok_rebel_trainer_2:s_%w+$" }
	rows[#rows + 1] = { O.TUROLDINE, "pilot_not_corsec", "^@conversation/corellia_privateer_tier4:s_%w+$" }

	for _, row in ipairs(rows) do
		local s = DE.requireScreen(row[1], row[2])

		lu.assertTrue(s.leftDialog:match(row[3]) ~= nil, row[2] .. ": leftDialog is not a string id: " .. tostring(s.leftDialog))

		for i, o in ipairs(s.options or {}) do
			lu.assertTrue(o[1]:match(row[3]) ~= nil, row[2] .. ": option " .. i .. " is not a string id: " .. tostring(o[1]))
		end
	end
end

-- AC-10: each line that holds one of these ids carries the client text as its trailing comment
function TestOffTrackGatesClientStrings:test_each_id_line_ends_in_the_client_text_comment()
	for _, row in ipairs(O.TEXT) do
		local literal = '"@conversation/' .. row[1] .. ":" .. row[2] .. '"'
		local found = 0

		for _, f in ipairs(O.ALL_SOURCES) do
			for line in O.readFile(f):gmatch("[^\n]+") do
				local from, to = line:find(literal, 1, true)

				if from then
					local comment = line:sub(to + 1):match("%-%-%s*(.-)%s*$")

					found = found + 1
					lu.assertEquals(comment, row[3], row[1] .. ":" .. row[2] .. " in " .. f .. ": trailing comment of `" .. line:gsub("^%s+", "") .. "`")
				end
			end
		end

		lu.assertTrue(found > 0, row[1] .. ":" .. row[2] .. " is used in the six touched files")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: the SWG answer keys
---------------------------------------------------------------------------------------------

TestOffTrackGatesAnswerKey = {}

function TestOffTrackGatesAnswerKey:setUp() H.reset() end

local function key(name)
	return Swgjava.read(H.FIXTURES .. "script/conversation/" .. name .. ".java")
end

-- AC-9: K:12327-12393, K:21987-22070
function TestOffTrackGatesAnswerKey:test_kreezo_offer_and_refusal_match_corellia_rebel_trainer_1_java()
	local k = key("corellia_rebel_trainer_1")

	lu.assertEquals(k.successorsOf("s_535b6177", "s_1583743c"), { "s_64977077", "s_150b3020" }, "SWG successors of the gate reply (offer, refusal)")
	lu.assertEquals(k.successorsOf("s_64977077", "s_d3ba53db"), { "s_dc243da2" }, "SWG successor of the patrol reply")
	lu.assertEquals(k.successorsOf("s_64977077", "s_b17f599d"), { "s_b282cc98" }, "SWG successor of the escort reply")
	lu.assertTrue(k.nodes["s_150b3020"].isEnd, "SWG refusal ends the conversation")
	lu.assertTrue(k.nodes["s_dc243da2"].isEnd and k.nodes["s_b282cc98"].isEnd, "SWG closing lines end the conversation")
	lu.assertEquals(k.nodes["s_dc243da2"].animation, "goodbye", "SWG closing animation (destroy)")
	lu.assertEquals(k.nodes["s_b282cc98"].animation, "goodbye", "SWG closing animation (escort)")
end

-- AC-9, D-8: Core3 has SWG's two replies of the offer and drops the NGE-only s_589
function TestOffTrackGatesAnswerKey:test_kreezos_core3_graph_matches_the_java_minus_the_nge_only_reply()
	local k = key("corellia_rebel_trainer_1")
	local offer = DE.requireScreen(O.KREEZO, "non_havoc_duty_options")
	local kept = {}

	for _, sid in ipairs(k.nodes["s_64977077"].options) do
		if sid ~= "s_589" then
			kept[#kept + 1] = sid
		end
	end

	local sids = {}

	for i, o in ipairs(offer.options) do
		sids[i] = o[1]:match(":(s_[%w_]+)$")
	end

	lu.assertEquals(offer.leftDialog:match(":(s_[%w_]+)$"), "s_64977077", "offer line")
	lu.assertEquals(sids, kept, "offer options against SWG minus s_589")
	lu.assertEquals(DE.requireScreen(O.KREEZO, "non_havoc_no_missions").leftDialog:match(":(s_[%w_]+)$"), "s_150b3020", "refusal line")
	lu.assertEquals(DE.requireScreen(O.KREEZO, "non_havoc_destroy_duty").animation, k.nodes["s_dc243da2"].animation, "destroy closing animation")
	lu.assertEquals(DE.requireScreen(O.KREEZO, "non_havoc_escort_duty").animation, k.nodes["s_b282cc98"].animation, "escort closing animation")
end

-- AC-9: V:608-745, V:5428-5482
function TestOffTrackGatesAnswerKey:test_viopa_offer_menu_and_refusal_match_lok_rebel_trainer_2_java()
	local v = key("lok_rebel_trainer_2")

	lu.assertEquals(v.successorsOf("s_148ee1c2", "s_1583743c"), { "s_9d922723", "s_990019e5" }, "SWG successors of the gate reply (offer, refusal)")
	lu.assertEquals(v.successorsOf("s_9d922723", "s_e84d85e2"), { "s_565951d5" }, "SWG successor of 'Sounds great.'")
	lu.assertEquals(v.successorsOf("s_9d922723", "s_e87a40f8"), { "s_39e697de" }, "SWG successor of the decline")
	lu.assertEquals(v.successorsOf("s_565951d5", "s_e02126d9"), { "s_a0ee0d37" }, "SWG recovery reply")
	lu.assertEquals(v.successorsOf("s_565951d5", "s_cd3e2b38"), { "s_8447c7d7" }, "SWG escort reply")
	lu.assertEquals(v.successorsOf("s_565951d5", "s_1dfeca09"), { "s_ca434bbe" }, "SWG destroy reply")
	lu.assertEquals(v.successorsOf("s_565951d5", "s_cd1a5817"), { "s_17653741" }, "SWG 'fix things first' reply")
	lu.assertEquals(v.nodes["s_565951d5"].animation, "explain", "SWG briefing animation")
	lu.assertEquals(v.nodes["s_565951d5"].options, { "s_e02126d9", "s_cd3e2b38", "s_1dfeca09", "s_cd1a5817" }, "SWG briefing options")
	lu.assertTrue(v.nodes["s_990019e5"].isEnd and v.nodes["s_39e697de"].isEnd, "SWG refusal and decline end the conversation")
end

-- AC-9: Core3's line for each of those edges
function TestOffTrackGatesAnswerKey:test_viopas_core3_graph_has_the_java_edges()
	local line = function(id) return DE.requireScreen(O.VIOPA, id).leftDialog:match(":(s_[%w_]+)$") end

	lu.assertEquals(line("non_havoc_duty_offer"), "s_9d922723", "offer line")
	lu.assertEquals(line("non_havoc_no_missions"), "s_990019e5", "refusal line")
	lu.assertEquals(line("non_havoc_duty_options"), "s_565951d5", "briefing line")
	lu.assertEquals(line("non_havoc_duty_decline"), "s_39e697de", "decline line")
	lu.assertEquals(line("intro_recovery_duty"), "s_a0ee0d37", "recovery line")
	lu.assertEquals(line("intro_escort_duty"), "s_8447c7d7", "escort line")
	lu.assertEquals(line("intro_destroy_duty"), "s_ca434bbe", "destroy line")
	lu.assertEquals(line("intro_duty_goodbye"), "s_17653741", "goodbye line")
	lu.assertEquals(DE.requireScreen(O.VIOPA, "non_havoc_duty_options").animation, key("lok_rebel_trainer_2").nodes["s_565951d5"].animation, "briefing animation")
end

-- AC-9: T:451-536 (the fixture is a byte copy of the research clone)
function TestOffTrackGatesAnswerKey:test_turoldine_offer_and_refusal_match_corellia_privateer_tier4_java()
	local t = key("corellia_privateer_tier4")

	lu.assertEquals(t.successorsOf("s_32f5282f", "s_c1ff5062"), { "s_3d991214", "s_784ca15" }, "SWG successors of the gate reply (offer, refusal)")
	lu.assertTrue(t.nodes["s_784ca15"].isEnd, "SWG refusal ends the conversation")
	lu.assertEquals(t.nodes["s_784ca15"].animation, "shake_head_no", "SWG refusal animation")
	lu.assertEquals(t.nodes["s_3d991214"].animation, "nod_head_once", "SWG briefing animation")

	local refusal = DE.requireScreen(O.TUROLDINE, "non_corsec_no_missions")

	lu.assertEquals(refusal.leftDialog:match(":(s_[%w_]+)$"), "s_784ca15", "refusal line")
	lu.assertEquals(refusal.animation, t.nodes["s_784ca15"].animation, "refusal animation")
	lu.assertEquals(DE.requireScreen(O.TUROLDINE, "here_for_work").leftDialog:match(":(s_[%w_]+)$"), "s_3d991214", "briefing line")
end

-- AC-9: the path to the offer in Core3 is the one reply SWG has
function TestOffTrackGatesAnswerKey:test_the_java_path_to_each_offer_is_the_one_gate_reply()
	lu.assertEquals(key("corellia_rebel_trainer_1").pathTo("s_535b6177", "s_64977077"), { "s_1583743c" }, "Kreezo")
	lu.assertEquals(key("lok_rebel_trainer_2").pathTo("s_148ee1c2", "s_9d922723"), { "s_1583743c" }, "Viopa")
	lu.assertEquals(key("corellia_privateer_tier4").pathTo("s_32f5282f", "s_3d991214"), { "s_c1ff5062" }, "Turoldine")
end

-- AC-9: the two new java fixtures are byte copies of the research clone
function TestOffTrackGatesAnswerKey:test_the_java_fixtures_are_the_research_clone_copies()
	for _, name in ipairs({ "corellia_rebel_trainer_1", "lok_rebel_trainer_2", "corellia_privateer_tier4" }) do
		local copy = assert(io.open(H.FIXTURES .. "script/conversation/" .. name .. ".java", "rb"), name .. ".java fixture is missing")
		local copyText = copy:read("a")

		copy:close()

		local src = io.open(RESEARCH .. name .. ".java", "rb")

		if src ~= nil then -- no research clone on this machine: the fixture is committed
			local original = src:read("a")

			src:close()
			lu.assertTrue(copyText == original, "fixtures/script/conversation/" .. name .. ".java differs from the research clone")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-10, I-6: nothing else moves (against the commit the spec was measured on)
---------------------------------------------------------------------------------------------

TestOffTrackGatesNothingElseMoves = {}

function TestOffTrackGatesNothingElseMoves:setUp() H.reset() end

local function baseFile(rel)
	local pipe = io.popen("git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " 2>&1")
	local text = pipe:read("a")

	pipe:close()
	lu.assertTrue(#text > 500 and text:find("^fatal") == nil, "git show " .. BASE .. ":MMOCoreORB/bin/scripts/" .. rel .. " did not return the file: " .. text:sub(1, 120))

	return text
end

-- The text of the addScreen table of `id`, from its `id = "..."` line to the closing `}` line
local function screenBody(text, id, what)
	local at = text:find('id = "' .. id .. '"', 1, true)

	lu.assertNotNil(at, what .. ": screen " .. id)

	local e = text:find("\n}\n", at, true)

	lu.assertNotNil(e, what .. ": end of screen " .. id)

	return text:sub(at, e + 2)
end

local GATES = {
	{ "mobile/conversations/space/rebel/havoc_squadron/kreezo_convo.lua", "non_havoc_pilot", "non_havoc_no_missions", "duty_missions" },
	{ "mobile/conversations/space/rebel/havoc_squadron/viopa_convo.lua", "non_havoc_pilot", "non_havoc_no_missions", "duty_missions" },
	{ "mobile/conversations/space/neutral/corsec_squadron/turoldine_convo.lua", "pilot_not_corsec", "non_corsec_no_missions", "here_for_work" },
}

-- AC-10, I-6: every screen of the base templates is byte-identical, except the one option link of each gate screen
function TestOffTrackGatesNothingElseMoves:test_every_pre_existing_screen_is_unchanged_except_the_gate_link()
	for _, g in ipairs(GATES) do
		local now, base = O.readFile(g[1]), baseFile(g[1])
		local count = 0

		for id in base:gmatch('id = "([%w_]+)"') do
			local want = screenBody(base, id, "base " .. g[1])
			local got = screenBody(now, id, g[1])

			if id == g[2] then
				got = got:gsub('"' .. g[3] .. '"', '"' .. g[4] .. '"', 1)
			end

			lu.assertTrue(got == want, g[1] .. ": screen " .. id .. " differs from " .. BASE)
			count = count + 1
		end

		lu.assertTrue(count > 20, g[1] .. ": expected the base template to have many screens, found " .. count)
	end
end

local INITIAL = {
	{ "screenplays/space/conversations/rebel/havoc_squadron/kreezoConvoHandler.lua", "kreezoConvoHandler" },
	{ "screenplays/space/conversations/rebel/havoc_squadron/viopaConvoHandler.lua", "viopaConvoHandler" },
	{ "screenplays/space/conversations/neutral/corsec_squadron/turoldineConvoHandler.lua", "turoldineConvoHandler" },
}

-- AC-10, I-6: getInitialScreen is byte-identical
function TestOffTrackGatesNothingElseMoves:test_get_initial_screen_is_byte_identical_to_the_base()
	for _, h in ipairs(INITIAL) do
		local function block(text, what)
			local s = text:find("function " .. h[2] .. ":getInitialScreen", 1, true)

			lu.assertNotNil(s, what .. ": getInitialScreen of " .. h[2])

			local e = text:find("\nend\n", s, true)

			lu.assertNotNil(e, what .. ": end of getInitialScreen of " .. h[2])

			return text:sub(s, e + 4)
		end

		lu.assertTrue(block(O.readFile(h[1]), "now") == block(baseFile(h[1]), BASE), h[2] .. ":getInitialScreen differs from " .. BASE)
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: file hygiene
---------------------------------------------------------------------------------------------

TestOffTrackGatesFiles = {}

-- AC-10
function TestOffTrackGatesFiles:test_the_six_touched_files_are_lf_only_and_end_with_a_newline()
	for _, f in ipairs(O.ALL_SOURCES) do
		local s = O.readFile(f)

		lu.assertNil(s:find("\r", 1, true), f .. ": contains a CR")
		lu.assertEquals(s:sub(-1), "\n", f .. ": final newline")
	end
end

-- AC-10: tab indentation
function TestOffTrackGatesFiles:test_the_six_touched_files_are_indented_with_tabs()
	for _, f in ipairs(O.ALL_SOURCES) do
		local s = O.readFile(f)

		lu.assertNil(s:find("\n  +[%w{}]"), f .. ": a line is indented with spaces")
	end
end
