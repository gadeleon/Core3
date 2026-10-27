-- Haymir Rendundi (Black Epsilon tier 3) conversation handler; ported from SWG-Source corellia_imperial_tier3.java. One-click, free-choice training and the "wanted" gate: pre-NGE client lines (feature black-epsilon-tier3-haymir).
local SpaceHelpers = require("utils.space_helpers")

haymirConvoHandler = conv_handler:new {}

-- Missions: { head quest global, BlackEpsilonSquadronScreenplay quest string of the head, quest string of the chain end }
haymirConvoHandler.MISSIONS = {
	{ head = "patrol_corellia_imperial_tier3_1", questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE3" },
	{ head = "recovery_corellia_imperial_tier3_2", questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE3" },
	{ head = "rescue_corellia_imperial_tier3_3", questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE1" },
	{ head = "recovery_corellia_imperial_tier3_4", questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE3" }
}

-- Pre-NGE free choice of a tier 3 skill, one click: { skill, topic reply, trained screen }, in menu order
haymirConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_03", "@conversation/corellia_imperial_tier3:s_adc23ed9", "trained_starships" },
	{ "pilot_imperial_navy_weapons_03", "@conversation/corellia_imperial_tier3:s_77f35957", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_03", "@conversation/corellia_imperial_tier3:s_3f4fdcbd", "trained_procedures" },
	{ "pilot_imperial_navy_droid_03", "@conversation/corellia_imperial_tier3:s_2dd8b42", "trained_droid" }
}

-- The skill lead-in screens that carry the topic replies (built at run time)
haymirConvoHandler.TRAINING_SCREENS = {
	m1_training = true, m2_training = true, m3_training = true, m4_training = true, m4_training_philosophy = true
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
haymirConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry_excuse = 1, m1_retry = 1,
	m2_accept = 2, m2_retry_sarcastic = 2, m2_retry = 2,
	m3_accept = 3, m3_retry = 3, m3_retry_rebels = 3,
	m4_accept = 4, m4_retry = 4, m4_retry_promise = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
haymirConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

function haymirConvoHandler:getQuestString(n)
	return BlackEpsilonSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function haymirConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function haymirConvoHandler:isWon(pPlayer, n)
	local endString = BlackEpsilonSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function haymirConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function haymirConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

-- Any of the four chains is running
function haymirConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- SWG collectingQuestNReward (corellia_imperial_tier3.java:68-167): mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function haymirConvoHandler:getRewardMission(pPlayer)
	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 3)

	for n = 1, 4 do
		if (self:isWon(pPlayer, n)) then
			if (count < n or (n == 4 and not self:hasStatus(pPlayer, 4, ":reward"))) then
				return n
			end
		end
	end

	return nil
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function haymirConvoHandler:getLastScreenID(pPlayer)
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

-- Raises pilot tier 3 to 4 once all four tier 3 skills are held
function haymirConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost ~= nil and ghost:getPilotTier() <= 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		ghost:incrementPilotTier()
	end
end

-- Pre-NGE one-click training: a topic reply on a training screen grants the skill (free, as J noisyGrantSkill) and
-- shows its trained screen. Any failed guard sends the pilot back through the gates.
function haymirConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if (not self.TRAINING_SCREENS[self:getLastScreenID(pPlayer) or ""]) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	local link = nil
	local convSession = CreatureObject(pPlayer):getConversationSession()

	if (convSession ~= nil) then
		local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()

		if (pLastScreen ~= nil) then
			link = LuaConversationScreen(pLastScreen):getOptionLink(selectedOption)
		end
	end

	local choice = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry[3] == link) then
			choice = entry
		end
	end

	if (choice == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	local skill = choice[1]

	if (CreatureObject(pPlayer):hasSkill(skill) or self:getRewardMission(pPlayer) == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	SpaceHelpers:grantSpaceSkill(pPlayer, skill, false)

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 3
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		self:raisePilotTier(pPlayer, LuaPlayerObject(pGhost))
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

function haymirConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("not_pilot")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	if (not (SpaceHelpers:isImperialPilot(pPlayer) or SpaceHelpers:isRebelPilot(pPlayer) or SpaceHelpers:isNeutralPilot(pPlayer))) then
		return convoTemplate:getScreen("not_pilot")
	elseif (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not SpaceHelpers:isBlackEpsilonSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
		return convoTemplate:getScreen("not_ready")
	-- The "wanted" gate: negative Imperial standing
	elseif (ghost:getFactionStanding("imperial") < 0) then
		return convoTemplate:getScreen("wanted")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_failed")
		end
	end

	local rewardMission = self:getRewardMission(pPlayer)

	if (rewardMission ~= nil) then
		return convoTemplate:getScreen("m" .. rewardMission .. "_reward")
	end

	for n = 1, 4 do
		if (not self:isWon(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_offer")
		end
	end

	return convoTemplate:getScreen("tour_complete")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 100 Imperial standing
function haymirConvoHandler:payMission(pPlayer, ghost, n)
	if (self:hasStatus(pPlayer, n, ":reward")) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 100)
end

function haymirConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (self.TRAINING_SCREENS[screenID]) then
		-- C-1: every tier 3 skill the pilot lacks
		clonedConversation:removeAllOptions()

		local added = false

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
				added = true
			end
		end

		if (not added) then
			clonedConversation:setStopConversation(true)
		end
	elseif (screenID == "tour_complete") then
		self:raisePilotTier(pPlayer, ghost)
	end

	return pClonedScreen
end
