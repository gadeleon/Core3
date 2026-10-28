-- Admiral Willham Burke (Rebel master trainer) conversation handler; ported from SWG-Source rebel_master_trainer.java. Two Kessel missions and the free master skill: pre-NGE client lines (feature space-master-trainer-rebel).
local SpaceHelpers = require("utils.space_helpers")

willhamBurkeConvoHandler = conv_handler:new {}

-- Missions: { head quest global, MasterTrainerScreenplay quest string }
willhamBurkeConvoHandler.MISSIONS = {
	{ head = "destroy_master_rebel_1", questString = "QUEST_STRING_REBEL_1" },
	{ head = "destroy_master_rebel_2", questString = "QUEST_STRING_REBEL_2" }
}

-- Screens that start a mission (on display): screen -> mission number
willhamBurkeConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry_a = 1, m1_retry_b = 1,
	m2_accept = 2, m2_retry_a = 2, m2_retry_b = 2
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
willhamBurkeConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, master_grant = 2
}

-- Rebel standing paid with each mission
willhamBurkeConvoHandler.STANDING = { 200, 400 }

-- Granted free (SWG noisyGrantSkill) on the screen that pays mission 2
willhamBurkeConvoHandler.MASTER_SKILL = "pilot_rebel_navy_master"
willhamBurkeConvoHandler.MASTER_SCREEN = "master_grant"

function willhamBurkeConvoHandler:getQuestString(n)
	return MasterTrainerScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function willhamBurkeConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- <playerID><key> is "1"
function willhamBurkeConvoHandler:hasKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. key) == "1"
end

function willhamBurkeConvoHandler:isWon(pPlayer, n)
	local questString = self:getQuestString(n)

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
end

function willhamBurkeConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function willhamBurkeConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function willhamBurkeConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Rebel standing
function willhamBurkeConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.STANDING[n])
end

-- The master skill, once and without an XP charge
function willhamBurkeConvoHandler:grantMaster(pPlayer)
	if (CreatureObject(pPlayer):hasSkill(self.MASTER_SKILL)) then
		return
	end

	SpaceHelpers:grantSpaceSkill(pPlayer, self.MASTER_SKILL, false)
end

function willhamBurkeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("default")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("default")
	end

	local rebel = SpaceHelpers:isRebelPilot(pPlayer)

	if (self:hasKey(pPlayer, MasterTrainerScreenplay.MASTER_MISSION_IMPERIAL_KEY)) then
		return convoTemplate:getScreen("working_for_empire")
	elseif (SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	elseif (SpaceHelpers:isRSFSquadron(pPlayer)) then
		return convoTemplate:getScreen("rsf_pilot")
	elseif (rebel and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4)) then
		return convoTemplate:getScreen("not_ready")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer) and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then
		return convoTemplate:getScreen("privateer_not_ready")
	elseif (SpaceHelpers:hasMasterSkill(pPlayer, "neutral")) then
		return convoTemplate:getScreen("other_master")
	elseif (SpaceHelpers:hasMasterSkill(pPlayer, "rebel_navy")) then
		return convoTemplate:getScreen("master_done")
	elseif (self:isActive(pPlayer, 1) or self:isActive(pPlayer, 2)) then
		return convoTemplate:getScreen("on_master_mission")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer)) then
		return convoTemplate:getScreen("on_quest")
	elseif (self:isFailed(pPlayer, 2)) then
		return convoTemplate:getScreen("m2_failed")
	elseif (self:isFailed(pPlayer, 1)) then
		return convoTemplate:getScreen("m1_failed")
	elseif (self:isWon(pPlayer, 2) and not self:isPaid(pPlayer, 2)) then
		return convoTemplate:getScreen("m2_won")
	elseif (self:isWon(pPlayer, 1) and not self:isPaid(pPlayer, 1)) then
		return convoTemplate:getScreen("m1_won")
	elseif (self:isPaid(pPlayer, 1)) then
		return convoTemplate:getScreen("m2_brief")
	elseif (rebel) then
		return convoTemplate:getScreen("intro")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("privateer_ready")
	end

	return convoTemplate:getScreen("default")
end

function willhamBurkeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return pClonedScreen
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return pClonedScreen
	end

	local startMission = self.START_SCREENS[screenID]
	local rewardMission = self.REWARD_SCREENS[screenID]

	if (startMission ~= nil) then
		local playerID = CreatureObject(pPlayer):getObjectID()

		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		self:payMission(pPlayer, ghost, rewardMission)

		if (screenID == self.MASTER_SCREEN) then
			self:grantMaster(pPlayer)
		end
	end

	return pClonedScreen
end
