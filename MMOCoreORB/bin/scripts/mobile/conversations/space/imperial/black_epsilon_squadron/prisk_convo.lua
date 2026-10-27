-- Prisk Kith'Vys (Black Epsilon tier 2) conversation; ported from SWG-Source corellia_imperial_trainer_2.java with the pre-NGE client lines (feature black-epsilon-tier2-prisk). Handler: priskConvoHandler.
prisk_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "priskConvoHandler",
	screens = {}
}

prisk_convo_privateer = ConvoScreen:new {
	id = "privateer",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_fc007f1", -- You would hate to ruin my mood by speaking with me friend, so why don't we end our conversation here.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_privateer)

prisk_convo_rebel = ConvoScreen:new {
	id = "rebel",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_dbf39d2a", -- Your face is familiar to me, but I can't remember why. You're probably wanted for something, I'm sure.
	stopConversation = "true",
	animation = "slow_down",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_rebel)

prisk_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_4391b2de", -- You would hate to ruin my mood by speaking with me, so why don't we end our conversation here.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_not_pilot)

prisk_convo_wanted_male = ConvoScreen:new {
	id = "wanted_male",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f7df921b", -- %TU, is it?  I hear you are a wanted man.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_7090182", "enemy_male"}, -- What?!
	}
}
prisk_convo_template:addScreen(prisk_convo_wanted_male)

prisk_convo_enemy_male = ConvoScreen:new {
	id = "enemy_male",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_83993cf3", -- It seems you are an enemy of the Empire after all.  Did you think we would not know of this little... indiscretion?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_ecb17e60", "cannot_trust_male"}, -- I don't know what you mean
	}
}
prisk_convo_template:addScreen(prisk_convo_enemy_male)

prisk_convo_cannot_trust_male = ConvoScreen:new {
	id = "cannot_trust_male",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_3ec7906d", -- Yes, of course you don't.  Nevertheless, you cannot be trusted to fly for the Imperial Navy.  Not after what you did.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_5b204877", "prove_devotion"}, -- What can I do?
	}
}
prisk_convo_template:addScreen(prisk_convo_cannot_trust_male)

prisk_convo_prove_devotion = ConvoScreen:new {
	id = "prove_devotion",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_8f26747e", -- Prove your devotion to the Empire.  If you improve your standing with the Empire, you may have a future after all.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_71d84d34", "not_ahead"}, -- A future in the Imperial Navy, you mean.
	}
}
prisk_convo_template:addScreen(prisk_convo_prove_devotion)

prisk_convo_not_ahead = ConvoScreen:new {
	id = "not_ahead",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f35be898", -- Let's not get ahead of ourselves, %NU.
	stopConversation = "true",
	animation = "laugh_titter",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_not_ahead)

prisk_convo_wanted_female = ConvoScreen:new {
	id = "wanted_female",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_9d62faa2", -- %TU, is it?  I hear you are a wanted woman.
	stopConversation = "false",
	animation = "sigh_deeply",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_7090182", "enemy_female"}, -- What?!
	}
}
prisk_convo_template:addScreen(prisk_convo_wanted_female)

prisk_convo_enemy_female = ConvoScreen:new {
	id = "enemy_female",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_c2b7ea3a", -- It seems females such as yourself are too unreliable to be trustworthy agents for the Empire after all.  Did you think we would not know of this little... indiscretion?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_ecb17e60", "cannot_trust_female"}, -- I don't know what you mean
	}
}
prisk_convo_template:addScreen(prisk_convo_enemy_female)

prisk_convo_cannot_trust_female = ConvoScreen:new {
	id = "cannot_trust_female",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_af154d31", -- Yes, of course you don't.  Nevertheless, you cannot be trusted to fly for the Imperial Navy.  Not that I am surprised. I have long argued against the inclusion of females in the military.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_5b204877", "prove_devotion"}, -- What can I do?
	}
}
prisk_convo_template:addScreen(prisk_convo_cannot_trust_female)

prisk_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_74f9775d", -- I do not have time for pleasantries, pilot. Why have you come?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_4854758d", "off_track_no_missions"}, -- I would like to request a mission.
	}
}
prisk_convo_template:addScreen(prisk_convo_off_track)

prisk_convo_off_track_duties = ConvoScreen:new {
	id = "off_track_duties",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_60a52374", -- I would like to think that you are more skilled at flying than you are at military protocol. However, I do have some duty missions that need tending to. I'll save the important missions for my good pilots.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_bd5df827", "duty_pirates"}, -- [DESTROY] I wish to assist in anti-pirate patrols.
		{"@conversation/corellia_imperial_trainer_2:s_798fbe2", "duty_merchant"}, -- [ESCORT] I will assist as a merchant escort.
		{"@conversation/corellia_imperial_trainer_2:s_1a0f022", "duty_rebels"}, -- [DESTROY] I'm looking to dust a few Rebels.
		{"@conversation/corellia_imperial_trainer_2:s_3e38e6a0", "duty_security"}, -- [ESCORT] I wish to assist the local security forces.
	}
}
prisk_convo_template:addScreen(prisk_convo_off_track_duties)

prisk_convo_off_track_no_missions = ConvoScreen:new {
	id = "off_track_no_missions",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_42aa1748", -- Do not waste my time with inane requests. If you want a mission, go speak to your own commanding officer.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_off_track_no_missions)

prisk_convo_duty_pirates = ConvoScreen:new {
	id = "duty_pirates",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_dc33e486", -- Downing local pirates will make the Empire look favorable to the citizens of this sector.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_duty_pirates)

prisk_convo_duty_merchant = ConvoScreen:new {
	id = "duty_merchant",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e8db34a5", -- Trade is the lifeblood of the Corellian system. This task will give us high visibility with those whose loyalty we aim to sway.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_duty_merchant)

prisk_convo_duty_rebels = ConvoScreen:new {
	id = "duty_rebels",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e17fc7e4", -- Leave no survivors. The Emperor does not look favorably on mercy or weakness.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_duty_rebels)

prisk_convo_duty_security = ConvoScreen:new {
	id = "duty_security",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_3ab6a9ed", -- We need you to escort one of our scanning vessels on its rounds.  As you can imagine both smugglers and Rebels alike would love to see these craft out of commission.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_duty_security)

prisk_convo_assignment_waiting = ConvoScreen:new {
	id = "assignment_waiting",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_9a117462", -- It's about time that you returned. I have an assignment for you and it cannot wait.
	stopConversation = "false",
	animation = "nod",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_6d3be6aa", "m12_brief"}, -- What is the task?
	}
}
prisk_convo_template:addScreen(prisk_convo_assignment_waiting)

prisk_convo_tour_complete = ConvoScreen:new {
	id = "tour_complete",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_be3a7e31", -- That is all I have for you.  Speak with Haymir Rendundi for more duties. He is currently stationed at Imperial command on Yavin 4. Keep your nose clean and do your duty.  Haymir isn't nice like me and will be all over you if you mess up. Or are you here for more duties?
	stopConversation = "false",
	animation = "thumb_up",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_79375065", "dismissed"}, -- Dismissed, aye sir!
		{"@conversation/corellia_imperial_trainer_2:s_d335136f", "duty_menu"}, -- Yes I am.
	}
}
prisk_convo_template:addScreen(prisk_convo_tour_complete)

prisk_convo_dismissed = ConvoScreen:new {
	id = "dismissed",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_25457635", -- Good, that is all.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_dismissed)

prisk_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_ee11d13c", -- Since you appear to have run out of useful things to do, take some duties to keep you busy.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_bd5df827", "duty_pirates"}, -- [DESTROY] I wish to assist in anti-pirate patrols.
		{"@conversation/corellia_imperial_trainer_2:s_798fbe2", "duty_merchant"}, -- [ESCORT] I will assist as a merchant escort.
		{"@conversation/corellia_imperial_trainer_2:s_1a0f022", "duty_rebels"}, -- [DESTROY] I'm looking to dust a few Rebels.
		{"@conversation/corellia_imperial_trainer_2:s_3e38e6a0", "duty_security"}, -- [ESCORT] I wish to assist the local security forces.
	}
}
prisk_convo_template:addScreen(prisk_convo_duty_menu)

prisk_convo_final_retry = ConvoScreen:new {
	id = "final_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_4cc1cf3b", -- This attack must proceed as planned.  Survive for as long as you can and keep their communications down.  Black Epsilon and your Emperor are counting on you.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_final_retry)

prisk_convo_final_offer = ConvoScreen:new {
	id = "final_offer",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_d9391d4a", -- Your tour with me is just about finished, but I have one final task.
	stopConversation = "false",
	animation = "nod",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9d2c9b0a", "final_surprise"}, -- Do you have more enemy fighter squads to put out of commission?
	}
}
prisk_convo_template:addScreen(prisk_convo_final_offer)

prisk_convo_final_surprise = ConvoScreen:new {
	id = "final_surprise",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e978ca6b", -- Not exactly.  The Rebels have taken note of your activities in this system and are setting up a little surprise for you.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_7ca4fcb8", "final_decoy_fighter"}, -- What sort of surprise?
	}
}
prisk_convo_template:addScreen(prisk_convo_final_surprise)

prisk_convo_final_decoy_fighter = ConvoScreen:new {
	id = "final_decoy_fighter",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_25edc644", -- There will be a lone fighter passing near one of the outer asteroid belts.  This fighter will be unmanned though the piloting droid will put up a fight.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_17780ca7", "final_decoy"}, -- What is the purpose of this craft?
	}
}
prisk_convo_template:addScreen(prisk_convo_final_decoy_fighter)

prisk_convo_final_decoy = ConvoScreen:new {
	id = "final_decoy",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_af16cd74", -- It is a decoy to lure you specifically.  They intend to ambush you, and Black Epsilon intends to let them.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9cca1500", "final_ambush"}, -- Why is the ambush important?
		{"@conversation/corellia_imperial_trainer_2:s_6ed7de92", "final_survive"}, -- What must I do?
		{"@conversation/corellia_imperial_trainer_2:s_83bf02e8", "final_backup"}, -- What sort of back up will I have?
		{"@conversation/corellia_imperial_trainer_2:s_dbd8c729", "final_accept"}, -- I am ready.
	}
}
prisk_convo_template:addScreen(prisk_convo_final_decoy)

prisk_convo_final_ambush = ConvoScreen:new {
	id = "final_ambush",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f0c8febb", -- We have discovered the location of their fighter wing headquarters.  When they scramble the ships to destroy you, Black Epsilon will launch its own attack on their undefended base.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9cca1500", "final_ambush"}, -- Why is the ambush important?
		{"@conversation/corellia_imperial_trainer_2:s_6ed7de92", "final_survive"}, -- What must I do?
		{"@conversation/corellia_imperial_trainer_2:s_83bf02e8", "final_backup"}, -- What sort of back up will I have?
		{"@conversation/corellia_imperial_trainer_2:s_dbd8c729", "final_accept"}, -- I am ready.
	}
}
prisk_convo_template:addScreen(prisk_convo_final_ambush)

prisk_convo_final_survive = ConvoScreen:new {
	id = "final_survive",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_2fa7f312", -- You must survive.  TechOps is installing a powerful communications jammer in your craft.  This jammer will allow the attacking forces to communicate with each other to avoid suspicion, but will prevent communications from their base.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9cca1500", "final_ambush"}, -- Why is the ambush important?
		{"@conversation/corellia_imperial_trainer_2:s_6ed7de92", "final_survive"}, -- What must I do?
		{"@conversation/corellia_imperial_trainer_2:s_83bf02e8", "final_backup"}, -- What sort of back up will I have?
		{"@conversation/corellia_imperial_trainer_2:s_dbd8c729", "final_accept"}, -- I am ready.
	}
}
prisk_convo_template:addScreen(prisk_convo_final_survive)

prisk_convo_final_backup = ConvoScreen:new {
	id = "final_backup",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_d1f1fea2", -- You will have none.  If you are half as good as you are confidant, you might live long enough to get out of this.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9cca1500", "final_ambush"}, -- Why is the ambush important?
		{"@conversation/corellia_imperial_trainer_2:s_6ed7de92", "final_survive"}, -- What must I do?
		{"@conversation/corellia_imperial_trainer_2:s_83bf02e8", "final_backup"}, -- What sort of back up will I have?
		{"@conversation/corellia_imperial_trainer_2:s_dbd8c729", "final_accept"}, -- I am ready.
	}
}
prisk_convo_template:addScreen(prisk_convo_final_backup)

prisk_convo_final_accept = ConvoScreen:new {
	id = "final_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_329f7488", -- Remember, you must stay within range of the ambush point.  We will provide you with a location that will disrupt their hyperspace jumps, it is all the help you will get from us.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_final_accept)

prisk_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_ae8492d2", -- You already have orders to carry out. Your time is my time, so quit wasting it or you may find yourself out of time.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_5ffdd434", "hyperdrive"}, -- I need a hyperdrive!
	}
}
prisk_convo_template:addScreen(prisk_convo_on_mission)

prisk_convo_hyperdrive = ConvoScreen:new {
	id = "hyperdrive",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_ccf466b2", -- That is correct.  You do need a hyperdrive if you're going to be of use to me.  I suggest you purchase a better ship immediately.
	stopConversation = "true",
	animation = "nod_head_once",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_hyperdrive)

prisk_convo_opening_failed = ConvoScreen:new {
	id = "opening_failed",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e2d5b9eb", -- Blast it! Next time you mess up and fail, stay dead! I don't have any time for pilots who don't know when to zig when they should have zagged.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_37680b25", "opening_retry"}, -- Let me try again. You won't be disappointed.
	}
}
prisk_convo_template:addScreen(prisk_convo_opening_failed)

prisk_convo_opening_retry = ConvoScreen:new {
	id = "opening_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_5bfd4371", -- Fine. Have it your way. Get out there and prove yourself worthy of being in my squad. Capture that Hidden Dagger freighter.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_opening_retry)

prisk_convo_m12_retry = ConvoScreen:new {
	id = "m12_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_bae9fe80", -- You have failed to dispose of Darmin, get back up there before he can land.
	stopConversation = "true",
	animation = "point_up",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m12_retry)

prisk_convo_m13_retry = ConvoScreen:new {
	id = "m13_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_63e01bb7", -- How can you fail such a simple task? Get back in space and complete your mission.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m13_retry)

prisk_convo_m14_retry = ConvoScreen:new {
	id = "m14_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_b5a3714a", -- I will not have these bombers reach their objective.  Get up there and destroy them.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m14_retry)

prisk_convo_m15_retry = ConvoScreen:new {
	id = "m15_retry",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_fe284208", -- What's wrong?  Were the mean Rebels too much for you?  Get up there and finish them.
	stopConversation = "true",
	animation = "point_up",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m15_retry)

prisk_convo_m12_won = ConvoScreen:new {
	id = "m12_won",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e67a0734", -- You have more potential than I was expecting. Darmin will no longer be a thorn in the side of the Empire, thanks to your...intervention.
	stopConversation = "false",
	animation = "thumb_up",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_59894e66", "m12_reward"}, -- It was nothing. He deserved what he got.
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_won)

prisk_convo_m12_reward = ConvoScreen:new {
	id = "m12_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_c4179a5d", -- Indeed. The Empire always rewards those who go above and beyond. Here is a small token of our appreciation for your service. Enjoy it and come back to me when you are ready for more work.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m12_reward)

prisk_convo_m13_won = ConvoScreen:new {
	id = "m13_won",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_cfb9fb6e", -- You are back already? Do you have anything to report or are you just here wasting my time?
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_d4374209", "m13_reward"}, -- [Hand over dossier]
	}
}
prisk_convo_template:addScreen(prisk_convo_m13_won)

prisk_convo_m13_reward = ConvoScreen:new {
	id = "m13_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_9f952cc3", -- Excellently done. Maybe you are not as worthless as I first thought. This dossier is sure to have many interesting facts that the Inquisition is sure to enjoy. Here is your payment for services rendered. Return to me when you are ready for more work.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m13_reward)

prisk_convo_m14_won = ConvoScreen:new {
	id = "m14_won",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_b69b5bf4", -- I honestly didn't expect you to survive this one. Yet again you prove to be a very resourceful pilot. Thanks to your efforts, the bomber squadron has been destroyed and security brought to the system.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_16439d46", "m14_reward"}, -- All in a days work.
	}
}
prisk_convo_template:addScreen(prisk_convo_m14_won)

prisk_convo_m14_reward = ConvoScreen:new {
	id = "m14_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_a70cef5", -- You destroy and entire squad of Rebel bombers and all you say is...all in a days work? I am liking you more and more each day. Here is your commission for taking those bombers out. Take some time to yourself and when you are ready come back for some more work.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m14_reward)

prisk_convo_m15_won = ConvoScreen:new {
	id = "m15_won",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_9d96ae32", -- I have reviewed your ship logs and must say that I am surprised that the Rebels decided to attack you. Regardless you handled yourself with utmost skill and ruthlessness. Nice work.
	stopConversation = "false",
	animation = "thumb_up",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_8e613fca", "m15_reward"}, -- The Rebels barely know how to pilot their ships. It is no big deal.
	}
}
prisk_convo_template:addScreen(prisk_convo_m15_won)

prisk_convo_m15_reward = ConvoScreen:new {
	id = "m15_reward",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_345e676a", -- To the Empire it is a very big deal. To show their appreciation, here is a bonus payment. Take some time off and enjoy that bonus. When you are ready come back and see me for some more work.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m15_reward)

prisk_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_584a90f8", -- You've done an excellent job for me, %NU.  I can see that you are ready for more training.  What are you interested in learning?
	stopConversation = "false",
	animation = "explain",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_training_menu)

prisk_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_3f764ef1", -- Excellent choice.  The Empires advanced craft are worth the effort required to master them.  I have a critical task that you can apply your new-found skills to.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_116d8b3b", "m12_brief_trained"}, -- What sort of task.
	}
}
prisk_convo_template:addScreen(prisk_convo_trained_starships)

prisk_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_cc4d7ea", -- Yes, and you will be afforded the opportunity to use that knowledge.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_ceafaf0b", "m14_brief_trained"}, -- Do you have a task for me?
	}
}
prisk_convo_template:addScreen(prisk_convo_trained_weapons)

prisk_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f3d4db20", -- I have a priority task to accompany this assignment.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_116d8b3b", "m15_brief"}, -- What sort of task.
	}
}
prisk_convo_template:addScreen(prisk_convo_trained_procedures)

prisk_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_c914798f", -- Indeed, droid management is important. Your droid is almost as vital as your blaster. I have another mission lined up for you, so get your droid prepared.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_b51a649", "m13_brief"}, -- Do I get to baby-sit another freighter?
	}
}
prisk_convo_template:addScreen(prisk_convo_trained_droid)

prisk_convo_m12_brief = ConvoScreen:new {
	id = "m12_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_50b5b468", -- The Rebels are flying in a diplomat named Darmin Lerspri, supposedly an Alderaanian official of some sort who happened to be off world when it was destroyed.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_69d014bc", "m12_intel"}, -- What Intelligence do we have on the target?
		{"@conversation/corellia_imperial_trainer_2:s_1bbb820a", "m12_alderaan"}, -- About Alderaan....
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_brief)

prisk_convo_m12_brief_trained = ConvoScreen:new {
	id = "m12_brief_trained",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_8db61bfa", -- Not all tasks can be fit for the history books, but perhaps this one may.  The Rebels are flying in a diplomat named Darmin Lerspri, supposedly an Alderaanian official of some sort who happened to be off world when it was destroyed.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_69d014bc", "m12_intel"}, -- What Intelligence do we have on the target?
		{"@conversation/corellia_imperial_trainer_2:s_1bbb820a", "m12_alderaan"}, -- About Alderaan....
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_brief_trained)

prisk_convo_m12_alderaan = ConvoScreen:new {
	id = "m12_alderaan",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_cf473cb7", -- We are not here to discuss a dead and wasted planet, stay focused!
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_69d014bc", "m12_intel"}, -- What Intelligence do we have on the target?
		{"@conversation/corellia_imperial_trainer_2:s_1bbb820a", "m12_alderaan"}, -- About Alderaan....
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_alderaan)

prisk_convo_m12_intel = ConvoScreen:new {
	id = "m12_intel",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_3dc996d2", -- Darmin will be travelling in a YT-1300 named the 'Nerfs Pride', and will likely have an armed escort.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_cb86c1fc", "m12_nerfs_pride"}, -- 'Nerfs Pride'?
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_intel)

prisk_convo_m12_nerfs_pride = ConvoScreen:new {
	id = "m12_nerfs_pride",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_a335f4ff", -- Apparently he was some sort of nerf herder on his native Alderaan.  The ships name is not of concern.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_d6508432", "m12_kill"}, -- I am to capture this man?
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_nerfs_pride)

prisk_convo_m12_kill = ConvoScreen:new {
	id = "m12_kill",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_1d40157", -- No, you are to kill him.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_62b8eb46", "m12_assassin"}, -- I thought you wanted pilots, not assassins?
		{"@conversation/corellia_imperial_trainer_2:s_91f63d81", "m12_escort"}, -- Can you estimate the strength of his escort?
		{"@conversation/corellia_imperial_trainer_2:s_2c4789b", "m12_accept"}, -- Understood.
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_kill)

prisk_convo_m12_assassin = ConvoScreen:new {
	id = "m12_assassin",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_b0ab6617", -- Pilots I have.  But I do not want this man to even set foot on Corellia. So I need an assassin.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_62b8eb46", "m12_assassin"}, -- I thought you wanted pilots, not assassins?
		{"@conversation/corellia_imperial_trainer_2:s_91f63d81", "m12_escort"}, -- Can you estimate the strength of his escort?
		{"@conversation/corellia_imperial_trainer_2:s_2c4789b", "m12_accept"}, -- Understood.
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_assassin)

prisk_convo_m12_escort = ConvoScreen:new {
	id = "m12_escort",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f016912e", -- I expect only a couple fighters.  What you should be more concerned with is the local fighter wing here on Corellia.  We do not know of their base yet, so they may be scrambled while we remain unaware.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_62b8eb46", "m12_assassin"}, -- I thought you wanted pilots, not assassins?
		{"@conversation/corellia_imperial_trainer_2:s_91f63d81", "m12_escort"}, -- Can you estimate the strength of his escort?
		{"@conversation/corellia_imperial_trainer_2:s_2c4789b", "m12_accept"}, -- Understood.
	}
}
prisk_convo_template:addScreen(prisk_convo_m12_escort)

prisk_convo_m12_accept = ConvoScreen:new {
	id = "m12_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_96e86218", -- Good luck %NU, take no prisoners.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m12_accept)

prisk_convo_m13_brief = ConvoScreen:new {
	id = "m13_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_79813bfb", -- Black Epsilon command wants you to intercept a freighter and inspect their cargo.  You are looking for a Personnel Dossier on Rebel agents working in the Coronet area.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_88523765", "m13_accept"}, -- What should I do with the freighter?
	}
}
prisk_convo_template:addScreen(prisk_convo_m13_brief)

prisk_convo_m13_accept = ConvoScreen:new {
	id = "m13_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_b76e5165", -- That is between you, the freighter, and the cold reaches of space.  Dismissed!
	stopConversation = "true",
	animation = "salute1",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m13_accept)

prisk_convo_m14_brief = ConvoScreen:new {
	id = "m14_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_c52a69c1", -- There has been a squad of Rebel bombers sighted in the system. Black Epsilon has been tasked with their destruction.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_d6dfa36e", "m14_navy"}, -- Shouldn't a straightforward assault be handled by the Navy?
	}
}
prisk_convo_template:addScreen(prisk_convo_m14_brief)

prisk_convo_m14_brief_trained = ConvoScreen:new {
	id = "m14_brief_trained",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_98840984", -- Indeed.  There has been a squad of Rebel bombers sighted in the system. Black Epsilon has been tasked with their destruction.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_d6dfa36e", "m14_navy"}, -- Shouldn't a straightforward assault be handled by the Navy?
	}
}
prisk_convo_template:addScreen(prisk_convo_m14_brief_trained)

prisk_convo_m14_navy = ConvoScreen:new {
	id = "m14_navy",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_2517a327", -- The Imperial Navy is tied up with other tasks at the moment.  Black Epsilon can accomplish with one craft what would take them ten.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_1ff4247a", "m14_accept"}, -- I will not fail.
	}
}
prisk_convo_template:addScreen(prisk_convo_m14_navy)

prisk_convo_m14_accept = ConvoScreen:new {
	id = "m14_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_8abe1dd0", -- See that you don't.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m14_accept)

prisk_convo_m15_brief = ConvoScreen:new {
	id = "m15_brief",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_1946850", -- One of the scanning vessels received odd signals from a Nebula in the system. There are possible Rebel craft in the area, but the interference from the Nebula make it difficult to confirm.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_908955bc", "m15_hunt"}, -- This is a reconnaissance flight then?
	}
}
prisk_convo_template:addScreen(prisk_convo_m15_brief)

prisk_convo_m15_hunt = ConvoScreen:new {
	id = "m15_hunt",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_eb835e9e", -- No, this is a burrow mite hunt.  I KNOW they are in there, and I want you to dig them out.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_2c4789b", "m15_accept"}, -- Understood.
	}
}
prisk_convo_template:addScreen(prisk_convo_m15_hunt)

prisk_convo_m15_accept = ConvoScreen:new {
	id = "m15_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_f4fd144d", -- They will not be able to resist attacking you.  Ambush is their favorite tactic knowing that a direct assault is futile.  Show them what it means cross with Black Epsilon.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_m15_accept)

prisk_convo_opening_done = ConvoScreen:new {
	id = "opening_done",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_392fc531", -- Well done. Consider yourself part of my squad. I do not have time for idle chatter %NU, so are you prepared for your next assignment?
	stopConversation = "false",
	animation = "thumbs_up",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_d335136f", "duty_menu"}, -- Yes I am.
		{"@conversation/corellia_imperial_trainer_2:s_25c6e073", "other_matters"}, -- No, I have other matters to attend to.
	}
}
prisk_convo_template:addScreen(prisk_convo_opening_done)

prisk_convo_other_matters = ConvoScreen:new {
	id = "other_matters",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_395e48e8", -- Then return when speaking with me will not be such an inconvenience.  I will not look forward to you wasting more of my time.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_other_matters)

prisk_convo_hakassha_sent = ConvoScreen:new {
	id = "hakassha_sent",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_6a1562ad", -- What do you want?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_9edd30bf", "gawking"}, -- Hakasha sent me.
	}
}
prisk_convo_template:addScreen(prisk_convo_hakassha_sent)

prisk_convo_gawking = ConvoScreen:new {
	id = "gawking",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_c71a5ce3", -- How does that explain you gawking like a fool?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_f87e5fe8", "bothawui"}, -- I believed that Bothawui had sided with the Rebellion.
	}
}
prisk_convo_template:addScreen(prisk_convo_gawking)

prisk_convo_bothawui = ConvoScreen:new {
	id = "bothawui",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_eea972b1", -- By such narrow minded thinking, all humans would be loyal followers of the Empire. Bothawui remains neutral as always, though many clans have openly sided with the Rebels, my clan has found the Imperial coffers deep enough for our loyalties.  I am sure one such as you can understand.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_f4f691ae", "test_run"}, -- Indeed.  I am ready for a mission.
	}
}
prisk_convo_template:addScreen(prisk_convo_bothawui)

prisk_convo_test_run = ConvoScreen:new {
	id = "test_run",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_2ee19e18", -- Eager and to the point, I like that. I willing to give you a test run. If you succeed I think that I might have an opening in my squad for you. If you fail...well you will be dead and I won't lose any sleep over it. There is a Hidden Dagger heavy transport entering the system that needs to be eliminated.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_7a33d3dc", "expendable"}, -- What will be my involvement?
	}
}
prisk_convo_template:addScreen(prisk_convo_test_run)

prisk_convo_expendable = ConvoScreen:new {
	id = "expendable",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_fd8878bc", -- I fully expect you to die. You are still expendable in my book so consider this a test.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_e7f16de3", "hidden_daggers"}, -- Who are these Hidden Daggers?
		{"@conversation/corellia_imperial_trainer_2:s_f37f3d1a", "why_destroy"}, -- Why do we want them destroyed?
		{"@conversation/corellia_imperial_trainer_2:s_8bf01045", "capture"}, -- I'll take the mission.
	}
}
prisk_convo_template:addScreen(prisk_convo_expendable)

prisk_convo_hidden_daggers = ConvoScreen:new {
	id = "hidden_daggers",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_683cbf70", -- The Hidden Daggers were a minor band of highly skilled Assassins founded by a disavowed Flail Cutthroat Lieutenant.  They were never well known, taking only small bounties and have since degenerated into a band of thugs and pirates.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_e7f16de3", "hidden_daggers"}, -- Who are these Hidden Daggers?
		{"@conversation/corellia_imperial_trainer_2:s_f37f3d1a", "why_destroy"}, -- Why do we want them destroyed?
		{"@conversation/corellia_imperial_trainer_2:s_8bf01045", "capture"}, -- I'll take the mission.
	}
}
prisk_convo_template:addScreen(prisk_convo_hidden_daggers)

prisk_convo_why_destroy = ConvoScreen:new {
	id = "why_destroy",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_bc90f6c5", -- However inept they may be, they did manage to acquire some information about the 'Rebel' attack of the 72nd Army Barracks.  They are transporting this information to the Rebels here on Corellia now.  This cannot be allowed to happen.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_e7f16de3", "hidden_daggers"}, -- Who are these Hidden Daggers?
		{"@conversation/corellia_imperial_trainer_2:s_f37f3d1a", "why_destroy"}, -- Why do we want them destroyed?
		{"@conversation/corellia_imperial_trainer_2:s_8bf01045", "capture"}, -- I'll take the mission.
	}
}
prisk_convo_template:addScreen(prisk_convo_why_destroy)

prisk_convo_capture = ConvoScreen:new {
	id = "capture",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_aa457e5d", -- This will not be a simple ordeal.  If Black Epsilon just wanted them destroyed, we would have dispatched the Navy.  We need this vessel captured.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_83c3790d", "how"}, -- How will I do this?
		{"@conversation/corellia_imperial_trainer_2:s_c8516ab0", "why_capture"}, -- Why do we need them captured?
		{"@conversation/corellia_imperial_trainer_2:s_1d1f03a8", "opening_accept"}, -- I am ready to take off.
	}
}
prisk_convo_template:addScreen(prisk_convo_capture)

prisk_convo_how = ConvoScreen:new {
	id = "how",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_52841755", -- They will likely have an escort.  This escort must be neutralized.  Then target the freighter's engines to disable them.  After they are down, move into position, and upload an autopilot override program that TechOps is outfitting your craft with now.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_26912e4b", "crew"}, -- What should I do with the crew?
	}
}
prisk_convo_template:addScreen(prisk_convo_how)

prisk_convo_crew = ConvoScreen:new {
	id = "crew",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_4a5ef35b", -- The crew has been accounted for.  Just get the program uploaded.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_83c3790d", "how"}, -- How will I do this?
		{"@conversation/corellia_imperial_trainer_2:s_c8516ab0", "why_capture"}, -- Why do we need them captured?
		{"@conversation/corellia_imperial_trainer_2:s_1d1f03a8", "opening_accept"}, -- I am ready to take off.
	}
}
prisk_convo_template:addScreen(prisk_convo_crew)

prisk_convo_why_capture = ConvoScreen:new {
	id = "why_capture",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_4ea4b48d", -- Black Epsilon does not wish the Rebels to have any local allies here.  We will use the ship, properly scuttled, to implicate foul play at the hands of the Rebels.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_trainer_2:s_83c3790d", "how"}, -- How will I do this?
		{"@conversation/corellia_imperial_trainer_2:s_c8516ab0", "why_capture"}, -- Why do we need them captured?
		{"@conversation/corellia_imperial_trainer_2:s_1d1f03a8", "opening_accept"}, -- I am ready to take off.
	}
}
prisk_convo_template:addScreen(prisk_convo_why_capture)

prisk_convo_opening_accept = ConvoScreen:new {
	id = "opening_accept",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_38d28ac2", -- Stay focused.  The fallback plan is to destroy this freighter outright if your assault fails.  We do not have any craft available for a rescue, so don't expect one.
	stopConversation = "true",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_opening_accept)

prisk_convo_see_hakassha = ConvoScreen:new {
	id = "see_hakassha",
	leftDialog = "@conversation/corellia_imperial_trainer_2:s_e71f0d40", -- You would hate to ruin my mood by speaking with me friend, so why don't we end our conversation here.  If you have Imperial interests at heart, perhaps it is Hakasha Sireen you are seeking.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {}
}
prisk_convo_template:addScreen(prisk_convo_see_hakassha)

addConversationTemplate("prisk_convo_template", prisk_convo_template)
