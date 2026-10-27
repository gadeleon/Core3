-- Black Epsilon tier 1: surrendering the pilot profession clears Hakassha's progress (resetHakasshaQuests).
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Hakassha again.

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

B.load()

local STORY = { B.P1, B.S1, B.M2, B.E3, B.A4 }
local KEYS = {}

for n = 1, 4 do
	KEYS[#KEYS + 1] = "corellia_imperial_" .. n .. ":attempted"
	KEYS[#KEYS + 1] = "corellia_imperial_" .. n .. ":reward"
end

-- A graduate who carries every kind of Hakassha state: the 5 story entries complete, 8 status keys, both flags, four skills, pilot tier 2
local function graduate()
	return B.pilot({ paid = 4, tier = 4, series = true, prisk = true, pilotTier = 2 })
end

TestBlackEpsilonT1Surrender = {}

function TestBlackEpsilonT1Surrender:setUp()
	H.reset()
	B.load()
end

-- AC-11 (the setup itself)
function TestBlackEpsilonT1Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(STORY) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(H.getQuestStatus(player, B.SERIES_SUFFIX), "1", "series flag")
	lu.assertEquals(H.getQuestStatus(player, B.PRISK_SUFFIX), "1", "Prisk flag")
	lu.assertEquals(#B.held(player), 4, "tier 1 skills")
end

-- AC-11
function TestBlackEpsilonT1Surrender:test_surrendering_clears_the_five_story_journal_entries()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(STORY) do
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestBlackEpsilonT1Surrender:test_surrendering_clears_active_runs()
	local player = B.pilot({ paid = 1, state = "active" })

	B.setState(player, B.S1, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(STORY) do
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestBlackEpsilonT1Surrender:test_surrendering_removes_the_eight_status_keys_and_both_flags()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, B.SERIES_SUFFIX), "series flag after the surrender")
	lu.assertNil(H.getQuestStatus(player, B.PRISK_SUFFIX), "Prisk flag after the surrender")
end

-- AC-11
function TestBlackEpsilonT1Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestBlackEpsilonT1Surrender:test_the_next_talk_opens_recruitment_and_the_pilot_can_sign_up_again()
	B.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = B.talk(player, { "s_11bb9c43" })

	lu.assertEquals(t[1].id, "recruitment", "first screen after the surrender")
	lu.assertEquals(t[2].id, "recruit_pilot", "the sign-up starts over")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Hakassha state
function TestBlackEpsilonT1Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = B.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestBlackEpsilonT1Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Black Epsilon pilots only
function TestBlackEpsilonT1Surrender:test_only_a_black_epsilon_pilot_triggers_the_hakassha_reset()
	local reset = H.spyOn(BlackEpsilonSquadronScreenplay, "resetHakasshaQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(B.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetHakasshaQuests calls for CorSec, RSF and Havoc pilots")

	local player = B.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetHakasshaQuests calls for a Black Epsilon pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: the other squadrons still reset as before (spot check; the full suites are test_trainer_fixes_reset.lua and the surrender tests)
function TestBlackEpsilonT1Surrender:test_a_black_epsilon_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
end

-- AC-11: the reset is directly callable like Kreezo's
function TestBlackEpsilonT1Surrender:test_resetHakasshaQuests_clears_without_touching_skills()
	local player = graduate()

	BlackEpsilonSquadronScreenplay:resetHakasshaQuests(player)

	for _, global in ipairs(STORY) do
		lu.assertEquals(B.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#B.held(player), 4, "skills are the surrender's business, not the reset's")
end
