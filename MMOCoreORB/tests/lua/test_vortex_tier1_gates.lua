-- V3-FX: which screen a pilot opens on (gate table G), the conditional link C-1, the duty hand-outs and the grounded dialogue.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (AC-6; Conversation flow 1 and 2; FI-1, FI-3, FI-5, FI-7; D-4 to D-8, D-10; I-10).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- vortex_tier1_data.lua V.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).
-- The order is J's, with the two Core3 adaptations of the spec (JTL first, the tier-done gate needs the mission 4 reward).

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")
local CS = require("harness.client_strings")

I.load()

TestVortexT1Gates = {}

function TestVortexT1Gates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function opens(player) return I.firstScreen(player) end

local function handler() return rawget(_G, I.HANDLER) end

local function squadron(name) return rawget(_G, name) end

-- G0
-- AC-6
function TestVortexT1Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = I.pilot(), I.npc(), H.conversationTemplate(I.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestVortexT1Gates:test_jtl_disabled_opens_no_jtl()
	H.Engine.config.jtlEnabled = false

	local t = I.talk(I.pilot())

	lu.assertEquals(I.ids(t), { "no_jtl" }, "JTL disabled")
	lu.assertTrue(t[1].stop, "no_jtl ends the conversation")
	lu.assertEquals(#t[1].options, 0, "no_jtl offers no reply")
end

-- AC-6
function TestVortexT1Gates:test_a_pilot_without_a_player_object_opens_no_jtl()
	local player = I.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "no_jtl", "ghost is nil (SWG !hasSpaceExpansion)")
end

-- AC-6: the JTL gate comes before everything, including the help line (the one adaptation of J's order)
function TestVortexT1Gates:test_jtl_disabled_beats_the_first_mission_help_and_every_other_gate()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(I.pilot({ state = "active" })), "no_jtl", "JTL disabled with mission 1 active")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false })), "no_jtl", "JTL disabled, a neutral pilot")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, faction = "neutral" })), "no_jtl", "JTL disabled, a neutral non-pilot")
end

-- G2
-- AC-6
function TestVortexT1Gates:test_a_pilot_with_a_ship_and_mission_1_active_opens_the_first_mission_help()
	local t = I.talk(I.pilot({ state = "active" }))

	lu.assertEquals(I.ids(t), { "first_mission_help" }, "mission 1 patrol active")
	lu.assertEquals(I.optionSids(t[1]), { "s_60c4f974", "s_85dd7d6c", "s_4358efe9" }, "the three questions")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-6
function TestVortexT1Gates:test_the_surprise_attack_being_active_also_counts_as_mission_1_active()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "active")
	lu.assertEquals(opens(player), "first_mission_help", "patrol complete, surprise attack active")
end

-- AC-6: the help line comes before every faction and membership gate (only the JTL gate precedes it)
function TestVortexT1Gates:test_the_help_line_comes_before_the_faction_and_membership_gates()
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "imperial" })), "first_mission_help", "imperial faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "neutral" })), "first_mission_help", "no faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", squadron = false })), "first_mission_help", "no squadron, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", standing = -5 })), "first_mission_help", "negative standing, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", graduated = true })), "first_mission_help", "graduation key, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", datapad = "story" })), "first_mission_help", "a datapad mission, mission 1 active: G2 precedes G9")
	lu.assertEquals(opens(I.pilot({ state = "active", pilot = "neutral", squadron = false })), "first_mission_help", "a neutral pilot with mission 1 active: G2 precedes G3")
end

-- G2 needs a certified ship
-- AC-6
function TestVortexT1Gates:test_mission_1_active_without_a_ship_does_not_open_the_help()
	lu.assertEquals(opens(I.pilot({ state = "active", ship = false })), "lost_ship", "no certified ship: G8")
end

-- G3
-- AC-6
function TestVortexT1Gates:test_a_corsec_pilot_opens_privateer_pilot_before_the_faction_gates()
	local t = I.talk(I.pilot({ pilot = "neutral", squadron = squadron("CORSEC_SQUADRON") }))

	lu.assertEquals(I.ids(t), { "privateer_pilot" }, "a CorSec pilot")
	lu.assertEquals(I.optionSids(t[1]), { "s_b26194cb", "s_ca776e30", "s_1a53f653" }, "the three questions")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "privateer_pilot", "neutral pilot, no faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "imperial" })), "privateer_pilot", "neutral pilot, Imperial faction: G3 precedes G4")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, ship = false })), "privateer_pilot", "neutral pilot without a ship: G3 precedes G8")
end

-- G4
-- AC-6
function TestVortexT1Gates:test_an_imperial_faction_non_pilot_or_an_imperial_pilot_opens_imperial_pilot()
	local t = I.talk(I.pilot({ pilot = false, faction = "imperial", squadron = false }))

	lu.assertEquals(I.ids(t), { "imperial_pilot" }, "an Imperial-faction non-pilot")
	lu.assertEquals(I.optionSids(t[1]), { "s_a425f33d", "s_c16bab26", "s_9f6cf52" }, "the three replies")
	lu.assertEquals(opens(I.pilot({ pilot = "imperial", faction = "rebel", squadron = false })), "imperial_pilot", "an Imperial pilot with Rebel faction")
	lu.assertEquals(opens(I.pilot({ pilot = "imperial", faction = "neutral", squadron = false })), "imperial_pilot", "an Imperial pilot with no faction")
	lu.assertEquals(opens(I.pilot({ faction = "imperial" })), "imperial_pilot", "a Vortex pilot with Imperial faction: G4 precedes G5 and G7")
end

-- G5
-- AC-6
function TestVortexT1Gates:test_a_neutral_non_pilot_opens_not_rebel_which_ends_without_replies_or_sparks()
	local t = I.talk(I.pilot({ pilot = false, faction = "neutral", squadron = false }))

	lu.assertEquals(I.ids(t), { "not_rebel" }, "a non-pilot without faction")
	lu.assertTrue(t[1].stop, "not_rebel ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_rebel offers no reply")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_eedd7284", "the droid's 'I cannot help you with that. *bzzt*' line (D-5)")
	lu.assertEquals(#I.sparks(), 0, "no sparks on not_rebel (only no_jtl, privateer_training and imperial_answers spark)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G5
-- AC-6
function TestVortexT1Gates:test_a_rebel_pilot_whose_faction_is_not_rebel_opens_grounded_with_its_reply()
	local havoc = I.talk(I.pilot({ faction = "neutral", squadron = squadron("HAVOC_SQUADRON") }))

	lu.assertEquals(I.ids(havoc), { "grounded" }, "a Havoc pilot whose faction is neutral")
	lu.assertEquals(I.optionSids(havoc[1]), { "s_10581a3e" }, "grounded reply")
	lu.assertFalse(havoc[1].stop, "grounded does not end: the reply follows")
	lu.assertEquals(opens(I.pilot({ faction = "neutral" })), "grounded", "a Vortex pilot without Rebel faction: G5 precedes G7")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", squadron = false, ship = false })), "grounded", "G5 precedes G8")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", standing = 500 })), "grounded", "good standing does not help without the faction")
end

-- G6
-- AC-6
function TestVortexT1Gates:test_a_rebel_faction_non_pilot_opens_recruitment()
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false })), "recruitment", "Rebel faction, no pilot skills")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, ship = false })), "recruitment", "Rebel faction, no pilot skills, no ship: G6 precedes G8")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, standing = -50 })), "recruitment", "negative Rebel standing does not stop a non-pilot (G10 is for members)")
end

-- G7
-- AC-6
function TestVortexT1Gates:test_a_rebel_pilot_of_another_squadron_or_none_opens_non_member()
	lu.assertEquals(opens(I.pilot({ squadron = squadron("HAVOC_SQUADRON") })), "non_member", "Havoc pilot")
	lu.assertEquals(opens(I.pilot({ squadron = squadron("CRIMSON_PHOENIX_SQUADRON") })), "non_member", "Crimson Phoenix pilot")
	lu.assertEquals(opens(I.pilot({ squadron = false })), "non_member", "a Rebel pilot without a squadron (D-7: no track adoption)")
	lu.assertEquals(opens(I.pilot({ squadron = false, ship = false })), "non_member", "no ship: G7 precedes G8")
	lu.assertEquals(opens(I.pilot({ squadron = false, datapad = "story" })), "non_member", "a datapad mission: G7 precedes G9")
	lu.assertEquals(opens(I.pilot({ squadron = false, standing = -1 })), "non_member", "negative standing: G7 precedes G10")
	lu.assertEquals(opens(I.pilot({ squadron = false, graduated = true })), "non_member", "graduation key of a pilot who left the squadron: G7 precedes G11")
end

-- G8
-- AC-6
function TestVortexT1Gates:test_a_vortex_pilot_without_a_certified_ship_opens_lost_ship()
	local t = I.talk(I.pilot({ ship = false }))

	lu.assertEquals(I.ids(t), { "lost_ship" }, "Vortex member without a ship")
	lu.assertTrue(t[1].stop, "lost_ship ends the conversation")
	lu.assertEquals(opens(I.pilot({ ship = false, paid = 2 })), "lost_ship", "with two missions paid")
	lu.assertEquals(opens(I.pilot({ ship = false, datapad = "story" })), "lost_ship", "G8 precedes G9")
	lu.assertEquals(opens(I.pilot({ ship = false, standing = -1 })), "lost_ship", "G8 precedes G10")
	lu.assertEquals(opens(I.pilot({ ship = false, graduated = true, paid = 4, tier = 4 })), "lost_ship", "a graduate without a ship: G8 precedes G11")
end

-- G9
-- AC-6
function TestVortexT1Gates:test_a_vortex_pilot_with_any_space_quest_opens_on_mission()
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
function TestVortexT1Gates:test_mission_3_with_the_escort_active_after_the_patrol_is_still_running()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	I.setState(player, I.E3, "active")
	lu.assertEquals(opens(player), "on_mission", "the escort split is running")
end

-- G10 (D-4)
-- AC-6
function TestVortexT1Gates:test_a_member_with_negative_rebel_standing_opens_grounded()
	local t = I.talk(I.pilot({ standing = -1 }))

	lu.assertEquals(I.ids(t), { "grounded" }, "Vortex pilot, standing -1")
	lu.assertEquals(I.optionSids(t[1]), { "s_10581a3e" }, "grounded reply")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 4, tier = 4 })), "grounded", "everything done, standing -1")
	lu.assertEquals(opens(I.pilot({ standing = -1, graduated = true })), "grounded", "G10 precedes graduated (G11)")
	lu.assertEquals(opens(I.pilot({ standing = 0 })), "mission1_offer", "standing 0 is served normally")
end

-- AC-6: the gate lifts at 0
function TestVortexT1Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = I.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "grounded", "standing -1")
	player.ghost.factionStanding.rebel = 0
	lu.assertEquals(opens(player), "mission2_offer", "standing 0")
end

-- G11
-- AC-6, AC-10
function TestVortexT1Gates:test_the_graduation_key_opens_graduated()
	local t = I.talk(I.pilot({ graduated = true, paid = 4, tier = 4 }))

	lu.assertEquals(I.ids(t), { "graduated" }, "promoted pilot")
	lu.assertEquals(I.optionSids(t[1]), { "s_741df7ed", "s_2be1e8b", "s_b3bebc5e" }, "the three direction questions")
	lu.assertEquals(opens(I.pilot({ graduated = true })), "graduated", "the key alone")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4, tier = 4, xp = 100000 })), "graduated", "with XP to spare")
	lu.assertEquals(opens(I.pilot({ graduated = true, paid = 4 })), "graduated", "G11 precedes the training gates")
end

-- G11, R-1: graduated is "the key is set" (SWG hasSpaceFlag), whatever the value; tier 2 writes "2" and "3" (D-11)
-- AC-6, AC-10
function TestVortexT1Gates:test_any_set_graduation_key_value_opens_graduated_and_is_left_alone()
	for _, value in ipairs({ "1", "2", "3" }) do
		local player = I.pilot({ graduated = value, paid = 4, tier = 4 })
		local t = I.talk(player)

		lu.assertEquals(I.ids(t), { "graduated" }, "key '" .. value .. "': first screen")
		lu.assertEquals(H.getQuestStatus(player, I.VORTEX_PILOT_KEY), value, "key '" .. value .. "': unchanged after the talk")

		-- a second talk is the same
		lu.assertEquals(I.firstScreen(player), "graduated", "key '" .. value .. "': second talk")
		lu.assertEquals(H.getQuestStatus(player, I.VORTEX_PILOT_KEY), value, "key '" .. value .. "': unchanged after the second talk")
	end
end

-- G12
-- AC-6
function TestVortexT1Gates:test_all_four_skills_and_the_mission_4_reward_open_tier_done()
	local t = I.talk(I.pilot({ paid = 4, tier = 4 }))

	lu.assertEquals(I.ids(t), { "tier_done" }, "four tier 1 skills, mission 4 paid")
	lu.assertEquals(I.optionSids(t[1]), { "s_f75b511f", "s_4efbdbfa", "s_b89c30f1", "s_1df40ac6", "s_8334632" }, "the five replies")
end

-- AC-6, FI-7: the tier-done gate needs the mission 4 reward
function TestVortexT1Gates:test_mission_4_won_and_unpaid_beats_the_tier_done_and_the_training_gates()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 4 })), "mission4_won", "four skills, mission 4 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 1, xp = 99999 })), "mission4_won", "one skill, XP, mission 4 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won" })), "mission4_won", "no skill, mission 4 won and unpaid")
end

-- G13 .. G24: one row per mission
local MISSIONS = {
	{ n = 1, won = "mission1_won", failed = "mission1_failed", offer = "mission1_offer" },
	{ n = 2, won = "mission2_won", failed = "mission2_failed", offer = "mission2_offer" },
	{ n = 3, won = "mission3_won", failed = "mission3_failed", offer = "mission3_offer" },
	{ n = 4, won = "mission4_won", failed = "mission4_failed", offer = "mission4_offer" },
}

for _, m in ipairs(MISSIONS) do
	-- AC-6, AC-8
	TestVortexT1Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.won] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "won" })), m.won, "mission " .. m.n .. " won, reward unpaid")
	end

	-- AC-6, AC-7 (an abort is a failure, FI-4)
	TestVortexT1Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.failed] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "failed" })), m.failed, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- AC-6
	TestVortexT1Gates["test_mission_" .. m.n .. "_not_started_opens_" .. m.offer] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1 })), m.offer, "missions before " .. m.n .. " paid")
	end
end

-- AC-6, D-6 (FI-5): a lost surprise attack is a mission 1 failure, not the mission 1 offer SWG shows (its typo)
function TestVortexT1Gates:test_mission_1_with_the_patrol_won_and_the_surprise_attack_lost_opens_mission1_failed()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	lu.assertEquals(opens(player), "mission1_failed", "patrol complete, surprise attack never won (D-6)")
	lu.assertEquals(opens(I.pilot({ state = "failed" })), "mission1_failed", "patrol failed")
end

-- AC-6, D-6: mission 3 counts as won only when the patrol and the escort are both complete
function TestVortexT1Gates:test_mission_3_with_only_the_patrol_complete_is_not_won()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	lu.assertEquals(opens(player), "mission3_failed", "patrol complete, escort never flown")
end

-- AC-6: mission 1 won needs the patrol and the surprise attack both complete
function TestVortexT1Gates:test_mission_1_is_won_only_when_the_patrol_and_the_surprise_attack_are_both_complete()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "complete")
	lu.assertEquals(opens(player), "mission1_won", "both complete, unpaid")
end

-- G25
-- AC-6
function TestVortexT1Gates:test_mission_4_paid_with_no_skill_opens_training_first_whatever_the_xp()
	local t = I.talk(I.pilot({ paid = 4 }))

	lu.assertEquals(I.ids(t), { "training_first" }, "no tier 1 skill, no XP: the first skill is free")
	lu.assertEquals(opens(I.pilot({ paid = 4, xp = 99999 })), "training_first", "no skill, plenty of XP")
end

-- G26
-- AC-6
function TestVortexT1Gates:test_mission_4_paid_with_some_skills_and_7500_xp_opens_training_more()
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, xp = 7500 })), "training_more", "one skill, 7500 XP")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3, xp = 99999 })), "training_more", "three skills, plenty of XP")
end

-- G27
-- AC-6
function TestVortexT1Gates:test_mission_4_paid_with_some_skills_but_too_little_xp_opens_duty_missions()
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, xp = 7499 })), "duty_missions", "one skill, 7499 XP")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3 })), "duty_missions", "three skills, no XP")
end

-- AC-6: every gate screen exists in Appendix A and the template
function TestVortexT1Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(I.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "no_jtl", "first_mission_help", "privateer_pilot", "imperial_pilot", "not_rebel", "grounded", "recruitment", "non_member", "lost_ship", "on_mission", "graduated", "tier_done",
		"mission1_failed", "mission2_failed", "mission3_failed", "mission4_failed", "mission1_offer", "mission1_won", "mission2_offer", "mission2_won", "mission3_offer", "mission3_won",
		"mission4_offer", "mission4_won", "training_first", "training_more", "duty_missions" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(I.TEMPLATE)):getScreen(id), I.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- I-10: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestVortexT1PureGates = {}

function TestVortexT1PureGates:setUp()
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
	out.journal = player.ghost and I.state(player, I.P1) .. I.state(player, I.M2) .. I.state(player, I.P3) .. I.state(player, I.A4) .. I.state(player, I.DUTY6) .. I.state(player, I.DUTY7)

	for _, suffix in ipairs({ "naboo_rebel_1:attempted", "naboo_rebel_1:reward", "naboo_rebel_2:attempted", "naboo_rebel_2:reward",
		"naboo_rebel_3:attempted", "naboo_rebel_3:reward", "naboo_rebel_4:attempted", "naboo_rebel_4:reward", I.VORTEX_PILOT_KEY }) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	return out
end

-- I-10, AC-6: the gate decision itself writes nothing, for pilots of every kind and state (the on-display actions are the screens')
function TestVortexT1PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return I.pilot() end,
		function() return I.pilot({ state = "active" }) end,
		function() return I.pilot({ faction = "imperial" }) end,
		function() return I.pilot({ pilot = "neutral", squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false, faction = "neutral" }) end,
		function() return I.pilot({ faction = "neutral" }) end,
		function() return I.pilot({ squadron = false }) end,
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
		function() return I.pilot({ squadron = false, tier = 1 }) end,
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

-- I-10: and with JTL off and no ghost (the sparks belong to the screen's display, not to the gate)
function TestVortexT1PureGates:test_the_no_jtl_gate_plays_no_effect_before_the_screen_is_shown()
	H.Engine.config.jtlEnabled = false

	local player = I.pilot()

	handler():getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE))
	lu.assertEquals(#I.sparks(), 0, "playClientEffectLoc calls made by getInitialScreen")
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track non-member's mission request and the duty hand-outs
---------------------------------------------------------------------------------------------

TestVortexT1NonMember = {}

function TestVortexT1NonMember:setUp()
	H.reset()
	I.requireConversation(lu)
end

local ASK = "s_ac05bfba"
local OFFER_DUTY_MENU, OFFER_EXPLAIN, OFFER_GROUND = "s_4ffd4b9d", "s_6106187c", "s_761039fa"
local DESTROY_REPLY, ESCORT_REPLY = "s_cf63ee80", "s_a66ff602"

local function havoc(o)
	o = o or {}
	o.squadron = squadron("HAVOC_SQUADRON")

	return I.pilot(o)
end

-- C-1
-- AC-6
function TestVortexT1NonMember:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_a_tier_1_skill_and_flies_nothing()
	local t = I.talk(havoc({ tier = 1 }), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer" }, "a tier 1 skill, no mission, empty datapad")
	lu.assertEquals(I.optionSids(t[2]), { OFFER_EXPLAIN, OFFER_DUTY_MENU, OFFER_GROUND }, "the duty offer's replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-1
-- AC-6
function TestVortexT1NonMember:test_the_request_is_refused_without_a_tier_1_skill()
	local t = I.talk(havoc(), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_no_missions" }, "only the novice box")
	lu.assertTrue(t[2].stop, "non_member_no_missions ends the conversation")
end

-- C-1
-- AC-6: a non-member with a space quest opens non_member (G7 precedes G9), and the request is refused
function TestVortexT1NonMember:test_the_request_is_refused_with_a_space_quest_in_the_datapad_or_a_running_chain()
	for _, o in ipairs({ { datapad = "story" }, { datapad = "duty" }, { duty = I.DUTY7 }, { paid = 1, state = "active" } }) do
		H.reset()

		local t = I.talk(havoc({ tier = 1, datapad = o.datapad, duty = o.duty, paid = o.paid, state = o.state }), { ASK })

		lu.assertEquals(I.ids(t), { "non_member", "non_member_no_missions" }, "tier 1 skill with " .. (o.datapad or o.duty or "a running mission 2"))
	end
end

-- C-1: the two public helpers
-- AC-6
function TestVortexT1NonMember:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(havoc({ tier = 1 })), "tier 1 skill, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(havoc()), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(havoc({ tier = 1, duty = I.DUTY7 })), "his escort duty active")
	lu.assertFalse(h:canFlyNonTrackDuty(havoc({ tier = 1, paid = 1, state = "active" })), "his mission 2 active")
	lu.assertFalse(h:canFlyNonTrackDuty(havoc({ tier = 1, datapad = "story" })), "a story mission in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(havoc({ tier = 1, datapad = "duty" })), "a duty in the datapad")

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

-- C-1, C-6: the off-track duty menu starts V3-FX's duties, the destroy duty by gender
-- AC-6, AC-7
function TestVortexT1NonMember:test_the_off_track_duty_menu_starts_the_destroy_duty_for_a_man_and_a_woman()
	for gender, screen in pairs({ [0] = "destroy_duty_male", [1] = "destroy_duty_female" }) do
		H.reset()

		local d6, d7 = spyDuties()
		local t = I.talk(havoc({ tier = 1, gender = gender }), { ASK, OFFER_DUTY_MENU, DESTROY_REPLY })

		lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", screen }, "screens shown, gender " .. gender)
		lu.assertTrue(t[4].stop, screen .. " ends")
		lu.assertEquals(#d6, 1, "destroy duty started, gender " .. gender)
		lu.assertEquals(#d7, 0, "escort duty not started, gender " .. gender)
	end
end

-- C-1
-- AC-6, AC-7
function TestVortexT1NonMember:test_the_off_track_duty_menu_starts_the_escort_duty()
	local d6, d7 = spyDuties()
	local t = I.talk(havoc({ tier = 1 }), { ASK, OFFER_DUTY_MENU, ESCORT_REPLY })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", "escort_duty" }, "screens shown")
	lu.assertEquals(#d7, 1, "escort duty started")
	lu.assertEquals(#d6, 0, "destroy duty not started")
end

-- C-1: the explanation and the ground-forces answer start nothing
-- AC-6
function TestVortexT1NonMember:test_the_duty_explanation_and_the_ground_forces_answer_start_nothing()
	local d6, d7 = spyDuties()
	local t = I.talk(havoc({ tier = 1 }), { ASK, OFFER_EXPLAIN })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_explained" }, "the explanation")
	lu.assertEquals(I.optionSids(t[3]), { OFFER_EXPLAIN, OFFER_DUTY_MENU, OFFER_GROUND }, "the explanation loops back to the same three replies")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")

	H.reset()
	d6, d7 = spyDuties()
	t = I.talk(havoc({ tier = 1 }), { ASK, OFFER_GROUND })
	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "enlist_ground" }, "ground forces")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")
end

---------------------------------------------------------------------------------------------
-- The grounded dialogue (FI-3, D-4)
---------------------------------------------------------------------------------------------

TestVortexT1Grounded = {}

function TestVortexT1Grounded:setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUNDED_WALK = { "s_10581a3e", "s_7426e000", "s_f8b02865", "s_6576f571" }
local GROUNDED_IDS = { "grounded", "grounded_error", "grounded_bad_news", "grounded_standing", "grounded_missions" }

-- AC-6: the whole chain, grants nothing, changes nothing
function TestVortexT1Grounded:test_the_walk_leads_through_the_four_replies_to_the_missions_line_and_grants_nothing()
	local player = I.pilot({ standing = -3 })
	local t = I.talk(player, GROUNDED_WALK)

	lu.assertEquals(I.ids(t), GROUNDED_IDS, "screens shown")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_60c2803a", "greeting")
	lu.assertEquals(t[2].text, I.PREFIX .. "s_3fc246bd", "the accusation")
	lu.assertEquals(t[3].text, I.PREFIX .. "s_de748105", "bad news")
	lu.assertEquals(t[4].text, I.PREFIX .. "s_da1db2a5", "improve your standing")
	lu.assertEquals(t[5].text, I.PREFIX .. "s_692451bc", "the missions line")
	lu.assertTrue(t[5].stop, "grounded_missions ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "%TU of the greeting")
	lu.assertEquals(t[3].params.TU, "Ace", "%TU of the bad news")
	lu.assertEquals(t[5].params.TU, "Ace", "%TU of the missions line")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	lu.assertEquals(#I.sparks(), 0, "no sparks")
	lu.assertEquals(player.ghost.factionStanding.rebel, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the grounded walk")
end

-- AC-6: the same dialogue for a Havoc pilot who lost the Rebel faction, and nothing is offered on it
function TestVortexT1Grounded:test_a_pilot_without_rebel_faction_walks_the_same_dialogue_and_is_offered_nothing()
	local player = I.pilot({ faction = "neutral", squadron = squadron("HAVOC_SQUADRON") })
	local t = I.talk(player, GROUNDED_WALK)

	lu.assertEquals(I.ids(t), GROUNDED_IDS, "screens shown")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")

	for i = 1, 4 do
		lu.assertEquals(#t[i].options, 1, "grounded step " .. i .. ": exactly one reply")
	end
end
