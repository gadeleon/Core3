-- Burke: surrendering the Rebel pilot profession clears Burke's progress (resetBurkeQuests), for Havoc, Vortex and Crimson Phoenix alike.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (AC-10; Content contract 1 (resetBurkeQuests); Shared code changes; D-10).
--
-- SpaceHelpers:surrenderPilot picks the profession by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Burke again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")

M.load()

local REBEL_SQUADRONS = M.REBEL_SQUADRONS

local HAVOC_RESETS = { "resetKreezoQuests", "resetViopaQuests", "resetAqzowQuests", "resetArkonQuests" }

-- A master with every kind of Burke state: both journal entries complete, the 4 status keys, the master-mission key, the master skill
local function master(squadron, extra)
	local o = { squadron = squadron, paid = { 1, 2 }, master = true, keys = { rebel = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local player = M.pilot(o)

	M.setState(player, "destroy_master_rebel_1", "complete")
	M.setState(player, "destroy_master_rebel_2", "complete")

	return player
end

-- a red run reads "MasterTrainerScreenplay:resetBurkeQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(M.mts().resetBurkeQuests), "function", "MasterTrainerScreenplay:resetBurkeQuests (screenplays/space/squadrons/MasterTrainerScreenplay.lua). Load problems: " .. M.problems())
end

TestMasterTrainerRebelSurrender = {}

function TestMasterTrainerRebelSurrender:setUp()
	H.reset()
	M.load()
end

-- AC-10 (the setup itself)
function TestMasterTrainerRebelSurrender:test_the_setup_carries_every_kind_of_burke_state()
	local player = master("havoc")

	lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "complete", "mission 1 journal")
	lu.assertEquals(M.state(player, "destroy_master_rebel_2"), "complete", "mission 2 journal")

	for _, key in ipairs(M.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertTrue(CreatureObject(player):hasSkill(M.MASTER), "the master skill")
	lu.assertEquals(#M.KEYS, 5, "keys the reset removes")
end

-- AC-10: one case per Rebel squadron: both journal entries cleared
function TestMasterTrainerRebelSurrender:test_surrendering_clears_both_journal_entries_for_every_rebel_squadron()
	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "none", squadron .. ": mission 1 journal after the surrender")
		lu.assertEquals(M.state(player, "destroy_master_rebel_2"), "none", squadron .. ": mission 2 journal after the surrender")
	end
end

-- AC-10: running quests are cleared too
function TestMasterTrainerRebelSurrender:test_surrendering_clears_a_running_master_mission()
	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = M.pilot({ squadron = squadron, mission = { [1] = "active" } })

		lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "active", squadron .. ": precondition")
		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "none", squadron .. ": mission 1 journal after the surrender")
	end
end

-- AC-10: the five keys
function TestMasterTrainerRebelSurrender:test_surrendering_removes_the_five_burke_keys_for_every_rebel_squadron()
	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)

		for _, key in ipairs(M.KEYS) do
			lu.assertNil(H.getQuestStatus(player, key), squadron .. ": " .. key .. " after the surrender")
		end
	end
end

-- AC-10: the master skill and the rest go with the surrender
function TestMasterTrainerRebelSurrender:test_surrendering_removes_the_master_skill_and_resets_the_pilot_tier()
	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertFalse(CreatureObject(player):hasSkill(M.MASTER), squadron .. ": the master skill after the surrender")

		for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
			lu.assertFalse(CreatureObject(player):hasSkill(skill), squadron .. ": " .. skill .. " after the surrender")
		end

		lu.assertEquals(player.ghost.pilotTier, 0, squadron .. ": pilot tier after the surrender")
	end
end

-- AC-10: the next talk
function TestMasterTrainerRebelSurrender:test_the_next_talk_opens_default()
	M.requireConversation(lu)

	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		player.pilot = nil -- the server derives the pilot kind from the skills that are gone

		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "default" }, squadron .. ": first screen after the surrender")
		lu.assertTrue(t[1].stop, "default ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-10: resetBurkeQuests is called once, after the squadron's own resets
function TestMasterTrainerRebelSurrender:test_the_burke_reset_is_called_once_for_each_rebel_squadron_after_the_squadrons_own_resets()
	local order = {}

	for _, name in ipairs(HAVOC_RESETS) do
		H.spyOn(HavocSquadronScreenplay, name, function() order[#order + 1] = name end)
	end

	local reset = H.spyOn(M.mts(), "resetBurkeQuests", function() order[#order + 1] = "burke" end)

	local player = M.pilot({ squadron = "havoc" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetBurkeQuests calls for a Havoc pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "resetKreezoQuests", "resetViopaQuests", "resetAqzowQuests", "resetArkonQuests", "burke" }, "the order of the resets (Arkon's, then Burke's)")

	-- vortex-tier1-v3-fx: a Vortex pilot's surrender runs V3-FX's reset first, then Burke's
	lu.assertEquals(type(VortexSquadronScreenplay.resetV3fxQuests), "function", "VortexSquadronScreenplay:resetV3fxQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing")
	H.spyOn(VortexSquadronScreenplay, "resetV3fxQuests", function() order[#order + 1] = "resetV3fxQuests" end)
	lu.assertEquals(type(VortexSquadronScreenplay.resetVrovelQuests), "function", "VortexSquadronScreenplay:resetVrovelQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing (vortex-tier2-vrovel-missions)")
	H.spyOn(VortexSquadronScreenplay, "resetVrovelQuests", function() order[#order + 1] = "resetVrovelQuests" end)
	lu.assertEquals(type(VortexSquadronScreenplay.resetEzkielQuests), "function", "VortexSquadronScreenplay:resetEzkielQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing (vortex-tier3-ezkiel-missions)")
	H.spyOn(VortexSquadronScreenplay, "resetEzkielQuests", function() order[#order + 1] = "resetEzkielQuests" end)
	lu.assertEquals(type(VortexSquadronScreenplay.resetEvinQuests), "function", "VortexSquadronScreenplay:resetEvinQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing (vortex-tier4-extok-evin)")
	H.spyOn(VortexSquadronScreenplay, "resetEvinQuests", function() order[#order + 1] = "resetEvinQuests" end)

	-- crimson-phoenix-tier1-da-la-socuna: a Crimson Phoenix pilot's surrender runs Da'la Socuna's reset first, then Burke's
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetSocunaQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetSocunaQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing (crimson-phoenix-tier1-da-la-socuna)")
	H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests", function() order[#order + 1] = "resetSocunaQuests" end)
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetEkerQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetEkerQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing (crimson-phoenix-tier2-eker)")
	H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetEkerQuests", function() order[#order + 1] = "resetEkerQuests" end)

	local expectedOrder = { vortex = { "resetV3fxQuests", "resetVrovelQuests", "resetEzkielQuests", "resetEvinQuests", "burke" }, crimson = { "resetSocunaQuests", "resetEkerQuests", "burke" } }

	for _, squadron in ipairs({ "vortex", "crimson" }) do
		order = {}

		local before = #reset
		local p = M.pilot({ squadron = squadron })

		SpaceHelpers:surrenderPilot(p)
		lu.assertEquals(#reset, before + 1, squadron .. ": resetBurkeQuests calls")
		lu.assertEquals(reset[#reset].args[1], p, squadron .. ": the reset gets the pilot")
		lu.assertEquals(order, expectedOrder[squadron], squadron .. ": the order of the resets (Vortex: V3-FX's, Brother Vrovel's (vortex-tier2-vrovel-missions), Brother Ezkiel's (vortex-tier3-ezkiel-missions), Brother Extok Evin's (vortex-tier4-extok-evin), then Burke's; Crimson Phoenix: Da'la Socuna's, Major Eker's (crimson-phoenix-tier2-eker), then Burke's)")
	end
end

-- AC-10: the reset is called while the skills are still held (it runs before the skill loop)
function TestMasterTrainerRebelSurrender:test_the_burke_reset_runs_before_the_skills_are_surrendered()
	local heldDuring

	H.spyOn(M.mts(), "resetBurkeQuests", function(_, player) heldDuring = CreatureObject(player):hasSkill(M.MASTER) end)

	local player = master("havoc")

	SpaceHelpers:surrenderPilot(player)
	lu.assertTrue(heldDuring, "the master skill is still held when resetBurkeQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(M.MASTER), "and gone afterwards")
end

-- AC-10: Imperial pilots do not call it; their surrender is as before
-- Superseded by space-master-trainer-privateer: CorSec, RSF and Smuggler pilots now call it (test_master_trainer_privateer_surrender.lua).
function TestMasterTrainerRebelSurrender:test_imperial_pilots_do_not_call_the_burke_reset()
	local reset = H.spyOn(M.mts(), "resetBurkeQuests")

	for _, o in ipairs({
		{ kind = "imperial", squadron = "black_epsilon" }, { kind = "imperial", squadron = "storm" }, { kind = "imperial", squadron = "inquisition" },
	}) do
		local player = M.pilot(o)

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(#reset, 0, o.squadron .. ": resetBurkeQuests calls")
		lu.assertEquals(player.ghost.pilotTier, 0, o.squadron .. ": the surrender still resets the pilot tier")
	end
end

-- AC-10: Declann's keys and state are untouched, by the surrender and by the direct reset
function TestMasterTrainerRebelSurrender:test_the_imperial_master_keys_are_untouched()
	requireReset()

	for _, squadron in ipairs(REBEL_SQUADRONS) do
		local player = master(squadron)

		for _, key in ipairs(M.IMPERIAL_KEYS) do
			H.setQuestStatus(player, key, "1")
		end

		SpaceHelpers:surrenderPilot(player)

		for _, key in ipairs(M.IMPERIAL_KEYS) do
			lu.assertEquals(H.getQuestStatus(player, key), "1", squadron .. ": " .. key .. " belongs to Declann's reset")
		end
	end

	local direct = master("havoc")

	for _, key in ipairs(M.IMPERIAL_KEYS) do
		H.setQuestStatus(direct, key, "1")
	end

	M.mts():resetBurkeQuests(direct)

	for _, key in ipairs(M.IMPERIAL_KEYS) do
		lu.assertEquals(H.getQuestStatus(direct, key), "1", "resetBurkeQuests leaves " .. key)
	end
end

-- AC-10: nothing else is removed by the Burke reset
function TestMasterTrainerRebelSurrender:test_the_burke_reset_removes_only_its_five_keys()
	requireReset()

	local player = M.pilot({})

	H.setQuestStatus(player, "master_rebel_3:reward", "1")
	H.setQuestStatus(player, "master_rebel_1:somethingElse", "1")
	H.setQuestStatus(player, "corellia_rebel_tier4_1:reward", "1")
	H.setQuestStatus(player, "MasterTrainerScreenplay:somethingElse", "1")
	H.setQuestStatus(player, "HavocSquadronScreenplay:StartedArkon", "1")
	M.mts():resetBurkeQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "master_rebel_3:reward"), "1", "a key outside n = 1, 2 stays")
	lu.assertEquals(H.getQuestStatus(player, "master_rebel_1:somethingElse"), "1", "an unrelated key stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_tier4_1:reward"), "1", "an Arkon key stays")
	lu.assertEquals(H.getQuestStatus(player, "MasterTrainerScreenplay:somethingElse"), "1", "an unrelated screenplay key stays")
	lu.assertEquals(H.getQuestStatus(player, "HavocSquadronScreenplay:StartedArkon"), "1", "Arkon's met flag is Arkon's reset's business")
end

-- AC-10, Content contract 1: resetQuest runs on both tables, once each
function TestMasterTrainerRebelSurrender:test_the_burke_reset_resets_both_quest_tables_once_each()
	local spies = {}

	for _, global in ipairs(M.GLOBALS) do
		spies[global] = H.spyOn(M.quest(global), "resetQuest")
	end

	local player = M.pilot({})

	M.mts():resetBurkeQuests(player)

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(spies[global][1].args[1], player, global .. ": resetQuest gets the pilot")
	end
end

-- AC-10, Content contract 1: the journal entries are cleared silently (notify false), exactly the two
function TestMasterTrainerRebelSurrender:test_the_burke_reset_clears_the_two_journal_entries_without_notifying()
	for _, global in ipairs(M.GLOBALS) do
		H.spyOn(M.quest(global), "resetQuest")
	end

	local calls = H.spyOn(SpaceHelpers, "clearSpaceQuest")

	M.mts():resetBurkeQuests(M.pilot({}))

	local seen, n = {}, 0

	for _, c in ipairs(calls) do
		seen[c.args[2] .. "/" .. c.args[3]] = c.args[4]
		n = n + 1
	end

	lu.assertEquals(n, 2, "clearSpaceQuest calls")
	lu.assertEquals(seen["destroy/master_rebel_1"], false, "clearSpaceQuest(destroy, master_rebel_1, false)")
	lu.assertEquals(seen["destroy/master_rebel_2"], false, "clearSpaceQuest(destroy, master_rebel_2, false)")
end

-- AC-10: nil pilot, no state
function TestMasterTrainerRebelSurrender:test_the_burke_reset_returns_early_on_nil_and_is_harmless_without_state()
	local ok, err = pcall(M.mts().resetBurkeQuests, M.mts(), nil)

	lu.assertTrue(ok, "resetBurkeQuests(nil) raised: " .. tostring(err))

	local player = M.pilot({ t4 = 0, pilotTier = 1 })

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "surrenderPilot with no Burke state raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-10: twice is the same as once
function TestMasterTrainerRebelSurrender:test_surrendering_twice_is_harmless()
	local player = master("vortex")

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- D-10: the call is nil-guarded so surrender works without the master trainer file loaded
function TestMasterTrainerRebelSurrender:test_surrender_works_when_the_master_trainer_screenplay_is_not_loaded()
	local saved = rawget(_G, "MasterTrainerScreenplay")

	_G.MasterTrainerScreenplay = nil

	local player = M.pilot({ squadron = "havoc" })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	_G.MasterTrainerScreenplay = saved
	lu.assertTrue(ok, "surrenderPilot without MasterTrainerScreenplay raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-10: Havoc's own surrender still runs the four tier resets when Burke's state is present
function TestMasterTrainerRebelSurrender:test_a_havoc_surrender_still_runs_the_four_tier_resets()
	local calls = {}

	for _, name in ipairs(HAVOC_RESETS) do
		calls[name] = H.spyOn(HavocSquadronScreenplay, name)
	end

	SpaceHelpers:surrenderPilot(master("havoc"))

	for name, c in pairs(calls) do
		lu.assertEquals(#c, 1, name .. " calls")
	end
end
