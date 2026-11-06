-- Lt. Akal Colzet (Storm Squadron tier 1) conversation; ported from SWG-Source tatooine_imperial_trainer_1.java with the pre-NGE client lines (feature storm-tier1-akal-colzet). Handler: akalColzetConvoHandler.
akal_colzet_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "akalColzetConvoHandler",
	screens = {}
}

akal_colzet_convo_first_mission_help = ConvoScreen:new {
	id = "first_mission_help",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_c19ed115", -- You've got your assignment, and the control device for your ship in your datapad.  Go to the Starport and access the terminal to launch into space.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_first_mission_help)

akal_colzet_convo_no_jtl = ConvoScreen:new {
	id = "no_jtl",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6138854f", -- Do you have business with the Imperial Navy? No? Then I suggest that you come back another time.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_no_jtl)

akal_colzet_convo_lost_ship = ConvoScreen:new {
	id = "lost_ship",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_e106780b", -- Good to see you, Pilot.
	stopConversation = "false",
	animation = "greet",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7d477c70", "lost_ship_confirm"}, -- Sir...I...ah...lost my ship control device.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_lost_ship)

akal_colzet_convo_lost_ship_confirm = ConvoScreen:new {
	id = "lost_ship_confirm",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_bc695163", -- I can clear you for a new TIE Fighter, but only the basic model. Are you sure you want a new control device?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_8efde2ae", "lost_ship_granted"}, -- Yes, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_169df3bb", "lost_ship_declined"}, -- Never mind.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_lost_ship_confirm)

akal_colzet_convo_lost_ship_granted = ConvoScreen:new {
	id = "lost_ship_granted",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_94131047", -- Don't lose it this time.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_lost_ship_granted)

akal_colzet_convo_lost_ship_declined = ConvoScreen:new {
	id = "lost_ship_declined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_e1da893f", -- I'm fairly busy, so I'll have to talk to you later.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_lost_ship_declined)

akal_colzet_convo_neutral_pilot = ConvoScreen:new {
	id = "neutral_pilot",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7537c07c", -- I think I recognize you. You're on a wanted list I think...
	stopConversation = "true",
	animation = "point_accusingly",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_neutral_pilot)

akal_colzet_convo_rebel_pilot = ConvoScreen:new {
	id = "rebel_pilot",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2d4337c5", -- I've seen your face! You're a known Rebel pilot! Guards, arrest this man!
	stopConversation = "true",
	animation = "threaten",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_rebel_pilot)

akal_colzet_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8c262163", -- Report back to me when you are finished with your current mission.  You can abort your mission if you want to start over.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_on_mission)

akal_colzet_convo_not_imperial = ConvoScreen:new {
	id = "not_imperial",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2844cc74", -- Pilot, you are a disgrace.  You have been assisting the Rebel Alliance against the Empire.  This will not be tolerated.  You are grounded until further notice!
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_not_imperial)

akal_colzet_convo_grounded = ConvoScreen:new {
	id = "grounded",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2844cc74", -- Pilot, you are a disgrace.  You have been assisting the Rebel Alliance against the Empire.  This will not be tolerated.  You are grounded until further notice!
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7090182", "grounded_standing"}, -- What?!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_grounded)

akal_colzet_convo_grounded_standing = ConvoScreen:new {
	id = "grounded_standing",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_49af5773", -- You heard me.  If you ever want to fly for the Imperial Navy again, you'd better improve your standing with the Empire!
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_fcf4d778", "grounded_ground_pounders"}, -- How?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_grounded_standing)

akal_colzet_convo_grounded_ground_pounders = ConvoScreen:new {
	id = "grounded_ground_pounders",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_eb1ee299", -- Why don't you run missions for the ground-pounders until you've got better faction standing?  Until then, don't talk to me.  You brought this on yourself.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_grounded_ground_pounders)

akal_colzet_convo_non_member = ConvoScreen:new {
	id = "non_member",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_966ca13e", -- Ah, yes. You're in my files as a member of the Imperial Navy, but you're not assigned to my roster. What can I do for you?
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_4854758d", "non_member_no_missions"}, -- I would like to request a mission.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_non_member)

akal_colzet_convo_non_member_duty_offer = ConvoScreen:new {
	id = "non_member_duty_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a742819b", -- I've got most of the critical assignments covered right now, but I do have some elective duty missions if you are interested.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_e814cf37", "duty_menu"}, -- I would like a duty mission.
		{"@conversation/tatooine_imperial_trainer_1:s_e87a40f8", "non_member_declined"}, -- I'd rather not right now.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_non_member_duty_offer)

akal_colzet_convo_non_member_no_missions = ConvoScreen:new {
	id = "non_member_no_missions",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1cccf249", -- You are not a pilot in my squadron, and therefore unable to fly any of the missions I have. Go back to your unit and speak with your commanding officer.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_non_member_no_missions)

akal_colzet_convo_non_member_declined = ConvoScreen:new {
	id = "non_member_declined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a0d8ac32", -- Then be on your way. Dismissed.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_non_member_declined)

akal_colzet_convo_series_complete = ConvoScreen:new {
	id = "series_complete",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2e935a2c", -- Good to see you again, pilot. I hope your new assignment is going well. The voluntary conscription program has been quite successful. If there is anything I can help you with, let me know. Although you are overqualified, I can offer you some basic missions and duties. I can also train you in simple skills, in case you need a refresher.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_88241861", "form_reissued"}, -- I lost my Application of Transfer.
		{"@conversation/tatooine_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/tatooine_imperial_trainer_1:s_943c7ba6", "series_no_training"}, -- I'd like training.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_series_complete)

akal_colzet_convo_form_reissued = ConvoScreen:new {
	id = "form_reissued",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3f904297", -- Lost it? How do you lose one of those massive things? Alright, I'll imprint you a new one, but don't lose it. They only give me a limited allotment of these disks every week.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "form_good_luck"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_form_reissued)

akal_colzet_convo_form_good_luck = ConvoScreen:new {
	id = "form_good_luck",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_aceff31e", -- Good luck, pilot.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_form_good_luck)

akal_colzet_convo_form_inventory_full = ConvoScreen:new {
	id = "form_inventory_full",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_506aa7cf", -- Sorry, pilot, but you are carrying way too much stuff. I hope you don't take all of that into your ship with you. Drop some of it and come back for your form.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_form_inventory_full)

akal_colzet_convo_series_no_training = ConvoScreen:new {
	id = "series_no_training",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_34bc5f5e", -- You don't have the experience to apply to training.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_series_no_training)

akal_colzet_convo_tier_done = ConvoScreen:new {
	id = "tier_done",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d25495b9", -- Pilot, I am singularly impressed. You have mastered the fundamentals of your profession and have performed beyond expectation and all without formal Imperial Naval Flight & Command training. I think it's time for a promotion.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_3f6a8711", "promotion"}, -- Thank you, sir. I do my best.
		{"@conversation/tatooine_imperial_trainer_1:s_31967d85", "promotion_handler"}, -- Does this mean I get a new handler? I'm sick of working with you.
		{"@conversation/tatooine_imperial_trainer_1:s_24890a54", "promotion_overdue"}, -- This recognition should have happened a long time ago.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_tier_done)

akal_colzet_convo_promotion = ConvoScreen:new {
	id = "promotion",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_fa0ab23c", -- By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby commend you and bestow upon you the rank of Pilot Officer. Congratulations, Pilot Officer.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_304d169e", "promotion_honored"}, -- I am honored, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion)

akal_colzet_convo_promotion_honored = ConvoScreen:new {
	id = "promotion_honored",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6e62e955", -- You should be. An officer rank is usually only given to those who graduate Naval Command School. All combat pilots in the Imperial Navy hold at least the rank of Pilot Officer. The Empire has recognized your ability and has seen fit to elevate you to the lowest rank of the command echelon.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_565cc8ba", "promotion_serve"}, -- I live only to serve the Emperor, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_honored)

akal_colzet_convo_promotion_serve = ConvoScreen:new {
	id = "promotion_serve",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_dd40f86b", -- As do we all. Now that you have achieved an official command rank, I am no longer your commanding officer. Although it pains me to lose such a fine pilot, you have been reassigned pending approval of transfer.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_de76730a", "new_assignment"}, -- Where is my new assignment?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_serve)

akal_colzet_convo_promotion_handler = ConvoScreen:new {
	id = "promotion_handler",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_14aa29c", -- I haven't exactly enjoyed your company, either. Yes, it does mean you will have a new commanding officer. I'll skip the formality. You are now a Pilot Officer. Personally, I think it's a mistake, but Naval Command likes the results you've shown.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_b8ca7ab0", "promotion_reassigned"}, -- As long as you keep paying, I'll keep delivering.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_handler)

akal_colzet_convo_promotion_reassigned = ConvoScreen:new {
	id = "promotion_reassigned",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8fc58e91", -- The Empire has recognized your ability and has seen fit to elevate you to the lowest rank of the Naval command echelon. Don't abuse that trust. Commander Oberhaur of the ISD Accuser will handle your assignments from this point on.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_9bcd2229", "new_assignment"}, -- What kind of assignment is this?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_reassigned)

akal_colzet_convo_promotion_overdue = ConvoScreen:new {
	id = "promotion_overdue",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_30a48366", -- Perhaps. By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby commend you and bestow upon you the rank of Pilot Officer.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c0c8fe59", "promotion_killed"}, -- One day the Emperor himself will recognize my strength.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_overdue)

akal_colzet_convo_promotion_killed = ConvoScreen:new {
	id = "promotion_killed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_df69a100", -- If you don't get yourself killed first. Now that you have achieved an official command rank, I am no longer your commanding officer. You have been reassigned. Commander Oberhaur of the ISD Accuser will handle your assignments from this point on.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_83fc71cf", "new_assignment"}, -- What kind of assignment is it?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_promotion_killed)

akal_colzet_convo_new_assignment = ConvoScreen:new {
	id = "new_assignment",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_9465e2c7", -- You must have impressed someone, pilot. You are being posted for consideration to join Storm Squadron. The squadron is a special operations wing based here in the Tatooine system. Their C.O. is a man named Commander Jhon Oberhaur.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_15a6458f", "oberhaur_info"}, -- What is Oberhaur like?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_new_assignment)

akal_colzet_convo_oberhaur_info = ConvoScreen:new {
	id = "oberhaur_info",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_93b4f46e", -- Cdr. Oberhaur is friendly, but a tough man. He'll work you hard. You aren't officially a member of Storm Squadron yet. You need to impress Cdr. Oberhaur during the application phase to be accepted. You'll need to take this Authorization of Transfer to him. He's currently stationed here in Bestine. You can find his office over in the capital building. Sign this form and give it to him to start.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_163d48b6", "oberhaur_good_luck"}, -- (Take the form.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_oberhaur_info)

akal_colzet_convo_oberhaur_good_luck = ConvoScreen:new {
	id = "oberhaur_good_luck",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_17519607", -- Good luck, pilot. Stay sharp.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_5c5b19e2", "dismissed"}, -- Yes, Sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_oberhaur_good_luck)

akal_colzet_convo_dismissed = ConvoScreen:new {
	id = "dismissed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4d41f7fe", -- Dismissed.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_dismissed)

akal_colzet_convo_training_offer = ConvoScreen:new {
	id = "training_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_c2ef0b45", -- Pilot. You've managed to achieve some level of success, but you are still relatively inexperienced. I have been authorized to give you special instruction in an area of your choosing.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_19ff301f", "training_menu"}, -- What kind of training?
		{"@conversation/tatooine_imperial_trainer_1:s_bf64734d", "training_declined"}, -- I don't want to learn anything right now.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_training_offer)

akal_colzet_convo_training_declined = ConvoScreen:new {
	id = "training_declined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_fd4fe208", -- That is your choice, but you may not get this chance again.  I suggest that you take it while you can.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_training_declined)

akal_colzet_convo_training_menu = ConvoScreen:new {
	id = "training_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_bb6caa54", -- You can learn about Imperial technology, weapons, standard Imperial training, or astromech management.
	stopConversation = "false",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_training_menu)

akal_colzet_convo_train_starships = ConvoScreen:new {
	id = "train_starships",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_438b2349", -- So far you've been flying a basic TIE.  The normal TIE is quite a bit more complicated than that.  For one thing, you'll find that you can install better components on it... better weapons, better armor, and so on.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c6d9f61", "trained_starships"}, -- I'd like to study that in detail.
		{"@conversation/tatooine_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_train_starships)

akal_colzet_convo_train_weapons = ConvoScreen:new {
	id = "train_weapons",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a4c65e0b", -- With just a little more training, you could be using better weapons.  Missiles can really help to swing the battle your way, and this skill can allow you to use some good ones.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c6d9f61", "trained_weapons"}, -- I'd like to study that in detail.
		{"@conversation/tatooine_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_train_weapons)

akal_colzet_convo_train_procedures = ConvoScreen:new {
	id = "train_procedures",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2e48b5f1", -- It's no secret that Imperial pilots utilize some of the best starfighter tactics the galaxy has ever seen.  I can get you started on the road to mastering these uniquely Imperial procedures.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c6d9f61", "trained_procedures"}, -- I'd like to study that in detail.
		{"@conversation/tatooine_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_train_procedures)

akal_colzet_convo_train_droid = ConvoScreen:new {
	id = "train_droid",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_df76b2e8", -- Imperial astromech functionality is typically built into a rugged navicomputer, rather than those annoying sorts of astromech units that the Rebel Alliance relies on.  I can teach you how to utilize some of the basic functionality of the droid interface to normalize your shields, overload your weapons, and that sort of thing.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c6d9f61", "trained_droid"}, -- I'd like to study that in detail.
		{"@conversation/tatooine_imperial_trainer_1:s_786f3cf7", "training_menu"}, -- I want to study something else.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_train_droid)

akal_colzet_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_trained_starships)

akal_colzet_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_trained_weapons)

akal_colzet_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_trained_procedures)

akal_colzet_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c8aca1b", -- Good choice.  Report back when you are ready for an assignment.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_trained_droid)

akal_colzet_convo_training_never_mind = ConvoScreen:new {
	id = "training_never_mind",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d825aeb0", -- Very well, good day Pilot.
	stopConversation = "true",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_training_never_mind)

akal_colzet_convo_duty_missions = ConvoScreen:new {
	id = "duty_missions",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d8487693", -- Pilot. I don't have any specific work for you at this time. You can now select your preferred operation from a list of general duties. Or, if you have enough experience, pursue training.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_6a128385", "duty_explained"}, -- What is a duty?
		{"@conversation/tatooine_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/tatooine_imperial_trainer_1:s_3b3aabc1", "no_training_xp"}, -- I'd like training, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_cdbce743", "enlist_ground"}, -- I want to enlist in the ground forces.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_missions)

akal_colzet_convo_duty_explained = ConvoScreen:new {
	id = "duty_explained",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d25c510b", -- Duty missions are open ended assignments. They end when you choose to end them. For example, if I assign you the task of hunting pirates, you can hunt as many pirates as you want. You can end the duty any time from the mission entry in your datapad. Perform duties to earn pay and build experience. Once you've received enough experience, I can instruct you on various aspects of the pilot's combat role.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_2d5d4bf0", "duty_menu"}, -- I'm interested in a duty.
		{"@conversation/tatooine_imperial_trainer_1:s_1091c96a", "duty_done_for_now"}, -- I'm done for now.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_explained)

akal_colzet_convo_duty_done_for_now = ConvoScreen:new {
	id = "duty_done_for_now",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_88ffee3a", -- Report back to me when you are ready for some work.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_done_for_now)

akal_colzet_convo_no_training_xp = ConvoScreen:new {
	id = "no_training_xp",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8e66d267", -- You don't have the experience for training, yet. Perform some more duties.
	stopConversation = "true",
	animation = "shake_head_no",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_no_training_xp)

akal_colzet_convo_enlist_ground = ConvoScreen:new {
	id = "enlist_ground",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2879b9e3", -- Indeed.  You didn't seem the type.  You realize that enlisting with the ground forces - even as a covert operative - could open you to attack from Rebels when you least expect it?
	stopConversation = "false",
	animation = "cough_polite",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_f195b141", "enlist_recruiter"}, -- Yes, I know
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_enlist_ground)

akal_colzet_convo_enlist_recruiter = ConvoScreen:new {
	id = "enlist_recruiter",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a7f76b6d", -- We'll see about that.  If you want to enlist then speak to an Imperial Recruiter.  He will put your name on the roster.  I'm certain the Empire can put you to as good use on the ground, as it does in space.
	stopConversation = "true",
	animation = "explain",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_enlist_recruiter)

akal_colzet_convo_duty_menu = ConvoScreen:new {
	id = "duty_menu",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_518959d2", -- Good, I have a lot of work for you. Pirate activity in the area is still fairly high. There are plenty of pirates to hunt or you could help escort transports moving supplies.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_259013cd", "destroy_duty"}, -- [Destroy Duty] I'm interested in hunting pirates.
		{"@conversation/tatooine_imperial_trainer_1:s_79ab4bbe", "escort_duty"}, -- [Escort Duty] I'm interested in escorting transports.
		{"@conversation/tatooine_imperial_trainer_1:s_5ebce168", "duty_later"}, -- Actually, I'd like to do this later.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_menu)

akal_colzet_convo_destroy_duty = ConvoScreen:new {
	id = "destroy_duty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_abffcfd7", -- Pirate activity is still high enough that we need combat capable pilots on active duty locating and eliminating them. You have free reign to use lethal force against any commerce raiders you locate around Tatooine. The Empire will pay a bounty on every one you destroy. Good luck.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a490d2c6", "duty_accepted"}, -- Alright.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_destroy_duty)

akal_colzet_convo_escort_duty = ConvoScreen:new {
	id = "escort_duty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_37910d75", -- With the recent increase in pirate activity, our supply transports are at risk. The Empire would like to assign at least one TIE pilot to every transport operating in the Tatooine region. You will be paid for every successful escort operation you complete.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a490d2c6", "duty_accepted"}, -- Alright.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_escort_duty)

akal_colzet_convo_duty_later = ConvoScreen:new {
	id = "duty_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_101a6629", -- Report back to me when you are ready.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_later)

akal_colzet_convo_duty_accepted = ConvoScreen:new {
	id = "duty_accepted",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_ee63dfa9", -- Report back to me when you would like a new duty or mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_duty_accepted)

akal_colzet_convo_recruitment = ConvoScreen:new {
	id = "recruitment",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b7c14c03", -- Good morning. My name is Lieutenant Akal Colzet, Imperial Navy. I've been assigned to Tatooine to recruit local volunteer pilots into service. Are you interested in learning about the Imperial Navy?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_11fcdd9f", "recruit_navy"}, -- I'm interested in hearing about the Imperial Navy, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_42bfca2f", "recruit_pay"}, -- If you've got work that pays, I'll listen.
		{"@conversation/tatooine_imperial_trainer_1:s_5e6be58d", "recruit_stare"}, -- (Nod silently, but stare intensely.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruitment)

akal_colzet_convo_recruit_navy = ConvoScreen:new {
	id = "recruit_navy",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4608dfe8", -- The Imperial Navy is the finest fleet in the galaxy. The brave and the bold. We command the Empire's starships and fighters. We are the hammer of Imperial justice. All members of the Imperial Navy are officers, however we are now starting to recruit non-officer pilots for limited support duty.
	stopConversation = "false",
	animation = "conversation_1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_388cfea9", "recruit_volunteers"}, -- The Empire is recruiting volunteer pilots?
		{"@conversation/tatooine_imperial_trainer_1:s_c124ad4f", "recruit_sure"}, -- Sir, I can fly. It would be an honor to fly with the Imperial Navy.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_navy)

akal_colzet_convo_recruit_volunteers = ConvoScreen:new {
	id = "recruit_volunteers",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_72ed61c", -- Yes, volunteers. Under normal circumstances it takes years of formal education to become a flight officer in the Imperial Navy. Recently, Rebel opposition has become more direct. We want to recruit new pilots for support duty, freeing up combat pilots for the front lines. Are you a pilot?
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_22564d44", "recruit_sure"}, -- Sir, I can fly. It would be an honor to serve the Empire.
		{"@conversation/tatooine_imperial_trainer_1:s_37eb1d12", "recruit_declined"}, -- I'd rather not sign up right now, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_volunteers)

akal_colzet_convo_recruit_sure = ConvoScreen:new {
	id = "recruit_sure",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_ee657693", -- Service in the Imperial Navy isn't something to be taken lightly. Your training will be strict, you'll be expected to follow orders, and of course, any association with the Rebellion would be punished severely. Are you sure you want to sign up?
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_68c831e7", "recruit_sworn"}, -- Yes. I want to be in the Imperial Navy.
		{"@conversation/tatooine_imperial_trainer_1:s_37eb1d12", "recruit_declined"}, -- I'd rather not sign up right now, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_sure)

akal_colzet_convo_recruit_declined = ConvoScreen:new {
	id = "recruit_declined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_fcb1448e", -- I hope you reconsider. You have the right kind of attitude and character. If you decide you'd like to fly for us, you know where to find me. Good day, citizen.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_declined)

akal_colzet_convo_recruit_sworn = ConvoScreen:new {
	id = "recruit_sworn",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2fe328e", -- By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby conscript you to service with the non-officer flight rank of Pilot Initiate. May you serve the Empire dutifully. Welcome to the Imperial Navy.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "recruit_ship_granted"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_sworn)

akal_colzet_convo_recruit_ship_granted = ConvoScreen:new {
	id = "recruit_ship_granted",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1d0e7364", -- I'm transferring a ship authorization and control device to your datapad. You'll need this to use your TIE Fighter. Should you lose your control device and access to your ship, you can apply for a new one at any time. Unfortunately, I'm only authorized to supply you with access to our low end TIE technology.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "first_assignment"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_ship_granted)

akal_colzet_convo_first_assignment = ConvoScreen:new {
	id = "first_assignment",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b3408be1", -- Are you ready for your first assignment?
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_aaa6ec13", "mission1_salute"}, -- (Salute) Sir!
		{"@conversation/tatooine_imperial_trainer_1:s_2a1015e6", "mission1_no_salute"}, -- (Don't salute.)
		{"@conversation/tatooine_imperial_trainer_1:s_8cd3467e", "mission1_emperor"}, -- (Salute) For the Emperor.
		{"@conversation/tatooine_imperial_trainer_1:s_f43f3569", "mission1_prove"}, -- I'm ready for training
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_first_assignment)

akal_colzet_convo_recruit_pay = ConvoScreen:new {
	id = "recruit_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_266d5a8d", -- I'm not sure that's the right kind of motivation, citizen. The Imperial Navy is the finest fleet in the galaxy. We command the Empire's starships and fighters. We are the hammer of Imperial justice. The Navy wants patriots who will fight for the security of the Empire.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_9ef7bea1", "recruit_patriot"}, -- Motivation doesn't matter if the job gets done.
		{"@conversation/tatooine_imperial_trainer_1:s_8df7dba2", "recruit_scum"}, -- I can fly and I can shoot, but I don't come cheap.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_pay)

akal_colzet_convo_recruit_patriot = ConvoScreen:new {
	id = "recruit_patriot",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_84cc9ca1", -- The Imperial Navy prides itself on the character and loyalty of its officers. I don't think you understand what it means to be a patriot. The lines are drawn, citizen. You are either with us or you are a Rebel. There is no neutral ground.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a4622f42", "recruit_scum"}, -- I don't care about your civil war. I'm just looking for work.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_patriot)

akal_colzet_convo_recruit_scum = ConvoScreen:new {
	id = "recruit_scum",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d422a73d", -- Your attitude is poor and I can tell by your dress that you are nothing more than petty scum. I don't like you, but then I suppose that I don't have to like you. I need to hire volunteers for limited military service. If you really can fly and shoot, we might have something for you.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_3d5b4720", "recruit_outsource"}, -- Why would the Imperial Navy need to...outsource?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_scum)

akal_colzet_convo_recruit_outsource = ConvoScreen:new {
	id = "recruit_outsource",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6942663f", -- Recently, Rebel opposition has become more direct. We want to recruit new pilots for support duty, freeing up combat pilots for the front lines. Under normal circumstances it takes years of formal education to become a flight officer in the Imperial Navy.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_5c4e4259", "recruit_pay_sure"}, -- Whatever. Like I said before, just name the target and the price.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_outsource)

akal_colzet_convo_recruit_pay_sure = ConvoScreen:new {
	id = "recruit_pay_sure",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6705894e", -- Service in the Imperial Navy isn't to be taken lightly. You'll be expected to follow orders and any association with the Rebellion would be punished severely.  Are you sure you want to sign up? You aren't exactly Imperial Pilot quality.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_e92da88", "recruit_sworn_pay"}, -- Sure, sign me up. I like making you squirm.
		{"@conversation/tatooine_imperial_trainer_1:s_65dcd253", "recruit_thrown_out"}, -- I'd rather suck plasma than work for you.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_pay_sure)

akal_colzet_convo_recruit_thrown_out = ConvoScreen:new {
	id = "recruit_thrown_out",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_154024b0", -- Get out of my office, trash! Guards, throw this scum out!
	stopConversation = "true",
	animation = "gesticulate_wildly",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_thrown_out)

akal_colzet_convo_recruit_sworn_pay = ConvoScreen:new {
	id = "recruit_sworn_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3ab04e84", -- As much as it pains me to say it, I hereby conscript you to service with the non-officer flight rank of Pilot Initiate. May you serve the Empire dutifully. Come back when you're ready for your 'job.'
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_860c425d", "recruit_ship_granted_bust"}, -- Great, where's my ship?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_sworn_pay)

akal_colzet_convo_recruit_ship_granted_bust = ConvoScreen:new {
	id = "recruit_ship_granted_bust",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1d0e7364", -- I'm transferring a ship authorization and control device to your datapad. You'll need this to use your TIE Fighter. Should you lose your control device and access to your ship, you can apply for a new one at any time. Unfortunately, I'm only authorized to supply you with access to our low end TIE technology.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7796b57c", "first_assignment"}, -- Great, I can't wait to try this baby out.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_ship_granted_bust)

akal_colzet_convo_recruit_stare = ConvoScreen:new {
	id = "recruit_stare",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d90e49c9", -- Ah, yes, well, the Imperial Navy is the finest fleet in the galaxy. We command the Empire's starships and fighters. We are the hammer of Imperial justice. All members of the Imperial Navy are officers, however we are now starting to recruit non-officer pilots for limited support duty.
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_13a199af", "recruit_greatest"}, -- Why recruit volunteers? Is not the strength of the Emperor's Navy unmatched?
		{"@conversation/tatooine_imperial_trainer_1:s_cbfb3200", "recruit_doctrine"}, -- Only the will of the Emperor delivers true justice...
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_stare)

akal_colzet_convo_recruit_greatest = ConvoScreen:new {
	id = "recruit_greatest",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3988f447", -- We are the greatest fleet in the galaxy, surmounting even the warships of the old Republic. Nonetheless, Rebel opposition has become more direct. We want to recruit new pilots for support duty, freeing up combat pilots for the front lines. Are you a pilot?
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_bc1c993d", "recruit_honored"}, -- I am. I would be honored to hunt the enemies of the Empire.
		{"@conversation/tatooine_imperial_trainer_1:s_b737f77e", "recruit_other_things"}, -- I have other things to attend to, good day.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_greatest)

akal_colzet_convo_recruit_other_things = ConvoScreen:new {
	id = "recruit_other_things",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_378987b0", -- Let me know if you decide you want to work with us.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_other_things)

akal_colzet_convo_recruit_doctrine = ConvoScreen:new {
	id = "recruit_doctrine",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_bc7382d4", -- 'We are but a tool to achieve that end.' I, too, know the text of the Imperial Doctrine. It's an element of core officer training. Although many members of the Imperial Navy are adherents to the doctrine, we are ultimately a military organization. Politics and theology are the realm of the bureaucrats.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_5cd3c77", "recruit_faith"}, -- There are those who believe the officers lack faith.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_doctrine)

akal_colzet_convo_recruit_faith = ConvoScreen:new {
	id = "recruit_faith",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_64b01ff", -- That may be, but they haven't stood on the command deck of an Imperial Star Destroyer while facing down a squadron of enemy hostiles. Sir, I have no time for the Imperial Inquisition. My record shows that I am a patriot.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_21309acb", "recruit_no_inquisitor"}, -- I'm no Inquisitor. I merely seek the will of the Emperor.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_faith)

akal_colzet_convo_recruit_no_inquisitor = ConvoScreen:new {
	id = "recruit_no_inquisitor",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8fc0b08b", -- You won't make many friends in the Imperial Navy if you question the faith of everyone you meet.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c3e56b53", "recruit_busy"}, -- Perhaps.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_no_inquisitor)

akal_colzet_convo_recruit_busy = ConvoScreen:new {
	id = "recruit_busy",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_703a1e55", -- Now, do you have further business here? I am quite busy.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_13a199af", "recruit_greatest"}, -- Why recruit volunteers? Is not the strength of the Emperor's Navy unmatched?
		{"@conversation/tatooine_imperial_trainer_1:s_eee17bb3", "recruit_honored"}, -- I seek to serve the Empire.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_busy)

akal_colzet_convo_recruit_honored = ConvoScreen:new {
	id = "recruit_honored",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a6574c9a", -- Service in the Imperial Navy isn't to be taken lightly.  You'll be expected to follow orders and any association with the Rebellion would be punished severely. Are you sure you want to sign up?
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7611fee0", "recruit_sworn_will"}, -- It is the Emperor's will.
		{"@conversation/tatooine_imperial_trainer_1:s_5c709097", "recruit_not_will"}, -- It is not the Emperor's will.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_honored)

akal_colzet_convo_recruit_not_will = ConvoScreen:new {
	id = "recruit_not_will",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6cb86d0c", -- Ah...yes. Good day then.
	stopConversation = "true",
	animation = "goodbye",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_not_will)

akal_colzet_convo_recruit_sworn_will = ConvoScreen:new {
	id = "recruit_sworn_will",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5070b6e", -- Very good. By the powers vested in me by the Imperial Naval Command, under the ever watchful eye of the Emperor, I hereby conscript you to service with the non-officer flight rank of Pilot Initiate. May you serve the Empire dutifully. Welcome to the Imperial Navy.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_670201ae", "recruit_ship_granted"}, -- I need a ship.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_recruit_sworn_will)

akal_colzet_convo_mission1_offer = ConvoScreen:new {
	id = "mission1_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_c16743ff", -- Service Pilot Initiate stand at attention!
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_aaa6ec13", "mission1_salute"}, -- (Salute) Sir!
		{"@conversation/tatooine_imperial_trainer_1:s_2a1015e6", "mission1_no_salute"}, -- (Don't salute.)
		{"@conversation/tatooine_imperial_trainer_1:s_8cd3467e", "mission1_emperor"}, -- (Salute) For the Emperor.
		{"@conversation/tatooine_imperial_trainer_1:s_f43f3569", "mission1_prove"}, -- I'm ready for training
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_offer)

akal_colzet_convo_mission1_prove = ConvoScreen:new {
	id = "mission1_prove",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1a100286", -- I think you need to prove you're worhty first, don't you?  Now stand at attention!
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_aaa6ec13", "mission1_salute"}, -- (Salute) Sir!
		{"@conversation/tatooine_imperial_trainer_1:s_2a1015e6", "mission1_no_salute"}, -- (Don't salute.)
		{"@conversation/tatooine_imperial_trainer_1:s_8cd3467e", "mission1_emperor"}, -- (Salute) For the Emperor.
		{"@conversation/tatooine_imperial_trainer_1:s_f43f3569", "mission1_prove"}, -- I'm ready for training
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_prove)

akal_colzet_convo_mission1_salute = ConvoScreen:new {
	id = "mission1_salute",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_431ac3d4", -- Very good. How may I help you, Initiate?
	stopConversation = "false",
	animation = "listen",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_16244233", "mission1_overstep"}, -- I'm ready for a mission, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_salute)

akal_colzet_convo_mission1_overstep = ConvoScreen:new {
	id = "mission1_overstep",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_fd8bce2a", -- A mission, pilot? Don't overstep your station. You're a voluntary conscript, not a combat pilot. If you're lucky, the Empire might one day see fit to post you to combat duty.
	stopConversation = "false",
	animation = "stop",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a8c82b1c", "mission1_pcr"}, -- Sir, yes sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_overstep)

akal_colzet_convo_mission1_pcr = ConvoScreen:new {
	id = "mission1_pcr",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_9a809034", -- As it stands, I do have an assignment for you. As you know, ships travel to and from Bestine every day along the Primary Commerce Route. Commercial traffic to Bestine is limited to the route, so we can scan each ship for illegal cargo. I want you to perform a circuit patrol of the Bestine PCR.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_83d1f7de", "mission1_accept"}, -- Understood, sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_pcr)

akal_colzet_convo_mission1_accept = ConvoScreen:new {
	id = "mission1_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3b510c1a", -- The purpose of this patrol assignment isn't to add any additional security to the Commerce Route. I highly doubt you would be effective in a combat situation. This is to assess your ability to pilot a ship and follow basic instructions. I've transferred the patrol route to your datapad. You are to fly to each point in the patrol route and then report back to me upon completion. Is this clear, Pilot Initiate?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a3b6d1bc", "mission1_good_luck"}, -- Clear as Duralian Tea, sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_accept)

akal_colzet_convo_mission1_good_luck = ConvoScreen:new {
	id = "mission1_good_luck",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_e95fb13d", -- If you perform capably, we will consider you for more dangerous assignments. Good luck.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_good_luck)

akal_colzet_convo_mission1_no_salute = ConvoScreen:new {
	id = "mission1_no_salute",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_46c8d76c", -- Show respect, Pilot! Outside you might be street scum, but in this office you are a pilot of the Imperial Navy. You will demonstrate the proper respect to your senior officer or you will demonstrate how to clean a sewage compactor. Is that clear?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d51ef84a", "mission1_tighten"}, -- (Give a mocking salute.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_no_salute)

akal_colzet_convo_mission1_tighten = ConvoScreen:new {
	id = "mission1_tighten",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_42be2dbc", -- Tighten it up, pilot! If you fly half as bad as you smell, you'll end up space scrap. Discipline is key to victory.
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_976cba8a", "mission1_job"}, -- (Sniff derisively.) You got a job for me or what?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_tighten)

akal_colzet_convo_mission1_job = ConvoScreen:new {
	id = "mission1_job",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_853678d0", -- I have an assignment for you. As you know, ships travel to and from Bestine every day along the Primary Commerce Route. Commercial traffic to Bestine is limited to the route, so we can scan each ship for illegal cargo. I want you to perform a circuit patrol of the Bestine PCR.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_780a9b6f", "mission1_accept_patrol_only"}, -- A patrol? I want something to shoot. Shooting always pays better.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_job)

akal_colzet_convo_mission1_accept_patrol_only = ConvoScreen:new {
	id = "mission1_accept_patrol_only",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_566cddb5", -- This is a patrol and only a patrol. The purpose of the assignment is to assess your ability to pilot a ship and follow basic instructions. I will be very surprised if you manage to succeed. I've transferred the patrol route to your datapad. You are to report back to me upon completion.  Is this clear, Pilot Initiate?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_78dbec92", "mission1_disgrace"}, -- Whatever. Sounds like easy money.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_accept_patrol_only)

akal_colzet_convo_mission1_disgrace = ConvoScreen:new {
	id = "mission1_disgrace",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_9a79a8e3", -- You are a disgrace. Get out of my sight, pilot. I don't want to see you again until you have results. If you perform capably, I might see about fitting you with a nice garbage escort detail.
	stopConversation = "true",
	animation = "pound_fist_palm",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_disgrace)

akal_colzet_convo_mission1_emperor = ConvoScreen:new {
	id = "mission1_emperor",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8a6a16c8", -- A simple 'sir' is fine, Initiate.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_83ea480b", "mission1_assignment"}, -- (Glare) Very well. Sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_emperor)

akal_colzet_convo_mission1_assignment = ConvoScreen:new {
	id = "mission1_assignment",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_853678d0", -- I have an assignment for you. As you know, ships travel to and from Bestine every day along the Primary Commerce Route. Commercial traffic to Bestine is limited to the route, so we can scan each ship for illegal cargo. I want you to perform a circuit patrol of the Bestine PCR.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_66ac46dc", "mission1_accept_warrior"}, -- A patrol is somewhat less than my ability. I prefer a warrior's assignment.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_assignment)

akal_colzet_convo_mission1_accept_warrior = ConvoScreen:new {
	id = "mission1_accept_warrior",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6a7d2af7", -- The purpose of the mission is to assess your ability to pilot a ship and follow basic instructions. If you pass, you will be considered for more dangerous assignments. You are to report back to me upon completion. Is this clear, Pilot Initiate?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_2562a051", "mission1_report"}, -- For the Emperor. Sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_accept_warrior)

akal_colzet_convo_mission1_report = ConvoScreen:new {
	id = "mission1_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_37979335", -- Report back to me when you are finished with the patrol.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_report)

akal_colzet_convo_mission1_failed = ConvoScreen:new {
	id = "mission1_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4e95ac78", -- Service Pilot Initiate, it is beyond my understanding how you could fail to achieve the objective of flying such a simple circuit patrol.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_16fc739e", "mission1_no_excuses"}, -- I...
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_failed)

akal_colzet_convo_mission1_no_excuses = ConvoScreen:new {
	id = "mission1_no_excuses",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_969498f6", -- I don't want to hear excuses. You haven't earned the right to give excuses. I want you to get back up there and finish that patrol.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_59c8db72", "mission1_retry"}, -- Sir, yes, sir!
		{"@conversation/tatooine_imperial_trainer_1:s_f91b288f", "mission1_retry_again"}, -- Very well. I'll fly it again.
		{"@conversation/tatooine_imperial_trainer_1:s_cb99174", "mission1_later"}, -- I have to study what went wrong.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_no_excuses)

akal_colzet_convo_mission1_retry = ConvoScreen:new {
	id = "mission1_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8d324b72", -- I've transferred the patrol coordinates to your datapad. Try harder this time, pilot.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_retry)

akal_colzet_convo_mission1_retry_again = ConvoScreen:new {
	id = "mission1_retry_again",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_94ed5057", -- I've transferred the patrol coordinates to your datapad.  Try not to fly into anything.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_retry_again)

akal_colzet_convo_mission1_later = ConvoScreen:new {
	id = "mission1_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_47691a6", -- Report to me when you are ready to attempt the patrol again.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_later)

akal_colzet_convo_mission1_won = ConvoScreen:new {
	id = "mission1_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_311a3b47", -- Stand at attention. Now, deliver your report on the Commerce Route patrol.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_ee91723f", "mission1_pirates"}, -- (Relate the facts on the commerce raider attack.)
		{"@conversation/tatooine_imperial_trainer_1:s_263baa57", "mission1_brag"}, -- (Brag about how you bagged several raiders.)
		{"@conversation/tatooine_imperial_trainer_1:s_d92fcf8d", "mission1_purged"}, -- (Relate how you purged several Imperial enemies.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_won)

akal_colzet_convo_mission1_pirates = ConvoScreen:new {
	id = "mission1_pirates",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d788f447", -- Pirates? Tatooine is known for criminal activity, but Bestine has always been strongly protected by Imperial justice. The recent Rebel insurgency must be giving the pirates a new spirit of confidence.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_b3753189", "mission1_pay_hazard"}, -- I was able to eliminate all of the pirates who attacked, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_pirates)

akal_colzet_convo_mission1_pay_hazard = ConvoScreen:new {
	id = "mission1_pay_hazard",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_ffd5b6f7", -- Hmm. You may have what it takes to be a combat pilot. On the other hand, you might have just gotten lucky. Either way, you fulfilled your duty. Here is your payment and an additional sum to compensate for hazards encountered.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "mission1_another_duty"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_pay_hazard)

akal_colzet_convo_mission1_another_duty = ConvoScreen:new {
	id = "mission1_another_duty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_82f901aa", -- Report back to me when you are ready for another duty.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_another_duty)

akal_colzet_convo_mission1_brag = ConvoScreen:new {
	id = "mission1_brag",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_d788f447", -- Pirates? Tatooine is known for criminal activity, but Bestine has always been strongly protected by Imperial justice. The recent Rebel insurgency must be giving the pirates a new spirit of confidence.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7baeb853", "mission1_bounty_hunter"}, -- I expect to be paid for each kill.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_brag)

akal_colzet_convo_mission1_bounty_hunter = ConvoScreen:new {
	id = "mission1_bounty_hunter",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_bc6327c0", -- I don't like working with bounty hunters like you. For a soldier, killing is a necessary evil. You seem to get some kind of thrill from it.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_23600775", "mission1_pay_yawn"}, -- (Yawn.) My payment?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_bounty_hunter)

akal_colzet_convo_mission1_pay_yawn = ConvoScreen:new {
	id = "mission1_pay_yawn",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4efae056", -- I'm surprised those pirates didn't turn your ship into a burning heap. Here's your payment. Report back to me when you're ready for another job.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_pay_yawn)

akal_colzet_convo_mission1_purged = ConvoScreen:new {
	id = "mission1_purged",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_dae6651c", -- Pirates?  Tatooine is known for criminal activity, but Bestine has always been strongly protected by Imperial justice.  The recent Rebel insurgency must be giving the pirates a new spirit of confidence.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7ef9666e", "mission1_pay_ego"}, -- They were no match for my skill.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_purged)

akal_colzet_convo_mission1_pay_ego = ConvoScreen:new {
	id = "mission1_pay_ego",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_264e2e43", -- Or your ego. Here is your payment for a successful mission and an additional sum to compensate for hazards encountered.
	stopConversation = "false",
	animation = "dismiss",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_39f8ff3b", "mission1_good_day"}, -- How else may I serve the Empire?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_pay_ego)

akal_colzet_convo_mission1_good_day = ConvoScreen:new {
	id = "mission1_good_day",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_9eb2b131", -- Return later and I'll have another mission prepared for you. Good day, Initiate.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission1_good_day)

akal_colzet_convo_mission2_offer = ConvoScreen:new {
	id = "mission2_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c4d87dd", -- Pilot Initiate. Your success in responding to pirate aggression during patrol has encouraged the local Naval Command. Despite their enthusiasm, I am still not convinced their faith in voluntary conscripts is justified. I am honestly surprised you survived.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a1088c08", "mission2_accept"}, -- Just a simple patrol, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_ae6ab110", "mission2_accept_spice"}, -- Glad I could bring a little spice to your life.
		{"@conversation/tatooine_imperial_trainer_1:s_d8a302bc", "mission2_accept_destined"}, -- All who oppose me are destined to fail.
		{"@conversation/tatooine_imperial_trainer_1:s_d9d4feec", "mission2_no_training"}, -- Will you train me, now?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_offer)

akal_colzet_convo_mission2_no_training = ConvoScreen:new {
	id = "mission2_no_training",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_94eb8fab", -- As I said, I'm not convinced their faith in 'volunteers' is justified, and I'm certainly not ready to trust you with more knowledge just yet, in spite of your recent victory.
	stopConversation = "false",
	animation = "shake_head_no",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a1088c08", "mission2_accept"}, -- Just a simple patrol, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_ae6ab110", "mission2_accept_spice"}, -- Glad I could bring a little spice to your life.
		{"@conversation/tatooine_imperial_trainer_1:s_d8a302bc", "mission2_accept_destined"}, -- All who oppose me are destined to fail.
		{"@conversation/tatooine_imperial_trainer_1:s_d9d4feec", "mission2_no_training"}, -- Will you train me, now?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_no_training)

akal_colzet_convo_mission2_accept = ConvoScreen:new {
	id = "mission2_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1144321a", -- Don't get too cocky, it might have just been luck. I've convinced the Naval Command to test your abilities further. We want to crush the pirates and demonstrate that Imperial resolve remains strong. I want you to get into space and destroy any Commerce Raiders you find. Your mission is to eliminate four of the pirates.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c08929f2", "mission2_spirit"}, -- Consider them dead, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_accept)

akal_colzet_convo_mission2_spirit = ConvoScreen:new {
	id = "mission2_spirit",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5c8922d8", -- That's the spirit, Pilot Initiate! You're starting to sound like an Imperial Pilot should. We have Intelligence reports on areas of high pirate activity that will be good places for you to start your search for the pirates. Report back to me upon completion of your task.
	stopConversation = "true",
	animation = "standing_raise_fist",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_spirit)

akal_colzet_convo_mission2_accept_spice = ConvoScreen:new {
	id = "mission2_accept_spice",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_c9d11db3", -- You might come to regret it. I've convinced the Naval Command to test your abilities further. We want to crush the pirates and demonstrate that Imperial resolve remains strong. I want you to get into space and destroy any Commerce Raiders you find. Your mission is to eliminate four of the pirates.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_3ca32099", "mission2_overconfidence"}, -- They're as good as dead.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_accept_spice)

akal_colzet_convo_mission2_overconfidence = ConvoScreen:new {
	id = "mission2_overconfidence",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_37ae364a", -- That overconfidence will get you killed some day. We have Intelligence reports on areas of high pirate activity that will be good places for you to start your search for the pirates. Report back to me upon completion of your task.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_overconfidence)

akal_colzet_convo_mission2_accept_destined = ConvoScreen:new {
	id = "mission2_accept_destined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b0b9044d", -- So it would seem. Naval Command would like to test your abilities further. We want to crush the pirates and demonstrate that Imperial resolve remains strong. I want you to get into space and destroy any Commerce Raiders you find. Your mission is to eliminate four of the pirates.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_25d6b961", "mission2_enthusiasm"}, -- Their destruction is inevitable.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_accept_destined)

akal_colzet_convo_mission2_enthusiasm = ConvoScreen:new {
	id = "mission2_enthusiasm",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6337731b", -- I suggest you reign in your enthusiasm. I need you to have a clear mind up there. Do not underestimate your enemy. We have Intelligence reports on areas of high pirate activity that will be good places for you to start your search for the pirates. Report back to me when you've completed the objective.
	stopConversation = "true",
	animation = "slow_down",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_enthusiasm)

akal_colzet_convo_mission2_failed = ConvoScreen:new {
	id = "mission2_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6971748f", -- So, it seems I was right after all. Your success with the pirates was just luck and the trust of Naval Command was misplaced. I suppose you could try hunting down the pirates again, but you would probably still fail.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_1768c7c4", "mission2_retry"}, -- Just a minor set back. Those pirates won't last long.
		{"@conversation/tatooine_imperial_trainer_1:s_19288eda", "mission2_rethink"}, -- I think I need to rethink things.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_failed)

akal_colzet_convo_mission2_retry = ConvoScreen:new {
	id = "mission2_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a934fd0c", -- Go ahead then, try again. The destruction of the pirates benefits the Empire's business in this region. Report back to me when your task is complete.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_retry)

akal_colzet_convo_mission2_rethink = ConvoScreen:new {
	id = "mission2_rethink",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3b1fee95", -- Report to me when you are ready to give it another try.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_rethink)

akal_colzet_convo_mission2_won = ConvoScreen:new {
	id = "mission2_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b9173bca", -- I've already received word of your success against Commerce Raiders in the region. It seems the Empire was not at error to place its trust in you.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_96c14c06", "mission2_pay_dutiful"}, -- Yes, sir. I overcame the enemy with ease.
		{"@conversation/tatooine_imperial_trainer_1:s_5f418636", "mission2_pay_calm"}, -- They were dead money. Now I want to be paid.
		{"@conversation/tatooine_imperial_trainer_1:s_838b6daf", "mission2_pay_patronizing"}, -- They died cursing my name.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_won)

akal_colzet_convo_mission2_pay_dutiful = ConvoScreen:new {
	id = "mission2_pay_dutiful",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_bb4e17d0", -- No doubt you did, as would be expected from any Imperial pilot. Here is your salary as well as a little extra. The Emperor rewards dutiful service. I've taken liberty of submitting your physical profile to the Commissions Office. Your spec TIE flight suit will be ready soon.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "mission2_success"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_pay_dutiful)

akal_colzet_convo_mission2_success = ConvoScreen:new {
	id = "mission2_success",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b9b88c88", -- I see success in your future, Initiate. You appear to be capable of things the average conscript is not. Report to me when you are ready for further duties.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_success)

akal_colzet_convo_mission2_pay_calm = ConvoScreen:new {
	id = "mission2_pay_calm",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_976ec302", -- Calm down, your payment has been arranged. I've also taken the liberty of submitting your physical profile to the Commissions Office. You stink and you aren't dressed for your position as an Imperial Pilot. A spec TIE pilot flightsuit will be ready for you soon.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a607dd0f", "mission2_wear_told"}, -- I wear what I please.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_pay_calm)

akal_colzet_convo_mission2_wear_told = ConvoScreen:new {
	id = "mission2_wear_told",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8c63d8cd", -- You'll wear what you are told to wear. Now get lost. I have other business to attend to. Let me know when you're ready for another job.
	stopConversation = "true",
	animation = "wave_finger_warning",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_wear_told)

akal_colzet_convo_mission2_pay_patronizing = ConvoScreen:new {
	id = "mission2_pay_patronizing",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_3060d15b", -- (Patronizing) The Emperor himself will take note of you, I'm sure. Here is your salary as well as a little extra. The Emperor rewards dutiful service.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d07b11b5", "mission2_ahem"}, -- (Glower at him, disapprovingly.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_pay_patronizing)

akal_colzet_convo_mission2_ahem = ConvoScreen:new {
	id = "mission2_ahem",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b3e4cc19", -- Ahem. You appear to be capable of things the average conscript is not. Report to me when you are ready for further duties.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission2_ahem)

akal_colzet_convo_mission3_offer = ConvoScreen:new {
	id = "mission3_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6b63ee3", -- Stand at attention, Pilot. Having shown skill in combat situations you are being elevated to an Outer Rim security detail. For the time being, I will handle your assignments, briefings, and deployment. You will operate as an independent agent until we determine a specific placement for you.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_6d8d3e00", "mission3_not_fail"}, -- I will not fail you, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_63380f34", "mission3_team"}, -- I've always been an independent agent. I work alone.
		{"@conversation/tatooine_imperial_trainer_1:s_da07fb7a", "mission3_specops"}, -- I would prefer a posting to Special Operations.
		{"@conversation/tatooine_imperial_trainer_1:s_f43f3569", "mission3_no_training"}, -- I'm ready for training
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_offer)

akal_colzet_convo_mission3_no_training = ConvoScreen:new {
	id = "mission3_no_training",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_323e4b0d", -- I will decide when you are ready for training, Pilot.  And right now I say you aren't.  Now, about your new role in the Outer Rim security detail...
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_6d8d3e00", "mission3_not_fail"}, -- I will not fail you, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_63380f34", "mission3_team"}, -- I've always been an independent agent. I work alone.
		{"@conversation/tatooine_imperial_trainer_1:s_da07fb7a", "mission3_specops"}, -- I would prefer a posting to Special Operations.
		{"@conversation/tatooine_imperial_trainer_1:s_f43f3569", "mission3_no_training"}, -- I'm ready for training
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_no_training)

akal_colzet_convo_mission3_not_fail = ConvoScreen:new {
	id = "mission3_not_fail",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_f1471b6a", -- As well you should not. You will be given assignments that, while small, are still critical to Imperial interests in the Outer Rim. The consequences of failure would be significant.  So, as you say, you will not fail.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_8efde2ae", "mission3_bestine"}, -- Yes, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_not_fail)

akal_colzet_convo_mission3_bestine = ConvoScreen:new {
	id = "mission3_bestine",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6988fd93", -- Now then, your mission. Bestine has become a key base location for Imperial Naval operations in the Outer Rim. Many ships and men are moved through this region on a daily basis. Ships and men consume supplies and uninterrupted delivery of supplies is critical to the integrity of base operations.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_60c81a4c", "mission3_accept"}, -- Absolutely, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_bestine)

akal_colzet_convo_mission3_accept = ConvoScreen:new {
	id = "mission3_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_726bd76b", -- Wing Epsilon Zeta, operating out of the garrisoned ISD Accuser, usually handles supply security operations.  Escort, patrol, and the like. They are overtaxed and have asked for additional support. Your job will be to fly a standard patrol sweep through the region.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_83d1f7de", "mission3_guard"}, -- Understood, sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_accept)

akal_colzet_convo_mission3_guard = ConvoScreen:new {
	id = "mission3_guard",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_c48451bf", -- I don't expect you will run into trouble, as many ships safely move through the region every day, but be on guard. If you do encounter something amiss, you have permission to respond as you see fit. This operational autonomy is contingent upon your continued success.  Screw up and you'll be kept on a short leash.
	stopConversation = "false",
	animation = "conversation_1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_16f8c58a", "mission3_excellent"}, -- I will not disappoint, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_guard)

akal_colzet_convo_mission3_excellent = ConvoScreen:new {
	id = "mission3_excellent",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5fdd32ea", -- Excellent. Deliver a report to me upon completion of the mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_excellent)

akal_colzet_convo_mission3_team = ConvoScreen:new {
	id = "mission3_team",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7fdc4805", -- As a member of this Navy you will be expected to work with the team when necessary. Your assignments, while small, are critical to Imperial interests in the Outer Rim. If I need you to work with others to achieve those goals, you will do so and you will like it. Is that clear?
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_627065f5", "mission3_insubordinate"}, -- I work alone and then I get paid.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_team)

akal_colzet_convo_mission3_insubordinate = ConvoScreen:new {
	id = "mission3_insubordinate",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_465b51a7", -- I am sick of this insubordinate, disrespectful attitude. Shape up or you'll find yourself in a detention block.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d7816410", "mission3_listen"}, -- Look, I've got people to pay. Do you have work for me or not?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_insubordinate)

akal_colzet_convo_mission3_listen = ConvoScreen:new {
	id = "mission3_listen",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7f6cd2e6", -- Listen up. Bestine has become a key base location for Imperial Naval operations in the Outer Rim. Many ships and men are moved through this region on a daily basis. Ships and men consume supplies and uninterrupted delivery of supplies is critical to the integrity of base operations.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_16c1201f", "mission3_accept_briefing"}, -- Ah, joy. A briefing.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_listen)

akal_colzet_convo_mission3_accept_briefing = ConvoScreen:new {
	id = "mission3_accept_briefing",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_726bd76b", -- Wing Epsilon Zeta, operating out of the garrisoned ISD Accuser, usually handles supply security operations.  Escort, patrol, and the like. They are overtaxed and have asked for additional support. Your job will be to fly a standard patrol sweep through the region.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_76de9d3f", "mission3_cold_guns"}, -- My talents lie in the direction of hunting men, not patrols.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_accept_briefing)

akal_colzet_convo_mission3_cold_guns = ConvoScreen:new {
	id = "mission3_cold_guns",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_aaac7e85", -- I don't expect you will need to shoot at anything. Let me be particularly clear: this is a patrol. Keep your guns cold unless you are fired upon first.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_78dbec92", "mission3_report"}, -- Whatever. Sounds like easy money.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_cold_guns)

akal_colzet_convo_mission3_report = ConvoScreen:new {
	id = "mission3_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_e4e336cc", -- Report to me upon completion of the mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_report)

akal_colzet_convo_mission3_specops = ConvoScreen:new {
	id = "mission3_specops",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5b34a8a8", -- In the Imperial Navy we don't pick our postings, they pick us. The Naval Command feels you make a good candidate for Security.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_f3852d77", "mission3_too_highly"}, -- They have underestimated my ability.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_specops)

akal_colzet_convo_mission3_too_highly = ConvoScreen:new {
	id = "mission3_too_highly",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a91015df", -- You certainly think highly of yourself. Too highly. Until you prove otherwise, you are at the lowest rung on the ladder. Tools do not select how they are used.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_b2995db3", "mission3_confined"}, -- (Growl at him.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_too_highly)

akal_colzet_convo_mission3_confined = ConvoScreen:new {
	id = "mission3_confined",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_561d4b08", -- I will have you confined if you cannot control yourself.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_84047858", "mission3_keep_quiet"}, -- (Glare at him, violently.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_confined)

akal_colzet_convo_mission3_keep_quiet = ConvoScreen:new {
	id = "mission3_keep_quiet",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_10675ec9", -- Keep quiet and listen. Bestine has become a key base location for Imperial Naval operations in the Outer Rim. Many ships and men are moved through this region on a daily basis. Ships and men consume supplies and uninterrupted delivery of supplies is critical to the integrity of base operations.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_989ea72c", "mission3_accept_petty"}, -- I am aware of how fleets function.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_keep_quiet)

akal_colzet_convo_mission3_accept_petty = ConvoScreen:new {
	id = "mission3_accept_petty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_726bd76b", -- Wing Epsilon Zeta, operating out of the garrisoned ISD Accuser, usually handles supply security operations.  Escort, patrol, and the like. They are overtaxed and have asked for additional support. Your job will be to fly a standard patrol sweep through the region.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_e4e8b551", "mission3_glory"}, -- There seems to be no end to these petty duties.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_accept_petty)

akal_colzet_convo_mission3_glory = ConvoScreen:new {
	id = "mission3_glory",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7fa6a6f8", -- What did you expect? Glory in the name of the Emperor? That may be what the men and women of the Death Star found, but out here its business as usual. This war will be won through the daily effort of loyal officers doing their assigned duties, not the heroics of a single SpecOps ghost.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_22451e60", "mission3_serve"}, -- We serve as the Emperor wills.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_glory)

akal_colzet_convo_mission3_serve = ConvoScreen:new {
	id = "mission3_serve",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4c6875a7", -- In this outfit, you serve as I will. Now get out to that patrol. Report to me when you're done.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_serve)

akal_colzet_convo_mission3_failed = ConvoScreen:new {
	id = "mission3_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_92c85144", -- You flubbed a simple operation. This patrol should have been flawless.
	stopConversation = "false",
	animation = "gesticulate_wildly",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d4dd5a28", "mission3_no_excuses"}, -- There was a...
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_failed)

akal_colzet_convo_mission3_no_excuses = ConvoScreen:new {
	id = "mission3_no_excuses",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7ba2ac61", -- No excuses! Get back out there and complete your mission, or I'll find someone who can!
	stopConversation = "false",
	animation = "threaten",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_28586fd5", "mission3_retry"}, -- Very well.
		{"@conversation/tatooine_imperial_trainer_1:s_668cac00", "mission3_later"}, -- I need to think about the mission and figure out what went wrong.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_no_excuses)

akal_colzet_convo_mission3_retry = ConvoScreen:new {
	id = "mission3_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_34975e9f", -- Report back to me when you've successfully completed the mission.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_retry)

akal_colzet_convo_mission3_later = ConvoScreen:new {
	id = "mission3_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_34ff44c5", -- Maybe you should reread your flight manual. Come back when you want to try again.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_later)

akal_colzet_convo_mission3_won = ConvoScreen:new {
	id = "mission3_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_36b3ba5a", -- Report on your patrol, pilot.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_52b712dc", "mission3_proud"}, -- (Relate the details of the distress call.)
		{"@conversation/tatooine_imperial_trainer_1:s_85414d61", "mission3_uncharacteristic"}, -- (Brag about how you saved some stupid transport.)
		{"@conversation/tatooine_imperial_trainer_1:s_39aba3b6", "mission3_glorious"}, -- (Tell him about your victory in battle.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_won)

akal_colzet_convo_mission3_proud = ConvoScreen:new {
	id = "mission3_proud",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_35daf5c2", -- You responded to a rapidly changing situation, eliminated the enemy, and helped secure valuable medical supplies. I'm proud of you, pilot. You've come a long way in a short time. The Empire could use more people like you.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d09c1ecb", "mission3_pay"}, -- Just doing my duty, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_proud)

akal_colzet_convo_mission3_pay_bandolier = ConvoScreen:new {
	id = "mission3_pay_bandolier",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_601e26c5", -- Here's your salary for the operation and another bonus for exceptional duty. I also received your Imperial flight suit, but you'll never fit into this...Why don't you take this bandolier, instead.  At least you can keep your things organized.  Your helmet will take a while longer, the inertia electronics have to be calibrated for every pilot. You wouldn't want to black out during a fast maneuver.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_69d5148f", "mission3_officer"}, -- Thank you sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay_bandolier)

akal_colzet_convo_mission3_pay = ConvoScreen:new {
	id = "mission3_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_13195064", -- Here's your salary for the operation and another bonus for exceptional duty. I also received your Imperial flight suit. Please wear it while you are on duty. Your helmet will take a while longer, the inertia electronics have to be calibrated for every pilot. You wouldn't want to black out during a fast maneuver.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_69d5148f", "mission3_officer"}, -- Thank you sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay)

akal_colzet_convo_mission3_officer = ConvoScreen:new {
	id = "mission3_officer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_ea5b6641", -- I have to admit that you have the makings of a true Imperial officer about you. Report back to me when you are ready for your next mission.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_officer)

akal_colzet_convo_mission3_uncharacteristic = ConvoScreen:new {
	id = "mission3_uncharacteristic",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2800bbf1", -- Yes, I've heard. Saving that transport was very uncharacteristic of you.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_61f0326", "mission3_owe"}, -- Figured if I didn't, you wouldn't pay me.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_uncharacteristic)

akal_colzet_convo_mission3_owe = ConvoScreen:new {
	id = "mission3_owe",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_2f923a47", -- Yes, you're probably right about that. You managed to help secure valuable medical supplies. A lot of people owe you for your bravery.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_713afe89", "mission3_pay_wear"}, -- Yeah? Well you can tell 'em where to find me so they can pay up.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_owe)

akal_colzet_convo_mission3_pay_embarrassment = ConvoScreen:new {
	id = "mission3_pay_embarrassment",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b36213b9", -- It never changes with you does it. Here's your payment as well as a bonus for saving the transport. I also received your Imperial flight suit, but I'm not going to give it to you... you'd be an embarrassment to the Empire.  Just take this bandolier.  At least you can keep your things organized, for a change.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a0129ea3", "mission3_obstinate"}, -- I told you before, I wear what I want.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay_embarrassment)

akal_colzet_convo_mission3_pay_wear = ConvoScreen:new {
	id = "mission3_pay_wear",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7ff3bffd", -- It never changes with you does it. Here's your payment as well as a bonus for saving the transport. I also received your Imperial flight suit. At least try to look like a pilot and wear it while you're on duty.
	stopConversation = "false",
	animation = "wave_finger_warning",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a0129ea3", "mission3_obstinate"}, -- I told you before, I wear what I want.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay_wear)

akal_colzet_convo_mission3_obstinate = ConvoScreen:new {
	id = "mission3_obstinate",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_153a5c24", -- You are the most obstinate person I have ever had the displeasure of meeting. Report back to me when you are ready for another mission.
	stopConversation = "true",
	animation = "shake_head_disgust",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_obstinate)

akal_colzet_convo_mission3_glorious = ConvoScreen:new {
	id = "mission3_glorious",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_63f41edf", -- A glorious achievement, I'm sure. You responded to a rapidly changing situation, eliminated the enemy, and helped secure valuable medical supplies. The Naval Command is pleased with your adaptability.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_2bca7dec", "mission3_pay_surprising"}, -- Apparently there are few skilled warriors in this Navy, if my actions are surprising.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_glorious)

akal_colzet_convo_mission3_pay_too_large = ConvoScreen:new {
	id = "mission3_pay_too_large",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_42b12aab", -- Perhaps they merely find them surprising coming from you. Here's your payment as well as a bonus for saving the transport. I also received your Imperial flight suit, but you're much too large to fit into this... take this bandolier instead.  At the very least, it will help you organize your things.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c0ce49d6", "mission3_next_mission"}, -- (Grunt in affirmation.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay_too_large)

akal_colzet_convo_mission3_pay_surprising = ConvoScreen:new {
	id = "mission3_pay_surprising",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_36f7cf1e", -- Perhaps they merely find them surprising coming from you. Here's your payment as well as a bonus for saving the transport. I also received your Imperial flight suit. Please wear it while you are on duty.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c0ce49d6", "mission3_next_mission"}, -- (Grunt in affirmation.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_pay_surprising)

akal_colzet_convo_mission3_next_mission = ConvoScreen:new {
	id = "mission3_next_mission",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_701f8a8e", -- Report back to me when you are ready for your next mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission3_next_mission)

akal_colzet_convo_mission4_offer = ConvoScreen:new {
	id = "mission4_offer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_f7913cae", -- At ease, Pilot. The security situation in the Bestine Orbital Region has clearly deteriorated. Pirate attacks on commerce lanes and supply transports cannot be tolerated. You have shown commendable initiative in responding to pirate aggression, so you have been selected for a special mission.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_8efde2ae", "mission4_located"}, -- Yes, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_b2b35c1f", "mission4_special"}, -- Special, eh? Hope that means it pays more money.
		{"@conversation/tatooine_imperial_trainer_1:s_523f6698", "mission4_worthy"}, -- This sounds like something that might be worthy.
		{"@conversation/tatooine_imperial_trainer_1:s_9237617f", "mission4_no_training"}, -- What about training?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_offer)

akal_colzet_convo_mission4_no_training = ConvoScreen:new {
	id = "mission4_no_training",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_28526663", -- Later!  This situation is urgent.  I'll train you AFTER you have completed this special assignment.  Got it?
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_8efde2ae", "mission4_located"}, -- Yes, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_b2b35c1f", "mission4_special"}, -- Special, eh? Hope that means it pays more money.
		{"@conversation/tatooine_imperial_trainer_1:s_523f6698", "mission4_worthy"}, -- This sounds like something that might be worthy.
		{"@conversation/tatooine_imperial_trainer_1:s_9237617f", "mission4_no_training"}, -- What about training?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_no_training)

akal_colzet_convo_mission4_located = ConvoScreen:new {
	id = "mission4_located",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5ce97ee2", -- Imperial intelligence has located a suspected pirate leader. He seems to frequent a staging area close to the Bestine Orbital Region. I'm transferring the coordinates to your datapad now.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_83d1f7de", "mission4_accept"}, -- Understood, sir!
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_located)

akal_colzet_convo_mission4_accept = ConvoScreen:new {
	id = "mission4_accept",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_930b7f4c", -- Your job is to locate and eliminate the pirate leader at the coordinates I have given you. Imperial Naval Command believes a decisive strike against the pirates would cripple, if not eliminate, their operations in this system.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_2c3d0c07", "mission4_guide"}, -- I will find and destroy the enemy, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_accept)

akal_colzet_convo_mission4_guide = ConvoScreen:new {
	id = "mission4_guide",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_4c97441f", -- Report to me when you have completed your mission. May the Emperor guide you to victory.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_guide)

akal_colzet_convo_mission4_special = ConvoScreen:new {
	id = "mission4_special",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5ce97ee2", -- Imperial intelligence has located a suspected pirate leader. He seems to frequent a staging area close to the Bestine Orbital Region. I'm transferring the coordinates to your datapad now.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_f4fa11bb", "mission4_accept_bounty"}, -- Hmm. Nope, don't know the guy.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_special)

akal_colzet_convo_mission4_accept_bounty = ConvoScreen:new {
	id = "mission4_accept_bounty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7279069a", -- Your job is to locate and eliminate the pirate leader. Imperial Naval Command believes a decisive strike against the pirates would cripple, if not eliminate, their operations in this system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_7e347138", "mission4_bounty"}, -- He's as good as dead.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_accept_bounty)

akal_colzet_convo_mission4_bounty = ConvoScreen:new {
	id = "mission4_bounty",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_f4d10868", -- Report to me when you have completed your mission to claim your bounty.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_bounty)

akal_colzet_convo_mission4_worthy = ConvoScreen:new {
	id = "mission4_worthy",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_5ce97ee2", -- Imperial intelligence has located a suspected pirate leader. He seems to frequent a staging area close to the Bestine Orbital Region. I'm transferring the coordinates to your datapad now.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_6942ec7e", "mission4_strike"}, -- You want me to eliminate him.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_worthy)

akal_colzet_convo_mission4_strike = ConvoScreen:new {
	id = "mission4_strike",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_7c96fa97", -- Imperial Naval Command believes a decisive strike against the pirates would cripple their operations in this system.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_a2d4dd9d", "mission4_report"}, -- I will not fail the Emperor.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_strike)

akal_colzet_convo_mission4_report = ConvoScreen:new {
	id = "mission4_report",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_fdbe01c2", -- Report in with me when you've completed the operation.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_report)

akal_colzet_convo_mission4_failed = ConvoScreen:new {
	id = "mission4_failed",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_83fa9322", -- Give me an update on the status of your operation against the pirate leader, pilot.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_248cfc90", "mission4_underestimate"}, -- (Relate information on your inability to defeat the pirate leader.)
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_failed)

akal_colzet_convo_mission4_underestimate = ConvoScreen:new {
	id = "mission4_underestimate",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_1a5d8b73", -- Don't underestimate him. A particularly skilled and charismatic leader might explain the increase in the pirate activity. You must continue to hunt him down.
	stopConversation = "false",
	animation = "rub_chin_thoughtful",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_28586fd5", "mission4_retry"}, -- Very well.
		{"@conversation/tatooine_imperial_trainer_1:s_3de840b5", "mission4_later"}, -- I need to spend some time practicing.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_underestimate)

akal_colzet_convo_mission4_retry = ConvoScreen:new {
	id = "mission4_retry",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_adf9eee2", -- Report to me when you've completed your mission.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_retry)

akal_colzet_convo_mission4_later = ConvoScreen:new {
	id = "mission4_later",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6868d86b", -- Return to me when you are ready to take the mission.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_later)

akal_colzet_convo_mission4_won = ConvoScreen:new {
	id = "mission4_won",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_a79075ab", -- Report on the status of your operation against the pirate leader, pilot.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_e12b6418", "mission4_masterful"}, -- I located and destroyed him, sir.
		{"@conversation/tatooine_imperial_trainer_1:s_4d7a1ae4", "mission4_asset"}, -- Spaced him. Now, about my fee?
		{"@conversation/tatooine_imperial_trainer_1:s_2a1af001", "mission4_impressive"}, -- I defeated him with ease.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_won)

akal_colzet_convo_mission4_masterful = ConvoScreen:new {
	id = "mission4_masterful",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b5d0e16a", -- This information will please the Naval Command. No doubt they will also realize that part of your success came from my masterful instruction. I think you may have done us both a great service.
	stopConversation = "false",
	animation = "applause_polite",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_d09c1ecb", "mission4_pay"}, -- Just doing my duty, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_masterful)

akal_colzet_convo_mission4_pay_head = ConvoScreen:new {
	id = "mission4_pay_head",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_247ae5a6", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions. Nevertheless, keep it as a symbol of the technological and military might of the Empire.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c6aae4cb", "mission4_cranial"}, -- Cranial proportions?
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_pay_head)

akal_colzet_convo_mission4_cranial = ConvoScreen:new {
	id = "mission4_cranial",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_42dfe6db", -- Indeed. The Empire rarely enlists non-Humans as pilots, and so we are poorly prepared to equip someone such as yourself. But do not be discouraged. Your current standing in the Imperial Navy is a testament to your abilities.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "mission4_earned"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_cranial)

akal_colzet_convo_mission4_pay = ConvoScreen:new {
	id = "mission4_pay",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b8f011dc", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile. Wear this whenever you are on duty as a symbol of the Empire's technological and military might.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_987445c9", "mission4_earned"}, -- Thank you, sir.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_pay)

akal_colzet_convo_mission4_earned = ConvoScreen:new {
	id = "mission4_earned",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_6fcaa2a", -- You've earned it, pilot. You have exceeded the expectations of this program and of myself. Your duty has not ended, however. Return when you are ready to take on another operation.
	stopConversation = "true",
	animation = "salute1",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_earned)

akal_colzet_convo_mission4_asset = ConvoScreen:new {
	id = "mission4_asset",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_8273f08f", -- Naval Command will be pleased. I didn't expect someone like you to be such an asset to the Empire.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_c01da9e4", "mission4_sneer"}, -- (Sneer at him.) Just pay me.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_asset)

akal_colzet_convo_mission4_sneer_head = ConvoScreen:new {
	id = "mission4_sneer_head",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_15daf24e", -- You don't take complements very well. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet. Unfortunately, these standard issue helmets are not suited to meet your, uh... cranial proportions.
	stopConversation = "false",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_87e1d305", "mission4_cant_wear"}, -- It's kinda ugly lookin'.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_sneer_head)

akal_colzet_convo_mission4_cant_wear = ConvoScreen:new {
	id = "mission4_cant_wear",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_19d7d16a", -- It's too bad you can't wear it. It would be a marked improvement. Report back to me when you're ready for more work.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_cant_wear)

akal_colzet_convo_mission4_sneer = ConvoScreen:new {
	id = "mission4_sneer",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_dfd0987b", -- You don't take complements very well. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_87e1d305", "mission4_wear_it"}, -- It's kinda ugly lookin'.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_sneer)

akal_colzet_convo_mission4_wear_it = ConvoScreen:new {
	id = "mission4_wear_it",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_95f0e74b", -- Even so, I suggest you wear it. It would be a marked improvement. Report back to me when you're ready for more work.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_wear_it)

akal_colzet_convo_mission4_impressive = ConvoScreen:new {
	id = "mission4_impressive",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b1f99085", -- This information will please the Naval Command. You have done an impressive job, Pilot. Perhaps you really are all that you claim.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_ce681825", "mission4_pay_bold"}, -- You should have realized this long ago.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_impressive)

akal_colzet_convo_mission4_pay_bold = ConvoScreen:new {
	id = "mission4_pay_bold",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_b8f011dc", -- Here is your salary for the mission. This one was worth double the normal rate. I've also received your Imperial TIE pilot helmet, specifically calibrated for your mental and physical flight profile. Wear this whenever you are on duty as a symbol of the Empire's technological and military might.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/tatooine_imperial_trainer_1:s_cd024d84", "mission4_suits"}, -- It looks intimidating. I like it.
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_pay_bold)

akal_colzet_convo_mission4_suits = ConvoScreen:new {
	id = "mission4_suits",
	leftDialog = "@conversation/tatooine_imperial_trainer_1:s_ca3578cc", -- I think it suits you. You have exceeded the expectations of this program and of myself. Your duty has not ended, however. Return when you are ready to take on another operation.
	stopConversation = "true",
	animation = "dismiss",
	options = {
	}
}
akal_colzet_convo_template:addScreen(akal_colzet_convo_mission4_suits)

addConversationTemplate("akal_colzet_convo_template", akal_colzet_convo_template)
