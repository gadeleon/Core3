-- Harness fakes for LuaShipAiAgent::addExclusiveAggro / removeExclusiveAggro / hasExclusiveAggro and the parity check against the
-- real binding table (space-quest-exclusive-aggro, AC-5).

local lu = require("luaunit")
local H = require("harness")

H.boot()

local BINDING_FILE = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"
local NAMES = { "addExclusiveAggro", "removeExclusiveAggro", "hasExclusiveAggro" }

-- Names registered in a Lua binding file's Methods table: lines like `{ "name", &Class::name },`.
local function bindingNames(source)
	local names = {}

	for name in source:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

TestExclusiveAggroFakes = {}

function TestExclusiveAggroFakes:setUp() H.reset() end

local function spawn()
	return spawnShipAgent("hutt_pirate_s02_tier2", "space_yavin4", 1, 2, 3, H.newShip({}))
end

-- AC-5
function TestExclusiveAggroFakes:test_the_lua_binding_table_registers_the_three_methods()
	local f = io.open(BINDING_FILE, "r")

	lu.assertNotNil(f, "cannot read " .. BINDING_FILE)

	local registered = bindingNames(f:read("a"))

	f:close()

	for _, name in ipairs(NAMES) do
		lu.assertTrue(registered[name] == true, "LuaShipAiAgent.cpp Methods table registers " .. name)
	end
end

-- AC-5
function TestExclusiveAggroFakes:test_the_fake_agent_implements_the_three_methods()
	local agent = spawn()

	for _, name in ipairs(NAMES) do
		lu.assertEquals(type(agent[name]), "function", "FakeAgent:" .. name)
	end
end

-- AC-5
function TestExclusiveAggroFakes:test_add_makes_has_true_for_that_player_only()
	local agent = spawn()
	local pilot, other = H.newPlayer({ name = "Pilot" }), H.newPlayer({ name = "Other" })

	lu.assertFalse(ShipAiAgent(agent):hasExclusiveAggro(pilot), "before add")

	ShipAiAgent(agent):addExclusiveAggro(pilot)

	lu.assertTrue(ShipAiAgent(agent):hasExclusiveAggro(pilot), "hasExclusiveAggro(pilot) after add")
	lu.assertFalse(ShipAiAgent(agent):hasExclusiveAggro(other), "hasExclusiveAggro(other player) after add for the pilot")
end

-- AC-5
function TestExclusiveAggroFakes:test_remove_clears_the_flag_and_the_set_is_per_agent()
	local first, second = spawn(), spawn()
	local pilot = H.newPlayer({ name = "Pilot" })

	ShipAiAgent(first):addExclusiveAggro(pilot)
	ShipAiAgent(second):addExclusiveAggro(pilot)
	ShipAiAgent(first):removeExclusiveAggro(pilot)

	lu.assertFalse(ShipAiAgent(first):hasExclusiveAggro(pilot), "first agent after remove")
	lu.assertTrue(ShipAiAgent(second):hasExclusiveAggro(pilot), "second agent is untouched")
end

-- AC-5
function TestExclusiveAggroFakes:test_calls_with_no_argument_or_two_arguments_raise()
	local agent = spawn()
	local pilot, other = H.newPlayer({ name = "Pilot" }), H.newPlayer({ name = "Other" })

	for _, name in ipairs(NAMES) do
		lu.assertErrorMsgContains("exactly 1 argument", agent[name], agent)
		lu.assertErrorMsgContains("exactly 1 argument", agent[name], agent, pilot, other)
	end
end

-- AC-5
function TestExclusiveAggroFakes:test_calls_with_a_ship_or_a_nil_raise()
	local agent = spawn()
	local ship = H.newShip({})

	for _, name in ipairs(NAMES) do
		lu.assertErrorMsgContains("a player creature", agent[name], agent, ship)
		lu.assertErrorMsgContains("a player creature", agent[name], agent, spawn())
		lu.assertErrorMsgContains("a player creature", agent[name], agent, nil)
	end
end

-- AC-5 (I-1 helper): add, remove and setMissionOwner are logged in call order in agent.aggroLog
function TestExclusiveAggroFakes:test_the_aggro_log_keeps_the_call_order_with_set_mission_owner()
	local agent = spawn()
	local pilot = H.newPlayer({ name = "Pilot" })

	ShipAiAgent(agent):setMissionOwner(pilot)
	ShipAiAgent(agent):addExclusiveAggro(pilot)
	ShipAiAgent(agent):removeExclusiveAggro(pilot)

	local names = {}

	for i, e in ipairs(agent.aggroLog) do
		names[i] = e.name
		lu.assertEquals(e.args[1], pilot, "aggroLog entry " .. i .. " argument")
	end

	lu.assertEquals(names, { "setMissionOwner", "addExclusiveAggro", "removeExclusiveAggro" }, "aggroLog order")
end
