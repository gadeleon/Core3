-- /object spacespawn list/spawn/despawn (SpaceSpawnerScreenPlay:admin), tried on Kessel's corvette convoys
local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.loadScreenplay("space/spawning/space_spawner.lua")
H.loadScreenplay("space/spawning/space_light1_spawner.lua")

local CONVOYS = {
	corvette_convoy_imperial = { corvette = "imp_corellian_corvette_tier4", gunboat = "imp_imperial_gunboat_tier5" },
	corvette_convoy_rebel = { corvette = "reb_corellian_corvette_tier4", gunboat = "reb_gunboat_tier5" },
}

local function admin()
	return H.newPlayer { pilot = "neutral", zone = "space_light1" }
end

local function texts(player)
	local out = {}
	for _, m in ipairs(H.messageLog(player)) do out[#out + 1] = tostring(m.text or m.id) end
	return table.concat(out, "\n")
end

local function spawnIndex(name) return SpaceLight1Spawner:findSpawnIndex(name) end

TestSpaceSpawnerAdmin = {}

function TestSpaceSpawnerAdmin:setUp() H.reset() end

for name, c in pairs(CONVOYS) do
	TestSpaceSpawnerAdmin["test_admin_spawn_and_despawn_" .. name] = function()
		local player = admin()

		SpaceLight1Spawner:admin(player, "spawn", "space_light1", name)
		H.advance(10)
		lu.assertEquals(#SpaceLight1Spawner:getTrackedShips(name), 10, name .. ": tracked after the spawn")
		lu.assertStrContains(texts(player), "Spawning " .. name)

		local events = #H.pendingEvents()

		SpaceLight1Spawner:admin(player, "despawn", "space_light1", name)
		H.advance(10)

		lu.assertEquals(#SpaceLight1Spawner:getTrackedShips(name), 0, name .. ": none left")
		for _, a in ipairs(H.spawnedShips()) do
			lu.assertNil(getSceneObject(SceneObject(a):getObjectID()), name .. ": " .. a.shipName .. " removed")
		end
		lu.assertTrue(#H.pendingEvents() <= events, name .. ": no respawn scheduled by the despawn")
	end
end

function TestSpaceSpawnerAdmin:test_admin_list_and_bad_names()
	local player = admin()

	SpaceLight1Spawner:admin(player, "list", "space_light1", "corvette")
	local out = texts(player)
	lu.assertStrContains(out, "corvette_convoy_imperial at 7400 7500 7384")
	lu.assertStrContains(out, "corvette_convoy_rebel at 7479 -7520 -7482")
	lu.assertStrContains(out, "2 spawner(s)")

	SpaceSpawnerScreenPlay:admin(player, "spawn", "space_light1", "nope")
	lu.assertStrContains(texts(player), "No spawner named nope")

	SpaceSpawnerScreenPlay:admin(player, "spawn", "space_nowhere", "x")
	lu.assertStrContains(texts(player), "No space spawner for zone space_nowhere")
end
