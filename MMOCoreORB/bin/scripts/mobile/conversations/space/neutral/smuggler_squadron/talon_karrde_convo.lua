-- Talon Karrde (Smuggler transition, tier 1 -> 2) conversation screens; ported from SWG-Source tatooine_privateer_trainer_2 (STF conversation/tatooine_privateer_trainer_2). Handler: talonKarrdeConvoHandler.lua (feature smuggler-transition-karrde).
talon_karrde_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "talonKarrdeConvoHandler",
	screens = {}
}

not_member = ConvoScreen:new {
	id = "not_member",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_b50f6fd1", -- I'm too busy to talk to you. If you're looking for work, then talk to my man Dravis.
	animation = "wave_on_dismissing",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_dc9e436d", "not_member_what"}, -- What do you do?
		{"@conversation/tatooine_privateer_trainer_2:s_ba77b53a", "not_member_work"}, -- What sort of work?
	}
}
talon_karrde_convo_template:addScreen(not_member);

not_member_what = ConvoScreen:new {
	id = "not_member_what",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_3f2c222d", -- And what are you now, some sort of Imperial Inquisitor? It's none of your business what I'm doing!
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(not_member_what);

not_member_work = ConvoScreen:new {
	id = "not_member_work",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_c8206f73", -- If you don't know, then I'm not going to tell you. Go talk to Dravis if you're curious. He'll either tell you or shoot you.
	animation = "shrug_hands",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(not_member_work);

series_done = ConvoScreen:new {
	id = "series_done",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_697e04cf", -- So Shamdon got cold feet and decided to call off the operation. Nothing unusual about that though, you have to have an iron will to mess with Jabba. No matter, we always have work lined up for our pilots.
	animation = "tap_foot",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_98893f74", "jabba_wants_you"}, -- So what is going to be my next assignment?
	}
}
talon_karrde_convo_template:addScreen(series_done);

jabba_wants_you = ConvoScreen:new {
	id = "jabba_wants_you",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_fa31c92f", -- Believe it or not, Jabba was so impressed by your work against him that he has asked for your services specifically. You are to speak with Beissa in Jabba's Palace.
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_de9b68cd", "jabba_respects"}, -- Jabba wants me to work for him after what I did?
	}
}
talon_karrde_convo_template:addScreen(jabba_wants_you);

jabba_respects = ConvoScreen:new {
	id = "jabba_respects",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_7642f4a4", -- What did you do? Kill a bunch of fodder that Jabba really doesn't care about? Jabba respects only one thing and that is strength. You showed backbone and Jabba is more then willing to forgive and forget as long as you do a good job for him.
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_805cb6f3", "see_beissa"}, -- Alright I will report to Jabba.
	}
}
talon_karrde_convo_template:addScreen(jabba_respects);

see_beissa = ConvoScreen:new {
	id = "see_beissa",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_9504aca1", -- So you are smarter than you look. I would have really hated to train a new pilot after Jabba's men got through with you, had you refused. Go talk to Beissa in Jabba's Palace. Good luck to you and welcome to the big time.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(see_beissa);

trans_failed = ConvoScreen:new {
	id = "trans_failed",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_983a902c", -- What are you doing here? Didn't I tell you to go to Lok?
	animation = "gesticulate_wildly",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_a60a995b", "trans_retry"}, -- I ran into a problem.
	}
}
talon_karrde_convo_template:addScreen(trans_failed);

trans_retry = ConvoScreen:new {
	id = "trans_retry",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_12f6a89c", -- I don't want to hear about YOUR problem. Now complete that assignment or something REAL bad is going to happen to you.
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(trans_retry);

dravis_employee = ConvoScreen:new {
	id = "dravis_employee",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_3ff6efdd", -- Ah, %TU! One of Dravis's new 'employees', right?
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_151b3d1", "employee_keep_up"}, -- That's right.
		{"@conversation/tatooine_privateer_trainer_2:s_6372b444", "employee_not_ready"}, -- Can you give me an assignment?
	}
}
talon_karrde_convo_template:addScreen(dravis_employee);

employee_keep_up = ConvoScreen:new {
	id = "employee_keep_up",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_2a5548e1", -- He's told me about you, %NU. Keep up the good work. You should talk to Dravis if you're looking for something to do.
	animation = "explain",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(employee_keep_up);

employee_not_ready = ConvoScreen:new {
	id = "employee_not_ready",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_ff6979b6", -- Sorry, %NU, I don't think you're quite ready for anything that I would need for you to do. Check with Dravis and see if he's got some work for you.
	animation = "slow_down",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(employee_not_ready);

trans_won = ConvoScreen:new {
	id = "trans_won",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_9571c1b4", -- Excellent work! We have recovered the package from the scene of the battle; Now deliver it to Shamdon in the Lucky Despot like I asked you to. She's going to be one of the Smugglers Alliance's best clients after this. Just keep a low profile and work for Shamdon, now.
	animation = "applause_polite",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(trans_won);

on_trans = ConvoScreen:new {
	id = "on_trans",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_e002e01a", -- What are you doing here? I told you to go to Lok!
	animation = "gesticulate_wildly",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(on_trans);

summons = ConvoScreen:new {
	id = "summons",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_89b061e3", -- %NU! It's about time you got here. Didn't Dravis tell you I wanted to see you right away?
	animation = "check_wrist_device",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_c3c2195b", "summons_busy"}, -- I was busy.
		{"@conversation/tatooine_privateer_trainer_2:s_3f10da9d", "summons_fast"}, -- I got here as fast as I could.
	}
}
talon_karrde_convo_template:addScreen(summons);

summons_busy = ConvoScreen:new {
	id = "summons_busy",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_71162f37", -- Busy?! You lazy antenna-breaker! Next time Dravis tells you that I need to see you, you'd better haul jets! This is no Lum Run, I've got an important job for you... and this assignment is going to make us RICH.
	animation = "pound_fist_palm",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_1c8bddbb", "job_lok"}, -- What is it?
	}
}
talon_karrde_convo_template:addScreen(summons_busy);

summons_fast = ConvoScreen:new {
	id = "summons_fast",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_7a2ca8fc", -- That's what passes as 'fast' for you? Look, this is no Lum Run, I have an important job for you. And this assignment is going to make us RICH!
	animation = "shake_head_disgust",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_1c8bddbb", "job_lok"}, -- What is it?
	}
}
talon_karrde_convo_template:addScreen(summons_fast);

job_lok = ConvoScreen:new {
	id = "job_lok",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_810a7e7", -- Oh NOW you're in a hurry. You greedy bludfly! Alright, here's the deal, I need you to travel to Lok. Ever heard of a guy named Nym?
	animation = "laugh_titter",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_e70a45c9", "nym_unknown"}, -- Never heard of him.
		{"@conversation/tatooine_privateer_trainer_2:s_365a729a", "nym_known"}, -- I know him.
		{"@conversation/tatooine_privateer_trainer_2:s_ba9fbfb1", "nym_hates"}, -- Yes... and he really hates me.
	}
}
talon_karrde_convo_template:addScreen(job_lok);

nym_unknown = ConvoScreen:new {
	id = "nym_unknown",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_4312ff91", -- That's ok. He's one nasty customer anyway. He's a Feeorin, if you can believe that. You know how they are!
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_25e48bc1", "nym_feeorin"}, -- No, actually, I don't.
		{"@conversation/tatooine_privateer_trainer_2:s_9cf1e4c3", "nym_say_no_more"}, -- Say no more.
	}
}
talon_karrde_convo_template:addScreen(nym_unknown);

nym_feeorin = ConvoScreen:new {
	id = "nym_feeorin",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_af906d73", -- No? Well, I suppose you wouldn't. Not many of them around any more. Anyway, like I said, it's not really important.
	animation = "shrug_shoulders",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_db4bd0fd", "job_details"}, -- What is the job?
	}
}
talon_karrde_convo_template:addScreen(nym_feeorin);

nym_say_no_more = ConvoScreen:new {
	id = "nym_say_no_more",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_daf180e6", -- Right to the point, huh.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_db4bd0fd", "job_details"}, -- What is the job?
	}
}
talon_karrde_convo_template:addScreen(nym_say_no_more);

nym_known = ConvoScreen:new {
	id = "nym_known",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_4963bef6", -- Good, then you know he's not one to mess with. 'Course, he has a lot of enemies, but it's better to be on his good side than not, if you know what I mean.
	animation = "nod_head_multiple",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_db4bd0fd", "job_details"}, -- What is the job?
	}
}
talon_karrde_convo_template:addScreen(nym_known);

nym_hates = ConvoScreen:new {
	id = "nym_hates",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_9a287fb8", -- What? Why? What did you do?
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_privateer_trainer_2:s_db4bd0fd", "job_details"}, -- What is the job?
	}
}
talon_karrde_convo_template:addScreen(nym_hates);

job_details = ConvoScreen:new {
	id = "job_details",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_bb6309e6", -- Simple. Just travel to the Lok system and rendezvous with Nym's man. Here are the coordinates. All you need to do is to pick-up a package from him and deliver it to Shamdon in the Lucky Despot here on Tatooine.
	animation = "explain",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(job_details);

low_profile = ConvoScreen:new {
	id = "low_profile",
	leftDialog = "@conversation/tatooine_privateer_trainer_2:s_1169dea4", -- Whoa! Listen up, you need to keep a low profile as long as you're working for Shamdon! We don't want Jabba to find out we're also working for his competitors! Just hang out at the Lucky Despot for a while and do what Shamdon asks of you.
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
}
talon_karrde_convo_template:addScreen(low_profile);

addConversationTemplate("talon_karrde_convo_template", talon_karrde_convo_template)
