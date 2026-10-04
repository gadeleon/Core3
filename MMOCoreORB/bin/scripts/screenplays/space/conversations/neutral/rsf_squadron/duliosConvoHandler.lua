duliosConvoHandler = conv_handler:new {}

duliosConvoHandler.REWARD_SCREENS = { complete_mission1 = 1, complete_mission2 = 2, complete_mission3 = 3, complete_mission4 = 4 }

duliosConvoHandler.START_SCREENS = {
	m1_e1e07205 = 1, m1_70 = 1, m1_78 = 1, m1_100 = 1, m1_118 = 1, m1_139 = 1, m1_165 = 1, m1_182 = 1,
	m1_retry_2bcd2d13 = 1, m1_retry_ff7bebda = 1,
	m2_61968e69 = 2, m2_233 = 2, m2_b8955212 = 2, m2_274 = 2,
	m2_retry_327eb2d6 = 2, m2_retry_145dcab = 2,
	m3_c4095762 = 3, m3_3fa8b6f1 = 3, m3_331 = 3, m3_349 = 3,
	m3_retry_2852c031 = 3, m3_retry_b679efe = 3,
	m4_d9c145dd = 4, m4_46eb0ec8 = 4,
	m4_retry_57d34626 = 4, m4_retry_ff5d0ba8 = 4
}

-- Skill, choice option string id, training screen id
duliosConvoHandler.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_03", "@conversation/naboo_privateer_tier3:s_aa766bd6", "train_warships" },
	{ "pilot_neutral_weapons_03", "@conversation/naboo_privateer_tier3:s_a70b470e", "train_components" },
	{ "pilot_neutral_procedures_03", "@conversation/naboo_privateer_tier3:s_da0e8cd0", "train_techniques" },
	{ "pilot_neutral_droid_03", "@conversation/naboo_privateer_tier3:s_c28a300f", "train_programming" }
}

local MISSION_HEADS = {
	"recovery_naboo_privateer_tier3_1a",
	"escort_naboo_privateer_tier3_2a",
	"inspect_naboo_privateer_tier3_3a",
	"assassinate_naboo_privateer_tier3_4a"
}

local MISSION_QUESTS = {
	RsfSquadronScreenplay.TIER3_QUEST_STRING_1,
	RsfSquadronScreenplay.TIER3_QUEST_STRING_2,
	RsfSquadronScreenplay.TIER3_QUEST_STRING_3,
	RsfSquadronScreenplay.TIER3_QUEST_STRING_4
}

function duliosConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	if (not SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	end

	-- Check if player is RSF Pilot
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

	-- RSF neutral pilot has not completed Tier2
	if (ghost:getPilotTier() < 3) then
		return convoTemplate:getScreen("not_tier3")
	end

	local questOneStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_1.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_1.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE1.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE1.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE2.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE2.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE3.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE3.name)
	local questTwoStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_2.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_2.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE1.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE1.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE2.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE2.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE3.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE3.name)
	local questThreeStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_3.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_3.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE1.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE1.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE2.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE2.name) or
							SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE3.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE3.name)
	local questFourStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_privateer_tier3_4a")

	local questOneComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE3.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE3.name)
	local questTwoComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE1.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE1.name)
	local questThreeComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE2.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_3_SIDE2.name)
	local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER3_QUEST_STRING_4_SIDE5.type, RsfSquadronScreenplay.TIER3_QUEST_STRING_4_SIDE5.name)

	local completedTier3 = SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)

	-- Check if players have all the tier3 skill boxes and finished the last mission, then send them to next trainer.
	if (questFourComplete and completedTier3) then
		-- Players has all the skill boxes, they should be a tier 4. Increment if not proper
		if (ghost:getPilotTier() <= 3) then
			-- Increment pilot to Tier 4
			ghost:incrementPilotTier()
		end

		return convoTemplate:getScreen("completed_dulios")
	end

	--[[
			Quests
	--]]

	-- Player has an active mission from CDR Dulios
	-- Any active member of a tier 3 chain counts, even after its mission win quest is complete (SWG isOnQuest)
	local onMission = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "recovery_naboo_privateer_tier3_1a") or
						SpaceHelpers:isSpaceQuestChainActive(pPlayer, "escort_naboo_privateer_tier3_2a") or
						SpaceHelpers:isSpaceQuestChainActive(pPlayer, "inspect_naboo_privateer_tier3_3a") or
						SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_privateer_tier3_4a")

	if (onMission) then
		return convoTemplate:getScreen("on_mission")
	end

	local tier3SkillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 3)

	-- Reward Checks. Tier3 grants a skill box for each mission
	if (questFourComplete and tier3SkillCount == 3) then
		return convoTemplate:getScreen("complete_mission4")
	elseif (questThreeComplete and tier3SkillCount == 2) then
		return convoTemplate:getScreen("complete_mission3")
	elseif (questTwoComplete and tier3SkillCount == 1) then
		return convoTemplate:getScreen("complete_mission2")
	elseif (questOneComplete and tier3SkillCount < 1) then
		return convoTemplate:getScreen("complete_mission1")

	-- Mission Starters
	elseif (not questFourComplete) then
		-- Player is able to start fourth mission
		if (questThreeComplete and not questFourStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_4.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("failed_fourth_mission")
			else
				return convoTemplate:getScreen("fourth_mission")
			end

		-- Player is able to start third mission
		elseif (questTwoComplete and not questThreeStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_3.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("failed_third_mission")
			else
				return convoTemplate:getScreen("third_mission")
			end
		-- Player is able to start second mission
		elseif (questOneComplete and not questTwoStarted) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_2.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("failed_second_mission")
			else
				return convoTemplate:getScreen("second_mission")
			end
		-- Player is ready for first mission, so either was not given it after training first box or failed
		elseif (not questOneComplete) then
			if (getQuestStatus(playerID .. RsfSquadronScreenplay.TIER3_QUEST_STRING_1.name .. ":attempted") == "1") then
				return convoTemplate:getScreen("failed_first_mission")
			else
				return convoTemplate:getScreen("first_mission")
			end
		end
	end

	-- Fewer than four skills but the last mission is done: the old dead end shows the last reward screen
	return convoTemplate:getScreen("complete_mission4")
end

function duliosConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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

	local rewardMission = duliosConvoHandler.REWARD_SCREENS[screenID]

	if (rewardMission ~= nil) then
		local statusKey = playerID .. MISSION_QUESTS[rewardMission].name .. ":reward"

		if (getQuestStatus(statusKey) ~= "1") then
			setQuestStatus(statusKey, 1)

			-- Grant Reward
			_G[MISSION_HEADS[rewardMission]]:rewardPlayer(pPlayer)
		end

		local screenAppend = ""

		if (SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 3) == 3) then
			screenAppend = "_final"
		end

		for i = 1, #duliosConvoHandler.TRAIN_CHOICES do
			local choice = duliosConvoHandler.TRAIN_CHOICES[i]

			if (not CreatureObject(pPlayer):hasSkill(choice[1])) then
				clonedConversation:addOption(choice[2], choice[3] .. screenAppend)
			end
		end

		return pClonedScreen
	end

	-- Handle Skill box granting
	for i = 1, #duliosConvoHandler.TRAIN_CHOICES do
		local choice = duliosConvoHandler.TRAIN_CHOICES[i]

		if (screenID == choice[3] or screenID == choice[3] .. "_final") then
			-- Train player Skill Box
			SpaceHelpers:grantSpaceSkill(pPlayer, choice[1], false)

			if (ghost:getPilotTier() <= 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
				-- If player has all of the Tier 3 skills, increment their pilot tier
				ghost:incrementPilotTier()
			end

			return pClonedScreen
		end
	end

	-- Give Missions
	local startMission = duliosConvoHandler.START_SCREENS[screenID]

	if (startMission ~= nil) then
		setQuestStatus(playerID .. MISSION_QUESTS[startMission].name .. ":attempted", 1)

		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, MISSION_HEADS[startMission])
	end

	return pClonedScreen
end
