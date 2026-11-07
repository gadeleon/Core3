-- Admiral Kilnstrider (Storm Squadron tier 4, Endor research outpost) conversation screens; ported from SWG-Source tatooine_imperial_tier4 (STF conversation/tatooine_imperial_tier4, pre-NGE client lines). Handler: kilnstriderConvoHandler.lua (feature storm-tier4-kilnstrider).
kilnstrider_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "kilnstriderConvoHandler",
	screens = {}
}

kilnstrider_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_d318f289", -- You don't look like much of a pilot.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_not_pilot)

kilnstrider_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_e16137e8", -- Get out of my sight immediately!
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_wrong_faction)

kilnstrider_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_50605b35", -- What are you doing here pilot. You are not a part of this unit.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_4854758d", "off_track_duties"}, -- I would like to request a mission.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_off_track)

kilnstrider_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_7247f243", -- I do not have any missions for which you are authorized. But I do have some elective duty tasks if you are interested. Would you like a briefing?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_8a4f7617", "duty_briefing"}, -- Please.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_off_track_duties)

kilnstrider_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_e542a06b", -- You are not authorized to fly the missions that I have. You would probably have more luck talking to your commanding officer.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_off_track_refused)

kilnstrider_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f2643fdd", -- What is your major malfunction, %TU!?  I just got a report that you're under investigation for treason!  Do you realize how this makes ME look?  I should shoot you myself.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_7090182", "wanted_c8003afd"}, -- What?!
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_wanted)

kilnstrider_convo_wanted_c8003afd = ConvoScreen:new {
	id = "wanted_c8003afd",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_c8003afd", -- Don't play innocent with me, %TU.  You need to get this situation straightened out.  If you cannot improve your standing with the Empire, then you can't be trusted with any more assignments.  Do I make myself clear?  You are dismissed.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_wanted_c8003afd)

kilnstrider_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_d3b2272c", -- I believe your trainer is looking for you.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_not_ready)

kilnstrider_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2a35d2fe", -- This war will be won by pilots who FIGHT, not by  pilots who like to drop by for visits! Begone!
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_on_mission)

kilnstrider_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_71e775f5", -- You have not done your job!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_8f4d001d", "m1_failed_898e32ed"}, -- I haven't?
		{"@conversation/tatooine_imperial_tier4:s_abddb145", "m1_failed_9da5d80d"}, -- I am sorry, it won't happen again.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_failed)

kilnstrider_convo_m1_failed_898e32ed = ConvoScreen:new {
	id = "m1_failed_898e32ed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_898e32ed", -- I should say not! I am unsatisfied! Finish what you have started, imbecile!
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_failed_898e32ed)

kilnstrider_convo_m1_failed_9da5d80d = ConvoScreen:new {
	id = "m1_failed_9da5d80d",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_9da5d80d", -- See that it doesn't! The Empire only has room for the best. Get back to work.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_failed_9da5d80d)

kilnstrider_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2eb3aa2", -- You are resting on your laurels, %TU. Do not be so overconfident. 
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_77e48d5b", "m2_failed_b3c5ff5e"}, -- What do you mean?
		{"@conversation/tatooine_imperial_tier4:s_b3d150e3", "m2_failed_eb570c2b"}, -- I know I have not completed my mission.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed)

kilnstrider_convo_m2_failed_b3c5ff5e = ConvoScreen:new {
	id = "m2_failed_b3c5ff5e",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_b3c5ff5e", -- Have you completed your mission?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_49237f95", "m2_failed_83cb9cbb"}, -- No...
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed_b3c5ff5e)

kilnstrider_convo_m2_failed_83cb9cbb = ConvoScreen:new {
	id = "m2_failed_83cb9cbb",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_83cb9cbb", -- I would have no problem replacing you with another pilot. And replaced pilots are dead pilots. Am I making myself clear?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_87d4bfc2", "m2_failed_a9fb7454"}, -- Crystal.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed_83cb9cbb)

kilnstrider_convo_m2_failed_a9fb7454 = ConvoScreen:new {
	id = "m2_failed_a9fb7454",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a9fb7454", -- I suggest you get back to work.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed_a9fb7454)

kilnstrider_convo_m2_failed_eb570c2b = ConvoScreen:new {
	id = "m2_failed_eb570c2b",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_eb570c2b", -- Ah yes. I know this too. What should we do about this?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_60db9426", "m2_failed_661f1464"}, -- I should...finish my mission?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed_eb570c2b)

kilnstrider_convo_m2_failed_661f1464 = ConvoScreen:new {
	id = "m2_failed_661f1464",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_661f1464", -- Excellent idea! Let's do that. 
	stopConversation = "true",
	animation = "clap_rousing",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_failed_661f1464)

kilnstrider_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_e0e28bdb", -- You are drawing the attention of the Inquisition. They are wondering how a pilot like yourself could possibly be an Imperial.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_c1ce722e", "m3_failed_7a3b60ae"}, -- I will complete my mission! I swear it!
		{"@conversation/tatooine_imperial_tier4:s_e26ff616", "m3_failed_ee7cbdbe"}, -- I will do my job.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_failed)

kilnstrider_convo_m3_failed_7a3b60ae = ConvoScreen:new {
	id = "m3_failed_7a3b60ae",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_7a3b60ae", -- Pretty words. I would rather see ugly action, if you know what I mean.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_6ebb13d3", "m3_failed_8bcb23a1"}, -- I do.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_failed_7a3b60ae)

kilnstrider_convo_m3_failed_8bcb23a1 = ConvoScreen:new {
	id = "m3_failed_8bcb23a1",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_8bcb23a1", -- Then show me  that you are a person of your word.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_failed_8bcb23a1)

kilnstrider_convo_m3_failed_ee7cbdbe = ConvoScreen:new {
	id = "m3_failed_ee7cbdbe",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_ee7cbdbe", -- See that you do. Because, you see, it is also drawing attention to myself. And I do not want that. So do good - for me. 
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_failed_ee7cbdbe)

kilnstrider_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_3e3689e0", -- Do you REALIZE what will happen if you fail this mission?!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_ef420789", "m4_failed_ee15b61"}, -- Yes!
		{"@conversation/tatooine_imperial_tier4:s_4c695dbd", "m4_failed_175d585"}, -- No.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_failed)

kilnstrider_convo_m4_failed_ee15b61 = ConvoScreen:new {
	id = "m4_failed_ee15b61",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_ee15b61", -- I hope so - for your sake. Return to your duties immediately.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_failed_ee15b61)

kilnstrider_convo_m4_failed_175d585 = ConvoScreen:new {
	id = "m4_failed_175d585",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_175d585", -- I will kill you myself. Is that enough motivation for you? Return to your duties!
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_failed_175d585)

kilnstrider_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_3ec8b347", -- The Rebels continue to bother us. They are incessant! But you have done well, %TU. You have earned your duty pay.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_b9b27823", "m1_reward_b1d99272"}, -- Thank you.
		{"@conversation/tatooine_imperial_tier4:s_71197541", "m1_reward_cae57de6"}, -- Yes. I have.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_reward)

kilnstrider_convo_m1_reward_b1d99272 = ConvoScreen:new {
	id = "m1_reward_b1d99272",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_b1d99272", -- Life is short - especially for an Imperial pilot. I would enjoy that money if I were you.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_reward_b1d99272)

kilnstrider_convo_m1_reward_cae57de6 = ConvoScreen:new {
	id = "m1_reward_cae57de6",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_cae57de6", -- There's more where that came from.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_reward_cae57de6)

kilnstrider_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a4dd5d0d", -- Very good, %TU. I have your duty pay.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_c90d9b02", "m2_reward_f5ef44e1"}, -- The Empire pays well.
		{"@conversation/tatooine_imperial_tier4:s_a46cdee9", "m2_reward_d7be8f57"}, -- Excellent!
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_reward)

kilnstrider_convo_m2_reward_f5ef44e1 = ConvoScreen:new {
	id = "m2_reward_f5ef44e1",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f5ef44e1", -- The Emperor appreciates your loyalty.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_reward_f5ef44e1)

kilnstrider_convo_m2_reward_d7be8f57 = ConvoScreen:new {
	id = "m2_reward_d7be8f57",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_d7be8f57", -- Don't spend it all in one place.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_reward_d7be8f57)

kilnstrider_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_9ff091bd", -- Ah. %TU. Hello. I wish to give you your duty pay.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_134dd45", "m3_reward_1e4c7d44"}, -- I will accept it.
		{"@conversation/tatooine_imperial_tier4:s_469b88eb", "m3_reward_a5182b84"}, -- I wish only to serve.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_reward)

kilnstrider_convo_m3_reward_1e4c7d44 = ConvoScreen:new {
	id = "m3_reward_1e4c7d44",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_1e4c7d44", -- Ha! How very kind of you.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_reward_1e4c7d44)

kilnstrider_convo_m3_reward_a5182b84 = ConvoScreen:new {
	id = "m3_reward_a5182b84",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a5182b84", -- You have earned it.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_reward_a5182b84)

kilnstrider_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_5066022c", -- And so, of course, I will pay you now.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_b474959c", "m4_reward_1e20c3ab"}, -- Of course! I did my duty.
		{"@conversation/tatooine_imperial_tier4:s_5085bdab", "m4_reward_2c46518"}, -- I can use the money.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_reward)

kilnstrider_convo_m4_reward_1e20c3ab = ConvoScreen:new {
	id = "m4_reward_1e20c3ab",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_1e20c3ab", -- You did. And the Emperor thanks you.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_reward_1e20c3ab)

kilnstrider_convo_m4_reward_2c46518 = ConvoScreen:new {
	id = "m4_reward_2c46518",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2c46518", -- It's always useful.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_reward_2c46518)

kilnstrider_convo_ready = ConvoScreen:new {
	id = "ready",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_53773f7e", -- Welcome back, %TU. Your next assignment is waiting. Are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_52917b0d", "m1_brief"}, -- Of course.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_ready)

kilnstrider_convo_ready_train = ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_d1e73984", -- It is essential that all pilots continue their training. Select your next course of study!
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_a50d5eb4", "m1_brief"}, -- I want to learn about experimental TIE vessels.
		{"@conversation/tatooine_imperial_tier4:s_2c2ce09e", "m1_brief"}, -- I want to learn about heavy starship component use.
		{"@conversation/tatooine_imperial_tier4:s_a5d7d28d", "m1_brief"}, -- I want to learn about elite TIE guard training.
		{"@conversation/tatooine_imperial_tier4:s_97682588", "m1_brief"}, -- I want to learn about droid intelligence theory.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_ready_train)

kilnstrider_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_7f465235", -- Oh yes. I was told to expect you. I imagine you fancy yourself quite the pilot. Well I'll make my own judgments once your prove yourself. Now, how about you get to work?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_49425c4b", "intro_briefing"}, -- I'd like to do more than talk.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_intro)

kilnstrider_convo_intro_briefing = ConvoScreen:new {
	id = "intro_briefing",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_3e6a4237", -- Very well. The sitrep is as follows. A pirate clan has foolishly chosen to set up operations in this system. They must be dealt with. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_61657d0f", "duty_freighters"}, -- I see.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_intro_briefing)

kilnstrider_convo_duty_briefing = ConvoScreen:new {
	id = "duty_briefing",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_3e6a4237", -- Very well. The sitrep is as follows. A pirate clan has foolishly chosen to set up operations in this system. They must be dealt with. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_61657d0f", "duty_freighters"}, -- I see.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_briefing)

kilnstrider_convo_duty_freighters = ConvoScreen:new {
	id = "duty_freighters",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_77788129", -- More supply freighters are arriving every day. They must be transported to headquarters.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_eef2363b", "duty_pirates"}, -- Mm.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_freighters)

kilnstrider_convo_duty_pirates = ConvoScreen:new {
	id = "duty_pirates",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a0bfbb", -- We are also receiving reports that several freighters were attacked by pirate vessels. We need an experienced pilot to retrieve those freighters.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_7b7590d4", "duty_menu"}, -- Yes...
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_pirates)

kilnstrider_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2d7a9ef4", -- Freighters are also a popular target for Rebel forces. Several have taken damage, and they must be rescued. And that is the situation. Tell me, which one interests you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_cec1f447", "duty_destroy"}, -- I'd like to take out that pirate clan.
		{"@conversation/tatooine_imperial_tier4:s_7b2d0234", "duty_escort"}, -- I'll be happy to transport those freighters.
		{"@conversation/tatooine_imperial_tier4:s_d115dd42", "duty_recovery"}, -- Somebody's got to recover those freighters.
		{"@conversation/tatooine_imperial_tier4:s_5208f382", "duty_rescue"}, -- I can help those damaged freighters.
		{"@conversation/tatooine_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_menu)

kilnstrider_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_67f91789", -- Always plenty of work for a pilot like you. Are you ready to accept an assignment? Or would you like to hear the briefing again?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_cec1f447", "duty_destroy"}, -- I'd like to take out that pirate clan.
		{"@conversation/tatooine_imperial_tier4:s_7b2d0234", "duty_escort"}, -- I'll be happy to transport those freighters.
		{"@conversation/tatooine_imperial_tier4:s_d115dd42", "duty_recovery"}, -- Somebody's got to recover those freighters.
		{"@conversation/tatooine_imperial_tier4:s_5208f382", "duty_rescue"}, -- I can help those damaged freighters.
		{"@conversation/tatooine_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_tier4_incomplete)

kilnstrider_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f5e3efbe", -- I understand that you served the Grand Admiral with distinction. You have done well by me and the squadron. Are you just here for more work?  Sure you are.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_cec1f447", "duty_destroy"}, -- I'd like to take out that pirate clan.
		{"@conversation/tatooine_imperial_tier4:s_7b2d0234", "duty_escort"}, -- I'll be happy to transport those freighters.
		{"@conversation/tatooine_imperial_tier4:s_d115dd42", "duty_recovery"}, -- Somebody's got to recover those freighters.
		{"@conversation/tatooine_imperial_tier4:s_5208f382", "duty_rescue"}, -- I can help those damaged freighters.
		{"@conversation/tatooine_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_here_for_work)

kilnstrider_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f6f97563", -- Excellent. Sometimes I think half the galaxy has taken an interest in this godforsaken little corner. You're free to leave anytime.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_destroy)

kilnstrider_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f4d0ec53", -- Do so! You're clear to leave.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_escort)

kilnstrider_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_31428bf1", -- Looks like that somebody is you, %TU.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_recovery)

kilnstrider_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_86c72612", -- That's very good of you. My men will upload coordinates to your ship.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_duty_rescue)

kilnstrider_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_146bc0b9", -- I just received the orders, you are shipping out. Grand Admiral Nial Declann has ordered that you attend him immediately. The orders come from the Palace at Theed so that is where I expect he wants you to go.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_333f441a", "transfer_45c5c358"}, -- What would a Grand Admiral want with me?
		{"@conversation/tatooine_imperial_tier4:s_7177c3f2", "transfer_dc219a69"}, -- Who is Grand Admiral Nial Declann?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer)

kilnstrider_convo_transfer_45c5c358 = ConvoScreen:new {
	id = "transfer_45c5c358",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_45c5c358", -- The orders don't say and I don't make a point of sticking my nose in their business. The order simply say that you are being transferred under his command and that you are to report to him immediately. I suggest that you be on your best behavior for this one.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_df3eeb29", "transfer_a4f1dc7d"}, -- Why, what sort of man is he?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_45c5c358)

kilnstrider_convo_transfer_a4f1dc7d = ConvoScreen:new {
	id = "transfer_a4f1dc7d",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a4f1dc7d", -- How would I know? I have never had the honor of meeting a Grand Admiral. But your behavior reflects on me. If you screw up  he will probably just have you executed. I on the other hand will probably be put on garbage detail for the rest of my life. So show this Grand Admiral what being a member of Storm Squadron is all about.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_b8173a60", "transfer_b78b6139"}, -- Yes, sir. I won't let the squadron down.
		{"@conversation/tatooine_imperial_tier4:s_adcc0a23", "transfer_d669284c"}, -- You want me to be lazy and undisciplined?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_a4f1dc7d)

kilnstrider_convo_transfer_b78b6139 = ConvoScreen:new {
	id = "transfer_b78b6139",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_b78b6139", -- Good. Now don't keep the Admiral waiting. Get to Theed Palace on the double and report in.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_b78b6139)

kilnstrider_convo_transfer_d669284c = ConvoScreen:new {
	id = "transfer_d669284c",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_d669284c", -- Pilot, if you screw this up, the Grand Admiral won't have a chance to execute you because I will do it myself. And I won't make it all pleasant like he would. You will suffer long, you will suffer hard, and you will live to regret ever messing with my squadron. Now get out of my sight before I have to inform the Grand Admiral that you had a little accident involving my foot.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_d669284c)

kilnstrider_convo_transfer_dc219a69 = ConvoScreen:new {
	id = "transfer_dc219a69",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_dc219a69", -- Grand Admiral Nial Declann is one of the twelve men in charge of the Imperial Navy. From what I have heard he has the Emperor's ear and is definitely not a man to be trifled with. I would suggest that you be on your best behavior because that man will not tolerate any impertinence.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_bf2260fb", "transfer_e015cb4"}, -- Yes, sir. I will be on my best behavior.
		{"@conversation/tatooine_imperial_tier4:s_613f70ae", "transfer_a5827814"}, -- So I shouldn't call him Nial?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_dc219a69)

kilnstrider_convo_transfer_e015cb4 = ConvoScreen:new {
	id = "transfer_e015cb4",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_e015cb4", -- Good. Remember you reflect on me and the entire squadron. The Grand Admiral has the power to eliminate our entire group with a single order, so don't let us down. Now don't keep the Admiral waiting. Get to Theed Palace and report in right away.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_e015cb4)

kilnstrider_convo_transfer_a5827814 = ConvoScreen:new {
	id = "transfer_a5827814",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a5827814", -- You will address him as Grand Admiral or sir! If you lip off to the Grand Admiral he is liable to have you shot on the spot and then he will probably turn his vengeance on me. You are a reflection of our entire squadron so you had better not screw this up. Now get to Theed Palace and report in.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_transfer_a5827814)

kilnstrider_convo_m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_f10afb8", -- Very good! Now you will serve me! I have a mission for you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_469b88eb", "m1_satellites"}, -- I wish only to serve.
		{"@conversation/tatooine_imperial_tier4:s_9cc5ad7c", "m1_emperor"}, -- I am here to serve the Empire.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_brief)

kilnstrider_convo_m1_satellites = ConvoScreen:new {
	id = "m1_satellites",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2a973dfa", -- Something is knocking our system satellites offline.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_555b7ab7", "m1_unlikely"}, -- Sabotage?
		{"@conversation/tatooine_imperial_tier4:s_e5f302f7", "m1_engineers"}, -- Space debris?
		{"@conversation/tatooine_imperial_tier4:s_adfa15d1", "m1_your_concern"}, -- Any idea what it could be?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_satellites)

kilnstrider_convo_m1_emperor = ConvoScreen:new {
	id = "m1_emperor",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_6c642831", -- And I speak for the Emperor! The Endor system is back under our control. This is as it should be.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_ebe5a831", "m1_shoot"}, -- We destroyed the Rebel command ship, but they may still have the stolen information.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_emperor)

kilnstrider_convo_m1_shoot = ConvoScreen:new {
	id = "m1_shoot",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_8028a6ed", -- I am not concerned. We took action in time. The Empire may shoot too far or too wide at times - but at least we shoot!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_e604f53", "m1_exactly"}, -- And that's why we will win.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_shoot)

kilnstrider_convo_m1_exactly = ConvoScreen:new {
	id = "m1_exactly",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_43e05ffa", -- Exactly. Now listen! Satellites in this system are going offline. There is no reason this should be happening.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_555b7ab7", "m1_unlikely"}, -- Sabotage?
		{"@conversation/tatooine_imperial_tier4:s_e5f302f7", "m1_engineers"}, -- Space debris?
		{"@conversation/tatooine_imperial_tier4:s_adfa15d1", "m1_your_concern"}, -- Any idea what it could be?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_exactly)

kilnstrider_convo_m1_unlikely = ConvoScreen:new {
	id = "m1_unlikely",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_8f48acff", -- Unlikely. But whatever it is, it will be corrected. By you. I want you to investigate each satellite personally. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_4621ec24", "m1_accept_hope"}, -- I'll report my findings back to you.
		{"@conversation/tatooine_imperial_tier4:s_951d1b06", "m1_accept_busy"}, -- There must be...How many satellites are there in this system?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_unlikely)

kilnstrider_convo_m1_engineers = ConvoScreen:new {
	id = "m1_engineers",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_6dda58fa", -- Of course not. Our engineers plan for that kind of logical event. It's something else.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_adfa15d1", "m1_your_concern"}, -- Any idea what it could be?
		{"@conversation/tatooine_imperial_tier4:s_951d1b06", "m1_accept_busy"}, -- There must be...How many satellites are there in this system?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_engineers)

kilnstrider_convo_m1_your_concern = ConvoScreen:new {
	id = "m1_your_concern",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_9853c232", -- That is not my concern. It is yours. You will fix the problem. I want you to inspect each satellite personally.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_4621ec24", "m1_accept_hope"}, -- I'll report my findings back to you.
		{"@conversation/tatooine_imperial_tier4:s_951d1b06", "m1_accept_busy"}, -- There must be...How many satellites are there in this system?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_your_concern)

kilnstrider_convo_m1_accept_busy = ConvoScreen:new {
	id = "m1_accept_busy",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_b2a9497c", -- Enough to keep you busy, I think. You are to leave immediately.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_accept_busy)

kilnstrider_convo_m1_accept_hope = ConvoScreen:new {
	id = "m1_accept_hope",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_bc2b5278", -- I hope so. Dismissed.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m1_accept_hope)

kilnstrider_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_4aef73fb", -- You have earned some of my trust, %NU. Not all, but some. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_c782ced7", "m2_dont_be"}, -- I'm flattered.
		{"@conversation/tatooine_imperial_tier4:s_dd2ae025", "m2_listen"}, -- I don't know what to say.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_brief)

kilnstrider_convo_m2_brief_trained = ConvoScreen:new {
	id = "m2_brief_trained",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_71874e85", -- You have earned some of my trust, %NU. Not all, but some.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_c782ced7", "m2_dont_be"}, -- I'm flattered.
		{"@conversation/tatooine_imperial_tier4:s_dd2ae025", "m2_listen"}, -- I don't know what to say.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_brief_trained)

kilnstrider_convo_m2_dont_be = ConvoScreen:new {
	id = "m2_dont_be",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_717d4e48", -- Don't be. I'm only giving you the information you need to serve the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_c28a04da", "m2_spies"}, -- I don't tell secrets.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_dont_be)

kilnstrider_convo_m2_spies = ConvoScreen:new {
	id = "m2_spies",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_ae9853f8", -- Bothan spies are operating in this system. They have gone so far as to capture several of our command shuttles.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_52bae760", "m2_accept_fire"}, -- Incredible! Bothans are rarely so bold.
		{"@conversation/tatooine_imperial_tier4:s_b2da1ce2", "m2_answer"}, -- Bothan? They usually work with the Rebels.
		{"@conversation/tatooine_imperial_tier4:s_6a85372e", "m2_leaving"}, -- What are they doing with them?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_spies)

kilnstrider_convo_m2_listen = ConvoScreen:new {
	id = "m2_listen",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_499130ad", -- Then shut your mouth and listen! We have learned that Bothan spies are operating in this system.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_b7879974", "m2_not_this_time"}, -- How do you know they're here? Bothan spies are usually invisible.
		{"@conversation/tatooine_imperial_tier4:s_b2da1ce2", "m2_answer"}, -- Bothan? They usually work with the Rebels.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_listen)

kilnstrider_convo_m2_not_this_time = ConvoScreen:new {
	id = "m2_not_this_time",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_c3f0115e", -- Not this time. They have captured several of our command shuttles.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_6a85372e", "m2_leaving"}, -- What are they doing with them?
		{"@conversation/tatooine_imperial_tier4:s_52bae760", "m2_accept_fire"}, -- Incredible! Bothans are rarely so bold.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_not_this_time)

kilnstrider_convo_m2_answer = ConvoScreen:new {
	id = "m2_answer",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_cc9ccc9a", -- Well then. There's your answer.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_6a85372e", "m2_leaving"}, -- What are they doing with them?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_answer)

kilnstrider_convo_m2_leaving = ConvoScreen:new {
	id = "m2_leaving",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_83e62040", -- They are attempting to leave this system. But they will not - because you will stop them. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_5ec3bab9", "m2_accept_good"}, -- It's as good as done.
		{"@conversation/tatooine_imperial_tier4:s_2c4789b", "m2_accept_dismissed"}, -- Understood.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_leaving)

kilnstrider_convo_m2_accept_fire = ConvoScreen:new {
	id = "m2_accept_fire",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_3de69a90", -- They are attempting to leave this system. You will stop them. Fire at will.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_accept_fire)

kilnstrider_convo_m2_accept_good = ConvoScreen:new {
	id = "m2_accept_good",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_665b67d1", -- Very good.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_accept_good)

kilnstrider_convo_m2_accept_dismissed = ConvoScreen:new {
	id = "m2_accept_dismissed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_4d41f7fe", -- Dismissed.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m2_accept_dismissed)

kilnstrider_convo_m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_66bd8046", -- The Emperor continues to take an interest in this system. He is sending an Inquisitor here.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_643d24c8", "m3_weapon"}, -- An Inquisitor?
		{"@conversation/tatooine_imperial_tier4:s_34f8d771", "m3_not_concerned"}, -- Why? Have you been naughty?
		{"@conversation/tatooine_imperial_tier4:s_ad56e0fd", "m3_bothan_interest"}, -- For what reason?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_brief)

kilnstrider_convo_m3_weapon = ConvoScreen:new {
	id = "m3_weapon",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_958dc561", -- The Emperor's most potent weapon - besides myself,  that is. Your fears are well founded.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_21b67b7a", "m3_not_concerned"}, -- I have nothing to fear from them, right?
		{"@conversation/tatooine_imperial_tier4:s_ad56e0fd", "m3_bothan_interest"}, -- For what reason?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_weapon)

kilnstrider_convo_m3_not_concerned = ConvoScreen:new {
	id = "m3_not_concerned",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_bac59fd8", -- No. Of course not. I am not concerned. You know and I know that if you betrayed the Empire, you would be dead before nightfall.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_ad56e0fd", "m3_bothan_interest"}, -- For what reason?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_not_concerned)

kilnstrider_convo_m3_bothan_interest = ConvoScreen:new {
	id = "m3_bothan_interest",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_33cd03fd", -- I am sure the Inquisition is interested in Bothan spy activity. This particular - person - is very important to me, which means he is very important to you as well.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_9b43a7ee", "m3_accept_escort"}, -- Yes sir.
		{"@conversation/tatooine_imperial_tier4:s_d88c15de", "m3_accept_bottom"}, -- Of that you can be sure.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_bothan_interest)

kilnstrider_convo_m3_accept_escort = ConvoScreen:new {
	id = "m3_accept_escort",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_1c3b8136", -- You will personally escort the Inquisitor's ship to this position. You are to leave at once.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_accept_escort)

kilnstrider_convo_m3_accept_bottom = ConvoScreen:new {
	id = "m3_accept_bottom",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2483f4e0", -- The Inquisition means to get to the bottom of this. You are to escort their ship to this location. Dismissed.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m3_accept_bottom)

kilnstrider_convo_m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_fee3d28f", -- We continue to pursue these stolen shuttles.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_2f748550", "m4_escaped"}, -- I thought I had all of them!
		{"@conversation/tatooine_imperial_tier4:s_a1586753", "m4_curious"}, -- Do you know how the Bothans managed to pull this off?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_brief)

kilnstrider_convo_m4_escaped = ConvoScreen:new {
	id = "m4_escaped",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2e7cf1a7", -- No. You did not. Several shuttles managed to escape our sensors. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_9e02d014", "m4_amazed"}, -- Incredible! How can this be? We've been pursuing them at full speed!
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_escaped)

kilnstrider_convo_m4_amazed = ConvoScreen:new {
	id = "m4_amazed",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_e91413e7", -- I am amazed myself. As is the Inquisitor. He is eager to speak to one of these Bothan spies. They've done an amazing job.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_a5b9be0a", "m4_curious"}, -- The Bothan spies are good pilots after all.
		{"@conversation/tatooine_imperial_tier4:s_fcc7875e", "m4_information"}, -- Do you have any more information on the shuttles?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_amazed)

kilnstrider_convo_m4_curious = ConvoScreen:new {
	id = "m4_curious",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_b03d4317", -- It is curious, isn't it? But no matter. They won't get far. Bothan spies have no chance against an Imperial pilot such as yourself.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_96443422", "m4_dantooine"}, -- We'll get them.
		{"@conversation/tatooine_imperial_tier4:s_fcc7875e", "m4_not_yet"}, -- Do you have any more information on the shuttles?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_curious)

kilnstrider_convo_m4_information = ConvoScreen:new {
	id = "m4_information",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_783f1d49", -- We have gathered information from that Rebel shuttle.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_6a85372e", "m4_dantooine"}, -- What are they doing with them?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_information)

kilnstrider_convo_m4_not_yet = ConvoScreen:new {
	id = "m4_not_yet",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_510025b7", -- Not yet. But we DO know that the stolen shuttles were taken to the Dantooine system - and will  be transferred to the Rebel Alliance shortly.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_535d53b3", "m4_thoughts"}, -- That must not happen!
		{"@conversation/tatooine_imperial_tier4:s_7426e000", "m4_temper"}, -- No!
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_not_yet)

kilnstrider_convo_m4_dantooine = ConvoScreen:new {
	id = "m4_dantooine",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_484092bd", -- The Bothans took the ships to the Dantooine system. They will be transferred to the Rebellion shortly. But that must not happen.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_8eb7d0ee", "m4_temper"}, -- Destroy those shuttles!
		{"@conversation/tatooine_imperial_tier4:s_b885dd25", "m4_accept_prejudice"}, -- Can I fire on the ships?
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_dantooine)

kilnstrider_convo_m4_thoughts = ConvoScreen:new {
	id = "m4_thoughts",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_99e3a272", -- My thoughts exactly. You must make your way to Dantooine and destroy those stolen shuttles.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_b885dd25", "m4_accept_prejudice"}, -- Can I fire on the ships?
		{"@conversation/tatooine_imperial_tier4:s_5ec3bab9", "m4_accept_expect"}, -- It's as good as done.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_thoughts)

kilnstrider_convo_m4_temper = ConvoScreen:new {
	id = "m4_temper",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_a87c6f7d", -- You must control your temper. If you find these Bothans, you must deliver them to the Inquisitor unharmed. They will know what to do, believe me.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_tier4:s_2c4789b", "m4_accept_search"}, -- Understood.
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_temper)

kilnstrider_convo_m4_accept_prejudice = ConvoScreen:new {
	id = "m4_accept_prejudice",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_9ad8fa8f", -- Use extreme prejudice. We'd rather see those ships destroyed than fall into Rebel hands. 
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_accept_prejudice)

kilnstrider_convo_m4_accept_search = ConvoScreen:new {
	id = "m4_accept_search",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_c9b872a1", -- Then continue your search for those shuttles.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_accept_search)

kilnstrider_convo_m4_accept_expect = ConvoScreen:new {
	id = "m4_accept_expect",
	leftDialog = "@conversation/tatooine_imperial_tier4:s_2afd4ef5", -- I would expect nothing less.
	stopConversation = "true",
	options = {
	}
}
kilnstrider_convo_template:addScreen(kilnstrider_convo_m4_accept_expect)

addConversationTemplate("kilnstrider_convo_template", kilnstrider_convo_template)
