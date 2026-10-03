-- RSF Squadron tier 2 (Captain Kaydine) missions on SWG-Source's quests: the assassination chain 1a/1b/1c, destroy 13,
-- recovery 14 and escort 15, the four deleted Core3 inventions, the constants, the legacy data and the 21 real points.
-- Spec: .claude/work/rsf-tier2-kaydine-missions/01-spec.md (AC-1 .. AC-5, Content contract 1, 2, 5, 7, Data mapping,
-- invariants I-1 .. I-7, I-11, I-12).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/, the Kaydine script naboo_privateer_trainer_2.java
-- (rewards) and the buildout extract fixtures/space_zones/buildout/space_naboo.rsf_tier2_points.tab, never the Core3 tables
-- under test. The literals of the spec's Content contract are repeated as anchors so a misparsed fixture cannot make a wrong
-- table look right.

local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

local A1, A2, A3 = "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c"
local D13, R14, E15 = "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15"
local NEW_GLOBALS = { A1, A2, A3, D13, R14, E15 }
local DELETED = { "destroy_naboo_privateer_13a", "escort_naboo_privateer_14", "inspect_naboo_privateer_15", "assassinate_naboo_privateer_tier2_4a" }

local COMP = "object/tangible/ship/components/"
local ITEMS = {
	[A1] = COMP .. "booster/bst_mission_reward_neutral_mandal_m_series.iff",
	[D13] = COMP .. "weapon/wpn_mission_reward_neutral_hk_military_blaster.iff",
	[R14] = COMP .. "shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff",
	[E15] = COMP .. "droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff",
}

local function quest(global) return H.expectGlobal(global, "RSF tier 2 Kaydine quest table (rsf-tier2-kaydine-missions)") end

local function fixtureOf(global)
	local q = quest(global)

	return H.questFixture(q.questType, q.questName)
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

-- "object/mobile/<f>.iff" -> "object/mobile/shared_<f>.iff" (D-10)
local function sharedAppearance(path)
	return (path:gsub("([^/]+)$", "shared_%1"))
end

---------------------------------------------------------------------------------------------
-- Oracle sanity: the fixtures carry the values the spec lists
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineFixtures = {}

function TestRsfTier2KaydineFixtures:setUp() H.reset() end

-- AC-1 .. AC-4 (the oracle itself)
function TestRsfTier2KaydineFixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local function row(rec) return { rec:get("questZone"), rec:get("targetShipType"), rec:num("targetArrivalDelay"), #rec:list("targetEscort"), #rec:list("escortPath") } end

	lu.assertEquals(row(H.questFixture("assassinate", "naboo_privateer_tier2_1a")), { "space_naboo", "aynat_enforcer_tier3", 5, 2, 4 }, "assassinate 1a")
	lu.assertEquals(row(H.questFixture("assassinate", "naboo_privateer_tier2_1b")), { "space_naboo", "aynat_enforcer_tier3", 6, 3, 4 }, "assassinate 1b")
	lu.assertEquals(row(H.questFixture("assassinate", "naboo_privateer_tier2_1c")), { "space_naboo", "aynat_enforcer_tier3", 2, 2, 2 }, "assassinate 1c")

	local d = H.questFixture("destroy", "naboo_privateer_13")

	lu.assertEquals({ d:get("questZone"), d:num("killCount"), #d:list("shipList"), #d:list("validSpawns"), d:get("triggerEvent") }, { "space_naboo", 6, 6, 2, "none" }, "destroy 13")

	local r = H.questFixture("recovery", "naboo_privateer_14")

	lu.assertEquals({ r:get("targetShipType"), r:num("targetArrivalDelay"), r:num("targetRecoverTime"), r:get("recoveryAppearance"), #r:list("targetEscort"), #r:list("escortPath"), #r:list("recoveryPath"), r:num("numAttackShipLists"), r:num("attackPeriod"), r:num("numResponses") },
		{ "aynat_yacht_tier3", 12, 30, "object/mobile/space_comm_aynat_ace_04.iff", 2, 4, 3, 2, 120, 5 }, "recovery 14")

	local e = H.questFixture("escort", "naboo_privateer_15")

	lu.assertEquals({ e:get("escortShipType"), #e:list("escortPath"), e:num("numAttackShipLists"), e:num("attackPeriod"), e:num("numResponses") }, { "rsf_prison_ship_tier3", 4, 1, 120, 5 }, "escort 15")
end

-- AC-1 .. AC-4: the spec's reward lines are the giveReward lines of the SWG script (K:208-229)
function TestRsfTier2KaydineFixtures:test_the_reward_table_matches_the_giveReward_lines_of_the_swg_kaydine_script()
	local found = {}

	for questType, questName, credits, item in readFile(H.FIXTURES .. "script/conversation/naboo_privateer_trainer_2.java"):gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		found[questType .. "_" .. questName] = { tonumber(credits), item }
	end

	for _, global in ipairs({ A1, D13, R14, E15 }) do
		lu.assertEquals(found[global], { 5000, ITEMS[global] }, global .. ": K giveReward")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: the assassination chain 1a / 1b / 1c
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineAssassinate = {}

function TestRsfTier2KaydineAssassinate:setUp() H.reset() end

-- global, quest name, parent global/type/name, side type/name (nil: none), delay, escorts, patrol names
local ASSASSINATE = {
	{ A1, "naboo_privateer_tier2_1a", "", "", "", "assassinate", "naboo_privateer_tier2_1b", 5, { "aynat_ghost_tier2", "aynat_ghost_tier2" },
		{ "naboo_privateer_tier2_assassinate_one_1", "naboo_privateer_tier2_assassinate_one_2", "naboo_privateer_tier2_assassinate_one_3", "naboo_privateer_tier2_assassinate_one_4" } },
	{ A2, "naboo_privateer_tier2_1b", A1, "assassinate", "naboo_privateer_tier2_1a", "assassinate", "naboo_privateer_tier2_1c", 6, { "aynat_ghost_tier2", "aynat_ghost_tier2", "aynat_ghost_tier2" },
		{ "naboo_imperial_tier2_escortduty_7", "naboo_imperial_tier2_recoveryduty_1", "naboo_imperial_tier3_recovery1_3", "privateer_security_escort_1" } },
	{ A3, "naboo_privateer_tier2_1c", A2, "assassinate", "naboo_privateer_tier2_1b", nil, nil, 2, { "aynat_outlaw_tier2", "aynat_outlaw_tier2" },
		{ "privateer_tier2_recovery_2", "privateer_patrol_3" } },
}

-- AC-1
function TestRsfTier2KaydineAssassinate:test_payload_equals_the_fixture_for_all_three()
	for _, row in ipairs(ASSASSINATE) do
		local name = row[1]
		local q = quest(name)
		local rec = fixtureOf(name)

		lu.assertEquals(q.className, name, name .. ": className")
		lu.assertEquals({ q.questType, q.questName }, { "assassinate", row[2] }, name .. ": questType, questName")
		lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), name .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.assassinateSpawns.target, rec:get("targetShipType"), name .. ": assassinateSpawns.target")
		lu.assertEquals(q.assassinateSpawns.escorts, rec:list("targetEscort"), name .. ": assassinateSpawns.escorts (in order)")
		lu.assertEquals(q.failTimer, 20, name .. ": failTimer (Core3 choice, no SWG column)")

		local points = rec:list("escortPath")

		lu.assertEquals(#q.targetPatrols, #points, name .. ": number of targetPatrols")

		for i, value in ipairs(points) do
			local zone, pointName = H.Tab.splitNavPoint(value)
			local p = point(zone, pointName)

			lu.assertEquals(zone, q.questZone, name .. ": escortPath zone equals questZone")
			lu.assertEquals(q.targetPatrols[i], { patrolPointName = pointName, x = p.x, z = p.z, y = p.y }, name .. ": targetPatrols[" .. i .. "] (" .. pointName .. ")")
		end
	end
end

-- AC-1: the literals of the Content contract
function TestRsfTier2KaydineAssassinate:test_literal_payload_of_the_contract()
	for _, row in ipairs(ASSASSINATE) do
		local q = quest(row[1])

		lu.assertEquals(q.arrivalDelay, row[8], row[1] .. ": arrivalDelay")
		lu.assertEquals(q.assassinateSpawns, { target = "aynat_enforcer_tier3", escorts = row[9] }, row[1] .. ": assassinateSpawns")

		local names = {}

		for i, p in ipairs(q.targetPatrols) do
			names[i] = p.patrolPointName
		end

		lu.assertEquals(names, row[10], row[1] .. ": targetPatrols names, in order")
	end

	lu.assertEquals(quest(A1).targetPatrols, {
		{ patrolPointName = "naboo_privateer_tier2_assassinate_one_1", x = 6000, z = -2000, y = 500 },
		{ patrolPointName = "naboo_privateer_tier2_assassinate_one_2", x = 1500, z = -1250, y = -1500 },
		{ patrolPointName = "naboo_privateer_tier2_assassinate_one_3", x = -500, z = -500, y = -4000 },
		{ patrolPointName = "naboo_privateer_tier2_assassinate_one_4", x = -700, z = 0, y = -4000 },
	}, "1a: targetPatrols")
	lu.assertEquals(quest(A2).targetPatrols, {
		{ patrolPointName = "naboo_imperial_tier2_escortduty_7", x = -4015, z = 4013, y = -4023 },
		{ patrolPointName = "naboo_imperial_tier2_recoveryduty_1", x = 3331, z = -3465, y = -3994 },
		{ patrolPointName = "naboo_imperial_tier3_recovery1_3", x = -1560, z = -4222, y = 2922 },
		{ patrolPointName = "privateer_security_escort_1", x = 1341, z = -546, y = 3125 },
	}, "1b: targetPatrols")
	lu.assertEquals(quest(A3).targetPatrols, {
		{ patrolPointName = "privateer_tier2_recovery_2", x = -2063, z = -2771, y = -1840 },
		{ patrolPointName = "privateer_patrol_3", x = 2466, z = 854, y = -505 },
	}, "1c: targetPatrols")
end

-- AC-1, I-3: the split fields derive from the fixture (success split, triggerDelay + 5); 1c does not split
function TestRsfTier2KaydineAssassinate:test_split_fields_equal_the_fixture()
	for _, row in ipairs(ASSASSINATE) do
		local q, rec = quest(row[1]), fixtureOf(row[1])

		if row[7] ~= nil then
			local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

			lu.assertEquals({ rec:get("triggerEvent"), rec:get("triggerSplitCondition") }, { "splitquest", "success" }, row[1] .. ": fixture split")
			lu.assertTrue(q.sideQuest, row[1] .. ": sideQuest")
			lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { sideType, sideName }, row[1] .. ": side quest (triggerArg)")
			lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { row[6], row[7] }, row[1] .. ": side quest (spec)")
			lu.assertEquals(q.sideQuestSplitType, SPLIT.COMPLETION, row[1] .. ": sideQuestSplitType")
			lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, row[1] .. ": sideQuestDelay (triggerDelay + 5)")
			lu.assertEquals(q.sideQuestDelay, 5, row[1] .. ": sideQuestDelay (spec)")
		else
			lu.assertEquals(rec:get("triggerEvent"), "none", row[1] .. ": fixture triggerEvent")
			lu.assertFalse(q.sideQuest and true or false, row[1] .. ": sideQuest")
			lu.assertTrue(q.sideQuestSplitType == nil or q.sideQuestSplitType == SPLIT.NONE, row[1] .. ": sideQuestSplitType is NONE or unset")
			lu.assertTrue(q.sideQuestType == nil or q.sideQuestType == "", row[1] .. ": sideQuestType is empty")
		end
	end
end

-- AC-1, I-3: parents follow the split chain
function TestRsfTier2KaydineAssassinate:test_parent_fields_name_the_splitting_quest()
	for _, row in ipairs(ASSASSINATE) do
		local q = quest(row[1])

		lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { row[3], row[4], row[5] }, row[1] .. ": parent fields")
	end
end

-- AC-1, I-2: only 1a pays, with the item of K:208
function TestRsfTier2KaydineAssassinate:test_only_1a_pays_5000_credits_and_the_booster()
	lu.assertEquals(quest(A1).creditReward, 5000, "1a: creditReward")
	lu.assertEquals(quest(A1).itemReward, { { species = { -1 }, item = ITEMS[A1] } }, "1a: itemReward")

	for _, name in ipairs({ A2, A3 }) do
		lu.assertEquals(quest(name).creditReward, 0, name .. ": creditReward")
		lu.assertEquals(quest(name).itemReward, {}, name .. ": itemReward")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: destroy 13
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineDestroy13 = {}

function TestRsfTier2KaydineDestroy13:setUp() H.reset() end

-- AC-2
function TestRsfTier2KaydineDestroy13:test_payload_equals_the_fixture()
	local q, rec = quest(D13), fixtureOf(D13)

	lu.assertEquals(q.className, D13, "className")
	lu.assertEquals({ q.questType, q.questName }, { "destroy", "naboo_privateer_13" }, "questType, questName")
	lu.assertEquals(q.questZone, rec:get("questZone"), D13 .. ": questZone")
	lu.assertEquals(q.killsRequired, rec:num("killCount"), D13 .. ": killsRequired (killCount)")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), D13 .. ": shipTypes (shipList, in order)")

	local spawns = rec:list("validSpawns")

	lu.assertEquals(#q.shipLocations, #spawns, D13 .. ": number of shipLocations")

	for i, value in ipairs(spawns) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, D13 .. ": spawner " .. spawnName .. " in " .. zone)
		lu.assertEquals(zone, q.questZone, D13 .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.shipLocations[i], { spawnName = spawnName, x = s.x, z = s.z, y = s.y }, D13 .. ": shipLocations[" .. i .. "] (" .. spawnName .. ")")
	end

	lu.assertFalse(q.sideQuest and true or false, D13 .. ": sideQuest (triggerEvent " .. tostring(rec:get("triggerEvent")) .. ")")
	lu.assertTrue(q.sideQuestType == nil or q.sideQuestType == "", D13 .. ": sideQuestType")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { "", "", "" }, D13 .. ": parent fields")
end

-- AC-2: the literals of the contract
function TestRsfTier2KaydineDestroy13:test_literal_payload_and_reward()
	local q = quest(D13)

	lu.assertEquals(q.killsRequired, 6, "killsRequired")
	lu.assertEquals(q.shipTypes, { "aynat_ghost_tier1", "aynat_ghost_tier2", "aynat_ghost_tier3", "aynat_ghost_tier4", "aynat_ghost_tier5", "aynat_ghost" }, "shipTypes")
	lu.assertEquals(q.shipLocations, {
		{ spawnName = "naboo_privateer_12", x = 3142, z = -3591, y = -492 },
		{ spawnName = "naboo_privateer_13", x = 3168, z = -1441, y = -1209 },
	}, "shipLocations")
	lu.assertEquals(q.creditReward, 5000, "creditReward")
	lu.assertEquals(q.itemReward, { { species = { -1 }, item = ITEMS[D13] } }, "itemReward")
end

---------------------------------------------------------------------------------------------
-- AC-3: recovery 14
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineRecovery14 = {}

function TestRsfTier2KaydineRecovery14:setUp() H.reset() end

local function checkRecoveryPath(q, rec, field, column, label)
	local rows = rec:list(column)

	lu.assertEquals(#q[field], #rows, label .. ": number of " .. field)

	for i, value in ipairs(rows) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		lu.assertEquals(zone, q.questZone, label .. ": " .. column .. " zone equals questZone")
		lu.assertEquals(q[field][i], { patrolPointName = name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 },
			label .. ": " .. field .. "[" .. i .. "] (" .. name .. "), no zoneName")
	end
end

-- AC-3
function TestRsfTier2KaydineRecovery14:test_payload_equals_the_fixture()
	local q, rec = quest(R14), fixtureOf(R14)

	lu.assertEquals(q.className, R14, "className")
	lu.assertEquals({ q.questType, q.questName }, { "recovery", "naboo_privateer_14" }, "questType, questName")
	lu.assertEquals(q.questZone, rec:get("questZone"), R14 .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), R14 .. ": recoverShip")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), R14 .. ": arrivalDelay")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), R14 .. ": recoveryDelay")
	lu.assertEquals(q.recoveryConversationMobile, sharedAppearance(rec:get("recoveryAppearance")), R14 .. ": recoveryConversationMobile (shared_ prefix)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), R14 .. ": escortShips (in order)")
	checkRecoveryPath(q, rec, "preRecoveryPoints", "escortPath", R14)
	checkRecoveryPath(q, rec, "recoveryPoints", "recoveryPath", R14)
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), R14 .. ": attackDelay (attackPeriod)")

	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	lu.assertEquals(q.attackShips, lists, R14 .. ": attackShips (column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, R14 .. ": tauntData (max(numResponses, 1))")
	lu.assertFalse(q.sideQuest and true or false, R14 .. ": sideQuest")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { "", "", "" }, R14 .. ": parent fields")
end

-- AC-3: the literals of the contract
function TestRsfTier2KaydineRecovery14:test_literal_payload_and_reward()
	local q = quest(R14)

	lu.assertEquals({ q.recoverShip, q.arrivalDelay, q.recoveryDelay }, { "aynat_yacht_tier3", 12, 30 }, "recoverShip, arrivalDelay, recoveryDelay")
	lu.assertEquals(q.recoveryConversationMobile, "object/mobile/shared_space_comm_aynat_ace_04.iff", "recoveryConversationMobile")
	lu.assertEquals(q.escortShips, { "aynat_enforcer_tier2", "aynat_ghost_tier2" }, "escortShips")
	lu.assertEquals(q.preRecoveryPoints, {
		{ patrolPointName = "naboo_privateer_tier2_recovery_escort_1", x = 5000, z = -1500, y = 1000, escortNumber = 1, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier2_recovery_escort_2", x = 2000, z = -750, y = -1000, escortNumber = 2, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier2_recovery_escort_3", x = 0, z = 0, y = -3500, escortNumber = 3, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier2_recovery_escort_4", x = -1200, z = 500, y = -4500, escortNumber = 4, radius = 250 },
	}, "preRecoveryPoints")
	lu.assertEquals(q.recoveryPoints, {
		{ patrolPointName = "naboo_privateer_tier2_recovery_egress_1", x = -1800, z = 0, y = -3500, escortNumber = 1, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier2_recovery_egress_2", x = -3500, z = 100, y = -2200, escortNumber = 2, radius = 250 },
		{ patrolPointName = "naboo_privateer_tier2_recovery_egress_3", x = -5100, z = 350, y = -1000, escortNumber = 3, radius = 250 },
	}, "recoveryPoints")
	lu.assertEquals(q.attackDelay, 120, "attackDelay")
	lu.assertEquals(q.attackShips, { { "aynat_enforcer_tier2", "aynat_enforcer_tier2" }, { "aynat_ghost_tier2", "aynat_ghost_tier2" } }, "attackShips")
	lu.assertEquals(q.tauntData, { panicCount = 5, thanksCount = 5 }, "tauntData")
	lu.assertEquals(q.creditReward, 5000, "creditReward")
	lu.assertEquals(q.itemReward, { { species = { -1 }, item = ITEMS[R14] } }, "itemReward")
end

---------------------------------------------------------------------------------------------
-- AC-4: escort 15
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineEscort15 = {}

function TestRsfTier2KaydineEscort15:setUp() H.reset() end

-- AC-4
function TestRsfTier2KaydineEscort15:test_payload_equals_the_fixture()
	local q, rec = quest(E15), fixtureOf(E15)

	lu.assertEquals(q.className, E15, "className")
	lu.assertEquals({ q.questType, q.questName }, { "escort", "naboo_privateer_15" }, "questType, questName")
	lu.assertEquals(q.questZone, rec:get("questZone"), E15 .. ": questZone")
	lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, E15 .. ": escortShips (escortShipType)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), E15 .. ": attackDelay (attackPeriod)")

	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	lu.assertEquals(q.attackShips, lists, E15 .. ": attackShips (column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, E15 .. ": tauntData (max(numResponses, 1))")

	local rows = rec:list("escortPath")

	lu.assertEquals(#q.escortPoints, #rows, E15 .. ": number of escortPoints")

	for i, value in ipairs(rows) do
		local zone, pointName = H.Tab.splitNavPoint(value)
		local p = point(zone, pointName)

		lu.assertEquals(zone, q.questZone, E15 .. ": escortPath zone equals questZone")
		lu.assertEquals(q.escortPoints[i], { patrolPointName = pointName, zoneName = q.questZone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }, E15 .. ": escortPoints[" .. i .. "] (" .. pointName .. ")")
	end

	lu.assertFalse(q.sideQuest and true or false, E15 .. ": sideQuest")
	lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { "", "", "" }, E15 .. ": parent fields")
end

-- AC-4: the literals of the contract
function TestRsfTier2KaydineEscort15:test_literal_payload_and_reward()
	local q = quest(E15)

	lu.assertEquals(q.escortShips, { "rsf_prison_ship_tier3" }, "escortShips")
	lu.assertEquals(q.escortPoints, {
		{ patrolPointName = "privateer_tier2_escort_4", zoneName = "space_naboo", x = 581, z = -89, y = -2524, escortNumber = 1, radius = 250 },
		{ patrolPointName = "privateer_tier2_escort_5", zoneName = "space_naboo", x = 646, z = -1687, y = -1161, escortNumber = 2, radius = 250 },
		{ patrolPointName = "privateer_tier2_escort_6", zoneName = "space_naboo", x = -323, z = -3430, y = 709, escortNumber = 3, radius = 250 },
		{ patrolPointName = "privateer_tier2_escort_7", zoneName = "space_naboo", x = -1933, z = -3233, y = 808, escortNumber = 4, radius = 250 },
	}, "escortPoints")
	lu.assertEquals(q.attackDelay, 120, "attackDelay")
	lu.assertEquals(q.attackShips, { { "aynat_enforcer_tier2", "aynat_ghost_tier2", "aynat_intimidator_tier2", "aynat_outlaw_tier2" } }, "attackShips")
	lu.assertEquals(q.tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, "tauntData")
	lu.assertEquals(q.creditReward, 5000, "creditReward")
	lu.assertEquals(q.itemReward, { { species = { -1 }, item = ITEMS[E15] } }, "itemReward")
end

---------------------------------------------------------------------------------------------
-- AC-5: identity (I-1, I-2, I-3)
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineIdentity = {}

function TestRsfTier2KaydineIdentity:setUp() H.reset() end

-- AC-5, I-1
function TestRsfTier2KaydineIdentity:test_the_four_invented_tables_are_nil_and_not_registered()
	for _, name in ipairs(DELETED) do
		lu.assertNil(rawget(_G, name), name .. ": global must be gone")
		lu.assertNil(H.registered(name), name .. ": registerScreenPlay must be gone")
	end
end

-- AC-5, I-1
function TestRsfTier2KaydineIdentity:test_the_six_new_tables_are_registered_as_started_screenplays_under_their_own_names()
	for _, name in ipairs(NEW_GLOBALS) do
		local q = quest(name)

		lu.assertEquals(q.className, name, name .. ": className")
		lu.assertEquals(q.questType .. "_" .. q.questName, name, name .. ": questType_questName")
		lu.assertEquals(q.questZone, "space_naboo", name .. ": questZone")
		lu.assertNotNil(H.registered(name), name .. ": registerScreenPlay was called")
		lu.assertTrue(H.registered(name).start, name .. ": registered with start = true")
	end
end

-- AC-5, I-1
function TestRsfTier2KaydineIdentity:test_there_are_165_space_quest_globals()
	lu.assertEquals(#H.questGlobals(), 165, "space quest globals (CorSec, Havoc and RSF loaded)")
end

-- AC-5, I-2
function TestRsfTier2KaydineIdentity:test_exactly_the_four_mission_heads_pay_5000_credits_and_an_item()
	local paying = {}

	for _, name in ipairs(NEW_GLOBALS) do
		if quest(name).creditReward ~= 0 or #quest(name).itemReward ~= 0 then
			paying[#paying + 1] = name
		end
	end

	lu.assertEquals(paying, { A1, D13, R14, E15 }, "globals with a reward")

	for _, name in ipairs(paying) do
		lu.assertEquals(quest(name).creditReward, 5000, name .. ": creditReward")
		lu.assertEquals(#quest(name).itemReward, 1, name .. ": number of items")
	end
end

-- AC-5, I-3
function TestRsfTier2KaydineIdentity:test_the_chains_walk_the_new_tables_in_order()
	local function names(head)
		local out = {}

		for i, member in ipairs(SpaceHelpers:getSpaceQuestChain(head)) do
			out[i] = member.global
		end

		return out
	end

	lu.assertEquals(names(A1), { A1, A2, A3 }, "mission 1 chain")
	lu.assertEquals(names(D13), { D13 }, "mission 2 chain")
	lu.assertEquals(names(R14), { R14 }, "mission 3 chain")
	lu.assertEquals(names(E15), { E15 }, "mission 4 chain")
end

-- AC-5, I-3: every split names an existing table that names it back
function TestRsfTier2KaydineIdentity:test_every_split_has_a_target_that_names_it_as_parent()
	for _, name in ipairs(NEW_GLOBALS) do
		local q = quest(name)

		if q.sideQuest then
			local target = rawget(_G, q.sideQuestType .. "_" .. q.sideQuestName)

			lu.assertNotNil(target, name .. ": split target " .. q.sideQuestType .. "_" .. q.sideQuestName)
			lu.assertEquals({ target.questType, target.questName }, { q.sideQuestType, q.sideQuestName }, name .. ": target type, name")
			lu.assertEquals({ target.parentQuest, target.parentQuestType, target.parentQuestName }, { name, q.questType, q.questName }, name .. ": the target names it back")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: constants, legacy data, step names (Content contract 2, I-11, I-12)
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineConstants = {}

function TestRsfTier2KaydineConstants:setUp() H.reset() end

-- AC-5
function TestRsfTier2KaydineConstants:test_the_tier_2_quest_strings_equal_the_contract()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.TIER2_QUEST_STRING_1, { type = "assassinate", name = "naboo_privateer_tier2_1a" }, "TIER2_QUEST_STRING_1")
	lu.assertEquals(R.TIER2_QUEST_STRING_1_SIDE1, { type = "assassinate", name = "naboo_privateer_tier2_1b" }, "TIER2_QUEST_STRING_1_SIDE1")
	lu.assertEquals(R.TIER2_QUEST_STRING_1_SIDE2, { type = "assassinate", name = "naboo_privateer_tier2_1c" }, "TIER2_QUEST_STRING_1_SIDE2")
	lu.assertEquals(R.TIER2_QUEST_STRING_2, { type = "destroy", name = "naboo_privateer_13" }, "TIER2_QUEST_STRING_2")
	lu.assertEquals(R.TIER2_QUEST_STRING_3, { type = "recovery", name = "naboo_privateer_14" }, "TIER2_QUEST_STRING_3")
	lu.assertEquals(R.TIER2_QUEST_STRING_4, { type = "escort", name = "naboo_privateer_15" }, "TIER2_QUEST_STRING_4")
end

-- AC-5, I-11; rsf-tier2-kaydine-duties AC-2: the duty strings follow SWG's menu order, escort, recovery, destroy (D-11)
function TestRsfTier2KaydineConstants:test_the_duty_strings_follow_the_swg_menu_order_and_there_is_no_fourth()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_1, { type = "escort_duty", name = "naboo_privateer_9" }, "TIER2_QUEST_STRING_DUTY_1")
	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_2, { type = "recovery_duty", name = "naboo_privateer_10" }, "TIER2_QUEST_STRING_DUTY_2")
	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_3, { type = "destroy_duty", name = "naboo_privateer_11" }, "TIER2_QUEST_STRING_DUTY_3")
	lu.assertNil(R.TIER2_QUEST_STRING_DUTY_4, "TIER2_QUEST_STRING_DUTY_4 no longer exists")

	for _, name in ipairs({ "escort_duty_naboo_privateer_9", "recovery_duty_naboo_privateer_10", "destroy_duty_naboo_privateer_11" }) do
		lu.assertNotNil(H.registered(name), name .. ": registered")
	end
end

-- AC-5, I-11; rsf-tier2-kaydine-duties AC-3: privateer_escort_4 stays, the 11 invented duty points are gone (the rest is in test_rsf_tier2_kaydine_duties_data.lua)
function TestRsfTier2KaydineConstants:test_the_tier_1_escort_points_stay_and_the_invented_duty_points_are_gone()
	local points = H.patrolPoints("space_naboo")

	lu.assertNotNil(points.commerce_route_1_04, "space_naboo: commerce_route_1_04 must stay (privateer_escort_4 went with rsf-tier1-dinge-data)")

	for _, name in ipairs({ "rsf_duty_patrol_1", "rsf_duty_patrol_2", "rsf_duty_patrol_3", "rsf_duty_patrol_4", "rsf_duty_patrol_5", "rsf_duty_patrol_6",
		"rsf_tier2_duty_escort_1", "rsf_tier2_duty_escort_2", "rsf_tier2_duty_escort_3", "rsf_recovery_1", "rsf_recovery_2" }) do
		lu.assertNil(points[name], "space_naboo: " .. name .. " is still defined")
	end
end

-- AC-5
function TestRsfTier2KaydineConstants:test_the_legacy_tier_2_data_equals_the_contract()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.LEGACY_TIER2_QUESTS, {
		{ type = "destroy", name = "naboo_privateer_13a", moveTo = {
			{ type = "assassinate", name = "naboo_privateer_tier2_1a" },
			{ type = "assassinate", name = "naboo_privateer_tier2_1b" },
			{ type = "assassinate", name = "naboo_privateer_tier2_1c" },
		} },
		{ type = "escort", name = "naboo_privateer_14", moveTo = { { type = "destroy", name = "naboo_privateer_13" } } },
		{ type = "inspect", name = "naboo_privateer_15", moveTo = { { type = "recovery", name = "naboo_privateer_14" } } },
		{ type = "assassinate", name = "naboo_privateer_tier2_4a", moveTo = { { type = "escort", name = "naboo_privateer_15" } } },
	}, "LEGACY_TIER2_QUESTS")
	lu.assertEquals(R.LEGACY_TIER2_STATUS, {
		{ old = "naboo_privateer_13a:attempted", new = "naboo_privateer_tier2_1a:attempted" },
		{ old = "naboo_privateer_13a:reward", new = "naboo_privateer_tier2_1a:reward" },
		{ old = "naboo_privateer_14:attempted", new = "naboo_privateer_13:attempted" },
		{ old = "naboo_privateer_14:reward", new = "naboo_privateer_13:reward" },
		{ old = "naboo_privateer_15:attempted", new = "naboo_privateer_14:attempted" },
		{ old = "naboo_privateer_15:reward", new = "naboo_privateer_14:reward" },
		{ old = "naboo_privateer_tier2_4a:attempted", new = "naboo_privateer_15:attempted" },
		{ old = "naboo_privateer_tier2_4a:reward", new = "naboo_privateer_15:reward" },
	}, "LEGACY_TIER2_STATUS")
	lu.assertEquals(R.LEGACY_MIGRATION_STEPS, { "migrateLegacyTier3", "migrateLegacyTier2", "migrateLegacyTier2Duties" }, "LEGACY_MIGRATION_STEPS")
end

-- AC-5, I-12: a misspelt step name would raise an error in the middle of a conversation
function TestRsfTier2KaydineConstants:test_every_migration_step_name_resolves_to_a_function_on_the_screenplay()
	lu.assertTrue(#RsfSquadronScreenplay.LEGACY_MIGRATION_STEPS >= 3, "at least the three steps")

	for k, name in ipairs(RsfSquadronScreenplay.LEGACY_MIGRATION_STEPS) do
		lu.assertEquals(type(RsfSquadronScreenplay[name]), "function", "LEGACY_MIGRATION_STEPS[" .. k .. "] = '" .. tostring(name) .. "' must be a function on RsfSquadronScreenplay")
	end

	lu.assertEquals(type(RsfSquadronScreenplay.migrateLegacyProgress), "function", "RsfSquadronScreenplay:migrateLegacyProgress")
end

---------------------------------------------------------------------------------------------
-- I-6: no legacy name in live code
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineNoLegacyNames = {}

function TestRsfTier2KaydineNoLegacyNames:setUp() H.reset() end

local LEGACY_PATTERNS = { "naboo_privateer_13a", "naboo_privateer_tier2_4a", "escort_naboo_privateer_14", "inspect_naboo_privateer_15" }

local function readLines(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local out = {}

	for line in f:lines() do
		out[#out + 1] = (line:gsub("\r$", ""))
	end

	f:close()
	return out
end

local function stripComment(line) return (line:gsub("%-%-.*$", "")) end

-- I-6
function TestRsfTier2KaydineNoLegacyNames:test_no_script_names_a_legacy_tier_2_quest_outside_the_rsf_legacy_data()
	local rsfPath = H.SCRIPTS .. "screenplays/space/squadrons/RsfSquadronScreenplay.lua"
	local offenders = {}
	local pipe = assert(io.popen("grep -rIlE '" .. table.concat(LEGACY_PATTERNS, "|") .. "' " .. H.SCRIPTS .. " --include='*.lua' 2>/dev/null"))

	for file in pipe:lines() do
		if file ~= rsfPath then
			offenders[#offenders + 1] = file
		end
	end

	pipe:close()
	table.sort(offenders)
	lu.assertEquals(offenders, {}, "scripts other than RsfSquadronScreenplay.lua that name a legacy tier 2 quest")

	local inBlock, bad = false, {}

	for n, line in ipairs(readLines(rsfPath)) do
		local code = stripComment(line)

		if code:find("LEGACY_TIER3_QUESTS", 1, true) and code:find("=", 1, true) then
			inBlock = true
		end

		if not inBlock then
			for _, pattern in ipairs(LEGACY_PATTERNS) do
				if code:find(pattern, 1, true) then
					bad[#bad + 1] = n .. ": " .. code
				end
			end
		end

		if inBlock and code:find("LEGACY_MIGRATION_STEPS", 1, true) and code:find("=", 1, true) then
			inBlock = false
		end
	end

	lu.assertEquals(bad, {}, "RsfSquadronScreenplay.lua code lines outside the LEGACY_* data that name a legacy tier 2 quest")
end

-- I-6: "escort"/"naboo_privateer_14" and "inspect"/"naboo_privateer_15" are also names of the new quests in other pairs
function TestRsfTier2KaydineNoLegacyNames:test_no_constant_outside_the_legacy_data_pairs_escort_with_14_or_inspect_with_15()
	local pipe = assert(io.popen("grep -rInE '\"escort\".*\"naboo_privateer_14\"|\"inspect\".*\"naboo_privateer_15\"' " .. H.SCRIPTS .. " --include='*.lua' 2>/dev/null"))
	local bad = {}
	local rsfPath = H.SCRIPTS .. "screenplays/space/squadrons/RsfSquadronScreenplay.lua"
	local legacyFrom, legacyTo

	for n, line in ipairs(readLines(rsfPath)) do
		local code = stripComment(line)

		if code:find("LEGACY_TIER3_QUESTS", 1, true) and code:find("=", 1, true) then
			legacyFrom = n
		end

		if code:find("LEGACY_MIGRATION_STEPS", 1, true) and code:find("=", 1, true) then
			legacyTo = n
		end
	end

	for hit in pipe:lines() do
		local file, n = hit:match("^([^:]+):(%d+):")

		if not (file == rsfPath and legacyFrom ~= nil and tonumber(n) >= legacyFrom and tonumber(n) <= (legacyTo or 0)) then
			bad[#bad + 1] = hit
		end
	end

	pipe:close()
	table.sort(bad)
	lu.assertEquals(bad, {}, "pairs of the legacy tier 2 type and name outside the legacy data")
end

---------------------------------------------------------------------------------------------
-- AC-5 (I-5): the 21 real points and the two spawners equal the buildout
---------------------------------------------------------------------------------------------

TestRsfTier2KaydinePoints = {}

function TestRsfTier2KaydinePoints:setUp() H.reset() end

local EXTRACT = "space_zones/buildout/space_naboo.rsf_tier2_points.tab"

local SWG_POINTS = {
	"naboo_privateer_tier2_assassinate_one_1", "naboo_privateer_tier2_assassinate_one_2", "naboo_privateer_tier2_assassinate_one_3", "naboo_privateer_tier2_assassinate_one_4",
	"naboo_imperial_tier2_escortduty_7", "naboo_imperial_tier2_recoveryduty_1", "naboo_imperial_tier3_recovery1_3", "privateer_security_escort_1",
	"privateer_tier2_recovery_2", "privateer_patrol_3",
	"naboo_privateer_tier2_recovery_escort_1", "naboo_privateer_tier2_recovery_escort_2", "naboo_privateer_tier2_recovery_escort_3", "naboo_privateer_tier2_recovery_escort_4",
	"naboo_privateer_tier2_recovery_egress_1", "naboo_privateer_tier2_recovery_egress_2", "naboo_privateer_tier2_recovery_egress_3",
	"privateer_tier2_escort_4", "privateer_tier2_escort_5", "privateer_tier2_escort_6", "privateer_tier2_escort_7",
}

-- nav point name -> { x, z, y } and spawner name -> { x, z, y } of the extract, truncated toward zero
local function buildout()
	local tab = H.fixture(EXTRACT)
	local navs, spawners, nNav, nSpawn = {}, {}, 0, 0

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawner = vars:match("strSpawnerName|4|([^|]+)|")
		local xyz = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }

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

-- AC-5 (the extract itself)
function TestRsfTier2KaydinePoints:test_the_extract_holds_21_nav_points_and_2_spawners()
	local _, _, nNav, nSpawn = buildout()

	lu.assertEquals({ nNav, nSpawn }, { 21, 2 }, "nav_name rows, strSpawnerName rows in " .. EXTRACT)
	lu.assertEquals(#SWG_POINTS, 21, "points listed by the spec")
end

-- AC-5, I-5
function TestRsfTier2KaydinePoints:test_the_21_points_in_core3_equal_the_truncated_buildout_values()
	local navs = buildout()

	for _, name in ipairs(SWG_POINTS) do
		lu.assertNotNil(navs[name], name .. " is in the buildout extract")

		local p = point("space_naboo", name)

		lu.assertEquals({ p.x, p.z, p.y }, navs[name], "space_naboo: " .. name .. " x/z/y equal the truncated buildout fltPX/fltPY/fltPZ")
	end
end

-- AC-5, I-5
function TestRsfTier2KaydinePoints:test_the_two_spawners_in_core3_equal_the_truncated_buildout_values()
	local _, spawners = buildout()

	for _, name in ipairs({ "naboo_privateer_12", "naboo_privateer_13" }) do
		local s = H.spawners("space_naboo")[name]

		lu.assertNotNil(s, "space_naboo spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, spawners[name], "spawner " .. name .. " x/z/y equal the truncated buildout")
	end
end

-- AC-5, I-5: every point and spawner the six tables name resolves, with the inlined coordinates, and they are the 21 + 2
function TestRsfTier2KaydinePoints:test_every_point_the_six_tables_use_resolves_with_its_inlined_coordinates()
	local seenPoints, seenSpawners = {}, {}

	local function walk(global, q, value, path, seen)
		if type(value) ~= "table" or seen[value] then
			return
		end

		seen[value] = true

		if value.patrolPointName ~= nil then
			local p = point(value.zoneName or q.questZone, value.patrolPointName)

			lu.assertEquals({ value.x, value.z, value.y }, { p.x, p.z, p.y }, global .. ": " .. path .. " (" .. value.patrolPointName .. ") coordinates")
			seenPoints[value.patrolPointName] = true
		elseif value.spawnName ~= nil then
			local s = H.spawners(q.questZone)[value.spawnName]

			lu.assertNotNil(s, global .. ": " .. path .. " spawner " .. value.spawnName .. " in " .. q.questZone)
			lu.assertEquals({ value.x, value.z, value.y }, { s.x, s.z, s.y }, global .. ": " .. path .. " (" .. value.spawnName .. ") coordinates")
			seenSpawners[value.spawnName] = true
		end

		for k, v in pairs(value) do
			walk(global, q, v, path .. "." .. tostring(k), seen)
		end
	end

	for _, global in ipairs(NEW_GLOBALS) do
		walk(global, quest(global), quest(global), "", {})
	end

	local names = {}

	for name in pairs(seenPoints) do
		names[#names + 1] = name
	end

	table.sort(names)

	local expected = {}

	for i, name in ipairs(SWG_POINTS) do
		expected[i] = name
	end

	table.sort(expected)
	lu.assertEquals(names, expected, "distinct patrol points named by the six tables")
	lu.assertEquals(seenSpawners, { naboo_privateer_12 = true, naboo_privateer_13 = true }, "spawners named by the six tables")
end

---------------------------------------------------------------------------------------------
-- I-7: the invented points are gone
---------------------------------------------------------------------------------------------

TestRsfTier2KaydineInventedPointsGone = {}

function TestRsfTier2KaydineInventedPointsGone:setUp() H.reset() end

local INVENTED = {
	"rsf_tier2_escort_1", "rsf_tier2_escort_2", "rsf_tier2_escort_3", "rsf_tier2_escort_4", "rsf_tier2_assassinate_1", "rsf_tier2_assassinate_2",
}

-- I-7
function TestRsfTier2KaydineInventedPointsGone:test_none_of_the_six_invented_points_is_defined()
	for _, name in ipairs(INVENTED) do
		lu.assertNil(H.patrolPoints("space_naboo")[name], "space_naboo: " .. name .. " is still defined")
	end
end

-- I-7
function TestRsfTier2KaydineInventedPointsGone:test_no_script_under_bin_scripts_mentions_an_invented_point()
	local args = {}

	for _, name in ipairs(INVENTED) do
		args[#args + 1] = "-e " .. name
	end

	local pipe = io.popen("grep -rnwF --include='*.lua' " .. table.concat(args, " ") .. " " .. H.SCRIPTS .. " 2>&1")
	local out = pipe:read("a")

	pipe:close()
	lu.assertEquals(out, "", "bin/scripts still mentions invented points")
end

-- I-7: the loaded quest globals
function TestRsfTier2KaydineInventedPointsGone:test_no_loaded_quest_global_contains_an_invented_point_name_at_any_depth()
	local set = {}

	for _, name in ipairs(INVENTED) do
		set[name] = true
	end

	local hits = {}

	local function walk(value, path, seen)
		if type(value) == "string" then
			if set[value] then
				hits[#hits + 1] = path .. " = " .. value
			end
		elseif type(value) == "table" and not seen[value] then
			seen[value] = true

			for k, v in pairs(value) do
				if type(k) == "string" and set[k] then
					hits[#hits + 1] = path .. " key " .. k
				end

				walk(v, path .. "." .. tostring(k), seen)
			end
		end
	end

	for _, name in ipairs(H.questGlobals()) do
		walk(rawget(_G, name), name, {})
	end

	table.sort(hits)
	lu.assertEquals(hits, {}, "invented point names in loaded quest globals")
end

-- AC-5: the file keeps its neighbours and its registration call, and loses the two comment lines
function TestRsfTier2KaydineInventedPointsGone:test_the_naboo_point_file_loses_the_two_comments_and_keeps_its_registration()
	local text = readFile(H.SCRIPTS .. "ship_mobile/patrol_points/space_naboo.lua")

	lu.assertNil(text:find("RSF Tier 2 Mission 1: Escort", 1, true), "comment 'RSF Tier 2 Mission 1: Escort' is gone")
	lu.assertNil(text:find("RSF Tier 2 Mission 2: Assassinate", 1, true), "comment 'RSF Tier 2 Mission 2: Assassinate' is gone")
	lu.assertNil(text:find("-- RSF Tier 1 Duty: Patrol", 1, true), "the comment of the orphaned duty block is gone (rsf-tier2-kaydine-duties)")
	lu.assertNotNil(text:find("SpacePatrolPoints:addSpacePatrolPoints(space_naboo, \"space_naboo\")", 1, true), "addSpacePatrolPoints call")
	lu.assertNotNil(H.patrolPoints("space_naboo").commerce_route_1_04, "commerce_route_1_04 stays (privateer_escort_4 went with rsf-tier1-dinge-data)")
	lu.assertNil(H.patrolPoints("space_naboo").rsf_duty_patrol_1, "rsf_duty_patrol_1 is gone (rsf-tier2-kaydine-duties)")
end
