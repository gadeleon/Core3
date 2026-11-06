-- Inquisition tier 3: surrendering the pilot profession clears Vrke's progress and both Barlow keys (resetVrkeQuests).
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-11; Content contract 2; Shared code changes; D-9, D-15).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the server
-- from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

M.load()
V.load()

local TIER1_JOURNAL = {
	{ "patrol", "naboo_imperial_1" }, { "destroy_surpriseattack", "naboo_imperial_1" }, { "destroy", "naboo_imperial_2" }, { "patrol", "naboo_imperial_3" },
	{ "escort", "naboo_imperial_3" }, { "assassinate", "naboo_imperial_4" }, { "destroy_duty", "naboo_imperial_6" }, { "escort_duty", "naboo_imperial_7" },
}

local TIER2_JOURNAL = {
	{ "inspect", "naboo_imperial_tier2_1" }, { "survival", "naboo_imperial_tier2_2" }, { "recovery", "naboo_imperial_tier2_3" }, { "assassinate", "naboo_imperial_tier2_4" },
	{ "recovery_duty", "naboo_imperial_tier2_recoveryduty" }, { "escort_duty", "naboo_imperial_tier2_escortduty" }, { "destroy_duty", "naboo_imperial_tier2_destroyduty" },
}

local OLDER_KEYS = { "naboo_imperial_2:aborted", V.SERIES_SUFFIX, V.AGENT_SUFFIX }

for n = 1, 4 do
	OLDER_KEYS[#OLDER_KEYS + 1] = "naboo_imperial_" .. n .. ":attempted"
	OLDER_KEYS[#OLDER_KEYS + 1] = "naboo_imperial_" .. n .. ":reward"
	OLDER_KEYS[#OLDER_KEYS + 1] = "naboo_imperial_tier2_" .. n .. ":attempted"
	OLDER_KEYS[#OLDER_KEYS + 1] = "naboo_imperial_tier2_" .. n .. ":reward"
end

local TIER3_KEYS = { V.QUESTION_SUFFIX, V.SPOKE_SUFFIX }

for _, k in ipairs(V.KEYS) do
	TIER3_KEYS[#TIER3_KEYS + 1] = k
end

-- A graduate who carries every kind of Barn, Fa'Zoll and Vrke state: the tier 1 and 2 journals complete and their keys, the 16 tier 3 entries (all
-- complete but one running member of mission 2's chain), the 8 tier 3 keys, both Barlow keys, the tier 1-3 skills, pilot tier 4
local function graduate()
	local player = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, question = true, spoke = true, pilotTier = 4 })

	for _, q in ipairs(TIER1_JOURNAL) do
		player.ghost.journalComplete[H.questCrc(q[1], q[2])] = true
	end

	for _, q in ipairs(TIER2_JOURNAL) do
		player.ghost.journalComplete[H.questCrc(q[1], q[2])] = true
	end

	for _, key in ipairs(OLDER_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	V.setState(player, V.M2[3], "active")

	return player
end

local function olderState(player)
	local out = {}

	for _, q in ipairs(TIER1_JOURNAL) do
		out[#out + 1] = player.ghost.journalComplete[H.questCrc(q[1], q[2])] and "complete" or "none"
	end

	for _, q in ipairs(TIER2_JOURNAL) do
		out[#out + 1] = player.ghost.journalComplete[H.questCrc(q[1], q[2])] and "complete" or "none"
	end

	for _, key in ipairs(OLDER_KEYS) do
		out[#out + 1] = H.getQuestStatus(player, key) or "nil"
	end

	return out
end

local function requireReset()
	lu.assertEquals(type(InquisitionSquadronScreenplay.resetVrkeQuests), "function", "InquisitionSquadronScreenplay:resetVrkeQuests is not defined (Content contract 2)")
end

TestInquisitionT3Surrender = {}

function TestInquisitionT3Surrender:setUp()
	H.reset()
	V.load()
end

-- AC-11 (the setup itself)
function TestInquisitionT3Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), global == V.M2[3] and "active" or "complete", global .. ": journal state")
	end

	for _, key in ipairs(TIER3_KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#V.held(player), 4, "tier 3 skills")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
end

-- AC-11
function TestInquisitionT3Surrender:test_surrendering_clears_the_sixteen_journal_entries_complete_or_active()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too, each mission
function TestInquisitionT3Surrender:test_surrendering_clears_an_active_head_of_each_mission()
	requireReset()

	for n = 1, 4 do
		H.reset()

		local player = V.pilot({ mission = { [n] = "active" } })

		SpaceHelpers:surrenderPilot(player)

		for _, global in ipairs(V.CHAINS[n]) do
			lu.assertEquals(V.state(player, global), "none", global .. ": journal state after the surrender")
		end
	end
end

-- AC-11
function TestInquisitionT3Surrender:test_surrendering_removes_the_eight_status_keys_and_both_barlow_keys()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(TIER3_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11: tiers 1 and 2 are cleared as before
function TestInquisitionT3Surrender:test_surrendering_still_clears_all_of_barns_and_fa_zolls_state()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local want = {}

	for _ = 1, #TIER1_JOURNAL + #TIER2_JOURNAL do
		want[#want + 1] = "none"
	end

	for _ = 1, #OLDER_KEYS do
		want[#want + 1] = "nil"
	end

	lu.assertEquals(olderState(player), want, "tier 1 and 2 journal entries and keys after the surrender")
end

-- AC-11
function TestInquisitionT3Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	for _, t in ipairs(V.TRAIN) do
		lu.assertFalse(CreatureObject(player):hasSkill(t.skill), t.skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the resets run in the order Barn, Fa'Zoll, Vrke, Ja'ce, Declann, each once
function TestInquisitionT3Surrender:test_the_resets_run_once_each_in_the_order_barn_fa_zoll_vrke_jace_declann()
	requireReset()

	local order = {}

	H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests", function() order[#order + 1] = "barn" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests", function() order[#order + 1] = "fazoll" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests", function() order[#order + 1] = "vrke" end)
	-- inquisition-tier4-jace-yiaso: Ja'ce's reset runs between Vrke's and Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests", function() order[#order + 1] = "jace" end)
	H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	SpaceHelpers:surrenderPilot(V.pilot({}))
	lu.assertEquals(order, { "barn", "fazoll", "vrke", "jace", "declann" }, "the order of the resets")
end

-- AC-11
function TestInquisitionT3Surrender:test_the_vrke_reset_gets_the_pilot()
	requireReset()

	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests")
	local player = V.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetVrkeQuests calls for an Inquisition pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: only Inquisition pilots trigger it; other squadrons' surrender is unchanged
function TestInquisitionT3Surrender:test_only_an_inquisition_pilot_triggers_the_vrke_reset()
	requireReset()

	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(V.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetVrkeQuests calls for CorSec, RSF, Havoc, Black Epsilon and Storm pilots")
end

-- AC-11: the other squadrons' keys survive
function TestInquisitionT3Surrender:test_a_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
end

-- AC-11: a pilot with no state, and twice
function TestInquisitionT3Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = V.pilot({ agent = false, series = false, t2paid4 = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: the next talk with Vrke opens not_pilot, and a re-enlisted pilot starts tier 3 clean
function TestInquisitionT3Surrender:test_after_a_surrender_vrke_treats_the_pilot_as_a_non_pilot_and_a_re_enlisted_pilot_starts_clean()
	requireReset()
	V.requireConversation(lu)

	local player = graduate()

	V.setState(player, V.M2[3], "complete") -- the running member would make Vrke say on_mission
	removeQuestStatus(player.objectID .. V.QUESTION_SUFFIX) -- Barlow's interview done: the key would make Vrke say barlow_pending
	lu.assertEquals(V.firstScreen(player), "tour_complete", "Vrke before the surrender")
	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone
	lu.assertEquals(V.firstScreen(player), "not_pilot", "Vrke after the surrender")

	-- the pilot enlists again and flies through tiers 1 and 2 (skills and Fa'Zoll's mission 4 reward key)
	player.pilot = "imperial"
	player.ghost.squadronType = INQUISITION_SQUADRON
	player.skills[V.NOVICE] = true

	for _, skill in ipairs(V.TIER1_SKILLS) do
		player.skills[skill] = true
	end

	for _, skill in ipairs(V.TIER2_SKILLS) do
		player.skills[skill] = true
	end

	H.setQuestStatus(player, V.TIER2_M4_REWARD, "1")
	player.ghost.pilotTier = 3
	lu.assertEquals(V.firstScreen(player), "m1_offer", "the re-enlisted pilot is offered mission 1 again, no stale tier 3 state")
	lu.assertNil(H.getQuestStatus(player, V.QUESTION_SUFFIX), "no stale question key")
	lu.assertNil(H.getQuestStatus(player, V.SPOKE_SUFFIX), "no stale spoke key")
end

---------------------------------------------------------------------------------------------
-- resetVrkeQuests called directly
---------------------------------------------------------------------------------------------

TestInquisitionT3Reset = {}

function TestInquisitionT3Reset:setUp()
	H.reset()
	V.load()
	requireReset()
end

-- AC-11, Content contract 2
function TestInquisitionT3Reset:test_resetVrkeQuests_clears_tier_3_without_touching_tiers_1_and_2_skills_or_pilot_tier()
	local player = graduate()
	local older = olderState(player)

	InquisitionSquadronScreenplay:resetVrkeQuests(player)

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(TIER3_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(olderState(player), older, "tier 1 and 2 journal entries and keys (Barn's and Fa'Zoll's resets, not this one)")
	lu.assertEquals(#V.held(player), 4, "skills are the surrender's business, not the reset's")

	for _, skill in ipairs(V.TIER1_SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill)
	end

	for _, skill in ipairs(V.TIER2_SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill)
	end

	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
end

-- AC-11: nil returns
function TestInquisitionT3Reset:test_resetVrkeQuests_with_a_nil_pilot_returns()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetVrkeQuests, InquisitionSquadronScreenplay, nil)

	lu.assertTrue(ok, "resetVrkeQuests(nil) raised: " .. tostring(err))
end

-- AC-11: the reset asks every table once
function TestInquisitionT3Reset:test_resetVrkeQuests_calls_resetQuest_on_all_sixteen_tables()
	local spies = {}

	for _, g in ipairs(V.GLOBALS) do
		spies[g] = H.spyOn(V.quest(g), "resetQuest")
	end

	local player = graduate()

	InquisitionSquadronScreenplay:resetVrkeQuests(player)

	for _, g in ipairs(V.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-11: the reset clears the journal entries of the sixteen quests through clearSpaceQuest(p, type, name, false) (and not the tier 1-2 ones)
function TestInquisitionT3Reset:test_resetVrkeQuests_clears_the_sixteen_journal_entries_through_clearSpaceQuest()
	local cleared = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = graduate()

	InquisitionSquadronScreenplay:resetVrkeQuests(player)

	local got = {}

	for _, call in ipairs(cleared) do
		got[#got + 1] = call.args[2] .. "/" .. call.args[3]
		lu.assertEquals(call.args[1], player, "clearSpaceQuest got the pilot")
		lu.assertEquals(call.args[4], false, "clearSpaceQuest(" .. call.args[2] .. "/" .. call.args[3] .. ") 4th argument (the Barn / Fa'Zoll convention)")
	end

	table.sort(got)

	local want = {}

	for _, global in ipairs(V.GLOBALS) do
		want[#want + 1] = V.IDENTITY[global].type .. "/" .. V.IDENTITY[global].name
	end

	table.sort(want)
	lu.assertEquals(got, want, "clearSpaceQuest (type/name) calls")
end

-- AC-11: the reset of a pilot with no state is harmless
function TestInquisitionT3Reset:test_resetVrkeQuests_on_a_pilot_with_no_tier_3_state_raises_no_error()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetVrkeQuests, InquisitionSquadronScreenplay, V.pilot({}))

	lu.assertTrue(ok, "resetVrkeQuests raised: " .. tostring(err))
end
