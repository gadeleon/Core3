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

	creditKillBonus = 0, -- Per ship of a fully cleared attack set (.tab killReward)
	numResponses = 0, -- Variants of the capture taunts, 0 for the plain keys

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

	-- Reward plus a bonus for every ship of the cleared attack sets (recovery_duty.java)
	local playerID = SceneObject(pPlayer):getObjectID()
	local amount = self.creditReward + self.creditKillBonus * readData(playerID .. self.className .. ":rewardShips:")

	CreatureObject(pPlayer):addBankCredits(amount, true)

	local rewardMessage = LuaStringIdChatParameter("@space/quest:recovery_reward")
	rewardMessage:setDI(amount)

	CreatureObject(pPlayer):sendSystemMessage(rewardMessage:_getObject())

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

function SpaceDutyRecoveryScreenplay:cleanUpQuestData(playerID)
	SpaceRecoveryScreenplay.cleanUpQuestData(self, playerID)

	deleteData(playerID .. self.className .. ":rewardShips:")
	deleteData(playerID .. self.className .. ":killsPending:")
end

-- Counts the kills of fully cleared attack sets (recovery.java deadships)
function SpaceDutyRecoveryScreenplay:onAttackShipKilled(pPlayer, remaining)
	local playerID = SceneObject(pPlayer):getObjectID()
	local pendingKey = playerID .. self.className .. ":killsPending:"
	local pending = readData(pendingKey) + 1

	if (remaining == 0) then
		local rewardKey = playerID .. self.className .. ":rewardShips:"

		writeData(rewardKey, readData(rewardKey) + pending)
		deleteData(pendingKey)
	else
		writeData(pendingKey, pending)
	end
end

function SpaceDutyRecoveryScreenplay:capturePhraseKey(phase)
	if (self.numResponses >= 1) then
		return "capture_phase_" .. phase .. "_" .. getRandomNumber(1, self.numResponses)
	end

	return SpaceRecoveryScreenplay.capturePhraseKey(self, phase)
end
