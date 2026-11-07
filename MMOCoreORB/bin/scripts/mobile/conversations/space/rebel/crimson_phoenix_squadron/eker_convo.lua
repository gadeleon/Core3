-- Major Eker (Crimson Phoenix Squadron tier 2, Yavin 4 labor outpost) conversation; ported from SWG-Source yavin_rebel_trainer_2.java with the pre-NGE client lines (feature crimson-phoenix-tier2-eker-convo). Handler: ekerConvoHandler.
eker_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "ekerConvoHandler",
	screens = {}
}

eker_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e18f6059", -- I can't think of one good reason for you to be talking to me, can you? On your way, then.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_not_pilot)

eker_convo_tier3_handoff = ConvoScreen:new {
	id = "tier3_handoff",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_71f6ca11", -- Good to see you %TU! I'm afraid that our time of service together has come to an end. The Navy has requested your presence at a different location. I just wanted to let you know that even though I've been hard on you now and then, you've been one of my best pilots ever %NU.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_3938bdfc", "tier3_teaching"},
		{"@conversation/yavin_rebel_trainer_2:s_214de988", "tier3_honor"}
	}
}
eker_convo_template:addScreen(eker_convo_tier3_handoff)

eker_convo_tier3_teaching = ConvoScreen:new {
	id = "tier3_teaching",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6a18240d", -- It's just my way of teaching. Anyway, you are to report to a Bothan named Arnecio Ulvaw'op in a science outpost on the planet of Dathomir. Remember what you've learned during your time here and be careful %TU!
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_tier3_teaching)

eker_convo_tier3_honor = ConvoScreen:new {
	id = "tier3_honor",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_308630ef", -- You will do well in the Rebel Navy pilot. Now you are to report to a Bothan named Arnecio Ulvaw'op in a science outpost on the planet of Dathomir. Be careful there %TU, that's a dangerous place. Now get out of here and remember everything you've learned!
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_tier3_honor)

eker_convo_imperial = ConvoScreen:new {
	id = "imperial",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9c34f0ad", -- I know you. You better get out of here if you know what's good for you.
	stopConversation = "true",
	animation = "whisper",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_imperial)

eker_convo_neutral_pilot = ConvoScreen:new {
	id = "neutral_pilot",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1a1b1cf0", -- Move along.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ca776e30", "neutral_nightmare"},
		{"@conversation/yavin_rebel_trainer_2:s_e93cc431", "neutral_custody"}
	}
}
eker_convo_template:addScreen(eker_convo_neutral_pilot)

eker_convo_neutral_nightmare = ConvoScreen:new {
	id = "neutral_nightmare",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a35edd6c", -- I'm going to be your worst nightmare, if you keep talking to me. Now get out of here.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_neutral_nightmare)

eker_convo_neutral_custody = ConvoScreen:new {
	id = "neutral_custody",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_b030df0f", -- Looking for people who are aligned with the Empire. Should I send someone over here to take you into custody?
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_neutral_custody)

eker_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_418a4a24", -- Sorry, %TU.  You're on report.  That means no more missions for you.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_7f9b8387", "grounded_why"}
	}
}
eker_convo_template:addScreen(eker_convo_grounded)

eker_convo_grounded_why = ConvoScreen:new {
	id = "grounded_why",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_4cc5f79c", -- No one ever tells me anything.  Maybe Alliance Intelligence found out something about you they didn't like.  You haven't been doing anything they might take the wrong way, have you?
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_f5427310", "grounded_standing"}
	}
}
eker_convo_template:addScreen(eker_convo_grounded_why)

eker_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_44d689b7", -- Well, sorry.  Nothing I can do about it.  If you want to get your wings back you'll have to do SOMETHING to improve your standing in the eyes of the Alliance.  'Show 'em you're still on OUR team.
	stopConversation = "true",
	animation = "sigh_deeply",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_grounded_standing)

eker_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_56b0632", -- A Rebel pilot, eh? But you don't fly with the Phoenix? What are you doing here, soldier?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_1583743c", "off_track_no_missions"}
	}
}
eker_convo_template:addScreen(eker_convo_off_track)

eker_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_cc00d56b", -- I don't have any missions, but I do have several elective duty tasks if you'd like to take one of those?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ca47d528", "duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_7115a155", "off_track_goodbye"}
	}
}
eker_convo_template:addScreen(eker_convo_off_track_duties)

eker_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e641a3d8", -- I have a few different duty missions available. Help steal Imperial ships, destroy pirate patrols or help escort Alliance smugglers. Take your pick pilot. I want you to assist with these duties until you feel you have enough experience to proceed with training. They are voluntarily missions and can be aborted at any time.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_73c783f8", "duty_recovery"},
		{"@conversation/yavin_rebel_trainer_2:s_80e4843e", "duty_escort"},
		{"@conversation/yavin_rebel_trainer_2:s_46fb1c35", "duty_destroy"},
		{"@conversation/yavin_rebel_trainer_2:s_6deac9a2", "duty_menu_later"}
	}
}
eker_convo_template:addScreen(eker_convo_duty_menu)

eker_convo_handin_duty_menu = ConvoScreen:new {
	id = "handin_duty_menu",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e641a3d8", -- I have a few different duty missions available. Help steal Imperial ships, destroy pirate patrols or help escort Alliance smugglers. Take your pick pilot. I want you to assist with these duties until you feel you have enough experience to proceed with training. They are voluntarily missions and can be aborted at any time.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_73c783f8", "duty_recovery"},
		{"@conversation/yavin_rebel_trainer_2:s_80e4843e", "duty_escort"},
		{"@conversation/yavin_rebel_trainer_2:s_46fb1c35", "duty_destroy"},
		{"@conversation/yavin_rebel_trainer_2:s_6deac9a2", "duty_menu_later"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_duty_menu)

eker_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d6f036fd", -- That's what I thought you'd say. Get moving, we'll update you once you're airborne.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_duty_recovery)

eker_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_908b2b2c", -- Watch your six. There are plenty of experienced TIE fighters up there.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_duty_escort)

eker_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d6896b", -- You'll get your chance, soldier - unless they hit you first. Move into position, and we'll tell you more over your comlink.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_duty_destroy)

eker_convo_duty_menu_later = ConvoScreen:new {
	id = "duty_menu_later",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1bab5480", -- Sorry to hear that I'm not your top priority, soldier! I'll remember this.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_duty_menu_later)

eker_convo_off_track_goodbye = ConvoScreen:new {
	id = "off_track_goodbye",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_36b1d069", -- Be on your way then.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_off_track_goodbye)

eker_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_5242f9d0", -- Since you're not a member of my unit, I can't assign you missions. Why don't you scuttle back to your own commanding officer?
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_off_track_no_missions)

eker_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_30e8e9e0", -- Unless you're here to request a transfer, I'd suggest you get back to your unit.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_non_member)

eker_convo_tier3_veteran = ConvoScreen:new {
	id = "tier3_veteran",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9ec42807", -- Nice to see you again, %TU. They tell me you've been a great help to the Alliance since you I last saw you. Looks like you turned out alright.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_tier3_veteran)

eker_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_94dbed1a", -- I'm still waiting on your mission report, soldier.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_on_mission)

eker_convo_other_mission = ConvoScreen:new {
	id = "other_mission",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f7f3ab80", -- Duty reports show you've already got an assignment. Finish what you've started, then we'll talk.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_other_mission)

eker_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3c9ecbe9", -- I didn't expect those Imperial rescue squads to respond so quickly.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_591601b8", "m2_failed_maneuvers"},
		{"@conversation/yavin_rebel_trainer_2:s_d8db54f6", "m2_retry"},
		{"@conversation/yavin_rebel_trainer_2:s_b130ff0a", "m2_failed_repairs"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_failed)

eker_convo_m2_failed_maneuvers = ConvoScreen:new {
	id = "m2_failed_maneuvers",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8bea99a9", -- Watch their maneuvers. Imperial forces are predictable.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_4ca03ddb", "m2_retry_rules"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_failed_maneuvers)

eker_convo_m2_retry_rules = ConvoScreen:new {
	id = "m2_retry_rules",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_cd41219", -- They're all trained the same way. Once you've learned their rules, you can break them. Good luck.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_retry_rules)

eker_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_393047f3", -- Get going.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_retry)

eker_convo_m2_failed_repairs = ConvoScreen:new {
	id = "m2_failed_repairs",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_7b2f5e99", -- Make it quick.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_failed_repairs)

eker_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9777c464", -- Good work, soldier. With this information, we'll be able to run rings around those Imperial patrols.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_c48841", "m2_pay_good_work"},
		{"@conversation/yavin_rebel_trainer_2:s_8d66b6a5", "m2_pay_come_again"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_won)

eker_convo_m2_pay_good_work = ConvoScreen:new {
	id = "m2_pay_good_work",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c9846d38", -- That won't happen - not for a while. The Empire doesn't exactly  turn on a dime. Good work, soldier.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_pay_good_work)

eker_convo_m2_pay_come_again = ConvoScreen:new {
	id = "m2_pay_come_again",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_61b35d7b", -- Come again? I'd think very carefully about what comes out of your mouth next, soldier.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_bb847e4c", "m2_uniform"},
		{"@conversation/yavin_rebel_trainer_2:s_287ec62a", "m2_yeah_right"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_pay_come_again)

eker_convo_m2_uniform = ConvoScreen:new {
	id = "m2_uniform",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8f0eb0e", -- This uniform comes off, you know.
	stopConversation = "false",
	animation = "threaten",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_287ec62a", "m2_get_out"},
		{"@conversation/yavin_rebel_trainer_2:s_d757b665", "m2_dismissed"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_uniform)

eker_convo_m2_get_out = ConvoScreen:new {
	id = "m2_get_out",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6fe71f0c", -- Get out of here.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_get_out)

eker_convo_m2_dismissed = ConvoScreen:new {
	id = "m2_dismissed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d3b6ccb7", -- You can count on it. Dismissed.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_dismissed)

eker_convo_m2_yeah_right = ConvoScreen:new {
	id = "m2_yeah_right",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_4c6d0461", -- Yeah right. Get out of here.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_yeah_right)

eker_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_27ad3073", -- %NU! Get over here. I've got a job for you.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_b1df084d", "m2_spy_shuttle"},
		{"@conversation/yavin_rebel_trainer_2:s_12a5eddf", "m2_beauty_sleep"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_offer)

eker_convo_m2_spy_shuttle = ConvoScreen:new {
	id = "m2_spy_shuttle",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a760a737", -- An Imperial Spy shuttle has malfunctioned in our area. We think it's carrying data on the Imperial Navy's patrol routes.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_d5609495", "m2_spy_droid"},
		{"@conversation/yavin_rebel_trainer_2:s_564211e6", "m2_joke"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_spy_shuttle)

eker_convo_m2_spy_droid = ConvoScreen:new {
	id = "m2_spy_droid",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_cec991df", -- If we can get that information, we can protect our ships. I need you get out there and shoot a spy droid into the shuttle's hull, so that we can extract the information.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_8bdbd90b", "m2_accept_closing"},
		{"@conversation/yavin_rebel_trainer_2:s_62b1a1d0", "m2_accept_droid"}
	}
}
eker_convo_template:addScreen(eker_convo_m2_spy_droid)

eker_convo_m2_accept_closing = ConvoScreen:new {
	id = "m2_accept_closing",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f9855bf1", -- Closing in. An Imperial rescue squad is en route. Suit up and get out there ASAP.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_accept_closing)

eker_convo_m2_accept_droid = ConvoScreen:new {
	id = "m2_accept_droid",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c56973bf", -- Done. The coordinates are already in your nav system.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_accept_droid)

eker_convo_m2_joke = ConvoScreen:new {
	id = "m2_joke",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3d2dd8e2", -- Is this a joke? When are they going to start sending me some REAL pilots?...Dismissed.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_joke)

eker_convo_m2_beauty_sleep = ConvoScreen:new {
	id = "m2_beauty_sleep",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_15192b9e", -- Aw. Sorry it's been so rough on you. Come back once you've caught up on your damn beauty sleep.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m2_beauty_sleep)

eker_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_7b57442", -- You've got to find those pirates. They know where that Imperial freighter is. We HAVE to find it.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_e0651b79", "m3_retry"},
		{"@conversation/yavin_rebel_trainer_2:s_b130ff0a", "m3_failed_worry"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_failed)

eker_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_2eef8e0e", -- I'm counting on you.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_retry)

eker_convo_m3_failed_worry = ConvoScreen:new {
	id = "m3_failed_worry",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_dd3bf8f6", -- You're going to have a lot more than your ship to worry about if we don't get that database!
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_failed_worry)

eker_convo_m3_won = ConvoScreen:new {
	id = "m3_won",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_cdb6a148", -- You look like your dog just died.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_faf96c0a", "m3_pay_another_post"},
		{"@conversation/yavin_rebel_trainer_2:s_4471d2b", "m3_pay_war_not_over"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_won)

eker_convo_m3_pay_another_post = ConvoScreen:new {
	id = "m3_pay_another_post",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1a163be3", -- Maybe you'll have better luck at another post.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_pay_another_post)

eker_convo_m3_pay_war_not_over = ConvoScreen:new {
	id = "m3_pay_war_not_over",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_450abd55", -- You lost the battle - but the war's not over. The Alliance still needs you.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_affe46cc", "duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_166e7e70", "m3_take_a_walk"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_pay_war_not_over)

eker_convo_m3_take_a_walk = ConvoScreen:new {
	id = "m3_take_a_walk",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_354d9179", -- Take a walk. Clear your head. I'll be here when you're ready.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_take_a_walk)

eker_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_fddb83ca", -- I've got news, %NU.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ae785ffa", "m3_why_yavin"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_offer)

eker_convo_m3_why_yavin = ConvoScreen:new {
	id = "m3_why_yavin",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_154b642e", -- We know now why the Empire is so interested in Yavin.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_841d27db", "m3_station_sections"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_why_yavin)

eker_convo_m3_station_sections = ConvoScreen:new {
	id = "m3_station_sections",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_918115be", -- Apparently there's sections of the space station there that are still intact... And have important information.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_3de0965c", "m3_database"},
		{"@conversation/yavin_rebel_trainer_2:s_a0412756", "m3_tracks"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_station_sections)

eker_convo_m3_database = ConvoScreen:new {
	id = "m3_database",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_44584a57", -- Our spy droids have located a database within the Death Star debris listing many of the Imperial spies operating within the Alliance.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_71bb443b", "m3_no_arrests"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_database)

eker_convo_m3_no_arrests = ConvoScreen:new {
	id = "m3_no_arrests",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_329b2195", -- We haven't made any arrests, because we don't have any details  - yet.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6aacd1f1", "m3_recovery_team"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_no_arrests)

eker_convo_m3_recovery_team = ConvoScreen:new {
	id = "m3_recovery_team",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c928423d", -- The Imperial Recovery team seized the Death Star section before we could get the data. It's en route to Naboo as we speak.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_38f14bb8", "m3_travel_lok"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_recovery_team)

eker_convo_m3_travel_lok = ConvoScreen:new {
	id = "m3_travel_lok",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a1f998fd", -- Correct. We need you to travel to Lok and steal that data before the shuttle reaches a safe location.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ee790f5c", "m3_arrest"},
		{"@conversation/yavin_rebel_trainer_2:s_2588496a", "m3_through_lok"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_travel_lok)

eker_convo_m3_arrest = ConvoScreen:new {
	id = "m3_arrest",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c909e899", -- What do you think this is %TU?! You will do as you're told or you will be put under arrest!
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_arrest)

eker_convo_m3_through_lok = ConvoScreen:new {
	id = "m3_through_lok",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_b0753766", -- It is. But first it has to pass through Lok. Nym and his men know everything about that system and have provided us with coordinates that it will pass through. You can't cut a fart in Lok without Nym hearing about it.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_a99ad4e8", "m3_accept"},
		{"@conversation/yavin_rebel_trainer_2:s_d583db1d", "m3_cowboy"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_through_lok)

eker_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a7558b8", -- Proceed to the Lok system and we will supply you with the coordinates we got from Nym. Search the nearby area there, if the freighter is not in sight, wait near the point to ambush him when he arrives.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_accept)

eker_convo_m3_cowboy = ConvoScreen:new {
	id = "m3_cowboy",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a57083c1", -- Are you kidding me? Just what the galaxy needs, another cowboy. Get out of here!
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_cowboy)

eker_convo_m3_tracks = ConvoScreen:new {
	id = "m3_tracks",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_5018d177", -- The Empire's done a good job covering their tracks. However, our spy droids have located a database within the Death Star debris listing many of the Imperial spies operating within the Alliance.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_7b4382cf", "m3_carrying_info"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_tracks)

eker_convo_m3_carrying_info = ConvoScreen:new {
	id = "m3_carrying_info",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e015a069", -- No. It's carrying information on Imperial spies. We need that data.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_cd0a60d4", "m3_not_easy"},
		{"@conversation/yavin_rebel_trainer_2:s_31f57362", "m3_easy_jobs"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_carrying_info)

eker_convo_m3_not_easy = ConvoScreen:new {
	id = "m3_not_easy",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_5c4ab8c9", -- It won't be easy. An Imperial Recovery team is transporting the database section to Naboo right now.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_47003e68", "m3_passing_lok"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_not_easy)

eker_convo_m3_passing_lok = ConvoScreen:new {
	id = "m3_passing_lok",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_32a7abcd", -- They're passing through Lok. Nym and his space pirates run that system with an iron fist. In exchange for some services they have provided us with some coordinates that the freighter will pass through.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_851cc47", "m3_nym_hears"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_passing_lok)

eker_convo_m3_nym_hears = ConvoScreen:new {
	id = "m3_nym_hears",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9525ae41", -- It is. But first it has to pass through Lok. And Nym and his men know everything about that system. You can't cut a fart in Lok without Nym hearing about it. He's SURE to know the location of the Imperial freighter.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_a99ad4e8", "m3_accept"},
		{"@conversation/yavin_rebel_trainer_2:s_b9adf734", "m3_cowboy"}
	}
}
eker_convo_template:addScreen(eker_convo_m3_nym_hears)

eker_convo_m3_easy_jobs = ConvoScreen:new {
	id = "m3_easy_jobs",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_38bfb556", -- Hm. Good point. I'll just use you for the easy jobs.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m3_easy_jobs)

eker_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_fcfc8bbb", -- What are you doing here?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_78bae101", "m4_failed_dismissed"},
		{"@conversation/yavin_rebel_trainer_2:s_80d8485c", "m4_retry"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_failed)

eker_convo_m4_failed_dismissed = ConvoScreen:new {
	id = "m4_failed_dismissed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d5c526b8", -- Dismissed, soldier. As of NOW.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_failed_dismissed)

eker_convo_m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_ec739555", -- Move it!
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_retry)

eker_convo_m4_won = ConvoScreen:new {
	id = "m4_won",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_865fdc7d", -- Alliance forces are rounding up the Imperial spies as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ef170270", "m4_pay_right_about_you"},
		{"@conversation/yavin_rebel_trainer_2:s_21bdbf0f", "m4_pay_war_not_over"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_won)

eker_convo_m4_pay_right_about_you = ConvoScreen:new {
	id = "m4_pay_right_about_you",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a86a8807", -- Looks like I was right about you after all.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_c551ea96", "m4_see_you"},
		{"@conversation/yavin_rebel_trainer_2:s_813ee7df", "m4_good_soldier"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_pay_right_about_you)

eker_convo_m4_see_you = ConvoScreen:new {
	id = "m4_see_you",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_2e8799ad", -- See you around, soldier.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_see_you)

eker_convo_m4_good_soldier = ConvoScreen:new {
	id = "m4_good_soldier",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_877ef2c8", -- I know a good soldier when I see one.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_good_soldier)

eker_convo_m4_pay_war_not_over = ConvoScreen:new {
	id = "m4_pay_war_not_over",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_a10e0cd4", -- The war's not over yet. The Empire's going to respond with force.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6d00e51e", "m4_congratulations"},
		{"@conversation/yavin_rebel_trainer_2:s_4e2c42f1", "m4_so_long"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_pay_war_not_over)

eker_convo_m4_congratulations = ConvoScreen:new {
	id = "m4_congratulations",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_b685e199", -- Congratulations, soldier. You did good today.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_congratulations)

eker_convo_m4_so_long = ConvoScreen:new {
	id = "m4_so_long",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e6f59343", -- So will we. So long, %NU.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_so_long)

eker_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_643292f4", -- %TU! Just the person I wanted to see.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6673b556", "m4_nym_has_it"},
		{"@conversation/yavin_rebel_trainer_2:s_47a389f6", "m4_double_time"},
		{"@conversation/yavin_rebel_trainer_2:s_4431cbae", "m4_never_better"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_offer)

eker_convo_m4_nym_has_it = ConvoScreen:new {
	id = "m4_nym_has_it",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_18ac5f05", -- Turns out the Death Star section didn't burn up in the freighter explosion. It fell to Lok - and Nym's got it.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_14bcd839", "m4_suit_up"},
		{"@conversation/yavin_rebel_trainer_2:s_3d419bc4", "m4_two_reasons"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_nym_has_it)

eker_convo_m4_suit_up = ConvoScreen:new {
	id = "m4_suit_up",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1c128099", -- That's right. Suit up. You're heading back to Lok. Get the Death Star section from Nym. He's charging a fee. Don't worry about it; the Alliance will pay.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_32146025", "m4_station"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_suit_up)

eker_convo_m4_station = ConvoScreen:new {
	id = "m4_station",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d76c93fd", -- Take it to the Rebel space station in Lok. And keep it out of sight of those Imperial patrols.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_d24a2285", "m4_trust"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_station)

eker_convo_m4_trust = ConvoScreen:new {
	id = "m4_trust",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_df72e251", -- They didn't want me to give you this mission, you know. Said I couldn't trust you.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_c3c8f385", "m4_accept_trust"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_trust)

eker_convo_m4_accept_trust = ConvoScreen:new {
	id = "m4_accept_trust",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_76473360", -- They used to say that about me too. Don't let me down.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_accept_trust)

eker_convo_m4_two_reasons = ConvoScreen:new {
	id = "m4_two_reasons",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_b6cf63f0", -- Two reasons. One, he doesn't want Imperial patrols to spot him. Two, he wants us to pay his fee.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_b2e9d505", "m4_pirate_guild"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_two_reasons)

eker_convo_m4_pirate_guild = ConvoScreen:new {
	id = "m4_pirate_guild",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_2857391a", -- He has to charge us, or they'll kick him out of the pirate guild.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_bb25f9e7", "m4_accept_go_back"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_pirate_guild)

eker_convo_m4_accept_go_back = ConvoScreen:new {
	id = "m4_accept_go_back",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6c872984", -- Go back to Lok, get the Death Star section from Nym, and bring it to the Rebel space station in the Lok system. And the sooner you leave, the better.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_accept_go_back)

eker_convo_m4_double_time = ConvoScreen:new {
	id = "m4_double_time",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_5ab73a77", -- Double-time, soldier! I've got a job for you.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_double_time)

eker_convo_m4_never_better = ConvoScreen:new {
	id = "m4_never_better",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d931ff32", -- Never better! Good news, soldier. The Death Star section didn't burn up in the explosion.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_f930a587", "m4_price"},
		{"@conversation/yavin_rebel_trainer_2:s_62f0f943", "m4_see_you_around"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_never_better)

eker_convo_m4_price = ConvoScreen:new {
	id = "m4_price",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3e7eb818", -- It's on Lok. Nym's got it. And he's ready to hand it over - if the price is right.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_39acc227", "m4_buy_it"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_price)

eker_convo_m4_buy_it = ConvoScreen:new {
	id = "m4_buy_it",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_81fb32f3", -- At this point, we can't afford NOT to buy it. Go back to Lok. Pay Nym his fee. And bring back that Death Star!
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6c251948", "m4_accept_smuggle"}
	}
}
eker_convo_template:addScreen(eker_convo_m4_buy_it)

eker_convo_m4_accept_smuggle = ConvoScreen:new {
	id = "m4_accept_smuggle",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8efa75c2", -- It won't be easy; you'll have to smuggle it past Imperial patrols. Keep your eyes peeled. Dismissed.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_accept_smuggle)

eker_convo_m4_see_you_around = ConvoScreen:new {
	id = "m4_see_you_around",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_dee42d5e", -- If that's the way you feel. See you around, %NU.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m4_see_you_around)

eker_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_2a29add6", -- Nice job out there. It's not every day I see a pilot outrun a TIE Interceptor.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_837615b6", "m1_refugee"},
		{"@conversation/yavin_rebel_trainer_2:s_c3e68b1f", "m1_cantina"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_won)

eker_convo_m1_refugee = ConvoScreen:new {
	id = "m1_refugee",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_35783339", -- She's not just any refugee, and the Empire knows it.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_e39ec30", "m1_duties"},
		{"@conversation/yavin_rebel_trainer_2:s_7f93598d", "m1_work_to_do"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_refugee)

eker_convo_m1_duties = ConvoScreen:new {
	id = "m1_duties",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d2acb60b", -- Take on some duties.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_b54697f", "duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_1b4c2d5d", "m1_discipline"},
		{"@conversation/yavin_rebel_trainer_2:s_67a197b0", "m1_exercise"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_duties)

eker_convo_m1_discipline = ConvoScreen:new {
	id = "m1_discipline",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_82844140", -- What you need is some discipline. I advise you to take on some duties.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_aaf61b87", "duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_be61c03c", "m1_go_getter"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_discipline)

eker_convo_m1_go_getter = ConvoScreen:new {
	id = "m1_go_getter",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6b8fc506", -- You're a real go-getter, you know that?
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_go_getter)

eker_convo_m1_exercise = ConvoScreen:new {
	id = "m1_exercise",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8786e77c", -- Come back. I expect my soldiers to be in top condition. And you need the exercise.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_exercise)

eker_convo_m1_work_to_do = ConvoScreen:new {
	id = "m1_work_to_do",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_32c8e4da", -- I don't know where you think you're going. There's work to do.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_2f9e3b7b", "m1_other_time"},
		{"@conversation/yavin_rebel_trainer_2:s_53de9d8f", "duty_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_work_to_do)

eker_convo_m1_other_time = ConvoScreen:new {
	id = "m1_other_time",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e8a0555b", -- Some other time, soldier.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_other_time)

eker_convo_m1_cantina = ConvoScreen:new {
	id = "m1_cantina",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_25670467", -- You've earned it. Hit the cantina.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_cantina)

eker_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_14086bc1", -- That woman is vital to Alliance interests. You're going back out there, stat.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_d9c145dd", "m1_retry_now"},
		{"@conversation/yavin_rebel_trainer_2:s_b585598c", "m1_report"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_failed)

eker_convo_m1_retry_now = ConvoScreen:new {
	id = "m1_retry_now",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1f02f56b", -- How about now?
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_retry_now)

eker_convo_m1_report = ConvoScreen:new {
	id = "m1_report",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_bf176a8f", -- I've read your report. I know what kind of pilot you are.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_b601ca9f", "m1_not_beg"},
		{"@conversation/yavin_rebel_trainer_2:s_252b3bf5", "m1_retry_knew"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_report)

eker_convo_m1_not_beg = ConvoScreen:new {
	id = "m1_not_beg",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_ee36cca8", -- I'm not going to beg, soldier. If you can't do it, I'll find someone else. Dismissed.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_not_beg)

eker_convo_m1_retry_knew = ConvoScreen:new {
	id = "m1_retry_knew",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6a1944ad", -- I knew you would.
	stopConversation = "true",
	animation = "nod_head_multiple",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_retry_knew)

eker_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f88289a7", -- There's work to do on Yavin.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_38e4c8a3", "m1_paperwork"},
		{"@conversation/yavin_rebel_trainer_2:s_468ab4d3", "m1_sitrep"},
		{"@conversation/yavin_rebel_trainer_2:s_e58651c5", "m1_holdout"},
		{"@conversation/yavin_rebel_trainer_2:s_7065e138", "m1_action"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_offer)

eker_convo_m1_paperwork = ConvoScreen:new {
	id = "m1_paperwork",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_ff0af3bc", -- What? You're not my pilot? I've had it with this sloppy Rebel paperwork!...Dismissed, soldier.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_paperwork)

eker_convo_m1_sitrep = ConvoScreen:new {
	id = "m1_sitrep",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d8ffe780", -- Sitrep is as follows: we've got a VIP down on the surface. She resisted the first evacuation, but now she's ready for exfil.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_313aff7d", "m1_do_you_copy"},
		{"@conversation/yavin_rebel_trainer_2:s_1591adc2", "m1_massassi"},
		{"@conversation/yavin_rebel_trainer_2:s_2dec7766", "m1_theory"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_sitrep)

eker_convo_m1_do_you_copy = ConvoScreen:new {
	id = "m1_do_you_copy",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_76491b38", -- Unknown. But we don't leave anyone behind. Do you copy, pilot?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_f685a04e", "m1_accept_dismissed"},
		{"@conversation/yavin_rebel_trainer_2:s_2e17432d", "m1_accept_opinion"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_do_you_copy)

eker_convo_m1_accept_dismissed = ConvoScreen:new {
	id = "m1_accept_dismissed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9bcf9c5b", -- You're to take your ship to the Massassi temple, pick her up at the extraction point, and bring her back to base.  Dismissed.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_dismissed)

eker_convo_m1_accept_opinion = ConvoScreen:new {
	id = "m1_accept_opinion",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_22bd4bdf", -- When I want your opinion, soldier, I'll tell you what it is. She's ready to go, and WE'RE ready to help her in any way we can.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_e23e884f", "m1_ready_to_work"},
		{"@conversation/yavin_rebel_trainer_2:s_5494c458", "m1_accept_right"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_opinion)

eker_convo_m1_ready_to_work = ConvoScreen:new {
	id = "m1_ready_to_work",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_998c6a73", -- Well in that case, get out of here, and don't talk to me again until you're ready to work.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_ready_to_work)

eker_convo_m1_accept_right = ConvoScreen:new {
	id = "m1_accept_right",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d80e99ca", -- You're to take your ship to the Massassi temple, pick her up at the extraction point, and bring her back to base.  We're uploading coordinates to your ship now. Get going.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_right)

eker_convo_m1_massassi = ConvoScreen:new {
	id = "m1_massassi",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_5fdfb6c3", -- You're to take your ship to the Massassi temple, pick her up at the extraction point, and bring her back to base.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_8e9d0848", "m1_accept_uploading"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_massassi)

eker_convo_m1_accept_uploading = ConvoScreen:new {
	id = "m1_accept_uploading",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c4480fc5", -- We're uploading coordinates to your navigation system now. You're clear to leave our airspace.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_uploading)

eker_convo_m1_theory = ConvoScreen:new {
	id = "m1_theory",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_67c78480", -- Unknown - although I have a theory. Are you ready to go?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_9b43a7ee", "m1_accept_uploading"},
		{"@conversation/yavin_rebel_trainer_2:s_241bc364", "m1_new_ship"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_theory)

eker_convo_m1_new_ship = ConvoScreen:new {
	id = "m1_new_ship",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_29b7d74a", -- Sounds like you need a new ship.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_new_ship)

eker_convo_m1_holdout = ConvoScreen:new {
	id = "m1_holdout",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_88179ade", -- That's a negative. We've got a holdout down there. A female.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_8e571bd6", "m1_sitrep"},
		{"@conversation/yavin_rebel_trainer_2:s_97f7a201", "m1_her_problem"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_holdout)

eker_convo_m1_her_problem = ConvoScreen:new {
	id = "m1_her_problem",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9ddb6cf8", -- Right now, her problem is that her pilot's got a negative attitude.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_260761cf", "m1_still_standing"},
		{"@conversation/yavin_rebel_trainer_2:s_d945a469", "m1_accept_priority"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_her_problem)

eker_convo_m1_still_standing = ConvoScreen:new {
	id = "m1_still_standing",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8650827b", -- Is that right? Well in that case, why are you still standing here?
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_still_standing)

eker_convo_m1_accept_priority = ConvoScreen:new {
	id = "m1_accept_priority",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6dccb496", -- That's nice to hear. Her safe arrival is now your top priority. You're to take your ship to the Massassi temple, pick her up at the extraction point, and bring her back to base.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_priority)

eker_convo_m1_action = ConvoScreen:new {
	id = "m1_action",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_ceb818e1", -- You can count on it. Imperial TIE fighters are patrolling the area. The Empire's taken a serious interest in this system.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_7b3f9583", "m1_sitrep"},
		{"@conversation/yavin_rebel_trainer_2:s_5e7c5f7b", "m1_old_friends"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_action)

eker_convo_m1_old_friends = ConvoScreen:new {
	id = "m1_old_friends",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d5b4ea09", -- Because I told them to come here. They're my old friends after all. That's your point, isn't it?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_ca4d37ba", "m1_accept_immediately"},
		{"@conversation/yavin_rebel_trainer_2:s_af144418", "m1_another_pilot"}
	}
}
eker_convo_template:addScreen(eker_convo_m1_old_friends)

eker_convo_m1_accept_immediately = ConvoScreen:new {
	id = "m1_accept_immediately",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_c4f8041b", -- Immediately. Coordinates are already in your ship database. You're to take your ship to the Massassi temple, pick her up at the extraction point, and bring her back to base.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_accept_immediately)

eker_convo_m1_another_pilot = ConvoScreen:new {
	id = "m1_another_pilot",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_98361f2c", -- You're not the first person to say that to me. It's all right. I'll find another pilot. Dismissed.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_m1_another_pilot)

eker_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_434cf40e", -- Good news, soldier. One of my best pilots has volunteered to train new recruits - and that includes you.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_dd2fd70", "training_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_2f0a6ba8", "training_find_out"},
		{"@conversation/yavin_rebel_trainer_2:s_dede1eae", "training_free"},
		{"@conversation/yavin_rebel_trainer_2:s_fd447981", "training_pass"}
	}
}
eker_convo_template:addScreen(eker_convo_training_offer)

eker_convo_training_find_out = ConvoScreen:new {
	id = "training_find_out",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8d0a5ef4", -- I don't know! Why don't we find out?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_a6e1c30a", "training_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_11e0bfe9", "duty_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_training_find_out)

eker_convo_training_free = ConvoScreen:new {
	id = "training_free",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f2142cc7", -- It's free, soldier. An Alliance perk.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_f4862cb7", "training_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_8a4cdaa1", "duty_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_training_free)

eker_convo_training_pass = ConvoScreen:new {
	id = "training_pass",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_1f1b512d", -- Pass? Who passes on training? I hope whatever else you're doing is just as useful.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_training_pass)

eker_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_27b3d1b3", -- Plenty. Take a look.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_c6c91897", "train_starships"},
		{"@conversation/yavin_rebel_trainer_2:s_98d991e7", "train_weapons"},
		{"@conversation/yavin_rebel_trainer_2:s_73ccefde", "train_procedures"},
		{"@conversation/yavin_rebel_trainer_2:s_3c4ff185", "train_droid"},
		{"@conversation/yavin_rebel_trainer_2:s_fabecb04", "training_passing_up"}
	}
}
eker_convo_template:addScreen(eker_convo_training_menu)

eker_convo_train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3f00169", -- That's the one?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6bb0cb94", "trained_starships"},
		{"@conversation/yavin_rebel_trainer_2:s_f39da193", "training_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_train_starships)

eker_convo_train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_45b2289f", -- That's your choice?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6bb0cb94", "trained_weapons"},
		{"@conversation/yavin_rebel_trainer_2:s_65c36194", "training_passing_up"}
	}
}
eker_convo_template:addScreen(eker_convo_train_weapons)

eker_convo_train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_82b46acf", -- You sure you can handle it?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_d9cced1f", "trained_procedures"},
		{"@conversation/yavin_rebel_trainer_2:s_d8fef41", "training_passing_up"}
	}
}
eker_convo_template:addScreen(eker_convo_train_procedures)

eker_convo_train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3f00169", -- That's the one?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_d9cced1f", "trained_droid"},
		{"@conversation/yavin_rebel_trainer_2:s_9b34069d", "training_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_train_droid)

eker_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_895e16f4", -- Good choice. Come back when you're done. We've got work to do.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_trained_starships)

eker_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_895e16f4", -- Good choice. Come back when you're done. We've got work to do.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_trained_weapons)

eker_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_895e16f4", -- Good choice. Come back when you're done. We've got work to do.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_trained_procedures)

eker_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_895e16f4", -- Good choice. Come back when you're done. We've got work to do.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_trained_droid)

eker_convo_training_passing_up = ConvoScreen:new {
	id = "training_passing_up",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8f4bcc2b", -- You're passing up a good offer here.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_training_passing_up)

eker_convo_duty_offer = ConvoScreen:new {
	id = "duty_offer",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_6d80a4d8", -- Are you ready for duty? There's plenty of work to be done around here.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_2bf9b1f7", "duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_72c594c9", "duty_later"},
		{"@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_duty_offer)

eker_convo_duty_later = ConvoScreen:new {
	id = "duty_later",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_d270ae31", -- You come see me when you're ready.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_duty_later)

eker_convo_gm_menu = ConvoScreen:new {
	id = "gm_menu",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_e53c5017", -- What mission do you want?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_165db597", "gm_mission1"},
		{"@conversation/yavin_rebel_trainer_2:s_64b6ea44", "gm_mission2"},
		{"@conversation/yavin_rebel_trainer_2:s_b6af2b98", "gm_mission3"},
		{"@conversation/yavin_rebel_trainer_2:s_816055e2", "gm_mission4"},
		{"@conversation/yavin_rebel_trainer_2:s_954c43bb", "gm_escort_duty"},
		{"@conversation/yavin_rebel_trainer_2:s_ec5b15d1", "gm_destroy_duty"},
		{"@conversation/yavin_rebel_trainer_2:s_91156160", "gm_recovery_duty"}
	}
}
eker_convo_template:addScreen(eker_convo_gm_menu)

eker_convo_gm_mission1 = ConvoScreen:new {
	id = "gm_mission1",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_9d95a0f8", -- Very well. Escort mission in Yavin sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_mission1)

eker_convo_gm_mission2 = ConvoScreen:new {
	id = "gm_mission2",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_91746e6", -- Very well. Inspect mission in Yavin sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_mission2)

eker_convo_gm_mission3 = ConvoScreen:new {
	id = "gm_mission3",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8c839067", -- Very well. Inspect mission in Lok sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_mission3)

eker_convo_gm_mission4 = ConvoScreen:new {
	id = "gm_mission4",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_753a307b", -- Very well. Escort mission in Lok sector. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_mission4)

eker_convo_gm_escort_duty = ConvoScreen:new {
	id = "gm_escort_duty",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_escort_duty)

eker_convo_gm_destroy_duty = ConvoScreen:new {
	id = "gm_destroy_duty",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_destroy_duty)

eker_convo_gm_recovery_duty = ConvoScreen:new {
	id = "gm_recovery_duty",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_f3cbd30c", -- Very well. If you find any errors or have suggestions, report them to Niklas at njohansson@soe.sony.com
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_gm_recovery_duty)

eker_convo_handin = ConvoScreen:new {
	id = "handin",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_928a5ee3", -- I'm Major Eker. I am your commanding officer.  You are going to do what I say, when I say it. Do we understand each other?
	stopConversation = "false",
	animation = "salute2",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6a1c47d9", "handin_dismissed"},
		{"@conversation/yavin_rebel_trainer_2:s_c1015a4d", "handin_is_that_right"},
		{"@conversation/yavin_rebel_trainer_2:s_f685a04e", "handin_confession"},
		{"@conversation/yavin_rebel_trainer_2:s_6b158a0e", "gm_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_handin)

eker_convo_handin_dismissed = ConvoScreen:new {
	id = "handin_dismissed",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_97073639", -- Good. I look forward to seeing what you're capable of. Get settled in and return to me when you are ready for your first duty mission. Dismissed.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_handin_dismissed)

eker_convo_handin_is_that_right = ConvoScreen:new {
	id = "handin_is_that_right",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_535a48bf", -- Is that right?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_a9d63a81", "handin_duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_92310551", "handin_which_eker"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_is_that_right)

eker_convo_handin_which_eker = ConvoScreen:new {
	id = "handin_which_eker",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_cc34a699", -- Which Eker is that?
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_8f9a3bf4", "handin_duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_5e5b4379", "handin_defected"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_which_eker)

eker_convo_handin_defected = ConvoScreen:new {
	id = "handin_defected",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_ee574fb3", -- That is correct, soldier. And if you've got a problem with that, then you can transfer to another unit right now. Otherwise, you can rest assured that I now serve the Alliance, 100%. And we will not speak of this again.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_6a1c47d9", "handin_dismissed"},
		{"@conversation/yavin_rebel_trainer_2:s_a9d63a81", "handin_duty_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_defected)

eker_convo_handin_confession = ConvoScreen:new {
	id = "handin_confession",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_fe82187", -- I'm going to tell you something, before you hear it from somebody else. I am a former Imperial officer. I defected. Now I fight for the Alliance.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_2bc43dfd", "handin_heard_me"},
		{"@conversation/yavin_rebel_trainer_2:s_a9d63a81", "handin_duty_menu"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_confession)

eker_convo_handin_heard_me = ConvoScreen:new {
	id = "handin_heard_me",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_3c468733", -- You heard me.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_a9d63a81", "handin_duty_menu"},
		{"@conversation/yavin_rebel_trainer_2:s_dd0cb0d4", "handin_understand"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_heard_me)

eker_convo_handin_understand = ConvoScreen:new {
	id = "handin_understand",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_fd00fedc", -- Because I want you to understand something about me.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_b2e340f6", "handin_hate_empire"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_understand)

eker_convo_handin_hate_empire = ConvoScreen:new {
	id = "handin_hate_empire",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_b532b4dc", -- I hate the Empire. I hate it more than anybody else you'll ever meet. With me, you will have the chance to hit Imperial forces like never before.
	stopConversation = "false",
	options = {
		{"@conversation/yavin_rebel_trainer_2:s_bc57b086", "handin_dismissed"}
	}
}
eker_convo_template:addScreen(eker_convo_handin_hate_empire)

eker_convo_too_busy = ConvoScreen:new {
	id = "too_busy",
	leftDialog = "@conversation/yavin_rebel_trainer_2:s_8740fd1", -- I'm too busy to deal with you now... whatever you are.
	stopConversation = "true",
	options = {
	}
}
eker_convo_template:addScreen(eker_convo_too_busy)

addConversationTemplate("eker_convo_template", eker_convo_template)
