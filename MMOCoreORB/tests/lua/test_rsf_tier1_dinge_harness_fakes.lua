-- Harness additions for rsf-tier1-dinge-data: the ShipAiAgent setters of the escort attack wave (setWaveAttack,
-- removeSpaceFactionAlly). These tests exercise the fakes only; they pass without any production change.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local function bindingNames(path)
	local f = io.open(path, "r")

	lu.assertNotNil(f, "cannot read " .. path)

	local src = f:read("a")

	f:close()

	local names = {}

	for name in src:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

TestRsfTier1DingeAgentFakes = {}

function TestRsfTier1DingeAgentFakes:setUp() H.reset() end

function TestRsfTier1DingeAgentFakes:test_the_new_agent_setters_are_bound_by_luashipaiagent()
	local names = bindingNames(H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp")

	for _, name in ipairs({ "setWaveAttack", "removeSpaceFactionAlly" }) do
		lu.assertTrue(names[name] == true, name .. " is not in the LuaShipAiAgent method table")
	end
end

function TestRsfTier1DingeAgentFakes:test_a_spawned_agent_records_the_wave_attack_flag_and_the_removed_ally()
	local ship = H.newShip({})
	local agent = spawnShipAgent("blacksun_marauder_tier2", "space_naboo", 1, 2, 3, ship)

	lu.assertNil(agent.waveAttack, "waveAttack before the call")

	ShipAiAgent(agent):setWaveAttack()
	ShipAiAgent(agent):removeSpaceFactionAlly(1234)

	lu.assertTrue(agent.waveAttack, "waveAttack")
	lu.assertEquals(agent.removedFactionAllies, { 1234 }, "removedFactionAllies")
end

function TestRsfTier1DingeAgentFakes:test_get_distance_to_3d_is_bound_by_luasceneobject_and_measures_between_positions()
	local names = bindingNames(H.ROOT .. "/src/server/zone/objects/scene/LuaSceneObject.cpp")

	lu.assertTrue(names.getDistanceTo3d == true, "getDistanceTo3d is not in the LuaSceneObject method table")

	local player = H.newPlayer({ zone = "space_naboo", ship = { x = 0, z = 0, y = 0 } })
	local agent = spawnShipAgent("freighterheavy_tier2", "space_naboo", 3, 4, 12, player.rootParent)

	lu.assertEquals(SceneObject(agent):getDistanceTo3d(player), 13, "agent (3, 4, 12) to the pilot of a ship at the origin")
	lu.assertEquals(SceneObject(agent):getDistanceTo3d(player.rootParent), 13, "agent to the ship itself")
end
