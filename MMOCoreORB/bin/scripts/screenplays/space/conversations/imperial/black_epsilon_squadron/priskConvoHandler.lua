-- Prisk Kith'Vys (Black Epsilon tier 2) conversation handler; ported from SWG-Source corellia_imperial_trainer_2.java. One-click training and the "wanted" gate: pre-NGE client lines (feature black-epsilon-tier2-prisk).
local SpaceHelpers = require("utils.space_helpers")

priskConvoHandler = conv_handler:new {}

-- Story missions in SWG flag order: { skill, head quest global, BlackEpsilonSquadronScreenplay quest string, briefing screen }
priskConvoHandler.MISSIONS = {
	{ skill = "pilot_imperial_navy_starships_02", head = "assassinate_corellia_imperial_12", questString = "TIER2_QUEST_STRING_1", brief = "m12_brief" },
	{ skill = "pilot_imperial_navy_droid_02", head = "inspect_corellia_imperial_13", questString = "TIER2_QUEST_STRING_2", brief = "m13_brief" },
	{ skill = "pilot_imperial_navy_weapons_02", head = "assassinate_corellia_imperial_14", questString = "TIER2_QUEST_STRING_3", brief = "m14_brief" },
	{ skill = "pilot_imperial_navy_procedures_02", head = "patrol_corellia_imperial_15", questString = "TIER2_QUEST_STRING_4", brief = "m15_brief" }
}

-- The opening recovery and the final assassination
priskConvoHandler.OPENING = { head = "recovery_corellia_imperial_16", questString = "TIER2_QUEST_STRING_OPENING" }
priskConvoHandler.FINAL = { head = "assassinate_corellia_imperial_17", questString = "TIER2_QUEST_STRING_FINAL" }

-- Pre-NGE free choice of a tier 2 skill, one click: { skill, topic reply, trained screen }, in menu order
priskConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_02", "@conversation/corellia_imperial_trainer_2:s_be505897", "trained_starships" },
	{ "pilot_imperial_navy_weapons_02", "@conversation/corellia_imperial_trainer_2:s_82fd8660", "trained_weapons" },
	{ "pilot_imperial_navy_procedures_02", "@conversation/corellia_imperial_trainer_2:s_a872e9f9", "trained_procedures" },
	{ "pilot_imperial_navy_droid_02", "@conversation/corellia_imperial_trainer_2:s_9b4e084a", "trained_droid" }
}

-- Screens that start a story quest (the head chain is started on display): screen -> "opening", mission number or "final"
priskConvoHandler.START_SCREENS = {
	opening_accept = "opening", opening_retry = "opening",
	m12_accept = 1, m12_retry = 1,
	m13_accept = 2, m13_retry = 2,
	m14_accept = 3, m14_retry = 3,
	m15_accept = 4, m15_retry = 4,
	final_accept = "final", final_retry = "final"
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
priskConvoHandler.REWARD_SCREENS = {
	m12_reward = 1, m13_reward = 2, m14_reward = 3, m15_reward = 4
}

-- Screens that start a duty: screen -> duty quest global
priskConvoHandler.DUTY_SCREENS = {
	duty_pirates = "destroy_duty_corellia_imperial_8",
	duty_merchant = "escort_duty_corellia_imperial_9",
	duty_rebels = "destroy_duty_corellia_imperial_10",
	duty_security = "escort_duty_corellia_imperial_11"
}

function priskConvoHandler:getQuestString(key)
	if (key == "opening") then
		return BlackEpsilonSquadronScreenplay[self.OPENING.questString]
	elseif (key == "final") then
		return BlackEpsilonSquadronScreenplay[self.FINAL.questString]
	end

	return BlackEpsilonSquadronScreenplay[self.MISSIONS[key].questString]
end

function priskConvoHandler:getHead(key)
	if (key == "opening") then
		return self.OPENING.head
	elseif (key == "final") then
		return self.FINAL.head
	end

	return self.MISSIONS[key].head
end

-- <playerID><questName><suffix> is "1"
function priskConvoHandler:hasStatus(pPlayer, key, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(key).name .. suffix) == "1"
end

function priskConvoHandler:isActive(pPlayer, key)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self:getHead(key))
end

-- The story quest is complete (mission 4 needs the patrol and its surprise attack, the final the survival)
function priskConvoHandler:isWon(pPlayer, key)
	local BE = BlackEpsilonSquadronScreenplay

	local function complete(questString)
		return SpaceHelpers:isSpaceQuestComplete(pPlayer, questString.type, questString.name)
	end

	if (key == "opening") then
		return complete(BE.TIER2_QUEST_STRING_OPENING)
	elseif (key == "final") then
		return complete(BE.TIER2_QUEST_STRING_FINAL_SIDE)
	elseif (key == 4) then
		return complete(BE.TIER2_QUEST_STRING_4) and complete(BE.TIER2_QUEST_STRING_4_SIDE)
	end

	return complete(self:getQuestString(key))
end

-- Attempted, not won and not running
function priskConvoHandler:isFailed(pPlayer, key)
	return self:hasStatus(pPlayer, key, ":attempted") and not self:isWon(pPlayer, key) and not self:isActive(pPlayer, key)
end

-- Any of Prisk's story chains or duties is running (the journal checks of the SWG isOnMission)
function priskConvoHandler:isOnMission(pPlayer)
	local BE = BlackEpsilonSquadronScreenplay

	if (self:isActive(pPlayer, "opening") or self:isActive(pPlayer, "final")) then
		return true
	end

	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	for n = 1, 4 do
		local duty = BE["TIER2_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, duty.type, duty.name)) then
			return true
		end
	end

	return false
end

-- SWG canFlyNonTrackDuty (corellia_imperial_trainer_2.java:82-89): all tier 1 skills and no quest
function priskConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- SWG isReadyForMission, derived: the first mission whose skill is held and that was not attempted yet (nil if none)
function priskConvoHandler:getReadyMission(pPlayer)
	if (not self:isWon(pPlayer, "opening")) then
		return nil
	end

	for n = 1, 4 do
		if (CreatureObject(pPlayer):hasSkill(self.MISSIONS[n].skill) and not self:hasStatus(pPlayer, n, ":attempted")) then
			return n
		end
	end

	return nil
end

-- SWG isReadyForTraining (corellia_imperial_trainer_2.java:46-57); the opening is required for every skill
function priskConvoHandler:isReadyForTraining(pPlayer)
	return self:isWon(pPlayer, "opening")
		and not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)
		and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 1)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 2) == true
		and self:getReadyMission(pPlayer) == nil
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function priskConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: a topic reply on training_menu buys the skill and shows its trained screen. Any failed
-- guard sends the pilot back through the gates.
function priskConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if ((self:getLastScreenID(pPlayer) or "") ~= "training_menu") then
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

		if (ghost ~= nil and ghost:getPilotTier() == 2 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
			ghost:incrementPilotTier()
		end
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(link)
end

function priskConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	local BE = BlackEpsilonSquadronScreenplay

	local playerID = CreatureObject(pPlayer):getObjectID()
	local faction = CreatureObject(pPlayer):getFaction()
	local standing = ghost:getFactionStanding("imperial")

	if (SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("privateer")
	elseif (faction == FACTIONREBEL or SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel")
	elseif (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	-- The "wanted" gate: negative Imperial standing, by gender
	elseif (standing < 0 and CreatureObject(pPlayer):getGender() == 0) then
		return convoTemplate:getScreen("wanted_male")
	elseif (standing < 0) then
		return convoTemplate:getScreen("wanted_female")
	elseif (not SpaceHelpers:isBlackEpsilonSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (self:getReadyMission(pPlayer) ~= nil) then
		return convoTemplate:getScreen("assignment_waiting")
	elseif (self:isWon(pPlayer, "final")) then
		return convoTemplate:getScreen("tour_complete")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	elseif (self:isFailed(pPlayer, "final")) then
		return convoTemplate:getScreen("final_retry")
	end

	local allPaid = true

	for n = 1, 4 do
		allPaid = allPaid and self:hasStatus(pPlayer, n, ":reward")
	end

	if (allPaid and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 2)) then
		return convoTemplate:getScreen("final_offer")
	elseif (self:isFailed(pPlayer, "opening")) then
		return convoTemplate:getScreen("opening_failed")
	end

	local retryScreens = { "m12_retry", "m13_retry", "m14_retry", "m15_retry" }
	local wonScreens = { "m12_won", "m13_won", "m14_won", "m15_won" }

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen(retryScreens[n])
		end
	end

	for n = 1, 4 do
		if (self:isWon(pPlayer, n) and not self:hasStatus(pPlayer, n, ":reward")) then
			return convoTemplate:getScreen(wonScreens[n])
		end
	end

	if (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("training_menu")
	elseif (self:isWon(pPlayer, "opening")) then
		return convoTemplate:getScreen("opening_done")
	elseif (getQuestStatus(playerID .. BE.SERIES_COMPLETE_KEY) == "1") then
		return convoTemplate:getScreen("hakassha_sent")
	end

	return convoTemplate:getScreen("see_hakassha")
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 75 Imperial standing
function priskConvoHandler:payMission(pPlayer, ghost, n)
	if (self:hasStatus(pPlayer, n, ":reward")) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 75)
end

function priskConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local playerID = CreatureObject(pPlayer):getObjectID()

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

	local startQuest = self.START_SCREENS[screenID]
	local rewardMission = self.REWARD_SCREENS[screenID]
	local duty = self.DUTY_SCREENS[screenID]

	if (startQuest ~= nil) then
		-- Quests (started on the screen that carries the grant)
		setQuestStatus(playerID .. self:getQuestString(startQuest).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self:getHead(startQuest))
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen that carries the reward)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (screenID == "off_track") then
		-- C-1: off-track pilots may fly a duty (corellia_imperial_trainer_2.java:670-745)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_imperial_trainer_2:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_no_missions")
	elseif (screenID == "assignment_waiting") then
		-- C-2: the briefing of the mission that is ready
		local ready = self:getReadyMission(pPlayer)

		if (ready ~= nil) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/corellia_imperial_trainer_2:s_6d3be6aa", self.MISSIONS[ready].brief)
		end
	elseif (screenID == "training_menu") then
		-- C-3: every tier 2 skill the pilot lacks
		clonedConversation:removeAllOptions()

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], entry[3])
			end
		end
	end

	return pClonedScreen
end
