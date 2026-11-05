-- Lt. Barn Sinkko (Inquisition tier 1) conversation; ported from SWG-Source naboo_imperial_trainer_1.java with the pre-NGE client lines (feature inquisition-tier1-barn-sinkko). Handler: barnSinkkoConvoHandler.
barn_sinkko_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "barnSinkkoConvoHandler",
	screens = {}
}

barn_sinkko_convo_first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c19ed115", -- You've got your assignment, and the control device for your ship in your datapad.  Go to the Starport and access the terminal to launch into space.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_60c4f974", "help_where"}, -- Where do I go?
		{"@conversation/naboo_imperial_trainer_1:s_69a4eec5", "help_return"}, -- How do I return?
		{"@conversation/naboo_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_first_mission_help)

barn_sinkko_convo_help_where = ConvoScreen:new {
	id = "help_where",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_50ad850c", -- You will need to go to the starport. Once you reach the starport, go inside and look for a 'starship terminal.' You'll find them in the main room of the starport. Use the terminal to launch your starship into space.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_60c4f974", "help_where"}, -- Where do I go?
		{"@conversation/naboo_imperial_trainer_1:s_69a4eec5", "help_return"}, -- How do I return?
		{"@conversation/naboo_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_help_where)

barn_sinkko_convo_help_return = ConvoScreen:new {
	id = "help_return",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_4d88001", -- When you launch into space, the TIE navicomputer will create a special 'launch waypoint' that you can use to navigate back to the main Naboo space station. When you arrive at the space station, comm them and request landing clearance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_60c4f974", "help_where"}, -- Where do I go?
		{"@conversation/naboo_imperial_trainer_1:s_69a4eec5", "help_return"}, -- How do I return?
		{"@conversation/naboo_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_help_return)

barn_sinkko_convo_help_ship = ConvoScreen:new {
	id = "help_ship",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b29a803f", -- It's not your ship. It's the Emperor's ship... and it's one of many basic TIE craft parked at the starport. You have the 'control codes' for this ship. I uploaded them to your personal datapad. Check your datapad to see your ship status.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_60c4f974", "help_where"}, -- Where do I go?
		{"@conversation/naboo_imperial_trainer_1:s_69a4eec5", "help_return"}, -- How do I return?
		{"@conversation/naboo_imperial_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_help_ship)

barn_sinkko_convo_no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a8755a48", -- Unless you have business with the Imperial Navy, I must ask you to come back another time. I'm very busy right now.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_no_jtl)

barn_sinkko_convo_neutral_pilot = ConvoScreen:new {
	id = "neutral_pilot",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fc1001ba", -- Aren't you on a wanted list? I think I've seen your picture before...
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_neutral_pilot)

barn_sinkko_convo_rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_6159d1a3", -- I've seen your face! You're a known Rebel pilot!
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_rebel_pilot)

barn_sinkko_convo_not_imperial = ConvoScreen:new {
	id = "not_imperial",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_87019da4", -- I was hoping you would show your face, just so I could tell you myself:  You're a disgrace to the Imperial Navy and you've been grounded.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_not_imperial)

barn_sinkko_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_87019da4", -- I was hoping you would show your face, just so I could tell you myself:  You're a disgrace to the Imperial Navy and you've been grounded.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b5ba52d1", "grounded_command"}, -- What did I do?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_grounded)

barn_sinkko_convo_grounded_command = ConvoScreen:new {
	id = "grounded_command",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b6a9dd10", -- I should be asking you that.  All I know is that Imperial command has grounded you for actions against the Empire.  You'll never fly again.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_39ca1bf", "grounded_devotion"}, -- Wait!  There must be something I can do!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_grounded_command)

barn_sinkko_convo_grounded_devotion = ConvoScreen:new {
	id = "grounded_devotion",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_36d269f7", -- Prove your devotion to the Empire and your dedication to the Emperor.  If you improve your standing with the Empire, you MIGHT be allowed to fly again.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_grounded_devotion)

barn_sinkko_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f6e10f56", -- Good to meet you Pilot. According to my records you're already working with a different division. What can I do for you?
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4854758d", "non_member_no_missions"}, -- I would like to request a mission.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_non_member)

barn_sinkko_convo_non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a087f2d5", -- You do not have the proper security clearance to fly any of the missions I have, but I do have some elective duty tasks that you can perform. Do you want a duty task?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_2692ee30", "duty_menu"}, -- Yes, I want a duty.
		{"@conversation/naboo_imperial_trainer_1:s_90ce1297", "non_member_declined"}, -- No, thank you.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_non_member_duty_offer)

barn_sinkko_convo_non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_5eba6ff3", -- I have not received authorization to assign you any missions, Pilot. Speak with your commanding officer if you are looking for something to do.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_non_member_no_missions)

barn_sinkko_convo_non_member_declined = ConvoScreen:new {
	id = "non_member_declined",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_4cf693b", -- As you wish. Dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_non_member_declined)

barn_sinkko_convo_lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e106780b", -- Good to see you, Pilot.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_7d477c70", "lost_ship_confirm"}, -- Sir...I...ah...lost my ship control device.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_lost_ship)

barn_sinkko_convo_lost_ship_confirm = ConvoScreen:new {
	id = "lost_ship_confirm",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bc695163", -- I can clear you for a new TIE Fighter, but only the basic model. Are you sure you want a new control device?
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8efde2ae", "lost_ship_granted"}, -- Yes, sir.
		{"@conversation/naboo_imperial_trainer_1:s_169df3bb", "lost_ship_declined"}, -- Never mind.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_lost_ship_confirm)

barn_sinkko_convo_lost_ship_granted = ConvoScreen:new {
	id = "lost_ship_granted",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_94131047", -- Don't lose it this time.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_lost_ship_granted)

barn_sinkko_convo_lost_ship_declined = ConvoScreen:new {
	id = "lost_ship_declined",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_5f2d3c1e", -- I'm fairly busy, so I'll have to talk to you more later.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_lost_ship_declined)

barn_sinkko_convo_working_for_fazoll = ConvoScreen:new {
	id = "working_for_fazoll",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1fa7fe89", -- I don't have anything else for you. Talk to Under Inquisitor Fa'Zoll in the Emperor's Retreat.
	stopConversation = "true",
	animation = "point_away",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_working_for_fazoll)

barn_sinkko_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8c262163", -- Report back to me when you are finished with your current mission.  You can abort your mission if you want to start over.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_on_mission)

barn_sinkko_convo_series_complete = ConvoScreen:new {
	id = "series_complete",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2e935a2c", -- Good to see you again, pilot. I hope your new assignment is going well. The voluntary conscription program has been quite successful. If there is anything I can help you with, let me know. Although you are overqualified, I can offer you some basic missions and duties. I can also train you in simple skills, in case you need a refresher.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/naboo_imperial_trainer_1:s_943c7ba6", "series_no_training"}, -- I'd like training.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_series_complete)

barn_sinkko_convo_series_no_training = ConvoScreen:new {
	id = "series_no_training",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_34bc5f5e", -- You don't have the experience to apply to training.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_series_no_training)

barn_sinkko_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d25495b9", -- Pilot, I am singularly impressed. You have mastered the fundamentals of your profession and have performed beyond expectation and all without formal Imperial Naval Flight & Command training. I think it's time for a promotion.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_3f6a8711", "promotion"}, -- Thank you, sir. I do my best.
		{"@conversation/naboo_imperial_trainer_1:s_31967d85", "promotion_handler"}, -- Does this mean I get a new handler? I'm sick of working with you.
		{"@conversation/naboo_imperial_trainer_1:s_24890a54", "promotion_overdue"}, -- This recognition should have happened a long time ago.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_tier_done)

barn_sinkko_convo_promotion = ConvoScreen:new {
	id = "promotion",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_4e0900db", -- By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby commend you and bestow upon you the rank of Pilot Officer. Congratulations, Pilot Officer %NU.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_304d169e", "promotion_honored"}, -- I am honored, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion)

barn_sinkko_convo_promotion_honored = ConvoScreen:new {
	id = "promotion_honored",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_6e62e955", -- You should be. An officer rank is usually only given to those who graduate Naval Command School. All combat pilots in the Imperial Navy hold at least the rank of Pilot Officer. The Empire has recognized your ability and has seen fit to elevate you to the lowest rank of the command echelon.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_565cc8ba", "promotion_serve"}, -- I live only to serve the Emperor, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_honored)

barn_sinkko_convo_promotion_serve = ConvoScreen:new {
	id = "promotion_serve",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_4918bb61", -- As do we all. Now that you have achieved an official command rank, I am no longer your commanding officer. Although it pains me to lose such a fine pilot, you have been reassigned.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c7d82215", "new_assignment"}, -- What's the new assignment?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_serve)

barn_sinkko_convo_promotion_handler = ConvoScreen:new {
	id = "promotion_handler",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_14aa29c", -- I haven't exactly enjoyed your company, either. Yes, it does mean you will have a new commanding officer. I'll skip the formality. You are now a Pilot Officer. Personally, I think it's a mistake, but Naval Command likes the results you've shown.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b8ca7ab0", "promotion_reassigned"}, -- As long as you keep paying, I'll keep delivering.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_handler)

barn_sinkko_convo_promotion_reassigned = ConvoScreen:new {
	id = "promotion_reassigned",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7258dd22", -- The Empire has recognized your ability and has seen fit to elevate you to the lowest rank of the Naval command echelon. Don't abuse that trust. You have also been reassigned.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c7d82215", "new_assignment"}, -- What's the new assignment?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_reassigned)

barn_sinkko_convo_promotion_overdue = ConvoScreen:new {
	id = "promotion_overdue",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_30a48366", -- Perhaps. By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby commend you and bestow upon you the rank of Pilot Officer.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c0c8fe59", "promotion_killed"}, -- One day the Emperor himself will recognize my strength.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_overdue)

barn_sinkko_convo_promotion_killed = ConvoScreen:new {
	id = "promotion_killed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f6c21772", -- If you don't get yourself killed first. Now that you have achieved an official command rank, I am no longer your commanding officer. You have been reassigned.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c7d82215", "new_assignment"}, -- What's the new assignment?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_promotion_killed)

barn_sinkko_convo_new_assignment = ConvoScreen:new {
	id = "new_assignment",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_56dbc789", -- Your skill behind the controls of the TIE Fighter have peaked the interest of several high ranking officers. In particular, members of the Imperial Inquisition have expressed their desire to take over your training. They rarely request specific pilots, so you should consider this quite the honor.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6396820e", "inquisition_info"}, -- What is the Imperial Inquisition?
		{"@conversation/naboo_imperial_trainer_1:s_1e9a88a8", "report_to_fazoll"}, -- Who do I report to?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_new_assignment)

barn_sinkko_convo_inquisition_info = ConvoScreen:new {
	id = "inquisition_info",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_9be59baa", -- The Inquisition is a special judicial branch of the Imperial Intelligence bureau. Of all of the Imperial divisions, only the Inquisition has the ability to investigate criminals, judge them, and execute punishment without recourse to standard Imperial law. The Inquisition is powerful and secretive. To become a member of the Inquisition is a rare honor.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6396820e", "inquisition_info"}, -- What is the Imperial Inquisition?
		{"@conversation/naboo_imperial_trainer_1:s_1e9a88a8", "report_to_fazoll"}, -- Who do I report to?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_inquisition_info)

barn_sinkko_convo_report_to_fazoll = ConvoScreen:new {
	id = "report_to_fazoll",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1cfc4684", -- Under Inquisitor Fa'Zoll in the Emperor's Retreat has been assigned as your new commanding officer. I don't know anything about this person and frankly I don't want to. The last thing any officer wants is to be noticed by the Inquisition. Their eyes rest only upon the guilty.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_11b1315a", "fazoll_goodbye"}, -- I will report to Fa'Zoll at the Emperor's Retreat immediately.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_report_to_fazoll)

barn_sinkko_convo_fazoll_goodbye = ConvoScreen:new {
	id = "fazoll_goodbye",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_448fbf05", -- You will always address him as Inquisitor Fa'Zoll. Good luck, Pilot Officer %NU. You have done the Empire a great service.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_fazoll_goodbye)

barn_sinkko_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7ae0d223", -- Good to see you again. I've been authorized by my superiors to give you special training. Congratulations.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_19ff301f", "training_menu"}, -- What kind of training?
		{"@conversation/naboo_imperial_trainer_1:s_bf64734d", "training_declined"}, -- I don't want to learn anything right now.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_training_offer)

barn_sinkko_convo_training_declined = ConvoScreen:new {
	id = "training_declined",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fd4fe208", -- That is your choice, but you may not get this chance again.  I suggest that you take it while you can.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_training_declined)

barn_sinkko_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_366e0c62", -- You can learn about Imperial technology, equipment, space combat training, or astromech management.
	stopConversation = "false",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_training_menu)

barn_sinkko_convo_train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_438b2349", -- So far you've been flying a basic TIE.  The normal TIE is quite a bit more complicated than that.  For one thing, you'll find that you can install better components on it... better weapons, better armor, and so on.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c6d9f61", "trained_starships"}, -- I'd like to study that in detail.
		{"@conversation/naboo_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_train_starships)

barn_sinkko_convo_train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_754edf1d", -- With just a little more training, you could be using better equipment.  Missiles can really help to swing the battle your way, and this skill can allow you to use some good ones.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c6d9f61", "trained_weapons"}, -- I'd like to study that in detail.
		{"@conversation/naboo_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_train_weapons)

barn_sinkko_convo_train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2e48b5f1", -- It's no secret that Imperial pilots utilize some of the best starfighter tactics the galaxy has ever seen.  I can get you started on the road to mastering these uniquely Imperial procedures.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c6d9f61", "trained_procedures"}, -- I'd like to study that in detail.
		{"@conversation/naboo_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_train_procedures)

barn_sinkko_convo_train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_df76b2e8", -- Imperial astromech functionality is typically built into a rugged navicomputer, rather than those annoying sorts of astromech units that the Rebel Alliance relies on.  I can teach you how to utilize some of the basic functionality of the droid interface to normalize your shields, overload your weapons, and that sort of thing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c6d9f61", "trained_droid"}, -- I'd like to study that in detail.
		{"@conversation/naboo_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_train_droid)

barn_sinkko_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_trained_starships)

barn_sinkko_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_trained_weapons)

barn_sinkko_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_trained_procedures)

barn_sinkko_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_trained_droid)

barn_sinkko_convo_training_never_mind = ConvoScreen:new {
	id = "training_never_mind",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d825aeb0", -- Very well, good day Pilot.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_training_never_mind)

barn_sinkko_convo_duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d8487693", -- Pilot. I don't have any specific work for you at this time. You can now select your preferred operation from a list of general duties. Or, if you have enough experience, pursue training.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6a128385", "duty_explained"}, -- What is a duty?
		{"@conversation/naboo_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/naboo_imperial_trainer_1:s_3b3aabc1", "no_training_xp"}, -- I'd like training, sir.
		{"@conversation/naboo_imperial_trainer_1:s_47925d97", "enlist_ground"}, -- I want to join the ground forces
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_missions)

barn_sinkko_convo_duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d25c510b", -- Duty missions are open ended assignments. They end when you choose to end them. For example, if I assign you the task of hunting pirates, you can hunt as many pirates as you want. You can end the duty any time from the mission entry in your datapad. Perform duties to earn pay and build experience. Once you've received enough experience, I can instruct you on various aspects of the pilot's combat role.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/naboo_imperial_trainer_1:s_1091c96a", "duty_done_for_now"}, -- I'm done for now.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_explained)

barn_sinkko_convo_duty_done_for_now = ConvoScreen:new {
	id = "duty_done_for_now",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_88ffee3a", -- Report back to me when you are ready for some work.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_done_for_now)

barn_sinkko_convo_no_training_xp = ConvoScreen:new {
	id = "no_training_xp",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8e66d267", -- You don't have the experience for training, yet. Perform some more duties.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_no_training_xp)

barn_sinkko_convo_enlist_ground = ConvoScreen:new {
	id = "enlist_ground",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b3d4ac64", -- Naval command will not be happy with having to share its resources with the ground forces... but I suppose we ARE on the same team.  You do realize that even as a covert operative, you may be opening yourself to attack when you least expect it?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8efde2ae", "enlist_recruiter"}, -- Yes, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_enlist_ground)

barn_sinkko_convo_enlist_recruiter = ConvoScreen:new {
	id = "enlist_recruiter",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_48852667", -- I see.  I certainly hope you're not going to spend ALL of your time on the ground, Pilot.  But if you insist on becoming a soldier as well, go talk to an Imperial Recruiter.  He'll get you squared away.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_enlist_recruiter)

barn_sinkko_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_45b14b72", -- Good, I have a lot of work for you. The Emperor has decreed that the rebellion is to be driven from the Naboo system.  I can also assign you to escorting transports moving supplies.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_87bb7015", "destroy_duty"}, -- [Destroy Duty] I'm interested in hunting Rebel scum.
		{"@conversation/naboo_imperial_trainer_1:s_79ab4bbe", "escort_duty"}, -- [Escort Duty] I'm interested in escorting transports.
		{"@conversation/naboo_imperial_trainer_1:s_5ebce168", "duty_later"}, -- Actually, I'd like to do this later.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_menu)

barn_sinkko_convo_destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c80f115e", -- Rebel activity is still high enough that we need combat capable pilots on active duty locating and eliminating them. You have free reign to use lethal force against any member of the Rebellion you locate in the Naboo system. The Empire will pay a bounty on every one you destroy. Good luck.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a490d2c6", "duty_accepted"}, -- Alright.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_destroy_duty)

barn_sinkko_convo_escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_98c44634", -- With the recent increase in Rebel activity, our supply transports are at risk. The Empire would like to assign at least one TIE pilot to every transport operating in the Naboo system. You will be paid for every successful escort operation you complete.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a490d2c6", "duty_accepted"}, -- Alright.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_escort_duty)

barn_sinkko_convo_duty_later = ConvoScreen:new {
	id = "duty_later",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_101a6629", -- Report back to me when you are ready.
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_later)

barn_sinkko_convo_duty_accepted = ConvoScreen:new {
	id = "duty_accepted",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ee63dfa9", -- Report back to me when you would like a new duty or mission.
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_duty_accepted)

barn_sinkko_convo_recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_5797c779", -- Welcome to the Imperial Navy Recruitment Center. My name is Lieutenant Barn Sinkko. Are you interested in learning about the Imperial Navy?
	stopConversation = "false",
	animation = "spit_hands",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b00e89d5", "recruit_sign_up"}, -- I'd like to sign up, sir.
		{"@conversation/naboo_imperial_trainer_1:s_6df58958", "recruit_pay"}, -- I'm only interested if there's pay involved. I need work.
		{"@conversation/naboo_imperial_trainer_1:s_6fc304c8", "recruit_bust"}, -- I'm here to bust Rebel heads. Sign me up!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruitment)

barn_sinkko_convo_recruit_sign_up = ConvoScreen:new {
	id = "recruit_sign_up",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_890c4859", -- Glad to hear it! Normally, all of our pilots are officers. Usually that means years of study at a Naval school, as well as special recommendations from an Imperial accredited academic center. We have a new program for volunteer pilots. Noncombat support work, but all the normal military perks and pay.
	stopConversation = "false",
	animation = "conversation_1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_388cfea9", "recruit_volunteers"}, -- The Empire is recruiting volunteer pilots?
		{"@conversation/naboo_imperial_trainer_1:s_88f723eb", "recruit_sure"}, -- Sir, I would be honored to fly with the Imperial Navy.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_sign_up)

barn_sinkko_convo_recruit_volunteers = ConvoScreen:new {
	id = "recruit_volunteers",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_550165e", -- Yes, volunteers or conscripts. Rebel opposition has become more direct. We want to recruit new pilots for support duty, freeing up combat pilots for the front lines.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_519c6a35", "recruit_sure"}, -- It would be an honor to fly for you, sir.
		{"@conversation/naboo_imperial_trainer_1:s_37eb1d12", "recruit_declined"}, -- I'd rather not sign up right now, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_volunteers)

barn_sinkko_convo_recruit_sure = ConvoScreen:new {
	id = "recruit_sure",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_9a34f731", -- Are you sure you want to sign up? You'll be expected to follow orders and treat your superiors with respect. This is a tight operation and we deal harshly with insubordinate behavior.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_37650e5c", "recruit_sworn"}, -- Yes, sir! I want to be in the Imperial Navy.
		{"@conversation/naboo_imperial_trainer_1:s_37eb1d12", "recruit_declined"}, -- I'd rather not sign up right now, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_sure)

barn_sinkko_convo_recruit_declined = ConvoScreen:new {
	id = "recruit_declined",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c2685407", -- I hope you reconsider. Good day, citizen.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_declined)

barn_sinkko_convo_recruit_sworn = ConvoScreen:new {
	id = "recruit_sworn",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2fe328e", -- By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby conscript you to service with the non-officer flight rank of Pilot Initiate. May you serve the Empire dutifully. Welcome to the Imperial Navy.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "recruit_ship_granted"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_sworn)

barn_sinkko_convo_recruit_ship_granted = ConvoScreen:new {
	id = "recruit_ship_granted",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1d0e7364", -- I'm transferring a ship authorization and control device to your datapad. You'll need this to use your TIE Fighter. Should you lose your control device and access to your ship, you can apply for a new one at any time. Unfortunately, I'm only authorized to supply you with access to our low end TIE technology.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "first_assignment"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_ship_granted)

barn_sinkko_convo_first_assignment = ConvoScreen:new {
	id = "first_assignment",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b3408be1", -- Are you ready for your first assignment?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b6b25f13", "mission1_test"}, -- Yes, sir!
		{"@conversation/naboo_imperial_trainer_1:s_9bd7e7db", "mission1_credits"}, -- Alright! I'm ready to make some credits.
		{"@conversation/naboo_imperial_trainer_1:s_5bc07030", "mission1_what"}, -- What's the mission, sir?
		{"@conversation/naboo_imperial_trainer_1:s_b39049de", "mission1_train_when"}, -- When will you train me?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_first_assignment)

barn_sinkko_convo_recruit_pay = ConvoScreen:new {
	id = "recruit_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f6c0eced", -- We can definitely help you out, although we generally work with officer material from academic centers or Naval Training facilities. We have a new program for recruiting volunteers. The work pays and you'll be doing noncombat support missions.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_9c2b0ed7", "recruit_noncombat"}, -- Noncombat? Doesn't sound very interesting.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_pay)

barn_sinkko_convo_recruit_noncombat = ConvoScreen:new {
	id = "recruit_noncombat",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c760c195", -- There's always a chance you might get into combat during a support operation, but don't be so quick to want to get into a furball. The flyboys have a saying: 'dead is dead.'
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_798ef1b", "recruit_why"}, -- Cute. Why recruit volunteers?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_noncombat)

barn_sinkko_convo_recruit_why = ConvoScreen:new {
	id = "recruit_why",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fa138f3b", -- Since the destruction of the Death Star, we are increasing the number of resources directed against the Rebellion. We need to put our more experienced fighters on the front lines, which means we need new blood for support duty.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_e565620f", "recruit_pay_sure"}, -- Fair enough. As long as it pays, I'm willing to do the job.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_why)

barn_sinkko_convo_recruit_pay_sure = ConvoScreen:new {
	id = "recruit_pay_sure",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_9a34f731", -- Are you sure you want to sign up? You'll be expected to follow orders and treat your superiors with respect. This is a tight operation and we deal harshly with insubordinate behavior.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b7bdfe36", "recruit_sworn_pay"}, -- Sure, sign me up.
		{"@conversation/naboo_imperial_trainer_1:s_f967fcee", "recruit_pay_declined"}, -- No, this doesn't sound like my kind of job.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_pay_sure)

barn_sinkko_convo_recruit_sworn_pay = ConvoScreen:new {
	id = "recruit_sworn_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_95d2ba30", -- By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby conscript you to service with the flight rank of Pilot Initiate. May you serve the Empire dutifully. Welcome to the Imperial Navy.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f774e399", "recruit_ship_granted"}, -- Cool.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_sworn_pay)

barn_sinkko_convo_recruit_pay_declined = ConvoScreen:new {
	id = "recruit_pay_declined",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b317642c", -- Alright. Come back if you reconsider.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_pay_declined)

barn_sinkko_convo_recruit_bust = ConvoScreen:new {
	id = "recruit_bust",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8153a680", -- Slow down, friend. I appreciate the enthusiasm, believe me there are plenty of Rebels out there who need that kind of treatment, but the Imperial Navy is about more than combat duty.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_cf68a5b5", "recruit_combat"}, -- Yeah, but the combat duty is the part I'm interested in.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_bust)

barn_sinkko_convo_recruit_combat = ConvoScreen:new {
	id = "recruit_combat",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d2639576", -- Getting authorized for combat duty takes work. All of our pilots are officers. Usually that means years of study at a Naval school, as well as special recommendations from an Imperial accredited academic center.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_bc7d6b01", "recruit_great_pilot"}, -- I'm a great fighter pilot. You guys could use me.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_combat)

barn_sinkko_convo_recruit_great_pilot = ConvoScreen:new {
	id = "recruit_great_pilot",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a1302371", -- Since the destruction of the Death Star, we are increasing the number of resources directed against the Rebellion. We have a new program for volunteer recruits. You bypass the normal training and academic program for immediate assignments. Most of the assignments are noncombat oriented.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c297a8d4", "recruit_most"}, -- Most?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_great_pilot)

barn_sinkko_convo_recruit_most = ConvoScreen:new {
	id = "recruit_most",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ec61d38d", -- There's always a chance you might encounter Rebel resistance during a support operation, but it tends to be low. The real drawback to the program is that without formal Imperial training, you'll be on your own to learn the ropes of space combat.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6e71a8bb", "recruit_fly_shoot"}, -- I already know how to fly and shoot.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_most)

barn_sinkko_convo_recruit_fly_shoot = ConvoScreen:new {
	id = "recruit_fly_shoot",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e16ed40c", -- Then you're the kind of person we're looking for. Are you sure you want to sign up? You'll be expected to follow orders and treat your superiors with respect. This is a tight operation and we deal harshly with insubordinate behavior.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a9f55c8c", "recruit_sworn_pay"}, -- Yeah, I'm ready. Sign me up!
		{"@conversation/naboo_imperial_trainer_1:s_9d7bc2d3", "recruit_colzet"}, -- On second thought, this sounds like too much for me.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_fly_shoot)

barn_sinkko_convo_recruit_colzet = ConvoScreen:new {
	id = "recruit_colzet",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a54e8a02", -- We also have a volunteer division on Tatooine under the direction of Lt. Akal Colzet. He's a little extreme, but you could talk to him if you want to work in the Outer Rim. Good day.
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_recruit_colzet)

barn_sinkko_convo_mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_64fb691f", -- Good morning, Pilot Initiate. I hope you've had your Drall cakes and cream, because its going to be a busy day. Stand at attention!
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b6b25f13", "mission1_test"}, -- Yes, sir!
		{"@conversation/naboo_imperial_trainer_1:s_9bd7e7db", "mission1_credits"}, -- Alright! I'm ready to make some credits.
		{"@conversation/naboo_imperial_trainer_1:s_5bc07030", "mission1_what"}, -- What's the mission, sir?
		{"@conversation/naboo_imperial_trainer_1:s_b39049de", "mission1_train_when"}, -- When will you train me?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_offer)

barn_sinkko_convo_mission1_test = ConvoScreen:new {
	id = "mission1_test",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e9339227", -- Very good. Today we will be testing your basic flight capability. You'll need to have your ship prepped for flight.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6047677", "mission1_coords"}, -- I'm ready, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_test)

barn_sinkko_convo_mission1_coords = ConvoScreen:new {
	id = "mission1_coords",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8b493b63", -- Excellent. I'm transferring the coordinates of a local security patrol route. It's quiet up there, so you won't run into any trouble. Fly a single circuit of the patrol route to demonstrate your competence of basic ship operations. When you're done, return to me for further instructions.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a8c82b1c", "mission1_accept"}, -- Sir, yes sir!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_coords)

barn_sinkko_convo_mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_62ee6ad5", -- Pilot, dismissed!
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_accept)

barn_sinkko_convo_mission1_credits = ConvoScreen:new {
	id = "mission1_credits",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_5109c7f7", -- Restrain your enthusiasm, pilot. This is a simple training operation and it doesn't pay as much as a real duty. Today you will be subject to a basic test of skill. We want to make sure you are capable of performing the kind of operations that are common in naval duty.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_bd5ec97c", "mission1_attention"}, -- Lowered pay?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_credits)

barn_sinkko_convo_mission1_attention = ConvoScreen:new {
	id = "mission1_attention",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a1f66568", -- Stand at attention pilot! You are a member of the Imperial Navy. A modest level of respect for your superiors is required at all times. Complete this operation without incident and you will see better assignments, but for now you will shut up and listen! Is that clear?
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_59c8db72", "mission1_patrol_route"}, -- Sir, yes, sir!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_attention)

barn_sinkko_convo_mission1_patrol_route = ConvoScreen:new {
	id = "mission1_patrol_route",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_859cd287", -- I'm transferring the coordinates of a local security patrol route. It's quiet up there, so you won't run into any trouble. Fly a single circuit of the patrol route to demonstrate your competence of basic ship operations. When you're done, return to me for further instructions.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_d06e1eb", "mission1_mumble"}, -- (mumble) Yes, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_patrol_route)

barn_sinkko_convo_mission1_mumble = ConvoScreen:new {
	id = "mission1_mumble",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_486c459c", -- What was that, pilot?
	stopConversation = "false",
	animation = "listen",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a8c82b1c", "mission1_accept_sloppy"}, -- Sir, yes sir!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_mumble)

barn_sinkko_convo_mission1_accept_sloppy = ConvoScreen:new {
	id = "mission1_accept_sloppy",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ea289c5d", -- You should clean up your act pilot. You're sloppy. Report back to me when the mission is complete.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_accept_sloppy)

barn_sinkko_convo_mission1_what = ConvoScreen:new {
	id = "mission1_what",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_3f082a8b", -- Since you are new to the Imperial Navy, we have to subject you to a basic test of skill. We want to make sure you are capable of performing the kind of operations that are common in naval duty.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c7ca1c2c", "mission1_shooting"}, -- Will there be any shooting, sir?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_what)

barn_sinkko_convo_mission1_shooting = ConvoScreen:new {
	id = "mission1_shooting",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_14abbd01", -- Not today. I'm transferring the coordinates of a local security patrol route. It's pretty quiet up there, so you won't run into any trouble. Fly a single circuit of the patrol route to demonstrate your competence of basic ship operations. When you're done, return to me for further instructions.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_bb8aff15", "mission1_challenge"}, -- This is hardly a challenge.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_shooting)

barn_sinkko_convo_mission1_challenge = ConvoScreen:new {
	id = "mission1_challenge",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ce7aa9b7", -- I don't think it's wise to throw you into a combat situation without first measuring your abilities. Demonstrate that you can follow simple orders and then we can talk about giving you something that's more of a challenge.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8efde2ae", "mission1_accept_orders"}, -- Yes, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_challenge)

barn_sinkko_convo_mission1_accept_orders = ConvoScreen:new {
	id = "mission1_accept_orders",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_37979335", -- Report back to me when you are finished with the patrol.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_accept_orders)

barn_sinkko_convo_mission1_train_when = ConvoScreen:new {
	id = "mission1_train_when",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2670fd69", -- I'll train you when I think you're ready.  And I don't think you're ready.  Now are you ready for your first assignment?
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b6b25f13", "mission1_test"}, -- Yes, sir!
		{"@conversation/naboo_imperial_trainer_1:s_9bd7e7db", "mission1_credits"}, -- Alright! I'm ready to make some credits.
		{"@conversation/naboo_imperial_trainer_1:s_5bc07030", "mission1_what"}, -- What's the mission, sir?
		{"@conversation/naboo_imperial_trainer_1:s_b39049de", "mission1_train_when"}, -- When will you train me?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_train_when)

barn_sinkko_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7724d1e6", -- Pilot Initiate. I've been informed of your failure. Unfortunately, until you are able to complete that patrol without error, I cannot offer you further assignments with the Imperial Navy. I am very disappointed.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_16fc739e", "mission1_failed_again"}, -- I...
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_failed)

barn_sinkko_convo_mission1_failed_again = ConvoScreen:new {
	id = "mission1_failed_again",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_68951976", -- Get back out there and fly it again or turn in your authorization papers and hit the road. I don't have time for pilots who are incapable of completing simple assignments.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_59c8db72", "mission1_retry"}, -- Sir, yes, sir!
		{"@conversation/naboo_imperial_trainer_1:s_cb99174", "mission1_later"}, -- I have to study what went wrong.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_failed_again)

barn_sinkko_convo_mission1_retry = ConvoScreen:new {
	id = "mission1_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8d324b72", -- I've transferred the patrol coordinates to your datapad. Try harder this time, pilot.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_retry)

barn_sinkko_convo_mission1_later = ConvoScreen:new {
	id = "mission1_later",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_47691a6", -- Report to me when you are ready to attempt the patrol again.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_later)

barn_sinkko_convo_mission1_won = ConvoScreen:new {
	id = "mission1_won",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_76892f68", -- Pilot. Report on the status of your patrol.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_3a1ddc14", "mission1_attacked"}, -- I was attacked by a Rebel fighter wing, sir.
		{"@conversation/naboo_imperial_trainer_1:s_da5219a7", "mission1_stirring"}, -- Some Rebels were stirring up trouble, thought you said that wouldn't happen.
		{"@conversation/naboo_imperial_trainer_1:s_a6069c84", "mission1_easy_prey"}, -- Ran into some Rebel opposition, but they were easy prey.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_won)

barn_sinkko_convo_mission1_attacked = ConvoScreen:new {
	id = "mission1_attacked",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_916fe685", -- Rebels...near Naboo? I'm surprised. We haven't had any reports on significant Rebel activity for quite a while. They must be working on a new operation. We'll scramble some sensor craft and try to track down where the Rebels were headed.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_add5962c", "mission1_pay_wing"}, -- I eliminated the entire Rebel fighter wing, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_attacked)

barn_sinkko_convo_mission1_pay_wing = ConvoScreen:new {
	id = "mission1_pay_wing",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f50739c7", -- You did? Impressive. I suppose that means we won't be able to track their heading, but under the circumstances you did the right thing. My congratulations. You've shown that not only can you fly a basic patrol, but you aren't bad with a laser cannon either. Here's your payment for the job.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission1_rebel_problem"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_pay_wing)

barn_sinkko_convo_mission1_rebel_problem = ConvoScreen:new {
	id = "mission1_rebel_problem",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1614fceb", -- Report back to me when you are ready for another duty. I think we should look into this Rebel problem.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_rebel_problem)

barn_sinkko_convo_mission1_stirring = ConvoScreen:new {
	id = "mission1_stirring",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_9c044885", -- Rebels? We haven't had any reports on significant Rebel activity in this region for some time. Are you sure they were Rebels?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f5559c6a", "mission1_disturbing"}, -- Rebel markings on the hull of X-Wing spec fighters.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_stirring)

barn_sinkko_convo_mission1_disturbing = ConvoScreen:new {
	id = "mission1_disturbing",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e1d8cd2a", -- This is disturbing. We'll need to increase our sensor coverage and try to determine where the rebels are coming from. The Emperor's Retreat is located on Naboo... the Rebels may very well be planning some kind of sabotage.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8bc18758", "mission1_pay_money"}, -- I eliminated the patrol. I expect to be paid for that.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_disturbing)

barn_sinkko_convo_mission1_pay_money = ConvoScreen:new {
	id = "mission1_pay_money",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a9bcd9f0", -- Good job. I'm crediting you for the mission, along with a little extra. You performed admirably. I can't say I appreciate your money motivation, but as long as you continue to do your job as efficiently, you can expect further rewards.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_fc27931b", "mission1_thank_you_sir"}, -- Thanks.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_pay_money)

barn_sinkko_convo_mission1_thank_you_sir = ConvoScreen:new {
	id = "mission1_thank_you_sir",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_20f98863", -- That's 'Thank you, sir.'
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_efa5623a", "mission1_look_into"}, -- Thank you...sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_thank_you_sir)

barn_sinkko_convo_mission1_easy_prey = ConvoScreen:new {
	id = "mission1_easy_prey",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_610250ee", -- Rebels? Near Naboo? Are you certain?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8c85a270", "mission1_adjutant"}, -- The burning scrap of their ships still bear Rebel insignia.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_easy_prey)

barn_sinkko_convo_mission1_adjutant = ConvoScreen:new {
	id = "mission1_adjutant",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_feb83ab9", -- Well, you're certainly sure of yourself. My adjutant will send someone out to confirm the kills. If there are active Rebel fighter wings near Naboo, we need to be concerned. The Emperor's Retreat is located on Naboo...the Rebels may very well be planning some kind of sabotage.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_a5bc9cf4", "mission1_pay_sure"}, -- My payment?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_adjutant)

barn_sinkko_convo_mission1_pay_sure = ConvoScreen:new {
	id = "mission1_pay_sure",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_25dee8db", -- Here's credit for the mission, plus a little extra for the danger involved. You performed well. Eliminating the Rebel fighter wing was the right decision, given the circumstances.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission1_look_into"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_pay_sure)

barn_sinkko_convo_mission1_look_into = ConvoScreen:new {
	id = "mission1_look_into",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_9b6aa4b0", -- Report back to me when you are ready for another duty. We need to look into this Rebel problem.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission1_look_into)

barn_sinkko_convo_mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c15ca8cc", -- Pilot Initiate. At ease. Since your discovery of Rebel activity in the Naboo region, I've received further reports of Rebel sightings. The most recent report was from Commercial Transport 'Kantari.' Several hours ago, 'Kantari' spotted a Rebel fighter wing moving close to a commercial traffic route.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_78d92576", "mission2_orders"}, -- What are my orders, sir?
		{"@conversation/naboo_imperial_trainer_1:s_48d418c", "mission2_kill"}, -- Let me guess, you want me to kill them?
		{"@conversation/naboo_imperial_trainer_1:s_5ee0d552", "mission2_better"}, -- This sounds like a better mission...
		{"@conversation/naboo_imperial_trainer_1:s_8c9c5f1a", "mission2_no_training"}, -- Will you train me now?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_offer)

barn_sinkko_convo_mission2_orders = ConvoScreen:new {
	id = "mission2_orders",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e1147f5d", -- I want you to hunt down and destroy the Rebel vessels in the area of the 'Kantari' attack. The Rebels are still out there and we must make them pay. Eliminate them. The security of the Naboo system must be maintained.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission2_risk"}, -- Aye, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_orders)

barn_sinkko_convo_mission2_risk = ConvoScreen:new {
	id = "mission2_risk",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e24fd46f", -- You've already proven your combat capability. I'm taking a risk assigning you this mission, don't let me down. Remember, they could be anywhere in the system!  Intelligence reports there are several areas of high Rebel activity, which will be a good place to start your search.
	stopConversation = "false",
	animation = "standing_raise_fist",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6f12f083", "mission2_accept"}, -- I won't, sir. You can count on me.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_risk)

barn_sinkko_convo_mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a44450e3", -- Good luck, pilot. Report back to me when you've completed the mission.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_accept)

barn_sinkko_convo_mission2_kill = ConvoScreen:new {
	id = "mission2_kill",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f3e660d", -- Some of them, at least. I want you to hunt down and destroy the Rebel vessels in the area of the 'Kantari' attack. The Rebels are still out there and we must make them pay. The security of the Naboo system must be maintained.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_de1d8561", "mission2_accept_pay"}, -- I want to be paid for each Rebel I take out.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_kill)

barn_sinkko_convo_mission2_accept_pay = ConvoScreen:new {
	id = "mission2_accept_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c17b4421", -- If you complete the mission, you'll get your pay. Report back to me when you're done.  Don't forget:  they could be anywhere in the system! Intelligence reports there are several areas of high Rebel activity, which will be a good place to start your search.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_accept_pay)

barn_sinkko_convo_mission2_better = ConvoScreen:new {
	id = "mission2_better",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bc1b7622", -- You performed admirably in combat with the last fighter wing. We want to see an encore. I want you to hunt down and destroy the rebel vessels in the area of the 'Kantari' attack. The Rebels are still out there and we must make them pay. The security of the Naboo system must be maintained.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_44a60f99", "mission2_accept_cocky"}, -- Tell your adjutant he'll have more kills to confirm soon.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_better)

barn_sinkko_convo_mission2_accept_cocky = ConvoScreen:new {
	id = "mission2_accept_cocky",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bb78a22c", -- Don't get too cocky. The Rebels would be stupid to think we haven't detected them. Even though we don't know their exact location, they may be expecting an armed response. Intelligence reports there are several areas of high Rebel activity, which will be a good place to start your search.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_accept_cocky)

barn_sinkko_convo_mission2_no_training = ConvoScreen:new {
	id = "mission2_no_training",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_6554bb6c", -- Absolutely not.  You need to complete a few more assignments before I'll train you.  Now, about that Rebel fighter wing...
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_78d92576", "mission2_orders"}, -- What are my orders, sir?
		{"@conversation/naboo_imperial_trainer_1:s_48d418c", "mission2_kill"}, -- Let me guess, you want me to kill them?
		{"@conversation/naboo_imperial_trainer_1:s_5ee0d552", "mission2_better"}, -- This sounds like a better mission...
		{"@conversation/naboo_imperial_trainer_1:s_8c9c5f1a", "mission2_no_training"}, -- Will you train me now?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_no_training)

barn_sinkko_convo_mission2_aborted = ConvoScreen:new {
	id = "mission2_aborted",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ada6c751", -- I've already received the reports regarding your failure to eliminate the Rebel fighter wing. I'm disappointed. If the Rebels think that Imperial defense on Naboo is weak, they may launch a costly offensive. They have no hope of winning, but we also don't want to see that kind of war here.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_29ad976e", "mission2_aborted_orders"}, -- I'll go after them again.
		{"@conversation/naboo_imperial_trainer_1:s_19288eda", "mission2_rethink"}, -- I think I need to rethink things.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_aborted)

barn_sinkko_convo_mission2_aborted_orders = ConvoScreen:new {
	id = "mission2_aborted_orders",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_730419d7", -- Very well. The Rebels are apparently still in the same area. You must ensure their destruction this time. It's important that we maintain proper security on this planet and that means crushing even minor Rebel activity.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission2_aborted_retry"}, -- Aye, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_aborted_orders)

barn_sinkko_convo_mission2_aborted_retry = ConvoScreen:new {
	id = "mission2_aborted_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_5fdfcebf", -- Report back to me when you've successfully eliminated the Rebels.  And do not abort your mission again!
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_aborted_retry)

barn_sinkko_convo_mission2_rethink = ConvoScreen:new {
	id = "mission2_rethink",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_3b1fee95", -- Report to me when you are ready to give it another try.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_rethink)

barn_sinkko_convo_mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d66c56cf", -- I've already received the reports on the damage to your ship and your failure to eliminate the Rebel fighter wing. I'm disappointed. If the Rebels think that Imperial defense on Naboo is weak, they may launch a costly offensive. They have no hope of winning, but we also don't want to see that kind of war here.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f9660223", "mission2_failed_orders"}, -- I'll get the damage repaired and go after them again.
		{"@conversation/naboo_imperial_trainer_1:s_19288eda", "mission2_rethink"}, -- I think I need to rethink things.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_failed)

barn_sinkko_convo_mission2_failed_orders = ConvoScreen:new {
	id = "mission2_failed_orders",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_730419d7", -- Very well. The Rebels are apparently still in the same area. You must ensure their destruction this time. It's important that we maintain proper security on this planet and that means crushing even minor Rebel activity.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission2_retry"}, -- Aye, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_failed_orders)

barn_sinkko_convo_mission2_retry = ConvoScreen:new {
	id = "mission2_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_81849afb", -- Report back to me when you've successfully eliminated the Rebels.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_retry)

barn_sinkko_convo_mission2_won = ConvoScreen:new {
	id = "mission2_won",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_11dce039", -- Great job, Pilot. I was able to oversee your assault on the Rebels via sensor relay. You displayed a particularly impressive tactical sense. Even the Deck Commander expressed his surprise. Congratulations on a fine mission.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f9081167", "mission2_pay_honored"}, -- I'm honored, sir.
		{"@conversation/naboo_imperial_trainer_1:s_5c314851", "mission2_mercenary"}, -- You get what you pay for.
		{"@conversation/naboo_imperial_trainer_1:s_e80d813e", "mission2_pay_combat"}, -- I'd like more combat duty, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_won)

barn_sinkko_convo_mission2_pay_honored = ConvoScreen:new {
	id = "mission2_pay_honored",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_36ccf586", -- As you should be. Very few academy graduates could have pulled that off, much less a conscript. Here is your payment for the mission, plus a bonus. I've also received permission to have your personal profile sent to the Commissions Office. They'll start work on your custom TIE flightsuit.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission2_frontline"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_pay_honored)

barn_sinkko_convo_mission2_frontline = ConvoScreen:new {
	id = "mission2_frontline",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_62645c46", -- Keep up this level of performance and you're sure to see some frontline action. We're still trying to determine the Rebels' intentions. For now, things seem quiet, so go get some rest and report back when you are ready for another mission.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_frontline)

barn_sinkko_convo_mission2_mercenary = ConvoScreen:new {
	id = "mission2_mercenary",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ae102a", -- Your mercenary spirit is unsettling. I would like to think that you have some kind of patriotic belief. Something that drives you to help us, instead of joining the Rebellion.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_fe48d61f", "mission2_pay_philosophy"}, -- I'm not interested in debating personal philosophies.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_mercenary)

barn_sinkko_convo_mission2_pay_philosophy = ConvoScreen:new {
	id = "mission2_pay_philosophy",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a7f18ee0", -- Very well.  Here is your payment for the mission. I've also received permission to have your personal profile sent to the Commissions Office so they can start work on your custom TIE flightsuit.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_5e2a2bb1", "mission2_drink"}, -- Sounds good.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_pay_philosophy)

barn_sinkko_convo_mission2_drink = ConvoScreen:new {
	id = "mission2_drink",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2501f4f1", -- Don't drink all of those credits. You'll want to keep some spare for ship repairs and upgrades.
	stopConversation = "false",
	animation = "belly_laugh",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f79f892a", "mission2_hmph"}, -- I think I can manage my money just fine by myself.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_drink)

barn_sinkko_convo_mission2_hmph = ConvoScreen:new {
	id = "mission2_hmph",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bda5060f", -- Hmph. Report back to me when you're ready for your next assignment.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_hmph)

barn_sinkko_convo_mission2_pay_combat = ConvoScreen:new {
	id = "mission2_pay_combat",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b33bb9fd", -- You may very well receive it. For now, I want to continue to ease you into things. You may have some natural talent, but there is more to space combat than talent alone. Here is your payment for the mission, plus a bonus. I've also received permission to have your personal profile sent to the Commissions Office. They'll start work on your custom TIE flightsuit.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission2_predisposed"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_pay_combat)

barn_sinkko_convo_mission2_predisposed = ConvoScreen:new {
	id = "mission2_predisposed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b01365ea", -- You do seem naturally predisposed to this kind of work. I'm glad you chose to work with the Imperial Navy. Report back to me when you're ready for your next assignment.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission2_predisposed)

barn_sinkko_convo_mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2bbdc667", -- Pilot. We've analyzed your recent encounters with the Rebellion and have been unable to determine any pattern to their activity. The planetary security teams have decided these are probably probing raids.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_37b6c92d", "mission3_purpose"}, -- What is the purpose behind the raids?
		{"@conversation/naboo_imperial_trainer_1:s_8c9c5f1a", "mission3_almost_ready"}, -- Will you train me now?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_offer)

barn_sinkko_convo_mission3_almost_ready = ConvoScreen:new {
	id = "mission3_almost_ready",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a38ce775", -- You're almost ready, I think... but right now this is more important.  Pay attention!  I'll train you after you've completed a couple more assignments.  Right now, you need to deal with those Rebels.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_37b6c92d", "mission3_purpose"}, -- What is the purpose behind the raids?
		{"@conversation/naboo_imperial_trainer_1:s_8c9c5f1a", "mission3_almost_ready"}, -- Will you train me now?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_almost_ready)

barn_sinkko_convo_mission3_purpose = ConvoScreen:new {
	id = "mission3_purpose",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ce63cdc0", -- That isn't clear. The Rebels may be trying to find a weakness in the planetary defense grid, or they may be trying to distract us from some other operation. There is one small lead.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_df1a0b2a", "mission3_e62"}, -- What is that?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_purpose)

barn_sinkko_convo_mission3_e62 = ConvoScreen:new {
	id = "mission3_e62",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_aa61375", -- Apparently, the Imperial Army has been receiving shipments of a new blaster prototype, the 'E-62'. For some political reason, the Ground Force Command deemed it wasn't critical to inform the Navy of these shipments. Strategic Planning believes the probing raids are meant to locate and capture one of the transports ferrying an E-62 shipment.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_8a2b78b3", "mission3_prevent"}, -- Can we prevent that?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_e62)

barn_sinkko_convo_mission3_prevent = ConvoScreen:new {
	id = "mission3_prevent",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e660e010", -- We need to confirm our suspicions. Make the Rebels show their hand. If we assign too many ships to protecting E-62 shipments, we may miss the Rebels' actual objective.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b24a6589", "mission3_plan"}, -- It sounds like you already have a plan.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_prevent)

barn_sinkko_convo_mission3_plan = ConvoScreen:new {
	id = "mission3_plan",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_eb4bd86c", -- We've thrown something together. I'm transferring a set of coordinates to your datapad. I want you to fly this route until an E-62 transport contacts you. The transport is a decoy, being piloted by a Naval Intelligence operative. The transport will broadcast lightly encrypted information on E-62 and will fly through an area we believe the Rebels may be monitoring.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_dca3d46b", "mission3_bait"}, -- You want to draw them out.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_plan)

barn_sinkko_convo_mission3_bait = ConvoScreen:new {
	id = "mission3_bait",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2a29a3de", -- Yes, exactly. If they go for the bait, we'll know for certain that the prototype weapons are their goal. Obviously, you need to ensure the operative survives. You should also attempt to destroy any Rebels that attack, but that isn't a requirement. If things get hairy, protect the transport and then flee.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission3_accept"}, -- Aye, sir.
		{"@conversation/naboo_imperial_trainer_1:s_1598dcb2", "mission3_flee"}, -- I'll be gone at the first sign of trouble.
		{"@conversation/naboo_imperial_trainer_1:s_b0ef8499", "mission3_no_coward"}, -- Flee? I'm no coward!
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_bait)

barn_sinkko_convo_mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bb462a81", -- Very good. We're counting on you to trap the Rebels. Don't let me down.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_accept)

barn_sinkko_convo_mission3_flee = ConvoScreen:new {
	id = "mission3_flee",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_3d71cce7", -- You have to make sure the transport escapes before you leave. We will not leave one of our own behind.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_71ab0619", "mission3_accept_credits"}, -- Just make sure you have my credits ready.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_flee)

barn_sinkko_convo_mission3_accept_credits = ConvoScreen:new {
	id = "mission3_accept_credits",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a8264b81", -- Reveal the Rebel plan and keep the transport alive and you'll be paid. Report back to me when you've completed the mission.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_accept_credits)

barn_sinkko_convo_mission3_no_coward = ConvoScreen:new {
	id = "mission3_no_coward",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_4774404f", -- There will be a time to strike against the Rebels once we know what their intentions are. This mission is for information gathering. If you get a chance to take out a target of opportunity, then by all means do so, but do not risk your life at this stage in the operation.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_2ddcdfff", "mission3_accept_priority"}, -- The Rebels don't stand a chance.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_no_coward)

barn_sinkko_convo_mission3_accept_priority = ConvoScreen:new {
	id = "mission3_accept_priority",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fa7b1fcc", -- Keep the transport alive. That is a priority directive. Report back to me when the mission is complete.
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_accept_priority)

barn_sinkko_convo_mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d82fc96f", -- Pilot Initiate, that was a complete disaster! Strategic Command wants you stripped of your commission. Fortunately for you, I still believe in this operation. I've convinced them to give you another try. Get back out there and find those Rebels!
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_b6b25f13", "mission3_retry"}, -- Yes, sir!
		{"@conversation/naboo_imperial_trainer_1:s_668cac00", "mission3_later"}, -- I need to think about the mission and figure out what went wrong.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_failed)

barn_sinkko_convo_mission3_retry = ConvoScreen:new {
	id = "mission3_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_34975e9f", -- Report back to me when you've successfully completed the mission.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_retry)

barn_sinkko_convo_mission3_later = ConvoScreen:new {
	id = "mission3_later",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d2ed722", -- Maybe you should reconsider your chosen profession! Come back when you want to try again.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_later)

barn_sinkko_convo_mission3_won = ConvoScreen:new {
	id = "mission3_won",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b6683056", -- Welcome back, Pilot. Please report the results of the operation to bait a Rebel attack.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_fe5a7681", "mission3_solved"}, -- The Rebels attacked exactly as expected, sir.
		{"@conversation/naboo_imperial_trainer_1:s_c0265f54", "mission3_decisive"}, -- Yeah, they tried to take the transport.
		{"@conversation/naboo_imperial_trainer_1:s_43d18dec", "mission3_stupid"}, -- You know, these Rebels are really stupid people.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_won)

barn_sinkko_convo_mission3_solved = ConvoScreen:new {
	id = "mission3_solved",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1301bfd7", -- Then our mystery is solved. The ground forces will need to track down how information on the prototypes leaked, but we know enough to secure further shipments of the technology. This is very good news.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_30e39201", "mission3_pay"}, -- Glad I could help...
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_solved)

barn_sinkko_convo_mission3_pay_bandolier = ConvoScreen:new {
	id = "mission3_pay_bandolier",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_424f48fc", -- Here's your pay for the operation and another bonus for exceptional duty. I also received your Imperial flight suit, but you'll never fit into this. Take this bandolier, instead.  At least it'll help you to keep your things organized.  The helmet will take a while longer to be finished. Each helmet contains special electronic equipment calibrated to the user.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_729d0338", "mission3_next_phase"}, -- Thank you, Sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_pay_bandolier)

barn_sinkko_convo_mission3_pay = ConvoScreen:new {
	id = "mission3_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fe2c6775", -- Here's your pay for the operation and another bonus for exceptional duty. I also received your Imperial flight suit. Please wear it while you are on duty. The helmet will take a while longer to be finished. Each helmet contains special electronic equipment calibrated to the user.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_729d0338", "mission3_next_phase"}, -- Thank you, Sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_pay)

barn_sinkko_convo_mission3_next_phase = ConvoScreen:new {
	id = "mission3_next_phase",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_d9f28087", -- The command staff will begin planning the next phase of the operation. We need to eliminate the remainder of the Rebel forces. Your next assignment will probably involve doing just that. Report back to me when you are ready.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_next_phase)

barn_sinkko_convo_mission3_decisive = ConvoScreen:new {
	id = "mission3_decisive",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_78efc377", -- I'm glad to see you didn't leave at the first sign of trouble. The Intelligence operative says you acted decisively.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_3e7988c1", "mission3_pleased"}, -- Sometimes I surprise myself.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_decisive)

barn_sinkko_convo_mission3_pleased = ConvoScreen:new {
	id = "mission3_pleased",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_336e9422", -- Naval Command will be pleased at the outcome of the operation. Our mystery is solved. The ground forces will need to track down how information on the prototypes leaked, but we know enough to secure further shipments of the technology.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_30e39201", "mission3_payment_wait"}, -- Glad I could help...
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_pleased)

barn_sinkko_convo_mission3_payment_wait = ConvoScreen:new {
	id = "mission3_payment_wait",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f7924d1a", -- I suppose you're waiting for your payment.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_cb0c70a2", "mission3_credited"}, -- I was wondering when you were going to get to that part.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_payment_wait)

barn_sinkko_convo_mission3_credited_bandolier = ConvoScreen:new {
	id = "mission3_credited_bandolier",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_69a4d9f8", -- I'm having your account credited. You've earned it. I also had a bandolier made for you, since you'll never fit into a uniform... at least you can keep your things organized.  The helmet will take a while longer to arrive.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6456f762", "mission3_difficult"}, -- Great, now I'll look good at my funeral.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_credited_bandolier)

barn_sinkko_convo_mission3_credited = ConvoScreen:new {
	id = "mission3_credited",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1110cd35", -- I'm having your account credited. You've earned it. I also have your TIE flight suit. You should wear it while you're on duty. The helmet will take a while longer to arrive.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6456f762", "mission3_difficult"}, -- Great, now I'll look good at my funeral.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_credited)

barn_sinkko_convo_mission3_difficult = ConvoScreen:new {
	id = "mission3_difficult",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_abb72a4a", -- You are quite difficult to work with.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_9c80b7c7", "mission3_report"}, -- I'll take that as a complement.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_difficult)

barn_sinkko_convo_mission3_report = ConvoScreen:new {
	id = "mission3_report",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_fa956108", -- The command staff will begin planning the next phase of the operation. Report back to me when you're ready for another assignment.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_report)

barn_sinkko_convo_mission3_stupid = ConvoScreen:new {
	id = "mission3_stupid",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7bdc0484", -- I take it they attacked as expected?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_61eba7c4", "mission3_intellect"}, -- I wouldn't have fallen for that trap.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_stupid)

barn_sinkko_convo_mission3_intellect = ConvoScreen:new {
	id = "mission3_intellect",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_7c4734cc", -- Well, it's a good thing for us that the Rebels lack your towering intellect. Our mystery is solved. The Rebels were here for the E-62 after all. Ground forces will need to track down how information on the prototypes leaked, but we know enough to secure further shipments of the technology.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_f02428e4", "mission3_army"}, -- Do you think I could get one of those blasters?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_intellect)

barn_sinkko_convo_mission3_army_bandolier = ConvoScreen:new {
	id = "mission3_army_bandolier",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_f123cba6", -- Let's leave the ground combat to the Army, shall we? I do have your payment for completing this operation. I also had a bandolier made for you, since you're much too large for a flight suit. The helmet will take a while longer to be finished. Each helmet contains special electronic equipment calibrated to the user.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_89bc583c", "mission3_next_phase"}, -- Very well, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_army_bandolier)

barn_sinkko_convo_mission3_army = ConvoScreen:new {
	id = "mission3_army",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_53f85004", -- Let's leave the ground combat to the Army, shall we? I do have your payment for completing this operation. I also received your Imperial flight suit. The helmet will take a while longer to be finished. Each helmet contains special electronic equipment calibrated to the user.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_89bc583c", "mission3_next_phase"}, -- Very well, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission3_army)

barn_sinkko_convo_mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_a6e045f3", -- Don't bother taking a seat, this will be brief. We've had a breakthrough. At 03:00 last night, an intelligence operative working under cover delivered a report detailing recent Rebel activities in the Naboo system.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_651c4d7a", "mission4_breakthrough"}, -- And...
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_offer)

barn_sinkko_convo_mission4_breakthrough = ConvoScreen:new {
	id = "mission4_breakthrough",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_cfb2442e", -- It's as we thought. The Rebels have dispatched a small combat wing to attempt to recover a shipment of E-62 prototype blasters. Based on intelligence projections and the results of your engagements, it seems likely only a few of the original team are still alive.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_78d92576", "mission4_leader"}, -- What are my orders, sir?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_breakthrough)

barn_sinkko_convo_mission4_leader = ConvoScreen:new {
	id = "mission4_leader",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_368fd90b", -- We have discovered the possible location of the Rebel team leader. You are to be dispatched immediately. Travel to the waypoint I'm transferring to your datapad. Find and eliminate him. Don't worry if he isn't there when you arrive. Take out a few of his fellow pilots in the area and he will show up.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission4_key"}, -- Aye, sir.
		{"@conversation/naboo_imperial_trainer_1:s_7e347138", "mission4_underestimate"}, -- He's as good as dead.
		{"@conversation/naboo_imperial_trainer_1:s_7478cd28", "mission4_train_after"}, -- Will you train me after this?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_leader)

barn_sinkko_convo_mission4_key = ConvoScreen:new {
	id = "mission4_key",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_2ac29eb6", -- You've shown a lot of promise so far, Pilot. This is a key assignment. We expect the Rebel team leader to be a highly skilled and well trained pilot. Don't underestimate him.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_ea112eca", "mission4_accept"}, -- I'll be ready, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_key)

barn_sinkko_convo_mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_bcadc07d", -- Good, report back to me when the mission is complete.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_accept)

barn_sinkko_convo_mission4_underestimate = ConvoScreen:new {
	id = "mission4_underestimate",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_c5d91ca3", -- Don't underestimate the Rebel leader. He may be a highly skilled pilot and possibly have special operations training. He will probably be more skilled than the other ships you've encountered so far.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_e034da9", "mission4_accept_mind"}, -- I'll keep that in mind.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_underestimate)

barn_sinkko_convo_mission4_accept_mind = ConvoScreen:new {
	id = "mission4_accept_mind",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_e8a06d76", -- Report back to me when the mission is complete.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_accept_mind)

barn_sinkko_convo_mission4_train_after = ConvoScreen:new {
	id = "mission4_train_after",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8529aa51", -- Yes.  I'd train you NOW if this weren't so urgent.  So make it quick.  Eliminate that Rebel leader!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_4aa87431", "mission4_key"}, -- Aye, sir.
		{"@conversation/naboo_imperial_trainer_1:s_7e347138", "mission4_underestimate"}, -- He's as good as dead.
		{"@conversation/naboo_imperial_trainer_1:s_7478cd28", "mission4_train_after"}, -- Will you train me after this?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_train_after)

barn_sinkko_convo_mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_38becb2d", -- Report on the status of your operation against the Rebel team leader, Pilot.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_59d306ec", "mission4_failed_explain"}, -- (Relate information on your inability to defeat the Rebel leader.)
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_failed)

barn_sinkko_convo_mission4_failed_explain = ConvoScreen:new {
	id = "mission4_failed_explain",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_1a5d8b73", -- Don't underestimate him. A particularly skilled and charismatic leader might explain the increase in the pirate activity. You must continue to hunt him down.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_e034da9", "mission4_retry"}, -- I'll keep that in mind.
		{"@conversation/naboo_imperial_trainer_1:s_3de840b5", "mission4_later"}, -- I need to spend some time practicing.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_failed_explain)

barn_sinkko_convo_mission4_retry = ConvoScreen:new {
	id = "mission4_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_adf9eee2", -- Report to me when you've completed your mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_retry)

barn_sinkko_convo_mission4_later = ConvoScreen:new {
	id = "mission4_later",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_6868d86b", -- Return to me when you are ready to take the mission.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_later)

barn_sinkko_convo_mission4_won = ConvoScreen:new {
	id = "mission4_won",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ec04a9b3", -- Report on the status of your operation against the Rebel leader, Pilot.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_e12b6418", "mission4_masterful"}, -- I located and destroyed him, sir.
		{"@conversation/naboo_imperial_trainer_1:s_4d7a1ae4", "mission4_asset"}, -- Spaced him. Now, about my fee?
		{"@conversation/naboo_imperial_trainer_1:s_2a1af001", "mission4_impressive"}, -- I defeated him with ease.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_won)

barn_sinkko_convo_mission4_masterful = ConvoScreen:new {
	id = "mission4_masterful",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b5d0e16a", -- This information will please the Naval Command. No doubt they will also realize that part of your success came from my masterful instruction. I think you may have done us both a great service.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_d09c1ecb", "mission4_pay"}, -- Just doing my duty, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_masterful)

barn_sinkko_convo_mission4_pay_head = ConvoScreen:new {
	id = "mission4_pay_head",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_247ae5a6", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions. Nevertheless, keep it as a symbol of the technological and military might of the Empire.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c6aae4cb", "mission4_cranial"}, -- Cranial proportions?
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_pay_head)

barn_sinkko_convo_mission4_cranial = ConvoScreen:new {
	id = "mission4_cranial",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_42dfe6db", -- Indeed. The Empire rarely enlists non-Humans as pilots, and so we are poorly prepared to equip someone such as yourself. But do not be discouraged. Your current standing in the Imperial Navy is a testament to your abilities.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission4_earned"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_cranial)

barn_sinkko_convo_mission4_pay = ConvoScreen:new {
	id = "mission4_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b8f011dc", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile. Wear this whenever you are on duty as a symbol of the Empire's technological and military might.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_987445c9", "mission4_earned"}, -- Thank you, sir.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_pay)

barn_sinkko_convo_mission4_earned = ConvoScreen:new {
	id = "mission4_earned",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_49ab06fa", -- You've earned it, Pilot. You have exceeded the expectations of this program and of myself. Your duty has not ended, however. Return when you are ready to take on another operation.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_earned)

barn_sinkko_convo_mission4_asset = ConvoScreen:new {
	id = "mission4_asset",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_8273f08f", -- Naval Command will be pleased. I didn't expect someone like you to be such an asset to the Empire.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_c01da9e4", "mission4_sneer"}, -- (Sneer at him.) Just pay me.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_asset)

barn_sinkko_convo_mission4_sneer_head = ConvoScreen:new {
	id = "mission4_sneer_head",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_15daf24e", -- You don't take complements very well. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6f5e007c", "mission4_cant_wear"}, -- It's kinda ugly lookin.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_sneer_head)

barn_sinkko_convo_mission4_cant_wear = ConvoScreen:new {
	id = "mission4_cant_wear",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_19d7d16a", -- It's too bad you can't wear it. It would be a marked improvement. Report back to me when you're ready for more work.
	stopConversation = "true",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_cant_wear)

barn_sinkko_convo_mission4_sneer = ConvoScreen:new {
	id = "mission4_sneer",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_dfd0987b", -- You don't take complements very well. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_6f5e007c", "mission4_wear_it"}, -- It's kinda ugly lookin.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_sneer)

barn_sinkko_convo_mission4_wear_it = ConvoScreen:new {
	id = "mission4_wear_it",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_95f0e74b", -- Even so, I suggest you wear it. It would be a marked improvement. Report back to me when you're ready for more work.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_wear_it)

barn_sinkko_convo_mission4_impressive = ConvoScreen:new {
	id = "mission4_impressive",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b1f99085", -- This information will please the Naval Command. You have done an impressive job, Pilot. Perhaps you really are all that you claim.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_ce681825", "mission4_pay_bold"}, -- You should have realized this long ago.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_impressive)

barn_sinkko_convo_mission4_pay_bold = ConvoScreen:new {
	id = "mission4_pay_bold",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_b8f011dc", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile. Wear this whenever you are on duty as a symbol of the Empire's technological and military might.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_trainer_1:s_cd024d84", "mission4_suits"}, -- It looks intimidating. I like it.
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_pay_bold)

barn_sinkko_convo_mission4_suits = ConvoScreen:new {
	id = "mission4_suits",
	leftDialog = "@conversation/naboo_imperial_trainer_1:s_ca3578cc", -- I think it suits you. You have exceeded the expectations of this program and of myself. Your duty has not ended, however. Return when you are ready to take on another operation.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
barn_sinkko_convo_template:addScreen(barn_sinkko_convo_mission4_suits)

addConversationTemplate("barn_sinkko_convo_template", barn_sinkko_convo_template)
