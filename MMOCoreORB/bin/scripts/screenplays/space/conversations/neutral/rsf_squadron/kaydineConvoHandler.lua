-- Kaydine (RSF tier 2) conversation handler; ported from SWG-Source naboo_privateer_trainer_2.java. Chain retry/won-check routing: feature space-trainer-fixes.
kaydineConvoHandler = conv_handler:new {
	-- Purchase prompt screen => the skill bought when its option is chosen (naboo_privateer_trainer_2.java:2335, 3033, 3302, 3571)
	TRAIN_SCREENS = {
		train_starships = "pilot_neutral_starships_02",
		train_weapons = "pilot_neutral_weapons_02",
		train_procedures = "pilot_neutral_procedures_02",
		train_droid = "pilot_neutral_droid_02"
	}
}

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

	-- Check if player has any pilot skills, then which faction (naboo_privateer_trainer_2.java:3881-3898)
	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	elseif (SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
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
	local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 2)

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
	elseif (not questFourComplete) then
		-- Player is able to start fourth mission
		if (questThreeComplete and not questFourStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission4_failed")
			elseif (skillCount >= 4) then
				return convoTemplate:getScreen("mission4_ready")
			end

		-- Player is able to start third mission
		elseif (questTwoComplete and not questThreeStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission3_failed")
			elseif (skillCount >= 3) then
				return convoTemplate:getScreen("mission3_ready")
			end
		-- Player is able to start second mission
		elseif (questOneComplete and not questTwoStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_2.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission2_failed")
			elseif (skillCount >= 2) then
				return convoTemplate:getScreen("mission2_ready")
			end
		-- Player is ready for first mission
		elseif (not questOneComplete) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("mission1_failed")
			elseif (skillCount >= 1) then
				return convoTemplate:getScreen("mission1_ready")
			end
		end
	end

	-- Pilot is able to train
	if (self:canTrain(pPlayer)) then
		return convoTemplate:getScreen("ready_train_pilot")
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
		-- Offer the first skill the pilot lacks, in SWG's order (naboo_privateer_trainer_2.java:2204-2330)
		local link = "train_droid"

		if (not CreatureObject(pPlayer):hasSkill(self.TRAIN_SCREENS.train_starships)) then
			link = "train_starships"
		elseif (not CreatureObject(pPlayer):hasSkill(self.TRAIN_SCREENS.train_weapons)) then
			link = "train_weapons"
		elseif (not CreatureObject(pPlayer):hasSkill(self.TRAIN_SCREENS.train_procedures)) then
			link = "train_procedures"
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_187", link)

	-- Duty Missions (naboo_privateer_trainer_2.java:248-259, branch 55)
	elseif (screenID == "accept_duty_escort") then
		escort_duty_naboo_privateer_9:startQuest(pPlayer, pNpc)
	elseif (screenID == "accept_duty_recovery") then
		recovery_duty_naboo_privateer_10:startQuest(pPlayer, pNpc)
	elseif (screenID == "accept_duty_destroy") then
		destroy_duty_naboo_privateer_11:startQuest(pPlayer, pNpc)

	-- Off-track pilots may fly a duty (naboo_privateer_trainer_2.java:282-343)
	elseif (screenID == "pilot_not_rsf") then
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_c1ff5062", self:canFlyNonTrackDuty(pPlayer) and "non_rsf_duty_options" or "non_rsf_missions")

	-- Mission Rewards
	elseif (screenID == "mission4_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward", 1)
		escort_naboo_privateer_15:rewardPlayer(pPlayer)
	elseif (screenID == "mission3_reward") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_3.name .. ":reward", 1)
		recovery_naboo_privateer_14:rewardPlayer(pPlayer)

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_78", "mission3_reward_end")

		if (self:canTrain(pPlayer)) then
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

	-- Mission 1 introduction: male pilots get a different last line
	elseif (screenID == "mission1_intro_b4") then
		if (CreatureObject(pPlayer):getGender() == 0) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/naboo_privateer_trainer_2:s_264", "mission1_intro_accept_male")
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
	elseif (screenID == "mission1_accept" or screenID == "mission1_accept_male" or screenID == "mission1_failed" or screenID == "mission1_intro_accept" or screenID == "mission1_intro_accept_male") then
		setQuestStatus(playerID .. RsfSquadronScreenplay.TIER2_QUEST_STRING_1.name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "assassinate_naboo_privateer_tier2_1a")
	end

	return pClonedScreen
end

-- Any of Kaydine's story chains or duties is running (the on_mission condition of getInitialScreen)
function kaydineConvoHandler:isOnMission(pPlayer)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_privateer_tier2_1a")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_privateer_13")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "recovery_naboo_privateer_14")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "escort_naboo_privateer_15")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_1.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_2.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_2.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_3.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_DUTY_3.name)
end

-- SWG canFlyNonTrackDuty (naboo_privateer_trainer_2.java:183-190): all of tier 1 and no quest
function kaydineConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The story mission the pilot is on: 5 once mission 4 is won, else 1 + the number of missions won in order
function kaydineConvoHandler:getNextMission(pPlayer)
	local won = function(quest)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, quest.type, quest.name)
	end

	if (won(RsfSquadronScreenplay.TIER2_QUEST_STRING_4)) then
		return 5
	elseif (won(RsfSquadronScreenplay.TIER2_QUEST_STRING_3)) then
		return 4
	elseif (won(RsfSquadronScreenplay.TIER2_QUEST_STRING_2)) then
		return 3
	elseif (won(RsfSquadronScreenplay.TIER2_QUEST_STRING_1_SIDE2)) then
		return 2
	end

	return 1
end

-- SWG's isReadyForMoreTraining, with the skill count below the next mission (one skill per mission)
function kaydineConvoHandler:canTrain(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 2)
		and SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 2) < self:getNextMission(pPlayer)
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function kaydineConvoHandler:getLastScreenID(pPlayer)
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

-- Choosing the option on a train_<x> screen buys the skill (once), then the pilot is introduced to
-- the mission the skill count unlocks (naboo_privateer_trainer_2.java:2335-2479)
function kaydineConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""
	local skill = self.TRAIN_SCREENS[lastScreen]

	if (skill == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill) and SpaceHelpers:hasExperienceForTraining(pPlayer, 2) and LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() <= 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
			ghost:incrementPilotTier()
		end
	end

	local nextMission = self:getNextMission(pPlayer)
	local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 2)

	if (nextMission <= 4 and skillCount >= nextMission) then
		local name = string.gsub(lastScreen, "^train_", "")

		return LuaConversationTemplate(pConvTemplate):getScreen("trained_" .. name .. "_mission" .. nextMission)
	end

	-- Nothing to introduce (pilot behind on skills, or all missions won): start over
	return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
end
