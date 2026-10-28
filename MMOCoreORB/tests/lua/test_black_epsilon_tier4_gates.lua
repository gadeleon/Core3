-- Nin Gursawe: which screen a pilot opens on (gate table P) and the public helpers.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-6, AC-11; Conversation flow 1; Content contract 3; D-4, D-5, D-9, D-11, D-15).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- black_epsilon_tier4_data.lua T.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function opens(player) return T.firstScreen(player) end

local function handler() return rawget(_G, T.HANDLER) end

local ALL = { 1, 2, 3, 4 }
local KEYS = { intro = true, met = true }

-- a pilot past the intro with the XP for nothing: P17 and below by the options given
local function pilot(o)
	o = o or {}

	local out = { keys = { intro = true, met = true } }

	for k, v in pairs(o) do
		out[k] = v
	end

	return T.pilot(out)
end

TestBlackEpsilonT4Gates = {}

TestBlackEpsilonT4Gates.setUp = setUp

-- P0
-- AC-6
function TestBlackEpsilonT4Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = T.pilot(), T.npc(), H.conversationTemplate(T.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- P1
-- AC-6
function TestBlackEpsilonT4Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(T.pilot()), "not_pilot", "JTL disabled")
	lu.assertEquals(opens(T.pilot({ standing = -1 })), "not_pilot", "JTL disabled beats the wanted gate")
end

-- P1
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = T.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- P2
-- AC-6
function TestBlackEpsilonT4Gates:test_a_player_who_is_not_a_pilot_opens_not_pilot()
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false })), "not_pilot", "Imperial faction, no pilot skills")
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_pilot", "no faction, no pilot skills")
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false, standing = -3 })), "not_pilot", "a non-pilot is refused before the wanted gate")
end

-- P3
-- AC-6
function TestBlackEpsilonT4Gates:test_a_rebel_or_freelance_pilot_opens_wrong_faction()
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false })), "wrong_faction", "freelance (neutral) pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "wrong_faction", "rebel pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "rebel", squadron = false, standing = -5 })), "wrong_faction", "the faction check comes before the wanted gate")
end

-- P4 (D-15): before the track check, unlike tier 3
-- AC-6
function TestBlackEpsilonT4Gates:test_negative_imperial_standing_opens_wanted()
	lu.assertEquals(opens(T.pilot({ standing = -1 })), "wanted", "standing -1")
	lu.assertEquals(opens(T.pilot({ standing = -300 })), "wanted", "standing -300")
	lu.assertNotEquals(opens(T.pilot({ standing = 0 })), "wanted", "standing 0 is not wanted")
	lu.assertNotEquals(opens(T.pilot({ standing = 1 })), "wanted", "standing 1 is not wanted")
end

-- P4: the wanted gate comes before the track check and the tier check
-- AC-6
function TestBlackEpsilonT4Gates:test_the_wanted_gate_comes_before_the_track_check_and_the_tier_check()
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "STORM_SQUADRON"), standing = -1 })), "wanted", "an off-track Imperial with standing -1")
	lu.assertEquals(opens(T.pilot({ squadron = false, standing = -2 })), "wanted", "an Imperial without a squadron")
	lu.assertEquals(opens(T.pilot({ t3 = 3, standing = -1 })), "wanted", "Black Epsilon with three _03 skills")
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "standing 0: no wanted gate")
end

-- P4: the wanted gate blocks missions, rewards, training and the hand-off
-- AC-6
function TestBlackEpsilonT4Gates:test_the_wanted_gate_comes_before_missions_rewards_training_and_the_hand_off()
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "active" } })), "wanted", "a mission running")
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "failed" } })), "wanted", "a failed mission")
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "won" } })), "wanted", "a reward waiting")
	lu.assertEquals(opens(T.pilot({ standing = -1, xp = T.TRAIN_COST })), "wanted", "a training offer")
	lu.assertEquals(opens(T.pilot({ standing = -1, t4 = ALL, paid = ALL, keys = KEYS })), "wanted", "the hand-off")
end

-- P4: the wanted dialogue grants nothing and walks to the end after two replies
-- AC-6
function TestBlackEpsilonT4Gates:test_the_wanted_dialogue_walks_to_the_end_after_two_replies_and_grants_nothing()
	local spies = T.spyStarts()
	local player = T.pilot({ standing = -3, mission = { [1] = "won" } })
	local t = T.talk(player, { "s_61ee3818", "s_14c18bea" })

	lu.assertEquals(T.ids(t), { "wanted", "wanted_traitor", "wanted_end" }, "screens shown")
	lu.assertTrue(t[#t].stop, "wanted_end ends the conversation")
	lu.assertEquals(T.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- P4: raising the standing to 0 lifts the gate
-- AC-6
function TestBlackEpsilonT4Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = T.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "intro", "standing 0 lifts the gate")
end

-- P5
-- AC-6
function TestBlackEpsilonT4Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track()
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "Storm Squadron pilot")
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })), "off_track", "Inquisition Squadron pilot")
	lu.assertEquals(opens(T.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(T.pilot({ squadron = false, mission = { [1] = "won" } })), "off_track", "other squadron with Black Epsilon state: the track check comes first")
end

-- P6
-- AC-6
function TestBlackEpsilonT4Gates:test_a_black_epsilon_pilot_without_all_four_tier_3_skills_opens_not_ready()
	for have = 0, 3 do
		H.reset()
		lu.assertEquals(opens(T.pilot({ t3 = have })), "not_ready", have .. " of the four tier 3 skills")
	end

	lu.assertEquals(opens(T.pilot({ t3 = 3, mission = { [1] = "won" } })), "not_ready", "tier 4 state without the tier 3 skills")
	lu.assertEquals(opens(T.pilot({ t3 = 3, xp = T.TRAIN_COST })), "not_ready", "the XP does not help")
end

-- Passed P1-P6: the pilot tier heals to 4, and to 5 when tier 4 is complete (D-11)
-- AC-6
function TestBlackEpsilonT4Gates:test_a_tier_3_graduate_leaves_the_gates_at_pilot_tier_4()
	local player = T.pilot({ pilotTier = 3 })

	lu.assertEquals(opens(player), "intro", "a tier 3 graduate")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the first screen")
	opens(player)
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier stays 4 on the next talk")
end

-- Passed P1-P6, D-11 (the Arkon rule)
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_with_four_tier_4_skills_is_raised_to_pilot_tier_5_on_entry()
	local from3 = T.pilot({ pilotTier = 3, t4 = ALL })
	local from4 = T.pilot({ pilotTier = 4, t4 = ALL })

	opens(from3)
	opens(from4)
	lu.assertEquals(from3.ghost.pilotTier, 5, "pilot tier 3 with four _04 skills")
	lu.assertEquals(from4.ghost.pilotTier, 5, "pilot tier 4 with four _04 skills")
	opens(from4)
	lu.assertEquals(from4.ghost.pilotTier, 5, "never above 5")
end

-- Passed P1-P6: a refused pilot keeps the tier
-- AC-6
function TestBlackEpsilonT4Gates:test_a_refused_pilot_keeps_the_pilot_tier()
	local notReady = T.pilot({ pilotTier = 3, t3 = 3 })
	local wanted = T.pilot({ pilotTier = 3, standing = -1 })
	local offTrack = T.pilot({ pilotTier = 3, squadron = false })

	opens(notReady)
	opens(wanted)
	opens(offTrack)
	lu.assertEquals({ notReady.ghost.pilotTier, wanted.ghost.pilotTier, offTrack.ghost.pilotTier }, { 3, 3, 3 }, "pilot tiers of refused pilots")
end

-- P7
-- AC-6
function TestBlackEpsilonT4Gates:test_a_running_mission_chain_or_any_datapad_quest_opens_on_mission()
	lu.assertEquals(opens(pilot({ mission = { [1] = "active" } })), "on_mission", "mission 1 head active")
	lu.assertEquals(opens(pilot({ mission = { [4] = "active" } })), "on_mission", "mission 4 head active")

	local player = pilot({ mission = { [2] = "attempted" } })

	T.setState(player, T.M2[2], "active")
	lu.assertEquals(opens(player), "on_mission", "a split child alone is active")

	lu.assertEquals(opens(pilot({ datapad = "duty" })), "on_mission", "a duty from another trainer in the datapad")
	lu.assertEquals(opens(pilot({ datapad = "story" })), "on_mission", "a story mission from another trainer in the datapad")
	lu.assertEquals(opens(pilot({ duty = T.DUTIES[1] })), "on_mission", "this trainer's destroy duty active")
	lu.assertEquals(opens(pilot({ duty = T.DUTIES[4] })), "on_mission", "this trainer's rescue duty active")
end

-- P7 before P8: a running mission hides the failure of another
-- AC-6
function TestBlackEpsilonT4Gates:test_on_mission_comes_before_failures_and_rewards()
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "active" } })), "on_mission", "M1 failed, M2 running")
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "active" } })), "on_mission", "M1 reward waiting, M2 running")
end

-- P8 .. P11
-- AC-6
function TestBlackEpsilonT4Gates:test_a_failed_mission_opens_its_failure_screen()
	for n = 1, 4 do
		local paid = {}

		for i = 1, n - 1 do
			paid[i] = i
		end

		lu.assertEquals(opens(pilot({ paid = paid, mission = { [n] = "failed" } })), "m" .. n .. "_failed", "mission " .. n .. " failed")
		lu.assertEquals(opens(pilot({ paid = paid, mission = { [n] = "attempted" } })), "m" .. n .. "_failed", "mission " .. n .. " attempted and not won")
	end
end

-- P8 .. P11, P12: failures come before rewards, smallest n first
-- AC-6
function TestBlackEpsilonT4Gates:test_failures_come_before_rewards_and_the_smallest_mission_first()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "failed" } })), "m2_failed", "M1 won and M2 failed: m2_failed before m1_reward")
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m1_failed", "M1 and M2 failed")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "failed" } })), "m3_failed", "M2 reward waiting, M3 failed")
end

-- P8: a won mission is not failed
-- AC-6
function TestBlackEpsilonT4Gates:test_a_won_mission_is_not_failed_even_with_the_attempted_key()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won" } })), "m1_reward", "won and attempted: reward, not failure")
	lu.assertEquals(opens(pilot({ mission = { [1] = "endonly" } })), "m1_reward", "the chain end complete without the attempted key: won")
end

-- P12 .. P15
-- AC-6
function TestBlackEpsilonT4Gates:test_a_won_unpaid_mission_opens_its_reward_screen_smallest_first()
	for n = 1, 4 do
		local paid = {}

		for i = 1, n - 1 do
			paid[i] = i
		end

		lu.assertEquals(opens(pilot({ paid = paid, mission = { [n] = "won" } })), "m" .. n .. "_reward", "mission " .. n .. " won and unpaid")
	end

	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })), "m1_reward", "four rewards waiting: the first")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "won" } })), "m2_reward", "M1 paid: the second")
end

-- P12 .. P15: a partly done chain is neither won nor a reward
-- AC-6
function TestBlackEpsilonT4Gates:test_a_partial_chain_is_not_won()
	lu.assertEquals(opens(pilot({ mission = { [1] = "partial" } })), "m1_failed", "head complete, end not, attempted: failed")
end

-- P16
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_who_has_not_met_the_insurgent_opens_the_intro()
	lu.assertEquals(opens(T.pilot()), "intro", "no intro key")
	lu.assertEquals(opens(T.pilot({ xp = T.TRAIN_COST })), "intro", "the intro comes before the training offer")
	lu.assertEquals(opens(T.pilot({ keys = { met = true } })), "intro", "the met key alone is not the intro key")
	lu.assertNotEquals(opens(T.pilot({ keys = { intro = true } })), "intro", "the intro key lifts it")
end

-- P17
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_with_a_skill_for_the_next_mission_who_left_before_accepting_opens_ready()
	lu.assertEquals(opens(pilot({ t4 = { 1 } })), "ready", "one skill, mission 1 not started")
	lu.assertEquals(opens(pilot({ t4 = { 1, 3 }, paid = { 1 } })), "ready", "two skills, mission 1 paid, mission 2 not started")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2 } })), "ready", "three skills, missions 1-2 paid")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), "ready", "four skills, mission 4 not started")
end

-- P17: the skill of mission n does not make mission n+1 ready
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_with_fewer_skills_than_the_next_mission_is_not_ready()
	lu.assertNotEquals(opens(pilot({ t4 = { 1 }, paid = { 1 } })), "ready", "one skill, mission 1 paid: mission 2 needs a second skill")
	lu.assertNotEquals(opens(pilot({})), "ready", "no skill")
end

-- P18
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_with_the_xp_and_no_mission_pending_opens_the_training_screen()
	lu.assertEquals(opens(pilot({ xp = T.TRAIN_COST })), "ready_train", "1,000,000 XP, no skill")
	lu.assertEquals(opens(pilot({ xp = T.TRAIN_COST, t4 = { 2 }, paid = { 1 } })), "ready_train", "one skill and mission 1 paid")
	lu.assertEquals(opens(pilot({ xp = T.TRAIN_COST, t4 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "ready_train", "three skills and three missions paid")
	lu.assertNotEquals(opens(pilot({ xp = T.TRAIN_COST - 1 })), "ready_train", "999,999 XP")
end

-- P18: the training offer needs the missions done; it never shows while a skill waits for its mission
-- AC-6
function TestBlackEpsilonT4Gates:test_the_training_screen_does_not_show_while_a_skill_is_waiting_for_its_mission()
	lu.assertEquals(opens(pilot({ xp = 5000000, t4 = { 1 } })), "ready", "a skill for mission 1 is held: ready, not training")
end

-- P19
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_who_has_not_heard_the_briefing_opens_expecting()
	lu.assertEquals(opens(T.pilot({ keys = { intro = true } })), "expecting", "intro key, no met key, under 1,000,000 XP")
	lu.assertEquals(opens(T.pilot({ keys = { intro = true }, xp = T.TRAIN_COST - 1 })), "expecting", "999,999 XP")
	lu.assertEquals(opens(T.pilot({ keys = { intro = true }, xp = T.TRAIN_COST })), "ready_train", "the training offer comes before expecting")
end

-- P20
-- AC-6
function TestBlackEpsilonT4Gates:test_a_pilot_who_met_the_insurgent_with_tier_4_incomplete_opens_the_duty_menu_screen()
	lu.assertEquals(opens(pilot({})), "tier4_incomplete", "no skills")
	lu.assertEquals(opens(pilot({ t4 = { 1 }, paid = { 1 } })), "tier4_incomplete", "one skill, mission 1 paid, under the XP")
	lu.assertEquals(opens(pilot({ paid = { 1, 2 } })), "tier4_incomplete", "missions paid without skills")
end

-- P21 (D-9)
-- AC-6, AC-11
function TestBlackEpsilonT4Gates:test_a_pilot_with_all_missions_paid_and_four_skills_opens_the_transfer()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL })), "transfer", "four skills, four missions paid, no master, no Declann key")
	lu.assertEquals(opens(T.pilot({ t4 = ALL, paid = ALL, keys = { intro = true } })), "expecting", "the met key unset: expecting once first (R-7)")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, pilotTier = 5 })), "transfer", "pilot tier 5")
end

-- P22 (D-9)
-- AC-11
function TestBlackEpsilonT4Gates:test_the_transfer_is_skipped_with_the_master_skill_or_after_the_declann_key()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, master = true })), "here_for_work", "the master skill")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, keys = { intro = true, met = true, declann = true } })), "here_for_work", "the Declann key")
end

-- P12 .. P15 before P21: the fourth reward comes first
-- AC-9, AC-11
function TestBlackEpsilonT4Gates:test_mission_4_unpaid_with_four_skills_opens_the_reward_not_the_transfer()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "M4 won and unpaid, four skills")
end

-- P17 before P21: four skills and mission 4 not won
-- AC-6
function TestBlackEpsilonT4Gates:test_four_skills_with_mission_4_not_won_is_held_before_the_transfer()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), "ready", "mission 4 not started: ready")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "mission 4 running")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "failed" } })), "m4_failed", "mission 4 failed")
end

-- Refusals end with the right NPC line
-- AC-6
function TestBlackEpsilonT4Gates:test_the_refusals_show_their_client_lines_and_end()
	local cases = {
		{ T.pilot({ pilot = false, squadron = false }), "not_pilot", "s_362907ef" },
		{ T.pilot({ pilot = "neutral", squadron = false }), "wrong_faction", "s_9ed0c023" },
		{ T.pilot({ standing = -1 }), "wanted", "s_b66c783f" },
		{ T.pilot({ t3 = 3 }), "not_ready", "s_2934bbe1" },
		{ pilot({ mission = { [1] = "active" } }), "on_mission", "s_520cdd79" },
	}

	for _, c in ipairs(cases) do
		local t = T.talk(c[1])

		lu.assertEquals(T.ids(t), { c[2] }, "screens shown")
		lu.assertEquals(t[1].text, T.PREFIX .. c[3], c[2] .. ": the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end

	lu.assertTrue(T.talk(T.pilot({ pilot = false, squadron = false }))[1].stop, "not_pilot ends")
	lu.assertTrue(T.talk(T.pilot({ t3 = 3 }))[1].stop, "not_ready ends")
	lu.assertTrue(T.talk(pilot({ mission = { [1] = "active" } }))[1].stop, "on_mission ends")
end

-- The gate screens do not start, pay or grant anything
-- AC-6
function TestBlackEpsilonT4Gates:test_opening_any_gate_screen_grants_pays_and_starts_nothing()
	local spies = T.spyStarts()
	local players = {
		T.pilot({ standing = -1 }), T.pilot({ t3 = 3 }), T.pilot({ squadron = false }), T.pilot(), pilot({ xp = T.TRAIN_COST }), pilot({ t4 = { 1 } }), pilot({}),
		pilot({ t4 = ALL, paid = ALL }),
	}

	for _, player in ipairs(players) do
		opens(player)
		lu.assertEquals(player.bankCredits, 0, "no credits")
	end

	lu.assertEquals(T.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
end

---------------------------------------------------------------------------------------------
-- The public helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Helpers = {}

TestBlackEpsilonT4Helpers.setUp = setUp

-- isWon, isActive, isFailed, isPaid
function TestBlackEpsilonT4Helpers:test_is_won_is_active_is_failed_and_is_paid_follow_the_chain_end_the_head_and_the_keys()
	local h = handler()
	local player = pilot({ mission = { [1] = "won", [2] = "active", [3] = "failed" }, paid = { 4 } })

	lu.assertEquals({ h:isWon(player, 1), h:isWon(player, 2), h:isWon(player, 3), h:isWon(player, 4) }, { true, false, false, true }, "isWon 1..4")
	lu.assertEquals({ h:isActive(player, 1), h:isActive(player, 2), h:isActive(player, 3), h:isActive(player, 4) }, { false, true, false, false }, "isActive 1..4")
	lu.assertEquals({ h:isFailed(player, 1), h:isFailed(player, 2), h:isFailed(player, 3), h:isFailed(player, 4) }, { false, false, true, false }, "isFailed 1..4")
	lu.assertEquals({ h:isPaid(player, 1), h:isPaid(player, 2), h:isPaid(player, 3), h:isPaid(player, 4) }, { false, false, false, true }, "isPaid 1..4")
end

-- isActive: any member of the chain, not only the head
function TestBlackEpsilonT4Helpers:test_is_active_sees_any_chain_member()
	local h = handler()

	for n, m in ipairs(T.MISSIONS) do
		for i, global in ipairs(m.chain) do
			local player = pilot({ mission = { [n] = "attempted" } })

			T.setState(player, global, "active")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. ": member " .. i .. " (" .. global .. ") active")
			lu.assertFalse(h:isFailed(player, n), "mission " .. n .. ": an active member is not a failure")
		end
	end
end

-- isWon needs the chain end, not the head
function TestBlackEpsilonT4Helpers:test_is_won_needs_the_chain_end()
	local h = handler()

	for n, m in ipairs(T.MISSIONS) do
		local partial = pilot({ mission = { [n] = "partial" } })
		local endOnly = pilot({ mission = { [n] = "endonly" } })

		lu.assertFalse(h:isWon(partial, n), "mission " .. n .. ": the head alone")
		lu.assertTrue(h:isWon(endOnly, n), "mission " .. n .. ": the chain end alone")
	end
end

-- isOnMission: the four chains or the four duties
function TestBlackEpsilonT4Helpers:test_is_on_mission_sees_the_four_chains_and_the_four_duties()
	local h = handler()

	lu.assertFalse(h:isOnMission(pilot({})), "nothing running")
	lu.assertFalse(h:isOnMission(pilot({ mission = { [1] = "won", [2] = "failed" } })), "won and failed missions are not running")

	for n = 1, 4 do
		lu.assertTrue(h:isOnMission(pilot({ mission = { [n] = "active" } })), "mission " .. n .. " running")
		lu.assertTrue(h:isOnMission(pilot({ duty = T.DUTIES[n] })), "duty " .. n .. " running")
	end
end

-- getNextMission
function TestBlackEpsilonT4Helpers:test_get_next_mission_is_the_smallest_mission_not_won()
	local h = handler()

	lu.assertEquals(h:getNextMission(pilot({})), 1, "nothing won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won" } })), 2, "M1 won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won", [3] = "won" } })), 2, "M1 and M3 won: the gap")
	lu.assertEquals(h:getNextMission(pilot({ paid = { 1, 2, 3 } })), 4, "M1-M3 paid")
	lu.assertNil(h:getNextMission(pilot({ paid = ALL })), "all won")
end

-- getReadyMission
function TestBlackEpsilonT4Helpers:test_get_ready_mission_needs_a_skill_for_the_next_mission_that_is_not_attempted()
	local h = handler()

	lu.assertNil(h:getReadyMission(pilot({})), "no skill")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 3 } })), 1, "one skill, nothing won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 3 }, paid = { 1 } })), "one skill, mission 1 won: mission 2 needs two")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 } })), 2, "two skills, mission 1 won")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 } })), 4, "four skills, three missions won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = ALL, paid = ALL })), "all won: no next mission")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "attempted" } })), "the next mission is attempted")
end

-- canFlyNonTrackDuty
function TestBlackEpsilonT4Helpers:test_can_fly_non_track_duty_needs_tier_3_done_no_mission_and_no_datapad_quest()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(T.pilot({ squadron = false })), "four _03 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(T.pilot({ squadron = false, t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(T.pilot({ squadron = false, datapad = "duty" })), "a datapad duty")
	lu.assertFalse(h:canFlyNonTrackDuty(T.pilot({ squadron = false, datapad = "story" })), "a datapad story mission")
	lu.assertFalse(h:canFlyNonTrackDuty(T.pilot({ squadron = false, mission = { [2] = "active" } })), "a running Black Epsilon chain")
	lu.assertFalse(h:canFlyNonTrackDuty(T.pilot({ squadron = false, duty = T.DUTIES[2] })), "a running duty of this trainer")
end

-- isReadyForTraining
function TestBlackEpsilonT4Helpers:test_is_ready_for_training_needs_the_xp_tier_3_done_tier_4_open_and_no_ready_mission()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST })) == true, "1,000,000 XP exactly")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST - 1 })) == true, "999,999 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST, t3 = 3 })) == true, "three _03 skills")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST, t4 = ALL, paid = ALL })) == true, "tier 4 complete")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST, t4 = { 1 } })) == true, "a ready mission waits (Prisk's precedence)")
	lu.assertTrue(h:isReadyForTraining(pilot({ xp = T.TRAIN_COST, t4 = { 1 }, paid = { 1 } })) == true, "the skill's mission is done")
end
