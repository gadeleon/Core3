-- Storm tier 1: surrendering the pilot profession clears Colzet's progress (resetColzetQuests).
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-11; Content contract 2 and 4; Shared code changes; D-11).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Colzet again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local I = require("storm_tier1_data")
local CS = require("harness.client_strings")

M.load()
I.load()

local JOURNAL = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }
local KEYS = {}

for n = 1, 4 do
	KEYS[#KEYS + 1] = "tatooine_imperial_" .. n .. ":attempted"
	KEYS[#KEYS + 1] = "tatooine_imperial_" .. n .. ":reward"
end

KEYS[#KEYS + 1] = I.SERIES_SUFFIX

-- A graduate who carries every kind of Colzet state: the six story entries complete, a duty complete and one active, 8 status keys,
-- the series flag, four skills, pilot tier 2 and a transfer form in the inventory
local function graduate()
	local player = I.pilot({ paid = 4, tier = 4, series = true, pilotTier = 2 })

	player.inventory.items[#player.inventory.items + 1] = { template = I.TRANSFER_FORM }

	I.setState(player, I.DUTY6, "active")
	I.setState(player, I.DUTY7, "complete")

	return player
end

TestStormT1Surrender = {}

function TestStormT1Surrender:setUp()
	H.reset()
	I.load()
end

-- AC-11 (the setup itself)
function TestStormT1Surrender:test_the_setup_carries_every_kind_of_state()
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
function TestStormT1Surrender:test_surrendering_clears_the_eight_journal_entries_complete_or_active()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestStormT1Surrender:test_surrendering_clears_active_runs_of_both_split_chains()
	local player = I.pilot({ paid = 1, state = "active" })

	I.setState(player, I.S1, "active")
	I.setState(player, I.E3, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11
function TestStormT1Surrender:test_surrendering_removes_the_eight_status_keys_and_the_series_flag()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11
function TestStormT1Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the next talk
function TestStormT1Surrender:test_the_next_talk_opens_recruitment_and_the_pilot_can_sign_up_again()
	I.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = I.talk(player, { "s_11fcdd9f" })

	lu.assertEquals(t[1].id, "recruitment", "first screen after the surrender")
	lu.assertEquals(t[2].id, "recruit_navy", "the sign-up starts over")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no Colzet state
function TestStormT1Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = I.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestStormT1Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-11: the reset is called for Storm pilots only
function TestStormT1Surrender:test_only_a_storm_pilot_triggers_the_colzet_reset()
	local reset = H.spyOn(StormSquadronScreenplay, "resetColzetQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(I.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetColzetQuests calls for CorSec, RSF, Havoc, Black Epsilon and Inquisition pilots")

	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetColzetQuests calls for a Storm pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-11: Declann's reset still runs once, after Colzet's
function TestStormT1Surrender:test_declanns_reset_still_runs_once_after_colzets()
	local order = {}

	H.spyOn(StormSquadronScreenplay, "resetColzetQuests", function() order[#order + 1] = "colzet" end)

	local declann = H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#declann, 1, "resetDeclannQuests calls")
	lu.assertEquals(order, { "colzet", "declann" }, "the order of the resets")
end

-- AC-11: the other squadrons still reset as before (spot check; the full suites are the per-squadron surrender tests)
function TestStormT1Surrender:test_a_colzet_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:reward"), "1", "Inquisition's key")
end

-- AC-11, D-11: the reset is directly callable; it leaves skills, the pilot tier and the inventory (a held transfer form) alone
function TestStormT1Surrender:test_resetColzetQuests_clears_without_touching_skills_or_the_inventory()
	local player = graduate()

	lu.assertEquals(type(StormSquadronScreenplay.resetColzetQuests), "function", "StormSquadronScreenplay:resetColzetQuests is not defined")
	StormSquadronScreenplay:resetColzetQuests(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#I.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is the surrender's business too")
	lu.assertEquals(#player.inventory.items, 1, "the held transfer form stays (D-11)")
end

-- AC-11: surrendering leaves the inventory alone as well
function TestStormT1Surrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#player.inventory.items, 1, "the held transfer form stays")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
end

-- AC-11: resetColzetQuests resets the quests through their own resetQuest (every table is asked once)
function TestStormT1Surrender:test_resetColzetQuests_calls_resetQuest_on_all_eight_tables()
	local spies = {}

	for _, g in ipairs(JOURNAL) do
		spies[g] = H.spyOn(I.quest(g), "resetQuest")
	end

	local player = graduate()

	StormSquadronScreenplay:resetColzetQuests(player)

	for _, g in ipairs(JOURNAL) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-11: a reset with nothing to reset raises nothing
function TestStormT1Surrender:test_resetColzetQuests_on_a_fresh_pilot_and_on_nil_raises_nothing()
	lu.assertEquals(pcall(StormSquadronScreenplay.resetColzetQuests, StormSquadronScreenplay, I.pilot({})), true, "fresh pilot")
	lu.assertEquals(pcall(StormSquadronScreenplay.resetColzetQuests, StormSquadronScreenplay, nil), true, "nil")
end

-- AC-11: the surrender must not need a nil guard: a Storm pilot's surrender calls the real reset (the squadron file is loaded by the server)
function TestStormT1Surrender:test_a_storm_pilot_surrender_runs_the_real_reset_and_clears_active_runs()
	local player = I.pilot({ paid = 1, state = "active" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(I.state(player, I.M2), "none", "the active mission 2 run is cleared")
	lu.assertNil(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "mission 1's reward key")
end
