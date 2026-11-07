-- Brother Vrovel (Vortex Squadron tier 2, Dantooine abandoned Rebel base) conversation handler; ported from SWG-Source dantooine_rebel_trainer_2.java with the pre-NGE client lines (feature vortex-tier2-vrovel). Training is two-step (topic, then confirm), free choice, bought with XP only. The hand-in of V3-FX graduates writes VORTEX_PILOT_KEY "2", the mission 4 reward writes "3". Hand-in comes before missions and training. Privileged players (isPrivileged) also get a GM branch. Pilots who finished tier 2 are handed to Brother Ezkiel (tier 3, not ported).
local SpaceHelpers = require("utils.space_helpers")

vrovelConvoHandler = conv_handler:new {}

-- Per mission: head quest global, the quest that counts as won, Rebel standing paid with the reward
vrovelConvoHandler.MISSIONS = {
	{ head = "escort_vortex_mission_1", wonType = "destroy_surpriseattack", wonName = "vortex_mission_1", standing = 75 },
	{ head = "escort_vortex_mission_2", wonType = "escort", wonName = "vortex_mission_2", standing = 75 },
	{ head = "recovery_vortex_mission_3", wonType = "recovery", wonName = "vortex_mission_3", standing = 75 },
	{ head = "inspect_vortex_mission_4", wonType = "inspect", wonName = "vortex_mission_4", standing = 75 }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
vrovelConvoHandler.START_SCREENS = {
	m1_accept = 1, m1_retry = 1, gm_mission1 = 1, gm_mission1_plain = 1,
	m2_accept = 2, m2_retry = 2, gm_mission2 = 2,
	m3_accept_yes_sir = 3, m3_accept_terminate = 3, m3_accept_very = 3, m3_accept_wartime = 3, m3_accept_understood = 3, m3_retry = 3, gm_mission3 = 3,
	m4_accept = 4, m4_retry = 4, gm_mission4 = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
vrovelConvoHandler.REWARD_SCREENS = {
	m1_won = 1, m2_pay_rest = 2, m2_pay_bonus = 2, m3_won = 3, m4_pay_close_call = 4, m4_pay_impressed = 4
}

-- Screens that start a duty: screen -> duty global
vrovelConvoHandler.DUTY_SCREENS = {
	duty_escort = "escort_duty_vortex_mission_5", gm_escort_duty = "escort_duty_vortex_mission_5",
	duty_recovery = "recovery_duty_vortex_mission_7", gm_recovery_duty = "recovery_duty_vortex_mission_7",
	duty_destroy = "destroy_duty_vortex_mission_6", gm_destroy_duty = "destroy_duty_vortex_mission_6"
}

-- The hand-in acceptances (J2 setVortexPilot 2)
vrovelConvoHandler.HANDIN_SCREENS = {
	handin_dont_salute = true, handin_promise = true, handin_pay = true
}

-- Pre-NGE free choice of the next skill: { skill, topic reply, confirm screen, trained screen }, in SWG order
vrovelConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_02", "@conversation/dantooine_rebel_trainer_2:s_c6c91897", "train_starships", "trained_starships" },
	{ "pilot_rebel_navy_weapons_02", "@conversation/dantooine_rebel_trainer_2:s_98d991e7", "train_weapons", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_02", "@conversation/dantooine_rebel_trainer_2:s_73ccefde", "train_procedures", "trained_procedures" },
	{ "pilot_rebel_navy_droid_02", "@conversation/dantooine_rebel_trainer_2:s_3c4ff185", "train_droid", "trained_droid" }
}

-- Screens that carry the player's name (%TU / %NU)
vrovelConvoHandler.NAME_SCREENS = {
	ezkiel_handoff = true, grounded = true, non_member = true, on_mission = true, handin = true,
	m4_failed_nonsense = true, m4_retry = true, m4_won = true, m4_pay_close_call = true, m4_offer = true, m4_short_version = true,
	m4_later = true, m4_madness = true, m4_desperate = true, m4_accept = true,
	m3_won = true, m3_lucky = true, m3_spend_bonus = true, m3_failed = true, m3_coward = true, m3_offer = true, m3_wonder = true,
	m3_accept_wartime = true, m3_save_him = true, m3_accept_yes_sir = true, m3_this_is_war = true, m3_accept_terminate = true,
	m3_accept_very = true, m3_accept_understood = true, m3_reconsider = true,
	m2_won = true, m2_pay_rest = true, m2_failed = true, m2_confession = true, m2_retry = true, m2_recover = true, m2_offer = true,
	m2_why_crystals = true, m2_accept = true, m2_not_playing = true, m2_coward = true,
	m1_won = true, m1_attitude = true, m1_trust_misplaced = true, m1_offer = true, m1_no_time = true, m1_urgent = true, m1_accept = true,
	training_offer = true, training_declined = true, duty_offer = true, duty_escort = true, duty_recovery = true, duty_destroy = true
}

-- Any of Vrovel's story chains or duties is running (J2 isOnMission)
function vrovelConvoHandler:isOnMission(pPlayer)
	local VS = VortexSquadronScreenplay

	for _, mission in ipairs(self.MISSIONS) do
		if (SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)) then
			return true
		end
	end

	return SpaceHelpers:isSpaceQuestActive(pPlayer, VS.TIER2_QUEST_STRING_DUTY_1.type, VS.TIER2_QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, VS.TIER2_QUEST_STRING_DUTY_2.type, VS.TIER2_QUEST_STRING_DUTY_2.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, VS.TIER2_QUEST_STRING_DUTY_3.type, VS.TIER2_QUEST_STRING_DUTY_3.name)
end

-- J2 canFlyNonTrackDuty (:344-351): tier 1 done and no quest
function vrovelConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- Tier 2 skills held (J2 skill count j)
function vrovelConvoHandler:tier2Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 2)
end

-- The VORTEX_PILOT_KEY value, nil when unset or empty
function vrovelConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. VortexSquadronScreenplay.VORTEX_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- J2 canBuySkill (:261): the pilot can buy a tier 2 skill now
function vrovelConvoHandler:isReadyForTraining(pPlayer)
	return self:getPilotFlag(pPlayer) ~= nil
		and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1)
		and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 2) == true
end

-- J2 isGm: Core3's admin flag
function vrovelConvoHandler:isTester(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return false
	end

	return PlayerObject(pGhost):isPrivileged() == true
end

-- The id of the screen the player chose an option on
function vrovelConvoHandler:getLastScreenID(pPlayer)
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

-- Two-step training: yes on a confirm screen (train_<x> -> trained_<x>) buys the skill with XP. Any failed guard
-- sends the pilot back through the gates.
function vrovelConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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

	if (LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 2
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() == 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2)) then
			ghost:incrementPilotTier()
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows dantooine_rebel_trainer_2.java OnStartNpcConversation, with the hand-in before the missions and training
function vrovelConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	local VS = VortexSquadronScreenplay
	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()
	local flag = self:getPilotFlag(pPlayer)

	local won, paid, failed = {}, {}, {}
	local count2 = self:tier2Count(pPlayer)

	for n, mission in ipairs(self.MISSIONS) do
		local name = VS["TIER2_QUEST_STRING_" .. n].name
		local active = SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)

		won[n] = SpaceHelpers:isSpaceQuestComplete(pPlayer, mission.wonType, mission.wonName)
		paid[n] = getQuestStatus(playerID .. name .. ":reward") == "1"
		failed[n] = getQuestStatus(playerID .. name .. ":attempted") == "1" and not won[n] and not active
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2) and flag ~= nil and paid[4]) then
		return convoTemplate:getScreen("ezkiel_handoff")
	elseif (faction == FACTIONIMPERIAL or SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("neutral_pilot")
	elseif (ghost:getFactionStanding("rebel") < 0 or faction ~= FACTIONREBEL) then
		return convoTemplate:getScreen("grounded")
	elseif (not SpaceHelpers:isVortexSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (flag == nil) then
		return convoTemplate:getScreen("non_member")
	elseif (self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer)) then
		return convoTemplate:getScreen("other_mission")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and SpaceHelpers:isRebelPilot(pPlayer) and flag == "1") then
		return convoTemplate:getScreen("handin")
	elseif (failed[4]) then
		return convoTemplate:getScreen("m4_failed")
	elseif (won[4] and not paid[4]) then
		return convoTemplate:getScreen("m4_won")
	elseif (count2 == 4 and not won[4]) then
		return convoTemplate:getScreen("m4_offer")
	elseif (won[3] and not paid[3]) then
		return convoTemplate:getScreen("m3_won")
	elseif (failed[3]) then
		return convoTemplate:getScreen("m3_failed")
	elseif (count2 == 3 and not won[3]) then
		return convoTemplate:getScreen("m3_offer")
	elseif (won[2] and not paid[2]) then
		return convoTemplate:getScreen("m2_won")
	elseif (failed[2]) then
		return convoTemplate:getScreen("m2_failed")
	elseif (count2 == 2 and not won[2]) then
		return convoTemplate:getScreen("m2_offer")
	elseif (failed[1]) then
		return convoTemplate:getScreen("m1_failed")
	elseif (won[1] and not paid[1]) then
		return convoTemplate:getScreen("m1_won")
	elseif (count2 >= 1 and not won[1]) then
		return convoTemplate:getScreen("m1_offer")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (flag == "2") then
		return convoTemplate:getScreen("duty_offer")
	end

	return convoTemplate:getScreen("private_property")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Rebel standing; mission 4 also graduates the pilot
function vrovelConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. VortexSquadronScreenplay["TIER2_QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)

	if (n == 4) then
		setQuestStatus(playerID .. VortexSquadronScreenplay.VORTEX_PILOT_KEY, "3")
	end
end

function vrovelConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()
	local VS = VortexSquadronScreenplay

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	if (self.NAME_SCREENS[screenID]) then
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
	local duty = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		setQuestStatus(playerID .. VS["TIER2_QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (self.HANDIN_SCREENS[screenID]) then
		if (self:getPilotFlag(pPlayer) == "1") then
			setQuestStatus(playerID .. VS.VORTEX_PILOT_KEY, "2")
		end
	elseif (screenID == "off_track") then
		-- C-1
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_c23a0a19", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions")
	elseif (screenID == "training_menu") then
		-- C-3: every skill the pilot lacks, then the leave reply
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_75a6ca67", "training_later")
	end

	-- C-2: the Developer/Tester reply for privileged players only
	if (screenID == "duty_offer") then
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_9b43a7ee", "duty_menu")
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_6b054777", "duty_later")

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu")
		end
	elseif (screenID == "handin") then
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_d049b613", "handin_mistaken")
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_45236b6c", "handin_vortex")

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu")
		end
	elseif (screenID == "private_property") then
		clonedConversation:removeAllOptions()

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu_sectors")
		end

		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_6f6eeaf3", "private_goodbye")
		clonedConversation:addOption("@conversation/dantooine_rebel_trainer_2:s_9f0a282", "private_leave")
	end

	return pClonedScreen
end
