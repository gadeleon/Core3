dinge_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "dingeConvoHandler",
	screens = {}
}

no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_7c1fe68f", -- Sorry, but I can't chit-chat with you. I'm busy doing important Royal Security work here.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(no_jtl);

rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_72f94b8e", -- I think you're a pilot for the Rebel Alliance! Look, the Royal Security Forces don't have any use for the likes of you. I think you should leave now.
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
dinge_convo_template:addScreen(rebel_pilot);

imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_7217d77", -- Greetings officer! Nothing to worry about here, we've got everything under control.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
dinge_convo_template:addScreen(imperial_pilot);

non_rsf_pilot = ConvoScreen:new {
	id = "non_rsf_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_6b25cc31", -- I've heard you're quite a pilot. What brings you to speak with the Royal Security Forces?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_c1ff5062", "non_rsf_duty_missions"}, -- I'm looking for a mission. Do you have any?
	}
}
dinge_convo_template:addScreen(non_rsf_pilot);

non_rsf_duty_offer = ConvoScreen:new {
	id = "non_rsf_duty_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_1e029d90",
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_6106187c", "what_is_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_e814cf37", "duty_options"},
		{"@conversation/naboo_privateer_trainer_1:s_db74ddc6", "duty_no_training"},
		{"@conversation/naboo_privateer_trainer_1:s_2883b989", "duty_not_now"},
	}
}
dinge_convo_template:addScreen(non_rsf_duty_offer);

non_rsf_duty_missions = ConvoScreen:new {
	id = "non_rsf_duty_missions",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_38d8b2c4", -- I appreciate your enthusiasm, but unless you're a member of the RSF, I'm afraid I cannot help you. Talk to your own contacts if you're looking for a mission.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(non_rsf_duty_missions);

recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_465e6eeb",
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_d70dba34", "yes_enlist"},
		{"@conversation/naboo_privateer_trainer_1:s_4c695dbd", "no_enlist"},
	}
}
dinge_convo_template:addScreen(recruitment);

yes_enlist = ConvoScreen:new {
	id = "yes_enlist",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_c19e20c9",
	stopConversation = "false",
	animation = "point_to_self",
	options = {}
}
dinge_convo_template:addScreen(yes_enlist);

no_enlist = ConvoScreen:new {
	id = "no_enlist",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_789f76ee",
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dinge_convo_template:addScreen(no_enlist);

signup_no_ship = ConvoScreen:new {
	id = "signup_no_ship",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_e3245432",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_b9b27823", "ready_first_assignment"},
	}
}
dinge_convo_template:addScreen(signup_no_ship);

ready_first_assignment = ConvoScreen:new {
	id = "ready_first_assignment",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_eed2fe3e",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_36a4e374", "signup_offer"},
		{"@conversation/naboo_privateer_trainer_1:s_68660d24", "signup_not_ready"},
	}
}
dinge_convo_template:addScreen(ready_first_assignment);

signup_offer = ConvoScreen:new {
	id = "signup_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_97a2f8dc",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_1db37a0f", "mission1_accept"},
		{"@conversation/naboo_privateer_trainer_1:s_48566ef9", "mission1_boast"},
		{"@conversation/naboo_privateer_trainer_1:s_7478cd28", "mission1_after_assignments"},
	}
}
dinge_convo_template:addScreen(signup_offer);

signup_not_ready = ConvoScreen:new {
	id = "signup_not_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_f5f16210",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(signup_not_ready);

yes_ship = ConvoScreen:new {
	id = "yes_ship",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_5ed33504",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_30", "signup_ready_ship"},
		{"@conversation/naboo_privateer_trainer_1:s_34", "signup_ship_later"},
	}
}
dinge_convo_template:addScreen(yes_ship);

signup_ready_ship = ConvoScreen:new {
	id = "signup_ready_ship",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_32",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_1db37a0f", "mission1_accept"},
		{"@conversation/naboo_privateer_trainer_1:s_48566ef9", "mission1_boast"},
		{"@conversation/naboo_privateer_trainer_1:s_7478cd28", "mission1_after_assignments"},
	}
}
dinge_convo_template:addScreen(signup_ready_ship);

signup_ship_later = ConvoScreen:new {
	id = "signup_ship_later",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_36",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(signup_ship_later);

no_ship = ConvoScreen:new {
	id = "no_ship",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_b24af40a",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(no_ship);

has_mission = ConvoScreen:new {
	id = "has_mission",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_61036267",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dinge_convo_template:addScreen(has_mission);

completed_tier1 = ConvoScreen:new {
	id = "completed_tier1",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_7c4368e",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_b3a9fd05", "go_to_tier2"},
	}
}
dinge_convo_template:addScreen(completed_tier1);

go_to_tier2 = ConvoScreen:new {
	id = "go_to_tier2",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_919029b", -- Go see Captain Kaydine. He is in one of the large meeting rooms upstairs here in the palace. Should be easy to find, just follow the ego.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(go_to_tier2);

mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_904d71cf",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_1db37a0f", "mission1_accept"},
		{"@conversation/naboo_privateer_trainer_1:s_48566ef9", "mission1_boast"},
		{"@conversation/naboo_privateer_trainer_1:s_7478cd28", "mission1_after_assignments"},
	}
}
dinge_convo_template:addScreen(mission1_offer);

mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_b02e116",
	stopConversation = "true",
	animation = "goodbye",
	options = {}
}
dinge_convo_template:addScreen(mission1_accept);

mission1_boast = ConvoScreen:new {
	id = "mission1_boast",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_bbbfb8db",
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_c261cfae", "mission1_boast_accept1"},
		{"@conversation/naboo_privateer_trainer_1:s_65d63b3c", "mission1_boast_accept2"},
	}
}
dinge_convo_template:addScreen(mission1_boast);

mission1_boast_accept1 = ConvoScreen:new {
	id = "mission1_boast_accept1",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_7b3b28bf",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dinge_convo_template:addScreen(mission1_boast_accept1);

mission1_boast_accept2 = ConvoScreen:new {
	id = "mission1_boast_accept2",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_f07f26ad",
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {}
}
dinge_convo_template:addScreen(mission1_boast_accept2);

mission1_after_assignments = ConvoScreen:new {
	id = "mission1_after_assignments",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_8fb73c4",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_1db37a0f", "mission1_accept"},
		{"@conversation/naboo_privateer_trainer_1:s_48566ef9", "mission1_boast"},
		{"@conversation/naboo_privateer_trainer_1:s_7478cd28", "mission1_after_assignments"},
	}
}
dinge_convo_template:addScreen(mission1_after_assignments);

mission1_active = ConvoScreen:new {
	id = "mission1_active",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_8853a92c",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_60c4f974", "mission1_where_go"},
		{"@conversation/naboo_privateer_trainer_1:s_85dd7d6c", "mission1_get_back"},
		{"@conversation/naboo_privateer_trainer_1:s_4358efe9", "mission1_where_ship"},
	}
}
dinge_convo_template:addScreen(mission1_active);

mission1_where_go = ConvoScreen:new {
	id = "mission1_where_go",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_41c478b2",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_60c4f974", "mission1_where_go"},
		{"@conversation/naboo_privateer_trainer_1:s_85dd7d6c", "mission1_get_back"},
		{"@conversation/naboo_privateer_trainer_1:s_4358efe9", "mission1_where_ship"},
	}
}
dinge_convo_template:addScreen(mission1_where_go);

mission1_get_back = ConvoScreen:new {
	id = "mission1_get_back",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_1664d807",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_60c4f974", "mission1_where_go"},
		{"@conversation/naboo_privateer_trainer_1:s_85dd7d6c", "mission1_get_back"},
		{"@conversation/naboo_privateer_trainer_1:s_4358efe9", "mission1_where_ship"},
	}
}
dinge_convo_template:addScreen(mission1_get_back);

mission1_where_ship = ConvoScreen:new {
	id = "mission1_where_ship",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_a49a3700",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_60c4f974", "mission1_where_go"},
		{"@conversation/naboo_privateer_trainer_1:s_85dd7d6c", "mission1_get_back"},
		{"@conversation/naboo_privateer_trainer_1:s_4358efe9", "mission1_where_ship"},
	}
}
dinge_convo_template:addScreen(mission1_where_ship);

mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_443c036b",
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_aec5c3dd", "mission1_failed_attacked"},
		{"@conversation/naboo_privateer_trainer_1:s_ea059f38", "mission1_failed_will_do"},
	}
}
dinge_convo_template:addScreen(mission1_failed);

mission1_failed_attacked = ConvoScreen:new {
	id = "mission1_failed_attacked",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_7af03aab",
	stopConversation = "true",
	animation = "cover_ears_mocking",
	options = {}
}
dinge_convo_template:addScreen(mission1_failed_attacked);

mission1_failed_will_do = ConvoScreen:new {
	id = "mission1_failed_will_do",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_b9c77549",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dinge_convo_template:addScreen(mission1_failed_will_do);

mission1_reward = ConvoScreen:new {
	id = "mission1_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_5df0371b",
	stopConversation = "true",
	animation = "greet",
	options = {}
}
dinge_convo_template:addScreen(mission1_reward);

mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_bcdb501b",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_fb1c19c1", "mission2_brief"},
	}
}
dinge_convo_template:addScreen(mission2_offer);

mission2_brief = ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_d487641c",
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_b5b6e634", "mission2_accept"},
	}
}
dinge_convo_template:addScreen(mission2_brief);

mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_d07cf233",
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
dinge_convo_template:addScreen(mission2_accept);

mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_659e0fa0",
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
dinge_convo_template:addScreen(mission2_failed);

mission2_reward = ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_3d6c25c7",
	stopConversation = "true",
	animation = "greet",
	options = {}
}
dinge_convo_template:addScreen(mission2_reward);

mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_c29502",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_9237617f", "mission3_accept"},
	}
}
dinge_convo_template:addScreen(mission3_offer);

mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_e6c0bf4f",
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
dinge_convo_template:addScreen(mission3_accept);

mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_652689c",
	stopConversation = "false",
	animation = "cover_eyes",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_52", "mission3_failed_retry1"},
		{"@conversation/naboo_privateer_trainer_1:s_56", "mission3_failed_retry2"},
	}
}
dinge_convo_template:addScreen(mission3_failed);

mission3_failed_retry1 = ConvoScreen:new {
	id = "mission3_failed_retry1",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_54",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dinge_convo_template:addScreen(mission3_failed_retry1);

mission3_failed_retry2 = ConvoScreen:new {
	id = "mission3_failed_retry2",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_58",
	stopConversation = "true",
	animation = "cover_ears_mocking",
	options = {}
}
dinge_convo_template:addScreen(mission3_failed_retry2);

mission3_reward = ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_cd397d97",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_c4682ea6", "mission3_reward_bandolier"},
		{"@conversation/naboo_privateer_trainer_1:s_1c8bddbb", "mission3_reward_bandolier"},
	}
}
dinge_convo_template:addScreen(mission3_reward);

mission3_reward_bandolier = ConvoScreen:new {
	id = "mission3_reward_bandolier",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_d05d7112",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_3f49e786", "mission4_offer"},
	}
}
dinge_convo_template:addScreen(mission3_reward_bandolier);

mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_966bc2b6",
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_95", "mission4_accept"},
	}
}
dinge_convo_template:addScreen(mission4_offer);

mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_3175b359",
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {}
}
dinge_convo_template:addScreen(mission4_accept);

mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_f742d1e8",
	stopConversation = "false",
	animation = "smack_self",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_7eb4d42", "mission4_failed_retry1"},
		{"@conversation/naboo_privateer_trainer_1:s_48b8131c", "mission4_failed_retry2"},
		{"@conversation/naboo_privateer_trainer_1:s_7736f08b", "mission4_failed_retry3"},
	}
}
dinge_convo_template:addScreen(mission4_failed);

mission4_failed_retry1 = ConvoScreen:new {
	id = "mission4_failed_retry1",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_983440a3",
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
dinge_convo_template:addScreen(mission4_failed_retry1);

mission4_failed_retry2 = ConvoScreen:new {
	id = "mission4_failed_retry2",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_80744015",
	stopConversation = "true",
	animation = "laugh_cackle",
	options = {}
}
dinge_convo_template:addScreen(mission4_failed_retry2);

mission4_failed_retry3 = ConvoScreen:new {
	id = "mission4_failed_retry3",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_73f727e7",
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
dinge_convo_template:addScreen(mission4_failed_retry3);

mission4_reward = ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_6ea4aa1e",
	stopConversation = "true",
	animation = "applause_excited",
	options = {}
}
dinge_convo_template:addScreen(mission4_reward);

-- Training
first_training = ConvoScreen:new {
	id = "first_training",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_5e36283d",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_139", "first_training_lesson"},
	}
}
dinge_convo_template:addScreen(first_training);

first_training_lesson = ConvoScreen:new {
	id = "first_training_lesson",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_140",
	stopConversation = "false",
	options = {}
}
dinge_convo_template:addScreen(first_training_lesson);

more_training = ConvoScreen:new {
	id = "more_training",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_122b0165",
	stopConversation = "false",
	animation = "explain",
	options = {}
}
dinge_convo_template:addScreen(more_training);

train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_144",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_148", "trained_starships"},
	}
}
dinge_convo_template:addScreen(train_starships);

train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_145",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_151", "trained_weapons"},
	}
}
dinge_convo_template:addScreen(train_weapons);

train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_146",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_155", "trained_procedures"},
	}
}
dinge_convo_template:addScreen(train_procedures);

train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_147",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_159", "trained_droid"},
	}
}
dinge_convo_template:addScreen(train_droid);

trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_149",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(trained_starships);

trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_153",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(trained_weapons);

trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_157",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(trained_procedures);

trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_161",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(trained_droid);



duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_63336624",
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_6106187c", "what_is_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_e814cf37", "duty_options"},
		{"@conversation/naboo_privateer_trainer_1:s_db74ddc6", "duty_no_training"},
		{"@conversation/naboo_privateer_trainer_1:s_2883b989", "duty_not_now"},
	}
}
dinge_convo_template:addScreen(duty_missions);

what_is_duty = ConvoScreen:new {
	id = "what_is_duty",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_a8cdf3dc",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_6106187c", "what_is_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_e814cf37", "duty_options"},
		{"@conversation/naboo_privateer_trainer_1:s_db74ddc6", "duty_no_training"},
		{"@conversation/naboo_privateer_trainer_1:s_2883b989", "duty_not_now"},
	}
}
dinge_convo_template:addScreen(what_is_duty);

duty_no_training = ConvoScreen:new {
	id = "duty_no_training",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_f4245779",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_6106187c", "what_is_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_e814cf37", "duty_options"},
		{"@conversation/naboo_privateer_trainer_1:s_db74ddc6", "duty_no_training"},
		{"@conversation/naboo_privateer_trainer_1:s_2883b989", "duty_not_now"},
	}
}
dinge_convo_template:addScreen(duty_no_training);

duty_not_now = ConvoScreen:new {
	id = "duty_not_now",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_138",
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(duty_not_now);

duty_options = ConvoScreen:new {
	id = "duty_options",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_e38f886b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_1:s_40759c25", "destroy_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_629c7d23", "escort_duty"},
		{"@conversation/naboo_privateer_trainer_1:s_3d36a0e4", "not_ready"},
	}
}
dinge_convo_template:addScreen(duty_options);

destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_6575e5d0", -- Get up there and put those Black Sun in their place.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(destroy_duty);

escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_90b16aa7", -- We'll pay for every transport that makes it through.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(escort_duty);

not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_privateer_trainer_1:s_792ad840", -- OK, OK. Come back when you're ready.
	stopConversation = "true",
	options = {}
}
dinge_convo_template:addScreen(not_ready);

addConversationTemplate("dinge_convo_template", dinge_convo_template);
