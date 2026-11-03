-- Smuggler tier 2: surrendering the pilot profession clears Shamdon's progress (resetShamdonQuests).
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-11; Content contract 2 and 4; SC-3).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Shamdon again.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

M.load()

local KEYS = M.statusKeys()

-- A graduate who carries every kind of Shamdon state: the 4 stories and the 3 duties complete, 8 status keys, the 4 skills, pilot tier 3
local function graduate()
	local player = M.pilot({ all4 = true, pilotTier = 3, met = true })

	for _, global in ipairs(M.DUTIES) do
		M.setState(player, global, "complete")
	end

	return player
end

TestSmugglerT2Surrender = {}

function TestSmugglerT2Surrender:setUp()
	H.reset()
	M.load()
end

-- AC-11 (the setup itself)
function TestSmugglerT2Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#M.held2(player), 4, "tier 2 skills")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron")
end

-- AC-11
function TestSmugglerT2Surrender:test_surrendering_clears_the_seven_journal_entries()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestSmugglerT2Surrender:test_surrendering_clears_active_runs()
	local player = M.pilot({ tier2 = 2, missions = { [1] = "active" }, duty2 = M.DUTY_RECOVERY })

	M.setState(player, M.E4, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestSmugglerT2Surrender:test_surrendering_removes_the_eight_status_keys()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11: the transition's :reward key goes with Karrde's reset (it is Shamdon's to write, Karrde's to clear)
function TestSmugglerT2Surrender:test_surrendering_removes_the_transition_reward_key_the_delivery_wrote()
	local player = graduate()

	lu.assertEquals(H.getQuestStatus(player, T.REWARD), "1", "precondition: the delivery key")
	SpaceHelpers:surrenderPilot(player)
	lu.assertNil(H.getQuestStatus(player, T.REWARD), "tat_priv_quest_trans:reward after the surrender")
end

-- AC-11
function TestSmugglerT2Surrender:test_surrendering_removes_the_neutral_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.neutralPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestSmugglerT2Surrender:test_the_next_talk_opens_not_pilot()
	M.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = M.talk(player)

	lu.assertEquals(M.ids(t), { "not_pilot" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: the reset is called once, after Karrde's reset, while the skills are still held, and each table's resetQuest runs once
function TestSmugglerT2Surrender:test_surrender_calls_resetShamdonQuests_once_after_the_karrde_reset_while_the_skills_are_still_held()
	local sq = M.squadron()
	local order = {}

	H.spyOn(sq, "resetDravisQuests", function() order[#order + 1] = "dravis" end)
	H.spyOn(sq, "resetKarrdeQuests", function() order[#order + 1] = "karrde" end)

	local reset = H.spyOn(sq, "resetShamdonQuests", function(_, p)
		order[#order + 1] = "shamdon"

		return CreatureObject(p):hasSkill(S.NOVICE)
	end)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	lu.assertEquals(#reset, 1, "resetShamdonQuests calls for a Smuggler pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "dravis", "karrde", "shamdon" }, "resetDravisQuests, resetKarrdeQuests, then resetShamdonQuests")
	lu.assertTrue(reset[1].snapshot, "the novice box is still held when resetShamdonQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(S.NOVICE), "and gone afterwards")
end

-- AC-11: only a Smuggler triggers it
function TestSmugglerT2Surrender:test_only_a_smuggler_triggers_the_shamdon_reset()
	local sq = M.squadron()
	local reset = H.spyOn(sq, "resetShamdonQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(S.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetShamdonQuests calls for CorSec, RSF, Havoc and Black Epsilon pilots")
end

-- AC-11: the other squadrons' surrender is as before: their keys survive a Smuggler's
function TestSmugglerT2Surrender:test_a_smuggler_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "naboo_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:reward"), "1", "RSF's key")
end

-- AC-11: surrendering still clears Dravis' and Karrde's progress
function TestSmugglerT2Surrender:test_surrender_still_clears_dravis_and_karrde_progress()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(S.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Dravis' key " .. key)
	end

	lu.assertNil(H.getQuestStatus(player, T.ATTEMPTED), "Karrde's :attempted key")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", "Karrde's assassinate journal entry")
end

-- AC-11: no state at all, and twice
function TestSmugglerT2Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = M.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11, Content contract 2: the reset is directly callable, resets each table once, and touches neither skills, tier, tier 1 keys nor the transition keys
function TestSmugglerT2Surrender:test_resetShamdonQuests_resets_the_seven_tables_and_clears_without_touching_skills_tier_1_or_the_transition()
	local sq = M.squadron()
	local resets = {}

	for _, global in ipairs(M.GLOBALS) do
		resets[global] = H.spyOn(M.quest(global), "resetQuest")
	end

	local player = graduate()

	sq:resetShamdonQuests(player)

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(resets[global][1].args[1], player, global .. ": resetQuest gets the pilot")
		lu.assertEquals(M.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#M.held2(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 3, "so is the pilot tier")
	lu.assertEquals(H.getQuestStatus(player, T.REWARD), "1", "the transition :reward key is Karrde's reset's business")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "complete", "so is the transition's journal entry")

	for _, key in ipairs(S.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Dravis' key " .. key)
	end

	lu.assertTrue(S.met(player), "met-Dravis key")
end

-- AC-11: the reset does not touch another player's state
function TestSmugglerT2Surrender:test_resetShamdonQuests_is_per_player()
	local a, b = graduate(), graduate()

	M.squadron():resetShamdonQuests(a)

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(b, key), "1", "other pilot's " .. key)
	end

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(b, global), "complete", "other pilot's " .. global)
	end
end

-- AC-11: a running mission is aborted by the reset (resetQuest of the real table)
function TestSmugglerT2Surrender:test_resetShamdonQuests_stops_a_running_duty()
	local q = M.quest(M.DUTY_DESTROY)

	q:start()

	local player = M.pilot({ zone = q.questZone, inShip = true })

	q:startQuest(player, "")
	H.advance(0)
	lu.assertEquals(M.state(player, M.DUTY_DESTROY), "active", "precondition: the duty runs")
	M.squadron():resetShamdonQuests(player)
	H.advance(0)
	lu.assertEquals(M.state(player, M.DUTY_DESTROY), "none", M.DUTY_DESTROY .. ": journal state")
end
