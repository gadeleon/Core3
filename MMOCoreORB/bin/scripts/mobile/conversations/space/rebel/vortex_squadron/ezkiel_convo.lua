-- Brother Ezkiel (Vortex Squadron tier 3, Dantooine abandoned Rebel base) conversation; ported from SWG-Source naboo_rebel_tier3.java with the pre-NGE client lines (feature vortex-tier3-ezkiel). Handler: ezkielConvoHandler.
ezkiel_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "ezkielConvoHandler",
	screens = {}
}

ezkiel_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8a226979", -- I cannot help you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_not_pilot)

ezkiel_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/naboo_rebel_tier3:s_cbc2d68c", -- Your work here is done %TU.
	animation = "bow3",
	options = {
		{"@conversation/naboo_rebel_tier3:s_9ac7f904", "handoff_evin"}, -- Am I leaving the Vortex?
		{"@conversation/naboo_rebel_tier3:s_eb3c17f0", "handoff_miss"} -- Was it something I said?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_tier_done)

ezkiel_convo_handoff_evin = ConvoScreen:new {
	id = "handoff_evin",
	leftDialog = "@conversation/naboo_rebel_tier3:s_991a471c", -- Not yet. You'll be reporting to Brother Extok Evin from now on. He is on Talus. You can find him in the 'Green Room' of the theater in Dearic.
	options = {
		{"@conversation/naboo_rebel_tier3:s_eba35f17", "handoff_leave"} -- When do I leave?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_handoff_evin)

ezkiel_convo_handoff_leave = ConvoScreen:new {
	id = "handoff_leave",
	leftDialog = "@conversation/naboo_rebel_tier3:s_be1e6832", -- Immediately, I'm afraid. I'm sorry to see you go. It's been a pleasure working with you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_handoff_leave)

ezkiel_convo_handoff_miss = ConvoScreen:new {
	id = "handoff_miss",
	leftDialog = "@conversation/naboo_rebel_tier3:s_ab272dee", -- Not at all! I will miss you and your spirited attitude. You'll be reporting to Brother Extok Evin from now on. He is on Talus. You can find him in the 'Green Room' of the theater in Dearic.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5e57a2aa", "handoff_thanks"} -- Well, thanks for everything, Brother Ezkiel.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_handoff_miss)

ezkiel_convo_handoff_thanks = ConvoScreen:new {
	id = "handoff_thanks",
	leftDialog = "@conversation/naboo_rebel_tier3:s_b9b27823", -- Thank you.
	stopConversation = "true",
	animation = "bow3",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_handoff_thanks)

ezkiel_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8a226979", -- I cannot help you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_wrong_faction)

ezkiel_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/naboo_rebel_tier3:s_3e7fb8a3", -- I appreciate your devotion to the Alliance, but I have nothing for you right now. I suggest you find your commanding officer.
	stopConversation = "true",
	animation = "bow",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_off_track)

ezkiel_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/naboo_rebel_tier3:s_74967449", -- I thought that we could trust you, %TU... but it seems we were mistaken.
	animation = "slump_head",
	options = {
		{"@conversation/naboo_rebel_tier3:s_ceaea132", "grounded_aided"} -- You can trust me
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_grounded)

ezkiel_convo_grounded_aided = ConvoScreen:new {
	id = "grounded_aided",
	leftDialog = "@conversation/naboo_rebel_tier3:s_b552b5dd", -- Not according to what I've been hearing.  You have aided the Empire against us.  We will not trust you with any more assignments until you prove yourself an ally of the Rebel Alliance.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_grounded_aided)

ezkiel_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2750c5d9", -- You still have work to do, young one.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_not_ready)

ezkiel_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_rebel_tier3:s_44fd681b", -- Wouldn't you rather be on your ship? You are still on a mission.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_on_mission)

ezkiel_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/naboo_rebel_tier3:s_1ba01028", -- Not good enough, %NU. You must start over.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_failed)

ezkiel_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/naboo_rebel_tier3:s_4f98b9b7", -- You are not helping the Rebellion.
	options = {
		{"@conversation/naboo_rebel_tier3:s_a0e6a107", "m2_retry_turn"}, -- I can still turn this around.
		{"@conversation/naboo_rebel_tier3:s_30760d01", "m2_retry_shot"} -- Give me another shot.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_failed)

ezkiel_convo_m2_retry_turn = ConvoScreen:new {
	id = "m2_retry_turn",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d2bd9636", -- Not standing here, you can't. Please return to your ship.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_retry_turn)

ezkiel_convo_m2_retry_shot = ConvoScreen:new {
	id = "m2_retry_shot",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c9f02e02", -- Go! You must succeed.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_retry_shot)

ezkiel_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/naboo_rebel_tier3:s_840116ce", -- Blast you! You haven't done your job!
	options = {
		{"@conversation/naboo_rebel_tier3:s_ded27301", "m3_retry_defeated"}, -- I'm not defeated yet!
		{"@conversation/naboo_rebel_tier3:s_fd2e11b9", "m3_retry_blowtorch"} -- I don't see how this helps the Alliance!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_failed)

ezkiel_convo_m3_retry_defeated = ConvoScreen:new {
	id = "m3_retry_defeated",
	leftDialog = "@conversation/naboo_rebel_tier3:s_6a5142e8", -- I don't know why you are talking to me when you have Imperials to kill!
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_retry_defeated)

ezkiel_convo_m3_retry_blowtorch = ConvoScreen:new {
	id = "m3_retry_blowtorch",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a30c289b", -- You'll understand when an Imperial tries to attach you to a ship - with a blowtorch. Unless that sounds good to you - get back out there!
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_retry_blowtorch)

ezkiel_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/naboo_rebel_tier3:s_51fbced7", -- You have failed! Try again, %TU!
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_failed)

ezkiel_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/naboo_rebel_tier3:s_eeb2051f", -- Very nice work, %TU. Are you ready for further training?
	options = {
		{"@conversation/naboo_rebel_tier3:s_879249ea", "trained_starships"}, -- I'm interested in space superiority fighters.
		{"@conversation/naboo_rebel_tier3:s_a436613b", "trained_weapons"}, -- I'm interested in advanced starship component use.
		{"@conversation/naboo_rebel_tier3:s_e6be1367", "trained_procedures"}, -- I'm interested in advanced space combat.
		{"@conversation/naboo_rebel_tier3:s_ccecab6a", "trained_droid"} -- I'm interested in system balance programming.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_reward)

ezkiel_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/naboo_rebel_tier3:s_6dea91bd", -- That mission was quite dangerous. Perhaps it's time to return to training. I want you to have the skills you need to succeed.
	options = {
		{"@conversation/naboo_rebel_tier3:s_879249ea", "trained_starships"}, -- I'm interested in space superiority fighters.
		{"@conversation/naboo_rebel_tier3:s_a436613b", "trained_weapons"}, -- I'm interested in advanced starship component use.
		{"@conversation/naboo_rebel_tier3:s_e6be1367", "trained_procedures"}, -- I'm interested in advanced space combat.
		{"@conversation/naboo_rebel_tier3:s_ccecab6a", "trained_droid"} -- I'm interested in system balance programming.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_reward)

ezkiel_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/naboo_rebel_tier3:s_f8438ea7", -- A pilot as good as you are, you deserve the best training possible. I can help.
	options = {
		{"@conversation/naboo_rebel_tier3:s_879249ea", "trained_starships"}, -- I'm interested in space superiority fighters.
		{"@conversation/naboo_rebel_tier3:s_a436613b", "trained_weapons"}, -- I'm interested in advanced starship component use.
		{"@conversation/naboo_rebel_tier3:s_e6be1367", "trained_procedures"}, -- I'm interested in advanced space combat.
		{"@conversation/naboo_rebel_tier3:s_ccecab6a", "trained_droid"} -- I'm interested in system balance programming.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_reward)

ezkiel_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5beffaeb", -- The Alliance is fortunate to have a pilot like you in their ranks. All you need now is more training.
	options = {
		{"@conversation/naboo_rebel_tier3:s_879249ea", "trained_starships"}, -- I'm interested in space superiority fighters.
		{"@conversation/naboo_rebel_tier3:s_a436613b", "trained_weapons"}, -- I'm interested in advanced starship component use.
		{"@conversation/naboo_rebel_tier3:s_e6be1367", "trained_procedures"}, -- I'm interested in advanced space combat.
		{"@conversation/naboo_rebel_tier3:s_ccecab6a", "trained_droid"} -- I'm interested in system balance programming.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_reward)

ezkiel_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5a7254ca", -- One of our pilots will teach you that skill. When you're done, I will have another mission for you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_trained_starships)

ezkiel_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5a7254ca", -- One of our pilots will teach you that skill. When you're done, I will have another mission for you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_trained_weapons)

ezkiel_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5a7254ca", -- One of our pilots will teach you that skill. When you're done, I will have another mission for you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_trained_procedures)

ezkiel_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5a7254ca", -- One of our pilots will teach you that skill. When you're done, I will have another mission for you.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_trained_droid)

ezkiel_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a285e391", -- %TU. Brother Vrovel says you can be trusted.
	animation = "bow",
	options = {
		{"@conversation/naboo_rebel_tier3:s_ba5bf569", "m1_6e75fbb0"}, -- I try.
		{"@conversation/naboo_rebel_tier3:s_58ddac81", "m1_s94"}, -- I'm trustworthy - AND I'm a good fighter.
		{"@conversation/naboo_rebel_tier3:s_6eb747d4", "m1_aacbf366"} -- That's very kind of him.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_offer)

ezkiel_convo_m1_6e75fbb0 = ConvoScreen:new {
	id = "m1_6e75fbb0",
	leftDialog = "@conversation/naboo_rebel_tier3:s_6e75fbb0", -- The Vortex is in danger.
	options = {
		{"@conversation/naboo_rebel_tier3:s_4ca47de6", "m1_692e89db"} -- The Empire doesn't know about the Vortex.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_6e75fbb0)

ezkiel_convo_m1_s94 = ConvoScreen:new {
	id = "m1_s94",
	leftDialog = "@conversation/naboo_rebel_tier3:s_3f107c3c", -- Imperial ships are attacking a Rebel outpost - one that is very important to us.
	options = {
		{"@conversation/naboo_rebel_tier3:s_7d043357", "m1_s98"} -- What's so special about it?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s94)

ezkiel_convo_m1_aacbf366 = ConvoScreen:new {
	id = "m1_aacbf366",
	leftDialog = "@conversation/naboo_rebel_tier3:s_aacbf366", -- Are you ready to work? The Vortex needs good pilots, now more than ever.
	options = {
		{"@conversation/naboo_rebel_tier3:s_841d27db", "m1_d001ebec"} -- Why?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_aacbf366)

ezkiel_convo_m1_692e89db = ConvoScreen:new {
	id = "m1_692e89db",
	leftDialog = "@conversation/naboo_rebel_tier3:s_692e89db", -- They do now, I'm afraid.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_804150c5", "m1_629b68ab"}, -- What's happened?
		{"@conversation/naboo_rebel_tier3:s_5bd69df6", "m1_s78"} -- What do you need me to do?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_692e89db)

ezkiel_convo_m1_629b68ab = ConvoScreen:new {
	id = "m1_629b68ab",
	leftDialog = "@conversation/naboo_rebel_tier3:s_629b68ab", -- It was going so well. We thought we were on the verge of learning the purpose of the Imperial Inquisition.
	options = {
		{"@conversation/naboo_rebel_tier3:s_17c8fb82", "m1_a2f15702"} -- Inquisitors punish and torture Rebels.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_629b68ab)

ezkiel_convo_m1_s78 = ConvoScreen:new {
	id = "m1_s78",
	leftDialog = "@conversation/naboo_rebel_tier3:s_3f107c3c", -- Imperial ships are attacking a Rebel outpost - one that is very important to us.
	options = {
		{"@conversation/naboo_rebel_tier3:s_7d043357", "m1_2d9a2e66"} -- What's so special about it?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s78)

ezkiel_convo_m1_a2f15702 = ConvoScreen:new {
	id = "m1_a2f15702",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a2f15702", -- Yes they do, and they enjoy their work - but I do not think that is their true purpose.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_1545afe8", "m1_840cb413"}, -- Vortex members see conspiracies at every turn.
		{"@conversation/naboo_rebel_tier3:s_3d5f6974", "m1_3f107c3c"} -- You handle the cloak and dagger; I'm here to fight.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_a2f15702)

ezkiel_convo_m1_840cb413 = ConvoScreen:new {
	id = "m1_840cb413",
	leftDialog = "@conversation/naboo_rebel_tier3:s_840cb413", -- It's not paranoia if they're really after you, %NU.
	options = {
		{"@conversation/naboo_rebel_tier3:s_119da2e0", "m1_9feb4fa3"} -- Why do you think the Empire cares about your group?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_840cb413)

ezkiel_convo_m1_3f107c3c = ConvoScreen:new {
	id = "m1_3f107c3c",
	leftDialog = "@conversation/naboo_rebel_tier3:s_3f107c3c", -- Imperial ships are attacking a Rebel outpost - one that is very important to us.
	options = {
		{"@conversation/naboo_rebel_tier3:s_7d043357", "m1_a63013e4"} -- What's so special about it?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_3f107c3c)

ezkiel_convo_m1_9feb4fa3 = ConvoScreen:new {
	id = "m1_9feb4fa3",
	leftDialog = "@conversation/naboo_rebel_tier3:s_9feb4fa3", -- Imperial forces are attacking a Rebel outpost - one that is very important to the Vortex.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_d178b596", "m1_bc380d91"} -- That doesn't prove anything! The Empire attacks everything it sees.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_9feb4fa3)

ezkiel_convo_m1_bc380d91 = ConvoScreen:new {
	id = "m1_bc380d91",
	leftDialog = "@conversation/naboo_rebel_tier3:s_bc380d91", -- I'm not here to convince you. I'm here to order you to defend the base.
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_tier3:s_b2aaabb1", "m1_49776d50"} -- I don't need a reason to shoot Imperials!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_bc380d91)

ezkiel_convo_m1_49776d50 = ConvoScreen:new {
	id = "m1_49776d50",
	leftDialog = "@conversation/naboo_rebel_tier3:s_49776d50", -- You'll be doing more than shooting TIE fighters. The attack is led by an Imperial Inquisitor. He is your primary target. Kill him, and the attacking forces will scatter.
	options = {
		{"@conversation/naboo_rebel_tier3:s_55d6f6", "m1_accept_d683dc69"} -- Not a problem.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_49776d50)

ezkiel_convo_m1_accept_d683dc69 = ConvoScreen:new {
	id = "m1_accept_d683dc69",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d683dc69", -- I hope not. Now please hurry. There's not much time.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_accept_d683dc69)

ezkiel_convo_m1_a63013e4 = ConvoScreen:new {
	id = "m1_a63013e4",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a63013e4", -- It is a rendezvous point for the Vortex. It is, in many ways, our library. It holds our secrets.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_4f707592", "m1_1611aa95"} -- Does the Empire know that?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_a63013e4)

ezkiel_convo_m1_1611aa95 = ConvoScreen:new {
	id = "m1_1611aa95",
	leftDialog = "@conversation/naboo_rebel_tier3:s_1611aa95", -- I don't know. I hope to find out. In the meantime, I need you to defend that outpost...
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_a490d2c6", "m1_8cf5321"} -- Alright.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_1611aa95)

ezkiel_convo_m1_8cf5321 = ConvoScreen:new {
	id = "m1_8cf5321",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8cf5321", -- The attack is led by an Imperial Inquisitor. He is your primary target. Kill him, and the attacking forces will scatter.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fdba7430", "m1_accept_401aa65c"} -- You can count on me.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_8cf5321)

ezkiel_convo_m1_accept_401aa65c = ConvoScreen:new {
	id = "m1_accept_401aa65c",
	leftDialog = "@conversation/naboo_rebel_tier3:s_401aa65c", -- I hope so. Now please hurry. There's not much time.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_accept_401aa65c)

ezkiel_convo_m1_2d9a2e66 = ConvoScreen:new {
	id = "m1_2d9a2e66",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2d9a2e66", -- It is a rendezvous point for the Vortex. It is, in many ways, our library. It holds a lot of the information we have gathered over the years.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_4f707592", "m1_s85"} -- Does the Empire know that?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_2d9a2e66)

ezkiel_convo_m1_s85 = ConvoScreen:new {
	id = "m1_s85",
	leftDialog = "@conversation/naboo_rebel_tier3:s_1611aa95", -- I don't know. I hope to find out. In the meantime, I need you to defend that outpost...
	options = {
		{"@conversation/naboo_rebel_tier3:s_a490d2c6", "m1_s89"} -- Alright.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s85)

ezkiel_convo_m1_s89 = ConvoScreen:new {
	id = "m1_s89",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8cf5321", -- The attack is led by an Imperial Inquisitor. He is your primary target. Kill him, and the attacking forces will scatter.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_d561a496", "m1_accept_c872184"} -- I will do my best.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s89)

ezkiel_convo_m1_accept_c872184 = ConvoScreen:new {
	id = "m1_accept_c872184",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c872184", -- I know you will. Now please hurry. There's not much time.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_accept_c872184)

ezkiel_convo_m1_s98 = ConvoScreen:new {
	id = "m1_s98",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a63013e4", -- It is a rendezvous point for the Vortex. It is, in many ways, our library. It holds our secrets.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_4f707592", "m1_s102"}, -- Does the Empire know that?
		{"@conversation/naboo_rebel_tier3:s_7d3deb6", "m1_2e3763ed"} -- Secrets about the Force crystals?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s98)

ezkiel_convo_m1_s102 = ConvoScreen:new {
	id = "m1_s102",
	leftDialog = "@conversation/naboo_rebel_tier3:s_1611aa95", -- I don't know. I hope to find out. In the meantime, I need you to defend that outpost...
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_ba11bd82", "m1_91a4e21b"} -- And?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_s102)

ezkiel_convo_m1_2e3763ed = ConvoScreen:new {
	id = "m1_2e3763ed",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2e3763ed", -- We want to learn more about how the Empire is using those crystals. Have you heard about their medical experiments?
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_d57982dc", "m1_d7eb327a"}, -- Yes. They're horrible.
		{"@conversation/naboo_rebel_tier3:s_1a1b97f4", "m1_88e20a47"} -- No. What experiments?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_2e3763ed)

ezkiel_convo_m1_91a4e21b = ConvoScreen:new {
	id = "m1_91a4e21b",
	leftDialog = "@conversation/naboo_rebel_tier3:s_91a4e21b", -- And give safe passage to someone on the station.
	options = {
		{"@conversation/naboo_rebel_tier3:s_deccbb06", "m1_accept_fb1d4add"} -- Who? A member of the Vortex?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_91a4e21b)

ezkiel_convo_m1_accept_fb1d4add = ConvoScreen:new {
	id = "m1_accept_fb1d4add",
	leftDialog = "@conversation/naboo_rebel_tier3:s_fb1d4add", -- Not exactly. Now please hurry. There's not much time.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_accept_fb1d4add)

ezkiel_convo_m1_d7eb327a = ConvoScreen:new {
	id = "m1_d7eb327a",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d7eb327a", -- There's no word for what they're doing. You must defend that outpost. We need that information.
	options = {
		{"@conversation/naboo_rebel_tier3:s_d55f2579", "m1_9f97864a"} -- I'm ready to go.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_d7eb327a)

ezkiel_convo_m1_88e20a47 = ConvoScreen:new {
	id = "m1_88e20a47",
	leftDialog = "@conversation/naboo_rebel_tier3:s_88e20a47", -- They have found a way to fuse a pilot forcibly to his ship, turning him into a cybernetic slave.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_e7150ae1", "m1_d3cb3651"} -- That's not possible.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_88e20a47)

ezkiel_convo_m1_9f97864a = ConvoScreen:new {
	id = "m1_9f97864a",
	leftDialog = "@conversation/naboo_rebel_tier3:s_9f97864a", -- There's more. You need to pick up someone on the station.
	options = {
		{"@conversation/naboo_rebel_tier3:s_a1217b89", "m1_accept_fb1d4add"} -- Who? Another member of the Vortex?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_9f97864a)

ezkiel_convo_m1_d3cb3651 = ConvoScreen:new {
	id = "m1_d3cb3651",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d3cb3651", -- It's evil, but not impossible. We must know more. And we need that outpost secured!
	options = {
		{"@conversation/naboo_rebel_tier3:s_d55f2579", "m1_28d86e3"} -- I'm ready to go.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_d3cb3651)

ezkiel_convo_m1_28d86e3 = ConvoScreen:new {
	id = "m1_28d86e3",
	leftDialog = "@conversation/naboo_rebel_tier3:s_28d86e3", -- There's more. You'll be picking up a new passenger at the outpost.
	options = {
		{"@conversation/naboo_rebel_tier3:s_a1217b89", "m1_accept_fb1d4add"} -- Who? Another member of the Vortex?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_28d86e3)

ezkiel_convo_m1_d001ebec = ConvoScreen:new {
	id = "m1_d001ebec",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d001ebec", -- We've attracted the attention of the Inquisition.
	options = {
		{"@conversation/naboo_rebel_tier3:s_d88c653e", "m1_5491ac40"} -- Are you sure?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_d001ebec)

ezkiel_convo_m1_5491ac40 = ConvoScreen:new {
	id = "m1_5491ac40",
	leftDialog = "@conversation/naboo_rebel_tier3:s_5491ac40", -- They are massing their forces for an attack on our outpost, even as we speak.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_cd53d6a8", "m1_e2e9a78f"} -- But do they know it's a Vortex outpost?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_5491ac40)

ezkiel_convo_m1_e2e9a78f = ConvoScreen:new {
	id = "m1_e2e9a78f",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e2e9a78f", -- It would seem so. We've always been very private about our activities there. I do not know how they found out about us.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fd120cac", "m1_10d9119c"}, -- Vrovel told me a bit about the Vortex - about what you do.
		{"@conversation/naboo_rebel_tier3:s_cd650ee8", "m1_c5c397c9"} -- The Empire is everywhere.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_e2e9a78f)

ezkiel_convo_m1_10d9119c = ConvoScreen:new {
	id = "m1_10d9119c",
	leftDialog = "@conversation/naboo_rebel_tier3:s_10d9119c", -- Ah, he did. And what did you think?
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5d126009", "m1_8a4f7617"}, -- [pause] Honestly?
		{"@conversation/naboo_rebel_tier3:s_d3b66245", "m1_b5be169d"} -- I think the Force exists.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_10d9119c)

ezkiel_convo_m1_c5c397c9 = ConvoScreen:new {
	id = "m1_c5c397c9",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c5c397c9", -- Danger lurks around every corner. We cannot be sure who is friend and who is foe.
	options = {
		{"@conversation/naboo_rebel_tier3:s_40b69b18", "m1_4ec95981"}, -- That's life during wartime.
		{"@conversation/naboo_rebel_tier3:s_b34ab6f6", "m1_2f820fac"} -- The Empire is DEFINITELY the enemy.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_c5c397c9)

ezkiel_convo_m1_8a4f7617 = ConvoScreen:new {
	id = "m1_8a4f7617",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8a4f7617", -- Please.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_3154a04f", "m1_a44e69af"} -- I think the Force is an old wives' tale.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_8a4f7617)

ezkiel_convo_m1_b5be169d = ConvoScreen:new {
	id = "m1_b5be169d",
	leftDialog = "@conversation/naboo_rebel_tier3:s_b5be169d", -- Not many people share your belief. We face opposition from within the Alliance, all the time.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_fca1dce9", "m1_189c01a2"} -- I've seen a lot of strange things out here. Anything's possible. That's what I think.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_b5be169d)

ezkiel_convo_m1_a44e69af = ConvoScreen:new {
	id = "m1_a44e69af",
	leftDialog = "@conversation/naboo_rebel_tier3:s_a44e69af", -- I see. Then we must seem like a silly group of old men to you.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_f4fff1e0", "m1_31a5e862"} -- No offense.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_a44e69af)

ezkiel_convo_m1_31a5e862 = ConvoScreen:new {
	id = "m1_31a5e862",
	leftDialog = "@conversation/naboo_rebel_tier3:s_31a5e862", -- None taken. Are you still willing to help us?
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_tier3:s_9d7c11a1", "m1_c3fb9152"} -- Of course. I'm a soldier.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_31a5e862)

ezkiel_convo_m1_c3fb9152 = ConvoScreen:new {
	id = "m1_c3fb9152",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c3fb9152", -- I appreciate that. Because we can use your help. The Empire is preparing to attack our outpost. We are in desperate need of your help.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_fc9a12c0", "m1_e9c7f196"} -- I'm ready to go. Just point the way.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_c3fb9152)

ezkiel_convo_m1_e9c7f196 = ConvoScreen:new {
	id = "m1_e9c7f196",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e9c7f196", -- We've uploaded the coordinates to your database. Be warned, an Imperial Inquisitor is leading the attack. He is your primary target.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_2c4789b", "m1_accept_21aa6c60"} -- Understood.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_e9c7f196)

ezkiel_convo_m1_accept_21aa6c60 = ConvoScreen:new {
	id = "m1_accept_21aa6c60",
	leftDialog = "@conversation/naboo_rebel_tier3:s_21aa6c60", -- You're free to leave.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_accept_21aa6c60)

ezkiel_convo_m1_189c01a2 = ConvoScreen:new {
	id = "m1_189c01a2",
	leftDialog = "@conversation/naboo_rebel_tier3:s_189c01a2", -- The Empire is preparing to attack our outpost. We are in desperate need of your help.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fc9a12c0", "m1_e9c7f196"} -- I'm ready to go. Just point the way.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_189c01a2)

ezkiel_convo_m1_4ec95981 = ConvoScreen:new {
	id = "m1_4ec95981",
	leftDialog = "@conversation/naboo_rebel_tier3:s_4ec95981", -- Yes it is, my cavalier young friend. But the Vortex must continue. Our work is too important. The Empire is preparing to attack our outpost. We are in desperate need of your help.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_fc9a12c0", "m1_e9c7f196"} -- I'm ready to go. Just point the way.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_4ec95981)

ezkiel_convo_m1_2f820fac = ConvoScreen:new {
	id = "m1_2f820fac",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2f820fac", -- To be sure. Vrovel has told you about their cybernetic experiments?
	options = {
		{"@conversation/naboo_rebel_tier3:s_6e6f308b", "m1_ebd3969d"} -- With the pilots? Yes he has. It makes me sick.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_2f820fac)

ezkiel_convo_m1_ebd3969d = ConvoScreen:new {
	id = "m1_ebd3969d",
	leftDialog = "@conversation/naboo_rebel_tier3:s_ebd3969d", -- No man should die that way. There is no end to the darkness in the heart of the Emperor. If he finds a way to harness the power of the Force, then our future will be bleak indeed.
	options = {
		{"@conversation/naboo_rebel_tier3:s_3950a8d4", "m1_e5f0e762"} -- They won't.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_ebd3969d)

ezkiel_convo_m1_e5f0e762 = ConvoScreen:new {
	id = "m1_e5f0e762",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e5f0e762", -- We have the opportunity to learn more about the Inquisition's activities. We have found an Imperial aide, someone who possesses a great deal of knowledge about the experiments and the Force Crystals. He is willing to tell us what he knows.
	options = {
		{"@conversation/naboo_rebel_tier3:s_841654d2", "m1_54abba14"} -- That's great news!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_e5f0e762)

ezkiel_convo_m1_54abba14 = ConvoScreen:new {
	id = "m1_54abba14",
	leftDialog = "@conversation/naboo_rebel_tier3:s_54abba14", -- Perhaps. In the meantime, there's the business of our outpost. The Empire is preparing to attack. We are in desperate need of your help.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fc9a12c0", "m1_e9c7f196"} -- I'm ready to go. Just point the way.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m1_54abba14)

ezkiel_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/naboo_rebel_tier3:s_3f38ab04", -- Thank you, %NU. Our library is safe now.
	options = {
		{"@conversation/naboo_rebel_tier3:s_2f1094c2", "m2_27f52134"}, -- My pleasure. That Inquisitor put up a good fight.
		{"@conversation/naboo_rebel_tier3:s_8b1d3cb", "m2_930d070e"} -- Is it? I don't know. The Empire will probably send more forces.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_offer)

ezkiel_convo_m2_27f52134 = ConvoScreen:new {
	id = "m2_27f52134",
	leftDialog = "@conversation/naboo_rebel_tier3:s_27f52134", -- That's quite the understatement.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_590bda59", "m2_f0300e70"} -- Well, it's over now. And I've delivered the information to the Sypnet outpost, as ordered.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_27f52134)

ezkiel_convo_m2_930d070e = ConvoScreen:new {
	id = "m2_930d070e",
	leftDialog = "@conversation/naboo_rebel_tier3:s_930d070e", -- The Empire is ambitious. They will continue to unleash their forces against us. They are extremely interested in what we know. And, of course, we are equally interested in what THEY know.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_9f3f2aef", "m2_63e41"} -- Know about what?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_930d070e)

ezkiel_convo_m2_f0300e70 = ConvoScreen:new {
	id = "m2_f0300e70",
	leftDialog = "@conversation/naboo_rebel_tier3:s_f0300e70", -- Yes. Well unfortunately things have become more complicated. Have you ever dealt with Bothans before?
	options = {
		{"@conversation/naboo_rebel_tier3:s_4c695dbd", "m2_e711b5e8"}, -- No.
		{"@conversation/naboo_rebel_tier3:s_d70dba34", "m2_8874f806"}, -- Yes.
		{"@conversation/naboo_rebel_tier3:s_1d69f13f", "m2_2600dae8"} -- No. Are you sending me to fight against the Bothans?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_f0300e70)

ezkiel_convo_m2_e711b5e8 = ConvoScreen:new {
	id = "m2_e711b5e8",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e711b5e8", -- Maddening creatures.
	options = {
		{"@conversation/naboo_rebel_tier3:s_f845f64a", "m2_d15e12a8"} -- They're a lot like you. They always want information.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_e711b5e8)

ezkiel_convo_m2_8874f806 = ConvoScreen:new {
	id = "m2_8874f806",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8874f806", -- Then you know how crafty they can be.
	options = {
		{"@conversation/naboo_rebel_tier3:s_5fec5259", "m2_d5ad9570"} -- No craftier than the spy at that outpost.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_8874f806)

ezkiel_convo_m2_2600dae8 = ConvoScreen:new {
	id = "m2_2600dae8",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2600dae8", -- No, not exactly. You will be fighting FOR Bothans. Nym's pirates are attacking one of their bases. They're outgunned, and they need our help.
	options = {
		{"@conversation/naboo_rebel_tier3:s_1f94856d", "m2_7af82252"} -- Why are you helping the Bothans?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_2600dae8)

ezkiel_convo_m2_d15e12a8 = ConvoScreen:new {
	id = "m2_d15e12a8",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d15e12a8", -- We want information. They want secrets. There is a difference.
	options = {
		{"@conversation/naboo_rebel_tier3:s_31b106e4", "m2_515906d2"} -- Well, you were working with that informer. I'm sure he had some secrets.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_d15e12a8)

ezkiel_convo_m2_515906d2 = ConvoScreen:new {
	id = "m2_515906d2",
	leftDialog = "@conversation/naboo_rebel_tier3:s_515906d2", -- That spy, you mean! Yes, we were working with him, as you say. We had no choice, unsavory though he was. And now we have his data. It may explain everything about the cybernetic experiments and the Empire's interest in Force Crystals. But it's not in a language we understand.
	options = {
		{"@conversation/naboo_rebel_tier3:s_ea78d92a", "m2_f68ef5df"} -- Do you need a translation? Bothans are master translators.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_515906d2)

ezkiel_convo_m2_f68ef5df = ConvoScreen:new {
	id = "m2_f68ef5df",
	leftDialog = "@conversation/naboo_rebel_tier3:s_f68ef5df", -- Yes, they are. Now you see why we need their help. But it's quid pro quo. First, WE must help THEM.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5cfd5571", "m2_19fdbf16"} -- The Bothans are holding out on you?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_f68ef5df)

ezkiel_convo_m2_19fdbf16 = ConvoScreen:new {
	id = "m2_19fdbf16",
	leftDialog = "@conversation/naboo_rebel_tier3:s_19fdbf16", -- That's one way to put it. They won't translate the data until they get what they want.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_133ae1ef", "m2_1c058156"} -- Sounds like they don't care much about the Force!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_19fdbf16)

ezkiel_convo_m2_1c058156 = ConvoScreen:new {
	id = "m2_1c058156",
	leftDialog = "@conversation/naboo_rebel_tier3:s_1c058156", -- A Bothan base is under attack by Nym's pirates. They are in trouble and need defenders.
	options = {
		{"@conversation/naboo_rebel_tier3:s_5d2275e3", "m2_c9e0d4f1"} -- And I'm playing defense?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_1c058156)

ezkiel_convo_m2_c9e0d4f1 = ConvoScreen:new {
	id = "m2_c9e0d4f1",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c9e0d4f1", -- If you would.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_eba35f17", "m2_accept_cb3876f5"} -- When do I leave?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_c9e0d4f1)

ezkiel_convo_m2_accept_cb3876f5 = ConvoScreen:new {
	id = "m2_accept_cb3876f5",
	leftDialog = "@conversation/naboo_rebel_tier3:s_cb3876f5", -- Immediately. Coordinates are already in your ship database. Thank you for your help.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_accept_cb3876f5)

ezkiel_convo_m2_d5ad9570 = ConvoScreen:new {
	id = "m2_d5ad9570",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d5ad9570", -- The less said about him, the better.
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_rebel_tier3:s_1dccb274", "m2_81f74c8a"} -- He had useful information, at least.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_d5ad9570)

ezkiel_convo_m2_81f74c8a = ConvoScreen:new {
	id = "m2_81f74c8a",
	leftDialog = "@conversation/naboo_rebel_tier3:s_81f74c8a", -- His data may explain everything about the cybernetic experiments and the Empire's interest in Force Crystals. Or it may be a recipe for chocolate cake. We don't know. It's encrypted.  We need the Bothans to translate it.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_bb3b47bf", "m2_c5fd31d9"} -- But first? It sounds like there's a problem.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_81f74c8a)

ezkiel_convo_m2_c5fd31d9 = ConvoScreen:new {
	id = "m2_c5fd31d9",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c5fd31d9", -- You're right. First we must help the Bothans.
	animation = "tap_head",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5bd69df6", "m2_9a2a8f72"} -- What do you need me to do?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_c5fd31d9)

ezkiel_convo_m2_9a2a8f72 = ConvoScreen:new {
	id = "m2_9a2a8f72",
	leftDialog = "@conversation/naboo_rebel_tier3:s_9a2a8f72", -- A Bothan base is under attack by Nym's pirates. They are in trouble and need defenders. They are spies, not soldiers.
	options = {
		{"@conversation/naboo_rebel_tier3:s_5d2275e3", "m2_c9e0d4f1"} -- And I'm playing defense?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_9a2a8f72)

ezkiel_convo_m2_7af82252 = ConvoScreen:new {
	id = "m2_7af82252",
	leftDialog = "@conversation/naboo_rebel_tier3:s_7af82252", -- Because I must. The informer's data is encrypted. Only the Bothans can translate it.
	options = {
		{"@conversation/naboo_rebel_tier3:s_a6792612", "m2_97c42bb7"} -- And they won't help until we secure their base.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_7af82252)

ezkiel_convo_m2_97c42bb7 = ConvoScreen:new {
	id = "m2_97c42bb7",
	leftDialog = "@conversation/naboo_rebel_tier3:s_97c42bb7", -- Of course. That's how Bothans are. Nothing is free.
	animation = "rub_belly",
	options = {
		{"@conversation/naboo_rebel_tier3:s_eba35f17", "m2_accept_f8a22f8"} -- When do I leave?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_97c42bb7)

ezkiel_convo_m2_accept_f8a22f8 = ConvoScreen:new {
	id = "m2_accept_f8a22f8",
	leftDialog = "@conversation/naboo_rebel_tier3:s_f8a22f8", -- Immediately. Coordinates are already in your ship database.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_accept_f8a22f8)

ezkiel_convo_m2_63e41 = ConvoScreen:new {
	id = "m2_63e41",
	leftDialog = "@conversation/naboo_rebel_tier3:s_63e41", -- About the Force. The Inquisitors have dedicated their lives to the pursuit of that knowledge. We have done the same. And now we have that informer's information.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_7eab0dc3", "m2_22fbdd51"} -- So even though he was an Imperial spy, he was carrying useful information after all!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_63e41)

ezkiel_convo_m2_22fbdd51 = ConvoScreen:new {
	id = "m2_22fbdd51",
	leftDialog = "@conversation/naboo_rebel_tier3:s_22fbdd51", -- His databank may hold all the secrets of the Force crystals, and every dark detail of the Empire's cybernetic experiments. But we don't know yet. The information is encrypted. And only the Bothans can translate it.
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_tier3:s_170add4", "m2_c20e6f2b"} -- Perfect! The Bothans have the data now. I delivered it myself!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_22fbdd51)

ezkiel_convo_m2_c20e6f2b = ConvoScreen:new {
	id = "m2_c20e6f2b",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c20e6f2b", -- Ah, but it's not so simple. The Bothans have made a small request.
	options = {
		{"@conversation/naboo_rebel_tier3:s_45c4d2ca", "m2_61b6494b"} -- Uh oh. I smell trouble.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_c20e6f2b)

ezkiel_convo_m2_61b6494b = ConvoScreen:new {
	id = "m2_61b6494b",
	leftDialog = "@conversation/naboo_rebel_tier3:s_61b6494b", -- Am I that transparent? Oh dear. I would be a terrible diplomat, I'm afraid. You are correct.  A Bothan base is under attack by Nym's pirates. They are in trouble and need defenders. They are spies, not soldiers.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5d2275e3", "m2_c9e0d4f1"} -- And I'm playing defense?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m2_61b6494b)

ezkiel_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/naboo_rebel_tier3:s_8287425f", -- Well done. You gave those pirates a run for their money.
	animation = "greet",
	options = {
		{"@conversation/naboo_rebel_tier3:s_1ab74446", "m3_2c1e1068"}, -- You noticed.
		{"@conversation/naboo_rebel_tier3:s_9cc8e2ce", "m3_e5e9b349"} -- I'm ready for another mission.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_offer)

ezkiel_convo_m3_2c1e1068 = ConvoScreen:new {
	id = "m3_2c1e1068",
	leftDialog = "@conversation/naboo_rebel_tier3:s_2c1e1068", -- I'm not the only one. The Bothans are most grateful.
	options = {
		{"@conversation/naboo_rebel_tier3:s_98332b2a", "m3_d40fde1"} -- Anytime.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_2c1e1068)

ezkiel_convo_m3_e5e9b349 = ConvoScreen:new {
	id = "m3_e5e9b349",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e5e9b349", -- The Bothans want those pirates destroyed, once and for all. And you can help them.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fcf4d778", "m3_9865d5b5"} -- How?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_e5e9b349)

ezkiel_convo_m3_d40fde1 = ConvoScreen:new {
	id = "m3_d40fde1",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d40fde1", -- Anytime, you say? Well, how about right now? They'd like to enlist your services again.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_eb5863d5", "m3_51fbaf83"} -- You're awfully quick to help Bothans. I thought you hated them.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_d40fde1)

ezkiel_convo_m3_51fbaf83 = ConvoScreen:new {
	id = "m3_51fbaf83",
	leftDialog = "@conversation/naboo_rebel_tier3:s_51fbaf83", -- We need information. They can provide it. That's all. Personal feelings don't come into it.
	animation = "shiver",
	options = {
		{"@conversation/naboo_rebel_tier3:s_5f5ad8b2", "m3_d786a9a7"} -- You're dedicated.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_51fbaf83)

ezkiel_convo_m3_d786a9a7 = ConvoScreen:new {
	id = "m3_d786a9a7",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d786a9a7", -- Nothing is more important than those Force crystals. Now you must help us, and quickly.
	options = {
		{"@conversation/naboo_rebel_tier3:s_fcf4d778", "m3_abd40fb"} -- How?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_d786a9a7)

ezkiel_convo_m3_abd40fb = ConvoScreen:new {
	id = "m3_abd40fb",
	leftDialog = "@conversation/naboo_rebel_tier3:s_abd40fb", -- With you by their side, the Bothans see an opportunity to defeat these pirates once and for all.
	animation = "explain",
	options = {
		{"@conversation/naboo_rebel_tier3:s_da08554e", "m3_aa11d5d2"} -- But the pirate fleet is huge! I can't kill them all.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_abd40fb)

ezkiel_convo_m3_aa11d5d2 = ConvoScreen:new {
	id = "m3_aa11d5d2",
	leftDialog = "@conversation/naboo_rebel_tier3:s_aa11d5d2", -- You only need to kill their leader.
	animation = "tap_head",
	options = {
		{"@conversation/naboo_rebel_tier3:s_ba42ea16", "m3_96483773"} -- You say that like it's easy.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_aa11d5d2)

ezkiel_convo_m3_96483773 = ConvoScreen:new {
	id = "m3_96483773",
	leftDialog = "@conversation/naboo_rebel_tier3:s_96483773", -- Oh no. Have no illusions, it will be difficult. But you will have the element of surprise.
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_rebel_tier3:s_2330166f", "m3_d611f5ae"} -- I'll say. Rebel forces hardly ever attack pirates.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_96483773)

ezkiel_convo_m3_d611f5ae = ConvoScreen:new {
	id = "m3_d611f5ae",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d611f5ae", -- All's fair in love and war.
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_rebel_tier3:s_6a273da9", "m3_accept_68355d90"} -- I'm ready to go. Where is this leader's ship?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_d611f5ae)

ezkiel_convo_m3_accept_68355d90 = ConvoScreen:new {
	id = "m3_accept_68355d90",
	leftDialog = "@conversation/naboo_rebel_tier3:s_68355d90", -- We've uploaded general coordinates in the Endor system, but you'll have to find his exact location yourself, I'm afraid. Good luck.
	stopConversation = "true",
	animation = "bow",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_accept_68355d90)

ezkiel_convo_m3_9865d5b5 = ConvoScreen:new {
	id = "m3_9865d5b5",
	leftDialog = "@conversation/naboo_rebel_tier3:s_9865d5b5", -- Destroy their leader ship. Without it, the pirate fleet will flounder - and that's exactly what the Bothans want.
	options = {
		{"@conversation/naboo_rebel_tier3:s_cdcbf519", "m3_ef42359f"} -- What do YOU want?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_9865d5b5)

ezkiel_convo_m3_ef42359f = ConvoScreen:new {
	id = "m3_ef42359f",
	leftDialog = "@conversation/naboo_rebel_tier3:s_ef42359f", -- I want information on those Force crystals. And the Bothans are going to give it to me!
	animation = "pound_fist_palm",
	options = {
		{"@conversation/naboo_rebel_tier3:s_d5f9f79b", "m3_accept_18c308e1"} -- But only if I do my job.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_ef42359f)

ezkiel_convo_m3_accept_18c308e1 = ConvoScreen:new {
	id = "m3_accept_18c308e1",
	leftDialog = "@conversation/naboo_rebel_tier3:s_18c308e1", -- The leader ship is doing its best to keep a low profile. You'll have to hunt it down in the Endor system. Good luck.
	stopConversation = "true",
	animation = "bow2",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m3_accept_18c308e1)

ezkiel_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/naboo_rebel_tier3:s_fffd9426", -- The Bothans have delivered their translations, as promised.
	animation = "beckon",
	options = {
		{"@conversation/naboo_rebel_tier3:s_3c566f87", "m4_b70082a7"}, -- I should hope so! How many favors are they going to ask of us?
		{"@conversation/naboo_rebel_tier3:s_9e4cb685", "m4_d41d97bf"} -- Excellent! They must reveal something about the Empire's plans.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_offer)

ezkiel_convo_m4_b70082a7 = ConvoScreen:new {
	id = "m4_b70082a7",
	leftDialog = "@conversation/naboo_rebel_tier3:s_b70082a7", -- The Spynet's quite pleased. I think you've shut those pirates down, once and for all. This will help us in the future. Bothans are good friends to have.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_420c68fc", "m4_d764414f"} -- I thought you hated them! You're confusing me.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_b70082a7)

ezkiel_convo_m4_d41d97bf = ConvoScreen:new {
	id = "m4_d41d97bf",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d41d97bf", -- Things are coming to a head in this system. Imperial forces are launching a major assault.
	options = {
		{"@conversation/naboo_rebel_tier3:s_93c9d623", "m4_bc7aea36"} -- What about Alliance forces?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_d41d97bf)

ezkiel_convo_m4_d764414f = ConvoScreen:new {
	id = "m4_d764414f",
	leftDialog = "@conversation/naboo_rebel_tier3:s_d764414f", -- Hate is a tool of the Dark Side. I must learn to control my feelings. It is not easy.
	animation = "sigh_deeply",
	options = {
		{"@conversation/naboo_rebel_tier3:s_26fbd13e", "m4_58ec27cc"} -- If you were a pilot, you wouldn't have to control your feelings. You could vent them with your blasters!
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_d764414f)

ezkiel_convo_m4_58ec27cc = ConvoScreen:new {
	id = "m4_58ec27cc",
	leftDialog = "@conversation/naboo_rebel_tier3:s_58ec27cc", -- Ha! True enough. But you have your destiny, and I have mine.
	animation = "laugh",
	options = {
		{"@conversation/naboo_rebel_tier3:s_4869a9c5", "m4_47ae0171"} -- What was in the translated data?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_58ec27cc)

ezkiel_convo_m4_47ae0171 = ConvoScreen:new {
	id = "m4_47ae0171",
	leftDialog = "@conversation/naboo_rebel_tier3:s_47ae0171", -- The rumors are true.  Imperial doctors have found a way to create hybrid, cybernetic pilots.
	options = {
		{"@conversation/naboo_rebel_tier3:s_a64028fc", "m4_92ecc2cf"} -- Why would the Empire force loyal soldiers into those kind of experiments?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_47ae0171)

ezkiel_convo_m4_92ecc2cf = ConvoScreen:new {
	id = "m4_92ecc2cf",
	leftDialog = "@conversation/naboo_rebel_tier3:s_92ecc2cf", -- The Empire will do anything to gain the edge in this war.
	options = {
		{"@conversation/naboo_rebel_tier3:s_8a212117", "m4_c1e154f"} -- Sick.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_92ecc2cf)

ezkiel_convo_m4_c1e154f = ConvoScreen:new {
	id = "m4_c1e154f",
	leftDialog = "@conversation/naboo_rebel_tier3:s_c1e154f", -- Sick - but efficient. These cybernetic pilots never question orders, and they never sleep, never eat.
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_rebel_tier3:s_ed8cbd3f", "m4_e77894ce"} -- So they're just killing machines.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_c1e154f)

ezkiel_convo_m4_e77894ce = ConvoScreen:new {
	id = "m4_e77894ce",
	leftDialog = "@conversation/naboo_rebel_tier3:s_e77894ce", -- I hope they ARE machines - for their sake. Can you imagine being trapped in your own body like that?
	options = {
		{"@conversation/naboo_rebel_tier3:s_c5c41a6", "m4_f92771aa"} -- No. Are these pilots flying for the Empire?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_e77894ce)

ezkiel_convo_m4_f92771aa = ConvoScreen:new {
	id = "m4_f92771aa",
	leftDialog = "@conversation/naboo_rebel_tier3:s_f92771aa", -- Not yet. But they will be, soon. And Imperial forces are launching a huge attack now, to soften the ground.
	options = {
		{"@conversation/naboo_rebel_tier3:s_e494ecca", "m4_accept_aa7a038e"} -- Then what am I doing here on the ground?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_f92771aa)

ezkiel_convo_m4_accept_aa7a038e = ConvoScreen:new {
	id = "m4_accept_aa7a038e",
	leftDialog = "@conversation/naboo_rebel_tier3:s_aa7a038e", -- Talking to me - but you're leaving for the Dathomir system, as of now. Take out those Imperials!
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_accept_aa7a038e)

ezkiel_convo_m4_bc7aea36 = ConvoScreen:new {
	id = "m4_bc7aea36",
	leftDialog = "@conversation/naboo_rebel_tier3:s_bc7aea36", -- They're holding their own, but just barely.
	options = {
		{"@conversation/naboo_rebel_tier3:s_82cf4ca7", "m4_39b859cf"} -- Why is the Empire targeting this system? Is it because of you?
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_bc7aea36)

ezkiel_convo_m4_39b859cf = ConvoScreen:new {
	id = "m4_39b859cf",
	leftDialog = "@conversation/naboo_rebel_tier3:s_39b859cf", -- I don't know, young one. But I think that very soon WE will be attacking THEM. In the meantime, though, we will simply defend our position and help our Alliance brothers.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_rebel_tier3:s_6bdcb65c", "m4_accept_b24e355f"} -- Just tell me where to go.
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_39b859cf)

ezkiel_convo_m4_accept_b24e355f = ConvoScreen:new {
	id = "m4_accept_b24e355f",
	leftDialog = "@conversation/naboo_rebel_tier3:s_b24e355f", -- You'll find your coordinates in your ships computer. Take off for the Dathomir system immediately. Good luck.
	stopConversation = "true",
	options = {
	}
}
ezkiel_convo_template:addScreen(ezkiel_convo_m4_accept_b24e355f)

addConversationTemplate("ezkiel_convo_template", ezkiel_convo_template)
