-- Harness fakes for LuaShipAiAgent::setDockable / isDockable and the parity check against the
-- real binding table (space-docking-permission, AC-7).

local lu = require("luaunit")
local H = require("harness")

H.boot()

local BINDING_FILE = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"

-- Names registered in a Lua binding file's Methods table: lines like `{ "name", &Class::name },`.
local function bindingNames(source)
	local names = {}

	for name in source:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

local function readBindings()
	local f = io.open(BINDING_FILE, "r")
	lu.assertNotNil(f, "cannot read " .. BINDING_FILE)
	local src = f:read("a")
	f:close()
	return bindingNames(src)
end

TestShipAgentDockableFakes = {}

function TestShipAgentDockableFakes:setUp() H.reset() end

local function spawn()
	return spawnShipAgent("transport", "space_corellia", 1, 2, 3, H.newShip({}))
end

-- AC-7
function TestShipAgentDockableFakes:test_fake_agent_is_not_dockable_by_default()
	local agent = spawn()

	lu.assertFalse(ShipAiAgent(agent):isDockable(), "default isDockable()")
end

-- AC-7
function TestShipAgentDockableFakes:test_set_dockable_is_remembered_and_recorded()
	local agent = spawn()

	ShipAiAgent(agent):setDockable(true)
	lu.assertTrue(ShipAiAgent(agent):isDockable(), "after setDockable(true)")

	ShipAiAgent(agent):setDockable(false)
	lu.assertFalse(ShipAiAgent(agent):isDockable(), "after setDockable(false)")

	lu.assertEquals(agent.dockableCalls, { true, false }, "recorded setDockable values")
end

-- AC-7
function TestShipAgentDockableFakes:test_dockable_state_is_per_agent()
	local first, second = spawn(), spawn()

	ShipAiAgent(first):setDockable(true)

	lu.assertTrue(ShipAiAgent(first):isDockable(), "first")
	lu.assertFalse(ShipAiAgent(second):isDockable(), "second")
end

TestShipAgentBindingParity = {}

-- AC-7
function TestShipAgentBindingParity:test_binding_parser_reads_a_methods_table()
	local names = bindingNames('{ "_setObject", &LuaShipAiAgent::_setObject },\n\t{ "foo", &X::foo },')

	lu.assertTrue(names._setObject)
	lu.assertTrue(names.foo)
	lu.assertNil(names.bar)
end

-- AC-7
function TestShipAgentBindingParity:test_set_dockable_is_registered_in_LuaShipAiAgent_cpp()
	lu.assertTrue(readBindings().setDockable,
			"LuaShipAiAgent.cpp Methods table must contain { \"setDockable\", &LuaShipAiAgent::setDockable }")
end

-- AC-7
function TestShipAgentBindingParity:test_is_dockable_is_registered_in_LuaShipAiAgent_cpp()
	lu.assertTrue(readBindings().isDockable,
			"LuaShipAiAgent.cpp Methods table must contain { \"isDockable\", &LuaShipAiAgent::isDockable }")
end

-- AC-7
function TestShipAgentBindingParity:test_every_dockable_method_the_fake_agent_exposes_is_a_real_binding()
	local bindings = readBindings()
	local agent = spawn()

	for _, name in ipairs({ "setDockable", "isDockable" }) do
		lu.assertEquals(type(agent[name]), "function", "fake agent method " .. name)
		lu.assertTrue(bindings[name], "fake agent exposes '" .. name .. "' but LuaShipAiAgent.cpp has no such binding")
	end
end
