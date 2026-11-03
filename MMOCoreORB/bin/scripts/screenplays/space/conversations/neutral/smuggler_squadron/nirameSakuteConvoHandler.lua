-- Nirame Sakute (Smuggler tier 4, Dathomir Trade Outpost) conversation handler; ported from SWG-Source tatooine_privateer_tier4.java. One-click, free-choice training bought with XP: pre-NGE client lines (feature smuggler-tier4-nirame).
local SpaceHelpers = require("utils.space_helpers")

nirameSakuteConvoHandler = conv_handler:new {}

-- Missions: { head quest global, SmugglerSquadronScreenplay quest string of the head, quest string of the chain end }
nirameSakuteConvoHandler.MISSIONS = {
	{ head = "delivery_tatooine_privateer_tier4_1a", questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE1" },
	{ head = "recovery_tatooine_privateer_tier4_2a", questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE2" },
	{ head = "inspect_tatooine_privateer_tier4_3a", questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE2" },
	{ head = "assassinate_tatooine_privateer_tier4_4a", questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE2" }
}

-- Duty screens: screen -> the duty global that is started
nirameSakuteConvoHandler.DUTY_SCREENS = {
	duty_escort = "escort_duty_tatooine_privateer_tier4_1",
	duty_rescue = "rescue_duty_tatooine_privateer_tier4_1",
	duty_recovery = "recovery_duty_tatooine_privateer_tier4_1",
	duty_destroy = "destroy_duty_tatooine_privateer_tier4_1"
}

-- Pre-NGE free choice of a tier 4 skill, one click on ready_train: { skill, topic reply, screen shown when the next mission is 1 }, in menu order (SWG grant order)
nirameSakuteConvoHandler.TRAIN_CHOICES = {
	{ skill = "pilot_neutral_starships_04", topic = "@conversation/tatooine_privateer_tier4:s_842279cd", trained = "m1_trained_starships" },
	{ skill = "pilot_neutral_weapons_04", topic = "@conversation/tatooine_privateer_tier4:s_dbb3b0b0", trained = "m1_trained_weapons" },
	{ skill = "pilot_neutral_procedures_04", topic = "@conversation/tatooine_privateer_tier4:s_ee28691a", trained = "m1_trained_procedures" },
	{ skill = "pilot_neutral_droid_04", topic = "@conversation/tatooine_privateer_tier4:s_71d852f5", trained = "m1_trained_droid" }
}

-- The opening of the mission brief after training, for missions 2 to 4 (mission 1 uses the chosen skill's screen)
nirameSakuteConvoHandler.TRAINED_BRIEFS = {
	[2] = "m2_brief_trained", [3] = "m3_brief", [4] = "m4_brief_trained"
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
nirameSakuteConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
nirameSakuteConvoHandler.START_SCREENS = {
	m1_retry_a = 1, m1_retry_b = 1, m1_accept_a = 1, m1_accept_b = 1,
	m2_retry_a = 2, m2_retry_b = 2, m2_accept = 2,
	m3_retry_a = 3, m3_retry_b = 3, m3_accept = 3,
	m4_retry_a = 4, m4_retry_b = 4, m4_accept_a = 4, m4_accept_b = 4
}

-- Screens that record that the pilot has met Nirame
nirameSakuteConvoHandler.MET_SCREENS = {
	intro_busy = true
}

-- Screens that only raise the pilot tier
nirameSakuteConvoHandler.TIER_SCREENS = {
	transfer = true, here_for_work = true
}

function nirameSakuteConvoHandler:getQuestString(n)
	return SmugglerSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function nirameSakuteConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

function nirameSakuteConvoHandler:hasKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. key) == "1"
end

function nirameSakuteConvoHandler:setKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. key, 1)
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function nirameSakuteConvoHandler:isWon(pPlayer, n)
	local endString = SmugglerSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

-- Any member of the chain is running, the surprise attack of a failed split included
function nirameSakuteConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function nirameSakuteConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function nirameSakuteConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains or the four duties is running
function nirameSakuteConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	for n = 1, 4 do
		local questString = SmugglerSquadronScreenplay["TIER4_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, questString.type, questString.name)) then
			return true
		end
	end

	return false
end

-- SWG canFlyNonTrackDuty (tatooine_privateer_tier4.java:183-190) for neutral pilots only
function nirameSakuteConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:isNeutralPilot(pPlayer) and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The first mission that is not won, or nil
function nirameSakuteConvoHandler:getNextMission(pPlayer)
	for n = 1, 4 do
		if (not self:isWon(pPlayer, n)) then
			return n
		end
	end

	return nil
end

-- SWG readyForTier4Mission, derived: the next mission is covered by the skills bought and was never granted
function nirameSakuteConvoHandler:getReadyMission(pPlayer)
	local n = self:getNextMission(pPlayer)

	if (n ~= nil and SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 4) >= n and not self:hasStatus(pPlayer, n, ":attempted")) then
		return n
	end

	return nil
end

function nirameSakuteConvoHandler:isReadyForTraining(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4) and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 4) == true and self:getReadyMission(pPlayer) == nil
end

-- Pays the reward of mission n once: the :reward key, then the head's credits and item
function nirameSakuteConvoHandler:payMission(pPlayer, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)
end

-- Pilot tier 3 -> 4 once the four tier 3 skills are held (Beissa raises it too), then 4 -> 5 once the four tier 4 skills are held
function nirameSakuteConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost == nil) then
		return
	end

	if (ghost:getPilotTier() == 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
		ghost:incrementPilotTier()
	end

	if (ghost:getPilotTier() == 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then
		ghost:incrementPilotTier()
	end
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function nirameSakuteConvoHandler:getLastScreenID(pPlayer)
	local convSession = CreatureObject(pPlayer):getConversationSession()

	if (convSession == nil) then
		return nil
	end

	local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()

	if (pLastScreen == nil) then
		return nil
	end

	return LuaConversationScreen(pLastScreen):getScreenID()
end

-- Pre-NGE one-click training: a topic reply on ready_train buys that skill (1,000,000 XP) and shows the mission brief.
-- Any failed guard sends the pilot back through the gates, granting nothing.
function nirameSakuteConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if (self:getLastScreenID(pPlayer) ~= "ready_train") then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	-- The skill is the one whose topic the pilot picked on the live (cloned) screen
	local chosen = nil
	local convSession = CreatureObject(pPlayer):getConversationSession()

	if (convSession ~= nil) then
		local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()

		if (pLastScreen ~= nil) then
			chosen = LuaConversationScreen(pLastScreen):getOptionText(selectedOption)
		end
	end

	local choice = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry.topic == chosen) then
			choice = entry
			break
		end
	end

	if (choice == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	local skill = choice.skill

	if (CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer) or not LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 4
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		self:raisePilotTier(pPlayer, LuaPlayerObject(pGhost))
	end

	local n = self:getNextMission(pPlayer)

	if (n == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (n == 1) then
		return convoTemplate:getScreen(choice.trained)
	end

	return convoTemplate:getScreen(self.TRAINED_BRIEFS[n])
end

-- Side-effect free; gates in SWG order
function nirameSakuteConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("not_neutral")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("not_neutral")
	end

	if (not SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("not_neutral")
	elseif (not SpaceHelpers:isSmugglerSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
		return convoTemplate:getScreen("not_ready")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("busy")
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_failed")
		end
	end

	for n = 1, 4 do
		if (self:isWon(pPlayer, n) and not self:isPaid(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_reward")
		end
	end

	if (self:getReadyMission(pPlayer) ~= nil) then
		return convoTemplate:getScreen("ready")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("ready_train")
	elseif (not self:hasKey(pPlayer, SmugglerSquadronScreenplay.TIER4_MET_KEY)) then
		return convoTemplate:getScreen("intro")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then
		return convoTemplate:getScreen("tier4_incomplete")
	elseif (not SpaceHelpers:hasMasterSkill(pPlayer, "neutral")) then
		return convoTemplate:getScreen("transfer")
	end

	return convoTemplate:getScreen("here_for_work")
end

function nirameSakuteConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()

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
	local dutyGlobal = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		self:raisePilotTier(pPlayer, ghost)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, rewardMission)
	elseif (dutyGlobal ~= nil) then
		self:raisePilotTier(pPlayer, ghost)
		_G[dutyGlobal]:startQuest(pPlayer, pNpc)
	elseif (self.MET_SCREENS[screenID]) then
		self:setKey(pPlayer, SmugglerSquadronScreenplay.TIER4_MET_KEY)
	elseif (self.TIER_SCREENS[screenID]) then
		self:raisePilotTier(pPlayer, ghost)
	elseif (screenID == "ready_train") then
		-- C-1: every tier 4 skill the pilot lacks
		clonedConversation:removeAllOptions()

		local added = false

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry.skill)) then
				clonedConversation:addOption(entry.topic, entry.trained)
				added = true
			end
		end

		if (not added) then
			clonedConversation:setStopConversation(true)
		end
	elseif (screenID == "off_track") then
		-- C-2: off-track pilots may fly a duty (java:339-397)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_tier4:s_c1ff5062", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_refused")
	elseif (screenID == "ready") then
		-- C-3: the brief of the mission the pilot is ready for
		local n = self:getReadyMission(pPlayer) or 1

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_tier4:s_8be640b8", "m" .. n .. "_brief")
	end

	return pClonedScreen
end
