dulios_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "duliosConvoHandler",
	screens = {}
}

not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_privateer_tier3:s_406e1216",
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
dulios_convo_template:addScreen(not_pilot);

wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2734ffac",
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(wrong_faction);

pilot_not_rsf = ConvoScreen:new {
	id = "pilot_not_rsf",
	leftDialog = "@conversation/naboo_privateer_tier3:s_843db48d",
	stopConversation = "true",
	animation = "shake_head_no",
	options = {}
}
dulios_convo_template:addScreen(pilot_not_rsf);

not_tier3 = ConvoScreen:new {
	id = "not_tier3",
	leftDialog = "@conversation/naboo_privateer_tier3:s_406e1216", -- Looks like you took a wrong turn somewhere. Scram.
	stopConversation = "true",
	animation = "check_wrist_device",
	options = {}
}
dulios_convo_template:addScreen(not_tier3);

on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e15039ea",
	stopConversation = "true",
	animation = "stretch",
	options = {}
}
dulios_convo_template:addScreen(on_mission);

first_mission = ConvoScreen:new {
	id = "first_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_a31b65f9",
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/naboo_privateer_tier3:s_c551ea96", "m1_4ad40b9b"}, -- Looks that way.
		{"@conversation/naboo_privateer_tier3:s_89ae25d4", "m1_e85927c2"}
	}
}
dulios_convo_template:addScreen(first_mission);

m1_4ad40b9b = ConvoScreen:new {
	id = "m1_4ad40b9b",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4ad40b9b",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_fa9d37d5", "m1_8e574ecb"},
		{"@conversation/naboo_privateer_tier3:s_ee08441", "m1_b7137723"}
	}
}
dulios_convo_template:addScreen(m1_4ad40b9b);

m1_8e574ecb = ConvoScreen:new {
	id = "m1_8e574ecb",
	leftDialog = "@conversation/naboo_privateer_tier3:s_8e574ecb",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_76703443", "m1_c65cf2da"}
	}
}
dulios_convo_template:addScreen(m1_8e574ecb);

m1_c65cf2da = ConvoScreen:new {
	id = "m1_c65cf2da",
	leftDialog = "@conversation/naboo_privateer_tier3:s_c65cf2da",
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier3:s_38e0a377", "m1_49772db3"}
	}
}
dulios_convo_template:addScreen(m1_c65cf2da);

m1_49772db3 = ConvoScreen:new {
	id = "m1_49772db3",
	leftDialog = "@conversation/naboo_privateer_tier3:s_49772db3",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_707ab918", "m1_333a7093"}
	}
}
dulios_convo_template:addScreen(m1_49772db3);

m1_333a7093 = ConvoScreen:new {
	id = "m1_333a7093",
	leftDialog = "@conversation/naboo_privateer_tier3:s_333a7093",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_1839ef54", "m1_96924c42"}
	}
}
dulios_convo_template:addScreen(m1_333a7093);

m1_96924c42 = ConvoScreen:new {
	id = "m1_96924c42",
	leftDialog = "@conversation/naboo_privateer_tier3:s_96924c42",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6aba4373", "m1_21bb034b"},
		{"@conversation/naboo_privateer_tier3:s_41a8901f", "m1_19ab407"}
	}
}
dulios_convo_template:addScreen(m1_96924c42);

m1_21bb034b = ConvoScreen:new {
	id = "m1_21bb034b",
	leftDialog = "@conversation/naboo_privateer_tier3:s_21bb034b",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7478d95d", "m1_d84b1644"}
	}
}
dulios_convo_template:addScreen(m1_21bb034b);

m1_d84b1644 = ConvoScreen:new {
	id = "m1_d84b1644",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d84b1644",
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_9851897f"}
	}
}
dulios_convo_template:addScreen(m1_d84b1644);

m1_9851897f = ConvoScreen:new {
	id = "m1_9851897f",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_e1e07205"}
	}
}
dulios_convo_template:addScreen(m1_9851897f);

m1_e1e07205 = ConvoScreen:new {
	id = "m1_e1e07205",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205",
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_e1e07205);

m1_19ab407 = ConvoScreen:new {
	id = "m1_19ab407",
	leftDialog = "@conversation/naboo_privateer_tier3:s_19ab407",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_efb3dd1e", "m1_ec96bcc4"},
		{"@conversation/naboo_privateer_tier3:s_9d51a937", "m1_a8a872ba"}
	}
}
dulios_convo_template:addScreen(m1_19ab407);

m1_ec96bcc4 = ConvoScreen:new {
	id = "m1_ec96bcc4",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ec96bcc4",
	stopConversation = "false",
	animation = "smack_self",
	options = {
		{"@conversation/naboo_privateer_tier3:s_eb9af09b", "m1_3271f1e9"}
	}
}
dulios_convo_template:addScreen(m1_ec96bcc4);

m1_3271f1e9 = ConvoScreen:new {
	id = "m1_3271f1e9",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3271f1e9",
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_b8c1a96f", "m1_70"}
	}
}
dulios_convo_template:addScreen(m1_3271f1e9);

m1_70 = ConvoScreen:new {
	id = "m1_70",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_70);

m1_a8a872ba = ConvoScreen:new {
	id = "m1_a8a872ba",
	leftDialog = "@conversation/naboo_privateer_tier3:s_a8a872ba",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_f2eec235", "m1_fcd5590a"}
	}
}
dulios_convo_template:addScreen(m1_a8a872ba);

m1_fcd5590a = ConvoScreen:new {
	id = "m1_fcd5590a",
	leftDialog = "@conversation/naboo_privateer_tier3:s_fcd5590a",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_b8c1a96f", "m1_78"} -- Hm. That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_fcd5590a);

m1_78 = ConvoScreen:new {
	id = "m1_78",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(m1_78);

m1_b7137723 = ConvoScreen:new {
	id = "m1_b7137723",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b7137723",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_589399fa", "m1_4bdc789d"},
		{"@conversation/naboo_privateer_tier3:s_af5ccac", "m1_55a8fc90"}
	}
}
dulios_convo_template:addScreen(m1_b7137723);

m1_4bdc789d = ConvoScreen:new {
	id = "m1_4bdc789d",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4bdc789d",
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/naboo_privateer_tier3:s_51ca1520", "m1_85"}
	}
}
dulios_convo_template:addScreen(m1_4bdc789d);

m1_85 = ConvoScreen:new {
	id = "m1_85",
	leftDialog = "@conversation/naboo_privateer_tier3:s_96924c42", -- A couple of ambassadors, for starters. But that's not why we're interested in him. Word is, his next target is the Queen.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6aba4373", "m1_89"}, -- [low whistle]
		{"@conversation/naboo_privateer_tier3:s_841d27db", "m1_d5861157"} -- Why?
	}
}
dulios_convo_template:addScreen(m1_85);

m1_89 = ConvoScreen:new {
	id = "m1_89",
	leftDialog = "@conversation/naboo_privateer_tier3:s_21bb034b", -- You got it. And we want to keep that a little-known fact, if you get my drift.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7478d95d", "m1_be0b0711"} -- Loud and clear. Where to?
	}
}
dulios_convo_template:addScreen(m1_89);

m1_be0b0711 = ConvoScreen:new {
	id = "m1_be0b0711",
	leftDialog = "@conversation/naboo_privateer_tier3:s_be0b0711",
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_96"} -- There's more?
	}
}
dulios_convo_template:addScreen(m1_be0b0711);

m1_96 = ConvoScreen:new {
	id = "m1_96",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f", -- We want him alive.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_100"} -- That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_96);

m1_100 = ConvoScreen:new {
	id = "m1_100",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_100);

m1_d5861157 = ConvoScreen:new {
	id = "m1_d5861157",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d5861157",
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier3:s_1aa056a8", "m1_7009d8d"}
	}
}
dulios_convo_template:addScreen(m1_d5861157);

m1_7009d8d = ConvoScreen:new {
	id = "m1_7009d8d",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7009d8d",
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/naboo_privateer_tier3:s_84c9860e", "m1_36507434"}
	}
}
dulios_convo_template:addScreen(m1_7009d8d);

m1_36507434 = ConvoScreen:new {
	id = "m1_36507434",
	leftDialog = "@conversation/naboo_privateer_tier3:s_36507434",
	stopConversation = "false",
	animation = "smack_self",
	options = {
		{"@conversation/naboo_privateer_tier3:s_984c29f6", "m1_110"}
	}
}
dulios_convo_template:addScreen(m1_36507434);

m1_110 = ConvoScreen:new {
	id = "m1_110",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d84b1644", -- I'm not done.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_114"} -- There's more?
	}
}
dulios_convo_template:addScreen(m1_110);

m1_114 = ConvoScreen:new {
	id = "m1_114",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f", -- We want him alive.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_118"} -- That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_114);

m1_118 = ConvoScreen:new {
	id = "m1_118",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_118);

m1_55a8fc90 = ConvoScreen:new {
	id = "m1_55a8fc90",
	leftDialog = "@conversation/naboo_privateer_tier3:s_55a8fc90",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_be88ef61", "m1_123"}
	}
}
dulios_convo_template:addScreen(m1_55a8fc90);

m1_123 = ConvoScreen:new {
	id = "m1_123",
	leftDialog = "@conversation/naboo_privateer_tier3:s_96924c42", -- A couple of ambassadors, for starters. But that's not why we're interested in him. Word is, his next target is the Queen.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6aba4373", "m1_127"} -- [low whistle]
	}
}
dulios_convo_template:addScreen(m1_123);

m1_127 = ConvoScreen:new {
	id = "m1_127",
	leftDialog = "@conversation/naboo_privateer_tier3:s_21bb034b", -- You got it. And we want to keep that a little-known fact, if you get my drift.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7478d95d", "m1_131"} -- Loud and clear. Where to?
	}
}
dulios_convo_template:addScreen(m1_127);

m1_131 = ConvoScreen:new {
	id = "m1_131",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d84b1644", -- I'm not done.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_135"} -- There's more?
	}
}
dulios_convo_template:addScreen(m1_131);

m1_135 = ConvoScreen:new {
	id = "m1_135",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f", -- We want him alive.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_139"} -- That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_135);

m1_139 = ConvoScreen:new {
	id = "m1_139",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_139);

m1_e85927c2 = ConvoScreen:new {
	id = "m1_e85927c2",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e85927c2",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier3:s_a6f174c", "m1_ab3f1614"}
	}
}
dulios_convo_template:addScreen(m1_e85927c2);

m1_ab3f1614 = ConvoScreen:new {
	id = "m1_ab3f1614",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ab3f1614",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_df607c49", "m1_1d2b4360"}
	}
}
dulios_convo_template:addScreen(m1_ab3f1614);

m1_1d2b4360 = ConvoScreen:new {
	id = "m1_1d2b4360",
	leftDialog = "@conversation/naboo_privateer_tier3:s_1d2b4360",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_24ee6c29", "m1_bf22a8c8"},
		{"@conversation/naboo_privateer_tier3:s_2df26676", "m1_d6b3034c"}
	}
}
dulios_convo_template:addScreen(m1_1d2b4360);

m1_bf22a8c8 = ConvoScreen:new {
	id = "m1_bf22a8c8",
	leftDialog = "@conversation/naboo_privateer_tier3:s_bf22a8c8",
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_privateer_tier3:s_5772fc88", "m1_919b5558"}
	}
}
dulios_convo_template:addScreen(m1_bf22a8c8);

m1_919b5558 = ConvoScreen:new {
	id = "m1_919b5558",
	leftDialog = "@conversation/naboo_privateer_tier3:s_919b5558",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6aba4373", "m1_153"} -- [low whistle]
	}
}
dulios_convo_template:addScreen(m1_919b5558);

m1_153 = ConvoScreen:new {
	id = "m1_153",
	leftDialog = "@conversation/naboo_privateer_tier3:s_21bb034b", -- You got it. And we want to keep that a little-known fact, if you get my drift.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7478d95d", "m1_157"} -- Loud and clear. Where to?
	}
}
dulios_convo_template:addScreen(m1_153);

m1_157 = ConvoScreen:new {
	id = "m1_157",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d84b1644", -- I'm not done.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_161"} -- There's more?
	}
}
dulios_convo_template:addScreen(m1_157);

m1_161 = ConvoScreen:new {
	id = "m1_161",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f", -- We want him alive.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_165"} -- That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_161);

m1_165 = ConvoScreen:new {
	id = "m1_165",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_165);

m1_d6b3034c = ConvoScreen:new {
	id = "m1_d6b3034c",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d6b3034c",
	stopConversation = "false",
	animation = "rub_belly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_1ebb58e3", "m1_2c556bd9"}
	}
}
dulios_convo_template:addScreen(m1_d6b3034c);

m1_2c556bd9 = ConvoScreen:new {
	id = "m1_2c556bd9",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2c556bd9",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_d5b06d9e", "m1_88a726df"}
	}
}
dulios_convo_template:addScreen(m1_2c556bd9);

m1_88a726df = ConvoScreen:new {
	id = "m1_88a726df",
	leftDialog = "@conversation/naboo_privateer_tier3:s_88a726df",
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_privateer_tier3:s_b1da46d", "m1_174"}
	}
}
dulios_convo_template:addScreen(m1_88a726df);

m1_174 = ConvoScreen:new {
	id = "m1_174",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d84b1644", -- I'm not done.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_acc52186", "m1_178"} -- There's more?
	}
}
dulios_convo_template:addScreen(m1_174);

m1_178 = ConvoScreen:new {
	id = "m1_178",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9851897f", -- We want him alive.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ebe811bd", "m1_182"} -- That makes it a little more complicated.
	}
}
dulios_convo_template:addScreen(m1_178);

m1_182 = ConvoScreen:new {
	id = "m1_182",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1e07205", -- All you need to do is stop his ship. The boys in the lab are putting together a little surprise for him, but it's up to you to deliver the package.  Get over to the Dantooine System; we'll update you from there.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_182);

second_mission = ConvoScreen:new {
	id = "second_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_8de81731",
	stopConversation = "false",
	animation = "weeping",
	options = {
		{"@conversation/naboo_privateer_tier3:s_98427ee4", "m2_d5f1fa36"},
		{"@conversation/naboo_privateer_tier3:s_2ca7d4f4", "m2_be2c5a18"},
		{"@conversation/naboo_privateer_tier3:s_719a036e", "m2_928dcf38"}
	}
}
dulios_convo_template:addScreen(second_mission);

m2_d5f1fa36 = ConvoScreen:new {
	id = "m2_d5f1fa36",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d5f1fa36",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_18868d04", "m2_b43b6c14"}
	}
}
dulios_convo_template:addScreen(m2_d5f1fa36);

m2_b43b6c14 = ConvoScreen:new {
	id = "m2_b43b6c14",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b43b6c14",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_e7b0a6c9", "m2_653b9611"}
	}
}
dulios_convo_template:addScreen(m2_b43b6c14);

m2_653b9611 = ConvoScreen:new {
	id = "m2_653b9611",
	leftDialog = "@conversation/naboo_privateer_tier3:s_653b9611",
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier3:s_d919151c", "m2_6bd02793"},
		{"@conversation/naboo_privateer_tier3:s_d5d85519", "m2_b2ff9cb"}
	}
}
dulios_convo_template:addScreen(m2_653b9611);

m2_6bd02793 = ConvoScreen:new {
	id = "m2_6bd02793",
	leftDialog = "@conversation/naboo_privateer_tier3:s_6bd02793",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2bc43dfd", "m2_f92d904a"}
	}
}
dulios_convo_template:addScreen(m2_6bd02793);

m2_f92d904a = ConvoScreen:new {
	id = "m2_f92d904a",
	leftDialog = "@conversation/naboo_privateer_tier3:s_f92d904a",
	stopConversation = "false",
	animation = "tap_foot",
	options = {
		{"@conversation/naboo_privateer_tier3:s_800cd173", "m2_7278c01"}
	}
}
dulios_convo_template:addScreen(m2_f92d904a);

m2_7278c01 = ConvoScreen:new {
	id = "m2_7278c01",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7278c01",
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6540bc41", "m2_72c4169a"}
	}
}
dulios_convo_template:addScreen(m2_7278c01);

m2_72c4169a = ConvoScreen:new {
	id = "m2_72c4169a",
	leftDialog = "@conversation/naboo_privateer_tier3:s_72c4169a",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7a9f14df", "m2_3b32ba04"}
	}
}
dulios_convo_template:addScreen(m2_72c4169a);

m2_3b32ba04 = ConvoScreen:new {
	id = "m2_3b32ba04",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3b32ba04",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2b6e8499", "m2_17dec7f9"}
	}
}
dulios_convo_template:addScreen(m2_3b32ba04);

m2_17dec7f9 = ConvoScreen:new {
	id = "m2_17dec7f9",
	leftDialog = "@conversation/naboo_privateer_tier3:s_17dec7f9",
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6bdcb65c", "m2_61968e69"}
	}
}
dulios_convo_template:addScreen(m2_17dec7f9);

m2_61968e69 = ConvoScreen:new {
	id = "m2_61968e69",
	leftDialog = "@conversation/naboo_privateer_tier3:s_61968e69",
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m2_61968e69);

m2_b2ff9cb = ConvoScreen:new {
	id = "m2_b2ff9cb",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b2ff9cb",
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier3:s_ad973bd9", "m2_ea9bff27"}
	}
}
dulios_convo_template:addScreen(m2_b2ff9cb);

m2_ea9bff27 = ConvoScreen:new {
	id = "m2_ea9bff27",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ea9bff27",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_3895c4ae", "m2_210"}
	}
}
dulios_convo_template:addScreen(m2_ea9bff27);

m2_210 = ConvoScreen:new {
	id = "m2_210",
	leftDialog = "@conversation/naboo_privateer_tier3:s_6bd02793", -- Nothing.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2bc43dfd", "m2_3c468733"} -- Come again?
	}
}
dulios_convo_template:addScreen(m2_210);

m2_3c468733 = ConvoScreen:new {
	id = "m2_3c468733",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3c468733",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_800cd173", "m2_217"} -- You gotta give me a better explanation than that.
	}
}
dulios_convo_template:addScreen(m2_3c468733);

m2_217 = ConvoScreen:new {
	id = "m2_217",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7278c01", -- I don't have to give you BUPKIS. But I'll tell ya 'cause I'm feeling generous. This is a decoy ship. The real goods are on another transport.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6540bc41", "m2_221"} -- Who's gunning for it?
	}
}
dulios_convo_template:addScreen(m2_217);

m2_221 = ConvoScreen:new {
	id = "m2_221",
	leftDialog = "@conversation/naboo_privateer_tier3:s_72c4169a", -- Ay'Nat Pirate Faction. They want what that ship's got. Or what they THINK it's got, anyway.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7a9f14df", "m2_225"} -- So I'm guarding nothing.
	}
}
dulios_convo_template:addScreen(m2_221);

m2_225 = ConvoScreen:new {
	id = "m2_225",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3b32ba04", -- You're providing a valuable service to the Royal Security Forces of Naboo.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2b6e8499", "m2_229"} -- As long as I get to shoot down a couple of pirate ships, I'm happy.
	}
}
dulios_convo_template:addScreen(m2_225);

m2_229 = ConvoScreen:new {
	id = "m2_229",
	leftDialog = "@conversation/naboo_privateer_tier3:s_17dec7f9", -- Then get in your ship and get happy.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6bdcb65c", "m2_233"} -- Just tell me where to go.
	}
}
dulios_convo_template:addScreen(m2_229);

m2_233 = ConvoScreen:new {
	id = "m2_233",
	leftDialog = "@conversation/naboo_privateer_tier3:s_61968e69", -- The freighter's in orbit around Naboo. See ya.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m2_233);

m2_be2c5a18 = ConvoScreen:new {
	id = "m2_be2c5a18",
	leftDialog = "@conversation/naboo_privateer_tier3:s_be2c5a18",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_731caa45", "m2_70b9cf4c"}
	}
}
dulios_convo_template:addScreen(m2_be2c5a18);

m2_70b9cf4c = ConvoScreen:new {
	id = "m2_70b9cf4c",
	leftDialog = "@conversation/naboo_privateer_tier3:s_70b9cf4c",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier3:s_992fcb9e", "m2_80a39a22"}
	}
}
dulios_convo_template:addScreen(m2_70b9cf4c);

m2_80a39a22 = ConvoScreen:new {
	id = "m2_80a39a22",
	leftDialog = "@conversation/naboo_privateer_tier3:s_80a39a22",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2dbfc867", "m2_dfc8b68e"}
	}
}
dulios_convo_template:addScreen(m2_80a39a22);

m2_dfc8b68e = ConvoScreen:new {
	id = "m2_dfc8b68e",
	leftDialog = "@conversation/naboo_privateer_tier3:s_dfc8b68e",
	stopConversation = "false",
	animation = "rub_belly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_dc54e9e4", "m2_d3583e11"}
	}
}
dulios_convo_template:addScreen(m2_dfc8b68e);

m2_d3583e11 = ConvoScreen:new {
	id = "m2_d3583e11",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d3583e11",
	stopConversation = "false",
	animation = "stretch",
	options = {
		{"@conversation/naboo_privateer_tier3:s_d5d8a006", "m2_b8955212"}
	}
}
dulios_convo_template:addScreen(m2_d3583e11);

m2_b8955212 = ConvoScreen:new {
	id = "m2_b8955212",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b8955212",
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
dulios_convo_template:addScreen(m2_b8955212);

m2_928dcf38 = ConvoScreen:new {
	id = "m2_928dcf38",
	leftDialog = "@conversation/naboo_privateer_tier3:s_928dcf38",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_f80d4276", "m2_7b05ff95"}
	}
}
dulios_convo_template:addScreen(m2_928dcf38);

m2_7b05ff95 = ConvoScreen:new {
	id = "m2_7b05ff95",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7b05ff95",
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_privateer_tier3:s_53de9d8f", "m2_4f5f8321"}
	}
}
dulios_convo_template:addScreen(m2_7b05ff95);

m2_4f5f8321 = ConvoScreen:new {
	id = "m2_4f5f8321",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4f5f8321",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_8be640b8", "m2_e1775a2f"}
	}
}
dulios_convo_template:addScreen(m2_4f5f8321);

m2_e1775a2f = ConvoScreen:new {
	id = "m2_e1775a2f",
	leftDialog = "@conversation/naboo_privateer_tier3:s_e1775a2f",
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier3:s_47d51826", "m2_4636b7d1"}
	}
}
dulios_convo_template:addScreen(m2_e1775a2f);

m2_4636b7d1 = ConvoScreen:new {
	id = "m2_4636b7d1",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4636b7d1",
	stopConversation = "false",
	animation = "smell_armpit",
	options = {
		{"@conversation/naboo_privateer_tier3:s_cc756770", "m2_738baf5a"}
	}
}
dulios_convo_template:addScreen(m2_4636b7d1);

m2_738baf5a = ConvoScreen:new {
	id = "m2_738baf5a",
	leftDialog = "@conversation/naboo_privateer_tier3:s_738baf5a",
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2d582b36", "m2_2c397539"}
	}
}
dulios_convo_template:addScreen(m2_738baf5a);

m2_2c397539 = ConvoScreen:new {
	id = "m2_2c397539",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2c397539",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_992fcb9e", "m2_263"} -- Hm! Must be carrying something good.
	}
}
dulios_convo_template:addScreen(m2_2c397539);

m2_263 = ConvoScreen:new {
	id = "m2_263",
	leftDialog = "@conversation/naboo_privateer_tier3:s_80a39a22", -- Not exactly. This is a decoy ship. The REAL goods are somewhere else.
	stopConversation = "false",
	animation = "rub_belly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_2dbfc867", "m2_267"} -- Somebody's going to a lot of trouble! Must be quite a juicy haul they're protecting.
	}
}
dulios_convo_template:addScreen(m2_263);

m2_267 = ConvoScreen:new {
	id = "m2_267",
	leftDialog = "@conversation/naboo_privateer_tier3:s_dfc8b68e", -- The juiciest.
	stopConversation = "false",
	animation = "snap_finger1",
	options = {
		{"@conversation/naboo_privateer_tier3:s_dc54e9e4", "m2_42d73452"} -- Can you tell me what it is?
	}
}
dulios_convo_template:addScreen(m2_267);

m2_42d73452 = ConvoScreen:new {
	id = "m2_42d73452",
	leftDialog = "@conversation/naboo_privateer_tier3:s_42d73452",
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier3:s_d5d8a006", "m2_274"} -- But what they'll get is me.
	}
}
dulios_convo_template:addScreen(m2_42d73452);

m2_274 = ConvoScreen:new {
	id = "m2_274",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b8955212", -- Double helping. The freighter is up around Naboo; you're clear to go.
	stopConversation = "true",
	animation = "stretch",
	options = {}
}
dulios_convo_template:addScreen(m2_274);

third_mission = ConvoScreen:new {
	id = "third_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_29a181c",
	stopConversation = "false",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier3:s_d5b8e3f8", "m3_7e23ff31"},
		{"@conversation/naboo_privateer_tier3:s_f2697794", "m3_efff0139"}
	}
}
dulios_convo_template:addScreen(third_mission);

m3_7e23ff31 = ConvoScreen:new {
	id = "m3_7e23ff31",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7e23ff31",
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/naboo_privateer_tier3:s_19b65be5", "m3_7ea4b2be"}
	}
}
dulios_convo_template:addScreen(m3_7e23ff31);

m3_7ea4b2be = ConvoScreen:new {
	id = "m3_7ea4b2be",
	leftDialog = "@conversation/naboo_privateer_tier3:s_7ea4b2be",
	stopConversation = "false",
	animation = "applause_excited",
	options = {
		{"@conversation/naboo_privateer_tier3:s_c0167dab", "m3_80cc6c3b"}
	}
}
dulios_convo_template:addScreen(m3_7ea4b2be);

m3_80cc6c3b = ConvoScreen:new {
	id = "m3_80cc6c3b",
	leftDialog = "@conversation/naboo_privateer_tier3:s_80cc6c3b",
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier3:s_c6e9b9c7", "m3_b6d8cc82"}
	}
}
dulios_convo_template:addScreen(m3_80cc6c3b);

m3_b6d8cc82 = ConvoScreen:new {
	id = "m3_b6d8cc82",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b6d8cc82",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_9ba13c", "m3_8ebe23b3"}
	}
}
dulios_convo_template:addScreen(m3_b6d8cc82);

m3_8ebe23b3 = ConvoScreen:new {
	id = "m3_8ebe23b3",
	leftDialog = "@conversation/naboo_privateer_tier3:s_8ebe23b3",
	stopConversation = "false",
	animation = "smell_armpit",
	options = {
		{"@conversation/naboo_privateer_tier3:s_a41bb8c7", "m3_83905129"}
	}
}
dulios_convo_template:addScreen(m3_8ebe23b3);

m3_83905129 = ConvoScreen:new {
	id = "m3_83905129",
	leftDialog = "@conversation/naboo_privateer_tier3:s_83905129",
	stopConversation = "false",
	animation = "flex_biceps",
	options = {
		{"@conversation/naboo_privateer_tier3:s_66f6527f", "m3_3898bb41"}
	}
}
dulios_convo_template:addScreen(m3_83905129);

m3_3898bb41 = ConvoScreen:new {
	id = "m3_3898bb41",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3898bb41",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_5bd69df6", "m3_c4095762"}
	}
}
dulios_convo_template:addScreen(m3_3898bb41);

m3_c4095762 = ConvoScreen:new {
	id = "m3_c4095762",
	leftDialog = "@conversation/naboo_privateer_tier3:s_c4095762",
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m3_c4095762);

m3_efff0139 = ConvoScreen:new {
	id = "m3_efff0139",
	leftDialog = "@conversation/naboo_privateer_tier3:s_efff0139",
	stopConversation = "false",
	animation = "yawn",
	options = {
		{"@conversation/naboo_privateer_tier3:s_97b0942d", "m3_83c29fd0"}
	}
}
dulios_convo_template:addScreen(m3_efff0139);

m3_83c29fd0 = ConvoScreen:new {
	id = "m3_83c29fd0",
	leftDialog = "@conversation/naboo_privateer_tier3:s_83c29fd0",
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_privateer_tier3:s_c3363bcd", "m3_5075e20b"},
		{"@conversation/naboo_privateer_tier3:s_98448a60", "m3_ddd7e395"}
	}
}
dulios_convo_template:addScreen(m3_83c29fd0);

m3_5075e20b = ConvoScreen:new {
	id = "m3_5075e20b",
	leftDialog = "@conversation/naboo_privateer_tier3:s_5075e20b",
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_4b6422f4", "m3_fc59c904"}
	}
}
dulios_convo_template:addScreen(m3_5075e20b);

m3_fc59c904 = ConvoScreen:new {
	id = "m3_fc59c904",
	leftDialog = "@conversation/naboo_privateer_tier3:s_fc59c904",
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_41d3138c", "m3_68d4ba6b"}
	}
}
dulios_convo_template:addScreen(m3_fc59c904);

m3_68d4ba6b = ConvoScreen:new {
	id = "m3_68d4ba6b",
	leftDialog = "@conversation/naboo_privateer_tier3:s_68d4ba6b",
	stopConversation = "false",
	animation = "rub_belly",
	options = {
		{"@conversation/naboo_privateer_tier3:s_9d9af42e", "m3_76734574"}
	}
}
dulios_convo_template:addScreen(m3_68d4ba6b);

m3_76734574 = ConvoScreen:new {
	id = "m3_76734574",
	leftDialog = "@conversation/naboo_privateer_tier3:s_76734574",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6c251948", "m3_3fa8b6f1"}
	}
}
dulios_convo_template:addScreen(m3_76734574);

m3_3fa8b6f1 = ConvoScreen:new {
	id = "m3_3fa8b6f1",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3fa8b6f1",
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m3_3fa8b6f1);

m3_ddd7e395 = ConvoScreen:new {
	id = "m3_ddd7e395",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ddd7e395",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier3:s_c089dba4", "m3_88e6f763"}
	}
}
dulios_convo_template:addScreen(m3_ddd7e395);

m3_88e6f763 = ConvoScreen:new {
	id = "m3_88e6f763",
	leftDialog = "@conversation/naboo_privateer_tier3:s_88e6f763",
	stopConversation = "false",
	animation = "tap_foot",
	options = {
		{"@conversation/naboo_privateer_tier3:s_a56734f6", "m3_a09da7f1"}
	}
}
dulios_convo_template:addScreen(m3_88e6f763);

m3_a09da7f1 = ConvoScreen:new {
	id = "m3_a09da7f1",
	leftDialog = "@conversation/naboo_privateer_tier3:s_a09da7f1",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_3b315f68", "m3_2b25d03f"},
		{"@conversation/naboo_privateer_tier3:s_c5fdab6d", "m3_942ba0c6"}
	}
}
dulios_convo_template:addScreen(m3_a09da7f1);

m3_2b25d03f = ConvoScreen:new {
	id = "m3_2b25d03f",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2b25d03f",
	stopConversation = "false",
	animation = "whisper",
	options = {
		{"@conversation/naboo_privateer_tier3:s_1d418957", "m3_4ebef758"}
	}
}
dulios_convo_template:addScreen(m3_2b25d03f);

m3_4ebef758 = ConvoScreen:new {
	id = "m3_4ebef758",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4ebef758",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier3:s_4b6422f4", "m3_319"} -- Why do you work with the RSF if you hate politicians so much?
	}
}
dulios_convo_template:addScreen(m3_4ebef758);

m3_319 = ConvoScreen:new {
	id = "m3_319",
	leftDialog = "@conversation/naboo_privateer_tier3:s_fc59c904", -- The benefits are good. Now listen up. Naboo's hosting a conference. Diplomats are coming in from all over. And odds are, some of them are carrying contraband.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_41d3138c", "m3_323"} -- Why would they take that chance?
	}
}
dulios_convo_template:addScreen(m3_319);

m3_323 = ConvoScreen:new {
	id = "m3_323",
	leftDialog = "@conversation/naboo_privateer_tier3:s_68d4ba6b", -- To be honest, it's probably not them. It's probably smugglers taking advantage of the opportunity, and hiding gear on their ship. Doesn't matter. Same difference.
	stopConversation = "false",
	animation = "stretch",
	options = {
		{"@conversation/naboo_privateer_tier3:s_9d9af42e", "m3_327"} -- Where are these diplomats?
	}
}
dulios_convo_template:addScreen(m3_323);

m3_327 = ConvoScreen:new {
	id = "m3_327",
	leftDialog = "@conversation/naboo_privateer_tier3:s_76734574", -- En route. Fly out to the waypoint and get ready to inspect each and every one of them.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6c251948", "m3_331"} -- You got it.
	}
}
dulios_convo_template:addScreen(m3_327);

m3_331 = ConvoScreen:new {
	id = "m3_331",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3fa8b6f1", -- Coordinates are in your ship. You're clear to leave.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m3_331);

m3_942ba0c6 = ConvoScreen:new {
	id = "m3_942ba0c6",
	leftDialog = "@conversation/naboo_privateer_tier3:s_942ba0c6",
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier3:s_4b6422f4", "m3_337"} -- Why do you work with the RSF if you hate politicians so much?
	}
}
dulios_convo_template:addScreen(m3_942ba0c6);

m3_337 = ConvoScreen:new {
	id = "m3_337",
	leftDialog = "@conversation/naboo_privateer_tier3:s_fc59c904", -- The benefits are good. Now listen up. Naboo's hosting a conference. Diplomats are coming in from all over. And odds are, some of them are carrying contraband.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier3:s_41d3138c", "m3_341"} -- Why would they take that chance?
	}
}
dulios_convo_template:addScreen(m3_337);

m3_341 = ConvoScreen:new {
	id = "m3_341",
	leftDialog = "@conversation/naboo_privateer_tier3:s_68d4ba6b", -- To be honest, it's probably not them. It's probably smugglers taking advantage of the opportunity, and hiding gear on their ship. Doesn't matter. Same difference.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier3:s_9d9af42e", "m3_345"} -- Where are these diplomats?
	}
}
dulios_convo_template:addScreen(m3_341);

m3_345 = ConvoScreen:new {
	id = "m3_345",
	leftDialog = "@conversation/naboo_privateer_tier3:s_76734574", -- En route. Fly out to the waypoint and get ready to inspect each and every one of them.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_6c251948", "m3_349"} -- You got it.
	}
}
dulios_convo_template:addScreen(m3_345);

m3_349 = ConvoScreen:new {
	id = "m3_349",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3fa8b6f1", -- Coordinates are in your ship. You're clear to leave.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m3_349);

fourth_mission = ConvoScreen:new {
	id = "fourth_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_70e76a9a",
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/naboo_privateer_tier3:s_5a889c20", "m4_2b9a70e4"},
		{"@conversation/naboo_privateer_tier3:s_5a2317e2", "m4_47152ac5"}
	}
}
dulios_convo_template:addScreen(fourth_mission);

m4_2b9a70e4 = ConvoScreen:new {
	id = "m4_2b9a70e4",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2b9a70e4",
	stopConversation = "false",
	animation = "accept_affection",
	options = {
		{"@conversation/naboo_privateer_tier3:s_7339c95e", "m4_5ed53186"}
	}
}
dulios_convo_template:addScreen(m4_2b9a70e4);

m4_5ed53186 = ConvoScreen:new {
	id = "m4_5ed53186",
	leftDialog = "@conversation/naboo_privateer_tier3:s_5ed53186",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_981c060d", "m4_f6976b78"}
	}
}
dulios_convo_template:addScreen(m4_5ed53186);

m4_f6976b78 = ConvoScreen:new {
	id = "m4_f6976b78",
	leftDialog = "@conversation/naboo_privateer_tier3:s_f6976b78",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_9d1fa2a2", "m4_d9c145dd"}
	}
}
dulios_convo_template:addScreen(m4_f6976b78);

m4_d9c145dd = ConvoScreen:new {
	id = "m4_d9c145dd",
	leftDialog = "@conversation/naboo_privateer_tier3:s_d9c145dd",
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
dulios_convo_template:addScreen(m4_d9c145dd);

m4_47152ac5 = ConvoScreen:new {
	id = "m4_47152ac5",
	leftDialog = "@conversation/naboo_privateer_tier3:s_47152ac5",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier3:s_f69a2921", "m4_666cac71"}
	}
}
dulios_convo_template:addScreen(m4_47152ac5);

m4_666cac71 = ConvoScreen:new {
	id = "m4_666cac71",
	leftDialog = "@conversation/naboo_privateer_tier3:s_666cac71",
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/naboo_privateer_tier3:s_e49c6b33", "m4_3c432969"}
	}
}
dulios_convo_template:addScreen(m4_666cac71);

m4_3c432969 = ConvoScreen:new {
	id = "m4_3c432969",
	leftDialog = "@conversation/naboo_privateer_tier3:s_3c432969",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_692788e8", "m4_46eb0ec8"}
	}
}
dulios_convo_template:addScreen(m4_3c432969);

m4_46eb0ec8 = ConvoScreen:new {
	id = "m4_46eb0ec8",
	leftDialog = "@conversation/naboo_privateer_tier3:s_46eb0ec8",
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m4_46eb0ec8);

failed_first_mission = ConvoScreen:new {
	id = "failed_first_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_cae364a9",
	stopConversation = "false",
	animation = "snap_finger1",
	options = {
		{"@conversation/naboo_privateer_tier3:s_5a236288", "m1_retry_2bcd2d13"},
		{"@conversation/naboo_privateer_tier3:s_c551ea96", "m1_retry_ff7bebda"}
	}
}
dulios_convo_template:addScreen(failed_first_mission);

m1_retry_2bcd2d13 = ConvoScreen:new {
	id = "m1_retry_2bcd2d13",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2bcd2d13",
	stopConversation = "true",
	animation = "tap_foot",
	options = {}
}
dulios_convo_template:addScreen(m1_retry_2bcd2d13);

m1_retry_ff7bebda = ConvoScreen:new {
	id = "m1_retry_ff7bebda",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ff7bebda",
	stopConversation = "true",
	animation = "explain",
	options = {}
}
dulios_convo_template:addScreen(m1_retry_ff7bebda);

failed_second_mission = ConvoScreen:new {
	id = "failed_second_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_41480145",
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/naboo_privateer_tier3:s_800745bc", "m2_retry_327eb2d6"},
		{"@conversation/naboo_privateer_tier3:s_19425c2f", "m2_retry_145dcab"}
	}
}
dulios_convo_template:addScreen(failed_second_mission);

m2_retry_327eb2d6 = ConvoScreen:new {
	id = "m2_retry_327eb2d6",
	leftDialog = "@conversation/naboo_privateer_tier3:s_327eb2d6",
	stopConversation = "true",
	animation = "tap_head",
	options = {}
}
dulios_convo_template:addScreen(m2_retry_327eb2d6);

m2_retry_145dcab = ConvoScreen:new {
	id = "m2_retry_145dcab",
	leftDialog = "@conversation/naboo_privateer_tier3:s_145dcab",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dulios_convo_template:addScreen(m2_retry_145dcab);

failed_third_mission = ConvoScreen:new {
	id = "failed_third_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_97e76dd",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_privateer_tier3:s_b144d69b", "m3_retry_2852c031"},
		{"@conversation/naboo_privateer_tier3:s_a5fe9928", "m3_retry_b679efe"}
	}
}
dulios_convo_template:addScreen(failed_third_mission);

m3_retry_2852c031 = ConvoScreen:new {
	id = "m3_retry_2852c031",
	leftDialog = "@conversation/naboo_privateer_tier3:s_2852c031",
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
dulios_convo_template:addScreen(m3_retry_2852c031);

m3_retry_b679efe = ConvoScreen:new {
	id = "m3_retry_b679efe",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b679efe",
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
dulios_convo_template:addScreen(m3_retry_b679efe);

failed_fourth_mission = ConvoScreen:new {
	id = "failed_fourth_mission",
	leftDialog = "@conversation/naboo_privateer_tier3:s_53daee1c",
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier3:s_83b47a80", "m4_retry_57d34626"},
		{"@conversation/naboo_privateer_tier3:s_841d27db", "m4_retry_ff5d0ba8"}
	}
}
dulios_convo_template:addScreen(failed_fourth_mission);

m4_retry_57d34626 = ConvoScreen:new {
	id = "m4_retry_57d34626",
	leftDialog = "@conversation/naboo_privateer_tier3:s_57d34626",
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {}
}
dulios_convo_template:addScreen(m4_retry_57d34626);

m4_retry_ff5d0ba8 = ConvoScreen:new {
	id = "m4_retry_ff5d0ba8",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ff5d0ba8",
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
dulios_convo_template:addScreen(m4_retry_ff5d0ba8);

complete_mission1 = ConvoScreen:new {
	id = "complete_mission1",
	leftDialog = "@conversation/naboo_privateer_tier3:s_b61d6d4f",
	stopConversation = "false",
	animation = "nod_head_once",
	options = {}
}
dulios_convo_template:addScreen(complete_mission1);

complete_mission2 = ConvoScreen:new {
	id = "complete_mission2",
	leftDialog = "@conversation/naboo_privateer_tier3:s_530e5eb4",
	stopConversation = "false",
	options = {}
}
dulios_convo_template:addScreen(complete_mission2);

complete_mission3 = ConvoScreen:new {
	id = "complete_mission3",
	leftDialog = "@conversation/naboo_privateer_tier3:s_f765036a",
	stopConversation = "false",
	animation = "offer_affection",
	options = {}
}
dulios_convo_template:addScreen(complete_mission3);

complete_mission4 = ConvoScreen:new {
	id = "complete_mission4",
	leftDialog = "@conversation/naboo_privateer_tier3:s_ae2d3229",
	stopConversation = "false",
	animation = "salute1",
	options = {}
}
dulios_convo_template:addScreen(complete_mission4);

completed_dulios = ConvoScreen:new {
	id = "completed_dulios",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", -- Aw. I think I'm actually going to miss you - maybe. But duty calls. You're now assigned to Admiral Diness Imler, down the hall - he'll be giving you orders from now on. See ya, %TU.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(completed_dulios);

train_warships = ConvoScreen:new {
	id = "train_warships",
	leftDialog = "@conversation/naboo_privateer_tier3:s_89ff8475", -- Obviously. This pilot will give you a lesson. Afterwards, you come see me for your next mission.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_warships);

train_components = ConvoScreen:new {
	id = "train_components",
	leftDialog = "@conversation/naboo_privateer_tier3:s_9b1d2d87", -- Done. This pilot will give you a lesson. Afterwards, you come see me for your next mission.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_components);

train_techniques = ConvoScreen:new {
	id = "train_techniques",
	leftDialog = "@conversation/naboo_privateer_tier3:s_bd234730", -- You got it. This pilot will give you a lesson. Afterwards, you come see me for your next mission.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_techniques);

train_programming = ConvoScreen:new {
	id = "train_programming",
	leftDialog = "@conversation/naboo_privateer_tier3:s_dcf601cc", -- Don't we all! This pilot will give you a lesson. Afterwards, you come see me for your next mission.
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_programming);

train_warships_final = ConvoScreen:new {
	id = "train_warships_final",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", -- Aw. I think I'm actually going to miss you...
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_warships_final);

train_components_final = ConvoScreen:new {
	id = "train_components_final",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", -- Aw. I think I'm actually going to miss you...
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_components_final);

train_techniques_final = ConvoScreen:new {
	id = "train_techniques_final",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", -- Aw. I think I'm actually going to miss you...
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_techniques_final);

train_programming_final = ConvoScreen:new {
	id = "train_programming_final",
	leftDialog = "@conversation/naboo_privateer_tier3:s_4fc6a099", -- Aw. I think I'm actually going to miss you...
	stopConversation = "true",
	options = {}
}
dulios_convo_template:addScreen(train_programming_final);

addConversationTemplate("dulios_convo_template", dulios_convo_template);
