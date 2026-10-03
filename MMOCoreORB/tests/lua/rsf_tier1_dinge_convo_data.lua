-- Shared test data for the RSF tier 1 Dinge conversation (not a test file).
-- Spec: .claude/work/rsf-tier1-dinge-convo/01-spec.md (Appendix A, Content contract, Data mapping); updated for
-- .claude/work/rsf-tier1-dinge-training/01-spec.md section 3 (72 screens, 9 kept, no foreign sids, DH regions truncated or deleted).
--
-- Everything below is copied from the spec or from commit 4eefa91216, not read from dinge_convo.lua / dingeConvoHandler.lua at test
-- time, so a wrong production value makes a test fail instead of agreeing with itself:
--   D.ROWS      Appendix A, 60 rows (status "new" | "chg" | "kept"), options as {sid, link id}; yes_enlist carries no template options (E-2)
--   D.KEPT      the 9 screens that stay byte-identical, as defined at 4eefa91216 (the 9 Appendix A "kept" rows; the 7 training screens left
--               with rsf-tier1-dinge-training, see rsf_tier1_dinge_training_data.lua)
--   D.DELETED   the 20 screens F6 had for the old story mission flow
--   D.PAYS / D.STARTS  the handler contract (Content contract 2)
--   D.DH_*      the DH lines Content contract 2 says do not change, as they are at 4eefa91216

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_1:"
D.TEMPLATE = "dinge_convo_template"
D.SCREEN_COUNT = 72 -- 47 - 20 deleted + 40 new, then rsf-tier1-dinge-training: - 6 deleted + 11 new

-- Appendix A. `exceptions` marks the options whose static link differs from the java default (E-1).
D.ROWS = {
	{ id = "no_jtl", status = "kept", sid = "s_7c1fe68f", animation = "", stop = true, options = {  } },
	{ id = "rebel_pilot", status = "kept", sid = "s_72f94b8e", animation = "", stop = true, options = {  } },
	{ id = "imperial_pilot", status = "kept", sid = "s_7217d77", animation = "", stop = true, options = {  } },
	{ id = "non_rsf_pilot", status = "kept", sid = "s_6b25cc31", animation = "", stop = false, options = { {"s_c1ff5062", "non_rsf_duty_missions"} } },
	{ id = "non_rsf_duty_missions", status = "kept", sid = "s_38d8b2c4", animation = "", stop = true, options = {  } },
	{ id = "recruitment", status = "chg", sid = "s_465e6eeb", animation = "greet", stop = false, options = { {"s_d70dba34", "yes_enlist"}, {"s_4c695dbd", "no_enlist"} } },
	{ id = "yes_enlist", status = "chg", sid = "s_c19e20c9", animation = "point_to_self", stop = false, options = {  } },
	{ id = "no_enlist", status = "chg", sid = "s_789f76ee", animation = "dismiss", stop = true, options = {  } },
	{ id = "signup_no_ship", status = "new", sid = "s_e3245432", animation = "", stop = false, options = { {"s_b9b27823", "ready_first_assignment"} } },
	{ id = "ready_first_assignment", status = "chg", sid = "s_eed2fe3e", animation = "", stop = false, options = { {"s_36a4e374", "signup_offer"}, {"s_68660d24", "signup_not_ready"} } },
	{ id = "signup_offer", status = "new", sid = "s_97a2f8dc", animation = "", stop = false, options = { {"s_1db37a0f", "mission1_accept"}, {"s_48566ef9", "mission1_boast"}, {"s_7478cd28", "mission1_after_assignments"} } },
	{ id = "signup_not_ready", status = "new", sid = "s_f5f16210", animation = "", stop = true, options = {  } },
	{ id = "yes_ship", status = "chg", sid = "s_5ed33504", animation = "", stop = false, options = { {"s_30", "signup_ready_ship"}, {"s_34", "signup_ship_later"} } },
	{ id = "signup_ready_ship", status = "new", sid = "s_32", animation = "", stop = false, options = { {"s_1db37a0f", "mission1_accept"}, {"s_48566ef9", "mission1_boast"}, {"s_7478cd28", "mission1_after_assignments"} } },
	{ id = "signup_ship_later", status = "new", sid = "s_36", animation = "", stop = true, options = {  } },
	{ id = "no_ship", status = "chg", sid = "s_b24af40a", animation = "", stop = true, options = {  } },
	{ id = "has_mission", status = "chg", sid = "s_61036267", animation = "point_away", stop = true, options = {  } },
	{ id = "completed_tier1", status = "chg", sid = "s_7c4368e", animation = "", stop = false, options = { {"s_b3a9fd05", "go_to_tier2"} } },
	{ id = "go_to_tier2", status = "kept", sid = "s_919029b", animation = "", stop = true, options = {  } },
	{ id = "mission1_offer", status = "new", sid = "s_904d71cf", animation = "", stop = false, options = { {"s_1db37a0f", "mission1_accept"}, {"s_48566ef9", "mission1_boast"}, {"s_7478cd28", "mission1_after_assignments"} } },
	{ id = "mission1_accept", status = "new", sid = "s_b02e116", animation = "goodbye", stop = true, options = {  } },
	{ id = "mission1_boast", status = "new", sid = "s_bbbfb8db", animation = "pose_proudly", stop = false, options = { {"s_c261cfae", "mission1_boast_accept1"}, {"s_65d63b3c", "mission1_boast_accept2"} } },
	{ id = "mission1_boast_accept1", status = "new", sid = "s_7b3b28bf", animation = "point_away", stop = true, options = {  } },
	{ id = "mission1_boast_accept2", status = "new", sid = "s_f07f26ad", animation = "gesticulate_wildly", stop = true, options = {  } },
	{ id = "mission1_after_assignments", status = "new", sid = "s_8fb73c4", animation = "nod_head_once", stop = false, options = { {"s_1db37a0f", "mission1_accept"}, {"s_48566ef9", "mission1_boast"}, {"s_7478cd28", "mission1_after_assignments"} } },
	{ id = "mission1_active", status = "new", sid = "s_8853a92c", animation = "", stop = false, options = { {"s_60c4f974", "mission1_where_go"}, {"s_85dd7d6c", "mission1_get_back"}, {"s_4358efe9", "mission1_where_ship"} } },
	{ id = "mission1_where_go", status = "new", sid = "s_41c478b2", animation = "", stop = false, options = { {"s_60c4f974", "mission1_where_go"}, {"s_85dd7d6c", "mission1_get_back"}, {"s_4358efe9", "mission1_where_ship"} } },
	{ id = "mission1_get_back", status = "new", sid = "s_1664d807", animation = "", stop = false, options = { {"s_60c4f974", "mission1_where_go"}, {"s_85dd7d6c", "mission1_get_back"}, {"s_4358efe9", "mission1_where_ship"} } },
	{ id = "mission1_where_ship", status = "new", sid = "s_a49a3700", animation = "", stop = false, options = { {"s_60c4f974", "mission1_where_go"}, {"s_85dd7d6c", "mission1_get_back"}, {"s_4358efe9", "mission1_where_ship"} } },
	{ id = "mission1_failed", status = "new", sid = "s_443c036b", animation = "shake_head_disgust", stop = false, options = { {"s_aec5c3dd", "mission1_failed_attacked"}, {"s_ea059f38", "mission1_failed_will_do"} } },
	{ id = "mission1_failed_attacked", status = "new", sid = "s_7af03aab", animation = "cover_ears_mocking", stop = true, options = {  } },
	{ id = "mission1_failed_will_do", status = "new", sid = "s_b9c77549", animation = "point_away", stop = true, options = {  } },
	{ id = "mission1_reward", status = "new", sid = "s_5df0371b", animation = "greet", stop = true, options = {  } },
	{ id = "mission2_offer", status = "new", sid = "s_bcdb501b", animation = "explain", stop = false, options = { {"s_fb1c19c1", "mission2_brief"} } },
	{ id = "mission2_brief", status = "new", sid = "s_d487641c", animation = "shake_head_no", stop = false, options = { {"s_b5b6e634", "mission2_accept"} } },
	{ id = "mission2_accept", status = "new", sid = "s_d07cf233", animation = "wave_finger_warning", stop = true, options = {  } },
	{ id = "mission2_failed", status = "new", sid = "s_659e0fa0", animation = "point_accusingly", stop = true, options = {  } },
	{ id = "mission2_reward", status = "new", sid = "s_3d6c25c7", animation = "greet", stop = true, options = {  } },
	{ id = "mission3_offer", status = "new", sid = "s_c29502", animation = "explain", stop = false, options = { {"s_9237617f", "mission3_accept"} } },
	{ id = "mission3_accept", status = "new", sid = "s_e6c0bf4f", animation = "slow_down", stop = true, options = {  } },
	{ id = "mission3_failed", status = "new", sid = "s_652689c", animation = "cover_eyes", stop = false, options = { {"s_52", "mission3_failed_retry1"}, {"s_56", "mission3_failed_retry2"} } },
	{ id = "mission3_failed_retry1", status = "new", sid = "s_54", animation = "point_away", stop = true, options = {  } },
	{ id = "mission3_failed_retry2", status = "new", sid = "s_58", animation = "cover_ears_mocking", stop = true, options = {  } },
	{ id = "mission3_reward", status = "new", sid = "s_cd397d97", animation = "", stop = false, options = { {"s_c4682ea6", "mission3_reward_bandolier"}, {"s_1c8bddbb", "mission3_reward_bandolier"} } },
	{ id = "mission3_reward_bandolier", status = "new", sid = "s_d05d7112", animation = "rub_chin_thoughtful", stop = false, options = { {"s_3f49e786", "mission4_offer"} }, exceptions = { ["s_3f49e786"] = "E-1" } },
	{ id = "mission4_offer", status = "new", sid = "s_966bc2b6", animation = "pound_fist_palm", stop = false, options = { {"s_95", "mission4_accept"} } },
	{ id = "mission4_accept", status = "new", sid = "s_3175b359", animation = "nod_head_multiple", stop = true, options = {  } },
	{ id = "mission4_failed", status = "new", sid = "s_f742d1e8", animation = "smack_self", stop = false, options = { {"s_7eb4d42", "mission4_failed_retry1"}, {"s_48b8131c", "mission4_failed_retry2"}, {"s_7736f08b", "mission4_failed_retry3"} } },
	{ id = "mission4_failed_retry1", status = "new", sid = "s_983440a3", animation = "threaten", stop = true, options = {  } },
	{ id = "mission4_failed_retry2", status = "new", sid = "s_80744015", animation = "laugh_cackle", stop = true, options = {  } },
	{ id = "mission4_failed_retry3", status = "new", sid = "s_73f727e7", animation = "slow_down", stop = true, options = {  } },
	{ id = "mission4_reward", status = "new", sid = "s_6ea4aa1e", animation = "applause_excited", stop = true, options = {  } },
	{ id = "duty_missions", status = "chg", sid = "s_63336624", animation = "pose_proudly", stop = false, options = { {"s_6106187c", "what_is_duty"}, {"s_e814cf37", "duty_options"}, {"s_db74ddc6", "duty_no_training"}, {"s_2883b989", "duty_not_now"} } },
	{ id = "what_is_duty", status = "chg", sid = "s_a8cdf3dc", animation = "", stop = false, options = { {"s_6106187c", "what_is_duty"}, {"s_e814cf37", "duty_options"}, {"s_db74ddc6", "duty_no_training"}, {"s_2883b989", "duty_not_now"} } },
	{ id = "duty_no_training", status = "new", sid = "s_f4245779", animation = "", stop = false, options = { {"s_6106187c", "what_is_duty"}, {"s_e814cf37", "duty_options"}, {"s_db74ddc6", "duty_no_training"}, {"s_2883b989", "duty_not_now"} } },
	{ id = "duty_not_now", status = "new", sid = "s_138", animation = "", stop = true, options = {  } },
	{ id = "duty_options", status = "chg", sid = "s_e38f886b", animation = "", stop = false, options = { {"s_40759c25", "destroy_duty"}, {"s_629c7d23", "escort_duty"}, {"s_3d36a0e4", "not_ready"} } },
	{ id = "destroy_duty", status = "kept", sid = "s_6575e5d0", animation = "", stop = true, options = {  } },
	{ id = "escort_duty", status = "kept", sid = "s_90b16aa7", animation = "", stop = true, options = {  } },
	{ id = "not_ready", status = "kept", sid = "s_792ad840", animation = "", stop = true, options = {  } },
}

-- E-6: the java animation the two gate screens lack (kept without animation; gate screens are gap report item 24)
D.JAVA_ONLY_ANIMATION = { rebel_pilot = "slow_down", imperial_pilot = "salute1" }

-- Content contract 1: the 9 screens kept byte-identical (definitions at 4eefa91216)
D.KEPT = {
	["no_jtl"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_7c1fe68f", stopConversation = "true", options = {  } },
	["rebel_pilot"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_72f94b8e", stopConversation = "true", options = {  } },
	["imperial_pilot"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_7217d77", stopConversation = "true", options = {  } },
	["non_rsf_pilot"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_6b25cc31", stopConversation = "false", options = { {"@conversation/naboo_privateer_trainer_1:s_c1ff5062", "non_rsf_duty_missions"} } },
	["non_rsf_duty_missions"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_38d8b2c4", stopConversation = "true", options = {  } },
	["not_ready"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_792ad840", stopConversation = "true", options = {  } },
	["go_to_tier2"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_919029b", stopConversation = "true", options = {  } },
	["destroy_duty"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_6575e5d0", stopConversation = "true", options = {  } },
	["escort_duty"] = { leftDialog = "@conversation/naboo_privateer_trainer_1:s_90b16aa7", stopConversation = "true", options = {  } },
}

-- Content contract 1: the 20 deleted screens
D.DELETED = {
	"yes_im_ready", "go_patrol", "where_go", "first_assignment", "was_attacked", "will_do", "excellent_work", "no_training_yet", "train_me2", "go_destroy",
	"excellent_work2", "train_me3", "go_patrol3", "excellent_work3", "what_is_it", "train_me4", "will_train", "go_assassinate", "where_is_ship", "how_get_back",
}

-- Mission head, :attempted / :reward key base, per mission
D.HEADS = { "patrol_naboo_privateer_1", "destroy_naboo_privateer_2", "patrol_naboo_privateer_3", "assassinate_naboo_privateer_tier1_4a" }
D.KEYS = { "naboo_privateer_1", "naboo_privateer_2", "naboo_privateer_3", "naboo_privateer_tier1_4a" }

-- Content contract 2: the screens that pay (I-4) and the screens that start a chain (I-5), screen id -> mission
D.PAYS = { mission1_reward = 1, mission2_reward = 2, mission3_reward = 3, mission4_reward = 4 }
D.STARTS = {
	mission1_accept = 1, mission1_boast_accept1 = 1, mission1_boast_accept2 = 1, mission1_failed_attacked = 1, mission1_failed_will_do = 1,
	mission2_accept = 2, mission2_failed = 2,
	mission3_accept = 3, mission3_failed_retry1 = 3, mission3_failed_retry2 = 3,
	mission4_accept = 4, mission4_failed_retry1 = 4, mission4_failed_retry2 = 4, mission4_failed_retry3 = 4,
}
-- The failure screens: first screen of a failed mission n, and the screens its replies lead to
D.FAILED = {
	{ "mission1_failed", { "mission1_failed_attacked", "mission1_failed_will_do" } },
	{ "mission2_failed", {} },
	{ "mission3_failed", { "mission3_failed_retry1", "mission3_failed_retry2" } },
	{ "mission4_failed", { "mission4_failed_retry1", "mission4_failed_retry2", "mission4_failed_retry3" } },
}

-- Sids the files may carry that are not in the java (I-3)
D.DC_FOREIGN = {}
D.DH_FOREIGN = {}
D.GONE_SID = "s_e9c7c6bb"

-- The four screens that show a story mission's first line when the pilot has not tried it yet, then the ones for the other states
D.OFFER = { "mission1_offer", "mission2_offer", "mission3_offer", "mission4_offer" }

-- Content contract 2 / I-7: lines of dingeConvoHandler.lua at 4eefa91216 that this feature does not touch.
-- SUBSEQUENCE regions must appear line for line, in order (new lines may be inserted between them); CONTIGUOUS regions verbatim.
D.DH_GET_INITIAL_HEAD = [==[
-- Dinge (RSF tier 1) conversation handler; ported from SWG-Source naboo_privateer_trainer_1.java. Chain retry/won-check routing: feature space-trainer-fixes.
dingeConvoHandler = conv_handler:new {}

function dingeConvoHandler:getInitialScreen(pPlayer, pNpc, pConvTemplate)
	if (pPlayer == nil or pNpc == nil or pConvTemplate == nil) then
		return nil
	end

	local convoTemplate = LuaConversationTemplate(pConvTemplate)

	local faction = CreatureObject(pPlayer):getFaction()
	local playerID = CreatureObject(pPlayer):getObjectID()

	-- JTL is disabled
	if (not isJtlEnabled()) then
		return convoTemplate:getScreen("no_jtl")
	end

	-- Player is Rebel Pilot
	if (SpaceHelpers:isRebelPilot(pPlayer)) then
		return convoTemplate:getScreen("rebel_pilot")
	-- Player is Imperial Pilot
	elseif (SpaceHelpers:isImperialPilot(pPlayer)) then
		return convoTemplate:getScreen("imperial_pilot")
	end

	local isNeutralPilot = SpaceHelpers:isNeutralPilot(pPlayer)
	local hasShip = SpaceHelpers:hasCertifiedShip(pPlayer, true)

	local questOneStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_privateer_1")
	local questTwoStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_2.type, RsfSquadronScreenplay.QUEST_STRING_2.name)
	local questThreeStarted = SpaceHelpers:isSpaceQuestChainActive(pPlayer, "patrol_naboo_privateer_3")
	local questFourStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_4.type, RsfSquadronScreenplay.QUEST_STRING_4.name)

	local questOneComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_1.type, RsfSquadronScreenplay.QUEST_STRING_1.name) and SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_1_SIDE.type, RsfSquadronScreenplay.QUEST_STRING_1_SIDE.name)
	local questTwoComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_2.type, RsfSquadronScreenplay.QUEST_STRING_2.name)
	local questThreeComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_3.type, RsfSquadronScreenplay.QUEST_STRING_3.name) and SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_3_SIDE.type, RsfSquadronScreenplay.QUEST_STRING_3_SIDE.name)
	local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_4.type, RsfSquadronScreenplay.QUEST_STRING_4.name)

	local destroyDutyStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.name)
	local escortDutyStarted = SpaceHelpers:isSpaceQuestActive(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.name)

	local destroyDutyComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_1.name)
	local escortDutyComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.type, RsfSquadronScreenplay.QUEST_STRING_DUTY_4_2.name)

	-- Player is a Neutral Pilot but not RSF
	if (isNeutralPilot and not SpaceHelpers:isRSFSquadron(pPlayer)) then
		return convoTemplate:getScreen("non_rsf_pilot")
	-- Player does not have neutral pilot novice skill
	elseif (not isNeutralPilot) then
		return convoTemplate:getScreen("recruitment")

	-- Check to ensure player has a starter ship or one they can use
	elseif (not hasShip and not questOneStarted) then
		return convoTemplate:getScreen("no_ship")
	end

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return convoTemplate:getScreen("no_jtl")
	end

	-- Player destroyed their ship control device
	if (not hasShip) then
		grantStarterShip(pPlayer, "neutral")
	end

	--[[
			Quests
	--]]

	-- Player has an active quest from this trainer
	if ((questTwoStarted and not questTwoComplete) or (questThreeStarted and not questThreeComplete) or (questFourStarted and not questFourComplete) or (destroyDutyStarted and not destroyDutyComplete) or (escortDutyStarted and not escortDutyComplete)) then
		return convoTemplate:getScreen("has_mission")
	-- Check if players have all the tier1 skill boxes, send them to next trainer.
	elseif (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 1)) then
		return convoTemplate:getScreen("completed_tier1")]==]
D.DH_PROLOGUE = [==[
function dingeConvoHandler:runScreenHandlers(pConvTemplate, pPlayer, pNpc, selectedOption, pConvScreen)
	if (pPlayer == nil or pConvScreen == nil) then
		return
	end

	local screen = LuaConversationScreen(pConvScreen)
	local screenID = screen:getScreenID()

	local pClonedScreen = screen:cloneScreen()
	local clonedConversation = LuaConversationScreen(pClonedScreen)

	clonedConversation:setDialogTextTU(CreatureObject(pPlayer):getFirstName())

	local pGhost = CreatureObject(pPlayer):getPlayerObject()

	if (pGhost == nil) then
		return pClonedScreen
	end

	local ghost = LuaPlayerObject(pGhost)

	if (ghost == nil) then
		return pClonedScreen
	end]==]
D.DH_TIER2_AND_DUTIES = [==[
	elseif (screenID == "go_to_tier2") then
		-- Increment tier when player is sent to Kaydine
		if (ghost:getPilotTier() == 1) then
			ghost:incrementPilotTier()
		end
	elseif (screenID == "destroy_duty") then
		destroy_duty_naboo_privateer_6:startQuest(pPlayer, pNpc)
	elseif (screenID == "escort_duty") then
		escort_duty_naboo_privateer_7:startQuest(pPlayer, pNpc)]==]

return D
