-- Shared data of the Imler part 2 client-string work (space-convo-client-strings-imler-b, F6b, .claude/work/space-convo-client-strings-imler-b/01-spec.md).
-- Copied from the spec (Content contract 1 and 4, Appendix A, B, D, G and P), not read from imler_convo.lua, so a wrong production value fails a test instead of agreeing with itself.
-- Generated from the spec tables by a scratch script and then reviewed; edit by hand only to follow a spec revision.
--   D.BASE            the commit the "nothing else moves" checks compare with
--   D.BRIEF_OPTIONS   Appendix G: the options of the four brief screens, { reply, link } in order; D.BRIEF_NPC their (unchanged) lines
--   D.SCREENS         Appendix G: the 62 new screens { id, sid, anim (grant screens only), text, mission, row, options = { { reply, link }, ... } } in FILE order (rows 54-62, 35-53, 17-34, 1-16)
--   D.TEXT            sid -> client text (trailing whitespace trimmed) of the 126 pool ids; D.BRIEF_TEXT the 4 unchanged brief lines; D.TRAILING the ids whose STF text ends in one space
--   D.GRANTS          grant screen -> mission; D.PATHS Appendix P: grant screen -> reply sids from the brief
--   D.REMOVED         Appendix D: the 91 removed screen ids
--   D.REPLACED        the two replaced base line ranges of imler_convo.lua (Content contract 1)

local D = {}

D.BASE = "8c4e07808b"
D.PREFIX = "@conversation/naboo_privateer_tier4:"
D.FILE = "conversation/naboo_privateer_tier4"
D.BASE_LINES = 1337
D.AC_LINES = 1035
D.SCREEN_COUNT = 138
D.IH_LINES = 391

D.BRIEF_ORDER = { "mission4_brief", "mission3_brief", "mission2_brief", "mission1_brief" } -- the briefs' file order

D.BRIEF_NPC = {
	mission1_brief = "s_9312a850",
	mission2_brief = "s_bdc28bb4",
	mission3_brief = "s_ff6e1247",
	mission4_brief = "s_e4bbe441",
}

D.BRIEF_TEXT = {
	s_9312a850 = "So. How was life with Commander Delios?",
	s_bdc28bb4 = "You did a nice job protecting that scan vessel. We took a look at the tapes.",
	s_ff6e1247 = "Those Black Suns didn't like the fact you found their secret cargo.",
	s_e4bbe441 = "I think the Black Suns have declared war on the RSF.",
}

-- Appendix A: the 9 brief option lines, { base line, brief, index }
D.BRIEF_LINES = {
	{ 296, "mission4_brief", 1 }, { 297, "mission4_brief", 2 },
	{ 304, "mission3_brief", 1 }, { 305, "mission3_brief", 2 }, { 306, "mission3_brief", 3 },
	{ 313, "mission2_brief", 1 }, { 314, "mission2_brief", 2 },
	{ 321, "mission1_brief", 1 }, { 322, "mission1_brief", 2 },
}

D.BRIEF_OPTIONS = {
	mission1_brief = {
		{ "s_68441a06", "s_3d333deb" }, -- Action packed.
		{ "s_6cee1a83", "s_ebb2f602" }, -- Not so much.
	},
	mission2_brief = {
		{ "s_39500c68", "s_f803a81b" }, -- What did you find?
		{ "s_841d27db", "s_105bb565" }, -- Why?
	},
	mission3_brief = {
		{ "s_3210ae50", "s_2035fbe6" }, -- Haha! They sure did.
		{ "s_5b5570cd", "s_55453170" }, -- I didn't like the fact they tried to kill me.
		{ "s_9d4ab52b", "s_ebcc7726" }, -- What was the cargo?
	},
	mission4_brief = {
		{ "s_e9ea6fec", "s_76701ff2" }, -- Good. Because I want to go after them.
		{ "s_983ebe8d", "s_3af6b354" }, -- They're going after the RSF pretty hard.
	},
}

D.SCREENS = {
	{ id = "s_3af6b354", sid = "s_3af6b354", mission = 4, row = 54,
		text = "No, my friend. They're going against YOU pretty hard. You're good at what you do. And that means you're getting in their way. Black Suns don't like people getting in their way.",
		options = {
			{ "s_cdbde300", "s_16106529" }, -- Well I'm not going to stop.
		},
	},
	{ id = "s_16106529", sid = "s_16106529", mission = 4, row = 55,
		text = "Well, this is a new problem in Yavin. We'll just have to deal with it. I'm not going to wait for them to come to us.",
		options = {
			{ "s_63e5cad0", "s_fd271a84" }, -- Send me out there.
		},
	},
	{ id = "s_76701ff2", sid = "s_76701ff2", mission = 4, row = 56,
		text = "You're about to get your wish. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots up around Yavin in a sortie against the Black Sun.",
		options = {
			{ "s_63c379c4", "s_2271ff14" }, -- These other pilots. Are they any good?
		},
	},
	{ id = "s_fd271a84", sid = "s_fd271a84", mission = 4, row = 57,
		text = "You read my mind. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots in a sortie against the Black Sun.",
		options = {
			{ "s_63c379c4", "s_80714a31" }, -- These other pilots. Are they any good?
		},
	},
	{ id = "s_2271ff14", sid = "s_2271ff14", mission = 4, row = 58,
		text = "I think so. But you can be the judge of that.",
		options = {
			{ "s_bbd611b4", "s_237b421d" }, -- What about the Imperials?
		},
	},
	{ id = "s_80714a31", sid = "s_80714a31", mission = 4, row = 59,
		text = "I think so. But you can be the judge of that. Ready to go?",
		options = {
			{ "s_eb2cfdac", "mission4_accept_a" }, -- You bet.
		},
	},
	{ id = "s_237b421d", sid = "s_237b421d", mission = 4, row = 60,
		text = "They're not going to get involved. They've got other things to worry about. You just take care of those Black Suns. Ready to go?",
		options = {
			{ "s_556c01dc", "mission4_accept_b" }, -- Just get me up there.
		},
	},
	{ id = "mission4_accept_a", sid = "s_9281abbb", mission = 4, row = 61, anim = "salute1",
		text = "Go get 'em, tiger.",
		options = {
		},
	},
	{ id = "mission4_accept_b", sid = "s_8a0c5ce7", mission = 4, row = 62, anim = "salute1",
		text = "I'll talk to you when you get back.",
		options = {
		},
	},
	{ id = "s_2035fbe6", sid = "s_2035fbe6", mission = 3, row = 35,
		text = "You're lucky you made it back in one piece.",
		options = {
			{ "s_db51959a", "s_f453a7fa" }, -- Luck had nothing to do with it.
		},
	},
	{ id = "s_f453a7fa", sid = "s_f453a7fa", mission = 3, row = 36,
		text = "I like your attitude. I was right about that freighter, wasn't I?",
		options = {
			{ "s_27e6d728", "s_840f4ebe" }, -- You were right. They were packed to the gills with contraband.
		},
	},
	{ id = "s_840f4ebe", sid = "s_840f4ebe", mission = 3, row = 37,
		text = "What can I say? I've got a nose for these kinds of  things.",
		options = {
			{ "s_9d4ab52b", "s_ebcc7726" }, -- What was the cargo?
		},
	},
	{ id = "s_55453170", sid = "s_55453170", mission = 3, row = 38,
		text = "Not this time. But they'll try again.",
		options = {
			{ "s_cdbde300", "s_4cae7d37" }, -- Well I'm not going to stop.
			{ "s_9299cabe", "s_27cad067" }, -- What's going on with the Black Suns?
		},
	},
	{ id = "s_27cad067", sid = "s_27cad067", mission = 3, row = 39,
		text = "Don't think I can help you there.",
		options = {
			{ "s_7f9b8387", "s_720204b2" }, -- Why not?
		},
	},
	{ id = "s_4cae7d37", sid = "s_4cae7d37", mission = 3, row = 40,
		text = "Of course not. Forget about them for now. I have a new mission for you.",
		options = {
			{ "s_1adbadc4", "s_b5ee61ed" }, -- I'm ready.
		},
	},
	{ id = "s_720204b2", sid = "s_720204b2", mission = 3, row = 41,
		text = "Let me worry about the Black Suns. I have a new mission for you.",
		options = {
			{ "s_a11918f3", "s_b5ee61ed" }, -- OK.
		},
	},
	{ id = "s_ebcc7726", sid = "s_ebcc7726", mission = 3, row = 42,
		text = "'Materials for an explosives plant. If they had moved them into this system undetected... well, they didn't. That's all that matters.",
		options = {
			{ "s_dfb50fb1", "s_41799e3b" }, -- I think you're right.
		},
	},
	{ id = "s_41799e3b", sid = "s_41799e3b", mission = 3, row = 43,
		text = "You did good. I have a new mission for you.",
		options = {
			{ "s_8289ab5b", "s_b5ee61ed" }, -- I'm ready for my next mission.
		},
	},
	{ id = "s_b5ee61ed", sid = "s_b5ee61ed", mission = 3, row = 44,
		text = "A pair of Imperial freighters have entered Yavin space. They need a go-between for a supply transfer. And that go-between would be you.",
		options = {
			{ "s_c290ec08", "s_9252108e" }, -- Imperials!
			{ "s_5b6fb4cf", "s_539c8d41" }, -- Why? For what reason?
		},
	},
	{ id = "s_539c8d41", sid = "s_539c8d41", mission = 3, row = 45,
		text = "The head honchos like to know EVERYTHING happening in this system. You must have figured  that out by now.",
		options = {
			{ "s_fb1b0124", "s_4e740301" }, -- They're paranoid, I know that.
		},
	},
	{ id = "s_4e740301", sid = "s_4e740301", mission = 3, row = 46,
		text = "You would be, too, if half the galaxy was gunning for you. And besides, the Imperials are awfully active down here.",
		options = {
			{ "s_fadf51b5", "s_9252108e" }, -- Imperials.
		},
	},
	{ id = "s_9252108e", sid = "s_9252108e", mission = 3, row = 47,
		text = "Not your favorites, I take it?",
		options = {
			{ "s_a2989575", "s_841d27db" }, -- They're lowlifes.
			{ "s_f4146fa1", "s_babb0d0c" }, -- Lowlifes with guns.
		},
	},
	{ id = "s_841d27db", sid = "s_841d27db", mission = 3, row = 48,
		text = "Why?",
		options = {
			{ "s_a5795662", "s_917f4150" }, -- Because they're bloodthirsty lunatics, I guess.
		},
	},
	{ id = "s_917f4150", sid = "s_917f4150", mission = 3, row = 49,
		text = "Well THAT'S not a good enough reason! You're pretty bloodthirsty, too.",
		options = {
			{ "s_f0583774", "s_babb0d0c" }, -- Yeah, but...well...
			{ "s_1f2b0388", "s_babb0d0c" }, -- Not any more.
		},
	},
	{ id = "s_babb0d0c", sid = "s_babb0d0c", mission = 3, row = 50,
		text = "Look, this isn't an ethics class. We're all just here to do our job.",
		options = {
			{ "s_ba8f5de7", "s_7378bc13" }, -- I see what you're saying.
		},
	},
	{ id = "s_7378bc13", sid = "s_7378bc13", mission = 3, row = 51,
		text = "You know how testy Imperial freighter captains can be. They think they own the universe. Especially these two. They're a real couple of killjoys. But they're our friends, so make nice, OK?",
		options = {
			{ "s_3fdc63be", "mission3_accept_a" }, -- Because we love the Empire so much.
			{ "s_18a76ec8", "mission3_accept_a" }, -- Who cares what they think?
			{ "s_e4399cac", "mission3_accept_b" }, -- What about the Black Suns?
		},
	},
	{ id = "mission3_accept_a", sid = "s_ff66ed8b", mission = 3, row = 52, anim = "wave_on_dismissing",
		text = "You don't have  to love 'em. You just have to keep 'em happy. Get out there and take care of those captains.",
		options = {
		},
	},
	{ id = "mission3_accept_b", sid = "s_48621561", mission = 3, row = 53, anim = "wave_on_dismissing",
		text = "What about  them? Look, they don't bother us, we don't bother them. Right now, Imperial happiness is your only concern. Get out there and take care of those captains.",
		options = {
		},
	},
	{ id = "s_f803a81b", sid = "s_f803a81b", mission = 2, row = 17,
		text = "Nothing definite. Black Suns know how to cover their tracks. But they're definitely active in this system. And that's a problem, considering the Imperial crackdown.",
		options = {
			{ "s_c0540c7f", "s_d56fe8b0" }, -- What Imperial crackdown?
		},
	},
	{ id = "s_d56fe8b0", sid = "s_d56fe8b0", mission = 2, row = 18,
		text = "Boy, where have YOU been? The Empire's tightening the leash.",
		options = {
			{ "s_841d27db", "s_d3c9b4d0" }, -- Why?
		},
	},
	{ id = "s_d3c9b4d0", sid = "s_d3c9b4d0", mission = 2, row = 19,
		text = "Beats me! Something about trouble with the prison. And word is that the Vortex is gunning for the Inquisitors.",
		options = {
			{ "s_ec5dca32", "s_c60b4787" }, -- Vortex? Inquisitors?
		},
	},
	{ id = "s_c60b4787", sid = "s_c60b4787", mission = 2, row = 20,
		text = "Hey! You want to know more, ask somebody who cares. All I know is, They want everything in this system to be ship-shape. No illegal activity of any kind. And of course we are going to comply.",
		options = {
			{ "s_77e48d5b", "s_3c53afd8" }, -- What do you mean?
		},
	},
	{ id = "s_3c53afd8", sid = "s_3c53afd8", mission = 2, row = 21,
		text = "I mean, the Empire's number one problem is that prison, but their radar is up, if you know what I mean. They're looking for trouble across the board. So we're going  to watch our step. We're going to watch everybody ELSE'S steps, too.",
		options = {
			{ "s_fc00cf40", "s_9145ef83" }, -- I see what you mean.
		},
	},
	{ id = "s_105bb565", sid = "s_105bb565", mission = 2, row = 22,
		text = "The head honchos like to know EVERYTHING that happens in this system. You must have figured  that out by now.",
		options = {
			{ "s_3c9a53fb", "s_c5eae735" }, -- I've noticed.
		},
	},
	{ id = "s_c5eae735", sid = "s_c5eae735", mission = 2, row = 23,
		text = "Then maybe you've noticed that the Imperials aren't exactly tolerant of troublemakers. They'll stay out of our hair, as long as we keep running a tight ship.",
		options = {
			{ "s_85a73c8b", "s_9e779014" }, -- So do you have a mission for me?
		},
	},
	{ id = "s_9145ef83", sid = "s_9145ef83", mission = 2, row = 24,
		text = "Listen. There's a heavy mining freighter passing through Endor space.",
		options = {
			{ "s_25f8ac14", "s_88678c75" }, -- What's it carrying?
			{ "s_d9177ade", "s_31c66e02" }, -- This is another escort mission?
		},
	},
	{ id = "s_9e779014", sid = "s_9e779014", mission = 2, row = 25,
		text = "Always. There's a heavy mining freighter passing through Endor space.",
		options = {
			{ "s_25f8ac14", "s_88678c75" }, -- What's it carrying?
			{ "s_d9177ade", "s_31c66e02" }, -- This is another escort mission?
		},
	},
	{ id = "s_88678c75", sid = "s_88678c75", mission = 2, row = 26,
		text = "Supplies, a few passengers, nothing special.",
		options = {
			{ "s_963212ec", "s_4d02fd15" }, -- OK...
		},
	},
	{ id = "s_4d02fd15", sid = "s_4d02fd15", mission = 2, row = 27,
		text = "That's what they SAY they're carrying. But I'm not so sure. I'd like you to take a closer look.",
		options = {
			{ "s_8462774c", "s_87246f3e" }, -- So I should inspect the ship.
		},
	},
	{ id = "s_31c66e02", sid = "s_31c66e02", mission = 2, row = 28,
		text = "Not exactly. Since the Black Suns are willing to fight RSF pilots, they must have something to hide. So we're going to start taking a closer look at all activity in this system.",
		options = {
			{ "s_79387096", "s_ba2102e3" }, -- An inspect mission?
		},
	},
	{ id = "s_87246f3e", sid = "s_87246f3e", mission = 2, row = 29,
		text = "You got it. Go check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.",
		options = {
			{ "s_89aa28bd", "s_aa07a17b" }, -- Any idea what I should be looking for?
		},
	},
	{ id = "s_ba2102e3", sid = "s_ba2102e3", mission = 2, row = 30,
		text = "You got it. So check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.",
		options = {
			{ "s_89aa28bd", "s_aa07a17b" }, -- Any idea what I should be looking for?
		},
	},
	{ id = "s_aa07a17b", sid = "s_aa07a17b", mission = 2, row = 31,
		text = "Spice? Sliced weapons? Who knows. Anything's possible. And I mean ANYTHING. So keep your eyes open and your blasters primed.",
		options = {
			{ "s_9e7f84ea", "s_d9008914" }, -- I always do.
		},
	},
	{ id = "s_d9008914", sid = "s_d9008914", mission = 2, row = 32,
		text = "And listen. Don't be too gung-ho, okay? If you find some contraband, you know, tell me first.",
		options = {
			{ "s_84c002ae", "mission2_accept_a" }, -- Looking for a taste?
			{ "s_2836e6b5", "mission2_accept_b" }, -- OK.
		},
	},
	{ id = "mission2_accept_a", sid = "s_e7515ed5", mission = 2, row = 33, anim = "dismiss",
		text = "Go on. I'm busy. I've got things to do.",
		options = {
		},
	},
	{ id = "mission2_accept_b", sid = "s_90422eb5", mission = 2, row = 34, anim = "dismiss",
		text = "Good luck.",
		options = {
		},
	},
	{ id = "s_3d333deb", sid = "s_3d333deb", mission = 1, row = 1,
		text = "Well, you'll get more of the same here, if you're lucky. Are you a good pilot?",
		options = {
			{ "s_d9cced1f", "s_cab61bc8" }, -- Absolutely.
			{ "s_5277eec5", "s_ab0e62" }, -- You tell me.
		},
	},
	{ id = "s_cab61bc8", sid = "s_cab61bc8", mission = 1, row = 2,
		text = "I've met pilots like you before. Raring to go. It's pilots like you that die first.",
		options = {
			{ "s_afec8242", "s_d6a8a04d" }, -- Not THIS pilot.
		},
	},
	{ id = "s_d6a8a04d", sid = "s_d6a8a04d", mission = 1, row = 3,
		text = "Oo. I can't wait to see you in action.",
		options = {
			{ "s_e5235eff", "s_a82676b8" }, -- Do you have a mission for me?
		},
	},
	{ id = "s_ab0e62", sid = "s_ab0e62", mission = 1, row = 4,
		text = "Mm!  Good answer, %TU.I should warn you, though. I don't like telling people what I'm thinking.",
		options = {
			{ "s_65f98b49", "s_df2f398b" }, -- Maybe you'll make an exception for me.
		},
	},
	{ id = "s_df2f398b", sid = "s_df2f398b", mission = 1, row = 5,
		text = "Don't hold your breath. We're wasting time here. I have a mission for you.",
		options = {
			{ "s_d9177ade", "s_a284d393" }, -- This is another escort mission?
		},
	},
	{ id = "s_ebb2f602", sid = "s_ebb2f602", mission = 1, row = 6,
		text = "He didn't dazzle you with his charm?",
		options = {
			{ "s_a087e986", "s_e4254ae2" }, -- Not exactly.
			{ "s_e87166ba", "s_d76f1ea3" }, -- He'd like to start a one-man war against the Gungans.
		},
	},
	{ id = "s_e4254ae2", sid = "s_e4254ae2", mission = 1, row = 7,
		text = "Aw, come on. That guy's harmless. I like his negative attitude. It cheers me up.",
		options = {
			{ "s_d1f589da", "s_d76f1ea3" }, -- Ridiculous.
			{ "s_2befd882", "s_d76f1ea3" }, -- Well...
		},
	},
	{ id = "s_d76f1ea3", sid = "s_d76f1ea3", mission = 1, row = 8,
		text = "What do you expect? He's a lifer here on Naboo. It's all he knows. Maybe you're more enlightened.",
		options = {
			{ "s_dfb50fb1", "s_44b1cd3c" }, -- I think you're right.
		},
	},
	{ id = "s_44b1cd3c", sid = "s_44b1cd3c", mission = 1, row = 9,
		text = "Mm. We'll see. Let's get you going on a new mission.",
		options = {
			{ "s_9a74f227", "s_a284d393" }, -- So I see. This one's an escort job.
		},
	},
	{ id = "s_a284d393", sid = "s_a284d393", mission = 1, row = 10,
		text = "Something like that.",
		options = {
			{ "s_d7ffd6a9", "s_a224e8fe" }, -- What am I escorting?
		},
	},
	{ id = "s_a82676b8", sid = "s_a82676b8", mission = 1, row = 11,
		text = "Royal Security Forces are using a deep space scan vessel in Endor space.",
		options = {
			{ "s_3f68df7d", "s_7cc97d1a" }, -- Sounds easy enough.
		},
	},
	{ id = "s_a224e8fe", sid = "s_a224e8fe", mission = 1, row = 12,
		text = "A deep space scan vessel. It's an RSF ship. We're using it to investigate Endor space.",
		options = {
			{ "s_2836e6b5", "s_9405f2ce" }, -- OK.
		},
	},
	{ id = "s_7cc97d1a", sid = "s_7cc97d1a", mission = 1, row = 13,
		text = "Well, apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.",
		options = {
			{ "s_9525d65c", "s_b47b0542" }, -- Any idea what the Black Suns are up to?
		},
	},
	{ id = "s_9405f2ce", sid = "s_9405f2ce", mission = 1, row = 14,
		text = "So apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.",
		options = {
			{ "s_9525d65c", "s_b47b0542" }, -- Any idea what the Black Suns are up to?
		},
	},
	{ id = "s_b47b0542", sid = "s_b47b0542", mission = 1, row = 15,
		text = "I don't know, and right now, I don't care. The only thing that matters right now is that deep space scan. It's an expensive piece of equipment. We'd hate to lose it.",
		options = {
			{ "s_9422ee24", "mission1_accept_a" }, -- You won't.
		},
	},
	{ id = "mission1_accept_a", sid = "s_42d6c3ee", mission = 1, row = 16, anim = "dismiss",
		text = "Go on. Your ship is waiting.",
		options = {
		},
	},
}

D.TEXT = {
	s_105bb565 = "The head honchos like to know EVERYTHING that happens in this system. You must have figured  that out by now.",
	s_16106529 = "Well, this is a new problem in Yavin. We'll just have to deal with it. I'm not going to wait for them to come to us.",
	s_18a76ec8 = "Who cares what they think?",
	s_1adbadc4 = "I'm ready.",
	s_1f2b0388 = "Not any more.",
	s_2035fbe6 = "You're lucky you made it back in one piece.",
	s_2271ff14 = "I think so. But you can be the judge of that.",
	s_237b421d = "They're not going to get involved. They've got other things to worry about. You just take care of those Black Suns. Ready to go?",
	s_25f8ac14 = "What's it carrying?",
	s_27cad067 = "Don't think I can help you there.",
	s_27e6d728 = "You were right. They were packed to the gills with contraband.",
	s_2836e6b5 = "OK.",
	s_2befd882 = "Well...",
	s_31c66e02 = "Not exactly. Since the Black Suns are willing to fight RSF pilots, they must have something to hide. So we're going to start taking a closer look at all activity in this system.",
	s_3210ae50 = "Haha! They sure did.",
	s_39500c68 = "What did you find?",
	s_3af6b354 = "No, my friend. They're going against YOU pretty hard. You're good at what you do. And that means you're getting in their way. Black Suns don't like people getting in their way.",
	s_3c53afd8 = "I mean, the Empire's number one problem is that prison, but their radar is up, if you know what I mean. They're looking for trouble across the board. So we're going  to watch our step. We're going to watch everybody ELSE'S steps, too.",
	s_3c9a53fb = "I've noticed.",
	s_3d333deb = "Well, you'll get more of the same here, if you're lucky. Are you a good pilot?",
	s_3f68df7d = "Sounds easy enough.",
	s_3fdc63be = "Because we love the Empire so much.",
	s_41799e3b = "You did good. I have a new mission for you.",
	s_42d6c3ee = "Go on. Your ship is waiting.",
	s_44b1cd3c = "Mm. We'll see. Let's get you going on a new mission.",
	s_48621561 = "What about  them? Look, they don't bother us, we don't bother them. Right now, Imperial happiness is your only concern. Get out there and take care of those captains.",
	s_4cae7d37 = "Of course not. Forget about them for now. I have a new mission for you.",
	s_4d02fd15 = "That's what they SAY they're carrying. But I'm not so sure. I'd like you to take a closer look.",
	s_4e740301 = "You would be, too, if half the galaxy was gunning for you. And besides, the Imperials are awfully active down here.",
	s_5277eec5 = "You tell me.",
	s_539c8d41 = "The head honchos like to know EVERYTHING happening in this system. You must have figured  that out by now.",
	s_55453170 = "Not this time. But they'll try again.",
	s_556c01dc = "Just get me up there.",
	s_5b5570cd = "I didn't like the fact they tried to kill me.",
	s_5b6fb4cf = "Why? For what reason?",
	s_63c379c4 = "These other pilots. Are they any good?",
	s_63e5cad0 = "Send me out there.",
	s_65f98b49 = "Maybe you'll make an exception for me.",
	s_68441a06 = "Action packed.",
	s_6cee1a83 = "Not so much.",
	s_720204b2 = "Let me worry about the Black Suns. I have a new mission for you.",
	s_7378bc13 = "You know how testy Imperial freighter captains can be. They think they own the universe. Especially these two. They're a real couple of killjoys. But they're our friends, so make nice, OK?",
	s_76701ff2 = "You're about to get your wish. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots up around Yavin in a sortie against the Black Sun.",
	s_77e48d5b = "What do you mean?",
	s_79387096 = "An inspect mission?",
	s_7cc97d1a = "Well, apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.",
	s_7f9b8387 = "Why not?",
	s_80714a31 = "I think so. But you can be the judge of that. Ready to go?",
	s_8289ab5b = "I'm ready for my next mission.",
	s_840f4ebe = "What can I say? I've got a nose for these kinds of  things.",
	s_841d27db = "Why?",
	s_8462774c = "So I should inspect the ship.",
	s_84c002ae = "Looking for a taste?",
	s_85a73c8b = "So do you have a mission for me?",
	s_87246f3e = "You got it. Go check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.",
	s_88678c75 = "Supplies, a few passengers, nothing special.",
	s_89aa28bd = "Any idea what I should be looking for?",
	s_8a0c5ce7 = "I'll talk to you when you get back.",
	s_90422eb5 = "Good luck.",
	s_9145ef83 = "Listen. There's a heavy mining freighter passing through Endor space.",
	s_917f4150 = "Well THAT'S not a good enough reason! You're pretty bloodthirsty, too.",
	s_9252108e = "Not your favorites, I take it?",
	s_9281abbb = "Go get 'em, tiger.",
	s_9299cabe = "What's going on with the Black Suns?",
	s_9405f2ce = "So apparently there are some Black Suns in the area, and they'd prefer to keep their activities private. So they're launching an attack against our vessel.",
	s_9422ee24 = "You won't.",
	s_9525d65c = "Any idea what the Black Suns are up to?",
	s_963212ec = "OK...",
	s_983ebe8d = "They're going after the RSF pretty hard.",
	s_9a74f227 = "So I see. This one's an escort job.",
	s_9d4ab52b = "What was the cargo?",
	s_9e779014 = "Always. There's a heavy mining freighter passing through Endor space.",
	s_9e7f84ea = "I always do.",
	s_a087e986 = "Not exactly.",
	s_a11918f3 = "OK.",
	s_a224e8fe = "A deep space scan vessel. It's an RSF ship. We're using it to investigate Endor space.",
	s_a284d393 = "Something like that.",
	s_a2989575 = "They're lowlifes.",
	s_a5795662 = "Because they're bloodthirsty lunatics, I guess.",
	s_a82676b8 = "Royal Security Forces are using a deep space scan vessel in Endor space.",
	s_aa07a17b = "Spice? Sliced weapons? Who knows. Anything's possible. And I mean ANYTHING. So keep your eyes open and your blasters primed.",
	s_ab0e62 = "Mm!  Good answer, %TU.I should warn you, though. I don't like telling people what I'm thinking.",
	s_afec8242 = "Not THIS pilot.",
	s_b47b0542 = "I don't know, and right now, I don't care. The only thing that matters right now is that deep space scan. It's an expensive piece of equipment. We'd hate to lose it.",
	s_b5ee61ed = "A pair of Imperial freighters have entered Yavin space. They need a go-between for a supply transfer. And that go-between would be you.",
	s_ba2102e3 = "You got it. So check it out. And I don't mean one quick pass, either. Take a GOOD look. Because if they're carrying any contraband, we better find it before the Imperials do. Otherwise, the Empire might think we're pirate-friendly. And that would be a problem.",
	s_ba8f5de7 = "I see what you're saying.",
	s_babb0d0c = "Look, this isn't an ethics class. We're all just here to do our job.",
	s_bbd611b4 = "What about the Imperials?",
	s_c0540c7f = "What Imperial crackdown?",
	s_c290ec08 = "Imperials!",
	s_c5eae735 = "Then maybe you've noticed that the Imperials aren't exactly tolerant of troublemakers. They'll stay out of our hair, as long as we keep running a tight ship.",
	s_c60b4787 = "Hey! You want to know more, ask somebody who cares. All I know is, They want everything in this system to be ship-shape. No illegal activity of any kind. And of course we are going to comply.",
	s_cab61bc8 = "I've met pilots like you before. Raring to go. It's pilots like you that die first.",
	s_cdbde300 = "Well I'm not going to stop.",
	s_d1f589da = "Ridiculous.",
	s_d3c9b4d0 = "Beats me! Something about trouble with the prison. And word is that the Vortex is gunning for the Inquisitors.",
	s_d56fe8b0 = "Boy, where have YOU been? The Empire's tightening the leash.",
	s_d6a8a04d = "Oo. I can't wait to see you in action.",
	s_d76f1ea3 = "What do you expect? He's a lifer here on Naboo. It's all he knows. Maybe you're more enlightened.",
	s_d7ffd6a9 = "What am I escorting?",
	s_d9008914 = "And listen. Don't be too gung-ho, okay? If you find some contraband, you know, tell me first.",
	s_d9177ade = "This is another escort mission?",
	s_d9cced1f = "Absolutely.",
	s_db51959a = "Luck had nothing to do with it.",
	s_df2f398b = "Don't hold your breath. We're wasting time here. I have a mission for you.",
	s_dfb50fb1 = "I think you're right.",
	s_e4254ae2 = "Aw, come on. That guy's harmless. I like his negative attitude. It cheers me up.",
	s_e4399cac = "What about the Black Suns?",
	s_e5235eff = "Do you have a mission for me?",
	s_e7515ed5 = "Go on. I'm busy. I've got things to do.",
	s_e87166ba = "He'd like to start a one-man war against the Gungans.",
	s_e9ea6fec = "Good. Because I want to go after them.",
	s_eb2cfdac = "You bet.",
	s_ebb2f602 = "He didn't dazzle you with his charm?",
	s_ebcc7726 = "'Materials for an explosives plant. If they had moved them into this system undetected... well, they didn't. That's all that matters.",
	s_ec5dca32 = "Vortex? Inquisitors?",
	s_f0583774 = "Yeah, but...well...",
	s_f4146fa1 = "Lowlifes with guns.",
	s_f453a7fa = "I like your attitude. I was right about that freighter, wasn't I?",
	s_f803a81b = "Nothing definite. Black Suns know how to cover their tracks. But they're definitely active in this system. And that's a problem, considering the Imperial crackdown.",
	s_fadf51b5 = "Imperials.",
	s_fb1b0124 = "They're paranoid, I know that.",
	s_fc00cf40 = "I see what you mean.",
	s_fd271a84 = "You read my mind. But this time, you're not going alone. We need a show of force. You'll be joining a fleet of RSF pilots in a sortie against the Black Sun.",
	s_ff66ed8b = "You don't have  to love 'em. You just have to keep 'em happy. Get out there and take care of those captains.",
}

D.TRAILING = {s_2271ff14 = true, s_48621561 = true, s_4d02fd15 = true, s_4e740301 = true, s_55453170 = true, s_720204b2 = true, s_7cc97d1a = true, s_9405f2ce = true, s_9422ee24 = true, s_a087e986 = true, s_a11918f3 = true, s_a224e8fe = true, s_a2989575 = true, s_a82676b8 = true, s_ab0e62 = true, s_b5ee61ed = true, s_babb0d0c = true, s_d56fe8b0 = true, s_dfb50fb1 = true, s_ff66ed8b = true}

D.GRANTS = {
	mission1_accept_a = 1,
	mission2_accept_a = 2,
	mission2_accept_b = 2,
	mission3_accept_a = 3,
	mission3_accept_b = 3,
	mission4_accept_a = 4,
	mission4_accept_b = 4,
}

D.PATHS = {
	mission1_accept_a = { "s_68441a06", "s_d9cced1f", "s_afec8242", "s_e5235eff", "s_3f68df7d", "s_9525d65c", "s_9422ee24" },
	mission2_accept_a = { "s_841d27db", "s_3c9a53fb", "s_85a73c8b", "s_d9177ade", "s_79387096", "s_89aa28bd", "s_9e7f84ea", "s_84c002ae" },
	mission2_accept_b = { "s_841d27db", "s_3c9a53fb", "s_85a73c8b", "s_d9177ade", "s_79387096", "s_89aa28bd", "s_9e7f84ea", "s_2836e6b5" },
	mission3_accept_a = { "s_5b5570cd", "s_cdbde300", "s_1adbadc4", "s_c290ec08", "s_f4146fa1", "s_ba8f5de7", "s_3fdc63be" },
	mission3_accept_b = { "s_5b5570cd", "s_cdbde300", "s_1adbadc4", "s_c290ec08", "s_f4146fa1", "s_ba8f5de7", "s_e4399cac" },
	mission4_accept_a = { "s_983ebe8d", "s_cdbde300", "s_63e5cad0", "s_63c379c4", "s_eb2cfdac" },
	mission4_accept_b = { "s_e9ea6fec", "s_63c379c4", "s_bbd611b4", "s_556c01dc" },
}

D.REMOVED = {"s_455", "s_475", "s_493", "s_541", "s_589", "s_627", "s_711", "s_741", "s_821", "s_459", "s_463", "s_467", "s_479", "s_483", "s_497", "s_501", "s_505", "s_509", "s_517", "s_521", "s_525", "s_529", "s_533", "s_545", "s_549", "s_553", "s_565", "s_557", "mission3_accept_c", "s_569", "s_573", "s_577", "s_581", "mission3_accept_d", "s_593", "s_597", "s_601", "s_605", "s_609", "s_613", "s_617", "mission3_accept_e", "s_631", "s_667", "s_635", "s_639", "s_643", "s_647", "s_651", "s_655", "s_659", "s_671", "s_675", "s_679", "s_683", "s_687", "s_691", "s_695", "s_699", "s_703", "s_715", "s_719", "s_723", "s_727", "s_731", "mission2_accept_c", "s_745", "s_785", "s_749", "s_753", "s_757", "s_761", "s_765", "s_769", "s_773", "s_777", "s_789", "s_793", "s_797", "s_801", "s_805", "s_809", "s_813", "mission1_accept_b", "s_825", "s_829", "s_833", "s_837", "s_841", "s_845", "mission1_accept_c"}

D.REPLACED = { briefLines = { 296, 297, 304, 305, 306, 313, 314, 321, 322 }, blockFrom = 325, blockTo = 1072 }

-- Appendix B: the 130 client-only ids the files use after F6b (the 126 pool ids and the 4 F6a training replies); the STF has 260 ids, 258 are used
D.TRAINING_REPLIES = { "s_1813de4d", "s_25506b23", "s_ada4db16", "s_fd7e4ac8" }
D.CLIENT_ONLY = {}

for id in pairs(D.TEXT) do D.CLIENT_ONLY[#D.CLIENT_ONLY + 1] = id end
for _, id in ipairs(D.TRAINING_REPLIES) do D.CLIENT_ONLY[#D.CLIENT_ONLY + 1] = id end

table.sort(D.CLIENT_ONLY)

-- the 7 grant screens
D.GRANT_IDS = { "mission1_accept_a", "mission2_accept_a", "mission2_accept_b", "mission3_accept_a", "mission3_accept_b", "mission4_accept_a", "mission4_accept_b" }

-- screens by id
D.BY_ID = {}

for _, row in ipairs(D.SCREENS) do D.BY_ID[row.id] = row end

-- the exact source lines of the format (Content contract 1) for a row
function D.optionLine(reply, link, text)
	return '\t\t{"' .. D.PREFIX .. reply .. '", "' .. link .. '"}, -- ' .. text
end

-- text of any id of the pool or the briefs
function D.textOf(sid)
	return D.TEXT[sid] or D.BRIEF_TEXT[sid]
end

-- the exact lines of one screen block (Content contract 1)
function D.blockLines(row)
	local lines = {
		"imler_convo_template:addScreen(ConvoScreen:new {",
		'\tid = "' .. row.id .. '",',
		'\tleftDialog = "' .. D.PREFIX .. row.sid .. '", -- ' .. row.text,
	}

	if row.anim then
		lines[#lines + 1] = '\tanimation = "' .. row.anim .. '",'
		lines[#lines + 1] = '\tstopConversation = "true",'
		lines[#lines + 1] = "\toptions = {}"
	else
		lines[#lines + 1] = "\toptions = {"

		for _, o in ipairs(row.options) do
			lines[#lines + 1] = D.optionLine(o[1], o[2], D.textOf(o[1]))
		end

		lines[#lines + 1] = "\t}"
	end

	lines[#lines + 1] = "})"

	return lines
end

return D
