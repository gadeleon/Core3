-- Worked example of an SWG-Source conformance test, written against content that already
-- exists (CorSec tier 1, mission 1). Copy this pattern for new ports: load the Core3 quest
-- table, load the fixture copied from SWG-Source, and compare each mapped field with the
-- quest name and field in the failure message.
--
-- Mapping used here (patrol + surprise-attack split):
--   questZone                      -> questZone
--   navPoints  "zone:name" (rows)  -> patrolPoints[i].patrolPointName, in order; coordinates
--                                     must equal Core3's ship_mobile/patrol_points entry
--   triggerEvent=splitquest,
--   triggerArg "type:name"         -> sideQuest=true, sideQuestType, sideQuestName
--   triggerOn                      -> sideQuestPatrolStart
--   triggerDelay                   -> sideQuestDelay
--   (surprise attack) triggerArg   -> parentQuestType / parentQuestName
--   (surprise attack) shipType     -> set of ship names in surpriseAttackShips.spawns
-- Ship counts are not compared here: how SWG-Source's single shipCount maps onto Core3's
-- per-ship counts is a decision for the spec that ports a given quest.

local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("CorsecSquadronScreenplay")

local function shipNameSet(spawns)
	local set = {}

	for _, s in ipairs(spawns) do
		set[s.shipName] = true
	end

	return set
end

TestCorsecTier1Conformance = {}

function TestCorsecTier1Conformance:test_patrol_corellia_privateer_1_matches_swg_source()
	local quest = H.expectGlobal("patrol_corellia_privateer_1")
	local rec = H.questFixture("patrol", "corellia_privateer_1")
	local q = "patrol/corellia_privateer_1"

	lu.assertEquals(quest.questType, "patrol", q .. ": questType")
	lu.assertEquals(quest.questName, "corellia_privateer_1", q .. ": questName")
	lu.assertEquals(quest.questZone, rec:get("questZone"), q .. ": questZone")

	local navPoints = rec:list("navPoints")
	lu.assertEquals(#quest.patrolPoints, #navPoints, q .. ": number of patrol points")

	local zonePoints = H.patrolPoints(quest.questZone)

	for i, nav in ipairs(navPoints) do
		local zone, name = H.Tab.splitNavPoint(nav)
		local point = quest.patrolPoints[i]

		lu.assertEquals(zone, quest.questZone, q .. ": navPoints[" .. i .. "] zone")
		lu.assertEquals(point.patrolPointName, name, q .. ": patrolPoints[" .. i .. "] name")

		local known = zonePoints[name]
		lu.assertNotNil(known, q .. ": " .. name .. " missing from ship_mobile/patrol_points/" .. zone .. ".lua")
		lu.assertEquals({ point.x, point.z, point.y }, { known.x, known.z, known.y }, q .. ": " .. name .. " coordinates")
	end

	lu.assertEquals(rec:get("triggerEvent"), "splitquest", q .. ": fixture triggerEvent")

	local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))
	lu.assertTrue(quest.sideQuest, q .. ": sideQuest")
	lu.assertEquals(quest.sideQuestType, sideType, q .. ": sideQuestType")
	lu.assertEquals(quest.sideQuestName, sideName, q .. ": sideQuestName")
	lu.assertEquals(quest.sideQuestPatrolStart, rec:num("triggerOn"), q .. ": sideQuestPatrolStart (triggerOn)")
	lu.assertEquals(quest.sideQuestDelay, rec:num("triggerDelay"), q .. ": sideQuestDelay (triggerDelay)")
end

function TestCorsecTier1Conformance:test_surprise_attack_corellia_privateer_1_matches_swg_source()
	local quest = H.expectGlobal("destroy_surpriseattack_corellia_privateer_1")
	local rec = H.questFixture("destroy_surpriseattack", "corellia_privateer_1")
	local q = "destroy_surpriseattack/corellia_privateer_1"

	lu.assertEquals(quest.questZone, rec:get("questZone"), q .. ": questZone")
	lu.assertEquals(quest.surpriseAttackShips.zone, rec:get("questZone"), q .. ": surpriseAttackShips.zone")

	local parentType, parentName = H.Tab.splitQuestRef(rec:get("triggerArg"))
	lu.assertEquals(quest.parentQuestType, parentType, q .. ": parentQuestType")
	lu.assertEquals(quest.parentQuestName, parentName, q .. ": parentQuestName")

	local expected = {}

	for _, ship in ipairs(rec:list("shipType")) do
		expected[ship] = true
	end

	lu.assertEquals(shipNameSet(quest.surpriseAttackShips.spawns), expected, q .. ": ship types")
end

function TestCorsecTier1Conformance:test_quests_are_registered_to_start()
	for _, name in ipairs({ "patrol_corellia_privateer_1", "destroy_surpriseattack_corellia_privateer_1" }) do
		local reg = H.registered(name)
		lu.assertNotNil(reg, name .. " registered with registerScreenPlay")
		lu.assertTrue(reg.start, name .. " registered with start = true")
	end
end
