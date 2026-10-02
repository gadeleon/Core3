--[[
	Space Battle Screenplay

	Ported from SWG-Source: script/space/quest_logic/space_battle.java and space_battle_ship.java
	Used by: CorSec tier 4, RSF tier 3, Havoc tier 3 and 4 battle quests
	Feature: space-quest-stub-space-battle

	An allied and an enemy force warp in at the battle point after their arrival delays (no fly-in from the origin,
	the origin distances are kept as data only). The battle starts once both forces are there. Destroying every
	enemy wins the quest, losing every ally fails it, each two seconds after the last kill. A warp-out timeout ends
	battles that go on too long, and any zone change after setup abandons the run.

	Run token (stale event guard): <pid>:<className>:runID, the object id of the run's waypoint, which is new for
	every run. Every timer carries it in args; handlers re-check against the stored value to ignore ended runs.
	No run state lives in Lua variables, it is kept in shared memory under <pid>:<className>:.

	Observers (ZONESWITCHED, SHIPDESTROYED) only validate and schedule a 0 ms event, they run under engine locks.
	Engage orders (engageShipTarget) are only given from the battle start and kill handling timers.
]]

SpaceBattleScreenplay = SpaceQuestLogic:new {
	className = "SpaceBattleScreenplay",

	questName = "",
	questType = "space_battle",

	questZone = "",

	creditReward = 0,
	itemReward = {},

	parentQuest = "",
	parentQuestType = "",
	parentQuestName = "",

	sideQuest = false,
	sideQuestType = "",
	sideQuestName = "",
	sideQuestSplitType = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.NONE,
	sideQuestDelay = 5, -- Time in seconds to wait to trigger side quest

	DEBUG_SPACE_BATTLE = false,

	-- Sides of the battle (space_battle.java enemy 0/1)
	SIDES = {
		ALLY = 1,
		ENEMY = 2,
	},

	-- Stage of the run, stored under the "stage" key
	STAGES = {
		SETUP = 1,
		BATTLE = 2,
		RESOLVED = 3,
	},

	-- Tuning constants from space_battle.java / space_battle_ship.java
	setupCheckDelay = 1, -- seconds
	resolveDelay = 2, -- seconds
	warpoutTimeout = 1500, -- seconds
	formationSpread = 100, -- meters, replaces squadSetFormationRandom

	-- Per quest data, copied from the space_battle .tab
	battlePoint = {}, -- {patrolPointName = "<name>", x = 0, z = 0, y = 0, forward = {x = 0, z = 0, y = 0}}
	damageMultiplier = 1, -- stored only, Core3 has no NPC vs NPC damage scaling
	allyArrivalDelay = 0, -- seconds from setup
	enemyArrivalDelay = 0, -- seconds from setup
	allyOriginDist = 0, -- stored only, forces warp in at their arrival point
	enemyOriginDist = 0, -- stored only
	allyArrivalDist = 0, -- meters along battlePoint.forward
	enemyArrivalDist = 0, -- meters along battlePoint.forward
	allyForce = {}, -- {"ship_template", ...}
	enemyForce = {}, -- {"ship_template", ...}
}

registerScreenPlay("SpaceBattleScreenplay", false)

--[[

		Space Battle Quest Functions

--]]

function SpaceBattleScreenplay:start()
end

-- Prefix of every shared memory key this quest writes for a player
function SpaceBattleScreenplay:dataKey(playerID, name)
	return playerID .. ":" .. self.className .. ":" .. name
end

function SpaceBattleScreenplay:messagePath(key)
	return "@spacequest/" .. self.questType .. "/" .. self.questName .. ":" .. key
end

-- True if args starts with the id of the player's current run
function SpaceBattleScreenplay:isCurrentRun(pPlayer, args)
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
function SpaceBattleScreenplay:getRunToken(playerID)
	return string.format("%d", readData(self:dataKey(playerID, "runID")))
end

function SpaceBattleScreenplay:isStage(playerID, ...)
	local stage = readData(self:dataKey(playerID, "stage"))

	for _, wanted in ipairs({...}) do
		if (stage == wanted) then
			return true
		end
	end

	return false
end

-- Ids of the live ships of a side, in spawn order
function SpaceBattleScreenplay:liveIDs(playerID, side)
	local ids = {}

	for i, id in ipairs(readStringVectorSharedMemory(self:dataKey(playerID, "ids:" .. side))) do
		ids[i] = tonumber(id)
	end

	return ids
end

function SpaceBattleScreenplay:forceOf(side)
	if (side == self.SIDES.ALLY) then
		return self.allyForce
	end

	return self.enemyForce
end

function SpaceBattleScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_BATTLE) then
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

-- Waypoint and the arrival timers of both forces, once per run
function SpaceBattleScreenplay:setupRun(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		return
	end

	local point = self.battlePoint

	if (point == nil or point.patrolPointName == nil or #self.allyForce == 0 or #self.enemyForce == 0) then
		Logger:log(self.className .. ":setupRun -- missing battle point or force for " .. self.questName .. ".", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	local waypointID = PlayerObject(pGhost):addWaypoint(self.questZone, "Mission Objective", "", point.x, point.z, point.y, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	local pWaypoint = getSceneObject(waypointID)

	if (pWaypoint ~= nil) then
		WaypointObject(pWaypoint):setQuestDetails(self:messagePath("title_d"))
	end

	-- Store the waypointID on the player
	setQuestStatus(self:dataKey(playerID, "waypointID"), waypointID)

	writeData(self:dataKey(playerID, "runID"), waypointID)
	writeData(self:dataKey(playerID, "stage"), self.STAGES.SETUP)

	-- Complete the quest task 0
	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)

	-- Activate quest task 1
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, true)

	SpaceHelpers:sendQuestProgess(pPlayer, self:messagePath("title"))
	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("found_loc"))

	local token = self:getRunToken(playerID)

	createEvent(self.allyArrivalDelay * 1000, self.className, "forceArrives", pPlayer, token .. ":" .. self.SIDES.ALLY)
	createEvent(self.enemyArrivalDelay * 1000, self.className, "forceArrives", pPlayer, token .. ":" .. self.SIDES.ENEMY)
end

function SpaceBattleScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_BATTLE) then
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

function SpaceBattleScreenplay:failQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to failQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_BATTLE) then
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

function SpaceBattleScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log(self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (self.DEBUG_SPACE_BATTLE) then
		print(self.className .. ":resetQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Set Quest failed
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	self:cleanUpQuestData(pPlayer)
end

-- Ends the player's run: waypoint, observers, both forces and all stored data
function SpaceBattleScreenplay:cleanUpQuestData(pPlayer)
	if (pPlayer == nil) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Remove the waypoint
	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	-- Remove the zone entry observer
	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)

	for _, side in pairs(self.SIDES) do
		for _, shipID in ipairs(self:liveIDs(playerID, side)) do
			local pShip = getSceneObject(shipID)

			CreatureObject(pPlayer):removeSpaceMissionObject(shipID, false)

			if (pShip ~= nil) then
				dropObserver(SHIPDESTROYED, self.className, "notifyBattleShipDestroyed", pShip)

				ShipObject(pShip):setHyperspacing(true)

				createEvent(2000, "SpaceHelpers", "delayedDestroyShipAgent", pShip, "")
			end

			deleteData(self:dataKey(playerID, "side:" .. shipID))
			deleteData(self:dataKey(playerID, "target:" .. shipID))
		end

		deleteStringVectorSharedMemory(self:dataKey(playerID, "ids:" .. side))
		deleteData(self:dataKey(playerID, "live:" .. side))
		deleteData(self:dataKey(playerID, "arrived:" .. side))
		deleteData(self:dataKey(playerID, "engageCursor:" .. side))
	end

	deleteData(self:dataKey(playerID, "runID"))
	deleteData(self:dataKey(playerID, "stage"))
end

--[[

		Space Battle Observers

--]]

function SpaceBattleScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- Any zone change once the run is set up (leaving, or the respawn after a ship is destroyed) abandons it
	if (readData(self:dataKey(playerID, "runID")) ~= 0) then
		createEvent(0, self.className, "abandonRun", pPlayer, self:getRunToken(playerID))
		return 0
	end

	-- ZONESWITCHED fires before the player is moved, so the zone and ship are checked a moment later
	if (zoneNameHash == getHashCode(self.questZone)) then
		createEvent(self.setupCheckDelay * 1000, self.className, "checkSetup", pPlayer, "")
	end

	return 0
end

function SpaceBattleScreenplay:checkSetup(pPlayer)
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

-- SHIPDESTROYED on a force ship: validate and defer
function SpaceBattleScreenplay:notifyBattleShipDestroyed(pShip, pKillerShip)
	if (pShip == nil) then
		return 1
	end

	local pPlayer = getSceneObject(ShipAiAgent(pShip):getMissionOwnerID())

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 1
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local shipID = SceneObject(pShip):getObjectID()

	if (readData(self:dataKey(playerID, "side:" .. shipID)) == 0) then
		return 1
	end

	createEvent(0, self.className, "shipLost", pPlayer, self:getRunToken(playerID) .. ":" .. shipID)

	return 1
end

--[[

		Space Battle Timers (args start with the run id)

--]]

function SpaceBattleScreenplay:abandonRun(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, "@space/quest:battle_abandoned")
	self:failQuest(pPlayer, "false")
end

-- args: <runID>:<side>
function SpaceBattleScreenplay:forceArrives(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local side = tonumber(string.match(tostring(args), ":(%d+)$"))

	if (side == nil or self:isStage(playerID, self.STAGES.RESOLVED)) then
		return
	end

	local isAlly = (side == self.SIDES.ALLY)
	local force = self:forceOf(side)
	local distance = self.enemyArrivalDist
	local effect = "clienteffect/ui_quest_spawn_enemy.cef"
	local updateKey = "enemies_arrived"

	if (isAlly) then
		distance = self.allyArrivalDist
		effect = "clienteffect/ui_quest_spawn_friendly.cef"
		updateKey = "allies_arrived"
	end

	local point = self.battlePoint
	local forward = point.forward
	local baseX = point.x + distance * forward.x
	local baseZ = point.z + distance * forward.z
	local baseY = point.y + distance * forward.y
	local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)

	local shipIDs = {}
	local pLeader = nil

	for i = 1, #force, 1 do
		local x = baseX + getRandomNumber(-self.formationSpread, self.formationSpread)
		local y = baseY + getRandomNumber(-self.formationSpread, self.formationSpread)
		local pShip = spawnShipAgent(force[i], self.questZone, x, baseZ, y)

		if (pShip == nil) then
			Logger:log(self.className .. ":forceArrives -- failed to spawn " .. force[i] .. ".", LT_ERROR)
		else
			local shipID = SceneObject(pShip):getObjectID()

			ShipAiAgent(pShip):setMissionOwner(pPlayer)

			if (isAlly) then
				ShipAiAgent(pShip):removeSpaceFactionEnemy(playerFactionHash)
				ShipAiAgent(pShip):addSpaceFactionAlly(playerFactionHash)
			else
				ShipAiAgent(pShip):addSpaceFactionEnemy(playerFactionHash)
			end

			if (pLeader == nil) then
				ShipAiAgent(pShip):createSquadron()
				pLeader = pShip
			else
				ShipAiAgent(pShip):assignToSquadron(pLeader)
			end

			CreatureObject(pPlayer):addSpaceMissionObject(shipID, i == #force)

			createObserver(SHIPDESTROYED, self.className, "notifyBattleShipDestroyed", pShip)

			writeData(self:dataKey(playerID, "side:" .. shipID), side)
			shipIDs[#shipIDs + 1] = shipID
		end
	end

	writeStringVectorSharedMemory(self:dataKey(playerID, "ids:" .. side), shipIDs)
	writeData(self:dataKey(playerID, "live:" .. side), #shipIDs)

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath(updateKey))
	CreatureObject(pPlayer):playEffect(effect, "")

	createEvent(self.warpoutTimeout * 1000, self.className, "warpOut", pPlayer, self:getRunToken(playerID))

	if (#shipIDs == 0) then
		Logger:log(self.className .. ":forceArrives -- no ship of side " .. side .. " spawned for " .. self.questName .. ".", LT_ERROR)
		self:failQuest(pPlayer, "true")
		return
	end

	writeData(self:dataKey(playerID, "arrived:" .. side), 1)

	if (readData(self:dataKey(playerID, "arrived:" .. self.SIDES.ALLY)) == 1 and readData(self:dataKey(playerID, "arrived:" .. self.SIDES.ENEMY)) == 1) then
		self:startBattle(pPlayer, playerID)
	end
end

-- "Pick a target on side": round robin over the side's live ships in spawn order
function SpaceBattleScreenplay:pickTarget(playerID, side)
	local live = self:liveIDs(playerID, side)

	if (#live == 0) then
		return nil
	end

	local cursorKey = self:dataKey(playerID, "engageCursor:" .. side)
	local cursor = readData(cursorKey)

	writeData(cursorKey, cursor + 1)

	return live[(cursor % #live) + 1]
end

function SpaceBattleScreenplay:engage(playerID, shipID, targetID)
	local pShip = getSceneObject(shipID)
	local pTarget = getSceneObject(targetID)

	if (pShip == nil or pTarget == nil) then
		return
	end

	ShipAiAgent(pShip):engageShipTarget(pTarget)
	writeData(self:dataKey(playerID, "target:" .. shipID), targetID)
end

function SpaceBattleScreenplay:startBattle(pPlayer, playerID)
	if (not self:isStage(playerID, self.STAGES.SETUP)) then
		return
	end

	writeData(self:dataKey(playerID, "stage"), self.STAGES.BATTLE)

	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)

	SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("battle_started"))

	-- Initial engage orders: allies pick enemies first, then enemies pick allies
	local allies = self:liveIDs(playerID, self.SIDES.ALLY)
	local enemies = self:liveIDs(playerID, self.SIDES.ENEMY)

	for _, shipID in ipairs(allies) do
		local targetID = self:pickTarget(playerID, self.SIDES.ENEMY)

		if (targetID ~= nil) then
			self:engage(playerID, shipID, targetID)
		end
	end

	for _, shipID in ipairs(enemies) do
		local targetID = self:pickTarget(playerID, self.SIDES.ALLY)

		if (targetID ~= nil) then
			self:engage(playerID, shipID, targetID)
		end
	end
end

-- args: <runID>:<agent id>
function SpaceBattleScreenplay:shipLost(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local shipID = tonumber(string.match(tostring(args), ":(%d+)$"))

	if (shipID == nil) then
		return
	end

	local sideKey = self:dataKey(playerID, "side:" .. shipID)
	local side = readData(sideKey)

	if (side == 0) then
		return
	end

	deleteData(sideKey)
	deleteData(self:dataKey(playerID, "target:" .. shipID))

	local remaining = {}

	for _, id in ipairs(self:liveIDs(playerID, side)) do
		if (id ~= shipID) then
			remaining[#remaining + 1] = id
		end
	end

	if (#remaining > 0) then
		writeStringVectorSharedMemory(self:dataKey(playerID, "ids:" .. side), remaining)
	else
		deleteStringVectorSharedMemory(self:dataKey(playerID, "ids:" .. side))
	end

	CreatureObject(pPlayer):removeSpaceMissionObject(shipID, true)

	local liveKey = self:dataKey(playerID, "live:" .. side)
	local liveCount = readData(liveKey) - 1

	writeData(liveKey, liveCount)

	if (self:isStage(playerID, self.STAGES.RESOLVED)) then
		return
	end

	local isAllySide = (side == self.SIDES.ALLY)
	local opposing = self.SIDES.ENEMY

	if (not isAllySide) then
		opposing = self.SIDES.ALLY
	end

	-- Ships that were engaged on the dead ship pick a new target on its side
	if (self:isStage(playerID, self.STAGES.BATTLE) and liveCount > 0) then
		for _, attackerID in ipairs(self:liveIDs(playerID, opposing)) do
			if (readData(self:dataKey(playerID, "target:" .. attackerID)) == shipID) then
				local targetID = self:pickTarget(playerID, side)

				if (targetID ~= nil) then
					self:engage(playerID, attackerID, targetID)
				end
			end
		end
	end

	if (liveCount > 0) then
		local key = "enemies_remain"

		if (isAllySide) then
			key = "allies_remain"
		end

		local message = LuaStringIdChatParameter(self:messagePath(key))
		message:setDI(liveCount)

		CreatureObject(pPlayer):sendSystemMessage(message:_getObject())
		return
	end

	writeData(self:dataKey(playerID, "stage"), self.STAGES.RESOLVED)

	local token = self:getRunToken(playerID)

	if (isAllySide) then
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("enemies_win"))
		createEvent(self.resolveDelay * 1000, self.className, "loseBattle", pPlayer, token)
	else
		SpaceHelpers:sendQuestUpdate(pPlayer, self:messagePath("allies_win"))
		createEvent(self.resolveDelay * 1000, self.className, "winBattle", pPlayer, token)
	end
end

function SpaceBattleScreenplay:winBattle(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	if (SpaceHelpers:isSpaceQuestTaskActive(pPlayer, self.questType, self.questName, 2)) then
		SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 2, false)
	end

	self:completeQuest(pPlayer, "true")
end

function SpaceBattleScreenplay:loseBattle(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	self:failQuest(pPlayer, "true")
end

function SpaceBattleScreenplay:warpOut(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- The journal quest vanished (for example a datapad abort): clean up silently
	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		self:cleanUpQuestData(pPlayer)
		return
	end

	if (self:isStage(playerID, self.STAGES.RESOLVED)) then
		return
	end

	CreatureObject(pPlayer):sendSystemMessage("@space/quest:warpout_failure")
	self:failQuest(pPlayer, "true")
end
