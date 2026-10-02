--[[
	Space Rescue Screenplay

	Ported from SWG-Source: script/space/quest_logic/rescue.java (extends recovery.java) and rescue_target.java
	Used by: RSF tier 3 (Dulios, Naboo), Havoc tier 4 (Warvog Arkon, Lok) quests
	Feature: space-quest-rescue-docking

	The target warps in near the first recoveryPath point and holds position as a dockable mission ship. The player
	/docks with it, ten seconds later the repaired target flies the recoveryPath under escort while attack waves
	(SpaceAttackWaves) go for it. The quest completes when the target enters the area at the last point.

	Run token (stale event guard): <pid>:<className>:runID, the object id of the run's destination area (also stored
	as areaID). Every timer carries it in args; handlers re-check against the stored value to ignore ended runs.
	No run state lives in Lua variables, it is kept in shared memory under <pid>:<className>:.

	Observers (ZONESWITCHED, SHIPDOCKED, SHIPDESTROYED, ENTEREDAREA) only validate and schedule a 0 ms event, they
	run under engine locks.
]]

SpaceRescueScreenplay = SpaceQuestLogic:new {
	className = "SpaceRescueScreenplay",

	questName = "",
	questType = "rescue",

	questZone = "",

	creditReward = 0,
	itemReward = {
		--{species = {}, item = ""},
	},

	sideQuest = false,
	sideQuestType = "",
	sideQuestName = "",

	DEBUG_SPACE_RESCUE = false,

	-- attackListType values, same as the rescue .tab enum e(sequential=0,random=1)
	ATTACK_LIST_TYPES = {
		SEQUENTIAL = 0,
		RANDOM = 1,
	},

	-- Stage of the run, stored under the "stage" key
	STAGES = {
		WARP = 1,
		DOCK = 2,
		DOCKED = 3,
		ESCORT = 4,
		ARRIVED = 5,
	},

	-- Tuning constants from rescue.java / recovery.java / rescue_target.java
	arrivalRadius = 300,
	setupCheckDelay = 1, -- seconds
	targetSpawnMinDistance = 100,
	targetSpawnMaxDistance = 200,
	waypointFirstDelay = 1, -- seconds
	waypointRefreshPeriod = 30, -- seconds
	escortStartDelay = 10, -- seconds
	finishDelay = 3, -- seconds
	targetLifetime = 3600, -- seconds
	escortSpeed = 50, -- SWG uses the player ship's maximum speed (capped at 100), Lua cannot read it
	repairAmount = 1,
	maxActiveWaves = 2,
	spawnMinDistance = 1000,
	spawnMaxDistance = 1200,
	spawnSpread = 150,
	squadronMinSize = 4,

	-- Per quest data, copied from the rescue .tab
	recoveryPath = {}, -- { {patrolPointName = "<name>", x = 0, z = 0, y = 0}, ... }; [1] is the warp-in point, [#] the destination
	targetShipType = "", -- ship_mobile template
	targetArrivalDelay = 0, -- seconds from setup to warp-in
	attackShipLists = {}, -- { {"ship", ...}, ... } one inner list per .tab attackShipsN column
	attackPeriod = 0, -- seconds between waves
	attackListType = 0, -- ATTACK_LIST_TYPES
	numResponses = 0, -- panic_N / thanks_N range
}

SpaceAttackWaves:mixInto(SpaceRescueScreenplay)

registerScreenPlay("SpaceRescueScreenplay", false)

--[[

		Space Rescue Quest Functions

--]]

function SpaceRescueScreenplay:start()
end

-- Prefix of every shared memory key this quest writes for a player
function SpaceRescueScreenplay:dataKey(playerID, name)
	return playerID .. ":" .. self.className .. ":" .. name
end

function SpaceRescueScreenplay:messagePath(key)
	return "@spacequest/" .. self.questType .. "/" .. self.questName .. ":" .. key
end

-- True if args starts with the id of the player's current run
function SpaceRescueScreenplay:isCurrentRun(pPlayer, args)
	if (pPlayer == nil) then
		return false
	end

	local runID = tonumber(string.match(tostring(args), "^(%d+)"))

	if (runID == nil) then
		return false
	end

	return readData(self:dataKey(SceneObject(pPlayer):getObjectID(), "runID")) == runID
end

-- Run token as a string for event args
function SpaceRescueScreenplay:getRunToken(playerID)
	return string.format("%d", readData(self:dataKey(playerID, "runID")))
end

--[[

		Extension points (Duty Rescue overrides these)

--]]

-- The run's path
function SpaceRescueScreenplay:pathPoints(playerID)
	return self.recoveryPath
end

-- Template of the target ship
function SpaceRescueScreenplay:pickTargetShip(playerID)
	return self.targetShipType
end

function SpaceRescueScreenplay:capturePhraseKey(playerID)
	return "rescue_phase_2"
end

function SpaceRescueScreenplay:completePhraseKey(playerID)
	return "complete"
end

-- What happens after the target arrived
function SpaceRescueScreenplay:onRescueArrived(pPlayer, token)
	createEvent(self.finishDelay * 1000, self.className, "finishQuest", pPlayer, token)
end

function SpaceRescueScreenplay:isStage(playerID, ...)
	local stage = readData(self:dataKey(playerID, "stage"))

	for _, wanted in ipairs({...}) do
		if (stage == wanted) then
			return true
		end
	end

	return false
end

function SpaceRescueScreenplay:getTarget(playerID)
	local targetID = readData(self:dataKey(playerID, "targetID"))

	if (targetID == 0) then
		return nil
	end

	return getSceneObject(targetID)
end

function SpaceRescueScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_RESCUE) then
		print(self.className .. ":startQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	if (pNpc == "") then
		pNpc = nil
	end

	-- Activate the Journal Quest
	SpaceHelpers:activateSpaceQuest(pPlayer, pNpc, self.questType, self.questName, false)

	-- Create inital observer for player entering Zone and to handle failing quest
	if (not hasObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)) then
		createObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer, 1)
	end

	-- Check if the player is in the proper zone already
	if (getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone) and not SpaceHelpers:isInYacht(pPlayer)) then
		self:setupRun(pPlayer)
	end
end

-- Spawns the destination area and schedules the target warp-in, once per run
function SpaceRescueScreenplay:setupRun(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		return
	end

	local path = self:pathPoints(playerID)

	if (path == nil or #path == 0 or self:pickTargetShip(playerID) == "") then
		Logger:log(self.className .. ":setupRun -- no recoveryPath or target ship for " .. self.questName .. ".", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local last = path[#path]
	local pArea = spawnSpaceActiveArea(self.questZone, "object/space_active_area.iff", last.x, last.z, last.y, self.arrivalRadius)

	if (pArea == nil) then
		Logger:log(self.className .. ":setupRun -- pArea is nil.", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local areaID = SceneObject(pArea):getObjectID()

	createObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)

	writeData(self:dataKey(playerID, "runID"), areaID)
	writeData(self:dataKey(playerID, "areaID"), areaID)
	writeData(self:dataKey(playerID, "stage"), self.STAGES.WARP)

	-- Complete the quest task 0
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	-- Activate quest task 1
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, true)

	SpaceHelpers:sendQuestProgess(pPlayer, self:messagePath("title"))
	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("arrival_phase_1"))

	createEvent(self.targetArrivalDelay * 1000, self.className, "warpTarget", pPlayer, self:getRunToken(playerID))
end

function SpaceRescueScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_RESCUE) then
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

function SpaceRescueScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_RESCUE) then
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

function SpaceRescueScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_RESCUE) then
		print(self.className .. ":resetQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)
end

-- Ends the player's run: waypoint, observers, area, target, attack ships and all stored data
function SpaceRescueScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Remove the waypoint
	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	-- Remove the zone entry and docking observers
	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)
	dropObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)

	-- Destroy the destination area
	local areaID = readData(self:dataKey(playerID, "areaID"))

	if (areaID ~= 0) then
		local pArea = getSceneObject(areaID)

		if (pArea ~= nil) then
			dropObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)
			SceneObject(pArea):destroyObjectFromWorld()
		end
	end

	-- Release the target
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
	end

	self:removeAttackShips(pPlayer)
	self:cleanUpWaveData(pPlayer)

	deleteData(self:dataKey(playerID, "runID"))
	deleteData(self:dataKey(playerID, "areaID"))
	deleteData(self:dataKey(playerID, "targetID"))
	deleteData(self:dataKey(playerID, "stage"))
end

--[[

		Space Rescue Observers

--]]

function SpaceRescueScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local token = self:getRunToken(playerID)

	-- Any zone change once the run is set up (leaving, or the respawn after a ship is destroyed) abandons it
	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		createEvent(0, self.className, "abandonRun", pPlayer, token)
		return 0
	end

	-- ZONESWITCHED fires before the player is moved, so the zone and ship are checked a moment later
	if (zoneNameHash == getHashCode(self.questZone)) then
		createEvent(self.setupCheckDelay * 1000, self.className, "checkSetup", pPlayer, "")
	end

	return 0
end

function SpaceRescueScreenplay:checkSetup(pPlayer)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		return
	end

	if (getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone) and not SpaceHelpers:isInYacht(pPlayer)) then
		self:setupRun(pPlayer)
	end
end

-- ENTEREDAREA on the destination area: only the player's own target counts, in the escort stage
function SpaceRescueScreenplay:notifyEnteredQuestArea(pActiveArea, pShip)
	if (pActiveArea == nil or pShip == nil or not SceneObject(pShip):isShipAiAgent()) then
		return 0
	end

	local pPlayer = getSceneObject(ShipAiAgent(pShip):getMissionOwnerID())

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "targetID")) ~= SceneObject(pShip):getObjectID()) then
		return 0
	end

	if (readData(self:dataKey(playerID, "areaID")) ~= SceneObject(pActiveArea):getObjectID()) then
		return 0
	end

	if (not self:isStage(playerID, self.STAGES.ESCORT)) then
		return 0
	end

	createEvent(0, self.className, "rescueArrived", pPlayer, self:getRunToken(playerID))

	return 0
end

-- SHIPDOCKED on the player creature, fired with the pilot and target locked: validate and defer
function SpaceRescueScreenplay:notifyDocked(pPlayer, pTargetShip, cargoHash)
	if (pPlayer == nil or pTargetShip == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local targetID = readData(self:dataKey(playerID, "targetID"))

	if (targetID == 0 or not self:isStage(playerID, self.STAGES.DOCK) or SceneObject(pTargetShip):getObjectID() ~= targetID) then
		return 0
	end

	createEvent(0, self.className, "dockComplete", pPlayer, self:getRunToken(playerID) .. ":" .. targetID)

	return 1
end

-- SHIPDESTROYED on the target: validate and defer
function SpaceRescueScreenplay:notifyTargetDestroyed(pShip, pKillerShip)
	if (pShip == nil) then
		return 1
	end

	local pPlayer = getSceneObject(ShipAiAgent(pShip):getMissionOwnerID())

	if (pPlayer == nil) then
		return 1
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "targetID")) ~= SceneObject(pShip):getObjectID()) then
		return 1
	end

	if (not self:isStage(playerID, self.STAGES.DOCK, self.STAGES.DOCKED, self.STAGES.ESCORT)) then
		return 1
	end

	createEvent(0, self.className, "targetLost", pPlayer, self:getRunToken(playerID))

	return 1
end

--[[

		Space Rescue Timers (args start with the run id)

--]]

function SpaceRescueScreenplay:abandonRun(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, "@space/quest:rescue_abandoned")
	self:failQuest(pPlayer, "false")
end

function SpaceRescueScreenplay:warpTarget(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.WARP)) then
		return
	end

	local first = self:pathPoints(playerID)[1]
	local x, z, y = first.x, first.z, first.y
	local location = SpaceHelpers:getRandomPositionInSphere(first.x, first.z, first.y, self.targetSpawnMinDistance, self.targetSpawnMaxDistance)

	if (type(location) == "table" and location.x ~= nil) then
		x, z, y = location.x, location.z, location.y
	end

	local shipName = self:pickTargetShip(playerID)
	local pPlayerShip = SceneObject(pPlayer):getRootParent()
	local pTarget = spawnShipAgent(shipName, self.questZone, x, z, y, pPlayerShip)

	if (pTarget == nil) then
		Logger:log(self.className .. ":warpTarget -- failed to spawn " .. shipName .. ".", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local targetID = SceneObject(pTarget):getObjectID()
	local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)

	-- Docking is owner-only
	ShipAiAgent(pTarget):setMissionOwner(pPlayer)
	ShipAiAgent(pTarget):addSpaceFactionAlly(playerFactionHash)
	ShipAiAgent(pTarget):removeSpaceFactionEnemy(playerFactionHash)

	-- Dockable ships hold their position
	ShipAiAgent(pTarget):setDockable(true)

	CreatureObject(pPlayer):addSpaceMissionObject(targetID, true)

	createObserver(SHIPDESTROYED, self.className, "notifyTargetDestroyed", pTarget)

	writeData(self:dataKey(playerID, "targetID"), targetID)
	writeData(self:dataKey(playerID, "stage"), self.STAGES.DOCK)

	if (not hasObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)) then
		createObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("arrival_phase_2"))

	createEvent(self.waypointFirstDelay * 1000, self.className, "refreshWaypoint", pPlayer, args)
	createEvent(self.targetLifetime * 1000, self.className, "targetExpired", pPlayer, args)
end

-- Moves the "Mission Target" waypoint to the target
function SpaceRescueScreenplay:refreshWaypoint(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.DOCK, self.STAGES.DOCKED, self.STAGES.ESCORT)) then
		return
	end

	local pTarget = self:getTarget(playerID)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pTarget == nil or pGhost == nil) then
		return
	end

	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	local detailsKey = "quest_dock_d"

	if (self:isStage(playerID, self.STAGES.ESCORT)) then
		detailsKey = "quest_escort_d"
	end

	local waypointID = PlayerObject(pGhost):addWaypoint(self.questZone, "Mission Target", "", SceneObject(pTarget):getPositionX(), SceneObject(pTarget):getPositionZ(), SceneObject(pTarget):getPositionY(), WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	local pWaypoint = getSceneObject(waypointID)

	if (pWaypoint ~= nil) then
		WaypointObject(pWaypoint):setQuestDetails(self:messagePath(detailsKey))
	end

	setQuestStatus(self:dataKey(playerID, "waypointID"), waypointID)

	createEvent(self.waypointRefreshPeriod * 1000, self.className, "refreshWaypoint", pPlayer, args)
end

-- args: <runID>:<target id>
function SpaceRescueScreenplay:dockComplete(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local dockedID = tonumber(string.match(tostring(args), ":(%d+)$"))
	local targetID = readData(self:dataKey(playerID, "targetID"))

	-- Idempotent: only the first trigger finds the DOCK stage
	if (targetID == 0 or dockedID ~= targetID or not self:isStage(playerID, self.STAGES.DOCK)) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local pTarget = getSceneObject(targetID)

	if (pTarget == nil) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("docking_complete"))
	ShipAiAgent(pTarget):tauntPlayer(pPlayer, self:messagePath(self:capturePhraseKey(playerID)))

	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)

	writeData(self:dataKey(playerID, "stage"), self.STAGES.DOCKED)

	-- The target stays dockable (held in place) until the escort starts
	createEvent(self.escortStartDelay * 1000, self.className, "startEscort", pPlayer, self:getRunToken(playerID))
end

-- Repairs the target and sends it along the path, then releases it
function SpaceRescueScreenplay:startEscort(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.DOCKED)) then
		return
	end

	local pTarget = self:getTarget(playerID)

	if (pTarget == nil) then
		return
	end

	local names = {}
	local path = self:pathPoints(playerID)

	for i = 1, #path, 1 do
		names[#names + 1] = path[i].patrolPointName
	end

	ShipAiAgent(pTarget):repairShipAgent(self.repairAmount)
	ShipAiAgent(pTarget):setFixedPatrol()
	ShipAiAgent(pTarget):setEscort()
	ShipAiAgent(pTarget):setEscortSpeed(self.escortSpeed)
	ShipAiAgent(pTarget):assignFixedPatrolPointsTable(names)

	-- Released last, so the next patrol the AI generates is the escort route
	ShipAiAgent(pTarget):setDockable(false)

	writeData(self:dataKey(playerID, "stage"), self.STAGES.ESCORT)

	if (self.attackPeriod > 0 and #self.attackShipLists > 0) then
		createEvent(self.attackPeriod * 1000, self.className, "launchWave", pPlayer, args)
	end
end

function SpaceRescueScreenplay:rescueArrived(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.ESCORT)) then
		return
	end

	writeData(self:dataKey(playerID, "stage"), self.STAGES.ARRIVED)

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("recovery_success"))
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)

	local pTarget = self:getTarget(playerID)

	if (pTarget ~= nil) then
		ShipAiAgent(pTarget):tauntPlayer(pPlayer, self:messagePath(self:completePhraseKey(playerID)))
	end

	self:onRescueArrived(pPlayer, self:getRunToken(playerID))
end

function SpaceRescueScreenplay:finishQuest(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	self:completeQuest(pPlayer, "true")
end

function SpaceRescueScreenplay:targetLost(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.DOCK, self.STAGES.DOCKED, self.STAGES.ESCORT)) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("failed_destroy"))
	self:failQuest(pPlayer, "true")
end

function SpaceRescueScreenplay:targetExpired(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.DOCK, self.STAGES.DOCKED, self.STAGES.ESCORT)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("@space/quest:warpout_failure")
	self:failQuest(pPlayer, "true")
end

--[[

		Wave hooks (override the SpaceAttackWaves defaults, defined after mixInto)

--]]

-- Waves attack the target, and only while it is being escorted
function SpaceRescueScreenplay:getWaveAnchor(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()

	if (not self:isStage(playerID, self.STAGES.ESCORT)) then
		return nil
	end

	return self:getTarget(playerID)
end

function SpaceRescueScreenplay:notifyWaveLaunched(pPlayer)
	if (self.numResponses < 1) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pTarget = self:getTarget(playerID)

	if (pTarget ~= nil) then
		ShipAiAgent(pTarget):tauntPlayer(pPlayer, self:messagePath("panic_" .. getRandomNumber(1, self.numResponses)))
	end
end

function SpaceRescueScreenplay:notifyWavesCleared(pPlayer)
	if (self.numResponses < 1) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pTarget = self:getTarget(playerID)

	if (pTarget ~= nil) then
		ShipAiAgent(pTarget):tauntPlayer(pPlayer, self:messagePath("thanks_" .. getRandomNumber(1, self.numResponses)))
	end
end

-- Wave hook: tells the player how many attack ships are left
function SpaceRescueScreenplay:notifyTargetsRemaining(pPlayer, remaining)
	local message = LuaStringIdChatParameter("@space/quest:destroy_duty_targets_remaining")
	message:setDI(remaining)

	CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
end
