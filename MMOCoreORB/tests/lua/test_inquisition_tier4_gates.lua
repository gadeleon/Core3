-- Ja'ce Yiaso: which screen a pilot opens on (gate table G) and the public helpers.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-6, AC-7; Conversation flow 1; Content contract 3; D-4, D-5, D-6, D-9, D-10, D-16, D-17; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- inquisition_tier4_data.lua J4.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local function setUp()
	H.reset()
	J4.requireConversation(lu)
end

local function opens(player) return J4.firstScreen(player) end

local function handler() return rawget(_G, J4.HANDLER) end

local ALL = { 1, 2, 3, 4 }

-- a pilot who has heard the first-meeting briefing: G18 and below by the options given
local function pilot(o)
	local out = { met = true }

	for k, v in pairs(o or {}) do
		out[k] = v
	end

	return J4.pilot(out)
end

-- the missions 1 .. n-1 paid
local function paidBefore(n)
	local paid = {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	return paid
end

TestInquisitionT4Gates = {}

TestInquisitionT4Gates.setUp = setUp

-- G0
-- AC-6
function TestInquisitionT4Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = J4.pilot(), J4.npc(), H.conversationTemplate(J4.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- AC-6
function TestInquisitionT4Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(J4.pilot()), "not_pilot", "JTL disabled")
	lu.assertEquals(opens(J4.pilot({ standing = -1 })), "not_pilot", "JTL disabled beats the wanted gate")
end

-- G1
-- AC-6
function TestInquisitionT4Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = J4.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- G2 (FJ-3: before the faction check)
-- AC-6
function TestInquisitionT4Gates:test_a_player_who_is_not_a_pilot_opens_not_pilot()
	lu.assertEquals(opens(J4.pilot({ pilot = false, squadron = false })), "not_pilot", "Imperial faction, no pilot skills")
	lu.assertEquals(opens(J4.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_pilot", "no faction, no pilot skills")
	lu.assertEquals(opens(J4.pilot({ pilot = false, squadron = false, faction = "rebel" })), "not_pilot", "a Rebel non-pilot is a non-pilot first (FJ-3)")
	lu.assertEquals(opens(J4.pilot({ pilot = false, squadron = false, standing = -3 })), "not_pilot", "a non-pilot is refused before the wanted gate")
end

-- G3
-- AC-6
function TestInquisitionT4Gates:test_a_rebel_or_freelance_pilot_opens_wrong_faction()
	lu.assertEquals(opens(J4.pilot({ pilot = "neutral", squadron = false })), "wrong_faction", "freelance (neutral) pilot")
	lu.assertEquals(opens(J4.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(J4.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "wrong_faction", "rebel pilot")
	lu.assertEquals(opens(J4.pilot({ pilot = "rebel", faction = "rebel", squadron = false, standing = -5 })), "wrong_faction", "the faction check comes before the wanted gate")
end

-- G4: standing below zero or no longer Imperial (V D-6)
-- AC-6
function TestInquisitionT4Gates:test_negative_imperial_standing_or_a_changed_faction_opens_wanted()
	lu.assertEquals(opens(J4.pilot({ standing = -1 })), "wanted", "standing -1")
	lu.assertEquals(opens(J4.pilot({ standing = -300 })), "wanted", "standing -300")
	lu.assertEquals(opens(J4.pilot({ faction = "neutral" })), "wanted", "Imperial pilot skills but the faction is no longer Imperial")
	lu.assertEquals(opens(J4.pilot({ faction = "rebel" })), "wanted", "Imperial pilot skills but a Rebel faction")
	lu.assertNotEquals(opens(J4.pilot({ standing = 0 })), "wanted", "standing 0 is not wanted")
	lu.assertNotEquals(opens(J4.pilot({ standing = 1 })), "wanted", "standing 1 is not wanted")
end

-- G4: J's order: before the track check, a grounded Black Epsilon pilot is wanted
-- AC-6
function TestInquisitionT4Gates:test_the_wanted_gate_comes_before_the_track_check_and_the_tier_check()
	lu.assertEquals(opens(J4.pilot({ squadron = "storm", standing = -1 })), "wanted", "a grounded Storm pilot")
	lu.assertEquals(opens(J4.pilot({ squadron = "black_epsilon", standing = -1 })), "wanted", "a grounded Black Epsilon pilot (J's order)")
	lu.assertEquals(opens(J4.pilot({ squadron = false, standing = -2 })), "wanted", "an Imperial without a squadron")
	lu.assertEquals(opens(J4.pilot({ t3 = 3, standing = -1 })), "wanted", "an Inquisition pilot with three _03 skills")
	lu.assertEquals(opens(J4.pilot({ squadron = "storm" })), "off_track", "standing 0: no wanted gate")
end

-- G4: the wanted gate blocks missions, rewards, training and the hand-off
-- AC-6
function TestInquisitionT4Gates:test_the_wanted_gate_comes_before_missions_rewards_training_and_the_hand_off()
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "active" } })), "wanted", "a mission running")
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "failed" } })), "wanted", "a failed mission")
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "won" } })), "wanted", "a reward waiting")
	lu.assertEquals(opens(pilot({ standing = -1, xp = J4.TRAIN_COST })), "wanted", "a training offer")
	lu.assertEquals(opens(pilot({ standing = -1, t4 = ALL, paid = ALL })), "wanted", "the hand-off")
end

-- G4: the wanted dialogue walks to the end and grants nothing
-- AC-6
function TestInquisitionT4Gates:test_the_wanted_dialogue_walks_to_the_end_after_two_replies_and_grants_nothing()
	local spies = J4.spyStarts()
	local player = J4.pilot({ standing = -3, mission = { [1] = "won" } })
	local t = J4.talk(player, { "s_53de9d8f", "s_8feb33c1" })

	lu.assertEquals(J4.ids(t), { "wanted", "wanted_rebels", "wanted_grounded" }, "screens shown")
	lu.assertTrue(t[#t].stop, "wanted_grounded ends the conversation")
	lu.assertEquals(J4.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- G4: standing back at zero lifts the gate
-- AC-6
function TestInquisitionT4Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = J4.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "intro", "standing 0: the first meeting")
end

-- G5
-- AC-6
function TestInquisitionT4Gates:test_a_black_epsilon_a_storm_and_a_squadron_less_imperial_pilot_open_off_track()
	lu.assertEquals(opens(J4.pilot({ squadron = "black_epsilon" })), "off_track", "Black Epsilon pilot")
	lu.assertEquals(opens(J4.pilot({ squadron = "storm" })), "off_track", "Storm pilot")
	lu.assertEquals(opens(J4.pilot({ squadron = false })), "off_track", "squadron-less Imperial pilot")
	lu.assertNotEquals(opens(J4.pilot({})), "off_track", "an Inquisition pilot is on track")
end

-- G6
-- AC-6
function TestInquisitionT4Gates:test_an_inquisition_pilot_without_all_four_tier_3_skills_opens_not_ready()
	for have = 0, 3 do
		lu.assertEquals(opens(J4.pilot({ t3 = have })), "not_ready", have .. " _03 skills")
	end

	lu.assertNotEquals(opens(J4.pilot({ t3 = 4 })), "not_ready", "four _03 skills")
end

-- G7
-- AC-6
function TestInquisitionT4Gates:test_a_running_mission_chain_a_duty_or_any_datapad_quest_opens_on_mission()
	lu.assertEquals(opens(pilot({ mission = { [1] = "active" } })), "on_mission", "mission 1 head active")
	lu.assertEquals(opens(pilot({ mission = { [4] = "active" } })), "on_mission", "mission 4 head active")

	local player = pilot({ mission = { [2] = "attempted" } })

	J4.setState(player, J4.M2[2], "active")
	lu.assertEquals(opens(player), "on_mission", "a split child alone is active")

	lu.assertEquals(opens(pilot({ datapad = "duty" })), "on_mission", "a duty from another trainer in the datapad")
	lu.assertEquals(opens(pilot({ datapad = "story" })), "on_mission", "a story mission from another trainer in the datapad")
	lu.assertEquals(opens(pilot({ duty = J4.DUTIES[1] })), "on_mission", "this trainer's destroy duty active")
	lu.assertEquals(opens(pilot({ duty = J4.DUTIES[4] })), "on_mission", "this trainer's rescue duty active")
end

-- G7 before G8: a running mission hides the failure of another
-- AC-6
function TestInquisitionT4Gates:test_on_mission_comes_before_failures_and_rewards()
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "active" } })), "on_mission", "M1 failed, M2 running")
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "active" } })), "on_mission", "M1 reward waiting, M2 running")
end

-- G8 .. G11
-- AC-6
function TestInquisitionT4Gates:test_a_failed_or_aborted_mission_opens_its_failure_screen()
	for n = 1, 4 do
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "failed" } })), "m" .. n .. "_failed", "mission " .. n .. " failed")
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "attempted" } })), "m" .. n .. "_failed", "mission " .. n .. " attempted and not won (aborted)")
	end
end

-- G8 .. G12: failures come before rewards, smallest n first
-- AC-6
function TestInquisitionT4Gates:test_failures_come_before_rewards_and_the_smallest_mission_first()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "failed" } })), "m2_failed", "M1 won and M2 failed: m2_failed before m1_reward")
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m1_failed", "M1 and M2 failed")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "failed" } })), "m3_failed", "M2 reward waiting, M3 failed")
end

-- G8: a won mission is not failed
-- AC-6
function TestInquisitionT4Gates:test_a_won_mission_is_not_failed_even_with_the_attempted_key()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won" } })), "m1_reward", "won and attempted: reward, not failure")
	lu.assertEquals(opens(pilot({ mission = { [1] = "endonly" } })), "m1_reward", "the chain end complete without the attempted key: won")
end

-- G12 .. G15
-- AC-6
function TestInquisitionT4Gates:test_a_won_unpaid_mission_opens_its_reward_screen_smallest_first()
	for n = 1, 4 do
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "won" } })), "m" .. n .. "_reward", "mission " .. n .. " won, unpaid")
	end

	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "won" } })), "m1_reward", "M1 and M2 won, both unpaid")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "won" } })), "m2_reward", "M2 and M3 unpaid")
end

-- G12: a partial chain is not won
-- AC-6
function TestInquisitionT4Gates:test_a_partial_chain_is_not_won()
	lu.assertNotEquals(opens(pilot({ mission = { [1] = "partial" } })), "m1_reward", "only the head complete")
end

-- G16 (C-3, FJ-4)
-- AC-6
function TestInquisitionT4Gates:test_a_pilot_with_a_skill_for_the_next_mission_who_left_before_accepting_opens_ready()
	lu.assertEquals(opens(pilot({ t4 = { 3 } })), "ready", "one _04 skill, nothing attempted")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2 }, paid = { 1 } })), "ready", "two skills, mission 1 paid")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2 } })), "ready", "three skills, missions 1 and 2 paid")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), "ready", "four skills with mission 4 unattempted: ready, not the transfer")
	lu.assertEquals(opens(pilot({ xp = J4.TRAIN_COST, t4 = { 2 } })), "ready", "the XP is there but the skill's mission comes first")
end

-- G16: not ready with fewer skills than the next mission, or when it is attempted
-- AC-6
function TestInquisitionT4Gates:test_a_pilot_with_fewer_skills_than_the_next_mission_is_not_ready()
	lu.assertNotEquals(opens(pilot({ t4 = { 3 }, paid = { 1 } })), "ready", "one skill, mission 1 won: mission 2 needs two")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "attempted" } })), "m2_failed", "mission 2 attempted: the failure line, not ready")
end

-- G17 (C-1)
-- AC-6
function TestInquisitionT4Gates:test_a_pilot_with_the_xp_and_no_mission_pending_opens_the_training_screen()
	lu.assertEquals(opens(pilot({ xp = J4.TRAIN_COST })), "ready_train", "1,000,000 XP, no _04 skill")
	lu.assertEquals(opens(pilot({ xp = J4.TRAIN_COST, t4 = { 1 }, paid = { 1 } })), "ready_train", "one skill, its mission paid")
	lu.assertEquals(opens(pilot({ xp = J4.TRAIN_COST, t4 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "ready_train", "three skills, three missions paid")
	lu.assertNotEquals(opens(pilot({ xp = J4.TRAIN_COST - 1 })), "ready_train", "999,999 XP")
end

-- G17 comes before G18
-- AC-6, R-6
function TestInquisitionT4Gates:test_the_training_screen_comes_before_the_first_meeting()
	lu.assertEquals(opens(J4.pilot({ xp = J4.TRAIN_COST })), "ready_train", "no met key, the XP: J's order puts the training first")
end

-- G18
-- AC-6, AC-7
function TestInquisitionT4Gates:test_a_pilot_who_has_not_met_ja_ce_opens_the_intro()
	lu.assertEquals(opens(J4.pilot({})), "intro", "no met key")
	lu.assertEquals(opens(J4.pilot({ xp = J4.TRAIN_COST - 1 })), "intro", "just under the XP")
end

-- G19
-- AC-6
function TestInquisitionT4Gates:test_a_pilot_who_met_ja_ce_with_tier_4_incomplete_opens_the_duty_menu_screen()
	lu.assertEquals(opens(pilot({})), "tier4_incomplete", "no _04 skill, under the XP")
	lu.assertEquals(opens(pilot({ t4 = { 1 }, paid = { 1 } })), "tier4_incomplete", "one skill, its mission paid, under the XP")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "tier4_incomplete", "three skills, three missions paid")
end

-- G20
-- AC-6, AC-11
function TestInquisitionT4Gates:test_a_pilot_with_all_missions_paid_and_four_skills_opens_the_transfer_on_every_talk()
	for _ = 1, 3 do
		lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL })), "transfer", "four skills, four missions paid, no master skill")
	end

	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, xp = J4.TRAIN_COST })), "transfer", "the XP does not offer training once tier 4 is complete")
end

-- G21
-- AC-6, AC-11
function TestInquisitionT4Gates:test_a_pilot_with_the_master_skill_opens_here_for_work()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, master = true })), "here_for_work", "the master skill")
end

-- G12-G15 before G20: mission 4 unpaid with four skills is the reward, not the transfer
-- AC-6
function TestInquisitionT4Gates:test_mission_4_unpaid_with_four_skills_opens_the_reward_not_the_transfer()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "mission 4 won, unpaid")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "mission 4 running")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "failed" } })), "m4_failed", "mission 4 failed")
end

-- R-6: a graduate without the met key sees the first meeting, and the briefing sets the key
-- AC-6, AC-11
function TestInquisitionT4Gates:test_a_graduate_without_the_met_key_sees_the_intro_then_the_transfer()
	local player = J4.pilot({ t4 = ALL, paid = ALL })

	lu.assertEquals(opens(player), "intro", "G18 comes before G20")

	local t = J4.talk(player, { "s_a3958e6a" })

	lu.assertEquals(J4.ids(t), { "intro", "intro_briefing" }, "the first meeting")
	lu.assertEquals(opens(player), "transfer", "the next talk is the transfer")
end

-- the refusal lines
-- AC-6
function TestInquisitionT4Gates:test_the_refusals_show_their_client_lines_and_end()
	local cases = {
		{ J4.pilot({ pilot = false, squadron = false }), "not_pilot", "s_4b509b" },
		{ J4.pilot({ pilot = "neutral", squadron = false }), "wrong_faction", "s_8a7c509a" },
		{ J4.pilot({ standing = -1 }), "wanted", "s_e3ea301" },
		{ J4.pilot({ t3 = 3 }), "not_ready", "s_a11a905b" },
		{ pilot({ mission = { [1] = "active" } }), "on_mission", "s_fcbb92d0" },
	}

	for _, c in ipairs(cases) do
		local t = J4.talk(c[1])

		lu.assertEquals(J4.ids(t), { c[2] }, "screens shown")
		lu.assertEquals(t[1].text, J4.PREFIX .. c[3], c[2] .. ": the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end

	lu.assertTrue(J4.talk(J4.pilot({ pilot = false, squadron = false }))[1].stop, "not_pilot ends")
	lu.assertTrue(J4.talk(J4.pilot({ pilot = "neutral", squadron = false }))[1].stop, "wrong_faction ends")
	lu.assertTrue(J4.talk(J4.pilot({ t3 = 3 }))[1].stop, "not_ready ends")
	lu.assertTrue(J4.talk(pilot({ mission = { [1] = "active" } }))[1].stop, "on_mission ends")
end

-- I-9: getInitialScreen changes no state (the action screens may, on display: that is table H, tested elsewhere)
-- AC-6
function TestInquisitionT4Gates:test_get_initial_screen_changes_no_state_and_starts_pays_and_grants_nothing()
	local spies = J4.spyStarts()
	local cases = {
		J4.pilot({ standing = -1 }), J4.pilot({ t3 = 3 }), J4.pilot({ squadron = false }), J4.pilot(), pilot({ xp = J4.TRAIN_COST }), pilot({ t4 = { 1 } }), pilot({}),
		pilot({ t4 = ALL, paid = ALL }), pilot({ t4 = ALL, paid = ALL, master = true }), pilot({ mission = { [2] = "failed" } }), pilot({ mission = { [3] = "won" } }),
		pilot({ t4 = ALL, paid = { 1, 2, 3 }, pilotTier = 3 }), pilot({ pilot = "rebel", faction = "rebel", squadron = false }), pilot({ t4 = ALL, paid = ALL, pilotTier = 4 }),
	}

	for i, player in ipairs(cases) do
		local before = {
			tier = player.ghost and player.ghost.pilotTier,
			xp = player.ghost and player.ghost.experience.space_combat_general,
			standing = player.ghost and player.ghost.factionStanding.imperial,
			keys = H.Engine.sharedMemoryKeys(),
			met = J4.hasKey(player, J4.MET_SUFFIX),
		}

		lu.assertNotNil(handler():getInitialScreen(player, J4.npc(), H.conversationTemplate(J4.TEMPLATE)), "case " .. i .. ": a screen")
		lu.assertEquals(player.bankCredits, 0, "case " .. i .. ": no credits")
		lu.assertEquals(player.ghost.pilotTier, before.tier, "case " .. i .. ": the pilot tier is untouched by a gate")
		lu.assertEquals(player.ghost.experience.space_combat_general, before.xp, "case " .. i .. ": the XP is untouched")
		lu.assertEquals(player.ghost.factionStanding.imperial, before.standing, "case " .. i .. ": the standing is untouched")
		lu.assertEquals(J4.hasKey(player, J4.MET_SUFFIX), before.met, "case " .. i .. ": the met key is not set by a gate")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), before.keys, "case " .. i .. ": no shared memory key is set by a gate")
	end

	lu.assertEquals(J4.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
end

-- I-9: the met key and the status keys of an unmet pilot stay unset after the gate
-- AC-6
function TestInquisitionT4Gates:test_the_intro_gate_does_not_set_the_met_key()
	local player = J4.pilot({})

	lu.assertEquals(opens(player), "intro", "first talk")
	lu.assertFalse(J4.hasKey(player, J4.MET_SUFFIX), "the met key after the gate screen")
	lu.assertEquals(opens(player), "intro", "a second talk without the reply still opens intro")
end

---------------------------------------------------------------------------------------------
-- The public helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestInquisitionT4Helpers = {}

TestInquisitionT4Helpers.setUp = setUp

function TestInquisitionT4Helpers:test_get_quest_string_returns_the_squadron_constants_of_the_mission()
	local h = handler()

	for n, m in ipairs(J4.MISSIONS) do
		lu.assertEquals(h:getQuestString(n), J4.QUEST_STRINGS[m.questString], "getQuestString(" .. n .. ")")
	end
end

-- isWon, isActive, isFailed, isPaid
function TestInquisitionT4Helpers:test_is_won_is_active_is_failed_and_is_paid_follow_the_chain_end_the_head_and_the_keys()
	local h = handler()
	local player = pilot({ mission = { [1] = "won", [2] = "active", [3] = "failed" }, paid = { 4 } })

	lu.assertEquals({ h:isWon(player, 1), h:isWon(player, 2), h:isWon(player, 3), h:isWon(player, 4) }, { true, false, false, true }, "isWon 1..4")
	lu.assertEquals({ h:isActive(player, 1), h:isActive(player, 2), h:isActive(player, 3), h:isActive(player, 4) }, { false, true, false, false }, "isActive 1..4")
	lu.assertEquals({ h:isFailed(player, 1), h:isFailed(player, 2), h:isFailed(player, 3), h:isFailed(player, 4) }, { false, false, true, false }, "isFailed 1..4")
	lu.assertEquals({ h:isPaid(player, 1), h:isPaid(player, 2), h:isPaid(player, 3), h:isPaid(player, 4) }, { false, false, false, true }, "isPaid 1..4")
end

-- isActive: any member of the chain, not only the head
function TestInquisitionT4Helpers:test_is_active_sees_any_chain_member()
	local h = handler()

	for n, m in ipairs(J4.MISSIONS) do
		for i, global in ipairs(m.chain) do
			local player = pilot({ mission = { [n] = "attempted" } })

			J4.setState(player, global, "active")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. ": member " .. i .. " (" .. global .. ") active")
			lu.assertFalse(h:isFailed(player, n), "mission " .. n .. ": an active member is not a failure")
		end
	end
end

-- isWon needs the chain end, not the head
function TestInquisitionT4Helpers:test_is_won_needs_the_chain_end()
	local h = handler()

	for n in ipairs(J4.MISSIONS) do
		lu.assertFalse(h:isWon(pilot({ mission = { [n] = "partial" } }), n), "mission " .. n .. ": the head alone")
		lu.assertTrue(h:isWon(pilot({ mission = { [n] = "endonly" } }), n), "mission " .. n .. ": the chain end alone")
	end
end

-- isOnMission: the four chains or the four duties
function TestInquisitionT4Helpers:test_is_on_mission_sees_the_four_chains_and_the_four_duties()
	local h = handler()

	lu.assertFalse(h:isOnMission(pilot({})), "nothing running")
	lu.assertFalse(h:isOnMission(pilot({ mission = { [1] = "won", [2] = "failed" } })), "won and failed missions are not running")

	for n = 1, 4 do
		lu.assertTrue(h:isOnMission(pilot({ mission = { [n] = "active" } })), "mission " .. n .. " running")
		lu.assertTrue(h:isOnMission(pilot({ duty = J4.DUTIES[n] })), "duty " .. n .. " running (a running duty makes isOnMission true)")
	end
end

-- isGrounded (V D-6)
function TestInquisitionT4Helpers:test_is_grounded_is_negative_standing_or_a_faction_that_is_not_imperial()
	local h = handler()

	lu.assertFalse(h:isGrounded(J4.pilot({ standing = 0 })), "standing 0")
	lu.assertTrue(h:isGrounded(J4.pilot({ standing = -1 })), "standing -1")
	lu.assertTrue(h:isGrounded(J4.pilot({ faction = "neutral" })), "no faction")
	lu.assertTrue(h:isGrounded(J4.pilot({ faction = "rebel" })), "Rebel faction")
end

-- getNextMission
function TestInquisitionT4Helpers:test_get_next_mission_is_the_smallest_mission_not_won()
	local h = handler()

	lu.assertEquals(h:getNextMission(pilot({})), 1, "nothing won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won" } })), 2, "M1 won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won", [3] = "won" } })), 2, "M1 and M3 won: the gap")
	lu.assertEquals(h:getNextMission(pilot({ paid = { 1, 2, 3 } })), 4, "M1-M3 paid")
	lu.assertNil(h:getNextMission(pilot({ paid = ALL })), "all won")
end

-- getReadyMission
function TestInquisitionT4Helpers:test_get_ready_mission_needs_a_skill_for_the_next_mission_that_is_not_attempted()
	local h = handler()

	lu.assertNil(h:getReadyMission(pilot({})), "no skill")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 3 } })), 1, "one skill, nothing won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 3 }, paid = { 1 } })), "one skill, mission 1 won: mission 2 needs two")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 } })), 2, "two skills, mission 1 won")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), 4, "four skills, three missions won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = ALL, paid = ALL })), "all won: no next mission")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "attempted" } })), "the next mission is attempted")
end

-- canFlyNonTrackDuty (J:212-219)
function TestInquisitionT4Helpers:test_can_fly_non_track_duty_needs_tier_3_done_no_mission_and_no_datapad_quest()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(J4.pilot({ squadron = false })), "four _03 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(J4.pilot({ squadron = false, t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(J4.pilot({ squadron = false, datapad = "duty" })), "a datapad duty")
	lu.assertFalse(h:canFlyNonTrackDuty(J4.pilot({ squadron = false, datapad = "story" })), "a datapad story mission")
	lu.assertFalse(h:canFlyNonTrackDuty(J4.pilot({ squadron = false, mission = { [2] = "active" } })), "a running Inquisition chain")
	lu.assertFalse(h:canFlyNonTrackDuty(J4.pilot({ squadron = false, duty = J4.DUTIES[2] })), "a running duty of this trainer")
end

-- isReadyForTraining
function TestInquisitionT4Helpers:test_is_ready_for_training_needs_the_xp_tier_3_done_tier_4_open_and_no_ready_mission()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST })) == true, "1,000,000 XP exactly")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST - 1 })) == true, "999,999 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST, t3 = 3 })) == true, "three _03 skills")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST, t4 = ALL, paid = ALL })) == true, "tier 4 complete")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST, t4 = { 1 } })) == true, "a ready mission waits")
	lu.assertTrue(h:isReadyForTraining(pilot({ xp = J4.TRAIN_COST, t4 = { 1 }, paid = { 1 } })) == true, "the skill's mission is done")
end

-- the status helpers read <playerID><head questName><suffix> == "1"; key helpers use the squadron constants
function TestInquisitionT4Helpers:test_has_status_and_the_key_helpers_read_and_write_the_player_keyed_status()
	local h = handler()
	local player = pilot({ mission = { [2] = "attempted" }, paid = { 1 } })

	lu.assertTrue(h:hasStatus(player, 1, ":reward"), "mission 1 reward key")
	lu.assertTrue(h:hasStatus(player, 2, ":attempted"), "mission 2 attempted key")
	lu.assertFalse(h:hasStatus(player, 2, ":reward"), "mission 2 reward key")
	lu.assertFalse(h:hasKey(J4.pilot({}), InquisitionSquadronScreenplay.TIER4_MET_KEY), "met key not set")
	h:setKey(player, J4.MET_SUFFIX)
	lu.assertEquals(H.getQuestStatus(player, J4.MET_SUFFIX), "1", "setKey stores '1' under the player id and the key")
end
