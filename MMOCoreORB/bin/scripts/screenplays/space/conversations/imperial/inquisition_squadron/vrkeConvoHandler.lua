-- Inquisitor Vrke (Inquisition tier 3) conversation handler; ported from SWG-Source naboo_imperial_tier3.java. One-click, free-choice training, the grounded gate and the Barlow hand-shake: pre-NGE client lines (feature inquisition-tier3-vrke).
local SpaceHelpers = require("utils.space_helpers")

vrkeConvoHandler = conv_handler:new {}

-- Missions: { head quest global, InquisitionSquadronScreenplay quest string of the head, quest string of the chain end }
vrkeConvoHandler.MISSIONS = {
	{ head = "recovery_naboo_imperial_tier3_1", questString = "TIER3_QUEST_STRING_1", endString = "TIER3_QUEST_STRING_1_SIDE2" },
	{ head = "inspect_naboo_imperial_tier3_2", questString = "TIER3_QUEST_STRING_2", endString = "TIER3_QUEST_STRING_2_SIDE3" },
	{ head = "delivery_naboo_imperial_tier3_3", questString = "TIER3_QUEST_STRING_3", endString = "TIER3_QUEST_STRING_3_SIDE4" },
	{ head = "assassinate_naboo_imperial_tier3_4", questString = "TIER3_QUEST_STRING_4", endString = "TIER3_QUEST_STRING_4_SIDE3" }
}

-- Pre-NGE free choice of a tier 3 skill, one click: { skill, topic reply }, in menu order (J3 grant order)
vrkeConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_03", "@conversation/naboo_imperial_tier3:s_40cda759" },
	{ "pilot_imperial_navy_weapons_03", "@conversation/naboo_imperial_tier3:s_a9aeb386" },
	{ "pilot_imperial_navy_procedures_03", "@conversation/naboo_imperial_tier3:s_ef7a2df5" },
	{ "pilot_imperial_navy_droid_03", "@conversation/naboo_imperial_tier3:s_473d09d8" }
}

-- The skill lead-in screens that carry the topic replies (built at run time): screen -> mission number
vrkeConvoHandler.TRAINING_SCREENS = {
	m1_training = 1, m1_training_best = 1, m2_training = 2, m3_training = 3, m4_training = 4, m4_training_bah = 4
}

-- The screen each topic leads to: [mission][skill] -> trained screen
vrkeConvoHandler.TRAINED_SCREENS = {
	[1] = {
		pilot_imperial_navy_starships_03 = "m1_trained_starships", pilot_imperial_navy_weapons_03 = "m1_trained_weapons",
		pilot_imperial_navy_procedures_03 = "m1_trained_procedures", pilot_imperial_navy_droid_03 = "m1_trained_droid"
	},
	[2] = {
		pilot_imperial_navy_starships_03 = "m2_trained_starships", pilot_imperial_navy_weapons_03 = "m2_trained_weapons",
		pilot_imperial_navy_procedures_03 = "m2_trained_procedures", pilot_imperial_navy_droid_03 = "m2_trained_droid"
	},
	[3] = {
		pilot_imperial_navy_starships_03 = "m3_trained_starships", pilot_imperial_navy_weapons_03 = "m3_trained_weapons",
		pilot_imperial_navy_procedures_03 = "m3_trained_procedures", pilot_imperial_navy_droid_03 = "m3_trained_droid"
	},
	[4] = {
		pilot_imperial_navy_starships_03 = "m4_trained_starships", pilot_imperial_navy_weapons_03 = "m4_trained_weapons",
		pilot_imperial_navy_procedures_03 = "m4_trained_procedures", pilot_imperial_navy_droid_03 = "m4_trained_droid"
	}
}

-- The mission 1 trained screens order the Barlow interview (SWG sentToBarlow)
local QUESTION_BARLOW_SCREENS = {
	m1_trained_starships = true, m1_trained_weapons = true, m1_trained_procedures = true, m1_trained_droid = true
}

-- Screens that start a mission (the head chain is started on display): screen -> mission number
vrkeConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry_searching = 1, m1_retry_promise = 1, m1_retry_sooner = 1,
	m2_accept = 2, m2_accept_simple = 2, m2_retry_loyal = 2, m2_retry_actions = 2,
	m3_accept_dathomir = 3, m3_accept_bait = 3, m3_accept_die = 3, m3_accept_leave = 3, m3_retry = 3,
	m4_accept_accident = 4, m4_accept_accident_2 = 4, m4_accept_casualty = 4, m4_retry_again = 4, m4_retry_excuses = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
vrkeConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens whose line carries the %TU / %NU name token
local NAME_SCREENS = {
	wanted_29eb9a6b = true, m1_reward = true, m2_offer_d3f5b32c = true, jace_elders = true
}

function vrkeConvoHandler:getQuestString(n)
	return InquisitionSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function vrkeConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function vrkeConvoHandler:isWon(pPlayer, n)
	local endString = InquisitionSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function vrkeConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function vrkeConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

-- Any of the four chains is running
function vrkeConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	return false
end

-- All four tier 2 skills and Fa'Zoll's mission 4 paid (J3 reads the skills only; see the spec, D-5)
function vrkeConvoHandler:isReadyForTier3(pPlayer)
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
		return false
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. InquisitionSquadronScreenplay.TIER2_QUEST_STRING_4.name .. ":reward") == "1"
end

-- SWG collectingQuestNReward (naboo_imperial_tier3.java:68-167): mission n won and fewer than n tier 3 skills.
-- Mission 4 is also owed while its reward is unpaid, so the hand-off never precedes it.
function vrkeConvoHandler:getRewardMission(pPlayer)
	local count = SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 3)

	for n = 1, 4 do
		if (self:isWon(pPlayer, n)) then
			if (count < n or (n == 4 and not self:hasStatus(pPlayer, 4, ":reward"))) then
				return n
			end
		end
	end

	return nil
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function vrkeConvoHandler:getLastScreenID(pPlayer)
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

-- Raises pilot tier 3 to 4 once all four tier 3 skills are held
function vrkeConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost ~= nil and ghost:getPilotTier() <= 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		ghost:incrementPilotTier()
	end
end

-- Pre-NGE one-click training: a topic reply on a training screen grants the skill (free, as J3 noisyGrantSkill) and
-- shows its trained screen. Any failed guard sends the pilot back through the gates.
function vrkeConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local mission = self.TRAINING_SCREENS[self:getLastScreenID(pPlayer) or ""]

	if (mission == nil) then
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
		if (self.TRAINED_SCREENS[mission][entry[1]] == link) then
			skill = entry[1]
		end
	end

	if (skill == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	if (CreatureObject(pPlayer):hasSkill(skill) or self:getRewardMission(pPlayer) ~= mission) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	SpaceHelpers:grantSpaceSkill(pPlayer, skill, false)

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 3
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		self:raisePilotTier(pPlayer, LuaPlayerObject(pGhost))
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows naboo_imperial_tier3.java OnStartNpcConversation (:6681 on)
function vrkeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	local IS = InquisitionSquadronScreenplay
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not SpaceHelpers:isInquisitionSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	-- Imperials only: negative standing or a lost Imperial faction is grounded
	elseif (ghost:getFactionStanding("imperial") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen("wanted")
	elseif (not self:isReadyForTier3(pPlayer)) then
		return convoTemplate:getScreen("not_ready")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_failed")
		end
	end

	local rewardMission = self:getRewardMission(pPlayer)

	if (rewardMission ~= nil) then
		return convoTemplate:getScreen("m" .. rewardMission .. "_reward")
	end

	if (not self:isWon(pPlayer, 1)) then
		return convoTemplate:getScreen("m1_offer")
	elseif (getQuestStatus(playerID .. IS.QUESTION_BARLOW_KEY) == "1") then
		return convoTemplate:getScreen("barlow_pending")
	end

	for n = 2, 4 do
		if (not self:isWon(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_offer")
		end
	end

	return convoTemplate:getScreen("tour_complete")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 100 Imperial standing
function vrkeConvoHandler:payMission(pPlayer, ghost, n)
	if (self:hasStatus(pPlayer, n, ":reward")) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 100)
end

function vrkeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()
	local IS = InquisitionSquadronScreenplay

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	if (NAME_SCREENS[screenID]) then
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
	local trainingMission = self.TRAINING_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (trainingMission ~= nil) then
		-- C-1: every tier 3 skill the pilot lacks
		clonedConversation:removeAllOptions()

		local added = false

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], self.TRAINED_SCREENS[trainingMission][entry[1]])
				added = true
			end
		end

		if (not added) then
			clonedConversation:setStopConversation(true)
		end
	elseif (QUESTION_BARLOW_SCREENS[screenID]) then
		-- SWG sentToBarlow: the pilot is ordered to question Lt. Colonel Barlow
		setQuestStatus(playerID .. IS.QUESTION_BARLOW_KEY, 1)
	elseif (screenID == "tour_complete") then
		-- SWG removeTalkedToBarlow
		removeQuestStatus(playerID .. IS.SPOKE_TO_BARLOW_KEY)
		self:raisePilotTier(pPlayer, ghost)
	end

	return pClonedScreen
end
