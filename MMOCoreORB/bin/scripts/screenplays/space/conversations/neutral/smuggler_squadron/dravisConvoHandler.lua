-- Dravis (Smuggler tier 1) conversation handler; ported from SWG-Source tatooine_privateer_trainer_1.java. Training and the "I got a ship." reply: pre-NGE client lines (feature smuggler-tier1-dravis).
local SpaceHelpers = require("utils.space_helpers")

dravisConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the next skill: { skill, topic reply, closing screen }, in SWG order
dravisConvoHandler.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_01", "@conversation/tatooine_privateer_trainer_1:s_3818dc2a", "trained_starships" },
	{ "pilot_neutral_weapons_01", "@conversation/tatooine_privateer_trainer_1:s_3fa70900", "trained_weapons" },
	{ "pilot_neutral_procedures_01", "@conversation/tatooine_privateer_trainer_1:s_7d57477f", "trained_procedures" },
	{ "pilot_neutral_droid_01", "@conversation/tatooine_privateer_trainer_1:s_9480f430", "trained_droid" }
}

-- Per story mission: the head quest global that is started and paid
dravisConvoHandler.MISSION_HEADS = {
	"patrol_tatooine_privateer_1",
	"destroy_tatooine_privateer_2",
	"patrol_tatooine_privateer_3",
	"assassinate_tatooine_privateer_tier1_4a"
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
dravisConvoHandler.START_SCREENS = {
	mission1_brief = 1, mission1_accept = 1, mission1_retry = 1,
	mission2_accept = 2, mission2_retry = 2,
	mission3_accept = 3, mission3_retry = 3,
	mission4_accept = 4, mission4_retry = 4
}

-- Reward screens: screen -> mission number
dravisConvoHandler.REWARD_SCREENS = {
	mission1_reward = 1,
	mission2_reward = 2,
	mission3_reward = 3,
	mission4_reward = 4
}

-- The two replies of each reward screen (FS-1: both lead back into the gates)
dravisConvoHandler.REWARD_REPLIES = {
	{ "@conversation/tatooine_privateer_trainer_1:s_676c343f", "@conversation/tatooine_privateer_trainer_1:s_ff2a95e8" },
	{ "@conversation/tatooine_privateer_trainer_1:s_b9b27823", "@conversation/tatooine_privateer_trainer_1:s_d0cc72e0" },
	{ "@conversation/tatooine_privateer_trainer_1:s_98d00f66", "@conversation/tatooine_privateer_trainer_1:s_60225cc9" },
	{ "@conversation/tatooine_privateer_trainer_1:s_fc27931b", "@conversation/tatooine_privateer_trainer_1:s_481c3940" }
}

-- Any of Dravis's story chains or duties is running (the journal checks of the SWG isOnMission)
function dravisConvoHandler:isOnMission(pPlayer)
	local SSP = SmugglerSquadronScreenplay

	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_privateer_1")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_tatooine_privateer_2")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_privateer_3")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_tatooine_privateer_tier1_4a")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, SSP.QUEST_STRING_DUTY_1.type, SSP.QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, SSP.QUEST_STRING_DUTY_2.type, SSP.QUEST_STRING_DUTY_2.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, SSP.QUEST_STRING_DUTY_3.type, SSP.QUEST_STRING_DUTY_3.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, SSP.QUEST_STRING_DUTY_4.type, SSP.QUEST_STRING_DUTY_4.name)
end

-- SWG canFlyNonTrackDuty (tatooine_privateer_trainer_1.java:166-173): any tier 1 skill and no quest
function dravisConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasPilotTierSkill(pPlayer, "neutral", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- tatooine_privateer_trainer_1.java:60-70
function dravisConvoHandler:isReadyForFirstTraining(pPlayer)
	return not SpaceHelpers:hasPilotTierSkill(pPlayer, "neutral", 1)
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function dravisConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: the choice made on first_training grants that skill free, the choice made on
-- more_training buys it (once). The skill is read from the link of the chosen option.
function dravisConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""

	if (lastScreen ~= "first_training" and lastScreen ~= "more_training") then
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

	for _, choice in ipairs(self.TRAIN_CHOICES) do
		if (choice[3] == link) then
			skill = choice[1]
		end
	end

	if (skill == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	local had = CreatureObject(pPlayer):hasSkill(skill)

	if (lastScreen == "first_training") then
		if (self:isReadyForFirstTraining(pPlayer)) then
			SpaceHelpers:grantSpaceSkill(pPlayer, skill, false)
		end
	elseif (not had and SpaceHelpers:hasExperienceForTraining(pPlayer, 1) and LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	-- The fourth skill completes tier 1
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() == 1 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1)) then
			ghost:incrementPilotTier()
		end
	end

	if (not had and CreatureObject(pPlayer):hasSkill(skill)) then
		return LuaConversationTemplate(pConvTemplate):getScreen(link)
	end

	return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
end

-- Side-effect free: the reward screens call it after paying (FS-1)
function dravisConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local playerID = CreatureObject(pPlayer):getObjectID()
	local SSP = SmugglerSquadronScreenplay

	-- JTL is disabled, or no player object
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

	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	local function status(questString, suffix)
		return getQuestStatus(playerID .. questString.name .. suffix) == "1"
	end

	local active = {}

	for n = 1, 4 do
		active[n] = SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSION_HEADS[n])
	end

	local won = {
		complete(SSP.QUEST_STRING_1) and complete(SSP.QUEST_STRING_1_SIDE),
		complete(SSP.QUEST_STRING_2),
		complete(SSP.QUEST_STRING_3) and complete(SSP.QUEST_STRING_3_SIDE),
		complete(SSP.QUEST_STRING_4)
	}

	local questStrings = { SSP.QUEST_STRING_1, SSP.QUEST_STRING_2, SSP.QUEST_STRING_3, SSP.QUEST_STRING_4 }
	local reward, failed = {}, {}

	for n = 1, 4 do
		reward[n] = status(questStrings[n], ":reward")
		failed[n] = status(questStrings[n], ":attempted") and not won[n] and not active[n]
	end

	if (hasShip and active[1]) then
		return convoTemplate:getScreen("first_mission_help")
	elseif (SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	elseif (SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer) and not SpaceHelpers:isSmugglerSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_member")
	elseif (not SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("recruitment")
	elseif (not hasShip) then
		return convoTemplate:getScreen("lost_ship")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (failed[1]) then
		return convoTemplate:getScreen("mission1_retry")
	elseif (failed[2]) then
		return convoTemplate:getScreen("mission2_retry")
	elseif (failed[3]) then
		return convoTemplate:getScreen("mission3_retry")
	elseif (failed[4]) then
		return convoTemplate:getScreen("mission4_retry")
	elseif (won[1] and not reward[1]) then
		return convoTemplate:getScreen("mission1_reward")
	elseif (not won[1]) then
		return convoTemplate:getScreen("mission1_offer")
	elseif (won[2] and not reward[2]) then
		return convoTemplate:getScreen("mission2_reward")
	elseif (not won[2]) then
		return convoTemplate:getScreen("mission2_offer")
	elseif (won[3] and not reward[3]) then
		return convoTemplate:getScreen("mission3_reward")
	elseif (not won[3]) then
		return convoTemplate:getScreen("mission3_offer")
	elseif (won[4] and not reward[4]) then
		return convoTemplate:getScreen("mission4_reward")
	elseif (not won[4]) then
		return convoTemplate:getScreen("mission4_offer")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1)) then
		return convoTemplate:getScreen("tier_done")
	elseif (self:isReadyForFirstTraining(pPlayer)) then
		return convoTemplate:getScreen("first_training")
	elseif (SpaceHelpers:hasExperienceForTraining(pPlayer, 1)) then
		return convoTemplate:getScreen("more_training")
	end

	return convoTemplate:getScreen("duty_missions")
end

-- Pays the reward of mission n once: the :reward key, then the head's credits and item
function dravisConvoHandler:payMission(pPlayer, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. SmugglerSquadronScreenplay["QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSION_HEADS[n]]:rewardPlayer(pPlayer)
end

function dravisConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
		setQuestStatus(playerID .. SmugglerSquadronScreenplay["QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSION_HEADS[startMission])
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward), then C-3: every reply goes where the gates now lead
		self:payMission(pPlayer, rewardMission)

		local pNext = self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		local nextID = pNext ~= nil and LuaConversationScreen(pNext):getScreenID() or "no_jtl"
		local replies = self.REWARD_REPLIES[rewardMission]

		clonedConversation:removeAllOptions()
		clonedConversation:addOption(replies[1], nextID)

		if (rewardMission ~= 4 or self:isReadyForFirstTraining(pPlayer)) then
			clonedConversation:addOption(replies[2], nextID)
		end
	elseif (screenID == "recruitment") then
		-- C-4: Dravis has already told this recruit to bring a ship (J:10466)
		if (readData(playerID .. SmugglerSquadronScreenplay.MET_DRAVIS_KEY) == 1) then
			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_1:s_2268b9e0", "recruit_got_ship")
		end
	elseif (screenID == "recruit_work_something") then
		writeData(playerID .. SmugglerSquadronScreenplay.MET_DRAVIS_KEY, 1)
	elseif (screenID == "non_member") then
		-- C-1: off-track pilots may fly a duty (tatooine_privateer_trainer_1.java:1643)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_1:s_c1ff5062", self:canFlyNonTrackDuty(pPlayer) and "non_member_duty_offer" or "non_member_no_missions")
	elseif (screenID == "recruit_signed") then
		-- Sign-up: novice box, squadron, tier 1 (tatooine_privateer_trainer_1.java:178-183)
		SpaceHelpers:grantNovicePilot(pPlayer, "neutralPilot")
		SpaceHelpers:setSquadronType(pPlayer, SMUGGLER_SQUADRON)

		if (ghost:getPilotTier() < 1) then
			ghost:incrementPilotTier()
		end

		-- C-2
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_1:s_fc0b7ade", "recruit_no_ship")
		end
	elseif (screenID == "lost_ship" or screenID == "recruit_loan_ship") then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "neutral")
		end
	elseif (screenID == "first_training" or screenID == "more_training") then
		-- Every skill the pilot lacks (pre-NGE free choice instead of the NGE offers)
		clonedConversation:removeAllOptions()

		for _, choice in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(choice[1])) then
				clonedConversation:addOption(choice[2], choice[3])
			end
		end
	elseif (screenID == "tier_done") then
		if (ghost:getPilotTier() == 1) then
			ghost:incrementPilotTier()
		end
	elseif (screenID == "destroy_duty") then
		destroy_duty_tatooine_privateer_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "recovery_duty") then
		recovery_duty_tatooine_privateer_5:startQuest(pPlayer, pNpc)
	elseif (screenID == "leader_duty") then
		destroy_duty_tatooine_privateer_8:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_tatooine_privateer_7:startQuest(pPlayer, pNpc)
	end

	return pClonedScreen
end
