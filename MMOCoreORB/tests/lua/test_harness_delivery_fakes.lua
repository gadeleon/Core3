-- Harness additions for space-quest-stub-delivery: fake agent taunts and faction calls, H.dock,
-- and the parity check of the new fake methods against LuaShipAiAgent.cpp's binding table.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local BINDING_FILE = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"

local function readBindings()
	local f = io.open(BINDING_FILE, "r")
	lu.assertNotNil(f, "cannot read " .. BINDING_FILE)
	local src = f:read("a")
	f:close()

	local names = {}

	for name in src:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

local function spawn(x, z, y)
	return spawnShipAgent("transport", "space_corellia", x or 1, z or 2, y or 3, H.newShip({}))
end

TestDeliveryFakeAgent = {}

function TestDeliveryFakeAgent:setUp() H.reset() end

function TestDeliveryFakeAgent:test_taunt_player_is_recorded_with_time_on_the_agent_and_the_player()
	local player = H.newPlayer({ zone = "space_corellia" })
	local agent = spawn()

	H.advance(1500)
	ShipAiAgent(agent):tauntPlayer(player, "@spacequest/delivery/x:hello_p")

	lu.assertEquals(#H.tauntLog(player), 1, "player taunt log")
	lu.assertEquals(H.tauntLog(player)[1].t, 1500, "taunt time")
	lu.assertEquals(H.tauntLog(player)[1].msg, "@spacequest/delivery/x:hello_p", "taunt message")
	lu.assertEquals(H.tauntLog(player)[1].ship, agent, "taunting ship")
	lu.assertEquals(#agent.taunts, 1, "agent taunt log")
end

function TestDeliveryFakeAgent:test_taunt_logs_are_per_player()
	local a, b = H.newPlayer({}), H.newPlayer({})

	ShipAiAgent(spawn()):tauntPlayer(a, "m")

	lu.assertEquals(#H.tauntLog(a), 1, "a")
	lu.assertEquals(#H.tauntLog(b), 0, "b")
end

function TestDeliveryFakeAgent:test_faction_ally_and_enemy_removal_are_recorded_per_agent()
	local first, second = spawn(), spawn()

	ShipAiAgent(first):addSpaceFactionAlly(111)
	ShipAiAgent(first):removeSpaceFactionEnemy(111)
	ShipAiAgent(first):addSpaceFactionAlly(222)

	lu.assertEquals(first.factionAllies, { 111, 222 }, "allies")
	lu.assertEquals(first.removedFactionEnemies, { 111 }, "removed enemies")
	lu.assertEquals(second.factionAllies, {}, "other agent untouched")
end

function TestDeliveryFakeAgent:test_agent_world_position_is_the_spawn_position()
	local agent = spawn(10, 20, 30)

	lu.assertEquals({ SceneObject(agent):getWorldPositionX(), SceneObject(agent):getWorldPositionZ(), SceneObject(agent):getWorldPositionY() }, { 10, 20, 30 }, "x z y")
end

TestDeliveryHDock = {}

function TestDeliveryHDock:setUp() H.reset() end

local seen

function TestDeliveryHDock.recorder(self, pPlayer, pTarget, cargoHash)
	seen[#seen + 1] = { pPlayer = pPlayer, pTarget = pTarget, cargoHash = cargoHash }
	return 0
end

function TestDeliveryHDock:test_dock_fires_ship_docked_on_the_player_with_target_and_cargo_hash()
	seen = {}
	TestDeliveryHDock.className = "TestDeliveryHDock"
	rawset(_G, "TestDeliveryHDockSp", { recorder = TestDeliveryHDock.recorder })

	local player = H.newPlayer({ zone = "space_corellia" })
	local ship = spawn()

	createObserver(SHIPDOCKED, "TestDeliveryHDockSp", "recorder", player)
	H.dock(player, ship)
	H.dock(player, ship, 42)

	rawset(_G, "TestDeliveryHDockSp", nil)

	lu.assertEquals(#seen, 2, "handler calls")
	lu.assertEquals(seen[1].pPlayer, player, "pilot")
	lu.assertEquals(seen[1].pTarget, ship, "target ship")
	lu.assertEquals(seen[1].cargoHash, 0, "default cargo hash")
	lu.assertEquals(seen[2].cargoHash, 42, "explicit cargo hash")
end

function TestDeliveryHDock:test_dock_with_no_observer_does_nothing()
	H.dock(H.newPlayer({}), spawn())
end

TestDeliveryBindingParity = {}

function TestDeliveryBindingParity:setUp() H.reset() end

function TestDeliveryBindingParity:test_every_new_fake_agent_method_is_a_real_binding()
	local bindings = readBindings()
	local agent = spawn()

	for _, name in ipairs({ "tauntPlayer", "addSpaceFactionAlly", "removeSpaceFactionEnemy" }) do
		lu.assertEquals(type(agent[name]), "function", "fake agent method " .. name)
		lu.assertTrue(bindings[name], "fake agent exposes '" .. name .. "' but LuaShipAiAgent.cpp has no such binding")
	end
end
