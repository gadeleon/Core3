-- Kaydine (RSF tier 2) conversation handler; ported from SWG-Source naboo_privateer_trainer_2.java. Chain retry/won-check routing: feature space-trainer-fixes.
kaydineConvoHandler = conv_handler:new {}

function kaydineConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	RsfSquadronScreenplay:migrateLegacyProgress(pPlayer)

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("not_pilot")
	end

	-- Check if player has any pilot skills
	if (not SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	-- We know the player is a neutral pilot, check if pilot is a different squadron
	if (not SpaceHelpers:isRSFSquadron(pPlayer)) then
		return convoTemplate:getScreen("pilot_not_rsf")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	-- RSF neutral pilot has completed Tier 3
	if (ghost:getPilotTier() > 3) then
		return convoTemplate:getScreen("finished_tier3")
	end

	-- Player hasn't completed Tier 1 yet
	if (ghost:getPilotTier() < 2) then
		return convoTemplate:getScreen("not_ready_tier2")
	end

	local questOneStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_privateer_tier2_1a")
	local questTwoStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_privateer_13")
	local questThreeStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "recovery_naboo_privateer_14")
	local questFourStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "escort_naboo_privateer_15")

	local questOneComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_1_SIDE2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_1_SIDE2.name)
	local questTwoComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name)
	local questThreeComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_3.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name)
	local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name)

	local escortDutyActive = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_1.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_1.name)
	local recoveryDutyActive = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_2.name)
	local destroyDutyActive = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_3.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_3.name)

	local completedTier2 = SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)

	--[[
			Quests
	--]]

	-- Player has an active mission from Captain Kaydine
	if (questOneStarted or questTwoStarted or questThreeStarted or questFourStarted or escortDutyActive or recoveryDutyActive or destroyDutyActive) then

		return convoTemplate:getScreen("on_mission")

	-- Check if players have all the tier2 skill boxes and finished the last mission, then send them to next trainer.
	elseif (questFourComplete and completedTier2 and getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward") == "1") then
		-- Player has all the skill boxes, they should be tier 3. Increment if not proper
		if (ghost:getPilotTier() <= 2) then
			ghost:incrementPilotTier()
		end

		return convoTemplate:getScreen("completed_kaydine")
	-- Reward Checks
	elseif (questFourComplete and getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward") ~= "1") then
			return convoTemplate:getScreen("mission4_complete")
	elseif (questThreeComplete and getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":reward") ~= "1") then
			return convoTemplate:getScreen("mission3_complete")
	elseif (questTwoComplete and getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":reward") ~= "1") then
			return convoTemplate:getScreen("mission2_reward")
	elseif (questOneComplete and getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":reward") ~= "1") then
			return convoTemplate:getScreen("mission1_complete")
	-- Pilot is able to train
	elseif (not completedTier2 and SpaceHelpers:hasExperienceForTraining(pPlayer, 2)) then
		return convoTemplate:getScreen("ready_train_pilot")
	elseif (not questFourComplete) then
		-- Player is able to start fourth mission
		if (questThreeComplete and not questFourStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission4_failed")
			else
				return convoTemplate:getScreen("mission4_ready")
			end

		-- Player is able to start third mission
		elseif (questTwoComplete and not questThreeStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission3_failed")
			else
				return convoTemplate:getScreen("mission3_ready")
			end
		-- Player is able to start second mission
		elseif (questOneComplete and not questTwoStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission2_failed")
			else
				return convoTemplate:getScreen("mission2_ready")
			end
		-- Player is ready for first mission
		elseif (not questOneComplete and SpaceHelpers:hasPilotTierSkill(pPlayer, "neutral", 2)) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission1_failed")
			else
				return convoTemplate:getScreen("mission1_ready")
			end
		end
	end

	return convoTemplate:getScreen("here_for_work")
end

function kaydineConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()
	local playerID = CreatureObject(pPlayer):getObjectID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	-- Set player as conversation target
	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return pClonedScreen
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return pClonedScreen
	end

	if (screenID == "ready_train_pilot") then
		local skillManager = LuaSkillManager()

		local responseString = "initial_"

		if (SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name)) then
			responseString = "final_"
		elseif (SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_3.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name)) then
			responseString = "mission4_"
		elseif (SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name)) then
			responseString = "mission3_"
		elseif (SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_1_SIDE2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_1_SIDE2.name)) then
			responseString = "mission2_"
		end

		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_starships_02") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_starships_02")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_45b71b4d", responseString .. "train_fighters") -- I am interested in advanced fighters.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_weapons_02") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_weapons_02")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_197f4f94", responseString .. "train_components") -- I am interested in intermediate starship component use.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_procedures_02") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_procedures_02")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_8f5942fa", responseString .. "train_techniques") -- I am interested in starship defense training.
		end
		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_droid_02") and skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_droid_02")) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_eff66f4d", responseString .. "train_algorithms") -- I am interested in reactor engineering algorithms.
		end

	-- Handle Skill box granting
	elseif (string.find(screenID, "_train_")) then
		local skillManager = LuaSkillManager()

		if (string.find(screenID, "train_fighters")) then
			if (skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_starships_02")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_starships_02", true)
			end
		elseif (string.find(screenID, "train_components")) then
			if (skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_weapons_02")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_weapons_02", true)
			end
		elseif (string.find(screenID, "train_techniques")) then
			if (skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_procedures_02")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_procedures_02", true)
			end
		elseif (string.find(screenID, "train_algorithms")) then
			if (skillManager:fulfillsSkillPrerequisitesAndXp(pPlayer, "pilot_neutral_droid_02")) then
				SpaceHelpers:grantSpaceSkill(pPlayer, "pilot_neutral_droid_02", true)
			end
		end

		if (ghost:getPilotTier() <= 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
			ghost:incrementPilotTier()
		end

		return pClonedScreen

	-- Duty Missions (naboo_privateer_trainer_2.java:248-259, branch 55)
	elseif (screenID == "accept_duty_escort") then
		escort_duty_naboo_privateer_9:startQuest(pPlayer, pNpc)
	elseif (screenID == "accept_duty_recovery") then
		recovery_duty_naboo_privateer_10:startQuest(pPlayer, pNpc)
	elseif (screenID == "accept_duty_destroy") then
		destroy_duty_naboo_privateer_11:startQuest(pPlayer, pNpc)

	-- Mission Rewards
	elseif (screenID == "mission4_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward", 1)
		escort_naboo_privateer_15:rewardPlayer(pPlayer)
	elseif (screenID == "mission3_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":reward", 1)
		recovery_naboo_privateer_14:rewardPlayer(pPlayer)

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_78", "mission3_reward_end")

		if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2) and SpaceHelpers:hasExperienceForTraining(pPlayer, 2)) then
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_45d20070", "ready_train_pilot")
		else
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_6114e8b7", "mission3_reward_duty")
		end
	elseif (screenID == "mission2_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":reward", 1)
		destroy_naboo_privateer_13:rewardPlayer(pPlayer)
	elseif (screenID == "mission1_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":reward", 1)
		assassinate_naboo_privateer_tier2_1a:rewardPlayer(pPlayer)

	-- Mission 1 briefing: male pilots get a different last line
	elseif (screenID == "mission1_brief") then
		if (CreatureObject(pPlayer):getGender() == 0) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_242", "mission1_accept_male")
		end

	-- Give Missions
	elseif (screenID == "mission4_accept" or screenID == "mission4_failed") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "escort_naboo_privateer_15")
	elseif (screenID == "mission3_accept" or screenID == "mission3_failed") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "recovery_naboo_privateer_14")
	elseif (screenID == "mission2_accept" or screenID == "mission2_failed") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "destroy_naboo_privateer_13")
	elseif (screenID == "mission1_accept" or screenID == "mission1_accept_male" or screenID == "mission1_failed") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "assassinate_naboo_privateer_tier2_1a")
	end

	return pClonedScreen
end
