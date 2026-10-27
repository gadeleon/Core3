-- Black Epsilon tier 2: surrendering the pilot profession clears Prisk's progress (resetPriskQuests), after Hakassha's.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Prisk again.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

P.load()

local TIER1_STORY = { B.P1, B.S1, B.M2, B.E3, B.A4 }

-- A graduate who carries every kind of Prisk and Hakassha state: the 8 tier 2 story entries complete, the 10 tier 2 keys, the tier 1 state,
-- all eight skills, pilot tier 3
local function veteran()
	local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, mission = { final = "won" }, pilotTier = 3, prisk = true })

	for _, key in ipairs(P.KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	for _, global in ipairs(TIER1_STORY) do
		B.setState(player, global, "complete")
	end

	for _, key in ipairs(B.STATUS_NAMES) do
		H.setQuestStatus(player, key .. ":attempted", "1")
		H.setQuestStatus(player, key .. ":reward", "1")
	end

	return player
end

TestBlackEpsilonT2Surrender = {}

function TestBlackEpsilonT2Surrender:setUp()
	H.reset()
	P.load()
end

-- AC-11 (the setup itself)
function TestBlackEpsilonT2Surrender:test_the_setup_carries_every_kind_of_state()
	local player = veteran()

	for _, global in ipairs(P.STORY) do
		lu.assertEquals(P.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(P.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": tier 1 journal state")
	end

	lu.assertEquals(#P.held(player), 4, "tier 2 skills")
	lu.assertEquals(H.getQuestStatus(player, P.SERIES_SUFFIX), "1", "series flag")
	lu.assertEquals(#P.STORY, 8, "tier 2 story entries")
	lu.assertEquals(#P.KEYS, 10, "tier 2 keys")
end

-- AC-11
function TestBlackEpsilonT2Surrender:test_surrendering_clears_the_eight_tier_2_journal_entries()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(P.STORY) do
		lu.assertEquals(P.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestBlackEpsilonT2Surrender:test_surrendering_clears_active_runs()
	local player = P.pilot({ opening = "won", mission = { [4] = "active" } })

	P.setState(player, P.S15, "active")
	P.setState(player, P.FINAL, "active")
	P.setState(player, P.OPENING, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(P.STORY) do
		lu.assertEquals(P.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestBlackEpsilonT2Surrender:test_surrendering_removes_the_ten_tier_2_status_keys()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(P.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11: the tier 1 reset still runs
function TestBlackEpsilonT2Surrender:test_surrendering_still_clears_all_tier_1_state()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for _, key in ipairs(B.STATUS_NAMES) do
		lu.assertNil(H.getQuestStatus(player, key .. ":attempted"), key .. ":attempted")
		lu.assertNil(H.getQuestStatus(player, key .. ":reward"), key .. ":reward")
	end

	lu.assertNil(H.getQuestStatus(player, P.SERIES_SUFFIX), "series flag after the surrender")
	lu.assertNil(H.getQuestStatus(player, P.PRISK_SUFFIX), "Prisk flag after the surrender")
end

-- AC-11
function TestBlackEpsilonT2Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestBlackEpsilonT2Surrender:test_the_next_talk_opens_not_pilot()
	P.requireConversation(lu)

	local player = veteran()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = P.talk(player)

	lu.assertEquals(P.ids(t), { "not_pilot" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Prisk state
function TestBlackEpsilonT2Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = P.pilot({ tier1 = 0, pilotTier = 1, series = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestBlackEpsilonT2Surrender:test_surrendering_twice_is_harmless()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Black Epsilon pilots only, after the tier 1 reset
function TestBlackEpsilonT2Surrender:test_only_a_black_epsilon_pilot_triggers_the_prisk_reset_and_it_follows_the_hakassha_reset()
	local order = {}

	H.spyOn(BlackEpsilonSquadronScreenplay, "resetHakasshaQuests", function() order[#order + 1] = "hakassha" end)

	local reset = H.spyOn(BlackEpsilonSquadronScreenplay, "resetPriskQuests", function() order[#order + 1] = "prisk" end)
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(P.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetPriskQuests calls for CorSec, RSF and Havoc pilots")
	lu.assertEquals(order, {}, "no Black Epsilon reset for them at all")

	local player = P.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetPriskQuests calls for a Black Epsilon pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "hakassha", "prisk" }, "the order of the two resets")
end

-- AC-11: the other squadrons' keys survive
function TestBlackEpsilonT2Surrender:test_a_black_epsilon_reset_leaves_other_squadrons_keys_alone()
	local player = veteran()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
end

-- AC-11: the reset is directly callable
function TestBlackEpsilonT2Surrender:test_resetPriskQuests_clears_tier_2_without_touching_skills_or_tier_1()
	local player = veteran()

	BlackEpsilonSquadronScreenplay:resetPriskQuests(player)

	for _, global in ipairs(P.STORY) do
		lu.assertEquals(P.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(P.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#P.held(player), 4, "skills are the surrender's business, not the reset's")

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": tier 1 journal state stays")
	end

	for _, key in ipairs(B.STATUS_NAMES) do
		lu.assertEquals(H.getQuestStatus(player, key .. ":reward"), "1", key .. ":reward stays")
	end

	lu.assertEquals(H.getQuestStatus(player, P.SERIES_SUFFIX), "1", "series flag stays")
	lu.assertEquals(H.getQuestStatus(player, P.PRISK_SUFFIX), "1", "Prisk flag stays")
end

-- AC-11, Content contract 2: resetQuest runs on the 8 story tables, not on the duties
function TestBlackEpsilonT2Surrender:test_resetPriskQuests_resets_the_eight_story_tables_and_not_the_duties()
	local spies = {}

	for _, global in ipairs(P.GLOBALS) do
		spies[global] = H.spyOn(P.quest(global), "resetQuest")
	end

	BlackEpsilonSquadronScreenplay:resetPriskQuests(P.pilot({}))

	for _, global in ipairs(P.STORY) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
	end

	for _, global in ipairs(P.DUTIES) do
		lu.assertEquals(#spies[global], 0, global .. ": resetQuest calls (the duties are not reset)")
	end
end

-- AC-11, Content contract 2: no new flag key and nothing else is removed
function TestBlackEpsilonT2Surrender:test_resetPriskQuests_removes_only_the_ten_keys()
	local player = P.pilot({})

	H.setQuestStatus(player, "corellia_imperial_16:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_17:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_12:somethingElse", "1")
	BlackEpsilonSquadronScreenplay:resetPriskQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_16:reward"), "1", "corellia_imperial_16:reward is not one of the ten")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_17:reward"), "1", "corellia_imperial_17:reward is not one of the ten")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_12:somethingElse"), "1", "an unrelated key stays")
end
