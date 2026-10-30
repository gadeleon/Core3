--[[

	Persistent destroy quest for the pilot master missions (feature space-master-mission-quest-type).

	Progress survives leaving the zone, landing, death, logout and server restarts. It ends only by
	completion, journal abort or surrendering the profession. The kill count is saved on the
	PlayerObject and the observers are persistent.

	Used by the four master missions in squadrons/MasterTrainerScreenplay.lua (Declann: master_imperial_1/2,
	Burke: master_rebel_1/2; SWG-Source datatables/spacequest/destroy). Deliberately differs from SWG-Source
	(NGE) destroy.java, which fails the quest on leaving the zone: this is the pre-NGE rule. Kills count only in
	the quest zone, a group member's kill counts for every member, and the corvette validSpawns filter is not used.

]]

local SpaceHelpers = require("utils.space_helpers")

SpaceMasterDestroyScreenplay = SpaceQuestLogic:new {
	className = "SpaceMasterDestroyScreenplay",

	questName = "",
	questType = "",
	questZone = "",

	creditReward = 0,
	itemReward = {},

	killsRequired = 0,
	shipTypes = {},

	-- Seconds after entering the quest zone (or logging in there) before the saved count is shown
	REMINDER_DELAY = 5,
}

registerScreenPlay("SpaceMasterDestroyScreenplay", false)

local OBSERVERS = {
	{ event = ZONESWITCHED, method = "enteredZone" },
	{ event = LOGGEDIN, method = "onLoggedIn" },
	{ event = DESTROYEDSHIP, method = "notifyDestroyedShip" },
}

function SpaceMasterDestroyScreenplay:lastKillKey(pPlayer)
	return SceneObject(pPlayer):getObjectID() .. ":" .. self.className .. ":lastKillID"
end

function SpaceMasterDestroyScreenplay:progress(count)
	return "Kills: " .. count .. " of " .. self.killsRequired
end

function SpaceMasterDestroyScreenplay:getKillCount(pPlayer)
	return tonumber(readScreenPlayData(pPlayer, self.className, "killCount")) or 0
end

function SpaceMasterDestroyScreenplay:ensureObservers(pPlayer)
	for i = 1, #OBSERVERS, 1 do
		local o = OBSERVERS[i]

		if (not hasObserver(o.event, self.className, o.method, pPlayer)) then
			createObserver(o.event, self.className, o.method, pPlayer, 1)
		end
	end
end

function SpaceMasterDestroyScreenplay:dropObservers(pPlayer)
	for i = 1, #OBSERVERS, 1 do
		local o = OBSERVERS[i]

		dropObserver(o.event, self.className, o.method, pPlayer)
	end
end

function SpaceMasterDestroyScreenplay:clearProgress(pPlayer)
	deleteScreenPlayData(pPlayer, self.className, "killCount")
	deleteStringData(self:lastKillKey(pPlayer))
end

function SpaceMasterDestroyScreenplay:startQuest(pPlayer, pNpc)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to startQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (pNpc == "") then
		pNpc = nil
	end

	if (not SpaceHelpers:activateSpaceQuest(pPlayer, pNpc, self.questType, self.questName, false)) then
		return
	end

	self:clearProgress(pPlayer)
	self:ensureObservers(pPlayer)
end

-- Task 0 -> task 1 on arrival in the quest zone. Idempotent.
function SpaceMasterDestroyScreenplay:arrive(pPlayer)
	if (SpaceHelpers:isSpaceQuestTaskComplete(pPlayer, self.questType, self.questName, 0)) then
		return
	end

	SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 0, false)
	SpaceHelpers:activateSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)

	CreatureObject(pPlayer):playEffect("clienteffect/ui_quest_waypoint_target.cef", "")
end

function SpaceMasterDestroyScreenplay:enteredZone(pPlayer, nill, zoneNameHash)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		self:dropObservers(pPlayer)
		return 1
	end

	self:ensureObservers(pPlayer)

	if (zoneNameHash == getHashCode(self.questZone)) then
		self:arrive(pPlayer)
		createEvent(self.REMINDER_DELAY * 1000, self.className, "remindProgress", pPlayer, "")
	end

	return 0
end

function SpaceMasterDestroyScreenplay:onLoggedIn(pPlayer)
	if (pPlayer == nil) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		self:dropObservers(pPlayer)
		return 1
	end

	self:ensureObservers(pPlayer)

	if (getHashCode(SceneObject(pPlayer):getZoneName()) == getHashCode(self.questZone)) then
		self:arrive(pPlayer)
		createEvent(self.REMINDER_DELAY * 1000, self.className, "remindProgress", pPlayer, "")
	end

	return 0
end

function SpaceMasterDestroyScreenplay:remindProgress(pPlayer)
	if (pPlayer == nil) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (SpaceHelpers:isSpaceQuestTaskComplete(pPlayer, self.questType, self.questName, 1)) then
		return
	end

	if (SceneObject(pPlayer):getZoneName() ~= self.questZone) then
		return
	end

	SpaceHelpers:sendQuestUpdate(pPlayer, self:progress(self:getKillCount(pPlayer)))
end

function SpaceMasterDestroyScreenplay:notifyDestroyedShip(pPlayer, pShipAgent)
	if (pShipAgent == nil or not SceneObject(pShipAgent):isShipAiAgent()) then
		return 0
	end

	if (pPlayer == nil or not SceneObject(pPlayer):isPlayerCreature()) then
		return 0
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		self:dropObservers(pPlayer)
		return 1
	end

	-- Completion pending
	if (SpaceHelpers:isSpaceQuestTaskComplete(pPlayer, self.questType, self.questName, 1)) then
		return 0
	end

	if (SceneObject(pPlayer):getZoneName() ~= self.questZone) then
		return 0
	end

	local shipTempName = ShipAiAgent(pShipAgent):getShipAgentTemplateName()
	local isValid = false

	for i = 1, #self.shipTypes, 1 do
		if (shipTempName == self.shipTypes[i]) then
			isValid = true
			break
		end
	end

	if (not isValid) then
		return 0
	end

	-- Never count the same destroyed ship twice
	local shipID = tostring(SceneObject(pShipAgent):getObjectID())
	local lastKillKey = self:lastKillKey(pPlayer)

	if (readStringData(lastKillKey) == shipID) then
		return 0
	end

	writeStringData(lastKillKey, shipID)

	self:arrive(pPlayer)

	local killCount = self:getKillCount(pPlayer) + 1

	writeScreenPlayData(pPlayer, self.className, "killCount", tostring(killCount))

	SpaceHelpers:sendQuestUpdate(pPlayer, self:progress(killCount))

	if (killCount >= self.killsRequired) then
		SpaceHelpers:completeSpaceQuestTask(pPlayer, self.questType, self.questName, 1, false)

		CreatureObject(pPlayer):playEffect("clienteffect/ui_quest_destroyed_all.cef", "")

		createEvent(200, self.className, "completeQuest", pPlayer, "true")
	end

	return 0
end

function SpaceMasterDestroyScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to completeQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	SpaceHelpers:completeSpaceQuest(pPlayer, self.questType, self.questName, notifyClient ~= "false")

	self:clearProgress(pPlayer)
	self:dropObservers(pPlayer)
end

-- Used by the shared abortQuest and by surrender
function SpaceMasterDestroyScreenplay:resetQuest(pPlayer)
	if (pPlayer == nil) then
		Logger:log("Quest: " .. self.questName .. " Type: " .. self.questType .. " -- Failed to resetQuest due to pPlayer being nil.", LT_ERROR)
		return
	end

	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)
	SpaceHelpers:clearQuestWaypoints(pPlayer, self.className)

	self:clearProgress(pPlayer)
	self:dropObservers(pPlayer)
end
