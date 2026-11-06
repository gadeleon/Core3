-- Commander Jhon Oberhaur (Storm Squadron tier 2) conversation handler; ported from SWG-Source tatooine_imperial_trainer_2.java. Training and the NGE-only gates: pre-NGE client lines (feature storm-tier2-oberhaur).
local SpaceHelpers = require("utils.space_helpers")

oberhaurConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the tier 2 skill: { skill, topic reply, trained screen }, in SWG order (one click, bought)
oberhaurConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_02", "@conversation/tatooine_imperial_trainer_2:s_594a07fa", "trained_starships" },
	{ "pilot_imperial_navy_weapons_02", "@conversation/tatooine_imperial_trainer_2:s_dbb5bf46", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_02", "@conversation/tatooine_imperial_trainer_2:s_e73e5d21", "trained_procedures" },
	{ "pilot_imperial_navy_droid_02", "@conversation/tatooine_imperial_trainer_2:s_c76594d7", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
oberhaurConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry = 1,
	m2_accept = 2, m2_retry = 2
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
oberhaurConvoHandler.REWARD_SCREENS = {
	m1_pay = 1, m2_outstanding = 2, claw_pay = 3
}

-- Per mission: head quest global (the Kimogila's Claw is granted by the Nym technicians, not by Oberhaur)
oberhaurConvoHandler.MISSIONS = {
	{ head = "inspect_imperial_ss_1", questString = "TIER2_QUEST_STRING_1" },
	{ head = "recovery_imperial_ss_2", questString = "TIER2_QUEST_STRING_2" },
	{ head = "assassinate_imperial_ss_3", questString = "TIER2_QUEST_STRING_3" }
}

-- Screens that start a duty: screen -> duty quest global
oberhaurConvoHandler.DUTY_SCREENS = {
	duty_fleet = "destroy_duty_lok_imperial_ss_1a",
	duty_smugglers = "recovery_duty_lok_imperial_ss_1b",
	duty_pirates = "escort_duty_lok_imperial_ss_1c"
}

-- Standing paid with every story reward
oberhaurConvoHandler.REWARD_STANDING = 75

-- Any of Oberhaur's story chains or duties is running (the journal checks of the SWG isOnMission)
function oberhaurConvoHandler:isOnMission(pPlayer)
	local SS = StormSquadronScreenplay

	for _, mission in ipairs(self.MISSIONS) do
		if (SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)) then
			return true
		end
	end

	for n = 1, 3 do
		local duty = SS["TIER2_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, duty.type, duty.name)) then
			return true
		end
	end

	return false
end

-- SWG canFlyNonTrackDuty (tatooine_imperial_trainer_2.java:227-234): any tier 1 skill is the nine-trainer rule
function oberhaurConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

function oberhaurConvoHandler:tier2Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 2)
end

function oberhaurConvoHandler:isPaid(pPlayer, n)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. StormSquadronScreenplay[self.MISSIONS[n].questString].name .. ":reward") == "1"
end

-- SWG readyforTraining / readyForTraining2: M2 paid, tier 1 done, XP, and the second skill only after the Claw is paid
function oberhaurConvoHandler:isReadyForTraining(pPlayer)
	if (not self:isPaid(pPlayer, 2)) then
		return false
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)) then
		return false
	end

	local count = self:tier2Count(pPlayer)

	if (count >= 2) then
		return false
	end

	if (SpaceHelpers:hasExperienceForTraining(pPlayer, 2) ~= true) then
		return false
	end

	return self:isPaid(pPlayer, 3) or count == 0
end

-- Approximation of space_quest.hasCertifiedNonNewbieShip (D-10): a certified ship and a non-basic, non-yacht ship device in the datapad
function oberhaurConvoHandler:hasHyperspaceShip(pPlayer)
	if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
		return false
	end

	local pDatapad = SceneObject(pPlayer):getSlottedObject("datapad")

	if (pDatapad == nil) then
		return false
	end

	for i = 1, SceneObject(pDatapad):getContainerObjectsSize(), 1 do
		local pObject = SceneObject(pDatapad):getContainerObject(i - 1)

		if (pObject ~= nil) then
			local path = SceneObject(pObject):getTemplateObjectPath()

			if (path ~= nil and string.find(path, "^object/intangible/ship/") ~= nil and string.find(path, "_pcd%.iff$") ~= nil
				and string.find(path, "basic", 1, true) == nil and path ~= "object/intangible/ship/sorosuub_space_yacht_pcd.iff") then
				return true
			end
		end
	end

	return false
end

-- State of the transfer form for the application: none (no form, or no tier 1 promotion, Q-2), unsigned, wrong_name or valid
function oberhaurConvoHandler:formState(pPlayer)
	local SS = StormSquadronScreenplay
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (getQuestStatus(playerID .. SS.SERIES_COMPLETE_KEY) ~= "1") then
		return "none"
	end

	local pForm = SS:getTransferForm(pPlayer)

	if (pForm == nil) then
		return "none"
	end

	local signature = SS:getTransferFormSignature(pForm)

	if (signature == "") then
		return "unsigned"
	end

	if (signature ~= SceneObject(pPlayer):getDisplayedName()) then
		return "wrong_name"
	end

	return "valid"
end

-- SWG removeAuthOfTransfer (J2:332-354): every top-level inventory item of the form template
function oberhaurConvoHandler:removeTransferForms(pPlayer)
	local pInventory = CreatureObject(pPlayer):getSlottedObject("inventory")

	if (pInventory == nil) then
		return
	end

	local forms = {}

	for i = 1, SceneObject(pInventory):getContainerObjectsSize(), 1 do
		local pObject = SceneObject(pInventory):getContainerObject(i - 1)

		if (pObject ~= nil and SceneObject(pObject):getTemplateObjectPath() == StormSquadronScreenplay.TRANSFER_FORM) then
			forms[#forms + 1] = pObject
		end
	end

	for _, pForm in ipairs(forms) do
		SceneObject(pForm):destroyObjectFromWorld()
		SceneObject(pForm):destroyObjectFromDatabase()
	end
end

-- The id of the screen the player chose an option on (the session still holds it while the next screen is picked and handled)
function oberhaurConvoHandler:getLastScreenID(pPlayer)
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
function oberhaurConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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
		end

		if (not CreatureObject(pPlayer):hasSkill(skill)) then
			return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows tatooine_imperial_trainer_2.java OnStartNpcConversation (:5287 on)
function oberhaurConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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
		return convoTemplate:getScreen("grounded")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (not SpaceHelpers:isStormSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	end

	local count2 = self:tier2Count(pPlayer)

	if (status(playerID .. SS.TIER2_ALOZEN_KEY)) then
		return convoTemplate:getScreen("report_to_alozen")
	elseif (count2 >= 2 and paid[3]) then
		return convoTemplate:getScreen("alozen_orders")
	elseif (paid[3] and self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (paid[3]) then
		return convoTemplate:getScreen("claw_duties")
	elseif (won[3]) then
		return convoTemplate:getScreen("claw_won")
	elseif (status(playerID .. SS.TIER2_FINDING_AGENT_KEY)) then
		return convoTemplate:getScreen("find_morv")
	elseif (count2 > 0 and paid[2]) then
		return convoTemplate:getScreen("m3_offer")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (paid[2]) then
		return convoTemplate:getScreen("duty_after_m2")
	elseif (won[2]) then
		return convoTemplate:getScreen("m2_won")
	elseif (failed[2]) then
		return convoTemplate:getScreen("m2_failed")
	elseif (paid[1]) then
		return convoTemplate:getScreen("m2_offer")
	elseif (won[1]) then
		return convoTemplate:getScreen("m1_won")
	elseif (failed[1]) then
		return convoTemplate:getScreen("m1_failed")
	elseif (status(playerID .. SS.TIER2_INITIATE_KEY)) then
		return convoTemplate:getScreen("m1_offer")
	end

	return convoTemplate:getScreen("greeting")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Imperial standing
function oberhaurConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. StormSquadronScreenplay[self.MISSIONS[n].questString].name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", self.REWARD_STANDING)
end

-- Replaces the options of a cloned screen by { reply, link } pairs
local function setOptions(clonedConversation, options)
	clonedConversation:removeAllOptions()

	for _, option in ipairs(options) do
		clonedConversation:addOption(option[1], option[2])
	end
end

function oberhaurConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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

		if (screenID == "claw_pay") then
			removeQuestStatus(playerID .. SS.TIER2_FINDING_AGENT_KEY)
		end
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (screenID == "form_accepted") then
		self:removeTransferForms(pPlayer)
	elseif (screenID == "initiate") then
		setQuestStatus(playerID .. SS.TIER2_INITIATE_KEY, 1)
	elseif (screenID == "m3_codephrase") then
		setQuestStatus(playerID .. SS.TIER2_FINDING_AGENT_KEY, 1)
	elseif (screenID == "yavin_alozen") then
		setQuestStatus(playerID .. SS.TIER2_ALOZEN_KEY, 1)
	end

	if (screenID == "on_mission") then
		-- C-1
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2:s_a30c1a53", "on_mission_outstanding" },
			{ "@conversation/tatooine_imperial_trainer_2:s_8d17fc6e", self:hasHyperspaceShip(pPlayer) and "travel_capable" or "travel_need_ship" }
		})
	elseif (screenID == "m1_accept") then
		-- C-1
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2:s_2c4789b", "m1_return" },
			{ "@conversation/tatooine_imperial_trainer_2:s_401fdcbd", self:hasHyperspaceShip(pPlayer) and "travel_capable" or "travel_need_ship" }
		})
	elseif (screenID == "off_track") then
		-- C-2
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions" }
		})
	elseif (screenID == "duty_menu") then
		-- C-3: off track the training option is dropped (D-9)
		local options = {
			{ "@conversation/tatooine_imperial_trainer_2:s_45f4f7db", "duty_fleet" },
			{ "@conversation/tatooine_imperial_trainer_2:s_a6363375", "duty_smugglers" },
			{ "@conversation/tatooine_imperial_trainer_2:s_721e2818", "duty_pirates" }
		}

		if (SpaceHelpers:isStormSquadron(pPlayer)) then
			options[#options + 1] = { "@conversation/tatooine_imperial_trainer_2:s_b0d3b474", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready" }
		end

		setOptions(clonedConversation, options)
	elseif (screenID == "training_offer") then
		-- C-3
		setOptions(clonedConversation, {
			{ "@conversation/tatooine_imperial_trainer_2:s_a4faf714", self:isReadyForTraining(pPlayer) and "training_menu" or "training_not_ready" }
		})
	elseif (screenID == "training_menu") then
		-- C-4: every skill the pilot lacks (pre-NGE topic menu)
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/tatooine_imperial_trainer_2:s_ae26c22", "training_later")
	elseif (screenID == "apply") then
		-- C-6: exactly one option
		local state = self:formState(pPlayer)
		local links = { unsigned = "form_unsigned", wrong_name = "form_wrong_name", valid = "form_accepted" }

		if (state == "none") then
			setOptions(clonedConversation, { { "@conversation/tatooine_imperial_trainer_2:s_58c1df5a", "no_form" } })
		else
			setOptions(clonedConversation, { { "@conversation/tatooine_imperial_trainer_2:s_e3d28c95", links[state] } })
		end
	end

	return pClonedScreen
end
