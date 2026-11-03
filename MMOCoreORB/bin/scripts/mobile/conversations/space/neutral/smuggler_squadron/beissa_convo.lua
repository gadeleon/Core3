-- Beissa (Smuggler tier 3, Jabba's Palace) conversation screens; ported from SWG-Source tatooine_privateer_tier3 (STF conversation/tatooine_privateer_tier3). Handler: beissaConvoHandler.lua (feature smuggler-tier3-beissa).
beissa_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "beissaConvoHandler",
	screens = {}
}

beissa_convo_not_neutral = ConvoScreen:new {
	id = "not_neutral",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_a2c78f81", -- Unless you're here to buy something, I suggest you keep walking.
	stopConversation = "true",
	animation = "snap_finger1",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_not_neutral)

beissa_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_38d9a05a", -- Who are you? %TU? Oh, yeah...I've heard of you. Word is you're a pretty fair pilot. What can I do for you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_615d980b", "off_track_refused"}, -- I'm looking for work. You got anything?
	}
}
beissa_convo_template:addScreen(beissa_convo_off_track)

beissa_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_59d3a31c", -- Look. You're good, but not that good. If I go around handing our missions to fresh-meat pilots like you, I'd be Sarlacc food in no time, if you know what I mean. Some other time.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_off_track_refused)

beissa_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1baaff63", -- Who are you? One of Jabba's new pilots?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4c695dbd", "not_ready_scram"}, -- No.
		{"@conversation/tatooine_privateer_tier3:s_db3d67b", "not_ready_other_boss"}, -- I don't work for Jabba.
	}
}
beissa_convo_template:addScreen(beissa_convo_not_ready)

beissa_convo_not_ready_scram = ConvoScreen:new {
	id = "not_ready_scram",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_15ef997f", -- This is Jabba's Palace. Unless you're here to work, scram!
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_not_ready_scram)

beissa_convo_not_ready_other_boss = ConvoScreen:new {
	id = "not_ready_other_boss",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_3a0e2d87", -- Then I suggest you find the person you DO work for - and stop wasting my time!
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_not_ready_other_boss)

beissa_convo_busy = ConvoScreen:new {
	id = "busy",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_98be92ae", -- Looking for something?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_11a6885c", "busy_finish"}, -- You, actually.
		{"@conversation/tatooine_privateer_tier3:s_5288ea5c", "busy_why"}, -- Why do you ask?
	}
}
beissa_convo_template:addScreen(beissa_convo_busy)

beissa_convo_busy_finish = ConvoScreen:new {
	id = "busy_finish",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_25ba96cd", -- I don't have anything to say to you - not until you finish your job.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_busy_finish)

beissa_convo_busy_why = ConvoScreen:new {
	id = "busy_why",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e4b6a4d3", -- Because you're supposed to be working. I can't figure out why you'd be shuffling around here.
	stopConversation = "false",
	animation = "cough_polite",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_ac7fe93", "busy_back_to_work"}, -- My mistake.
	}
}
beissa_convo_template:addScreen(beissa_convo_busy_why)

beissa_convo_busy_back_to_work = ConvoScreen:new {
	id = "busy_back_to_work",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_8e5921a5", -- Back to work.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_busy_back_to_work)

beissa_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f840ac8a", -- Was it too much for you to handle, %TU?
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_f5427310", "m1_failed_loyal"}, -- Of course not!
		{"@conversation/tatooine_privateer_tier3:s_a042a4cf", "m1_failed_something"}, -- Are you kidding? Nothing stops me.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_failed)

beissa_convo_m1_failed_loyal = ConvoScreen:new {
	id = "m1_failed_loyal",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_be1391ec", -- Maybe you're not loyal to Jabba after all.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_fa1878f7", "m1_retry_run_over"}, -- I AM. I just ran into a little problem.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_failed_loyal)

beissa_convo_m1_retry_run_over = ConvoScreen:new {
	id = "m1_retry_run_over",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c4f23e9b", -- I suggest you run OVER that little problem, if you get my drift. Get back out there.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1_retry_run_over)

beissa_convo_m1_failed_something = ConvoScreen:new {
	id = "m1_failed_something",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_fa60efdf", -- Looks like SOMETHING stopped you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_2feb7c0f", "m1_failed_plan"}, -- It's all part of my plan.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_failed_something)

beissa_convo_m1_failed_plan = ConvoScreen:new {
	id = "m1_failed_plan",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c1c1d8a5", -- Getting shot down is part of your plan? That's quite a plan.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8117e382", "m1_failed_genius"}, -- You just don't understand genius.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_failed_plan)

beissa_convo_m1_failed_genius = ConvoScreen:new {
	id = "m1_failed_genius",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_53b3094d", -- Ohhhh! I see! Well, genius, why don't you get back to your master plan?
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_85af2484", "m1_retry_shut_up"}, -- I will - as soon as you stop talking to me.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_failed_genius)

beissa_convo_m1_retry_shut_up = ConvoScreen:new {
	id = "m1_retry_shut_up",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f9a25cfc", -- Hey, I know when to shut up!
	stopConversation = "true",
	animation = "laugh_cackle",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1_retry_shut_up)

beissa_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_be822621", -- I didn't expect you back so soon.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_28a543ae", "m2_failed_why_here"}, -- I'm not done yet.
		{"@conversation/tatooine_privateer_tier3:s_581da545", "m2_failed_thin_ice"}, -- I didn't think those Witchbloods would be so tenacious.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_failed)

beissa_convo_m2_failed_why_here = ConvoScreen:new {
	id = "m2_failed_why_here",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_d87ceb8", -- Then why are you here?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4389abe9", "m2_retry_blast"}, -- I missed you.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_failed_why_here)

beissa_convo_m2_retry_blast = ConvoScreen:new {
	id = "m2_retry_blast",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f9cb6eac", -- Get out of here before I blast you myself!
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m2_retry_blast)

beissa_convo_m2_failed_thin_ice = ConvoScreen:new {
	id = "m2_failed_thin_ice",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_5a2f9ba", -- It's not an easy assignment. But then, you're still on thin ice with Jabba.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_63684ac5", "m2_retry_guess"}, -- I guess I better get back to work.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_failed_thin_ice)

beissa_convo_m2_retry_guess = ConvoScreen:new {
	id = "m2_retry_guess",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_af22b9b2", -- I guess so.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m2_retry_guess)

beissa_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_5723e13e", -- The Imperials are going to be VERY upset with you.
	stopConversation = "false",
	animation = "tap_foot",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_a4c5fb69", "m3_failed_century"}, -- No. They'll be fine. Because I'm going to finish the job.
		{"@conversation/tatooine_privateer_tier3:s_461e9b3f", "m3_retry_angry_jabba"}, -- You've got nothing to worry about.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_failed)

beissa_convo_m3_failed_century = ConvoScreen:new {
	id = "m3_failed_century",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_80b8ba1c", -- Sometime this century?
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_e9b69720", "m3_retry_hurry"}, -- That's the plan.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_failed_century)

beissa_convo_m3_retry_hurry = ConvoScreen:new {
	id = "m3_retry_hurry",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1c10e380", -- Hurry up.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m3_retry_hurry)

beissa_convo_m3_retry_angry_jabba = ConvoScreen:new {
	id = "m3_retry_angry_jabba",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_9b22b078", -- I'm not going to face an angry Jabba on account of you! Get the job done, or I'll find somebody who can.
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m3_retry_angry_jabba)

beissa_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c59afc3a", -- Oh hi!
	stopConversation = "false",
	animation = "offer_affection",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_fbe476b0", "m4_failed_feeling"}, -- Um...hi.
		{"@conversation/tatooine_privateer_tier3:s_601fa39", "m4_failed_know_what"}, -- I know, I know.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_failed)

beissa_convo_m4_failed_feeling = ConvoScreen:new {
	id = "m4_failed_feeling",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_86313707", -- How are you feeling? Good?
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_17c44740", "m4_retry_why"}, -- I guess.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_failed_feeling)

beissa_convo_m4_retry_why = ConvoScreen:new {
	id = "m4_retry_why",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_57bbda2a", -- WHY?! You shouldn't feel good! You should feel BAD! Because you haven't finished your job yet! DO IT!!
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m4_retry_why)

beissa_convo_m4_failed_know_what = ConvoScreen:new {
	id = "m4_failed_know_what",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1875ff4e", -- Know what?
	stopConversation = "false",
	animation = "listen",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8516d505", "m4_retry_do_it"}, -- I know that I haven't finished my job yet!
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_failed_know_what)

beissa_convo_m4_retry_do_it = ConvoScreen:new {
	id = "m4_retry_do_it",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_bb7d89de", -- THAT'S RIGHT! You haven't! So DO IT NOW!!!
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m4_retry_do_it)

beissa_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_ea4e584a", -- I salute you, %TU, for your brave and loyal service! Jabba is always generous with his employees. He'd like to offer you a training session. Isn't that nice? What would you like to learn?
	stopConversation = "false",
	animation = "salute1",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1_reward)

beissa_convo_m1_trained = ConvoScreen:new {
	id = "m1_trained",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e413d452", -- If you say so! Try to learn quickly, I have more exciting missions for you.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1_trained)

beissa_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_3f262d6b", -- The winner gets the toys. And you're the winner! Which skill would you like?
	stopConversation = "false",
	animation = "clap_rousing",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m2_reward)

beissa_convo_m2_trained = ConvoScreen:new {
	id = "m2_trained",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_999144d9", -- Tut, tut! No please? You should learn better manners. Come see me when you are ready. I'll have work for you.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m2_trained)

beissa_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_22f30f4c", -- The VIPs have all arrived safely. There is going to be a party at the Palace tonight. And what's a party without party favors? The first one's for you. Here! Pick a skill.
	stopConversation = "false",
	animation = "applause_excited",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m3_reward)

beissa_convo_m3_trained = ConvoScreen:new {
	id = "m3_trained",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_32376199", -- Now who's giving the orders?! Come see me sometime. I just love your company.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m3_trained)

beissa_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_bcb460ff", -- Who wants a skill?
	stopConversation = "false",
	animation = "listen",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m4_reward)

beissa_convo_m4_trained = ConvoScreen:new {
	id = "m4_trained",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f2593c16", -- Next time, say Please. I'm sure we'll meet again soon.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m4_trained)

beissa_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_da70d826", -- So YOU'RE the fool!
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9ea143d7", "m1_valarian"}, -- Have we met?
		{"@conversation/tatooine_privateer_tier3:s_ea84693", "m1_beissa"}, -- You're hurting my feelings.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_offer)

beissa_convo_m1_valarian = ConvoScreen:new {
	id = "m1_valarian",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_dea9aa2e", -- I know all about you. You were working with Lady Valarian. Going against Jabba! Are you crazy?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8ecd2ed0", "m1_friendly"}, -- I don't have to explain myself to you.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_valarian)

beissa_convo_m1_friendly = ConvoScreen:new {
	id = "m1_friendly",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e2e25101", -- You might want to be a little more friendly, %TU. I'm your contact for Jabba. You don't want me telling him what a sourpuss you are, do you?
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4c695dbd", "m1_why_back"}, -- No.
		{"@conversation/tatooine_privateer_tier3:s_40a19463", "m1_start_caring"}, -- I don't care what you tell him.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_friendly)

beissa_convo_m1_why_back = ConvoScreen:new {
	id = "m1_why_back",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e610029c", -- I didn't think so. Why did you come back, anyway?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_fccc4442", "m1_strange"}, -- Jabba invited me.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_why_back)

beissa_convo_m1_strange = ConvoScreen:new {
	id = "m1_strange",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_ef696d16", -- Doesn't that seem strange? You WERE working for the competition, after all.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_d6d5b88c", "m1_killed"}, -- It's a little strange, I guess.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_strange)

beissa_convo_m1_killed = ConvoScreen:new {
	id = "m1_killed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_eb9f64f0", -- Maybe he brought you back so that he could have you killed. Did you ever think of that?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_1110a04b", "m1_tongue"}, -- [no answer]
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_killed)

beissa_convo_m1_tongue = ConvoScreen:new {
	id = "m1_tongue",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_6a5f1bad", -- Well? Cat got your tongue?
	stopConversation = "false",
	animation = "listen",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4d5af593", "m1_some_use"}, -- Well...then I'd be dead by now, right?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_tongue)

beissa_convo_m1_some_use = ConvoScreen:new {
	id = "m1_some_use",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_48a3c712", -- Maybe! Or maybe he just has some use for you. And that's where I come in! I have a job for you.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_1adbadc4", "m1_loyalty"}, -- I'm ready.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_some_use)

beissa_convo_m1_loyalty = ConvoScreen:new {
	id = "m1_loyalty",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_15349399", -- Are you? I hope so. These aren't fluff jobs. You've got something to prove to Jabba. He expects to see loyalty.
	stopConversation = "false",
	animation = "stretch",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_438512f8", "m1_shipment"}, -- And loyalty is what he'll get.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_loyalty)

beissa_convo_m1_shipment = ConvoScreen:new {
	id = "m1_shipment",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_ff68e70a", -- Very nice. First, you'll recover a weapons shipment. Somebody stole it from Jabba. Can you believe the nerve?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4d69a104", "m1_clear_system"}, -- Shocking.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_shipment)

beissa_convo_m1_clear_system = ConvoScreen:new {
	id = "m1_clear_system",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_505c7932", -- After that, Jabba would like you to clear a few of his enemies out of this system. It's getting a little crowded.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_719a036e", "m1_old_friends"}, -- Who?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_clear_system)

beissa_convo_m1_old_friends = ConvoScreen:new {
	id = "m1_old_friends",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f5dff86f", -- Your old friends, Lady Valarian's thugs. You remember the Valarians, don't you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8c796cbf", "m1_perfect_person"}, -- Hey, why me? I'm friends with some of  those people.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_old_friends)

beissa_convo_m1_perfect_person = ConvoScreen:new {
	id = "m1_perfect_person",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f3d30738", -- Makes you the perfect person for the job, doesn't it? You know how they think. Remember, this is your big chance to show Jabba how loyal you are.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_bc375f79", "m1_ripe"}, -- Got it.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_perfect_person)

beissa_convo_m1_ripe = ConvoScreen:new {
	id = "m1_ripe",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_acbfc0cc", -- The Imperials and Rebels in this system are fighting like cats and dogs, which leaves the whole area ripe for  the picking. Play your cards right, and you could find yourself a very wealthy pilot.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_31960979", "m1_get_shipment"}, -- That's why I'm here.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_ripe)

beissa_convo_m1_get_shipment = ConvoScreen:new {
	id = "m1_get_shipment",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c6e0e27", -- First, get that weapons shipment. I'll transmit your other orders later.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_ad7db4d", "m1_accept"}, -- More orders from you! I can't wait.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_get_shipment)

beissa_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c9979b12", -- Me neither. Intercept that freighter in near Yavin. See you later, %TU.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1_accept)

beissa_convo_m1_start_caring = ConvoScreen:new {
	id = "m1_start_caring",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_40d4f979", -- You better START caring. I broker pilots for Jabba. My opinion carries a lot of weight with him.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_535a48bf", "m1_cross_me"}, -- Is that right?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_start_caring)

beissa_convo_m1_cross_me = ConvoScreen:new {
	id = "m1_cross_me",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_a75b6949", -- Don't believe me? Just cross me once. You'll find out how much pull I have. And remember. Jabba's rancors are ALWAYS hungry.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_79a6c35c", "m1_start_over"}, -- Oh, I'm scared.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_cross_me)

beissa_convo_m1_start_over = ConvoScreen:new {
	id = "m1_start_over",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_70969772", -- I can see that. Look, let's start over. YOU'RE with Jabba, and I'M with Jabba. That's all that matters right now. And I have a job for you.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5dc82348", "m1_todo_list"}, -- Good.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_start_over)

beissa_convo_m1_todo_list = ConvoScreen:new {
	id = "m1_todo_list",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_dc7d2ed4", -- OK. You've got a couple of items on your to-do list. First, you'll recover a weapons shipment. Somebody stole it from Jabba. Can you believe the nerve?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4d69a104", "m1_clear_system"}, -- Shocking.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_todo_list)

beissa_convo_m1_beissa = ConvoScreen:new {
	id = "m1_beissa",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f5f8f818", -- Excellent! Then we're getting off to the right start. I'm Beissa. I'll be your commanding officer today.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_de174124", "m1_my_orders"}, -- Nobody orders me around.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_beissa)

beissa_convo_m1_my_orders = ConvoScreen:new {
	id = "m1_my_orders",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_315f6f1a", -- You'll take MY orders, if you want to live! You're on thin ice with Jabba as it is.
	stopConversation = "false",
	animation = "threaten",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5413ef97", "m1_losing_team"}, -- Fine. Whatever.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_my_orders)

beissa_convo_m1_losing_team = ConvoScreen:new {
	id = "m1_losing_team",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_b9ca256f", -- Lady Valarian...you know how to choose the losing team. Don't you realize that Jabba is unstoppable?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_f20d43a6", "m1_big_plans"}, -- I've learned the error of my ways.
		{"@conversation/tatooine_privateer_tier3:s_54d1d117", "m1_best_friends"}, -- Valarians are good pilots. Good people, too.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_losing_team)

beissa_convo_m1_big_plans = ConvoScreen:new {
	id = "m1_big_plans",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1ad6a2e4", -- This system is ripe for the picking. And Jabba's got plans, big plans. You'd be wise to show your loyalty.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_c0b27fdb", "m1_shipment_nerve"}, -- What do I have to do?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_big_plans)

beissa_convo_m1_shipment_nerve = ConvoScreen:new {
	id = "m1_shipment_nerve",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_98504882", -- First, you'll recover a weapons shipment. Somebody had the nerve to steal it from Jabba. Can you believe the nerve?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4d69a104", "m1b_clear_system"}, -- Shocking.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_shipment_nerve)

beissa_convo_m1b_clear_system = ConvoScreen:new {
	id = "m1b_clear_system",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_505c7932", -- After that, Jabba would like you to clear a few of his enemies out of this system. It's getting a little crowded.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_719a036e", "m1b_old_friends"}, -- Who?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1b_clear_system)

beissa_convo_m1b_old_friends = ConvoScreen:new {
	id = "m1b_old_friends",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e17cca44", -- Your old friends, the Valarians. You remember them, don't you?
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_44285b8f", "m1b_perfect_person"}, -- I know those people.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1b_old_friends)

beissa_convo_m1b_perfect_person = ConvoScreen:new {
	id = "m1b_perfect_person",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f3d30738", -- Makes you the perfect person for the job, doesn't it? You know how they think. Remember, this is your big chance to show Jabba how loyal you are.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_bc375f79", "m1b_ripe"}, -- Got it.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1b_perfect_person)

beissa_convo_m1b_ripe = ConvoScreen:new {
	id = "m1b_ripe",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_acbfc0cc", -- The Imperials and Rebels in this system are fighting like cats and dogs, which leaves the whole area ripe for  the picking. Play your cards right, and you could find yourself a very wealthy pilot.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_31960979", "m1b_get_shipment"}, -- That's why I'm here.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1b_ripe)

beissa_convo_m1b_get_shipment = ConvoScreen:new {
	id = "m1b_get_shipment",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c6e0e27", -- First, get that weapons shipment. I'll transmit your other orders later.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_ad7db4d", "m1b_accept"}, -- More orders from you! I can't wait.
	}
}
beissa_convo_template:addScreen(beissa_convo_m1b_get_shipment)

beissa_convo_m1b_accept = ConvoScreen:new {
	id = "m1b_accept",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_5d667e15", -- Me neither! Go intercept that freighter in near Yavin. See you later, %TU.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m1b_accept)

beissa_convo_m1_best_friends = ConvoScreen:new {
	id = "m1_best_friends",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_3024ad9d", -- Oh yeah? Are they your best friends forever or something?
	stopConversation = "false",
	animation = "cover_ears_mocking",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_66ec8629", "m1_my_problem"}, -- Back off! What did I ever do to you?
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_best_friends)

beissa_convo_m1_my_problem = ConvoScreen:new {
	id = "m1_my_problem",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_589dbb5b", -- You showed up. THAT'S what you did. And now you're MY problem. I don't like problems. So you can just forget about those Valarians right now.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9532fb5c", "m1_shipment_nerve"}, -- [stay quiet]
	}
}
beissa_convo_template:addScreen(beissa_convo_m1_my_problem)

beissa_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_afa084aa", -- Those Valarians really put up a fight!
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8255ca09", "m2_jabba_thanks"}, -- I did my job.
		{"@conversation/tatooine_privateer_tier3:s_db509386", "m2_replacements"}, -- Was killing them really necessary?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_offer)

beissa_convo_m2_jabba_thanks = ConvoScreen:new {
	id = "m2_jabba_thanks",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_ef2cceae", -- Yes, you did. Jabba thanks you. I don't think Lady Valaria will want to see you again anytime soon.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_b984dc7a", "m2_impressed"}, -- Probably not.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_jabba_thanks)

beissa_convo_m2_impressed = ConvoScreen:new {
	id = "m2_impressed",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_bc7d4c35", -- Jabba's very impressed. In fact, he'd like me to let you in on his secret plans.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_6ec06027", "m2_confidential"}, -- What plans?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_impressed)

beissa_convo_m2_confidential = ConvoScreen:new {
	id = "m2_confidential",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_fcb2370", -- This is confidential information. You cannot share this, with anybody.
	stopConversation = "false",
	animation = "whisper",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_cd0dcead", "m2_up_to_me"}, -- Of course not.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_confidential)

beissa_convo_m2_up_to_me = ConvoScreen:new {
	id = "m2_up_to_me",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2e7619b1", -- If it were up to me, I wouldn't tell you anything!
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_61412ebf", "m2_dathomir"}, -- But it's not up to you. is it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_up_to_me)

beissa_convo_m2_dathomir = ConvoScreen:new {
	id = "m2_dathomir",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2a03f752", -- Watch your mouth. Now listen up. Jabba's decided that he's ready to move his operations into Dathomir. It's ripe. There's plenty of contraband in the area - and plenty of potential customers, too.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5a8556d4", "m2_juicy_deal"}, -- I believe it! Seems like a plan that's way overdue.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_dathomir)

beissa_convo_m2_juicy_deal = ConvoScreen:new {
	id = "m2_juicy_deal",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_bcad400e", -- And you can be a part of it, but only if you work with Jabba. This is going to be a juicy deal, and he's not going to let anybody outside of his organization have a taste.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_731189e6", "m2_witchblood"}, -- I get it! What do I have to do?
		{"@conversation/tatooine_privateer_tier3:s_3e7d2d37", "m2_inroads"}, -- But the Imperials are bound to hear about this.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_juicy_deal)

beissa_convo_m2_witchblood = ConvoScreen:new {
	id = "m2_witchblood",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_a8371342", -- For now, you need to get the Witchblood clan under control.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_edd73236", "m2_witchblood_who"}, -- What is the Witchblood clan?
		{"@conversation/tatooine_privateer_tier3:s_2675f275", "m2_force"}, -- Uh oh. Those witches are Force sensitive.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_witchblood)

beissa_convo_m2_witchblood_who = ConvoScreen:new {
	id = "m2_witchblood_who",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_221dc44d", -- You've never heard of them? They live on Dathomir. Been there for centuries. They have their own ideas about how things should work. AND they're Force sensitive.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_aea8a145", "m2_dangerous"}, -- Hm! Sounds dangerous.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_witchblood_who)

beissa_convo_m2_dangerous = ConvoScreen:new {
	id = "m2_dangerous",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_26c54c13", -- That's why Jabba assigned the mission to YOU!
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_e1ffebd7", "m2_respect"}, -- What am I supposed to do?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_dangerous)

beissa_convo_m2_respect = ConvoScreen:new {
	id = "m2_respect",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_7a9d89cc", -- These witches are obsessed with respect. They want everybody who comes to Dathomir to respect  them. Whatever! That is their weakness, as far as I'm concerned. I want you to find the clan's burial ground. It's an asteroid base somewhere nearby.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4f4e1c4e", "m2_soldiers"}, -- How do I find it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_respect)

beissa_convo_m2_soldiers = ConvoScreen:new {
	id = "m2_soldiers",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_81ed00dd", -- Their soldiers will know. I suggest you commandeer one of their ships and interrogate the captain. He'll tell you what you need to know.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_a7edf0be", "m2_visit"}, -- And once I've found the burial ground?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_soldiers)

beissa_convo_m2_visit = ConvoScreen:new {
	id = "m2_visit",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_66f326f", -- You're going to go there for a little visit.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_d59f78b0", "m2_desecrate"}, -- That's it?!
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_visit)

beissa_convo_m2_desecrate = ConvoScreen:new {
	id = "m2_desecrate",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_974272bf", -- That's EVERYTHING, as far as the witches are concerned. Non-believers like you will desecrate their sacred burial ground! They'll be entirely focused on you.
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_a609e8c", "m2_assassins"}, -- That might get me killed, but I don't understand how this helps Jabba.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_desecrate)

beissa_convo_m2_assassins = ConvoScreen:new {
	id = "m2_assassins",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2cb5d040", -- You know that Jabba has a whole cadre of assassins at his disposal.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_8be640b8", "m2_explosives"}, -- Sure.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_assassins)

beissa_convo_m2_explosives = ConvoScreen:new {
	id = "m2_explosives",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_50b517b8", -- While you're distracting the witches with your shenanigans, his assassins will move in and rig up explosives. We'll blast those crazy ladies sky-high.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5dd29234", "m2_accept"}, -- Ahh. I see.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_explosives)

beissa_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_ed7786ee", -- Yes, quite ingenious! Once the Witchbloods are under control, we can move forward with our plans. It all hinges on you. Get to your ship!
	stopConversation = "true",
	animation = "tap_head",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m2_accept)

beissa_convo_m2_force = ConvoScreen:new {
	id = "m2_force",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c4fdcde1", -- Don't tell me you believe in the Force! Please. You should just use their superstitious nature to your advantage. We have to get them under control, for Jabba's sake.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_d793b51", "m2_idea"}, -- You have an idea?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_force)

beissa_convo_m2_idea = ConvoScreen:new {
	id = "m2_idea",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_84c0df0e", -- Of course! You know how these witches are obsessed with respect. They want everybody who comes to Dathomir to respect  them. Whatever! That is their weakness, as far as I'm concerned. I want you to find the clan's burial ground. It's an asteroid base somewhere nearby.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4f4e1c4e", "m2_soldiers"}, -- How do I find it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_idea)

beissa_convo_m2_inroads = ConvoScreen:new {
	id = "m2_inroads",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e0114da3", -- Exactly. Which is why it's important that we start making inroads with them now. We'll scratch their back, and then they'll scratch ours. Or something like that. Anyway! Back to my point.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9b113074", "m2_point"}, -- Do you have a point?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_inroads)

beissa_convo_m2_point = ConvoScreen:new {
	id = "m2_point",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_5e53a3dd", -- Yes I do, thank you very much! Jabba's got a plan. It'll make our life easier, and it's a good way to earn points with the Imperials.
	stopConversation = "false",
	animation = "stamp_feet",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_1c8bddbb", "m2_under_control"}, -- What is it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_point)

beissa_convo_m2_under_control = ConvoScreen:new {
	id = "m2_under_control",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_5ba23093", -- You're going to get the Witchblood clan under control.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_edd73236", "m2_witchblood_who"}, -- What is the Witchblood clan?
		{"@conversation/tatooine_privateer_tier3:s_2675f275", "m2_force"}, -- Uh oh. Those witches are Force sensitive.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_under_control)

beissa_convo_m2_replacements = ConvoScreen:new {
	id = "m2_replacements",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_26790919", -- No. But it's nice to know that you'll do what you're told. Shamdon found some talented replacements for you! I wasn't sure you were going to make it back alive.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_d7c19f3f", "m2_welcome_back"}, -- Well here I am.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_replacements)

beissa_convo_m2_welcome_back = ConvoScreen:new {
	id = "m2_welcome_back",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2d9d7c64", -- Welcome back. I have an idea about how to use you. But first, tell me, can you work alongside the Imperials?
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9fc316af", "m2_force_reckoned"}, -- Sure - when I have to.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_welcome_back)

beissa_convo_m2_force_reckoned = ConvoScreen:new {
	id = "m2_force_reckoned",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_38f0bcdf", -- Hm. That's good to know, because Imperials are a force to be reckoned with in Dathomir.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_2bbcaa92", "m2b_dathomir"}, -- Dathomir?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2_force_reckoned)

beissa_convo_m2b_dathomir = ConvoScreen:new {
	id = "m2b_dathomir",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_7943df8d", -- Jabba's decided that he's ready to move his operations into Dathomir. It's ripe. There's plenty of contraband in the area - and plenty of potential customers, too.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5a8556d4", "m2b_juicy_deal"}, -- I believe it! Seems like a plan that's way overdue.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2b_dathomir)

beissa_convo_m2b_juicy_deal = ConvoScreen:new {
	id = "m2b_juicy_deal",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_bcad400e", -- And you can be a part of it, but only if you work with Jabba. This is going to be a juicy deal, and he's not going to let anybody outside of his organization have a taste.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_731189e6", "m2b_later_imperials"}, -- I get it! What do I have to do?
	}
}
beissa_convo_template:addScreen(beissa_convo_m2b_juicy_deal)

beissa_convo_m2b_later_imperials = ConvoScreen:new {
	id = "m2b_later_imperials",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_6d22c58", -- Later on, I'll need your help with the Imperials. For now, you need to get the Witchblood clan under control.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_bf01df79", "m2_witchblood_who"}, -- Who is the Witchblood clan?
		{"@conversation/tatooine_privateer_tier3:s_2675f275", "m2_force"}, -- Uh oh. Those witches are Force sensitive.
	}
}
beissa_convo_template:addScreen(beissa_convo_m2b_later_imperials)

beissa_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2a335ce3", -- Here comes a special pilot. Ready for a special mission?
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_52917b0d", "m3_imperials"}, -- Of course.
		{"@conversation/tatooine_privateer_tier3:s_1b6a5a1c", "m3_inquisitive"}, -- I'm ready to find out more about this Dathomir situation.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_offer)

beissa_convo_m3_imperials = ConvoScreen:new {
	id = "m3_imperials",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_509249db", -- I want to know if you can work with Imperials?
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_b55e3f14", "m3_goon"}, -- I can work with anybody, if the money's right.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_imperials)

beissa_convo_m3_goon = ConvoScreen:new {
	id = "m3_goon",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1edbaf3a", -- Obviously you can, you traitorous Valarian-loving goon.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_ecbb4e43", "m3_gifts"}, -- Oh whatever.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_goon)

beissa_convo_m3_gifts = ConvoScreen:new {
	id = "m3_gifts",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_d60918d0", -- Here is your mission. I want you to deliver a few gifts to Imperial officers operating in this system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_72318c63", "m3_kind_of_gifts"}, -- What kind of gifts?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_gifts)

beissa_convo_m3_kind_of_gifts = ConvoScreen:new {
	id = "m3_kind_of_gifts",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_dcea0b58", -- The kind of gifts any Imperial would accept. Data on other factions. Insider information. Secret passwords. You know. The good stuff.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_551c4bc7", "m3_genius"}, -- You're right. They'll like it.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_kind_of_gifts)

beissa_convo_m3_genius = ConvoScreen:new {
	id = "m3_genius",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_4b6d65c6", -- I can't take any credit. This was all Jabba's idea. He's a genius.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_c33fad75", "m3_party"}, -- It's always good to make friends with the Imperials, but is there some reason behind the timing?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_genius)

beissa_convo_m3_party = ConvoScreen:new {
	id = "m3_party",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_3b45cd54", -- Of course. Jabba's getting ready to throw a little party.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_651adfc1", "m3_big_names"}, -- What kind of party?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_party)

beissa_convo_m3_big_names = ConvoScreen:new {
	id = "m3_big_names",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_859cab0", -- The kind of party people like YOU don't get invited to. All the big names will be there. Including some of Jabba's biggest competitors.
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_841d27db", "m3_enemies_closer"}, -- Why?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_big_names)

beissa_convo_m3_enemies_closer = ConvoScreen:new {
	id = "m3_enemies_closer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_38c86018", -- You know what they say. Keep your friends close, and your enemies closer. Jabba's getting ready to make a big move. He's got to know what's going on out there.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_6ce4e96f", "m3_uploaded"}, -- Right.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_enemies_closer)

beissa_convo_m3_uploaded = ConvoScreen:new {
	id = "m3_uploaded",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_c1730a04", -- We've uploaded the Imperials' coordinates to your ship's system. And we've uploaded the data as well. They're password-protected. We wouldn't want you taking those - gifts - for yourself.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_80bfc2af", "m3_accept"}, -- I wouldn't think of it!
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_uploaded)

beissa_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_4050c6fc", -- Of course not. Have fun!
	stopConversation = "true",
	animation = "wave1",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m3_accept)

beissa_convo_m3_inquisitive = ConvoScreen:new {
	id = "m3_inquisitive",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_29456ce7", -- Such an inquisitive mind! Young pilots like you shouldn't ask so many questions.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_255518bb", "m3_gold_mine"}, -- Don't be ridiculous. Tell me what's going on.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_inquisitive)

beissa_convo_m3_gold_mine = ConvoScreen:new {
	id = "m3_gold_mine",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e480eda0", -- What's there to tell? Dathomir's a gold mine, for the right sort of entrepreneur. We just need to establish good relationships with the neighbors.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9dd2c52f", "m3_define_good"}, -- Like we did with the witches of Dathomir?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_gold_mine)

beissa_convo_m3_define_good = ConvoScreen:new {
	id = "m3_define_good",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_95ff4e4", -- Well...it all depends on how you define Good. Every situation is different. Take the Imperial forces, for example. We need to treat them with the utmost respect.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_4edf9084", "m3_blast_us"}, -- Or else they'll blast you out of the galaxy.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_define_good)

beissa_convo_m3_blast_us = ConvoScreen:new {
	id = "m3_blast_us",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_36d47f1a", -- You mean they'll blast US. We're in this together now, remember?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_73e3d4ef", "m3b_imperials"}, -- How could I forget?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3_blast_us)

beissa_convo_m3b_imperials = ConvoScreen:new {
	id = "m3b_imperials",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_509249db", -- I want to know if you can work with Imperials?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_b55e3f14", "m3b_gifts"}, -- I can work with anybody, if the money's right.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3b_imperials)

beissa_convo_m3b_gifts = ConvoScreen:new {
	id = "m3b_gifts",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_cb13d341", -- So here is your mission. I want you to deliver a few gifts to Imperial officers operating in this system.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_72318c63", "m3b_kind_of_gifts"}, -- What kind of gifts?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3b_gifts)

beissa_convo_m3b_kind_of_gifts = ConvoScreen:new {
	id = "m3b_kind_of_gifts",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_3c1e7fc0", -- The kind of gifts any Imperial would want. Data on other factions. Insider information. Secret passwords. The good stuff.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_841d27db", "m3b_enemies_closer"}, -- Why?
	}
}
beissa_convo_template:addScreen(beissa_convo_m3b_kind_of_gifts)

beissa_convo_m3b_enemies_closer = ConvoScreen:new {
	id = "m3b_enemies_closer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_38c86018", -- You know what they say. Keep your friends close, and your enemies closer. Jabba's getting ready to make a big move. He's got to know what's going on out there.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_5494c458", "m3_uploaded"}, -- Right.
	}
}
beissa_convo_template:addScreen(beissa_convo_m3b_enemies_closer)

beissa_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f390de3b", -- How did you like Jabba's party guests?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_e2b3bd3d", "m4_disgusting"}, -- They were almost as disgusting as Jabba.
		{"@conversation/tatooine_privateer_tier3:s_9ef8ae7d", "m4_testy"}, -- Who? I've already forgotten them. Give me a mission.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_offer)

beissa_convo_m4_disgusting = ConvoScreen:new {
	id = "m4_disgusting",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_2795978a", -- Ha! Well, disgusting they may be, but they're useful, too. Jabba's laying the foundation for his Dathomir operation.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_6713da6c", "m4_friends"}, -- Did he announce his plans?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_disgusting)

beissa_convo_m4_friends = ConvoScreen:new {
	id = "m4_friends",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_7f124363", -- Not in so many words. But he made sure that he knew who his friends were, if you know what I mean.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_9754c9cf", "m4_respect"}, -- No. I don't know what you mean.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_friends)

beissa_convo_m4_respect = ConvoScreen:new {
	id = "m4_respect",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_821a5372", -- Well, that's why Jabba's a syndicate head, and you're just a lowly pilot. You don't have to like Jabba, but you have to respect him. He knows how to get things done.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_58081a79", "m4_good_news"}, -- Uh huh. Got a mission for me?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_respect)

beissa_convo_m4_good_news = ConvoScreen:new {
	id = "m4_good_news",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_99b1ec0", -- Of course! We don't pay you to stand around and look pretty. I have good news and bad news. The good news is, business is booming.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_dd19988e", "m4_bad_news"}, -- And the bad news?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_good_news)

beissa_convo_m4_bad_news = ConvoScreen:new {
	id = "m4_bad_news",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_83c2b64", -- The bad news is that a new clan is trying to make inroads in this system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_800d8ca1", "m4_rancor_clan"}, -- Who is it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_bad_news)

beissa_convo_m4_rancor_clan = ConvoScreen:new {
	id = "m4_rancor_clan",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f0fbdf16", -- That's the REALLY bad news - we don't know. Nobody's been able to identify them yet. They call themselves the Rancor Clan.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_272a2246", "m4_silly_name"}, -- They've named themselves after rancors? Ha! Those idiotic creatures can't even brush their own teeth, much less fly a spaceship.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_rancor_clan)

beissa_convo_m4_silly_name = ConvoScreen:new {
	id = "m4_silly_name",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_65ef9330", -- The name is silly; the threat is not. These are aggressive, dangerous fighters. I wonder why they've taken an interest in this area?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_98b1ccd4", "m4_talking"}, -- No idea.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_silly_name)

beissa_convo_m4_talking = ConvoScreen:new {
	id = "m4_talking",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_b3b84a9f", -- Oh really? Have you been talking to your friends about Dathomir?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_d33e2776", "m4_lying"}, -- Of course not! I have no friends.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_talking)

beissa_convo_m4_lying = ConvoScreen:new {
	id = "m4_lying",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1e9e6433", -- If I find out you're lying to me, I'll kill you myself. And I'll do it slowly.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_1e18c922", "m4_patrol"}, -- I haven't said a word!
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_lying)

beissa_convo_m4_patrol = ConvoScreen:new {
	id = "m4_patrol",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_55fa5d7a", -- Well, regardless of the reason, the Rancor Clan is here. And they need to go. This is your problem, as of now. I want you to get back up there and patrol the area. If you find rancors, engage and destroy. Got it?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_bc375f79", "m4_kicker"}, -- Got it.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_patrol)

beissa_convo_m4_kicker = ConvoScreen:new {
	id = "m4_kicker",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_a92435e7", -- The kicker is that Jabba is installing a vigo on Dathomir. He'll be here soon.  We need to eliminate this problem before this guy arrives. If he decides that we're doing a bad job, he will DEFINITELY replace us. And do you know what replace means?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_ea9e3ad2", "m4_accept"}, -- I can guess.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_kicker)

beissa_convo_m4_accept = ConvoScreen:new {
	id = "m4_accept",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_6fe71f0c", -- Get out of here.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_m4_accept)

beissa_convo_m4_testy = ConvoScreen:new {
	id = "m4_testy",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_da8f9cc9", -- So testy! What did you have for breakfast? You need to work on the subtle art of conversation.
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_2c4b729", "m4b_good_news"}, -- You're boring me.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4_testy)

beissa_convo_m4b_good_news = ConvoScreen:new {
	id = "m4b_good_news",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_b834e090", -- All right, all right! You don't need to take my head off. I have good news and bad news. The good news is, business is booming.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_dd19988e", "m4b_bad_news"}, -- And the bad news?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4b_good_news)

beissa_convo_m4b_bad_news = ConvoScreen:new {
	id = "m4b_bad_news",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_83c2b64", -- The bad news is that a new clan is trying to make inroads in this system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_800d8ca1", "m4b_rancor_clan"}, -- Who is it?
	}
}
beissa_convo_template:addScreen(beissa_convo_m4b_bad_news)

beissa_convo_m4b_rancor_clan = ConvoScreen:new {
	id = "m4b_rancor_clan",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_f0fbdf16", -- That's the REALLY bad news - we don't know. Nobody's been able to identify them yet. They call themselves the Rancor Clan.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_bee781d7", "m4b_very"}, -- Strange!
	}
}
beissa_convo_template:addScreen(beissa_convo_m4b_rancor_clan)

beissa_convo_m4b_very = ConvoScreen:new {
	id = "m4b_very",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_e4dc5d6", -- Very.  These are aggressive, dangerous fighters. I wonder why they've taken an interest in this area?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_98b1ccd4", "m4_talking"}, -- No idea.
	}
}
beissa_convo_template:addScreen(beissa_convo_m4b_very)

beissa_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_82751e5b", -- Guess what, %TU. Jabba's sending you somewhere else.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_cc1cb635", "done_never_together"}, -- Does that mean we aren't going to work together any more?
		{"@conversation/tatooine_privateer_tier3:s_249fa88e", "done_sarcastic"}, -- Oh no!
	}
}
beissa_convo_template:addScreen(beissa_convo_tier_done)

beissa_convo_done_never_together = ConvoScreen:new {
	id = "done_never_together",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_1360f736", -- We never DID work together. YOU worked for ME.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_741f40ea", "done_wont_miss"}, -- Hm! You know what? I don't think I'll miss you too much.
	}
}
beissa_convo_template:addScreen(beissa_convo_done_never_together)

beissa_convo_done_wont_miss = ConvoScreen:new {
	id = "done_wont_miss",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_b3b64ad2", -- I won't miss you either. Jabba's done with you for now, so go back to where you came from.  I think Talon Karrde is expecting you at the Mos Eisley cantina.  And in the future, if you see me coming, do me a favor and get out of my way!
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_done_wont_miss)

beissa_convo_done_sarcastic = ConvoScreen:new {
	id = "done_sarcastic",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_6553e1d6", -- Are you being sarcastic?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier3:s_1248fc74", "done_strange"}, -- Honestly, I'm not sure.
	}
}
beissa_convo_template:addScreen(beissa_convo_done_sarcastic)

beissa_convo_done_strange = ConvoScreen:new {
	id = "done_strange",
	leftDialog = "@conversation/tatooine_privateer_tier3:s_4c6b6df2", -- You're a strange one. Jabba's finished with you for now, and Talon Karrde is waiting for you at the Mos Eisley cantina.  See you later.
	stopConversation = "true",
	options = {}
}
beissa_convo_template:addScreen(beissa_convo_done_strange)

addConversationTemplate("beissa_convo_template", beissa_convo_template)
