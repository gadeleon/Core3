-- Single patrol rotation spawners (SWG patrolNoRecycle): the whole route in order, then the ships leave and respawn
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

TestSpaceSpawnerRoutes = {}

function TestSpaceSpawnerRoutes:setUp() H.reset() end

local function called(agent, name)
	for _, c in ipairs(agent.callLog) do
		if c.name == name then return true end
	end
	return false
end

for name, c in pairs(CONVOYS) do
	-- SWG patrolNoRecycle: the squadron flies every patrol point in order
	TestSpaceSpawnerRoutes["test_the_corvette_leads_the_whole_route_in_order_" .. name] = function()
		SpaceLight1Spawner:spawnShipSquadron(nil, tostring(spawnIndex(name)))

		local ships = H.spawnedShips()
		local corvette = ships[1]
		local route = SpaceLight1Spawner.shipSpawns[spawnIndex(name)].fixedPatrolPoints

		lu.assertEquals(corvette.fixedPatrolPointNames, route, name .. ": all points, first to last")
		lu.assertTrue(called(corvette, "setSinglePatrolRotation"), name .. ": single rotation")
		lu.assertEquals(H.Engine.observerCount(DESTINATIONREACHED, "SpaceLight1Spawner", "squadronDestinationReached", corvette), 1, name)

		for i = 2, #ships do
			lu.assertNil(ships[i].fixedPatrolPointNames, name .. ": " .. ships[i].shipName .. " follows the squadron")
			lu.assertEquals(H.Engine.observerCount(DESTINATIONREACHED, "SpaceLight1Spawner", "squadronDestinationReached", ships[i]), 0, name)
		end
	end

	-- SWG leaderSpawnerArrival: at the end of the route the whole squadron leaves, then the spawner respawns it
	TestSpaceSpawnerRoutes["test_end_of_route_removes_the_squadron_and_schedules_one_respawn_" .. name] = function()
		local index = spawnIndex(name)
		SpaceLight1Spawner:spawnShipSquadron(nil, tostring(index))

		local ships = H.spawnedShips()
		local count = #ships

		-- one fighter already shot down: it is gone and scheduled nothing
		H.fireObservers(SHIPDESTROYED, ships[5], nil, count)
		Fakes.destroy(ships[5])

		H.fireObservers(DESTINATIONREACHED, ships[1])
		H.advance(1000)

		for i, a in ipairs(ships) do
			lu.assertNil(getSceneObject(SceneObject(a):getObjectID()), name .. ": " .. a.shipName .. " #" .. i .. " left")
		end

		local respawns = 0
		for _, e in ipairs(H.pendingEvents()) do
			if e.method == "spawnShipSquadron" and e.args == tostring(index) then respawns = respawns + 1 end
		end
		lu.assertEquals(respawns, 1, name .. ": one respawn")

		H.advance(2400 * 1000)
		lu.assertEquals(#H.spawnedShips(), count * 2, name .. ": respawned")
	end
end

-- Every zone: the lead ship of a single patrol rotation squadron gets the whole route, first point to last
-- (patrolsToAssign is not used for them), and nobody else in the squadron gets a route
local ZONE_SPAWNERS = {
	SpaceCorelliaSpawner = "space_corellia_spawner.lua", SpaceDantooineSpawner = "space_dantooine_spawner.lua",
	SpaceDathomirSpawner = "space_dathomir_spawner.lua", SpaceEndorSpawner = "space_endor_spawner.lua",
	SpaceHeavy1Spawner = "space_heavy1_spawner.lua", SpaceLight1Spawner = "space_light1_spawner.lua",
	SpaceLokSpawner = "space_lok_spawner.lua", SpaceNabooSpawner = "space_naboo_spawner.lua",
	SpaceTatooineSpawner = "space_tatooine_spawner.lua", SpaceYavin4Spawner = "space_yavin4_spawner.lua",
}

function TestSpaceSpawnerRoutes:test_every_single_rotation_squadron_flies_its_whole_route()
	local checked = 0

	for global, file in pairs(ZONE_SPAWNERS) do
		H.loadScreenplay("space/spawning/" .. file)
		local spawner = _G[global]

		for idx, spawn in ipairs(spawner.shipSpawns) do
			if (spawn.spawnType == SHIP_SPAWN_SQUADRON and spawn.patrolType == SHIP_AI_SINGLE_PATROL_ROTATION) then
				H.reset()
				spawner:spawnShipSquadron(nil, tostring(idx))

				local leads = {}
				for _, a in ipairs(H.spawnedShips()) do
					if (a.fixedPatrolPointNames ~= nil) then leads[#leads + 1] = a end
				end

				local label = global .. " " .. spawn.spawnName
				lu.assertEquals(#leads, 1, label .. ": one ship leads the route")
				lu.assertEquals(leads[1].fixedPatrolPointNames, spawn.fixedPatrolPoints, label .. ": the whole route in order")
				lu.assertEquals(H.Engine.observerCount(DESTINATIONREACHED, global, "squadronDestinationReached", leads[1]), 1, label)

				checked = checked + 1
			end
		end
	end

	lu.assertEquals(checked, 27, "single rotation squadron spawners")
end

-- Every zone: a single ship on a single patrol rotation gets the whole route, first point to last, and at the end
-- flies away with exactly one respawn of itself
function TestSpaceSpawnerRoutes:test_every_single_rotation_ship_flies_its_whole_route()
	local checked = 0

	for global, file in pairs(ZONE_SPAWNERS) do
		H.loadScreenplay("space/spawning/" .. file)
		local spawner = _G[global]

		for idx, spawn in ipairs(spawner.shipSpawns) do
			if (spawn.spawnType == SHIP_SPAWN_SINGLE and spawn.patrolType == SHIP_AI_SINGLE_PATROL_ROTATION) then
				H.reset()
				spawner:spawnShipAgent(nil, tostring(idx))

				local ships = H.spawnedShips()
				local label = global .. " " .. spawn.spawnName

				lu.assertEquals(#ships, 1, label)
				lu.assertEquals(ships[1].fixedPatrolPointNames, spawn.fixedPatrolPoints, label .. ": the whole route in order")
				lu.assertTrue(called(ships[1], "setSinglePatrolRotation"), label)
				lu.assertEquals(H.Engine.observerCount(DESTINATIONREACHED, global, "shipDestinationReached", ships[1]), 1, label)

				checked = checked + 1
			end
		end
	end

	lu.assertTrue(checked > 0, "single rotation single ship spawners")
	print("single rotation single ship spawners: " .. checked)
end

function TestSpaceSpawnerRoutes:test_single_ship_end_of_route_leaves_and_schedules_one_respawn()
	local idx = spawnIndex("rebel_tier5Patrol_12")

	SpaceLight1Spawner:spawnShipAgent(nil, tostring(idx))
	local ship = H.spawnedShips()[1]

	H.fireObservers(DESTINATIONREACHED, ship)
	H.advance(1000)

	lu.assertNil(getSceneObject(SceneObject(ship):getObjectID()), "flown away")

	local respawns = 0
	for _, e in ipairs(H.pendingEvents()) do
		if (e.method == "spawnShipAgent") then respawns = respawns + 1 end
	end
	lu.assertEquals(respawns, 1)
end
