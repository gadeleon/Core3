-- Dravis: which screen a pilot opens on (gate table G), the helpers, the conditional link C-1 and the pure-gate invariant I-10.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-6; Conversation flow 1 and 2; FS-6, FS-7; D-7, D-8, D-9; I-10).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- smuggler_tier1_data.lua S.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")
local MS = require("migration_scenario")

S.load()

TestSmugglerT1Gates = {}

function TestSmugglerT1Gates:setUp()
	H.reset()
	S.requireConversation(lu)
end

local function opens(player) return S.firstScreen(player) end

local function handler() return rawget(_G, S.HANDLER) end

-- G0
-- AC-6
function TestSmugglerT1Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = S.pilot(), S.npc(), H.conversationTemplate(S.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestSmugglerT1Gates:test_jtl_disabled_opens_no_jtl()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(S.pilot()), "no_jtl", "JTL disabled")
end

-- AC-6
function TestSmugglerT1Gates:test_a_pilot_without_a_player_object_opens_no_jtl()
	local player = S.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "no_jtl", "ghost is nil")
end

-- AC-6 (D-9): the JTL gate comes before everything, including the help loop
function TestSmugglerT1Gates:test_jtl_disabled_beats_the_first_mission_help()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(S.pilot({ state = "active" })), "no_jtl", "JTL disabled with mission 1 active")
end

-- G2
-- AC-6
function TestSmugglerT1Gates:test_a_pilot_with_a_ship_and_mission_1_active_opens_the_first_mission_help()
	lu.assertEquals(opens(S.pilot({ state = "active" })), "first_mission_help", "mission 1 patrol active")
end

-- AC-6
function TestSmugglerT1Gates:test_the_surprise_attack_being_active_also_counts_as_mission_1_active()
	local player = S.pilot({ state = "failed" })

	S.setState(player, S.P1, "complete")
	S.setState(player, S.S1, "active")
	lu.assertEquals(opens(player), "first_mission_help", "patrol complete, surprise attack active")
end

-- AC-6: the help loop needs a certified ship (hasVeryFirstQuest)
function TestSmugglerT1Gates:test_mission_1_active_without_a_ship_does_not_open_the_help()
	lu.assertEquals(opens(S.pilot({ state = "active", ship = false })), "lost_ship", "no certified ship: G7, not G2")
end

-- AC-6: the help loop comes before the faction and squadron gates (J order)
function TestSmugglerT1Gates:test_the_help_loop_comes_before_the_pilot_kind_gates()
	lu.assertEquals(opens(S.pilot({ state = "active", faction = "rebel" })), "first_mission_help", "rebel GCW faction, mission 1 active")
	lu.assertEquals(opens(S.pilot({ state = "active", faction = "imperial" })), "first_mission_help", "imperial GCW faction, mission 1 active")
	lu.assertEquals(opens(S.pilot({ state = "active", squadron = false })), "first_mission_help", "no squadron, mission 1 active")
end

-- G3
-- AC-6
function TestSmugglerT1Gates:test_a_rebel_pilot_opens_rebel_pilot()
	lu.assertEquals(opens(S.pilot({ pilot = "rebel", squadron = false })), "rebel_pilot", "rebel pilot")
	lu.assertEquals(opens(S.pilot({ pilot = "rebel", squadron = false, faction = "rebel" })), "rebel_pilot", "rebel pilot, rebel faction")
end

-- G4
-- AC-6
function TestSmugglerT1Gates:test_an_imperial_pilot_opens_imperial_pilot()
	lu.assertEquals(opens(S.pilot({ pilot = "imperial", squadron = false })), "imperial_pilot", "imperial pilot")
	lu.assertEquals(opens(S.pilot({ pilot = "imperial", squadron = false, faction = "imperial" })), "imperial_pilot", "imperial pilot, imperial faction")
end

-- G5
-- AC-6: a CorSec pilot, an RSF pilot and a neutral pilot with no squadron are all pilots but not Smugglers
function TestSmugglerT1Gates:test_a_corsec_an_rsf_or_squadronless_neutral_pilot_opens_non_member()
	lu.assertEquals(opens(S.pilot({ squadron = CORSEC_SQUADRON })), "non_member", "CorSec pilot")
	lu.assertEquals(opens(S.pilot({ squadron = RSF_SQUADRON })), "non_member", "RSF pilot")
	lu.assertEquals(opens(S.pilot({ squadron = false })), "non_member", "neutral pilot without a squadron")
	lu.assertEquals(opens(S.pilot({ squadron = CORSEC_SQUADRON, tier = 4, paid = 4 })), "non_member", "a CorSec pilot with Smuggler-looking history")
end

-- G6 (FS-6, D-7)
-- AC-6: no GCW faction gate: every non-pilot opens recruitment
function TestSmugglerT1Gates:test_non_pilots_of_every_faction_open_recruitment()
	lu.assertEquals(opens(S.pilot({ pilot = false, squadron = false, faction = "neutral" })), "recruitment", "neutral faction")
	lu.assertEquals(opens(S.pilot({ pilot = false, squadron = false, faction = "rebel" })), "recruitment", "rebel faction")
	lu.assertEquals(opens(S.pilot({ pilot = false, squadron = false, faction = "imperial" })), "recruitment", "imperial faction")
end

-- G7
-- AC-6
function TestSmugglerT1Gates:test_a_smuggler_without_a_ship_opens_lost_ship()
	lu.assertEquals(opens(S.pilot({ ship = false })), "lost_ship", "member without a ship")
	lu.assertEquals(opens(S.pilot({ ship = false, paid = 2, state = "won" })), "lost_ship", "a won mission does not matter without a ship")
	lu.assertEquals(opens(S.pilot({ ship = false, paid = 4, tier = 4 })), "lost_ship", "graduate without a ship")
end

-- G8 (D-8)
-- AC-6
function TestSmugglerT1Gates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	lu.assertEquals(opens(S.pilot({ paid = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(S.pilot({ paid = 2, state = "active" })), "on_mission", "mission 3 active")
	lu.assertEquals(opens(S.pilot({ paid = 3, state = "active" })), "on_mission", "mission 4 active")

	for _, duty in ipairs(S.DUTIES) do
		lu.assertEquals(opens(S.pilot({ paid = 4, tier = 4, duty = duty })), "on_mission", duty .. " active")
	end

	lu.assertEquals(opens(S.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 1, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(S.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
	lu.assertEquals(opens(S.pilot({ datapad = "duty" })), "on_mission", "a duty of another trainer, before mission 1")
end

-- AC-6: a split child alone keeps the chain active
function TestSmugglerT1Gates:test_a_running_split_child_alone_opens_on_mission()
	local player = S.pilot({ paid = 2, state = "failed" })

	S.setState(player, S.P3, "complete")
	S.setState(player, S.E3, "active")
	lu.assertEquals(opens(player), "on_mission", "patrol 3 complete, escort 3 active")
end

-- G9 .. G20: one row per mission
local MISSIONS = {
	{ n = 4, reward = "mission4_reward", retry = "mission4_retry", offer = "mission4_offer" },
	{ n = 3, reward = "mission3_reward", retry = "mission3_retry", offer = "mission3_offer" },
	{ n = 2, reward = "mission2_reward", retry = "mission2_retry", offer = "mission2_offer" },
	{ n = 1, reward = "mission1_reward", retry = "mission1_retry", offer = "mission1_offer" },
}

for _, m in ipairs(MISSIONS) do
	-- AC-6, AC-8
	TestSmugglerT1Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.reward] = function(self)
		lu.assertEquals(opens(S.pilot({ paid = m.n - 1, state = "won" })), m.reward, "mission " .. m.n .. " won, reward unpaid")
	end

	-- AC-6
	TestSmugglerT1Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.retry] = function(self)
		lu.assertEquals(opens(S.pilot({ paid = m.n - 1, state = "failed" })), m.retry, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- AC-6
	TestSmugglerT1Gates["test_mission_" .. m.n .. "_not_started_opens_" .. m.offer] = function(self)
		lu.assertEquals(opens(S.pilot({ paid = m.n - 1 })), m.offer, "missions before " .. m.n .. " paid")
	end
end

-- AC-6: a mission counts as won only when its whole chain is complete
function TestSmugglerT1Gates:test_mission_1_with_only_the_patrol_complete_is_not_won()
	local player = S.pilot({ state = "failed" })

	S.setState(player, S.P1, "complete")
	lu.assertEquals(opens(player), "mission1_retry", "patrol complete, surprise attack never flown")
end

-- AC-6
function TestSmugglerT1Gates:test_mission_3_with_only_the_patrol_complete_is_not_won()
	local player = S.pilot({ paid = 2, state = "failed" })

	S.setState(player, S.P3, "complete")
	lu.assertEquals(opens(player), "mission3_retry", "patrol 3 complete, escort never flown")
end

-- AC-6: attempted is what makes a mission failed
function TestSmugglerT1Gates:test_a_mission_never_attempted_is_offered_not_retried()
	local player = S.pilot({ paid = 1 })

	lu.assertNil(H.getQuestStatus(player, "tatooine_privateer_2:attempted"), "precondition: no :attempted key")
	lu.assertEquals(opens(player), "mission2_offer", "mission 2 never attempted")
end

-- AC-8 (AC-6 order): M4 won and unpaid reaches mission4_reward before tier_done, even with all four skills (9034fa3254)
function TestSmugglerT1Gates:test_mission_4_won_and_unpaid_beats_tier_done()
	lu.assertEquals(opens(S.pilot({ paid = 3, state = "won", tier = 4 })), "mission4_reward", "four skills, mission 4 won but unpaid")
	lu.assertEquals(opens(S.pilot({ paid = 3, state = "won", tier = 2, xp = 99999 })), "mission4_reward", "two skills, XP to spare, mission 4 won but unpaid")
end

-- G21
-- AC-6
function TestSmugglerT1Gates:test_all_four_skills_and_the_mission_4_reward_open_tier_done()
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 4 })), "tier_done", "four tier 1 skills, mission 4 paid")
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 4, pilotTier = 2 })), "tier_done", "again after the pilot tier went up")
end

-- G22
-- AC-6
function TestSmugglerT1Gates:test_mission_4_paid_with_no_skill_opens_first_training()
	lu.assertEquals(opens(S.pilot({ paid = 4 })), "first_training", "no tier 1 skill, no XP: the first skill is free")
	lu.assertEquals(opens(S.pilot({ paid = 4, xp = 99999 })), "first_training", "no tier 1 skill, plenty of XP")
end

-- G23
-- AC-6
function TestSmugglerT1Gates:test_mission_4_paid_with_some_skills_and_enough_xp_opens_more_training()
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 1, xp = 7500 })), "more_training", "one skill, 7500 XP")
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 3, xp = 99999 })), "more_training", "three skills, plenty of XP")
end

-- G24
-- AC-6
function TestSmugglerT1Gates:test_mission_4_paid_with_some_skills_but_too_little_xp_opens_duty_missions()
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 1, xp = 7499 })), "duty_missions", "one skill, 7499 XP")
	lu.assertEquals(opens(S.pilot({ paid = 4, tier = 3 })), "duty_missions", "three skills, no XP")
end

-- AC-6: the skills may be any of the four, not just the first ones
function TestSmugglerT1Gates:test_any_single_tier_1_skill_counts_as_having_started_training()
	for _, t in ipairs(S.TRAIN) do
		lu.assertEquals(opens(S.pilot({ paid = 4, skills = { t.skill } })), "duty_missions", t.skill .. " held, no XP")
		lu.assertEquals(opens(S.pilot({ paid = 4, skills = { t.skill }, xp = 7500 })), "more_training", t.skill .. " held, 7500 XP")
	end
end

-- AC-6: every gate screen exists in the template
function TestSmugglerT1Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(S.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "no_jtl", "first_mission_help", "rebel_pilot", "imperial_pilot", "non_member", "recruitment", "lost_ship", "on_mission", "mission1_retry", "mission2_retry",
		"mission3_retry", "mission4_retry", "mission1_reward", "mission1_offer", "mission2_reward", "mission2_offer", "mission3_reward", "mission3_offer", "mission4_reward", "mission4_offer",
		"tier_done", "first_training", "more_training", "duty_missions" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(S.TEMPLATE)):getScreen(id), S.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track pilot's mission request
---------------------------------------------------------------------------------------------

TestSmugglerT1NonMember = {}

function TestSmugglerT1NonMember:setUp()
	H.reset()
	S.requireConversation(lu)
end

local ASK = "s_c1ff5062" -- "I'm looking for a mission. Do you have any?"

-- C-1
-- AC-6, FS-7
function TestSmugglerT1NonMember:test_the_request_leads_to_the_duty_offer_for_a_corsec_or_rsf_pilot_with_a_tier_1_skill_and_nothing_running()
	for _, squadron in ipairs({ CORSEC_SQUADRON, RSF_SQUADRON }) do
		local t = S.talk(S.pilot({ squadron = squadron, tier = 1 }), { ASK })

		lu.assertEquals(S.ids(t), { "non_member", "non_member_duty_offer" }, "squadron " .. tostring(squadron) .. ": a tier 1 skill, no mission, empty datapad")
	end

	lu.assertEquals(S.ids(S.talk(S.pilot({ squadron = false, skills = { "pilot_neutral_droid_01" } }), { ASK })), { "non_member", "non_member_duty_offer" }, "any one tier 1 skill counts")
end

-- C-1
-- AC-6
function TestSmugglerT1NonMember:test_the_request_is_refused_without_a_tier_1_skill()
	local t = S.talk(S.pilot({ squadron = CORSEC_SQUADRON }), { ASK })

	lu.assertEquals(S.ids(t), { "non_member", "non_member_no_missions" }, "only the novice box")
	lu.assertTrue(t[2].stop, "non_member_no_missions ends the conversation")
end

-- C-1
-- AC-6
function TestSmugglerT1NonMember:test_the_request_is_refused_with_any_space_quest_in_the_datapad()
	lu.assertEquals(S.ids(S.talk(S.pilot({ squadron = RSF_SQUADRON, tier = 1, datapad = "story" }), { ASK })), { "non_member", "non_member_no_missions" }, "a story mission in the datapad")
	lu.assertEquals(S.ids(S.talk(S.pilot({ squadron = RSF_SQUADRON, tier = 1, datapad = "duty" }), { ASK })), { "non_member", "non_member_no_missions" }, "a duty in the datapad")
end

-- C-1
-- AC-6
function TestSmugglerT1NonMember:test_the_request_is_refused_while_one_of_dravis_quests_is_active()
	lu.assertEquals(S.ids(S.talk(S.pilot({ squadron = CORSEC_SQUADRON, tier = 1, duty = S.DUTY6 }), { ASK })), { "non_member", "non_member_no_missions" }, "his destroy duty is active")
	lu.assertEquals(S.ids(S.talk(S.pilot({ squadron = CORSEC_SQUADRON, tier = 1, paid = 1, state = "active" }), { ASK })), { "non_member", "non_member_no_missions" }, "his mission 2 is active")
end

-- AC-6: the duty offer reaches the same four duties as the member's menu
function TestSmugglerT1NonMember:test_the_off_track_duty_offer_has_the_duty_menu_and_hands_out_a_duty()
	local spies = {}

	for _, g in ipairs(S.DUTIES) do
		spies[g] = H.spyOn(S.quest(g), "startQuest")
	end

	local t = S.talk(S.pilot({ squadron = CORSEC_SQUADRON, tier = 1 }), { ASK, "s_8aeba6e5", "s_695b8483" })

	lu.assertEquals(S.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty" }, "off-track walk to the first duty")
	lu.assertEquals(#spies[S.DUTY6], 1, "destroy duty 6 started once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the walk")
end

-- C-1: helper agreement (the spec names canFlyNonTrackDuty, isOnMission and isReadyForFirstTraining as public helpers)
-- AC-6
function TestSmugglerT1NonMember:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = rawget(_G, S.HANDLER)

	lu.assertTrue(h:canFlyNonTrackDuty(S.pilot({ squadron = false, tier = 1 })), "tier 1 skill, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(S.pilot({ squadron = false })), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(S.pilot({ squadron = false, tier = 1, datapad = "story" })), "datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(S.pilot({ squadron = false, tier = 1, duty = S.DUTY7 })), "his escort duty active")

	lu.assertTrue(h:isOnMission(S.pilot({ state = "active" })), "mission 1 active")
	lu.assertTrue(h:isOnMission(S.pilot({ paid = 1, state = "active" })), "mission 2 active")
	lu.assertTrue(h:isOnMission(S.pilot({ paid = 2, state = "active" })), "mission 3 active")
	lu.assertTrue(h:isOnMission(S.pilot({ paid = 3, state = "active" })), "mission 4 active")

	for _, duty in ipairs(S.DUTIES) do
		lu.assertTrue(h:isOnMission(S.pilot({ duty = duty })), duty .. " active")
	end

	lu.assertFalse(h:isOnMission(S.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(S.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")

	lu.assertFalse(h:isReadyForFirstTraining(S.pilot({ tier = 1 })), "one tier 1 skill: no longer ready for the first training")
	lu.assertTrue(h:isReadyForFirstTraining(S.pilot({})), "no tier 1 skill: ready for the first training")
end

---------------------------------------------------------------------------------------------
-- I-10: the gates are pure
---------------------------------------------------------------------------------------------

TestSmugglerT1PureGates = {}

function TestSmugglerT1PureGates:setUp()
	H.reset()
	S.requireConversation(lu)
end

-- every pilot of the gate tests above, by name
local PILOTS = {
	{ "fresh_smuggler", { paid = 0 } },
	{ "non_pilot", { pilot = false, squadron = false } },
	{ "rebel_pilot", { pilot = "rebel", squadron = false } },
	{ "imperial_pilot", { pilot = "imperial", squadron = false } },
	{ "corsec_pilot", { squadron = CORSEC_SQUADRON, tier = 1 } },
	{ "rsf_pilot", { squadron = RSF_SQUADRON } },
	{ "no_ship", { ship = false } },
	{ "mission_1_active", { state = "active" } },
	{ "mission_2_active", { paid = 1, state = "active" } },
	{ "datapad_quest", { paid = 1, datapad = "story" } },
	{ "mission_1_failed", { state = "failed" } },
	{ "mission_2_failed", { paid = 1, state = "failed" } },
	{ "mission_3_failed", { paid = 2, state = "failed" } },
	{ "mission_4_failed", { paid = 3, state = "failed" } },
	{ "mission_1_won", { state = "won" } },
	{ "mission_2_won", { paid = 1, state = "won" } },
	{ "mission_3_won", { paid = 2, state = "won", species = SPECIES_ITHORIAN } },
	{ "mission_4_won", { paid = 3, state = "won" } },
	{ "mission_4_won_four_skills", { paid = 3, state = "won", tier = 4 } },
	{ "needs_first_training", { paid = 4 } },
	{ "needs_more_training", { paid = 4, tier = 2, xp = 99999 } },
	{ "duty_pilot", { paid = 4, tier = 2 } },
	{ "graduate", { paid = 4, tier = 4 } },
	{ "on_duty", { paid = 4, tier = 4, duty = "destroy_duty_tatooine_privateer_6" } },
	{ "met_dravis", { pilot = false, squadron = false, met = true } },
}

-- I-10: no skill, item, ship, quest start, journal, status, observer, waypoint, datapad or shared-memory change on the first screen
function TestSmugglerT1PureGates:test_getInitialScreen_changes_nothing_for_any_pilot()
	local starts = {}

	for _, g in ipairs(S.GLOBALS) do
		starts[g] = H.spyOn(S.quest(g), "startQuest")
	end

	for _, p in ipairs(PILOTS) do
		local name, opts = p[1], p[2]
		local player = S.pilot(opts)
		local before = MS.snapshot(player)
		local sideBefore = MS.sideEffects(player)
		local free0, bought0, items0, ships0 = #S.free(), #S.bought(), #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip")
		local n0 = {}

		for _, g in ipairs(S.GLOBALS) do
			n0[g] = #starts[g]
		end

		local screen = handler():getInitialScreen(player, S.npc(), H.conversationTemplate(S.TEMPLATE))

		lu.assertNotNil(screen, name .. ": a first screen")
		lu.assertEquals(MS.snapshot(player), before, name .. ": journal, statuses, observers, waypoints, datapad and shared memory")
		lu.assertEquals(MS.sideEffects(player), sideBefore, name .. ": messages, music and events")
		lu.assertEquals({ #S.free(), #S.bought(), #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip") }, { free0, bought0, items0, ships0 },
			name .. ": awardSkill, skillManagerAwardSkill, giveItem, grantStarterShip calls")

		for _, g in ipairs(S.GLOBALS) do
			lu.assertEquals(#starts[g], n0[g], name .. ": " .. g .. ":startQuest calls")
		end

		lu.assertEquals(player.bankCredits or 0, 0, name .. ": credits")
	end
end

-- I-10: the first screen is the same on every call
function TestSmugglerT1PureGates:test_getInitialScreen_answers_the_same_every_time()
	for _, p in ipairs(PILOTS) do
		local player = S.pilot(p[2])
		local first = handler():getInitialScreen(player, S.npc(), H.conversationTemplate(S.TEMPLATE))
		local again = handler():getInitialScreen(player, S.npc(), H.conversationTemplate(S.TEMPLATE))

		lu.assertEquals(again, first, p[1] .. ": the screen of a repeated call")
	end
end

-- AC-5 (every transcript of the gate tests resolves in the client): the first screen of every pilot above
function TestSmugglerT1PureGates:test_every_first_screen_resolves_in_the_client()
	for _, p in ipairs(PILOTS) do
		H.reset()

		local t = S.talk(S.pilot(p[2]))

		lu.assertEquals(CS.transcriptUnresolved(t), {}, p[1] .. ": client strings of the first screen")
	end
end
