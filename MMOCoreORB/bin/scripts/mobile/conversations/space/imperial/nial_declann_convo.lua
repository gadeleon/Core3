-- Grand Admiral Nial Declann (Imperial master trainer) conversation; ported from SWG-Source imperial_master_trainer.java with the pre-NGE client lines (feature space-master-trainer-imperial). Also the CorSec/RSF privateer branch (priv_* screens, pilot_neutral_master; Smugglers are refused), ported from the same script's isPrivateer arms (feature space-master-trainer-privateer). Handler: nialDeclannConvoHandler.
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

nial_declann_convo_privateer_ready_rsf = ConvoScreen:new {
	id = "privateer_ready_rsf",
	leftDialog = "@conversation/imperial_master_trainer:s_10009b23", -- Yes, what is it? Speak up, I don't have all day to chat with you.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/imperial_master_trainer:s_308a9ab1", "priv_rsf_intro"}, -- I was told by RSF Command to report to you.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_privateer_ready_rsf)

nial_declann_convo_privateer_ready_corsec = ConvoScreen:new {
	id = "privateer_ready_corsec",
	leftDialog = "@conversation/imperial_master_trainer:s_10009b23", -- Yes, what is it? Speak up, I don't have all day to chat with you.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/imperial_master_trainer:s_8409f60e", "priv_corsec_intro"}, -- I was told by Corellia Security Command to report to you.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_privateer_ready_corsec)

nial_declann_convo_priv_rsf_intro = ConvoScreen:new {
	id = "priv_rsf_intro",
	leftDialog = "@conversation/imperial_master_trainer:s_19aeaf5e", -- Ah, so you must be %NU. I have heard a great deal about you from your commanding officers from the RSF. A fine tradition that of the Royal Security Force. Not quite as noble as being a member of the Imperial Navy, but they have been known to make some very fine pilots.
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/imperial_master_trainer:s_7964ad2d", "priv_rsf_treated_well"}, -- Yes, sir. The RSF has treated me very well.
		{"@conversation/imperial_master_trainer:s_6c92dab", "priv_rsf_best"}, -- I must disagree. The RSF has the best pilots in the galaxy.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_intro)

nial_declann_convo_priv_rsf_treated_well = ConvoScreen:new {
	id = "priv_rsf_treated_well",
	leftDialog = "@conversation/imperial_master_trainer:s_63462bcc", -- From what I have heard you are among their best and brightest. Which is good since I have a very important honor to bestow on you. The time has come for you to prove yourself to your Imperial allies. I have an important mission that I believe you are well suited for.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_e9aec8d7", "priv_rsf_question"}, -- A mission? Shouldn't that be handled by the Imperial Navy?
		{"@conversation/imperial_master_trainer:s_bc9b4055", "priv_skilled_pilot"}, -- Yes, sir. It would be an honor, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_treated_well)

nial_declann_convo_priv_rsf_question = ConvoScreen:new {
	id = "priv_rsf_question",
	leftDialog = "@conversation/imperial_master_trainer:s_5fca12da", -- Are you questioning my judgment on this matter? I understand that things are a little less rigid in the RSF, but I would have still expected lesser flight officers not to question their superiors. Perhaps I need to have a word with the Queen about discipline among her troops. I made my decision based off of what is good for the Empire and that is all you need to know about that subject.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_8db79f00", "priv_skilled_pilot"}, -- No, sir. Sorry, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_question)

nial_declann_convo_priv_skilled_pilot = ConvoScreen:new {
	id = "priv_skilled_pilot",
	leftDialog = "@conversation/imperial_master_trainer:s_47cf08a2", -- Yes, I am sure. Since I do not have all day I am going to dispense with further pleasantries. I am in need of a skilled pilot to implement a plan I have devised in order to secure the Kessel system.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_85b8ffbd", "priv_kessel"}, -- The Kessel system?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_skilled_pilot)

nial_declann_convo_priv_rsf_best = ConvoScreen:new {
	id = "priv_rsf_best",
	leftDialog = "@conversation/imperial_master_trainer:s_1837e4aa", -- Do not try my patience. The RSF exists at the whim of the Empire. At any time we can take away your vaunted security force and the whole lot of you would be placed into the Imperial Navy. I would be surprised if even a third of you made it out of our training program.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_913ac8c9", "priv_rsf_forget_place"}, -- Sir, I must disagree.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_best)

nial_declann_convo_priv_rsf_forget_place = ConvoScreen:new {
	id = "priv_rsf_forget_place",
	leftDialog = "@conversation/imperial_master_trainer:s_c38038fe", -- You forget your place, pilot. I asked for you simply based on the recommendations from your superior officers. They seemed to have a great deal of faith in you and were completely sure of your loyalty. Was their faith misplaced?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_8db79f00", "priv_rsf_respect"}, -- No, sir. Sorry, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_forget_place)

nial_declann_convo_priv_rsf_respect = ConvoScreen:new {
	id = "priv_rsf_respect",
	leftDialog = "@conversation/imperial_master_trainer:s_1be63a5a", -- Just because they might tolerate insolence in the RSF does not mean that I have to listen to it. With this operation I am in command I expect complete respect. Do I make myself clear, pilot?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_baca5aeb", "priv_skilled_pilot"}, -- Yes, sir. You are absolutely clear.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rsf_respect)

nial_declann_convo_priv_corsec_intro = ConvoScreen:new {
	id = "priv_corsec_intro",
	leftDialog = "@conversation/imperial_master_trainer:s_f9df4c83", -- It is good to see that the CorSec are not a breeding ground for the Rebellion like many of my peers seem to believe. Perhaps if you work well for me, you can show your fellow pilots that the only way to truly have peace is to fully support the Empire and it's endeavors.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_c5aa2921", "priv_corsec_my_way"}, -- That is exactly how I feel, sir.
		{"@conversation/imperial_master_trainer:s_e685629c", "priv_corsec_dissension"}, -- I think you are mistaken about the ideals of CorSec.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_intro)

nial_declann_convo_priv_corsec_my_way = ConvoScreen:new {
	id = "priv_corsec_my_way",
	leftDialog = "@conversation/imperial_master_trainer:s_4fb6fb91", -- I knew you would see things my way. I could tell from the moment you walked in that you were unlike the rest of that ilk. Personally I believe that the problems that exist within the CorSec can be fixed. I don't how many times I have saved your group from destruction. 
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_87ccb642", "priv_corsec_appreciate"}, -- And many members of the CorSec do appreciate it.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_my_way)

nial_declann_convo_priv_corsec_appreciate = ConvoScreen:new {
	id = "priv_corsec_appreciate",
	leftDialog = "@conversation/imperial_master_trainer:s_c92b41e9", -- As well you should. I am hardly required to spend my valuable time trying to protect an agency that isn't under Imperial control. But I think that you and I shall change the perception that other members of Imperial Command might have of CorSec. Wouldn't you agree?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_7b3a873", "priv_corsec_presence"}, -- Perhaps if I had a better idea what you wanted from me.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_appreciate)

nial_declann_convo_priv_corsec_presence = ConvoScreen:new {
	id = "priv_corsec_presence",
	leftDialog = "@conversation/imperial_master_trainer:s_8c202f75", -- Ah, yes. You are interested in finding out why I have ordered your presence. I am in need of a skilled pilot to implement a plan I have devised in order to secure the Kessel system. 
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_85b8ffbd", "priv_kessel"}, -- The Kessel system?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_presence)

nial_declann_convo_priv_corsec_dissension = ConvoScreen:new {
	id = "priv_corsec_dissension",
	leftDialog = "@conversation/imperial_master_trainer:s_3d30040d", -- It has been well known for years that CorSec is nothing more then a breeding ground for dissension. Do not question my judgment in this matter. If it wasn't for me there wouldn't be a CorSec. I don't know how many times I fought against having your entire corps eliminated. Despite all of it's obvious flaws, I do believe that the corps can be saved.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_24077de7", "priv_corsec_together"}, -- I see, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_dissension)

nial_declann_convo_priv_corsec_together = ConvoScreen:new {
	id = "priv_corsec_together",
	leftDialog = "@conversation/imperial_master_trainer:s_22dd5c33", -- You and I shall work together in order to bring respectability back to CorSec.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_4041b73c", "priv_corsec_simple"}, -- How do you propose we do that?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_together)

nial_declann_convo_priv_corsec_simple = ConvoScreen:new {
	id = "priv_corsec_simple",
	leftDialog = "@conversation/imperial_master_trainer:s_cf1c32cf", -- Very simple. You will offer support to a plan I have devised in order to gain control of the Kessel system. With my brilliant strategy, even a pilot such as yourself, should have no trouble bringing victory in the name of the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_85b8ffbd", "priv_kessel"}, -- The Kessel system?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_corsec_simple)

nial_declann_convo_priv_kessel = ConvoScreen:new {
	id = "priv_kessel",
	leftDialog = "@conversation/imperial_master_trainer:s_a622496d", -- Of course, why would I assume that you know anything of the Kessel system? The Kessel system is located deep in the Outer Rim. The Empire has had plans to take full control of the system for some time now, but we have never quite been able to succeed in it's ultimate control.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/imperial_master_trainer:s_fd661a34", "priv_kessel_why"}, -- Why would the Empire want control of the Kessel system?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_kessel)

nial_declann_convo_priv_kessel_why = ConvoScreen:new {
	id = "priv_kessel_why",
	leftDialog = "@conversation/imperial_master_trainer:s_1aff8b69", -- The Kessel system is strategically connected to three other systems along the Outer Rim. With control of that one system, the Empire can exert it's influence on the entire region. From there it is only a small step in order to control the entire Outer Rim.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_15f15e84", "priv_overestimate"}, -- I think you might over estimate the value of the Kessel system.
		{"@conversation/imperial_master_trainer:s_78dfc859", "priv_battlegroup"}, -- Sounds like a very sound plan, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_kessel_why)

nial_declann_convo_priv_overestimate = ConvoScreen:new {
	id = "priv_overestimate",
	leftDialog = "@conversation/imperial_master_trainer:s_ca9b9b68", -- This is why you are but a lowly pilot in a local planet security force and I am a Grand Admiral. Do not ever make the mistake of questioning my judgment. I am willing to let that remark go unpunished this time, but I am not accustomed to being questioned by mere pilots... and I do not plan on making a habit out of it.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/imperial_master_trainer:s_af2fc12f", "priv_battlegroup"}, -- Sorry, sir. I spoke out of turn.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_overestimate)

nial_declann_convo_priv_battlegroup = ConvoScreen:new {
	id = "priv_battlegroup",
	leftDialog = "@conversation/imperial_master_trainer:s_ba2453bc", -- Yes, yes. The Rebellion has moved portions of their fourth battle group into the region and before we can take control of the Kessel system, it is imperative that they be eliminated. In order to do this we will need to perform a duel stage attack on their power bases in the system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_92172df0", "priv_rebel_control"}, -- The Rebellion has control of the Kessel system right now?
		{"@conversation/imperial_master_trainer:s_33d1d488", "priv_why_not_navy"}, -- Why isn't the Imperial Navy taking care of the Rebels in the region?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_battlegroup)

nial_declann_convo_priv_rebel_control = ConvoScreen:new {
	id = "priv_rebel_control",
	leftDialog = "@conversation/imperial_master_trainer:s_a340005a", -- The Rebellion controls nothing in the galaxy. But they have a force in the Kessel system that could pose problems to our operations. Before we move into the system in force, we need to eliminate the Rebel threat. That will be your mission.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_60d3f4f8", "priv_orders"}, -- What is it that you want me to do?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_rebel_control)

nial_declann_convo_priv_why_not_navy = ConvoScreen:new {
	id = "priv_why_not_navy",
	leftDialog = "@conversation/imperial_master_trainer:s_732a67f3", -- The Rebel battlegroup moved into the system sooner then we anticipated. Unfortunately, the main portion of our battle fleets are engaged elsewhere. The Rebels want Kessel for it's strategic location in order to spread their chaos and dissension across the entire Outer Rim. In the same way, we want use Kessel to help bring order to the Outer Rim.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_bcb643d", "priv_allies"}, -- So you are turning to local security forces to assist you in this matter?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_why_not_navy)

nial_declann_convo_priv_allies = ConvoScreen:new {
	id = "priv_allies",
	leftDialog = "@conversation/imperial_master_trainer:s_794642f2", -- I would rather keep this matter completely in the Imperial Navy's hands but the situation dictates that we occasionally need to rely on our allies. This is a great opportunity for the planetary security forces to prove that the Empire was correct in not disbanding them.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_63f7aad9", "priv_orders"}, -- What is it you want me to do?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_allies)

nial_declann_convo_priv_orders = ConvoScreen:new {
	id = "priv_orders",
	leftDialog = "@conversation/imperial_master_trainer:s_ecdec8ad", -- As I said, you are to eliminate the Rebel threat in the region. The first stage of the attack is to destroy a number of their smaller vessels that patrol throughout the region. These vessels would include fighters as well as gunboats.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_2bd3a43c", "priv_m1_accept"}, -- You said smaller vessels. Does that mean there are larger capital class ships in the region?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_orders)

nial_declann_convo_priv_m1_accept = ConvoScreen:new {
	id = "priv_m1_accept",
	leftDialog = "@conversation/imperial_master_trainer:s_58a058a9", -- That is not your concern at this time. My plan is to first weaken the fighter capability of the Rebels in the region and then we can initiate stage two. You are to focus all your energies on the destruction of the Rebel fighter craft in the region. Is that understood, Pilot?
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/imperial_master_trainer:s_bb9e4a63", "priv_m1_dismissed_corsec"}, -- Understood, sir.
		{"@conversation/imperial_master_trainer:s_65031818", "priv_positions"}, -- Where are the Rebel positions in the sector?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m1_accept)

nial_declann_convo_priv_positions = ConvoScreen:new {
	id = "priv_positions",
	leftDialog = "@conversation/imperial_master_trainer:s_1df5b492", -- Due to the interference from the Maw, long range scans are virtually useless in the Kessel system. You are going to have to hunt them down. Our system intelligence reports that they patrol throughout the system. You will just have to find them. Is that understood?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_bb9e4a63", "priv_m1_dismissed_corsec"}, -- Understood, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_positions)

nial_declann_convo_priv_m1_dismissed_corsec = ConvoScreen:new {
	id = "priv_m1_dismissed_corsec",
	leftDialog = "@conversation/imperial_master_trainer:s_7eeb4f8c", -- Good. Now get on with my operation. I am placing a great deal of faith in a pilot who does not even belong to the Imperial Navy. I expect that you will prove that the CorSec is not the breeding ground for Rebels that many of my peers seem to believe. Pilot, you are dismissed.
	stopConversation = "true",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m1_dismissed_corsec)

nial_declann_convo_priv_m1_dismissed_rsf = ConvoScreen:new {
	id = "priv_m1_dismissed_rsf",
	leftDialog = "@conversation/imperial_master_trainer:s_eb171ae9", -- Good. Now get on with my operation. I am placing a great deal of faith in a pilot who does not even belong to the Imperial Navy. I expect that you will prove the RSF is completely loyal to the Empire. Pilot, you are dismissed.
	stopConversation = "true",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m1_dismissed_rsf)

nial_declann_convo_priv_m1_reward = ConvoScreen:new {
	id = "priv_m1_reward",
	leftDialog = "@conversation/imperial_master_trainer:s_fbe23895", -- I have decided that you deserve a small token of my appreciation as a reward for your successful flight. I am going to have some credits transferred to your account so you can take a little rest and relaxation. A rested pilot is a better pilot.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_1affba73", "m1_kind"}, -- The Grand Admiral is too kind.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m1_reward)

nial_declann_convo_priv_m2_brief = ConvoScreen:new {
	id = "priv_m2_brief",
	leftDialog = "@conversation/imperial_master_trainer:s_52c03f61", -- I hope that you are well rested because the time has come for me to unleash the second part of my plan. As you know, we have managed to partially cripple the Rebel battlegroup in the Kessel system and I feel the time to strike at their heart is now.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_a2bd8a18", "priv_m2_crippled"}, -- I am not sure if I would call the Rebel battlegroup crippled.
		{"@conversation/imperial_master_trainer:s_8f760eed", "priv_m2_corvette"}, -- Yes, sir. The Rebels are poised to crumble.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_brief)

nial_declann_convo_priv_m2_crippled = ConvoScreen:new {
	id = "priv_m2_crippled",
	leftDialog = "@conversation/imperial_master_trainer:s_88eb64f3", -- Again you speak without thinking. You accomplished the tasks that comprised the first part of my plan. There is no way that the Rebels could have recovered from such a devastating strike this quickly.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/imperial_master_trainer:s_6844241f", "priv_m2_tone"}, -- If you say so, sir.
		{"@conversation/imperial_master_trainer:s_8efde2ae", "priv_m2_corvette"}, -- Yes, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_crippled)

nial_declann_convo_priv_m2_tone = ConvoScreen:new {
	id = "priv_m2_tone",
	leftDialog = "@conversation/imperial_master_trainer:s_26e02f1d", -- I don't care much for the tone in your voice. If you wish to continue to fly for your organization I suggest that you find a way to control your tongue. I will not suffer any rudeness from a local security pilot.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/imperial_master_trainer:s_af2fc12f", "priv_m2_corvette_again"}, -- Sorry, sir. I spoke out of turn.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_tone)

nial_declann_convo_priv_m2_corvette_again = ConvoScreen:new {
	id = "priv_m2_corvette_again",
	leftDialog = "@conversation/imperial_master_trainer:s_36e64ebe", -- As I said, the Rebellion's fighter squads are greatly diminished and the time to unleash the second stage of my plan has come. The Rebels have moved a Corellian corvette into the Kessel system as part of their battlegroup. This ship is the Rebel command vessel for the entire system.
	stopConversation = "false",
	animation = "shush",
	options = {
		{"@conversation/imperial_master_trainer:s_9e28d2b0", "priv_m2_capital"}, -- A Corellian corvette? Isn't that a capital ship?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_corvette_again)

nial_declann_convo_priv_m2_corvette = ConvoScreen:new {
	id = "priv_m2_corvette",
	leftDialog = "@conversation/imperial_master_trainer:s_16374fa8", -- As I said, the Rebellion's fighter squads are greatly diminished and the time to unleash the second stage of my plan has come. The Rebels have moved a Corellian corvette into the Kessel system as part of their battlegroup. This ship is the Rebel command vessel for the entire sector.
	stopConversation = "false",
	options = {
		{"@conversation/imperial_master_trainer:s_9e28d2b0", "priv_m2_capital"}, -- A Corellian corvette? Isn't that a capital ship?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_corvette)

nial_declann_convo_priv_m2_capital = ConvoScreen:new {
	id = "priv_m2_capital",
	leftDialog = "@conversation/imperial_master_trainer:s_50e3a94f", -- It is what the Rebellion considers to be a capital ship. It lacks the fire power and strength of even the weakest Star Destroyer. Your job should be rather simple. You are to destroy that Corellian corvette as it passes through the system on it's patrol. It apparently patrols several systems, so it is not always in Kessel. You will have to wait for it to enter Kessel on patrol before you will be able to strike.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/imperial_master_trainer:s_ef6b4924", "priv_m2_insolent"}, -- Sir, that is insanity.
		{"@conversation/imperial_master_trainer:s_7cc631fe", "priv_m2_support"}, -- Will I have support?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_capital)

nial_declann_convo_priv_m2_insolent = ConvoScreen:new {
	id = "priv_m2_insolent",
	leftDialog = "@conversation/imperial_master_trainer:s_5d0b4f6b", -- You insolent pup. You dare insinuate that I do not know exactly what I have ordered you to do. If I felt that there were any other pilots available to perform this task I would have you executed and be done with you. Unfortunately, I am still in need of your skills.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_5ac61a82", "priv_m2_delegate"}, -- I didn't mean any disrespect, sir. It is just that, attacking a corvette in a fighter is not an effective combat technique.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_insolent)

nial_declann_convo_priv_m2_delegate = ConvoScreen:new {
	id = "priv_m2_delegate",
	leftDialog = "@conversation/imperial_master_trainer:s_bd095033", -- I do not recall telling you to attack that ship alone. I am giving you this assignment but I am delegating you the authority to put together your own flight in order to accomplish this assignment. I know that a local security force is not expected to be a crack combat unit but I would expect that even there people show initiative.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/imperial_master_trainer:s_fd386cda", "priv_m2_accept_a"}, -- Again I apologize for my hasty words, sir.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_delegate)

nial_declann_convo_priv_m2_accept_a = ConvoScreen:new {
	id = "priv_m2_accept_a",
	leftDialog = "@conversation/imperial_master_trainer:s_a15a9037", -- My continued support for your organization is waning. I feel that your success in the destruction of the Rebel flag ship is just about the only thing that will convince me to change my mind.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/imperial_master_trainer:s_f352e00f", "priv_m2_accept_a_end"}, -- I will not fail you or the Empire.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_accept_a)

nial_declann_convo_priv_m2_accept_a_end = ConvoScreen:new {
	id = "priv_m2_accept_a_end",
	leftDialog = "@conversation/imperial_master_trainer:s_ace4b0c3", -- See that you don't. I would hate to see you be the cause for me to decide that the time has come to do away with local security forces and replace them all with members of the Imperial Navy. You are dismissed.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_accept_a_end)

nial_declann_convo_priv_m2_support = ConvoScreen:new {
	id = "priv_m2_support",
	leftDialog = "@conversation/imperial_master_trainer:s_f85f5c9d", -- I would hardly expect you to attack a capital vessel by yourself. I may expect a lot out of the men that serve under me, but you going out alone to attack that vessel would not accomplish anything... other than your death.
	stopConversation = "false",
	animation = "cover_eyes",
	options = {
		{"@conversation/imperial_master_trainer:s_9bbd1090", "priv_m2_accept_b"}, -- So I will have support?
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_support)

nial_declann_convo_priv_m2_accept_b = ConvoScreen:new {
	id = "priv_m2_accept_b",
	leftDialog = "@conversation/imperial_master_trainer:s_30f24d", -- Show some initiative. I have given you orders and the plan, everything else I delegate to you. It is time to prove that you are a capable leader as well as a pilot. Assemble a team that will assist you on your assault on the Rebel corvette.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/imperial_master_trainer:s_65d9bf6c", "priv_m2_accept_b_end"}, -- Yes, sir. I shall not fail you.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_accept_b)

nial_declann_convo_priv_m2_accept_b_end = ConvoScreen:new {
	id = "priv_m2_accept_b_end",
	leftDialog = "@conversation/imperial_master_trainer:s_1ae97099", -- See that you don't. Once the Empire has Kessel under it's control the rest of the Outer Rim will fall into line without much of a struggle. With my great victory, I will personally hand the Emperor a prize that he has longed for, the Outer Rim.
	stopConversation = "true",
	animation = "applause_polite",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_m2_accept_b_end)

nial_declann_convo_priv_master_grant = ConvoScreen:new {
	id = "priv_master_grant",
	leftDialog = "@conversation/imperial_master_trainer:s_110667a0", -- You may not be a member of the Imperial Navy but you have shown yourself to be a loyal member and valuable asset to the Empire. I believe that you have achieved the highest level of piloting skill that anyone can hope to accomplish. And as a token of my personal appreciation I have authorized a transfer of payment to your account.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/imperial_master_trainer:s_377d1a96", "priv_master_end"}, -- Thank you, sir. It has been an honor to be allowed to serve under you.
	}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_master_grant)

nial_declann_convo_priv_master_end = ConvoScreen:new {
	id = "priv_master_end",
	leftDialog = "@conversation/imperial_master_trainer:s_ebd84e91", -- Yes, I am sure it was. You are dismissed, pilot.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
nial_declann_convo_template:addScreen(nial_declann_convo_priv_master_end)

addConversationTemplate("nial_declann_convo_template", nial_declann_convo_template)
