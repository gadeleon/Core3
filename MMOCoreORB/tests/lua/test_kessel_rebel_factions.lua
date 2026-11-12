-- Kessel (space_light1): Rebel ships are not aggressive to Smuggler's Alliance pilots (hutt), Imperials stay hostile.
-- Pre-CU behaviour per the user (2026-11-12); applied per spawn so template names (master-mission kill counts) are unchanged.
local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.loadScreenplay("space/spawning/space_spawner.lua")
H.loadScreenplay("space/spawning/space_light1_spawner.lua")

TestKesselRebelFactions = {}

function TestKesselRebelFactions:setUp() H.reset() end

local function agent(faction)
	local a = Fakes.newShipAgent { shipName = "reb_xwing_tier5" }
	a.shipFactionString = faction
	return a
end

function TestKesselRebelFactions:test_kessel_spawner_drops_hutt_from_rebel_enemies()
	lu.assertEquals(SpaceLight1Spawner.removeEnemyFactions, { rebel = { "hutt" } })

	local rebel = agent("rebel")
	SpaceLight1Spawner:applyFactionOverrides(rebel)
	lu.assertEquals(rebel.removedFactionEnemies, { getHashCode("hutt") })
end

function TestKesselRebelFactions:test_imperials_and_others_untouched()
	for _, faction in ipairs({ "imperial", "blacksun", "pirate" }) do
		local a = agent(faction)
		SpaceLight1Spawner:applyFactionOverrides(a)
		lu.assertEquals(a.removedFactionEnemies, {}, faction)
	end
end

function TestKesselRebelFactions:test_other_zones_untouched()
	lu.assertNil(SpaceSpawnerScreenPlay.removeEnemyFactions)

	local rebel = agent("rebel")
	SpaceSpawnerScreenPlay:applyFactionOverrides(rebel)
	lu.assertEquals(rebel.removedFactionEnemies, {})
end
