-- Lt. Akal Colzet: which screen a pilot opens on (gate table G), the conditional link C-1 and the grounded dialogue.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-6; Conversation flow 1 and 2; FI-1, FI-3, FI-8; D-4, D-5, D-6; I-10).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- storm_tier1_data.lua I.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).
-- J's gate order is kept (D-6): the lost-ship loan (G3) and on-mission (G6) come before the faction and membership gates.

local lu = require("luaunit")
local H = require("harness")
local I = require("storm_tier1_data")
local CS = require("harness.client_strings")

I.load()

TestStormT1Gates = {}

function TestStormT1Gates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function opens(player) return I.firstScreen(player) end

local function handler() return rawget(_G, I.HANDLER) end

-- G0
-- AC-6
function TestStormT1Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = I.pilot(), I.npc(), H.conversationTemplate(I.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestStormT1Gates:test_jtl_disabled_opens_no_jtl()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(I.pilot()), "no_jtl", "JTL disabled")
end

-- AC-6
function TestStormT1Gates:test_a_pilot_without_a_player_object_opens_no_jtl()
	local player = I.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "no_jtl", "ghost is nil")
end

-- AC-6: the JTL gate comes before everything, including the help line
function TestStormT1Gates:test_jtl_disabled_beats_the_first_mission_help()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(I.pilot({ state = "active" })), "no_jtl", "JTL disabled with mission 1 active")
end

-- G2
-- AC-6
function TestStormT1Gates:test_a_pilot_with_a_ship_and_mission_1_active_opens_the_first_mission_help_which_ends()
	local t = I.talk(I.pilot({ state = "active" }))

	lu.assertEquals(I.ids(t), { "first_mission_help" }, "mission 1 patrol active")
	lu.assertTrue(t[1].stop, "first_mission_help ends the conversation")
	lu.assertEquals(#t[1].options, 0, "first_mission_help offers no reply")
end

-- AC-6
function TestStormT1Gates:test_the_surprise_attack_being_active_also_counts_as_mission_1_active()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	I.setState(player, I.S1, "active")
	lu.assertEquals(opens(player), "first_mission_help", "patrol complete, surprise attack active")
end

-- AC-6: the help line comes before every faction and membership gate
function TestStormT1Gates:test_the_help_line_comes_before_the_faction_and_membership_gates()
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "rebel" })), "first_mission_help", "rebel faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", faction = "neutral" })), "first_mission_help", "no faction, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", squadron = false })), "first_mission_help", "other squadron, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", standing = -5 })), "first_mission_help", "negative standing, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", series = true })), "first_mission_help", "series flag, mission 1 active")
	lu.assertEquals(opens(I.pilot({ state = "active", datapad = "story" })), "first_mission_help", "a datapad mission, mission 1 active: G2 precedes G6")
end

-- G2 needs a certified ship
-- AC-6
function TestStormT1Gates:test_mission_1_active_without_a_ship_does_not_open_the_help()
	lu.assertEquals(opens(I.pilot({ state = "active", ship = false })), "lost_ship", "no certified ship: G3")
end

-- G3 (D-6: J's order)
-- AC-6
function TestStormT1Gates:test_an_imperial_pilot_without_a_ship_opens_lost_ship_before_the_faction_and_membership_gates()
	lu.assertEquals(opens(I.pilot({ ship = false })), "lost_ship", "Storm member without a ship")
	lu.assertEquals(opens(I.pilot({ ship = false, paid = 2 })), "lost_ship", "Storm member with two missions paid, no ship")
	lu.assertEquals(opens(I.pilot({ ship = false, standing = -1 })), "lost_ship", "G3 precedes the standing gate G9")
	lu.assertEquals(opens(I.pilot({ ship = false, faction = "neutral" })), "lost_ship", "G3 precedes the grounded gate G7")
	lu.assertEquals(opens(I.pilot({ ship = false, squadron = rawget(_G, "BLACK_EPSILON_SQUADRON") })), "lost_ship", "a Black Epsilon pilot without a ship: G3 precedes G8")
	lu.assertEquals(opens(I.pilot({ ship = false, squadron = false })), "lost_ship", "a squadron-less Imperial pilot without a ship")
	lu.assertEquals(opens(I.pilot({ ship = false, series = true, paid = 4, tier = 4 })), "lost_ship", "a graduate without a ship: G3 precedes G10")
end

-- G4
-- AC-6
function TestStormT1Gates:test_a_neutral_pilot_opens_neutral_pilot_before_the_rebel_gate()
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false })), "neutral_pilot", "neutral pilot, Imperial faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "neutral_pilot", "neutral pilot, no faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "rebel" })), "neutral_pilot", "neutral pilot with rebel faction: G4 precedes G5")
end

-- G5
-- AC-6
function TestStormT1Gates:test_rebel_faction_or_a_rebel_pilot_opens_rebel_pilot()
	lu.assertEquals(opens(I.pilot({ faction = "rebel" })), "rebel_pilot", "Storm pilot with rebel faction")
	lu.assertEquals(opens(I.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "rebel_pilot", "rebel pilot")
	lu.assertEquals(opens(I.pilot({ pilot = false, faction = "rebel", squadron = false })), "rebel_pilot", "rebel faction non-pilot")
end

-- G5 / G7: no standing test for non-pilots
-- AC-6
function TestStormT1Gates:test_a_non_pilot_with_negative_imperial_standing_is_not_called_a_rebel()
	lu.assertEquals(opens(I.pilot({ pilot = false, faction = "neutral", squadron = false, standing = -300 })), "not_imperial", "no faction, negative Imperial standing")
	lu.assertEquals(opens(I.pilot({ pilot = false, faction = "imperial", squadron = false, standing = -1 })), "recruitment", "Imperial faction non-pilot with standing -1 may still hear the recruitment")
end

-- G6 (D-6)
-- AC-6
function TestStormT1Gates:test_an_imperial_pilot_with_any_space_quest_opens_on_mission_even_from_another_squadron()
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "active" })), "on_mission", "mission 3 active")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "active" })), "on_mission", "mission 4 active")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 4, duty = I.DUTY6 })), "on_mission", "destroy duty active")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 4, duty = I.DUTY7 })), "on_mission", "escort duty active")
	lu.assertEquals(opens(I.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(I.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
	lu.assertEquals(opens(I.pilot({ squadron = rawget(_G, "BLACK_EPSILON_SQUADRON"), datapad = "story" })), "on_mission", "a Black Epsilon pilot with a space quest")
	lu.assertEquals(opens(I.pilot({ squadron = false, datapad = "duty" })), "on_mission", "a squadron-less Imperial pilot with a duty")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 1, state = "active" })), "on_mission", "G6 precedes the grounded gate G9")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", paid = 1, state = "active" })), "on_mission", "G6 precedes the grounded gate G7")
	lu.assertEquals(opens(I.pilot({ series = true, paid = 4, tier = 4, datapad = "story" })), "on_mission", "G6 precedes series_complete (G10)")
	lu.assertEquals(opens(I.pilot({ series = true, paid = 4, tier = 4, duty = I.DUTY7 })), "on_mission", "a graduate on a duty")
end

-- AC-6: mission 3's escort running after the patrol is a running mission
function TestStormT1Gates:test_mission_3_with_the_escort_active_after_the_patrol_is_still_running()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	I.setState(player, I.E3, "active")
	lu.assertEquals(opens(player), "on_mission", "the escort split is running")
end

-- G7 (D-4, D-5)
-- AC-6
function TestStormT1Gates:test_an_imperial_pilot_whose_faction_is_gone_opens_grounded_with_the_replies()
	local t = I.talk(I.pilot({ faction = "neutral" }))

	lu.assertEquals(I.ids(t), { "grounded" }, "Storm pilot without Imperial faction")
	lu.assertEquals(I.optionSids(t[1]), { "s_7090182" }, "grounded replies")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_2844cc74", "grounded shares the not_imperial line")
	lu.assertFalse(t[1].stop, "grounded does not end: the replies follow")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", squadron = false })), "grounded", "a pilot of no squadron without Imperial faction: G7 precedes G8")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", standing = 5 })), "grounded", "good standing does not help without the faction")
end

-- G7 (D-5)
-- AC-6
function TestStormT1Gates:test_a_non_imperial_non_pilot_opens_not_imperial_which_ends_without_replies()
	local t = I.talk(I.pilot({ pilot = false, faction = "neutral", squadron = false }))

	lu.assertEquals(I.ids(t), { "not_imperial" }, "non-pilot without faction")
	lu.assertTrue(t[1].stop, "not_imperial ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_imperial offers no reply")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_2844cc74", "J's 'you are grounded' line")
end

-- G8
-- AC-6
function TestStormT1Gates:test_an_imperial_pilot_of_another_squadron_opens_non_member()
	lu.assertEquals(opens(I.pilot({ squadron = rawget(_G, "BLACK_EPSILON_SQUADRON") })), "non_member", "Black Epsilon pilot")
	lu.assertEquals(opens(I.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })), "non_member", "Inquisition pilot")
	lu.assertEquals(opens(I.pilot({ squadron = false })), "non_member", "pilot without a squadron")
	lu.assertEquals(opens(I.pilot({ squadron = false, standing = -1 })), "non_member", "other squadron with negative standing: G8 precedes G9")
	lu.assertEquals(opens(I.pilot({ squadron = false, series = true })), "non_member", "series flag of a pilot who left the squadron: G8 precedes G10")
end

-- G9 (D-4)
-- AC-6
function TestStormT1Gates:test_a_member_with_negative_imperial_standing_opens_grounded()
	lu.assertEquals(opens(I.pilot({ standing = -1 })), "grounded", "member, standing -1")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 4, tier = 4 })), "grounded", "member with everything done, standing -1")
	lu.assertEquals(opens(I.pilot({ standing = -1, series = true })), "grounded", "the grounded gate comes before series_complete")
	lu.assertEquals(opens(I.pilot({ standing = 0 })), "mission1_offer", "standing 0 is served normally")
end

-- G10 (FI-1)
-- AC-6, AC-10
function TestStormT1Gates:test_the_series_flag_opens_series_complete()
	local t = I.talk(I.pilot({ series = true, paid = 4, tier = 4 }))

	lu.assertEquals(I.ids(t), { "series_complete" }, "promoted pilot")
	lu.assertEquals(opens(I.pilot({ series = true })), "series_complete", "flag alone")
	lu.assertEquals(opens(I.pilot({ series = true, paid = 4, tier = 4, xp = 100000 })), "series_complete", "with XP to spare")
	lu.assertEquals(opens(I.pilot({ series = true, paid = 4 })), "series_complete", "G10 precedes training_offer")
end

-- G11
-- AC-6
function TestStormT1Gates:test_all_four_skills_and_the_mission_4_reward_open_tier_done()
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 4 })), "tier_done", "four tier 1 skills, mission 4 paid")
end

-- G12
-- AC-6
function TestStormT1Gates:test_mission_4_paid_with_no_skill_or_enough_xp_opens_training_offer()
	lu.assertEquals(opens(I.pilot({ paid = 4 })), "training_offer", "no tier 1 skill, no XP: the first skill is free")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, xp = 7500 })), "training_offer", "one skill, 7500 XP")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3, xp = 99999 })), "training_offer", "three skills, plenty of XP")
end

-- G13
-- AC-6
function TestStormT1Gates:test_mission_4_paid_with_some_skills_but_too_little_xp_opens_duty_missions()
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 1, xp = 7499 })), "duty_missions", "one skill, 7499 XP")
	lu.assertEquals(opens(I.pilot({ paid = 4, tier = 3 })), "duty_missions", "three skills, no XP")
end

-- G14 .. G25: one row per mission
local MISSIONS = {
	{ n = 4, won = "mission4_won", failed = "mission4_failed", offer = "mission4_offer" },
	{ n = 3, won = "mission3_won", failed = "mission3_failed", offer = "mission3_offer" },
	{ n = 2, won = "mission2_won", failed = "mission2_failed", offer = "mission2_offer" },
	{ n = 1, won = "mission1_won", failed = "mission1_failed", offer = "mission1_offer" },
}

for _, m in ipairs(MISSIONS) do
	-- AC-6, AC-8
	TestStormT1Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.won] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "won" })), m.won, "mission " .. m.n .. " won, reward unpaid")
	end

	-- AC-6, AC-7 (an abort is a failure, FI-4)
	TestStormT1Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.failed] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1, state = "failed" })), m.failed, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- AC-6
	TestStormT1Gates["test_mission_" .. m.n .. "_not_started_opens_" .. m.offer] = function(self)
		lu.assertEquals(opens(I.pilot({ paid = m.n - 1 })), m.offer, "missions before " .. m.n .. " paid")
	end
end

-- AC-6: M4 won and unpaid reaches mission4_won even with all four skills (G11 - G13 need the reward)
function TestStormT1Gates:test_mission_4_won_and_unpaid_beats_the_training_and_promotion_gates()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 4 })), "mission4_won", "four skills, mission 4 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", tier = 1, xp = 99999 })), "mission4_won", "one skill, XP, mission 4 won and unpaid")
end

-- AC-6: mission 1 counts as won only when the patrol and its surprise attack are both complete
function TestStormT1Gates:test_mission_1_with_only_the_patrol_complete_is_not_won()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")
	lu.assertEquals(opens(player), "mission1_failed", "patrol complete, surprise attack never flown")
end

-- AC-6, D-7: mission 3 counts as won only when the patrol and the escort are both complete
function TestStormT1Gates:test_mission_3_with_only_the_patrol_complete_is_not_won()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	lu.assertEquals(opens(player), "mission3_failed", "patrol complete, escort never flown")
end

-- G26
-- AC-6
function TestStormT1Gates:test_an_imperial_faction_non_pilot_opens_recruitment()
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false })), "recruitment", "Imperial faction, no pilot skills")
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, ship = false })), "recruitment", "Imperial faction, no pilot skills, no ship")
end

-- AC-6 (D-5): a neutral player cannot sign up
function TestStormT1Gates:test_a_neutral_faction_non_pilot_never_reaches_recruitment()
	lu.assertEquals(opens(I.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_imperial", "no faction")
end

-- AC-6: every gate screen exists in the template
function TestStormT1Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(I.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "no_jtl", "first_mission_help", "lost_ship", "neutral_pilot", "rebel_pilot", "on_mission", "not_imperial", "grounded", "non_member", "series_complete", "tier_done",
		"training_offer", "duty_missions", "mission4_won", "mission4_failed", "mission4_offer", "mission3_won", "mission3_failed", "mission3_offer", "mission2_won", "mission2_failed",
		"mission2_offer", "mission1_won", "mission1_failed", "mission1_offer", "recruitment" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(H.conversationTemplate(I.TEMPLATE) and LuaConversationTemplate(H.conversationTemplate(I.TEMPLATE)):getScreen(id), I.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- I-10: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestStormT1PureGates = {}

function TestStormT1PureGates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function effects(player)
	local out = {}

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip", "createEvent", "createObserver" }) do
		out[fn] = #H.Engine.callsTo(fn)
	end

	out.bank = player.bankCredits
	out.standing = player.ghost and player.ghost.factionStanding.imperial
	out.squadron = player.ghost and player.ghost.squadronType
	out.pilotTier = player.ghost and player.ghost.pilotTier

	for _, suffix in ipairs({ "tatooine_imperial_1:attempted", "tatooine_imperial_1:reward", "tatooine_imperial_2:attempted", "tatooine_imperial_2:reward",
		"tatooine_imperial_3:attempted", "tatooine_imperial_3:reward", "tatooine_imperial_4:attempted", "tatooine_imperial_4:reward", I.SERIES_SUFFIX }) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	return out
end

-- I-10, AC-6
function TestStormT1PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return I.pilot() end,
		function() return I.pilot({ state = "active" }) end,
		function() return I.pilot({ faction = "rebel" }) end,
		function() return I.pilot({ pilot = "neutral", squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false }) end,
		function() return I.pilot({ pilot = false, squadron = false, faction = "neutral" }) end,
		function() return I.pilot({ faction = "neutral" }) end,
		function() return I.pilot({ squadron = false }) end,
		function() return I.pilot({ ship = false }) end,
		function() return I.pilot({ standing = -1 }) end,
		function() return I.pilot({ series = true, paid = 4, tier = 4 }) end,
		function() return I.pilot({ paid = 1, datapad = "story" }) end,
		function() return I.pilot({ paid = 4, tier = 4 }) end,
		function() return I.pilot({ paid = 4 }) end,
		function() return I.pilot({ paid = 4, tier = 1, xp = 7500 }) end,
		function() return I.pilot({ paid = 4, tier = 3 }) end,
		function() return I.pilot({ paid = 3, state = "won" }) end,
		function() return I.pilot({ paid = 2, state = "won" }) end,
		function() return I.pilot({ paid = 1, state = "won" }) end,
		function() return I.pilot({ state = "won" }) end,
		function() return I.pilot({ paid = 1, state = "failed" }) end,
		function() return I.pilot({ paid = 2, state = "failed" }) end,
		function() return I.pilot({ paid = 3, state = "failed" }) end,
		function() return I.pilot({ state = "failed" }) end,
		function() return I.pilot({ paid = 4, tier = 4, duty = I.DUTY6 }) end,
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

---------------------------------------------------------------------------------------------
-- C-1: the off-track non-member's mission request
---------------------------------------------------------------------------------------------

TestStormT1NonMember = {}

function TestStormT1NonMember:setUp()
	H.reset()
	I.requireConversation(lu)
end

local ASK = "s_4854758d"

-- C-1
-- AC-6
function TestStormT1NonMember:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_a_tier_1_skill_and_flies_nothing()
	local t = I.talk(I.pilot({ squadron = rawget(_G, "BLACK_EPSILON_SQUADRON"), tier = 1 }), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer" }, "a tier 1 skill, no mission, empty datapad")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-1
-- AC-6
function TestStormT1NonMember:test_the_request_is_refused_without_a_tier_1_skill()
	local t = I.talk(I.pilot({ squadron = rawget(_G, "BLACK_EPSILON_SQUADRON") }), { ASK })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_no_missions" }, "only the novice box")
	lu.assertTrue(t[2].stop, "non_member_no_missions ends the conversation")
end

-- C-1
-- AC-6: with a space quest the pilot opens on_mission (G6), so the refusal is reached through the helper rule
function TestStormT1NonMember:test_the_helper_refuses_a_pilot_with_any_space_quest_in_the_datapad()
	local h = rawget(_G, I.HANDLER)

	lu.assertFalse(h:canFlyNonTrackDuty(I.pilot({ squadron = false, tier = 1, datapad = "story" })), "a story mission in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(I.pilot({ squadron = false, tier = 1, datapad = "duty" })), "a duty in the datapad")
end

-- C-1: helper agreement (the spec names canFlyNonTrackDuty and isOnMission as public helpers)
-- AC-6
function TestStormT1NonMember:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = rawget(_G, I.HANDLER)

	lu.assertTrue(h:canFlyNonTrackDuty(I.pilot({ squadron = false, tier = 1 })), "tier 1 skill, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(I.pilot({ squadron = false })), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(I.pilot({ squadron = false, tier = 1, duty = I.DUTY7 })), "his escort duty active")
	lu.assertFalse(h:canFlyNonTrackDuty(I.pilot({ squadron = false, tier = 1, paid = 1, state = "active" })), "his mission 2 active")

	lu.assertTrue(h:isOnMission(I.pilot({ state = "active" })), "mission 1 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 1, state = "active" })), "mission 2 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 2, state = "active" })), "mission 3 active")
	lu.assertTrue(h:isOnMission(I.pilot({ paid = 3, state = "active" })), "mission 4 active")
	lu.assertTrue(h:isOnMission(I.pilot({ duty = I.DUTY6 })), "destroy duty active")
	lu.assertTrue(h:isOnMission(I.pilot({ duty = I.DUTY7 })), "escort duty active")
	lu.assertFalse(h:isOnMission(I.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(I.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")
end

-- C-1: the off-track duty hand-out starts Colzet's duties
-- AC-6
function TestStormT1NonMember:test_the_off_track_duty_menu_starts_colzets_duties()
	local d6, d7 = H.spyOn(I.quest(I.DUTY6), "startQuest"), H.spyOn(I.quest(I.DUTY7), "startQuest")
	local t = I.talk(I.pilot({ squadron = false, tier = 1 }), { ASK, "s_e814cf37", "s_259013cd", "s_a490d2c6" })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertEquals(#d6, 1, "destroy duty started")
	lu.assertEquals(#d7, 0, "escort duty not started")
end

-- C-1
-- AC-6
function TestStormT1NonMember:test_declining_the_off_track_duty_ends_without_a_start()
	local d6, d7 = H.spyOn(I.quest(I.DUTY6), "startQuest"), H.spyOn(I.quest(I.DUTY7), "startQuest")
	local t = I.talk(I.pilot({ squadron = false, tier = 1 }), { ASK, "s_e87a40f8" })

	lu.assertEquals(I.ids(t), { "non_member", "non_member_duty_offer", "non_member_declined" }, "screens shown")
	lu.assertTrue(t[3].stop, "non_member_declined ends")
	lu.assertEquals(#d6 + #d7, 0, "no duty started")
end

---------------------------------------------------------------------------------------------
-- The grounded dialogue (FI-3, D-4)
---------------------------------------------------------------------------------------------

TestStormT1Grounded = {}

function TestStormT1Grounded:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-6
function TestStormT1Grounded:test_the_walk_leads_through_the_two_replies_to_the_ground_pounders_line_and_grants_nothing()
	local player = I.pilot({ standing = -3 })
	local t = I.talk(player, { "s_7090182", "s_fcf4d778" })

	lu.assertEquals(I.ids(t), { "grounded", "grounded_standing", "grounded_ground_pounders" }, "screens shown")
	lu.assertEquals(I.PREFIX .. "s_49af5773", t[2].text, "the second line")
	lu.assertEquals(I.PREFIX .. "s_eb1ee299", t[3].text, "the third line")
	lu.assertTrue(t[3].stop, "grounded_ground_pounders ends the conversation")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the grounded walk")
end

-- AC-6: the faction-less variant walks the same screens
function TestStormT1Grounded:test_a_pilot_without_imperial_faction_walks_the_same_dialogue()
	local t = I.talk(I.pilot({ faction = "neutral" }), { "s_7090182", "s_fcf4d778" })

	lu.assertEquals(I.ids(t), { "grounded", "grounded_standing", "grounded_ground_pounders" }, "screens shown")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
end

-- AC-6: the gate lifts at 0
function TestStormT1Grounded:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = I.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "grounded", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "mission2_offer", "standing 0")
end
