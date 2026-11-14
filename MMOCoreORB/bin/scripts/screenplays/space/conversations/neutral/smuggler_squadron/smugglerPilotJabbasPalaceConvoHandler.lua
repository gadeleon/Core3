-- Smuggler Pilot outside Jabba's Palace conversation handler; ported from SWG-Source generic_newbie_pilot_info_jabbas_palace.java (feature tatooine-station-palace-access).
-- Handing in a signed Palace Access Document destroys it and grants the Jabba's Palace landing at Tatooine station (Smuggler squadron pilots only).
local SpaceHelpers = require("utils.space_helpers")

smugglerPilotJabbasPalaceConvoHandler = conv_handler:new {}

function smugglerPilotJabbasPalaceConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return
	end

	return LuaConversationTemplate(pConvTemplate):getScreen("greeting")
end

-- The papers_* screen the hand-in ends on (SWG order: Smugglers' Alliance, signed, signed with the right name)
function smugglerPilotJabbasPalaceConvoHandler:getPapersScreen(pPlayer, pDoc)
	if (not SpaceHelpers:isSmugglerSquadron(pPlayer)) then
		return "papers_not_smuggler"
	end

	local signature = TatooineStationPalaceAccessScreenplay:getDocSignature(pDoc)

	if (signature == "") then
		return "papers_unsigned"
	end

	if (signature ~= SceneObject(pPlayer):getDisplayedName()) then
		return "papers_wrong_name"
	end

	return "papers_accepted"
end

function smugglerPilotJabbasPalaceConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pScreenClone = screen:cloneScreen()
	local pClonedConvo = LuaConversationScreen(pScreenClone)

	if (screenID == "greeting") then
		if (SpaceHelpers:hasCertifiedShip(pPlayer, false)) then
			-- Listed first, as in SWG: the static options are re-added after it
			pClonedConvo:removeAllOptions()
			pClonedConvo:addOption("@conversation/generic_newbie_pilot_info_jabbas_palace:s_daa8544b", "palace_way") -- I need to get in the palace.
			pClonedConvo:addOption("@conversation/generic_newbie_pilot_info_jabbas_palace:s_b8b50032", "errand") -- What sort of errand did you run?
			pClonedConvo:addOption("@conversation/generic_newbie_pilot_info_jabbas_palace:s_bc4e70bf", "rest_bye") -- I better let you rest.
		end
	elseif (screenID == "palace_way") then
		local pDoc = TatooineStationPalaceAccessScreenplay:getAccessDoc(pPlayer)

		if (pDoc == nil) then
			pClonedConvo:addOption("@conversation/generic_newbie_pilot_info_jabbas_palace:s_5c484c74", "friend_hutts") -- What way is that?
		else
			pClonedConvo:addOption("@conversation/generic_newbie_pilot_info_jabbas_palace:s_f97d453c", self:getPapersScreen(pPlayer, pDoc)) -- Well I have these papers?
		end
	elseif (screenID == "papers_wrong_name") then
		pClonedConvo:setDialogTextTU(SceneObject(pPlayer):getDisplayedName())
	elseif (screenID == "papers_accepted") then
		if (TatooineStationPalaceAccessScreenplay:removeAccessDocs(pPlayer) > 0) then
			TatooineStationPalaceAccessScreenplay:grantPalaceAccess(pPlayer)
		end
	end

	return pScreenClone
end
