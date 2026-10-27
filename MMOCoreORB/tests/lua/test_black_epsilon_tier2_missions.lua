-- Prisk Kith'Vys: the hand-in and the opening mission, the four briefings (after training and on a later visit), failures and retries, the final,
-- the tour report and the duty hand-outs.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-5, AC-7, AC-10; Conversation flow 2, 3, 3.3 and 4; Appendix A).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (black_epsilon_tier2_screens_data.lua)
-- unless a conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local CS = require("harness.client_strings")

P.load()

local function setUp()
	H.reset()
	P.requireConversation(lu)
end

-- The screens an Appendix A graph shows when `choices` (reply sids) are followed from screen `first`
local function follow(first, choices)
	local ids = { first }

	for _, sid in ipairs(choices) do
		local row = P.screenRow(ids[#ids])

		lu.assertNotNil(row, "Appendix A has no screen '" .. tostring(ids[#ids]) .. "'")

		local link

		for _, o in ipairs(row.options) do
			if o[1] == sid then
				link = o[2]
			end
		end

		lu.assertNotNil(link, "Appendix A: screen '" .. row.id .. "' has no reply " .. sid)
		ids[#ids + 1] = link
	end

	return ids
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- Runs a walk: the screens shown, the quests started, the client strings of the transcript
local function walk(w)
	local spies = P.spyStarts()
	local player = w.player or P.pilot(w.pilot)
	local t = P.talk(player, w.choices)
	local ids = w.ids or follow(w.first, w.choices)

	lu.assertEquals(P.ids(t), ids, w.name .. ": screens shown")
	lu.assertEquals(P.started(spies), w.starts or {}, w.name .. ": quests started")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings of the transcript (AC-5)")

	return t, player
end

---------------------------------------------------------------------------------------------
-- The hand-in and the opening mission
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Opening = {}

TestBlackEpsilonT2Opening.setUp = setUp

local HAND_IN = { "s_9edd30bf", "s_f87e5fe8", "s_f4f691ae", "s_7a33d3dc" } -- hakassha_sent -> gawking -> bothawui -> test_run -> expendable
local TO_ACCEPT_FROM_EXPENDABLE = { "s_8bf01045", "s_1d1f03a8" }            -- expendable -> capture -> opening_accept

-- AC-7: the straight walk
function TestBlackEpsilonT2Opening:test_the_hand_in_walks_to_opening_accept_and_starts_recovery_16()
	local t, player = walk({ pilot = {}, first = "hakassha_sent", choices = concat(HAND_IN, TO_ACCEPT_FROM_EXPENDABLE), starts = { P.OPENING }, name = "hand-in" })

	lu.assertEquals(P.ids(t), { "hakassha_sent", "gawking", "bothawui", "test_run", "expendable", "capture", "opening_accept" }, "screens shown")
	lu.assertTrue(t[#t].stop, "opening_accept ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_16:attempted"), "1", "corellia_imperial_16:attempted")
end

-- AC-7: the question loops come back to their option sets
function TestBlackEpsilonT2Opening:test_the_expendable_and_capture_loops_return_to_their_option_sets()
	local expendable = { "s_e7f16de3", "s_f37f3d1a" }
	local capture = { "s_83c3790d", "s_26912e4b", "s_c8516ab0" } -- how -> crew -> why_capture

	local t = walk({ pilot = {}, first = "hakassha_sent", name = "loops",
		choices = concat(HAND_IN, { "s_e7f16de3", "s_f37f3d1a", "s_e7f16de3", "s_8bf01045", "s_83c3790d", "s_26912e4b", "s_c8516ab0", "s_83c3790d", "s_26912e4b", "s_1d1f03a8" }),
		starts = { P.OPENING } })

	lu.assertEquals(P.ids(t), { "hakassha_sent", "gawking", "bothawui", "test_run", "expendable", "hidden_daggers", "why_destroy", "hidden_daggers", "capture", "how", "crew",
		"why_capture", "how", "crew", "opening_accept" }, "screens shown")

	for _, i in ipairs({ 5, 6, 7, 8 }) do
		lu.assertEquals(P.optionSids(t[i]), { "s_e7f16de3", "s_f37f3d1a", "s_8bf01045" }, t[i].id .. ": the expendable option set")
	end

	for _, i in ipairs({ 9, 11, 12, 14 }) do
		lu.assertEquals(P.optionSids(t[i]), { "s_83c3790d", "s_c8516ab0", "s_1d1f03a8" }, t[i].id .. ": the capture option set")
	end

	lu.assertEquals(#expendable + #capture, 5, "walk bookkeeping")
end

-- AC-7: every other ending grants nothing
function TestBlackEpsilonT2Opening:test_leaving_the_hand_in_before_the_accept_screen_starts_nothing()
	local stops = {
		{ "gawking", concat({ HAND_IN[1] }) },
		{ "test_run", { "s_9edd30bf", "s_f87e5fe8", "s_f4f691ae" } },
		{ "expendable", HAND_IN },
		{ "capture", concat(HAND_IN, { "s_8bf01045" }) },
		{ "crew", concat(HAND_IN, { "s_8bf01045", "s_83c3790d", "s_26912e4b" }) },
		{ "why_capture", concat(HAND_IN, { "s_8bf01045", "s_c8516ab0" }) },
	}

	for _, s in ipairs(stops) do
		H.reset()

		local spies = P.spyStarts()
		local player = P.pilot({})

		P.talk(player, s[2])
		lu.assertEquals(P.started(spies), {}, "left at " .. s[1] .. ": quests started")
		lu.assertNil(H.getQuestStatus(player, "corellia_imperial_16:attempted"), "left at " .. s[1] .. ": the :attempted key")
	end
end

-- AC-7: the first screen of a failed opening re-grants nothing until the pilot agrees
function TestBlackEpsilonT2Opening:test_opening_failed_retries_through_opening_retry_and_starts_recovery_16()
	local t = walk({ pilot = { opening = "failed" }, first = "opening_failed", choices = { "s_37680b25" }, starts = { P.OPENING }, name = "opening retry" })

	lu.assertEquals(P.ids(t), { "opening_failed", "opening_retry" }, "screens shown")
	lu.assertTrue(t[2].stop, "opening_retry ends the conversation")
end

-- AC-7: opening_failed alone does not start the mission
function TestBlackEpsilonT2Opening:test_opening_failed_shown_alone_starts_nothing()
	walk({ pilot = { opening = "failed" }, first = "opening_failed", choices = {}, starts = {}, name = "opening_failed alone" })
end

-- AC-7: the opening needs a real start that works
function TestBlackEpsilonT2Opening:test_the_real_start_of_recovery_16_makes_the_quest_active()
	local player = P.pilot({ inShip = true, zone = "space_corellia" })
	local q = P.quest(P.OPENING)

	q:start()
	P.talk(player, concat(HAND_IN, TO_ACCEPT_FROM_EXPENDABLE))
	H.advance(0)
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "recovery", "corellia_imperial_16"), "recovery/corellia_imperial_16 is active in the journal")
end

---------------------------------------------------------------------------------------------
-- Start screens (table H)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Starts = {}

TestBlackEpsilonT2Starts.setUp = setUp

local STARTS = {
	{ screen = "opening_accept", head = P.OPENING, stem = "corellia_imperial_16" },
	{ screen = "opening_retry", head = P.OPENING, stem = "corellia_imperial_16" },
	{ screen = "m12_accept", head = P.A12, stem = "corellia_imperial_12" },
	{ screen = "m12_retry", head = P.A12, stem = "corellia_imperial_12" },
	{ screen = "m13_accept", head = P.I13, stem = "corellia_imperial_13" },
	{ screen = "m13_retry", head = P.I13, stem = "corellia_imperial_13" },
	{ screen = "m14_accept", head = P.A14, stem = "corellia_imperial_14" },
	{ screen = "m14_retry", head = P.A14, stem = "corellia_imperial_14" },
	{ screen = "m15_accept", head = P.P15, stem = "corellia_imperial_15" },
	{ screen = "m15_retry", head = P.P15, stem = "corellia_imperial_15" },
	{ screen = "final_accept", head = P.A17, stem = "corellia_imperial_17" },
	{ screen = "final_retry", head = P.A17, stem = "corellia_imperial_17" },
}

for _, s in ipairs(STARTS) do
	-- AC-7: each start screen sets its :attempted key and starts its chain head
	TestBlackEpsilonT2Starts["test_" .. s.screen .. "_sets_the_attempted_key_and_starts_" .. s.head] = function()
		local spies = P.spyStarts()
		local player = P.pilot({ opening = "won" })
		local t = P.drive(player, s.screen)

		lu.assertEquals(P.ids(t), { s.screen }, "screens shown")
		lu.assertTrue(t[1].stop, s.screen .. " ends the conversation")
		lu.assertEquals(P.started(spies), { s.head }, s.screen .. ": quests started")
		lu.assertEquals(spies[s.head][1].args[1], player, s.screen .. ": the chain head is started for the pilot")
		lu.assertEquals(H.getQuestStatus(player, s.stem .. ":attempted"), "1", s.screen .. ": " .. s.stem .. ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, s.screen .. ": client strings")
	end
end

-- AC-7: a stale run (a finished member of the chain) is cleared before the start
function TestBlackEpsilonT2Starts:test_a_start_clears_a_stale_chain_member_first()
	local spies = P.spyStarts()
	local player = P.pilot({ opening = "won", t2 = { 3 }, mission = { [4] = "won4patrol" } })

	lu.assertEquals(P.state(player, P.P15), "complete", "precondition: the patrol is complete, the surprise attack is not")
	P.drive(player, "m15_retry")
	lu.assertEquals(P.state(player, P.P15), "none", "the stale patrol entry is cleared")
	lu.assertEquals(P.state(player, P.S15), "none", "the surprise attack entry is cleared")
	lu.assertEquals(P.started(spies), { P.P15 }, "the patrol is started once")
end

-- AC-7: a stale final: assassinate 17 complete, the survival failed
function TestBlackEpsilonT2Starts:test_the_final_retry_clears_a_completed_assassinate_17_before_the_start()
	local spies = P.spyStarts()
	local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "failed" } })

	P.setState(player, P.A17, "complete")
	P.talk(player)
	lu.assertEquals(P.state(player, P.A17), "none", "assassinate 17 is cleared")
	lu.assertEquals(P.started(spies), { P.A17 }, "assassinate 17 is started once")
end

-- AC-7: every first screen of a failed mission re-grants on display, and only that one
local RETRIES = {
	{ first = "opening_retry", pilot = { opening = "failed" }, head = P.OPENING, stem = "corellia_imperial_16", via = "opening_failed" },
	{ first = "m12_retry", pilot = { opening = "won", t2 = { 1 }, mission = { [1] = "failed" } }, head = P.A12, stem = "corellia_imperial_12" },
	{ first = "m13_retry", pilot = { opening = "won", t2 = { 4 }, mission = { [2] = "failed" } }, head = P.I13, stem = "corellia_imperial_13" },
	{ first = "m14_retry", pilot = { opening = "won", t2 = { 2 }, mission = { [3] = "failed" } }, head = P.A14, stem = "corellia_imperial_14" },
	{ first = "m15_retry", pilot = { opening = "won", t2 = { 3 }, mission = { [4] = "failed" } }, head = P.P15, stem = "corellia_imperial_15" },
	{ first = "final_retry", pilot = { opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "failed" } }, head = P.A17, stem = "corellia_imperial_17" },
}

for _, r in ipairs(RETRIES) do
	if r.via == nil then
		-- AC-7: D-7
		TestBlackEpsilonT2Starts["test_a_pilot_with_" .. r.stem .. "_failed_is_re_granted_it_on_display_of_" .. r.first] = function()
			local spies = P.spyStarts()
			local player = P.pilot(r.pilot)
			local t = P.talk(player)

			lu.assertEquals(P.ids(t), { r.first }, "screens shown")
			lu.assertTrue(t[1].stop, r.first .. " ends the conversation")
			lu.assertEquals(P.started(spies), { r.head }, r.first .. ": quests started on display")
			lu.assertEquals(H.getQuestStatus(player, r.stem .. ":attempted"), "1", r.stem .. ":attempted stays set")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-7, D-6: a retry is not granted on display while another space quest runs
function TestBlackEpsilonT2Starts:test_no_retry_is_granted_while_another_space_quest_runs()
	for _, r in ipairs(RETRIES) do
		H.reset()

		local o = {}

		for k, v in pairs(r.pilot) do
			o[k] = v
		end

		o.datapad = "story"

		local spies = P.spyStarts()
		local t = P.talk(P.pilot(o))

		lu.assertEquals(t[1].id, "on_mission", r.stem .. " failed + a datapad quest: first screen")
		lu.assertEquals(P.started(spies), {}, r.stem .. ": nothing started")
	end
end

-- AC-7: the real start of each head from its retry screen, with the pilot in a ship in the quest zone
function TestBlackEpsilonT2Starts:test_the_real_start_of_each_chain_head_makes_it_active_for_a_pilot_in_a_ship()
	for _, r in ipairs(RETRIES) do
		H.reset()

		local o = {}

		for k, v in pairs(r.pilot) do
			o[k] = v
		end

		o.inShip = true
		o.zone = "space_corellia"

		local player = P.pilot(o)
		local q = P.quest(r.head)
		local id = P.IDENTITY[r.head]

		q:start()

		local ok, err = pcall(P.talk, player, r.via and { "s_37680b25" } or nil)

		lu.assertTrue(ok, r.first .. ": talking raised a Lua error: " .. tostring(err))
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after " .. r.first)
	end
end

---------------------------------------------------------------------------------------------
-- Briefings: ready missions and the walks (AC-7)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Briefings = {}

TestBlackEpsilonT2Briefings.setUp = setUp

-- AC-7: "It's about time that you returned..." -> s_6d3be6aa -> the briefing of the ready mission
function TestBlackEpsilonT2Briefings:test_a_ready_mission_opens_assignment_waiting_and_its_reply_leads_to_that_missions_briefing()
	for i, m in ipairs(P.MISSIONS) do
		H.reset()

		-- the TRAIN index of the mission's skill
		local trainIndex
		for ti, t in ipairs(P.TRAIN) do
			if t.skill == m.skill then
				trainIndex = ti
			end
		end

		local t = P.talk(P.pilot({ opening = "won", t2 = { trainIndex } }), { "s_6d3be6aa" })

		lu.assertEquals(P.ids(t), { "assignment_waiting", m.brief }, "mission " .. m.n .. " (" .. m.x .. "): screens shown")
		lu.assertEquals(t[1].text, P.PREFIX .. "s_9a117462", "the NPC line")
		lu.assertEquals(P.linksOf(t[1]), { m.brief }, "mission " .. m.n .. ": the link the handler set (C-2)")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(i, m.n, "bookkeeping")
	end
end

-- AC-7: the static link stays when nothing is ready
function TestBlackEpsilonT2Briefings:test_assignment_waiting_keeps_the_static_link_when_no_mission_is_ready()
	local t = P.drive(P.pilot({ opening = "won" }), "assignment_waiting")

	lu.assertEquals(P.linksOf(t[1]), { "m12_brief" }, "the static link")
end

-- one entry per briefing: the pilot, the walk from its first screen, the head and status stem
local function pilotWith(trainIndex, extra)
	local o = { opening = "won", t2 = { trainIndex }, xp = 0 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return o
end

local WALKS = {
	-- mission 1 (starships), returning
	{ name = "M12 returning", first = "assignment_waiting", pilot = pilotWith(1), head = P.A12, stem = "corellia_imperial_12",
		choices = { "s_6d3be6aa", "s_69d014bc", "s_cb86c1fc", "s_d6508432", "s_2c4789b" },
		ids = { "assignment_waiting", "m12_brief", "m12_intel", "m12_nerfs_pride", "m12_kill", "m12_accept" } },
	{ name = "M12 returning with the Alderaan question", first = "assignment_waiting", pilot = pilotWith(1), head = P.A12, stem = "corellia_imperial_12",
		choices = { "s_6d3be6aa", "s_1bbb820a", "s_1bbb820a", "s_69d014bc", "s_cb86c1fc", "s_d6508432", "s_62b8eb46", "s_91f63d81", "s_62b8eb46", "s_2c4789b" },
		ids = { "assignment_waiting", "m12_brief", "m12_alderaan", "m12_alderaan", "m12_intel", "m12_nerfs_pride", "m12_kill", "m12_assassin", "m12_escort", "m12_assassin", "m12_accept" } },
	-- mission 2 (droid), returning
	{ name = "M13 returning", first = "assignment_waiting", pilot = pilotWith(4), head = P.I13, stem = "corellia_imperial_13",
		choices = { "s_6d3be6aa", "s_88523765" }, ids = { "assignment_waiting", "m13_brief", "m13_accept" } },
	-- mission 3 (weapons), returning
	{ name = "M14 returning", first = "assignment_waiting", pilot = pilotWith(2), head = P.A14, stem = "corellia_imperial_14",
		choices = { "s_6d3be6aa", "s_d6dfa36e", "s_1ff4247a" }, ids = { "assignment_waiting", "m14_brief", "m14_navy", "m14_accept" } },
	-- mission 4 (procedures), returning
	{ name = "M15 returning", first = "assignment_waiting", pilot = pilotWith(3), head = P.P15, stem = "corellia_imperial_15",
		choices = { "s_6d3be6aa", "s_908955bc", "s_2c4789b" }, ids = { "assignment_waiting", "m15_brief", "m15_hunt", "m15_accept" } },
}

for _, w in ipairs(WALKS) do
	-- AC-7, AC-5
	TestBlackEpsilonT2Briefings["test_" .. w.name:gsub("[^%w]+", "_"):lower() .. "_reaches_the_accept_screen_and_grants_the_mission"] = function()
		local t, player = walk({ pilot = w.pilot, first = w.first, choices = w.choices, ids = w.ids, starts = { w.head }, name = w.name })

		lu.assertTrue(t[#t].stop, w.name .. ": the accept screen ends the conversation")
		lu.assertEquals(H.getQuestStatus(player, w.stem .. ":attempted"), "1", w.name .. ": " .. w.stem .. ":attempted")
	end

	-- AC-7: leaving before the accept screen grants nothing, and the next talk still opens assignment_waiting
	TestBlackEpsilonT2Briefings["test_" .. w.name:gsub("[^%w]+", "_"):lower() .. "_left_before_the_accept_screen_grants_nothing"] = function()
		local spies = P.spyStarts()
		local player = P.pilot(w.pilot)
		local partial = {}

		for i = 1, #w.choices - 1 do
			partial[i] = w.choices[i]
		end

		P.talk(player, partial)
		lu.assertEquals(P.started(spies), {}, w.name .. ": quests started before the accept screen")
		lu.assertNil(H.getQuestStatus(player, w.stem .. ":attempted"), w.name .. ": the :attempted key")
		lu.assertEquals(P.firstScreen(player), "assignment_waiting", w.name .. ": the next talk")
	end
end

-- the briefings right after training: topic reply (buys the skill) -> trained_<x> -> reply -> briefing ...
local TRAINED = {
	{ name = "M12 after training", x = 1, head = P.A12, stem = "corellia_imperial_12",
		choices = { "s_be505897", "s_116d8b3b", "s_69d014bc", "s_cb86c1fc", "s_d6508432", "s_2c4789b" },
		ids = { "training_menu", "trained_starships", "m12_brief_trained", "m12_intel", "m12_nerfs_pride", "m12_kill", "m12_accept" } },
	{ name = "M12 after training with both loops", x = 1, head = P.A12, stem = "corellia_imperial_12",
		choices = { "s_be505897", "s_116d8b3b", "s_1bbb820a", "s_69d014bc", "s_cb86c1fc", "s_d6508432", "s_91f63d81", "s_62b8eb46", "s_2c4789b" },
		ids = { "training_menu", "trained_starships", "m12_brief_trained", "m12_alderaan", "m12_intel", "m12_nerfs_pride", "m12_kill", "m12_escort", "m12_assassin", "m12_accept" } },
	{ name = "M13 after training", x = 4, head = P.I13, stem = "corellia_imperial_13",
		choices = { "s_9b4e084a", "s_b51a649", "s_88523765" }, ids = { "training_menu", "trained_droid", "m13_brief", "m13_accept" } },
	{ name = "M14 after training", x = 2, head = P.A14, stem = "corellia_imperial_14",
		choices = { "s_82fd8660", "s_ceafaf0b", "s_d6dfa36e", "s_1ff4247a" }, ids = { "training_menu", "trained_weapons", "m14_brief_trained", "m14_navy", "m14_accept" } },
	{ name = "M15 after training", x = 3, head = P.P15, stem = "corellia_imperial_15",
		choices = { "s_a872e9f9", "s_116d8b3b", "s_908955bc", "s_2c4789b" }, ids = { "training_menu", "trained_procedures", "m15_brief", "m15_hunt", "m15_accept" } },
}

for _, w in ipairs(TRAINED) do
	-- AC-7, AC-9, AC-5
	TestBlackEpsilonT2Briefings["test_" .. w.name:gsub("[^%w]+", "_"):lower() .. "_reaches_the_accept_screen_and_grants_the_mission"] = function()
		P.useSkillCosts()

		local player = P.pilot({ opening = "won", xp = 60000 })
		local t = walk({ player = player, choices = w.choices, ids = w.ids, starts = { w.head }, name = w.name })

		lu.assertTrue(t[#t].stop, w.name .. ": the accept screen ends the conversation")
		lu.assertEquals(H.getQuestStatus(player, w.stem .. ":attempted"), "1", w.name .. ": " .. w.stem .. ":attempted")
		lu.assertEquals(#P.bought(), 1, w.name .. ": skills bought")
		lu.assertEquals(P.bought()[1][2], P.TRAIN[w.x].skill, w.name .. ": the skill bought")
	end

	-- AC-7: leaving after training, before the accept screen: nothing started, the next talk opens assignment_waiting (FP-2)
	TestBlackEpsilonT2Briefings["test_" .. w.name:gsub("[^%w]+", "_"):lower() .. "_left_midway_opens_assignment_waiting_next_time"] = function()
		P.useSkillCosts()

		local spies = P.spyStarts()
		local player = P.pilot({ opening = "won", xp = 120000 })

		P.talk(player, { w.choices[1], w.choices[2] })
		lu.assertEquals(P.started(spies), {}, w.name .. ": nothing started")
		lu.assertNil(H.getQuestStatus(player, w.stem .. ":attempted"), w.name .. ": the :attempted key")
		lu.assertEquals(P.firstScreen(player), "assignment_waiting", w.name .. ": the next talk opens the waiting assignment, not training")
	end
end

-- AC-7: the question loops of mission 12 come back to their option sets
function TestBlackEpsilonT2Briefings:test_the_m12_alderaan_and_question_loops_return_to_their_option_sets()
	local t = P.talk(P.pilot(pilotWith(1)), { "s_6d3be6aa", "s_1bbb820a", "s_1bbb820a", "s_69d014bc", "s_cb86c1fc", "s_d6508432", "s_62b8eb46", "s_91f63d81" })
	local brief = { "s_69d014bc", "s_1bbb820a" }
	local questions = { "s_62b8eb46", "s_91f63d81", "s_2c4789b" }

	lu.assertEquals(P.optionSids(t[2]), brief, "m12_brief")
	lu.assertEquals(P.optionSids(t[3]), brief, "m12_alderaan")
	lu.assertEquals(P.optionSids(t[4]), brief, "m12_alderaan again")
	lu.assertEquals(P.optionSids(t[7]), questions, "m12_kill")
	lu.assertEquals(P.optionSids(t[8]), questions, "m12_assassin")
	lu.assertEquals(P.optionSids(t[9]), questions, "m12_escort")
end

---------------------------------------------------------------------------------------------
-- The final
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Final = {}

TestBlackEpsilonT2Final.setUp = setUp

local FINAL_PILOT = { opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } }

-- AC-10: the briefing, the loops and the accept
function TestBlackEpsilonT2Final:test_the_final_offer_walks_to_final_accept_and_starts_assassinate_17()
	local t, player = walk({ pilot = FINAL_PILOT, first = "final_offer", name = "final",
		choices = { "s_9d2c9b0a", "s_7ca4fcb8", "s_17780ca7", "s_dbd8c729" }, starts = { P.A17 } })

	lu.assertEquals(P.ids(t), { "final_offer", "final_surprise", "final_decoy_fighter", "final_decoy", "final_accept" }, "screens shown")
	lu.assertTrue(t[#t].stop, "final_accept ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_17:attempted"), "1", "corellia_imperial_17:attempted")
end

-- AC-10: the loop screens return to their option set
function TestBlackEpsilonT2Final:test_the_final_question_loops_return_to_the_same_four_replies()
	local t = walk({ pilot = FINAL_PILOT, first = "final_offer", name = "final loops", starts = { P.A17 },
		choices = { "s_9d2c9b0a", "s_7ca4fcb8", "s_17780ca7", "s_9cca1500", "s_6ed7de92", "s_83bf02e8", "s_9cca1500", "s_dbd8c729" } })

	lu.assertEquals(P.ids(t), { "final_offer", "final_surprise", "final_decoy_fighter", "final_decoy", "final_ambush", "final_survive", "final_backup", "final_ambush", "final_accept" }, "screens shown")

	for i = 4, 8 do
		lu.assertEquals(P.optionSids(t[i]), { "s_9cca1500", "s_6ed7de92", "s_83bf02e8", "s_dbd8c729" }, t[i].id .. ": the four replies")
	end
end

-- AC-10: nothing starts before final_accept
function TestBlackEpsilonT2Final:test_nothing_starts_before_final_accept()
	local spies = P.spyStarts()
	local player = P.pilot(FINAL_PILOT)

	P.talk(player, { "s_9d2c9b0a", "s_7ca4fcb8", "s_17780ca7", "s_9cca1500" })
	lu.assertEquals(P.started(spies), {}, "quests started")
	lu.assertNil(H.getQuestStatus(player, "corellia_imperial_17:attempted"), "the :attempted key")
end

-- AC-10: the final retry is an ending screen that re-grants on display
function TestBlackEpsilonT2Final:test_the_final_retry_ends_and_regrants_assassinate_17()
	local o = {}

	for k, v in pairs(FINAL_PILOT) do
		o[k] = v
	end

	o.mission = { final = "failed" }

	local t = walk({ pilot = o, first = "final_retry", choices = {}, starts = { P.A17 }, name = "final retry" })

	lu.assertTrue(t[1].stop, "final_retry ends the conversation")
end

-- AC-10: the survival won opens tour_complete, whose replies lead to dismissed and the duty menu
function TestBlackEpsilonT2Final:test_tour_complete_leads_to_dismissed_and_to_the_duty_menu()
	local pilot = { opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "won" } }
	local t = walk({ pilot = pilot, first = "tour_complete", choices = { "s_79375065" }, name = "tour complete: dismissed" })

	lu.assertEquals(P.ids(t), { "tour_complete", "dismissed" }, "screens shown")
	lu.assertTrue(t[2].stop, "dismissed ends the conversation")
	lu.assertEquals(P.optionSids(t[1]), { "s_79375065", "s_d335136f" }, "tour_complete replies")
	lu.assertEquals(P.linksOf(t[1]), { "dismissed", "duty_menu" }, "tour_complete links")

	local t2 = walk({ pilot = pilot, first = "tour_complete", choices = { "s_d335136f" }, name = "tour complete: duty menu" })

	lu.assertEquals(P.ids(t2), { "tour_complete", "duty_menu" }, "screens shown")
end

-- AC-10: the report names the pilot's tour result without granting anything
function TestBlackEpsilonT2Final:test_tour_complete_pays_and_grants_nothing()
	local spies = P.spyStarts()
	local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "won" } })

	P.talk(player, { "s_79375065" })
	lu.assertEquals(P.started(spies), {}, "quests started")
	lu.assertEquals(player.bankCredits, 0, "the final mission pays nothing (FP-6)")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(player.ghost.factionStanding.imperial, 0, "no standing")
end

---------------------------------------------------------------------------------------------
-- Duty menus, on_mission, the opening_done screen
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Duties = {}

TestBlackEpsilonT2Duties.setUp = setUp

local DUTY_REPLIES = {
	{ reply = "s_bd5df827", screen = "duty_pirates", global = P.DUTY8 },
	{ reply = "s_798fbe2", screen = "duty_merchant", global = P.DUTY9 },
	{ reply = "s_1a0f022", screen = "duty_rebels", global = P.DUTY10 },
	{ reply = "s_3e38e6a0", screen = "duty_security", global = P.DUTY11 },
}

-- AC-7, D-9: opening_done -> duty menu -> a duty, which starts on display and ends
function TestBlackEpsilonT2Duties:test_opening_done_leads_through_the_duty_menu_to_each_duty()
	for _, d in ipairs(DUTY_REPLIES) do
		H.reset()

		local spies = P.spyStarts()
		local t = P.talk(P.pilot({ opening = "won" }), { "s_d335136f", d.reply })

		lu.assertEquals(P.ids(t), { "opening_done", "duty_menu", d.screen }, d.screen .. ": screens shown")
		lu.assertTrue(t[3].stop, d.screen .. " ends the conversation (D-9)")
		lu.assertEquals(P.started(spies), { d.global }, d.screen .. ": the duty started on display")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, d.screen .. ": client strings")
	end
end

-- AC-7: the other reply of opening_done
function TestBlackEpsilonT2Duties:test_opening_done_other_matters_ends_without_a_start()
	local t = walk({ pilot = { opening = "won" }, first = "opening_done", choices = { "s_25c6e073" }, name = "other matters" })

	lu.assertEquals(P.ids(t), { "opening_done", "other_matters" }, "screens shown")
	lu.assertTrue(t[2].stop, "other_matters ends the conversation")
end

-- AC-7: the tour_complete duty menu starts a duty too
function TestBlackEpsilonT2Duties:test_the_duty_menu_after_the_tour_starts_each_duty()
	for _, d in ipairs(DUTY_REPLIES) do
		H.reset()

		local spies = P.spyStarts()
		local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "won" } })
		local t = P.talk(player, { "s_d335136f", d.reply })

		lu.assertEquals(P.ids(t), { "tour_complete", "duty_menu", d.screen }, d.screen .. ": screens shown")
		lu.assertEquals(P.started(spies), { d.global }, d.screen .. ": the duty started")
	end
end

-- AC-7: on_mission -> hyperdrive
function TestBlackEpsilonT2Duties:test_on_mission_leads_to_the_hyperdrive_line_and_ends()
	local t = walk({ pilot = { opening = "active" }, first = "on_mission", choices = { "s_5ffdd434" }, name = "on mission" })

	lu.assertEquals(P.ids(t), { "on_mission", "hyperdrive" }, "screens shown")
	lu.assertTrue(t[2].stop, "hyperdrive ends the conversation")
end

-- AC-7 (Appendix A): the screens that are not start, reward or duty screens grant nothing when shown
function TestBlackEpsilonT2Duties:test_no_other_screen_starts_a_quest_or_sets_a_mission_key_when_shown()
	local active = {}

	for _, s in ipairs(STARTS) do
		active[s.screen] = true
	end

	for _, d in ipairs(DUTY_REPLIES) do
		active[d.screen] = true
	end

	for _, m in ipairs(P.MISSIONS) do
		active[m.reward] = true
	end

	for _, row in ipairs(P.SCREENS) do
		if not active[row.id] then
			H.reset()

			local spies = P.spyStarts()
			local player = P.pilot({ opening = "won", t2 = { 1 }, xp = 0 })
			local ok, err = pcall(P.drive, player, row.id)

			lu.assertTrue(ok, "showing '" .. row.id .. "' raised a Lua error: " .. tostring(err))
			lu.assertEquals(P.started(spies), {}, "showing '" .. row.id .. "' started a quest")
			lu.assertEquals(#P.free() + #P.bought(), 0, "showing '" .. row.id .. "' granted a skill")
			lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "showing '" .. row.id .. "' gave an item")
			lu.assertEquals(player.bankCredits, 0, "showing '" .. row.id .. "' paid credits")
		end
	end
end
