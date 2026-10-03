--[[
	Space Survival Screenplay

	Ported from SWG-Source: script/space/quest_logic/survival.java
	Handles transmission timeline, attack waves with cap, distance check and abandon-on-zone-switch.

	Run token (stale event guard): Stored as <pid>:<className>:areaID, the arrival area's object id.
	Every timer carries it in args; handlers re-check against stored value to ignore ended runs.

	Setup deferral: enteredZone defers setup by ~1 s after zone switch (checkSetup event), so the
	player's zone and position are updated before waypoint and area creation.
]]

SpaceSurvivalScreenplay = SpaceQuestLogic:new {
	className = "SpaceSurvivalScreenplay",

	questName = "",
	questType = "",

	questZone = "",

	creditReward = 0,
	itemReward = {
		--{species = {}, item = ""},
	},

	sideQuest = false,
	sideQuestType = "",
	sideQuestName = "",

	DEBUG_SPACE_SURVIVAL = false,

	-- attackListType values, same as the survival .tab enum e(sequential=0,random=1)
	ATTACK_LIST_TYPES = {
		SEQUENTIAL = 0,
		RANDOM = 1,
	},

	-- Tuning constants from survival.java
	arrivalRadius = 150, -- space_quest.PATROL_NAV_RADIUS
	maxDistance = 2000, -- meters from the transmission point before the player is out of range
	distanceCheckInterval = 30, -- seconds
	endMissionDelay = 5, -- seconds from transmission_received to mission_complete
	firstWaveDelay = 5, -- seconds from first_attack to the first launch
	maxActiveWaves = 2,
	spawnMinDistance = 1000,
	spawnMaxDistance = 1200,
	spawnSpread = 150,
	squadronMinSize = 4,

	-- Per quest data, copied from the survival .tab
	transmissionPoint = {}, -- {patrolPointName = "<name>", x = 0, z = 0, y = 0}
	totalTransmissionTime = 0, -- seconds
	timesToUpdateProgress = 0,
	transmissionStartDelay = 0, -- seconds after arrival
	delayToFirstAttack = 0, -- seconds after arrival
	attackShipLists = {}, -- { {"ship", ...}, ... } one inner list per .tab attackShipsN column
	attackPeriod = 0, -- seconds between waves
	attackListType = 0, -- ATTACK_LIST_TYPES
}

SpaceAttackWaves:mixInto(SpaceSurvivalScreenplay)

registerScreenPlay("SpaceSurvivalScreenplay", false)

-- Timer events carry a run token (the object id of the run's arrival area, which is new for every run
-- and lives in shared memory, so it is the same in every worker thread's Lua VM). They do nothing once
-- that run has ended, even if the same quest has been started again since.

--[[

		Space Survival Quest Functions

--]]

function SpaceSurvivalScreenplay:start()
end

-- Prefix of every shared memory key this quest writes for a player
function SpaceSurvivalScreenplay:dataKey(playerID, name)
	return playerID .. ":" .. self.className .. ":" .. name
end

function SpaceSurvivalScreenplay:messagePath(key)
	return "@spacequest/" .. self.questType .. "/" .. self.questName .. ":" .. key
end

-- True if args starts with the id of the player's current run
function SpaceSurvivalScreenplay:isCurrentRun(pPlayer, args)
	if (pPlayer == nil) then
		return false
	end

	local runID = tonumber(string.match(tostring(args), "^(%d+)"))

	if (runID == nil) then
		return false
	end

	return readData(self:dataKey(SceneObject(pPlayer):getObjectID(), "areaID")) == runID
end

-- Run token as a string for event args
function SpaceSurvivalScreenplay:getRunToken(playerID)
	return string.format("%d", readData(self:dataKey(playerID, "areaID")))
end

function SpaceSurvivalScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_SURVIVAL) then
		print(self.className .. ":startQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	if (pNpc == "") then
		pNpc = nil
	end

	-- Activate the Journal Quest
	if (not SpaceHelpers:activateSpaceQuest(pPlayer, pNpc, self.questType, self.questName, false)) then
		return
	end

	-- Create inital observer for player entering Zone and to handle failing quest
	if (not hasObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)) then
		createObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer, 1)
	end

	-- Check if the player is in the proper zone already
	if (getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone) and not SpaceHelpers:isInYacht(pPlayer)) then
		self:setupRun(pPlayer)
	end
end

-- Waypoint and arrival area, once per run
function SpaceSurvivalScreenplay:setupRun(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "areaID")) ~= 0) then
		return
	end

	local point = self.transmissionPoint
	local pArea = spawnSpaceActiveArea(self.questZone, "object/space_active_area.iff", point.x, point.z, point.y, self.arrivalRadius)

	if (pArea == nil) then
		Logger:log(self.className .. ":setupRun -- pArea is nil.", LT_ERROR)
		return
	end

	writeData(self:dataKey(playerID, "areaID"), SceneObject(pArea):getObjectID())
	createObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)

	-- Complete the quest task 0
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	-- Activate quest task 1
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, true)

	local waypointID = PlayerObject(pGhost):addWaypoint(self.questZone, "Mission Objective", "", point.x, point.z, point.y, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	local pWaypoint = getSceneObject(waypointID)

	if (pWaypoint ~= nil) then
		WaypointObject(pWaypoint):setQuestDetails(self:messagePath("title_d"))
	end

	-- Store the waypointID on the player
	setQuestStatus(self:dataKey(playerID, "waypointID"), waypointID)

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("found_loc"))
end

function SpaceSurvivalScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_SURVIVAL) then
		print(self.className .. ":completeQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	local notifyBool = true

	if (notifyClient == "false") then
		notifyBool = false
	end

	-- Complete the Journal Quest
	SpaceHelpers:completeSpaceQuest(pPlayer, self.questType, self.questName, notifyBool)

	self:cleanUpQuestData(pPlayer)

	if (self.sideQuest and (self.sideQuestSplitType == self.SIDE_QUEST_SPLIT_TYPES.COMPLETION or self.sideQuestSplitType == self.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL)) then
		local alertMessage = "@spacequest/" .. self.questType .. "/" .. self.questName .. ":split_quest_alert"

		-- Split Quest Alert
		createEvent(self.sideQuestDelay * 1000, "SpaceHelpers", "sendQuestAlert", pPlayer, alertMessage)

		-- Trigger Sidequest
		createEvent(self.sideQuestDelay * 1050, self.sideQuestType .. "_" .. self.sideQuestName, "startQuest", pPlayer, "")
	end
end

function SpaceSurvivalScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_SURVIVAL) then
		print(self.className .. ":failQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	local notifyBool = true

	if (notifyClient == "false") then
		notifyBool = false
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, notifyBool)

	self:cleanUpQuestData(pPlayer)

	-- Fail the parent quest
	if (self.parentQuestType ~= "") then
		createEvent(200, self.parentQuestType .. "_" .. self.parentQuestName, "failQuest", pPlayer, "false")
	end

	-- Fail the side quest
	if (self.sideQuest and SpaceHelpers:isSpaceQuestActive(pPlayer, self.sideQuestType, self.sideQuestName)) then
		createEvent(200, self.sideQuestType .. "_" .. self.sideQuestName, "failQuest", pPlayer, "false")
	end

	if (self.sideQuest and (self.sideQuestSplitType == self.SIDE_QUEST_SPLIT_TYPES.FAILURE or self.sideQuestSplitType == self.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL)) then
		self:triggerFailureSplitQuest(pPlayer)
	end
end

function SpaceSurvivalScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_SURVIVAL) then
		print(self.className .. ":resetQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)
end

-- Ends the player's run: waypoint, observers, area, attack ships and all stored data
function SpaceSurvivalScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Remove any patrol points
	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	-- Remove the zone entry observer
	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)

	-- Destroy the arrival area
	local areaID = readData(self:dataKey(playerID, "areaID"))

	if (areaID ~= 0) then
		local pArea = getSceneObject(areaID)

		if (pArea ~= nil) then
			dropObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)
			SceneObject(pArea):destroyObjectFromWorld()
		end
	end

	self:removeAttackShips(pPlayer)
	self:cleanUpWaveData(pPlayer)

	deleteData(self:dataKey(playerID, "areaID"))
	deleteData(self:dataKey(playerID, "arrived"))
	deleteData(self:dataKey(playerID, "warned"))
end


--[[

		Space Survival Observers

--]]

function SpaceSurvivalScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Any zone change once the player has arrived (leaving, or the respawn after a ship is destroyed) fails the quest
	if (readData(self:dataKey(playerID, "arrived")) == 1) then
		SpaceHelpers:sendQuestUpdate(pPlayer, "@space/quest:survival_abandoned")
		self:failQuest(pPlayer, "false")
		return 0
	end

	-- ZONESWITCHED fires before the player is moved, so the zone and ship are checked a moment later
	if (zoneNameHash == getHashCode(self.questZone)) then
		createEvent(1000, self.className, "checkSetup", pPlayer, "")
	end

	return 0
end

function SpaceSurvivalScreenplay:checkSetup(pPlayer)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "arrived")) == 1) then
		return
	end

	if (getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone) and not SpaceHelpers:isInYacht(pPlayer)) then
		self:setupRun(pPlayer)
	end
end

function SpaceSurvivalScreenplay:notifyEnteredQuestArea(pActiveArea, pShip)
	if ((pActiveArea == nil) or (pShip == nil) or (not SceneObject(pShip):isPlayerShip())) then
		return 0
	end

	local pPilot = LuaShipObject(pShip):getPilot()

	if (pPilot == nil or not SceneObject(pPilot):isPlayerCreature()) then
		return 0
	end

	-- Player is not actively on this quest
	if (not SpaceHelpers:isSpaceQuestActive(pPilot, self.questType, self.questName)) then
		return 0
	end

	local playerID = SceneObject(pPilot):getObjectID()

	-- Only the area made for this player counts, and only once
	if (readData(self:dataKey(playerID, "areaID")) ~= SceneObject(pActiveArea):getObjectID() or readData(self:dataKey(playerID, "arrived")) == 1) then
		return 0
	end

	self:arrive(pPilot)

	return 0
end

function SpaceSurvivalScreenplay:arrive(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	local runID = self:getRunToken(playerID)

	writeData(self:dataKey(playerID, "arrived"), 1)

	SpaceHelpers:sendQuestProgess(pPlayer, self:messagePath("title"))
	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("arrived_at_loc"))

	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)

	-- Transmission timeline
	local updates = math.max(self.timesToUpdateProgress, 1)
	local step = math.floor(self.totalTransmissionTime / updates)
	local startMs = self.transmissionStartDelay * 1000

	createEvent(startMs, self.className, "transmissionStart", pPlayer, runID)

	for k = 1, updates - 1, 1 do
		createEvent(startMs + k * step * 1000, self.className, "transmissionUpdate", pPlayer, runID .. ":" .. k)
	end

	local receivedMs = startMs + updates * step * 1000

	createEvent(receivedMs, self.className, "transmissionReceived", pPlayer, runID)
	createEvent(receivedMs + self.endMissionDelay * 1000, self.className, "endMission", pPlayer, runID)

	-- Attack waves
	createEvent(self.delayToFirstAttack * 1000, self.className, "firstAttack", pPlayer, runID)

	-- Range checks
	createEvent(self.distanceCheckInterval * 1000, self.className, "checkDistance", pPlayer, runID)
end

--[[

		Space Survival Timers (args start with the run id)

--]]

function SpaceSurvivalScreenplay:transmissionStart(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage(self:messagePath("transmission_start"))
end

function SpaceSurvivalScreenplay:transmissionUpdate(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local k = tonumber(string.match(args, ":(%d+)$"))
	local updates = math.max(self.timesToUpdateProgress, 1)
	local step = math.floor(self.totalTransmissionTime / updates)

	if (k == nil or self.totalTransmissionTime <= 0) then
		return
	end

	local message = LuaStringIdChatParameter(self:messagePath("trans_update"))
	message:setDI(math.floor(100 * k * step / self.totalTransmissionTime))

	CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
end

function SpaceSurvivalScreenplay:transmissionReceived(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage(self:messagePath("transmission_received"))
end

function SpaceSurvivalScreenplay:endMission(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("mission_complete"))
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)

	self:completeQuest(pPlayer, "true")
end

function SpaceSurvivalScreenplay:checkDistance(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pShip = SceneObject(pPlayer):getRootParent()

	if (pShip ~= nil and SceneObject(pShip):isShipObject()) then
		local point = self.transmissionPoint
		local dx = SceneObject(pShip):getWorldPositionX() - point.x
		local dz = SceneObject(pShip):getWorldPositionZ() - point.z
		local dy = SceneObject(pShip):getWorldPositionY() - point.y
		local distance = math.sqrt(dx * dx + dz * dz + dy * dy)
		local warnedKey = self:dataKey(playerID, "warned")

		if (distance > self.maxDistance) then
			if (readData(warnedKey) == 1) then
				CreatureObject(pPlayer):sendSystemMessage(self:messagePath("outofrange_failed"))
				self:failQuest(pPlayer, "true")
				return
			end

			writeData(warnedKey, 1)
			CreatureObject(pPlayer):sendSystemMessage(self:messagePath("outofrange"))
		else
			deleteData(warnedKey)
		end
	end

	createEvent(self.distanceCheckInterval * 1000, self.className, "checkDistance", pPlayer, args)
end

function SpaceSurvivalScreenplay:firstAttack(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("first_attack"))

	createEvent(self.firstWaveDelay * 1000, self.className, "launchWave", pPlayer, args)
end
