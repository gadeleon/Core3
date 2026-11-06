-- Lt. Colonel Barlow (Inquisition tier 3 interrogation) conversation; ported from SWG-Source naboo_imperial_tier3_barlow.java with the pre-NGE client lines (feature inquisition-tier3-barlow). Handler: barlowConvoHandler.
barlow_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "barlowConvoHandler",
	screens = {}
}

barlow_convo_restricted = ConvoScreen:new {
	id = "restricted",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_127f71ad", -- This is a restricted area. I suggest that you move along before I am forced to charge you under violation of Imperial directive T43-X9A.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_restricted)

barlow_convo_interview = ConvoScreen:new {
	id = "interview",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a72db7d9", -- Yes? What do you want? I am extremely busy.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_40f102e4", "interview_d8cce866"}, -- My name is not important. I am here on behalf of Inquisitor Vrke.
		{"@conversation/naboo_imperial_tier3_barlow:s_ca59425a", "interview_61286e9e"}, -- I don't care how busy you are. We are going to talk.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview)

barlow_convo_interview_d8cce866 = ConvoScreen:new {
	id = "interview_d8cce866",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_d8cce866", -- Vrke eh? I have already spoken with you people. I had nothing to do with Colonel Hend and I didn't know anything about what he was doing.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_aeb1b3ee", "interview_1506d494"}, -- Perhaps you are unaware of what you actually know.
		{"@conversation/naboo_imperial_tier3_barlow:s_28a49383", "interview_7e952afa"}, -- And now you are going to talk with me.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_d8cce866)

barlow_convo_interview_61286e9e = ConvoScreen:new {
	id = "interview_61286e9e",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_61286e9e", -- Uh? Am I in some sort of trouble? You are not going to do anything to me are you? Because I will have you know that torture of an officer is forbidden under Imperial directive Y70-32C subsection 14.
	animation = "nervous",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_f9e3a71b", "interview_3d1204e0"}, -- There will be no need if you answer some questions for me.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_61286e9e)

barlow_convo_interview_1506d494 = ConvoScreen:new {
	id = "interview_1506d494",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_1506d494", -- What! What does that mean? I don't understand what you are talking about.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_c97a22d4", "interview_61286e9e"}, -- You are not supposed to understand the mysteries of the Inquisition!
		{"@conversation/naboo_imperial_tier3_barlow:s_b39c7b81", "interview_64113df0"}, -- Sorry, that sounded much more intimidating in my head.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_1506d494)

barlow_convo_interview_7e952afa = ConvoScreen:new {
	id = "interview_7e952afa",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_7e952afa", -- Of course. It is the duty of every Imperial officer to assist any Inquisition agent on assignment. I will be very glad to answer any questions that you might have.
	animation = "salute1",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_a623d5ba", "interview_39774984"}, -- Did you ever suspect Colonel Hend as a traitor?
		{"@conversation/naboo_imperial_tier3_barlow:s_15fccf52", "interview_3181543b"}, -- Who did Colonel Hend spend most of his time with?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_7e952afa)

barlow_convo_interview_3d1204e0 = ConvoScreen:new {
	id = "interview_3d1204e0",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3d1204e0", -- Of course I will cooperate. It is every Imperial officer's duty to cooperate in the fullest with any Inquisition investigation. All you had to do was ask. You didn't have to threaten me like that.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_3700f6", "interview_45d046d5"}, -- Silence! I will ask you questions and you will answer them.
		{"@conversation/naboo_imperial_tier3_barlow:s_9d1204e3", "interview_eed04a50"}, -- Sorry, I am sort of new at this whole Inquisition thing.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3d1204e0)

barlow_convo_interview_64113df0 = ConvoScreen:new {
	id = "interview_64113df0",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_64113df0", -- I recommend that you try saying those things out loud in private before you actually say them to someone else. That way you won't come off like some sort of crazed fool.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_24614dc6", "interview_61286e9e"}, -- A member of the Inquisition is never foolish! You will pay for that statement!
		{"@conversation/naboo_imperial_tier3_barlow:s_ac8cb7ce", "interview_38ae0970"}, -- Yeah, maybe in a mirror or something. Anyway...what was I saying?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_64113df0)

barlow_convo_interview_39774984 = ConvoScreen:new {
	id = "interview_39774984",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_39774984", -- Of course not. If I had I would have arrested him and made my report according to Imperial directive J323-9V. I wish I had known, so I could have put an end to it. It makes me sick to know that I served under a traitor.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_61c6827c", "interview_c39786e7"}, -- Wouldn't arresting a superior officer violate Imperial directive T44A-0-niner?
		{"@conversation/naboo_imperial_tier3_barlow:s_fb1ee7a5", "interview_be74eb0"}, -- Are you aware of anyone that suspected?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_39774984)

barlow_convo_interview_3181543b = ConvoScreen:new {
	id = "interview_3181543b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3181543b", -- He spent most of his off hours with a few of the junior officers. Occasionally the group of them would take leave together and fly off in Hend's yacht. Nothing really out of the ordinary, although I must say I don't approve of officers mixing in social circumstances.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_6f94037e", "interview_fcbf7850"}, -- Who here had higher security clearance than Colonel Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3181543b)

barlow_convo_interview_45d046d5 = ConvoScreen:new {
	id = "interview_45d046d5",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_45d046d5", -- Very well. But I will have you know that I will be in contact with Inquisitor Vrke as soon as this interview is done and discuss your behavior towards a superior officer. You might be a member of the Inquisition, but I am a Lieutenant Colonel in the Imperial Army and your respect is still expected.
	animation = "wave_finger_warning",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_7ef5613c", "interview_c3c8f385"}, -- I said silence! Now, how well did you know Colonel Hend?
		{"@conversation/naboo_imperial_tier3_barlow:s_1fa017ef", "interview_c3c8f385_b"}, -- I said silence! What did Colonel Hend do in his spare time?
		{"@conversation/naboo_imperial_tier3_barlow:s_fa3924b4", "interview_c3c8f385_c"}, -- I said silence! Did Colonel Hend fraternize with the Engineers corps?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_45d046d5)

barlow_convo_interview_eed04a50 = ConvoScreen:new {
	id = "interview_eed04a50",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_eed04a50", -- Well, that isn't very professional of you. You shouldn't threaten to torture someone unless you are actually planning on doing it. It just really shows a lack of resolve and planning on your part.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_80254eb2", "interview_7e952afa"}, -- I suppose you are right. So would you answer some questions for me?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_eed04a50)

barlow_convo_interview_38ae0970 = ConvoScreen:new {
	id = "interview_38ae0970",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_38ae0970", -- You were going to ask me about Colonel Hend.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_2b0fcb12", "interview_129cd101"}, -- Yes, I know that. I was just testing to see if you were paying attention.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_38ae0970)

barlow_convo_interview_c39786e7 = ConvoScreen:new {
	id = "interview_c39786e7",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_c39786e7", -- How would arresting a superior officer violate the directive banning the use of an Imperial officer's hat as a Wookiee beating device? I am afraid that I really don't understand your question.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_8d77e799", "interview_be74eb0"}, -- Never mind. Do you know of anyone who might have known Hend was a traitor?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_c39786e7)

barlow_convo_interview_be74eb0 = ConvoScreen:new {
	id = "interview_be74eb0",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_be74eb0", -- If I had that information, I would have given it to the Inquisitors that were here before. All I know is that Hend liked to spend his off time with some of the junior officers. They all get together after they were off duty and sometimes they would all take leave together and go out on Hend's yacht. But I don't think any of them even knew.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_dc89a970", "interview_fcbf7850"}, -- Who here has higher security clearance than Colonel Hend did?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_be74eb0)

barlow_convo_interview_fcbf7850 = ConvoScreen:new {
	id = "interview_fcbf7850",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_fcbf7850", -- Several of the engineers do. Doctor Verr, Doctor Plenki, Doctor Shinss, and Doctor Stile all do. Even though Colonel Hend was in charge of security, there are a number of things going on here that it was not necessary for him to know about.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_35f73adf", "interview_6ac3f291"}, -- Did Colonel Hend spend any time with any of them?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_fcbf7850)

barlow_convo_interview_c3c8f385 = ConvoScreen:new {
	id = "interview_c3c8f385",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_c3c8f385", -- [silence]
	animation = "tap_foot",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d5ad0fe2", "interview_22cf270c"}, -- Ah ha! You cannot hide your guilt behind silence!
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_c3c8f385)

barlow_convo_interview_c3c8f385_b = ConvoScreen:new {
	id = "interview_c3c8f385_b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_c3c8f385", -- [silence]
	animation = "tap_foot",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d5ad0fe2", "interview_6bd0e9b"}, -- Ah ha! You cannot hide your guilt behind silence!
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_c3c8f385_b)

barlow_convo_interview_c3c8f385_c = ConvoScreen:new {
	id = "interview_c3c8f385_c",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_c3c8f385", -- [silence]
	animation = "tap_foot",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d5ad0fe2", "interview_bf9b99b9"}, -- Ah ha! You cannot hide your guilt behind silence!
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_c3c8f385_c)

barlow_convo_interview_129cd101 = ConvoScreen:new {
	id = "interview_129cd101",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_129cd101", -- You do have my full attention, Inquisitor. What can I help you with?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_f211ed92", "interview_aa484e27"}, -- Colonel Hend. A very bad man, but what sort of man was he?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_129cd101)

barlow_convo_interview_6ac3f291 = ConvoScreen:new {
	id = "interview_6ac3f291",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_6ac3f291", -- Not really. He dealt with Doctor Shinss mostly but that was all official work. Doctor Shinss is the head of the salvage operation and it was important for the head of security to work closely with him.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_14c38c33", "interview_e6ae8de"}, -- What sort of man is Doctor Shinss?
		{"@conversation/naboo_imperial_tier3_barlow:s_c3185891", "interview_760db2a"}, -- How often would the two of them meet?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_6ac3f291)

barlow_convo_interview_22cf270c = ConvoScreen:new {
	id = "interview_22cf270c",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_22cf270c", -- I am not hiding anything. You told me to be silent so I was silent. I may have to follow your orders and answer you questions but I will not tolerate any accusations against my loyalty. To answer your question, Colonel Hend was my superior officer for the past three months. I did not know him very well on a personal level, since I disapprove of officers becoming too friendly with each other.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_81caddeb", "interview_4bbd7016"}, -- So you don't believe that officers should work together?
		{"@conversation/naboo_imperial_tier3_barlow:s_874f9344", "interview_d9a69ecd"}, -- You are protesting a lot. Are you sure you are not guilty of something?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_22cf270c)

barlow_convo_interview_6bd0e9b = ConvoScreen:new {
	id = "interview_6bd0e9b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_6bd0e9b", -- I am not hiding anything. You told me to be silent so I was silent. I may have to follow your orders and answer you questions but I will not tolerate any accusations against my loyalty. To answer your question, I really don't know what Colonel Hend did in his spare time.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_cd5b3d17", "interview_e40d4ee9"}, -- So you are telling me you have no idea what your superior officer liked to do?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_6bd0e9b)

barlow_convo_interview_bf9b99b9 = ConvoScreen:new {
	id = "interview_bf9b99b9",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_bf9b99b9", -- I am not hiding anything. You told me to be silent so I was silent. I may have to follow your orders and answer you questions but I will not tolerate any accusations against my loyalty. But to answer your question, Colonel Hend didn't fraternize with anyone from the engineering corps. He obviously worked with them since he was head of security.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_8fa4c7bd", "interview_ffee58bf"}, -- Well, who did he fraternize with if not the engineers?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_bf9b99b9)

barlow_convo_interview_aa484e27 = ConvoScreen:new {
	id = "interview_aa484e27",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_aa484e27", -- What? Oh...you mean other than a bad man. He was a fair commander. Liked his junior officer a bit too much in my opinion. But nothing about him ever gave away the fact that he was a traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_99701b9c", "interview_d2a410b8"}, -- So he had a light complexion. Very interesting.
		{"@conversation/naboo_imperial_tier3_barlow:s_f039fce5", "interview_5b81ae31"}, -- But he was a traitor, so there had to be something.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_aa484e27)

barlow_convo_interview_e6ae8de = ConvoScreen:new {
	id = "interview_e6ae8de",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_e6ae8de", -- Shinss is a good enough man. From my understanding he is supposed to be brilliant but I don't know him well enough to make a judgment to that matter.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_797cf757", "interview_a55b2dc8"}, -- Don't you deal with the Doctor now?
		{"@conversation/naboo_imperial_tier3_barlow:s_3c8f00ed", "interview_760db2a"}, -- How often would Hend and Shinss meet?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_e6ae8de)

barlow_convo_interview_760db2a = ConvoScreen:new {
	id = "interview_760db2a",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_760db2a", -- While they were on duty it was constant. Shinss was always in Colonel Hend's office complaining about the way he was running things. Several times they had to take shuttles out to view the debris fields. I think Shinss wanted to actually show Colonel Hend what he needed. That sort of thing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_45ebf891", "interview_d1d8d28a"}, -- So you were there while they had their discussions?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_760db2a)

barlow_convo_interview_4bbd7016 = ConvoScreen:new {
	id = "interview_4bbd7016",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_4bbd7016", -- What? I didn't say that. I said that I didn't think that officers should become friends. It ruins the objectiveness of command. I was less than pleased by Colonel Hend's relationship with some of the other officers on the project.
	animation = "point_away",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_9b59f040", "interview_4c694267"}, -- So you were jealous?
		{"@conversation/naboo_imperial_tier3_barlow:s_e616a383", "interview_ffee58bf"}, -- Which officers were these?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_4bbd7016)

barlow_convo_interview_d9a69ecd = ConvoScreen:new {
	id = "interview_d9a69ecd",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_d9a69ecd", -- I have no idea what is going on here but I can assure you that I have nothing to hide. I am just trying to assist you in your investigation any way that I can. But you certainly are not making this easy on me.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_eb02c97f", "interview_3b0eba1c"}, -- So now I should take it easy on you?
		{"@conversation/naboo_imperial_tier3_barlow:s_cb6d22cd", "interview_a82360e0"}, -- I will determine if you are hiding anything or not!
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_d9a69ecd)

barlow_convo_interview_e40d4ee9 = ConvoScreen:new {
	id = "interview_e40d4ee9",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_e40d4ee9", -- Colonel Hend was my superior officer for the past three months. I did not know him very well on a personal level, since I disapprove of officers becoming too friendly with each other.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_81caddeb", "interview_4bbd7016"}, -- So you don't believe that officers should work together?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_e40d4ee9)

barlow_convo_interview_ffee58bf = ConvoScreen:new {
	id = "interview_ffee58bf",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_ffee58bf", -- Colonel Hend liked to relax with all sorts of junior officers. I don't know if I would really call them friends but they would do things together, like take leave at the same time. It was my understanding that Colonel Hend would fly them around in that yacht of his when they did. Of course, I never went with them.
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_3668d398", "interview_379b50a7"}, -- I am sorry that they left you out of their fun. That must be very painful for you.
		{"@conversation/naboo_imperial_tier3_barlow:s_85c0a145", "interview_ecda4c4f"}, -- Where would they go on these trips?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_ffee58bf)

barlow_convo_interview_d2a410b8 = ConvoScreen:new {
	id = "interview_d2a410b8",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_d2a410b8", -- I am afraid that I am not following were you are going with this. I would very much like to assist the Inquisition but I don't understand what you want me to tell you.
	animation = "listen",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_5bc4c2f1", "interview_1ae1c792"}, -- Of course you don't. That is why I am here and you are there.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_d2a410b8)

barlow_convo_interview_5b81ae31 = ConvoScreen:new {
	id = "interview_5b81ae31",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_5b81ae31", -- I would imagine so. But I was unable to determine what those signs were. As far as I knew, Colonel Hend was absolutely loyal to the Empire. If I would have had any inkling otherwise, I would have reported him.
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_46897102", "interview_2188ff96"}, -- Really? Who would you have reported him to?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_5b81ae31)

barlow_convo_interview_a55b2dc8 = ConvoScreen:new {
	id = "interview_a55b2dc8",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a55b2dc8", -- There is little need for me to meet with the Doctor. I do my duty and he has his operation to run. I run a very tight ship so that Doctor Shinss doesn't have to constantly hold my hand like he always did with Colonel Hend. It seemed like every time I turned around, Shinss and Hend had their heads together discussing what a terrible job Colonel Hend was doing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_62adf222", "interview_e0659186"}, -- Let me get this straight, you never meet with Doctor Shinss?
		{"@conversation/naboo_imperial_tier3_barlow:s_802362c2", "interview_760db2a"}, -- Shinss and Hend spent a lot of time together?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_a55b2dc8)

barlow_convo_interview_d1d8d28a = ConvoScreen:new {
	id = "interview_d1d8d28a",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_d1d8d28a", -- No, of course not. But if I were Doctor Shinss, that is what I would be talking to Colonel Hend about. Hend wasn't the best of leaders. Of course, now that I am in charge the operation is running smoothly and Doctor Shinss can concentrate on his mission.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_ea32ea5a", "end_2b71207d"}, -- Thank you for your time. I see no need to continue this conversation.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_d1d8d28a)

barlow_convo_interview_4c694267 = ConvoScreen:new {
	id = "interview_4c694267",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_4c694267", -- There is something seriously wrong with you. Why would I be jealous of Colonel Hend's relationship with other officers? I just disapproved, that is all. I mean I never really wanted to have anything to do with him...other than being under his command.
	animation = "refuse_offer_affection",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d324b656", "interview_c4c46aa"}, -- So you murdered Colonel Hend out of revenge for his rejection towards you?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_4c694267)

barlow_convo_interview_3b0eba1c = ConvoScreen:new {
	id = "interview_3b0eba1c",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3b0eba1c", -- I would at least appreciate a little respect. You may work for the Inquisition which means that I have to obey you while you are on assignment but you are making an enemy here.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_4c90f2a4", "interview_b693b85f"}, -- Is that a threat? I suggest you just answer my questions.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3b0eba1c)

barlow_convo_interview_a82360e0 = ConvoScreen:new {
	id = "interview_a82360e0",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a82360e0", -- Fine, fine. Ask me anything. What would you like to know?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_883e63f3", "interview_ffee58bf"}, -- Who were these friends of Colonel Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_a82360e0)

barlow_convo_interview_379b50a7 = ConvoScreen:new {
	id = "interview_379b50a7",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_379b50a7", -- No! As I said before, I don't think that officers should get too friendly with each other. Also since I was second in command I had to stay here when Colonel Hend went on leave. It might have been nice to receive an invitation but I completely understand.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_7b1ee2bd", "interview_9ce47b1f"}, -- It's okay. Just let it out.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_379b50a7)

barlow_convo_interview_ecda4c4f = ConvoScreen:new {
	id = "interview_ecda4c4f",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_ecda4c4f", -- How would I know? I never asked and they never volunteered any details. All I know is that they would leave for a few days and then come back. To my understanding they filed all the appropriate transportation paperwork so it was never an issue with me.
	animation = "shrug_shoulders",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_c37cc43f", "interview_1dfabdd9"}, -- Who else did Colonel Hend go on trips with?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_ecda4c4f)

barlow_convo_interview_1ae1c792 = ConvoScreen:new {
	id = "interview_1ae1c792",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_1ae1c792", -- Hmmm...
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_b72bfe9c", "interview_ffee58bf"}, -- You say that Colonel Hend had lots of friends. Tell me about them.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_1ae1c792)

barlow_convo_interview_2188ff96 = ConvoScreen:new {
	id = "interview_2188ff96",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_2188ff96", -- First I would have arrested him and then made my report according to Imperial directive J323-9V. I wish I had known, so I could have put an end to it. It makes me sick to know that I served under a traitor.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_61c6827c", "interview_c39786e7"}, -- Wouldn't arresting a superior officer violate Imperial directive T44A-0-niner?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_2188ff96)

barlow_convo_interview_e0659186 = ConvoScreen:new {
	id = "interview_e0659186",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_e0659186", -- Like I said, I do my job so well there is no need. Doctor Shinss doesn't have to worry about a thing now that I am charge.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_1b131a47", "end_7ebbd888"}, -- I am sure that he doesn't worry about you. I must be going.
		{"@conversation/naboo_imperial_tier3_barlow:s_ea32ea5a", "end_2b71207d"}, -- Thank you for your time. I see no need to continue this conversation.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_e0659186)

barlow_convo_end_2b71207d = ConvoScreen:new {
	id = "end_2b71207d",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_2b71207d", -- Uh...whatever you wish, Inquisitor. I hope that you have gotten the answers you were looking for, although I don't see how. Good day.
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_end_2b71207d)

barlow_convo_interview_c4c46aa = ConvoScreen:new {
	id = "interview_c4c46aa",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_c4c46aa", -- You are completely mad. From what I heard, you were the one who killed Colonel Hend. In the Dantooine system. Thousands of light years from here. Where I was. It would have been impossible for me to have murdered Colonel Hend!
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_ea5a649e", "interview_2723a841"}, -- Hmmm. I really thought I was on to something there.
		{"@conversation/naboo_imperial_tier3_barlow:s_283dca97", "interview_ffee58bf"}, -- I believe you colonel. Now about Colonel Hend's friends?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_c4c46aa)

barlow_convo_interview_b693b85f = ConvoScreen:new {
	id = "interview_b693b85f",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_b693b85f", -- Fine. What questions would you like me to answer?
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_883e63f3", "interview_ffee58bf"}, -- Who were these friends of Colonel Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_b693b85f)

barlow_convo_interview_9ce47b1f = ConvoScreen:new {
	id = "interview_9ce47b1f",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_9ce47b1f", -- Let it out? Let what out? Why aren't you asking questions like the other Inquisitor's were doing?
	animation = "gesticulate_wildly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_ffead1ac", "interview_20ff0a31"}, -- Oh, and what sort of questions were those?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_9ce47b1f)

barlow_convo_interview_1dfabdd9 = ConvoScreen:new {
	id = "interview_1dfabdd9",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_1dfabdd9", -- No one. Well, actually he would travel around with Doctor Shinss inspecting the debris fields, but that was official business and not Leave.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_47e55614", "interview_9d22bb03"}, -- So which is it? 'No one' or 'Doctor Shinss'?.
		{"@conversation/naboo_imperial_tier3_barlow:s_cd0207ad", "interview_394ac527"}, -- Who is this Doctor Shinss?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_1dfabdd9)

barlow_convo_end_7ebbd888 = ConvoScreen:new {
	id = "end_7ebbd888",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_7ebbd888", -- Not in the least. I tell you that I am a fine officer and you can quote me on that if you wish. I hope that I have been helpful to your investigation. Good day.
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_end_7ebbd888)

barlow_convo_interview_2723a841 = ConvoScreen:new {
	id = "interview_2723a841",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_2723a841", -- On to what? You accused me of being a traitor, then you accuse me of murdering someone half-way across the galaxy! I try to tell you what I know and you accuse me of having an inappropriate fascination with Colonel Hend! I have no idea what this line of questioning is all about. 
	animation = "gesticulate_wildly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_5c896992", "interview_a253bfbf"}, -- That is because you are not paying attention.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_2723a841)

barlow_convo_interview_20ff0a31 = ConvoScreen:new {
	id = "interview_20ff0a31",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_20ff0a31", -- You know. Things like where were you on date so and so. Did you ever see Colonel Hend do this. Are you loyal to the Empire. Things like that!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_55a16d2b", "interview_f978aafb"}, -- Did you ever see Colonel Hend steal secrets and give them to the Rebellion?
		{"@conversation/naboo_imperial_tier3_barlow:s_2002f393", "interview_ff55610e"}, -- If the other Inquisitors already asked those why do you want to answer them again?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_20ff0a31)

barlow_convo_interview_9d22bb03 = ConvoScreen:new {
	id = "interview_9d22bb03",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_9d22bb03", -- He never went on leave with Doctor Shinss, but they did work together in an official capacity. They would take shuttles out to inspect the debris fields.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_90c2580f", "interview_91237089"}, -- Why are you trying to protect Doctor Shinss?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_9d22bb03)

barlow_convo_interview_394ac527 = ConvoScreen:new {
	id = "interview_394ac527",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_394ac527", -- Doctor Shinss is head of the salvage operation. He and his team of engineers are locating and extracting the most important pieces from the debris in order to be reused in other projects. He worked closely with Colonel Hend to ensure the safety of all involved.
	animation = "point_left",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_749aece", "interview_eb02637b"}, -- So I take it you are working closely with Doctor Shinss now as well.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_394ac527)

barlow_convo_interview_a253bfbf = ConvoScreen:new {
	id = "interview_a253bfbf",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a253bfbf", -- You are insane.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_72ceec2c", "interview_ffee58bf"}, -- Do not question my methods! Tell me about Colonel Hends friends.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_a253bfbf)

barlow_convo_interview_f978aafb = ConvoScreen:new {
	id = "interview_f978aafb",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_f978aafb", -- Argh! If I would have seen him doing that I would have arrested him and turned him over to the Inquisition. What kind of dumb question is that?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_b83437a1", "interview_3cdbed0b"}, -- You were the one telling me to ask you about it.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_f978aafb)

barlow_convo_interview_ff55610e = ConvoScreen:new {
	id = "interview_ff55610e",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_ff55610e", -- I don't want to answer them again! Don't you even know what I told the other Inquisitors when they last questioned me? Why are you even here?
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_59904aa4", "interview_3cdbed0b_b"}, -- My mission is a mystery that will reveal itself in time.
		{"@conversation/naboo_imperial_tier3_barlow:s_58079535", "interview_a3391195"}, -- Maybe you would be more comfortable if you pour us both a drink.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_ff55610e)

barlow_convo_interview_91237089 = ConvoScreen:new {
	id = "interview_91237089",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_91237089", -- What do you mean, trying to protect Doctor Shinss? I am not protecting anyone. He and Colonel Hend worked together. As head of the project and head of security they spent a lot of time in meetings planning for the project.
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_749aece", "interview_eb02637b"}, -- So I take it you are working closely with Doctor Shinss now as well.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_91237089)

barlow_convo_interview_eb02637b = ConvoScreen:new {
	id = "interview_eb02637b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_eb02637b", -- Well, I have not yet had a chance to meet with Doctor Shinss. But that doesn't mean I do not know what my duties are on this project. I understand completely what it is that needs to get done. Doctor Shinss has no reason to worry about the security of this project with me in command.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_2e851dd5", "end_65ec117a"}, -- Silence fool! I am tired of listening to you. Good day.
		{"@conversation/naboo_imperial_tier3_barlow:s_c346ae59", "end_3be36a24"}, -- You really do not have a clue do you? I am finished here. Good day.
		{"@conversation/naboo_imperial_tier3_barlow:s_110ac144", "end_4ccd5b75"}, -- Thank you for your time, Colonel. There will be no need for us to speak again.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_eb02637b)

barlow_convo_interview_3cdbed0b = ConvoScreen:new {
	id = "interview_3cdbed0b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3cdbed0b", -- This is getting nowhere. I am going to have to end this interview right now unless you get to the point. Inquisition or no, I am very busy man and do not have time to waste answering fool questions.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_c2631c46", "interview_45363db1"}, -- Tell me some more about the people Colonel Hend dealt with.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3cdbed0b)

barlow_convo_interview_3cdbed0b_b = ConvoScreen:new {
	id = "interview_3cdbed0b_b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3cdbed0b", -- This is getting nowhere. I am going to have to end this interview right now unless you get to the point. Inquisition or no, I am very busy man and do not have time to waste answering fool questions.
	animation = "check_wrist_device",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_c2631c46", "interview_45363db1"}, -- Tell me some more about the people Colonel Hend dealt with.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3cdbed0b_b)

barlow_convo_interview_a3391195 = ConvoScreen:new {
	id = "interview_a3391195",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a3391195", -- I most certainly am not going to pour us both a drink. I am on duty and so are you. Imperial directive 43C-90L clearly states that the consumption of spirits while on duty is punishable by two weeks in the brig.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_cfd0827b", "interview_3cdbed0b_b"}, -- You really like quoting Imperial directives, don't you?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_a3391195)

barlow_convo_end_65ec117a = ConvoScreen:new {
	id = "end_65ec117a",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_65ec117a", -- Good! Now I can get back to work.
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_end_65ec117a)

barlow_convo_end_3be36a24 = ConvoScreen:new {
	id = "end_3be36a24",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3be36a24", -- What do you mean I don't have a clue? You were the one asking all of those crazy questions. Bah, fine! I have work to do anyway.
	animation = "point_accusingly",
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_end_3be36a24)

barlow_convo_end_4ccd5b75 = ConvoScreen:new {
	id = "end_4ccd5b75",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_4ccd5b75", -- I certainly hope not. I will still be required to speak with Inquisitor Vrke about your behavior. It was completely unacceptable.
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_end_4ccd5b75)

barlow_convo_interview_45363db1 = ConvoScreen:new {
	id = "interview_45363db1",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_45363db1", -- There was the group of junior officers, mostly members of the security force, although there were some Naval men in that group as well. Of course, he had dealing with the engineers handling the salvage operation. I never saw him with any of the enlisted men or civilians. In fact I don't think I ever even heard of him talking to any of them. When he had to deal with any of the men, he would always delegate that to another officer.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d1511c14", "interview_dd34119b"}, -- So, Colonel Hend hated the enlisted men.
		{"@conversation/naboo_imperial_tier3_barlow:s_8931a146", "interview_62784e3f"}, -- What would he do with the engineers?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_45363db1)

barlow_convo_interview_dd34119b = ConvoScreen:new {
	id = "interview_dd34119b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_dd34119b", -- I don't know. He just never dealt with any of them. From what I understand he wasn't like that before I arrived. I have heard he used to be really friendly with the men but about three or four months before I arrived he just suddenly stopped dealing with any of them.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_51df4407", "interview_cb65c4f9"}, -- Classic sign of betrayal. Those most hurt by his treason would be the men in the trenches.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_dd34119b)

barlow_convo_interview_62784e3f = ConvoScreen:new {
	id = "interview_62784e3f",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_62784e3f", -- He was head of security on an operation that was being run by the engineers. He dealt with them everyday but I wouldn't say that he ever did anything with any of them. 
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_9cb92ec3", "interview_6a726863"}, -- So these engineers would know how the Death Star worked?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_62784e3f)

barlow_convo_interview_cb65c4f9 = ConvoScreen:new {
	id = "interview_cb65c4f9",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_cb65c4f9", -- I suppose that could have been the case. I really do not like to speculate about things like that. Is there anything else you wanted to know?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_540a88a5", "interview_a43281d6"}, -- As a matter of fact. Yes! What engineers?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_cb65c4f9)

barlow_convo_interview_6a726863 = ConvoScreen:new {
	id = "interview_6a726863",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_6a726863", -- Of course they would know. Many of them helped build the station. That is another reason why security is so tight on this operation. We cannot allow any of these scientists to fall into enemy hands. The knowledge they possess is of great importance to the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_7324835", "interview_3c673988"}, -- That is most interesting. And by enemy you mean the Rebellion?
		{"@conversation/naboo_imperial_tier3_barlow:s_e6f64e19", "interview_f6fe3ce5"}, -- Do any of these engineers have higher security clearance than Colonel Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_6a726863)

barlow_convo_interview_a43281d6 = ConvoScreen:new {
	id = "interview_a43281d6",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_a43281d6", -- What engineers? The ones that are running the salvage operation in this system? They are the whole reason that any of us are here. The engineers are locating and extracting the most important pieces from the debris in order to be reused in other projects.
	animation = "sigh_deeply",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_9cb92ec3", "interview_6a726863"}, -- So these engineers would know how the Death Star worked?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_a43281d6)

barlow_convo_interview_3c673988 = ConvoScreen:new {
	id = "interview_3c673988",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_3c673988", -- Uh...yes of course. Who did you think I meant?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_b969a839", "interview_85e6fdd1"}, -- That's not important right now. What is important are these engineers.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_3c673988)

barlow_convo_interview_f6fe3ce5 = ConvoScreen:new {
	id = "interview_f6fe3ce5",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_f6fe3ce5", -- Several of them do. Doctor Verr, Doctor Plenki, Doctor Shinss, and Doctor Stile all do. Even though Colonel Hend was in charge of security, there are a number of things going on here that it was not necessary for him to know about.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_9bdca9f6", "interview_900f01d1"}, -- Do you know what goes on here?
		{"@conversation/naboo_imperial_tier3_barlow:s_18782a4b", "interview_6773e97b"}, -- Of these engineers who had the most contact with Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_f6fe3ce5)

barlow_convo_interview_85e6fdd1 = ConvoScreen:new {
	id = "interview_85e6fdd1",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_85e6fdd1", -- What else do you want to know about them?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_e6f64e19", "interview_f6fe3ce5"}, -- Do any of these engineers have higher security clearance than Colonel Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_85e6fdd1)

barlow_convo_interview_900f01d1 = ConvoScreen:new {
	id = "interview_900f01d1",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_900f01d1", -- What?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_d1dc8a70", "interview_1a949924"}, -- Aren't you head of security on this project now?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_900f01d1)

barlow_convo_interview_6773e97b = ConvoScreen:new {
	id = "interview_6773e97b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_6773e97b", -- That would definitely be Doctor Shinss. He is head of the project so naturally spent the most time with Colonel Hend.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_107a83ec", "interview_7061349d"}, -- Did the two of them ever spend any time alone together?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_6773e97b)

barlow_convo_interview_1a949924 = ConvoScreen:new {
	id = "interview_1a949924",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_1a949924", -- Yes, I was promoted after Colonel Hend's death.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_57cfb6a7", "interview_12173b9e"}, -- You said your last statement like you don't know what is going on.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_1a949924)

barlow_convo_interview_7061349d = ConvoScreen:new {
	id = "interview_7061349d",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_7061349d", -- Of course they did. They were in quite a few private meetings together, almost daily. They would take shuttles out to inspect the debris field together quite often. Nothing out of the ordinary.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_5ffde8db", "interview_2a60fbf6"}, -- So Colonel Hend spent time alone with the other engineers?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_7061349d)

barlow_convo_interview_12173b9e = ConvoScreen:new {
	id = "interview_12173b9e",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_12173b9e", -- Of course I don't know what is going on around here. My security clearance is the same as Colonel Hend's was. So how could I know?
	animation = "standing_placate",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_becaf709", "interview_6c17ce1b"}, -- Just as I suspected. You are innocent.
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_12173b9e)

barlow_convo_interview_2a60fbf6 = ConvoScreen:new {
	id = "interview_2a60fbf6",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_2a60fbf6", -- Not that I ever saw. But Doctor Shinss was project lead. It was necessary for him to deal with Colonel Hend in order to organize security.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_30a96327", "interview_eb02637b"}, -- Really? How many times have you had private meetings with Doctor Shinss?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_2a60fbf6)

barlow_convo_interview_6c17ce1b = ConvoScreen:new {
	id = "interview_6c17ce1b",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_6c17ce1b", -- I thought we had already determined that I had nothing to do with Colonel Hend being a traitor. I know that has to look bad for a second not to be aware of his commanders activities but that is the truth. I have nothing to hide from the Inquisition.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_imperial_tier3_barlow:s_7ed6dd6", "interview_6773e97b"}, -- Who amongst those engineers had the most contact with Hend?
	}
}
barlow_convo_template:addScreen(barlow_convo_interview_6c17ce1b)

barlow_convo_already_spoke = ConvoScreen:new {
	id = "already_spoke",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_f813490a", -- You again? I don't know anything else. I have already told you everything that I know. Now please, let me continue my duties in peace.
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_already_spoke)

barlow_convo_not_requested = ConvoScreen:new {
	id = "not_requested",
	leftDialog = "@conversation/naboo_imperial_tier3_barlow:s_4355764f", -- I do not recall requesting your presence? If you have no business here I highly suggest that you get back to your unit or where ever you came from.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
barlow_convo_template:addScreen(barlow_convo_not_requested)

addConversationTemplate("barlow_convo_template", barlow_convo_template)
