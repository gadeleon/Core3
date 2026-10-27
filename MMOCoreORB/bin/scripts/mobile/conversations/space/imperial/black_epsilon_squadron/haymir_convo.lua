-- Haymir Rendundi (Black Epsilon tier 3) conversation; ported from SWG-Source corellia_imperial_tier3.java with the pre-NGE client lines (feature black-epsilon-tier3-haymir). Handler: haymirConvoHandler.
haymir_convo_template = ConvoTemplate:new {
	initialScreen = "",
	templateType = "Lua",
	luaClassHandler = "haymirConvoHandler",
	screens = {}
}

haymir_convo_not_pilot = ConvoScreen:new {
	id = "not_pilot",
	leftDialog = "@conversation/corellia_imperial_tier3:s_8ccf2f5f", -- You don't look like you could pilot a pair of shoes, much less a starship. Get out of here.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_not_pilot)

haymir_convo_wrong_faction = ConvoScreen:new {
	id = "wrong_faction",
	leftDialog = "@conversation/corellia_imperial_tier3:s_7bcc420b", -- Keep moving, puke.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_wrong_faction)

haymir_convo_off_track = ConvoScreen:new {
	id = "off_track",
	leftDialog = "@conversation/corellia_imperial_tier3:s_9be798dc", -- I don't have time for you, maggot. If you are interested in becoming a good pilot, I suggest you lose your current unit and transfer to the Black Epsilon.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_off_track)

haymir_convo_not_ready = ConvoScreen:new {
	id = "not_ready",
	leftDialog = "@conversation/corellia_imperial_tier3:s_8eaae252", -- You think you're ready to play with grownups? Get out of here; your mama's waiting for you.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_not_ready)

haymir_convo_wanted = ConvoScreen:new {
	id = "wanted",
	leftDialog = "@conversation/corellia_imperial_tier3:s_ff9d26dd", -- You treasonous worm.  How dare you even show your face.
	stopConversation = "false",
	animation = "slit_throat",
	options = {
		{"@conversation/corellia_imperial_tier3:s_77e48d5b", "wanted_reports"}, -- What do you mean?
	}
}
haymir_convo_template:addScreen(haymir_convo_wanted)

haymir_convo_wanted_reports = ConvoScreen:new {
	id = "wanted_reports",
	leftDialog = "@conversation/corellia_imperial_tier3:s_28d87347", -- Reports are you've been working against the Empire... assisting the Rebel Alliance.  Well?  What do you have to say for yourself?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_765d3767", "wanted_loyalty"}, -- I'm loyal to the Empire!
	}
}
haymir_convo_template:addScreen(haymir_convo_wanted_reports)

haymir_convo_wanted_loyalty = ConvoScreen:new {
	id = "wanted_loyalty",
	leftDialog = "@conversation/corellia_imperial_tier3:s_50e8d95e", -- That's what you call 'loyalty'?  You don't know the meaning of the word, maggot.  If you ever want to fly for the Imperial Navy again, you'd better re-evaluate some of your past decisions.
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/corellia_imperial_tier3:s_900f01d1", "wanted_end"}, -- What?
	}
}
haymir_convo_template:addScreen(haymir_convo_wanted_loyalty)

haymir_convo_wanted_end = ConvoScreen:new {
	id = "wanted_end",
	leftDialog = "@conversation/corellia_imperial_tier3:s_c82eaa27", -- Either improve your standing with the Empire, or shoot yourself in the head.  I don't care which you choose... either option will earn my forgiveness.
	stopConversation = "true",
	animation = "smack_self",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_wanted_end)

haymir_convo_on_mission = ConvoScreen:new {
	id = "on_mission",
	leftDialog = "@conversation/corellia_imperial_tier3:s_2e69b8ed", -- You've got a job to do, maggot.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_on_mission)

haymir_convo_m1_failed = ConvoScreen:new {
	id = "m1_failed",
	leftDialog = "@conversation/corellia_imperial_tier3:s_c6844d2a", -- Should have known.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_tier3:s_a5d90aff", "m1_retry_excuse"}, -- It was harder than it looked.
		{"@conversation/corellia_imperial_tier3:s_9c5ae9a", "m1_second_shot"}, -- Second time's the charm.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_failed)

haymir_convo_m1_retry_excuse = ConvoScreen:new {
	id = "m1_retry_excuse",
	leftDialog = "@conversation/corellia_imperial_tier3:s_1f1da1b8", -- Do I look like I want to hear excuses from you? Get out of here! And don't come back until the job is done.
	stopConversation = "true",
	animation = "point_away",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m1_retry_excuse)

haymir_convo_m1_second_shot = ConvoScreen:new {
	id = "m1_second_shot",
	leftDialog = "@conversation/corellia_imperial_tier3:s_30b6b17c", -- Why should I give you a second shot?
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_883481e3", "m1_retry"}, -- Because I'll get the job done right.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_second_shot)

haymir_convo_m1_retry = ConvoScreen:new {
	id = "m1_retry",
	leftDialog = "@conversation/corellia_imperial_tier3:s_73c4833", -- That's what you said the last time. Get back up there. Put your money where your mouth is.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m1_retry)

haymir_convo_m2_failed = ConvoScreen:new {
	id = "m2_failed",
	leftDialog = "@conversation/corellia_imperial_tier3:s_64d5bea6", -- Nice work.
	stopConversation = "false",
	animation = "hold_nose",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b713f64f", "m2_retry_sarcastic"}, -- I think you're being sarcastic.
		{"@conversation/corellia_imperial_tier3:s_e6e69be4", "m2_retry"}, -- I blew it. I know.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_failed)

haymir_convo_m2_retry_sarcastic = ConvoScreen:new {
	id = "m2_retry_sarcastic",
	leftDialog = "@conversation/corellia_imperial_tier3:s_823cc9e1", -- Mm, you think? Get back out there.
	stopConversation = "true",
	animation = "rub_chin_thoughtful",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m2_retry_sarcastic)

haymir_convo_m2_retry = ConvoScreen:new {
	id = "m2_retry",
	leftDialog = "@conversation/corellia_imperial_tier3:s_d32315a8", -- 'Blew it' doesn't begin to describe this scenario. It's time for you to do your job, soldier.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m2_retry)

haymir_convo_m3_failed = ConvoScreen:new {
	id = "m3_failed",
	leftDialog = "@conversation/corellia_imperial_tier3:s_3f9b3561", -- Is that what I asked you to do?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_dbb3a834", "m3_retry"}, -- Um, no.
		{"@conversation/corellia_imperial_tier3:s_d8a7505", "m3_retry_rebels"}, -- The Rebels had another idea.
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_failed)

haymir_convo_m3_retry = ConvoScreen:new {
	id = "m3_retry",
	leftDialog = "@conversation/corellia_imperial_tier3:s_4c47ba68", -- I didn't think so. This time, there better not be any mistakes. Get going.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m3_retry)

haymir_convo_m3_retry_rebels = ConvoScreen:new {
	id = "m3_retry_rebels",
	leftDialog = "@conversation/corellia_imperial_tier3:s_cf274903", -- Maybe they have the right idea when they start taking potshots at you. This mission is critical, soldier: don't blow it.
	stopConversation = "true",
	animation = "point_accusingly",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m3_retry_rebels)

haymir_convo_m4_failed = ConvoScreen:new {
	id = "m4_failed",
	leftDialog = "@conversation/corellia_imperial_tier3:s_38be6beb", -- What am I going to do with you?
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d8db54f6", "m4_retry"}, -- Send me back out there!
		{"@conversation/corellia_imperial_tier3:s_31dd2d63", "m4_retry_promise"}, -- It won't happen again.
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_failed)

haymir_convo_m4_retry = ConvoScreen:new {
	id = "m4_retry",
	leftDialog = "@conversation/corellia_imperial_tier3:s_c0cca856", -- I think I will. Now beat it!
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m4_retry)

haymir_convo_m4_retry_promise = ConvoScreen:new {
	id = "m4_retry_promise",
	leftDialog = "@conversation/corellia_imperial_tier3:s_fdbdc3c3", -- It better not. Get back to your ship.
	stopConversation = "true",
	animation = "wave_on_dismissing",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m4_retry_promise)

haymir_convo_m1_reward = ConvoScreen:new {
	id = "m1_reward",
	leftDialog = "@conversation/corellia_imperial_tier3:s_14060a1c", -- I've seen worse - and I've seen better, too. If you want to stay with Black Epsilon, you'll need more skills.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b200234c", "m1_debrief"}, -- I think my mission was successful.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_reward)

haymir_convo_m1_debrief = ConvoScreen:new {
	id = "m1_debrief",
	leftDialog = "@conversation/corellia_imperial_tier3:s_b695af6b", -- So you do. Well it is a good thing that we don't judge success on what you think. Fortunately we have both the operations plan and the Rebel officer.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_2c7b60e", "m1_need_to_know"}, -- Did we find out how Nym and the Rebellion are working together?
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_debrief)

haymir_convo_m1_need_to_know = ConvoScreen:new {
	id = "m1_need_to_know",
	leftDialog = "@conversation/corellia_imperial_tier3:s_2b261439", -- You're just full of questions. But I suppose you are on the need-to-know list. Apparently there is a loose alliance between the Rebels and Nym that was forged by some Rebel officer. In exchange for Nym's help the Rebels are giving him a portion of the salvage. Fortunately for us, the deal is contingent on Nym not taking extensive losses.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_72418db3", "m1_storm"}, -- Why would Nym care about losses?
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_need_to_know)

haymir_convo_m1_storm = ConvoScreen:new {
	id = "m1_storm",
	leftDialog = "@conversation/corellia_imperial_tier3:s_a1b009ed", -- Apparently, Storm Squadron hit him pretty hard in the Lok system and he is still attempting to recover from that blow. We are currently working on ways to exploit his current timidness, because we feel that will be the key to causing the split.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/corellia_imperial_tier3:s_8c751827", "m1_why_not_assault"}, -- Why don't we just directly assault Nym's forces?
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_storm)

haymir_convo_m1_why_not_assault = ConvoScreen:new {
	id = "m1_why_not_assault",
	leftDialog = "@conversation/corellia_imperial_tier3:s_a4f70dc9", -- This is why we pay you to fly and not to think. A direct assault on Nym will have the desired effect but could also be costly for us as well. That is just the sort of advantage that the Rebels are waiting for. Sometimes the direct, kick down the door approach works just fine. But if you are going to learn anything from me, learn this...it is always better to have someone else do your dirty work for you.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_8efde2ae", "m1_training"}, -- Yes, sir.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_why_not_assault)

haymir_convo_m1_training = ConvoScreen:new {
	id = "m1_training",
	leftDialog = "@conversation/corellia_imperial_tier3:s_8dcf50f", -- We will figure out how to split Nym and the Rebels, I assure you. But right now we need to focus on you. In order for you to be any use at all to me, you are going to need some training. Normally, I would just tell you what I want you to learn and you would learn it. But I am feeling generous so I am going to let you decide where you think you need the most work.
	stopConversation = "false",
	animation = "explain",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m1_training)

haymir_convo_m2_reward = ConvoScreen:new {
	id = "m2_reward",
	leftDialog = "@conversation/corellia_imperial_tier3:s_6cef5164", -- So you made it back in one piece. I would have thought the Hutts would be serving you for dinner right now. You don't know how glad that I am you survived.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_a6944d2", "m2_thanks"}, -- Thank you sir, it was tough but I pulled through.
		{"@conversation/corellia_imperial_tier3:s_ddfa7bdb", "m2_mocking"}, -- Why do I get the feeling that you are mocking me?
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_reward)

haymir_convo_m2_thanks = ConvoScreen:new {
	id = "m2_thanks",
	leftDialog = "@conversation/corellia_imperial_tier3:s_bd1d7bf2", -- I told you that subtlety is lost on you. Regardless, I am happy to report that our operation seems to have been a complete success. The Hutts are furious with Nym and are basically attacking his ships on sight. Nym's men are putting up a good defense, but the Hutts are not under the same constraints as Nym.  They're just tossing men at him in order to get revenge.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b779a3", "m2_beautiful"}, -- Sounds like a beautiful thing, sir.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_thanks)

haymir_convo_m2_mocking = ConvoScreen:new {
	id = "m2_mocking",
	leftDialog = "@conversation/corellia_imperial_tier3:s_a1314746", -- Because I am. Regardless, I am happy to report that our operation seems to have been a complete success. The Hutts are furious with Nym and are basically attacking his ships on sight. Nym's men are putting up a good defense but the Hutts are not under the same constraints as Nym.  They are just tossing men at him in order to get revenge.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b779a3", "m2_beautiful"}, -- Sounds like a beautiful thing, sir.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_mocking)

haymir_convo_m2_beautiful = ConvoScreen:new {
	id = "m2_beautiful",
	leftDialog = "@conversation/corellia_imperial_tier3:s_62ccc48d", -- It sure is. 'Nothing better than accomplishing your goal and not having to pay any of the costs. Not only do we start breaking the bridge between Nym and the Rebels, but we also get to eliminate some Hutts in the process. I love it when a plan comes together.
	stopConversation = "false",
	animation = "pose_proudly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_107391a2", "m2_training"}, -- Hmmm, where have I heard that before?
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_beautiful)

haymir_convo_m2_training = ConvoScreen:new {
	id = "m2_training",
	leftDialog = "@conversation/corellia_imperial_tier3:s_47132c0f", -- What! Don't think about it too hard.  You will damage what little you have left of your brain. And you are going to need it in order to learn some new skills. What would you like me to teach you?
	stopConversation = "false",
	animation = "smack_self",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m2_training)

haymir_convo_m3_reward = ConvoScreen:new {
	id = "m3_reward",
	leftDialog = "@conversation/corellia_imperial_tier3:s_d3306841", -- You have done a man's work today. Without the emissary, the Rebels do not have the only man in this operation that Nym trusts. This combined with the heavy fighting with the Hutts is sure to cause an impassable rift between the two.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_657cb9bd", "m3_resolve"}, -- Are you sure about Nym's lack of resolve?
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_reward)

haymir_convo_m3_resolve = ConvoScreen:new {
	id = "m3_resolve",
	leftDialog = "@conversation/corellia_imperial_tier3:s_91e2ca48", -- In this matter I would have to say yes. If nothing else Nym will probably remove his direct support of the Rebellion for the time being. And without Nym's support the Rebels once again find themselves at a major disadvantage. I think that the local security forces can handle the rest of the operation in Yavin.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_tier3:s_1c74e041", "m3_find_out"}, -- Do you think they will find out it was us?
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_resolve)

haymir_convo_m3_find_out = ConvoScreen:new {
	id = "m3_find_out",
	leftDialog = "@conversation/corellia_imperial_tier3:s_26b0b5d1", -- I would be rather shocked if they didn't already know. I don't like Nym or the Hutts, but never assume that either group is stupid. The thing is that it doesn't matter. There is so much bad blood between the two groups that all they really needed was an excuse to start fighting. All they needed was a little push.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_f7a9cb6c", "m3_training"}, -- You risked all your effort and planning on a hunch?
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_find_out)

haymir_convo_m3_training = ConvoScreen:new {
	id = "m3_training",
	leftDialog = "@conversation/corellia_imperial_tier3:s_847e468b", -- I wasn't really risking all that much... just you. If you failed then I would have simply started over with another angle. I took a minimal risk and received maximum gain, that is what being a great leader is all about. Now you are in need of training, are you not?
	stopConversation = "false",
	animation = "laugh_cackle",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m3_training)

haymir_convo_m4_reward = ConvoScreen:new {
	id = "m4_reward",
	leftDialog = "@conversation/corellia_imperial_tier3:s_dd4ea40c", -- That felt good, didn't it? I can just imagine Nym squirming in his Stronghold. Probably cursing the day that emissary convinced him to help the Rebellion.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_84bc2cb6", "m4_training"}, -- I must admit I sort of enjoyed that one.
		{"@conversation/corellia_imperial_tier3:s_1d2c73ce", "m4_revenge"}, -- What if he tries to get revenge?
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_reward)

haymir_convo_m4_training = ConvoScreen:new {
	id = "m4_training",
	leftDialog = "@conversation/corellia_imperial_tier3:s_726bfa38", -- Of course it was. Smash you enemies and all that. We didn't join Black Epsilon so we could take part in peace-keeping missions. I think that there is still something you can learn from me. Do you have anything in mind?
	stopConversation = "false",
	animation = "explain",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m4_training)

haymir_convo_m4_revenge = ConvoScreen:new {
	id = "m4_revenge",
	leftDialog = "@conversation/corellia_imperial_tier3:s_ea45b3c5", -- Oh, no! I didn't think of that. Big, bad Nym is coming to get me. If you are afraid of making enemies you should have become a moisture farmer. You are an Imperial pilot in the Imperial Navy, most of the galaxy already hates you. What is one more? Punish them before they punish you, that's what I say.
	stopConversation = "false",
	animation = "pound_fist_chest",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d9391333", "m4_training_philosophy"}, -- Good philosophy.
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_revenge)

haymir_convo_m4_training_philosophy = ConvoScreen:new {
	id = "m4_training_philosophy",
	leftDialog = "@conversation/corellia_imperial_tier3:s_1dab174a", -- See, you do still have something to learn from me. What is it you are interested in?
	stopConversation = "false",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m4_training_philosophy)

haymir_convo_trained_starships = ConvoScreen:new {
	id = "trained_starships",
	leftDialog = "@conversation/corellia_imperial_tier3:s_7fe8c9bb", -- Yeah, how ABOUT those vessels? You could use a lesson in respect. But for now I'll teach you about Imperial technology. And later, you'll  get a mission - if you ask nicely.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_trained_starships)

haymir_convo_trained_weapons = ConvoScreen:new {
	id = "trained_weapons",
	leftDialog = "@conversation/corellia_imperial_tier3:s_84ce496b", -- Are you kidding? I wrote the book. Let's get started; come back when you're ready for another mission.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_trained_weapons)

haymir_convo_trained_procedures = ConvoScreen:new {
	id = "trained_procedures",
	leftDialog = "@conversation/corellia_imperial_tier3:s_9d2d47d4", -- Your call. I'll give you the intel, and when you're feeling up to it, maybe I'll give you another mission.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_trained_procedures)

haymir_convo_trained_droid = ConvoScreen:new {
	id = "trained_droid",
	leftDialog = "@conversation/corellia_imperial_tier3:s_f00894a4", -- Glad you think so. Your opinion matters to me. Let's do this, and when you're done, maybe you'll be ready for another mission.
	stopConversation = "true",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_trained_droid)

haymir_convo_m1_offer = ConvoScreen:new {
	id = "m1_offer",
	leftDialog = "@conversation/corellia_imperial_tier3:s_1c0f4063", -- %TU. What kind of name is that?
	stopConversation = "false",
	animation = "laugh_titter",
	options = {
		{"@conversation/corellia_imperial_tier3:s_fd236a42", "m1_who_sent"}, -- A good one.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_offer)

haymir_convo_m1_who_sent = ConvoScreen:new {
	id = "m1_who_sent",
	leftDialog = "@conversation/corellia_imperial_tier3:s_b622a494", -- Not in my book it isn't. Who sent you? I need soldiers! And this is what I get.
	stopConversation = "false",
	animation = "shake_head_disgust",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d547e29b", "m1_salvage"}, -- Prisk Kith'Vys told me to report to you for my new assignment.
		{"@conversation/corellia_imperial_tier3:s_19be2c59", "m1_fine_soldier"}, -- You got yourself a fine soldier.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_who_sent)

haymir_convo_m1_fine_soldier = ConvoScreen:new {
	id = "m1_fine_soldier",
	leftDialog = "@conversation/corellia_imperial_tier3:s_18509eaa", -- That is something I will be the judge of. It says in your record that you served under Prisk Kith'Vys. Usually he is a good judge of talent but I am not so sure about his choice this time. What do you have to say for yourself, pilot?
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b93b0c31", "m1_salvage"}, -- Sir, I was told to report to you for my new assignment.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_fine_soldier)

haymir_convo_m1_salvage = ConvoScreen:new {
	id = "m1_salvage",
	leftDialog = "@conversation/corellia_imperial_tier3:s_ecfe85ae", -- Lucky me. Listen up. As you probably know the Empire has been running salvage operations in this system. Unfortunately, we are not the only ones who have taken an interest in the wreckage of the Death Star. We have to deal with pirates, on top of members of the Rebel Alliance trying to get their hands on top secret technologies.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_7af5dab4", "m1_storm_squadron"}, -- Sounds like a job for local security to handle.
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_salvage)

haymir_convo_m1_storm_squadron = ConvoScreen:new {
	id = "m1_storm_squadron",
	leftDialog = "@conversation/corellia_imperial_tier3:s_7bef2106", -- Storm Squadron has done the brunt of the work already in this system, but they are in the process of being reassigned. Not to mention that a new threat has emerged and High Command thinks that we are just the right people to take care of it.
	stopConversation = "false",
	animation = "wave_on_dismissing",
	options = {
		{"@conversation/corellia_imperial_tier3:s_1969477d", "m1_questions"}, -- What would this new problem be?
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_storm_squadron)

haymir_convo_m1_questions = ConvoScreen:new {
	id = "m1_questions",
	leftDialog = "@conversation/corellia_imperial_tier3:s_53126084", -- Did I say you could ask questions? I will explain it all in good time and I can do without your comments. Anyway, it would seem that Nym and the Rebellion have decided to work together in harrying Imperial forces while grabbing as much salvage as they can.
	stopConversation = "false",
	animation = "point_accusingly",
	options = {
		{"@conversation/corellia_imperial_tier3:s_f2993921", "m1_nym"}, -- [wait]
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_questions)

haymir_convo_m1_nym = ConvoScreen:new {
	id = "m1_nym",
	leftDialog = "@conversation/corellia_imperial_tier3:s_586a7d64", -- So you can be silent when required. That is a good thing. Nym is a pirate chief from the Lok system. We have known for a long time that he sympathized with the Rebellion but, as long as he stayed out of the way, we didn't care. It looks like he has had a policy change.
	stopConversation = "false",
	animation = "nod_head_multiple",
	options = {
		{"@conversation/corellia_imperial_tier3:s_12c769cf", "m1_split"}, -- So we are to try to split the alliance between Nym and the Rebellion?
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_nym)

haymir_convo_m1_split = ConvoScreen:new {
	id = "m1_split",
	leftDialog = "@conversation/corellia_imperial_tier3:s_daab08d3", -- You catch on quick. Our first task is to locate a Rebel officer or spy and try to find out about their joint operation. If we can discover how the two forces are working together we can figure out how best to break their alliance. You are to take patrol inside the Yavin system and perform scans of the zone until you can find a ranking member of the Rebel Alliance. Capture and inspect that ship to see if they have the information we are looking for.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_b6b25f13", "m1_accept"}, -- Yes, sir!
	}
}
haymir_convo_template:addScreen(haymir_convo_m1_split)

haymir_convo_m1_accept = ConvoScreen:new {
	id = "m1_accept",
	leftDialog = "@conversation/corellia_imperial_tier3:s_e3bbe83c", -- While you are up there, do not be surprised if we contact you again. This operation will involve careful timing and precise actions. Do not fail me.
	stopConversation = "true",
	animation = "point_up",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m1_accept)

haymir_convo_m2_offer = ConvoScreen:new {
	id = "m2_offer",
	leftDialog = "@conversation/corellia_imperial_tier3:s_fdda16c7", -- OK, junior, new mission. We have careful reviewed all of the data that you somehow managed to provide us, and we believe that we have a course of action that will cause Nym to withdraw his aid to the Rebellion in this sector.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/corellia_imperial_tier3:s_5eb7a1e3", "m2_other_pirates"}, -- I am ready and willing, sir.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_offer)

haymir_convo_m2_other_pirates = ConvoScreen:new {
	id = "m2_other_pirates",
	leftDialog = "@conversation/corellia_imperial_tier3:s_fe5bcaa2", -- How did I know that you were going to say that? Remember how I mentioned that there were other pirates at work in this system? Of course you don't. Hutts, man...Hutts are also working on salvaging as much as they can get their hands on. It would appear that they have a deal with Nym and the Rebels not to get in each other's way. Well, that is about to change.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_2ef3848a", "m2_simple"}, -- I don't quite follow you.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_other_pirates)

haymir_convo_m2_simple = ConvoScreen:new {
	id = "m2_simple",
	leftDialog = "@conversation/corellia_imperial_tier3:s_1bf62740", -- It's so simple. We start a fight between the Hutts and Nym. The Hutts do our dirty work for us and suddenly it becomes too expensive for Nym to operate in this system. He cannot afford to fight with both the Empire and Hutts.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/corellia_imperial_tier3:s_7c05dd60", "m2_smuggler"}, -- How do we get those two factions to start fighting?
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_simple)

haymir_convo_m2_smuggler = ConvoScreen:new {
	id = "m2_smuggler",
	leftDialog = "@conversation/corellia_imperial_tier3:s_22f895e3", -- Glad you asked. First we are going to need one of the Hutt's smuggler ships. You will capture that ship for us. We will retrofit that vessel with a special sensor jammer that will increase its signature, masking other ships flying with it.
	stopConversation = "false",
	animation = "snap_finger2",
	options = {
		{"@conversation/corellia_imperial_tier3:s_44750833", "m2_broadcasts"}, -- So you want me to get you a Hutt smuggler?
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_smuggler)

haymir_convo_m2_broadcasts = ConvoScreen:new {
	id = "m2_broadcasts",
	leftDialog = "@conversation/corellia_imperial_tier3:s_1e26f934", -- Correct! And after you capture the ship we will need you to stir up Nym's gang a bit with some Hutt broadcasts. Then you will be traveling with the retrofitted vessel in order to destroy some of Nym's fighters.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_24f21f71", "m2_accept"}, -- Ah, I see. With the enlarged signature it will appear that the Hutt vessel is destroying Nym's men.
	}
}
haymir_convo_template:addScreen(haymir_convo_m2_broadcasts)

haymir_convo_m2_accept = ConvoScreen:new {
	id = "m2_accept",
	leftDialog = "@conversation/corellia_imperial_tier3:s_bc65ef6a", -- I am surprised. You are a little brighter than you look..not much, but a little. If all goes well Nym's forces will retaliate on the Hutts, who will simply think that Nym has double-crossed them.  And they in turn, will respond with force.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m2_accept)

haymir_convo_m3_offer = ConvoScreen:new {
	id = "m3_offer",
	leftDialog = "@conversation/corellia_imperial_tier3:s_424f249d", -- OK %TU - you're up. We just received word that one of our salvage transports was hit hard and left for dead. We have reason to believe that it was hit by a joint force of Nym's men and Rebels Alliance starfighters.
	stopConversation = "false",
	animation = "beckon",
	options = {
		{"@conversation/corellia_imperial_tier3:s_ecd826ee", "m3_cracks"}, -- I thought their alliance was shattered.
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_offer)

haymir_convo_m3_cracks = ConvoScreen:new {
	id = "m3_cracks",
	leftDialog = "@conversation/corellia_imperial_tier3:s_3af86b40", -- We caused some cracks that will grow in time, but I think if we hit it one more time we can break it apart now.
	stopConversation = "false",
	animation = "nod_head_once",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d0f9703", "m3_emissary"}, -- So what is this have to do with that transport?
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_cracks)

haymir_convo_m3_emissary = ConvoScreen:new {
	id = "m3_emissary",
	leftDialog = "@conversation/corellia_imperial_tier3:s_8bbc7303", -- Intelligence doesn't believe that Nym approached the Rebellion. He is far too cautious for that. Reports from the inside suggest that a Rebel emissary met with Nym, and the pirate chief took such a liking to this Rebel that he agreed to help out. We figure if this emissary is eliminated, then Nym will back out of the agreement.
	stopConversation = "false",
	animation = "pound_fist_palm",
	options = {
		{"@conversation/corellia_imperial_tier3:s_af020de3", "m3_freighter"}, -- Where can we find the emissary?
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_emissary)

haymir_convo_m3_freighter = ConvoScreen:new {
	id = "m3_freighter",
	leftDialog = "@conversation/corellia_imperial_tier3:s_85e02cc1", -- That is where the freighter comes in. Nym's men will not take orders from any member of the Rebellion regardless of the agreement. But they will follow anyone who Nym tells them too. In this case the only member of the Rebellion that we can see Nym having his men follow is this emissary. So if the freighter was hit by a joint attack of Rebels and Nym's men, then it was probably lead by the emissary.
	stopConversation = "false",
	animation = "explain",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d1e44f54", "m3_accept"}, -- Ah, so the freighter might have some clue as to where the emissary went.
	}
}
haymir_convo_template:addScreen(haymir_convo_m3_freighter)

haymir_convo_m3_accept = ConvoScreen:new {
	id = "m3_accept",
	leftDialog = "@conversation/corellia_imperial_tier3:s_66ebf9d3", -- You earn your gold star for the day. Get out to that freighter, assist it with any repairs it might need, and escort it back to port. We can question the pilot and check its computer logs to see if we can get a lock on the emissary's ship. Dismissed.
	stopConversation = "true",
	animation = "shrug_shoulders",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m3_accept)

haymir_convo_m4_offer = ConvoScreen:new {
	id = "m4_offer",
	leftDialog = "@conversation/corellia_imperial_tier3:s_799d2952", -- Maybe you've got what it takes, after all.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_fc27931b", "m4_lok"}, -- Thanks.
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_offer)

haymir_convo_m4_lok = ConvoScreen:new {
	id = "m4_lok",
	leftDialog = "@conversation/corellia_imperial_tier3:s_27e5eff7", -- Don't thank me yet. I haven't thrown you any curveballs - until now. Prepare to head for Lok.
	stopConversation = "false",
	animation = "slow_down",
	options = {
		{"@conversation/corellia_imperial_tier3:s_c9015929", "m4_punish"}, -- Why am I heading to Lok?
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_lok)

haymir_convo_m4_punish = ConvoScreen:new {
	id = "m4_punish",
	leftDialog = "@conversation/corellia_imperial_tier3:s_36900273", -- Let me use small words so you can understand. Lok is Nym's base of power. Nym was helping the Rebellion. The Empire cannot allow Nym to flaunt it's authority like that. We are going to punish Nym.
	stopConversation = "false",
	options = {
		{"@conversation/corellia_imperial_tier3:s_cd445db2", "m4_accept"}, -- I like the sound of that.
	}
}
haymir_convo_template:addScreen(haymir_convo_m4_punish)

haymir_convo_m4_accept = ConvoScreen:new {
	id = "m4_accept",
	leftDialog = "@conversation/corellia_imperial_tier3:s_271e95b3", -- So does the Emperor. Our goals will be to first take one of Nym's transport ships. They usually have detailed records of shipping lanes and that sort of thing in the Lok system. Once we have that we can find out where Nym's military forces are and hammer them with everything we got. Go capture and inspect me one of those transports.
	stopConversation = "true",
	animation = "dismiss",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_m4_accept)

haymir_convo_tour_complete = ConvoScreen:new {
	id = "tour_complete",
	leftDialog = "@conversation/corellia_imperial_tier3:s_daaff7a", -- Well %TU, I've had about enough of you. Time to hand you off.
	stopConversation = "false",
	animation = "salute1",
	options = {
		{"@conversation/corellia_imperial_tier3:s_d2e23af2", "insurgent"}, -- What's my next assignment?
	}
}
haymir_convo_template:addScreen(haymir_convo_tour_complete)

haymir_convo_insurgent = ConvoScreen:new {
	id = "insurgent",
	leftDialog = "@conversation/corellia_imperial_tier3:s_91cf92a7", -- From now on, you'll be reporting to someone named Insurgent. And I thought YOU had a ridiculous name the first time we met.
	stopConversation = "false",
	animation = "shrug_shoulders",
	options = {
		{"@conversation/corellia_imperial_tier3:s_24a3fa0c", "insurgent_who"}, -- Who's that?
	}
}
haymir_convo_template:addScreen(haymir_convo_insurgent)

haymir_convo_insurgent_who = ConvoScreen:new {
	id = "insurgent_who",
	leftDialog = "@conversation/corellia_imperial_tier3:s_c18b617e", -- I have absolutely no idea. He showed up here today and tossed an Imperial order on my desk. And wouldn't you know it that order was signed by the Emperor himself.
	stopConversation = "false",
	animation = "shrug_hands",
	options = {
		{"@conversation/corellia_imperial_tier3:s_1474f13c", "insurgent_order"}, -- What did the order say?
	}
}
haymir_convo_template:addScreen(haymir_convo_insurgent_who)

haymir_convo_insurgent_order = ConvoScreen:new {
	id = "insurgent_order",
	leftDialog = "@conversation/corellia_imperial_tier3:s_6d0b02b", -- The order simply read, 'Obey this man as you would obey me'. As far as I can tell it is completely legit. Then that Insurgent fellow told me that I was to transfer you over to his command immediately.
	stopConversation = "false",
	animation = "point_to_self",
	options = {
		{"@conversation/corellia_imperial_tier3:s_9b5a6b23", "insurgent_dantooine"}, -- He asked for me by name?
	}
}
haymir_convo_template:addScreen(haymir_convo_insurgent_order)

haymir_convo_insurgent_dantooine = ConvoScreen:new {
	id = "insurgent_dantooine",
	leftDialog = "@conversation/corellia_imperial_tier3:s_c65e1fa7", -- I don't know what he wants with you and frankly I wasn't about to ask. There was something about him that made me feel real uneasy. Regardless he told me that you were to meet him at the Imperial Outpost on Dantooine and then jumped in his ship and took off. I suggest that you don't keep him waiting. I get the feeling that he isn't someone who likes to be kept waiting. You are dismissed.
	stopConversation = "true",
	animation = "explain",
	options = {}
}
haymir_convo_template:addScreen(haymir_convo_insurgent_dantooine)

addConversationTemplate("haymir_convo_template", haymir_convo_template)
