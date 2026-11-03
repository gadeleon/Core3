-- Smuggler tier 1: surrendering the pilot profession clears Dravis' progress (resetDravisQuests).
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Dravis again.

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

S.load()

local KEYS = S.statusKeys()

-- A graduate who carries every kind of Dravis state: the 10 journal entries complete, 8 status keys, the met key, four skills, pilot tier 2
local function graduate()
	local player = S.pilot({ paid = 4, tier = 4, pilotTier = 2, met = true })

	for _, global in ipairs(S.GLOBALS) do
		S.setState(player, global, "complete")
	end

	return player
end

TestSmugglerT1Surrender = {}

function TestSmugglerT1Surrender:setUp()
	H.reset()
	S.load()
end

-- AC-11 (the setup itself)
function TestSmugglerT1Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(S.GLOBALS) do
		lu.assertEquals(S.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertTrue(S.met(player), "met-Dravis key")
	lu.assertEquals(#S.held(player), 4, "tier 1 skills")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron")
end

-- AC-11
function TestSmugglerT1Surrender:test_surrendering_clears_the_ten_journal_entries()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(S.GLOBALS) do
		lu.assertEquals(S.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestSmugglerT1Surrender:test_surrendering_clears_active_runs()
	local player = S.pilot({ paid = 1, state = "active" })

	S.setState(player, S.S1, "active")
	S.setState(player, S.E3, "active")
	S.setState(player, S.DUTY5, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(S.GLOBALS) do
		lu.assertEquals(S.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestSmugglerT1Surrender:test_surrendering_removes_the_eight_status_keys_and_the_met_key()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertFalse(S.met(player), "met-Dravis key after the surrender")
end

-- AC-11
function TestSmugglerT1Surrender:test_surrendering_removes_the_neutral_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.neutralPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestSmugglerT1Surrender:test_the_next_talk_opens_recruitment_without_the_i_got_a_ship_reply_and_the_pilot_can_sign_up_again()
	S.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = S.talk(player, { "s_900f01d1" })

	lu.assertEquals(t[1].id, "recruitment", "first screen after the surrender")
	lu.assertEquals(S.optionSids(t[1]), { "s_900f01d1", "s_2b595da6", "s_2b691aa0" }, "the met key is gone: no 'I got a ship.'")
	lu.assertEquals(t[2].id, "recruit_kid", "the sign-up starts over")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Dravis state
function TestSmugglerT1Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = S.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestSmugglerT1Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Smuggler pilots only, once
function TestSmugglerT1Surrender:test_only_a_smuggler_triggers_the_dravis_reset()
	local sq = H.expectGlobal("SmugglerSquadronScreenplay", "squadron screenplay object")
	local reset = H.spyOn(sq, "resetDravisQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(S.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetDravisQuests calls for CorSec, RSF, Havoc and Black Epsilon pilots")

	local player = S.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetDravisQuests calls for a Smuggler pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: the reset is called before the skills are surrendered, like every squadron's
function TestSmugglerT1Surrender:test_the_dravis_reset_runs_while_the_pilot_still_holds_the_skills()
	local sq = H.expectGlobal("SmugglerSquadronScreenplay", "squadron screenplay object")
	local held

	H.spyOn(sq, "resetDravisQuests", function(_, p) held = CreatureObject(p):hasSkill(S.NOVICE) end)

	local player = S.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertTrue(held, "the novice box is still held when resetDravisQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(S.NOVICE), "and gone afterwards")
end

-- AC-11: the other squadrons still reset as before (spot check; the full suites are test_trainer_fixes_reset.lua and the surrender tests)
function TestSmugglerT1Surrender:test_a_smuggler_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "naboo_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:reward"), "1", "RSF's key")
end

-- AC-11: the reset is directly callable like Dinge's and clears each table through its own resetQuest
function TestSmugglerT1Surrender:test_resetDravisQuests_resets_the_ten_tables_and_clears_without_touching_skills()
	local sq = H.expectGlobal("SmugglerSquadronScreenplay", "squadron screenplay object")
	local resets = {}

	for _, global in ipairs(S.GLOBALS) do
		resets[global] = H.spyOn(S.quest(global), "resetQuest")
	end

	local player = graduate()

	sq:resetDravisQuests(player)

	for _, global in ipairs(S.GLOBALS) do
		lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(resets[global][1].args[1], player, global .. ": resetQuest gets the pilot")
		lu.assertEquals(S.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertFalse(S.met(player), "met-Dravis key")
	lu.assertEquals(#S.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 2, "so is the pilot tier (surrenderPilot resets it)")
end

-- AC-11: the reset does not touch another player's state
function TestSmugglerT1Surrender:test_resetDravisQuests_is_per_player()
	local a, b = graduate(), graduate()

	SmugglerSquadronScreenplay:resetDravisQuests(a)

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(b, key), "1", "other pilot's " .. key)
	end

	lu.assertTrue(S.met(b), "other pilot's met key")
	lu.assertEquals(S.state(b, S.P1), "complete", "other pilot's journal")
end
