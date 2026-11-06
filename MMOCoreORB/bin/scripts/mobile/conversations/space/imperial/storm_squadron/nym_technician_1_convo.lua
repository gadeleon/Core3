-- Nym fuel technician 1 on Lok conversation (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_1 is lost; TB row 37); feature storm-tier2-nym-technicians. Handler: nymTechnician1ConvoHandler.
nym_technician_1_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "nymTechnician1ConvoHandler",
	screens = {}
}

nym_technician_1_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/nym_technician_1:s_ccc723ff", -- I'm really busy at the moment. Five wrecks and three borderline cases so far today. The Empire is really bringing it to Nym. I've got to get that blaster cylinder back online and it's probably going to take all day.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_ced0fec8", "in_your_way"}, -- Oh, don't let me get in your way.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_greeting)

nym_technician_1_convo_greeting_agent = ConvoScreen:new {
	id = "greeting_agent",
	leftDialog = "@conversation/nym_technician_1:s_ccc723ff", -- I'm really busy at the moment. Five wrecks and three borderline cases so far today. The Empire is really bringing it to Nym. I've got to get that blaster cylinder back online and it's probably going to take all day.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_67a590c3", "codephrase_ok"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_1:s_62f865dd", "huh"}, -- I'm here to scrub the plasma injector.
		{"@conversation/nym_technician_1:s_35de4fcc", "what_did_you_say"}, -- I'm here to wax the matter infuser.
		{"@conversation/nym_technician_1:s_ced0fec8", "in_your_way"}, -- Oh, don't let me get in your way.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_greeting_agent)

nym_technician_1_convo_in_your_way = ConvoScreen:new {
	id = "in_your_way",
	leftDialog = "@conversation/nym_technician_1:s_aae05f6b", -- I won't. You should probably take off, this area is supposed to be cordoned off.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_in_your_way)

nym_technician_1_convo_huh = ConvoScreen:new {
	id = "huh",
	leftDialog = "@conversation/nym_technician_1:s_135c7b04", -- You're here to...huh?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_67a590c3", "codephrase_ok"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_1:s_35de4fcc", "wrong_guy"}, -- I'm here to wax the matter infuser.
		{"@conversation/nym_technician_1:s_169df3bb", "cordoned"}, -- Never mind.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_huh)

nym_technician_1_convo_what_did_you_say = ConvoScreen:new {
	id = "what_did_you_say",
	leftDialog = "@conversation/nym_technician_1:s_8d9eefec", -- What did you say?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_67a590c3", "codephrase_ok"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_1:s_62f865dd", "wrong_guy"}, -- I'm here to scrub the plasma injector.
		{"@conversation/nym_technician_1:s_169df3bb", "cordoned"}, -- Never mind.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_what_did_you_say)

nym_technician_1_convo_wrong_guy = ConvoScreen:new {
	id = "wrong_guy",
	leftDialog = "@conversation/nym_technician_1:s_dce481f1", -- Sorry, you've got the wrong guy. I don't handle engine work.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_wrong_guy)

nym_technician_1_convo_cordoned = ConvoScreen:new {
	id = "cordoned",
	leftDialog = "@conversation/nym_technician_1:s_2d587639", -- This area is supposed to be cordoned off.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_cordoned)

nym_technician_1_convo_codephrase_ok = ConvoScreen:new {
	id = "codephrase_ok",
	leftDialog = "@conversation/nym_technician_1:s_66c37cce", -- Shh! Quiet. I can't believe the Empire sent someone here after what happened to the other agents.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_395d4c4", "nym_organize"}, -- Your report indicated a possible attack...
		{"@conversation/nym_technician_1:s_37dad091", "blown_cover"}, -- I'm here to find out Nym's plans.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_codephrase_ok)

nym_technician_1_convo_blown_cover = ConvoScreen:new {
	id = "blown_cover",
	leftDialog = "@conversation/nym_technician_1:s_42e8bcae", -- Well, you've probably only managed to blow my cover! Nym doesn't have any plans. He's too busy putting out fires and keeping his upper leadership from falling apart. The pressure the Empire has been putting on the organization has really started to test Nym's leadership.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_395d4c4", "nym_organize"}, -- Your report indicated a possible attack...
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_blown_cover)

nym_technician_1_convo_nym_organize = ConvoScreen:new {
	id = "nym_organize",
	leftDialog = "@conversation/nym_technician_1:s_ed4d7aa6", -- Nym wants to organize something. Push the Empire back so he can start rebuilding. He's probably here for the long haul, but the Empire's assaults have definitely made him less likely to support the Rebels openly.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_536a83dc", "five_captains"}, -- So what is he trying to organize?
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_nym_organize)

nym_technician_1_convo_five_captains = ConvoScreen:new {
	id = "five_captains",
	leftDialog = "@conversation/nym_technician_1:s_9518acb5", -- I don't know. He's called for five of his captains to meet and work out details for a massive response. They're preparing to leave soon on a YT-1300. The plan is to review the damage to Nym's fleet and then discuss how best to proceed...
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_c70b951e", "lobotomize"}, -- YT-1300? If I can find that ship...
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_five_captains)

nym_technician_1_convo_lobotomize = ConvoScreen:new {
	id = "lobotomize",
	leftDialog = "@conversation/nym_technician_1:s_d724a599", -- You could lobotomize Nym's command structure. Nym wouldn't have much of a chance to mount any kind of significant response if that happened.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_81e175a9", "find_zabrak"}, -- How can I find that ship?
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_lobotomize)

nym_technician_1_convo_find_zabrak = ConvoScreen:new {
	id = "find_zabrak",
	leftDialog = "@conversation/nym_technician_1:s_3b4b03fd", -- There is another fuel technician that might know. She's should be around here somewhere. Pretty Zabrak, no tattoos, won't come with me to the cantina. You shouldn't have any trouble finding her. Tell her that you think the fuel balance on the 'Kimogila's Claw' is wrong and you need to check it. That should get you access to the ship.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_b8779a78", "take_off"}, -- I'm going there now.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_find_zabrak)

nym_technician_1_convo_take_off = ConvoScreen:new {
	id = "take_off",
	leftDialog = "@conversation/nym_technician_1:s_3345f404", -- You better take off or you'll blow my cover.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_take_off)

nym_technician_1_convo_back_again = ConvoScreen:new {
	id = "back_again",
	leftDialog = "@conversation/nym_technician_1:s_e727edeb", -- What are you doing back here? Didn't I tell you to take off or you would blow my cover?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_81e175a9", "find_zabrak"}, -- How can I find that ship?
		{"@conversation/nym_technician_1:s_b8779a78", "good_luck"}, -- I'm going there now.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_back_again)

nym_technician_1_convo_good_luck = ConvoScreen:new {
	id = "good_luck",
	leftDialog = "@conversation/nym_technician_1:s_90422eb5", -- Good luck.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_good_luck)

nym_technician_1_convo_claw_destroyed = ConvoScreen:new {
	id = "claw_destroyed",
	leftDialog = "@conversation/nym_technician_1:s_51f0669b", -- You did? Excellent. High Command will be pleased. You should try to get off Lok as soon as possible. Inform the Fleet of your success.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_273b318b", "you_too"}, -- You don't have to tell me twice. Good luck.
		{"@conversation/nym_technician_1:s_e15acd61", "cant_leave"}, -- Thanks. You better get out of here.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_claw_destroyed)

nym_technician_1_convo_you_too = ConvoScreen:new {
	id = "you_too",
	leftDialog = "@conversation/nym_technician_1:s_39510e77", -- You too.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_you_too)

nym_technician_1_convo_cant_leave = ConvoScreen:new {
	id = "cant_leave",
	leftDialog = "@conversation/nym_technician_1:s_3e5e55b6", -- I can't leave without authorization from command.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_1:s_5c3323fd", "in_the_clear"}, -- Then keep your head down.
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_cant_leave)

nym_technician_1_convo_in_the_clear = ConvoScreen:new {
	id = "in_the_clear",
	leftDialog = "@conversation/nym_technician_1:s_a84adf58", -- I'll be fine here. I think I'm still in the clear.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_in_the_clear)

nym_technician_1_convo_keep_trying = ConvoScreen:new {
	id = "keep_trying",
	leftDialog = "@conversation/nym_technician_1:s_ccc1622", -- Shhhhh. What are you telling me for? I don't want to know anything about that. All I can tell you is if you are going to try to blow up a ship full of Nym's men, you better not stop until you succeed. Now beat it.
	stopConversation = "true",
	options = {
	}
}
nym_technician_1_convo_template:addScreen(nym_technician_1_convo_keep_trying)

addConversationTemplate("nym_technician_1_convo_template", nym_technician_1_convo_template)
