-- Vortex tier 2 part A: surrendering the pilot profession clears Brother Vrovel's progress (resetVrovelQuests), after V3-FX's reset and before Burke's.
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (A-6; Content contract 2 and 3; D-5; SC-3).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_rebel_surrender.lua; the order test here adds "each once" and the pilot each reset receives.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local V1 = require("vortex_tier1_data")
local V = require("vortex_tier2_data")

M.load()
V.load()

local KEYS = V.statusKeys()

local REBEL_SHIP = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") }

-- A graduate who carries every kind of tier 2 state: the four missions complete (all 6 members), the 8 status keys, a duty complete, the four tier 2 skills,
-- pilot tier 3, plus V3-FX's state (the tier 1 resets still run)
local function graduate(extra)
	local o = { missions = 4, t2 = 4 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	local player = V.pilot(o)

	V.setState(player, V.DUTY6, "complete")

	return player
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

-- a red run reads "resetVrovelQuests is missing", not "attempt to call a nil value"
local function requireReset()
	lu.assertEquals(type(VortexSquadronScreenplay.resetVrovelQuests), "function",
		"VortexSquadronScreenplay:resetVrovelQuests (screenplays/space/squadrons/VortexSquadronScreenplay.lua) is missing. Load problems: " .. V.problems())
end

TestVrovelSurrender = {}

function TestVrovelSurrender:setUp()
	H.reset()
	V.load()
end

-- A-6 (the setup itself)
function TestVrovelSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), (global == V.DUTY6) and "complete" or (V.IDENTITY[global].type:find("duty") and "none" or "complete"), global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#KEYS, 8, "tier 2 status keys")
	lu.assertEquals(H.getQuestStatus(player, V.VORTEX_PILOT_KEY), "2", "VORTEX_PILOT_KEY")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
	lu.assertEquals(V1.state(player, V1.P1), "complete", "a tier 1 journal entry")
end

-- A-6
function TestVrovelSurrender:test_surrendering_clears_the_nine_journal_entries_complete_and_active()
	requireReset()

	local player = graduate()

	V.setState(player, V.DUTY5, "active")
	V.setState(player, V.DUTY7, "complete")
	surrender(player)

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-6: active runs are cleared too (each of the 9 tables, one at a time)
function TestVrovelSurrender:test_surrendering_clears_an_active_run_of_each_of_the_nine_tables()
	requireReset()

	for _, global in ipairs(V.GLOBALS) do
		H.reset()

		local player = V.pilot({ missions = 0 })

		V.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(V.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-6
function TestVrovelSurrender:test_surrendering_removes_the_eight_status_keys()
	requireReset()

	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-6, D-5: everything V3-FX's reset clears goes too, VORTEX_PILOT_KEY included
function TestVrovelSurrender:test_surrendering_still_clears_v3fxs_state_and_the_graduation_key()
	requireReset()

	local player = surrender(graduate())

	for _, global in ipairs(V.TIER1_GLOBALS) do
		lu.assertEquals(V1.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for _, key in ipairs(V1.STATUS_NAMES) do
		lu.assertNil(H.getQuestStatus(player, key .. ":attempted"), key .. ":attempted after the surrender")
		lu.assertNil(H.getQuestStatus(player, key .. ":reward"), key .. ":reward after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, V.VORTEX_PILOT_KEY), "VORTEX_PILOT_KEY after the surrender")
end

-- A-6: the pilot profession goes, the pilot tier is reset
function TestVrovelSurrender:test_surrendering_removes_the_rebel_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.rebelPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-6: the inventory is untouched
function TestVrovelSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-6, D-5: resetVrovelQuests alone clears Vrovel's state and nothing else: VORTEX_PILOT_KEY, tier 1 state, skills, pilot tier and items stay
function TestVrovelSurrender:test_the_reset_alone_touches_only_vrovels_state()
	requireReset()

	local player = graduate()
	local skillsBefore = #V1.held(player)
	local inventoryBefore = #player.inventory.items

	VortexSquadronScreenplay:resetVrovelQuests(player)

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	lu.assertEquals(H.getQuestStatus(player, V.VORTEX_PILOT_KEY), "2", "VORTEX_PILOT_KEY is V3-FX's reset to remove, not Vrovel's (D-5)")

	for _, chain in ipairs(V1.CHAINS) do
		for _, global in ipairs(chain) do
			lu.assertEquals(V1.state(player, global), "complete", global .. ": tier 1 journal state is not touched")
		end
	end

	for _, name in ipairs(V1.STATUS_NAMES) do
		lu.assertEquals(H.getQuestStatus(player, name .. ":reward"), "1", name .. ":reward (tier 1) is not touched")
	end

	lu.assertEquals(#V1.held(player), skillsBefore, "tier 1 skills untouched")

	for _, skill in ipairs(V.tier2Skills(4)) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " untouched")
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-6: the reset asks each of the nine tables once, with the pilot
function TestVrovelSurrender:test_the_reset_calls_reset_quest_on_all_nine_tables()
	requireReset()

	local spies = {}

	for _, g in ipairs(V.GLOBALS) do
		spies[g] = H.spyOn(V.quest(g), "resetQuest")
	end

	local player = graduate()

	VortexSquadronScreenplay:resetVrovelQuests(player)

	for _, g in ipairs(V.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- A-6: the reset is nil-safe
function TestVrovelSurrender:test_the_reset_returns_on_a_nil_player_and_raises_nothing_on_a_fresh_pilot()
	requireReset()
	lu.assertEquals(pcall(VortexSquadronScreenplay.resetVrovelQuests, VortexSquadronScreenplay, nil), true, "resetVrovelQuests(nil)")
	lu.assertEquals(pcall(VortexSquadronScreenplay.resetVrovelQuests, VortexSquadronScreenplay, V.pilot({ graduated = false })), true, "a pilot with no tier 2 state")
end

-- A-6: a surrender with no tier 2 state at all
function TestVrovelSurrender:test_surrendering_with_no_tier_2_state_raises_no_error()
	requireReset()

	local player = V.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- A-6: twice is the same as once
function TestVrovelSurrender:test_surrendering_twice_is_the_same_as_once()
	requireReset()

	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(V.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-6: the resets run in the order V3-FX, Vrovel, Burke, each once
function TestVrovelSurrender:test_a_vortex_surrender_runs_v3fx_then_vrovel_then_burke_once_each()
	requireReset()

	local order = {}
	local mts = M.mts()

	H.spyOn(VortexSquadronScreenplay, "resetV3fxQuests", function() order[#order + 1] = "resetV3fxQuests" end)
	H.spyOn(VortexSquadronScreenplay, "resetVrovelQuests", function() order[#order + 1] = "resetVrovelQuests" end)

	local burke = H.spyOn(mts, "resetBurkeQuests", function() order[#order + 1] = "burke" end)
	local player = graduate()

	surrender(player)
	lu.assertEquals(order, { "resetV3fxQuests", "resetVrovelQuests", "burke" }, "the Vortex surrender: the resets in order, each once")
	lu.assertEquals(#burke, 1, "resetBurkeQuests calls")
end

-- A-6: Vrovel's reset gets the surrendering pilot, and other squadrons do not run it
function TestVrovelSurrender:test_vrovels_reset_gets_the_pilot_and_other_squadrons_do_not_run_it()
	requireReset()

	local reset = H.spyOn(VortexSquadronScreenplay, "resetVrovelQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "CRIMSON_PHOENIX_SQUADRON", "rebel" },
		{ "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(V1.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetVrovelQuests calls for CorSec, RSF, Havoc, Crimson Phoenix, Black Epsilon, Inquisition and Storm pilots")

	local player = graduate()

	surrender(player)
	lu.assertEquals(#reset, 1, "resetVrovelQuests calls for a Vortex pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- A-6: the other squadrons' keys survive a Vortex surrender (spot check)
function TestVrovelSurrender:test_a_vrovel_reset_leaves_other_squadrons_keys_alone()
	requireReset()

	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "tatooine_imperial_1:reward", "1")
	surrender(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:reward"), "1", "Storm's key")
end

-- A-3, A-6, D-8: surrendering while inspect 1 has counted its first inspection clears the count, and the pending split starts nothing
function TestVrovelSurrender:test_surrendering_inside_the_inspection_window_clears_the_count_and_the_split_starts_nothing()
	requireReset()

	local q = V.quest(V.I1)

	q:start()

	local player = V.pilot({ missions = 0, inShip = REBEL_SHIP, zone = "space_lok" })

	q:startQuest(player, "")
	H.advance(1500)

	local cargo = "stolen_data"

	H.inspect(player, H.worldAgent({ shipName = "imp_tie_fighter_tier2", cargo = cargo, zone = "space_lok" }), getHashCode(cargo))
	H.advance(0)
	lu.assertEquals(readData(player.objectID .. ":" .. q.className .. ":inspectCount:"), 1, "precondition: the first inspection is counted")

	local starts = H.spyOn(V.quest(V.S1), "startQuest")

	surrender(player)
	lu.assertEquals(readData(player.objectID .. ":" .. q.className .. ":inspectCount:"), 0, "the count is cleared by the surrender")
	H.advance(30000)
	lu.assertEquals(#starts, 0, V.S1 .. ": startQuest calls after the surrender")
	lu.assertEquals(V.state(player, V.I1), "none", V.I1 .. ": journal state")
	lu.assertEquals(V.state(player, V.S1), "none", V.S1 .. ": journal state")
end

return nil
