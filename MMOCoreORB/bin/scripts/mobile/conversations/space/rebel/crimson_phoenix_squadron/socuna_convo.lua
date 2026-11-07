-- Da'la Socuna (Crimson Phoenix Squadron tier 1, Mos Espa cantina) conversation; ported from SWG-Source tatooine_rebel_trainer_1.java with the pre-NGE client lines (feature crimson-phoenix-tier1-da-la-socuna). Handler: socunaConvoHandler.
socuna_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "socunaConvoHandler",
	screens = {}
}

socuna_convo_first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c19ed115", -- You've got your assignment, and the control device for your ship in your datapad.  Go to the Starport and access the terminal to launch into space.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a4652c6", "fm_now_what"}, -- So now what?
		{"@conversation/tatooine_rebel_trainer_1:s_680cda08", "fm_get_back"}, -- How do I get back from space?
		{"@conversation/tatooine_rebel_trainer_1:s_5bfac9f1", "fm_where_ship"}, -- Where's my starship?
	}
}
socuna_convo_template:addScreen(socuna_convo_first_mission_help)

socuna_convo_fm_now_what = ConvoScreen:new {
	id = "fm_now_what",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_59dceadb", -- Now you need to go to the starport. Go inside and look for a 'starship terminal.' Use the terminal to launch your starship into space. When you launch, a waypoint will be created to help guide you back to your landing spot. When you want to land - comm the space station and ask for landing clearance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a4652c6", "fm_now_what"}, -- So now what?
		{"@conversation/tatooine_rebel_trainer_1:s_680cda08", "fm_get_back"}, -- How do I get back from space?
		{"@conversation/tatooine_rebel_trainer_1:s_5bfac9f1", "fm_where_ship"}, -- Where's my starship?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_now_what)

socuna_convo_fm_get_back = ConvoScreen:new {
	id = "fm_get_back",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9a159641", -- When you are done with your patrol, you will need to find your way to a space station above Tatooine. Communicate with the station operatives and request landing clearance. The rest is automatic.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4738e99f", "fm_find_station"}, -- How do I find a space station?
		{"@conversation/tatooine_rebel_trainer_1:s_c4c3d546", "fm_comm_station"}, -- How do I comm the space station?
		{"@conversation/tatooine_rebel_trainer_1:s_d038a005", "fm_then_what"}, -- And then what?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_get_back)

socuna_convo_fm_where_ship = ConvoScreen:new {
	id = "fm_where_ship",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d806feaa", -- A number of slightly-used Z95 starships are parked around Tatooine... hidden from Imperial eyes. The codes I uploaded to your datapad will allow you to assume control of one. Just head down to the starport...
	stopConversation = "false",
	animation = "point_away",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a4652c6", "fm_now_what"}, -- So now what?
		{"@conversation/tatooine_rebel_trainer_1:s_680cda08", "fm_get_back"}, -- How do I get back from space?
		{"@conversation/tatooine_rebel_trainer_1:s_5bfac9f1", "fm_where_ship"}, -- Where's my starship?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_where_ship)

socuna_convo_fm_find_station = ConvoScreen:new {
	id = "fm_find_station",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_29b9c1a7", -- Use your zone map interface to locate space stations while in-flight. Or - use the automatic 'landing waypoint' that your ship computer creates for you when you take off. The 'landing waypoint' can be activated from your datapad. Just find your way back to that point when you are done with your assignment.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4738e99f", "fm_find_station"}, -- How do I find a space station?
		{"@conversation/tatooine_rebel_trainer_1:s_c4c3d546", "fm_comm_station"}, -- How do I comm the space station?
		{"@conversation/tatooine_rebel_trainer_1:s_d038a005", "fm_then_what"}, -- And then what?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_find_station)

socuna_convo_fm_comm_station = ConvoScreen:new {
	id = "fm_comm_station",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_6440d5e7", -- Target the space station and then comm the space station. Most likely the station will recognize you and will comm you first. But if you are in a hurry, use SHIFT+C to target the space station and open communication with the station commander.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4738e99f", "fm_find_station"}, -- How do I find a space station?
		{"@conversation/tatooine_rebel_trainer_1:s_c4c3d546", "fm_comm_station"}, -- How do I comm the space station?
		{"@conversation/tatooine_rebel_trainer_1:s_d038a005", "fm_then_what"}, -- And then what?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_comm_station)

socuna_convo_fm_then_what = ConvoScreen:new {
	id = "fm_then_what",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a6c2aaa1", -- Then you rejoice! You're still alive, you're done with your assignment, and life is good... right? Come back here when you're done so I can give you your next assignment.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a4652c6", "fm_now_what"}, -- So now what?
		{"@conversation/tatooine_rebel_trainer_1:s_680cda08", "fm_get_back"}, -- How do I get back from space?
		{"@conversation/tatooine_rebel_trainer_1:s_5bfac9f1", "fm_where_ship"}, -- Where's my starship?
	}
}
socuna_convo_template:addScreen(socuna_convo_fm_then_what)

socuna_convo_not_a_pilot = ConvoScreen:new {
	id = "not_a_pilot",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1d3d8b65", -- You don't look like any sort of pilot to me.  I can't help you.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_not_a_pilot)

socuna_convo_privateer_pilot = ConvoScreen:new {
	id = "privateer_pilot",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_19d3ee2b", -- I can't help you, smuggler. Try sniffing around Wayfar... you'll find something that suits you.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_privateer_pilot)

socuna_convo_imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d6c8f764", -- Heh. What do you know. An Imperial. Get out of here while you still can!
	stopConversation = "true",
	animation = "threaten",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_imperial_pilot)

socuna_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_eff4eef6", -- %TU, isn't it?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_370822d1", "grounded_bad_news"}, -- Yes
	}
}
socuna_convo_template:addScreen(socuna_convo_grounded)

socuna_convo_grounded_bad_news = ConvoScreen:new {
	id = "grounded_bad_news",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_90087734", -- Bad news for you, %NU.  Alliance command has grounded you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_841d27db", "grounded_why"}, -- Why?
	}
}
socuna_convo_template:addScreen(socuna_convo_grounded_bad_news)

socuna_convo_grounded_why = ConvoScreen:new {
	id = "grounded_why",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4c85e14a", -- I think you know why.  You don't seem very dedicated to the cause.  I've heard reports that you've even been fighting FOR the Empire!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4d2987d3", "grounded_framed"}, -- No I haven't!
	}
}
socuna_convo_template:addScreen(socuna_convo_grounded_why)

socuna_convo_grounded_framed = ConvoScreen:new {
	id = "grounded_framed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4dd4aa17", -- Then you've been framed, %TU.  There's nothing I can do about it.  You need to clear your name before you can fly any more missions for the Rebel Alliance.  Improve your faction standing!
	stopConversation = "true",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_grounded_framed)

socuna_convo_recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1622e456", -- Good to meet you. My name is Da'la Socuna and I am here on behalf of the Rebel Alliance naval forces. I train pilots to fly and fight.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_78679b31", "recruit_fun"}, -- Sounds like fun. Where do I sign?
		{"@conversation/tatooine_rebel_trainer_1:s_3f5c320e", "recruit_help"}, -- I know of the rebellion. I want to help!
		{"@conversation/tatooine_rebel_trainer_1:s_db6b2243", "recruit_kindred"}, -- We are kindred spirits, Da'la Socuna.
	}
}
socuna_convo_template:addScreen(socuna_convo_recruitment)

socuna_convo_recruit_fun = ConvoScreen:new {
	id = "recruit_fun",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1eed018e", -- Fun? This is war, my friend. There's nothing 'fun' about having your friends swept away by the bloody tides of battle, losing your home, your future, everything that ever meant anything to you...
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8268c49d", "recruit_charming"}, -- We can skip the moral lesson, sister.
		{"@conversation/tatooine_rebel_trainer_1:s_55ea0c1b", "recruit_tell_me"}, -- Relax, lady. I didn't mean anything by that!
	}
}
socuna_convo_template:addScreen(socuna_convo_recruit_fun)

socuna_convo_recruit_charming = ConvoScreen:new {
	id = "recruit_charming",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d497fa22", -- Charming. What can I do to get you out of here?
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4101ebdd", "oath_regret"}, -- Make me a part of the Rebel Alliance.
		{"@conversation/tatooine_rebel_trainer_1:s_8631e93", "oath_all_kinds"}, -- I don't want to leave. I want to help.
	}
}
socuna_convo_template:addScreen(socuna_convo_recruit_charming)

socuna_convo_recruit_tell_me = ConvoScreen:new {
	id = "recruit_tell_me",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_66ae2bdf", -- Then tell me what you want or get out of here.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_768b62bc", "oath_youre_in"}, -- Just let me in your club, okay?
		{"@conversation/tatooine_rebel_trainer_1:s_7ed5fec3", "oath_cannon_fodder"}, -- I want to be part of the Alliance.
	}
}
socuna_convo_template:addScreen(socuna_convo_recruit_tell_me)

socuna_convo_recruit_help = ConvoScreen:new {
	id = "recruit_help",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_790724e4", -- Then it is fortunate that we have met. I can induct you to the Alliance pilot training program immediately.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c8fa77b8", "oath_enthusiasm"}, -- I can't wait!
		{"@conversation/tatooine_rebel_trainer_1:s_705f0112", "oath_we_begin"}, -- Train me to fly for the Alliance.
	}
}
socuna_convo_template:addScreen(socuna_convo_recruit_help)

socuna_convo_recruit_kindred = ConvoScreen:new {
	id = "recruit_kindred",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_33e1f5f2", -- Your kindness is radiant, my friend. We could really use someone like you in our organization. Are you willing to place your trust in the Rebel Alliance?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_31d45080", "oath_space_navy"}, -- The Alliance has my eternal faith.
		{"@conversation/tatooine_rebel_trainer_1:s_8234fa32", "oath_right_decision"}, -- Yes... I am willing. Yes.
	}
}
socuna_convo_template:addScreen(socuna_convo_recruit_kindred)

socuna_convo_oath_regret = ConvoScreen:new {
	id = "oath_regret",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a13bb0b0", -- I hope I don't regret this. I hereby admit you into the Alliance pilot training program.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise"}, -- I need a space ship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_regret)

socuna_convo_oath_all_kinds = ConvoScreen:new {
	id = "oath_all_kinds",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a93c5fce", -- Well, it takes all kinds, doesn't it? Welcome to the Rebel Alliance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise"}, -- I need a space ship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_all_kinds)

socuna_convo_oath_youre_in = ConvoScreen:new {
	id = "oath_youre_in",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_492ca0a5", -- Fine. You're in.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise"}, -- I need a space ship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_youre_in)

socuna_convo_oath_cannon_fodder = ConvoScreen:new {
	id = "oath_cannon_fodder",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_987055b5", -- We can always use cannon fodder. Welcome to the Alliance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e095ac8", "ship_surprise"}, -- I need a space ship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_cannon_fodder)

socuna_convo_oath_enthusiasm = ConvoScreen:new {
	id = "oath_enthusiasm",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_84d7bb8e", -- Your enthusiasm is welcome, friend!
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_bd53784c", "ship_not_a_problem"}, -- Ma'am, I require a starship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_enthusiasm)

socuna_convo_oath_we_begin = ConvoScreen:new {
	id = "oath_we_begin",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2fdfe99f", -- Then we shall begin. Welcome to the Rebel Alliance.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_bd53784c", "ship_covered"}, -- Ma'am, I require a starship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_we_begin)

socuna_convo_oath_space_navy = ConvoScreen:new {
	id = "oath_space_navy",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7d2cd92d", -- Then it is my pleasure to welcome you to the Alliance space navy.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_aed0dff", "ship_yours"}, -- I will require a starship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_space_navy)

socuna_convo_oath_right_decision = ConvoScreen:new {
	id = "oath_right_decision",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_23567daf", -- I know that you are making the right decision, friend.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_a42932d7", "ship_understood"}, -- I will need a starship.
	}
}
socuna_convo_template:addScreen(socuna_convo_oath_right_decision)

socuna_convo_ship_surprise = ConvoScreen:new {
	id = "ship_surprise",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_39f7d683", -- What a surprise. I'll grant access to one of the refurbished Z95's we have hidden here on Tatooine. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_ship_surprise)

socuna_convo_ship_not_a_problem = ConvoScreen:new {
	id = "ship_not_a_problem",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b2133e77", -- Not a problem. I'll grant access to one of the refurbished Z95's we have hidden here on Tatooine. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_ship_not_a_problem)

socuna_convo_ship_covered = ConvoScreen:new {
	id = "ship_covered",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_42ae7917", -- The Alliance has you covered. I'll grant access to one of the refurbished Z95's we have hidden here on Tatooine. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_ship_covered)

socuna_convo_ship_yours = ConvoScreen:new {
	id = "ship_yours",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f6e9edd", -- You shall have one. I'll grant access to one of the refurbished Z95's we have hidden here on Tatooine. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_ship_yours)

socuna_convo_ship_understood = ConvoScreen:new {
	id = "ship_understood",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f29cdd1", -- Understood, my friend. I'll grant access to one of the refurbished Z95's we have hidden here on Tatooine. Are you ready for your first assignment?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_ship_understood)

socuna_convo_first_assignment = ConvoScreen:new {
	id = "first_assignment",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b3408be1", -- Are you ready for your first assignment?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_first_assignment)

socuna_convo_mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_784540b7", -- Greetings, pilot! Are you ready for your assignment?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_mission1_offer)

socuna_convo_m1_not_so_fast = ConvoScreen:new {
	id = "m1_not_so_fast",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_38485fa9", -- Not so fast, Pilot!  You need to complete a few assignments before I'll train you.  Are you ready?
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d731f764", "m1_focus"}, -- (Shrug and smile.)
		{"@conversation/tatooine_rebel_trainer_1:s_90377ed4", "m1_outstanding"}, -- Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_6bb935f1", "m1_four_point"}, -- Yes, Da'la. I am ready.
		{"@conversation/tatooine_rebel_trainer_1:s_7478cd28", "m1_not_so_fast"}, -- Will you train me after this?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_not_so_fast)

socuna_convo_m1_focus = ConvoScreen:new {
	id = "m1_focus",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a6ec653a", -- Focus! You need to get over yourself or you won't be any use to us.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_b7b3029f", "m1_handle_it"}, -- Get on with it, lady.
		{"@conversation/tatooine_rebel_trainer_1:s_1a1806c1", "m1_better"}, -- Okay, okay. I'm sorry.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_focus)

socuna_convo_m1_handle_it = ConvoScreen:new {
	id = "m1_handle_it",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a5ecfd93", -- You think you can handle a simple four-point patrol?
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c261cfae", "m1_good_luck"}, -- No problem.
		{"@conversation/tatooine_rebel_trainer_1:s_c9c9c683", "m1_fried"}, -- What do you think, sweetie?
		{"@conversation/tatooine_rebel_trainer_1:s_31123adb", "m1_gonzo"}, -- Just four points, huh?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_handle_it)

socuna_convo_m1_good_luck = ConvoScreen:new {
	id = "m1_good_luck",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_aceff31e", -- Good luck, pilot.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_good_luck)

socuna_convo_m1_fried = ConvoScreen:new {
	id = "m1_fried",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_91d36035", -- I think you're going to get fried up there if you don't take this seriously.
	stopConversation = "false",
	animation = "threaten",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c261cfae", "m1_good_luck"}, -- No problem.
		{"@conversation/tatooine_rebel_trainer_1:s_c9c9c683", "m1_fried"}, -- What do you think, sweetie?
		{"@conversation/tatooine_rebel_trainer_1:s_31123adb", "m1_gonzo"}, -- Just four points, huh?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_fried)

socuna_convo_m1_gonzo = ConvoScreen:new {
	id = "m1_gonzo",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_cac4a12c", -- Don't worry, I'll have a gonzo patrol ready for you when you come back!
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c261cfae", "m1_good_luck"}, -- No problem.
		{"@conversation/tatooine_rebel_trainer_1:s_c9c9c683", "m1_fried"}, -- What do you think, sweetie?
		{"@conversation/tatooine_rebel_trainer_1:s_31123adb", "m1_gonzo"}, -- Just four points, huh?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_gonzo)

socuna_convo_m1_better = ConvoScreen:new {
	id = "m1_better",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9f625af9", -- That's better! You're assignment is a four-point patrol above Tatooine. Keep your sensors running the whole time - and when you come back, we'll want to download the data.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e28249ac", "m1_lucky"}, -- I'll be back in a snap!
		{"@conversation/tatooine_rebel_trainer_1:s_aa521016", "m1_be_careful"}, -- Looking for something in particular?
		{"@conversation/tatooine_rebel_trainer_1:s_2dfa0bf9", "m1_paid"}, -- When do I get paid?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_better)

socuna_convo_m1_lucky = ConvoScreen:new {
	id = "m1_lucky",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4536f86f", -- Yes. If you're lucky...
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_lucky)

socuna_convo_m1_be_careful = ConvoScreen:new {
	id = "m1_be_careful",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9487e7cd", -- Something might be looking for you, pilot... so be careful.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e28249ac", "m1_lucky"}, -- I'll be back in a snap!
		{"@conversation/tatooine_rebel_trainer_1:s_aa521016", "m1_be_careful"}, -- Looking for something in particular?
		{"@conversation/tatooine_rebel_trainer_1:s_2dfa0bf9", "m1_paid"}, -- When do I get paid?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_be_careful)

socuna_convo_m1_paid = ConvoScreen:new {
	id = "m1_paid",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_79e3a94", -- When you're done with the mission, slaymo.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e28249ac", "m1_lucky"}, -- I'll be back in a snap!
		{"@conversation/tatooine_rebel_trainer_1:s_aa521016", "m1_be_careful"}, -- Looking for something in particular?
		{"@conversation/tatooine_rebel_trainer_1:s_2dfa0bf9", "m1_paid"}, -- When do I get paid?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_paid)

socuna_convo_m1_outstanding = ConvoScreen:new {
	id = "m1_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4416b2d0", -- Outstanding. Your responsibility is to run a short-range, four-point patrol. When you are finished, your ship's sensor data will be downloaded to the Alliance 'net for Intel to review. Any questions?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/tatooine_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_outstanding)

socuna_convo_m1_looking = ConvoScreen:new {
	id = "m1_looking",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ce6b43af", -- We have reason to believe that the Empire is moving a wing of TIE fighters directly into an Alliance supply route. We need to know more.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/tatooine_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_looking)

socuna_convo_m1_where = ConvoScreen:new {
	id = "m1_where",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9757e73a", -- You'll be covering a little-used Alliance supply route. It's become more important in recent days because of Imperial activity outside the asteroid belt. We have plans for this area, and need to know that we'll remain unseen.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/tatooine_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_where)

socuna_convo_m1_blast = ConvoScreen:new {
	id = "m1_blast",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9b562c5a", -- Don't make this more than it is, pilot. This is not 'search and destroy' - this is a sensor sweep. Stay out of trouble. Come back in one piece!
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c7939f2f", "m1_looking"}, -- What are we looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_2adb435", "m1_where"}, -- Where am I patrolling?
		{"@conversation/tatooine_rebel_trainer_1:s_7a27e11", "m1_blast"}, -- I'll blast any Imperial crosses my path!
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_blast)

socuna_convo_force_be_with_you = ConvoScreen:new {
	id = "force_be_with_you",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d4f7f6d5", -- And with you as well.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_force_be_with_you)

socuna_convo_m1_four_point = ConvoScreen:new {
	id = "m1_four_point",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8720792f", -- You will fly a four-point patrol above Tatooine. We will need your ship's sensor data when you are finished. Stay hidden... sorry to say, I have a bad feeling about this one.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_92e1301f", "m1_fine"}, -- Don't worry. I will be fine.
		{"@conversation/tatooine_rebel_trainer_1:s_658f174d", "m1_what_looking"}, -- What am I looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_four_point)

socuna_convo_m1_fine = ConvoScreen:new {
	id = "m1_fine",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4e8bbd4d", -- The Force be with you, friend...
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_fine)

socuna_convo_m1_what_looking = ConvoScreen:new {
	id = "m1_what_looking",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_6360ad02", -- Any Imperial activities. This is a little-used Alliance supply route. It will become more important in the near future - and we are concerned that the Empire has knowledge of our operations.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_92e1301f", "m1_fine"}, -- Don't worry. I will be fine.
		{"@conversation/tatooine_rebel_trainer_1:s_658f174d", "m1_what_looking"}, -- What am I looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_what_looking)

socuna_convo_m1_hidden = ConvoScreen:new {
	id = "m1_hidden",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_5d157c36", -- Just try not to stir up any pirate action - and don't fire on any Imperials unless they threaten you.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_92e1301f", "m1_fine"}, -- Don't worry. I will be fine.
		{"@conversation/tatooine_rebel_trainer_1:s_658f174d", "m1_what_looking"}, -- What am I looking for?
		{"@conversation/tatooine_rebel_trainer_1:s_93470245", "m1_hidden"}, -- How should I stay hidden?
	}
}
socuna_convo_template:addScreen(socuna_convo_m1_hidden)

socuna_convo_mission1_patrol_failed = ConvoScreen:new {
	id = "mission1_patrol_failed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_fb9b39e5", -- Report, pilot!
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_4f90bab3", "m1f_why_not"}, -- I was unable to finish.
		{"@conversation/tatooine_rebel_trainer_1:s_b9c55cab", "m1f_unacceptable"}, -- I failed the mission.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission1_patrol_failed)

socuna_convo_m1f_why_not = ConvoScreen:new {
	id = "m1f_why_not",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7f9b8387", -- Why not?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_7d4eaca7", "m1f_try_again"}, -- I don't know.
		{"@conversation/tatooine_rebel_trainer_1:s_583707c4", "m1f_interesting"}, -- (Lie about what happened.)
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_why_not)

socuna_convo_m1f_unacceptable = ConvoScreen:new {
	id = "m1f_unacceptable",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_bb761ef6", -- This is unacceptable! You get back out there and finish this mission, pilot!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_unacceptable)

socuna_convo_m1f_try_again = ConvoScreen:new {
	id = "m1f_try_again",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c4b9eaff", -- Maybe you should try again. And this time... don't fail!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_try_again)

socuna_convo_m1f_interesting = ConvoScreen:new {
	id = "m1f_interesting",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a7a6018f", -- Hm. Interesting. Are you ready to try again?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d70dba34", "m1f_renewed"}, -- Yes.
		{"@conversation/tatooine_rebel_trainer_1:s_4c695dbd", "m1f_not_working"}, -- No.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_interesting)

socuna_convo_m1f_renewed = ConvoScreen:new {
	id = "m1f_renewed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_cc82ca6b", -- Good! Your orders have been renewed. Good luck, pilot!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_renewed)

socuna_convo_m1f_not_working = ConvoScreen:new {
	id = "m1f_not_working",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_dcf7d387", -- I don't think this is going to work out, pilot.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1f_not_working)

socuna_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_fe789dac", -- Report!
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_11327023", "m1s_tie_attack"}, -- The patrol was interrupted by a TIE attack.
		{"@conversation/tatooine_rebel_trainer_1:s_68ee2577", "m1s_cannot_fail"}, -- I could not finish the mission.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission1_failed)

socuna_convo_m1s_tie_attack = ConvoScreen:new {
	id = "m1s_tie_attack",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_aadc4812", -- Well, I'll admit that I didn't prep you for a TIE fighter attack. How do you think you'll fare on your second try?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_b2683b4a", "m1s_prove_it"}, -- Piece of cake.
		{"@conversation/tatooine_rebel_trainer_1:s_ffb79794", "m1s_good_luck"}, -- I will complete the mission, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_b3e9c738", "m1s_hope_so"}, -- I'm ready for anything.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_tie_attack)

socuna_convo_m1s_prove_it = ConvoScreen:new {
	id = "m1s_prove_it",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_34bc4ce6", -- Yeah, right. Prove it!
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_prove_it)

socuna_convo_m1s_good_luck = ConvoScreen:new {
	id = "m1s_good_luck",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ed5af630", -- Excellent. Good luck, pilot.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_good_luck)

socuna_convo_m1s_hope_so = ConvoScreen:new {
	id = "m1s_hope_so",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9e21ae0d", -- I truly hope so.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_hope_so)

socuna_convo_m1s_cannot_fail = ConvoScreen:new {
	id = "m1s_cannot_fail",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ca06f3a2", -- We cannot afford for you to fail, pilot. The Empire outnumbers us - outguns us... the only hope we have is to out-fight them! Are you ready to try again?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d70dba34", "m1s_get_back"}, -- Yes.
		{"@conversation/tatooine_rebel_trainer_1:s_4c695dbd", "m1s_act_together"}, -- No.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_cannot_fail)

socuna_convo_m1s_get_back = ConvoScreen:new {
	id = "m1s_get_back",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_834edaa1", -- Good. Then get back out there!
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_get_back)

socuna_convo_m1s_act_together = ConvoScreen:new {
	id = "m1s_act_together",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_fb7175d6", -- Get your act together!
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1s_act_together)

socuna_convo_mission1_report = ConvoScreen:new {
	id = "mission1_report",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2c052357", -- Good to see you again, pilot! I will hear your report, now.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_64b4e5f7", "m1r_no_clue"}, -- (Brag about blasting TIE fighters)
		{"@conversation/tatooine_rebel_trainer_1:s_97e13b2e", "m1r_not_random"}, -- (Brief Da'la with all due accuracy)
		{"@conversation/tatooine_rebel_trainer_1:s_11327023", "m1r_bad_news"}, -- The patrol was interrupted by a TIE attack.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission1_report)

socuna_convo_m1r_no_clue = ConvoScreen:new {
	id = "m1r_no_clue",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d7f5cd5b", -- You have no clue, do you?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_7e77b672", "m1r_probably"}, -- Shouldn't you be thanking me?
		{"@conversation/tatooine_rebel_trainer_1:s_2313ac9e", "m1r_lucky"}, -- What are you talking about?
		{"@conversation/tatooine_rebel_trainer_1:s_2427d272", "m1r_consider"}, -- Well... I'm sorry.
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_no_clue)

socuna_convo_m1r_probably = ConvoScreen:new {
	id = "m1r_probably",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_bc865091", -- Probably.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_probably)

socuna_convo_m1r_lucky = ConvoScreen:new {
	id = "m1r_lucky",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8a7cca63", -- You got LUCKY! You need to get your act together or you'll be space dust. Understand me?
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_lucky)

socuna_convo_m1r_consider = ConvoScreen:new {
	id = "m1r_consider",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_71239ef6", -- I don't want to hear it. Consider yourself lucky to be alive.
	stopConversation = "true",
	animation = "point_to_self",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_consider)

socuna_convo_m1r_not_random = ConvoScreen:new {
	id = "m1r_not_random",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_e03d1a04", -- Hm. This does not sound like a random encounter. I would bet the Empire has knowledge of our operations here. Alliance HQ isn't going to like this report... but I'm very glad you're safe and sound.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_74474b33", "m1r_we_wait"}, -- What is our next move, ma'am?
		{"@conversation/tatooine_rebel_trainer_1:s_bac616e6", "m1r_digest"}, -- I'm ready for my next mission!
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_not_random)

socuna_convo_m1r_we_wait = ConvoScreen:new {
	id = "m1r_we_wait",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a46d9f8b", -- Our next move? We wait. Alliance HQ is going to want time to review our situation and re-evaluate our combat options. Check back with me later...
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_we_wait)

socuna_convo_m1r_digest = ConvoScreen:new {
	id = "m1r_digest",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a018cd7e", -- Let's give Alliance HQ a moment to digest this information. A change of plans may be in store...
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_digest)

socuna_convo_m1r_bad_news = ConvoScreen:new {
	id = "m1r_bad_news",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2784686", -- So the Empire knows a bit more than we expected. This is very bad news, pilot. Alliance HQ will want to learn of this attack as soon as possible.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m1r_bad_news)

socuna_convo_mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_406f8d3e", -- It will take a bit to decode your ship sensor data. In the meantime, we have another assignment for you... if you are ready.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c92d07b4", "m2_take_off"}, -- Sure. Why not.
		{"@conversation/tatooine_rebel_trainer_1:s_fbac0bde", "m2_outstanding"}, -- (Salute) Ma'am! Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_7d15be50", "m2_excellent"}, -- I am more than ready, Da'la.
		{"@conversation/tatooine_rebel_trainer_1:s_1895ee37", "m2_not_yet"}, -- Will you train me yet?
	}
}
socuna_convo_template:addScreen(socuna_convo_mission2_offer)

socuna_convo_m2_not_yet = ConvoScreen:new {
	id = "m2_not_yet",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_6b52240", -- Not just yet, Pilot!  I have a few more assignments for you before I can train you.  Are you ready to get to work?
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_c92d07b4", "m2_take_off"}, -- Sure. Why not.
		{"@conversation/tatooine_rebel_trainer_1:s_fbac0bde", "m2_outstanding"}, -- (Salute) Ma'am! Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_7d15be50", "m2_excellent"}, -- I am more than ready, Da'la.
		{"@conversation/tatooine_rebel_trainer_1:s_1895ee37", "m2_not_yet"}, -- Will you train me yet?
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_not_yet)

socuna_convo_m2_take_off = ConvoScreen:new {
	id = "m2_take_off",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_e28bc942", -- Hmph. Take off. Find any Imperial Tie Fighters in the Tatooine system and take out at least four of them.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e9da2a94", "m2_four"}, -- More TIE fighters, huh?
		{"@conversation/tatooine_rebel_trainer_1:s_57a53dcf", "m2_find_them"}, -- Where do I find them?
		{"@conversation/tatooine_rebel_trainer_1:s_5aa307dc", "m2_one_piece"}, -- Piece o'cake, lady.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_take_off)

socuna_convo_m2_four = ConvoScreen:new {
	id = "m2_four",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_949ea1ef", -- Just four should do it. We want the Empire to understand that their intel is compromised. This will buy us some time for other operations. Any more questions, or are you ready to shut up and get to work?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e9da2a94", "m2_four"}, -- More TIE fighters, huh?
		{"@conversation/tatooine_rebel_trainer_1:s_57a53dcf", "m2_find_them"}, -- Where do I find them?
		{"@conversation/tatooine_rebel_trainer_1:s_5aa307dc", "m2_one_piece"}, -- Piece o'cake, lady.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_four)

socuna_convo_m2_find_them = ConvoScreen:new {
	id = "m2_find_them",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7f3c5f06", -- We can't hold your hand all the time pilot. Search the system, you're bound to find some!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_e9da2a94", "m2_four"}, -- More TIE fighters, huh?
		{"@conversation/tatooine_rebel_trainer_1:s_57a53dcf", "m2_find_them"}, -- Where do I find them?
		{"@conversation/tatooine_rebel_trainer_1:s_5aa307dc", "m2_one_piece"}, -- Piece o'cake, lady.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_find_them)

socuna_convo_m2_one_piece = ConvoScreen:new {
	id = "m2_one_piece",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_434aa00b", -- Make sure you stay in one piece, pilot.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_one_piece)

socuna_convo_m2_outstanding = ConvoScreen:new {
	id = "m2_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8001a590", -- Outstanding! Find any Imperial TIE Fighters in the Tatooine system and take out at least four of them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a78d00e", "m2_only_ties"}, -- Only TIE fighters, ma'am?
		{"@conversation/tatooine_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_outstanding)

socuna_convo_m2_only_ties = ConvoScreen:new {
	id = "m2_only_ties",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b0778713", -- The Empire does not yet know that their fleet info has been compromised. Strike the new TIE fighters moving into this area with extreme prejudice, and they will have no choice but to halt their invasion strategy.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a78d00e", "m2_only_ties"}, -- Only TIE fighters, ma'am?
		{"@conversation/tatooine_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_only_ties)

socuna_convo_m2_rally = ConvoScreen:new {
	id = "m2_rally",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f1147d11", -- There is none, it is your job to find them pilot. Search the Tatooine system for targets of opportunity.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8a78d00e", "m2_only_ties"}, -- Only TIE fighters, ma'am?
		{"@conversation/tatooine_rebel_trainer_1:s_97e129cd", "m2_rally"}, -- Where is the rally point?
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_rally)

socuna_convo_m2_excellent = ConvoScreen:new {
	id = "m2_excellent",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_306de5c", -- Excellent. Find any Imperial Tie Fighters in the Tatooine system and take out at least four of them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/tatooine_rebel_trainer_1:s_ab56e9c6", "m2_target_info"}, -- Do you have more target information?
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_excellent)

socuna_convo_m2_location = ConvoScreen:new {
	id = "m2_location",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7f3c5f06", -- We can't hold your hand all the time pilot. Search the system, you're bound to find some!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/tatooine_rebel_trainer_1:s_ab56e9c6", "m2_target_info"}, -- Do you have more target information?
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_location)

socuna_convo_m2_target_info = ConvoScreen:new {
	id = "m2_target_info",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a89f2288", -- The Empire plans to move several wings of TIE fighters into this zone. If they are allowed to succeed, it could spell disaster for the Alliance here on Tatooine.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_1809c6fc", "m2_location"}, -- What is the location?
		{"@conversation/tatooine_rebel_trainer_1:s_ab56e9c6", "m2_target_info"}, -- Do you have more target information?
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "force_be_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2_target_info)

socuna_convo_mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_9c146b24", -- I don't like what I'm hearing, pilot! Report, now!
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6657b5a3", "m2f_whose_fault"}, -- It wasn't my fault!
		{"@conversation/tatooine_rebel_trainer_1:s_740e2e66", "m2f_redeem"}, -- Sorry, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_54ec182b", "m2f_second_time"}, -- I failed to destroy the targets.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission2_failed)

socuna_convo_m2f_whose_fault = ConvoScreen:new {
	id = "m2f_whose_fault",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a9163b5e", -- Whose fault was it, then?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_adacb6c2", "m2f_do_something"}, -- Well... the Empire's?
		{"@conversation/tatooine_rebel_trainer_1:s_a45033de", "m2f_learning"}, -- Okay, so it was mine.
		{"@conversation/tatooine_rebel_trainer_1:s_6cf8e18b", "m2f_no_sense"}, -- (Tell a bold lie.)
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_whose_fault)

socuna_convo_m2f_do_something = ConvoScreen:new {
	id = "m2f_do_something",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_add5c243", -- Well... do something about it!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_do_something)

socuna_convo_m2f_learning = ConvoScreen:new {
	id = "m2f_learning",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_5100b9ac", -- You're learning, then. Good. Try again!
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_learning)

socuna_convo_m2f_no_sense = ConvoScreen:new {
	id = "m2f_no_sense",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8e0b0814", -- Hm. You're not making any sense. Why don't you try this mission again?
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_no_sense)

socuna_convo_m2f_redeem = ConvoScreen:new {
	id = "m2f_redeem",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2aab204b", -- Are you ready to redeem yourself, pilot?!
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_347e4a03", "m2f_see_you"}, -- Ma'am! Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_1b488c78", "m2f_disappoint"}, -- I'm... not sure
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_redeem)

socuna_convo_m2f_see_you = ConvoScreen:new {
	id = "m2f_see_you",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ac596e57", -- Outstanding! I'll see you when you're done!
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_see_you)

socuna_convo_m2f_disappoint = ConvoScreen:new {
	id = "m2f_disappoint",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_648f0fc", -- You really disappoint me, pilot.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_disappoint)

socuna_convo_m2f_second_time = ConvoScreen:new {
	id = "m2f_second_time",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f7ebcc5f", -- Will you fail a second time if I re-assign the mission to you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_968c130f", "m2f_try_again"}, -- No. I will not!
		{"@conversation/tatooine_rebel_trainer_1:s_f892eb03", "m2f_try_harder"}, -- I make no guarantees.
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_second_time)

socuna_convo_m2f_try_again = ConvoScreen:new {
	id = "m2f_try_again",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_71370b1e", -- Good! Try again!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_try_again)

socuna_convo_m2f_try_harder = ConvoScreen:new {
	id = "m2f_try_harder",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_63c4c628", -- You must try harder! The Alliance doesn't stand a chance with pilots like you... with your attitude!
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2f_try_harder)

socuna_convo_mission2_report = ConvoScreen:new {
	id = "mission2_report",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1f0828c5", -- Report mission status!
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6a7a0499", "m2r_best"}, -- (Brag about blasting even more TIE fighters)
		{"@conversation/tatooine_rebel_trainer_1:s_6d7d5f1b", "m2r_outstanding"}, -- All targets eliminated, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_dcbc639a", "m2r_anticipated"}, -- The mission is a success, Da'la.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission2_report)

socuna_convo_m2r_best = ConvoScreen:new {
	id = "m2r_best",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1500b5d6", -- You know, all the pilots say that you're the BEST!
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_3b6d2f05", "m2r_backwards"}, -- Whatever...
		{"@conversation/tatooine_rebel_trainer_1:s_2ea6d944", "m2r_backwards"}, -- Really?
	}
}
socuna_convo_template:addScreen(socuna_convo_m2r_best)

socuna_convo_m2r_backwards = ConvoScreen:new {
	id = "m2r_backwards",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d18e28ba", -- Maybe I got that completely backwards. Who knows?
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2r_backwards)

socuna_convo_m2r_outstanding = ConvoScreen:new {
	id = "m2r_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b91ba199", -- Outstanding! Check back with me when you are ready for your next assignment!
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2r_outstanding)

socuna_convo_m2r_anticipated = ConvoScreen:new {
	id = "m2r_anticipated",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_463f3bbc", -- I anticipated as much. Good work, pilot! Check back with me soon for your next assignment.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m2r_anticipated)

socuna_convo_mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_bda1eb17", -- Your ship sensor data has been completely decoded. The Alliance supply route is entirely compromised. We need you to scout a new route for our in-system supply convoy. Are you up to it?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_3f1a842c", "m3_death_of_me"}, -- Yeah, yeah.
		{"@conversation/tatooine_rebel_trainer_1:s_fbac0bde", "m3_affirmative"}, -- (Salute) Ma'am! Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_1e626caa", "m3_critical"}, -- Of course. Those supplies are critical!
		{"@conversation/tatooine_rebel_trainer_1:s_1895ee37", "m3_impatient"}, -- Will you train me yet?
	}
}
socuna_convo_template:addScreen(socuna_convo_mission3_offer)

socuna_convo_m3_impatient = ConvoScreen:new {
	id = "m3_impatient",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d89a93ff", -- %TU, you're too impatient.  Right now I need you to scout that supply route.  We'll talk about training later.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_3f1a842c", "m3_death_of_me"}, -- Yeah, yeah.
		{"@conversation/tatooine_rebel_trainer_1:s_fbac0bde", "m3_affirmative"}, -- (Salute) Ma'am! Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_1e626caa", "m3_critical"}, -- Of course. Those supplies are critical!
		{"@conversation/tatooine_rebel_trainer_1:s_1895ee37", "m3_impatient"}, -- Will you train me yet?
	}
}
socuna_convo_template:addScreen(socuna_convo_m3_impatient)

socuna_convo_m3_death_of_me = ConvoScreen:new {
	id = "m3_death_of_me",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_bb68963e", -- You'll be the death of me, pilot.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3_death_of_me)

socuna_convo_m3_affirmative = ConvoScreen:new {
	id = "m3_affirmative",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8b9926b6", -- Affirmative. Report when your patrol is complete.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3_affirmative)

socuna_convo_m3_critical = ConvoScreen:new {
	id = "m3_critical",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ab640430", -- Critical to say the least, my friend. We must resume supply flights as soon as possible. To accomplish this, we need you to sweep a five-point area. Again, your ship sensor data will be used to plot an effective route for our larger transports.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d0233b4b", "always"}, -- The Force be with us.
	}
}
socuna_convo_template:addScreen(socuna_convo_m3_critical)

socuna_convo_always = ConvoScreen:new {
	id = "always",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ca51315f", -- Always.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_always)

socuna_convo_mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a87c06b", -- I already know what happened. Do you have anything to say for yourself?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6657b5a3", "m3f_kidding"}, -- It wasn't my fault!
		{"@conversation/tatooine_rebel_trainer_1:s_877e028c", "m3_affirmative"}, -- Ma'am! I want another chance, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_eab1caa8", "m3f_make_it_happen"}, -- I'm not in the habit of making excuses.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission3_failed)

socuna_convo_m3f_kidding = ConvoScreen:new {
	id = "m3f_kidding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b7af9aa", -- Are you kidding me?! Not your fault? I have grown so sick of your attitude... I just can't stand it! Tell me you're going to get back up there and do it right this time!
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_fc1f4e33", "m3f_fine"}, -- Okay, fine!
		{"@conversation/tatooine_rebel_trainer_1:s_2c3fe4f", "m3f_save_it"}, -- Listen, lady...
	}
}
socuna_convo_template:addScreen(socuna_convo_m3f_kidding)

socuna_convo_m3f_fine = ConvoScreen:new {
	id = "m3f_fine",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_3fa4f0ff", -- Fine!
	stopConversation = "true",
	animation = "threaten",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3f_fine)

socuna_convo_m3f_save_it = ConvoScreen:new {
	id = "m3f_save_it",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_616dbcc8", -- Save it! I'm assigning a new mission to you. Don't come back until it's finished!
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3f_save_it)

socuna_convo_m3f_make_it_happen = ConvoScreen:new {
	id = "m3f_make_it_happen",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b5719d30", -- Then get back out there and make it happen, pilot!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3f_make_it_happen)

socuna_convo_mission3_report = ConvoScreen:new {
	id = "mission3_report",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_52efbcd5", -- I hear you had some surprises up there?
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_766563c7", "m3r_lucky"}, -- Nothing I couldn't handle.
		{"@conversation/tatooine_rebel_trainer_1:s_3ccb2ef2", "m3r_outstanding"}, -- I responded to a distress call, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_9109c202", "m3r_beautifully"}, -- An Alliance freighter needed my help.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission3_report)

socuna_convo_m3r_lucky = ConvoScreen:new {
	id = "m3r_lucky",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f2ef125b", -- Lucky for us.  Here's a little bonus for you.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_flightsuit"}, -- What's this?
	}
}
socuna_convo_template:addScreen(socuna_convo_m3r_lucky)

socuna_convo_m3r_outstanding = ConvoScreen:new {
	id = "m3r_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_16949037", -- Outstanding work, pilot! Get some rest. Check back with me later for a new assignment.  Also, I've got something extra for you.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_flightsuit"}, -- What's this?
	}
}
socuna_convo_template:addScreen(socuna_convo_m3r_outstanding)

socuna_convo_m3r_beautifully = ConvoScreen:new {
	id = "m3r_beautifully",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4c1acfbf", -- And you performed beautifully. The Alliance thanks you.  I've got something special for you.
	stopConversation = "false",
	animation = "bow",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8be95ab4", "m3r_flightsuit"}, -- What's this?
	}
}
socuna_convo_template:addScreen(socuna_convo_m3r_beautifully)

socuna_convo_m3r_bandolier = ConvoScreen:new {
	id = "m3r_bandolier",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f4642ca3", -- It's a multipocket bandolier.  I'd get you a flightsuit but I don't think I have one that would fit you... anyway, this will help you keep your things organized.
	stopConversation = "true",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3r_bandolier)

socuna_convo_m3r_flightsuit = ConvoScreen:new {
	id = "m3r_flightsuit",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_5b4a6885", -- It's a flightsuit.  You'll look like a real pilot, now.
	stopConversation = "true",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m3r_flightsuit)

socuna_convo_mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ae1edd02", -- While you were away we gathered enough information to put the Imperial fleet movement out of commission. Are you ready to take flight again?
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_cd68fc71", "m4_younger"}, -- Well, I'm not getting any younger.
		{"@conversation/tatooine_rebel_trainer_1:s_6b490480", "m4_superb"}, -- (Salute) Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_2477af4a", "m4_rallying"}, -- For the Alliance... always.
		{"@conversation/tatooine_rebel_trainer_1:s_f80372b3", "m4_no_youre_not"}, -- I'm ready for training?
	}
}
socuna_convo_template:addScreen(socuna_convo_mission4_offer)

socuna_convo_m4_no_youre_not = ConvoScreen:new {
	id = "m4_no_youre_not",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_22ce0785", -- No, you're not!
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_eb7aaed2", "m4_deal"}, -- Yes I am!
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_no_youre_not)

socuna_convo_m4_deal = ConvoScreen:new {
	id = "m4_deal",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b9c90f82", -- Well... maybe you are.  But this is more important, right now.  I'll make a deal with you, complete this mission and THEN I will train you.  This is urgent, so I hope you're ready.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_cd68fc71", "m4_younger"}, -- Well, I'm not getting any younger.
		{"@conversation/tatooine_rebel_trainer_1:s_6b490480", "m4_superb"}, -- (Salute) Affirmative!
		{"@conversation/tatooine_rebel_trainer_1:s_2477af4a", "m4_rallying"}, -- For the Alliance... always.
		{"@conversation/tatooine_rebel_trainer_1:s_f80372b3", "m4_no_youre_not"}, -- I'm ready for training?
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_deal)

socuna_convo_m4_younger = ConvoScreen:new {
	id = "m4_younger",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_994615e7", -- This is good - for some day you shall rejoin the infinite... and I may then be allowed to rest.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_ddea1965", "m4_nothing_you_cant"}, -- What's the job, honey?
		{"@conversation/tatooine_rebel_trainer_1:s_6a150013", "m4_details"}, -- Let's have some details.
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_younger)

socuna_convo_m4_nothing_you_cant = ConvoScreen:new {
	id = "m4_nothing_you_cant",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_55ce5bee", -- Nothing you can't handle. Destroy the veteran TIE pilot leader at a specific rally point. Come back here... if you survive.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_nothing_you_cant)

socuna_convo_m4_details = ConvoScreen:new {
	id = "m4_details",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_a20f8416", -- The recent Imperial activity is being led by a veteran TIE fighter pilot. We know of his location. Fly to the nav point, and eliminate this pilot with extreme prejudice.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_details)

socuna_convo_m4_superb = ConvoScreen:new {
	id = "m4_superb",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2f0da72f", -- Superb! We have located a rally point from which the Empire has staged their recent aggressions. Go to this point and bring down a veteran TIE fighter pilot - the ringleader, as it were.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_640d20f4", "m4_good_luck"}, -- Yes ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_87a8cca7", "m4_know_pilot"}, -- How will I know this pilot?
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_superb)

socuna_convo_m4_good_luck = ConvoScreen:new {
	id = "m4_good_luck",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c62cae3d", -- Good luck, my friend.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_good_luck)

socuna_convo_m4_know_pilot = ConvoScreen:new {
	id = "m4_know_pilot",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8916a30", -- It should not be difficult. He should be one of very few veteran TIE fighter pilots in this vicinity. But, if you want to be thorough... bring down any TIE fighter pilots you see in this area.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_640d20f4", "m4_good_luck"}, -- Yes ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_87a8cca7", "m4_know_pilot"}, -- How will I know this pilot?
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_know_pilot)

socuna_convo_m4_rallying = ConvoScreen:new {
	id = "m4_rallying",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_61c8b0c2", -- Then you will be glad to know we have reliable information that the Empire is rallying TIE fighter forces at a nav point high above Tatooine. They are being led by an experienced TIE veteran. Eliminate this TIE veteran pilot with extreme prejudice. This should bring their plans crashing to the ground.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/tatooine_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/tatooine_rebel_trainer_1:s_3d693d0", "m4_honor"}, -- I will bring honor to the Alliance, ma'am.
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_rallying)

socuna_convo_m4_veteran = ConvoScreen:new {
	id = "m4_veteran",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f4cc85fa", -- Not very much. You may find more than one in the general area - but Alliance intelligence indicates that the Empire has charged one veteran TIE pilot with coordinating aggressions in this system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/tatooine_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/tatooine_rebel_trainer_1:s_3d693d0", "m4_honor"}, -- I will bring honor to the Alliance, ma'am.
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_veteran)

socuna_convo_m4_targets = ConvoScreen:new {
	id = "m4_targets",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c3d77bb4", -- Expect the rally point to be patrolled by junior TIE cadets. They will be quick to respond if they see you first - so be very careful. Keep your eye out for the veteran TIE fighter pilot, eliminate him, and get back here as soon as you can.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_cf04e474", "m4_veteran"}, -- What more do we know of this TIE veteran?
		{"@conversation/tatooine_rebel_trainer_1:s_d779178a", "m4_targets"}, -- What other targets are in the area?
		{"@conversation/tatooine_rebel_trainer_1:s_3d693d0", "m4_honor"}, -- I will bring honor to the Alliance, ma'am.
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_targets)

socuna_convo_m4_honor = ConvoScreen:new {
	id = "m4_honor",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_e24d9d51", -- You already have. Good luck to you... I hope to see you again very soon.
	stopConversation = "true",
	animation = "bow",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4_honor)

socuna_convo_mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_fcd9ce0e", -- This cannot stand, pilot! We need you to take down that Veteran TIE pilot!
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_7e1ada01", "m4f_whats_wrong"}, -- Yeah, yeah...
		{"@conversation/tatooine_rebel_trainer_1:s_8ef10336", "m4f_outstanding"}, -- Affirmative, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_e42b260e", "m4f_force"}, -- I'm on my way.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission4_failed)

socuna_convo_m4f_whats_wrong = ConvoScreen:new {
	id = "m4f_whats_wrong",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_ca0c0b13", -- What's wrong with you? Get out there and prove your worth!
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4f_whats_wrong)

socuna_convo_m4f_outstanding = ConvoScreen:new {
	id = "m4f_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_cd1af2b9", -- Outstanding! Good luck, pilot!
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4f_outstanding)

socuna_convo_m4f_force = ConvoScreen:new {
	id = "m4f_force",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1f7c77cd", -- The Force be with you.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4f_force)

socuna_convo_mission4_report = ConvoScreen:new {
	id = "mission4_report",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2f8ec5d4", -- Report on the TIE veteran target!
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_a8b44679", "m4r_didnt_catch"}, -- (Brag about defeating the TIE Veteran)
		{"@conversation/tatooine_rebel_trainer_1:s_ce2c09ec", "m4r_great_work"}, -- Mission accomplished, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_67104689", "m4r_honor"}, -- He has joined the infinite, Da'la.
	}
}
socuna_convo_template:addScreen(socuna_convo_mission4_report)

socuna_convo_m4r_didnt_catch = ConvoScreen:new {
	id = "m4r_didnt_catch",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_4ba4be80", -- What was that? I didn't catch that...
	stopConversation = "false",
	animation = "yawn",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_3f30cd7b", "m4r_thrilling"}, -- (Brag more)
		{"@conversation/tatooine_rebel_trainer_1:s_40440fa", "m4r_dismissed"}, -- The TIE Vet is dead, okay?
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_didnt_catch)

socuna_convo_m4r_thrilling = ConvoScreen:new {
	id = "m4r_thrilling",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_3cb5ab17", -- So thrilling...
	stopConversation = "true",
	animation = "hug_self",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_thrilling)

socuna_convo_m4r_dismissed = ConvoScreen:new {
	id = "m4r_dismissed",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_5c7ecf43", -- That's good to know. You're dismissed.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_dismissed)

socuna_convo_m4r_great_work = ConvoScreen:new {
	id = "m4r_great_work",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2da98563", -- Great work! Now, get some rest and check back with me later. I will have more for you to do.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_great_work)

socuna_convo_m4r_honor = ConvoScreen:new {
	id = "m4r_honor",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_95ad8f55", -- You bring honor to the Alliance, my friend. This was no easy task.
	stopConversation = "false",
	animation = "bow",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d0233b4b", "always"}, -- The Force be with us.
		{"@conversation/tatooine_rebel_trainer_1:s_baae2f70", "m4r_also_with_you"}, -- (Salute) The Force be with you.
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_honor)

socuna_convo_m4r_also_with_you = ConvoScreen:new {
	id = "m4r_also_with_you",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_30c1fec7", -- And also with you.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_m4r_also_with_you)

socuna_convo_training_first = ConvoScreen:new {
	id = "training_first",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_6221bd32", -- Congratulations, pilot. Our immediate goals have been met. We have time for training. What areas of Alliance piloting interest you the most?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_26970ef", "trained_starships"}, -- I am interested in basic starfighter training.
		{"@conversation/tatooine_rebel_trainer_1:s_d912490", "trained_weapons"}, -- I am interested in basic Alliance component use.
		{"@conversation/tatooine_rebel_trainer_1:s_8c272224", "trained_procedures"}, -- I am interested in starfighter survival tactics.
		{"@conversation/tatooine_rebel_trainer_1:s_9480f430", "trained_droid"}, -- I am interested in droid interface basics.
	}
}
socuna_convo_template:addScreen(socuna_convo_training_first)

socuna_convo_training_more = ConvoScreen:new {
	id = "training_more",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2c8ee9d", -- There is more I have to teach you, pilot. What areas interest you at the moment?
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_26970ef", "trained_starships"}, -- I am interested in basic starfighter training.
		{"@conversation/tatooine_rebel_trainer_1:s_d912490", "trained_weapons"}, -- I am interested in basic Alliance component use.
		{"@conversation/tatooine_rebel_trainer_1:s_8c272224", "trained_procedures"}, -- I am interested in starfighter survival tactics.
		{"@conversation/tatooine_rebel_trainer_1:s_9480f430", "trained_droid"}, -- I am interested in droid interface basics.
	}
}
socuna_convo_template:addScreen(socuna_convo_training_more)

socuna_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c7afc225", -- Let's upgrade your starship license then, shall we?
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_trained_starships)

socuna_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d5bc59d9", -- I have adjusted your pilot certification to handle more intricate components.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_trained_weapons)

socuna_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_96e50d8", -- Here is an update to your procedures manual.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_trained_procedures)

socuna_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c93f1cdc", -- Here are some new droid programs. Use them wisely.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_trained_droid)

socuna_convo_duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_59c382bc", -- Good day, pilot. Are you here for elective duty mission? There is still plenty of work for us here in Tatooine.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/tatooine_rebel_trainer_1:s_6e646769", "duty_no_thanks"}, -- No, thanks.
		{"@conversation/tatooine_rebel_trainer_1:s_e0cb3e19", "enlist_ground"}, -- I'm ready to enlist with the ground forces!
	}
}
socuna_convo_template:addScreen(socuna_convo_duty_missions)

socuna_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_57c3f83e", -- Always good to see another Rebel pilot... but you're not one of my recruits. What can I do for you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_1583743c", "non_member_no_missions"}, -- Do you have any missions I could fly?
	}
}
socuna_convo_template:addScreen(socuna_convo_non_member)

socuna_convo_non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_c5ac7e76", -- I don't have any pressing assignments right now, but I do have some elective duty missions if you're interested?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/tatooine_rebel_trainer_1:s_6e646769", "duty_no_thanks"}, -- No, thanks.
		{"@conversation/tatooine_rebel_trainer_1:s_e0cb3e19", "enlist_ground"}, -- I'm ready to enlist with the ground forces!
	}
}
socuna_convo_template:addScreen(socuna_convo_non_member_duty_offer)

socuna_convo_non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_b2c15146", -- Unfortunately, since you are not part of my unit, I cannot assign you missions. You should probably return and speak with your commanding officer.
	stopConversation = "true",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_non_member_no_missions)

socuna_convo_duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_cb60fa8", -- A duty mission is a good way to earn experience. Especially for a pilot looking for training like yourself. Duty missions have no real end. You just finish when you finish, know what I mean? So what do you say?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/tatooine_rebel_trainer_1:s_6e646769", "duty_no_thanks"}, -- No, thanks.
		{"@conversation/tatooine_rebel_trainer_1:s_e0cb3e19", "enlist_ground"}, -- I'm ready to enlist with the ground forces!
	}
}
socuna_convo_template:addScreen(socuna_convo_duty_explained)

socuna_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_bf55aded", -- Great. You can either patrol the Tatooine system looking for Imperials to send to the scrapyard, or you can help escort Alliance transports. What sounds good to you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6a0aba27", "destroy_duty"}, -- I would like to patrol Tatooine space.
		{"@conversation/tatooine_rebel_trainer_1:s_2cb7683a", "escort_duty"}, -- I feel our transports need escort...
	}
}
socuna_convo_template:addScreen(socuna_convo_duty_menu)

socuna_convo_destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_66dc0f99", -- Interesting. Alliance HQ has a number of possible Imperial rally points for you to investigate. These 'duty' missions have been prepared for you to gain some much needed space combat experience. You can return to the ground at any time when you feel that you have learned enough. Good luck!
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_destroy_duty)

socuna_convo_escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_d6e44b20", -- You're right. The Alliance is attempting to move a large number of refugees out of Tatooine space. Protect as many of them as you can. These 'duty' missions have been prepared for you to gain some much needed space combat experience. You can return to the ground at any time when you feel that you have learned enough.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_escort_duty)

socuna_convo_duty_no_thanks = ConvoScreen:new {
	id = "duty_no_thanks",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_1c2f3f24", -- The Force be with you, then...
	stopConversation = "true",
	animation = "bow",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_duty_no_thanks)

socuna_convo_enlist_ground = ConvoScreen:new {
	id = "enlist_ground",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_8da0fa08", -- Are you sure about that, %NU?  We could officially put your name on the roster, but even if you remain Covert, there's always a chance of an Imperial uncovering you.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d01d0154", "duty_would_you_like"}, -- No, never mind.
		{"@conversation/tatooine_rebel_trainer_1:s_831a22ee", "enlist_recruiter"}, -- I know the dangers
	}
}
socuna_convo_template:addScreen(socuna_convo_enlist_ground)

socuna_convo_duty_would_you_like = ConvoScreen:new {
	id = "duty_would_you_like",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_236daee8", -- So would you like a duty?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_rebel_trainer_1:s_4ffd4b9d", "duty_menu"}, -- I am interested in a duty mission.
		{"@conversation/tatooine_rebel_trainer_1:s_6e646769", "duty_no_thanks"}, -- No, thanks.
		{"@conversation/tatooine_rebel_trainer_1:s_e0cb3e19", "enlist_ground"}, -- I'm ready to enlist with the ground forces!
	}
}
socuna_convo_template:addScreen(socuna_convo_duty_would_you_like)

socuna_convo_enlist_recruiter = ConvoScreen:new {
	id = "enlist_recruiter",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_618c3a1c", -- Very well, %NU.  Just find a Rebel Recruiter and tell him you want to join the Rebel Alliance.  He'll sign you up with the ground forces.
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_enlist_recruiter)

socuna_convo_lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_19ec1fce", -- Just how exactly do you expect to be a Rebel Alliance pilot without a ship?  Here.  I'll add these access codes for a small fighter to your datapad.  You ought to upgrade to a better ship pretty soon, though.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_7553991", "lost_ship_blow_up"}, -- Yeah, yeah!
		{"@conversation/tatooine_rebel_trainer_1:s_288ce434", "lost_ship_outstanding"}, -- Ma'am! Thank you, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_a994ca63", "lost_ship_force"}, -- For the Alliance!
	}
}
socuna_convo_template:addScreen(socuna_convo_lost_ship)

socuna_convo_lost_ship_blow_up = ConvoScreen:new {
	id = "lost_ship_blow_up",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_33823c2e", -- Try to keep this one from blowing up, okay?
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_lost_ship_blow_up)

socuna_convo_lost_ship_outstanding = ConvoScreen:new {
	id = "lost_ship_outstanding",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7077f9f7", -- Outstanding!
	stopConversation = "true",
	animation = "applause_excited",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_lost_ship_outstanding)

socuna_convo_lost_ship_force = ConvoScreen:new {
	id = "lost_ship_force",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2d4bb338", -- May the Force be with you.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_lost_ship_force)

socuna_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_e31d65b7", -- The duty logs indicate that you are in mid-mission. We have nothing to discuss until you are finished.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_on_mission)

socuna_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_63642f8", -- It appears that our time together has come to an end, pilot. Alliance HQ wants you reallocated to special operations on Yavin 4 and placed under the command of Major Eker... immediately.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_abc65d0", "eker_respect"}, -- Okay. Bye!
		{"@conversation/tatooine_rebel_trainer_1:s_f843dc6a", "eker_ops"}, -- (Salute) Yes, ma'am!
		{"@conversation/tatooine_rebel_trainer_1:s_d8913d37", "eker_great_things"}, -- If it is my duty, Da'la.
	}
}
socuna_convo_template:addScreen(socuna_convo_tier_done)

socuna_convo_eker_respect = ConvoScreen:new {
	id = "eker_respect",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_7eff4d79", -- Perhaps you will show Major Eker more respect. The Major is currently located at the labor outpost on the moon Yavin 4. Good luck, %NU.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_respect)

socuna_convo_eker_ops = ConvoScreen:new {
	id = "eker_ops",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_f5255b8a", -- Major Eker and his special operations team have a wide-range of responsibilities on Yavin 4. Before you head off, I want you to appreciate just how dangerous this assignment could be.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_8685174d", "eker_good_luck"}, -- I do, ma'am.
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_ops)

socuna_convo_eker_good_luck = ConvoScreen:new {
	id = "eker_good_luck",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2b43e56e", -- Good luck to you, pilot! The Major is currently located at the labor outpost on the moon Yavin 4. Hope to see you again when this war is over...
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_good_luck)

socuna_convo_eker_great_things = ConvoScreen:new {
	id = "eker_great_things",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_95310ec0", -- You have done great things here in Tatooine, %NU... but the Alliance needs you on Yavin. The stakes in this conflict are continuing to rise, and our pilots must go where they are needed. I am sure you will flourish under Major Eker's command.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6f3e992", "eker_who"}, -- What can you tell me of Major Eker?
		{"@conversation/tatooine_rebel_trainer_1:s_fdb94a71", "eker_yavin_op"}, -- What do you know of the Yavin 4 operation?
		{"@conversation/tatooine_rebel_trainer_1:s_cd0ae4c4", "eker_with_you"}, -- The Force be with you, Da'la...
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_great_things)

socuna_convo_eker_who = ConvoScreen:new {
	id = "eker_who",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_cfba4c0a", -- We exchanged messages through the Alliance 'net right after the Battle of Yavin. He was in need of pilots then, too. So, we didn't discuss anything outside of that. Of course, I have heard rumors of his history before joining the Alliance... but nothing concrete.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_d5c41154", "eker_rumors"}, -- What rumors?
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_who)

socuna_convo_eker_rumors = ConvoScreen:new {
	id = "eker_rumors",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_855c7780", -- I've heard that Eker was a decorated Imperial pilot and leader of a vicious TIE squadron for several years... until he sickened of their tactics. I believe he defected after being ordered to fire on an unarmed medical transport.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6f3e992", "eker_who"}, -- What can you tell me of Major Eker?
		{"@conversation/tatooine_rebel_trainer_1:s_fdb94a71", "eker_yavin_op"}, -- What do you know of the Yavin 4 operation?
		{"@conversation/tatooine_rebel_trainer_1:s_cd0ae4c4", "eker_with_you"}, -- The Force be with you, Da'la...
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_rumors)

socuna_convo_eker_yavin_op = ConvoScreen:new {
	id = "eker_yavin_op",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_5f15e36", -- I know only that it involves researching the Death Star space station technology. With so much wreckage in the area, the Alliance has an opportunity to deconstruct the Empire's elite doomsday weapon... and prepare an adequate response if they were to build another one.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_6f3e992", "eker_who"}, -- What can you tell me of Major Eker?
		{"@conversation/tatooine_rebel_trainer_1:s_fdb94a71", "eker_yavin_op"}, -- What do you know of the Yavin 4 operation?
		{"@conversation/tatooine_rebel_trainer_1:s_cd0ae4c4", "eker_with_you"}, -- The Force be with you, Da'la...
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_yavin_op)

socuna_convo_eker_with_you = ConvoScreen:new {
	id = "eker_with_you",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_111cd324", -- And with you as well. The Major is currently located at the labor outpost on the moon Yavin 4. Good luck, %NU. I know you will serve the Alliance well on Yavin 4.
	stopConversation = "true",
	animation = "salute2",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_eker_with_you)

socuna_convo_graduated = ConvoScreen:new {
	id = "graduated",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_2e56f341", -- You're not supposed to be here, pilot. You're assigned to Major Eker's group on Yavin 4.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/tatooine_rebel_trainer_1:s_b3bebc5e", "graduated_how"}, -- How do I get there?
	}
}
socuna_convo_template:addScreen(socuna_convo_graduated)

socuna_convo_graduated_how = ConvoScreen:new {
	id = "graduated_how",
	leftDialog = "@conversation/tatooine_rebel_trainer_1:s_e2a3d627", -- Fly there, Pilot.  Your ship is equipped with a hyperdrive.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
socuna_convo_template:addScreen(socuna_convo_graduated_how)

addConversationTemplate("socuna_convo_template", socuna_convo_template)
