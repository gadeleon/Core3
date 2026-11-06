-- Commander Jhon Oberhaur (Storm Squadron tier 2) conversation; ported from SWG-Source tatooine_imperial_trainer_2.java with the pre-NGE client lines (feature storm-tier2-oberhaur). Handler: oberhaurConvoHandler.
oberhaur_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "oberhaurConvoHandler",
	screens = {}
}

oberhaur_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_21772e5a", -- I'm sorry, I can't help you.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_not_pilot)

oberhaur_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7a3165e7", -- Hold on, there, %TU.  I've got strict orders about you.  You're GROUNDED!  Finished!  You won't be flying for the Empire ever again!
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_f3ce4b22", "grounded_reports"}, -- Why?  What did I do?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded)

oberhaur_convo_grounded_reports = ConvoScreen:new {
	id = "grounded_reports",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_46b74bbf", -- We've had reports of pro-Rebel, anti-Imperial activity from you.  Obviously, you can't be trusted.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_a78a4ac3", "grounded_shot"}, -- What do I do now?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded_reports)

oberhaur_convo_grounded_shot = ConvoScreen:new {
	id = "grounded_shot",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_c6b6729b", -- Well, if it were up to me, you'd be shot, now.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_3ed9f29c", "grounded_serious"}, -- No, seriously!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded_shot)

oberhaur_convo_grounded_serious = ConvoScreen:new {
	id = "grounded_serious",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_ad8385f7", -- I am being serious.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ae06e68f", "grounded_prove"}, -- But I want to fly for the Imperial Navy!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded_serious)

oberhaur_convo_grounded_prove = ConvoScreen:new {
	id = "grounded_prove",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_92b2297b", -- Hrmph.  In that case, if I were you, I'd be trying to do SOMETHING to prove to the Empire that you are 100% behind us in this war, and not some sort of Rebel sympathizer.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_2f84158b", "grounded_figure_out"}, -- How can I do that?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded_prove)

oberhaur_convo_grounded_figure_out = ConvoScreen:new {
	id = "grounded_figure_out",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7970189a", -- I don't know, %NU.  But if I were you, I'd be trying to figure out SOME way of doing it.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_grounded_figure_out)

oberhaur_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_a59c7bd7", -- It looks like you're busy with an assignment already. Come talk to me when you're done.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_a30c1a53", "on_mission_outstanding"}, -- Yes sir!
		{"@conversation/tatooine_imperial_trainer_2:s_8d17fc6e", "travel_need_ship"}, -- How do I travel to another system?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_on_mission)

oberhaur_convo_on_mission_outstanding = ConvoScreen:new {
	id = "on_mission_outstanding",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_4838444a", -- Outstanding.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_on_mission_outstanding)

oberhaur_convo_travel_capable = ConvoScreen:new {
	id = "travel_capable",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_e0d37cc2", -- I've seen one of your ships in the hangar. It looks capable of hyperspace travel. After you launch, just open your Hyperspace Map and select the system to which you want to travel. Pretty simple, no?
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_9288900f", "travel_carry_on"}, -- I understand.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_capable)

oberhaur_convo_travel_carry_on = ConvoScreen:new {
	id = "travel_carry_on",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_16cbd029", -- Excellent. Carry on, Pilot. Good luck.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_carry_on)

oberhaur_convo_travel_need_ship = ConvoScreen:new {
	id = "travel_need_ship",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_ad7e53a9", -- Firstly, you will need a vessel capable of hyperspace travel. Unfortunately the Empire does not issue TIE craft equipped with the engine upgrades and hyperdrive abilities you will need.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_81198b45", "travel_why"}, -- Why is that?
		{"@conversation/tatooine_imperial_trainer_2:s_dcf3ae18", "travel_carry_on"}, -- Then I will acquire a new ship, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_need_ship)

oberhaur_convo_travel_why = ConvoScreen:new {
	id = "travel_why",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_6c1a8ce", -- The war has taken a significant toll... even considering the strength our great Galactic Empire. These more modern TIE designs are only available on the free market through third party engineers.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_c81a4272", "travel_where"}, -- Where can I find one?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_why)

oberhaur_convo_travel_where = ConvoScreen:new {
	id = "travel_where",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_f542dcb0", -- Most lawful Shipwrights will put ship chassis up for sale on vendors in local shops. So, locate a vendor or contact a Shipwright, find a TIE fighter that you're capable of handling, and purchase a suite of upgrades... including a modern engine.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_c14f8951", "travel_handle"}, -- How do I know what I can handle?
		{"@conversation/tatooine_imperial_trainer_2:s_1d4a07d0", "travel_vendor"}, -- Where can I find such a vendor?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_where)

oberhaur_convo_travel_handle = ConvoScreen:new {
	id = "travel_handle",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_2358dc3e", -- I don't have time to explain this all to you, pilot! Double-check what skills you have. Make sure that you are certified to fly the ship you plan to buy.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_9288900f", "travel_launch"}, -- I understand.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_handle)

oberhaur_convo_travel_launch = ConvoScreen:new {
	id = "travel_launch",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_fced7bf", -- Once you have launched, simply activate your Hyperspace map and select the system to which you would like to travel.
	stopConversation = "false",
	animation = "point_up",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_2c4789b", "travel_begone"}, -- Understood.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_launch)

oberhaur_convo_travel_begone = ConvoScreen:new {
	id = "travel_begone",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_884a3faf", -- Outstanding. Now begone.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_begone)

oberhaur_convo_travel_vendor = ConvoScreen:new {
	id = "travel_vendor",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_466882ff", -- Tell you what. How about I just go out and buy everything for you?
	stopConversation = "false",
	animation = "offer_affection",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_5d988999", "travel_not_nice"}, -- That would be nice. Thanks!
		{"@conversation/tatooine_imperial_trainer_2:s_43862ef7", "travel_planetary_map"}, -- Of course not, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_vendor)

oberhaur_convo_travel_not_nice = ConvoScreen:new {
	id = "travel_not_nice",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_773fa657", -- No, that would not be nice! Check your planetary map, or just ask around to find a Shipwright vendor.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_c64c7c75", "travel_launch"}, -- I will do that immediately.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_not_nice)

oberhaur_convo_travel_planetary_map = ConvoScreen:new {
	id = "travel_planetary_map",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_237eaf5c", -- Check your planetary map, or just ask around to find a Shipwright vendor.
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_c64c7c75", "travel_launch"}, -- I will do that immediately.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_travel_planetary_map)

oberhaur_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_61e8cd5e", -- Greetings, pilot. I don't see you on the Storm Squadron roster. Why have you come here?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_4854758d", "off_track_no_missions"}, -- I would like to request a mission.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_off_track)

oberhaur_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_df611704", -- I cannot assign you a mission, but I do have a number of elective duty assignments. If you like, I can give you a briefing.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b2a924ab", "duty_briefing"}, -- I'd like a briefing.
		{"@conversation/tatooine_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_off_track_duties)

oberhaur_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_a784219e", -- Only your commanding officer can assign you missions, pilot. Go back to your own unit.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_off_track_no_missions)

oberhaur_convo_duty_briefing = ConvoScreen:new {
	id = "duty_briefing",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_cacf4333", -- As I said, there are several areas of Nym's power that need to be neutralized. First, the relative isolation of the Lok System has allowed Nym to build a significant rogue fleet. While the size of this fleet pales in comparison to that of the Empire, the potential for its use in rapid strike or terrorist operations cannot be ignored. It must be eliminated.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_5102164f", "duty_briefing_smugglers"}, -- (Nod and listen.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_briefing)

oberhaur_convo_duty_briefing_smugglers = ConvoScreen:new {
	id = "duty_briefing_smugglers",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_1524504", -- Second, Nym has established a significant trade in contraband and weapons technology. We believe this is his primary method of income. Fortunately, the majority of Nym's smuggler captains are only dubiously loyal. We believe that these criminals can be convinced to abandon Nym's cause with the application of modest force.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_45fa29cc", "duty_briefing_pirates"}, -- (Grin and listen.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_briefing_smugglers)

oberhaur_convo_duty_briefing_pirates = ConvoScreen:new {
	id = "duty_briefing_pirates",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_a329a20", -- While the smuggler trade is a primary source of income for Nym, he relies on piracy to make up the balance. You could fly as an 'escort' for some Imperial transports in the Lok system to bait and trap Nym's pirates. There's no need to capture them alive for interrogation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_briefing_pirates)

oberhaur_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5b4ccb84", -- You have operational discretion to choose an assignment from the areas outlined by Imperial Intelligence in your briefing. I can also instruct you in the use of new technology if you think you're ready.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_45f4f7db", "duty_fleet"}, -- I'd like to engage Nym's combat fleet.
		{"@conversation/tatooine_imperial_trainer_2:s_a6363375", "duty_smugglers"}, -- I'd like to pressure Nym's smuggler fleet.
		{"@conversation/tatooine_imperial_trainer_2:s_721e2818", "duty_pirates"}, -- I'd like to trap a few pirates.
		{"@conversation/tatooine_imperial_trainer_2:s_b0d3b474", "training_not_ready"}, -- I'm ready for training.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_menu)

oberhaur_convo_duty_fleet = ConvoScreen:new {
	id = "duty_fleet",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5c222b7", -- We have a tactical intelligence and telemetry probe inside the Lok System. Go to Lok and download enemy position information from the probe. Use that information to hunt Nym's fighter wings. Any damage you inflict will make it harder for Nym to carry out military operations.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b6b25f13", "duty_fleet_aces"}, -- Yes, sir!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_fleet)

oberhaur_convo_duty_fleet_aces = ConvoScreen:new {
	id = "duty_fleet_aces",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_2f3095bd", -- Be on your guard. Nym may decide to dispatch his ace pilots once you're detected.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_fleet_aces)

oberhaur_convo_duty_smugglers = ConvoScreen:new {
	id = "duty_smugglers",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7d4535c0", -- Nym has smuggler fleets moving through Lok on a regular basis. Since he controls most of the system, he doesn't worry about stealth. Intercept the fleets, destroy the escorts, and disable the smuggler transports. That should be enough show of force to convince the smuggler captains to surrender. Once you've secured the transports, escort them to interrogation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b6b25f13", "duty_smugglers_guard"}, -- Yes, sir!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_smugglers)

oberhaur_convo_duty_smugglers_guard = ConvoScreen:new {
	id = "duty_smugglers_guard",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_435dd8f2", -- Nym's officers may try to recover the transports, so be on your guard.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_smugglers_guard)

oberhaur_convo_duty_pirates = ConvoScreen:new {
	id = "duty_pirates",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_28a8e342", -- Imperial Intelligence has supplied us with several convoy freighters disguised to emit weapon and equipment signatures. That should attract the interest of Nym's pirate gangs. Fly escort and eliminate the pirates as they show up.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b6b25f13", "duty_pirates_alive"}, -- Yes, sir!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_pirates)

oberhaur_convo_duty_pirates_alive = ConvoScreen:new {
	id = "duty_pirates_alive",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_b1097134", -- The freighters aren't carrying anything valuable, but we don't want the pilots to die needlessly. Make sure you keep them alive.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_pirates_alive)

oberhaur_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_883a28d9", -- Pilot, it is time for you to learn some new skills. It is important that you keep sharp and keep your skills at the top of their game in order to succeed as an Imperial pilot. Are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_a4faf714", "training_not_ready"}, -- I am ready for some training, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_training_offer)

oberhaur_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_44d66989", -- You've shown considerable improvement in ability since joining the Squadron. It's time to allow you access to the next level of training and technology. I remind you that anything you learn is highly confidential, security rating Gamma Three. You may not share your knowledge with fellow officers of any rank at or below your own. What area would you like to train in?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ae26c22", "training_later"}, -- Let me think about this for a bit.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_training_menu)

oberhaur_convo_training_not_ready = ConvoScreen:new {
	id = "training_not_ready",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_311f2b4", -- Flying Officer %NU, I have the highest level of respect for you, but I want to see more results in the operation against Nym before I authorize you for advanced training.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_89bc583c", "training_report_back"}, -- Very well, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_training_not_ready)

oberhaur_convo_training_report_back = ConvoScreen:new {
	id = "training_report_back",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_49f3270b", -- Report back to me when you're ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_training_report_back)

oberhaur_convo_training_later = ConvoScreen:new {
	id = "training_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7b25fbc3", -- You're cleared for training, so let me know when you are ready to begin.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_training_later)

oberhaur_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_486da900", -- Your continued success will rely on your ability to make maximum use of all new Imperial technology. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_trained_starships)

oberhaur_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_8bd72bb5", -- Mastering proper use of heavy weapons technology is key. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_trained_weapons)

oberhaur_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_c4880407", -- Developing new levels of tactical and physical excellence will be critical in realizing your true potential. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_trained_procedures)

oberhaur_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_31804e15", -- Understanding how to rapidly and efficiently manage the complex systems on board a fighter is a necessary step in your development as a pilot. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_trained_droid)

oberhaur_convo_trained_report = ConvoScreen:new {
	id = "trained_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9c0c10ef", -- Report back to me when you are ready for a new assignment.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_trained_report)

oberhaur_convo_report_to_alozen = ConvoScreen:new {
	id = "report_to_alozen",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_1e3ab8f3", -- You need to report to Field Commander Alozen at the Imperial outpost on Yavin 4. He will be handling your assignments for the time being.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_report_to_alozen)

oberhaur_convo_alozen_orders = ConvoScreen:new {
	id = "alozen_orders",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9d8051f1", -- High Command has decided that Nym's operations have been sufficiently neutralized. Any aid he renders the Rebellion from this point will be inconsequential to the outcome of the overall conflict. You are commended for your contribution to the Lok operation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "yavin_reassigned"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_alozen_orders)

oberhaur_convo_yavin_reassigned = ConvoScreen:new {
	id = "yavin_reassigned",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_c13418d8", -- We've been reassigned to the Yavin system. Yavin has been plagued with insurgent activity ever since the destruction of the Death Star. This is the front line of the civil war and our assignments in the region will be dangerous.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_72d41043", "yavin_training"}, -- I am prepared.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_yavin_reassigned)

oberhaur_convo_yavin_training = ConvoScreen:new {
	id = "yavin_training",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_93a06155", -- I hope you've studied those information programs I gave you. You'll need your new training.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_de381f95", "yavin_salvage"}, -- I have, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_yavin_training)

oberhaur_convo_yavin_salvage = ConvoScreen:new {
	id = "yavin_salvage",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5f703249", -- Increasing insurgent activity in the Yavin system has drawn the interest of High Command. Since the destruction of the Death Star, the Imperial Engineering Corps have carried out an ongoing scrap recovery operation. Command suspects the Rebels may be conducting their own salvage operation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6598178f", "yavin_alozen"}, -- Interesting.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_yavin_salvage)

oberhaur_convo_yavin_alozen = ConvoScreen:new {
	id = "yavin_alozen",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_ed65d4cb", -- You'll be doing some leg work on this mission. I want you to go to the Imperial outpost on Yavin 4. Report to Field Commander Alozen, of the Imperial Army, for a situation report. He's requested the assistance of the fleet. Storm Squadron has been assigned to see to his needs.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_8efde2ae", "yavin_ground_pounder"}, -- Yes, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_yavin_alozen)

oberhaur_convo_yavin_ground_pounder = ConvoScreen:new {
	id = "yavin_ground_pounder",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_ca6a5e04", -- Alozen is a ground pounder and may show you a little disrespect. Ignore it and behave professionally. I know you'll do the right thing.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_yavin_ground_pounder)

oberhaur_convo_claw_duties = ConvoScreen:new {
	id = "claw_duties",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_b56905cc", -- Naval Command wants us to continue to harass Nym's forces. Their assessment of the situation is positive, but they feel that inflicting further damage is necessary. They want to avoid any possibility of having to bring a large force to bear against Nym should he decide to openly declare support for the insurgents.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_claw_duties)

oberhaur_convo_claw_won = ConvoScreen:new {
	id = "claw_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9f814876", -- Report what you've found regarding Nym's plans.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_e44ffcd2", "claw_impressive"}, -- [Relate the destruction of the Kimogila's Claw.]
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_claw_won)

oberhaur_convo_claw_impressive = ConvoScreen:new {
	id = "claw_impressive",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_94a3f917", -- Incredible work, pilot. You've managed to eliminate several of Nym's key commanders with a single decisive strike. I'm impressed by your initiative in this matter.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_198d54a6", "claw_pay"}, -- It should keep Nym busy for a while.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_claw_impressive)

oberhaur_convo_claw_pay = ConvoScreen:new {
	id = "claw_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_78af2fb0", -- Indeed. Nym will have to find replacements and rebuild his command. I'm transferring a pay reward to your account. I will also inform High Command of the status of our operation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_94999d7b", "claw_next_step"}, -- What is the next step?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_claw_pay)

oberhaur_convo_claw_next_step = ConvoScreen:new {
	id = "claw_next_step",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_46d97b9f", -- For the time being, continue to harass Nym's forces. Naval Operations will deliver new orders when they want us to withdraw. So far this has been a high impact operation with little drain on resources. They will probably want to draw it out a bit longer before moving us to a new theater.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_claw_next_step)

oberhaur_convo_find_morv = ConvoScreen:new {
	id = "find_morv",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_fea3d7f3", -- You can find our agent, Morv, at Nym's stronghold on Lok. He'll be disguised as a fuel technician. Use the codephrase *I'm here to clean the antimatter condenser.* He is probably not using his real name so you will have to find him. Report to me when you have his information.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_find_morv)

oberhaur_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_70a7d20e", -- Good to see you, Flying Officer %NU. You've been making significant headway into reducing Nym's influence in the Lok system, so High Command has selected you for a special operation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6abf6436", "m3_agent_report"}, -- What's the assignment?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m3_offer)

oberhaur_convo_m3_agent_report = ConvoScreen:new {
	id = "m3_agent_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_350d8ffa", -- Our remaining agent within Nym's stronghold has succeeded in avoiding detection. His latest report indicates that Nym is frustrated by our progress and has ordered several of his captains to plan a heavy armed response.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_fb7f6474", "m3_find_out"}, -- What kind of response?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m3_agent_report)

oberhaur_convo_m3_find_out = ConvoScreen:new {
	id = "m3_find_out",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_d424ba86", -- We aren't sure and we need to find out. Contact with the agent has been limited. I need you to go to Nym's stronghold on Lok and find the agent. His name is Trizan Morv, but he is undercover as one of Nym's Fuel Technicians. See if you can find out from Morv what Nym has planned. If you get the opportunity, stop those plans.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_edeedb42", "m3_codephrase"}, -- How will I recognize Morv?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m3_find_out)

oberhaur_convo_m3_codephrase = ConvoScreen:new {
	id = "m3_codephrase",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_6f520748", -- Morv is disguised as one of Nym's fuel technicians. He is undercover so he will not be using his real name, you will have to find him. You can identify yourself to him with the codephrase 'I'm here to clean the antimatter condenser.' Be discrete. We don't usually send pilots to interact with intelligence officers, but in this case you may be best equipped to handle whatever Nym has planned.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_746fbd0c", "m3_good_luck"}, -- I'll do what I can.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m3_codephrase)

oberhaur_convo_m3_good_luck = ConvoScreen:new {
	id = "m3_good_luck",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_d4648675", -- Return to me when you have information. Good luck, %NU.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m3_good_luck)

oberhaur_convo_duty_after_m2 = ConvoScreen:new {
	id = "duty_after_m2",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_3321cb2d", -- Imperial Intelligence has identified several key elements of Nym's power base. I have a briefing prepared. Or if you've already examined the briefing material, you can select a type of operation to begin.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b2a924ab", "duty_briefing"}, -- I'd like a briefing.
		{"@conversation/tatooine_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_duty_after_m2)

oberhaur_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_23ca92a1", -- Report on the status of the hostage rescue operation, soldier.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ae061ee", "m2_outstanding"}, -- I was able to recover all of our agents, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_won)

oberhaur_convo_m2_outstanding = ConvoScreen:new {
	id = "m2_outstanding",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_e27dc0f8", -- Outstanding work. You've managed to defuse what could have become a major incident. I'm impressed, HQ is impressed, and most of all the rest of Storm Squadron is impressed.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "m2_promotion"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_outstanding)

oberhaur_convo_m2_promotion = ConvoScreen:new {
	id = "m2_promotion",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_48636f93", -- Pilot Officer %NU, it's time that you were elevated to full operational status within the Squadron. You are hereby granted the rank of Flying Officer. Congratulations Flying Officer %NU. You are now a full member of the Storm Squadron. Fly with honor and fight with the Emperor's own fury.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b6b25f13", "m2_pay_increase"}, -- Yes, sir!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_promotion)

oberhaur_convo_m2_pay_increase = ConvoScreen:new {
	id = "m2_pay_increase",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_6927e4a9", -- SS Command has authorized a duty pay increase for your exceptional performance and new rank. Since you are now a Flying Officer, you may select your own assignment.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_89bc583c", "m2_lok_ops"}, -- Very well, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_pay_increase)

oberhaur_convo_m2_lok_ops = ConvoScreen:new {
	id = "m2_lok_ops",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_88311d58", -- For the time being, Storm Squadron has been assigned to continue operations in the Lok system. High Command has decided that Nym has grown far too prominent and he represents a potential threat that must be checked.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_afce570", "m2_threat"}, -- He has extensive resources, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_lok_ops)

oberhaur_convo_m2_threat = ConvoScreen:new {
	id = "m2_threat",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_203532fd", -- Exactly. Initial reports indicated that Nym was merely an outsystem pirate. Clearly those reports were incorrect. His operation has grown beyond a simple pirate outpost and he now poses a possible military threat should he enter the war on the side of the insurgency. We want to destroy his resource base and devastate his space power.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_fe63bc1a", "m2_same_page"}, -- My thoughts exactly.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_threat)

oberhaur_convo_m2_same_page = ConvoScreen:new {
	id = "m2_same_page",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_8739f4b1", -- I'm glad we're on the same page. Since you have complete operational discretion, it will be up to you to decide how to attack Nym's power base. Other Storm Squadron operatives will be carrying out similar assignments. Nym will soon regret casting his lot in with the insurgents.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_91223b5c", "duty_after_m2"}, -- I'm ready to begin immediately, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_same_page)

oberhaur_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_3f799832", -- Pilot, you're supposed to be on your ship! Get up there and intercept the hostage transport immediately!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_8efde2ae", "m2_retry"}, -- Yes, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_failed)

oberhaur_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9940eb95", -- Return to me once you've freed the hostages and delivered them to safety. Your window to pull off this operation is limited, so get your jax in gear soldier! Dismissed!
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_retry)

oberhaur_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7f95f0a5", -- Get suited up, you're being scrambled immediately.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b6b25f13", "m2_decrypted"}, -- Yes, sir!
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_offer)

oberhaur_convo_m2_decrypted = ConvoScreen:new {
	id = "m2_decrypted",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_22461041", -- The information you retrieved from the pirate officer has been decrypted. It's a transport and transfer schedule for the hostages. Nym apparently doesn't want them located in his main stronghold. He's having them moved to a secret location and he's moving them today.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_61657d0f", "m2_ransom"}, -- I see.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_decrypted)

oberhaur_convo_m2_ransom = ConvoScreen:new {
	id = "m2_ransom",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_f7876bb3", -- Nym may be planning on ransoming the officers or he may decide to hand them over to the insurgents. Imperial Intel thinks the latter is more likely. What better way to win favor with his fellow criminals. We need to recover our agents before they are moved to an unknown location.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d55f2579", "m2_flight_plan"}, -- I'm ready to go.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_ransom)

oberhaur_convo_m2_flight_plan = ConvoScreen:new {
	id = "m2_flight_plan",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5ea454fa", -- Here's the flight plan of the transport. Expect it to be under guard. The operatives on board are valuable: we want them alive. Your mission is to disable the transport. Fire on the engines or the reactor. Either one should be enough to give our boys a chance to take over the ship.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_1940763a", "m2_escort"}, -- Are you sure they'll be able to capture the ship?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_flight_plan)

oberhaur_convo_m2_escort = ConvoScreen:new {
	id = "m2_escort",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_cf8e92fc", -- Positive. We suspect the only reason they don't try to escape now is Nym's armed escort. You need to take out the escort to give the operatives a shot at survival.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_bc375f79", "m2_protect"}, -- Got it.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_escort)

oberhaur_convo_m2_protect = ConvoScreen:new {
	id = "m2_protect",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_986aeb7b", -- Once the agents capture the ship, protect her while she calculates a hyperspace jump. The Lok region isn't well known, so it may take some time. Nym may try to recapture the ship or just take you both out. That cannot happen.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_8efde2ae", "m2_accept"}, -- Yes, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_protect)

oberhaur_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9940eb95", -- Return to me once you've freed the hostages and delivered them to safety. Your window to pull off this operation is limited, so get your jax in gear soldier! Dismissed!
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m2_accept)

oberhaur_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_f91e446d", -- What have you learned so far, %NU?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_f432c46f", "m1_manifest"}, -- (Transfer the information to Oberhaur.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_won)

oberhaur_convo_m1_manifest = ConvoScreen:new {
	id = "m1_manifest",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_263bc84b", -- Ah, this is interesting. Looks like a manifest detailing the transport of the hostages. Part of it is encoded, but it doesn't look like a very strong form of encryption.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_22a1fc52", "m1_pay"}, -- Perhaps Imperial Intelligence can crack it.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_manifest)

oberhaur_convo_m1_pay = ConvoScreen:new {
	id = "m1_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_60c9f5e1", -- I know just the man for the job. Good work, pilot. Here is a consignment fee for completing the job. Stay close, though. Once this data is cracked we will need to move quickly to secure the hostages.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "m1_bite_to_eat"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_pay)

oberhaur_convo_m1_bite_to_eat = ConvoScreen:new {
	id = "m1_bite_to_eat",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5c1a4059", -- Go grab yourself a quick bite to eat and then report back. We'll have these logs cracked in a nanosec.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_bite_to_eat)

oberhaur_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_706c2e4c", -- Have you managed to track down information on the hostages, pilot?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_29d0a2db", "m1_retry"}, -- I've run into some trouble so far.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_failed)

oberhaur_convo_m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_99306072", -- Get back out there. You need to find one of the Nym's Lieutenants. He'll have probably entrusted them with information regarding the status of the hostages. Disable the pirate scum and inspect his ship for information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_8efde2ae", "m1_retry_luck"}, -- Yes, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_retry)

oberhaur_convo_m1_retry_luck = ConvoScreen:new {
	id = "m1_retry_luck",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_aceff31e", -- Good luck, pilot.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_retry_luck)

oberhaur_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_eac44789", -- Applicant, I hope you are well rested because today you begin working with Storm Squadron. Stand at attention for briefing!
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_a787fa2e", "m1_lok_operation"}, -- (Stand at attention.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_offer)

oberhaur_convo_m1_lok_operation = ConvoScreen:new {
	id = "m1_lok_operation",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_46185cf9", -- The Imperial Intelligence organization has, for several years, conducted a small operation in the Lok system. The target of the operation is a pirate warlord named Nym. Lok holds little to no strategic value for the Empire, so only limited resources have been invested in the operation.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_5102164f", "m1_rebel_link"}, -- (Nod and listen.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_lok_operation)

oberhaur_convo_m1_rebel_link = ConvoScreen:new {
	id = "m1_rebel_link",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_5fdd804", -- While Lok has no overt value, there have been indications that the Rebellion may be working with the pirate Nym to undermine Imperial interests. Imperial Intelligence set up their infiltration operation to probe the pirate connections to the Rebellion and, if connections were found, sever them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_7a761694", "m1_agent_missed"}, -- (Continue to listen.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_rebel_link)

oberhaur_convo_m1_agent_missed = ConvoScreen:new {
	id = "m1_agent_missed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_eda80412", -- At 09:50 this morning, the primary ground agent in the Lok operation failed to contact his handler and deliver a status report. Imperial Intelligence immediately reported the failure, suspecting the agent had been compromised. At 11:32, shortly following that report, an as of yet uncompromised agent contacted the handler.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_f1f7e3da", "m1_compromised"}, -- (Listen intently.)
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_agent_missed)

oberhaur_convo_m1_compromised = ConvoScreen:new {
	id = "m1_compromised",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_3cfac67e", -- The agent indicated that the rest of the operation, five men total, had indeed been compromised and taken captive by pirate gunmen loyal to Nym.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_61657d0f", "m1_no_demands"}, -- I see.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_compromised)

oberhaur_convo_m1_no_demands = ConvoScreen:new {
	id = "m1_no_demands",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_4d6d2800", -- As of this time, Nym has not delivered demands. It is unclear if the hostages are still alive. Imperial Intelligence and Naval Command have decided that the situation must be resolved before it spirals into a major incident. Storm Squadron has been assigned with the cleanup.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d1be90a9", "m1_plan"}, -- What's the plan?
		{"@conversation/tatooine_imperial_trainer_2:s_36fb7ae1", "m1_who_is_nym"}, -- Who is Nym?
		{"@conversation/tatooine_imperial_trainer_2:s_712ea0b5", "m1_hostages"}, -- What will Nym do to the hostages?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_no_demands)

oberhaur_convo_m1_who_is_nym = ConvoScreen:new {
	id = "m1_who_is_nym",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_8ebfa37e", -- Nym is a Feeorin. The self proclaimed 'Lord' of the Lok system. He's a pirate and absolute scum. Many years ago, Nym was a war hero, when the Trade Federation attempted to capture Naboo. He seems to have forgotten what it means to be a hero and now he simply preys on the spacelanes.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d1be90a9", "m1_plan"}, -- What's the plan?
		{"@conversation/tatooine_imperial_trainer_2:s_36fb7ae1", "m1_who_is_nym"}, -- Who is Nym?
		{"@conversation/tatooine_imperial_trainer_2:s_712ea0b5", "m1_hostages"}, -- What will Nym do to the hostages?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_who_is_nym)

oberhaur_convo_m1_hostages = ConvoScreen:new {
	id = "m1_hostages",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_4d13db1b", -- We aren't entirely sure. It's out of character for him to murder needlessly. He's scum, but he's also smart enough to avoid Imperial scrutiny. The fact that he hasn't released the spies tells me that he's probably going to hand them over to the Rebellion. High Command probably considers that worse than if he just killed them.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d1be90a9", "m1_plan"}, -- What's the plan?
		{"@conversation/tatooine_imperial_trainer_2:s_36fb7ae1", "m1_who_is_nym"}, -- Who is Nym?
		{"@conversation/tatooine_imperial_trainer_2:s_712ea0b5", "m1_hostages"}, -- What will Nym do to the hostages?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_hostages)

oberhaur_convo_m1_plan = ConvoScreen:new {
	id = "m1_plan",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_4afba144", -- First, we need to determine the status and location of the hostages. If the hostages are dead, we need to launch a hostile response. If the hostages are alive, we need to find and recover them. Your orders are to dispatch to the Lok system immediately.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_8efde2ae", "m1_accept"}, -- Yes, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_plan)

oberhaur_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7936c7db", -- Lok is remote and Nym's pirates travel openly. Locate one of his Lieutenants. Disable the pirate's ship and search it for information on the whereabouts of the hostages. You may then eliminate the pirate. We are uncertain of these officer's location but a good bet is you can find them around the Lok station after they have taken off from the planet surface on their way to hyperspace.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_2c4789b", "m1_return"}, -- Understood.
		{"@conversation/tatooine_imperial_trainer_2:s_401fdcbd", "travel_need_ship"}, -- How do I get to Lok?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_accept)

oberhaur_convo_m1_return = ConvoScreen:new {
	id = "m1_return",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_15b68f56", -- Return to me with any information you find. It is critical that you move quickly on this. Good luck.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_m1_return)

oberhaur_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_82669139", -- Glad to meet you. I'm Commander Oberhaur, of Storm Squadron. Several members of the squadron are currently bunking here Bestine on shore leave. We operate from the ISD Accuser, in Tatooine Orbit. Being shut up in a Star Destroyer for weeks is bad for the men's morale, so we're down here for leave.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6ae72fac", "about_storm"}, -- What is the Storm Squadron?
		{"@conversation/tatooine_imperial_trainer_2:s_6a67413c", "about_accuser"}, -- What's the ISD Accuser?
		{"@conversation/tatooine_imperial_trainer_2:s_e8e1f35f", "apply"}, -- I'm here to apply to Storm Squadron.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_greeting)

oberhaur_convo_about_storm = ConvoScreen:new {
	id = "about_storm",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_b9024ec3", -- Storm Squadron is an elite special operations team within the Imperial Navy. Our jurisdiction extends to many worlds throughout the Outer Rim and we have a complement of fighters, transports, and equipment we maintain ourselves. Life in the Storm Squadron can be hard, some missions require operating with limited or no support behind enemy lines. Our pilots work hard and earn their pay.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6ae72fac", "about_storm"}, -- What is the Storm Squadron?
		{"@conversation/tatooine_imperial_trainer_2:s_6a67413c", "about_accuser"}, -- What's the ISD Accuser?
		{"@conversation/tatooine_imperial_trainer_2:s_e8e1f35f", "apply"}, -- I'm here to apply to Storm Squadron.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_about_storm)

oberhaur_convo_about_accuser = ConvoScreen:new {
	id = "about_accuser",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_dacc15a0", -- The Accuser is an Imperator class Star Destroyer currently on assignment here in the Tatooine system. She has a storied history and a long service record. Storm Squadron has served aboard the Accuser for as long as I can remember. The Accuser is on duty out here on the Rim to show the flag...a warning against Rebel activity.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6ae72fac", "about_storm"}, -- What is the Storm Squadron?
		{"@conversation/tatooine_imperial_trainer_2:s_6a67413c", "about_accuser"}, -- What's the ISD Accuser?
		{"@conversation/tatooine_imperial_trainer_2:s_e8e1f35f", "apply"}, -- I'm here to apply to Storm Squadron.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_about_accuser)

oberhaur_convo_apply = ConvoScreen:new {
	id = "apply",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_e06d735b", -- You are? Let me see your Authorization of Transfer. Make sure it's filled out and signed. They'll have my jax if I send along an incomplete form.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_e3d28c95", "form_unsigned"}, -- (Give him your Authorization of Transfer.)
		{"@conversation/tatooine_imperial_trainer_2:s_58c1df5a", "no_form"}, -- I don't have an Authorization of Transfer.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_apply)

oberhaur_convo_form_unsigned = ConvoScreen:new {
	id = "form_unsigned",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_9b9f672f", -- Pilot you have quite a history. Seems you've come through for us several times in the past. With that in mind...why is it you failed to follow simple instructions and sign this form? Until you confirm things with a digital signature, we can't move forward with your new assignment.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_3821ef35", "form_sign_it"}, -- Uh, whoops?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_form_unsigned)

oberhaur_convo_form_wrong_name = ConvoScreen:new {
	id = "form_wrong_name",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_802f576d", -- Well, your history is very impressive. You have participated in several missions that required accuracy and skill. Why, then, did you sign this form with someone else's name? The Naval Command wants to give you an opportunity, but you are putting it at risk by playing games. Sign the form correctly and then we'll talk.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_b2ef8844", "form_sign_it"}, -- Uh, sorry.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_form_wrong_name)

oberhaur_convo_form_sign_it = ConvoScreen:new {
	id = "form_sign_it",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_183bb6da", -- Sign the form and then talk to me.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_form_sign_it)

oberhaur_convo_form_accepted = ConvoScreen:new {
	id = "form_accepted",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_8065ca4e", -- This form looks correct. Pilot you have an impressive history. In a short period of time you've managed to rise above your station and perform at a level much higher than expected.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_987445c9", "join_storm"}, -- Thank you, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_form_accepted)

oberhaur_convo_join_storm = ConvoScreen:new {
	id = "join_storm",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_451c0d14", -- So you want to join Storm Squadron? It won't be easy. We take tough jobs and we expect results. Unquestioned loyalty and a steel will are merely the most basic of prerequisites to being a member of Storm Squadron.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_6047677", "initiate"}, -- I'm ready, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_join_storm)

oberhaur_convo_initiate = ConvoScreen:new {
	id = "initiate",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_355e31ff", -- You may think you're ready, but I don't believe you really are. You need to prove you are capable of meeting my standards before I'll let you into the Storm Squadron. Just being considered is a grand honor and will look good on your record. If you can stay alive and perform to standard, you will be one of the few and great.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_89bc583c", "initiate_rest"}, -- Very well, sir.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_initiate)

oberhaur_convo_initiate_rest = ConvoScreen:new {
	id = "initiate_rest",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_7e66b604", -- Go take it easy for now and report back to me when you are ready to begin. I've received new orders from Command and I need someone like you for the operation.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_initiate_rest)

oberhaur_convo_no_form = ConvoScreen:new {
	id = "no_form",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_84a82bee", -- Then I can't help you. This stuff has to be done by the books and unless you can prove your flight combat record, I can't deal with you in an official capacity.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d7001705", "unofficial"}, -- What about in an unofficial capacity?
		{"@conversation/tatooine_imperial_trainer_2:s_9288900f", "come_back_with_form"}, -- I understand.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_no_form)

oberhaur_convo_unofficial = ConvoScreen:new {
	id = "unofficial",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_ed3a1afc", -- I operate strictly on the record. Storm Squadron has a noble history within the service and we aren't about to tarnish it. Talk to Hakasha Sireen on Talus if you want something under the table.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_d96f60fb", "hakassha"}, -- Who is Hakasha Sireen?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_unofficial)

oberhaur_convo_hakassha = ConvoScreen:new {
	id = "hakassha",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_55b3e68b", -- Someone I've worked with in the past. A Zabrak with the trust of some very important, very dangerous people. If you work with her, watch your back. She's as likely to pay you with a blaster bolt as she is with credits.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_ffaac8c1", "hakassha_where"}, -- Where can I find her?
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_hakassha)

oberhaur_convo_hakassha_where = ConvoScreen:new {
	id = "hakassha_where",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_49d848b8", -- She is located at the Imperial compound on Talus. She's a core worlds kind of woman. Cloak and daggers, venom and roses.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2:s_88796240", "navy_recruiters"}, -- Thanks for the information.
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_hakassha_where)

oberhaur_convo_navy_recruiters = ConvoScreen:new {
	id = "navy_recruiters",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_392923da", -- Not a problem. It's always a pleasure to talk to a fellow serviceman. If you're interested in working with the Navy you might talk to Lt. Colzet in Bestine or Lt. Sinkko in Kadaara. Both are good men.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_navy_recruiters)

oberhaur_convo_come_back_with_form = ConvoScreen:new {
	id = "come_back_with_form",
	leftDialog = "@conversation/tatooine_imperial_trainer_2:s_fb57ae40", -- Come back with the form and we can get things moving.
	stopConversation = "true",
	options = {
	}
}
oberhaur_convo_template:addScreen(oberhaur_convo_come_back_with_form)

addConversationTemplate("oberhaur_convo_template", oberhaur_convo_template)
