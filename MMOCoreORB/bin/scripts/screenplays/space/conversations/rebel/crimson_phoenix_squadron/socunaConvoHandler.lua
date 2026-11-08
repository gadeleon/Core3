-- Commander Da'la Socuna (Crimson Phoenix Squadron tier 1, Mos Espa cantina) conversation handler; ported from SWG-Source tatooine_rebel_trainer_1.java with the pre-NGE client lines (feature crimson-phoenix-tier1-da-la-socuna). Training is one click per skill, free choice (pre-NGE); the promotion screen hands off to Major Eker (tier 2, ekerConvoHandler) through CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY.
local SpaceHelpers = require("utils.space_helpers")

socunaConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the next skill: { skill, topic reply, screen }, in SWG order
socunaConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_01", "@conversation/tatooine_rebel_trainer_1:s_26970ef", "trained_starships" },
	{ "pilot_rebel_navy_weapons_01", "@conversation/tatooine_rebel_trainer_1:s_d912490", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_01", "@conversation/tatooine_rebel_trainer_1:s_8c272224", "trained_procedures" },
	{ "pilot_rebel_navy_droid_01", "@conversation/tatooine_rebel_trainer_1:s_9480f430", "trained_droid" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
socunaConvoHandler.START_SCREENS = {
	m1_focus = 1, m1_handle_it = 1, m1_better = 1, m1_outstanding = 1, m1_four_point = 1,
	m1f_unacceptable = 1, m1f_try_again = 1, m1f_renewed = 1, m1s_prove_it = 1, m1s_good_luck = 1, m1s_hope_so = 1, m1s_get_back = 1,
	m2_take_off = 2, m2_outstanding = 2, m2_excellent = 2,
	m2f_do_something = 2, m2f_learning = 2, m2f_no_sense = 2, m2f_see_you = 2, m2f_try_again = 2,
	m3_death_of_me = 3, m3_affirmative = 3, m3_critical = 3, m3f_fine = 3, m3f_save_it = 3, m3f_make_it_happen = 3,
	m4_younger = 4, m4_superb = 4, m4_rallying = 4, m4f_whats_wrong = 4, m4f_outstanding = 4, m4f_force = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
socunaConvoHandler.REWARD_SCREENS = {
	m1r_probably = 1, m1r_lucky = 1, m1r_consider = 1, m1r_we_wait = 1, m1r_digest = 1, m1r_bad_news = 1,
	m2r_best = 2, m2r_outstanding = 2, m2r_anticipated = 2,
	m3r_lucky = 3, m3r_outstanding = 3, m3r_beautifully = 3,
	m4r_dismissed = 4, m4r_great_work = 4, m4r_honor = 4
}

-- Per mission: head quest global, Rebel standing paid with the reward
socunaConvoHandler.MISSIONS = {
	{ head = "patrol_tatooine_rebel_1", standing = 25 },
	{ head = "destroy_tatooine_rebel_3", standing = 50 },
	{ head = "patrol_tatooine_rebel_2", standing = 50 },
	{ head = "assassinate_tatooine_rebel_4", standing = 75 }
}

-- Conditional links: screen -> { { reply, link when the test holds, link otherwise }, ..., test }
socunaConvoHandler.CONDITIONAL_LINKS = {
	non_member = { { "@conversation/tatooine_rebel_trainer_1:s_1583743c", "non_member_duty_offer", "non_member_no_missions" }, test = "canFlyNonTrackDuty" },
	m3r_lucky = { { "@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_bandolier", "m3r_flightsuit" }, test = "isWookieeOrIthorian" },
	m3r_outstanding = { { "@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_bandolier", "m3r_flightsuit" }, test = "isWookieeOrIthorian" },
	m3r_beautifully = { { "@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_bandolier", "m3r_flightsuit" }, test = "isWookieeOrIthorian" }
}

-- C-2: the eight oath screens -> { reply without a ship, its ship line, reply with a ship }
socunaConvoHandler.OATH_SCREENS = {
	oath_regret = { "@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise", "@conversation/tatooine_rebel_trainer_1:s_c5cc6139" },
	oath_all_kinds = { "@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise", "@conversation/tatooine_rebel_trainer_1:s_c5cc6139" },
	oath_youre_in = { "@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise", "@conversation/tatooine_rebel_trainer_1:s_c5cc6139" },
	oath_cannon_fodder = { "@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise", "@conversation/tatooine_rebel_trainer_1:s_c5cc6139" },
	oath_enthusiasm = { "@conversation/tatooine_rebel_trainer_1:s_bd53784c", "ship_not_a_problem", "@conversation/tatooine_rebel_trainer_1:s_4136c2df" },
	oath_we_begin = { "@conversation/tatooine_rebel_trainer_1:s_bd53784c", "ship_covered", "@conversation/tatooine_rebel_trainer_1:s_4136c2df" },
	oath_space_navy = { "@conversation/tatooine_rebel_trainer_1:s_aed0dff", "ship_yours", "@conversation/tatooine_rebel_trainer_1:s_4136c2df" },
	oath_right_decision = { "@conversation/tatooine_rebel_trainer_1:s_a42932d7", "ship_understood", "@conversation/tatooine_rebel_trainer_1:s_4136c2df" }
}

-- Screens that grant the starter ship to a pilot who has none (J:331-334)
socunaConvoHandler.SHIP_SCREENS = {
	ship_surprise = true, ship_not_a_problem = true, ship_covered = true, ship_yours = true, ship_understood = true, lost_ship = true
}

-- Screens that carry the player's name (%TU / %NU)
socunaConvoHandler.NAME_SCREENS = {
	grounded = true, grounded_bad_news = true, grounded_framed = true, m3_impatient = true, enlist_ground = true,
	enlist_recruiter = true, eker_respect = true, eker_great_things = true, eker_with_you = true
}

-- Screens that add the Major Eker waypoint (J giveMajorEkerWaypoint)
socunaConvoHandler.WAYPOINT_SCREENS = {
	eker_respect = true, eker_good_luck = true, graduated_how = true
}

-- Any of Socuna's story chains or duties is running (the journal checks of the SWG isOnMission)
function socunaConvoHandler:isOnMission(pPlayer)
	local CP = CrimsonPhoenixSquadronScreenplay

	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_rebel_1")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_tatooine_rebel_3")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_rebel_2")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_tatooine_rebel_4")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, CP.QUEST_STRING_DUTY_1.type, CP.QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, CP.QUEST_STRING_DUTY_2.type, CP.QUEST_STRING_DUTY_2.name)
end

-- SWG canFlyNonTrackDuty (tatooine_rebel_trainer_1.java:161-168): any tier 1 skill and no quest
function socunaConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The pilot can be trained now: mission 4 paid, tier 1 unfinished, the first skill free and later ones paid for in XP
function socunaConvoHandler:isReadyForTraining(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (getQuestStatus(playerID .. CrimsonPhoenixSquadronScreenplay.QUEST_STRING_4.name .. ":reward") ~= "1") then
		return false
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1)) then
		return false
	end

	return not SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1) or SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true
end

-- tatooine_rebel_trainer_1.java:181-185
function socunaConvoHandler:isWookieeOrIthorian(pPlayer)
	local species = CreatureObject(pPlayer):getSpecies()

	return species == SPECIES_WOOKIEE or species == SPECIES_ITHORIAN
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function socunaConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: the topic chosen on training_first / training_more grants the skill. The first
-- tier 1 skill is free, later ones are bought. Any failed guard sends the pilot back through the gates.
function socunaConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local lastScreen = self:getLastScreenID(pPlayer) or ""

	if (lastScreen ~= "training_first" and lastScreen ~= "training_more") then
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

	if (CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	if (not SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1)) then
		-- The first skill is free
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, false)
	elseif (LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	-- The fourth skill completes tier 1
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() == 1 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1)) then
			ghost:incrementPilotTier()
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

-- First screen (side-effect free). Gate order follows tatooine_rebel_trainer_1.java OnStartNpcConversation (:15994 on)
function socunaConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("not_a_pilot")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("not_a_pilot")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("not_a_pilot")
	end

	local CP = CrimsonPhoenixSquadronScreenplay

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	local function status(key)
		return getQuestStatus(key) == "1"
	end

	local active = {
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_rebel_1"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_tatooine_rebel_3"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tatooine_rebel_2"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_tatooine_rebel_4")
	}

	local patrol1Done = complete(CP.QUEST_STRING_1)

	local won = {
		patrol1Done and complete(CP.QUEST_STRING_1_SIDE),
		complete(CP.QUEST_STRING_2),
		complete(CP.QUEST_STRING_3) and complete(CP.QUEST_STRING_3_SIDE),
		complete(CP.QUEST_STRING_4)
	}

	local questStrings = { CP.QUEST_STRING_1, CP.QUEST_STRING_2, CP.QUEST_STRING_3, CP.QUEST_STRING_4 }
	local reward, failed = {}, {}

	for n = 1, 4 do
		reward[n] = status(playerID .. questStrings[n].name .. ":reward")
		failed[n] = status(playerID .. questStrings[n].name .. ":attempted") and not won[n] and not active[n]
	end

	local isRebelPilot = SpaceHelpers:isRebelPilot(pPlayer)
	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)
	local ekerFlag = getQuestStatus(playerID .. CP.EKER_PILOT_KEY)

	-- Help loop while mission 1 is running
	if (hasShip and active[1]) then
		return convoTemplate:getScreen("first_mission_help")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("privateer_pilot")
	elseif (faction == FACTIONIMPERIAL or SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	elseif (faction ~= FACTIONREBEL) then
		return convoTemplate:getScreen(isRebelPilot and "grounded" or "not_a_pilot")
	elseif (not isRebelPilot) then
		return convoTemplate:getScreen("recruitment")
	elseif (not SpaceHelpers:isCrimsonPhoenixSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_member")
	elseif (not hasShip) then
		return convoTemplate:getScreen("lost_ship")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	-- Pre-NGE gate: a pilot who turned against the Alliance
	elseif (ghost:getFactionStanding("rebel") < 0) then
		return convoTemplate:getScreen("grounded")
	-- SWG hasSpaceFlag(player, "ekerPilot"): any non-empty value is graduated
	elseif (ekerFlag ~= nil and ekerFlag ~= "") then
		return convoTemplate:getScreen("graduated")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and reward[4]) then
		return convoTemplate:getScreen("tier_done")
	elseif (failed[1] and not patrol1Done) then
		return convoTemplate:getScreen("mission1_patrol_failed")
	elseif (failed[1]) then
		return convoTemplate:getScreen("mission1_failed")
	elseif (failed[2]) then
		return convoTemplate:getScreen("mission2_failed")
	elseif (failed[3]) then
		return convoTemplate:getScreen("mission3_failed")
	elseif (failed[4]) then
		return convoTemplate:getScreen("mission4_failed")
	-- Missions: offer until won, report until paid
	elseif (not won[1]) then
		return convoTemplate:getScreen("mission1_offer")
	elseif (not reward[1]) then
		return convoTemplate:getScreen("mission1_report")
	elseif (not won[2]) then
		return convoTemplate:getScreen("mission2_offer")
	elseif (not reward[2]) then
		return convoTemplate:getScreen("mission2_report")
	elseif (not won[3]) then
		return convoTemplate:getScreen("mission3_offer")
	elseif (not reward[3]) then
		return convoTemplate:getScreen("mission3_report")
	elseif (not won[4]) then
		return convoTemplate:getScreen("mission4_offer")
	elseif (not reward[4]) then
		return convoTemplate:getScreen("mission4_report")
	elseif (not SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1)) then
		return convoTemplate:getScreen("training_first")
	elseif (SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true) then
		return convoTemplate:getScreen("training_more")
	end

	return convoTemplate:getScreen("duty_missions")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Rebel standing
function socunaConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. CrimsonPhoenixSquadronScreenplay["QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)
end

-- The sign-up: novice box, squadron, pilot tier 1 (tatooine_rebel_trainer_1.java:197-201)
function socunaConvoHandler:signUp(pPlayer, ghost)
	SpaceHelpers:grantNovicePilot(pPlayer, "rebelPilot")
	SpaceHelpers:setSquadronType(pPlayer, CRIMSON_PHOENIX_SQUADRON)

	if (ghost:getPilotTier() < 1) then
		ghost:incrementPilotTier()
	end
end

function socunaConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
	local conditional = self.CONDITIONAL_LINKS[screenID]
	local oath = self.OATH_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		setQuestStatus(playerID .. CP["QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	end

	if (conditional ~= nil) then
		-- C-1, C-3
		local holds = self[conditional.test](self, pPlayer)

		clonedConversation:removeAllOptions()

		for _, entry in ipairs(conditional) do
			clonedConversation:addOption(entry[1], holds and entry[2] or entry[3])
		end
	elseif (oath ~= nil) then
		self:signUp(pPlayer, ghost)

		-- C-2
		clonedConversation:removeAllOptions()

		if (SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			clonedConversation:addOption(oath[3], "first_assignment")
		else
			clonedConversation:addOption(oath[1], oath[2])
		end
	elseif (self.SHIP_SCREENS[screenID]) then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "rebel")
		end
	elseif (screenID == "training_first" or screenID == "training_more") then
		-- C-4: every skill the pilot lacks (pre-NGE topic menu)
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end
	elseif (screenID == "destroy_duty") then
		destroy_duty_tatooine_rebel_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_tatooine_rebel_7:startQuest(pPlayer, pNpc)
	elseif (screenID == "tier_done") then
		setQuestStatus(playerID .. CP.EKER_PILOT_KEY, "1")
	end

	if (self.WAYPOINT_SCREENS[screenID]) then
		SpaceHelpers:addEkerWaypoint(pPlayer)
	end

	return pClonedScreen
end
