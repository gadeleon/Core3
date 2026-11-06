-- Lt. Colonel Barlow (Inquisition tier 3 interrogation) conversation handler; ported from SWG-Source naboo_imperial_tier3_barlow.java: gates and the removeTalktoBarlow hand-shake with Vrke, pre-NGE client lines (feature inquisition-tier3-barlow).
local SpaceHelpers = require("utils.space_helpers")

barlowConvoHandler = conv_handler:new {}

-- The interview end screens: J3B removeTalktoBarlow runs right before each of these lines
barlowConvoHandler.END_SCREENS = {
	end_65ec117a = true,
	end_3be36a24 = true,
	end_4ccd5b75 = true,
	end_7ebbd888 = true,
	end_2b71207d = true
}

-- First screen (side-effect free). Gate order follows naboo_imperial_tier3_barlow.java OnStartNpcConversation (:4611 on)
function barlowConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	-- JTL is disabled, or not a player
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("restricted")
	end

	if (CreatureObject(pPlayer):getPlayerObject() == nil) then
		return convoTemplate:getScreen("restricted")
	end

	-- isCorrectFaction
	if (not SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("restricted")
	end

	local IS = InquisitionSquadronScreenplay
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- setByInquisition (questionBarlow)
	if (getQuestStatus(playerID .. IS.QUESTION_BARLOW_KEY) == "1") then
		return convoTemplate:getScreen("interview")
	end

	-- alreadyTalkedTo (spokeToBarlow)
	if (getQuestStatus(playerID .. IS.SPOKE_TO_BARLOW_KEY) == "1") then
		return convoTemplate:getScreen("already_spoke")
	end

	return convoTemplate:getScreen("not_requested")
end

function barlowConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return nil
	end

	local screenID = LuaConversationScreen(pConvScreen):getScreenID()

	if (self.END_SCREENS[screenID]) then
		local playerID = CreatureObject(pPlayer):getObjectID()

		-- removeTalktoBarlow
		removeQuestStatus(playerID .. InquisitionSquadronScreenplay.QUESTION_BARLOW_KEY)
		setQuestStatus(playerID .. InquisitionSquadronScreenplay.SPOKE_TO_BARLOW_KEY, 1)
	end

	return pConvScreen
end
