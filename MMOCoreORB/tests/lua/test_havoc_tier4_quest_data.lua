-- Havoc Squadron tier 4 (Warvog Arkon): quest data conformance against SWG-Source.
-- Spec: .claude/work/havoc-tier4-arkon/01-spec.md (AC-9, AC-10, invariants I-2, I-3).
--
-- Mapping (spec "Data mapping"), per .tab record:
--   questZone                          -> questZone
--   triggerEvent = splitquest / none   -> sideQuest = true / false-or-unset
--   triggerSplitCondition both/success/failure
--                                      -> sideQuestSplitType BIDIRECTIONAL / COMPLETION / FAILURE
--   triggerArg  "type:name"            -> sideQuestType, sideQuestName
--   triggerArg2 "type:name"            -> sideFailQuestType, sideFailQuestName
-- Main tables must not set sideQuestType2/sideQuestName2.

local lu = require("luaunit")
local H = require("harness")
local D = require("havoc_tier4_data")

H.loadSquadron("HavocSquadronScreenplay")

local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

local SPLIT_BY_CONDITION = {
	both = SPLIT.BIDIRECTIONAL,
	success = SPLIT.COMPLETION,
	failure = SPLIT.FAILURE,
}

-- The 13 story quests that have a SWG-Source .tab (the duties are unchanged and out of scope).
local STORY = { "m1", "m1a", "m1b", "m2", "m2a", "m2b", "m3", "m3a", "m3b", "m4", "m4a", "m4b", "m4c" }
local MAINS = { "m1", "m2", "m3", "m4" }
local CHILDREN = { "m1a", "m1b", "m2a", "m2b", "m3a", "m3b", "m4a", "m4b", "m4c" }

-- pairs() in sorted key order, so failure messages are stable between runs.
local function sortedPairs(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = k
	end

	table.sort(keys)

	local i = 0

	return function()
		i = i + 1
		return keys[i], t[keys[i]]
	end
end

TestHavocTier4Conformance = {}

function TestHavocTier4Conformance:setUp()
	H.reset()
end

-- AC-9
function TestHavocTier4Conformance:test_each_story_quest_matches_its_swg_source_tab()
	for _, key in ipairs(STORY) do
		local questType, questName = D.QUEST[key][1], D.QUEST[key][2]
		local q = questType .. "/" .. questName
		local quest = H.expectGlobal(questType .. "_" .. questName, "tier 4 quest table for " .. q)
		local rec = H.questFixture(questType, questName)

		lu.assertEquals(quest.questType, questType, q .. ": questType")
		lu.assertEquals(quest.questName, questName, q .. ": questName")
		lu.assertEquals(quest.questZone, rec:get("questZone"), q .. ": questZone")

		local event = rec:get("triggerEvent")

		if event == "splitquest" then
			local condition = rec:get("triggerSplitCondition")
			local sideType, sideName = H.Tab.splitQuestRef(rec:get("triggerArg"))

			lu.assertNotNil(SPLIT_BY_CONDITION[condition], q .. ": fixture triggerSplitCondition '" .. tostring(condition) .. "' is not mapped by this test")
			lu.assertTrue(quest.sideQuest, q .. ": sideQuest (triggerEvent=splitquest)")
			lu.assertEquals(quest.sideQuestSplitType, SPLIT_BY_CONDITION[condition], q .. ": sideQuestSplitType (triggerSplitCondition=" .. condition .. ")")
			lu.assertEquals(quest.sideQuestType, sideType, q .. ": sideQuestType (triggerArg)")
			lu.assertEquals(quest.sideQuestName, sideName, q .. ": sideQuestName (triggerArg)")

			local arg2 = rec:get("triggerArg2")

			if arg2 ~= nil then
				local failType, failName = H.Tab.splitQuestRef(arg2)

				lu.assertEquals(quest.sideFailQuestType, failType, q .. ": sideFailQuestType (triggerArg2)")
				lu.assertEquals(quest.sideFailQuestName, failName, q .. ": sideFailQuestName (triggerArg2)")
			end
		else
			lu.assertEquals(event, "none", q .. ": fixture triggerEvent")
			lu.assertFalse(quest.sideQuest and true or false, q .. ": sideQuest must be false (triggerEvent=none)")
			lu.assertTrue(quest.sideQuestSplitType == nil or quest.sideQuestSplitType == SPLIT.NONE, q .. ": sideQuestSplitType must be NONE or unset")
		end
	end
end

-- AC-9
function TestHavocTier4Conformance:test_four_main_quests_do_not_set_the_unread_second_side_quest_fields()
	for _, key in ipairs(MAINS) do
		local quest = H.expectGlobal(D.global(key))
		local q = D.QUEST[key][1] .. "/" .. D.QUEST[key][2]

		lu.assertNil(rawget(quest, "sideQuestType2"), q .. ": sideQuestType2 (no quest type reads it)")
		lu.assertNil(rawget(quest, "sideQuestName2"), q .. ": sideQuestName2 (no quest type reads it)")
	end
end

-- AC-9
function TestHavocTier4Conformance:test_the_wiring_graph_is_the_one_in_the_spec()
	local expected = {
		m1 = { "space_battle_corellia_rebel_tier4_1_a", "space_battle_corellia_rebel_tier4_1_b" },
		m2 = { "delivery_no_pickup_corellia_rebel_tier4_2_a", "rescue_corellia_rebel_tier4_2_b" },
		m3 = { "space_battle_corellia_rebel_tier4_3_a", "survival_corellia_rebel_tier4_3_b" },
		m4 = { "assassinate_corellia_rebel_tier4_4_a", "rescue_corellia_rebel_tier4_4_b" },
	}

	for key, targets in sortedPairs(expected) do
		local quest = H.expectGlobal(D.global(key))
		local q = D.global(key)

		lu.assertEquals(quest.sideQuestSplitType, SPLIT.BIDIRECTIONAL, q .. ": sideQuestSplitType")
		lu.assertEquals(quest.sideQuestType .. "_" .. quest.sideQuestName, targets[1], q .. ": success leads to")
		lu.assertEquals(quest.sideFailQuestType .. "_" .. quest.sideFailQuestName, targets[2], q .. ": failure leads to")
	end

	local b = H.expectGlobal(D.global("m4b"))
	lu.assertEquals(b.sideQuestSplitType, SPLIT.COMPLETION, "rescue_corellia_rebel_tier4_4_b: sideQuestSplitType")
	lu.assertEquals(b.sideQuestType .. "_" .. b.sideQuestName, "assassinate_corellia_rebel_tier4_4_a", "rescue_corellia_rebel_tier4_4_b: leads to")

	local a = H.expectGlobal(D.global("m4a"))
	lu.assertEquals(a.sideQuestSplitType, SPLIT.COMPLETION, "assassinate_corellia_rebel_tier4_4_a: sideQuestSplitType")
	lu.assertEquals(a.sideQuestType .. "_" .. a.sideQuestName, "space_battle_corellia_rebel_tier4_4_c", "assassinate_corellia_rebel_tier4_4_a: leads to")
end

-- AC-9, I-2
function TestHavocTier4Conformance:test_tier4_constants_hold_the_real_quest_types_and_names()
	for constant, key in sortedPairs(D.CONSTANTS) do
		local value = HavocSquadronScreenplay[constant]

		lu.assertNotNil(value, "HavocSquadronScreenplay." .. constant .. " is defined")
		lu.assertEquals(value.type, D.QUEST[key][1], constant .. ": type")
		lu.assertEquals(value.name, D.QUEST[key][2], constant .. ": name")
	end
end

-- AC-9, I-2
function TestHavocTier4Conformance:test_every_tier4_constant_names_a_registered_quest_global()
	local seen = 0
	local constants = {}

	for k, v in pairs(HavocSquadronScreenplay) do
		if type(k) == "string" and k:match("^TIER4_QUEST_STRING_") then
			constants[k] = v
		end
	end

	for constant, value in sortedPairs(constants) do
		do
			seen = seen + 1

			local global = rawget(_G, value.type .. "_" .. value.name)

			lu.assertNotNil(global, constant .. ": global " .. value.type .. "_" .. value.name .. " exists")
			lu.assertEquals(global.questType, value.type, constant .. ": questType of global")
			lu.assertEquals(global.questName, value.name, constant .. ": questName of global")
		end
	end

	lu.assertTrue(seen >= 17, "expected at least 17 TIER4_QUEST_STRING_* constants, found " .. seen)
end

-- AC-10
function TestHavocTier4Conformance:test_main_quests_carry_the_swg_source_rewards()
	-- Rewards come from corellia_rebel_tier4.java giveReward(...) calls, lines 367-398.
	local base = "object/tangible/ship/components/"
	local expected = {
		m1 = base .. "shield_generator/shd_mission_reward_rebel_taim_military_grade.iff", -- java 367-374
		m2 = base .. "droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff", -- java 375-382
		m3 = base .. "booster/bst_mission_reward_rebel_qualdex_halcyon.iff", -- java 383-390
		m4 = base .. "weapon/wpn_mission_reward_rebel_incom_tricannon.iff", -- java 391-398
	}

	for key, item in sortedPairs(expected) do
		local quest = H.expectGlobal(D.global(key))
		local q = D.global(key)

		lu.assertEquals(quest.creditReward, 10000, q .. ": creditReward")
		lu.assertEquals(quest.itemReward, { { species = { -1 }, item = item } }, q .. ": itemReward")
	end
end

-- AC-10
function TestHavocTier4Conformance:test_child_quests_pay_no_credits()
	for _, key in ipairs(CHILDREN) do
		lu.assertEquals(H.expectGlobal(D.global(key)).creditReward, 0, D.global(key) .. ": creditReward")
	end
end
