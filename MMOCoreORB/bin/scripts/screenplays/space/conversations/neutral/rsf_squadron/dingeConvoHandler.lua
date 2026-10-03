-- Dinge (RSF tier 1) conversation handler; ported from SWG-Source naboo_privateer_trainer_1.java. Chain retry/won-check routing: feature space-trainer-fixes.
dingeConvoHandler = conv_handler:new {}

function dingeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	-- Player is Rebel Pilot
	if (SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	-- Player is Imperial Pilot
	elseif (SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	end

	local isNeutralPilot = SpaceHelpers:isNeutralPilot(pPlayer)
	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)

	local questOneStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_privateer_1")
	local questTwoStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_2.type, RsfSquadronScreenplay.QUEST_STRING_2.name)
	local questThreeStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_privateer_3")
	local questFourStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_4.type, RsfSquadronScreenplay.QUEST_STRING_4.name)

	local questOneComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_1.type, RsfSquadronScreenplay.QUEST_STRING_1.name) and SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_1_SIDE.type, RsfSquadronScreenplay.QUEST_STRING_1_SIDE.name)
	local questTwoComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_2.type, RsfSquadronScreenplay.QUEST_STRING_2.name)
	local questThreeComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_3.type, RsfSquadronScreenplay.QUEST_STRING_3.name) and SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_3_SIDE.type, RsfSquadronScreenplay.QUEST_STRING_3_SIDE.name)
	local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_4.type, RsfSquadronScreenplay.QUEST_STRING_4.name)

	local destroyDutyStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.name)
	local escortDutyStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.name)

	local destroyDutyComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.name)
	local escortDutyComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.name)

	-- Player is a Neutral Pilot but not RSF
	if (isNeutralPilot and not SpaceHelpers:isRSFSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_rsf_pilot")
	-- Player does not have neutral pilot novice skill
	elseif (not isNeutralPilot) then
		return convoTemplate:getScreen("recruitment")

	-- Check to ensure player has a starter ship or one they can use
	elseif (not hasShip and not questOneStarted) then
		return convoTemplate:getScreen("no_ship")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	-- Player destroyed their ship control device
	if (not hasShip) then
		grantStarterShip(pPlayer, "neutral")
	end

	--[[
			Quests
	--]]

	-- (rsf-tier1-dinge-convo) status keys
	local reward1 = getQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_1.name .. ":reward")
	local reward2 = getQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_2.name .. ":reward")
	local reward3 = getQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_3.name .. ":reward")
	local reward4 = getQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_4.name .. ":reward")

	local function attempted(questString)
		return getQuestStatus(playerID .. questString.name .. ":attempted") == "1"
	end

	-- Player has an active quest from this trainer
	if ((questTwoStarted and not questTwoComplete) or (questThreeStarted and not questThreeComplete) or (questFourStarted and not questFourComplete) or (destroyDutyStarted and not destroyDutyComplete) or (escortDutyStarted and not escortDutyComplete)) then
		return convoTemplate:getScreen("has_mission")
	-- Check if players have all the tier1 skill boxes, send them to next trainer.
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1)) then
		return convoTemplate:getScreen("completed_tier1")
	-- Player is an RSF pilot and has at least one of the Tier1 skill boxes
	elseif (SpaceHelpers:hasPilotTierSkill(pPlayer, "neutral", 1)) then
		-- Check if the player can be trained in the remaining Tier1 Skills
		if (SpaceHelpers:hasExperienceForTraining(pPlayer, 1)) then
			return convoTemplate:getScreen("more_training")
		-- Offer Duty missions
		else
			return convoTemplate:getScreen("duty_missions")
		end
	-- Player has finished 4 and has received the reward, but needs to accept training of first pilot skill
	elseif (questFourComplete and reward4 == "1") then
		return convoTemplate:getScreen("missions_complete")
	-- Player has completed quest 4 and needs reward (paid on the reward screen)
	elseif (questFourComplete and reward4 ~= "1") then
		return convoTemplate:getScreen("mission4_reward")
	-- Player has finished 3, has received the reward and needs to start quest 4
	elseif (questThreeComplete and not questFourStarted and reward3 == "1") then
		return convoTemplate:getScreen(attempted(RsfSquadronScreenplay.QUEST_STRING_4) and "mission4_failed" or "mission4_offer")
	-- Player has completed quest 3 and needs reward
	elseif (questThreeComplete and reward3 ~= "1") then
		return convoTemplate:getScreen("mission3_reward")
	-- Player has finished 2, has received the reward and needs to start quest 3
	elseif (questTwoComplete and not questThreeStarted and reward2 == "1") then
		return convoTemplate:getScreen(attempted(RsfSquadronScreenplay.QUEST_STRING_3) and "mission3_failed" or "mission3_offer")
	-- Player has completed quest 2 and needs reward
	elseif (questTwoComplete and reward2 ~= "1") then
		return convoTemplate:getScreen("mission2_reward")
	-- Player has finished quest 1, has received the reward and needs to start quest 2
	elseif (questOneComplete and not questTwoStarted and reward1 == "1") then
		return convoTemplate:getScreen(attempted(RsfSquadronScreenplay.QUEST_STRING_2) and "mission2_failed" or "mission2_offer")
	-- Player has finished quest 1 and needs reward
	elseif (questOneComplete and reward1 ~= "1") then
		return convoTemplate:getScreen("mission1_reward")
	-- Player has first quest active, the mission giver will offer assistance
	elseif (questOneStarted and not questOneComplete) then
		return convoTemplate:getScreen("mission1_active")
	-- Player has failed or aborted the first quest
	elseif (not questOneComplete) then
		return convoTemplate:getScreen(attempted(RsfSquadronScreenplay.QUEST_STRING_1) and "mission1_failed" or "mission1_offer")
	end

	return convoTemplate:getScreen("no_jtl")
end

function dingeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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

	-- Handle additional training
	if (screenID == "more_training") then
		local skillManager = LuaSkillManager()

		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_starships_01") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_starships_01")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_e94f494b", "train_player_fighters") -- I want to know about basic fighters.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_weapons_01") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_weapons_01")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_939b6844", "train_player_component") -- I want to know about basic starship component use.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_procedures_01") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_procedures_01")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_ac00d21e", "train_player_basics") -- I want to know about basic training.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_droid_01") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_droid_01")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_1726d8a5", "train_player_droid") -- I want to know about droid interface basics.
		end
	-- Handle Skill box granting
	elseif (string.find(screenID, "train_player_")) then
		local skillManager = LuaSkillManager()

		local deductExperience = (string.find(screenID, "_free") == nil)

		screenID = string.gsub(screenID, "_free", "")

		if (screenID == "train_player_droid") then
			if (not deductExperience or skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_droid_01")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_droid_01", deductExperience)
			end
		elseif (screenID == "train_player_basics") then
			if (not deductExperience or skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_procedures_01")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_procedures_01", deductExperience)
			end
		elseif (screenID == "train_player_fighters") then
			if (not deductExperience or skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_starships_01")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_starships_01", deductExperience)
			end
		elseif (screenID == "train_player_component") then
			if (not deductExperience or skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_weapons_01")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_weapons_01", deductExperience)
			end
		end

		if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1) and ghost:getPilotTier() == 1) then
			ghost:incrementPilotTier()
		end

		return pClonedScreen
	elseif (screenID == "go_to_tier2") then
		-- Increment tier when player is sent to Kaydine
		if (ghost:getPilotTier() == 1) then
			ghost:incrementPilotTier()
		end
	elseif (screenID == "destroy_duty") then
		destroy_duty_naboo_privateer_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_naboo_privateer_7:startQuest(pPlayer, pNpc)
	elseif (screenID == "yes_enlist") then
		CreatureObject(pPlayer):doAnimation("nod_head_once")

		-- Grant freelance pilot novice box
		SpaceHelpers:grantNovicePilot(pPlayer, "neutralPilot")

		-- Sets RSF Squadron
		SpaceHelpers:setSquadronType(pPlayer, RSF_SQUADRON)

		-- Set pilot tier
		if (ghost:getPilotTier() < 1) then
			ghost:incrementPilotTier()
		end

		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_9817b9bb", "signup_no_ship") -- No, I don't.
		else
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_1:s_5c522568", "yes_ship")
		end
	elseif (screenID == "no_ship" or screenID == "signup_no_ship") then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "neutral")
		end

	-- Rewards (paid on the screen that carries the reward)
	elseif (screenID == "mission1_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_1.name .. ":reward", 1)
		patrol_naboo_privateer_1:rewardPlayer(pPlayer)
	elseif (screenID == "mission2_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_2.name .. ":reward", 1)
		destroy_naboo_privateer_2:rewardPlayer(pPlayer)
	elseif (screenID == "mission3_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_3.name .. ":reward", 1)
		patrol_naboo_privateer_3:rewardPlayer(pPlayer)
	elseif (screenID == "mission4_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_4.name .. ":reward", 1)
		assassinate_naboo_privateer_tier1_4a:rewardPlayer(pPlayer)

	-- Missions (started on the screen that carries the grant)
	elseif (screenID == "mission1_accept" or screenID == "mission1_boast_accept1" or screenID == "mission1_boast_accept2" or screenID == "mission1_failed_attacked" or screenID == "mission1_failed_will_do") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_1.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "patrol_naboo_privateer_1")
	elseif (screenID == "mission2_accept" or screenID == "mission2_failed") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_2.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "destroy_naboo_privateer_2")
	elseif (screenID == "mission3_accept" or screenID == "mission3_failed_retry1" or screenID == "mission3_failed_retry2") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_3.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "patrol_naboo_privateer_3")
	elseif (screenID == "mission4_accept" or screenID == "mission4_failed_retry1" or screenID == "mission4_failed_retry2" or screenID == "mission4_failed_retry3") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.QUEST_STRING_4.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "assassinate_naboo_privateer_tier1_4a")
	end

	return pClonedScreen
end
