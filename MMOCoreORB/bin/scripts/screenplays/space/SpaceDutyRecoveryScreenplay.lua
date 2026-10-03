SpaceDutyRecoveryScreenplay = SpaceRecoveryScreenplay:new {
	className = "SpaceDutyRecoveryScreenplay",

	-- Screenplay Specific Variables

	DEBUG_SPACE_DUTY_RECOVERY = false,

	arrivalDelay = 5, -- In Seconds

	recoverShip = "",
	recoveryConversationMobile = "",

	preRecoveryPoints = {
		--{zoneName = "space_corellia", x = -4381, z = -4943, y = -7262, patrolNumber = 1, radius = 150},
	},

	recoveryPoints = {
		--{zoneName = "space_corellia", x = -4381, z = -4943, y = -7262, patrolNumber = 1, radius = 150},
	},

	escortSpeed = 20,
	testEscortSpeed = 40,

	attackDelay = 30, -- In Seconds

	attackShips = {
		{},
	},

	recoveryDelay = 5,

	tauntData = {
		panicCount = 5,
		thanksCount = 5,
	},
}

registerScreenPlay("SpaceDutyRecoveryScreenplay", false)

--[[

		Space Duty Recovery Quest Functions

--]]

-- A duty ends by clearing its journal entry (not completing it) so it can be taken again
function SpaceDutyRecoveryScreenplay:completeQuest(pPlayer, notifyClient)
	if (pPlayer == nil) then
		return
	end

	if (not SpaceHelpers:isSpaceQuestActive(pPlayer, self.questType, self.questName)) then
		return
	end

	if (self.DEBUG_SPACE_DUTY_RECOVERY) then
		print(self.className .. ":completeQuest called -- QuestType: " .. self.questType .. " Quest Name: " .. self.questName)
	end

	-- Clear the journal entry and remove the datapad mission
	SpaceHelpers:failSpaceQuest(pPlayer, self.questType, self.questName, false)

	SpaceHelpers:clearQuestWaypoint(pPlayer, self.className)

	dropObserver(ZONESWITCHED, self.className, "enteredZone", pPlayer)

	self:despawnShips(pPlayer)

	self:cleanUpQuestData(SceneObject(pPlayer):getObjectID())

	if (notifyClient ~= "false") then
		SpaceHelpers:sendMissionEnded(pPlayer, "@spacequest/" .. self.questType .. "/" .. self.questName .. ":title")

		CreatureObject(pPlayer):playMusicMessage("sound/music_themequest_victory_rebel.snd")
	end
end
