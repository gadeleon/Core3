-- Talon Karrde (Smuggler transition quest, tier 1 -> 2, and the tier 2/3/4 done hub) conversation handler; ported from SWG-Source tatooine_privateer_trainer_2.java (features smuggler-transition-karrde, smuggler-tier2-shamdon, smuggler-tier3-beissa, smuggler-tier4-nirame).
local SpaceHelpers = require("utils.space_helpers")

talonKarrdeConvoHandler = conv_handler:new {}

-- Screens that grant the transition quest (K grantTransQuest, branches 27 and 14): the chain is started on display
talonKarrdeConvoHandler.GRANT_SCREENS = {
	job_details = true,
	trans_retry = true
}

-- K isOnTransQuest: either half of the transition quest is in the journal
function talonKarrdeConvoHandler:isOnTransQuest(pPlayer)
	return SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_tat_priv_quest_trans")
end

-- K failedTransQuest: granted before, but neither won nor running any more
function talonKarrdeConvoHandler:hasFailedTransQuest(pPlayer)
	local playerID = CreatureObject(pPlayer):getObjectID()

	return getQuestStatus(playerID .. "tat_priv_quest_trans:attempted") == "1" and not SmugglerSquadronScreenplay:hasWonTransQuest(pPlayer) and not self:isOnTransQuest(pPlayer)
end

-- Side-effect free; gates in SWG order, except tier 4 done, which sits above tier 3 done so that it can show (feature smuggler-tier4-nirame)
function talonKarrdeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local playerID = CreatureObject(pPlayer):getObjectID()

	-- Not a Smuggler Alliance member (or JTL is disabled)
	if (not isJtlEnabled() or not SpaceHelpers:isSmugglerSquadron(pPlayer)) then
		return convoTemplate:getScreen("not_member")
	end

	-- Tier 4 complete (the four tier 4 skills; SWG doneWithTier4, K:379)
	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 4)) then return convoTemplate:getScreen("tier4_done") end

	-- Tier 3 complete (the four tier 3 skills; SWG doneWithTier3)
	if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then
		return convoTemplate:getScreen("tier3_done")
	end

	-- Tier 2 series complete (Shamdon's missions and the four tier 2 skills)
	if (SmugglerSquadronScreenplay:hasCompletedTier2Series(pPlayer)) then
		return convoTemplate:getScreen("series_done")
	end

	-- Failed or aborted the transition quest
	if (self:hasFailedTransQuest(pPlayer)) then
		return convoTemplate:getScreen("trans_failed")
	end

	-- Tier 1 not complete
	if (not SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1)) then
		return convoTemplate:getScreen("dravis_employee")
	end

	local won = SmugglerSquadronScreenplay:hasWonTransQuest(pPlayer)
	local paid = getQuestStatus(playerID .. "tat_priv_quest_trans:reward") == "1"

	-- Won, waiting to deliver the package to Shamdon
	if (won and not paid) then
		return convoTemplate:getScreen("trans_won")
	end

	if (self:isOnTransQuest(pPlayer)) then
		return convoTemplate:getScreen("on_trans")
	end

	if (not won) then
		return convoTemplate:getScreen("summons")
	end

	return convoTemplate:getScreen("low_profile")
end

function talonKarrdeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return nil
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	if (self.GRANT_SCREENS[screenID]) then
		local playerID = CreatureObject(pPlayer):getObjectID()

		setQuestStatus(playerID .. "tat_priv_quest_trans:attempted", 1)
		SpaceHelpers:startSpaceQuestChain(pPlayer, pNpc, "patrol_tat_priv_quest_trans")
	end

	return pClonedScreen
end
