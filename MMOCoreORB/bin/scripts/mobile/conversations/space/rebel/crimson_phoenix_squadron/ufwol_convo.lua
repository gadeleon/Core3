-- General Ufwol (Crimson Phoenix Squadron tier 4, Rori Rebel outpost) conversation; ported from SWG-Source tatooine_rebel_tier4.java with the pre-NGE client lines (feature crimson-phoenix-tier4-ufwol). Handler: ufwolConvoHandler.
ufwol_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "ufwolConvoHandler",
	screens = {}
}

ufwol_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4a4a0211", -- I don't think that you belong here, soldier.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_not_pilot)

ufwol_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4a4a0211", -- I don't think that you belong here, soldier.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_wrong_faction)

ufwol_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_b9b83ec5", -- Eh? You don't fly for the Crimson Phoenix. What are you doing here?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d157e1de", "off_track_duties" } -- I'm looking for missions.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_off_track)

ufwol_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1338e704", -- I can give you an elective duty task. If you're interested, I can give you a briefing?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_c82e9a2f", "duty_brief" } -- Yes, please.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_off_track_duties)

ufwol_convo_off_track_refused = ConvoScreen:new {
	id = "off_track_refused",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_ae002d12", -- Only your commanding officer can assign you a mission. Return to your unit.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_off_track_refused)

ufwol_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4a4a0211", -- I don't think that you belong here, soldier.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_grounded)

ufwol_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_46ccc483", -- I think you've got work to do for Ulvaw'op, soldier.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_not_ready)

ufwol_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a86d6540", -- You've already got a mission. I suggest you do it.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_on_mission)

ufwol_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_8d9faecf", -- That's mission failure, soldier.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_a95ef734", "m1_failed_b0933679" }, -- Requesting redeployment!
		{ "@conversation/tatooine_rebel_tier4:s_9fc24a78", "m1_failed_afcb06fc" } -- Are you transferring me out of this unit?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_failed)

ufwol_convo_m1_failed_b0933679 = ConvoScreen:new {
	id = "m1_failed_b0933679",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_b0933679", -- Granted. 
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_failed_b0933679)

ufwol_convo_m1_failed_afcb06fc = ConvoScreen:new {
	id = "m1_failed_afcb06fc",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_afcb06fc", -- Not yet. But you're on thin ice. Get back out there.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_failed_afcb06fc)

ufwol_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_9b578280", -- Where's that Imperial ship?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_1678be5a", "m2_failed_e2a4b15e" }, -- I haven't brought one down yet.
		{ "@conversation/tatooine_rebel_tier4:s_6912a453", "m2_failed_18e57f03" } -- We're trying, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_failed)

ufwol_convo_m2_failed_e2a4b15e = ConvoScreen:new {
	id = "m2_failed_e2a4b15e",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e2a4b15e", -- Don't talk to me until you've completed your mission.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_failed_e2a4b15e)

ufwol_convo_m2_failed_18e57f03 = ConvoScreen:new {
	id = "m2_failed_18e57f03",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_18e57f03", -- Well try harder! 
	stopConversation = "true",
	animation = "threaten",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_failed_18e57f03)

ufwol_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6d4fe1fb", -- Unacceptable, soldier.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8c5f29f4", "m3_failed_45ae8603" }, -- I want to be a part of the Crimson Phoenix, sir.
		{ "@conversation/tatooine_rebel_tier4:s_63740522", "m3_failed_f3bbd7e7" } -- Requesting redeployment, sir!
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_failed)

ufwol_convo_m3_failed_45ae8603 = ConvoScreen:new {
	id = "m3_failed_45ae8603",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_45ae8603", -- It's not going to happen. Not with results like this. Get back out there and clean up that mess!
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_failed_45ae8603)

ufwol_convo_m3_failed_f3bbd7e7 = ConvoScreen:new {
	id = "m3_failed_f3bbd7e7",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f3bbd7e7", -- I'm not so sure that's a good idea. I'll give you one more shot.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_failed_f3bbd7e7)

ufwol_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_eb925c97", -- I thought you said you WANTED to be a part of the Crimson Phoenix.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_4479e343", "m4_failed_71854a18" }, -- I do, sir!
		{ "@conversation/tatooine_rebel_tier4:s_2022581b", "m4_failed_bbd20f83" } -- Sir, it won't happen again.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_failed)

ufwol_convo_m4_failed_71854a18 = ConvoScreen:new {
	id = "m4_failed_71854a18",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_71854a18", -- Well let's see some guts out  there! Get back in your ship! 
	stopConversation = "true",
	animation = "point_forward",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_failed_71854a18)

ufwol_convo_m4_failed_bbd20f83 = ConvoScreen:new {
	id = "m4_failed_bbd20f83",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_bbd20f83", -- See that it doesn't. Return to your ship and finish what you started.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_failed_bbd20f83)

ufwol_convo_intro = ConvoScreen:new {
	id = "intro",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1ec8846c", -- Hello, pilot. Welcome to Rori. First time here?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_9b43a7ee", "met_258d2f1e" } -- Yes sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_intro)

ufwol_convo_met_258d2f1e = ConvoScreen:new {
	id = "met_258d2f1e",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_258d2f1e", -- You'll be working for me. You've been assigned to the Crimson Phoenix squad. Do you know what that means?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_86137261", "met_36085c51" } -- No sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_met_258d2f1e)

ufwol_convo_met_36085c51 = ConvoScreen:new {
	id = "met_36085c51",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_36085c51", --  Let me tell you something about Crimson Phoenix. This unit was designed to be the best. Do you hear me? THE BEST. I don't tolerate anything less from my pilots.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bb9e4a63", "met_db77876d" } -- Understood, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_met_36085c51)

ufwol_convo_met_db77876d = ConvoScreen:new {
	id = "met_db77876d",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_db77876d", -- I sure as heck am not going to put an untested pilot in charge of important missions. I need to test you out. See what you're made of. Pilots in this unit have nerves of steel. Do you have nerves of steel?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d9cced1f", "met_917742b8" } -- Absolutely.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_met_db77876d)

ufwol_convo_met_917742b8 = ConvoScreen:new {
	id = "met_917742b8",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_917742b8", -- I don't think you do. I think you'll flame out on your first mission.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_6db5d6ce", "met_ab288b4d" } -- Well, put me up there, sir, and we'll see which one of us is wrong.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_met_917742b8)

ufwol_convo_met_ab288b4d = ConvoScreen:new {
	id = "met_ab288b4d",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_ab288b4d", -- OK! Well that's a good start, soldier. You've got some options here. I need a pilot to travel to  the Yavin system and launch a series of attacks against Imperial patrols near the Death Star debris field. We've got Rebel smugglers in that system, and they're doing their best to collect Death Star components for analysis.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_61657d0f", "brief_7e962bfb" } -- I see.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_met_ab288b4d)

ufwol_convo_brief_7e962bfb = ConvoScreen:new {
	id = "brief_7e962bfb",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7e962bfb", -- Several Rebel operatives have been scouting Endor, looking for suspicious Imperial activity. Their mission is complete, and now they're carrying valuable data. They need a fighter pilot to escort them safely out of the system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_2c4789b", "brief_73c9f8b3" } -- Understood.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_brief_7e962bfb)

ufwol_convo_brief_73c9f8b3 = ConvoScreen:new {
	id = "brief_73c9f8b3",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_73c9f8b3", -- Here's an exciting one. I'm looking for a pilot willing to intercept prison ships in the Dathomir system. Those ships are carrying Rebels, and we need those men here with us! The pilot who takes this job will carry a probe outfitted with a virus. That virus will unlock the prisoners' cells. Once they're free, our men will be able to take control of the ship.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bc57b086", "brief_ac30ef3" } -- Sounds good to me.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_brief_73c9f8b3)

ufwol_convo_brief_ac30ef3 = ConvoScreen:new {
	id = "brief_ac30ef3",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_ac30ef3", -- And finally, we've got several damaged freighters out there. Imperial forces attacked them, thinking they carried Rebel forces. They didn't. These are innocent bystanders, and they've suffered on account of us, and now they're sitting ducks. Imperial forces are getting ready to move in and seize those ships. We're going to save them. 
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8ddbf95b", "brief_6231dba" } -- I understand. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_brief_ac30ef3)

ufwol_convo_brief_6231dba = ConvoScreen:new {
	id = "brief_6231dba",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6231dba", -- So? Which mission will you take?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_89951606", "duty_destroy" }, -- Let me at those Imperial patrols.
		{ "@conversation/tatooine_rebel_tier4:s_91502216", "duty_escort" }, -- I'll fly escort for those Rebel spies.
		{ "@conversation/tatooine_rebel_tier4:s_67ee2a0", "duty_recovery" }, -- I want to help those prisoners. 
		{ "@conversation/tatooine_rebel_tier4:s_c1c9b365", "duty_rescue" }, -- I'll do whatever I can to help those disabled freighters.
		{ "@conversation/tatooine_rebel_tier4:s_49805f81", "duty_brief" } -- Can I hear the briefing again?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_brief_6231dba)

ufwol_convo_duty_brief = ConvoScreen:new {
	id = "duty_brief",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4b3f09bc", -- I need a pilot to travel to  the Yavin system and launch a series of attacks against Imperial patrols near the Death Star debris field. We've got Rebel smugglers in that system, and they're doing their best to collect Death Star components for analysis.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_61657d0f", "brief_7e962bfb" } -- I see.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_duty_brief)

ufwol_convo_tier4_incomplete = ConvoScreen:new {
	id = "tier4_incomplete",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_39a10eac", -- Well? Are you ready for a duty assignment? Or would you like to hear the briefing again?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_89951606", "duty_destroy" }, -- Let me at those Imperial patrols.
		{ "@conversation/tatooine_rebel_tier4:s_91502216", "duty_escort" }, -- I'll fly escort for those Rebel spies.
		{ "@conversation/tatooine_rebel_tier4:s_67ee2a0", "duty_recovery" }, -- I want to help those prisoners. 
		{ "@conversation/tatooine_rebel_tier4:s_c1c9b365", "duty_rescue" }, -- I'll do whatever I can to help those disabled freighters.
		{ "@conversation/tatooine_rebel_tier4:s_49805f81", "duty_brief" } -- Can I hear the briefing again?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_tier4_incomplete)

ufwol_convo_here_for_work = ConvoScreen:new {
	id = "here_for_work",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_233489bc", -- Glad to see that you made it back from your assignment with Admiral Burke. Are you looking for work?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_89951606", "duty_destroy" }, -- Let me at those Imperial patrols.
		{ "@conversation/tatooine_rebel_tier4:s_91502216", "duty_escort" }, -- I'll fly escort for those Rebel spies.
		{ "@conversation/tatooine_rebel_tier4:s_67ee2a0", "duty_recovery" }, -- I want to help those prisoners. 
		{ "@conversation/tatooine_rebel_tier4:s_c1c9b365", "duty_rescue" }, -- I'll do whatever I can to help those disabled freighters.
		{ "@conversation/tatooine_rebel_tier4:s_49805f81", "duty_brief" } -- Can I hear the briefing again?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_here_for_work)

ufwol_convo_duty_destroy = ConvoScreen:new {
	id = "duty_destroy",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a5b93c4d", -- You're cleared for liftoff.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_duty_destroy)

ufwol_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a5b93c4d", -- You're cleared for liftoff.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_duty_escort)

ufwol_convo_duty_recovery = ConvoScreen:new {
	id = "duty_recovery",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a5b93c4d", -- You're cleared for liftoff.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_duty_recovery)

ufwol_convo_duty_rescue = ConvoScreen:new {
	id = "duty_rescue",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a5b93c4d", -- You're cleared for liftoff.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_duty_rescue)

ufwol_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_831e2b3a", -- All soldiers receive duty pay at the end of each mission.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_987445c9", "m1_reward_a871501f" }, -- Thank you, sir.
		{ "@conversation/tatooine_rebel_tier4:s_f69a2921", "m1_reward_a871501f" } -- Glad to hear it.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_reward)

ufwol_convo_m1_reward_a871501f = ConvoScreen:new {
	id = "m1_reward_a871501f",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a871501f", -- Report back to me when you're ready for another assignment.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_reward_a871501f)

ufwol_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6c524e01", -- Nice work, %TU. Our engineers are examining  that TIE fighter now. Here's your duty pay.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_9c236354", "m2_reward_76dd2544" }, -- Excellent.
		{ "@conversation/tatooine_rebel_tier4:s_d0fd857b", "m3_reward_76e9b54b" } -- I'll take it.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_reward)

ufwol_convo_m2_reward_76dd2544 = ConvoScreen:new {
	id = "m2_reward_76dd2544",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_76dd2544", -- I suggest you save it for a rainy day.
	stopConversation = "true",
	animation = "tap_head",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_reward_76dd2544)

ufwol_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_d5a98554", -- I have your duty pay.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_acef64cd", "m3_reward_6c01a28a" }, -- I did a good job out there.
		{ "@conversation/tatooine_rebel_tier4:s_d0fd857b", "m3_reward_76e9b54b" } -- I'll take it.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_reward)

ufwol_convo_m3_reward_6c01a28a = ConvoScreen:new {
	id = "m3_reward_6c01a28a",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6c01a28a", -- Well, you're not dead, I'll give you that. Report to me later for your next assignment.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_reward_6c01a28a)

ufwol_convo_m3_reward_76e9b54b = ConvoScreen:new {
	id = "m3_reward_76e9b54b",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_76e9b54b", -- Report to me later for your next assignment.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_reward_76e9b54b)

ufwol_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_bf1cdb65", -- Here's a little something.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_a58b9067", "m4_reward_528a2d25" }, -- Duty pay?
		{ "@conversation/tatooine_rebel_tier4:s_987445c9", "m4_reward_fb3d31a9" } -- Thank you, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_reward)

ufwol_convo_m4_reward_528a2d25 = ConvoScreen:new {
	id = "m4_reward_528a2d25",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_528a2d25", -- Absolutely. You've earned it.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_reward_528a2d25)

ufwol_convo_m4_reward_fb3d31a9 = ConvoScreen:new {
	id = "m4_reward_fb3d31a9",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_fb3d31a9", -- You earned it. Good work out there.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_reward_fb3d31a9)

ufwol_convo_training = ConvoScreen:new {
	id = "training",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_cb594529", -- Well soldier, you've earned the right to upgrade to a new skill. I expect all my pilots to continue their training, at all times! Pick a skill.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_efdacfde", "trained_starships" }, -- I'm interested in hyper-maneuverable starfighters.
		{ "@conversation/tatooine_rebel_tier4:s_daa1d4f4", "trained_weapons" }, -- I'm interested in heavy Alliance component use.
		{ "@conversation/tatooine_rebel_tier4:s_270a2a57", "trained_procedures" }, -- I'm interested in special weapons and tactics training.
		{ "@conversation/tatooine_rebel_tier4:s_1e8289a2", "trained_droid" } -- I'm interested in droid intelligence theory.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_training)

ufwol_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7dae4367", -- Sound choice %TU. Come back soon, we have a lot to do.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_trained_starships)

ufwol_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2eebfe4c", -- With the kind of opposition we've been facing lately, an understanding of new component technology will be invaluable.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_trained_weapons)

ufwol_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7dae4367", -- Sound choice %TU. Come back soon, we have a lot to do.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_trained_procedures)

ufwol_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_cee1914e", -- Solid knowledge of your onboard droid is essential.
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_trained_droid)

ufwol_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_37df0fba", -- You're up. Let's see if you can keep up with my squadron.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bc07030", "m1_2db03120" }, -- What's the mission, sir?
		{ "@conversation/tatooine_rebel_tier4:s_b3e9c738", "m1_e9ad7c02" } -- I'm ready for anything.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_offer)

ufwol_convo_m1_2db03120 = ConvoScreen:new {
	id = "m1_2db03120",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2db03120", -- It's not a spy mission, that's for sure. Hope that doesn't bother you. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_221bd4ce", "m1_6e4f5881" } -- Why would it?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_2db03120)

ufwol_convo_m1_6e4f5881 = ConvoScreen:new {
	id = "m1_6e4f5881",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6e4f5881", -- I hear you did a good job under Ulvaw'op. Do you enjoy working with spies?
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_6c38055e", "m1_325c76db" }, -- I was good at it.
		{ "@conversation/tatooine_rebel_tier4:s_48b7214b", "m1_f3c74323" } -- I just do what I'm told.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_6e4f5881)

ufwol_convo_m1_325c76db = ConvoScreen:new {
	id = "m1_325c76db",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_325c76db", -- Don't have any patience for it, myself. Can't stand all that sneaking around.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_856aca7d", "m1_aa15510b" } -- Ulvaw'op has helped the Alliance.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_325c76db)

ufwol_convo_m1_aa15510b = ConvoScreen:new {
	id = "m1_aa15510b",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_aa15510b", -- I know. His information has saved our butts more than once. And he's probably onto something. I've never seen so much Imperial activity in this area.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_521e8b09", "m1_15235513" } -- I'm sure you've got a plan.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_aa15510b)

ufwol_convo_m1_15235513 = ConvoScreen:new {
	id = "m1_15235513",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_15235513", -- You bet I do. There's trouble brewing. I can smell it in the air. That's why the Alliance created the Crimson Phoenix. We're the frontline defenders. Think you can handle it?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d9cced1f", "m1_5471712d" } -- Absolutely.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_15235513)

ufwol_convo_m1_5471712d = ConvoScreen:new {
	id = "m1_5471712d",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_5471712d", -- We've been planning an attack against a fleet of Imperial fighters for quite some time. We've laid the groundwork. We're ready to go.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_43fcfbca", "m1_f73581de" } -- Imperial fighters? No problem!
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_5471712d)

ufwol_convo_m1_f73581de = ConvoScreen:new {
	id = "m1_f73581de",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f73581de", -- Now listen. Based on the numbers, they've got us beat. No doubt about it. They've got far more ships out there than we do. So every single one of my fighters has got to do the job of TEN pilots.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8ddbf95b", "m1_579532ac" } -- I understand. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_f73581de)

ufwol_convo_m1_579532ac = ConvoScreen:new {
	id = "m1_579532ac",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_579532ac", -- There's something else you need to know. You'll be seeing a new breed of Imperial ships out there.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_c127c173", "m1_b1dd06bd" } -- New TIE fighters?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_579532ac)

ufwol_convo_m1_b1dd06bd = ConvoScreen:new {
	id = "m1_b1dd06bd",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_b1dd06bd", -- Exactly. These are next-generation models. They're designed to be faster, lighter, more accurate and more deadly than any other Imperial ship.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_914a4095", "m1_954ec468" } -- I didn't know the Empire was working on new designs.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_b1dd06bd)

ufwol_convo_m1_954ec468 = ConvoScreen:new {
	id = "m1_954ec468",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_954ec468", -- We've heard advance warnings about this fleet, but we didn't expect so see operational models so soon. The Empire is moving quickly.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_61657d0f", "m1_f689a56f" } -- I see.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_954ec468)

ufwol_convo_m1_f689a56f = ConvoScreen:new {
	id = "m1_f689a56f",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f689a56f", -- The Alliance wants to know one thing. They want to know if OUR best can handle THEIR best. And this is where they get their answer. Right here. Right now.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d55f2579", "m1_accept_d68a9f0a" } -- I'm ready to go.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_f689a56f)

ufwol_convo_m1_accept_d68a9f0a = ConvoScreen:new {
	id = "m1_accept_d68a9f0a",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_d68a9f0a", -- At least you'll have the element of surprise. They're not expecting an attack. I want you to get out there and hit as many of them as you can. We've uploaded coordinates to your ships computer. You're clear to leave for the Dathomir system.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_49e55ca2", "m1_79e6aa32" } -- Yes Sir!
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_accept_d68a9f0a)

ufwol_convo_m1_79e6aa32 = ConvoScreen:new {
	id = "m1_79e6aa32",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_79e6aa32", -- Oh one more thing %TU. All the missions I provide you with will be high risk missions and might be too much to handle by yourself. If you have any favors you can call in, doing so during my missions might be a good idea. Dismissed!
	stopConversation = "true",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_79e6aa32)

ufwol_convo_m1_f3c74323 = ConvoScreen:new {
	id = "m1_f3c74323",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f3c74323", -- Well now you're going to do what I tell you.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_9b43a7ee", "m1_5471712d" } -- Yes sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_f3c74323)

ufwol_convo_m1_e9ad7c02 = ConvoScreen:new {
	id = "m1_e9ad7c02",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e9ad7c02", -- All right. I think you're ready to at least FLY with my squad.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_c8fa77b8", "m1_7ba8daf7" } -- I can't wait!
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_e9ad7c02)

ufwol_convo_m1_7ba8daf7 = ConvoScreen:new {
	id = "m1_7ba8daf7",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7ba8daf7", -- This doesn't mean you're a full member yet. I want to see what my men think of your abilities. Their opinions carry a lot of weight with me.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_2c4789b", "m1_f7cbbb30" } -- Understood.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_7ba8daf7)

ufwol_convo_m1_f7cbbb30 = ConvoScreen:new {
	id = "m1_f7cbbb30",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f7cbbb30", -- And you're in luck. You're going to be one of the first Rebel soldiers to get an up close look at the new Imperial ships.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_314f0ae4", "m1_6d164e59" } -- A new model?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_f7cbbb30)

ufwol_convo_m1_6d164e59 = ConvoScreen:new {
	id = "m1_6d164e59",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6d164e59", -- The Empire has unveiled a new class of TIE fighter. These are brand-new models, next-generation material. They're designed to be faster, lighter, more accurate and more deadly than any ship that's come before them.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_907e88bd", "m1_a71cdd82" } -- Lucky me.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_6d164e59)

ufwol_convo_m1_a71cdd82 = ConvoScreen:new {
	id = "m1_a71cdd82",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a71cdd82", -- The new ships will be part of this fleet. But you've got more than ship technology to worry about. I'll tell you now, based on the numbers, they've got us beat. No doubt about it. They've got far more ships out there than we do. So every single one of my fighters has got to do the job of TEN pilots.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8ddbf95b", "m1_f689a56f" } -- I understand. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m1_a71cdd82)

ufwol_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7b03d343", -- My men tell me you weren't too bad up there. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d059f8aa", "m2_83b2f3f1" }, -- Those TIE fighters are tough!
		{ "@conversation/tatooine_rebel_tier4:s_24f29c02", "m2_8574f09" } -- I held my own.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_offer)

ufwol_convo_m2_83b2f3f1 = ConvoScreen:new {
	id = "m2_83b2f3f1",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_83b2f3f1", -- The Empire has deep pockets. It's incredible, the way they fund their research labs. It's no surprise that their technology outstrips ours.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bb47d59", "m2_ea7b0fb2" } -- I agree.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_83b2f3f1)

ufwol_convo_m2_ea7b0fb2 = ConvoScreen:new {
	id = "m2_ea7b0fb2",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_ea7b0fb2", -- Up 'til now, we've been able to level the playing field just by gutting it out.
	stopConversation = "false",
	animation = "tap_foot",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_61657d0f", "m2_4ca48b38" } -- I see.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_ea7b0fb2)

ufwol_convo_m2_4ca48b38 = ConvoScreen:new {
	id = "m2_4ca48b38",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4ca48b38", -- But I think we can work smarter than that. I want to take a closer look at these new TIE fighters.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_e816c4f3", "m2_4df417ce" } -- I'm not following, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_4ca48b38)

ufwol_convo_m2_4df417ce = ConvoScreen:new {
	id = "m2_4df417ce",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4df417ce", -- These new Imperial ships constitute an imminent threat. We need to know what, EXACTLY, we're up against. 
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bb47d59", "m2_c946f118" } -- I agree.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_4df417ce)

ufwol_convo_m2_c946f118 = ConvoScreen:new {
	id = "m2_c946f118",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c946f118", -- So here's what we're going to do. %TU, you're going to hijack one of those ships.
	stopConversation = "false",
	animation = "point_forward",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_790d22d6", "m2_1cd7da68" } -- That won't be easy.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_c946f118)

ufwol_convo_m2_1cd7da68 = ConvoScreen:new {
	id = "m2_1cd7da68",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1cd7da68", -- I don't think you'd be interested in an easy mission.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_a33056f4", "m2_2183d62a" } -- Absolutely not.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_1cd7da68)

ufwol_convo_m2_2183d62a = ConvoScreen:new {
	id = "m2_2183d62a",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2183d62a", -- I want to get inside one of those ships. Sit in the driver's seat. Take it for a test ride. Smell that Imperial leather. 
	stopConversation = "false",
	animation = "snap_finger1",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d82b46ba", "m2_32b7bf59" } -- I'll try to bring it back in one piece.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_2183d62a)

ufwol_convo_m2_32b7bf59 = ConvoScreen:new {
	id = "m2_32b7bf59",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_32b7bf59", -- I'm giving you access to a space assault droid. It'll help you to get the job done. The droid will take control of the ship, once you've disabled the pilot.  
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8e9d0848", "m2_92a98982" } -- [nod]
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_32b7bf59)

ufwol_convo_m2_92a98982 = ConvoScreen:new {
	id = "m2_92a98982",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_92a98982", -- With any luck, our technicians will figure out a way to put that new technology into OUR ships. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_6425e854", "m2_accept_9fcfe841" } -- Yes sir. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_92a98982)

ufwol_convo_m2_accept_9fcfe841 = ConvoScreen:new {
	id = "m2_accept_9fcfe841",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_9fcfe841", -- Bring me one of those birds. Do whatever it takes. You're cleared to leave for Dathomir.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_accept_9fcfe841)

ufwol_convo_m2_8574f09 = ConvoScreen:new {
	id = "m2_8574f09",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_8574f09", -- Don't be a cowboy. Remember, you're part of a team now. You've got to work with the squad members.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_958c1289", "m2_4c56b685" }, -- As long as they can keep up! 
		{ "@conversation/tatooine_rebel_tier4:s_9288900f", "m2_1b9a0acd" } -- I understand.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_8574f09)

ufwol_convo_m2_4c56b685 = ConvoScreen:new {
	id = "m2_4c56b685",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4c56b685", -- Hey! Don't assume you're the best. You're not a kid anymore, and this isn't a holocron. This is the real thing. You remember that the next time you see one of your fellow pilots taking fire. 
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bb9e4a63", "m2_s201" } -- Understood, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_4c56b685)

ufwol_convo_m2_s201 = ConvoScreen:new {
	id = "m2_s201",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4df417ce", -- These new Imperial ships constitute an imminent threat. We need to know what, EXACTLY, we're up against. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_18d61e21", "m2_c946f118" } -- Agreed.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_s201)

ufwol_convo_m2_1b9a0acd = ConvoScreen:new {
	id = "m2_1b9a0acd",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1b9a0acd", -- What did you think of those new TIE fighters?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_2acccb89", "m2_5e35901c" } -- They're impressive. No doubt about it.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_1b9a0acd)

ufwol_convo_m2_5e35901c = ConvoScreen:new {
	id = "m2_5e35901c",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_5e35901c", -- I lost some brave men up there.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8ddbf95b", "m2_d3234c01" } -- I understand. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_5e35901c)

ufwol_convo_m2_d3234c01 = ConvoScreen:new {
	id = "m2_d3234c01",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_d3234c01", -- Alliance leaders need to know that they can deploy a full Crimson Phoenix squad at any time. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_58a20c33", "m2_428c6440" } -- I know, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_d3234c01)

ufwol_convo_m2_428c6440 = ConvoScreen:new {
	id = "m2_428c6440",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_428c6440", -- My job is to protect my pilots as much as possible. They are the most valuable asset we've got. 
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bb9e4a63", "m2_a582cadc" } -- Understood, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_428c6440)

ufwol_convo_m2_a582cadc = ConvoScreen:new {
	id = "m2_a582cadc",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a582cadc", -- These new Imperial ships constitute an imminent threat. We need to know what, EXACTLY, we're up against.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bb47d59", "m2_s239" } -- I agree.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_a582cadc)

ufwol_convo_m2_s239 = ConvoScreen:new {
	id = "m2_s239",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c946f118", -- So here's what we're going to do. %TU, you're going to hijack one of those ships.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_790d22d6", "m2_s243" } -- That won't be easy.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_s239)

ufwol_convo_m2_s243 = ConvoScreen:new {
	id = "m2_s243",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1cd7da68", -- I don't think you'd be interested in an easy mission.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_a33056f4", "m2_s247" } -- Absolutely not.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_s243)

ufwol_convo_m2_s247 = ConvoScreen:new {
	id = "m2_s247",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2183d62a", -- I want to get inside one of those ships. Sit in the driver's seat. Take it for a test ride. Smell that Imperial leather. 
	stopConversation = "false",
	animation = "snap_finger1",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_d82b46ba", "m2_c5512cb2" } -- I'll try to bring it back in one piece.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_s247)

ufwol_convo_m2_c5512cb2 = ConvoScreen:new {
	id = "m2_c5512cb2",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c5512cb2", -- I'm giving you access to a space assault droid. It'll help you to get the job done. The droid will take control of the ship, once you've disabled the pilot. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8e9d0848", "m2_92a98982" } -- [nod]
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m2_c5512cb2)

ufwol_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_49bf2ccb", -- We've been taking a close look at that TIE fighter. Quite a piece of machinery.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_c8a0830d", "m3_6dea357d" }, -- Especially those guns.
		{ "@conversation/tatooine_rebel_tier4:s_c01ad90e", "m3_c84fe27f" } -- They're going to give us a problem, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_offer)

ufwol_convo_m3_6dea357d = ConvoScreen:new {
	id = "m3_6dea357d",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_6dea357d", -- Incredible handling. It's going to take a while before we find a way to modify their technology for our X-Wings. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bb47d59", "m3_f3eda860" } -- I agree.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_6dea357d)

ufwol_convo_m3_f3eda860 = ConvoScreen:new {
	id = "m3_f3eda860",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f3eda860", -- I'd like to know who's building these ships. They could answer a lot of questions for us. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_2c10011d", "m3_9722b330" } -- Imperial engineers are usually well hidden in the belly of the Empire.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_f3eda860)

ufwol_convo_m3_9722b330 = ConvoScreen:new {
	id = "m3_9722b330",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_9722b330", -- I don't think Imperials built these ships. I think they're using a third-party group.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_89e27dc9", "m3_7d8f56b6" } -- There should be a manufacturing stamp on the chassis.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_9722b330)

ufwol_convo_m3_7d8f56b6 = ConvoScreen:new {
	id = "m3_7d8f56b6",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7d8f56b6", -- No luck there. The engineers, whoever they are, have done a good job covering their tracks.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_63e0ab42", "m3_1eed1024" } -- Don't blame 'em. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_7d8f56b6)

ufwol_convo_m3_1eed1024 = ConvoScreen:new {
	id = "m3_1eed1024",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_1eed1024", -- We're taking a new tack. We may not know WHO'S building them. But maybe we can figure out WHERE their facilities are. 
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_8009422e", "m3_c2b3ccaa" } -- Any leads?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_1eed1024)

ufwol_convo_m3_c2b3ccaa = ConvoScreen:new {
	id = "m3_c2b3ccaa",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c2b3ccaa", -- We're tracking the path of these new ships. They're scattered across several systems, but they seem to be concentrated around Endor. My guess is, where there's smoke there's fire. So let's take a closer look. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bc57b086", "m3_62fa1f75" } -- Sounds good to me.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_c2b3ccaa)

ufwol_convo_m3_62fa1f75 = ConvoScreen:new {
	id = "m3_62fa1f75",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_62fa1f75", -- There's an Imperial space station in Endor. I think that's where the engineers are unloading the new models. So that's your primary target.  You'll join forces with a Crimson Phoenix squad, travel to Endor, and launch an attack. 
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_e42b260e", "m3_accept_fed525e5" } -- I'm on my way.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_62fa1f75)

ufwol_convo_m3_accept_fed525e5 = ConvoScreen:new {
	id = "m3_accept_fed525e5",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_fed525e5", -- Let's see how you do. This is your big break, %TU. Don't screw it up.
	stopConversation = "true",
	animation = "point_forward",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_accept_fed525e5)

ufwol_convo_m3_c84fe27f = ConvoScreen:new {
	id = "m3_c84fe27f",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c84fe27f", -- You got that right. Tell me, what did you accomplish while you were with Ulvaw'op?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_cbcd1643", "m3_c3bd7a11" } -- We were able to capture several spies, a security officer, and an Imperial defector.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_c84fe27f)

ufwol_convo_m3_c3bd7a11 = ConvoScreen:new {
	id = "m3_c3bd7a11",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_c3bd7a11", -- Amazing. This place is lousy with Imperials! What did you learn?
	stopConversation = "false",
	animation = "smack_self",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_f00c2726", "m3_15dc5860" } -- Personally? Not much. Ulvaw'op was in charge of interrogations, and he wasn't exactly forthcoming with me.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_c3bd7a11)

ufwol_convo_m3_15dc5860 = ConvoScreen:new {
	id = "m3_15dc5860",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_15dc5860", -- See? That's what I hate about these guys. They never tell you anything until it's absolutely necessary.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_68772323", "m3_e2aefddd" } -- Sounds like you're trying to stay one step ahead of the Imperials.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_15dc5860)

ufwol_convo_m3_e2aefddd = ConvoScreen:new {
	id = "m3_e2aefddd",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e2aefddd", -- Always. And in the meantime, we've got to find a way to deal with these new TIE fighters. It's going to take a while before we find a way to modify their technology for our X-Wings. 
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_5bb47d59", "m3_3a640dfa" } -- I agree.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_e2aefddd)

ufwol_convo_m3_3a640dfa = ConvoScreen:new {
	id = "m3_3a640dfa",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_3a640dfa", -- And now they know we're out here, so they're sure to come after us eventually. We need to move quickly. I'd like to know who's building these ships. They could answer a lot of questions for us. 
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_15bf89c7", "m3_e81875f0" } -- Imperial engineers?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_3a640dfa)

ufwol_convo_m3_e81875f0 = ConvoScreen:new {
	id = "m3_e81875f0",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e81875f0", -- I don't think they did this in-house. I think the Empire is working with a third party.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_719a036e", "m3_7f14ac3a" } -- Who?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_e81875f0)

ufwol_convo_m3_7f14ac3a = ConvoScreen:new {
	id = "m3_7f14ac3a",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7f14ac3a", -- Don't know. The engineers, whoever they are, have done a good job covering their tracks.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_63e0ab42", "m3_1eed1024" } -- Don't blame 'em. 
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m3_7f14ac3a)

ufwol_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_d30b6d26", -- Congratulations, soldier. You're officially a part of the Crimson Phoenix.
	stopConversation = "false",
	animation = "salute2",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_87f091b9", "m4_33cdebfd" }, -- Thank you, sir. I'm happy to be a part of the team. 
		{ "@conversation/tatooine_rebel_tier4:s_987445c9", "m4_f60ad3e3" } -- Thank you, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_offer)

ufwol_convo_m4_33cdebfd = ConvoScreen:new {
	id = "m4_33cdebfd",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_33cdebfd", -- I've heard good things out there. My boys tell me you can hold your own.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_742d8c68", "m4_856e4aab" } -- I try, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_33cdebfd)

ufwol_convo_m4_856e4aab = ConvoScreen:new {
	id = "m4_856e4aab",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_856e4aab", -- You're now a full member of the squad. That means you'll be reporting to me, and you'll be participating in all squad missions. 
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_b3e9c738", "m4_323479fd" } -- I'm ready for anything.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_856e4aab)

ufwol_convo_m4_323479fd = ConvoScreen:new {
	id = "m4_323479fd",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_323479fd", -- Our attack in Endor was a complete dead end. I was SURE we'd find the manufacturing area. It's too late now anyway. The ships are scattered all over the place, and there's a million of them. 
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_1131a10a", "m4_5b998dc7" } -- Sorry to hear that we wasted our time, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_323479fd)

ufwol_convo_m4_5b998dc7 = ConvoScreen:new {
	id = "m4_5b998dc7",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_5b998dc7", -- On the contrary! We found some very interesting information - and we would have missed it completely if we hadn't inspected Endor so closely.
	stopConversation = "false",
	animation = "tap_head",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_71a53f8b", "m4_ba8b09ff" } -- What's that, sir?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_5b998dc7)

ufwol_convo_m4_ba8b09ff = ConvoScreen:new {
	id = "m4_ba8b09ff",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_ba8b09ff", -- There is a strange level of Imperial activity taking place around Endor. There are hundreds of men and women working there. They are taking extraordinary measures to hide their activities. We just happened to catch a few irregularities on our radar. 
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_fa396956", "m4_a72f79b2" } -- What's the project?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_ba8b09ff)

ufwol_convo_m4_a72f79b2 = ConvoScreen:new {
	id = "m4_a72f79b2",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a72f79b2", -- Unknown.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_32b5bee1", "m4_4123d99b" } -- Could it be the ship factory?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_a72f79b2)

ufwol_convo_m4_4123d99b = ConvoScreen:new {
	id = "m4_4123d99b",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_4123d99b", -- That was my first thought. But I don't think that's it. It's something bigger and much more complex. Based on the data, it doesn't look like they're churning out any mass-produced product. It's something much more unusual, with very detailed specifications.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_fbb318e5", "m4_b659eebb" } -- How can I help, sir?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_4123d99b)

ufwol_convo_m4_b659eebb = ConvoScreen:new {
	id = "m4_b659eebb",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_b659eebb", -- I want you to launch an attack against a TIE bomber. Intel tells us that this bomber is transporting a key piece of machinery to the planet's surface. I'd like to know just what that piece IS.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_fb9f7cd6", "m4_accept_cc7b5947" } -- I'll deliver it to you personally.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_b659eebb)

ufwol_convo_m4_accept_cc7b5947 = ConvoScreen:new {
	id = "m4_accept_cc7b5947",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_cc7b5947", -- See that you do. Head for the Endor system immediately. Dismissed.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_accept_cc7b5947)

ufwol_convo_m4_f60ad3e3 = ConvoScreen:new {
	id = "m4_f60ad3e3",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f60ad3e3", -- You've earned it. You've done everything I've asked, and then some.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_85660b3d", "m4_2f190cf" } -- Any news from that Imperial space station?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_f60ad3e3)

ufwol_convo_m4_2f190cf = ConvoScreen:new {
	id = "m4_2f190cf",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2f190cf", -- Your attack was a success, no doubt about it. But those engineers have vanished. I've never seen anything like it! How can a group of men with heavy machinery be so mobile?
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_2c10011d", "m4_fb05125c" } -- Imperial engineers are usually well hidden in the belly of the Empire.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_2f190cf)

ufwol_convo_m4_fb05125c = ConvoScreen:new {
	id = "m4_fb05125c",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_fb05125c", -- If Ulvaw'op would just TELL us something, maybe we could anticipate these kinds of problems! 
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_9b43a7ee", "m4_2d4185b" } -- Yes sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_fb05125c)

ufwol_convo_m4_2d4185b = ConvoScreen:new {
	id = "m4_2d4185b",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_2d4185b", -- Maybe it's not his fault. Maybe the Imperials are just extremely motivated. What in blazes are they up to?!?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_1131a10a", "m4_7aa5d0f7" } -- Sorry to hear that we wasted our time, sir.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_2d4185b)

ufwol_convo_m4_7aa5d0f7 = ConvoScreen:new {
	id = "m4_7aa5d0f7",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_7aa5d0f7", -- The news isn't all bad. We found some very interesting information - and we would have missed it completely if we hadn't inspected Endor so closely.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_71a53f8b", "m4_ba8b09ff" } -- What's that, sir?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_m4_7aa5d0f7)

ufwol_convo_transfer = ConvoScreen:new {
	id = "transfer",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_30a32651", -- Good, you're here. I have your orders. Seems that somebody has taken an interest in your piloting abilities. You're being transferred.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_1d23eb6a", "transfer_e075ea09" }, -- Where to?
		{ "@conversation/tatooine_rebel_tier4:s_3cc21469", "transfer_f252cbc8" } -- I always knew I was destined for greatness.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer)

ufwol_convo_transfer_e075ea09 = ConvoScreen:new {
	id = "transfer_e075ea09",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e075ea09", -- You'll be serving under Admiral Willham Burke. You may have heard of him. He's commander of the Fourth Battle Group stationed in the Outer Rim, two time recipient of the Alliance Medal of Valor, and one of the finest field commanders in the business.
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bc4f4a10", "transfer_265095d0" }, -- Nope, never heard of him.
		{ "@conversation/tatooine_rebel_tier4:s_8ee4f074", "transfer_36fbddee" } -- Oh, THAT Admiral Burke. I thought you meant someone else.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_e075ea09)

ufwol_convo_transfer_f252cbc8 = ConvoScreen:new {
	id = "transfer_f252cbc8",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_f252cbc8", -- I can assure you that Admiral Burke will not be interested in how great you think you are. He'll expect you to shut your mouth and do your job.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_622525cb", "transfer_3bf1bb23" } -- And Admiral Burke is...?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_f252cbc8)

ufwol_convo_transfer_3bf1bb23 = ConvoScreen:new {
	id = "transfer_3bf1bb23",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_3bf1bb23", -- Your new commanding officer, Admiral Willham Burke. You may have heard of him. Commander of the Fourth Battle Group stationed in the Outer Rim, two time recipient of the Alliance Medal of Valor, one of the finest field commanders in the business.
	stopConversation = "false",
	animation = "explain",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_bc4f4a10", "transfer_265095d0" }, -- Nope, never heard of him.
		{ "@conversation/tatooine_rebel_tier4:s_8ee4f074", "transfer_36fbddee" } -- Oh, THAT Admiral Burke. I thought you meant someone else.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_3bf1bb23)

ufwol_convo_transfer_265095d0 = ConvoScreen:new {
	id = "transfer_265095d0",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_265095d0", -- Then you've been living under a rock. He's heard of you. He's looking for men who can handle a Black Ops mission. I think you may be just the pilot he needs.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_614d7ac4", "transfer_bed2013a" } -- What is the mission?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_265095d0)

ufwol_convo_transfer_36fbddee = ConvoScreen:new {
	id = "transfer_36fbddee",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_36fbddee", -- You getting smart with me? For crying out loud, soldier, it's time for you to straighten up and fly right. Your orders are to report to Doaba Guerfel on Corellia. Admiral Burke will be there to fill you in on the rest of the details.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_9e999838", "transfer_a778e999" } -- I don't really like Corellia this time of year.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_36fbddee)

ufwol_convo_transfer_bed2013a = ConvoScreen:new {
	id = "transfer_bed2013a",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_bed2013a", -- Didn't I say it was top secret? That generally means they don't broadcast all the details. I am sure that Admiral Burke will fill you in once you report for duty.
	stopConversation = "false",
	animation = "laugh",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_ef167e72", "transfer_e7488f0b" } -- Where am I headed?
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_bed2013a)

ufwol_convo_transfer_e7488f0b = ConvoScreen:new {
	id = "transfer_e7488f0b",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_e7488f0b", -- You'll find the Admiral on Corellia, in Doaba Guerfel. You had better prepare yourself. The Fourth Battle Group takes on some of the most dangerous and difficult tasks in the Outer Rim.
	stopConversation = "false",
	options = {
		{ "@conversation/tatooine_rebel_tier4:s_e1da7727", "transfer_35208536" } -- I can handle it.
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_e7488f0b)

ufwol_convo_transfer_35208536 = ConvoScreen:new {
	id = "transfer_35208536",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_35208536", -- Yes, you can. But that doesn't mean you know everything. Keep your wits about you and pay attention. You could learn a lot from Admiral Burke. Now don't keep him waiting. Good luck, pilot.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_35208536)

ufwol_convo_transfer_a778e999 = ConvoScreen:new {
	id = "transfer_a778e999",
	leftDialog = "@conversation/tatooine_rebel_tier4:s_a778e999", -- Are you trying to push my buttons? Bad move, soldier. Now listen to me. Obey your orders, don't give Admiral Burke any of your lip, and pay attention. You could probably learn a thing or two from the Admiral. Now get moving.
	stopConversation = "true",
	animation = "threaten",
	options = {
	}
}
ufwol_convo_template:addScreen(ufwol_convo_transfer_a778e999)

addConversationTemplate("ufwol_convo_template", ufwol_convo_template)
