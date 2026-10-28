-- Grand Admiral Nial Declann (Imperial master trainer) conversation; ported from SWG-Source imperial_master_trainer.java with the pre-NGE client lines (feature space-master-trainer-imperial). Handler: nialDeclannConvoHandler.
nial_declann_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "nialDeclannConvoHandler",
	screens = {}
}

nial_declann_convo_default = ConvoScreen:new {
	id = "default",
	leftDialog = "@conversation/imperial_master_trainer:s_104cc43b", -- How dare you approach me. Where are my bodyguards? I will have them flogged for failure in their duties. I suggest that you get out of my sight before I decide that you are a threat rather than an annoyance.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_default)

nial_declann_convo_working_for_rebellion = ConvoScreen:new {
	id = "working_for_rebellion",
	leftDialog = "@conversation/imperial_master_trainer:s_ad4fc220", -- Dog! How dare you get this close to me. I will have my security detail flogged for this transgression. Get out of my sight before you suffer a similar fate.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_working_for_rebellion)

nial_declann_convo_rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/imperial_master_trainer:s_452c0be9", -- How did one such as you get this close to me? I will have my bodyguards heads for this. Get your traitorous self from my presence before I decide to sully my hands and terminate you myself.
	stopConversation = "true",
	animation = "threaten",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_rebel_pilot)

nial_declann_convo_smuggler = ConvoScreen:new {
	id = "smuggler",
	leftDialog = "@conversation/imperial_master_trainer:s_da529897", -- How dare you speak with me. Don't you have any idea of who I am? Go back to your grubby little hole and be thankful I don't have you put to death for this outrage.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_smuggler)

nial_declann_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/imperial_master_trainer:s_a4bdc579", -- Pilot, what is the meaning of this? If I wish to speak to you I will have your superior officer inform you. Until that time I expect you to act with the appropriateness of a member of the Imperial Navy and only speak to your betters when spoken to.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_f2aa6939", "not_ready_sorry"}, -- Sorry, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_not_ready)

nial_declann_convo_not_ready_sorry = ConvoScreen:new {
	id = "not_ready_sorry",
	leftDialog = "@conversation/imperial_master_trainer:s_46a8c207", -- Did I ask for an apology? Get out of my sight before I decide to have you brought up on insubordination charges.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_not_ready_sorry)

nial_declann_convo_privateer_not_ready = ConvoScreen:new {
	id = "privateer_not_ready",
	leftDialog = "@conversation/imperial_master_trainer:s_cd392cb5", -- Why would you assume that I wish to talk to you? Did I order your presence? Do I look like I wanted to speak with you? When and if I wish to speak to you I am sure you will be informed by your superior. Now get out of my sight before I begin to care that you are bothering me.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_privateer_not_ready)

nial_declann_convo_other_master = ConvoScreen:new {
	id = "other_master",
	leftDialog = "@conversation/imperial_master_trainer:s_73ed2b9a", -- Pilot, you have performed my brilliant plan to cripple the Rebellion in the Kessel system with competence,  but that does not give you reign to disturb me any time you please. Do not make the mistake of trying my patience simply because I lent you a kind word in the past.
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_other_master)

nial_declann_convo_master_done = ConvoScreen:new {
	id = "master_done",
	leftDialog = "@conversation/imperial_master_trainer:s_80cfab4c", -- Pilot, you have performed my brilliant plan to cripple the Rebellion in the Kessel system with competence. And I believe that you have the makings of a fine Imperial Naval Officer, but that does not give you reign to disturb me any time you please. Do not make the mistake of trying my patience simply because I lent you a kind word in the past.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_master_done)

nial_declann_convo_on_master_mission = ConvoScreen:new {
	id = "on_master_mission",
	leftDialog = "@conversation/imperial_master_trainer:s_faa7bc59", -- What are you doing back here? I explained what you need to do in full detail and I expect you to do it. This mission will not fail because of your incompetence. Get back to the Kessel system and finish the job.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_on_master_mission)

nial_declann_convo_on_quest = ConvoScreen:new {
	id = "on_quest",
	leftDialog = "@conversation/imperial_master_trainer:s_4f462e49", -- You seem distracted.  Perhaps there is somewhere else you are supposed to be, and something else you are supposed to be doing.  Wrap it up, and I mean NOW.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_on_quest)

nial_declann_convo_privateer_ready = ConvoScreen:new {
	id = "privateer_ready",
	leftDialog = "@conversation/imperial_master_trainer:s_10009b23", -- Yes, what is it? Speak up, I don't have all day to chat with you.
	stopConversation = "true",
	animation = "beckon",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_privateer_ready)

nial_declann_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/imperial_master_trainer:s_5c54d077", -- You have disappointed me. Your former superiors spoke so highly of you that I assumed you were skilled enough to handle the important task that I gave to you. Perhaps they need me to teach them how to pick a good pilot from an incompetent buffoon.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/imperial_master_trainer:s_21a81b0b", "m2_failed_loyalty"}, -- There is no need for that, sir.
		{"@conversation/imperial_master_trainer:s_eb02d65", "m2_failed_skills"}, -- I am a good pilot, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_failed)

nial_declann_convo_m2_failed_loyalty = ConvoScreen:new {
	id = "m2_failed_loyalty",
	leftDialog = "@conversation/imperial_master_trainer:s_9f12075", -- So you show some loyalty to those who have supported you. Loyalty is a good trait to have for a soldier, as long as you do not misplace that loyalty. I demand that you show loyalty to me and do what I have asked you to accomplish.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/imperial_master_trainer:s_bb68f6ed", "m2_retry_a"}, -- I will not fail again, sir.
		{"@conversation/imperial_master_trainer:s_e6cf6a6f", "m2_failed_quit"}, -- I cannot do this
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_failed_loyalty)

nial_declann_convo_m2_retry_a = ConvoScreen:new {
	id = "m2_retry_a",
	leftDialog = "@conversation/imperial_master_trainer:s_37e6fdef", -- The Rebels are still using their corvettes to patrol the Kessel system with regularity. Against my better judgment, I am going to give you another chance to prove yourself worthy to wear the uniform of an Imperial Navy Flight Officer. Get to your ship and destroy the Rebel corvette patrolling the Kessel system.
	stopConversation = "false",
	animation = "point_up",
	options = {
		{"@conversation/imperial_master_trainer:s_4effeedc", "m2_retry_a_end"}, -- Yes, sir! Thank you, sir!
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_retry_a)

nial_declann_convo_m2_retry_a_end = ConvoScreen:new {
	id = "m2_retry_a_end",
	leftDialog = "@conversation/imperial_master_trainer:s_7245a3eb", -- Are you still here? On the double trooper.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_retry_a_end)

nial_declann_convo_m2_failed_quit = ConvoScreen:new {
	id = "m2_failed_quit",
	leftDialog = "@conversation/imperial_master_trainer:s_7d404504", -- Pathetic.
	stopConversation = "true",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_failed_quit)

nial_declann_convo_m2_failed_skills = ConvoScreen:new {
	id = "m2_failed_skills",
	leftDialog = "@conversation/imperial_master_trainer:s_2881a66c", -- You certainly have an interesting way of showing your skills then, pilot. Normally when someone is good at something they accomplish any tasks involved.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/imperial_master_trainer:s_c13f9a11", "m2_retry_b"}, -- I am sorry, sir. Give me another chance. I will succeed.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_failed_skills)

nial_declann_convo_m2_retry_b = ConvoScreen:new {
	id = "m2_retry_b",
	leftDialog = "@conversation/imperial_master_trainer:s_18cbe5e7", -- To show you that I am a forgiving man, I accept your apology. And I will also give you another chance to destroy the Rebel corvette that is regularly patrolling the Kessel system. For your sake, do not fail me again. Are we understood?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_b6b25f13", "m2_retry_b_end"}, -- Yes, sir!
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_retry_b)

nial_declann_convo_m2_retry_b_end = ConvoScreen:new {
	id = "m2_retry_b_end",
	leftDialog = "@conversation/imperial_master_trainer:s_3924b90e", -- Good. Now get to your ship before I change my mind.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_retry_b_end)

nial_declann_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/imperial_master_trainer:s_15cded59", -- Did I not make myself clear to what your assignment was? Because it certainly had nothing to do with failure! You were supposed to strike the Rebel forces in Kessel and cripple their ability to control that system. Instead you come back with your tail between your legs.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/imperial_master_trainer:s_fc42e227", "m1_failed_sorry"}, -- I am sorry, sir. Give me another chance. I will not let you down.
		{"@conversation/imperial_master_trainer:s_a460d610", "m1_failed_stronger"}, -- Sir, the Rebels were stronger than initially reported.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_failed)

nial_declann_convo_m1_failed_sorry = ConvoScreen:new {
	id = "m1_failed_sorry",
	leftDialog = "@conversation/imperial_master_trainer:s_c4069644", -- Let me make one thing clear. I do not care about your career. I do not care about your goals. I do not care about you. I only care about results. If you are unable to give me results then you will find out what it is to cross a Grand Admiral.
	stopConversation = "false",
	animation = "threaten",
	options = {
		{"@conversation/imperial_master_trainer:s_862d3332", "m1_retry_a"}, -- I will give you results, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_failed_sorry)

nial_declann_convo_m1_retry_a = ConvoScreen:new {
	id = "m1_retry_a",
	leftDialog = "@conversation/imperial_master_trainer:s_cb5e0360", -- That is what I expect. I will give you another chance at attacking the Rebel positions in Kessel. Launch the attack immediately on the Rebel positions and cripple their ability to hold that system.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_59047203", "m1_retry_a_end"}, -- Yes, sir! Right away, sir!
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_retry_a)

nial_declann_convo_m1_retry_a_end = ConvoScreen:new {
	id = "m1_retry_a_end",
	leftDialog = "@conversation/imperial_master_trainer:s_e1e9b306", -- You are dismissed, pilot. Move it before I change my mind and have you flying patrols in the Dagobah system for the rest of your career.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_retry_a_end)

nial_declann_convo_m1_failed_stronger = ConvoScreen:new {
	id = "m1_failed_stronger",
	leftDialog = "@conversation/imperial_master_trainer:s_74926dbb", -- Are you saying that I was wrong in my assessment of the Rebel strength in the Kessel system?
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/imperial_master_trainer:s_c788dadf", "m1_retry_b"}, -- No, sir. Of course not, sir.
		{"@conversation/imperial_master_trainer:s_34ac7172", "m1_failed_quit"}, -- This is too hard for me
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_failed_stronger)

nial_declann_convo_m1_retry_b = ConvoScreen:new {
	id = "m1_retry_b",
	leftDialog = "@conversation/imperial_master_trainer:s_275d33d7", -- Listen to me closely because you are walking on some very thin ice right now, Pilot. You are to return to the Kessel system and destroy the Rebel positions. My plan will not fail because of the incompetence of a lowly pilot such as yourself. Are we clear?
	stopConversation = "false",
	animation = "whisper",
	options = {
		{"@conversation/imperial_master_trainer:s_87d4bfc2", "m1_retry_b_clear"}, -- Crystal.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_retry_b)

nial_declann_convo_m1_retry_b_clear = ConvoScreen:new {
	id = "m1_retry_b_clear",
	leftDialog = "@conversation/imperial_master_trainer:s_1ffdcc4b", -- Are we clear?
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_f799f9ec", "m1_retry_b_end"}, -- Perfectly clear, sir!
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_retry_b_clear)

nial_declann_convo_m1_retry_b_end = ConvoScreen:new {
	id = "m1_retry_b_end",
	leftDialog = "@conversation/imperial_master_trainer:s_1ebf705e", -- Good, now get to your ship and take out those Rebel positions in Kessel.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_retry_b_end)

nial_declann_convo_m1_failed_quit = ConvoScreen:new {
	id = "m1_failed_quit",
	leftDialog = "@conversation/imperial_master_trainer:s_3eccac5", -- Then we have nothing else to talk about.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_failed_quit)

nial_declann_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/imperial_master_trainer:s_38294227", -- Make your report, pilot.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_f010d9ab", "m2_report"}, -- [relay the destruction of the Rebel Corellia Corvette]
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_won)

nial_declann_convo_m2_report = ConvoScreen:new {
	id = "m2_report",
	leftDialog = "@conversation/imperial_master_trainer:s_825762e5", -- Excellent, then my plan worked to perfection. I cannot wait to see the smug expression on Grant's face drop when he hears of my success. Should I open or close with this success in my report to the Emperor? Hmmm, oh are you still here?
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/imperial_master_trainer:s_2f52e0af", "m2_not_dismissed"}, -- I haven't been dismissed yet, sir.
		{"@conversation/imperial_master_trainer:s_6aa8adaf", "m2_hoping"}, -- I was hoping for a reward of sorts, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_report)

nial_declann_convo_m2_not_dismissed = ConvoScreen:new {
	id = "m2_not_dismissed",
	leftDialog = "@conversation/imperial_master_trainer:s_a8fd6791", -- Of course, you haven't. You have performed excellently for me and I always reward those who serve me. You have proven yourself a very valuable asset to the Empire and more importantly you have proven yourself to me.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_beb9353a", "master_grant"}, -- I do my best, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_not_dismissed)

nial_declann_convo_m2_hoping = ConvoScreen:new {
	id = "m2_hoping",
	leftDialog = "@conversation/imperial_master_trainer:s_4008a214", -- I am willing to overlook your impertinence for your success in this difficult endeavor. But make no mistake, I will not overlook any lack of respect towards me, regardless of any deed that you might have performed for me in the past.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_6a66a025", "m2_rewarded"}, -- Sorry, sir. I didn't mean to speak out of turn.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_hoping)

nial_declann_convo_m2_rewarded = ConvoScreen:new {
	id = "m2_rewarded",
	leftDialog = "@conversation/imperial_master_trainer:s_14fd07f0", -- Very well, pilot. You are correct in the assumption that you will be rewarded for your small part in making my plan a success.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_377d1a96", "master_grant"}, -- Thank you, sir. It has been an honor to be allowed to serve under you.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_rewarded)

nial_declann_convo_master_grant = ConvoScreen:new {
	id = "master_grant",
	leftDialog = "@conversation/imperial_master_trainer:s_c6be1c53", -- Your accomplishments have proven that you are a valued asset to the Empire and a truly exceptional pilot. I believe that you have achieved the highest level of piloting skill that anyone can possess. I have also decided that a payment bonus should be transferred to your account as a show of my personal gratitude. And, most importantly, I have decided to mention your name to the Emperor, in passing of course, but still the greatest of honors.
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/imperial_master_trainer:s_a1669dff", "master_end"}, -- You honor me too much. Thank you, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_master_grant)

nial_declann_convo_master_end = ConvoScreen:new {
	id = "master_end",
	leftDialog = "@conversation/imperial_master_trainer:s_6276e267", -- Yes, maybe you are right. It might not be wise for me to mention you to the Emperor. Others might try to have you transferred under their command. Oh, you are still here. Dismissed, Pilot!
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_master_end)

nial_declann_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/imperial_master_trainer:s_6e1047cb", -- So you have managed to dilute the Rebel influence on the Kessel system. That is good. It is good to see that you were able to follow simple orders and allow my genius planning to do it's work.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_b8ead210", "m1_perfection"}, -- Yes, sir. Your plan worked to perfection. The Rebellion didn't know what hit them.
		{"@conversation/imperial_master_trainer:s_3876be4f", "m1_improvise"}, -- Sir, I beg to differ but I had to improvise quite a bit out there to succeed.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_won)

nial_declann_convo_m1_perfection = ConvoScreen:new {
	id = "m1_perfection",
	leftDialog = "@conversation/imperial_master_trainer:s_fdd6a0a8", -- The Rebels are fools. They will be crushed shortly, of that I have no doubt. But I have never been one to overlook the value of a good pilot. I am beginning to see what your other superiors saw in you.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/imperial_master_trainer:s_3ffe1ded", "m1_modest"}, -- Thank you, sir. I simply do my best to serve the Empire.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_perfection)

nial_declann_convo_m1_modest = ConvoScreen:new {
	id = "m1_modest",
	leftDialog = "@conversation/imperial_master_trainer:s_3cbc1b19", -- There is no need to be modest. You have the makings of one of the finest pilots I have ever seen. Of course, all the skill in the world is meaningless without proper planning and careful guidance,
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/imperial_master_trainer:s_a8ea09e9", "m1_reward"}, -- You are absolutely correct, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_modest)

nial_declann_convo_m1_improvise = ConvoScreen:new {
	id = "m1_improvise",
	leftDialog = "@conversation/imperial_master_trainer:s_966bc725", -- What! Are you questioning the plan that I gave to you? Improvisation should be left to actors not Imperial Pilots. A good Imperial Pilot obeys orders without question and follows them explicitly. It's a wonder that you even succeeded.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_a8ea09e9", "m1_reward"}, -- You are absolutely correct, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_improvise)

nial_declann_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/imperial_master_trainer:s_fbe23895", -- I have decided that you deserve a small token of my appreciation as a reward for your successful flight. I am going to have some credits transferred to your account so you can take a little rest and relaxation. A rested pilot is a better pilot.
	stopConversation = "false",
	animation = "snap_finger1",
	options = {
		{"@conversation/imperial_master_trainer:s_1affba73", "m1_kind"}, -- The Grand Admiral is too kind.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_reward)

nial_declann_convo_m1_kind = ConvoScreen:new {
	id = "m1_kind",
	leftDialog = "@conversation/imperial_master_trainer:s_79b77be4", -- Yes, I know. One of my character flaws is that I am to kindhearted to the men who serve under me. Regardless, enjoy your extra pay and take some time off. We will have to initiate the second part of my plan before long in order to take advantage of the situation in Kessel.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_cc0857f4", "m1_dismissed"}, -- Second part of your plan?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_kind)

nial_declann_convo_m1_dismissed = ConvoScreen:new {
	id = "m1_dismissed",
	leftDialog = "@conversation/imperial_master_trainer:s_378e9412", -- Didn't I just order you to take some time off? I will explain the second part of my plan to you when I am ready. Pilot if you want to make it very far with me you had better start following orders and stop asking questions that do not concern you. Dismissed!
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_dismissed)

nial_declann_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/imperial_master_trainer:s_b170039f", -- I trust you are well rested and ready to serve me as well as you had before. The time has come for me to unleash the second stage of my plan to take the Kessel system for the glory of the Empire.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_5d519e4c", "m2_strike"}, -- Yes, sir. I am ready.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_brief)

nial_declann_convo_m2_strike = ConvoScreen:new {
	id = "m2_strike",
	leftDialog = "@conversation/imperial_master_trainer:s_671a4e3c", -- Today we are going to launch the definitive strike at the Rebellion battlegroup inside the Kessel system. Part of the battlegroup consists of the support vessels that you attacked so successfully last time, the other is their command vessels. You are going to assault their command vessels and destroy their lead ship.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_77e59fd7", "m2_target"}, -- What is my target ship?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_strike)

nial_declann_convo_m2_target = ConvoScreen:new {
	id = "m2_target",
	leftDialog = "@conversation/imperial_master_trainer:s_92ac32ae", -- The Rebellion has moved a Corellian corvette into the system and are using that vessel as their staging point for all operations that take place inside the system. You are to destroy that vessel. Reports show that the vessel moves throughout several systems, so it may not always be in Kessel. You will have to wait for it to arrive on it's standard patrol through the system before you will be able to strike.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_b41b5772", "m2_star_destroyer"}, -- A Corellian corvette! Wouldn't it be better to send a Star Destroyer after it?
		{"@conversation/imperial_master_trainer:s_6b581019", "m2_unwise"}, -- Sir, I will try my best but isn't it unwise to send fighters against a capital ship?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_target)

nial_declann_convo_m2_star_destroyer = ConvoScreen:new {
	id = "m2_star_destroyer",
	leftDialog = "@conversation/imperial_master_trainer:s_43904a58", -- You are not thinking. Even a corvette, as weak as they are, can cause a large amount of damage to a star destroyer. Star destroyers are not inexpensive pieces of military equipment. I have no intention of sending in one unless there are no other alternatives.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/imperial_master_trainer:s_c7f4c531", "m2_expendable"}, -- So, I am expendable?
		{"@conversation/imperial_master_trainer:s_1980f233", "m2_fiscal"}, -- I understand, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_star_destroyer)

nial_declann_convo_m2_unwise = ConvoScreen:new {
	id = "m2_unwise",
	leftDialog = "@conversation/imperial_master_trainer:s_582dc96a", -- It is hardly uncommon for fighters to take down capital ships the size of a corvette. Granted they usually have the support of star destroyers but in this case I have full confidence in your abilities.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/imperial_master_trainer:s_f2ba71dd", "m2_accept"}, -- Sir, will I be supplied support?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_unwise)

nial_declann_convo_m2_expendable = ConvoScreen:new {
	id = "m2_expendable",
	leftDialog = "@conversation/imperial_master_trainer:s_9a3f8378", -- You are a pilot in the Imperial Navy. It is your duty to fight when, where, and what I tell you to fight. We all pay the costs for the conflict that the Rebels have brought on us. It is my lot to give the orders and it is your lot to obey and if necessary to die for those orders. You should not envy my position, for heavy is the crown of command.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_f2ba71dd", "m2_accept"}, -- Sir, will I be supplied support?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_expendable)

nial_declann_convo_m2_fiscal = ConvoScreen:new {
	id = "m2_fiscal",
	leftDialog = "@conversation/imperial_master_trainer:s_cb793d1b", -- It is good to see that you are someone who understands the fiscal responsibility that I am in. If I can give the Emperor the Outer Rim for minimal costs it will reflect very well on me.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_f2ba71dd", "m2_accept"}, -- Sir, will I be supplied support?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_fiscal)

nial_declann_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/imperial_master_trainer:s_58e29478", -- This is called delegation of responsibility. I am giving you the job to destroy the Rebel command vessel. How you accomplish that task is up to you. I would suggest that you assemble a strike team of fighter pilots in order to assist you with the assault. I cannot be bothered with the details.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/imperial_master_trainer:s_cd48bb84", "m2_accept_end"}, -- Yes, sir. I will put together my team and assault the vessel.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_accept)

nial_declann_convo_m2_accept_end = ConvoScreen:new {
	id = "m2_accept_end",
	leftDialog = "@conversation/imperial_master_trainer:s_88742275", -- See that you do. Once the Empire has Kessel under it's control the rest of the Outer Rim will fall into line without much of a struggle. With my great victory, I will personally hand the Emperor a prize that he has longed for, the Outer Rim.
	stopConversation = "true",
	animation = "applause_polite",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m2_accept_end)

nial_declann_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/imperial_master_trainer:s_b00fab2", -- Ah, yes. You are that bright, young pilot I have been hearing so much about. %NU, isn't it? That's okay, it really doesn't matter. You are probably wondering why a Grand Admiral wishes to see you.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_47acafeb", "intro_permission"}, -- The thought had crossed my mind.
		{"@conversation/imperial_master_trainer:s_6b18cf1e", "intro_punctual"}, -- Reporting as ordered, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro)

nial_declann_convo_intro_permission = ConvoScreen:new {
	id = "intro_permission",
	leftDialog = "@conversation/imperial_master_trainer:s_fa54959d", -- Were you given permission to speak freely? If discipline in the ranks of the Imperial Navy has broken down so badly I can make sure that it is restored. If it wasn't for your exceptional service record I might consider having you shipped off to some backwater world for the rest of your career.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_c788dadf", "intro_record"}, -- No, sir. Of course not, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro_permission)

nial_declann_convo_intro_punctual = ConvoScreen:new {
	id = "intro_punctual",
	leftDialog = "@conversation/imperial_master_trainer:s_80f7c402", -- It is about time you showed up. I was beginning to wonder if punctuality was a lost disciple in the Imperial Navy. At least you have enough sense to speak with respect to your betters. The last pilot who was in here and spoke to me out of turn is now servicing garbage scowls on Bespin.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_26c66fd1", "intro_record"}, -- It won't happen again, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro_punctual)

nial_declann_convo_intro_record = ConvoScreen:new {
	id = "intro_record",
	leftDialog = "@conversation/imperial_master_trainer:s_9039a33", -- That's better. Now getting back to the matter at hand. After looking over your service record I cannot help but to be impressed. Your record is almost as decorated as mine was at your age. I think that you have the makings of a fine Imperial officer.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_5bed3d33", "intro_hope"}, -- That would be my hope, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro_record)

nial_declann_convo_intro_hope = ConvoScreen:new {
	id = "intro_hope",
	leftDialog = "@conversation/imperial_master_trainer:s_939fa385", -- Well, if you perform the assignment that I have for you with any sort of competence you should go a long way in making that dream come true.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_78edd4f", "kessel_training"}, -- What is the assignment, sir?
		{"@conversation/imperial_master_trainer:s_8dd98074", "intro_best"}, -- I am the very best pilot, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro_hope)

nial_declann_convo_kessel_training = ConvoScreen:new {
	id = "kessel_training",
	leftDialog = "@conversation/imperial_master_trainer:s_842637c2", -- I trust you learned about the Kessel system in your naval flight training, so there shouldn't be any need to go into that.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/imperial_master_trainer:s_a4b7535d", "no_training"}, -- I never went through naval flight training, sir.
		{"@conversation/imperial_master_trainer:s_98790879", "kessel_value"}, -- Yes, I know all about Kessel, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_kessel_training)

nial_declann_convo_intro_best = ConvoScreen:new {
	id = "intro_best",
	leftDialog = "@conversation/imperial_master_trainer:s_6b3904f8", -- It remains to be seen if you are worthy of your glowing service record. I am not one of those men who believe everything that they read. My judgment on your prowess is far more keen than any of the commanders that you flew for in the past, I can assure you of that.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_78edd4f", "kessel_training"}, -- What is the assignment, sir?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_intro_best)

nial_declann_convo_no_training = ConvoScreen:new {
	id = "no_training",
	leftDialog = "@conversation/imperial_master_trainer:s_3eb86cb5", -- Remarkable. I am surprised that anyone who didn't go through flight training could rise through the ranks so quickly. Hmm...very interesting. I sense something in you that...never mind, I am just rambling.
	stopConversation = "false",
	animation = "nervous",
	options = {
		{"@conversation/imperial_master_trainer:s_4a7e1397", "kessel_located"}, -- Forgotten, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_no_training)

nial_declann_convo_kessel_value = ConvoScreen:new {
	id = "kessel_value",
	leftDialog = "@conversation/imperial_master_trainer:s_a2a4d2a", -- Then you are well aware of Kessel's strategic value. With Kessel under our control, the Empire will be able to quickly bring order to the Outer Rim and maintain dominance throughout the region.
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/imperial_master_trainer:s_a3bdfc08", "grand_admiral"}, -- I think that you are over estimating the value of the Kessel system.
		{"@conversation/imperial_master_trainer:s_19377f3b", "battlegroup"}, -- That would be my assessment as well, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_kessel_value)

nial_declann_convo_kessel_located = ConvoScreen:new {
	id = "kessel_located",
	leftDialog = "@conversation/imperial_master_trainer:s_a942beda", -- The Kessel system is located deep in the Outer Rim. It has great strategic value due to its close proximity to three other sectors in the Outer Rim, all of which have trade routes cutting through Kessel. If the Empire were able to control Kessel we would have virtual control over every system in the area and be able to quickly bring order to the Outer Rim.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_a3bdfc08", "grand_admiral"}, -- I think that you are over estimating the value of the Kessel system.
		{"@conversation/imperial_master_trainer:s_19377f3b", "battlegroup"}, -- That would be my assessment as well, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_kessel_located)

nial_declann_convo_grand_admiral = ConvoScreen:new {
	id = "grand_admiral",
	leftDialog = "@conversation/imperial_master_trainer:s_a5253219", -- I will remind you that I am a Grand Admiral. I did not gain my rank by over estimating anything. Control of the Kessel system is vital to the Empire's campaign in the Outer Rim. Without it we could be looking at years of chaos among the outer systems.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_1cb9631b", "good_pilot"}, -- I just think that we will be looking at that struggle even with Kessel.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_grand_admiral)

nial_declann_convo_good_pilot = ConvoScreen:new {
	id = "good_pilot",
	leftDialog = "@conversation/imperial_master_trainer:s_5f7103c7", -- You are here because you are a good pilot not because I care about your opinion. Never forget that.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/imperial_master_trainer:s_b6b25f13", "battlegroup_b"}, -- Yes, sir!
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_good_pilot)

nial_declann_convo_battlegroup_b = ConvoScreen:new {
	id = "battlegroup_b",
	leftDialog = "@conversation/imperial_master_trainer:s_2f2ac428", -- The Rebellion apparently has the same idea as we do about the Kessel system. They have already moved part of their fourth battlegroup into the system. Before we are able to take control of that system, that battlegroup will have to be eliminated.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_78d92576", "orders"}, -- What are my orders, sir?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_battlegroup_b)

nial_declann_convo_battlegroup = ConvoScreen:new {
	id = "battlegroup",
	leftDialog = "@conversation/imperial_master_trainer:s_b659975", -- The Rebellion apparently has the same idea as we do about the Kessel system. They have already moved part of their fourth battlegroup into the sector. Before we are able to take control of that system, that battlegroup will have to be eliminated.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_78d92576", "orders"}, -- What are my orders, sir?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_battlegroup)

nial_declann_convo_orders = ConvoScreen:new {
	id = "orders",
	leftDialog = "@conversation/imperial_master_trainer:s_eded2a14", -- My plan involves two steps. The first stage is to reduce the number of support fighters that the Rebels have in the area. I believe that if we can drop those numbers down enough it will be impossible for the Rebels to adequately defend against the second strike. Unfortunately, due to the interference from the Maw, long range scans are virtually useless in Kessel.  You are going to have to hunt the Rebel vessels down.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_cbf5f6bc", "m1_accept"}, -- What is the second strike?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_orders)

nial_declann_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/imperial_master_trainer:s_4f48309f", -- I will explain that to you when the time comes for that attack. The first thing that you need to worry about is reducing the fighters and gunboats in the Kessel system. If you can bring down enough of them, my plan cannot fail and the Empire will be on the verge of victory in the Kessel system.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_e4eceb3e", "m1_accept_end"}, -- I will do my best to destroy the Rebel fighters.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_accept)

nial_declann_convo_m1_accept_end = ConvoScreen:new {
	id = "m1_accept_end",
	leftDialog = "@conversation/imperial_master_trainer:s_36c3870b", -- I have placed my trust in you. Do not fail me. We cannot allow the Rebellion to maintain any sort of control in the system. You have your mission. Dismissed.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_m1_accept_end)

addConversationTemplate("nial_declann_convo_template", nial_declann_convo_template)
