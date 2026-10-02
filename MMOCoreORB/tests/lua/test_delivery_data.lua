-- Delivery quest data conformance (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (AC-1, I-2, I-3, Content contract: class
-- constants, Data mapping). The oracle is the SWG-Source .tab copies in fixtures/spacequest/delivery*/
-- plus the patrol point files, never the Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")

D.load()

local function quest(questType, name)
	return H.expectGlobal(D.global(questType, name), "delivery quest table for " .. name)
end

local function fileExists(path) return H.fileExists(path) end

local function label(o) return o.questType .. "/" .. o.name end

local function sameLists(actual, expected)
	local out = {}

	for i, list in ipairs(actual) do
		out[i] = table.concat(list, ",")
	end

	local want = {}

	for i, list in ipairs(expected) do
		want[i] = table.concat(list, ",")
	end

	return out, want
end

TestDeliveryDataConformance = {}

function TestDeliveryDataConformance:setUp() H.reset() end

-- AC-1
function TestDeliveryDataConformance:test_zone_and_ships_equal_the_tab()
	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local t = quest(q[1], q[2])

		lu.assertEquals(t.questZone, o.zone, label(o) .. ": questZone")
		lu.assertEquals(t.deliveryShip, o.deliveryShip, label(o) .. ": deliveryShip")
		lu.assertEquals(t.pickupShip, o.pickupShip or "", label(o) .. ": pickupShip")
	end
end

-- AC-1
function TestDeliveryDataConformance:test_delivery_points_resolve_to_the_patrol_point_coordinates()
	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local p = quest(q[1], q[2]).deliveryPoint

		lu.assertEquals(type(p), "table", label(o) .. ": deliveryPoint must be a table, not a 'zone:name' string")
		lu.assertEquals(p.patrolPointName, o.delivery.name, label(o) .. ": deliveryPoint.patrolPointName")
		lu.assertEquals(p.x, o.delivery.x, label(o) .. ": deliveryPoint.x")
		lu.assertEquals(p.z, o.delivery.z, label(o) .. ": deliveryPoint.z")
		lu.assertEquals(p.y, o.delivery.y, label(o) .. ": deliveryPoint.y")
		lu.assertEquals(o.delivery.zone, o.zone, label(o) .. ": the .tab's delivery zone equals questZone")
	end
end

-- AC-1
function TestDeliveryDataConformance:test_pickup_points_resolve_to_the_patrol_point_coordinates_for_the_five_pickup_quests()
	local checked = 0

	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])

		if o.pickup ~= nil then
			local p = quest(q[1], q[2]).pickupPoint

			checked = checked + 1
			lu.assertEquals(type(p), "table", label(o) .. ": pickupPoint must be a table, not a 'zone:name' string")
			lu.assertEquals(p.patrolPointName, o.pickup.name, label(o) .. ": pickupPoint.patrolPointName")
			lu.assertEquals(p.x, o.pickup.x, label(o) .. ": pickupPoint.x")
			lu.assertEquals(p.z, o.pickup.z, label(o) .. ": pickupPoint.z")
			lu.assertEquals(p.y, o.pickup.y, label(o) .. ": pickupPoint.y")
			lu.assertEquals(o.pickup.zone, o.zone, label(o) .. ": the .tab's pickup zone equals questZone")
		end
	end

	lu.assertEquals(checked, 5, "five of the six quests have a pickup point")
end

-- AC-1
function TestDeliveryDataConformance:test_attack_lists_are_the_tab_columns_not_rows()
	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local t = quest(q[1], q[2])

		lu.assertEquals(type(t.attackShipLists), "table", label(o) .. ": attackShipLists must be a table")
		lu.assertEquals(#t.attackShipLists, o.listCount, label(o) .. ": number of attack lists (numAttackShipLists)")

		local actual, want = sameLists(t.attackShipLists, o.lists)

		lu.assertEquals(actual, want, label(o) .. ": attackShipLists (column i of the .tab is list i)")
	end
end

-- AC-1
function TestDeliveryDataConformance:test_attack_period_and_list_type_equal_the_tab()
	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local t = quest(q[1], q[2])

		lu.assertEquals(t.attackPeriod, o.period, label(o) .. ": attackPeriod")
		lu.assertEquals(t.attackListType, o.listType, label(o) .. ": attackListType (sequential=0, random=1)")
	end
end

-- AC-1, the oracle itself (guards against a fixture that parsed into something unexpected)
function TestDeliveryDataConformance:test_the_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		corellia_privateer_tier3_2_b = { 3, 50, 0 },
		corellia_privateer_tier3_3 = { 0, 60, 0 },
		naboo_privateer_tier3_3b = { 5, 48, 0 },
		corellia_rebel_tier3_2_a = { 3, 70, 1 },
		corellia_rebel_tier3_3 = { 2, 80, 0 },
		corellia_rebel_tier4_2_a = { 3, 45, 1 },
	}

	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local w = want[q[2]]

		lu.assertEquals({ o.listCount, o.period, o.listType }, w, label(o) .. ": {lists, period, listType} in the fixture")
	end
end

TestDeliveryDataInvariants = {}

function TestDeliveryDataInvariants:setUp() H.reset() end

local function deliveryGlobals()
	local out = {}

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "delivery" or q.questType == "delivery_no_pickup" then
			out[#out + 1] = n
		end
	end

	return out
end

-- I-2
function TestDeliveryDataInvariants:test_there_are_exactly_the_six_delivery_quests()
	local expected = {}

	for _, q in ipairs(D.QUESTS) do
		expected[#expected + 1] = D.global(q[1], q[2])
	end

	table.sort(expected)

	lu.assertEquals(deliveryGlobals(), expected, "delivery quest globals")
end

-- I-2
function TestDeliveryDataInvariants:test_no_delivery_quest_keeps_the_invented_attack_delay_or_attack_ships_keys()
	for _, n in ipairs(deliveryGlobals()) do
		local q = rawget(_G, n)

		lu.assertNil(rawget(q, "attackDelay"), n .. ": raw attackDelay must be gone")
		lu.assertNil(rawget(q, "attackShips"), n .. ": raw attackShips must be gone")
	end
end

-- I-2
function TestDeliveryDataInvariants:test_points_are_tables_everywhere_and_the_no_pickup_quest_has_no_pickup_keys()
	for _, n in ipairs(deliveryGlobals()) do
		local q = rawget(_G, n)

		lu.assertEquals(type(q.pickupPoint), "table", n .. ": pickupPoint")
		lu.assertEquals(type(q.deliveryPoint), "table", n .. ": deliveryPoint")
	end

	local np = quest("delivery_no_pickup", "corellia_rebel_tier4_2_a")

	lu.assertNil(rawget(np, "pickupPoint"), "delivery_no_pickup_corellia_rebel_tier4_2_a: no raw pickupPoint")
	lu.assertNil(rawget(np, "pickupShip"), "delivery_no_pickup_corellia_rebel_tier4_2_a: no raw pickupShip")
	lu.assertEquals(np.pickupPoint, {}, "no-pickup pickupPoint stays the class default {}")
	lu.assertEquals(np.pickupShip, "", "no-pickup pickupShip stays the class default \"\"")
end

-- I-3
function TestDeliveryDataInvariants:test_every_transport_and_attack_ship_has_a_ship_template()
	for _, q in ipairs(D.QUESTS) do
		local o = D.oracle(q[1], q[2])
		local t = quest(q[1], q[2])
		local names = { t.deliveryShip }

		lu.assertEquals(type(t.attackShipLists), "table", label(o) .. ": attackShipLists must be a table")

		if o.hasPickup then
			names[#names + 1] = t.pickupShip
		end

		for _, list in ipairs(t.attackShipLists) do
			for _, ship in ipairs(list) do
				names[#names + 1] = ship
			end
		end

		for _, ship in ipairs(names) do
			lu.assertNotEquals(ship, "", label(o) .. ": empty ship name")
			lu.assertTrue(fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. ship .. ".lua"), label(o) .. ": no ship template ship_mobile/ships/" .. ship .. ".lua")
		end
	end
end

-- Content contract: every delivery table keeps its registration
function TestDeliveryDataInvariants:test_every_delivery_quest_is_still_registered_as_a_started_screenplay()
	for _, n in ipairs(deliveryGlobals()) do
		local r = H.registered(n)

		lu.assertNotNil(r, n .. ": registerScreenPlay")
		lu.assertTrue(r.start, n .. ": registered with start = true")
	end
end

-- Not touched by this slice: the fields the spec says stay exactly as they are
function TestDeliveryDataInvariants:test_class_names_quest_types_and_rewards_are_unchanged()
	local expected = {
		delivery_corellia_privateer_tier3_2_b = { zone = "space_dathomir", credit = 0, side = "destroy_surpriseattack_corellia_privateer_tier3_2_c", delay = 5, parent = "survival_corellia_privateer_tier3_2_a" },
		delivery_corellia_privateer_tier3_3 = { zone = "space_dantooine", credit = 100, side = "escort_corellia_privateer_tier3_3_pre_a", delay = 2, parent = "" },
		delivery_naboo_privateer_tier3_3b = { zone = "space_lok", credit = 0, side = "survival_naboo_privateer_tier3_3c", delay = 4, parent = "inspect_naboo_privateer_tier3_3a" },
		delivery_corellia_rebel_tier3_2_a = { zone = "space_lok", credit = 0, side = "survival_corellia_rebel_tier3_2_b", delay = 3, parent = "inspect_corellia_rebel_tier3_2" },
		delivery_corellia_rebel_tier3_3 = { zone = "space_endor", credit = 0, side = "assassinate_corellia_rebel_tier3_3_a", delay = 2, parent = "" },
		delivery_no_pickup_corellia_rebel_tier4_2_a = { zone = "space_dathomir", credit = 0, side = "", delay = 2, parent = "assassinate_corellia_rebel_tier4_2" },
	}

	for n, e in pairs(expected) do
		local q = rawget(_G, n)

		lu.assertNotNil(q, n .. ": exists")
		lu.assertEquals(q.className, n, n .. ": className")
		lu.assertEquals(q.questZone, e.zone, n .. ": questZone")
		lu.assertEquals(q.creditReward, e.credit, n .. ": creditReward")
		lu.assertEquals(q.sideQuestDelay, e.delay, n .. ": sideQuestDelay")
		lu.assertEquals(q.parentQuest, e.parent, n .. ": parentQuest")

		if e.side ~= "" then
			lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, e.side, n .. ": side quest")
		end
	end
end

TestDeliveryClassContract = {}

function TestDeliveryClassContract:setUp() H.reset() end

-- Content contract: constants readable on the class
function TestDeliveryClassContract:test_the_class_constants_are_the_ported_values()
	local c = H.expectGlobal("SpaceDeliveryScreenplay")

	lu.assertEquals(c.className, "SpaceDeliveryScreenplay", "className")
	lu.assertEquals(c.ATTACK_LIST_TYPES, { SEQUENTIAL = 0, RANDOM = 1 }, "ATTACK_LIST_TYPES")
	lu.assertEquals(c.hasPickup, true, "hasPickup")
	lu.assertEquals(c.arrivalRadius, 150, "arrivalRadius")
	lu.assertEquals(c.transportSpawnMinDistance, 100, "transportSpawnMinDistance")
	lu.assertEquals(c.transportSpawnMaxDistance, 200, "transportSpawnMaxDistance")
	lu.assertEquals(c.transportWarpBaseDelay, 5, "transportWarpBaseDelay")
	lu.assertEquals(c.helloDelay, 2, "helloDelay")
	lu.assertEquals(c.nextLegDelay, 2, "nextLegDelay")
	lu.assertEquals(c.finishDelay, 2, "finishDelay")
	lu.assertEquals(c.transportDepartDelay, 15, "transportDepartDelay")
	lu.assertEquals(c.noPickupAttackDelay, 10, "noPickupAttackDelay")
	lu.assertEquals(c.maxActiveWaves, 2, "maxActiveWaves")
	lu.assertEquals(c.spawnMinDistance, 1000, "spawnMinDistance")
	lu.assertEquals(c.spawnMaxDistance, 1200, "spawnMaxDistance")
	lu.assertEquals(c.spawnSpread, 150, "spawnSpread")
	lu.assertEquals(c.squadronMinSize, 4, "squadronMinSize")
end

-- Content contract: per-quest data defaults on the class
function TestDeliveryClassContract:test_the_per_quest_data_fields_have_class_defaults()
	local c = H.expectGlobal("SpaceDeliveryScreenplay")

	lu.assertEquals(c.pickupPoint, {}, "pickupPoint default")
	lu.assertEquals(c.deliveryPoint, {}, "deliveryPoint default")
	lu.assertEquals(c.pickupShip, "", "pickupShip default")
	lu.assertEquals(c.deliveryShip, "", "deliveryShip default")
	lu.assertEquals(c.attackShipLists, {}, "attackShipLists default")
	lu.assertEquals(c.attackPeriod, 0, "attackPeriod default")
	lu.assertEquals(c.attackListType, 0, "attackListType default")
end

-- Content contract: the screenplay is registered without autostart and has an empty start()
function TestDeliveryClassContract:test_both_classes_are_registered_screenplays_without_autostart()
	for _, name in ipairs({ "SpaceDeliveryScreenplay", "SpaceDeliveryNoPickupScreenplay" }) do
		local r = H.registered(name)

		lu.assertNotNil(r, name .. ": registerScreenPlay")
		lu.assertFalse(r.start, name .. ": registered with start = false")
		lu.assertEquals(type(H.expectGlobal(name).start), "function", name .. ": start()")
	end
end

-- Content contract: the public method names tests and events rely on
function TestDeliveryClassContract:test_the_public_methods_exist_on_the_quest_instances()
	local names = { "startQuest", "completeQuest", "failQuest", "resetQuest", "enteredZone", "notifyEnteredQuestArea",
		"notifyTransportDestroyed", "notifyDocked", "notifyAttackShipDestroyed", "cleanUpQuestData", "notifyTargetsRemaining",
		"launchWave", "dataKey", "messagePath", "isCurrentRun", "getRunToken" }
	local q = quest("delivery", "corellia_rebel_tier3_3")

	for _, m in ipairs(names) do
		lu.assertEquals(type(q[m]), "function", "delivery_corellia_rebel_tier3_3." .. m)
	end
end

-- Content contract: the no-pickup class has no logic of its own
function TestDeliveryClassContract:test_the_no_pickup_class_only_flips_has_pickup_and_keeps_an_empty_start()
	local c = H.expectGlobal("SpaceDeliveryNoPickupScreenplay")

	lu.assertEquals(c.className, "SpaceDeliveryNoPickupScreenplay", "className")
	lu.assertEquals(rawget(c, "hasPickup"), false, "hasPickup = false")
	lu.assertEquals(H.expectGlobal("SpaceDeliveryScreenplay").hasPickup, true, "the base class keeps hasPickup = true")

	local functions = {}

	for k, v in pairs(c) do
		if type(v) == "function" then
			functions[#functions + 1] = k
		end
	end

	lu.assertEquals(functions, { "start" }, "raw functions on SpaceDeliveryNoPickupScreenplay (all behavior branches on self.hasPickup)")
end

-- AC-2 (source level): the half-second stub is gone
function TestDeliveryClassContract:test_the_remove_after_implementation_stub_is_gone_from_the_source()
	local f = io.open(H.SCRIPTS .. "screenplays/space/SpaceDeliveryScreenplay.lua", "r")

	lu.assertNotNil(f, "SpaceDeliveryScreenplay.lua exists")

	local src = f:read("a")
	f:close()

	lu.assertNil(src:find("REMOVE AFTER IMPLEMENTATION", 1, true), "the stub marker must be removed")
	lu.assertNil(src:find('createEvent(500, self.className, "completeQuest"', 1, true), "the 0.5 s auto-completion must be removed")
end
