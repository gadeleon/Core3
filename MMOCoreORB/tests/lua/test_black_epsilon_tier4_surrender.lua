-- Black Epsilon tier 4: surrendering the pilot profession clears Nin Gursawe's progress (resetNinGursaweQuests), after Hakassha's, Prisk's and Haymir's.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-12; Content contract 2 and 4; Shared code changes; D-9, D-16).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to the Insurgent again.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local T3 = require("black_epsilon_tier3_data")
local P2 = require("black_epsilon_tier2_data")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

T.load()

local TIER1_STORY = { B.P1, B.S1, B.M2, B.E3, B.A4 }

-- A graduate who carries every kind of state: the 15 tier 4 story entries complete, the 11 tier 4 keys (the intro, met and Declann keys included),
-- the tier 3, 2 and 1 state, all skills including the master skill, pilot tier 5
local function veteran()
	local player = T.pilot({ t4 = { 1, 2, 3, 4 }, master = true, paid = { 1, 2, 3, 4 }, pilotTier = 5, keys = { intro = true, met = true, declann = true } })

	for _, global in ipairs(T.STORY) do
		T.setState(player, global, "complete")
	end

	for _, key in ipairs(T.KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	for _, global in ipairs(T3.GLOBALS) do
		T3.setState(player, global, "complete")
	end

	for _, key in ipairs(T3.KEYS) do
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

TestBlackEpsilonT4Surrender = {}

function TestBlackEpsilonT4Surrender:setUp()
	H.reset()
	T.load()
end

-- AC-12 (the setup itself)
function TestBlackEpsilonT4Surrender:test_the_setup_carries_every_kind_of_state()
	local player = veteran()

	for _, global in ipairs(T.STORY) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(T.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#T.held(player), 4, "tier 4 skills")
	lu.assertTrue(CreatureObject(player):hasSkill(T.MASTER), "the master skill")
	lu.assertEquals({ #T.STORY, #T.KEYS }, { 15, 11 }, "tier 4 journal entries and keys")
end

-- AC-12
function TestBlackEpsilonT4Surrender:test_surrendering_clears_the_fifteen_tier_4_journal_entries()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(T.STORY) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12: active runs are cleared too, split children included
function TestBlackEpsilonT4Surrender:test_surrendering_clears_active_runs()
	local player = T.pilot({})

	for _, global in ipairs(T.STORY) do
		T.setState(player, global, "active")
	end

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(T.STORY) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12
function TestBlackEpsilonT4Surrender:test_surrendering_removes_the_eleven_tier_4_status_keys()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(T.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-12: the tier 1, 2 and 3 resets still run
function TestBlackEpsilonT4Surrender:test_surrendering_still_clears_all_tier_1_to_3_state()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(T3.GLOBALS) do
		lu.assertEquals(T3.state(player, global), "none", global .. ": tier 3 journal state after the surrender")
	end

	for _, key in ipairs(T3.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

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
end

-- AC-12: every Imperial pilot skill, the tier 4 skills and the master skill included
function TestBlackEpsilonT4Surrender:test_surrendering_removes_the_imperial_pilot_skills_the_master_skill_included_and_resets_the_pilot_tier()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertFalse(CreatureObject(player):hasSkill(T.MASTER), "the master skill after the surrender")

	for _, t in ipairs(T.TRAIN) do
		lu.assertFalse(CreatureObject(player):hasSkill(t.skill), t.skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-12: the next talk
function TestBlackEpsilonT4Surrender:test_the_next_talk_opens_not_pilot()
	T.requireConversation(lu)

	local player = veteran()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = T.talk(player)

	lu.assertEquals(T.ids(t), { "not_pilot" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-12: a pilot with no Nin Gursawe state
function TestBlackEpsilonT4Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = T.pilot({ tier1 = 0, t2 = 0, t3 = 0, pilotTier = 1 })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-12: twice is the same as once
function TestBlackEpsilonT4Surrender:test_surrendering_twice_is_harmless()
	local player = veteran()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-12: the reset is called for Black Epsilon pilots only, after the tier 1, 2 and 3 resets
function TestBlackEpsilonT4Surrender:test_only_a_black_epsilon_pilot_triggers_the_nin_gursawe_reset_and_it_follows_the_haymir_reset()
	local order = {}

	H.spyOn(BlackEpsilonSquadronScreenplay, "resetHakasshaQuests", function() order[#order + 1] = "hakassha" end)
	H.spyOn(BlackEpsilonSquadronScreenplay, "resetPriskQuests", function() order[#order + 1] = "prisk" end)
	H.spyOn(BlackEpsilonSquadronScreenplay, "resetHaymirQuests", function() order[#order + 1] = "haymir" end)

	local reset = H.spyOn(BlackEpsilonSquadronScreenplay, "resetNinGursaweQuests", function() order[#order + 1] = "nin" end)
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(T.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetNinGursaweQuests calls for CorSec, RSF and Havoc pilots")
	lu.assertEquals(order, {}, "no Black Epsilon reset for them at all")

	local player = T.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetNinGursaweQuests calls for a Black Epsilon pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "hakassha", "prisk", "haymir", "nin" }, "the order of the four resets")
end

-- AC-12: the other squadrons' keys survive
function TestBlackEpsilonT4Surrender:test_a_black_epsilon_reset_leaves_other_squadrons_keys_alone()
	local player = veteran()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
end

-- AC-12: the reset is directly callable and touches tier 4 only
function TestBlackEpsilonT4Surrender:test_resetNinGursaweQuests_clears_tier_4_without_touching_skills_older_tiers_or_duties()
	local player = veteran()

	for _, global in ipairs(T.DUTIES) do
		T.setState(player, global, "complete")
	end

	BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(player)

	for _, global in ipairs(T.STORY) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(T.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#T.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertTrue(CreatureObject(player):hasSkill(T.MASTER), "the master skill stays too")

	for _, global in ipairs(T.DUTIES) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": the duties are not reset (D-16)")
	end

	for _, global in ipairs(T3.GLOBALS) do
		lu.assertEquals(T3.state(player, global), "complete", global .. ": tier 3 journal state stays")
	end

	for _, key in ipairs(T3.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " stays")
	end

	for _, global in ipairs(P2.STORY) do
		lu.assertEquals(P2.state(player, global), "complete", global .. ": tier 2 journal state stays")
	end

	for _, global in ipairs(TIER1_STORY) do
		lu.assertEquals(B.state(player, global), "complete", global .. ": tier 1 journal state stays")
	end
end

-- AC-12, Content contract 2: resetQuest runs on the 15 story tables, once each, and not on the duties
function TestBlackEpsilonT4Surrender:test_resetNinGursaweQuests_resets_the_fifteen_story_tables_and_no_duty()
	local spies = {}

	for _, global in ipairs(T.GLOBALS) do
		spies[global] = H.spyOn(T.quest(global), "resetQuest")
	end

	BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(T.pilot({}))

	for _, global in ipairs(T.STORY) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
	end

	for _, global in ipairs(T.DUTIES) do
		lu.assertEquals(#spies[global], 0, global .. ": a duty is not reset (D-16)")
	end
end

-- AC-12, Content contract 2: the journal entries are cleared silently (notify false), the 15 non-duty strings
function TestBlackEpsilonT4Surrender:test_resetNinGursaweQuests_clears_the_fifteen_journal_entries_without_notifying()
	local calls = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = T.pilot({})

	BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(player)

	local seen = {}

	for _, c in ipairs(calls) do
		seen[c.args[2] .. "/" .. c.args[3]] = c.args[4]
	end

	for _, global in ipairs(T.STORY) do
		local id = T.IDENTITY[global]

		lu.assertEquals(seen[id.type .. "/" .. id.name], false, global .. ": clearSpaceQuest(..., false)")
	end

	for _, global in ipairs(T.DUTIES) do
		local id = T.IDENTITY[global]

		lu.assertNil(seen[id.type .. "/" .. id.name], global .. ": a duty entry is not cleared")
	end
end

-- AC-12, Content contract 2: nothing else is removed
function TestBlackEpsilonT4Surrender:test_resetNinGursaweQuests_removes_only_the_eleven_keys()
	local player = T.pilot({})

	H.setQuestStatus(player, "corellia_imperial_tier4_1:somethingElse", "1")
	H.setQuestStatus(player, "corellia_imperial_tier4_5:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_tier3_1:reward", "1")
	H.setQuestStatus(player, "BlackEpsilonSquadronScreenplay:somethingElse", "1")
	BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier4_1:somethingElse"), "1", "an unrelated key stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier4_5:reward"), "1", "a key outside n = 1..4 stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier3_1:reward"), "1", "a tier 3 key stays")
	lu.assertEquals(H.getQuestStatus(player, "BlackEpsilonSquadronScreenplay:somethingElse"), "1", "an unrelated squadron key stays")
end

-- AC-12, D-9: the three flag keys are removed with the player id prefix
function TestBlackEpsilonT4Surrender:test_the_intro_met_and_declann_keys_are_removed_from_the_pilot_who_holds_them()
	local player = T.pilot({ keys = { intro = true, met = true, declann = true } })

	for _, suffix in ipairs({ T.INTRO_SUFFIX, T.MET_SUFFIX, T.DECLANN_SUFFIX }) do
		lu.assertEquals(H.getQuestStatus(player, suffix), "1", suffix .. ": precondition")
	end

	BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(player)

	for _, suffix in ipairs({ T.INTRO_SUFFIX, T.MET_SUFFIX, T.DECLANN_SUFFIX }) do
		lu.assertNil(H.getQuestStatus(player, suffix), suffix .. " after the reset")
	end
end
