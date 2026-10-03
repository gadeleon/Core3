-- Shared test data for the RSF tier 2 Kaydine conversation (not a test file).
-- Spec: .claude/work/rsf-tier2-kaydine-convo/01-spec.md (Appendix A, Content contract, Data mapping).
--
-- Everything below is copied from the spec, not read from kaydine_convo.lua / kaydineConvoHandler.lua, so a wrong
-- production value makes a test fail instead of agreeing with itself:
--   D.ROWS     Appendix A, 46 rows (status "new" | "chg" | "kept"), options as {sid, link id}
--   D.KEPT     the 6 screens that stay byte-identical, copied from kaydine_convo.lua at 74247cbede (rsf-tier2-kaydine-training removed the 21 training rows)
--   D.DELETED  the 36 screens F4 had for the story missions
--   D.PAYS / D.STARTS  the handler contract (Content contract 2)
--   D.OFFER_CHAIN      the screens the "ready" option walks through, per mission

local D = {}

D.PREFIX = "@conversation/naboo_privateer_trainer_2:"
D.TEMPLATE = "kaydine_convo_template"
D.SCREEN_COUNT = 91 -- rsf-tier2-kaydine-training: 77 - 20 deleted training screens + 30 new ones, then rsf-gate-screens: + 4 gate screens

-- Appendix A. `exceptions` marks the options whose static link differs from the java default (E-1, E-2, E-3, E-5).
D.ROWS = {
	{ id = "mission1_ready", status = "new", sid = "s_8b529447", animation = "", stop = false, options = { {"s_1b428a9f", "mission1_offer"}, {"s_1c2b565d", "not_ready"} }, exceptions = { ["s_1b428a9f"] = "E-1" } },
	{ id = "mission2_ready", status = "new", sid = "s_8b529447", animation = "", stop = false, options = { {"s_1b428a9f", "mission2_offer"}, {"s_1c2b565d", "not_ready"} }, exceptions = { ["s_1b428a9f"] = "E-1" } },
	{ id = "mission3_ready", status = "new", sid = "s_8b529447", animation = "", stop = false, options = { {"s_1b428a9f", "mission3_offer"}, {"s_1c2b565d", "not_ready"} }, exceptions = { ["s_1b428a9f"] = "E-1" } },
	{ id = "mission4_ready", status = "new", sid = "s_8b529447", animation = "", stop = false, options = { {"s_1b428a9f", "mission4_offer"}, {"s_1c2b565d", "not_ready"} }, exceptions = {  } },
	{ id = "not_ready", status = "kept", sid = "s_943f6352", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_offer", status = "new", sid = "s_4a743aa7", animation = "", stop = false, options = { {"s_238", "mission1_brief"} }, exceptions = {  } },
	{ id = "mission1_brief", status = "new", sid = "s_240", animation = "", stop = false, options = { {"s_242", "mission1_accept"} }, exceptions = { ["s_242"] = "E-2" } },
	{ id = "mission1_accept_male", status = "new", sid = "s_244", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_accept", status = "new", sid = "s_246", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission2_offer", status = "new", sid = "s_9af8d581", animation = "", stop = false, options = { {"s_272", "mission2_brief"} }, exceptions = {  } },
	{ id = "mission2_brief", status = "new", sid = "s_274", animation = "", stop = false, options = { {"s_276", "mission2_details"} }, exceptions = {  } },
	{ id = "mission2_details", status = "new", sid = "s_278", animation = "", stop = false, options = { {"s_280", "mission2_accept"} }, exceptions = {  } },
	{ id = "mission2_accept", status = "new", sid = "s_282", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission3_offer", status = "new", sid = "s_130b925b", animation = "", stop = false, options = { {"s_290", "mission3_accept"} }, exceptions = {  } },
	{ id = "mission3_accept", status = "new", sid = "s_292", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission4_offer", status = "new", sid = "s_387397fb", animation = "", stop = false, options = { {"s_296", "mission4_brief"} }, exceptions = {  } },
	{ id = "mission4_brief", status = "new", sid = "s_298", animation = "", stop = false, options = { {"s_300", "mission4_accept"} }, exceptions = {  } },
	{ id = "mission4_accept", status = "new", sid = "s_302", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_failed", status = "new", sid = "s_65042122", animation = "shrug_hands", stop = false, options = { {"s_45", "mission1_failed_end"} }, exceptions = {  } },
	{ id = "mission1_failed_end", status = "new", sid = "s_bb291959", animation = "salute1", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission2_failed", status = "new", sid = "s_6da2c92b", animation = "", stop = false, options = { {"s_49", "mission2_failed_end"} }, exceptions = {  } },
	{ id = "mission2_failed_end", status = "new", sid = "s_d586f458", animation = "salute1", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission3_failed", status = "new", sid = "s_85263c6d", animation = "pound_fist_palm", stop = false, options = { {"s_c8f39347", "mission3_failed_end"} }, exceptions = {  } },
	{ id = "mission3_failed_end", status = "new", sid = "s_726bdb69", animation = "salute1", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission4_failed", status = "new", sid = "s_287eca83", animation = "shake_head_disgust", stop = false, options = { {"s_9817b9bb", "mission4_failed_end"} }, exceptions = {  } },
	{ id = "mission4_failed_end", status = "new", sid = "s_57ba8a73", animation = "salute1", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_complete", status = "new", sid = "s_43148596", animation = "", stop = false, options = { {"s_370822d1", "mission1_reward"} }, exceptions = {  } },
	{ id = "mission1_reward", status = "new", sid = "s_ef08027f", animation = "applause_polite", stop = false, options = { {"s_d65590b1", "mission1_reward_modest"}, {"s_326deced", "mission1_reward_more"} }, exceptions = {  } },
	{ id = "mission1_reward_modest", status = "new", sid = "s_8d90962a", animation = "shake_head_no", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_reward_more", status = "new", sid = "s_be7af651", animation = "", stop = false, options = { {"s_ce72ef85", "mission1_reward_joke"}, {"s_5fa9a5d3", "mission1_reward_thanks"} }, exceptions = {  } },
	{ id = "mission1_reward_joke", status = "new", sid = "s_b0ab3e88", animation = "smack_self", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission1_reward_thanks", status = "new", sid = "s_9928bf27", animation = "rub_chin_thoughtful", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission2_reward", status = "new", sid = "s_9abb9538", animation = "bow2", stop = false, options = { {"s_aa77ffde", "mission2_reward_modest"}, {"s_b45e2166", "mission2_reward_proud"} }, exceptions = {  } },
	{ id = "mission2_reward_modest", status = "new", sid = "s_da8818c5", animation = "belly_laugh", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission2_reward_proud", status = "new", sid = "s_70287826", animation = "snap_finger2", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission3_complete", status = "new", sid = "s_a0c23472", animation = "", stop = false, options = { {"s_75", "mission3_reward"} }, exceptions = {  } },
	{ id = "mission3_reward", status = "new", sid = "s_d2ffe31e", animation = "applause_polite", stop = false, options = { {"s_78", "mission3_reward_end"}, {"s_45d20070", "ready_train_pilot"}, {"s_6114e8b7", "mission3_reward_duty"} }, exceptions = { ["s_45d20070"] = "E-3" } },
	{ id = "mission3_reward_end", status = "new", sid = "s_9248b2ba", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission3_reward_duty", status = "new", sid = "s_7bc9bef7", animation = "rub_chin_thoughtful", stop = false, options = { {"s_9b73da8", "accept_duty_escort"}, {"s_30297e22", "accept_duty_recovery"}, {"s_c892e540", "accept_duty_destroy"} }, exceptions = {  } }, -- rsf-tier2-kaydine-duties: no E-5 exceptions remain
	{ id = "mission4_complete", status = "new", sid = "s_afe7700f", animation = "salute2", stop = false, options = { {"s_588f56b2", "mission4_reward"} }, exceptions = {  } },
	{ id = "mission4_reward", status = "new", sid = "s_ae21cb72", animation = "nod_head_once", stop = false, options = { {"s_c261cfae", "mission4_reward_dulios"}, {"s_725573da", "mission4_reward_end"} }, exceptions = {  } },
	{ id = "mission4_reward_dulios", status = "new", sid = "s_aae78dca", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "mission4_reward_end", status = "new", sid = "s_90", animation = "", stop = true, options = {  }, exceptions = {  } },
	{ id = "completed_kaydine", status = "chg", sid = "s_2d86b58b", animation = "", stop = false, options = { {"s_32c46e00", "completed_kaydine_end"} }, exceptions = {  } },
	{ id = "finished_tier3", status = "chg", sid = "s_2d86b58b", animation = "", stop = false, options = { {"s_32c46e00", "completed_kaydine_end"} }, exceptions = {  } },
	{ id = "completed_kaydine_end", status = "new", sid = "s_aa83c988", animation = "", stop = true, options = {  }, exceptions = {  } },
}

-- rsf-gate-screens (Appendix A-K): pilot_not_rsf, not_ready_tier2 and on_mission changed; their entries below are the definitions after that
-- feature (the other three kept screens are literally unchanged).
-- Content contract 1: the 27 screens kept byte-identical (definitions at 74247cbede; the five duty screens here_for_work, duty_options,
-- accept_duty_destroy1, accept_duty_escort and accept_duty_recovery left this list in rsf-tier2-kaydine-duties, see
-- test_rsf_tier2_kaydine_duties_dialogue.lua)
D.KEPT = {
	["not_pilot"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_3db3463f", stopConversation = "true", options = {  } },
	["pilot_not_rsf"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_c89c3456", stopConversation = "false", options = { {"@conversation/naboo_privateer_trainer_2:s_c1ff5062", "non_rsf_missions"} } },
	["non_rsf_missions"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_7458c693", stopConversation = "true", options = {  } },
	["not_ready_tier2"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_394f0902", stopConversation = "false", animation = "bow", options = { {"@conversation/naboo_privateer_trainer_2:s_b0704da1", "not_ready_tier2_end"} } },
	["on_mission"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_e95a95a5", stopConversation = "true", animation = "rub_chin_thoughtful", options = {  } },
	["not_ready"] = { leftDialog = "@conversation/naboo_privateer_trainer_2:s_943f6352", stopConversation = "true", options = {  } },
}

-- Content contract 1: the 36 deleted story screens
D.DELETED = {
	"first_mission", "failed_first_mission", "start_first_mission", "try_first_mission", "cant_wait_first", "complete_first_mission", "according_to_plan", "first_mission_success", "second_mission", "accept_escort_details", "failed_second_mission", "accept_escort", "back_to_escort", "now_is_good", "be_smarter", "complete_second_mission", "duty_calls", "here_is_pay", "third_mission", "failed_third_mission", "accept_inspect", "on_your_way", "take_it_serious", "bad_liar", "complete_third_mission", "turnover_intelligence", "fourth_mission", "failed_fourth_mission", "accept_assassinate", "nonsense", "let_me_know", "report_back_success", "key_to_success", "just_malfunctioned", "complete_fourth_mission", "fourth_mission_success"
}

-- Sids the KC/KH may carry that are not in the java (I-3)
-- rsf-tier2-kaydine-training (spec section 3): the eight old training sids are gone from both files, so nothing is foreign any more
D.KC_FOREIGN = {}
D.KH_FOREIGN = {}
D.F4_STORY_STRINGS = { "s_3cef63a0", "s_c4ef0e93", "s_ec671b3f", "s_a80d9308", "s_ff45f1fd", "s_225b33f", "s_2d67b7a8", "s_a6c7fa2b" }

-- Mission head, :attempted / :reward key base, per mission
D.HEADS = {
	"assassinate_naboo_privateer_tier2_1a", "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15",
}
D.KEYS = { "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }

-- Content contract 2: the screens that pay (I-4) and the screens that start a chain (I-5)
D.PAYS = {
	mission1_reward = 1, mission2_reward = 2, mission3_reward = 3, mission4_reward = 4,
}
D.STARTS = {
	mission1_accept = 1, mission1_accept_male = 1, mission1_failed = 1,
	mission1_intro_accept = 1, mission1_intro_accept_male = 1, -- rsf-tier2-kaydine-training I-5: the two new M1 start screens
	mission2_accept = 2, mission2_failed = 2,
	mission3_accept = 3, mission3_failed = 3,
	mission4_accept = 4, mission4_failed = 4,
}

-- Conversation flow C9 / Offer chains: the first screen of mission n (C9), then the option 1 steps to its accept screen
D.READY = { "mission1_ready", "mission2_ready", "mission3_ready", "mission4_ready" }
D.OFFER_CHAIN = {
	{ "mission1_ready", "mission1_offer", "mission1_brief", "mission1_accept" },
	{ "mission2_ready", "mission2_offer", "mission2_brief", "mission2_details", "mission2_accept" },
	{ "mission3_ready", "mission3_offer", "mission3_accept" },
	{ "mission4_ready", "mission4_offer", "mission4_brief", "mission4_accept" },
}
-- C8: first screen of a failed mission, then its end screen, and the option sid between them
D.FAILED = {
	{ "mission1_failed", "s_45", "mission1_failed_end" },
	{ "mission2_failed", "s_49", "mission2_failed_end" },
	{ "mission3_failed", "s_c8f39347", "mission3_failed_end" },
	{ "mission4_failed", "s_9817b9bb", "mission4_failed_end" },
}
-- C3 .. C6: first (complete) screen, the pay screen, the tail screens (option 1 / option 2 of the pay screen)
D.REWARD = {
	{ first = "mission1_complete", pay = "mission1_reward", tails = { "mission1_reward_modest", "mission1_reward_more" } },
	{ first = "mission2_reward", pay = "mission2_reward", tails = { "mission2_reward_modest", "mission2_reward_proud" } },
	{ first = "mission3_complete", pay = "mission3_reward", tails = { "mission3_reward_end" } },
	{ first = "mission4_complete", pay = "mission4_reward", tails = { "mission4_reward_dulios", "mission4_reward_end" } },
}

-- C9: the first screen once the mission before is paid (the next state's first screen)
D.AFTER_PAID = { "mission2_ready", "mission3_ready", "mission4_ready", "here_for_work" }

function D.rowsById()
	local byId = {}

	for _, r in ipairs(D.ROWS) do
		byId[r.id] = r
	end

	return byId
end

return D
