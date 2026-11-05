-- Lt. Barn Sinkko (Inquisition tier 1) conversation handler; ported from SWG-Source naboo_imperial_trainer_1.java. Training, grounded gate and ground-forces branch: pre-NGE client lines (feature inquisition-tier1-barn-sinkko).
local SpaceHelpers = require("utils.space_helpers")

barnSinkkoConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the next skill: { skill, topic reply, description screen, trained screen }, in SWG order
barnSinkkoConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_01", "@conversation/naboo_imperial_trainer_1:s_5e3cf461", "train_starships", "trained_starships" },
	{ "pilot_imperial_navy_weapons_01", "@conversation/naboo_imperial_trainer_1:s_527c6359", "train_weapons", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_01", "@conversation/naboo_imperial_trainer_1:s_40f3848e", "train_procedures", "trained_procedures" },
	{ "pilot_imperial_navy_droid_01", "@conversation/naboo_imperial_trainer_1:s_a57e647c", "train_droid", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
barnSinkkoConvoHandler.START_SCREENS = {
	mission1_accept = 1, mission1_accept_sloppy = 1, mission1_accept_orders = 1, mission1_retry = 1,
	mission2_accept = 2, mission2_accept_pay = 2, mission2_accept_cocky = 2, mission2_retry = 2, mission2_aborted_retry = 2,
	mission3_accept = 3, mission3_accept_credits = 3, mission3_accept_priority = 3, mission3_retry = 3,
	mission4_accept = 4, mission4_accept_mind = 4, mission4_retry = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
barnSinkkoConvoHandler.REWARD_SCREENS = {
	mission1_pay_wing = 1, mission1_pay_money = 1, mission1_pay_sure = 1,
	mission2_pay_honored = 2, mission2_pay_philosophy = 2, mission2_pay_combat = 2,
	mission3_pay = 3, mission3_pay_bandolier = 3, mission3_credited = 3, mission3_credited_bandolier = 3, mission3_army = 3, mission3_army_bandolier = 3,
	mission4_pay_head = 4, mission4_pay = 4, mission4_pay_bold = 4, mission4_sneer_head = 4, mission4_sneer = 4
}

-- Per mission: head quest global, Imperial standing paid with the reward
barnSinkkoConvoHandler.MISSIONS = {
	{ head = "patrol_naboo_imperial_1", standing = 25 },
	{ head = "destroy_naboo_imperial_2", standing = 50 },
	{ head = "patrol_naboo_imperial_3", standing = 50 },
	{ head = "assassinate_naboo_imperial_4", standing = 75 }
}

-- Conditional links: screen -> { reply, link when the test holds, link otherwise, test }
barnSinkkoConvoHandler.CONDITIONAL_LINKS = {
	non_member = { "@conversation/naboo_imperial_trainer_1:s_4854758d", "non_member_duty_offer", "non_member_no_missions", "canFlyNonTrackDuty" },
	mission3_solved = { "@conversation/naboo_imperial_trainer_1:s_30e39201", "mission3_pay_bandolier", "mission3_pay", "isWookieeOrIthorian" },
	mission3_payment_wait = { "@conversation/naboo_imperial_trainer_1:s_cb0c70a2", "mission3_credited_bandolier", "mission3_credited", "isWookieeOrIthorian" },
	mission3_intellect = { "@conversation/naboo_imperial_trainer_1:s_f02428e4", "mission3_army_bandolier", "mission3_army", "isWookieeOrIthorian" },
	mission4_masterful = { "@conversation/naboo_imperial_trainer_1:s_d09c1ecb", "mission4_pay_head", "mission4_pay", "hasWeirdHead" },
	mission4_asset = { "@conversation/naboo_imperial_trainer_1:s_c01da9e4", "mission4_sneer_head", "mission4_sneer", "hasWeirdHead" },
	mission4_impressive = { "@conversation/naboo_imperial_trainer_1:s_ce681825", "mission4_pay_head", "mission4_pay_bold", "hasWeirdHead" }
}

-- Any of Barn's story chains or duties is running (the journal checks of the SWG isOnMission)
function barnSinkkoConvoHandler:isOnMission(pPlayer)
	local IS = InquisitionSquadronScreenplay

	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_imperial_1")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_imperial_2")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_imperial_3")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_imperial_4")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, IS.QUEST_STRING_DUTY_1.type, IS.QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, IS.QUEST_STRING_DUTY_2.type, IS.QUEST_STRING_DUTY_2.name)
end

-- SWG canFlyNonTrackDuty (naboo_imperial_trainer_1.java:297-304): any tier 1 skill and no quest
function barnSinkkoConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- SWG readyForSecondSkill, with the mission 4 reward and an unfinished tier: the pilot can be trained now
function barnSinkkoConvoHandler:isReadyForTraining(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (getQuestStatus(playerID .. InquisitionSquadronScreenplay.QUEST_STRING_4.name .. ":reward") ~= "1") then
		return false
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)) then
		return false
	end

	return not SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1) or SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true
end

-- naboo_imperial_trainer_1.java:314-322
function barnSinkkoConvoHandler:hasWeirdHead(pPlayer)
	local species = CreatureObject(pPlayer):getSpecies()

	return species ~= SPECIES_HUMAN and species ~= SPECIES_ZABRAK
end

-- naboo_imperial_trainer_1.java:305-309
function barnSinkkoConvoHandler:isWookieeOrIthorian(pPlayer)
	local species = CreatureObject(pPlayer):getSpecies()

	return species == SPECIES_WOOKIEE or species == SPECIES_ITHORIAN
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function barnSinkkoConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE two-step training: the confirm chosen on a topic description (train_<x> -> trained_<x>) grants the skill. The first
-- tier 1 skill is free, later ones are bought. Any failed guard sends the pilot back through the gates.
function barnSinkkoConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""
	local choice = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry[3] == lastScreen) then
			choice = entry
		end
	end

	if (choice == nil) then
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

	if (link ~= choice[4]) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	local skill = choice[1]

	if (CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	if (not SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1)) then
		-- The first skill is free
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, false)
	elseif (LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 1
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() == 1 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)) then
			ghost:incrementPilotTier()
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows naboo_imperial_trainer_1.java OnStartNpcConversation (:8554 on)
function barnSinkkoConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("no_jtl")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local standing = ghost:getFactionStanding("imperial")
	local isImperialPilot = SpaceHelpers:isImperialPilot(pPlayer)
	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)

	local IS = InquisitionSquadronScreenplay

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	local function status(key)
		return getQuestStatus(key) == "1"
	end

	local active = {
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_imperial_1"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_imperial_2"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_imperial_3"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_imperial_4")
	}

	local won = {
		complete(IS.QUEST_STRING_1) and complete(IS.QUEST_STRING_1_SIDE),
		complete(IS.QUEST_STRING_2),
		complete(IS.QUEST_STRING_3) and complete(IS.QUEST_STRING_3_SIDE),
		complete(IS.QUEST_STRING_4)
	}

	local questStrings = { IS.QUEST_STRING_1, IS.QUEST_STRING_2, IS.QUEST_STRING_3, IS.QUEST_STRING_4 }
	local reward, failed = {}, {}

	for n = 1, 4 do
		reward[n] = status(playerID .. questStrings[n].name .. ":reward")
		failed[n] = status(playerID .. questStrings[n].name .. ":attempted") and not won[n] and not active[n]
	end

	local aborted2 = status(playerID .. IS.QUEST_STRING_2.name .. ":aborted")
	local series = status(playerID .. IS.SERIES_COMPLETE_KEY)
	local agent = status(playerID .. IS.INQUISITORIAL_AGENT_KEY)

	-- Help loop while mission 1 is running
	if (hasShip and active[1]) then
		return convoTemplate:getScreen("first_mission_help")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("neutral_pilot")
	elseif (faction == FACTIONREBEL or SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	-- Imperials only: a pilot without the Imperial faction is grounded, anyone else is turned away
	elseif (faction ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen(isImperialPilot and "grounded" or "not_imperial")
	elseif (isImperialPilot and not SpaceHelpers:isInquisitionSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_member")
	-- Lost the starter ship
	elseif (isImperialPilot and not hasShip) then
		return convoTemplate:getScreen("lost_ship")
	-- Pre-NGE gate: an Inquisition pilot who turned against the Empire
	elseif (isImperialPilot and standing < 0) then
		return convoTemplate:getScreen("grounded")
	elseif (series and not agent) then
		return convoTemplate:getScreen("working_for_fazoll")
	elseif (isImperialPilot and (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer))) then
		return convoTemplate:getScreen("on_mission")
	elseif (series) then
		return convoTemplate:getScreen("series_complete")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and reward[4]) then
		return convoTemplate:getScreen("tier_done")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (reward[4]) then
		return convoTemplate:getScreen("duty_missions")
	-- Missions: won (reward due), failed or aborted, next one to offer
	elseif (won[4]) then
		return convoTemplate:getScreen("mission4_won")
	elseif (failed[4]) then
		return convoTemplate:getScreen("mission4_failed")
	elseif (reward[3]) then
		return convoTemplate:getScreen("mission4_offer")
	elseif (won[3]) then
		return convoTemplate:getScreen("mission3_won")
	elseif (failed[3]) then
		return convoTemplate:getScreen("mission3_failed")
	elseif (reward[2]) then
		return convoTemplate:getScreen("mission3_offer")
	elseif (won[2]) then
		return convoTemplate:getScreen("mission2_won")
	elseif (aborted2) then
		return convoTemplate:getScreen("mission2_aborted")
	elseif (failed[2]) then
		return convoTemplate:getScreen("mission2_failed")
	elseif (reward[1]) then
		return convoTemplate:getScreen("mission2_offer")
	elseif (won[1]) then
		return convoTemplate:getScreen("mission1_won")
	elseif (failed[1]) then
		return convoTemplate:getScreen("mission1_failed")
	elseif (isImperialPilot) then
		return convoTemplate:getScreen("mission1_offer")
	end

	return convoTemplate:getScreen("recruitment")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Imperial standing
function barnSinkkoConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. InquisitionSquadronScreenplay["QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", self.MISSIONS[n].standing)
end

-- The sign-up: novice box, squadron, pilot tier 1 (naboo_imperial_trainer_1.java:349-355)
function barnSinkkoConvoHandler:signUp(pPlayer, ghost)
	SpaceHelpers:grantNovicePilot(pPlayer, "imperialPilot")
	SpaceHelpers:setSquadronType(pPlayer, INQUISITION_SQUADRON)

	if (ghost:getPilotTier() < 1) then
		ghost:incrementPilotTier()
	end
end

function barnSinkkoConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
	local conditional = self.CONDITIONAL_LINKS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		if (startMission == 2) then
			removeQuestStatus(playerID .. IS.QUEST_STRING_2.name .. ":aborted")
		end

		setQuestStatus(playerID .. IS["QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (conditional ~= nil) then
		-- C-1, C-3 .. C-8
		clonedConversation:removeAllOptions()
		clonedConversation:addOption(conditional[1], self[conditional[4]](self, pPlayer) and conditional[2] or conditional[3])
	elseif (screenID == "recruit_sworn" or screenID == "recruit_sworn_pay") then
		self:signUp(pPlayer, ghost)

		-- C-2
		clonedConversation:removeAllOptions()
		clonedConversation:addOption(screenID == "recruit_sworn" and "@conversation/naboo_imperial_trainer_1:s_987445c9" or "@conversation/naboo_imperial_trainer_1:s_f774e399", SpaceHelpers:hasCertifiedShip(pPlayer, true) and "first_assignment" or "recruit_ship_granted")
	elseif (screenID == "recruit_ship_granted" or screenID == "lost_ship_granted") then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "imperial")
		end
	elseif (screenID == "training_menu") then
		-- Every skill the pilot lacks (pre-NGE topic menu)
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/naboo_imperial_trainer_1:s_dc63dc1a", "training_never_mind")
	elseif (screenID == "destroy_duty") then
		destroy_duty_naboo_imperial_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_naboo_imperial_7:startQuest(pPlayer, pNpc)
	elseif (screenID == "promotion" or screenID == "promotion_reassigned" or screenID == "promotion_overdue") then
		setQuestStatus(playerID .. IS.SERIES_COMPLETE_KEY, 1)
	end

	return pClonedScreen
end
