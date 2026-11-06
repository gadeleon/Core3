-- Declann: surrendering the Imperial pilot profession clears Declann's progress (resetDeclannQuests), for Black Epsilon, Storm and Inquisition alike.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-10; Content contract 1 (resetDeclannQuests); Shared code changes; D-10).
--
-- SpaceHelpers:surrenderPilot picks the profession by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Declann again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local CS = require("harness.client_strings")

M.load()

local IMPERIAL_SQUADRONS = { "black_epsilon", "storm", "inquisition" }

-- A master with every kind of Declann state: both journal entries complete, the 4 status keys, the master-mission key, the master skill
local function master(squadron, extra)
	local o = { squadron = squadron, paid = { 1, 2 }, master = true, keys = { imperial = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local player = M.pilot(o)

	M.setState(player, "destroy_master_imperial_1", "complete")
	M.setState(player, "destroy_master_imperial_2", "complete")

	return player
end

TestMasterTrainerImperialSurrender = {}

function TestMasterTrainerImperialSurrender:setUp()
	H.reset()
	M.load()
end

-- AC-10 (the setup itself)
function TestMasterTrainerImperialSurrender:test_the_setup_carries_every_kind_of_declann_state()
	local player = master("black_epsilon")

	lu.assertEquals(M.state(player, "destroy_master_imperial_1"), "complete", "mission 1 journal")
	lu.assertEquals(M.state(player, "destroy_master_imperial_2"), "complete", "mission 2 journal")

	for _, key in ipairs(M.KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertTrue(CreatureObject(player):hasSkill(M.MASTER), "the master skill")
	lu.assertEquals(#M.KEYS, 5, "keys the reset removes")
end

-- AC-10: one case per Imperial squadron: both journal entries cleared
function TestMasterTrainerImperialSurrender:test_surrendering_clears_both_journal_entries_for_every_imperial_squadron()
	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(M.state(player, "destroy_master_imperial_1"), "none", squadron .. ": mission 1 journal after the surrender")
		lu.assertEquals(M.state(player, "destroy_master_imperial_2"), "none", squadron .. ": mission 2 journal after the surrender")
	end
end

-- AC-10: running quests are cleared too
function TestMasterTrainerImperialSurrender:test_surrendering_clears_a_running_master_mission()
	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = M.pilot({ squadron = squadron, mission = { [1] = "active" } })

		lu.assertEquals(M.state(player, "destroy_master_imperial_1"), "active", squadron .. ": precondition")
		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(M.state(player, "destroy_master_imperial_1"), "none", squadron .. ": mission 1 journal after the surrender")
	end
end

-- AC-10: the five keys
function TestMasterTrainerImperialSurrender:test_surrendering_removes_the_five_declann_keys_for_every_imperial_squadron()
	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)

		for _, key in ipairs(M.KEYS) do
			lu.assertNil(H.getQuestStatus(player, key), squadron .. ": " .. key .. " after the surrender")
		end
	end
end

-- AC-10: the master skill and the rest go with the surrender
function TestMasterTrainerImperialSurrender:test_surrendering_removes_the_master_skill_and_resets_the_pilot_tier()
	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		lu.assertFalse(CreatureObject(player):hasSkill(M.MASTER), squadron .. ": the master skill after the surrender")

		for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
			lu.assertFalse(CreatureObject(player):hasSkill(skill), squadron .. ": " .. skill .. " after the surrender")
		end

		lu.assertEquals(player.ghost.pilotTier, 0, squadron .. ": pilot tier after the surrender")
	end
end

-- AC-10: the next talk
function TestMasterTrainerImperialSurrender:test_the_next_talk_opens_default()
	M.requireConversation(lu)

	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = master(squadron)

		SpaceHelpers:surrenderPilot(player)
		player.pilot = nil -- the server derives the pilot kind from the skills that are gone

		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "default" }, squadron .. ": first screen after the surrender")
		lu.assertTrue(t[1].stop, "default ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-10: resetDeclannQuests is called once, after the squadron's own resets
function TestMasterTrainerImperialSurrender:test_the_declann_reset_is_called_once_for_each_imperial_squadron_after_the_squadrons_own_resets()
	local order = {}

	for _, name in ipairs({ "resetHakasshaQuests", "resetPriskQuests", "resetHaymirQuests", "resetNinGursaweQuests" }) do
		H.spyOn(BlackEpsilonSquadronScreenplay, name, function() order[#order + 1] = name end)
	end

	-- inquisition-tier1-barn-sinkko: Inquisition pilots now run Barn's reset before Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests", function() order[#order + 1] = "resetBarnQuests" end)
	-- inquisition-tier2-fa-zoll: ... and Fa'Zoll's reset between Barn's and Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests", function() order[#order + 1] = "resetFaZollQuests" end)

	-- inquisition-tier3-vrke: ... and Vrke's reset between Fa'Zoll's and Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests", function() order[#order + 1] = "resetVrkeQuests" end)

	-- inquisition-tier4-jace-yiaso: ... and Ja'ce's reset between Vrke's and Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests", function() order[#order + 1] = "resetJaceYiasoQuests" end)

	-- storm-tier1-akal-colzet: Storm pilots now run Colzet's reset before Declann's
	H.spyOn(StormSquadronScreenplay, "resetColzetQuests", function() order[#order + 1] = "resetColzetQuests" end)

	-- storm-tier2-oberhaur: ... and Oberhaur's reset between Colzet's and Declann's
	H.spyOn(StormSquadronScreenplay, "resetOberhaurQuests", function() order[#order + 1] = "resetOberhaurQuests" end)

	-- storm-tier2-alozen: ... and Alozen's reset between Oberhaur's and Declann's
	H.spyOn(StormSquadronScreenplay, "resetAlozenQuests", function() order[#order + 1] = "resetAlozenQuests" end)

	-- storm-tier3-denner-missions: ... and Denner's reset between Alozen's and Declann's
	H.spyOn(StormSquadronScreenplay, "resetDennerQuests", function() order[#order + 1] = "resetDennerQuests" end)

	local reset = H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)

	local player = M.pilot({ squadron = "black_epsilon" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetDeclannQuests calls for a Black Epsilon pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
	lu.assertEquals(order, { "resetHakasshaQuests", "resetPriskQuests", "resetHaymirQuests", "resetNinGursaweQuests", "declann" }, "the order of the resets")

	for _, squadron in ipairs({ "storm", "inquisition" }) do
		order = {}

		local before = #reset
		local p = M.pilot({ squadron = squadron })

		SpaceHelpers:surrenderPilot(p)
		lu.assertEquals(#reset, before + 1, squadron .. ": resetDeclannQuests calls")
		lu.assertEquals(reset[#reset].args[1], p, squadron .. ": the reset gets the pilot")

		if squadron == "inquisition" then
			lu.assertEquals(order, { "resetBarnQuests", "resetFaZollQuests", "resetVrkeQuests", "resetJaceYiasoQuests", "declann" }, squadron .. ": Barn's reset runs first, then Fa'Zoll's, then Vrke's, then Ja'ce's, then Declann's")
		else
			lu.assertEquals(order, { "resetColzetQuests", "resetOberhaurQuests", "resetAlozenQuests", "resetDennerQuests", "declann" }, squadron .. ": Colzet's reset runs first, then Oberhaur's, then Alozen's, then Denner's, then Declann's (storm-tier3-denner-missions)")
		end
	end
end

-- AC-10: the reset is called before the skills go (it runs inside the squadron branch)
function TestMasterTrainerImperialSurrender:test_the_declann_reset_runs_before_the_skills_are_surrendered()
	local heldDuring

	H.spyOn(M.mts(), "resetDeclannQuests", function(_, player) heldDuring = CreatureObject(player):hasSkill(M.MASTER) end)

	local player = master("black_epsilon")

	SpaceHelpers:surrenderPilot(player)
	lu.assertTrue(heldDuring, "the master skill is still held when resetDeclannQuests runs")
	lu.assertFalse(CreatureObject(player):hasSkill(M.MASTER), "and gone afterwards")
end

-- AC-10: Havoc pilots do not call it; their surrender is as before
-- Superseded by space-master-trainer-privateer: CorSec, RSF and Smuggler pilots now call it (test_master_trainer_privateer_surrender.lua).
function TestMasterTrainerImperialSurrender:test_havoc_pilots_do_not_call_the_declann_reset()
	local reset = H.spyOn(M.mts(), "resetDeclannQuests")

	for _, o in ipairs({
		{ kind = "rebel", squadron = "havoc" },
	}) do
		local player = M.pilot(o)

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(#reset, 0, o.squadron .. ": resetDeclannQuests calls")
		lu.assertEquals(player.ghost.pilotTier, 0, o.squadron .. ": the surrender still resets the pilot tier")
	end
end

-- AC-10: the Rebel key is untouched
function TestMasterTrainerImperialSurrender:test_the_rebel_master_key_is_untouched()
	for _, squadron in ipairs(IMPERIAL_SQUADRONS) do
		local player = master(squadron, { keys = { imperial = true, rebel = true } })

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(H.getQuestStatus(player, M.REBEL_KEY), "1", squadron .. ": MASTER_MISSION_REBEL_KEY belongs to Burke's reset")
	end

	local direct = master("black_epsilon", { keys = { imperial = true, rebel = true } })

	M.mts():resetDeclannQuests(direct)
	lu.assertEquals(H.getQuestStatus(direct, M.REBEL_KEY), "1", "resetDeclannQuests leaves MASTER_MISSION_REBEL_KEY")
end

-- AC-10: nothing else is removed by the Declann reset
function TestMasterTrainerImperialSurrender:test_the_declann_reset_removes_only_its_five_keys()
	local player = M.pilot({ keys = { nin = true } })

	H.setQuestStatus(player, "master_imperial_3:reward", "1")
	H.setQuestStatus(player, "master_imperial_1:somethingElse", "1")
	H.setQuestStatus(player, "corellia_imperial_tier4_1:reward", "1")
	H.setQuestStatus(player, "MasterTrainerScreenplay:somethingElse", "1")
	M.mts():resetDeclannQuests(player)
	lu.assertEquals(H.getQuestStatus(player, "master_imperial_3:reward"), "1", "a key outside n = 1, 2 stays")
	lu.assertEquals(H.getQuestStatus(player, "master_imperial_1:somethingElse"), "1", "an unrelated key stays")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier4_1:reward"), "1", "a Nin Gursawe key stays")
	lu.assertEquals(H.getQuestStatus(player, "MasterTrainerScreenplay:somethingElse"), "1", "an unrelated screenplay key stays")
	lu.assertEquals(H.getQuestStatus(player, M.NIN_KEY), "1", "Nin's Declann hand-off flag is Nin's reset's business")
end

-- AC-10, Content contract 1: resetQuest runs on both tables, once each
function TestMasterTrainerImperialSurrender:test_the_declann_reset_resets_both_quest_tables_once_each()
	local spies = {}

	for _, global in ipairs(M.GLOBALS) do
		spies[global] = H.spyOn(M.quest(global), "resetQuest")
	end

	local player = M.pilot({})

	M.mts():resetDeclannQuests(player)

	for _, global in ipairs(M.GLOBALS) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(spies[global][1].args[1], player, global .. ": resetQuest gets the pilot")
	end
end

-- AC-10, Content contract 1: the journal entries are cleared silently (notify false), exactly the two
function TestMasterTrainerImperialSurrender:test_the_declann_reset_clears_the_two_journal_entries_without_notifying()
	for _, global in ipairs(M.GLOBALS) do
		H.spyOn(M.quest(global), "resetQuest")
	end

	local calls = H.spyOn(SpaceHelpers, "clearSpaceQuest")

	M.mts():resetDeclannQuests(M.pilot({}))

	local seen, n = {}, 0

	for _, c in ipairs(calls) do
		seen[c.args[2] .. "/" .. c.args[3]] = c.args[4]
		n = n + 1
	end

	lu.assertEquals(n, 2, "clearSpaceQuest calls")
	lu.assertEquals(seen["destroy/master_imperial_1"], false, "clearSpaceQuest(destroy, master_imperial_1, false)")
	lu.assertEquals(seen["destroy/master_imperial_2"], false, "clearSpaceQuest(destroy, master_imperial_2, false)")
end

-- AC-10: nil pilot, no state
function TestMasterTrainerImperialSurrender:test_the_declann_reset_returns_early_on_nil_and_is_harmless_without_state()
	local ok, err = pcall(M.mts().resetDeclannQuests, M.mts(), nil)

	lu.assertTrue(ok, "resetDeclannQuests(nil) raised: " .. tostring(err))

	local player = M.pilot({ t4 = 0, pilotTier = 1 })

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "surrenderPilot with no Declann state raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-10: twice is the same as once
function TestMasterTrainerImperialSurrender:test_surrendering_twice_is_harmless()
	local player = master("storm")

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- D-10: the call is nil-guarded so surrender works without the master trainer file loaded
function TestMasterTrainerImperialSurrender:test_surrender_works_when_the_master_trainer_screenplay_is_not_loaded()
	local saved = rawget(_G, "MasterTrainerScreenplay")

	_G.MasterTrainerScreenplay = nil

	local player = M.pilot({ squadron = "black_epsilon" })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	_G.MasterTrainerScreenplay = saved
	lu.assertTrue(ok, "surrenderPilot without MasterTrainerScreenplay raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-10: Black Epsilon's own surrender still clears its tiers when Declann's state is present
function TestMasterTrainerImperialSurrender:test_a_black_epsilon_surrender_still_runs_the_four_tier_resets()
	local calls = {}

	for _, name in ipairs({ "resetHakasshaQuests", "resetPriskQuests", "resetHaymirQuests", "resetNinGursaweQuests" }) do
		calls[name] = H.spyOn(BlackEpsilonSquadronScreenplay, name)
	end

	SpaceHelpers:surrenderPilot(master("black_epsilon"))

	for name, c in pairs(calls) do
		lu.assertEquals(#c, 1, name .. " calls")
	end
end
