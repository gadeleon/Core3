-- Crimson Phoenix tier 4 part A: surrendering the pilot profession clears General Ufwol's progress (resetUfwolQuests), after Socuna's, Eker's and Ulvaw'op's resets
-- and before Burke's.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol-missions/01-spec.md (A-6; Content contract 2 and 3; D-8, D-9; SC-1).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_rebel_surrender.lua; the order test here adds "each once" and the pilot each reset receives.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")
local T = require("crimson_tier3_data")
local U = require("crimson_tier4_data")

M.load()
U.load()

local KEYS = U.statusKeys()

-- A graduate who carries every kind of tier 4 state: the four missions complete (all 13 story members), the 8 status keys and the met key, an active duty, the
-- four tier 3 skills, pilot tier 4, EKER_PILOT_KEY "3", plus tier 1-3 state (their resets still run)
local function graduate(extra)
	local o = { ufwol = 4, met = true, duty = U.DUTIES[2] }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return U.pilot(o)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

-- a red run reads "resetUfwolQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetUfwolQuests), "function",
		"CrimsonPhoenixSquadronScreenplay:resetUfwolQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing. Load problems: " .. U.problems())
end

TestUfwolSurrender = {}

function TestUfwolSurrender:setUp()
	H.reset()
	U.load()
end

-- A-6 (the setup itself)
function TestUfwolSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(U.CHILDREN) do
		lu.assertEquals(U.state(player, global), "complete", global .. ": journal state")
	end

	for _, head in ipairs(U.HEADS) do
		lu.assertEquals(U.state(player, head), "complete", head .. ": journal state")
	end

	lu.assertEquals(U.state(player, U.DUTIES[2]), "active", "the escort duty")

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#KEYS, 9, "tier 4 status keys: 8 head keys and the met key")
	lu.assertEquals(H.getQuestStatus(player, U.EKER_PILOT_KEY), "3", "EKER_PILOT_KEY")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(T.state(player, T.M4[5]), "complete", "a tier 3 journal entry")
	lu.assertEquals(E.state(player, E.E16), "complete", "a tier 2 journal entry")
	lu.assertEquals(C.state(player, C.P1), "complete", "a tier 1 journal entry")
end

-- A-6
function TestUfwolSurrender:test_surrendering_clears_the_seventeen_journal_entries_complete_and_active()
	requireReset()

	local player = graduate()

	U.setState(player, U.M1[3], "active")
	U.setState(player, U.M4[3], "active")
	surrender(player)

	for _, global in ipairs(U.GLOBALS) do
		lu.assertEquals(U.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-6: active runs are cleared too (each of the 17 tables, one at a time)
function TestUfwolSurrender:test_surrendering_clears_an_active_run_of_each_of_the_seventeen_tables()
	requireReset()

	for _, global in ipairs(U.GLOBALS) do
		H.reset()

		local player = U.pilot({ missions = 0 })

		U.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(U.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-6, I-10: the nine keys go (the eight head keys and the met key)
function TestUfwolSurrender:test_surrendering_removes_the_eight_status_keys_and_the_met_key()
	requireReset()

	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-6: everything Socuna's, Eker's and Ulvaw'op's resets clear goes too, EKER_PILOT_KEY included
function TestUfwolSurrender:test_surrendering_still_clears_ulvawop_eker_and_socunas_state_and_the_flag()
	requireReset()

	local player = surrender(graduate())

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": tier 3 journal state after the surrender")
	end

	for _, key in ipairs(T.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " (tier 3) after the surrender")
	end

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

	lu.assertNil(H.getQuestStatus(player, U.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")
end

-- A-6: the pilot profession goes, the pilot tier is reset
function TestUfwolSurrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-6: the inventory is untouched
function TestUfwolSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-6, D-8: resetUfwolQuests alone clears tier 4's state and nothing else: EKER_PILOT_KEY, tier 1-3 state, skills, pilot tier and items stay
function TestUfwolSurrender:test_the_reset_alone_touches_only_ufwols_state()
	requireReset()

	local player = graduate()
	local skillsBefore = #C.held(player)
	local inventoryBefore = #player.inventory.items

	CrimsonPhoenixSquadronScreenplay:resetUfwolQuests(player)

	for _, global in ipairs(U.GLOBALS) do
		lu.assertEquals(U.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	lu.assertEquals(H.getQuestStatus(player, U.EKER_PILOT_KEY), "3", "EKER_PILOT_KEY is Socuna's reset to remove, not Ufwol's (C3A D-7)")

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": tier 3 journal state is not touched")
	end

	for _, key in ipairs(T.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (tier 3) is not touched")
	end

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

	for _, t in ipairs(T.TRAIN) do
		lu.assertTrue(CreatureObject(player):hasSkill(t.skill), t.skill .. " (tier 3) untouched")
	end

	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-6: the reset asks each of the seventeen tables once, with the pilot
function TestUfwolSurrender:test_the_reset_calls_reset_quest_on_all_seventeen_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(U.GLOBALS) do
		spies[g] = H.spyOn(U.quest(g), "resetQuest")
	end

	local player = graduate()

	CrimsonPhoenixSquadronScreenplay:resetUfwolQuests(player)

	for _, g in ipairs(U.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- A-6: the reset is nil-safe
function TestUfwolSurrender:test_the_reset_returns_on_a_nil_player_and_raises_nothing_on_a_fresh_pilot()
	requireReset()
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetUfwolQuests, CrimsonPhoenixSquadronScreenplay, nil), true, "resetUfwolQuests(nil)")
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetUfwolQuests, CrimsonPhoenixSquadronScreenplay, U.pilot({ graduated = false })), true, "a pilot with no tier 4 state")
end

-- A-6: a surrender with no tier 4 state at all (a tier 2 pilot): nothing raised, nothing else changed
function TestUfwolSurrender:test_surrendering_with_no_tier_4_state_raises_no_error()
	requireReset()

	local player = E.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")

	local fresh = U.pilot({ missions = 0 })

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, fresh)
	lu.assertTrue(ok, "surrenderPilot of a tier 3 pilot with no tier 4 state raised: " .. tostring(err))
end

-- A-6: twice is the same as once
function TestUfwolSurrender:test_surrendering_twice_is_the_same_as_once()
	requireReset()

	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(U.GLOBALS) do
		lu.assertEquals(U.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-6: the resets run in the order Socuna, Eker, Ulvaw'op, Ufwol, Burke, each once
function TestUfwolSurrender:test_a_crimson_phoenix_surrender_runs_socuna_eker_ulvawop_ufwol_then_burke_once_each()
	requireReset()

	local order = {}
	local mts = M.mts()

	local socuna = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests", function() order[#order + 1] = "resetSocunaQuests" end)
	local eker = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetEkerQuests", function() order[#order + 1] = "resetEkerQuests" end)
	local ulvawop = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetUlvawopQuests", function() order[#order + 1] = "resetUlvawopQuests" end)
	local ufwol = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetUfwolQuests", function() order[#order + 1] = "resetUfwolQuests" end)
	local burke = H.spyOn(mts, "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = graduate()

	surrender(player)
	lu.assertEquals(order, { "resetSocunaQuests", "resetEkerQuests", "resetUlvawopQuests", "resetUfwolQuests", "burke" }, "the Crimson Phoenix surrender: the resets in order, each once")
	lu.assertEquals({ #socuna, #eker, #ulvawop, #ufwol, #burke }, { 1, 1, 1, 1, 1 }, "calls of Socuna's, Eker's, Ulvaw'op's, Ufwol's and Burke's resets")
end

-- A-6: Ufwol's reset gets the surrendering pilot, and other squadrons do not run it
function TestUfwolSurrender:test_ufwols_reset_gets_the_pilot_and_other_squadrons_do_not_run_it()
	requireReset()

	local reset = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetUfwolQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "VORTEX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(C.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetUfwolQuests calls for CorSec, RSF, Havoc, Vortex, Black Epsilon, Inquisition and Storm pilots")

	local player = graduate()

	surrender(player)
	lu.assertEquals(#reset, 1, "resetUfwolQuests calls for a Crimson Phoenix pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- A-6: the other squadrons' keys survive a Crimson Phoenix surrender (spot check), and the duty and head names do not collide with another squadron's tier 4
function TestUfwolSurrender:test_a_ufwol_reset_leaves_other_squadrons_keys_alone()
	requireReset()

	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_rebel_tier4_1:reward", "1")
	H.setQuestStatus(player, "VortexSquadronScreenplay:metTier4", "1")
	surrender(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_tier4_1:reward"), "1", "Vortex's tier 4 key (a different name from tatooine_rebel_tier4_1)")
	lu.assertEquals(H.getQuestStatus(player, "VortexSquadronScreenplay:metTier4"), "1", "Vortex's met key (a different key from the Crimson met key)")
end

return nil
