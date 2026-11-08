-- General Ufwol (Crimson Phoenix Squadron tier 4) conversation handler; ported from SWG-Source tatooine_rebel_tier4.java (JF). One-click, free-choice training bought with XP, missions alternating with skills, the duties and the hand-off to Admiral Willham Burke: pre-NGE client lines (feature crimson-phoenix-tier4-ufwol).
local SpaceHelpers = require("utils.space_helpers")

ufwolConvoHandler = conv_handler:new {}

-- Missions: head quest global, quest string constant, won children (either one complete is a win, JF:120-179), Rebel standing paid with the reward
ufwolConvoHandler.MISSIONS = {
	{ head = "space_battle_tatooine_rebel_tier4_1", questString = "TIER4_QUEST_STRING_1", wins = { "TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE3" }, standing = 150 },
	{ head = "recovery_tatooine_rebel_tier4_2", questString = "TIER4_QUEST_STRING_2", wins = { "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2" }, standing = 150 },
	{ head = "space_battle_tatooine_rebel_tier4_3", questString = "TIER4_QUEST_STRING_3", wins = { "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2" }, standing = 150 },
	{ head = "assassinate_tatooine_rebel_tier4_4", questString = "TIER4_QUEST_STRING_4", wins = { "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2" }, standing = 150 }
}

-- Duty screens: screen -> { duty quest global, quest string constant }
ufwolConvoHandler.DUTY_SCREENS = {
	duty_destroy = { global = "destroy_duty_tatooine_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_1" },
	duty_escort = { global = "escort_duty_tatooine_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_2" },
	duty_recovery = { global = "recovery_duty_tatooine_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_3" },
	duty_rescue = { global = "rescue_duty_tatooine_rebel_tier4_1", questString = "TIER4_QUEST_STRING_DUTY_4" }
}

-- Pre-NGE free choice of a tier 4 skill, one click: { skill, topic reply, trained screen }, in menu order
ufwolConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_04", "@conversation/tatooine_rebel_tier4:s_efdacfde", "trained_starships" },
	{ "pilot_rebel_navy_weapons_04", "@conversation/tatooine_rebel_tier4:s_daa1d4f4", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_04", "@conversation/tatooine_rebel_tier4:s_270a2a57", "trained_procedures" },
	{ "pilot_rebel_navy_droid_04", "@conversation/tatooine_rebel_tier4:s_1e8289a2", "trained_droid" }
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
ufwolConvoHandler.START_SCREENS = {
	m1_failed = 1, m1_accept_d68a9f0a = 1,
	m2_failed = 2, m2_accept_9fcfe841 = 2,
	m3_failed = 3, m3_accept_fed525e5 = 3,
	m4_failed = 4, m4_accept_cc7b5947 = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
ufwolConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- The screen that sets the first-meeting key on display
ufwolConvoHandler.MET_SCREEN = "met_258d2f1e"

-- Screens that only raise the pilot tier on display
ufwolConvoHandler.TIER_SCREENS = {
	transfer = true, here_for_work = true
}

-- Screens whose line carries the %TU name token
ufwolConvoHandler.NAME_SCREENS = {
	m2_reward = true, trained_starships = true, trained_procedures = true, m1_79e6aa32 = true, m2_c946f118 = true, m2_s239 = true, m3_accept_fed525e5 = true
}

function ufwolConvoHandler:getQuestString(n)
	return CrimsonPhoenixSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function ufwolConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The EKER_PILOT_KEY value, or nil when unset
function ufwolConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- SWG hasMetMe (the metTier4 space flag)
function ufwolConvoHandler:hasMet(pPlayer)
	return getQuestStatus(CreatureObject(pPlayer):getObjectID() .. CrimsonPhoenixSquadronScreenplay.TIER4_MET_KEY) == "1"
end

-- Tier 4 skills held
function ufwolConvoHandler:tier4Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 4)
end

-- JF either first-level child of the head is complete
function ufwolConvoHandler:isWon(pPlayer, n)
	for _, name in ipairs(self.MISSIONS[n].wins) do
		local quest = CrimsonPhoenixSquadronScreenplay[name]

		if (SpaceHelpers:isSpaceQuestComplete(pPlayer, quest.type, quest.name)) then
			return true
		end
	end

	return false
end

-- Any member of the mission's chain is running
function ufwolConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function ufwolConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function ufwolConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four duties is running
function ufwolConvoHandler:isDutyActive(pPlayer)
	for _, duty in pairs(self.DUTY_SCREENS) do
		local quest = CrimsonPhoenixSquadronScreenplay[duty.questString]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, quest.type, quest.name)) then
			return true
		end
	end

	return false
end

-- Any of the four chains or the duties is running
function ufwolConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return self:isDutyActive(pPlayer)
end

-- Negative Rebel standing or a lost Rebel faction
function ufwolConvoHandler:isGrounded(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return false
	end

	return LuaPlayerObject(pGhost):getFactionStanding("rebel") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONREBEL
end

-- JF canFlyNonTrackDuty (:215-222): tier 3 done and no quest
function ufwolConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- Tier 3 complete, the Crimson flag set and Arnecio Ulvaw'op's mission 4 paid (Q-B1 = A)
function ufwolConvoHandler:isReadyForTier4(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) or self:getPilotFlag(pPlayer) == nil) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. CrimsonPhoenixSquadronScreenplay.TIER3_QUEST_STRING_4.name .. ":reward") == "1"
end

-- JF readyForMissionFour..One: mission n needs n tier 4 skills (mission 1: at least 1) and is unpaid
function ufwolConvoHandler:getOfferMission(pPlayer)
	local count = self:tier4Count(pPlayer)

	for n = 4, 1, -1 do
		if (not self:isPaid(pPlayer, n) and ((n == 1 and count >= 1) or (n >= 2 and count == n))) then
			return n
		end
	end

	return nil
end

-- JF isReadyForTraining (:100-107)
function ufwolConvoHandler:isReadyForTraining(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4) and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and SpaceHelpers:hasExperienceForTraining(pPlayer, 4) == true
end

-- The id of the screen the player chose an option on
function ufwolConvoHandler:getLastScreenID(pPlayer)
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
function ufwolConvoHandler:raisePilotTier(pPlayer, ghost)
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
function ufwolConvoHandler:gateScreenId(pPlayer)
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
	elseif (not SpaceHelpers:isCrimsonPhoenixSquadron(pPlayer)) then
		return "off_track"
	elseif (self:isGrounded(pPlayer)) then
		return "grounded"
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

-- First screen (side-effect free). Gate order follows tatooine_rebel_tier4.java OnStartNpcConversation (:5828 on)
function ufwolConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
function ufwolConvoHandler:payMission(pPlayer, ghost, n)
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
function ufwolConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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

function ufwolConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
		setQuestStatus(playerID .. CrimsonPhoenixSquadronScreenplay.TIER4_MET_KEY, 1)
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
		clonedConversation:addOption("@conversation/tatooine_rebel_tier4:s_d157e1de", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_refused")
	end

	return pClonedScreen
end
