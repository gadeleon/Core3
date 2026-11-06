-- Storm tier 3 part A (Captain Denner's missions): surrendering the pilot profession clears Denner's progress (resetDennerQuests), after Colzet's,
-- Oberhaur's and Alozen's resets and before Declann's.
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (A-6; Content contract 2 and 3; D-8; SC-3; T1 D-11).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field. The order of the
-- resets is also pinned in test_master_trainer_imperial_surrender.lua; the order test here adds Denner's reset and the "each once" rule.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local D = require("storm_tier3_data")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")
local M = require("master_trainer_imperial_data")

D.load()

local KEYS = D.statusKeys()

local SHIP = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") }

-- A graduate who carries every kind of Denner state: the four missions complete (all 20 members), every status key, four tier 3 skills, pilot tier 4,
-- plus Alozen's, Oberhaur's and Colzet's state (the surrender clears those through their own resets)
local function graduate(extra)
	local o = { missions = 4, t3 = { 1, 2, 3, 4 } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

TestStormT3Surrender = {}

function TestStormT3Surrender:setUp()
	H.reset()
	D.load()
end

function TestStormT3Surrender:tearDown() AC.tearDown() end

-- A-6 (the setup itself)
function TestStormT3Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	for _, global in ipairs(A.MISSIONS) do
		lu.assertEquals(A.state(player, global), "complete", global .. ": Alozen's journal state")
	end

	lu.assertEquals(#KEYS, 8, "tier 3 status keys")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
end

-- A-6
function TestStormT3Surrender:test_surrendering_clears_the_twenty_journal_entries_complete()
	local player = surrender(graduate())

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- A-6: active runs are cleared too (each of the 20 tables, one at a time)
function TestStormT3Surrender:test_surrendering_clears_an_active_run_of_each_of_the_twenty_members()
	for _, global in ipairs(D.GLOBALS) do
		H.reset()

		local player = D.pilot({ missions = 0 })

		D.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(D.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- A-6
function TestStormT3Surrender:test_surrendering_removes_the_eight_status_keys()
	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- A-6: Alozen's, Oberhaur's and Colzet's state goes too (their resets still run)
function TestStormT3Surrender:test_surrendering_still_clears_alozens_oberhaurs_and_colzets_state()
	local player = surrender(graduate())

	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(A.state(player, global), "none", global .. ": Alozen's journal state after the surrender")
	end

	for _, key in ipairs(A.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": Oberhaur's journal state after the surrender")
	end

	for _, suffix in ipairs(T.FLAG_SUFFIXES) do
		lu.assertNil(H.getQuestStatus(player, suffix), suffix .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, T.SERIES_SUFFIX), "Colzet's series flag after the surrender")
end

-- A-6: the pilot profession goes, the pilot tier is reset
function TestStormT3Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- A-6: the inventory is untouched
function TestStormT3Surrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- A-6: resetDennerQuests alone clears Denner's state and nothing else (T1 D-11)
function TestStormT3Surrender:test_the_reset_alone_touches_only_denners_state()
	local player = graduate()
	local sq = D.squadron()
	local skillsBefore = #A.held(player)
	local inventoryBefore = #player.inventory.items

	sq:resetDennerQuests(player)

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
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

	for _, key in ipairs({ "imperial_ss_1:attempted", "imperial_ss_1:reward", "imperial_ss_3:reward" }) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (Oberhaur's status key) is not touched")
	end

	for _, suffix in ipairs({ T.INITIATE_SUFFIX, T.ALOZEN_SUFFIX, T.SERIES_SUFFIX }) do
		lu.assertEquals(H.getQuestStatus(player, suffix), "1", suffix .. " is owned by Oberhaur's or Colzet's reset")
	end

	lu.assertEquals(#A.held(player), skillsBefore, "skills untouched")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- A-6: the reset is nil-safe
function TestStormT3Surrender:test_the_reset_returns_on_a_nil_player()
	lu.assertEquals(pcall(D.squadron().resetDennerQuests, D.squadron(), nil), true, "resetDennerQuests(nil)")
end

-- A-6: Denner's reset on a pilot with no tier 3 state at all
function TestStormT3Surrender:test_surrendering_with_no_tier_3_state_raises_no_error()
	local player = A.pilot({ t2 = {}, alozen = false, initiate = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- A-6: twice is the same as once
function TestStormT3Surrender:test_surrendering_twice_is_the_same_as_once()
	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(D.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- A-6: the five resets run in the order Colzet, Oberhaur, Alozen, Denner, Declann, each once; other squadrons do not run Denner's
function TestStormT3Surrender:test_a_storm_surrender_runs_the_five_resets_once_each_in_order_and_other_squadrons_do_not_run_denners()
	local order = {}
	local mts = M.mts() -- loads Declann's pieces first: a later load would replace the squadron table the spies sit on
	local sq = D.squadron()

	for _, name in ipairs({ "resetColzetQuests", "resetOberhaurQuests", "resetAlozenQuests", "resetDennerQuests" }) do
		H.spyOn(sq, name, function() order[#order + 1] = name end)
	end

	local reset = H.spyOn(mts, "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	local storm = graduate()

	surrender(storm)
	lu.assertEquals(order, { "resetColzetQuests", "resetOberhaurQuests", "resetAlozenQuests", "resetDennerQuests", "declann" }, "the Storm surrender: the resets in order, each once")
	lu.assertEquals(#reset, 1, "resetDeclannQuests calls")

	order = {}

	local inquisition = A.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })

	surrender(inquisition)

	for _, name in ipairs(order) do
		lu.assertNotEquals(name, "resetDennerQuests", "an Inquisition pilot must not run Denner's reset")
		lu.assertNotEquals(name, "resetAlozenQuests", "an Inquisition pilot must not run Alozen's reset")
	end
end

-- A-6: Denner's reset gets the pilot
function TestStormT3Surrender:test_denners_reset_gets_the_surrendering_pilot()
	local calls = H.spyOn(D.squadron(), "resetDennerQuests")
	local storm = graduate()

	surrender(storm)
	lu.assertEquals(#calls, 1, "resetDennerQuests calls for a Storm pilot")
	lu.assertEquals(calls[1].args[1], storm, "the reset gets the pilot")
end

-- A-6: a running escort 3_a (spawned ships, a half-counted wave, the observers) is torn down by the surrender
function TestStormT3Surrender:test_surrendering_in_the_middle_of_escort_3_a_removes_its_ships_and_counter()
	local q = D.quest(D.M3[3])

	q:start()

	local player = D.pilot({ missions = 0, inShip = SHIP, zone = D.ZONE })

	q:startQuest(player, "")
	H.advance(2500)

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	H.advance(11000)
	lu.assertNotNil(getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:")), "precondition: the escort ship flies")

	local before = {}

	for i, ship in ipairs(H.spawnedShips()) do
		before[i] = ship
	end

	writeData(player.objectID .. ":" .. q.className .. ":wavesCleared:", 2) -- two waves cleared (D-A4)
	surrender(player)
	H.advance(5000)

	lu.assertEquals(D.state(player, D.M3[3]), "none", "the escort's journal entry is cleared")
	lu.assertEquals(readData(player.objectID .. ":" .. q.className .. ":wavesCleared:"), 0, "the wave counter is cleared")

	for _, ship in ipairs(before) do
		lu.assertTrue(ship.destroyed == true, "the ship '" .. tostring(ship.shipName) .. "' is gone after the surrender")
	end
end

return nil
