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

-- Rebel pilot (naboo_privateer_trainer_2.java:3887-3892)
rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_7ac0f961",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(rebel_pilot);

-- Imperial pilot (naboo_privateer_trainer_2.java:3893-3898)
imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_6c6f3940",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(imperial_pilot);

-- Pilot but not RSF; the option is re-pointed at non_rsf_duty_options by the handler when the pilot can fly a duty (naboo_privateer_trainer_2.java:3899-3927)
pilot_not_rsf = ConvoScreen:new {
	id = "pilot_not_rsf",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_c89c3456",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_c1ff5062", "non_rsf_missions"}, -- I'm looking for a mission. Do you have any?
	}
}
kaydine_convo_template:addScreen(pilot_not_rsf);

-- Off-track duty offer (naboo_privateer_trainer_2.java:282-334, branch 55 at 2160)
non_rsf_duty_options = ConvoScreen:new {
	id = "non_rsf_duty_options",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8a84109d",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_9b73da8", "accept_duty_escort"},
		{"@conversation/naboo_privateer_trainer_2:s_30297e22", "accept_duty_recovery"},
		{"@conversation/naboo_privateer_trainer_2:s_c892e540", "accept_duty_destroy"},
	}
}
kaydine_convo_template:addScreen(non_rsf_duty_options);

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
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_394f0902",
	stopConversation = "false",
	animation = "bow",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_b0704da1", "not_ready_tier2_end"},
	}
}
kaydine_convo_template:addScreen(not_ready_tier2);

not_ready_tier2_end = ConvoScreen:new {
	id = "not_ready_tier2_end",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_eac39719", -- Sorry, kiddo. You're still in need of training! Come back when you've learned to handle yourself better.
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(not_ready_tier2_end);

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
	animation = "rub_chin_thoughtful",
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

-- Training (naboo_privateer_trainer_2.java:2200-3700); the handler offers one reply per missing skill on ready_train_pilot (pre-NGE free choice)
ready_train_pilot = ConvoScreen:new {
	id = "ready_train_pilot",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_76e6f264",
	stopConversation = "false",
	animation = "salute1",
	options = {}
}
kaydine_convo_template:addScreen(ready_train_pilot);

trained_starships_mission1 = ConvoScreen:new {
	id = "trained_starships_mission1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_bb45477c", -- Excellent choice! What starfighter do you have your eye on? Are you interested in the Kimogila? Or are you obsessed with that hideous Kihraxz Light Fighter like all the other kids?
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_34ac61a2", "mission1_intro_a1"}, -- The 'Kimogila'
		{"@conversation/naboo_privateer_trainer_2:s_92dbc95c", "mission1_intro_b1"}, -- Kihraxz Light Fighter
	}
}
kaydine_convo_template:addScreen(trained_starships_mission1);

trained_starships_mission2 = ConvoScreen:new {
	id = "trained_starships_mission2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2dee44ae", -- You bet! A new starship would probably do a lot better against some Ay'Nat Ghost Fighters!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_86358e09", "mission2_brief"}, -- Ghost Fighters?
	}
}
kaydine_convo_template:addScreen(trained_starships_mission2);

trained_starships_mission3 = ConvoScreen:new {
	id = "trained_starships_mission3",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4aa3066e", -- Ah yes! Good choice! Learning to fly many different types of ships makes an effective pilot!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_5e2a2bb1", "mission3_intro"}, -- Sounds good.
	}
}
kaydine_convo_template:addScreen(trained_starships_mission3);

trained_starships_mission4 = ConvoScreen:new {
	id = "trained_starships_mission4",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4495137d", -- Sorry, I'm a bit distracted... did you hear how the RSF Guard foiled an attempt by Ay'Nat Legion pirates to detonate proton packs in the Palace reactor?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission4_brief"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(trained_starships_mission4);

trained_weapons_mission1 = ConvoScreen:new {
	id = "trained_weapons_mission1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_24b7f2f", -- Excellent choice. This will especially come in handy since the Ay'Nat pirate legion is mounting an aggressive campaign for control here in Naboo. They're building fast... so we need to strike at their leadership, and send them scrambling.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_2d67b7a8", "mission1_brief"}, -- Where do I come in?
	}
}
kaydine_convo_template:addScreen(trained_weapons_mission1);

trained_weapons_mission2 = ConvoScreen:new {
	id = "trained_weapons_mission2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_8ad6a62e", -- You bet! New components should make your ship more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_86358e09", "mission2_brief"}, -- Ghost Fighters?
	}
}
kaydine_convo_template:addScreen(trained_weapons_mission2);

trained_weapons_mission3 = ConvoScreen:new {
	id = "trained_weapons_mission3",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2017d4b5", -- Ah yes! Good choice. Now there's no time to lose. We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission3_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(trained_weapons_mission3);

trained_weapons_mission4 = ConvoScreen:new {
	id = "trained_weapons_mission4",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4495137d", -- Sorry, I'm a bit distracted... did you hear how the RSF Guard foiled an attempt by Ay'Nat Legion pirates to detonate proton packs in the Palace reactor?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission4_brief"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(trained_weapons_mission4);

trained_procedures_mission1 = ConvoScreen:new {
	id = "trained_procedures_mission1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_24b7f2f", -- Excellent choice. This will especially come in handy since the Ay'Nat pirate legion is mounting an aggressive campaign for control here in Naboo. They're building fast... so we need to strike at their leadership, and send them scrambling.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_2d67b7a8", "mission1_brief"}, -- Where do I come in?
	}
}
kaydine_convo_template:addScreen(trained_procedures_mission1);

trained_procedures_mission2 = ConvoScreen:new {
	id = "trained_procedures_mission2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_f32117e", -- You bet! New defense procedures should make you more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_86358e09", "mission2_brief"}, -- Ghost Fighters?
	}
}
kaydine_convo_template:addScreen(trained_procedures_mission2);

trained_procedures_mission3 = ConvoScreen:new {
	id = "trained_procedures_mission3",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2017d4b5", -- Ah yes! Good choice. Now there's no time to lose. We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission3_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(trained_procedures_mission3);

trained_procedures_mission4 = ConvoScreen:new {
	id = "trained_procedures_mission4",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4495137d", -- Sorry, I'm a bit distracted... did you hear how the RSF Guard foiled an attempt by Ay'Nat Legion pirates to detonate proton packs in the Palace reactor?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission4_brief"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(trained_procedures_mission4);

trained_droid_mission1 = ConvoScreen:new {
	id = "trained_droid_mission1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_24b7f2f", -- Excellent choice. This will especially come in handy since the Ay'Nat pirate legion is mounting an aggressive campaign for control here in Naboo. They're building fast... so we need to strike at their leadership, and send them scrambling.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_2d67b7a8", "mission1_brief"}, -- Where do I come in?
	}
}
kaydine_convo_template:addScreen(trained_droid_mission1);

trained_droid_mission2 = ConvoScreen:new {
	id = "trained_droid_mission2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_fd75abb", -- You bet! New droid algorithms in there should make you more than a match against a dozen Ay'Nat Ghost Fighters!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_86358e09", "mission2_brief"}, -- Ghost Fighters?
	}
}
kaydine_convo_template:addScreen(trained_droid_mission2);

trained_droid_mission3 = ConvoScreen:new {
	id = "trained_droid_mission3",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2017d4b5", -- Ah yes! Good choice. Now there's no time to lose. We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission3_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(trained_droid_mission3);

trained_droid_mission4 = ConvoScreen:new {
	id = "trained_droid_mission4",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_4495137d", -- Sorry, I'm a bit distracted... did you hear how the RSF Guard foiled an attempt by Ay'Nat Legion pirates to detonate proton packs in the Palace reactor?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission4_brief"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(trained_droid_mission4);

mission1_intro_a1 = ConvoScreen:new {
	id = "mission1_intro_a1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9ce4dd83", -- Ah, yes! You'll certainly need the strength of the M12-L if you're going up against the Ay'Nat Legion's elite starfighter assassins. Definitely!
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_e9c57758", "mission1_intro_a2"}, -- Elite starfighter assassins?
	}
}
kaydine_convo_template:addScreen(mission1_intro_a1);

mission1_intro_a2 = ConvoScreen:new {
	id = "mission1_intro_a2",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_86a73ee1", -- Sorry... I forgot to mention... We have a mission. Or rather, I have a mission and you've got to do it.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission1_offer"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(mission1_intro_a2);

mission1_intro_b1 = ConvoScreen:new {
	id = "mission1_intro_b1",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2fd7906f", -- Why do all you kids want to fly around looking like pirates? Ugh! But... I'll admit... you will need the handling capabilities of the Kihraxz Light Fighter if you're going to survive a pre-emptive strike against the Ay'Nat Legion's elite starfighter assassins! That's for sure.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_e9c57758", "mission1_intro_a2"}, -- Elite starfighter assassins?
	}
}
kaydine_convo_template:addScreen(mission1_intro_b1);

mission3_intro = ConvoScreen:new {
	id = "mission3_intro",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_1c7ee38e", -- You'll find it handy in your next mission! We'll need you to catch up to the Ay'Nat Captain's personal starship... a rather fast vessel! Disable him, and protect an RSF Boarding Team while they arrest him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission3_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(mission3_intro);

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
		{"@conversation/naboo_privateer_trainer_2:s_2d67b7a8", "mission1_brief"}, -- Where do I come in?
	}
}
kaydine_convo_template:addScreen(mission1_offer);

mission1_brief = ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_c4ef0e93", -- We need you to slip in to Ay'Nat-controlled space, and hunt down a trio of Ace outlaws.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_e42b260e", "mission1_accept"}, -- I'm on my way.
	}
}
kaydine_convo_template:addScreen(mission1_brief);

mission1_accept_male = ConvoScreen:new {
	id = "mission1_accept_male",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_225b33f", -- Good luck, son!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission1_accept_male);

mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_ff45f1fd", -- Good luck to you, Captain %TU!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission1_accept);

mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9af8d581",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_86358e09", "mission2_brief"}, -- Ghost Fighters?
	}
}
kaydine_convo_template:addScreen(mission2_offer);

mission2_brief = ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_168f5655", -- I guess I forgot to mention this earlier... but yes, we have a mission to destroy a squadron of Ay'Nat Ghost Fighters that have been sighted outside of RSF controlled space.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_a6c7fa2b", "mission2_details"}, -- What are the details?
	}
}
kaydine_convo_template:addScreen(mission2_brief);

mission2_details = ConvoScreen:new {
	id = "mission2_details",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_3cef63a0", -- Fly out to your choice of strike points... look for Ay'Nat Legion fighters. Likely, if these are hired for support - they will come out if you start tearing up the rank-and-file.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission2_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(mission2_details);

mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_a80d9308", -- Good luck!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission2_accept);

mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_130b925b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_dc649bb3", "mission3_accept"}, -- I'm on my way!
	}
}
kaydine_convo_template:addScreen(mission3_offer);

mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_a80d9308", -- Good luck!
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(mission3_accept);

mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_387397fb",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_58362a8d", "mission4_brief"}, -- Tell me about it.
	}
}
kaydine_convo_template:addScreen(mission4_offer);

mission4_brief = ConvoScreen:new {
	id = "mission4_brief",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_ec671b3f", -- Well, the Empire has demanded that the prisoners be turned over for questioning. I'm not sure how I feel about that. Regardless... are you up to escorting the prisoner transport?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_36a4e374", "mission4_accept"}, -- Yes, I am.
	}
}
kaydine_convo_template:addScreen(mission4_brief);

mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2e7b17f3", -- It's very likely you'll fall under attack from Ay'Nat Legion pirates. Be careful...
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
		{"@conversation/naboo_privateer_trainer_2:s_c8f39347", "mission1_failed_end"}, -- I am.
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
		{"@conversation/naboo_privateer_trainer_2:s_c8f39347", "mission2_failed_end"}, -- I am.
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
		{"@conversation/naboo_privateer_trainer_2:s_370822d1", "mission3_reward"}, -- Yes
	}
}
kaydine_convo_template:addScreen(mission3_complete);

mission3_reward = ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_d2ffe31e",
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_5e2a2bb1", "mission3_reward_end"}, -- Sounds good.
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
		{"@conversation/naboo_privateer_trainer_2:s_725573da", "completed_kaydine_end"}, -- What now?
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

-- First-meeting sign-up (naboo_privateer_trainer_2.java:401-744, 3965-4000); fallthrough is s_837686a5 (java:4408)
signup = ConvoScreen:new {
	id = "signup",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_464cfc61",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_9560d48e", "signup_palace"},
	}
}
kaydine_convo_template:addScreen(signup);

signup_palace = ConvoScreen:new {
	id = "signup_palace",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_9ea46a82",
	stopConversation = "false",
	animation = "point_left",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_36a4e374", "signup_welcome"},
		{"@conversation/naboo_privateer_trainer_2:s_f93088f1", "signup_security"},
	}
}
kaydine_convo_template:addScreen(signup_palace);

signup_welcome = ConvoScreen:new {
	id = "signup_welcome",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_d8472b3c",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_f6ae3b07", "signup_job"},
	}
}
kaydine_convo_template:addScreen(signup_welcome);

signup_job = ConvoScreen:new {
	id = "signup_job",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_2847218",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_8f2e1055", "signup_duty"},
	}
}
kaydine_convo_template:addScreen(signup_job);

signup_duty = ConvoScreen:new {
	id = "signup_duty",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_6cd96c01",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_7614c65", "signup_accept"},
	}
}
kaydine_convo_template:addScreen(signup_duty);

signup_accept = ConvoScreen:new {
	id = "signup_accept",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_24d86e89",
	stopConversation = "true",
	animation = "manipulate_high",
	options = {}
}
kaydine_convo_template:addScreen(signup_accept);

signup_security = ConvoScreen:new {
	id = "signup_security",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_35fb22d6",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_d70dba34", "signup_security_welcome"},
	}
}
kaydine_convo_template:addScreen(signup_security);

signup_security_welcome = ConvoScreen:new {
	id = "signup_security_welcome",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_7cc7c206",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_trainer_2:s_f6ae3b07", "signup_job"},
	}
}
kaydine_convo_template:addScreen(signup_security_welcome);

fallthrough = ConvoScreen:new {
	id = "fallthrough",
	leftDialog = "@conversation/naboo_privateer_trainer_2:s_837686a5",
	stopConversation = "true",
	options = {}
}
kaydine_convo_template:addScreen(fallthrough);

addConversationTemplate("kaydine_convo_template", kaydine_convo_template)
