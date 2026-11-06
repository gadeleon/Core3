-- Field Commander Alozen (Storm Squadron tier 2) conversation; ported from SWG-Source tatooine_imperial_trainer_2b.java with the pre-NGE client lines (feature storm-tier2-alozen). Handler: alozenConvoHandler.
alozen_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "alozenConvoHandler",
	screens = {}
}

alozen_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_21772e5a", -- I'm sorry, I can't help you.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_not_pilot)

alozen_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_4b074298", -- Come back when you're done with your mission. You can abort your mission if you want to start over.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_on_mission)

alozen_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_42e9d63a", -- Well if it isn't another pilot for the Imperial Navy. What do you want?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_4854758d", "off_track_no_missions"}, -- I would like to request a mission.
	}
}
alozen_convo_template:addScreen(alozen_convo_off_track)

alozen_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_d7641f66", -- Normally I wouldn't even consider it, but as it turns out I do have some elective duty tasks that require a pilot.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_b84b366c", "duty_menu"}, -- How can I help?
		{"@conversation/tatooine_imperial_trainer_2b:s_aec16b0a", "off_track_never_mind"}, -- On second thought, never mind.
	}
}
alozen_convo_template:addScreen(alozen_convo_off_track_duties)

alozen_convo_off_track_never_mind = ConvoScreen:new {
	id = "off_track_never_mind",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_8dbf276d", -- Figures. Go get lost.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_off_track_never_mind)

alozen_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_ad3ca2e6", -- Do you think that I'm here to hand out missions like so much candy? Why don't you go talk to your own commanding officer.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_off_track_no_missions)

alozen_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_3d7cbb44", -- You could hunt Rebel raiders, escort our salvage transports or capture some of the pirate salvage transports.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8a202d7b", "duty_raiders"}, -- I'm going to hunt Rebel raiders.
		{"@conversation/tatooine_imperial_trainer_2b:s_d5ee9adc", "duty_escort"}, -- I'd like to escort salvage transports.
		{"@conversation/tatooine_imperial_trainer_2b:s_5950b85e", "duty_salvage"}, -- I'll try and capture pirate salvage ships.
		{"@conversation/tatooine_imperial_trainer_2b:s_b0d3b474", "training_not_ready"}, -- I'm ready for training.
	}
}
alozen_convo_template:addScreen(alozen_convo_duty_menu)

alozen_convo_duty_raiders = ConvoScreen:new {
	id = "duty_raiders",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_8e9a6b0f", -- Any raiders you destroy will hurt the Rebellion's recovery operation. Keep them busy while we finish refining the scan information.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_duty_raiders)

alozen_convo_duty_escort = ConvoScreen:new {
	id = "duty_escort",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_5d5a0c89", -- There's a never ending supply of salvage to recover. The Rebels and other pirates have been capturing our salvage transports. The transport pilots would be grateful of any cover you could provide.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_duty_escort)

alozen_convo_duty_salvage = ConvoScreen:new {
	id = "duty_salvage",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_17ce8fe5", -- It's nearly impossible to patrol the entire debris field, so some pirates go undetected. Any pirate salvage convoys you manage to capture would be an added bonus to our own operations.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_duty_salvage)

alozen_convo_duty_block = ConvoScreen:new {
	id = "duty_block",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_95549379", -- We need to buy time. Slow down the Rebel efforts until we can determine the exact location of the relic. You have operational discretion in this regard, but let me know your plans so I can coordinate with HQ. I've also received new details on the relic from Imperial Intelligence.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_5a7ec1e4", "duty_menu"}, -- What kind of operations can I help with?
	}
}
alozen_convo_template:addScreen(alozen_convo_duty_block)

alozen_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_9893fb0", -- Against my better judgment it would appear that you are fit for some flight training. Personally, I wouldn't waste my time training you but I have my orders too.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_7eed59f9", "training_not_ready"}, -- I am ready for my training.
	}
}
alozen_convo_template:addScreen(alozen_convo_training_offer)

alozen_convo_training_not_ready = ConvoScreen:new {
	id = "training_not_ready",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_1d253370", -- I'm not convinced you're ready for training.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_training_not_ready)

alozen_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_2172d08a", -- As much as I'd like to deny your request, I've seen nothing but good work from you over the past few operations. I have received permission from command to give you access to new training programs. This information is security rated Gamma Three and you may not share any information regarding your training level with another officer. What area would you like to train in?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_ae26c22", "training_later"}, -- Let me think about this for a bit.
	}
}
alozen_convo_template:addScreen(alozen_convo_training_menu)

alozen_convo_training_later = ConvoScreen:new {
	id = "training_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_7b25fbc3", -- You're cleared for training, so let me know when you are ready to begin.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_training_later)

alozen_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_486da900", -- Your continued success will rely on your ability to make maximum use of all new Imperial technology. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "trained_report"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_trained_starships)

alozen_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_8bd72bb5", -- Mastering proper use of heavy weapons technology is key. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "trained_report"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_trained_weapons)

alozen_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_c4880407", -- Developing new levels of tactical and physical excellence will be critical in realizing your true potential. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "trained_report"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_trained_procedures)

alozen_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_31804e15", -- Understanding how to rapidly and efficiently manage the complex systems on board a fighter is a necessary step in your development as a pilot. Use these study programs and destroy them when you have internalized the information.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "trained_report"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_trained_droid)

alozen_convo_trained_report = ConvoScreen:new {
	id = "trained_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_9c0c10ef", -- Report back to me when you are ready for a new assignment.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_trained_report)

alozen_convo_denner_transfer = ConvoScreen:new {
	id = "denner_transfer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_10ee338d", -- Do you have something wrong with your hearing, pilot? You are working for Captain Denner now. Report to him here in the Outpost on the double!
	stopConversation = "true",
	animation = "tap_head",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_denner_transfer)

alozen_convo_m3_won = ConvoScreen:new {
	id = "m3_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_b2d005b0", -- You did it. I would be lying if I said that I wasn't shocked. You have proven yourself to be one excellent pilot and an asset to the Empire. Unfortunately, for me I have just received word that you are being transferred from under my command. 
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_71bf4315", "m3_transferred"}, -- I am being transferred again?
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_won)

alozen_convo_m3_transferred = ConvoScreen:new {
	id = "m3_transferred",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_20009dcb", -- That is what I said soldier. Don't you fly boys ever pay any attention?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_53923b62", "m3_priority_alpha"}, -- Yes sir! We certainly...
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_transferred)

alozen_convo_m3_priority_alpha = ConvoScreen:new {
	id = "m3_priority_alpha",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_54c421ec", -- Never mind. Disregard that. Regardless you are being transferred over to Captain Denner. Word is that all members of Storm Squadron are being transferred over to his command for a priority alpha assignment. It would appear that the Empire is preparing to transfer resources out of this system in order for some new project.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_44522227", "m3_not_privy"}, -- What sort of new project?
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_priority_alpha)

alozen_convo_m3_not_privy = ConvoScreen:new {
	id = "m3_not_privy",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_1af04177", -- I am not privy to that information. Perhaps Captain Denner can fill you in more on your assignment. I am still required to continue with my salvage operation here and that is all I know or care about.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_bf7bc308", "m3_pay"}, -- Where can I find Captain Denner?
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_not_privy)

alozen_convo_m3_pay = ConvoScreen:new {
	id = "m3_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_2f3bf1d8", -- Captain Denner is stationed here in the outpost for the time being. He is organizing the transfer of Storm Squadron and salvage operatives to their new theater of operation. Jump to it soldier. Don't keep your commanding officer waiting. Oh, by the way here is your duty pay for the Twilight Sun.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_pay)

alozen_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_dc229c8d", -- Blast it! You were supposed to be the best man for the job and you seriously botched it. Fortunately for you it would appear that we managed to damage the gunboat enough that it has not been able to hyperspace out of the system.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_1da2b1f3", "m3_another_crack"}, -- So the Twilight Sun is still in the Yavin system.
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_failed)

alozen_convo_m3_another_crack = ConvoScreen:new {
	id = "m3_another_crack",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_c0203d03", -- That is the only reason that I have not busted you right out of the service. You are going to get another crack at capturing the vessel. Get up there and get me that ship before it's able to repair itself.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_a30c1a53", "m3_retry"}, -- Yes sir!
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_another_crack)

alozen_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_4fc85d67", -- What are you still doing standing here talking to me? Get to your ship and get me that core...NOW SOLDIER!
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_retry)

alozen_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_7ec622db", -- Flying Officer %NU, I have an urgent assignment for you. Stand at attention for briefing!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_b6b25f13", "m3_scan_results"}, -- Yes, sir!
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_offer)

alozen_convo_m3_scan_results = ConvoScreen:new {
	id = "m3_scan_results",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_395c2680", -- The scan team has finished processing the results of the system sweep. The scan has revealed a large concentration of Rebel ships in region M84/2. The scan details indicate the Rebels already have a Gunboat class in the region.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_f08d82df", "m3_gunboat"}, -- A capital ship?
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_scan_results)

alozen_convo_m3_gunboat = ConvoScreen:new {
	id = "m3_gunboat",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_62e2ea4c", -- Not quite but pretty close. The fact that this gunboat evaded our sensor net is disturbing. HQ believes the Rebels are planning to transport the Death Star firing core on board that vessel. Since the sensor sweep data is old, they may already have the core.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_916abbd9", "m3_disable"}, -- They may have already escaped.
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_gunboat)

alozen_convo_m3_disable = ConvoScreen:new {
	id = "m3_disable",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_ea3da11c", -- By the Emperor, I hope for all our sakes that is not the case. Your assignment is to locate that gunboat and disable it. We need to recover the core if it is on board and interrogate the crew if it isn't.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_16de6424", "m3_boarding"}, -- You want me to capture a gunboat?
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_disable)

alozen_convo_m3_boarding = ConvoScreen:new {
	id = "m3_boarding",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_9506a2bd", -- A squad of Storm Troopers will be standing by to board the ship. All you need to do is disable the ship's reactor or engine subsystems and render them helpless. Once the Storm Troopers are on board they will take over the ship and then you will have to escort them and the ship to a safe jump point.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "m3_omega"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_boarding)

alozen_convo_m3_omega = ConvoScreen:new {
	id = "m3_omega",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_b7cb6b94", -- This is an Ultimate Omega priority operation. The Emperor would dispatch a more elite team to handle the recovery, but there is no time. You must succeed. Failure to capture the firing core could result in disaster.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_1ff4247a", "m3_accept"}, -- I will not fail.
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_omega)

alozen_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_e6647df0", -- The Emperor himself is interested in the outcome of this operation. Failure will result in harsh penalties.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m3_accept)

alozen_convo_m2_won = ConvoScreen:new {
	id = "m2_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_7e1391b7", -- Welcome back, Officer %NU. The scanning team has submitted their data for review. It's going to take some time to process it all. The debris and the radiation fields make it difficult to get clear readings.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_5365b13d", "m2_processing"}, -- When do you expect the results?
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_won)

alozen_convo_m2_processing = ConvoScreen:new {
	id = "m2_processing",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_7e1ae5f8", -- It could take a few days, even with maximum computing power directed at the problem.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_57c8489e", "m2_buy_time"}, -- What should I do?
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_processing)

alozen_convo_m2_buy_time = ConvoScreen:new {
	id = "m2_buy_time",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_95549379", -- We need to buy time. Slow down the Rebel efforts until we can determine the exact location of the relic. You have operational discretion in this regard, but let me know your plans so I can coordinate with HQ. I've also received new details on the relic from Imperial Intelligence.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_3cbda2cf", "relic_core"}, -- What are the new details?
		{"@conversation/tatooine_imperial_trainer_2b:s_5a7ec1e4", "duty_menu"}, -- What kind of operations can I help with?
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_buy_time)

alozen_convo_relic_core = ConvoScreen:new {
	id = "relic_core",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_e70b39dd", -- Intelligence has lowered the security rating on this operation so key command elements can operate more effectively. The 'relic' is believed to be the firing core of the Death Star's planet-killer weapon.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_9315388f", "relic_mon_cal"}, -- (Whistle, impressed.)
	}
}
alozen_convo_template:addScreen(alozen_convo_relic_core)

alozen_convo_relic_mon_cal = ConvoScreen:new {
	id = "relic_mon_cal",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_f4817c", -- HQ believes that the Rebels have found the core and are planning to extract it. If they succeed, the Mon Cal traitors could duplicate the technology and fabricate their own super weapons.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_9f6b62d3", "relic_lid"}, -- I see why Intelligence put a lid on this.
	}
}
alozen_convo_template:addScreen(alozen_convo_relic_mon_cal)

alozen_convo_relic_lid = ConvoScreen:new {
	id = "relic_lid",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_4e7a1e3a", -- We need to keep it that way. The last thing we need are other races attempting their own recovery operations. Yavin could become a warzone.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_b54802f8", "relic_refine"}, -- We need to find the relic soon.
	}
}
alozen_convo_template:addScreen(alozen_convo_relic_lid)

alozen_convo_relic_refine = ConvoScreen:new {
	id = "relic_refine",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_e6315aa", -- Command is working to refine the scan data as quickly as possible. If we can recover the relic it may help us to construct similar weapons.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_relic_refine)

alozen_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_1a4113b", -- I've already received the report! You lost the scanning team. Unbelievable. Do you know how much it costs to manufacture and deploy a scanning freighter? I thought the Storm Squadron could handle this, but clearly I was misinformed.
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_da3db7b8", "m2_only_pilot"}, -- I..
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_failed)

alozen_convo_m2_only_pilot = ConvoScreen:new {
	id = "m2_only_pilot",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_e240955d", -- If I had anyone else to send up, I would, but you're the only pilot in the system rated for this kind of thing. As much as it disgusts me, I've been ordered to send another scanning team up. You're lucky they aren't sending you to fly garbage detail on some backwater outer rim world.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_b6b25f13", "m2_my_way"}, -- Yes, sir!
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_only_pilot)

alozen_convo_m2_my_way = ConvoScreen:new {
	id = "m2_my_way",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_c27ccdd6", -- If I had things my way, you'd never see the inside of a fighter again.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_10c85b25", "m2_reprimand"}, -- Good for me you don't have things your way.
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_my_way)

alozen_convo_m2_reprimand = ConvoScreen:new {
	id = "m2_reprimand",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_3c521b4d", -- Watch your mouth, pilot. I can still stick a reprimand on your file a shipload of boronic acid couldn't clean off.
	stopConversation = "false",
	animation = "snap_finger2",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_86b2a029", "m2_retry"}, -- (Roll eyes.) Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_reprimand)

alozen_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_dbcc5353", -- The new scan ship is waiting for you. Don't lose this one.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_retry)

alozen_convo_m2_start = ConvoScreen:new {
	id = "m2_start",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_bf7cf7b8", -- I'll dispatch the scanning team. I need you to go up and escort the team while they make their sweep. There are probably Rebel fighters in that region, so you'll need to stay sharp. Once the scans are complete, return to me. I have a few things you can do while we process the scan results.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m2_start)

alozen_convo_m1_won = ConvoScreen:new {
	id = "m1_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_80efb61c", -- Any progress with the search?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_4d81d507", "m1_pay"}, -- I managed to find this activity log on a Rebel ship.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_won)

alozen_convo_m1_pay = ConvoScreen:new {
	id = "m1_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_847e12c5", -- Hmm. Looks like the Rebels have definitely found something. There's a lot of activity in region M84/2. I'll dispatch a scanning team to check it out.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_65d0e7ef", "m1_region"}, -- Do you think that's where the relic is located?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_pay)

alozen_convo_m1_region = ConvoScreen:new {
	id = "m1_region",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_48a73eb9", -- Very likely. Region M84/2 is within the probability projection that Imperial Intelligence sent us. We still don't know what we'll find there.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_fe624ae0", "m2_start"}, -- What do you plan to do?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_region)

alozen_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_55289b72", -- Well, it's the pilot from the Navy. Having fun in your auto cooled little cockpit? You know what its like to trudge around in the jungle wearing armor? The sun is killing me, today.
	stopConversation = "false",
	animation = "tap_foot",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_5cab0f15", "m1_no_relic"}, -- I haven't had luck in finding Rebel information.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_failed)

alozen_convo_m1_no_relic = ConvoScreen:new {
	id = "m1_no_relic",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_5c8a242", -- We haven't had any luck finding the relic, either.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_647a7426", "m1_advice"}, -- Any advice?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_no_relic)

alozen_convo_m1_advice = ConvoScreen:new {
	id = "m1_advice",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_598456ed", -- Search the Death Star debris, the radiation clouds, and the nebulae from the Yavin gas giant. They seem like likely areas for the Rebels to hide. All of the garbage from the Death Star makes it hard to scan the system, so you're on your own.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_24fbbc08", "m1_retry"}, -- I'll keep searching.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_advice)

alozen_convo_m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_567022e6", -- You do that.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_retry)

alozen_convo_greeting = ConvoScreen:new {
	id = "greeting",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_128d62a", -- I'm very busy coordinating the ground effort here at the base. I'll have to talk to you later.
	stopConversation = "false",
	animation = "check_wrist_device",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_2eaae5bc", "m1_late"}, -- Commander Oberhaur told me to contact you.
		{"@conversation/tatooine_imperial_trainer_2b:s_53b0407b", "not_expected"}, -- I am a member of Storm Squadron.
		{"@conversation/tatooine_imperial_trainer_2b:s_a73dd488", "leave_alone"}, -- I'm sorry, I'll leave you alone.
	}
}
alozen_convo_template:addScreen(alozen_convo_greeting)

alozen_convo_not_expected = ConvoScreen:new {
	id = "not_expected",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_ed5d85e3", -- You aren't the one I was told to expect. My information is security rated Gamma Three. I can only talk to the one Oberhaur is sending.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_not_expected)

alozen_convo_leave_alone = ConvoScreen:new {
	id = "leave_alone",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_1eb2fb7a", -- If you see a pilot from Storm Squadron tell him to come talk to me. Oberhaur promised he'd be here by now.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_leave_alone)

alozen_convo_m1_late = ConvoScreen:new {
	id = "m1_late",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_f1639d7c", -- You flyboys certainly like to take your time. While you've been gallivanting across the stars, I've had men dying in Rebel raids.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_f14c78f8", "m1_supervision"}, -- I came as soon as I received my orders.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_late)

alozen_convo_m1_supervision = ConvoScreen:new {
	id = "m1_supervision",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_34b41ecc", -- Those orders detailed that you are under my direct supervision for the duration of this operation. You will be prompt next time, is that clear?
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_b6b25f13", "m1_respect"}, -- Yes, sir!
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_supervision)

alozen_convo_m1_respect = ConvoScreen:new {
	id = "m1_respect",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_591121d9", -- That's better. The least you fly boys can do is show a little respect.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_8efde2ae", "m1_situation"}, -- Yes, sir.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_respect)

alozen_convo_m1_situation = ConvoScreen:new {
	id = "m1_situation",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_957a3e29", -- Here's the situation. This information is highly classified, I do not need to remind you of the penalties of leaking Gamma Three intelligence.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_e053d691", "m1_death_star"}, -- (Nod.)
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_situation)

alozen_convo_m1_death_star = ConvoScreen:new {
	id = "m1_death_star",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_19717825", -- Since the destruction of the Death Star, the Empire has maintained a heavy presence in Yavin. The Death Star was not completely disintegrated in the core explosion and the remaining debris still contains valuable raw materials and technology.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_7a761694", "m1_salvage"}, -- (Continue to listen.)
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_death_star)

alozen_convo_m1_salvage = ConvoScreen:new {
	id = "m1_salvage",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_18478398", -- Although the Imperial Navy usually handles space operations, the Imperial Engineering Corps is in charge of materials recovery. We've been slowly salvaging large portions of the Death Star to be recycled into new projects.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_6598178f", "m1_incursions"}, -- Interesting.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_salvage)

alozen_convo_m1_incursions = ConvoScreen:new {
	id = "m1_incursions",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_6d22cae7", -- We aren't the only ones interested by the Death Star's potential. Various alien factions, as well as pirates, and the Rebellion has sent scavengers and special teams in to try and recover secret technology. We have a Navy division here, but lately the Rebellion has been sending in larger and larger incursions.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_47f58b41", "m1_something_big"}, -- You think they found something?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_incursions)

alozen_convo_m1_something_big = ConvoScreen:new {
	id = "m1_something_big",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_d1b5b50", -- Given our calculations of their incursions and the blast pattern of the Death Star's destruction, Imperial Intelligence believes they've found something. Something big. In fact, they are hopping mad we didn't find it first.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_81e0c16", "m1_bravo_zeta"}, -- What is it they found?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_something_big)

alozen_convo_m1_bravo_zeta = ConvoScreen:new {
	id = "m1_bravo_zeta",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_12d564a4", -- It's priority clearance Bravo Zeta. Way above my head. All I've been told is that the Storm Squadron was being assigned to deal with the situation.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_7a761694", "m1_search_teams"}, -- (Continue to listen.)
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_bravo_zeta)

alozen_convo_m1_search_teams = ConvoScreen:new {
	id = "m1_search_teams",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_bd3101cc", -- We've dispatched teams to search for whatever the Rebels found, but it will take time. Command has the idea that one of you Storm Squadron thugs could accelerate the process by hunting down the Rebels and beating the information out of them.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_d040d381", "m1_convoluted"}, -- I take it you don't agree?
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_search_teams)

alozen_convo_m1_convoluted = ConvoScreen:new {
	id = "m1_convoluted",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_f81f75fc", -- Command has us searching for something and we don't even have specs on its dimensions. We don't even know what its supposed to be. Now they want someone to go hunt down Rebels to find out the information they don't know or do know and just won't tell us? This job shouldn't be this convoluted. I should be directing walkers in battle, not grubbing around in a debris field.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/tatooine_imperial_trainer_2b:s_38c83a93", "m1_accept"}, -- I'll see if I can help.
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_convoluted)

alozen_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_2b:s_e617e5c8", -- We have located an area that it would appear the rebel agents are using as a meeting place with flight commanders. We believe it is these agents that have the information we are after. If you find a Rebel, search his ship's computer for the ships activity logs and return to me when you find anything that might help us out.
	stopConversation = "true",
	options = {
	}
}
alozen_convo_template:addScreen(alozen_convo_m1_accept)

addConversationTemplate("alozen_convo_template", alozen_convo_template)
