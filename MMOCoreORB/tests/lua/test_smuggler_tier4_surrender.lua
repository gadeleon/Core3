-- Smuggler tier 4: surrendering the pilot profession clears Nirame's progress (resetNirameQuests).
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-12; Content contract 2 and 4; Shared code changes SC-3; D-18).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the server from the
-- skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Nirame again.

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local B = require("smuggler_tier3_data")
local M = require("smuggler_tier2_data")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

N.load()

local KEYS = N.statusKeys()
local G = N.GLOBALS

-- the squadron object with resetNirameQuests, or a failure that says the reset is missing
local function squadron()
	local sq = N.squadron()

	lu.assertEquals(type(sq.resetNirameQuests), "function", "SmugglerSquadronScreenplay:resetNirameQuests is not defined")

	return sq
end

-- A graduate who carries every kind of Nirame state: the 16 tables complete, the 9 status keys, the 4 tier 4 skills, pilot tier 5 (plus tier 1 to 3)
local function graduate()
	local player = N.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, met = true, pilotTier = 5 })

	for _, global in ipairs(G) do
		N.setState(player, global, "complete")
	end

	-- Beissa's state too, so the reset can be shown to leave it alone
	for n = 1, 4 do
		B.setMission(player, n, "paid")
	end

	return player
end

local MASTER_CALLS

local function installMasterStub(order)
	local saved = rawget(_G, "MasterTrainerScreenplay")

	MASTER_CALLS = {}

	rawset(_G, "MasterTrainerScreenplay", {
		resetDeclannQuests = function(_, p)
			order[#order + 1] = "declann"
			MASTER_CALLS[#MASTER_CALLS + 1] = "declann"
		end,
		resetBurkeQuests = function(_, p)
			order[#order + 1] = "burke"
			MASTER_CALLS[#MASTER_CALLS + 1] = "burke"
		end,
	})

	return function() rawset(_G, "MasterTrainerScreenplay", saved) end
end

TestSmugglerT4Surrender = {}

function TestSmugglerT4Surrender:setUp()
	H.reset()
	N.load()
end

-- AC-12 (the setup itself)
function TestSmugglerT4Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(G) do
		lu.assertEquals(N.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#N.held(player), 4, "tier 4 skills")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron")
	lu.assertEquals(#KEYS, 9, "the nine keys of resetNirameQuests")
end

-- AC-12
function TestSmugglerT4Surrender:test_surrendering_clears_the_16_journal_entries()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(G) do
		lu.assertEquals(N.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12: active runs are cleared too, the duties and the failure child included
function TestSmugglerT4Surrender:test_surrendering_clears_active_runs()
	local player = N.pilot({ mission = { [1] = "active", [2] = "partial", [3] = "won" }, duty4 = G[13] })

	N.setState(player, G[8], "active")
	N.setState(player, G[14], "active")
	N.setState(player, G[16], "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(G) do
		lu.assertEquals(N.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12
function TestSmugglerT4Surrender:test_surrendering_removes_the_nine_status_keys()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-12
function TestSmugglerT4Surrender:test_surrendering_removes_the_neutral_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.neutralPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-12: the next talk opens not_neutral
function TestSmugglerT4Surrender:test_the_next_talk_opens_not_neutral()
	N.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	local t = N.talk(player)

	lu.assertEquals(N.ids(t), { "not_neutral" }, "first screen after the surrender")
	lu.assertTrue(t[1].stop, "not_neutral ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-12: the reset is called once, after Beissa's reset and before the Declann/Burke resets, while the skills are still held
function TestSmugglerT4Surrender:test_surrender_calls_resetNirameQuests_once_after_the_beissa_reset_and_before_the_master_trainer_resets()
	local sq = squadron()
	local order = {}
	local restore = installMasterStub(order)

	H.spyOn(sq, "resetDravisQuests", function() order[#order + 1] = "dravis" end)
	H.spyOn(sq, "resetKarrdeQuests", function() order[#order + 1] = "karrde" end)
	H.spyOn(sq, "resetShamdonQuests", function() order[#order + 1] = "shamdon" end)
	H.spyOn(sq, "resetBeissaQuests", function() order[#order + 1] = "beissa" end)

	local reset = H.spyOn(sq, "resetNirameQuests", function(_, p)
		order[#order + 1] = "nirame"

		return CreatureObject(p):hasSkill(S.NOVICE)
	end)

	local player = graduate()
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	restore()
	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(#reset, 1, "resetNirameQuests calls for a Smuggler pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "dravis", "karrde", "shamdon", "beissa", "nirame", "declann", "burke" },
		"resetDravisQuests, Karrde, Shamdon, Beissa, then resetNirameQuests, then the Declann and Burke resets")
	lu.assertTrue(reset[1].snapshot, "the novice box is still held when resetNirameQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(S.NOVICE), "and gone afterwards")
end

-- AC-12: only a Smuggler triggers it
function TestSmugglerT4Surrender:test_only_a_smuggler_triggers_the_nirame_reset()
	local sq = squadron()
	local reset = H.spyOn(sq, "resetNirameQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squad = rawget(_G, o[1])

		lu.assertNotNil(squad, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(S.pilot({ pilot = o[2], squadron = squad }))
	end

	lu.assertEquals(#reset, 0, "resetNirameQuests calls for CorSec, RSF, Havoc and Black Epsilon pilots")
end

-- AC-12: the other squadrons' surrender is as before: their keys survive a Smuggler's
function TestSmugglerT4Surrender:test_a_smuggler_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "naboo_privateer_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_1:reward"), "1", "RSF's key")
end

-- AC-12: surrendering still clears Dravis', Karrde's, Shamdon's and Beissa's progress
function TestSmugglerT4Surrender:test_surrender_still_clears_the_progress_of_tiers_1_to_3()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(S.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Dravis' key " .. key)
	end

	for _, key in ipairs(M.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Shamdon's key " .. key)
	end

	for _, key in ipairs(B.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), "Beissa's key " .. key)
	end

	lu.assertNil(H.getQuestStatus(player, T.ATTEMPTED), "Karrde's :attempted key")
	lu.assertNil(H.getQuestStatus(player, T.REWARD), "Karrde's :reward key")

	for _, global in ipairs(B.GLOBALS) do
		lu.assertEquals(B.state(player, global), "none", "Beissa's " .. global)
	end

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(M.state(player, global), "none", "Shamdon's " .. global)
	end
end

-- AC-12: no state at all, and twice
function TestSmugglerT4Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = N.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-12, Content contract 2: the reset is directly callable, resets each table once, and touches neither skills, tier, tier 1 to 3 keys nor tier 3 journal entries
function TestSmugglerT4Surrender:test_resetNirameQuests_resets_the_16_tables_and_clears_without_touching_skills_or_older_tiers()
	local sq = squadron()
	local resets = {}

	for _, global in ipairs(G) do
		resets[global] = H.spyOn(N.quest(global), "resetQuest")
	end

	local player = graduate()

	sq:resetNirameQuests(player)

	for _, global in ipairs(G) do
		lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(resets[global][1].args[1], player, global .. ": resetQuest gets the pilot")
		lu.assertEquals(N.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertEquals(#N.held(player), 4, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 5, "so is the pilot tier")

	for _, key in ipairs(B.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Beissa's key " .. key)
	end

	for _, global in ipairs(B.HEADS) do
		lu.assertEquals(B.state(player, global), "complete", "Beissa's " .. global)
	end

	for _, key in ipairs(M.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Shamdon's key " .. key)
	end

	for _, key in ipairs(S.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Dravis' key " .. key)
	end
end

-- AC-12: the reset clears the 16 quest strings through SpaceHelpers:clearSpaceQuest (journal entries gone, not just failed)
function TestSmugglerT4Surrender:test_resetNirameQuests_clears_the_16_quest_strings()
	local sq = squadron()
	local cleared = H.spyOn(SpaceHelpers, "clearSpaceQuest")

	sq:resetNirameQuests(graduate())

	local seen = {}

	for _, c in ipairs(cleared) do
		seen[tostring(c.args[2]) .. "/" .. tostring(c.args[3])] = true
	end

	for _, name in ipairs(N.RESET_STRINGS) do
		local qs = sq[name]

		lu.assertNotNil(qs, "SmugglerSquadronScreenplay." .. name)
		lu.assertTrue(seen[qs.type .. "/" .. qs.name] == true, name .. " (" .. qs.type .. "/" .. qs.name .. ") is cleared")
	end
end

-- AC-12: the reset does not touch another player's state
function TestSmugglerT4Surrender:test_resetNirameQuests_is_per_player()
	local a, b = graduate(), graduate()

	squadron():resetNirameQuests(a)

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(b, key), "1", "other pilot's " .. key)
	end

	for _, global in ipairs(G) do
		lu.assertEquals(N.state(b, global), "complete", "other pilot's " .. global)
	end
end

-- AC-12: a running mission is aborted by the reset (resetQuest of the real table)
function TestSmugglerT4Surrender:test_resetNirameQuests_stops_a_running_mission_and_a_running_duty()
	for _, global in ipairs({ G[10], G[13] }) do
		H.reset()

		local q = N.quest(global)

		q:start()

		local player = N.pilot({ zone = q.questZone, inShip = true })

		q:startQuest(player, "")
		H.advance(0)
		lu.assertEquals(N.state(player, global), "active", "precondition: " .. global .. " runs")
		squadron():resetNirameQuests(player)
		H.advance(0)
		lu.assertEquals(N.state(player, global), "none", global .. ": journal state")
	end
end
