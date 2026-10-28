-- Admiral Willham Burke (Rebel master trainer) conversation; ported from SWG-Source rebel_master_trainer.java with the pre-NGE client lines (feature space-master-trainer-rebel). Handler: willhamBurkeConvoHandler.
willham_burke_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "willhamBurkeConvoHandler",
	screens = {}
}

willham_burke_convo_default = ConvoScreen:new {
	id = "default",
	leftDialog = "@conversation/rebel_master_trainer:s_c2eca562", -- I am afraid that I am too busy right now to talk to you. If you are interested in helping our cause I would suggest that you find some of our recruiters. They are located here and there but I am afraid I really don't keep track of them. Maybe try talking to J'pai Brek in Tyrena.
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_default)

willham_burke_convo_working_for_empire = ConvoScreen:new {
	id = "working_for_empire",
	leftDialog = "@conversation/rebel_master_trainer:s_dc822762", -- You shouldn't be here! I have nothing to say to the likes of you. You have made your choice, now you must live with the consequences.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_working_for_empire)

willham_burke_convo_imperial_pilot = ConvoScreen:new {
	id = "imperial_pilot",
	leftDialog = "@conversation/rebel_master_trainer:s_d6d7f7f9", -- You and I have nothing to say to one another. I suggest you clear out of this area and get back to your tyrant leaders. We will one day meet on the field of battle, I can promise you that.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_imperial_pilot)

willham_burke_convo_rsf_pilot = ConvoScreen:new {
	id = "rsf_pilot",
	leftDialog = "@conversation/rebel_master_trainer:s_f2bb94ef", -- I normally do not drive off a potential ally, but I cannot trust just ANY member of the Royal Security Forces. Your group is just too tightly involved with the Empire, and I cannot risk allowing you to join our cause.
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_rsf_pilot)

willham_burke_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/rebel_master_trainer:s_efd059ff", -- %NU, it is always nice to stop and chat with the men, but I am afraid that I do not have time to talk right now. I am planning a very important operation and I can only use the finest pilots available to the Alliance. I suggest you gain some more flight experience and then come back to see me.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/rebel_master_trainer:s_a667be99", "not_ready_yes"}, -- Yes, sir. I will do that.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_not_ready)

willham_burke_convo_not_ready_yes = ConvoScreen:new {
	id = "not_ready_yes",
	leftDialog = "@conversation/rebel_master_trainer:s_5fa0c79", -- That's the spirit, %NU. Keep up the good work and one day maybe you will do great things for the Alliance.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_not_ready_yes)

willham_burke_convo_privateer_not_ready = ConvoScreen:new {
	id = "privateer_not_ready",
	leftDialog = "@conversation/rebel_master_trainer:s_7cd01fd0", -- I am afraid that I am rather busy right now. Under normal circumstances I am always willing to speak to possible allies in our struggle against the tyranny of the Empire, but right now there just doesn't seem to be any time. Perhaps we can talk again after you have earned some more flight experience in real situations.
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_privateer_not_ready)

willham_burke_convo_other_master = ConvoScreen:new {
	id = "other_master",
	leftDialog = "@conversation/rebel_master_trainer:s_98d92abb", -- %NU, you have performed brilliantly in the face of overwhelming odds. It has been my privilege to have been your commanding officer. The victory that you lead in Kessel has assured the continued freedom of the Outer Rim. Currently I do not have any new missions that I need you to perform. I trust in your ability to uphold the values of the Alliance without assistance from me.
	stopConversation = "true",
	animation = "point_to_self",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_other_master)

willham_burke_convo_master_done = ConvoScreen:new {
	id = "master_done",
	leftDialog = "@conversation/rebel_master_trainer:s_bfaef3d8", -- %NU, you have performed brilliantly in the face of overwhelming odds. It has been my privilege to have been your commanding officer. The victory that you lead in Kessel has assured the continued freedom of the Outer Rim. Currently I do not have any new missions that I need you to run. I trust in your ability to uphold the values of the Alliance without assistance from me.
	stopConversation = "true",
	animation = "point_to_self",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_master_done)

willham_burke_convo_on_master_mission = ConvoScreen:new {
	id = "on_master_mission",
	leftDialog = "@conversation/rebel_master_trainer:s_21d9c824", -- You shouldn't be back here. You have a job to do in the Kessel system. Your mission is of utmost importance and the entire Alliance is counting on your success. To your ship, Pilot!
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_on_master_mission)

willham_burke_convo_on_quest = ConvoScreen:new {
	id = "on_quest",
	leftDialog = "@conversation/rebel_master_trainer:s_fd815e48", -- You have your orders, Pilot. It is imperative that you complete the mission that you have! Once you have completed the task on hand, talk to me again and we will see what needs to be done.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_on_quest)

willham_burke_convo_privateer_ready = ConvoScreen:new {
	id = "privateer_ready",
	leftDialog = "@conversation/rebel_master_trainer:s_41910783", -- Greetings, %NU. I am sure you are plenty confused as to why an Alliance Admiral asked to speak with you. To put it bluntly, we are in need of your help.
	stopConversation = "true",
	animation = "greet",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_privateer_ready)

willham_burke_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/rebel_master_trainer:s_7826431d", -- I see that you failed to destroy the corvette. This is not good news. The balance of power inside of the Kessel system has shifted heavily in favor of the Empire. Unless we can destroy that vessel we could lose the entire region.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/rebel_master_trainer:s_d4d47c04", "m2_failed_chance"}, -- Give me another chance, sir.
		{"@conversation/rebel_master_trainer:s_eb02d65", "m2_failed_skills"}, -- I am a good pilot, sir.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_failed)

willham_burke_convo_m2_failed_chance = ConvoScreen:new {
	id = "m2_failed_chance",
	leftDialog = "@conversation/rebel_master_trainer:s_1c113900", -- I was about to suggest the same thing. I still cannot think of anyone better suited for this important mission than you. %NU, you must destroy that corvette. Unless the Empire's power in the Kessel system is diminished, they will begin exerting their influence on the entire Outer Rim.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/rebel_master_trainer:s_ce45643c", "m2_retry_a"}, -- Do not worry, sir. I will not fail you again.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_failed_chance)

willham_burke_convo_m2_retry_a = ConvoScreen:new {
	id = "m2_retry_a",
	leftDialog = "@conversation/rebel_master_trainer:s_becf889", -- You are not fighting for me. You are fighting for yourself and those you care about. Remember that. We have lost so much already, we cannot lose here.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/rebel_master_trainer:s_e374b3bf", "m2_retry_a_end"}, -- I will remember that, sir.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_retry_a)

willham_burke_convo_m2_retry_a_end = ConvoScreen:new {
	id = "m2_retry_a_end",
	leftDialog = "@conversation/rebel_master_trainer:s_a2b72d37", -- You are a brave soul, %NU. May the Force be with you.
	stopConversation = "true",
	animation = "snap_finger2",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_retry_a_end)

willham_burke_convo_m2_failed_skills = ConvoScreen:new {
	id = "m2_failed_skills",
	leftDialog = "@conversation/rebel_master_trainer:s_fe42648c", -- You certainly have an interesting way of showing your skills then, Pilot. Normally when someone is good at something they accomplish any tasks involved.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/rebel_master_trainer:s_c13f9a11", "m2_retry_b"}, -- I am sorry, sir. Give me another chance. I will succeed.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_failed_skills)

willham_burke_convo_m2_retry_b = ConvoScreen:new {
	id = "m2_retry_b",
	leftDialog = "@conversation/rebel_master_trainer:s_8c56411b", -- To show you that I am a forgiving man, I accept your apology. And I will also give you another chance to destroy the stolen Rebel corvette that is regularly patrolling the Kessel system. For your sake, do not fail me again. Are we understood?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_f799f9ec", "m2_retry_b_end"}, -- Perfectly clear, sir!
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_retry_b)

willham_burke_convo_m2_retry_b_end = ConvoScreen:new {
	id = "m2_retry_b_end",
	leftDialog = "@conversation/rebel_master_trainer:s_3924b90e", -- Good. Now get to your ship before I change my mind.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_retry_b_end)

willham_burke_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/rebel_master_trainer:s_7f725bea", -- %NU, what is the status of your operation in the Kessel system?
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_4c9055c9", "m1_failed_details"}, -- [relate the details of the failed mission]
		{"@conversation/rebel_master_trainer:s_ed30fff8", "m1_failed_planning"}, -- It wasn't my fault, sir. The mission failed due to bad planning.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_failed)

willham_burke_convo_m1_failed_details = ConvoScreen:new {
	id = "m1_failed_details",
	leftDialog = "@conversation/rebel_master_trainer:s_77a163bd", -- I see. That would explain why reports show that more Imperial vessels are moving into the system. We must find a way to reduce the number of Imperial support craft in the system for our primary objective to have any chance at success.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_e228ef89", "m1_failed_chance"}, -- Sir, may I suggest that you give me another chance?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_failed_details)

willham_burke_convo_m1_failed_chance = ConvoScreen:new {
	id = "m1_failed_chance",
	leftDialog = "@conversation/rebel_master_trainer:s_58559f7e", -- I am not sure. This mission is highly important and it is imperative that it succeed. The Empire cannot be allowed to gain absolute control of the Kessel system, or the Alliance will be hard pressed to maintain its forces in and around the Outer Rim.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_46ecd1ec", "m1_retry_a"}, -- I can do it, sir. I know I can.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_failed_chance)

willham_burke_convo_m1_retry_a = ConvoScreen:new {
	id = "m1_retry_a",
	leftDialog = "@conversation/rebel_master_trainer:s_39516a4", -- Very well. Get back to the Kessel system and destroy the Imperial support vessels that are patrolling the region. Good luck, pilot.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_retry_a)

willham_burke_convo_m1_failed_planning = ConvoScreen:new {
	id = "m1_failed_planning",
	leftDialog = "@conversation/rebel_master_trainer:s_a79ccb10", -- Are you saying that I was wrong in my assessment of the Imperial strength in the Kessel system?
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_c788dadf", "m1_retry_b"}, -- No, sir. Of course not, sir.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_failed_planning)

willham_burke_convo_m1_retry_b = ConvoScreen:new {
	id = "m1_retry_b",
	leftDialog = "@conversation/rebel_master_trainer:s_cab1f8c7", -- Listen to me closely because you are walking on some very thin ice right now, Pilot. You are to return to the Kessel system and destroy the Imperial positions. My plan will not fail because of the incompetence of a lowly pilot such as yourself. Are we clear?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/rebel_master_trainer:s_b6b25f13", "m1_retry_b_clear"}, -- Yes, sir!
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_retry_b)

willham_burke_convo_m1_retry_b_clear = ConvoScreen:new {
	id = "m1_retry_b_clear",
	leftDialog = "@conversation/rebel_master_trainer:s_1ffdcc4b", -- Are we clear?
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_87d4bfc2", "m1_retry_b_end"}, -- Crystal.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_retry_b_clear)

willham_burke_convo_m1_retry_b_end = ConvoScreen:new {
	id = "m1_retry_b_end",
	leftDialog = "@conversation/rebel_master_trainer:s_5bdc459b", -- Good! Now get to your ship and take out those Imperial positions in Kessel.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_retry_b_end)

willham_burke_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/rebel_master_trainer:s_e3714e1d", -- We were unable to follow your progress via long range scans due to the interference of the Maw. What do you have to report?
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_1da9fe53", "m2_report"}, -- [relay the destruction of the stolen Corellian Corvette]
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_won)

willham_burke_convo_m2_report = ConvoScreen:new {
	id = "m2_report",
	leftDialog = "@conversation/rebel_master_trainer:s_d09ace00", -- A glorious victory for the Alliance! You really came through when it counted, %NU. You have made a difference to millions of lives along the Outer Rim and you have proven yourself a hero of the Alliance.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/rebel_master_trainer:s_3f6a8711", "m2_modesty"}, -- Thank you, sir. I do my best.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_report)

willham_burke_convo_m2_modesty = ConvoScreen:new {
	id = "m2_modesty",
	leftDialog = "@conversation/rebel_master_trainer:s_3ccc33fb", -- There is no need for modesty. Be proud of your accomplishments. Unfortunately this business with the Imperial corvette has allowed them to reestablish a presence in the system. Although it is not as large as it once was, it is still formidable. Alliance Command has decided to play it safe and not issue the full scale assault on the Kessel system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_8d7967cc", "m2_disappointed"}, -- I am disappointed to hear that.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_modesty)

willham_burke_convo_m2_disappointed = ConvoScreen:new {
	id = "m2_disappointed",
	leftDialog = "@conversation/rebel_master_trainer:s_e87785ac", -- As am I. I still believe that we can take the area but Alliance Command believes that the Empire will be able to mount a Star Destroyer attack. We cannot risk a direct confrontation with one of those. Regardless, you have more than done your duty. I have been authorized on behalf of the Alliance to issue you a reward for your noble actions.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_5869e64b", "master_grant"}, -- Thank you, sir. I appreciate it.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_disappointed)

willham_burke_convo_master_grant = ConvoScreen:new {
	id = "master_grant",
	leftDialog = "@conversation/rebel_master_trainer:s_28d79ee3", -- Your accomplishments have proven that you are a valued asset to the Alliance and a truly exceptional pilot. I believe that you have achieved the highest level of piloting skill that anyone can possess. I think that you might find some measure of fame waiting for you when everyone finds out what you have done.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_c67e8169", "master_end"}, -- I am only one of many heroes for the Alliance.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_master_grant)

willham_burke_convo_master_end = ConvoScreen:new {
	id = "master_end",
	leftDialog = "@conversation/rebel_master_trainer:s_ef3cc459", -- Perhaps, but there is no need to be humble when it comes to your accomplishment. Victories like this can raise the morale of the troops across the entire galaxy. Thank you, %NU. You are dismissed.
	stopConversation = "true",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_master_end)

willham_burke_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/rebel_master_trainer:s_c78b33ad", -- Welcome back, %NU. It is good to see that you managed to perform such a difficult task and return. Intelligence reports that the number of Imperial ships in the system are down. Our Corellian Corvette should be able to drive the rest of their support craft out of the system.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/rebel_master_trainer:s_d02bfc3b", "m1_corvette"}, -- We brought in a Corellian Corvette?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_won)

willham_burke_convo_m1_corvette = ConvoScreen:new {
	id = "m1_corvette",
	leftDialog = "@conversation/rebel_master_trainer:s_c4d08624", -- Yes, it is patrolling several systems right now, but with your victory we should be able to set up a command post in the Kessel system. Alliance Command believes that the time might be right for us to make our move on the Outer Rim.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_f00f629f", "m1_outer_rim"}, -- We are mobilizing on the Outer Rim?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_corvette)

willham_burke_convo_m1_outer_rim = ConvoScreen:new {
	id = "m1_outer_rim",
	leftDialog = "@conversation/rebel_master_trainer:s_575c9eb2", -- With the Empire distracted elsewhere, we feel that this is a perfect time to strike. The attack will focus on attacking the weakened Imperial positions in the Kessel system. Then we can use it as a staging point for control of a number of systems around it.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/rebel_master_trainer:s_7cbd5de5", "m1_reward"}, -- Sounds like a big undertaking.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_outer_rim)

willham_burke_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/rebel_master_trainer:s_7e8aa338", -- It is at that. And it is only possible because of your victory. The Alliance thanks you and I have been authorized to issue a credit reward to your account. I still have some more planning to work on, but after you take some well deserved rest come and see me again. I am sure I will have a place for you in the attack plan.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_reward)

willham_burke_convo_m2_brief = ConvoScreen:new {
	id = "m2_brief",
	leftDialog = "@conversation/rebel_master_trainer:s_1c9d33ed", -- It is a good thing that you achieved victory over the Imperial support vessels. We desperately needed that good news. Unfortunately for us we have received some very disturbing reports from Ryloth. I fear that our plans on a large scale assault on the Kessel system have been scrapped.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_c68b1dd3", "m2_what_happened"}, -- What happened, sir?
		{"@conversation/rebel_master_trainer:s_ffeb2f4c", "m2_successful"}, -- Was my operation successful in pushing the Empire back?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_brief)

willham_burke_convo_m2_what_happened = ConvoScreen:new {
	id = "m2_what_happened",
	leftDialog = "@conversation/rebel_master_trainer:s_837c0670", -- The Empire has captured and retrofitted one of our corvettes that was in the Ryloth system. Intelligence reports that it has been seen in the Kessel system. This is truly grim news. We believed that we had their star destroyer fleet tied up in several other areas so we could accomplish our tasks here, but it would seem that the Empire has learned how to improvise.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_ca1a4aa4", "m2_corvette"}, -- The Empire has a corvette in the Kessel system?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_what_happened)

willham_burke_convo_m2_successful = ConvoScreen:new {
	id = "m2_successful",
	leftDialog = "@conversation/rebel_master_trainer:s_429ad94c", -- Yes. Your operation did accomplish its goals. But word has come in that the Empire has managed to capture one of our corvettes in the Ryloth system. Intelligence has reported it has been seen patrolling through Kessel.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/rebel_master_trainer:s_ca1a4aa4", "m2_corvette"}, -- The Empire has a corvette in the Kessel system?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_successful)

willham_burke_convo_m2_corvette = ConvoScreen:new {
	id = "m2_corvette",
	leftDialog = "@conversation/rebel_master_trainer:s_74cca111", -- It would seem that this corvette is patrolling several systems, so it is not always in Kessel... but it is always close enough to be a threat. I fear that we only have one choice. You are going to have to destroy that corvette.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_c1c7c6c", "m2_recapture"}, -- Wouldn't it be better to try to recapture the vessel?
		{"@conversation/rebel_master_trainer:s_a6fb8def", "m2_destroy"}, -- Destroy the corvette, sir?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_corvette)

willham_burke_convo_m2_recapture = ConvoScreen:new {
	id = "m2_recapture",
	leftDialog = "@conversation/rebel_master_trainer:s_826f20e2", -- Yes, it certainly would. But we simply do not have the resources to initiate a boarding party right now. I am afraid that our only choice is to make sure that if we don't have it, neither do they.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/rebel_master_trainer:s_7a052bd2", "m2_own_corvette"}, -- I understand we have a corvette in the system, couldn't we use that?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_recapture)

willham_burke_convo_m2_destroy = ConvoScreen:new {
	id = "m2_destroy",
	leftDialog = "@conversation/rebel_master_trainer:s_938d38", -- Our lack of resources in this system makes any attempt at recapturing the vessel futile. The Empire can use that ship to tie up the Kessel system long enough to bring in their star destroyers... and at that point I cannot foresee any chance of us getting Kessel back. The key to the whole Alliance operation in the Outer Rim lies with the destruction of that corvette.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_7a052bd2", "m2_own_corvette"}, -- I understand we have a corvette in the system, couldn't we use that?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_destroy)

willham_burke_convo_m2_own_corvette = ConvoScreen:new {
	id = "m2_own_corvette",
	leftDialog = "@conversation/rebel_master_trainer:s_9e5b1d54", -- Yes we do have our own corvette in the system that we use as a command vessel, but after the loss of the one in the Ryloth system, we cannot risk losing another one. It would appear that we will have to send out fighters to try to combat this menace.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_cba67818", "m2_support"}, -- I understand, sir. Will I have any support for this assault.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_own_corvette)

willham_burke_convo_m2_support = ConvoScreen:new {
	id = "m2_support",
	leftDialog = "@conversation/rebel_master_trainer:s_da1503ff", -- I am going to have to leave the assembly of a team up to you. Once you have your team assembled, enter the Kessel system and look for the Imperial corvette as it moves through the area. Keep in mind that it sometimes leaves the system for several hours, so you might have to hunt for a while in order to initiate attack.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_5bd6bf77", "m2_accept"}, -- Understood, sir. I will not let you down.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_support)

willham_burke_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/rebel_master_trainer:s_17652085", -- You are a courageous pilot. You might be all that stands between the Empire and freedom in the Outer Rim. May the Force be with you.
	stopConversation = "true",
	animation = "salute2",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m2_accept)

willham_burke_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/rebel_master_trainer:s_46b27b0c", -- Hello, %NU. I have been looking forward to meeting you. You are probably wondering why I asked to see you.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/rebel_master_trainer:s_9a0798b3", "intro_wondering"}, -- Yes, I was wondering that.
		{"@conversation/rebel_master_trainer:s_81f189ef", "intro_reporting"}, -- Reporting as ordered, Sir.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_intro)

willham_burke_convo_intro_wondering = ConvoScreen:new {
	id = "intro_wondering",
	leftDialog = "@conversation/rebel_master_trainer:s_36256b98", -- I have been speaking with several of your former commanding officers about an important mission that I need a talented pilot to undertake. Your name came up over and over again. I must say you really left quite an impression on your commanders.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_37157452", "intro_impression"}, -- I hope it was a good impression.
		{"@conversation/rebel_master_trainer:s_89f9ea03", "intro_humor"}, -- I am sorry, Sir. I didn't mean to.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_intro_wondering)

willham_burke_convo_intro_reporting = ConvoScreen:new {
	id = "intro_reporting",
	leftDialog = "@conversation/rebel_master_trainer:s_677c6a2", -- At ease, Pilot. I asked you here because after speaking with several of your commanding officers, I believe that you might be perfect for a very important mission. They told me that you were one of the finest pilots they have ever seen.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/rebel_master_trainer:s_ad709e77", "volunteers"}, -- What can I do for you, Sir?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_intro_reporting)

willham_burke_convo_intro_impression = ConvoScreen:new {
	id = "intro_impression",
	leftDialog = "@conversation/rebel_master_trainer:s_7660776e", -- From my understanding you were one of the finest pilots they have ever dealt with. They said you were a natural, which is just the sort of pilot I need.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_44bd3318", "volunteers"}, -- What is it you need me to do?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_intro_impression)

willham_burke_convo_intro_humor = ConvoScreen:new {
	id = "intro_humor",
	leftDialog = "@conversation/rebel_master_trainer:s_6f27454c", -- So you have a sense of humor as well. That is good. You will need to keep your moral up for we are looking at some bleak times and I fear that many lives may be lost. But we have to strive on if we ever hope to drive the Empire from power. I think you are just the type of pilot I need.
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/rebel_master_trainer:s_44bd3318", "volunteers"}, -- What is it you need me to do?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_intro_humor)

willham_burke_convo_volunteers = ConvoScreen:new {
	id = "volunteers",
	leftDialog = "@conversation/rebel_master_trainer:s_7bf46fb2", -- I need a pilot who is willing to brave the Imperial forces stationed in the Kessel system. It will be extremely dangerous and it is highly likely that anyone who accepts this mission will not make it back alive. I will not force a pilot to accept this mission so I am asking for volunteers.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_32062da9", "volunteer"}, -- I am your pilot, sir. I volunteer.
		{"@conversation/rebel_master_trainer:s_4c9d51f4", "decline"}, -- No thank you, sir. I do not wish to take this mission.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_volunteers)

willham_burke_convo_decline = ConvoScreen:new {
	id = "decline",
	leftDialog = "@conversation/rebel_master_trainer:s_69741346", -- I understand, %NU. If you change your mind come back and talk to me. Until then I wish you continued success in your own duties.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_decline)

willham_burke_convo_volunteer = ConvoScreen:new {
	id = "volunteer",
	leftDialog = "@conversation/rebel_master_trainer:s_5919485e", -- That is what I hoped you would say. The Alliance has decided that it is time to try to make a strike at the Outer Rim. We believe that the Empire is stretched too thin to adequately defend all of its positions in these system. Our first goal is to take Kessel.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/rebel_master_trainer:s_85b8ffbd", "kessel"}, -- The Kessel system?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_volunteer)

willham_burke_convo_kessel = ConvoScreen:new {
	id = "kessel",
	leftDialog = "@conversation/rebel_master_trainer:s_1668a97b", -- The Kessel system is strategically located between three separate systems, all of which have important shipping lanes passing through it. With control of the Kessel system it is possible to defend the surrounding systems very easily. Alliance Command has determined that we take the area for ourselves. Unfortunately, it would appear that the Empire has its own plans for Kessel.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_22d87576", "kessel_meaning"}, -- What do you mean, sir?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_kessel)

willham_burke_convo_kessel_meaning = ConvoScreen:new {
	id = "kessel_meaning",
	leftDialog = "@conversation/rebel_master_trainer:s_86a40b9e", -- The Alliance has been moving ships into the system, but we have come up against heavy resistance from Imperial forces. The Empire has also been moving support vessels into the system. My only guess is that they also realize the potential value of Kessel.
	stopConversation = "false",
	options = {
		{"@conversation/rebel_master_trainer:s_834a890e", "full_assault"}, -- Why not initialize a full scale assault?
		{"@conversation/rebel_master_trainer:s_c97cb0b8", "raid"}, -- Why not organize a raid on the Imperial support vessels?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_kessel_meaning)

willham_burke_convo_full_assault = ConvoScreen:new {
	id = "full_assault",
	leftDialog = "@conversation/rebel_master_trainer:s_e0c18ed4", -- Right now our force is roughly of equal strength to their own. I believe that we can win any such assault, but I fear it would weaken us to the point where we could not hold the system. The Empire would be able to wipe us out easily once their reinforcements arrived.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_47e9fbfd", "plan"}, -- I understand. So what is the plan?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_full_assault)

willham_burke_convo_plan = ConvoScreen:new {
	id = "plan",
	leftDialog = "@conversation/rebel_master_trainer:s_ff2c163e", -- We cannot afford a large scale assault, but we can use a small mobile force to strike quickly at their patrols. If we can hammer hard enough on their positions and destroy enough of their patrol craft, we can put them on their heels. Once we have them down, we will strike with everything we have.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/rebel_master_trainer:s_6d976791", "assault_team"}, -- A very good plan. And you need me for the assault team.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_plan)

willham_burke_convo_raid = ConvoScreen:new {
	id = "raid",
	leftDialog = "@conversation/rebel_master_trainer:s_a21308bb", -- That is exactly the plan. We cannot afford to have a large scale assault but we can use a small mobile force to strike quickly at their patrols. If we can hammer hard enough on their positions and destroy enough of their patrol craft, we can put them on their heels. Once we have them down, we will strike with everything we have.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_6d976791", "assault_team"}, -- A very good plan. And you need me for the assault team.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_raid)

willham_burke_convo_assault_team = ConvoScreen:new {
	id = "assault_team",
	leftDialog = "@conversation/rebel_master_trainer:s_63214db1", -- Correct. You will need to assemble a team of pilots who you feel are up to the challenge. The Imperial pilots in the Kessel system are some of the best in their entire fleet and they are all flying state of the art ships, so this will be no walk in the park.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/rebel_master_trainer:s_1fd64638", "imperials_location"}, -- Where are the Imperials held up?
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_assault_team)

willham_burke_convo_imperials_location = ConvoScreen:new {
	id = "imperials_location",
	leftDialog = "@conversation/rebel_master_trainer:s_875c631e", -- This is where things get a little more tricky. Because of the Maw, long range scanners are next to useless in Kessel. Recon reports that the Imperial vessels patrol all throughout the system, so I am afraid that you will have to perform a seek and destroy style attack on them. I estimate that you will have to destroy at least thirty of these patrol ships in order for us to have an overwhelming advantage.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/rebel_master_trainer:s_2cbd4ffa", "m1_accept"}, -- You can count on me, sir.
	}
}
willham_burke_convo_template:addScreen(willham_burke_convo_imperials_location)

willham_burke_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/rebel_master_trainer:s_3e83f2ea", -- Thank you, Pilot. May the force be with you.
	stopConversation = "true",
	animation = "salute2",
	options = {}
}
willham_burke_convo_template:addScreen(willham_burke_convo_m1_accept)

addConversationTemplate("willham_burke_convo_template", willham_burke_convo_template)
