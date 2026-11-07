-- Kiizete (Vortex Squadron tier 1 side NPC, Moenia gazebo); ported from SWG-Source naboo_rebel_tier1_kiizete.java with the pre-NGE client lines (feature vortex-tier1-kiizete)
kiizete_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "kiizeteConvoHandler",
	screens = {}
}

kiizete_convo_no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_933941d0", -- This droid is going to be the death of me! I'm sorry... I'm getting nowhere with this thing and I really need to get back home.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_ee55c9ed", "no_jtl_home"}, -- Where's home?
		{"@conversation/naboo_rebel_tier1_kiizete:s_7fa15433", "no_jtl_droid_memory"}, -- What's wrong with it?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_no_jtl)

kiizete_convo_no_jtl_home = ConvoScreen:new {
	id = "no_jtl_home",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_bc76e9cc", -- Dee'ja. My starship is grounded for the moment. I'm fulfilling a contract for the Empire right now. Got to get this droid's memory wiped and rebuilt.
	stopConversation = "false",
	animation = "point_right",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_8668104f", "no_jtl_starship"}, -- Your starship?
		{"@conversation/naboo_rebel_tier1_kiizete:s_6d949f10", "no_jtl_contract"}, -- A contract?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_no_jtl_home)

kiizete_convo_no_jtl_starship = ConvoScreen:new {
	id = "no_jtl_starship",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_6472f6c1", -- Yeah. I really miss flying! I can't wait to get my ship repaired.
	stopConversation = "true",
	animation = "slump_head",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_no_jtl_starship)

kiizete_convo_no_jtl_contract = ConvoScreen:new {
	id = "no_jtl_contract",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_88b50e", -- Yeah... sure... a contract.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_no_jtl_contract)

kiizete_convo_no_jtl_droid_memory = ConvoScreen:new {
	id = "no_jtl_droid_memory",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_46b93374", -- Its memory is defunct. Got an old pilot program in it. I gotta remove it... but it's proving to be difficult.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_no_jtl_droid_memory)

kiizete_convo_imperial_again = ConvoScreen:new {
	id = "imperial_again",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_7a0420ae", -- I'm serious. I don't have time for you right now!
	stopConversation = "true",
	animation = "stop",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imperial_again)

kiizete_convo_imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_bdc96417", -- Sorry. I really don't have time to talk right now. I've been trying to get this droid reprogrammed all day. It's turning out to be a nightmare!
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_9ddf5e8a", "imp_why_reprogram"}, -- Why reprogram it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_7fa15433", "imp_whats_wrong"}, -- What's wrong with it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_5e15545", "imp_your_job"}, -- Is this your job?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imperial_pilot)

kiizete_convo_imp_why_reprogram = ConvoScreen:new {
	id = "imp_why_reprogram",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_dd3ba522", -- Order of the Empire! What can you do? I just grabbed the contract from a terminal up in Dee'ja Peak.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_9ddf5e8a", "imp_why_reprogram"}, -- Why reprogram it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_7fa15433", "imp_whats_wrong"}, -- What's wrong with it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_5e15545", "imp_your_job"}, -- Is this your job?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imp_why_reprogram)

kiizete_convo_imp_whats_wrong = ConvoScreen:new {
	id = "imp_whats_wrong",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_8379d6bb", -- It's got this old pilot trainer program burned into it. Empire wants it out of there. It's not going to be easy, though. Moisture from the pond has gummed up this droid's circuitry. I'm going to have to replace a lot of parts!
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_9ddf5e8a", "imp_why_reprogram"}, -- Why reprogram it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_7fa15433", "imp_whats_wrong"}, -- What's wrong with it?
		{"@conversation/naboo_rebel_tier1_kiizete:s_5e15545", "imp_your_job"}, -- Is this your job?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imp_whats_wrong)

kiizete_convo_imp_your_job = ConvoScreen:new {
	id = "imp_your_job",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_489ec48f", -- Sort of. I normally work a shift on the Kai'rek mining ship... but I got tagged by pirates on my first day of shore leave. I figure I'll need to run a few more contracts here on Naboo before I can afford to pay for repairs.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_fdbd2351", "imp_what_fly"}, -- What do you fly?
		{"@conversation/naboo_rebel_tier1_kiizete:s_dff67cdc", "imp_mining_ship"}, -- You erase droids on a mining ship?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imp_your_job)

kiizete_convo_imp_what_fly = ConvoScreen:new {
	id = "imp_what_fly",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_af558512", -- A '95. Hand-me-down. Look, I really need to get back to work...
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imp_what_fly)

kiizete_convo_imp_mining_ship = ConvoScreen:new {
	id = "imp_mining_ship",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_8dee77bb", -- I do odd jobs, okay? And I need to get back to this one...
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_imp_mining_ship)

kiizete_convo_first_mission_again = ConvoScreen:new {
	id = "first_mission_again",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_b78a2c76", -- Look. Go to the starport. Find a terminal and launch into space. The war isn't going to wait for you!
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_first_mission_again)

kiizete_convo_first_mission = ConvoScreen:new {
	id = "first_mission",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_65e8c460", -- So you're part of the Alliance now. How does it feel?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_b41e5c00", "fm_meh"}, -- Meh.
		{"@conversation/naboo_rebel_tier1_kiizete:s_8bf64edf", "fm_what_next"}, -- I don't know what to do next!
		{"@conversation/naboo_rebel_tier1_kiizete:s_1162efff", "fm_destiny"}, -- It is my destiny.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_first_mission)

kiizete_convo_fm_meh = ConvoScreen:new {
	id = "fm_meh",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_cbba56ce", -- I thought you would be excited.
	stopConversation = "false",
	animation = "hair_flip",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_6a1ce31d", "fm_scared"}, -- Well, I'm not.
		{"@conversation/naboo_rebel_tier1_kiizete:s_69a02cf2", "fm_be_safe"}, -- I am excited!
		{"@conversation/naboo_rebel_tier1_kiizete:s_7c075dce", "fm_way_out"}, -- How do I get out of here?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_meh)

kiizete_convo_fm_scared = ConvoScreen:new {
	id = "fm_scared",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_34d8b295", -- I think you're scared.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_scared)

kiizete_convo_fm_be_safe = ConvoScreen:new {
	id = "fm_be_safe",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_fd0a45a7", -- Well, just be safe up there. Okay?
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_be_safe)

kiizete_convo_fm_way_out = ConvoScreen:new {
	id = "fm_way_out",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_fe562082", -- Walk directly down the stairs... then wade into the water and slosh toward the starport. It's fun!
	stopConversation = "true",
	animation = "point_left",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_way_out)

kiizete_convo_fm_what_next = ConvoScreen:new {
	id = "fm_what_next",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_bd21db14", -- Take it easy. What don't you understand?
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_e97d81c5", "fm_launch"}, -- How do I launch?
		{"@conversation/naboo_rebel_tier1_kiizete:s_3704b308", "fm_up_there"}, -- What do I do up there?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_what_next)

kiizete_convo_fm_launch = ConvoScreen:new {
	id = "fm_launch",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_5c46c104", -- The starship terminal in the starport will allow you to do that. Go to the starport, and use the ship terminal to launch.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_4ed31d3f", "fm_land"}, -- How do I land?
		{"@conversation/naboo_rebel_tier1_kiizete:s_fc27931b", "fm_take_care"}, -- Thanks.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_launch)

kiizete_convo_fm_up_there = ConvoScreen:new {
	id = "fm_up_there",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_c1499ae3", -- Fly your route. Keep a low profile. Don't get into anything you can't handle. Come home safe.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_e97d81c5", "fm_launch"}, -- How do I launch?
		{"@conversation/naboo_rebel_tier1_kiizete:s_3704b308", "fm_up_there"}, -- What do I do up there?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_up_there)

kiizete_convo_fm_land = ConvoScreen:new {
	id = "fm_land",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_3e796521", -- Fly back to a space station. Comm the space station and tell them you want to land.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_a65b9c24", "fm_comm_station"}, -- How do I comm a space station?
		{"@conversation/naboo_rebel_tier1_kiizete:s_e5aa590e", "fm_find_station"}, -- Where will I find a space station?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_land)

kiizete_convo_fm_comm_station = ConvoScreen:new {
	id = "fm_comm_station",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_890f3624", -- Use SHIFT+C to target it and open communication with the station commander. You can choose to repair your ship or land.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_a65b9c24", "fm_comm_station"}, -- How do I comm a space station?
		{"@conversation/naboo_rebel_tier1_kiizete:s_e5aa590e", "fm_find_station"}, -- Where will I find a space station?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_comm_station)

kiizete_convo_fm_find_station = ConvoScreen:new {
	id = "fm_find_station",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_2895a98", -- When you launch, your ship computer system will create a 'launch waypoint' that you can use to find your way back. Keep this point active by opening your datapad, choosing the waypoint labeled 'Launch Waypoint', and choosing to 'Activate' it.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_a65b9c24", "fm_comm_station"}, -- How do I comm a space station?
		{"@conversation/naboo_rebel_tier1_kiizete:s_e5aa590e", "fm_find_station"}, -- Where will I find a space station?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_find_station)

kiizete_convo_fm_take_care = ConvoScreen:new {
	id = "fm_take_care",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_f6c52e55", -- Take care.
	stopConversation = "true",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_take_care)

kiizete_convo_fm_destiny = ConvoScreen:new {
	id = "fm_destiny",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_9cd181e7", -- I see. Pretty intense. For me it's just a question of survival.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_1c48bff0", "fm_survival"}, -- Survival?
		{"@conversation/naboo_rebel_tier1_kiizete:s_b369f7cd", "fm_sorry"}, -- I know what you mean.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_destiny)

kiizete_convo_fm_survival = ConvoScreen:new {
	id = "fm_survival",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_4669a3e4", -- Yeah. I'll tell you about it sometime.
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_survival)

kiizete_convo_fm_sorry = ConvoScreen:new {
	id = "fm_sorry",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_705da14d", -- Sorry to hear that.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_fm_sorry)

kiizete_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_17eec115", -- Stinks to fail missions doesn't it?
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_77e48d5b", "failed_forget_it"}, -- What do you mean?
		{"@conversation/naboo_rebel_tier1_kiizete:s_5df1433d", "failed_try_again"}, -- Yes. It does.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_mission1_failed)

kiizete_convo_failed_forget_it = ConvoScreen:new {
	id = "failed_forget_it",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_d2083ee4", -- Nothing. Forget I said anything.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_failed_forget_it)

kiizete_convo_failed_try_again = ConvoScreen:new {
	id = "failed_try_again",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_5655b98e", -- Don't beat yourself up about it. Just get back up there and try again.
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_fc27931b", "failed_no_problem"}, -- Thanks.
		{"@conversation/naboo_rebel_tier1_kiizete:s_670bb9d5", "failed_pointers"}, -- Any pointers?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_failed_try_again)

kiizete_convo_failed_no_problem = ConvoScreen:new {
	id = "failed_no_problem",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_c261cfae", -- No problem.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_failed_no_problem)

kiizete_convo_failed_pointers = ConvoScreen:new {
	id = "failed_pointers",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_b9934459", -- Me? No. I never made it as a fighter pilot. Sorry.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_failed_pointers)

kiizete_convo_mission1_won = ConvoScreen:new {
	id = "mission1_won",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_27b64c88", -- Hey... so tell me. How are things going?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_4bd66142", "won_mystery"}, -- Couldn't be better.
		{"@conversation/naboo_rebel_tier1_kiizete:s_ce894b84", "won_duty"}, -- Just doing my duty.
		{"@conversation/naboo_rebel_tier1_kiizete:s_93f420a0", "won_kidding"}, -- It's all falling apart.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_mission1_won)

kiizete_convo_won_mystery = ConvoScreen:new {
	id = "won_mystery",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_cff6adcf", -- It's interesting you say that. I hear the Alliance is scrambling to stay ahead of the Empire in the Naboo system. You're tangled up with a mystery squadron of rookie TIE fighters... or something... What are you hearing?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_4c90db01", "won_hope"}, -- We're doing just fine.
		{"@conversation/naboo_rebel_tier1_kiizete:s_8dbe594", "won_keep_cool"}, -- I'm living it! Back off!
		{"@conversation/naboo_rebel_tier1_kiizete:s_5dc9a083", "won_see_about"}, -- You don't need to worry.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_mystery)

kiizete_convo_won_hope = ConvoScreen:new {
	id = "won_hope",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_82288395", -- I hope you're right.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_hope)

kiizete_convo_won_keep_cool = ConvoScreen:new {
	id = "won_keep_cool",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_49a108e5", -- Sorry! Keep your cool, okay?
	stopConversation = "true",
	animation = "standing_placate",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_keep_cool)

kiizete_convo_won_see_about = ConvoScreen:new {
	id = "won_see_about",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_5aff38e2", -- We'll see about that...
	stopConversation = "true",
	animation = "sigh_deeply",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_see_about)

kiizete_convo_won_duty = ConvoScreen:new {
	id = "won_duty",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_65372fa4", -- I hear things about a mysterious wing of TIE fighters. Like the Empire is relocating some combat school to the Naboo system. Stinks! We'll have squints crawling all over us!
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_a5fe9928", "won_you_might"}, -- I'll take care of it.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_duty)

kiizete_convo_won_you_might = ConvoScreen:new {
	id = "won_you_might",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_8920c0f2", -- I think you just might.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_you_might)

kiizete_convo_won_kidding = ConvoScreen:new {
	id = "won_kidding",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_85d464bf", -- Are you kidding me?
	stopConversation = "true",
	animation = "stop",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_won_kidding)

kiizete_convo_stranger = ConvoScreen:new {
	id = "stranger",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_ca776e30", -- Who are you?
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_e518378e", "meet_name"}, -- (Give Kiizete your name)
		{"@conversation/naboo_rebel_tier1_kiizete:s_17edec66", "meet_who"}, -- First, who are you?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_stranger)

kiizete_convo_meet_name = ConvoScreen:new {
	id = "meet_name",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_46dcc469", -- Nice to meet you, %NU. What are you doing around here?
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_6bd02793", "meet_nothing"}, -- Nothing.
		{"@conversation/naboo_rebel_tier1_kiizete:s_c899d08d", "meet_join"}, -- I want to join the Rebel Alliance!
		{"@conversation/naboo_rebel_tier1_kiizete:s_2f212745", "meet_destiny"}, -- Destiny has drawn me here.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_name)

kiizete_convo_meet_nothing = ConvoScreen:new {
	id = "meet_nothing",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_61657d0f", -- I see.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_nothing)

kiizete_convo_meet_join = ConvoScreen:new {
	id = "meet_join",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_695e9ca2", -- What makes you think I would have anything to do with that?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_9940f453", "meet_email"}, -- I got a recruitment email from the Alliance.
		{"@conversation/naboo_rebel_tier1_kiizete:s_ff33d98b", "meet_training_droid"}, -- That droid is an Alliance training droid!
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_join)

kiizete_convo_meet_email = ConvoScreen:new {
	id = "meet_email",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_861c2497", -- You did, huh? Why don't you talk to V3 over there. He has a state-of-the-art Alliance Pilot training program!
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_c9274747", "meet_state_of_art"}, -- State-of-the-art?
		{"@conversation/naboo_rebel_tier1_kiizete:s_14aade81", "meet_teach"}, -- Do you teach?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_email)

kiizete_convo_meet_state_of_art = ConvoScreen:new {
	id = "meet_state_of_art",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_8a824d71", -- Well, maybe not. It's just the best that we can afford out here on Naboo. The Alliance doesn't have many friends in this system. It works, though. It's a very effective program.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_afd1368", "meet_how_use"}, -- How do I use it?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_state_of_art)

kiizete_convo_meet_how_use = ConvoScreen:new {
	id = "meet_how_use",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_2e823c5f", -- Just talk to the droid. He'll take it from there!
	stopConversation = "true",
	animation = "shrug_hands",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_how_use)

kiizete_convo_meet_teach = ConvoScreen:new {
	id = "meet_teach",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_a5edd9e5", -- No. Never really got the urge to teach piloting. Try the droid... He's good.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_teach)

kiizete_convo_meet_training_droid = ConvoScreen:new {
	id = "meet_training_droid",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_565d17f2", -- For now, maybe. But I'm going to fix that. So... let me get back to it!
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_training_droid)

kiizete_convo_meet_destiny = ConvoScreen:new {
	id = "meet_destiny",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_9d788910", -- I see, %NU... What destiny are you talking about?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_ed72de53", "meet_alliance_needs"}, -- The Alliance needs me.
		{"@conversation/naboo_rebel_tier1_kiizete:s_ca932c28", "meet_forget_it"}, -- Forget it.
		{"@conversation/naboo_rebel_tier1_kiizete:s_c39cb5eb", "meet_come_to_join"}, -- I've come to join the Rebel Alliance.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_destiny)

kiizete_convo_meet_alliance_needs = ConvoScreen:new {
	id = "meet_alliance_needs",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_e5b2f859", -- For what?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_a95b1747", "meet_save_galaxy"}, -- To save the galaxy!
		{"@conversation/naboo_rebel_tier1_kiizete:s_95658182", "meet_calling"}, -- I don't know yet...
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_alliance_needs)

kiizete_convo_meet_save_galaxy = ConvoScreen:new {
	id = "meet_save_galaxy",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_92a0a895", -- You should talk to the droid...
	stopConversation = "true",
	animation = "point_right",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_save_galaxy)

kiizete_convo_meet_calling = ConvoScreen:new {
	id = "meet_calling",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_7136aa3f", -- But you know that this is your calling? Did it come to you in a dream? I'm not trying to insult you - I do have dreams myself from time to time... sitting in a cockpit, blasting TIE fighters left and right!
	stopConversation = "false",
	animation = "standing_placate",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_9f32bc26", "meet_speak_v3fx"}, -- Yes. Like that.
		{"@conversation/naboo_rebel_tier1_kiizete:s_6103a248", "meet_good_luck"}, -- My destiny is different.
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_calling)

kiizete_convo_meet_speak_v3fx = ConvoScreen:new {
	id = "meet_speak_v3fx",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_104f81b8", -- Then you should speak with V3-FX right here. He can get you set up as an Alliance Pilot!
	stopConversation = "true",
	animation = "point_away",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_speak_v3fx)

kiizete_convo_meet_good_luck = ConvoScreen:new {
	id = "meet_good_luck",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_1ae7f565", -- I wish you good luck, my friend.
	stopConversation = "true",
	animation = "bow",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_good_luck)

kiizete_convo_meet_forget_it = ConvoScreen:new {
	id = "meet_forget_it",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_e22b6287", -- Ah. I probably wouldn't understand anyhow... Take care!
	stopConversation = "true",
	animation = "greet",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_forget_it)

kiizete_convo_meet_come_to_join = ConvoScreen:new {
	id = "meet_come_to_join",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_6a22af26", -- Then get to it! Grab hold of that droid and get your ship codes and flight clearance!
	stopConversation = "true",
	animation = "point_right",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_come_to_join)

kiizete_convo_meet_who = ConvoScreen:new {
	id = "meet_who",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_2b5181ae", -- My name is Kiizete. I am a technician.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_b26194cb", "meet_technician"}, -- What are you doing here?
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_who)

kiizete_convo_meet_technician = ConvoScreen:new {
	id = "meet_technician",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_ea3a9cb0", -- I've taken a contract to reprogram the droid... but it's proving to be a lot harder than anyone thought it would be. Maybe impossible!
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier1_kiizete:s_e518378e", "meet_name"}, -- (Give Kiizete your name)
		{"@conversation/naboo_rebel_tier1_kiizete:s_1628fad8", "meet_thanks"}, -- Good luck, then!
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_technician)

kiizete_convo_meet_thanks = ConvoScreen:new {
	id = "meet_thanks",
	leftDialog = "@conversation/naboo_rebel_tier1_kiizete:s_c4682ea6", -- Thanks!
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
kiizete_convo_template:addScreen(kiizete_convo_meet_thanks)

addConversationTemplate("kiizete_convo_template", kiizete_convo_template)
