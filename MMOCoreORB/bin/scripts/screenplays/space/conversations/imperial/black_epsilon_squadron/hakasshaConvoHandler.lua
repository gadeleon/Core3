-- Hakassha Sireen (Black Epsilon tier 1) conversation handler; ported from SWG-Source corellia_imperial_trainer_1.java. Training and grounded gate: pre-NGE client lines (feature black-epsilon-tier1-hakassha).
local SpaceHelpers = require("utils.space_helpers")

hakasshaConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the next skill: { skill, topic reply, description screen, trained screen }, in SWG order
hakasshaConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_01", "@conversation/corellia_imperial_trainer_1:s_5e3cf461", "train_starships", "trained_starships" },
	{ "pilot_imperial_navy_weapons_01", "@conversation/corellia_imperial_trainer_1:s_577aca95", "train_weapons", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_01", "@conversation/corellia_imperial_trainer_1:s_fb13007f", "train_procedures", "trained_procedures" },
	{ "pilot_imperial_navy_droid_01", "@conversation/corellia_imperial_trainer_1:s_a57e647c", "train_droid", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
hakasshaConvoHandler.START_SCREENS = {
	mission1_accept = 1, mission1_retry = 1,
	mission2_accept = 2, mission2_retry = 2,
	mission3_accept = 3, mission3_accept_no_choice = 3, mission3_retry = 3,
	mission4_accept = 4, mission4_retry = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
hakasshaConvoHandler.REWARD_SCREENS = {
	mission1_won = 1,
	mission2_reward = 2, mission2_reward_pay = 2,
	mission3_reward = 3, mission3_reward_bandolier = 3,
	mission4_reward_head = 4, mission4_reward = 4, mission4_pay_head = 4, mission4_pay = 4
}

-- Per mission: head quest global, Imperial standing paid with the reward
hakasshaConvoHandler.MISSIONS = {
	{ head = "patrol_corellia_imperial_1", standing = 25 },
	{ head = "destroy_corellia_imperial_2", standing = 50 },
	{ head = "escort_corellia_imperial_3", standing = 50 },
	{ head = "assassinate_corellia_imperial_4", standing = 75 }
}

-- Any of Hakassha's story chains or duties is running (the journal checks of the SWG isOnMission)
function hakasshaConvoHandler:isOnMission(pPlayer)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_corellia_imperial_1")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_corellia_imperial_2")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "escort_corellia_imperial_3")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_corellia_imperial_4")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, BlackEpsilonSquadronScreenplay.QUEST_STRING_DUTY_1.type, BlackEpsilonSquadronScreenplay.QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, BlackEpsilonSquadronScreenplay.QUEST_STRING_DUTY_2.type, BlackEpsilonSquadronScreenplay.QUEST_STRING_DUTY_2.name)
end

-- SWG canFlyNonTrackDuty (corellia_imperial_trainer_1.java:344-351): any tier 1 skill and no quest
function hakasshaConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- SWG readyForSecondSkill, with the mission 4 reward and an unfinished tier: the pilot can be trained now
function hakasshaConvoHandler:isReadyForTraining(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (getQuestStatus(playerID .. BlackEpsilonSquadronScreenplay.QUEST_STRING_4.name .. ":reward") ~= "1") then
		return false
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)) then
		return false
	end

	return not SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1) or SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true
end

-- corellia_imperial_trainer_1.java:361-369
function hakasshaConvoHandler:hasWeirdHead(pPlayer)
	local species = CreatureObject(pPlayer):getSpecies()

	return species ~= SPECIES_HUMAN and species ~= SPECIES_ZABRAK
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function hakasshaConvoHandler:getLastScreenID(pPlayer)
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
function hakasshaConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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

function hakasshaConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	local function status(questString, suffix)
		return getQuestStatus(playerID .. questString.name .. suffix) == "1"
	end

	local BE = BlackEpsilonSquadronScreenplay

	local active = {
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_corellia_imperial_1"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_corellia_imperial_2"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "escort_corellia_imperial_3"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_corellia_imperial_4")
	}

	local won = {
		complete(BE.QUEST_STRING_1) and complete(BE.QUEST_STRING_1_SIDE),
		complete(BE.QUEST_STRING_2),
		complete(BE.QUEST_STRING_3),
		complete(BE.QUEST_STRING_4)
	}

	local questStrings = { BE.QUEST_STRING_1, BE.QUEST_STRING_2, BE.QUEST_STRING_3, BE.QUEST_STRING_4 }
	local reward, failed = {}, {}

	for n = 1, 4 do
		reward[n] = status(questStrings[n], ":reward")
		failed[n] = status(questStrings[n], ":attempted") and not won[n] and not active[n]
	end

	-- Help loop while mission 1 is running
	if (hasShip and active[1]) then
		return convoTemplate:getScreen("first_mission_help")
	-- Rebel faction, rebel pilot or an openly hostile non-pilot
	elseif (faction == FACTIONREBEL or (not isImperialPilot and standing < 0) or SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("neutral_pilot")
	-- Lost the starter ship
	elseif (isImperialPilot and not hasShip) then
		return convoTemplate:getScreen("lost_ship")
	elseif (faction ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen("not_imperial")
	elseif (isImperialPilot and not SpaceHelpers:isBlackEpsilonSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_member")
	-- Pre-NGE gate: a Black Epsilon pilot who turned against the Empire
	elseif (isImperialPilot and standing < 0) then
		return convoTemplate:getScreen("grounded")
	elseif (getQuestStatus(playerID .. BE.WORKING_FOR_PRISK_KEY) == "1") then
		return convoTemplate:getScreen("working_for_prisk")
	elseif (isImperialPilot and (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer))) then
		return convoTemplate:getScreen("on_mission")
	elseif (getQuestStatus(playerID .. BE.SERIES_COMPLETE_KEY) == "1") then
		return convoTemplate:getScreen("series_complete")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and reward[4]) then
		return convoTemplate:getScreen("tier_done")
	elseif (reward[4] and (not SpaceHelpers:hasPilotTierSkill(pPlayer, "imperial_navy", 1) or SpaceHelpers:hasExperienceForTraining(pPlayer, 1))) then
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
function hakasshaConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. BlackEpsilonSquadronScreenplay["QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", self.MISSIONS[n].standing)
end

function hakasshaConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
		setQuestStatus(playerID .. BlackEpsilonSquadronScreenplay["QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (screenID == "non_member") then
		-- C-1: off-track pilots may fly a duty (corellia_imperial_trainer_1.java:2350-2400)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_29e5ec7", self:canFlyNonTrackDuty(pPlayer) and "non_member_duty_offer" or "non_member_no_missions")
	elseif (screenID == "recruit_sworn") then
		-- Sign-up: novice box, squadron, tier 1 (corellia_imperial_trainer_1.java:405-411)
		SpaceHelpers:grantNovicePilot(pPlayer, "imperialPilot")
		SpaceHelpers:setSquadronType(pPlayer, BLACK_EPSILON_SQUADRON)

		if (ghost:getPilotTier() < 1) then
			ghost:incrementPilotTier()
		end

		-- C-2
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_4ecd165f", SpaceHelpers:hasCertifiedShip(pPlayer, true) and "recruit_has_ship" or "recruit_ship_granted")
	elseif (screenID == "recruit_ship_granted" or screenID == "lost_ship_granted") then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "imperial")
		end
	elseif (screenID == "training_offer") then
		-- C-3
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_19ff301f", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready")
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_710daa61", "training_declined")
	elseif (screenID == "training_menu") then
		-- Every skill the pilot lacks (pre-NGE topic menu instead of corellia_imperial_trainer_1.java:2655-2900)
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_dc63dc1a", "training_never_mind")
	elseif (screenID == "mission4_won_close") then
		-- C-4
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_15799d85", self:hasWeirdHead(pPlayer) and "mission4_reward_head" or "mission4_reward")
	elseif (screenID == "mission4_won_toast") then
		-- C-5
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_659a2365", self:hasWeirdHead(pPlayer) and "mission4_pay_head" or "mission4_pay")
	elseif (screenID == "mission3_casualties") then
		-- C-6
		local species = CreatureObject(pPlayer):getSpecies()

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_1:s_34ac7110", (species == SPECIES_WOOKIEE or species == SPECIES_ITHORIAN) and "mission3_reward_bandolier" or "mission3_reward")
	elseif (screenID == "destroy_duty") then
		destroy_duty_corellia_imperial_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_corellia_imperial_7:startQuest(pPlayer, pNpc)
	elseif (screenID == "promotion") then
		setQuestStatus(playerID .. BlackEpsilonSquadronScreenplay.SERIES_COMPLETE_KEY, 1)
	elseif (screenID == "transfer_to_prisk") then
		setQuestStatus(playerID .. BlackEpsilonSquadronScreenplay.WORKING_FOR_PRISK_KEY, 1)
	end

	return pClonedScreen
end
