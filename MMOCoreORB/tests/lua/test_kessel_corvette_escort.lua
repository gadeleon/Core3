-- Kessel corvette convoys: the gunboats fly the escort AI (stay with the corvette), the fighters do not
local lu = require("luaunit")
local H = require("harness")

H.loadScreenplay("space/spawning/space_spawner.lua")
H.loadScreenplay("space/spawning/space_light1_spawner.lua")

local CONVOYS = {
	corvette_convoy_imperial = { corvette = "imp_corellian_corvette_tier4", gunboat = "imp_imperial_gunboat_tier5" },
	corvette_convoy_rebel = { corvette = "reb_corellian_corvette_tier4", gunboat = "reb_gunboat_tier5" },
}

local function spawnIndex(name)
	for i, t in ipairs(SpaceLight1Spawner.shipSpawns) do
		if t.spawnName == name then return i end
	end
end

TestKesselCorvetteEscort = {}

function TestKesselCorvetteEscort:setUp() H.reset() end

for name, c in pairs(CONVOYS) do
	TestKesselCorvetteEscort["test_only_gunboats_fly_escort_in_" .. name] = function()
		SpaceLight1Spawner:spawnShipSquadron(nil, tostring(spawnIndex(name)))

		local ships = H.spawnedShips()
		lu.assertEquals(#ships, 10, name .. ": the whole squadron")

		local gunboats = 0

		for _, a in ipairs(ships) do
			if (a.shipName == c.gunboat) then
				gunboats = gunboats + 1
				lu.assertEquals(a.escortCalls, 1, name .. ": gunboat escort")
			else
				lu.assertEquals(a.escortCalls, 0, name .. ": " .. a.shipName .. " chases")
			end
		end

		lu.assertEquals(gunboats, 2, name)
		lu.assertEquals(ships[1].shipName, c.corvette, name .. ": the corvette leads")
	end
end

function TestKesselCorvetteEscort:test_other_kessel_squadrons_have_no_escorts()
	local t = SpaceLight1Spawner.shipSpawns[spawnIndex("kessel_lootship_escort_imp")]
	lu.assertNil(t.escortShips)
end
