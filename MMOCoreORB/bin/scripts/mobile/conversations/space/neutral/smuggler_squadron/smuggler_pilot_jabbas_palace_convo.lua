-- Smuggler Pilot outside Jabba's Palace conversation screens; ported from SWG-Source generic_newbie_pilot_info_jabbas_palace.java (STF conversation/generic_newbie_pilot_info_jabbas_palace). Handler: smugglerPilotJabbasPalaceConvoHandler.lua (feature tatooine-station-palace-access).
-- The greeting's static options are the two below; the handler rebuilds them for pilots with a certified ship (adds s_daa8544b first, as SWG does), and adds the palace_way options at run time.
smuggler_pilot_jabbas_palace_convo_template = ConvoTemplate:new {
	initialScreen = "greeting",
	templateType = "Lua",
	luaClassHandler = "smugglerPilotJabbasPalaceConvoHandler",
	screens = {}
}

smuggler_pilot_jabbas_palace_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_b543ec60", -- Oh, hi there. Sorry... I'm a little dazed. My friends and I had to run an errand for Porcellus. I had no idea it was going to be so difficult! What can I do for you, friend?
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_b8b50032", "errand"},
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_bc4e70bf", "rest_bye"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_greeting)

smuggler_pilot_jabbas_palace_rest_bye = ConvoScreen:new {
	id = "rest_bye",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_29430ed4", -- Thanks. Take care of yourself, pal.
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_rest_bye)

smuggler_pilot_jabbas_palace_palace_way = ConvoScreen:new {
	id = "palace_way",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_9bd20141", -- There's only one way into the palace... without getting shot by Hutt assassins or getting thrown to the Sarlacc pit.
	stopConversation = "false",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_palace_way)

smuggler_pilot_jabbas_palace_papers_not_smuggler = ConvoScreen:new {
	id = "papers_not_smuggler",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_3385ded9", -- Yes they looks to be in order but you're not a part of the Smugglers Alliance are you? Get your priorities straight and then come back to see me.
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_papers_not_smuggler)

smuggler_pilot_jabbas_palace_papers_unsigned = ConvoScreen:new {
	id = "papers_unsigned",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_2b167dbd", -- Hmm, yes, yes these looks to be correct. See this dotted line at the bottom though? You're supposed to sign it, come back to me when you have.
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_papers_unsigned)

smuggler_pilot_jabbas_palace_papers_wrong_name = ConvoScreen:new {
	id = "papers_wrong_name",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_f7d7d0fe", -- Let's see...Hmm yes these looks to be in order. I thought you said your name was %TU though? So why haven't you signed with your correct name? Get that fixed and come back to see me when you have.
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_papers_wrong_name)

smuggler_pilot_jabbas_palace_papers_accepted = ConvoScreen:new {
	id = "papers_accepted",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_51bcd889", -- I can't believe we're still using paper documents. Let's see here... hmm, yes these looks to be correct I suppose. I will inform the guards of your privileges. Keep in mind though, if you abuse Jabba's rules, you will be in deep trouble.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_d06b92dc", "papers_glue"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_papers_accepted)

smuggler_pilot_jabbas_palace_papers_glue = ConvoScreen:new {
	id = "papers_glue",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_6f8371ee", -- You better not. *sniff* *sniff* Strange...is that glue I sme...
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_papers_glue)

smuggler_pilot_jabbas_palace_friend_hutts = ConvoScreen:new {
	id = "friend_hutts",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_6fa59967", -- You have to become a friend of the Hutts. You need to get Jabba's associates to trust you.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_a9e4fd02", "reelo"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_friend_hutts)

smuggler_pilot_jabbas_palace_reelo = ConvoScreen:new {
	id = "reelo",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_d11dc1bf", -- Start by doing some favors for Reelo Baruk. He's in the main entry of the palace ... you know?
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_cba77fff", "favors"},
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_ebf8ee6f", "meet_jabba"},
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_2c017871", "dont_mention"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_reelo)

smuggler_pilot_jabbas_palace_favors = ConvoScreen:new {
	id = "favors",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_6d6fc618", -- It depends. You'll probably see a lot of combat when working for Jabba the Hutt. I know I have!
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_d038a005", "chain"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_favors)

smuggler_pilot_jabbas_palace_chain = ConvoScreen:new {
	id = "chain",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_9dd79035", -- After doing favors for Reelo, he'll pass you on up the chain of command. ... face-to-face with Jabba himself.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_2c017871", "dont_mention"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_chain)

smuggler_pilot_jabbas_palace_meet_jabba = ConvoScreen:new {
	id = "meet_jabba",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_8aeca88d", -- Do favors for Reelo, then he'll pass you on up the chain. ... face-to-face with Jabba himself.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_2c017871", "dont_mention"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_meet_jabba)

smuggler_pilot_jabbas_palace_dont_mention = ConvoScreen:new {
	id = "dont_mention",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_bc324892", -- Don't mention it!
	stopConversation = "true",
	options = {
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_dont_mention)

smuggler_pilot_jabbas_palace_errand = ConvoScreen:new {
	id = "errand",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_8583811b", -- My friend is the guy to ask, honestly. I'm just a hired gun. Porcellus needed us to take down a rare animal ... in over our heads.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_d94b37db", "errand_tone"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_errand)

smuggler_pilot_jabbas_palace_errand_tone = ConvoScreen:new {
	id = "errand_tone",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_aefb75dd", -- Don't take that tone with me, friend! I'd like to see how well you do in the same situation.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_80f90f12", "errand_grenade"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_errand_tone)

smuggler_pilot_jabbas_palace_errand_grenade = ConvoScreen:new {
	id = "errand_grenade",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_6b059369", -- Only by rolling a fragmentation grenade into the creature's mouth ... picking shrapnel out of his entrees.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_daa8544b", "palace_way_2"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_errand_grenade)

smuggler_pilot_jabbas_palace_palace_way_2 = ConvoScreen:new {
	id = "palace_way_2",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_9bd20141", -- There's only one way into the palace... without getting shot by Hutt assassins or getting thrown to the Sarlacc pit.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_5c484c74", "friend_hutts_2"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_palace_way_2)

smuggler_pilot_jabbas_palace_friend_hutts_2 = ConvoScreen:new {
	id = "friend_hutts_2",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_6fa59967", -- You have to become a friend of the Hutts. You need to get Jabba's associates to trust you.
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_a9e4fd02", "reelo_2"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_friend_hutts_2)

smuggler_pilot_jabbas_palace_reelo_2 = ConvoScreen:new {
	id = "reelo_2",
	leftDialog = "@conversation/generic_newbie_pilot_info_jabbas_palace:s_37388d12", -- Do some favors for Reelo Baruk. He's in the main entry of the palace ... you know?
	stopConversation = "false",
	options = {
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_cba77fff", "favors"},
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_ebf8ee6f", "meet_jabba"},
		{"@conversation/generic_newbie_pilot_info_jabbas_palace:s_2c017871", "dont_mention"},
	}
}
smuggler_pilot_jabbas_palace_convo_template:addScreen(smuggler_pilot_jabbas_palace_reelo_2)

addConversationTemplate("smuggler_pilot_jabbas_palace_convo_template", smuggler_pilot_jabbas_palace_convo_template)
