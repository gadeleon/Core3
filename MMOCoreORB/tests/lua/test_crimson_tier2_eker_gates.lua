-- Major Eker: which screen a pilot opens on (gate table E), the conditional off-track link (C-1) and purity (I-3).
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-3; Conversation flow 1 and 2; Source inventory 3; FE-3, FE-4, FE-10, FE-14; D-4, D-7, D-9; I-3; Q-3 = A, Q-4 = A).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is crimson_tier2_data.lua E.pilot
-- (a Crimson Phoenix pilot who graduated Socuna's tier 1: four tier 1 skills, EKER_PILOT_KEY "1" by default; missions = Eker's missions won and paid;
-- t2 = the tier 2 skills held; state = the state of mission missions + 1; graduated = the flag value, false = unset). P() below defaults the flag to "2"
-- (a pilot Eker has handed in). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

-- a pilot Eker has already handed in (flag "2") unless the test says otherwise
local function P(o)
	local opts = { graduated = "2" }

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	return E.pilot(opts)
end

local function snapshot(player)
	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = E.standing(player),
		pilotTier = player.ghost and player.ghost.pilotTier, skills2 = E.held2(player), flag = E.flag(player), viopa = H.getQuestStatus(player, E.VIOPA_KEY),
		xp = player.ghost and player.ghost.experience.space_combat_general,
		inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-3 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = E.handler():getInitialScreen(player, E.npc(), H.conversationTemplate(E.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-3)")
	return first
end

TestEkerGates = {}

TestEkerGates.setUp = setUp

-- E0
-- AC-3
function TestEkerGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = P(), E.npc(), H.conversationTemplate(E.TEMPLATE)

	lu.assertNil(E.handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(E.handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(E.handler():getInitialScreen(player, npc, nil), "no template")
end

-- E1
-- AC-3
function TestEkerGates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	local t = E.talk(P())

	lu.assertEquals(E.ids(t), { "not_pilot" }, "JTL disabled")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
end

-- AC-3
function TestEkerGates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = P()

	player.ghost = nil

	-- (no snapshot: the state snapshot reads the ghost)
	local pScreen = E.handler():getInitialScreen(player, E.npc(), H.conversationTemplate(E.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")
	lu.assertEquals(LuaConversationScreen(pScreen):getScreenID(), "not_pilot", "ghost is nil (SWG !hasSpaceExpansion)")
end

-- E2
-- AC-3
function TestEkerGates:test_a_non_pilot_opens_not_pilot()
	local t = E.talk(P({ pilot = false, squadron = false, faction = "neutral" }))

	lu.assertEquals(E.ids(t), { "not_pilot" }, "a player with no pilot skill")
	lu.assertTrue(t[1].stop, "not_pilot ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E3
-- AC-3: a tier 2 graduate (four _02 skills, flag "3", M4 paid) is handed on; the screen's two replies end and grant nothing
function TestEkerGates:test_a_tier_2_graduate_opens_the_hand_off_whose_replies_end_and_grant_nothing()
	local player = P({ missions = 4, t2 = 4, graduated = "3" })
	local before = snapshot(player)
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "tier3_handoff" }, "tier 2 done, flag 3, M4 paid")
	lu.assertEquals(E.optionSids(t[1]), { "s_3938bdfc", "s_214de988" }, "the two replies")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(snapshot(player).credits, before.credits, "credits")
	lu.assertEquals(E.standing(player), before.standing, "standing")
	lu.assertEquals(E.flag(player), "3", "the flag is untouched")

	for _, reply in ipairs({ "s_3938bdfc", "s_214de988" }) do
		H.reset()

		local p = P({ missions = 4, t2 = 4, graduated = "3" })
		local spies = E.spyStarts()
		local walk = E.talk(p, { reply })

		lu.assertEquals(#walk, 2, "reply " .. reply .. ": a second screen")
		lu.assertTrue(walk[2].stop, "reply " .. reply .. ": the hand-off line ends")
		lu.assertEquals(E.startedCount(spies), {}, "reply " .. reply .. ": quests started")
		lu.assertEquals(p.bankCredits, 0, "reply " .. reply .. ": credits")
		lu.assertEquals(E.standing(p), 0, "reply " .. reply .. ": standing")
	end
end

-- AC-3: any set flag value counts for the hand-off, with the M4 reward paid and all four _02 skills
function TestEkerGates:test_the_hand_off_needs_a_set_flag_four_tier_2_skills_and_the_mission_4_reward_not_a_particular_value()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(E.pilot({ missions = 4, t2 = 4, graduated = flag })), "tier3_handoff", "flag " .. flag .. ", tier 2 done, M4 paid")
	end

	lu.assertNotEquals(opens(P({ missions = 4, t2 = 3, graduated = "3" })), "tier3_handoff", "three _02 skills only")
	lu.assertNotEquals(opens(P({ missions = 4, t2 = 4, graduated = false })), "tier3_handoff", "no flag")
	lu.assertEquals(opens(P({ missions = 3, t2 = 4, state = "won" })), "m4_won", "mission 4 won but unpaid shows the won screen, not the hand-off")
end

-- AC-3, SWG gate 2 precedes gates 3 to 6: the tier-done pilot is handed on whatever his faction or standing is
function TestEkerGates:test_the_hand_off_comes_before_the_faction_standing_and_squadron_gates()
	lu.assertEquals(opens(P({ missions = 4, t2 = 4, graduated = "3", faction = "imperial" })), "tier3_handoff", "Imperial faction")
	lu.assertEquals(opens(P({ missions = 4, t2 = 4, graduated = "3", standing = -1 })), "tier3_handoff", "negative standing")
	lu.assertEquals(opens(P({ missions = 4, t2 = 4, graduated = "3", squadron = false })), "tier3_handoff", "no squadron")
end

-- E4
-- AC-3
function TestEkerGates:test_an_imperial_faction_player_opens_imperial()
	local t = E.talk(P({ faction = "imperial" }))

	lu.assertEquals(E.ids(t), { "imperial" }, "Imperial faction")
	lu.assertTrue(t[1].stop, "imperial ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3
function TestEkerGates:test_an_imperial_pilot_opens_imperial()
	lu.assertEquals(opens(P({ pilot = "imperial", faction = "imperial" })), "imperial", "Imperial pilot")
	lu.assertEquals(opens(P({ pilot = "imperial", faction = "rebel" })), "imperial", "Imperial pilot skills with Rebel faction (isImperialPilot)")
end

-- E5
-- AC-3: a CorSec pilot and any neutral pilot
function TestEkerGates:test_a_neutral_pilot_opens_neutral_pilot()
	local t = E.talk(P({ pilot = "neutral", squadron = CORSEC_SQUADRON, faction = "neutral" }))

	lu.assertEquals(E.ids(t), { "neutral_pilot" }, "CorSec pilot")
	lu.assertEquals(E.optionSids(t[1]), { "s_ca776e30", "s_e93cc431" }, "the two hostile answers")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(P({ pilot = "neutral", squadron = false, faction = "neutral" })), "neutral_pilot", "neutral pilot without a squadron")
end

-- AC-3: both neutral answers end the conversation after one more line
function TestEkerGates:test_the_two_neutral_answers_lead_to_ending_lines()
	local nightmare = E.talk(P({ pilot = "neutral", squadron = CORSEC_SQUADRON, faction = "neutral" }), { "s_ca776e30" })
	local custody = E.talk(P({ pilot = "neutral", squadron = CORSEC_SQUADRON, faction = "neutral" }), { "s_e93cc431" })

	lu.assertEquals(E.ids(nightmare), { "neutral_pilot", "neutral_nightmare" }, "first answer")
	lu.assertTrue(nightmare[2].stop, "neutral_nightmare ends")
	lu.assertEquals(E.ids(custody), { "neutral_pilot", "neutral_custody" }, "second answer")
	lu.assertTrue(custody[2].stop, "neutral_custody ends")
end

-- E6
-- AC-3, D-7: negative Rebel standing grounds the pilot
function TestEkerGates:test_a_crimson_phoenix_pilot_with_rebel_standing_minus_one_opens_grounded()
	local t = E.talk(P({ standing = -1 }))

	lu.assertEquals(E.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(E.optionSids(t[1]), { "s_7f9b8387" }, "the grounded chain opens with one reply")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, D-7: standing 0 is not negative
function TestEkerGates:test_standing_zero_is_not_grounded()
	lu.assertNotEquals(opens(P({ standing = 0 })), "grounded", "standing 0")
end

-- AC-3, D-7: a Rebel pilot whose faction is not Rebel (neutral) is grounded too
function TestEkerGates:test_a_crimson_phoenix_pilot_of_neutral_faction_opens_grounded()
	lu.assertEquals(opens(P({ faction = "neutral" })), "grounded", "neutral faction, Rebel pilot")
end

-- AC-3: the grounded chain walks to its end and offers nothing
function TestEkerGates:test_the_grounded_chain_walks_to_standing_and_ends_without_a_grant()
	local player = P({ standing = -5, xp = 99999 })
	local t = E.talk(player, { "s_7f9b8387", "s_f5427310" })

	lu.assertEquals(E.ids(t), { "grounded", "grounded_why", "grounded_standing" }, "the grounded walk")
	lu.assertTrue(t[3].stop, "grounded_standing ends")
	lu.assertEquals(#E.held2(player), 0, "no skill is trained")
	lu.assertEquals(E.standing(player), -5, "standing unchanged")
end

-- E7
-- AC-3: a Havoc pilot is off track
function TestEkerGates:test_a_havoc_pilot_opens_off_track()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON }))

	lu.assertEquals(E.ids(t), { "off_track" }, "Havoc pilot")
	lu.assertEquals(E.optionSids(t[1]), { "s_1583743c" }, "the one reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3: a Rebel pilot with no squadron is off track as well
function TestEkerGates:test_a_rebel_pilot_without_a_squadron_opens_off_track()
	lu.assertEquals(opens(P({ squadron = false })), "off_track", "no squadron")
end

-- E7 before E8: the squadron gate beats the missing flag
function TestEkerGates:test_off_track_comes_before_non_member()
	lu.assertEquals(opens(P({ squadron = HAVOC_SQUADRON, graduated = false })), "off_track", "Havoc pilot without the flag")
end

-- E8
-- AC-3: a Crimson Phoenix pilot without the flag (Socuna has not promoted him) is not a member
function TestEkerGates:test_a_crimson_phoenix_pilot_without_the_flag_opens_non_member()
	local t = E.talk(P({ graduated = false }))

	lu.assertEquals(E.ids(t), { "non_member" }, "no EKER_PILOT_KEY")
	lu.assertTrue(t[1].stop, "non_member ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E9
-- AC-3, D-13: the four _03 skills without the tier 2 hand-off
function TestEkerGates:test_a_pilot_with_the_four_tier_3_skills_and_no_hand_off_opens_tier3_veteran()
	local t = E.talk(P({ t3 = 4, t2 = 4 }))

	lu.assertEquals(E.ids(t), { "tier3_veteran" }, "four _03 skills, mission 4 not paid")
	lu.assertTrue(t[1].stop, "tier3_veteran ends")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(P({ t3 = 4 })), "tier3_veteran", "four _03 skills and no _02 skill")
end

-- E3 before E9: with the hand-off conditions met, tier 3 skills do not change the screen
function TestEkerGates:test_the_tier_2_hand_off_beats_the_tier_3_veteran_screen()
	lu.assertEquals(opens(P({ missions = 4, t2 = 4, t3 = 4, graduated = "3" })), "tier3_handoff", "hand-off conditions and tier 3 skills")
end

-- E10
-- AC-3: a pilot flying any chain member or duty of Eker's is on a mission
function TestEkerGates:test_a_pilot_flying_any_eker_quest_opens_on_mission()
	for _, global in ipairs(E.GLOBALS) do
		H.reset()
		lu.assertEquals(opens(P({ active = global })), "on_mission", global .. " active in the journal")
	end

	local t = E.talk(P({ missions = 1, t2 = 2, active = E.I14 }))

	lu.assertEquals(E.ids(t), { "on_mission" }, "mission 2 flying")
	lu.assertTrue(t[1].stop, "on_mission ends")
end

-- E10 before E12: the hand-in waits while a quest is flying
function TestEkerGates:test_on_mission_comes_before_the_hand_in()
	lu.assertEquals(opens(E.pilot({ graduated = "1", active = E.DUTY10 })), "on_mission", "flag 1 with a duty active")
end

-- E11
-- AC-3: a pilot with another space mission (a story or duty mission in the datapad) is on another mission
function TestEkerGates:test_a_pilot_holding_another_space_quest_opens_other_mission()
	local t = E.talk(P({ datapad = "story" }))

	lu.assertEquals(E.ids(t), { "other_mission" }, "a story mission in the datapad")
	lu.assertTrue(t[1].stop, "other_mission ends")
	lu.assertEquals(opens(P({ datapad = "duty" })), "other_mission", "a duty mission in the datapad")
	lu.assertEquals(opens(E.pilot({ graduated = "1", datapad = "duty" })), "other_mission", "flag 1: the datapad gate comes before the hand-in")
end

-- E12
-- AC-3, AC-4, D-4: a Socuna graduate is handed in first
function TestEkerGates:test_a_graduate_with_flag_1_opens_the_hand_in()
	local t = E.talk(E.pilot({ graduated = "1" }))

	lu.assertEquals(E.ids(t), { "handin" }, "flag 1, tier 1 done")
	lu.assertEquals(E.optionSids(t[1]), { "s_6a1c47d9", "s_c1015a4d", "s_f685a04e" }, "the three replies (no GM reply for a normal pilot)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, AC-4, D-4, FE-4: also with the XP for training
function TestEkerGates:test_the_hand_in_comes_before_training_for_a_graduate_with_60000_experience()
	lu.assertEquals(opens(E.pilot({ graduated = "1", xp = E.XP_COST })), "handin", "flag 1, exactly 60,000 XP")
	lu.assertEquals(opens(E.pilot({ graduated = "1", xp = 999999 })), "handin", "flag 1, far more XP")
end

-- AC-3, D-4: the hand-in precedes every mission gate
function TestEkerGates:test_the_hand_in_comes_before_every_mission_gate()
	lu.assertEquals(opens(E.pilot({ graduated = "1", t2 = 1 })), "handin", "flag 1 with one _02 skill (mission 1 would be offered)")
	lu.assertEquals(opens(E.pilot({ graduated = "1", t2 = 1, state = "failed" })), "handin", "flag 1, mission 1 failed")
	lu.assertEquals(opens(E.pilot({ graduated = "1", t2 = 1, state = "won" })), "handin", "flag 1, mission 1 won")
end

-- E12 needs the flag to be exactly "1": a flag "2" pilot never sees the hand-in
function TestEkerGates:test_a_pilot_with_flag_2_or_3_is_not_handed_in_again()
	lu.assertNotEquals(opens(P()), "handin", "flag 2")
	lu.assertNotEquals(opens(P({ graduated = "3", missions = 2, t2 = 2 })), "handin", "flag 3")
end

-- E13 to E24 (the mission gates, in JE's order M2, M3, M4, M1): one row per mission and state
local ROWS = {
	-- { mission n, state, expected screen } (missions before n paid, n tier 2 skills)
	{ 2, "failed", "m2_failed" }, { 2, "won", "m2_won" }, { 2, nil, "m2_offer" },
	{ 3, "failed", "m3_failed" }, { 3, "won", "m3_won" }, { 3, nil, "m3_offer" },
	{ 4, "failed", "m4_failed" }, { 4, "won", "m4_won" }, { 4, nil, "m4_offer" },
	{ 1, "won", "m1_won" }, { 1, "failed", "m1_failed" }, { 1, nil, "m1_offer" },
}

for _, row in ipairs(ROWS) do
	local n, state, screen = row[1], row[2], row[3]

	-- AC-3, AC-5
	TestEkerGates["test_a_flag_2_pilot_with_" .. n .. "_tier_2_skills_and_mission_" .. n .. "_" .. (state or "unstarted") .. "_opens_" .. screen] = function()
		local t = E.talk(P({ missions = n - 1, t2 = n, state = state }))

		lu.assertEquals(t[1].id, screen, "mission " .. n .. " " .. (state or "unstarted"))
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-5: the won mission n is shown only with n skills; the next mission is never offered while mission n is unpaid
function TestEkerGates:test_the_next_mission_is_never_offered_while_the_mission_before_it_is_won_and_unpaid()
	for n = 1, 3 do
		H.reset()
		lu.assertEquals(opens(P({ missions = n - 1, t2 = n, state = "won" })), E.MISSIONS[n].won, "mission " .. n .. " won and unpaid shows its won screen")
	end
end

-- AC-5: a mission is offered only with exactly its skill count (M2 exactly 2, M3 exactly 3, M4 exactly 4, M1 at least 1)
function TestEkerGates:test_a_mission_is_offered_only_with_its_skill_count()
	-- mission 1 paid with 1 skill: no mission is offered (training or duties)
	lu.assertNotEquals(opens(P({ missions = 1, t2 = 1 })), "m2_offer", "mission 1 paid, one skill: mission 2 needs two")
	lu.assertNotEquals(opens(P({ missions = 1, t2 = 3 })), "m2_offer", "three skills: not mission 2's count")
	lu.assertNotEquals(opens(P({ missions = 2, t2 = 2 })), "m3_offer", "two skills: not mission 3's count")
	lu.assertNotEquals(opens(P({ missions = 3, t2 = 3 })), "m4_offer", "three skills: not mission 4's count")
end

-- AC-5: with n skills and mission n paid, nothing offers mission n + 1 until the next skill is bought (training or the duty list)
function TestEkerGates:test_after_a_paid_mission_the_pilot_is_offered_training_or_duties_not_the_next_mission()
	for n = 1, 3 do
		H.reset()
		lu.assertEquals(opens(P({ missions = n, t2 = n, xp = 0 })), "duty_offer", "mission " .. n .. " paid, no XP: the duty offer")
		H.reset()
		lu.assertEquals(opens(P({ missions = n, t2 = n, xp = E.XP_COST })), "training_offer", "mission " .. n .. " paid, 60,000 XP: the training offer")
	end
end

-- AC-5: a mission that is active is on_mission, not failed
function TestEkerGates:test_an_active_mission_is_not_failed()
	lu.assertEquals(opens(P({ missions = 0, t2 = 1, state = "active" })), "on_mission", "mission 1 active")
	lu.assertEquals(opens(P({ missions = 3, t2 = 4, state = "active" })), "on_mission", "mission 4 active")
end

-- AC-5: attempted, not won, not active is failed for every mission
function TestEkerGates:test_a_mission_with_attempted_set_and_nothing_complete_is_failed_for_every_mission()
	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(P({ missions = n - 1, t2 = n, state = "failed" })), E.MISSIONS[n].failed, "mission " .. n .. ": attempted, not won, not active")
	end
end

-- AC-5: M3 counts as won only when the surprise attack is complete; a completed inspect alone (the silent split completion) is a failed mission
function TestEkerGates:test_mission_3_with_only_the_inspect_complete_is_not_won()
	local player = P({ missions = 2, t2 = 3, state = "failed" })

	E.setState(player, E.I15, "complete")
	lu.assertEquals(opens(player), "m3_failed", "inspect 15 complete, surprise attack 15 not")
end

-- AC-5: M3 won (both complete) is won; the surprise attack alone counts as the win check of JE
function TestEkerGates:test_mission_3_with_the_surprise_attack_complete_is_won()
	local player = P({ missions = 2, t2 = 3, state = "failed" })

	E.setState(player, E.S15, "complete")
	lu.assertEquals(opens(player), "m3_won", "surprise attack 15 complete")
end

-- AC-5, FE-10, Q-3 = A: out of order (only possible after a GM grant) JE's order holds: M2, M3, M4, then M1
function TestEkerGates:test_mission_gates_are_checked_in_the_order_2_3_4_1()
	-- mission 1 won and unpaid, two skills: M2's offer comes before M1's win
	lu.assertEquals(opens(P({ missions = 0, t2 = 2, state = "won" })), "m2_offer", "M2 before M1")

	-- mission 2 and mission 3 both attempted and not won: M2 first (Vrovel's order would show M3)
	local both = P({ missions = 0, t2 = 0 })

	H.setQuestStatus(both, E.STATUS[2] .. ":attempted", "1")
	H.setQuestStatus(both, E.STATUS[3] .. ":attempted", "1")
	lu.assertEquals(opens(both), "m2_failed", "M2 failed before M3 failed")

	-- mission 4 attempted and not won beats mission 1 won and unpaid
	local last = P({ missions = 0, t2 = 1, state = "won" })

	H.setQuestStatus(last, E.STATUS[4] .. ":attempted", "1")
	lu.assertEquals(opens(last), "m4_failed", "M4 failed before M1 won")
end

-- E1 won vs failed: M1's won comes before M1's failed (JE: won, failed, ready)
function TestEkerGates:test_mission_1_won_comes_before_mission_1_failed()
	local player = P({ missions = 0, t2 = 1, state = "won" })

	lu.assertEquals(opens(player), "m1_won", "every chain member complete")
end

-- E25
-- AC-3, AC-7: 60,000 XP and no mission ready
function TestEkerGates:test_a_flag_2_pilot_with_60000_experience_and_no_mission_ready_opens_the_training_offer()
	local t = E.talk(P({ xp = E.XP_COST }))

	lu.assertEquals(E.ids(t), { "training_offer" }, "0 _02 skills, 60,000 XP")
	lu.assertEquals(E.optionSids(t[1]), { "s_dd2fd70", "s_2f0a6ba8", "s_dede1eae", "s_fd447981" }, "the four replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the XP threshold is exactly 60,000
function TestEkerGates:test_the_training_offer_needs_60000_experience_exactly()
	lu.assertEquals(opens(P({ xp = E.XP_COST - 1 })), "duty_offer", "59,999 XP")
	lu.assertEquals(opens(P({ xp = E.XP_COST })), "training_offer", "60,000 XP")
end

-- AC-7 (isReadyForTraining): any set flag value (not only "2") with tier 1 done and tier 2 not complete
function TestEkerGates:test_training_is_offered_for_any_set_flag_value_past_the_hand_in()
	lu.assertEquals(opens(P({ graduated = "2", xp = E.XP_COST })), "training_offer", "flag 2")
	lu.assertEquals(opens(P({ graduated = "3", xp = E.XP_COST, missions = 3, t2 = 3 })), "training_offer", "flag 3 with three _02 skills (the set flag is what counts)")
end

-- AC-3 (FE-3, Q-4 = A): no training for a pilot with the tier 1 incomplete (E26 then matches the flag "2")
function TestEkerGates:test_no_training_for_a_pilot_with_tier_1_incomplete()
	lu.assertEquals(opens(P({ t1 = 3, xp = 999999 })), "duty_offer", "three _01 skills, flag 2, XP: no training offer")
end

-- E26
-- AC-3: flag "2", no _02 skill and less than 60,000 XP
function TestEkerGates:test_a_flag_2_pilot_with_no_tier_2_skill_and_little_experience_opens_the_duty_offer()
	local t = E.talk(P({ xp = 0 }))

	lu.assertEquals(E.ids(t), { "duty_offer" }, "flag 2")
	lu.assertEquals(E.optionSids(t[1]), { "s_2bf9b1f7", "s_72c594c9" }, "the two replies (no GM reply)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E27
-- AC-3: a flag-1 pilot with incomplete tier 1 falls to the default (SWG: stays at "1", no duties)
function TestEkerGates:test_a_flag_1_pilot_with_incomplete_tier_1_opens_too_busy()
	local t = E.talk(E.pilot({ graduated = "1", t1 = 3 }))

	lu.assertEquals(E.ids(t), { "too_busy" }, "flag 1, three _01 skills")
	lu.assertTrue(t[1].stop, "too_busy ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3: a flag-3 pilot who is between missions and cannot train (three skills, no XP, mission 3 paid): the duty offer is not for flag 3, the default shows
function TestEkerGates:test_a_flag_3_pilot_without_a_hand_off_or_training_falls_to_too_busy()
	lu.assertEquals(opens(P({ graduated = "3", missions = 3, t2 = 3, xp = 0 })), "too_busy", "flag 3, mission 3 paid, no XP")
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track reply (FE-14)
---------------------------------------------------------------------------------------------

TestEkerOffTrack = {}

TestEkerOffTrack.setUp = setUp

-- AC-3, AC-8: tier 1 done and no quest -> the duty offer
function TestEkerOffTrack:test_a_havoc_pilot_with_tier_1_done_and_no_quest_is_offered_duties()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON }), { "s_1583743c" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_duties" }, "the reply leads to the duty offer")
	lu.assertEquals(E.optionSids(t[2]), { "s_ca47d528", "s_7115a155" }, "interested / not")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-3, AC-8: fewer than four _01 skills -> "Since you're not a member of my unit..."
function TestEkerOffTrack:test_an_off_track_pilot_without_tier_1_done_gets_no_missions()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON, t1 = 3 }), { "s_1583743c" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_no_missions" }, "three _01 skills")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends")
end

-- AC-8: no skill at all
function TestEkerOffTrack:test_an_off_track_pilot_with_no_tier_1_skill_gets_no_missions()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON, t1 = 0 }), { "s_1583743c" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_no_missions" }, "no _01 skill")
end

-- AC-8: any space quest (a datapad mission) refuses the duties; the gate itself still opens off_track (E7 precedes E11)
function TestEkerOffTrack:test_an_off_track_pilot_with_a_space_quest_gets_no_missions()
	for _, kind in ipairs({ "story", "duty" }) do
		H.reset()

		local t = E.talk(P({ squadron = HAVOC_SQUADRON, datapad = kind }), { "s_1583743c" })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_no_missions" }, kind .. " mission in the datapad")
	end
end

-- AC-8: an Eker quest active in the journal also refuses
function TestEkerOffTrack:test_an_off_track_pilot_flying_a_duty_gets_no_missions()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON, active = E.DUTY12 }), { "s_1583743c" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_no_missions" }, "a duty active in the journal")
end

-- AC-3 (C-1): the decision is made when the reply is shown, from the pilot's state then
function TestEkerOffTrack:test_the_reply_link_follows_the_state_at_the_time_of_the_talk()
	local first = E.talk(P({ squadron = HAVOC_SQUADRON, t1 = 3 }))

	lu.assertEquals(E.linksOf(first[1]), { "off_track_no_missions" }, "no tier 1 done: the link")
	lu.assertEquals(E.linksOf(E.talk(P({ squadron = HAVOC_SQUADRON }))[1]), { "off_track_duties" }, "tier 1 done: the link")
end

---------------------------------------------------------------------------------------------
-- I-3: purity
---------------------------------------------------------------------------------------------

TestEkerPureGates = {}

TestEkerPureGates.setUp = setUp

-- AC-3, I-3: the gate decision itself writes nothing (status keys, flag, viopaSmuggler, journal, skills, XP, pilot tier, standing, credits, inventory), for every kind of pilot
function TestEkerPureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return P() end,
		function() return E.pilot({ graduated = "1" }) end,
		function() return E.pilot({ graduated = "1", xp = 999999 }) end,
		function() return P({ graduated = false }) end,
		function() return P({ faction = "imperial" }) end,
		function() return P({ pilot = "neutral", squadron = CORSEC_SQUADRON }) end,
		function() return P({ pilot = false, squadron = false }) end,
		function() return P({ standing = -1 }) end,
		function() return P({ faction = "neutral" }) end,
		function() return P({ squadron = HAVOC_SQUADRON }) end,
		function() return P({ active = E.E13 }) end,
		function() return P({ datapad = "story" }) end,
		function() return P({ t2 = 1, state = "won" }) end,
		function() return P({ t2 = 1, state = "failed" }) end,
		function() return P({ t2 = 1 }) end,
		function() return P({ missions = 1, t2 = 2, state = "won" }) end,
		function() return P({ missions = 1, t2 = 2, state = "failed" }) end,
		function() return P({ missions = 1, t2 = 2 }) end,
		function() return P({ missions = 2, t2 = 3, state = "won" }) end,
		function() return P({ missions = 2, t2 = 3, state = "failed" }) end,
		function() return P({ missions = 2, t2 = 3 }) end,
		function() return P({ missions = 3, t2 = 4, state = "won" }) end,
		function() return P({ missions = 3, t2 = 4, state = "failed" }) end,
		function() return P({ missions = 3, t2 = 4 }) end,
		function() return P({ missions = 4, t2 = 4, graduated = "3" }) end,
		function() return P({ missions = 3, t2 = 3, xp = E.XP_COST }) end,
		function() return P({ xp = E.XP_COST }) end,
		function() return E.pilot({ graduated = "1", t1 = 3 }) end,
		function() return P({ t3 = 4 }) end,
		function() return P({ privileged = true }) end,
		function() return P({ missions = 0, t2 = 1, state = "won", inventory = false }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local screen = opens(player)

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertNil(H.getQuestStatus(player, E.VIOPA_KEY), "pilot " .. i .. ": no viopaSmuggler key")
	end
end

-- AC-3, I-3: the JTL-off pilot too
function TestEkerPureGates:test_the_jtl_gate_changes_no_state()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(P()), "not_pilot", "JTL disabled")
end

-- AC-3: the gate order is first match wins; a missing JTL beats every other gate
function TestEkerPureGates:test_jtl_disabled_beats_every_other_gate()
	H.Engine.config.jtlEnabled = false

	for _, o in ipairs({ { graduated = "1" }, { missions = 4, t2 = 4, graduated = "3" }, { faction = "imperial" }, { xp = E.XP_COST }, { active = E.E13 } }) do
		lu.assertEquals(opens(E.pilot(o)), "not_pilot", "JTL disabled")
	end
end
