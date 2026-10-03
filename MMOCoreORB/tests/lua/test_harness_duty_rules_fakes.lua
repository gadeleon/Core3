-- Harness changes for space-quest-duty-rules: a fake journal that refuses to re-activate a completed
-- entry (PlayerObjectImplementation.cpp:3192), a quest CRC on fake missions, and failQuestMission /
-- removeQuestMission that take the datapad mission away. These tests exercise the fakes only; they
-- pass without any production change.

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.boot()

TestDutyRulesFakes = {}

function TestDutyRulesFakes:setUp() H.reset() end

local function mission(player, questType, questName)
	local m = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	m:setQuestType(questType)
	m:setQuestName(questName)

	return m
end

function TestDutyRulesFakes:test_activating_a_completed_entry_does_nothing()
	local p = H.newPlayer({})
	local crc = H.questCrc("recovery_duty", "viopa_rebel_7")

	p.ghost:activateJournalQuest(crc, false)
	p.ghost:completeJournalQuest(crc, false)
	p.ghost:activateJournalQuest(crc, false)

	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "stays inactive")
	lu.assertTrue(p.ghost:isJournalQuestComplete(crc), "stays complete")
end

function TestDutyRulesFakes:test_clearing_a_completed_entry_lets_it_activate_again()
	local p = H.newPlayer({})
	local crc = H.questCrc("recovery_duty", "viopa_rebel_7")

	p.ghost:activateJournalQuest(crc, false)
	p.ghost:completeJournalQuest(crc, false)
	p.ghost:clearJournalQuest(crc, false)
	p.ghost:activateJournalQuest(crc, false)

	lu.assertTrue(p.ghost:isJournalQuestActive(crc), "active")
	lu.assertFalse(p.ghost:isJournalQuestComplete(crc), "not complete")
end

function TestDutyRulesFakes:test_a_player_built_with_a_completed_entry_cannot_activate_it()
	local crc = H.questCrc("survival", "corellia_rebel_tier4_1")
	local p = H.newPlayer({ completedQuests = { crc } })

	p.ghost:activateJournalQuest(crc, false)

	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "stays inactive")
end

function TestDutyRulesFakes:test_a_mission_reports_the_crc_of_its_type_and_name()
	local p = H.newPlayer({})
	local m = mission(p, "patrol", "corellia_privateer_1")

	lu.assertEquals(m:getQuestCRC(), H.questCrc("patrol", "corellia_privateer_1"), "getQuestCRC")
end

function TestDutyRulesFakes:test_fail_quest_mission_removes_the_first_matching_mission_and_records_the_crc()
	local p = H.newPlayer({})
	local a = mission(p, "patrol", "corellia_privateer_1")
	local b = mission(p, "survival", "corellia_privateer_2")
	local crc = H.questCrc("patrol", "corellia_privateer_1")

	CreatureObject(p):failQuestMission(crc)

	lu.assertEquals(#p.datapad.items, 1, "one mission left")
	lu.assertIs(p.datapad.items[1], b, "the other mission stays")
	lu.assertEquals(p.failedMissions, { crc }, "failedMissions")
	lu.assertNotIs(p.datapad.items[1], a, "the failed mission is gone")
end

function TestDutyRulesFakes:test_fail_quest_mission_for_an_unknown_crc_removes_nothing_but_is_recorded()
	local p = H.newPlayer({})

	mission(p, "patrol", "corellia_privateer_1")
	CreatureObject(p):failQuestMission(42)

	lu.assertEquals(#p.datapad.items, 1, "datapad")
	lu.assertEquals(p.failedMissions, { 42 }, "failedMissions")
end

function TestDutyRulesFakes:test_remove_quest_mission_removes_the_mission_without_recording_a_fail()
	local p = H.newPlayer({})
	local crc = H.questCrc("patrol", "corellia_privateer_1")

	mission(p, "patrol", "corellia_privateer_1")
	CreatureObject(p):removeQuestMission(crc)

	lu.assertEquals(#p.datapad.items, 0, "datapad")
	lu.assertEquals(p.failedMissions, {}, "failedMissions")
end

function TestDutyRulesFakes:test_only_the_first_of_two_missions_with_the_same_crc_is_removed()
	local p = H.newPlayer({})
	local crc = H.questCrc("patrol", "corellia_privateer_1")

	mission(p, "patrol", "corellia_privateer_1")
	mission(p, "patrol", "corellia_privateer_1")
	CreatureObject(p):removeQuestMission(crc)

	lu.assertEquals(#p.datapad.items, 1, "datapad")
end

function TestDutyRulesFakes:test_a_player_without_a_datapad_survives_fail_quest_mission()
	local p = H.newPlayer({})

	p.datapad = nil
	CreatureObject(p):failQuestMission(1)

	lu.assertEquals(p.failedMissions, { 1 }, "failedMissions")
end
