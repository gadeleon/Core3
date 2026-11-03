-- Smuggler transition: surrendering the pilot profession clears Karrde's progress (resetKarrdeQuests, SC-2).
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-8; Content contract 2 and 4; Shared code changes SC-2; D-7).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the server
-- from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Karrde again.

local lu = require("luaunit")
local H = require("harness")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")

T.load()

-- every transition state, with the :reward key on the won one
local STATES = {
	{ "none", { trans = "none" } },
	{ "attempted", { trans = "attempted" } },
	{ "active", { trans = "active" } },
	{ "child_active", { trans = "child_active" } },
	{ "patrol_only", { trans = "patrol_only" } },
	{ "won", { trans = "won" } },
	{ "paid", { trans = "won", rewarded = true } },
}

TestSmugglerTransSurrender = {}

function TestSmugglerTransSurrender:setUp()
	H.reset()
	T.load()
end

-- AC-8 (the setup itself)
function TestSmugglerTransSurrender:test_the_setup_carries_every_kind_of_state()
	local player = T.pilot({ trans = "won", rewarded = true })

	lu.assertEquals(T.state(player, T.PATROL), "complete", T.PATROL .. ": journal state")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "complete", T.ASSASSINATE .. ": journal state")
	lu.assertEquals(H.getQuestStatus(player, T.ATTEMPTED), "1", ":attempted")
	lu.assertEquals(H.getQuestStatus(player, T.REWARD), "1", ":reward")
end

for _, st in ipairs(STATES) do
	-- AC-8: both journal entries and both keys are gone, whatever state the transition was in
	TestSmugglerTransSurrender["test_surrendering_in_the_state_" .. st[1] .. "_clears_both_journal_entries_and_both_keys"] = function()
		local player = T.pilot(st[2])

		SpaceHelpers:surrenderPilot(player)

		for _, global in ipairs(T.GLOBALS) do
			lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender (" .. st[1] .. ")")
		end

		for _, key in ipairs(T.STATUS_KEYS) do
			lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender (" .. st[1] .. ")")
		end
	end
end

-- AC-8: the next talk to Karrde
function TestSmugglerTransSurrender:test_the_next_talk_opens_dravis_employee()
	T.requireConversation(lu)

	for _, st in ipairs(STATES) do
		local player = T.pilot(st[2])

		SpaceHelpers:surrenderPilot(player)
		player.pilot = nil -- the server derives the pilot kind from the skills that are gone

		lu.assertEquals(T.firstScreen(player), "dravis_employee", "first screen after the surrender (" .. st[1] .. ")")
	end
end

-- AC-8: the reset is called once, after Dravis' and before the skills go, and each table's resetQuest runs once
function TestSmugglerTransSurrender:test_surrender_calls_resetKarrdeQuests_once_after_the_dravis_reset_while_the_skills_are_still_held()
	local sq = T.squadron()
	local order = {}

	H.spyOn(sq, "resetDravisQuests", function() order[#order + 1] = "dravis" end)

	local reset = H.spyOn(sq, "resetKarrdeQuests", function(_, p)
		order[#order + 1] = "karrde"

		return CreatureObject(p):hasSkill(S.NOVICE)
	end)

	local player = T.pilot({ trans = "child_active" })

	SpaceHelpers:surrenderPilot(player)

	lu.assertEquals(#reset, 1, "resetKarrdeQuests calls for a Smuggler pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "dravis", "karrde" }, "resetDravisQuests, then resetKarrdeQuests")
	lu.assertTrue(reset[1].snapshot, "the novice box is still held when resetKarrdeQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(S.NOVICE), "and gone afterwards")
end

-- AC-8: only a Smuggler triggers it
function TestSmugglerTransSurrender:test_only_a_smuggler_triggers_the_karrde_reset()
	local sq = T.squadron()
	local reset = H.spyOn(sq, "resetKarrdeQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(S.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetKarrdeQuests calls for CorSec, RSF, Havoc and Black Epsilon pilots")
end

-- AC-8: the other squadrons' surrender is as before: their keys survive a Smuggler's
function TestSmugglerTransSurrender:test_a_smuggler_surrender_leaves_other_squadrons_keys_alone()
	local player = T.pilot({ trans = "won", rewarded = true })

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "naboo_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:reward"), "1", "RSF's key")
end

-- AC-8: surrendering also still clears Dravis' progress
function TestSmugglerTransSurrender:test_surrender_still_clears_dravis_progress()
	local player = T.pilot({ trans = "won", met = true })

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(S.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Dravis' key " .. key)
	end

	lu.assertFalse(S.met(player), "met-Dravis key")
	lu.assertEquals(S.state(player, S.A4), "none", "Dravis' mission 4 journal entry")
end

-- AC-8: no state at all, and twice
function TestSmugglerTransSurrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = T.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-8: the reset is directly callable, resets each table once, and touches neither skills, tier nor tier 1 keys
function TestSmugglerTransSurrender:test_resetKarrdeQuests_resets_the_two_tables_and_clears_without_touching_skills_or_tier_1()
	local sq = T.squadron()
	local resets = {}

	for _, global in ipairs(T.GLOBALS) do
		resets[global] = H.spyOn(T.quest(global), "resetQuest")
	end

	local player = T.pilot({ trans = "won", rewarded = true, met = true })

	sq:resetKarrdeQuests(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(resets[global][1].args[1], player, global .. ": resetQuest gets the pilot")
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(T.STATUS_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#S.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 2, "so is the pilot tier")

	for _, key in ipairs(S.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Dravis' key " .. key)
	end

	lu.assertTrue(S.met(player), "met-Dravis key")
end

-- AC-8: the reset does not touch another player's state
function TestSmugglerTransSurrender:test_resetKarrdeQuests_is_per_player()
	local a, b = T.pilot({ trans = "won", rewarded = true }), T.pilot({ trans = "won", rewarded = true })

	T.squadron():resetKarrdeQuests(a)

	for _, key in ipairs(T.STATUS_KEYS) do
		lu.assertEquals(H.getQuestStatus(b, key), "1", "other pilot's " .. key)
	end

	lu.assertEquals(T.state(b, T.PATROL), "complete", "other pilot's patrol")
	lu.assertEquals(T.state(b, T.ASSASSINATE), "complete", "other pilot's assassinate")
end

-- AC-8: a running chain is aborted by the reset: the wiring drops its observer and waypoint (resetQuest of the real tables)
function TestSmugglerTransSurrender:test_resetKarrdeQuests_stops_a_running_chain_and_removes_its_waypoint()
	H.reset()
	T.quest(T.PATROL):start()

	local player = T.pilot({ zone = T.ZONE, inShip = true })

	T.quest(T.PATROL):startQuest(player, "")
	H.advance(0)
	lu.assertEquals(#player.ghost.waypoints, 1, "precondition: the rendezvous waypoint")
	T.squadron():resetKarrdeQuests(player)
	H.advance(0)
	lu.assertEquals(T.state(player, T.PATROL), "none", T.PATROL .. ": journal state")
	lu.assertEquals(#player.ghost.waypoints, 0, "the waypoint is removed")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, T.PATROL, "enteredZone", player), "the zone observer is dropped")
end
