-- Nin Gursawe, the Insurgent (Black Epsilon tier 4) conversation handler; ported from SWG-Source corellia_imperial_tier4.java. One-click, free-choice training bought with XP, the "wanted" gate and the hand-off toward Grand Admiral Declann: pre-NGE client lines (feature black-epsilon-tier4-nin-gursawe).
local SpaceHelpers = require("utils.space_helpers")

ninGursaweConvoHandler = conv_handler:new {}

-- Missions: { head quest global, BlackEpsilonSquadronScreenplay quest string of the head, quest string of the chain end }
ninGursaweConvoHandler.MISSIONS = {
	{ head = "patrol_corellia_imperial_tier4_1", questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE2" },
	{ head = "recovery_corellia_imperial_tier4_2", questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE2" },
	{ head = "escort_corellia_imperial_tier4_3", questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE3" },
	{ head = "assassinate_corellia_imperial_tier4_4", questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE4" }
}

-- Screens that start a duty: screen -> duty quest global
ninGursaweConvoHandler.DUTY_SCREENS = {
	duty_destroy = "destroy_duty_corellia_imperial_tier4_1",
	duty_escort = "escort_duty_corellia_imperial_tier4_2",
	duty_recovery = "recovery_duty_corellia_imperial_tier4_3",
	duty_rescue = "rescue_duty_corellia_imperial_tier4_4"
}

-- Pre-NGE free choice of a tier 4 skill, one click: { skill, topic reply, default link }, in menu order.
-- Every topic links the first post-training brief; the grant routes by the reply text.
ninGursaweConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_04", "@conversation/corellia_imperial_tier4:s_c17d1a82", "m1_brief_trained" },
	{ "pilot_imperial_navy_weapons_04", "@conversation/corellia_imperial_tier4:s_6560cc1a", "m1_brief_trained" },
	{ "pilot_imperial_navy_procedures_04", "@conversation/corellia_imperial_tier4:s_bfe54df0", "m1_brief_trained" },
	{ "pilot_imperial_navy_droid_04", "@conversation/corellia_imperial_tier4:s_588da3c3", "m1_brief_trained" }
}

-- The briefing shown after training, by the mission that is next (mission 3 has no pre-NGE post-training variant)
ninGursaweConvoHandler.TRAINED_BRIEFS = { "m1_brief_trained", "m2_brief_trained", "m3_brief", "m4_brief_trained" }

-- Screens that start a mission (the head chain is started on display): screen -> mission number
ninGursaweConvoHandler.START_SCREENS = {
	m1_accept_a = 1, m1_accept_b = 1, m1_accept_c = 1, m1_accept_d = 1, m1_accept_e = 1, m1_accept_f = 1,
	m1_retry_a = 1, m1_retry_b = 1,
	m2_accept_a = 2, m2_accept_b = 2, m2_accept_c = 2, m2_accept_d = 2, m2_accept_e = 2, m2_accept_f = 2, m2_accept_g = 2,
	m2_retry_a = 2, m2_retry_b = 2,
	m3_accept = 3, m3_retry_a = 3, m3_retry_b = 3,
	m4_accept_a = 4, m4_accept_b = 4, m4_accept_c = 4, m4_retry = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
ninGursaweConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- The six ends of the introduction set the intro flag; the two Declann ends set the transfer flag
ninGursaweConvoHandler.INTRO_SCREENS = {
	intro_end_a = true, intro_end_b = true, intro_end_c = true, intro_end_d = true, intro_end_e = true, intro_end_f = true
}

ninGursaweConvoHandler.DECLANN_SCREENS = {
	transfer_done_a = true, transfer_done_b = true
}

function ninGursaweConvoHandler:getQuestString(n)
	return BlackEpsilonSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function ninGursaweConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- <playerID><key> is "1"
function ninGursaweConvoHandler:hasKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. key) == "1"
end

function ninGursaweConvoHandler:setKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. key, 1)
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function ninGursaweConvoHandler:isWon(pPlayer, n)
	local endString = BlackEpsilonSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function ninGursaweConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function ninGursaweConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function ninGursaweConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains or the four duties is running
function ninGursaweConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	for n = 1, 4 do
		local duty = BlackEpsilonSquadronScreenplay["TIER4_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, duty.type, duty.name)) then
			return true
		end
	end

	return false
end

-- SWG canFlyNonTrackDuty (corellia_imperial_tier4.java:247-254): all tier 3 skills and no quest
function ninGursaweConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The first mission that is not won (nil when all four are)
function ninGursaweConvoHandler:getNextMission(pPlayer)
	for n = 1, 4 do
		if (not self:isWon(pPlayer, n)) then
			return n
		end
	end

	return nil
end

-- SWG isReadyForMission, derived: the next mission when the pilot holds as many tier 4 skills as its number and has
-- not attempted it yet (nil if none)
function ninGursaweConvoHandler:getReadyMission(pPlayer)
	local n = self:getNextMission(pPlayer)

	if (n ~= nil and SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 4) >= n and not self:hasStatus(pPlayer, n, ":attempted")) then
		return n
	end

	return nil
end

-- SWG isReadyForTraining (corellia_imperial_tier4.java:68-75)
function ninGursaweConvoHandler:isReadyForTraining(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)
		and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 4) == true
		and self:getReadyMission(pPlayer) == nil
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function ninGursaweConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: a topic reply on ready_train buys the skill (1,000,000 XP) and shows the briefing of the
-- next mission. Any failed guard sends the pilot back through the gates, granting nothing.
function ninGursaweConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if ((self:getLastScreenID(pPlayer) or "") ~= "ready_train") then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	-- The skill is the one whose reply the pilot picked on the live (cloned) screen
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
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

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
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() <= 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)) then
			ghost:incrementPilotTier()
		end
	end

	local n = self:getNextMission(pPlayer)

	if (n == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(self.TRAINED_BRIEFS[n])
end

function ninGursaweConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
	-- The "wanted" gate: negative Imperial standing, before the track check
	elseif (ghost:getFactionStanding("imperial") < 0) then
		return convoTemplate:getScreen("wanted")
	elseif (not SpaceHelpers:isBlackEpsilonSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		return convoTemplate:getScreen("not_ready")
	end

	-- Pilot tier 4 on entry, 5 once tier 4 is complete
	if (ghost:getPilotTier() < 4) then
		ghost:incrementPilotTier()
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4) and ghost:getPilotTier() < 5) then
		ghost:incrementPilotTier()
	end

	if (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
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

	if (not self:hasKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_INTRO_KEY)) then
		return convoTemplate:getScreen("intro")
	elseif (self:getReadyMission(pPlayer) ~= nil) then
		return convoTemplate:getScreen("ready")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("ready_train")
	elseif (not self:hasKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_MET_KEY)) then
		return convoTemplate:getScreen("expecting")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)) then
		return convoTemplate:getScreen("tier4_incomplete")
	elseif (not SpaceHelpers:hasMasterSkill(pPlayer, "imperial_navy") and not self:hasKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_DECLANN_KEY)) then
		return convoTemplate:getScreen("transfer")
	end

	return convoTemplate:getScreen("here_for_work")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 150 Imperial standing
function ninGursaweConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 150)
end

function ninGursaweConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
	local duty = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		local playerID = CreatureObject(pPlayer):getObjectID()

		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (self.INTRO_SCREENS[screenID]) then
		self:setKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_INTRO_KEY)
	elseif (screenID == "briefing") then
		self:setKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_MET_KEY)
	elseif (self.DECLANN_SCREENS[screenID]) then
		self:setKey(pPlayer, BlackEpsilonSquadronScreenplay.TIER4_DECLANN_KEY)
	elseif (screenID == "ready_train") then
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
		-- C-2: off-track pilots may fly a duty (corellia_imperial_tier4.java:247-254)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_tier4:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_duty")
	elseif (screenID == "ready") then
		-- C-3: the briefing of the mission that is ready
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_tier4:s_36a4e374", "m" .. (self:getReadyMission(pPlayer) or 1) .. "_brief")
	end

	return pClonedScreen
end
