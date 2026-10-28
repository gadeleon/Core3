-- Nin Gursawe, the Insurgent (Black Epsilon tier 4) conversation; ported from SWG-Source corellia_imperial_tier4.java with the pre-NGE client lines (feature black-epsilon-tier4-nin-gursawe). Handler: ninGursaweConvoHandler.
nin_gursawe_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "ninGursaweConvoHandler",
	screens = {}
}

nin_gursawe_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/corellia_imperial_tier4:s_362907ef", -- I don't have time to deal with you right now. How about you come back when you actually know how to pilot a ship? Of course, I probably won't talk to you then either...but it would be a start.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_not_pilot)

nin_gursawe_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9ed0c023", -- You really don't have any business here or with me. Since you don't belong here, why don't you just move along quietly?
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_wrong_faction)

nin_gursawe_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b66c783f", -- Get lost, %TU.  I don't want to be seen talking to you.  Before you know it, people will think that I am a traitor, too.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_tier4:s_61ee3818", "wanted_traitor"}, -- Traitor?!
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_wanted)

nin_gursawe_convo_wanted_traitor = ConvoScreen:new {
	id = "wanted_traitor",
	leftDialog = "@conversation/corellia_imperial_tier4:s_6a0fad7b", -- Don't act surprised.  A person doesn't just ACCIDENTALLY work for the Rebel Alliance to overthrow the Empire.  Now get lost, we have no use for your kind.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier4:s_14c18bea", "wanted_end"}, -- It's not true!
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_wanted_traitor)

nin_gursawe_convo_wanted_end = ConvoScreen:new {
	id = "wanted_end",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1f6db0c9", -- Save your stories for children.  If you ever want to fly for the Imperial Navy again, you'll improve your standing with the Empire.  Until then, don't talk to me.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_wanted_end)

nin_gursawe_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/corellia_imperial_tier4:s_253224d8", -- You're a long way from home, pilot. Why have you come?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4854758d", "off_track_no_duty"}, -- I would like to request a mission.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_off_track)

nin_gursawe_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/corellia_imperial_tier4:s_81995254", -- Normally I would only give missions to my own pilots, but I'm a little short-handed and I have several elective duty missions available. Would you like to hear a briefing?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_c82e9a2f", "briefing"}, -- Yes, please.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_off_track_duties)

nin_gursawe_convo_off_track_no_duty = ConvoScreen:new {
	id = "off_track_no_duty",
	leftDialog = "@conversation/corellia_imperial_tier4:s_83af3aa0", -- I cannot use someone like you. I am only looking for highly skilled pilots and you don't make the cut. Perhaps you should return to your commanding officer.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_off_track_no_duty)

nin_gursawe_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2934bbe1", -- I do have need for a skilled pilot but I have no interest in babysitting. I would suggest that you go work on your skills a bit more and maybe you will hear from me.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_not_ready)

nin_gursawe_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/corellia_imperial_tier4:s_520cdd79", -- Shouldn't you be out on assignment? I have no use for someone who cannot finish what they start.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_on_mission)

nin_gursawe_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d832aba0", -- Are you having any luck?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b4712f35", "m1_failed_excuses"}, -- I'm afraid not.
		{"@conversation/corellia_imperial_tier4:s_828cdbfa", "m1_failed_resilient"}, -- I'm still in pursuit.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_failed)

nin_gursawe_convo_m1_failed_excuses = ConvoScreen:new {
	id = "m1_failed_excuses",
	leftDialog = "@conversation/corellia_imperial_tier4:s_8406a42d", -- These mercenaries are very good - and very motivated. I'm not surprised to hear that you've run into difficulties, but I still don't want to hear any excuses. You are supposed to be better.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9d071495", "m1_retry_a"}, -- I just need another shot.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_failed_excuses)

nin_gursawe_convo_m1_failed_resilient = ConvoScreen:new {
	id = "m1_failed_resilient",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e3e51927", -- I've read your report. I know how good you are. These mercenaries are surprisingly resilient, if they can fight you off.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_bbed80fc", "m1_retry_b"}, -- They won't last for long.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_failed_resilient)

nin_gursawe_convo_m1_retry_a = ConvoScreen:new {
	id = "m1_retry_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_bde3268d", -- Of course. Good luck.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_retry_a)

nin_gursawe_convo_m1_retry_b = ConvoScreen:new {
	id = "m1_retry_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9f7da911", -- The Empire will prevail. You're clear to leave. Better luck this time.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_retry_b)

nin_gursawe_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b94e3a35", -- Your mission's not yet complete.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_87d7e908", "m2_failed_important"}, -- I know.
		{"@conversation/corellia_imperial_tier4:s_40d40fc4", "m2_failed_river"}, -- It's been difficult.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_failed)

nin_gursawe_convo_m2_failed_important = ConvoScreen:new {
	id = "m2_failed_important",
	leftDialog = "@conversation/corellia_imperial_tier4:s_81b729d2", -- This is very important, %TU. More important than you realize.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_7017e938", "m2_retry_a"}, -- It'll get done.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_failed_important)

nin_gursawe_convo_m2_failed_river = ConvoScreen:new {
	id = "m2_failed_river",
	leftDialog = "@conversation/corellia_imperial_tier4:s_77729b2", -- Cry me a river. I thought you were tough?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_e76b9ab1", "m2_retry_b"}, -- I know what to do; I just need to do it.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_failed_river)

nin_gursawe_convo_m2_retry_a = ConvoScreen:new {
	id = "m2_retry_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9a8ac7e9", -- I'm counting on you. Do not fail.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_retry_a)

nin_gursawe_convo_m2_retry_b = ConvoScreen:new {
	id = "m2_retry_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1d3e1b08", -- Then do it.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_retry_b)

nin_gursawe_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1d658537", -- They're quite good, aren't they?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_c4c33621", "m3_failed_meaning"}, -- I've never seen mercenaries that good!
		{"@conversation/corellia_imperial_tier4:s_50b309d4", "m3_failed_join"}, -- Too good, if you ask me.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_failed)

nin_gursawe_convo_m3_failed_meaning = ConvoScreen:new {
	id = "m3_failed_meaning",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2f76570d", -- What does that mean, do you think?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_96219092", "m3_failed_not_mercs"}, -- Maybe they're getting better.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_failed_meaning)

nin_gursawe_convo_m3_failed_not_mercs = ConvoScreen:new {
	id = "m3_failed_not_mercs",
	leftDialog = "@conversation/corellia_imperial_tier4:s_30f28d53", -- Or maybe it's not mercenaries you're fighting.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_2313ac9e", "m3_retry_a"}, -- What are you talking about?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_failed_not_mercs)

nin_gursawe_convo_m3_retry_a = ConvoScreen:new {
	id = "m3_retry_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_5d0255cb", -- Keep trying, %NU. You're doing the Emperor's work.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_retry_a)

nin_gursawe_convo_m3_failed_join = ConvoScreen:new {
	id = "m3_failed_join",
	leftDialog = "@conversation/corellia_imperial_tier4:s_450797b1", -- I wish I could join you out there.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_cd02ac28", "m3_failed_focus"}, -- I could use the help.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_failed_join)

nin_gursawe_convo_m3_failed_focus = ConvoScreen:new {
	id = "m3_failed_focus",
	leftDialog = "@conversation/corellia_imperial_tier4:s_ca6d4505", -- No, %NU. You don't need my help. We would do well together, but you are the one for the job. You can do this. Focus your mind.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9301eff1", "m3_retry_b"}, -- I will.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_failed_focus)

nin_gursawe_convo_m3_retry_b = ConvoScreen:new {
	id = "m3_retry_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d7e41231", -- Good luck. I'll be watching you.
	stopConversation = "true",
	animation = "wave1",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_retry_b)

nin_gursawe_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/corellia_imperial_tier4:s_dcdce64", -- Listen to me. Our targets must be stopped. They are our greatest enemy! They have the potential to be a major thorn in the side of the Empire unless we take care of them now.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier4:s_83502a2", "m4_failed_succeed"}, -- The enemy of the Emperor must be destroyed!
		{"@conversation/corellia_imperial_tier4:s_4af031d3", "m4_failed_fight"}, -- It's brutal up there.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_failed)

nin_gursawe_convo_m4_failed_succeed = ConvoScreen:new {
	id = "m4_failed_succeed",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9bad275c", -- You've never had a more important mission, %NU. You MUST succeed.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_c1ece7d0", "m4_retry"}, -- Yes, Lord Insurgent. I will not fail you.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_failed_succeed)

nin_gursawe_convo_m4_failed_fight = ConvoScreen:new {
	id = "m4_failed_fight",
	leftDialog = "@conversation/corellia_imperial_tier4:s_87f2bc56", -- You have to fight like you've never fought before. Do you understand me?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_d70dba34", "m4_failed_guts"}, -- Yes.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_failed_fight)

nin_gursawe_convo_m4_failed_guts = ConvoScreen:new {
	id = "m4_failed_guts",
	leftDialog = "@conversation/corellia_imperial_tier4:s_edc55445", -- I gave this job to you for a reason. You're my best pilot. Do you have  the guts to go back out there?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier4:s_37e2608d", "m4_retry"}, -- I do not fear danger.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_failed_guts)

nin_gursawe_convo_m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/corellia_imperial_tier4:s_90422eb5", -- Good luck.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_retry)

nin_gursawe_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e705e25f", -- Good work, %NU. You managed to gather me some information that might turn out to be very important. I believe that this will lead us on the right direction.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_fd6077a1", "m1_message"}, -- What was in the message?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_reward)

nin_gursawe_convo_m1_message = ConvoScreen:new {
	id = "m1_message",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e08f9706", -- The message was essentially all in code. There isn't much chance that we will actually be able to find out what it actually told the Velocity. It contained a few phrases, such as, 'the enlightened walks with rancors' and 'keep the skeletons walking the path of misdirection'. Basically if you do not already know what the code words mean you probably will never find out what is being said.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_40cb88ec", "m1_beyond"}, -- I don't understand. How is that useful information?
		{"@conversation/corellia_imperial_tier4:s_6465b813", "m1_theories"}, -- I bet I could figure it out.
		{"@conversation/corellia_imperial_tier4:s_68d65b58", "m1_clue"}, -- We should capture one of the Velocity and make him tell us what it means.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_message)

nin_gursawe_convo_m1_beyond = ConvoScreen:new {
	id = "m1_beyond",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e0aca724", -- One has to look beyond the words of the message itself. The transmission originated from deep in the Dantooine system, so that is a place to start my search. Also it is a good bet that this message came from whoever hired the Velocity, since the message does appear to be instructions of some sort.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_tier4:s_42c52a5", "m1_direction"}, -- I still don't see how this helps us.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_beyond)

nin_gursawe_convo_m1_direction = ConvoScreen:new {
	id = "m1_direction",
	leftDialog = "@conversation/corellia_imperial_tier4:s_5bea4bf3", -- It doesn't matter that you do not know what is going on. All that matters is that I have some direction. When the time comes, I will point you in that direction and together we will find what I am after. For now I will leave you to your own devices. You can continue to take some duty missions from me or go on leave, it really doesn't matter to me. Once I figure out my next move I will let you know.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_direction)

nin_gursawe_convo_m1_theories = ConvoScreen:new {
	id = "m1_theories",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a4f727f1", -- Of course, I have my own theories on what those phrases mean but I am very intrigued to find out what you think they mean.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_592140", "m1_origin"}, -- The first obviously means that only the smart man can deal with danger.
		{"@conversation/corellia_imperial_tier4:s_79d6c690", "m1_origin"}, -- The second means that the Velocity should continue their assault on the Empire.
		{"@conversation/corellia_imperial_tier4:s_493aef07", "m1_direction"}, -- I would need more time and information about our targets.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_theories)

nin_gursawe_convo_m1_origin = ConvoScreen:new {
	id = "m1_origin",
	leftDialog = "@conversation/corellia_imperial_tier4:s_7dd5c9b5", -- Perhaps. Like I said, I have my own theories on what those code phrases mean. But it is not so much what was in the message, but rather where the message was from that interested me. The message originated from deep in the Dantooine system. I believe that will be a good place for me to start my search. For now, you are on stand by. You can take some more duty missions or go on leave. When we are both ready, we will continue.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_origin)

nin_gursawe_convo_m1_clue = ConvoScreen:new {
	id = "m1_clue",
	leftDialog = "@conversation/corellia_imperial_tier4:s_74f79dbe", -- There is very little need for us to do that. They have left me a very large clue without even knowing they did. Instead of trying to figure out what the message actually said I am going to be looking into where the message originated from.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b5e3a1", "m1_dantooine"}, -- What can that tell you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_clue)

nin_gursawe_convo_m1_dantooine = ConvoScreen:new {
	id = "m1_dantooine",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e5dc0118", -- The transmission originated from deep in the Dantooine system, so that is a place to start my search. Also it is a good bet that this message came from whoever hired the Velocity, since the message does appear to be instructions of some sort.  For now I will leave you to your own devices. You can continue to take some duty missions from me or go on leave, it really doesn't matter to me. Once I figure out my next move I will let you know.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_dantooine)

nin_gursawe_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/corellia_imperial_tier4:s_f8880079", -- Welcome back. We have the orders you retrieved from the Velocity in our possession and I will be investigating the freighter shortly. So far, you have performed better than I expected you to be able to.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_dcc126b1", "m2_business"}, -- Just doing my job.
		{"@conversation/corellia_imperial_tier4:s_f83729d0", "m2_better"}, -- I can do better.
		{"@conversation/corellia_imperial_tier4:s_6d6d19f4", "m2_unstoppable"}, -- With the Emperor's blessing, I am unstoppable.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_reward)

nin_gursawe_convo_m2_business = ConvoScreen:new {
	id = "m2_business",
	leftDialog = "@conversation/corellia_imperial_tier4:s_35e6e0c7", -- That is what I like most about you. You are all business. If there isn't anything else I would like to get on with my investigation.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_d56d9c26", "m2_orders"}, -- What were in the orders from the Velocity?
		{"@conversation/corellia_imperial_tier4:s_7fc0dbf6", "m2_standby"}, -- No, Insurgent. I will wait until you need me again.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_business)

nin_gursawe_convo_m2_orders = ConvoScreen:new {
	id = "m2_orders",
	leftDialog = "@conversation/corellia_imperial_tier4:s_92c25c6d", -- It is more of that coded phrasing but I am quite certain I have figured out the code, or at least the general meaning behind the orders. I will tell you more about this once I am certain.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_47e47c9e", "m2_standby"}, -- Very well. I will wait until you need me again.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_orders)

nin_gursawe_convo_m2_standby = ConvoScreen:new {
	id = "m2_standby",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d460a728", -- While I am looking into the latest information that you have brought to me, feel free to take some duty missions or...do whatever you wish. Frankly I don't care which, just as long as you become available when I need you again.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_standby)

nin_gursawe_convo_m2_better = ConvoScreen:new {
	id = "m2_better",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b3f97e26", -- I get the feeling that soon you will have to. Of course, that will not happen until I can have a chance to look into this new information you brought to me.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_e3d62b89", "m2_standby"}, -- Understood. I will leave you to your work.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_better)

nin_gursawe_convo_m2_unstoppable = ConvoScreen:new {
	id = "m2_unstoppable",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e7e4fdc5", -- Do not put to much faith into words, even if they come from the Emperor. Action is the only true way of gaining power and the Emperor only respects people of action. Keep that in mind.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_ce9d7377", "m2_prerogative"}, -- It is the Emperor's prerogative who he takes favor with.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_unstoppable)

nin_gursawe_convo_m2_prerogative = ConvoScreen:new {
	id = "m2_prerogative",
	leftDialog = "@conversation/corellia_imperial_tier4:s_29b41abf", -- Very true. While I am looking into the latest information that you have brought to me, feel free to take some duty missions or...do whatever you wish. Frankly I don't care which, just as long as you become available when I need you again.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_prerogative)

nin_gursawe_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/corellia_imperial_tier4:s_3f2bae5b", -- That pretty much confirms my suspicion. The Velocity are in the Dathomir system, which means the targets are as well. We will get those orders you recovered decoded and see if they lead us any closer to our prey.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_bb5f90b1", "m3_dathomir"}, -- You mean you didn't know for certain that they would be there?
		{"@conversation/corellia_imperial_tier4:s_14c473a", "m3_decoding"}, -- I think that information should be helpful.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_reward)

nin_gursawe_convo_m3_dathomir = ConvoScreen:new {
	id = "m3_dathomir",
	leftDialog = "@conversation/corellia_imperial_tier4:s_43d39a86", -- I was almost certain they were, but the unique nature of Dathomir makes it a little hard to completely detect these things. It doesn't matter now though. We have a confirmation. Also, the ground crew has reported in and there are no signs of any vessels landing on Dathomir recently so I think it is safe to assume the targets are still in space. On a humorous note, the ground crew asked when they could expect to be picked up.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_516e76a2", "m3_decoding"}, -- Then I will have to track the targets down.
		{"@conversation/corellia_imperial_tier4:s_c0036582", "m3_crew"}, -- What did you tell them?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_dathomir)

nin_gursawe_convo_m3_decoding = ConvoScreen:new {
	id = "m3_decoding",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9c7a221c", -- We will begin decoding these orders and see where they lead us. Until then feel free to take some duty missions or go on leave. When you are ready for your next step, we will hunt them down. The time is drawing very near now.
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_decoding)

nin_gursawe_convo_m3_crew = ConvoScreen:new {
	id = "m3_crew",
	leftDialog = "@conversation/corellia_imperial_tier4:s_62c2e765", -- I haven't told them anything. They will either make it to the prison, be eaten by a Rancor, or perhaps worse. They do not matter to me now. All that does matter is catching our prey. We will begin decoding these orders and see where they lead us. Until then feel free to take some duty missions or go on leave. When you are ready for your next step, we will hunt them down.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_crew)

nin_gursawe_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d4500734", -- You have done very well. There are not many people in this entire galaxy who can out-pilot one Jedi much less three.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_d129b116", "m4_jedi"}, -- What! Those were Jedi?
		{"@conversation/corellia_imperial_tier4:s_85e8b1c4", "m4_figured"}, -- I figured that is who we were after.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_reward)

nin_gursawe_convo_m4_jedi = ConvoScreen:new {
	id = "m4_jedi",
	leftDialog = "@conversation/corellia_imperial_tier4:s_15b3b360", -- Who else would garner such attention from the Emperor? I must say that he is very pleased with the outcome. Now that the Jedi are no more, the remaining Velocity should be fairly simple to clean up.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_tier4:s_fe20f03e", "m4_goodbye"}, -- Wait! I still want to know is who you are.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_jedi)

nin_gursawe_convo_m4_figured = ConvoScreen:new {
	id = "m4_figured",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a8fbb11", -- Really? Perhaps you have learned to read between the lines. The Emperor is most pleased with the outcome of this situation. You have done very well.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_8778fe46", "m4_goodbye"}, -- What I want to know is who you are?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_figured)

nin_gursawe_convo_m4_goodbye = ConvoScreen:new {
	id = "m4_goodbye",
	leftDialog = "@conversation/corellia_imperial_tier4:s_84fad79c", -- Too bad. Good bye, %NU. Nice work out there.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_goodbye)

nin_gursawe_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/corellia_imperial_tier4:s_735e94f9", -- So you must be %NU. I have been watching your progress for sometime now.  I must say that I am very impressed, although there ARE a number of areas where you could use improvement... but we will get to that later.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_cdcb7b73", "intro_black_epsilon"}, -- Are you with Black Epsilon, sir?
		{"@conversation/corellia_imperial_tier4:s_2b6c0655", "intro_ego"}, -- Improvement!? You cannot improve perfection.
		{"@conversation/corellia_imperial_tier4:s_c06cf370", "intro_instrument"}, -- I am but a simple instrument of the Empire.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro)

nin_gursawe_convo_intro_black_epsilon = ConvoScreen:new {
	id = "intro_black_epsilon",
	leftDialog = "@conversation/corellia_imperial_tier4:s_644e6e82", -- No, I am not part of Black Epsilon, although I have used their pilots several times in the past and have always been more than satisfied with the results. And do not call me sir. I have no military rank.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_453c3282", "intro_insurgent"}, -- If you are not in the military, who are you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_black_epsilon)

nin_gursawe_convo_intro_insurgent = ConvoScreen:new {
	id = "intro_insurgent",
	leftDialog = "@conversation/corellia_imperial_tier4:s_6f6fe7c5", -- You may call me Insurgent. And let us just say that I have the Emperor's best interests at heart and leave it at that.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_41f35a20", "intro_real_name"}, -- Insurgent isn't your real name, is it?
		{"@conversation/corellia_imperial_tier4:s_fad3519e", "intro_end_a"}, -- What do you need me to do, si... Insurgent?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_insurgent)

nin_gursawe_convo_intro_real_name = ConvoScreen:new {
	id = "intro_real_name",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e031ecbb", -- That is why I like using Black Epsilon pilots. Always thinking unlike your standard neolithic naval pilot. You are correct in your assumption that Insurgent is not my real name. Of course, if you attempt to find out my real name I will be forced to kill you and neither of us want that.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_95c4c876", "intro_end_b"}, -- So noted. What will I be doing for you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_real_name)

nin_gursawe_convo_intro_end_a = ConvoScreen:new {
	id = "intro_end_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_f97238d8", -- It is quite simple. You will be going where I say, when I say, and doing what I say. Until that time comes you have no need to know, so let us just keep it that way. For now I was just simply interested in meeting the pilot who would be working for me face-to-face. I have seen what I need, that is all. Come back and see me a little later, perhaps I will have something for you then.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_a)

nin_gursawe_convo_intro_end_b = ConvoScreen:new {
	id = "intro_end_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_78026113", -- It is quite simple. You will be going where I say, when I say, and doing what I say. Until that time comes you have no need to know, so let us just keep it that way. For now I was just simply interested in meeting the pilot who would be working for me face to-face. I have seen what I need, that is all. Come back and see me a little later, perhaps I will have something for you then.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_b)

nin_gursawe_convo_intro_ego = ConvoScreen:new {
	id = "intro_ego",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a4d2d2a4", -- Very amusing. I had hoped that the stories about your ego were exaggerations, but I can see now that they were right on the mark. To be honest, I do not really care what you think of yourself, as long as you do your job.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_c0dc404f", "intro_rough"}, -- I always do my job.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_ego)

nin_gursawe_convo_intro_rough = ConvoScreen:new {
	id = "intro_rough",
	leftDialog = "@conversation/corellia_imperial_tier4:s_35dc12ce", -- Good. I will have need for a talented pilot very shortly and I think that you might just do very well. You are still a little rough around the edges but I can take care of that. With my help you should become an acceptable pilot.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_a2d93e75", "intro_end_c"}, -- What is it I will be doing for you?
		{"@conversation/corellia_imperial_tier4:s_e4de90b3", "intro_potent"}, -- I don't need your help! I know how to fly.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_rough)

nin_gursawe_convo_intro_end_c = ConvoScreen:new {
	id = "intro_end_c",
	leftDialog = "@conversation/corellia_imperial_tier4:s_c93f02d5", -- It is quite simple. You will be going where I say, when I say, and doing what I say. Until that time comes you have no need to know, so let us just keep it that way. For now I was just simply interested in meeting the pilot who would be working for me face to face. I have seen what I need, that is all. Come back and see me a little later, perhaps I will have something for you then.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_c)

nin_gursawe_convo_intro_potent = ConvoScreen:new {
	id = "intro_potent",
	leftDialog = "@conversation/corellia_imperial_tier4:s_340f88e7", -- And I will make you even more potent. Despite your claim that you are perfection personified, your approach needs some polish. When you are working for me you will gain that polish.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4e7e870d", "intro_end_d"}, -- What exactly will I be doing for you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_potent)

nin_gursawe_convo_intro_end_d = ConvoScreen:new {
	id = "intro_end_d",
	leftDialog = "@conversation/corellia_imperial_tier4:s_50bf402f", -- It is quite simple. You will be going where I say, when I say, and you will  be doing WHAT I say. Until that time comes, you have no need to know, so let us just keep it that way. For now, I was simply interested in meeting my new pilot face-to-face. I have seen what I need, that is all. Come back and see me a little later. Perhaps I will have something for you then.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_d)

nin_gursawe_convo_intro_instrument = ConvoScreen:new {
	id = "intro_instrument",
	leftDialog = "@conversation/corellia_imperial_tier4:s_fd2777e5", -- Ah, one of those. I have worked with people like you in the past and I haven't had any difficulties. I just require that you keep your mind on the task at hand and do not let your fervor cloud your judgment. As long as you are able to do that, we shall not have any problems.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_ca776e30", "intro_who"}, -- Who are you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_instrument)

nin_gursawe_convo_intro_who = ConvoScreen:new {
	id = "intro_who",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d1579156", -- You may call me Insurgent. And let us just say that, much like you, I only have the Emperor's best interests at heart. I, too, live only to serve.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4e718340", "intro_end_e"}, -- Ah, a kindred spirit. It will be a pleasure.
		{"@conversation/corellia_imperial_tier4:s_244c9eec", "intro_end_f"}, -- I will see if that is true.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_who)

nin_gursawe_convo_intro_end_e = ConvoScreen:new {
	id = "intro_end_e",
	leftDialog = "@conversation/corellia_imperial_tier4:s_beec51b5", -- As long as you work for me, you will go where I say, when I say, and you will do what I tell you to do. Until that time comes you have no need to know, so let us just keep it that way. For now, I was simply interested in meeting my new pilot face-to-face. I have seen what I need, that is all. Come back and see me a little later. Perhaps I will have something for you then.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_e)

nin_gursawe_convo_intro_end_f = ConvoScreen:new {
	id = "intro_end_f",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b4a065ba", -- A fanatic and a skeptic. What other surprises do you have in store for me? Do not bother to answer that question. I am sure I will find out in time. For now, it is enough that you do what I say without question. I will have need of you later, but for now you may go. Come back to me when you think you are ready to undertake my task.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_intro_end_f)

nin_gursawe_convo_ready = ConvoScreen:new {
	id = "ready",
	leftDialog = "@conversation/corellia_imperial_tier4:s_cbf9f5e7", -- You are doing well, Pilot. Are you ready for your next assignment?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_36a4e374", "m1_brief"}, -- Yes, I am.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_ready)

nin_gursawe_convo_ready_train = ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2afc3f27", -- You have done very well and it would seem that your skills are improving. I will assist you in your quest for pilot perfection, when man and machine become almost one. What skill would you like to learn? Once you have made your choice, I have a very important task that requires immediate attention.
	stopConversation = "false",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_ready_train)

nin_gursawe_convo_expecting = ConvoScreen:new {
	id = "expecting",
	leftDialog = "@conversation/corellia_imperial_tier4:s_dce56ebd", -- I've been expecting you. And you are late. There is much to be done. Are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_52917b0d", "briefing"}, -- Of course.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_expecting)

nin_gursawe_convo_briefing = ConvoScreen:new {
	id = "briefing",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b3155267", -- A new group of mercenaries, calling themselves the Velocity, have moved into the Dantooine system. I have reason to believe that they are connected to my ultimate targets but more investigation will be needed in order to confirm that suspicion. But for now I need someone to start reducing the numbers of these Velocity mercenaries to a more manageable level.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4ecc8830", "briefing_targets"}, -- Who are your ultimate targets?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_briefing)

nin_gursawe_convo_briefing_targets = ConvoScreen:new {
	id = "briefing_targets",
	leftDialog = "@conversation/corellia_imperial_tier4:s_5e4d41df", -- All in good time. You are not quite ready for that challenge yet. The next task would be protecting the interests of the Emperor in this system. The Velocity mercenaries have been attacking Imperial military freighters, most likely in order to increase their own combat capability. We need escorts to protect our freighters from these attacks.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_3f68df7d", "briefing_smuggling"}, -- Sounds easy enough.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_briefing_targets)

nin_gursawe_convo_briefing_smuggling = ConvoScreen:new {
	id = "briefing_smuggling",
	leftDialog = "@conversation/corellia_imperial_tier4:s_34120baf", -- Of course. Another task that has need for a good pilot is to cull the smuggling aspects of the Velocity mercenaries. It would seem that they are moving the supplies stolen from us to other systems. We need someone to break their supply lines and capture the vessels carrying these goods. The Empire wants its property back.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_362a48e0", "briefing_adrift"}, -- Anything else?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_briefing_smuggling)

nin_gursawe_convo_briefing_adrift = ConvoScreen:new {
	id = "briefing_adrift",
	leftDialog = "@conversation/corellia_imperial_tier4:s_8fd1ce47", -- The Velocity mercenaries have been targeting Imperial ships, as you know. They've left several ships adrift most likely to be picked up at a later time. We need a pilot to meet those ships, assist with repairs, and bring those valuable craft safely back to Imperial hands.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_6b9c2fb8", "duty_menu"}, -- I understand. I would like to take a duty mission.
		{"@conversation/corellia_imperial_tier4:s_d26d7ae1", "duty_declined"}, -- I don't think I will take a duty mission at this time.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_briefing_adrift)

nin_gursawe_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/corellia_imperial_tier4:s_beb66be", -- What duty mission would you like to undertake?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_99bb69ca", "duty_destroy"}, -- Shooting down mercenaries? That's not business; that's pleasure.
		{"@conversation/corellia_imperial_tier4:s_4349156c", "duty_escort"}, -- I can escort those ships, no problem.
		{"@conversation/corellia_imperial_tier4:s_b881db2e", "duty_recovery"}, -- I hate smugglers. I'll take that job.
		{"@conversation/corellia_imperial_tier4:s_98338b18", "duty_rescue"}, -- Sure. I'll get those ships.
		{"@conversation/corellia_imperial_tier4:s_49805f81", "briefing"}, -- Can I hear the briefing again?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_menu)

nin_gursawe_convo_duty_declined = ConvoScreen:new {
	id = "duty_declined",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9caa883f", -- Very well, come back to me if you decide differently.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_declined)

nin_gursawe_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1c6fdb34", -- Excellent. You're clear to leave.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_destroy)

nin_gursawe_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/corellia_imperial_tier4:s_828612f", -- The Empire does a lot of good in this system. It provides work for people who need it. It's important that the equilibrium not be disturbed. Take good care of those freighters.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_escort)

nin_gursawe_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/corellia_imperial_tier4:s_65da4fa5", -- I'm curious about this smuggler. See what you can find out. Let me know what he's carrying.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_recovery)

nin_gursawe_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b456d97d", -- It's good work. The Emperor will appreciate your efforts.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_duty_rescue)

nin_gursawe_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/corellia_imperial_tier4:s_966e7d64", -- You have great potential, but you still have much to learn before I can make use of your talents. I have a few odd jobs that I need taken care of. If you wish I can give you one of these duty missions. Or would you like to hear the briefing again?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_99bb69ca", "duty_destroy"}, -- Shooting down mercenaries? That's not business; that's pleasure.
		{"@conversation/corellia_imperial_tier4:s_4349156c", "duty_escort"}, -- I can escort those ships, no problem.
		{"@conversation/corellia_imperial_tier4:s_b881db2e", "duty_recovery"}, -- I hate smugglers. I'll take that job.
		{"@conversation/corellia_imperial_tier4:s_98338b18", "duty_rescue"}, -- Sure. I'll get those ships.
		{"@conversation/corellia_imperial_tier4:s_49805f81", "briefing"}, -- Can I hear the briefing again?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_tier4_incomplete)

nin_gursawe_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a74ee1d8", -- I appreciate the work you have done for me in the past but really have nothing more for you to do. Unless you would be interested in some duties that I still need help with.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_99bb69ca", "duty_destroy"}, -- Shooting down mercenaries? That's not business; that's pleasure.
		{"@conversation/corellia_imperial_tier4:s_4349156c", "duty_escort"}, -- I can escort those ships, no problem.
		{"@conversation/corellia_imperial_tier4:s_b881db2e", "duty_recovery"}, -- I hate smugglers. I'll take that job.
		{"@conversation/corellia_imperial_tier4:s_98338b18", "duty_rescue"}, -- Sure. I'll get those ships.
		{"@conversation/corellia_imperial_tier4:s_49805f81", "briefing"}, -- Can I hear the briefing again?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_here_for_work)

nin_gursawe_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1d2760a0", -- So, you seem to have made a fan. I can tell by your look that you do not have any idea what I am talking about. I have just received orders from High Command that you are being transferred.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_6d9530c5", "transfer_declann"}, -- Transferred? Who am I being transferred to this time?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer)

nin_gursawe_convo_transfer_declann = ConvoScreen:new {
	id = "transfer_declann",
	leftDialog = "@conversation/corellia_imperial_tier4:s_c610ccb7", -- I have been ordered to have you moved under Nial Declann's command. I am not very used to taking orders from one quite so low but since I am through with you I see no reason to fight him on this. You are to report to Theed palace and present yourself to Nial immediately.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_817cf33", "transfer_who"}, -- Who is Nial Declann?
		{"@conversation/corellia_imperial_tier4:s_4b6d4db", "transfer_grand_admiral"}, -- Nial Declann? Grand Admiral Nial Declann!
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer_declann)

nin_gursawe_convo_transfer_who = ConvoScreen:new {
	id = "transfer_who",
	leftDialog = "@conversation/corellia_imperial_tier4:s_fde2347a", -- I would highly suggest that you only refer to him as Grand Admiral or better yet...sir. He is one of twelve top navy men in the entire galaxy and a definite favorite of the Emperor, though I have never quite figured out why...perhaps one day. Regardless, I have accepted his transfer and suggest you get to Theed in a hurry.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9ec3be5d", "transfer_done_a"}, -- I will do so. Thank you for allowing me to assist you in your assignment.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer_who)

nin_gursawe_convo_transfer_done_a = ConvoScreen:new {
	id = "transfer_done_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_94a6034a", -- It is I who thank you. It is very rare to meet a competent pilot who can think for themselves. I wish you the best with your new assignment.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer_done_a)

nin_gursawe_convo_transfer_grand_admiral = ConvoScreen:new {
	id = "transfer_grand_admiral",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d2794755", -- One and the same. One of the original members of the twelve Grand Admirals of the Imperial Fleet, member of the High Council, and personal favorite to the Empire. Overall a very unpleasant man. But it is never wise to make enemies when one can avoid it, which is why you are going to report to him immediately.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_11c1ca52", "transfer_done_b"}, -- You have the authority to choose to obey a Grand Admiral? Insurgent, who are you?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer_grand_admiral)

nin_gursawe_convo_transfer_done_b = ConvoScreen:new {
	id = "transfer_done_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_69231042", -- Having the authority to ignore a Grand Admiral's order is very different than actually using that authority. Just because someone can do something doesn't always mean that they should. I am Insurgent and I am but a humble servant of the Emperor. Now, I suggest you do not keep the Nial waiting. While I might be able to get away with it you most certainly cannot.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_transfer_done_b)

nin_gursawe_convo_m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b52941c3", -- Now it is time to put your training to good use. The time has come for us to find out more about who these Velocity mercenaries are. I have my suspicious about who is pulling their strings but I must be certain before I act.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_f1d64636", "s_8c64bf19"}, -- Ah, yes. I am even more deadly than before!
		{"@conversation/corellia_imperial_tier4:s_993596a8", "s_2751f674"}, -- Now that I have more training, I am pretty sure I am unstoppable.
		{"@conversation/corellia_imperial_tier4:s_b2f1386a", "s_f2f68275"}, -- I will crush our enemies.
		{"@conversation/corellia_imperial_tier4:s_a476ea3d", "s_9ce82616"}, -- Ready and willing, sir.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_brief)

nin_gursawe_convo_m1_brief_trained = ConvoScreen:new {
	id = "m1_brief_trained",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e3a57b46", -- Now it is time to put your training to good use. The time has come for us to find out more about who these Velocity mercenaries are. I have my suspicious about who is pulling their strings, but I must be certain before I act.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_f1d64636", "s_8c64bf19"}, -- Ah, yes. I am even more deadly than before!
		{"@conversation/corellia_imperial_tier4:s_993596a8", "s_2751f674"}, -- Now that I have more training, I am pretty sure I am unstoppable.
		{"@conversation/corellia_imperial_tier4:s_b2f1386a", "s_f2f68275"}, -- I will crush our enemies.
		{"@conversation/corellia_imperial_tier4:s_a476ea3d", "s_9ce82616"}, -- Ready and willing, sir.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_brief_trained)

nin_gursawe_convo_s_8c64bf19 = ConvoScreen:new {
	id = "s_8c64bf19",
	leftDialog = "@conversation/corellia_imperial_tier4:s_8c64bf19", -- Indeed. And the time is at hand for you to prove just how deadly you can be. I want to know as much as we can about the Velocity mercenary operation in this system. More than anything, I want to know who hired them.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_bb26b12d", "s_27b64a53"}, -- Who is it you are actually looking for?
		{"@conversation/corellia_imperial_tier4:s_5e2181b5", "s_1fff2e"}, -- I take it they are to be killed?
		{"@conversation/corellia_imperial_tier4:s_ca2b4f36", "s_7a5034fe"}, -- I can capture one and we can 'question' him together.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_8c64bf19)

nin_gursawe_convo_s_2751f674 = ConvoScreen:new {
	id = "s_2751f674",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2751f674", -- If you say so. But I would suggest that you not start counting your victory quite yet. If this was an easy operation, I would not be involved.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_1d8537b", "s_e7575630"}, -- Hmm, well what is it you want me to do?
		{"@conversation/corellia_imperial_tier4:s_b9c73c6d", "s_e7575630"}, -- I am ready for whatever you need me to do.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_2751f674)

nin_gursawe_convo_s_f2f68275 = ConvoScreen:new {
	id = "s_f2f68275",
	leftDialog = "@conversation/corellia_imperial_tier4:s_f2f68275", -- All in good time. Right now I have a job that may not require any crushing of anyone. Of course, that is a best case scenario and when has anything gone according to that?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_ae99b26e", "s_e7575630"}, -- So what am I am going to be doing?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_f2f68275)

nin_gursawe_convo_s_9ce82616 = ConvoScreen:new {
	id = "s_9ce82616",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9ce82616", -- I thought I told you to simply refer to me as Insurgent! I cannot use someone who is incapable of even obeying the simplest of orders.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_7423a2e5", "s_79bf4ef1"}, -- Sorry, Insurgent. Force of habit.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_9ce82616)

nin_gursawe_convo_s_79bf4ef1 = ConvoScreen:new {
	id = "s_79bf4ef1",
	leftDialog = "@conversation/corellia_imperial_tier4:s_79bf4ef1", -- I see. Must be a military thing. Usually, members of Black Epsilon are not quite so rigid, which is why I like using them. Despite that, I still believe you will do. Now back to the matter at hand. We need to find out more about the Velocity. I want to know everything I can about their operations in this system, especially who they are working for.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4d7b8699", "s_6a902b99"}, -- Should I just go out there and ask them or do you actually have a plan?
		{"@conversation/corellia_imperial_tier4:s_ca2b4f36", "s_7a5034fe"}, -- I can capture one and we can 'question' him together.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_79bf4ef1)

nin_gursawe_convo_s_e7575630 = ConvoScreen:new {
	id = "s_e7575630",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e7575630", -- I need to find out more about the Velocity and more specifically who hired them. As I said before, I have a good idea as to who their benefactor is, but I have never liked following hunches. You are going to get that information for me.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4d7b8699", "s_6a902b99"}, -- Should I just go out there and ask them or do you actually have a plan?
		{"@conversation/corellia_imperial_tier4:s_ccefd6f4", "s_b8896d92"}, -- It would be better if we had a live captive.
		{"@conversation/corellia_imperial_tier4:s_ca2b4f36", "s_7a5034fe"}, -- I can capture one and we can 'question' him together.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_e7575630)

nin_gursawe_convo_s_b8896d92 = ConvoScreen:new {
	id = "s_b8896d92",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b8896d92", -- And how do you expect to find this officer? Just fly up into space and hope that one is waiting for you? You are eager enough but you should think before you speak up.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_83a5b2ca", "s_6a902b99"}, -- Sorry, Insurgent. So how will I find this officer?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_b8896d92)

nin_gursawe_convo_s_27b64a53 = ConvoScreen:new {
	id = "s_27b64a53",
	leftDialog = "@conversation/corellia_imperial_tier4:s_27b64a53", -- I will explain that shortly. Once we find them they must be killed. We think that they are attempting to build power, either to help the Rebellion or for their own reasons. That is why they have the Velocity working for them.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_f8b02865", "s_cb55c240"}, -- What do I do?
		{"@conversation/corellia_imperial_tier4:s_95dd869a", "s_5fb89d5e"}, -- It must be expensive to pay for an entire mercenary outfit.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_27b64a53)

nin_gursawe_convo_s_1fff2e = ConvoScreen:new {
	id = "s_1fff2e",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1fff2e", -- Yes, once we find them they must be killed. We think that they are attempting to build power, either to help the Rebellion or for their own reasons. That is why they have the Velocity working for them.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_95dd869a", "s_5fb89d5e"}, -- It must be expensive to pay for an entire mercenary outfit.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_1fff2e)

nin_gursawe_convo_s_5fb89d5e = ConvoScreen:new {
	id = "s_5fb89d5e",
	leftDialog = "@conversation/corellia_imperial_tier4:s_5fb89d5e", -- I doubt if these particular people had any problems convincing the Velocity to work for them. They can be very persuasive when they need to be. I would be surprised if the Velocity is being paid, which is why they attack our supply freighters...in order to pay for their operations.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_929e4e42", "s_74052171"}, -- How should I proceed?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_5fb89d5e)

nin_gursawe_convo_s_74052171 = ConvoScreen:new {
	id = "s_74052171",
	leftDialog = "@conversation/corellia_imperial_tier4:s_74052171", -- I have formulated a patrol route that I need you to follow. While on this patrol, you will scan the region for signs of a Velocity officer's vessel. I am hoping that an officer will have valuable information that will allow us to dig deeper into uncovering who they are working for.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9205783d", "m1_accept_a"}, -- What should I do if I locate the officer?
		{"@conversation/corellia_imperial_tier4:s_229e4f7a", "m1_accept_b"}, -- Why are you so interested in who hired these mercenaries?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_74052171)

nin_gursawe_convo_s_cb55c240 = ConvoScreen:new {
	id = "s_cb55c240",
	leftDialog = "@conversation/corellia_imperial_tier4:s_cb55c240", -- I have formulated a patrol route that I need you to follow. While on this patrol you will scan the region for signs of a Velocity officer's vessel. I am hoping that an officer will contain valuable information that will allow us to dig deeper into uncovering who they are working for.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9205783d", "m1_accept_a"}, -- What should I do if I locate the officer?
		{"@conversation/corellia_imperial_tier4:s_229e4f7a", "m1_accept_c"}, -- Why are you so interested in who hired these mercenaries?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_cb55c240)

nin_gursawe_convo_s_6a902b99 = ConvoScreen:new {
	id = "s_6a902b99",
	leftDialog = "@conversation/corellia_imperial_tier4:s_6a902b99", -- Glad you asked! I have formulated a patrol based on the Velocity fighter movements that I believe will take you close enough to recognize a Velocity officer's vessel with short-range scanning. Follow the patrol route and find me an officer.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_af6c1480", "m1_accept_d"}, -- An officer. Check.
		{"@conversation/corellia_imperial_tier4:s_596bf3ab", "m1_accept_e"}, -- Excellent. I take it that it is time for me to do my thing?
		{"@conversation/corellia_imperial_tier4:s_9205783d", "m1_accept_a"}, -- What should I do if I locate the officer?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_6a902b99)

nin_gursawe_convo_s_7a5034fe = ConvoScreen:new {
	id = "s_7a5034fe",
	leftDialog = "@conversation/corellia_imperial_tier4:s_7a5034fe", -- Your zeal is much appreciated but if everything goes according to my plan we will not have to get our hands dirty in that fashion. All you need to do is to follow a patrol route that I have formulated based off of the mercenary movements and use short range scans to locate a Velocity officer.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_9e9b2154", "m1_accept_f"}, -- I don't see where the fun in that is but if it is as the Emperor will...
		{"@conversation/corellia_imperial_tier4:s_c4a2f234", "m1_accept_d"}, -- Completely understood, Insurgent.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_7a5034fe)

nin_gursawe_convo_m1_accept_a = ConvoScreen:new {
	id = "m1_accept_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_cf2329c0", -- You mean, WHEN you locate the officer. Naturally, I want you to inspect the officer for any information that we can use to help us track down the people who hired the mercenaries. I could care less about the Velocity...I just want the ones who hired them. Now get on with your patrol. I am not known to be a patient man.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_a)

nin_gursawe_convo_m1_accept_b = ConvoScreen:new {
	id = "m1_accept_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a6916467", -- I suggest you simply focus on finding me any information that an officer can produce. If you pay attention, I am sure all will be revealed in time. Now you had best get on with my patrol. I am not well known for my patience.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_b)

nin_gursawe_convo_m1_accept_c = ConvoScreen:new {
	id = "m1_accept_c",
	leftDialog = "@conversation/corellia_imperial_tier4:s_291ab9fa", -- Again with a question whose answer you are not ready for. I suggest you simply focus on finding me any information that an officer can produce. If you pay attention, I am sure all will be revealed in time. Now you had best get on with my patrol. I am not well known for my patience.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_c)

nin_gursawe_convo_m1_accept_d = ConvoScreen:new {
	id = "m1_accept_d",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e1d956f4", -- Once you locate the officer, search his vessel for any information that will progress my investigation forward. Now, get on with that patrol. I am not well known for my patience.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_d)

nin_gursawe_convo_m1_accept_e = ConvoScreen:new {
	id = "m1_accept_e",
	leftDialog = "@conversation/corellia_imperial_tier4:s_953d9a9c", -- It is. Now get on with the patrol. I am in a hurry to get this information and I have never been well known for patience.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_e)

nin_gursawe_convo_m1_accept_f = ConvoScreen:new {
	id = "m1_accept_f",
	leftDialog = "@conversation/corellia_imperial_tier4:s_241c37e7", -- Try not to be disappointed. We are going to be doing the Emperor's bidding, after all. Once you have located the Velocity officer, inspect the vessel for anything that might be used to further my investigation.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m1_accept_f)

nin_gursawe_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1138832b", -- I have another little job that I want you to address. My instincts were correct. I was right to tell you to search that area.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_596bf3ab", "s_80bab111"}, -- Excellent. I take it that it is time for me to do my thing?
		{"@conversation/corellia_imperial_tier4:s_5a23ab6f", "s_707841db"}, -- What did you find, Insurgent?
		{"@conversation/corellia_imperial_tier4:s_3bdff7cb", "s_8a63a671"}, -- What is it you require of me?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_brief)

nin_gursawe_convo_m2_brief_trained = ConvoScreen:new {
	id = "m2_brief_trained",
	leftDialog = "@conversation/corellia_imperial_tier4:s_8ba804b8", -- Very well; here is your skill. And now I have another little job that I want you to address. My instincts were correct. I was right to tell you to search that area.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_596bf3ab", "s_80bab111"}, -- Excellent. I take it that it is time for me to do my thing?
		{"@conversation/corellia_imperial_tier4:s_5a23ab6f", "s_707841db"}, -- What did you find, Insurgent?
		{"@conversation/corellia_imperial_tier4:s_3bdff7cb", "s_8a63a671"}, -- What is it you require of me?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_brief_trained)

nin_gursawe_convo_s_80bab111 = ConvoScreen:new {
	id = "s_80bab111",
	leftDialog = "@conversation/corellia_imperial_tier4:s_80bab111", -- Yes, it is. There is a freighter that appears to be on autopilot flying on the outskirts of the system that sent the signal. I have it on very good authority that my targets were on board that vessel shortly before it sent the signal.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_6af70645", "s_b2fb027c"}, -- So they are on the freighter?
		{"@conversation/corellia_imperial_tier4:s_2d7994ed", "s_3573ecdf"}, -- How do you know that?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_80bab111)

nin_gursawe_convo_s_707841db = ConvoScreen:new {
	id = "s_707841db",
	leftDialog = "@conversation/corellia_imperial_tier4:s_707841db", -- It took me a little while but I managed to find the source of the transmission. There is a freighter that appears to be on autopilot flying on the outskirts of the system that sent the signal. I have it on very good authority that my targets were on board that vessel shortly before it sent the signal.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_a67cea0d", "s_23c3015a"}, -- Whose authority?
		{"@conversation/corellia_imperial_tier4:s_64a73278", "m2_accept_a"}, -- Do you want me to retrieve the vessel?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_707841db)

nin_gursawe_convo_s_8a63a671 = ConvoScreen:new {
	id = "s_8a63a671",
	leftDialog = "@conversation/corellia_imperial_tier4:s_8a63a671", -- It took me a little while but I managed to find the source of the transmission. There is a freighter that appears to be on autopilot flying on the outskirts of the system that sent the signal. I have it on very good authority that my targets were on board that vessel shortly before it sent the signal. I require that freighter.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_6af70645", "s_a41ab42f"}, -- So they are on the freighter?
		{"@conversation/corellia_imperial_tier4:s_ed88b4e2", "m2_accept_b"}, -- Then it shall be yours.
		{"@conversation/corellia_imperial_tier4:s_b31fa56c", "m2_accept_b"}, -- I can handle that.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_8a63a671)

nin_gursawe_convo_s_b2fb027c = ConvoScreen:new {
	id = "s_b2fb027c",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b2fb027c", -- No. They evacuated the vessel for parts unknown before the message was sent. I am highly surprised that the Velocity did not destroy the freighter, or perhaps they just haven't gotten around to it yet. You must get me that freighter.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_e244a0f9", "m2_accept_c"}, -- Or it could be a trap.
		{"@conversation/corellia_imperial_tier4:s_ed88b4e2", "m2_accept_b"}, -- Then it shall be yours.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_b2fb027c)

nin_gursawe_convo_s_3573ecdf = ConvoScreen:new {
	id = "s_3573ecdf",
	leftDialog = "@conversation/corellia_imperial_tier4:s_3573ecdf", -- I have my...sources. But you can rest assured that the vessel is currently on autopilot and should be an easy target. It probably will have auto defenses on but for a skilled pilot like yourself those should be nothing. I would like to examine that freighter and see if it contains any clues about my targets whereabouts.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_5bea5f9", "s_b3a57003"}, -- Your sources? What does that mean?
		{"@conversation/corellia_imperial_tier4:s_8fe70af3", "m2_accept_d"}, -- This will not take me very long.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_3573ecdf)

nin_gursawe_convo_s_b3a57003 = ConvoScreen:new {
	id = "s_b3a57003",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b3a57003", -- What makes you think that I would share any of my secrets with you? We are not friends. You are a tool and I will use you in any way that I see fit. A craftsman does not explain what he is doing to his wrench, does he? Be thankful for what I do tell you.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_2fa1f209", "m2_accept_e"}, -- Fine. If that is the way it is.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_b3a57003)

nin_gursawe_convo_s_23c3015a = ConvoScreen:new {
	id = "s_23c3015a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_23c3015a", -- I have spoken with the Emperor and he has told me many things about those I seek. It is on his command that you are to capture and protect this freighter so I can investigate it.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_7ef4aae8", "m2_accept_f"}, -- Understood, Insurgent. I will retrieve their freighter in one piece.
		{"@conversation/corellia_imperial_tier4:s_e93d5171", "m2_accept_f"}, -- Then it shall be done.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_23c3015a)

nin_gursawe_convo_s_a41ab42f = ConvoScreen:new {
	id = "s_a41ab42f",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a41ab42f", -- The freighter's passengers left shortly before the transmission was sent and I must admit I am surprised that freighter has not been destroyed. Perhaps the Velocity are being slack in their duty, or perhaps it is a trap. Either way I care not. You are to recover that freighter for me.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_64a73278", "m2_accept_g"}, -- Do you want me to retrieve the vessel?
		{"@conversation/corellia_imperial_tier4:s_7ef4aae8", "m2_accept_f"}, -- Understood, Insurgent. I will retrieve their freighter in one piece.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_a41ab42f)

nin_gursawe_convo_m2_accept_a = ConvoScreen:new {
	id = "m2_accept_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_da6d3376", -- Yes. The vessel is unmanned, but I think it may still contain what I am looking for. Be warned that the vessel probably has automatic defenses, but since it is just a freighter I doubt they will be any issue for you. Keep your eyes open though:  If the Velocity meant to destroy the ship and haven't yet, your taking it will draw them out in a hurry. Good luck, pilot.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_a)

nin_gursawe_convo_m2_accept_b = ConvoScreen:new {
	id = "m2_accept_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_996a0939", -- Be wary, %NU. I am surprised that the Velocity have not already destroyed this freighter. I think that when you capture the vessel they will attack in force. But that shouldn't be anything you cannot handle. The Emperor's bless be on you.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_b)

nin_gursawe_convo_m2_accept_c = ConvoScreen:new {
	id = "m2_accept_c",
	leftDialog = "@conversation/corellia_imperial_tier4:s_aa1396ab", -- That is a risk I am willing to let you take. One way or the other get me that freighter. Show me the vaunted skill you are constantly claiming your possess. Good luck to you, %NU.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_c)

nin_gursawe_convo_m2_accept_d = ConvoScreen:new {
	id = "m2_accept_d",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9d4fc33d", -- I didn't assume that it would. One last thing though. I am surprised that the Velocity have not destroyed the vessel, although it is possible that they just haven't gotten around to it yet. I would guess that if their intention was to destroy the ship they will come swarming once you take it.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_d)

nin_gursawe_convo_m2_accept_e = ConvoScreen:new {
	id = "m2_accept_e",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e37138ed", -- That is the way it is. I suggest you show some caution when recovering that freighter. I am surprised that the Velocity have not destroyed it already but I would imagine that you taking it will cause them some distress. Make sure that you get that freighter back to me intact. You are dismissed.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_e)

nin_gursawe_convo_m2_accept_f = ConvoScreen:new {
	id = "m2_accept_f",
	leftDialog = "@conversation/corellia_imperial_tier4:s_99f23e5f", -- Be warned that the vessel probably has automatic defenses but since it is just a freighter I doubt they will be any issue for you. Keep your eyes open though, if the Velocity meant to destroy the ship and haven't yet, your taking it will draw them out in a hurry. Good luck, pilot.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_f)

nin_gursawe_convo_m2_accept_g = ConvoScreen:new {
	id = "m2_accept_g",
	leftDialog = "@conversation/corellia_imperial_tier4:s_410ca3d8", -- You are catching on, good. Now no more talk. Go get me that freighter and bring it back to me. I have wasted more than enough of my time dealing with your ego. I really hope that you don't run into any unforeseen problems out there. Go!
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m2_accept_g)

nin_gursawe_convo_m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/corellia_imperial_tier4:s_4faccfdf", -- I have need of your abilities yet again. It would seem that you are now even more important to this operation than ever before.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b4876691", "s_cc949f12"}, -- What is your command, my lord?
		{"@conversation/corellia_imperial_tier4:s_dbfcbbf", "s_147257b1"}, -- Haven't I already been doing your job?
		{"@conversation/corellia_imperial_tier4:s_3e9d32e0", "s_415093c5"}, -- What about the orders I recovered from the Velocity?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_brief)

nin_gursawe_convo_s_415093c5 = ConvoScreen:new {
	id = "s_415093c5",
	leftDialog = "@conversation/corellia_imperial_tier4:s_415093c5", -- Yes, it would seem that those were not quite as important as I originally thought they would be. From what I understand of the code it simply told the Velocity to continue their operations in this system until they were told otherwise.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_657816d", "s_b19d5f06"}, -- You really haven't told me anything.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_415093c5)

nin_gursawe_convo_s_b19d5f06 = ConvoScreen:new {
	id = "s_b19d5f06",
	leftDialog = "@conversation/corellia_imperial_tier4:s_b19d5f06", -- Just because I might be lax on the discipline does not mean that I will tolerate any lip from the likes of you. I suggest you do your best to stay in my good graces.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_c4a2f234", "s_cc949f12"}, -- Completely understood, Insurgent.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_b19d5f06)

nin_gursawe_convo_s_147257b1 = ConvoScreen:new {
	id = "s_147257b1",
	leftDialog = "@conversation/corellia_imperial_tier4:s_147257b1", -- You have simply done what I told you to do in order to assist me in tracking down my targets. I never intended you to have to face them in combat, but it would seem that I do not have any other choice.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_e477225c", "s_cafb4d3"}, -- Who are your targets?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_147257b1)

nin_gursawe_convo_s_cc949f12 = ConvoScreen:new {
	id = "s_cc949f12",
	leftDialog = "@conversation/corellia_imperial_tier4:s_cc949f12", -- First, I think it is time for me to better explain what my mission is. I am afraid that I am going to have to place much of my responsibility on your shoulders because of circumstances out of my control. It will become far more dangerous for you from here on out.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_37e2608d", "s_2f35ade3"}, -- I do not fear danger.
		{"@conversation/corellia_imperial_tier4:s_e477225c", "s_cafb4d3"}, -- Who are your targets?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_cc949f12)

nin_gursawe_convo_s_2f35ade3 = ConvoScreen:new {
	id = "s_2f35ade3",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2f35ade3", -- I hope so. My targets are criminals that have eluded Imperial justice since the days of the Old Republic. The Emperor has been searching for them for a very long time, finally discovered a lead with these Velocity mercenaries, and sent me to deal with these criminals.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_33b79521", "s_ffcc3ac9"}, -- Why would the Emperor concern himself with criminals?
		{"@conversation/corellia_imperial_tier4:s_f74915b8", "s_c19cc229"}, -- How many of these criminals are there?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_2f35ade3)

nin_gursawe_convo_s_cafb4d3 = ConvoScreen:new {
	id = "s_cafb4d3",
	leftDialog = "@conversation/corellia_imperial_tier4:s_cafb4d3", -- My targets are criminals that have eluded Imperial justice since the days of the Old Republic. The Emperor has been searching for them for a very long time, finally discovered a lead with these Velocity mercenaries, and sent me to deal with these criminals.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_33b79521", "s_ffcc3ac9"}, -- Why would the Emperor concern himself with criminals?
		{"@conversation/corellia_imperial_tier4:s_f74915b8", "s_c19cc229"}, -- How many of these criminals are there?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_cafb4d3)

nin_gursawe_convo_s_ffcc3ac9 = ConvoScreen:new {
	id = "s_ffcc3ac9",
	leftDialog = "@conversation/corellia_imperial_tier4:s_ffcc3ac9", -- Let us just say that these are 'special' criminals who at one time threatened the Emperor. After this much time we finally have a chance to deal out justice on them and cannot allow them to escape again. Do you understand?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_4c9ca3b6", "s_a84b9540"}, -- I don't understand. What do you mean?
		{"@conversation/corellia_imperial_tier4:s_c4a2f234", "s_912bb601"}, -- Completely understood, Insurgent.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_ffcc3ac9)

nin_gursawe_convo_s_a84b9540 = ConvoScreen:new {
	id = "s_a84b9540",
	leftDialog = "@conversation/corellia_imperial_tier4:s_a84b9540", -- I never assumed that the likes of you would. That is why I think you will at least stand a chance in bringing my targets to justice as my stand in.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_e477225c", "s_912bb601"}, -- Who are your targets?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_a84b9540)

nin_gursawe_convo_s_912bb601 = ConvoScreen:new {
	id = "s_912bb601",
	leftDialog = "@conversation/corellia_imperial_tier4:s_912bb601", -- My targets have eluded Imperial justice since the days of the Old Republic. They are all veterans of the Clone Wars. The Emperor himself has declared that they are to be hunted down and killed in order to neutralize their threat. These are very dangerous men.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b2b5f713", "s_556fb99a"}, -- The Clone Wars? What threat could these old criminals possibly be?
		{"@conversation/corellia_imperial_tier4:s_be6c531e", "s_556fb99a"}, -- Clone wars? So our feared enemies are a bunch of old men?
		{"@conversation/corellia_imperial_tier4:s_f4749d1d", "s_e8da36ce"}, -- Impressive resume. This might actually be a challenge.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_912bb601)

nin_gursawe_convo_s_556fb99a = ConvoScreen:new {
	id = "s_556fb99a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_556fb99a", -- So much more than you could possibly imagine. They have great knowledge and skill. What they might have lost with youth, I am sure they gained in experience. Do not discount them simply because of their age.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_f74915b8", "s_c19cc229"}, -- How many of these criminals are there?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_556fb99a)

nin_gursawe_convo_s_e8da36ce = ConvoScreen:new {
	id = "s_e8da36ce",
	leftDialog = "@conversation/corellia_imperial_tier4:s_e8da36ce", -- You could say that. There are three of them. Nej'a Bertolo, Onli Shi'en, and Tiberus Anderlock. Every one a very dangerous individual. They were my targets and now they are yours. You are going to have to be the one to finally bring about their demise.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_d2ae8b94", "s_556fb99a"}, -- How tough can they be?
		{"@conversation/corellia_imperial_tier4:s_ebbe675b", "s_ea47a197"}, -- No problem. Just point in the right direction.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_e8da36ce)

nin_gursawe_convo_s_c19cc229 = ConvoScreen:new {
	id = "s_c19cc229",
	leftDialog = "@conversation/corellia_imperial_tier4:s_c19cc229", -- Three. Nej'a Bertolo, Onli Shi'en, and Tiberus Anderlock. Every one a very dangerous individual. They were my targets and now they are yours. You are going to have to be the one to finally bring about their demise.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_ebbe675b", "s_ea47a197"}, -- No problem. Just point in the right direction.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_c19cc229)

nin_gursawe_convo_s_ea47a197 = ConvoScreen:new {
	id = "s_ea47a197",
	leftDialog = "@conversation/corellia_imperial_tier4:s_ea47a197", -- The freighter you recovered told me much more than was intended. My targets were careful but not careful enough. Their mercenaries force really made a mistake by not destroying that freighter after it sent its final transmission.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_5babb29c", "s_63378cc1"}, -- What was it you found?
		{"@conversation/corellia_imperial_tier4:s_5a23ab6f", "s_67a8d328"}, -- What did you find, Insurgent?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_ea47a197)

nin_gursawe_convo_s_63378cc1 = ConvoScreen:new {
	id = "s_63378cc1",
	leftDialog = "@conversation/corellia_imperial_tier4:s_63378cc1", -- They wiped the databanks, cleared out the logs, and destroyed the flight recorder but they left behind traces of themselves all over the vessel. It was those traces which have pointed me in the direction of where they went.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_6b6c3181", "s_31cfa803"}, -- Where did they go?
		{"@conversation/corellia_imperial_tier4:s_2d7994ed", "s_2e6aa8f3"}, -- How do you know that?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_63378cc1)

nin_gursawe_convo_s_67a8d328 = ConvoScreen:new {
	id = "s_67a8d328",
	leftDialog = "@conversation/corellia_imperial_tier4:s_67a8d328", -- The freighter you brought back told me everything. Those three used it to help leave the system after your operation started to put the heat on them. They sent the transmission, wiped all the databanks, boarded their fighters, and left the system.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_22d9230a", "s_2e6aa8f3"}, -- Then what could you possibly learn from it?
		{"@conversation/corellia_imperial_tier4:s_d9059da1", "s_31cfa803"}, -- Hmmm...then where did the criminals go?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_67a8d328)

nin_gursawe_convo_s_2e6aa8f3 = ConvoScreen:new {
	id = "s_2e6aa8f3",
	leftDialog = "@conversation/corellia_imperial_tier4:s_2e6aa8f3", -- The unseen sometimes can tell you far more than what is right in front of your eyes. You can learn to see things that others cannot with the proper training and lets just leave it at that. What I did learn was that our targets went to the one place I cannot follow...Dathomir.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b8088c9b", "s_34acb72a"}, -- Why can you not follow them?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_2e6aa8f3)

nin_gursawe_convo_s_31cfa803 = ConvoScreen:new {
	id = "s_31cfa803",
	leftDialog = "@conversation/corellia_imperial_tier4:s_31cfa803", -- They have gone to the one place I cannot follow. They have gone to the Dathomir system.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_b8088c9b", "s_34acb72a"}, -- Why can you not follow them?
		{"@conversation/corellia_imperial_tier4:s_47ffecb6", "s_34acb72a"}, -- What does that have to do with me taking on more responsibility?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_31cfa803)

nin_gursawe_convo_s_34acb72a = ConvoScreen:new {
	id = "s_34acb72a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_34acb72a", -- Because it has been forbidden for me to follow them there. I do not know why I am not allowed to follow my prey, but I do not question those orders. It will be up to you to finish the job that was started so long ago.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_579dbb01", "s_d26b0750"}, -- Wouldn't it make more sense to launch a full scale attack on them?
		{"@conversation/corellia_imperial_tier4:s_929e4e42", "s_9f2ab4a0"}, -- How should I proceed?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_34acb72a)

nin_gursawe_convo_s_d26b0750 = ConvoScreen:new {
	id = "s_d26b0750",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d26b0750", -- The last thing we want to do is to make it readily known that these three have survived for so long. It would be nearly impossible to conduct a large scale operation without drawing unwanted attention, especially from the Rebellion. If the Rebellion got word of these three they would most certainly reach out and try to offer their support. As far as the rest of the galaxy is concerned these three died during the Clone Wars.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_929e4e42", "s_9f2ab4a0"}, -- How should I proceed?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_d26b0750)

nin_gursawe_convo_s_9f2ab4a0 = ConvoScreen:new {
	id = "s_9f2ab4a0",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9f2ab4a0", -- First, we need to make sure they have not taken shelter on the planets surface. I have arranged for a drop ship to send a scan team to the planets surface to begin a sweep of the surface. Of course, once that team is on the surface they will not be able to leave, but they don't know that and there is no reason to tell them.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_ae99b26e", "m3_accept"}, -- So what am I am going to be doing?
		{"@conversation/corellia_imperial_tier4:s_eba35f17", "m3_accept"}, -- When do I leave?
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_9f2ab4a0)

nin_gursawe_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/corellia_imperial_tier4:s_622b4f74", -- Once the team is searching the surface, you will begin searching space. I completely expect that they took a number of their Velocity lackies along with them. Find the Velocity and they will lead us to our targets. There is no where else they can run. Let's get this operation under way. Good luck, %NU.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m3_accept)

nin_gursawe_convo_m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/corellia_imperial_tier4:s_690701a5", -- We have Neja' Bertolo! My men have finally decoded the orders you brought back to me. They have Nej'a all over them. He also made a terrible mistake by putting his coordinates in those orders. Apparently, he wanted his men to be able to reach him if he was needed.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_fc7e0cf7", "m4_accept_a"}, -- So, when do you want me to finish him off?
		{"@conversation/corellia_imperial_tier4:s_630c41d4", "s_d7fc6920"}, -- Doesn't sound like he is all that smart.
		{"@conversation/corellia_imperial_tier4:s_ea248fbf", "m4_accept_c"}, -- If it is the Emperor's will, than I shall do so.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_brief)

nin_gursawe_convo_m4_brief_trained = ConvoScreen:new {
	id = "m4_brief_trained",
	leftDialog = "@conversation/corellia_imperial_tier4:s_4c99c2f5", -- We have Neja' Bertolo! Those orders you brought back to me have finally been decoded and they have Nej'a all over them. He also made a most fatal flaw of placing his coordinates in those orders. Apparently he wanted his men to be able to reach him if he was needed.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_fc7e0cf7", "m4_accept_a"}, -- So, when do you want me to finish him off?
		{"@conversation/corellia_imperial_tier4:s_630c41d4", "s_d7fc6920"}, -- Doesn't sound like he is all that smart.
		{"@conversation/corellia_imperial_tier4:s_ea248fbf", "m4_accept_c"}, -- If it is the Emperor's will, than I shall do so.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_brief_trained)

nin_gursawe_convo_s_d7fc6920 = ConvoScreen:new {
	id = "s_d7fc6920",
	leftDialog = "@conversation/corellia_imperial_tier4:s_d7fc6920", -- He didn't expect us to be able to find him in Dathomir. His lack of vision will be his undoing, but it is unwise to question his intelligence. He is a formidable foe and he will be made even more so now that he is cornered.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier4:s_37e2608d", "m4_accept_b"}, -- I do not fear danger.
	}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_s_d7fc6920)

nin_gursawe_convo_m4_accept_a = ConvoScreen:new {
	id = "m4_accept_a",
	leftDialog = "@conversation/corellia_imperial_tier4:s_9f02cebc", -- That is what you are going to do. We cannot take the risk that Nej'a will change his staging location. The Empire has waited for many years to bring this criminal to justice... today is that day. Remember he is very dangerous, destroy him quickly. Good luck, %NU.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_accept_a)

nin_gursawe_convo_m4_accept_b = ConvoScreen:new {
	id = "m4_accept_b",
	leftDialog = "@conversation/corellia_imperial_tier4:s_1b4ddba3", -- Now, we cannot take the risk that Nej'a will change his staging location. The Empire has waited for many years to bring this criminal to justice... today is that day. Remember he is very dangerous, destroy him quickly. Good luck, %NU.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_accept_b)

nin_gursawe_convo_m4_accept_c = ConvoScreen:new {
	id = "m4_accept_c",
	leftDialog = "@conversation/corellia_imperial_tier4:s_c0bee78", -- I have the feeling that you will do just fine. The Emperor's blessing be on you, %NU.
	stopConversation = "true",
	options = {}
}
nin_gursawe_convo_template:addScreen(nin_gursawe_convo_m4_accept_c)

addConversationTemplate("nin_gursawe_convo_template", nin_gursawe_convo_template)
