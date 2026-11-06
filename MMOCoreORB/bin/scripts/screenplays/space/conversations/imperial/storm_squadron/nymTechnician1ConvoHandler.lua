-- Trizan Morv, the undercover agent among Nym's fuel technicians on Lok (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_1 is lost); feature storm-tier2-nym-technicians.

nymTechnician1ConvoHandler = conv_handler:new {}

-- First screen (side-effect free)
function nymTechnician1ConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local stage = StormSquadronScreenplay:getClawStage(pPlayer)

	if (stage == "none") then
		return convoTemplate:getScreen("greeting")
	elseif (stage == "briefed") then
		return convoTemplate:getScreen("greeting_agent")
	end

	return convoTemplate:getScreen("back_again")
end

function nymTechnician1ConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	local stage = StormSquadronScreenplay:getClawStage(pPlayer)

	if (screenID == "back_again") then
		-- C-1
		clonedConversation:removeAllOptions()

		if (stage == "won") then
			clonedConversation:addOption("@conversation/nym_technician_1:s_fdee07ad", "claw_destroyed")
		else
			if (stage == "failed") then
				clonedConversation:addOption("@conversation/nym_technician_1:s_7d114e8", "keep_trying")
			end

			clonedConversation:addOption("@conversation/nym_technician_1:s_81e175a9", "find_zabrak")
			clonedConversation:addOption("@conversation/nym_technician_1:s_b8779a78", "good_luck")
		end
	elseif (screenID == "find_zabrak") then
		-- H: the tip is recorded once, while the pilot is briefed
		if (stage == "briefed") then
			local playerID = CreatureObject(pPlayer):getObjectID()

			setQuestStatus(playerID .. StormSquadronScreenplay.TIER2_MORV_TIP_KEY, 1)
		end
	end

	return pClonedScreen
end
