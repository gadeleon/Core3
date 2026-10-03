--[[
	Havoc Squadron - Tier 4 (Warvog Arkon) - Conversation Handler
	SWG-Source: corellia_rebel_tier4.java
	Feature: havoc-tier4-arkon
]]

local SpaceHelpers = require("utils.space_helpers")

arkonConvoHandler = conv_handler:new {}

-- Quest constants (on HavocSquadronScreenplay) that make up each story mission. "wins" are the
-- children whose completion counts as winning the mission.
arkonConvoHandler.MISSIONS = {
	[1] = {
		main = "TIER4_QUEST_STRING_1",
		children = {"TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2"},
		wins = {"TIER4_QUEST_STRING_1_SIDE1", "TIER4_QUEST_STRING_1_SIDE2"},
	},
	[2] = {
		main = "TIER4_QUEST_STRING_2",
		children = {"TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2"},
		wins = {"TIER4_QUEST_STRING_2_SIDE1", "TIER4_QUEST_STRING_2_SIDE2"},
	},
	[3] = {
		main = "TIER4_QUEST_STRING_3",
		children = {"TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2"},
		wins = {"TIER4_QUEST_STRING_3_SIDE1", "TIER4_QUEST_STRING_3_SIDE2"},
	},
	[4] = {
		main = "TIER4_QUEST_STRING_4",
		children = {"TIER4_QUEST_STRING_4_SIDE1", "TIER4_QUEST_STRING_4_SIDE2", "TIER4_QUEST_STRING_4_SIDE3"},
		wins = {"TIER4_QUEST_STRING_4_SIDE3"},
	},
}

arkonConvoHandler.DUTY_QUESTS = {"TIER4_QUEST_STRING_DUTY_1", "TIER4_QUEST_STRING_DUTY_2", "TIER4_QUEST_STRING_DUTY_3", "TIER4_QUEST_STRING_DUTY_4"}

arkonConvoHandler.DUTY_SCREENS = {
	duty_destroy = "TIER4_QUEST_STRING_DUTY_4",
	duty_escort = "TIER4_QUEST_STRING_DUTY_1",
	duty_recovery = "TIER4_QUEST_STRING_DUTY_3",
	duty_rescue = "TIER4_QUEST_STRING_DUTY_2",
}

arkonConvoHandler.TRAINED_SCREENS = {
	trained_starships = "pilot_rebel_navy_starships_04",
	trained_weapons = "pilot_rebel_navy_weapons_04",
	trained_procedures = "pilot_rebel_navy_procedures_04",
	trained_droid = "pilot_rebel_navy_droid_04",
}

-- Pre-NGE free choice of the next skill: { skill, reply, purchase screen }, in SWG order.
-- The replies are the skill names.
arkonConvoHandler.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_04", "@skl_n:pilot_rebel_navy_starships_04", "train_starships" },
	{ "pilot_rebel_navy_weapons_04", "@skl_n:pilot_rebel_navy_weapons_04", "train_weapons" },
	{ "pilot_rebel_navy_procedures_04", "@skl_n:pilot_rebel_navy_procedures_04", "train_procedures" },
	{ "pilot_rebel_navy_droid_04", "@skl_n:pilot_rebel_navy_droid_04", "train_droid" }
}

arkonConvoHandler.MET_SUFFIX = "HavocSquadronScreenplay:StartedArkon"

function arkonConvoHandler:questInfo(constant)
	return HavocSquadronScreenplay[constant]
end

-- Quest globals are named <type>_<name>; they are looked up at call time.
function arkonConvoHandler:questGlobal(constant)
	local quest = HavocSquadronScreenplay[constant]

	return _G[quest.type .. "_" .. quest.name]
end

function arkonConvoHandler:isActive(pPlayer, constant)
	local quest = HavocSquadronScreenplay[constant]

	return SpaceHelpers:isSpaceQuestActive(pPlayer, quest.type, quest.name)
end

function arkonConvoHandler:isComplete(pPlayer, constant)
	local quest = HavocSquadronScreenplay[constant]

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, quest.type, quest.name)
end

function arkonConvoHandler:isOnMission(pPlayer)
	for n = 1, 4 do
		local mission = self.MISSIONS[n]

		if (self:isActive(pPlayer, mission.main)) then
			return true
		end

		for _, child in ipairs(mission.children) do
			if (self:isActive(pPlayer, child)) then
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

function arkonConvoHandler:hasWon(pPlayer, n)
	for _, constant in ipairs(self.MISSIONS[n].wins) do
		if (self:isComplete(pPlayer, constant)) then
			return true
		end
	end

	return false
end

function arkonConvoHandler:statusKey(pPlayer, n, suffix)
	return CreatureObject(pPlayer):getObjectID() .. HavocSquadronScreenplay[self.MISSIONS[n].main].name .. suffix
end

function arkonConvoHandler:hasReward(pPlayer, n)
	return getQuestStatus(self:statusKey(pPlayer, n, ":reward")) == "1"
end

function arkonConvoHandler:hasAttempted(pPlayer, n)
	return getQuestStatus(self:statusKey(pPlayer, n, ":attempted")) == "1"
end

function arkonConvoHandler:canFlyNonTrackDuty(pPlayer)
	return SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3) and not self:isOnMission(pPlayer) and not SpaceHelpers:hasSpaceQuest(pPlayer)
end

function arkonConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local playerID = CreatureObject(pPlayer):getObjectID()

	if (not isJtlEnabled() or not SpaceHelpers:isPilot(pPlayer)) then
		return convoTemplate:getScreen("not_pilot")
	end

	if (not SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("wrong_faction")
	end

	if (not SpaceHelpers:isHavocSquadron(pPlayer)) then
		return convoTemplate:getScreen("not_my_track")
	end

	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 3)) then
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

	local completedTier4 = SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4)

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

	if (ghost:getFactionStanding("rebel") < 0) then
		return convoTemplate:getScreen("negative_faction")
	end

	-- Rewards due
	for n = 1, 4 do
		if (self:hasWon(pPlayer, n) and not self:hasReward(pPlayer, n)) then
			return convoTemplate:getScreen("mission" .. n .. "_reward")
		end
	end

	-- Failed missions
	for n = 1, 4 do
		if (self:hasAttempted(pPlayer, n) and not self:hasWon(pPlayer, n)) then
			return convoTemplate:getScreen("mission" .. n .. "_failed")
		end
	end

	-- Ready for the next mission, by number of tier 4 skills
	local skillCount = SpaceHelpers:getPilotTierSkillCount(pPlayer, "rebel_navy", 4)

	if (skillCount >= 1 and not self:hasReward(pPlayer, 1)) then
		return convoTemplate:getScreen("mission1_offer")
	elseif (skillCount == 2 and not self:hasReward(pPlayer, 2)) then
		return convoTemplate:getScreen("mission2_offer")
	elseif (skillCount == 3 and not self:hasReward(pPlayer, 3)) then
		return convoTemplate:getScreen("mission3_offer")
	elseif (skillCount == 4 and not self:hasReward(pPlayer, 4)) then
		return convoTemplate:getScreen("mission4_offer")
	end

	if (not completedTier4 and SpaceHelpers:hasExperienceForTraining(pPlayer, 4)) then
		return convoTemplate:getScreen("ready_train")
	end

	if (getQuestStatus(playerID .. self.MET_SUFFIX) ~= "1") then
		return convoTemplate:getScreen("intro")
	end

	if (not completedTier4) then
		return convoTemplate:getScreen("tier4_incomplete")
	end

	if (not SpaceHelpers:hasMasterSkill(pPlayer, "rebel_navy")) then
		return convoTemplate:getScreen("no_master")
	end

	return convoTemplate:getScreen("here_for_work")
end

function arkonConvoHandler:startMission(pPlayer, pNpc, n)
	local mission = self.MISSIONS[n]

	-- Clear old journal entries of this mission so it can be run again
	local main = HavocSquadronScreenplay[mission.main]
	SpaceHelpers:clearSpaceQuest(pPlayer, main.type, main.name, false)

	for _, child in ipairs(mission.children) do
		local quest = HavocSquadronScreenplay[child]
		SpaceHelpers:clearSpaceQuest(pPlayer, quest.type, quest.name, false)
	end

	setQuestStatus(self:statusKey(pPlayer, n, ":attempted"), 1)

	self:questGlobal(mission.main):startQuest(pPlayer, pNpc)
end

function arkonConvoHandler:payReward(pPlayer, ghost, n)
	if (self:hasReward(pPlayer, n)) then
		return
	end

	setQuestStatus(self:statusKey(pPlayer, n, ":reward"), 1)

	self:questGlobal(self.MISSIONS[n].main):rewardPlayer(pPlayer)

	ghost:increaseFactionStanding("rebel", 150)
end

function arkonConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()
	local playerID = CreatureObject(pPlayer):getObjectID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	-- Set player name token
	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return pClonedScreen
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return pClonedScreen
	end

	-- Non-Havoc pilots may still fly Arkon's duty missions
	if (screenID == "not_my_track") then
		local link = "nontrack_no_duty"

		if (self:canFlyNonTrackDuty(pPlayer)) then
			link = "nontrack_duty"
		end

		clonedConversation:removeAllOptions()
		clonedConversation:addOption("@conversation/corellia_rebel_tier4:s_6222b64d", link)

	-- Training menu: one choice per tier 4 skill the pilot lacks
	elseif (screenID == "ready_train") then
		clonedConversation:removeAllOptions()

		for _, choice in ipairs(self.TRAIN_CHOICES) do
			if (not CreatureObject(pPlayer):hasSkill(choice[1])) then
				clonedConversation:addOption(choice[2], choice[3])
			end
		end

	elseif (self.TRAINED_SCREENS[screenID] ~= nil) then
		local skill = self.TRAINED_SCREENS[screenID]

		if (not CreatureObject(pPlayer):hasSkill(skill) and SpaceHelpers:hasExperienceForTraining(pPlayer, 4)) then
			SpaceHelpers:grantSpaceSkill(pPlayer, skill, true)
		end

		if (ghost:getPilotTier() <= 4 and SpaceHelpers:hasCompletedPilotTier(pPlayer, "rebel_navy", 4)) then
			ghost:incrementPilotTier()
		end

	elseif (screenID == "intro_met") then
		setQuestStatus(playerID .. self.MET_SUFFIX, 1)

	elseif (self.DUTY_SCREENS[screenID] ~= nil) then
		self:questGlobal(self.DUTY_SCREENS[screenID]):startQuest(pPlayer, pNpc)

	else
		local rewardMission = string.match(screenID, "^mission(%d)_reward$")

		if (rewardMission ~= nil) then
			self:payReward(pPlayer, ghost, tonumber(rewardMission))
		else
			local mission = string.match(screenID, "^mission(%d)_accept_") or string.match(screenID, "^mission(%d)_retry_")

			if (mission ~= nil) then
				self:startMission(pPlayer, pNpc, tonumber(mission))
			end
		end
	end

	return pClonedScreen
end
