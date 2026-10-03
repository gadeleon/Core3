-- CorSec tier 3 extensions: the two new Ramna mission 4 quests, split wiring, cargo and rewards.
-- Spec: .claude/work/corsec-tier3-extensions/01-spec.md (AC-1, AC-2, AC-3, AC-4, AC-9, invariants I-1 to I-6, Data mapping).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/, the cut-down buildout extract
-- fixtures/space_zones/buildout/space_endor.corsec_tier3_points.tab, the space_mobile excerpt, the trainer script
-- fixtures/script/conversation/corellia_privateer_tier3.java and the Core3 patrol point / spawner files, never the
-- Core3 quest tables under test. Values the spec spells out are repeated as literal anchors so a misparsed fixture
-- cannot make a wrong table look right. "Pre-feature" values are pinned as literals taken from the tables at 83e2437024.
--
-- Fixture recipes (see tests/lua/README.md, "SWG-Source fixtures"; G = .../dsrc/sku.0/sys.server/compiled/game):
--   space_zones/buildout/space_endor.corsec_tier3_points.tab = sed -n '1,2p;17p;391p;764p;765p' $G/datatables/space_zones/buildout/space_endor.tab
--   space_mobile/space_mobile.evil_raider_tyrant_tier3.tab   = sed -n '1,2p;706p' $G/datatables/space_mobile/space_mobile.tab

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")
local I = require("inspect_scenario")
local S = require("survival_scenario")

D.load()

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

local INSPECT = "inspect_corellia_privateer_tier3_4_b"
local DELIVERY = "delivery_no_pickup_corellia_privateer_tier3_4_c"
local SURVIVAL = "survival_corellia_privateer_tier3_4_a"
local ASSASSINATE_4 = "assassinate_corellia_privateer_tier3_4"
local ASSASSINATE_3D = "assassinate_corellia_privateer_tier3_3d"
local SPAWNER = "corellia_privateer_tier3_inspect_spawner"

local function quest(global, hint)
	return H.expectGlobal(global, hint or "CorSec tier 3 quest table")
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- Truncation toward zero, as Core3's coordinates truncate the buildout floats.
local function trunc(n)
	if n >= 0 then
		return math.floor(n)
	end

	return math.ceil(n)
end

-- The buildout extract record whose strObjVars contain `needle`.
local function buildout(needle)
	local tab = H.fixture("space_zones/buildout/space_endor.corsec_tier3_points.tab")

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars")

		if vars ~= nil and vars:find(needle, 1, true) then
			return rec
		end
	end

	error("buildout extract has no record containing " .. needle, 0)
end

-- { x, z, y } of a buildout record (fltPX, fltPY, fltPZ), truncated.
local function buildoutXzy(rec)
	return { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
end

---------------------------------------------------------------------------------------------
-- Oracle sanity: the fixtures carry the values the spec lists
---------------------------------------------------------------------------------------------

TestCorsecTier3Fixtures = {}

function TestCorsecTier3Fixtures:setUp() H.reset() end

-- AC-1, AC-2 (the oracle itself)
function TestCorsecTier3Fixtures:test_the_new_quest_fixtures_carry_the_values_the_spec_lists()
	local ins = H.questFixture("inspect", "corellia_privateer_tier3_4_b")

	lu.assertEquals({ ins:get("questZone"), ins:list("shipList"), ins:list("validSpawns"), ins:num("giveSpawnWaypoint"), ins:get("cargo") },
		{ "space_endor", { "evil_raider_tyrant_tier3" }, { "space_endor:" .. SPAWNER }, 1, "stolen_data" }, "inspect/corellia_privateer_tier3_4_b: {zone, ships, spawns, give, cargo}")
	lu.assertEquals({ ins:get("triggerEvent"), ins:get("triggerSplitCondition"), ins:get("triggerArg"), ins:num("triggerDelay") },
		{ "splitquest", "success", "delivery_no_pickup:corellia_privateer_tier3_4_c", 0 }, "inspect/corellia_privateer_tier3_4_b: trigger columns")

	local del = H.questFixture("delivery_no_pickup", "corellia_privateer_tier3_4_c")

	lu.assertEquals({ del:get("questZone"), del:get("deliveryPoint"), del:get("deliveryShip"), del:num("numAttackShipLists"), del:num("attackPeriod"), del:get("attackListType"), del:get("triggerEvent") },
		{ "space_endor", "space_endor:corellia_privateer_tier3_delivery", "corsec_lancer_tier3", 2, 65, "random", "none" }, "delivery_no_pickup/corellia_privateer_tier3_4_c: scalar columns")
	lu.assertEquals(del:list("attackShips1"), { "evil_raider_tyrant_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3" }, "4_c attackShips1")
	lu.assertEquals(del:list("attackShips2"), { "evil_raider_tyrant_tier3", "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3" }, "4_c attackShips2")

	local sur = H.questFixture("survival", "corellia_privateer_tier3_4_a")

	lu.assertEquals({ sur:get("triggerEvent"), sur:get("triggerSplitCondition"), sur:get("triggerArg"), sur:get("triggerDelay") },
		{ "splitquest", "success", "inspect:corellia_privateer_tier3_4_b", nil }, "survival/corellia_privateer_tier3_4_a: trigger columns (no triggerDelay)")

	local a4 = H.questFixture("assassinate", "corellia_privateer_tier3_4")

	lu.assertEquals({ a4:get("triggerEvent"), a4:get("triggerSplitCondition"), a4:get("triggerArg") }, { "splitquest", "success", "survival:corellia_privateer_tier3_4_a" }, "assassinate/corellia_privateer_tier3_4: trigger columns")
	lu.assertEquals(H.questFixture("assassinate", "corellia_privateer_tier3_3d"):get("triggerEvent"), "none", "assassinate/corellia_privateer_tier3_3d: triggerEvent")
end

---------------------------------------------------------------------------------------------
-- AC-1: inspect_corellia_privateer_tier3_4_b
---------------------------------------------------------------------------------------------

TestCorsecTier3Inspect4b = {}

function TestCorsecTier3Inspect4b:setUp() H.reset() end

-- AC-1, I-1
function TestCorsecTier3Inspect4b:test_the_inspect_table_exists_is_registered_with_start_and_is_named_after_its_global()
	local q = quest(INSPECT, "inspect_corellia_privateer_tier3_4_b in screenplays/space/squadrons/CorsecSquadronScreenplay.lua")

	lu.assertEquals(q.className, INSPECT, "className")
	lu.assertEquals(q.questType, "inspect", "questType")
	lu.assertEquals(q.questName, "corellia_privateer_tier3_4_b", "questName")
	lu.assertEquals(q.questType .. "_" .. q.questName, INSPECT, "questType_questName is the global name")
	lu.assertNotNil(H.registered(INSPECT), INSPECT .. ": registerScreenPlay was called")
	lu.assertTrue(H.registered(INSPECT).start, INSPECT .. ": registered with start = true")
end

-- AC-1, I-2
function TestCorsecTier3Inspect4b:test_zone_ship_list_waypoint_flag_and_cargo_equal_the_tab()
	local o = I.oracle("corellia_privateer_tier3_4_b")
	local q = quest(INSPECT)

	lu.assertEquals(q.questZone, o.zone, "inspect/corellia_privateer_tier3_4_b: questZone")
	lu.assertEquals(q.shipList, o.shipList, "inspect/corellia_privateer_tier3_4_b: shipList")
	lu.assertEquals(q.giveSpawnWaypoint, o.give, "inspect/corellia_privateer_tier3_4_b: giveSpawnWaypoint")
	lu.assertEquals(q.cargo, o.cargo, "inspect/corellia_privateer_tier3_4_b: cargo")
end

-- AC-1, I-5
function TestCorsecTier3Inspect4b:test_valid_spawns_are_the_tab_spawner_with_the_spawner_table_coordinates()
	local o = I.oracle("corellia_privateer_tier3_4_b")
	local spawns = quest(INSPECT).validSpawns

	lu.assertEquals(type(spawns), "table", "validSpawns must be a table")
	lu.assertEquals(#spawns, 1, "inspect/corellia_privateer_tier3_4_b: number of validSpawns")
	lu.assertEquals(spawns[1].spawnName, o.spawns[1].spawnName, "validSpawns[1].spawnName")
	lu.assertEquals(spawns[1].x, o.spawns[1].x, "validSpawns[1].x")
	lu.assertEquals(spawns[1].z, o.spawns[1].z, "validSpawns[1].z")
	lu.assertEquals(spawns[1].y, o.spawns[1].y, "validSpawns[1].y")
	lu.assertEquals({ spawns[1].spawnName, spawns[1].x, spawns[1].z, spawns[1].y }, { SPAWNER, 1317, -455, -2876 }, "validSpawns[1] literal (spec contract)")
end

-- AC-1, I-5
function TestCorsecTier3Inspect4b:test_the_spawner_entry_spawns_the_tyrant_and_equals_the_truncated_buildout_values()
	local entry = H.spawners("space_endor")[SPAWNER]

	lu.assertNotNil(entry, SPAWNER .. " must exist in space_endor_spawner.lua")
	lu.assertEquals(entry.shipSpawns, { "evil_raider_tyrant_tier3" }, SPAWNER .. ": shipSpawns")

	local spawner = buildout("strSpawnerName|4|" .. SPAWNER .. "|")

	lu.assertEquals({ entry.x, entry.z, entry.y }, buildoutXzy(spawner), SPAWNER .. ": Core3 spawner x/z/y equal the SWG buildout truncated")
	lu.assertEquals(entry.totalSpawns, 3, SPAWNER .. ": totalSpawns equals the buildout intSpawnCount")
	lu.assertNotNil(spawner:get("strObjVars"):find("intSpawnCount|0|3|", 1, true), "buildout intSpawnCount is 3")
	lu.assertNotNil(spawner:get("strObjVars"):find("strSpawns_mangled.segment.0|5|evil_raider_tyrant_tier3:", 1, true), "buildout spawns the tyrant")
end

-- AC-1 (existing content the new quest relies on, passes before the feature)
function TestCorsecTier3Inspect4b:test_the_two_spawner_patrol_points_equal_the_truncated_buildout_rows()
	local points = H.patrolPoints("space_endor")
	local want = {
		corellia_privateer_tier3_inspect_spawner_00 = buildoutXzy(buildout("strName|4|corellia_privateer_tier3_inspect_spawner_00|")),
		corellia_privateer_tier3_inspect_spawner_01 = buildoutXzy(buildout("strName|4|corellia_privateer_tier3_inspect_spawner_01|")),
	}

	for name, xzy in pairs(want) do
		lu.assertNotNil(points[name], "patrol point " .. name)
		lu.assertEquals({ points[name].x, points[name].z, points[name].y }, xzy, name .. ": x/z/y")
	end
end

-- AC-1
function TestCorsecTier3Inspect4b:test_the_contract_fields_rewards_parent_and_split_wiring()
	local q = quest(INSPECT)

	lu.assertEquals(q.creditReward, 0, "creditReward")
	lu.assertEquals(q.itemReward, {}, "itemReward")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { SURVIVAL, "survival", "corellia_privateer_tier3_4_a" }, "parentQuest / Type / Name")
	lu.assertEquals(q.sideQuest, true, "sideQuest")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { "delivery_no_pickup", "corellia_privateer_tier3_4_c" }, "sideQuestType / sideQuestName")
	lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, "sideQuestSplitType (triggerSplitCondition success)")
end

-- AC-1, I-3 (D-3: triggerDelay 0 + 5)
function TestCorsecTier3Inspect4b:test_the_split_delay_is_the_tab_trigger_delay_plus_five()
	local o = I.oracle("corellia_privateer_tier3_4_b")

	lu.assertEquals(quest(INSPECT).sideQuestDelay, (o.triggerDelay or 0) + 5, "inspect/corellia_privateer_tier3_4_b: sideQuestDelay = triggerDelay + 5")
	lu.assertEquals(quest(INSPECT).sideQuestDelay, 5, "literal")
end

-- AC-1 (the split target comes from the tab's triggerArg)
function TestCorsecTier3Inspect4b:test_the_split_target_equals_the_tab_trigger_arg()
	local o = I.oracle("corellia_privateer_tier3_4_b")
	local q = quest(INSPECT)

	lu.assertEquals(o.sideGlobal, DELIVERY, "oracle: the tab names the 4_c delivery_no_pickup quest")
	lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, o.sideGlobal, "inspect/corellia_privateer_tier3_4_b: split target")
end

---------------------------------------------------------------------------------------------
-- AC-2: delivery_no_pickup_corellia_privateer_tier3_4_c
---------------------------------------------------------------------------------------------

TestCorsecTier3Delivery4c = {}

function TestCorsecTier3Delivery4c:setUp() H.reset() end

-- AC-2, I-1
function TestCorsecTier3Delivery4c:test_the_delivery_table_exists_is_registered_with_start_and_has_no_pickup()
	local q = quest(DELIVERY, "delivery_no_pickup_corellia_privateer_tier3_4_c in screenplays/space/squadrons/CorsecSquadronScreenplay.lua")

	lu.assertEquals(q.className, DELIVERY, "className")
	lu.assertEquals(q.questType, "delivery_no_pickup", "questType")
	lu.assertEquals(q.questName, "corellia_privateer_tier3_4_c", "questName")
	lu.assertEquals(q.questType .. "_" .. q.questName, DELIVERY, "questType_questName is the global name")
	lu.assertNotNil(H.registered(DELIVERY), DELIVERY .. ": registerScreenPlay was called")
	lu.assertTrue(H.registered(DELIVERY).start, DELIVERY .. ": registered with start = true")
	lu.assertEquals(q.hasPickup, false, "hasPickup (SpaceDeliveryNoPickupScreenplay)")
end

-- AC-2, I-2
function TestCorsecTier3Delivery4c:test_zone_and_delivery_ship_equal_the_tab_and_no_pickup_is_configured()
	local o = D.oracle("delivery_no_pickup", "corellia_privateer_tier3_4_c")
	local q = quest(DELIVERY)

	lu.assertEquals(o.hasPickup, false, "oracle: the tab has no pickupPoint column")
	lu.assertEquals(q.questZone, o.zone, "delivery_no_pickup/corellia_privateer_tier3_4_c: questZone")
	lu.assertEquals(q.deliveryShip, o.deliveryShip, "delivery_no_pickup/corellia_privateer_tier3_4_c: deliveryShip")
	lu.assertEquals(q.pickupShip, "", "pickupShip inherits the class default")
	lu.assertEquals(q.pickupPoint, {}, "pickupPoint inherits the class default")
	lu.assertNil(rawget(q, "pickupShip"), "no raw pickupShip")
	lu.assertNil(rawget(q, "pickupPoint"), "no raw pickupPoint")
end

-- AC-2, I-5
function TestCorsecTier3Delivery4c:test_the_delivery_point_is_the_named_patrol_point_with_its_coordinates_and_the_buildout_values()
	local o = D.oracle("delivery_no_pickup", "corellia_privateer_tier3_4_c")
	local p = quest(DELIVERY).deliveryPoint

	lu.assertEquals(type(p), "table", "deliveryPoint must be a table")
	lu.assertEquals(p.patrolPointName, o.delivery.name, "deliveryPoint.patrolPointName")
	lu.assertEquals({ p.x, p.z, p.y }, { o.delivery.x, o.delivery.z, o.delivery.y }, "deliveryPoint x/z/y equal the space_endor patrol point")
	lu.assertEquals(p.patrolPointName, "corellia_privateer_tier3_delivery", "literal name")

	local nav = buildout("nav_name|4|corellia_privateer_tier3_delivery|")

	lu.assertEquals({ p.x, p.z, p.y }, buildoutXzy(nav), "deliveryPoint x/z/y equal the SWG buildout nav point truncated")
end

-- AC-2
function TestCorsecTier3Delivery4c:test_attack_lists_are_the_tab_columns_with_two_lists_period_65_and_random()
	local o = D.oracle("delivery_no_pickup", "corellia_privateer_tier3_4_c")
	local q = quest(DELIVERY)

	lu.assertEquals(type(q.attackShipLists), "table", "attackShipLists must be a table")
	lu.assertEquals(o.listCount, 2, "oracle: numAttackShipLists")
	lu.assertEquals(#q.attackShipLists, o.listCount, "#attackShipLists == numAttackShipLists")

	for i, list in ipairs(o.lists) do
		lu.assertEquals(q.attackShipLists[i], list, "delivery_no_pickup/corellia_privateer_tier3_4_c: attackShipLists[" .. i .. "] (column attackShips" .. i .. ")")
	end

	lu.assertEquals(q.attackPeriod, o.period, "attackPeriod")
	lu.assertEquals(q.attackPeriod, 65, "attackPeriod literal")
	lu.assertEquals(q.attackListType, o.listType, "attackListType (random = 1 in the .tab enum)")
	lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, "attackListType is ATTACK_LIST_TYPES.RANDOM")
end

-- AC-2
function TestCorsecTier3Delivery4c:test_the_contract_fields_rewards_parent_and_no_side_quest()
	local q = quest(DELIVERY)

	lu.assertEquals(q.creditReward, 0, "creditReward")
	lu.assertEquals(q.itemReward, {}, "itemReward")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { INSPECT, "inspect", "corellia_privateer_tier3_4_b" }, "parentQuest / Type / Name")
	lu.assertEquals(q.sideQuest, false, "sideQuest (triggerEvent none)")
	lu.assertEquals(q.sideQuestType, "", "sideQuestType")
end

-- AC-2, I-3, I-4
function TestCorsecTier3Delivery4c:test_every_attack_ship_and_the_transport_have_a_ship_template()
	local q = quest(DELIVERY)
	local names = { q.deliveryShip }

	for _, list in ipairs(q.attackShipLists) do
		for _, ship in ipairs(list) do
			names[#names + 1] = ship
		end
	end

	lu.assertTrue(#names > 1, "the quest names ships")

	for _, ship in ipairs(names) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. ship .. ".lua"), "delivery_no_pickup/corellia_privateer_tier3_4_c: no ship template ship_mobile/ships/" .. ship .. ".lua")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: split wiring and chains
---------------------------------------------------------------------------------------------

TestCorsecTier3Wiring = {}

function TestCorsecTier3Wiring:setUp() H.reset() end

-- AC-3
function TestCorsecTier3Wiring:test_survival_4_a_splits_to_the_inspect_quest_on_completion_with_the_tab_delay_plus_five()
	local q = quest(SURVIVAL)
	local rec = H.questFixture("survival", "corellia_privateer_tier3_4_a")
	local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertEquals(rec:get("triggerEvent"), "splitquest", "oracle: triggerEvent")
	lu.assertEquals(q.sideQuest, true, "survival/corellia_privateer_tier3_4_a: sideQuest")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { sideType, sideName }, "survival/corellia_privateer_tier3_4_a: split target from triggerArg")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { "inspect", "corellia_privateer_tier3_4_b" }, "split target literal")
	lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, "survival/corellia_privateer_tier3_4_a: sideQuestSplitType (success)")
	lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, "survival/corellia_privateer_tier3_4_a: sideQuestDelay = triggerDelay (absent = 0) + 5")
	lu.assertEquals(q.sideQuestDelay, 5, "literal")
end

-- AC-3 (everything else stays byte-identical)
function TestCorsecTier3Wiring:test_survival_4_a_keeps_its_data_parent_and_reward()
	local q = quest(SURVIVAL)

	lu.assertEquals(q.className, SURVIVAL, "className")
	lu.assertEquals(q.questZone, "space_endor", "questZone")
	lu.assertEquals(q.transmissionPoint, { patrolPointName = "corellia_privateer_tier3_endor_survival_1", x = 3250, z = 5631, y = 6980 }, "transmissionPoint")
	lu.assertEquals({ q.totalTransmissionTime, q.timesToUpdateProgress, q.transmissionStartDelay, q.delayToFirstAttack, q.attackPeriod, q.attackListType },
		{ 420, 2, 60, 10, 90, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL }, "timings, attackPeriod and attackListType")
	lu.assertEquals(q.attackShipLists, {
		{ "evil_raider_fighter_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3" },
		{ "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3" },
		{ "evil_raider_fighter_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3", "evil_raider_fighter_tier3" },
		{ "evil_raider_cutthroat_tier3", "evil_raider_cutthroat_tier3" },
	}, "attackShipLists")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { ASSASSINATE_4, "assassinate", "corellia_privateer_tier3_4" }, "parent")
	lu.assertEquals({ q.creditReward, q.itemReward }, { 0, {} }, "reward")
	lu.assertNil(rawget(q, "sideFailQuestType"), "no failure split type")
	lu.assertNil(rawget(q, "sideFailQuestName"), "no failure split name")
end

-- AC-3, I-3, I-4 (tab triggerEvent none)
function TestCorsecTier3Wiring:test_assassinate_3d_has_no_side_quest_and_none_of_the_stray_tier_4_fields()
	local q = quest(ASSASSINATE_3D)

	lu.assertEquals(H.questFixture("assassinate", "corellia_privateer_tier3_3d"):get("triggerEvent"), "none", "oracle: triggerEvent")
	lu.assertEquals(q.sideQuest, false, "assassinate/corellia_privateer_tier3_3d: sideQuest")
	lu.assertEquals(q.sideQuestType, "", "sideQuestType")

	for _, field in ipairs({ "sideQuestName", "sideFailQuestType", "sideFailQuestName" }) do
		local v = rawget(q, field)

		lu.assertTrue(v == nil or v == "", "assassinate/corellia_privateer_tier3_3d: " .. field .. " must be nil or \"\", got " .. tostring(v))
	end

	lu.assertNil(rawget(q, "sideQuestSplitType"), "assassinate/corellia_privateer_tier3_3d: sideQuestSplitType removed")
	lu.assertNil(rawget(q, "sideQuestDelay"), "assassinate/corellia_privateer_tier3_3d: sideQuestDelay removed")
end

-- AC-3 (everything else is unchanged)
function TestCorsecTier3Wiring:test_assassinate_3d_keeps_its_data_parent_and_reward()
	local q = quest(ASSASSINATE_3D)

	lu.assertEquals(q.className, ASSASSINATE_3D, "className")
	lu.assertEquals(q.questZone, "space_dantooine", "questZone")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { "patrol_corellia_privateer_tier3_3_a", "patrol", "corellia_privateer_tier3_3_a" }, "parent")
	lu.assertEquals({ q.creditReward, q.itemReward }, { 0, {} }, "reward")
	lu.assertEquals({ q.arrivalDelay, q.failTimer }, { 7, 20 }, "arrivalDelay and failTimer")
	lu.assertEquals(q.assassinateSpawns, {
		target = "blacksun_gunship_tier2",
		escorts = { "blacksun_aggressor_tier3", "blacksun_aggressor_tier4", "blacksun_marauder_tier3", "blacksun_marauder_tier3" },
	}, "assassinateSpawns")
	lu.assertEquals(q.targetPatrols, {
		{ patrolPointName = "corellia_privateer_tier3_patrol_4", x = -4468, z = -3583, y = 624 },
		{ patrolPointName = "corellia_privateer_tier3_patrol_1", x = -4204, z = -3241, y = 3652 },
		{ patrolPointName = "corellia_privateer_tier3_patrol_2", x = -4773, z = -3338, y = 2891 },
	}, "targetPatrols")
end

-- AC-3, I-3: the fixture decides whether a table splits; the split target's parent is the table itself
function TestCorsecTier3Wiring:test_side_quest_is_true_exactly_when_the_tab_splits_and_the_target_names_its_parent()
	local rows = {
		{ ASSASSINATE_4, "assassinate", "corellia_privateer_tier3_4", false },
		{ SURVIVAL, "survival", "corellia_privateer_tier3_4_a", true },
		{ INSPECT, "inspect", "corellia_privateer_tier3_4_b", true },
		{ DELIVERY, "delivery_no_pickup", "corellia_privateer_tier3_4_c", true },
		{ ASSASSINATE_3D, "assassinate", "corellia_privateer_tier3_3d", true },
	}

	for _, row in ipairs(rows) do
		local global, questType, name = row[1], row[2], row[3]
		local q = quest(global)
		local rec = H.questFixture(questType, name)
		local label = questType .. "/" .. name

		if rec:get("triggerEvent") == "splitquest" then
			local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local target = rawget(_G, sideType .. "_" .. sideName)

			lu.assertEquals(q.sideQuest, true, label .. ": sideQuest")
			lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, sideType .. "_" .. sideName, label .. ": split target")
			lu.assertNotNil(target, label .. ": split target global " .. sideType .. "_" .. sideName .. " exists")
			lu.assertEquals(target.parentQuest, global, label .. ": the split target's parentQuest is this table")
		else
			lu.assertNotEquals(q.sideQuest, true, label .. ": sideQuest must not be true when triggerEvent is " .. tostring(rec:get("triggerEvent")))

			for _, field in ipairs({ "sideQuestName", "sideFailQuestType", "sideFailQuestName" }) do
				local v = q[field]

				lu.assertTrue(v == nil or v == "", label .. ": " .. field .. " must be unset, got " .. tostring(v))
			end
		end
	end
end

-- AC-3
function TestCorsecTier3Wiring:test_the_mission_4_chain_is_the_four_members_in_order()
	local chain = SpaceHelpers:getSpaceQuestChain(ASSASSINATE_4)
	local globals = {}

	for i, e in ipairs(chain) do
		globals[i] = e.global
	end

	lu.assertEquals(globals, { ASSASSINATE_4, SURVIVAL, INSPECT, DELIVERY }, "getSpaceQuestChain(" .. ASSASSINATE_4 .. ")")
end

-- AC-3
function TestCorsecTier3Wiring:test_the_mission_3_chain_ends_at_3d_with_no_tier_4_member()
	local chain = SpaceHelpers:getSpaceQuestChain("delivery_corellia_privateer_tier3_3")
	local globals = {}

	for i, e in ipairs(chain) do
		globals[i] = e.global
	end

	lu.assertEquals(globals, { "delivery_corellia_privateer_tier3_3", "escort_corellia_privateer_tier3_3_pre_a", "patrol_corellia_privateer_tier3_3_a", ASSASSINATE_3D }, "getSpaceQuestChain(delivery_corellia_privateer_tier3_3)")
end

-- AC-3: pre-feature wiring of every other CorSec table, pinned as literals
-- { sideQuest, sideQuestType, sideQuestName, sideFailQuestType, sideFailQuestName, sideQuestSplitType, sideQuestDelay, parentQuest }
-- (effective values, class defaults included) as the tables were at 83e2437024.
local PRE_FEATURE_WIRING = {
	assassinate_corellia_privateer_tier1_4a = { false, "", "", "", "", 0, 2, "" },
	assassinate_corellia_privateer_tier2_4a = { false, "", "", "", "", 0, 2, "" },
	assassinate_corellia_privateer_tier3_4 = { true, "survival", "corellia_privateer_tier3_4_a", "", "", 1, 1, "" },
	assassinate_corellia_privateer_tier4_1b = { true, "destroy_surpriseattack", "corellia_privateer_tier4_1c", "", "", 1, 2, "patrol_corellia_privateer_tier4_1a" },
	assassinate_corellia_privateer_tier4_2a = { true, "escort", "corellia_privateer_tier4_2b", "", "", 1, 2, "" },
	assassinate_corellia_privateer_tier4_3b = { true, "space_battle", "corellia_privateer_tier4_3c_win", "space_battle", "corellia_privateer_tier4_3c_lose", 3, 1, "space_battle_corellia_privateer_tier4_3a" },
	assassinate_corellia_privateer_tier4_4a = { true, "assassinate", "corellia_privateer_tier4_4b", "", "", 1, 1, "" },
	assassinate_corellia_privateer_tier4_4b = { true, "destroy_surpriseattack", "corellia_privateer_tier4_4c", "", "", 1, 1, "assassinate_corellia_privateer_tier4_4a" },
	assassinate_corellia_privateer_tier4_4d = { false, "", "", "", "", 0, 1, "" },
	delivery_corellia_privateer_tier3_2_b = { true, "destroy_surpriseattack", "corellia_privateer_tier3_2_c", "", "", 1, 5, "survival_corellia_privateer_tier3_2_a" },
	delivery_corellia_privateer_tier3_3 = { true, "escort", "corellia_privateer_tier3_3_pre_a", "", "", 1, 2, "" },
	destroy_corellia_privateer_13a = { false, "", "", "", "", 0, 0, "" },
	destroy_corellia_privateer_2 = { false, "", "", "", "", 0, 0, "" },
	destroy_duty_corellia_privateer_11 = { false, "", "", "", "", 0, 0, "" },
	destroy_duty_corellia_privateer_6 = { false, "", "", "", "", 0, 0, "" },
	destroy_duty_corellia_privateer_9 = { false, "", "", "", "", 0, 0, "" },
	destroy_duty_corellia_privateer_tier4_1 = { false, "", "", "", "", 0, 0, "" },
	destroy_surpriseattack_corellia_privateer_1 = { false, "", "", "", "", 0, 2, "patrol_corellia_privateer_1" },
	destroy_surpriseattack_corellia_privateer_tier3_1_c = { false, "", "", "", "", 0, 2, "escort_corellia_privateer_tier3_1_b" },
	destroy_surpriseattack_corellia_privateer_tier3_2_c = { false, "", "", "", "", 0, 2, "delivery_corellia_privateer_tier3_2_b" },
	destroy_surpriseattack_corellia_privateer_tier4_1c = { false, "", "", "", "", 0, 2, "assassinate_corellia_privateer_tier4_1b" },
	destroy_surpriseattack_corellia_privateer_tier4_4c = { true, "assassinate", "corellia_privateer_tier4_4d", "", "", 1, 1, "assassinate_corellia_privateer_tier4_4b" },
	escort_corellia_privateer_14 = { false, "", "", "", "", 0, 2, "" },
	escort_corellia_privateer_3 = { false, "", "", "", "", 0, 2, "patrol_corellia_privateer_3" },
	escort_corellia_privateer_tier3_1_b = { true, "destroy_surpriseattack", "corellia_privateer_tier3_1_c", "", "", 1, 5, "patrol_corellia_privateer_tier3_1_a" },
	escort_corellia_privateer_tier3_3_pre_a = { true, "patrol", "corellia_privateer_tier3_3_a", "", "", 1, 1, "delivery_corellia_privateer_tier3_3" },
	escort_corellia_privateer_tier4_2b = { false, "", "", "", "", 0, 5, "assassinate_corellia_privateer_tier4_2a" },
	escort_duty_corellia_privateer_10 = { false, "", "", "", "", 0, 2, "" },
	escort_duty_corellia_privateer_7 = { false, "", "", "", "", 0, 2, "" },
	escort_duty_corellia_privateer_tier4_1 = { false, "", "", "", "", 0, 2, "" },
	inspect_corellia_privateer_15 = { false, "", "", "", "", 0, 2, "" },
	inspect_corellia_privateer_tier3_2 = { true, "survival", "corellia_privateer_tier3_2_a", "", "", 1, 2, "" },
	patrol_corellia_privateer_1 = { true, "destroy_surpriseattack", "corellia_privateer_1", "", "", 4, 20, "" },
	patrol_corellia_privateer_3 = { true, "escort", "corellia_privateer_3", "", "", 4, 20, "" },
	patrol_corellia_privateer_tier3_1_a = { true, "escort", "corellia_privateer_tier3_1_b", "", "", 4, 4, "recovery_corellia_privateer_tier3_1" },
	patrol_corellia_privateer_tier3_3_a = { true, "assassinate", "corellia_privateer_tier3_3d", "", "", 4, 4, "escort_corellia_privateer_tier3_3_pre_a" },
	patrol_corellia_privateer_tier4_1a = { true, "assassinate", "corellia_privateer_tier4_1b", "", "", 4, 11, "" },
	recovery_corellia_privateer_tier3_1 = { true, "patrol", "corellia_privateer_tier3_1_a", "", "", 1, 2, "" },
	recovery_duty_corellia_privateer_12 = { false, "", "", "", "", 0, 0, "" },
	recovery_duty_corellia_privateer_tier4_1 = { false, "", "", "", "", 0, 2, "" },
	rescue_duty_corellia_privateer_tier4_1 = { false, "", "", "", "", 0, 2, "" },
	space_battle_corellia_privateer_tier4_3a = { true, "assassinate", "corellia_privateer_tier4_3b", "", "", 1, 1, "" },
	space_battle_corellia_privateer_tier4_3c_lose = { false, "", "", "", "", 0, 1, "assassinate_corellia_privateer_tier4_3b" },
	space_battle_corellia_privateer_tier4_3c_win = { false, "", "", "", "", 0, 1, "assassinate_corellia_privateer_tier4_3b" },
	survival_corellia_privateer_tier3_2_a = { true, "delivery", "corellia_privateer_tier3_2_b", "", "", 1, 4, "inspect_corellia_privateer_tier3_2" },
}

-- AC-3
function TestCorsecTier3Wiring:test_the_wiring_of_every_other_corsec_table_is_unchanged()
	local names = {}

	for n in pairs(PRE_FEATURE_WIRING) do
		names[#names + 1] = n
	end

	table.sort(names)
	lu.assertEquals(#names, 45, "setup: pinned CorSec tables")

	for _, n in ipairs(names) do
		local q = quest(n, "pre-existing CorSec table " .. n)

		lu.assertEquals({ q.sideQuest and true or false, q.sideQuestType or "", q.sideQuestName or "", q.sideFailQuestType or "", q.sideFailQuestName or "", q.sideQuestSplitType, q.sideQuestDelay, q.parentQuest or "" },
			PRE_FEATURE_WIRING[n], n .. ": {sideQuest, type, name, failType, failName, splitType, delay, parent}")
	end
end

-- AC-3: no CorSec table beyond the pinned ones and the slice's own appeared
function TestCorsecTier3Wiring:test_no_other_corsec_table_appeared()
	local known = {
		[SURVIVAL] = true, [ASSASSINATE_3D] = true, [INSPECT] = true, [DELIVERY] = true,
	}
	local extra = {}

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if n:find("corellia_privateer", 1, true) and q.questName ~= "" and not known[n] and PRE_FEATURE_WIRING[n] == nil then
			extra[#extra + 1] = n
		end
	end

	lu.assertEquals(extra, {}, "CorSec quest globals that are neither pinned nor part of the slice")
end

---------------------------------------------------------------------------------------------
-- AC-4: cargo on the tyrant template
---------------------------------------------------------------------------------------------

local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")
	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

TestCorsecTier3Cargo = {}

function TestCorsecTier3Cargo:setUp() H.reset() end

-- AC-4
function TestCorsecTier3Cargo:test_the_tyrant_template_declares_the_swg_cargo_string()
	local rec = H.fixture("space_mobile/space_mobile.evil_raider_tyrant_tier3.tab").records[1]

	lu.assertEquals(rec:get("strIndex"), "evil_raider_tyrant_tier3", "oracle: the excerpt row is the tyrant")
	lu.assertEquals(rec:get("cargo"), "stolen_data", "oracle: space_mobile.tab cargo column")
	lu.assertEquals(templateSource("evil_raider_tyrant_tier3"):match('cargoString%s*=%s*"(.-)"'), rec:get("cargo"), "ship_mobile/ships/evil_raider_tyrant_tier3.lua: cargoString")
end

-- AC-4
function TestCorsecTier3Cargo:test_the_cargo_string_is_the_single_transferable_row_of_stolen_data()
	local rows = H.fixture("spacequest/inspect_cargo/stolen_data.tab").records

	lu.assertEquals(#rows, 1, "stolen_data.tab rows")
	lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { "stolen_data", 1 }, "stolen_data.tab row")

	local src = templateSource("evil_raider_tyrant_tier3")

	lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), "stolen_data", "questLoot names the cargo table")
	lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), rows[1]:get("name"), "cargoString is that row")
end

-- AC-4 (no other field changed)
function TestCorsecTier3Cargo:test_no_other_field_of_the_tyrant_template_changed()
	local t = H.shipTemplate("evil_raider_tyrant_tier3")

	lu.assertNotNil(t, "ship_mobile/ships/evil_raider_tyrant_tier3.lua registers a template")
	lu.assertEquals(t, {
		template = "hutt_heavy_s01_tier3", pilotTemplate = "heavy_fighter_tier3", shipType = "fighter",
		experience = 1664, lootChance = 0.195, lootRolls = 1, lootTable = "space_pirate_tier3", minCredits = 170, maxCredits = 382,
		aggressive = 1, spaceFaction = "pirate", alliedFactions = { "pirate" },
		enemyFactions = { "imperial", "rebel", "civilian", "merchant", "hutt", "valarian", "rsf", "corsec" },
		color1 = 23, color2 = 56, texture = 3, questLoot = "stolen_data", appearance = "generic_pirate",
		tauntType = "generic", tauntAttackChance = 0.1, tauntDefendChance = 0.05, tauntDieChance = 0.1,
		pvpBitmask = ATTACKABLE, shipBitmask = NONE, optionsBitmask = AIENABLED, customShipAiMap = "",
		conversationTemplate = "", conversationMobile = "", conversationMessage = "",
		cargoString = "stolen_data",
	}, "evil_raider_tyrant_tier3 template fields (the pre-feature fields plus cargoString)")
end

-- AC-4, I-3 (inspect-cargo invariant): every ship the new inspect quest lists carries the quest cargo
function TestCorsecTier3Cargo:test_every_ship_of_the_new_inspect_quest_carries_the_quest_cargo()
	local q = quest(INSPECT)

	lu.assertEquals(type(q.shipList), "table", "shipList must be a table")
	lu.assertTrue(#q.shipList > 0, "shipList is not empty")

	for _, ship in ipairs(q.shipList) do
		lu.assertEquals(templateSource(ship):match('cargoString%s*=%s*"(.-)"'), q.cargo, "ship_mobile/ships/" .. ship .. ".lua: cargoString must equal the quest cargo")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9 / I-6: Ramna mission rewards
---------------------------------------------------------------------------------------------

-- { head global, SWG quest type, SWG quest name, item } from corellia_privateer_tier3.java:231-257
local REWARDS = {
	{ "recovery_corellia_privateer_tier3_1", "recovery", "corellia_privateer_tier3_1", "object/tangible/ship/components/reactor/rct_mission_reward_neutral_subpro_military.iff" },
	{ "inspect_corellia_privateer_tier3_2", "inspect", "corellia_privateer_tier3_2", "object/tangible/ship/components/engine/eng_mission_reward_neutral_mandal_inferno.iff" },
	{ "delivery_corellia_privateer_tier3_3", "delivery", "corellia_privateer_tier3_3", "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff" },
	{ ASSASSINATE_4, "assassinate", "corellia_privateer_tier3_4", "object/tangible/ship/components/armor/arm_mission_reward_neutral_kse_handcrafted.iff" },
}

local RAMNA_CHAIN = {
	"recovery_corellia_privateer_tier3_1", "patrol_corellia_privateer_tier3_1_a", "escort_corellia_privateer_tier3_1_b", "destroy_surpriseattack_corellia_privateer_tier3_1_c",
	"inspect_corellia_privateer_tier3_2", "survival_corellia_privateer_tier3_2_a", "delivery_corellia_privateer_tier3_2_b", "destroy_surpriseattack_corellia_privateer_tier3_2_c",
	"delivery_corellia_privateer_tier3_3", "escort_corellia_privateer_tier3_3_pre_a", "patrol_corellia_privateer_tier3_3_a", ASSASSINATE_3D,
	ASSASSINATE_4, SURVIVAL, INSPECT, DELIVERY,
}

TestCorsecTier3Rewards = {}

function TestCorsecTier3Rewards:setUp() H.reset() end

-- AC-9 (the oracle: the SWG java gives each head 25000 credits and one component)
function TestCorsecTier3Rewards:test_the_swg_trainer_script_gives_25000_credits_and_the_component_per_mission()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_privateer_tier3.java")

	for _, row in ipairs(REWARDS) do
		local line = string.format('space_quest.giveReward(player, "%s", "%s", 25000, "%s");', row[2], row[3], row[4])

		lu.assertNotNil(java:find(line, 1, true), "corellia_privateer_tier3.java must contain " .. line)
	end
end

-- AC-9
function TestCorsecTier3Rewards:test_each_head_carries_25000_credits_and_its_component()
	for _, row in ipairs(REWARDS) do
		local q = quest(row[1])

		lu.assertEquals(q.creditReward, 25000, row[1] .. ": creditReward")
		lu.assertEquals(q.itemReward, { { species = { -1 }, item = row[4] } }, row[1] .. ": itemReward")
	end
end

-- AC-9
function TestCorsecTier3Rewards:test_the_reward_components_have_server_templates()
	for _, row in ipairs(REWARDS) do
		local path = H.SCRIPTS .. row[4]:gsub("%.iff$", ".lua")

		lu.assertTrue(H.fileExists(path), row[1] .. ": server template " .. path .. " must exist")
	end
end

-- AC-9
function TestCorsecTier3Rewards:test_reward_player_pays_25000_credits_and_the_listed_item_for_each_head()
	for _, row in ipairs(REWARDS) do
		H.reset()

		local player = H.newPlayer({ name = "Ace" })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local items = H.spyOn(SpaceHelpers, "spaceItemReward")

		quest(row[1]):rewardPlayer(player)

		lu.assertEquals(#credits, 1, row[1] .. ": spaceCreditReward calls")
		lu.assertIs(credits[1].args[1], player, row[1] .. ": credits go to the player")
		lu.assertEquals(credits[1].args[2], 25000, row[1] .. ": credit amount")
		lu.assertEquals(#items, 1, row[1] .. ": spaceItemReward calls")
		lu.assertIs(items[1].args[1], player, row[1] .. ": item goes to the player")
		lu.assertEquals(items[1].args[2], row[4], row[1] .. ": item path")
	end
end

-- AC-9, I-6
function TestCorsecTier3Rewards:test_only_the_four_heads_pay_among_the_sixteen_ramna_chain_tables()
	local heads = {}

	for _, row in ipairs(REWARDS) do
		heads[row[1]] = true
	end

	lu.assertEquals(#RAMNA_CHAIN, 16, "setup: the Ramna chain tables")

	for _, n in ipairs(RAMNA_CHAIN) do
		local q = quest(n)

		if not heads[n] then
			lu.assertEquals(q.creditReward, 0, n .. ": creditReward must stay 0")
			lu.assertEquals(q.itemReward, {}, n .. ": itemReward must stay empty")
		end
	end
end
