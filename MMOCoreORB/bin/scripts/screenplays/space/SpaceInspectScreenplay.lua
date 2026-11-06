--[[
	Space Inspect Screenplay

	Ported from SWG-Source: script/space/quest_logic/inspect.java and the player_spacequest.java cmdDock/finishTransfer path
	Used by: CorSec tier 2/3, Havoc tier 2/3, RSF tier 3 quests
	Feature: space-quest-inspect-cargo

	The player enters the quest zone and gets one "Possible Target Location" waypoint per validSpawns entry, optionally
	/inspects ships until one carries the quest cargo, then disables a target ship and /docks with it to recover the cargo.

	Run state is the journal: task 0 complete means "set up", task 1 is the inspect stage, task 2 the dock stage.
	The only shared memory key is <pid>:<className>:waypointVector. Observers only validate and schedule a 0 ms event.
]]

SpaceInspectScreenplay = SpaceQuestLogic:new {
	className = "SpaceInspectScreenplay",

	questName = "",
	questType = "inspect",

	questZone = "",

	creditReward = 0,
	itemReward = {
		--{species = {}, item = ""},
	},

	sideQuest = false,
	sideQuestType = "",

	DEBUG_SPACE_INSPECT = false,

	-- Tuning constants from inspect.java
	setupDelay = 1000, -- ms
	waypointNoticeDelay = 1000, -- ms
	waypointName = "@spacequest/generic:possible_target_location_t",
	waypointDetails = "@spacequest/generic:possible_target_location_d",
	firstSpawnTask = 3,

	-- Per quest data, copied from the inspect .tab
	shipList = {}, -- ship_mobile template names
	validSpawns = {}, -- { {spawnName = "<name>", x = 0, z = 0, y = 0}, ... }
	giveSpawnWaypoint = 0, -- 1 = add a waypoint per validSpawns entry
	cargo = "", -- cargo name compared with the ship's cargoString
}

registerScreenPlay("SpaceInspectScreenplay", false)

--[[

		Space Inspect Quest Functions

--]]

function SpaceInspectScreenplay:start()
end

function SpaceInspectScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_INSPECT) then
		print(self.className .. ":startQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	if (pNpc == "") then
		pNpc = nil
	end

	-- Activate the Journal Quest
	if (not SpaceHelpers:activateSpaceQuest(pPlayer, pNpc, "inspect", self.questName, false)) then
		return
	end

	-- Activate the quest task 0, wherever the player is
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	-- Observer for zone entry and for failing the quest
	if (not hasObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)) then
		createObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer, 1)
	end

	-- Setup the inspection if the player is already in the quest zone
	if (self:isInQuestZone(pPlayer) and not SpaceHelpers:isInYacht(pPlayer)) then
		createEvent(self.setupDelay, self.className, "setupInspection", pPlayer, "")
	end
end

function SpaceInspectScreenplay:isInQuestZone(pPlayer)
	return getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone)
end

function SpaceInspectScreenplay:hasQuestData()
	return #self.shipList > 0 and self.cargo ~= ""
end

function SpaceInspectScreenplay:isQuestCargo(cargoHash)
	return tonumber(cargoHash) == getHashCode(self.cargo)
end

function SpaceInspectScreenplay:isQuestTarget(pTargetShip)
	if (pTargetShip == nil or not SceneObject(pTargetShip):isShipAiAgent()) then
		return false
	end

	local templateName = ShipAiAgent(pTargetShip):getShipAgentTemplateName()
	local isListed = false

	for i = 1, #self.shipList, 1 do
		if (self.shipList[i] == templateName) then
			isListed = true
			break
		end
	end

	if (not isListed) then
		return false
	end

	-- SWG inspect.java: no spawner list means any spawner counts
	if (#self.validSpawns == 0) then
		return true
	end

	local spawnerName = readStringData(SceneObject(pTargetShip):getObjectID() .. ":SpawnerName:")

	for i = 1, #self.validSpawns, 1 do
		if (self.validSpawns[i].spawnName == spawnerName) then
			return true
		end
	end

	return false
end

function SpaceInspectScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	SpaceHelpers:clearQuestWaypoints(pPlayer, self.className)

	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)
	dropObserver(INSPECTEDSHIP, self.className, "inspectedShip", pPlayer)
	dropObserver(SHIPDOCKED, self.className, "dockedShip", pPlayer)
end

function SpaceInspectScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_INSPECT) then
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

function SpaceInspectScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_INSPECT) then
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

function SpaceInspectScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_INSPECT) then
		print(self.className .. ":resetQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)
end

-- Event: sets the inspection up once the player is in the quest zone
function SpaceInspectScreenplay:setupInspection(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (SpaceHelpers:isSpaceQuestTaskComplete(pPlayer, self.questType, self.questName, 0)) then
		return
	end

	if (not self:isInQuestZone(pPlayer) or SpaceHelpers:isInYacht(pPlayer)) then
		return
	end

	if (not self:hasQuestData()) then
		Logger:log(self.className .. " -- Quest has no inspect data (shipList, cargo), failing the quest.", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		self:failQuest(pPlayer, "true")
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Activate the inspect task, complete the location task
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, true)
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	if (self.giveSpawnWaypoint == 1) then
		local waypointIDs = {}

		for i = 1, #self.validSpawns, 1 do
			local point = self.validSpawns[i]
			local waypointID = PlayerObject(pGhost):addWaypoint(self.questZone, self.waypointName, "", point.x, point.z, point.y, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)

			if (waypointID > 0) then
				waypointIDs[#waypointIDs + 1] = tostring(waypointID)

				local pWaypoint = getSceneObject(waypointID)

				if (pWaypoint ~= nil) then
					WaypointObject(pWaypoint):setQuestDetails(self.waypointDetails)
				end
			end

			SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, self.firstSpawnTask + i - 1, true)
		end

		writeStringVectorSharedMemory(playerID .. ":" .. self.className .. ":waypointVector", waypointIDs)

		if (#waypointIDs > 0) then
			createEvent(self.waypointNoticeDelay, self.className, "notifyTargetWaypoints", pPlayer, tostring(#waypointIDs))
		end
	end

	if (not hasObserver(INSPECTEDSHIP, self.className, "inspectedShip", pPlayer)) then
		createObserver(INSPECTEDSHIP, self.className, "inspectedShip", pPlayer, 1)
	end

	if (not hasObserver(SHIPDOCKED, self.className, "dockedShip", pPlayer)) then
		createObserver(SHIPDOCKED, self.className, "dockedShip", pPlayer, 1)
	end
end

-- Event: tells the player how many target locations were added
function SpaceInspectScreenplay:notifyTargetWaypoints(pPlayer, countString)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local message = LuaStringIdChatParameter("@space/quest:inspect_target_waypoints")
	message:setDI(tonumber(countString) or 0)

	CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
end

-- Event: the inspected ship carries the quest cargo
function SpaceInspectScreenplay:cargoFound(pPlayer, args)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestTaskActive(pPlayer, self.questType, self.questName, 1)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("@space/quest:inspect_found_cargo")

	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, true)
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)
end

-- Event: the player docked with a quest target
function SpaceInspectScreenplay:cargoRecovered(pPlayer, targetIdString)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	local targetID = tonumber(targetIdString)

	if (targetID ~= nil) then
		local pTarget = getSceneObject(targetID)

		-- The cargo is taken from the ship
		if (pTarget ~= nil) then
			ShipObject(pTarget):setCargoString("")
		end
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, "@space/quest:inspect_recovered_cargo")

	if (SpaceHelpers:isSpaceQuestTaskActive(pPlayer, self.questType, self.questName, 2)) then
		SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
	end

	self:completeQuest(pPlayer, "true")
end

-- Event: the player left the zone after setup
function SpaceInspectScreenplay:abandonInspection(pPlayer, args)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	self:failQuest(pPlayer, "true")
end

--[[

		Space Inspect Observers

--]]

function SpaceInspectScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	if (SpaceHelpers:isSpaceQuestTaskComplete(pPlayer, self.questType, self.questName, 0)) then
		createEvent(0, self.className, "abandonInspection", pPlayer, "")

		return 0
	end

	if (zoneNameHash == getHashCode(self.questZone)) then
		createEvent(self.setupDelay, self.className, "setupInspection", pPlayer, "")
	end

	return 0
end

function SpaceInspectScreenplay:inspectedShip(pPlayer, pTargetShip, cargoHash)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	if (pTargetShip == nil or not self:isQuestCargo(cargoHash)) then
		return 0
	end

	createEvent(0, self.className, "cargoFound", pPlayer, "")

	return 1
end

function SpaceInspectScreenplay:dockedShip(pPlayer, pTargetShip, cargoHash)
	if (pPlayer == nil or not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	if (not self:isQuestCargo(cargoHash) or not self:isQuestTarget(pTargetShip)) then
		return 0
	end

	createEvent(0, self.className, "cargoRecovered", pPlayer, tostring(SceneObject(pTargetShip):getObjectID()))

	return 1
end
