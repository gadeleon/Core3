--[[
	Havoc Squadron - Tier 4 (Warvog Arkon) - Conversation Template
	SWG-Source: corellia_rebel_tier4.java
	Feature: havoc-tier4-arkon
]]

arkon_convo = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "arkonConvoHandler",
	screens = {}
}

arkon_convo:addScreen(ConvoScreen:new {
	id = "s_649d2a19",
	leftDialog = "@conversation/corellia_rebel_tier4:s_649d2a19",
	animation = "shake_head_disgust",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_2da082b6",
	leftDialog = "@conversation/corellia_rebel_tier4:s_2da082b6",
	animation = "standing_raise_fist",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "nontrack_duty",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f0743f82",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c82e9a2f", "duty_info"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "nontrack_no_duty",
	leftDialog = "@conversation/corellia_rebel_tier4:s_c73f5fdb",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "duty_info",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4bce8f6f",
	options = {
		{"@conversation/corellia_rebel_tier4:s_42880861", "s_386"}, -- Okay...
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_3bcc34e7",
	leftDialog = "@conversation/corellia_rebel_tier4:s_3bcc34e7",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_5e0e14bc",
	leftDialog = "@conversation/corellia_rebel_tier4:s_5e0e14bc",
	animation = "stamp_feet",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_549b97e6",
	leftDialog = "@conversation/corellia_rebel_tier4:s_549b97e6",
	animation = "standing_raise_fist",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_86df2510",
	leftDialog = "@conversation/corellia_rebel_tier4:s_86df2510",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_436c2ab2",
	leftDialog = "@conversation/corellia_rebel_tier4:s_436c2ab2",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_rebel_tier4:s_77e48d5b", "s_2744b825"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_2744b825",
	leftDialog = "@conversation/corellia_rebel_tier4:s_2744b825",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_ad621c08", "s_ee83a0c2"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_ee83a0c2",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ee83a0c2",
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_6fdab943",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6fdab943",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_b4e09e44",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b4e09e44",
	animation = "tap_head",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_c4dc6b9d",
	leftDialog = "@conversation/corellia_rebel_tier4:s_c4dc6b9d",
	animation = "flex_biceps",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_868699d3",
	leftDialog = "@conversation/corellia_rebel_tier4:s_868699d3",
	animation = "snap_finger1",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f87c573",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f87c573",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c72c337a", "s_9a4a59e0"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_e3653d50",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e3653d50",
	options = {
		{"@conversation/corellia_rebel_tier4:s_fc27931b", "s_3bfd507c"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_9a4a59e0",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9a4a59e0",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_f60b81f8", "s_3172f07e"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_3172f07e",
	leftDialog = "@conversation/corellia_rebel_tier4:s_3172f07e",
	animation = "shrug_shoulders",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_3bfd507c",
	leftDialog = "@conversation/corellia_rebel_tier4:s_3bfd507c",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_85fbc617",
	leftDialog = "@conversation/corellia_rebel_tier4:s_85fbc617",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_4c97efb1",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4c97efb1",
	animation = "salute1",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_retry_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_76c0ae11",
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_retry_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_fa6bfaff",
	animation = "offer_affection",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_retry_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_16e3e795",
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_retry_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_13835aab",
	animation = "check_wrist_device",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_retry_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f5d1e7f4",
	animation = "wave_finger_warning",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_retry_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_42b12fa4",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_retry_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_2eec3c3b",
	animation = "stamp_feet",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_retry_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6561f20e",
	animation = "implore",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_99069e90",
	leftDialog = "@conversation/corellia_rebel_tier4:s_99069e90",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_f27f6d98", "s_449db6d4"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_decline",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9be0e2f1",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_e380bbf8",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e380bbf8",
	options = {
		{"@conversation/corellia_rebel_tier4:s_96bfa401", "s_fcddb599"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_449db6d4",
	leftDialog = "@conversation/corellia_rebel_tier4:s_449db6d4",
	animation = "point_to_self",
	options = {
		{"@conversation/corellia_rebel_tier4:s_67e6df55", "s_d98a6441"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_d98a6441",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d98a6441",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d566a3c", "s_ffeba47a"},
		{"@conversation/corellia_rebel_tier4:s_f35bbdbd", "s_2284c46"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_ffeba47a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ffeba47a",
	options = {
		{"@conversation/corellia_rebel_tier4:s_997f2d21", "s_f5e4dcb6"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_2284c46",
	leftDialog = "@conversation/corellia_rebel_tier4:s_2284c46",
	options = {
		{"@conversation/corellia_rebel_tier4:s_2a5d0bf1", "s_dfc39325"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f5e4dcb6",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f5e4dcb6",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_f5cc7cf3", "s_c95dbd1"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_c95dbd1",
	leftDialog = "@conversation/corellia_rebel_tier4:s_c95dbd1",
	options = {
		{"@conversation/corellia_rebel_tier4:s_9d0a2207", "mission1_accept_a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_accept_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_526ce515",
	animation = "shake_head_no",
	options = {
		{"@conversation/corellia_rebel_tier4:s_410d920c", "s_a434ad25"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_a434ad25",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a434ad25",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_dfc39325",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dfc39325",
	options = {
		{"@conversation/corellia_rebel_tier4:s_b045a378", "s_9f50a13"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_9f50a13",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9f50a13",
	options = {
		{"@conversation/corellia_rebel_tier4:s_9d0a2207", "mission1_accept_b"}, -- Should I target the Black Suns directly?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_accept_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_526ce515", -- Negative! They outgun YOU, too. Don't try to blast them to smithereens. Just hold them off long enough to give our mining vessels the time they need to escape.
	options = {
		{"@conversation/corellia_rebel_tier4:s_410d920c", "s_106"}, -- Alright, let's do this!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_106",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a434ad25", -- One more thing Rebel. All the missions I provide you with will be high risk missions and might be too much to handle by yourself. If you have any favors you can call in, doing so during my missions might be a good idea.
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_fcddb599",
	leftDialog = "@conversation/corellia_rebel_tier4:s_fcddb599",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_6318beeb", "s_115"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_115",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d98a6441", -- Apparently, the Black Suns are preparing to launch an assault on one of our mining interests in the Dathomir system.
	options = {
		{"@conversation/corellia_rebel_tier4:s_f5cc7cf3", "s_119"}, -- Can't the vessels defend themselves?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_119",
	leftDialog = "@conversation/corellia_rebel_tier4:s_c95dbd1", -- They're outgunned! So we need to help them out.
	options = {
		{"@conversation/corellia_rebel_tier4:s_9d0a2207", "mission1_accept_c"}, -- Should I target the Black Suns directly?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_accept_c",
	leftDialog = "@conversation/corellia_rebel_tier4:s_526ce515", -- Negative! They outgun YOU, too. Don't try to blast them to smithereens. Just hold them off long enough to give our mining vessels the time they need to escape.
	animation = "shake_head_no",
	options = {
		{"@conversation/corellia_rebel_tier4:s_410d920c", "s_127"}, -- Alright, let's do this!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_127",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a434ad25", -- One more thing Rebel. All the missions I provide you with will be high risk missions and might be too much to handle by yourself. If you have any favors you can call in, doing so during my missions might be a good idea.
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_5d976742",
	leftDialog = "@conversation/corellia_rebel_tier4:s_5d976742",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_rebel_tier4:s_cd445db2", "s_8b4d636d"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_decline",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f15aeb5",
	animation = "shake_head_disgust",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_87e30fff",
	leftDialog = "@conversation/corellia_rebel_tier4:s_87e30fff",
	animation = "laugh",
	options = {
		{"@conversation/corellia_rebel_tier4:s_eb703128", "s_3b361a5f"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_8b4d636d",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8b4d636d",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_841d27db", "s_900f01d1"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_900f01d1",
	leftDialog = "@conversation/corellia_rebel_tier4:s_900f01d1",
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c985b91", "s_d6f2e64d"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_d6f2e64d",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d6f2e64d",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/corellia_rebel_tier4:s_29544149", "s_f59d9106"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f59d9106",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f59d9106",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_37e345fe", "s_9a01b8f2"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_9a01b8f2",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9a01b8f2",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/corellia_rebel_tier4:s_eb1c3d4e", "mission2_accept_a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_accept_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f3603d67",
	animation = "point_forward",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_3b361a5f",
	leftDialog = "@conversation/corellia_rebel_tier4:s_3b361a5f",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_761dd18e", "s_a04dd423"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_a04dd423",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a04dd423",
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7052aaab", "s_29f4061f"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_29f4061f",
	leftDialog = "@conversation/corellia_rebel_tier4:s_29f4061f",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c2bbb747", "s_d16ee99f"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_d16ee99f",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d16ee99f",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_841d27db", "s_158"}, -- Why?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_158",
	leftDialog = "@conversation/corellia_rebel_tier4:s_900f01d1", -- What?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c985b91", "s_162"}, -- I said, 'Why?'
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_162",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d6f2e64d", -- What am I, a mind reader? They're probably concerned about Alliance attacks.
	animation = "shrug_shoulders",
	options = {
		{"@conversation/corellia_rebel_tier4:s_29544149", "s_166"}, -- Then why send an Inquisitor?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_166",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f59d9106", -- Well, %TU, think about it. The Empire needs to know what the Alliance is planning. And no one is better at gathering information than an Inquisitor.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_37e345fe", "s_170"}, -- Have you ever seen an Inquisitor up close?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_170",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9a01b8f2", -- Once...a long, long time ago. Let's not talk about it right now. I want you to kill that Inquisitor before he reaches the Imperial fleet in Dathomir.
	options = {
		{"@conversation/corellia_rebel_tier4:s_eb1c3d4e", "mission2_accept_b"}, -- Are you crazy? No one can kill an Inquisitor!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_accept_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f3603d67", -- Don't talk back to me, junior! And don't be ridiculous! The Inquisitors are mortal, like the rest of us. Believe me, they CAN be killed. I know that for a fact. Now I want you to get out there, immediately!
	animation = "point_accusingly",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_178",
	leftDialog = "@conversation/corellia_rebel_tier4:s_900f01d1", -- What?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_3b95cf2f", "s_ff9fae78"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_decline",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1af32f06",
	animation = "shake_head_disgust",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_83f72ca3",
	leftDialog = "@conversation/corellia_rebel_tier4:s_83f72ca3",
	animation = "curtsey1",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7065a3b", "s_a2c04cca"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_7da3fc7a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_7da3fc7a",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d054f893", "s_220"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_ff9fae78",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ff9fae78",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8fc8c755", "s_4057d656"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_4057d656",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4057d656",
	options = {
		{"@conversation/corellia_rebel_tier4:s_840af840", "s_882e7ab9"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_882e7ab9",
	leftDialog = "@conversation/corellia_rebel_tier4:s_882e7ab9",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d06c9b96", "s_a6e1a5f4"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_a6e1a5f4",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a6e1a5f4",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/corellia_rebel_tier4:s_bed0dfe7", "s_8cac3c56"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_8cac3c56",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8cac3c56",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_rebel_tier4:s_98199797", "s_1bb2f893"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_1bb2f893",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1bb2f893",
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7ae51280", "mission3_accept_a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_accept_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_11769c29",
	animation = "pose_proudly",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_a2c04cca",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a2c04cca",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7fca522a", "s_7afc40b8"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_7afc40b8",
	leftDialog = "@conversation/corellia_rebel_tier4:s_7afc40b8",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c55a344e", "s_9e1c0119"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_9e1c0119",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9e1c0119",
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d1be90a9", "s_ccac6a71"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_ccac6a71",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ccac6a71",
	options = {
		{"@conversation/corellia_rebel_tier4:s_f50be00f", "s_207"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_207",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8cac3c56", -- I thought you would! Now you don't have to take the whole base apart. You're just going to pave the way for an Alliance B-Wing squadron. They've had their sights set on this base for a while.
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_98199797", "s_211"}, -- Why is the Alliance sending pirates? This sounds like strictly a Rebel operation.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_211",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1bb2f893", -- They're using my men because they know every inch of Dathomir space. They'll run rings around those Imperials. I suggest you follow their every move. I trained them all myself.
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7ae51280", "mission3_accept_b"}, -- You did?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_accept_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_11769c29", -- Sure! I wasn't ALWAYS an old man, you know. I used to have a few more marbles rolling around upstairs. Now go on; get out of here.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_220",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ff9fae78", -- What kind of question is that?
	options = {
		{"@conversation/corellia_rebel_tier4:s_b45dc260", "s_268606ba"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_268606ba",
	leftDialog = "@conversation/corellia_rebel_tier4:s_268606ba",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7ce1c24", "s_21374155"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_21374155",
	leftDialog = "@conversation/corellia_rebel_tier4:s_21374155",
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_77633b61", "s_a64a6f6f"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_a64a6f6f",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a64a6f6f",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_98588d70", "s_229"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_229",
	leftDialog = "@conversation/corellia_rebel_tier4:s_882e7ab9", -- Well, the Empire has no idea what the Alliance has planned, thanks to you.
	options = {
		{"@conversation/corellia_rebel_tier4:s_d06c9b96", "s_233"}, -- Even I don't know what the Alliance has planned.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_233",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a6e1a5f4", -- That's because it's top secret! In the meantime, let's keep gunning for the Empire. You're going to Dathomir. I want you to join some of my men on a guerilla strike against an Imperial base.
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_bed0dfe7", "s_237"}, -- I like that!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_237",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8cac3c56", -- I thought you would! Now you don't have to take the whole base apart. You're just going to pave the way for an Alliance B-Wing squadron. They've had their sights set on this base for a while.
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_rebel_tier4:s_98199797", "s_241"}, -- Why is the Alliance sending pirates? This sounds like strictly a Rebel operation.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_241",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1bb2f893", -- They're using my men because they know every inch of Dathomir space. They'll run rings around those Imperials. I suggest you follow their every move. I trained them all myself.
	options = {
		{"@conversation/corellia_rebel_tier4:s_7ae51280", "mission3_accept_c"}, -- You did?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_accept_c",
	leftDialog = "@conversation/corellia_rebel_tier4:s_11769c29", -- Sure! I wasn't ALWAYS an old man, you know. I used to have a few more marbles rolling around upstairs. Now go on; get out of here.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_1c669",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1c669",
	animation = "embarrassed",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d9cced1f", "s_5e4c5d9a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_decline",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9e3df78d",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f5427310",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f5427310",
	options = {
		{"@conversation/corellia_rebel_tier4:s_2ac3e9a6", "s_cbcfe001"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_5e4c5d9a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_5e4c5d9a",
	options = {
		{"@conversation/corellia_rebel_tier4:s_99d3b4fd", "s_50669846"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_50669846",
	leftDialog = "@conversation/corellia_rebel_tier4:s_50669846",
	options = {
		{"@conversation/corellia_rebel_tier4:s_9a626852", "s_e93fce3e"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_e93fce3e",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e93fce3e",
	options = {
		{"@conversation/corellia_rebel_tier4:s_53544796", "s_b607bb2e"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_b607bb2e",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b607bb2e",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8729f60e", "s_31fd5acf"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_31fd5acf",
	leftDialog = "@conversation/corellia_rebel_tier4:s_31fd5acf",
	options = {
		{"@conversation/corellia_rebel_tier4:s_a9e4fd02", "s_127f2e23"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_127f2e23",
	leftDialog = "@conversation/corellia_rebel_tier4:s_127f2e23",
	options = {
		{"@conversation/corellia_rebel_tier4:s_69a739e6", "mission4_accept_a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_accept_a",
	leftDialog = "@conversation/corellia_rebel_tier4:s_abf08a18",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_cbcfe001",
	leftDialog = "@conversation/corellia_rebel_tier4:s_cbcfe001",
	options = {
		{"@conversation/corellia_rebel_tier4:s_4519dec9", "s_8762aa6e"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_8762aa6e",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8762aa6e",
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_77e48d5b", "s_b1f1f364"}, -- What do you mean?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_b1f1f364",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b1f1f364",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_af22b9b2", "s_dbcde2d3"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_dbcde2d3",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dbcde2d3",
	animation = "pound_fist_chest",
	options = {
		{"@conversation/corellia_rebel_tier4:s_99d3b4fd", "s_279"}, -- What have you got for me?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_279",
	leftDialog = "@conversation/corellia_rebel_tier4:s_50669846", -- Apparently, the Empire's had just about enough of our activities in the area. I don't know who they hate more, smugglers or Rebels.
	options = {
		{"@conversation/corellia_rebel_tier4:s_9a626852", "s_283"}, -- Same difference to them.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_283",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e93fce3e", -- You're probably right, %NU. We've received word that they're planning to build a space station in the Lok system. They'll use it to monitor all the activity in the area.
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/corellia_rebel_tier4:s_53544796", "s_287"}, -- Sounds like a problem.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_287",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b607bb2e", -- Yep. A BIG one. We can't let them build that station. So here's the plan! We're going to destroy the station components while they're en route to Lok.
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8729f60e", "s_291"}, -- Smart.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_291",
	leftDialog = "@conversation/corellia_rebel_tier4:s_31fd5acf", -- Of course it's smart! It was my idea. Now listen up. Your first objective is to find out what route those Imperial freighters plan to use.
	animation = "tap_head",
	options = {
		{"@conversation/corellia_rebel_tier4:s_a9e4fd02", "s_295"}, -- How do I do that?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_295",
	leftDialog = "@conversation/corellia_rebel_tier4:s_127f2e23", -- You're going to kidnap one of their technical supervisors. He knows the plan. And pretty soon, you'll know the plan as well!
	options = {
		{"@conversation/corellia_rebel_tier4:s_69a739e6", "mission4_accept_b"}, -- Where do I find this guy?
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_accept_b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_abf08a18", -- Check your ship's computer. All the information you need is there. Good luck.
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/corellia_rebel_tier4:s_66d4c0f2", -- You don't have to shout! I've never seen anybody so excited about starships.
	options = {
		{"@conversation/corellia_rebel_tier4:s_2efd90c2", "trained_starships_end"}, -- I didn't shout!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_starships_end",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ecfe38f9", -- Oh! Well, here you go. Bye now!
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/corellia_rebel_tier4:s_7d2fc507", -- Say please!
	options = {
		{"@conversation/corellia_rebel_tier4:s_69020482", "trained_weapons_end"}, -- I did!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_weapons_end",
	leftDialog = "@conversation/corellia_rebel_tier4:s_650af8ec", -- Don't tell ME what you did! Now go on, make yourself useful!
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/corellia_rebel_tier4:s_62c873d4", -- Are you sure? Well too late it's yours now! Haha I'm just teasing you! That is a fine skill... for a NERF-HERDER! Now go on, get out of here!
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ba9df4a6", -- Oh all right. Here you go. Now go away and stop bothering me.
	animation = "giveup",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "intro_met",
	leftDialog = "@conversation/corellia_rebel_tier4:s_450d7208",
	animation = "slow_down",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d70dba34", "s_c384d95e"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_c384d95e",
	leftDialog = "@conversation/corellia_rebel_tier4:s_c384d95e",
	animation = "cover_mouth",
	options = {
		{"@conversation/corellia_rebel_tier4:s_2846f47d", "s_981faf84"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_981faf84",
	leftDialog = "@conversation/corellia_rebel_tier4:s_981faf84",
	animation = "tap_foot",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8209f997", "s_3dc78ada"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_3dc78ada",
	leftDialog = "@conversation/corellia_rebel_tier4:s_3dc78ada",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_rebel_tier4:s_afc14266", "s_fc6dfba9"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_fc6dfba9",
	leftDialog = "@conversation/corellia_rebel_tier4:s_fc6dfba9",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d9cced1f", "s_58e80738"}, -- Absolutely.
		{"@conversation/corellia_rebel_tier4:s_73313039", "s_347"}, -- Really, I just want to work.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_58e80738",
	leftDialog = "@conversation/corellia_rebel_tier4:s_58e80738",
	options = {
		{"@conversation/corellia_rebel_tier4:s_d79718db", "s_f51574ed"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_347",
	leftDialog = "@conversation/corellia_rebel_tier4:s_28d914fc", -- Well listen up. We are dealing with several situations here, and I'd like to see what you can do. First of all, the Black Suns have been taking a lot of business from us lately. Nym doesn't like it. We need a pilot to send them a message. A LOUD message. Heh!
	options = {
		{"@conversation/corellia_rebel_tier4:s_42880861", "s_351"}, -- Okay...
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f51574ed",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f51574ed",
	options = {
		{"@conversation/corellia_rebel_tier4:s_73313039", "s_28d914fc"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_28d914fc",
	leftDialog = "@conversation/corellia_rebel_tier4:s_28d914fc",
	options = {
		{"@conversation/corellia_rebel_tier4:s_42880861", "s_dc241019"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_dc241019",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019",
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_48529763", "s_f13513cd"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_f13513cd",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f13513cd",
	options = {
		{"@conversation/corellia_rebel_tier4:s_c3363bcd", "s_337"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_337",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019", -- What'd you say?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_539f9a2e", "s_e3e480fe"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_e3e480fe",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e3e480fe",
	animation = "threaten",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7e602d1b", "s_6429f86b"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_6429f86b",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6429f86b",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8e9d0848", "s_9bbb9999"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_9bbb9999",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9bbb9999",
	options = {
		{"@conversation/corellia_rebel_tier4:s_647ad2bc", "duty_destroy"},
		{"@conversation/corellia_rebel_tier4:s_d9116b4d", "duty_escort"},
		{"@conversation/corellia_rebel_tier4:s_8450d7db", "duty_recovery"},
		{"@conversation/corellia_rebel_tier4:s_9943289", "duty_rescue"},
		{"@conversation/corellia_rebel_tier4:s_9775f996", "duty_info"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d8209030",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/corellia_rebel_tier4:s_fed79efe",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b0d064ef",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/corellia_rebel_tier4:s_835acc11",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_351",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019", -- What'd you say?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_48529763", "s_355"}, -- I said, 'Okay'!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_355",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f13513cd", -- Hmph! Well here's some good news. One of our men has raided an Imperial outpost on Dathomir and he walked away with plenty of loot. Now all he has to do is escape! Easier said than done, of course, as the Empire wants their things back. So you could escort our man out of Dathomir...
	options = {
		{"@conversation/corellia_rebel_tier4:s_c3363bcd", "s_359"}, -- Uh huh.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_359",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019", -- What'd you say?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_539f9a2e", "s_363"}, -- Nothing!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_363",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e3e480fe", -- Don't smart off to me!
	animation = "threaten",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7e602d1b", "s_367"}, -- I'm not!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_367",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6429f86b", -- Here's some MORE good news. Another group of our men infiltrated a number of Imperial troop transports in the Endor system. But they can't take control of those ships - not yet. First we need a pilot to disable the transport controls. This requires a pilot with skills.
	options = {
		{"@conversation/corellia_rebel_tier4:s_8e9d0848", "s_371"}, -- [nod]
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_371",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9bbb9999", -- Hm, what else is there? Oh yes...you'll like this, it's a Rebel rescue mission! A Rebel fleet was carrying several scientists through the Dantooine system, they were ambushed by Imperial fighters! That's not right. I want a pilot to get out there and help those ships escape before more Imperial ships arrive! And that's it! So what's it going to be, junior?
	options = {
		{"@conversation/corellia_rebel_tier4:s_647ad2bc", "duty_destroy"},
		{"@conversation/corellia_rebel_tier4:s_d9116b4d", "duty_escort"},
		{"@conversation/corellia_rebel_tier4:s_8450d7db", "duty_recovery"},
		{"@conversation/corellia_rebel_tier4:s_9943289", "duty_rescue"},
		{"@conversation/corellia_rebel_tier4:s_9775f996", "duty_info"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_386",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019", -- What'd you say?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_48529763", "s_390"}, -- I said, 'Okay'!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_390",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f13513cd", -- Hmph! Well here's some good news. One of our men has raided an Imperial outpost on Dathomir and he walked away with plenty of loot. Now all he has to do is escape! Easier said than done, of course, as the Empire wants their things back. So you could escort our man out of Dathomir...
	options = {
		{"@conversation/corellia_rebel_tier4:s_c3363bcd", "s_394"}, -- Uh huh.
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_394",
	leftDialog = "@conversation/corellia_rebel_tier4:s_dc241019", -- What'd you say?
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_539f9a2e", "s_398"}, -- Nothing!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_398",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e3e480fe", -- Don't smart off to me!
	animation = "threaten",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7e602d1b", "s_402"}, -- I'm not!
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_402",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6429f86b", -- Here's some MORE good news. Another group of our men infiltrated a number of Imperial troop transports in the Endor system. But they can't take control of those ships - not yet. First we need a pilot to disable the transport controls. This requires a pilot with skills.
	options = {
		{"@conversation/corellia_rebel_tier4:s_8e9d0848", "s_406"}, -- [nod]
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_406",
	leftDialog = "@conversation/corellia_rebel_tier4:s_9bbb9999", -- Hm, what else is there? Oh yes...you'll like this, it's a Rebel rescue mission! A Rebel fleet was carrying several scientists through the Dantooine system, they were ambushed by Imperial fighters! That's not right. I want a pilot to get out there and help those ships escape before more Imperial ships arrive! And that's it! So what's it going to be, junior?
	options = {
		{"@conversation/corellia_rebel_tier4:s_647ad2bc", "duty_destroy"},
		{"@conversation/corellia_rebel_tier4:s_d9116b4d", "duty_escort"},
		{"@conversation/corellia_rebel_tier4:s_8450d7db", "duty_recovery"},
		{"@conversation/corellia_rebel_tier4:s_9943289", "duty_rescue"},
		{"@conversation/corellia_rebel_tier4:s_9775f996", "duty_info"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_bcbc9230",
	leftDialog = "@conversation/corellia_rebel_tier4:s_bcbc9230",
	animation = "explain",
	options = {
		{"@conversation/corellia_rebel_tier4:s_86677c6b", "s_6634adb9"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_8057f803",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8057f803",
	animation = "laugh",
	options = {
		{"@conversation/corellia_rebel_tier4:s_ff9bf289", "s_cb25bcd4"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_6634adb9",
	leftDialog = "@conversation/corellia_rebel_tier4:s_6634adb9",
	options = {
		{"@conversation/corellia_rebel_tier4:s_bcc6b959", "s_d74e67f"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_d74e67f",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d74e67f",
	options = {
		{"@conversation/corellia_rebel_tier4:s_2c4789b", "s_4ef35507"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_4ef35507",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4ef35507",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "s_cb25bcd4",
	leftDialog = "@conversation/corellia_rebel_tier4:s_cb25bcd4",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/corellia_rebel_tier4:s_92c6d3dd",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/corellia_rebel_tier4:s_774fb2f0",
	animation = "listen",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7e579e1e", "s_649d2a19"},
		{"@conversation/corellia_rebel_tier4:s_fb4c1f1f", "s_2da082b6"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "not_my_track",
	leftDialog = "@conversation/corellia_rebel_tier4:s_84c908b8",
	options = {
		{"@conversation/corellia_rebel_tier4:s_6222b64d", "nontrack_no_duty"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4f44d41d",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/corellia_rebel_tier4:s_e0dc5fad", "s_3bcc34e7"},
		{"@conversation/corellia_rebel_tier4:s_e86f1062", "s_5e0e14bc"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/corellia_rebel_tier4:s_256f3624",
	options = {
		{"@conversation/corellia_rebel_tier4:s_4ccb8d59", "s_549b97e6"},
		{"@conversation/corellia_rebel_tier4:s_c1013aa7", "s_86df2510"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "negative_faction",
	leftDialog = "@conversation/corellia_rebel_tier4:s_de1e215f",
	animation = "slit_throat",
	options = {
		{"@conversation/corellia_rebel_tier4:s_7090182", "s_436c2ab2"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_reward",
	leftDialog = "@conversation/corellia_rebel_tier4:s_f95cd5f5",
	animation = "applause_excited",
	options = {
		{"@conversation/corellia_rebel_tier4:s_95c399f6", "s_6fdab943"},
		{"@conversation/corellia_rebel_tier4:s_6f679fea", "s_b4e09e44"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_reward",
	leftDialog = "@conversation/corellia_rebel_tier4:s_da8e9da5",
	animation = "shrug_hands",
	options = {
		{"@conversation/corellia_rebel_tier4:s_def742", "s_c4dc6b9d"},
		{"@conversation/corellia_rebel_tier4:s_b20c71fe", "s_868699d3"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_reward",
	leftDialog = "@conversation/corellia_rebel_tier4:s_10d8bf69",
	animation = "salute1",
	options = {
		{"@conversation/corellia_rebel_tier4:s_aed5139a", "s_f87c573"},
		{"@conversation/corellia_rebel_tier4:s_cb6eb294", "s_e3653d50"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_reward",
	leftDialog = "@conversation/corellia_rebel_tier4:s_81e25d24",
	animation = "laugh",
	options = {
		{"@conversation/corellia_rebel_tier4:s_61485366", "s_85fbc617"},
		{"@conversation/corellia_rebel_tier4:s_197c8928", "s_4c97efb1"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/corellia_rebel_tier4:s_4f755af2",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_8f3b3edb", "mission1_retry_a"},
		{"@conversation/corellia_rebel_tier4:s_88563b84", "mission1_retry_b"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1909d363",
	animation = "stamp_feet",
	options = {
		{"@conversation/corellia_rebel_tier4:s_87d7e908", "mission2_retry_a"},
		{"@conversation/corellia_rebel_tier4:s_e42b260e", "mission2_retry_b"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d3d98e75",
	animation = "smack_self",
	options = {
		{"@conversation/corellia_rebel_tier4:s_e30b9697", "mission3_retry_a"},
		{"@conversation/corellia_rebel_tier4:s_10eafe13", "mission3_retry_b"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/corellia_rebel_tier4:s_78b8ac8f",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_4dd9a7b9", "mission4_retry_a"},
		{"@conversation/corellia_rebel_tier4:s_35dd4aa2", "mission4_retry_b"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/corellia_rebel_tier4:s_5bf6779f",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_rebel_tier4:s_3609c810", "s_99069e90"},
		{"@conversation/corellia_rebel_tier4:s_3c546115", "mission1_decline"},
		{"@conversation/corellia_rebel_tier4:s_ef3e641a", "s_e380bbf8"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/corellia_rebel_tier4:s_1047bc70",
	options = {
		{"@conversation/corellia_rebel_tier4:s_6adec6b0", "s_5d976742"},
		{"@conversation/corellia_rebel_tier4:s_dcabe09b", "mission2_decline"},
		{"@conversation/corellia_rebel_tier4:s_beaf1664", "s_87e30fff"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/corellia_rebel_tier4:s_e8f374d9",
	animation = "beckon",
	options = {
		{"@conversation/corellia_rebel_tier4:s_1c8bddbb", "s_178"},
		{"@conversation/corellia_rebel_tier4:s_f48fdfbd", "mission3_decline"},
		{"@conversation/corellia_rebel_tier4:s_1551b284", "s_83f72ca3"},
		{"@conversation/corellia_rebel_tier4:s_60080304", "s_7da3fc7a"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/corellia_rebel_tier4:s_ceb77d0c",
	options = {
		{"@conversation/corellia_rebel_tier4:s_5673ded2", "s_1c669"},
		{"@conversation/corellia_rebel_tier4:s_9976a72", "mission4_decline"},
		{"@conversation/corellia_rebel_tier4:s_5fe6ae71", "s_f5427310"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "ready_train",
	leftDialog = "@conversation/corellia_rebel_tier4:s_8907c99",
	animation = "beckon",
	options = {}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/corellia_rebel_tier4:s_71f899d5",
	options = {
		{"@conversation/corellia_rebel_tier4:s_34d61fa3", "intro_met"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/corellia_rebel_tier4:s_a5958aac",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/corellia_rebel_tier4:s_647ad2bc", "duty_destroy"},
		{"@conversation/corellia_rebel_tier4:s_d9116b4d", "duty_escort"},
		{"@conversation/corellia_rebel_tier4:s_8450d7db", "duty_recovery"},
		{"@conversation/corellia_rebel_tier4:s_9943289", "duty_rescue"},
		{"@conversation/corellia_rebel_tier4:s_9775f996", "duty_info"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "no_master",
	leftDialog = "@conversation/corellia_rebel_tier4:s_b6b4b241",
	animation = "beckon",
	options = {
		{"@conversation/corellia_rebel_tier4:s_bbe3529b", "s_bcbc9230"},
		{"@conversation/corellia_rebel_tier4:s_36f346a5", "s_8057f803"},
	}
})
arkon_convo:addScreen(ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/corellia_rebel_tier4:s_d318a2bb",
	options = {
		{"@conversation/corellia_rebel_tier4:s_647ad2bc", "duty_destroy"},
		{"@conversation/corellia_rebel_tier4:s_d9116b4d", "duty_escort"},
		{"@conversation/corellia_rebel_tier4:s_8450d7db", "duty_recovery"},
		{"@conversation/corellia_rebel_tier4:s_9943289", "duty_rescue"},
		{"@conversation/corellia_rebel_tier4:s_9775f996", "duty_info"},
	}
})

addConversationTemplate("arkon_convo", arkon_convo)
