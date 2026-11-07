-- Vortex tier 3 part A: surrendering the pilot profession clears Brother Ezkiel's progress (resetEzkielQuests), after V3-FX's and Vrovel's resets and before Burke's.
-- Spec: .claude/work/vortex-tier3-ezkiel-missions/01-spec.md (A-7; Content contract 2 and 3; D-7; SC-2).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_rebel_surrender.lua; the order test here adds "each once" and the pilot each reset receives.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local V1 = require("vortex_tier1_data")
local V2 = require("vortex_tier2_data")
local W = require("vortex_tier3_data")

M.load()
W.load()

local KEYS = W.statusKeys()

-- A graduate who carries every kind of tier 3 state: the four missions complete (all 20 members), the 8 status keys, the four tier 3 skills, pilot tier 4,
-- plus tier 1 and 2 state (their resets still run)
local function graduate(extra)
	local o = { missions = 4, t3 = 4 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return W.pilot(o)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

-- a red run reads "resetEzkielQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(VortexSquadronScreenplay.resetEzkielQuests), "function",
		"VortexSquadronScreenplay:resetEzkielQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing. Load problems: " .. W.problems())
end

TestEzkielSurrender = {}

function TestEzkielSurrender:setUp()
	H.reset()
	W.load()
end

-- A-7 (the setup itself)
function TestEzkielSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(W.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#KEYS, 8, "tier 3 status keys")
	lu.assertEquals(H.getQuestStatus(player, W.VORTEX_PILOT_KEY), "3", "VORTEX_PILOT_KEY")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(V1.state(player, V1.P1), "complete", "a tier 1 journal entry")
	lu.assertEquals(V2.state(player, V2.E1), "complete", "a tier 2 journal entry")
end

-- A-7
function TestEzkielSurrender:test_surrendering_clears_the_twenty_journal_entries_complete_and_active()
	requireReset()

	local player = graduate()

	surrender(player)

	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(W.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-7: active runs are cleared too (each of the 20 tables, one at a time)
function TestEzkielSurrender:test_surrendering_clears_an_active_run_of_each_of_the_twenty_tables()
	requireReset()

	for _, global in ipairs(W.GLOBALS) do
		H.reset()

		local player = W.pilot({ missions = 0 })

		W.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(W.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-7
function TestEzkielSurrender:test_surrendering_removes_the_eight_status_keys()
	requireReset()

	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-7, D-7: everything V3-FX's and Vrovel's resets clear goes too, VORTEX_PILOT_KEY included
function TestEzkielSurrender:test_surrendering_still_clears_tier_1_and_tier_2_state_and_the_graduation_key()
	requireReset()

	local player = surrender(graduate())

	for _, global in ipairs(V1.GLOBALS) do
		lu.assertEquals(V1.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for _, global in ipairs(V2.GLOBALS) do
		lu.assertEquals(V2.state(player, global), "none", global .. ": tier 2 journal state after the surrender")
	end

	for _, key in ipairs(V1.STATUS_NAMES) do
		lu.assertNil(H.getQuestStatus(player, key .. ":attempted"), key .. ":attempted after the surrender")
		lu.assertNil(H.getQuestStatus(player, key .. ":reward"), key .. ":reward after the surrender")
	end

	for _, key in ipairs(V2.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, W.VORTEX_PILOT_KEY), "VORTEX_PILOT_KEY after the surrender")
end

-- A-7: the pilot profession goes, the pilot tier is reset
function TestEzkielSurrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-7: the inventory is untouched
function TestEzkielSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-7, D-7: resetEzkielQuests alone clears Ezkiel's state and nothing else: VORTEX_PILOT_KEY, tier 1-2 state, skills, pilot tier and items stay
function TestEzkielSurrender:test_the_reset_alone_touches_only_ezkiels_state()
	requireReset()

	local player = graduate()
	local skillsBefore = #V1.held(player)
	local inventoryBefore = #player.inventory.items

	VortexSquadronScreenplay:resetEzkielQuests(player)

	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(W.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	lu.assertEquals(H.getQuestStatus(player, W.VORTEX_PILOT_KEY), "3", "VORTEX_PILOT_KEY is V3-FX's reset to remove, not Ezkiel's (D-7)")

	for _, chain in ipairs(V1.CHAINS) do
		for _, global in ipairs(chain) do
			lu.assertEquals(V1.state(player, global), "complete", global .. ": tier 1 journal state is not touched")
		end
	end

	for _, global in ipairs(V2.GLOBALS) do
		if not V2.IDENTITY[global].type:find("duty") then
			lu.assertEquals(V2.state(player, global), "complete", global .. ": tier 2 journal state is not touched")
		end
	end

	for _, name in ipairs(V1.STATUS_NAMES) do
		lu.assertEquals(H.getQuestStatus(player, name .. ":reward"), "1", name .. ":reward (tier 1) is not touched")
	end

	for _, key in ipairs(V2.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (tier 2) is not touched")
	end

	lu.assertEquals(#V1.held(player), skillsBefore, "skills untouched")

	for _, skill in ipairs(W.tier3Skills(4)) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " untouched")
	end

	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-7: the reset asks each of the twenty tables once, with the pilot
function TestEzkielSurrender:test_the_reset_calls_reset_quest_on_all_twenty_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(W.GLOBALS) do
		spies[g] = H.spyOn(W.quest(g), "resetQuest")
	end

	local player = graduate()

	VortexSquadronScreenplay:resetEzkielQuests(player)

	for _, g in ipairs(W.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- A-7: the reset is nil-safe
function TestEzkielSurrender:test_the_reset_returns_on_a_nil_player_and_raises_nothing_on_a_fresh_pilot()
	requireReset()
	lu.assertEquals(pcall(VortexSquadronScreenplay.resetEzkielQuests, VortexSquadronScreenplay, nil), true, "resetEzkielQuests(nil)")
	lu.assertEquals(pcall(VortexSquadronScreenplay.resetEzkielQuests, VortexSquadronScreenplay, W.pilot({ graduated = false })), true, "a pilot with no tier 3 state")
end

-- A-7: a surrender with no tier 3 state at all
function TestEzkielSurrender:test_surrendering_with_no_tier_3_state_raises_no_error()
	requireReset()

	local player = W.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- A-7: twice is the same as once
function TestEzkielSurrender:test_surrendering_twice_is_the_same_as_once()
	requireReset()

	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(W.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-7: the resets run in the order V3-FX, Vrovel, Ezkiel, Burke, each once
function TestEzkielSurrender:test_a_vortex_surrender_runs_v3fx_then_vrovel_then_ezkiel_then_burke_once_each()
	requireReset()

	local order = {}
	local mts = M.mts()

	H.spyOn(VortexSquadronScreenplay, "resetV3fxQuests", function() order[#order + 1] = "resetV3fxQuests" end)
	H.spyOn(VortexSquadronScreenplay, "resetVrovelQuests", function() order[#order + 1] = "resetVrovelQuests" end)
	H.spyOn(VortexSquadronScreenplay, "resetEzkielQuests", function() order[#order + 1] = "resetEzkielQuests" end)

	local burke = H.spyOn(mts, "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = graduate()

	surrender(player)
	lu.assertEquals(order, { "resetV3fxQuests", "resetVrovelQuests", "resetEzkielQuests", "burke" }, "the Vortex surrender: the resets in order, each once")
	lu.assertEquals(#burke, 1, "resetBurkeQuests calls")
end

-- A-7: Ezkiel's reset gets the surrendering pilot, and other squadrons do not run it
function TestEzkielSurrender:test_ezkiels_reset_gets_the_pilot_and_other_squadrons_do_not_run_it()
	requireReset()

	local reset = H.spyOn(VortexSquadronScreenplay, "resetEzkielQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "CRIMSON_PHOENIX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(V1.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetEzkielQuests calls for CorSec, RSF, Havoc, Crimson Phoenix, Black Epsilon, Inquisition and Storm pilots")

	local player = graduate()

	surrender(player)
	lu.assertEquals(#reset, 1, "resetEzkielQuests calls for a Vortex pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- A-7: the other squadrons' keys survive a Vortex surrender (spot check)
function TestEzkielSurrender:test_an_ezkiel_reset_leaves_other_squadrons_keys_alone()
	requireReset()

	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	surrender(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
end

return nil
