-- Shamdon Kree (Smuggler tier 2) conversation screens; ported from SWG-Source tatooine_privateer_trainer_shamdon (STF conversation/tatooine_privateer_trainer_shamdon). Handler: shamdonKreeConvoHandler.lua (feature smuggler-tier2-shamdon).
shamdon_kree_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "shamdonKreeConvoHandler",
	screens = {}
}

not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_dab97824", -- I don't know who you are, but you don't look like someone I want to talk to.
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(not_pilot);

off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_36bdb4df", -- I don't know why you're talking to me... do I know you? Why are you here?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c1ff5062", "off_track_refused"}, -- I'm looking for a mission. Do you have any?
	}
}
shamdon_kree_convo_template:addScreen(off_track);

off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_9839c24f", -- Eh... I may be making a mistake, but you've got that look about you... like you might make a good smuggler one day. Yes, I do have some duty missions. What do you think you can handle?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c631f8da", "duty_escort"}, -- Escort Transports in Lok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_6ff30da7", "duty_recovery"}, -- Hijack transports in Dantooine.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_93ba78e7", "duty_destroy"}, -- Kill Black Sun Pirates in Yavin.
	}
}
shamdon_kree_convo_template:addScreen(off_track_duties);

off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_739845d3", -- No... especially not for the likes of you. Go find your own contacts.
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(off_track_refused);

stranger = ConvoScreen:new {
	id = "stranger",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_b4790825", -- I don't know why you're talking to me... do I know you?
	animation = "wave_on_dismissing",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_aed52b48", "talon_only"}, -- Yes, I'm here to do a job for you.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d01d0154", "never_mind"}, -- No, never mind.
	}
}
shamdon_kree_convo_template:addScreen(stranger);

never_mind = ConvoScreen:new {
	id = "never_mind",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_c261cfae", -- No problem.
	animation = "wave2",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(never_mind);

talon_only = ConvoScreen:new {
	id = "talon_only",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_3c3002fc", -- Oh, I don't think so. The only people doing jobs for me are from Talon Karrde's outfit. And if Talon sent you, you'd have something for me.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_32965dab", "talon_who_male"}, -- Who is Talon Karrde?
		{"@conversation/tatooine_privateer_trainer_shamdon:s_bb27779e", "talon_what"}, -- What would I have?
	}
}
shamdon_kree_convo_template:addScreen(talon_only);

talon_who_male = ConvoScreen:new {
	id = "talon_who_male",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_9939e2d7", -- A smart-looking boy like you ought to be able to figure that on your own. You go on now and interrogate someone else, alright?
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(talon_who_male);

talon_who_female = ConvoScreen:new {
	id = "talon_who_female",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_90a85d36", -- A smart-looking girl like you ought to be able to figure that on your own. You go on now and interrogate someone else, alright?
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(talon_who_female);

talon_what = ConvoScreen:new {
	id = "talon_what",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_2118caa8", -- Ha ha! Well that's none of your business now, is it? You go on now and find something useful to do.
	animation = "laugh_titter",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(talon_what);

package_delivery = ConvoScreen:new {
	id = "package",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_8be95ab4", -- What's this?
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d14c381d", "trans_paid_male"}, -- I brought this from Lok.
	}
}
shamdon_kree_convo_template:addScreen(package_delivery);

trans_paid_male = ConvoScreen:new {
	id = "trans_paid_male",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_2e6c7754", -- Oh you must be Talon Karrde's new man. Thanks for this. Here's the money Talon and I agreed upon.
	animation = "greet",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c4682ea6", "more_jobs"}, -- Thanks!
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1a3dce13", "more_jobs"}, -- This isn't much money.
	}
}
shamdon_kree_convo_template:addScreen(trans_paid_male);

trans_paid_female = ConvoScreen:new {
	id = "trans_paid_female",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_c562c4fb", -- Oh, I guess you're the new woman working for Talon Karrde's outfit. Here's the payment Talon and I agreed upon.
	animation = "greet",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c4682ea6", "more_jobs"}, -- Thanks!
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1a3dce13", "more_jobs"}, -- This isn't much money.
	}
}
shamdon_kree_convo_template:addScreen(trans_paid_female);

more_jobs = ConvoScreen:new {
	id = "more_jobs",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_69e17dd2", -- I'm sure I'll have more for you if you're up to doing some more jobs... or say, if you'd like to flip for that. What do you say, double or nothing?
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(more_jobs);

busy = ConvoScreen:new {
	id = "busy",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_98adf66d", -- I can see you're busy. Come talk to me when you've got some time. I can always use your services.
	animation = "shake_head_no",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(busy);

m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_3b48f08", -- That Canyon Corsair leader needs to be taken out! He's responsible for our lost transports in the Lok system. Go defeat him!
	animation = "pound_fist_palm",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m1_retry);

m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_ae1a4b87", -- Our contacts on Dantooine are getting nervous. You have to destroy that Imperial patrol before our customers decide to take their business elsewhere. Now get out there are finish the job!
	animation = "point_away",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m2_retry);

m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_a24306df", -- There's no way we're going to allow the Black Sun to move in on our operations! Get back to the Yavin system and destroy that ship before it's too late!
	animation = "pound_fist_palm",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m3_retry);

m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_e4c0ecd", -- We can't afford any more mistakes! It's only a matter of time before Jabba figures out you're working for me. Now go escort our transport so it can make it out of the system!
	animation = "shake_head_disgust",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m4_retry);

m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d9b1bd09", -- Nice work with that Corsair leader. Maybe that'll teach those guys to steer clear of our transports. I've got your payment right here.
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_bc000879", "m1_reward_nothing"}, -- It was nothing.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_34e4d30", "m1_reward_doubt"}, -- I doubt it!
	}
}
shamdon_kree_convo_template:addScreen(m1_reward);

m1_reward_nothing = ConvoScreen:new {
	id = "m1_reward_nothing",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_f1bbe36f", -- Don't get too full of yourself. It's a dangerous world, you know? Ready for another assignment?
	animation = "slow_down",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back"}, -- No thanks.
	}
}
shamdon_kree_convo_template:addScreen(m1_reward_nothing);

m1_reward_doubt = ConvoScreen:new {
	id = "m1_reward_doubt",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_63227fe4", -- You're probably right. Ready for another assignment?
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back"}, -- No thanks.
	}
}
shamdon_kree_convo_template:addScreen(m1_reward_doubt);

m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_f520ab35", -- How did it go?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_4362ba26", "m2_paid"}, -- The Imperial Pilot has been neutralized.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_43f63a81", "m2_paid"}, -- I killed the Imperial.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_9f5f269", "m2_paid"}, -- No problem
	}
}
shamdon_kree_convo_template:addScreen(m2_reward);

m2_paid = ConvoScreen:new {
	id = "m2_paid",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_dffe951a", -- Fantastic! %NU, I knew I could count on you. Ready for another assignment?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back"}, -- No thanks.
	}
}
shamdon_kree_convo_template:addScreen(m2_paid);

m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5b1bed8b", -- Well?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1fe46aff", "m3_eliminate"}, -- Well what?
	}
}
shamdon_kree_convo_template:addScreen(m3_reward);

m3_eliminate = ConvoScreen:new {
	id = "m3_eliminate",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_1b1dd9b4", -- What do you think? Did you eliminate that pirate?
	animation = "smack_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8179979d", "m3_paid_naturally"}, -- Naturally.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d70dba34", "m3_paid_yes"}, -- Yes.
	}
}
shamdon_kree_convo_template:addScreen(m3_eliminate);

m3_paid_naturally = ConvoScreen:new {
	id = "m3_paid_naturally",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_1f4922ce", -- %NU, you'd make an excellent pirate. Ready for another assignment?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back_soon"}, -- No thanks.
	}
}
shamdon_kree_convo_template:addScreen(m3_paid_naturally);

m3_paid_yes = ConvoScreen:new {
	id = "m3_paid_yes",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_57adb96", -- Who knew you'd make such a good pirate, %NU? Ready for another assignment?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_d6695e83", "come_back_soon"}, -- No thanks.
	}
}
shamdon_kree_convo_template:addScreen(m3_paid_yes);

m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_7cb248ee", -- Did it go alright? Any problems?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_eca7c053", "m4_paid_fine"}, -- No problem at all.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_766563c7", "m4_paid_handle"}, -- Nothing I couldn't handle.
	}
}
shamdon_kree_convo_template:addScreen(m4_reward);

m4_paid_fine = ConvoScreen:new {
	id = "m4_paid_fine",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_2b2c40c1", -- I knew you could handle it. Ready for another assignment?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_360d8728", "come_back"}, -- No thanks
	}
}
shamdon_kree_convo_template:addScreen(m4_paid_fine);

m4_paid_handle = ConvoScreen:new {
	id = "m4_paid_handle",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d4079379", -- That's what makes you such a good pilot. Ready for another assignment?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8be640b8", "training"}, -- Sure.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_895d093", "duty_menu"}, -- Ok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_360d8728", "come_back"}, -- No thanks
	}
}
shamdon_kree_convo_template:addScreen(m4_paid_handle);

come_back = ConvoScreen:new {
	id = "come_back",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5ad49b89", -- Alright. Well come see me when you're ready.
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(come_back);

come_back_soon = ConvoScreen:new {
	id = "come_back_soon",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_66b1a06f", -- Alright. Come see me when you're ready.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(come_back_soon);

duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_acda8fe", -- What are you interested in?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c631f8da", "duty_escort"}, -- Escort Transports in Lok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_6ff30da7", "duty_recovery"}, -- Hijack transports in Dantooine.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_93ba78e7", "duty_destroy"}, -- Kill Black Sun Pirates in Yavin.
	}
}
shamdon_kree_convo_template:addScreen(duty_menu);

ready_mission = ConvoScreen:new {
	id = "ready_mission",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d6924ee9", -- Welcome back, %NU. Are you ready to get back to work?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_5c522568", "m1_brief"}, -- Yes, of course.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_f3d46f0b", "not_yet"}, -- No, not quite yet.
	}
}
shamdon_kree_convo_template:addScreen(ready_mission);

not_yet = ConvoScreen:new {
	id = "not_yet",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_bce510d4", -- Alright, but you'd better be ready soon. Hurry back.
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(not_yet);

m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_89555084", -- Excellent. I want you to head Lok and destroy a Canyon Corsair Behemoth. This pirate's been trying to block our shipments to Nym... and we just can't have that.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m1_brief);

m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_666ebdc8", -- Excellent. Our shipments to Dantooine have been blocked by a surprisingly competent Imperial patrol. I need you to go destroy it so we can resume operations there.
	animation = "pound_fist_palm",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m2_brief);

m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d70e2c34", -- Excellent. This is a special assignment. The Black Sun pirates are trying to move in on our territory. They been blocking our operations in the Yavin system. I want you to go there and destroy the Black Sun leader. Once he's out of the picture we'll own smuggling there.
	animation = "explain",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m3_brief);

m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_a07f4bc4", -- Excellent. This is a very special assignment! Jabba's pirates have been cracking down on our smuggling operations in Tatooine and we're having problems getting shipments out of the system. I want you to escort one of our transports out of the system... and watch out for the Hutts!
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(m4_brief);

bad_news = ConvoScreen:new {
	id = "bad_news",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_650a0c35", -- Bad news, %NU.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1c8bddbb", "jabba_thug"}, -- What is it?
	}
}
shamdon_kree_convo_template:addScreen(bad_news);

bad_news_reply = ConvoScreen:new {
	id = "bad_news_reply",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_c29ec5c2", -- Well, we've got some bad news, %NU.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1c8bddbb", "jabba_thug"}, -- What is it?
	}
}
shamdon_kree_convo_template:addScreen(bad_news_reply);

jabba_thug = ConvoScreen:new {
	id = "jabba_thug",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_9b0ac27a", -- Jabba sent a thug over to have a little 'talk' with Talon Karrde. He's a little spooked, I think.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_ff5b4126", "competitors"}, -- Jabba? Why?
		{"@conversation/tatooine_privateer_trainer_shamdon:s_71a8cc01", "death_mark"}, -- Why is Karrde spooked?
	}
}
shamdon_kree_convo_template:addScreen(jabba_thug);

competitors = ConvoScreen:new {
	id = "competitors",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_2640d39c", -- You know Lady Valarian and Jabba are... 'competitors'... so to speak. Right?
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_114c29a9", "too_successful"}, -- So?
	}
}
shamdon_kree_convo_template:addScreen(competitors);

death_mark = ConvoScreen:new {
	id = "death_mark",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_6e21ce1c", -- Talon thinks Jabba's going to put a death-mark on him... because of you!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8a24761e", "competitors"}, -- Me? What did I do?
	}
}
shamdon_kree_convo_template:addScreen(death_mark);

too_successful = ConvoScreen:new {
	id = "too_successful",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_75d43a2b", -- Well apparently you've been just a little TOO successful, working for Lady Valarian. Jabba wants Talon Karrde to work for him, and only for him.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_725573da", "see_karrde"}, -- What now?
		{"@conversation/tatooine_privateer_trainer_shamdon:s_474f9205", "naive"}, -- Who cares what Jabba wants?
	}
}
shamdon_kree_convo_template:addScreen(too_successful);

see_karrde = ConvoScreen:new {
	id = "see_karrde",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_52e7e5e", -- You'd better go talk to Talon Karrde. I have a feeling he's made some promises to Jabba on your behalf.
	animation = "shrug_hands",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(see_karrde);

naive = ConvoScreen:new {
	id = "naive",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5f96d75a", -- %NU, don't be naive. This is Tatooine. Everyone cares what Jabba wants. More importantly, Talon Karrde cares, so you better care too.
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_725573da", "see_karrde"}, -- What now?
	}
}
shamdon_kree_convo_template:addScreen(naive);

training = ConvoScreen:new {
	id = "training",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_383435", -- You've done an excellent job for me, %NU. I can see that you are ready for more training. What are you interested in learning?
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_45b71b4d", "trained_starships"}, -- I am interested in advanced fighters.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_197f4f94", "trained_weapons"}, -- I am interested in intermediate starship component use.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_8f5942fa", "trained_procedures"}, -- I am interested in starship defense training.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_eff66f4d", "trained_droid"}, -- I am interested in reactor engineering algorithms.
	}
}
shamdon_kree_convo_template:addScreen(training);

trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_dfd3392c", -- Good choice. Your new abilities will come in handy soon. Are you ready for your next assignment?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_36a4e374", "m1_brief"}, -- Yes, I am.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_da9a29e9", "not_yet"}, -- No, not yet.
	}
}
shamdon_kree_convo_template:addScreen(trained_starships);

trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_2fef6afd", -- Good choice. No doubt that will come in handy soon. Are you ready for your next assignment?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_36a4e374", "m3_brief"}, -- Yes, I am.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_da9a29e9", "not_yet"}, -- No, not yet.
	}
}
shamdon_kree_convo_template:addScreen(trained_weapons);

trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d5a42663", -- Good choice. Are you ready for your next assignment?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_36a4e374", "m4_brief"}, -- Yes, I am.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_da9a29e9", "not_yet"}, -- No, not yet.
	}
}
shamdon_kree_convo_template:addScreen(trained_procedures);

trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_d5a42663", -- Good choice. Are you ready for your next assignment?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_36a4e374", "m2_brief"}, -- Yes, I am.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_da9a29e9", "not_yet"}, -- No, not yet.
	}
}
shamdon_kree_convo_template:addScreen(trained_droid);

work = ConvoScreen:new {
	id = "work",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5d262b71", -- You are here for work now, yes?
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_f4b9423e", "duty_offer"}, -- Yes, I am
		{"@conversation/tatooine_privateer_trainer_shamdon:s_1aaeed53", "work_no"}, -- No I am not.
	}
}
shamdon_kree_convo_template:addScreen(work);

work_no = ConvoScreen:new {
	id = "work_no",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_cbe97427", -- Then stop bothering me. Can't you see I'm busy?
	animation = "point_to_self",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(work_no);

duty_offer = ConvoScreen:new {
	id = "duty_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5af9448", -- Good. There are a number of things you can do for me. What can you do for me right now?
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_shamdon:s_c631f8da", "duty_escort"}, -- Escort Transports in Lok.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_6ff30da7", "duty_recovery"}, -- Hijack transports in Dantooine.
		{"@conversation/tatooine_privateer_trainer_shamdon:s_93ba78e7", "duty_destroy"}, -- Kill Black Sun Pirates in Yavin.
	}
}
shamdon_kree_convo_template:addScreen(duty_offer);

duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_5423b2d0", -- Right! Help our shipments get through to Lok without being hijacked by those Canyon Corsairs.
	animation = "point_down",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(duty_escort);

duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_9eb35e93", -- Good thinking. The Imperial patrols there are making it difficult to operate, but if we can cut down on the amount of legal traffic, demand for our services will soar!
	animation = "point_up",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(duty_recovery);

duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/tatooine_privateer_trainer_shamdon:s_9fa5f777", -- Excellent! They've been moving in on our operations for just a little too long. Go to the Yavin system and wipe them out!
	animation = "clap_rousing",
	stopConversation = "true",
	options = {}
}
shamdon_kree_convo_template:addScreen(duty_destroy);

addConversationTemplate("shamdon_kree_convo_template", shamdon_kree_convo_template)
