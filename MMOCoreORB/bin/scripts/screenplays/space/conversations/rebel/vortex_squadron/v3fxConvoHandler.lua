-- V3-FX (Vortex Squadron tier 1, Moenia gazebo) conversation handler; ported from SWG-Source naboo_rebel_trainer_1.java with the pre-NGE client lines (feature vortex-tier1-v3-fx). Training is one click per skill, free choice (pre-NGE); the promotion screen hands off to Brother Vrovel (tier 2, not ported yet) through VortexSquadronScreenplay.VORTEX_PILOT_KEY.
local SpaceHelpers = require("utils.space_helpers")

v3fxConvoHandler = conv_handler:new {}

-- Pre-NGE free choice of the next skill: { skill, topic reply, male screen, female screen }, in SWG order
v3fxConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_01", "@conversation/naboo_rebel_trainer_1:s_26970ef", "trained_starships_male", "trained_starships_female" },
	{ "pilot_rebel_navy_weapons_01", "@conversation/naboo_rebel_trainer_1:s_3fa70900", "trained_weapons", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_01", "@conversation/naboo_rebel_trainer_1:s_8c272224", "trained_procedures", "trained_procedures" },
	{ "pilot_rebel_navy_droid_01", "@conversation/naboo_rebel_trainer_1:s_9480f430", "trained_droid_male", "trained_droid_female" }
}

-- Screens that start a story mission: screen -> mission number (the head chain is started on display)
v3fxConvoHandler.START_SCREENS = {
	mission1_failed = 1, m1_frontier = 1, m1_glorious = 1, m1_four_point = 1,
	mission2_failed = 2, m2_why_not = 2, m2_um_yes = 2, m2_good_to_hear = 2,
	mission3_failed = 3, m3_thank_maker = 3, m3_good_luck = 3, m3_critical = 3,
	mission4_failed = 4, m4_splendid = 4, m4_rally = 4, m4_tie_forces = 4
}

-- Screens that pay a mission reward: screen -> mission number (paid once per mission, on display)
v3fxConvoHandler.REWARD_SCREENS = {
	mission1_won = 1, mission2_won = 2, mission3_won = 3, mission4_won = 4
}

-- Per mission: head quest global, Rebel standing paid with the reward
v3fxConvoHandler.MISSIONS = {
	{ head = "patrol_naboo_rebel_1", standing = 25 },
	{ head = "destroy_naboo_rebel_2", standing = 50 },
	{ head = "patrol_naboo_rebel_3", standing = 50 },
	{ head = "assassinate_naboo_rebel_4", standing = 75 }
}

-- Conditional links: screen -> { { reply, link when the test holds, link otherwise }, ..., test }
v3fxConvoHandler.CONDITIONAL_LINKS = {
	non_member = { { "@conversation/naboo_rebel_trainer_1:s_ac05bfba", "non_member_duty_offer", "non_member_no_missions" }, test = "canFlyNonTrackDuty" },
	mission3_won = {
		{ "@conversation/naboo_rebel_trainer_1:s_9561a5a9", "m3_bandolier", "m3_flightsuit" },
		{ "@conversation/naboo_rebel_trainer_1:s_27a8c796", "m3_thanks_bandolier", "m3_thanks_flightsuit" },
		test = "isWookieeOrIthorian"
	},
	duty_menu = {
		{ "@conversation/naboo_rebel_trainer_1:s_cf63ee80", "destroy_duty_male", "destroy_duty_female" },
		{ "@conversation/naboo_rebel_trainer_1:s_a66ff602", "escort_duty", "escort_duty" },
		test = "isMale"
	}
}

-- The promotion menu (the goodbye link depends on gender), shown on all four screens
v3fxConvoHandler.PROMOTION_SCREENS = {
	tier_done = true, vrovel_vortex = true, vrovel_who = true, vrovel_where = true
}

-- C-2: the seven oath screens
v3fxConvoHandler.OATH_SCREENS = {
	oath_splendid = true, oath_glorious = true, oath_excellent_choice = true, oath_welcome = true,
	oath_great_day = true, oath_rebel_program = true, oath_space_navy = true
}

-- Screens that carry the player's name (%TU)
v3fxConvoHandler.NAME_SCREENS = {
	grounded = true, grounded_bad_news = true, grounded_missions = true, m2_not_so_fast = true
}

-- Any of V3-FX's story chains or duties is running (the journal checks of the SWG isOnMission)
function v3fxConvoHandler:isOnMission(pPlayer)
	local VS = VortexSquadronScreenplay

	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_1")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_rebel_2")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_3")
		or SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_rebel_4")
		or SpaceHelpers:isSpaceQuestActive(pPlayer, VS.QUEST_STRING_DUTY_1.type, VS.QUEST_STRING_DUTY_1.name)
		or SpaceHelpers:isSpaceQuestActive(pPlayer, VS.QUEST_STRING_DUTY_2.type, VS.QUEST_STRING_DUTY_2.name)
end

-- SWG canFlyNonTrackDuty (naboo_rebel_trainer_1.java:173-180): any tier 1 skill and no quest
function v3fxConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The pilot can be trained now: mission 4 paid, tier 1 unfinished, the first skill free and later ones paid for in XP
function v3fxConvoHandler:isReadyForTraining(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (getQuestStatus(playerID .. VortexSquadronScreenplay.QUEST_STRING_4.name .. ":reward") ~= "1") then
		return false
	end

	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1)) then
		return false
	end

	return not SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1) or SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true
end

-- naboo_rebel_trainer_1.java:181-185
function v3fxConvoHandler:isWookieeOrIthorian(pPlayer)
	local species = CreatureObject(pPlayer):getSpecies()

	return species == SPECIES_WOOKIEE or species == SPECIES_ITHORIAN
end

-- naboo_rebel_trainer_1.java:40-43
function v3fxConvoHandler:isMale(pPlayer)
	return CreatureObject(pPlayer):getGender() == 0
end

-- naboo_rebel_trainer_1.java:212-215: the droid's sparks
function v3fxConvoHandler:sparks(pPlayer, pNpc)
	if (pNpc == nil) then
		return
	end

	local npc = SceneObject(pNpc)

	playClientEffectLoc(pPlayer, "clienteffect/lair_damage_light.cef", npc:getZoneName(), npc:getPositionX(), npc:getPositionZ(), npc:getPositionY(), npc:getParentID())
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function v3fxConvoHandler:getLastScreenID(pPlayer)
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
function v3fxConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
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
		if (entry[3] == link or entry[4] == link) then
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

-- First screen (side-effect free). Gate order follows naboo_rebel_trainer_1.java OnStartNpcConversation (:14525 on)
function v3fxConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("no_jtl")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local VS = VortexSquadronScreenplay

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	local function status(key)
		return getQuestStatus(key) == "1"
	end

	local active = {
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_1"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "destroy_naboo_rebel_2"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_3"),
		SpaceHelpers:isSpaceQuestChainActive(pPlayer, "assassinate_naboo_rebel_4")
	}

	local won = {
		complete(VS.QUEST_STRING_1) and complete(VS.QUEST_STRING_1_SIDE),
		complete(VS.QUEST_STRING_2),
		complete(VS.QUEST_STRING_3) and complete(VS.QUEST_STRING_3_SIDE),
		complete(VS.QUEST_STRING_4)
	}

	local questStrings = { VS.QUEST_STRING_1, VS.QUEST_STRING_2, VS.QUEST_STRING_3, VS.QUEST_STRING_4 }
	local reward, failed = {}, {}

	for n = 1, 4 do
		reward[n] = status(playerID .. questStrings[n].name .. ":reward")
		failed[n] = status(playerID .. questStrings[n].name .. ":attempted") and not won[n] and not active[n]
	end

	local isRebelPilot = SpaceHelpers:isRebelPilot(pPlayer)
	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)

	-- Help loop while mission 1 is running
	if (hasShip and active[1]) then
		return convoTemplate:getScreen("first_mission_help")
	elseif (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("privateer_pilot")
	elseif (faction == FACTIONIMPERIAL or SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	elseif (faction ~= FACTIONREBEL) then
		return convoTemplate:getScreen(isRebelPilot and "grounded" or "not_rebel")
	elseif (not isRebelPilot) then
		return convoTemplate:getScreen("recruitment")
	elseif (not SpaceHelpers:isVortexSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_member")
	elseif (not hasShip) then
		return convoTemplate:getScreen("lost_ship")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	-- Pre-NGE gate: a pilot who turned against the Alliance
	elseif (ghost:getFactionStanding("rebel") < 0) then
		return convoTemplate:getScreen("grounded")
	-- SWG hasSpaceFlag(player, "vortexPilot"): any non-empty value is graduated
	elseif (getQuestStatus(playerID .. VS.VORTEX_PILOT_KEY) ~= nil and getQuestStatus(playerID .. VS.VORTEX_PILOT_KEY) ~= "") then
		return convoTemplate:getScreen("graduated")
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 1) and reward[4]) then
		return convoTemplate:getScreen("tier_done")
	elseif (failed[1]) then
		return convoTemplate:getScreen("mission1_failed")
	elseif (failed[2]) then
		return convoTemplate:getScreen("mission2_failed")
	elseif (failed[3]) then
		return convoTemplate:getScreen("mission3_failed")
	elseif (failed[4]) then
		return convoTemplate:getScreen("mission4_failed")
	-- Missions: offer until won, reward screen until paid
	elseif (not won[1]) then
		return convoTemplate:getScreen("mission1_offer")
	elseif (not reward[1]) then
		return convoTemplate:getScreen("mission1_won")
	elseif (not won[2]) then
		return convoTemplate:getScreen("mission2_offer")
	elseif (not reward[2]) then
		return convoTemplate:getScreen("mission2_won")
	elseif (not won[3]) then
		return convoTemplate:getScreen("mission3_offer")
	elseif (not reward[3]) then
		return convoTemplate:getScreen("mission3_won")
	elseif (not won[4]) then
		return convoTemplate:getScreen("mission4_offer")
	elseif (not reward[4]) then
		return convoTemplate:getScreen("mission4_won")
	elseif (not SpaceHelpers:hasPilotTierSkill(pPlayer, "rebel_navy", 1)) then
		return convoTemplate:getScreen("training_first")
	elseif (SpaceHelpers:hasExperienceForTraining(pPlayer, 1) == true) then
		return convoTemplate:getScreen("training_more")
	end

	return convoTemplate:getScreen("duty_missions")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, the Rebel standing
function v3fxConvoHandler:payMission(pPlayer, ghost, n)
	local playerID = CreatureObject(pPlayer):getObjectID()
	local key = playerID .. VortexSquadronScreenplay["QUEST_STRING_" .. n].name .. ":reward"

	if (getQuestStatus(key) == "1") then
		return
	end

	setQuestStatus(key, 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", self.MISSIONS[n].standing)
end

-- The sign-up: novice box, squadron, pilot tier 1 (naboo_rebel_trainer_1.java:186-190)
function v3fxConvoHandler:signUp(pPlayer, ghost)
	SpaceHelpers:grantNovicePilot(pPlayer, "rebelPilot")
	SpaceHelpers:setSquadronType(pPlayer, VORTEX_SQUADRON)

	if (ghost:getPilotTier() < 1) then
		ghost:incrementPilotTier()
	end
end

function v3fxConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
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
	local conditional = self.CONDITIONAL_LINKS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		setQuestStatus(playerID .. VS["QUEST_STRING_" .. startMission].name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	end

	if (conditional ~= nil) then
		-- C-1, C-3, C-6
		local holds = self[conditional.test](self, pPlayer)

		clonedConversation:removeAllOptions()

		for _, entry in ipairs(conditional) do
			clonedConversation:addOption(entry[1], holds and entry[2] or entry[3])
		end
	elseif (self.OATH_SCREENS[screenID]) then
		self:signUp(pPlayer, ghost)

		-- C-2
		clonedConversation:removeAllOptions()

		if (SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_fc27931b", "first_assignment")
		else
			clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted")
		end
	elseif (screenID == "recruit_ship_granted" or screenID == "lost_ship") then
		if (not SpaceHelpers:hasCertifiedShip(pPlayer, true)) then
			grantStarterShip(pPlayer, "rebel")
		end
	elseif (screenID == "training_first" or screenID == "training_more") then
		-- C-4: every skill the pilot lacks (pre-NGE topic menu), linked by gender
		local male = self:isMale(pPlayer)

		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], male and entry[3] or entry[4])
			end
		end
	elseif (screenID == "destroy_duty_male" or screenID == "destroy_duty_female") then
		destroy_duty_naboo_rebel_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_naboo_rebel_7:startQuest(pPlayer, pNpc)
	elseif (screenID == "no_jtl" or screenID == "privateer_training" or screenID == "imperial_answers") then
		self:sparks(pPlayer, pNpc)
	end

	if (self.PROMOTION_SCREENS[screenID]) then
		-- C-5
		if (screenID == "tier_done") then
			setQuestStatus(playerID .. VS.VORTEX_PILOT_KEY, "1")
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_f75b511f", "vrovel_splendid")
		clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_4efbdbfa", "vrovel_vortex")
		clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_b89c30f1", "vrovel_who")
		clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_1df40ac6", self:isMale(pPlayer) and "vrovel_goodbye_male" or "vrovel_goodbye_female")
		clonedConversation:addOption("@conversation/naboo_rebel_trainer_1:s_8334632", "vrovel_where")
	end

	return pClonedScreen
end
