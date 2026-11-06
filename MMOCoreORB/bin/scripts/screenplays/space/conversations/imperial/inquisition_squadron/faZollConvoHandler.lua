-- Inquisitor Fa'Zoll (Inquisition tier 2) conversation handler; ported from SWG-Source naboo_imperial_trainer_2.java. Training and grounded gate: pre-NGE client lines (feature inquisition-tier2-fa-zoll).
local SpaceHelpers = require("utils.space_helpers")

faZollConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the tier 2 skills: { skill, topic reply, trained screen }, in SWG order. A topic buys the skill at once
faZollConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_02", "@conversation/naboo_imperial_trainer_2:s_594a07fa", "trained_starships" },
	{ "pilot_imperial_navy_weapons_02", "@conversation/naboo_imperial_trainer_2:s_be30f309", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_02", "@conversation/naboo_imperial_trainer_2:s_e73e5d21", "trained_procedures" },
	{ "pilot_imperial_navy_droid_02", "@conversation/naboo_imperial_trainer_2:s_c76594d7", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
faZollConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry = 1,
	m2_accept = 2, m2_retry = 2,
	m3_accept = 3, m3_retry = 3,
	m4_accept = 4, m4_retry = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
faZollConvoHandler.REWARD_SCREENS = {
	m1_pay = 1, m2_pay = 2, m3_pay = 3, m4_pay = 4
}

-- Per mission: head quest global, Imperial standing paid with the reward
faZollConvoHandler.MISSIONS = {
	{ head = "inspect_naboo_imperial_tier2_1", standing = 75 },
	{ head = "survival_naboo_imperial_tier2_2", standing = 75 },
	{ head = "recovery_naboo_imperial_tier2_3", standing = 75 },
	{ head = "assassinate_naboo_imperial_tier2_4", standing = 75 }
}

-- Screens that hand out a duty: screen -> duty quest global
faZollConvoHandler.DUTY_SCREENS = {
	duty_police = "recovery_duty_naboo_imperial_tier2_recoveryduty",
	duty_escort = "escort_duty_naboo_imperial_tier2_escortduty",
	duty_insurgents = "destroy_duty_naboo_imperial_tier2_destroyduty"
}

local GREETING_SCREENS = { greeting = true, inquisition_duties = true, rebellion_info = true }

-- Any of Fa'Zoll's story chains or duties is running (the journal checks of the SWG isOnMission)
function faZollConvoHandler:isOnMission(pPlayer)
	local IS = InquisitionSquadronScreenplay

	for _, mission in ipairs(self.MISSIONS) do
		if (SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)) then
			return true
		end
	end

	return SpaceHelpers:isSpaceQuestActive(pPlayer, IS.TIER2_QUEST_STRING_DUTY_1.type, IS.TIER2_QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, IS.TIER2_QUEST_STRING_DUTY_2.type, IS.TIER2_QUEST_STRING_DUTY_2.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, IS.TIER2_QUEST_STRING_DUTY_3.type, IS.TIER2_QUEST_STRING_DUTY_3.name)
end

-- SWG canFlyNonTrackDuty (naboo_imperial_trainer_2.java:24-31): all of tier 1 and no quest
function faZollConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

function faZollConvoHandler:hasCompletedTierTwo(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)
end

function faZollConvoHandler:isPaid(pPlayer, n)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. InquisitionSquadronScreenplay["TIER2_QUEST_STRING_" .. n].name .. ":reward") == "1"
end

-- SWG isReadyForTraining: mission 2 paid and XP; before mission 3 is paid the pilot holds at most one tier 2 skill
function faZollConvoHandler:isReadyForTraining(pPlayer)
	if (not self:isPaid(pPlayer, 2)) then
		return false
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) or self:hasCompletedTierTwo(pPlayer)) then
		return false
	end

	if (SpaceHelpers:hasExperienceForTraining(pPlayer, 2) ~= true) then
		return false
	end

	return self:isPaid(pPlayer, 3) or SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 2) == 0
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function faZollConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: the topic chosen on the training menu buys the skill. Any failed guard sends the pilot back through the gates.
function faZollConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""

	if (lastScreen ~= "training_menu" and lastScreen ~= "m4_more_training") then
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

	if (CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	if (LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 2
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() == 2 and self:hasCompletedTierTwo(pPlayer)) then
			ghost:incrementPilotTier()
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows naboo_imperial_trainer_2.java OnStartNpcConversation (:4310 on)
function faZollConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

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

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()
	local standing = ghost:getFactionStanding("imperial")
	local IS = InquisitionSquadronScreenplay

	local function status(key)
		return getQuestStatus(key) == "1"
	end

	local won, active, paid, failed = {}, {}, {}, {}

	for n = 1, 4 do
		local questString = IS["TIER2_QUEST_STRING_" .. n]

		won[n] = SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
		active[n] = SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
		paid[n] = status(playerID .. questString.name .. ":reward")
		failed[n] = status(playerID .. questString.name .. ":attempted") and not won[n] and not active[n]
	end

	local tier2done = self:hasCompletedTierTwo(pPlayer)
	local anyTier2 = SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 2) > 0

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (faction == FACTIONREBEL or SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	-- Imperials only: negative standing or a lost Imperial faction is grounded
	elseif (standing < 0 or faction ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen("wanted")
	elseif (not SpaceHelpers:isInquisitionSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (tier2done and paid[4]) then
		return convoTemplate:getScreen("report_to_vrke")
	elseif (won[4]) then
		return convoTemplate:getScreen("m4_won")
	elseif (failed[4]) then
		return convoTemplate:getScreen("m4_failed")
	elseif (tier2done and paid[3]) then
		return convoTemplate:getScreen("m4_offer")
	elseif (paid[3]) then
		return convoTemplate:getScreen("duty_after_m3")
	elseif (won[3]) then
		return convoTemplate:getScreen("m3_won")
	elseif (failed[3]) then
		return convoTemplate:getScreen("m3_failed")
	elseif (anyTier2 and paid[2]) then
		return convoTemplate:getScreen("m3_offer")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (paid[2]) then
		return convoTemplate:getScreen("duty_after_m2")
	elseif (won[2]) then
		return convoTemplate:getScreen("m2_won")
	elseif (failed[2]) then
		return convoTemplate:getScreen("m2_failed")
	elseif (paid[1]) then
		return convoTemplate:getScreen("m2_offer")
	elseif (won[1]) then
		return convoTemplate:getScreen("m1_won")
	elseif (failed[1]) then
		return convoTemplate:getScreen("m1_failed")
	elseif (status(playerID .. IS.INQUISITORIAL_AGENT_KEY)) then
		return convoTemplate:getScreen("m1_offer")
	end

	return convoTemplate:getScreen("greeting")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Imperial standing
function faZollConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. InquisitionSquadronScreenplay["TIER2_QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", self.MISSIONS[n].standing)
end

-- The training menu: every tier 2 skill the pilot lacks, then "let me think about this"
function faZollConvoHandler:addTrainingOptions(pPlayer, conversation)
	conversation:removeAllOptions()

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
			conversation:addOption(entry[2], entry[3])
		end
	end

	conversation:addOption("@conversation/naboo_imperial_trainer_2:s_ae26c22", "training_later")
end

function faZollConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()
	local IS = InquisitionSquadronScreenplay

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
		setQuestStatus(playerID .. IS["TIER2_QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (screenID == "sign_up_agent") then
		-- SWG makeInquisitorialAgent
		setQuestStatus(playerID .. IS.INQUISITORIAL_AGENT_KEY, 1)
	elseif (screenID == "off_track") then
		-- C-1
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions")
	elseif (GREETING_SCREENS[screenID]) then
		-- C-2: the sign-up needs Barn's promotion
		local signUp = getQuestStatus(playerID .. IS.SERIES_COMPLETE_KEY) == "1" and "sign_up" or "not_recruiting"

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_6396820e", "inquisition_info")
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_3ce84ec1", "rebellion_info")
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_696a6a00", signUp)
	elseif (screenID == "m4_won") then
		-- C-3
		clonedConversation:removeAllOptions()

		if (self:hasCompletedTierTwo(pPlayer)) then
			clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_97d51490", "m4_pay")
		else
			clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_c104d444", "m4_more_training")
		end
	elseif (screenID == "duty_menu") then
		-- C-4: only the Inquisition trains here
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_e84f3a62", "duty_police")
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_e6765c30", "duty_escort")
		clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_f0a7a4ef", "duty_insurgents")

		if (SpaceHelpers:isInquisitionSquadron(pPlayer)) then
			clonedConversation:addOption("@conversation/naboo_imperial_trainer_2:s_b0d3b474", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready")
		end
	elseif (screenID == "training_menu" or screenID == "m4_more_training") then
		-- C-5
		self:addTrainingOptions(pPlayer, clonedConversation)
	end

	return pClonedScreen
end
