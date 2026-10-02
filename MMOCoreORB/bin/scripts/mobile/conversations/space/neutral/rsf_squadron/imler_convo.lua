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
	leftDialog = "@conversation/naboo_privateer_tier4:s_9",
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
		{"@conversation/naboo_privateer_tier4:s_416", "s_1993702c"},
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
		{"@conversation/naboo_privateer_tier4:s_453", "s_455"},
		{"@conversation/naboo_privateer_tier4:s_473", "s_475"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_ff6e1247",
	options = {
		{"@conversation/naboo_privateer_tier4:s_491", "s_493"},
		{"@conversation/naboo_privateer_tier4:s_539", "s_541"},
		{"@conversation/naboo_privateer_tier4:s_587", "s_589"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_bdc28bb4",
	options = {
		{"@conversation/naboo_privateer_tier4:s_625", "s_627"},
		{"@conversation/naboo_privateer_tier4:s_709", "s_711"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_brief",
	leftDialog = "@conversation/naboo_privateer_tier4:s_9312a850",
	options = {
		{"@conversation/naboo_privateer_tier4:s_739", "s_741"},
		{"@conversation/naboo_privateer_tier4:s_819", "s_821"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_455",
	leftDialog = "@conversation/naboo_privateer_tier4:s_455",
	options = {
		{"@conversation/naboo_privateer_tier4:s_457", "s_459"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_475",
	leftDialog = "@conversation/naboo_privateer_tier4:s_475",
	animation = "laugh_titter",
	options = {
		{"@conversation/naboo_privateer_tier4:s_477", "s_479"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_493",
	leftDialog = "@conversation/naboo_privateer_tier4:s_493",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_495", "s_497"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_541",
	leftDialog = "@conversation/naboo_privateer_tier4:s_541",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_543", "s_545"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_589",
	leftDialog = "@conversation/naboo_privateer_tier4:s_589",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_591", "s_593"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_627",
	leftDialog = "@conversation/naboo_privateer_tier4:s_627",
	animation = "check_wrist_device",
	options = {
		{"@conversation/naboo_privateer_tier4:s_629", "s_631"},
		{"@conversation/naboo_privateer_tier4:s_665", "s_667"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_711",
	leftDialog = "@conversation/naboo_privateer_tier4:s_711",
	options = {
		{"@conversation/naboo_privateer_tier4:s_713", "s_715"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_741",
	leftDialog = "@conversation/naboo_privateer_tier4:s_741",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_743", "s_745"},
		{"@conversation/naboo_privateer_tier4:s_783", "s_785"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_821",
	leftDialog = "@conversation/naboo_privateer_tier4:s_821",
	options = {
		{"@conversation/naboo_privateer_tier4:s_823", "s_825"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/naboo_privateer_tier4:s_439",
	options = {
		{"@conversation/naboo_privateer_tier4:s_443", "trained_mission1"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/naboo_privateer_tier4:s_440",
	options = {
		{"@conversation/naboo_privateer_tier4:s_445", "trained_mission1"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/naboo_privateer_tier4:s_441",
	options = {
		{"@conversation/naboo_privateer_tier4:s_447", "trained_mission1"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/naboo_privateer_tier4:s_442",
	options = {
		{"@conversation/naboo_privateer_tier4:s_449", "trained_mission1"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "trained_mission4",
	leftDialog = "@conversation/naboo_privateer_tier4:s_451",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_453", "s_455"},
		{"@conversation/naboo_privateer_tier4:s_473", "s_475"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "trained_mission3",
	leftDialog = "@conversation/naboo_privateer_tier4:s_489",
	animation = "laugh_titter",
	options = {
		{"@conversation/naboo_privateer_tier4:s_491", "s_493"},
		{"@conversation/naboo_privateer_tier4:s_539", "s_541"},
		{"@conversation/naboo_privateer_tier4:s_587", "s_589"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "trained_mission2",
	leftDialog = "@conversation/naboo_privateer_tier4:s_623",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier4:s_625", "s_627"},
		{"@conversation/naboo_privateer_tier4:s_709", "s_711"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "trained_mission1",
	leftDialog = "@conversation/naboo_privateer_tier4:s_737",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_739", "s_741"},
		{"@conversation/naboo_privateer_tier4:s_819", "s_821"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_459",
	leftDialog = "@conversation/naboo_privateer_tier4:s_459",
	animation = "salute1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_461", "s_463"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_463",
	leftDialog = "@conversation/naboo_privateer_tier4:s_463",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_465", "s_467"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_467",
	leftDialog = "@conversation/naboo_privateer_tier4:s_467",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_469", "mission4_accept_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_471",
	animation = "salute1",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_479",
	leftDialog = "@conversation/naboo_privateer_tier4:s_479",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_481", "s_483"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_483",
	leftDialog = "@conversation/naboo_privateer_tier4:s_483",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier4:s_485", "mission4_accept_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission4_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_487",
	animation = "salute1",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_497",
	leftDialog = "@conversation/naboo_privateer_tier4:s_497",
	animation = "shiver",
	options = {
		{"@conversation/naboo_privateer_tier4:s_499", "s_501"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_501",
	leftDialog = "@conversation/naboo_privateer_tier4:s_501",
	animation = "point_to_self",
	options = {
		{"@conversation/naboo_privateer_tier4:s_503", "s_505"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_505",
	leftDialog = "@conversation/naboo_privateer_tier4:s_505",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_507", "s_509"},
		{"@conversation/naboo_privateer_tier4:s_515", "s_517"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_509",
	leftDialog = "@conversation/naboo_privateer_tier4:s_509",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_511", "mission3_accept_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_517",
	leftDialog = "@conversation/naboo_privateer_tier4:s_517",
	options = {
		{"@conversation/naboo_privateer_tier4:s_519", "s_521"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_513",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_521",
	leftDialog = "@conversation/naboo_privateer_tier4:s_521",
	options = {
		{"@conversation/naboo_privateer_tier4:s_523", "s_525"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_525",
	leftDialog = "@conversation/naboo_privateer_tier4:s_525",
	options = {
		{"@conversation/naboo_privateer_tier4:s_527", "s_529"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_529",
	leftDialog = "@conversation/naboo_privateer_tier4:s_529",
	animation = "dismiss",
	options = {
		{"@conversation/naboo_privateer_tier4:s_531", "s_533"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_533",
	leftDialog = "@conversation/naboo_privateer_tier4:s_533",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_535", "mission3_accept_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_537",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_545",
	leftDialog = "@conversation/naboo_privateer_tier4:s_545",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier4:s_547", "s_549"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_549",
	leftDialog = "@conversation/naboo_privateer_tier4:s_549",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_551", "s_553"},
		{"@conversation/naboo_privateer_tier4:s_563", "s_565"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_553",
	leftDialog = "@conversation/naboo_privateer_tier4:s_553",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_555", "s_557"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_565",
	leftDialog = "@conversation/naboo_privateer_tier4:s_565",
	options = {
		{"@conversation/naboo_privateer_tier4:s_567", "s_569"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_557",
	leftDialog = "@conversation/naboo_privateer_tier4:s_557",
	animation = "snap_finger1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_559", "mission3_accept_c"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_561",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_569",
	leftDialog = "@conversation/naboo_privateer_tier4:s_569",
	options = {
		{"@conversation/naboo_privateer_tier4:s_571", "s_573"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_573",
	leftDialog = "@conversation/naboo_privateer_tier4:s_573",
	options = {
		{"@conversation/naboo_privateer_tier4:s_575", "s_577"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_577",
	leftDialog = "@conversation/naboo_privateer_tier4:s_577",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/naboo_privateer_tier4:s_579", "s_581"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_581",
	leftDialog = "@conversation/naboo_privateer_tier4:s_581",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_583", "mission3_accept_d"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_d",
	leftDialog = "@conversation/naboo_privateer_tier4:s_585",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_593",
	leftDialog = "@conversation/naboo_privateer_tier4:s_593",
	animation = "pose_proudly",
	options = {
		{"@conversation/naboo_privateer_tier4:s_595", "s_597"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_597",
	leftDialog = "@conversation/naboo_privateer_tier4:s_597",
	options = {
		{"@conversation/naboo_privateer_tier4:s_599", "s_601"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_601",
	leftDialog = "@conversation/naboo_privateer_tier4:s_601",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier4:s_603", "s_605"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_605",
	leftDialog = "@conversation/naboo_privateer_tier4:s_605",
	options = {
		{"@conversation/naboo_privateer_tier4:s_607", "s_609"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_609",
	leftDialog = "@conversation/naboo_privateer_tier4:s_609",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_611", "s_613"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_613",
	leftDialog = "@conversation/naboo_privateer_tier4:s_613",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_615", "s_617"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_617",
	leftDialog = "@conversation/naboo_privateer_tier4:s_617",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier4:s_619", "mission3_accept_e"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission3_accept_e",
	leftDialog = "@conversation/naboo_privateer_tier4:s_621",
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_631",
	leftDialog = "@conversation/naboo_privateer_tier4:s_631",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_633", "s_635"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_667",
	leftDialog = "@conversation/naboo_privateer_tier4:s_667",
	animation = "smack_self",
	options = {
		{"@conversation/naboo_privateer_tier4:s_669", "s_671"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_635",
	leftDialog = "@conversation/naboo_privateer_tier4:s_635",
	animation = "sigh_deeply",
	options = {
		{"@conversation/naboo_privateer_tier4:s_637", "s_639"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_639",
	leftDialog = "@conversation/naboo_privateer_tier4:s_639",
	options = {
		{"@conversation/naboo_privateer_tier4:s_641", "s_643"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_643",
	leftDialog = "@conversation/naboo_privateer_tier4:s_643",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier4:s_645", "s_647"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_647",
	leftDialog = "@conversation/naboo_privateer_tier4:s_647",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier4:s_649", "s_651"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_651",
	leftDialog = "@conversation/naboo_privateer_tier4:s_651",
	animation = "shrug_hands",
	options = {
		{"@conversation/naboo_privateer_tier4:s_653", "s_655"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_655",
	leftDialog = "@conversation/naboo_privateer_tier4:s_655",
	animation = "whisper",
	options = {
		{"@conversation/naboo_privateer_tier4:s_657", "s_659"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_659",
	leftDialog = "@conversation/naboo_privateer_tier4:s_659",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_661", "mission2_accept_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_663",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_671",
	leftDialog = "@conversation/naboo_privateer_tier4:s_671",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/naboo_privateer_tier4:s_673", "s_675"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_675",
	leftDialog = "@conversation/naboo_privateer_tier4:s_675",
	animation = "snap_finger1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_677", "s_679"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_679",
	leftDialog = "@conversation/naboo_privateer_tier4:s_679",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_681", "s_683"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_683",
	leftDialog = "@conversation/naboo_privateer_tier4:s_683",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier4:s_685", "s_687"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_687",
	leftDialog = "@conversation/naboo_privateer_tier4:s_687",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_689", "s_691"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_691",
	leftDialog = "@conversation/naboo_privateer_tier4:s_691",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_693", "s_695"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_695",
	leftDialog = "@conversation/naboo_privateer_tier4:s_695",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/naboo_privateer_tier4:s_697", "s_699"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_699",
	leftDialog = "@conversation/naboo_privateer_tier4:s_699",
	animation = "whisper",
	options = {
		{"@conversation/naboo_privateer_tier4:s_701", "s_703"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_703",
	leftDialog = "@conversation/naboo_privateer_tier4:s_703",
	animation = "embarrassed",
	options = {
		{"@conversation/naboo_privateer_tier4:s_705", "mission2_accept_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_707",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_715",
	leftDialog = "@conversation/naboo_privateer_tier4:s_715",
	options = {
		{"@conversation/naboo_privateer_tier4:s_717", "s_719"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_719",
	leftDialog = "@conversation/naboo_privateer_tier4:s_719",
	options = {
		{"@conversation/naboo_privateer_tier4:s_721", "s_723"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_723",
	leftDialog = "@conversation/naboo_privateer_tier4:s_723",
	options = {
		{"@conversation/naboo_privateer_tier4:s_725", "s_727"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_727",
	leftDialog = "@conversation/naboo_privateer_tier4:s_727",
	options = {
		{"@conversation/naboo_privateer_tier4:s_729", "s_731"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_731",
	leftDialog = "@conversation/naboo_privateer_tier4:s_731",
	options = {
		{"@conversation/naboo_privateer_tier4:s_733", "mission2_accept_c"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission2_accept_c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_735",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_745",
	leftDialog = "@conversation/naboo_privateer_tier4:s_745",
	options = {
		{"@conversation/naboo_privateer_tier4:s_747", "s_749"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_785",
	leftDialog = "@conversation/naboo_privateer_tier4:s_785",
	animation = "laugh",
	options = {
		{"@conversation/naboo_privateer_tier4:s_787", "s_789"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_749",
	leftDialog = "@conversation/naboo_privateer_tier4:s_749",
	animation = "slit_throat",
	options = {
		{"@conversation/naboo_privateer_tier4:s_751", "s_753"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_753",
	leftDialog = "@conversation/naboo_privateer_tier4:s_753",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/naboo_privateer_tier4:s_755", "s_757"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_757",
	leftDialog = "@conversation/naboo_privateer_tier4:s_757",
	options = {
		{"@conversation/naboo_privateer_tier4:s_759", "s_761"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_761",
	leftDialog = "@conversation/naboo_privateer_tier4:s_761",
	options = {
		{"@conversation/naboo_privateer_tier4:s_763", "s_765"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_765",
	leftDialog = "@conversation/naboo_privateer_tier4:s_765",
	options = {
		{"@conversation/naboo_privateer_tier4:s_767", "s_769"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_769",
	leftDialog = "@conversation/naboo_privateer_tier4:s_769",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_771", "s_773"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_773",
	leftDialog = "@conversation/naboo_privateer_tier4:s_773",
	options = {
		{"@conversation/naboo_privateer_tier4:s_775", "s_777"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_777",
	leftDialog = "@conversation/naboo_privateer_tier4:s_777",
	options = {
		{"@conversation/naboo_privateer_tier4:s_779", "mission1_accept_a"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_accept_a",
	leftDialog = "@conversation/naboo_privateer_tier4:s_781",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_789",
	leftDialog = "@conversation/naboo_privateer_tier4:s_789",
	animation = "snap_finger1",
	options = {
		{"@conversation/naboo_privateer_tier4:s_791", "s_793"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_793",
	leftDialog = "@conversation/naboo_privateer_tier4:s_793",
	options = {
		{"@conversation/naboo_privateer_tier4:s_795", "s_797"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_797",
	leftDialog = "@conversation/naboo_privateer_tier4:s_797",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier4:s_799", "s_801"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_801",
	leftDialog = "@conversation/naboo_privateer_tier4:s_801",
	options = {
		{"@conversation/naboo_privateer_tier4:s_803", "s_805"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_805",
	leftDialog = "@conversation/naboo_privateer_tier4:s_805",
	animation = "tap_head",
	options = {
		{"@conversation/naboo_privateer_tier4:s_807", "s_809"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_809",
	leftDialog = "@conversation/naboo_privateer_tier4:s_809",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_811", "s_813"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_813",
	leftDialog = "@conversation/naboo_privateer_tier4:s_813",
	animation = "shake_head_no",
	options = {
		{"@conversation/naboo_privateer_tier4:s_815", "mission1_accept_b"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_accept_b",
	leftDialog = "@conversation/naboo_privateer_tier4:s_817",
	animation = "dismiss",
	stopConversation = "true",
	options = {}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_825",
	leftDialog = "@conversation/naboo_privateer_tier4:s_825",
	animation = "hair_flip",
	options = {
		{"@conversation/naboo_privateer_tier4:s_827", "s_829"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_829",
	leftDialog = "@conversation/naboo_privateer_tier4:s_829",
	animation = "yawn",
	options = {
		{"@conversation/naboo_privateer_tier4:s_831", "s_833"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_833",
	leftDialog = "@conversation/naboo_privateer_tier4:s_833",
	animation = "nod_head_once",
	options = {
		{"@conversation/naboo_privateer_tier4:s_835", "s_837"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_837",
	leftDialog = "@conversation/naboo_privateer_tier4:s_837",
	options = {
		{"@conversation/naboo_privateer_tier4:s_839", "s_841"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_841",
	leftDialog = "@conversation/naboo_privateer_tier4:s_841",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_843", "s_845"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "s_845",
	leftDialog = "@conversation/naboo_privateer_tier4:s_845",
	animation = "explain",
	options = {
		{"@conversation/naboo_privateer_tier4:s_847", "mission1_accept_c"},
	}
})
imler_convo_template:addScreen(ConvoScreen:new {
	id = "mission1_accept_c",
	leftDialog = "@conversation/naboo_privateer_tier4:s_849",
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
	leftDialog = "@conversation/naboo_privateer_tier4:s_4",
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
	options = {
		{"@conversation/naboo_privateer_tier4:s_438", "train_droid"},
	}
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
