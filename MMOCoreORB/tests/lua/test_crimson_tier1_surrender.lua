-- Crimson Phoenix tier 1: surrendering the pilot profession clears Da'la Socuna's progress (resetSocunaQuests).
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes; Migration of tests).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Da'la Socuna again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

M.load()
I.load()

local JOURNAL = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }
local KEYS = {}

for n = 1, 4 do
	KEYS[#KEYS + 1] = I.statusName(n) .. ":attempted"
	KEYS[#KEYS + 1] = I.statusName(n) .. ":reward"
end

KEYS[#KEYS + 1] = I.EKER_PILOT_KEY

-- A graduate who carries every kind of Da'la Socuna state: the six story entries complete, a duty complete and one active, 8 status keys,
-- the graduation key, four skills and pilot tier 2
local function graduate()
	local player = I.pilot({ paid = 4, tier = 4, graduated = true, pilotTier = 2 })

	I.setState(player, I.DUTY6, "active")
	I.setState(player, I.DUTY7, "complete")

	return player
end

-- a red run reads "resetSocunaQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetSocunaQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetSocunaQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing. Load problems: " .. table.concat(I.loadErrors, " | "))
end

TestCrimsonT1Surrender = {}

function TestCrimsonT1Surrender:setUp()
	H.reset()
	I.load()
end

-- AC-11 (the setup itself)
function TestCrimsonT1Surrender:test_the_setup_carries_every_kind_of_state()
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
function TestCrimsonT1Surrender:test_surrendering_clears_the_eight_journal_entries_complete_or_active()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestCrimsonT1Surrender:test_surrendering_clears_active_runs_of_both_split_chains()
	requireReset()

	local player = I.pilot({ paid = 1, state = "active" })

	I.setState(player, I.S1, "active")
	I.setState(player, I.E3, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestCrimsonT1Surrender:test_surrendering_removes_the_eight_status_keys_and_the_graduation_key()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11
function TestCrimsonT1Surrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestCrimsonT1Surrender:test_the_next_talk_opens_recruitment_and_the_pilot_can_sign_up_again()
	requireReset()
	I.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = I.talk(player, { "s_78679b31" })

	lu.assertEquals(t[1].id, "recruitment", "first screen after the surrender (a Rebel-faction non-pilot)")
	lu.assertEquals(t[2].id, "recruit_fun", "the sign-up starts over")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Da'la Socuna state
function TestCrimsonT1Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = I.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestCrimsonT1Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Crimson Phoenix pilots only
function TestCrimsonT1Surrender:test_only_a_crimson_phoenix_pilot_triggers_the_socuna_reset()
	requireReset()

	local reset = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "VORTEX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(I.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetSocunaQuests calls for CorSec, RSF, Havoc, Vortex, Black Epsilon, Inquisition and Storm pilots")

	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetSocunaQuests calls for a Crimson Phoenix pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: Burke's reset still runs once, after Socuna's
function TestCrimsonT1Surrender:test_burkes_reset_still_runs_once_after_socunas()
	requireReset()

	local order = {}

	H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests", function() order[#order + 1] = "socuna" end)

	local burke = H.spyOn(M.mts(), "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#burke, 1, "resetBurkeQuests calls")
	lu.assertEquals(order, { "socuna", "burke" }, "the order of the resets")
end

-- AC-11: the other squadrons still reset as before (spot check; the full suites are the per-squadron surrender tests)
function TestCrimsonT1Surrender:test_a_socuna_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_imperial_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:reward"), "1", "Inquisition's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
end

-- AC-11: the reset is directly callable; it leaves skills and the pilot tier alone (the surrender's business)
function TestCrimsonT1Surrender:test_resetSocunaQuests_clears_without_touching_skills_or_the_pilot_tier()
	requireReset()

	local player = graduate()

	CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#I.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is the surrender's business too")
end

-- AC-11: resetSocunaQuests resets the quests through their own resetQuest (every table is asked once)
function TestCrimsonT1Surrender:test_resetSocunaQuests_calls_resetQuest_on_all_eight_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(JOURNAL) do
		spies[g] = H.spyOn(I.quest(g), "resetQuest")
	end

	local player = graduate()

	CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(player)

	for _, g in ipairs(JOURNAL) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-11: a reset with nothing to reset raises nothing
function TestCrimsonT1Surrender:test_resetSocunaQuests_on_a_fresh_pilot_and_on_nil_raises_nothing()
	requireReset()
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetSocunaQuests, CrimsonPhoenixSquadronScreenplay, I.pilot({})), true, "fresh pilot")
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetSocunaQuests, CrimsonPhoenixSquadronScreenplay, nil), true, "nil")
end

-- AC-11: the surrender must not need a nil guard: a Crimson Phoenix pilot's surrender calls the real reset (the squadron file is loaded by the server)
function TestCrimsonT1Surrender:test_a_crimson_phoenix_pilot_surrender_runs_the_real_reset_and_clears_active_runs()
	requireReset()

	local player = I.pilot({ paid = 1, state = "active" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(I.state(player, I.M2), "none", "the active mission 2 run is cleared")
	lu.assertNil(H.getQuestStatus(player, "tatooine_rebel_1:reward"), "mission 1's reward key")
end
