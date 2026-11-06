-- The Zabrak fuel technician on Lok, who tells the pilot where the Kimogila's Claw is (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_3 is lost); feature storm-tier2-nym-technicians.

nymTechnician3ConvoHandler = conv_handler:new {}

-- First screen (side-effect free)
function nymTechnician3ConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)
	local stage = StormSquadronScreenplay:getClawStage(pPlayer)

	if (stage == "none") then
		return convoTemplate:getScreen("greeting")
	elseif (stage == "briefed" or stage == "tipped") then
		return convoTemplate:getScreen("greeting_agent")
	end

	return convoTemplate:getScreen("you_again")
end

function nymTechnician3ConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	local SS = StormSquadronScreenplay

	if (screenID == "greeting_agent") then
		-- C-2: the fuel-balance line only while the Claw can be granted
		if (SS:canStartClaw(pPlayer)) then
			clonedConversation:removeAllOptions()
			clonedConversation:addOption("@conversation/nym_technician_3:s_7002e5c4", "balance_perfect")
			clonedConversation:addOption("@conversation/nym_technician_3:s_67a590c3", "ahead_of_schedule")
			clonedConversation:addOption("@conversation/nym_technician_3:s_62f865dd", "pilot_slang")
			clonedConversation:addOption("@conversation/nym_technician_3:s_f49a789f", "disgusting")
			clonedConversation:addOption("@conversation/nym_technician_3:s_88d98675", "pilot_ship")
		end
	elseif (screenID == "you_again") then
		-- C-3
		local stage = SS:getClawStage(pPlayer)

		clonedConversation:removeAllOptions()

		if (stage == "active" or SS:canStartClaw(pPlayer)) then
			clonedConversation:addOption("@conversation/nym_technician_3:s_248faf8a", "long_gone")
		end

		clonedConversation:addOption("@conversation/nym_technician_3:s_52fbe706", "clear_out")
	elseif (screenID == "long_gone") then
		-- H: the grant (guarded, so an active, won or blocked Claw is not started again)
		SS:startClaw(pPlayer, pNpc)
	end

	return pClonedScreen
end
