--[[
	Space Duty Rescue Screenplay

	Ported from SWG-Source: script/space/quest_logic/rescue_duty.java (extends rescue.java)
	Used by: CorSec tier 4 (Turoldine), Havoc tier 4 (Warvog Arkon) duty rescue quests
	Feature: space-quest-rescue-duty

	Built on SpaceRescueScreenplay through its extension points. Rescues repeat: every rescue picks a random target
	ship and a random start on the recoveryPath (stored in shared memory at first use, so every call of one rescue
	agrees), arrival pays creditReward + creditKillBonus * ships killed in fully cleared attack sets, and ten seconds
	later the next rescue starts. Leaving the zone ends the duty, dying or losing the target fails it.

	The journal quest is never completed: a completed journal quest can not be activated again, so a duty ends by
	clearing its journal entry.
]]

SpaceDutyRescueScreenplay = SpaceRescueScreenplay:new {
	className = "SpaceDutyRescueScreenplay",

	questType = "rescue_duty",

	-- Screenplay Specific Variables

	DEBUG_SPACE_DUTY_RESCUE = false,

	-- Per quest data, copied from the rescue_duty .tab
	targetShipTypes = {}, -- ship_mobile templates, one is picked per rescue
	creditKillBonus = 0, -- .tab killReward (creditReward holds .tab reward)

	cycleCleanupDelay = 2, -- seconds from arrival to the target and area cleanup, rescue_duty.java cleanupShipsMsg
	nextCycleDelay = 10, -- seconds from arrival to the next rescue
}

registerScreenPlay("SpaceDutyRescueScreenplay", false)

--[[

		Space Duty Rescue Quest Functions

--]]

--[[

		Extension points of SpaceRescueScreenplay

--]]

-- The recoveryPath rotated to a random start, chosen once per rescue
function SpaceDutyRescueScreenplay:pathPoints(playerID)
	local count = #self.recoveryPath

	if (count == 0) then
		return {}
	end

	local startKey = self:dataKey(playerID, "pathStart")
	local pathStart = readData(startKey)

	if (pathStart == 0) then
		pathStart = getRandomNumber(1, count)
		writeData(startKey, pathStart)
	end

	local path = {}

	for i = pathStart, count, 1 do
		path[#path + 1] = self.recoveryPath[i]
	end

	for i = 1, pathStart - 1, 1 do
		path[#path + 1] = self.recoveryPath[i]
	end

	return path
end

-- A random target ship, chosen once per rescue
function SpaceDutyRescueScreenplay:pickTargetShip(playerID)
	local count = #self.targetShipTypes

	if (count == 0) then
		return ""
	end

	local shipKey = self:dataKey(playerID, "shipIndex")
	local shipIndex = readData(shipKey)

	if (shipIndex == 0) then
		shipIndex = getRandomNumber(1, count)
		writeData(shipKey, shipIndex)
	end

	return self.targetShipTypes[shipIndex]
end

function SpaceDutyRescueScreenplay:capturePhraseKey(playerID)
	if (self.numResponses < 1) then
		return "rescue_phase_2"
	end

	return "rescue_phase_2_" .. getRandomNumber(1, self.numResponses)
end

-- The in-progress message is sent once per duty, not once per rescue
function SpaceDutyRescueScreenplay:shouldSendInProgress(playerID)
	return readData(self:dataKey(playerID, "cycle")) == 0
end

-- Pays the rescue and schedules the cleanup and the next rescue
function SpaceDutyRescueScreenplay:onRescueArrived(pPlayer, token)
	local playerID = SceneObject(pPlayer):getObjectID()
	local rewardKey = self:dataKey(playerID, "rewardShips")
	local amount = self.creditReward + self.creditKillBonus * readData(rewardKey)

	local message = LuaStringIdChatParameter("@space/quest:rescue_reward")
	message:setDI(amount)

	CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
	CreatureObject(pPlayer):addBankCredits(amount, true)

	deleteData(rewardKey)

	createEvent(self.cycleCleanupDelay * 1000, self.className, "endCycle", pPlayer, token)
	createEvent(self.nextCycleDelay * 1000, self.className, "nextCycle", pPlayer, token)
end

-- Counts the kills of fully cleared attack sets (rescue_duty.java / recovery.java deadships)
function SpaceDutyRescueScreenplay:notifyAttackShipKilled(pPlayer, remaining)
	local playerID = SceneObject(pPlayer):getObjectID()

	-- Kills up to the next rescue's setup still count (a set cleared after the payment is paid at the next arrival, as in SWG)
	if (not self:isStage(playerID, self.STAGES.DOCK, self.STAGES.DOCKED, self.STAGES.ESCORT, self.STAGES.ARRIVED)) then
		return
	end

	local pendingKey = self:dataKey(playerID, "killsPending")
	local pending = readData(pendingKey) + 1

	if (remaining == 0) then
		local rewardKey = self:dataKey(playerID, "rewardShips")

		writeData(rewardKey, readData(rewardKey) + pending)
		deleteData(pendingKey)
	else
		writeData(pendingKey, pending)
	end
end

--[[

		Duty Rescue Observers

--]]

-- Leaving the zone ends the duty; other switches go to the base handling, which ignores a same-zone switch (the respawn after a
-- destroyed ship; the death itself fails the duty through SpaceQuestLogic:playerShipDestroyed)
function SpaceDutyRescueScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		local playerID = SceneObject(pPlayer):getObjectID()

		if (readData(self:dataKey(playerID, "runID")) ~= 0 and zoneNameHash ~= getHashCode(self.questZone)) then
			createEvent(0, self.className, "endDuty", pPlayer, self:getRunToken(playerID))
			return 0
		end
	end

	return SpaceRescueScreenplay.enteredZone(self, pPlayer, nill, zoneNameHash)
end

--[[

		Duty Rescue Quest End

--]]

-- The duty fails instead of being abandoned (a same-zone respawn no longer reaches this; ship death fails through playerShipDestroyed)
function SpaceDutyRescueScreenplay:abandonRun(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	self:failQuest(pPlayer, "true")
end

function SpaceDutyRescueScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_DUTY_RESCUE) then
		print(self.className .. ":failQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Clears the journal quest, the duty is never completed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)

	if (notifyClient ~= "false") then
		SpaceHelpers:sendMissionFailed(pPlayer, "@spacequest/" .. self.questType .. "/" .. self.questName .. ":title")
		CreatureObject(pPlayer):playMusicMessage("sound/music_themequest_fail_criminal.snd")
	end
end

function SpaceDutyRescueScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	SpaceRescueScreenplay.cleanUpQuestData(self, pPlayer)

	local playerID = SceneObject(pPlayer):getObjectID()

	deleteData(self:dataKey(playerID, "cycle"))
	deleteData(self:dataKey(playerID, "pathStart"))
	deleteData(self:dataKey(playerID, "shipIndex"))
	deleteData(self:dataKey(playerID, "killsPending"))
	deleteData(self:dataKey(playerID, "rewardShips"))
end

-- The player left the zone (rescue_duty.java initializedQuestPlayer), args: run token
function SpaceDutyRescueScreenplay:endDuty(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	SpaceHelpers:sendDutyUpdate(pPlayer, "@space/quest:destroy_abandoned")

	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)

	SpaceHelpers:sendMissionEnded(pPlayer, "@spacequest/" .. self.questType .. "/" .. self.questName .. ":title")
end

--[[

		Duty Rescue Cycle Timers (args: run token)

--]]

-- Removes the rescue's target, area, waypoint and attack ships. Keeps the run id and stage, safe to call twice.
function SpaceDutyRescueScreenplay:releaseCycle(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()

	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	dropObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)

	local areaID = readData(self:dataKey(playerID, "areaID"))

	if (areaID ~= 0) then
		local pArea = getSceneObject(areaID)

		if (pArea ~= nil) then
			dropObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)
			SceneObject(pArea):destroyObjectFromWorld()
		end

		deleteData(self:dataKey(playerID, "areaID"))
	end

	local targetID = readData(self:dataKey(playerID, "targetID"))

	if (targetID ~= 0) then
		local pTarget = getSceneObject(targetID)

		CreatureObject(pPlayer):removeSpaceMissionObject(targetID, false)

		if (pTarget ~= nil) then
			ShipAiAgent(pTarget):setDockable(false)
			dropObserver(SHIPDESTROYED, self.className, "notifyTargetDestroyed", pTarget)

			ShipObject(pTarget):setHyperspacing(true)

			createEvent(2000, "SpaceHelpers", "delayedDestroyShipAgent", pTarget, "")
		end

		deleteData(self:dataKey(playerID, "targetID"))
	end

	self:removeAttackShips(pPlayer)
	self:cleanUpWaveData(pPlayer)
end

-- 2 s after arrival
function SpaceDutyRescueScreenplay:endCycle(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.ARRIVED)) then
		return
	end

	self:releaseCycle(pPlayer)
end

-- 10 s after arrival: the next rescue
function SpaceDutyRescueScreenplay:nextCycle(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.ARRIVED)) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	self:releaseCycle(pPlayer)

	deleteData(self:dataKey(playerID, "runID"))
	deleteData(self:dataKey(playerID, "stage"))
	deleteData(self:dataKey(playerID, "pathStart"))
	deleteData(self:dataKey(playerID, "shipIndex"))
	deleteData(self:dataKey(playerID, "killsPending"))

	writeData(self:dataKey(playerID, "cycle"), readData(self:dataKey(playerID, "cycle")) + 1)

	SpaceHelpers:clearSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
	SpaceHelpers:clearSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)

	self:setupRun(pPlayer)
end
