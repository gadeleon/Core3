-- A decoy fuel technician on Lok (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_2 is lost); feature storm-tier2-nym-technicians.

nymTechnician2ConvoHandler = conv_handler:new {}

-- First screen (side-effect free)
function nymTechnician2ConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	if (StormSquadronScreenplay:getClawStage(pPlayer) == "none") then
		return convoTemplate:getScreen("greeting")
	end

	return convoTemplate:getScreen("greeting_agent")
end

function nymTechnician2ConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	return LuaConversationScreen(pConvScreen):cloneScreen()
end
