-- Crimson Phoenix tier 3 part A: surrendering the pilot profession clears Arnecio Ulvaw'op's progress (resetUlvawopQuests), after Socuna's and Eker's resets and
-- before Burke's.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop-missions/01-spec.md (A-5; Content contract 3 and 4; D-7; SC-2).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_rebel_surrender.lua; the order test here adds "each once" and the pilot each reset receives.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")
local T = require("crimson_tier3_data")

M.load()
T.load()

local KEYS = T.statusKeys()

-- A graduate who carries every kind of tier 3 state: the four missions complete (all 17 members), the 8 status keys, the four tier 3 skills, pilot tier 4,
-- EKER_PILOT_KEY "3", plus Eker's and Socuna's state (their resets still run)
local function graduate(extra)
	local o = { missions = 4, t3 = 4 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

-- a red run reads "resetUlvawopQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetUlvawopQuests), "function",
		"CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing. Load problems: " .. T.problems())
end

TestUlvawopSurrender = {}

function TestUlvawopSurrender:setUp()
	H.reset()
	T.load()
end

-- A-5 (the setup itself)
function TestUlvawopSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#KEYS, 8, "tier 3 status keys")
	lu.assertEquals(H.getQuestStatus(player, T.EKER_PILOT_KEY), "3", "EKER_PILOT_KEY")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(E.state(player, E.E16), "complete", "a tier 2 journal entry")
	lu.assertEquals(C.state(player, C.P1), "complete", "a tier 1 journal entry")
end

-- A-5
function TestUlvawopSurrender:test_surrendering_clears_the_seventeen_journal_entries_complete_and_active()
	requireReset()

	local player = graduate()

	T.setState(player, T.M2[3], "active")
	T.setState(player, T.M4[5], "active")
	surrender(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-5: active runs are cleared too (each of the 17 tables, one at a time)
function TestUlvawopSurrender:test_surrendering_clears_an_active_run_of_each_of_the_seventeen_tables()
	requireReset()

	for _, global in ipairs(T.GLOBALS) do
		H.reset()

		local player = T.pilot({ missions = 0 })

		T.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(T.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-5
function TestUlvawopSurrender:test_surrendering_removes_the_eight_status_keys()
	requireReset()

	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-5: everything Socuna's and Eker's resets clear goes too, EKER_PILOT_KEY included
function TestUlvawopSurrender:test_surrendering_still_clears_eker_and_socunas_state_and_the_flag()
	requireReset()

	local player = surrender(graduate())

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), "none", global .. ": tier 2 journal state after the surrender")
	end

	for _, key in ipairs(E.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	for _, global in ipairs(E.TIER1_GLOBALS) do
		lu.assertEquals(C.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for n = 1, 4 do
		lu.assertNil(H.getQuestStatus(player, C.statusName(n) .. ":attempted"), C.statusName(n) .. ":attempted after the surrender")
		lu.assertNil(H.getQuestStatus(player, C.statusName(n) .. ":reward"), C.statusName(n) .. ":reward after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, T.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")
end

-- A-5: the pilot profession goes, the pilot tier is reset
function TestUlvawopSurrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-5: the inventory is untouched
function TestUlvawopSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-5, D-7: resetUlvawopQuests alone clears tier 3's state and nothing else: EKER_PILOT_KEY, tier 1-2 state, skills, pilot tier and items stay
function TestUlvawopSurrender:test_the_reset_alone_touches_only_ulvawops_state()
	requireReset()

	local player = graduate()
	local skillsBefore = #C.held(player)
	local inventoryBefore = #player.inventory.items

	CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(player)

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	lu.assertEquals(H.getQuestStatus(player, T.EKER_PILOT_KEY), "3", "EKER_PILOT_KEY is Socuna's reset to remove, not Ulvaw'op's (D-7)")

	for _, global in ipairs(E.GLOBALS) do
		if not E.IDENTITY[global].type:find("duty") then
			lu.assertEquals(E.state(player, global), "complete", global .. ": tier 2 journal state is not touched")
		end
	end

	for _, key in ipairs(E.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (tier 2) is not touched")
	end

	for _, chain in ipairs(C.CHAINS) do
		for _, global in ipairs(chain) do
			lu.assertEquals(C.state(player, global), "complete", global .. ": tier 1 journal state is not touched")
		end
	end

	lu.assertEquals(#C.held(player), skillsBefore, "tier 1 skills untouched")

	for _, skill in ipairs(E.tier2Skills(4)) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " untouched")
	end

	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-5: the reset asks each of the seventeen tables once, with the pilot
function TestUlvawopSurrender:test_the_reset_calls_reset_quest_on_all_seventeen_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(T.GLOBALS) do
		spies[g] = H.spyOn(T.quest(g), "resetQuest")
	end

	local player = graduate()

	CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(player)

	for _, g in ipairs(T.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- A-5: the reset is nil-safe
function TestUlvawopSurrender:test_the_reset_returns_on_a_nil_player_and_raises_nothing_on_a_fresh_pilot()
	requireReset()
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetUlvawopQuests, CrimsonPhoenixSquadronScreenplay, nil), true, "resetUlvawopQuests(nil)")
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetUlvawopQuests, CrimsonPhoenixSquadronScreenplay, T.pilot({ graduated = false })), true, "a pilot with no tier 3 state")
end

-- A-5: a surrender with no tier 3 state at all (a tier 1 or 2 pilot): nothing raised, nothing else changed
function TestUlvawopSurrender:test_surrendering_with_no_tier_3_state_raises_no_error()
	requireReset()

	local player = E.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- A-5: twice is the same as once
function TestUlvawopSurrender:test_surrendering_twice_is_the_same_as_once()
	requireReset()

	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-1, A-5: the resets run in the order Socuna, Eker, Ulvaw'op, Burke, each once
function TestUlvawopSurrender:test_a_crimson_phoenix_surrender_runs_socuna_then_eker_then_ulvawop_then_burke_once_each()
	requireReset()

	local order = {}
	local mts = M.mts()

	local socuna = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests", function() order[#order + 1] = "resetSocunaQuests" end)
	local eker = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetEkerQuests", function() order[#order + 1] = "resetEkerQuests" end)
	local ulvawop = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetUlvawopQuests", function() order[#order + 1] = "resetUlvawopQuests" end)
	local burke = H.spyOn(mts, "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = graduate()

	surrender(player)
	lu.assertEquals(order, { "resetSocunaQuests", "resetEkerQuests", "resetUlvawopQuests", "burke" }, "the Crimson Phoenix surrender: the resets in order, each once")
	lu.assertEquals({ #socuna, #eker, #ulvawop, #burke }, { 1, 1, 1, 1 }, "calls of Socuna's, Eker's, Ulvaw'op's and Burke's resets")
end

-- A-5: Ulvaw'op's reset gets the surrendering pilot, and other squadrons do not run it
function TestUlvawopSurrender:test_ulvawops_reset_gets_the_pilot_and_other_squadrons_do_not_run_it()
	requireReset()

	local reset = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetUlvawopQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "VORTEX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(C.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetUlvawopQuests calls for CorSec, RSF, Havoc, Vortex, Black Epsilon, Inquisition and Storm pilots")

	local player = graduate()

	surrender(player)
	lu.assertEquals(#reset, 1, "resetUlvawopQuests calls for a Crimson Phoenix pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- A-5: the other squadrons' keys survive a Crimson Phoenix surrender (spot check)
function TestUlvawopSurrender:test_an_ulvawop_reset_leaves_other_squadrons_keys_alone()
	requireReset()

	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_rebel_tier3_1:reward", "1")
	surrender(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_tier3_1:reward"), "1", "Vortex's tier 3 key (a different name from tatooine_rebel_tier3_1)")
end

return nil
