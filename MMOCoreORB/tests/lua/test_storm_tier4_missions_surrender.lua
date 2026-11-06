-- Storm tier 4 part A (Admiral Kilnstrider's missions): surrendering the pilot profession clears Kilnstrider's progress (resetKilnstriderQuests), after
-- Colzet's, Oberhaur's, Alozen's and Denner's resets and before Declann's.
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (A-5; Content contract 2 and 3; D-A3, D-A7, D-A8).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_imperial_surrender.lua and test_storm_tier3_missions_surrender.lua; the order test here adds Kilnstrider's
-- reset and the "each once" rule.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local D = require("storm_tier4_data")
local D3 = require("storm_tier3_data")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")
local M = require("master_trainer_imperial_data")

D.load()

local KEYS = D.statusKeys()

local SHIP = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") }

-- A graduate who carries every kind of Kilnstrider state: the four missions complete (all 16 story members), every status key (8 head keys and the met key),
-- an active duty, plus Denner's, Alozen's, Oberhaur's and Colzet's state (the surrender clears those through their own resets)
local function graduate(extra)
	local o = { missions = 4, met = true, active = D.DUTIES[1] }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

TestStormT4Surrender = {}

function TestStormT4Surrender:setUp()
	H.reset()
	D.load()
end

function TestStormT4Surrender:tearDown() AC.tearDown() end

-- A-5 (the setup itself)
function TestStormT4Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(D.STORY) do
		lu.assertEquals(D.state(player, global), "complete", global .. ": journal state")
	end

	lu.assertEquals(D.state(player, D.DUTIES[1]), "active", D.DUTIES[1] .. ": the active duty")

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	for _, global in ipairs(D3.GLOBALS) do
		lu.assertEquals(D3.state(player, global), "complete", global .. ": Denner's journal state")
	end

	lu.assertEquals(#KEYS, 9, "tier 4 status keys (8 head keys and the met key)")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
end

-- A-5
function TestStormT4Surrender:test_surrendering_clears_the_twenty_journal_entries()
	local player = surrender(graduate())

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-5: active runs are cleared too (each of the 20 tables, one at a time)
function TestStormT4Surrender:test_surrendering_clears_an_active_run_of_each_of_the_twenty_tables()
	for _, global in ipairs(D.GLOBALS) do
		H.reset()

		local player = D.pilot({})

		D.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(D.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-5, D-A8: the nine keys go (the eight head keys and the met key)
function TestStormT4Surrender:test_surrendering_removes_the_nine_status_keys()
	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-5: Denner's, Alozen's, Oberhaur's and Colzet's state goes too (their resets still run)
function TestStormT4Surrender:test_surrendering_still_clears_denners_alozens_oberhaurs_and_colzets_state()
	local player = surrender(graduate())

	for _, global in ipairs(D3.GLOBALS) do
		lu.assertEquals(D3.state(player, global), "none", global .. ": Denner's journal state after the surrender")
	end

	for _, key in ipairs(D3.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(A.state(player, global), "none", global .. ": Alozen's journal state after the surrender")
	end

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": Oberhaur's journal state after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, T.SERIES_SUFFIX), "Colzet's series flag after the surrender")
end

-- A-5: the pilot profession goes, the pilot tier is reset
function TestStormT4Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-5: the inventory is untouched
function TestStormT4Surrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-5: each of the 20 tier 4 tables' resetQuest is called once, with the pilot
function TestStormT4Surrender:test_surrendering_calls_each_tier_4_tables_reset_quest_once()
	local spies = {}

	for _, global in ipairs(D.GLOBALS) do
		spies[global] = H.spyOn(D.quest(global), "resetQuest")
	end

	local storm = graduate()

	surrender(storm)

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(#spies[global], 1, global .. ": resetQuest calls")
		lu.assertEquals(spies[global][1].args[1], storm, global .. ": resetQuest gets the pilot")
	end
end

-- A-5: resetKilnstriderQuests alone clears Kilnstrider's state and nothing else (the tier 1-3 keys and journal entries are their own resets')
function TestStormT4Surrender:test_the_reset_alone_touches_only_kilnstriders_state()
	local player = graduate()
	local sq = D.squadron()
	local skillsBefore = #A.held(player)
	local inventoryBefore = #player.inventory.items

	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")
	sq:resetKilnstriderQuests(player)

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	for _, global in ipairs(D3.GLOBALS) do
		lu.assertEquals(D3.state(player, global), "complete", global .. ": Denner's journal state is not touched")
	end

	for _, key in ipairs(D3.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (Denner's status key) is not touched")
	end

	for _, global in ipairs(A.MISSIONS) do
		lu.assertEquals(A.state(player, global), "complete", global .. ": Alozen's journal state is not touched")
	end

	for _, global in ipairs(T.MISSIONS) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": Oberhaur's journal state is not touched")
	end

	for _, key in ipairs(A.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (Alozen's status key) is not touched")
	end

	for _, suffix in ipairs({ T.INITIATE_SUFFIX, T.ALOZEN_SUFFIX, T.SERIES_SUFFIX }) do
		lu.assertEquals(H.getQuestStatus(player, suffix), "1", suffix .. " is owned by Oberhaur's or Colzet's reset")
	end

	lu.assertEquals(#A.held(player), skillsBefore, "skills untouched")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-5: the reset is nil-safe
function TestStormT4Surrender:test_the_reset_returns_on_a_nil_player()
	local sq = D.squadron()

	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")
	lu.assertEquals(pcall(sq.resetKilnstriderQuests, sq, nil), true, "resetKilnstriderQuests(nil)")
end

-- A-5: Kilnstrider's reset on a pilot with no tier 4 state at all
function TestStormT4Surrender:test_surrendering_with_no_tier_4_state_raises_no_error()
	local player = D.pilot({})
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
	lu.assertEquals(type(D.squadron().resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")
end

-- A-5: a pilot who has not even finished tier 2 surrenders without an error
function TestStormT4Surrender:test_surrendering_a_tier_2_pilot_raises_no_error()
	local player = A.pilot({ t2 = {}, alozen = false, initiate = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
	lu.assertEquals(type(D.squadron().resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")
end

-- A-5: twice is the same as once
function TestStormT4Surrender:test_surrendering_twice_is_the_same_as_once()
	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after two surrenders")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after two surrenders")
	end
end

-- A-5: the resets run in the order Colzet, Oberhaur, Alozen, Denner, Kilnstrider, Declann, each once; other squadrons do not run Kilnstrider's
function TestStormT4Surrender:test_a_storm_surrender_runs_the_six_resets_once_each_in_order_and_other_squadrons_do_not_run_kilnstriders()
	local order = {}
	local mts = M.mts() -- loads Declann's pieces first: a later load would replace the squadron table the spies sit on
	local sq = D.squadron()

	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")

	for _, name in ipairs({ "resetColzetQuests", "resetOberhaurQuests", "resetAlozenQuests", "resetDennerQuests", "resetKilnstriderQuests" }) do
		H.spyOn(sq, name, function() order[#order + 1] = name end)
	end

	local reset = H.spyOn(mts, "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	local storm = graduate()

	surrender(storm)
	lu.assertEquals(order, { "resetColzetQuests", "resetOberhaurQuests", "resetAlozenQuests", "resetDennerQuests", "resetKilnstriderQuests", "declann" }, "the Storm surrender: the resets in order, each once")
	lu.assertEquals(#reset, 1, "resetDeclannQuests calls")

	order = {}

	local inquisition = A.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })

	H.setQuestStatus(inquisition, D.MET_KEY, 1)
	surrender(inquisition)

	for _, name in ipairs(order) do
		lu.assertNotEquals(name, "resetKilnstriderQuests", "an Inquisition pilot must not run Kilnstrider's reset")
		lu.assertNotEquals(name, "resetDennerQuests", "an Inquisition pilot must not run Denner's reset")
	end

	lu.assertEquals(H.getQuestStatus(inquisition, D.MET_KEY), "1", "an Inquisition pilot's surrender does not clear the Storm met key")
	lu.assertEquals(inquisition.ghost.pilotTier, 0, "the Inquisition pilot still surrenders: pilot tier")
end

-- A-5: Black Epsilon does not run it either
function TestStormT4Surrender:test_a_black_epsilon_surrender_does_not_run_kilnstriders_reset()
	local mts = M.mts()
	local sq = D.squadron()

	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")

	local calls = H.spyOn(sq, "resetKilnstriderQuests")
	local reset = H.spyOn(mts, "resetDeclannQuests")
	local pilot = M.pilot({ squadron = "black_epsilon" })

	surrender(pilot)
	lu.assertEquals(#calls, 0, "resetKilnstriderQuests calls for a Black Epsilon pilot")
	lu.assertEquals(#reset, 1, "resetDeclannQuests calls for a Black Epsilon pilot (as before)")
end

-- A-5: Kilnstrider's reset gets the pilot
function TestStormT4Surrender:test_kilnstriders_reset_gets_the_surrendering_pilot()
	local sq = D.squadron()

	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests")

	local calls = H.spyOn(sq, "resetKilnstriderQuests")
	local storm = graduate()

	surrender(storm)
	lu.assertEquals(#calls, 1, "resetKilnstriderQuests calls for a Storm pilot")
	lu.assertEquals(calls[1].args[1], storm, "the reset gets the pilot")
end

-- A-5: a running assassinate 4 (Dantooine: the target and six escorts in space) is torn down by the surrender
function TestStormT4Surrender:test_surrendering_in_the_middle_of_assassinate_4_removes_its_ships()
	local q = D.quest(D.M4[1])

	q:start()

	local player = D.pilot({ inShip = SHIP, zone = D.ZONE_M4 })

	q:startQuest(player, "")
	H.advance(40000)

	local before = {}

	for i, ship in ipairs(H.spawnedShips()) do
		before[i] = ship
	end

	lu.assertTrue(#before >= 1, "precondition: the target and escorts were deployed")
	surrender(player)
	H.advance(5000)
	lu.assertEquals(D.state(player, D.M4[1]), "none", "the assassinate's journal entry is cleared")

	for _, ship in ipairs(before) do
		lu.assertTrue(ship.destroyed == true, "the ship '" .. tostring(ship.shipName) .. "' is gone after the surrender")
	end
end

return nil
