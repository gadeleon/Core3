-- Captain Denner (Storm Squadron tier 3) conversation handler; ported from SWG-Source tatooine_imperial_tier3.java. One-click, free-choice training and the grounded gate: pre-NGE client lines (feature storm-tier3-denner).
local SpaceHelpers = require("utils.space_helpers")

dennerConvoHandler = conv_handler:new {}

-- Missions: { head quest global, StormSquadronScreenplay quest string of the head, quest string of the chain end }
dennerConvoHandler.MISSIONS = {
	{ head = "escort_tatooine_imperial_tier3_1", questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE4" },
	{ head = "inspect_tatooine_imperial_tier3_2", questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE5" },
	{ head = "delivery_tatooine_imperial_tier3_3", questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE4" },
	{ head = "assassinate_tatooine_imperial_tier3_4", questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE3" }
}

-- Pre-NGE free choice of a tier 3 skill, one click: { skill, topic reply, trained screen }, in menu order
dennerConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_03", "@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships" },
	{ "pilot_imperial_navy_weapons_03", "@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_03", "@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures" },
	{ "pilot_imperial_navy_droid_03", "@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid" }
}

-- The skill lead-in screens that carry the topic replies (built at run time): screen -> mission number
dennerConvoHandler.TRAINING_SCREENS = {
	m1_training_813c7eed = 1, m1_training_cb3f07d5 = 1, m1_training_c198d74c = 1,
	m2_training_dc98dda7 = 2, m2_training_64617aad = 2, m2_training_a3f5c141 = 2,
	m3_training_1d7c7ed2 = 3, m3_training_612db735 = 3, m3_training_41ecd1f = 3,
	m4_training_df0f8037 = 4, m4_training_d837376f = 4, m4_training_30651d99 = 4
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
dennerConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_assignment = 1, m1_retry_fail = 1, m1_retry_sooner = 1, m1_retry_luck = 1, m1_retry_replaceable = 1,
	m2_accept = 2, m2_accept_promise = 2, m2_retry_prove = 2, m2_retry_shut = 2,
	m3_accept = 3, m3_accept_half = 3, m3_accept_smite = 3, m3_retry_again = 3, m3_retry_prove = 3,
	m4_accept = 4, m4_accept_confident = 4, m4_accept_blessing = 4, m4_failed = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
dennerConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens whose line carries the %TU / %NU name token
local NAME_SCREENS = {
	wanted = true, wanted_cd3a54f7 = true, tour_7ea66fab = true, tour_a099839c = true, m4_reward = true,
	m1_offer_4ca34e11 = true, m1_offer_52345d7c = true, m2_accept = true, m2_accept_promise = true, m3_offer = true,
	m3_accept = true, m3_accept_half = true, m3_accept_smite = true
}

function dennerConvoHandler:getQuestString(n)
	return StormSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function dennerConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function dennerConvoHandler:isWon(pPlayer, n)
	local endString = StormSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function dennerConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function dennerConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function dennerConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains is running
function dennerConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- All four tier 2 skills and Alozen's mission 3 paid (J3 isReadyForTier3)
function dennerConvoHandler:isReadyForTier3(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. StormSquadronScreenplay.TIER2_QUEST_STRING_6.name .. ":reward") == "1"
end

-- SWG collectingQuestNReward: mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function dennerConvoHandler:getRewardMission(pPlayer)
	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 3)

	for n = 1, 4 do
		if (self:isWon(pPlayer, n)) then
			if (count < n or (n == 4 and not self:isPaid(pPlayer, 4))) then
				return n
			end
		end
	end

	return nil
end

-- The id of the screen the player chose an option on
function dennerConvoHandler:getLastScreenID(pPlayer)
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
function dennerConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost ~= nil and ghost:getPilotTier() <= 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		ghost:incrementPilotTier()
	end
end

-- Pre-NGE one-click training: a topic reply on a training screen grants the skill (free, as J3 noisyGrantSkill) and
-- shows its trained screen. Any failed guard sends the pilot back through the gates.
function dennerConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local mission = self.TRAINING_SCREENS[self:getLastScreenID(pPlayer) or ""]

	if (mission == nil) then
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

	local skill = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry[3] == link) then
			skill = entry[1]
		end
	end

	if (skill == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	if (CreatureObject(pPlayer):hasSkill(skill) or self:getRewardMission(pPlayer) ~= mission) then
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

-- First screen (side-effect free). Gate order follows tatooine_imperial_tier3.java OnStartNpcConversation (:7724 on)
function dennerConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not self:isReadyForTier3(pPlayer)) then
		return convoTemplate:getScreen("not_ready")
	elseif (not SpaceHelpers:isStormSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	-- Imperials only: negative standing or a lost Imperial faction is grounded
	elseif (ghost:getFactionStanding("imperial") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen("wanted")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	end

	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 3)

	if (count >= 4 and self:isPaid(pPlayer, 4)) then
		return convoTemplate:getScreen("tour_complete")
	end

	for _, n in ipairs({ 4, 2, 3, 1 }) do
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
function dennerConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 100)
end

function dennerConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	if (NAME_SCREENS[screenID]) then
		clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())
	end

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
	elseif (self.TRAINING_SCREENS[screenID] ~= nil) then
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
