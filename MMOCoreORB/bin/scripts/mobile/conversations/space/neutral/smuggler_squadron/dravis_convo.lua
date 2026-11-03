-- Dravis (Smuggler tier 1) conversation screens; ported from SWG-Source tatooine_privateer_trainer_1 (STF conversation/tatooine_privateer_trainer_1). Handler: dravisConvoHandler.lua (feature smuggler-tier1-dravis).
dravis_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "dravisConvoHandler",
	screens = {}
}

first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_70421509", -- You've got your assignment and the control device for your ship in your datapad. Go to the Starport and access the terminal to launch into space.
	animation = "dismiss",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_111621e7", "help_where"}, -- Where do I go now?
		{"@conversation/tatooine_privateer_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/tatooine_privateer_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
dravis_convo_template:addScreen(first_mission_help);

help_where = ConvoScreen:new {
	id = "help_where",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_8622fd74", -- Go to the starport. Look for a 'starship terminal.' You can use these terminals to configure your ship and to launch into space.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_111621e7", "help_where"}, -- Where do I go now?
		{"@conversation/tatooine_privateer_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/tatooine_privateer_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
dravis_convo_template:addScreen(help_where);

help_return = ConvoScreen:new {
	id = "help_return",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_fd8bee64", -- You'll need to comm the Tatooine space station and tell them you want to land.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_4738e99f", "help_station"}, -- How do I find a space station?
		{"@conversation/tatooine_privateer_trainer_1:s_c4c3d546", "help_comm"}, -- How do I comm the space station?
		{"@conversation/tatooine_privateer_trainer_1:s_d038a005", "help_then"}, -- And then what?
	}
}
dravis_convo_template:addScreen(help_return);

help_ship = ConvoScreen:new {
	id = "help_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7425c603", -- Your ship is parked at the starport. The control codes are uploaded to your personal datapad. Check your datapad to review the status of your ship.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_111621e7", "help_where"}, -- Where do I go now?
		{"@conversation/tatooine_privateer_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/tatooine_privateer_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
dravis_convo_template:addScreen(help_ship);

help_station = ConvoScreen:new {
	id = "help_station",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_599b087d", -- You'll launch into the vicinity of a space station just above Tatooine. A waypoint will be automatically created. Fly back to this point when you are done with your assignment. You can also use the zone map to find space stations.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_4738e99f", "help_station"}, -- How do I find a space station?
		{"@conversation/tatooine_privateer_trainer_1:s_c4c3d546", "help_comm"}, -- How do I comm the space station?
		{"@conversation/tatooine_privateer_trainer_1:s_d038a005", "help_then"}, -- And then what?
	}
}
dravis_convo_template:addScreen(help_station);

help_comm = ConvoScreen:new {
	id = "help_comm",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_2e13d0e0", -- The station operator will recognize you when you show up and they'll comm you... but if you get impatient, hit SHIFT+C.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_4738e99f", "help_station"}, -- How do I find a space station?
		{"@conversation/tatooine_privateer_trainer_1:s_c4c3d546", "help_comm"}, -- How do I comm the space station?
		{"@conversation/tatooine_privateer_trainer_1:s_d038a005", "help_then"}, -- And then what?
	}
}
dravis_convo_template:addScreen(help_comm);

help_then = ConvoScreen:new {
	id = "help_then",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7f1ca275", -- The space station will let you land. You know - you might want to have the station repair your ship before landing. It would save me some trouble...
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_111621e7", "help_where"}, -- Where do I go now?
		{"@conversation/tatooine_privateer_trainer_1:s_85dd7d6c", "help_return"}, -- How do I get back?
		{"@conversation/tatooine_privateer_trainer_1:s_4358efe9", "help_ship"}, -- Where is my ship?
	}
}
dravis_convo_template:addScreen(help_then);

no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_71e7a88", -- You don't look like much of a pilot to me. Get lost before I feed you to the womp rats.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(no_jtl);

rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_6bedd221", -- You must be lost! Why don't you go somewhere else before you attract any unwanted attention my way.
	animation = "point_away",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(rebel_pilot);

imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_49a60ce1", -- I don't want any trouble, Imperial. Why don't you go harass someone else?
	animation = "refuse_offer_affection",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(imperial_pilot);

non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_20df70f7", -- Hey, I've heard of you! Not a bad pilot, as I understand it. What can I do for you?
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_c1ff5062", "non_member_no_missions"}, -- I'm looking for a mission. Do you have any?
	}
}
dravis_convo_template:addScreen(non_member);

non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_32c51f93", -- I probably shouldn't, but the Smugglers need all the help they can get right now. I do have some duty missions available. Are you ready for a duty mission?
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_privateer_trainer_1:s_8aeba6e5", "duty_menu"}, -- Yes, I am. What missions are available?
		{"@conversation/tatooine_privateer_trainer_1:s_db74ddc6", "training_not_ready"}, -- How about some training?
		{"@conversation/tatooine_privateer_trainer_1:s_2883b989", "duty_declined"}, -- Not right now, thanks.
	}
}
dravis_convo_template:addScreen(non_member_duty_offer);

non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_35047e82", -- Look, no offense, but I could get in big trouble with the Smugglers Alliance if I started just handing out missions to anybody. You should really go through your own contacts.
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(non_member_no_missions);

lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_ce52ddaa", -- You're going to need a ship if you plan on doing anything constructive around here. I'll add the control codes to your datapad that will get you into a little model that I, uh, found. You'd better think about upgrading to a better ship, though.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(lost_ship);

on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_c30fda16", -- Don't you have something you should be doing right now?
	animation = "rub_chin_thoughtful",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(on_mission);

duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_4d19fcb1", -- What's on your mind? Thinking about performing some duty missions?
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_privateer_trainer_1:s_8aeba6e5", "duty_menu"}, -- Yes, I am. What missions are available?
		{"@conversation/tatooine_privateer_trainer_1:s_db74ddc6", "training_not_ready"}, -- How about some training?
		{"@conversation/tatooine_privateer_trainer_1:s_2883b989", "duty_declined"}, -- Not right now, thanks.
	}
}
dravis_convo_template:addScreen(duty_missions);

duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d43b2932", -- Duty missions are a good way for you to get experience as a pilot. Only experienced pilots can receive the proper training to learn new skills and abilities.There's no real final objective so you can end the mission whenever you want. So, would you like to take a duty mission?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_privateer_trainer_1:s_8aeba6e5", "duty_menu"}, -- Yes, I am. What missions are available?
		{"@conversation/tatooine_privateer_trainer_1:s_db74ddc6", "training_not_ready"}, -- How about some training?
		{"@conversation/tatooine_privateer_trainer_1:s_2883b989", "duty_declined"}, -- Not right now, thanks.
	}
}
dravis_convo_template:addScreen(duty_explained);

training_not_ready = ConvoScreen:new {
	id = "training_not_ready",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_e5c453e0", -- You're not ready for more training yet. But duty missions are a good way of getting good experience so that you'll be ready for training soon. What do you say? Are you ready to try a duty mission?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6106187c", "duty_explained"}, -- What is a duty mission?
		{"@conversation/tatooine_privateer_trainer_1:s_8aeba6e5", "duty_menu"}, -- Yes, I am. What missions are available?
		{"@conversation/tatooine_privateer_trainer_1:s_db74ddc6", "training_not_ready"}, -- How about some training?
		{"@conversation/tatooine_privateer_trainer_1:s_2883b989", "duty_declined"}, -- Not right now, thanks.
	}
}
dravis_convo_template:addScreen(training_not_ready);

duty_declined = ConvoScreen:new {
	id = "duty_declined",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_41e93b9e", -- Perhaps some other time, then.
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(duty_declined);

duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_f04d5e44", -- Well, we do need someone to escort our supply shipments. If you're feeling more aggresive, you could take out some Black Sun pirates, or even the Black Sun leader. Of course, there's always room for some healthy competition with the Valarians, too. What do you say?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_695b8483", "destroy_duty"}, -- Black Sun pirates.
		{"@conversation/tatooine_privateer_trainer_1:s_61b6e28a", "recovery_duty"}, -- Healthy competition.
		{"@conversation/tatooine_privateer_trainer_1:s_87f48e61", "leader_duty"}, -- The Black Sun leader.
		{"@conversation/tatooine_privateer_trainer_1:s_96294214", "escort_duty"}, -- Escort Duty.
	}
}
dravis_convo_template:addScreen(duty_menu);

destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_71015a7d", -- There are a lot of Black Sun pirates in the Tatooine system and they have no business being here. Just go out and kill all of them that you can find and we'll pay you for each kill. This is HUTT space!
	animation = "pound_fist_palm",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(destroy_duty);

recovery_duty = ConvoScreen:new {
	id = "recovery_duty",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_c8bcb663", -- You're right! It is rather unfortunate but we find that the Valarians are not keeping up their end of the bargain. So we need to help them meet their dues. Go 'recover' some of their precious cargo, though I don't expect they will just hand it to you.
	animation = "explain",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recovery_duty);

leader_duty = ConvoScreen:new {
	id = "leader_duty",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_a2e76d1a", -- No sooner do you kill one of their leaders than they find some thug to take his place. We're just going to have to take their leader out, is all. I hope you're committed to this!
	animation = "threaten",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(leader_duty);

escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7436b5b6", -- That's good thinking. We need to make sure our shipments are making it through safely. Get out there and escort our transports through and we'll pay you for every one that makes it.
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(escort_duty);

recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_e2bc57c4", -- Who sent you?
	animation = "hands_above_head",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_900f01d1", "recruit_kid"}, -- What?
		{"@conversation/tatooine_privateer_trainer_1:s_2b595da6", "recruit_shuttle"}, -- No one sent me.
		{"@conversation/tatooine_privateer_trainer_1:s_2b691aa0", "recruit_friend"}, -- A friend.
	}
}
dravis_convo_template:addScreen(recruitment);

recruit_kid = ConvoScreen:new {
	id = "recruit_kid",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_cd038c67", -- Look, if you're here about the kid... It's not mine
	animation = "refuse_offer_affection",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_b1f10b5", "recruit_shuttle"}, -- I don't care about that.
		{"@conversation/tatooine_privateer_trainer_1:s_5f272b1e", "recruit_shuttle"}, -- I don't know what you're talking about.
	}
}
dravis_convo_template:addScreen(recruit_kid);

recruit_shuttle = ConvoScreen:new {
	id = "recruit_shuttle",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_c28cc06d", -- Are you here about that Imperial Shuttle? I'm telling you, that's an unsubstantiated rumor, nothing more. I have never stolen a shuttle in my life. Don't you think the Empire has precautions and safeguards to prevent that sort of thing?
	animation = "refuse_offer_affection",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_2e5f3688", "recruit_what_want"}, -- I really don't know what you are talking about.
	}
}
dravis_convo_template:addScreen(recruit_shuttle);

recruit_friend = ConvoScreen:new {
	id = "recruit_friend",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_dc5b3564", -- A friend of yours or a friend of mine? And just what did this friend tell you about me?
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_681e480d", "recruit_maybe"}, -- I hear you can train pilots.
		{"@conversation/tatooine_privateer_trainer_1:s_c6f8e9e9", "recruit_depends"}, -- Ever heard of the Smugglers Alliance?
	}
}
dravis_convo_template:addScreen(recruit_friend);

recruit_got_ship = ConvoScreen:new {
	id = "recruit_got_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_140229b8", -- Oh yeah? That was fast. Must have been a level zip ship. So, you ready to sign up with old Dravis?
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_dc9e436d", "recruit_karrde"}, -- What do you do?
		{"@conversation/tatooine_privateer_trainer_1:s_d335136f", "recruit_signed"}, -- Yes I am.
		{"@conversation/tatooine_privateer_trainer_1:s_4440ce87", "recruit_go_away"}, -- I changed my mind.
	}
}
dravis_convo_template:addScreen(recruit_got_ship);

recruit_go_away = ConvoScreen:new {
	id = "recruit_go_away",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_31fc5801", -- Well then go away and stop bothering me. I'm a busy man!
	animation = "dismiss",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_go_away);

recruit_what_want = ConvoScreen:new {
	id = "recruit_what_want",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_fc4ba900", -- Well what DO you want?
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_b26194cb", "recruit_minding"}, -- What are you doing here?
		{"@conversation/tatooine_privateer_trainer_1:s_cdcb429b", "recruit_forget"}, -- Nothing! Forget I said anything.
	}
}
dravis_convo_template:addScreen(recruit_what_want);

recruit_minding = ConvoScreen:new {
	id = "recruit_minding",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_c86b6bef", -- I'm minding my own business. What are YOU doing here?
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_e81a1436", "recruit_academy"}, -- I want to be a pilot.
	}
}
dravis_convo_template:addScreen(recruit_minding);

recruit_forget = ConvoScreen:new {
	id = "recruit_forget",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_58b6db3f", -- Well, ok, then. Go bother someone else.
	animation = "dismiss",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_forget);

recruit_academy = ConvoScreen:new {
	id = "recruit_academy",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d60a3e3", -- Oh you do, huh? Well what do I look like, a flight instructor? Go join the Imperial Academy if you want to learn how to fly.
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_4ff172ab", "recruit_no_empire"}, -- I don't want to fly for the Empire!
		{"@conversation/tatooine_privateer_trainer_1:s_80094dc8", "recruit_great_idea"}, -- Great idea!
	}
}
dravis_convo_template:addScreen(recruit_academy);

recruit_no_empire = ConvoScreen:new {
	id = "recruit_no_empire",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_cff9699e", -- Well, I can't say I blame you. After what happened to that massive space station of theirs!
	animation = "nod_head_multiple",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6e03f969", "recruit_work_something"}, -- So can you teach me to fly?
	}
}
dravis_convo_template:addScreen(recruit_no_empire);

recruit_great_idea = ConvoScreen:new {
	id = "recruit_great_idea",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7262f027", -- Hey wait... you're not going to say anything about that shuttle business are you?
	animation = "slow_down",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_cd0dcead", "recruit_appreciate"}, -- Of course not.
		{"@conversation/tatooine_privateer_trainer_1:s_40a69ad7", "recruit_hasty"}, -- Maybe I will...
	}
}
dravis_convo_template:addScreen(recruit_great_idea);

recruit_appreciate = ConvoScreen:new {
	id = "recruit_appreciate",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_ea9c260b", -- Oh good. I'd really appreciate that.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_appreciate);

recruit_hasty = ConvoScreen:new {
	id = "recruit_hasty",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_174c33a6", -- Whoa, whoa! Don't be hasty. Look, you don't want to join the Imperial Academy. Do you have any idea how long they make you serve? Years! Trust me, you'll be dying to get away from the Empire within a month.
	animation = "slow_down",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6e03f969", "recruit_work_something"}, -- So can you teach me to fly?
		{"@conversation/tatooine_privateer_trainer_1:s_cf4d3521", "recruit_rue"}, -- We'll see about that.
	}
}
dravis_convo_template:addScreen(recruit_hasty);

recruit_rue = ConvoScreen:new {
	id = "recruit_rue",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d57c89f2", -- Ha! All right then, go ahead and join the Empire! You'll rue the day!
	animation = "laugh_cackle",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_rue);

recruit_maybe = ConvoScreen:new {
	id = "recruit_maybe",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_bb3a34dc", -- Maybe I can...
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6d273b75", "recruit_work_something"}, -- Will you train me?
	}
}
dravis_convo_template:addScreen(recruit_maybe);

recruit_depends = ConvoScreen:new {
	id = "recruit_depends",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_afc7e628", -- Depends who's asking.
	animation = "look_casual",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_940e1e78", "recruit_skills"}, -- I want to join.
		{"@conversation/tatooine_privateer_trainer_1:s_d9eefb7e", "recruit_skills"}, -- I am
	}
}
dravis_convo_template:addScreen(recruit_depends);

recruit_skills = ConvoScreen:new {
	id = "recruit_skills",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_a02b95fc", -- Look, this is no job for a creddrone. You've got to have SKILLS to be a pilot!
	animation = "snap_finger1",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_6d273b75", "recruit_work_something"}, -- Will you train me?
	}
}
dravis_convo_template:addScreen(recruit_skills);

recruit_work_something = ConvoScreen:new {
	id = "recruit_work_something",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_aa69d394", -- I suppose we could work something out. But you're going to owe me! And you'll need your own ship! I can't supply every wannabe freighter bum.
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_381dd7dd", "recruit_cost"}, -- How much is this going to cost?
	}
}
dravis_convo_template:addScreen(recruit_work_something);

recruit_cost = ConvoScreen:new {
	id = "recruit_cost",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_62f16f7a", -- Well, training like this, it's worth its weight in spice. And I hope you don't think you're going to turn into an ace spacer overnight! Tell you what: you come to work for me and I'll teach you how fly. We'll call it OJT - On the Job Training. Do a good job and maybe I'll even pay you, too.
	animation = "snap_finger1",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_dc9e436d", "recruit_karrde"}, -- What do you do?
		{"@conversation/tatooine_privateer_trainer_1:s_ebe2e111", "recruit_signed"}, -- It's a deal.
		{"@conversation/tatooine_privateer_trainer_1:s_9dcdd171", "recruit_refused"}, -- I don't want to work for you.
	}
}
dravis_convo_template:addScreen(recruit_cost);

recruit_karrde = ConvoScreen:new {
	id = "recruit_karrde",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_298df3ee", -- It's Talon Karrde's idea, really. Just something we're trying out here on Tatooine. Nothing strictly what you'd call 'legal' exactly, but here in the Outer Rim who cares, you know?
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_9f8c06d0", "recruit_alliance"}, -- So you're smuggling?
	}
}
dravis_convo_template:addScreen(recruit_karrde);

recruit_alliance = ConvoScreen:new {
	id = "recruit_alliance",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d5cecb82", -- Hey, the way the Empire has been cracking down lately, it's not as if a free-freighter bum has any choice, right? Anyway, we figure we've all got to stick together, so we're forming a sort of Smugglers Alliance.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_e84d85e2", "recruit_signed"}, -- Sounds great.
		{"@conversation/tatooine_privateer_trainer_1:s_2d1e63d0", "recruit_all_types"}, -- I don't want to smuggle.
	}
}
dravis_convo_template:addScreen(recruit_alliance);

recruit_all_types = ConvoScreen:new {
	id = "recruit_all_types",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_88a0099", -- That's the beauty of it! Forming a Smugglers Alliance means we have jobs for all types. We need combat pilots to guard shipments, rescue ships for when things go bad. Heck, we could even use someone to run decoy flights.
	animation = "tap_head",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_ca932c28", "recruit_refused"}, -- Forget it.
		{"@conversation/tatooine_privateer_trainer_1:s_429872ac", "recruit_signed"}, -- Ok, it's a deal!
	}
}
dravis_convo_template:addScreen(recruit_all_types);

recruit_refused = ConvoScreen:new {
	id = "recruit_refused",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_541c2f70", -- Well that's just fine. I've got plenty of people working for me already. Come see me if you change your mind.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_refused);

recruit_signed = ConvoScreen:new {
	id = "recruit_signed",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_807f6dd0", -- Ok, I'll let Talon Karrde know we've got a new employee. Are you ready for your first assignment?
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_eb2cfdac", "mission1_brief"}, -- You bet.
		{"@conversation/tatooine_privateer_trainer_1:s_8d95c731", "recruit_later"}, -- I'd rather take care of some things, first.
	}
}
dravis_convo_template:addScreen(recruit_signed);

recruit_later = ConvoScreen:new {
	id = "recruit_later",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_9ea8105f", -- Alright, make your preparations and come see me again when you're ready. But don't take too long...
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_later);

recruit_no_ship = ConvoScreen:new {
	id = "recruit_no_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_94e896c1", -- NMP. Do you know what that stands for? Not my problem. Come see me when you get your own ship.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_a0b4565", "recruit_loan_ship"}, -- Can't you loan me one?
		{"@conversation/tatooine_privateer_trainer_1:s_d24a2285", "recruit_get_ship"}, -- Will do.
	}
}
dravis_convo_template:addScreen(recruit_no_ship);

recruit_loan_ship = ConvoScreen:new {
	id = "recruit_loan_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_b4d6cb30", -- Ok, fine. Look, here are the access codes to a little thing that I, uh, found. Do you think you're ready for your first assignment NOW? Or do you want me to pull it around front for you?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_1adbadc4", "mission1_brief"}, -- I'm ready.
		{"@conversation/tatooine_privateer_trainer_1:s_8d95c731", "recruit_trouble"}, -- I'd rather take care of some things, first.
	}
}
dravis_convo_template:addScreen(recruit_loan_ship);

recruit_get_ship = ConvoScreen:new {
	id = "recruit_get_ship",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_5ac0c4a5", -- Good, great, whatever. See you later.
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_get_ship);

recruit_trouble = ConvoScreen:new {
	id = "recruit_trouble",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d345d41f", -- Hutts in a handbag, you're starting to be more trouble than you're worth. Fine, make your preparations and come see me again when you're ready. But don't take too long...
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(recruit_trouble);

mission1_brief = ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_95df6b05", -- Some of our shipments have come up missing. We suspect foul play... Why don't you run a quick patrol and make sure there's nothing under-handed going on out there? Jabba's going to be pretty angry if we start failing to deliver the goods!
	animation = "greet",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission1_brief);

mission1_retry = ConvoScreen:new {
	id = "mission1_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_fa5082f1", -- Ran into a spot of trouble, huh? Are you up to running that patrol again, or not? 'Course you are!
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission1_retry);

mission2_retry = ConvoScreen:new {
	id = "mission2_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_3924fc00", -- There are still pirates in the area. We need you to get out there and kill them right now, understand?
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission2_retry);

mission3_retry = ConvoScreen:new {
	id = "mission3_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_6d6f9a8d", -- We thought that would be the last of the Black Sun pirates, but I guess there were more out there. Try running that patrol again, ok? Maybe they've moved on.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission3_retry);

mission4_retry = ConvoScreen:new {
	id = "mission4_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_999009d", -- What happened to you? I thought you could handle this? Look, we need that ace DEAD. If you're not up to this, then maybe you should hire some help.
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission4_retry);

mission1_reward = ConvoScreen:new {
	id = "mission1_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7705d12c", -- Good job. I knew that patrol would be no problem for you.
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_676c343f", "mission2_offer"}, -- That was easy.
		{"@conversation/tatooine_privateer_trainer_1:s_ff2a95e8", "mission2_offer"}, -- A Black Sun pirate attacked me!
	}
}
dravis_convo_template:addScreen(mission1_reward);

mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_95df6b05", -- Some of our shipments have come up missing. We suspect foul play... Why don't you run a quick patrol and make sure there's nothing under-handed going on out there? Jabba's going to be pretty angry if we start failing to deliver the goods!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_9237617f", "mission1_accept"}, -- What about training?
	}
}
dravis_convo_template:addScreen(mission1_offer);

mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_ca38bc3e", -- Run that patrol, and we'll talk about training later.
	animation = "point_away",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission1_accept);

mission2_reward = ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_1f0c9843", -- Ha! That'll get the Black Sun off our backs for a while. Way to go!
	animation = "celebrate",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_b9b27823", "mission3_offer"}, -- Thank you.
		{"@conversation/tatooine_privateer_trainer_1:s_d0cc72e0", "mission3_offer"}, -- I bet there are more out there.
	}
}
dravis_convo_template:addScreen(mission2_reward);

mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_25669048", -- So the Black Sun are trying to move in on Hutt space, huh? Well we'd better show them who's in charge around here. Analyzing the sensor data from that ship you killed, you should find more in the system. We will provide you with some possible locations, now get at it.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_9237617f", "mission2_accept"}, -- What about training?
	}
}
dravis_convo_template:addScreen(mission2_offer);

mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_a2123b71", -- You need to do some more for me, before I do anything more for you. There'll be time for training later. Go get those Black Sun right now.
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission2_accept);

mission3_reward = ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_b34a0dd2", -- That was quick thinking on your part, rescuing our transport like that and escorting it through. You deserve a bonus for that. I've also got something special for you... this mercenary bandolier will help you keep your things organized.
	animation = "nod_head_multiple",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_98d00f66", "mission4_offer"}, -- Great! Thanks!
		{"@conversation/tatooine_privateer_trainer_1:s_60225cc9", "mission4_offer"}, -- Thanks, but it was nothing.
	}
}
dravis_convo_template:addScreen(mission3_reward);

mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_25cf6221", -- You'd better run a more thorough patrol to make sure there aren't more Black Sun in the area. We don't want to lose any more shipments through here.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_9237617f", "mission3_accept"}, -- What about training?
	}
}
dravis_convo_template:addScreen(mission3_offer);

mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_110c7bdd", -- Just complete a couple more assignment, %TU. You're doing a good job. Don't worry, I'll train you soon.
	animation = "shake_head_disgust",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission3_accept);

mission4_reward = ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_66ef1520", -- Fantastic job! The Black Sun ace won't bother us again, I can tell you that.
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_fc27931b", "duty_missions"}, -- Thanks.
		{"@conversation/tatooine_privateer_trainer_1:s_481c3940", "first_training"}, -- When will you teach me to fly?
	}
}
dravis_convo_template:addScreen(mission4_reward);

mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_2a8b0366", -- Well these Black Sun pirates aren't getting the message. We need to hit them hard: Cut off the head and the tail will follow. I want you to kill an ace pilot operating in our area.
	animation = "pound_fist_palm",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_fc963b1e", "mission4_accept"}, -- I'm ready to train
	}
}
dravis_convo_template:addScreen(mission4_offer);

mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_85355c2f", -- Ok, ok... tell ya what, %NU. You go dispose of that ace pilot for me, and then I'll train you to be a better pilot. I'll even throw in a new blaster for your ship.
	animation = "rub_chin_thoughtful",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(mission4_accept);

tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_be1beb37", -- Listen, something has come up that we need you to take care of. Talon Karrde's got a special assignment for you. He is right over there. Go talk to him.
	animation = "point_forward",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_8467c710", "tier_done_oh_and"}, -- Ok
	}
}
dravis_convo_template:addScreen(tier_done);

tier_done_oh_and = ConvoScreen:new {
	id = "tier_done_oh_and",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_f17c03b4", -- Oh, and %TU...
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_9fdd7cf3", "tier_done_hyperdrive"}, -- Yes?
	}
}
dravis_convo_template:addScreen(tier_done_oh_and);

tier_done_hyperdrive = ConvoScreen:new {
	id = "tier_done_hyperdrive",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_7d5682f4", -- You're going to need a ship with a hyperdrive. Do you have one?
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_370822d1", "tier_done_talk"}, -- Yes
	}
}
dravis_convo_template:addScreen(tier_done_hyperdrive);

tier_done_talk = ConvoScreen:new {
	id = "tier_done_talk",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_d3d66c68", -- Excellent! Now talk to Talon Karrde.
	animation = "snap_finger2",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(tier_done_talk);

first_training = ConvoScreen:new {
	id = "first_training",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_605d90db", -- Right! I think you're ready for some additional training. Now tell me, which area interests you the most?
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_3818dc2a", "trained_starships"}, -- I am interested in basic fighters.
		{"@conversation/tatooine_privateer_trainer_1:s_3fa70900", "trained_weapons"}, -- I am interested in basic starship component use.
		{"@conversation/tatooine_privateer_trainer_1:s_7d57477f", "trained_procedures"}, -- I am interested in basic training.
		{"@conversation/tatooine_privateer_trainer_1:s_9480f430", "trained_droid"}, -- I am interested in droid interface basics.
	}
}
dravis_convo_template:addScreen(first_training);

more_training = ConvoScreen:new {
	id = "more_training",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_ae220ebc", -- There's no doubt all that practice has paid off. I think you've proven you're ready for some additional training. What skill interests you?
	animation = "nod_head_multiple",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_1:s_3818dc2a", "trained_starships"}, -- I am interested in basic fighters.
		{"@conversation/tatooine_privateer_trainer_1:s_3fa70900", "trained_weapons"}, -- I am interested in basic starship component use.
		{"@conversation/tatooine_privateer_trainer_1:s_7d57477f", "trained_procedures"}, -- I am interested in basic training.
		{"@conversation/tatooine_privateer_trainer_1:s_9480f430", "trained_droid"}, -- I am interested in droid interface basics.
	}
}
dravis_convo_template:addScreen(more_training);

trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_2b94498c", -- Excellent choice. Learning to pilot better ships will allow you to tackle more difficult assignments.
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(trained_starships);

trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_9690c2f9", -- There are a few simple tricks I can teach you that will make you a much more lethal fighter pilot. Of course, you'll need to get out there and practice these maneuvers in order to really improve.
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(trained_weapons);

trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_4a441e77", -- Improving your skills as a pilot will definitely help you in your career. This will probably save your life someday!
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(trained_procedures);

trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_privateer_trainer_1:s_35a591ea", -- The ability to interface with droids is an invaluable skill for any pilot.
	animation = "nod_head_multiple",
	stopConversation = "true",
	options = {}
}
dravis_convo_template:addScreen(trained_droid);

addConversationTemplate("dravis_convo_template", dravis_convo_template);
