-- V3-FX (Vortex Squadron tier 1) conversation; ported from SWG-Source naboo_rebel_trainer_1.java with the pre-NGE client lines (feature vortex-tier1-v3-fx). Handler: v3fxConvoHandler.
v3fx_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "v3fxConvoHandler",
	screens = {}
}

v3fx_convo_first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_1323cdc1", -- How can I be of service? I have added your first assignment to your log... and I have uploaded codes for a ship control device in your datapad.  Go to the Starport and access the terminal to launch into space... unless I forgot something?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_60c4f974", "fm_where_go"}, -- Where do I go?
		{"@conversation/naboo_rebel_trainer_1:s_85dd7d6c", "fm_how_back"}, -- How do I get back?
		{"@conversation/naboo_rebel_trainer_1:s_4358efe9", "fm_where_ship"}, -- Where is my ship?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_first_mission_help)

v3fx_convo_fm_where_go = ConvoScreen:new {
	id = "fm_where_go",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_e6a9899d", -- You must go to the starport in order to begin your assignment. It's just over there - on the other side of the pond. You can see it from here, actually. Go inside and look for a 'starship terminal.' Use the terminal to launch your ship into space.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_60c4f974", "fm_where_go"}, -- Where do I go?
		{"@conversation/naboo_rebel_trainer_1:s_85dd7d6c", "fm_how_back"}, -- How do I get back?
		{"@conversation/naboo_rebel_trainer_1:s_4358efe9", "fm_where_ship"}, -- Where is my ship?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_fm_where_go)

v3fx_convo_fm_how_back = ConvoScreen:new {
	id = "fm_how_back",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b952209b", -- When you launch, your ship computer will create a 'launch waypoint' near the Naboo traffic control station. At the conclusion of your mission - return to this point. Communicate with the Naboo space station and request landing clearance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_60c4f974", "fm_where_go"}, -- Where do I go?
		{"@conversation/naboo_rebel_trainer_1:s_85dd7d6c", "fm_how_back"}, -- How do I get back?
		{"@conversation/naboo_rebel_trainer_1:s_4358efe9", "fm_where_ship"}, -- Where is my ship?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_fm_how_back)

v3fx_convo_fm_where_ship = ConvoScreen:new {
	id = "fm_where_ship",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_26bc1385", -- A basic Z95 starship is being held for you at the starport. I have uploaded the control codes for this ship to your personal datapad. Any time you wish to review the ship status, open your datapad and examine the ship control device.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_60c4f974", "fm_where_go"}, -- Where do I go?
		{"@conversation/naboo_rebel_trainer_1:s_85dd7d6c", "fm_how_back"}, -- How do I get back?
		{"@conversation/naboo_rebel_trainer_1:s_4358efe9", "fm_where_ship"}, -- Where is my ship?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_fm_where_ship)

v3fx_convo_no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_eedd7284", -- Greeting, Sir.  Ma'am?  Pardon me.  I'm terribly sorry.  I cannot help you with that.  *bzzt*
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_no_jtl)

v3fx_convo_privateer_pilot = ConvoScreen:new {
	id = "privateer_pilot",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_968b4bae", -- Oh. Excuse me. I didn't see you there.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_b26194cb", "privateer_doing"}, -- What are you doing here?
		{"@conversation/naboo_rebel_trainer_1:s_ca776e30", "privateer_who"}, -- Who are you?
		{"@conversation/naboo_rebel_trainer_1:s_1a53f653", "privateer_training"}, -- I am looking for pilot training.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_pilot)

v3fx_convo_privateer_doing = ConvoScreen:new {
	id = "privateer_doing",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_e9b471e7", -- I am not doing anything here.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_doing)

v3fx_convo_privateer_who = ConvoScreen:new {
	id = "privateer_who",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2e4fedc2", -- I am V3-FX... Alliance Pilot Relations.
	stopConversation = "true",
	animation = "pose_proudly",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_who)

v3fx_convo_privateer_training = ConvoScreen:new {
	id = "privateer_training",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_54a7239a", -- I ***CRACKLE*** excellent pilot trainer!
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f60c8a5", "privateer_smuggler"}, -- Train me to fly starships!
		{"@conversation/naboo_rebel_trainer_1:s_900f01d1", "privateer_forget"}, -- What?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_training)

v3fx_convo_privateer_smuggler = ConvoScreen:new {
	id = "privateer_smuggler",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_706c5683", -- ...smuggler...does not...compute...
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_smuggler)

v3fx_convo_privateer_forget = ConvoScreen:new {
	id = "privateer_forget",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_72d418bf", -- I... forget...
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_privateer_forget)

v3fx_convo_imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_85e2e26d", -- Greetings. Can I be of service?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a425f33d", "imperial_no_use"}, -- I have no use for you.
		{"@conversation/naboo_rebel_trainer_1:s_c16bab26", "imperial_answers"}, -- I need answers, droid.
		{"@conversation/naboo_rebel_trainer_1:s_9f6cf52", "imperial_glare"}, -- (Glare in silent hatred.)
	}
}
v3fx_convo_template:addScreen(v3fx_convo_imperial_pilot)

v3fx_convo_imperial_no_use = ConvoScreen:new {
	id = "imperial_no_use",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_41e49ae6", -- Good day to you, then.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_imperial_no_use)

v3fx_convo_imperial_answers = ConvoScreen:new {
	id = "imperial_answers",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_67d49232", -- **zzt** What sort of answers?
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_imperial_answers)

v3fx_convo_imperial_glare = ConvoScreen:new {
	id = "imperial_glare",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_babb9df9", -- Oh dear. Oh no! I hope I have not offended you.
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_imperial_glare)

v3fx_convo_not_rebel = ConvoScreen:new {
	id = "not_rebel",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_eedd7284", -- Greeting, Sir.  Ma'am?  Pardon me.  I'm terribly sorry.  I cannot help you with that.  *bzzt*
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_not_rebel)

v3fx_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_60c2803a", -- Greetings... %TU?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_10581a3e", "grounded_error"}, -- That's right
	}
}
v3fx_convo_template:addScreen(v3fx_convo_grounded)

v3fx_convo_grounded_error = ConvoScreen:new {
	id = "grounded_error",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_3fc246bd", -- Error.  You have been grounded by Alliance HQ.  There are serious accusations against you... Working for the Empire?!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_7426e000", "grounded_bad_news"}, -- No!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_grounded_error)

v3fx_convo_grounded_bad_news = ConvoScreen:new {
	id = "grounded_bad_news",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_de748105", -- Bad news, %TU.  Clear your name with the Rebel Alliance.  Prove your dedication against the Empire.  I'm afraid you cannot fly for the Rebel Alliance until this matter is resolved.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f8b02865", "grounded_standing"}, -- What do I do?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_grounded_bad_news)

v3fx_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_da1db2a5", -- Improve your faction standing with the Rebel Alliance.  Then they will believe you are still dedicated to overthrowing the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_6576f571", "grounded_missions"}, -- How?!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_grounded_standing)

v3fx_convo_grounded_missions = ConvoScreen:new {
	id = "grounded_missions",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_692451bc", -- You could do missions for the Rebel Alliance, if you can locate a mission terminal... that will prove your dedication.  I'm terribly sorry, %TU.
	stopConversation = "true",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_grounded_missions)

v3fx_convo_recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_cd448c20", -- Greetings. I am V3-FX, Alliance Pilot Relations. May I interest you in our starfighter training program?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_78679b31", "recruit_sign"}, -- Sounds like fun. Where do I sign?
		{"@conversation/naboo_rebel_trainer_1:s_1a0322d9", "recruit_fly"}, -- I want to fly for the Alliance!
		{"@conversation/naboo_rebel_trainer_1:s_616cd1dd", "recruit_ready"}, -- Yes. I am ready to train.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruitment)

v3fx_convo_recruit_sign = ConvoScreen:new {
	id = "recruit_sign",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_48d7182e", -- Oh, there is nothing to sign. You simply need to apply yourself to the flight lessons I have to teach. Are you interested?
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_99dfe276", "recruit_money"}, -- Interested? Is there money in it?
		{"@conversation/naboo_rebel_trainer_1:s_b0643db5", "recruit_teach"}, -- You're going to teach ME?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_sign)

v3fx_convo_recruit_money = ConvoScreen:new {
	id = "recruit_money",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_9ba2e5e1", -- There is a measure of monetary compensation for your efforts. Honestly, most pilots fly because they feel it is important to their survival. Do you not agree?
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_2bf47615", "oath_splendid"}, -- Yeah, sure. Why not.
		{"@conversation/naboo_rebel_trainer_1:s_1d2430a3", "recruit_how_much"}, -- What sort of money are we talking about?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_money)

v3fx_convo_oath_splendid = ConvoScreen:new {
	id = "oath_splendid",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_65a3e672", -- Splendid! You are now part of the Alliance pilot training program.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_splendid)

v3fx_convo_recruit_how_much = ConvoScreen:new {
	id = "recruit_how_much",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_4c08239e", -- I cannot say. Being a droid, I have no use for such things.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_104b565a", "oath_glorious"}, -- Well, I'll join anyway.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_how_much)

v3fx_convo_oath_glorious = ConvoScreen:new {
	id = "oath_glorious",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_3be54b2c", -- Glorious! Welcome to the Alliance pilot training system. I will be your tutor.
	stopConversation = "false",
	animation = "applause_excited",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_glorious)

v3fx_convo_recruit_teach = ConvoScreen:new {
	id = "recruit_teach",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_16642b72", -- But of course. It is the standard starfighter training curriculum. I am a very skilled teacher, I assure you.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_e096316d", "oath_excellent_choice"}, -- Sounds wizard. Let's go.
		{"@conversation/naboo_rebel_trainer_1:s_7ed5fec3", "oath_welcome"}, -- I want to be part of the Alliance.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_teach)

v3fx_convo_oath_excellent_choice = ConvoScreen:new {
	id = "oath_excellent_choice",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_de7d9c3a", -- You have made an excellent choice. You are now part of the Alliance flight training program.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_excellent_choice)

v3fx_convo_oath_welcome = ConvoScreen:new {
	id = "oath_welcome",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_11e3b199", -- Welcome to the Alliance.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_welcome)

v3fx_convo_recruit_fly = ConvoScreen:new {
	id = "recruit_fly",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_cca63822", -- What a fortunate coincidence! I am able to induct you to the Alliance pilot training course immediately - provided that you agree to certain obligations.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_546aa4f5", "oath_great_day"}, -- You got it!
		{"@conversation/naboo_rebel_trainer_1:s_f91d81c7", "recruit_obligations"}, -- What sort of obligations?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_fly)

v3fx_convo_oath_great_day = ConvoScreen:new {
	id = "oath_great_day",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_e93422bf", -- This is a great day! Welcome to the Alliance pilot training program.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_great_day)

v3fx_convo_recruit_obligations = ConvoScreen:new {
	id = "recruit_obligations",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_71a4b693", -- In order to qualify for continued training you must participate in Alliance military operations in Naboo space - and beyond.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d002385f", "oath_rebel_program"}, -- Sounds great!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_obligations)

v3fx_convo_oath_rebel_program = ConvoScreen:new {
	id = "oath_rebel_program",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_6cc94470", -- In that case, I welcome you to the Rebel Alliance pilot training program.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_rebel_program)

v3fx_convo_recruit_ready = ConvoScreen:new {
	id = "recruit_ready",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a9a1aa2a", -- Wonderful! I will teach you to fly starfighters in exchange for your loyalty to the Alliance, and your full willingness to support the rebellion in Naboo space and beyond.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_31d45080", "oath_space_navy"}, -- The Alliance has my eternal faith.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_ready)

v3fx_convo_oath_space_navy = ConvoScreen:new {
	id = "oath_space_navy",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_7d2cd92d", -- Then it is my pleasure to welcome you to the Alliance space navy.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a42932d7", "recruit_ship_granted"}, -- I will need a starship.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_oath_space_navy)

v3fx_convo_recruit_ship_granted = ConvoScreen:new {
	id = "recruit_ship_granted",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_efd8333f", -- You are in luck. The Alliance has stowed a number of restored fighter craft at starports here on Naboo. I will upload the security codes for one of these vessels to your datapad.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_fc27931b", "first_assignment"}, -- Thanks.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_recruit_ship_granted)

v3fx_convo_first_assignment = ConvoScreen:new {
	id = "first_assignment",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_52fb0136", -- You are most welcome. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d731f764", "m1_health"}, -- (Shrug and smile.)
		{"@conversation/naboo_rebel_trainer_1:s_90377ed4", "m1_glorious"}, -- Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_b04f2893", "m1_four_point"}, -- Yes. I am ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m1_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_first_assignment)

v3fx_convo_lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_909a1feb", -- You will need a ship, in order to be a pilot.  I will add the control codes to your datapad for a simple Z95.  I hope that it serves you well.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_lost_ship)

v3fx_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_e31d65b7", -- The duty logs indicate that you are in mid-mission. We have nothing to discuss until you are finished.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_on_mission)

v3fx_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_8c6a4b66", -- Oh. You are an Alliance pilot, but I do not recognize you. How may I be of service?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_ac05bfba", "non_member_no_missions"}, -- Are there any missions I can fly?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_non_member)

v3fx_convo_non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_dfc3b1e1", -- Of course. I am authorized to assign a selection of combat duty missions to you. Would you like to perform a duty mission?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/naboo_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/naboo_rebel_trainer_1:s_761039fa", "enlist_ground"}, -- I want to enlist with the ground forces
	}
}
v3fx_convo_template:addScreen(v3fx_convo_non_member_duty_offer)

v3fx_convo_non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_466afe42", -- Forgive me. I am not authorized to assign missions to you. Perhaps you should speak with your commanding officer.
	stopConversation = "true",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_non_member_no_missions)

v3fx_convo_graduated = ConvoScreen:new {
	id = "graduated",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b7b55289", -- Hello there! It is good to see you, although I believe you are supposed to be on planet Dantooine... correct?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_741df7ed", "graduated_where"}, -- Where?
		{"@conversation/naboo_rebel_trainer_1:s_2be1e8b", "graduated_info"}, -- (Salute) Requesting more info, sir!
		{"@conversation/naboo_rebel_trainer_1:s_b3bebc5e", "graduated_how"}, -- How do I get there?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_graduated)

v3fx_convo_graduated_where = ConvoScreen:new {
	id = "graduated_where",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a26aaa8b", -- Planet Dantooine. You are supposed to meet with the Vortex group leader, Brother Vrovel, at the 'abandoned' Rebel base there. Due to the secretive nature of the Vortex you won't be let in to the base until you are a full member of the Alliance.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_graduated_where)

v3fx_convo_graduated_info = ConvoScreen:new {
	id = "graduated_info",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_4063c2da", -- You must go to planet Dantooine and meet with Brother Vrovel, leader of the Vortex organization. He's located in the North West at what the Empire thinks is an abandoned Rebel base. Due to the secretive nature of the Vortex you won't be let in to the base until you are a full member of the Alliance.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_graduated_info)

v3fx_convo_graduated_how = ConvoScreen:new {
	id = "graduated_how",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a3f21650", -- Get into your ship, Pilot, and FLY there.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_graduated_how)

v3fx_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2e5c9032", -- Congratulations, pilot! You have successfully completed the first tier of the Alliance starfighter training program. Your next assignment will take you to planet Dantooine and place you under the guidance of Brother Vrovel... leader of the Vortex organization.
	stopConversation = "false",
	animation = "celebrate1",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f75b511f", "vrovel_splendid"}, -- You got it, metal head!
		{"@conversation/naboo_rebel_trainer_1:s_4efbdbfa", "vrovel_vortex"}, -- What is 'Vortex?'
		{"@conversation/naboo_rebel_trainer_1:s_b89c30f1", "vrovel_who"}, -- Who is Brother Vrovel?
		{"@conversation/naboo_rebel_trainer_1:s_1df40ac6", "vrovel_goodbye_male"}, -- Goodbye, V3.
		{"@conversation/naboo_rebel_trainer_1:s_8334632", "vrovel_where"}, -- Where do I find this Brother Vrovel?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_tier_done)

v3fx_convo_vrovel_splendid = ConvoScreen:new {
	id = "vrovel_splendid",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_fedae3f2", -- Splendid! Please convey my admiration to the Alliance pilots on Dantooine. You will find Brother Vrovel in the 'abandoned' Rebel base in the North West. Be aware, you need to be a full member of the Alliance faction to be allowed entrance in to this secret base. Good luck!
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_splendid)

v3fx_convo_vrovel_vortex = ConvoScreen:new {
	id = "vrovel_vortex",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_7a4f9992", -- Unfortunately, I have very little information on the Vortex group. Alliance HQ indicates that they are a friendly organization dedicated to locating Light-side Jedi and recruiting them to the Rebel cause. They are a very secretive part of the Alliance which is why you need to be a full faction member of the Alliance before you can join them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f75b511f", "vrovel_splendid"}, -- You got it, metal head!
		{"@conversation/naboo_rebel_trainer_1:s_4efbdbfa", "vrovel_vortex"}, -- What is 'Vortex?'
		{"@conversation/naboo_rebel_trainer_1:s_b89c30f1", "vrovel_who"}, -- Who is Brother Vrovel?
		{"@conversation/naboo_rebel_trainer_1:s_1df40ac6", "vrovel_goodbye_male"}, -- Goodbye, V3.
		{"@conversation/naboo_rebel_trainer_1:s_8334632", "vrovel_where"}, -- Where do I find this Brother Vrovel?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_vortex)

v3fx_convo_vrovel_who = ConvoScreen:new {
	id = "vrovel_who",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_6be218d", -- According to the Alliance main computer, Brother Vrovel is an eccentric Bith who has helped the Rebels on numerous occasions. He himself is not a pilot... for that matter, he has almost no pilots in his ranks. That is why you have been re-assigned.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f75b511f", "vrovel_splendid"}, -- You got it, metal head!
		{"@conversation/naboo_rebel_trainer_1:s_4efbdbfa", "vrovel_vortex"}, -- What is 'Vortex?'
		{"@conversation/naboo_rebel_trainer_1:s_b89c30f1", "vrovel_who"}, -- Who is Brother Vrovel?
		{"@conversation/naboo_rebel_trainer_1:s_1df40ac6", "vrovel_goodbye_male"}, -- Goodbye, V3.
		{"@conversation/naboo_rebel_trainer_1:s_8334632", "vrovel_where"}, -- Where do I find this Brother Vrovel?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_who)

v3fx_convo_vrovel_where = ConvoScreen:new {
	id = "vrovel_where",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ae8026b4", -- Searching my extensive database I see that he is in what the Empire think is an 'abandoned' Rebel base on Dantooine. The Alliance is so clever it's almost scary.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_f75b511f", "vrovel_splendid"}, -- You got it, metal head!
		{"@conversation/naboo_rebel_trainer_1:s_4efbdbfa", "vrovel_vortex"}, -- What is 'Vortex?'
		{"@conversation/naboo_rebel_trainer_1:s_b89c30f1", "vrovel_who"}, -- Who is Brother Vrovel?
		{"@conversation/naboo_rebel_trainer_1:s_1df40ac6", "vrovel_goodbye_male"}, -- Goodbye, V3.
		{"@conversation/naboo_rebel_trainer_1:s_8334632", "vrovel_where"}, -- Where do I find this Brother Vrovel?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_where)

v3fx_convo_vrovel_goodbye_male = ConvoScreen:new {
	id = "vrovel_goodbye_male",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a6661be0", -- Good bye, sir! And good luck on Dantooine!
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_goodbye_male)

v3fx_convo_vrovel_goodbye_female = ConvoScreen:new {
	id = "vrovel_goodbye_female",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_9cb26d6a", -- Good bye, ma'am! And good luck to you on Dantooine!
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_vrovel_goodbye_female)

v3fx_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b1ab42f0", -- Alliance HQ has requested that I assign a new mission to you... since you have failed the previous. Good luck!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d731f764", "m1_health"}, -- (Shrug and smile.)
		{"@conversation/naboo_rebel_trainer_1:s_90377ed4", "m1_glorious"}, -- Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_b04f2893", "m1_four_point"}, -- Yes. I am ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m1_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission1_failed)

v3fx_convo_mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_f4d0e976", -- The Alliance HQ computer system is rather disappointed with your performance. I have been instructed to renew your mission assignment. Good luck!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c92d07b4", "m2_why_not"}, -- Sure. Why not.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m2_um_yes"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_6fb5a316", "m2_good_to_hear"}, -- I am more than ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m2_not_so_fast"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission2_failed)

v3fx_convo_mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_c7626ea8", -- I have been ordered to reassign a mission to you. The mission you most recently failed. My apologies. And... good luck!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_3f1a842c", "m3_thank_maker"}, -- Yeah, yeah.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m3_good_luck"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_1e626caa", "m3_critical"}, -- Of course. Those supplies are critical!
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m3_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission3_failed)

v3fx_convo_mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_54d18017", -- Alliance HQ demands that you rejoin battle against the TIE Veteran so that our campaign may move forward. Good luck!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_ebc0661b", "m4_splendid"}, -- I got nothing better to do.
		{"@conversation/naboo_rebel_trainer_1:s_6b490480", "m4_rally"}, -- (Salute) Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_a994ca63", "m4_tie_forces"}, -- For the Alliance!
		{"@conversation/naboo_rebel_trainer_1:s_7478cd28", "m4_word"}, -- Will you train me after this?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission4_failed)

v3fx_convo_mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_79a06a16", -- Salutations, pilot! I hope you are well-rested and ready for your first assignment for the Alliance training system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d731f764", "m1_health"}, -- (Shrug and smile.)
		{"@conversation/naboo_rebel_trainer_1:s_90377ed4", "m1_glorious"}, -- Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_b04f2893", "m1_four_point"}, -- Yes. I am ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m1_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission1_offer)

v3fx_convo_mission1_won = ConvoScreen:new {
	id = "mission1_won",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_f14340ef", -- Thank goodness you've returned in one piece! How was your first mission?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1f6a762c", "m1_superior"}, -- No sweat, droid.
		{"@conversation/naboo_rebel_trainer_1:s_85fcdc55", "m1_attacked"}, -- Fighters attacked me!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission1_won)

v3fx_convo_m1_superior = ConvoScreen:new {
	id = "m1_superior",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_45e27f53", -- You are clearly a superior pilot! Congratulations.
	stopConversation = "true",
	animation = "celebrate",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_superior)

v3fx_convo_m1_attacked = ConvoScreen:new {
	id = "m1_attacked",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_db851c67", -- Oh dear! What did you do?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_7d4a858e", "m1_exciting"}, -- Blasted 'em.
		{"@conversation/naboo_rebel_trainer_1:s_73edb45", "m1_fought_better"}, -- They fought well, but I fought better.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_attacked)

v3fx_convo_m1_exciting = ConvoScreen:new {
	id = "m1_exciting",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_9f83d209", -- Sounds very exciting! Congratulations!
	stopConversation = "true",
	animation = "celebrate",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_exciting)

v3fx_convo_m1_fought_better = ConvoScreen:new {
	id = "m1_fought_better",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_98a1c60d", -- This is good to hear, pilot! Congratulations.
	stopConversation = "true",
	animation = "celebrate",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_fought_better)

v3fx_convo_mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_36fa01ee", -- We will need a short while to decode and interpret your starship sensor data. In the meantime, there is more work to be done... if you are ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c92d07b4", "m2_why_not"}, -- Sure. Why not.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m2_um_yes"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_6fb5a316", "m2_good_to_hear"}, -- I am more than ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m2_not_so_fast"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission2_offer)

v3fx_convo_mission2_won = ConvoScreen:new {
	id = "mission2_won",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_76fb5d49", -- Alliance HQ has spread word of your victory! Congratulations, pilot!
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c1013aa7", "m2_yes_indeed"}, -- Whatever.
		{"@conversation/naboo_rebel_trainer_1:s_6b490480", "m2_affirmative"}, -- (Salute) Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_f0b6493f", "m2_welcome"}, -- Thank you, V3.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission2_won)

v3fx_convo_m2_yes_indeed = ConvoScreen:new {
	id = "m2_yes_indeed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_e50bc223", -- Yes! Yes indeed!
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_yes_indeed)

v3fx_convo_m2_affirmative = ConvoScreen:new {
	id = "m2_affirmative",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_83cb5e35", -- Affirmative, pilot! Congratulations.
	stopConversation = "true",
	animation = "celebrate",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_affirmative)

v3fx_convo_m2_welcome = ConvoScreen:new {
	id = "m2_welcome",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_d7d27ed7", -- You are welcome, pilot! Congratulations!
	stopConversation = "true",
	animation = "celebrate1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_welcome)

v3fx_convo_mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b0047226", -- We have decoded your starship sensor data... and we have bad news. The planned Alliance supply route has been thoroughly compromised. We need you to find us another route. Are you ready to take flight again?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_3f1a842c", "m3_thank_maker"}, -- Yeah, yeah.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m3_good_luck"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_1e626caa", "m3_critical"}, -- Of course. Those supplies are critical!
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m3_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission3_offer)

v3fx_convo_mission3_won = ConvoScreen:new {
	id = "mission3_won",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_7ad400bc", -- Alliance command is impressed with your courage, pilot! The main computer specifically mentioned your ability to improvise in a crisis situation. Very good work!
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_9561a5a9", "m3_flightsuit"}, -- (Salute) Thank you, sir!
		{"@conversation/naboo_rebel_trainer_1:s_27a8c796", "m3_thanks_flightsuit"}, -- For the Alliance, my friend.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission3_won)

v3fx_convo_m3_bandolier = ConvoScreen:new {
	id = "m3_bandolier",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_fbd6b3e6", -- You are welcome, pilot!  As a bonus:  I've had a bandolier made for you.
	stopConversation = "true",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_bandolier)

v3fx_convo_m3_flightsuit = ConvoScreen:new {
	id = "m3_flightsuit",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_cd4363b6", -- You are welcome, pilot!  As a bonus:  I've had a flightsuit made for you.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_flightsuit)

v3fx_convo_m3_thanks_bandolier = ConvoScreen:new {
	id = "m3_thanks_bandolier",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_9490adec", -- Yes. The Alliance thanks you.  As a little bonus, I've had this bandolier made for you.
	stopConversation = "true",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_thanks_bandolier)

v3fx_convo_m3_thanks_flightsuit = ConvoScreen:new {
	id = "m3_thanks_flightsuit",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_1fb7129c", -- Yes. The Alliance thanks you.  As a little bonus, I've had this flightsuit made for you.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_thanks_flightsuit)

v3fx_convo_mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_999f2284", -- While you were away, we discovered some information that will break the back of the Empire's fleet movements here in Naboo. Are you ready to fly again?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_ebc0661b", "m4_splendid"}, -- I got nothing better to do.
		{"@conversation/naboo_rebel_trainer_1:s_6b490480", "m4_rally"}, -- (Salute) Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_a994ca63", "m4_tie_forces"}, -- For the Alliance!
		{"@conversation/naboo_rebel_trainer_1:s_7478cd28", "m4_word"}, -- Will you train me after this?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission4_offer)

v3fx_convo_mission4_won = ConvoScreen:new {
	id = "mission4_won",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_61836246", -- The Alliance HQ computer system has informed me that the TIE Veteran pilot has been defeated. Very good work, my friend. Very good, indeed!
	stopConversation = "true",
	animation = "applause_polite",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_mission4_won)

v3fx_convo_training_first = ConvoScreen:new {
	id = "training_first",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_6f3e9d4b", -- You have performed wonderfully! Alliance HQ has authorized me to provide your first starship training module. It is customary for the trainee to choose their area of emphasis. Which do you prefer?
	stopConversation = "false",
	animation = "applause_excited",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_26970ef", "trained_starships_male"}, -- I am interested in basic starfighter training.
		{"@conversation/naboo_rebel_trainer_1:s_3fa70900", "trained_weapons"}, -- I am interested in basic starship component use.
		{"@conversation/naboo_rebel_trainer_1:s_8c272224", "trained_procedures"}, -- I am interested in starfighter survival tactics.
		{"@conversation/naboo_rebel_trainer_1:s_9480f430", "trained_droid_male"}, -- I am interested in droid interface basics.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_training_first)

v3fx_convo_training_more = ConvoScreen:new {
	id = "training_more",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_838cca30", -- Greetings, pilot. You are performing exceptionally well! It would be my pleasure to provide any further training modules that you require. What area interests you the most?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_26970ef", "trained_starships_male"}, -- I am interested in basic starfighter training.
		{"@conversation/naboo_rebel_trainer_1:s_3fa70900", "trained_weapons"}, -- I am interested in basic starship component use.
		{"@conversation/naboo_rebel_trainer_1:s_8c272224", "trained_procedures"}, -- I am interested in starfighter survival tactics.
		{"@conversation/naboo_rebel_trainer_1:s_9480f430", "trained_droid_male"}, -- I am interested in droid interface basics.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_training_more)

v3fx_convo_trained_starships_male = ConvoScreen:new {
	id = "trained_starships_male",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_d671116a", -- Yes, of course! Congratulations. Good work, sir!
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_starships_male)

v3fx_convo_trained_starships_female = ConvoScreen:new {
	id = "trained_starships_female",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_593caccf", -- Yes, of course! Congratulations. Excellent work, ma'am.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_starships_female)

v3fx_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_c5dca41d", -- Splendid! You are now rated for more powerful components. Use them well!
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_weapons)

v3fx_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_145a9b15", -- Of course! I have removed the code-lock on your procedures manual. Secret techniques are now available to you.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_procedures)

v3fx_convo_trained_droid_male = ConvoScreen:new {
	id = "trained_droid_male",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_8062b983", -- How noble of you, sir! Droid programming is a critical skill for the Alliance pilot.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_droid_male)

v3fx_convo_trained_droid_female = ConvoScreen:new {
	id = "trained_droid_female",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b0d2b96b", -- How noble of you, ma'am! Droid programming is a most respectable vocation.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_trained_droid_female)

v3fx_convo_duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_400d7391", -- Greetings, my friend. You will be pleased to know that Alliance High Command has authorized me to offer you a selection of combat duty missions. Are you interested in a duty mission?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/naboo_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/naboo_rebel_trainer_1:s_761039fa", "enlist_ground"}, -- I want to enlist with the ground forces
	}
}
v3fx_convo_template:addScreen(v3fx_convo_duty_missions)

v3fx_convo_duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_96184c1", -- A duty mission is an excellent way of earning experience towards your next training session. No good trainer would teach a pilot with no experience. Duty missions have no real end to them, you simply finish whenever you are ready. Would you like a duty mission?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/naboo_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/naboo_rebel_trainer_1:s_761039fa", "enlist_ground"}, -- I want to enlist with the ground forces
	}
}
v3fx_convo_template:addScreen(v3fx_convo_duty_explained)

v3fx_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_614176fe", -- That is most excellent to hear. We have two mission types available. You may choose to patrol the system and destroy any Imperials that you find, or you may choose to help escort our supply ships. Which would you like?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cf63ee80", "destroy_duty_male"}, -- I would like to patrol Naboo space.
		{"@conversation/naboo_rebel_trainer_1:s_a66ff602", "escort_duty"}, -- Our transports could use my help.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_duty_menu)

v3fx_convo_destroy_duty_male = ConvoScreen:new {
	id = "destroy_duty_male",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ca5e8b8b", -- Affirmative, sir. I have placed your ID on the duty roster. You are free to sweep and clear Imperial warships in the area. You can return to the ground at any time when you feel that you have learned enough.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_destroy_duty_male)

v3fx_convo_destroy_duty_female = ConvoScreen:new {
	id = "destroy_duty_female",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_284dc5d3", -- Yes, ma'am! I have uploaded your ID to the system duty roster. You are cleared to sweep Naboo space for Imperial starships. You can return to the ground at any time when you feel that you have learned enough. Good luck!
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_destroy_duty_female)

v3fx_convo_escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_6c399378", -- Agreed! I will put your ID on the escort duty roster. You can return to the ground at any time when you feel that you have learned enough. Take flight whenever you wish.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_escort_duty)

v3fx_convo_enlist_ground = ConvoScreen:new {
	id = "enlist_ground",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_81eaed4e", -- Finally decided to become a REAL Rebel, huh?  Well it's about time.  You do realize that enlisting with the ground forces means you could be attacked when you least expect it... even if you are a covert operative, there's still a danger!
	stopConversation = "false",
	animation = "laugh_cackle",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_e5f13c4", "enlist_recruiter"}, -- I'm not afraid
	}
}
v3fx_convo_template:addScreen(v3fx_convo_enlist_ground)

v3fx_convo_enlist_recruiter = ConvoScreen:new {
	id = "enlist_recruiter",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2ff8ef01", -- Good for you!  Alliance command will be happy to have you as an asset both in space and planetside!  Just seek a Rebel Recruiter and tell him you want to join.  I'm certain there won't be a problem with it.
	stopConversation = "true",
	animation = "applause_polite",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_enlist_recruiter)

v3fx_convo_m1_health = ConvoScreen:new {
	id = "m1_health",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b4155765", -- Excellent! I see you are in perfect health!
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_3a8fb4dd", "m1_frontier"}, -- Let's get on with it, buddy.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_health)

v3fx_convo_m1_frontier = ConvoScreen:new {
	id = "m1_frontier",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2518a758", -- As you wish! Your first assignment is a four-point patrol along the Naboo frontier. Be careful of local pirates - and be kind to local merchants. They are friends to us all, you know.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_116bd775", "m1_good_day"}, -- (Wave dismissively.)
		{"@conversation/naboo_rebel_trainer_1:s_afdd3bc5", "m1_pirates"}, -- Pirates? Nobody mentioned pirates before...
		{"@conversation/naboo_rebel_trainer_1:s_c713935d", "m1_merchants"}, -- You say there are merchants to save?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_frontier)

v3fx_convo_m1_good_day = ConvoScreen:new {
	id = "m1_good_day",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ae7a2a24", -- Uh... yes, and good day to you too!
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_good_day)

v3fx_convo_m1_pirates = ConvoScreen:new {
	id = "m1_pirates",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_eceb89e1", -- Oh absolutely! Naboo space is teeming with deadly gangs of pirates - and horrid nebula that will melt your ship in mere seconds. Do be careful out there!
	stopConversation = "false",
	animation = "wave2",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_116bd775", "m1_good_day"}, -- (Wave dismissively.)
		{"@conversation/naboo_rebel_trainer_1:s_afdd3bc5", "m1_pirates"}, -- Pirates? Nobody mentioned pirates before...
		{"@conversation/naboo_rebel_trainer_1:s_c713935d", "m1_merchants"}, -- You say there are merchants to save?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_pirates)

v3fx_convo_m1_merchants = ConvoScreen:new {
	id = "m1_merchants",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_81c3ab31", -- They're quite safe on their own, I assure you. We only ask that you stay out of sight. Starfighter patrols make the local business interests somewhat... timid, if you get my meaning.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_116bd775", "m1_good_day"}, -- (Wave dismissively.)
		{"@conversation/naboo_rebel_trainer_1:s_afdd3bc5", "m1_pirates"}, -- Pirates? Nobody mentioned pirates before...
		{"@conversation/naboo_rebel_trainer_1:s_c713935d", "m1_merchants"}, -- You say there are merchants to save?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_merchants)

v3fx_convo_m1_glorious = ConvoScreen:new {
	id = "m1_glorious",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_748d90dd", -- Glorious! Your first mission is a short-range, four-point patrol. When you return, your ship's sensor data will be downloaded to the Alliance 'net for Intel to review.
	stopConversation = "false",
	animation = "celebrate",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/naboo_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/naboo_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/naboo_rebel_trainer_1:s_123652f8", "m1_delightful"}, -- (Salute) May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_glorious)

v3fx_convo_m1_looking = ConvoScreen:new {
	id = "m1_looking",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ce6b43af", -- We have reason to believe that the Empire is moving a wing of TIE fighters directly into an Alliance supply route. We need to know more.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/naboo_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/naboo_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/naboo_rebel_trainer_1:s_123652f8", "m1_delightful"}, -- (Salute) May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_looking)

v3fx_convo_m1_where = ConvoScreen:new {
	id = "m1_where",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_9757e73a", -- You'll be covering a little-used Alliance supply route. It's become more important in recent days because of Imperial activity outside the asteroid belt. We have plans for this area, and need to know that we'll remain unseen.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/naboo_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/naboo_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/naboo_rebel_trainer_1:s_123652f8", "m1_delightful"}, -- (Salute) May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_where)

v3fx_convo_m1_blast = ConvoScreen:new {
	id = "m1_blast",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_c89c913b", -- Oh dear! Please just stay out of trouble. Come back in one piece!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/naboo_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/naboo_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/naboo_rebel_trainer_1:s_123652f8", "m1_delightful"}, -- (Salute) May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_blast)

v3fx_convo_m1_delightful = ConvoScreen:new {
	id = "m1_delightful",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_25572e24", -- That sounds delightful.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_delightful)

v3fx_convo_m1_four_point = ConvoScreen:new {
	id = "m1_four_point",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_4d3c3acd", -- You will fly a four-point patrol above Naboo. We will need your ship's sensor data when you are finished.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_92e1301f", "m1_certain"}, -- Don't worry. I will be fine.
		{"@conversation/naboo_rebel_trainer_1:s_658f174d", "m1_plans"}, -- What am I looking for?
		{"@conversation/naboo_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_four_point)

v3fx_convo_m1_certain = ConvoScreen:new {
	id = "m1_certain",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_35657a01", -- Of that I am certain.
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_certain)

v3fx_convo_m1_plans = ConvoScreen:new {
	id = "m1_plans",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_85cea100", -- Alliance intelligence has plans for this route. I don't know precisely what these plans are - but I assure you that I'll tell you as soon as I know.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_92e1301f", "m1_certain"}, -- Don't worry. I will be fine.
		{"@conversation/naboo_rebel_trainer_1:s_658f174d", "m1_plans"}, -- What am I looking for?
		{"@conversation/naboo_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_plans)

v3fx_convo_m1_hidden = ConvoScreen:new {
	id = "m1_hidden",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_1c2c03ae", -- There are a number of pirates in the area. The Empire is interested in removing these pirate elements, so I suspect your route will be clouded with peril... unfortunately.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_92e1301f", "m1_certain"}, -- Don't worry. I will be fine.
		{"@conversation/naboo_rebel_trainer_1:s_658f174d", "m1_plans"}, -- What am I looking for?
		{"@conversation/naboo_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_hidden)

v3fx_convo_m1_not_yet = ConvoScreen:new {
	id = "m1_not_yet",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_8b2a5c11", -- After you have completed a few assignments for me, then I will train you.  So, are you ready?
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d731f764", "m1_health"}, -- (Shrug and smile.)
		{"@conversation/naboo_rebel_trainer_1:s_90377ed4", "m1_glorious"}, -- Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_b04f2893", "m1_four_point"}, -- Yes. I am ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m1_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m1_not_yet)

v3fx_convo_m2_why_not = ConvoScreen:new {
	id = "m2_why_not",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_64308f9f", -- Why not indeed! Let's have some revenge on the Empire. Find four of their puny TIE fighters in the Naboo system and destroy them!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1728f71a", "m2_thin"}, -- How thin are we talking?
		{"@conversation/naboo_rebel_trainer_1:s_6c620e99", "m2_groups"}, -- Don't they travel in big groups though?
		{"@conversation/naboo_rebel_trainer_1:s_8b4893d6", "m2_irrepressible"}, -- Piece o'cake, metal-mouth!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_why_not)

v3fx_convo_m2_thin = ConvoScreen:new {
	id = "m2_thin",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_d9c6f8a5", -- Four or more will do quite nicely. Focus on the TIE fighters. They are critical to the Empire's operations in Naboo. If you focus on these craft, the Empire will know that their intelligence is compromised and that their operations are in jeopardy. This will buy us some time...
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1728f71a", "m2_thin"}, -- How thin are we talking?
		{"@conversation/naboo_rebel_trainer_1:s_6c620e99", "m2_groups"}, -- Don't they travel in big groups though?
		{"@conversation/naboo_rebel_trainer_1:s_8b4893d6", "m2_irrepressible"}, -- Piece o'cake, metal-mouth!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_thin)

v3fx_convo_m2_groups = ConvoScreen:new {
	id = "m2_groups",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_1137ccd7", -- We cannot say at this time. Alliance pilots in the Naboo system have reported a wide variety of Imperial activity. You should be able to find some smaller support wings...
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1728f71a", "m2_thin"}, -- How thin are we talking?
		{"@conversation/naboo_rebel_trainer_1:s_6c620e99", "m2_groups"}, -- Don't they travel in big groups though?
		{"@conversation/naboo_rebel_trainer_1:s_8b4893d6", "m2_irrepressible"}, -- Piece o'cake, metal-mouth!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_groups)

v3fx_convo_m2_irrepressible = ConvoScreen:new {
	id = "m2_irrepressible",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_85c109c3", -- You're irrepressible! Best of luck!
	stopConversation = "true",
	animation = "wave2",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_irrepressible)

v3fx_convo_m2_um_yes = ConvoScreen:new {
	id = "m2_um_yes",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2582d5e6", -- Um... yes... um... Let's have some revenge on the Empire. Find four of their puny TIE fighters in the Naboo system and destroy them!
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cbe69427", "m2_only_ties"}, -- Only the TIE fighters?
		{"@conversation/naboo_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
		{"@conversation/naboo_rebel_trainer_1:s_49bfaf2", "m2_name_alliance"}, -- (Salute) For the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_um_yes)

v3fx_convo_m2_only_ties = ConvoScreen:new {
	id = "m2_only_ties",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_cc07efa5", -- Yes, please. Alliance intelligence 'net is quite clever - you see, the Empire does not yet know that their fleet info has been compromised. Strike their TIE fighters with extreme prejudice, and they will have no choice but to halt their greater strategy.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cbe69427", "m2_only_ties"}, -- Only the TIE fighters?
		{"@conversation/naboo_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
		{"@conversation/naboo_rebel_trainer_1:s_49bfaf2", "m2_name_alliance"}, -- (Salute) For the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_only_ties)

v3fx_convo_m2_rally = ConvoScreen:new {
	id = "m2_rally",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_1aaecbcb", -- There will be none. You have to search the Naboo system until you find some good targets.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cbe69427", "m2_only_ties"}, -- Only the TIE fighters?
		{"@conversation/naboo_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
		{"@conversation/naboo_rebel_trainer_1:s_49bfaf2", "m2_name_alliance"}, -- (Salute) For the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_rally)

v3fx_convo_m2_name_alliance = ConvoScreen:new {
	id = "m2_name_alliance",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_81770bc2", -- Yes! Please perform this task in the name of the Alliance!
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_name_alliance)

v3fx_convo_m2_good_to_hear = ConvoScreen:new {
	id = "m2_good_to_hear",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_314a123f", -- That is good to hear. Let's have some revenge on the Empire. Find four of their puny TIE fighters in the Naboo system and destroy them!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/naboo_rebel_trainer_1:s_8995f223", "m2_targets"}, -- What are my targets?
		{"@conversation/naboo_rebel_trainer_1:s_2d4bb338", "m2_thank_you"}, -- May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_good_to_hear)

v3fx_convo_m2_location = ConvoScreen:new {
	id = "m2_location",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_c267cd40", -- There's none specified in the data I received from our esteemed superiors. You have to search the Naboo system until you find some good targets.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/naboo_rebel_trainer_1:s_8995f223", "m2_targets"}, -- What are my targets?
		{"@conversation/naboo_rebel_trainer_1:s_2d4bb338", "m2_thank_you"}, -- May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_location)

v3fx_convo_m2_targets = ConvoScreen:new {
	id = "m2_targets",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_576d5b2a", -- TIE fighters only. There are other Imperial targets above Naboo, these TIE fighters are special. They are part of the Empire's occupation plans. Once you eliminate these craft - and only these craft - the Empire will know that their secrets are compromised.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/naboo_rebel_trainer_1:s_8995f223", "m2_targets"}, -- What are my targets?
		{"@conversation/naboo_rebel_trainer_1:s_2d4bb338", "m2_thank_you"}, -- May the Force be with you.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_targets)

v3fx_convo_m2_thank_you = ConvoScreen:new {
	id = "m2_thank_you",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b9b27823", -- Thank you.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_thank_you)

v3fx_convo_m2_not_so_fast = ConvoScreen:new {
	id = "m2_not_so_fast",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_fb2ee4e7", -- Not so fast, %TU.  There'll be time for training later.  Right now we need you to do another assignment.  I hope you are ready for it.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_c92d07b4", "m2_why_not"}, -- Sure. Why not.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m2_um_yes"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_6fb5a316", "m2_good_to_hear"}, -- I am more than ready.
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m2_not_so_fast"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m2_not_so_fast)

v3fx_convo_m3_thank_maker = ConvoScreen:new {
	id = "m3_thank_maker",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a30d25ad", -- Thank the maker!
	stopConversation = "true",
	animation = "applause_excited",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_thank_maker)

v3fx_convo_m3_good_luck = ConvoScreen:new {
	id = "m3_good_luck",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a80d9308", -- Good luck!
	stopConversation = "true",
	animation = "wave2",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_good_luck)

v3fx_convo_m3_critical = ConvoScreen:new {
	id = "m3_critical",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_b5caf1b6", -- Critical to say the least! We must resume supply flights as soon as possible. To accomplish this, we need you to sweep a five-point area. Once again, your ship sensor data will be used to plot an effective route for our larger transports.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_d0233b4b", "m3_agreed"}, -- The Force be with us.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_critical)

v3fx_convo_m3_agreed = ConvoScreen:new {
	id = "m3_agreed",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2099a39c", -- Agreed!
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_agreed)

v3fx_convo_m3_not_yet = ConvoScreen:new {
	id = "m3_not_yet",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_5f65d2ef", -- Not yet, this is important!  Now are you ready?
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_3f1a842c", "m3_thank_maker"}, -- Yeah, yeah.
		{"@conversation/naboo_rebel_trainer_1:s_b2d473c6", "m3_good_luck"}, -- (Salute) Yes, sir!
		{"@conversation/naboo_rebel_trainer_1:s_1e626caa", "m3_critical"}, -- Of course. Those supplies are critical!
		{"@conversation/naboo_rebel_trainer_1:s_fb1c19c1", "m3_not_yet"}, -- I want training!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m3_not_yet)

v3fx_convo_m4_splendid = ConvoScreen:new {
	id = "m4_splendid",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_c010439f", -- Splendid!
	stopConversation = "false",
	animation = "celebrate1",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_bf1a0f3e", "m4_job"}, -- So tell me about the job.
		{"@conversation/naboo_rebel_trainer_1:s_6a150013", "m4_details"}, -- Let's have some details.
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_splendid)

v3fx_convo_m4_job = ConvoScreen:new {
	id = "m4_job",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_74163bd7", -- Destroy the veteran TIE pilot leader at a specific rally point. You will receive the waypoint data once you are in space.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_job)

v3fx_convo_m4_details = ConvoScreen:new {
	id = "m4_details",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_a20f8416", -- The recent Imperial activity is being led by a veteran TIE fighter pilot. We know of his location. Fly to the nav point, and eliminate this pilot with extreme prejudice.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_details)

v3fx_convo_m4_rally = ConvoScreen:new {
	id = "m4_rally",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_47ce8fc2", -- We have located a rally point from which the Empire has staged their recent aggressions. Go to this point and bring down a veteran TIE fighter pilot.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a30c1a53", "m4_yes_sir"}, -- Yes sir!
		{"@conversation/naboo_rebel_trainer_1:s_87a8cca7", "m4_know_pilot"}, -- How will I know this pilot?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_rally)

v3fx_convo_m4_yes_sir = ConvoScreen:new {
	id = "m4_yes_sir",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_81770bc2", -- Yes! Please perform this task in the name of the Alliance!
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_yes_sir)

v3fx_convo_m4_know_pilot = ConvoScreen:new {
	id = "m4_know_pilot",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ee82c4c3", -- It should not be difficult. He should be one of very few veteran TIE fighter pilots in this vicinity.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_a30c1a53", "m4_yes_sir"}, -- Yes sir!
		{"@conversation/naboo_rebel_trainer_1:s_87a8cca7", "m4_know_pilot"}, -- How will I know this pilot?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_know_pilot)

v3fx_convo_m4_tie_forces = ConvoScreen:new {
	id = "m4_tie_forces",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_da803d9b", -- Yes... We have reliable information about the location of Imperial TIE forces. They are being led by an experienced TIE veteran. Eliminate this TIE veteran pilot with extreme prejudice. This should halt the Empire's plans rather effectively.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/naboo_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/naboo_rebel_trainer_1:s_6aadaf18", "m4_honor"}, -- I will bring honor to the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_tie_forces)

v3fx_convo_m4_veteran = ConvoScreen:new {
	id = "m4_veteran",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_4bbbb3ee", -- I, myself? Not very much. You may find more than one in the general area - but Alliance intelligence indicates that the Empire has charged one veteran TIE pilot with coordinating aggressions in this system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/naboo_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/naboo_rebel_trainer_1:s_6aadaf18", "m4_honor"}, -- I will bring honor to the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_veteran)

v3fx_convo_m4_targets = ConvoScreen:new {
	id = "m4_targets",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_2b74415f", -- Expect the rally point to be patrolled by junior TIE cadets. They will be quick to respond if they see you first - so be very careful. Keep your eye out for the veteran TIE fighter pilot, and eliminate him.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/naboo_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/naboo_rebel_trainer_1:s_6aadaf18", "m4_honor"}, -- I will bring honor to the Alliance!
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_targets)

v3fx_convo_m4_honor = ConvoScreen:new {
	id = "m4_honor",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_f1c5717b", -- I am quite certain the Alliance appreciates it, as well!
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_honor)

v3fx_convo_m4_word = ConvoScreen:new {
	id = "m4_word",
	leftDialog = "@conversation/naboo_rebel_trainer_1:s_ca62728c", -- Yes, yes, you have my word.  Complete this last assignment for me and I will train you.  Are you ready?
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/naboo_rebel_trainer_1:s_ebc0661b", "m4_splendid"}, -- I got nothing better to do.
		{"@conversation/naboo_rebel_trainer_1:s_6b490480", "m4_rally"}, -- (Salute) Affirmative!
		{"@conversation/naboo_rebel_trainer_1:s_a994ca63", "m4_tie_forces"}, -- For the Alliance!
		{"@conversation/naboo_rebel_trainer_1:s_7478cd28", "m4_word"}, -- Will you train me after this?
	}
}
v3fx_convo_template:addScreen(v3fx_convo_m4_word)

addConversationTemplate("v3fx_convo_template", v3fx_convo_template)
