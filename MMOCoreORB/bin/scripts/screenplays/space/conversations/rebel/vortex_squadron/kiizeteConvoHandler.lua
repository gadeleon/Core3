-- Kiizete (Vortex Squadron tier 1 side NPC) conversation handler; ported from SWG-Source naboo_rebel_tier1_kiizete.java with the pre-NGE client lines (feature vortex-tier1-kiizete). She grants nothing; her two SWG scriptVar flags are VortexSquadronScreenplay session flags.
local SpaceHelpers = require("utils.space_helpers")

kiizeteConvoHandler = conv_handler:new {}

-- Screens that carry the player's name (%NU)
kiizeteConvoHandler.NAME_SCREENS = {
	meet_name = true, meet_destiny = true
}

-- naboo_rebel_tier1_kiizete.java:16-27
function kiizeteConvoHandler:isImperial(pPlayer)
	return CreatureObject(pPlayer):getFaction() == FACTIONIMPERIAL or SpaceHelpers:isImperialPilot(pPlayer)
end

-- naboo_rebel_tier1_kiizete.java:40-50
function kiizeteConvoHandler:isOnFirstMission(pPlayer)
	return SpaceHelpers:hasCertifiedShip(pPlayer, true) and SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_1")
end

-- naboo_rebel_tier1_kiizete.java hasCompletedQuestOne (both quests, as V3-FX)
function kiizeteConvoHandler:hasWonMissionOne(pPlayer)
	local VS = VortexSquadronScreenplay

	return SpaceHelpers:isSpaceQuestComplete(pPlayer, VS.QUEST_STRING_1.type, VS.QUEST_STRING_1.name)
		and SpaceHelpers:isSpaceQuestComplete(pPlayer, VS.QUEST_STRING_1_SIDE.type, VS.QUEST_STRING_1_SIDE.name)
end

-- naboo_rebel_tier1_kiizete.java hasFailedQuestOne (attempted, not won, not running; as V3-FX)
function kiizeteConvoHandler:hasFailedMissionOne(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. VortexSquadronScreenplay.QUEST_STRING_1.name .. ":attempted") == "1"
		and not self:hasWonMissionOne(pPlayer)
		and not SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_rebel_1")
end

-- First screen (side-effect free). Gate order follows naboo_rebel_tier1_kiizete.java OnStartNpcConversation (:2850 on)
function kiizeteConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local VS = VortexSquadronScreenplay

	if (not isJtlEnabled() or CreatureObject(pPlayer):getPlayerObject() == nil) then
		return convoTemplate:getScreen("no_jtl")
	elseif (VS:hasKiizeteFlag(pPlayer, VS.KIIZETE_IMP_ASKING_KEY)) then
		return convoTemplate:getScreen("imperial_again")
	elseif (self:isImperial(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	elseif (VS:hasKiizeteFlag(pPlayer, VS.KIIZETE_Q1_DISCUSSED_KEY)) then
		return convoTemplate:getScreen("first_mission_again")
	elseif (self:isOnFirstMission(pPlayer)) then
		return convoTemplate:getScreen("first_mission")
	elseif (self:hasFailedMissionOne(pPlayer)) then
		return convoTemplate:getScreen("mission1_failed")
	elseif (self:hasWonMissionOne(pPlayer)) then
		return convoTemplate:getScreen("mission1_won")
	end

	return convoTemplate:getScreen("stranger")
end

function kiizeteConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()
	local VS = VortexSquadronScreenplay

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	if (self.NAME_SCREENS[screenID]) then
		clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())
	end

	-- SWG an_imp_is_asking and q1_set_discussed
	if (screenID == "imperial_pilot") then
		VS:setKiizeteFlag(pPlayer, VS.KIIZETE_IMP_ASKING_KEY)
	elseif (screenID == "first_mission") then
		VS:setKiizeteFlag(pPlayer, VS.KIIZETE_Q1_DISCUSSED_KEY)
	end

	return pClonedScreen
end
