-- Brother Ezkiel (Vortex Squadron tier 3) conversation handler; ported from SWG-Source naboo_rebel_tier3.java. One-click, free-choice free training and the hand-off to Brother Extok Evin: pre-NGE client lines (feature vortex-tier3-ezkiel).
local SpaceHelpers = require("utils.space_helpers")

ezkielConvoHandler = conv_handler:new {}

-- Missions: head quest global, quest string of the chain end, Rebel standing paid with the reward
ezkielConvoHandler.MISSIONS = {
	{ head = "assassinate_naboo_rebel_tier3_1", endString = "TIER3_QUEST_STRING_1_SIDE4", standing = 100 },
	{ head = "space_battle_naboo_rebel_tier3_2", endString = "TIER3_QUEST_STRING_2_SIDE4", standing = 100 },
	{ head = "patrol_naboo_rebel_tier3_3", endString = "TIER3_QUEST_STRING_3_SIDE4", standing = 100 },
	{ head = "space_battle_naboo_rebel_tier3_4", endString = "TIER3_QUEST_STRING_4_SIDE4", standing = 100 }
}

-- Pre-NGE free choice of a tier 3 skill, one click: { skill, topic reply, trained screen }, in menu order
ezkielConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_03", "@conversation/naboo_rebel_tier3:s_879249ea", "trained_starships" },
	{ "pilot_rebel_navy_weapons_03", "@conversation/naboo_rebel_tier3:s_a436613b", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_03", "@conversation/naboo_rebel_tier3:s_e6be1367", "trained_procedures" },
	{ "pilot_rebel_navy_droid_03", "@conversation/naboo_rebel_tier3:s_ccecab6a", "trained_droid" }
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
ezkielConvoHandler.START_SCREENS = {
	m1_failed = 1, m1_accept_d683dc69 = 1, m1_accept_401aa65c = 1, m1_accept_c872184 = 1, m1_accept_fb1d4add = 1, m1_accept_21aa6c60 = 1,
	m2_retry_turn = 2, m2_retry_shot = 2, m2_accept_cb3876f5 = 2, m2_accept_f8a22f8 = 2,
	m3_retry_defeated = 3, m3_retry_blowtorch = 3, m3_accept_68355d90 = 3, m3_accept_18c308e1 = 3,
	m4_failed = 4, m4_accept_aa7a038e = 4, m4_accept_b24e355f = 4
}

-- Screens that pay a mission reward (once, on display) and offer the training topics: screen -> mission number
ezkielConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens whose line carries the %TU / %NU name token
ezkielConvoHandler.NAME_SCREENS = {
	tier_done = true, grounded = true, m1_failed = true, m4_failed = true,
	m1_reward = true, m1_offer = true, m1_840cb413 = true, m2_offer = true
}

function ezkielConvoHandler:getQuestString(n)
	return VortexSquadronScreenplay["TIER3_QUEST_STRING_" .. n]
end

-- <playerID><questName><suffix> is "1"
function ezkielConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function ezkielConvoHandler:isWon(pPlayer, n)
	local endString = VortexSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function ezkielConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function ezkielConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function ezkielConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains is running
function ezkielConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- The VORTEX_PILOT_KEY value, or nil when unset
function ezkielConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. VortexSquadronScreenplay.VORTEX_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- Tier 2 complete, the Vortex flag set and Brother Vrovel's mission 4 paid
function ezkielConvoHandler:isReadyForTier3(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2) or self:getPilotFlag(pPlayer) == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. VortexSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward") == "1"
end

-- J3 isReadyForTier4: tier 3 complete, the Vortex flag set and mission 4 paid
function ezkielConvoHandler:isReadyForTier4(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and self:getPilotFlag(pPlayer) ~= nil and self:isPaid(pPlayer, 4)
end

-- SWG collectingQuestNReward: mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function ezkielConvoHandler:getRewardMission(pPlayer)
	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 3)

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
function ezkielConvoHandler:getLastScreenID(pPlayer)
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
function ezkielConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost ~= nil and ghost:getPilotTier() <= 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3)) then
		ghost:incrementPilotTier()
	end
end

-- Pre-NGE one-click training: a topic reply on a reward screen grants the skill (free, as J3 noisyGrantSkill) and
-- shows its trained screen. Any failed guard sends the pilot back through the gates.
function ezkielConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local mission = self.REWARD_SCREENS[self:getLastScreenID(pPlayer) or ""]

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

-- First screen (side-effect free). Gate order follows naboo_rebel_tier3.java OnStartNpcConversation (:4574 on)
function ezkielConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
	elseif (self:isReadyForTier4(pPlayer)) then
		return convoTemplate:getScreen("tier_done")
	elseif (not SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not SpaceHelpers:isVortexSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	-- Rebels only: negative standing or a lost Rebel faction is grounded
	elseif (ghost:getFactionStanding("rebel") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONREBEL) then
		return convoTemplate:getScreen("grounded")
	elseif (not self:isReadyForTier3(pPlayer)) then
		return convoTemplate:getScreen("not_ready")
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

	for n = 1, 3 do
		if (not self:isWon(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_offer")
		end
	end

	return convoTemplate:getScreen("m4_offer")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 100 Rebel standing
function ezkielConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)
end

function ezkielConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	if (self.NAME_SCREENS[screenID]) then
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
	elseif (screenID == "tier_done") then
		self:raisePilotTier(pPlayer, ghost)
	end

	return pClonedScreen
end
