-- Recovery duties clear their journal entry when they end; every duty can be taken again.
-- Spec: .claude/work/space-quest-duty-rules/01-spec.md (AC-5, AC-6, I-5)

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")

H.boot()
H.loadSpaceQuestTypes()
DR.loadSquadrons()

local REP = "recovery_duty_corellia_rebel_tier4_1"

-- The four recovery duties built on SpaceDutyRecoveryScreenplay (the _12 ones are destroy duties)
local RECOVERY_DUTIES = { "recovery_duty_viopa_rebel_7", "recovery_duty_corellia_rebel_tier4_1", "recovery_duty_corellia_privateer_tier4_1",
	"recovery_duty_naboo_privateer_tier4_1" }

local function entries(globals)
	local out = {}

	for _, g in ipairs(globals) do
		out[#out + 1] = { global = g, quest = H.expectGlobal(g, "recovery duty quest table") }
	end

	return out
end

local function titleOf(q)
	return "@spacequest/" .. q.questType .. "/" .. q.questName .. ":title"
end

---------------------------------------------------------------------------------------------
-- AC-5: a recovery duty ends by clearing its journal entry
---------------------------------------------------------------------------------------------

TestRecoveryDutyEnd = {}

function TestRecoveryDutyEnd:setUp()
	H.reset()
	self.q = H.expectGlobal(REP, "recovery duty quest table")
	self.run = DR.startRecoveryRun(self.q)
	self.p = self.run.player
end

function TestRecoveryDutyEnd:tearDown() DR.restoreRecoveryTables() end

-- AC-5
function TestRecoveryDutyEnd:test_the_run_starts_with_an_active_entry_and_one_flagged_mission()
	lu.assertTrue(DR.active(self.p, self.q), "journal entry is active")
	lu.assertEquals(#self.p.datapad.items, 1, "one datapad mission")
	lu.assertTrue(self.p.datapad.items[1]:isSpaceDutyMission(), "flagged duty")
end

-- AC-5
function TestRecoveryDutyEnd:test_the_journal_entry_is_neither_active_nor_complete_after_the_last_recovery_point()
	DR.finishRecovery(self.run)

	lu.assertFalse(DR.active(self.p, self.q), "journal entry is active")
	lu.assertFalse(DR.complete(self.p, self.q), "journal entry is complete")
end

-- AC-5
function TestRecoveryDutyEnd:test_the_datapad_mission_is_failed_by_its_crc_and_gone()
	DR.finishRecovery(self.run)

	lu.assertEquals(self.p.failedMissions, { DR.crc(self.q) }, "failQuestMission got the quest CRC")
	lu.assertEquals(#self.p.datapad.items, 0, "datapad is empty")
end

-- AC-5
function TestRecoveryDutyEnd:test_quest_ended_is_sent_with_the_title_and_quest_won_is_not()
	DR.finishRecovery(self.run)

	local ended = DR.messages(self.p, DR.MSG_ENDED)

	lu.assertEquals(#ended, 1, "quest_ended sent once")
	lu.assertEquals(ended[1].TO, titleOf(self.q), "quest_ended TO")
	lu.assertEquals(#DR.messages(self.p, DR.MSG_WON), 0, "quest_won is not sent")
end

-- AC-5 (D-6)
function TestRecoveryDutyEnd:test_the_victory_music_plays_and_the_run_is_not_completed_through_the_journal_helper()
	local complete = H.spyOn(SpaceHelpers, "completeSpaceQuest")

	DR.finishRecovery(self.run)

	lu.assertEquals(#complete, 0, "completeSpaceQuest is never called")
	lu.assertEquals(self.p.music[#self.p.music], "sound/music_themequest_victory_rebel.snd", "last music")
end

-- AC-5: the inherited update and taunt stay
function TestRecoveryDutyEnd:test_the_recovery_success_update_and_the_complete_taunt_are_kept()
	DR.finishRecovery(self.run)

	local updates = DR.messages(self.p, "@spacequest/recovery_duty/corellia_rebel_tier4_1:quest_update")

	lu.assertEquals(#updates, 1, "quest_update sent once")
	lu.assertEquals(updates[1].TO, "@spacequest/recovery_duty/corellia_rebel_tier4_1:recovery_success", "quest_update TO")

	local taunts = H.tauntLog(self.p)

	lu.assertEquals(taunts[#taunts].msg, "@spacequest/recovery_duty/corellia_rebel_tier4_1:complete", "last taunt")
end

-- AC-5
function TestRecoveryDutyEnd:test_the_waypoint_the_observer_the_ships_and_the_quest_data_are_gone()
	local shipID = self.run.ship.objectID
	local escortIDs = {}

	for _, id in ipairs(readStringVectorSharedMemory(self.p.objectID .. self.q.className .. ":spawnedShips:")) do
		escortIDs[#escortIDs + 1] = tonumber(id)
	end

	lu.assertTrue(#escortIDs > 0, "precondition: the run has escort ships")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, self.q.className, "enteredZone", self.p), "precondition: zone observer")

	DR.finishRecovery(self.run)
	H.advanceSeconds(5)

	lu.assertEquals(#self.p.ghost.waypoints, 0, "quest waypoints")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, self.q.className, "enteredZone", self.p), "ZONESWITCHED observer")
	lu.assertNil(getSceneObject(shipID), "recovery ship is despawned")

	for _, id in ipairs(escortIDs) do
		lu.assertNil(getSceneObject(id), "escort ship " .. id .. " is despawned")
	end

	lu.assertEquals(readData(self.p.objectID .. self.q.className .. ":recoveryShip:"), 0, "recoveryShip key")
	lu.assertEquals(readStringVectorSharedMemory(self.p.objectID .. self.q.className .. ":spawnedShips:"), {}, "spawnedShips key")
	lu.assertEquals(readStringVectorSharedMemory(self.p.objectID .. self.q.className .. ":attackShips:"), {}, "attackShips key")
end

-- AC-5
function TestRecoveryDutyEnd:test_the_duty_can_be_taken_again_after_it_ended()
	DR.finishRecovery(self.run)
	H.advanceSeconds(5)

	self.q:startQuest(self.p, "")
	H.advance(0)

	lu.assertTrue(DR.active(self.p, self.q), "journal entry is active again")
	lu.assertEquals(#self.p.datapad.items, 1, "one datapad mission")
	lu.assertTrue(self.p.datapad.items[1]:isSpaceDutyMission(), "flagged duty")
	lu.assertEquals(#DR.messages(self.p, DR.MSG_DUTY_ALREADY), 0, "no duty_already")
end

-- AC-5 (D-6): no split is triggered
function TestRecoveryDutyEnd:test_ending_the_duty_starts_no_other_quest()
	local startSpies = {}

	for _, name in ipairs(H.questGlobals()) do
		if name ~= REP then
			startSpies[name] = H.spyOn(_G[name], "startQuest")
		end
	end

	DR.finishRecovery(self.run)
	H.advanceSeconds(60)

	for name, calls in pairs(startSpies) do
		lu.assertEquals(#calls, 0, name .. ": startQuest calls after the duty ended")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: completeQuest on its own
---------------------------------------------------------------------------------------------

TestRecoveryDutyCompleteQuest = {}

function TestRecoveryDutyCompleteQuest:setUp()
	H.reset()
	self.q = H.expectGlobal(REP, "recovery duty quest table")
	self.p = DR.player(self.q)
end

-- AC-5
function TestRecoveryDutyCompleteQuest:test_complete_quest_defines_its_own_override_on_the_duty_class()
	lu.assertEquals(type(rawget(SpaceDutyRecoveryScreenplay, "completeQuest")), "function",
		"expected SpaceDutyRecoveryScreenplay to define completeQuest itself (screenplays/space/SpaceDutyRecoveryScreenplay.lua)")
end

-- AC-5
function TestRecoveryDutyCompleteQuest:test_complete_quest_without_notification_sends_no_message_and_no_music()
	self.q:startQuest(self.p, "")

	local before = DR.snapshot(self.p)

	self.q:completeQuest(self.p, "false")

	lu.assertFalse(DR.active(self.p, self.q), "journal entry is active")
	lu.assertFalse(DR.complete(self.p, self.q), "journal entry is complete")
	lu.assertEquals(#self.p.datapad.items, 0, "datapad")
	lu.assertEquals(#DR.messages(self.p, DR.MSG_ENDED), 0, "no quest_ended")
	lu.assertEquals(#self.p.music, before.music, "no music")
end

-- AC-5
function TestRecoveryDutyCompleteQuest:test_complete_quest_on_an_inactive_entry_does_nothing()
	local before = DR.snapshot(self.p)

	self.q:completeQuest(self.p, "true")

	lu.assertEquals(#self.p.messageLog, before.messages, "no messages")
	lu.assertEquals(self.p.failedMissions, {}, "no failed mission")
	lu.assertEquals(#self.p.music, 0, "no music")
	lu.assertFalse(DR.complete(self.p, self.q), "journal entry is complete")
end

-- AC-5
function TestRecoveryDutyCompleteQuest:test_complete_quest_for_a_missing_player_does_not_raise()
	lu.assertNil(self.q:completeQuest(nil, "true"), "result")
end

-- AC-5 (D-5): the destroy-based recovery duties keep the destroy duty ending
function TestRecoveryDutyCompleteQuest:test_the_twelve_recovery_duties_are_not_changed_to_clear_their_entry()
	for _, g in ipairs({ "recovery_duty_corellia_privateer_12", "recovery_duty_naboo_privateer_12" }) do
		local q = H.expectGlobal(g, "recovery duty quest table")

		lu.assertEquals(rawget(q, "completeQuest"), nil, g .. ": no own completeQuest")
		lu.assertNotEquals(q.completeQuest, SpaceDutyRecoveryScreenplay.completeQuest, g .. ": does not use the recovery duty's completeQuest")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: every duty can be taken again
---------------------------------------------------------------------------------------------

TestDutyRetake = {}

function TestDutyRetake:setUp() H.reset() end

local function retakeProblem(p, q)
	q:startQuest(p, "")
	H.advance(0)

	if not DR.active(p, q) then
		return "startQuest did not activate the duty again"
	end

	if DR.complete(p, q) then
		return "journal entry is still complete"
	end

	if #p.datapad.items ~= 1 then
		return "datapad holds " .. #p.datapad.items .. " missions after the re-take, expected 1"
	end

	if #DR.messages(p, DR.MSG_DUTY_ALREADY) ~= 0 then
		return "duty_already was sent for a duty that had ended"
	end
end

-- AC-6 (legacy state)
function TestDutyRetake:test_every_duty_starts_again_from_a_completed_journal_entry()
	local problems = DR.collect(DR.dutyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		p.ghost:activateJournalQuest(DR.crc(q), false)
		p.ghost:completeJournalQuest(DR.crc(q), false)

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "duties that could not be re-taken from a completed entry")
end

-- AC-6
function TestDutyRetake:test_every_duty_starts_again_after_a_fail()
	local problems = DR.collect(DR.dutyQuests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)

		if not DR.active(p, q) then
			return "first start did not activate"
		end

		q:failQuest(p, "true")
		H.advance(0)

		if DR.active(p, q) or #p.datapad.items ~= 0 then
			return "failQuest left the entry active or the mission on the datapad"
		end

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "duties that could not be re-taken after a fail")
end

-- AC-6: destroy duty after the final boss
function TestDutyRetake:test_every_destroy_duty_starts_again_after_the_final_boss()
	local destroyDuties = {}

	for _, entry in ipairs(DR.dutyQuests()) do
		if entry.quest.questType == "destroy_duty" then
			destroyDuties[#destroyDuties + 1] = entry
		end
	end

	lu.assertTrue(#destroyDuties > 0, "destroy duties found")

	local problems = DR.collect(destroyDuties, function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)

		-- The last level's boss, the way the quest spawns it: a mission-owned agent that is the only attack ship left
		local boss = spawnShipAgent(q.bossShip, q.questZone, 0, 0, 0)

		ShipAiAgent(boss):setMissionOwner(p)
		writeStringVectorSharedMemory(p.objectID .. q.className .. ":attackShips:", { SceneObject(boss):getObjectID() })
		writeData(p.objectID .. ":" .. q.className .. ":CurrentLevel:", q.totalLevels - 1)
		createObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", boss)

		H.destroyShip(boss, p.rootParent)
		H.advance(0)

		if DR.active(p, q) then
			return "the duty is still active after the final boss"
		end

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "destroy duties that could not be re-taken after the final boss")
end

-- AC-6: escort duty after leaving the zone
function TestDutyRetake:test_every_escort_duty_starts_again_after_leaving_the_zone()
	local escortDuties = {}

	for _, entry in ipairs(DR.dutyQuests()) do
		if entry.quest.questType == "escort_duty" then
			escortDuties[#escortDuties + 1] = entry
		end
	end

	lu.assertTrue(#escortDuties > 0, "escort duties found")

	local problems = DR.collect(escortDuties, function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)

		H.zoneSwitch(p, "space_tatooine")
		H.advanceSeconds(5)

		if DR.active(p, q) then
			return "the duty is still active after the player left the zone"
		end

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "escort duties that could not be re-taken after leaving the zone")
end

-- AC-6: rescue duty after endDuty
function TestDutyRetake:test_every_rescue_duty_starts_again_after_it_ended()
	local rescueDuties = {}

	for _, entry in ipairs(DR.dutyQuests()) do
		if entry.quest.questType == "rescue_duty" then
			rescueDuties[#rescueDuties + 1] = entry
		end
	end

	lu.assertEquals(#rescueDuties, 3, "rescue duties found")

	local problems = DR.collect(rescueDuties, function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)

		local token = q:getRunToken(p.objectID)

		q:endDuty(p, token)

		if DR.active(p, q) then
			return "the duty is still active after endDuty"
		end

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "rescue duties that could not be re-taken after endDuty")
end

-- AC-6: recovery duty after its own end (the four SpaceDutyRecoveryScreenplay duties)
function TestDutyRetake:test_every_recovery_duty_starts_again_after_its_end()
	local problems = DR.collect(entries(RECOVERY_DUTIES), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)

		q:completeQuest(p, "true")

		if DR.active(p, q) or DR.complete(p, q) then
			return "the entry is not cleared when the duty ends"
		end

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "recovery duties that could not be re-taken after their end")
end

-- AC-6: the two recovery duties on the destroy duty base
function TestDutyRetake:test_the_destroy_based_recovery_duties_start_again_after_the_final_boss()
	local problems = DR.collect(entries({ "recovery_duty_corellia_privateer_12", "recovery_duty_naboo_privateer_12" }), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		q:startQuest(p, "")
		H.advance(0)
		q:completeQuest(p, "true")

		return retakeProblem(p, q)
	end)

	lu.assertEquals(problems, {}, "destroy-based recovery duties that could not be re-taken")
end
