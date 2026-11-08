-- Arnecio Ulvaw'op (Crimson Phoenix Squadron tier 3) conversation handler; ported from SWG-Source tatooine_rebel_tier3.java (JU). One-click, free-choice free training and the hand-off to General Ufwol (not ported yet): pre-NGE client lines (feature crimson-phoenix-tier3-ulvawop).
local SpaceHelpers = require("utils.space_helpers")

ulvawopConvoHandler = conv_handler:new {}

-- Missions: head quest global, quest string of the chain end, Rebel standing paid with the reward
ulvawopConvoHandler.MISSIONS = {
	{ head = "recovery_tatooine_rebel_tier3_1", endString = "TIER3_QUEST_STRING_1_SIDE3", standing = 100 },
	{ head = "inspect_tatooine_rebel_tier3_2", endString = "TIER3_QUEST_STRING_2_SIDE3", standing = 100 },
	{ head = "delivery_tatooine_rebel_tier3_3", endString = "TIER3_QUEST_STRING_3_SIDE3", standing = 100 },
	{ head = "assassinate_tatooine_rebel_tier3_4", endString = "TIER3_QUEST_STRING_4_SIDE4", standing = 100 }
}

-- Pre-NGE free choice of a tier 3 skill, one click: { skill, topic reply, trained screen }, in menu order
ulvawopConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_03", "@conversation/tatooine_rebel_tier3:s_c43eb58", "trained_starships" },
	{ "pilot_rebel_navy_weapons_03", "@conversation/tatooine_rebel_tier3:s_9b989e16", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_03", "@conversation/tatooine_rebel_tier3:s_3a9f883c", "trained_procedures" },
	{ "pilot_rebel_navy_droid_03", "@conversation/tatooine_rebel_tier3:s_473d09d8", "trained_droid" }
}

-- The reward screens' decline reply (leads to on_mission)
ulvawopConvoHandler.DECLINE_REPLY = "@conversation/tatooine_rebel_tier3:s_337aea88"

-- Screens that start a mission (the head chain is started on display): screen -> mission number
ulvawopConvoHandler.START_SCREENS = {
	m1_accept_d5bf212f = 1, m1_retry_652ff698 = 1, m1_retry_a53ea74c = 1,
	m2_accept_b1479cf9 = 2, m2_retry_59552474 = 2, m2_retry_3eeaed57 = 2,
	m3_accept_94a2001c = 3, m3_accept_573af66b = 3, m3_accept_89962192 = 3, m3_accept_404b8a10 = 3, m3_retry_5973a2b6 = 3, m3_retry_665b67d1 = 3,
	m4_accept_7b3fb40b = 4, m4_accept_2493aca3 = 4, m4_retry_d6643019 = 4, m4_retry_9df42b04 = 4
}

-- Screens that pay a mission reward (once, on display) and offer the training topics: screen -> mission number
ulvawopConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens whose line carries the %TU / %NU name token
ulvawopConvoHandler.NAME_SCREENS = {
	grounded = true, m1_offer = true, m1_8a88463d = true, m3_83b7fee0 = true
}

function ulvawopConvoHandler:getQuestString(n)
	return CrimsonPhoenixSquadronScreenplay["TIER3_QUEST_STRING_" .. n]
end

-- <playerID><questName><suffix> is "1"
function ulvawopConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function ulvawopConvoHandler:isWon(pPlayer, n)
	local endString = CrimsonPhoenixSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function ulvawopConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function ulvawopConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function ulvawopConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains is running
function ulvawopConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- The EKER_PILOT_KEY value, or nil when unset
function ulvawopConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- Tier 2 complete, the pilot flag set and Major Eker's mission 4 paid (the condition of Eker's tier3_handoff)
function ulvawopConvoHandler:isReadyForTier3(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2) or self:getPilotFlag(pPlayer) == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. CrimsonPhoenixSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward") == "1"
end

-- JU isReadyForTier4: tier 3 complete, the pilot flag set and mission 4 paid
function ulvawopConvoHandler:isReadyForTier4(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and self:getPilotFlag(pPlayer) ~= nil and self:isPaid(pPlayer, 4)
end

-- SWG collectingQuestNReward: mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function ulvawopConvoHandler:getRewardMission(pPlayer)
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
function ulvawopConvoHandler:getLastScreenID(pPlayer)
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
function ulvawopConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost ~= nil and ghost:getPilotTier() == 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3)) then
		ghost:incrementPilotTier()
	end
end

-- Pre-NGE one-click training: a topic reply on a reward screen grants the skill (free, as JU noisyGrantSkill) and
-- shows its trained screen. Any failed guard sends the pilot back through the gates.
function ulvawopConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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

-- First screen (side-effect free). Gate order follows tatooine_rebel_tier3.java OnStartNpcConversation (:8088 on)
function ulvawopConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
	elseif (not SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not SpaceHelpers:isCrimsonPhoenixSquadron(pPlayer)) then
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

	for n = 1, 4 do
		if (not self:isWon(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_offer")
		end
	end

	if (self:isReadyForTier4(pPlayer)) then
		return convoTemplate:getScreen("handoff")
	end

	return convoTemplate:getScreen("not_ready")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 100 Rebel standing
function ulvawopConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)
end

function ulvawopConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption(self.DECLINE_REPLY, "on_mission")
	elseif (screenID == "handoff") then
		self:raisePilotTier(pPlayer, ghost)
	end

	return pClonedScreen
end
