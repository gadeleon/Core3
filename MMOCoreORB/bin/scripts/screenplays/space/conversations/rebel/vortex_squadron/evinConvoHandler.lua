-- Brother Extok Evin (Vortex Squadron tier 4) conversation handler; ported from SWG-Source naboo_rebel_tier4.java. One-click, free-choice training bought with XP, missions alternating with skills, the duties and the hand-off to Admiral Willham Burke: pre-NGE client lines (feature vortex-tier4-extok-evin-convo).
local SpaceHelpers = require("utils.space_helpers")

evinConvoHandler = conv_handler:new {}

-- Missions: head quest global, quest string constant, first-level children (either one won is a win, J4:116-175), Rebel standing paid with the reward
evinConvoHandler.MISSIONS = {
	{ head = "survival_naboo_rebel_tier4_1", questString = "TIER4_QUEST_STRING_1", wins = { "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2" }, standing = 150 },
	{ head = "assassinate_naboo_rebel_tier4_2", questString = "TIER4_QUEST_STRING_2", wins = { "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2" }, standing = 150 },
	{ head = "rescue_naboo_rebel_tier4_3", questString = "TIER4_QUEST_STRING_3", wins = { "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2" }, standing = 150 },
	{ head = "space_battle_naboo_rebel_tier4_4", questString = "TIER4_QUEST_STRING_4", wins = { "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2" }, standing = 150 }
}

-- Duty screens: screen -> { duty quest global, quest string constant }
evinConvoHandler.DUTY_SCREENS = {
	duty_destroy = { global = "destroy_duty_naboo_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_1" },
	duty_escort = { global = "escort_duty_naboo_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_2" },
	duty_recovery = { global = "recovery_duty_naboo_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_3" },
	duty_rescue = { global = "rescue_duty_naboo_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_4" }
}

-- Pre-NGE free choice of a tier 4 skill, one click: { skill, topic reply, trained screen }, in menu order
evinConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_04", "@conversation/naboo_rebel_tier4:s_f4d84e3", "trained_starships" },
	{ "pilot_rebel_navy_weapons_04", "@conversation/naboo_rebel_tier4:s_dbb3b0b0", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_04", "@conversation/naboo_rebel_tier4:s_d0f87f24", "trained_procedures" },
	{ "pilot_rebel_navy_droid_04", "@conversation/naboo_rebel_tier4:s_71d852f5", "trained_droid" }
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
evinConvoHandler.START_SCREENS = {
	m1_retry_c8592539 = 1, m1_retry_4a835de4 = 1, m1_accept_df1c8925 = 1,
	m2_retry_80803e51 = 2, m2_retry_13010c2d = 2, m2_accept_4eaf90e6 = 2,
	m3_retry_34a99b58 = 3, m3_retry_84f5730a = 3, m3_accept_4e0bf82f = 3, m3_accept_dd76100c = 3,
	m4_retry_3de94b24 = 4, m4_retry_be8a1d81 = 4, m4_accept_122f0ea4 = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
evinConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- The screen that sets the first-meeting key on display
evinConvoHandler.MET_SCREEN = "met_b5eac7c2"

-- Screens that only raise the pilot tier on display
evinConvoHandler.TIER_SCREENS = {
	transfer = true, here_for_work = true
}

-- Screens whose line carries the %TU / %NU name token
evinConvoHandler.NAME_SCREENS = {
	grounded = true, m4_retry_3de94b24 = true, met_b5815881 = true, duty_brief_4 = true, duty_recovery = true, duty_rescue = true,
	m1_reward = true, m4_reward_cc6fef40 = true, m4_reward_ac8b75ef = true, m1_offer = true, m2_d8a1ee7e = true
}

function evinConvoHandler:getQuestString(n)
	return VortexSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function evinConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The VORTEX_PILOT_KEY value, or nil when unset
function evinConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. VortexSquadronScreenplay.VORTEX_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- SWG hasMetMe (the metTier4 space flag)
function evinConvoHandler:hasMet(pPlayer)
	return getQuestStatus(CreatureObject(pPlayer):getObjectID() .. VortexSquadronScreenplay.TIER4_MET_KEY) == "1"
end

-- Tier 4 skills held
function evinConvoHandler:tier4Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 4)
end

-- J4 either first-level child of the head is complete
function evinConvoHandler:isWon(pPlayer, n)
	for _, name in ipairs(self.MISSIONS[n].wins) do
		local quest = VortexSquadronScreenplay[name]

		if (SpaceHelpers:isSpaceQuestComplete(pPlayer, quest.type, quest.name)) then
			return true
		end
	end

	return false
end

-- Any member of the mission's chain is running
function evinConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function evinConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function evinConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four duties is running
function evinConvoHandler:isDutyActive(pPlayer)
	for _, duty in pairs(self.DUTY_SCREENS) do
		local quest = VortexSquadronScreenplay[duty.questString]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, quest.type, quest.name)) then
			return true
		end
	end

	return false
end

-- Any of the four chains or the duties is running
function evinConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return self:isDutyActive(pPlayer)
end

-- Negative Rebel standing or a lost Rebel faction
function evinConvoHandler:isGrounded(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return false
	end

	return LuaPlayerObject(pGhost):getFactionStanding("rebel") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONREBEL
end

-- J4 canFlyNonTrackDuty (:195-202): tier 1 done and no quest
function evinConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- Tier 3 complete, the Vortex flag set and Brother Ezkiel's mission 4 paid
function evinConvoHandler:isReadyForTier4(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) or self:getPilotFlag(pPlayer) == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. VortexSquadronScreenplay.TIER3_QUEST_STRING_4.name .. ":reward") == "1"
end

-- J4 readyForMissionFour..One: mission n needs n tier 4 skills (mission 1: at least 1) and is unpaid
function evinConvoHandler:getOfferMission(pPlayer)
	local count = self:tier4Count(pPlayer)

	for n = 4, 1, -1 do
		if (not self:isPaid(pPlayer, n) and ((n == 1 and count >= 1) or (n >= 2 and count == n))) then
			return n
		end
	end

	return nil
end

-- J4 isReadyForTraining (:100-107)
function evinConvoHandler:isReadyForTraining(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4) and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and SpaceHelpers:hasExperienceForTraining(pPlayer, 4) == true
end

-- The id of the screen the player chose an option on
function evinConvoHandler:getLastScreenID(pPlayer)
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

-- Pilot tier 3 -> 4 once tier 3 is complete, then 4 -> 5 once tier 4 is complete
function evinConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost == nil) then
		return
	end

	if (ghost:getPilotTier() == 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3)) then
		ghost:incrementPilotTier()
	end

	if (ghost:getPilotTier() == 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4)) then
		ghost:incrementPilotTier()
	end
end

-- The id of the screen the gates open (Conversation flow table E), or nil. Side-effect free
function evinConvoHandler:gateScreenId(pPlayer)
	if (pPlayer == nil) then
		return nil
	end

	if (not isJtlEnabled()) then
		return "not_pilot"
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil or LuaPlayerObject(pGhost) == nil) then
		return "not_pilot"
	end

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return "not_pilot"
	elseif (not SpaceHelpers:isRebelPilot(pPlayer)) then
		return "wrong_faction"
	elseif (self:isGrounded(pPlayer)) then
		return "grounded"
	elseif (not SpaceHelpers:isVortexSquadron(pPlayer)) then
		return "off_track"
	elseif (not self:isReadyForTier4(pPlayer)) then
		return "not_ready"
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return "on_mission"
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return "m" .. n .. "_failed"
		end
	end

	if (not self:hasMet(pPlayer)) then
		return "intro"
	end

	for n = 1, 4 do
		if (self:isWon(pPlayer, n) and not self:isPaid(pPlayer, n)) then
			return "m" .. n .. "_reward"
		end
	end

	local offer = self:getOfferMission(pPlayer)

	if (offer ~= nil) then
		return "m" .. offer .. "_offer"
	elseif (self:isReadyForTraining(pPlayer)) then
		return "training"
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4)) then
		return "tier4_incomplete"
	elseif (not SpaceHelpers:hasMasterSkill(pPlayer, "rebel_navy")) then
		return "transfer"
	end

	return "here_for_work"
end

-- First screen (side-effect free). Gate order follows naboo_rebel_tier4.java OnStartNpcConversation (:4484 on)
function evinConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local screenID = self:gateScreenId(pPlayer)

	if (screenID == nil) then
		return nil
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(screenID)
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 150 Rebel standing
function evinConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)
end

-- Pre-NGE one-click training: a topic reply on `training` buys the skill (1,000,000 XP) and shows its trained screen.
-- Any failed guard sends the pilot back through the gates.
function evinConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if (self:getLastScreenID(pPlayer) ~= "training") then
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

	if (CreatureObject(pPlayer):hasSkill(skill) or self:gateScreenId(pPlayer) ~= "training" or not LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
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

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

function evinConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
	local duty = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		self:raisePilotTier(pPlayer, ghost)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		self:raisePilotTier(pPlayer, ghost)
		_G[duty.global]:startQuest(pPlayer, pNpc)
	elseif (screenID == self.MET_SCREEN) then
		setQuestStatus(playerID .. VortexSquadronScreenplay.TIER4_MET_KEY, 1)
	elseif (self.TIER_SCREENS[screenID]) then
		self:raisePilotTier(pPlayer, ghost)
	elseif (screenID == "training") then
		-- C-1: every tier 4 skill the pilot lacks
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
	elseif (screenID == "off_track") then
		-- C-2: the duties only for a pilot who can fly them
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_rebel_tier4:s_dab8fd8e", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_refused")
	end

	return pClonedScreen
end
