-- Crimson Phoenix tier 2 part A: surrendering the pilot profession clears Major Eker's progress (resetEkerQuests), after Socuna's reset and before Burke's.
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (A-1, A-6; Content contract 2 and 3; D-5; SC-2).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_rebel_surrender.lua; the order test here adds "each once" and the pilot each reset receives.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")

M.load()
E.load()

local KEYS = E.statusKeys()

local REBEL_SHIP = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") }

-- A graduate who carries every kind of tier 2 state: the four missions complete (all 5 members), the 8 status keys, a duty complete, the four tier 2 skills,
-- pilot tier 3, EKER_PILOT_KEY "2" (after the hand-in), plus Socuna's state (the tier 1 resets still run)
local function graduate(extra)
	local o = { missions = 4, t2 = 4, graduated = "2" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local player = E.pilot(o)

	E.setState(player, E.DUTY9, "complete")

	return player
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

-- a red run reads "resetEkerQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(CrimsonPhoenixSquadronScreenplay.resetEkerQuests), "function",
		"CrimsonPhoenixSquadronScreenplay:resetEkerQuests (screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua) is missing. Load problems: " .. E.problems())
end

TestEkerSurrender = {}

function TestEkerSurrender:setUp()
	H.reset()
	E.load()
end

-- A-6 (the setup itself)
function TestEkerSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), (global == E.DUTY9) and "complete" or (E.IDENTITY[global].type:find("duty") and "none" or "complete"), global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#KEYS, 8, "tier 2 status keys")
	lu.assertEquals(H.getQuestStatus(player, E.EKER_PILOT_KEY), "2", "EKER_PILOT_KEY")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
	lu.assertEquals(C.state(player, C.P1), "complete", "a tier 1 journal entry")
	lu.assertEquals(#C.held(player), 4, "tier 1 skills")
end

-- A-6
function TestEkerSurrender:test_surrendering_clears_the_eight_journal_entries_complete_and_active()
	requireReset()

	local player = graduate()

	E.setState(player, E.DUTY10, "active")
	E.setState(player, E.DUTY12, "complete")
	surrender(player)

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-6: active runs are cleared too (each of the 8 tables, one at a time)
function TestEkerSurrender:test_surrendering_clears_an_active_run_of_each_of_the_eight_tables()
	requireReset()

	for _, global in ipairs(E.GLOBALS) do
		H.reset()

		local player = E.pilot({ missions = 0 })

		E.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(E.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-6
function TestEkerSurrender:test_surrendering_removes_the_eight_status_keys()
	requireReset()

	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-6, D-5: everything Socuna's reset clears goes too, EKER_PILOT_KEY included
function TestEkerSurrender:test_surrendering_still_clears_socunas_state_and_the_graduation_key()
	requireReset()

	local player = surrender(graduate())

	for _, global in ipairs(E.TIER1_GLOBALS) do
		lu.assertEquals(C.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for n = 1, 4 do
		lu.assertNil(H.getQuestStatus(player, C.statusName(n) .. ":attempted"), C.statusName(n) .. ":attempted after the surrender")
		lu.assertNil(H.getQuestStatus(player, C.statusName(n) .. ":reward"), C.statusName(n) .. ":reward after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, E.EKER_PILOT_KEY), "EKER_PILOT_KEY after the surrender")
end

-- A-6: the pilot profession goes, the pilot tier is reset
function TestEkerSurrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-6: the inventory is untouched
function TestEkerSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-6, D-5: resetEkerQuests alone clears Eker's state and nothing else: EKER_PILOT_KEY, tier 1 state, skills, pilot tier and items stay
function TestEkerSurrender:test_the_reset_alone_touches_only_ekers_state()
	requireReset()

	local player = graduate()
	local skillsBefore = #C.held(player)
	local inventoryBefore = #player.inventory.items

	CrimsonPhoenixSquadronScreenplay:resetEkerQuests(player)

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	lu.assertEquals(H.getQuestStatus(player, E.EKER_PILOT_KEY), "2", "EKER_PILOT_KEY is Socuna's reset to remove, not Eker's (D-5)")

	for _, chain in ipairs(C.CHAINS) do
		for _, global in ipairs(chain) do
			lu.assertEquals(C.state(player, global), "complete", global .. ": tier 1 journal state is not touched")
		end
	end

	for n = 1, 4 do
		lu.assertEquals(H.getQuestStatus(player, C.statusName(n) .. ":reward"), "1", C.statusName(n) .. ":reward (tier 1) is not touched")
	end

	lu.assertEquals(#C.held(player), skillsBefore, "tier 1 skills untouched")

	for _, skill in ipairs(E.tier2Skills(4)) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " untouched")
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-6: the reset asks each of the eight tables once, with the pilot
function TestEkerSurrender:test_the_reset_calls_reset_quest_on_all_eight_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(E.GLOBALS) do
		spies[g] = H.spyOn(E.quest(g), "resetQuest")
	end

	local player = graduate()

	CrimsonPhoenixSquadronScreenplay:resetEkerQuests(player)

	for _, g in ipairs(E.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- A-6: the reset is nil-safe
function TestEkerSurrender:test_the_reset_returns_on_a_nil_player_and_raises_nothing_on_a_fresh_pilot()
	requireReset()
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetEkerQuests, CrimsonPhoenixSquadronScreenplay, nil), true, "resetEkerQuests(nil)")
	lu.assertEquals(pcall(CrimsonPhoenixSquadronScreenplay.resetEkerQuests, CrimsonPhoenixSquadronScreenplay, E.pilot({ graduated = false })), true, "a pilot with no tier 2 state")
end

-- A-6: a surrender with no tier 2 state at all
function TestEkerSurrender:test_surrendering_with_no_tier_2_state_raises_no_error()
	requireReset()

	local player = E.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- A-6: twice is the same as once
function TestEkerSurrender:test_surrendering_twice_is_the_same_as_once()
	requireReset()

	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(E.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-1, A-6: the resets run in the order Socuna, Eker, Burke, each once
function TestEkerSurrender:test_a_crimson_phoenix_surrender_runs_socuna_then_eker_then_burke_once_each()
	requireReset()

	local order = {}
	local mts = M.mts()

	H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetSocunaQuests", function() order[#order + 1] = "resetSocunaQuests" end)
	H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetEkerQuests", function() order[#order + 1] = "resetEkerQuests" end)

	local burke = H.spyOn(mts, "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = graduate()

	surrender(player)
	lu.assertEquals(order, { "resetSocunaQuests", "resetEkerQuests", "burke" }, "the Crimson Phoenix surrender: the resets in order, each once")
	lu.assertEquals(#burke, 1, "resetBurkeQuests calls")
end

-- A-6: Eker's reset gets the surrendering pilot, and other squadrons do not run it
function TestEkerSurrender:test_ekers_reset_gets_the_pilot_and_other_squadrons_do_not_run_it()
	requireReset()

	local reset = H.spyOn(CrimsonPhoenixSquadronScreenplay, "resetEkerQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "VORTEX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(C.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetEkerQuests calls for CorSec, RSF, Havoc, Vortex, Black Epsilon, Inquisition and Storm pilots")

	local player = graduate()

	surrender(player)
	lu.assertEquals(#reset, 1, "resetEkerQuests calls for a Crimson Phoenix pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- A-6: the other squadrons' keys survive a Crimson Phoenix surrender (spot check)
function TestEkerSurrender:test_an_eker_reset_leaves_other_squadrons_keys_alone()
	requireReset()

	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	surrender(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
end

-- A-3, A-6: surrendering while inspect 15 has counted its first inspection clears the count, and the pending split starts nothing
function TestEkerSurrender:test_surrendering_inside_the_inspection_window_clears_the_count_and_the_split_starts_nothing()
	requireReset()

	local q = E.quest(E.I15)

	q:start()

	local player = E.pilot({ missions = 0, inShip = REBEL_SHIP, zone = "space_lok" })

	q:startQuest(player, "")
	H.advance(1500)

	local cargo = "stolen_data"

	H.inspect(player, H.worldAgent({ shipName = "imp_tie_fighter_tier2", cargo = cargo, zone = "space_lok" }), getHashCode(cargo))
	H.advance(0)
	lu.assertEquals(readData(player.objectID .. ":" .. q.className .. ":inspectCount:"), 1, "precondition: the first inspection is counted")

	local starts = H.spyOn(E.quest(E.S15), "startQuest")

	surrender(player)
	lu.assertEquals(readData(player.objectID .. ":" .. q.className .. ":inspectCount:"), 0, "the count is cleared by the surrender")
	H.advance(30000)
	lu.assertEquals(#starts, 0, E.S15 .. ": startQuest calls after the surrender")
	lu.assertEquals(E.state(player, E.I15), "none", E.I15 .. ": journal state")
	lu.assertEquals(E.state(player, E.S15), "none", E.S15 .. ": journal state")
end

return nil
