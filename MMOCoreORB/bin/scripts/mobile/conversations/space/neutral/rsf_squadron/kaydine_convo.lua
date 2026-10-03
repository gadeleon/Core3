kaydine_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "kaydineConvoHandler",
	screens = {}
}

-- Not a pilot or JTL disabled
not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_3db3463f", -- How do you do civilian! Captain Kaydine, at your service.
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(not_pilot);

-- Pilot but not RSF
pilot_not_rsf = ConvoScreen:new {
	id = "pilot_not_rsf",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_7ac0f961", -- How do you do. Captain Kaydine, at your service.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_c1ff5062", "non_rsf_missions"}, -- I'm looking for a mission. Do you have any?
	}
}
kaydine_convo_template:addScreen(pilot_not_rsf);

non_rsf_missions = ConvoScreen:new {
	id = "non_rsf_missions",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_7458c693", -- Sorry, kiddo. You don't have RSF clearance to fly any of my missions.
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(non_rsf_missions);

-- Not ready for Tier 2 yet
not_ready_tier2 = ConvoScreen:new {
	id = "not_ready_tier2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_eac39719", -- Sorry, kiddo. You're still in need of training! Come back when you've learned to handle yourself better.
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(not_ready_tier2);

-- Already finished Tier 3
finished_tier3 = ConvoScreen:new {
	id = "finished_tier3",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2d86b58b", -- Hey, kiddo! What are you still doing around here? You got bigger, better things to be doing!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_32c46e00", "completed_kaydine_end"},
	}
}
kaydine_convo_template:addScreen(finished_tier3);

-- On mission already
on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_e95a95a5", -- I believe you have some business to attend to... in space?
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(on_mission);

-- Completed Kaydine's tier, go to next trainer (Dulios)
completed_kaydine = ConvoScreen:new {
	id = "completed_kaydine",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2d86b58b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_32c46e00", "completed_kaydine_end"},
	}
}
kaydine_convo_template:addScreen(completed_kaydine);

-- Here for work (default greeting, naboo_privateer_trainer_2.java:4332-4369)
here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_c5fcc7f5", -- Greetings, Captain %TU! Are you ready to take my place on the duty roster?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_4a1d2431", "duty_options"}, -- I'm ready for duty
	}
}
kaydine_convo_template:addScreen(here_for_work);

-- Duty mission options (naboo_privateer_trainer_2.java:2099-2158)
duty_options = ConvoScreen:new {
	id = "duty_options",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_63053557", -- Good! What duty element do you want to participate in today?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_9b73da8", "accept_duty_escort"}, -- Protect the Royal Kylantha cargo.
		{"@conversation/naboo_privateer_trainer_2:s_30297e22", "accept_duty_recovery"}, -- Recover ships stolen by the Ay'Nat Legion.
		{"@conversation/naboo_privateer_trainer_2:s_c892e540", "accept_duty_destroy"}, -- Destroy Ay'Nat Legion pirates in this system.
	}
}
kaydine_convo_template:addScreen(duty_options);

accept_duty_escort = ConvoScreen:new {
	id = "accept_duty_escort",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_b104c183", -- A fine choice, my friend. I will add you to the Queen's duty roster. Good luck up there! (naboo_privateer_trainer_2.java:2162-2172)
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(accept_duty_escort);

accept_duty_recovery = ConvoScreen:new {
	id = "accept_duty_recovery",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_a91b70fb", -- Those Ay'Nat are the worst! You bet! I'll be updating the duty roster with your pilot info presently. Good luck! (naboo_privateer_trainer_2.java:2174-2184)
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(accept_duty_recovery);

accept_duty_destroy = ConvoScreen:new {
	id = "accept_duty_destroy",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_a0072111", -- Hm. A grim job if there ever was one. I respect your courage. Good luck! (naboo_privateer_trainer_2.java:2186-2196)
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(accept_duty_destroy);

-- Training screen (options added dynamically)
ready_train_pilot = ConvoScreen:new {
	id = "ready_train_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8a84109d", -- It must be your lucky day. I actually do have some elective duty missions. Take a look and tell me what you want.
	stopConversation = "false",
	options = {}
}
kaydine_convo_template:addScreen(ready_train_pilot);

-- Training completion screens
initial_train_fighters = ConvoScreen:new {
	id = "initial_train_fighters",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e", -- Ah yes! Good choice! Learning to fly many different types of ships makes an effective pilot!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(initial_train_fighters);

initial_train_components = ConvoScreen:new {
	id = "initial_train_components",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e", -- You bet! New components should make your ship more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(initial_train_components);

initial_train_techniques = ConvoScreen:new {
	id = "initial_train_techniques",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e", -- You bet! New defense procedures should make you more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(initial_train_techniques);

initial_train_algorithms = ConvoScreen:new {
	id = "initial_train_algorithms",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb", -- You bet! New droid algorithms in there should make you more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(initial_train_algorithms);

-- Mission 2 training screens
mission2_train_fighters = ConvoScreen:new {
	id = "mission2_train_fighters",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e", -- Ah yes! Good choice!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_train_fighters);

mission2_train_components = ConvoScreen:new {
	id = "mission2_train_components",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e", -- You bet! New components...
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_train_components);

mission2_train_techniques = ConvoScreen:new {
	id = "mission2_train_techniques",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e", -- You bet! New defense procedures...
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_train_techniques);

mission2_train_algorithms = ConvoScreen:new {
	id = "mission2_train_algorithms",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb", -- You bet! New droid algorithms...
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_train_algorithms);

-- Mission 3 training screens
mission3_train_fighters = ConvoScreen:new {
	id = "mission3_train_fighters",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_train_fighters);

mission3_train_components = ConvoScreen:new {
	id = "mission3_train_components",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_train_components);

mission3_train_techniques = ConvoScreen:new {
	id = "mission3_train_techniques",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_train_techniques);

mission3_train_algorithms = ConvoScreen:new {
	id = "mission3_train_algorithms",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_train_algorithms);

-- Mission 4 training screens
mission4_train_fighters = ConvoScreen:new {
	id = "mission4_train_fighters",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_train_fighters);

mission4_train_components = ConvoScreen:new {
	id = "mission4_train_components",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_train_components);

mission4_train_techniques = ConvoScreen:new {
	id = "mission4_train_techniques",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_train_techniques);

mission4_train_algorithms = ConvoScreen:new {
	id = "mission4_train_algorithms",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_train_algorithms);

-- Final training screens
final_train_fighters = ConvoScreen:new {
	id = "final_train_fighters",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(final_train_fighters);

final_train_components = ConvoScreen:new {
	id = "final_train_components",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(final_train_components);

final_train_techniques = ConvoScreen:new {
	id = "final_train_techniques",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(final_train_techniques);

final_train_algorithms = ConvoScreen:new {
	id = "final_train_algorithms",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(final_train_algorithms);

-- Story missions (SWG naboo_privateer_trainer_2 dialogue)
mission1_ready = ConvoScreen:new {
	id = "mission1_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8b529447",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_1b428a9f", "mission1_offer"},
		{"@conversation/naboo_privateer_trainer_2:s_1c2b565d", "not_ready"},
	}
}
kaydine_convo_template:addScreen(mission1_ready);

mission2_ready = ConvoScreen:new {
	id = "mission2_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8b529447",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_1b428a9f", "mission2_offer"},
		{"@conversation/naboo_privateer_trainer_2:s_1c2b565d", "not_ready"},
	}
}
kaydine_convo_template:addScreen(mission2_ready);

mission3_ready = ConvoScreen:new {
	id = "mission3_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8b529447",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_1b428a9f", "mission3_offer"},
		{"@conversation/naboo_privateer_trainer_2:s_1c2b565d", "not_ready"},
	}
}
kaydine_convo_template:addScreen(mission3_ready);

mission4_ready = ConvoScreen:new {
	id = "mission4_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8b529447",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_1b428a9f", "mission4_offer"},
		{"@conversation/naboo_privateer_trainer_2:s_1c2b565d", "not_ready"},
	}
}
kaydine_convo_template:addScreen(mission4_ready);

mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4a743aa7",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_238", "mission1_brief"},
	}
}
kaydine_convo_template:addScreen(mission1_offer);

mission1_brief = ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_240",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_242", "mission1_accept"},
	}
}
kaydine_convo_template:addScreen(mission1_brief);

mission1_accept_male = ConvoScreen:new {
	id = "mission1_accept_male",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_244",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission1_accept_male);

mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_246",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission1_accept);

mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9af8d581",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_272", "mission2_brief"},
	}
}
kaydine_convo_template:addScreen(mission2_offer);

mission2_brief = ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_274",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_276", "mission2_details"},
	}
}
kaydine_convo_template:addScreen(mission2_brief);

mission2_details = ConvoScreen:new {
	id = "mission2_details",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_278",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_280", "mission2_accept"},
	}
}
kaydine_convo_template:addScreen(mission2_details);

mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_282",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_accept);

mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_130b925b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_290", "mission3_accept"},
	}
}
kaydine_convo_template:addScreen(mission3_offer);

mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_292",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_accept);

mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_387397fb",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_296", "mission4_brief"},
	}
}
kaydine_convo_template:addScreen(mission4_offer);

mission4_brief = ConvoScreen:new {
	id = "mission4_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_298",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_300", "mission4_accept"},
	}
}
kaydine_convo_template:addScreen(mission4_brief);

mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_302",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_accept);

mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_65042122",
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_45", "mission1_failed_end"},
	}
}
kaydine_convo_template:addScreen(mission1_failed);

mission1_failed_end = ConvoScreen:new {
	id = "mission1_failed_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_bb291959",
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(mission1_failed_end);

mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_6da2c92b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_49", "mission2_failed_end"},
	}
}
kaydine_convo_template:addScreen(mission2_failed);

mission2_failed_end = ConvoScreen:new {
	id = "mission2_failed_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_d586f458",
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(mission2_failed_end);

mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_85263c6d",
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_c8f39347", "mission3_failed_end"},
	}
}
kaydine_convo_template:addScreen(mission3_failed);

mission3_failed_end = ConvoScreen:new {
	id = "mission3_failed_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_726bdb69",
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(mission3_failed_end);

mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_287eca83",
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_9817b9bb", "mission4_failed_end"},
	}
}
kaydine_convo_template:addScreen(mission4_failed);

mission4_failed_end = ConvoScreen:new {
	id = "mission4_failed_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_57ba8a73",
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(mission4_failed_end);

mission1_complete = ConvoScreen:new {
	id = "mission1_complete",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_43148596",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_370822d1", "mission1_reward"},
	}
}
kaydine_convo_template:addScreen(mission1_complete);

mission1_reward = ConvoScreen:new {
	id = "mission1_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_ef08027f",
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_d65590b1", "mission1_reward_modest"},
		{"@conversation/naboo_privateer_trainer_2:s_326deced", "mission1_reward_more"},
	}
}
kaydine_convo_template:addScreen(mission1_reward);

mission1_reward_modest = ConvoScreen:new {
	id = "mission1_reward_modest",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8d90962a",
	stopConversation = "true",
	animation = "shake_head_no",
	options = {}
}
kaydine_convo_template:addScreen(mission1_reward_modest);

mission1_reward_more = ConvoScreen:new {
	id = "mission1_reward_more",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_be7af651",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_ce72ef85", "mission1_reward_joke"},
		{"@conversation/naboo_privateer_trainer_2:s_5fa9a5d3", "mission1_reward_thanks"},
	}
}
kaydine_convo_template:addScreen(mission1_reward_more);

mission1_reward_joke = ConvoScreen:new {
	id = "mission1_reward_joke",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_b0ab3e88",
	stopConversation = "true",
	animation = "smack_self",
	options = {}
}
kaydine_convo_template:addScreen(mission1_reward_joke);

mission1_reward_thanks = ConvoScreen:new {
	id = "mission1_reward_thanks",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9928bf27",
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {}
}
kaydine_convo_template:addScreen(mission1_reward_thanks);

mission2_reward = ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9abb9538",
	stopConversation = "false",
	animation = "bow2",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_aa77ffde", "mission2_reward_modest"},
		{"@conversation/naboo_privateer_trainer_2:s_b45e2166", "mission2_reward_proud"},
	}
}
kaydine_convo_template:addScreen(mission2_reward);

mission2_reward_modest = ConvoScreen:new {
	id = "mission2_reward_modest",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_da8818c5",
	stopConversation = "true",
	animation = "belly_laugh",
	options = {}
}
kaydine_convo_template:addScreen(mission2_reward_modest);

mission2_reward_proud = ConvoScreen:new {
	id = "mission2_reward_proud",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_70287826",
	stopConversation = "true",
	animation = "snap_finger2",
	options = {}
}
kaydine_convo_template:addScreen(mission2_reward_proud);

mission3_complete = ConvoScreen:new {
	id = "mission3_complete",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_a0c23472",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_75", "mission3_reward"},
	}
}
kaydine_convo_template:addScreen(mission3_complete);

mission3_reward = ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_d2ffe31e",
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_78", "mission3_reward_end"},
		{"@conversation/naboo_privateer_trainer_2:s_45d20070", "ready_train_pilot"},
		{"@conversation/naboo_privateer_trainer_2:s_6114e8b7", "mission3_reward_duty"},
	}
}
kaydine_convo_template:addScreen(mission3_reward);

mission3_reward_end = ConvoScreen:new {
	id = "mission3_reward_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9248b2ba",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_reward_end);

mission3_reward_duty = ConvoScreen:new {
	id = "mission3_reward_duty",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_7bc9bef7",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_9b73da8", "accept_duty_escort"},
		{"@conversation/naboo_privateer_trainer_2:s_30297e22", "accept_duty_recovery"},
		{"@conversation/naboo_privateer_trainer_2:s_c892e540", "accept_duty_destroy"},
	}
}
kaydine_convo_template:addScreen(mission3_reward_duty);

mission4_complete = ConvoScreen:new {
	id = "mission4_complete",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_afe7700f",
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_588f56b2", "mission4_reward"},
	}
}
kaydine_convo_template:addScreen(mission4_complete);

mission4_reward = ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_ae21cb72",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_c261cfae", "mission4_reward_dulios"},
		{"@conversation/naboo_privateer_trainer_2:s_725573da", "mission4_reward_end"},
	}
}
kaydine_convo_template:addScreen(mission4_reward);

mission4_reward_dulios = ConvoScreen:new {
	id = "mission4_reward_dulios",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_aae78dca",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_reward_dulios);

mission4_reward_end = ConvoScreen:new {
	id = "mission4_reward_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_90",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission4_reward_end);

completed_kaydine_end = ConvoScreen:new {
	id = "completed_kaydine_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_aa83c988",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(completed_kaydine_end);

-- Not ready
not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_943f6352", -- Alright. Hurry up and come back when you're ready.
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(not_ready);

addConversationTemplate("kaydine_convo_template", kaydine_convo_template)
