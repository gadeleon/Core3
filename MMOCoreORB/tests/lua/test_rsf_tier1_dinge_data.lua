-- RSF Squadron tier 1 (Dinge) data on SWG-Source's quest payloads: the 8 tables, the 15 real points and 5 spawners, the 4 deleted
-- invented points, the files that must not move.
-- Spec: .claude/work/rsf-tier1-dinge-data/01-spec.md (AC-1 .. AC-4, AC-6, AC-7, AC-9, AC-10, Content contract 1, 3, 4, 5,
-- Data mapping, invariants I-1 .. I-8).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/, the trainer script fixtures/script/conversation/
-- naboo_privateer_trainer_1.java and the buildout extract fixtures/space_zones/buildout/space_naboo.rsf_tier1_points.tab, never
-- the Core3 tables under test. The literals of the spec's Content contract (rsf_tier1_dinge_data.lua) are repeated as anchors,
-- so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier1_dinge_data")
local R = require("surprise_replay")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local EXTRACT = "space_zones/buildout/space_naboo.rsf_tier1_points.tab"
local JAVA = H.FIXTURES .. "script/conversation/naboo_privateer_trainer_1.java"
local PP_PATH = H.SCRIPTS .. "ship_mobile/patrol_points/space_naboo.lua"

local function quest(global) return H.expectGlobal(global, "RSF tier 1 Dinge quest table (rsf-tier1-dinge-data)") end

local function fixtureOf(global)
	local id = D.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
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

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

local function ownKeys(q)
	local own = {}

	for k, v in pairs(q) do
		own[k] = v
	end

	return own
end

local function inherits(q, class)
	local mt = getmetatable(q)

	for _ = 1, 8 do
		if mt == nil then
			return false
		end

		if mt == class or mt.__index == class then
			return true
		end

		mt = getmetatable(mt.__index)
	end

	return false
end

-- The "zone:name" cells of a column as { zone, name, x, z, y } rows read from the patrol point files
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

-- nav point name -> { x, z, y } and spawner name -> { x, z, y } of the extract, truncated toward zero
local function buildout()
	local navs, spawners, nNav, nSpawn = {}, {}, 0, 0

	for _, rec in ipairs(H.fixture(EXTRACT).records) do
		local vars = rec:get("strObjVars") or ""
		local xyz = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawner = vars:match("strSpawnerName|4|([^|]+)|")

		if nav ~= nil then
			navs[nav] = xyz
			nNav = nNav + 1
		elseif spawner ~= nil then
			spawners[spawner] = xyz
			nSpawn = nSpawn + 1
		end
	end

	return navs, spawners, nNav, nSpawn
end

local function expected() return D.expected() end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestRsfTier1DingeFixtures = {}

function TestRsfTier1DingeFixtures:setUp() H.reset() end

-- AC-1 .. AC-7 (the oracle itself)
function TestRsfTier1DingeFixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = H.questFixture("patrol", "naboo_privateer_1")

	lu.assertEquals({ p1:get("questZone"), #p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg") },
		{ "space_naboo", 3, 2, 20, "destroy_surpriseattack:naboo_privateer_1" }, "patrol/naboo_privateer_1")

	local p3 = H.questFixture("patrol", "naboo_privateer_3")

	lu.assertEquals({ p3:get("questZone"), #p3:list("navPoints"), p3:num("triggerOn"), p3:num("triggerDelay"), p3:get("triggerArg") },
		{ "space_naboo", 4, 2, 20, "escort:naboo_privateer_3" }, "patrol/naboo_privateer_3")

	local s1 = H.questFixture("destroy_surpriseattack", "naboo_privateer_1")

	lu.assertEquals({ s1:list("shipType"), s1:list("shipCount") }, { { "blacksun_fighter_s02_tier1", "blacksun_fighter_s01_tier1" }, { "3" } }, "destroy_surpriseattack/naboo_privateer_1")

	local d2 = H.questFixture("destroy", "naboo_privateer_2")

	lu.assertEquals({ #d2:list("shipList"), #d2:list("validSpawns"), d2:num("killCount"), d2:num("giveSpawnWaypoint"), d2:num("spawnsForWaypointsOnly") },
		{ 34, 5, 4, 1, 0 }, "destroy/naboo_privateer_2")

	local e3 = H.questFixture("escort", "naboo_privateer_3")

	lu.assertEquals({ e3:get("escortShipType"), #e3:list("escortPath"), e3:num("numAttackShipLists"), e3:num("attackPeriod"), e3:get("attackListType"), e3:num("numResponses") },
		{ "freighterheavy_tier1", 4, 2, 90, "random", 3 }, "escort/naboo_privateer_3")

	local a4 = H.questFixture("assassinate", "naboo_privateer_tier1_4a")

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), #a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "blacksun_ace_s04_tier1", 0, 4, 3, 1 }, "assassinate/naboo_privateer_tier1_4a")

	local d6 = H.questFixture("destroy_duty", "naboo_privateer_6")

	lu.assertEquals({ d6:num("wavesPerRound"), d6:num("roundsPerLevel"), d6:num("levelsPerDuty"), d6:num("shipTypes"), d6:get("bossType"), d6:num("numResponses"), d6:num("reward") },
		{ 2, 2, 2, 2, "blacksun_marauder_tier1", 5, 100 }, "destroy_duty/naboo_privateer_6")

	local e7 = H.questFixture("escort_duty", "naboo_privateer_7")

	lu.assertEquals({ #e7:list("escortShipTypes"), #e7:list("escortPoints"), e7:num("numAttackShipLists"), e7:num("attackPeriod"), e7:num("numResponses"), e7:num("reward"), e7:num("killReward") },
		{ 3, 4, 1, 90, 5, 2500, 200 }, "escort_duty/naboo_privateer_7")
end

-- I-2, I-3 (the oracle itself): the extract holds exactly the 15 nav points and 5 spawners of the spec, with the buildout floats
function TestRsfTier1DingeFixtures:test_the_buildout_extract_holds_the_fifteen_points_and_five_spawners_of_the_spec()
	local navs, spawners, nNav, nSpawn = buildout()

	lu.assertEquals({ nNav, nSpawn }, { 15, 5 }, "nav_name rows and strSpawnerName rows in " .. EXTRACT)
	lu.assertEquals(sortedKeys(navs), sortedKeys(D.POINTS), "nav points in " .. EXTRACT)
	lu.assertEquals(sortedKeys(spawners), sortedKeys(D.SPAWNERS), "spawners in " .. EXTRACT)

	for name, xyz in pairs(D.POINTS) do
		lu.assertEquals(navs[name], xyz, EXTRACT .. ": " .. name .. " truncated x, z, y")
	end

	for name, xyz in pairs(D.SPAWNERS) do
		lu.assertEquals(spawners[name], xyz, EXTRACT .. ": spawner " .. name .. " truncated x, z, y")
	end
end

-- I-6 (the oracle itself): the reward amounts are the giveReward lines of the SWG Dinge script (J:205-239)
function TestRsfTier1DingeFixtures:test_the_reward_table_matches_the_giveReward_lines_of_the_swg_dinge_script()
	local found = {}

	for questType, questName, credits, rest in readFile(JAVA):gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.patrol_naboo_privateer_1, { { 100, nil } }, "J rewardForQuestOne")
	lu.assertEquals(found.destroy_naboo_privateer_2, { { 200, nil } }, "J rewardForQuestTwo")
	lu.assertEquals(found.patrol_naboo_privateer_3, { { 500, D.BANDOLIER }, { 500, D.ITH_BANDOLIER } }, "J rewardForQuestThree")
	lu.assertEquals(found.assassinate_naboo_privateer_tier1_4a, { { 1000, D.BLASTER } }, "J rewardForQuestFour")
	lu.assertEquals(sortedKeys(found), { "assassinate_naboo_privateer_tier1_4a", "destroy_naboo_privateer_2", "patrol_naboo_privateer_1", "patrol_naboo_privateer_3" }, "quests J pays")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-1 .. AC-4, AC-6, AC-7, I-1, I-7, I-8)
---------------------------------------------------------------------------------------------

TestRsfTier1DingeTables = {}

function TestRsfTier1DingeTables:setUp() H.reset() end

-- I-1
function TestRsfTier1DingeTables:test_the_eight_tables_are_registered_with_start_and_keep_their_identity()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local id = D.IDENTITY[global]

		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_naboo", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-1 .. AC-4, AC-6, AC-7: Content contract 1, every key, nothing else
function TestRsfTier1DingeTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	lu.assertEquals(type(SPECIES_ITHORIAN), "number", "precondition: SPECIES_ITHORIAN is a harness constant")

	local want = expected()

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- I-7
function TestRsfTier1DingeTables:test_no_table_sets_a_key_its_quest_type_never_reads()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		for _, key in ipairs({ "assassinateTarget", "assassinateWingmen", "dutyMissionLevel" }) do
			lu.assertNil(rawget(q, key), global .. ": " .. key)
		end
	end

	for _, global in ipairs({ D.DUTY6, D.DUTY7 }) do
		lu.assertNil(rawget(quest(global), "shipLocations"), global .. ": shipLocations")
	end
end

-- I-8
function TestRsfTier1DingeTables:test_only_patrol_1_and_patrol_3_split_and_they_split_at_point_2_after_20_seconds()
	local split = {
		[D.P1] = { "destroy_surpriseattack", "naboo_privateer_1" },
		[D.P3] = { "escort", "naboo_privateer_3" },
	}

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local want = split[global]

		lu.assertEquals(q.sideQuest and true or false, want ~= nil, global .. ": sideQuest")

		if want ~= nil then
			lu.assertEquals({ q.sideQuestType, q.sideQuestName }, want, global .. ": sideQuestType, sideQuestName")
			lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, global .. ": sideQuestSplitType")
			lu.assertEquals({ q.sideQuestPatrolStart, q.sideQuestDelay }, { 2, 20 }, global .. ": sideQuestPatrolStart, sideQuestDelay")
		end
	end

	lu.assertEquals({ quest(D.S1).parentQuest, quest(D.S1).parentQuestType, quest(D.S1).parentQuestName }, { D.P1, "patrol", "naboo_privateer_1" }, D.S1 .. ": parent fields")
	lu.assertEquals({ quest(D.E3).parentQuest, quest(D.E3).parentQuestType, quest(D.E3).parentQuestName }, { D.P3, "patrol", "naboo_privateer_3" }, D.E3 .. ": parent fields")
end

-- I-6
function TestRsfTier1DingeTables:test_credits_and_items_are_paid_by_the_quests_j_pays_and_the_duties_only()
	local pays = { [D.P1] = 100, [D.M2] = 200, [D.P3] = 500, [D.A4] = 1000, [D.DUTY6] = 100, [D.DUTY7] = 2500 }

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if global == D.P3 then
			lu.assertEquals(q.itemReward, { { species = { SPECIES_ITHORIAN }, item = D.ITH_BANDOLIER }, { species = { -1 }, item = D.BANDOLIER } }, global .. ": itemReward (J:219-232)")
		elseif global == D.A4 then
			lu.assertEquals(q.itemReward, { { species = { -1 }, item = D.BLASTER } }, global .. ": itemReward (J:233-239)")
		else
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping)
---------------------------------------------------------------------------------------------

TestRsfTier1DingeConformance = {}

function TestRsfTier1DingeConformance:setUp() H.reset() end

local function patrolPointsOf(rec)
	local out = {}

	for i, p in ipairs(pointsOf(rec, "navPoints")) do
		out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
	end

	return out
end

-- AC-1, AC-3 (Data mapping): patrol/naboo_privateer_1.tab and patrol/naboo_privateer_3.tab
function TestRsfTier1DingeConformance:test_patrol_1_and_3_map_points_and_split_from_their_fixtures()
	for _, global in ipairs({ D.P1, D.P3 }) do
		local q, rec = quest(global), fixtureOf(global)
		local label = "patrol/" .. q.questName
		local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

		lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
		lu.assertEquals(q.patrolPoints, patrolPointsOf(rec), label .. ": patrolPoints (navPoints)")
		lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), label .. ": sideQuestPatrolStart (triggerOn)")
		lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), label .. ": sideQuestDelay (triggerDelay)")
		lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, label .. ": sideQuestType, sideQuestName (triggerArg)")
	end
end

-- AC-3: the two points that were wrong
function TestRsfTier1DingeConformance:test_patrol_3_points_1_and_4_have_the_corrected_coordinates()
	local pts = quest(D.P3).patrolPoints

	lu.assertEquals({ pts[1].x, pts[1].z, pts[1].y }, { 1690, -686, 2007 }, "patrol_naboo_privateer_3: point 1 (privateer_security_patrol_1)")
	lu.assertEquals({ pts[4].x, pts[4].z, pts[4].y }, { 1314, -489, 3639 }, "patrol_naboo_privateer_3: point 4 (privateer_security_patrol_4)")
end

-- AC-1 (Data mapping): destroy_surpriseattack/naboo_privateer_1.tab, by replaying SWG's spawn loop
function TestRsfTier1DingeConformance:test_surprise_attack_1_equals_the_replay_of_the_swg_spawn_loop()
	local q = quest(D.S1)

	lu.assertEquals(q.surpriseAttackShips, { zone = H.questFixture("destroy_surpriseattack", "naboo_privateer_1"):get("questZone"), spawns = R.runs(R.replay("naboo_privateer_1")) },
		"destroy_surpriseattack/naboo_privateer_1: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.replay("naboo_privateer_1"), { "blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier1", "blacksun_fighter_s02_tier1" }, "the replay itself: 3 x s02, the s01 row has count 0")
end

-- AC-2 (Data mapping): destroy/naboo_privateer_2.tab
function TestRsfTier1DingeConformance:test_destroy_2_maps_ships_kills_and_spawners()
	local q, rec = quest(D.M2), fixtureOf(D.M2)
	local label = "destroy/naboo_privateer_2"

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), label .. ": shipTypes (shipList, in order)")
	lu.assertEquals(#q.shipTypes, 34, label .. ": number of ship types (spec)")
	lu.assertEquals(q.killsRequired, rec:num("killCount"), label .. ": killsRequired (killCount)")

	local spawns = rec:list("validSpawns")

	lu.assertEquals(#q.shipLocations, #spawns, label .. ": number of shipLocations")

	for i, value in ipairs(spawns) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, label .. ": spawner " .. spawnName .. " in " .. zone)
		lu.assertEquals(zone, q.questZone, label .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.shipLocations[i], { spawnName = spawnName, x = s.x, z = s.z, y = s.y }, label .. ": shipLocations[" .. i .. "] (" .. spawnName .. ")")
	end
end

-- AC-3 (Data mapping): escort/naboo_privateer_3.tab; AC-7 (Data mapping): escort_duty/naboo_privateer_7.tab
function TestRsfTier1DingeConformance:test_escort_3_and_escort_duty_7_map_ships_path_attack_lists_delay_and_taunts()
	for _, global in ipairs({ D.E3, D.DUTY7 }) do
		local q, rec = quest(global), fixtureOf(global)
		local label = D.IDENTITY[global].type .. "/" .. q.questName
		local shipsColumn = global == D.E3 and "escortShipType" or "escortShipTypes"
		local pathColumn = global == D.E3 and "escortPath" or "escortPoints"
		local points = {}

		for i, p in ipairs(pointsOf(rec, pathColumn)) do
			points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
		lu.assertEquals(q.escortShips, rec:list(shipsColumn), label .. ": escortShips (" .. shipsColumn .. ")")
		lu.assertEquals(q.escortPoints, points, label .. ": escortPoints (" .. pathColumn .. ")")
		lu.assertEquals(#points, 4, label .. ": number of escort points (spec)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, label .. ": tauntData (max(numResponses, 1))")
	end

	local d7 = quest(D.DUTY7)
	local rec = fixtureOf(D.DUTY7)

	lu.assertEquals(d7.creditReward, rec:num("reward"), "escort_duty/naboo_privateer_7: creditReward (reward)")
	lu.assertEquals(d7.creditKillBonus, rec:num("killReward"), "escort_duty/naboo_privateer_7: creditKillBonus (killReward)")
end

-- AC-4 (Data mapping): assassinate/naboo_privateer_tier1_4a.tab
function TestRsfTier1DingeConformance:test_assassinate_4a_maps_target_escorts_delay_and_path()
	local q, rec = quest(D.A4), fixtureOf(D.A4)
	local label = "assassinate/naboo_privateer_tier1_4a"
	local path = {}

	for i, p in ipairs(pointsOf(rec, "escortPath")) do
		path[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
		lu.assertEquals(p.zone, q.questZone, label .. ": escortPath zone equals questZone")
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, label .. ": assassinateSpawns (targetShipType, targetEscort)")
	lu.assertEquals(#q.assassinateSpawns.escorts, 3, label .. ": number of escorts (spec)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.targetPatrols, path, label .. ": targetPatrols (escortPath)")
	lu.assertEquals(q.failTimer, 20, label .. ": failTimer (Core3-only)")
	lu.assertNil(rawget(q, "assassinateTarget"), label .. ": assassinateTarget is not read by SpaceAssassinateScreenplay")
	lu.assertNil(rawget(q, "assassinateWingmen"), label .. ": assassinateWingmen is not read by SpaceAssassinateScreenplay")
end

-- AC-6 (Data mapping): destroy_duty/naboo_privateer_6.tab
function TestRsfTier1DingeConformance:test_destroy_duty_6_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(D.DUTY6), fixtureOf(D.DUTY6)
	local label = "destroy_duty/naboo_privateer_6"
	local shipTypes = {}

	for i = 1, rec:num("shipTypes") do
		shipTypes[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), label .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), label .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), label .. ": totalLevels (levelsPerDuty, D-11)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), label .. ": bossShip (bossType)")
	lu.assertEquals(q.shipTypes, shipTypes, label .. ": shipTypes (columns shipType1..shipTypes)")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")

	for i, ships in ipairs(q.shipTypes) do
		lu.assertEquals(type(ships), "table", label .. ": shipTypes[" .. i .. "] is a list, not a string")
	end
end

-- I-4: every ship the 8 tables name has a ship template (the engine gate checks the real load)
function TestRsfTier1DingeConformance:test_every_ship_the_eight_tables_name_has_a_ship_template()
	local seen = {}

	local function walk(value)
		if type(value) == "string" then
			seen[value] = true
		elseif type(value) == "table" then
			for _, v in ipairs(value) do
				walk(v)
			end
		end
	end

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes" }) do
			walk(rawget(q, field))
		end

		walk(rawget(q, "bossShip"))

		if global == D.S1 then
			for _, spawn in ipairs(q.surpriseAttackShips.spawns) do
				walk(spawn.shipName)
			end
		elseif global == D.A4 then
			lu.assertNotNil(q.assassinateSpawns, global .. ": assassinateSpawns")
			walk(q.assassinateSpawns.target)
			walk(q.assassinateSpawns.escorts)
		end
	end

	local names = sortedKeys(seen)

	-- 34 destroy 2 types, the s02/s01/s03 fighters and bombers they share, 3 freighters, 3 tier 2 escort freighters, 2 marauders and the ace are among them
	lu.assertTrue(#names >= 38, "ship names found in the 8 tables, got " .. #names)

	for _, name in ipairs(names) do
		local f = io.open(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua", "r")

		lu.assertNotNil(f, "ship_mobile/ships/" .. name .. ".lua does not exist")
		f:close()
	end
end

---------------------------------------------------------------------------------------------
-- Points (AC-9, I-2, I-3)
---------------------------------------------------------------------------------------------

TestRsfTier1DingePoints = {}

function TestRsfTier1DingePoints:setUp() H.reset() end

-- Every {patrolPointName = ...} entry of the 8 tables, with its owner
local function pointUses()
	local uses = {}

	local function walk(owner, value)
		if type(value) ~= "table" then
			return
		end

		if type(value.patrolPointName) == "string" then
			uses[#uses + 1] = { owner = owner, entry = value }
		end

		for _, v in pairs(value) do
			walk(owner, v)
		end
	end

	for _, global in ipairs(D.GLOBALS) do
		walk(global, quest(global))
	end

	return uses
end

-- AC-9, I-2: the points the 8 tables name are the 15 real ones, in the point files and in the buildout, with identical coordinates
function TestRsfTier1DingePoints:test_every_point_a_table_names_is_a_buildout_nav_point_with_the_same_coordinates_in_the_point_file()
	local navs = buildout()
	local points = H.patrolPoints("space_naboo")
	local seen, count = {}, 0

	for _, use in ipairs(pointUses()) do
		local name, e = use.entry.patrolPointName, use.entry

		lu.assertNotNil(points[name], use.owner .. ": " .. name .. " is not defined in space_naboo.lua")
		lu.assertNotNil(navs[name], use.owner .. ": " .. name .. " is not a nav point of the buildout extract")
		lu.assertEquals({ e.x, e.z, e.y }, { points[name].x, points[name].z, points[name].y }, use.owner .. ": " .. name .. " x, z, y equal the point file")
		lu.assertEquals({ points[name].x, points[name].z, points[name].y }, navs[name], "space_naboo.lua: " .. name .. " equals the buildout truncated toward zero")
		seen[name] = true
		count = count + 1
	end

	lu.assertEquals(sortedKeys(seen), sortedKeys(D.POINTS), "distinct patrol points named by the 8 tables")
	lu.assertEquals(count, 19, "point uses (3 + 4 patrol, 4 + 4 escort, 4 assassinate)")
end

-- AC-9, I-3: destroy 2's spawners are space_naboo spawners with the buildout coordinates
function TestRsfTier1DingePoints:test_every_spawner_of_destroy_2_exists_with_the_buildout_coordinates()
	local _, spawners = buildout()
	local all = H.spawners("space_naboo")
	local n = 0

	for _, loc in ipairs(quest(D.M2).shipLocations) do
		lu.assertNotNil(loc.spawnName, D.M2 .. ": shipLocations entry without spawnName at x = " .. tostring(loc.x))

		local s = all[loc.spawnName]

		lu.assertNotNil(s, D.M2 .. ": spawner " .. loc.spawnName .. " is not in space_naboo_spawner.lua")
		lu.assertEquals({ loc.x, loc.z, loc.y }, { s.x, s.z, s.y }, D.M2 .. ": " .. loc.spawnName .. " x, z, y equal the spawner table")
		lu.assertEquals({ s.x, s.z, s.y }, spawners[loc.spawnName], "space_naboo_spawner.lua: " .. loc.spawnName .. " equals the buildout truncated toward zero")
		n = n + 1
	end

	lu.assertEquals(n, 5, "number of spawners")
end

-- AC-9, Content contract 3
function TestRsfTier1DingePoints:test_the_four_invented_escort_points_and_their_comment_are_gone_from_space_naboo()
	local points = H.patrolPoints("space_naboo")
	local text = readFile(PP_PATH)

	for _, name in ipairs(D.INVENTED) do
		lu.assertNil(points[name], "space_naboo: " .. name .. " is still defined (rsf-tier1-dinge-data)")
		lu.assertNil(text:find('"' .. name .. '"', 1, true), "space_naboo.lua still names " .. name)
	end

	lu.assertNil(text:find(D.PP_COMMENT, 1, true), "space_naboo.lua still has the comment '" .. D.PP_COMMENT .. "'")
end

-- AC-9, Content contract 3: the file loses exactly the five lines and keeps its neighbour, closing brace and registration call
function TestRsfTier1DingePoints:test_the_point_file_keeps_its_preceding_row_and_its_registration_call()
	local text = readFile(PP_PATH)

	lu.assertNotNil(H.patrolPoints("space_naboo").commerce_route_1_04, "commerce_route_1_04 (the row before the deleted block) stays")
	lu.assertNotNil(text:find('{patrolPointName = "commerce_route_1_04", x = 987, z = 1211, y = -2681},\n}\n\nSpacePatrolPoints:addSpacePatrolPoints(space_naboo, "space_naboo")', 1, true),
		"the last row is commerce_route_1_04, then the closing brace and the registration call")
end

-- AC-9: the points other content owns stay
function TestRsfTier1DingePoints:test_space_lok_and_corsec_keep_their_own_privateer_escort_points()
	local lok = H.patrolPoints("space_lok")

	lu.assertEquals({ lok.privateer_escort_1.x, lok.privateer_escort_1.z, lok.privateer_escort_1.y }, { 0, 0, 852 }, "space_lok: privateer_escort_1")
	lu.assertEquals({ lok.privateer_escort_2.x, lok.privateer_escort_2.z, lok.privateer_escort_2.y }, { -833, 145, 5234 }, "space_lok: privateer_escort_2")
	lu.assertEquals({ lok.privateer_escort_3.x, lok.privateer_escort_3.z, lok.privateer_escort_3.y }, { -1502, 231, 6021 }, "space_lok: privateer_escort_3")

	local corsec = {}

	for _, global in ipairs(H.questGlobals()) do
		local q = rawget(_G, global)

		for _, p in ipairs(rawget(q, "escortPoints") or {}) do
			if p.patrolPointName:match("^privateer_escort_%d$") and p.zoneName == "space_yavin4" then
				corsec[p.patrolPointName] = { p.x, p.z, p.y, global }
			end
		end
	end

	lu.assertEquals(corsec.privateer_escort_1, { -2163, 956, 4991, "escort_corellia_privateer_14" }, "CorSec escort 14: privateer_escort_1 (zone space_yavin4)")
	lu.assertEquals(corsec.privateer_escort_2, { -637, -295, 4770, "escort_corellia_privateer_14" }, "CorSec escort 14: privateer_escort_2")
	lu.assertEquals(corsec.privateer_escort_3, { 2043, -1230, 5414, "escort_corellia_privateer_14" }, "CorSec escort 14: privateer_escort_3")
	lu.assertEquals(corsec.privateer_escort_4, { -2064, -929, -3183, "escort_corellia_privateer_14" }, "CorSec escort 14: privateer_escort_4")
end

-- AC-9, R-6: no loaded quest names a deleted point in space_naboo any more
function TestRsfTier1DingePoints:test_no_loaded_space_naboo_quest_names_a_deleted_point()
	local set = {}

	for _, name in ipairs(D.INVENTED) do
		set[name] = true
	end

	local hits = {}

	for _, global in ipairs(H.questGlobals()) do
		local q = rawget(_G, global)

		if rawget(q, "questZone") == "space_naboo" then
			local function walk(value, path, visited)
				if type(value) == "table" and not visited[value] then
					visited[value] = true

					if set[value.patrolPointName] and (value.zoneName == nil or value.zoneName == "space_naboo") then
						hits[#hits + 1] = path .. " = " .. value.patrolPointName
					end

					for k, v in pairs(value) do
						walk(v, path .. "." .. tostring(k), visited)
					end
				end
			end

			walk(q, global, {})
		end
	end

	table.sort(hits)
	lu.assertEquals(hits, {}, "space_naboo quest tables that still name privateer_escort_1..4")
end

---------------------------------------------------------------------------------------------
-- Nothing else moves (AC-10)
---------------------------------------------------------------------------------------------

TestRsfTier1DingeUntouched = {}

function TestRsfTier1DingeUntouched:setUp() H.reset() end

-- rsf-tier1-dinge-convo D-10: the F6 byte-identity test (every file equal to 0d2c61189c) is retired; F6 was data-only and that
-- is settled by the reviewed commit 4eefa91216. The constants test below stays.

-- AC-10: §2, the constants
function TestRsfTier1DingeUntouched:test_the_rsf_constants_and_the_migration_steps_do_not_move()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.QUEST_STRING_1, { type = "patrol", name = "naboo_privateer_1" }, "QUEST_STRING_1")
	lu.assertEquals(R.QUEST_STRING_1_SIDE, { type = "destroy_surpriseattack", name = "naboo_privateer_1" }, "QUEST_STRING_1_SIDE")
	lu.assertEquals(R.QUEST_STRING_2, { type = "destroy", name = "naboo_privateer_2" }, "QUEST_STRING_2")
	lu.assertEquals(R.QUEST_STRING_3, { type = "patrol", name = "naboo_privateer_3" }, "QUEST_STRING_3")
	lu.assertEquals(R.QUEST_STRING_3_SIDE, { type = "escort", name = "naboo_privateer_3" }, "QUEST_STRING_3_SIDE")
	lu.assertEquals(R.QUEST_STRING_4, { type = "assassinate", name = "naboo_privateer_tier1_4a" }, "QUEST_STRING_4")
	lu.assertEquals(R.QUEST_STRING_DUTY_4_1, { type = "destroy_duty", name = "naboo_privateer_6" }, "QUEST_STRING_DUTY_4_1")
	lu.assertEquals(R.QUEST_STRING_DUTY_4_2, { type = "escort_duty", name = "naboo_privateer_7" }, "QUEST_STRING_DUTY_4_2")
	lu.assertEquals(R.LEGACY_MIGRATION_STEPS, { "migrateLegacyTier3", "migrateLegacyTier2", "migrateLegacyTier2Duties" }, "LEGACY_MIGRATION_STEPS (no step in F6)")
end

-- AC-10: the whole RSF screenplay still has the tier 1 comment-free neighbours; the data port adds no migration step and no new global
function TestRsfTier1DingeUntouched:test_the_set_of_rsf_tier_1_quest_globals_is_exactly_the_eight()
	local found = {}

	for _, global in ipairs(H.questGlobals()) do
		local q = rawget(_G, global)

		if q.questZone == "space_naboo" and (q.questName:match("^naboo_privateer_[1-7]$") or q.questName == "naboo_privateer_tier1_4a") then
			found[#found + 1] = global
		end
	end

	local want = {}

	for i, global in ipairs(D.GLOBALS) do
		want[i] = global
	end

	table.sort(want)
	table.sort(found)
	lu.assertEquals(found, want, "space_naboo quest globals named naboo_privateer_1..7 / tier1_4a")
end
