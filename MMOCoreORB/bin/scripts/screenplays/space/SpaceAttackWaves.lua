--[[
	Space Attack Waves (shared mixin)

	Attack wave logic shared by survival, delivery, and rescue quest types, ported from SWG-Source
	survival.java / delivery.java / rescue.java. Not a screenplay: hosts copy the functions in with
	SpaceAttackWaves:mixInto(Host), called right after the host's class table and before registerScreenPlay.

	Host requirements: className, questZone, questType, questName, attackShipLists, attackPeriod,
	attackListType, ATTACK_LIST_TYPES, maxActiveWaves, spawnMinDistance, spawnMaxDistance, spawnSpread,
	squadronMinSize and the methods dataKey, messagePath, isCurrentRun and getRunToken. Rescue quests
	override the three wave hooks (getWaveAnchor, notifyWaveLaunched, notifyWavesCleared).
]]

SpaceAttackWaves = {}

-- Copies every function except mixInto into the class as raw fields
function SpaceAttackWaves:mixInto(class)
	for name, value in pairs(self) do
		if (type(value) == "function" and name ~= "mixInto") then
			rawset(class, name, value)
		end
	end
end

-- Hook: the ship the waves spawn in front of and attack. Default is the player's ship. Hosts may override it.
function SpaceAttackWaves:getWaveAnchor(pPlayer)
	local pPlayerShip = SceneObject(pPlayer):getRootParent()

	if (pPlayerShip ~= nil and SceneObject(pPlayerShip):isShipObject()) then
		return pPlayerShip
	end

	return nil
end

-- Hook: called after a wave was launched. Hosts may override it.
function SpaceAttackWaves:notifyWaveLaunched(pPlayer)
end

-- Hook: called after the last attack ship died. Hosts may override it.
function SpaceAttackWaves:notifyWavesCleared(pPlayer)
end

-- Number of waves that still have a live ship
function SpaceAttackWaves:getLiveWaveCount(playerID)
	local live = 0

	for i = 1, readData(self:dataKey(playerID, "waveCount")), 1 do
		if (readData(self:dataKey(playerID, "waveLive:" .. i)) > 0) then
			live = live + 1
		end
	end

	return live
end

function SpaceAttackWaves:launchWave(pPlayer, args)
	if (not self:isCurrentRun(pPlayer, args)) then
		return
	end

	local playerID = SceneObject(pPlayer):getObjectID()

	-- At the cap: wait for a wave to be destroyed, which launches this one
	if (self:getLiveWaveCount(playerID) >= self.maxActiveWaves) then
		writeData(self:dataKey(playerID, "wavePending"), 1)
		return
	end

	deleteData(self:dataKey(playerID, "wavePending"))

	local pAnchor = self:getWaveAnchor(pPlayer)

	if (pAnchor ~= nil and #self.attackShipLists > 0) then
		self:spawnWave(pPlayer, pAnchor, self:pickList(playerID))

		CreatureObject(pPlayer):sendSystemMessage(self:messagePath("attack_notify"))
		CreatureObject(pPlayer):playEffect("clienteffect/ui_quest_spawn_wave.cef", "")

		self:notifyWaveLaunched(pPlayer)
	end

	createEvent(self.attackPeriod * 1000, self.className, "launchWave", pPlayer, args)
end

function SpaceAttackWaves:pickList(playerID)
	local listCount = #self.attackShipLists

	if (self.attackListType == self.ATTACK_LIST_TYPES.RANDOM) then
		return self.attackShipLists[getRandomNumber(1, listCount)]
	end

	local nextKey = self:dataKey(playerID, "nextList")
	local index = readData(nextKey) % listCount + 1

	writeData(nextKey, index)

	return self.attackShipLists[index]
end

function SpaceAttackWaves:spawnWave(pPlayer, pAnchorShip, shipList)
	local playerID = SceneObject(pPlayer):getObjectID()
	local waveNumber = readData(self:dataKey(playerID, "waveCount")) + 1
	local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)
	local spawnPoint = ShipObject(pAnchorShip):getSpawnPointInFrontOfShip(self.spawnMinDistance, self.spawnMaxDistance)
	local shipIDs = readStringVectorSharedMemory(self:dataKey(playerID, "attackShips"))
	local pLeader = nil
	local spawned = 0

	writeData(self:dataKey(playerID, "waveCount"), waveNumber)

	for i = 1, #shipList, 1 do
		local x = spawnPoint[1] + getRandomNumber(-self.spawnSpread, self.spawnSpread)
		local y = spawnPoint[3] + getRandomNumber(-self.spawnSpread, self.spawnSpread)
		local pShipAgent = spawnShipAgent(shipList[i], self.questZone, x, spawnPoint[2], y, pAnchorShip)

		if (pShipAgent ~= nil) then
			local agentID = SceneObject(pShipAgent):getObjectID()

			ShipAiAgent(pShipAgent):setMissionOwner(pPlayer)

			if (#shipList >= self.squadronMinSize) then
				if (pLeader == nil) then
					pLeader = pShipAgent
					ShipAiAgent(pShipAgent):createSquadron()
				else
					ShipAiAgent(pShipAgent):assignToSquadron(pLeader)
				end
			end

			ShipAiAgent(pShipAgent):addSpaceFactionEnemy(playerFactionHash)
			ShipAiAgent(pShipAgent):engageShipTarget(pAnchorShip)

			CreatureObject(pPlayer):addSpaceMissionObject(agentID, (i == #shipList))

			createObserver(SHIPDESTROYED, self.className, "notifyAttackShipDestroyed", pShipAgent)

			shipIDs[#shipIDs + 1] = agentID
			spawned = spawned + 1
			writeData(self:dataKey(playerID, "shipWave:" .. agentID), waveNumber)
		end
	end

	writeData(self:dataKey(playerID, "waveLive:" .. waveNumber), spawned)
	writeStringVectorSharedMemory(self:dataKey(playerID, "attackShips"), shipIDs)
end

function SpaceAttackWaves:notifyAttackShipDestroyed(pShipAgent, pKillerShip)
	if (pShipAgent == nil) then
		return 1
	end

	local pPlayer = getSceneObject(ShipAiAgent(pShipAgent):getMissionOwnerID())

	if (pPlayer == nil) then
		return 1
	end

	local playerID = SceneObject(pPlayer):getObjectID()
	local agentID = SceneObject(pShipAgent):getObjectID()
	local waveKey = self:dataKey(playerID, "shipWave:" .. agentID)
	local waveNumber = readData(waveKey)

	-- Not a ship of the player's current run
	if (waveNumber == 0) then
		return 1
	end

	deleteData(waveKey)

	CreatureObject(pPlayer):removeSpaceMissionObject(agentID, true)

	local shipIDs = readStringVectorSharedMemory(self:dataKey(playerID, "attackShips"))
	local remaining = {}

	for i = 1, #shipIDs, 1 do
		if (tonumber(shipIDs[i]) ~= agentID) then
			remaining[#remaining + 1] = shipIDs[i]
		end
	end

	if (#remaining > 0) then
		writeStringVectorSharedMemory(self:dataKey(playerID, "attackShips"), remaining)
	else
		deleteStringVectorSharedMemory(self:dataKey(playerID, "attackShips"))
	end

	local liveKey = self:dataKey(playerID, "waveLive:" .. waveNumber)
	local waveLive = readData(liveKey) - 1

	writeData(liveKey, waveLive)

	if (#remaining > 0) then
		self:notifyTargetsRemaining(pPlayer, #remaining)
	end

	local launching = false

	-- A wave was waiting for room, launch it right after this handler (the destroyed ship is locked here)
	if (waveLive <= 0 and readData(self:dataKey(playerID, "wavePending")) == 1) then
		deleteData(self:dataKey(playerID, "wavePending"))
		createEvent(0, self.className, "launchWave", pPlayer, self:getRunToken(playerID))
		launching = true
	end

	if (not launching and #readStringVectorSharedMemory(self:dataKey(playerID, "attackShips")) == 0) then
		CreatureObject(pPlayer):sendSystemMessage(self:messagePath("attack_stopped"))
		CreatureObject(pPlayer):playEffect("clienteffect/ui_quest_destroyed_wave.cef", "")

		self:notifyWavesCleared(pPlayer)
	end

	return 1
end


function SpaceAttackWaves:removeAttackShips(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()
	local shipIDs = readStringVectorSharedMemory(self:dataKey(playerID, "attackShips"))

	deleteStringVectorSharedMemory(self:dataKey(playerID, "attackShips"))

	for i = 1, #shipIDs, 1 do
		local attackAgentID = tonumber(shipIDs[i])

		deleteData(self:dataKey(playerID, "shipWave:" .. attackAgentID))

		-- Remove the attacking ship agent as a mission object
		CreatureObject(pPlayer):removeSpaceMissionObject(attackAgentID, false)

		local pAttackShip = getSceneObject(attackAgentID)

		if (pAttackShip ~= nil) then
			-- Remove the kill observer
			dropObserver(SHIPDESTROYED, self.className, "notifyAttackShipDestroyed", pAttackShip)

			ShipObject(pAttackShip):setHyperspacing(true)

			-- Remove the attack ship
			createEvent(2000, "SpaceHelpers", "delayedDestroyShipAgent", pAttackShip, "")
		end
	end
end

-- Ends the wave state of the run
function SpaceAttackWaves:cleanUpWaveData(pPlayer)
	local playerID = SceneObject(pPlayer):getObjectID()

	deleteData(self:dataKey(playerID, "wavePending"))
	deleteData(self:dataKey(playerID, "nextList"))

	local waveCount = readData(self:dataKey(playerID, "waveCount"))

	for i = 1, waveCount, 1 do
		deleteData(self:dataKey(playerID, "waveLive:" .. i))
	end

	deleteData(self:dataKey(playerID, "waveCount"))
end

-- Hook: called with the number of attack ships still alive after a kill. Hosts may override it.
function SpaceAttackWaves:notifyTargetsRemaining(pPlayer, remaining)
end
