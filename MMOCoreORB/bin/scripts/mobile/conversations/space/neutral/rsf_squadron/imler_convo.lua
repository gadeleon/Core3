--[[
	Royal Security Forces - Tier 4 (Admiral Diness Imler) - Conversation Template
	SWG-Source: naboo_privateer_tier4.java
	Feature: rsf-tier4
]]

imler_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "imlerConvoHandler",
	screens = {}
}

imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_35a5b893",
	leftDialog = "@conversation/naboo_privateer_tier4:s_35a5b893",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9",
	leftDialog = "@conversation/naboo_privateer_tier4:s_35a5b893", -- Won't find any here. See ya.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "nontrack_duty",
	leftDialog = "@conversation/naboo_privateer_tier4:s_24231574",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c82e9a2f", "duty_info"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "nontrack_no_duty",
	leftDialog = "@conversation/naboo_privateer_tier4:s_aff98418",
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_info",
	leftDialog = "@conversation/naboo_privateer_tier4:s_5603b2a1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_3f68df7d", "s_1993702c"}, -- Sounds easy enough.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_25cf4e47",
	leftDialog = "@conversation/naboo_privateer_tier4:s_25cf4e47",
	animation = "cough_polite",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_886cd421",
	leftDialog = "@conversation/naboo_privateer_tier4:s_886cd421",
	animation = "shrug_shoulders",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_3892e6da",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3892e6da",
	animation = "snap_finger2",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_94654f90",
	leftDialog = "@conversation/naboo_privateer_tier4:s_94654f90",
	animation = "tap_head",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_retry_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a77b8282",
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_retry_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_87f301d7",
	animation = "offer_affection",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_c5b4e219",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c5b4e219",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_privateer_tier4:s_cfba6d32", "s_b7bd69e9"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_retry_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a9d8ef68",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_b7bd69e9",
	leftDialog = "@conversation/naboo_privateer_tier4:s_b7bd69e9",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c4fcfcf7", "mission2_retry_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_retry_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_501c35bc",
	animation = "shrug_shoulders",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_5fff247b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_5fff247b",
	animation = "point_to_self",
	options = {
		{"@conversation/naboo_privateer_tier4:s_5c429d49", "mission3_retry_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_fcd38a06",
	leftDialog = "@conversation/naboo_privateer_tier4:s_fcd38a06",
	animation = "tap_foot",
	options = {
		{"@conversation/naboo_privateer_tier4:s_fc7e0e7a", "mission3_retry_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_retry_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d858532",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_retry_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d767398d",
	animation = "threaten",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_1f680e83",
	leftDialog = "@conversation/naboo_privateer_tier4:s_1f680e83",
	options = {
		{"@conversation/naboo_privateer_tier4:s_b0da26cf", "mission4_retry_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_bd3f3d63",
	leftDialog = "@conversation/naboo_privateer_tier4:s_bd3f3d63",
	options = {
		{"@conversation/naboo_privateer_tier4:s_d55f2579", "mission4_retry_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_retry_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a479efa4",
	animation = "nod_head_once",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_retry_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_de697017",
	animation = "shrug_hands",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4d30b2ce",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4d30b2ce",
	options = {
		{"@conversation/naboo_privateer_tier4:s_e1e40ead", "s_7b043f5c"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4ff27acf",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4ff27acf",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c8888bec", "s_e9b81b8b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_7b043f5c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_7b043f5c",
	animation = "offer_affection",
	options = {
		{"@conversation/naboo_privateer_tier4:s_55dae7d2", "s_4f4c63b2"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4f4c63b2",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4f4c63b2",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_e9b81b8b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_e9b81b8b",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_4cbd4a9d", "s_6140c0f4"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_6140c0f4",
	leftDialog = "@conversation/naboo_privateer_tier4:s_6140c0f4",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_3ff13caa",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3ff13caa",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_95fa2e6",
	leftDialog = "@conversation/naboo_privateer_tier4:s_95fa2e6",
	options = {
		{"@conversation/naboo_privateer_tier4:s_d70dba34", "s_76cd7167"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_76cd7167",
	leftDialog = "@conversation/naboo_privateer_tier4:s_76cd7167",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier4:s_18a40c8c", "s_c62300e0"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_c62300e0",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c62300e0",
	animation = "shrug_shoulders",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_ab583079",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ab583079",
	options = {
		{"@conversation/naboo_privateer_tier4:s_af9cab7a", "s_eb559766"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_96b5ddf3",
	leftDialog = "@conversation/naboo_privateer_tier4:s_96b5ddf3",
	options = {
		{"@conversation/naboo_privateer_tier4:s_ddf79f01", "s_c31a5da7"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_eb559766",
	leftDialog = "@conversation/naboo_privateer_tier4:s_eb559766",
	animation = "gesticulate_wildly",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_c31a5da7",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c31a5da7",
	animation = "stretch",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9d566d78",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9d566d78",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9b07df81",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9b07df81",
	animation = "laugh",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_e4bbe441",
	options = {
		{"@conversation/naboo_privateer_tier4:s_e9ea6fec", "s_76701ff2"}, -- Good. Because I want to go after them.
		{"@conversation/naboo_privateer_tier4:s_983ebe8d", "s_3af6b354"}, -- They're going after the RSF pretty hard.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ff6e1247",
	options = {
		{"@conversation/naboo_privateer_tier4:s_3210ae50", "s_2035fbe6"}, -- Haha! They sure did.
		{"@conversation/naboo_privateer_tier4:s_5b5570cd", "s_55453170"}, -- I didn't like the fact they tried to kill me.
		{"@conversation/naboo_privateer_tier4:s_9d4ab52b", "s_ebcc7726"}, -- What was the cargo?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_bdc28bb4",
	options = {
		{"@conversation/naboo_privateer_tier4:s_39500c68", "s_f803a81b"}, -- What did you find?
		{"@conversation/naboo_privateer_tier4:s_841d27db", "s_105bb565"}, -- Why?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9312a850",
	options = {
		{"@conversation/naboo_privateer_tier4:s_68441a06", "s_3d333deb"}, -- Action packed.
		{"@conversation/naboo_privateer_tier4:s_6cee1a83", "s_ebb2f602"}, -- Not so much.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_3af6b354",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3af6b354", -- No, my friend. They're going against YOU pretty hard. You're good at what you do. And that means you're getting in their way. Black Suns don't like people getting in their way.
	options = {
		{"@conversation/naboo_privateer_tier4:s_cdbde300", "s_16106529"}, -- Well I'm not going to stop.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_16106529",
	leftDialog = "@conversation/naboo_privateer_tier4:s_16106529", -- Well, this is a new problem in Yavin. We'll just have to deal with it. I'm not going to wait for them to come to us.
	options = {
		{"@conversation/naboo_privateer_tier4:s_63e5cad0", "s_fd271a84"}, -- Send me out there.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_76701ff2",
	leftDialog = "@conversation/naboo_privateer_tier4:s_76701ff2", -- You're about to get your wish. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots up around Yavin in a sortie against the Black Sun.
	options = {
		{"@conversation/naboo_privateer_tier4:s_63c379c4", "s_2271ff14"}, -- These other pilots. Are they any good?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_fd271a84",
	leftDialog = "@conversation/naboo_privateer_tier4:s_fd271a84", -- You read my mind. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots in a sortie against the Black Sun.
	options = {
		{"@conversation/naboo_privateer_tier4:s_63c379c4", "s_80714a31"}, -- These other pilots. Are they any good?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_2271ff14",
	leftDialog = "@conversation/naboo_privateer_tier4:s_2271ff14", -- I think so. But you can be the judge of that.
	options = {
		{"@conversation/naboo_privateer_tier4:s_bbd611b4", "s_237b421d"}, -- What about the Imperials?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_80714a31",
	leftDialog = "@conversation/naboo_privateer_tier4:s_80714a31", -- I think so. But you can be the judge of that. Ready to go?
	options = {
		{"@conversation/naboo_privateer_tier4:s_eb2cfdac", "mission4_accept_a"}, -- You bet.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_237b421d",
	leftDialog = "@conversation/naboo_privateer_tier4:s_237b421d", -- They're not going to get involved. They've got other things to worry about. You just take care of those Black Suns. Ready to go?
	options = {
		{"@conversation/naboo_privateer_tier4:s_556c01dc", "mission4_accept_b"}, -- Just get me up there.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9281abbb", -- Go get 'em, tiger.
	animation = "salute1",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_8a0c5ce7", -- I'll talk to you when you get back.
	animation = "salute1",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_2035fbe6",
	leftDialog = "@conversation/naboo_privateer_tier4:s_2035fbe6", -- You're lucky you made it back in one piece.
	options = {
		{"@conversation/naboo_privateer_tier4:s_db51959a", "s_f453a7fa"}, -- Luck had nothing to do with it.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_f453a7fa",
	leftDialog = "@conversation/naboo_privateer_tier4:s_f453a7fa", -- I like your attitude. I was right about that freighter, wasn't I?
	options = {
		{"@conversation/naboo_privateer_tier4:s_27e6d728", "s_840f4ebe"}, -- You were right. They were packed to the gills with contraband.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_840f4ebe",
	leftDialog = "@conversation/naboo_privateer_tier4:s_840f4ebe", -- What can I say? I've got a nose for these kinds of  things.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9d4ab52b", "s_ebcc7726"}, -- What was the cargo?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_55453170",
	leftDialog = "@conversation/naboo_privateer_tier4:s_55453170", -- Not this time. But they'll try again.
	options = {
		{"@conversation/naboo_privateer_tier4:s_cdbde300", "s_4cae7d37"}, -- Well I'm not going to stop.
		{"@conversation/naboo_privateer_tier4:s_9299cabe", "s_27cad067"}, -- What's going on with the Black Suns?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_27cad067",
	leftDialog = "@conversation/naboo_privateer_tier4:s_27cad067", -- Don't think I can help you there.
	options = {
		{"@conversation/naboo_privateer_tier4:s_7f9b8387", "s_720204b2"}, -- Why not?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4cae7d37",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4cae7d37", -- Of course not. Forget about them for now. I have a new mission for you.
	options = {
		{"@conversation/naboo_privateer_tier4:s_1adbadc4", "s_b5ee61ed"}, -- I'm ready.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_720204b2",
	leftDialog = "@conversation/naboo_privateer_tier4:s_720204b2", -- Let me worry about the Black Suns. I have a new mission for you.
	options = {
		{"@conversation/naboo_privateer_tier4:s_a11918f3", "s_b5ee61ed"}, -- OK.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_ebcc7726",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ebcc7726", -- 'Materials for an explosives plant. If they had moved them into this system undetected... well, they didn't. That's all that matters.
	options = {
		{"@conversation/naboo_privateer_tier4:s_dfb50fb1", "s_41799e3b"}, -- I think you're right.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_41799e3b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_41799e3b", -- You did good. I have a new mission for you.
	options = {
		{"@conversation/naboo_privateer_tier4:s_8289ab5b", "s_b5ee61ed"}, -- I'm ready for my next mission.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_b5ee61ed",
	leftDialog = "@conversation/naboo_privateer_tier4:s_b5ee61ed", -- A pair of Imperial freighters have entered Yavin space. They need a go-between for a supply transfer. And that go-between would be you.
	options = {
		{"@conversation/naboo_privateer_tier4:s_c290ec08", "s_9252108e"}, -- Imperials!
		{"@conversation/naboo_privateer_tier4:s_5b6fb4cf", "s_539c8d41"}, -- Why? For what reason?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_539c8d41",
	leftDialog = "@conversation/naboo_privateer_tier4:s_539c8d41", -- The head honchos like to know EVERYTHING happening in this system. You must have figured  that out by now.
	options = {
		{"@conversation/naboo_privateer_tier4:s_fb1b0124", "s_4e740301"}, -- They're paranoid, I know that.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4e740301",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4e740301", -- You would be, too, if half the galaxy was gunning for you. And besides, the Imperials are awfully active down here.
	options = {
		{"@conversation/naboo_privateer_tier4:s_fadf51b5", "s_9252108e"}, -- Imperials.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9252108e",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9252108e", -- Not your favorites, I take it?
	options = {
		{"@conversation/naboo_privateer_tier4:s_a2989575", "s_841d27db"}, -- They're lowlifes.
		{"@conversation/naboo_privateer_tier4:s_f4146fa1", "s_babb0d0c"}, -- Lowlifes with guns.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_841d27db",
	leftDialog = "@conversation/naboo_privateer_tier4:s_841d27db", -- Why?
	options = {
		{"@conversation/naboo_privateer_tier4:s_a5795662", "s_917f4150"}, -- Because they're bloodthirsty lunatics, I guess.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_917f4150",
	leftDialog = "@conversation/naboo_privateer_tier4:s_917f4150", -- Well THAT'S not a good enough reason! You're pretty bloodthirsty, too.
	options = {
		{"@conversation/naboo_privateer_tier4:s_f0583774", "s_babb0d0c"}, -- Yeah, but...well...
		{"@conversation/naboo_privateer_tier4:s_1f2b0388", "s_babb0d0c"}, -- Not any more.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_babb0d0c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_babb0d0c", -- Look, this isn't an ethics class. We're all just here to do our job.
	options = {
		{"@conversation/naboo_privateer_tier4:s_ba8f5de7", "s_7378bc13"}, -- I see what you're saying.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_7378bc13",
	leftDialog = "@conversation/naboo_privateer_tier4:s_7378bc13", -- You know how testy Imperial freighter captains can be. They think they own the universe. Especially these two. They're a real couple of killjoys. But they're our friends, so make nice, OK?
	options = {
		{"@conversation/naboo_privateer_tier4:s_3fdc63be", "mission3_accept_a"}, -- Because we love the Empire so much.
		{"@conversation/naboo_privateer_tier4:s_18a76ec8", "mission3_accept_a"}, -- Who cares what they think?
		{"@conversation/naboo_privateer_tier4:s_e4399cac", "mission3_accept_b"}, -- What about the Black Suns?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ff66ed8b", -- You don't have  to love 'em. You just have to keep 'em happy. Get out there and take care of those captains.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_48621561", -- What about  them? Look, they don't bother us, we don't bother them. Right now, Imperial happiness is your only concern. Get out there and take care of those captains.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_f803a81b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_f803a81b", -- Nothing definite. Black Suns know how to cover their tracks. But they're definitely active in this system. And that's a problem, considering the Imperial crackdown.
	options = {
		{"@conversation/naboo_privateer_tier4:s_c0540c7f", "s_d56fe8b0"}, -- What Imperial crackdown?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_d56fe8b0",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d56fe8b0", -- Boy, where have YOU been? The Empire's tightening the leash.
	options = {
		{"@conversation/naboo_privateer_tier4:s_841d27db", "s_d3c9b4d0"}, -- Why?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_d3c9b4d0",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d3c9b4d0", -- Beats me! Something about trouble with the prison. And word is that the Vortex is gunning for the Inquisitors.
	options = {
		{"@conversation/naboo_privateer_tier4:s_ec5dca32", "s_c60b4787"}, -- Vortex? Inquisitors?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_c60b4787",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c60b4787", -- Hey! You want to know more, ask somebody who cares. All I know is, They want everything in this system to be ship-shape. No illegal activity of any kind. And of course we are going to comply.
	options = {
		{"@conversation/naboo_privateer_tier4:s_77e48d5b", "s_3c53afd8"}, -- What do you mean?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_3c53afd8",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3c53afd8", -- I mean, the Empire's number one problem is that prison, but their radar is up, if you know what I mean. They're looking for trouble across the board. So we're going  to watch our step. We're going to watch everybody ELSE'S steps, too.
	options = {
		{"@conversation/naboo_privateer_tier4:s_fc00cf40", "s_9145ef83"}, -- I see what you mean.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_105bb565",
	leftDialog = "@conversation/naboo_privateer_tier4:s_105bb565", -- The head honchos like to know EVERYTHING that happens in this system. You must have figured  that out by now.
	options = {
		{"@conversation/naboo_privateer_tier4:s_3c9a53fb", "s_c5eae735"}, -- I've noticed.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_c5eae735",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c5eae735", -- Then maybe you've noticed that the Imperials aren't exactly tolerant of troublemakers. They'll stay out of our hair, as long as we keep running a tight ship.
	options = {
		{"@conversation/naboo_privateer_tier4:s_85a73c8b", "s_9e779014"}, -- So do you have a mission for me?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9145ef83",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9145ef83", -- Listen. There's a heavy mining freighter passing through Endor space.
	options = {
		{"@conversation/naboo_privateer_tier4:s_25f8ac14", "s_88678c75"}, -- What's it carrying?
		{"@conversation/naboo_privateer_tier4:s_d9177ade", "s_31c66e02"}, -- This is another escort mission?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9e779014",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9e779014", -- Always. There's a heavy mining freighter passing through Endor space.
	options = {
		{"@conversation/naboo_privateer_tier4:s_25f8ac14", "s_88678c75"}, -- What's it carrying?
		{"@conversation/naboo_privateer_tier4:s_d9177ade", "s_31c66e02"}, -- This is another escort mission?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_88678c75",
	leftDialog = "@conversation/naboo_privateer_tier4:s_88678c75", -- Supplies, a few passengers, nothing special.
	options = {
		{"@conversation/naboo_privateer_tier4:s_963212ec", "s_4d02fd15"}, -- OK...
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_4d02fd15",
	leftDialog = "@conversation/naboo_privateer_tier4:s_4d02fd15", -- That's what they SAY they're carrying. But I'm not so sure. I'd like you to take a closer look.
	options = {
		{"@conversation/naboo_privateer_tier4:s_8462774c", "s_87246f3e"}, -- So I should inspect the ship.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_31c66e02",
	leftDialog = "@conversation/naboo_privateer_tier4:s_31c66e02", -- Not exactly. Since the Black Suns are willing to fight RSF pilots, they must have something to hide. So we're going to start taking a closer look at all activity in this system.
	options = {
		{"@conversation/naboo_privateer_tier4:s_79387096", "s_ba2102e3"}, -- An inspect mission?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_87246f3e",
	leftDialog = "@conversation/naboo_privateer_tier4:s_87246f3e", -- You got it. Go check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.
	options = {
		{"@conversation/naboo_privateer_tier4:s_89aa28bd", "s_aa07a17b"}, -- Any idea what I should be looking for?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_ba2102e3",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ba2102e3", -- You got it. So check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.
	options = {
		{"@conversation/naboo_privateer_tier4:s_89aa28bd", "s_aa07a17b"}, -- Any idea what I should be looking for?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_aa07a17b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_aa07a17b", -- Spice? Sliced weapons? Who knows. Anything's possible. And I mean ANYTHING. So keep your eyes open and your blasters primed.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9e7f84ea", "s_d9008914"}, -- I always do.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_d9008914",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d9008914", -- And listen. Don't be too gung-ho, okay? If you find some contraband, you know, tell me first.
	options = {
		{"@conversation/naboo_privateer_tier4:s_84c002ae", "mission2_accept_a"}, -- Looking for a taste?
		{"@conversation/naboo_privateer_tier4:s_2836e6b5", "mission2_accept_b"}, -- OK.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_e7515ed5", -- Go on. I'm busy. I've got things to do.
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_90422eb5", -- Good luck.
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_3d333deb",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3d333deb", -- Well, you'll get more of the same here, if you're lucky. Are you a good pilot?
	options = {
		{"@conversation/naboo_privateer_tier4:s_d9cced1f", "s_cab61bc8"}, -- Absolutely.
		{"@conversation/naboo_privateer_tier4:s_5277eec5", "s_ab0e62"}, -- You tell me.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_cab61bc8",
	leftDialog = "@conversation/naboo_privateer_tier4:s_cab61bc8", -- I've met pilots like you before. Raring to go. It's pilots like you that die first.
	options = {
		{"@conversation/naboo_privateer_tier4:s_afec8242", "s_d6a8a04d"}, -- Not THIS pilot.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_d6a8a04d",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d6a8a04d", -- Oo. I can't wait to see you in action.
	options = {
		{"@conversation/naboo_privateer_tier4:s_e5235eff", "s_a82676b8"}, -- Do you have a mission for me?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_ab0e62",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ab0e62", -- Mm!  Good answer, %TU.I should warn you, though. I don't like telling people what I'm thinking.
	options = {
		{"@conversation/naboo_privateer_tier4:s_65f98b49", "s_df2f398b"}, -- Maybe you'll make an exception for me.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_df2f398b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_df2f398b", -- Don't hold your breath. We're wasting time here. I have a mission for you.
	options = {
		{"@conversation/naboo_privateer_tier4:s_d9177ade", "s_a284d393"}, -- This is another escort mission?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_ebb2f602",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ebb2f602", -- He didn't dazzle you with his charm?
	options = {
		{"@conversation/naboo_privateer_tier4:s_a087e986", "s_e4254ae2"}, -- Not exactly.
		{"@conversation/naboo_privateer_tier4:s_e87166ba", "s_d76f1ea3"}, -- He'd like to start a one-man war against the Gungans.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_e4254ae2",
	leftDialog = "@conversation/naboo_privateer_tier4:s_e4254ae2", -- Aw, come on. That guy's harmless. I like his negative attitude. It cheers me up.
	options = {
		{"@conversation/naboo_privateer_tier4:s_d1f589da", "s_d76f1ea3"}, -- Ridiculous.
		{"@conversation/naboo_privateer_tier4:s_2befd882", "s_d76f1ea3"}, -- Well...
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_d76f1ea3",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d76f1ea3", -- What do you expect? He's a lifer here on Naboo. It's all he knows. Maybe you're more enlightened.
	options = {
		{"@conversation/naboo_privateer_tier4:s_dfb50fb1", "s_44b1cd3c"}, -- I think you're right.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_44b1cd3c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_44b1cd3c", -- Mm. We'll see. Let's get you going on a new mission.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9a74f227", "s_a284d393"}, -- So I see. This one's an escort job.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_a284d393",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a284d393", -- Something like that.
	options = {
		{"@conversation/naboo_privateer_tier4:s_d7ffd6a9", "s_a224e8fe"}, -- What am I escorting?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_a82676b8",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a82676b8", -- Royal Security Forces are using a deep space scan vessel in Endor space.
	options = {
		{"@conversation/naboo_privateer_tier4:s_3f68df7d", "s_7cc97d1a"}, -- Sounds easy enough.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_a224e8fe",
	leftDialog = "@conversation/naboo_privateer_tier4:s_a224e8fe", -- A deep space scan vessel. It's an RSF ship. We're using it to investigate Endor space.
	options = {
		{"@conversation/naboo_privateer_tier4:s_2836e6b5", "s_9405f2ce"}, -- OK.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_7cc97d1a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_7cc97d1a", -- Well, apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9525d65c", "s_b47b0542"}, -- Any idea what the Black Suns are up to?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_9405f2ce",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9405f2ce", -- So apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9525d65c", "s_b47b0542"}, -- Any idea what the Black Suns are up to?
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_b47b0542",
	leftDialog = "@conversation/naboo_privateer_tier4:s_b47b0542", -- I don't know, and right now, I don't care. The only thing that matters right now is that deep space scan. It's an expensive piece of equipment. We'd hate to lose it.
	options = {
		{"@conversation/naboo_privateer_tier4:s_9422ee24", "mission1_accept_a"}, -- You won't.
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_42d6c3ee", -- Go on. Your ship is waiting.
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/naboo_privateer_tier4:s_221582e4",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9750cd6f",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/naboo_privateer_tier4:s_552b15d",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ee2b4c16",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_1993702c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_1993702c",
	options = {
		{"@conversation/naboo_privateer_tier4:s_aba1f75e", "s_8ca0b65b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_8ca0b65b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_8ca0b65b",
	options = {
		{"@conversation/naboo_privateer_tier4:s_362a48e0", "s_1cf9a0f6"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_1cf9a0f6",
	leftDialog = "@conversation/naboo_privateer_tier4:s_1cf9a0f6",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c782ced7", "duty_info_end"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "duty_info_end",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9192ecb",
	options = {
		{"@conversation/naboo_privateer_tier4:s_62c8be58", "duty_destroy"},
		{"@conversation/naboo_privateer_tier4:s_619658af", "duty_escort"},
		{"@conversation/naboo_privateer_tier4:s_7869de8a", "duty_recovery"},
		{"@conversation/naboo_privateer_tier4:s_413ac49a", "duty_rescue"},
		{"@conversation/naboo_privateer_tier4:s_70d61202", "duty_info"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_92fa7352",
	leftDialog = "@conversation/naboo_privateer_tier4:s_92fa7352",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_7177c3f2", "s_cf0a01fd"},
		{"@conversation/naboo_privateer_tier4:s_57f232d6", "s_5d72fdfa"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_cf0a01fd",
	leftDialog = "@conversation/naboo_privateer_tier4:s_cf0a01fd",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_50d4081c", "s_cd140a4"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_5d72fdfa",
	leftDialog = "@conversation/naboo_privateer_tier4:s_5d72fdfa",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_9fe8c7e7", "s_75f5450f"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_cd140a4",
	leftDialog = "@conversation/naboo_privateer_tier4:s_cd140a4",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_614d7ac4", "s_492a501d"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_492a501d",
	leftDialog = "@conversation/naboo_privateer_tier4:s_492a501d",
	animation = "stretch",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_75f5450f",
	leftDialog = "@conversation/naboo_privateer_tier4:s_75f5450f",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_privateer_tier4:s_aa1834ec",
	animation = "rub_chin_thoughtful",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_privateer_tier4:s_aa1834ec", -- I don't think I've seen you before. Maybe you took a wrong turn somewhere.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c09ba3fa", "s_35a5b893"},
		{"@conversation/naboo_privateer_tier4:s_251ee0bd", "s_9"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "not_my_track",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d6473733",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_c1ff5062", "nontrack_no_duty"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9686f892",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_privateer_tier4:s_a404eb10", "s_25cf4e47"},
		{"@conversation/naboo_privateer_tier4:s_2313ac9e", "s_886cd421"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_privateer_tier4:s_eaf3e39a",
	animation = "stamp_feet",
	options = {
		{"@conversation/naboo_privateer_tier4:s_eb4e939", "s_3892e6da"},
		{"@conversation/naboo_privateer_tier4:s_23e8aa6d", "s_94654f90"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/naboo_privateer_tier4:s_c93f357b",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_5e1ad1a2", "mission1_retry_a"},
		{"@conversation/naboo_privateer_tier4:s_ff47ef5a", "mission1_retry_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/naboo_privateer_tier4:s_b59b9d3e",
	options = {
		{"@conversation/naboo_privateer_tier4:s_eb72f32e", "s_c5b4e219"},
		{"@conversation/naboo_privateer_tier4:s_c17d2691", "mission2_retry_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/naboo_privateer_tier4:s_95fbf5d7",
	options = {
		{"@conversation/naboo_privateer_tier4:s_8bbbb2ce", "s_5fff247b"},
		{"@conversation/naboo_privateer_tier4:s_c5f46951", "s_fcd38a06"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/naboo_privateer_tier4:s_8705a395",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier4:s_e2dbfb72", "s_1f680e83"},
		{"@conversation/naboo_privateer_tier4:s_8fe73508", "s_bd3f3d63"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_reward",
	leftDialog = "@conversation/naboo_privateer_tier4:s_8180cd8a",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_e0ce54d", "s_4d30b2ce"},
		{"@conversation/naboo_privateer_tier4:s_9121b74a", "s_4ff27acf"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/naboo_privateer_tier4:s_191d50ad",
	options = {
		{"@conversation/naboo_privateer_tier4:s_328cdc99", "s_3ff13caa"},
		{"@conversation/naboo_privateer_tier4:s_f1e2aed8", "s_95fa2e6"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/naboo_privateer_tier4:s_6362f5f4",
	options = {
		{"@conversation/naboo_privateer_tier4:s_7977e8e2", "s_ab583079"},
		{"@conversation/naboo_privateer_tier4:s_953c410e", "s_96b5ddf3"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/naboo_privateer_tier4:s_60d0f37b",
	animation = "beckon",
	options = {
		{"@conversation/naboo_privateer_tier4:s_ad713f95", "s_9d566d78"},
		{"@conversation/naboo_privateer_tier4:s_2e904f6c", "s_9b07df81"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "ready_mission",
	leftDialog = "@conversation/naboo_privateer_tier4:s_67b2bdc1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_39e697de", "mission1_brief"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/naboo_privateer_tier4:s_d91c04b2",
	animation = "check_wrist_device",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/naboo_privateer_tier4:s_cdffba3e",
	options = {
		{"@conversation/naboo_privateer_tier4:s_52917b0d", "duty_info"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/naboo_privateer_tier4:s_3f76a413",
	options = {
		{"@conversation/naboo_privateer_tier4:s_62c8be58", "duty_destroy"},
		{"@conversation/naboo_privateer_tier4:s_619658af", "duty_escort"},
		{"@conversation/naboo_privateer_tier4:s_7869de8a", "duty_recovery"},
		{"@conversation/naboo_privateer_tier4:s_413ac49a", "duty_rescue"},
		{"@conversation/naboo_privateer_tier4:s_70d61202", "duty_info"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "no_master",
	leftDialog = "@conversation/naboo_privateer_tier4:s_256dbbde",
	animation = "beckon",
	options = {
		{"@conversation/naboo_privateer_tier4:s_b2e340f6", "s_92fa7352"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/naboo_privateer_tier4:s_bd35f50b",
	options = {
		{"@conversation/naboo_privateer_tier4:s_62c8be58", "duty_destroy"},
		{"@conversation/naboo_privateer_tier4:s_619658af", "duty_escort"},
		{"@conversation/naboo_privateer_tier4:s_7869de8a", "duty_recovery"},
		{"@conversation/naboo_privateer_tier4:s_413ac49a", "duty_rescue"},
		{"@conversation/naboo_privateer_tier4:s_70d61202", "duty_info"},
	}
})

addConversationTemplate("imler_convo_template", imler_convo_template)
