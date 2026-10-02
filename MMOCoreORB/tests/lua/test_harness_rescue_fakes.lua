-- Harness additions for space-quest-rescue-docking: the fake ship agent's escort bindings
-- (setFixedPatrol, setEscort, setEscortSpeed, repairShipAgent, assignFixedPatrolPointsTable) with an
-- ordered call log, isShipAiAgent, a movable agent position, an AI agent entering an area, and the
-- area-spawn failure switch. Spec: .claude/work/space-quest-rescue-docking/01-spec.md (Harness additions).
-- These tests exercise the fakes only; they pass without any production change.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local AGENT_BINDINGS = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"
local SCENE_BINDINGS = H.ROOT .. "/src/server/zone/objects/scene/LuaSceneObject.cpp"

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

local function spawn()
	return spawnShipAgent("reb_diplomat_tier4", "space_dathomir", 1, 2, 3, H.newShip({}))
end

TestRescueFakeAgent = {}

function TestRescueFakeAgent:setUp() H.reset() end

function TestRescueFakeAgent:test_escort_calls_are_recorded_in_order_together_with_set_dockable()
	local a = spawn()

	ShipAiAgent(a):setDockable(true)
	ShipAiAgent(a):repairShipAgent(1)
	ShipAiAgent(a):setFixedPatrol()
	ShipAiAgent(a):setEscort()
	ShipAiAgent(a):setEscortSpeed(50)
	ShipAiAgent(a):assignFixedPatrolPointsTable({ "p1", "p2" })
	ShipAiAgent(a):setDockable(false)

	local names = {}

	for i, c in ipairs(a.callLog) do
		names[i] = c.name
	end

	lu.assertEquals(names, { "setDockable", "repairShipAgent", "setFixedPatrol", "setEscort", "setEscortSpeed", "assignFixedPatrolPointsTable", "setDockable" }, "callLog order")
	lu.assertEquals(a.repairs, { 1 }, "repairs")
	lu.assertEquals(a.escortSpeeds, { 50 }, "escortSpeeds")
	lu.assertEquals(a.fixedPatrolCalls, 1, "fixedPatrolCalls")
	lu.assertEquals(a.escortCalls, 1, "escortCalls")
	lu.assertEquals(a.patrolPointTables, { { "p1", "p2" } }, "patrolPointTables")
	lu.assertEquals(a.dockableCalls, { true, false }, "dockableCalls still recorded")
end

function TestRescueFakeAgent:test_logs_are_per_agent()
	local a, b = spawn(), spawn()

	ShipAiAgent(a):setEscort()

	lu.assertEquals(#a.callLog, 1, "a")
	lu.assertEquals(#b.callLog, 0, "b")
end

function TestRescueFakeAgent:test_assign_fixed_patrol_points_table_refuses_anything_but_exactly_one_argument()
	local a = spawn()
	local ok1, e1 = pcall(function() ShipAiAgent(a):assignFixedPatrolPointsTable({ "p1" }, { "p2" }) end)
	local ok2, e2 = pcall(function() ShipAiAgent(a):assignFixedPatrolPointsTable() end)
	local ok3, e3 = pcall(function() ShipAiAgent(a):assignFixedPatrolPointsTable("p1", 250) end)

	lu.assertFalse(ok1, "two arguments (the old rescue code passed a table and a second one)")
	lu.assertStrContains(tostring(e1), "exactly 1 argument")
	lu.assertFalse(ok2, "no argument")
	lu.assertStrContains(tostring(e2), "exactly 1 argument")
	lu.assertFalse(ok3, "a name and a number")
	lu.assertStrContains(tostring(e3), "exactly 1 argument")
	lu.assertEquals(a.patrolPointTables, {}, "nothing recorded for a refused call")
end

function TestRescueFakeAgent:test_assign_fixed_patrol_points_table_wants_a_table_of_names_not_point_tables()
	local a = spawn()
	local ok1 = pcall(function() ShipAiAgent(a):assignFixedPatrolPointsTable("p1") end)
	local ok2 = pcall(function() ShipAiAgent(a):assignFixedPatrolPointsTable({ { patrolPointName = "p1", x = 1, z = 2, y = 3 } }) end)

	lu.assertFalse(ok1, "a string is not a table")
	lu.assertFalse(ok2, "a table of point tables is not a table of names")
end

function TestRescueFakeAgent:test_assign_fixed_patrol_points_table_records_a_copy()
	local a = spawn()
	local names = { "p1", "p2" }

	ShipAiAgent(a):assignFixedPatrolPointsTable(names)
	names[3] = "p3"

	lu.assertEquals(a.patrolPointTables[1], { "p1", "p2" }, "the copy taken at call time")
end

function TestRescueFakeAgent:test_escort_speed_and_repair_refuse_a_wrong_argument_count()
	local a = spawn()

	lu.assertFalse(pcall(function() ShipAiAgent(a):setEscortSpeed() end), "setEscortSpeed()")
	lu.assertFalse(pcall(function() ShipAiAgent(a):setEscortSpeed(50, 1) end), "setEscortSpeed(50, 1)")
	lu.assertFalse(pcall(function() ShipAiAgent(a):repairShipAgent() end), "repairShipAgent()")
	lu.assertFalse(pcall(function() ShipAiAgent(a):repairShipAgent(1, 2) end), "repairShipAgent(1, 2)")
	lu.assertEquals(a.callLog, {}, "nothing recorded")
end

function TestRescueFakeAgent:test_is_ship_ai_agent_is_true_only_for_agents()
	local agent = spawn()
	local ship = H.newShip({})
	local player = H.newPlayer({ ship = {} })
	local area = spawnSpaceActiveArea("space_dathomir", "object/space_active_area.iff", 1, 2, 3, 300)

	lu.assertTrue(SceneObject(agent):isShipAiAgent(), "agent")
	lu.assertFalse(SceneObject(ship):isShipAiAgent(), "player ship")
	lu.assertFalse(SceneObject(player):isShipAiAgent(), "player")
	lu.assertFalse(SceneObject(area):isShipAiAgent(), "area")
end

function TestRescueFakeAgent:test_agent_position_is_movable_and_backs_the_scene_object_getters()
	local agent = spawn()

	agent:setPosition(10, 20, 30)

	lu.assertEquals({ SceneObject(agent):getPositionX(), SceneObject(agent):getPositionZ(), SceneObject(agent):getPositionY() }, { 10, 20, 30 }, "x z y")
end

TestRescueHarnessEvents = {}

function TestRescueHarnessEvents:setUp() H.reset() end

local seen

rawset(_G, "TestRescueAreaProbe", {
	entered = function(self, pArea, pShip)
		seen[#seen + 1] = { area = pArea, ship = pShip }
		return 0
	end,
})

function TestRescueHarnessEvents:test_enter_area_passes_an_ai_agent_as_the_entering_ship()
	seen = {}

	local area = spawnSpaceActiveArea("space_dathomir", "object/space_active_area.iff", 1, 2, 3, 300)
	local agent = spawn()

	createObserver(ENTEREDAREA, "TestRescueAreaProbe", "entered", area)
	H.enterArea(area, agent)

	lu.assertEquals(#seen, 1, "handler calls")
	lu.assertEquals(seen[1].area, area, "area")
	lu.assertEquals(seen[1].ship, agent, "entering agent")
	lu.assertTrue(SceneObject(seen[1].ship):isShipAiAgent(), "the handler can tell it is an AI agent")
end

function TestRescueHarnessEvents:test_area_spawn_failure_switch_makes_spawn_space_active_area_return_nil()
	H.Engine.config.areaFails = true

	lu.assertNil(spawnSpaceActiveArea("space_dathomir", "object/space_active_area.iff", 1, 2, 3, 300), "area")
	lu.assertEquals(#H.spawnedAreas(), 0, "no area registered")
	lu.assertEquals(#H.Engine.callsTo("spawnSpaceActiveArea"), 1, "the call is still recorded")

	H.reset()
	lu.assertNotNil(spawnSpaceActiveArea("space_dathomir", "object/space_active_area.iff", 1, 2, 3, 300), "reset clears the switch")
end

TestRescueBindingParity = {}

function TestRescueBindingParity:setUp() H.reset() end

function TestRescueBindingParity:test_every_new_fake_agent_method_is_a_real_binding()
	local bindings = bindingNames(AGENT_BINDINGS)
	local agent = spawn()

	for _, name in ipairs({ "setFixedPatrol", "setEscort", "setEscortSpeed", "repairShipAgent", "assignFixedPatrolPointsTable" }) do
		lu.assertEquals(type(agent[name]), "function", "fake agent method " .. name)
		lu.assertTrue(bindings[name], "fake agent exposes '" .. name .. "' but LuaShipAiAgent.cpp has no such binding")
	end
end

function TestRescueBindingParity:test_is_ship_ai_agent_is_a_real_scene_object_binding()
	lu.assertTrue(bindingNames(SCENE_BINDINGS).isShipAiAgent, "LuaSceneObject.cpp must register isShipAiAgent")
end
