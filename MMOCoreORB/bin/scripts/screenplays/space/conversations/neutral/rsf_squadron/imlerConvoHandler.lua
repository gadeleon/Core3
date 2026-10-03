--[[
	Royal Security Forces - Tier 4 (Admiral Diness Imler) - Conversation Handler
	SWG-Source: naboo_privateer_tier4.java
	Feature: rsf-tier4
]]

local SpaceHelpers = require("utils.space_helpers")

imlerConvoHandler = conv_handler:new {}

-- Quest constants (on RsfSquadronScreenplay) that make up each story mission. "chain" is every quest of
-- the mission (cleared on grant), "wins" are the quests whose completion counts as winning the mission.
imlerConvoHandler.MISSIONS = {
	[1] = {
		main = "TIER4_QUEST_STRING_1",
		chain = {"TIER4_QUEST_STRING_1", "TIER4_QUEST_STRING_1_SIDE1"},
		wins = {"TIER4_QUEST_STRING_1_SIDE1"},
	},
	[2] = {
		main = "TIER4_QUEST_STRING_2",
		chain = {"TIER4_QUEST_STRING_2", "TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2", "TIER4_QUEST_STRING_2_SIDE3"},
		wins = {"TIER4_QUEST_STRING_2_SIDE3"},
	},
	[3] = {
		main = "TIER4_QUEST_STRING_3",
		chain = {"TIER4_QUEST_STRING_3", "TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2"},
		wins = {"TIER4_QUEST_STRING_3_SIDE2"},
	},
	[4] = {
		main = "TIER4_QUEST_STRING_4",
		chain = {"TIER4_QUEST_STRING_4", "TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2A", "TIER4_QUEST_STRING_4_SIDE2B"},
		wins = {"TIER4_QUEST_STRING_4_SIDE2A", "TIER4_QUEST_STRING_4_SIDE2B"},
	},
}

imlerConvoHandler.DUTY_QUESTS = {"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4"}

imlerConvoHandler.DUTY_SCREENS = {
	duty_destroy = "TIER4_QUEST_STRING_DUTY_1",
	duty_escort = "TIER4_QUEST_STRING_DUTY_2",
	duty_recovery = "TIER4_QUEST_STRING_DUTY_3",
	duty_rescue = "TIER4_QUEST_STRING_DUTY_4",
}

-- Training screens: the skill bought when the player chooses the option on them
imlerConvoHandler.TRAIN_SCREENS = {
	train_starships = "pilot_neutral_starships_04",
	train_weapons = "pilot_neutral_weapons_04",
	train_procedures = "pilot_neutral_procedures_04",
	train_droid = "pilot_neutral_droid_04",
}

imlerConvoHandler.MET_SUFFIX = "RsfSquadronScreenplay:StartedImler"
imlerConvoHandler.READY_SUFFIX = "RsfSquadronScreenplay:readyForTier4Mission"

-- Option texts whose link is changed at run time
imlerConvoHandler.NOT_MY_TRACK_OPTION = "@conversation/naboo_privateer_tier4:s_c1ff5062"
imlerConvoHandler.READY_MISSION_OPTION = "@conversation/naboo_privateer_tier4:s_39e697de"
imlerConvoHandler.READY_TRAIN_OPTION = "@conversation/naboo_privateer_tier4:s_438"

-- Quest globals are named <type>_<name>; they are looked up at call time.
function imlerConvoHandler:questGlobal(constant)
	local quest = RsfSquadronScreenplay[constant]

	return _G[quest.type .. "_" .. quest.name]
end

function imlerConvoHandler:isActive(pPlayer, constant)
	local quest = RsfSquadronScreenplay[constant]

	return SpaceHelpers:isSpaceQuestActive(pPlayer, quest.type, quest.name)
end

function imlerConvoHandler:isComplete(pPlayer, constant)
	local quest = RsfSquadronScreenplay[constant]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, quest.type, quest.name)
end

function imlerConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		for _, constant in ipairs(self.MISSIONS[n].chain) do
			if (self:isActive(pPlayer, constant)) then
				return true
			end
		end
	end

	for _, duty in ipairs(self.DUTY_QUESTS) do
		if (self:isActive(pPlayer, duty)) then
			return true
		end
	end

	return false
end

function imlerConvoHandler:hasWon(pPlayer, n)
	for _, constant in ipairs(self.MISSIONS[n].wins) do
		if (self:isComplete(pPlayer, constant)) then
			return true
		end
	end

	return false
end

function imlerConvoHandler:statusKey(pPlayer, n, suffix)
	return CreatureObject(pPlayer):getObjectID() .. RsfSquadronScreenplay[self.MISSIONS[n].main].name .. suffix
end

function imlerConvoHandler:hasReward(pPlayer, n)
	return getQuestStatus(self:statusKey(pPlayer, n, ":reward")) == "1"
end

function imlerConvoHandler:hasAttempted(pPlayer, n)
	return getQuestStatus(self:statusKey(pPlayer, n, ":attempted")) == "1"
end

function imlerConvoHandler:flagKey(pPlayer, suffix)
	return CreatureObject(pPlayer):getObjectID() .. suffix
end

function imlerConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

function imlerConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (not isJtlEnabled() or not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	if (not SpaceHelpers:isNeutralPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	end

	if (not SpaceHelpers:isRSFSquadron(pPlayer)) then
		return convoTemplate:getScreen("not_my_track")
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
		return convoTemplate:getScreen("not_ready")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("not_pilot")
	end

	local completedTier4 = SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)

	-- Tier 3 is done, so the pilot is at least tier 4; tier 5 once tier 4 is done
	if (ghost:getPilotTier() < 4) then
		ghost:incrementPilotTier()
	end

	if (completedTier4 and ghost:getPilotTier() < 5) then
		ghost:incrementPilotTier()
	end

	if (self:isOnMission(pPlayer)) then
		return convoTemplate:getScreen("on_mission")
	end

	-- Failed missions come before rewards
	for n = 1, 4 do
		if (self:hasAttempted(pPlayer, n) and not self:hasWon(pPlayer, n)) then
			return convoTemplate:getScreen("mission" .. n .. "_failed")
		end
	end

	-- Rewards due
	for n = 1, 4 do
		if (self:hasWon(pPlayer, n) and not self:hasReward(pPlayer, n)) then
			return convoTemplate:getScreen("mission" .. n .. "_reward")
		end
	end

	if (getQuestStatus(self:flagKey(pPlayer, self.READY_SUFFIX)) == "1") then
		return convoTemplate:getScreen("ready_mission")
	end

	if (not completedTier4 and SpaceHelpers:hasExperienceForTraining(pPlayer, 4)) then
		return convoTemplate:getScreen("ready_train")
	end

	if (getQuestStatus(self:flagKey(pPlayer, self.MET_SUFFIX)) ~= "1") then
		return convoTemplate:getScreen("intro")
	end

	if (not completedTier4) then
		return convoTemplate:getScreen("tier4_incomplete")
	end

	if (not SpaceHelpers:hasMasterSkill(pPlayer, "neutral")) then
		return convoTemplate:getScreen("no_master")
	end

	return convoTemplate:getScreen("here_for_work")
end

-- The id of the screen the player chose an option on (the session still holds it while the next
-- screen is picked and handled)
function imlerConvoHandler:getLastScreenID(pPlayer)
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

-- Choosing the option on a train_<x> screen buys the skill, then the screen follows the number of
-- tier 4 skills held after the purchase
function imlerConvoHandler:getNextConversationScreen(pConvTemplate, pPlayer, selectedOption, pNpc)
	local skill = self.TRAIN_SCREENS[self:getLastScreenID(pPlayer) or ""]

	if (skill == nil) then
		return conv_handler.getNextConversationScreen(self, pConvTemplate, pPlayer, selectedOption, pNpc)
	end

	if (not CreatureObject(pPlayer):hasSkill(skill) and SpaceHelpers:hasExperienceForTraining(pPlayer, 4)) then
		SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost ~= nil) then
		local ghost = LuaPlayerObject(pGhost)

		if (ghost ~= nil and ghost:getPilotTier() <= 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then
			ghost:incrementPilotTier()
		end
	end

	local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 4)
	local nextScreen = "trained_mission1"

	if (skillCount >= 2 and skillCount <= 4) then
		nextScreen = "trained_mission" .. skillCount
	end

	return LuaConversationTemplate(pConvTemplate):getScreen(nextScreen)
end

function imlerConvoHandler:startMission(pPlayer, pNpc, n)
	local mission = self.MISSIONS[n]

	-- Clear old journal entries of this mission so it can be run again
	for _, constant in ipairs(mission.chain) do
		local quest = RsfSquadronScreenplay[constant]

		SpaceHelpers:clearSpaceQuest(pPlayer, quest.type, quest.name, false)
	end

	setQuestStatus(self:statusKey(pPlayer, n, ":attempted"), 1)
	removeQuestStatus(self:flagKey(pPlayer, self.READY_SUFFIX))

	self:questGlobal(mission.main):startQuest(pPlayer, pNpc)
end

function imlerConvoHandler:payReward(pPlayer, n)
	if (self:hasReward(pPlayer, n)) then
		return
	end

	setQuestStatus(self:statusKey(pPlayer, n, ":reward"), 1)

	self:questGlobal(self.MISSIONS[n].main):rewardPlayer(pPlayer)
end

function imlerConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	-- Set player name token
	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	-- Non-RSF pilots may still fly Imler's duty missions
	if (screenID == "not_my_track") then
		local link = "nontrack_no_duty"

		if (self:canFlyNonTrackDuty(pPlayer)) then
			link = "nontrack_duty"
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption(self.NOT_MY_TRACK_OPTION, link)

	-- Ready for a mission: the briefing follows the number of tier 4 skills
	elseif (screenID == "ready_mission") then
		local link = "mission1_brief"
		local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "neutral", 4)

		if (skillCount >= 2 and skillCount <= 4) then
			link = "mission" .. skillCount .. "_brief"
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption(self.READY_MISSION_OPTION, link)

	-- Training menu: send the pilot to the first tier 4 skill they lack
	elseif (screenID == "ready_train") then
		local link = "train_droid"

		if (not CreatureObject(pPlayer):hasSkill("pilot_neutral_starships_04")) then
			link = "train_starships"
		elseif (not CreatureObject(pPlayer):hasSkill("pilot_neutral_weapons_04")) then
			link = "train_weapons"
		elseif (not CreatureObject(pPlayer):hasSkill("pilot_neutral_procedures_04")) then
			link = "train_procedures"
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption(self.READY_TRAIN_OPTION, link)

	elseif (string.match(screenID, "^trained_mission%d$") ~= nil) then
		setQuestStatus(self:flagKey(pPlayer, self.READY_SUFFIX), 1)

	elseif (screenID == "duty_info") then
		-- Only the intro counts as meeting the Admiral; the non-track route reaches the same line
		if (self:getLastScreenID(pPlayer) == "intro") then
			setQuestStatus(self:flagKey(pPlayer, self.MET_SUFFIX), 1)
		end

	elseif (self.DUTY_SCREENS[screenID] ~= nil) then
		self:questGlobal(self.DUTY_SCREENS[screenID]):startQuest(pPlayer, pNpc)

	else
		local rewardMission = string.match(screenID, "^mission(%d)_reward$")

		if (rewardMission ~= nil) then
			self:payReward(pPlayer, tonumber(rewardMission))
		else
			local mission = string.match(screenID, "^mission(%d)_accept_") or string.match(screenID, "^mission(%d)_retry_")

			if (mission ~= nil) then
				self:startMission(pPlayer, pNpc, tonumber(mission))
			end
		end
	end

	return pClonedScreen
end
