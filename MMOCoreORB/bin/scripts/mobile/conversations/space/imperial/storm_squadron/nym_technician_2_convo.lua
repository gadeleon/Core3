-- Nym fuel technician 2 on Lok conversation (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_2 is lost; TB row 36); feature storm-tier2-nym-technicians. Handler: nymTechnician2ConvoHandler.
nym_technician_2_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "nymTechnician2ConvoHandler",
	screens = {}
}

nym_technician_2_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/nym_technician_2:s_6aa58622", -- I'm really, really busy. It's a complete mess around here. The Empire has been laying it into Nym for some reason and the damaged ships keep rolling in. I've had to replace two engine cores today alone!
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_2:s_8358e7c8", "sob_story"}, -- I'm sorry to hear that.
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_greeting)

nym_technician_2_convo_greeting_agent = ConvoScreen:new {
	id = "greeting_agent",
	leftDialog = "@conversation/nym_technician_2:s_6aa58622", -- I'm really, really busy. It's a complete mess around here. The Empire has been laying it into Nym for some reason and the damaged ships keep rolling in. I've had to replace two engine cores today alone!
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_2:s_67a590c3", "snaff_grease"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_2:s_62f865dd", "scrub_the"}, -- I'm here to scrub the plasma injector.
		{"@conversation/nym_technician_2:s_f49a789f", "dont_get_it"}, -- I'm here to wax the matter inducer.
		{"@conversation/nym_technician_2:s_8358e7c8", "sob_story"}, -- I'm sorry to hear that.
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_greeting_agent)

nym_technician_2_convo_sob_story = ConvoScreen:new {
	id = "sob_story",
	leftDialog = "@conversation/nym_technician_2:s_4c3cb236", -- Yeah, well it's my sob story. Beat it so I can get to work. I don't think you're supposed to be back here anyway.
	stopConversation = "true",
	options = {
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_sob_story)

nym_technician_2_convo_snaff_grease = ConvoScreen:new {
	id = "snaff_grease",
	leftDialog = "@conversation/nym_technician_2:s_cbb1bec7", -- Clean the antimatter condenser? Well...yeah I suppose it's probably getting a little jammed with all of the work we've been putting it through. You can find the Snaff Grease in the back. Hurry up though, there's probably a bunch of ships waiting to be fueled up.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_2:s_76ac95c", "get_moving"}, -- Uh...okay...
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_snaff_grease)

nym_technician_2_convo_get_moving = ConvoScreen:new {
	id = "get_moving",
	leftDialog = "@conversation/nym_technician_2:s_b7141451", -- Get moving now.
	stopConversation = "true",
	options = {
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_get_moving)

nym_technician_2_convo_scrub_the = ConvoScreen:new {
	id = "scrub_the",
	leftDialog = "@conversation/nym_technician_2:s_501ea131", -- Scrub the? Excuse me?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_2:s_62f865dd", "jeffy"}, -- I'm here to scrub the plasma injector.
		{"@conversation/nym_technician_2:s_67a590c3", "snaff_grease"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_2:s_f49a789f", "dont_get_it"}, -- I'm here to wax the matter inducer.
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_scrub_the)

nym_technician_2_convo_jeffy = ConvoScreen:new {
	id = "jeffy",
	leftDialog = "@conversation/nym_technician_2:s_b0c60048", -- What? You don't scrub a plasma injector. Those things are stored in sealed containers and fused into engines. Is this some kind of joke? Did Jeffy put you up to this?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_2:s_5afecbb7", "funny"}, -- Uh...yeah Jeffy. Funny huh?
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_jeffy)

nym_technician_2_convo_funny = ConvoScreen:new {
	id = "funny",
	leftDialog = "@conversation/nym_technician_2:s_60900624", -- Hahaha! That's funny stuff!
	stopConversation = "true",
	options = {
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_funny)

nym_technician_2_convo_dont_get_it = ConvoScreen:new {
	id = "dont_get_it",
	leftDialog = "@conversation/nym_technician_2:s_b44f916c", -- I don't get it. Look, I'm really busy. Can you come back later?
	stopConversation = "true",
	options = {
	}
}
nym_technician_2_convo_template:addScreen(nym_technician_2_convo_dont_get_it)

addConversationTemplate("nym_technician_2_convo_template", nym_technician_2_convo_template)
