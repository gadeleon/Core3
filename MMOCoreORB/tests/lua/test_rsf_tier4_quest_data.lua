-- RSF Squadron tier 4 (Admiral Diness Imler): quest registry, wiring, rewards and payload
-- conformance against SWG-Source.
-- Spec: .claude/work/rsf-tier4/01-spec.md (AC-9, AC-10, invariants I-2, I-3, I-4, Data mapping).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/, the cut-down buildout
-- extract and the patrol point / spawner files, never the Core3 tables under test. The few values
-- spelled out in the spec tables are repeated as anchors ("the fixtures carry the values the spec
-- lists") so a misparsed fixture cannot make a wrong table look right.
--
-- Q2 (user answer): the legacy escort and duty types are used as-is, so their tables are mapped with
-- the Core3 field names of those types (escortShips/escortPoints/attackShips/tauntData, ...).
-- Q3 (user answer): surprise attacks spawn SWG's runtime result: the loop of destroy_surpriseattack.java
-- 78-121 is replayed below.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier4_data")
local B = require("battle_scenario")

H.loadSquadron("RsfSquadronScreenplay")

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
local ATTACK_LIST_TYPE = { sequential = 0, random = 1 }

-- The 18 SWG-Source tables: { dir, name, key }. key is the D.QUEST short key, or "m2cUnreachable".
local ALL = {
	{ "escort", "naboo_privateer_tier4_1a", "m1" },
	{ "escort", "naboo_privateer_tier4_1b", "m1b" },
	{ "inspect", "naboo_privateer_tier4_2a", "m2" },
	{ "destroy_surpriseattack", "naboo_privateer_tier4_2b", "m2b" },
	{ "patrol", "naboo_privateer_tier4_2c", "m2c" },
	{ "destroy_surpriseattack", "naboo_privateer_tier4_2c", "m2cUnreachable" },
	{ "destroy_surpriseattack", "naboo_privateer_tier4_2d", "m2d" },
	{ "delivery", "naboo_privateer_tier4_3a", "m3" },
	{ "patrol", "naboo_privateer_tier4_3b", "m3b" },
	{ "survival", "naboo_privateer_tier4_3c", "m3c" },
	{ "space_battle", "naboo_privateer_tier4_4a", "m4" },
	{ "escort", "naboo_privateer_tier4_4b", "m4b" },
	{ "space_battle", "naboo_privateer_tier4_4c_win", "m4cw" },
	{ "space_battle", "naboo_privateer_tier4_4c_lose", "m4cl" },
	{ "destroy_duty", "naboo_privateer_tier4_1", "dDestroy" },
	{ "escort_duty", "naboo_privateer_tier4_1", "dEscort" },
	{ "recovery_duty", "naboo_privateer_tier4_1", "dRecovery" },
	{ "rescue_duty", "naboo_privateer_tier4_1", "dRescue" },
}

local CLASS = {
	escort = "SpaceEscortScreenplay", inspect = "SpaceInspectScreenplay", destroy_surpriseattack = "SpaceSurpriseAttackScreenplay",
	patrol = "SpacePatrolScreenplay", delivery = "SpaceDeliveryScreenplay", survival = "SpaceSurvivalScreenplay",
	space_battle = "SpaceBattleScreenplay", destroy_duty = "SpaceDutyDestroyScreenplay", escort_duty = "SpaceDutyEscortScreenplay",
	recovery_duty = "SpaceDutyRecoveryScreenplay", rescue_duty = "SpaceDutyRescueScreenplay",
}

-- Parent quest (the one that triggers it) per spec "Split wiring"; nil = none.
local PARENT = {
	m1b = "m1", m2b = "m2", m2c = "m2b", m2d = "m2c", m3b = "m3", m3c = "m3b", m4b = "m4", m4cw = "m4b", m4cl = "m4b",
}

local MAINS = { "m1", "m2", "m3", "m4" }

local function labelOf(row) return row[1] .. "/" .. row[2] end

local function globalOf(row) return row[1] .. "_" .. row[2] end

local function quest(row)
	return H.expectGlobal(globalOf(row), "tier 4 quest table for " .. labelOf(row))
end

local function rowsOf(dirs)
	local out = {}

	for _, row in ipairs(ALL) do
		if dirs[row[1]] then
			out[#out + 1] = row
		end
	end

	return out
end

local function fixture(row) return H.questFixture(row[1], row[2]) end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
end

-- Points of a column of "zone:name" cells -> list of { zone, name, x, z, y }.
local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		out[i] = { zone = zone, name = name, x = p.x, z = p.z, y = p.y }
	end

	return out
end

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")
	f:close()
	return text
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	table.sort(keys)
	return keys
end

TestRsfTier4Registry = {}

function TestRsfTier4Registry:setUp() H.reset() end

-- AC-9
function TestRsfTier4Registry:test_each_of_the_18_fixtures_has_a_registered_global_of_the_right_class()
	for _, row in ipairs(ALL) do
		local q = quest(row)
		local label = labelOf(row)
		local registration = H.registered(globalOf(row))

		lu.assertNotNil(registration, label .. ": registerScreenPlay(" .. globalOf(row) .. ", true) was not called")
		lu.assertTrue(registration.start, label .. ": registered with start = true")
		lu.assertEquals(q.className, globalOf(row), label .. ": className")
		lu.assertEquals(q.questType, row[1], label .. ": questType")
		lu.assertEquals(q.questName, row[2], label .. ": questName")
		lu.assertEquals(q.questZone, fixture(row):get("questZone"), label .. ": questZone")
		lu.assertEquals(getmetatable(q), rawget(_G, CLASS[row[1]]), label .. ": class (metatable) is " .. CLASS[row[1]])
	end
end

-- AC-9, I-2
function TestRsfTier4Registry:test_tier4_constants_hold_the_real_quest_types_and_names()
	for _, constant in ipairs(sortedKeys(D.CONSTANTS)) do
		local key = D.CONSTANTS[constant]
		local value = RsfSquadronScreenplay[constant]

		lu.assertNotNil(value, "RsfSquadronScreenplay." .. constant .. " is defined")
		lu.assertEquals(value.type, D.QUEST[key][1], constant .. ": type")
		lu.assertEquals(value.name, D.QUEST[key][2], constant .. ": name")
	end
end

-- AC-9, I-2
function TestRsfTier4Registry:test_every_tier4_constant_names_a_registered_quest_global_with_matching_identity()
	local seen = 0

	for _, constant in ipairs(sortedKeys(RsfSquadronScreenplay)) do
		if type(constant) == "string" and constant:match("^TIER4_QUEST_STRING_") then
			local value = RsfSquadronScreenplay[constant]
			local name = value.type .. "_" .. value.name
			local global = rawget(_G, name)

			seen = seen + 1

			lu.assertNotNil(global, constant .. ": global " .. name .. " exists")
			lu.assertEquals(global.questType, value.type, constant .. ": questType of global")
			lu.assertEquals(global.questName, value.name, constant .. ": questName of global")
			lu.assertEquals(global.className, name, constant .. ": className of global")
			lu.assertNotNil(H.registered(name), constant .. ": " .. name .. " is registered")
		end
	end

	lu.assertEquals(seen, 17, "number of TIER4_QUEST_STRING_* constants")
end

-- AC-9
function TestRsfTier4Registry:test_the_unreachable_surprise_attack_2c_exists_but_has_no_constant()
	local global = "destroy_surpriseattack_naboo_privateer_tier4_2c"

	lu.assertNotNil(rawget(_G, global), global .. " is ported as data (D-6)")

	for _, constant in ipairs(sortedKeys(RsfSquadronScreenplay)) do
		local value = RsfSquadronScreenplay[constant]

		if type(constant) == "string" and constant:match("^TIER4_QUEST_STRING_") then
			lu.assertFalse(value.type == "destroy_surpriseattack" and value.name == "naboo_privateer_tier4_2c", constant .. " must not name the unreachable surprise attack 2c")
		end
	end
end

-- AC-9
function TestRsfTier4Registry:test_no_tier4_table_sets_the_unread_second_side_quest_fields()
	for _, row in ipairs(ALL) do
		local q = quest(row)

		lu.assertNil(rawget(q, "sideQuestType2"), labelOf(row) .. ": sideQuestType2 (no quest type reads it)")
		lu.assertNil(rawget(q, "sideQuestName2"), labelOf(row) .. ": sideQuestName2 (no quest type reads it)")
	end
end

TestRsfTier4Wiring = {}

function TestRsfTier4Wiring:setUp() H.reset() end

-- AC-9: split wiring derived from each fixture by the spec's Data mapping rules.
function TestRsfTier4Wiring:test_split_wiring_equals_the_fixture_by_the_spec_rules()
	for _, row in ipairs(ALL) do
		local q = quest(row)
		local rec = fixture(row)
		local label = labelOf(row)
		local event = rec:get("triggerEvent")

		if event == "splitquest" then
			local condition = rec:get("triggerSplitCondition")
			local delay = rec:num("triggerDelay") or 0
			local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

			lu.assertTrue(q.sideQuest, label .. ": sideQuest (triggerEvent=splitquest)")
			lu.assertEquals(q.sideQuestType, sideType, label .. ": sideQuestType (triggerArg)")
			lu.assertEquals(q.sideQuestName, sideName, label .. ": sideQuestName (triggerArg)")

			if condition == "triggerOn" then
				lu.assertEquals(q.sideQuestSplitType, SPLIT.PATROL_POINT, label .. ": sideQuestSplitType (triggerOn)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), label .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, label .. ": sideQuestDelay (triggerDelay, triggerOn split)")
			else
				local expectedType = { success = SPLIT.COMPLETION, both = SPLIT.BIDIRECTIONAL }

				lu.assertNotNil(expectedType[condition], label .. ": fixture triggerSplitCondition '" .. tostring(condition) .. "' is not mapped by this test")
				lu.assertEquals(q.sideQuestSplitType, expectedType[condition], label .. ": sideQuestSplitType (triggerSplitCondition=" .. condition .. ")")
				lu.assertEquals(q.sideQuestDelay, delay + 5, label .. ": sideQuestDelay (triggerDelay + 5, success/failure split)")
			end

			local arg2 = rec:get("triggerArg2")

			if arg2 ~= nil then
				local failType, failName = H.Tab.splitQuestRef(arg2)

				lu.assertEquals(q.sideFailQuestType, failType, label .. ": sideFailQuestType (triggerArg2)")
				lu.assertEquals(q.sideFailQuestName, failName, label .. ": sideFailQuestName (triggerArg2)")
			end
		elseif row[1] == "destroy_duty" or row[1] == "escort_duty" or row[1] == "recovery_duty" or row[1] == "rescue_duty" then
			lu.assertFalse(q.sideQuest and true or false, label .. ": a duty has no split")
		else
			lu.assertEquals(event, "none", label .. ": fixture triggerEvent")
			lu.assertFalse(q.sideQuest and true or false, label .. ": sideQuest must be false (triggerEvent=none)")
			lu.assertEquals(q.sideQuestSplitType, SPLIT.NONE, label .. ": sideQuestSplitType must be NONE")
		end
	end
end

-- AC-9, spec "Split wiring" table repeated as an anchor for the delays and targets.
function TestRsfTier4Wiring:test_the_split_table_in_the_spec_holds()
	local expected = {
		m1 = { SPLIT.COMPLETION, "escort_naboo_privateer_tier4_1b", nil, 15 },
		m2 = { SPLIT.COMPLETION, "destroy_surpriseattack_naboo_privateer_tier4_2b", nil, 16 },
		m2b = { SPLIT.COMPLETION, "patrol_naboo_privateer_tier4_2c", nil, 5 },
		m2cUnreachable = { SPLIT.COMPLETION, "patrol_naboo_privateer_tier4_2c", nil, 5 },
		m2c = { SPLIT.PATROL_POINT, "destroy_surpriseattack_naboo_privateer_tier4_2d", nil, 13 },
		m3 = { SPLIT.COMPLETION, "patrol_naboo_privateer_tier4_3b", nil, 14 },
		m3b = { SPLIT.PATROL_POINT, "survival_naboo_privateer_tier4_3c", nil, 13 },
		m4 = { SPLIT.COMPLETION, "escort_naboo_privateer_tier4_4b", nil, 5 },
		m4b = { SPLIT.BIDIRECTIONAL, "space_battle_naboo_privateer_tier4_4c_win", "space_battle_naboo_privateer_tier4_4c_lose", 5 },
	}

	local byKey = {}

	for _, row in ipairs(ALL) do
		byKey[row[3]] = row
	end

	for _, key in ipairs(sortedKeys(expected)) do
		local row = byKey[key]
		local q = quest(row)
		local want = expected[key]

		lu.assertTrue(q.sideQuest, labelOf(row) .. ": sideQuest")
		lu.assertEquals(q.sideQuestSplitType, want[1], labelOf(row) .. ": sideQuestSplitType")
		lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, want[2], labelOf(row) .. ": success leads to")
		lu.assertEquals(q.sideQuestDelay, want[4], labelOf(row) .. ": sideQuestDelay")

		if want[3] ~= nil then
			lu.assertEquals(q.sideFailQuestType .. "_" .. q.sideFailQuestName, want[3], labelOf(row) .. ": failure leads to")
		end
	end

	local patrol2c = quest(byKey.m2c)
	local patrol3b = quest(byKey.m3b)

	lu.assertEquals(patrol2c.sideQuestPatrolStart, 3, "patrol/naboo_privateer_tier4_2c: sideQuestPatrolStart")
	lu.assertEquals(patrol3b.sideQuestPatrolStart, 3, "patrol/naboo_privateer_tier4_3b: sideQuestPatrolStart")
end

-- AC-9
function TestRsfTier4Wiring:test_parent_quest_fields_name_the_quest_that_triggers_each_table()
	for _, row in ipairs(ALL) do
		local q = quest(row)
		local parentKey = PARENT[row[3]]
		local label = labelOf(row)

		if parentKey == nil then
			lu.assertEquals(q.parentQuest or "", "", label .. ": parentQuest (none)")
			lu.assertEquals(q.parentQuestType or "", "", label .. ": parentQuestType (none)")
			lu.assertEquals(q.parentQuestName or "", "", label .. ": parentQuestName (none)")
		else
			local parent = D.QUEST[parentKey]

			lu.assertEquals(q.parentQuest, parent[1] .. "_" .. parent[2], label .. ": parentQuest")
			lu.assertEquals(q.parentQuestType, parent[1], label .. ": parentQuestType")
			lu.assertEquals(q.parentQuestName, parent[2], label .. ": parentQuestName")
		end
	end
end

-- AC-9
function TestRsfTier4Wiring:test_the_four_main_tables_carry_10000_credits_and_the_swg_reward_item_and_the_rest_carry_none()
	local base = "object/tangible/ship/components/"
	local items = {
		m1 = base .. "booster/bst_mission_reward_neutral_mandal_q_series.iff", -- java 336-342
		m2 = base .. "weapon/wpn_mission_reward_neutral_borstel_disruptor.iff", -- java 343-349
		m3 = base .. "shield_generator/shd_mission_reward_neutral_armek_plasma_web.iff", -- java 350-356
		m4 = base .. "engine/eng_mission_reward_neutral_haor_chall_military.iff", -- java 357-363
	}

	local isMain = {}

	for _, key in ipairs(MAINS) do
		isMain[key] = true
	end

	for _, row in ipairs(ALL) do
		local q = quest(row)
		local key = row[3]
		local isStory = not (row[1]:match("_duty$"))

		if isMain[key] then
			lu.assertEquals(q.creditReward, 10000, labelOf(row) .. ": creditReward")
			lu.assertEquals(q.itemReward, { { species = { -1 }, item = items[key] } }, labelOf(row) .. ": itemReward")
		elseif isStory then
			lu.assertEquals(q.creditReward, 0, labelOf(row) .. ": creditReward (not a main quest)")
			lu.assertEquals(#(q.itemReward or {}), 0, labelOf(row) .. ": itemReward entries (not a main quest)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: payload conformance
---------------------------------------------------------------------------------------------

TestRsfTier4Payload = {}

function TestRsfTier4Payload:setUp() H.reset() end

-- AC-10: the fixtures carry the values the spec tables list.
function TestRsfTier4Payload:test_the_fixtures_carry_the_values_the_spec_tables_list()
	local function fx(dir, name) return H.questFixture(dir, name) end

	local e1a, e1b, e4b = fx("escort", "naboo_privateer_tier4_1a"), fx("escort", "naboo_privateer_tier4_1b"), fx("escort", "naboo_privateer_tier4_4b")

	lu.assertEquals({ e1a:get("questZone"), e1a:get("escortShipType"), e1a:num("attackPeriod"), e1a:num("numAttackShipLists"), #e1a:list("escortPath") }, { "space_endor", "rsf_scanner_tier4", 120, 3, 5 }, "escort 1a")
	lu.assertEquals({ e1b:get("questZone"), e1b:get("escortShipType"), e1b:num("attackPeriod"), e1b:num("numResponses"), #e1b:list("escortPath") }, { "space_endor", "imp_lambda_shuttle_tier4", 120, 2, 5 }, "escort 1b")
	lu.assertEquals({ e4b:get("questZone"), e4b:get("escortShipType"), e4b:num("attackPeriod"), e4b:num("numResponses"), e4b:num("numAttackShipLists") }, { "space_yavin4", "rsf_scanner_tier4", 90, 2, 4 }, "escort 4b")

	local patrol2c, patrol3b = fx("patrol", "naboo_privateer_tier4_2c"), fx("patrol", "naboo_privateer_tier4_3b")

	lu.assertEquals({ patrol2c:get("questZone"), #patrol2c:list("navPoints") }, { "space_endor", 5 }, "patrol 2c")
	lu.assertEquals({ patrol3b:get("questZone"), #patrol3b:list("navPoints") }, { "space_yavin4", 5 }, "patrol 3b")

	local delivery = fx("delivery", "naboo_privateer_tier4_3a")

	lu.assertEquals({ delivery:get("questZone"), delivery:get("pickupShip"), delivery:get("deliveryShip"), delivery:num("attackPeriod"), delivery:get("attackListType") },
		{ "space_yavin4", "imp_freighterheavy_tier4", "imp_transport_tier4", 45, "random" }, "delivery 3a")

	local survival = fx("survival", "naboo_privateer_tier4_3c")

	lu.assertEquals({ survival:num("totalTransmissionTime"), survival:num("timesToUpdateProgress"), survival:num("transmissionStartDelay"), survival:num("delayToFirstAttack"), survival:num("attackPeriod"), survival:num("numAttackShipLists") },
		{ 720, 10, 15, 35, 90, 4 }, "survival 3c")

	local duty = fx("destroy_duty", "naboo_privateer_tier4_1")

	lu.assertEquals({ duty:num("wavesPerRound"), duty:num("roundsPerLevel"), duty:num("levelsPerDuty"), duty:get("bossType"), duty:num("reward") }, { 2, 2, 4, "blacksun_ace_s04_tier4", 300 }, "destroy_duty")
end

-- AC-10 (Escort 1a, 1b, 4b; legacy type, Q2)
function TestRsfTier4Payload:test_escort_tables_map_ship_points_attack_lists_delay_and_taunt_counts()
	for _, row in ipairs(rowsOf({ escort = true })) do
		local q = quest(row)
		local rec = fixture(row)
		local label = labelOf(row)

		lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, label .. ": escortShips")

		local points = {}

		for i, value in ipairs(rec:list("escortPath")) do
			local zone, name = H.Tab.splitNavPoint(value)
			local p = point(zone, name)

			lu.assertEquals(zone, rec:get("questZone"), label .. ": escortPath[" .. i .. "] zone equals questZone")
			points[i] = { patrolPointName = name, zoneName = zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		lu.assertEquals(q.escortPoints, points, label .. ": escortPoints")
		lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips (column i = list i)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, label .. ": tauntData (max(numResponses, 1))")
	end
end

-- AC-10 (Inspect 2a)
function TestRsfTier4Payload:test_inspect_2a_maps_ships_spawner_waypoint_flag_and_cargo()
	local row = { "inspect", "naboo_privateer_tier4_2a" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)

	lu.assertEquals(q.shipList, rec:list("shipList"), label .. ": shipList")
	lu.assertEquals(q.shipList, { "freighterheavy_tier4_inspect" }, label .. ": shipList (spec)")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), label .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), label .. ": cargo")
	lu.assertEquals(q.cargo, "industrial_cargo", label .. ": cargo (spec)")

	local spawns = rec:list("validSpawns")

	lu.assertEquals(type(q.validSpawns), "table", label .. ": validSpawns is a table")
	lu.assertEquals(#q.validSpawns, #spawns, label .. ": number of validSpawns")

	for i, value in ipairs(spawns) do
		local zone, name = H.Tab.splitNavPoint(value)
		local entry = H.spawners(zone)[name]

		lu.assertNotNil(entry, label .. ": spawner " .. name .. " in " .. zone .. "_spawner.lua")
		lu.assertEquals(q.validSpawns[i].spawnName, name, label .. ": validSpawns[" .. i .. "].spawnName")
		lu.assertEquals(q.validSpawns[i].x, entry.x, label .. ": validSpawns[" .. i .. "].x")
		lu.assertEquals(q.validSpawns[i].z, entry.z, label .. ": validSpawns[" .. i .. "].z")
		lu.assertEquals(q.validSpawns[i].y, entry.y, label .. ": validSpawns[" .. i .. "].y")
	end

	lu.assertEquals({ q.validSpawns[1].x, q.validSpawns[1].z, q.validSpawns[1].y }, { 3571, -480, -2419 }, label .. ": spec spawner coordinates")
end

-- Replays SWG destroy_surpriseattack.java 78-121 on the raw .tab rows: returns the ship name of every
-- spawned ship in order. Empty int cells read 0.
local function replaySurpriseAttack(row)
	local text = readFile(H.FIXTURES .. "spacequest/" .. row[1] .. "/" .. row[2] .. ".tab")
	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		lines[#lines + 1] = line
	end

	local function cells(line)
		local out = {}

		for cell in (line .. "\t"):gmatch("(.-)\t") do
			out[#out + 1] = cell
		end

		return out
	end

	local header = cells(lines[1])
	local column = {}

	for i, name in ipairs(header) do
		column[name] = i
	end

	local ships, counts = {}, {}

	for n = 3, #lines do
		if lines[n]:match("%S") then
			local c = cells(lines[n])
			local ship, count = c[column.shipType], c[column.shipCount]

			if ship ~= nil and ship ~= "" then
				ships[#ships + 1] = ship
				counts[#ships] = tonumber(count) or 0
			end
		end
	end

	local total = 0

	for i = 1, #ships do
		total = total + counts[i]
	end

	local out = {}
	local j, k = 1, 0

	for _ = 1, total do
		assert(ships[j] ~= nil, labelOf(row) .. ": SWG loop would run past the ship list (ArrayIndexOutOfBounds)")
		out[#out + 1] = ships[j]
		k = k + 1

		if k > counts[j] then
			k = 0
			j = j + 1
		end
	end

	return out
end

-- Groups consecutive equal ship names into { count, shipName }.
local function runs(list)
	local out = {}

	for _, name in ipairs(list) do
		local last = out[#out]

		if last ~= nil and last.shipName == name then
			last.count = last.count + 1
		else
			out[#out + 1] = { count = 1, shipName = name }
		end
	end

	return out
end

-- AC-10 (Destroy surprise attack 2b, 2c, 2d; Q3)
function TestRsfTier4Payload:test_surprise_attacks_spawn_the_swg_runtime_result_of_the_spawn_loop()
	for _, row in ipairs(rowsOf({ destroy_surpriseattack = true })) do
		local q = quest(row)
		local label = labelOf(row)

		lu.assertEquals(type(q.surpriseAttackShips), "table", label .. ": surpriseAttackShips is a table")
		lu.assertEquals(q.surpriseAttackShips.zone, fixture(row):get("questZone"), label .. ": surpriseAttackShips.zone")
		lu.assertEquals(q.surpriseAttackShips.spawns, runs(replaySurpriseAttack(row)), label .. ": surpriseAttackShips.spawns (SWG loop replay)")
	end
end

-- AC-10: the replay itself against the spec table.
function TestRsfTier4Payload:test_the_spawn_loop_replay_matches_the_spec_table()
	local want = {
		naboo_privateer_tier4_2b = { { count = 5, shipName = "blacksun_vehement_tier4" } },
		naboo_privateer_tier4_2c = { { count = 5, shipName = "blacksun_vehement_tier4" } },
		naboo_privateer_tier4_2d = { { count = 7, shipName = "blacksun_fighter_s01_tier4" } },
	}

	for _, name in ipairs(sortedKeys(want)) do
		lu.assertEquals(runs(replaySurpriseAttack({ "destroy_surpriseattack", name })), want[name], "destroy_surpriseattack/" .. name .. ": replay of the SWG spawn loop")
	end
end

-- AC-10 (Patrol 2c, 3b)
function TestRsfTier4Payload:test_patrol_points_are_the_nav_points_with_patrol_numbers_and_radius_150()
	for _, row in ipairs(rowsOf({ patrol = true })) do
		local q = quest(row)
		local rec = fixture(row)
		local label = labelOf(row)
		local points = {}

		for i, p in ipairs(pointsOf(rec, "navPoints")) do
			lu.assertEquals(p.zone, rec:get("questZone"), label .. ": navPoints[" .. i .. "] zone equals questZone")
			points[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
		end

		lu.assertEquals(q.patrolPoints, points, label .. ": patrolPoints")
	end
end

-- AC-10 (Delivery 3a)
function TestRsfTier4Payload:test_delivery_3a_maps_points_ships_attack_lists_period_and_list_type()
	local row = { "delivery", "naboo_privateer_tier4_3a" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)
	local pickup, delivery = pointsOf(rec, "pickupPoint")[1], pointsOf(rec, "deliveryPoint")[1]

	lu.assertEquals(q.pickupPoint, { patrolPointName = pickup.name, x = pickup.x, z = pickup.z, y = pickup.y }, label .. ": pickupPoint")
	lu.assertEquals(q.deliveryPoint, { patrolPointName = delivery.name, x = delivery.x, z = delivery.z, y = delivery.y }, label .. ": deliveryPoint")
	lu.assertEquals({ pickup.x, pickup.z, pickup.y }, { -1306, -5141, -3812 }, label .. ": spec pickup coordinates")
	lu.assertEquals({ delivery.x, delivery.z, delivery.y }, { -3500, 0, -3500 }, label .. ": spec delivery coordinates")
	lu.assertEquals(q.pickupShip, rec:get("pickupShip"), label .. ": pickupShip")
	lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), label .. ": deliveryShip")
	lu.assertEquals(q.attackShipLists, attackLists(rec), label .. ": attackShipLists")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), label .. ": attackPeriod")
	lu.assertEquals(q.attackListType, ATTACK_LIST_TYPE[rec:get("attackListType")], label .. ": attackListType (random = 1)")
end

-- AC-10 (Survival 3c)
function TestRsfTier4Payload:test_survival_3c_maps_point_timers_attack_lists_period_and_list_type()
	local row = { "survival", "naboo_privateer_tier4_3c" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)
	local p = pointsOf(rec, "transmissionPoint")[1]

	lu.assertEquals(q.transmissionPoint, { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }, label .. ": transmissionPoint")
	lu.assertEquals({ p.x, p.z, p.y }, { -5249, 3585, -1619 }, label .. ": spec transmission coordinates")

	for _, field in ipairs({ "totalTransmissionTime", "timesToUpdateProgress", "transmissionStartDelay", "delayToFirstAttack", "attackPeriod" }) do
		lu.assertEquals(q[field], rec:num(field), label .. ": " .. field)
	end

	lu.assertEquals(q.attackShipLists, attackLists(rec), label .. ": attackShipLists")
	lu.assertEquals(q.attackListType, ATTACK_LIST_TYPE[rec:get("attackListType")], label .. ": attackListType (random = 1)")
end

-- AC-10 (Space battle 4a, 4c_win, 4c_lose)
function TestRsfTier4Payload:test_space_battle_tables_map_point_forward_axis_scalars_and_forces()
	for _, row in ipairs(rowsOf({ space_battle = true })) do
		local q = quest(row)
		local o = B.oracle(row[2])
		local label = labelOf(row)
		local bp = q.battlePoint

		lu.assertEquals(q.questZone, o.zone, label .. ": questZone")
		lu.assertEquals(q.damageMultiplier, o.damageMultiplier, label .. ": damageMultiplier")
		lu.assertEquals(q.allyArrivalDelay, o.allyDelay, label .. ": allyArrivalDelay")
		lu.assertEquals(q.enemyArrivalDelay, o.enemyDelay, label .. ": enemyArrivalDelay")
		lu.assertEquals(q.allyOriginDist, o.allyOrigin, label .. ": allyOriginDist")
		lu.assertEquals(q.enemyOriginDist, o.enemyOrigin, label .. ": enemyOriginDist")
		lu.assertEquals(q.allyArrivalDist, o.allyDist, label .. ": allyArrivalDist")
		lu.assertEquals(q.enemyArrivalDist, o.enemyDist, label .. ": enemyArrivalDist")
		lu.assertEquals(q.allyForce, o.allyForce, label .. ": allyForce")
		lu.assertEquals(q.enemyForce, o.enemyForce, label .. ": enemyForce")

		lu.assertEquals(type(bp), "table", label .. ": battlePoint must be a table")
		lu.assertEquals(o.pointZone, o.zone, label .. ": the .tab's battlePoint zone equals questZone")
		lu.assertEquals(bp.patrolPointName, o.pointName, label .. ": battlePoint.patrolPointName")
		lu.assertEquals({ bp.x, bp.z, bp.y }, { o.point.x, o.point.z, o.point.y }, label .. ": battlePoint x/z/y")
		lu.assertEquals(type(bp.forward), "table", label .. ": battlePoint.forward must be a table")
		lu.assertEquals({ bp.forward.x, bp.forward.z, bp.forward.y }, { o.forward.x, o.forward.z, o.forward.y }, label .. ": battlePoint.forward (fltKX, fltKY, fltKZ)")
		lu.assertEquals(o.useConversation, 0, label .. ": useConversation in the fixture")
		lu.assertEquals(o.convo, {}, label .. ": convo in the fixture")
	end
end

-- AC-10: the battle oracle against the spec table.
function TestRsfTier4Payload:test_the_battle_fixtures_carry_the_values_the_spec_table_lists()
	local want = {
		naboo_privateer_tier4_4a = { "naboo_privateer_tier4_leg_4_space_battle_one", { 5926, 1988, -4590 }, { 0.999064, 0.042300, -0.009016 }, 4, 65, 85, 5, 7 },
		naboo_privateer_tier4_4c_win = { "naboo_privateer_tier4_leg_4_space_battle_two", { -4578, 1604, -3839 }, { 0.301881, -0.595319, -0.744622 }, 3, 69, 120, 10, 12 },
		naboo_privateer_tier4_4c_lose = { "naboo_privateer_tier4_leg_4_space_battle_two", { -4578, 1604, -3839 }, { 0.301881, -0.595319, -0.744622 }, 3, 69, 120, 6, 12 },
	}

	for _, name in ipairs(sortedKeys(want)) do
		local o = B.oracle(name)
		local w = want[name]

		lu.assertEquals(o.pointName, w[1], name .. ": point name")
		lu.assertEquals({ o.point.x, o.point.z, o.point.y }, w[2], name .. ": point")
		lu.assertEquals({ o.forward.x, o.forward.z, o.forward.y }, w[3], name .. ": forward")
		lu.assertEquals({ o.damageMultiplier, o.allyDelay, o.enemyDelay, #o.allyForce, #o.enemyForce }, { w[4], w[5], w[6], w[7], w[8] }, name .. ": {damage, allyDelay, enemyDelay, allies, enemies}")
		lu.assertEquals({ o.allyOrigin, o.enemyOrigin, o.allyDist, o.enemyDist }, { -400, 400, -250, 250 }, name .. ": origin/arrival distances")
	end
end

-- AC-10 (Destroy duty)
function TestRsfTier4Payload:test_destroy_duty_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local row = { "destroy_duty", "naboo_privateer_tier4_1" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)
	local shipTypes = {}

	for i = 1, rec:num("shipTypes") do
		shipTypes[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), label .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), label .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), label .. ": totalLevels (levelsPerDuty)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), label .. ": bossShip (bossType)")
	lu.assertEquals(q.shipTypes, shipTypes, label .. ": shipTypes (columns shipType1..shipTypes)")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
end

-- AC-10 (Escort duty)
function TestRsfTier4Payload:test_escort_duty_maps_ship_points_attack_lists_delay_pay_and_taunt_counts()
	local row = { "escort_duty", "naboo_privateer_tier4_1" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)
	local points = {}

	for i, value in ipairs(rec:list("escortPoints")) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		points[i] = { patrolPointName = name, zoneName = zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.escortShips, { rec:get("escortShipTypes") }, label .. ": escortShips")
	lu.assertEquals(q.escortPoints, points, label .. ": escortPoints")
	lu.assertEquals(#points, 4, label .. ": number of escort points (spec)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), label .. ": creditKillBonus (killReward)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(type(q.tauntData), "table", label .. ": tauntData is a table")
	lu.assertEquals(q.tauntData.goodbyeCount, m, label .. ": tauntData.goodbyeCount")

	for _, field in ipairs({ "reasonCount", "tauntCount", "thanksCount" }) do
		lu.assertTrue(q.tauntData[field] == nil or q.tauntData[field] == m, label .. ": tauntData." .. field .. " is unset or " .. m)
	end
end

-- AC-10 (Recovery duty)
function TestRsfTier4Payload:test_recovery_duty_maps_ship_escorts_points_attack_lists_delay_pay_and_taunt_counts()
	local row = { "recovery_duty", "naboo_privateer_tier4_1" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)

	local function numbered(column)
		local out = {}

		for i, p in ipairs(pointsOf(rec, column)) do
			out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		return out
	end

	local escort = rec:get("targetEscort")

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipTypes"), label .. ": recoverShip (targetShipTypes)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), label .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.recoveryConversationMobile or "", "", label .. ": recoveryConversationMobile (recoveryAppearance is empty)")
	lu.assertEquals(q.escortShips, { escort, escort }, label .. ": escortShips (targetEscort, twice)")
	lu.assertEquals(q.preRecoveryPoints, numbered("escortPath"), label .. ": preRecoveryPoints (escortPath)")
	lu.assertEquals(q.recoveryPoints, numbered("recoveryPath"), label .. ": recoveryPoints (recoveryPath)")
	lu.assertEquals(#q.preRecoveryPoints, 5, label .. ": number of pre-recovery points (spec)")
	lu.assertEquals(#q.recoveryPoints, 3, label .. ": number of recovery points (spec)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), label .. ": creditKillBonus (killReward; space-recovery-duty-fixes S-7)")
	lu.assertEquals(q.tauntData, { panicCount = 2, thanksCount = 2 }, label .. ": tauntData")
end

-- AC-10 (Rescue duty)
function TestRsfTier4Payload:test_rescue_duty_maps_path_targets_attack_lists_period_responses_and_pay()
	local row = { "rescue_duty", "naboo_privateer_tier4_1" }
	local q = quest(row)
	local rec = fixture(row)
	local label = labelOf(row)
	local path = pointsOf(rec, "recoveryPath")

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(type(q.recoveryPath), "table", label .. ": recoveryPath is a table")
	lu.assertEquals(#q.recoveryPath, #path, label .. ": number of recoveryPath points")

	for i, p in ipairs(path) do
		lu.assertEquals(q.recoveryPath[i].patrolPointName, p.name, label .. ": recoveryPath[" .. i .. "].patrolPointName")
		lu.assertEquals({ q.recoveryPath[i].x, q.recoveryPath[i].z, q.recoveryPath[i].y }, { p.x, p.z, p.y }, label .. ": recoveryPath[" .. i .. "] x/z/y")
	end

	lu.assertEquals(q.targetShipTypes, rec:list("targetShipTypes"), label .. ": targetShipTypes")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), label .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), label .. ": attackShipLists")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), label .. ": attackPeriod")
	lu.assertEquals(q.attackListType, ATTACK_LIST_TYPE[rec:get("attackListType")], label .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), label .. ": numResponses")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), label .. ": creditKillBonus")
end

---------------------------------------------------------------------------------------------
-- I-4: ships and points resolve
---------------------------------------------------------------------------------------------

TestRsfTier4References = {}

function TestRsfTier4References:setUp() H.reset() end

local function collectShips(q)
	local ships = {}

	local function add(v)
		if type(v) == "string" and v ~= "" then
			ships[v] = true
		elseif type(v) == "table" then
			for _, e in ipairs(v) do
				add(e)
			end
		end
	end

	for _, field in ipairs({ "escortShips", "attackShips", "attackShipLists", "shipTypes", "bossShip", "shipList", "pickupShip", "deliveryShip",
		"allyForce", "enemyForce", "targetShipTypes", "recoverShip" }) do
		add(rawget(q, field))
	end

	for _, spawn in ipairs((rawget(q, "surpriseAttackShips") or {}).spawns or {}) do
		add(spawn.shipName)
	end

	return ships
end

-- AC-10, I-4
function TestRsfTier4References:test_every_ship_named_by_a_tier4_table_has_a_ship_template_file()
	local total = 0

	for _, row in ipairs(ALL) do
		for ship in pairs(collectShips(quest(row))) do
			total = total + 1
			lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. ship .. ".lua"), labelOf(row) .. ": ship template bin/scripts/ship_mobile/ships/" .. ship .. ".lua exists")
		end
	end

	lu.assertTrue(total > 0, "at least one ship name collected from the tier 4 tables")
end

-- AC-10, I-4
function TestRsfTier4References:test_every_point_in_a_tier4_table_resolves_in_the_zone_patrol_point_file_with_the_same_coordinates()
	local checked = 0

	for _, row in ipairs(ALL) do
		local q = quest(row)

		local function check(p, zone)
			checked = checked + 1

			local known = H.patrolPoints(zone)[p.patrolPointName]

			lu.assertNotNil(known, labelOf(row) .. ": " .. tostring(p.patrolPointName) .. " missing from ship_mobile/patrol_points/" .. zone .. ".lua")
			lu.assertEquals({ p.x, p.z, p.y }, { known.x, known.z, known.y }, labelOf(row) .. ": " .. p.patrolPointName .. " coordinates")
		end

		for _, field in ipairs({ "patrolPoints", "escortPoints", "preRecoveryPoints", "recoveryPoints", "recoveryPath" }) do
			for _, p in ipairs(rawget(q, field) or {}) do
				check(p, p.zoneName or q.questZone)
			end
		end

		for _, field in ipairs({ "pickupPoint", "deliveryPoint", "transmissionPoint", "battlePoint" }) do
			if rawget(q, field) ~= nil then
				check(q[field], q.questZone)
			end
		end
	end

	lu.assertTrue(checked > 40, "number of points checked: " .. checked)
end

TestRsfTier4InspectShip = {}

function TestRsfTier4InspectShip:setUp() H.reset() end

-- AC-10
function TestRsfTier4InspectShip:test_freighterheavy_tier4_inspect_declares_the_industrial_cargo_the_quest_needs()
	local path = H.SCRIPTS .. "ship_mobile/ships/freighterheavy_tier4_inspect.lua"
	local src = readFile(path):gsub("%-%-[^\n]*", "")

	lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), "industrial_cargo", "ship_mobile/ships/freighterheavy_tier4_inspect.lua: cargoString")

	local found = false

	for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/freighter_inspect_cargo.tab").records) do
		if rec:get("name") == "industrial_cargo" and rec:num("canTransfer") == 1 then
			found = true
		end
	end

	lu.assertTrue(found, "industrial_cargo is a canTransfer = 1 row of inspect_cargo/freighter_inspect_cargo.tab")
end
