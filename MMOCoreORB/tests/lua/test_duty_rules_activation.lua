-- Tests for SpaceHelpers:activateSpaceQuest: duty flag, one-duty guard, completed-entry rules, result.
-- Spec: .claude/work/space-quest-duty-rules/01-spec.md (AC-1, AC-2, AC-3)

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")

H.boot()
H.loadSpaceQuestTypes()
DR.loadSquadrons()

local function activate(player, questType, questName)
	return SpaceHelpers:activateSpaceQuest(player, nil, questType, questName, false)
end

local function freshPlayer()
	return H.newPlayer({ zone = "space_corellia", ship = true, pilot = "rebel" })
end

---------------------------------------------------------------------------------------------
-- AC-1: duty flag
---------------------------------------------------------------------------------------------

TestDutyFlag = {}

function TestDutyFlag:setUp() H.reset() end

local DUTY_TYPES = { "destroy_duty", "escort_duty", "recovery_duty", "rescue_duty", "patrol_duty" }

local STORY_TYPES = { "patrol", "destroy", "destroy_surpriseattack", "escort", "recovery", "rescue", "assassinate", "survival",
	"delivery", "delivery_no_pickup", "inspect", "space_battle" }

-- AC-1
function TestDutyFlag:test_every_duty_type_flags_its_datapad_mission()
	for _, questType in ipairs(DUTY_TYPES) do
		H.reset()

		local p = freshPlayer()
		local result = activate(p, questType, "corellia_privateer_1")
		local mission = p.datapad.items[1]

		lu.assertNotNil(mission, questType .. ": a datapad mission was created")
		lu.assertTrue(mission:isSpaceDutyMission(), questType .. ": isSpaceDutyMission")
		lu.assertEquals(result, true, questType .. ": result")
	end
end

-- AC-1
function TestDutyFlag:test_no_story_type_flags_its_datapad_mission()
	for _, questType in ipairs(STORY_TYPES) do
		H.reset()

		local p = freshPlayer()
		local result = activate(p, questType, "corellia_privateer_1")
		local mission = p.datapad.items[1]

		lu.assertNotNil(mission, questType .. ": a datapad mission was created")
		lu.assertFalse(mission:isSpaceDutyMission(), questType .. ": isSpaceDutyMission")
		lu.assertEquals(result, true, questType .. ": result")
	end
end

-- AC-1 (I-2): the marker is in the quest type, never in the quest name
function TestDutyFlag:test_a_story_quest_with_duty_in_its_name_is_not_flagged()
	local p = freshPlayer()

	lu.assertEquals(activate(p, "recovery", "corellia_duty_9"), true, "result")
	lu.assertFalse(p.datapad.items[1]:isSpaceDutyMission(), "recovery/corellia_duty_9: isSpaceDutyMission")
end

-- AC-1 (I-2): a duty whose name has no marker is still a duty
function TestDutyFlag:test_a_duty_type_with_a_plain_name_is_flagged()
	local p = freshPlayer()

	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), true, "result")
	lu.assertTrue(p.datapad.items[1]:isSpaceDutyMission(), "recovery_duty/viopa_rebel_7: isSpaceDutyMission")
end

-- AC-1: every real quest global gets the flag its type says
function TestDutyFlag:test_every_quest_global_of_the_three_squadrons_flags_by_its_type()
	local problems = DR.collect(DR.quests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		if activate(p, q.questType, q.questName) ~= true then
			return "activation did not succeed"
		end

		local expected = DR.isDutyType(q.questType)

		if p.datapad.items[1]:isSpaceDutyMission() ~= expected then
			return "isSpaceDutyMission should be " .. tostring(expected) .. " for type " .. q.questType
		end
	end)

	lu.assertEquals(problems, {}, "quests whose datapad mission flag is wrong")
end

---------------------------------------------------------------------------------------------
-- AC-2: one-duty guard
---------------------------------------------------------------------------------------------

TestOneDutyGuard = {}

function TestOneDutyGuard:setUp() H.reset() end

-- AC-2
function TestOneDutyGuard:test_a_held_duty_refuses_every_other_duty_quest_of_the_three_squadrons()
	local problems = DR.collect(DR.dutyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		DR.holdDuty(p)

		local before = DR.snapshot(p)
		local result = activate(p, q.questType, q.questName)

		if result ~= false then
			return "result should be false, got " .. tostring(result)
		end

		if #DR.messages(p, DR.MSG_DUTY_ALREADY) ~= 1 then
			return "duty_already should be sent once, got " .. #DR.messages(p, DR.MSG_DUTY_ALREADY)
		end

		if #H.Engine.callsTo("giveItem") ~= before.giveItem then
			return "giveItem was called"
		end

		if #p.datapad.items ~= 1 then
			return "datapad holds " .. #p.datapad.items .. " missions, expected the one held duty"
		end

		if DR.active(p, q) then
			return "journal entry is active"
		end

		if #DR.messages(p, DR.MSG_RECEIVED) ~= 0 then
			return "quest_received was sent"
		end

		if #p.music ~= before.music then
			return "music was played"
		end
	end)

	lu.assertEquals(problems, {}, "duty quests that were not refused cleanly")
end

-- AC-2
function TestOneDutyGuard:test_a_held_duty_does_not_refuse_a_story_quest()
	local p = freshPlayer()

	DR.holdDuty(p)

	lu.assertEquals(activate(p, "patrol", "corellia_privateer_1"), true, "result")
	lu.assertTrue(p.ghost:isJournalQuestActive(H.questCrc("patrol", "corellia_privateer_1")), "journal entry is active")
	lu.assertEquals(#p.datapad.items, 2, "the held duty and the new story mission")
	lu.assertFalse(p.datapad.items[2]:isSpaceDutyMission(), "the new mission is not a duty")
	lu.assertEquals(#DR.messages(p, DR.MSG_DUTY_ALREADY), 0, "no duty_already for a story quest")
end

-- AC-2
function TestOneDutyGuard:test_a_pilot_with_two_story_missions_can_still_take_a_duty()
	local p = freshPlayer()

	lu.assertEquals(activate(p, "patrol", "corellia_privateer_1"), true, "first story quest")
	lu.assertEquals(activate(p, "survival", "corellia_privateer_2"), true, "second story quest")
	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), true, "the duty")

	lu.assertEquals(#p.datapad.items, 3, "three missions")
	lu.assertEquals(#DR.flaggedMissions(p), 1, "one flagged duty")
	lu.assertEquals(#DR.messages(p, DR.MSG_DUTY_ALREADY), 0, "no duty_already")
end

-- AC-2 (I-3)
function TestOneDutyGuard:test_a_second_duty_from_the_same_trainer_is_refused_until_the_first_ends()
	local p = freshPlayer()

	lu.assertEquals(activate(p, "destroy_duty", "corellia_rebel_6"), true, "first duty")
	lu.assertEquals(activate(p, "escort_duty", "corellia_rebel_7"), false, "second duty while the first is held")
	lu.assertEquals(#DR.flaggedMissions(p), 1, "still one flagged duty")

	SpaceHelpers:failSpaceQuest(p, "destroy_duty", "corellia_rebel_6", false)

	lu.assertEquals(#p.datapad.items, 0, "the failed duty left the datapad")
	lu.assertEquals(activate(p, "escort_duty", "corellia_rebel_7"), true, "second duty after the first ended")
	lu.assertEquals(#DR.flaggedMissions(p), 1, "one flagged duty again")
end

-- AC-2
function TestOneDutyGuard:test_taking_the_same_duty_twice_is_refused_and_leaves_one_mission()
	local p = freshPlayer()

	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), true, "first")
	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), false, "second")
	lu.assertEquals(#p.datapad.items, 1, "one mission")
end

---------------------------------------------------------------------------------------------
-- AC-3: refusals and the legacy repair
---------------------------------------------------------------------------------------------

TestActivationRefusals = {}

function TestActivationRefusals:setUp() H.reset() end

-- AC-3
function TestActivationRefusals:test_an_active_entry_is_refused_without_a_mission_or_a_message()
	local p = freshPlayer()

	p.ghost:activateJournalQuest(H.questCrc("survival", "corellia_rebel_tier4_1"), false)

	local before = DR.snapshot(p)
	local result = activate(p, "survival", "corellia_rebel_tier4_1")

	lu.assertEquals(result, false, "result")
	lu.assertEquals(#p.datapad.items, 0, "no mission created")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), before.giveItem, "giveItem not called")
	lu.assertEquals(#DR.messages(p, DR.MSG_RECEIVED), 0, "no quest_received")
	lu.assertEquals(#p.music, 0, "no music")
	lu.assertTrue(p.ghost:isJournalQuestActive(H.questCrc("survival", "corellia_rebel_tier4_1")), "entry stays active")
end

-- AC-3
function TestActivationRefusals:test_an_active_duty_entry_is_refused_without_a_mission()
	local p = freshPlayer()

	p.ghost:activateJournalQuest(H.questCrc("recovery_duty", "viopa_rebel_7"), false)

	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), false, "result")
	lu.assertEquals(#p.datapad.items, 0, "no mission created")
	lu.assertEquals(#DR.messages(p, DR.MSG_DUTY_ALREADY), 0, "an active entry is not a duty_already case")
end

-- AC-3
function TestActivationRefusals:test_a_completed_story_entry_is_refused_and_stays_complete()
	local p = freshPlayer()
	local crc = H.questCrc("survival", "corellia_rebel_tier4_1")

	p.ghost:activateJournalQuest(crc, false)
	p.ghost:completeJournalQuest(crc, false)

	local result = activate(p, "survival", "corellia_rebel_tier4_1")

	lu.assertEquals(result, false, "result")
	lu.assertEquals(#p.datapad.items, 0, "no mission created")
	lu.assertEquals(#DR.messages(p, DR.MSG_RECEIVED), 0, "no quest_received")
	lu.assertEquals(#p.music, 0, "no music")
	lu.assertTrue(p.ghost:isJournalQuestComplete(crc), "entry stays complete")
	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "entry stays inactive")
end

-- AC-3
function TestActivationRefusals:test_a_completed_duty_entry_is_repaired_and_activated_with_one_flagged_mission()
	local p = H.newPlayer({ zone = "space_lok", ship = true, pilot = "rebel", completedQuests = { H.questCrc("recovery_duty", "viopa_rebel_7") } })
	local crc = H.questCrc("recovery_duty", "viopa_rebel_7")

	local result = activate(p, "recovery_duty", "viopa_rebel_7")

	lu.assertEquals(result, true, "result")
	lu.assertTrue(p.ghost:isJournalQuestActive(crc), "entry is active")
	lu.assertFalse(p.ghost:isJournalQuestComplete(crc), "entry is no longer complete")
	lu.assertEquals(#p.datapad.items, 1, "exactly one mission")
	lu.assertTrue(p.datapad.items[1]:isSpaceDutyMission(), "the mission is flagged")
	lu.assertEquals(#DR.messages(p, DR.MSG_RECEIVED), 1, "quest_received sent once")
end

-- AC-3 (I-1): the repair stays even when the held duty then refuses the activation
function TestActivationRefusals:test_a_completed_duty_entry_is_repaired_even_when_another_duty_is_held()
	local crc = H.questCrc("recovery_duty", "viopa_rebel_7")
	local p = H.newPlayer({ zone = "space_lok", ship = true, pilot = "rebel", completedQuests = { crc } })

	DR.holdDuty(p)

	lu.assertEquals(activate(p, "recovery_duty", "viopa_rebel_7"), false, "result")
	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "entry is not active")
	lu.assertFalse(p.ghost:isJournalQuestComplete(crc), "the legacy completed entry was cleared")
	lu.assertEquals(#p.datapad.items, 1, "only the held duty is on the datapad")
	lu.assertEquals(#DR.messages(p, DR.MSG_DUTY_ALREADY), 1, "duty_already sent")
end

-- AC-3
function TestActivationRefusals:test_a_fresh_story_activation_succeeds_with_message_and_music()
	local p = freshPlayer()
	local crc = H.questCrc("patrol", "corellia_privateer_1")

	local result = activate(p, "patrol", "corellia_privateer_1")

	lu.assertEquals(result, true, "result")
	lu.assertTrue(p.ghost:isJournalQuestActive(crc), "entry is active")
	lu.assertEquals(#p.datapad.items, 1, "exactly one mission")
	lu.assertEquals(#DR.messages(p, DR.MSG_RECEIVED), 1, "quest_received sent once")
	lu.assertEquals(DR.messages(p, DR.MSG_RECEIVED)[1].TO, "@spacequest/patrol/corellia_privateer_1:title", "quest_received TO")
	lu.assertEquals(p.music, { "sound/music_themequest_acc_criminal.snd" }, "music")
end

-- AC-3
function TestActivationRefusals:test_a_missing_player_ghost_or_datapad_returns_false()
	lu.assertIs(SpaceHelpers:activateSpaceQuest(nil, nil, "patrol", "corellia_privateer_1", false), false, "nil player")

	local noGhost = freshPlayer()
	noGhost.ghost = nil

	lu.assertIs(activate(noGhost, "patrol", "corellia_privateer_1"), false, "no ghost")

	local noDatapad = freshPlayer()
	noDatapad.datapad = nil

	lu.assertIs(activate(noDatapad, "patrol", "corellia_privateer_1"), false, "no datapad")
	lu.assertFalse(noDatapad.ghost:isJournalQuestActive(H.questCrc("patrol", "corellia_privateer_1")), "no journal entry without a datapad")
end

-- AC-3 (I-1)
function TestActivationRefusals:test_a_refusal_leaves_the_journal_and_datapad_unchanged()
	local p = freshPlayer()
	local held = DR.holdDuty(p)

	activate(p, "destroy_duty", "corellia_rebel_6")

	lu.assertEquals(#p.datapad.items, 1, "datapad size")
	lu.assertIs(p.datapad.items[1], held, "datapad holds only the held duty")
	lu.assertEquals(p.ghost.journalActive, {}, "active journal entries")
	lu.assertEquals(p.ghost.journalComplete, {}, "completed journal entries")
end
