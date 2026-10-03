-- SpaceHelpers:hasSpaceQuest: SWG's space_quest.hasQuest(player) (any space quest mission in the datapad).
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-1, Content contract 1, D-9).
--
-- The fake mission answers getQuestCRC with nil when no quest type and name were set; the server answers 0 for an empty quest name
-- (MissionObjectImplementation.cpp:404-415), so the zero case replaces the method on the instance.

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")
local DR = require("duty_rules_scenario")
local G = require("rsf_gate_screens_data")

H.boot()
H.loadSpaceQuestTypes()
DR.loadSquadrons()

local function hasSpaceQuest(player)
	lu.assertEquals(type(SpaceHelpers.hasSpaceQuest), "function",
		"expected utils/space_helpers.lua to define SpaceHelpers:hasSpaceQuest (spec Content contract 1)")

	return SpaceHelpers:hasSpaceQuest(player)
end

-- A mission object the way a ground mission looks: no quest type, no quest name
local function groundMission(player)
	return Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)
end

local function zeroCrcMission(player)
	local mission = groundMission(player)

	mission.getQuestCRC = function() return 0 end

	return mission
end

local function newPlayer()
	return H.newPlayer({ pilot = "neutral", zone = "space_naboo", ship = true })
end

-- What the helper must not change: messages, music, datapad, journal, quest status, and every engine call recorded
local function worldSnapshot(player)
	local journal = {}

	for _, name in ipairs({ G.CORSEC_STORY, G.RSF_STORY, G.HAVOC_STORY, G.CORSEC_DUTY, G.HAVOC_DUTY }) do
		local crc = G.crc(name)

		journal[name] = { player.ghost:isJournalQuestActive(crc), player.ghost:isJournalQuestComplete(crc) }
	end

	local calls = {}

	for _, fn in ipairs({ "createObserver", "createEvent", "spawnShipAgent", "spawnSpaceActiveArea", "addWaypoint", "giveItem", "awardSkill", "skillManagerAwardSkill", "grantStarterShip" }) do
		calls[fn] = #H.Engine.callsTo(fn)
	end

	return { messages = #player.messageLog, music = #player.music, missions = #player.datapad.items, journal = journal, status = G.statusSnapshot(), calls = calls }
end

---------------------------------------------------------------------------------------------
-- AC-1: false when there is no space quest mission
---------------------------------------------------------------------------------------------

TestHasSpaceQuestFalse = {}

function TestHasSpaceQuestFalse:setUp() H.reset() end

-- AC-1
function TestHasSpaceQuestFalse:test_is_false_for_a_nil_player()
	lu.assertFalse(hasSpaceQuest(nil), "hasSpaceQuest(nil)")
end

-- AC-1
function TestHasSpaceQuestFalse:test_is_false_for_a_player_without_a_datapad()
	local player = newPlayer()

	player.datapad = nil
	lu.assertFalse(hasSpaceQuest(player), "hasSpaceQuest of a player with no datapad")
end

-- AC-1
function TestHasSpaceQuestFalse:test_is_false_for_an_empty_datapad()
	local player = newPlayer()

	lu.assertEquals(#player.datapad.items, 0, "setup: the datapad is empty")
	lu.assertFalse(hasSpaceQuest(player), "hasSpaceQuest of an empty datapad")
end

-- AC-1
function TestHasSpaceQuestFalse:test_is_false_for_a_datapad_holding_only_non_mission_objects()
	local player = newPlayer()

	Fakes.giveItem(player.datapad, "object/intangible/vehicle/speederbike_swoop_pcd.iff", -1)
	Fakes.giveItem(player.datapad, "object/intangible/pet/pet_control.iff", -1)
	Fakes.giveItem(player.datapad, "object/intangible/ship/ship_control_device.iff", -1)

	lu.assertEquals(#player.datapad.items, 3, "setup: three objects in the datapad")
	lu.assertFalse(hasSpaceQuest(player), "hasSpaceQuest with only non-mission objects")
end

-- AC-1: a ground mission has no quest name, so its quest CRC is nil in the fake
function TestHasSpaceQuestFalse:test_is_false_for_a_mission_whose_quest_crc_is_nil()
	local player = newPlayer()

	groundMission(player)

	lu.assertNil(player.datapad.items[1]:getQuestCRC(), "setup: the fake ground mission has no quest CRC")
	lu.assertFalse(hasSpaceQuest(player), "hasSpaceQuest with a mission of quest CRC nil")
end

-- AC-1: the server answers 0 for an empty quest name
function TestHasSpaceQuestFalse:test_is_false_for_a_mission_whose_quest_crc_is_zero()
	local player = newPlayer()

	zeroCrcMission(player)
	zeroCrcMission(player)

	lu.assertEquals(player.datapad.items[1]:getQuestCRC(), 0, "setup: the mission answers CRC 0")
	lu.assertFalse(hasSpaceQuest(player), "hasSpaceQuest with only missions of quest CRC 0")
end

---------------------------------------------------------------------------------------------
-- AC-1: true with a space quest mission
---------------------------------------------------------------------------------------------

TestHasSpaceQuestTrue = {}

function TestHasSpaceQuestTrue:setUp() H.reset() end

-- AC-1
function TestHasSpaceQuestTrue:test_is_true_with_a_held_duty_mission()
	local player = newPlayer()

	DR.holdDuty(player)
	lu.assertTrue(hasSpaceQuest(player), "hasSpaceQuest with DR.holdDuty")
end

-- AC-1
function TestHasSpaceQuestTrue:test_is_true_with_a_held_story_mission()
	local player = newPlayer()

	DR.holdStory(player)
	lu.assertTrue(hasSpaceQuest(player), "hasSpaceQuest with DR.holdStory")
end

-- AC-1: the quest mission is found among other objects, wherever it sits
function TestHasSpaceQuestTrue:test_finds_the_quest_mission_among_other_datapad_objects()
	local player = newPlayer()

	Fakes.giveItem(player.datapad, "object/intangible/pet/pet_control.iff", -1)
	zeroCrcMission(player)
	groundMission(player)
	DR.holdStory(player)
	Fakes.giveItem(player.datapad, "object/intangible/ship/ship_control_device.iff", -1)

	lu.assertTrue(hasSpaceQuest(player), "hasSpaceQuest with the one quest mission in the last-but-one slot")
end

-- AC-1: a quest started through the quest's own startQuest, for each of the three squadrons' stories and duties
local STARTED = {
	{ "corsec_story", G.CORSEC_STORY }, { "rsf_story", G.RSF_STORY }, { "havoc_story", G.HAVOC_STORY },
	{ "corsec_duty", G.CORSEC_DUTY }, { "rsf_duty", G.DINGE_DUTIES.destroy }, { "havoc_duty", G.HAVOC_DUTY },
}

for _, row in ipairs(STARTED) do
	-- AC-1
	TestHasSpaceQuestTrue["test_is_true_after_start_quest_of_the_" .. row[1] .. "_and_false_again_after_it_fails"] = function()
		local q = H.expectGlobal(row[2], "quest table")
		local player = DR.player(q)

		lu.assertFalse(hasSpaceQuest(player), row[2] .. ": before the start")

		q:startQuest(player, "")
		H.advance(0)

		lu.assertTrue(DR.active(player, q), row[2] .. ": setup, the quest started")
		lu.assertTrue(hasSpaceQuest(player), row[2] .. ": after startQuest")

		q:failQuest(player, "true")
		H.advance(0)

		lu.assertEquals(#player.datapad.items, 0, row[2] .. ": setup, failQuest removed the datapad mission")
		lu.assertFalse(hasSpaceQuest(player), row[2] .. ": after failQuest")
	end

	-- AC-1
	TestHasSpaceQuestTrue["test_is_true_after_start_quest_of_the_" .. row[1] .. "_and_false_again_after_it_completes"] = function()
		local q = H.expectGlobal(row[2], "quest table")
		local player = DR.player(q)

		q:startQuest(player, "")
		H.advance(0)

		lu.assertTrue(hasSpaceQuest(player), row[2] .. ": after startQuest")

		SpaceHelpers:completeSpaceQuest(player, q.questType, q.questName, false)

		lu.assertEquals(#player.datapad.items, 0, row[2] .. ": setup, completeSpaceQuest removed the datapad mission")
		lu.assertFalse(hasSpaceQuest(player), row[2] .. ": after the quest completed")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: read-only
---------------------------------------------------------------------------------------------

TestHasSpaceQuestReadOnly = {}

function TestHasSpaceQuestReadOnly:setUp() H.reset() end

local READ_ONLY_CASES = {
	{ "an_empty_datapad", function(p) end },
	{ "a_duty_mission", function(p) DR.holdDuty(p) end },
	{ "a_story_mission", function(p) DR.holdStory(p) end },
	{ "mixed_objects", function(p) zeroCrcMission(p); Fakes.giveItem(p.datapad, "object/intangible/pet/pet_control.iff", -1); DR.holdStory(p) end },
}

for _, case in ipairs(READ_ONLY_CASES) do
	-- AC-1
	TestHasSpaceQuestReadOnly["test_sends_no_message_and_changes_nothing_with_" .. case[1]] = function()
		local player = newPlayer()

		case[2](player)

		local before = worldSnapshot(player)
		local itemsBefore = {}

		for i, item in ipairs(player.datapad.items) do
			itemsBefore[i] = item
		end

		hasSpaceQuest(player)
		hasSpaceQuest(player)

		lu.assertEquals(worldSnapshot(player), before, "messages, music, datapad size, journal, quest status and engine calls after two reads")
		lu.assertEquals(player.datapad.items, itemsBefore, "the datapad objects themselves")
	end
end
