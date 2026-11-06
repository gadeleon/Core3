-- Inquisition tier 4: surrendering the pilot profession clears Ja'ce's progress (resetJaceYiasoQuests), after Vrke's reset and before Declann's.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-12; Content contract 2; Shared code changes SC-1; D-15).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the server
-- from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local J4 = require("inquisition_tier4_data")

M.load()
J4.load()

-- A graduate who carries every kind of Ja'ce state: all 16 story entries complete but one running member, one running duty, the nine keys, the
-- tier 1-3 keys, the met key, the tier 1-4 skills, pilot tier 5
local function graduate()
	local player = J4.pilot({ paid = { 1, 2, 3, 4 }, t4 = { 1, 2, 3, 4 }, met = true, pilotTier = 5, duty = J4.DUTIES[2] })

	J4.setState(player, J4.M2[3], "active")
	J4.setState(player, J4.DUTIES[1], "complete")
	J4.setState(player, J4.DUTIES[3], "active")

	return player
end

local function requireReset()
	lu.assertEquals(type(InquisitionSquadronScreenplay.resetJaceYiasoQuests), "function", "InquisitionSquadronScreenplay:resetJaceYiasoQuests is not defined (Content contract 2)")
end

local function olderKeys(player)
	local out = {}

	for _, key in ipairs(J4.OLDER_KEYS) do
		out[#out + 1] = H.getQuestStatus(player, key) or "nil"
	end

	return out
end

TestInquisitionT4Surrender = {}

function TestInquisitionT4Surrender:setUp()
	H.reset()
	J4.load()
end

-- AC-12 (the setup itself)
function TestInquisitionT4Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(J4.STORY) do
		lu.assertEquals(J4.state(player, global), global == J4.M2[3] and "active" or "complete", global .. ": journal state")
	end

	lu.assertEquals({ J4.state(player, J4.DUTIES[1]), J4.state(player, J4.DUTIES[2]), J4.state(player, J4.DUTIES[3]) }, { "complete", "active", "active" }, "duty journal states")

	for _, key in ipairs(J4.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#J4.held(player), 4, "tier 4 skills")
	lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier")
	lu.assertEquals(#J4.KEYS, 9, "the nine keys")
end

-- AC-12
function TestInquisitionT4Surrender:test_surrendering_clears_the_twenty_journal_entries_complete_or_active()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(J4.GLOBALS) do
		lu.assertEquals(J4.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12: active runs are cleared too, each mission and each duty
function TestInquisitionT4Surrender:test_surrendering_clears_an_active_head_of_each_mission_and_each_duty()
	requireReset()

	for n = 1, 4 do
		H.reset()

		local player = J4.pilot({ mission = { [n] = "active" }, duty = J4.DUTIES[n] })

		SpaceHelpers:surrenderPilot(player)

		for _, global in ipairs(J4.CHAINS[n]) do
			lu.assertEquals(J4.state(player, global), "none", global .. ": journal state after the surrender")
		end

		lu.assertEquals(J4.state(player, J4.DUTIES[n]), "none", J4.DUTIES[n] .. ": journal state after the surrender")
	end
end

-- AC-12
function TestInquisitionT4Surrender:test_surrendering_removes_the_nine_status_keys_including_the_met_key()
	requireReset()

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(J4.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-12: tiers 1 to 3 are cleared as before (by their own resets)
function TestInquisitionT4Surrender:test_surrendering_still_clears_the_tier_1_to_3_keys()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local want = {}

	for _ = 1, #J4.OLDER_KEYS do
		want[#want + 1] = "nil"
	end

	lu.assertEquals(olderKeys(player), want, "the tier 1-3 keys after the surrender")
end

-- AC-12
function TestInquisitionT4Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	for _, t in ipairs(J4.TRAIN) do
		lu.assertFalse(CreatureObject(player):hasSkill(t.skill), t.skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-12, SC-1: Ja'ce's reset runs once, after Vrke's and before Declann's
function TestInquisitionT4Surrender:test_the_resets_run_once_each_in_the_order_barn_fa_zoll_vrke_jace_declann()
	requireReset()

	local order = {}

	H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests", function() order[#order + 1] = "barn" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests", function() order[#order + 1] = "fazoll" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests", function() order[#order + 1] = "vrke" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests", function() order[#order + 1] = "jace" end)
	H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	SpaceHelpers:surrenderPilot(J4.pilot({}))
	lu.assertEquals(order, { "barn", "fazoll", "vrke", "jace", "declann" }, "the order of the resets")
end

-- AC-12
function TestInquisitionT4Surrender:test_the_jace_reset_gets_the_pilot()
	requireReset()

	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests")
	local player = J4.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetJaceYiasoQuests calls for an Inquisition pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-12: only Inquisition pilots trigger it; other squadrons' surrender is unchanged
function TestInquisitionT4Surrender:test_only_an_inquisition_pilot_triggers_the_jace_reset()
	requireReset()

	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(J4.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetJaceYiasoQuests calls for CorSec, RSF, Havoc, Black Epsilon and Storm pilots")
end

-- AC-12: the other squadrons' keys survive
function TestInquisitionT4Surrender:test_a_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
end

-- AC-12: a pilot with no state, and twice
function TestInquisitionT4Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = J4.pilot({ older = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-12: the next talk with Ja'ce opens not_pilot
function TestInquisitionT4Surrender:test_after_a_surrender_ja_ce_treats_the_pilot_as_a_non_pilot()
	requireReset()
	J4.requireConversation(lu)

	local player = graduate()

	J4.setState(player, J4.M2[3], "complete")
	J4.setState(player, J4.DUTIES[2], "none")
	J4.setState(player, J4.DUTIES[3], "none")
	lu.assertEquals(J4.firstScreen(player), "transfer", "Ja'ce before the surrender")
	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone
	lu.assertEquals(J4.firstScreen(player), "not_pilot", "Ja'ce after the surrender")
end

---------------------------------------------------------------------------------------------
-- resetJaceYiasoQuests called directly
---------------------------------------------------------------------------------------------

TestInquisitionT4Reset = {}

function TestInquisitionT4Reset:setUp()
	H.reset()
	J4.load()
	requireReset()
end

-- AC-12, Content contract 2
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_clears_tier_4_without_touching_skills_older_keys_or_pilot_tier()
	local player = graduate()
	local older = olderKeys(player)

	InquisitionSquadronScreenplay:resetJaceYiasoQuests(player)

	for _, global in ipairs(J4.GLOBALS) do
		lu.assertEquals(J4.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(J4.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(olderKeys(player), older, "tier 1-3 keys (their own resets, not this one)")
	lu.assertEquals(#J4.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertTrue(CreatureObject(player):hasSkill(J4.TIER3_SKILLS[1]), "tier 3 skills stay")
	lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier")
end

-- AC-12: nil returns
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_with_a_nil_pilot_returns()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetJaceYiasoQuests, InquisitionSquadronScreenplay, nil)

	lu.assertTrue(ok, "resetJaceYiasoQuests(nil) raised: " .. tostring(err))
end

-- AC-12: the reset asks every table once, the duties included
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_calls_resetQuest_once_on_all_twenty_tables()
	local spies = {}

	for _, g in ipairs(J4.GLOBALS) do
		spies[g] = H.spyOn(J4.quest(g), "resetQuest")
	end

	local player = graduate()

	InquisitionSquadronScreenplay:resetJaceYiasoQuests(player)

	for _, g in ipairs(J4.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-12: the reset clears the journal entries of the twenty quests through clearSpaceQuest(p, type, name, false)
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_clears_the_twenty_journal_entries_through_clear_space_quest()
	local cleared = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = graduate()

	InquisitionSquadronScreenplay:resetJaceYiasoQuests(player)

	local got = {}

	for _, call in ipairs(cleared) do
		got[#got + 1] = call.args[2] .. "/" .. call.args[3]
		lu.assertEquals(call.args[1], player, "clearSpaceQuest got the pilot")
		lu.assertEquals(call.args[4], false, "clearSpaceQuest(" .. call.args[2] .. "/" .. call.args[3] .. ") 4th argument (the Barn / Fa'Zoll / Vrke convention)")
	end

	table.sort(got)

	local want = {}

	for _, global in ipairs(J4.GLOBALS) do
		want[#want + 1] = J4.IDENTITY[global].type .. "/" .. J4.IDENTITY[global].name
	end

	table.sort(want)
	lu.assertEquals(got, want, "clearSpaceQuest (type/name) calls")
end

-- AC-12: removeQuestStatus on exactly the nine keys
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_removes_only_the_nine_keys()
	local player = graduate()
	local before = olderKeys(player)

	InquisitionSquadronScreenplay:resetJaceYiasoQuests(player)

	for _, key in ipairs(J4.KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(olderKeys(player), before, "no other key is removed")
end

-- AC-12: the reset of a pilot with no tier 4 state is harmless
function TestInquisitionT4Reset:test_resetJaceYiasoQuests_on_a_pilot_with_no_tier_4_state_raises_no_error()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetJaceYiasoQuests, InquisitionSquadronScreenplay, J4.pilot({}))

	lu.assertTrue(ok, "raised: " .. tostring(err))
end
