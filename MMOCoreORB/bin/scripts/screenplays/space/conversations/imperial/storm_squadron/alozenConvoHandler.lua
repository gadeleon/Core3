-- Field Commander Alozen (Storm Squadron tier 2) conversation handler; ported from SWG-Source tatooine_imperial_trainer_2b.java. Training and the NGE-only gates: pre-NGE client lines (feature storm-tier2-alozen).
local SpaceHelpers = require("utils.space_helpers")

alozenConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the tier 2 skill: { skill, topic reply, trained screen }, in SWG order (one click, bought)
alozenConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_02", "@conversation/tatooine_imperial_trainer_2b:s_594a07fa", "trained_starships" },
	{ "pilot_imperial_navy_weapons_02", "@conversation/tatooine_imperial_trainer_2b:s_dbb5bf46", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_02", "@conversation/tatooine_imperial_trainer_2b:s_e73e5d21", "trained_procedures" },
	{ "pilot_imperial_navy_droid_02", "@conversation/tatooine_imperial_trainer_2b:s_c76594d7", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
alozenConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry = 1,
	m2_start = 2, m2_retry = 2,
	m3_accept = 3, m3_retry = 3
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
alozenConvoHandler.REWARD_SCREENS = {
	m1_pay = 1, m2_won = 2, m3_pay = 3
}

-- Per mission: head quest global, quest string key and the Imperial standing paid with the reward
alozenConvoHandler.MISSIONS = {
	{ head = "inspect_imperial_ss_4", questString = "TIER2_QUEST_STRING_4", standing = 75 },
	{ head = "escort_imperial_ss_5", questString = "TIER2_QUEST_STRING_5", standing = 50 },
	{ head = "recovery_imperial_ss_6", questString = "TIER2_QUEST_STRING_6", standing = 50 }
}

-- Screens that start a duty: screen -> duty quest global
alozenConvoHandler.DUTY_SCREENS = {
	duty_raiders = "destroy_duty_lok_imperial_ss_2a",
	duty_salvage = "recovery_duty_lok_imperial_ss_2b",
	duty_escort = "escort_duty_lok_imperial_ss_2c"
}

-- Any of Alozen's story chains or duties is running (the journal checks of the SWG isOnMission)
function alozenConvoHandler:isOnMission(pPlayer)
	local SS = StormSquadronScreenplay

	for _, mission in ipairs(self.MISSIONS) do
		if (SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)) then
			return true
		end
	end

	for n = 4, 6 do
		local duty = SS["TIER2_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, duty.type, duty.name)) then
			return true
		end
	end

	return false
end

-- SWG canFlyNonTrackDuty (tatooine_imperial_trainer_2b.java:247-254): any tier 1 skill is the nine-trainer rule
function alozenConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

function alozenConvoHandler:tier2Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 2)
end

function alozenConvoHandler:isPaid(pPlayer, n)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. StormSquadronScreenplay[self.MISSIONS[n].questString].name .. ":reward") == "1"
end

-- SWG canBuySkill1 (J2b:126-140): M2 paid, tier 1 done, fewer than four tier 2 skills, and the XP
function alozenConvoHandler:isReadyForTraining(pPlayer)
	if (not self:isPaid(pPlayer, 2)) then
		return false
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)) then
		return false
	end

	if (self:tier2Count(pPlayer) >= 4) then
		return false
	end

	return SpaceHelpers:hasExperienceForTraining(pPlayer, 2) == true
end

-- The id of the screen the player chose an option on (the session still holds it while the next screen is picked and handled)
function alozenConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: the topic chosen on training_menu buys the skill. Any failed guard sends the pilot back through the gates.
function alozenConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if (self:getLastScreenID(pPlayer) ~= "training_menu") then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	local convSession = CreatureObject(pPlayer):getConversationSession()
	local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()
	local link = LuaConversationScreen(pLastScreen):getOptionLink(selectedOption)
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

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		if (self:isReadyForTraining(pPlayer) and LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
			SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)

			-- The fourth skill completes tier 2
			if (CreatureObject(pPlayer):hasSkill(skill)) then
				local pGhost = CreatureObject(pPlayer):getPlayerObject()

				if (pGhost ~= nil) then
					local ghost = LuaPlayerObject(pGhost)

					if (ghost ~= nil and ghost:getPilotTier() == 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
						ghost:incrementPilotTier()
					end
				end
			end
		end

		if (not CreatureObject(pPlayer):hasSkill(skill)) then
			return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows tatooine_imperial_trainer_2b.java OnStartNpcConversation (:2404 on)
function alozenConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
	local SS = StormSquadronScreenplay

	local function status(key)
		return getQuestStatus(key) == "1"
	end

	local won, active, paid, failed = {}, {}, {}, {}

	for n = 1, 3 do
		local questString = SS[self.MISSIONS[n].questString]

		won[n] = SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
		active[n] = SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
		paid[n] = status(playerID .. questString.name .. ":reward")
		failed[n] = status(playerID .. questString.name .. ":attempted") and not won[n] and not active[n]
	end

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (faction == FACTIONREBEL or SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (standing < 0 or faction ~= FACTIONIMPERIAL) then
		return convoTemplate:getScreen("not_pilot")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (not SpaceHelpers:isStormSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (paid[3]) then
		return convoTemplate:getScreen("denner_transfer")
	elseif (won[3]) then
		return convoTemplate:getScreen("m3_won")
	elseif (failed[3]) then
		return convoTemplate:getScreen("m3_failed")
	elseif (self:tier2Count(pPlayer) >= 4 and paid[2]) then
		return convoTemplate:getScreen("m3_offer")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (paid[2]) then
		return convoTemplate:getScreen("duty_block")
	elseif (won[2]) then
		return convoTemplate:getScreen("m2_won")
	elseif (failed[2]) then
		return convoTemplate:getScreen("m2_failed")
	elseif (paid[1]) then
		return convoTemplate:getScreen("m2_start")
	elseif (won[1]) then
		return convoTemplate:getScreen("m1_won")
	elseif (failed[1]) then
		return convoTemplate:getScreen("m1_failed")
	end

	return convoTemplate:getScreen("greeting")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Imperial standing
function alozenConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. StormSquadronScreenplay[self.MISSIONS[n].questString].name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", self.MISSIONS[n].standing)
end

-- Replaces the options of a cloned screen by { reply, link } pairs
local function setOptions(clonedConversation, options)
	clonedConversation:removeAllOptions()

	for _, option in ipairs(options) do
		clonedConversation:addOption(option[1], option[2])
	end
end

function alozenConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()
	local SS = StormSquadronScreenplay

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
		setQuestStatus(playerID .. SS[self.MISSIONS[startMission].questString].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	end

	if (screenID == "greeting") then
		-- C-1
		local options = {}

		if (getQuestStatus(playerID .. SS.TIER2_ALOZEN_KEY) == "1") then
			options[#options + 1] = { "@conversation/tatooine_imperial_trainer_2b:s_2eaae5bc", "m1_late" }
		end

		if (getQuestStatus(playerID .. SS.TIER2_INITIATE_KEY) == "1") then
			options[#options + 1] = { "@conversation/tatooine_imperial_trainer_2b:s_53b0407b", "not_expected" }
		end

		options[#options + 1] = { "@conversation/tatooine_imperial_trainer_2b:s_a73dd488", "leave_alone" }

		setOptions(clonedConversation, options)
	elseif (screenID == "off_track") then
		-- C-2
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2b:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions" }
		})
	elseif (screenID == "duty_menu") then
		-- C-3: off track the training option is dropped
		local options = {
			{ "@conversation/tatooine_imperial_trainer_2b:s_8a202d7b", "duty_raiders" },
			{ "@conversation/tatooine_imperial_trainer_2b:s_d5ee9adc", "duty_escort" },
			{ "@conversation/tatooine_imperial_trainer_2b:s_5950b85e", "duty_salvage" }
		}

		if (SpaceHelpers:isStormSquadron(pPlayer)) then
			options[#options + 1] = { "@conversation/tatooine_imperial_trainer_2b:s_b0d3b474", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready" }
		end

		setOptions(clonedConversation, options)
	elseif (screenID == "training_offer") then
		-- C-3
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2b:s_7eed59f9", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready" }
		})
	elseif (screenID == "training_menu") then
		-- C-4: every skill the pilot lacks (pre-NGE topic menu)
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/tatooine_imperial_trainer_2b:s_ae26c22", "training_later")
	end

	return pClonedScreen
end
