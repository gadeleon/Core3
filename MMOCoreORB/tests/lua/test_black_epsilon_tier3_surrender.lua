-- Black Epsilon tier 3: surrendering the pilot profession clears Haymir's progress (resetHaymirQuests), after Hakassha's and Prisk's.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Haymir again.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local P2 = require("black_epsilon_tier2_data")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

T.load()

local TIER1_STORY = { B.P1, B.S1, B.M2, B.E3, B.A4 }

-- A graduate who carries every kind of state: the 14 tier 3 entries complete, the 8 tier 3 keys, the tier 2 and tier 1 state,
-- all twelve skills, pilot tier 4
local function veteran()
	local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, pilotTier = 4 })

	for _, key in ipairs(T.KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	for _, global in ipairs(P2.STORY) do
		P2.setState(player, global, "complete")
	end

	for _, key in ipairs(P2.KEYS) do
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

TestBlackEpsilonT3Surrender = {}

function TestBlackEpsilonT3Surrender:setUp()
	H.reset()
	T.load()
end

-- AC-11 (the setup itself)
function TestBlackEpsilonT3Surrender:test_the_setup_carries_every_kind_of_state()
	local player = veteran()

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(T.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#T.held(player), 4, "tier 3 skills")
	lu.assertEquals(#T.GLOBALS, 14, "tier 3 journal entries")
	lu.assertEquals(#T.KEYS, 8, "tier 3 keys")
end

-- AC-11
function TestBlackEpsilonT3Surrender:test_surrendering_clears_the_fourteen_tier_3_journal_entries()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too, split children included
function TestBlackEpsilonT3Surrender:test_surrendering_clears_active_runs()
	local player = T.pilot({})

	for _, global in ipairs(T.GLOBALS) do
		T.setState(player, global, "active")
	end

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestBlackEpsilonT3Surrender:test_surrendering_removes_the_eight_tier_3_status_keys()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(T.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11: the tier 1 and tier 2 resets still run
function TestBlackEpsilonT3Surrender:test_surrendering_still_clears_all_tier_1_and_2_state()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(P2.STORY) do
		lu.assertEquals(P2.state(player, global), "none", global .. ": tier 2 journal state after the surrender")
	end

	for _, key in ipairs(P2.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for _, key in ipairs(B.STATUS_NAMES) do
		lu.assertNil(H.getQuestStatus(player, key .. ":attempted"), key .. ":attempted")
		lu.assertNil(H.getQuestStatus(player, key .. ":reward"), key .. ":reward")
	end

	lu.assertNil(H.getQuestStatus(player, T.SERIES_SUFFIX), "series flag after the surrender")
end

-- AC-11
function TestBlackEpsilonT3Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestBlackEpsilonT3Surrender:test_the_next_talk_opens_not_pilot()
	T.requireConversation(lu)

	local player = veteran()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = T.talk(player)

	lu.assertEquals(T.ids(t), { "not_pilot" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Haymir state
function TestBlackEpsilonT3Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = T.pilot({ tier1 = 0, t2 = 0, pilotTier = 1, series = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestBlackEpsilonT3Surrender:test_surrendering_twice_is_harmless()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Black Epsilon pilots only, after the tier 1 and 2 resets
function TestBlackEpsilonT3Surrender:test_only_a_black_epsilon_pilot_triggers_the_haymir_reset_and_it_follows_the_prisk_reset()
	local order = {}

	H.spyOn(BlackEpsilonSquadronScreenplay, "resetHakasshaQuests", function() order[#order + 1] = "hakassha" end)
	H.spyOn(BlackEpsilonSquadronScreenplay, "resetPriskQuests", function() order[#order + 1] = "prisk" end)

	local reset = H.spyOn(BlackEpsilonSquadronScreenplay, "resetHaymirQuests", function() order[#order + 1] = "haymir" end)
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(T.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetHaymirQuests calls for CorSec, RSF and Havoc pilots")
	lu.assertEquals(order, {}, "no Black Epsilon reset for them at all")

	local player = T.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetHaymirQuests calls for a Black Epsilon pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "hakassha", "prisk", "haymir" }, "the order of the three resets")
end

-- AC-11: the other squadrons' keys survive
function TestBlackEpsilonT3Surrender:test_a_black_epsilon_reset_leaves_other_squadrons_keys_alone()
	local player = veteran()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
end

-- AC-11: the reset is directly callable and touches tier 3 only
function TestBlackEpsilonT3Surrender:test_resetHaymirQuests_clears_tier_3_without_touching_skills_or_older_tiers()
	local player = veteran()

	BlackEpsilonSquadronScreenplay:resetHaymirQuests(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(T.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#T.held(player), 4, "skills are the surrender's business, not the reset's")

	for _, global in ipairs(P2.STORY) do
		lu.assertEquals(P2.state(player, global), "complete", global .. ": tier 2 journal state stays")
	end

	for _, key in ipairs(P2.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " stays")
	end

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": tier 1 journal state stays")
	end

	lu.assertEquals(H.getQuestStatus(player, T.SERIES_SUFFIX), "1", "series flag stays")
end

-- AC-11, Content contract 2: resetQuest runs on the 14 tables, once each
function TestBlackEpsilonT3Surrender:test_resetHaymirQuests_resets_the_fourteen_tables()
	local spies = {}

	for _, global in ipairs(T.GLOBALS) do
		spies[global] = H.spyOn(T.quest(global), "resetQuest")
	end

	BlackEpsilonSquadronScreenplay:resetHaymirQuests(T.pilot({}))

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
	end
end

-- AC-11, Content contract 2: nothing else is removed
function TestBlackEpsilonT3Surrender:test_resetHaymirQuests_removes_only_the_eight_keys()
	local player = T.pilot({})

	H.setQuestStatus(player, "corellia_imperial_tier3_1:somethingElse", "1")
	H.setQuestStatus(player, "corellia_imperial_tier3_5:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_12:reward", "1")
	BlackEpsilonSquadronScreenplay:resetHaymirQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier3_1:somethingElse"), "1", "an unrelated key stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier3_5:reward"), "1", "a key outside n = 1..4 stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_12:reward"), "1", "a tier 2 key stays")
end
