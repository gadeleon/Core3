-- Brother Ezkiel: which screen a pilot opens on (gate table E), the refusal walks, the hand-off hardenings, the Q-B1 ready gate, the failure/reward/offer ordering and purity.
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-3; Conversation flow 1; FV-4, FV-5, FV-6; D-6, D-7, D-8, D-9, D-10; I-3, I-7).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is vortex_tier3_data.lua W.pilot
-- (a Vortex pilot who finished tier 2: four _02 skills, VORTEX_PILOT_KEY "3", Vrovel's four missions paid; missions = Ezkiel's missions won and paid; t3 = the tier 3
-- skills held; state = the state of the next mission). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

W.loadConversation()

local function handler() return rawget(_G, W.HANDLER) end

local function snapshot(player)
	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = W.standing(player), xp = player.ghost.experience.space_combat_general,
		pilotTier = player.ghost.pilotTier, skills = W.held3(player), inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
		flag = W.flag(player),
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-3 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = handler():getInitialScreen(player, W.npc(), H.conversationTemplate(W.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-3)")
	return first
end

local function setUp()
	H.reset()
	W.requireConversation(lu)
end

TestEzkielGates = {}

TestEzkielGates.setUp = setUp

-- E0
-- AC-3
function TestEzkielGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = W.pilot(), W.npc(), H.conversationTemplate(W.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- E1
-- AC-3
function TestEzkielGates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(W.pilot()), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = W.pilot()

	player.ghost = nil
	lu.assertEquals(W.firstScreen(player), "not_pilot", "ghost is nil")
end

-- E2 (J3:4581)
-- AC-3
function TestEzkielGates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = W.talk(W.nonPilot())

	lu.assertEquals(W.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_8a226979", "'I cannot help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E2 precedes every other row (J3 checks isPilot first)
-- AC-3
function TestEzkielGates:test_not_pilot_precedes_the_hand_off_the_faction_gates_and_the_offers()
	lu.assertEquals(opens(W.nonPilot({ faction = "neutral" })), "not_pilot", "plain non-pilot without a faction")
	lu.assertEquals(opens(W.nonPilot({ standing = -5 })), "not_pilot", "E2 precedes the grounded gate")
	lu.assertEquals(opens(W.pilot({ pilot = false, missions = 4, t3 = 4 })), "not_pilot", "four _03 skills, the flag and M4 paid, but no pilot: E2 precedes E3")
end

-- E3 (J3:4587)
-- AC-3, AC-8
function TestEzkielGates:test_a_tier_3_graduate_opens_tier_done_which_greets_by_name_and_offers_the_two_hand_off_replies()
	local player = W.pilot({ missions = 4, t3 = 4 })
	local t = W.talk(player)

	lu.assertEquals(W.ids(t), { "tier_done" }, "four _03 skills, flag, M4 paid")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_cbc2d68c", "'Your work here is done %TU.'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(W.optionSids(t[1]), { "s_9ac7f904", "s_eb3c17f0" }, "the two replies")
	lu.assertFalse(t[1].stop, "tier_done does not end the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E3: any set flag value counts, not a particular one (Vrovel writes "3"; the older writers "1" and "2")
-- AC-3
function TestEzkielGates:test_the_hand_off_needs_a_set_flag_not_a_particular_value()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, graduated = flag })), "tier_done", "flag " .. flag)
	end

	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, graduated = false })), "not_ready", "no flag: the tier 3 graduate is not a Vortex tier 2 graduate (E7)")
end

-- E3 precedes E4 to E6 (FV-5): the graduate is handed on whatever his faction, standing or squadron is
-- AC-3
function TestEzkielGates:test_the_hand_off_comes_before_the_faction_track_and_standing_gates()
	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, faction = "imperial" })), "tier_done", "Imperial faction")
	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, standing = -1 })), "tier_done", "negative standing")
	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, squadron = false })), "tier_done", "no squadron")
	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 4, pilot = "imperial", faction = "imperial" })), "tier_done", "Imperial pilot skills")
end

-- E3 hardening (FV-4): tier 3 complete is not enough, mission 4 must be paid; a won, unpaid mission 4 opens m4_reward
-- AC-3, AC-8
function TestEzkielGates:test_four_skills_with_mission_4_won_and_unpaid_open_m4_reward_not_tier_done()
	lu.assertEquals(opens(W.pilot({ missions = 3, t3 = 4, state = "won" })), "m4_reward", "four _03 skills, mission 4 won and unpaid")
	lu.assertEquals(opens(W.pilot({ missions = 3, t3 = 3, state = "won" })), "m4_reward", "three _03 skills, mission 4 won and unpaid")
	lu.assertEquals(opens(W.pilot({ missions = 4, t3 = 3 })), "m4_reward", "mission 4 paid with its skill unchosen (three _03 skills)")
end

-- E4 (J3:4637; Data mapping 2: s_13 -> the non-pilot line)
-- AC-3
function TestEzkielGates:test_an_imperial_pilot_and_a_freelance_pilot_open_wrong_faction_which_ends_without_replies()
	local t = W.talk(W.pilot({ pilot = "imperial", faction = "imperial" }))

	lu.assertEquals(W.ids(t), { "wrong_faction" }, "Imperial pilot")
	lu.assertTrue(t[1].stop, "wrong_faction ends the conversation")
	lu.assertEquals(#t[1].options, 0, "wrong_faction offers no reply")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_8a226979", "'I cannot help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local freelance = W.talk(W.pilot({ pilot = "neutral", faction = "neutral", squadron = false }))

	lu.assertEquals(W.ids(freelance), { "wrong_faction" }, "freelance pilot")
	lu.assertTrue(freelance[1].stop, "wrong_faction ends the conversation")
	lu.assertEquals(opens(W.pilot({ pilot = "imperial", faction = "rebel" })), "wrong_faction", "Imperial pilot skills with Rebel faction")
	lu.assertEquals(opens(W.pilot({ pilot = "neutral", faction = "rebel", squadron = false })), "wrong_faction", "freelance pilot with Rebel faction")
end

-- E4 precedes E5 to E8
-- AC-3
function TestEzkielGates:test_wrong_faction_comes_before_the_track_standing_and_ready_gates()
	lu.assertEquals(opens(W.pilot({ pilot = "imperial", faction = "imperial", squadron = HAVOC_SQUADRON })), "wrong_faction", "an Imperial pilot in a Havoc squadron: E4 precedes E5")
	lu.assertEquals(opens(W.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "wrong_faction", "E4 precedes the grounded gate")
	lu.assertEquals(opens(W.pilot({ pilot = "imperial", faction = "imperial", vrovelMissions = 0 })), "wrong_faction", "E4 precedes not_ready")
end

-- E5 (J3:4643)
-- AC-3
function TestEzkielGates:test_a_havoc_pilot_with_four_tier_3_skills_and_no_flag_opens_off_track_which_ends_and_offers_nothing()
	local player = W.pilot({ squadron = HAVOC_SQUADRON, missions = 4, t3 = 4, graduated = false })
	local t = W.talk(player)

	lu.assertEquals(W.ids(t), { "off_track" }, "Havoc pilot who finished Havoc tier 3 (the same _03 skills)")
	lu.assertTrue(t[1].stop, "off_track ends the conversation")
	lu.assertEquals(#t[1].options, 0, "off_track offers no reply: no duties exist for Ezkiel")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_3e7fb8a3", "'I appreciate your devotion to the Alliance...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E5: a Rebel pilot with no squadron, or in another squadron, is off track too; E5 precedes E6 to E8
-- AC-3
function TestEzkielGates:test_a_pilot_outside_the_vortex_squadron_opens_off_track_before_the_standing_and_ready_gates()
	lu.assertEquals(opens(W.pilot({ squadron = false })), "off_track", "no squadron")
	lu.assertEquals(opens(W.pilot({ squadron = HAVOC_SQUADRON, standing = -5 })), "off_track", "E5 precedes the grounded gate")
	lu.assertEquals(opens(W.pilot({ squadron = HAVOC_SQUADRON, vrovelMissions = 0 })), "off_track", "E5 precedes not_ready")
	lu.assertEquals(opens(W.pilot({ squadron = HAVOC_SQUADRON, active = W.M1[1] })), "off_track", "E5 precedes on_mission")
end

-- E6 (J3:4650, hardened FV-4/D-7)
-- AC-3
function TestEzkielGates:test_a_vortex_pilot_with_rebel_standing_minus_one_opens_grounded_and_the_walk_grants_nothing()
	local player = W.pilot({ standing = -1 })
	local before = snapshot(player)
	local t = W.talk(player)

	lu.assertEquals(W.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_74967449", "'I thought that we could trust you, %TU...'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(W.optionSids(t[1]), { "s_ceaea132" }, "the grounded chain opens with one reply")
	lu.assertFalse(t[1].stop, "grounded does not end")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local walked = W.talk(player, { "s_ceaea132" })

	lu.assertEquals(W.ids(walked), { "grounded", "grounded_aided" }, "the grounded walk")
	lu.assertTrue(walked[2].stop, "grounded_aided ends")
	lu.assertEquals(#walked[2].options, 0, "grounded_aided offers nothing")

	local after = snapshot(player)

	lu.assertEquals(after.state.status, before.state.status, "no status key written")
	lu.assertEquals(after.skills, before.skills, "no skill")
	lu.assertEquals(after.credits, before.credits, "no credits")
	lu.assertEquals(after.standing, -1, "standing unchanged")
	lu.assertEquals(after.flag, before.flag, "VORTEX_PILOT_KEY untouched")
end

-- E6: standing 0 is not negative; a Rebel pilot whose faction is not Rebel is grounded too (V2B D-7); E6 precedes E7 to E20
-- AC-3
function TestEzkielGates:test_standing_zero_is_not_grounded_a_non_rebel_faction_is_and_grounded_precedes_the_ready_and_mission_gates()
	lu.assertNotEquals(opens(W.pilot({ standing = 0 })), "grounded", "standing 0")
	lu.assertEquals(opens(W.pilot({ faction = "neutral" })), "grounded", "Rebel pilot of neutral faction")
	lu.assertEquals(opens(W.pilot({ standing = -1, vrovelMissions = 0 })), "grounded", "E6 precedes not_ready")
	lu.assertEquals(opens(W.pilot({ standing = -1, active = W.M2[1] })), "grounded", "E6 precedes on_mission")
	lu.assertEquals(opens(W.pilot({ standing = -1, missions = 1, state = "failed" })), "grounded", "E6 precedes the failure screens")
	lu.assertEquals(opens(W.rewardPilot(1, { standing = -1 })), "grounded", "E6 precedes the reward screens")
end

-- E7 (J3:4688, Q-B1 = A)
-- AC-3
function TestEzkielGates:test_a_vortex_pilot_whose_tier_2_is_not_complete_opens_not_ready_which_ends_without_replies()
	local t = W.talk(W.pilot({ vrovelMissions = 3 }))

	lu.assertEquals(W.ids(t), { "not_ready" }, "four _02 skills and the flag, Vrovel's M4 unpaid")
	lu.assertTrue(t[1].stop, "not_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_ready offers no reply")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_2750c5d9", "'You still have work to do, young one.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(W.pilot({ t2 = 3 })), "not_ready", "Vrovel's M4 paid but only three _02 skills")
	lu.assertEquals(opens(W.pilot({ t2 = 0 })), "not_ready", "no _02 skill")
	lu.assertEquals(opens(W.pilot({ graduated = false })), "not_ready", "four _02 skills, M4 paid, no VORTEX_PILOT_KEY")
	lu.assertEquals(opens(W.pilot({ vrovelMissions = 0 })), "not_ready", "no Vrovel mission paid")
end

-- E7: the ready check reads the vortex_mission_4:reward key of Vrovel's M4
-- AC-3
function TestEzkielGates:test_the_ready_gate_reads_vrovels_mission_4_reward_key()
	local player = W.pilot({ vrovelMissions = 3 })

	lu.assertEquals(opens(player), "not_ready", "reward key absent")
	H.setQuestStatus(player, W.TIER2_M4_REWARD, 1)
	lu.assertEquals(opens(player), "m1_offer", "the vortex_mission_4:reward key opens the first offer")
end

-- E7: any set flag value is ready (the testing values 1, 2 and 3)
-- AC-3
function TestEzkielGates:test_flag_values_1_2_and_3_are_all_ready_for_tier_3()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(W.pilot({ graduated = flag })), "m1_offer", "flag " .. flag .. ", tier 2 complete")
	end
end

-- E7 precedes E8 to E20
-- AC-3
function TestEzkielGates:test_not_ready_comes_before_on_mission_the_failures_and_the_offers()
	lu.assertEquals(opens(W.pilot({ vrovelMissions = 3, active = W.M1[1] })), "not_ready", "E7 precedes on_mission")
	lu.assertEquals(opens(W.pilot({ vrovelMissions = 3, state = "failed" })), "not_ready", "E7 precedes m1_failed")
	lu.assertEquals(opens(W.pilot({ vrovelMissions = 3, state = "won" })), "not_ready", "E7 precedes m1_reward")
end

-- E8 (J3:4694)
-- AC-3
function TestEzkielGates:test_a_pilot_flying_any_of_the_twenty_ezkiel_quests_opens_on_mission_which_ends_without_replies()
	for _, global in ipairs(W.GLOBALS) do
		H.reset()

		local t = W.talk(W.pilot({ active = global }))

		lu.assertEquals(W.ids(t), { "on_mission" }, global .. " active")
		lu.assertTrue(t[1].stop, "on_mission ends the conversation")
		lu.assertEquals(#t[1].options, 0, "on_mission offers no reply")
		lu.assertEquals(t[1].text, W.PREFIX .. "s_44fd681b", "'Wouldn't you rather be on your ship?...'")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- E8: a quest from another trainer in the datapad blocks too (SpaceHelpers:hasSpaceQuest)
-- AC-3
function TestEzkielGates:test_a_space_quest_of_another_trainer_in_the_datapad_opens_on_mission()
	lu.assertEquals(opens(W.pilot({ datapad = "story" })), "on_mission", "a story mission of another trainer in the datapad")
	lu.assertEquals(opens(W.pilot({ datapad = "duty" })), "on_mission", "a duty of another trainer in the datapad")
	lu.assertEquals(opens(W.pilot({ missions = 2, t3 = 2, datapad = "story" })), "on_mission", "between missions 2 and 3")
end

-- E8 precedes E9 to E20
-- AC-3
function TestEzkielGates:test_on_mission_comes_before_the_failures_the_rewards_and_the_offers()
	lu.assertEquals(opens(W.pilot({ state = "failed", active = W.M2[1] })), "on_mission", "mission 1 attempted and mission 2 running")
	lu.assertEquals(opens(W.pilot({ state = "active" })), "on_mission", "mission 1 running")
	lu.assertEquals(opens(W.rewardPilot(2, { active = W.M3[1] })), "on_mission", "a reward owed, another mission running")
end

-- E9 to E12: a mission attempted and neither won nor running opens its failure screen
-- AC-3, AC-5
for n = 1, 4 do
	TestEzkielGates["test_mission_" .. n .. "_attempted_and_not_won_opens_m" .. n .. "_failed"] = function()
		local player = W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" })

		lu.assertEquals(opens(player), "m" .. n .. "_failed", "mission " .. n .. " attempted, nothing complete or running")
	end

	-- AC-5: any chain member failed (a prefix of the chain complete, nothing running) is a failure, as is a head aborted from the datapad
	TestEzkielGates["test_mission_" .. n .. "_with_a_failed_chain_member_opens_m" .. n .. "_failed"] = function()
		for k = 0, #W.CHAINS[n] - 1 do
			H.reset()

			local player = W.pilot({ missions = n - 1, t3 = n - 1, partial = k })

			lu.assertEquals(opens(player), "m" .. n .. "_failed", "mission " .. n .. ": the first " .. k .. " quests complete, the next one failed")
		end
	end

	TestEzkielGates["test_mission_" .. n .. "_aborted_from_the_datapad_opens_m" .. n .. "_failed"] = function()
		local player = W.pilot({ missions = n - 1, t3 = n - 1 })
		local head = W.quest(W.HEADS[n])

		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")
		W.setState(player, W.HEADS[n], "active")
		lu.assertEquals(opens(player), "on_mission", "while it flies")
		head:abortQuest(player)
		lu.assertEquals(W.state(player, W.HEADS[n]), "none", "the abort ends the run")
		lu.assertEquals(opens(player), "m" .. n .. "_failed", "after the abort (abort is failure)")
	end
end

-- FV-6: the failures are checked in the order M1, M2, M3, M4
-- AC-3
function TestEzkielGates:test_the_failure_screens_come_in_the_order_m1_m2_m3_m4()
	local function openFor(attempted)
		local player = W.pilot({})

		for _, n in ipairs(attempted) do
			H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")
		end

		return opens(player)
	end

	lu.assertEquals(openFor({ 2, 3 }), "m2_failed", "2 before 3")
	lu.assertEquals(openFor({ 3, 1 }), "m1_failed", "1 before 3")
	lu.assertEquals(openFor({ 4, 1 }), "m1_failed", "1 before 4")
	lu.assertEquals(openFor({ 4, 3 }), "m3_failed", "3 before 4")
	lu.assertEquals(openFor({ 1, 2, 3, 4 }), "m1_failed", "1 first of all")
end

-- E9 to E12: a won mission is not failed, a running one is on_mission
-- AC-3, AC-5
function TestEzkielGates:test_attempted_and_won_is_not_failed_and_attempted_and_running_is_on_mission()
	lu.assertEquals(opens(W.pilot({ state = "won" })), "m1_reward", "attempted and won: the reward, not the failure")
	lu.assertEquals(opens(W.pilot({ state = "active" })), "on_mission", "attempted and running: E8 precedes E9")
end

-- E9 to E12 precede the rewards and the offers
-- AC-3
function TestEzkielGates:test_the_failure_screens_precede_the_reward_and_offer_screens()
	local player = W.pilot({ missions = 0, state = "won" })

	H.setQuestStatus(player, W.STATUS[2] .. ":attempted", "1")
	lu.assertEquals(opens(player), "m2_failed", "mission 1 won and unpaid, mission 2 attempted: E10 precedes E13")
end

-- E13 to E16
-- AC-3, AC-6
for n = 1, 4 do
	TestEzkielGates["test_mission_" .. n .. "_won_and_unpaid_with_fewer_than_" .. n .. "_skills_opens_m" .. n .. "_reward"] = function()
		lu.assertEquals(opens(W.rewardPilot(n)), "m" .. n .. "_reward", "mission " .. n .. " won, count " .. (n - 1))
	end

	-- the count rule: mission n paid with its skill unchosen reopens on the reward screen; no later offer comes first
	TestEzkielGates["test_mission_" .. n .. "_paid_with_its_skill_unchosen_still_opens_m" .. n .. "_reward_before_any_later_offer"] = function()
		local player = W.pilot({ missions = n, t3 = n - 1 })

		lu.assertEquals(opens(player), "m" .. n .. "_reward", "mission " .. n .. " paid, count " .. (n - 1))
	end
end

-- E13 to E16: the smallest owed mission first
-- AC-3
function TestEzkielGates:test_the_smallest_owed_reward_screen_comes_first()
	lu.assertEquals(opens(W.pilot({ missions = 2 })), "m1_reward", "missions 1 and 2 won and paid, no skill chosen")
	lu.assertEquals(opens(W.pilot({ missions = 2, t3 = 1 })), "m2_reward", "two won, one skill chosen")
end

-- E17 to E20, AC-4: mission n+1 is offered only after mission n's skill is chosen
-- AC-3, AC-4
for n = 0, 3 do
	TestEzkielGates["test_a_pilot_with_" .. n .. "_missions_won_and_" .. n .. "_skills_chosen_opens_m" .. (n + 1) .. "_offer"] = function()
		lu.assertEquals(opens(W.pilot({ missions = n, t3 = n })), "m" .. (n + 1) .. "_offer", n .. " missions paid, " .. n .. " skills")
	end
end

-- E17: a pilot with no tier 3 state at all
-- AC-3, AC-4
function TestEzkielGates:test_a_pilot_with_no_quest_state_opens_the_first_offer_and_the_walk_greets_him()
	local t = W.talk(W.pilot({}))

	lu.assertEquals(W.ids(t), { "m1_offer" }, "first screen")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_a285e391", "'%TU. Brother Vrovel says you can be trusted.'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E17 to E20: the offer lines (J3:4930, 4990, 5038, 5079) and the screens' names
-- AC-4
function TestEzkielGates:test_the_four_offers_show_the_j3_lines()
	local want = { "s_a285e391", "s_3f38ab04", "s_8287425f", "s_fffd9426" }

	for n = 1, 4 do
		H.reset()

		local t = W.talk(W.readyFor(n))

		lu.assertEquals(W.ids(t), { "m" .. n .. "_offer" }, "mission " .. n .. ": first screen")
		lu.assertEquals(t[1].text, W.PREFIX .. want[n], "mission " .. n .. ": the offer line")
	end
end

-- The session opens on the screen getInitialScreen picks (I-3)
-- AC-3
function TestEzkielGates:test_the_session_opens_on_the_screen_getInitialScreen_picks()
	lu.assertEquals(W.firstScreen(W.pilot({ missions = 2, t3 = 2 })), "m3_offer", "session start")
	lu.assertEquals(opens(W.pilot({ missions = 2, t3 = 2 })), "m3_offer", "getInitialScreen alone")
end

-- I-3: getInitialScreen changes nothing for the pilots of every row (the state is checked inside opens())
-- AC-3
function TestEzkielGates:test_getInitialScreen_is_pure_for_every_kind_of_pilot()
	local pilots = {
		W.nonPilot(), W.pilot({ missions = 4, t3 = 4, pilotTier = 3 }), W.pilot({ missions = 3, t3 = 4, state = "won", pilotTier = 3 }),
		W.pilot({ pilot = "imperial", faction = "imperial" }), W.pilot({ squadron = HAVOC_SQUADRON }), W.pilot({ standing = -1 }), W.pilot({ vrovelMissions = 3 }),
		W.pilot({ active = W.M3[3] }), W.pilot({ datapad = "story" }), W.pilot({ missions = 1, t3 = 1, state = "failed" }), W.pilot({ missions = 3, t3 = 3, state = "failed" }),
		W.rewardPilot(1), W.rewardPilot(4, { xp = 200000 }), W.pilot({ missions = 2, t3 = 2, inventory = { limit = 0 } }), W.pilot({}),
	}

	for i, player in ipairs(pilots) do
		opens(player)
		lu.assertTrue(i > 0, "pilot " .. i)
	end
end

-- AC-8, I-7: a graduate opening the conversation does not move VORTEX_PILOT_KEY, whatever its value
-- AC-3, AC-8
function TestEzkielGates:test_the_gates_never_write_the_vortex_pilot_key()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = W.pilot({ missions = 4, t3 = 4, graduated = flag })

		W.talk(player)
		W.talk(player, { "s_9ac7f904" })
		lu.assertEquals(W.flag(player), flag, "VORTEX_PILOT_KEY after two talks with flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- The helpers the spec names (Content contract 2)
---------------------------------------------------------------------------------------------

TestEzkielHelpers = {}

TestEzkielHelpers.setUp = setUp

-- Content contract 2: isWon is the chain end complete, isActive the chain running, isFailed attempted and neither, isPaid the :reward key
function TestEzkielHelpers:test_is_won_is_active_is_failed_and_is_paid_follow_the_chain_end_the_journal_and_the_keys()
	local h = handler()
	local fresh = W.pilot({})

	for n = 1, 4 do
		lu.assertFalse(h:isWon(fresh, n), "fresh: isWon " .. n)
		lu.assertFalse(h:isActive(fresh, n), "fresh: isActive " .. n)
		lu.assertFalse(h:isFailed(fresh, n), "fresh: isFailed " .. n)
		lu.assertFalse(h:isPaid(fresh, n), "fresh: isPaid " .. n)
	end

	lu.assertFalse(h:isOnMission(fresh), "fresh: isOnMission")

	local won = W.pilot({ missions = 2, t3 = 2 })

	lu.assertTrue(h:isWon(won, 1) and h:isWon(won, 2), "two missions won")
	lu.assertTrue(h:isPaid(won, 1) and h:isPaid(won, 2), "two missions paid")
	lu.assertFalse(h:isWon(won, 3) or h:isPaid(won, 3), "mission 3 neither")
	lu.assertFalse(h:isFailed(won, 1), "a won mission is not failed")

	for n = 1, 4 do
		local flying = W.pilot({ state = nil, active = W.CHAINS[n][3] })

		lu.assertTrue(h:isActive(flying, n), "a running member of chain " .. n .. ": isActive")
		lu.assertTrue(h:isOnMission(flying), "a running member of chain " .. n .. ": isOnMission")
		H.setQuestStatus(flying, W.STATUS[n] .. ":attempted", "1")
		lu.assertFalse(h:isFailed(flying, n), "attempted but running is not failed")
	end

	local failed = W.pilot({ state = "failed" })

	lu.assertTrue(h:isFailed(failed, 1), "attempted, not won, not running")
	lu.assertFalse(h:isWon(failed, 1), "failed is not won")
end

-- Content contract 2: getPilotFlag is the key value, or nil when unset or empty
function TestEzkielHelpers:test_get_pilot_flag_is_the_key_value_or_nil()
	local h = handler()

	lu.assertEquals(h:getPilotFlag(W.pilot({ graduated = "3" })), "3", "flag 3")
	lu.assertEquals(h:getPilotFlag(W.pilot({ graduated = "1" })), "1", "flag 1")
	lu.assertNil(h:getPilotFlag(W.pilot({ graduated = false })), "flag unset")

	local empty = W.pilot({ graduated = false })

	H.setQuestStatus(empty, W.VORTEX_PILOT_KEY, "")
	lu.assertNil(h:getPilotFlag(empty), "flag empty")
end

-- Content contract 2: isReadyForTier3 (Q-B1 = A) and isReadyForTier4
function TestEzkielHelpers:test_is_ready_for_tier_3_and_tier_4()
	local h = handler()

	lu.assertTrue(h:isReadyForTier3(W.pilot({})), "tier 2 complete, flag, Vrovel's M4 paid")
	lu.assertFalse(h:isReadyForTier3(W.pilot({ vrovelMissions = 3 })), "Vrovel's M4 unpaid")
	lu.assertFalse(h:isReadyForTier3(W.pilot({ t2 = 3 })), "three _02 skills")
	lu.assertFalse(h:isReadyForTier3(W.pilot({ graduated = false })), "no flag")
	lu.assertTrue(h:isReadyForTier4(W.pilot({ missions = 4, t3 = 4 })), "four _03 skills, flag, M4 paid")
	lu.assertFalse(h:isReadyForTier4(W.pilot({ missions = 3, t3 = 4, state = "won" })), "M4 won and unpaid")
	lu.assertFalse(h:isReadyForTier4(W.pilot({ missions = 4, t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:isReadyForTier4(W.pilot({ missions = 4, t3 = 4, graduated = false })), "no flag")
end

-- Content contract 2: getRewardMission is the smallest n with n won and fewer than n _03 skills; 4 also while M4 is won and unpaid; nil otherwise
function TestEzkielHelpers:test_get_reward_mission_is_the_smallest_won_mission_with_fewer_skills_than_its_number()
	local h = handler()

	lu.assertNil(h:getRewardMission(W.pilot({})), "nothing won")
	lu.assertEquals(h:getRewardMission(W.rewardPilot(1)), 1, "mission 1 won, no skill")
	lu.assertEquals(h:getRewardMission(W.rewardPilot(3)), 3, "mission 3 won, two skills")
	lu.assertNil(h:getRewardMission(W.pilot({ missions = 1, t3 = 1 })), "mission 1 won and its skill chosen")
	lu.assertEquals(h:getRewardMission(W.pilot({ missions = 3, t3 = 4, state = "won" })), 4, "mission 4 won and unpaid with four skills")
	lu.assertNil(h:getRewardMission(W.pilot({ missions = 4, t3 = 4 })), "four paid, four skills")
end
