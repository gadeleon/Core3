-- Brother Vrovel (Vortex Squadron tier 2, Dantooine abandoned Rebel base) conversation; ported from SWG-Source dantooine_rebel_trainer_2.java with the pre-NGE client lines (feature vortex-tier2-vrovel). Handler: vrovelConvoHandler.
vrovel_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "vrovelConvoHandler",
	screens = {}
}

vrovel_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8ea054c0", -- Please leave. This is private property.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_not_pilot)

vrovel_convo_ezkiel_handoff = ConvoScreen:new {
	id = "ezkiel_handoff",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_319cfac4", -- Good to see you, %NU.  I've really enjoyed our time together. But now I'm placing you under the command of Brother Ezkiel. You can find him right over there. He will continue your guidance in the Vortex. Stay in touch, my friend!
	stopConversation = "true",
	animation = "bow3",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_ezkiel_handoff)

vrovel_convo_imperial = ConvoScreen:new {
	id = "imperial",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_6e50b681", -- What do you want? We're running a legal scientific expedition here.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_imperial)

vrovel_convo_neutral_pilot = ConvoScreen:new {
	id = "neutral_pilot",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b6efe97d", -- Please leave. This is private property!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_neutral_pilot)

vrovel_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b9e38f83", -- Woah, there, %TU.  Just what do you think you're doing?
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_900f01d1", "grounded_hq"}, -- What?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_grounded)

vrovel_convo_grounded_hq = ConvoScreen:new {
	id = "grounded_hq",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_7f77ceba", -- Haven't you heard?  You've been grounded.  I don't know what you did, but Alliance HQ is pretty mad about it.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f8b02865", "grounded_standing"}, -- What do I do?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_grounded_hq)

vrovel_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_96605d37", -- Beats me.  Better do something to improve your standing in the eyes of the Rebel Alliance though, or they'll never trust you with a mission again.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_grounded_standing)

vrovel_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_14c2f902", -- You don't look like a Vortex pilot. What can I do for you?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_c23a0a19", "off_track_no_missions"}, -- Do you have any missions that I can fly?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_off_track)

vrovel_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_87a97a09", -- Sorry, I can only assign missions to Vortex pilots. Perhaps you should go speak to your commanding officer.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_off_track_no_missions)

vrovel_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_10d3ddf5", -- I do have a few elective duty tasks. Are you interested?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_52917b0d", "duty_menu"}, -- Of course.
		{"@conversation/dantooine_rebel_trainer_2:s_28f9c5ec", "off_track_goodbye"}, -- Actually, no.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_off_track_duties)

vrovel_convo_off_track_goodbye = ConvoScreen:new {
	id = "off_track_goodbye",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_faebdc4c", -- Alright, good bye then.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_off_track_goodbye)

vrovel_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_be0843f2", -- Greetings %TU. Too bad you're already working for a different part of the Alliance Navy. We are short a few pilots at the moment.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_non_member)

vrovel_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d69a6474", -- What are you still doing here %TU? Time is of the essence!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_on_mission)

vrovel_convo_other_mission = ConvoScreen:new {
	id = "other_mission",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d0f52630", -- What's your name again? Oh yes, I see you on the duty roster. But it looks like you already have an assignment. Wrap that up, and then we can talk.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_other_mission)

vrovel_convo_handin = ConvoScreen:new {
	id = "handin",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_e14c4a10", -- You are %TU, the new pilot the navy sent us? Good, you couldn't have come at a better time. I am Vrovel. We are a part of the Rebel Alliance called the Vortex. We have several missions that require your assistance. But first I would like to see how well you can work with us. I have some duty work for you.
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_d049b613", "handin_mistaken"}, -- I'm sorry, you must have mistaken me for someone else.
		{"@conversation/dantooine_rebel_trainer_2:s_45236b6c", "handin_vortex"}, -- The Vortex? I've never heard of you before.
		{"@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu"}, -- I'm a Developer/Tester and want missions.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin)

vrovel_convo_handin_mistaken = ConvoScreen:new {
	id = "handin_mistaken",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b5a9bcf1", -- Hmm, then I must ask you to leave immediately.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_mistaken)

vrovel_convo_handin_vortex = ConvoScreen:new {
	id = "handin_vortex",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_2a02eb78", -- I'm not surprised. I will go in to more detail of what it is we do later, but we need to know how well you can work with us before we can give out any information on our operations here.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_e788dfef", "handin_dont_salute"}, -- Yes, sir. I'm ready, what are my orders?
		{"@conversation/dantooine_rebel_trainer_2:s_5088ea12", "handin_out"}, -- I didn't sign up to be kept in the dark. I'm out of here.
		{"@conversation/dantooine_rebel_trainer_2:s_cff9d397", "handin_promise"}, -- I suppose. But I will hold you to your promise. You have information?
		{"@conversation/dantooine_rebel_trainer_2:s_a59f4abe", "handin_pay"}, -- These high-risk missions? High-risk means more pay right?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_vortex)

vrovel_convo_handin_dont_salute = ConvoScreen:new {
	id = "handin_dont_salute",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f22c0d35", -- Don't salute me, soldier! The Imperial presence has increased around here lately, so we are pretending to be a scientific expedition. If an Imperial scout sees you saluting me, we might find ourselves in a holding cell tomorrow! We currently have a few duty assignments. That would test your mettle.  You can take your pick.
	stopConversation = "false",
	animation = "refuse_offer_affection",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_60e93806", "duty_menu"}, -- Sorry, sir. What are my options?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_dont_salute)

vrovel_convo_handin_out = ConvoScreen:new {
	id = "handin_out",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_299ce3a0", -- Yes this is clearly not for you. Good bye.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_out)

vrovel_convo_handin_promise = ConvoScreen:new {
	id = "handin_promise",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_6ad1ad62", -- Very well, I will tell you what I can when the time comes around. Now we have some duties for you. Are you ready?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_22a1e2bb", "duty_menu"}, -- Yes. How can I help?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_promise)

vrovel_convo_handin_pay = ConvoScreen:new {
	id = "handin_pay",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_57c7d4b9", -- We are not bounty hunters! You will be paid your regular salary, and at times you can keep things you collect from the enemy. Now that we have that squared away, are you ready to pick your task?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_33f02b70", "duty_menu"}, -- Okay okay, no need to get upset. What are my options?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_handin_pay)

vrovel_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_59d7264c", -- Quick! We have another chance to catch that officer before he reaches the Imperial fleet. Here are the new coordinates. Suit up and get going!
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_1d85385d", "m4_failed_nonsense"}, -- I can't do it. He's too heavily guarded.
		{"@conversation/dantooine_rebel_trainer_2:s_6a35a7eb", "m4_retry"}, -- Great! I hate failure!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_failed)

vrovel_convo_m4_failed_nonsense = ConvoScreen:new {
	id = "m4_failed_nonsense",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_21736cfe", -- Nonsense! Get your act together. Finish what you started, %NU. There's no turning back now!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_failed_nonsense)

vrovel_convo_m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_424b5808", -- Good. This is our last chance, %NU. May the Force be with you!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_retry)

vrovel_convo_m4_won = ConvoScreen:new {
	id = "m4_won",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_74e55e9e", -- We have it within our grasp, thanks to you,  %NU. Outstanding job up there. Rest up and get ready for the final step. It's time to shut this Imperial operation down for good!
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f931eb62", "m4_pay_close_call"}, -- Thank you, sir. It was a close call.
		{"@conversation/dantooine_rebel_trainer_2:s_7363d4a2", "m4_pay_impressed"}, -- I have to admit, I impressed even myself.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_won)

vrovel_convo_m4_pay_close_call = ConvoScreen:new {
	id = "m4_pay_close_call",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_450d0c76", -- Indeed %NU. Here's the completion bonus. You've earned every last bit of it. Come back later. Hopefully by then, the plan of attack will be completed.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_pay_close_call)

vrovel_convo_m4_pay_impressed = ConvoScreen:new {
	id = "m4_pay_impressed",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_7088f02a", -- I'm sure. Here's your completion bonus; I know you've been looking forward to it. Come back later. Hopefully by then, we'll have a battle plan ready to go.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_pay_impressed)

vrovel_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_985bcff1", -- Perfect timing, %NU. We are ready for the next phase of our mission. We have finally learned what this project is all about - AND we've figured out a way to stop it.
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_1807105", "m4_short_version"}, -- Give me the short version; I'm ready for action.
		{"@conversation/dantooine_rebel_trainer_2:s_2ca477ff", "m4_later"}, -- I can't right now, Vrovel. I have things to do.
		{"@conversation/dantooine_rebel_trainer_2:s_9793aadf", "m4_project"}, -- Finally! What is it all about?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_offer)

vrovel_convo_m4_short_version = ConvoScreen:new {
	id = "m4_short_version",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8bc4846e", -- There is no such thing as the short version, %NU. You need to understand what we are dealing with here.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_777420ae", "m4_project"}, -- Alright, alright, go on.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_short_version)

vrovel_convo_m4_later = ConvoScreen:new {
	id = "m4_later",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_451de7ba", -- You better take care of your business quick, %NU. We are running out of time!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_later)

vrovel_convo_m4_project = ConvoScreen:new {
	id = "m4_project",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_84d88402", -- The Empire is creating a new type of star fighter. It is a combination of a pilot and his ship. The technicians meld the pilot into the ship with cybernetics. They become one. The Force crystals keep the abomination alive. The crystals do other things as well; we don't fully understand them yet.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_8c4fba26", "m4_madness"}, -- That's madness! Pilots give up their lives to fly that thing?
		{"@conversation/dantooine_rebel_trainer_2:s_2d54810a", "m4_desperate"}, -- Guess the Empire is desperate to find some decent pilots.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_project)

vrovel_convo_m4_madness = ConvoScreen:new {
	id = "m4_madness",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_bed2d9a5", -- I doubt that they volunteer for it, %NU... This has to be stopped, for the good of the galaxy and all that is just. We need to find out where this criminal activity takes place. We may have a lead.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9dbb5a9a", "m4_plan"}, -- What is the plan?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_madness)

vrovel_convo_m4_desperate = ConvoScreen:new {
	id = "m4_desperate",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_4c539d9e", -- I would laugh with you, if it wasn't so horrific %NU. We have to find out where this research is taking place. We may have a lead.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_fcf4d778", "m4_plan"}, -- How?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_desperate)

vrovel_convo_m4_plan = ConvoScreen:new {
	id = "m4_plan",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_ee59d5b1", -- The SpyNet has identified one of the officers working on this project. They've even provided us with his travel route. He's on his way to the Star Destroyer in the Dantooine system. We have laid out an intercept course. You need to disable his shuttle. You can find the starting location in your onboard nav computer.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_16d870fe", "m4_accept"}, -- Consider it done.
		{"@conversation/dantooine_rebel_trainer_2:s_9b291e2", "m4_wait"}, -- I can't right now. Can it wait?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_plan)

vrovel_convo_m4_accept = ConvoScreen:new {
	id = "m4_accept",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_49003628", -- I hope so %NU, for all of us. Here are the intercept coordinates. If he's not there, search the nearby area and pray that he didn't get past you. Best of luck, my friend.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_accept)

vrovel_convo_m4_wait = ConvoScreen:new {
	id = "m4_wait",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_31f985f7", -- No! Wrap up your business immediately. We can't let this opportunity slip by.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m4_wait)

vrovel_convo_m3_won = ConvoScreen:new {
	id = "m3_won",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_e6de2bcb", -- I understand that the smuggler arrived safely at Lok. Very well done, %NU. I'm glad we didn't have to take any extreme measures. Here's your completion bonus. Get some rest. You deserve it.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_4d99132b", "m3_lucky"}, -- Thank you, sir. I'll be back shortly.
		{"@conversation/dantooine_rebel_trainer_2:s_93f5b2e2", "m3_duty_work"}, -- Rest? Bah! I'm ready for action!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_won)

vrovel_convo_m3_lucky = ConvoScreen:new {
	id = "m3_lucky",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_9694dc98", -- Good. %NU, the Alliance is lucky to have you.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_lucky)

vrovel_convo_m3_duty_work = ConvoScreen:new {
	id = "m3_duty_work",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_5cde55e2", -- If you say so. We have some duty work.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_e02f4f90", "duty_menu"}, -- Excellent! Give me the rundown.
		{"@conversation/dantooine_rebel_trainer_2:s_52eb52dc", "m3_spend_bonus"}, -- On second thought, think I'll spend some of this bonus.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_duty_work)

vrovel_convo_m3_spend_bonus = ConvoScreen:new {
	id = "m3_spend_bonus",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_46f83a2d", -- That's the %NU I know. Come back when you're ready. But don't take too long! There's a lot of work to do.
	stopConversation = "true",
	animation = "belly_laugh",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_spend_bonus)

vrovel_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_e8baa9a9", -- I heard of your misfortune, %TU. I have some good news, though. The clever smuggler managed to avoid capture. He escaped in a pod. Now we will get a second chance. Are you ready %NU?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_e3516195", "m3_retry"}, -- Excellent. Payback time!
		{"@conversation/dantooine_rebel_trainer_2:s_5d243499", "m3_coward"}, -- I'm not going back into that death trap!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_failed)

vrovel_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_a82e4fe0", -- Indeed. Here are the new coordinates. Hopefully you will be able to slip by undetected this time.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_retry)

vrovel_convo_m3_coward = ConvoScreen:new {
	id = "m3_coward",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_739ccb66", -- You disappoint me, %TU. I didn't take you for a coward.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_coward)

vrovel_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_4d4bd15c", -- We have a problem, %NU. The smuggler that sold you the information in Yavin has been captured by the Empire. They are transporting him to an interrogator as we speak. We have to save him!
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_aa05c8e8", "m3_knows_data"}, -- What does it matter? We have what we needed from him.
		{"@conversation/dantooine_rebel_trainer_2:s_db0d4bc2", "m3_wonder"}, -- Who cares! I have other things to attend to.
		{"@conversation/dantooine_rebel_trainer_2:s_3aa053cf", "m3_where"}, -- Where is he?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_offer)

vrovel_convo_m3_knows_data = ConvoScreen:new {
	id = "m3_knows_data",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_71eef77f", -- Yes, but he knows what was in that data. Under no circumstances can the Empire be allowed to find out what we know about their research project.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f520dc9f", "m3_find_him"}, -- Agreed. Where do I find him?
		{"@conversation/dantooine_rebel_trainer_2:s_dedb7d52", "m3_orders"}, -- I suppose. So what do you want me to do?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_knows_data)

vrovel_convo_m3_wonder = ConvoScreen:new {
	id = "m3_wonder",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_624d0dce", -- Sometimes I wonder what is going on inside that head of yours, %TU.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_wonder)

vrovel_convo_m3_where = ConvoScreen:new {
	id = "m3_where",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_5459b64", -- He's being transported from Yavin 4 right now. You need to disable his prison transport and unlock his energy cell by hacking into the ship's computer. Then he can take control of the ship and head for safety. Under no circumstances can he fall into Empire hands - even if it means his death. Do I make myself clear?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_ca3670fd", "m3_accept_wartime"}, -- Very.
		{"@conversation/dantooine_rebel_trainer_2:s_c6af7ee", "m3_save_him"}, -- Killing civilians is not my style, Vrovel.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_where)

vrovel_convo_m3_find_him = ConvoScreen:new {
	id = "m3_find_him",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_92364805", -- He's being transported from Yavin 4 right now. You need to disable the prison transport and unlock his energy cell. You can accomplish this by hacking into the ship's computer. Once you've done that, he can take control of the ship and head for safety. He cannot fall into the hands of the Imperial interrogators, even if it means that he doesn't make it at all. Understood?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_a30c1a53", "m3_accept_yes_sir"}, -- Yes sir!
		{"@conversation/dantooine_rebel_trainer_2:s_b4922a9d", "m3_this_is_war"}, -- I can't do that...
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_find_him)

vrovel_convo_m3_orders = ConvoScreen:new {
	id = "m3_orders",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_7dc6a3c6", -- Intercept the prison transport in the Yavin system. Disable it and unlock the smuggler's energy cell by hacking in to the ship's computer. He CANNOT fall into Empire hands. Do I make myself clear?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_261519e4", "m3_accept_terminate"}, -- Sure. Maybe I should just terminate him right away, just to be safe?
		{"@conversation/dantooine_rebel_trainer_2:s_b4922a9d", "m3_this_is_war"}, -- I can't do that...
		{"@conversation/dantooine_rebel_trainer_2:s_ca3670fd", "m3_accept_very"}, -- Very.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_orders)

vrovel_convo_m3_accept_wartime = ConvoScreen:new {
	id = "m3_accept_wartime",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_78de5e19", -- Good. As much as it pains me to make decisions like this, this is what you have to do in wartime. Here are the intercept coordinates of the prison transport in Yavin. May the Force be with you, %NU.
	stopConversation = "true",
	animation = "wave1",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_accept_wartime)

vrovel_convo_m3_save_him = ConvoScreen:new {
	id = "m3_save_him",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_64fbc05f", -- Then you better save him, %NU! This pains me as well, but under no circumstances can the Empire learn how much we know about their research project!
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_2c4789b", "m3_accept_understood"}, -- Understood.
		{"@conversation/dantooine_rebel_trainer_2:s_b4922a9d", "m3_reconsider"}, -- I can't do that...
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_save_him)

vrovel_convo_m3_accept_yes_sir = ConvoScreen:new {
	id = "m3_accept_yes_sir",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_729c6465", -- Good. You can intercept the prison transport at these coordinates in the Yavin system. May the Force be with you, %NU.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_accept_yes_sir)

vrovel_convo_m3_this_is_war = ConvoScreen:new {
	id = "m3_this_is_war",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_524b8ce7", -- This is war, %NU! You have some time to reconsider. But if you don't, I may have to reassign you to another part of the navy.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_this_is_war)

vrovel_convo_m3_accept_terminate = ConvoScreen:new {
	id = "m3_accept_terminate",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_7ca73534", -- Sometimes I wonder if you are on the right side in this war, %TU. We don't attack civilians unless it's absolutely necessary. Now get yourself over to the Yavin system and save this man from the Empire's clutches!
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_accept_terminate)

vrovel_convo_m3_accept_very = ConvoScreen:new {
	id = "m3_accept_very",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_48235568", -- Good. You can intercept the transport at these coordinates in the Yavin system. May the Force be with you, %NU.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_accept_very)

vrovel_convo_m3_accept_understood = ConvoScreen:new {
	id = "m3_accept_understood",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_339b44ad", -- Good. Intercept his prison transport at this location in the Yavin system. Good luck, and may the Force be with you, %TU.
	stopConversation = "true",
	animation = "wave1",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_accept_understood)

vrovel_convo_m3_reconsider = ConvoScreen:new {
	id = "m3_reconsider",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_9eadc5d9", -- This is war, %NU! You have some time to reconsider.  But if you don't, I may have to reassign you to another part of the navy.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m3_reconsider)

vrovel_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d6450824", -- Fantastic performance, %NU! We will soon find out what this is all about and how we can disrupt the Empire's plans.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_fe92f35f", "m2_pay_rest"}, -- Thank you, sir. What happens now?
		{"@conversation/dantooine_rebel_trainer_2:s_235bfb27", "m2_pay_bonus"}, -- Wasn't exactly difficult. Where's my bonus?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_won)

vrovel_convo_m2_pay_rest = ConvoScreen:new {
	id = "m2_pay_rest",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_561c250a", -- You should get some rest and then fly some duties while we put our plans together. Here's your completion bonus for a job well done. See you soon, %NU.
	stopConversation = "true",
	animation = "wave1",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_pay_rest)

vrovel_convo_m2_pay_bonus = ConvoScreen:new {
	id = "m2_pay_bonus",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_15c6406b", -- If you weren't such a good pilot...very well, here's the mission completion bonus.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_e997312f", "m2_now_what"}, -- Good, now what?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_pay_bonus)

vrovel_convo_m2_now_what = ConvoScreen:new {
	id = "m2_now_what",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_73bf51b7", -- Take some personal time or fly some duties while we formulate our plans.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_now_what)

vrovel_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_5a928bc", -- I'm glad you made it, %NU. I have a confession to make. We didn't send you out with the correct data.
	stopConversation = "false",
	animation = "nervous",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_900f01d1", "m2_confession"}, -- What?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_failed)

vrovel_convo_m2_confession = ConvoScreen:new {
	id = "m2_confession",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f11d138d", -- I'm sorry ,%NU. We couldn't risk the possibility of that data falling into Imperial hands. This attack against you confirmed that we have a traitor working against us. We wanted to draw him out. We did, thanks to you. Again, my apologies. I couldn't tell you.
	stopConversation = "false",
	animation = "refuse_offer_affection",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_b17504ae", "m2_trackers"}, -- This better lead to something, Vrovel. I almost died out there!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_confession)

vrovel_convo_m2_trackers = ConvoScreen:new {
	id = "m2_trackers",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f0c94176", -- Yes. I would not have been able to forgive myself had that happened. But I had confidence in your abilities. Now one of my most trusted men has gone over every inch of your ship, looking for trackers. This time I am the only one that will know your route and your mission. Will you indulge me and take the mission again, for real this time?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_24084ede", "m2_retry"}, -- I suppose. But this time I better be hauling the right data!
		{"@conversation/dantooine_rebel_trainer_2:s_304f442f", "m2_recover"}, -- I need some time to recover from my wounds.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_trackers)

vrovel_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_9c5e6360", -- Indeed you will. I'm very grateful the Alliance sent us such a honorable soldier. Be careful %NU. We can't afford to fail.
	stopConversation = "true",
	animation = "bow3",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_retry)

vrovel_convo_m2_recover = ConvoScreen:new {
	id = "m2_recover",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_5e7cd3e1", -- I understand %NU. But I hope you rest up quickly. We are running out of time.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_recover)

vrovel_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d9b0de0a", -- Great! I was looking for you, %NU. We've made a breakthrough. We've analyzed the Imperial research project information. It seems to include something about Force Crystals. We are not sure what it's all about yet, but that's what the material that their 'science team' has been extracting from Dantooine caves.
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_b91de387", "m2_brief"}, -- So what is my part in this, sir?
		{"@conversation/dantooine_rebel_trainer_2:s_8a5579fe", "m2_crystals"}, -- What are Force Crystals?
		{"@conversation/dantooine_rebel_trainer_2:s_dcf1ce97", "m2_busy"}, -- Not now, Vrovel; I'm busy.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_offer)

vrovel_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b712823e", -- We have very little information. But we've received word from one of Nym's smugglers in the Yavin system. He was examining some of the debris left from the Empire's destroyed space station. (Remember that explosion?) He apparently found some data there, relating to this same project.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_432be150", "m2_smuggle"}, -- Sounds good. Go on, sir.
		{"@conversation/dantooine_rebel_trainer_2:s_188656b1", "m2_calm_down"}, -- Doesn't explain what my part in this is.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_brief)

vrovel_convo_m2_crystals = ConvoScreen:new {
	id = "m2_crystals",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f2fabb27", -- It's a common term for crystals that emit powerful bursts of light when induced by resonant frequencies. In the past, they were used by the Jedi Knights to construct their lightsabers. Although rare, they can still be found in different areas of the galaxy.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_de6ce73a", "m2_why_crystals"}, -- Why would the Empire want these crystals?
		{"@conversation/dantooine_rebel_trainer_2:s_48398692", "vortex_name"}, -- Okay, I think it's time you explain what the Vortex is.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_crystals)

vrovel_convo_m2_busy = ConvoScreen:new {
	id = "m2_busy",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_c358c931", -- Hmph. Well, you need to get un-busy and get back to me quickly. This is a high-priority task!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_busy)

vrovel_convo_m2_smuggle = ConvoScreen:new {
	id = "m2_smuggle",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_ed422a6f", -- You need to smuggle our data to Yavin and meet up with one of our scientists who is stationed there. He has purchased the smuggler's information. He will try to make sense of the different pieces of data.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_b74318f4", "m2_accept"}, -- I will do my best, sir.
		{"@conversation/dantooine_rebel_trainer_2:s_dd108499", "m2_not_playing"}, -- I can't go to Yavin right now. I will be back as soon as I can.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_smuggle)

vrovel_convo_m2_calm_down = ConvoScreen:new {
	id = "m2_calm_down",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_861734b9", -- If you calm down and let me finish, I'll explain everything. One of our scientists is on his way to meet the smuggler at a space station in the Yavin system now. You need to take the information to that base and meet with our scientist. He will purchase the smuggler's data, compare it to your data, and see if he can't make some kind of connection.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_73ff6c2b", "m2_accept"}, -- That's it? No problem.
		{"@conversation/dantooine_rebel_trainer_2:s_e2b7d84c", "m2_coward"}, -- I don't think so. That place is crawling with Imperials.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_calm_down)

vrovel_convo_m2_why_crystals = ConvoScreen:new {
	id = "m2_why_crystals",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_1fd8891b", -- That's what we want to find out. And with your help, we shall succeed %NU.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_8631d353", "m2_brief"}, -- All right. What is my mission?
		{"@conversation/dantooine_rebel_trainer_2:s_48398692", "vortex_name"}, -- Okay, I think it's time you explain what the Vortex is.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_why_crystals)

vrovel_convo_vortex_name = ConvoScreen:new {
	id = "vortex_name",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_65ce28c1", -- Hmm. Yes, I suppose you are right. The Vortex is the name of the planet where our agency was formed. We have since relocated many times to avoid the Imperial Inquisition, but our goal remains the same.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_e5546db1", "vortex_goal"}, -- And what is that goal?
		{"@conversation/dantooine_rebel_trainer_2:s_ff86e506", "vortex_inquisition"}, -- Why is the Inquisition so interested in your activities?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_name)

vrovel_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_605dfe75", -- Be careful. If this data falls into the hands of the Empire, it is lost forever. Stay sharp out there, %NU.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_accept)

vrovel_convo_m2_not_playing = ConvoScreen:new {
	id = "m2_not_playing",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_303fc274", -- We are not playing games here, %NU! You need to hurry up and finish what it is you have to do so that you can get underway on this project immediately.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_not_playing)

vrovel_convo_m2_coward = ConvoScreen:new {
	id = "m2_coward",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_e244bb48", -- I didn't think you were a coward, %TU! Maybe I should rethink your place here.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m2_coward)

vrovel_convo_vortex_goal = ConvoScreen:new {
	id = "vortex_goal",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_dea568e", -- We investigate anything relating to the Force or the ancient Jedi Knights. Our hope is to find Jedi to aid us in the war against the Empire and to learn as much as we can about the Force. Many people in the Alliance think our group is absurd.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_4cf117bb", "vortex_jedi_exist"}, -- How come?
		{"@conversation/dantooine_rebel_trainer_2:s_ef95a2b0", "vortex_jedi_myth"}, -- I might agree with them, Jedi were a myth, last I heard.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_goal)

vrovel_convo_vortex_inquisition = ConvoScreen:new {
	id = "vortex_inquisition",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_bd1936e2", -- They want to confiscate our library. It holds decades of information, gathered from all corners of the galaxy, on anything relating to the Force.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_507325ab", "vortex_goal"}, -- Understood. And what does the Vortex hope to accomplish?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_inquisition)

vrovel_convo_vortex_jedi_exist = ConvoScreen:new {
	id = "vortex_jedi_exist",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_dcece74b", -- Not many believe in the Force. Or they think that all the Jedi have been exterminated by the Empire. If that was true, though, why is the Empire wasting millions of credits on Jedi hunts? No, my friend, the Jedi still exist. In fact, we have found a few already - and we've convinced them  to join the Alliance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_1f3a637e", "vortex_jedi_few"}, -- There are Jedi working for the Rebel Alliance?
		{"@conversation/dantooine_rebel_trainer_2:s_f0eba675", "m2_brief"}, -- Very interesting. So what's my mission?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_jedi_exist)

vrovel_convo_vortex_jedi_myth = ConvoScreen:new {
	id = "vortex_jedi_myth",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_a9c811de", -- If that was true, though, why is the Empire wasting millions of credits on Jedi hunts? No, my friend, the Jedi still exist. In fact, we have found a few already - and we've convinced them  to join the Alliance.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_1f3a637e", "vortex_jedi_few"}, -- There are Jedi working for the Rebel Alliance?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_jedi_myth)

vrovel_convo_vortex_jedi_few = ConvoScreen:new {
	id = "vortex_jedi_few",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8bb57c8b", -- Yes, only but a few. And so far, they are mostly untrained Jedi. It's hard for us to train them, as the only information we have available is from old documents that are often hard to comprehend. We are making more and more progress, however.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f0eba675", "m2_brief"}, -- Very interesting. So what's my mission?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_vortex_jedi_few)

vrovel_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_2faaa2e5", -- Did I give you the wrong location or something? Let me double-check your datapad.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f4f48ced", "m1_retry"}, -- Yeah, something must be wrong.
		{"@conversation/dantooine_rebel_trainer_2:s_d5273669", "m1_hurry_back"}, -- I don't have time right now. I will be back.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_failed)

vrovel_convo_m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_6a1fe0ee", -- All fixed. Make haste for the Lok system.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_retry)

vrovel_convo_m1_hurry_back = ConvoScreen:new {
	id = "m1_hurry_back",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_c2eb0440", -- Well hurry back. We need your skills for this!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_hurry_back)

vrovel_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f204572b", -- Glad to have you back in one piece, %NU. We were worried there for a while. It's apparent that someone set you up. We are trying to figure out who that someone is. The Inquisitor onboard the ship was probably going to try and force you to bring him to me. Anyway, here's your completion bonus.
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_266422af", "m1_setup"}, -- Thank you, sir. So what happens now?
		{"@conversation/dantooine_rebel_trainer_2:s_73b1dbda", "m1_spend_bonus"}, -- I'll be back. It's time to put this bonus to good use.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_won)

vrovel_convo_m1_setup = ConvoScreen:new {
	id = "m1_setup",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_df11a579", -- Well, even though it was a setup, it had some truth to it and we might have found a second source from which to retrieve the information.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_b8b49994", "m1_not_yet"}, -- So when do I take off?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_setup)

vrovel_convo_m1_spend_bonus = ConvoScreen:new {
	id = "m1_spend_bonus",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_266c4054", -- Haha! Well, don't take too long. We have a lot of work to do still, and we will need your expertise soon again.
	stopConversation = "true",
	animation = "laugh",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_spend_bonus)

vrovel_convo_m1_not_yet = ConvoScreen:new {
	id = "m1_not_yet",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b2e20726", -- Not yet, my friend. We are still analyzing our information. Take on a few duties and get some more experience under your belt.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9d33db7", "duty_menu"}, -- All right. What duties are available?
		{"@conversation/dantooine_rebel_trainer_2:s_dcc384fa", "m1_attitude"}, -- Bah! Menial tasks like that are worthless.
		{"@conversation/dantooine_rebel_trainer_2:s_a1e6b9f4", "m1_practice"}, -- I can't right now, but I will be back as soon as possible.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_not_yet)

vrovel_convo_m1_attitude = ConvoScreen:new {
	id = "m1_attitude",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_3890da84", -- If you're going to succeed, you need to be the best pilot out there - better than any Imperial pilot! An attitude like that won't do! You have to constantly sharpen your skills, %TU!
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_aaf61b87", "duty_menu"}, -- Fine, what tasks are available right now?
		{"@conversation/dantooine_rebel_trainer_2:s_330ba710", "m1_trust_misplaced"}, -- Bah, I don't have time for this. I'll be back.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_attitude)

vrovel_convo_m1_practice = ConvoScreen:new {
	id = "m1_practice",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_55a5f573", -- Okay. Just don't let your piloting skills slip; we will need them more than ever now. Practice every chance you get.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_practice)

vrovel_convo_m1_trust_misplaced = ConvoScreen:new {
	id = "m1_trust_misplaced",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_fb5d75c8", -- I'm starting to think that my trust in you was misplaced, %TU.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_trust_misplaced)

vrovel_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_5b12c8f8", -- There you are! Just in time. This is the real deal, %NU. We have learned that the Empire is starting a new research project. It is of particular interest to us. A Rebel Officer on Lok has asked us to send a pilot to help retrieve more information.
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_90297a58", "m1_no_time"}, -- Wait! You promised to tell me what the Vortex is about.
		{"@conversation/dantooine_rebel_trainer_2:s_9a079bb1", "m1_project"}, -- What is this research project?
		{"@conversation/dantooine_rebel_trainer_2:s_77213dae", "m1_finn"}, -- Alright, where do I go and who am I meeting?
		{"@conversation/dantooine_rebel_trainer_2:s_e9c1932", "m1_urgent"}, -- I'm sorry, I can't right now. I'll be back.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_offer)

vrovel_convo_m1_no_time = ConvoScreen:new {
	id = "m1_no_time",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_13aaae57", -- There is no time now, my young friend. I will give you the answers soon. But for now, your presence is needed in the Lok system, %TU.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9805ba81", "m1_project"}, -- Alright, but what is this research project?
		{"@conversation/dantooine_rebel_trainer_2:s_77213dae", "m1_finn"}, -- Alright, where do I go and who am I meeting?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_no_time)

vrovel_convo_m1_project = ConvoScreen:new {
	id = "m1_project",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_1e45ad6c", -- We have very little information, which is where you come in, my friend. You have to travel to the Lok system immediately.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_f2a21231", "m1_finn"}, -- Alright. Who do I meet and where?
		{"@conversation/dantooine_rebel_trainer_2:s_3436f186", "m1_no_time"}, -- Wait. You promised to tell me what the Vortex is about!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_project)

vrovel_convo_m1_finn = ConvoScreen:new {
	id = "m1_finn",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_dad7c05e", -- There's a Rebel operative named Finn Darktrin stationed at Lok. He will rendezvous with you. He has information on the location and ship signature of an Imperial shuttle. It's carrying a scientist - and he is working on this project. We need to capture that scientist and interrogate him.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_92aee067", "m1_accept"}, -- Consider it done, sir.
		{"@conversation/dantooine_rebel_trainer_2:s_3360046f", "m1_moisture"}, -- I don't have time to go to Lok right now.
		{"@conversation/dantooine_rebel_trainer_2:s_9a079bb1", "m1_project"}, -- What is this research project?
		{"@conversation/dantooine_rebel_trainer_2:s_3436f186", "m1_no_time"}, -- Wait. You promised to tell me what the Vortex is about!
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_finn)

vrovel_convo_m1_urgent = ConvoScreen:new {
	id = "m1_urgent",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_c4279134", -- This is urgent %NU! Whatever it is you need to do, do it quickly.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_urgent)

vrovel_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_4c86e37b", -- Excellent. May the force be with you, %TU.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_accept)

vrovel_convo_m1_moisture = ConvoScreen:new {
	id = "m1_moisture",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_3e1fc046", -- What?! This is of the utmost importance. If you continue to disappoint me like this, I will have you working a moisture harvester on Tatooine for the rest of your career. Get out of here and don't come back until you're ready to work!
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_m1_moisture)

vrovel_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8917475d", -- Welcome back, %NU. You have acquired some experience in our ways and I believe you are ready for some training. Are you willing?
	stopConversation = "false",
	animation = "bow3",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9b8d2abd", "training_menu"}, -- I would like some training. What can you teach me?
		{"@conversation/dantooine_rebel_trainer_2:s_2e18346d", "training_declined"}, -- I don't have time right now.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_training_offer)

vrovel_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_c5b76777", -- You have earned enough experience to advance to the next level in one of the following fields.
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_c6c91897", "train_starships"}, -- Multi-Role Craft
		{"@conversation/dantooine_rebel_trainer_2:s_98d991e7", "train_weapons"}, -- Weapons B, Intermediate Alliance Starship Ordnance
		{"@conversation/dantooine_rebel_trainer_2:s_73ccefde", "train_procedures"}, -- Space Combat Techniques
		{"@conversation/dantooine_rebel_trainer_2:s_3c4ff185", "train_droid"}, -- Reactor Engineering Algorithms
		{"@conversation/dantooine_rebel_trainer_2:s_75a6ca67", "training_later"}, -- None right now, thank you. I have some other things to attend to.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_training_menu)

vrovel_convo_training_declined = ConvoScreen:new {
	id = "training_declined",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_82930541", -- All right. But we need your help, so don't take too long, %NU.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_training_declined)

vrovel_convo_train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_4b9a2c6f", -- This is what you want us to teach you?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_6bb0cb94", "trained_starships"}, -- Correct.
		{"@conversation/dantooine_rebel_trainer_2:s_4c1dac60", "training_menu"}, -- Hold on, what choices did I have again?
	}
}
vrovel_convo_template:addScreen(vrovel_convo_train_starships)

vrovel_convo_train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_80f24a30", -- This is the one? You're sure?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_bb87cc7c", "trained_weapons"}, -- One hundred percent, sir.
		{"@conversation/dantooine_rebel_trainer_2:s_65c36194", "training_later"}, -- On second thought, no.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_train_weapons)

vrovel_convo_train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_92ddd562", -- You are sure of this?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_d5ff7cb2", "trained_procedures"}, -- Yes, definitely.
		{"@conversation/dantooine_rebel_trainer_2:s_d8fef41", "training_later"}, -- Perhaps not...
	}
}
vrovel_convo_template:addScreen(vrovel_convo_train_procedures)

vrovel_convo_train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d88c653e", -- Are you sure?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_98bb41ea", "trained_droid"}, -- Indeed.
		{"@conversation/dantooine_rebel_trainer_2:s_ef759e6d", "training_menu"}, -- No wait, let me reconsider.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_train_droid)

vrovel_convo_training_later = ConvoScreen:new {
	id = "training_later",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_d8841255", -- Very well. But hurry back. We need to get this operation under way.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_training_later)

vrovel_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_1b8807cc", -- Very well. I will have one of the pilots instruct you. When you are ready, come back to me. An urgent situation is developing. I could use your newly acquired skills.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_trained_starships)

vrovel_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_1b8807cc", -- Very well. I will have one of the pilots instruct you. When you are ready, come back to me. An urgent situation is developing. I could use your newly acquired skills.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_trained_weapons)

vrovel_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_820a0ee7", -- Very well, I will have one of the pilots teach you. When you are ready, come back to me. An urgent situation is developing. I could use your newly acquired skills.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_trained_procedures)

vrovel_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_820a0ee7", -- Very well, I will have one of the pilots teach you. When you are ready, come back to me. An urgent situation is developing. I could use your newly acquired skills.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_trained_droid)

vrovel_convo_duty_offer = ConvoScreen:new {
	id = "duty_offer",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_2ba96f57", -- Good to see you, %NU. Ready to hear the list of active duties?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9b43a7ee", "duty_menu"}, -- Yes sir.
		{"@conversation/dantooine_rebel_trainer_2:s_6b054777", "duty_later"}, -- Not right now, I have some things to attend to.
		{"@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu"}, -- I'm a Developer/Tester and want missions.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_offer)

vrovel_convo_duty_later = ConvoScreen:new {
	id = "duty_later",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_7c61dac0", -- Very well but hurry back, there's lots to do and little time, as always.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_later)

vrovel_convo_private_property = ConvoScreen:new {
	id = "private_property",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_3475f83d", -- Please leave. This is private property. Thank you.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_6b158a0e", "gm_menu_sectors"}, -- I'm a Developer/Tester and want missions.
		{"@conversation/dantooine_rebel_trainer_2:s_6f6eeaf3", "private_goodbye"}, -- Fine, goodbye.
		{"@conversation/dantooine_rebel_trainer_2:s_9f0a282", "private_leave"}, -- Say please? Oh you did. Never mind.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_private_property)

vrovel_convo_private_goodbye = ConvoScreen:new {
	id = "private_goodbye",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_e6772f13", -- Goodbye.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_private_goodbye)

vrovel_convo_private_leave = ConvoScreen:new {
	id = "private_leave",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_a6720368", -- Okay, you can leave now.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_private_leave)

vrovel_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_62726774", -- We have some freighters requiring escort past Imperial patrols. We also have a few opportunities to hijack Imperial ships, and of course we could launch some guerilla strikes on Imperial Scout patrols. We want you to assist with these duties until we feel you have enough experience to proceed with your training. But they operate on a volunteer basis and can be aborted at any time.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_9828194f", "duty_escort"}, -- I'll help you with some escort tasks.
		{"@conversation/dantooine_rebel_trainer_2:s_a7fb8221", "duty_recovery"}, -- Hijacking Imperial ships! That sounds exciting.
		{"@conversation/dantooine_rebel_trainer_2:s_948462ad", "duty_destroy"}, -- Not many can stand toe-to-toe in a dogfight with me. Where are these guys?
		{"@conversation/dantooine_rebel_trainer_2:s_cd1a5817", "duty_menu_later"}, -- I have some quick things I need to fix first. I will be back.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_menu)

vrovel_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b21d8dfe", -- Good. I will tell our freighters and shuttles where they can meet-up with you. When you feel that you have learned our routes well enough, come back and see me. If you think you have enough experience, let me know and we will teach you a few of our skills. Good luck, %TU.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_escort)

vrovel_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_360d72eb", -- Indeed. I will have the locations of the Imperial ships transmitted to you above orbit. Come back and see me later for different duties. Or, if you feel that you have enough experience, let me know and we will teach you some of our skills. Good luck out there %TU.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_recovery)

vrovel_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_16e68393", -- If you can stand up to that firepower, I will be most pleased. We will transmit locations as we find them once you enter orbit. Come find me after you (or your ship) need a break and pick a new assignment. If you feel experienced enough, let us know and we'll teach you some of our skills. Go get them %TU.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_destroy)

vrovel_convo_duty_menu_later = ConvoScreen:new {
	id = "duty_menu_later",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_b09129f6", -- Alright. But hurry, this is not a vacation.
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_duty_menu_later)

vrovel_convo_gm_menu = ConvoScreen:new {
	id = "gm_menu",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_9ffd1405", -- Which mission?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_165db597", "gm_mission1_plain"}, -- I want mission 1.
		{"@conversation/dantooine_rebel_trainer_2:s_64b6ea44", "gm_mission2"}, -- I want mission 2.
		{"@conversation/dantooine_rebel_trainer_2:s_b6af2b98", "gm_mission3"}, -- I want mission 3.
		{"@conversation/dantooine_rebel_trainer_2:s_816055e2", "gm_mission4"}, -- I want mission 4.
		{"@conversation/dantooine_rebel_trainer_2:s_2c008858", "gm_escort_duty"}, -- I want Escort Duty.
		{"@conversation/dantooine_rebel_trainer_2:s_7a128ed0", "gm_recovery_duty"}, -- I want Recovery Duty.
		{"@conversation/dantooine_rebel_trainer_2:s_544003d6", "gm_destroy_duty"}, -- I want Destroy Duty.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_menu)

vrovel_convo_gm_menu_sectors = ConvoScreen:new {
	id = "gm_menu_sectors",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_9ffd1405", -- Which mission?
	stopConversation = "false",
	options = {
		{"@conversation/dantooine_rebel_trainer_2:s_165db597", "gm_mission1"}, -- I want mission 1.
		{"@conversation/dantooine_rebel_trainer_2:s_64b6ea44", "gm_mission2"}, -- I want mission 2.
		{"@conversation/dantooine_rebel_trainer_2:s_b6af2b98", "gm_mission3"}, -- I want mission 3.
		{"@conversation/dantooine_rebel_trainer_2:s_816055e2", "gm_mission4"}, -- I want mission 4.
		{"@conversation/dantooine_rebel_trainer_2:s_2c008858", "gm_escort_duty"}, -- I want Escort Duty.
		{"@conversation/dantooine_rebel_trainer_2:s_7a128ed0", "gm_recovery_duty"}, -- I want Recovery Duty.
		{"@conversation/dantooine_rebel_trainer_2:s_544003d6", "gm_destroy_duty"}, -- I want Destroy Duty.
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_menu_sectors)

vrovel_convo_gm_mission1_plain = ConvoScreen:new {
	id = "gm_mission1_plain",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_mission1_plain)

vrovel_convo_gm_mission2 = ConvoScreen:new {
	id = "gm_mission2",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8b97769", -- Very well. Escort in Yavin sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_mission2)

vrovel_convo_gm_mission3 = ConvoScreen:new {
	id = "gm_mission3",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_8b6b8696", -- Very well. Recovery in Yavin sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_mission3)

vrovel_convo_gm_mission4 = ConvoScreen:new {
	id = "gm_mission4",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_c763dbaa", -- Very well. Inspect in Dantooine sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_mission4)

vrovel_convo_gm_escort_duty = ConvoScreen:new {
	id = "gm_escort_duty",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_escort_duty)

vrovel_convo_gm_recovery_duty = ConvoScreen:new {
	id = "gm_recovery_duty",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_recovery_duty)

vrovel_convo_gm_destroy_duty = ConvoScreen:new {
	id = "gm_destroy_duty",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_destroy_duty)

vrovel_convo_gm_mission1 = ConvoScreen:new {
	id = "gm_mission1",
	leftDialog = "@conversation/dantooine_rebel_trainer_2:s_3080e198", -- Very well. Escort in Lok sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
vrovel_convo_template:addScreen(vrovel_convo_gm_mission1)

addConversationTemplate("vrovel_convo_template", vrovel_convo_template)
