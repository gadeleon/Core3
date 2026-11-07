-- Major Eker (Crimson Phoenix Squadron tier 2, Yavin 4 labor outpost) conversation handler; ported from SWG-Source yavin_rebel_trainer_2.java with the pre-NGE client lines (feature crimson-phoenix-tier2-eker-convo). Training is two-step (topic, then confirm), free choice, bought with XP only. The hand-in of Socuna graduates writes EKER_PILOT_KEY "2", the mission 4 reward writes "3". Hand-in comes before missions and training. Privileged players (isPrivileged) also get a GM branch. Pilots who finished tier 2 are handed to Arnecio Ulvaw'op (tier 3, not ported).
local SpaceHelpers = require("utils.space_helpers")

ekerConvoHandler = conv_handler:new {}

-- Per mission: head quest global, the quest that counts as won, Rebel standing paid with the reward
ekerConvoHandler.MISSIONS = {
	{ head = "escort_yavin_rebel_13", wonType = "escort", wonName = "yavin_rebel_13", standing = 75 },
	{ head = "inspect_yavin_rebel_14", wonType = "inspect", wonName = "yavin_rebel_14", standing = 75 },
	{ head = "inspect_yavin_rebel_15", wonType = "destroy_surpriseattack", wonName = "yavin_rebel_15", standing = 75 },
	{ head = "escort_yavin_rebel_16", wonType = "escort", wonName = "yavin_rebel_16", standing = 75 }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
ekerConvoHandler.START_SCREENS = {
	m1_accept_dismissed = 1, m1_accept_opinion = 1, m1_accept_right = 1, m1_accept_uploading = 1, m1_accept_priority = 1,
	m1_accept_immediately = 1, m1_retry_now = 1, m1_retry_knew = 1, gm_mission1 = 1,
	m2_accept_closing = 2, m2_accept_droid = 2, m2_retry = 2, m2_retry_rules = 2, gm_mission2 = 2,
	m3_accept = 3, m3_retry = 3, gm_mission3 = 3,
	m4_accept_trust = 4, m4_accept_go_back = 4, m4_accept_smuggle = 4, m4_retry = 4, gm_mission4 = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission)
ekerConvoHandler.REWARD_SCREENS = {
	m1_won = 1, m2_pay_good_work = 2, m2_pay_come_again = 2, m3_pay_another_post = 3, m3_pay_war_not_over = 3,
	m4_pay_right_about_you = 4, m4_pay_war_not_over = 4
}

-- Screens that start a duty: screen -> duty global
ekerConvoHandler.DUTY_SCREENS = {
	duty_recovery = "recovery_duty_yavin_rebel_12", gm_recovery_duty = "recovery_duty_yavin_rebel_12",
	duty_escort = "escort_duty_yavin_rebel_10", gm_escort_duty = "escort_duty_yavin_rebel_10",
	duty_destroy = "destroy_duty_yavin_rebel_9", gm_destroy_duty = "destroy_duty_yavin_rebel_9"
}

-- The hand-in acceptances (JE makeEkerPilot 2)
ekerConvoHandler.HANDIN_SCREENS = {
	handin_dismissed = true, handin_duty_menu = true
}

-- Pre-NGE free choice of the next skill: { skill, topic reply, confirm screen, trained screen }, in SWG order
ekerConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_02", "@conversation/yavin_rebel_trainer_2:s_c6c91897", "train_starships", "trained_starships" },
	{ "pilot_rebel_navy_weapons_02", "@conversation/yavin_rebel_trainer_2:s_98d991e7", "train_weapons", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_02", "@conversation/yavin_rebel_trainer_2:s_73ccefde", "train_procedures", "trained_procedures" },
	{ "pilot_rebel_navy_droid_02", "@conversation/yavin_rebel_trainer_2:s_3c4ff185", "train_droid", "trained_droid" }
}

-- Screens that carry the player's name (%TU / %NU)
ekerConvoHandler.NAME_SCREENS = {
	tier3_handoff = true, tier3_teaching = true, tier3_honor = true, grounded = true, tier3_veteran = true, m2_offer = true,
	m3_offer = true, m3_arrest = true, m4_so_long = true, m4_offer = true, m4_see_you_around = true
}

-- Any of Eker's story chains or duties is running (JE isOnMission)
function ekerConvoHandler:isOnMission(pPlayer)
	local CP = CrimsonPhoenixSquadronScreenplay

	for _, mission in ipairs(self.MISSIONS) do
		if (SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)) then
			return true
		end
	end

	return SpaceHelpers:isSpaceQuestActive(pPlayer, CP.TIER2_QUEST_STRING_DUTY_1.type, CP.TIER2_QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, CP.TIER2_QUEST_STRING_DUTY_2.type, CP.TIER2_QUEST_STRING_DUTY_2.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, CP.TIER2_QUEST_STRING_DUTY_3.type, CP.TIER2_QUEST_STRING_DUTY_3.name)
end

-- JE canFlyNonTrackDuty: tier 1 done and no quest
function ekerConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- Tier 2 skills held (JE skill count j)
function ekerConvoHandler:tier2Count(pPlayer)
	return SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 2)
end

-- The EKER_PILOT_KEY value, nil when unset or empty
function ekerConvoHandler:getPilotFlag(pPlayer)
	local value = getQuestStatus(CreatureObject(pPlayer):getObjectID() .. CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY)

	if (value == nil or value == "") then
		return nil
	end

	return value
end

-- JE canBuySkill: the pilot can buy a tier 2 skill now
function ekerConvoHandler:isReadyForTraining(pPlayer)
	return self:getPilotFlag(pPlayer) ~= nil
		and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1)
		and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 2) == true
end

-- JE isGm: Core3's admin flag
function ekerConvoHandler:isTester(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return false
	end

	return PlayerObject(pGhost):isPrivileged() == true
end

-- The id of the screen the player chose an option on
function ekerConvoHandler:getLastScreenID(pPlayer)
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
function ekerConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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

-- First screen (side-effect free). Gate order follows yavin_rebel_trainer_2.java OnStartNpcConversation, with the hand-in before the missions and training
function ekerConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	local CP = CrimsonPhoenixSquadronScreenplay
	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()
	local flag = self:getPilotFlag(pPlayer)

	local won, paid, failed = {}, {}, {}
	local count2 = self:tier2Count(pPlayer)

	for n, mission in ipairs(self.MISSIONS) do
		local name = CP["TIER2_QUEST_STRING_" .. n].name
		local active = SpaceHelpers:isSpaceQuestChainActive(pPlayer, mission.head)

		won[n] = SpaceHelpers:isSpaceQuestComplete(pPlayer, mission.wonType, mission.wonName)
		paid[n] = getQuestStatus(playerID .. name .. ":reward") == "1"
		failed[n] = getQuestStatus(playerID .. name .. ":attempted") == "1" and not won[n] and not active
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 2) and flag ~= nil and paid[4]) then
		return convoTemplate:getScreen("tier3_handoff")
	elseif (faction == FACTIONIMPERIAL or SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("neutral_pilot")
	elseif (ghost:getFactionStanding("rebel") < 0 or faction ~= FACTIONREBEL) then
		return convoTemplate:getScreen("grounded")
	elseif (not SpaceHelpers:isCrimsonPhoenixSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (flag == nil) then
		return convoTemplate:getScreen("non_member")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3)) then
		return convoTemplate:getScreen("tier3_veteran")
	elseif (self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer)) then
		return convoTemplate:getScreen("other_mission")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and flag == "1") then
		return convoTemplate:getScreen("handin")
	elseif (failed[2]) then
		return convoTemplate:getScreen("m2_failed")
	elseif (won[2] and not paid[2]) then
		return convoTemplate:getScreen("m2_won")
	elseif (count2 == 2 and not won[2]) then
		return convoTemplate:getScreen("m2_offer")
	elseif (failed[3]) then
		return convoTemplate:getScreen("m3_failed")
	elseif (won[3] and not paid[3]) then
		return convoTemplate:getScreen("m3_won")
	elseif (count2 == 3 and not won[3]) then
		return convoTemplate:getScreen("m3_offer")
	elseif (failed[4]) then
		return convoTemplate:getScreen("m4_failed")
	elseif (won[4] and not paid[4]) then
		return convoTemplate:getScreen("m4_won")
	elseif (count2 == 4 and not won[4]) then
		return convoTemplate:getScreen("m4_offer")
	elseif (won[1] and not paid[1]) then
		return convoTemplate:getScreen("m1_won")
	elseif (failed[1]) then
		return convoTemplate:getScreen("m1_failed")
	elseif (count2 >= 1 and not won[1]) then
		return convoTemplate:getScreen("m1_offer")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_offer")
	elseif (flag == "2") then
		return convoTemplate:getScreen("duty_offer")
	end

	return convoTemplate:getScreen("too_busy")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Rebel standing; mission 4 also writes flag "3"
function ekerConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. CrimsonPhoenixSquadronScreenplay["TIER2_QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)

	if (n == 4) then
		setQuestStatus(playerID .. CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY, "3")
	end
end

function ekerConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()
	local CP = CrimsonPhoenixSquadronScreenplay

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
		setQuestStatus(playerID .. CP["TIER2_QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (self.HANDIN_SCREENS[screenID]) then
		if (self:getPilotFlag(pPlayer) == "1") then
			setQuestStatus(playerID .. CP.EKER_PILOT_KEY, "2")
		end
	elseif (screenID == "off_track") then
		-- C-1
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_1583743c", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions")
	elseif (screenID == "training_menu") then
		-- C-3: every skill the pilot lacks, then the leave reply
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end

		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_fabecb04", "training_passing_up")
	end

	-- C-2: the Developer/Tester reply for privileged players only
	if (screenID == "duty_offer") then
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_2bf9b1f7", "duty_menu")
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_72c594c9", "duty_later")

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu")
		end
	elseif (screenID == "handin") then
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_6a1c47d9", "handin_dismissed")
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_c1015a4d", "handin_is_that_right")
		clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_f685a04e", "handin_confession")

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu")
		end
	elseif (screenID == "duty_later") then
		clonedConversation:removeAllOptions()

		if (self:isTester(pPlayer)) then
			clonedConversation:addOption("@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu")
		else
			clonedConversation:setStopConversation(true)
		end
	end

	return pClonedScreen
end
