-- Arnecio Ulvaw'op (Crimson Phoenix Squadron tier 3, Dathomir science outpost) conversation; ported from SWG-Source tatooine_rebel_tier3.java with the pre-NGE client lines (feature crimson-phoenix-tier3-ulvawop). Handler: ulvawopConvoHandler.
ulvawop_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "ulvawopConvoHandler",
	screens = {}
}

ulvawop_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d9245236", -- I don't think I know you. I'm certainly not expecting you.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_not_pilot)

ulvawop_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_39d07e54", -- There's nothing for you here. 
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_wrong_faction)

ulvawop_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_30a2d12d", -- I'm afraid I won't be of much use to you. I suggest you find someone else. 
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_off_track)

ulvawop_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c3e376a5", -- %TU!  Explain yourself!  What's this I've heard about you assisting the Empire?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ecb17e60", "grounded_trust"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_grounded)

ulvawop_convo_grounded_trust = ConvoScreen:new {
	id = "grounded_trust",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_861c21de", -- The Rebel Alliance can't trust just ANYONE, you know.  You could be a spy for the Empire... and the reports we've been receiving about you are making me nervous.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_f8b02865", "grounded_standing"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_grounded_trust)

ulvawop_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_1d28ae3", -- Nothing!  Not until you straighten this situation out.  You need to improve your standing with the Rebel Alliance before I can trust you with any more assignments.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_grounded_standing)

ulvawop_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_614f7f1c", -- You haven't been cleared for this level yet.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_not_ready)

ulvawop_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_329414b2", -- Please, do not waste your time talking to me. You are needed elsewhere.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_on_mission)

ulvawop_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_5a66cd79", -- You haven't finished your assignment. Please get back to work.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a68dfaa6", "m1_retry_652ff698"},
		{"@conversation/tatooine_rebel_tier3:s_9401fd7b", "m1_retry_a53ea74c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_failed)

ulvawop_convo_m1_retry_652ff698 = ConvoScreen:new {
	id = "m1_retry_652ff698",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_652ff698", -- Come now. I was born at night, but not LAST night.
	stopConversation = "true",
	animation = "stretch",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_retry_652ff698)

ulvawop_convo_m1_retry_a53ea74c = ConvoScreen:new {
	id = "m1_retry_a53ea74c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_a53ea74c", -- Worthwhile things often are.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_retry_a53ea74c)

ulvawop_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_67c8f113", -- You still have work to do.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d85b3a9c", "m2_retry_59552474"},
		{"@conversation/tatooine_rebel_tier3:s_87d7e908", "m2_retry_3eeaed57"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_failed)

ulvawop_convo_m2_retry_59552474 = ConvoScreen:new {
	id = "m2_retry_59552474",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_59552474", -- Then the Alliance will crumble. You don't want that on your conscience, do you?
	stopConversation = "true",
	animation = "tap_head",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_retry_59552474)

ulvawop_convo_m2_retry_3eeaed57 = ConvoScreen:new {
	id = "m2_retry_3eeaed57",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_3eeaed57", -- I suggest you get to it.
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_retry_3eeaed57)

ulvawop_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c74a6348", -- You must finish what you started.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d454739a", "m3_retry_5973a2b6"},
		{"@conversation/tatooine_rebel_tier3:s_9173548c", "m3_retry_665b67d1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_failed)

ulvawop_convo_m3_retry_5973a2b6 = ConvoScreen:new {
	id = "m3_retry_5973a2b6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_5973a2b6", -- No. NOW.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_retry_5973a2b6)

ulvawop_convo_m3_retry_665b67d1 = ConvoScreen:new {
	id = "m3_retry_665b67d1",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_665b67d1", -- Very good.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_retry_665b67d1)

ulvawop_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_4748286f", -- That pilot's not going to get the better of you, I hope. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_b40f340", "m4_retry_d6643019"},
		{"@conversation/tatooine_rebel_tier3:s_9fb0046e", "m4_retry_9df42b04"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_failed)

ulvawop_convo_m4_retry_d6643019 = ConvoScreen:new {
	id = "m4_retry_d6643019",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d6643019", -- Actions speak louder than words.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_retry_d6643019)

ulvawop_convo_m4_retry_9df42b04 = ConvoScreen:new {
	id = "m4_retry_9df42b04",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_9df42b04", -- So are you. Please return to your ship.
	stopConversation = "true",
	animation = "point_forward",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_retry_9df42b04)

ulvawop_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8bd6bf55", -- Well done. I look forward to meeting that Imperial officer. Let me teach you a skill.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c43eb58", "trained_starships"},
		{"@conversation/tatooine_rebel_tier3:s_9b989e16", "trained_weapons"},
		{"@conversation/tatooine_rebel_tier3:s_3a9f883c", "trained_procedures"},
		{"@conversation/tatooine_rebel_tier3:s_473d09d8", "trained_droid"},
		{"@conversation/tatooine_rebel_tier3:s_337aea88", "on_mission"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_reward)

ulvawop_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_fa6e2383", -- Looks like our information was correct. Thank you for your efforts. Are you ready for a new skill?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c43eb58", "trained_starships"},
		{"@conversation/tatooine_rebel_tier3:s_9b989e16", "trained_weapons"},
		{"@conversation/tatooine_rebel_tier3:s_3a9f883c", "trained_procedures"},
		{"@conversation/tatooine_rebel_tier3:s_473d09d8", "trained_droid"},
		{"@conversation/tatooine_rebel_tier3:s_337aea88", "on_mission"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_reward)

ulvawop_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_f72b6d44", -- Would you like to learn a new skill now?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c43eb58", "trained_starships"},
		{"@conversation/tatooine_rebel_tier3:s_9b989e16", "trained_weapons"},
		{"@conversation/tatooine_rebel_tier3:s_3a9f883c", "trained_procedures"},
		{"@conversation/tatooine_rebel_tier3:s_473d09d8", "trained_droid"},
		{"@conversation/tatooine_rebel_tier3:s_337aea88", "on_mission"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_reward)

ulvawop_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_f9044504", -- There's more I could teach you.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c43eb58", "trained_starships"},
		{"@conversation/tatooine_rebel_tier3:s_9b989e16", "trained_weapons"},
		{"@conversation/tatooine_rebel_tier3:s_3a9f883c", "trained_procedures"},
		{"@conversation/tatooine_rebel_tier3:s_473d09d8", "trained_droid"},
		{"@conversation/tatooine_rebel_tier3:s_337aea88", "on_mission"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_reward)

ulvawop_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_3b851af5", -- I'll teach you what I know. If you want another mission later, ask me.
	stopConversation = "true",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_trained_starships)

ulvawop_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_738d24fd", -- Very well, let's begin. Talk to me again when you are ready for a mission.
	stopConversation = "true",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_trained_weapons)

ulvawop_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_7da64d88", -- Ah, that will be very useful.  Let's begin, and later I'll be ready to give you a mission.
	stopConversation = "true",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_trained_procedures)

ulvawop_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_aa4f6738", -- I can and I will. Find me later, when you are ready for another mission.
	stopConversation = "true",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_trained_droid)

ulvawop_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_6f921f12", -- Welcome, %TU. You look different than I expected from your picture.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_783af10a", "m1_be9caae0"},
		{"@conversation/tatooine_rebel_tier3:s_5b000af8", "m1_64170652"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_offer)

ulvawop_convo_m1_be9caae0 = ConvoScreen:new {
	id = "m1_be9caae0",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_be9caae0", -- The Rebellion sent me your dossier.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_b9f4f973", "m1_e95511fe"},
		{"@conversation/tatooine_rebel_tier3:s_81682525", "m1_645464dc"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_be9caae0)

ulvawop_convo_m1_64170652 = ConvoScreen:new {
	id = "m1_64170652",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_64170652", -- Your hair. You've changed it.
	stopConversation = "false",
	animation = "hair_flip",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d2d48b62", "m1_1fd170b2"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_64170652)

ulvawop_convo_m1_e95511fe = ConvoScreen:new {
	id = "m1_e95511fe",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_e95511fe", -- Of course they are. 
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_79209e7", "m1_c93b6a54"},
		{"@conversation/tatooine_rebel_tier3:s_1106a07b", "m1_8539c0c6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_e95511fe)

ulvawop_convo_m1_645464dc = ConvoScreen:new {
	id = "m1_645464dc",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_645464dc", -- What you'd expect. Tell me, have you been here before?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d70dba34", "m1_b136da95"},
		{"@conversation/tatooine_rebel_tier3:s_4c695dbd", "m1_d2f7d204"},
		{"@conversation/tatooine_rebel_tier3:s_11a59fbe", "m1_4d7b2f02"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_645464dc)

ulvawop_convo_m1_c93b6a54 = ConvoScreen:new {
	id = "m1_c93b6a54",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c93b6a54", -- That won't be necessary. 
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_8e632a96", "m1_94ece311"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_c93b6a54)

ulvawop_convo_m1_8539c0c6 = ConvoScreen:new {
	id = "m1_8539c0c6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8539c0c6", -- Absolutely. Thanks to you, we now have Imperial spies in our custody. They've provided us with extremely useful information. 
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_53de9d8f", "m1_81d92cad"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_8539c0c6)

ulvawop_convo_m1_94ece311 = ConvoScreen:new {
	id = "m1_94ece311",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_94ece311", -- I think that's my line. And besides, you should know better than most people how important security is these days.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_75913251", "m1_58159522"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_94ece311)

ulvawop_convo_m1_58159522 = ConvoScreen:new {
	id = "m1_58159522",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_58159522", -- Of course. Congratulations on catching them. Very nice work up there, but I'm also referring to Eker.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_77e48d5b", "m1_4d74f4db"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_58159522)

ulvawop_convo_m1_4d74f4db = ConvoScreen:new {
	id = "m1_4d74f4db",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_4d74f4db", -- He once fought for the Empire. And now he fights for us. People do change allegiances, you see. We must always keep a close eye on our people. And that includes you.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_7f0ba495", "m1_d1ec36f0"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_4d74f4db)

ulvawop_convo_m1_d1ec36f0 = ConvoScreen:new {
	id = "m1_d1ec36f0",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d1ec36f0", -- Very good. We have been tracking the movements of an Imperial Security Officer. He has information we need. The time has come to capture him.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m1_189648be"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_d1ec36f0)

ulvawop_convo_m1_189648be = ConvoScreen:new {
	id = "m1_189648be",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_189648be", -- At the moment, he is in Dathomir space on a Lambda shuttle, en route between the planet and an Imperial fleet... with an Imperial escort.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_6a45ad00", "m1_459dafe4"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_189648be)

ulvawop_convo_m1_459dafe4 = ConvoScreen:new {
	id = "m1_459dafe4",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_459dafe4", -- He's on board a Lambda shuttle. Do you know what that is?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d70dba34", "m1_13faa821"},
		{"@conversation/tatooine_rebel_tier3:s_4103a0b8", "m1_374e94fe"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_459dafe4)

ulvawop_convo_m1_13faa821 = ConvoScreen:new {
	id = "m1_13faa821",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_13faa821", -- He's also flying with an elite escort.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_1bd3a505", "m1_c4bc453f"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_13faa821)

ulvawop_convo_m1_374e94fe = ConvoScreen:new {
	id = "m1_374e94fe",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_374e94fe", -- It's a type of shuttle reserved for only the most important Empire personnel. It's heavily armed.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_61657d0f", "m1_13faa821"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_374e94fe)

ulvawop_convo_m1_c4bc453f = ConvoScreen:new {
	id = "m1_c4bc453f",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c4bc453f", -- Indeed. We've equipped your ship with a space assault droid. Disable his ship and shoot that droid onto its hull. The droid will breach the ship, subdue the crew and take control of the ship. Then we'll see what we've got.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_25e98647", "m1_accept_d5bf212f"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_c4bc453f)

ulvawop_convo_m1_accept_d5bf212f = ConvoScreen:new {
	id = "m1_accept_d5bf212f",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d5bf212f", -- The coordinates are in your database. Go now.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_accept_d5bf212f)

ulvawop_convo_m1_81d92cad = ConvoScreen:new {
	id = "m1_81d92cad",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_81d92cad", -- Ah. That would be telling.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c6594c52", "m1_47da17a9"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_81d92cad)

ulvawop_convo_m1_47da17a9 = ConvoScreen:new {
	id = "m1_47da17a9",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_47da17a9", -- Not at all. Forgive me. 
	stopConversation = "false",
	animation = "accept_affection",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_5c8eeafa", "m1_7b907498"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_47da17a9)

ulvawop_convo_m1_7b907498 = ConvoScreen:new {
	id = "m1_7b907498",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_7b907498", -- We have been tracking the movements of an Imperial Security Officer. He has information we need. The time has come to capture him.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m1_189648be"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_7b907498)

ulvawop_convo_m1_b136da95 = ConvoScreen:new {
	id = "m1_b136da95",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b136da95", -- Then you know about the prison here. This planet is a backwater, a worthless hunk of rock. Yet for some reason, the Empire has taken an unusual interest in the area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4bbc7af6", "m1_58cd53b6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_b136da95)

ulvawop_convo_m1_d2f7d204 = ConvoScreen:new {
	id = "m1_d2f7d204",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d2f7d204", -- This is a prison planet. Worthless. And yet for some reason, the Empire has taken a keen interest in the area.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_2787404a", "m1_8fbd3f85"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_d2f7d204)

ulvawop_convo_m1_4d7b2f02 = ConvoScreen:new {
	id = "m1_4d7b2f02",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_4d7b2f02", -- Do you have something to hide?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4c695dbd", "m1_137f3e6f"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_4d7b2f02)

ulvawop_convo_m1_58cd53b6 = ConvoScreen:new {
	id = "m1_58cd53b6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_58cd53b6", -- I don't know. But I'd like to find out. And there's an Imperial Security Officer who may have the information we need. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3899c4e1", "m1_c9ba6bc2"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_58cd53b6)

ulvawop_convo_m1_c9ba6bc2 = ConvoScreen:new {
	id = "m1_c9ba6bc2",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c9ba6bc2", -- Of course. 
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m1_189648be"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_c9ba6bc2)

ulvawop_convo_m1_8fbd3f85 = ConvoScreen:new {
	id = "m1_8fbd3f85",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8fbd3f85", -- I don't think it's the prison that interests them.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3059f369", "m1_b3f5831e"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_8fbd3f85)

ulvawop_convo_m1_b3f5831e = ConvoScreen:new {
	id = "m1_b3f5831e",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b3f5831e", -- Ah, we do not know each other yet. Even if I knew, I would not tell you.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_82f0aea5", "m1_12e4e81a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_b3f5831e)

ulvawop_convo_m1_12e4e81a = ConvoScreen:new {
	id = "m1_12e4e81a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_12e4e81a", -- Do not take it personally.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_5bd69df6", "m1_86fe6fa2"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_12e4e81a)

ulvawop_convo_m1_86fe6fa2 = ConvoScreen:new {
	id = "m1_86fe6fa2",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_86fe6fa2", -- There is an Imperial Security Officer in the area. He may be carrying useful information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m1_189648be"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_86fe6fa2)

ulvawop_convo_m1_137f3e6f = ConvoScreen:new {
	id = "m1_137f3e6f",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_137f3e6f", -- Then there is nothing in your dossier of interest to you.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_59cd5207", "m1_ca2ba04f"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_137f3e6f)

ulvawop_convo_m1_ca2ba04f = ConvoScreen:new {
	id = "m1_ca2ba04f",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_ca2ba04f", -- Speaking of Imperials, you did a very nice job out there with the Corellian Corvette. Thanks to you, we now have several Imperial spies in our custody. They are founts of information.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_b0da26cf", "m1_ab085367"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_ca2ba04f)

ulvawop_convo_m1_ab085367 = ConvoScreen:new {
	id = "m1_ab085367",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_ab085367", -- Those spies would have been no use to us dead. But you brought them back alive. Very useful. And that's why I've chosen you for this next mission.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_e6631bf8", "m1_341568b3"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_ab085367)

ulvawop_convo_m1_1fd170b2 = ConvoScreen:new {
	id = "m1_1fd170b2",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_1fd170b2", -- It's a must, for my job.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_90875aed", "m1_ec44bbf0"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_1fd170b2)

ulvawop_convo_m1_ec44bbf0 = ConvoScreen:new {
	id = "m1_ec44bbf0",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_ec44bbf0", -- We are interested in an Imperial Security Officer. He has information we need.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_d6963a70", "m1_ff8b2372"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_ec44bbf0)

ulvawop_convo_m1_ff8b2372 = ConvoScreen:new {
	id = "m1_ff8b2372",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_ff8b2372", -- Correct. They are fiercely guarding something there. Do you know anything about it?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3269c6d", "m1_8a88463d"},
		{"@conversation/tatooine_rebel_tier3:s_8cfb34cb", "m1_a41a2281"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_ff8b2372)

ulvawop_convo_m1_8a88463d = ConvoScreen:new {
	id = "m1_8a88463d",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8a88463d", -- Please keep your ears open, %TU - and tell me everything you learn. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_e6631bf8", "m1_341568b3"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_8a88463d)

ulvawop_convo_m1_a41a2281 = ConvoScreen:new {
	id = "m1_a41a2281",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_a41a2281", -- Hm. Rumors. Interesting. I wonder what people are saying.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_2700bc9b", "m1_55eef619"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_a41a2281)

ulvawop_convo_m1_341568b3 = ConvoScreen:new {
	id = "m1_341568b3",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_341568b3", -- There is an Imperial security officer in the area. He has information we need.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m1_189648be"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_341568b3)

ulvawop_convo_m1_55eef619 = ConvoScreen:new {
	id = "m1_55eef619",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_55eef619", -- Of course. Now let's get down to business.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_89dfa4de", "m1_341568b3"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m1_55eef619)

ulvawop_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_1061c440", -- Your reputation is well deserved.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4dbdf08", "m2_d057d7d3"},
		{"@conversation/tatooine_rebel_tier3:s_de2df0e3", "m2_8b898446"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_offer)

ulvawop_convo_m2_d057d7d3 = ConvoScreen:new {
	id = "m2_d057d7d3",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d057d7d3", -- That is the price of success. 
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_bf9961a9", "m2_1a40c7ec"},
		{"@conversation/tatooine_rebel_tier3:s_a9bcadc0", "m2_aeb6556c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_d057d7d3)

ulvawop_convo_m2_8b898446 = ConvoScreen:new {
	id = "m2_8b898446",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8b898446", -- Tell me, why do you fight with the Rebellion?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_821fd0ab", "m2_2cc79657"},
		{"@conversation/tatooine_rebel_tier3:s_895be92b", "m2_3949fe14"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_8b898446)

ulvawop_convo_m2_1a40c7ec = ConvoScreen:new {
	id = "m2_1a40c7ec",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_1a40c7ec", -- Of course. This is a bit of a change for you. You won't be chasing after Imperials this time.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_7a9322d", "m2_3d2253c6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_1a40c7ec)

ulvawop_convo_m2_aeb6556c = ConvoScreen:new {
	id = "m2_aeb6556c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_aeb6556c", -- You would be tremendously bored by it, I think.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_43647dca", "m2_41a00423"},
		{"@conversation/tatooine_rebel_tier3:s_d3e5c0aa", "m2_887fc0e9"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_aeb6556c)

ulvawop_convo_m2_3d2253c6 = ConvoScreen:new {
	id = "m2_3d2253c6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_3d2253c6", -- Shame. You're very good at it. We now have the spies and an Imperial Security Officer, thanks to you. They continue to provide us with information. (It's against their will, but still.) The Empire's plans are even more sinister than we imagined.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_53de9d8f", "m2_b7d2e561"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_3d2253c6)

ulvawop_convo_m2_b7d2e561 = ConvoScreen:new {
	id = "m2_b7d2e561",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b7d2e561", -- The information is frightening, but not specific. And for all we know, they're giving us disinformation. It will take us a while before we can be sure they are telling us the truth.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_fd8741c0", "m2_fffe6e23"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_b7d2e561)

ulvawop_convo_m2_fffe6e23 = ConvoScreen:new {
	id = "m2_fffe6e23",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_fffe6e23", -- You will be.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_15e6c3e4", "m2_69f60e66"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_fffe6e23)

ulvawop_convo_m2_69f60e66 = ConvoScreen:new {
	id = "m2_69f60e66",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_69f60e66", -- It relates to your recent attacks against those Imperial ships. You were effective - perhaps too effective.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_315ecc88"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_69f60e66)

ulvawop_convo_m2_315ecc88 = ConvoScreen:new {
	id = "m2_315ecc88",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_315ecc88", -- We believe the Empire plans to return the favor, and launch attacks against OUR ships.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_26c0af06", "m2_c2efe3eb"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_315ecc88)

ulvawop_convo_m2_c2efe3eb = ConvoScreen:new {
	id = "m2_c2efe3eb",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c2efe3eb", -- They're not just going to walk through the front door, either. I expect they'll try something more devious. According to our intel, they may try to smuggle explosives into this system on Rebel ships.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_b84b366c", "m2_a8e0243a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_c2efe3eb)

ulvawop_convo_m2_a8e0243a = ConvoScreen:new {
	id = "m2_a8e0243a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_a8e0243a", -- All Rebel ships are now subject to inspection. And YOU will inspect them.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_658f174d", "m2_843eff43"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_a8e0243a)

ulvawop_convo_m2_843eff43 = ConvoScreen:new {
	id = "m2_843eff43",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_843eff43", -- Bomb-making material, Imperial comlinks, schematics, anything suspicious.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ca8f5dda", "m2_accept_b1479cf9"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_843eff43)

ulvawop_convo_m2_accept_b1479cf9 = ConvoScreen:new {
	id = "m2_accept_b1479cf9",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b1479cf9", -- Now would be a good time.
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_accept_b1479cf9)

ulvawop_convo_m2_41a00423 = ConvoScreen:new {
	id = "m2_41a00423",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_41a00423", -- How did you like using that space assault droid?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4ffa3018", "m2_e19c193f"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_41a00423)

ulvawop_convo_m2_887fc0e9 = ConvoScreen:new {
	id = "m2_887fc0e9",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_887fc0e9", -- The battles have been going our way. We have captured an Imperial Security Officer, thanks to you, and your attacks against those Imperial ships was effective - perhaps too effective.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_db14e2c1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_887fc0e9)

ulvawop_convo_m2_e19c193f = ConvoScreen:new {
	id = "m2_e19c193f",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_e19c193f", -- That Imperial Security Officer has provided us with a tremendous amount of information. With it, we can launch attacks that will decimate the Imperial fleet's infrastructure.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_2f6ac50d", "m2_b3ae7d2"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_e19c193f)

ulvawop_convo_m2_b3ae7d2 = ConvoScreen:new {
	id = "m2_b3ae7d2",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b3ae7d2", -- Yes. Well, that brings me to my next mission. The Empire knows that we have this information, and I am sure they are planning attacks as we speak, to kill us before we can take action.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_52d4385d", "m2_cd86689a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_b3ae7d2)

ulvawop_convo_m2_cd86689a = ConvoScreen:new {
	id = "m2_cd86689a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_cd86689a", -- They're not going to walk through the front door and announce themselves, that's for sure. According to our intel, they're going to try and smuggle explosives into this system using Rebel ships.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a30c8590", "m2_c65b834a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_cd86689a)

ulvawop_convo_m2_c65b834a = ConvoScreen:new {
	id = "m2_c65b834a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c65b834a", -- Exactly. But we are going to start inspecting them, starting immediately. And YOU will inspect them.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_658f174d", "m2_e3d61563"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_c65b834a)

ulvawop_convo_m2_db14e2c1 = ConvoScreen:new {
	id = "m2_db14e2c1",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_db14e2c1", -- We believe the Empire plans to return the favor.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_52d4385d", "m2_cd86689a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_db14e2c1)

ulvawop_convo_m2_2cc79657 = ConvoScreen:new {
	id = "m2_2cc79657",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_2cc79657", -- What would you do to stop the Empire?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_527fe7c", "m2_4df738bb"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_2cc79657)

ulvawop_convo_m2_3949fe14 = ConvoScreen:new {
	id = "m2_3949fe14",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_3949fe14", -- Some people think the Empire will bring order to the galaxy.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_37402596", "m2_9c7613eb"},
		{"@conversation/tatooine_rebel_tier3:s_e68c0bb8", "m2_825313cf"},
		{"@conversation/tatooine_rebel_tier3:s_129bdf42", "m2_f9f2fe5c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_3949fe14)

ulvawop_convo_m2_4df738bb = ConvoScreen:new {
	id = "m2_4df738bb",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_4df738bb", -- Anything?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_151b3d1", "m2_6b4f10db"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_4df738bb)

ulvawop_convo_m2_6b4f10db = ConvoScreen:new {
	id = "m2_6b4f10db",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_6b4f10db", -- Hm. Interesting. You've been very helpful so far. You've brought us the Imperial Security Officer, and you've launched a devastating wave of attacks against Imperial forces. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_5f46c092", "m2_d762182e"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_6b4f10db)

ulvawop_convo_m2_d762182e = ConvoScreen:new {
	id = "m2_d762182e",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d762182e", -- The Empire's good too. And they want to put a stop to our activities, immediately if not sooner.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3dc14ee3", "m2_8a4015bb"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_d762182e)

ulvawop_convo_m2_8a4015bb = ConvoScreen:new {
	id = "m2_8a4015bb",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8a4015bb", -- As a matter of fact, yes - thanks to that Security Officer. We believe the Empire plans to return the favor, and launch attacks against OUR ships.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_26c0af06", "m2_c2efe3eb"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_8a4015bb)

ulvawop_convo_m2_9c7613eb = ConvoScreen:new {
	id = "m2_9c7613eb",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_9c7613eb", -- Perhaps. 
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_51a30f3e", "m2_d9a23c21"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_9c7613eb)

ulvawop_convo_m2_825313cf = ConvoScreen:new {
	id = "m2_825313cf",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_825313cf", -- Do you think the Emperor is an idiot?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_be155900", "m2_d258e826"},
		{"@conversation/tatooine_rebel_tier3:s_c2051287", "m2_35b12d6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_825313cf)

ulvawop_convo_m2_f9f2fe5c = ConvoScreen:new {
	id = "m2_f9f2fe5c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_f9f2fe5c", -- I like to know who I'm dealing with.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ec3a4b5b", "m2_188d0288"},
		{"@conversation/tatooine_rebel_tier3:s_18b63392", "m2_d9a23c21"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_f9f2fe5c)

ulvawop_convo_m2_d258e826 = ConvoScreen:new {
	id = "m2_d258e826",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d258e826", -- Do not underestimate your enemies. They are as dedicated to their cause as you are to yours.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a9cddbcc", "m2_dfcc11ba"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_d258e826)

ulvawop_convo_m2_35b12d6 = ConvoScreen:new {
	id = "m2_35b12d6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_35b12d6", -- Just a habit. Your attack on those Imperial ships was effective - perhaps too effective.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_db14e2c1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_35b12d6)

ulvawop_convo_m2_dfcc11ba = ConvoScreen:new {
	id = "m2_dfcc11ba",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_dfcc11ba", -- Yes, about that assault. It was effective - perhaps too effective.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_db14e2c1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_dfcc11ba)

ulvawop_convo_m2_e3d61563 = ConvoScreen:new {
	id = "m2_e3d61563",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_e3d61563", -- Bomb-making material, Imperial comlinks, schematics - anything suspicious.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ca8f5dda", "m2_accept_b1479cf9"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_e3d61563)

ulvawop_convo_m2_188d0288 = ConvoScreen:new {
	id = "m2_188d0288",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_188d0288", -- Then I have a job for you. Your attack on those Imperial ships was effective - perhaps too effective.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_db14e2c1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_188d0288)

ulvawop_convo_m2_d9a23c21 = ConvoScreen:new {
	id = "m2_d9a23c21",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d9a23c21", -- Your attack on those Imperial ships was effective - perhaps too effective.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c4f6eef8", "m2_db14e2c1"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m2_d9a23c21)

ulvawop_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_5852ee6b", -- The intel was correct.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ed4e5e50", "m3_f9e6ef1b"},
		{"@conversation/tatooine_rebel_tier3:s_ab1cce5f", "m3_83b7fee0"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_offer)

ulvawop_convo_m3_f9e6ef1b = ConvoScreen:new {
	id = "m3_f9e6ef1b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_f9e6ef1b", -- I do. There's a prisoner on Dathomir we wish to meet.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_841d27db", "m3_db5f856c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_f9e6ef1b)

ulvawop_convo_m3_83b7fee0 = ConvoScreen:new {
	id = "m3_83b7fee0",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_83b7fee0", -- Absolutely. And after that attack, we can be sure they're watching us closely. We've GOT to find out what the Empire is planning. Tell me %NU, do you know many people in this system?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_2f463615", "m3_d31b92f9"},
		{"@conversation/tatooine_rebel_tier3:s_3269c6d", "m3_27bc6d70"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_83b7fee0)

ulvawop_convo_m3_db5f856c = ConvoScreen:new {
	id = "m3_db5f856c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_db5f856c", -- He's an Imperial defector. We plan to engineer an outbreak.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a0e63032", "m3_58999327"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_db5f856c)

ulvawop_convo_m3_58999327 = ConvoScreen:new {
	id = "m3_58999327",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_58999327", -- Yes - from the outside, in. But we have access to a former prisoner. He will help us.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_412e0683", "m3_accept_94a2001c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_58999327)

ulvawop_convo_m3_accept_94a2001c = ConvoScreen:new {
	id = "m3_accept_94a2001c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_94a2001c", -- He's a smuggler who works with Nym. You can find him in Lok. Meet with him there and bring his information back to the Rebel Commando team in the Dathomir system.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_accept_94a2001c)

ulvawop_convo_m3_d31b92f9 = ConvoScreen:new {
	id = "m3_d31b92f9",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d31b92f9", -- Perhaps you could introduce me to your friends. I am always interested in meeting new people.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_710aa637", "m3_fab55d44"},
		{"@conversation/tatooine_rebel_tier3:s_8b436d82", "m3_c7aa6bdb"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_d31b92f9)

ulvawop_convo_m3_27bc6d70 = ConvoScreen:new {
	id = "m3_27bc6d70",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_27bc6d70", -- I'd like to introduce you to someone. He's a smuggler. He works with Nym.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a8af09fc", "m3_be88a7d6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_27bc6d70)

ulvawop_convo_m3_fab55d44 = ConvoScreen:new {
	id = "m3_fab55d44",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_fab55d44", -- I know a smuggler. He works with Nym. And now he's going to work with you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c265503e", "m3_9f86f530"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_fab55d44)

ulvawop_convo_m3_c7aa6bdb = ConvoScreen:new {
	id = "m3_c7aa6bdb",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c7aa6bdb", -- The Bothan reputation precedes me.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_ff50cabc", "m3_b4a1239c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_c7aa6bdb)

ulvawop_convo_m3_9f86f530 = ConvoScreen:new {
	id = "m3_9f86f530",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_9f86f530", -- There is an Imperial defector in the Dathomir prison. We want to free him and find out what he knows. This smuggler I mentioned, he has been to the prison, he knows the layout.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_f6cd86be", "m3_b2aeeeda"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_9f86f530)

ulvawop_convo_m3_b2aeeeda = ConvoScreen:new {
	id = "m3_b2aeeeda",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b2aeeeda", -- He's a pirate. Everything he does is illegal.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_42a9f4a3", "m3_2914d34b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_b2aeeeda)

ulvawop_convo_m3_2914d34b = ConvoScreen:new {
	id = "m3_2914d34b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_2914d34b", -- Trust isn't necessary. You can still work together. After all, we work together, and I don't think you trust me.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_82f0aea5", "m3_accept_573af66b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_2914d34b)

ulvawop_convo_m3_accept_573af66b = ConvoScreen:new {
	id = "m3_accept_573af66b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_573af66b", -- So there you go. Travel to Lok, meet up with the smuggler, and bring his information to the Rebel Commando team in the Dathomir system.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_accept_573af66b)

ulvawop_convo_m3_b4a1239c = ConvoScreen:new {
	id = "m3_b4a1239c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b4a1239c", -- Ugly word. I prefer 'information broker.'
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_c2850e6", "m3_966a1e03"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_b4a1239c)

ulvawop_convo_m3_966a1e03 = ConvoScreen:new {
	id = "m3_966a1e03",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_966a1e03", -- Information is more valuable than gold in wartime. And remember, I'm working for you.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_fa38c858", "m3_b6da869b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_966a1e03)

ulvawop_convo_m3_b6da869b = ConvoScreen:new {
	id = "m3_b6da869b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_b6da869b", -- We are both serving the Rebellion. 
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_e5235eff", "m3_eb3726f6"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_b6da869b)

ulvawop_convo_m3_eb3726f6 = ConvoScreen:new {
	id = "m3_eb3726f6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_eb3726f6", -- Yes. You're going to help me get information - from an Imperial defector.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_52819991", "m3_24d21bf3"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_eb3726f6)

ulvawop_convo_m3_24d21bf3 = ConvoScreen:new {
	id = "m3_24d21bf3",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_24d21bf3", -- As do I. There's only one problem - he's in a Dathomir prison. As long as he's there, we don't know what he knows.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_129732ea", "m3_3414728a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_24d21bf3)

ulvawop_convo_m3_3414728a = ConvoScreen:new {
	id = "m3_3414728a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_3414728a", -- Only with our help. I want you to go to Lok and meet with one of Nym's smugglers.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a8af09fc", "m3_accept_89962192"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_3414728a)

ulvawop_convo_m3_accept_89962192 = ConvoScreen:new {
	id = "m3_accept_89962192",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_89962192", -- He's been to the Dathomir prison. He can help us plan an escape. Get his information and deliver it to the Rebel Commando team in the Dathomir system.
	stopConversation = "true",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_accept_89962192)

ulvawop_convo_m3_be88a7d6 = ConvoScreen:new {
	id = "m3_be88a7d6",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_be88a7d6", -- Because he's been to prison.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_114c29a9", "m3_e3c318b4"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_be88a7d6)

ulvawop_convo_m3_e3c318b4 = ConvoScreen:new {
	id = "m3_e3c318b4",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_e3c318b4", -- Specifically the Dathomir prison.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_b7138aed", "m3_e24417b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_e3c318b4)

ulvawop_convo_m3_e24417b = ConvoScreen:new {
	id = "m3_e24417b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_e24417b", -- He will help us to plan an attack on Dathomir prison.  
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_2bc4bdb7", "m3_c599f19a"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_e24417b)

ulvawop_convo_m3_c599f19a = ConvoScreen:new {
	id = "m3_c599f19a",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_c599f19a", -- There's a prisoner there, an Imperial defector. He will be helpful to us - once he's free.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_9e4da02c", "m3_accept_404b8a10"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_c599f19a)

ulvawop_convo_m3_accept_404b8a10 = ConvoScreen:new {
	id = "m3_accept_404b8a10",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_404b8a10", -- Yes. But first we need a plan. Go to Lok, meet with the smuggler, and deliver his information to the Rebel Commando team in the Dathomir system. 
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m3_accept_404b8a10)

ulvawop_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_5bd53e0a", -- We meet again.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a91e3c6b", "m4_4ffe2e0d"},
		{"@conversation/tatooine_rebel_tier3:s_e5235eff", "m4_8bf6086e"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_offer)

ulvawop_convo_m4_4ffe2e0d = ConvoScreen:new {
	id = "m4_4ffe2e0d",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_4ffe2e0d", -- I did. Do you think you can hold your own against an Imperial pilot?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_628181f3", "m4_5e8b8f88"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_4ffe2e0d)

ulvawop_convo_m4_8bf6086e = ConvoScreen:new {
	id = "m4_8bf6086e",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_8bf6086e", -- We've had a run of good luck. A hard blow against the Empire now would destroy morale.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4ece8e4c", "m4_ae11747c"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_8bf6086e)

ulvawop_convo_m4_5e8b8f88 = ConvoScreen:new {
	id = "m4_5e8b8f88",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_5e8b8f88", -- He's one of the best. In fact, the Emperor himself is going to award him with their highest medal.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4291c3cf", "m4_23c7ed04"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_5e8b8f88)

ulvawop_convo_m4_23c7ed04 = ConvoScreen:new {
	id = "m4_23c7ed04",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_23c7ed04", -- He's killed more Rebel pilots that any other soldier.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_76340c2f", "m4_dc95008b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_23c7ed04)

ulvawop_convo_m4_dc95008b = ConvoScreen:new {
	id = "m4_dc95008b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_dc95008b", -- We'll soon find out which one of you is the best. I want you to go after him.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_3aa053cf", "m4_accept_7b3fb40b"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_dc95008b)

ulvawop_convo_m4_accept_7b3fb40b = ConvoScreen:new {
	id = "m4_accept_7b3fb40b",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_7b3fb40b", -- He's in the Endor system, en route to the medal ceremony. Make sure he doesn't get there.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_accept_7b3fb40b)

ulvawop_convo_m4_ae11747c = ConvoScreen:new {
	id = "m4_ae11747c",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_ae11747c", -- Leave that to me. Are you ready for a dogfight?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_90377ed4", "m4_d35a8803"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_ae11747c)

ulvawop_convo_m4_d35a8803 = ConvoScreen:new {
	id = "m4_d35a8803",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d35a8803", -- One of the Empire's best pilots is en route to a medal ceremony. He is the hope of the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_4291c3cf", "m4_92bcea"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_d35a8803)

ulvawop_convo_m4_92bcea = ConvoScreen:new {
	id = "m4_92bcea",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_92bcea", -- You're going to find out. I want you to track him down. Make sure he never gets that medal.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_25e98647", "m4_accept_2493aca3"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_92bcea)

ulvawop_convo_m4_accept_2493aca3 = ConvoScreen:new {
	id = "m4_accept_2493aca3",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_2493aca3", -- He's in the Endor system, en route to Dathomir. You're clear to leave anytime.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_m4_accept_2493aca3)

ulvawop_convo_handoff = ConvoScreen:new {
	id = "handoff",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_fb871ded", -- Central Command has issued new orders for you.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_a927c891", "handoff_rori"},
		{"@conversation/tatooine_rebel_tier3:s_554b78dd", "handoff_spy"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_handoff)

ulvawop_convo_handoff_rori = ConvoScreen:new {
	id = "handoff_rori",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_d72cbbfa", -- You are now assigned to the Rebel outpost on Rori. You'll be reporting to General Ufwol.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_eba35f17", "handoff_leave"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_handoff_rori)

ulvawop_convo_handoff_leave = ConvoScreen:new {
	id = "handoff_leave",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_db13b2d9", -- Immediately. Thank you again for all your hard work. And remember: watch your back.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_handoff_leave)

ulvawop_convo_handoff_spy = ConvoScreen:new {
	id = "handoff_spy",
	leftDialog = "@conversation/tatooine_rebel_tier3:s_9c91459e", -- You should always keep your eyes and ears open.  But as of now, you're stationed at a Rebel outpost on the planet Rori. You'll report to General Ufwol.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_rebel_tier3:s_eba35f17", "handoff_leave"}
	}
}
ulvawop_convo_template:addScreen(ulvawop_convo_handoff_spy)

addConversationTemplate("ulvawop_convo_template", ulvawop_convo_template)
