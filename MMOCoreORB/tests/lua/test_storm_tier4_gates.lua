-- Admiral Kilnstrider: which screen a pilot opens on (gate table G) and the public helpers.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-3; Conversation flow 1; Content contract 2 (handler helpers); D-6, D-7, D-9, D-10, D-14, D-16, D-17; FK-3, FK-5; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is storm_tier4_data.lua D.pilot
-- (a Storm graduate of tier 3: all four _03 skills, Denner's missions paid, pilot tier 4; t4 = the _04 skills held, mission = the state of single missions,
-- paid = the missions won and paid). getInitialScreen is side-effect free (I-9): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function handler() return rawget(_G, D.HANDLER) end

local ALL = { 1, 2, 3, 4 }

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-9 for this pilot
local function opens(player)
	local before = D.snapshot(player)
	local pScreen = handler():getInitialScreen(player, D.npc(), H.conversationTemplate(D.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(D.snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-9)")
	return first
end

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

-- a pilot who has heard the first-meeting briefing: G18 and below by the options given
local function pilot(o)
	local out = { met = true }

	for k, v in pairs(o or {}) do
		out[k] = v
	end

	return D.pilot(out)
end

-- the missions 1 .. n-1 paid
local function paidBefore(n)
	local paid = {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	return paid
end

-- the pilot of the tier 3 skills only: a non-pilot has none
local NON_PILOT = { pilot = false, squadron = false }

TestStormT4Gates = {}

TestStormT4Gates.setUp = setUp

-- G0
-- B-3
function TestStormT4Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = D.pilot(), D.npc(), H.conversationTemplate(D.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- Content contract 2: runScreenHandlers returns nothing without a player or a screen
-- B-3
function TestStormT4Gates:test_run_screen_handlers_returns_nil_without_a_player_or_a_screen()
	local tmpl = H.conversationTemplate(D.TEMPLATE)
	local screen = LuaConversationTemplate(tmpl):getScreen("not_pilot")

	lu.assertNil(handler():runScreenHandlers(tmpl, nil, D.npc(), 0, screen), "no player")
	lu.assertNil(handler():runScreenHandlers(tmpl, D.pilot(), D.npc(), 0, nil), "no screen")
end

-- G1
-- B-3
function TestStormT4Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(D.pilot()), "not_pilot", "JTL disabled")
	lu.assertEquals(opens(D.pilot({ standing = -1 })), "not_pilot", "JTL disabled beats the wanted gate")
end

-- G1
-- B-3
function TestStormT4Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = D.pilot()

	player.ghost = nil
	lu.assertEquals(D.firstScreen(player), "not_pilot", "ghost is nil")
end

-- G2 (FK-5: before the faction check, so the non-pilot line is reachable)
-- B-3
function TestStormT4Gates:test_a_player_who_is_not_a_pilot_opens_not_pilot_which_ends_without_replies()
	local t = D.talk(D.pilot(NON_PILOT))

	lu.assertEquals(D.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_d318f289", "'You don't look like much of a pilot.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(D.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_pilot", "no faction, no pilot skills")
	lu.assertEquals(opens(D.pilot({ pilot = false, squadron = false, faction = "rebel" })), "not_pilot", "a Rebel non-pilot is a non-pilot first")
	lu.assertEquals(opens(D.pilot({ pilot = false, squadron = false, standing = -3 })), "not_pilot", "a non-pilot is refused before the wanted gate")
end

-- G3
-- B-3
function TestStormT4Gates:test_a_rebel_or_freelance_pilot_opens_wrong_faction()
	local t = D.talk(D.pilot({ pilot = "neutral", squadron = false }))

	lu.assertEquals(D.ids(t), { "wrong_faction" }, "freelance pilot")
	lu.assertTrue(t[1].stop, "wrong_faction ends the conversation")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_e16137e8", "'Get out of my sight immediately!'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(D.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(D.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "wrong_faction", "rebel pilot")
	lu.assertEquals(opens(D.pilot({ pilot = "rebel", faction = "rebel", squadron = false, standing = -5 })), "wrong_faction", "the faction check comes before the wanted gate")
end

-- G4: Black Epsilon, Inquisition and squadron-less Imperial pilots
-- B-3
function TestStormT4Gates:test_a_black_epsilon_an_inquisition_and_a_squadron_less_imperial_pilot_open_off_track()
	lu.assertEquals(opens(D.pilot({ squadron = "black_epsilon" })), "off_track", "Black Epsilon pilot")
	lu.assertEquals(opens(D.pilot({ squadron = "inquisition" })), "off_track", "Inquisition pilot")
	lu.assertEquals(opens(D.pilot({ squadron = false })), "off_track", "squadron-less Imperial pilot")
	lu.assertNotEquals(opens(D.pilot({})), "off_track", "a Storm pilot is on track")
end

-- G4 before G5 (FK-5): the track check comes before the grounded check
-- B-3
function TestStormT4Gates:test_a_grounded_off_track_pilot_still_opens_off_track()
	lu.assertEquals(opens(D.pilot({ squadron = "black_epsilon", standing = -1 })), "off_track", "a grounded Black Epsilon pilot (FK-5)")
	lu.assertEquals(opens(D.pilot({ squadron = "inquisition", standing = -4 })), "off_track", "a grounded Inquisition pilot")
	lu.assertEquals(opens(D.pilot({ squadron = false, faction = "neutral" })), "off_track", "a squadron-less pilot whose faction is gone")
end

-- G4, B-4: the three off-track pilots get a reply, and an off-track pilot's wrong-faction refusal is not reachable from here
-- B-3
function TestStormT4Gates:test_the_off_track_line_is_the_client_line_with_one_reply()
	local t = D.talk(D.pilot({ squadron = "black_epsilon" }))

	lu.assertEquals(t[1].text, D.PREFIX .. "s_50605b35", "'What are you doing here pilot. You are not a part of this unit.'")
	lu.assertEquals(D.optionSids(t[1]), { "s_4854758d" }, "the one reply")
	lu.assertFalse(t[1].stop, "off_track waits for the reply")
end

-- G5: standing below zero or no longer Imperial (D-6)
-- B-3
function TestStormT4Gates:test_negative_imperial_standing_or_a_changed_faction_opens_wanted()
	lu.assertEquals(opens(D.pilot({ standing = -1 })), "wanted", "standing -1")
	lu.assertEquals(opens(D.pilot({ standing = -300 })), "wanted", "standing -300")
	lu.assertEquals(opens(D.pilot({ faction = "neutral" })), "wanted", "Storm pilot skills but the faction is no longer Imperial")
	lu.assertEquals(opens(D.pilot({ faction = "rebel" })), "wanted", "Storm pilot skills but a Rebel faction")
	lu.assertNotEquals(opens(D.pilot({ standing = 0 })), "wanted", "standing 0 is not wanted")
	lu.assertNotEquals(opens(D.pilot({ standing = 1 })), "wanted", "standing 1 is not wanted")
end

-- G5: the wanted gate comes before the tier check and everything below it
-- B-3
function TestStormT4Gates:test_the_wanted_gate_comes_before_not_ready_missions_rewards_training_and_the_hand_off()
	lu.assertEquals(opens(pilot({ standing = -1, t3 = { 1, 2, 3 } })), "wanted", "three _03 skills")
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "active" } })), "wanted", "a mission running")
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "failed" } })), "wanted", "a failed mission")
	lu.assertEquals(opens(pilot({ standing = -1, mission = { [1] = "won" } })), "wanted", "a reward waiting")
	lu.assertEquals(opens(pilot({ standing = -1, xp = D.TRAIN_COST })), "wanted", "a training offer")
	lu.assertEquals(opens(pilot({ standing = -1, t4 = ALL, paid = ALL })), "wanted", "the hand-off")
end

-- G5: the wanted dialogue walks to the end and grants nothing
-- B-3
function TestStormT4Gates:test_the_wanted_dialogue_walks_to_the_end_after_one_reply_and_grants_nothing()
	local spies = D.spyStarts()
	local player = D.pilot({ standing = -3, mission = { [1] = "won" } })
	local t = D.talk(player, { "s_7090182" })

	lu.assertEquals(D.ids(t), { "wanted", "wanted_c8003afd" }, "screens shown")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_f2643fdd", "'What is your major malfunction, %TU!? ...'")
	lu.assertTrue(t[#t].stop, "wanted_c8003afd ends the conversation")
	lu.assertEquals(D.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(D.standingOf(player), -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- G5: standing back at zero lifts the gate
-- B-3
function TestStormT4Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = D.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "intro", "standing 0: the first meeting")
end

-- G6
-- B-3
function TestStormT4Gates:test_a_storm_pilot_without_all_four_tier_3_skills_opens_not_ready()
	for _, have in ipairs({ {}, { 1 }, { 1, 2 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
		local t = D.talk(D.pilot({ t3 = have }))

		lu.assertEquals(D.ids(t), { "not_ready" }, #have .. " _03 skills")
		lu.assertTrue(t[1].stop, "not_ready ends the conversation")
		lu.assertEquals(t[1].text, D.PREFIX .. "s_d3b2272c", "'I believe your trainer is looking for you.'")
	end

	lu.assertNotEquals(opens(D.pilot({ t3 = ALL })), "not_ready", "four _03 skills")
end

-- G6: finding 1: Denner's hand-in is exactly this gate
-- B-3
function TestStormT4Gates:test_not_ready_comes_before_the_mission_gates()
	lu.assertEquals(opens(pilot({ t3 = { 1, 2, 3 }, mission = { [1] = "active" } })), "not_ready", "a running mission")
	lu.assertEquals(opens(pilot({ t3 = { 1, 2, 3 }, mission = { [1] = "failed" } })), "not_ready", "a failed mission")
	lu.assertEquals(opens(pilot({ t3 = { 1, 2, 3 }, xp = D.TRAIN_COST })), "not_ready", "the XP")
end

-- G7
-- B-3
function TestStormT4Gates:test_a_running_mission_chain_a_duty_or_any_datapad_quest_opens_on_mission()
	for n = 1, 4 do
		local t = D.talk(pilot({ mission = { [n] = "active" } }))

		lu.assertEquals(D.ids(t), { "on_mission" }, "mission " .. n .. " head active")
		lu.assertTrue(t[1].stop, "on_mission ends the conversation")
		lu.assertEquals(t[1].text, D.PREFIX .. "s_2a35d2fe", "the on-mission line")
	end

	local player = pilot({ mission = { [2] = "attempted" } })

	D.setState(player, D.M2[2], "active")
	lu.assertEquals(opens(player), "on_mission", "a split child alone is active")

	lu.assertEquals(opens(pilot({ datapad = "duty" })), "on_mission", "a duty from another trainer in the datapad")
	lu.assertEquals(opens(pilot({ datapad = "story" })), "on_mission", "a story mission from another trainer in the datapad")

	for i, duty in ipairs(D.DUTIES) do
		lu.assertEquals(opens(pilot({ duty = duty })), "on_mission", "this trainer's duty " .. i .. " active")
	end
end

-- G7 before G8: a running mission hides the failure of another
-- B-3
function TestStormT4Gates:test_on_mission_comes_before_failures_and_rewards()
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "active" } })), "on_mission", "M1 failed, M2 running")
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "active" } })), "on_mission", "M1 reward waiting, M2 running")
end

-- G8 .. G11
-- B-3
function TestStormT4Gates:test_a_failed_or_aborted_mission_opens_its_failure_screen()
	for n = 1, 4 do
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "failed" } })), "m" .. n .. "_failed", "mission " .. n .. " failed")
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "attempted" } })), "m" .. n .. "_failed", "mission " .. n .. " attempted and not won (aborted)")
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "partial" } })), "m" .. n .. "_failed", "mission " .. n .. ": the head done, the end not")
	end
end

-- G8 .. G15: failures come before rewards, smallest n first
-- B-3
function TestStormT4Gates:test_failures_come_before_rewards_and_the_smallest_mission_first()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "failed" } })), "m2_failed", "M1 won and M2 failed: m2_failed before m1_reward")
	lu.assertEquals(opens(pilot({ mission = { [1] = "failed", [2] = "failed" } })), "m1_failed", "M1 and M2 failed")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "failed" } })), "m3_failed", "M2 reward waiting, M3 failed")
end

-- G8: a won mission is not failed
-- B-3
function TestStormT4Gates:test_a_won_mission_is_not_failed_even_with_the_attempted_key()
	lu.assertEquals(opens(pilot({ mission = { [1] = "won" } })), "m1_reward", "won and attempted: reward, not failure")
	lu.assertEquals(opens(pilot({ mission = { [1] = "endonly" } })), "m1_reward", "the chain end complete without the attempted key: won")
end

-- G12 .. G15
-- B-3
function TestStormT4Gates:test_a_won_unpaid_mission_opens_its_reward_screen_smallest_first()
	for n = 1, 4 do
		lu.assertEquals(opens(pilot({ paid = paidBefore(n), mission = { [n] = "won" } })), "m" .. n .. "_reward", "mission " .. n .. " won, unpaid")
	end

	lu.assertEquals(opens(pilot({ mission = { [1] = "won", [2] = "won" } })), "m1_reward", "M1 and M2 won, both unpaid")
	lu.assertEquals(opens(pilot({ paid = { 1 }, mission = { [2] = "won", [3] = "won" } })), "m2_reward", "M2 and M3 unpaid")
end

-- G12: the reward screens are client lines with the first name where J has %TU / %NU
-- B-3
function TestStormT4Gates:test_the_reward_screens_show_their_client_lines()
	local sids = { "s_3ec8b347", "s_a4dd5d0d", "s_9ff091bd", "s_5066022c" }

	for n = 1, 4 do
		local t = D.talk(pilot({ paid = paidBefore(n), mission = { [n] = "won" } }))

		lu.assertEquals(t[1].text, D.PREFIX .. sids[n], "m" .. n .. "_reward: the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- G12: a partial chain is not won
-- B-3
function TestStormT4Gates:test_a_partial_chain_is_not_won()
	lu.assertNotEquals(opens(pilot({ mission = { [1] = "partial" } })), "m1_reward", "only the head complete")
end

-- G16 (C-3, FK-3)
-- B-3
function TestStormT4Gates:test_a_pilot_with_a_skill_for_the_next_mission_who_left_before_accepting_opens_ready()
	lu.assertEquals(opens(pilot({ t4 = { 3 } })), "ready", "one _04 skill, nothing attempted")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2 }, paid = { 1 } })), "ready", "two skills, mission 1 paid")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2 } })), "ready", "three skills, missions 1 and 2 paid")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), "ready", "four skills with mission 4 unattempted: ready, not the transfer")
	lu.assertEquals(opens(pilot({ xp = D.TRAIN_COST, t4 = { 2 } })), "ready", "the XP is there but the skill's mission comes first")
end

-- G16: not ready with fewer skills than the next mission, or when it is attempted
-- B-3
function TestStormT4Gates:test_a_pilot_with_fewer_skills_than_the_next_mission_is_not_ready()
	lu.assertNotEquals(opens(pilot({ t4 = { 3 }, paid = { 1 } })), "ready", "one skill, mission 1 won: mission 2 needs two")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "attempted" } })), "m2_failed", "mission 2 attempted: the failure line, not ready")
end

-- G17 (C-1)
-- B-3
function TestStormT4Gates:test_a_pilot_with_the_xp_and_no_mission_pending_opens_the_training_screen()
	lu.assertEquals(opens(pilot({ xp = D.TRAIN_COST })), "ready_train", "1,000,000 XP, no _04 skill")
	lu.assertEquals(opens(pilot({ xp = D.TRAIN_COST, t4 = { 1 }, paid = { 1 } })), "ready_train", "one skill, its mission paid")
	lu.assertEquals(opens(pilot({ xp = D.TRAIN_COST, t4 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "ready_train", "three skills, three missions paid")
	lu.assertNotEquals(opens(pilot({ xp = D.TRAIN_COST - 1 })), "ready_train", "999,999 XP")
end

-- G17 comes before G18
-- B-3, R-6
function TestStormT4Gates:test_the_training_screen_comes_before_the_first_meeting()
	lu.assertEquals(opens(D.pilot({ xp = D.TRAIN_COST })), "ready_train", "no met key, the XP: J's order puts the training first")
end

-- G18
-- B-3, B-4
function TestStormT4Gates:test_a_pilot_who_has_not_met_kilnstrider_opens_the_intro()
	lu.assertEquals(opens(D.pilot({})), "intro", "no met key")
	lu.assertEquals(opens(D.pilot({ xp = D.TRAIN_COST - 1 })), "intro", "just under the XP")
end

-- G19
-- B-3
function TestStormT4Gates:test_a_pilot_who_met_kilnstrider_with_tier_4_incomplete_opens_the_duty_menu_screen()
	lu.assertEquals(opens(pilot({})), "tier4_incomplete", "no _04 skill, under the XP")
	lu.assertEquals(opens(pilot({ t4 = { 1 }, paid = { 1 } })), "tier4_incomplete", "one skill, its mission paid, under the XP")
	lu.assertEquals(opens(pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "tier4_incomplete", "three skills, three missions paid")
end

-- G20
-- B-3, B-8
function TestStormT4Gates:test_a_pilot_with_all_missions_paid_and_four_skills_opens_the_transfer_on_every_talk()
	for _ = 1, 3 do
		lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL })), "transfer", "four skills, four missions paid, no master skill")
	end

	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, xp = D.TRAIN_COST })), "transfer", "the XP does not offer training once tier 4 is complete")
end

-- G21
-- B-3, B-8
function TestStormT4Gates:test_a_pilot_with_the_master_skill_opens_here_for_work()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = ALL, master = true })), "here_for_work", "the master skill")
end

-- G12-G15 before G20: mission 4 unpaid with four skills is the reward, not the transfer
-- B-3
function TestStormT4Gates:test_mission_4_unpaid_with_four_skills_opens_the_reward_not_the_transfer()
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "mission 4 won, unpaid")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "mission 4 running")
	lu.assertEquals(opens(pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "failed" } })), "m4_failed", "mission 4 failed")
end

-- R-6: a graduate without the met key sees the first meeting, and the briefing sets the key
-- B-3, B-4
function TestStormT4Gates:test_a_graduate_without_the_met_key_sees_the_intro_then_the_transfer()
	local player = D.pilot({ t4 = ALL, paid = ALL })

	lu.assertEquals(opens(player), "intro", "G18 comes before G20")

	local t = D.talk(player, { "s_49425c4b" })

	lu.assertEquals(D.ids(t), { "intro", "intro_briefing" }, "the first meeting")
	lu.assertEquals(opens(player), "transfer", "the next talk is the transfer")
end

-- the refusal lines
-- B-3
function TestStormT4Gates:test_the_refusals_show_their_client_lines_and_end()
	local cases = {
		{ D.pilot(NON_PILOT), "not_pilot", "s_d318f289" },
		{ D.pilot({ pilot = "neutral", squadron = false }), "wrong_faction", "s_e16137e8" },
		{ D.pilot({ standing = -1 }), "wanted", "s_f2643fdd" },
		{ D.pilot({ t3 = { 1, 2, 3 } }), "not_ready", "s_d3b2272c" },
		{ pilot({ mission = { [1] = "active" } }), "on_mission", "s_2a35d2fe" },
	}

	for _, c in ipairs(cases) do
		local t = D.talk(c[1])

		lu.assertEquals(D.ids(t), { c[2] }, "screens shown")
		lu.assertEquals(t[1].text, D.PREFIX .. c[3], c[2] .. ": the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end

	lu.assertTrue(D.talk(D.pilot(NON_PILOT))[1].stop, "not_pilot ends")
	lu.assertTrue(D.talk(D.pilot({ pilot = "neutral", squadron = false }))[1].stop, "wrong_faction ends")
	lu.assertTrue(D.talk(D.pilot({ t3 = { 1, 2, 3 } }))[1].stop, "not_ready ends")
	lu.assertTrue(D.talk(pilot({ mission = { [1] = "active" } }))[1].stop, "on_mission ends")
end

-- I-9: getInitialScreen changes no state (the action screens may, on display: that is table H, tested elsewhere)
-- B-3
function TestStormT4Gates:test_get_initial_screen_changes_no_state_and_starts_pays_and_grants_nothing()
	local spies = D.spyStarts()
	local cases = {
		D.pilot({ standing = -1 }), D.pilot({ t3 = { 1, 2, 3 } }), D.pilot({ squadron = false }), D.pilot(), D.pilot(NON_PILOT), pilot({ xp = D.TRAIN_COST }),
		pilot({ t4 = { 1 } }), pilot({}), pilot({ t4 = ALL, paid = ALL }), pilot({ t4 = ALL, paid = ALL, master = true }), pilot({ mission = { [2] = "failed" } }),
		pilot({ mission = { [3] = "won" } }), pilot({ mission = { [1] = "won", [2] = "failed" } }), pilot({ t4 = ALL, paid = { 1, 2, 3 }, pilotTier = 3 }),
		pilot({ pilot = "rebel", faction = "rebel", squadron = false }), pilot({ t4 = ALL, paid = ALL, pilotTier = 4 }), pilot({ squadron = "black_epsilon", standing = -1 }),
		pilot({ duty = D.DUTIES[1] }), pilot({ t3 = { 1, 2, 3 }, xp = D.TRAIN_COST, pilotTier = 3 }),
	}

	for i, player in ipairs(cases) do
		local before = D.snapshot(player)

		lu.assertNotNil(handler():getInitialScreen(player, D.npc(), H.conversationTemplate(D.TEMPLATE)), "case " .. i .. ": a screen")
		lu.assertEquals(D.snapshot(player), before, "case " .. i .. ": credits, standing, pilot tier, XP, skills, inventory, keys and the met key are untouched by a gate")
	end

	lu.assertEquals(D.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
end

-- I-9: the met key and the status keys of an unmet pilot stay unset after the gate
-- B-3, B-4
function TestStormT4Gates:test_the_intro_gate_does_not_set_the_met_key()
	local player = D.pilot({})

	lu.assertEquals(opens(player), "intro", "first talk")
	lu.assertFalse(D.hasKey(player, D.MET_KEY), "the met key after the gate screen")
	lu.assertEquals(opens(player), "intro", "a second talk without the reply still opens intro")
end

---------------------------------------------------------------------------------------------
-- The public helpers (Content contract 2)
---------------------------------------------------------------------------------------------

TestStormT4Helpers = {}

TestStormT4Helpers.setUp = setUp

function TestStormT4Helpers:test_get_quest_string_returns_the_squadron_constants_of_the_mission()
	local h = handler()

	for n, m in ipairs(D.MISSIONS) do
		lu.assertEquals(h:getQuestString(n), D.QUEST_STRINGS[m.questString], "getQuestString(" .. n .. ")")
		lu.assertEquals(h.MISSIONS[n].head, m.head, "MISSIONS[" .. n .. "].head")
		lu.assertEquals(h.MISSIONS[n].questString, m.questString, "MISSIONS[" .. n .. "].questString")
		lu.assertEquals(h.MISSIONS[n].endString, m.endString, "MISSIONS[" .. n .. "].endString")
	end
end

-- isWon, isActive, isFailed, isPaid
function TestStormT4Helpers:test_is_won_is_active_is_failed_and_is_paid_follow_the_chain_end_the_head_and_the_keys()
	local h = handler()
	local player = pilot({ mission = { [1] = "won", [2] = "active", [3] = "failed" }, paid = { 4 } })

	lu.assertEquals({ h:isWon(player, 1), h:isWon(player, 2), h:isWon(player, 3), h:isWon(player, 4) }, { true, false, false, true }, "isWon 1..4")
	lu.assertEquals({ h:isActive(player, 1), h:isActive(player, 2), h:isActive(player, 3), h:isActive(player, 4) }, { false, true, false, false }, "isActive 1..4")
	lu.assertEquals({ h:isFailed(player, 1), h:isFailed(player, 2), h:isFailed(player, 3), h:isFailed(player, 4) }, { false, false, true, false }, "isFailed 1..4")
	lu.assertEquals({ h:isPaid(player, 1), h:isPaid(player, 2), h:isPaid(player, 3), h:isPaid(player, 4) }, { false, false, false, true }, "isPaid 1..4")
end

-- isActive: any member of the chain, not only the head
function TestStormT4Helpers:test_is_active_sees_any_chain_member()
	local h = handler()

	for n, m in ipairs(D.MISSIONS) do
		for i, global in ipairs(m.chain) do
			local player = pilot({ mission = { [n] = "attempted" } })

			D.setState(player, global, "active")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. ": member " .. i .. " (" .. global .. ") active")
			lu.assertFalse(h:isFailed(player, n), "mission " .. n .. ": an active member is not a failure")
		end
	end
end

-- isWon needs the chain end, not the head
function TestStormT4Helpers:test_is_won_needs_the_chain_end()
	local h = handler()

	for n in ipairs(D.MISSIONS) do
		lu.assertFalse(h:isWon(pilot({ mission = { [n] = "partial" } }), n), "mission " .. n .. ": the head alone")
		lu.assertTrue(h:isWon(pilot({ mission = { [n] = "endonly" } }), n), "mission " .. n .. ": the chain end alone")
	end
end

-- isOnMission: the four chains or the four duties
function TestStormT4Helpers:test_is_on_mission_sees_the_four_chains_and_the_four_duties()
	local h = handler()

	lu.assertFalse(h:isOnMission(pilot({})), "nothing running")
	lu.assertFalse(h:isOnMission(pilot({ mission = { [1] = "won", [2] = "failed" } })), "won and failed missions are not running")

	for n = 1, 4 do
		lu.assertTrue(h:isOnMission(pilot({ mission = { [n] = "active" } })), "mission " .. n .. " running")
		lu.assertTrue(h:isOnMission(pilot({ duty = D.DUTIES[n] })), "duty " .. n .. " running")
	end
end

-- isGrounded (D-6)
function TestStormT4Helpers:test_is_grounded_is_negative_standing_or_a_faction_that_is_not_imperial()
	local h = handler()

	lu.assertFalse(h:isGrounded(D.pilot({ standing = 0 })), "standing 0")
	lu.assertTrue(h:isGrounded(D.pilot({ standing = -1 })), "standing -1")
	lu.assertTrue(h:isGrounded(D.pilot({ faction = "neutral" })), "no faction")
	lu.assertTrue(h:isGrounded(D.pilot({ faction = "rebel" })), "Rebel faction")
end

-- getNextMission
function TestStormT4Helpers:test_get_next_mission_is_the_smallest_mission_not_won()
	local h = handler()

	lu.assertEquals(h:getNextMission(pilot({})), 1, "nothing won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won" } })), 2, "M1 won")
	lu.assertEquals(h:getNextMission(pilot({ mission = { [1] = "won", [3] = "won" } })), 2, "M1 and M3 won: the gap")
	lu.assertEquals(h:getNextMission(pilot({ paid = { 1, 2, 3 } })), 4, "M1-M3 paid")
	lu.assertNil(h:getNextMission(pilot({ paid = ALL })), "all won")
end

-- getReadyMission (FK-3)
function TestStormT4Helpers:test_get_ready_mission_needs_a_skill_for_the_next_mission_that_is_not_attempted()
	local h = handler()

	lu.assertNil(h:getReadyMission(pilot({})), "no skill")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 3 } })), 1, "one skill, nothing won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 3 }, paid = { 1 } })), "one skill, mission 1 won: mission 2 needs two")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 } })), 2, "two skills, mission 1 won")
	lu.assertEquals(h:getReadyMission(pilot({ t4 = ALL, paid = { 1, 2, 3 } })), 4, "four skills, three missions won")
	lu.assertNil(h:getReadyMission(pilot({ t4 = ALL, paid = ALL })), "all won: no next mission")
	lu.assertNil(h:getReadyMission(pilot({ t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "attempted" } })), "the next mission is attempted")
end

-- canFlyNonTrackDuty (J:244-251)
function TestStormT4Helpers:test_can_fly_non_track_duty_needs_tier_3_done_no_mission_and_no_datapad_quest()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(D.pilot({ squadron = false })), "four _03 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(D.pilot({ squadron = false, t3 = { 1, 2, 3 } })), "three _03 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(D.pilot({ squadron = false, datapad = "duty" })), "a datapad duty")
	lu.assertFalse(h:canFlyNonTrackDuty(D.pilot({ squadron = false, datapad = "story" })), "a datapad story mission")
	lu.assertFalse(h:canFlyNonTrackDuty(D.pilot({ squadron = false, mission = { [2] = "active" } })), "a running Kilnstrider chain")
	lu.assertFalse(h:canFlyNonTrackDuty(D.pilot({ squadron = false, duty = D.DUTIES[2] })), "a running duty of this trainer")
end

-- isReadyForTraining
function TestStormT4Helpers:test_is_ready_for_training_needs_the_xp_tier_3_done_tier_4_open_and_no_ready_mission()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST })) == true, "1,000,000 XP exactly")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST - 1 })) == true, "999,999 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST, t3 = { 1, 2, 3 } })) == true, "three _03 skills")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST, t4 = ALL, paid = ALL })) == true, "tier 4 complete")
	lu.assertFalse(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST, t4 = { 1 } })) == true, "a ready mission waits")
	lu.assertTrue(h:isReadyForTraining(pilot({ xp = D.TRAIN_COST, t4 = { 1 }, paid = { 1 } })) == true, "the skill's mission is done")
end

-- the status helpers read <playerID><head questName><suffix> == "1"; key helpers use the squadron constants
function TestStormT4Helpers:test_has_status_and_the_key_helpers_read_and_write_the_player_keyed_status()
	local h = handler()
	local player = pilot({ mission = { [2] = "attempted" }, paid = { 1 } })

	lu.assertTrue(h:hasStatus(player, 1, ":reward"), "mission 1 reward key")
	lu.assertTrue(h:hasStatus(player, 2, ":attempted"), "mission 2 attempted key")
	lu.assertFalse(h:hasStatus(player, 2, ":reward"), "mission 2 reward key")
	lu.assertFalse(h:hasKey(D.pilot({}), StormSquadronScreenplay.TIER4_MET_KEY), "met key not set")
	h:setKey(player, D.MET_KEY)
	lu.assertEquals(H.getQuestStatus(player, D.MET_KEY), "1", "setKey stores '1' under the player id and the key")
end

-- payMission / raisePilotTier are exercised through the screens (rewards and training tests); the tables of Content contract 2 are public
function TestStormT4Helpers:test_the_handler_tables_are_the_ones_of_content_contract_2()
	local h = handler()

	lu.assertEquals(h.TRAINED_BRIEFS, D.TRAINED_BRIEFS, "TRAINED_BRIEFS")
	lu.assertEquals(h.DUTY_SCREENS, {
		duty_destroy = D.DUTIES[1], duty_escort = D.DUTIES[2], duty_recovery = D.DUTIES[3], duty_rescue = D.DUTIES[4],
	}, "DUTY_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }, "REWARD_SCREENS")
	lu.assertEquals(h.START_SCREENS, D.STARTS, "START_SCREENS equals the start screens of Appendix A (14)")

	local train = {}

	for i, entry in ipairs(h.TRAIN_CHOICES) do
		train[i] = { entry[1], entry[2], entry[3] }
	end

	local want = {}

	for i, t in ipairs(D.TRAIN) do
		want[i] = { t.skill, D.PREFIX .. t.reply, "m1_brief" }
	end

	lu.assertEquals(train, want, "TRAIN_CHOICES: skill, topic, default link")
end
