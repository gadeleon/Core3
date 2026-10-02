-- Harness additions for space-quest-inspect-cargo: getShipAgentTemplateName and setCargoString on the fake
-- ship agent, world-spawned agents with a SpawnerName key, H.inspect (INSPECTEDSHIP) and H.spawners.
-- Spec: .claude/work/space-quest-inspect-cargo/01-spec.md (Harness additions).
-- These tests exercise the fakes only; they pass without any production change.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local AGENT_BINDINGS = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"
local SHIP_BINDINGS = H.ROOT .. "/src/server/zone/objects/ship/LuaShipObject.cpp"

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

local function spawn(name)
	return spawnShipAgent(name or "huttsmuggler", "space_endor", 1, 2, 3, H.newShip({}))
end

TestInspectFakeAgent = {}

function TestInspectFakeAgent:setUp() H.reset() end

function TestInspectFakeAgent:test_get_ship_agent_template_name_returns_the_spawn_name()
	local a = spawn("nym_cannon_ship_tier2")

	lu.assertEquals(ShipAiAgent(a):getShipAgentTemplateName(), "nym_cannon_ship_tier2")
end

function TestInspectFakeAgent:test_a_spawned_agent_starts_without_cargo()
	local a = spawn()

	lu.assertEquals(a.cargo, "", "cargo")
	lu.assertEquals(a.cargoStringCalls, {}, "cargoStringCalls")
end

function TestInspectFakeAgent:test_set_cargo_string_through_the_ship_object_wrapper_sets_and_records_the_cargo()
	local a = H.worldAgent({ shipName = "huttsmuggler", cargo = "sector_recon_data" })

	ShipObject(a):setCargoString("")
	ShipObject(a):setCargoString("x")

	lu.assertEquals(a.cargo, "x", "cargo after the last call")
	lu.assertEquals(a.cargoStringCalls, { "", "x" }, "every call is recorded in order")
end

function TestInspectFakeAgent:test_set_cargo_string_refuses_anything_but_exactly_one_string()
	local a = spawn()
	local ok1, e1 = pcall(function() ShipObject(a):setCargoString() end)
	local ok2, e2 = pcall(function() ShipObject(a):setCargoString("a", "b") end)
	local ok3, e3 = pcall(function() ShipObject(a):setCargoString(5) end)
	local ok4 = pcall(function() ShipObject(a):setCargoString(nil) end)

	lu.assertFalse(ok1, "no argument")
	lu.assertStrContains(tostring(e1), "exactly 1 argument")
	lu.assertFalse(ok2, "two arguments")
	lu.assertStrContains(tostring(e2), "exactly 1 argument")
	lu.assertFalse(ok3, "a number")
	lu.assertStrContains(tostring(e3), "takes a string")
	lu.assertFalse(ok4, "nil")
	lu.assertEquals(a.cargoStringCalls, {}, "nothing recorded for a refused call")
	lu.assertEquals(a.cargo, "", "cargo untouched")
end

function TestInspectFakeAgent:test_there_is_no_get_cargo_string_because_the_engine_has_no_such_binding()
	local a = spawn()

	lu.assertNil(a.getCargoString, "the fake must not offer getCargoString")
	lu.assertFalse(pcall(function() return ShipObject(a):getCargoString() end), "calling it through the wrapper fails loudly")
	lu.assertNil(bindingNames(SHIP_BINDINGS).getCargoString, "LuaShipObject.cpp has no getCargoString binding")
	lu.assertNil(bindingNames(AGENT_BINDINGS).getCargoString, "LuaShipAiAgent.cpp has no getCargoString binding")
end

function TestInspectFakeAgent:test_every_new_fake_method_is_a_real_binding()
	local a = spawn()

	lu.assertEquals(type(a.getShipAgentTemplateName), "function", "fake getShipAgentTemplateName")
	lu.assertTrue(bindingNames(AGENT_BINDINGS).getShipAgentTemplateName, "LuaShipAiAgent.cpp must register getShipAgentTemplateName")
	lu.assertEquals(type(a.setCargoString), "function", "fake setCargoString")
	lu.assertTrue(bindingNames(SHIP_BINDINGS).setCargoString, "LuaShipObject.cpp must register setCargoString")
end

TestInspectWorldAgent = {}

function TestInspectWorldAgent:setUp() H.reset() end

function TestInspectWorldAgent:test_a_world_agent_is_found_by_id_and_is_an_ai_agent_with_its_spawner_name()
	local a = H.worldAgent({ shipName = "huttsmuggler", cargo = "sector_recon_data", spawner = "hutt_smuggler_02" })

	lu.assertIs(getSceneObject(a.objectID), a, "getSceneObject finds it")
	lu.assertTrue(SceneObject(a):isShipAiAgent(), "isShipAiAgent")
	lu.assertEquals(ShipAiAgent(a):getShipAgentTemplateName(), "huttsmuggler", "template name")
	lu.assertEquals(a.cargo, "sector_recon_data", "cargo")
	lu.assertEquals(readStringData(a.objectID .. ":SpawnerName:"), "hutt_smuggler_02", "the key the space spawner writes")
end

function TestInspectWorldAgent:test_a_world_agent_without_a_spawner_has_no_spawner_name_key()
	local a = H.worldAgent({ shipName = "huttsmuggler", cargo = "x" })

	lu.assertEquals(readStringData(a.objectID .. ":SpawnerName:"), "", "readStringData of a missing key is the empty string")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "nothing written")
end

function TestInspectWorldAgent:test_world_agents_are_not_listed_as_spawned_ships()
	H.worldAgent({ shipName = "huttsmuggler" })

	lu.assertEquals(#H.spawnedShips(), 0, "spawnedShips only lists spawnShipAgent results")
	lu.assertEquals(#H.Engine.callsTo("spawnShipAgent"), 0, "no spawnShipAgent call recorded")
end

function TestInspectWorldAgent:test_a_destroyed_world_agent_leaves_the_world()
	local a = H.worldAgent({ shipName = "huttsmuggler", spawner = "s" })

	H.destroyShip(a, H.newShip({}))

	lu.assertNil(getSceneObject(a.objectID), "gone from getSceneObject")
end

TestInspectEvent = {}

function TestInspectEvent:setUp() H.reset() end

local seen

rawset(_G, "TestInspectProbe", {
	inspected = function(self, pPlayer, pShip, hash)
		seen[#seen + 1] = { player = pPlayer, ship = pShip, hash = hash }
		return 1
	end,
})

function TestInspectEvent:test_h_inspect_fires_inspectedship_on_the_player_with_the_ship_and_the_hash_and_the_observer_returning_1_goes_away()
	seen = {}

	local player = H.newPlayer({ zone = "space_endor", ship = {} })
	local a = H.worldAgent({ shipName = "huttsmuggler" })

	createObserver(INSPECTEDSHIP, "TestInspectProbe", "inspected", player)
	H.inspect(player, a, getHashCode("sector_recon_data"))
	H.inspect(player, a, getHashCode("sector_recon_data"))

	lu.assertEquals(#seen, 1, "one call, the observer returned 1 and was removed")
	lu.assertIs(seen[1].player, player, "player")
	lu.assertIs(seen[1].ship, a, "ship")
	lu.assertEquals(seen[1].hash, getHashCode("sector_recon_data"), "hash")
end

function TestInspectEvent:test_h_inspect_defaults_the_hash_to_0_like_h_dock()
	seen = {}

	local player = H.newPlayer({ zone = "space_endor", ship = {} })

	createObserver(INSPECTEDSHIP, "TestInspectProbe", "inspected", player)
	H.inspect(player, H.worldAgent({ shipName = "x" }))

	lu.assertEquals(seen[1].hash, 0, "default hash")
end

function TestInspectEvent:test_h_inspect_does_not_fire_other_observer_types()
	seen = {}

	local player = H.newPlayer({ zone = "space_endor", ship = {} })

	createObserver(SHIPDOCKED, "TestInspectProbe", "inspected", player)
	H.inspect(player, H.worldAgent({ shipName = "x" }), 5)

	lu.assertEquals(#seen, 0, "a SHIPDOCKED observer is not an INSPECTEDSHIP observer")
end

TestInspectSpawners = {}

function TestInspectSpawners:setUp() H.reset() end

function TestInspectSpawners:test_spawners_maps_spawn_names_to_the_core3_entries()
	local lok = H.spawners("space_lok")

	lu.assertEquals({ lok.nyms_boys.x, lok.nyms_boys.z, lok.nyms_boys.y }, { 3719, -2284, -1151 }, "nyms_boys x z y")
	lu.assertEquals(lok.nyms_boys.shipSpawns, { "nym_cannon_ship_tier2", "nym_enforcer_tier3" }, "nyms_boys ships")
	lu.assertEquals(H.spawners("space_endor").hutt_smuggler_02.x, 4730, "another zone")
	lu.assertIs(H.spawners("space_lok"), lok, "cached")
end

function TestInspectSpawners:test_squadrons_exposes_the_squadron_table()
	lu.assertEquals(H.squadrons().squad_viopa_rebel_1[2][1], "viopa_mission_1_shuttle", "first ship of squad_viopa_rebel_1")
end

function TestInspectSpawners:test_an_unknown_zone_fails_with_a_clear_message()
	local ok, err = pcall(function() return H.spawners("space_nowhere") end)

	lu.assertFalse(ok, "unknown zone")
	lu.assertStrContains(tostring(err), "space_nowhere_spawner.lua")
end

TestInspectHarnessEngine = {}

function TestInspectHarnessEngine:setUp() H.reset() end

rawset(_G, "TestInspectCancelProbe", {
	tick = function(self, pObject, args) seen[#seen + 1] = args end,
})

function TestInspectHarnessEngine:test_cancel_event_drops_only_the_matching_pending_events()
	seen = {}

	local a, b = H.newPlayer({}), H.newPlayer({})

	createEvent(100, "TestInspectCancelProbe", "tick", a, "a1")
	createEvent(100, "TestInspectCancelProbe", "tick", b, "b1")
	createEvent(200, "TestInspectCancelProbe", "tick", a, "a2")

	cancelEvent("TestInspectCancelProbe", "tick", a)
	H.advance(1000)

	lu.assertEquals(seen, { "b1" }, "only the other object's event ran")
	lu.assertEquals(#H.Engine.callsTo("cancelEvent"), 1, "the call is recorded")
end

function TestInspectHarnessEngine:test_cancel_event_takes_exactly_three_arguments_and_a_nil_object_cancels_nothing()
	seen = {}

	local a = H.newPlayer({})

	createEvent(100, "TestInspectCancelProbe", "tick", a, "a1")

	lu.assertFalse(pcall(function() cancelEvent("TestInspectCancelProbe", "tick") end), "two arguments")
	cancelEvent("TestInspectCancelProbe", "tick", nil)
	H.advance(1000)

	lu.assertEquals(seen, { "a1" }, "nothing cancelled")
end

function TestInspectHarnessEngine:test_the_ghost_fakes_set_pilot_tier_and_reset_pilot_tier_which_are_real_bindings()
	local player = H.newPlayer({ pilotTier = 3 })

	PlayerObject(player.ghost):setPilotTier(2)
	lu.assertEquals(player.ghost.pilotTier, 2, "setPilotTier")
	PlayerObject(player.ghost):resetPilotTier()
	lu.assertEquals(player.ghost.pilotTier, 0, "resetPilotTier")

	local names = bindingNames(H.ROOT .. "/src/server/zone/objects/player/LuaPlayerObject.cpp")

	lu.assertTrue(names.setPilotTier and names.resetPilotTier, "LuaPlayerObject.cpp registers both")
end
