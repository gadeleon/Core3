-- Inquisitor Vrke (Inquisition tier 3) conversation; ported from SWG-Source naboo_imperial_tier3.java with the pre-NGE client lines (feature inquisition-tier3-vrke). Handler: vrkeConvoHandler.
vrke_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "vrkeConvoHandler",
	screens = {}
}

vrke_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b6c9b83b", -- How did you get in here? The guards will certainly hear about their failure to keep the likes of you out. Begone before I decide to put you under the question.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1f64a6b3", "wrong_faction_788cbcfb"}, -- Sorry, I will leave right away.
	}
}
vrke_convo_template:addScreen(vrke_convo_wrong_faction)

vrke_convo_wrong_faction_788cbcfb = ConvoScreen:new {
	id = "wrong_faction_788cbcfb",
	leftDialog = "@conversation/naboo_imperial_tier3:s_788cbcfb", -- Don't stand there babbling like a fool. Just leave.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_wrong_faction_788cbcfb)

vrke_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e1b0c231", -- I have more important things to do right now than to speak with you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_5ff8baab", "not_pilot_57d96aed"}, -- I was wondering if you could answer some questions?
	}
}
vrke_convo_template:addScreen(vrke_convo_not_pilot)

vrke_convo_not_pilot_57d96aed = ConvoScreen:new {
	id = "not_pilot_57d96aed",
	leftDialog = "@conversation/naboo_imperial_tier3:s_57d96aed", -- People don't ask me questions, I ask them questions! Where were you on the night of the Aqualish uprising?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_60495432", "not_pilot_ed26944d"}, -- Umm...I think I will be going now.
	}
}
vrke_convo_template:addScreen(vrke_convo_not_pilot_57d96aed)

vrke_convo_not_pilot_ed26944d = ConvoScreen:new {
	id = "not_pilot_ed26944d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_ed26944d", -- I honestly never expected you to have a good idea. It is refreshing to see that I was wrong.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_not_pilot_ed26944d)

vrke_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/naboo_imperial_tier3:s_246a0af2", -- For your sake, I will assume that you have NOT deserted your squadron. I suggest that you return to your commanding officer immediately.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b48bd0a4", "off_track_8f1228f6"}, -- I would never desert!
	}
}
vrke_convo_template:addScreen(vrke_convo_off_track)

vrke_convo_off_track_8f1228f6 = ConvoScreen:new {
	id = "off_track_8f1228f6",
	leftDialog = "@conversation/naboo_imperial_tier3:s_8f1228f6", -- You sound rather guilty about something. Maybe you would like to answer a few of my questions?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_e7435914", "off_track_54e4328d"}, -- No, I am fine. We are all fine here.
	}
}
vrke_convo_template:addScreen(vrke_convo_off_track_8f1228f6)

vrke_convo_off_track_54e4328d = ConvoScreen:new {
	id = "off_track_54e4328d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_54e4328d", -- I suggest that if you wish to stay that way, you leave now.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_off_track_54e4328d)

vrke_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7e0ef42a", -- You understand that the Inquisition can tolerate not even the slightest hint of treason?  You have a guilty look about you.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_tier3:s_dbd88d67", "wanted_14ef7b20"}, -- Who, me?
	}
}
vrke_convo_template:addScreen(vrke_convo_wanted)

vrke_convo_wanted_14ef7b20 = ConvoScreen:new {
	id = "wanted_14ef7b20",
	leftDialog = "@conversation/naboo_imperial_tier3:s_14ef7b20", -- Indeed.  Perhaps you should take some time to reflect on your dedication to the Empire.  Perhaps you should do that now, before I have you executed.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_imperial_tier3:s_77e48d5b", "wanted_29eb9a6b"}, -- What do you mean?
	}
}
vrke_convo_template:addScreen(vrke_convo_wanted_14ef7b20)

vrke_convo_wanted_29eb9a6b = ConvoScreen:new {
	id = "wanted_29eb9a6b",
	leftDialog = "@conversation/naboo_imperial_tier3:s_29eb9a6b", -- What I mean, %TU, is that unless you can prove your devotion to the Emperor - improve your standing with the Empire - I will have you shot for treason.  In any case, you will no longer fly missions for the Inquisition.  Not until you prove your loyalty.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_wanted_29eb9a6b)

vrke_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_imperial_tier3:s_12691b1c", -- I do not have time for idle chatter with any one right now. I am very busy doing the work of the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_8367fc83", "not_ready_f3a00a53"}, -- I am here to report for duty.
		{"@conversation/naboo_imperial_tier3:s_1ba9577c", "not_ready_3c1e05f"}, -- I will leave you alone then, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_not_ready)

vrke_convo_not_ready_f3a00a53 = ConvoScreen:new {
	id = "not_ready_f3a00a53",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f3a00a53", -- If I wanted the help of children, I would ask for it! You are not ready to face the challenges that our profession presents. Return to your commander, listen, watch, and learn. When the time is right perhaps I will send for you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_268fe491", "not_ready_b9fc0fde"}, -- Yes, sir. Sorry, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_not_ready_f3a00a53)

vrke_convo_not_ready_3c1e05f = ConvoScreen:new {
	id = "not_ready_3c1e05f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_3c1e05f", -- Discretion is the better part of valor.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_not_ready_3c1e05f)

vrke_convo_not_ready_b9fc0fde = ConvoScreen:new {
	id = "not_ready_b9fc0fde",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b9fc0fde", -- Well? Why are you still here?
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_not_ready_b9fc0fde)

vrke_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c9911c0f", -- A member of the Inquisition must show patience in all things. You must also learn to focus on your tasks. Do not return to me until you have completed the task that I have assigned to you.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_on_mission)

vrke_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c5903cb3", -- Is it done?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_2b4326ff", "m1_retry_searching"}, -- I'm still searching.
		{"@conversation/naboo_imperial_tier3:s_ff715762", "m1_failed_d3942818"}, -- I'll find that ship. I promise.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_failed)

vrke_convo_m1_retry_searching = ConvoScreen:new {
	id = "m1_retry_searching",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1834b871", -- Please continue. I am anxious to find out why the Colonel's yacht was stolen.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_retry_searching)

vrke_convo_m1_failed_d3942818 = ConvoScreen:new {
	id = "m1_failed_d3942818",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d3942818", -- Thank you for that promise.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3b7137e5", "m1_retry_promise"}, -- Um...you're welcome.
		{"@conversation/naboo_imperial_tier3:s_fd0ebe0b", "m1_retry_sooner"}, -- I'm going back out there immediately.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_failed_d3942818)

vrke_convo_m1_retry_promise = ConvoScreen:new {
	id = "m1_retry_promise",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f8076c38", -- I would like to make a promise as well. I promise to do my work. It will be with the people who stole Colonel Hend's yacht, or it will be with you.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_retry_promise)

vrke_convo_m1_retry_sooner = ConvoScreen:new {
	id = "m1_retry_sooner",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d9c145dd", -- The sooner the better.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_retry_sooner)

vrke_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1adf59ad", -- Tell me. Are you helping the traitors?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_765d3767", "m2_retry_loyal"}, -- I'm loyal to the Empire!
		{"@conversation/naboo_imperial_tier3:s_7426e000", "m2_retry_actions"}, -- No!
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_failed)

vrke_convo_m2_retry_loyal = ConvoScreen:new {
	id = "m2_retry_loyal",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a425b892", -- They used to say they were loyal, too.  I would like you to finish your job.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_retry_loyal)

vrke_convo_m2_retry_actions = ConvoScreen:new {
	id = "m2_retry_actions",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5a9c71e2", -- Actions speak louder than words. Complete your mission.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_retry_actions)

vrke_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f3d48e75", -- If you are here, then you must have completed your mission.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b5f15b19", "m3_retry"}, -- Not yet.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_failed)

vrke_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d8181837", -- Then returning was a mistake. Do not make me angry.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_retry)

vrke_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/naboo_imperial_tier3:s_fc6aad81", -- Didn't I tell you?  We cannot take the risk that an Imperial general has been trading secrets to the Rebellion.  Isn't that what I said to you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b45b7c66", "m4_retry_again"}, -- Yes, I'll try again
		{"@conversation/naboo_imperial_tier3:s_5815dd18", "m4_retry_excuses"}, -- It wasn't my fault
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_failed)

vrke_convo_m4_retry_again = ConvoScreen:new {
	id = "m4_retry_again",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d1fa7f48", -- You certainly will.  Again and again and again if necessary.  The General must never arrive.  So go to the Dathomir system and destroy his ship.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_retry_again)

vrke_convo_m4_retry_excuses = ConvoScreen:new {
	id = "m4_retry_excuses",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1530dc31", -- Save your excuses!  The General must never arrive!  Do you understand?  Go to the Dathomir system and destroy his ship.  NOW!
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_retry_excuses)

vrke_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/naboo_imperial_tier3:s_4b5066f2", -- Well done, %TU. You have the makings of a true Inquisitor. When assigned a task you follow through with determination and focus. It is now clear to me that the late Colonel Hend was working with someone else.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b9b27823", "m1_reward_7b9c0b3e"}, -- Thank you.
		{"@conversation/naboo_imperial_tier3:s_af70dc3", "m1_reward_c66cd0c9"}, -- Why do you think someone was helping Colonel Hend?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward)

vrke_convo_m1_reward_7b9c0b3e = ConvoScreen:new {
	id = "m1_reward_7b9c0b3e",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7b9c0b3e", -- Maybe I was mistaken. I tell you that I do not think Colonel Hend was working alone and all you notice is that I complemented you? Vanity has no place in the Inquisition! A good Inquisitor is nothing more than a tool for the Emperor, and tools have no ego. Never make the mistake of forgetting that, pilot.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b02effe8", "m1_reward_dc30826"}, -- Sorry, Inquisitor. I wasn't thinking clearly.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_7b9c0b3e)

vrke_convo_m1_reward_c66cd0c9 = ConvoScreen:new {
	id = "m1_reward_c66cd0c9",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c66cd0c9", -- The data you recovered is highly classified. Well above Colonel Hend's security clearance. The data was also put together rather roughly, almost like it was coming from someone's memory rather than official documentation.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_876396db", "m1_reward_371288aa"}, -- What was in the data?
		{"@conversation/naboo_imperial_tier3:s_f6f34e7b", "m1_reward_9df61e25"}, -- Someone in the engineering corps, perhaps?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_c66cd0c9)

vrke_convo_m1_reward_dc30826 = ConvoScreen:new {
	id = "m1_reward_dc30826",
	leftDialog = "@conversation/naboo_imperial_tier3:s_dc30826", -- I sometimes wonder if you ever think at all.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_bd61dda4", "m1_reward_c66cd0c9"}, -- What did you learn from the data I recovered?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_dc30826)

vrke_convo_m1_reward_371288aa = ConvoScreen:new {
	id = "m1_reward_371288aa",
	leftDialog = "@conversation/naboo_imperial_tier3:s_371288aa", -- If the data was classified higher than Colonel Hend's, the head of security on the project, clearance, what makes you think that you would have access to the information?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a729151d", "m1_reward_f5cc022d"}, -- If I knew what was in the data, it would help with the investigation.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_371288aa)

vrke_convo_m1_reward_9df61e25 = ConvoScreen:new {
	id = "m1_reward_9df61e25",
	leftDialog = "@conversation/naboo_imperial_tier3:s_9df61e25", -- That is what we believe. But who are we looking for? I think the answer to that question is on Yavin 4. I want you to go to the Imperial post on Yavin 4 and speak with Lieutenant Colonel Barlow.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_421e1b5d", "m1_reward_e8f655d8"}, -- Who is Lieutenant Colonel Barlow?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_9df61e25)

vrke_convo_m1_reward_f5cc022d = ConvoScreen:new {
	id = "m1_reward_f5cc022d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f5cc022d", -- Very true, but rules are rules, even for Inquisitors. Allow me to put it this way. Colonel Hend was in charge of security for the Death Star salvage operation. Many of the engineers who worked on the Death Star project are involved in the salvage operation. What do you think these people know that the Rebels would be so interested in getting their hands on?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_5b3ded86", "m1_reward_c682a578"}, -- I don't know. That is why I was asking you.
		{"@conversation/naboo_imperial_tier3:s_60e5259e", "m1_reward_47424e40"}, -- I completely understand.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_f5cc022d)

vrke_convo_m1_reward_e8f655d8 = ConvoScreen:new {
	id = "m1_reward_e8f655d8",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e8f655d8", -- He was Colonel Hend's second in command, and now that Hend is no longer with us, he has been promoted to his superior's old position.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_ee54dcb9", "m1_reward_46423ae4"}, -- Do you think he was involved?
		{"@conversation/naboo_imperial_tier3:s_b3b2214d", "m1_reward_b49d8273"}, -- Why do I need to speak with him?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_e8f655d8)

vrke_convo_m1_reward_c682a578 = ConvoScreen:new {
	id = "m1_reward_c682a578",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c682a578", -- Must I lead you around by the nose in order for you to read between the lines? If you cannot figure things out for yourself then I cannot use you. I would advise that you get your act together or I will have to open up an investigation about a missing pilot.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_73ffc0a4", "m1_reward_cb22323f"}, -- There will not be any need for that, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_c682a578)

vrke_convo_m1_reward_47424e40 = ConvoScreen:new {
	id = "m1_reward_47424e40",
	leftDialog = "@conversation/naboo_imperial_tier3:s_47424e40", -- It is good to see that you are able to read between the lines. You are learning some of the valuable skills that make a good Inquisitor. I think that it is time to put some of your skills to good use. I want you to go to our outpost on Yavin 4 and talk to Lieutenant Colonel Barlow.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_421e1b5d", "m1_reward_e8f655d8"}, -- Who is Lieutenant Colonel Barlow?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_47424e40)

vrke_convo_m1_reward_46423ae4 = ConvoScreen:new {
	id = "m1_reward_46423ae4",
	leftDialog = "@conversation/naboo_imperial_tier3:s_46423ae4", -- After we discovered that Hend was a traitor we questioned all who were stationed under him. We could not find any wrong doing on the part of the Lieutenant Colonel and have no reason to believe that he was involved in his commander's treachery. Frankly, Barlow doesn't have the imagination to be a traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_f8a8c2d0", "m1_reward_1fe8c0f8"}, -- Can you be sure? Isn't it dangerous to have him head of security for that operation?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_46423ae4)

vrke_convo_m1_reward_b49d8273 = ConvoScreen:new {
	id = "m1_reward_b49d8273",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b49d8273", -- We are fairly certain that the Lieutenant Colonel is free from guilt in the matter of Hend's treachery but that doesn't mean he is not aware of details that could help our investigation. I want you to question Barlow about Colonel Hend's activities. Who did he deal with in the Engineering corps? Did he have any private meetings with any of them? What did Hend do in his spare time? Basically, I want you to find out everything you can about Hend.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_6750e334", "m1_training"}, -- I see. Barlow might be aware of the other traitor and not know it.
		{"@conversation/naboo_imperial_tier3:s_a5beec1f", "m1_reward_30281933"}, -- Don't you know everything about Hend already?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_b49d8273)

vrke_convo_m1_reward_cb22323f = ConvoScreen:new {
	id = "m1_reward_cb22323f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_cb22323f", -- I hope there isn't. You have talent and I would hate to see it go to waste. Like I was saying, we believe that Colonel Hend had a cohort and we suspect that this cohort worked in the Engineering corps. You need to go to our outpost on Yavin 4 and talk to Lieutenant Colonel Barlow about this matter.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_421e1b5d", "m1_reward_e8f655d8"}, -- Who is Lieutenant Colonel Barlow?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_cb22323f)

vrke_convo_m1_reward_1fe8c0f8 = ConvoScreen:new {
	id = "m1_reward_1fe8c0f8",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1fe8c0f8", -- Lieutenant Colonel Barlow will not be allowed to hold his position for very long. I just fear that his health will take a turn for the worst in the near future. But for now he is the best available officer for the position.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b3b2214d", "m1_reward_b49d8273"}, -- Why do I need to speak with him?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_1fe8c0f8)

vrke_convo_m1_training = ConvoScreen:new {
	id = "m1_training",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e56fb28", -- Yes. Now you are catching on. Before you go, you will need to learn a new skill that might assist you in your investigation. I will offer you my expertise in helping you become a better pilot. Do you have any particular skill in mind?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m1_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m1_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m1_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m1_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_training)

vrke_convo_m1_reward_30281933 = ConvoScreen:new {
	id = "m1_reward_30281933",
	leftDialog = "@conversation/naboo_imperial_tier3:s_30281933", -- How can anyone know everything about a man? There are secrets that we even hide from ourselves. But in this case, I care nothing about Hend except who he was getting his information from. The answer is out there, Hend wasn't skilled enough to hide from us and neither is his ally. You will find it.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_180340a", "m1_training_best"}, -- I will do my best, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_reward_30281933)

vrke_convo_m1_trained_starships = ConvoScreen:new {
	id = "m1_trained_starships",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5a27cd7a", -- Very well. I will teach you about Imperial technology. Now you have your mission. Go question Lieutenant Colonel Barlow at our outpost on Yavin 4 about the traitor Hend. Find us a lead on who Hend was working with. You may leave me now.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_trained_starships)

vrke_convo_m1_trained_weapons = ConvoScreen:new {
	id = "m1_trained_weapons",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a3dbeea3", -- Very well. I will teach you about Imperial equipment. Now you have your mission. Go question Lieutenant Colonel Barlow at our outpost on Yavin 4 about the traitor Hend. Find us a lead on who Hend was working with. You may leave me now.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_trained_weapons)

vrke_convo_m1_trained_procedures = ConvoScreen:new {
	id = "m1_trained_procedures",
	leftDialog = "@conversation/naboo_imperial_tier3:s_96871003", -- Very well. I will teach you about Imperial training. Now you have your mission. Go question Lieutenant Colonel Barlow at our outpost on Yavin 4 about the traitor Hend. Find us a lead on who Hend was working with. You may leave me now.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_trained_procedures)

vrke_convo_m1_trained_droid = ConvoScreen:new {
	id = "m1_trained_droid",
	leftDialog = "@conversation/naboo_imperial_tier3:s_eb077a31", -- Very well. I will teach you droid management. Now you have your mission. Go question Lieutenant Colonel Barlow at our outpost on Yavin 4 about the traitor Hend. Find us a lead on who Hend was working with. You may leave me now.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_trained_droid)

vrke_convo_m1_training_best = ConvoScreen:new {
	id = "m1_training_best",
	leftDialog = "@conversation/naboo_imperial_tier3:s_14c5b74e", -- For your sake, I hope your best is good enough. But perhaps I can help you become a little bit better. Allow me to offer you my expertise to make you a better pilot. I will train you in one of your important pilot skills. Is there any particular skill that you would like to learn?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m1_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m1_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m1_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m1_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_training_best)

vrke_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/naboo_imperial_tier3:s_89772a9c", -- You have performed better than my expectations. The doctor is safely in our custody and we have plenty of evidence to assist us in questioning him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_e2f46aa7", "m2_reward_8403cf96"}, -- What is going to happen to Shinss?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward)

vrke_convo_m2_reward_8403cf96 = ConvoScreen:new {
	id = "m2_reward_8403cf96",
	leftDialog = "@conversation/naboo_imperial_tier3:s_8403cf96", -- That remains to be determined. I have not yet had a chance to chat with him. His guilt is not in question but it is important for us to make sure that there is no one else involved. There is a slight chance that he will simply be terminated but it would be a shame to execute such a brilliant and useful man.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_dfb757ef", "m2_reward_c102f303"}, -- Why keep him alive?
		{"@conversation/naboo_imperial_tier3:s_ac0524e5", "m2_reward_b4ee5a51"}, -- Someone else is involved?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_8403cf96)

vrke_convo_m2_reward_c102f303 = ConvoScreen:new {
	id = "m2_reward_c102f303",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c102f303", -- Doctor Shinss has one of the finest technical minds in all of the Empire. It was his work that led to the creation of the power cells used in the Death Star's primary weapon. You never know when a man of such intelligence can be of use again.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_383b4c1a", "m2_reward_10a23848"}, -- You would allow a traitor to work for the Empire again?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_c102f303)

vrke_convo_m2_reward_b4ee5a51 = ConvoScreen:new {
	id = "m2_reward_b4ee5a51",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b4ee5a51", -- Perhaps. Shinss certainly had access to the information that Colonel Hend was passing to the Rebellion. On the surface everything would appear to have been wrapped up in a tight little package. But I learned long ago to never believe anything that I hear and only believe half of what I see.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_92089a98", "m2_reward_91dcaa8e"}, -- That is sound thinking.
		{"@conversation/naboo_imperial_tier3:s_e9e86c08", "m2_reward_927126c5"}, -- Sounds like a pretty skeptical way to go through life.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_b4ee5a51)

vrke_convo_m2_reward_10a23848 = ConvoScreen:new {
	id = "m2_reward_10a23848",
	leftDialog = "@conversation/naboo_imperial_tier3:s_10a23848", -- I make no qualms about using anyone to further our goals. In a very controlled environment, I think that Doctor Shinss can still be of use to the Empire. Of course, this is just idle chatter. I must conduct my interview with Shinss before a final determination can be made.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_92a79510", "m2_training"}, -- So what should I do now?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_10a23848)

vrke_convo_m2_reward_91dcaa8e = ConvoScreen:new {
	id = "m2_reward_91dcaa8e",
	leftDialog = "@conversation/naboo_imperial_tier3:s_91dcaa8e", -- Of course it is. If the doctor had other friends in the Empire I will find out who they are. After that, I will determine the fate of Doctor Shinns.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_4dbbef78", "m2_reward_c102f303"}, -- Why not just eliminate him?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_91dcaa8e)

vrke_convo_m2_reward_927126c5 = ConvoScreen:new {
	id = "m2_reward_927126c5",
	leftDialog = "@conversation/naboo_imperial_tier3:s_927126c5", -- I hardly need approval from the likes of you for my life's philosophies. You forget that I have years of experience and knowledge that you will probably never possess. Just because I have bestowed some measure of favor on you does not make us friends.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_fffa7b3b", "m2_reward_b73943f"}, -- Of course not, Inquisitor.
		{"@conversation/naboo_imperial_tier3:s_6dec7910", "m2_reward_b61f3237"}, -- Perhaps you can tell me something about Doctor Shinss.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_927126c5)

vrke_convo_m2_training = ConvoScreen:new {
	id = "m2_training",
	leftDialog = "@conversation/naboo_imperial_tier3:s_138af3f9", -- For now you may go on leave. I am not certain how long I shall be detained with the doctor. Some people break very easily, others require some...effort. But before you go I would again like to offer my services as a trainer to you. Is there any particular skill you would like to learn?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m2_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m2_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m2_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m2_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_training)

vrke_convo_m2_reward_b73943f = ConvoScreen:new {
	id = "m2_reward_b73943f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b73943f", -- What! Are you saying that I am not good enough to be your friend? Am I just a pawn that you are planning to use in order to gain power within the ranks? Well? Speak up!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_24a28f9e", "m2_reward_a3921d3c"}, -- Uh...how about the weather we are having?
		{"@conversation/naboo_imperial_tier3:s_c4f95dc7", "m2_reward_c39bdaeb"}, -- I didn't mean it that way.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_b73943f)

vrke_convo_m2_reward_b61f3237 = ConvoScreen:new {
	id = "m2_reward_b61f3237",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b61f3237", -- So you decided to change the subject. You do have some measure of wisdom. Very well. Doctor Shinss has one of the finest technical minds in all of the Empire. It was his work that led to the creation of the power cells used in the Death Star's primary weapon. You never know when a man of such intelligence can be of use again.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_383b4c1a", "m2_reward_10a23848"}, -- You would allow a traitor to work for the Empire again?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_b61f3237)

vrke_convo_m2_trained_starships = ConvoScreen:new {
	id = "m2_trained_starships",
	leftDialog = "@conversation/naboo_imperial_tier3:s_231aa1cb", -- Imperial technology it is. I will instruct you. Come see me a little later and perhaps I will have some news about how my discussion with the doctor went.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_trained_starships)

vrke_convo_m2_trained_weapons = ConvoScreen:new {
	id = "m2_trained_weapons",
	leftDialog = "@conversation/naboo_imperial_tier3:s_adf8c646", -- Imperial equipment; always useful. Let's begin. Come see me a little later and perhaps I will have some news about how my discussion with the doctor went.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_trained_weapons)

vrke_convo_m2_trained_procedures = ConvoScreen:new {
	id = "m2_trained_procedures",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e73bd99d", -- Interesting choice. I will teach you. Come see me a little later and perhaps I will have some news about how my discussion with the doctor went.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_trained_procedures)

vrke_convo_m2_trained_droid = ConvoScreen:new {
	id = "m2_trained_droid",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d61b10cc", -- I, too, enjoy astromech management. I'll teach you what I know. Come see me a little later and perhaps I will have some news about how my discussion with the doctor went.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_trained_droid)

vrke_convo_m2_reward_a3921d3c = ConvoScreen:new {
	id = "m2_reward_a3921d3c",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a3921d3c", -- You seemed to have made a joke. Most amusing. Perhaps I will not have your transferred to investigating the wonders of Dathomir prison after all. Since I am in such a forgiving mood, I think now would be a good time to get back to matters at hand.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_64e8db24", "m2_reward_c102f303"}, -- Ok, can you tell me a bit about Doctor Shinss?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_a3921d3c)

vrke_convo_m2_reward_c39bdaeb = ConvoScreen:new {
	id = "m2_reward_c39bdaeb",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c39bdaeb", -- Then say what you mean! You will find we will get along much better if you pay attention and present useful ideas to me.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_8a631324", "m2_reward_c102f303"}, -- Yes, Inquisitor. I will try. About Doctor Shinss?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_reward_c39bdaeb)

vrke_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a7addb41", -- Just as I expected. The guilty parties come crawling out of the gutters to try to hide their names from us. It is always amusing to me to watch them start to panic when we begin to move in. You can almost smell the desperation.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_15ab633c", "m3_reward_596a67f0"}, -- So we are sure that Hend and Shinss were not working alone?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward)

vrke_convo_m3_reward_596a67f0 = ConvoScreen:new {
	id = "m3_reward_596a67f0",
	leftDialog = "@conversation/naboo_imperial_tier3:s_596a67f0", -- Oh yes, very much so. The rebel plans that you returned to us reveal much. Just as we expected the rebels were tipped off about your mission and had orders to protect their remaining agent at all costs.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_ed0f2b93", "m3_reward_bff840a0"}, -- So we know who the remaining agent is?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_596a67f0)

vrke_convo_m3_reward_bff840a0 = ConvoScreen:new {
	id = "m3_reward_bff840a0",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bff840a0", -- No. Even the Rebels wouldn't be foolish enough to name their agent in an order. But it does confirm our suspicion that Hend and Shinss were not working alone. We might have to use extreme measures to get Shinss to tell us who the third traitor is.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_82abf7e1", "m3_reward_d73be201"}, -- Extreme measures?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_bff840a0)

vrke_convo_m3_reward_d73be201 = ConvoScreen:new {
	id = "m3_reward_d73be201",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d73be201", -- Something that we use only as a last resort. It tends to have adverse effects on the neural paths in the brain. Most subjects survive the process but in an extreme vegetated state but it never fails to expose all of their secrets. It is actually quite fascinating.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_280b5512", "m3_reward_6db39b2b"}, -- I thought we wanted to keep Shinss alive?
		{"@conversation/naboo_imperial_tier3:s_b72f1079", "m3_reward_61fa7c14"}, -- It sounds very interesting.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_d73be201)

vrke_convo_m3_reward_6db39b2b = ConvoScreen:new {
	id = "m3_reward_6db39b2b",
	leftDialog = "@conversation/naboo_imperial_tier3:s_6db39b2b", -- We would only use it on Shinss as an absolute last resort. But unless we can figure out who the third traitor is, I fear that we will have no other choice. Do you have any suggestions?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7ef46a67", "m3_reward_ca264df9"}, -- Shinss was running to Dathomir. Maybe his ally is there.
		{"@conversation/naboo_imperial_tier3:s_e70ed5c9", "m3_reward_bb627418"}, -- How about another fake list of names?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_6db39b2b)

vrke_convo_m3_reward_61fa7c14 = ConvoScreen:new {
	id = "m3_reward_61fa7c14",
	leftDialog = "@conversation/naboo_imperial_tier3:s_61fa7c14", -- Yes, quite. Most interesting process really. We start with a slight insertion into the frontal lobe. Followed by a...the process doesn't matter. Let's just say that it is rather intense. But I would prefer not to let things come to that. I am sure that there is something I am overlooking.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7ef46a67", "m3_reward_ca264df9"}, -- Shinss was running to Dathomir. Maybe his ally is there.
		{"@conversation/naboo_imperial_tier3:s_e70ed5c9", "m3_reward_bb627418"}, -- How about another fake list of names?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_61fa7c14)

vrke_convo_m3_reward_ca264df9 = ConvoScreen:new {
	id = "m3_reward_ca264df9",
	leftDialog = "@conversation/naboo_imperial_tier3:s_ca264df9", -- Interesting. I figured he was meeting up with the Rebellion but what if he was actually trying to meet with his fellow conspirator? We only keep a small security force in the region in order to patrol the outskirts of the system. It would have to be a person of authority. I think that your idea is at least worth investigating.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1954fa73", "m3_training"}, -- What should I do in the meantime?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_ca264df9)

vrke_convo_m3_reward_bb627418 = ConvoScreen:new {
	id = "m3_reward_bb627418",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bb627418", -- Do you honestly think that the enemy is so stupid that they would fall for that again? They only fell for the ploy the first time because we moved quickly and kept them panicked. No, there is something else that I am missing. Dathomir...Dathomir...he wasn't going to Dathomir to meet up with the Rebellion, he was going to meet up with his ally!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_f7b0b9b0", "m3_reward_50c0b15c"}, -- How can you be certain?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_bb627418)

vrke_convo_m3_training = ConvoScreen:new {
	id = "m3_training",
	leftDialog = "@conversation/naboo_imperial_tier3:s_42fdfb8d", -- For now you are dismissed, I will be in need of your services again shortly though. Oh, and before you go let me teach you some more skills. You will probably have need of that training in the future. Is there anything you wish to learn?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m3_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m3_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m3_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m3_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_training)

vrke_convo_m3_reward_50c0b15c = ConvoScreen:new {
	id = "m3_reward_50c0b15c",
	leftDialog = "@conversation/naboo_imperial_tier3:s_50c0b15c", -- Nothing is ever certain. But I have been doing this for long enough to know to follow my instincts. Right now my instincts are telling me our target is in Dathomir. It is at least something to look into before we ruin one of the finest minds in the galaxy.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_57c8489e", "m3_training"}, -- What should I do?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_reward_50c0b15c)

vrke_convo_m3_trained_starships = ConvoScreen:new {
	id = "m3_trained_starships",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a112be1b", -- Imperial technology it is. I will instruct you. Check in with me after I have had a chance to look into this Dathomir lead. I might have use for a pilot at that time.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_trained_starships)

vrke_convo_m3_trained_weapons = ConvoScreen:new {
	id = "m3_trained_weapons",
	leftDialog = "@conversation/naboo_imperial_tier3:s_590440bf", -- Imperial equipment; always useful. Let's begin. Check in with me after I have had a chance to look into this Dathomir lead. I might have use for a pilot at that time.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_trained_weapons)

vrke_convo_m3_trained_procedures = ConvoScreen:new {
	id = "m3_trained_procedures",
	leftDialog = "@conversation/naboo_imperial_tier3:s_8fbd0301", -- Interesting choice. I will teach you. Check in with me after I have had a chance to look into this Dathomir lead. I might have use for a pilot at that time.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_trained_procedures)

vrke_convo_m3_trained_droid = ConvoScreen:new {
	id = "m3_trained_droid",
	leftDialog = "@conversation/naboo_imperial_tier3:s_cb94834e", -- I, too, enjoy astromech management. Check in with me after I have had a chance to look into this Dathomir lead. I might have use for a pilot at that time.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_trained_droid)

vrke_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5df75ba2", -- Again you have surprised me. I am very impressed with the way you handled yourself in a most difficult situation. General Breckon has been eliminated and the Rebels have been shown the mistake of trying to cross the Imperial Inquisition.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b6e7132e", "m4_reward_282a5395"}, -- I was only doing my duty.
		{"@conversation/naboo_imperial_tier3:s_da4bf33c", "m4_reward_cf7b4157"}, -- That is because I am the best.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward)

vrke_convo_m4_reward_282a5395 = ConvoScreen:new {
	id = "m4_reward_282a5395",
	leftDialog = "@conversation/naboo_imperial_tier3:s_282a5395", -- I must admit I had my doubts about you but one day I am sure you will make a fine addition to the ranks of the Inquisitors. You performed admirably in a difficult situation.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_eec10bf5", "m4_reward_d8d73e21"}, -- Is there any backlash about General Breckon?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_282a5395)

vrke_convo_m4_reward_cf7b4157 = ConvoScreen:new {
	id = "m4_reward_cf7b4157",
	leftDialog = "@conversation/naboo_imperial_tier3:s_cf7b4157", -- You arrogant whelp. You are nothing without the might and power of the Inquisition backing you. Do you think that you would have had any chance of success without the training that I so graciously offered to you? Just being able to say that you work for the Imperial Inquisition alone probably won you half your battles.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_baab1c4d", "m4_reward_35462f38"}, -- I didn't mean I was more important then the Inquisition.
		{"@conversation/naboo_imperial_tier3:s_3ced8a4e", "m4_training_bah"}, -- But I am the best.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_cf7b4157)

vrke_convo_m4_reward_d8d73e21 = ConvoScreen:new {
	id = "m4_reward_d8d73e21",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d8d73e21", -- There would be if anyone had evidence of what really happened. But everyone is simply willing to accept that General Breckon had a tragic accident on his way to Naboo. Of course, we are still working on the official report but no one is going to demand explanations on this one.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1d8714f1", "m4_reward_2fd0e3dd"}, -- Isn't the Army mad about the loss of a general?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_d8d73e21)

vrke_convo_m4_reward_35462f38 = ConvoScreen:new {
	id = "m4_reward_35462f38",
	leftDialog = "@conversation/naboo_imperial_tier3:s_35462f38", -- I should hope not. I wouldn't want to think less of you after you were coming along so nicely. The way you eliminated General Breckon and his allies was a thing of beauty.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_eec10bf5", "m4_reward_d8d73e21"}, -- Is there any backlash about General Breckon?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_35462f38)

vrke_convo_m4_training_bah = ConvoScreen:new {
	id = "m4_training_bah",
	leftDialog = "@conversation/naboo_imperial_tier3:s_85eab9a", -- Bah! I am done with you. I can no longer use someone like you. I have one last thing to teach you and, believe me, if I wasn't under orders to make you the best pilot I could I certainly wouldn't teach it to you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m4_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m4_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m4_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m4_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_training_bah)

vrke_convo_m4_reward_2fd0e3dd = ConvoScreen:new {
	id = "m4_reward_2fd0e3dd",
	leftDialog = "@conversation/naboo_imperial_tier3:s_2fd0e3dd", -- The Army is happy to be rid of him without having to explain why they did not discover the traitorous activities of two high ranking officials. Of course, they know that the Inquisition let them avoid embarrassment, so in the future we will have an advantage when dealing with them. One hand washes the other.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_25317705", "m4_reward_9d83e334"}, -- So this was all about politics?
		{"@conversation/naboo_imperial_tier3:s_a2078b19", "m4_reward_ab7d0c2d"}, -- Having an advantage over the other branches could be useful.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_2fd0e3dd)

vrke_convo_m4_trained_starships = ConvoScreen:new {
	id = "m4_trained_starships",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d05c3a79", -- Imperial technology it is. I will instruct you. Report back to me when you are prepared to undertake your next assignment.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_trained_starships)

vrke_convo_m4_trained_weapons = ConvoScreen:new {
	id = "m4_trained_weapons",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bfcce26a", -- Imperial equipment; always useful. Let's begin. Report back to me when you are prepared to undertake your next assignment.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_trained_weapons)

vrke_convo_m4_trained_procedures = ConvoScreen:new {
	id = "m4_trained_procedures",
	leftDialog = "@conversation/naboo_imperial_tier3:s_4c42a50e", -- Interesting choice. I will teach you. Report back to me when you are prepared to undertake your next assignment.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_trained_procedures)

vrke_convo_m4_trained_droid = ConvoScreen:new {
	id = "m4_trained_droid",
	leftDialog = "@conversation/naboo_imperial_tier3:s_9016869", -- I, too, enjoy astromech management. Report back to me when you are prepared to undertake your next assignment.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_trained_droid)

vrke_convo_m4_reward_9d83e334 = ConvoScreen:new {
	id = "m4_reward_9d83e334",
	leftDialog = "@conversation/naboo_imperial_tier3:s_9d83e334", -- As long as the Inquisition has the favor of the Emperor we are above politics. But the Emperor, in all his wisdom, has been known to abruptly change his mind. It is just smart to make sure we are prepared should that ever happen. But to answer your question...no. Our primary mission is to root out traitors inside of the Empire and that is what we have done. If we can turn that into our advantage then even better.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_81cf364c", "m4_training"}, -- That does make sense.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_9d83e334)

vrke_convo_m4_reward_ab7d0c2d = ConvoScreen:new {
	id = "m4_reward_ab7d0c2d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_ab7d0c2d", -- Indeed it is. It allows us far more room to operate and perform our primary function, finding and eliminating traitors from within. And we make the most of any advantage that we have. The Army will regret this whole incident for years to come, I can assure you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_ef85b67c", "m4_training"}, -- That makes sense.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_reward_ab7d0c2d)

vrke_convo_m4_training = ConvoScreen:new {
	id = "m4_training",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e331634e", -- Yes it does. You have learned much from me but I think there is still something else that I have to teach you. What would you like to learn?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40cda759", "m4_trained_starships"}, -- Teach me about advanced capability TIE vessels.
		{"@conversation/naboo_imperial_tier3:s_a9aeb386", "m4_trained_weapons"}, -- Teach me about advanced starship component use.
		{"@conversation/naboo_imperial_tier3:s_ef7a2df5", "m4_trained_procedures"}, -- Teach me about special forces training.
		{"@conversation/naboo_imperial_tier3:s_473d09d8", "m4_trained_droid"}, -- Teach me about system balance programming.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_training)

vrke_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5d47c3ad", -- I understand you served under Inquisitor Fa'Zoll.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_4d169c0a", "m1_offer_d1f39329"}, -- [describe last mission]
		{"@conversation/naboo_imperial_tier3:s_8d10c144", "m1_offer_57d605af"}, -- [no response]
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer)

vrke_convo_m1_offer_d1f39329 = ConvoScreen:new {
	id = "m1_offer_d1f39329",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d1f39329", -- Yes. I've heard of you. Tell me, did you enjoy it?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_2b08b3c4", "m1_offer_2015270f"}, -- I'm glad to serve the Empire.
		{"@conversation/naboo_imperial_tier3:s_e65df49", "m1_offer_a16f3f3d"}, -- I wish I could have killed more Rebels.
		{"@conversation/naboo_imperial_tier3:s_4c695dbd", "m1_offer_2fe1cf2f"}, -- No.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_d1f39329)

vrke_convo_m1_offer_57d605af = ConvoScreen:new {
	id = "m1_offer_57d605af",
	leftDialog = "@conversation/naboo_imperial_tier3:s_57d605af", -- You must speak when you are spoken to. It is only polite. Tell me, are you loyal to the Empire?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7a8608b9", "m1_offer_1d7660ea"}, -- I serve the Emperor.
		{"@conversation/naboo_imperial_tier3:s_4a796b5a", "m1_offer_e3e0a092"}, -- I hate the Rebellion.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_57d605af)

vrke_convo_m1_offer_2015270f = ConvoScreen:new {
	id = "m1_offer_2015270f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_2015270f", -- Very good. I have a job for you. Since you were there, you probably don't need me to tell you who Colonel Hend is.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3a77410f", "m1_offer_3f29cff4"}, -- Who is Colonel Hend?
		{"@conversation/naboo_imperial_tier3:s_204207", "m1_offer_e90f4f67"}, -- Yeah, I had the misfortune of dealing with him.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_2015270f)

vrke_convo_m1_offer_a16f3f3d = ConvoScreen:new {
	id = "m1_offer_a16f3f3d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a16f3f3d", -- You will get your chance. Of course, you have heard of Colonel Hend, how he had betrayed the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_d70dba34", "m1_offer_d2a2c5a9"}, -- Yes.
		{"@conversation/naboo_imperial_tier3:s_4103a0b8", "m1_offer_2fe1cf2f"}, -- No.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_a16f3f3d)

vrke_convo_m1_offer_2fe1cf2f = ConvoScreen:new {
	id = "m1_offer_2fe1cf2f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_2fe1cf2f", -- An unexpected answer. Perhaps you will find this posting more to your liking. Of course, you know about Colonel Hend...especially since you were the one who eliminated our problem for us.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3a77410f", "m1_offer_3f29cff4"}, -- Who is Colonel Hend?
		{"@conversation/naboo_imperial_tier3:s_204207", "m1_offer_e90f4f67"}, -- Yeah, I had the misfortune of dealing with him.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_2fe1cf2f)

vrke_convo_m1_offer_1d7660ea = ConvoScreen:new {
	id = "m1_offer_1d7660ea",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1d7660ea", -- As do we all. The Emperor has a very important mission for you. Of course, you of all people are aware of Colonel Hend's treachery?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3a77410f", "m1_offer_3f29cff4"}, -- Who is Colonel Hend?
		{"@conversation/naboo_imperial_tier3:s_204207", "m1_offer_e90f4f67"}, -- Yeah, I had the misfortune of dealing with him.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_1d7660ea)

vrke_convo_m1_offer_e3e0a092 = ConvoScreen:new {
	id = "m1_offer_e3e0a092",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e3e0a092", -- That is not quite the same as loyalty.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_e5235eff", "m1_offer_51edad38"}, -- Do you have a mission for me?
		{"@conversation/naboo_imperial_tier3:s_d24850e1", "m1_offer_fd9fd112"}, -- It's not?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_e3e0a092)

vrke_convo_m1_offer_3f29cff4 = ConvoScreen:new {
	id = "m1_offer_3f29cff4",
	leftDialog = "@conversation/naboo_imperial_tier3:s_3f29cff4", -- Hmmm, it would seem that either you have a very short term memory or are very good at forgetting things better left forgotten. If it is the first, you will not last for very long. If it is the latter, you might just go far.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_105d3df0", "m1_offer_d2a2c5a9"}, -- About Colonel Hend?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_3f29cff4)

vrke_convo_m1_offer_e90f4f67 = ConvoScreen:new {
	id = "m1_offer_e90f4f67",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e90f4f67", -- The Empire owes you a small debt for eliminating that most embarrassing colonel. Unfortunately for the Empire, we do not believe that he worked alone. The simple fact of the matter is that while he was in charge of security on our new special project, there was information leaked that even he did not have access to.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_531dcb5b", "m1_offer_1aa7b517"}, -- Interesting. So you think he was working with someone?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_e90f4f67)

vrke_convo_m1_offer_d2a2c5a9 = ConvoScreen:new {
	id = "m1_offer_d2a2c5a9",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d2a2c5a9", -- As I am sure you know, he has been eliminated for his traitorous activities. Unfortunately, for the Empire, we do not believe that he worked alone. The simple fact of the matter is that while he was in charge of security on our new special project, there was information leaked that even he did not have access to.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_531dcb5b", "m1_offer_1aa7b517"}, -- Interesting. So you think he was working with someone?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_d2a2c5a9)

vrke_convo_m1_offer_51edad38 = ConvoScreen:new {
	id = "m1_offer_51edad38",
	leftDialog = "@conversation/naboo_imperial_tier3:s_51edad38", -- Ah. Yes. You are eager to begin. You, of course, know of Colonel Hend.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3a77410f", "m1_offer_3f29cff4"}, -- Who is Colonel Hend?
		{"@conversation/naboo_imperial_tier3:s_204207", "m1_offer_e90f4f67"}, -- Yeah, I had the misfortune of dealing with him.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_51edad38)

vrke_convo_m1_offer_fd9fd112 = ConvoScreen:new {
	id = "m1_offer_fd9fd112",
	leftDialog = "@conversation/naboo_imperial_tier3:s_fd9fd112", -- Loyalty is very important. Colonel Hend betrayed  the Empire. And as you surely know, he paid the price for that treachery.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3a77410f", "m1_offer_3f29cff4"}, -- Who is Colonel Hend?
		{"@conversation/naboo_imperial_tier3:s_204207", "m1_offer_e90f4f67"}, -- Yeah, I had the misfortune of dealing with him.
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_fd9fd112)

vrke_convo_m1_offer_1aa7b517 = ConvoScreen:new {
	id = "m1_offer_1aa7b517",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1aa7b517", -- Or for someone. We try not to make too many assumptions but we are very confident that the answers are out there. One must be diligent in the search for the truth. But I digress. There is an important task that I need you to do. Given your background in this matter I can think of no one better suited to assist me than you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b266743b", "m1_offer_1bf6b48e"}, -- I appreciate the vote of confidence. What is it I can do for you?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_1aa7b517)

vrke_convo_m1_offer_1bf6b48e = ConvoScreen:new {
	id = "m1_offer_1bf6b48e",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1bf6b48e", -- Earlier this morning, Colonel Hend's private yacht was removed from the space dock where it was stored. We believe that whoever stole the yacht is trying to cover up something that might have been hidden on that ship. Just twenty minutes ago a scanning vessel got a lock on the shuttle in the Naboo system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_3c31fee3", "m1_accept"}, -- So you want me to recover the yacht and bring it back to you?
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_offer_1bf6b48e)

vrke_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/naboo_imperial_tier3:s_3b3b356f", -- Correct. I think we can find out what we are looking for by cracking the ship's logs. The yacht has been gone long enough for the perpetrator to hide whatever they were trying to cover up, but perhaps not long enough to also delete the ship's logs. Now to your ship, pilot.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m1_accept)

vrke_convo_barlow_pending = ConvoScreen:new {
	id = "barlow_pending",
	leftDialog = "@conversation/naboo_imperial_tier3:s_577a942", -- Have you finished your questioning of Lieutenant Colonel Barlow about Colonel Hend?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_e35bf94e", "barlow_pending_53d34239"}, -- I couldn't get anything out of him.
		{"@conversation/naboo_imperial_tier3:s_69d78804", "barlow_pending_370a9fe4"}, -- Not yet. I will get to it soon though.
	}
}
vrke_convo_template:addScreen(vrke_convo_barlow_pending)

vrke_convo_barlow_pending_53d34239 = ConvoScreen:new {
	id = "barlow_pending_53d34239",
	leftDialog = "@conversation/naboo_imperial_tier3:s_53d34239", -- Then you are not trying hard enough. I suggest that you get to our outpost on Yavin 4 and talk to him again. There are answers to our questions. You just need to find them. Do not come back without those answers.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_barlow_pending_53d34239)

vrke_convo_barlow_pending_370a9fe4 = ConvoScreen:new {
	id = "barlow_pending_370a9fe4",
	leftDialog = "@conversation/naboo_imperial_tier3:s_370a9fe4", -- What are you waiting on? Believe me, you do not want to let this traitor escape because of procrastination. If I find out that you are not performing your duty to the utmost, you will spend the rest of your very short life in agonizing pain. Am I understood, pilot?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_bca78274", "barlow_pending_6ffd0979"}, -- Yes, quite clearly, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_barlow_pending_370a9fe4)

vrke_convo_barlow_pending_6ffd0979 = ConvoScreen:new {
	id = "barlow_pending_6ffd0979",
	leftDialog = "@conversation/naboo_imperial_tier3:s_6ffd0979", -- Good. Now get out of my sight, get to our outpost on Yavin 4, and question Barlow about Colonel Hend.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_barlow_pending_6ffd0979)

vrke_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b1d44e0a", -- So what did you learn from Barlow? Well, spit it out. I have been waiting for this information for too long already.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_4c5e3fb9", "m2_offer_76cdb911"}, -- I believe that Colonel Hend's accomplice was a Doctor Shinss.
		{"@conversation/naboo_imperial_tier3:s_726886dd", "m2_offer_bf06e3a1"}, -- Being scary and intimidating is harder than it looks.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer)

vrke_convo_m2_offer_76cdb911 = ConvoScreen:new {
	id = "m2_offer_76cdb911",
	leftDialog = "@conversation/naboo_imperial_tier3:s_76cdb911", -- Doctor Shinss? The same Doctor Shinss that is currently in charge of the Yavin 4 salvage operation?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a86d23d", "m2_offer_7859ec"}, -- Yes, Inquisitor. He is the only one who makes sense.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_76cdb911)

vrke_convo_m2_offer_bf06e3a1 = ConvoScreen:new {
	id = "m2_offer_bf06e3a1",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bf06e3a1", -- Yes, it takes years of practice to perfect the technique that we are renowned throughout the galaxy for. But I take it you managed to get a lead even though the interview didn't go quite as smoothly as you thought it would?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_4c5e3fb9", "m2_offer_76cdb911"}, -- I believe that Colonel Hend's accomplice was a Doctor Shinss.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_bf06e3a1)

vrke_convo_m2_offer_7859ec = ConvoScreen:new {
	id = "m2_offer_7859ec",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7859ec", -- He would certainly have the knowledge and the opportunity to leak the stolen information to Colonel Hend. This is would be most unfortunate for the Empire if it turns out to be true.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_40abff84", "m2_offer_82c168be"}, -- I am very certain that he is the traitor.
		{"@conversation/naboo_imperial_tier3:s_7f9d08e9", "m2_offer_120e3960"}, -- Why would it be unfortunate?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_7859ec)

vrke_convo_m2_offer_82c168be = ConvoScreen:new {
	id = "m2_offer_82c168be",
	leftDialog = "@conversation/naboo_imperial_tier3:s_82c168be", -- Then we must find the proof. We would have a hard time explaining ourselves if we arrest such an important man on conjecture. You will have to find more evidence to his guilt.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b9c39774", "m2_offer_a0c5cad7"}, -- Where should I start looking?
		{"@conversation/naboo_imperial_tier3:s_d5f6b830", "m2_offer_7579d1ec"}, -- I thought we arrested people for no reason all the time?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_82c168be)

vrke_convo_m2_offer_120e3960 = ConvoScreen:new {
	id = "m2_offer_120e3960",
	leftDialog = "@conversation/naboo_imperial_tier3:s_120e3960", -- Doctor Shinss is a brilliant scientist. His research actually led to the development of the Death Star's power cells. Not only is he in charge of the Yavin salvage operation, he is slated to begin work on a new project in the Endor system. We are going to need evidence if we will have any chance at proving his guilt.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b9c39774", "m2_offer_a0c5cad7"}, -- Where should I start looking?
		{"@conversation/naboo_imperial_tier3:s_1ba0129b", "m2_offer_f16b1b64"}, -- I could always plant some.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_120e3960)

vrke_convo_m2_offer_a0c5cad7 = ConvoScreen:new {
	id = "m2_offer_a0c5cad7",
	leftDialog = "@conversation/naboo_imperial_tier3:s_a0c5cad7", -- The Empire has granted Shinss a private vessel for use in his work. From what I understand Shinss considers the vessel a refuge of sorts. If there is anything to be found it will probably be in Shinss private logs on board.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_60cd6629", "m2_offer_212d1edc"}, -- They shouldn't be that hard to recover.
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_a0c5cad7)

vrke_convo_m2_offer_7579d1ec = ConvoScreen:new {
	id = "m2_offer_7579d1ec",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7579d1ec", -- Of course we do. But generally those people do not have any use to the Empire, so no one really cares all that much. When it comes to someone with some power, we need proof of their illegal activities.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b9c39774", "m2_offer_a0c5cad7"}, -- Where should I start looking?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_7579d1ec)

vrke_convo_m2_offer_f16b1b64 = ConvoScreen:new {
	id = "m2_offer_f16b1b64",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f16b1b64", -- I appreciate your zeal. And it certainly wouldn't be the first time that we decided to take matters into our own hands. But in this case I think it would be best if we actually see what there is to find.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a96d5aee", "m2_offer_a0c5cad7"}, -- Very well. Where should I start looking?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_f16b1b64)

vrke_convo_m2_offer_212d1edc = ConvoScreen:new {
	id = "m2_offer_212d1edc",
	leftDialog = "@conversation/naboo_imperial_tier3:s_212d1edc", -- That is what I am thinking. We are going to have to keep this operation quiet for the time being though. There is no need to alert anyone of our investigation of the doctor. You are going to have to travel to the Yavin system and inspect the vessel's logs.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7904d29b", "m2_offer_8fdf2b5d"}, -- Won't Shinss notice if I am inspecting his vessel?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_212d1edc)

vrke_convo_m2_offer_8fdf2b5d = ConvoScreen:new {
	id = "m2_offer_8fdf2b5d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_8fdf2b5d", -- Fortune is currently on our side. Although Shinss is in charge of the Yavin salvage operation, he is currently in the Endor system beginning work on his next project there. He was not allowed to take his personal craft on this trip so it is still out in the Yavin system. If he is involved with the traitors and was using this vessel as a meeting point, you can bet it is being watched. So we have to move quickly before we tip our hand.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_68bcbb36", "m2_offer_d3f5b32c"}, -- What is Shinss doing in Endor?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_8fdf2b5d)

vrke_convo_m2_offer_d3f5b32c = ConvoScreen:new {
	id = "m2_offer_d3f5b32c",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d3f5b32c", -- That is none of your concern. Right now all you should be concerned with is recovering those logs from Shinss' Yacht. Is that understood, %NU?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_37d7964e", "m2_accept"}, -- Absolutely, Inquisitor.
		{"@conversation/naboo_imperial_tier3:s_c9d5576a", "m2_accept_simple"}, -- Not really. What is exactly I need to do?
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_offer_d3f5b32c)

vrke_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f64e0998", -- Good. Now move quickly, get to the Yavin system, and inspect Shinss' personal logs. You have your mission, now go!
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_accept)

vrke_convo_m2_accept_simple = ConvoScreen:new {
	id = "m2_accept_simple",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f8176023", -- You were doing so well up until this point. It is so simple that I am sure even you cannot mess this up. You are what's called a pilot. Your job is to fly your ship where I tell you to. You are to fly your ship to the Yavin system. That is in space. Then you are to find Doctor Shinss' Yacht. A Yacht is a type of ship... in space. When you find his ship, inspect Doctor Shinss' personal logs. Now get out of here before I get angry.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m2_accept_simple)

vrke_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/naboo_imperial_tier3:s_ee0c7787", -- I have enjoyed my time with the Doctor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7673fc64", "m3_offer_6d43b1bf"}, -- I bet you didn't discuss science.
		{"@conversation/naboo_imperial_tier3:s_15cfb2c9", "m3_offer_714d54de"}, -- Did he enjoy it too?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer)

vrke_convo_m3_offer_6d43b1bf = ConvoScreen:new {
	id = "m3_offer_6d43b1bf",
	leftDialog = "@conversation/naboo_imperial_tier3:s_6d43b1bf", -- Actually, we did. He truly is a brilliant man. I have enjoyed our conversations.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_727d7649", "m3_offer_e64051dc"}, -- What has he told you?
		{"@conversation/naboo_imperial_tier3:s_674c302", "m3_offer_fdfe8d73"}, -- Are you done?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_6d43b1bf)

vrke_convo_m3_offer_714d54de = ConvoScreen:new {
	id = "m3_offer_714d54de",
	leftDialog = "@conversation/naboo_imperial_tier3:s_714d54de", -- He is no longer in any condition to answer you. But he has been most informative.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_157ab93b", "m3_offer_36aa6786"}, -- Are there other traitors in the Empire?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_714d54de)

vrke_convo_m3_offer_e64051dc = ConvoScreen:new {
	id = "m3_offer_e64051dc",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e64051dc", -- He has told me much about the Death Star. He also has told me that he hopes to live to see his family again.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_b987ef3b", "m3_offer_5400c2b8"}, -- Will he?
		{"@conversation/naboo_imperial_tier3:s_a365e485", "m3_offer_1d79fda2"}, -- I'm glad I'm not the Doctor.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_e64051dc)

vrke_convo_m3_offer_fdfe8d73 = ConvoScreen:new {
	id = "m3_offer_fdfe8d73",
	leftDialog = "@conversation/naboo_imperial_tier3:s_fdfe8d73", -- I am afraid so. It was not pretty.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_8b2f0509", "m3_offer_85db59ee"}, -- Did he tell you more about the conspiracy?
		{"@conversation/naboo_imperial_tier3:s_fcdfe482", "m3_offer_679b150d"}, -- What do Inquisitors do to people?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_fdfe8d73)

vrke_convo_m3_offer_36aa6786 = ConvoScreen:new {
	id = "m3_offer_36aa6786",
	leftDialog = "@conversation/naboo_imperial_tier3:s_36aa6786", -- He would not tell us. But the Rebels don't know that. We will pretend that we have a list of conspirators.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a3ae4cb", "m3_offer_46fbca74"}, -- What are you going to do with that list?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_36aa6786)

vrke_convo_m3_offer_5400c2b8 = ConvoScreen:new {
	id = "m3_offer_5400c2b8",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5400c2b8", -- He may live but I would wager that he never sees his family again. What he has NOT told me is the names of his co-conspirators. But I have a plan.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1c8bddbb", "m3_offer_fda4456d"}, -- What is it?
		{"@conversation/naboo_imperial_tier3:s_f8e71988", "m3_offer_31d4944f"}, -- I'm ready for my mission.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_5400c2b8)

vrke_convo_m3_offer_1d79fda2 = ConvoScreen:new {
	id = "m3_offer_1d79fda2",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1d79fda2", -- Yes. But now you have work to do.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1c8bddbb", "m3_offer_28876e4d"}, -- What is it?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_1d79fda2)

vrke_convo_m3_offer_85db59ee = ConvoScreen:new {
	id = "m3_offer_85db59ee",
	leftDialog = "@conversation/naboo_imperial_tier3:s_85db59ee", -- No. But the Rebels don't know that. We'll leak word that we have information. One thing that I did find interesting is that he mentioned the Dathomir system in passing, but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_ce4c8e17", "m3_offer_697ba4d3"}, -- And then?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_85db59ee)

vrke_convo_m3_offer_679b150d = ConvoScreen:new {
	id = "m3_offer_679b150d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_679b150d", -- We do our jobs. And now you must do yours.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_f8e71988", "m3_offer_39dfc6b4"}, -- I'm ready for my mission.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_679b150d)

vrke_convo_m3_offer_46fbca74 = ConvoScreen:new {
	id = "m3_offer_46fbca74",
	leftDialog = "@conversation/naboo_imperial_tier3:s_46fbca74", -- We're going to give it to you and send you on an interplanetary errand to the Dathomir system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_841d27db", "m3_offer_e440e620"}, -- Why?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_46fbca74)

vrke_convo_m3_offer_fda4456d = ConvoScreen:new {
	id = "m3_offer_fda4456d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_fda4456d", -- We will leak news that he has given us a list of names. You will transport this list. One thing that I did find interesting is that he mentioned the Dathomir system in passing but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_75c4b8b4", "m3_accept_dathomir"}, -- And then the enemy will attack?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_fda4456d)

vrke_convo_m3_offer_31d4944f = ConvoScreen:new {
	id = "m3_offer_31d4944f",
	leftDialog = "@conversation/naboo_imperial_tier3:s_31d4944f", -- We will pretend that he has given us a list of names. You will transport this list. One thing that I did find interesting is that he mentioned the Dathomir system in passing but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_75c4b8b4", "m3_accept_dathomir"}, -- And then the enemy will attack?
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_31d4944f)

vrke_convo_m3_offer_28876e4d = ConvoScreen:new {
	id = "m3_offer_28876e4d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_28876e4d", -- We will leak news that the doctor has given us names of other conspirators. You will transport this list of names. One thing that I did find interesting is that he mentioned the Dathomir system in passing but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1d1e30b6", "m3_accept_bait"}, -- So I'm the bait.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_28876e4d)

vrke_convo_m3_offer_697ba4d3 = ConvoScreen:new {
	id = "m3_offer_697ba4d3",
	leftDialog = "@conversation/naboo_imperial_tier3:s_697ba4d3", -- And then you will carry this list. His slip up of mentioning Dathomir might have been nothing but I believe it to be a mistake on his part. That is where you will focus your energies.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1d1e30b6", "m3_accept_bait"}, -- So I'm the bait.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_697ba4d3)

vrke_convo_m3_offer_39dfc6b4 = ConvoScreen:new {
	id = "m3_offer_39dfc6b4",
	leftDialog = "@conversation/naboo_imperial_tier3:s_39dfc6b4", -- The doctor refused to name collaborators; but the Rebels don't know that. We're going to send you out with a false list of names. One thing that I did find interesting is that he mentioned the Dathomir system in passing but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_5188aced", "m3_accept_dathomir"}, -- To force the enemy to attack?
		{"@conversation/naboo_imperial_tier3:s_22515365", "m3_offer_68aa150c"}, -- Sounds like a dangerous idea.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_39dfc6b4)

vrke_convo_m3_offer_e440e620 = ConvoScreen:new {
	id = "m3_offer_e440e620",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e440e620", -- One thing that I did find interesting is that he mentioned the Dathomir system in passing but seemed to realize his mistake and quickly change the subject. I believe that is the area we should move the fake list through.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_dbde1ca8", "m3_accept_leave"}, -- I don't like this idea.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_e440e620)

vrke_convo_m3_accept_dathomir = ConvoScreen:new {
	id = "m3_accept_dathomir",
	leftDialog = "@conversation/naboo_imperial_tier3:s_c32eabc5", -- Perhaps. His slip up of mentioning Dathomir might have been nothing but I believe it to be a mistake on his part. That is where you will focus your energies.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_accept_dathomir)

vrke_convo_m3_accept_bait = ConvoScreen:new {
	id = "m3_accept_bait",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b8302127", -- It is your duty. Do it well.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_accept_bait)

vrke_convo_m3_offer_68aa150c = ConvoScreen:new {
	id = "m3_offer_68aa150c",
	leftDialog = "@conversation/naboo_imperial_tier3:s_68aa150c", -- Dangerous - and effective. The Rebels will have to try to get that list. His slip up of mentioning Dathomir might have been nothing but I believe it to be a mistake on his part. That is where you will focus your energies.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_f24b6a1a", "m3_accept_die"}, -- I could die.
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_offer_68aa150c)

vrke_convo_m3_accept_leave = ConvoScreen:new {
	id = "m3_accept_leave",
	leftDialog = "@conversation/naboo_imperial_tier3:s_4a34b1cc", -- Your opinion does not matter. You are to leave immediately.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_accept_leave)

vrke_convo_m3_accept_die = ConvoScreen:new {
	id = "m3_accept_die",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1eba352e", -- That, my friend, is up to you.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m3_accept_die)

vrke_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bb4a477f", -- It seems that we have managed to undercover the traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_dbd88d67", "m4_offer_7df37f4b"}, -- Who, me?
		{"@conversation/naboo_imperial_tier3:s_741df7ed", "m4_offer_ee64b80a"}, -- Where?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer)

vrke_convo_m4_offer_7df37f4b = ConvoScreen:new {
	id = "m4_offer_7df37f4b",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7df37f4b", -- I don't know. ARE you a traitor?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_7426e000", "m4_offer_1e10a6ef"}, -- No!
		{"@conversation/naboo_imperial_tier3:s_96d7ed6a", "m4_offer_10c8692a"}, -- What a ridiculous question!
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_7df37f4b)

vrke_convo_m4_offer_ee64b80a = ConvoScreen:new {
	id = "m4_offer_ee64b80a",
	leftDialog = "@conversation/naboo_imperial_tier3:s_ee64b80a", -- This time, it is a soldier high in Imperial command. A General Breckon. If you are unfamiliar with the name all you need to know is that he is in charge of the Imperial Army stationed in the Dathomir system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1c1bc0f8", "m4_offer_d3144c5a"}, -- An Imperial general?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_ee64b80a)

vrke_convo_m4_offer_1e10a6ef = ConvoScreen:new {
	id = "m4_offer_1e10a6ef",
	leftDialog = "@conversation/naboo_imperial_tier3:s_1e10a6ef", -- I see. Well it would seem that General Breckon very well might be though. The orders that you recovered from the Rebel smuggler have his name all over them. It is too bad that he didn't cover his tracks better but I assume he didn't think you could win.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_c142d50f", "m4_offer_3bd0f63e"}, -- Who is General Breckon?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_1e10a6ef)

vrke_convo_m4_offer_10c8692a = ConvoScreen:new {
	id = "m4_offer_10c8692a",
	leftDialog = "@conversation/naboo_imperial_tier3:s_10c8692a", -- Inquisitors don't ASK ridiculous questions.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a42ffb97", "m4_offer_5485ba8d"}, -- Were you going to tell me about a traitor?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_10c8692a)

vrke_convo_m4_offer_d3144c5a = ConvoScreen:new {
	id = "m4_offer_d3144c5a",
	leftDialog = "@conversation/naboo_imperial_tier3:s_d3144c5a", -- Even Imperial generals can be foolish men. He believed our story about  the names. Those orders you recovered from the Rebels might as well have been written in his own hand. There is no doubt.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_c0f4399a", "m4_offer_7f3265a7"}, -- Doesn't he realize he'll have to answer to you?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_d3144c5a)

vrke_convo_m4_offer_3bd0f63e = ConvoScreen:new {
	id = "m4_offer_3bd0f63e",
	leftDialog = "@conversation/naboo_imperial_tier3:s_3bd0f63e", -- Well obviously he is a general in the Imperial Army. General Breckon is in charge of the army forces stationed in the Dathomir system. His contacts and rank make him a perfect candidate to pass information along to the Rebels without arousing too much suspicion.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_c73e6431", "m4_offer_f4cbd517"}, -- Are you sure he's guilty?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_3bd0f63e)

vrke_convo_m4_offer_5485ba8d = ConvoScreen:new {
	id = "m4_offer_5485ba8d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_5485ba8d", -- Do you know General Breckon?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_13b747b7", "m4_offer_98ee25e0"}, -- The name sounds familiar.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_5485ba8d)

vrke_convo_m4_offer_7f3265a7 = ConvoScreen:new {
	id = "m4_offer_7f3265a7",
	leftDialog = "@conversation/naboo_imperial_tier3:s_7f3265a7", -- No. He's answering to you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_6c186cde", "m4_offer_e1a23a44"}, -- What? Why?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_7f3265a7)

vrke_convo_m4_offer_f4cbd517 = ConvoScreen:new {
	id = "m4_offer_f4cbd517",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f4cbd517", -- He swears his innocence. He's coming here now to clear his name. He is wise to do so. It is my understanding that he is traveling through the Dathomir system on his way here even as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_c0069753", "m4_offer_b374861b"}, -- Do you think he is innocent?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_f4cbd517)

vrke_convo_m4_offer_98ee25e0 = ConvoScreen:new {
	id = "m4_offer_98ee25e0",
	leftDialog = "@conversation/naboo_imperial_tier3:s_98ee25e0", -- General Breckon is in charge of the army forces stationed in the Dathomir system. His contacts and rank make him a perfect candidate to be able to pass information along to the Rebels without arousing too much suspicion.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_39fb010c", "m4_offer_92c37f5d"}, -- No Imperial officer would betray the Empire.
		{"@conversation/naboo_imperial_tier3:s_b981d334", "m4_offer_34da8f1d"}, -- Are we certain it was him?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_98ee25e0)

vrke_convo_m4_offer_e1a23a44 = ConvoScreen:new {
	id = "m4_offer_e1a23a44",
	leftDialog = "@conversation/naboo_imperial_tier3:s_e1a23a44", -- He's en route to Naboo with an escort - to protest his innocence. Destroy him. It is my understanding that he is traveling through the Dathomir system on his way here even as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_a8d5c2b9", "m4_accept_casualty"}, -- But what if he's innocent?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_e1a23a44)

vrke_convo_m4_offer_b374861b = ConvoScreen:new {
	id = "m4_offer_b374861b",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b374861b", -- That is irrelevant. You will kill him before he reaches Naboo.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_4a3aa62e", "m4_accept_accident"}, -- Why?!
		{"@conversation/naboo_imperial_tier3:s_14ea12c8", "m4_accept_accident_2"}, -- I'm sorry?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_b374861b)

vrke_convo_m4_offer_92c37f5d = ConvoScreen:new {
	id = "m4_offer_92c37f5d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_92c37f5d", -- Are you daft? Wasn't it you who helped bring down Colonel Hend? If you think that a uniform makes you immune to greed or moral indecision or whatever causes people to betray their own, then you are sadly mistaken. If that were the case there would be no need for us.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_2c8e3657", "m4_offer_b333ecf9"}, -- It's not true.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_92c37f5d)

vrke_convo_m4_offer_34da8f1d = ConvoScreen:new {
	id = "m4_offer_34da8f1d",
	leftDialog = "@conversation/naboo_imperial_tier3:s_34da8f1d", -- Those orders you recovered from the Rebels might as well have been hand written by him. There is no doubt. General Breckon has betrayed his people, his soldiers, and his Emperor. There is only one punishment for that crime.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_d8f69fec", "m4_offer_6905c6b2"}, -- I understand, Inquisitor.
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_34da8f1d)

vrke_convo_m4_accept_casualty = ConvoScreen:new {
	id = "m4_accept_casualty",
	leftDialog = "@conversation/naboo_imperial_tier3:s_bc30dc8c", -- Then he is a casualty of war. We cannot take the risk that an Imperial general has been trading secrets to the Rebellion. Can you imagine the scandal that would ensue? It is far better if the general and his escorts simply have an accident in the Dathomir system. Since we will perform the investigation into his death, it will be simple to sweep under the rug.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_accept_casualty)

vrke_convo_m4_accept_accident = ConvoScreen:new {
	id = "m4_accept_accident",
	leftDialog = "@conversation/naboo_imperial_tier3:s_22198261", -- A general in the Imperial Army a traitor? Think about the scandal and what a major black eye it would be for the Empire. It is simpler if he has an accident and then we sweep the whole mess under the carpet. Destroy his escort as well. No one must know how he died and since we will do the investigation we will conclude that he fell victim to a tragic accident.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_accept_accident)

vrke_convo_m4_accept_accident_2 = ConvoScreen:new {
	id = "m4_accept_accident_2",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b95f9ff4", -- A general in the Imperial Army a traitor? Think about the scandal and what a major black eye it would be for the Empire. It is simpler if he has an accident and then we sweep the whole mess under the carpet. Destroy his escort as well. No one must know how he died. Because we will do the investigation, we will conclude that he fell victim to a tragic accident.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_accept_accident_2)

vrke_convo_m4_offer_b333ecf9 = ConvoScreen:new {
	id = "m4_offer_b333ecf9",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b333ecf9", -- That's what he says. He's traveling to Naboo now, to protest his innocence. It is my understanding that he is traveling through the Dathomir system on his way here even as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_1ee84e30", "m4_offer_b374861b"}, -- Would anyone ever believe him?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_b333ecf9)

vrke_convo_m4_offer_6905c6b2 = ConvoScreen:new {
	id = "m4_offer_6905c6b2",
	leftDialog = "@conversation/naboo_imperial_tier3:s_6905c6b2", -- Good. General Breckon is actually on his way to Naboo in an attempt to protest his innocence. He must never be allowed to even reach the system. Tragedy must befall the general while he is still in Dathomir on his way here.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_33c41dc", "m4_accept_accident"}, -- Why not let him come here and then charge him formally?
	}
}
vrke_convo_template:addScreen(vrke_convo_m4_offer_6905c6b2)

vrke_convo_tour_complete = ConvoScreen:new {
	id = "tour_complete",
	leftDialog = "@conversation/naboo_imperial_tier3:s_b41ba13c", -- And so, our time together is done.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3:s_23e0dd3", "jace_unfortunate"}, -- Maybe we will see each other again.
		{"@conversation/naboo_imperial_tier3:s_9b43a7ee", "jace_elders"}, -- Yes sir.
	}
}
vrke_convo_template:addScreen(vrke_convo_tour_complete)

vrke_convo_jace_unfortunate = ConvoScreen:new {
	id = "jace_unfortunate",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f5039ccf", -- I hope not, because it would be under unfortunate circumstances. You are to report to Grand Inquisitor Ja'ce Yiaso. You can find him just outside of Lord Vader's office. Do not disappoint him or you will find yourself under the question very quickly. Goodbye.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_jace_unfortunate)

vrke_convo_jace_elders = ConvoScreen:new {
	id = "jace_elders",
	leftDialog = "@conversation/naboo_imperial_tier3:s_f50e2248", -- Ah, so you have learned to respect your elders. That is a good thing. You are to report to Grand Inquisitor Ja'ce Yiaso. You can find him just outside of Lord Vader's office. Do not disappoint him or you will find yourself under the question very quickly. Farewell, %NU.
	stopConversation = "true",
	options = {
	}
}
vrke_convo_template:addScreen(vrke_convo_jace_elders)

addConversationTemplate("vrke_convo_template", vrke_convo_template)
