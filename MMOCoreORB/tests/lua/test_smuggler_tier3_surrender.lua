-- Smuggler tier 3: surrendering the pilot profession clears Beissa's progress (resetBeissaQuests).
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Beissa again.

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local M = require("smuggler_tier2_data")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

B.load()

local KEYS = B.statusKeys()

-- the squadron object with resetBeissaQuests, or a failure that says the reset is missing
local function squadron()
	local sq = B.squadron()

	lu.assertEquals(type(sq.resetBeissaQuests), "function", "SmugglerSquadronScreenplay:resetBeissaQuests is not defined")

	return sq
end

-- A graduate who carries every kind of Beissa state: the 17 tables complete, 8 status keys, the 4 tier 3 skills, pilot tier 4 (plus tier 1, the transition and tier 2)
local function graduate()
	return B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, pilotTier = 4 })
end

TestSmugglerT3Surrender = {}

function TestSmugglerT3Surrender:setUp()
	H.reset()
	B.load()
end

-- AC-11 (the setup itself)
function TestSmugglerT3Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#B.held(player), 4, "tier 3 skills")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron")
end

-- AC-11
function TestSmugglerT3Surrender:test_surrendering_clears_the_17_journal_entries()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestSmugglerT3Surrender:test_surrendering_clears_active_runs()
	local player = B.pilot({ mission = { [1] = "active", [2] = "partial", [3] = "won" } })

	B.setState(player, B.GLOBALS[17], "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestSmugglerT3Surrender:test_surrendering_removes_the_eight_status_keys()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11
function TestSmugglerT3Surrender:test_surrendering_removes_the_neutral_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.neutralPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk opens not_neutral
function TestSmugglerT3Surrender:test_the_next_talk_opens_not_neutral()
	B.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = B.talk(player)

	lu.assertEquals(B.ids(t), { "not_neutral" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_neutral ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: the reset is called once, after Shamdon's reset, while the skills are still held, and each table's resetQuest runs once
function TestSmugglerT3Surrender:test_surrender_calls_resetBeissaQuests_once_after_the_shamdon_reset_while_the_skills_are_still_held()
	local sq = squadron()
	local order = {}

	H.spyOn(sq, "resetDravisQuests", function() order[#order + 1] = "dravis" end)
	H.spyOn(sq, "resetKarrdeQuests", function() order[#order + 1] = "karrde" end)
	H.spyOn(sq, "resetShamdonQuests", function() order[#order + 1] = "shamdon" end)

	local reset = H.spyOn(sq, "resetBeissaQuests", function(_, p)
		order[#order + 1] = "beissa"

		return CreatureObject(p):hasSkill(S.NOVICE)
	end)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	lu.assertEquals(#reset, 1, "resetBeissaQuests calls for a Smuggler pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "dravis", "karrde", "shamdon", "beissa" }, "resetDravisQuests, resetKarrdeQuests, resetShamdonQuests, then resetBeissaQuests")
	lu.assertTrue(reset[1].snapshot, "the novice box is still held when resetBeissaQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(S.NOVICE), "and gone afterwards")
end

-- AC-11: only a Smuggler triggers it
function TestSmugglerT3Surrender:test_only_a_smuggler_triggers_the_beissa_reset()
	local sq = squadron()
	local reset = H.spyOn(sq, "resetBeissaQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(S.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetBeissaQuests calls for CorSec, RSF, Havoc and Black Epsilon pilots")
end

-- AC-11: the other squadrons' surrender is as before: their keys survive a Smuggler's
function TestSmugglerT3Surrender:test_a_smuggler_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "naboo_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:reward"), "1", "RSF's key")
end

-- AC-11: surrendering still clears Dravis', Karrde's and Shamdon's progress
function TestSmugglerT3Surrender:test_surrender_still_clears_dravis_karrde_and_shamdon_progress()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(S.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Dravis' key " .. key)
	end

	for _, key in ipairs(M.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Shamdon's key " .. key)
	end

	lu.assertNil(H.getQuestStatus(player, T.ATTEMPTED), "Karrde's :attempted key")
	lu.assertNil(H.getQuestStatus(player, T.REWARD), "Karrde's :reward key")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", "Karrde's assassinate journal entry")

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(player, global), "none", "Shamdon's " .. global)
	end
end

-- AC-11: no state at all, and twice
function TestSmugglerT3Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = B.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11, Content contract 2: the reset is directly callable, resets each table once, and touches neither skills, tier, tier 1 keys, the transition keys nor tier 2
function TestSmugglerT3Surrender:test_resetBeissaQuests_resets_the_17_tables_and_clears_without_touching_skills_or_older_tiers()
	local sq = squadron()
	local resets = {}

	for _, global in ipairs(B.GLOBALS) do
		resets[global] = H.spyOn(B.quest(global), "resetQuest")
	end

	local player = graduate()

	sq:resetBeissaQuests(player)

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(resets[global][1].args[1], player, global .. ": resetQuest gets the pilot")
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#B.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 4, "so is the pilot tier")
	lu.assertEquals(H.getQuestStatus(player, T.REWARD), "1", "the transition :reward key is Karrde's reset's business")

	for _, key in ipairs(M.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Shamdon's key " .. key)
	end

	for _, global in ipairs(M.HEADS) do
		lu.assertEquals(M.state(player, global), "complete", "Shamdon's " .. global)
	end

	for _, key in ipairs(S.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Dravis' key " .. key)
	end
end

-- AC-11: the reset does not touch another player's state
function TestSmugglerT3Surrender:test_resetBeissaQuests_is_per_player()
	local a, b = graduate(), graduate()

	squadron():resetBeissaQuests(a)

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(b, key), "1", "other pilot's " .. key)
	end

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(B.state(b, global), "complete", "other pilot's " .. global)
	end
end

-- AC-11: a running mission is aborted by the reset (resetQuest of the real table)
function TestSmugglerT3Surrender:test_resetBeissaQuests_stops_a_running_mission()
	local q = B.quest(B.GLOBALS[13])

	q:start()

	local player = B.pilot({ zone = q.questZone, inShip = true })

	q:startQuest(player, "")
	H.advance(0)
	lu.assertEquals(B.state(player, B.GLOBALS[13]), "active", "precondition: the patrol runs")
	squadron():resetBeissaQuests(player)
	H.advance(0)
	lu.assertEquals(B.state(player, B.GLOBALS[13]), "none", B.GLOBALS[13] .. ": journal state")
end
