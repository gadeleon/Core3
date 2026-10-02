-- Inspect quest data conformance (space-quest-inspect-cargo).
-- Spec: .claude/work/space-quest-inspect-cargo/01-spec.md (AC-1, AC-2, I-1, I-2, I-3, Content contract: class
-- constants and data fields, Data mapping, Ship templates). The oracle is the SWG-Source .tab copies in
-- fixtures/spacequest/inspect/ and fixtures/spacequest/inspect_cargo/ plus the Core3 space spawner tables
-- (which are the port of the SWG buildout spawners), never the Core3 quest tables under test.

local lu = require("luaunit")
local H = require("harness")
local I = require("inspect_scenario")

I.load()

local function quest(name)
	return H.expectGlobal(I.global(name), "inspect quest table for " .. name)
end

local function label(name) return "inspect/" .. name end

---------------------------------------------------------------------------------------------
-- Ship template files (static read, the engine gate loads them for real)
---------------------------------------------------------------------------------------------

local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	local f = io.open(path, "r")
	local src = f:read("a")
	f:close()

	return (src:gsub("%-%-[^\n]*", ""))
end

-- { cargoString = string or nil, questLoot = string or nil } as the template file declares them.
local function template(shipName)
	local src = templateSource(shipName)

	return { cargoString = src:match('cargoString%s*=%s*"(.-)"'), questLoot = src:match('questLoot%s*=%s*"(.-)"') }
end

-- The (name, canTransfer) rows of fixtures/spacequest/inspect_cargo/<table>.tab.
local function cargoRows(tableName)
	local rows = {}

	for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/" .. tableName .. ".tab").records) do
		rows[#rows + 1] = { name = rec:get("name"), canTransfer = rec:num("canTransfer") }
	end

	return rows
end

local function cargoIsTransferable(tableName, cargo)
	for _, row in ipairs(cargoRows(tableName)) do
		if row.name == cargo and row.canTransfer == 1 then
			return true
		end
	end

	return false
end

---------------------------------------------------------------------------------------------
-- AC-1: quest data equals the .tab
---------------------------------------------------------------------------------------------

TestInspectDataConformance = {}

function TestInspectDataConformance:setUp() H.reset() end

-- AC-1
function TestInspectDataConformance:test_zone_ship_list_waypoint_flag_and_cargo_equal_the_tab()
	for _, name in ipairs(I.NAMES) do
		local o = I.oracle(name)
		local q = quest(name)

		lu.assertEquals(q.questZone, o.zone, label(name) .. ": questZone")
		lu.assertEquals(q.shipList, o.shipList, label(name) .. ": shipList (non-empty cells of the column, top to bottom)")
		lu.assertEquals(q.giveSpawnWaypoint, o.give, label(name) .. ": giveSpawnWaypoint")
		lu.assertEquals(q.cargo, o.cargo, label(name) .. ": cargo")
	end
end

-- AC-1
function TestInspectDataConformance:test_valid_spawns_are_the_tab_spawners_in_order_with_the_spawner_table_coordinates()
	for _, name in ipairs(I.NAMES) do
		local o = I.oracle(name)
		local spawns = quest(name).validSpawns

		lu.assertEquals(type(spawns), "table", label(name) .. ": validSpawns must be a table")
		lu.assertEquals(#spawns, #o.spawns, label(name) .. ": number of validSpawns")

		for i, s in ipairs(o.spawns) do
			lu.assertEquals(type(spawns[i]), "table", label(name) .. ": validSpawns[" .. i .. "] must be a table, not a 'zone:name' string")
			lu.assertEquals(spawns[i].spawnName, s.spawnName, label(name) .. ": validSpawns[" .. i .. "].spawnName")
			lu.assertEquals(s.zone, o.zone, label(name) .. ": the .tab's spawner zone equals questZone (spawner " .. i .. ")")
			lu.assertEquals(spawns[i].x, s.x, label(name) .. ": validSpawns[" .. i .. "].x")
			lu.assertEquals(spawns[i].z, s.z, label(name) .. ": validSpawns[" .. i .. "].z")
			lu.assertEquals(spawns[i].y, s.y, label(name) .. ": validSpawns[" .. i .. "].y")
		end
	end
end

-- AC-1, the oracle itself (guards against a fixture that parsed into something unexpected)
function TestInspectDataConformance:test_the_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		corellia_privateer_15 = { "space_lok", { "nym_cannon_ship_tier2", "nym_cannon_ship_tier4", "nym_cannon_ship" }, { { "nyms_boys", 3719, -2284, -1151 } }, "shipment_orders" },
		corellia_privateer_tier3_2 = { "space_dathomir", { "civshuttle_cor_tier3_pilot_capture" }, { { "corellia_privateer_tier3_2_inspect", -50, 1375, 1510 } }, "cor_priv_tier3_capture_pilot" },
		viopa_rebel_1 = { "space_lok", { "viopa_mission_1_shuttle" }, { { "viopa_rebel_1_shuttle", 2102, 1022, 2191 } }, "imperial_data" },
		corellia_rebel_tier3_2 = { "space_endor", { "huttsmuggler" }, { { "hutt_smuggler_01", 4249, 2899, 3799 }, { "hutt_smuggler_02", 4730, -2531, -3607 }, { "hutt_smuggler_route", -4266, 3939, -3918 } }, "sector_recon_data" },
		naboo_privateer_tier3_3a = { "space_naboo", { "naboo_diplomatic_corps_bad_tier3" }, { { "naboo_privateer_tier3_leg_3_inspect", 3151, 3183, 4026 } }, "encrypted_documents" },
	}

	for _, name in ipairs(I.NAMES) do
		local o = I.oracle(name)
		local spawns = {}

		for i, s in ipairs(o.spawns) do
			spawns[i] = { s.spawnName, s.x, s.z, s.y }
		end

		lu.assertEquals({ o.zone, o.shipList, spawns, o.cargo }, want[name], label(name) .. ": {zone, shipList, validSpawns, cargo} in the fixtures and spawner tables")
		lu.assertEquals(o.give, 1, label(name) .. ": giveSpawnWaypoint in the fixture")
	end
end

-- AC-1 (fields left alone), pre-existing content the slice must not regress
function TestInspectDataConformance:test_identity_and_split_fields_still_match_the_tab()
	for _, name in ipairs(I.NAMES) do
		local o = I.oracle(name)
		local q = quest(name)

		lu.assertEquals(q.className, I.global(name), label(name) .. ": className")
		lu.assertEquals(q.questName, name, label(name) .. ": questName")
		lu.assertEquals(q.questType, "inspect", label(name) .. ": questType")
		lu.assertNotNil(H.registered(I.global(name)), label(name) .. ": registerScreenPlay still called")
		lu.assertTrue(H.registered(I.global(name)).start, label(name) .. ": registered with start = true")

		if o.triggerEvent == "splitquest" then
			lu.assertTrue(q.sideQuest, label(name) .. ": sideQuest")
			lu.assertEquals(q.sideQuestType, o.sideType, label(name) .. ": sideQuestType")
			lu.assertEquals(q.sideQuestName, o.sideName, label(name) .. ": sideQuestName")
			lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, label(name) .. ": triggerSplitCondition success is COMPLETION")
		else
			lu.assertFalse(q.sideQuest, label(name) .. ": no side quest")
		end
	end
end

---------------------------------------------------------------------------------------------
-- I-2: no legacy keys; the class contract
---------------------------------------------------------------------------------------------

TestInspectDataInvariants = {}

function TestInspectDataInvariants:setUp() H.reset() end

-- I-2
function TestInspectDataInvariants:test_the_five_quests_have_no_legacy_inspect_keys()
	for _, name in ipairs(I.NAMES) do
		for _, key in ipairs({ "inspectTargets", "inspectCargo", "targetLocation" }) do
			lu.assertNil(quest(name)[key], label(name) .. ": legacy key " .. key .. " must be removed")
		end
	end
end

-- I-2
function TestInspectDataInvariants:test_the_class_drops_the_legacy_fields_and_the_old_verifier()
	for _, key in ipairs({ "inspectTargets", "inspectCargo", "targetLocation", "veryifyShipTargetAndCargo" }) do
		lu.assertNil(SpaceInspectScreenplay[key], "SpaceInspectScreenplay." .. key .. " must be removed")
	end
end

-- I-2, AC-7 (the documented exception)
function TestInspectDataInvariants:test_naboo_privateer_15_is_the_documented_exception_and_keeps_its_legacy_data_with_no_schema_data()
	local q = quest(I.MISSING)

	lu.assertEquals(q.inspectTargets, { "blacksun_gunship_tier2" }, "inspect/naboo_privateer_15: inspectTargets untouched")
	lu.assertEquals(q.inspectCargo, "shipment_orders", "inspect/naboo_privateer_15: inspectCargo untouched")
	lu.assertEquals(type(q.targetLocation), "table", "inspect/naboo_privateer_15: targetLocation untouched")
	lu.assertEquals(q.shipList, {}, "inspect/naboo_privateer_15: no shipList")
	lu.assertEquals(q.validSpawns, {}, "inspect/naboo_privateer_15: no validSpawns")
	lu.assertEquals(q.cargo, "", "inspect/naboo_privateer_15: no cargo")
	lu.assertEquals(q.giveSpawnWaypoint, 0, "inspect/naboo_privateer_15: giveSpawnWaypoint stays at the class default")
end

-- Content contract: class defaults and constants
function TestInspectDataInvariants:test_the_class_has_the_schema_defaults()
	lu.assertEquals(SpaceInspectScreenplay.className, "SpaceInspectScreenplay", "className")
	lu.assertEquals(SpaceInspectScreenplay.shipList, {}, "shipList default")
	lu.assertEquals(SpaceInspectScreenplay.validSpawns, {}, "validSpawns default")
	lu.assertEquals(SpaceInspectScreenplay.giveSpawnWaypoint, 0, "giveSpawnWaypoint default")
	lu.assertEquals(SpaceInspectScreenplay.cargo, "", "cargo default")
	lu.assertNotNil(H.registered("SpaceInspectScreenplay"), "registerScreenPlay(SpaceInspectScreenplay) still called")
	lu.assertFalse(H.registered("SpaceInspectScreenplay").start, "registered with start = false")
end

-- Content contract: class defaults and constants
function TestInspectDataInvariants:test_the_class_constants_equal_the_spec_values()
	lu.assertEquals(SpaceInspectScreenplay.setupDelay, I.SETUP_DELAY, "setupDelay (ms)")
	lu.assertEquals(SpaceInspectScreenplay.waypointNoticeDelay, I.NOTICE_DELAY, "waypointNoticeDelay (ms)")
	lu.assertEquals(SpaceInspectScreenplay.waypointName, I.WAYPOINT_NAME, "waypointName")
	lu.assertEquals(SpaceInspectScreenplay.waypointDetails, I.WAYPOINT_DETAILS, "waypointDetails")
	lu.assertEquals(SpaceInspectScreenplay.firstSpawnTask, I.FIRST_SPAWN_TASK, "firstSpawnTask")
end

-- Content contract: public methods
function TestInspectDataInvariants:test_the_class_defines_the_public_methods_the_tests_call()
	for _, m in ipairs({ "start", "startQuest", "completeQuest", "failQuest", "resetQuest", "cleanUpQuestData", "enteredZone", "setupInspection",
		"notifyTargetWaypoints", "inspectedShip", "dockedShip", "cargoFound", "cargoRecovered", "abandonInspection", "hasQuestData", "isQuestCargo",
		"isQuestTarget" }) do
		lu.assertEquals(type(SpaceInspectScreenplay[m]), "function", "SpaceInspectScreenplay:" .. m)
	end
end

-- Scope: only the 6 inspect globals exist, 5 with data
function TestInspectDataInvariants:test_there_are_exactly_the_six_inspect_quests()
	local got = {}

	for _, n in ipairs(H.questGlobals()) do
		if rawget(_G, n).questType == "inspect" and rawget(_G, n).questName ~= "" then
			got[#got + 1] = n
		end
	end

	local expected = { I.global(I.MISSING) }

	for _, name in ipairs(I.NAMES) do
		expected[#expected + 1] = I.global(name)
	end

	table.sort(expected)
	lu.assertEquals(got, expected, "inspect quest globals")
end

---------------------------------------------------------------------------------------------
-- AC-2 and I-3: ship templates and target supply
---------------------------------------------------------------------------------------------

TestInspectShipTemplates = {}

function TestInspectShipTemplates:setUp() H.reset() end

-- AC-2
function TestInspectShipTemplates:test_the_three_templates_gain_the_cargo_string_their_swg_cargo_table_names()
	local want = {
		nym_cannon_ship = "shipment_orders",
		nym_cannon_ship_tier4 = "shipment_orders",
		naboo_diplomatic_corps_bad_tier3 = "encrypted_documents",
	}

	for ship, cargo in pairs(want) do
		lu.assertEquals(template(ship).cargoString, cargo, "ship_mobile/ships/" .. ship .. ".lua: cargoString")
	end
end

-- AC-2
function TestInspectShipTemplates:test_each_new_cargo_string_is_a_transferable_row_of_the_ships_own_swg_cargo_table()
	for _, ship in ipairs({ "nym_cannon_ship", "nym_cannon_ship_tier4", "naboo_diplomatic_corps_bad_tier3" }) do
		local t = template(ship)

		lu.assertNotNil(t.questLoot, ship .. ": questLoot")
		lu.assertNotNil(t.cargoString, ship .. ": cargoString")
		lu.assertTrue(cargoIsTransferable(t.questLoot, t.cargoString),
			ship .. ": cargoString '" .. tostring(t.cargoString) .. "' must be a row with canTransfer = 1 in inspect_cargo/" .. t.questLoot .. ".tab")
	end
end

-- AC-2
function TestInspectShipTemplates:test_ships_without_swg_cargo_still_declare_no_cargo_string()
	for _, ship in ipairs({ "civshuttle", "blacksun_gunship_tier2" }) do
		local cargo = template(ship).cargoString

		lu.assertTrue(cargo == nil or cargo == "", ship .. ": must not declare a non-empty cargoString, got " .. tostring(cargo))
	end
end

-- AC-2, the oracle itself: the cargo tables the spec names have the rows it says
function TestInspectShipTemplates:test_the_cargo_table_fixtures_carry_the_rows_the_spec_lists()
	lu.assertEquals(cargoRows("corellia_privateer_15"), { { name = "shipment_orders", canTransfer = 1 } }, "corellia_privateer_15 table")
	lu.assertEquals(cargoRows("encrypted_documents"), { { name = "encrypted_documents", canTransfer = 1 } }, "encrypted_documents table")
	lu.assertEquals(cargoRows("cor_priv_tier3_capture_pilot"), { { name = "cor_priv_tier3_capture_pilot", canTransfer = 1 } }, "cor_priv_tier3_capture_pilot table")
	lu.assertEquals(cargoRows("viopa_rebel_1"), { { name = "imperial_data", canTransfer = 1 } }, "viopa_rebel_1 table")

	local hutt = 0

	for _, row in ipairs(cargoRows("hutt_smuggler")) do
		if row.name == "sector_recon_data" then
			hutt = hutt + 1
			lu.assertEquals(row.canTransfer, 1, "hutt_smuggler sector_recon_data canTransfer")
		end
	end

	lu.assertEquals(hutt, 3, "hutt_smuggler has 3 sector_recon_data rows")
end

-- I-3
function TestInspectShipTemplates:test_every_ship_of_every_quest_carries_the_quest_cargo_as_a_transferable_cargo_string()
	for _, name in ipairs(I.NAMES) do
		local q = quest(name)

		lu.assertEquals(type(q.shipList), "table", label(name) .. ": shipList must be a table")

		for _, ship in ipairs(q.shipList) do
			local t = template(ship)

			lu.assertEquals(t.cargoString, q.cargo, label(name) .. ": ship_mobile/ships/" .. ship .. ".lua cargoString must equal the quest cargo")
			lu.assertNotNil(t.questLoot, label(name) .. ": " .. ship .. " questLoot")
			lu.assertTrue(cargoIsTransferable(t.questLoot, q.cargo), label(name) .. ": " .. ship .. " cargo '" .. q.cargo .. "' is a canTransfer = 1 row of inspect_cargo/" .. t.questLoot .. ".tab")
		end
	end
end

-- I-3
function TestInspectShipTemplates:test_every_valid_spawner_exists_and_spawns_a_quest_ship_directly_or_through_a_squadron()
	local squadrons = H.squadrons()

	for _, name in ipairs(I.NAMES) do
		local q = quest(name)
		local wanted = {}

		lu.assertEquals(type(q.shipList), "table", label(name) .. ": shipList must be a table")
		lu.assertEquals(type(q.validSpawns), "table", label(name) .. ": validSpawns must be a table")

		for _, ship in ipairs(q.shipList) do
			wanted[ship] = true
		end

		for i, spawn in ipairs(q.validSpawns) do
			local entry = H.spawners(q.questZone)[spawn.spawnName]

			lu.assertNotNil(entry, label(name) .. ": validSpawns[" .. i .. "] '" .. tostring(spawn.spawnName) .. "' must exist in " .. q.questZone .. "_spawner.lua")

			local found = false

			for _, shipOrSquad in ipairs(entry.shipSpawns) do
				if wanted[shipOrSquad] then
					found = true
				end

				for _, member in ipairs(squadrons[shipOrSquad] and squadrons[shipOrSquad][2] or {}) do
					if wanted[member] then
						found = true
					end
				end
			end

			lu.assertTrue(found, label(name) .. ": spawner '" .. spawn.spawnName .. "' must spawn at least one of " .. table.concat(q.shipList, ", "))
		end
	end
end
