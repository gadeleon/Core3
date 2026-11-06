-- Nym fuel technician 3 on Lok conversation (Storm Squadron tier 2). Rebuilt from the pre-NGE client lines only (SWG-Source's script.conversation.nym_technician_3 is lost; TB row 56); feature storm-tier2-nym-technicians. Handler: nymTechnician3ConvoHandler.
nym_technician_3_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "nymTechnician3ConvoHandler",
	screens = {}
}

nym_technician_3_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/nym_technician_3:s_76b02ea3", -- Can I help you? This is a restricted area right now. We've had a lot of damaged ships come in and this area is cordoned off for repairs.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_88d98675", "pilot_ship"}, -- Oh yeah. Um, sorry about that.
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_greeting)

nym_technician_3_convo_greeting_agent = ConvoScreen:new {
	id = "greeting_agent",
	leftDialog = "@conversation/nym_technician_3:s_76b02ea3", -- Can I help you? This is a restricted area right now. We've had a lot of damaged ships come in and this area is cordoned off for repairs.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_67a590c3", "ahead_of_schedule"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_3:s_62f865dd", "pilot_slang"}, -- I'm here to scrub the plasma injector.
		{"@conversation/nym_technician_3:s_f49a789f", "disgusting"}, -- I'm here to wax the matter inducer.
		{"@conversation/nym_technician_3:s_88d98675", "pilot_ship"}, -- Oh yeah. Um, sorry about that.
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_greeting_agent)

nym_technician_3_convo_pilot_ship = ConvoScreen:new {
	id = "pilot_ship",
	leftDialog = "@conversation/nym_technician_3:s_544505bd", -- Look, if you're a pilot, you can check on your ship later. Most of these are going to be junk, but we might be able to save a few.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_pilot_ship)

nym_technician_3_convo_ahead_of_schedule = ConvoScreen:new {
	id = "ahead_of_schedule",
	leftDialog = "@conversation/nym_technician_3:s_54711fd3", -- You are? You're ahead of schedule. Our condenser has been working fine as far as I can tell. The thing isn't scheduled for maintenance for five cycles. Why don't you just clear out and let me focus on my repairs?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_1ebf6580", "five_cycles"}, -- Uh, okay I'll do that.
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_ahead_of_schedule)

nym_technician_3_convo_five_cycles = ConvoScreen:new {
	id = "five_cycles",
	leftDialog = "@conversation/nym_technician_3:s_5fcdd10d", -- No problem. Just tell your boss you cleaned the condenser and come back in five cycles.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_five_cycles)

nym_technician_3_convo_pilot_slang = ConvoScreen:new {
	id = "pilot_slang",
	leftDialog = "@conversation/nym_technician_3:s_cf08b4c6", -- Huh? Is that some kind of pilot slang? I'm not that kind of girl.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_cbc1d532", "get_lost"}, -- Oh, I thought...
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_pilot_slang)

nym_technician_3_convo_get_lost = ConvoScreen:new {
	id = "get_lost",
	leftDialog = "@conversation/nym_technician_3:s_6e00532f", -- You thought WHAT? Get lost or I'll yell.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_get_lost)

nym_technician_3_convo_disgusting = ConvoScreen:new {
	id = "disgusting",
	leftDialog = "@conversation/nym_technician_3:s_6da31acb", -- That's really disgusting. You pilots are all the same.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_disgusting)

nym_technician_3_convo_balance_perfect = ConvoScreen:new {
	id = "balance_perfect",
	leftDialog = "@conversation/nym_technician_3:s_debe2412", -- What? No way. I checked the Claw myself before it left. The balance is perfect.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_4d5276b", "long_gone"}, -- The ship already left?
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_balance_perfect)

nym_technician_3_convo_long_gone = ConvoScreen:new {
	id = "long_gone",
	leftDialog = "@conversation/nym_technician_3:s_e8060558", -- Are you an idiot? The Claw's already long gone. Somewhere in the Lok system, but I have no idea where.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_8804f6ee", "nothing_you_can_do"}, -- Oh, I had no idea.
		{"@conversation/nym_technician_3:s_52fbe706", "whatever"}, -- Never mind, I have to go.
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_long_gone)

nym_technician_3_convo_whatever = ConvoScreen:new {
	id = "whatever",
	leftDialog = "@conversation/nym_technician_3:s_c1013aa7", -- Whatever.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_whatever)

nym_technician_3_convo_nothing_you_can_do = ConvoScreen:new {
	id = "nothing_you_can_do",
	leftDialog = "@conversation/nym_technician_3:s_69e50906", -- Yeah, so there's nothing you can do about the fuel balance. Who are you anyway? You here to clean the antimatter condenser?
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_67a590c3", "ahead_of_schedule"}, -- I'm here to clean the antimatter condenser.
		{"@conversation/nym_technician_3:s_d65e601b", "strange"}, -- Oh yeah...
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_nothing_you_can_do)

nym_technician_3_convo_strange = ConvoScreen:new {
	id = "strange",
	leftDialog = "@conversation/nym_technician_3:s_a8162c2", -- You're strange.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_strange)

nym_technician_3_convo_you_again = ConvoScreen:new {
	id = "you_again",
	leftDialog = "@conversation/nym_technician_3:s_e32d36db", -- You again? I don't have time to help you.
	stopConversation = "false",
	options = {
		{"@conversation/nym_technician_3:s_248faf8a", "long_gone"}, -- Where did you say the Kimogila's Claw was?
		{"@conversation/nym_technician_3:s_52fbe706", "clear_out"}, -- Never mind, I have to go.
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_you_again)

nym_technician_3_convo_clear_out = ConvoScreen:new {
	id = "clear_out",
	leftDialog = "@conversation/nym_technician_3:s_7e5b1e91", -- Can you clear out now? This is hard enough without distractions.
	stopConversation = "true",
	options = {
	}
}
nym_technician_3_convo_template:addScreen(nym_technician_3_convo_clear_out)

addConversationTemplate("nym_technician_3_convo_template", nym_technician_3_convo_template)
