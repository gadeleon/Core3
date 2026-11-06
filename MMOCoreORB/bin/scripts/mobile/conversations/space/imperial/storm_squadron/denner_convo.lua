-- Captain Denner (Storm Squadron tier 3) conversation; ported from SWG-Source tatooine_imperial_tier3.java (J3) with the pre-NGE client lines (feature storm-tier3-denner). Handler: dennerConvoHandler.
denner_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "dennerConvoHandler",
	screens = {}
}

denner_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_43b48713", -- I am not sure who you are or why you are here, but I assure you I do not have time to help you regardless.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_not_pilot)

denner_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_e6e2ab99", -- You are not here on Imperial business. Leave now.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_b40f340", "wrong_faction_74df4"}, -- Not a chance.
		{"@conversation/tatooine_imperial_tier3:s_86137261", "wrong_faction_540bd108"}, -- No sir.
	}
}
denner_convo_template:addScreen(denner_convo_wrong_faction)

denner_convo_wrong_faction_74df4 = ConvoScreen:new {
	id = "wrong_faction_74df4",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_74df4", -- Then I suggest you leave, before my men take you into custody.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_wrong_faction_74df4)

denner_convo_wrong_faction_540bd108 = ConvoScreen:new {
	id = "wrong_faction_540bd108",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_540bd108", -- Then move on.
	stopConversation = "true",
	animation = "point_away",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_wrong_faction_540bd108)

denner_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_846bd129", -- I am afraid that you are not ready for the rigors I would be forced to put you through. I suggest you go work on your skills and perhaps we will meet again.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_not_ready)

denner_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_f06f4a8", -- You are not assigned to this Squadron, pilot. Perhaps you have gotten lost? I suggest you un-lose yourself quickly.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_off_track)

denner_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_6f21dd8e", -- You are under investigation for crimes against the Empire, %TU.  What is going on?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_5814e23b", "wanted_78b0ecc0"}, -- I don't know what you're talking about
	}
}
denner_convo_template:addScreen(denner_convo_wanted)

denner_convo_wanted_78b0ecc0 = ConvoScreen:new {
	id = "wanted_78b0ecc0",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_78b0ecc0", -- That is very unfortunate.  I need for you to get this situation resolved.  I cannot trust you with any more assignments so long as you are suspected of treason.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_6efcdb6b", "wanted_2ec9494f"}, -- Treason?!
	}
}
denner_convo_template:addScreen(denner_convo_wanted_78b0ecc0)

denner_convo_wanted_2ec9494f = ConvoScreen:new {
	id = "wanted_2ec9494f",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_2ec9494f", -- I'm certain it is a mistake of some sort.  Nevertheless, my hands are tied.  You must improve your standing with the Empire - prove that you are devoted to crushing the Rebellion - and do it quickly!
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40dea799", "wanted_cd3a54f7"}, -- Why quickly?
	}
}
denner_convo_template:addScreen(denner_convo_wanted_2ec9494f)

denner_convo_wanted_cd3a54f7 = ConvoScreen:new {
	id = "wanted_cd3a54f7",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_cd3a54f7", -- Because we need you, %TU.  And others like you.  But only so long as we can trust you.  So go handle this situation.  Pilots of your skill are not exactly common, you know.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_wanted_cd3a54f7)

denner_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_89af090b", -- You are on assignment, soldier. Get back to work.
	stopConversation = "true",
	animation = "shakefist",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_on_mission)

denner_convo_tour_complete = ConvoScreen:new {
	id = "tour_complete",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_704da203", -- Your time with me is over. I figured one of my superiors would have you transferred under his command.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_2dc37e6c", "tour_a5f19408"}, -- It has been a pleasure, sir.
		{"@conversation/tatooine_imperial_tier3:s_4ec1bd6b", "tour_7ea66fab"}, -- It's about time I was noticed.
		{"@conversation/tatooine_imperial_tier3:s_69f62a43", "tour_a0aa65a4"}, -- As was foretold.
	}
}
denner_convo_template:addScreen(denner_convo_tour_complete)

denner_convo_tour_a5f19408 = ConvoScreen:new {
	id = "tour_a5f19408",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a5f19408", -- The pleasure has been all mine. You are being transferred to Admiral Kilnstrider, head of Storm Squadron. He is personally taking over security of the Endor system. A base of operations has been set up on the research center on the moon of Endor.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_936b8cfc", "tour_a099839c"}, -- You have been removed as head of Endor security?
	}
}
denner_convo_template:addScreen(denner_convo_tour_a5f19408)

denner_convo_tour_7ea66fab = ConvoScreen:new {
	id = "tour_7ea66fab",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_7ea66fab", -- Well you have been noticed by Admiral Kilnstrider, head of Storm Squadron. He is taking over security for the Endor system and has set up operations on the moon of Endor at the research center. Again, I highly advise that you do not be yourself with Admiral Kilnstrider. He has very little use for braggarts. Good luck, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_tour_7ea66fab)

denner_convo_tour_a0aa65a4 = ConvoScreen:new {
	id = "tour_a0aa65a4",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a0aa65a4", -- Yes, I know. I was the one who foretold that you would be transferred. I cannot say that I am not happy to see you leave. Frankly, you worry me a little bit.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_25c39c01", "tour_66506cea"}, -- You cannot understand, so you fear.
	}
}
denner_convo_template:addScreen(denner_convo_tour_a0aa65a4)

denner_convo_tour_a099839c = ConvoScreen:new {
	id = "tour_a099839c",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a099839c", -- I am afraid so. I am to remain here and finish the preparations for the rest of Storm Squadron to be moved out of this system. Good luck to you, %NU. If you serve the Admiral as well as you served me all will be well.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_tour_a099839c)

denner_convo_tour_66506cea = ConvoScreen:new {
	id = "tour_66506cea",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_66506cea", -- I doubt that is it. But, you are no longer my problem. You have been transferred to Admiral Kilnstrider, head of Storm Squadron. Report to him at his command post at the research center on the moon of Endor. He will be granting you missions from the Emperor from now on. Dismissed.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_tour_66506cea)

denner_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_430701b", -- Your job's not done yet. I need you to see this through.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m4_failed)

denner_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d1fb3414", -- Maybe YOU'RE the traitor.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a22823c2", "m2_retry_prove"}, -- You're wrong!
		{"@conversation/tatooine_imperial_tier3:s_51a40299", "m2_retry_shut"}, -- [deny it]
	}
}
denner_convo_template:addScreen(denner_convo_m2_failed)

denner_convo_m2_retry_prove = ConvoScreen:new {
	id = "m2_retry_prove",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_fae9ce56", -- Prove it. Get back out there and do your job.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m2_retry_prove)

denner_convo_m2_retry_shut = ConvoScreen:new {
	id = "m2_retry_shut",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_f2bc2a81", -- Get back out there. Shut this situation down.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m2_retry_shut)

denner_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c70eec74", -- I should never have accepted you into this unit.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_1ebe3b4f", "m3_retry_again"}, -- I'll go again - if it's not too late.
		{"@conversation/tatooine_imperial_tier3:s_dab3c286", "m3_retry_prove"}, -- I know what I'm doing.
	}
}
denner_convo_template:addScreen(denner_convo_m3_failed)

denner_convo_m3_retry_again = ConvoScreen:new {
	id = "m3_retry_again",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_24315068", -- It's not. Get back out there.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m3_retry_again)

denner_convo_m3_retry_prove = ConvoScreen:new {
	id = "m3_retry_prove",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c0cba601", -- Prove it to me. Get back out there.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m3_retry_prove)

denner_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_599cef6e", -- So.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_78cd7b47", "m1_failed_187c0a86"}, -- I failed. It won't happen again.
		{"@conversation/tatooine_imperial_tier3:s_e094e94b", "m1_retry_fail"}, -- Send me back out there.
	}
}
denner_convo_template:addScreen(denner_convo_m1_failed)

denner_convo_m1_failed_187c0a86 = ConvoScreen:new {
	id = "m1_failed_187c0a86",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_187c0a86", -- Oh it won't. I see. Well I admire your confidence, but what is it based on?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_47021aad", "m1_failed_7c0ad410"}, -- Experience. I'm a great pilot.
		{"@conversation/tatooine_imperial_tier3:s_46977c75", "m1_retry_sooner"}, -- I'll crush the Rebellion; whatever it takes.
	}
}
denner_convo_template:addScreen(denner_convo_m1_failed_187c0a86)

denner_convo_m1_retry_fail = ConvoScreen:new {
	id = "m1_retry_fail",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_78d45540", -- Don't fail this time.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_retry_fail)

denner_convo_m1_failed_7c0ad410 = ConvoScreen:new {
	id = "m1_failed_7c0ad410",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_7c0ad410", -- Strong words from a pilot who's done nothing but fail since he got here!
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_3b0a14d7", "m1_retry_luck"}, -- I'll get them this time. I promise.
		{"@conversation/tatooine_imperial_tier3:s_c4088008", "m1_retry_replaceable"}, -- Get off my case.
	}
}
denner_convo_template:addScreen(denner_convo_m1_failed_7c0ad410)

denner_convo_m1_retry_sooner = ConvoScreen:new {
	id = "m1_retry_sooner",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_457d29c5", -- The sooner this war is over, the sooner we can all go home. Get back out there.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_retry_sooner)

denner_convo_m1_retry_luck = ConvoScreen:new {
	id = "m1_retry_luck",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_6b9765c5", -- Good luck, soldier. I think you will need it.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_retry_luck)

denner_convo_m1_retry_replaceable = ConvoScreen:new {
	id = "m1_retry_replaceable",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_8323fc9a", -- I'll explain this very simply. You are replaceable. The engineers are not. Get them, and bring them back - NOW.
	stopConversation = "true",
	animation = "slit_throat",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_retry_replaceable)

denner_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_9cfbfe87", -- Good to see that you are back. We have a mess on our hands right now. Reports are coming in from all over the Endor system that Rebels have been spotted in almost every quadrant.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_39a5745d", "m1_reward_5669d57a"}, -- Let me at them! I will drive them off.
		{"@conversation/tatooine_imperial_tier3:s_9dbb5a9a", "m1_training_813c7eed"}, -- What is the plan?
	}
}
denner_convo_template:addScreen(denner_convo_m1_reward)

denner_convo_m1_reward_5669d57a = ConvoScreen:new {
	id = "m1_reward_5669d57a",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_5669d57a", -- In good time. Right now we have to make sure that we get a good grasp on the situation. If we send pilots out without figuring out what the Rebels are up to we could be in serious trouble.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_bb9e4a63", "m1_training_cb3f07d5"}, -- Understood, sir.
		{"@conversation/tatooine_imperial_tier3:s_32778372", "m1_training_c198d74c"}, -- So we are not in trouble right now?
	}
}
denner_convo_template:addScreen(denner_convo_m1_reward_5669d57a)

denner_convo_m1_training_813c7eed = ConvoScreen:new {
	id = "m1_training_813c7eed",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_813c7eed", -- We are working on that. Right now what we have Intelligence focused on deciphering that data you recovered from the Rebel scout. Once we have that information we should have a better idea of how to proceed. While we are waiting for that we need you to get your skills up to speed. What are you interested in learning?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m1_training_813c7eed)

denner_convo_m1_training_cb3f07d5 = ConvoScreen:new {
	id = "m1_training_cb3f07d5",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_cb3f07d5", -- We have Intelligence working on deciphering the data that you recovered from the scout as we speak. Once we have that information we should have a better grasp on the situation and be able to figure out how best to proceed. Until then we need you to get up to speed with your skills. I think you will be instrumental in the upcoming days. What are you interested in learning?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m1_training_cb3f07d5)

denner_convo_m1_training_c198d74c = ConvoScreen:new {
	id = "m1_training_c198d74c",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c198d74c", -- I don't need any of your lip right now. We will have this situation under control shortly, you can count on that. Right now we have Intelligence deciphering that data you recovered from the Rebel scout and once we have that we will have a better understanding of how best to proceed. While we are waiting for that we need you to get your skills up to speed. What are you interested in learning?
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m1_training_c198d74c)

denner_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_cc9d8558", -- Welcome back. You have successfully managed to retrieve the information from the Rebel command vessel, as well as, save the 3rd TIE Wing from destruction. A very nice days work if I say so myself.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_2bdc8841", "m2_reward_162e1268"}, -- It was nothing. Just doing my job, sir.
		{"@conversation/tatooine_imperial_tier3:s_dcbac482", "m2_training_64617aad"}, -- Of course, I told you I was good.
		{"@conversation/tatooine_imperial_tier3:s_a3d2c25b", "m2_reward_e99b920a"}, -- Those weak minded fools were hardly a challenge.
	}
}
denner_convo_template:addScreen(denner_convo_m2_reward)

denner_convo_m2_reward_162e1268 = ConvoScreen:new {
	id = "m2_reward_162e1268",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_162e1268", -- Regardless, you have made Storm Squadron look very good to our superiors.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_f733628f", "m2_training_dc98dda7"}, -- What did we find out from the Rebel information?
	}
}
denner_convo_template:addScreen(denner_convo_m2_reward_162e1268)

denner_convo_m2_training_64617aad = ConvoScreen:new {
	id = "m2_training_64617aad",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_64617aad", -- And you are proving yourself over and over again. The information you recovered from the Rebels is still being examined by Intelligence. We should have more answers soon. Once we have all of it compiled, we will be sending you out again. Hopefully with more direction this time around. Until then let us see what we can do to increase your already very accomplished talents. What skill would you like training in?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m2_training_64617aad)

denner_convo_m2_reward_e99b920a = ConvoScreen:new {
	id = "m2_reward_e99b920a",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_e99b920a", -- The Rebellion might be foolish but they are hardly weak minded. The Empire has underestimated their abilities too often and has paid dearly for those mistakes. Storm Squadron will not make that same mistake. We will learn everything we can about our enemy and then defeat them using what we have learned.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_6612078b", "m2_training_a3f5c141"}, -- I do not fear the Rebellion.
	}
}
denner_convo_template:addScreen(denner_convo_m2_reward_e99b920a)

denner_convo_m2_training_dc98dda7 = ConvoScreen:new {
	id = "m2_training_dc98dda7",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_dc98dda7", -- That is still being examined by Intelligence. We should have more answers soon. Once we have all of it compiled we will be sending you out again. Hopefully with more direction this time around. Until then let us see what we can do to get you better prepared for your next assignment. What skill would you like training in?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m2_training_dc98dda7)

denner_convo_m2_training_a3f5c141 = ConvoScreen:new {
	id = "m2_training_a3f5c141",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a3f5c141", -- Neither do I. But I have respect for their abilities. The information you recovered from the Rebels is still being examined by Intelligence. We should have more answers soon. Once we have all of it compiled we will be sending you out again. Hopefully with more direction this time around. Until then let us see what we can do to increase your lethal talents. What skill would you like training in?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m2_training_a3f5c141)

denner_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_463a0835", -- Perfect! The Rebels fell right into our trap. We are monitoring the movements of the Rebel command vessel. I am fairly certain that they know we set a trap for them, but I do not think they understand to what purpose.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_7eeba249", "m3_training_1d7c7ed2"}, -- Excellent plan, sir. It went off without any trouble.
		{"@conversation/tatooine_imperial_tier3:s_b3f090c6", "m3_reward_fb75707f"}, -- I wouldn't say perfect. But fortunately I was able to compensate.
		{"@conversation/tatooine_imperial_tier3:s_609b8560", "m3_reward_9104408b"}, -- I was guided to victory by a greater power.
	}
}
denner_convo_template:addScreen(denner_convo_m3_reward)

denner_convo_m3_training_1d7c7ed2 = ConvoScreen:new {
	id = "m3_training_1d7c7ed2",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1d7c7ed2", -- Good. We are beginning our planning for what to do next. Once we are ready then you will be called on again. But before that you need to work on some of your techniques. What skill would you like to learn?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m3_training_1d7c7ed2)

denner_convo_m3_reward_fb75707f = ConvoScreen:new {
	id = "m3_reward_fb75707f",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_fb75707f", -- Then it is fortunate we have such a 'talented' pilot in Storm Squadron. Perhaps you would care to plan the next mission?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c33ed1f7", "m3_training_612db735"}, -- No, I think you are doing fine.
	}
}
denner_convo_template:addScreen(denner_convo_m3_reward_fb75707f)

denner_convo_m3_reward_9104408b = ConvoScreen:new {
	id = "m3_reward_9104408b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_9104408b", -- Please do not tell me that you are hearing voices. I cannot afford to take you off of active duty right now.We are in the process of planning our next step and you will be vital to the success of our plans.
	stopConversation = "false",
	animation = "cuckoo",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_dfb20007", "m3_training_41ecd1f"}, -- I can hear him talking to...
	}
}
denner_convo_template:addScreen(denner_convo_m3_reward_9104408b)

denner_convo_m3_training_612db735 = ConvoScreen:new {
	id = "m3_training_612db735",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_612db735", -- Well, we are in the process of planning our next step now. Once we have it worked out you will be called on again to perform the next mission. Even a 'great' pilot, such as yourself, has a thing or two to learn. What skill would you like training in?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m3_training_612db735)

denner_convo_m3_training_41ecd1f = ConvoScreen:new {
	id = "m3_training_41ecd1f",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_41ecd1f", -- I told you that I don't want you to tell me! Once we have worked out the details we will contact you again to fly our next mission. Until then let us see if you cannot wrap your mind around some training. Hopefully that will help cool your zeal. What skill would you like to learn?
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m3_training_41ecd1f)

denner_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c3a1b3b3", -- Well done, %NU. Not only did you manage to drive the Rebel force back into hiding from the Endor system, you also managed to uncover all the information that was leaked to them by the traitor. We will be able to quickly change our plans for the system based off of that information and neutralize any advantage the Rebels might have had.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_51f13870", "m4_reward_a7d9a14d"}, -- I am proud to have been of assistance, sir.
		{"@conversation/tatooine_imperial_tier3:s_44bf27d7", "m4_reward_aa3bdfaa"}, -- That was nothing. You should have seen me in the battle of...
		{"@conversation/tatooine_imperial_tier3:s_6196f26f", "m4_reward_299e29d5"}, -- What I did, I did for the glory of the Empire.
	}
}
denner_convo_template:addScreen(denner_convo_m4_reward)

denner_convo_m4_reward_a7d9a14d = ConvoScreen:new {
	id = "m4_reward_a7d9a14d",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a7d9a14d", -- You have been far more than an assistance, you have been instrumental. I have made sure to note your contributions in my reports and you have garnished more than a fair share of attention. I fear that you will not be under my command for very much longer.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_5de22b37", "m4_training_df0f8037"}, -- I do not fight for glory, sir.
	}
}
denner_convo_template:addScreen(denner_convo_m4_reward_a7d9a14d)

denner_convo_m4_reward_aa3bdfaa = ConvoScreen:new {
	id = "m4_reward_aa3bdfaa",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_aa3bdfaa", -- I am sure you were simply amazing in that battle. Of course, you will be happy to know that I listed your accomplishments in my reports to my superiors. They were rather impressed by your prowess. I wouldn't be surprised if you were promoted over this.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_1d6ab832", "m4_training_d837376f"}, -- If anyone deserves it...I do!
	}
}
denner_convo_template:addScreen(denner_convo_m4_reward_aa3bdfaa)

denner_convo_m4_reward_299e29d5 = ConvoScreen:new {
	id = "m4_reward_299e29d5",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_299e29d5", -- Regardless of why you did it, you have gained some measure of fame over your actions against the Rebellion. My superiors were quite impressed when I explained your value to the operation. I wouldn't be surprised if one of them took over your command.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_6da8109", "m4_training_30651d99"}, -- If that is in my fate.
	}
}
denner_convo_template:addScreen(denner_convo_m4_reward_299e29d5)

denner_convo_m4_training_df0f8037 = ConvoScreen:new {
	id = "m4_training_df0f8037",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_df0f8037", -- I know that. But you have gained some measure of fame regardless. It has not been made official but I believe you will be transferred soon. If that is the case we must be sure that you are up to snuff. What skill would you like training in?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m4_training_df0f8037)

denner_convo_m4_training_d837376f = ConvoScreen:new {
	id = "m4_training_d837376f",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d837376f", -- If the time comes and you are promoted, I would highly suggest curbing your ego a bit. Most officers above me are not as tolerant as I am. But if you are promoted we cannot have any of them being unimpressed by your skill. What skill would you like training in?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m4_training_d837376f)

denner_convo_m4_training_30651d99 = ConvoScreen:new {
	id = "m4_training_30651d99",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_30651d99", -- I wouldn't be surprised if it is. But in order to better serve the Empire you must have training. What skill would you like to be trained in?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_40cda759", "trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/tatooine_imperial_tier3:s_a9aeb386", "trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/tatooine_imperial_tier3:s_ef7a2df5", "trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/tatooine_imperial_tier3:s_473d09d8", "trained_droid"}, -- Teach me about system balance programming.
	}
}
denner_convo_template:addScreen(denner_convo_m4_training_30651d99)

denner_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_e5e51881", -- Field Commander Alozen tells me that you're ready to serve under my command. We will see, won't we?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_6e86b00", "m1_offer_ac951104"}, -- I'm ready to blast holes in as many Rebel ships as I can.
		{"@conversation/tatooine_imperial_tier3:s_9ae62db", "m1_offer_ego"}, -- You have yourself the best pilot in the fleet.
		{"@conversation/tatooine_imperial_tier3:s_47edbf24", "m1_offer_4ca34e11"}, -- Yes, SIR!
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer)

denner_convo_m1_offer_ac951104 = ConvoScreen:new {
	id = "m1_offer_ac951104",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ac951104", -- You'll get your chance. The Rebel faction remains active across a number of systems. Of course, we will only be dealing with security in one system.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_d3fb9e20", "m1_offer_e83e03f6"}, -- They're idiots.
		{"@conversation/tatooine_imperial_tier3:s_71375f7a", "m1_offer_aad92c11"}, -- In this system?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_ac951104)

denner_convo_m1_offer_ego = ConvoScreen:new {
	id = "m1_offer_ego",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_5e3cc3ae", -- Alozen did mention to me that you had a slight ego, but he also said you at least had the skills to back up you mouth. If this is true you can brag all you want. I find that pilots who express themselves fair far better on the battlefield. Although, I will not tolerate any rudeness towards me, this outfit, or the Empire.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_e374b3bf", "m1_offer_666d4e98"}, -- I will remember that, sir.
		{"@conversation/tatooine_imperial_tier3:s_c5320bec", "m1_offer_d2ef774"}, -- I don't have an ego. I am the best!
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_ego)

denner_convo_m1_offer_4ca34e11 = ConvoScreen:new {
	id = "m1_offer_4ca34e11",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_4ca34e11", -- I think that you and I are going to get along just splendidly. From what I understand you have the makings of a very find pilot, %NU.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_dd4be05c", "m1_offer_c8fb2a47"}, -- What is my first assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_4ca34e11)

denner_convo_m1_offer_e83e03f6 = ConvoScreen:new {
	id = "m1_offer_e83e03f6",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_e83e03f6", -- They're dreamers. They fail to recognize the futility of their cause. So many wasted lives all in the name of so called freedom. What they fail to understand that even if they win they will just be under someone else's control. There is no such thing as true freedom.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_996c6fd3", "m1_offer_8ff025a4"}, -- What's Storm Squadron's assignment?
		{"@conversation/tatooine_imperial_tier3:s_68b52625", "m1_offer_7728672b"}, -- That sounded sort of traitorous?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_e83e03f6)

denner_convo_m1_offer_aad92c11 = ConvoScreen:new {
	id = "m1_offer_aad92c11",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_aad92c11", -- No, Storm Squadron is moving out of the Yavin system. We have been reassigned to security detail for a top secret project taking place inside the Endor system. For the time being we will still be operating command from here on Yavin 4 until the move is completed.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_ad5060b2", "m1_offer_5e3cc3ae"}, -- Doesn't matter where I am located. I rule space no matter the system.
		{"@conversation/tatooine_imperial_tier3:s_b16490f1", "m1_offer_d09291f7"}, -- Secret project? Sounds interesting.
		{"@conversation/tatooine_imperial_tier3:s_c118c966", "m1_offer_7679bb3b"}, -- I am honored to serve under the Emperor's Hand.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_aad92c11)

denner_convo_m1_offer_666d4e98 = ConvoScreen:new {
	id = "m1_offer_666d4e98",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_666d4e98", -- Good. Then we will not have to worry about any sort of disciplinary action. For the time being Storm Squadron has been personally chosen by the Emperor to head security for a most important and secret project in the Endor system. We are beginning our move out of the Yavin system but have not yet set up a base of operations in Endor. Command will still be stationed on Yavin 4 for the time being.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_b16490f1", "m1_offer_d09291f7"}, -- Secret project? Sounds interesting.
		{"@conversation/tatooine_imperial_tier3:s_c118c966", "m1_offer_7679bb3b"}, -- I am honored to serve under the Emperor's Hand.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_666d4e98)

denner_convo_m1_offer_d2ef774 = ConvoScreen:new {
	id = "m1_offer_d2ef774",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d2ef774", -- I have heard that from more than a few young pilots who have walked through my door. Most of those pilots only live in my memory now. I sincerely hope that the same fate does not await you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_efdebeb8", "m1_offer_b6b37d2c"}, -- You can count on it, sir.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_d2ef774)

denner_convo_m1_offer_c8fb2a47 = ConvoScreen:new {
	id = "m1_offer_c8fb2a47",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c8fb2a47", -- Direct and to the point, I like it. Storm Squadron has been personally chosen by the Emperor to head security for a most important and secret project in the Endor system. We are beginning our move out of the Yavin system but have not yet set up a base of operations in Endor. Command will still be stationed on Yavin 4 for the time being.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_ad5060b2", "m1_offer_5e3cc3ae"}, -- Doesn't matter where I am located. I rule space no matter the system.
		{"@conversation/tatooine_imperial_tier3:s_b16490f1", "m1_offer_d09291f7"}, -- Secret project? Sounds interesting.
		{"@conversation/tatooine_imperial_tier3:s_c118c966", "m1_offer_7679bb3b"}, -- I am honored to serve under the Emperor's Hand.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_c8fb2a47)

denner_convo_m1_offer_8ff025a4 = ConvoScreen:new {
	id = "m1_offer_8ff025a4",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_8ff025a4", -- Storm Squadron has been personally chosen by the Emperor to head security for a most important and secret project in the Endor system. We are beginning our move out of the Yavin system but have not yet set up a base of operations in Endor. Command will still be stationed on Yavin 4 for the time being.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_ad5060b2", "m1_offer_5e3cc3ae"}, -- Doesn't matter where I am located. I rule space no matter the system.
		{"@conversation/tatooine_imperial_tier3:s_b16490f1", "m1_offer_d09291f7"}, -- Secret project? Sounds interesting.
		{"@conversation/tatooine_imperial_tier3:s_c118c966", "m1_offer_7679bb3b"}, -- I am honored to serve under the Emperor's Hand.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_8ff025a4)

denner_convo_m1_offer_7728672b = ConvoScreen:new {
	id = "m1_offer_7728672b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_7728672b", -- Not at all. I have made my choice and I am completely loyal to the Emperor. Only he can bring about order from the chaos that the Old Republic left us with. In these times you need to have a strong, capable leader and there is no one I would rather follow than the Emperor. But I am a realist and completely understand that to gain peace one must sacrifice some personal freedoms.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_13380a80", "m1_offer_d55771c4"}, -- I don't think that peace can only be brought about by loss of freedom.
		{"@conversation/tatooine_imperial_tier3:s_1c4ab1df", "m1_offer_8ace66c8"}, -- That is exactly how I feel.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_7728672b)

denner_convo_m1_offer_5e3cc3ae = ConvoScreen:new {
	id = "m1_offer_5e3cc3ae",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_5e3cc3ae", -- Alozen did mention to me that you had a slight ego, but he also said you at least had the skills to back up you mouth. If this is true you can brag all you want. I find that pilots who express themselves fair far better on the battlefield. Although, I will not tolerate any rudeness towards me, this outfit, or the Empire.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_e374b3bf", "m1_offer_ff74cc15"}, -- I will remember that, sir.
		{"@conversation/tatooine_imperial_tier3:s_dd4be05c", "m1_offer_8d0d7812"}, -- What is my first assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_5e3cc3ae)

denner_convo_m1_offer_d09291f7 = ConvoScreen:new {
	id = "m1_offer_d09291f7",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d09291f7", -- Please, keep your curiosity to yourself. This project has been sealed to the throne, any violation of that order will result in immediate execution. We are simply in the Endor system to provide security for the engineers, cargo freighters, and command personnel. We are NOT there to ask questions.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_b3001b77", "m1_offer_b8fba9bb"}, -- How can we provide security without knowing what we are protecting?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_d09291f7)

denner_convo_m1_offer_7679bb3b = ConvoScreen:new {
	id = "m1_offer_7679bb3b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_7679bb3b", -- Good! Then we will not have any problems understanding one another. Our mission is highly important and the Emperor has placed his faith in us. We will not fail.
	stopConversation = "false",
	animation = "nod",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_e8e85347", "m1_offer_8d0d7812"}, -- Direct me and I shall succeed.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_7679bb3b)

denner_convo_m1_offer_b6b37d2c = ConvoScreen:new {
	id = "m1_offer_b6b37d2c",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b6b37d2c", -- Well, we shall see now won't we? Storm Squadron has been personally chosen by the Emperor to head security for a most important and secret project in the Endor system. We are beginning our move out of the Yavin system but have not yet set up a base of operations in Endor. Command will still be stationed on Yavin 4 for the time being.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_b16490f1", "m1_offer_d09291f7"}, -- Secret project? Sounds interesting.
		{"@conversation/tatooine_imperial_tier3:s_c27dc8c9", "m1_offer_7679bb3b"}, -- I am honored to serve under the Emperor's hand.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_b6b37d2c)

denner_convo_m1_offer_d55771c4 = ConvoScreen:new {
	id = "m1_offer_d55771c4",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d55771c4", -- Absolute freedom breeds discontent and anarchy. If everyone is allowed to do their own thing then there will be growth for society as a whole. And there can be no peace as long as the galaxy is splintered into many different factions. Only the Empire can unify all those different factions and bring about ultimate peace. In order for us to do that we must be strong. Storm Squadron is part of that unifying strength.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_38a75f0", "m1_offer_8ff025a4"}, -- What is Storm Squadron's next assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_d55771c4)

denner_convo_m1_offer_8ace66c8 = ConvoScreen:new {
	id = "m1_offer_8ace66c8",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_8ace66c8", -- You wouldn't be here if you felt otherwise. The Empire will unify the galaxy and bring about an era of unprecedented peace. Storm Squadron's current assignment might play an important role in the realization of that goal.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_996c6fd3", "m1_offer_8ff025a4"}, -- What's Storm Squadron's assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_8ace66c8)

denner_convo_m1_offer_ff74cc15 = ConvoScreen:new {
	id = "m1_offer_ff74cc15",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ff74cc15", -- Good! It would be a shame for me to have to discipline someone who has just entered my command. So pilot, are you ready to take your first assignment or do you need a little time?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_789def9d", "m1_offer_8d0d7812"}, -- I am ready for my assignment.
		{"@conversation/tatooine_imperial_tier3:s_8df560dd", "m1_offer_2e0a96f8"}, -- Nope, I can't say that I am ready yet.
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_ff74cc15)

denner_convo_m1_offer_8d0d7812 = ConvoScreen:new {
	id = "m1_offer_8d0d7812",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_8d0d7812", -- As I said before we will be running security detail in the Endor system for a project that has been sealed to the throne. To my understanding there will be numerous engineers, supply freighters, and command vessels will need protection from any interference. On top of that the entire system must be kept under quarantine to avoid any word of the project from reaching the outside.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_9fbaa975", "m1_accept"}, -- Keeping a lid on entire system will be no easy task.
		{"@conversation/tatooine_imperial_tier3:s_31e494df", "m1_offer_ec6eda2a"}, -- What does sealed to the throne mean?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_8d0d7812)

denner_convo_m1_offer_b8fba9bb = ConvoScreen:new {
	id = "m1_offer_b8fba9bb",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b8fba9bb", -- We know exactly what we are protecting. We are protecting the personnel and vessels involved in a top secret project. That means we keep them safe and keep others out. Fairly simple, wouldn't you say?
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_9dedc264", "m1_offer_9511fbeb"}, -- I don't know if I would say...
		{"@conversation/tatooine_imperial_tier3:s_386b16a5", "m1_assignment"}, -- Understood, sir. What is my first assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_b8fba9bb)

denner_convo_m1_offer_2e0a96f8 = ConvoScreen:new {
	id = "m1_offer_2e0a96f8",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_2e0a96f8", -- To bad! In this outfit you will work on my schedule not your own. I only asked to be polite, I honestly didn't expect you to say no. Let us try this again. Pilot are you ready for your first assignment?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_2e4db1a8", "m1_offer_b4880204"}, -- Yes, sir! Ready and willing, sir!
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_2e0a96f8)

denner_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_9011f51", -- I couldn't agree more. But that is why the Emperor asked for Storm Squadron. We are the best military outfit in the whole of the Navy. Your first assignment will be the protection of engineers being transferred from the Yavin salvage operation. You are to meet their shuttle in the Endor system and escort them safely through the area until they reach system headquarters.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c7db2e97", "m1_offer_c183fa1a"}, -- So a simple, escort. I thought this was going to be hard.
		{"@conversation/tatooine_imperial_tier3:s_e82e2f2d", "m1_offer_52345d7c"}, -- You can count on me, sir! They will arrive safely.
		{"@conversation/tatooine_imperial_tier3:s_c17e8fe8", "m1_offer_ef77d77a"}, -- Hopefully they will attract some attention.The practice would be nice.
	}
}
denner_convo_template:addScreen(denner_convo_m1_accept)

denner_convo_m1_offer_ec6eda2a = ConvoScreen:new {
	id = "m1_offer_ec6eda2a",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ec6eda2a", -- Sealed to the throne basically means that all project information about Endor is on a need to know basis. Usually only a few top personnel even know entirely what is happening when something is sealed to the throne. Everyone is told only enough to do their jobs. Of course that doesn't mean we cannot speculate, just be sure to keep your speculation to yourself.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_ad622e6d", "m1_assignment"}, -- I see. About my assignment?
		{"@conversation/tatooine_imperial_tier3:s_7e276839", "m1_offer_88d2aba6"}, -- So they could be making another...
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_ec6eda2a)

denner_convo_m1_offer_9511fbeb = ConvoScreen:new {
	id = "m1_offer_9511fbeb",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_9511fbeb", -- That was a question that didn't need a response. I can see that I am going to have to keep a close watch on your activities. You are supposed to be a fine pilot so I would highly suggest that you keep your focus on that.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_84b912c3", "m1_assignment"}, -- Very well, what is my assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_9511fbeb)

denner_convo_m1_assignment = ConvoScreen:new {
	id = "m1_assignment",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_5c298649", -- Your first assignment will be the protection of engineers being transferred from the Yavin salvage operation. You are to meet their shuttle in the Endor system and escort them safely through the area until they reach system headquarters.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c7db2e97", "m1_offer_c183fa1a"}, -- So a simple, escort. I thought this was going to be hard.
		{"@conversation/tatooine_imperial_tier3:s_e82e2f2d", "m1_offer_52345d7c"}, -- You can count on me, sir! They will arrive safely.
		{"@conversation/tatooine_imperial_tier3:s_c17e8fe8", "m1_offer_ef77d77a"}, -- Hopefully they will attract some attention.The practice would be nice.
	}
}
denner_convo_template:addScreen(denner_convo_m1_assignment)

denner_convo_m1_offer_b4880204 = ConvoScreen:new {
	id = "m1_offer_b4880204",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b4880204", -- Much better! As I said before we will be running security detail in the Endor system for a project that has been sealed to the throne. To my understanding there will be numerous engineers, supply freighters, and command vessels will need protection from any interference. On top of that the entire system must be kept under quarantine to avoid any word of the project from reaching the outside.
	stopConversation = "false",
	animation = "nod",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_9fbaa975", "m1_accept"}, -- Keeping a lid on entire system will be no easy task.
		{"@conversation/tatooine_imperial_tier3:s_31e494df", "m1_offer_ec6eda2a"}, -- What does sealed to the throne mean?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_b4880204)

denner_convo_m1_offer_c183fa1a = ConvoScreen:new {
	id = "m1_offer_c183fa1a",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c183fa1a", -- Let's hope that this stays a simple escort. This project is of utmost importance to the Empire. Any disruption could jeopardize the entire operation. You will make sure that those engineers arrive in Endor just as safely as they left here. Dismissed, pilot.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_c183fa1a)

denner_convo_m1_offer_52345d7c = ConvoScreen:new {
	id = "m1_offer_52345d7c",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_52345d7c", -- That is what I wanted to hear. Good luck, %NU.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_52345d7c)

denner_convo_m1_offer_ef77d77a = ConvoScreen:new {
	id = "m1_offer_ef77d77a",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ef77d77a", -- Hopefully we most certainly will not attract any attention! You will not go out of your way to find any sort of action. Those engineers will arrive in Endor safely, you WILL be sure of that. You are dismissed, pilot.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_ef77d77a)

denner_convo_m1_offer_88d2aba6 = ConvoScreen:new {
	id = "m1_offer_88d2aba6",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_88d2aba6", -- STOP RIGHT THERE! I told you to keep any speculation you might have to yourself and I will not tolerate otherwise.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c84be049", "m1_assignment"}, -- Sorry, sir. Now about my assignment?
	}
}
denner_convo_template:addScreen(denner_convo_m1_offer_88d2aba6)

denner_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ea1cf0eb", -- Nice, timing. I was just about to send for you. We have work to do.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_9a760bb5", "m2_intel"}, -- I am ready, sir.
		{"@conversation/tatooine_imperial_tier3:s_5332f155", "m2_offer_558af4fe"}, -- And you need your best pilot.
		{"@conversation/tatooine_imperial_tier3:s_b9c26cb1", "m2_offer_c9189ff3"}, -- Just tell me who to kill.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer)

denner_convo_m2_intel = ConvoScreen:new {
	id = "m2_intel",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_2800345f", -- Intelligence has finished decrypting the data that you recovered from that Rebel scout. The data only included the operational status of a few of the Rebels in the area but it was enough to give us an idea of what the Rebels are doing in this area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_39538c2a", "m2_offer_4ac29222"}, -- What did they find out?
	}
}
denner_convo_template:addScreen(denner_convo_m2_intel)

denner_convo_m2_offer_558af4fe = ConvoScreen:new {
	id = "m2_offer_558af4fe",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_558af4fe", -- Yes, but he's out on a mission. You'll have to do.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_36111dde", "m2_offer_934958df"}, -- Hey, wait a minute!
		{"@conversation/tatooine_imperial_tier3:s_953ef4f4", "m2_intel"}, -- Hmmm...well what is it you want for me to do?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_558af4fe)

denner_convo_m2_offer_c9189ff3 = ConvoScreen:new {
	id = "m2_offer_c9189ff3",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c9189ff3", -- Pilot! Get you emotions under control. I cannot afford to hand this operation over to someone with a personnel vendetta. I want pilots, not rampaging psychopaths. Is that clear?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_826b239", "m2_offer_71d95d29"}, -- Clear enough.
		{"@conversation/tatooine_imperial_tier3:s_2642ebb3", "m2_offer_b89e6b42"}, -- Don't worry. I can keep a cool head when needed.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_c9189ff3)

denner_convo_m2_offer_4ac29222 = ConvoScreen:new {
	id = "m2_offer_4ac29222",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_4ac29222", -- Somehow the Rebels have gotten word of what is going on here. We don't believe that they have the complete story, but they are aware that the Empire is working on a top secret project in the Endor system. They also are aware that engineers working on the Yavin salvage operation are being transferred to the Endor system. It would seem they were trying to capture a few of them in order to discover the exact nature of the project.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_bf67c417", "m2_offer_524d9247"}, -- So they are not yet aware of what the Empire is doing?
		{"@conversation/tatooine_imperial_tier3:s_e956329d", "m2_offer_abcfd5a5"}, -- How would they have managed to get that information?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_4ac29222)

denner_convo_m2_offer_934958df = ConvoScreen:new {
	id = "m2_offer_934958df",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_934958df", -- Do you have a problem with my assessment of your skills? I would suggest that you try harder and maybe they will change. Regardless, we still have a job to do,
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_6acf2f90", "m2_offer_report"}, -- And what would that job be?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_934958df)

denner_convo_m2_offer_71d95d29 = ConvoScreen:new {
	id = "m2_offer_71d95d29",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_71d95d29", -- Hmm. Well any ways, Intelligence has finished decrypting the data that you recovered from that Rebel scout. The data only included the operational status of a few of the Rebels in the area but it was enough to give us an idea of what the Rebels are doing in this area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_3898a3b8", "m2_offer_d0ca9684"}, -- So what did the brains at Intel find out?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_71d95d29)

denner_convo_m2_offer_b89e6b42 = ConvoScreen:new {
	id = "m2_offer_b89e6b42",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b89e6b42", -- That is what I wanted to hear. Intelligence has finished decrypting the data that you recovered from that Rebel scout. The data only included the operational status of a few of the Rebels in the area but it was enough to give us an idea of what the Rebels are doing in this area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_1d653cbd", "m2_offer_4ac29222"}, -- And what did they uncover?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_b89e6b42)

denner_convo_m2_offer_524d9247 = ConvoScreen:new {
	id = "m2_offer_524d9247",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_524d9247", -- Not yet. But if we don't put a lid on this it is very likely that they will shortly. We need to find out more about what the Rebels are planning. THat is where you come in.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_44bd3318", "m2_offer_ad08e741"}, -- What is it you need me to do?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_524d9247)

denner_convo_m2_offer_abcfd5a5 = ConvoScreen:new {
	id = "m2_offer_abcfd5a5",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_abcfd5a5", -- There is only one way that the Rebels could have gotten the information that they did have...a member of the Empire leaked it to them. A since they were aware of the flight times and routes of the vessels they attacked that can only mean that whoever leaked this information was a commanding officer.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_37f05ce8", "m2_offer_20d40c9b"}, -- An Imperial officer has turned traitor! What are we going to do?
		{"@conversation/tatooine_imperial_tier3:s_6aba6ae5", "m2_offer_730d9c3d"}, -- How much more do the Rebels know?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_abcfd5a5)

denner_convo_m2_offer_report = ConvoScreen:new {
	id = "m2_offer_report",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_2800345f", -- Intelligence has finished decrypting the data that you recovered from that Rebel scout. The data only included the operational status of a few of the Rebels in the area but it was enough to give us an idea of what the Rebels are doing in this area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c8f732dc", "m2_offer_4ac29222"}, -- What was in that report?
		{"@conversation/tatooine_imperial_tier3:s_60c284ea", "m2_offer_9a5c94ec"}, -- Ah, yes. That was my finest hour.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_report)

denner_convo_m2_offer_d0ca9684 = ConvoScreen:new {
	id = "m2_offer_d0ca9684",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d0ca9684", -- The AGENTS in Intelligence discovered that the Rebellion has managed to get their hands on some very confidential information. They had flight schedules, routes, and defense plans from all over the system. It would seem that the Rebels were supposed to capture some of the engineers in order to find out more about the Imperial operations in the Endor system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_e2ebe5ea", "m2_offer_leak"}, -- And how would the Rebels have gotten that information?
		{"@conversation/tatooine_imperial_tier3:s_ef128cbc", "m2_offer_44f098fe"}, -- So, it is safe to assume they don't know exactly what the operation is.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_d0ca9684)

denner_convo_m2_offer_ad08e741 = ConvoScreen:new {
	id = "m2_offer_ad08e741",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ad08e741", -- We have placed out a number of barrier satellites around the Endor system. They are designed to track the movements of any vessels that move to close to them. They have recorded a few Rebel fighters moving and fortunately for us another of the Rebel scouts.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_fb7fd32", "m2_offer_f51fd3ee"}, -- I take it you want me to inspect that scout as well?
		{"@conversation/tatooine_imperial_tier3:s_33061c38", "m2_offer_6802fe45"}, -- I will destroy that scout with extremely prejudice.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_ad08e741)

denner_convo_m2_offer_20d40c9b = ConvoScreen:new {
	id = "m2_offer_20d40c9b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_20d40c9b", -- We are going to continue our job in trying to lock down the Endor system. The other matter has been turned over the Inquisition. If anyone can sniff out a traitor it will be them.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_5bd69df6", "m2_offer_ad08e741"}, -- What do you need me to do?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_20d40c9b)

denner_convo_m2_offer_730d9c3d = ConvoScreen:new {
	id = "m2_offer_730d9c3d",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_730d9c3d", -- It's hard to tell. Since they were trying to capture engineers for interrogation I think it is safe to assume that they are not yet aware of the nature of the Endor project. If I had to guess the traitor is either working on this project or a related project but does not have significant enough clearance to have the whole story.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_2e8fad6a", "m2_offer_4b2d23bc"}, -- So are we going to try to find out who the traitor is?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_730d9c3d)

denner_convo_m2_offer_9a5c94ec = ConvoScreen:new {
	id = "m2_offer_9a5c94ec",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_9a5c94ec", -- Yes...yes. You did very well in capturing that Rebel scout. Now that I have stroked your obviously fragile ego, may I continue with my briefing?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_d20bfc57", "m2_offer_6b6b3e96"}, -- Uhh, yes of course.
		{"@conversation/tatooine_imperial_tier3:s_ad784b0a", "m2_offer_1bc2db0c"}, -- My ego isn't fragile. I know I am the best!
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_9a5c94ec)

denner_convo_m2_offer_leak = ConvoScreen:new {
	id = "m2_offer_leak",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_abcfd5a5", -- There is only one way that the Rebels could have gotten the information that they did have...a member of the Empire leaked it to them. A since they were aware of the flight times and routes of the vessels they attacked that can only mean that whoever leaked this information was a commanding officer.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_2e8fad6a", "m2_offer_4b2d23bc"}, -- So are we going to try to find out who the traitor is?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_leak)

denner_convo_m2_offer_44f098fe = ConvoScreen:new {
	id = "m2_offer_44f098fe",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_44f098fe", -- It is not safe to assume any such thing, but all signs do point towards that conclusion.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_bf67c417", "m2_offer_524d9247"}, -- So they are not yet aware of what the Empire is doing?
		{"@conversation/tatooine_imperial_tier3:s_e956329d", "m2_offer_abcfd5a5"}, -- How would they have managed to get that information?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_44f098fe)

denner_convo_m2_offer_f51fd3ee = ConvoScreen:new {
	id = "m2_offer_f51fd3ee",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_f51fd3ee", -- Naturally. That scout probably contains another piece of the puzzle. If we can gather enough information on the Rebel operation then we will be able to plug this leak. Unfortunately, the Rebel will always know about the Imperial project in the Endor system but we can stop them from finding out what it is.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_bb9e4a63", "m2_accept"}, -- Understood, sir.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_f51fd3ee)

denner_convo_m2_offer_6802fe45 = ConvoScreen:new {
	id = "m2_offer_6802fe45",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_6802fe45", -- How would we learn anything about the Rebel plans if you go around destroying our best leads? I don't what the scout destroyed! I want you to capture and inspect it for any new information that it might be carrying. Is that understood, pilot?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a835651f", "m2_accept_promise"}, -- Understood! I will not let you down.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_6802fe45)

denner_convo_m2_offer_4b2d23bc = ConvoScreen:new {
	id = "m2_offer_4b2d23bc",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_4b2d23bc", -- No, we are going to continue our job and try to lock down the Endor system. We have to make sure that the Rebels are unable to find the answers that they are looking for. The matter of the traitor has been turned over to the Inquisition. If anyone can find the traitor, they can.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_5bd69df6", "m2_offer_ad08e741"}, -- What do you need me to do?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_4b2d23bc)

denner_convo_m2_offer_6b6b3e96 = ConvoScreen:new {
	id = "m2_offer_6b6b3e96",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_6b6b3e96", -- Good. Somehow the Rebels have gotten word of what is going on here. We don't believe that they have the complete story, but they are aware that the Empire is working on a top secret project in the Endor system. They also are aware that engineers working on the Yavin salvage operation are being transferred to the Endor system. It would seem they were trying to capture a few of them in order to discover the exact nature of the project.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_bf67c417", "m2_offer_524d9247"}, -- So they are not yet aware of what the Empire is doing?
		{"@conversation/tatooine_imperial_tier3:s_e956329d", "m2_offer_abcfd5a5"}, -- How would they have managed to get that information?
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_6b6b3e96)

denner_convo_m2_offer_1bc2db0c = ConvoScreen:new {
	id = "m2_offer_1bc2db0c",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1bc2db0c", -- Of course you are. Like I said before, if you continue to successfully perform your duty then I have no problem with your distorted vision of your self worth. But we really need to get back to matters at hand.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_202ff29c", "m2_offer_4ac29222"}, -- Of course we do.
	}
}
denner_convo_template:addScreen(denner_convo_m2_offer_1bc2db0c)

denner_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_afe7ad77", -- We will update you to the location of the new Rebel scout as soon as you are in the Endor system. Remember a lot is riding on your success. Good luck, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m2_accept)

denner_convo_m2_accept_promise = ConvoScreen:new {
	id = "m2_accept_promise",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_421f0679", -- Be sure that you don't. We will update you to the location of the new Rebel scout as soon as you are in the Endor system. Remember a lot is riding on your success. Good luck, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m2_accept_promise)

denner_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_3e08af61", -- %NU, I am glad to see you are back. We have completed our evaluation of the reports you took off of the Rebel command vessel. Based off of what we have found, I believe I have devised a way to bring the Rebel menace out into the open.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_4c927c36", "m3_offer_381d2195"}, -- I am ready to crush the Rebels, sir.
		{"@conversation/tatooine_imperial_tier3:s_d19e7587", "m3_offer_c4b21396"}, -- I am ready to add another notch to my belt.
		{"@conversation/tatooine_imperial_tier3:s_e634eb73", "m3_offer_93e9d03b"}, -- It is the Emperor's will that I defeat his foes.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer)

denner_convo_m3_offer_381d2195 = ConvoScreen:new {
	id = "m3_offer_381d2195",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_381d2195", -- If my plan works then you will have your opportunity. From the reports you recovered we discovered that the Rebels were given access to our security frequency. They have been listening in on our chatter and have been using what they heard from us to help plan their attacks.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_5c4d8358", "m3_offer_60f183ae"}, -- The traitor again?
		{"@conversation/tatooine_imperial_tier3:s_853fa46c", "m3_offer_d8c02b03"}, -- We should change our frequencies.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_381d2195)

denner_convo_m3_offer_c4b21396 = ConvoScreen:new {
	id = "m3_offer_c4b21396",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c4b21396", -- I see that you are eager to get underway. But perhaps it would be best if you allowed me to explain what we are going to try to accomplish before flying off.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_c01151b0", "m3_offer_1efa28ce"}, -- Sure. That might be useful.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_c4b21396)

denner_convo_m3_offer_93e9d03b = ConvoScreen:new {
	id = "m3_offer_93e9d03b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_93e9d03b", -- If you say so. But I would ask that you try to keep your zeal for killing the Emperor's enemies to a minimum and focus on the mission I am about to give to you. There will be plenty of enemy smiting on it, I assure you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a49e0a76", "m3_offer_52651592"}, -- Then you must explain this mission to me.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_93e9d03b)

denner_convo_m3_offer_60f183ae = ConvoScreen:new {
	id = "m3_offer_60f183ae",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_60f183ae", -- Of course. Although this is not all bad now that we know about the leak. My plan involves using this leak in order to draw the Rebels out.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a950fa1d", "m3_offer_be28f7e0"}, -- What is the plan, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_60f183ae)

denner_convo_m3_offer_d8c02b03 = ConvoScreen:new {
	id = "m3_offer_d8c02b03",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d8c02b03", -- Not quite yet. We are going to use our knowledge that the Rebels have tapped into our secure lines against them.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a950fa1d", "m3_offer_be28f7e0"}, -- What is the plan, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_d8c02b03)

denner_convo_m3_offer_1efa28ce = ConvoScreen:new {
	id = "m3_offer_1efa28ce",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1efa28ce", -- From the reports you recovered we discovered that the Rebels were given access to our security frequency. They have been listening in on our chatter and have been using what they heard from us to help plan their attacks.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_f9d2ed90", "m3_offer_c23c0889"}, -- Very crafty of them.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_1efa28ce)

denner_convo_m3_offer_52651592 = ConvoScreen:new {
	id = "m3_offer_52651592",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_52651592", -- Intelligence has discovered from the reports you captured that the Rebels have been using our communications to help plan their attacks. The traitor apparently gave them our frequencies and access codes.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_4296221e", "m3_offer_a8daab7"}, -- Send me after the traitor. I will destroy him.
		{"@conversation/tatooine_imperial_tier3:s_637a3419", "m3_offer_3c3702e6"}, -- The Rebellion will pay for that.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_52651592)

denner_convo_m3_offer_be28f7e0 = ConvoScreen:new {
	id = "m3_offer_be28f7e0",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_be28f7e0", -- First, we will need to inform Endor about our intentions. Because the Rebels are listening into our communications we will have to send the plans to them on your vessel. Once they have the plans we will send out a message about a shuttle carrying top secret documents on its way through the Endor system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_926a6e73", "m3_offer_d6bf6113"}, -- Is it wise to tell the Rebellion that we are sending top secret documents?
		{"@conversation/tatooine_imperial_tier3:s_3c1eecb4", "m3_offer_abdbf980"}, -- I take it the documents will be fakes.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_be28f7e0)

denner_convo_m3_offer_c23c0889 = ConvoScreen:new {
	id = "m3_offer_c23c0889",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c23c0889", -- Indeed. But now that we know they have access to our communications, we have the advantage. My plan involves using this leak in order to draw the Rebels out.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a950fa1d", "m3_offer_be28f7e0"}, -- What is the plan, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_c23c0889)

denner_convo_m3_offer_a8daab7 = ConvoScreen:new {
	id = "m3_offer_a8daab7",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a8daab7", -- I am sure the Inquisition appreciates your faith in their abilities. They will handle the matter of the traitor. Your concern should be on Storm Squadron business. The Emperor wants to here to help protect his interests.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_9b266fb", "m3_offer_31d67ce2"}, -- Yes. The Emperor needs me here.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_a8daab7)

denner_convo_m3_offer_3c3702e6 = ConvoScreen:new {
	id = "m3_offer_3c3702e6",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_3c3702e6", -- All in good time. Although this is not all bad now that we know about the leak. My plan involves using this leak in order to draw the Rebels out.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a950fa1d", "m3_offer_be28f7e0"}, -- What is the plan, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_3c3702e6)

denner_convo_m3_offer_d6bf6113 = ConvoScreen:new {
	id = "m3_offer_d6bf6113",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_d6bf6113", -- The documents will be fake. We are counting on the Rebels attacking the shuttle, which you will be escorting. If we can make this look real to them by killing enough of their fighters, it will cause them to want to find out what we are fighting so hard to protect. When the time is right, the shuttle will pretend to make a run for it and allow itself to be captured. The Rebels will find the fake documents and they will be ours.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_7077d0f3", "m3_offer_c3fac79d"}, -- Oh, of course I knew that.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_d6bf6113)

denner_convo_m3_offer_abdbf980 = ConvoScreen:new {
	id = "m3_offer_abdbf980",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_abdbf980", -- Exactly. We are counting on the Rebels attacking the shuttle, which you will be escorting. If we can make this look very real to them and kill enough of their fighters, it will cause them to want to find out what we are fighting so hard to protect. When the time is right, the shuttle will pretend to make a run for it and allow itself to be captured. The Rebels will find the fake documents and they will be ours.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_eacf6042", "m3_offer_20350ba5"}, -- What information will those documents contain?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_abdbf980)

denner_convo_m3_offer_31d67ce2 = ConvoScreen:new {
	id = "m3_offer_31d67ce2",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_31d67ce2", -- Yes he does. And this is what he wants you to do. First, you need to inform Endor about our intentions. Because the Rebels are listening into our transmissions we will have to send the plans to them on your vessel. Once they have the plans we will send out a message about a shuttle carrying top secret documents on its way through the Endor system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_926a6e73", "m3_offer_d6bf6113"}, -- Is it wise to tell the Rebellion that we are sending top secret documents?
		{"@conversation/tatooine_imperial_tier3:s_3c1eecb4", "m3_offer_abdbf980"}, -- I take it the documents will be fakes.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_31d67ce2)

denner_convo_m3_offer_c3fac79d = ConvoScreen:new {
	id = "m3_offer_c3fac79d",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c3fac79d", -- Of course you did. The documents will have coordinates to a supposed command station. If all goes well the Rebels will take the bait and attack in force. They will not find any station at that location but they will find you. You are keep the fighters occupied while we scan the surrounding area for the Rebel command.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_60893b02", "m3_offer_f0d5d662"}, -- If we find it, should it be destroyed?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_c3fac79d)

denner_convo_m3_offer_20350ba5 = ConvoScreen:new {
	id = "m3_offer_20350ba5",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_20350ba5", -- The documents will have coordinates to a supposed command station. If all goes well the Rebels will take the bait and attack in force. They will not find any station at that location but they will find you. You are keep the fighters occupied while we scan the surrounding area for the Rebel command.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_60893b02", "m3_offer_f0d5d662"}, -- If we find it, should it be destroyed?
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_20350ba5)

denner_convo_m3_offer_f0d5d662 = ConvoScreen:new {
	id = "m3_offer_f0d5d662",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_f0d5d662", -- No. We still do not know everything that the traitor has given to the Rebellion. Without that information the Rebels could simply send in another command ship and we would be right back to where we are now. But we will keep track of the vessel until we can decide how best to proceed.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_d25510d5", "m3_accept"}, -- Understood. I am ready to begin, sir.
		{"@conversation/tatooine_imperial_tier3:s_8195ae89", "m3_accept_half"}, -- This shouldn't be too hard.
		{"@conversation/tatooine_imperial_tier3:s_d4402e2e", "m3_accept_smite"}, -- The Emperor will guide me true.
	}
}
denner_convo_template:addScreen(denner_convo_m3_offer_f0d5d662)

denner_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1b1b59fd", -- Excellent. We are sending the plans on Lambda shuttle to the Endor system. Meet up with the shuttle and transfer them to your craft. Then drop them off at Endor control. Once that is done the real operation can begin. Good luck to you, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m3_accept)

denner_convo_m3_accept_half = ConvoScreen:new {
	id = "m3_accept_half",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_4d64efd2", -- I am sure if you perform the mission half as well as you think you will, it will go smoothly. We are sending the plans on Lambda shuttle to the Endor system. Meet up with the shuttle and transfer them to your craft. Then drop them off at Endor control. Once that is done the real operation can begin. Good luck to you, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m3_accept_half)

denner_convo_m3_accept_smite = ConvoScreen:new {
	id = "m3_accept_smite",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_f1ae24d9", -- Go forth, execute the Emperor's plan, and smite his enemies. We are sending the plans on Lambda shuttle to the Endor system. Meet up with the shuttle and transfer them to your craft. Then drop them off at Endor control. Once that is done the real operation can begin. Good luck to you, %NU.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m3_accept_smite)

denner_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_84affc75", -- Now that we have a lock on the Rebel command vessel the time has come for us to start flexing our muscles, so to speak.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_890ce7a3", "m4_offer_b196e01f"}, -- I couldn't agree more, sir.
		{"@conversation/tatooine_imperial_tier3:s_d6e0ca4c", "m4_offer_ee1dc70b"}, -- It's about time you let me take off the kid gloves.
		{"@conversation/tatooine_imperial_tier3:s_81652bd6", "m4_offer_a7f392e3"}, -- There is no strength without the guidance of the Emperor.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer)

denner_convo_m4_offer_b196e01f = ConvoScreen:new {
	id = "m4_offer_b196e01f",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b196e01f", -- Even though we are still looking for the clues as to how much information the Rebellion has been given by the traitor, we have allowed the Rebels to run rampant through out the Endor system for long enough. We need to start reducing their numbers before they get out of control.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_567580f2", "m4_offer_1ba3e73d"}, -- So we still have not been able to find the traitor?
		{"@conversation/tatooine_imperial_tier3:s_afdf6d6", "m4_offer_7750f639"}, -- What is it you want me to do, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_b196e01f)

denner_convo_m4_offer_ee1dc70b = ConvoScreen:new {
	id = "m4_offer_ee1dc70b",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_ee1dc70b", -- Well this is your chance. We are still looking for clues as to how much information the Rebellion has at their disposal, but we cannot ignore the growing number of Rebel fighters in the Endor system any longer.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_10a5b81d", "m4_offer_b9bfd3a8"}, -- I really hope this is a sweep and clear.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_ee1dc70b)

denner_convo_m4_offer_a7f392e3 = ConvoScreen:new {
	id = "m4_offer_a7f392e3",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_a7f392e3", -- And the Emperor wants you to follow my instructions. I am sure his guidance will lead you to victory over our enemies.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_95984c4", "m4_offer_1cbb3be8"}, -- I live only to serve.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_a7f392e3)

denner_convo_m4_offer_1ba3e73d = ConvoScreen:new {
	id = "m4_offer_1ba3e73d",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1ba3e73d", -- The Inquisition has not given us an update on their progress. That is not really a surprise. They tend to dislike sharing information with other branches. I can only hope that they stop the traitor from committing more acts of treason.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_afdf6d6", "m4_offer_7750f639"}, -- What is it you want me to do, sir?
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_1ba3e73d)

denner_convo_m4_offer_7750f639 = ConvoScreen:new {
	id = "m4_offer_7750f639",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_7750f639", -- You are to travel to Endor and start culling the number of Rebel fighters in the system. There is a flight of X-wing that we have been tracking for sometime that I want you to destroy. I have sent other Storm Squadron pilots out on similar missions so if you can take out that flight of Rebel fighters we should have their numbers reduced to a manageable amount.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_25042a7a", "m4_accept"}, -- I will not fail you.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_7750f639)

denner_convo_m4_offer_b9bfd3a8 = ConvoScreen:new {
	id = "m4_offer_b9bfd3a8",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b9bfd3a8", -- You are absolutely correct. You are to destroy a flight of X-wings that we have been tracking. Since I have dispatched other pilots from Storm Squadron you should only need to destroy that one squadron for us to accomplish our goals, but feel free to destroy any extra you wish.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_a14faca6", "m4_accept_confident"}, -- A squadron of X-wings? I don't like their chances.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_b9bfd3a8)

denner_convo_m4_offer_1cbb3be8 = ConvoScreen:new {
	id = "m4_offer_1cbb3be8",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_1cbb3be8", -- Then go to the Endor system and destroy a flight of Rebel X-wings that we have been tracking. It is time that we cull their growing numbers and show them that the Empire is not to be trifled with. I have dispatched other pilots to assist in this great undertaking, so that we will strike the Rebels from all sides.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier3:s_d760b1fe", "m4_accept_blessing"}, -- Yes, that is a sound plan. I will destroy our enemies.
	}
}
denner_convo_template:addScreen(denner_convo_m4_offer_1cbb3be8)

denner_convo_m4_accept = ConvoScreen:new {
	id = "m4_accept",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_76bbd809", -- I know you will not. I have every faith in your ability to handle the Rebels. You are dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m4_accept)

denner_convo_m4_accept_confident = ConvoScreen:new {
	id = "m4_accept_confident",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_266e8481", -- Don't become over confident. You are no good to me dead. Now go take out at least ten Rebel fighters. Good luck, pilot.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m4_accept_confident)

denner_convo_m4_accept_blessing = ConvoScreen:new {
	id = "m4_accept_blessing",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_b5094e65", -- Go with the Emperor's blessing. You are dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_m4_accept_blessing)

denner_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_5f736ba3", -- Very well. Let's begin. And later, report to me for your next mission.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_trained_starships)

denner_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_645af1cb", -- I'll train you now. Afterwards, report to me when you're ready for the next step.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_trained_weapons)

denner_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_c4f3b92c", -- Let's begin your training. When you're done, you'll be ready for a new mission.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_trained_procedures)

denner_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_imperial_tier3:s_3ec1a288", -- Of course. we'll begin now. Report back to me as soon as possible. The Empire needs all hands on deck.
	stopConversation = "true",
	options = {
	}
}
denner_convo_template:addScreen(denner_convo_trained_droid)

addConversationTemplate("denner_convo_template", denner_convo_template)
