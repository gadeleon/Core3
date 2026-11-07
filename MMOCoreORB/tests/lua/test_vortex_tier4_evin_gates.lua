-- Brother Extok Evin: which screen a pilot opens on (gate table E), the refusal walks, the Q-B1/Q-B2 ordering, the J4 won/failed rules and purity.
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (AC-3; Conversation flow 1; FE-3, FE-4; D-3, D-8, D-9; I-3, I-7, I-8; user answers Q-B1 = A, Q-B2 = A).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is vortex_tier4_data.lua E.pilot (a Vortex pilot of tier 3,
-- four _03 skills, VORTEX_PILOT_KEY "3", Ezkiel's four missions paid, pilot tier 4; options flag, ezkielM4Paid, t3, t4, met, mission, paid, master, squadron, otherQuest, xp,
-- standing, faction, pilot, duty, evinActive). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local E = require("vortex_tier4_data")
local CS = require("harness.client_strings")

E.loadConversation()

local XP = E.TRAIN_COST

local function handler() return rawget(_G, E.HANDLER) end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-3 for this pilot
local function opens(player)
	local before = E.snapshot(player)
	local pScreen = handler():getInitialScreen(player, E.npc(), H.conversationTemplate(E.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(E.snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-3)")
	return first
end

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

-- the first n skills, and the missions 1..n-1 paid
local function skills(n)
	local out = {}

	for i = 1, n do
		out[i] = i
	end

	return out
end

TestEvinGates = {}

TestEvinGates.setUp = setUp

-- E0
-- AC-3
function TestEvinGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = E.pilot(), E.npc(), H.conversationTemplate(E.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
	lu.assertNil(handler():gateScreenId(nil), "gateScreenId of no player")
end

-- E1
-- AC-3
function TestEvinGates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(E.pilot({ met = true })), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = E.pilot({ met = true })

	player.ghost = nil
	lu.assertEquals(E.firstScreen(player), "not_pilot", "ghost is nil")
end

-- E2 (J4:4491)
-- AC-3
function TestEvinGates:test_a_non_pilot_opens_not_pilot_with_two_replies_that_both_end_on_off_limits()
	local t = E.talk(E.nonPilot())

	lu.assertEquals(E.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_3daae2ee", "'Do I know you?'")
	lu.assertEquals(E.optionSids(t[1]), { "s_b3218dae", "s_4c695dbd" }, "the two replies")
	lu.assertEquals(E.linksOf(t[1]), { "off_limits", "off_limits" }, "both lead to the refusal")
	lu.assertFalse(t[1].stop, "not_pilot waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	for _, reply in ipairs({ "s_b3218dae", "s_4c695dbd" }) do
		local walked = E.talk(E.nonPilot(), { reply })

		lu.assertEquals(E.ids(walked), { "not_pilot", "off_limits" }, "reply " .. reply)
		lu.assertEquals(walked[2].text, E.PREFIX .. "s_8fc2022a", "'This area is off-limits for unsecured personnel.'")
		lu.assertTrue(walked[2].stop, "off_limits ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(walked), {}, "client strings")
	end
end

-- E2 precedes every other row (J4 checks isPilot first)
-- AC-3
function TestEvinGates:test_not_pilot_precedes_the_faction_standing_and_ready_gates()
	lu.assertEquals(opens(E.nonPilot({ faction = "neutral" })), "not_pilot", "plain non-pilot without a faction")
	lu.assertEquals(opens(E.nonPilot({ standing = -5 })), "not_pilot", "E2 precedes the grounded gate")
	lu.assertEquals(opens(E.pilot({ pilot = false, met = true })), "not_pilot", "four _03 skills, the flag and Ezkiel's M4 paid, but no pilot: E2 precedes E3")
end

-- E3 (J4:4532; Data mapping 2)
-- AC-3
function TestEvinGates:test_an_imperial_pilot_and_a_freelance_pilot_open_wrong_faction_whose_replies_end_on_off_limits()
	local imperial = E.talk(E.pilot({ pilot = "imperial", faction = "imperial", met = true }))

	lu.assertEquals(E.ids(imperial), { "wrong_faction" }, "Imperial pilot")
	lu.assertEquals(imperial[1].text, E.PREFIX .. "s_3daae2ee", "'Do I know you?'")
	lu.assertEquals(E.linksOf(imperial[1]), { "off_limits", "off_limits" }, "both replies lead to the refusal")
	lu.assertFalse(imperial[1].stop, "wrong_faction waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(imperial), {}, "client strings")

	local freelance = E.talk(E.pilot({ pilot = "neutral", faction = "neutral", squadron = "none", met = true }), { "s_b3218dae" })

	lu.assertEquals(E.ids(freelance), { "wrong_faction", "off_limits" }, "freelance pilot, first reply")
	lu.assertTrue(freelance[2].stop, "off_limits ends")

	local other = E.talk(E.pilot({ pilot = "imperial", faction = "imperial", met = true }), { "s_4c695dbd" })

	lu.assertEquals(E.ids(other), { "wrong_faction", "off_limits" }, "Imperial pilot, second reply")
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "rebel", met = true })), "wrong_faction", "Imperial pilot skills with Rebel faction")
	lu.assertEquals(opens(E.pilot({ pilot = "neutral", faction = "rebel", squadron = "none", met = true })), "wrong_faction", "freelance pilot with Rebel faction")
end

-- E3 precedes E4 to E24
-- AC-3
function TestEvinGates:test_wrong_faction_comes_before_the_grounded_track_ready_and_mission_gates()
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", squadron = "havoc", met = true })), "wrong_faction", "an Imperial pilot in a Havoc squadron: E3 precedes E5")
	lu.assertEquals(opens(E.pilot({ pilot = "neutral", squadron = "none", standing = -50, met = true })), "wrong_faction", "E3 precedes the grounded gate")
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", ezkielM4Paid = false })), "wrong_faction", "E3 precedes not_ready")
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", mission = { [1] = "active" } })), "wrong_faction", "E3 precedes on_mission")
end

-- E4 (J4:4573, widened by D-8)
-- AC-3
function TestEvinGates:test_a_vortex_pilot_with_rebel_standing_minus_one_opens_grounded_and_the_walk_grants_nothing()
	local player = E.pilot({ standing = -1, met = true })
	local before = E.snapshot(player)
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_2f2320af", "'What are you, %NU, some kind of double agent?'")
	lu.assertEquals(t[1].params.TU, "Ace", "the first name")
	lu.assertEquals(E.optionSids(t[1]), { "s_457a7010" }, "the grounded chain opens with one reply")
	lu.assertFalse(t[1].stop, "grounded does not end")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local walked = E.talk(player, { "s_457a7010", "s_c7932482" })

	lu.assertEquals(E.ids(walked), { "grounded", "grounded_8a64732d", "grounded_6b14c8d" }, "the grounded walk")
	lu.assertTrue(walked[3].stop, "grounded_6b14c8d ends")
	lu.assertEquals(#walked[3].options, 0, "grounded_6b14c8d offers nothing")
	lu.assertEquals(CS.transcriptUnresolved(walked), {}, "client strings")

	local after = E.snapshot(player)

	lu.assertEquals(after.status, before.status, "no status key written")
	lu.assertEquals(after.skills, before.skills, "no skill")
	lu.assertEquals(after.credits, before.credits, "no credits")
	lu.assertEquals(after.standing, -1, "standing unchanged")
	lu.assertEquals(after.flag, before.flag, "VORTEX_PILOT_KEY untouched")
end

-- E4: standing 0 is not negative; a Rebel pilot whose faction is not Rebel is grounded too (D-8); a grounded Havoc pilot is grounded, not off track (FE-4); E4 precedes E5 to E24
-- AC-3
function TestEvinGates:test_standing_zero_is_not_grounded_a_non_rebel_faction_is_and_grounded_precedes_the_track_ready_and_mission_gates()
	lu.assertNotEquals(opens(E.pilot({ standing = 0, met = true })), "grounded", "standing 0")
	lu.assertEquals(opens(E.pilot({ faction = "neutral", met = true })), "grounded", "Rebel pilot of neutral faction")
	lu.assertEquals(opens(E.pilot({ faction = "imperial", met = true })), "grounded", "Rebel pilot of Imperial faction")
	lu.assertEquals(opens(E.pilot({ standing = -1, squadron = "havoc", met = true })), "grounded", "a grounded Havoc pilot: E4 precedes E5 (FE-4)")
	lu.assertEquals(opens(E.pilot({ standing = -1, squadron = "none", met = true })), "grounded", "no squadron")
	lu.assertEquals(opens(E.pilot({ standing = -1, ezkielM4Paid = false })), "grounded", "E4 precedes not_ready")
	lu.assertEquals(opens(E.pilot({ standing = -1, mission = { [1] = "active" }, met = true })), "grounded", "E4 precedes on_mission")
	lu.assertEquals(opens(E.pilot({ standing = -1, mission = { [1] = "failed_head" }, met = true })), "grounded", "E4 precedes the failure screens")
	lu.assertEquals(opens(E.rewardPilot(1, "won_a", { standing = -1 })), "grounded", "E4 precedes the reward screens")
	lu.assertEquals(opens(E.pilot({ standing = -1 })), "grounded", "E4 precedes the first meeting")
end

-- E5 (J4:4611)
-- AC-3
function TestEvinGates:test_a_havoc_pilot_with_four_tier_3_skills_or_four_tier_4_skills_opens_off_track()
	local three = E.talk(E.pilot({ squadron = "havoc", met = true }))

	lu.assertEquals(E.ids(three), { "off_track" }, "a Havoc pilot with four _03 skills")
	lu.assertEquals(three[1].text, E.PREFIX .. "s_8cd97e8b", "'You're a Rebel pilot? But you're not part of this unit. Are you lost?'")
	lu.assertEquals(E.optionSids(three[1]), { "s_dab8fd8e" }, "the one reply (C-2)")
	lu.assertFalse(three[1].stop, "off_track waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(three), {}, "client strings")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })), "off_track", "a Havoc pilot with four _04 skills")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, master = true })), "off_track", "a Havoc pilot with the master skill")
end

-- E5: a Rebel pilot with no squadron, or in another squadron, is off track too; E5 precedes E6 to E24
-- AC-3
function TestEvinGates:test_a_pilot_outside_the_vortex_squadron_opens_off_track_before_the_ready_and_mission_gates()
	lu.assertEquals(opens(E.pilot({ squadron = "none" })), "off_track", "no squadron")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", ezkielM4Paid = false })), "off_track", "E5 precedes not_ready")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", mission = { [1] = "active" } })), "off_track", "E5 precedes on_mission")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", otherQuest = "story" })), "off_track", "E5 precedes on_mission (a datapad mission)")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", mission = { [1] = "failed_head" } })), "off_track", "E5 precedes the failure screens")
	lu.assertEquals(opens(E.rewardPilot(1, "won_a", { squadron = "havoc" })), "off_track", "E5 precedes the reward screens")
end

-- E6 (J4:4640; Q-B1 = A)
-- AC-3
function TestEvinGates:test_a_vortex_pilot_whose_tier_3_is_not_complete_opens_not_ready_with_two_replies_that_end()
	local t = E.talk(E.pilot({ ezkielM4Paid = false }))

	lu.assertEquals(E.ids(t), { "not_ready" }, "four _03 skills and the flag, Ezkiel's M4 unpaid")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_243a81bd", "'Ezkiel is still in need of your services.'")
	lu.assertEquals(E.optionSids(t[1]), { "s_c2d98904", "s_13f3baf7" }, "the two replies")
	lu.assertEquals(E.linksOf(t[1]), { "not_ready_dismissed", "not_ready_contact" }, "the two endings")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	for i, reply in ipairs({ "s_c2d98904", "s_13f3baf7" }) do
		local walked = E.talk(E.pilot({ ezkielM4Paid = false }), { reply })

		lu.assertEquals(E.ids(walked), { "not_ready", i == 1 and "not_ready_dismissed" or "not_ready_contact" }, "reply " .. reply)
		lu.assertTrue(walked[2].stop, "the ending ends")
	end

	lu.assertEquals(opens(E.pilot({ flag = false })), "not_ready", "four _03 skills, Ezkiel's M4 paid, no VORTEX_PILOT_KEY")
	lu.assertEquals(opens(E.pilot({ t3 = 3 })), "not_ready", "Ezkiel's M4 paid but only three _03 skills")
	lu.assertEquals(opens(E.pilot({ t3 = 0, missions = 0 })), "not_ready", "no _03 skill")
end

-- E6: the ready check reads Ezkiel's naboo_rebel_tier3_4:reward key (Q-B1 = A)
-- AC-3, AC-9
function TestEvinGates:test_the_ready_gate_reads_ezkiels_mission_4_reward_key()
	local player = E.pilot({ ezkielM4Paid = false })

	lu.assertEquals(opens(player), "not_ready", "reward key absent")
	H.setQuestStatus(player, "naboo_rebel_tier3_4:reward", "1")
	lu.assertEquals(opens(player), "intro", "the naboo_rebel_tier3_4:reward key opens the first meeting")
end

-- E6: any set flag value is ready (the values 1, 2 and 3: Q-B1 = A "set (any value)")
-- AC-3, AC-9
function TestEvinGates:test_flag_values_1_2_and_3_are_all_ready_for_tier_4()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(E.pilot({ flag = flag })), "intro", "flag " .. flag)
	end
end

-- E6 precedes E7 to E24
-- AC-3
function TestEvinGates:test_not_ready_comes_before_on_mission_the_failures_the_rewards_the_meeting_and_the_offers()
	lu.assertEquals(opens(E.pilot({ ezkielM4Paid = false, mission = { [1] = "active" } })), "not_ready", "E6 precedes on_mission")
	lu.assertEquals(opens(E.pilot({ ezkielM4Paid = false, mission = { [1] = "failed_head" } })), "not_ready", "E6 precedes m1_failed")
	lu.assertEquals(opens(E.pilot({ ezkielM4Paid = false, mission = { [1] = "won_a" } })), "not_ready", "E6 precedes m1_reward")
	lu.assertEquals(opens(E.pilot({ ezkielM4Paid = false, met = true, t4 = { 1 } })), "not_ready", "E6 precedes the offers")
	lu.assertEquals(opens(E.pilot({ ezkielM4Paid = false, met = true, xp = XP })), "not_ready", "E6 precedes the training")
end

-- E7 (J4:4680): any chain member of any mission, 2_c included
-- AC-3
function TestEvinGates:test_a_pilot_flying_any_of_the_thirteen_story_quests_opens_on_mission_which_ends_with_two_replies()
	for n, chain in ipairs(E.CHAINS) do
		for _, global in ipairs(chain) do
			H.reset()

			local t = E.talk(E.pilot({ met = true, evinActive = global }))

			lu.assertEquals(E.ids(t), { "on_mission" }, "mission " .. n .. ": " .. global .. " active")
			lu.assertEquals(t[1].text, E.PREFIX .. "s_e59caef0", "'You've received your orders.'")
			lu.assertEquals(E.optionSids(t[1]), { "s_d92f71f", "s_9b43a7ee" }, "the two replies")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	local walked = E.talk(E.pilot({ met = true, evinActive = E.M1[1] }), { "s_d92f71f" })

	lu.assertEquals(E.ids(walked), { "on_mission", "on_mission_481965b0" }, "first reply")
	lu.assertTrue(walked[2].stop, "on_mission_481965b0 ends")

	local second = E.talk(E.pilot({ met = true, evinActive = E.M1[1] }), { "s_9b43a7ee" })

	lu.assertEquals(E.ids(second), { "on_mission", "on_mission_49707203" }, "second reply")
	lu.assertTrue(second[2].stop, "on_mission_49707203 ends")
end

-- E7: any of the four Evin duties running (a duty has no :attempted key)
-- AC-3
function TestEvinGates:test_a_pilot_flying_any_of_the_four_evin_duties_opens_on_mission()
	for k, global in ipairs(E.DUTIES) do
		H.reset()
		lu.assertEquals(opens(E.pilot({ met = true, duty = global })), "on_mission", "duty " .. k .. " (" .. global .. ") active")
	end
end

-- E7: a quest from another trainer in the datapad blocks too (SpaceHelpers:hasSpaceQuest)
-- AC-3
function TestEvinGates:test_a_space_quest_of_another_trainer_in_the_datapad_opens_on_mission()
	lu.assertEquals(opens(E.pilot({ met = true, otherQuest = "story" })), "on_mission", "a story mission of another trainer in the datapad")
	lu.assertEquals(opens(E.pilot({ met = true, otherQuest = "duty" })), "on_mission", "a duty of another trainer in the datapad")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1 }, paid = {}, otherQuest = "story" })), "on_mission", "with a skill waiting for its mission")
	lu.assertEquals(opens(E.pilot({ otherQuest = "story" })), "on_mission", "before the first meeting: E7 precedes E12")
end

-- E7 precedes E8 to E24
-- AC-3
function TestEvinGates:test_on_mission_comes_before_the_failures_the_rewards_the_meeting_and_the_offers()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "failed_head" }, duty = E.DUTIES[1] })), "on_mission", "mission 2 attempted and a duty running")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1 }, mission = { [1] = "active" } })), "on_mission", "mission 1 running")
	lu.assertEquals(opens(E.rewardPilot(2, "won_a", { evinActive = E.M3[1] })), "on_mission", "a reward owed, another mission running")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, mission = { [1] = "active" }, xp = XP })), "on_mission", "before the first meeting: E7 precedes E12")
end

-- E8 to E11: a mission attempted and neither won nor running opens its failure screen, for every failure outcome of I-8
-- AC-3, AC-6
for n = 1, 4 do
	for _, state in ipairs({ "failed_head", "aborted", "failed_a", "failed_b" }) do
		TestEvinGates["test_mission_" .. n .. "_" .. state .. "_opens_m" .. n .. "_failed"] = function()
			local t = E.talk(E.rewardPilot(n, state))

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed" }, "mission " .. n .. " " .. state)
			lu.assertFalse(t[1].stop, "m" .. n .. "_failed waits for a reply")
			lu.assertEquals(#t[1].options, 2, "m" .. n .. "_failed: two replies")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-6: a head aborted from the datapad (the real abortQuest) is a failure too
	TestEvinGates["test_mission_" .. n .. "_aborted_from_the_datapad_opens_m" .. n .. "_failed"] = function()
		local player = E.rewardPilot(n, "active")

		lu.assertEquals(opens(player), "on_mission", "while it flies")
		E.quest(E.HEADS[n]):abortQuest(player)
		lu.assertEquals(E.state(player, E.HEADS[n]), "none", "the abort ends the run")
		lu.assertEquals(opens(player), "m" .. n .. "_failed", "after the abort (abort is failure)")
	end
end

-- E8 to E11: the failure screens' lines (J4:4720-4842)
-- AC-3
function TestEvinGates:test_the_four_failure_screens_show_the_j4_lines()
	local want = {
		{ "s_e8a5b38", "m1_retry_c8592539", "m1_retry_4a835de4" }, { "s_4e4d6d23", "m2_retry_80803e51", "m2_retry_13010c2d" },
		{ "s_d9bfbc18", "m3_retry_34a99b58", "m3_retry_84f5730a" }, { "s_82450216", "m4_retry_3de94b24", "m4_retry_be8a1d81" },
	}

	for n = 1, 4 do
		H.reset()

		local t = E.talk(E.rewardPilot(n, "failed_head"))

		lu.assertEquals(t[1].text, E.PREFIX .. want[n][1], "mission " .. n .. ": the failure line")
		lu.assertEquals(E.linksOf(t[1]), { want[n][2], want[n][3] }, "mission " .. n .. ": the retry screens")
	end
end

-- FE-6: the failures are checked in the order M1, M2, M3, M4
-- AC-3
function TestEvinGates:test_the_failure_screens_come_in_the_order_m1_m2_m3_m4()
	local function openFor(attempted)
		local player = E.pilot({ met = true, t4 = { 1, 2, 3, 4 } })

		for _, n in ipairs(attempted) do
			H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		end

		return opens(player)
	end

	lu.assertEquals(openFor({ 2, 3 }), "m2_failed", "2 before 3")
	lu.assertEquals(openFor({ 3, 1 }), "m1_failed", "1 before 3")
	lu.assertEquals(openFor({ 4, 1 }), "m1_failed", "1 before 4")
	lu.assertEquals(openFor({ 4, 3 }), "m3_failed", "3 before 4")
	lu.assertEquals(openFor({ 1, 2, 3, 4 }), "m1_failed", "1 first of all")
end

-- E8 to E11 precede the first meeting, the rewards and the offers (the table's order; before a first meeting no failure is possible, so only the order is pinned)
-- AC-3
function TestEvinGates:test_the_failure_screens_precede_the_meeting_the_reward_and_offer_screens()
	lu.assertEquals(opens(E.pilot({ mission = { [1] = "failed_head" } })), "m1_failed", "a failure before the first meeting: E8 precedes E12")

	local player = E.pilot({ met = true, t4 = { 1, 2 }, paid = {}, mission = { [1] = "won_a" } })

	H.setQuestStatus(player, E.STATUS[2] .. ":attempted", "1")
	lu.assertEquals(opens(player), "m2_failed", "mission 1 won and unpaid, mission 2 attempted: E9 precedes E13")
end

-- E8 to E11: a won mission is not failed, a running one is on_mission
-- AC-3, AC-6
function TestEvinGates:test_attempted_and_won_is_not_failed_and_attempted_and_running_is_on_mission()
	lu.assertEquals(opens(E.rewardPilot(1, "won_a")), "m1_reward", "attempted and won through the success child: the reward, not the failure")
	lu.assertEquals(opens(E.rewardPilot(1, "won_b")), "m1_reward", "attempted and won through the failure child")
	lu.assertEquals(opens(E.rewardPilot(1, "active")), "on_mission", "attempted and running: E7 precedes E8")
end

-- E12 (J4:5258, moved by Q-B2 = A): a ready pilot without the met key opens the first meeting, whatever the XP
-- AC-3
function TestEvinGates:test_a_ready_pilot_without_the_met_key_opens_intro_with_no_xp_and_with_two_million()
	local t = E.talk(E.pilot({}))

	lu.assertEquals(E.ids(t), { "intro" }, "no XP")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_52ea3d5c", "'Well, hey! There you are! Welcome, welcome...'")
	lu.assertEquals(E.optionSids(t[1]), { "s_4265144c" }, "the one reply")
	lu.assertEquals(E.linksOf(t[1]), { E.MET_SCREEN }, "it leads to the line that sets the met key")
	lu.assertFalse(t[1].stop, "intro waits for the reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.pilot({ xp = 2 * XP })), "intro", "2,000,000 XP: the meeting comes before the training (Q-B2 = A)")
	lu.assertEquals(opens(E.pilot({ xp = XP })), "intro", "1,000,000 XP")
end

-- E12 precedes E13 to E24 (Q-B2 = A): rewards, offers and training wait for the first meeting
-- AC-3
function TestEvinGates:test_the_first_meeting_comes_before_the_rewards_the_offers_and_the_training()
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, mission = { [1] = "won_a" } })), "intro", "M1 won and unpaid, no met key: E12 precedes E13")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 } })), "intro", "one skill, no met key: E12 precedes E17")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, paid = { 1 }, xp = XP })), "intro", "M1 paid, 1,000,000 XP, no met key: E12 precedes E21")
	lu.assertEquals(opens(E.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })), "intro", "a graduate who never met Evin: E12 precedes E23")
	lu.assertEquals(opens(E.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, master = true })), "intro", "with the master skill: E12 precedes E24")
end

-- E12: Ezkiel's graduate (four _03 skills, flag, M4 paid) opens intro, never not_ready (AC-9, Q-B1 = A)
-- AC-3, AC-9
function TestEvinGates:test_ezkiels_tier_done_pilot_opens_intro()
	lu.assertEquals(opens(E.pilot({ flag = "3", t3 = 4, ezkielM4Paid = true, pilotTier = 4 })), "intro", "tier 3 graduate")
	lu.assertEquals(opens(E.pilot({ pilotTier = 3 })), "intro", "tier 3 graduate left at pilot tier 3")
end

-- E13 to E16 (J4:4883-5016): "won" is either first-level child complete, whatever the head did; M2 pays on 2_b whatever 2_c does
-- AC-3, AC-7
for n = 1, 4 do
	for _, via in ipairs({ "won_a", "won_b" }) do
		TestEvinGates["test_mission_" .. n .. "_" .. via .. "_and_unpaid_opens_m" .. n .. "_reward"] = function()
			local t = E.talk(E.rewardPilot(n, via, {}))

			lu.assertEquals(E.ids(t), { "m" .. n .. "_reward" }, "mission " .. n .. " " .. via)
			lu.assertEquals(#t[1].options, 2, "m" .. n .. "_reward: two replies")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- E14: J4 never reads 2_c: a won 2_b opens the reward whatever Uvqolo in Dathomir did; while 2_c runs, the pilot is on a mission (D-3)
-- AC-3, AC-7
function TestEvinGates:test_mission_2_with_the_surprise_attack_won_opens_the_reward_whatever_2_c_did()
	lu.assertEquals(opens(E.rewardPilot(2, "won_b_c_failed")), "m2_reward", "2_b won, 2_c failed")
	lu.assertEquals(opens(E.rewardPilot(2, "won_b_c_won")), "m2_reward", "2_b won, 2_c won")
	lu.assertEquals(opens(E.rewardPilot(2, "c_active")), "on_mission", "2_b won, 2_c running: E7 precedes E14")
end

-- E13 to E16: the smallest owed mission first; a paid mission is not owed
-- AC-3
function TestEvinGates:test_the_smallest_owed_reward_screen_comes_first_and_a_paid_mission_is_not_owed()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, mission = { [1] = "won_a", [2] = "won_a" } })), "m1_reward", "missions 1 and 2 won and unpaid")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "won_a" } })), "m2_reward", "mission 1 paid, mission 2 won and unpaid")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = { 1 }, paid = { 1 } })), "m1_reward", "a paid mission opens no reward")
end

-- E13 to E16 precede the offers and the training (J4 order): a won mission is paid before anything else
-- AC-3
function TestEvinGates:test_a_reward_owed_comes_before_the_offers_and_the_training()
	lu.assertEquals(opens(E.rewardPilot(1, "won_a", { xp = 2 * XP })), "m1_reward", "one skill, M1 won and unpaid, XP for training")
	lu.assertEquals(opens(E.rewardPilot(4, "won_a", { xp = 2 * XP })), "m4_reward", "four skills, M4 won and unpaid: the reward before the transfer")
end

-- E17 to E20 (J4:5058-5180): mission n is offered with n skills and mission n unpaid; the offer comes before the training
-- AC-3, AC-5
for n = 1, 4 do
	TestEvinGates["test_a_pilot_with_" .. n .. "_tier_4_skills_and_missions_before_paid_opens_m" .. n .. "_offer"] = function()
		local t = E.talk(E.offerPilot(n))

		lu.assertEquals(E.ids(t), { "m" .. n .. "_offer" }, n .. " skills, missions 1.." .. (n - 1) .. " paid")
		lu.assertEquals(#t[1].options, 2, "m" .. n .. "_offer: two replies")
		lu.assertFalse(t[1].stop, "the offer waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(opens(E.offerPilot(n, { xp = 2 * XP })), "m" .. n .. "_offer", "the offer comes before the training (J4 order)")
	end
end

-- E17 to E20: the offer lines (J4:5183, 5142, 5101, 5061)
-- AC-3, AC-5
function TestEvinGates:test_the_four_offers_show_the_j4_lines()
	local want = { "s_4975777", "s_41e4adff", "s_fc2f8c4c", "s_4a858e06" }

	for n = 1, 4 do
		H.reset()

		local t = E.talk(E.offerPilot(n))

		lu.assertEquals(t[1].text, E.PREFIX .. want[n], "mission " .. n .. ": the offer line")
	end
end

-- E17 to E20: n skills held and mission n unpaid, with the earlier missions paid; mission 1 needs at least one skill
-- AC-3, AC-5
function TestEvinGates:test_mission_n_is_offered_only_with_n_skills_and_mission_1_with_at_least_one()
	lu.assertNotEquals(opens(E.offerPilot(2, { t4 = { 1 }, paid = { 1 } })), "m2_offer", "one skill: mission 2 is not offered")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 1 } })), "m2_offer", "three skills: mission 2 is not offered")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 2, 3 } })), "m1_offer", "n = 1: at least one skill and mission 1 unpaid")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = {}, paid = {} })), "m1_offer", "no skill: mission 1 is not offered")
	lu.assertNotEquals(opens(E.offerPilot(3, { paid = { 1, 2, 3 } })), "m3_offer", "mission 3 paid: not offered again")
end

-- E21 (J4:5229): the training; the skill waits for no mission
-- AC-3, AC-8
function TestEvinGates:test_a_ready_pilot_with_no_skill_and_1000000_xp_or_one_skill_with_its_mission_paid_opens_training()
	local t = E.talk(E.pilot({ met = true, xp = XP }))

	lu.assertEquals(E.ids(t), { "training" }, "no skill, 1,000,000 XP, the meeting heard")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_5dbf1a94", "'Congratulations! You've earned the right to acquire a new skill...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.trainee({ 1 })), "training", "one skill, M1 paid, 1,000,000 XP")
	lu.assertEquals(opens(E.trainee({ 1, 2 })), "training", "two skills, M1 and M2 paid, 1,000,000 XP")
	lu.assertEquals(opens(E.trainee({ 1, 2, 3 })), "training", "three skills, M1 to M3 paid, 1,000,000 XP")
end

-- E22 (J4:5287): under 1,000,000 XP the training is not open: the duty menu
-- AC-3
function TestEvinGates:test_a_ready_pilot_with_999999_xp_opens_tier4_incomplete_with_the_duty_menu()
	local t = E.talk(E.trainee({ 1 }, XP - 1))

	lu.assertEquals(E.ids(t), { "tier4_incomplete" }, "one skill, M1 paid, 999,999 XP")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_70814158", "'Here comes our pilot now! Are you ready to accept a duty mission?'")
	lu.assertEquals(E.optionSids(t[1]), E.MENU_REPLIES, "the duty menu")
	lu.assertEquals(E.linksOf(t[1]), E.MENU_LINKS, "the four duties and the briefing again")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.pilot({ met = true, xp = XP - 1 })), "tier4_incomplete", "no skill, 999,999 XP")
	lu.assertEquals(opens(E.pilot({ met = true })), "tier4_incomplete", "no skill, no XP")
end

-- E23 (J4:5361): four skills and no master skill: the Burke transfer, on every talk
-- AC-3, AC-9
function TestEvinGates:test_four_tier_4_skills_with_mission_4_paid_open_transfer_on_every_talk()
	for talk = 1, 3 do
		local t = E.talk(E.graduate())

		lu.assertEquals(E.ids(t), { "transfer" }, "talk " .. talk)
		lu.assertEquals(t[1].text, E.PREFIX .. "s_75c90fe4", "'Good to see you again. I have some great news...'")
		lu.assertEquals(E.optionSids(t[1]), { "s_a65d4a43", "s_fcbee9cd" }, "the two questions")
		lu.assertFalse(t[1].stop, "the transfer waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- E23: a pilot with four skills and mission 4 unpaid is held before the transfer (E7, E11, E16 or E17)
-- AC-3
function TestEvinGates:test_four_skills_with_mission_4_unpaid_are_held_before_the_transfer()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 } })), "m4_offer", "not yet flown: the offer (E17)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "flying (E7)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "failed_head" } })), "m4_failed", "failed (E11)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won_a" } })), "m4_reward", "won, unpaid (E16)")
end

-- E24 (J4:5403): the master skill: the greeting and the duty menu
-- AC-3, AC-9
function TestEvinGates:test_a_pilot_with_the_master_skill_opens_here_for_work_with_the_duty_menu()
	local t = E.talk(E.graduate({ master = true }))

	lu.assertEquals(E.ids(t), { "here_for_work" }, "master skill")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_fc615cb9", "'I see you have survived your experience with Admiral Burke...'")
	lu.assertEquals(E.optionSids(t[1]), E.MENU_REPLIES, "the duty menu")
	lu.assertEquals(E.linksOf(t[1]), E.MENU_LINKS, "the four duties and the briefing again")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- The session opens on the screen getInitialScreen picks (I-3)
-- AC-3
function TestEvinGates:test_the_session_opens_on_the_screen_getInitialScreen_picks()
	lu.assertEquals(E.firstScreen(E.offerPilot(3)), "m3_offer", "session start")
	lu.assertEquals(opens(E.offerPilot(3)), "m3_offer", "getInitialScreen alone")
end

-- gateScreenId is the pure function behind getInitialScreen (Content contract 2)
-- AC-3
function TestEvinGates:test_gate_screen_id_names_the_screen_getInitialScreen_opens_for_every_row()
	local pilots = {
		{ E.nonPilot(), "not_pilot" }, { E.pilot({ pilot = "imperial", faction = "imperial" }), "wrong_faction" }, { E.pilot({ standing = -1 }), "grounded" },
		{ E.pilot({ squadron = "havoc" }), "off_track" }, { E.pilot({ ezkielM4Paid = false }), "not_ready" }, { E.pilot({ evinActive = E.M1[1] }), "on_mission" },
		{ E.rewardPilot(1, "failed_head"), "m1_failed" }, { E.pilot({}), "intro" }, { E.rewardPilot(2, "won_b"), "m2_reward" }, { E.offerPilot(4), "m4_offer" },
		{ E.trainee({}), "training" }, { E.trainee({ 1 }, XP - 1), "tier4_incomplete" }, { E.graduate(), "transfer" }, { E.graduate({ master = true }), "here_for_work" },
	}

	for i, p in ipairs(pilots) do
		local before = E.snapshot(p[1])

		lu.assertEquals(handler():gateScreenId(p[1]), p[2], "pilot " .. i .. ": gateScreenId")
		lu.assertEquals(E.snapshot(p[1]), before, "pilot " .. i .. ": gateScreenId is pure")
	end
end

-- I-3: getInitialScreen changes nothing for the pilots of every row (the state is checked inside opens())
-- AC-3
function TestEvinGates:test_getInitialScreen_is_pure_for_every_kind_of_pilot()
	local pilots = {
		E.nonPilot(), E.pilot({ pilotTier = 3 }), E.pilot({ met = true, pilotTier = 3, xp = XP }), E.pilot({ pilot = "imperial", faction = "imperial" }), E.pilot({ squadron = "havoc" }),
		E.pilot({ standing = -1 }), E.pilot({ ezkielM4Paid = false }), E.pilot({ evinActive = E.M2[4] }), E.pilot({ otherQuest = "story" }), E.pilot({ duty = E.DUTIES[3] }),
		E.rewardPilot(1, "failed_head"), E.rewardPilot(3, "failed_b"), E.rewardPilot(1, "won_a"), E.rewardPilot(4, "won_b", { xp = 200000 }), E.pilot({}),
		E.offerPilot(2, { inventory = { limit = 0 } }), E.trainee({ 1 }), E.trainee({ 1, 2, 3 }, XP - 1), E.graduate({ pilotTier = 4 }), E.graduate({ master = true }),
	}

	for i, player in ipairs(pilots) do
		opens(player)
		opens(player)
		lu.assertTrue(i > 0, "pilot " .. i)
	end
end

-- AC-9, I-7: the gates never write VORTEX_PILOT_KEY, whatever its value
-- AC-3, AC-9
function TestEvinGates:test_the_gates_never_write_the_vortex_pilot_key()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = E.pilot({ flag = flag })

		E.talk(player)
		E.talk(player, { "s_4265144c" })
		lu.assertEquals(E.flag(player), flag, "VORTEX_PILOT_KEY after two talks with flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- The helpers the spec names (Content contract 2) and J4's won / failed rules (I-8)
---------------------------------------------------------------------------------------------

TestEvinHelpers = {}

TestEvinHelpers.setUp = setUp

-- J4:28-175 transcribed over the abstract outcome of each quest of a mission: head, success child (s), failure child (f). "failed" is a failed or aborted run.
-- failedMissionN = (head failed and the failure child not won) or the failure child failed or the success child failed (2_c is never read);
-- isGettingMissionNReward = either first-level child complete (and the reward not received).
local OUTCOMES = {
	won_a = { head = "won", s = "won" }, failed_a = { head = "won", s = "failed" }, won_b = { head = "failed", f = "won" }, failed_b = { head = "failed", f = "failed" },
	failed_head = { head = "failed" }, aborted = { head = "failed" }, won_b_c_failed = { head = "failed", f = "won" }, won_b_c_won = { head = "failed", f = "won" },
}

local function j4Failed(o) return (o.head == "failed" and o.f ~= "won") or o.f == "failed" or o.s == "failed" end

local function j4Won(o) return o.s == "won" or o.f == "won" end

-- I-8: for every reachable outcome of each mission, isWon / isFailed equal J4's predicates
-- AC-3, AC-6, AC-7
function TestEvinHelpers:test_is_won_and_is_failed_equal_the_j4_predicates_over_every_reachable_outcome()
	local h = handler()
	local compared = 0

	for n = 1, 4 do
		for state, outcome in pairs(OUTCOMES) do
			if (state ~= "won_b_c_failed" and state ~= "won_b_c_won") or n == 2 then
				H.reset()

				local player = E.rewardPilot(n, state)

				lu.assertEquals(h:isWon(player, n), j4Won(outcome), "mission " .. n .. " " .. state .. ": isWon vs J4 isGettingMissionNReward")
				lu.assertEquals(h:isFailed(player, n), j4Failed(outcome), "mission " .. n .. " " .. state .. ": isFailed vs J4 failedMissionN")
				lu.assertFalse(h:isActive(player, n), "mission " .. n .. " " .. state .. ": nothing runs")
				lu.assertFalse(h:isWon(player, n) and h:isFailed(player, n), "mission " .. n .. " " .. state .. ": never both won and failed")
				compared = compared + 1
			end
		end
	end

	lu.assertEquals(compared, 6 * 3 + 8, "outcomes compared (six per mission, eight for mission 2)")
end

-- I-8: a running quest is neither won nor failed through the helpers, and chain_active sees both branches and 2_c
-- AC-3, AC-6
function TestEvinHelpers:test_a_running_member_makes_the_chain_active_and_not_failed()
	local h = handler()

	for n = 1, 4 do
		for i, global in ipairs(E.CHAINS[n]) do
			H.reset()

			local player = E.pilot({ met = true, evinActive = global })

			H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. " member " .. i .. " (" .. global .. ") running: isActive")
			lu.assertTrue(h:isOnMission(player), "isOnMission")
			lu.assertFalse(h:isFailed(player, n), "attempted but running is not failed")
		end
	end
end

-- Content contract 2: isPaid is the :reward key; a mission never attempted is neither won, failed nor paid
-- AC-3, AC-7
function TestEvinHelpers:test_is_paid_follows_the_reward_key_and_a_fresh_pilot_has_no_mission_state()
	local h = handler()
	local fresh = E.pilot({})

	for n = 1, 4 do
		lu.assertFalse(h:isWon(fresh, n), "fresh: isWon " .. n)
		lu.assertFalse(h:isActive(fresh, n), "fresh: isActive " .. n)
		lu.assertFalse(h:isFailed(fresh, n), "fresh: isFailed " .. n)
		lu.assertFalse(h:isPaid(fresh, n), "fresh: isPaid " .. n)
	end

	lu.assertFalse(h:isOnMission(fresh), "fresh: isOnMission")
	lu.assertFalse(h:isDutyActive(fresh), "fresh: isDutyActive")

	local paid = E.pilot({ paid = { 1, 2 } })

	lu.assertTrue(h:isPaid(paid, 1) and h:isPaid(paid, 2), "two missions paid")
	lu.assertFalse(h:isPaid(paid, 3), "mission 3 not paid")
	lu.assertFalse(h:isFailed(paid, 1), "a paid mission is not failed")
end

-- Content contract 2: isDutyActive / isOnMission see the four duties
-- AC-3
function TestEvinHelpers:test_is_duty_active_sees_each_of_the_four_duties()
	local h = handler()

	for k, global in ipairs(E.DUTIES) do
		H.reset()

		local player = E.pilot({ duty = global })

		lu.assertTrue(h:isDutyActive(player), "duty " .. k .. ": isDutyActive")
		lu.assertTrue(h:isOnMission(player), "duty " .. k .. ": isOnMission")
	end
end

-- Content contract 2: getPilotFlag is the key value, or nil when unset or empty
-- AC-3
function TestEvinHelpers:test_get_pilot_flag_is_the_key_value_or_nil()
	local h = handler()

	lu.assertEquals(h:getPilotFlag(E.pilot({ flag = "3" })), "3", "flag 3")
	lu.assertEquals(h:getPilotFlag(E.pilot({ flag = "1" })), "1", "flag 1")
	lu.assertNil(h:getPilotFlag(E.pilot({ flag = false })), "flag unset")

	local empty = E.pilot({ flag = false })

	H.setQuestStatus(empty, E.VORTEX_PILOT_KEY, "")
	lu.assertNil(h:getPilotFlag(empty), "flag empty")
end

-- Content contract 2: hasMet is the met key "1"; tier4Count counts the _04 skills
-- AC-3, AC-4
function TestEvinHelpers:test_has_met_reads_the_met_key_and_tier_4_count_counts_the_tier_4_skills()
	local h = handler()

	lu.assertFalse(h:hasMet(E.pilot({})), "no met key")
	lu.assertTrue(h:hasMet(E.pilot({ met = true })), "met key set")

	for count = 0, 4 do
		lu.assertEquals(h:tier4Count(E.pilot({ t4 = skills(count) })), count, count .. " _04 skills")
	end
end

-- Content contract 2: isReadyForTier4 (Q-B1 = A) is exactly Ezkiel's: four _03 skills, the flag set, Ezkiel's mission 4 paid
-- AC-3
function TestEvinHelpers:test_is_ready_for_tier_4_needs_four_tier_3_skills_the_flag_and_ezkiels_mission_4_reward()
	local h = handler()

	lu.assertTrue(h:isReadyForTier4(E.pilot({})), "four _03 skills, flag, Ezkiel's M4 paid")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ ezkielM4Paid = false })), "Ezkiel's M4 unpaid")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ flag = false })), "no flag")
	lu.assertTrue(h:isReadyForTier4(E.pilot({ flag = "1" })), "flag 1")
end

-- Content contract 2: isGrounded (D-8): negative Rebel standing or a faction other than Rebel
-- AC-3
function TestEvinHelpers:test_is_grounded_is_negative_standing_or_a_non_rebel_faction()
	local h = handler()

	lu.assertFalse(h:isGrounded(E.pilot({ standing = 0 })), "standing 0")
	lu.assertFalse(h:isGrounded(E.pilot({ standing = 100 })), "standing 100")
	lu.assertTrue(h:isGrounded(E.pilot({ standing = -1 })), "standing -1")
	lu.assertTrue(h:isGrounded(E.pilot({ faction = "neutral" })), "no faction")
	lu.assertTrue(h:isGrounded(E.pilot({ faction = "imperial" })), "Imperial faction")
end

-- Content contract 2: canFlyNonTrackDuty (J4:195-202): tier 1 done, no quest, no mission running
-- AC-4
function TestEvinHelpers:test_can_fly_non_track_duty_needs_tier_1_done_and_no_quest()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc" })), "tier 1 done, no quest")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", t1 = 3 })), "three _01 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", t1 = 0 })), "no _01 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", otherQuest = "story" })), "a story mission in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", otherQuest = "duty" })), "a duty in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", duty = E.DUTIES[1] })), "an Evin duty running")
end

-- Content contract 2: getOfferMission (J4's order 4, 3, 2, 1; count rule; n = 1 needs at least one skill; nil otherwise)
-- AC-3, AC-5
function TestEvinHelpers:test_get_offer_mission_follows_the_count_rule_and_the_paid_keys()
	local h = handler()

	lu.assertNil(h:getOfferMission(E.pilot({ met = true })), "no skill")

	for n = 1, 4 do
		lu.assertEquals(h:getOfferMission(E.offerPilot(n)), n, n .. " skills, earlier missions paid")
	end

	lu.assertNil(h:getOfferMission(E.trainee({ 1 })), "one skill, M1 paid")
	lu.assertNil(h:getOfferMission(E.graduate()), "four skills, four missions paid")
	lu.assertEquals(h:getOfferMission(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 2, 3 } })), 1, "three skills, mission 1 unpaid: n = 1 needs at least one skill")
end

-- Content contract 2: isReadyForTraining (J4:100-107): tier 4 not complete, tier 3 complete, 1,000,000 XP
-- AC-3, AC-8
function TestEvinHelpers:test_is_ready_for_training_needs_the_xp_an_incomplete_tier_4_and_a_complete_tier_3()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(E.pilot({ xp = XP })), "1,000,000 XP, no skill")
	lu.assertFalse(h:isReadyForTraining(E.pilot({ xp = XP - 1 })), "999,999 XP")
	lu.assertFalse(h:isReadyForTraining(E.graduate({ xp = 2 * XP })), "tier 4 complete")
	lu.assertFalse(h:isReadyForTraining(E.pilot({ xp = XP, t3 = 3 })), "tier 3 incomplete")
end

-- Content contract 2: gateScreenId and getInitialScreen agree on the first screen of every pilot of the table
-- AC-3
function TestEvinHelpers:test_the_get_quest_string_helper_reads_the_squadron_constants()
	local h = handler()

	for n = 1, 4 do
		lu.assertEquals(h:getQuestString(n), VortexSquadronScreenplay[E.MISSIONS[n].questString], "getQuestString(" .. n .. ")")
		lu.assertEquals(h:getQuestString(n), E.QUEST_STRINGS[E.MISSIONS[n].questString], "getQuestString(" .. n .. ") is the Part A constant")
	end
end
