-- Arnecio Ulvaw'op: which screen a pilot opens on (gate table E), the refusal walks, the Q-B1 ready gate, the Q-B2 hand-off gate, the failure/reward/offer ordering,
-- the helpers the spec names and purity.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-3, AC-8 first bullet; Conversation flow 1; Content contract 2 (helpers); FU-6, FU-7; D-7 to D-10; I-3, I-7).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is crimson_tier3_data.lua T.pilot (a Crimson Phoenix
-- pilot who finished tier 2: four _02 skills, EKER_PILOT_KEY "3", Eker's four missions paid; missions = Ulvaw'op's missions won and paid; t3 = the tier 3 skills held;
-- state = the state of the next mission). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

T.loadConversation()

local function handler() return rawget(_G, T.HANDLER) end

local function snapshot(player)
	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = T.standing(player), xp = player.ghost.experience.space_combat_general,
		pilotTier = player.ghost.pilotTier, skills = T.held3(player), inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
		flag = T.flag(player),
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-3 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = handler():getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-3)")
	return first
end

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

TestUlvawopGates = {}

TestUlvawopGates.setUp = setUp

-- E0
-- AC-3
function TestUlvawopGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = T.pilot(), T.npc(), H.conversationTemplate(T.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- E1
-- AC-3
function TestUlvawopGates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(T.pilot()), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = T.pilot()

	player.ghost = nil
	lu.assertEquals(T.firstScreen(player), "not_pilot", "ghost is nil")
end

-- E2 (JU:8098)
-- AC-3
function TestUlvawopGates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = T.talk(T.nonPilot())

	lu.assertEquals(T.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_d9245236", "'I don't think I know you...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E2 precedes every other row (JU checks isPilot first)
-- AC-3
function TestUlvawopGates:test_not_pilot_precedes_the_faction_track_standing_ready_and_offer_gates()
	lu.assertEquals(opens(T.nonPilot({ faction = "neutral" })), "not_pilot", "plain non-pilot without a faction")
	lu.assertEquals(opens(T.nonPilot({ standing = -5 })), "not_pilot", "E2 precedes the grounded gate")
	lu.assertEquals(opens(T.pilot({ pilot = false, missions = 4, t3 = 4 })), "not_pilot", "four _03 skills, the flag and M4 paid, but no pilot: E2 precedes the hand-off")
end

-- E3 (JU:8105)
-- AC-3
function TestUlvawopGates:test_an_imperial_pilot_and_a_freelance_pilot_open_wrong_faction_which_ends_without_replies()
	local t = T.talk(T.pilot({ pilot = "imperial", faction = "imperial" }))

	lu.assertEquals(T.ids(t), { "wrong_faction" }, "Imperial pilot")
	lu.assertTrue(t[1].stop, "wrong_faction ends the conversation")
	lu.assertEquals(#t[1].options, 0, "wrong_faction offers no reply")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_39d07e54", "'There's nothing for you here.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local freelance = T.talk(T.pilot({ pilot = "neutral", faction = "neutral", squadron = false }))

	lu.assertEquals(T.ids(freelance), { "wrong_faction" }, "freelance pilot")
	lu.assertTrue(freelance[1].stop, "wrong_faction ends the conversation")
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", faction = "rebel" })), "wrong_faction", "Imperial pilot skills with Rebel faction")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", faction = "rebel", squadron = false })), "wrong_faction", "freelance pilot with Rebel faction")
end

-- E3 precedes E4 to E20 (D-9: a graduate who turned Imperial hears "There's nothing for you here.")
-- AC-3
function TestUlvawopGates:test_wrong_faction_comes_before_the_track_standing_ready_and_hand_off_gates()
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", faction = "imperial", squadron = HAVOC_SQUADRON })), "wrong_faction", "an Imperial pilot in a Havoc squadron: E3 precedes E4")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "wrong_faction", "E3 precedes the grounded gate")
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", faction = "imperial", ekerMissions = 0 })), "wrong_faction", "E3 precedes not_ready")
	lu.assertEquals(opens(T.pilot({ pilot = "imperial", faction = "imperial", missions = 4, t3 = 4 })), "wrong_faction", "a tier 3 graduate with Imperial pilot skills: E3 precedes the hand-off (D-9)")
end

-- E4 (JU:8112)
-- AC-3
function TestUlvawopGates:test_a_havoc_and_a_vortex_pilot_with_four_tier_3_skills_open_off_track_which_ends_and_offers_nothing()
	for name, squadron in pairs({ havoc = HAVOC_SQUADRON, vortex = VORTEX_SQUADRON }) do
		H.reset()

		local player = T.pilot({ squadron = squadron, missions = 4, t3 = 4, graduated = false })
		local t = T.talk(player)

		lu.assertEquals(T.ids(t), { "off_track" }, name .. " pilot who finished their own tier 3 (the same _03 skills)")
		lu.assertTrue(t[1].stop, "off_track ends the conversation")
		lu.assertEquals(#t[1].options, 0, "off_track offers no reply: no duties exist for Ulvaw'op")
		lu.assertEquals(t[1].text, T.PREFIX .. "s_30a2d12d", "'I'm afraid I won't be of much use to you...'")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- E4: a Rebel pilot with no squadron, or in another squadron, is off track too; E4 precedes E5 to E7 and the hand-off (a Havoc/Vortex graduate is never handed to Ufwol)
-- AC-3, AC-8
function TestUlvawopGates:test_a_pilot_outside_the_crimson_phoenix_squadron_opens_off_track_before_the_later_gates()
	lu.assertEquals(opens(T.pilot({ squadron = false })), "off_track", "no squadron")
	lu.assertEquals(opens(T.pilot({ squadron = HAVOC_SQUADRON, standing = -5 })), "off_track", "E4 precedes the grounded gate")
	lu.assertEquals(opens(T.pilot({ squadron = HAVOC_SQUADRON, ekerMissions = 0 })), "off_track", "E4 precedes not_ready")
	lu.assertEquals(opens(T.pilot({ squadron = VORTEX_SQUADRON, active = T.M1[1] })), "off_track", "E4 precedes on_mission")
	lu.assertEquals(opens(T.pilot({ squadron = VORTEX_SQUADRON, missions = 4, t3 = 4 })), "off_track", "a Vortex tier 3 graduate with the flag and a paid key is never handed to Ufwol")
end

-- E5 (JU:8119, hardened D-8)
-- AC-3
function TestUlvawopGates:test_a_crimson_phoenix_pilot_with_rebel_standing_minus_one_opens_grounded_and_the_walk_grants_nothing()
	local player = T.pilot({ standing = -1 })
	local before = snapshot(player)
	local t = T.talk(player)

	lu.assertEquals(T.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_c3e376a5", "'%TU!  Explain yourself!...'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(T.optionSids(t[1]), { "s_ecb17e60" }, "the grounded chain opens with one reply")
	lu.assertFalse(t[1].stop, "grounded does not end")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local walked = T.talk(player, { "s_ecb17e60", "s_f8b02865" })

	lu.assertEquals(T.ids(walked), { "grounded", "grounded_trust", "grounded_standing" }, "the grounded walk")
	lu.assertEquals(T.optionSids(walked[2]), { "s_f8b02865" }, "grounded_trust has one reply")
	lu.assertTrue(walked[3].stop, "grounded_standing ends")
	lu.assertEquals(#walked[3].options, 0, "grounded_standing offers nothing")
	lu.assertEquals(walked[3].text, T.PREFIX .. "s_1d28ae3", "'Nothing!  Not until you straighten this situation out...'")

	local after = snapshot(player)

	lu.assertEquals(after.state.status, before.state.status, "no status key written")
	lu.assertEquals(after.skills, before.skills, "no skill")
	lu.assertEquals(after.credits, before.credits, "no credits")
	lu.assertEquals(after.standing, -1, "standing unchanged")
	lu.assertEquals(after.flag, before.flag, "EKER_PILOT_KEY untouched")
end

-- E5: standing 0 is not negative; a Rebel pilot whose faction is not Rebel is grounded too; E5 precedes E6 to E20 including the hand-off (D-9)
-- AC-3, AC-8
function TestUlvawopGates:test_standing_zero_is_not_grounded_a_non_rebel_faction_is_and_grounded_precedes_the_ready_mission_and_hand_off_gates()
	lu.assertNotEquals(opens(T.pilot({ standing = 0 })), "grounded", "standing 0")
	lu.assertEquals(opens(T.pilot({ faction = "neutral" })), "grounded", "Rebel pilot of neutral faction")
	lu.assertEquals(opens(T.pilot({ standing = -1, ekerMissions = 0 })), "grounded", "E5 precedes not_ready")
	lu.assertEquals(opens(T.pilot({ standing = -1, active = T.M2[1] })), "grounded", "E5 precedes on_mission")
	lu.assertEquals(opens(T.pilot({ standing = -1, missions = 1, t3 = 1, state = "failed" })), "grounded", "E5 precedes the failure screens")
	lu.assertEquals(opens(T.rewardPilot(1, { standing = -1 })), "grounded", "E5 precedes the reward screens")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, standing = -1 })), "grounded", "a tier 3 graduate with negative standing: grounded, not the hand-off (JU's order, unlike Ezkiel's)")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, faction = "neutral" })), "grounded", "a tier 3 graduate of neutral faction: grounded")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, faction = "imperial" })), "grounded", "a tier 3 graduate of Imperial faction (Rebel pilot skills): grounded")
end

-- E6 (JU:8157, Q-B1 = A)
-- AC-3
function TestUlvawopGates:test_a_pilot_whose_tier_2_is_not_complete_opens_not_ready_which_ends_without_replies()
	local t = T.talk(T.pilot({ ekerMissions = 3 }))

	lu.assertEquals(T.ids(t), { "not_ready" }, "four _02 skills and the flag, Eker's M4 unpaid")
	lu.assertTrue(t[1].stop, "not_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_ready offers no reply")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_614f7f1c", "'You haven't been cleared for this level yet.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(T.pilot({ t2 = 3 })), "not_ready", "Eker's M4 paid but only three _02 skills")
	lu.assertEquals(opens(T.pilot({ t2 = 0 })), "not_ready", "no _02 skill")
	lu.assertEquals(opens(T.pilot({ graduated = false })), "not_ready", "four _02 skills, M4 paid, no EKER_PILOT_KEY")
	lu.assertEquals(opens(T.pilot({ ekerMissions = 0 })), "not_ready", "no Eker mission paid")
end

-- E6: the ready check reads the yavin_rebel_16:reward key of Eker's M4 (Q-B1 = A)
-- AC-3
function TestUlvawopGates:test_the_ready_gate_reads_ekers_mission_4_reward_key()
	local player = T.pilot({ ekerMissions = 3 })

	lu.assertEquals(opens(player), "not_ready", "reward key absent")
	H.setQuestStatus(player, T.TIER2_M4_REWARD, 1)
	lu.assertEquals(opens(player), "m1_offer", "the yavin_rebel_16:reward key opens the first offer")
end

-- E6: any set flag value is ready (the values 1, 2 and 3)
-- AC-3
function TestUlvawopGates:test_flag_values_1_2_and_3_are_all_ready_for_tier_3()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(T.pilot({ graduated = flag })), "m1_offer", "flag " .. flag .. ", tier 2 complete")
	end
end

-- E6 precedes E7 to E20
-- AC-3
function TestUlvawopGates:test_not_ready_comes_before_on_mission_the_failures_the_rewards_and_the_offers()
	lu.assertEquals(opens(T.pilot({ ekerMissions = 3, active = T.M1[1] })), "not_ready", "E6 precedes on_mission")
	lu.assertEquals(opens(T.pilot({ ekerMissions = 3, state = "failed" })), "not_ready", "E6 precedes m1_failed")
	lu.assertEquals(opens(T.pilot({ ekerMissions = 3, state = "won" })), "not_ready", "E6 precedes m1_reward")
	lu.assertEquals(opens(T.pilot({ ekerMissions = 3, missions = 4, t3 = 4 })), "not_ready", "E6 precedes the hand-off")
end

-- E7 (JU:8164)
-- AC-3
function TestUlvawopGates:test_a_pilot_flying_any_of_the_seventeen_ulvawop_quests_opens_on_mission_which_ends_without_replies()
	for _, global in ipairs(T.GLOBALS) do
		H.reset()

		local t = T.talk(T.pilot({ active = global }))

		lu.assertEquals(T.ids(t), { "on_mission" }, global .. " active")
		lu.assertTrue(t[1].stop, "on_mission ends the conversation")
		lu.assertEquals(#t[1].options, 0, "on_mission offers no reply")
		lu.assertEquals(t[1].text, T.PREFIX .. "s_329414b2", "'Please, do not waste your time talking to me...'")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- E7: a quest from another trainer in the datapad blocks too (SpaceHelpers:hasSpaceQuest)
-- AC-3
function TestUlvawopGates:test_a_space_quest_of_another_trainer_in_the_datapad_opens_on_mission()
	lu.assertEquals(opens(T.pilot({ datapad = "story" })), "on_mission", "a story mission of another trainer in the datapad")
	lu.assertEquals(opens(T.pilot({ datapad = "duty" })), "on_mission", "a duty of another trainer in the datapad")
	lu.assertEquals(opens(T.pilot({ missions = 2, t3 = 2, datapad = "story" })), "on_mission", "between missions 2 and 3")
end

-- E7 precedes E8 to E20
-- AC-3
function TestUlvawopGates:test_on_mission_comes_before_the_failures_the_rewards_the_offers_and_the_hand_off()
	lu.assertEquals(opens(T.pilot({ state = "failed", active = T.M2[1] })), "on_mission", "mission 1 attempted and mission 2 running")
	lu.assertEquals(opens(T.pilot({ state = "active" })), "on_mission", "mission 1 running")
	lu.assertEquals(opens(T.rewardPilot(2, { active = T.M3[1] })), "on_mission", "a reward owed, another mission running")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, datapad = "duty" })), "on_mission", "a graduate with a duty of another trainer in the datapad")
end

-- E8 to E11: a mission attempted and neither won nor running opens its failure screen
-- AC-3, AC-5
for n = 1, 4 do
	TestUlvawopGates["test_mission_" .. n .. "_attempted_and_not_won_opens_m" .. n .. "_failed"] = function()
		local player = T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" })

		lu.assertEquals(opens(player), "m" .. n .. "_failed", "mission " .. n .. " attempted, nothing complete or running")
	end

	-- AC-5: any chain member failed (a prefix of the chain complete, nothing running) is a failure
	TestUlvawopGates["test_mission_" .. n .. "_with_a_failed_chain_member_opens_m" .. n .. "_failed"] = function()
		for k = 0, #T.CHAINS[n] - 1 do
			H.reset()

			local player = T.pilot({ missions = n - 1, t3 = n - 1, partial = k })

			lu.assertEquals(opens(player), "m" .. n .. "_failed", "mission " .. n .. ": the first " .. k .. " quests complete, the next one failed")
		end
	end

	-- AC-5: a head aborted from the datapad is a failure (abort is failure)
	TestUlvawopGates["test_mission_" .. n .. "_aborted_from_the_datapad_opens_m" .. n .. "_failed"] = function()
		local player = T.pilot({ missions = n - 1, t3 = n - 1 })
		local head = T.quest(T.HEADS[n])

		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")
		T.setState(player, T.HEADS[n], "active")
		lu.assertEquals(opens(player), "on_mission", "while it flies")
		head:abortQuest(player)
		lu.assertEquals(T.state(player, T.HEADS[n]), "none", "the abort ends the run")
		lu.assertEquals(opens(player), "m" .. n .. "_failed", "after the abort (abort is failure)")
	end

	-- AC-5: the failure screen is the line of JU's failure gate and offers its two retry replies
	TestUlvawopGates["test_m" .. n .. "_failed_shows_the_ju_line_with_two_replies_and_does_not_end"] = function()
		local want = { { "s_5a66cd79", "s_a68dfaa6", "s_9401fd7b" }, { "s_67c8f113", "s_d85b3a9c", "s_87d7e908" }, { "s_c74a6348", "s_d454739a", "s_9173548c" }, { "s_4748286f", "s_b40f340", "s_9fb0046e" } }
		local t = T.talk(T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }))

		lu.assertEquals(T.ids(t), { "m" .. n .. "_failed" }, "mission " .. n .. ": first screen")
		lu.assertEquals(t[1].text, T.PREFIX .. want[n][1], "mission " .. n .. ": the failure line")
		lu.assertEquals(T.optionSids(t[1]), { want[n][2], want[n][3] }, "mission " .. n .. ": the two replies")
		lu.assertFalse(t[1].stop, "the failure screen does not end")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- FU-7: the failures are checked in the order M1, M2, M3, M4
-- AC-3
function TestUlvawopGates:test_the_failure_screens_come_in_the_order_m1_m2_m3_m4()
	local function openFor(attempted)
		local player = T.pilot({})

		for _, n in ipairs(attempted) do
			H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")
		end

		return opens(player)
	end

	lu.assertEquals(openFor({ 2, 3 }), "m2_failed", "2 before 3")
	lu.assertEquals(openFor({ 3, 1 }), "m1_failed", "1 before 3")
	lu.assertEquals(openFor({ 4, 1 }), "m1_failed", "1 before 4")
	lu.assertEquals(openFor({ 4, 3 }), "m3_failed", "3 before 4")
	lu.assertEquals(openFor({ 1, 2, 3, 4 }), "m1_failed", "1 first of all")
end

-- E8 to E11: a won mission is not failed, a running one is on_mission
-- AC-3, AC-5
function TestUlvawopGates:test_attempted_and_won_is_not_failed_and_attempted_and_running_is_on_mission()
	lu.assertEquals(opens(T.pilot({ state = "won" })), "m1_reward", "attempted and won: the reward, not the failure")
	lu.assertEquals(opens(T.pilot({ state = "active" })), "on_mission", "attempted and running: E7 precedes E8")
end

-- E8 to E11 precede the rewards and the offers
-- AC-3
function TestUlvawopGates:test_the_failure_screens_precede_the_reward_and_offer_screens()
	local player = T.pilot({ missions = 0, state = "won" })

	H.setQuestStatus(player, T.STATUS[2] .. ":attempted", "1")
	lu.assertEquals(opens(player), "m2_failed", "mission 1 won and unpaid, mission 2 attempted: E9 precedes E12")
end

-- E12 to E15
-- AC-3, AC-6
for n = 1, 4 do
	TestUlvawopGates["test_mission_" .. n .. "_won_and_unpaid_with_fewer_than_" .. n .. "_skills_opens_m" .. n .. "_reward"] = function()
		lu.assertEquals(opens(T.rewardPilot(n)), "m" .. n .. "_reward", "mission " .. n .. " won, count " .. (n - 1))
	end

	-- the count rule: mission n paid with its skill unchosen reopens on the reward screen; no later offer comes first
	TestUlvawopGates["test_mission_" .. n .. "_paid_with_its_skill_unchosen_still_opens_m" .. n .. "_reward_before_any_later_offer"] = function()
		local player = T.pilot({ missions = n, t3 = n - 1 })

		lu.assertEquals(opens(player), "m" .. n .. "_reward", "mission " .. n .. " paid, count " .. (n - 1))
	end
end

-- E12 to E15: the smallest owed mission first
-- AC-3
function TestUlvawopGates:test_the_smallest_owed_reward_screen_comes_first()
	lu.assertEquals(opens(T.pilot({ missions = 2 })), "m1_reward", "missions 1 and 2 won and paid, no skill chosen")
	lu.assertEquals(opens(T.pilot({ missions = 2, t3 = 1 })), "m2_reward", "two won, one skill chosen")
end

-- E12 to E15 / FU-6: tier 3 complete is not enough, mission 4 must be paid; a won, unpaid mission 4 opens m4_reward, never the hand-off
-- AC-3, AC-8
function TestUlvawopGates:test_four_skills_with_mission_4_won_and_unpaid_open_m4_reward_not_the_hand_off()
	lu.assertEquals(opens(T.pilot({ missions = 3, t3 = 4, state = "won" })), "m4_reward", "four _03 skills, mission 4 won and unpaid")
	lu.assertEquals(opens(T.pilot({ missions = 3, t3 = 3, state = "won" })), "m4_reward", "three _03 skills, mission 4 won and unpaid")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 3 })), "m4_reward", "mission 4 paid with its skill unchosen (three _03 skills)")
end

-- E16 to E19, AC-4: mission n+1 is offered only after mission n's skill is chosen
-- AC-3, AC-4
for n = 0, 3 do
	TestUlvawopGates["test_a_pilot_with_" .. n .. "_missions_won_and_" .. n .. "_skills_chosen_opens_m" .. (n + 1) .. "_offer"] = function()
		lu.assertEquals(opens(T.pilot({ missions = n, t3 = n })), "m" .. (n + 1) .. "_offer", n .. " missions paid, " .. n .. " skills")
	end
end

-- E16: a pilot with no quest state at all
-- AC-3, AC-4
function TestUlvawopGates:test_a_pilot_with_no_quest_state_opens_the_first_offer_and_the_walk_greets_him()
	local t = T.talk(T.pilot({}))

	lu.assertEquals(T.ids(t), { "m1_offer" }, "first screen")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_6f921f12", "'Welcome, %TU. You look different than I expected from your picture.'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(T.optionSids(t[1]), { "s_783af10a", "s_5b000af8" }, "'What picture?' / 'Different how?'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E16 to E19: the offer lines (JU:8453, 8502, 8543, 8584)
-- AC-4
function TestUlvawopGates:test_the_four_offers_show_the_ju_lines()
	local want = { "s_6f921f12", "s_1061c440", "s_5852ee6b", "s_5bd53e0a" }

	for n = 1, 4 do
		H.reset()

		local t = T.talk(T.readyFor(n))

		lu.assertEquals(T.ids(t), { "m" .. n .. "_offer" }, "mission " .. n .. ": first screen")
		lu.assertEquals(t[1].text, T.PREFIX .. want[n], "mission " .. n .. ": the offer line")
	end
end

-- E20 (JU:8624, Q-B2 = A): with four _03 skills, the flag and M4 paid the first screen is the hand-off
-- AC-3, AC-8
function TestUlvawopGates:test_a_tier_3_graduate_opens_handoff_which_offers_the_two_replies()
	local t = T.talk(T.pilot({ missions = 4, t3 = 4 }))

	lu.assertEquals(T.ids(t), { "handoff" }, "four _03 skills, flag, M4 paid")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_fb871ded", "'Central Command has issued new orders for you.'")
	lu.assertEquals(T.optionSids(t[1]), { "s_a927c891", "s_554b78dd" }, "'What's next?' / the spy remark")
	lu.assertFalse(t[1].stop, "handoff does not end the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E20: any set flag value counts (Q-B2 = A: the flag is part of isReadyForTier4)
-- AC-3, AC-8
function TestUlvawopGates:test_the_hand_off_needs_a_set_flag_not_a_particular_value()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, graduated = flag })), "handoff", "flag " .. flag)
	end
end

-- E6 precedes E20: a tier 3 graduate without the flag is not ready (Q-B1 = A), and a graduate whose Eker M4 key is gone neither
-- AC-3, AC-8
function TestUlvawopGates:test_a_graduate_without_the_flag_or_ekers_mission_4_reward_is_not_ready_and_gets_no_hand_off()
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, graduated = false })), "not_ready", "no flag")
	lu.assertEquals(opens(T.pilot({ missions = 4, t3 = 4, ekerMissions = 3 })), "not_ready", "Eker's M4 reward unset")
end

-- E21 (D-10): the default is JU's own refusal line, observable only with isReadyForTier4 stubbed false
-- AC-3
function TestUlvawopGates:test_with_is_ready_for_tier_4_stubbed_false_a_graduate_opens_not_ready_the_fallback()
	local player = T.pilot({ missions = 4, t3 = 4 })

	H.spyOn(handler(), "isReadyForTier4")
	lu.assertEquals(opens(player), "not_ready", "E21")
end

-- The session opens on the screen getInitialScreen picks (I-3)
-- AC-3
function TestUlvawopGates:test_the_session_opens_on_the_screen_getInitialScreen_picks()
	lu.assertEquals(T.firstScreen(T.pilot({ missions = 2, t3 = 2 })), "m3_offer", "session start")
	lu.assertEquals(opens(T.pilot({ missions = 2, t3 = 2 })), "m3_offer", "getInitialScreen alone")
end

-- I-3: getInitialScreen changes nothing for the pilots of every row (the state is checked inside opens())
-- AC-3
function TestUlvawopGates:test_getInitialScreen_is_pure_for_every_kind_of_pilot()
	local pilots = {
		T.nonPilot(), T.pilot({ missions = 4, t3 = 4, pilotTier = 3 }), T.pilot({ missions = 3, t3 = 4, state = "won", pilotTier = 3 }),
		T.pilot({ pilot = "imperial", faction = "imperial" }), T.pilot({ squadron = HAVOC_SQUADRON }), T.pilot({ squadron = VORTEX_SQUADRON, missions = 4, t3 = 4 }),
		T.pilot({ standing = -1 }), T.pilot({ missions = 4, t3 = 4, standing = -1 }), T.pilot({ ekerMissions = 3 }), T.pilot({ graduated = false }),
		T.pilot({ active = T.M3[3] }), T.pilot({ datapad = "story" }), T.pilot({ missions = 1, t3 = 1, state = "failed" }), T.pilot({ missions = 3, t3 = 3, state = "failed" }),
		T.rewardPilot(1), T.rewardPilot(4, { xp = 200000 }), T.pilot({ missions = 2, t3 = 2, inventory = { limit = 0 } }), T.pilot({}),
	}

	for i, player in ipairs(pilots) do
		opens(player)
		lu.assertTrue(i > 0, "pilot " .. i)
	end
end

-- AC-8, I-7: a graduate opening the conversation does not move EKER_PILOT_KEY, whatever its value
-- AC-3, AC-8
function TestUlvawopGates:test_the_gates_never_write_the_eker_pilot_key()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = T.pilot({ missions = 4, t3 = 4, graduated = flag })

		T.talk(player)
		T.talk(player, { "s_a927c891" })
		lu.assertEquals(T.flag(player), flag, "EKER_PILOT_KEY after two talks with flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- The helpers the spec names (Content contract 2)
---------------------------------------------------------------------------------------------

TestUlvawopHelpers = {}

TestUlvawopHelpers.setUp = setUp

-- Content contract 2: isWon is the chain end complete, isActive the chain running, isFailed attempted and neither, isPaid the :reward key
function TestUlvawopHelpers:test_is_won_is_active_is_failed_and_is_paid_follow_the_chain_end_the_journal_and_the_keys()
	local h = handler()
	local fresh = T.pilot({})

	for n = 1, 4 do
		lu.assertFalse(h:isWon(fresh, n), "fresh: isWon " .. n)
		lu.assertFalse(h:isActive(fresh, n), "fresh: isActive " .. n)
		lu.assertFalse(h:isFailed(fresh, n), "fresh: isFailed " .. n)
		lu.assertFalse(h:isPaid(fresh, n), "fresh: isPaid " .. n)
	end

	lu.assertFalse(h:isOnMission(fresh), "fresh: isOnMission")

	local won = T.pilot({ missions = 2, t3 = 2 })

	lu.assertTrue(h:isWon(won, 1) and h:isWon(won, 2), "two missions won")
	lu.assertTrue(h:isPaid(won, 1) and h:isPaid(won, 2), "two missions paid")
	lu.assertFalse(h:isWon(won, 3) or h:isPaid(won, 3), "mission 3 neither")
	lu.assertFalse(h:isFailed(won, 1), "a won mission is not failed")

	for n = 1, 4 do
		local flying = T.pilot({ active = T.CHAINS[n][3] })

		lu.assertTrue(h:isActive(flying, n), "a running member of chain " .. n .. ": isActive")
		lu.assertTrue(h:isOnMission(flying), "a running member of chain " .. n .. ": isOnMission")
		H.setQuestStatus(flying, T.STATUS[n] .. ":attempted", "1")
		lu.assertFalse(h:isFailed(flying, n), "attempted but running is not failed")
	end

	local failed = T.pilot({ state = "failed" })

	lu.assertTrue(h:isFailed(failed, 1), "attempted, not won, not running")
	lu.assertFalse(h:isWon(failed, 1), "failed is not won")
end

-- Content contract 2: isWon reads the chain end, not the head (a won head with an incomplete chain is not won)
function TestUlvawopHelpers:test_is_won_needs_the_chain_end_not_the_head()
	local player = T.pilot({ partial = 3 })

	lu.assertFalse(handler():isWon(player, 1), "head, delivery and survival complete, the escort (chain end) not")
	T.setState(player, T.M1[4], "complete")
	lu.assertTrue(handler():isWon(player, 1), "the chain end complete")
end

-- Content contract 2: getPilotFlag is the key value, or nil when unset or empty
function TestUlvawopHelpers:test_get_pilot_flag_is_the_key_value_or_nil()
	local h = handler()

	lu.assertEquals(h:getPilotFlag(T.pilot({ graduated = "3" })), "3", "flag 3")
	lu.assertEquals(h:getPilotFlag(T.pilot({ graduated = "1" })), "1", "flag 1")
	lu.assertNil(h:getPilotFlag(T.pilot({ graduated = false })), "flag unset")

	local empty = T.pilot({ graduated = false })

	H.setQuestStatus(empty, T.EKER_PILOT_KEY, "")
	lu.assertNil(h:getPilotFlag(empty), "flag empty")
end

-- Content contract 2: isReadyForTier3 (Q-B1 = A) and isReadyForTier4 (Q-B2 = A)
function TestUlvawopHelpers:test_is_ready_for_tier_3_and_tier_4()
	local h = handler()

	lu.assertTrue(h:isReadyForTier3(T.pilot({})), "tier 2 complete, flag, Eker's M4 paid")
	lu.assertFalse(h:isReadyForTier3(T.pilot({ ekerMissions = 3 })), "Eker's M4 unpaid")
	lu.assertFalse(h:isReadyForTier3(T.pilot({ t2 = 3 })), "three _02 skills")
	lu.assertFalse(h:isReadyForTier3(T.pilot({ graduated = false })), "no flag")
	lu.assertTrue(h:isReadyForTier4(T.pilot({ missions = 4, t3 = 4 })), "four _03 skills, flag, M4 paid")
	lu.assertFalse(h:isReadyForTier4(T.pilot({ missions = 3, t3 = 4, state = "won" })), "M4 won and unpaid")
	lu.assertFalse(h:isReadyForTier4(T.pilot({ missions = 4, t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:isReadyForTier4(T.pilot({ missions = 4, t3 = 4, graduated = false })), "no flag")
end

-- Content contract 2: getRewardMission is the smallest n with n won and fewer than n _03 skills; 4 also while M4 is won and unpaid; nil otherwise
function TestUlvawopHelpers:test_get_reward_mission_is_the_smallest_won_mission_with_fewer_skills_than_its_number()
	local h = handler()

	lu.assertNil(h:getRewardMission(T.pilot({})), "nothing won")
	lu.assertEquals(h:getRewardMission(T.rewardPilot(1)), 1, "mission 1 won, no skill")
	lu.assertEquals(h:getRewardMission(T.rewardPilot(3)), 3, "mission 3 won, two skills")
	lu.assertNil(h:getRewardMission(T.pilot({ missions = 1, t3 = 1 })), "mission 1 won and its skill chosen")
	lu.assertEquals(h:getRewardMission(T.pilot({ missions = 3, t3 = 4, state = "won" })), 4, "mission 4 won and unpaid with four skills")
	lu.assertNil(h:getRewardMission(T.pilot({ missions = 4, t3 = 4 })), "four paid, four skills")
end

-- Content contract 2: raisePilotTier raises a tier-3 pilot who holds all four _03 skills, once, and nobody else
function TestUlvawopHelpers:test_raise_pilot_tier_raises_a_tier_3_pilot_with_four_skills_only()
	local h = handler()
	local p = T.pilot({ missions = 4, t3 = 4, pilotTier = 3 })

	h:raisePilotTier(p, p.ghost)
	lu.assertEquals(p.ghost.pilotTier, 4, "tier 3 with four skills")
	h:raisePilotTier(p, p.ghost)
	lu.assertEquals(p.ghost.pilotTier, 4, "not raised twice")

	local three = T.pilot({ missions = 4, t3 = 3, pilotTier = 3 })

	h:raisePilotTier(three, three.ghost)
	lu.assertEquals(three.ghost.pilotTier, 3, "three skills: not raised")

	local two = T.pilot({ missions = 4, t3 = 4, pilotTier = 2 })

	h:raisePilotTier(two, two.ghost)
	lu.assertEquals(two.ghost.pilotTier, 2, "a tier 2 pilot is not raised by a tier 3 rule")
end
