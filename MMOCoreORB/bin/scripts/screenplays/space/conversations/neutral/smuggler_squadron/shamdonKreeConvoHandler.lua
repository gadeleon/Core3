-- Shamdon Kree (Smuggler tier 2) conversation handler; ported from SWG-Source tatooine_privateer_trainer_shamdon.java. Training: pre-NGE client lines, one click per skill (feature smuggler-tier2-shamdon).
local SpaceHelpers = require("utils.space_helpers")

shamdonKreeConvoHandler = conv_handler:new {}

-- Per story mission n (SWG flag order): the skill bought for it, the head quest global, its quest string key, its briefing and retry screens
shamdonKreeConvoHandler.MISSIONS = {
	{ skill = "pilot_neutral_starships_02", head = "assassinate_tatooine_privateer_tier2_1a", questString = "TIER2_QUEST_STRING_1", brief = "m1_brief", retry = "m1_retry" },
	{ skill = "pilot_neutral_droid_02", head = "assassinate_tatooine_privateer_tier2_2a", questString = "TIER2_QUEST_STRING_2", brief = "m2_brief", retry = "m2_retry" },
	{ skill = "pilot_neutral_weapons_02", head = "assassinate_tatooine_privateer_tier2_3a", questString = "TIER2_QUEST_STRING_3", brief = "m3_brief", retry = "m3_retry" },
	{ skill = "pilot_neutral_procedures_02", head = "escort_tatooine_privateer_tier2_4a", questString = "TIER2_QUEST_STRING_4", brief = "m4_brief", retry = "m4_retry" }
}

-- Pre-NGE free choice of the next skill: { skill, topic reply, trained screen }, in SWG order
shamdonKreeConvoHandler.TRAIN_CHOICES = {
	{ "pilot_neutral_starships_02", "@conversation/tatooine_privateer_trainer_shamdon:s_45b71b4d", "trained_starships" },
	{ "pilot_neutral_weapons_02", "@conversation/tatooine_privateer_trainer_shamdon:s_197f4f94", "trained_weapons" },
	{ "pilot_neutral_procedures_02", "@conversation/tatooine_privateer_trainer_shamdon:s_8f5942fa", "trained_procedures" },
	{ "pilot_neutral_droid_02", "@conversation/tatooine_privateer_trainer_shamdon:s_eff66f4d", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
shamdonKreeConvoHandler.START_SCREENS = {
	m1_brief = 1, m1_retry = 1,
	m2_brief = 2, m2_retry = 2,
	m3_brief = 3, m3_retry = 3,
	m4_brief = 4, m4_retry = 4
}

-- Screens whose reply pays the mission (M1 is paid on its greeting)
shamdonKreeConvoHandler.PAY_ON_REPLY = {
	m2_reward = 2,
	m3_eliminate = 3,
	m4_reward = 4
}

-- The "Ready for another assignment?" screens: screen -> { "no" reply, its screen }
shamdonKreeConvoHandler.ANOTHER_SCREENS = {
	m1_reward_nothing = { "@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back" },
	m1_reward_doubt = { "@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back" },
	m2_paid = { "@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back" },
	m3_paid_naturally = { "@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back_soon" },
	m3_paid_yes = { "@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back_soon" },
	m4_paid_fine = { "@conversation/tatooine_privateer_trainer_shamdon:s_360d8728", "come_back" },
	m4_paid_handle = { "@conversation/tatooine_privateer_trainer_shamdon:s_360d8728", "come_back" }
}

-- Duty screens: screen -> the duty global that is started
shamdonKreeConvoHandler.DUTY_SCREENS = {
	duty_escort = "escort_duty_tatooine_privateer_tier2_1",
	duty_recovery = "recovery_duty_tatooine_privateer_tier2_1",
	duty_destroy = "destroy_duty_tatooine_privateer_tier2_1"
}

-- Mission n won (SWG hasWonQuestRecursive)
function shamdonKreeConvoHandler:isWon(pPlayer, n)
	local questString = SmugglerSquadronScreenplay[self.MISSIONS[n].questString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
end

function shamdonKreeConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- suffix is ":attempted" or ":reward"
function shamdonKreeConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local questString = SmugglerSquadronScreenplay[self.MISSIONS[n].questString]

	return getQuestStatus(playerID .. questString.name .. suffix) == "1"
end

-- Granted before, but neither won nor running any more (failed or aborted)
function shamdonKreeConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

-- Any of the four missions or three duties is running
function shamdonKreeConvoHandler:isOnMission(pPlayer)
	local SSP = SmugglerSquadronScreenplay

	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	for n = 1, 3 do
		local questString = SSP["TIER2_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, questString.type, questString.name)) then
			return true
		end
	end

	return false
end

-- The delivery was paid (Karrde's transition quest key, written here)
function shamdonKreeConvoHandler:isTransPaid(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. "tat_priv_quest_trans:reward") == "1"
end

-- SWG canFlyNonTrackDuty (tatooine_privateer_trainer_shamdon.java:159-166) for neutral pilots only (spec D-6)
function shamdonKreeConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:isNeutralPilot(pPlayer) and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The mission of the lowest skill bought whose mission was never granted (SWG readyForTier2Mission, derived), or nil
function shamdonKreeConvoHandler:getReadyMission(pPlayer)
	for n = 1, 4 do
		if (CreatureObject(pPlayer):hasSkill(self.MISSIONS[n].skill) and not self:hasStatus(pPlayer, n, ":attempted")) then
			return n
		end
	end

	return nil
end

function shamdonKreeConvoHandler:isReadyForTraining(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1) and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 2) == true and self:getReadyMission(pPlayer) == nil
end

-- Pays the reward of mission n once: the :reward key, then the head's credits and item
function shamdonKreeConvoHandler:payMission(pPlayer, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local questString = SmugglerSquadronScreenplay[self.MISSIONS[n].questString]
	local key = playerID .. questString.name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)
end

-- Pays Karrde's package once: the transition's 5000 credits, and the key Karrde reads
function shamdonKreeConvoHandler:payTrans(pPlayer)
	if (self:isTransPaid(pPlayer)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. "tat_priv_quest_trans:reward", 1)

	assassinate_tat_priv_quest_trans:rewardPlayer(pPlayer)
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function shamdonKreeConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training (the skill is read from the link of the chosen option) and payment on the reply
function shamdonKreeConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""

	if (lastScreen == "training") then
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

		if (skill == nil or CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer)) then
			return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		end

		if (LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
			SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
		end

		if (not CreatureObject(pPlayer):hasSkill(skill)) then
			return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		end

		return LuaConversationTemplate(pConvTemplate):getScreen(link)
	end

	local payMission = self.PAY_ON_REPLY[lastScreen]

	if (payMission ~= nil) then
		self:payMission(pPlayer, payMission)

		if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
			return LuaConversationTemplate(pConvTemplate):getScreen("bad_news_reply")
		end
	end

	return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
end

-- Side-effect free: the "Sure." link of the reward screens calls it
function shamdonKreeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (not isJtlEnabled() or CreatureObject(pPlayer):getPlayerObject() == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	-- Not a Smuggler: Rebel, Imperial, CorSec, RSF and squadron-less pilots meet the off-track greeting
	if (not SpaceHelpers:isSmugglerSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	end

	-- Karrde's package is not delivered yet
	if (not SmugglerSquadronScreenplay:hasWonTransQuest(pPlayer)) then
		return convoTemplate:getScreen("stranger")
	end

	if (not self:isTransPaid(pPlayer)) then
		return convoTemplate:getScreen("package")
	end

	if (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("busy")
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen(self.MISSIONS[n].retry)
		end
	end

	local rewardScreens = { "m1_reward", "m2_reward", "m3_reward", "m4_reward" }

	for n = 1, 4 do
		if (self:isWon(pPlayer, n) and not self:hasStatus(pPlayer, n, ":reward")) then
			return convoTemplate:getScreen(rewardScreens[n])
		end
	end

	if (self:getReadyMission(pPlayer) ~= nil) then
		return convoTemplate:getScreen("ready_mission")
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
		return convoTemplate:getScreen("bad_news")
	end

	if (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training")
	end

	return convoTemplate:getScreen("work")
end

function shamdonKreeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return nil
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	local startMission = self.START_SCREENS[screenID]
	local another = self.ANOTHER_SCREENS[screenID]
	local dutyGlobal = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		setQuestStatus(playerID .. SmugglerSquadronScreenplay[self.MISSIONS[startMission].questString].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (dutyGlobal ~= nil) then
		_G[dutyGlobal]:startQuest(pPlayer, pNpc)
	elseif (screenID == "off_track") then
		-- C-1: off-track pilots may fly a duty (java:339-397)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_c1ff5062", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_refused")
	elseif (screenID == "talon_only") then
		-- C-2
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_32965dab", CreatureObject(pPlayer):getGender() == 0 and "talon_who_male" or "talon_who_female")
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_bb27779e", "talon_what")
	elseif (screenID == "package") then
		-- C-3
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_d14c381d", CreatureObject(pPlayer):getGender() == 0 and "trans_paid_male" or "trans_paid_female")
	elseif (screenID == "trans_paid_male" or screenID == "trans_paid_female") then
		self:payTrans(pPlayer)
	elseif (screenID == "m1_reward") then
		-- M1 is paid on its greeting; C-4: with all four skills the replies lead to the bad news
		self:payMission(pPlayer, 1)

		local done = SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_bc000879", done and "bad_news_reply" or "m1_reward_nothing")
		clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_34e4d30", done and "bad_news_reply" or "m1_reward_doubt")
	elseif (another ~= nil) then
		-- C-5: "Sure." goes where the gates now lead, "Ok." to the duty menu
		clonedConversation:removeAllOptions()

		if (self:isReadyForTraining(pPlayer)) then
			local pNext = self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
			local nextID = pNext ~= nil and LuaConversationScreen(pNext):getScreenID() or "not_pilot"

			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", nextID)
		else
			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu")
		end

		clonedConversation:addOption(another[1], another[2])
	elseif (screenID == "ready_mission") then
		-- C-6
		local n = self:getReadyMission(pPlayer)

		if (n ~= nil) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_5c522568", self.MISSIONS[n].brief)
			clonedConversation:addOption("@conversation/tatooine_privateer_trainer_shamdon:s_f3d46f0b", "not_yet")
		end
	elseif (screenID == "training") then
		-- C-7: every skill the pilot lacks (pre-NGE free choice instead of the NGE offers)
		clonedConversation:removeAllOptions()

		for _, choice in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(choice[1])) then
				clonedConversation:addOption(choice[2], choice[3])
			end
		end
	elseif (screenID == "bad_news" or screenID == "bad_news_reply") then
		-- The tier 2 series is done: the ship becomes Jabba's (pilot tier 3)
		local pGhost = CreatureObject(pPlayer):getPlayerObject()

		if (pGhost ~= nil) then
			local ghost = LuaPlayerObject(pGhost)

			if (ghost ~= nil and ghost:getPilotTier() == 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 2)) then
				ghost:incrementPilotTier()
			end
		end
	end

	return pClonedScreen
end
