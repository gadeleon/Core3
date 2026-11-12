--[[
	Battlefield entry stations (Kessel / Deep Space gates), reconstructed from the client string tables
	conversation/battlefield_entry_station_{neutral,imperial,rebel}.stf; the SWG server scripts are lost.
	Entry is free, so the Prestige lines (s_7e6edae / s_c2f477d7 cost prompts, s_37d359a2 / s_fe2e6ec0 /
	s_f68255a0 not enough Prestige, the Yes/No answers to the cost prompt and the "Okay, Goodbye" replies to
	declining it) are not used.
	Handlers: screenplays/space/spacestations/battlefield_entry_conv_handlers.lua
]]

--[[ Neutral: Dathomir (4000, 200, -4700) ]]

battlefield_entry_neutral_convotemplate = ConvoTemplate:new {
	initialScreen = "greeting",
	templateType = "Lua",
	luaClassHandler = "BattlefieldEntryNeutralConvoHandler",
	screens = {}
}

battlefield_entry_neutral_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_729b53ce", -- Welcome, pilot!
	stopConversation = "false",
	options = {
		{"@conversation/battlefield_entry_station_neutral:s_c4588d4d", "kessel"}, -- I want to go to Kessel
		{"@conversation/battlefield_entry_station_neutral:s_fa22e207", "deep_space_warning"}, -- I would like to enter Deep Space!
	}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_greeting);

battlefield_entry_neutral_out_of_range = ConvoScreen:new {
	id = "out_of_range",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_3b257674", -- You need to move close to this station, %TU.
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_out_of_range);

battlefield_entry_neutral_civilian_ship = ConvoScreen:new {
	id = "civilian_ship",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_3693fe50", -- There's nothing we can do for you as long as you're in that civilian ship.
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_civilian_ship);

battlefield_entry_neutral_kessel = ConvoScreen:new {
	id = "kessel",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_1cfc0538", -- Good luck
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_kessel);

battlefield_entry_neutral_deep_space_warning = ConvoScreen:new {
	id = "deep_space_warning",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_a99b5897", -- This area of Deep Space has been closed by order of the Empire. ...
	stopConversation = "false",
	options = {
		{"@conversation/battlefield_entry_station_neutral:s_43be1790", "choose_side"}, -- I understand
		{"@conversation/battlefield_entry_station_neutral:s_1e10b20e", "forget_it"}, -- Forget that!
	}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_deep_space_warning);

battlefield_entry_neutral_forget_it = ConvoScreen:new {
	id = "forget_it",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_11e15256", -- Ha ha! I don't blame you. Goodbye, then.
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_forget_it);

battlefield_entry_neutral_choose_side = ConvoScreen:new {
	id = "choose_side",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_a785faa6", -- Which side would you like to support?
	stopConversation = "false",
	options = {
		{"@conversation/battlefield_entry_station_neutral:s_5f09f8fe", "deep_space_imperial"}, -- The Empire
		{"@conversation/battlefield_entry_station_neutral:s_d62f971d", "deep_space_rebel"}, -- The Rebel Alliance
	}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_choose_side);

battlefield_entry_neutral_deep_space_imperial = ConvoScreen:new {
	id = "deep_space_imperial",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_f61543c9", -- Good Luck
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_deep_space_imperial);

battlefield_entry_neutral_deep_space_rebel = ConvoScreen:new {
	id = "deep_space_rebel",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_f61543c9", -- Good Luck
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_deep_space_rebel);

battlefield_entry_neutral_rebels_not_welcome = ConvoScreen:new {
	id = "rebels_not_welcome",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_45e440c8", -- Rebels are not welcome here
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_rebels_not_welcome);

battlefield_entry_neutral_imperials_not_welcome = ConvoScreen:new {
	id = "imperials_not_welcome",
	leftDialog = "@conversation/battlefield_entry_station_neutral:s_993453d7", -- Imperials are not welcome here.
	stopConversation = "true",
	options = {}
}
battlefield_entry_neutral_convotemplate:addScreen(battlefield_entry_neutral_imperials_not_welcome);

addConversationTemplate("battlefield_entry_neutral_convotemplate", battlefield_entry_neutral_convotemplate);

--[[ Faction stations: Endor Imperial (6200, 5000, 6000) and Dantooine Rebel (-4200, -3000, -6000) ]]

-- Imperial

battlefield_entry_imperial_convotemplate = ConvoTemplate:new {
	initialScreen = "greeting",
	templateType = "Lua",
	luaClassHandler = "BattlefieldEntryImperialConvoHandler",
	screens = {}
}

battlefield_entry_imperial_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_a136b7d3", -- Welcome to the Imperial Space Station!
	stopConversation = "false",
	options = {
		{"@conversation/battlefield_entry_station_imperial:s_fa22e207", "deep_space"}, -- I would like to enter Deep Space!
		{"@conversation/battlefield_entry_station_imperial:s_597d7f95", "kessel"}, -- I would like to go to Kessel.
	}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_greeting);

battlefield_entry_imperial_out_of_range = ConvoScreen:new {
	id = "out_of_range",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_48f82131", -- You need to move closer to this station.
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_out_of_range);

battlefield_entry_imperial_civilian_ship = ConvoScreen:new {
	id = "civilian_ship",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_358253b2", -- There's nothing we can do for you while you're in that civilian ship.
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_civilian_ship);

battlefield_entry_imperial_enemy_greeting = ConvoScreen:new {
	id = "enemy_greeting",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_33077605", -- You are not welcome at this station, Rebel SCUM!
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_enemy_greeting);

battlefield_entry_imperial_neutral_greeting = ConvoScreen:new {
	id = "neutral_greeting",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_2e491159", -- Sign up with the Empire and we'll talk.
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_neutral_greeting);

battlefield_entry_imperial_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_33f71018", -- You are not of the proper faction. Go find your own station.
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_wrong_faction);

battlefield_entry_imperial_deep_space = ConvoScreen:new {
	id = "deep_space",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_a80d9308", -- Good luck!
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_deep_space);

battlefield_entry_imperial_kessel = ConvoScreen:new {
	id = "kessel",
	leftDialog = "@conversation/battlefield_entry_station_imperial:s_a80d9308", -- Good luck!
	stopConversation = "true",
	options = {}
}
battlefield_entry_imperial_convotemplate:addScreen(battlefield_entry_imperial_kessel);

addConversationTemplate("battlefield_entry_imperial_convotemplate", battlefield_entry_imperial_convotemplate);

-- Rebel

battlefield_entry_rebel_convotemplate = ConvoTemplate:new {
	initialScreen = "greeting",
	templateType = "Lua",
	luaClassHandler = "BattlefieldEntryRebelConvoHandler",
	screens = {}
}

battlefield_entry_rebel_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_6aebdf84", -- Welcome to the Rebel Space Station!
	stopConversation = "false",
	options = {
		{"@conversation/battlefield_entry_station_rebel:s_fa22e207", "deep_space"}, -- I would like to enter Deep Space!
		{"@conversation/battlefield_entry_station_rebel:s_359fde4", "kessel"}, -- I want to go to Kessel.
	}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_greeting);

battlefield_entry_rebel_out_of_range = ConvoScreen:new {
	id = "out_of_range",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_3b257674", -- You need to move close to this station, %TU.
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_out_of_range);

battlefield_entry_rebel_civilian_ship = ConvoScreen:new {
	id = "civilian_ship",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_2103c96f", -- We can't do anything for you while you're in that civilian ship.
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_civilian_ship);

battlefield_entry_rebel_enemy_greeting = ConvoScreen:new {
	id = "enemy_greeting",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_514ace33", -- You are not welcome at this station!
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_enemy_greeting);

battlefield_entry_rebel_neutral_greeting = ConvoScreen:new {
	id = "neutral_greeting",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_17456755", -- Sign up with the Rebel Alliance and we'll talk.
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_neutral_greeting);

battlefield_entry_rebel_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_33f71018", -- You are not of the proper faction. Go find your own station.
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_wrong_faction);

battlefield_entry_rebel_deep_space = ConvoScreen:new {
	id = "deep_space",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_a80d9308", -- Good luck!
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_deep_space);

battlefield_entry_rebel_kessel = ConvoScreen:new {
	id = "kessel",
	leftDialog = "@conversation/battlefield_entry_station_rebel:s_93272f1a", -- Good Luck.
	stopConversation = "true",
	options = {}
}
battlefield_entry_rebel_convotemplate:addScreen(battlefield_entry_rebel_kessel);

addConversationTemplate("battlefield_entry_rebel_convotemplate", battlefield_entry_rebel_convotemplate);
