-- Shared data of the Arkon client-string work (space-convo-client-strings-arkon, .claude/work/space-convo-client-strings-arkon/01-spec.md).
-- Copied from the spec (Appendix A, B, D, E and Content contract 1b / 2), not read from arkon_convo.lua or arkonConvoHandler.lua, so a wrong production value fails a
-- test instead of agreeing with itself.
--   D.BASE          the commit the "nothing else moves" checks compare with
--   D.SITES         Appendix A: the 78 lines of arkon_convo.lua that change, as { line (at base f637c689a0), screen, field ("leftDialog" or the 1-based option index),
--                   link (option rows: the screen the option leads to, unchanged), nge, twin }
--   D.TWIN          nge id -> pre-NGE id (derived from D.SITES; the same NGE id always has the same twin)
--   D.TEXT          Appendix B: the client text of the 54 twin ids, as the trailing `-- <text>` comments quote it
--   D.TRAINING_TEXT Appendix B: the client text of the 12 pre-NGE-only training lines
--   D.LEFT_COUNTS   Appendix D: the leftDialog ids that appear on more than one screen after the feature, and on how many
--   D.TRAINING      Content contract 1b: the six training screens, the deleted and the added screen ids
--   D.TRAIN_CHOICES Content contract 2: the handler table, complete string literals
--   D.BLOCK         Appendix E: the replacement training block (base lines 859-925), line by line

local D = {}

D.BASE = "f637c689a0"
D.PREFIX = "@conversation/corellia_rebel_tier4:"

D.SITES = {
	{ line = 45, screen = "duty_info", field = 1, link = "s_386", nge = "s_384", twin = "s_42880861" },
	{ line = 320, screen = "s_9f50a13", field = 1, link = "mission1_accept_b", nge = "s_100", twin = "s_9d0a2207" },
	{ line = 325, screen = "mission1_accept_b", field = "leftDialog", link = nil, nge = "s_102", twin = "s_526ce515" },
	{ line = 327, screen = "mission1_accept_b", field = 1, link = "s_106", nge = "s_104", twin = "s_410d920c" },
	{ line = 332, screen = "s_106", field = "leftDialog", link = nil, nge = "s_106", twin = "s_a434ad25" },
	{ line = 346, screen = "s_115", field = "leftDialog", link = nil, nge = "s_115", twin = "s_d98a6441" },
	{ line = 348, screen = "s_115", field = 1, link = "s_119", nge = "s_117", twin = "s_f5cc7cf3" },
	{ line = 353, screen = "s_119", field = "leftDialog", link = nil, nge = "s_119", twin = "s_c95dbd1" },
	{ line = 355, screen = "s_119", field = 1, link = "mission1_accept_c", nge = "s_121", twin = "s_9d0a2207" },
	{ line = 360, screen = "mission1_accept_c", field = "leftDialog", link = nil, nge = "s_123", twin = "s_526ce515" },
	{ line = 363, screen = "mission1_accept_c", field = 1, link = "s_127", nge = "s_125", twin = "s_410d920c" },
	{ line = 368, screen = "s_127", field = "leftDialog", link = nil, nge = "s_127", twin = "s_a434ad25" },
	{ line = 471, screen = "s_d16ee99f", field = 1, link = "s_158", nge = "s_156", twin = "s_841d27db" },
	{ line = 476, screen = "s_158", field = "leftDialog", link = nil, nge = "s_158", twin = "s_900f01d1" },
	{ line = 479, screen = "s_158", field = 1, link = "s_162", nge = "s_160", twin = "s_c985b91" },
	{ line = 484, screen = "s_162", field = "leftDialog", link = nil, nge = "s_162", twin = "s_d6f2e64d" },
	{ line = 487, screen = "s_162", field = 1, link = "s_166", nge = "s_164", twin = "s_29544149" },
	{ line = 492, screen = "s_166", field = "leftDialog", link = nil, nge = "s_166", twin = "s_f59d9106" },
	{ line = 495, screen = "s_166", field = 1, link = "s_170", nge = "s_168", twin = "s_37e345fe" },
	{ line = 500, screen = "s_170", field = "leftDialog", link = nil, nge = "s_170", twin = "s_9a01b8f2" },
	{ line = 502, screen = "s_170", field = 1, link = "mission2_accept_b", nge = "s_172", twin = "s_eb1c3d4e" },
	{ line = 507, screen = "mission2_accept_b", field = "leftDialog", link = nil, nge = "s_174", twin = "s_f3603d67" },
	{ line = 514, screen = "s_178", field = "leftDialog", link = nil, nge = "s_178", twin = "s_900f01d1" },
	{ line = 627, screen = "s_207", field = "leftDialog", link = nil, nge = "s_207", twin = "s_8cac3c56" },
	{ line = 630, screen = "s_207", field = 1, link = "s_211", nge = "s_209", twin = "s_98199797" },
	{ line = 635, screen = "s_211", field = "leftDialog", link = nil, nge = "s_211", twin = "s_1bb2f893" },
	{ line = 638, screen = "s_211", field = 1, link = "mission3_accept_b", nge = "s_213", twin = "s_7ae51280" },
	{ line = 643, screen = "mission3_accept_b", field = "leftDialog", link = nil, nge = "s_215", twin = "s_11769c29" },
	{ line = 650, screen = "s_220", field = "leftDialog", link = nil, nge = "s_220", twin = "s_ff9fae78" },
	{ line = 680, screen = "s_229", field = "leftDialog", link = nil, nge = "s_229", twin = "s_882e7ab9" },
	{ line = 682, screen = "s_229", field = 1, link = "s_233", nge = "s_231", twin = "s_d06c9b96" },
	{ line = 687, screen = "s_233", field = "leftDialog", link = nil, nge = "s_233", twin = "s_a6e1a5f4" },
	{ line = 690, screen = "s_233", field = 1, link = "s_237", nge = "s_235", twin = "s_bed0dfe7" },
	{ line = 695, screen = "s_237", field = "leftDialog", link = nil, nge = "s_237", twin = "s_8cac3c56" },
	{ line = 698, screen = "s_237", field = 1, link = "s_241", nge = "s_239", twin = "s_98199797" },
	{ line = 703, screen = "s_241", field = "leftDialog", link = nil, nge = "s_241", twin = "s_1bb2f893" },
	{ line = 705, screen = "s_241", field = 1, link = "mission3_accept_c", nge = "s_243", twin = "s_7ae51280" },
	{ line = 710, screen = "mission3_accept_c", field = "leftDialog", link = nil, nge = "s_245", twin = "s_11769c29" },
	{ line = 796, screen = "s_8762aa6e", field = 1, link = "s_b1f1f364", nge = "s_272", twin = "s_77e48d5b" },
	{ line = 812, screen = "s_dbcde2d3", field = 1, link = "s_279", nge = "s_277", twin = "s_99d3b4fd" },
	{ line = 817, screen = "s_279", field = "leftDialog", link = nil, nge = "s_279", twin = "s_50669846" },
	{ line = 819, screen = "s_279", field = 1, link = "s_283", nge = "s_281", twin = "s_9a626852" },
	{ line = 824, screen = "s_283", field = "leftDialog", link = nil, nge = "s_283", twin = "s_e93fce3e" },
	{ line = 827, screen = "s_283", field = 1, link = "s_287", nge = "s_285", twin = "s_53544796" },
	{ line = 832, screen = "s_287", field = "leftDialog", link = nil, nge = "s_287", twin = "s_b607bb2e" },
	{ line = 835, screen = "s_287", field = 1, link = "s_291", nge = "s_289", twin = "s_8729f60e" },
	{ line = 840, screen = "s_291", field = "leftDialog", link = nil, nge = "s_291", twin = "s_31fd5acf" },
	{ line = 843, screen = "s_291", field = 1, link = "s_295", nge = "s_293", twin = "s_a9e4fd02" },
	{ line = 848, screen = "s_295", field = "leftDialog", link = nil, nge = "s_295", twin = "s_127f2e23" },
	{ line = 850, screen = "s_295", field = 1, link = "mission4_accept_b", nge = "s_297", twin = "s_69a739e6" },
	{ line = 855, screen = "mission4_accept_b", field = "leftDialog", link = nil, nge = "s_299", twin = "s_abf08a18" },
	{ line = 962, screen = "s_fc6dfba9", field = 1, link = "s_58e80738", nge = "s_325", twin = "s_d9cced1f" },
	{ line = 963, screen = "s_fc6dfba9", field = 2, link = "s_347", nge = "s_345", twin = "s_73313039" },
	{ line = 975, screen = "s_347", field = "leftDialog", link = nil, nge = "s_347", twin = "s_28d914fc" },
	{ line = 977, screen = "s_347", field = 1, link = "s_351", nge = "s_349", twin = "s_42880861" },
	{ line = 1011, screen = "s_337", field = "leftDialog", link = nil, nge = "s_337", twin = "s_dc241019" },
	{ line = 1069, screen = "s_351", field = "leftDialog", link = nil, nge = "s_351", twin = "s_dc241019" },
	{ line = 1072, screen = "s_351", field = 1, link = "s_355", nge = "s_353", twin = "s_48529763" },
	{ line = 1077, screen = "s_355", field = "leftDialog", link = nil, nge = "s_355", twin = "s_f13513cd" },
	{ line = 1079, screen = "s_355", field = 1, link = "s_359", nge = "s_357", twin = "s_c3363bcd" },
	{ line = 1084, screen = "s_359", field = "leftDialog", link = nil, nge = "s_359", twin = "s_dc241019" },
	{ line = 1087, screen = "s_359", field = 1, link = "s_363", nge = "s_361", twin = "s_539f9a2e" },
	{ line = 1092, screen = "s_363", field = "leftDialog", link = nil, nge = "s_363", twin = "s_e3e480fe" },
	{ line = 1095, screen = "s_363", field = 1, link = "s_367", nge = "s_365", twin = "s_7e602d1b" },
	{ line = 1100, screen = "s_367", field = "leftDialog", link = nil, nge = "s_367", twin = "s_6429f86b" },
	{ line = 1102, screen = "s_367", field = 1, link = "s_371", nge = "s_369", twin = "s_8e9d0848" },
	{ line = 1107, screen = "s_371", field = "leftDialog", link = nil, nge = "s_371", twin = "s_9bbb9999" },
	{ line = 1118, screen = "s_386", field = "leftDialog", link = nil, nge = "s_386", twin = "s_dc241019" },
	{ line = 1121, screen = "s_386", field = 1, link = "s_390", nge = "s_388", twin = "s_48529763" },
	{ line = 1126, screen = "s_390", field = "leftDialog", link = nil, nge = "s_390", twin = "s_f13513cd" },
	{ line = 1128, screen = "s_390", field = 1, link = "s_394", nge = "s_392", twin = "s_c3363bcd" },
	{ line = 1133, screen = "s_394", field = "leftDialog", link = nil, nge = "s_394", twin = "s_dc241019" },
	{ line = 1136, screen = "s_394", field = 1, link = "s_398", nge = "s_396", twin = "s_539f9a2e" },
	{ line = 1141, screen = "s_398", field = "leftDialog", link = nil, nge = "s_398", twin = "s_e3e480fe" },
	{ line = 1144, screen = "s_398", field = 1, link = "s_402", nge = "s_400", twin = "s_7e602d1b" },
	{ line = 1149, screen = "s_402", field = "leftDialog", link = nil, nge = "s_402", twin = "s_6429f86b" },
	{ line = 1151, screen = "s_402", field = 1, link = "s_406", nge = "s_404", twin = "s_8e9d0848" },
	{ line = 1156, screen = "s_406", field = "leftDialog", link = nil, nge = "s_406", twin = "s_9bbb9999" },
}

D.TWIN = {}

for _, site in ipairs(D.SITES) do
	assert(D.TWIN[site.nge] == nil or D.TWIN[site.nge] == site.twin, "inconsistent twin for " .. site.nge)
	D.TWIN[site.nge] = site.twin
end

D.TEXT = {
	s_11769c29 = "Sure! I wasn't ALWAYS an old man, you know. I used to have a few more marbles rolling around upstairs. Now go on; get out of here.",
	s_127f2e23 = "You're going to kidnap one of their technical supervisors. He knows the plan. And pretty soon, you'll know the plan as well!",
	s_1bb2f893 = "They're using my men because they know every inch of Dathomir space. They'll run rings around those Imperials. I suggest you follow their every move. I trained them all myself.",
	s_28d914fc = "Well listen up. We are dealing with several situations here, and I'd like to see what you can do. First of all, the Black Suns have been taking a lot of business from us lately. Nym doesn't like it. We need a pilot to send them a message. A LOUD message. Heh!",
	s_29544149 = "Then why send an Inquisitor?",
	s_31fd5acf = "Of course it's smart! It was my idea. Now listen up. Your first objective is to find out what route those Imperial freighters plan to use.",
	s_37e345fe = "Have you ever seen an Inquisitor up close?",
	s_410d920c = "Alright, let's do this!",
	s_42880861 = "Okay...",
	s_48529763 = "I said, 'Okay'!",
	s_50669846 = "Apparently, the Empire's had just about enough of our activities in the area. I don't know who they hate more, smugglers or Rebels.",
	s_526ce515 = "Negative! They outgun YOU, too. Don't try to blast them to smithereens. Just hold them off long enough to give our mining vessels the time they need to escape.",
	s_53544796 = "Sounds like a problem.",
	s_539f9a2e = "Nothing!",
	s_6429f86b = "Here's some MORE good news. Another group of our men infiltrated a number of Imperial troop transports in the Endor system. But they can't take control of those ships - not yet. First we need a pilot to disable the transport controls. This requires a pilot with skills.",
	s_69a739e6 = "Where do I find this guy?",
	s_73313039 = "Really, I just want to work.",
	s_77e48d5b = "What do you mean?",
	s_7ae51280 = "You did?",
	s_7e602d1b = "I'm not!",
	s_841d27db = "Why?",
	s_8729f60e = "Smart.",
	s_882e7ab9 = "Well, the Empire has no idea what the Alliance has planned, thanks to you.",
	s_8cac3c56 = "I thought you would! Now you don't have to take the whole base apart. You're just going to pave the way for an Alliance B-Wing squadron. They've had their sights set on this base for a while.",
	s_8e9d0848 = "[nod]",
	s_900f01d1 = "What?",
	s_98199797 = "Why is the Alliance sending pirates? This sounds like strictly a Rebel operation.",
	s_99d3b4fd = "What have you got for me?",
	s_9a01b8f2 = "Once...a long, long time ago. Let's not talk about it right now. I want you to kill that Inquisitor before he reaches the Imperial fleet in Dathomir.",
	s_9a626852 = "Same difference to them.",
	s_9bbb9999 = "Hm, what else is there? Oh yes...you'll like this, it's a Rebel rescue mission! A Rebel fleet was carrying several scientists through the Dantooine system, they were ambushed by Imperial fighters! That's not right. I want a pilot to get out there and help those ships escape before more Imperial ships arrive! And that's it! So what's it going to be, junior?",
	s_9d0a2207 = "Should I target the Black Suns directly?",
	s_a434ad25 = "One more thing Rebel. All the missions I provide you with will be high risk missions and might be too much to handle by yourself. If you have any favors you can call in, doing so during my missions might be a good idea.",
	s_a6e1a5f4 = "That's because it's top secret! In the meantime, let's keep gunning for the Empire. You're going to Dathomir. I want you to join some of my men on a guerilla strike against an Imperial base.",
	s_a9e4fd02 = "How do I do that?",
	s_abf08a18 = "Check your ship's computer. All the information you need is there. Good luck.",
	s_b607bb2e = "Yep. A BIG one. We can't let them build that station. So here's the plan! We're going to destroy the station components while they're en route to Lok.",
	s_bed0dfe7 = "I like that!",
	s_c3363bcd = "Uh huh.",
	s_c95dbd1 = "They're outgunned! So we need to help them out.",
	s_c985b91 = "I said, 'Why?'",
	s_d06c9b96 = "Even I don't know what the Alliance has planned.",
	s_d6f2e64d = "What am I, a mind reader? They're probably concerned about Alliance attacks.",
	s_d98a6441 = "Apparently, the Black Suns are preparing to launch an assault on one of our mining interests in the Dathomir system.",
	s_d9cced1f = "Absolutely.",
	s_dc241019 = "What'd you say?",
	s_e3e480fe = "Don't smart off to me!",
	s_e93fce3e = "You're probably right, %NU. We've received word that they're planning to build a space station in the Lok system. They'll use it to monitor all the activity in the area.",
	s_eb1c3d4e = "Are you crazy? No one can kill an Inquisitor!",
	s_f13513cd = "Hmph! Well here's some good news. One of our men has raided an Imperial outpost on Dathomir and he walked away with plenty of loot. Now all he has to do is escape! Easier said than done, of course, as the Empire wants their things back. So you could escort our man out of Dathomir...",
	s_f3603d67 = "Don't talk back to me, junior! And don't be ridiculous! The Inquisitors are mortal, like the rest of us. Believe me, they CAN be killed. I know that for a fact. Now I want you to get out there, immediately!",
	s_f59d9106 = "Well, %TU, think about it. The Empire needs to know what the Alliance is planning. And no one is better at gathering information than an Inquisitor.",
	s_f5cc7cf3 = "Can't the vessels defend themselves?",
	s_ff9fae78 = "What kind of question is that?",
}

D.TRAINING_TEXT = {
	s_2a5db9a8 = "I would like hyper-maneuverable starfighters, please.",
	s_2efd90c2 = "I didn't shout!",
	s_6065ab8b = "I would like special weapons and tactics, please.",
	s_62c873d4 = "Are you sure? Well too late it's yours now! Haha I'm just teasing you! That is a fine skill... for a NERF-HERDER! Now go on, get out of here!",
	s_650af8ec = "Don't tell ME what you did! Now go on, make yourself useful!",
	s_66d4c0f2 = "You don't have to shout! I've never seen anybody so excited about starships.",
	s_69020482 = "I did!",
	s_77758001 = "I would like heavy starship component use, please.",
	s_7d2fc507 = "Say please!",
	s_ba9df4a6 = "Oh all right. Here you go. Now go away and stop bothering me.",
	s_ecfe38f9 = "Oh! Well, here you go. Bye now!",
	s_f819adf9 = "I would like droid intelligence theory, please.",
}

-- Appendix D: sids shown on more than one screen after the feature (every other leftDialog sid is on exactly one screen)
D.LEFT_COUNTS = {
	s_dc241019 = 6,
	s_900f01d1 = 3, s_526ce515 = 3, s_11769c29 = 3,
	s_a434ad25 = 3, s_8cac3c56 = 3, s_1bb2f893 = 3, s_f13513cd = 3, s_e3e480fe = 3, s_6429f86b = 3, s_9bbb9999 = 3,
	s_f3603d67 = 2, s_abf08a18 = 2, s_d98a6441 = 2, s_c95dbd1 = 2, s_d6f2e64d = 2, s_f59d9106 = 2, s_9a01b8f2 = 2, s_ff9fae78 = 2, s_882e7ab9 = 2, s_a6e1a5f4 = 2,
	s_50669846 = 2, s_e93fce3e = 2, s_b607bb2e = 2, s_31fd5acf = 2, s_127f2e23 = 2, s_28d914fc = 2,
}

-- The screens that share s_dc241019 ("What'd you say?"), Appendix D
D.DC241019_SCREENS = { "s_337", "s_351", "s_359", "s_386", "s_394", "s_dc241019" }

D.DELETED = { "train_starships", "train_weapons", "train_procedures", "train_droid", "s_431", "s_437" }
D.ADDED = { "trained_starships_end", "trained_weapons_end" }

-- Content contract 1b, in this order: { id, leftDialog sid, animation ("" = none), stop, options = { { reply sid, link } } }
D.TRAINING = {
	{ id = "trained_starships", sid = "s_66d4c0f2", animation = "", stop = false, options = { { "s_2efd90c2", "trained_starships_end" } } },
	{ id = "trained_starships_end", sid = "s_ecfe38f9", animation = "", stop = true, options = {} },
	{ id = "trained_weapons", sid = "s_7d2fc507", animation = "", stop = false, options = { { "s_69020482", "trained_weapons_end" } } },
	{ id = "trained_weapons_end", sid = "s_650af8ec", animation = "", stop = true, options = {} },
	{ id = "trained_procedures", sid = "s_62c873d4", animation = "", stop = true, options = {} },
	{ id = "trained_droid", sid = "s_ba9df4a6", animation = "giveup", stop = true, options = {} },
}

-- Content contract 2: { skill, reply, acknowledgment screen }, in SWG order
D.TRAIN_CHOICES = {
	{ "pilot_rebel_navy_starships_04", "@conversation/corellia_rebel_tier4:s_2a5db9a8", "trained_starships" },
	{ "pilot_rebel_navy_weapons_04", "@conversation/corellia_rebel_tier4:s_77758001", "trained_weapons" },
	{ "pilot_rebel_navy_procedures_04", "@conversation/corellia_rebel_tier4:s_6065ab8b", "trained_procedures" },
	{ "pilot_rebel_navy_droid_04", "@conversation/corellia_rebel_tier4:s_f819adf9", "trained_droid" },
}

-- Appendix E: the replacement training block, one entry per line (LF between them). Tabs as in the file.
D.BLOCK = {
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_starships\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_66d4c0f2\", -- You don't have to shout! I've never seen anybody so excited about starships.",
	"\toptions = {",
	"\t\t{\"@conversation/corellia_rebel_tier4:s_2efd90c2\", \"trained_starships_end\"}, -- I didn't shout!",
	"\t}",
	"})",
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_starships_end\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_ecfe38f9\", -- Oh! Well, here you go. Bye now!",
	"\tstopConversation = \"true\",",
	"\toptions = {}",
	"})",
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_weapons\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_7d2fc507\", -- Say please!",
	"\toptions = {",
	"\t\t{\"@conversation/corellia_rebel_tier4:s_69020482\", \"trained_weapons_end\"}, -- I did!",
	"\t}",
	"})",
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_weapons_end\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_650af8ec\", -- Don't tell ME what you did! Now go on, make yourself useful!",
	"\tstopConversation = \"true\",",
	"\toptions = {}",
	"})",
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_procedures\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_62c873d4\", -- Are you sure? Well too late it's yours now! Haha I'm just teasing you! That is a fine skill... for a NERF-HERDER! Now go on, get out of here!",
	"\tstopConversation = \"true\",",
	"\toptions = {}",
	"})",
	"arkon_convo:addScreen(ConvoScreen:new {",
	"\tid = \"trained_droid\",",
	"\tleftDialog = \"@conversation/corellia_rebel_tier4:s_ba9df4a6\", -- Oh all right. Here you go. Now go away and stop bothering me.",
	"\tanimation = \"giveup\",",
	"\tstopConversation = \"true\",",
	"\toptions = {}",
	"})",
}

-- Content contract 2: the handler lines 52-59 after the feature (LF between them)
D.HANDLER_LINES = {
	"-- Pre-NGE free choice of the next skill: { skill, reply, acknowledgment screen }, in SWG order.",
	"-- The replies are Arkon's pre-NGE client lines (space-convo-client-strings-arkon).",
	"arkonConvoHandler.TRAIN_CHOICES = {",
	"\t{ \"pilot_rebel_navy_starships_04\", \"@conversation/corellia_rebel_tier4:s_2a5db9a8\", \"trained_starships\" },",
	"\t{ \"pilot_rebel_navy_weapons_04\", \"@conversation/corellia_rebel_tier4:s_77758001\", \"trained_weapons\" },",
	"\t{ \"pilot_rebel_navy_procedures_04\", \"@conversation/corellia_rebel_tier4:s_6065ab8b\", \"trained_procedures\" },",
	"\t{ \"pilot_rebel_navy_droid_04\", \"@conversation/corellia_rebel_tier4:s_f819adf9\", \"trained_droid\" }",
	"}",
}

-- Base (f637c689a0) line ranges that are replaced: the training block of arkon_convo.lua and the TRAIN_CHOICES lines of arkonConvoHandler.lua
D.BLOCK_FROM, D.BLOCK_TO = 859, 925
D.HANDLER_FROM, D.HANDLER_TO = 52, 59

-- Line counts after the feature (AC: 1414 - 67 + 39; AH unchanged)
D.AC_LINES, D.AH_LINES = 1386, 346

return D
