-- Da'la Socuna: which screen a pilot opens on (gate table G), the conditional link C-1, the pure gates (I-10) and the grounded dialogue.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-6; Conversation flow 1 and 2; FI-1, FI-3, FI-4, FI-5, FI-7; D-4 to D-8, D-10; I-10).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- crimson_tier1_data.lua C.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).
-- The order is J's, with the adaptations of the spec (JTL first, the tier-done gate needs the mission 4 reward).

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

I.load()

TestCrimsonT1Gates = {}

function TestCrimsonT1Gates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function opens(player) return I.firstScreen(player) end

local function handler() return rawget(_G, I.HANDLER) end

local function squadron(name) return rawget(_G, name) end

-- G0
-- AC-6
function TestCrimsonT1Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = I.pilot(), I.npc(), H.conversationTemplate(I.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestCrimsonT1Gates:test_jtl_disabled_opens_not_a_pilot_which_ends_without_replies()
	H.Engine.config.jtlEnabled = false

	local t = I.talk(I.pilot())

	lu.assertEquals(I.ids(t), { "not_a_pilot" }, "JTL disabled")
	lu.assertTrue(t[1].stop, "not_a_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_a_pilot offers no reply")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_1d3d8b65", "J's own no-JTL line")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-6
function TestCrimsonT1Gates:test_a_pilot_without_a_player_object_opens_not_a_pilot()
	local player = I.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_a_pilot", "ghost is nil (SWG !hasSpaceExpansion)")
end

-- AC-6: the JTL gate comes before everything, including the help line
function TestCrimsonT1Gates:test_jtl_disabled_beats_the_first_mission_help_and_every_other_gate()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(I.pilot({ state = "active" })), "not_a_pilot", "JTL disabled with mission 1 active")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false })), "not_a_pilot", "JTL disabled, a neutral pilot")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_a_pilot", "JTL disabled, a neutral non-pilot")
end

-- G2
-- AC-6
function TestCrimsonT1Gates:test_a_pilot_with_a_ship_and_mission_1_active_opens_the_first_mission_help()
	local t = I.talk(I.pilot({ state = "active" }))

	lu.assertEquals(I.ids(t), { "first_mission_help" }, "mission 1 patrol active")
	lu.assertEquals(I.optionSids(t[1]), { "s_8a4652c6", "s_680cda08", "s_5bfac9f1" }, "the three questions")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-6
function TestCrimsonT1Gates:test_the_surprise_attack_being_active_also_counts_as_mission_1_active()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "active")
	lu.assertEquals(opens(player), "first_mission_help", "patrol complete, surprise attack active")
end

-- AC-6: the help line comes before the faction and membership gates (only the JTL gate precedes it)
function TestCrimsonT1Gates:test_the_help_line_comes_before_the_faction_and_membership_gates()
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "imperial" })), "first_mission_help", "imperial faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "neutral" })), "first_mission_help", "no faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", squadron = false })), "first_mission_help", "no squadron, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", standing = -5 })), "first_mission_help", "negative standing, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", graduated = true })), "first_mission_help", "Eker key, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", datapad = "story" })), "first_mission_help", "a datapad mission, mission 1 active: G2 precedes G9")
	lu.assertEquals(opens(I.pilot({ state = "active", pilot = "neutral", squadron = false })), "first_mission_help", "a neutral pilot with mission 1 active: G2 precedes G3")
end

-- G2 needs a certified ship
-- AC-6
function TestCrimsonT1Gates:test_mission_1_active_without_a_ship_does_not_open_the_help()
	lu.assertEquals(opens(I.pilot({ state = "active", ship = false })), "lost_ship", "no certified ship: G8")
end

-- G3
-- AC-6
function TestCrimsonT1Gates:test_a_corsec_pilot_opens_privateer_pilot_before_the_faction_gates()
	local t = I.talk(I.pilot({ pilot = "neutral", squadron = squadron("CORSEC_SQUADRON") }))

	lu.assertEquals(I.ids(t), { "privateer_pilot" }, "a CorSec pilot")
	lu.assertTrue(t[1].stop, "privateer_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "privateer_pilot offers no reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "privateer_pilot", "neutral pilot, no faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "imperial" })), "privateer_pilot", "neutral pilot, Imperial faction: G3 precedes G4")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, ship = false })), "privateer_pilot", "neutral pilot without a ship: G3 precedes G8")
end

-- G4
-- AC-6
function TestCrimsonT1Gates:test_an_imperial_faction_non_pilot_or_an_imperial_pilot_opens_imperial_pilot()
	local t = I.talk(I.pilot({ pilot = false, faction = "imperial", squadron = false }))

	lu.assertEquals(I.ids(t), { "imperial_pilot" }, "an Imperial-faction non-pilot")
	lu.assertTrue(t[1].stop, "imperial_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "imperial_pilot offers no reply")
	lu.assertEquals(opens(I.pilot({ pilot = "imperial", faction = "rebel", squadron = false })), "imperial_pilot", "an Imperial pilot with Rebel faction")
	lu.assertEquals(opens(I.pilot({ pilot = "imperial", faction = "neutral", squadron = false })), "imperial_pilot", "an Imperial pilot with no faction")
	lu.assertEquals(opens(I.pilot({ faction = "imperial" })), "imperial_pilot", "a Crimson Phoenix pilot with Imperial faction: G4 precedes G5 and G7")
end

-- G5 (D-5)
-- AC-6
function TestCrimsonT1Gates:test_a_neutral_non_pilot_opens_not_a_pilot_which_ends_without_replies()
	local t = I.talk(I.pilot({ pilot = false, faction = "neutral", squadron = false }))

	lu.assertEquals(I.ids(t), { "not_a_pilot" }, "a non-pilot without faction")
	lu.assertTrue(t[1].stop, "not_a_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_a_pilot offers no reply")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_1d3d8b65", "'You don't look like any sort of pilot to me. I can't help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("giveItem") + #H.Engine.callsTo("grantStarterShip"), 0, "nothing granted")
end

-- G5 (D-4)
-- AC-6
function TestCrimsonT1Gates:test_a_rebel_pilot_whose_faction_is_not_rebel_opens_grounded_with_its_reply()
	local havoc = I.talk(I.pilot({ faction = "neutral", squadron = squadron("HAVOC_SQUADRON") }))

	lu.assertEquals(I.ids(havoc), { "grounded" }, "a Havoc pilot whose faction is neutral")
	lu.assertEquals(I.optionSids(havoc[1]), { "s_370822d1" }, "grounded reply")
	lu.assertFalse(havoc[1].stop, "grounded does not end: the reply follows")
	lu.assertEquals(opens(I.pilot({ faction = "neutral" })), "grounded", "a Crimson Phoenix pilot without Rebel faction: G5 precedes G7")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", squadron = false, ship = false })), "grounded", "G5 precedes G8")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", standing = 500 })), "grounded", "good standing does not help without the faction")
end

-- G6
-- AC-6
function TestCrimsonT1Gates:test_a_rebel_faction_non_pilot_opens_recruitment()
	local t = I.talk(I.pilot({ pilot = false, squadron = false }))

	lu.assertEquals(I.ids(t), { "recruitment" }, "Rebel faction, no pilot skills")
	lu.assertEquals(I.optionSids(t[1]), { "s_78679b31", "s_3f5c320e", "s_db6b2243" }, "the three routes")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, ship = false })), "recruitment", "no ship: G6 precedes G8")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, standing = -50 })), "recruitment", "negative Rebel standing does not stop a non-pilot (G10 is for members)")
end

-- G7
-- AC-6
function TestCrimsonT1Gates:test_a_rebel_pilot_of_another_squadron_or_none_opens_non_member()
	lu.assertEquals(opens(I.pilot({ squadron = squadron("HAVOC_SQUADRON") })), "non_member", "Havoc pilot")
	lu.assertEquals(opens(I.pilot({ squadron = squadron("VORTEX_SQUADRON") })), "non_member", "Vortex pilot")
	lu.assertEquals(opens(I.pilot({ squadron = false })), "non_member", "a Rebel pilot without a squadron (D-7: no track adoption)")
	lu.assertEquals(opens(I.pilot({ squadron = false, ship = false })), "non_member", "no ship: G7 precedes G8")
	lu.assertEquals(opens(I.pilot({ squadron = false, datapad = "story" })), "non_member", "a datapad mission: G7 precedes G9")
	lu.assertEquals(opens(I.pilot({ squadron = false, standing = -1 })), "non_member", "negative standing: G7 precedes G10")
	lu.assertEquals(opens(I.pilot({ squadron = false, graduated = true })), "non_member", "Eker key of a pilot who left the squadron: G7 precedes G11")
end

-- G8
-- AC-6
function TestCrimsonT1Gates:test_a_member_without_a_certified_ship_opens_lost_ship_which_ends()
	local t = I.talk(I.pilot({ ship = false }))

	lu.assertEquals(I.ids(t), { "lost_ship" }, "member without a ship")
	lu.assertEquals(opens(I.pilot({ ship = false, paid = 2 })), "lost_ship", "with two missions paid")
	lu.assertEquals(opens(I.pilot({ ship = false, datapad = "story" })), "lost_ship", "G8 precedes G9")
	lu.assertEquals(opens(I.pilot({ ship = false, standing = -1 })), "lost_ship", "G8 precedes G10")
	lu.assertEquals(opens(I.pilot({ ship = false, graduated = true, paid = 4, tier = 4 })), "lost_ship", "a graduate without a ship: G8 precedes G11")
end

-- G8: lost_ship grants one Rebel starter ship
-- AC-6
function TestCrimsonT1Gates:test_lost_ship_grants_one_rebel_starter_ship()
	local player = I.pilot({ ship = false })

	I.talk(player)

	local calls = H.Engine.callsTo("grantStarterShip")

	lu.assertEquals(#calls, 1, "grantStarterShip calls")
	lu.assertTrue(calls[1][1] == player and calls[1][2] == "rebel", "the starter ship is a rebel one for the pilot")
end

-- G9
-- AC-6
function TestCrimsonT1Gates:test_a_member_with_any_space_quest_opens_on_mission()
	local t = I.talk(I.pilot({ paid = 1, state = "active" }))

	lu.assertEquals(I.ids(t), { "on_mission" }, "mission 2 active")
	lu.assertTrue(t[1].stop, "on_mission ends the conversation")
	lu.assertEquals(#t[1].options, 0, "on_mission offers no reply")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "active" })), "on_mission", "mission 3 active")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "active" })), "on_mission", "mission 4 active")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 4, duty = I.DUTY6 })), "on_mission", "destroy duty active")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 4, duty = I.DUTY7 })), "on_mission", "escort duty active")
	lu.assertEquals(opens(I.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(I.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 1, state = "active" })), "on_mission", "G9 precedes the grounded gate G10")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4, tier = 4, datapad = "story" })), "on_mission", "G9 precedes graduated (G11)")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4, tier = 4, duty = I.DUTY7 })), "on_mission", "a graduate on a duty")
end

-- AC-6: mission 3's escort running after the patrol is a running mission
function TestCrimsonT1Gates:test_mission_3_with_the_escort_active_after_the_patrol_is_still_running()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	I.setState(player, I.E3, "active")
	lu.assertEquals(opens(player), "on_mission", "the escort split is running")
end

-- G10 (D-4)
-- AC-6
function TestCrimsonT1Gates:test_a_member_with_negative_rebel_standing_opens_grounded()
	local t = I.talk(I.pilot({ standing = -1 }))

	lu.assertEquals(I.ids(t), { "grounded" }, "Crimson Phoenix pilot, standing -1")
	lu.assertEquals(I.optionSids(t[1]), { "s_370822d1" }, "grounded reply")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 4, tier = 4 })), "grounded", "everything done, standing -1")
	lu.assertEquals(opens(I.pilot({ standing = -1, graduated = true })), "grounded", "G10 precedes graduated (G11)")
	lu.assertEquals(opens(I.pilot({ standing = 0 })), "mission1_offer", "standing 0 is served normally")
end

-- AC-6: the gate lifts at 0
function TestCrimsonT1Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = I.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "grounded", "standing -1")
	player.ghost.factionStanding.rebel = 0
	lu.assertEquals(opens(player), "mission2_offer", "standing 0")
end

-- G11
-- AC-6, AC-10
function TestCrimsonT1Gates:test_the_eker_key_opens_graduated()
	local t = I.talk(I.pilot({ graduated = true, paid = 4, tier = 4 }))

	lu.assertEquals(I.ids(t), { "graduated" }, "promoted pilot")
	lu.assertEquals(I.optionSids(t[1]), { "s_b3bebc5e" }, "the one direction question")
	lu.assertEquals(opens(I.pilot({ graduated = true })), "graduated", "the key alone")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4, tier = 4, xp = 100000 })), "graduated", "with XP to spare")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4 })), "graduated", "G11 precedes the training gates")
end

-- G11: graduated is "the key is set" (SWG hasSpaceFlag), whatever the value; tier 2 writes "2" (D-11)
-- AC-6, AC-10
function TestCrimsonT1Gates:test_any_set_eker_key_value_opens_graduated_and_is_left_alone()
	for _, value in ipairs({ "1", "2", "3" }) do
		local player = I.pilot({ graduated = value, paid = 4, tier = 4 })
		local t = I.talk(player)

		lu.assertEquals(I.ids(t), { "graduated" }, "key '" .. value .. "': first screen")
		lu.assertEquals(H.getQuestStatus(player, I.EKER_PILOT_KEY), value, "key '" .. value .. "': unchanged after the talk")
		lu.assertEquals(I.firstScreen(player), "graduated", "key '" .. value .. "': second talk")
		lu.assertEquals(H.getQuestStatus(player, I.EKER_PILOT_KEY), value, "key '" .. value .. "': unchanged after the second talk")
	end
end

-- G12
-- AC-6
function TestCrimsonT1Gates:test_all_four_skills_and_the_mission_4_reward_open_tier_done()
	local t = I.talk(I.pilot({ paid = 4, tier = 4 }))

	lu.assertEquals(I.ids(t), { "tier_done" }, "four tier 1 skills, mission 4 paid")
	lu.assertEquals(I.optionSids(t[1]), { "s_abc65d0", "s_f843dc6a", "s_d8913d37" }, "the three replies")
end

-- AC-6, FI-7: the tier-done gate needs the mission 4 reward
function TestCrimsonT1Gates:test_mission_4_won_and_unpaid_beats_the_tier_done_and_the_training_gates()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 4 })), "mission4_report", "four skills, mission 4 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 1, xp = 99999 })), "mission4_report", "one skill, XP, mission 4 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won" })), "mission4_report", "no skill, mission 4 won and unpaid")
end

-- G15 .. G25: one row per mission
local MISSIONS = {
	{ n = 2, report = "mission2_report", failed = "mission2_failed", offer = "mission2_offer" },
	{ n = 3, report = "mission3_report", failed = "mission3_failed", offer = "mission3_offer" },
	{ n = 4, report = "mission4_report", failed = "mission4_failed", offer = "mission4_offer" },
}

for _, m in ipairs(MISSIONS) do
	-- AC-6, AC-8
	TestCrimsonT1Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.report] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "won" })), m.report, "mission " .. m.n .. " won, reward unpaid")
	end

	-- AC-6, AC-7 (an abort is a failure, FI-4)
	TestCrimsonT1Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.failed] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "failed" })), m.failed, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- AC-6
	TestCrimsonT1Gates["test_mission_" .. m.n .. "_not_started_opens_" .. m.offer] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1 })), m.offer, "missions before " .. m.n .. " paid")
	end
end

-- G13 (FI-5, D-6): a patrol that was lost or aborted before it was won
-- AC-6
function TestCrimsonT1Gates:test_mission_1_attempted_with_the_patrol_not_won_opens_mission1_patrol_failed()
	local t = I.talk(I.pilot({ state = "failed" }))

	lu.assertEquals(I.ids(t), { "mission1_patrol_failed" }, "patrol failed")
	lu.assertEquals(I.optionSids(t[1]), { "s_4f90bab3", "s_b9c55cab" }, "the two routes")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G14 (FI-5, D-6): the patrol is won and the surprise attack lost
-- AC-6
function TestCrimsonT1Gates:test_mission_1_with_the_patrol_won_and_the_surprise_attack_lost_opens_mission1_failed()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")

	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "mission1_failed" }, "patrol complete, surprise attack never won")
	lu.assertEquals(I.optionSids(t[1]), { "s_11327023", "s_68ee2577" }, "the two routes")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G18, G19
-- AC-6
function TestCrimsonT1Gates:test_mission_1_not_started_opens_the_offer_and_won_and_unpaid_opens_the_report()
	local t = I.talk(I.pilot())

	lu.assertEquals(I.ids(t), { "mission1_offer" }, "no mission started")
	lu.assertEquals(I.optionSids(t[1]), { "s_d731f764", "s_90377ed4", "s_6bb935f1", "s_7478cd28" }, "the four routes")

	local r = I.talk(I.pilot({ state = "won" }))

	lu.assertEquals(I.ids(r), { "mission1_report" }, "both quests complete, reward unpaid")
	lu.assertEquals(I.optionSids(r[1]), { "s_64b4e5f7", "s_97e13b2e", "s_11327023" }, "the three routes")
	lu.assertEquals(CS.transcriptUnresolved(r), {}, "client strings")
end

-- AC-6: mission 1 is won only when the patrol and the surprise attack are both complete
function TestCrimsonT1Gates:test_mission_1_is_won_only_when_the_patrol_and_the_surprise_attack_are_both_complete()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "complete")
	lu.assertEquals(opens(player), "mission1_report", "both complete, unpaid")
end

-- AC-6: mission 3 counts as won only when the patrol and the escort are both complete
function TestCrimsonT1Gates:test_mission_3_with_only_the_patrol_complete_is_not_won()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	lu.assertEquals(opens(player), "mission3_failed", "patrol complete, escort never flown")
end

-- AC-6: J's mission numbers: mission 2 is destroy/tatooine_rebel_3 and mission 3 is patrol/tatooine_rebel_2 (D-14)
function TestCrimsonT1Gates:test_the_mission_numbers_follow_j_and_the_status_keys_follow_the_swg_quest_names()
	local p2 = I.pilot({ paid = 1, state = "failed" })

	lu.assertEquals(H.getQuestStatus(p2, "tatooine_rebel_3:attempted"), "1", "mission 2 is attempted under tatooine_rebel_3")
	I.setState(p2, I.M2, "complete")
	lu.assertEquals(opens(p2), "mission2_report", "destroy/tatooine_rebel_3 complete is mission 2 won")

	local p3 = I.pilot({ paid = 2, state = "failed" })

	lu.assertEquals(H.getQuestStatus(p3, "tatooine_rebel_2:attempted"), "1", "mission 3 is attempted under tatooine_rebel_2")
end

-- G26
-- AC-6
function TestCrimsonT1Gates:test_mission_4_paid_with_no_skill_opens_training_first_whatever_the_xp()
	local t = I.talk(I.pilot({ paid = 4 }))

	lu.assertEquals(I.ids(t), { "training_first" }, "no tier 1 skill, no XP: the first skill is free")
	lu.assertEquals(opens(I.pilot({ paid = 4, xp = 99999 })), "training_first", "no skill, plenty of XP")
end

-- G27
-- AC-6
function TestCrimsonT1Gates:test_mission_4_paid_with_some_skills_and_7500_xp_opens_training_more()
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, xp = 7500 })), "training_more", "one skill, 7500 XP")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3, xp = 99999 })), "training_more", "three skills, plenty of XP")
end

-- G28
-- AC-6
function TestCrimsonT1Gates:test_mission_4_paid_with_some_skills_but_too_little_xp_opens_duty_missions()
	local t = I.talk(I.pilot({ paid = 4, tier = 1, xp = 7499 }))

	lu.assertEquals(I.ids(t), { "duty_missions" }, "one skill, 7499 XP")
	lu.assertEquals(I.optionSids(t[1]), { "s_6106187c", "s_4ffd4b9d", "s_6e646769", "s_e0cb3e19" }, "the four replies")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3 })), "duty_missions", "three skills, no XP")
end

-- AC-6: every gate screen exists in Appendix A and the template
function TestCrimsonT1Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(I.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_a_pilot", "first_mission_help", "privateer_pilot", "imperial_pilot", "grounded", "recruitment", "non_member", "lost_ship", "on_mission", "graduated", "tier_done",
		"mission1_patrol_failed", "mission1_failed", "mission2_failed", "mission3_failed", "mission4_failed", "mission1_offer", "mission1_report", "mission2_offer", "mission2_report", "mission3_offer",
		"mission3_report", "mission4_offer", "mission4_report", "training_first", "training_more", "duty_missions" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(I.TEMPLATE)):getScreen(id), I.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- I-10: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestCrimsonT1PureGates = {}

function TestCrimsonT1PureGates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function effects(player)
	local out = {}

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip", "createEvent", "createObserver", "playClientEffectLoc" }) do
		out[fn] = #H.Engine.callsTo(fn)
	end

	out.bank = player.bankCredits
	out.standing = player.ghost and player.ghost.factionStanding.rebel
	out.squadron = player.ghost and player.ghost.squadronType
	out.pilotTier = player.ghost and player.ghost.pilotTier
	out.waypoints = player.ghost and #player.ghost.waypoints
	out.journal = player.ghost and I.state(player, I.P1) .. I.state(player, I.M2) .. I.state(player, I.P3) .. I.state(player, I.A4) .. I.state(player, I.DUTY6) .. I.state(player, I.DUTY7)

	for _, suffix in ipairs({ "tatooine_rebel_1:attempted", "tatooine_rebel_1:reward", "tatooine_rebel_3:attempted", "tatooine_rebel_3:reward",
		"tatooine_rebel_2:attempted", "tatooine_rebel_2:reward", "tatooine_rebel_4:attempted", "tatooine_rebel_4:reward", I.EKER_PILOT_KEY }) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	return out
end

-- I-10, AC-6: the gate decision itself writes nothing, for pilots of every kind and state (the on-display actions are the screens')
function TestCrimsonT1PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return I.pilot() end,
		function() return I.pilot({ state = "active" }) end,
		function() return I.pilot({ faction = "imperial" }) end,
		function() return I.pilot({ pilot = "neutral", squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false, faction = "neutral" }) end,
		function() return I.pilot({ faction = "neutral" }) end,
		function() return I.pilot({ squadron = false }) end,
		function() return I.pilot({ squadron = false, tier = 1 }) end,
		function() return I.pilot({ ship = false }) end,
		function() return I.pilot({ standing = -1 }) end,
		function() return I.pilot({ graduated = true, paid = 4, tier = 4 }) end,
		function() return I.pilot({ paid = 1, datapad = "story" }) end,
		function() return I.pilot({ paid = 4, tier = 4 }) end,
		function() return I.pilot({ paid = 4 }) end,
		function() return I.pilot({ paid = 4, tier = 1, xp = 7500 }) end,
		function() return I.pilot({ paid = 4, tier = 3 }) end,
		function() return I.pilot({ paid = 3, state = "won" }) end,
		function() return I.pilot({ paid = 3, state = "won", tier = 4 }) end,
		function() return I.pilot({ paid = 2, state = "won" }) end,
		function() return I.pilot({ paid = 1, state = "won" }) end,
		function() return I.pilot({ state = "won" }) end,
		function() return I.pilot({ paid = 1, state = "failed" }) end,
		function() return I.pilot({ paid = 2, state = "failed" }) end,
		function() return I.pilot({ paid = 3, state = "failed" }) end,
		function() return I.pilot({ state = "failed" }) end,
		function() return I.pilot({ paid = 4, tier = 4, duty = I.DUTY6 }) end,
		function() return I.pilot({ paid = 1, state = "won", species = SPECIES_WOOKIEE }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local before = effects(player)
		local screen = handler():getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE))

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertEquals(effects(player), before, "pilot " .. i .. " (" .. tostring(screen and screen.id) .. "): getInitialScreen changed state")
	end
end

-- I-10: and with JTL off and no ghost
function TestCrimsonT1PureGates:test_the_not_a_pilot_gate_changes_nothing()
	H.Engine.config.jtlEnabled = false

	local player = I.pilot()
	local before = effects(player)

	handler():getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE))
	lu.assertEquals(effects(player), before, "state after getInitialScreen with JTL off")
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track non-member's mission request and the duty hand-outs
---------------------------------------------------------------------------------------------

TestCrimsonT1NonMember = {}

function TestCrimsonT1NonMember:setUp()
	H.reset()
	I.requireConversation(lu)
end

local ASK = "s_1583743c"
local OFFER_EXPLAIN, OFFER_DUTY_MENU, OFFER_NO, OFFER_GROUND = "s_6106187c", "s_4ffd4b9d", "s_6e646769", "s_e0cb3e19"
local DESTROY_REPLY, ESCORT_REPLY = "s_6a0aba27", "s_2cb7683a"

local function vortex(o)
	o = o or {}
	o.squadron = squadron("VORTEX_SQUADRON")

	return I.pilot(o)
end

-- C-1
-- AC-6: a Vortex pilot with a ship and no quest -> non_member, whose reply leads to the duty offer only when canFlyNonTrackDuty
function TestCrimsonT1NonMember:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_a_tier_1_skill_and_flies_nothing()
	local t = I.talk(vortex({ tier = 1 }), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer" }, "a tier 1 skill, no mission, empty datapad")
	lu.assertEquals(I.optionSids(t[2]), { OFFER_EXPLAIN, OFFER_DUTY_MENU, OFFER_NO, OFFER_GROUND }, "the duty offer's replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-1
-- AC-6
function TestCrimsonT1NonMember:test_the_request_is_refused_without_a_tier_1_skill()
	local t = I.talk(vortex(), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_no_missions" }, "only the novice box")
	lu.assertTrue(t[2].stop, "non_member_no_missions ends the conversation")
end

-- C-1
-- AC-6
function TestCrimsonT1NonMember:test_the_request_is_refused_with_a_space_quest_in_the_datapad_or_a_running_chain()
	for _, o in ipairs({ { datapad = "story" }, { datapad = "duty" }, { duty = I.DUTY7 }, { paid = 1, state = "active" } }) do
		H.reset()

		local t = I.talk(vortex({ tier = 1, datapad = o.datapad, duty = o.duty, paid = o.paid, state = o.state }), { ASK })

		lu.assertEquals(I.ids(t), { "non_member", "non_member_no_missions" }, "tier 1 skill with " .. (o.datapad or o.duty or "a running mission 2"))
	end
end

-- C-1: the public helpers
-- AC-6
function TestCrimsonT1NonMember:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(vortex({ tier = 1 })), "tier 1 skill, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(vortex()), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(vortex({ tier = 1, duty = I.DUTY7 })), "her escort duty active")
	lu.assertFalse(h:canFlyNonTrackDuty(vortex({ tier = 1, paid = 1, state = "active" })), "her mission 2 active")
	lu.assertFalse(h:canFlyNonTrackDuty(vortex({ tier = 1, datapad = "story" })), "a story mission in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(vortex({ tier = 1, datapad = "duty" })), "a duty in the datapad")

	lu.assertTrue(h:isOnMission(I.pilot({ state = "active" })), "mission 1 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 1, state = "active" })), "mission 2 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 2, state = "active" })), "mission 3 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 3, state = "active" })), "mission 4 active")
	lu.assertTrue(h:isOnMission(I.pilot({ duty = I.DUTY6 })), "destroy duty active")
	lu.assertTrue(h:isOnMission(I.pilot({ duty = I.DUTY7 })), "escort duty active")
	lu.assertFalse(h:isOnMission(I.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(I.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")
end

local function spyDuties()
	return H.spyOn(I.quest(I.DUTY6), "startQuest"), H.spyOn(I.quest(I.DUTY7), "startQuest")
end

-- C-1: the off-track duty menu starts Da'la Socuna's duties (one destroy screen, no gender split)
-- AC-6, AC-7
function TestCrimsonT1NonMember:test_the_off_track_duty_menu_starts_the_destroy_duty()
	local d6, d7 = spyDuties()
	local t = I.talk(vortex({ tier = 1 }), { ASK, OFFER_DUTY_MENU, DESTROY_REPLY })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty" }, "screens shown")
	lu.assertTrue(t[4].stop, "destroy_duty ends")
	lu.assertEquals(#d6, 1, "destroy duty started")
	lu.assertEquals(#d7, 0, "escort duty not started")
end

-- C-1
-- AC-6, AC-7
function TestCrimsonT1NonMember:test_the_off_track_duty_menu_starts_the_escort_duty()
	local d6, d7 = spyDuties()
	local t = I.talk(vortex({ tier = 1 }), { ASK, OFFER_DUTY_MENU, ESCORT_REPLY })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", "escort_duty" }, "screens shown")
	lu.assertEquals(#d7, 1, "escort duty started")
	lu.assertEquals(#d6, 0, "destroy duty not started")
end

-- C-1: the explanation, the refusal and the ground-forces answer start nothing
-- AC-6
function TestCrimsonT1NonMember:test_the_duty_explanation_the_refusal_and_the_ground_forces_answer_start_nothing()
	local d6, d7 = spyDuties()
	local t = I.talk(vortex({ tier = 1 }), { ASK, OFFER_EXPLAIN })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_explained" }, "the explanation")
	lu.assertEquals(I.optionSids(t[3]), { OFFER_EXPLAIN, OFFER_DUTY_MENU, OFFER_NO, OFFER_GROUND }, "the explanation loops back to the same four replies")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")

	H.reset()
	d6, d7 = spyDuties()
	t = I.talk(vortex({ tier = 1 }), { ASK, OFFER_GROUND })
	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "enlist_ground" }, "ground forces")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")

	H.reset()
	d6, d7 = spyDuties()
	t = I.talk(vortex({ tier = 1 }), { ASK, OFFER_NO })
	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_no_thanks" }, "no thanks")
	lu.assertTrue(t[3].stop, "duty_no_thanks ends")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")
end

---------------------------------------------------------------------------------------------
-- The grounded dialogue (FI-3, D-4)
---------------------------------------------------------------------------------------------

TestCrimsonT1Grounded = {}

function TestCrimsonT1Grounded:setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUNDED_WALK = { "s_370822d1", "s_841d27db", "s_4d2987d3" }
local GROUNDED_IDS = { "grounded", "grounded_bad_news", "grounded_why", "grounded_framed" }

-- AC-6: the whole chain, grants nothing, changes nothing
function TestCrimsonT1Grounded:test_the_walk_leads_through_the_three_replies_to_the_framed_line_and_grants_nothing()
	local player = I.pilot({ standing = -3 })
	local t = I.talk(player, GROUNDED_WALK)

	lu.assertEquals(I.ids(t), GROUNDED_IDS, "screens shown")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_eff4eef6", "'%TU, isn't it?'")
	lu.assertEquals(t[2].text, I.PREFIX .. "s_90087734", "bad news")
	lu.assertEquals(t[3].text, I.PREFIX .. "s_4c85e14a", "the accusation")
	lu.assertEquals(t[4].text, I.PREFIX .. "s_4dd4aa17", "framed")
	lu.assertTrue(t[4].stop, "grounded_framed ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "%TU of the greeting")
	lu.assertEquals(t[2].params.TU, "Ace", "%NU of the bad news (setDialogTextTU, D-15)")
	lu.assertEquals(t[4].params.TU, "Ace", "%TU of the framed line")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	lu.assertEquals(#player.ghost.waypoints, 0, "no waypoint")
	lu.assertEquals(player.ghost.factionStanding.rebel, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the grounded walk")
end

-- AC-6: the same dialogue for a Havoc pilot who lost the Rebel faction, and nothing is offered on it
function TestCrimsonT1Grounded:test_a_pilot_without_rebel_faction_walks_the_same_dialogue_and_is_offered_nothing()
	local player = I.pilot({ faction = "neutral", squadron = squadron("HAVOC_SQUADRON") })
	local t = I.talk(player, GROUNDED_WALK)

	lu.assertEquals(I.ids(t), GROUNDED_IDS, "screens shown")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")

	for i = 1, 3 do
		lu.assertEquals(#t[i].options, 1, "grounded step " .. i .. ": exactly one reply")
	end
end
