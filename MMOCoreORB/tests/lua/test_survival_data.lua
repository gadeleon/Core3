-- Survival quest data and class contract (space-quest-stub-survival).
-- Spec: .claude/work/space-quest-stub-survival/01-spec.md (AC-1, AC-2 static part, I-1, I-2, I-3).
--
-- Mapping (spec "Data mapping"), per SWG-Source survival .tab record:
--   questZone, totalTransmissionTime, timesToUpdateProgress, transmissionStartDelay,
--   delayToFirstAttack, attackPeriod                      -> same field name, equal
--   transmissionPoint "<zone>:<name>"                     -> transmissionPoint.patrolPointName = <name>,
--                                                            x/z/y from ship_mobile/patrol_points/<zone>.lua
--   numAttackShipLists, attackShips<i> (column i = list i)-> #attackShipLists, attackShipLists[i]
--   attackListType sequential/random                      -> ATTACK_LIST_TYPES.SEQUENTIAL / RANDOM

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

S.load()

local LEGACY_KEYS = { "survivalTime", "survivalPoint", "attackDelay", "attackShips", "survivalWaves", "waveDelay" }

local ALL_SURVIVAL = {
	"survival_corellia_privateer_tier3_2_a", "survival_corellia_privateer_tier3_4_a", "survival_naboo_privateer_tier3_3c",
	"survival_naboo_privateer_tier3_4c", "survival_corellia_rebel_tier3_2_b", "survival_corellia_rebel_tier3_4_d",
	"survival_corellia_rebel_tier4_1", "survival_corellia_rebel_tier4_3_b",
}

-- Every global that is a survival quest instance, sorted.
local function survivalGlobals()
	local out = {}

	for _, n in ipairs(H.questGlobals()) do
		local q = rawget(_G, n)

		if q.questType == "survival" then
			out[#out + 1] = n
		end
	end

	return out
end

TestSurvivalConformance = {}

function TestSurvivalConformance:setUp()
	H.reset()
end

-- AC-1, I-1
function TestSurvivalConformance:test_scalar_fields_match_the_swg_source_tab_for_every_quest()
	for _, name in ipairs(S.NAMES) do
		local q = "survival/" .. name
		local o = S.oracle(name)
		local quest = H.expectGlobal("survival_" .. name, "survival quest table for " .. q)

		lu.assertEquals(quest.questZone, o.zone, q .. ": questZone")
		lu.assertEquals(quest.totalTransmissionTime, o.total, q .. ": totalTransmissionTime")
		lu.assertEquals(quest.timesToUpdateProgress, o.updates, q .. ": timesToUpdateProgress")
		lu.assertEquals(quest.transmissionStartDelay, o.transStart, q .. ": transmissionStartDelay")
		lu.assertEquals(quest.delayToFirstAttack, o.firstAttack, q .. ": delayToFirstAttack")
		lu.assertEquals(quest.attackPeriod, o.period, q .. ": attackPeriod")
		lu.assertEquals(quest.attackListType, o.listType, q .. ": attackListType (0 = sequential, 1 = random in the .tab enum)")
	end
end

-- AC-1, I-1
function TestSurvivalConformance:test_transmission_point_is_the_named_patrol_point_with_inlined_coordinates()
	for _, name in ipairs(S.NAMES) do
		local q = "survival/" .. name
		local o = S.oracle(name)
		local quest = H.expectGlobal("survival_" .. name, "survival quest table for " .. q)
		local point = quest.transmissionPoint

		lu.assertEquals(type(point), "table", q .. ": transmissionPoint is a table")
		lu.assertEquals(o.pointZone, o.zone, q .. ": fixture transmissionPoint zone equals questZone (spec precondition)")
		lu.assertEquals(point.patrolPointName, o.pointName, q .. ": transmissionPoint.patrolPointName")
		lu.assertEquals(point.x, o.x, q .. ": transmissionPoint.x")
		lu.assertEquals(point.z, o.z, q .. ": transmissionPoint.z")
		lu.assertEquals(point.y, o.y, q .. ": transmissionPoint.y")
	end
end

-- AC-1, I-1
function TestSurvivalConformance:test_attack_lists_are_the_tab_columns_not_the_rows()
	for _, name in ipairs(S.NAMES) do
		local q = "survival/" .. name
		local o = S.oracle(name)
		local quest = H.expectGlobal("survival_" .. name, "survival quest table for " .. q)

		lu.assertEquals(type(quest.attackShipLists), "table", q .. ": attackShipLists is a table")
		lu.assertEquals(#quest.attackShipLists, #o.lists, q .. ": #attackShipLists == numAttackShipLists")

		for i, list in ipairs(o.lists) do
			lu.assertEquals(quest.attackShipLists[i], list, q .. ": attackShipLists[" .. i .. "] (column attackShips" .. i .. ")")
		end
	end
end

-- AC-1
function TestSurvivalConformance:test_a_sixth_column_beyond_numAttackShipLists_is_not_ported()
	-- corellia_rebel_tier3_2_b.tab has data in attackShips6 but numAttackShipLists = 5.
	local rec = H.questFixture("survival", "corellia_rebel_tier3_2_b")

	lu.assertEquals(rec:num("numAttackShipLists"), 5, "fixture numAttackShipLists")
	lu.assertTrue(#rec:list("attackShips6") > 0, "fixture still carries an unused sixth column")

	local lists = H.expectGlobal("survival_corellia_rebel_tier3_2_b").attackShipLists
	lu.assertEquals(type(lists), "table", "survival/corellia_rebel_tier3_2_b: attackShipLists is a table")
	lu.assertEquals(#lists, 5, "survival/corellia_rebel_tier3_2_b: #attackShipLists")
end

-- AC-1
function TestSurvivalConformance:test_the_lists_match_the_spec_tables_for_the_two_quests_the_spec_spells_out()
	-- Independent of the fixture reader: two lists copied from the spec's "Attack lists" section.
	local rebel41 = H.expectGlobal("survival_corellia_rebel_tier4_1").attackShipLists
	lu.assertEquals(type(rebel41), "table", "survival/corellia_rebel_tier4_1: attackShipLists is a table")

	lu.assertEquals(rebel41[1], { "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4" }, "survival/corellia_rebel_tier4_1: list 1")
	lu.assertEquals(rebel41[3], { "blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_marauder_tier4", "blacksun_fighter_s03_tier4" }, "survival/corellia_rebel_tier4_1: list 3")

	local privateer22a = H.expectGlobal("survival_corellia_privateer_tier3_2_a").attackShipLists
	lu.assertEquals(type(privateer22a), "table", "survival/corellia_privateer_tier3_2_a: attackShipLists is a table")

	lu.assertEquals(privateer22a[4], { "blacksun_bomber_s03_tier4", "blacksun_fighter_s01_tier3", "blacksun_fighter_s03_tier3" }, "survival/corellia_privateer_tier3_2_a: list 4")
end

-- AC-1 (spec D-4)
function TestSurvivalConformance:test_corsec_tier3_2_a_runs_in_dathomir_like_the_tab()
	lu.assertEquals(H.expectGlobal("survival_corellia_privateer_tier3_2_a").questZone, "space_dathomir")
end

-- AC-1, I-1
function TestSurvivalConformance:test_corellia_rebel_tier4_3_b_has_its_missing_fourth_list_back()
	-- Havoc's old table lost a row; the .tab has four lists, the last led by an aggressor.
	local lists = H.expectGlobal("survival_corellia_rebel_tier4_3_b").attackShipLists

	lu.assertEquals(type(lists), "table", "survival/corellia_rebel_tier4_3_b: attackShipLists is a table")
	lu.assertEquals(#lists, 4, "survival/corellia_rebel_tier4_3_b: #attackShipLists")
	lu.assertEquals(lists[4][1], "imp_tie_aggressor_tier4", "survival/corellia_rebel_tier4_3_b: list 4 first ship")
end

TestSurvivalContract = {}

function TestSurvivalContract:setUp()
	H.reset()
end

-- Content contract
function TestSurvivalContract:test_the_class_keeps_its_name_and_registration()
	lu.assertEquals(SpaceSurvivalScreenplay.className, "SpaceSurvivalScreenplay")
	lu.assertNotNil(H.registered("SpaceSurvivalScreenplay"), "registerScreenPlay('SpaceSurvivalScreenplay', false)")
	lu.assertFalse(H.registered("SpaceSurvivalScreenplay").start, "no load-time start")
end

-- Content contract
function TestSurvivalContract:test_attack_list_type_enum_is_sequential_0_random_1()
	lu.assertEquals(SpaceSurvivalScreenplay.ATTACK_LIST_TYPES, { SEQUENTIAL = 0, RANDOM = 1 })
end

-- Content contract
function TestSurvivalContract:test_tuning_constants_from_survival_java_are_on_the_class()
	local expected = {
		arrivalRadius = 150, maxDistance = 2000, distanceCheckInterval = 30, endMissionDelay = 5, firstWaveDelay = 5,
		maxActiveWaves = 2, spawnMinDistance = 1000, spawnMaxDistance = 1200, spawnSpread = 150, squadronMinSize = 4,
	}

	for field, value in pairs(expected) do
		lu.assertEquals(SpaceSurvivalScreenplay[field], value, "SpaceSurvivalScreenplay." .. field)
	end
end

-- Content contract
function TestSurvivalContract:test_per_quest_data_fields_have_class_defaults()
	lu.assertEquals(SpaceSurvivalScreenplay.transmissionPoint, {})
	lu.assertEquals(SpaceSurvivalScreenplay.totalTransmissionTime, 0)
	lu.assertEquals(SpaceSurvivalScreenplay.timesToUpdateProgress, 0)
	lu.assertEquals(SpaceSurvivalScreenplay.transmissionStartDelay, 0)
	lu.assertEquals(SpaceSurvivalScreenplay.delayToFirstAttack, 0)
	lu.assertEquals(SpaceSurvivalScreenplay.attackShipLists, {})
	lu.assertEquals(SpaceSurvivalScreenplay.attackPeriod, 0)
	lu.assertEquals(SpaceSurvivalScreenplay.attackListType, 0)
end

-- Content contract
function TestSurvivalContract:test_public_methods_exist()
	for _, method in ipairs({ "startQuest", "completeQuest", "failQuest", "resetQuest", "enteredZone", "notifyEnteredQuestArea",
		"notifyAttackShipDestroyed", "cleanUpQuestData" }) do
		lu.assertEquals(type(SpaceSurvivalScreenplay[method]), "function", "SpaceSurvivalScreenplay:" .. method)
	end
end

-- I-2
function TestSurvivalContract:test_no_survival_quest_keeps_a_legacy_data_key()
	local globals = survivalGlobals()

	for _, expected in ipairs(ALL_SURVIVAL) do
		lu.assertEquals(rawget(_G, expected) ~= nil, true, "survival quest global " .. expected .. " exists")
	end

	for _, n in ipairs(globals) do
		for _, key in ipairs(LEGACY_KEYS) do
			lu.assertNil(rawget(_G[n], key), n .. ": legacy key " .. key)
		end
	end
end

-- I-3, AC-2
function TestSurvivalContract:test_only_the_rsf_placeholder_has_its_own_start_quest()
	for _, n in ipairs(survivalGlobals()) do
		local own = rawget(_G[n], "startQuest")

		if n == "survival_naboo_privateer_tier3_4c" then
			lu.assertEquals(type(own), "function", n .. ": local override of startQuest (decision D-3)")
		else
			lu.assertNil(own, n .. ": must inherit startQuest from SpaceSurvivalScreenplay")
		end
	end
end

-- I-3
function TestSurvivalContract:test_every_survival_quest_but_the_placeholder_has_a_transmission_point()
	for _, n in ipairs(survivalGlobals()) do
		local point = _G[n].transmissionPoint

		lu.assertEquals(type(point), "table", n .. ": transmissionPoint is a table")

		if n == "survival_naboo_privateer_tier3_4c" then
			lu.assertNil(point.patrolPointName, n .. ": the placeholder has no SWG survival data")
		else
			lu.assertEquals(type(point.patrolPointName), "string", n .. ": transmissionPoint.patrolPointName")
		end
	end
end

-- Content contract: only the listed fields change; wiring, rewards and parents stay as they were
-- (spec "Out of scope" and Data mapping last row). Values pinned from the tables before this slice.
function TestSurvivalContract:test_wiring_rewards_and_parents_are_untouched()
	local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	local expected = {
		survival_corellia_privateer_tier3_2_a = { creditReward = 0, parent = "inspect_corellia_privateer_tier3_2", side = "delivery_corellia_privateer_tier3_2_b", split = SPLIT.COMPLETION, delay = 4 },
		survival_corellia_privateer_tier3_4_a = { creditReward = 0, parent = "assassinate_corellia_privateer_tier3_4", side = false },
		survival_naboo_privateer_tier3_3c = { creditReward = 25000, parent = "delivery_naboo_privateer_tier3_3b", side = false },
		survival_naboo_privateer_tier3_4c = { creditReward = 0, parent = "space_battle_naboo_privateer_tier3_4b", side = "assassinate_naboo_privateer_tier3_4f", split = SPLIT.COMPLETION, delay = 3 },
		survival_corellia_rebel_tier3_2_b = { creditReward = 0, parent = "delivery_corellia_rebel_tier3_2_a", side = "escort_corellia_rebel_tier3_2_c", split = SPLIT.COMPLETION, delay = 0 },
		survival_corellia_rebel_tier3_4_d = { creditReward = 0, parent = "space_battle_corellia_rebel_tier3_4_c", side = false },
		survival_corellia_rebel_tier4_1 = { creditReward = 10000, parent = "", side = "space_battle_corellia_rebel_tier4_1_a", split = SPLIT.BIDIRECTIONAL, fail = "space_battle_corellia_rebel_tier4_1_b", delay = 2 },
		survival_corellia_rebel_tier4_3_b = { creditReward = 0, parent = "space_battle_corellia_rebel_tier4_3", side = false },
	}

	for n, e in pairs(expected) do
		local q = H.expectGlobal(n)

		lu.assertEquals(q.className, n, n .. ": className")
		lu.assertEquals(q.questType, "survival", n .. ": questType")
		lu.assertEquals("survival_" .. q.questName, n, n .. ": questName")
		lu.assertEquals(q.creditReward, e.creditReward, n .. ": creditReward")
		lu.assertEquals(q.parentQuest or "", e.parent, n .. ": parentQuest")

		if e.side then
			lu.assertTrue(q.sideQuest, n .. ": sideQuest")
			lu.assertEquals(q.sideQuestType .. "_" .. q.sideQuestName, e.side, n .. ": side quest")
			lu.assertEquals(q.sideQuestSplitType, e.split, n .. ": sideQuestSplitType")
			lu.assertEquals(q.sideQuestDelay, e.delay, n .. ": sideQuestDelay")
		else
			lu.assertFalse(q.sideQuest and true or false, n .. ": sideQuest")
		end

		if e.fail then
			lu.assertEquals(q.sideFailQuestType .. "_" .. q.sideFailQuestName, e.fail, n .. ": failure split quest")
		end
	end
end

TestSurvivalPlaceholder = {}

function TestSurvivalPlaceholder:setUp()
	H.reset()
end

-- AC-2 (D-3)
function TestSurvivalPlaceholder:test_the_rsf_placeholder_has_no_survival_data_left()
	local q = H.expectGlobal("survival_naboo_privateer_tier3_4c")

	lu.assertNil(rawget(q, "survivalWaves"), "survivalWaves")
	lu.assertNil(rawget(q, "waveDelay"), "waveDelay")
	lu.assertEquals(q.questZone, "space_lok")
	lu.assertEquals(q.questType, "survival")
	lu.assertEquals(q.questName, "naboo_privateer_tier3_4c")
end
