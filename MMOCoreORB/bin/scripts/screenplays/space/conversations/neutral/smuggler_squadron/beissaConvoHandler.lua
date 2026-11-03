-- Beissa (Smuggler tier 3) conversation handler; ported from SWG-Source tatooine_privateer_tier3.java. One-click, free-choice training: pre-NGE client lines (feature smuggler-tier3-beissa).
local SpaceHelpers = require("utils.space_helpers")

beissaConvoHandler = conv_handler:new {}

-- Missions: { head quest global, SmugglerSquadronScreenplay quest string of the head, quest string of the chain end }
beissaConvoHandler.MISSIONS = {
	{ head = "recovery_tatooine_privateer_tier3_1", questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE4" },
	{ head = "inspect_tatooine_privateer_tier3_2", questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE2" },
	{ head = "delivery_no_pickup_tatooine_privateer_tier3_3", questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE3" },
	{ head = "patrol_tatooine_privateer_tier3_4", questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE4" }
}

-- Pre-NGE free choice of a tier 3 skill, one click on the reward screen: { skill, topic reply }, in menu order (SWG grant order)
beissaConvoHandler.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_03", "@conversation/tatooine_privateer_tier3:s_c634ffcd" },
	{ "pilot_neutral_weapons_03", "@conversation/tatooine_privateer_tier3:s_a9aeb386" },
	{ "pilot_neutral_procedures_03", "@conversation/tatooine_privateer_tier3:s_523a54d5" },
	{ "pilot_neutral_droid_03", "@conversation/tatooine_privateer_tier3:s_473d09d8" }
}

-- Screens that pay a mission reward (once, on display) and offer the skill topics: screen -> mission number
beissaConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
beissaConvoHandler.START_SCREENS = {
	m1_retry_run_over = 1, m1_retry_shut_up = 1, m1_accept = 1, m1b_accept = 1,
	m2_retry_blast = 2, m2_retry_guess = 2, m2_accept = 2,
	m3_retry_angry_jabba = 3, m3_retry_hurry = 3, m3_accept = 3,
	m4_retry_why = 4, m4_retry_do_it = 4, m4_accept = 4
}

function beissaConvoHandler:getQuestString(n)
	return SmugglerSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function beissaConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function beissaConvoHandler:isWon(pPlayer, n)
	local endString = SmugglerSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function beissaConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function beissaConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

-- Any of the four chains is running
function beissaConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- SWG collectingQuestNReward (tatooine_privateer_tier3.java:68-167): mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function beissaConvoHandler:getRewardMission(pPlayer)
	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 3)

	for n = 1, 4 do
		if (self:isWon(pPlayer, n)) then
			if (count < n or (n == 4 and not self:hasStatus(pPlayer, 4, ":reward"))) then
				return n
			end
		end
	end

	return nil
end

-- Pays the reward of mission n once: the :reward key, then the head's credits and item
function beissaConvoHandler:payMission(pPlayer, n)
	if (self:hasStatus(pPlayer, n, ":reward")) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)
end

-- Pilot tier 2 -> 3 once the tier 2 series is won (Karrde can send a pilot here without Shamdon's bad news),
-- then 3 -> 4 once all four tier 3 skills are held
function beissaConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost == nil) then
		return
	end

	if (ghost:getPilotTier() == 2 and SmugglerSquadronScreenplay:hasCompletedTier2Series(pPlayer)) then
		ghost:incrementPilotTier()
	end

	if (ghost:getPilotTier() == 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
		ghost:incrementPilotTier()
	end
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function beissaConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: a topic reply on a reward screen grants that skill (free, as SWG noisyGrantSkill) and
-- shows the mission's trained screen. Any failed guard sends the pilot back through the gates, granting nothing.
function beissaConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""
	local n = self.REWARD_SCREENS[lastScreen]

	if (n == nil) then
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

	local skill = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry[2] == chosen) then
			skill = entry[1]
			break
		end
	end

	if (skill == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

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

	return LuaConversationTemplate(pConvTemplate):getScreen("m" .. n .. "_trained")
end

-- Side-effect free; gates in SWG order
function beissaConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
	elseif (not SmugglerSquadronScreenplay:hasCompletedTier2Series(pPlayer)) then
		return convoTemplate:getScreen("not_ready")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("busy")
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

	return convoTemplate:getScreen("tier_done")
end

function beissaConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
		self:raisePilotTier(pPlayer, ghost)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward), then C-1: every tier 3 skill the pilot lacks
		self:payMission(pPlayer, rewardMission)

		clonedConversation:removeAllOptions()

		local added = false

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], "m" .. rewardMission .. "_trained")
				added = true
			end
		end

		if (not added) then
			clonedConversation:setStopConversation(true)
		end
	elseif (screenID == "tier_done") then
		self:raisePilotTier(pPlayer, ghost)
	end

	return pClonedScreen
end
