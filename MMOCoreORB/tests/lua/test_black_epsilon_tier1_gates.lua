-- Hakassha Sireen: which screen a pilot opens on (gate table G) and the conditional links C-1 .. C-3.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-6; Conversation flow 1 and 2; FH-3, FH-4; D-5, D-6, D-7).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- black_epsilon_tier1_data.lua B.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

B.load()

TestBlackEpsilonT1Gates = {}

function TestBlackEpsilonT1Gates:setUp()
	H.reset()
	B.requireConversation(lu)
end

local function opens(player) return B.firstScreen(player) end

local function handler() return rawget(_G, B.HANDLER) end

-- G0
-- AC-6
function TestBlackEpsilonT1Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = B.pilot(), B.npc(), H.conversationTemplate(B.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestBlackEpsilonT1Gates:test_jtl_disabled_opens_no_jtl()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(B.pilot()), "no_jtl", "JTL disabled")
end

-- AC-6
function TestBlackEpsilonT1Gates:test_a_pilot_without_a_player_object_opens_no_jtl()
	local player = B.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "no_jtl", "ghost is nil")
end

-- AC-6 (D-7): the JTL gate comes before everything, including the help loop
function TestBlackEpsilonT1Gates:test_jtl_disabled_beats_the_first_mission_help()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(B.pilot({ state = "active" })), "no_jtl", "JTL disabled with mission 1 active")
end

-- G2
-- AC-6
function TestBlackEpsilonT1Gates:test_a_pilot_with_a_ship_and_mission_1_active_opens_the_first_mission_help()
	lu.assertEquals(opens(B.pilot({ state = "active" })), "first_mission_help", "mission 1 patrol active")
end

-- AC-6
function TestBlackEpsilonT1Gates:test_the_surprise_attack_being_active_also_counts_as_mission_1_active()
	local player = B.pilot({ state = "failed" })

	B.setState(player, B.P1, "complete")
	B.setState(player, B.S1, "active")
	lu.assertEquals(opens(player), "first_mission_help", "patrol complete, surprise attack active")
end

-- AC-6: the help loop comes before every faction gate
function TestBlackEpsilonT1Gates:test_the_help_loop_comes_before_the_faction_gates()
	lu.assertEquals(opens(B.pilot({ state = "active", faction = "rebel" })), "first_mission_help", "rebel faction, mission 1 active")
	lu.assertEquals(opens(B.pilot({ state = "active", faction = "neutral" })), "first_mission_help", "no faction, mission 1 active")
	lu.assertEquals(opens(B.pilot({ state = "active", squadron = false })), "first_mission_help", "other squadron, mission 1 active")
	lu.assertEquals(opens(B.pilot({ state = "active", standing = -5 })), "first_mission_help", "negative standing, mission 1 active")
	lu.assertEquals(opens(B.pilot({ state = "active", prisk = true })), "first_mission_help", "Prisk flag, mission 1 active")
end

-- G3
-- AC-6
function TestBlackEpsilonT1Gates:test_rebel_faction_a_rebel_pilot_or_a_hostile_non_pilot_opens_rebel_pilot()
	lu.assertEquals(opens(B.pilot({ faction = "rebel" })), "rebel_pilot", "imperial pilot with rebel faction")
	lu.assertEquals(opens(B.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "rebel_pilot", "rebel pilot")
	lu.assertEquals(opens(B.pilot({ pilot = false, faction = "rebel", squadron = false })), "rebel_pilot", "rebel faction non-pilot")
	lu.assertEquals(opens(B.pilot({ pilot = false, faction = "imperial", squadron = false, standing = -1 })), "rebel_pilot", "non-pilot with negative Imperial standing (J:293-308)")
	lu.assertEquals(opens(B.pilot({ pilot = false, faction = "neutral", squadron = false, standing = -300 })), "rebel_pilot", "no faction, negative Imperial standing")
end

-- G4
-- AC-6
function TestBlackEpsilonT1Gates:test_a_neutral_pilot_opens_neutral_pilot()
	lu.assertEquals(opens(B.pilot({ pilot = "neutral", squadron = false })), "neutral_pilot", "neutral pilot, Imperial faction")
	lu.assertEquals(opens(B.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "neutral_pilot", "neutral pilot, no faction")
end

-- G5
-- AC-6
function TestBlackEpsilonT1Gates:test_an_imperial_pilot_without_a_ship_opens_lost_ship()
	lu.assertEquals(opens(B.pilot({ ship = false })), "lost_ship", "member without a ship")
	lu.assertEquals(opens(B.pilot({ ship = false, state = "active" })), "lost_ship", "mission 1 active but no certified ship (the help needs a ship)")
	lu.assertEquals(opens(B.pilot({ ship = false, squadron = false })), "lost_ship", "other squadron without a ship")
end

-- G6 (FH-4, D-6)
-- AC-6
function TestBlackEpsilonT1Gates:test_a_non_imperial_non_pilot_opens_not_imperial_and_cannot_sign_up()
	lu.assertEquals(opens(B.pilot({ pilot = false, faction = "neutral", squadron = false })), "not_imperial", "non-pilot without faction")
	lu.assertEquals(opens(B.pilot({ faction = "neutral" })), "not_imperial", "imperial pilot with a ship but no Imperial faction")
end

-- G7
-- AC-6
function TestBlackEpsilonT1Gates:test_an_imperial_pilot_of_another_squadron_opens_non_member()
	lu.assertEquals(opens(B.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "non_member", "Storm Squadron pilot")
	lu.assertEquals(opens(B.pilot({ squadron = false })), "non_member", "pilot without a squadron")
	lu.assertEquals(opens(B.pilot({ squadron = false, standing = -1 })), "non_member", "other squadron with negative standing: the member-only grounded gate does not apply")
end

-- G7a (Q2 = A, FH-3)
-- AC-6
function TestBlackEpsilonT1Gates:test_a_member_with_negative_imperial_standing_opens_grounded()
	lu.assertEquals(opens(B.pilot({ standing = -1 })), "grounded", "member, standing -1")
	lu.assertEquals(opens(B.pilot({ standing = -1, paid = 4, tier = 4 })), "grounded", "member with everything done, standing -1")
	lu.assertEquals(opens(B.pilot({ standing = -1, prisk = true })), "grounded", "the grounded gate comes before the Prisk flag")
	lu.assertEquals(opens(B.pilot({ standing = -1, paid = 1, state = "active" })), "grounded", "the grounded gate comes before on_mission")
	lu.assertEquals(opens(B.pilot({ standing = 0 })), "mission1_offer", "standing 0 is served normally")
end

-- G8
-- AC-6
function TestBlackEpsilonT1Gates:test_the_prisk_flag_opens_working_for_prisk()
	lu.assertEquals(opens(B.pilot({ prisk = true, series = true, paid = 4, tier = 4 })), "working_for_prisk", "after the hand-off")
	lu.assertEquals(opens(B.pilot({ prisk = true })), "working_for_prisk", "flag alone")
end

-- G9 (D-5)
-- AC-6
function TestBlackEpsilonT1Gates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	lu.assertEquals(opens(B.pilot({ paid = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(B.pilot({ paid = 2, state = "active" })), "on_mission", "mission 3 active")
	lu.assertEquals(opens(B.pilot({ paid = 3, state = "active" })), "on_mission", "mission 4 active")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 4, duty = B.DUTY6 })), "on_mission", "destroy duty active")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 4, duty = B.DUTY7 })), "on_mission", "escort duty active")
	lu.assertEquals(opens(B.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 1, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(B.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
end

-- G10
-- AC-6
function TestBlackEpsilonT1Gates:test_the_series_flag_opens_series_complete()
	lu.assertEquals(opens(B.pilot({ series = true, paid = 4, tier = 4 })), "series_complete", "promoted")
	lu.assertEquals(opens(B.pilot({ series = true, paid = 4, tier = 4, xp = 100000 })), "series_complete", "promoted with XP to spare")
end

-- G11
-- AC-6
function TestBlackEpsilonT1Gates:test_all_four_skills_and_the_mission_4_reward_open_tier_done()
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 4 })), "tier_done", "four tier 1 skills, mission 4 paid")
end

-- G12
-- AC-6
function TestBlackEpsilonT1Gates:test_mission_4_paid_with_no_skill_or_enough_xp_opens_training_offer()
	lu.assertEquals(opens(B.pilot({ paid = 4 })), "training_offer", "no tier 1 skill, no XP: the first skill is free")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 1, xp = 7500 })), "training_offer", "one skill, 7500 XP")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 3, xp = 99999 })), "training_offer", "three skills, plenty of XP")
end

-- G13
-- AC-6
function TestBlackEpsilonT1Gates:test_mission_4_paid_with_some_skills_but_too_little_xp_opens_duty_missions()
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 1, xp = 7499 })), "duty_missions", "one skill, 7499 XP")
	lu.assertEquals(opens(B.pilot({ paid = 4, tier = 3 })), "duty_missions", "three skills, no XP")
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
	TestBlackEpsilonT1Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.won] = function(self)
		lu.assertEquals(opens(B.pilot({ paid = m.n - 1, state = "won" })), m.won, "mission " .. m.n .. " won, reward unpaid")
	end

	-- AC-6
	TestBlackEpsilonT1Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.failed] = function(self)
		lu.assertEquals(opens(B.pilot({ paid = m.n - 1, state = "failed" })), m.failed, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- AC-6
	TestBlackEpsilonT1Gates["test_mission_" .. m.n .. "_not_started_opens_" .. m.offer] = function(self)
		lu.assertEquals(opens(B.pilot({ paid = m.n - 1 })), m.offer, "missions before " .. m.n .. " paid")
	end
end

-- AC-6: mission 1 counts as won only when the patrol and its surprise attack are both complete
function TestBlackEpsilonT1Gates:test_mission_1_with_only_the_patrol_complete_is_not_won()
	local player = B.pilot({ state = "failed" })

	B.setState(player, B.P1, "complete")
	lu.assertEquals(opens(player), "mission1_failed", "patrol complete, surprise attack never flown")
end

-- G25 / G26
-- AC-6
function TestBlackEpsilonT1Gates:test_an_imperial_faction_non_pilot_opens_recruitment()
	lu.assertEquals(opens(B.pilot({ pilot = false, squadron = false })), "recruitment", "Imperial faction, no pilot skills")
end

-- AC-6 (D-6): a neutral player cannot sign up
function TestBlackEpsilonT1Gates:test_a_neutral_faction_non_pilot_never_reaches_recruitment()
	lu.assertEquals(opens(B.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_imperial", "no faction")
end

-- AC-6: every gate screen exists in the template
function TestBlackEpsilonT1Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(B.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "no_jtl", "first_mission_help", "rebel_pilot", "neutral_pilot", "lost_ship", "not_imperial", "non_member", "grounded", "working_for_prisk",
		"on_mission", "series_complete", "tier_done", "training_offer", "duty_missions", "mission4_won", "mission4_failed", "mission4_offer", "mission3_won", "mission3_failed",
		"mission3_offer", "mission2_won", "mission2_failed", "mission2_offer", "mission1_won", "mission1_failed", "mission1_offer", "recruitment" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(H.conversationTemplate(B.TEMPLATE) and LuaConversationTemplate(H.conversationTemplate(B.TEMPLATE)):getScreen(id), B.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track non-member's mission request
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1NonMember = {}

function TestBlackEpsilonT1NonMember:setUp()
	H.reset()
	B.requireConversation(lu)
end

local ASK = "s_29e5ec7" -- "I'd like to request a mission."

-- C-1
-- AC-6
function TestBlackEpsilonT1NonMember:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_a_tier_1_skill_and_flies_nothing()
	local t = B.talk(B.pilot({ squadron = false, tier = 1 }), { ASK })

	lu.assertEquals(B.ids(t), { "non_member", "non_member_duty_offer" }, "a tier 1 skill, no mission, empty datapad")
end

-- C-1
-- AC-6
function TestBlackEpsilonT1NonMember:test_the_request_is_refused_without_a_tier_1_skill()
	local t = B.talk(B.pilot({ squadron = false }), { ASK })

	lu.assertEquals(B.ids(t), { "non_member", "non_member_no_missions" }, "only the novice box")
	lu.assertTrue(t[2].stop, "non_member_no_missions ends the conversation")
end

-- C-1
-- AC-6
function TestBlackEpsilonT1NonMember:test_the_request_is_refused_with_any_space_quest_in_the_datapad()
	lu.assertEquals(B.ids(B.talk(B.pilot({ squadron = false, tier = 1, datapad = "story" }), { ASK })), { "non_member", "non_member_no_missions" }, "a story mission in the datapad")
	lu.assertEquals(B.ids(B.talk(B.pilot({ squadron = false, tier = 1, datapad = "duty" }), { ASK })), { "non_member", "non_member_no_missions" }, "a duty in the datapad")
end

-- C-1
-- AC-6
function TestBlackEpsilonT1NonMember:test_the_request_is_refused_while_one_of_hakasshas_quests_is_active()
	lu.assertEquals(B.ids(B.talk(B.pilot({ squadron = false, tier = 1, duty = B.DUTY6 }), { ASK })), { "non_member", "non_member_no_missions" }, "her destroy duty is active")
	lu.assertEquals(B.ids(B.talk(B.pilot({ squadron = false, tier = 1, paid = 1, state = "active" }), { ASK })), { "non_member", "non_member_no_missions" }, "her mission 2 is active")
end

-- C-1: helper agreement (the spec names canFlyNonTrackDuty and isOnMission as public helpers)
-- AC-6
function TestBlackEpsilonT1NonMember:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = rawget(_G, B.HANDLER)

	lu.assertTrue(h:canFlyNonTrackDuty(B.pilot({ squadron = false, tier = 1 })), "tier 1 skill, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(B.pilot({ squadron = false })), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(B.pilot({ squadron = false, tier = 1, datapad = "story" })), "datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(B.pilot({ squadron = false, tier = 1, duty = B.DUTY7 })), "her escort duty active")

	lu.assertTrue(h:isOnMission(B.pilot({ state = "active" })), "mission 1 active")
	lu.assertTrue(h:isOnMission(B.pilot({ paid = 3, state = "active" })), "mission 4 active")
	lu.assertTrue(h:isOnMission(B.pilot({ duty = B.DUTY6 })), "destroy duty active")
	lu.assertFalse(h:isOnMission(B.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(B.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")
end

---------------------------------------------------------------------------------------------
-- The grounded dialogue (Q2 = A)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Grounded = {}

function TestBlackEpsilonT1Grounded:setUp()
	H.reset()
	B.requireConversation(lu)
end

-- Q2
-- AC-6
function TestBlackEpsilonT1Grounded:test_both_openers_lead_through_the_standing_line_to_the_closing_line_and_grant_nothing()
	for _, opener in ipairs({ "s_549eddbe", "s_77e48d5b" }) do
		H.reset()

		local player = B.pilot({ standing = -3 })
		local t = B.talk(player, { opener, "s_8467c710" })

		lu.assertEquals(B.ids(t), { "grounded", "grounded_standing", "grounded_believe" }, "opener " .. opener)
		lu.assertTrue(t[3].stop, "grounded_believe ends the conversation")
		lu.assertEquals(#B.free() + #B.bought(), 0, "no skill granted")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	end
end

-- Q2: the first line offers exactly the two replies of the client
-- AC-6
function TestBlackEpsilonT1Grounded:test_the_grounded_line_offers_grounded_and_what_do_you_mean()
	local t = B.talk(B.pilot({ standing = -1 }))

	lu.assertEquals(B.optionSids(t[1]), { "s_549eddbe", "s_77e48d5b" }, "replies of 'You're grounded, sweetie.'")
	lu.assertEquals(t[1].text, B.PREFIX .. "s_593de03f", "the NPC line")
end

-- Q2: the gate lifts at 0
-- AC-6
function TestBlackEpsilonT1Grounded:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = B.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "grounded", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "mission2_offer", "standing 0")
end

-- AC-5 (every transcript of the gate tests resolves in the client)
function TestBlackEpsilonT1Grounded:test_the_grounded_transcript_resolves_in_the_client()
	local t = B.talk(B.pilot({ standing = -3 }), { "s_549eddbe", "s_8467c710" })

	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the grounded walk")
end
