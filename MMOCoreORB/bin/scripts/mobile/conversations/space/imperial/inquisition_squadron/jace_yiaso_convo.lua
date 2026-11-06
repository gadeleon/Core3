-- Grand Inquisitor Ja'ce Yiaso (Inquisition tier 4, Emperor's Retreat) conversation screens; ported from SWG-Source naboo_imperial_tier4 (STF conversation/naboo_imperial_tier4). Handler: jaceYiasoConvoHandler.lua (feature inquisition-tier4-jace-yiaso).
jace_yiaso_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "jaceYiasoConvoHandler",
	screens = {}
}

jace_yiaso_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_imperial_tier4:s_8a7c509a", -- I have no idea how you managed to get down this far but I would suggest that leave immediately before something happens to you. People who don't belong here often find themselves losing everything.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_wrong_faction)

jace_yiaso_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4b509b", -- I am sure that you are just filled with fascinating stories. But I would rather not listen to any of them. I am in need of skilled pilots, not ground pounders.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_not_pilot)

jace_yiaso_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/naboo_imperial_tier4:s_e3ea301", -- I have heard bad things about you, %TU.
	animation = "cover_mouth",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_53de9d8f", "wanted_rebels"}, -- Like what?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_wanted)

jace_yiaso_convo_wanted_rebels = ConvoScreen:new {
	id = "wanted_rebels",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9e131808", -- I have heard that you've been assisting the Rebel Alliance against the Empire.  This concerns me a great deal, as you can imagine.  You cannot be trusted with any more assignments.
	animation = "shake_head_disgust",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_8feb33c1", "wanted_grounded"}, -- Ever?!
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_wanted_rebels)

jace_yiaso_convo_wanted_grounded = ConvoScreen:new {
	id = "wanted_grounded",
	leftDialog = "@conversation/naboo_imperial_tier4:s_3686a31b", -- Not until you improve your standing with the Empire.  Until then consider yourself grounded.
	animation = "shake_head_no",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_wanted_grounded)

jace_yiaso_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/naboo_imperial_tier4:s_3a3805e3", -- Ah, a young pilot. What brings you here, so far from your assigned squadron?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_4854758d", "off_track_duties"}, -- I would like to request a mission.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_off_track)

jace_yiaso_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1832fe3c", -- Hmm, this is highly unorthodox. Although I do have some elective duty missions if you are interested. Would you like to hear the briefing?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_c82e9a2f", "duty_briefing"}, -- Yes, please.
		{"@conversation/naboo_imperial_tier4:s_90ce1297", "off_track_no"}, -- No, thank you.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_off_track_duties)

jace_yiaso_convo_off_track_no = ConvoScreen:new {
	id = "off_track_no",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1769a080", -- Then quite wasting my time. I am a very busy man and cannot be bothered to stop and chat.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_off_track_no)

jace_yiaso_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1c3578bb", -- I'll bet you would, wouldn't you? I have no need for untrained and incompetent pilots. Perhaps you should return to your commanding officer and learn a thing or two before seeing me again.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_off_track_refused)

jace_yiaso_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a11a905b", -- You are one of our younger pilots, are you not? Of course you are. Is discipline in the ranks of the Inquisition breaking down so much that junior pilots think they can talk to a Grand Inquisitor unannounced? Perhaps it is time to purge out our slothful and weak...Why haven't you left yet?
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_not_ready)

jace_yiaso_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_imperial_tier4:s_fcbb92d0", -- You are already on a task. The Emperor would be most displeased to find out that his pilots are derelict in their duties. Get back to work.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_on_mission)

jace_yiaso_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a6380860", -- So you have failed. That is most distressing. I tasked you with such a simple task and you come back here with your tail between your legs like some mongrel dog.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_67183c1c", "m1_failed_trying"}, -- I'm trying.
		{"@conversation/naboo_imperial_tier4:s_26bb0194", "m1_failed_chance"}, -- Give me another chance. I will not fail again.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_failed)

jace_yiaso_convo_m1_failed_trying = ConvoScreen:new {
	id = "m1_failed_trying",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a6f30b2b", -- Did you say...you're trying?
	animation = "listen",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_ec457ebc", "m1_retry_a"}, -- I mean I'll do it!
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_failed_trying)

jace_yiaso_convo_m1_retry_a = ConvoScreen:new {
	id = "m1_retry_a",
	leftDialog = "@conversation/naboo_imperial_tier4:s_f7e33371", -- That's what  I thought.
	animation = "check_wrist_device",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_retry_a)

jace_yiaso_convo_m1_failed_chance = ConvoScreen:new {
	id = "m1_failed_chance",
	leftDialog = "@conversation/naboo_imperial_tier4:s_487cad", -- Very well. But you had better understand one thing...failure is not tolerated in the Inquisition. Failing in your duty is paramount to treason. And you know what we do to traitors, don't you?
	animation = "wave_finger_warning",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_b6b25f13", "m1_retry_b"}, -- Yes, sir!
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_failed_chance)

jace_yiaso_convo_m1_retry_b = ConvoScreen:new {
	id = "m1_retry_b",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b1a3b711", -- As long as we have come to an agreement. Dismissed!
	animation = "dismiss",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_retry_b)

jace_yiaso_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_cfb7c310", -- %TU, you were given this assignment because you were good. But you don't seem particularly skilled.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_97ce1c41", "m2_failed_worry"}, -- That problem was just a temporary setback. Don't worry.
		{"@conversation/naboo_imperial_tier4:s_e69b471b", "m2_retry_a"}, -- I'll get the job done.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_failed)

jace_yiaso_convo_m2_failed_worry = ConvoScreen:new {
	id = "m2_failed_worry",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a72c3c89", -- Inquisitors don't worry. But you SHOULD be worried. You don't want an Inquisitor to be angry with you, now do you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_f115f554", "m2_retry_b"}, -- Definitely not.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_failed_worry)

jace_yiaso_convo_m2_retry_a = ConvoScreen:new {
	id = "m2_retry_a",
	leftDialog = "@conversation/naboo_imperial_tier4:s_659c15a1", -- I suggest you do.
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_retry_a)

jace_yiaso_convo_m2_retry_b = ConvoScreen:new {
	id = "m2_retry_b",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5e0158c", -- Complete your mission, and perhaps all will be forgiven.
	animation = "dismiss",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_retry_b)

jace_yiaso_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1bfd2d3e", -- Where is the data from that communications satellite?
	animation = "hair_flip",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_85b1adc5", "m3_failed_dark"}, -- I haven't been able to bring it back yet, sir. But I'll take care of it.
		{"@conversation/naboo_imperial_tier4:s_873e726e", "m3_failed_why"}, -- My mission's not complete.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_failed)

jace_yiaso_convo_m3_failed_dark = ConvoScreen:new {
	id = "m3_failed_dark",
	leftDialog = "@conversation/naboo_imperial_tier4:s_da128253", -- Without that information, we won't know who's behind all this. And you wouldn't want the Inquisition to be left in the dark would you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_9c6ec037", "m3_retry_a"}, -- No, sir. I will get us that information.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_failed_dark)

jace_yiaso_convo_m3_retry_a = ConvoScreen:new {
	id = "m3_retry_a",
	leftDialog = "@conversation/naboo_imperial_tier4:s_57274357", -- That's a good little pilot. Get out of my sight before I lose my temper.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_retry_a)

jace_yiaso_convo_m3_failed_why = ConvoScreen:new {
	id = "m3_failed_why",
	leftDialog = "@conversation/naboo_imperial_tier4:s_424a2157", -- Then why are you here at the Emperor's Retreat?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_9ec59458", "m3_retry_b"}, -- I...um...
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_failed_why)

jace_yiaso_convo_m3_retry_b = ConvoScreen:new {
	id = "m3_retry_b",
	leftDialog = "@conversation/naboo_imperial_tier4:s_f435fbd2", -- Don't waste your breath telling me lies. You have work to do. Go do it!
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_retry_b)

jace_yiaso_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_91d10a84", -- How unfortunate that you are unable to do your job.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_7017e938", "m4_retry_a"}, -- It'll get done.
		{"@conversation/naboo_imperial_tier4:s_39ec8285", "m4_failed_complaint"}, -- It's harder than it looks, you know.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_failed)

jace_yiaso_convo_m4_retry_a = ConvoScreen:new {
	id = "m4_retry_a",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5f1cd2f8", -- See that it does.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_retry_a)

jace_yiaso_convo_m4_failed_complaint = ConvoScreen:new {
	id = "m4_failed_complaint",
	leftDialog = "@conversation/naboo_imperial_tier4:s_8bfb7a2f", -- What's this? A complaint?
	animation = "listen",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_dbb3a834", "m4_failed_relief"}, -- Um, no.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_failed_complaint)

jace_yiaso_convo_m4_failed_relief = ConvoScreen:new {
	id = "m4_failed_relief",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ecd3f704", -- What a relief. I'd hate to have to discipline you. I'm disappointed in you as it is.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_c17d2691", "m4_retry_b"}, -- I can do it.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_failed_relief)

jace_yiaso_convo_m4_retry_b = ConvoScreen:new {
	id = "m4_retry_b",
	leftDialog = "@conversation/naboo_imperial_tier4:s_7e2d0f69", -- We'll see if you can. Dismissed.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_retry_b)

jace_yiaso_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/naboo_imperial_tier4:s_417ab2a4", -- So you have returned. We have just received those interesting rocks you recovered from that unauthorized vessel. Did you leave the pilot just floating out there or did you finish him off after the search...wait! Don't tell me, I find it more amusing to think of him floating helpless in the cold depths of space.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_834bed59", "m1_reward_crystals"}, -- What were those crystals, sir?
		{"@conversation/naboo_imperial_tier4:s_5c9b37f9", "m1_reward_worm"}, -- See, I told you I would get this job done.
		{"@conversation/naboo_imperial_tier4:s_e479ad44", "m1_reward_deserved"}, -- He got what was coming to him for his disobedience.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward)

jace_yiaso_convo_m1_reward_crystals = ConvoScreen:new {
	id = "m1_reward_crystals",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9d1c334d", -- They are being analyzed by our top men. Those crystals are no longer your concern. You have done well this day and deserve to be rewarded for your loyal service. You want your reward don't you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_1cd21b47", "m1_reward_loyal"}, -- Yes, sir. Thank you.
		{"@conversation/naboo_imperial_tier4:s_d0918370", "m1_reward_duty"}, -- I do this for the duty, sir. No reward is necessary.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_crystals)

jace_yiaso_convo_m1_reward_loyal = ConvoScreen:new {
	id = "m1_reward_loyal",
	leftDialog = "@conversation/naboo_imperial_tier4:s_722463c0", -- That is a good, loyal pilot. Here you go. Try not to spend it all at once. When you are ready for some more lessons or to continue your duty come back and see me again. Perhaps I will have more need for you.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_loyal)

jace_yiaso_convo_m1_reward_duty = ConvoScreen:new {
	id = "m1_reward_duty",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b12a7f6", -- Very well. That will be all pilot.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_416d1887", "m1_reward_umm"}, -- Umm...
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_duty)

jace_yiaso_convo_m1_reward_umm = ConvoScreen:new {
	id = "m1_reward_umm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_af5329b0", -- What? Now you want your reward! Of course you do. Because all good, loyal pilots take their reward when they do something well. Here take this. You are a good pilot. A very good pilot.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_umm)

jace_yiaso_convo_m1_reward_worm = ConvoScreen:new {
	id = "m1_reward_worm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_d5225828", -- Ah, so the worm made it back. You have done very well to slip from my hook. Perhaps one day. Perhaps one day soon, eh worm?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_54ed82f4", "m1_reward_slippery"}, -- Not me. I am too slippery.
		{"@conversation/naboo_imperial_tier4:s_41040de1", "m1_reward_not_worm"}, -- I am not a worm!
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_worm)

jace_yiaso_convo_m1_reward_slippery = ConvoScreen:new {
	id = "m1_reward_slippery",
	leftDialog = "@conversation/naboo_imperial_tier4:s_7bc04afa", -- We will see. I will issue your duty pay. When you are ready for some more lessons or to continue your duty come back and see me again. Perhaps I will have more need for you. That rock you brought back is most interesting. We have top men working on it now.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_719a036e", "m1_reward_top_men"}, -- Who?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_slippery)

jace_yiaso_convo_m1_reward_top_men = ConvoScreen:new {
	id = "m1_reward_top_men",
	leftDialog = "@conversation/naboo_imperial_tier4:s_36af2d20", -- Top...men.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_top_men)

jace_yiaso_convo_m1_reward_not_worm = ConvoScreen:new {
	id = "m1_reward_not_worm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_725be20b", -- So you are not all bluster. That is good. I was beginning to wonder if you were right for this job. You are still a worm but maybe one with a little bit of a backbone. I was thinking of withholding your duty pay but I guess you have earned it.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_52c3d844", "m1_reward_earned"}, -- I did earn it.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_not_worm)

jace_yiaso_convo_m1_reward_earned = ConvoScreen:new {
	id = "m1_reward_earned",
	leftDialog = "@conversation/naboo_imperial_tier4:s_dc31882", -- Yes. Here is your pay. I am going to have that crystal you brought back analyzed. While that is being done you can go on leave or take some duties. When we have the crystal analyzed, perhaps I will have more for you to do. You may leave my presence now.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_earned)

jace_yiaso_convo_m1_reward_deserved = ConvoScreen:new {
	id = "m1_reward_deserved",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9bc48781", -- I am sure he did. That crystal you brought back is most interesting. Do you have any idea what it is?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_1ef1e040", "m1_reward_lab"}, -- I was glowing but other than that, no.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_deserved)

jace_yiaso_convo_m1_reward_lab = ConvoScreen:new {
	id = "m1_reward_lab",
	leftDialog = "@conversation/naboo_imperial_tier4:s_da53e28f", -- Well we will find out soon. It is in the lab being analyzed. While that is taking place I will issue your duty pay. You have done the Emperor's work very well.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_c0f7c528", "m1_reward_bidding"}, -- What is your bidding now?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_lab)

jace_yiaso_convo_m1_reward_bidding = ConvoScreen:new {
	id = "m1_reward_bidding",
	leftDialog = "@conversation/naboo_imperial_tier4:s_7c92f77a", -- Until we know what that crystal is there is no need to continue the main operation. For now you may go on leave or take some duty missions. Once we have what we need and you are ready, we will continue our investigation.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_reward_bidding)

jace_yiaso_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c4f74be1", -- So, yet again, you have accomplished the task that I placed before you. The Emperor was most pleased with your progress and has issued a reward for you. Here it is.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_64ce1b1d", "m2_reward_freighter"}, -- Thank you, sir. What is the next step?
		{"@conversation/naboo_imperial_tier4:s_40671b7a", "m2_reward_frugal"}, -- Excellent. I was getting a little short on credits.
		{"@conversation/naboo_imperial_tier4:s_f5d2aa8d", "m2_reward_attention"}, -- I am honored that the Emperor took notice of his humble servant.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward)

jace_yiaso_convo_m2_reward_freighter = ConvoScreen:new {
	id = "m2_reward_freighter",
	leftDialog = "@conversation/naboo_imperial_tier4:s_90f30b97", -- The freighter you recovered was indeed filled with more of the crystals from Dathomir. That can only mean that they are working with someone who has an operation on the planet's surface with the capability to mine these. They would have to have access to a lot just to pay for the Coynite.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_8a38a5ed", "m2_reward_who"}, -- Who could it be?
		{"@conversation/naboo_imperial_tier4:s_a459860a", "m2_reward_captive"}, -- What about the Coynite I captured?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward_freighter)

jace_yiaso_convo_m2_reward_who = ConvoScreen:new {
	id = "m2_reward_who",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c25d28ef", -- At this time, I don't know. But we will find out. I am hoping that the Coynite you captured will be able to tell me more. The people of Coyn are well known for their resiliency but he will crack...they all do. Until then you can continue our duty operations or go on leave. I am sure that I will have more use for you later.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward_who)

jace_yiaso_convo_m2_reward_captive = ConvoScreen:new {
	id = "m2_reward_captive",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4c65eeef", -- He is to be...questioned. The Coynite are well known for their strength. I will find it most interesting to test my resolve against his strength. I will win of course, but perhaps he will hold on long enough to make it interesting. In the end he will tell me everything he knows. Until then you may go on leave or continue our duty operations. I am sure I will have need for you later.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward_captive)

jace_yiaso_convo_m2_reward_frugal = ConvoScreen:new {
	id = "m2_reward_frugal",
	leftDialog = "@conversation/naboo_imperial_tier4:s_30d23b2c", -- I take it that frugality is not one of your strong suits. That is alright...the Empire is very wealthy and a pilot in the right position can make a healthy sum.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_bdebb4cc", "m2_reward_freighter"}, -- So what is the next step?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward_frugal)

jace_yiaso_convo_m2_reward_attention = ConvoScreen:new {
	id = "m2_reward_attention",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1cfa3230", -- The Emperor pays attention to far more than you could possibly imagine.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_aa695923", "m2_reward_freighter"}, -- What am I to do next?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_reward_attention)

jace_yiaso_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/naboo_imperial_tier4:s_bcd45d4", -- The Coynite should no longer be a problem for us in the Dathomir system. Without their flagship they will have no staging point to continue their activities. You've completed your mission to the Emperor's satisfaction. Here is your duty pay.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_28b58d98", "m3_reward_officers"}, -- Thank you, sir. Will there be anything else?
		{"@conversation/naboo_imperial_tier4:s_32bd6884", "m3_reward_spend"}, -- I'm going to spend every credit of it!
		{"@conversation/naboo_imperial_tier4:s_593c68fd", "m3_reward_punished"}, -- The Coynite were foolish to attempt to circumvent the will of the Emperor.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward)

jace_yiaso_convo_m3_reward_officers = ConvoScreen:new {
	id = "m3_reward_officers",
	leftDialog = "@conversation/naboo_imperial_tier4:s_bfcf1757", -- Nothing is pressing at this time. We will be dealing with the officers on Dathomir by telling the others that were not involved what was happening. They will deal with the traitorous officers in their own way.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_77e48d5b", "m3_reward_prison"}, -- What do you mean?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_officers)

jace_yiaso_convo_m3_reward_prison = ConvoScreen:new {
	id = "m3_reward_prison",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6d60481e", -- Well, the post at the prison is a life time assignment. Once you are there, you do not leave. Naturally, every officer stationed at the planet wants to leave. Think about it. If one group forms a plan to escape and doesn't let the other group in on it, they would be rather upset.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_3dd8800a", "m3_reward_curious"}, -- I can see that.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_prison)

jace_yiaso_convo_m3_reward_curious = ConvoScreen:new {
	id = "m3_reward_curious",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ac4bb3e6", -- I am sort of curious about what they will actually do though. Call it professional curiosity. Maybe one of them will put it in a report. As for you...you are free to do as you wish for now, perhaps continue with our duties in the Dathomir system. There are still a few Coynite that may continue to cause minor problems that need to be cleaned.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_curious)

jace_yiaso_convo_m3_reward_spend = ConvoScreen:new {
	id = "m3_reward_spend",
	leftDialog = "@conversation/naboo_imperial_tier4:s_185e40da", -- Very good. We like pilots who have no money. Keeps them motivated.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_e9065e37", "m3_reward_edge"}, -- You will use any edge you get, won't you?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_spend)

jace_yiaso_convo_m3_reward_edge = ConvoScreen:new {
	id = "m3_reward_edge",
	leftDialog = "@conversation/naboo_imperial_tier4:s_34aaab36", -- Of course. There is always some way to manipulate anyone. The key is just finding out what. On a side note, we will be dealing with the officers on Dathomir by telling the others that were not involved what was happening. They will deal with the traitorous officers in their own way.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_77e48d5b", "m3_reward_prison"}, -- What do you mean?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_edge)

jace_yiaso_convo_m3_reward_punished = ConvoScreen:new {
	id = "m3_reward_punished",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6145c468", -- Yes, you made quite sure that they were adequately punished. We will be dealing with the officers on Dathomir by telling the others that were not involved what was happening. They will deal with the traitorous officers in their own way.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_77e48d5b", "m3_reward_prison"}, -- What do you mean?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_reward_punished)

jace_yiaso_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5a0327df", -- You have performed wonderfully with an alarming situation. It would seem that I had under estimated the resolve of the Coynite to finish a job that they were paid to do. I am most impressed with them. Based off of the single one I had dealings with I wouldn't have thought they had it in them.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_57a5120c", "m4_reward_finished"}, -- I think they are finished now, sir.
		{"@conversation/naboo_imperial_tier4:s_2bfb5526", "m4_reward_gasbag"}, -- I told you and you wouldn't listen...I am the BEST!
		{"@conversation/naboo_imperial_tier4:s_44867e8a", "m4_reward_alone"}, -- They should have left well enough alone.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_reward)

jace_yiaso_convo_m4_reward_finished = ConvoScreen:new {
	id = "m4_reward_finished",
	leftDialog = "@conversation/naboo_imperial_tier4:s_fe2a11f4", -- Even if the Coynite are not, the traitorous prison officers are no longer alive to attempt escape. The Coynite have no reason to stay in the region anymore so they will move along. This is for you. You have earned it. You are dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_reward_finished)

jace_yiaso_convo_m4_reward_gasbag = ConvoScreen:new {
	id = "m4_reward_gasbag",
	leftDialog = "@conversation/naboo_imperial_tier4:s_8e075bc2", -- Bah! I give you the slightest of praise and you cannot help but blow up like an Inerbion Gasbag. Here take this and get out of my sight.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_reward_gasbag)

jace_yiaso_convo_m4_reward_alone = ConvoScreen:new {
	id = "m4_reward_alone",
	leftDialog = "@conversation/naboo_imperial_tier4:s_f82c2226", -- Yes, I will agree with you. But some people simply don't know when to quit. Here, this is for you. I look forward to our next chat. Good day, pilot %NU.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_reward_alone)

jace_yiaso_convo_ready = ConvoScreen:new {
	id = "ready",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ace49d41", -- If you are done wasting time, there is work to be done. Are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_52917b0d", "m1_brief"}, -- Of course.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_ready)

jace_yiaso_convo_ready_train = ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5dce257f", -- You must be here for your skills upgrade. Well, pick one. Be quick about it.
	animation = "tap_foot",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_d8355c02", "m1_brief_trained"}, -- I'll take experimental TIE vessels.
		{"@conversation/naboo_imperial_tier4:s_96a0374a", "m1_brief_trained"}, -- I'll take heavy starship component use.
		{"@conversation/naboo_imperial_tier4:s_d8efd03b", "m1_brief_trained"}, -- I'll take elite TIE guard training.
		{"@conversation/naboo_imperial_tier4:s_7e1308bc", "m1_brief_trained"}, -- I'll take droid intelligence theory.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_ready_train)

jace_yiaso_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/naboo_imperial_tier4:s_59da8c80", -- I've been waiting for you, pilot. It's about time you got here. There's no time to waste. I've prepped a briefing for you, are you ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_a3958e6a", "intro_briefing"}, -- Ready to serve, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_intro)

jace_yiaso_convo_intro_briefing = ConvoScreen:new {
	id = "intro_briefing",
	leftDialog = "@conversation/naboo_imperial_tier4:s_85c9e37e", -- Very well. The situation report is as follows: Smugglers continue to infiltrate this system. Diplomacy's no use with them; they only understand the business end of a space blaster. So, you could clear them out.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_8d7e0eff", "duty_escort_info"}, -- Hmm.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_intro_briefing)

jace_yiaso_convo_duty_briefing = ConvoScreen:new {
	id = "duty_briefing",
	leftDialog = "@conversation/naboo_imperial_tier4:s_85c9e37e", -- Very well. The situation report is as follows: Smugglers continue to infiltrate this system. Diplomacy's no use with them; they only understand the business end of a space blaster. So, you could clear them out.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_8d7e0eff", "duty_escort_info"}, -- Hmm.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_briefing)

jace_yiaso_convo_duty_escort_info = ConvoScreen:new {
	id = "duty_escort_info",
	leftDialog = "@conversation/naboo_imperial_tier4:s_327da557", -- Or you could escort prison ships to Dathomir - the guards are always eager to see a new face.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_61657d0f", "duty_recovery_info"}, -- I see.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_escort_info)

jace_yiaso_convo_duty_recovery_info = ConvoScreen:new {
	id = "duty_recovery_info",
	leftDialog = "@conversation/naboo_imperial_tier4:s_f76cec26", -- We need a pilot to bring in a few Imperial ships that are here without authorization.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_362a48e0", "duty_rescue_info"}, -- Anything else?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_recovery_info)

jace_yiaso_convo_duty_rescue_info = ConvoScreen:new {
	id = "duty_rescue_info",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ee9d18a3", -- There are always ships taking damage in this system. They need a pilot to guide them in for repairs.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_851406fb", "duty_destroy"}, -- Those pirates won't know what hit them.
		{"@conversation/naboo_imperial_tier4:s_82095b20", "duty_escort"}, -- I'll take those prisoners to Dathomir. Sounds like fun.
		{"@conversation/naboo_imperial_tier4:s_60a8bfcb", "duty_recovery"}, -- I'd like to bring those rogue Imperials in.
		{"@conversation/naboo_imperial_tier4:s_be7e95c", "duty_rescue"}, -- I'll clear those damaged ships.
		{"@conversation/naboo_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_rescue_info)

jace_yiaso_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/naboo_imperial_tier4:s_d70698c1", -- Work teaches discipline! Never waste a minute of your time. The Emperor needs your service, always. Tell me, are you ready to accept a duty mission, or would you like to hear the briefing again?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_851406fb", "duty_destroy"}, -- Those pirates won't know what hit them.
		{"@conversation/naboo_imperial_tier4:s_82095b20", "duty_escort"}, -- I'll take those prisoners to Dathomir. Sounds like fun.
		{"@conversation/naboo_imperial_tier4:s_60a8bfcb", "duty_recovery"}, -- I'd like to bring those rogue Imperials in.
		{"@conversation/naboo_imperial_tier4:s_be7e95c", "duty_rescue"}, -- I'll clear those damaged ships.
		{"@conversation/naboo_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_tier4_incomplete)

jace_yiaso_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/naboo_imperial_tier4:s_145d7cc3", -- So you are back. Did your visit with the Grand Admiral go well? Are you here for my pleasant company or did you come back looking for work?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_851406fb", "duty_destroy"}, -- Those pirates won't know what hit them.
		{"@conversation/naboo_imperial_tier4:s_82095b20", "duty_escort"}, -- I'll take those prisoners to Dathomir. Sounds like fun.
		{"@conversation/naboo_imperial_tier4:s_60a8bfcb", "duty_recovery"}, -- I'd like to bring those rogue Imperials in.
		{"@conversation/naboo_imperial_tier4:s_be7e95c", "duty_rescue"}, -- I'll clear those damaged ships.
		{"@conversation/naboo_imperial_tier4:s_49805f81", "duty_briefing"}, -- Can I hear the briefing again?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_here_for_work)

jace_yiaso_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1a40d259", -- Excellent. I wish you luck. Pirates must die.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_destroy)

jace_yiaso_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/naboo_imperial_tier4:s_84350489", -- I enjoy prisons, myself. Always full of men in need of discipline.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_escort)

jace_yiaso_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/naboo_imperial_tier4:s_647c9fa9", -- Yes. Quite unusual! Imperials are usually so well-behaved. Maybe it's just a paperwork error. Regardless, bring them in.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_recovery)

jace_yiaso_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5ca877f1", -- Please do. They're an eyesore.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_duty_rescue)

jace_yiaso_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6fb4f06a", -- A very interesting order came across my desk just a few moments ago. What is your relationship with Grand Admiral Nial Declann?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_7177c3f2", "transfer_who"}, -- Who is Grand Admiral Nial Declann?
		{"@conversation/naboo_imperial_tier4:s_fae9dc1b", "transfer_dont_know"}, -- I don't know Grand Admiral Nial Declann.
		{"@conversation/naboo_imperial_tier4:s_a3aef707", "transfer_way_back"}, -- Oh, me and Grand Admiral Nial Declann go way back.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer)

jace_yiaso_convo_transfer_who = ConvoScreen:new {
	id = "transfer_who",
	leftDialog = "@conversation/naboo_imperial_tier4:s_55905a28", -- Hmm, you really don't know do you? Admiral Nial Declann is one of the twelve men in charge of the Imperial Navy. He wields great power and is said to be favored by the Emperor. I am just curious as to why this order says that you are to be immediately transferred under his command?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_a4b30c88", "transfer_secrets"}, -- I really don't know, Inquisitor.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_who)

jace_yiaso_convo_transfer_secrets = ConvoScreen:new {
	id = "transfer_secrets",
	leftDialog = "@conversation/naboo_imperial_tier4:s_3e261fd0", -- Perhaps it wouldn't be a bad thing to have a member of the Inquisition working for a Grand Admiral. Who knows what secrets we might uncover. Yes, I think that this will be most enlightening.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6844241f", "transfer_say_so"}, -- If you say so, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_secrets)

jace_yiaso_convo_transfer_say_so = ConvoScreen:new {
	id = "transfer_say_so",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a9a7c838", -- I do indeed, as you put it...say so. You are to report to Grand Admiral Nial Declann, perform your duties for him without question, and you are to keep your eyes open. Learn everything you can about this man and his goals. I think we can both learn from this experience.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_270e6f7b", "transfer_theed"}, -- I will do my best. Where am I to report to?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_say_so)

jace_yiaso_convo_transfer_theed = ConvoScreen:new {
	id = "transfer_theed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a0d28eb", -- The Grand Admiral is stationed in Theed Palace. From what I understand its gaudy and worldly walls suit his personality just right. Go now. Do not keep the Grand Admiral waiting. There is much work to be done.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_theed)

jace_yiaso_convo_transfer_dont_know = ConvoScreen:new {
	id = "transfer_dont_know",
	leftDialog = "@conversation/naboo_imperial_tier4:s_cd04b926", -- Perhaps. Perhaps not. You are ordered to report to Grand Admiral Nial Declann immediately. Why he has asked for you I do not yet know, but I assure you I will find out. I do not like this but I do not have the authority to ignore a direct order from a Grand Admiral.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_58edcac7", "transfer_palace"}, -- Where am I to report to?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_dont_know)

jace_yiaso_convo_transfer_palace = ConvoScreen:new {
	id = "transfer_palace",
	leftDialog = "@conversation/naboo_imperial_tier4:s_365243f7", -- The Grand Admiral is stationed inside the palace walls of that treacherous woman. I still am not sure why the Emperor has allowed her to continue to rule and not turned her over to me. Regardless, I am sure he has his reasons.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_83803b19", "transfer_kylantha"}, -- Do you mean Theed Palace and Queen Kylantha?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_palace)

jace_yiaso_convo_transfer_kylantha = ConvoScreen:new {
	id = "transfer_kylantha",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ee94373b", -- Who do you think I was talking about? Sometimes I really wonder about you and what your agenda is. But I have time to find out, oh yes, I always have time. You are dismissed, do not keep the Grand Admiral waiting. I understand that he is an extremely impatient man.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_kylantha)

jace_yiaso_convo_transfer_way_back = ConvoScreen:new {
	id = "transfer_way_back",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c33416a7", -- I do not find your pathetic attempt at humor amusing. You are speaking about a Grand Admiral of the Imperial Navy and someone who has the ear of the Emperor. Even I would not be foolish enough to make light of such a man.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_3b9d259a", "transfer_orders"}, -- Sorry, Inquisitor. It won't happen again.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_way_back)

jace_yiaso_convo_transfer_orders = ConvoScreen:new {
	id = "transfer_orders",
	leftDialog = "@conversation/naboo_imperial_tier4:s_d8b3a5bc", -- See that it doesn't, or you may find yourself back here answering a few more questions. I have orders here that you are to be transferred to the Grand Admiral in the Theed Palace. I find it most interesting that you were asked for by name. Doesn't it seem strange to you that a Grand Admiral would even know your name?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_3b2c48b2", "transfer_records"}, -- Perhaps he has records, sir.
		{"@conversation/naboo_imperial_tier4:s_5dff5608", "transfer_strange"}, -- Yes, it does seem strange.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_orders)

jace_yiaso_convo_transfer_records = ConvoScreen:new {
	id = "transfer_records",
	leftDialog = "@conversation/naboo_imperial_tier4:s_8bae75a0", -- Bah! I assure you that I will find out the truth of why he asked for you. If I could I would keep you here until I found out the truth but even I cannot ignore an order from a Grand Admiral. You are to immediately report to the Grand Admiral Declann. You are dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_records)

jace_yiaso_convo_transfer_strange = ConvoScreen:new {
	id = "transfer_strange",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c28f20f3", -- Report to the Grand Admiral Declann immediately. Just remember where your allegiance lies, pilot. Because if it ever falters not even a Grand Admiral can protect you from me. You are dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_transfer_strange)

jace_yiaso_convo_m1_brief = ConvoScreen:new {
	id = "m1_brief",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b0abb9a4", -- I have need of your...unique talents. After all, idle hands are a dangerous thing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_a3958e6a", "m1_eager"}, -- Ready to serve, sir.
		{"@conversation/naboo_imperial_tier4:s_c4bc5314", "m1_willing"}, -- I am yours to command, High Inquisitor.
		{"@conversation/naboo_imperial_tier4:s_adb2030c", "m1_vaunted"}, -- It's about time you let me do my thing.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_brief)

jace_yiaso_convo_m1_brief_trained = ConvoScreen:new {
	id = "m1_brief_trained",
	leftDialog = "@conversation/naboo_imperial_tier4:s_490da0e3", -- I think that you might find that skill very useful. Especially now that I have need of your...unique talents. After all, idle hands are a dangerous thing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_b3a26c61", "m1_eager"}, -- I am ready to test out my new ability.
		{"@conversation/naboo_imperial_tier4:s_c4bc5314", "m1_willing"}, -- I am yours to command, High Inquisitor.
		{"@conversation/naboo_imperial_tier4:s_adb2030c", "m1_vaunted"}, -- It's about time you let me do my thing.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_brief_trained)

jace_yiaso_convo_m1_eager = ConvoScreen:new {
	id = "m1_eager",
	leftDialog = "@conversation/naboo_imperial_tier4:s_265434f7", -- You are very eager, my young pilot. That is good. I have much need for someone who is willing to get the job done and done quickly.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_898acaac", "m1_task"}, -- What is it you need me to do, sir?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_eager)

jace_yiaso_convo_m1_willing = ConvoScreen:new {
	id = "m1_willing",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6448a70", -- A willing mind? How refreshing. I was getting so tired of the standard military pilots. Such wastes. But I suppose they do have their uses...they are nice fodder for the war effort. Don't you agree?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_e36c1eee", "m1_thoughts"}, -- Someone has to die. Might as well be them.
		{"@conversation/naboo_imperial_tier4:s_c82a372", "m1_thoughts"}, -- I could care less about those weak fools.
		{"@conversation/naboo_imperial_tier4:s_1ce05254", "m1_accept_assume"}, -- Perhaps. Now what do you want me to do?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_willing)

jace_yiaso_convo_m1_vaunted = ConvoScreen:new {
	id = "m1_vaunted",
	leftDialog = "@conversation/naboo_imperial_tier4:s_fbcaed73", -- Let you do your thing? Ah...you mean that you are a skilled pilot and I have been holding you back. Most interesting. You must indeed have some small measure of skill or you would not have risen so far so fast. I agree with you. It is time for me to measure your 'vaunted' skill as a pilot.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_2ebece20", "m1_laugh"}, -- Great, time for me to save the Empire, yet again.
		{"@conversation/naboo_imperial_tier4:s_1eb19278", "m1_children"}, -- Sure. Sounds like a cake walk.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_vaunted)

jace_yiaso_convo_m1_laugh = ConvoScreen:new {
	id = "m1_laugh",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b9baa3d5", -- Save the Empire? You? Do not make me laugh, little worm. I will admit your flying skills are impressive but the might of the Empire hardly lies in the skills of one pilot with an overblown ego. I am thinking that you should reconsider your choice to become an Inquisitor...you will not go far.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_1045dd9d", "m1_ego"}, -- I would be a great Inquisitor.
		{"@conversation/naboo_imperial_tier4:s_2b68d8fe", "m1_mock"}, -- That sounded like you were mocking me.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_laugh)

jace_yiaso_convo_m1_ego = ConvoScreen:new {
	id = "m1_ego",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c181ff30", -- You still have much to learn, my young pilot. There is no YOUR way. There is only the way of the Inquisition and the way of the Emperor. Nothing else matters. To ever be more than just a simple pilot, you must lose your pathetic, self-indulgent ego. I can show you the way down the path to true power but until you choose to take it, you will be nothing more than a slimy, little worm.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_e643719b", "m1_tasks_first"}, -- Please show me the way to true power, High Inquisitor.
		{"@conversation/naboo_imperial_tier4:s_25b2a2f6", "m1_power"}, -- No, thanks. I am so good power and glory will just come a knockin'.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_ego)

jace_yiaso_convo_m1_mock = ConvoScreen:new {
	id = "m1_mock",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5434d72a", -- Mock you? You are not even worthy of my contempt. I suggest you put your mind on the task that I am about to place before you, rather than focusing on your own pathetic existence. You are only here to serve me and your life hangs on my whims. Are we understood?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_bb9e4a63", "m1_task_worm"}, -- Understood, sir.
		{"@conversation/naboo_imperial_tier4:s_90b2fe39", "m1_task_worm"}, -- I hear you loud and clear.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_mock)

jace_yiaso_convo_m1_children = ConvoScreen:new {
	id = "m1_children",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b3e5bbfc", -- This just gets better and better. You remind me of one of my children...of course, I had to put them all to the question some time ago...
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_c42f7c3f", "m1_memories"}, -- High Inquisitor?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_children)

jace_yiaso_convo_m1_task = ConvoScreen:new {
	id = "m1_task",
	leftDialog = "@conversation/naboo_imperial_tier4:s_47b7d709", -- You are to travel to Dathomir. I have been receiving some very disturbing reports of unauthorized activity within the system. You will find out what is going on there for me.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_f2050f58", "m1_accept_dismissed"}, -- Yes, sir. Right away, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_task)

jace_yiaso_convo_m1_task_worm = ConvoScreen:new {
	id = "m1_task_worm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_83850af8", -- You are to travel to Dathomir, my little worm. I have been receiving some very disturbing reports of unauthorized activity within the system. You will find out what is going on there for me.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_5ebf813b", "m1_accept_leave"}, -- As you wish, my lord.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_task_worm)

jace_yiaso_convo_m1_thoughts = ConvoScreen:new {
	id = "m1_thoughts",
	leftDialog = "@conversation/naboo_imperial_tier4:s_cd3e5a44", -- My thoughts exactly. The true power of the Empire lies only in the Emperor and those who understand that. I can see you understand that. Enough pleasantries, time for the reason you are here. You are to travel to Dathomir. I have been receiving some very disturbing reports of unauthorized activity within the system. You will find out what is going on there for me.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_d908cfb0", "m1_accept_blessing"}, -- At the Emperor's will, my lord.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_thoughts)

jace_yiaso_convo_m1_memories = ConvoScreen:new {
	id = "m1_memories",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4092eccc", -- It is nothing. Just old memories. Pilot, never listen to your memories! They tell nothing but lies. Now, on to your assignment. You are to travel to Dathomir. I have been receiving some very disturbing reports of unauthorized activity within the system. You will find out what is going on there for me.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_97a051ab", "m1_accept_excellent"}, -- As you command, High Inquisitor.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_memories)

jace_yiaso_convo_m1_tasks_first = ConvoScreen:new {
	id = "m1_tasks_first",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6c7488f3", -- First you must complete the tasks that I will lay before you. You will travel to Dathomir. I have been receiving some very disturbing reports of unauthorized activity within the system. I want answers about what is going on.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_56c3f73d", "m1_accept_hope"}, -- For anyone else but me that might be difficult.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_tasks_first)

jace_yiaso_convo_m1_power = ConvoScreen:new {
	id = "m1_power",
	leftDialog = "@conversation/naboo_imperial_tier4:s_18dda10a", -- Very well, worm. Let me know when it shows up, but until that time you have work to do...MY WORK! Your next assignment is the Dathomir system. There have been an increasing number of reports of unauthorized access to the system. This begs many questions and I want the answers. You will get me those answers...understood?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_14c99313", "m1_forbidden"}, -- Dathomir? Interesting world.
		{"@conversation/naboo_imperial_tier4:s_714fef09", "m1_business"}, -- What business does the Inquisition have in Dathomir?
		{"@conversation/naboo_imperial_tier4:s_bb9e4a63", "m1_accept_assignment"}, -- Understood, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_power)

jace_yiaso_convo_m1_forbidden = ConvoScreen:new {
	id = "m1_forbidden",
	leftDialog = "@conversation/naboo_imperial_tier4:s_e89ef227", -- I hope you have never been there. The planet, Dathomir, is forbidden to all by Imperial decree and there is only one punishment for violating the order of the Emperor...slow, painful death! You cannot even enter the system without proper authorization. It would be such a shame to have to waste a talent like yours.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_2732abfa", "m1_accept_stay"}, -- I have never had a reason to go to Dathomir.
		{"@conversation/naboo_imperial_tier4:s_c1abdf95", "m1_accept_insolence"}, -- I go where I please.
		{"@conversation/naboo_imperial_tier4:s_488aa777", "m1_question"}, -- Why is Dathomir a forbidden system?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_forbidden)

jace_yiaso_convo_m1_business = ConvoScreen:new {
	id = "m1_business",
	leftDialog = "@conversation/naboo_imperial_tier4:s_bee296b6", -- The Inquisition has business in all systems. But if you must know we have a special duty with the Dathomir system. Not only do we maintain a prison on the planet's surface, we are the only Imperial agency with the authorization to operation freely in the system. Everyone else must get special permission to even enter the system. Therefore, it is logical that we also maintain the security of that forbidden system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_488aa777", "m1_question"}, -- Why is Dathomir a forbidden system?
		{"@conversation/naboo_imperial_tier4:s_90b2fe39", "m1_accept_assignment"}, -- I hear you loud and clear.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_business)

jace_yiaso_convo_m1_question = ConvoScreen:new {
	id = "m1_question",
	leftDialog = "@conversation/naboo_imperial_tier4:s_719f44a", -- There are some things that you should not question. The Emperor has decreed it as so and that is all you need to know.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_bb9e4a63", "m1_accept_assignment"}, -- Understood, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_question)

jace_yiaso_convo_m1_accept_stay = ConvoScreen:new {
	id = "m1_accept_stay",
	leftDialog = "@conversation/naboo_imperial_tier4:s_f87bfa4c", -- Good. You are to stay off that planet. Now I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. Dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_stay)

jace_yiaso_convo_m1_accept_insolence = ConvoScreen:new {
	id = "m1_accept_insolence",
	leftDialog = "@conversation/naboo_imperial_tier4:s_55e3ea71", -- I will forgive your insolence and call it the follies of youth. But make no mistake...Dathomir is not for the weak of spirit. I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. Now get out of my sight before I decide that youth isn't a good enough excuse. Oh, and worm...fail me and you will find yourself firmly on a hook!
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_insolence)

jace_yiaso_convo_m1_accept_assignment = ConvoScreen:new {
	id = "m1_accept_assignment",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4bb3d9ba", -- Good. Now your assignment...I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. Dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_assignment)

jace_yiaso_convo_m1_accept_hope = ConvoScreen:new {
	id = "m1_accept_hope",
	leftDialog = "@conversation/naboo_imperial_tier4:s_517a8075", -- I hope for your sake that it is not. I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. Oh, and worm...fail me and you will find yourself firmly on a hook!
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_hope)

jace_yiaso_convo_m1_accept_assume = ConvoScreen:new {
	id = "m1_accept_assume",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9b3e4e71", -- I will simply assume that means no. I cannot afford to lose you at this moment. I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. You may leave now.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_assume)

jace_yiaso_convo_m1_accept_excellent = ConvoScreen:new {
	id = "m1_accept_excellent",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6387b3e9", -- Excellent. I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. You have your command...now go!
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_excellent)

jace_yiaso_convo_m1_accept_dismissed = ConvoScreen:new {
	id = "m1_accept_dismissed",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6807942", -- Excellent. I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. Dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_dismissed)

jace_yiaso_convo_m1_accept_leave = ConvoScreen:new {
	id = "m1_accept_leave",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a5e556b", -- I will have command transmit a patrol route that you will fly once you enter the Dathomir system. Keep a careful watch for any unauthorized activity. I have a strange feeling that this will only be the first step down a long path. You may leave my presence now.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_leave)

jace_yiaso_convo_m1_accept_blessing = ConvoScreen:new {
	id = "m1_accept_blessing",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c4f0640e", -- I will have command transmit a patrol route that I wish you to fly once you enter the Dathomir system. Follow the route and keep a careful watch for any unauthorized activity. These reports I have been receiving have left me feeling uneasy. I will know what is going on there. May the Emperor's blessing be on you, %NU.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m1_accept_blessing)

jace_yiaso_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b0feed48", -- We have completed our analysis of that crystal you recovered.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_ed8a35fe", "m2_report"}, -- What did you find out about it, sir?
		{"@conversation/naboo_imperial_tier4:s_c6f1b86f", "m2_serve"}, -- I am ready to serve, if the Emperor wills it.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_brief)

jace_yiaso_convo_m2_brief_trained = ConvoScreen:new {
	id = "m2_brief_trained",
	leftDialog = "@conversation/naboo_imperial_tier4:s_cacb4480", -- A very handy skill to know in a pinch. It is a good thing that you returned for training when you did, I was about to send a probe droid out after you. Just a little humor there, but in all seriousness, it is good that you have returned. We have completed our analysis of that crystal you recovered.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_ed8a35fe", "m2_report"}, -- What did you find out about it, sir?
		{"@conversation/naboo_imperial_tier4:s_c6f1b86f", "m2_serve"}, -- I am ready to serve, if the Emperor wills it.
		{"@conversation/naboo_imperial_tier4:s_2a5728d1", "m2_joviality"}, -- That joke, and I use that term loosely, was terrible.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_brief_trained)

jace_yiaso_convo_m2_joviality = ConvoScreen:new {
	id = "m2_joviality",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b9a22caa", -- I am afraid that I do not have much practice with joviality. My talents have always seemed to lie elsewhere but I always try to bring a little bit of merriment to the job. A light heart makes even the heaviest of tasks easier.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6973ca89", "m2_fruits"}, -- We are the Inquisition. I didn't think happy was our thing.
		{"@conversation/naboo_imperial_tier4:s_eaf485aa", "m2_persona"}, -- Wait a minute...this is all an act?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_joviality)

jace_yiaso_convo_m2_fruits = ConvoScreen:new {
	id = "m2_fruits",
	leftDialog = "@conversation/naboo_imperial_tier4:s_30c7137f", -- It is not for the people we deal with, but there is no reason why we cannot enjoy the fruits of our labor once in a while. Never mind, my advice is simply going to be wasted on you. Back to work. The lab finished the analysis of the crystal you recovered. With some very interesting results. I suppose you would like to know what those are, eh worm?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_98332c8e", "m2_report"}, -- Yes, what did they find out?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_fruits)

jace_yiaso_convo_m2_persona = ConvoScreen:new {
	id = "m2_persona",
	leftDialog = "@conversation/naboo_imperial_tier4:s_e9776d82", -- Almost any persona is half an act. It is actions that always speak the loudest about an individuals resolve. I assure you my resolve is far greater than my persona will ever be. Care to find out?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_28532034", "m2_report"}, -- No, thanks. How about you tell me about the crystal instead?
		{"@conversation/naboo_imperial_tier4:s_1eb19278", "m2_unbendable"}, -- Sure. Sounds like a cake walk.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_persona)

jace_yiaso_convo_m2_unbendable = ConvoScreen:new {
	id = "m2_unbendable",
	leftDialog = "@conversation/naboo_imperial_tier4:s_a6cd772d", -- You think that you are strong and unbendable? I have found the harder it is to bend the easier it is to break. You...I could crumble into dust in scant seconds. But I do not have even those scant seconds to waste. You have to do an assignment for me...perhaps we can get back to this later.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_898acaac", "m2_recon"}, -- What is it you need me to do, sir?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_unbendable)

jace_yiaso_convo_m2_report = ConvoScreen:new {
	id = "m2_report",
	leftDialog = "@conversation/naboo_imperial_tier4:s_fc6dc2db", -- I have the report right here. Let me see. The crystal is composed of...alichite...30 perc...timmerosu...AH! Here is the important part that you need to know about. The crystal is found on only one planet in the entire universe, Dathomir. It is clear that this smuggler landed on the planets surface and recovered the rock. A very unfortunate situation.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_ffa89518", "m2_concern"}, -- Why is it unfortunate?
		{"@conversation/naboo_imperial_tier4:s_ecb0921e", "m2_know_plain"}, -- Isn't Dathomir was forbidden. How do you know this?
		{"@conversation/naboo_imperial_tier4:s_9ac7bd6d", "m2_not_alone"}, -- So the smuggler had to land on the planet.
		{"@conversation/naboo_imperial_tier4:s_938d7337", "m2_recon"}, -- So what is the next step, sir?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_report)

jace_yiaso_convo_m2_serve = ConvoScreen:new {
	id = "m2_serve",
	leftDialog = "@conversation/naboo_imperial_tier4:s_6d844cc7", -- The Emperor does indeed wish you to serve. The lab has finished analyzing the crystal you recovered. A most interesting piece of rock. Most interesting and most rare, indeed. In fact that particular crystal can only be found one place in the entire galaxy...Dathomir.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6ef5b0ae", "m2_know_worm"}, -- I thought Dathomir was forbidden. How do you know this?
		{"@conversation/naboo_imperial_tier4:s_b84f68ab", "m2_sum"}, -- Why would he land on Dathomir for a crystal?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_serve)

jace_yiaso_convo_m2_know_worm = ConvoScreen:new {
	id = "m2_know_worm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_2ac3895f", -- It is my business to know things, worm. That and we maintain a prison on the planet's surface. Prisoners are dropped in from orbit, never to leave again. The guards who maintain the prison have surveyed a large portion of the planets unique flora, fauna, and, thankfully, geology.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_b84f68ab", "m2_sum"}, -- Why would he land on Dathomir for a crystal?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_know_worm)

jace_yiaso_convo_m2_know_plain = ConvoScreen:new {
	id = "m2_know_plain",
	leftDialog = "@conversation/naboo_imperial_tier4:s_952743eb", -- It is my business to know things. That and we maintain a prison on the planet's surface. Prisoners are dropped in from orbit, never to leave again. The guards who maintain the prison have surveyed a large portion of the planets unique flora, fauna, and, thankfully, geology.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_b84f68ab", "m2_sum"}, -- Why would he land on Dathomir for a crystal?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_know_plain)

jace_yiaso_convo_m2_sum = ConvoScreen:new {
	id = "m2_sum",
	leftDialog = "@conversation/naboo_imperial_tier4:s_81ccdc67", -- The crystals are worth a very handsome sum to the right people. They are rumored to have strange...properties. Of course, the question is how did that pilot get it? These crystals cannot be found just sitting around on the ground for any fool to pick up. They are only found deep under the surface.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_9ac7bd6d", "m2_not_alone"}, -- So the smuggler had to land on the planet.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_sum)

jace_yiaso_convo_m2_concern = ConvoScreen:new {
	id = "m2_concern",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c686dfd", -- That is not a matter for you to have to worry about. Your only concerns are what I tell them to be. That crystal can fetch a very large sum to the right people. It is said to contain 'unique' powers, if you believe in that sort of thing. Of course, the question is how did that pilot get it? These crystals cannot be found just sitting around on the ground for any fool to pick up. They are only found deep under the surface.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_9ac7bd6d", "m2_not_alone"}, -- So the smuggler had to land on the planet.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_concern)

jace_yiaso_convo_m2_not_alone = ConvoScreen:new {
	id = "m2_not_alone",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1e39a0ae", -- Yes. In clear violation of Imperial law. Of course, he is not working alone. All those reports I received would not have been generated by one lone individual. So I took the liberty of sending out several recon shuttles into the Dathomir system. It would appear that there are several vessels all working in unison in this little venture of theirs.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_eda629db", "m2_capture"}, -- Then I must destroy them.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_not_alone)

jace_yiaso_convo_m2_capture = ConvoScreen:new {
	id = "m2_capture",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4ee43f47", -- All in good time. I have a feeling that this goes a little bit deeper than that. The recon shuttle has tracked one of the vessels that landed on the planet's surface before we could stop it. You are to immediately capture that vessel as soon as it reenters orbit. If that ship looks like it is about to get away you are to destroy it. Take no chances that it will get out of the system. Is that understood?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6d741d67", "m2_accept_prey"}, -- Yes. If I cannot capture the vessel, it will die.
		{"@conversation/naboo_imperial_tier4:s_bb9e4a63", "m2_accept_counted"}, -- Understood, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_capture)

jace_yiaso_convo_m2_recon = ConvoScreen:new {
	id = "m2_recon",
	leftDialog = "@conversation/naboo_imperial_tier4:s_8074838e", -- I did not believe that all the reports I had been receiving were for this one lone individual, so I dispatched a set of recon shuttles to the system. Their scans revealed that a number of these vessels are moving around the system. We have a lock on one that recently touched down on the planet. Incidentally, or so it would seem, near the location of the prison. You are to capture me that ship when it returns to orbit.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6d741d67", "m2_accept_prey"}, -- Yes. If I cannot capture the vessel, it will die.
		{"@conversation/naboo_imperial_tier4:s_17fa0de9", "m2_accept_counted"}, -- Yes, sir. Right away.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_recon)

jace_yiaso_convo_m2_accept_prey = ConvoScreen:new {
	id = "m2_accept_prey",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9a9518f8", -- Good. Now get to Dathomir and wait for your prey to arrive.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_accept_prey)

jace_yiaso_convo_m2_accept_counted = ConvoScreen:new {
	id = "m2_accept_counted",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ee5488a5", -- That is a good pilot. I knew that you could be counted on. You are dismissed.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m2_accept_counted)

jace_yiaso_convo_m3_brief = ConvoScreen:new {
	id = "m3_brief",
	leftDialog = "@conversation/naboo_imperial_tier4:s_ad56bc53", -- I broke the Coynite mercenary, as I knew I would. Sadly he was no where near as strong as I had hoped he would be. Such a disappointment.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_231ed37", "m3_fulfilling"}, -- I am sorry you didn't enjoy your work.
		{"@conversation/naboo_imperial_tier4:s_e977b428", "m3_old_republic"}, -- There is no strength of will in people anymore.
		{"@conversation/naboo_imperial_tier4:s_6c2a8e60", "m3_one_and_same"}, -- What did you learn from him?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_brief)

jace_yiaso_convo_m3_brief_trained = ConvoScreen:new {
	id = "m3_brief_trained",
	leftDialog = "@conversation/naboo_imperial_tier4:s_aa21cdc1", -- I hope that skill serves me well as we begin the next stage of our operation. I broke the Coynite mercenary, as I knew I would. Sadly he was no where near as strong as I had hoped he would be. Such a disappointment.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_231ed37", "m3_fulfilling"}, -- I am sorry you didn't enjoy your work.
		{"@conversation/naboo_imperial_tier4:s_e977b428", "m3_old_republic"}, -- There is no strength of will in people anymore.
		{"@conversation/naboo_imperial_tier4:s_6c2a8e60", "m3_one_and_same"}, -- What did you learn from him?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_brief_trained)

jace_yiaso_convo_m3_fulfilling = ConvoScreen:new {
	id = "m3_fulfilling",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4c064599", -- I wouldn't say that. It just wasn't as fulfilling as I had hoped it would be. High expectations always lead to the greatest disappointments. On the bright side I did manage to get most of the information we were looking for out of him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6480af88", "m3_one_and_same"}, -- Really? What did he say?
		{"@conversation/naboo_imperial_tier4:s_64e1e69d", "m3_silence"}, -- Maybe you should have tried harder?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_fulfilling)

jace_yiaso_convo_m3_old_republic = ConvoScreen:new {
	id = "m3_old_republic",
	leftDialog = "@conversation/naboo_imperial_tier4:s_acaea8b8", -- Of course there isn't. If there was, there would be no need for the Emperor or the Empire. We are the rock in the middle of the decay of strength and character. This was all caused by the Old Republic of course. If they had done their duty long ago, none of this would be necessary.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_438b0dbc", "m3_one_and_same"}, -- What did the Coynite speak of?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_old_republic)

jace_yiaso_convo_m3_one_and_same = ConvoScreen:new {
	id = "m3_one_and_same",
	leftDialog = "@conversation/naboo_imperial_tier4:s_1899241d", -- The Coynite and the smugglers are one and the same. Just before he expired, he also told me all about their friends on the planets surface. It would seem that they are receiving aid from someone in the prison. Whoever their friend, or friends, are they are paying the Coynite with the crystals. I lost him before he could tell me who or why. Not my best work but we have what we need.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_63b2a28a", "m3_satellite"}, -- So, now we don't have any way to find out who is helping the Coynite?
		{"@conversation/naboo_imperial_tier4:s_e07a0513", "m3_theories"}, -- Do you have any idea who is helping them?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_one_and_same)

jace_yiaso_convo_m3_theories = ConvoScreen:new {
	id = "m3_theories",
	leftDialog = "@conversation/naboo_imperial_tier4:s_5fcdb10d", -- Oh, I have several theories but I do not like to work on theory. Cold, hard fact has always been more to my liking.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_63b2a28a", "m3_satellite"}, -- So, now we don't have any way to find out who is helping the Coynite?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_theories)

jace_yiaso_convo_m3_silence = ConvoScreen:new {
	id = "m3_silence",
	leftDialog = "@conversation/naboo_imperial_tier4:s_b517963a", -- Silence! I will have none of your lip today. Do not try my patience or I just might see if I can find fulfillment with questioning you. I did manage to get one very important piece of information out of him...how they communicate.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_df53fe63", "m3_fool"}, -- Open their mouths...talk to each other. That is how we do it.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_silence)

jace_yiaso_convo_m3_fool = ConvoScreen:new {
	id = "m3_fool",
	leftDialog = "@conversation/naboo_imperial_tier4:s_dafddb17", -- Fool! I meant how their friends on the ground send instructions to the Coynite. They use a satellite to send signals from the prison, then the Coynite listen in. It is a one way communication but is enough to suit their needs. You are going to travel to that satellite and tap into their instructions.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_9ab33e62", "m3_accept_surveillance"}, -- Is that it?
		{"@conversation/naboo_imperial_tier4:s_90b2fe39", "m3_accept_orders"}, -- I hear you loud and clear.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_fool)

jace_yiaso_convo_m3_satellite = ConvoScreen:new {
	id = "m3_satellite",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c13abf66", -- Didn't I mention that he told me about the satellite receiver that they are using to get instructions from the planet? I could have sworn I told you that. No matter. You are to travel to that satellite and tap into their communications. It should be fairly easy, except that the Coynite have the satellite under constant surveillance, so you will have to guard against them while running your tap. But then again that is what you are here for.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_56c3f73d", "m3_accept_trust"}, -- For anyone else but me that might be difficult.
		{"@conversation/naboo_imperial_tier4:s_bb9e4a63", "m3_accept_orders"}, -- Understood, sir.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_satellite)

jace_yiaso_convo_m3_accept_surveillance = ConvoScreen:new {
	id = "m3_accept_surveillance",
	leftDialog = "@conversation/naboo_imperial_tier4:s_4bcaf756", -- Well, the Coynite have the satellite under constant surveillance so they will most likely attack you while you are trying to tap into the signal. If you succeed you will have some very valuable information for me. If you fail then you will be dead. Sounds like a win win situation for me. You have you orders. Carry on, pilot.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_accept_surveillance)

jace_yiaso_convo_m3_accept_trust = ConvoScreen:new {
	id = "m3_accept_trust",
	leftDialog = "@conversation/naboo_imperial_tier4:s_320b2029", -- Then I trust you will not fail me. It would be a most unwise decision on your part if you did.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_accept_trust)

jace_yiaso_convo_m3_accept_orders = ConvoScreen:new {
	id = "m3_accept_orders",
	leftDialog = "@conversation/naboo_imperial_tier4:s_db35e23", -- You have your orders. Dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m3_accept_orders)

jace_yiaso_convo_m4_brief = ConvoScreen:new {
	id = "m4_brief",
	leftDialog = "@conversation/naboo_imperial_tier4:s_673b4c9b", -- It has been a long journey for you but you are nearing the end. I do have need of an extra pilot though. And since you are already here, you will do nicely.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_898acaac", "m4_prison"}, -- What is it you need me to do, sir?
		{"@conversation/naboo_imperial_tier4:s_f7053b89", "m4_prison"}, -- What are your orders, sir?
		{"@conversation/naboo_imperial_tier4:s_a6ef12b5", "m4_slow"}, -- Well what do you want me to do?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_brief)

jace_yiaso_convo_m4_brief_trained = ConvoScreen:new {
	id = "m4_brief_trained",
	leftDialog = "@conversation/naboo_imperial_tier4:s_72c7b032", -- Excellent you are nearly finished with your training. It has been a long journey for you but you are nearing the end. I do have need of an extra pilot though. And since you are already here, you will do nicely.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_898acaac", "m4_prison"}, -- What is it you need me to do, sir?
		{"@conversation/naboo_imperial_tier4:s_f7053b89", "m4_prison"}, -- What are your orders, sir?
		{"@conversation/naboo_imperial_tier4:s_a6ef12b5", "m4_slow"}, -- Well what do you want me to do?
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_brief_trained)

jace_yiaso_convo_m4_prison = ConvoScreen:new {
	id = "m4_prison",
	leftDialog = "@conversation/naboo_imperial_tier4:s_7d9ad22", -- The prison drop shuttle that we were holding until the Coynite issue was dealt with is ready to drop its payload of prisoners on Dathomir. I need you to escort it through the system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_d908cfb0", "m4_accept_blessing"}, -- At the Emperor's will, my lord.
		{"@conversation/naboo_imperial_tier4:s_97a051ab", "m4_accept_my_way"}, -- As you command, High Inquisitor.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_prison)

jace_yiaso_convo_m4_slow = ConvoScreen:new {
	id = "m4_slow",
	leftDialog = "@conversation/naboo_imperial_tier4:s_52708145", -- We will start you off with something slow. I need a prison drop shuttle escorted to the prison on Dathomir. We have been holding off shipping those prisoners while we dealt with the Coynite issue and it is time that they were sent home.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier4:s_6c193c27", "m4_accept_slow"}, -- Sure thing. Shouldn't be a problem.
		{"@conversation/naboo_imperial_tier4:s_1eb19278", "m4_accept_worm"}, -- Sure. Sounds like a cake walk.
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_slow)

jace_yiaso_convo_m4_accept_blessing = ConvoScreen:new {
	id = "m4_accept_blessing",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c2c13cf7", -- The Emperor's blessing be with you, %NU.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_accept_blessing)

jace_yiaso_convo_m4_accept_my_way = ConvoScreen:new {
	id = "m4_accept_my_way",
	leftDialog = "@conversation/naboo_imperial_tier4:s_9ac8a54c", -- Yes. I knew you would see it my way.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_accept_my_way)

jace_yiaso_convo_m4_accept_slow = ConvoScreen:new {
	id = "m4_accept_slow",
	leftDialog = "@conversation/naboo_imperial_tier4:s_55590e1c", -- Good. There shouldn't be any issues but there is still something that bothers me about the Coynite situation. I would rather be safe then sorry. We cannot have our prisoners running free all over the galaxy, now can we? You are dismissed, pilot.
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_accept_slow)

jace_yiaso_convo_m4_accept_worm = ConvoScreen:new {
	id = "m4_accept_worm",
	leftDialog = "@conversation/naboo_imperial_tier4:s_c71c1bab", -- Get out of my sight! Go escort a prison drop shuttle through the Dathomir system on its way to drop its payload on the prison. Begone, worm!
	stopConversation = "true",
	options = {
	}
}
jace_yiaso_convo_template:addScreen(jace_yiaso_convo_m4_accept_worm)

addConversationTemplate("jace_yiaso_convo_template", jace_yiaso_convo_template)
