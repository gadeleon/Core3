-- Harness changes for the space battle slice (space-quest-stub-space-battle): the stricter
-- FakeAgent:engageShipTarget (arguments checked like LuaShipAiAgent.cpp:388-418, plus engageLog),
-- H.shipTemplate, and a parity check of the binding names the battle code calls.

local lu = require("luaunit")
local H = require("harness")

H.boot()

local BINDING_FILE = H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp"

local function bindingNames()
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

TestEngageShipTargetFake = {}

function TestEngageShipTargetFake:setUp() H.reset() end

local function agents()
	local ship = H.newShip({})

	return spawnShipAgent("reb_xwing_tier3", "space_dathomir", 1, 2, 3), spawnShipAgent("imp_tie_fighter_tier3", "space_dathomir", 1, 2, 3), ship
end

function TestEngageShipTargetFake:test_one_ship_argument_is_recorded_in_engaged_and_engage_log_with_the_time()
	local a, b, ship = agents()

	H.advance(1500)
	ShipAiAgent(a):engageShipTarget(b)
	H.advance(500)
	ShipAiAgent(a):engageShipTarget(ship)

	lu.assertEquals(a.engaged, { b, ship }, "engaged keeps the ships in call order")
	lu.assertEquals(#a.engageLog, 2, "engageLog has one entry per call")
	lu.assertEquals(a.engageLog[1].t, 1500, "first call time")
	lu.assertTrue(a.engageLog[1].target == b, "first call target")
	lu.assertEquals(a.engageLog[2].t, 2000, "second call time")
	lu.assertTrue(a.engageLog[2].target == ship, "second call target")
end

function TestEngageShipTargetFake:test_no_argument_or_two_arguments_raise_the_binding_error_and_record_nothing()
	local a, b, ship = agents()

	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget() end)
	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget(b, ship) end)
	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget(nil) end)

	lu.assertEquals(a.engaged, {}, "nothing recorded in engaged")
	lu.assertEquals(a.engageLog, {}, "nothing recorded in engageLog")
end

function TestEngageShipTargetFake:test_an_argument_that_is_not_a_ship_object_raises_the_same_error()
	local a = agents()
	local player = H.newPlayer({ zone = "space_dathomir" })

	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget(player) end)
	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget("target") end)
	lu.assertErrorMsgContains("engageShipTarget: exactly 1 argument (a ship object)", function() ShipAiAgent(a):engageShipTarget({}) end)

	lu.assertEquals(a.engageLog, {}, "nothing recorded")
end

function TestEngageShipTargetFake:test_every_binding_the_battle_code_calls_exists_in_lua_ship_ai_agent_cpp()
	local names = bindingNames()

	for _, method in ipairs({ "setMissionOwner", "getMissionOwnerID", "addSpaceFactionAlly", "removeSpaceFactionEnemy", "addSpaceFactionEnemy",
		"createSquadron", "assignToSquadron", "engageShipTarget" }) do
		lu.assertTrue(names[method] == true, "LuaShipAiAgent.cpp registers " .. method)
	end
end

TestShipTemplateHelper = {}

function TestShipTemplateHelper:setUp() H.reset() end

function TestShipTemplateHelper:test_a_template_is_returned_by_name_with_its_factions()
	local t = H.shipTemplate("reb_xwing_tier3")

	lu.assertNotNil(t, "reb_xwing_tier3 loads")
	lu.assertEquals(t.spaceFaction, "rebel", "spaceFaction")
	lu.assertEquals(t.enemyFactions, { "imperial", "blacksun", "borvo", "hutt", "pirate", "aynat" }, "enemyFactions")
end

function TestShipTemplateHelper:test_a_missing_template_is_nil_and_loading_leaks_no_globals()
	lu.assertNil(H.shipTemplate("no_such_ship_template"), "unknown name")
	lu.assertNil(rawget(_G, "reb_xwing_tier3"), "the template table is not left in _G")
	lu.assertNil(rawget(_G, "ShipAgent"), "no ShipAgent stub is left in _G")
end

function TestShipTemplateHelper:test_unarmed_ships_have_no_enemy_factions()
	local freighter = H.shipTemplate("nym_freighterheavy_tier4")

	lu.assertNotNil(freighter, "nym_freighterheavy_tier4 loads")
	lu.assertNil(freighter.enemyFactions, "the unarmed Nym freighter has no enemyFactions (I-3 skips the reverse check for it)")
end
