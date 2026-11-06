-- Inquisitor Fa'Zoll (Inquisition tier 2) conversation; ported from SWG-Source naboo_imperial_trainer_2.java with the pre-NGE client lines (feature inquisition-tier2-fa-zoll). Handler: faZollConvoHandler.
fa_zoll_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "faZollConvoHandler",
	screens = {}
}

fa_zoll_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_21772e5a", -- I'm sorry, I can't help you.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_not_pilot)

fa_zoll_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_245945cb", -- What is the matter with you, pilot?!  You dare show your face around here?
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_2313ac9e", "wanted_not_trusted"}, -- What are you talking about?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted)

fa_zoll_convo_wanted_not_trusted = ConvoScreen:new {
	id = "wanted_not_trusted",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_c5e2a04a", -- I believe you know exactly what I'm talking about.  You're lucky you aren't shot on sight!  Naval command has issued orders throughout the galaxy... %TU is NOT to be trusted.  That's YOU, isn't it?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_97222fa4", "wanted_defected"}, -- Wait a minute... what happened?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted_not_trusted)

fa_zoll_convo_wanted_defected = ConvoScreen:new {
	id = "wanted_defected",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_3ce9c229", -- I hope you're trying to tell me this was all a misunderstanding.  You have NOT defected to the Rebel Alliance?  Because if you think we're not on to you... you will not like the consequences of your desertion.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_a7cceea9", "wanted_redeem"}, -- No, I am loyal to the Empire!
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted_defected)

fa_zoll_convo_wanted_redeem = ConvoScreen:new {
	id = "wanted_redeem",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_34d641c9", -- You have a peculiar definition of loyalty.  Nevertheless, you might have a chance to redeem yourself.  If you can improve your standing in the eyes of the Empire... you MIGHT be allowed to fly again.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_f8b02865", "wanted_two_things"}, -- What do I do?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted_redeem)

fa_zoll_convo_wanted_two_things = ConvoScreen:new {
	id = "wanted_two_things",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_2a77f19e", -- Two things, %TU.  One, you must perform missions for the Empire until your standing has improved enough that we might consider you trustworthy again.
	stopConversation = "false",
	animation = "snap_finger2",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_1ad5c0e0", "wanted_go_away"}, -- What's the second thing?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted_two_things)

fa_zoll_convo_wanted_go_away = ConvoScreen:new {
	id = "wanted_go_away",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_9930b065", -- The second thing is, you must go away from here, and don't show your face until you are no longer considered an enemy of the Empire.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_wanted_go_away)

fa_zoll_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_1c006c1c", -- Ah, you're a long way from your squadron pilot. What brings you out this way?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_4854758d", "off_track_no_missions"}, -- I would like to request a mission.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_off_track)

fa_zoll_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_3ead1387", -- There's not very much, but I do have some elective duty missions that you can fly. I have a briefing prepared if you'd like to hear it.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2a924ab", "duty_brief_police"}, -- I'd like a briefing.
		{"@conversation/naboo_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_off_track_duties)

fa_zoll_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_a2cfa58e", -- I'm sorry. I can only assign missions to pilots in my own unit. You should return and speak to your commanding officer.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_off_track_no_missions)

fa_zoll_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_a59c7bd7", -- It looks like you're busy with an assignment already. Come talk to me when you're done.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_on_mission)

fa_zoll_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_26cb713a", -- Yes, how may I help you? Have you come to report a suspicious activity? You really should speak to my secretary. I only handle heresies and other critical cases.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_6396820e", "inquisition_info"}, -- What is the Imperial Inquisition?
		{"@conversation/naboo_imperial_trainer_2:s_3ce84ec1", "rebellion_info"}, -- What do you think of the Rebellion?
		{"@conversation/naboo_imperial_trainer_2:s_696a6a00", "not_recruiting"}, -- I've been asked to report to you for duty.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_greeting)

fa_zoll_convo_inquisition_info = ConvoScreen:new {
	id = "inquisition_info",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_bb972bed", -- The Inquisition is a unique branch of the Imperial Intelligence service. Our job is to maintain discipline and security within the Empire as a whole. We are the ever watchful eye against heresy and betrayal. The children of the Empire sleep safely each night, knowing that the Inquisition never rests.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2101d5b", "inquisition_duties"}, -- Yes, but what do you do?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_inquisition_info)

fa_zoll_convo_inquisition_duties = ConvoScreen:new {
	id = "inquisition_duties",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_e2cb470f", -- Investigations, judgements, and punishments. Each agent of the Inquisition is fully empowered to carry out any of these most important activities. The Emperor will suffer not for a moment the thought of a traitor to live. We must all be willing to give of ourselves that the Emperor's great work might continue.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_6396820e", "inquisition_info"}, -- What is the Imperial Inquisition?
		{"@conversation/naboo_imperial_trainer_2:s_3ce84ec1", "rebellion_info"}, -- What do you think of the Rebellion?
		{"@conversation/naboo_imperial_trainer_2:s_696a6a00", "not_recruiting"}, -- I've been asked to report to you for duty.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_inquisition_duties)

fa_zoll_convo_rebellion_info = ConvoScreen:new {
	id = "rebellion_info",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_5f0835ab", -- We do not honor the insurgents with a name within these halls. They are a collection of foul aliens and wayward children of the Emperor. Strange outworld philosophies have twisted their understanding and have driven them to betrayal. It is a sad time we live in when the light of the Empire cannot reach all living things.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_6396820e", "inquisition_info"}, -- What is the Imperial Inquisition?
		{"@conversation/naboo_imperial_trainer_2:s_3ce84ec1", "rebellion_info"}, -- What do you think of the Rebellion?
		{"@conversation/naboo_imperial_trainer_2:s_696a6a00", "not_recruiting"}, -- I've been asked to report to you for duty.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_rebellion_info)

fa_zoll_convo_not_recruiting = ConvoScreen:new {
	id = "not_recruiting",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_ecb5e1e2", -- The Imperial Inquisition does not recruit and does not outsource work. If we have need of you, we will contact you.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_not_recruiting)

fa_zoll_convo_sign_up = ConvoScreen:new {
	id = "sign_up",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_7c0ff63d", -- Ah, so you are the fine pilot that I have heard so much about. Your ruthlessness and efficiency are known among the Naval High Command and it is even said that the Emperor himself read your name in an activity report.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_95dcb85a", "sign_up_modesty"}, -- I do what I can for the Empire.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up)

fa_zoll_convo_sign_up_modesty = ConvoScreen:new {
	id = "sign_up_modesty",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_8e68e9b0", -- Such modesty! How refreshing. So many pilots believe they are the only thing keeping the Empire together. They do not realize that they are but a single thread in the grand tapestry. They do not realize that they could be cut and the whole would remain.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_4d0198f9", "sign_up_seminary"}, -- How may I serve the Inquisition?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up_modesty)

fa_zoll_convo_sign_up_seminary = ConvoScreen:new {
	id = "sign_up_seminary",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_860b7132", -- Right to the point as well. Yes, yes, I can see that I am going to enjoy our time together. Most exciting indeed! Well, now where to begin? Most members of the Inquisition spend several years at a seminary camp, learning the values of Imperial justice. You are being recruited on an accelerated time frame. This means you are exempt from seminary, but it also means you will be closely monitored for deviant activities.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_8f913d8b", "sign_up_watched"}, -- I would never betray the Empire.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up_seminary)

fa_zoll_convo_sign_up_watched = ConvoScreen:new {
	id = "sign_up_watched",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_872eaec4", -- Indeed, I am sure you would not. Nonetheless, we must watch our agents twice as closely as we watch the other members of the Empire. Any violation of Imperial doctrine by an Inquisitorial agent is punishable by summary execution. Do not stray from the righteous path I will set for you.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_53d26b00", "sign_up_agent"}, -- Of course not, Lord Fa'Zoll.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up_watched)

fa_zoll_convo_sign_up_agent = ConvoScreen:new {
	id = "sign_up_agent",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_131def5c", -- Very well, yes, yes. Very well. Now then, I have an initial assignment for you. Why don't you familiarize yourself with the facilities and then return when you are ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_6a9a7be2", "sign_up_done"}, -- Yes, Lord Fa'Zoll.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up_agent)

fa_zoll_convo_sign_up_done = ConvoScreen:new {
	id = "sign_up_done",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_50f84d04", -- Good, very good.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_sign_up_done)

fa_zoll_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_1f0f791f", -- Ah, yes, excellent. You are ready to begin our work, then?
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_c8f39347", "m1_traitors"}, -- I am.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_offer)

fa_zoll_convo_m1_traitors = ConvoScreen:new {
	id = "m1_traitors",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_41786376", -- Then let us begin. It is a sad truth that many of the Emperor's own have chosen to betray his willful rule. The Imperial Inquisition must always practice vigilance against the traitor. It is often difficult to determine where these foul conspiracies take root. Indeed, the most dedicated traitor is also the most careful.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_7c7a7681", "m1_grim"}, -- How do you stop these crimes?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_traitors)

fa_zoll_convo_m1_grim = ConvoScreen:new {
	id = "m1_grim",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_5960dfeb", -- It is grim. Grim. We must often pluck up the brightest of our own commanding officers and examine their minds for any sign of conspiracy. The process is intrusive. Some do not live. As such, we only do this occasionally.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_d4948205", "m1_scan_minds"}, -- You scan their minds?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_grim)

fa_zoll_convo_m1_scan_minds = ConvoScreen:new {
	id = "m1_scan_minds",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_a2137dae", -- To the best of our ability. Sometimes more traditional means are necessary. The Emperor has taught us much. More often, though, the traitor is undone by their own carelessness. His eminence, the High Inquisitor, has granted me the privileged task of bringing this traitor under the watchful eye of the Inquisition.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_f1be3213", "m1_old_man"}, -- What part in this do I play?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_scan_minds)

fa_zoll_convo_m1_old_man = ConvoScreen:new {
	id = "m1_old_man",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_f283cf35", -- I am an old man. I have worked with His Eminence the High Inquisitor for many years. He is older than I. We make use of able pilots to carry out our judgements and commands.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_daf7bb7d", "m1_monitoring"}, -- I see. What task do you have for me?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_old_man)

fa_zoll_convo_m1_monitoring = ConvoScreen:new {
	id = "m1_monitoring",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_199bd27f", -- For several months now the Inquisition has been monitoring activities between certain members of our military and suspected Rebel sympathizers. One such meeting took place not long ago and it is time that the Inquisition discovered the truth behind these suspicious activities.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_483fa8ea", "m1_patience"}, -- Why don't you just arrest and question the parties involved?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_monitoring)

fa_zoll_convo_m1_patience = ConvoScreen:new {
	id = "m1_patience",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_5bb1e2", -- I think that you will fit in well with the Inquisition. But you must learn patience. The officer involved has friends in very high places and without evidence we could leave ourselves open to scrutiny. The key to every good investigation is evidence.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_fed6017c", "m1_brief"}, -- How do we gather the evidence that we need?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_patience)

fa_zoll_convo_m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_d2fa677d", -- The suspected Rebel sympathizer is being overly cautious about not being stopped by any Imperial patrol and has filed a flight plan leaving the Naboo system in route to Dantooine. You are to stop his ship and inspect its navcomputer for any information that it might contain.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_32a6fe1c", "m1_accept"}, -- I will do as you command, Fa'Zoll.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_brief)

fa_zoll_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_486a2be", -- Yes. Yes, I do think that you will have a brilliant future with the Inquisition. Report back to me with your findings.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_accept)

fa_zoll_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_6e9c09c4", -- Have you managed to track down the information that I requested, Pilot?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_29d0a2db", "m1_another_meeting"}, -- I've run into some trouble so far.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_failed)

fa_zoll_convo_m1_another_meeting = ConvoScreen:new {
	id = "m1_another_meeting",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_4eef704f", -- That is most unfortunate. But luck is with us this day since another meeting has taken place. Again the pilot is leaving the Naboo system for Dantooine. I find this most interesting, don't you? Capture and scan this ship...oh, and pilot, do not fail me again.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_846f2737", "m1_retry"}, -- Yes, sir! I will not fail you again.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_another_meeting)

fa_zoll_convo_m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_aceff31e", -- Good luck, pilot.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_retry)

fa_zoll_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_f91e446d", -- What have you learned so far, %NU?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_1d5aba18", "m1_encrypted"}, -- (Transfer the information to Inquisitor Fa'Zoll.)
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_won)

fa_zoll_convo_m1_encrypted = ConvoScreen:new {
	id = "m1_encrypted",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_5f0459fc", -- This is most interesting. The data seems to be encrypted. Only the guilty need to hide what they are doing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_22a1fc52", "m1_pay"}, -- Perhaps Imperial Intelligence can crack it.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_encrypted)

fa_zoll_convo_m1_pay = ConvoScreen:new {
	id = "m1_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_ad754", -- Do not presume in matters that concern you not. Never the less, you have done very well, pilot. Here is a consignment fee for completing the job. Stay close, though. Once this data is cracked we might have need of someone with your particular skills.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "m1_bite_to_eat"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_pay)

fa_zoll_convo_m1_bite_to_eat = ConvoScreen:new {
	id = "m1_bite_to_eat",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_61eac8c", -- Go grab yourself a quick bite to eat and then report back. I have the utmost faith that the code will not keep us from the truth for very long.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m1_bite_to_eat)

fa_zoll_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_7f95f0a5", -- Get suited up, you're being scrambled immediately.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b6b25f13", "m2_decrypted"}, -- Yes, sir!
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_offer)

fa_zoll_convo_m2_decrypted = ConvoScreen:new {
	id = "m2_decrypted",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_6ca30e9d", -- The information you retrieved from the courier has been decrypted.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_8efde2ae", "m2_encryption"}, -- Yes, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_decrypted)

fa_zoll_convo_m2_encryption = ConvoScreen:new {
	id = "m2_encryption",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_a5dff683", -- It would seem that the encryption of the message was a bit more advanced than initially indicated and part of the message was lost. But we did manage to recover some very important details regardless.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_c0996c6b", "m2_meeting"}, -- I am ready to serve.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_encryption)

fa_zoll_convo_m2_meeting = ConvoScreen:new {
	id = "m2_meeting",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_2dcd5da9", -- Your zeal is most appreciated. Although much was lost we did manage to uncover the location where the pirates will be meeting the insurgents. It would seem that they will be exchanging some important information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_19fe9586", "m2_intercept"}, -- Do you want me to destroy the conspirators?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_meeting)

fa_zoll_convo_m2_intercept = ConvoScreen:new {
	id = "m2_intercept",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_3252d1a", -- No, of course not. We must find out what is in that transmission. You are to travel to the meeting place and intercept that transmission. Once you have intercepted the signal immediately transmit the information back here.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_de5b2183", "m2_dantooine"}, -- Where is the enemy planning on meeting?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_intercept)

fa_zoll_convo_m2_dantooine = ConvoScreen:new {
	id = "m2_dantooine",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_2e7df33d", -- The meeting is going to be taking place inside of the Dantooine system. It would seem that the courier you captured was not the only ship involved in supplying data to the Rebellion.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_1980f233", "m2_noticed"}, -- I understand, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_dantooine)

fa_zoll_convo_m2_noticed = ConvoScreen:new {
	id = "m2_noticed",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_3b69b91e", -- Once you have started your transmission there is a very high chance that you will be noticed by the enemy. You must complete the transmission at all costs.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_c602907a", "m2_accept"}, -- I will not fail the Empire.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_noticed)

fa_zoll_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_576f96b8", -- That is correct. You will not fail the Empire. Now to your ship, pilot. Get me that transmission.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_accept)

fa_zoll_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_c50d6541", -- Pilot, you're supposed to be on your ship! Get up there and intercept that transmission immediately!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_8efde2ae", "m2_retry"}, -- Yes, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_failed)

fa_zoll_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_964c5567", -- Return to me once you've successfully intercepted that transmission.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_retry)

fa_zoll_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_32701355", -- We have received the transmission successfully and have begun the process of deciphering their code. There will be no error in the data this time to protect the traitor. Yet again, you have proven yourself an asset to the Inquisition.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "m2_promotion"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_won)

fa_zoll_convo_m2_promotion = ConvoScreen:new {
	id = "m2_promotion",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_78c7dc33", -- Pilot Officer %NU, it's time that you were elevated to full operational status within the Inquisition. You are hereby granted the rank of Flying Officer. Congratulations Flying Officer %NU. You are now a full member of the Imperial Inquisition. Fly with honor and fight with the Emperor's own fury.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "m2_pay"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_promotion)

fa_zoll_convo_m2_pay = ConvoScreen:new {
	id = "m2_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_b784db84", -- The Inquisition, in all its wisdom, has authorized a duty pay increase for your exceptional performance and new rank. Since you are now a Flying Officer, you may select your own assignment.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_89bc583c", "m2_local_command"}, -- Very well, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_pay)

fa_zoll_convo_m2_local_command = ConvoScreen:new {
	id = "m2_local_command",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_2865fd30", -- For the time being, the Inquisition is assisting the local command in its regional duties. It would seem that some of their pilots are less than trustworthy. Perhaps at some later date some of them need to be put to the question. But for now you will act as a normal member of the Imperial Navy.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_d8b8f3ac", "m2_emperor_commands"}, -- As the Emperor commands.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_local_command)

fa_zoll_convo_m2_emperor_commands = ConvoScreen:new {
	id = "m2_emperor_commands",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_4df61c15", -- Yes, as the Emperor commands.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_fa3398f3", "m2_discretion"}, -- What is it you wish me to do?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_emperor_commands)

fa_zoll_convo_m2_discretion = ConvoScreen:new {
	id = "m2_discretion",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_960be58b", -- Since you have complete operational discretion, it will be up to you to decide how to assist the local command. They are having several issues that require someone with your particular skills.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_91223b5c", "m2_duty_briefing"}, -- I'm ready to begin immediately, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_discretion)

fa_zoll_convo_m2_duty_briefing = ConvoScreen:new {
	id = "m2_duty_briefing",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_f85fd827", -- I have a briefing prepared. Or if you've already examined the briefing material, you can select a type of operation to begin.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2a924ab", "duty_brief_police"}, -- I'd like a briefing.
		{"@conversation/naboo_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m2_duty_briefing)

fa_zoll_convo_duty_after_m2 = ConvoScreen:new {
	id = "duty_after_m2",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_be89481", -- Welcome back, Pilot. Things are rather calm for the moment, so you will be flying some duty missions.I have a briefing prepared. Or if you've already examined the briefing material, you can select a type of operation to begin.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2a924ab", "duty_brief_police"}, -- I'd like a briefing.
		{"@conversation/naboo_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_after_m2)

fa_zoll_convo_duty_after_m3 = ConvoScreen:new {
	id = "duty_after_m3",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_9962665d", -- Naval Command wants us to continue to assist the local command. Their assessment of the situation is positive, but they feel that inflicting further damage is necessary.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2a924ab", "duty_brief_police"}, -- I'd like a briefing.
		{"@conversation/naboo_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_after_m3)

fa_zoll_convo_duty_brief_police = ConvoScreen:new {
	id = "duty_brief_police",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_6a6fe80", -- As I said, there are several areas that the local command needs assistance in. The first is strictly a simple police matter...if we could rely on the local authorities. A number of ships have been attempting to leave the system without filing the proper flight plans. You are to escort them back to port, by force if necessary.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_5102164f", "duty_brief_freighters"}, -- (Nod and listen.)
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_brief_police)

fa_zoll_convo_duty_brief_freighters = ConvoScreen:new {
	id = "duty_brief_freighters",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_b8791e16", -- The second matter is one that the Emperor himself took great interest in. Supply freighters will be leaving the Naboo system on their way to a small out of the way place called Endor. The Emperor very much wants these freighters to make it to their jump locations safe and sound.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_45fa29cc", "duty_brief_insurgents"}, -- (Grin and listen.)
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_brief_freighters)

fa_zoll_convo_duty_brief_insurgents = ConvoScreen:new {
	id = "duty_brief_insurgents",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_b2634e3d", -- The third and final task is one that I personally would like taken care of. I did a little investigation into the Dantooine system and have located small patrols of insurgents in the region. The Navy has no wish to begin operations in that system at this time but that doesn't stop me from sending one of my own in to clear out that little hornets nest.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_e71434ff", "duty_menu"}, -- Yes, sir! I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_brief_insurgents)

fa_zoll_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_5b4ccb84", -- You have operational discretion to choose an assignment from the areas outlined by Imperial Intelligence in your briefing. I can also instruct you in the use of new technology if you think you're ready.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_e84f3a62", "duty_police"}, -- I'd like to assist in the police action.
		{"@conversation/naboo_imperial_trainer_2:s_e6765c30", "duty_escort"}, -- I would like to serve the Emperor and escort the freighters.
		{"@conversation/naboo_imperial_trainer_2:s_f0a7a4ef", "duty_insurgents"}, -- It would be an honor to assist you in your quest to stamp out the insurgents.
		{"@conversation/naboo_imperial_trainer_2:s_b0d3b474", "training_not_ready"}, -- I'm ready for training.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_menu)

fa_zoll_convo_duty_police = ConvoScreen:new {
	id = "duty_police",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_4a2282c8", -- Very well. Patrol the Naboo system and we will direct you to any unauthorized flights. They are to be escorted back to port. If they resist, you are authorized to use any force necessary, with one exception: do not destroy any of those ships.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_8efde2ae", "duty_police_guard"}, -- Yes, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_police)

fa_zoll_convo_duty_police_guard = ConvoScreen:new {
	id = "duty_police_guard",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_205f33ca", -- Be on your guard. Any one of those ships could be in league with the insurgents.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_police_guard)

fa_zoll_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_dfdec194", -- Everything we do serves the Emperor. Meet the freighters in the Naboo system and escort them to their hyperspace locations.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_8efde2ae", "duty_escort_warned"}, -- Yes, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_escort)

fa_zoll_convo_duty_escort_warned = ConvoScreen:new {
	id = "duty_escort_warned",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_fb6ae829", -- Be warned with the suspected traitor inside the Empire it is possible that our enemies have gotten word of these transports.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_escort_warned)

fa_zoll_convo_duty_insurgents = ConvoScreen:new {
	id = "duty_insurgents",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_79d26fde", -- That is what I wanted to hear. Travel to Dantooine and begin your search for the insurgents. Where ever you might find them wipe them out. Let the justice of the Inquisition be swift and merciless.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b6b25f13", "duty_insurgents_blessing"}, -- Yes, sir!
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_insurgents)

fa_zoll_convo_duty_insurgents_blessing = ConvoScreen:new {
	id = "duty_insurgents_blessing",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_4682fc3c", -- May the Emperor's blessing be on you, pilot.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_duty_insurgents_blessing)

fa_zoll_convo_training_not_ready = ConvoScreen:new {
	id = "training_not_ready",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_d2f8399b", -- Flying Officer %NU, I have the highest level of respect for you, but I want to see more results in the operations available to you before you are ready for advancement.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_89bc583c", "training_not_ready_report"}, -- Very well, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_training_not_ready)

fa_zoll_convo_training_not_ready_report = ConvoScreen:new {
	id = "training_not_ready_report",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_49f3270b", -- Report back to me when you're ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_training_not_ready_report)

fa_zoll_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_883a28d9", -- Pilot, it is time for you to learn some new skills. It is important that you keep sharp and keep your skills at the top of their game in order to succeed as an Imperial pilot. Are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_c1bc23b4", "training_menu"}, -- I am ready for some training.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_training_offer)

fa_zoll_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_9ac35c60", -- You've shown considerable improvement in ability since joining the Inquisition. It's time to allow you access to the next level of training and technology. I remind you that anything you learn is highly confidential, security rating Gamma Three. You may not share your knowledge with fellow officers of any rank at or below your own. What area would you like to train in?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_594a07fa", "trained_starships"}, -- I want to study advanced TIE combat operations.
		{"@conversation/naboo_imperial_trainer_2:s_be30f309", "trained_weapons"}, -- I want to study advanced equipment technology.
		{"@conversation/naboo_imperial_trainer_2:s_e73e5d21", "trained_procedures"}, -- I want to study pilot combat training.
		{"@conversation/naboo_imperial_trainer_2:s_c76594d7", "trained_droid"}, -- I want to study advanced reactor engineering algorithms.
		{"@conversation/naboo_imperial_trainer_2:s_ae26c22", "training_later"}, -- Let me think about this for a bit.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_training_menu)

fa_zoll_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_486da900", -- Your continued success will rely on your ability to make maximum use of all new Imperial technology. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_trained_starships)

fa_zoll_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_241a34a1", -- Mastering proper use of heavy equipment technology is key. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_trained_weapons)

fa_zoll_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_c4880407", -- Developing new levels of tactical and physical excellence will be critical in realizing your true potential. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_trained_procedures)

fa_zoll_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_31804e15", -- Understanding how to rapidly and efficiently manage the complex systems on board a fighter is a necessary step in your development as a pilot. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_987445c9", "trained_report"}, -- Thank you, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_trained_droid)

fa_zoll_convo_trained_report = ConvoScreen:new {
	id = "trained_report",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_8e4bd7c1", -- Report back to me when you are ready for a new assignment. The Inquisition is in need of someone with your talents yet again.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_trained_report)

fa_zoll_convo_training_later = ConvoScreen:new {
	id = "training_later",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_7b25fbc3", -- You're cleared for training, so let me know when you are ready to begin.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_training_later)

fa_zoll_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_6309f032", -- Good to see you, Flying Officer %NU. You've been making significant impact with the other branches of the Imperial High Command. You have certainly done the Inquisition proud. But the time has come for you to resume your duties in rooting out traitors.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_51fe08f5", "m3_abduction"}, -- Point me in the proper direction and I will do as you command.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_offer)

fa_zoll_convo_m3_abduction = ConvoScreen:new {
	id = "m3_abduction",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_de870f1", -- The transmission that you managed to intercept for us has been partially deciphered and it indicated plans to abduct Colonel Hend of the Imperial Navy. Unfortunately, we received this information too late to stop the abduction.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_3c9b80ee", "m3_leads"}, -- Are there any leads on where they took him?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_abduction)

fa_zoll_convo_m3_leads = ConvoScreen:new {
	id = "m3_leads",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_26408ea", -- There are several leads and the Navy is sending out patrols trying to recover Hend. The Inquisition has volunteered to assist the Navy in their search for the lost colonel. Of course, we have information at our disposal that the Navy is not privy to...such as the jump location of the transport that Hend is on.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_6e39f51b", "m3_black_eye"}, -- Shouldn't we inform the Imperial Navy of this location?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_leads)

fa_zoll_convo_m3_black_eye = ConvoScreen:new {
	id = "m3_black_eye",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_b257ddf8", -- Why would we want to do something like that? It would be a major black eye to the Navy if the Inquisition managed to find and rescue their lost man before they could.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_fcff7b8e", "m3_brief"}, -- Of course. I wasn't thinking, sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_black_eye)

fa_zoll_convo_m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_1d63bf5d", -- You still have much to learn about what it means to be a member of the Inquisition. Regardless, you are to enter the Naboo system and recover the colonel. His transport will most likely be heavily guarded and I doubt they will be willing to give up their prize without a fight. Once you have his ship secured protect it from counter-attack until it can hyperspace back into safe space.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_9b43a7ee", "m3_accept"}, -- Yes sir.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_brief)

fa_zoll_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_e1771eb6", -- Remember, it will be worthless to the Inquisition if we are unable to recover the colonel alive. While you are recovering Hend we will continue our decoding of the transmission that you recovered.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_accept)

fa_zoll_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_ff5a78b2", -- What are you doing back here, pilot? I haven't received a report that you were successful in your mission.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_f6d4476d", "m3_failed_questions"}, -- I am sorry but I seem to be having some difficulties...
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_failed)

fa_zoll_convo_m3_failed_questions = ConvoScreen:new {
	id = "m3_failed_questions",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_825fac62", -- I do not care for your difficulties. Get back out there and finish what you started. If you are unable or unwilling to perform this task, perhaps you would care to answer some questions that I have?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_91e4b620", "m3_retry"}, -- That will not be necessary sir. I will handle itl.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_failed_questions)

fa_zoll_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_172871ff", -- I knew I could count on you. Report back to me when you have finished the job. Don't disappoint me again, pilot.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_retry)

fa_zoll_convo_m3_won = ConvoScreen:new {
	id = "m3_won",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_2ccef947", -- Good your back. We have discovered a serious problem. We managed to decipher the remainder of the message that you intercepted. It would seem that Colonel Hend was the one who was leaking the information to the insurgents.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_96db4fc7", "m3_traitor"}, -- What? And we assisted him on his escape.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_won)

fa_zoll_convo_m3_traitor = ConvoScreen:new {
	id = "m3_traitor",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_196d2fe6", -- That is what it would appear. This transgression must never be allowed to go unpunished. It is time for Colonel Hend to be punished for his treachery. We are in the process of tracking down where the colonel went. Once we have found his location it will be up to you to pass sentence on the traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_369ec9fc", "m3_pay"}, -- Yes, my lord. What should I do until you have his location?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_traitor)

fa_zoll_convo_m3_pay = ConvoScreen:new {
	id = "m3_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_85fe2519", -- For now we will act as if nothing is amiss. Until we can figure out where he is, continue your operation helping the local forces.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_b2a924ab", "duty_brief_police"}, -- I'd like a briefing.
		{"@conversation/naboo_imperial_trainer_2:s_ac71da57", "duty_menu"}, -- I'm ready to take an assignment.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m3_pay)

fa_zoll_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_e1b07878", -- I was wondering when you would finally arrive. We have just finished our calculations on Colonel Hend's jump position and it is clear he has traveled to the Dantooine system. The time has come for the Colonel to be punished for his crimes against the Emperor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_1f033c46", "m4_brief"}, -- I am ready and willing to make the traitor pay.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_offer)

fa_zoll_convo_m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_d1fa21c", -- As I knew you would be. Travel to the Dantooine system and scan for the colonel's ship. Once you have found it pass judgement on the colonel without mercy.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_20b3aa70", "m4_accept"}, -- Yes, my lord. But won't the colonel be expecting us?
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_brief)

fa_zoll_convo_m4_accept = ConvoScreen:new {
	id = "m4_accept",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_e17af774", -- No one expects the Imperial Inquisition. He obviously thinks that he has gotten away with his crimes. Now go before we lose him again.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_accept)

fa_zoll_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_681fb295", -- Have you accomplished what I have asked of you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_9c394eb4", "m4_failed_tolerate"}, -- No, sir. I am having difficulties with the colonel.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_failed)

fa_zoll_convo_m4_failed_tolerate = ConvoScreen:new {
	id = "m4_failed_tolerate",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_306da215", -- I told you once that I do not tolerate failure. Return to the Dantooine system and destroy that traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_846f2737", "m4_retry"}, -- Yes, sir! I will not fail you again.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_failed_tolerate)

fa_zoll_convo_m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_164b059e", -- For your sake I hope that you are right.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_retry)

fa_zoll_convo_m4_won = ConvoScreen:new {
	id = "m4_won",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_a08c6dc4", -- Have you accomplished the task that I gave to you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_97d51490", "m4_pay"}, -- Yes, sir. I have taught the traitor the error of his ways.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_won)

fa_zoll_convo_m4_pay = ConvoScreen:new {
	id = "m4_pay",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_49be19d2", -- Excellent. I think that you might have a very bright future with the Imperial Inquisition. I have decided to transfer you to Inquisitor Vrke. He is one of the finest field operatives within the Inquisition and I believe that you will be an asset to his operations.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_1bac802d", "m4_farewell"}, -- Thank you sir. It has been an honor to serve under you.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_pay)

fa_zoll_convo_m4_farewell = ConvoScreen:new {
	id = "m4_farewell",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_bc64aa40", -- The honor has been entirely mine. I have a feeling that one day you will be a shining example of an Inquisition officer. Listen and learn well from Vrke. He is currently stationed at the Emperor's Retreat and is expecting you. Farewell, until we meet again.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_farewell)

fa_zoll_convo_m4_more_training = ConvoScreen:new {
	id = "m4_more_training",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_7be3e248", -- I agree with you. Let's get you better prepared for future operations.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_594a07fa", "trained_starships"}, -- I want to study advanced TIE combat operations.
		{"@conversation/naboo_imperial_trainer_2:s_be30f309", "trained_weapons"}, -- I want to study advanced equipment technology.
		{"@conversation/naboo_imperial_trainer_2:s_e73e5d21", "trained_procedures"}, -- I want to study pilot combat training.
		{"@conversation/naboo_imperial_trainer_2:s_c76594d7", "trained_droid"}, -- I want to study advanced reactor engineering algorithms.
		{"@conversation/naboo_imperial_trainer_2:s_ae26c22", "training_later"}, -- Let me think about this for a bit.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_m4_more_training)

fa_zoll_convo_report_to_vrke = ConvoScreen:new {
	id = "report_to_vrke",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_69ea2753", -- You need to report to Inquisitor Vrke inside the Emperor's Retreat. He will be handling your assignments for the time being.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_3ba5368f", "vrke_goodbye"}, -- Don't you want to say good bye to me?
		{"@conversation/naboo_imperial_trainer_2:s_f2cf68b3", "vrke_dont_wait"}, -- Ok, well thanks for your guidance.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_report_to_vrke)

fa_zoll_convo_vrke_goodbye = ConvoScreen:new {
	id = "vrke_goodbye",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_f693949d", -- You mean, wish you well...tell you what a good job you have done for me and how much I will miss having you around?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_trainer_2:s_959d8d9b", "vrke_goodbye_no"}, -- Yeah, that sort of thing.
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_vrke_goodbye)

fa_zoll_convo_vrke_goodbye_no = ConvoScreen:new {
	id = "vrke_goodbye_no",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_4c695dbd", -- No.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_vrke_goodbye_no)

fa_zoll_convo_vrke_dont_wait = ConvoScreen:new {
	id = "vrke_dont_wait",
	leftDialog = "@conversation/naboo_imperial_trainer_2:s_b0e9edf4", -- Yes I know that I really went above and beyond the call of duty to help you. You were very lucky to have me as your commanding officer. Now don't keep Inquisitor Vrke waiting.
	stopConversation = "true",
	options = {
	}
}
fa_zoll_convo_template:addScreen(fa_zoll_convo_vrke_dont_wait)

addConversationTemplate("fa_zoll_convo_template", fa_zoll_convo_template)
