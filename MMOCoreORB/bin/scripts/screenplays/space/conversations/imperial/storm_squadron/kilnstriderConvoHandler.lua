-- Admiral Kilnstrider (Storm Squadron tier 4) conversation handler; ported from SWG-Source tatooine_imperial_tier4.java. One-click, free-choice training bought with XP, the grounded gate, duties and the hand-off to Grand Admiral Declann: pre-NGE client lines (feature storm-tier4-kilnstrider).
local SpaceHelpers = require("utils.space_helpers")

kilnstriderConvoHandler = conv_handler:new {}

-- Missions: { head quest global, StormSquadronScreenplay quest string of the head, quest string of the chain end }
kilnstriderConvoHandler.MISSIONS = {
	{ head = "patrol_tatooine_imperial_tier4_1", questString = "TIER4_QUEST_STRING_1", endString = "TIER4_QUEST_STRING_1_SIDE4" },
	{ head = "recovery_tatooine_imperial_tier4_2", questString = "TIER4_QUEST_STRING_2", endString = "TIER4_QUEST_STRING_2_SIDE3" },
	{ head = "escort_tatooine_imperial_tier4_3", questString = "TIER4_QUEST_STRING_3", endString = "TIER4_QUEST_STRING_3_SIDE2" },
	{ head = "assassinate_tatooine_imperial_tier4_4", questString = "TIER4_QUEST_STRING_4", endString = "TIER4_QUEST_STRING_4_SIDE3" }
}

-- Screens that start a duty: screen -> duty quest global
kilnstriderConvoHandler.DUTY_SCREENS = {
	duty_destroy = "destroy_duty_tatooine_imperial_tier4_destroyduty_1",
	duty_escort = "escort_duty_tatooine_imperial_tier4_escortduty_1",
	duty_recovery = "recovery_duty_tatooine_imperial_tier4_recoveryduty_1",
	duty_rescue = "rescue_duty_tatooine_imperial_tier4_rescueduty_1"
}

-- Pre-NGE free choice of a tier 4 skill, one click: { skill, topic reply, default link }, in menu order.
-- Every topic links the first post-training opening; the grant routes by the reply text.
kilnstriderConvoHandler.TRAIN_CHOICES = {
	{ "pilot_imperial_navy_starships_04", "@conversation/tatooine_imperial_tier4:s_a50d5eb4", "m1_brief" },
	{ "pilot_imperial_navy_weapons_04", "@conversation/tatooine_imperial_tier4:s_2c2ce09e", "m1_brief" },
	{ "pilot_imperial_navy_procedures_04", "@conversation/tatooine_imperial_tier4:s_a5d7d28d", "m1_brief" },
	{ "pilot_imperial_navy_droid_04", "@conversation/tatooine_imperial_tier4:s_97682588", "m1_brief" }
}

-- The opening shown after training, by the mission that is next
kilnstriderConvoHandler.TRAINED_BRIEFS = { "m1_brief", "m2_brief_trained", "m3_brief", "m4_brief" }

-- Screens that start a mission (the head chain is started on display): screen -> mission number
kilnstriderConvoHandler.START_SCREENS = {
	m1_failed = 1, m1_accept_busy = 1, m1_accept_hope = 1,
	m2_failed = 2, m2_accept_fire = 2, m2_accept_good = 2, m2_accept_dismissed = 2,
	m3_failed = 3, m3_accept_escort = 3, m3_accept_bottom = 3,
	m4_failed = 4, m4_accept_prejudice = 4, m4_accept_search = 4, m4_accept_expect = 4
}

-- Screens that pay a mission reward (once, on display): screen -> mission number
kilnstriderConvoHandler.REWARD_SCREENS = {
	m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4
}

-- Screens whose NPC line carries the %TU / %NU token
kilnstriderConvoHandler.NAME_SCREENS = {
	wanted = true, wanted_c8003afd = true, m2_failed = true, m1_reward = true, m2_reward = true, m3_reward = true,
	ready = true, duty_recovery = true, m2_brief = true, m2_brief_trained = true
}

-- Screens that only raise the pilot tier
kilnstriderConvoHandler.TIER_SCREENS = {
	transfer = true, here_for_work = true
}

local NAME_SCREENS = kilnstriderConvoHandler.NAME_SCREENS
local TIER_SCREENS = kilnstriderConvoHandler.TIER_SCREENS

function kilnstriderConvoHandler:getQuestString(n)
	return StormSquadronScreenplay[self.MISSIONS[n].questString]
end

-- <playerID><questName><suffix> is "1"
function kilnstriderConvoHandler:hasStatus(pPlayer, n, suffix)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. self:getQuestString(n).name .. suffix) == "1"
end

-- <playerID><key> is "1"
function kilnstriderConvoHandler:hasKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. key) == "1"
end

function kilnstriderConvoHandler:setKey(pPlayer, key)
	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. key, 1)
end

-- The end of the mission's chain is complete (SWG hasCompletedQuestRecursive)
function kilnstriderConvoHandler:isWon(pPlayer, n)
	local endString = StormSquadronScreenplay[self.MISSIONS[n].endString]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, endString.type, endString.name)
end

function kilnstriderConvoHandler:isActive(pPlayer, n)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, self.MISSIONS[n].head)
end

-- Attempted, not won and not running
function kilnstriderConvoHandler:isFailed(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":attempted") and not self:isWon(pPlayer, n) and not self:isActive(pPlayer, n)
end

function kilnstriderConvoHandler:isPaid(pPlayer, n)
	return self:hasStatus(pPlayer, n, ":reward")
end

-- Any of the four chains or the four duties is running
function kilnstriderConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		if (self:isActive(pPlayer, n)) then
			return true
		end
	end

	for n = 1, 4 do
		local duty = StormSquadronScreenplay["TIER4_QUEST_STRING_DUTY_" .. n]

		if (SpaceHelpers:isSpaceQuestActive(pPlayer, duty.type, duty.name)) then
			return true
		end
	end

	return false
end

-- Imperials only: negative standing or a lost Imperial faction is grounded
function kilnstriderConvoHandler:isGrounded(pPlayer)
	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return false
	end

	return LuaPlayerObject(pGhost):getFactionStanding("imperial") < 0 or CreatureObject(pPlayer):getFaction() ~= FACTIONIMPERIAL
end

-- SWG canFlyNonTrackDuty (tatooine_imperial_tier4.java:244-251): all tier 3 skills and no quest
function kilnstriderConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

-- The first mission that is not won (nil when all four are)
function kilnstriderConvoHandler:getNextMission(pPlayer)
	for n = 1, 4 do
		if (not self:isWon(pPlayer, n)) then
			return n
		end
	end

	return nil
end

-- SWG isReadyForMission, derived: the next mission when the pilot holds as many tier 4 skills as its number and has
-- not attempted it yet (nil if none)
function kilnstriderConvoHandler:getReadyMission(pPlayer)
	local n = self:getNextMission(pPlayer)

	if (n ~= nil and SpaceHelpers:getPilotTierSkillCount(pPlayer, "imperial_navy", 4) >= n and not self:hasStatus(pPlayer, n, ":attempted")) then
		return n
	end

	return nil
end

-- SWG isReadyForTraining (tatooine_imperial_tier4.java:68-75)
function kilnstriderConvoHandler:isReadyForTraining(pPlayer)
	return not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)
		and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)
		and SpaceHelpers:hasExperienceForTraining(pPlayer, 4) == true
		and self:getReadyMission(pPlayer) == nil
end

-- Pays the reward of mission n once: the :reward key, the head's credits and item, 150 Imperial standing
function kilnstriderConvoHandler:payMission(pPlayer, ghost, n)
	if (self:isPaid(pPlayer, n)) then
		return
	end

	local playerID = CreatureObject(pPlayer):getObjectID()

	setQuestStatus(playerID .. self:getQuestString(n).name .. ":reward", 1)

	_G[self.MISSIONS[n].head]:rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("imperial", 150)
end

-- Pilot tier 3 to 4 once the four tier 3 skills are held, then 4 to 5 once the four tier 4 skills are held
function kilnstriderConvoHandler:raisePilotTier(pPlayer, ghost)
	if (ghost == nil) then
		return
	end

	if (ghost:getPilotTier() == 3 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		ghost:incrementPilotTier()
	end

	if (ghost:getPilotTier() == 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)) then
		ghost:incrementPilotTier()
	end
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function kilnstriderConvoHandler:getLastScreenID(pPlayer)
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

-- Pre-NGE one-click training: a topic reply on ready_train buys the skill (1,000,000 XP) and shows the opening of the
-- next mission. Any failed guard sends the pilot back through the gates, granting nothing.
function kilnstriderConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	if ((self:getLastScreenID(pPlayer) or "") ~= "ready_train") then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	-- The skill is the one whose reply the pilot picked on the live (cloned) screen
	local chosen = nil
	local convSession = CreatureObject(pPlayer):getConversationSession()

	if (convSession ~= nil) then
		local pLastScreen = LuaConversationSession(convSession):getLastConversationScreen()

		if (pLastScreen ~= nil) then
			chosen = LuaConversationScreen(pLastScreen):getOptionText(selectedOption)
		end
	end

	local skill = nil

	for _, entry in ipairs(self.TRAIN_CHOICES) do
		if (entry[2] == chosen) then
			skill = entry[1]
			break
		end
	end

	if (skill == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	if (CreatureObject(pPlayer):hasSkill(skill) or not self:isReadyForTraining(pPlayer) or not LuaSkillManager():fulfillsSkillPrerequisitesAndXp(pPlayer, skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)

	if (not CreatureObject(pPlayer):hasSkill(skill)) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		self:raisePilotTier(pPlayer, LuaPlayerObject(pGhost))
	end

	local n = self:getNextMission(pPlayer)

	if (n == nil) then
		return self:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(self.TRAINED_BRIEFS[n])
end

-- Gates G0-G21 (first match wins); no side effects
function kilnstriderConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
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

	if (LuaPlayerObject(pGhost) == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	-- J checks isPilot first (tatooine_imperial_tier4.java): a non-pilot is refused before any faction or squadron gate
	if (not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	elseif (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	elseif (not SpaceHelpers:isStormSquadron(pPlayer)) then
		return convoTemplate:getScreen("off_track")
	elseif (self:isGrounded(pPlayer)) then
		return convoTemplate:getScreen("wanted")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 3)) then
		return convoTemplate:getScreen("not_ready")
	elseif (SpaceHelpers:hasSpaceQuest(pPlayer) or self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	end

	for n = 1, 4 do
		if (self:isFailed(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_failed")
		end
	end

	for n = 1, 4 do
		if (self:isWon(pPlayer, n) and not self:isPaid(pPlayer, n)) then
			return convoTemplate:getScreen("m" .. n .. "_reward")
		end
	end

	if (self:getReadyMission(pPlayer) ~= nil) then
		return convoTemplate:getScreen("ready")
	elseif (self:isReadyForTraining(pPlayer)) then
		return convoTemplate:getScreen("ready_train")
	elseif (not self:hasKey(pPlayer, StormSquadronScreenplay.TIER4_MET_KEY)) then
		return convoTemplate:getScreen("intro")
	elseif (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "imperial_navy", 4)) then
		return convoTemplate:getScreen("tier4_incomplete")
	elseif (not SpaceHelpers:hasMasterSkill(pPlayer, "imperial_navy")) then
		return convoTemplate:getScreen("transfer")
	end

	return convoTemplate:getScreen("here_for_work")
end

function kilnstriderConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

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
	local duty = self.DUTY_SCREENS[screenID]

	if (startMission ~= nil) then
		-- Missions (started on the screen that carries the grant)
		local playerID = CreatureObject(pPlayer):getObjectID()

		self:raisePilotTier(pPlayer, ghost)
		setQuestStatus(playerID .. self:getQuestString(startMission).name .. ":attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, self.MISSIONS[startMission].head)
	elseif (rewardMission ~= nil) then
		-- Rewards (paid on the screen where J pays)
		self:payMission(pPlayer, ghost, rewardMission)
	elseif (duty ~= nil) then
		self:raisePilotTier(pPlayer, ghost)
		_G[duty]:startQuest(pPlayer, pNpc)
	elseif (screenID == "intro_briefing") then
		-- Only the first meeting's briefing sets the met flag (SWG setMetMe)
		self:setKey(pPlayer, StormSquadronScreenplay.TIER4_MET_KEY)
	elseif (TIER_SCREENS[screenID]) then
		self:raisePilotTier(pPlayer, ghost)
	elseif (screenID == "ready_train") then
		-- C-1: every tier 4 skill the pilot lacks
		clonedConversation:removeAllOptions()

		local added = false

		for _, entry in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(entry[1])) then
				clonedConversation:addOption(entry[2], self.TRAINED_BRIEFS[self:getNextMission(pPlayer) or 1])
				added = true
			end
		end

		if (not added) then
			clonedConversation:setStopConversation(true)
		end
	elseif (screenID == "off_track") then
		-- C-2: off-track pilots may fly a duty (tatooine_imperial_tier4.java:244-251)
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_imperial_tier4:s_4854758d", self:canFlyNonTrackDuty(pPlayer) and "off_track_duties" or "off_track_refused")
	elseif (screenID == "ready") then
		-- C-3: the briefing of the mission that is ready
		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/tatooine_imperial_tier4:s_52917b0d", "m" .. (self:getReadyMission(pPlayer) or 1) .. "_brief")
	end

	return pClonedScreen
end
