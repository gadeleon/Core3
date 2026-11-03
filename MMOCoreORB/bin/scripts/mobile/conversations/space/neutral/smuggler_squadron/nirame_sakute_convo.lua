-- Nirame Sakute (Smuggler tier 4, Dathomir Trade Outpost) conversation screens; ported from SWG-Source tatooine_privateer_tier4 (STF conversation/tatooine_privateer_tier4). Handler: nirameSakuteConvoHandler.lua (feature smuggler-tier4-nirame).
nirame_sakute_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "nirameSakuteConvoHandler",
	screens = {}
}

nirame_sakute_convo_not_neutral = ConvoScreen:new {
	id = "not_neutral",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_30a9191e", -- Hey! I've got no time for bums like you.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_not_neutral)

nirame_sakute_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_13031eaa", -- What brings a pilot like you out this way? Surely you didn't come just to say hello.
	stopConversation = "false",
	animation = "rub_belly",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_c1ff5062", "off_track_duties"}, -- I'm looking for a mission. Do you have any?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_off_track)

nirame_sakute_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e9cabb66", -- Eh, you're in luck. Normally I would send you packing, but I do actually have a couple of duty missions . Do you want me to give you a briefing?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_c82e9a2f", "duty_explain"}, -- Yes, please.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_off_track_duties)

nirame_sakute_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_324779f6", -- Do I have any missions? Yes. Do I think you can handle them? No. Why don't you go find your mama and quit bothering me.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_off_track_refused)

nirame_sakute_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_fabf48da", -- Hey! Beissa's looking for you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_e86f1062", "not_ready_know"}, -- How do you know?
		{"@conversation/tatooine_privateer_tier4:s_5206ea9b", "not_ready_business"}, -- Mind your own business.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_not_ready)

nirame_sakute_convo_not_ready_know = ConvoScreen:new {
	id = "not_ready_know",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_555c668c", -- I know all! Get your backside over to Jabba's Palace.
	stopConversation = "true",
	animation = "tap_head",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_not_ready_know)

nirame_sakute_convo_not_ready_business = ConvoScreen:new {
	id = "not_ready_business",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_5e6a9bde", -- No, I'M telling YOU to mind your OWN business! And your business is at Jabba's Palace! So start walking, bub.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_not_ready_business)

nirame_sakute_convo_busy = ConvoScreen:new {
	id = "busy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1a5ce928", -- Time is money! And you're wasting time! I don't do business with malingerers!
	stopConversation = "false",
	animation = "stamp_feet",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_a30c1a53", "busy_back"}, -- Yes sir!
		{"@conversation/tatooine_privateer_tier4:s_f8e8f311", "busy_work"}, -- What'd you call me?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_busy)

nirame_sakute_convo_busy_back = ConvoScreen:new {
	id = "busy_back",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_49155225", -- I want to see the back of you! Pronto!
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_busy_back)

nirame_sakute_convo_busy_work = ConvoScreen:new {
	id = "busy_work",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_38264798", -- GET TO WORK!
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_busy_work)

nirame_sakute_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_4854b859", -- I thought you told me you were the greatest pilot of all time.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_3ff5bba1", "m1_failed_talon"}, -- I said that?
		{"@conversation/tatooine_privateer_tier4:s_3c7012a7", "m1_failed_good"}, -- No. I said I was good.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_failed)

nirame_sakute_convo_m1_failed_talon = ConvoScreen:new {
	id = "m1_failed_talon",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_69647725", -- Actually, no, you didn't. Talon said it! Maybe Talon was wrong!
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_559912", "m1_retry_a"}, -- Don't be so quick to judge me. I can get the job done.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_failed_talon)

nirame_sakute_convo_m1_retry_a = ConvoScreen:new {
	id = "m1_retry_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_cf53514d", -- I hope so! Go on, get out of here!
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_retry_a)

nirame_sakute_convo_m1_failed_good = ConvoScreen:new {
	id = "m1_failed_good",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_842eb2d9", -- Well, good pilots don't flub missions!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_190e0e72", "m1_failed_mocking"}, -- Good point.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_failed_good)

nirame_sakute_convo_m1_failed_mocking = ConvoScreen:new {
	id = "m1_failed_mocking",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1234129d", -- Are you mocking me?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_900f01d1", "m1_retry_b"}, -- What?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_failed_mocking)

nirame_sakute_convo_m1_retry_b = ConvoScreen:new {
	id = "m1_retry_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_aeab6bd1", -- Get back to work!
	stopConversation = "true",
	animation = "stamp_feet",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_retry_b)

nirame_sakute_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b30e002f", -- Those Imperials are STOMPING you.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_58362a8d", "m2_failed_shot"}, -- Tell me about it.
		{"@conversation/tatooine_privateer_tier4:s_db089cf0", "m2_failed_stink"}, -- What are you trying to say?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_failed)

nirame_sakute_convo_m2_failed_shot = ConvoScreen:new {
	id = "m2_failed_shot",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_76e45e0f", -- If I give you another shot, do you think you can handle it?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_7e0dff76", "m2_retry_a"}, -- Yeah.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_failed_shot)

nirame_sakute_convo_m2_retry_a = ConvoScreen:new {
	id = "m2_retry_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_6f729033", -- Okay. Suit up. You're going back out there.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_retry_a)

nirame_sakute_convo_m2_failed_stink = ConvoScreen:new {
	id = "m2_failed_stink",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e5e29dc", -- You stink!
	stopConversation = "false",
	animation = "hold_nose",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_df1485b", "m2_failed_straight"}, -- Don't beat around the bush! Just give it to me straight.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_failed_stink)

nirame_sakute_convo_m2_failed_straight = ConvoScreen:new {
	id = "m2_failed_straight",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_fa259cfa", -- The Imperials are giving it to YOU straight - with both barrels! Come on, now! Where's your pirate pride?
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f2648004", "m2_retry_b"}, -- Buried deep, deep down inside.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_failed_straight)

nirame_sakute_convo_m2_retry_b = ConvoScreen:new {
	id = "m2_retry_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e00688cd", -- OK smartmouth, that's enough out of you. Just get back to work!
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_retry_b)

nirame_sakute_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c9b06630", -- Let's review the basics here.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_3d6e04e6", "m3_failed_tell"}, -- Oh boy. Here we go.
		{"@conversation/tatooine_privateer_tier4:s_351c69aa", "m3_failed_what"}, -- Don't bother! I know what you're going to say.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed)

nirame_sakute_convo_m3_failed_tell = ConvoScreen:new {
	id = "m3_failed_tell",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c4076628", -- First, I TELL you what to do.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_c3363bcd", "m3_failed_do"}, -- Uh huh.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_tell)

nirame_sakute_convo_m3_failed_do = ConvoScreen:new {
	id = "m3_failed_do",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_a85bc17d", -- And then you DO it.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_a587c342", "m3_failed_understand"}, -- Mm hmm.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_do)

nirame_sakute_convo_m3_failed_understand = ConvoScreen:new {
	id = "m3_failed_understand",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b6298a33", -- Is there any part of that you don't understand?
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_a38a9e82", "m3_failed_situation"}, -- Nope! I think I got it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_understand)

nirame_sakute_convo_m3_failed_situation = ConvoScreen:new {
	id = "m3_failed_situation",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b5a3db93", -- Then why have we got this situation?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_851d7ea3", "m3_retry_a"}, -- Well, it's a little hard to explain.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_situation)

nirame_sakute_convo_m3_retry_a = ConvoScreen:new {
	id = "m3_retry_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e15e4244", -- You're upsetting me! And I don't LIKE getting upset! Get back to work! And do the job right this time!
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_retry_a)

nirame_sakute_convo_m3_failed_what = ConvoScreen:new {
	id = "m3_failed_what",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_3c81c35", -- What?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_b7e5af8c", "m3_failed_mindreader"}, -- That I blew it!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_what)

nirame_sakute_convo_m3_failed_mindreader = ConvoScreen:new {
	id = "m3_failed_mindreader",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_3fac3195", -- THAT'S RIGHT! You must be some kind of mindreader! Maybe you should quit being a pilot and get a job reading palms down at the cantina!
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_36a61f55", "m3_retry_b"}, -- OK! I get it! I'll get back to work!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_failed_mindreader)

nirame_sakute_convo_m3_retry_b = ConvoScreen:new {
	id = "m3_retry_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_9ee65601", -- Good luck! You'll need it!
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_retry_b)

nirame_sakute_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c4b1700b", -- You've got to finish what you've started.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_87d7e908", "m4_retry_a"}, -- I know.
		{"@conversation/tatooine_privateer_tier4:s_b857b065", "m4_retry_b"}, -- I'm still working on it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_failed)

nirame_sakute_convo_m4_retry_a = ConvoScreen:new {
	id = "m4_retry_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_58b4c6a6", -- The last thing you want is a bunch of fighter aces gunning for you. Get back out there!
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_retry_a)

nirame_sakute_convo_m4_retry_b = ConvoScreen:new {
	id = "m4_retry_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_10652869", -- Try not to get killed. Get back out there.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_retry_b)

nirame_sakute_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_18b41c2f", -- OK! So far, so good. Mission accomplished. And in true pirate tradition, you get a little off the top.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc27931b", "m1_reward_anytime"}, -- Thanks.
		{"@conversation/tatooine_privateer_tier4:s_6e4cac2c", "m1_reward_sure"}, -- I can use it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_reward)

nirame_sakute_convo_m1_reward_anytime = ConvoScreen:new {
	id = "m1_reward_anytime",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e775f9ef", -- Anytime! I'm a generous Rodian. See me later.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_reward_anytime)

nirame_sakute_convo_m1_reward_sure = ConvoScreen:new {
	id = "m1_reward_sure",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_baacb22a", -- Sure! We all need a little something now and then. Come back when you're ready for more.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_reward_sure)

nirame_sakute_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1371de7b", -- I'm always happy to see TIE fighter debris, floating through space. Nice work out there!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc27931b", "m2_reward_tide"}, -- Thanks.
		{"@conversation/tatooine_privateer_tier4:s_dcc126b1", "m2_reward_modesty"}, -- Just doing my job.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_reward)

nirame_sakute_convo_m2_reward_tide = ConvoScreen:new {
	id = "m2_reward_tide",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_88926265", -- Here's a little something to tide you over until your next mission. Don't spend it all in one place.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_reward_tide)

nirame_sakute_convo_m2_reward_modesty = ConvoScreen:new {
	id = "m2_reward_modesty",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_70a95d7f", -- False modesty! I love it. Here's your cut. Let me know when you're ready to do some more work for Talon.
	stopConversation = "true",
	animation = "laugh",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_reward_modesty)

nirame_sakute_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_62b0748", -- Everything's coming up roses, %TU.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_dd67013", "m3_reward_means"}, -- What does that mean?
		{"@conversation/tatooine_privateer_tier4:s_96c7f9b", "m3_reward_happy"}, -- Um, okay.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward)

nirame_sakute_convo_m3_reward_means = ConvoScreen:new {
	id = "m3_reward_means",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e6d5d85c", -- It means that Jabba's paid us for services rendered! And since YOU'RE the one that rendered said service, here's a little cut.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f69cf191", "m3_reward_ungrateful"}, -- This is all I get?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward_means)

nirame_sakute_convo_m3_reward_ungrateful = ConvoScreen:new {
	id = "m3_reward_ungrateful",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_3afa07bf", -- Hey! Don't be ungrateful. It's unattractive. If you want more, just ask me for another mission.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward_ungrateful)

nirame_sakute_convo_m3_reward_happy = ConvoScreen:new {
	id = "m3_reward_happy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_4bb84e05", -- Jabba's happy. And that means I'm happy. And if I'm happy, you're happy!
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_9cc12ff4", "m3_reward_pay"}, -- I'm not happy.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward_happy)

nirame_sakute_convo_m3_reward_pay = ConvoScreen:new {
	id = "m3_reward_pay",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_11eba9b0", -- Here's your pay!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f600815f", "m3_reward_now_happy"}, -- Okay, NOW I'm happy!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward_pay)

nirame_sakute_convo_m3_reward_now_happy = ConvoScreen:new {
	id = "m3_reward_now_happy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_ae9a6733", -- Of course. Come see me when you're ready for some more interstellar action!
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_reward_now_happy)

nirame_sakute_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_2e0d4c28", -- Money! You want it?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_d70dba34", "m4_reward_got_it"}, -- Yes.
		{"@conversation/tatooine_privateer_tier4:s_677b3694", "m4_reward_everybody"}, -- EVERYBODY wants money!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_reward)

nirame_sakute_convo_m4_reward_got_it = ConvoScreen:new {
	id = "m4_reward_got_it",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_35a6c533", -- You've got it!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_reward_got_it)

nirame_sakute_convo_m4_reward_everybody = ConvoScreen:new {
	id = "m4_reward_everybody",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_96d69e86", -- Especially smugglers! Here's your pay. Nice work out there.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_reward_everybody)

nirame_sakute_convo_ready = ConvoScreen:new {
	id = "ready",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_67ec71d0", -- Hey, there you are. Ready to get back to work?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_8be640b8", "m1_brief"}, -- Sure.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_ready)

nirame_sakute_convo_ready_train = ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_9a63e564", -- Pilots like you receive skills training. And you'll be getting that training from me. So get ready! And pick your poison.
	stopConversation = "false",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_ready_train)

nirame_sakute_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_593a67cd", -- Talon says you're a good worker. But I'll believe it when I see it!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_6b1ef548", "intro_busy"}, -- I'm looking for Talon Karrde.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_intro)

nirame_sakute_convo_intro_busy = ConvoScreen:new {
	id = "intro_busy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_90f41db9", -- Don't bother! He's too busy to deal with the likes of you. As far as you're concerned, I AM Talon Karrde.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_b0328fe7", "intro_name"}, -- Okay. So what's your name?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_intro_busy)

nirame_sakute_convo_intro_name = ConvoScreen:new {
	id = "intro_name",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_9f0981a2", -- What's in a name? You can just call me Sir.
	stopConversation = "false",
	animation = "flex_biceps",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f1aeca8b", "intro_love"}, -- Sounds like you're really in love with yourself.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_intro_name)

nirame_sakute_convo_intro_love = ConvoScreen:new {
	id = "intro_love",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8e76f5e4", -- Sure. What's not to love?
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_879f33d", "intro_roster"}, -- I'm assuming you have work for me.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_intro_love)

nirame_sakute_convo_intro_roster = ConvoScreen:new {
	id = "intro_roster",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8782c730", -- You guessed right. Let's see what I've got on my roster! If you want to be a hero to Nym's group, you could rescue one of his transports. CorSec and RSF ships are attacking it as we speak!
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_67e6df55", "duty_escort_info"}, -- Okay.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_intro_roster)

nirame_sakute_convo_duty_escort_info = ConvoScreen:new {
	id = "duty_escort_info",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e5da4e7", -- Then there's a Nym smuggler who needs an escort if he's going to make it though Lok space. As you can see, we have lots of opportunities here to earn Nym's gratitude. And that's a good thing.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc00cf40", "duty_freighter_info"}, -- I see what you mean.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_escort_info)

nirame_sakute_convo_duty_freighter_info = ConvoScreen:new {
	id = "duty_freighter_info",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_74aa808d", -- If you want to stick it to the Imperials, you could liberate - wink, wink - one of their freighters and bring it to a hyperspace jump point. We could always use something like that.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5866c569", "duty_menu"}, -- I follow you.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_freighter_info)

nirame_sakute_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c91fbb55", -- And if you just feel like blasting everything in sight, I could send you out a Dantooine patrol! Everybody's out there these days: CorSec, RSF, Imperial, even Valarian ships. Plenty of targets. So which one is it going to be?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_412dc22e", "duty_escort"}, -- I'll take that escort.
		{"@conversation/tatooine_privateer_tier4:s_4bb3bd9d", "duty_rescue"}, -- Sounds like that poor smuggler needs my help.
		{"@conversation/tatooine_privateer_tier4:s_aa6112c9", "duty_recovery"}, -- An Imperial freighter? Sounds like a tough assignment. I'll take it.
		{"@conversation/tatooine_privateer_tier4:s_fcb2db97", "duty_destroy"}, -- Let's see what I can do about making Dantooine safe for smuggler kind.
		{"@conversation/tatooine_privateer_tier4:s_694ce3f1", "duty_explain"}, -- Could you explain it to me again?.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_menu)

nirame_sakute_convo_duty_explain = ConvoScreen:new {
	id = "duty_explain",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_87550112", -- If you want to be a hero to Nym's group, you could rescue one of his transports. CorSec and RSF ships are attacking it as we speak!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_67e6df55", "duty_escort_info"}, -- Okay.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_explain)

nirame_sakute_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_38a1649f", -- Better make sure your blasters are operating at full capacity before you take off for Lok! Watch your back, %TU.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_escort)

nirame_sakute_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_aba2cf17", -- Sounds that way! They are in Lok. Get going.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_rescue)

nirame_sakute_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_ae92ea5d", -- You tell ME how tough it is - when you get back from Dantooine!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_recovery)

nirame_sakute_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_4eee118b", -- Nym's going to appreciate that!
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_duty_destroy)

nirame_sakute_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_81f135c8", -- Time for you to get to work! You're no use to me when you're just standing around. What are you going to do? Or do you need me to explain the situation to you again?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_412dc22e", "duty_escort"}, -- I'll take that escort.
		{"@conversation/tatooine_privateer_tier4:s_4bb3bd9d", "duty_rescue"}, -- Sounds like that poor smuggler needs my help.
		{"@conversation/tatooine_privateer_tier4:s_aa6112c9", "duty_recovery"}, -- An Imperial freighter? Sounds like a tough assignment. I'll take it.
		{"@conversation/tatooine_privateer_tier4:s_fcb2db97", "duty_destroy"}, -- Let's see what I can do about making Dantooine safe for smuggler kind.
		{"@conversation/tatooine_privateer_tier4:s_694ce3f1", "duty_explain"}, -- Could you explain it to me again?.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_tier4_incomplete)

nirame_sakute_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_303b5f14", -- Hey! There's my favorite bum now. I have some surprising news here for you.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_2313ac9e", "transfer_news"}, -- What are you talking about?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer)

nirame_sakute_convo_transfer_news = ConvoScreen:new {
	id = "transfer_news",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_95b55346", -- I just got a communique from Alliance headquarters. Admiral Burke is asking us for help. They're in a jam, and they are looking for the best pilots they can find.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_bbe3529b", "transfer_who"}, -- Who is Admiral Burke?
		{"@conversation/tatooine_privateer_tier4:s_8c39d757", "transfer_why"}, -- Why would we want to help the Rebellion?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_news)

nirame_sakute_convo_transfer_who = ConvoScreen:new {
	id = "transfer_who",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_5681e74d", -- He is one of the Alliance fleet commanders. He's got a force stationed in the Outer Rim. Not really sure what they are planning to do out there, but if he is looking for outside help, it must be something big.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_71d95498", "transfer_join"}, -- So you want me to join the Rebellion?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_who)

nirame_sakute_convo_transfer_why = ConvoScreen:new {
	id = "transfer_why",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b2909765", -- Why not? They're useful, in their way.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_71d95498", "transfer_join"}, -- So you want me to join the Rebellion?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_why)

nirame_sakute_convo_transfer_join = ConvoScreen:new {
	id = "transfer_join",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_94e9bd3b", -- I don't want you to join ANYTHING. But I'll tell you one thing, if the Alliance is going to do something big, you can be sure that the Empire will be involved. And the way I see it, anything that is bad for the Empire is good for us.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_ac1da756", "transfer_plans"}, -- What are the Rebels planning to do?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_join)

nirame_sakute_convo_transfer_plans = ConvoScreen:new {
	id = "transfer_plans",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1d267ca4", -- I can't really say, since I don't know. But it won't kill you to see this Admiral and hear what he has to say, right? He can't exactly force you to do anything for him, but there is a lot of things a pilot can learn from the Alliance.
	stopConversation = "false",
	animation = "stretch",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f8674c23", "transfer_where"}, -- Where am I supposed to meet him?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_plans)

nirame_sakute_convo_transfer_where = ConvoScreen:new {
	id = "transfer_where",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b1d60b3e", -- He's stationed on Corellia, in Doaba Guerfel. He is expecting someone from our operation to show up... and I think that someone should be you. I can't force you to go. It's up to you, but I think it would be a smart move, %TU.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_transfer_where)

nirame_sakute_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e46f0376", -- Hey, you're still in one piece. I guess those Alliance boys didn't work you over TOO hard. Are you looking for work?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_412dc22e", "duty_escort"}, -- I'll take that escort.
		{"@conversation/tatooine_privateer_tier4:s_4bb3bd9d", "duty_rescue"}, -- Sounds like that poor smuggler needs my help.
		{"@conversation/tatooine_privateer_tier4:s_aa6112c9", "duty_recovery"}, -- An Imperial freighter? Sounds like a tough assignment. I'll take it.
		{"@conversation/tatooine_privateer_tier4:s_fcb2db97", "duty_destroy"}, -- Let's see what I can do about making Dantooine safe for smuggler kind.
		{"@conversation/tatooine_privateer_tier4:s_694ce3f1", "duty_explain"}, -- Could you explain it to me again?.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_here_for_work)

nirame_sakute_convo_m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_da0b2b1e", -- Now then. You did good work with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5c05ecff", "m1_compliment"}, -- I just did what I was told.
		{"@conversation/tatooine_privateer_tier4:s_a59a1d43", "m1_paycheck"}, -- Skip the lecture and give me a mission! I need the money.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_brief)

nirame_sakute_convo_m1_trained_starships = ConvoScreen:new {
	id = "m1_trained_starships",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_bdae1e2f", -- Vessels! Done! Now then. You did good work with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5c05ecff", "m1_compliment"}, -- I just did what I was told.
		{"@conversation/tatooine_privateer_tier4:s_a59a1d43", "m1_paycheck"}, -- Skip the lecture and give me a mission! I need the money.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_trained_starships)

nirame_sakute_convo_m1_trained_weapons = ConvoScreen:new {
	id = "m1_trained_weapons",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c40a86d2", -- Components! Done! Now then. You did good work with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5c05ecff", "m1_compliment"}, -- I just did what I was told.
		{"@conversation/tatooine_privateer_tier4:s_a59a1d43", "m1_paycheck"}, -- Skip the lecture and give me a mission! I need the money.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_trained_weapons)

nirame_sakute_convo_m1_trained_procedures = ConvoScreen:new {
	id = "m1_trained_procedures",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e3cee4d9", -- Techniques! Done! Now then. You did good work with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5c05ecff", "m1_compliment"}, -- I just did what I was told.
		{"@conversation/tatooine_privateer_tier4:s_a59a1d43", "m1_paycheck"}, -- Skip the lecture and give me a mission! I need the money.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_trained_procedures)

nirame_sakute_convo_m1_trained_droid = ConvoScreen:new {
	id = "m1_trained_droid",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b00344d", -- Droids! Done! Now then. You did good work with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_5c05ecff", "m1_compliment"}, -- I just did what I was told.
		{"@conversation/tatooine_privateer_tier4:s_a59a1d43", "m1_paycheck"}, -- Skip the lecture and give me a mission! I need the money.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_trained_droid)

nirame_sakute_convo_m1_compliment = ConvoScreen:new {
	id = "m1_compliment",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_2a9aa104", -- Write that one down in your diary! I just gave you a compliment. I NEVER give compliments. It's a red-letter day.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_b3e1da76", "m1_lately"}, -- Aw shucks. Lucky me.
		{"@conversation/tatooine_privateer_tier4:s_b8dd8b3d", "m1_reporting"}, -- Very touching.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_compliment)

nirame_sakute_convo_m1_lately = ConvoScreen:new {
	id = "m1_lately",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e9125b15", -- But the question is, what have you done for me lately? So let's get to work. Had enough of this place?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_cfd8a48c", "m1_talking"}, -- Enough for a lifetime!
		{"@conversation/tatooine_privateer_tier4:s_73d0a21b", "m1_palace"}, -- What? No!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_lately)

nirame_sakute_convo_m1_talking = ConvoScreen:new {
	id = "m1_talking",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_a084de70", -- Now you're talking.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_59209e57", "m1_good_idea"}, -- So put me to work!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_talking)

nirame_sakute_convo_m1_reporting = ConvoScreen:new {
	id = "m1_reporting",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_f13c9503", -- Now that Jabba's happy, you're free to work with Talon Karrde again. But Talon's busy. So you're reporting to me!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_59209e57", "m1_good_idea"}, -- So put me to work!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_reporting)

nirame_sakute_convo_m1_palace = ConvoScreen:new {
	id = "m1_palace",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_717febcb", -- Did you like the palace?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_55671c91", "m1_smell"}, -- Not really. It smelled terrible.
		{"@conversation/tatooine_privateer_tier4:s_2bf9b1f7", "m1_ally"}, -- Oh yeah.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_palace)

nirame_sakute_convo_m1_smell = ConvoScreen:new {
	id = "m1_smell",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_a6359b23", -- That's the smell of money, %TU! Jabba's a good ally for us. He's the strongest crime lord in the system, by far.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_443da380", "m1_ugliest"}, -- Sure - for now. One of these days, Lady Valarian could become the strongest.
		{"@conversation/tatooine_privateer_tier4:s_95c7e5cc", "m1_happy"}, -- He is, isn't he? I've heard stories.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_smell)

nirame_sakute_convo_m1_ally = ConvoScreen:new {
	id = "m1_ally",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8138df62", -- Jabba's a good ally for us. He's the strongest crime lord in the sector, by far.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_443da380", "m1_ugliest"}, -- Sure - for now. One of these days, Lady Valarian could become the strongest.
		{"@conversation/tatooine_privateer_tier4:s_95c7e5cc", "m1_happy"}, -- He is, isn't he? I've heard stories.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_ally)

nirame_sakute_convo_m1_ugliest = ConvoScreen:new {
	id = "m1_ugliest",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_bd9c8748", -- She's definitely the UGLIEST - and that's saying something! Jabba's not exactly easy on the eyes. And forget about Lady Valarian becoming the top player. It'll never happen.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_312a9b56", "m1_happy"}, -- You never know.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_ugliest)

nirame_sakute_convo_m1_happy = ConvoScreen:new {
	id = "m1_happy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_616c8086", -- If Jabba's happy, we're happy. We can't do our jobs without the love and affection of our local crime lords.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_17c44740", "m1_on_top"}, -- I guess.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_happy)

nirame_sakute_convo_m1_on_top = ConvoScreen:new {
	id = "m1_on_top",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8d8e36c9", -- We're doing our part to keep Jabba on top. And that leads me to your next assignment.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_1c8bddbb", "m1_booty"}, -- What is it?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_on_top)

nirame_sakute_convo_m1_paycheck = ConvoScreen:new {
	id = "m1_paycheck",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_ed173ecd", -- What happened? Did you blow your paycheck at the cantina?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_eb577cb4", "m1_tough"}, -- None of your business.
		{"@conversation/tatooine_privateer_tier4:s_c8046dd", "m1_tough"}, -- No way.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_paycheck)

nirame_sakute_convo_m1_tough = ConvoScreen:new {
	id = "m1_tough",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_9c834ac9", -- OK tough guy, have it your way. Let's get down to business. We need to help Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_59209e57", "m1_good_idea"}, -- So put me to work!
		{"@conversation/tatooine_privateer_tier4:s_e56b171a", "m1_on_top"}, -- I thought I was done with him.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_tough)

nirame_sakute_convo_m1_booty = ConvoScreen:new {
	id = "m1_booty",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_d48df184", -- Well listen up, there's a whole galaxy of booty out there, ripe for the picking! It's time for you to branch out, see what's out there. Think you're up to it?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_6c251948", "m1_big_time"}, -- You got it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_booty)

nirame_sakute_convo_m1_good_idea = ConvoScreen:new {
	id = "m1_good_idea",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b504a09d", -- Hey! Good idea! Listen pal, there's a whole galaxy of booty out there, ripe for the picking! It's time for you to branch out, see what's out there. Think you're up to it?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_6c251948", "m1_big_time_buddy"}, -- You got it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_good_idea)

nirame_sakute_convo_m1_big_time = ConvoScreen:new {
	id = "m1_big_time",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_39d3e7a3", -- I'm warning you now - it's the big time! Lots of unsavory elements flying around out there!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc7d0eed", "m1_situation"}, -- I can handle them.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_big_time)

nirame_sakute_convo_m1_big_time_buddy = ConvoScreen:new {
	id = "m1_big_time_buddy",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_d2c2dc92", -- I'm warning you buddy - it's the big time! Lots of unsavory elements flying around out there!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc7d0eed", "m1_situation"}, -- I can handle them.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_big_time_buddy)

nirame_sakute_convo_m1_situation = ConvoScreen:new {
	id = "m1_situation",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_c870211d", -- OK! That's all I need to hear. Now listen up! Here's the situation. One of Nym's ships is carrying a load of spice - although you didn't hear that from me. You're going to transfer that spice to a Hutt smuggler.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_741df7ed", "m1_lok"}, -- Where?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_situation)

nirame_sakute_convo_m1_lok = ConvoScreen:new {
	id = "m1_lok",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e9b39b51", -- Lok! Prettiest corner of the galaxy. Although you won't be doing any business on the surface. This is strictly a space mission.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_3f68df7d", "m1_imperials"}, -- Sounds easy enough.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_lok)

nirame_sakute_convo_m1_imperials = ConvoScreen:new {
	id = "m1_imperials",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_7934ba4d", -- Sure! It'd be REAL easy, if the Imperials would just mind their own business! But I think you can count on some interference from Imperial forces.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_fc7d0eed", "m1_accept_a"}, -- I can handle them.
		{"@conversation/tatooine_privateer_tier4:s_6c251948", "m1_accept_b"}, -- You got it.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_imperials)

nirame_sakute_convo_m1_accept_a = ConvoScreen:new {
	id = "m1_accept_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_164c9f60", -- If you say so! You'll find the coordinates in your ship's database. Bye now!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_accept_a)

nirame_sakute_convo_m1_accept_b = ConvoScreen:new {
	id = "m1_accept_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_33dc0069", -- If you say so! You'll find the coordinates in your ship's database. Bye now!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m1_accept_b)

nirame_sakute_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_e2084aee", -- What do you know about the Black Sun?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_a6d95597", "m2_connected"}, -- Not much.
		{"@conversation/tatooine_privateer_tier4:s_4d999afa", "m2_not_for_us"}, -- I know they're trouble.
		{"@conversation/tatooine_privateer_tier4:s_e30ce38b", "m2_sure_are"}, -- I know they're good.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_brief)

nirame_sakute_convo_m2_brief_trained = ConvoScreen:new {
	id = "m2_brief_trained",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_10c507d9", -- Now that Jabba's content, we can go about our business.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_908cfde5", "m2_transport"}, -- What's the situation?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_brief_trained)

nirame_sakute_convo_m2_connected = ConvoScreen:new {
	id = "m2_connected",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_2e5c16e2", -- Oh come on! You're kidding, right? The Black Sun is the biggest criminal syndicate around. And they are CONNECTED.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_77e48d5b", "m2_every_pie"}, -- What do you mean?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_connected)

nirame_sakute_convo_m2_every_pie = ConvoScreen:new {
	id = "m2_every_pie",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_7b6327ac", -- And they are CONNECTED. They've got their fingers in every pie.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_49a22a42", "m2_understanding"}, -- Including Karrde's?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_every_pie)

nirame_sakute_convo_m2_understanding = ConvoScreen:new {
	id = "m2_understanding",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_92118a17", -- Talon and the Black Sun have an... understanding. A lucrative one.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_6598178f", "m2_earners"}, -- Interesting.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_understanding)

nirame_sakute_convo_m2_not_for_us = ConvoScreen:new {
	id = "m2_not_for_us",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_dd5bf0f8", -- Not for us, they're not! Talon and the Black Sun have an... understanding. A lucrative one.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_6598178f", "m2_earners_b"}, -- Interesting.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_not_for_us)

nirame_sakute_convo_m2_earners = ConvoScreen:new {
	id = "m2_earners",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_636f3f4d", -- Sure is! The Black Sun are killers and sociopaths, but they're good earners. And they need our help.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_908cfde5", "m2_freighter"}, -- What's the situation?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_earners)

nirame_sakute_convo_m2_earners_b = ConvoScreen:new {
	id = "m2_earners_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_6bc1a8b4", -- Sure is! They're killers and sociopaths, but they're good earners. And they need our help.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_908cfde5", "m2_transport"}, -- What's the situation?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_earners_b)

nirame_sakute_convo_m2_sure_are = ConvoScreen:new {
	id = "m2_sure_are",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1056a46b", -- They sure are! But even they get into trouble now and then. Any interest in helping them out?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_c39e9b19", "m2_own_code"}, -- Depends. I don't want to get sucked into their world.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_sure_are)

nirame_sakute_convo_m2_own_code = ConvoScreen:new {
	id = "m2_own_code",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_192c6747", -- Not likely. The Black Sun have their own code of ethics when it comes to business. They stick to their own.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_908cfde5", "m2_freighter"}, -- What's the situation?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_own_code)

nirame_sakute_convo_m2_freighter = ConvoScreen:new {
	id = "m2_freighter",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_a1c0645d", -- The Imperials have captured a Black Sun freighter. It's carrying some good contraband - the kind of thing that would eventually end up in our pockets, if the Imperials would just mind their own business.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_85c8a240", "m2_disabled"}, -- What about the Black Sun? Don't they want to save their own ship?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_freighter)

nirame_sakute_convo_m2_transport = ConvoScreen:new {
	id = "m2_transport",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_f8e8d1ee", -- The Imperials have captured a Black Sun transport. It's carrying some good contraband - the kind of thing that would eventually end up in our pockets, if the Imperials would just mind their own business.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_85c8a240", "m2_disabled"}, -- What about the Black Sun? Don't they want to save their own ship?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_transport)

nirame_sakute_convo_m2_disabled = ConvoScreen:new {
	id = "m2_disabled",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_59fffde8", -- Sure! But the ship's almost completely disabled, so the guys on board are no use. And there aren't any other Black Sun in the vicinity. We're it!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_4bef9ff9", "m2_accept"}, -- Then I guess I better get to work.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_disabled)

nirame_sakute_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_11bcf0c", -- I guess so! Let me know how it goes! Get to Dantooine and hurry up.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m2_accept)

nirame_sakute_convo_m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_50335ae8", -- So tell me. Did you hear any good rumors in Jabba's Palace?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_a87f150c", "m3_angle"}, -- You know Jabba was always trying to make backdoor deal with the Imperials.
		{"@conversation/tatooine_privateer_tier4:s_4e27fe11", "m3_one_word"}, -- I don't know what you're talking about.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_brief)

nirame_sakute_convo_m3_angle = ConvoScreen:new {
	id = "m3_angle",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8ee47f8c", -- Jabba's always working an angle. And we haven't heard much from him lately. Is he planning something in Dathomir?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_c758f78a", "m3_valarians"}, -- I can't tell you what I don't know!
		{"@conversation/tatooine_privateer_tier4:s_bc331bd7", "m3_valarians"}, -- Nothing to tell. I'm here to get a mission!
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_angle)

nirame_sakute_convo_m3_one_word = ConvoScreen:new {
	id = "m3_one_word",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_f17a86bc", -- I'll just say one word: Dathomir.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_f14cd6bf", "m3_valarians_b"}, -- Really, I don't! I didn't have any time for gossip. I was too busy working.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_one_word)

nirame_sakute_convo_m3_valarians = ConvoScreen:new {
	id = "m3_valarians",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_11ed6849", -- Valarians are starting to get active around Dantooine. Too active, if you know what I mean. We need to nip that nonsense in the bud. I want you to disable a Valarian gunship and inspect it.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_658f174d", "m3_freight_plans"}, -- What am I looking for?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_valarians)

nirame_sakute_convo_m3_valarians_b = ConvoScreen:new {
	id = "m3_valarians_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_4499bb6", -- Valarians are becoming active around Dantooine. Too active, if you know what I mean. We need to nip that nonsense in the bud. I want you to disable a Valarian gunship and inspect it.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_658f174d", "m3_freight_plans"}, -- What am I looking for?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_valarians_b)

nirame_sakute_convo_m3_freight_plans = ConvoScreen:new {
	id = "m3_freight_plans",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_472841f4", -- Freight plans. I want to know what they're transporting!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_e79eddec", "m3_accept"}, -- Sounds like fun.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_freight_plans)

nirame_sakute_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_5af217dd", -- Thanks. I think so! You're clear to leave anytime.
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m3_accept)

nirame_sakute_convo_m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_8945d3f4", -- Smugglers like us, we have a code.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_53de9d8f", "m4_simple"}, -- Like what?
		{"@conversation/tatooine_privateer_tier4:s_17dede1", "m4_angles"}, -- You know I worked WITH the Empire when I was helping Jabba.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_brief)

nirame_sakute_convo_m4_brief_trained = ConvoScreen:new {
	id = "m4_brief_trained",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_1bfa482b", -- Good job with those Valarian fighters! You really put them in their place.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_2836e6b5", "m4_publicity_b"}, -- OK.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_brief_trained)

nirame_sakute_convo_m4_simple = ConvoScreen:new {
	id = "m4_simple",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_cad10f7b", -- It's simple. We just try to help people in need.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_14a79f3e", "m4_help_us"}, -- That's it?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_simple)

nirame_sakute_convo_m4_help_us = ConvoScreen:new {
	id = "m4_help_us",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_db65cfb3", -- Well...we really try to help people who can help US later on.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_7b0a4618", "m4_pirate_life"}, -- But I thought...
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_help_us)

nirame_sakute_convo_m4_pirate_life = ConvoScreen:new {
	id = "m4_pirate_life",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_21cba89", -- Pirate life, my friend! There's no black and white. It's all just shades of gray.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_61657d0f", "m4_publicity"}, -- I see.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_pirate_life)

nirame_sakute_convo_m4_publicity = ConvoScreen:new {
	id = "m4_publicity",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_15e60405", -- Lots of people in this sector hate the Valarians. They appreciate what you did. It's good publicity for the Smugglers Alliance, see.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_4f268deb", "m4_goodwill"}, -- Uh huh.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_publicity)

nirame_sakute_convo_m4_publicity_b = ConvoScreen:new {
	id = "m4_publicity_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_b16ff72d", -- Lots of people in this system hate the Valarians. They appreciate what you did. It's good publicity for the Smugglers Alliance, see.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_4f268deb", "m4_goodwill"}, -- Uh huh.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_publicity_b)

nirame_sakute_convo_m4_goodwill = ConvoScreen:new {
	id = "m4_goodwill",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_29b1a1b4", -- So I want to keep spreading the love. You're going to go on a goodwill mission.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_877810f1", "m4_targets"}, -- Enlighten me.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_goodwill)

nirame_sakute_convo_m4_angles = ConvoScreen:new {
	id = "m4_angles",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_f43dd2bd", -- Jabba works all the angles! Things are different with Talon. He's no fan of the Empire. Are you willing to aim your blasters at those TIE fighters?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_ad973bd9", "m4_targets"}, -- Yeah.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_angles)

nirame_sakute_convo_m4_targets = ConvoScreen:new {
	id = "m4_targets",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_70597637", -- I want you to start targeting enemy forces - starting with an Imperial Ace. Everybody hates the Imperials!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_da3439a6", "m4_lok"}, -- Where is this guy?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_targets)

nirame_sakute_convo_m4_lok = ConvoScreen:new {
	id = "m4_lok",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_6c6479e8", -- All your action's going to be in Lok. Later on, you'll be targeting CorSec forces, even RSF - all the guys that do their part to stifle and subjugate the masses.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_e61fa67b", "m4_free"}, -- So you're just a freedom fighter.
		{"@conversation/tatooine_privateer_tier4:s_4ca03ddb", "m4_enemies"}, -- How so?
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_lok)

nirame_sakute_convo_m4_free = ConvoScreen:new {
	id = "m4_free",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_293b395b", -- Well...I want everybody to be free to do business with our smugglers, if that's what you mean!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_4bef9ff9", "m4_accept_a"}, -- Then I guess I better get to work.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_free)

nirame_sakute_convo_m4_enemies = ConvoScreen:new {
	id = "m4_enemies",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_30ea47ea", -- There's CorSec, for one thing. Those guys are always mucking things up for us. Then you've got your stuck-up RSF forces. The Imperials would like us to straighten up and fly right - and that'll never happen! Even your old friend Lady Valarian is gunning for us, since we're aligned with Jabba.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_tier4:s_30860224", "m4_accept_b"}, -- So I'm gunning for the Imperials.
	}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_enemies)

nirame_sakute_convo_m4_accept_a = ConvoScreen:new {
	id = "m4_accept_a",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_7f405b16", -- And remember: Jabba forever!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_accept_a)

nirame_sakute_convo_m4_accept_b = ConvoScreen:new {
	id = "m4_accept_b",
	leftDialog = "@conversation/tatooine_privateer_tier4:s_85ddd986", -- You sure are!
	stopConversation = "true",
	options = {}
}
nirame_sakute_convo_template:addScreen(nirame_sakute_convo_m4_accept_b)

addConversationTemplate("nirame_sakute_convo_template", nirame_sakute_convo_template)
