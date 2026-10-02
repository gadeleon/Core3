--[[
	Space Delivery Screenplay

	Ported from SWG-Source: script/space/quest_logic/delivery.java (and delivery_no_pickup.java through hasPickup = false)
	Fly to the pickup rendezvous, /dock with the pickup transport, fly to the delivery rendezvous and /dock
	with the delivery transport. Attack waves (SpaceAttackWaves) run from the pickup dock to the end.

	Run token (stale event guard): <pid>:<className>:runID, the object id of the run's first arrival area.
	Every timer carries it in args; handlers re-check against the stored value to ignore ended runs.
	<pid>:<className>:areaID is the current leg's area. No run state lives in Lua variables.

	Observers (SHIPDESTROYED, SHIPDOCKED) only validate and schedule a 0 ms event, they run under engine locks.
]]

SpaceDeliveryScreenplay = SpaceQuestLogic:new {
	className = "SpaceDeliveryScreenplay",

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

	DEBUG_SPACE_DELIVERY = false,

	-- delivery_no_pickup sets this to false
	hasPickup = true,

	-- attackListType values, same as the delivery .tab enum e(sequential=0,random=1)
	ATTACK_LIST_TYPES = {
		SEQUENTIAL = 0,
		RANDOM = 1,
	},

	-- Tuning constants from delivery.java
	arrivalRadius = 150, -- space_quest.PATROL_NAV_RADIUS
	transportSpawnMinDistance = 100,
	transportSpawnMaxDistance = 200,
	transportWarpBaseDelay = 5, -- seconds, plus getRandomNumber(1, 5)
	helloDelay = 2, -- seconds
	nextLegDelay = 2, -- seconds
	finishDelay = 2, -- seconds
	transportDepartDelay = 15, -- seconds
	noPickupAttackDelay = 10, -- seconds
	maxActiveWaves = 2,
	spawnMinDistance = 1000,
	spawnMaxDistance = 1200,
	spawnSpread = 150,
	squadronMinSize = 4,

	-- Per quest data, copied from the delivery .tab
	pickupPoint = {}, -- {patrolPointName = "<name>", x = 0, z = 0, y = 0}; stays {} for delivery_no_pickup
	deliveryPoint = {},
	pickupShip = "", -- ship_mobile template name; "" for delivery_no_pickup
	deliveryShip = "",
	attackShipLists = {}, -- { {"ship", ...}, ... } one inner list per .tab attackShipsN column
	attackPeriod = 0, -- seconds between waves
	attackListType = 0, -- ATTACK_LIST_TYPES
}

SpaceAttackWaves:mixInto(SpaceDeliveryScreenplay)

registerScreenPlay("SpaceDeliveryScreenplay", false)

--[[

		Space Delivery Quest Functions

--]]

function SpaceDeliveryScreenplay:start()
end

-- Prefix of every shared memory key this quest writes for a player
function SpaceDeliveryScreenplay:dataKey(playerID, name)
	return playerID .. ":" .. self.className .. ":" .. name
end

function SpaceDeliveryScreenplay:messagePath(key)
	return "@spacequest/" .. self.questType .. "/" .. self.questName .. ":" .. key
end

-- True if args starts with the id of the player's current run
function SpaceDeliveryScreenplay:isCurrentRun(pPlayer, args)
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
function SpaceDeliveryScreenplay:getRunToken(playerID)
	return string.format("%d", readData(self:dataKey(playerID, "runID")))
end

-- True while the current leg is the pickup leg (leg 1), false for the delivery leg (leg 2)
function SpaceDeliveryScreenplay:isPickupLeg(playerID)
	return self.hasPickup and readData(self:dataKey(playerID, "leg")) == 1
end

function SpaceDeliveryScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_DELIVERY) then
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

-- Creates the arrival area and waypoint of a leg. Returns the area, or nil.
function SpaceDeliveryScreenplay:setupLeg(pPlayer, point, waypointName, detailsKey)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return nil
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pArea = spawnSpaceActiveArea(self.questZone, "object/space_active_area.iff", point.x, point.z, point.y, self.arrivalRadius)

	if (pArea == nil) then
		Logger:log(self.className .. ":setupLeg -- pArea is nil.", LT_ERROR)
		return nil
	end

	writeData(self:dataKey(playerID, "areaID"), SceneObject(pArea):getObjectID())
	writeData(self:dataKey(playerID, "legArrived"), 0)
	createObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)

	local waypointID = PlayerObject(pGhost):addWaypoint(self.questZone, waypointName, "", point.x, point.z, point.y, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	local pWaypoint = getSceneObject(waypointID)

	if (pWaypoint ~= nil) then
		WaypointObject(pWaypoint):setQuestDetails(self:messagePath(detailsKey))
	end

	-- Store the waypointID on the player
	setQuestStatus(self:dataKey(playerID, "waypointID"), waypointID)

	return pArea
end

-- First leg, once per run
function SpaceDeliveryScreenplay:setupRun(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		return
	end

	local pArea

	if (self.hasPickup) then
		pArea = self:setupLeg(pPlayer, self.pickupPoint, "Pickup Rendezvous", "quest_rendezvous1_d")
	else
		pArea = self:setupLeg(pPlayer, self.deliveryPoint, "Delivery Rendezvous", "quest_rendezvous2_d")
	end

	if (pArea == nil) then
		return
	end

	writeData(self:dataKey(playerID, "runID"), SceneObject(pArea):getObjectID())

	if (self.hasPickup) then
		writeData(self:dataKey(playerID, "leg"), 1)
	else
		writeData(self:dataKey(playerID, "leg"), 2)
	end

	-- Complete the quest task 0
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	-- Activate quest task 1
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, true)

	SpaceHelpers:sendQuestProgess(pPlayer, self:messagePath("title"))

	if (self.hasPickup) then
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("found_loc_p"))
	else
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("found_loc_d"))

		-- Without a pickup the waves start a fixed time after setup
		if (self.attackPeriod > 0 and #self.attackShipLists > 0) then
			createEvent((self.noPickupAttackDelay + self.attackPeriod) * 1000, self.className, "launchWave", pPlayer, self:getRunToken(playerID))
		end
	end
end

function SpaceDeliveryScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_DELIVERY) then
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

function SpaceDeliveryScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_DELIVERY) then
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

function SpaceDeliveryScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_DELIVERY) then
		print(self.className .. ":resetQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)
end

-- Ends the player's run: waypoint, observers, area, transport, attack ships and all stored data
function SpaceDeliveryScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Remove any patrol points
	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	-- Remove the zone entry and docking observers
	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)
	dropObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)

	-- Destroy the arrival area
	local areaID = readData(self:dataKey(playerID, "areaID"))

	if (areaID ~= 0) then
		local pArea = getSceneObject(areaID)

		if (pArea ~= nil) then
			dropObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)
			SceneObject(pArea):destroyObjectFromWorld()
		end
	end

	-- Release a transport that is still waiting (released ones depart on their own timer)
	local transportID = readData(self:dataKey(playerID, "transportID"))

	if (transportID ~= 0) then
		local pTransport = getSceneObject(transportID)

		CreatureObject(pPlayer):removeSpaceMissionObject(transportID, false)

		if (pTransport ~= nil) then
			ShipAiAgent(pTransport):setDockable(false)
			dropObserver(SHIPDESTROYED, self.className, "notifyTransportDestroyed", pTransport)

			ShipObject(pTransport):setHyperspacing(true)

			createEvent(2000, "SpaceHelpers", "delayedDestroyShipAgent", pTransport, "")
		end
	end

	self:removeAttackShips(pPlayer)
	self:cleanUpWaveData(pPlayer)

	deleteData(self:dataKey(playerID, "runID"))
	deleteData(self:dataKey(playerID, "areaID"))
	deleteData(self:dataKey(playerID, "transportID"))
	deleteData(self:dataKey(playerID, "leg"))
	deleteData(self:dataKey(playerID, "legArrived"))
end

--[[

		Space Delivery Observers

--]]

function SpaceDeliveryScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
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

	-- Any zone change once the run is set up (leaving, or the respawn after a ship is destroyed) fails the quest
	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		SpaceHelpers:sendQuestUpdate(pPlayer, "@space/quest:mission_abandoned")
		self:failQuest(pPlayer, "false")
		return 0
	end

	-- ZONESWITCHED fires before the player is moved, so the zone and ship are checked a moment later
	if (zoneNameHash == getHashCode(self.questZone)) then
		createEvent(1000, self.className, "checkSetup", pPlayer, "")
	end

	return 0
end

function SpaceDeliveryScreenplay:checkSetup(pPlayer)
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

function SpaceDeliveryScreenplay:notifyEnteredQuestArea(pActiveArea, pShip)
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

	-- Only the leg area made for this player counts, and only once
	if (readData(self:dataKey(playerID, "areaID")) ~= SceneObject(pActiveArea):getObjectID() or readData(self:dataKey(playerID, "legArrived")) == 1) then
		return 0
	end

	self:arrive(pPilot)

	return 0
end

function SpaceDeliveryScreenplay:arrive(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()

	writeData(self:dataKey(playerID, "legArrived"), 1)

	if (self:isPickupLeg(playerID)) then
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("arrived_at_pickup"))
		SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
		SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)
	else
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("arrived_at_delivery"))

		if (self.hasPickup) then
			SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 4, false)
			SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 3, false)
		else
			SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
			SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)
		end
	end

	createEvent((self.transportWarpBaseDelay + getRandomNumber(1, 5)) * 1000, self.className, "warpTransport", pPlayer, self:getRunToken(playerID))
end

--[[

		Space Delivery Timers (args start with the run id)

--]]

function SpaceDeliveryScreenplay:warpTransport(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pickupLeg = self:isPickupLeg(playerID)

	-- One transport per leg
	if (readData(self:dataKey(playerID, "transportID")) ~= 0 or readData(self:dataKey(playerID, "legArrived")) ~= 1) then
		return
	end

	local point = self.deliveryPoint
	local shipName = self.deliveryShip

	if (pickupLeg) then
		point = self.pickupPoint
		shipName = self.pickupShip
	end

	-- Drop the leg area and waypoint
	local areaID = readData(self:dataKey(playerID, "areaID"))
	local pArea = getSceneObject(areaID)

	if (pArea ~= nil) then
		dropObserver(ENTEREDAREA, self.className, "notifyEnteredQuestArea", pArea)
		SceneObject(pArea):destroyObjectFromWorld()
	end

	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	local x, z, y = point.x, point.z, point.y
	local location = SpaceHelpers:getRandomPositionInSphere(point.x, point.z, point.y, self.transportSpawnMinDistance, self.transportSpawnMaxDistance)

	if (type(location) == "table" and location.x ~= nil) then
		x, z, y = location.x, location.z, location.y
	end

	local pPlayerShip = SceneObject(pPlayer):getRootParent()
	local pTransport = spawnShipAgent(shipName, self.questZone, x, z, y, pPlayerShip)

	if (pTransport == nil) then
		Logger:log(self.className .. ":warpTransport -- failed to spawn " .. shipName .. ".", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local transportID = SceneObject(pTransport):getObjectID()
	local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)

	-- Docking is owner-only
	ShipAiAgent(pTransport):setMissionOwner(pPlayer)
	ShipAiAgent(pTransport):addSpaceFactionAlly(playerFactionHash)
	ShipAiAgent(pTransport):removeSpaceFactionEnemy(playerFactionHash)

	-- Dockable ships hold their position
	ShipAiAgent(pTransport):setDockable(true)

	CreatureObject(pPlayer):addSpaceMissionObject(transportID, true)

	createObserver(SHIPDESTROYED, self.className, "notifyTransportDestroyed", pTransport)

	writeData(self:dataKey(playerID, "transportID"), transportID)

	CreatureObject(pPlayer):playEffect("clienteffect/ui_quest_spawn_escort.cef", "")

	if (not hasObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)) then
		createObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)
	end

	createEvent(self.helloDelay * 1000, self.className, "sayHello", pPlayer, args)
end

function SpaceDeliveryScreenplay:sayHello(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local pTransport = getSceneObject(readData(self:dataKey(playerID, "transportID")))

	if (pTransport == nil) then
		return
	end

	if (self:isPickupLeg(playerID)) then
		ShipAiAgent(pTransport):tauntPlayer(pPlayer, self:messagePath("hello_p"))
	else
		ShipAiAgent(pTransport):tauntPlayer(pPlayer, self:messagePath("hello_d"))
	end
end

-- Releases a docked transport: it resumes its patrol and jumps out later, whatever happens to the run
function SpaceDeliveryScreenplay:releaseTransport(pPlayer, pTransport, transportID)
	local playerID = SceneObject(pPlayer):getObjectID()

	ShipAiAgent(pTransport):setDockable(false)
	dropObserver(SHIPDESTROYED, self.className, "notifyTransportDestroyed", pTransport)
	CreatureObject(pPlayer):removeSpaceMissionObject(transportID, true)
	deleteData(self:dataKey(playerID, "transportID"))

	createEvent(self.transportDepartDelay * 1000, self.className, "transportDeparts", pTransport, "")
end

function SpaceDeliveryScreenplay:transportDeparts(pShip, args)
	if (pShip == nil) then
		return
	end

	ShipObject(pShip):setHyperspacing(true)

	createEvent(2000, "SpaceHelpers", "delayedDestroyShipAgent", pShip, "")
end

-- args: <runID>:<transport id>
function SpaceDeliveryScreenplay:dockComplete(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local dockedID = tonumber(string.match(tostring(args), ":(%d+)$"))
	local transportID = readData(self:dataKey(playerID, "transportID"))

	-- Idempotent: the transport is forgotten as soon as the first trigger released it
	if (transportID == 0 or dockedID ~= transportID or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local pTransport = getSceneObject(transportID)

	if (pTransport == nil) then
		return
	end

	local pickupLeg = self:isPickupLeg(playerID)

	if (pickupLeg) then
		ShipAiAgent(pTransport):tauntPlayer(pPlayer, self:messagePath("docking_complete_pickup"))
	else
		ShipAiAgent(pTransport):tauntPlayer(pPlayer, self:messagePath("docking_complete_delivery"))
	end

	self:releaseTransport(pPlayer, pTransport, transportID)

	dropObserver(SHIPDOCKED, self.className, "notifyDocked", pPlayer)

	local runID = self:getRunToken(playerID)

	if (pickupLeg) then
		SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 3, false)
		SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)

		writeData(self:dataKey(playerID, "leg"), 2)

		createEvent(self.nextLegDelay * 1000, self.className, "deliveryLegSetup", pPlayer, runID)

		if (self.attackPeriod > 0 and #self.attackShipLists > 0) then
			createEvent(self.attackPeriod * 1000, self.className, "launchWave", pPlayer, runID)
		end
	else
		if (self.hasPickup) then
			SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 4, false)
		else
			SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
		end

		createEvent(self.finishDelay * 1000, self.className, "finishQuest", pPlayer, runID)
	end
end

function SpaceDeliveryScreenplay:deliveryLegSetup(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	if (self:setupLeg(pPlayer, self.deliveryPoint, "Delivery Rendezvous", "quest_rendezvous2_d") == nil) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("found_loc_d"))
end

function SpaceDeliveryScreenplay:finishQuest(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	self:completeQuest(pPlayer, "true")
end

function SpaceDeliveryScreenplay:transportLost(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "transportID")) == 0) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("failed_destroyed"))
	self:failQuest(pPlayer, "true")
end

--[[

		Space Delivery Ship Observers

--]]

-- SHIPDOCKED on the player creature, fired with the pilot and target locked: validate and defer
function SpaceDeliveryScreenplay:notifyDocked(pPlayer, pTargetShip, cargoHash)
	if (pPlayer == nil or pTargetShip == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 0
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local transportID = readData(self:dataKey(playerID, "transportID"))

	if (transportID == 0 or SceneObject(pTargetShip):getObjectID() ~= transportID) then
		return 0
	end

	createEvent(0, self.className, "dockComplete", pPlayer, self:getRunToken(playerID) .. ":" .. transportID)

	return 1
end

-- SHIPDESTROYED on the transport: validate and defer
function SpaceDeliveryScreenplay:notifyTransportDestroyed(pShip, pKillerShip)
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

	if (readData(self:dataKey(playerID, "transportID")) ~= SceneObject(pShip):getObjectID()) then
		return 1
	end

	createEvent(0, self.className, "transportLost", pPlayer, self:getRunToken(playerID))

	return 1
end

-- Wave hook: tells the player how many attack ships are left
function SpaceDeliveryScreenplay:notifyTargetsRemaining(pPlayer, remaining)
	local message = LuaStringIdChatParameter("@space/quest:destroy_duty_targets_remaining")
	message:setDI(remaining)

	CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
end
