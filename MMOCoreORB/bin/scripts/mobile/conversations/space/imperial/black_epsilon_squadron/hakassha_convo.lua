-- Hakassha Sireen (Black Epsilon tier 1) conversation; ported from SWG-Source corellia_imperial_trainer_1.java with the pre-NGE client lines (feature black-epsilon-tier1-hakassha). Handler: hakasshaConvoHandler.
hakassha_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "hakasshaConvoHandler",
	screens = {}
}

-- Help loop (the player has not finished the first mission)
hakassha_convo_help_where = ConvoScreen:new {
	id = "help_where",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_59a0de2a", -- First you need to go to the starport. Once you get there, you will need to go inside and look for a 'starship terminal.' They tend to be in the big main area right past the foyer. When you find a terminal, use it to 'launch' your ship into space.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_where)

hakassha_convo_help_what = ConvoScreen:new {
	id = "help_what",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_16a81f", -- Well, sweetie - after you find the starport, and use the starship terminal to launch into space, you'll need to finish your mission... I thought we were clear on that, hon.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_what)

hakassha_convo_help_return = ConvoScreen:new {
	id = "help_return",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3b421b4c", -- When the mission is over, and you're all safe and sound, go to the nearest space station. You'll need to get landing clearance from the space station - so comm the station commander and tell her you'd like to land.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_4738e99f", "help_station"}, -- How do I find a space station?
		{"@conversation/corellia_imperial_trainer_1:s_9288900f", "help_understood"}, -- I understand.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_return)

hakassha_convo_help_ship = ConvoScreen:new {
	id = "help_ship",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_4bb6ea28", -- Your ship is parked at a starport. I've given you the control codes for a basic TIE fighter by uploading them to your personal datapad. Check your datapad to review your ship status whenever you'd like, sweetie.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_ship)

hakassha_convo_help_station = ConvoScreen:new {
	id = "help_station",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f4547ad0", -- Your ship navigation system will automatically create a 'launch waypoint' when you take off. Fly back to this point when your mission is over. However, if you're looking for a particular space station - open your space zone map. You'll find one there!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_station)

hakassha_convo_help_understood = ConvoScreen:new {
	id = "help_understood",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_9f128498", -- No doubt about that! What else can I tell you about?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_help_understood)

-- Lost ship
hakassha_convo_lost_ship_business = ConvoScreen:new {
	id = "lost_ship_business",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c4031ec5", -- Business it is then. I can issue you a new TIE fighter, but only the basic model. Are you sure that is what you want?
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_7f96a397", "lost_ship_declined"}, -- On second thought. No thanks.
		{"@conversation/corellia_imperial_trainer_1:s_67e76bed", "lost_ship_granted"}, -- Yes, please. I really need a new ship.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_lost_ship_business)

hakassha_convo_lost_ship_declined = ConvoScreen:new {
	id = "lost_ship_declined",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f02cd84d", -- Very well. Take care hon.
	stopConversation = "true",
	animation = "goodbye",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_lost_ship_declined)

hakassha_convo_lost_ship_granted = ConvoScreen:new {
	id = "lost_ship_granted",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b1f72a19", -- Here you are. Try not to lose this one.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_lost_ship_granted)

-- Off-track pilot: duty offer
hakassha_convo_non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c1024ba1", -- I'm sure you would, hon. As it so happens, I do have some elective duty missions, if you're interested.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b789ed1e", "duty_menu"}, -- I'm interested in a duty mission.
		{"@conversation/corellia_imperial_trainer_1:s_1acdc4ba", "non_member_declined"}, -- No, I'd rather not.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_non_member_duty_offer)

hakassha_convo_non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_aff8083e", -- And I'd like to give you one, but I'm afraid that I don't have anything you can do right now. Why don't you try speaking with your commanding officer?
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_non_member_no_missions)

-- Duty missions
hakassha_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_4dc7104e", -- Good, I have plenty of work for you. Pirate activity in the area is still fairly high. There are plenty of pirates to hunt or you could help escort transports moving supplies.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_13e807c3", "destroy_duty"}, -- [Destroy Duty] I'm interested in hunting more B-Wing Prototypes.
		{"@conversation/corellia_imperial_trainer_1:s_79ab4bbe", "escort_duty"}, -- [Escort Duty] I'm interested in escorting transports.
		{"@conversation/corellia_imperial_trainer_1:s_5ebce168", "duty_later"}, -- Actually, I'd like to do this later.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_menu)

hakassha_convo_non_member_declined = ConvoScreen:new {
	id = "non_member_declined",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3e935b51", -- Suit yourself, hon. Come and visit again sometime.
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_non_member_declined)

-- Series complete: hand-off to Prisk
hakassha_convo_nothing_to_teach = ConvoScreen:new {
	id = "nothing_to_teach",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f85e6621", -- There is nothing more that I can teach you hon. You need to move on in order to grow.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_nothing_to_teach)

hakassha_convo_transfer_to_prisk = ConvoScreen:new {
	id = "transfer_to_prisk",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_aac65592", -- I feared as much. I hate to lose someone with your obvious...talents, but the Emperor is in need of pilots with your skill. Prisk Kith'Vys has mentioned that he could use a good pilot, so I suggested you. He is roaming around here somewhere, just tell him that I sent you. Don't be fooled by his gruff, straightforward manner...he is really just a softy. Keep safe cutie.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_transfer_to_prisk)

hakassha_convo_promotion = ConvoScreen:new {
	id = "promotion",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_fb05d4a4", -- It's a promotion. Black Epsilon feels you've shown sufficient loyalty and skill to be elevated in rank. You'll be in charge of flying mission critical operations in this region. You may work directly with other agents of the Emperor.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_665a7735", "promotion_honored"}, -- I am honored.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_promotion)

hakassha_convo_promotion_honored = ConvoScreen:new {
	id = "promotion_honored",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_5e109aee", -- So you should be. There are very few active primary operatives in Black Epsilon. The Emperor himself is putting his faith and trust in you. I suppose it isn't necessary for me to say that failure would be punished harshly.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c602907a", "promotion_glory"}, -- I will not fail the Empire.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_promotion_honored)

hakassha_convo_promotion_glory = ConvoScreen:new {
	id = "promotion_glory",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_66f5a5c0", -- Glory for Emperor Palpatine! Go celebrate your promotion and come back when you're ready to get started on the next phase of your development.
	stopConversation = "true",
	animation = "pose_proudly",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_promotion_glory)

-- Training (pre-NGE two-step: topic, description, confirm)
hakassha_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_444df4b9", -- You can learn about Imperial technology, TIE weapons, Imperial operations, or astromech management.
	stopConversation = "false",
	animation = "explain",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_training_menu)

hakassha_convo_training_not_ready = ConvoScreen:new {
	id = "training_not_ready",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_eec1eeb4", -- You still have some work for me to do before I will train you. Okay, hon? Why don't you just finish up with what I am asking you to do? Then we will get you all trained up.
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_training_not_ready)

hakassha_convo_training_declined = ConvoScreen:new {
	id = "training_declined",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_1d0a2959", -- Hah, that's what you think! It's your choice, but you may not get this chance again. I suggest that you take it while you can.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_training_declined)

-- Duty explanation (after mission 4)
hakassha_convo_duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2ea86030", -- Duty missions are open ended assignments. They end when you choose to end them. For example, if I assign you the task of hunting B-Wing prototypes, you can destroy as many as you want. You can end the duty any time from the mission entry in your datapad. Perform duties to earn additional pay and experience.  Once you've received enough experience, I can teach you new skills.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b789ed1e", "duty_menu"}, -- I'm interested in a duty mission.
		{"@conversation/corellia_imperial_trainer_1:s_1091c96a", "duty_done_for_now"}, -- I'm done for now.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_explained)

hakassha_convo_no_training_xp = ConvoScreen:new {
	id = "no_training_xp",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7bff5a7f", -- You don't have the experience for training, yet.  Perform some more duties.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_no_training_xp)

hakassha_convo_enlist_ground = ConvoScreen:new {
	id = "enlist_ground",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_683cce3a", -- It is about time you sought a greater commitment to the Empire.  Seek out an Imperial Recruiter to join.  Keep in mind - even as a covert operative - you could be opening yourself to attack when you least expect it.
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_enlist_ground)

hakassha_convo_duty_done_for_now = ConvoScreen:new {
	id = "duty_done_for_now",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_88ffee3a", -- Report back to me when you are ready for some work.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_done_for_now)

hakassha_convo_destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_e3bb98c5", -- The Rebels still have prototype B-Wings in the system. Black Epsilon is paying agents a bounty for any that are destroyed. It helps our cause and it's a good way to hone your combat skills.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_7839f2d4", "duty_accepted"}, -- Consider them dead.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_destroy_duty)

hakassha_convo_escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_fb5547eb", -- We still have several key transports moving through the region on a regular basis. Most are ferrying operational supplies for us, but some are carrying equipment for other Imperial agencies. Black Epsilon will pay for every transport you escort safely.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_80d8485c", "duty_accepted"}, -- I'm on it.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_escort_duty)

hakassha_convo_duty_later = ConvoScreen:new {
	id = "duty_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7f8a87c", -- Alright, report back to me when you are ready.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_later)

hakassha_convo_duty_accepted = ConvoScreen:new {
	id = "duty_accepted",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_ee63dfa9", -- Report back to me when you would like a new duty or mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_accepted)

-- Mission 4: reward
hakassha_convo_mission4_won_close = ConvoScreen:new {
	id = "mission4_won_close",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f09f78be", -- I love it when you talk like that. The destruction of the prototype ship and all of the other trouble we've been causing should put the Rebels on high alert. A few more little pushes and they'll make the mistake we need to justify a full Imperial occupation of Corellia.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_15799d85", "mission4_reward"}, -- For the Emperor.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_won_close)

hakassha_convo_mission4_won_toast = ConvoScreen:new {
	id = "mission4_won_toast",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_e574a24f", -- The destruction of the prototype ship and all of the other trouble we've been causing should put the Rebels on high alert. A few more little pushes and they'll make the mistake we need to justify a full Imperial occupation of Corellia.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_659a2365", "mission4_pay"}, -- My pay?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_won_toast)

hakassha_convo_mission4_reward_head = ConvoScreen:new {
	id = "mission4_reward_head",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_219f04cc", -- For the Emperor, indeed. Here is your pay for the B-Wing mission. I've also gotten a hold of a TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions. Nevertheless, you've done an admirable job and Black Epsilon has taken note of your success.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6aae4cb", "mission4_cranial"}, -- Cranial proportions?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_reward_head)

hakassha_convo_mission4_reward = ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_54eaa333", -- For the Emperor, indeed. You've done an admirable job and Black Epsilon has taken note of your success. Here is your pay for the B-Wing mission. I've also gotten a hold of a TIE pilot helmet. It's pretty menacing, should make you feel more the part for these operations.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b9b27823", "mission4_reward_end"}, -- Thank you.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_reward)

hakassha_convo_mission4_cranial = ConvoScreen:new {
	id = "mission4_cranial",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_42dfe6db", -- Indeed. The Empire rarely enlists non-Humans as pilots, and so we are poorly prepared to equip someone such as yourself. But do not be discouraged. Your current standing in the Imperial Navy is a testament to your abilities.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b9b27823", "mission4_reward_end"}, -- Thank you.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_cranial)

hakassha_convo_mission4_reward_end = ConvoScreen:new {
	id = "mission4_reward_end",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_46405dbf", -- You've exceeded my expectations. Black Epsilon was right to recruit you. Come back when you are ready for more work.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_reward_end)

hakassha_convo_mission4_pay_head = ConvoScreen:new {
	id = "mission4_pay_head",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_23580c13", -- Here is your pay for the B-Wing mission. I've also gotten a hold of a TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6aae4cb", "mission4_cranial"}, -- Cranial proportions?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_pay_head)

hakassha_convo_mission4_pay = ConvoScreen:new {
	id = "mission4_pay",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_83dc5be7", -- Here is your pay for the B-Wing mission. I've also gotten a hold of a TIE pilot helmet. It looks pretty menacing, should make you feel more the part for these operations.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1cca067", "mission4_helmet"}, -- It's a little big...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_pay)

hakassha_convo_mission4_pay_end = ConvoScreen:new {
	id = "mission4_pay_end",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3599ff41", -- Pilot, you've exceeded my expectations. Black Epsilon was right to recruit you. With any luck, the Emperor's plans for this system will be fulfilled within the year. Come back when you are ready for more work.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_pay_end)

hakassha_convo_mission4_helmet = ConvoScreen:new {
	id = "mission4_helmet",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a65a372a", -- They are all that way. The helm contains an inertial dampening system that helps prevent blackouts during tactical maneuvers as well as various optical systems that integrate with the standard TIE flight interface.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_614b71f0", "mission4_pay_end"}, -- I see...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_helmet)

-- Mission 4: failed
hakassha_convo_mission4_failed_explain = ConvoScreen:new {
	id = "mission4_failed_explain",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3ac44381", -- Failure at this point is only going to encourage the Rebels to invest further in experimental ship designs. You need to get back up there and bag a B-Wing. Show the Rebels that technology isn't going to be their salvation.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ffba9145", "mission4_retry"}, -- I think I can take one out.
		{"@conversation/corellia_imperial_trainer_1:s_15588832", "mission4_later"}, -- I need some time to study the B-Wing operational logs.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_failed_explain)

hakassha_convo_mission4_retry = ConvoScreen:new {
	id = "mission4_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3ddbe3ce", -- Excellent. Let me know when you've done it.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_retry)

hakassha_convo_mission4_later = ConvoScreen:new {
	id = "mission4_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_d0803d68", -- Good idea. Let me know when you're ready to get back up there and try again.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_later)

-- Mission 4: briefing
hakassha_convo_mission4_brief = ConvoScreen:new {
	id = "mission4_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_540bd789", -- Apparently the Rebels are testing a new prototype starfighter called the B-Wing. It's a heavy assault fighter, loaded with weapons and layered in armor. B-Wing prototypes have been spotted in the Corellian system. We want you to find one and destroy it.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_801033a0", "mission4_capture"}, -- Destroy it? Why not capture it?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_brief)

hakassha_convo_mission4_training_deal = ConvoScreen:new {
	id = "mission4_training_deal",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_6942389e", -- And you've earned it!  I'll make a deal with you, %NU.  Do just one more assignment for me, and I'll train you to be a better starfighter pilot.  Are you up for a challenge?
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_55f35dd9", "mission4_brief"}, -- I'm always up for a challenge.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_training_deal)

hakassha_convo_mission4_capture = ConvoScreen:new {
	id = "mission4_capture",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3bcb2c4a", -- Imperial Intelligence has already captured extensive documentation on the ship's design, so we don't need to capture a working prototype. We'd prefer to simply send a message to the Rebellion: 'We know your secrets and they don't scare us one bit'.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_34089768", "mission4_tough"}, -- Sounds like a fun job.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_capture)

hakassha_convo_mission4_tough = ConvoScreen:new {
	id = "mission4_tough",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3b6083ca", -- Don't get too confident. The B-Wing is apparently one tough bofa treat. Blasters, missiles, good sensors and visibility. Outmaneuver her and you'll win. Our superiors think this assignment is a gamble, but I put in a good word for you. Don't let me down.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c261cfae", "mission4_accept"}, -- No problem.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_tough)

hakassha_convo_mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_5dd3c672", -- Report back to me when you've taken out the prototype ship. Good luck, hon.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_accept)

-- Mission 3: reward
hakassha_convo_mission3_casualties = ConvoScreen:new {
	id = "mission3_casualties",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_72fd1d8c", -- So I heard. More unfortunate casualties. I'm glad to see you didn't hesitate in eliminating them.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_34ac7110", "mission3_reward"}, -- If someone shoots at me, I shoot back.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_casualties)

hakassha_convo_mission3_reward = ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_1d1dfdd3", -- Just remember that sometimes you need to shoot first to survive. Our superiors are pleased that we've proceeded this far in our operation. Here is your payment plus a bonus. I also had a TIE pilot flight suit made for you.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_fc27931b", "mission3_reward_end"}, -- Thanks.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_reward)

hakassha_convo_mission3_reward_bandolier = ConvoScreen:new {
	id = "mission3_reward_bandolier",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_240aee17", -- Just remember that sometimes you need to shoot first to survive. Our superiors are pleased that we've proceeded this far in our operation. Here is your payment plus a bonus. I also had a double bandolier made for you.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_fc27931b", "mission3_reward_end"}, -- Thanks.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_reward_bandolier)

hakassha_convo_mission3_reward_end = ConvoScreen:new {
	id = "mission3_reward_end",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_33d3f25d", -- Hon, you are really shaping up to be a fine agent. Keep sharp. I'll have more work for you soon.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_reward_end)

-- Mission 3: failed
hakassha_convo_mission3_failed_another = ConvoScreen:new {
	id = "mission3_failed_another",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_8cf0a3be", -- I don't want to hear it. This operation is critical, so we have another transport coming in. Make sure this one arrives.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_25042a7a", "mission3_retry"}, -- I will not fail you.
		{"@conversation/corellia_imperial_trainer_1:s_8fdf4d92", "mission3_later"}, -- I need to figure out what went wrong.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_failed_another)

hakassha_convo_mission3_retry = ConvoScreen:new {
	id = "mission3_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_eb66b332", -- See that you don't. Report back to me when you've successfully completed the operation.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_retry)

hakassha_convo_mission3_later = ConvoScreen:new {
	id = "mission3_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c722467d", -- Don't hesitate too long. The ship will be arriving in the system shortly.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_later)

-- Mission 3: briefing
hakassha_convo_mission3_brief = ConvoScreen:new {
	id = "mission3_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_8dec57cb", -- Glad to see you came with your game face on, because we're going to up the ante. We've got a transport coming into the system soon carrying some delicate cargo. I need you to meet this transport and escort it safely to near Coronet orbit.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1ca122f0", "mission3_cargo"}, -- What's on the transport?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_brief)

hakassha_convo_mission3_ambitious = ConvoScreen:new {
	id = "mission3_ambitious",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c168cb82", -- Oh you are an ambitious one, %NU, I'll give you that.  But I need you to move on to the next step in the operation now.  There'll be plenty of time for training later.
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_7c1600a", "mission3_brief"}, -- What's the next step?  I'm ready.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_ambitious)

hakassha_convo_mission3_cargo = ConvoScreen:new {
	id = "mission3_cargo",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_42a16c5f", -- Some very nasty and very illegal explosive devices. We need to get them planet-side so our ground ops team can wire up a little demonstration of Rebel fanaticism.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_dd67013", "mission3_barracks"}, -- What does that mean?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_cargo)

hakassha_convo_mission3_barracks = ConvoScreen:new {
	id = "mission3_barracks",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b7b2ca97", -- We're going to destroy the barracks of the 72nd Imperial Army Division, based in Coronet. The explosives are of Mon Cal manufacture...extremely rare. Since the Mon Cal are open supporters of the Rebellion, it will look very much like a Rebel operation.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b1fa2372", "mission3_weak_stomach"}, -- You're going to kill your own troops?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_barracks)

hakassha_convo_mission3_weak_stomach = ConvoScreen:new {
	id = "mission3_weak_stomach",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b00eaf8", -- Getting a weak stomach, hon? This is a war and in war there are casualties. If destroying that barracks brings full Imperial occupation to this system and shuts down Rebel operations here, more Imperial lives will have been saved in the long run.
	stopConversation = "false",
	animation = "conversation_1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_995b811", "mission3_permutations"}, -- A brilliant plan.
		{"@conversation/corellia_imperial_trainer_1:s_32ab69ab", "mission3_excessive"}, -- This sounds excessive...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_weak_stomach)

hakassha_convo_mission3_permutations = ConvoScreen:new {
	id = "mission3_permutations",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b0f32222", -- Black Epsilon has calculated thousands of permutations on this scenario. The numbers don't lie. This will be a key move in bringing Corellia fully into the civil war on the side of the Empire.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_9265da40", "mission3_accept"}, -- Sounds like the right move, then.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_permutations)

hakassha_convo_mission3_excessive = ConvoScreen:new {
	id = "mission3_excessive",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a45281b6", -- It is excessive. Local civilian support for the Rebellion will be crushed. The Corellian government will be forced to take measures to stop Rebel aggression. The Rebels will plead innocence, all the while the vids report Imperial casualties.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_6d2bb136", "mission3_permutations"}, -- I suppose you have a point.
		{"@conversation/corellia_imperial_trainer_1:s_13bbdfe7", "mission3_second_guess"}, -- I'm not so sure about this...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_excessive)

hakassha_convo_mission3_second_guess = ConvoScreen:new {
	id = "mission3_second_guess",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_d2d78159", -- Now is not the time to second guess your masters. The fulfillment of our goals is within reach. Remember your oath. The Emperor has willed this and has foreseen a favorable outcome.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_644da0b1", "mission3_accept_no_choice"}, -- Then I suppose I don't have a choice.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_second_guess)

hakassha_convo_mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2df5ef77", -- Go meet up with that transport and escort it to safety. Report back to me when you've done the job.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_accept)

hakassha_convo_mission3_accept_no_choice = ConvoScreen:new {
	id = "mission3_accept_no_choice",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c0c1f033", -- If you want to stay alive, no. Report back to me when you've done the job.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_accept_no_choice)

-- Mission 2: reward
hakassha_convo_mission2_big_guns = ConvoScreen:new {
	id = "mission2_big_guns",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f498906e", -- Don't worry, if we get the Rebels stirred up enough, I'm sure they'll ship in the big guns. That's what we want, after all. A big move by the Rebels would justify a big counter move by the Empire.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_386d47c9", "mission2_reward_pay"}, -- I'm more interested in the pay than the politics.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_big_guns)

hakassha_convo_mission2_reward = ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_1345d43f", -- Excellent. You seem to understand what it takes to work with Black Epsilon. Our superiors will be pleased. Here's a little payment for the operation.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_67ded17", "mission2_superiors"}, -- When do I get to meet these superiors?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_reward)

hakassha_convo_mission2_reward_pay = ConvoScreen:new {
	id = "mission2_reward_pay",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_45c1b2ad", -- Here's your money for that last job. You know, hon, Black Epsilon is a political organization. We want members who understand the delicate balance of galactic power. I'm starting to have doubts about our...compatibility.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ee39efb1", "mission2_reward_pay_end"}, -- Give me credits and I give you results. Nothing else matters.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_reward_pay)

hakassha_convo_mission2_reward_pay_end = ConvoScreen:new {
	id = "mission2_reward_pay_end",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c782972e", -- For now, that's all the motivation I need. Later, I'll want to know you see things our way. Come back when you are ready to work on the next step in our operation.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_reward_pay_end)

hakassha_convo_mission2_superiors = ConvoScreen:new {
	id = "mission2_superiors",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_407c41b9", -- They work through me and only me. The less you know, the less you tell when you get caught.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_f6629a2e", "mission2_reward_end"}, -- Don't you mean IF I get caught?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_superiors)

hakassha_convo_mission2_reward_end = ConvoScreen:new {
	id = "mission2_reward_end",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7912ee34", -- Yeah, sorry, hon. IF you get caught. Come back when you are ready for the next step in our operation.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_reward_end)

-- Mission 2: failed
hakassha_convo_mission2_retry = ConvoScreen:new {
	id = "mission2_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_6f5dc45e", -- Good to hear it. Let me know when the job is done.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_retry)

hakassha_convo_mission2_later = ConvoScreen:new {
	id = "mission2_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_28d99e75", -- Come back when you want to try again.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_later)

-- Agency questions (loop between missions 1 and 2)
hakassha_convo_agency_navy_army = ConvoScreen:new {
	id = "agency_navy_army",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a8d68602", -- The majority of Imperial military operations are handled by the Navy and the Army. Both are massive, bureaucratic organizations. They destroy their enemies utterly, but sometimes a lighter touch is needed.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_8879f039", "agency_overt_force"}, -- Which means?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_navy_army)

hakassha_convo_mission2_not_yet = ConvoScreen:new {
	id = "mission2_not_yet",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_5c5f5b06", -- Not just yet, %NU.  You still have a few more assignments to complete before I'll train you.  Now, I promised to answer questions for you... so what do you want to know?
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_87f86e3e", "agency_navy_army"}, -- What agency do you work for?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_not_yet)

hakassha_convo_mission1_answers = ConvoScreen:new {
	id = "mission1_answers",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_67b99efb", -- Aren't we the tough one? So what do you want to know?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_87f86e3e", "agency_navy_army"}, -- What agency do you work for?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_answers)

hakassha_convo_agency_overt_force = ConvoScreen:new {
	id = "agency_overt_force",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_1bf00a8", -- When the Emperor desires to resolve a problem and the overt use of force is not politically feasible, he calls upon us. Black Epsilon.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_fe85123f", "agency_black_epsilon"}, -- Black Epsilon...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_overt_force)

hakassha_convo_agency_black_epsilon = ConvoScreen:new {
	id = "agency_black_epsilon",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_e99f26f3", -- We are a division of the Imperial Navy, but no record in the Imperial Archive on Coruscant would indicate our existence. We serve the will of the Emperor directly and silently. When political necessity requires a war, we create war. When it requires peace, we silence those who oppose peace.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1f78cffa", "agency_join"}, -- How do I join Black Epsilon?
		{"@conversation/corellia_imperial_trainer_1:s_70edc281", "agency_zabrak"}, -- Why would the Empire work with a Zabrak?
		{"@conversation/corellia_imperial_trainer_1:s_10499a33", "agency_trust"}, -- Why trust me?
		{"@conversation/corellia_imperial_trainer_1:s_3c26f38a", "agency_purpose"}, -- What is Black Epsilon doing here?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_black_epsilon)

hakassha_convo_agency_join = ConvoScreen:new {
	id = "agency_join",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_ca3b3777", -- Hon, you already are a part of Black Epsilon. You swore to the Emperor and you've shown your loyalty.  Your position with the agency is assured. Of course, if I discover that you intend to betray us, your life will be forfeit.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_70edc281", "agency_zabrak"}, -- Why would the Empire work with a Zabrak?
		{"@conversation/corellia_imperial_trainer_1:s_10499a33", "agency_trust"}, -- Why trust me?
		{"@conversation/corellia_imperial_trainer_1:s_3c26f38a", "agency_purpose"}, -- What is Black Epsilon doing here?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_join)

hakassha_convo_agency_zabrak = ConvoScreen:new {
	id = "agency_zabrak",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_ce07308a", -- The Emperor is willing to lay aside minor prejudice to work with talented individuals. I have long since proven my worth. You, on the other hand, have much to prove.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1f78cffa", "agency_join"}, -- How do I join Black Epsilon?
		{"@conversation/corellia_imperial_trainer_1:s_10499a33", "agency_trust"}, -- Why trust me?
		{"@conversation/corellia_imperial_trainer_1:s_3c26f38a", "agency_purpose"}, -- What is Black Epsilon doing here?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_zabrak)

hakassha_convo_agency_trust = ConvoScreen:new {
	id = "agency_trust",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f866da28", -- Babe, I don't trust anyone.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_da3e5ec3", "agency_test"}, -- Then why recruit me?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_trust)

hakassha_convo_agency_purpose = ConvoScreen:new {
	id = "agency_purpose",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_81a6747", -- Before the destruction of the Death Star, we primarily operated in the Outer Rim, softening new worlds for Imperial expansion. Since the rise of the Rebellion, we have been recalled to the Core Worlds.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ff1e8d6a", "agency_corellia"}, -- I mean on Corellia.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_purpose)

hakassha_convo_agency_next_assignment = ConvoScreen:new {
	id = "agency_next_assignment",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_27c9aa85", -- Mmm, all worked up and ready for another go. I like that. As it happens, I do have another assignment for you.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1adbadc4", "mission2_brief"}, -- I'm ready.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_next_assignment)

hakassha_convo_agency_test = ConvoScreen:new {
	id = "agency_test",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_bb310cb", -- I gave you a test and you passed. You killed for the Emperor without worrying about the consequences. To be a member of Black Epsilon, you must apply your will totally and act without the burden of conscience. We do what others can not.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_f1f8a5ca", "agency_sincere"}, -- How do you know I'm sincere?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_test)

hakassha_convo_agency_sincere = ConvoScreen:new {
	id = "agency_sincere",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_de514757", -- Few would swear to the Emperor and then kill in his name insincerely. The Emperor knew that in your heart you desired to strike out at your enemies. Your actions prove your loyalty.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_485d8416", "agency_rewarding"}, -- Yes...it did feel right.
		{"@conversation/corellia_imperial_trainer_1:s_48f07357", "agency_killer"}, -- No, I'm not a killer.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_sincere)

hakassha_convo_agency_rewarding = ConvoScreen:new {
	id = "agency_rewarding",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_cf202613", -- I think you'll find loyal service to the Emperor is very rewarding.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1f78cffa", "agency_join"}, -- How do I join Black Epsilon?
		{"@conversation/corellia_imperial_trainer_1:s_70edc281", "agency_zabrak"}, -- Why would the Empire work with a Zabrak?
		{"@conversation/corellia_imperial_trainer_1:s_3c26f38a", "agency_purpose"}, -- What is Black Epsilon doing here?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_rewarding)

hakassha_convo_agency_killer = ConvoScreen:new {
	id = "agency_killer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f0dfde7f", -- So you claim, yet you killed. In time you will come to realize the righteousness of your actions.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1f78cffa", "agency_join"}, -- How do I join Black Epsilon?
		{"@conversation/corellia_imperial_trainer_1:s_70edc281", "agency_zabrak"}, -- Why would the Empire work with a Zabrak?
		{"@conversation/corellia_imperial_trainer_1:s_3c26f38a", "agency_purpose"}, -- What is Black Epsilon doing here?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_killer)

hakassha_convo_agency_corellia = ConvoScreen:new {
	id = "agency_corellia",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_727f229", -- Corellia has declared neutrality in the so called 'Galactic Civil War.' At the same time, they are host to a wide range of Rebel operations, including the protection of known collaborators. The Emperor doesn't like this situation.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_e1ea9c75", "agency_invade"}, -- Why doesn't the Emperor just invade?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_corellia)

hakassha_convo_agency_invade = ConvoScreen:new {
	id = "agency_invade",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_8b4aa06c", -- If the Navy invades, other planets loyal to the Empire might turn to the Rebellion. The Emperor built his great Galactic Empire through a deft mix of politics and war. Sometimes, hon, the former is preferable to the latter.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_747c5a79", "agency_mandalore"}, -- Ah, like Mandalore.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_invade)

hakassha_convo_agency_mandalore = ConvoScreen:new {
	id = "agency_mandalore",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_506c3428", -- You know your history, I'm impressed! Yes, the Mandalorians tried to build an empire through war alone and were ultimately defeated. They didn't understand manipulation. To achieve victory you sometimes have to offer the embrace of peace while holding a hidden dagger.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1930ad3a", "agency_dagger"}, -- And Black Epsilon is that dagger?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_mandalore)

hakassha_convo_agency_dagger = ConvoScreen:new {
	id = "agency_dagger",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c81a8a32", -- Black Epsilon is one such tool. The Emperor wisely does not invest all of his trust in a single agent. Should we fail, others would eliminate us and take our place. Thus we do not fail.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1f78cffa", "agency_join"}, -- How do I join Black Epsilon?
		{"@conversation/corellia_imperial_trainer_1:s_10499a33", "agency_trust"}, -- Why trust me?
		{"@conversation/corellia_imperial_trainer_1:s_70edc281", "agency_zabrak"}, -- Why would the Empire work with a Zabrak?
		{"@conversation/corellia_imperial_trainer_1:s_d2e23af2", "agency_next_assignment"}, -- What's my next assignment?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_agency_dagger)

-- Mission 2: briefing
hakassha_convo_mission2_brief = ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_95d0bcb3", -- Your attack on the Rebel patrol was very successful. The attack looked like a failed act of Rebel aggression. Popular support for the Rebellion on Corellia is faltering. The Rebels suspect something's up, so they're starting to beef up their operations.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_86c66182", "mission2_next_step"}, -- What's the next step?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_brief)

hakassha_convo_mission2_next_step = ConvoScreen:new {
	id = "mission2_next_step",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_51db72fc", -- We need to make sure that we keep their military power in check while they increase their activity. Stirring up the chuba nest isn't going to do any good if the Rebels end up fortifying Corellia.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ef85b67c", "mission2_cadets"}, -- That makes sense.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_next_step)

hakassha_convo_mission2_cadets = ConvoScreen:new {
	id = "mission2_cadets",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_11c38900", -- I have discovered that the Rebels are training X-Wing cadets in Corellian space. The Rebels are quickly working to recruit new pilots to their cause. Destroying the cadets will cripple that effort. Corellian citizens will think twice about signing up if the Rebels can't even protect their young and inexperienced.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ec3c3e1d", "mission2_instructors"}, -- Sounds easy.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_cadets)

hakassha_convo_mission2_instructors = ConvoScreen:new {
	id = "mission2_instructors",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a074ac18", -- The trainees shouldn't be a match for you, but their instructors might. You are going to have to hunt them down in the Corellian system. Intelligence has not yet been able to locate their training grounds but there are reports of a Rebel station somewhere in the system. Might be a good start. Be on guard and don't worry if one escapes and reports you. The Empire is fully justified in destroying terrorist training grounds found within its jurisdiction.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_1ff4247a", "mission2_accept"}, -- I will not fail.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_instructors)

hakassha_convo_mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_3c33e829", -- Report back to me when you're done and we'll talk about the next step.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_accept)

-- Mission 1: failed
hakassha_convo_mission1_failed_explain = ConvoScreen:new {
	id = "mission1_failed_explain",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_4afb3952", -- A minor skirmish between an Imperial pilot and a Rebel patrol isn't exactly the kind of thing that will motivate Corellia to run to the Empire. Particularly not when the Empire loses. I want total carnage. Bait the Rebels into attacking you and smash them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_97d43fda", "mission1_retry"}, -- I get the idea.
		{"@conversation/corellia_imperial_trainer_1:s_593d4b61", "mission1_later"}, -- I understand you're angry but...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_failed_explain)

hakassha_convo_mission1_retry = ConvoScreen:new {
	id = "mission1_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_da237511", -- I take my job seriously, babe. Get back out there and do it right this time.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_retry)

hakassha_convo_mission1_later = ConvoScreen:new {
	id = "mission1_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_12d7f011", -- This is a serious operation, hon. Get a drink and chill out. Come back when you want to try this thing again.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_later)

-- Mission 1: briefing
hakassha_convo_mission1_brief = ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a37bb512", -- As you know, Corellia has been officially neutral in the galactic civil war. Despite this declaration of neutrality and some deft political maneuvering on behalf of the Corellian leadership, a strong Rebel sentiment has taken hold here. Rumor has it that Princess Leia Organa herself is operating a command center in the area.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c023d5a9", "mission1_rumors"}, -- I've heard these rumors before.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_brief)

hakassha_convo_mission1_train_later = ConvoScreen:new {
	id = "mission1_train_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_33a8fcd8", -- I can, hon, but I'm not going to... not yet.  I need you to do some things for me first.
	stopConversation = "false",
	animation = "hair_flip",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_5bd69df6", "mission1_brief"}, -- What do you need me to do?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_train_later)

hakassha_convo_mission1_rumors = ConvoScreen:new {
	id = "mission1_rumors",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_d0a7527e", -- I'm sure you have, hon. So you'll also be aware that the Emperor disapproves of this harboring of criminal activity and, naturally, wishes to put an end to it. The problem is that Corellia is a politically valuable world. Any overt move to take the planet by force would alienate her people and push her further towards Rebel ideology.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ac893f3a", "mission1_lesson"}, -- I'm here for a job, not a political science lesson.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_rumors)

hakassha_convo_mission1_lesson = ConvoScreen:new {
	id = "mission1_lesson",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_83980c8d", -- Listen to the lesson, then you'll get the job. I want to make sure you understand the delicacy of the situation.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ccf66c81", "mission1_reason"}, -- Go on then.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_lesson)

hakassha_convo_mission1_reason = ConvoScreen:new {
	id = "mission1_reason",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_41d4922", -- As I was saying. The Emperor can't order a direct invasion of Corellia. He needs a politically acceptable reason to make a move. My job is to provide that reason.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c261b36a", "mission1_spy"}, -- So you're a spy.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_reason)

hakassha_convo_mission1_spy = ConvoScreen:new {
	id = "mission1_spy",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_82040511", -- After a fashion. There's plenty of me to reveal later. I want you to fly a patrol in low orbit near Coronet. Use an Imperial TIE fighter. Show the flag. Most importantly, attract the attention of the Rebels. The Rebellion is a violent terrorist organization. They won't be able to resist a lone TIE strutting about in enemy territory. When they move in to shoot you down, eliminate them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_d1613a21", "mission1_kill"}, -- You want me to kill them?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_spy)

hakassha_convo_mission1_kill = ConvoScreen:new {
	id = "mission1_kill",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_41e7fbb3", -- That would be the point, dear. The destruction of a small Rebel force should stir things up a bit. The Rebels will probably start flying more patrols, putting up a more obvious presence. Exactly the kind of thing we need to betray Corellian neutrality. If anyone questions you, say you defended yourself against a hostile force while on patrol duty.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_2d4c3812", "mission1_answers_later"}, -- When I get back, I expect some answers.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_kill)

hakassha_convo_mission1_answers_later = ConvoScreen:new {
	id = "mission1_answers_later",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_6fb821bb", -- Oh, hon, you're no fun. Do this job and you'll get your answers. I'll have more work for you, too. Obviously one little incident won't be enough to achieve our goals. Come back and talk to me when you've killed the Rebels.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_38909ce3", "mission1_accept"}, -- You can count on it.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_answers_later)

hakassha_convo_mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_43fe629", -- Oh and be careful. I'd hate to see that cute face get a scratch.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_accept)

-- Recruitment and sign-up
hakassha_convo_recruit_pilot = ConvoScreen:new {
	id = "recruit_pilot",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f93af369", -- You're a pilot? Interesting... Yes, I'm looking to hire a pilot. The job isn't easy and you'll have to work with minimal information. You'll be shot at. Probably have to kill some people, too. Sure you want this kind of work?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_be86775e", "recruit_baggage"}, -- Doesn't sound like anything I'm not used to.
		{"@conversation/corellia_imperial_trainer_1:s_8417be65", "recruit_keep_skin"}, -- Actually, I'm interested in keeping my skin.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_pilot)

hakassha_convo_recruit_baggage = ConvoScreen:new {
	id = "recruit_baggage",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_1d646fae", -- Oh is that a fact? I don't want to hire someone with a lot of baggage. If you're too hot with CorSec you can look elsewhere.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_df871c0b", "recruit_agency"}, -- Don't worry about CorSec. I can handle the heat.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_baggage)

hakassha_convo_recruit_keep_skin = ConvoScreen:new {
	id = "recruit_keep_skin",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b1097fe", -- Then don't waste my time, hon.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_keep_skin)

hakassha_convo_recruit_agency = ConvoScreen:new {
	id = "recruit_agency",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_6a750265", -- Good. That kind of confidence is what I'm looking for. I represent an agency interested in seeing the Imperial presence in this region of space increased. I think you can help me achieve that goal.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_e749e2cd", "recruit_secrets"}, -- What is this agency?
		{"@conversation/corellia_imperial_trainer_1:s_62027e5", "recruit_swear"}, -- I'm a supporter of the Empire. What can I do to help?
		{"@conversation/corellia_imperial_trainer_1:s_92a51c16", "recruit_pay"}, -- Does this job pay?
		{"@conversation/corellia_imperial_trainer_1:s_d80177b5", "recruit_not_interested"}, -- Sorry, I'm not interested in helping the Empire.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_agency)

hakassha_convo_recruit_secrets = ConvoScreen:new {
	id = "recruit_secrets",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7e4287eb", -- All in good time, hon. Show me you're serious and then we can share all the dirty little secrets.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_11816971", "recruit_swear"}, -- Alright. I support the Empire. What can I do to help?
		{"@conversation/corellia_imperial_trainer_1:s_32fca1d6", "recruit_pay"}, -- Whatever. Does this job pay?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_secrets)

hakassha_convo_recruit_swear = ConvoScreen:new {
	id = "recruit_swear",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_f0fc751b", -- Being a supporter is commendable, but for this job I need to know you're loyal. You must swear obedience to the Emperor. Do it now, or walk away.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_845e6ef5", "recruit_sworn"}, -- I swear to serve the Emperor, to uphold his law, and to do his will without fail.
		{"@conversation/corellia_imperial_trainer_1:s_2fb75072", "recruit_extreme"}, -- Swear? That seems a little extreme.
		{"@conversation/corellia_imperial_trainer_1:s_7b9b2577", "recruit_refused"}, -- Swear to the Emperor? I can't do that.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_swear)

hakassha_convo_recruit_pay = ConvoScreen:new {
	id = "recruit_pay",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c7c75ec4", -- Right to the point. I like that. Yeah, it pays. Imperial credits and the opportunity for our relationship to get... closer. Of course, all of this depends upon your discretion. Tell someone about the job and you'll be paid with a different kind of currency.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_11816971", "recruit_swear"}, -- Alright. I support the Empire. What can I do to help?
		{"@conversation/corellia_imperial_trainer_1:s_e749e2cd", "recruit_secrets"}, -- What is this agency?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_pay)

hakassha_convo_recruit_not_interested = ConvoScreen:new {
	id = "recruit_not_interested",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2db4d111", -- Then don't waste my time.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_not_interested)

hakassha_convo_recruit_sworn = ConvoScreen:new {
	id = "recruit_sworn",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_d537ac2e", -- So witnessed. Congratulations, hon, you've made a very wise decision. For this operation, you'll need legitimate credentials. From now on, your ID will indicate your status as a Pilot Initiate in the Imperial Navy. My agency will ensure that the Navy records reflect this...half truth.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_4ecd165f", "recruit_has_ship"}, -- So now I'm an Imperial Pilot? Just like that?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_sworn)

hakassha_convo_recruit_extreme = ConvoScreen:new {
	id = "recruit_extreme",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_ae56cee4", -- If this was a normal job, I might agree. It isn't a normal job. I need someone I know I can trust. The agency I work for is very interested in the loyalty of its employees.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_7c7f3198", "recruit_zabrak"}, -- This doesn't make sense. The Empire has a policy against hiring non-humans and you're a Zabrak.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_extreme)

hakassha_convo_recruit_refused = ConvoScreen:new {
	id = "recruit_refused",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_cd5427a6", -- Maybe you should think about what it means to be a supporter of the Empire. Have a good evening, hon.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_refused)

hakassha_convo_recruit_ship_granted = ConvoScreen:new {
	id = "recruit_ship_granted",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c10b8471", -- Just like that. I am not big on ceremony so we are not going to worry about that much. I am authorized to grant you a basic TIE. If you want we can smash a bottle of corellian wine against it but I figure that would be a waste of good wine. The way I see it, you'll either do what I say and prove you have what it takes, or you'll die.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_3e8986a7", "recruit_business"}, -- You aren't exactly doing a good job of reassuring me.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_ship_granted)

hakassha_convo_recruit_has_ship = ConvoScreen:new {
	id = "recruit_has_ship",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_9644818a", -- Just like that. Sure, there's usually the years of formal officer education, the background checks, the certification trials...a mess, really. We can dispense with the formal stuff. The way I see it, you'll either do what I say and prove you have what it takes, or you'll die.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_3e8986a7", "recruit_business"}, -- You aren't exactly doing a good job of reassuring me.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_has_ship)

hakassha_convo_recruit_business = ConvoScreen:new {
	id = "recruit_business",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_78dd7bba", -- Look on the bright side, at least I won't make you call me 'sir'. Shall we get down to business?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_4b5d9495", "mission1_brief"}, -- Alright. What's the job?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_business)

hakassha_convo_recruit_zabrak = ConvoScreen:new {
	id = "recruit_zabrak",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_4acb4a79", -- How perceptive! Yes, I am a Zabrak. The Imperial policies don't apply to me or anyone with the agency.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_702795f8", "recruit_swear_again"}, -- That's all you have to say about it?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_zabrak)

hakassha_convo_recruit_swear_again = ConvoScreen:new {
	id = "recruit_swear_again",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_8b179721", -- That's all I have to say for now. Swear to the Emperor, prove your loyalty to the Empire, and then we can get personal.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_423667ed", "recruit_sworn"}, -- Fine, I will swear. I swear to serve the Emperor, to uphold his law, and to do his will without fail.
		{"@conversation/corellia_imperial_trainer_1:s_54328ce3", "recruit_refused"}, -- I won't swear to serve the Emperor.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruit_swear_again)

-- First screens (picked by getInitialScreen)
hakassha_convo_first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c006779f", -- What do you need, hon? You've got your assignment, and the control device for your ship is set up in your datapad.  You need to go to the Starport and access the starship terminal to launch into space.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_32c46e00", "help_where"}, -- Where should I go?
		{"@conversation/corellia_imperial_trainer_1:s_f8b02865", "help_what"}, -- What do I do?
		{"@conversation/corellia_imperial_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/corellia_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_first_mission_help)

hakassha_convo_no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_cae1bdcf", -- Well, aren't you a cute one. But unless you're a pilot, I'm afraid there's not much I can do for you.
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_no_jtl)

hakassha_convo_rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_bf5586b8", -- Sorry, I don't deal with Rebels.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_rebel_pilot)

hakassha_convo_neutral_pilot = ConvoScreen:new {
	id = "neutral_pilot",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_9e6137e3", -- I think I recognize you. You're on a wanted list I think... I can't work with known members of criminal organizations.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_neutral_pilot)

hakassha_convo_lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_cc282429", -- Nice to see you again hon. Are you here for business or pleasure?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_ca2a7f20", "lost_ship_business"}, -- I...well you see...I sort of lost my ship.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_lost_ship)

hakassha_convo_not_imperial = ConvoScreen:new {
	id = "not_imperial",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_d742dc00", -- Now, hon... just what sort of trouble have you gotten yourself into?
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_not_imperial)

hakassha_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2efb24e9", -- You're an Imperial pilot? Too bad you're already assigned to another unit. I'd be sure you'd make a fine addition to the Epsilon. What brings you here?
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_29e5ec7", "non_member_no_missions"}, -- I'd like to request a mission.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_non_member)

hakassha_convo_working_for_prisk = ConvoScreen:new {
	id = "working_for_prisk",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_62ce5e6e", -- Hiya hon. It's very sweet of you to come back for a visit but you no longer work for me. You should go see Prisk.
	stopConversation = "true",
	animation = "greet",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_working_for_prisk)

hakassha_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_4b074298", -- Come back when you're done with your mission. You can abort your mission if you want to start over.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_on_mission)

-- Mission and training entry screens
hakassha_convo_series_complete = ConvoScreen:new {
	id = "series_complete",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_afec2e39", -- Welcome back. You might like to know that I have mentioned your name to one of my superiors and he is most interested in meeting you. But I would highly recommend that you do not go until you feel yourself ready to take the next step.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/corellia_imperial_trainer_1:s_943c7ba6", "nothing_to_teach"}, -- I'd like training.
		{"@conversation/corellia_imperial_trainer_1:s_3e77e17d", "transfer_to_prisk"}, -- I appreciate all you have done for me but I am ready to move on.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_series_complete)

hakassha_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a60c6c26", -- Hey hon, glad you stopped in. Word just came down from the Black Epsilon command group: we're moving forward with the next phase of our operation. They want you to be the primary operative.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_df75425", "promotion"}, -- Primary operative?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_tier_done)

hakassha_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_56b5e7e6", -- Black Epsilon has authorized me to give you special instruction. Field training that will make you a more effective agent.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_19ff301f", "training_menu"}, -- What kind of training?
		{"@conversation/corellia_imperial_trainer_1:s_710daa61", "training_declined"}, -- I don't need any training.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_training_offer)

hakassha_convo_duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_15d6b9a5", -- Ground ops is working on the sabotage plan and I haven't received word from Black Epsilon regarding new space operations. For now, I have a few duties you can work on while we wait.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_6a128385", "duty_explained"}, -- What is a duty?
		{"@conversation/corellia_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/corellia_imperial_trainer_1:s_943c7ba6", "no_training_xp"}, -- I'd like training.
		{"@conversation/corellia_imperial_trainer_1:s_761039fa", "enlist_ground"}, -- I want to enlist with the ground forces
	}
}
hakassha_convo_template:addScreen(hakassha_convo_duty_missions)

hakassha_convo_mission4_won = ConvoScreen:new {
	id = "mission4_won",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_293e6269", -- Did you take out the B-Wing prototype?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_b224e12", "mission4_won_close"}, -- It was a close fight, but I came out on top.
		{"@conversation/corellia_imperial_trainer_1:s_6372912d", "mission4_won_toast"}, -- He's toast. Not such a tough ship after all.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_won)

hakassha_convo_mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b4d32046", -- Did you eliminate the B-Wing prototype?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_64a94075", "mission4_failed_explain"}, -- Ah, no...it's a tough ship.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_failed)

hakassha_convo_mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_fbd7d1ba", -- I think you'll like this mission, hon. You get to test your mettle against some new Rebel technology. Real cutting edge stuff, too.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_55f35dd9", "mission4_brief"}, -- I'm always up for a challenge.
		{"@conversation/corellia_imperial_trainer_1:s_5da44265", "mission4_training_deal"}, -- I want some training.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission4_offer)

hakassha_convo_mission3_won = ConvoScreen:new {
	id = "mission3_won",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_885decf4", -- My boys in ground ops say they received the package. Good work. They're going to be moving forward with the dirtier side of the plan soon.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_dd5ca133", "mission3_casualties"}, -- I was attacked by a CorSec patrol during the mission.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_won)

hakassha_convo_mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_c890222b", -- I can't believe you failed the escort. This operation is crucial. We don't have much of the explosive to spare!
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_fad19320", "mission3_failed_another"}, -- But, I...
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_failed)

hakassha_convo_mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2559ccf6", -- Welcome back, babe. Glad to see you're still with us.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_7a80cd06", "mission3_brief"}, -- I'm ready for the next step in the operation.
		{"@conversation/corellia_imperial_trainer_1:s_4d31f286", "mission3_ambitious"}, -- Are you going to train me now?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission3_offer)

hakassha_convo_mission2_won = ConvoScreen:new {
	id = "mission2_won",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_95797708", -- Hey babe. Did you deal with those annoying little Rebel trainees?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_fa187bb6", "mission2_big_guns"}, -- They weren't much of a challenge.
		{"@conversation/corellia_imperial_trainer_1:s_36eb0383", "mission2_reward"}, -- Took out enough of them to send a message.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_won)

hakassha_convo_mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b2e9f062", -- Black Epsilon demands results. You have failed to bring those results. If you can't bring yourself to do this job, there are others who will.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_28490f70", "mission2_retry"}, -- I ran into some trouble, but I'm ready to try again.
		{"@conversation/corellia_imperial_trainer_1:s_96c066fe", "mission2_later"}, -- I need to think about a better plan of attack, first.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_failed)

hakassha_convo_mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7dad1c0c", -- So what do you want to know?
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_87f86e3e", "agency_navy_army"}, -- What agency do you work for?
		{"@conversation/corellia_imperial_trainer_1:s_192ddc14", "mission2_not_yet"}, -- Are you going to train me?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission2_offer)

hakassha_convo_mission1_won = ConvoScreen:new {
	id = "mission1_won",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_34d65199", -- Hey cutey. I see you made it back in one piece. I've already heard the news. You managed to take out an entire Rebel security patrol. Nice work. Here's your payment.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_334f003c", "mission1_answers"}, -- Nothing to it. Now, you owe me some answers.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_won)

hakassha_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_71df5543", -- No luck with the Rebels eh?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_88da6887", "mission1_failed_explain"}, -- I ran into some trouble.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_failed)

hakassha_convo_mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_5a48897a", -- Hey there, hon. Ready to talk business?
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_96682689", "mission1_brief"}, -- Tell me about the job.
		{"@conversation/corellia_imperial_trainer_1:s_2c9c30a0", "mission1_train_later"}, -- Can you train me?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_mission1_offer)

hakassha_convo_recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_53c3dd52", -- Well, aren't you a cute one. My name is Hakasha Sireen. Is there something I can do for you?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_11bb9c43", "recruit_pilot"}, -- I was told you are looking for a pilot.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_recruitment)

-- Training: topic descriptions and results (pre-NGE)
hakassha_convo_train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_438b2349", -- So far you've been flying a basic TIE.  The normal TIE is quite a bit more complicated than that.  For one thing, you'll find that you can install better components on it... better weapons, better armor, and so on.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6d9f61", "trained_starships"}, -- I'd like to study that in detail.
		{"@conversation/corellia_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_train_starships)

hakassha_convo_train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_a4c65e0b", -- With just a little more training, you could be using better weapons.  Missiles can really help to swing the battle your way, and this skill can allow you to use some good ones.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6d9f61", "trained_weapons"}, -- I'd like to study that in detail.
		{"@conversation/corellia_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_train_weapons)

hakassha_convo_train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_2e48b5f1", -- It's no secret that Imperial pilots utilize some of the best starfighter tactics the galaxy has ever seen.  I can get you started on the road to mastering these uniquely Imperial procedures.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6d9f61", "trained_procedures"}, -- I'd like to study that in detail.
		{"@conversation/corellia_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_train_procedures)

hakassha_convo_train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_df76b2e8", -- Imperial astromech functionality is typically built into a rugged navicomputer, rather than those annoying sorts of astromech units that the Rebel Alliance relies on.  I can teach you how to utilize some of the basic functionality of the droid interface to normalize your shields, overload your weapons, and that sort of thing.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_c6d9f61", "trained_droid"}, -- I'd like to study that in detail.
		{"@conversation/corellia_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
hakassha_convo_template:addScreen(hakassha_convo_train_droid)

hakassha_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_trained_starships)

hakassha_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_trained_weapons)

hakassha_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_trained_procedures)

hakassha_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_trained_droid)

hakassha_convo_training_never_mind = ConvoScreen:new {
	id = "training_never_mind",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_b016fdf8", -- It's your choice, but I recommend you take training while you have the chance.
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_training_never_mind)

-- Grounded (pre-NGE gate: Black Epsilon pilot with negative Imperial standing)
hakassha_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_593de03f", -- You're grounded, sweetie.  Reports are you turned on the Empire.  You haven't been fighting for the Rebel Alliance, have you?  Please don't tell me it's true!
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_549eddbe", "grounded_standing"}, -- Grounded?!
		{"@conversation/corellia_imperial_trainer_1:s_77e48d5b", "grounded_standing"}, -- What do you mean?
	}
}
hakassha_convo_template:addScreen(hakassha_convo_grounded)

hakassha_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_7469594f", -- Sorry, hon.  There's nothing I can do until you improve your standing with the Empire.  You need to prove you're still on our side!
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_1:s_8467c710", "grounded_believe"}, -- Ok
	}
}
hakassha_convo_template:addScreen(hakassha_convo_grounded_standing)

hakassha_convo_grounded_believe = ConvoScreen:new {
	id = "grounded_believe",
	leftDialog = "@conversation/corellia_imperial_trainer_1:s_afc85a31", -- Don't worry, cutey, I still believe in you.  You'll be back in no time!
	stopConversation = "true",
	options = {}
}
hakassha_convo_template:addScreen(hakassha_convo_grounded_believe)

addConversationTemplate("hakassha_convo_template", hakassha_convo_template)
