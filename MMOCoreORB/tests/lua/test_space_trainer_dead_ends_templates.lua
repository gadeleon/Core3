-- Dead links, client strings, comments, SWG answer keys and file hygiene for the CorSec trainer dead-ends feature.
-- Spec: .claude/work/space-trainer-dead-ends/01-spec.md (AC-8, AC-9, AC-10; invariants I-1, I-2, I-5).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local Swgjava = require("harness.swgjava")
local D = require("space_trainer_dead_ends_data")
local KG = require("space_convo_client_strings_data")

D.loadAllTemplates()

local ALL = {}

for _, f in ipairs(D.SOURCES.rhea) do ALL[#ALL + 1] = f end
for _, f in ipairs(D.SOURCES.rikkh) do ALL[#ALL + 1] = f end

---------------------------------------------------------------------------------------------
-- AC-8, I-2: no dead links
---------------------------------------------------------------------------------------------

TestDeadEndsNoDeadLinks = {}

function TestDeadEndsNoDeadLinks:setUp() H.reset() end

-- AC-8
function TestDeadEndsNoDeadLinks:test_rhea_template_has_no_problems()
	lu.assertEquals(H.conversationProblems(D.RHEA), {}, D.RHEA)
end

-- AC-8
function TestDeadEndsNoDeadLinks:test_rikkh_template_has_no_problems()
	lu.assertEquals(H.conversationProblems(D.RIKKH), {}, D.RIKKH)
end

-- Dead links that already exist in templates this feature does not touch (a greeter and two space stations); found by this sweep, left for their own
-- features. Every other space template must stay free of dead links.
local OUT_OF_SCOPE = { gil_burtin_convo_template = true, spacestation_dathomir_convotemplate = true, spacestation_yavin4_convotemplate = true }

-- AC-8: every space conversation template that is loaded, not only the two trainers
function TestDeadEndsNoDeadLinks:test_no_loaded_space_template_links_to_a_missing_screen()
	local names = {}

	for name in pairs(H.Engine.conversationTemplates) do
		names[#names + 1] = name
	end

	table.sort(names)
	lu.assertTrue(#names >= 10, "expected the space templates to be loaded, got " .. #names)

	local dead = {}

	for _, name in ipairs(names) do
		for _, p in ipairs(H.conversationProblems(name)) do
			if p:find("links to missing screen", 1, true) and not OUT_OF_SCOPE[name] then
				dead[#dead + 1] = name .. ": " .. p
			end
		end
	end

	lu.assertEquals(dead, {}, "dead option links")
end

---------------------------------------------------------------------------------------------
-- AC-9, I-1: client strings
---------------------------------------------------------------------------------------------

TestDeadEndsClientStrings = {}

function TestDeadEndsClientStrings:setUp() H.reset() end

-- AC-9, I-1
function TestDeadEndsClientStrings:test_the_four_touched_files_use_only_ids_the_client_has()
	lu.assertEquals(CS.unresolved(ALL), {}, "ids the pre-NGE client cannot resolve")
end

-- AC-9, I-1: the ratchet stays empty
function TestDeadEndsClientStrings:test_the_ratchet_known_gaps_stay_empty()
	lu.assertEquals(next(KG.KNOWN_GAPS), nil, "KNOWN_GAPS must stay {}")
	lu.assertEquals(CS.unresolvedByFile(CS.spaceConversationSources()), {}, "unresolved ids of all space conversation sources")
end

local STRING_ID = "^@conversation/corellia_privateer_trainer_?2?:s_%w+$"

-- AC-9, I-1: the new screens use client string ids, not raw text
function TestDeadEndsClientStrings:test_the_new_screens_use_string_ids_only()
	local screens = {
		{ D.RHEA, "i_need_to" }, { D.RHEA, "no_missions" }, { D.RHEA, "not_corsec_duty_missions" }, { D.RHEA, "non_corsec_pilot" },
		{ D.RIKKH, "non_corsec_duty_options" }, { D.RIKKH, "non_corsec_missions" }, { D.RIKKH, "pilot_not_corsec" },
	}

	for _, row in ipairs(screens) do
		local s = D.requireScreen(row[1], row[2])

		lu.assertTrue(s.leftDialog:match(STRING_ID) ~= nil, row[2] .. ": leftDialog is not a string id: " .. s.leftDialog)

		for i, o in ipairs(s.options or {}) do
			lu.assertTrue(o[1]:match(STRING_ID) ~= nil, row[2] .. ": option " .. i .. " is not a string id: " .. o[1])
		end
	end
end

-- AC-9: every id the spec adds or re-uses is in the committed client fixture
function TestDeadEndsClientStrings:test_every_id_of_the_spec_is_in_the_client_fixtures()
	for _, row in ipairs(D.TEXT) do
		local ids = CS.sids("conversation/" .. row[1])

		lu.assertNotNil(ids, row[1] .. ": fixture")
		lu.assertTrue(ids[row[2]] == true, row[1] .. ":" .. row[2] .. " is in the client string table")
	end
end

-- AC-9: the NGE-only ids the spec rejects (D-2, D-3, D-4) never appear
function TestDeadEndsClientStrings:test_the_nge_only_ids_are_not_used()
	local source = ""

	for _, f in ipairs(ALL) do
		source = source .. D.readFile(f)
	end

	for _, id in ipairs({ "corellia_privateer_trainer:s_228", "corellia_privateer_trainer:s_43", "corellia_privateer_trainer:s_45", "corellia_privateer_trainer:s_47",
		"corellia_privateer_trainer:s_49", "corellia_privateer_trainer_2:s_237", "corellia_privateer_trainer_2:s_244" }) do
		lu.assertNil(source:find('"@conversation/' .. id .. '"', 1, true), id .. " is NGE-only and must not be used")
	end
end

-- AC-9: each line that holds one of these ids carries the client text as its trailing comment
function TestDeadEndsClientStrings:test_each_id_line_ends_in_the_client_text_comment()
	local source = {}

	for _, f in ipairs(ALL) do
		source[#source + 1] = D.readFile(f)
	end

	source = table.concat(source, "\n")

	for _, row in ipairs(D.TEXT) do
		local literal = '"@conversation/' .. row[1] .. ":" .. row[2] .. '"'
		local found = 0

		for line in source:gmatch("[^\n]+") do
			local from, to = line:find(literal, 1, true)

			if from then
				local comment = line:sub(to + 1):match("%-%-%s*(.-)%s*$")

				found = found + 1
				lu.assertEquals(comment, row[3], row[1] .. ":" .. row[2] .. ": trailing comment of `" .. line:gsub("^%s+", "") .. "`")
			end
		end

		lu.assertTrue(found > 0, row[1] .. ":" .. row[2] .. " is used in the four touched files")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: the SWG answer key
---------------------------------------------------------------------------------------------

TestDeadEndsAnswerKey = {}

function TestDeadEndsAnswerKey:setUp() H.reset() end

local function sidsOfOptions(screen)
	local out = {}

	for i, o in ipairs(screen.options or {}) do
		out[i] = o[1]:match(":(s_[%w_]+)$")
	end

	return out
end

-- AC-8: R:1687-1764
function TestDeadEndsAnswerKey:test_rhea_offer_and_refusal_match_corellia_privateer_trainer_java()
	local key = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer.java")

	lu.assertEquals(key.successorsOf("s_ff684aed", "s_c1ff5062"), { "s_dadaabf", "s_5b8a384b" }, "SWG successors of the gate reply (offer, refusal)")
	lu.assertEquals(key.nodes["s_dadaabf"].options, { "s_6106187c", "s_1a7f1a1b", "s_6276c98", "s_2883b989" }, "SWG offer options")
	lu.assertTrue(key.nodes["s_5b8a384b"].isEnd, "SWG refusal ends the conversation")

	local offer = D.requireScreen(D.RHEA, "not_corsec_duty_missions")
	local refusal = D.requireScreen(D.RHEA, "no_missions")

	lu.assertEquals(offer.leftDialog:match(":(s_[%w_]+)$"), "s_dadaabf", "offer line")
	lu.assertEquals(sidsOfOptions(offer), key.nodes["s_dadaabf"].options, "offer options against SWG")
	lu.assertEquals(refusal.leftDialog:match(":(s_[%w_]+)$"), "s_5b8a384b", "refusal line")
end

-- AC-8: R:2803-2876, the end screen of the sign-up
function TestDeadEndsAnswerKey:test_rhea_i_need_to_matches_the_java_end_line()
	local key = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer.java")

	lu.assertEquals(key.successorsOf("s_80a724aa", "s_68660d24"), { "s_c697d2d5" }, "SWG answer to 'I need to take care of some things first.'")
	lu.assertTrue(key.nodes["s_c697d2d5"].isEnd, "SWG s_c697d2d5 ends the conversation")
	lu.assertEquals(D.requireScreen(D.RHEA, "i_need_to").leftDialog:match(":(s_[%w_]+)$"), "s_c697d2d5", "i_need_to line")
end

-- AC-8: K:311-390 (the copy of the research clone, byte for byte)
function TestDeadEndsAnswerKey:test_rikkh_offer_and_refusal_match_corellia_privateer_trainer_2_java()
	local key = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer_2.java")

	lu.assertEquals(key.successorsOf("s_87bedbc6", "s_b978843d"), { "s_285c3698", "s_7b7fb169" }, "SWG successors of the gate reply (offer, refusal)")
	lu.assertEquals(key.nodes["s_285c3698"].animation, "explain", "SWG offer animation")
	lu.assertEquals(key.nodes["s_285c3698"].options, { "s_fa5c5669", "s_56e162f2", "s_237", "s_28ea80d" }, "SWG offer options")
	lu.assertEquals(key.nodes["s_7b7fb169"].animation, "slow_down", "SWG refusal animation")
	lu.assertTrue(key.nodes["s_7b7fb169"].isEnd, "SWG refusal ends the conversation")

	local offer = D.requireScreen(D.RIKKH, "non_corsec_duty_options")
	local refusal = D.requireScreen(D.RIKKH, "non_corsec_missions")
	local mapped = {}

	-- D-4: the NGE-only second "Destroy Duty" (s_237) is the pre-NGE s_fa5c5669
	for i, sid in ipairs(key.nodes["s_285c3698"].options) do
		mapped[i] = (sid == "s_237") and "s_fa5c5669" or sid
	end

	lu.assertEquals(offer.leftDialog:match(":(s_[%w_]+)$"), "s_285c3698", "offer line")
	lu.assertEquals(offer.animation, key.nodes["s_285c3698"].animation, "offer animation")
	lu.assertEquals(sidsOfOptions(offer), mapped, "offer options against SWG (D-4)")
	lu.assertEquals(refusal.leftDialog:match(":(s_[%w_]+)$"), "s_7b7fb169", "refusal line")
	lu.assertEquals(refusal.animation, key.nodes["s_7b7fb169"].animation, "refusal animation")
end

-- AC-8: the path to the offer in Core3 is the one reply SWG has
function TestDeadEndsAnswerKey:test_the_core3_path_to_each_offer_is_the_java_reply()
	local rhea = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer.java")
	local rikkh = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_privateer_trainer_2.java")

	lu.assertEquals(rhea.pathTo("s_ff684aed", "s_dadaabf"), { "s_c1ff5062" }, "SWG path to Rhea's offer")
	lu.assertEquals(rikkh.pathTo("s_87bedbc6", "s_285c3698"), { "s_b978843d" }, "SWG path to Rikkh's offer")

	local t = D.converse(D.RHEA, D.pilot({ skills = D.TIER1 }), { "s_c1ff5062" }, H.newNpc({ name = "Sgt. Rhea" }))

	lu.assertEquals(t[2].text, D.P .. "s_dadaabf", "Core3 Rhea offer line")

	H.reset()
	t = D.converse(D.RIKKH, D.pilot({ skills = D.TIER1 }), { "s_b978843d" }, H.newNpc({ name = "Capt. Rikkh" }))
	lu.assertEquals(t[2].text, D.Q .. "s_285c3698", "Core3 Rikkh offer line")
end

-- AC-8: the Rikkh java fixture is a byte-for-byte copy of the research clone
function TestDeadEndsAnswerKey:test_the_rikkh_java_fixture_is_the_research_clone_copy()
	local src = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/script/conversation/corellia_privateer_trainer_2.java"
	local f = io.open(src, "rb")

	if f == nil then
		return -- no research clone on this machine; the fixture is committed
	end

	local original = f:read("a")

	f:close()

	local g = assert(io.open(H.FIXTURES .. "script/conversation/corellia_privateer_trainer_2.java", "rb"))
	local copy = g:read("a")

	g:close()
	lu.assertTrue(copy == original, "fixtures/script/conversation/corellia_privateer_trainer_2.java differs from the research clone")
end

---------------------------------------------------------------------------------------------
-- AC-10: file hygiene
---------------------------------------------------------------------------------------------

TestDeadEndsFiles = {}

-- AC-10
function TestDeadEndsFiles:test_the_four_touched_files_are_lf_only_and_end_with_a_newline()
	for _, f in ipairs(ALL) do
		local s = D.readFile(f)

		lu.assertNil(s:find("\r", 1, true), f .. ": contains a CR")
		lu.assertEquals(s:sub(-1), "\n", f .. ": final newline")
	end
end

-- AC-10: tab indent on every added screen
function TestDeadEndsFiles:test_added_screens_are_indented_with_tabs()
	for _, f in ipairs({ D.SOURCES.rhea[1], D.SOURCES.rikkh[1] }) do
		local s = D.readFile(f)

		lu.assertNil(s:find("\n  +[%w{}]"), f .. ": a line is indented with spaces")
	end
end
