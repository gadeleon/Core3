-- Brother Extok Evin (Vortex Squadron tier 4, Dearic theater on Talus) conversation screens; ported from SWG-Source naboo_rebel_tier4 (STF conversation/naboo_rebel_tier4, pre-NGE client lines). Handler: evinConvoHandler.lua (feature vortex-tier4-extok-evin-convo).
evin_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "evinConvoHandler",
	screens = {}
}

evin_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3daae2ee", -- Do I know you?
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b3218dae", "off_limits"}, -- I don't think so.
		{"@conversation/naboo_rebel_tier4:s_4c695dbd", "off_limits"} -- No.
	}
}
evin_convo_template:addScreen(evin_convo_not_pilot)

evin_convo_off_limits = ConvoScreen:new {
	id = "off_limits",
	leftDialog = "@conversation/naboo_rebel_tier4:s_8fc2022a", -- This area is off-limits for unsecured personnel.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_off_limits)

evin_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3daae2ee", -- Do I know you?
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b3218dae", "off_limits"}, -- I don't think so.
		{"@conversation/naboo_rebel_tier4:s_4c695dbd", "off_limits"} -- No.
	}
}
evin_convo_template:addScreen(evin_convo_wrong_faction)

evin_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/naboo_rebel_tier4:s_2f2320af", -- What are you, %NU, some kind of double agent?
	animation = "point_accusingly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_457a7010", "grounded_8a64732d"} -- No
	}
}
evin_convo_template:addScreen(evin_convo_grounded)

evin_convo_grounded_8a64732d = ConvoScreen:new {
	id = "grounded_8a64732d",
	leftDialog = "@conversation/naboo_rebel_tier4:s_8a64732d", -- We've been receiving from pretty bad reports about you, though.  Did you know you're under investigation for supporting the Empire?
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_c7932482", "grounded_6b14c8d"} -- I had no idea
	}
}
evin_convo_template:addScreen(evin_convo_grounded_8a64732d)

evin_convo_grounded_6b14c8d = ConvoScreen:new {
	id = "grounded_6b14c8d",
	leftDialog = "@conversation/naboo_rebel_tier4:s_6b14c8d", -- I'm afraid you're grounded until you can clear-up this mess.  You need to improve your standing with the Rebel Alliance before we can trust you with any more assignments.
	animation = "explain",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_grounded_6b14c8d)

evin_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/naboo_rebel_tier4:s_8cd97e8b", -- You're a Rebel pilot? But you're not part of this unit. Are you lost?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_dab8fd8e", "off_track_duties"} -- No. Do you have a mission that I can fly?
	}
}
evin_convo_template:addScreen(evin_convo_off_track)

evin_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/naboo_rebel_tier4:s_127c7ddc", -- Hm! Well, I do have a few duty missions here. Would you like a briefing?
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_c82e9a2f", "duty_brief_1"} -- Yes, please.
	}
}
evin_convo_template:addScreen(evin_convo_off_track_duties)

evin_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/naboo_rebel_tier4:s_942559a7", -- Sorry, I can only assign missions to Vortex pilots. Why don't you try asking your commanding officer? I'll bet you'll have better luck there.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_off_track_refused)

evin_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/naboo_rebel_tier4:s_243a81bd", -- Ezkiel is still in need of your services.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_c2d98904", "not_ready_dismissed"}, -- Ah yes.
		{"@conversation/naboo_rebel_tier4:s_13f3baf7", "not_ready_contact"} -- How did you know?
	}
}
evin_convo_template:addScreen(evin_convo_not_ready)

evin_convo_not_ready_dismissed = ConvoScreen:new {
	id = "not_ready_dismissed",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4d41f7fe", -- Dismissed.
	animation = "dismiss",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_not_ready_dismissed)

evin_convo_not_ready_contact = ConvoScreen:new {
	id = "not_ready_contact",
	leftDialog = "@conversation/naboo_rebel_tier4:s_35065223", -- I stay in close contact with its members. Please return to your work.
	animation = "dismiss",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_not_ready_contact)

evin_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e59caef0", -- You've received your orders.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d92f71f", "on_mission_481965b0"}, -- Yes, I know.
		{"@conversation/naboo_rebel_tier4:s_9b43a7ee", "on_mission_49707203"} -- Yes sir.
	}
}
evin_convo_template:addScreen(evin_convo_on_mission)

evin_convo_on_mission_481965b0 = ConvoScreen:new {
	id = "on_mission_481965b0",
	leftDialog = "@conversation/naboo_rebel_tier4:s_481965b0", -- Please carry them out.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_on_mission_481965b0)

evin_convo_on_mission_49707203 = ConvoScreen:new {
	id = "on_mission_49707203",
	leftDialog = "@conversation/naboo_rebel_tier4:s_49707203", -- Please carry  them out.
	animation = "wave_on_dismissing",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_on_mission_49707203)

evin_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e8a5b38", -- Blast it! Don't you know how important this mission is?
	animation = "gesticulate_wildly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_47443361", "m1_retry_c8592539"}, -- Don't worry. It'll get done.
		{"@conversation/naboo_rebel_tier4:s_b9b677c2", "m1_retry_4a835de4"} -- I ran into a little trouble. It won't happen again.
	}
}
evin_convo_template:addScreen(evin_convo_m1_failed)

evin_convo_m1_retry_c8592539 = ConvoScreen:new {
	id = "m1_retry_c8592539",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c8592539", -- See that it does!
	animation = "stamp_feet",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m1_retry_c8592539)

evin_convo_m1_retry_4a835de4 = ConvoScreen:new {
	id = "m1_retry_4a835de4",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4a835de4", -- I want the Vortex to know that this is the BEST squad in the system.
	animation = "gesticulate_wildly",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m1_retry_4a835de4)

evin_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4e4d6d23", -- Do you realize what will happen if the Inquisitor reaches his destination?
	animation = "hands_above_head",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_25a79f70", "m2_retry_80803e51"}, -- I'm fully aware of the situation, sir!
		{"@conversation/naboo_rebel_tier4:s_d4928d9c", "m2_retry_13010c2d"} -- That's not going to happen.
	}
}
evin_convo_template:addScreen(evin_convo_m2_failed)

evin_convo_m2_retry_80803e51 = ConvoScreen:new {
	id = "m2_retry_80803e51",
	leftDialog = "@conversation/naboo_rebel_tier4:s_80803e51", -- Well start acting like it! Get back up there, NOW!
	animation = "point_up",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m2_retry_80803e51)

evin_convo_m2_retry_13010c2d = ConvoScreen:new {
	id = "m2_retry_13010c2d",
	leftDialog = "@conversation/naboo_rebel_tier4:s_13010c2d", -- You say that, but he's still safely en route! Hurry up and stop that monster, before he destroys all of us!
	animation = "slit_throat",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m2_retry_13010c2d)

evin_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d9bfbc18", -- You realize that if the Inquisition gets their hands on that spy...well, you just realize the situation, don't you?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_23b92517", "m3_retry_34a99b58"}, -- Of course. I'll bring him in.
		{"@conversation/naboo_rebel_tier4:s_461e9b3f", "m3_retry_84f5730a"} -- You've got nothing to worry about.
	}
}
evin_convo_template:addScreen(evin_convo_m3_failed)

evin_convo_m3_retry_34a99b58 = ConvoScreen:new {
	id = "m3_retry_34a99b58",
	leftDialog = "@conversation/naboo_rebel_tier4:s_34a99b58", -- Think about it. If the situation was reversed, and you were the one in trouble, he'd fight for YOU.
	animation = "tap_head",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_retry_34a99b58)

evin_convo_m3_retry_84f5730a = ConvoScreen:new {
	id = "m3_retry_84f5730a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_84f5730a", -- I hope not. This is nerve-wracking.
	animation = "smack_self",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_retry_84f5730a)

evin_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/naboo_rebel_tier4:s_82450216", -- Do you mean to tell me that's the best you can do?
	animation = "gesticulate_wildly",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_f5427310", "m4_retry_3de94b24"}, -- Of course not!
		{"@conversation/naboo_rebel_tier4:s_28a543ae", "m4_retry_be8a1d81"} -- I'm not done yet.
	}
}
evin_convo_template:addScreen(evin_convo_m4_failed)

evin_convo_m4_retry_3de94b24 = ConvoScreen:new {
	id = "m4_retry_3de94b24",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3de94b24", -- Then dig deep, %NU, and get back out there!
	animation = "point_away",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m4_retry_3de94b24)

evin_convo_m4_retry_be8a1d81 = ConvoScreen:new {
	id = "m4_retry_be8a1d81",
	leftDialog = "@conversation/naboo_rebel_tier4:s_be8a1d81", -- Hurry! There's no time to waste.
	animation = "check_wrist_device",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m4_retry_be8a1d81)

evin_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/naboo_rebel_tier4:s_52ea3d5c", -- Well, hey! There you are! Welcome, welcome. I was wondering if you were ever going to get here. I'm Extok Evin, head officer in charge of space warfare in this system.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_4265144c", "met_b5eac7c2"} -- Good to meet you.
	}
}
evin_convo_template:addScreen(evin_convo_intro)

evin_convo_met_b5eac7c2 = ConvoScreen:new {
	id = "met_b5eac7c2",
	leftDialog = "@conversation/naboo_rebel_tier4:s_b5eac7c2", -- You too. I've read your report. You did a heck of a job for Brother Ezkiel and those Bothans.
	animation = "salute1",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_dcc126b1", "met_f789d42a"} -- Just doing my job.
	}
}
evin_convo_template:addScreen(evin_convo_met_b5eac7c2)

evin_convo_met_f789d42a = ConvoScreen:new {
	id = "met_f789d42a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_f789d42a", -- I've been serving the Vortex since I first picked up a space blaster. I'll be coordinating operations against the Empire in this area. And you'll be reporting to me.
	animation = "point_to_self",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b3e9c738", "met_7dec31dd"} -- I'm ready for anything.
	}
}
evin_convo_template:addScreen(evin_convo_met_f789d42a)

evin_convo_met_7dec31dd = ConvoScreen:new {
	id = "met_7dec31dd",
	leftDialog = "@conversation/naboo_rebel_tier4:s_7dec31dd", -- Good! Because I'm happy to report that we're going to be escalating our efforts against the Inquisition.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_9c236354", "met_e67c13ca"} -- Excellent.
	}
}
evin_convo_template:addScreen(evin_convo_met_7dec31dd)

evin_convo_met_e67c13ca = ConvoScreen:new {
	id = "met_e67c13ca",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e67c13ca", -- I think so! Everyone thinks that the Inquisitors are the Emperor's most powerful weapons.  A blow against them would be a blow against Imperial morale.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_94d8d136", "met_e26b9261"} -- Well, Inquisitors ARE dangerous.
	}
}
evin_convo_template:addScreen(evin_convo_met_e67c13ca)

evin_convo_met_e26b9261 = ConvoScreen:new {
	id = "met_e26b9261",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e26b9261", -- Very. But so are we! We'll prove our worth on the battlefield. Now here is the mission roster. Ready?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1adbadc4", "met_7455cef5"} -- I'm ready.
	}
}
evin_convo_template:addScreen(evin_convo_met_e26b9261)

evin_convo_met_7455cef5 = ConvoScreen:new {
	id = "met_7455cef5",
	leftDialog = "@conversation/naboo_rebel_tier4:s_7455cef5", -- Here's the first mission. I want to soften the ground and let the Inquisition know that the Vortex means business. They have put several of their navy pilots on patrol duty. These aren't their elite fighters, so they're a good first target. I need a pilot to launch an attack against them. Maybe YOU are that pilot!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_5e2a2bb1", "met_ae528424"} -- Sounds good.
	}
}
evin_convo_template:addScreen(evin_convo_met_7455cef5)

evin_convo_met_ae528424 = ConvoScreen:new {
	id = "met_ae528424",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ae528424", -- OK, mission number two is as follows. The entire Vortex organization is on the move, in anticipation of our attacks. There are several freighters in the area that are carrying Vortex personnel. They need to be escorted to a secure location.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_61657d0f", "met_e5a30f12"} -- I see.
	}
}
evin_convo_template:addScreen(evin_convo_met_ae528424)

evin_convo_met_e5a30f12 = ConvoScreen:new {
	id = "met_e5a30f12",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e5a30f12", -- Here's the third mission. The Vortex has purchased a small number of Space Assault droids. These are experimental models; we are guarding them very carefully. I'd like you to experiment with them against the Inquisition's data-carrying vessels in Endor. They may be able to provide useful information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6598178f", "met_b5815881"} -- Interesting.
	}
}
evin_convo_template:addScreen(evin_convo_met_e5a30f12)

evin_convo_met_b5815881 = ConvoScreen:new {
	id = "met_b5815881",
	leftDialog = "@conversation/naboo_rebel_tier4:s_b5815881", -- And finally, mission number four! Imperial raiders have disabled a large number of civilian transports in Dantooine. We think they are searching for a Jedi. The ships are immobilized, and Imperial capital ships are closing in. We need a pilot to get there first and repair those ships! Take your pick, %NU.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1b9c5097", "duty_destroy"}, -- No briefing necessary. I am ready to DESTROY those fighter patrols.
		{"@conversation/naboo_rebel_tier4:s_e01d95b6", "duty_escort"}, -- I'd like to provide an escort for those freighters.
		{"@conversation/naboo_rebel_tier4:s_df069f76", "duty_recovery"}, -- Those space droids you mentioned sound interesting!
		{"@conversation/naboo_rebel_tier4:s_2477938c", "duty_rescue"}, -- My ship's built for speed. I'm sure I can reach those transports in time.
		{"@conversation/naboo_rebel_tier4:s_49805f81", "duty_brief_1"} -- Can I hear the briefing again?
	}
}
evin_convo_template:addScreen(evin_convo_met_b5815881)

evin_convo_duty_brief_1 = ConvoScreen:new {
	id = "duty_brief_1",
	leftDialog = "@conversation/naboo_rebel_tier4:s_7455cef5", -- Here's the first mission. I want to soften the ground and let the Inquisition know that the Vortex means business. They have put several of their navy pilots on patrol duty. These aren't their elite fighters, so they're a good first target. I need a pilot to launch an attack against them. Maybe YOU are that pilot!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_5e2a2bb1", "duty_brief_2"} -- Sounds good.
	}
}
evin_convo_template:addScreen(evin_convo_duty_brief_1)

evin_convo_duty_brief_2 = ConvoScreen:new {
	id = "duty_brief_2",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ae528424", -- OK, mission number two is as follows. The entire Vortex organization is on the move, in anticipation of our attacks. There are several freighters in the area that are carrying Vortex personnel. They need to be escorted to a secure location.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_61657d0f", "duty_brief_3"} -- I see.
	}
}
evin_convo_template:addScreen(evin_convo_duty_brief_2)

evin_convo_duty_brief_3 = ConvoScreen:new {
	id = "duty_brief_3",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e5a30f12", -- Here's the third mission. The Vortex has purchased a small number of Space Assault droids. These are experimental models; we are guarding them very carefully. I'd like you to experiment with them against the Inquisition's data-carrying vessels in Endor. They may be able to provide useful information.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6598178f", "duty_brief_4"} -- Interesting.
	}
}
evin_convo_template:addScreen(evin_convo_duty_brief_3)

evin_convo_duty_brief_4 = ConvoScreen:new {
	id = "duty_brief_4",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c2129c67", -- And finally, mission number four! Imperial raiders have disabled a large number of civilian transports in Dantooine. We think they are searching for a Jedi. The ships are immobilized, and Imperial capital ships are closing in. We need a pilot to get there first and repair those ships! Take your pick %NU.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1b9c5097", "duty_destroy"}, -- No briefing necessary. I am ready to DESTROY those fighter patrols.
		{"@conversation/naboo_rebel_tier4:s_e01d95b6", "duty_escort"}, -- I'd like to provide an escort for those freighters.
		{"@conversation/naboo_rebel_tier4:s_df069f76", "duty_recovery"}, -- Those space droids you mentioned sound interesting!
		{"@conversation/naboo_rebel_tier4:s_2477938c", "duty_rescue"}, -- My ship's built for speed. I'm sure I can reach those transports in time.
		{"@conversation/naboo_rebel_tier4:s_49805f81", "duty_brief_1"} -- Can I hear the briefing again?
	}
}
evin_convo_template:addScreen(evin_convo_duty_brief_4)

evin_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/naboo_rebel_tier4:s_70814158", -- Here comes our pilot now! Are you ready to accept a duty mission? Or would you like to hear the briefing again?
	animation = "greet",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1b9c5097", "duty_destroy"}, -- No briefing necessary. I am ready to DESTROY those fighter patrols.
		{"@conversation/naboo_rebel_tier4:s_e01d95b6", "duty_escort"}, -- I'd like to provide an escort for those freighters.
		{"@conversation/naboo_rebel_tier4:s_df069f76", "duty_recovery"}, -- Those space droids you mentioned sound interesting!
		{"@conversation/naboo_rebel_tier4:s_2477938c", "duty_rescue"}, -- My ship's built for speed. I'm sure I can reach those transports in time.
		{"@conversation/naboo_rebel_tier4:s_49805f81", "duty_brief_1"} -- Can I hear the briefing again?
	}
}
evin_convo_template:addScreen(evin_convo_tier4_incomplete)

evin_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/naboo_rebel_tier4:s_fc615cb9", -- I see you have survived your experience with Admiral Burke. Are you back looking for some work?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1b9c5097", "duty_destroy"}, -- No briefing necessary. I am ready to DESTROY those fighter patrols.
		{"@conversation/naboo_rebel_tier4:s_e01d95b6", "duty_escort"}, -- I'd like to provide an escort for those freighters.
		{"@conversation/naboo_rebel_tier4:s_df069f76", "duty_recovery"}, -- Those space droids you mentioned sound interesting!
		{"@conversation/naboo_rebel_tier4:s_2477938c", "duty_rescue"}, -- My ship's built for speed. I'm sure I can reach those transports in time.
		{"@conversation/naboo_rebel_tier4:s_49805f81", "duty_brief_1"} -- Can I hear the briefing again?
	}
}
evin_convo_template:addScreen(evin_convo_here_for_work)

evin_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/naboo_rebel_tier4:s_adc84c63", -- Excellent! Show no mercy. Remember, you decide when you want to end these missions. When you feel that the blow to the Empire has been delivered or you need a break, just land.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_duty_destroy)

evin_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c28b3318", -- You're clear to leave. Remember, you decide when you want to end these missions. When you feel exhausted and can't escort more freighters, we will send someone else to take over so just come back to base.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_duty_escort)

evin_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c9329734", -- They are. Good luck, %TU. Remember, you decide when you want to end these missions. When you feel that we have stolen enough Imperial ships for now, your ship has taken too much damage or something similar, just come back to the base.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_duty_recovery)

evin_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/naboo_rebel_tier4:s_b83725b", -- Let's hope so! Good luck, %TU. Remember, you decide when you want to end these missions. We have several of our personnel out there helping the drifters so when your exhausted or your ship is falling apart, just return to base.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_duty_rescue)

evin_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4222dbd0", -- Very nice, %TU! We are making inroads. The Inquisition is in for a surprise.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6b169ba1", "m1_reward_ba0973a6"}, -- Let's hope they continue to underestimate us.
		{"@conversation/naboo_rebel_tier4:s_d9cced1f", "m1_reward_e9e695cf"} -- Absolutely.
	}
}
evin_convo_template:addScreen(evin_convo_m1_reward)

evin_convo_m1_reward_ba0973a6 = ConvoScreen:new {
	id = "m1_reward_ba0973a6",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ba0973a6", -- They won't; not for long, anyway. They'll see how good we are soon enough. Here's your duty pay.
	animation = "shake_head_no",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m1_reward_ba0973a6)

evin_convo_m1_reward_e9e695cf = ConvoScreen:new {
	id = "m1_reward_e9e695cf",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e9e695cf", -- Here's your duty pay. Come and see me when you're ready for another mission.
	animation = "salute1",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m1_reward_e9e695cf)

evin_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e282986e", -- Duty pay, for my best pilot!
	animation = "salute1",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_88099422", "m2_reward_2e34ca37"}, -- Come on, Evin. Don't lay it on too thick.
		{"@conversation/naboo_rebel_tier4:s_a2454aa3", "m2_reward_d520f8e9"} -- Hey! SOMEBODY'S got to be the best.
	}
}
evin_convo_template:addScreen(evin_convo_m2_reward)

evin_convo_m2_reward_2e34ca37 = ConvoScreen:new {
	id = "m2_reward_2e34ca37",
	leftDialog = "@conversation/naboo_rebel_tier4:s_2e34ca37", -- Hate compliments? Very well. I bet you like money, though.
	animation = "shrug_shoulders",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_77e7784", "m2_reward_62074d0"} -- Who doesn't?
	}
}
evin_convo_template:addScreen(evin_convo_m2_reward_2e34ca37)

evin_convo_m2_reward_62074d0 = ConvoScreen:new {
	id = "m2_reward_62074d0",
	leftDialog = "@conversation/naboo_rebel_tier4:s_62074d0", -- Here you go. And let me know when you're ready for another mission.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m2_reward_62074d0)

evin_convo_m2_reward_d520f8e9 = ConvoScreen:new {
	id = "m2_reward_d520f8e9",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d520f8e9", -- And why shouldn't it be you? Here you go. And let me know when you're ready for another mission.
	animation = "laugh",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m2_reward_d520f8e9)

evin_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/naboo_rebel_tier4:s_75a002d0", -- Our secrets are safe for another day!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6371b34a", "m3_reward_85e568"}, -- Sure - thanks to me.
		{"@conversation/naboo_rebel_tier4:s_2c61b117", "m3_reward_c48bab68"} -- I don't know if the situation is THAT serious.
	}
}
evin_convo_template:addScreen(evin_convo_m3_reward)

evin_convo_m3_reward_85e568 = ConvoScreen:new {
	id = "m3_reward_85e568",
	leftDialog = "@conversation/naboo_rebel_tier4:s_85e568", -- Nice work out there. Here's your duty pay. Come see me when you're ready for your next mission.
	animation = "laugh",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_reward_85e568)

evin_convo_m3_reward_c48bab68 = ConvoScreen:new {
	id = "m3_reward_c48bab68",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c48bab68", -- Then you don't understand how important the Vortex is. Here's your duty pay. Come see me when you're ready for your next mission.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_reward_c48bab68)

evin_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/naboo_rebel_tier4:s_682985ff", -- That was FANTASTIC! I just wish I could have seen the expression on those Imperial faces!
	animation = "applause_excited",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_2928468c", "m4_reward_cc6fef40"}, -- The Inquisition won't be operating in this system anytime soon.
		{"@conversation/naboo_rebel_tier4:s_cbb055c6", "m4_reward_ac8b75ef"} -- They weren't smiling, I can promise you that.
	}
}
evin_convo_template:addScreen(evin_convo_m4_reward)

evin_convo_m4_reward_cc6fef40 = ConvoScreen:new {
	id = "m4_reward_cc6fef40",
	leftDialog = "@conversation/naboo_rebel_tier4:s_cc6fef40", -- This is a great day for the Vortex. Here's your duty pay, %NU. You have definitely earned it.
	animation = "salute1",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m4_reward_cc6fef40)

evin_convo_m4_reward_ac8b75ef = ConvoScreen:new {
	id = "m4_reward_ac8b75ef",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ac8b75ef", -- You're probably right! Well done, %NU. Please accept this duty pay with my thanks.
	animation = "laugh",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m4_reward_ac8b75ef)

evin_convo_training = ConvoScreen:new {
	id = "training",
	leftDialog = "@conversation/naboo_rebel_tier4:s_5dbf1a94", -- Congratulations! You've earned the right to acquire a new skill. The more skills you have, the more money you'll make.  What will it be today?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_f4d84e3", "trained_starships"}, -- How about hyper-maneuverable starfighters?
		{"@conversation/naboo_rebel_tier4:s_dbb3b0b0", "trained_weapons"}, -- How about heavy starship component use?
		{"@conversation/naboo_rebel_tier4:s_d0f87f24", "trained_procedures"}, -- How about special weapons and tactics training?
		{"@conversation/naboo_rebel_tier4:s_71d852f5", "trained_droid"} -- How about droid intelligence theory?
	}
}
evin_convo_template:addScreen(evin_convo_training)

evin_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/naboo_rebel_tier4:s_788df6ff", -- Very well! Come back soon, because we have a few things planned for those Inquisitors.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_trained_starships)

evin_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4ef111c8", -- Good choice. Once you've mastered this skill, I'll be able to use you for more dangerous missions. I feel fortunate to have a pilot like you at my disposal! You've exceeded my expectations in every way.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_trained_weapons)

evin_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/naboo_rebel_tier4:s_b322ae4b", -- Very good. Come back when you are ready for some more action, my friend.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_trained_procedures)

evin_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e5886662", -- Excellent choice. Come back as soon as you can, we have a bit of a problem.
	animation = "nod_head_once",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_trained_droid)

evin_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4975777", -- Well, we're doing our job, %NU. The Inquisition has definitely noticed us. And they're heading our way.
	animation = "pound_fist_chest",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_a399c876", "m1_cf9c9506"}, -- I'm surprised the Inquisition has waited until now to engage the Vortex.
		{"@conversation/naboo_rebel_tier4:s_426e2f6c", "m1_d082018b"} -- We're ready for them.
	}
}
evin_convo_template:addScreen(evin_convo_m1_offer)

evin_convo_m1_cf9c9506 = ConvoScreen:new {
	id = "m1_cf9c9506",
	leftDialog = "@conversation/naboo_rebel_tier4:s_cf9c9506", -- Traditionally, both the Inquisition and the Vortex have kept low profiles. But we can't afford to move slowly; not anymore. The Alliance MUST locate and train light Jedi as soon as possible.
	animation = "pound_fist_palm",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_23048e75", "m1_9ecb7fcf"} -- If Jedi are out there, the Vortex will find them.
	}
}
evin_convo_template:addScreen(evin_convo_m1_cf9c9506)

evin_convo_m1_9ecb7fcf = ConvoScreen:new {
	id = "m1_9ecb7fcf",
	leftDialog = "@conversation/naboo_rebel_tier4:s_9ecb7fcf", -- I think so. But it will be a long and bloody road. And not a straight one, either. We've been plagued by spy activities. Our upcoming missions are extremely dangerous. Frankly, I'm glad. They'll separate the weaklings from the true patriots.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d284d072", "m1_47eb0778"} -- It's hard to separate the good spies from the bad spies.
	}
}
evin_convo_template:addScreen(evin_convo_m1_9ecb7fcf)

evin_convo_m1_47eb0778 = ConvoScreen:new {
	id = "m1_47eb0778",
	leftDialog = "@conversation/naboo_rebel_tier4:s_47eb0778", -- Haha! True. They're all filthy sneaks, aren't they?
	animation = "laugh",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_bfc53dde", "m1_ed0a67e"} -- I guess.
	}
}
evin_convo_template:addScreen(evin_convo_m1_47eb0778)

evin_convo_m1_ed0a67e = ConvoScreen:new {
	id = "m1_ed0a67e",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ed0a67e", -- You know, of course, that we're evacuating Vortex personnel.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_cc335afa", "m1_e9c05f6b"} -- Yes, I  remember.
	}
}
evin_convo_template:addScreen(evin_convo_m1_ed0a67e)

evin_convo_m1_e9c05f6b = ConvoScreen:new {
	id = "m1_e9c05f6b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e9c05f6b", -- Several Vortex members are still in transit. And somehow the Inquisition has discovered the route they're using. They're sending a fleet of fighters to the area.  Our brothers are vulnerable while they're in flight, and the Inquisitors know it.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d1be90a9", "m1_c49d2b1"} -- What's the plan?
	}
}
evin_convo_template:addScreen(evin_convo_m1_e9c05f6b)

evin_convo_m1_c49d2b1 = ConvoScreen:new {
	id = "m1_c49d2b1",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c49d2b1", -- Those freighters aren't built to withstand attacks from Imperial fighters. They need your help.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_14ff5df8", "m1_ae934c27"} -- Are we launching a direct attack?
	}
}
evin_convo_template:addScreen(evin_convo_m1_c49d2b1)

evin_convo_m1_ae934c27 = ConvoScreen:new {
	id = "m1_ae934c27",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ae934c27", -- Negative. There's too many of them. I just want you to hold off the fighters until the freighters are able to move to safety.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_80d8485c", "m1_accept_df1c8925"} -- I'm on it.
	}
}
evin_convo_template:addScreen(evin_convo_m1_ae934c27)

evin_convo_m1_accept_df1c8925 = ConvoScreen:new {
	id = "m1_accept_df1c8925",
	leftDialog = "@conversation/naboo_rebel_tier4:s_df1c8925", -- You'll find the coordinates in your ship database once you reach the Endor system. One more thing my friend. All the missions I provide you with will be high risk missions and might be too much to handle by yourself. If you have any favors you can call in, doing so during my missions might be a good idea. Good luck.
	animation = "salute1",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m1_accept_df1c8925)

evin_convo_m1_d082018b = ConvoScreen:new {
	id = "m1_d082018b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d082018b", -- Absolutely! You know, of course, that we're evacuating Vortex personnel in preparation for the fight.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_cc335afa", "m1_a7a9e2a7"} -- Yes, I  remember.
	}
}
evin_convo_template:addScreen(evin_convo_m1_d082018b)

evin_convo_m1_a7a9e2a7 = ConvoScreen:new {
	id = "m1_a7a9e2a7",
	leftDialog = "@conversation/naboo_rebel_tier4:s_a7a9e2a7", -- Several Vortex members are still in transit. And somehow the Inquisition has discovered the route they're using. They're sending a fleet of fighters to the area. Our brothers are vulnerable while they're in flight, and the Inquisitors know it.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d1be90a9", "m1_c49d2b1"} -- What's the plan?
	}
}
evin_convo_template:addScreen(evin_convo_m1_a7a9e2a7)

evin_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/naboo_rebel_tier4:s_41e4adff", -- Good job out there. Our freighters are safe. And guess what? One of the Inquisitors has targeted our location!
	animation = "beckon",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d3c79ae3", "m2_803445b"}, -- You say that like it's a good thing.
		{"@conversation/naboo_rebel_tier4:s_61dcb099", "m2_s175"} -- Good! I'll destroy anybody who comes this way.
	}
}
evin_convo_template:addScreen(evin_convo_m2_offer)

evin_convo_m2_803445b = ConvoScreen:new {
	id = "m2_803445b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_803445b", -- Absolutely! It means they're taking us seriously.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_f4640a5b", "m2_d082cea6"} -- Which Inquisitor is it? Do you know?
	}
}
evin_convo_template:addScreen(evin_convo_m2_803445b)

evin_convo_m2_d082cea6 = ConvoScreen:new {
	id = "m2_d082cea6",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d082cea6", -- One of their worst. Uvqolo. He's a master technician, with an uncanny ability to find exactly what it is he's looking for.
	animation = "applause_excited",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_422deda3", "m2_5796fa91"} -- The Empire isn't sending him to fight us, is he?
	}
}
evin_convo_template:addScreen(evin_convo_m2_d082cea6)

evin_convo_m2_5796fa91 = ConvoScreen:new {
	id = "m2_5796fa91",
	leftDialog = "@conversation/naboo_rebel_tier4:s_5796fa91", -- No no, of course not. He's strictly an interrogator. And I suspect he wants to find out why the Alliance is so interested in Endor.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_15e6446", "m2_d8a1ee7e"} -- That space debris is definitely hiding Imperial secrets.
	}
}
evin_convo_template:addScreen(evin_convo_m2_5796fa91)

evin_convo_m2_d8a1ee7e = ConvoScreen:new {
	id = "m2_d8a1ee7e",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d8a1ee7e", -- Without a doubt. And those secrets may hold the key to this entire war. Who knows? This could be the most important posting of your career, %TU. You can say that you were there when Extok Evin changed the course of history
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_45387989", "m2_f20ed4c3"} -- Um, yes.
	}
}
evin_convo_template:addScreen(evin_convo_m2_d8a1ee7e)

evin_convo_m2_f20ed4c3 = ConvoScreen:new {
	id = "m2_f20ed4c3",
	leftDialog = "@conversation/naboo_rebel_tier4:s_f20ed4c3", -- Now listen to me. It's of the utmost importance that you stay out of the Inquisition's clutches.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_a13b304c", "m2_6a348e56"} -- Don't worry.  They won't catch me!
	}
}
evin_convo_template:addScreen(evin_convo_m2_f20ed4c3)

evin_convo_m2_6a348e56 = ConvoScreen:new {
	id = "m2_6a348e56",
	leftDialog = "@conversation/naboo_rebel_tier4:s_6a348e56", -- I'm serious. You've heard the stories about the Empire mutating their pilots and welding them to their ships.
	animation = "whisper",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_8a212117", "m2_422da50"} -- Sick.
	}
}
evin_convo_template:addScreen(evin_convo_m2_6a348e56)

evin_convo_m2_422da50 = ConvoScreen:new {
	id = "m2_422da50",
	leftDialog = "@conversation/naboo_rebel_tier4:s_422da50", -- Imagine what they'd do to us.
	animation = "tap_head",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_290b6cd5", "m2_de00af5"} -- I'd rather not.
	}
}
evin_convo_template:addScreen(evin_convo_m2_422da50)

evin_convo_m2_de00af5 = ConvoScreen:new {
	id = "m2_de00af5",
	leftDialog = "@conversation/naboo_rebel_tier4:s_de00af5", -- Inquisitors are careful to protect themselves at all times. But we have a small window of opportunity.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1c8bddbb", "m2_f8a134c0"} -- What is it?
	}
}
evin_convo_template:addScreen(evin_convo_m2_de00af5)

evin_convo_m2_f8a134c0 = ConvoScreen:new {
	id = "m2_f8a134c0",
	leftDialog = "@conversation/naboo_rebel_tier4:s_f8a134c0", -- Through sheer luck, we've managed to learn the details of his travel route. He wishes to stay inconspicuous, so he's not traveling with a large entourage. He's practically defenseless!
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d91a074", "m2_3d213ae3"} -- Well, I wouldn't go that far.
	}
}
evin_convo_template:addScreen(evin_convo_m2_f8a134c0)

evin_convo_m2_3d213ae3 = ConvoScreen:new {
	id = "m2_3d213ae3",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3d213ae3", -- Well, regardless, we know how to find him. That's the good news.
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_3069ecae", "m2_3678a87c"} -- What's the bad news?
	}
}
evin_convo_template:addScreen(evin_convo_m2_3d213ae3)

evin_convo_m2_3678a87c = ConvoScreen:new {
	id = "m2_3678a87c",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3678a87c", -- Most of our space fleet is already occupied. They're escorting Vortex personnel to safety.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_2896ca81", "m2_7294f771"} -- But I'M not busy.
	}
}
evin_convo_template:addScreen(evin_convo_m2_3678a87c)

evin_convo_m2_7294f771 = ConvoScreen:new {
	id = "m2_7294f771",
	leftDialog = "@conversation/naboo_rebel_tier4:s_7294f771", -- Exactly. And this is a golden opportunity, one we can't afford to pass up. I want you to get out there and blast Uvqolo! I'm warning you, it's going to take everything you've got, and then some. Are you up to the job?
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b3e9c738", "m2_accept_4eaf90e6"} -- I'm ready for anything.
	}
}
evin_convo_template:addScreen(evin_convo_m2_7294f771)

evin_convo_m2_accept_4eaf90e6 = ConvoScreen:new {
	id = "m2_accept_4eaf90e6",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4eaf90e6", -- Excellent! You're cleared to leave for the Yavin system immediately.
	animation = "salute1",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m2_accept_4eaf90e6)

evin_convo_m2_s175 = ConvoScreen:new {
	id = "m2_s175",
	leftDialog = "@conversation/naboo_rebel_tier4:s_de00af5", -- Inquisitors are careful to protect themselves at all times. But we have a small window of opportunity.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_1c8bddbb", "m2_s179"} -- What is it?
	}
}
evin_convo_template:addScreen(evin_convo_m2_s175)

evin_convo_m2_s179 = ConvoScreen:new {
	id = "m2_s179",
	leftDialog = "@conversation/naboo_rebel_tier4:s_f8a134c0", -- Through sheer luck, we've managed to learn the details of his travel route. He wishes to stay inconspicuous, so he's not traveling with a large entourage. He's practically defenseless!
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d91a074", "m2_s183"} -- Well, I wouldn't go that far.
	}
}
evin_convo_template:addScreen(evin_convo_m2_s179)

evin_convo_m2_s183 = ConvoScreen:new {
	id = "m2_s183",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3d213ae3", -- Well, regardless, we know how to find him. That's the good news.
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_3069ecae", "m2_3ff3b52b"} -- What's the bad news?
	}
}
evin_convo_template:addScreen(evin_convo_m2_s183)

evin_convo_m2_3ff3b52b = ConvoScreen:new {
	id = "m2_3ff3b52b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_3ff3b52b", -- Most of our space fleet is already busy, escorting Vortex personnel to safety.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_2592b2f2", "m2_7294f771"} -- But not me.
	}
}
evin_convo_template:addScreen(evin_convo_m2_3ff3b52b)

evin_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/naboo_rebel_tier4:s_fc2f8c4c", -- Nice job on that last mission. That Inquisitor didn't know what hit him!
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d17adb67", "m3_c424c512"}, -- I had a good time watching his ship explode.
		{"@conversation/naboo_rebel_tier4:s_3b45e8ed", "m3_a753d65f"} -- My ship's running at peak capacity. I'm ready for another mission.
	}
}
evin_convo_template:addScreen(evin_convo_m3_offer)

evin_convo_m3_c424c512 = ConvoScreen:new {
	id = "m3_c424c512",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c424c512", -- There will be more ships exploding in the future, I'm sure. Hopefully not yours! Now listen. We have a new problem.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_db140dbf", "m3_a8144f6"} -- What is it?
	}
}
evin_convo_template:addScreen(evin_convo_m3_c424c512)

evin_convo_m3_a8144f6 = ConvoScreen:new {
	id = "m3_a8144f6",
	leftDialog = "@conversation/naboo_rebel_tier4:s_a8144f6", -- One of our spies has reported a malfunction with his ship, and he's adrift in Dathomir as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d0b9a993", "m3_8dc4fc41"} -- That's strange. Could it be a false alarm?
	}
}
evin_convo_template:addScreen(evin_convo_m3_a8144f6)

evin_convo_m3_8dc4fc41 = ConvoScreen:new {
	id = "m3_8dc4fc41",
	leftDialog = "@conversation/naboo_rebel_tier4:s_8dc4fc41", -- We've scanned the ship ourselves. Engineers confirm the malfunction.The situation's serious. This spy is carrying valuable information. And the Inquisition is closing in on his location.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_25dc6fac", "m3_a747531a"} -- What kind of information is he carrying?
	}
}
evin_convo_template:addScreen(evin_convo_m3_8dc4fc41)

evin_convo_m3_a747531a = ConvoScreen:new {
	id = "m3_a747531a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_a747531a", -- Well...supposedly, he knows something new about Jedi.
	animation = "whisper",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_113f3fb6", "m3_d8845dfe"} -- Wow! Can you tell me more?
	}
}
evin_convo_template:addScreen(evin_convo_m3_a747531a)

evin_convo_m3_d8845dfe = ConvoScreen:new {
	id = "m3_d8845dfe",
	leftDialog = "@conversation/naboo_rebel_tier4:s_d8845dfe", -- I don't know much myself. The information is strictly classified! But...I overheard some of the brothers discussing it.
	animation = "shrug_hands",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_46787375", "m3_fc616447"} -- Tell me! I can keep a secret.
	}
}
evin_convo_template:addScreen(evin_convo_m3_d8845dfe)

evin_convo_m3_fc616447 = ConvoScreen:new {
	id = "m3_fc616447",
	leftDialog = "@conversation/naboo_rebel_tier4:s_fc616447", -- Well...okay! Supposedly it includes possible locations of several Force-sensitive children. If it's true, and that  information fell into Imperial hands, those children would be dead by the end of the month!
	animation = "whisper",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_711e6727", "m3_7d47427d"} -- Don't worry! It won't happen. Not as long as I'm here.
	}
}
evin_convo_template:addScreen(evin_convo_m3_fc616447)

evin_convo_m3_7d47427d = ConvoScreen:new {
	id = "m3_7d47427d",
	leftDialog = "@conversation/naboo_rebel_tier4:s_7d47427d", -- It can't. It's too important. The discovery of even one Jedi could change the course of this entire conflict! And it goes without saying that the spy knows key details about our organization.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_2c4789b", "m3_6daeb64a"} -- Understood.
	}
}
evin_convo_template:addScreen(evin_convo_m3_7d47427d)

evin_convo_m3_6daeb64a = ConvoScreen:new {
	id = "m3_6daeb64a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_6daeb64a", -- You know, it would look GREAT on our records if we could save this guy.
	animation = "rub_chin_thoughtful",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_c8b9717d", "m3_accept_4e0bf82f"} -- Sir! Can you please just give me the coordinates?
	}
}
evin_convo_template:addScreen(evin_convo_m3_6daeb64a)

evin_convo_m3_accept_4e0bf82f = ConvoScreen:new {
	id = "m3_accept_4e0bf82f",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4e0bf82f", -- Oh! Of course, you're right. The coordinates are already in your database. We're equipping your ship with repair materials. I need you to reach him ASAP, repair his ship, and escort him to safety. Now hurry to the Dathomir system.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_accept_4e0bf82f)

evin_convo_m3_a753d65f = ConvoScreen:new {
	id = "m3_a753d65f",
	leftDialog = "@conversation/naboo_rebel_tier4:s_a753d65f", -- Glad to hear it, because I've got an urgent assignment right here.
	animation = "applause_polite",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_db140dbf", "m3_ef2200e9"} -- What is it?
	}
}
evin_convo_template:addScreen(evin_convo_m3_a753d65f)

evin_convo_m3_ef2200e9 = ConvoScreen:new {
	id = "m3_ef2200e9",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ef2200e9", -- One of our spies' ships has malfunctioned. He's floating adrift in Dathomir as we speak.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_897a43f2", "m3_363f5a49"} -- It just broke down, out of the blue? Could it be a false alarm? Maybe a couple of wires got crossed.
	}
}
evin_convo_template:addScreen(evin_convo_m3_ef2200e9)

evin_convo_m3_363f5a49 = ConvoScreen:new {
	id = "m3_363f5a49",
	leftDialog = "@conversation/naboo_rebel_tier4:s_363f5a49", -- We've scanned the ship ourselves. Engineers confirm the malfunction.The situation's serious. This spy is carrying valuable information.  And the Inquisition is closing in on his location.
	animation = "shake_head_no",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_23c4339a", "m3_ca05e460"} -- The Inquisitors already spotted him?
	}
}
evin_convo_template:addScreen(evin_convo_m3_363f5a49)

evin_convo_m3_ca05e460 = ConvoScreen:new {
	id = "m3_ca05e460",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ca05e460", -- If they get a hold of him, they'll keep him alive - but he'll wish he was dead.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_89488f10", "m3_accept_dd76100c"} -- I'll get him.
	}
}
evin_convo_template:addScreen(evin_convo_m3_ca05e460)

evin_convo_m3_accept_dd76100c = ConvoScreen:new {
	id = "m3_accept_dd76100c",
	leftDialog = "@conversation/naboo_rebel_tier4:s_dd76100c", -- His coordinates are already in your database. We're equipping your ship with repair materials. I need you to reach him ASAP, repair his ship, and escort him to safety. Now hurry to the Dathomir system.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m3_accept_dd76100c)

evin_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/naboo_rebel_tier4:s_4a858e06", -- Incredible work out there! The spy is safe and sound - and so is his information. Soon, we'll have new Jedi walking among us! The entire Vortex organization is grateful for your help.
	animation = "salute1",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_5d4e24a2", "m4_a07914ba"}, -- I'm glad I can be of use.
		{"@conversation/naboo_rebel_tier4:s_9f4dbe82", "m4_2c5be3f2"} -- I'm always ready to fight the Empire.
	}
}
evin_convo_template:addScreen(evin_convo_m4_offer)

evin_convo_m4_a07914ba = ConvoScreen:new {
	id = "m4_a07914ba",
	leftDialog = "@conversation/naboo_rebel_tier4:s_a07914ba", -- We are ready to go after the Inquisition with a vengeance.
	animation = "pound_fist_palm",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_38f1d025", "m4_14192a1b"} -- Is this a declaration of war?
	}
}
evin_convo_template:addScreen(evin_convo_m4_a07914ba)

evin_convo_m4_14192a1b = ConvoScreen:new {
	id = "m4_14192a1b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_14192a1b", -- In my mind, it is. And this is the perfect time to make a move.
	animation = "nod_head_once",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_841d27db", "m4_5d9fd0db"} -- Why?
	}
}
evin_convo_template:addScreen(evin_convo_m4_14192a1b)

evin_convo_m4_5d9fd0db = ConvoScreen:new {
	id = "m4_5d9fd0db",
	leftDialog = "@conversation/naboo_rebel_tier4:s_5d9fd0db", -- They're still reeling from Uvqolo's death. They can't believe an Alliance pilot was able to kill one of their own. Let's see how many MORE we can kill!
	animation = "slit_throat",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_d1be90a9", "m4_80ecabfc"} -- What's the plan?
	}
}
evin_convo_template:addScreen(evin_convo_m4_5d9fd0db)

evin_convo_m4_80ecabfc = ConvoScreen:new {
	id = "m4_80ecabfc",
	leftDialog = "@conversation/naboo_rebel_tier4:s_80ecabfc", -- The Vortex has drawn up a plan of attack against the Imperial space station in Dathomir.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6798dc03", "m4_1e25d8e3"} -- Why that one in particular?
	}
}
evin_convo_template:addScreen(evin_convo_m4_80ecabfc)

evin_convo_m4_1e25d8e3 = ConvoScreen:new {
	id = "m4_1e25d8e3",
	leftDialog = "@conversation/naboo_rebel_tier4:s_1e25d8e3", -- The Inquisition has been using it as a base. It's the perfect way to send a message, if you know what I mean.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b76c91c2", "m4_9b0c24f5"} -- Ah. I see.
	}
}
evin_convo_template:addScreen(evin_convo_m4_1e25d8e3)

evin_convo_m4_9b0c24f5 = ConvoScreen:new {
	id = "m4_9b0c24f5",
	leftDialog = "@conversation/naboo_rebel_tier4:s_9b0c24f5", -- It goes without saying that the space station is well-defended by Imperial fighters.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_52917b0d", "m4_e7a8a370"} -- Of course.
	}
}
evin_convo_template:addScreen(evin_convo_m4_9b0c24f5)

evin_convo_m4_e7a8a370 = ConvoScreen:new {
	id = "m4_e7a8a370",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e7a8a370", -- And that's where you come in. You're going to join forces with  the Vortex squadron and launch an attack against those fighters. That will give our B-Wings time to move into position.
	animation = "point_forward",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_16d870fe", "m4_accept_122f0ea4"} -- Consider it done.
	}
}
evin_convo_template:addScreen(evin_convo_m4_e7a8a370)

evin_convo_m4_accept_122f0ea4 = ConvoScreen:new {
	id = "m4_accept_122f0ea4",
	leftDialog = "@conversation/naboo_rebel_tier4:s_122f0ea4", -- I'll see you when you get back from Dathomir.
	animation = "salute1",
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_m4_accept_122f0ea4)

evin_convo_m4_2c5be3f2 = ConvoScreen:new {
	id = "m4_2c5be3f2",
	leftDialog = "@conversation/naboo_rebel_tier4:s_2c5be3f2", -- We're going on the offensive. The Vortex has decided to attack the Imperial space station in Dathomir.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_6798dc03", "m4_18da605a"} -- Why that one in particular?
	}
}
evin_convo_template:addScreen(evin_convo_m4_2c5be3f2)

evin_convo_m4_18da605a = ConvoScreen:new {
	id = "m4_18da605a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_18da605a", -- The Inquisition has been using it as a base.  It's the perfect way to send a message.
	animation = "explain",
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_b76c91c2", "m4_9b0c24f5"} -- Ah. I see.
	}
}
evin_convo_template:addScreen(evin_convo_m4_18da605a)

evin_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/naboo_rebel_tier4:s_75c90fe4", -- Good to see you again. I have some great news, and I cannot think of a better pilot for this to happen to. You are being transferred to the command of Admiral Willhem Burke. Told you it was great news.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_a65d4a43", "transfer_839a8471"}, -- Who is Admiral Willham Burke?
		{"@conversation/naboo_rebel_tier4:s_fcbee9cd", "transfer_45ceb48b"} -- Why is that great news?
	}
}
evin_convo_template:addScreen(evin_convo_transfer)

evin_convo_transfer_839a8471 = ConvoScreen:new {
	id = "transfer_839a8471",
	leftDialog = "@conversation/naboo_rebel_tier4:s_839a8471", -- Admiral Burke is in charge of the fourth battle fleet, operating in the Outer Rim. A very fine commander. I had the honor of meeting him a few times. An officer and gentleman in every sense of the words.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_86677c6b", "transfer_e1aa63d"} -- What does he want with me?
	}
}
evin_convo_template:addScreen(evin_convo_transfer_839a8471)

evin_convo_transfer_e1aa63d = ConvoScreen:new {
	id = "transfer_e1aa63d",
	leftDialog = "@conversation/naboo_rebel_tier4:s_e1aa63d", -- I am sure he has read the reports of your flying skills and has need of them with his operation group. You are to report to the Admiral immediately. He is waiting for you in Doaba Guerfel on Corellia. I am sure you won't let him down just like you didn't let me down.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_df8d90f1", "transfer_ce74555e"}, -- I am ready. Thank you, sir.
		{"@conversation/naboo_rebel_tier4:s_cb44839f", "transfer_96d9696a"} -- What if I don't want to go?
	}
}
evin_convo_template:addScreen(evin_convo_transfer_e1aa63d)

evin_convo_transfer_ce74555e = ConvoScreen:new {
	id = "transfer_ce74555e",
	leftDialog = "@conversation/naboo_rebel_tier4:s_ce74555e", -- Then get to your ship and get to the Admiral quickly. I am sure that whatever he has in store for you is very urgent and we cannot waste anymore time. Keep attentive and you are sure to learn something from Admiral Burke. Good luck to you.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_transfer_ce74555e)

evin_convo_transfer_96d9696a = ConvoScreen:new {
	id = "transfer_96d9696a",
	leftDialog = "@conversation/naboo_rebel_tier4:s_96d9696a", -- We are in the middle of a war for not only our freedom but for everyone's. We don't get to choose how we serve the Alliance. Now I know that we are not the Empire but you had better be aware that when it comes to traitors and deserters we will not hesitate to act harshly. Are we understood, pilot?
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_8efde2ae", "transfer_c9014c96"} -- Yes, sir.
	}
}
evin_convo_template:addScreen(evin_convo_transfer_96d9696a)

evin_convo_transfer_c9014c96 = ConvoScreen:new {
	id = "transfer_c9014c96",
	leftDialog = "@conversation/naboo_rebel_tier4:s_c9014c96", -- Good. Now get to your ship and get to Corellia. The Admiral will be waiting for you and it does not reflect well on my outfit if you are late. Stay alert and you just might learn something from Admiral Burke. Good luck to you.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_transfer_c9014c96)

evin_convo_transfer_45ceb48b = ConvoScreen:new {
	id = "transfer_45ceb48b",
	leftDialog = "@conversation/naboo_rebel_tier4:s_45ceb48b", -- It means that Admiral Burke has seen your service record and has chosen you personally. He obviously respects your skills to handle a very important mission for him. Either that or he considers you to be expendable.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_e0907aab", "transfer_de5265b4"} -- What!
	}
}
evin_convo_template:addScreen(evin_convo_transfer_45ceb48b)

evin_convo_transfer_de5265b4 = ConvoScreen:new {
	id = "transfer_de5265b4",
	leftDialog = "@conversation/naboo_rebel_tier4:s_de5265b4", -- Oh, nothing. Regardless of why, you are ordered to report to Admiral Burke in Doaba Guerfel on Corellia. He is expecting you shortly so you had better not keep him waiting. I am sure you have important work to do.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_e63887f", "transfer_20ace535"} -- You think I am expendable?
	}
}
evin_convo_template:addScreen(evin_convo_transfer_de5265b4)

evin_convo_transfer_20ace535 = ConvoScreen:new {
	id = "transfer_20ace535",
	leftDialog = "@conversation/naboo_rebel_tier4:s_20ace535", -- No I don't. I assure you I was only kidding around. Let's stay on topic. I recommend that you pay close attention to Admiral Burke, he is supposed to be pretty decent leader so you can probably learn something from him. Be mindful and do your duty without fail.
	stopConversation = "false",
	options = {
		{"@conversation/naboo_rebel_tier4:s_8efde2ae", "transfer_2808ade7"} -- Yes, sir.
	}
}
evin_convo_template:addScreen(evin_convo_transfer_20ace535)

evin_convo_transfer_2808ade7 = ConvoScreen:new {
	id = "transfer_2808ade7",
	leftDialog = "@conversation/naboo_rebel_tier4:s_2808ade7", -- You had best get to your ship and report into Admiral Burke. Good luck to you, pilot.
	stopConversation = "true",
	options = {
	}
}
evin_convo_template:addScreen(evin_convo_transfer_2808ade7)

addConversationTemplate("evin_convo_template", evin_convo_template)
