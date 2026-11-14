spacestation_tatooine_convotemplate = ConvoTemplate:new {
	initialScreen = "spacestation_tatooine_greeting",
	templateType = "Lua",
	luaClassHandler = "SpacestationTatooineConvoHandler",
	screens = {}
}

--Greeting
spacestation_tatooine_greeting = ConvoScreen:new {
	id = "spacestation_tatooine_greeting",
	leftDialog = "@conversation/station_tatooine:s_a9152d31", --Hey, you! What do you want?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_5984746e", "spacestation_tatooine_land"}, --I want to land on Tatooine.
		--{"@conversation/station_tatooine:s_6c8ffad8", "spacestation_tatooine_repair"}, --I need repairs.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_greeting);

out_of_range = ConvoScreen:new {
	id = "out_of_range",
	leftDialog = "@conversation/station_tatooine:s_a9ce7ad3", -- Too Far Message
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(out_of_range);

--Land Main Menu
spacestation_tatooine_land = ConvoScreen:new {
	id = "spacestation_tatooine_land",
	leftDialog = "@conversation/station_tatooine:s_83bace61", --Yeah? Anywhere in particular or were you just gonna set down in the desert?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_43d2bcbe", "spacestation_tatooine_land_bestine"}, --Bestine Starport.
		{"@conversation/station_tatooine:s_ccbc6cf4", "spacestation_tatooine_land_eisley"}, --Mos Eisley Starport.
		{"@conversation/station_tatooine:s_75ba8830", "spacestation_tatooine_land_espa"}, --Mos Espa Starport.
		{"@conversation/station_tatooine:s_69ffeefe", "spacestation_tatooine_land_entha"}, --Mos Entha Starport.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land);

--Bestine Landing Main
spacestation_tatooine_land_bestine = ConvoScreen:new {
	id = "spacestation_tatooine_land_bestine",
	leftDialog = "@conversation/station_tatooine:s_ea06a410", --Ok, you're clear to land.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_c4682ea6", "spacestation_tatooine_land_bestine_complete"}, --Thanks!
		{"@conversation/station_tatooine:s_4dc4840b", "spacestation_tatooine_land_bestine_abort"}, --Wait, I changed my mind.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_bestine);

--Bestine Landing Complete
spacestation_tatooine_land_bestine_complete = ConvoScreen:new {
	id = "spacestation_tatooine_land_bestine_complete",
	leftDialog = "@conversation/station_tatooine:s_333ffc01", --Yeah, yeah.  Tatooine station, out!
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_bestine_complete);

--Bestine Landing Abort
spacestation_tatooine_land_bestine_abort = ConvoScreen:new {
	id = "spacestation_tatooine_land_bestine_abort",
	leftDialog = "@conversation/station_tatooine:s_43b6dcb9", --I'm too busy to wait.  Let me know when you figure out what it is you want.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_bestine_abort);

--Eisley Landing Main
spacestation_tatooine_land_eisley = ConvoScreen:new {
	id = "spacestation_tatooine_land_eisley",
	leftDialog = "@conversation/station_tatooine:s_6ff46cdd", --Go ahead and land. No one there cares who comes or goes.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_b9b27823", "spacestation_tatooine_land_eisley_complete"}, --Thank you.
		{"@conversation/station_tatooine:s_d195782", "spacestation_tatooine_land_eisley_abort"}, --Wait! I changed my mind.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_eisley);

--Eisley Landing
spacestation_tatooine_land_eisley_complete = ConvoScreen:new {
	id = "spacestation_tatooine_land_eisley_complete",
	leftDialog = "@conversation/station_tatooine:s_4650b19f", --Watch your back.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_eisley_complete);

--Eisley Landing Abort
spacestation_tatooine_land_eisley_abort = ConvoScreen:new {
	id = "spacestation_tatooine_land_eisley_abort",
	leftDialog = "@conversation/station_tatooine:s_1ba81e14", --Fine by me. Stay in orbit and rot. Tatooine Station, out!.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_eisley_abort);

--Espa Landing Main
spacestation_tatooine_land_espa = ConvoScreen:new {
	id = "spacestation_tatooine_land_espa",
	leftDialog = "@conversation/station_tatooine:s_ea06a410", --Ok, you're clear to land.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_895d093", "spacestation_tatooine_land_espa_complete"}, --Ok.
		{"@conversation/station_tatooine:s_e1ef9209", "spacestation_tatooine_land_espa_abort"}, --Wait, I don't want to land there.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_espa);

--Espa Landing Complete
spacestation_tatooine_land_espa_complete = ConvoScreen:new {
	id = "spacestation_tatooine_land_espa_complete",
	leftDialog = "@conversation/station_tatooine:s_b729c637", --Land in the Dune Sea for all I care. Tatooine Station, out!
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_espa_complete);

--Espa Landing Abort
spacestation_tatooine_land_espa_abort = ConvoScreen:new {
	id = "spacestation_tatooine_land_espa_abort",
	leftDialog = "@conversation/station_tatooine:s_2a7858d1", --Well, hail me when you figure out what it is you need.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_espa_abort);

--Entha Landing Main
spacestation_tatooine_land_entha = ConvoScreen:new {
	id = "spacestation_tatooine_land_entha",
	leftDialog = "@conversation/station_tatooine:s_ea06a410", --Ok, you're clear to land.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_895d093", "spacestation_tatooine_land_entha_complete"}, --Ok.
		{"@conversation/station_tatooine:s_e76d5278", "spacestation_tatooine_land_entha_abort"}, --On second thought, I don't want to land there.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_entha);

--Entha Landing Complete
spacestation_tatooine_land_entha_complete = ConvoScreen:new {
	id = "spacestation_tatooine_land_entha_complete",
	leftDialog = "@conversation/station_tatooine:s_c1013aa7", --Whatever.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_entha_complete);

--Entha Landing Abort
spacestation_tatooine_land_entha_abort = ConvoScreen:new {
	id = "spacestation_tatooine_land_entha_abort",
	leftDialog = "@conversation/station_tatooine:s_82f403b1", --I don't have time for this, come back when you have made up your mind.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_entha_abort);

-- Repair Main
spacestation_tatooine_repair = ConvoScreen:new {
	id = "spacestation_tatooine_repair",
	leftDialog = "@conversation/station_tatooine:s_35221afe", --So I noticed. Looks like you bit off a little more than you could chew. So what do want: a complete overhaul or just enough repairs to put you back on your way?
	stopConversation = "false",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_repair);

spacestation_tatooine_repair_deny = ConvoScreen:new {
	id = "spacestation_tatooine_repair_deny",
	leftDialog = "@conversation/station_tatooine:s_b086bdca", -- Fine by me. Repair it yourself.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_repair_deny);

-- Repair Some
repair_small = ConvoScreen:new {
	id = "repair_small",
	leftDialog = "@conversation/station_tatooine:s_eecfecc1", -- We can touch up the paint for %DI credits. How's that sound?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_895d093", "accept_repair_25"}, --Ok.
		{"@conversation/station_tatooine:s_4c695dbd", "deny_repair_25"}, -- No.
	}
}
spacestation_tatooine_convotemplate:addScreen(repair_small);

-- Accept Repair 25
accept_repair_25 = ConvoScreen:new {
	id = "accept_repair_25",
	leftDialog = "@conversation/station_tatooine:s_4d9fae53", -- Ok, there you go. We fixed just enough to get you out of my face. See you next time. Ha!
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(accept_repair_25);

-- Deny Repair 25
deny_repair_25 = ConvoScreen:new {
	id = "deny_repair_25",
	leftDialog = "@conversation/station_tatooine:s_b086bdca", -- Fine by me. Repair it yourself.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(deny_repair_25);

-- Repair Half
repair_half = ConvoScreen:new {
	id = "repair_half",
	leftDialog = "@conversation/station_tatooine:s_c130a6b8", -- Sure, we can do that. Does %DI credits sound fair?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_d70dba34", "accept_repair_50"}, -- Yes.
		{"@conversation/station_tatooine:s_4c695dbd", "deny_repair_50"}, -- No.
	}
}
spacestation_tatooine_convotemplate:addScreen(repair_half);

-- Accept Repair 50
accept_repair_50 = ConvoScreen:new {
	id = "accept_repair_50",
	leftDialog = "@conversation/station_tatooine:s_c5b42136", -- Repairs complete! See you soon! Ha!
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(accept_repair_50);

-- Deny Repair 50
deny_repair_50 = ConvoScreen:new {
	id = "deny_repair_50",
	leftDialog = "@conversation/station_tatooine:s_b086bdca", -- Fine by me. Repair it yourself.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(deny_repair_50);

-- Repair Most
repair_most = ConvoScreen:new {
	id = "repair_most",
	leftDialog = "@conversation/station_tatooine:s_42648804", -- Ok, how does %DI credits in exchange for repairing three-fourths of the damage sound to ya?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_5e2a2bb1", "accept_repair_75"}, -- Sounds good.
		{"@conversation/station_tatooine:s_d6695e83", "deny_repair_75"}, -- No thanks.
	}
}
spacestation_tatooine_convotemplate:addScreen(repair_most);

-- Accept Repair Most
accept_repair_75 = ConvoScreen:new {
	id = "accept_repair_75",
	leftDialog = "@conversation/station_tatooine:s_b6e0e78d", -- Repairs complete. You're almost as good as new. Good as you probably need to be, anyway.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(accept_repair_75);

-- Deny Repair Most
deny_repair_75 = ConvoScreen:new {
	id = "deny_repair_75",
	leftDialog = "@conversation/station_tatooine:s_b086bdca", -- Fine by me. Repair it yourself.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(deny_repair_75);

-- Repair Full
repair_full = ConvoScreen:new {
	id = "repair_full",
	leftDialog = "@conversation/station_tatooine:s_7a45c683", -- We can repair all the damage on your ship for a mere %DI credits. Good luck finding another offer like that around here.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_d0fd857b", "accept_repair_full"}, -- I'll take it.
		{"@conversation/station_tatooine:s_4c695dbd", "deny_repair_full"}, -- No.
	}
}
spacestation_tatooine_convotemplate:addScreen(repair_full);

-- Accept Repair Full
accept_repair_full = ConvoScreen:new {
	id = "accept_repair_full",
	leftDialog = "@conversation/station_tatooine:s_27445295", -- Your ship has been completely fixed. No doubt I'll be seeing you again real soon. Ha!
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(accept_repair_full);

-- Deny Repair Full
deny_repair_full = ConvoScreen:new {
	id = "deny_repair_full",
	leftDialog = "@conversation/station_tatooine:s_b086bdca", -- Fine by me. Repair it yourself.
	stopConversation = "true",
	options = {}
}
spacestation_tatooine_convotemplate:addScreen(deny_repair_full);

-- Lady Valarian's bounty, the Hutt freighter duty and the Jabba's Palace landing (feature tatooine-station-palace-access; pairings reconstructed from the client strings)

spacestation_tatooine_greeting_valarian = ConvoScreen:new {
	id = "spacestation_tatooine_greeting_valarian",
	leftDialog = "@conversation/station_tatooine:s_e2190b5d", -- That name, I recognize that name. Oh, that's right, you're on my list to be offered some sensitive work if you're interested.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_f2b8a1d8", "spacestation_tatooine_valarian_offer"}, -- What kind of work?
		{"@conversation/station_tatooine:s_375a3c20", "spacestation_tatooine_land"}, -- I just want to land on Tatooine.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_greeting_valarian);

spacestation_tatooine_valarian_offer = ConvoScreen:new {
	id = "spacestation_tatooine_valarian_offer",
	leftDialog = "@conversation/station_tatooine:s_462a718b", -- Lady Valarian has placed a bounty on one of Jabba's smugglers and is looking for competent pilots to collect it. Interested?
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_52917b0d", "spacestation_tatooine_valarian_warning"}, -- Of course.
		{"@conversation/station_tatooine:s_cd0dcead", "spacestation_tatooine_valarian_declined"}, -- Of course not.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_valarian_offer);

spacestation_tatooine_valarian_warning = ConvoScreen:new {
	id = "spacestation_tatooine_valarian_warning",
	leftDialog = "@conversation/station_tatooine:s_3cbb3f38", -- Keep in mind, the target is pretty dangerous. Looking at you, you may need some help in completing this. Anyway, if you are ready now, I will patch you up to the contact Lady Valarian gave me.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_dd4bb16d", "spacestation_tatooine_valarian_accepted"}, -- Let's do it!
		{"@conversation/station_tatooine:s_5964dabc", "spacestation_tatooine_valarian_not_now"}, -- I don't think so, maybe another time.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_valarian_warning);

spacestation_tatooine_valarian_accepted = ConvoScreen:new {
	id = "spacestation_tatooine_valarian_accepted",
	leftDialog = "@conversation/station_tatooine:s_12b89c7f", -- Very well, good luck. Oh, and this target you're going after, he's a clever guy. Make sure to search the cargo of his ship if you get him.  He's bound to have something interesting.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_valarian_accepted);

spacestation_tatooine_valarian_not_now = ConvoScreen:new {
	id = "spacestation_tatooine_valarian_not_now",
	leftDialog = "@conversation/station_tatooine:s_39076454", -- Suit yourself, you were probably not the right person for the job anyway.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_valarian_not_now);

spacestation_tatooine_valarian_declined = ConvoScreen:new {
	id = "spacestation_tatooine_valarian_declined",
	leftDialog = "@conversation/station_tatooine:s_66b68768", -- I thought so.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_valarian_declined);

spacestation_tatooine_work_refused = ConvoScreen:new {
	id = "spacestation_tatooine_work_refused",
	leftDialog = "@conversation/station_tatooine:s_121c3b6", -- What does this look like, an unemployment agency?
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_work_refused);

spacestation_tatooine_work_hutts = ConvoScreen:new {
	id = "spacestation_tatooine_work_hutts",
	leftDialog = "@conversation/station_tatooine:s_28b0a7fa", -- Well, if you don't mind helping the Hutts, I might have something.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_3147a9c7", "spacestation_tatooine_hutt_offer"}, -- Sounds interesting, how do I get started?
		{"@conversation/station_tatooine:s_382cb25f", "spacestation_tatooine_hutt_refused"}, -- Hutts?! I don't think so.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_work_hutts);

spacestation_tatooine_hutt_offer = ConvoScreen:new {
	id = "spacestation_tatooine_hutt_offer",
	leftDialog = "@conversation/station_tatooine:s_630ab375", -- Alright. The Hutts are hiring pilots to assist them in capturing freighters around the Tatooine system. If that sounds like something you want to do, I can connect you to one of them right now.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_2e631d52", "spacestation_tatooine_hutt_accepted"}, -- Hook me up!
		{"@conversation/station_tatooine:s_2f2188d5", "spacestation_tatooine_hutt_later"}, -- I will come back later.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_hutt_offer);

spacestation_tatooine_hutt_accepted = ConvoScreen:new {
	id = "spacestation_tatooine_hutt_accepted",
	leftDialog = "@conversation/station_tatooine:s_d7e462ff", -- Very well, give me a second.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_hutt_accepted);

spacestation_tatooine_hutt_later = ConvoScreen:new {
	id = "spacestation_tatooine_hutt_later",
	leftDialog = "@conversation/station_tatooine:s_1dbd74da", -- Well hail me when you figure out what it is you need.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_hutt_later);

spacestation_tatooine_hutt_refused = ConvoScreen:new {
	id = "spacestation_tatooine_hutt_refused",
	leftDialog = "@conversation/station_tatooine:s_5739799e", -- These are not times to be picky, but suit yourself.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_hutt_refused);

spacestation_tatooine_land_jabba = ConvoScreen:new {
	id = "spacestation_tatooine_land_jabba",
	leftDialog = "@conversation/station_tatooine:s_1d21e3c0", -- Let me see if you're welcome there. I guess you are.
	stopConversation = "false",
	options = {
		{"@conversation/station_tatooine:s_b9b27823", "spacestation_tatooine_land_jabba_complete"}, -- Thank you.
		{"@conversation/station_tatooine:s_e1ef9209", "spacestation_tatooine_land_jabba_abort"}, -- Wait, I don't want to land there.
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_jabba);

spacestation_tatooine_land_jabba_complete = ConvoScreen:new {
	id = "spacestation_tatooine_land_jabba_complete",
	leftDialog = "@conversation/station_tatooine:s_4650b19f", -- Watch your back.
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_jabba_complete);

spacestation_tatooine_land_jabba_abort = ConvoScreen:new {
	id = "spacestation_tatooine_land_jabba_abort",
	leftDialog = "@conversation/station_tatooine:s_b26eb03c", -- Good riddance!
	stopConversation = "true",
	options = {
	}
}
spacestation_tatooine_convotemplate:addScreen(spacestation_tatooine_land_jabba_abort);

-- Add Template (EOF)
addConversationTemplate("spacestation_tatooine_convotemplate", spacestation_tatooine_convotemplate);
