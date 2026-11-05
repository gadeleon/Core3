-- Inquisition tier 1: surrendering the pilot profession clears Barn's progress (resetBarnQuests).
-- Spec: .claude/work/inquisition-tier1-barn-sinkko/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes; D-15).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Barn again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local I = require("inquisition_tier1_data")
local CS = require("harness.client_strings")

M.load()
I.load()

local JOURNAL = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }
local KEYS = {}

for n = 1, 4 do
	KEYS[#KEYS + 1] = "naboo_imperial_" .. n .. ":attempted"
	KEYS[#KEYS + 1] = "naboo_imperial_" .. n .. ":reward"
end

KEYS[#KEYS + 1] = I.ABORTED_SUFFIX
KEYS[#KEYS + 1] = I.SERIES_SUFFIX

-- A graduate who carries every kind of Barn state: the six story entries complete, a duty complete and one active, 8 status keys, the aborted
-- marker, the series flag, four skills, pilot tier 2
local function graduate()
	local player = I.pilot({ paid = 4, tier = 4, series = true, aborted = true, pilotTier = 2 })

	I.setState(player, I.DUTY6, "active")
	I.setState(player, I.DUTY7, "complete")

	return player
end

TestInquisitionT1Surrender = {}

function TestInquisitionT1Surrender:setUp()
	H.reset()
	I.load()
end

-- AC-11 (the setup itself)
function TestInquisitionT1Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), global == I.DUTY6 and "active" or "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#I.held(player), 4, "tier 1 skills")
end

-- AC-11
function TestInquisitionT1Surrender:test_surrendering_clears_the_eight_journal_entries_complete_or_active()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestInquisitionT1Surrender:test_surrendering_clears_active_runs_of_both_split_chains()
	local player = I.pilot({ paid = 1, state = "active" })

	I.setState(player, I.S1, "active")
	I.setState(player, I.E3, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestInquisitionT1Surrender:test_surrendering_removes_the_eight_status_keys_the_aborted_marker_and_the_series_flag()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11
function TestInquisitionT1Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestInquisitionT1Surrender:test_the_next_talk_opens_recruitment_and_the_pilot_can_sign_up_again()
	I.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = I.talk(player, { "s_b00e89d5" })

	lu.assertEquals(t[1].id, "recruitment", "first screen after the surrender")
	lu.assertEquals(t[2].id, "recruit_sign_up", "the sign-up starts over")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: mission 2's aborted marker does not survive a surrender into a new career
function TestInquisitionT1Surrender:test_a_new_career_starts_mission_2_without_the_old_aborted_marker()
	I.requireConversation(lu)

	local player = I.pilot({ paid = 1, state = "aborted" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), "marker")
end

-- AC-11: a pilot with no Barn state
function TestInquisitionT1Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = I.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestInquisitionT1Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Inquisition pilots only
function TestInquisitionT1Surrender:test_only_an_inquisition_pilot_triggers_the_barn_reset()
	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(I.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetBarnQuests calls for CorSec, RSF, Havoc, Black Epsilon and Storm pilots")

	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetBarnQuests calls for an Inquisition pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: Declann's reset still runs once, after Barn's
function TestInquisitionT1Surrender:test_declanns_reset_still_runs_once_after_barns()
	local order = {}

	H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests", function() order[#order + 1] = "barn" end)

	local declann = H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#declann, 1, "resetDeclannQuests calls")
	lu.assertEquals(order, { "barn", "declann" }, "the order of the resets")
end

-- AC-11: the other squadrons still reset as before (spot check; the full suites are the per-squadron surrender tests)
function TestInquisitionT1Surrender:test_a_barn_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
end

-- AC-11: the reset is directly callable like Hakassha's, leaves skills and the tier 2 agent key alone
function TestInquisitionT1Surrender:test_resetBarnQuests_clears_without_touching_skills_or_the_agent_flag()
	local player = graduate()

	H.setQuestStatus(player, I.AGENT_SUFFIX, "1")
	lu.assertEquals(type(InquisitionSquadronScreenplay.resetBarnQuests), "function", "InquisitionSquadronScreenplay:resetBarnQuests is not defined")
	InquisitionSquadronScreenplay:resetBarnQuests(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), "1", "the tier 2 agent flag is tier 2's reset")
	lu.assertEquals(#I.held(player), 4, "skills are the surrender's business, not the reset's")
end

-- AC-11: resetBarnQuests resets the quests through their own resetQuest (every table is asked once)
function TestInquisitionT1Surrender:test_resetBarnQuests_calls_resetQuest_on_all_eight_tables()
	local spies = {}

	for _, g in ipairs(JOURNAL) do
		spies[g] = H.spyOn(I.quest(g), "resetQuest")
	end

	local player = graduate()

	InquisitionSquadronScreenplay:resetBarnQuests(player)

	for _, g in ipairs(JOURNAL) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end
