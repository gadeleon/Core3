-- General Ufwol: which screen a pilot opens on (gate table E), the refusal walks, the grounded gate, the Q-B1 ready gate, the first-meeting placement, JF's won/failed rules and purity.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-3; Conversation flow 1; FF-2; D-3, D-8, D-9; I-3, I-7, I-8; user answers Q-B1 = A, Q-B2 = A; R1: grounded gate E5).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is crimson_tier4_data.lua U.pilot (a Crimson Phoenix pilot of
-- tier 3, four _03 skills, EKER_PILOT_KEY "3", Ulvaw'op's four missions paid, pilot tier 4; options flag, ulvawopM4Paid, t3, t4, met, mission, paid, master, squadron, otherQuest, xp,
-- standing, faction, pilot, duty, ufwolActive). getInitialScreen is side-effect free (I-3): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")
local CS = require("harness.client_strings")

E.loadConversation()

pcall(H.loadScreenplay, "space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua")

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

-- talks with the chain starts recorded and not run (a failure screen restarts its mission on display)
local function talk(player, choices)
	E.stubChainStarts()
	E.spyDuties()

	return E.talk(player, choices)
end

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function tearDown() E.restore() end

-- the first n skills
local function skills(n)
	local out = {}

	for i = 1, n do
		out[i] = i
	end

	return out
end

TestUfwolGates = {}

TestUfwolGates.setUp = setUp
TestUfwolGates.tearDown = tearDown

-- E0
-- AC-3
function TestUfwolGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = E.pilot(), E.npc(), H.conversationTemplate(E.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
	lu.assertNil(handler():gateScreenId(nil), "gateScreenId of no player")
end

-- E1
-- AC-3
function TestUfwolGates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(E.pilot({ met = true })), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = E.pilot({ met = true })

	player.ghost = nil
	lu.assertEquals(E.firstScreen(player), "not_pilot", "ghost is nil")
end

-- E2 (JF:5835)
-- AC-3
function TestUfwolGates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = talk(E.nonPilot())

	lu.assertEquals(E.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_4a4a0211", "'I don't think that you belong here, soldier.'")
	lu.assertEquals(E.optionSids(t[1]), {}, "no reply")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- E2 precedes every other row (JF checks isPilot first)
-- AC-3
function TestUfwolGates:test_not_pilot_precedes_the_faction_standing_and_ready_gates()
	lu.assertEquals(opens(E.nonPilot({ faction = "neutral" })), "not_pilot", "plain non-pilot without a faction")
	lu.assertEquals(opens(E.nonPilot({ standing = -5 })), "not_pilot", "E2 precedes the grounded gate")
	lu.assertEquals(opens(E.pilot({ pilot = false, met = true })), "not_pilot", "four _03 skills, the flag and Ulvaw'op's M4 paid, but no pilot: E2 precedes E3")
end

-- E3 (JF:5842; Data mapping 2, D-6)
-- AC-3
function TestUfwolGates:test_an_imperial_pilot_and_a_freelance_pilot_open_wrong_faction_which_ends()
	for name, player in pairs({
		imperial = E.pilot({ pilot = "imperial", faction = "imperial", met = true }),
		freelance = E.pilot({ pilot = "neutral", faction = "neutral", squadron = "none", met = true }),
	}) do
		local t = talk(player)

		lu.assertEquals(E.ids(t), { "wrong_faction" }, name .. " pilot")
		lu.assertEquals(t[1].text, E.PREFIX .. "s_4a4a0211", name .. ": 'I don't think that you belong here, soldier.'")
		lu.assertEquals(E.optionSids(t[1]), {}, name .. ": no reply")
		lu.assertTrue(t[1].stop, name .. ": wrong_faction ends")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, name .. ": client strings")
	end

	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "rebel", met = true })), "wrong_faction", "Imperial pilot skills with Rebel faction")
	lu.assertEquals(opens(E.pilot({ pilot = "neutral", faction = "rebel", squadron = "none", met = true })), "wrong_faction", "freelance pilot with Rebel faction")
end

-- E3 precedes E4 to E24
-- AC-3
function TestUfwolGates:test_wrong_faction_comes_before_the_track_grounded_ready_and_mission_gates()
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", squadron = "havoc", met = true })), "wrong_faction", "an Imperial pilot in a Havoc squadron: E3 precedes E4")
	lu.assertEquals(opens(E.pilot({ pilot = "neutral", squadron = "none", standing = -50, met = true })), "wrong_faction", "E3 precedes the grounded gate")
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", ulvawopM4Paid = false })), "wrong_faction", "E3 precedes not_ready")
	lu.assertEquals(opens(E.pilot({ pilot = "imperial", faction = "imperial", mission = { [1] = "active" } })), "wrong_faction", "E3 precedes on_mission")
end

-- E4 (JF:5849): a Vortex or Havoc pilot, and one outside every squadron, with tier 3 or tier 4 skills
-- AC-3
function TestUfwolGates:test_a_vortex_or_havoc_pilot_opens_off_track_whatever_skills_they_hold()
	for _, squadron in ipairs({ "vortex", "havoc" }) do
		local t = talk(E.pilot({ squadron = squadron, met = true }))

		lu.assertEquals(E.ids(t), { "off_track" }, squadron .. " pilot with four _03 skills")
		lu.assertEquals(t[1].text, E.PREFIX .. "s_b9b83ec5", "'Eh? You don't fly for the Crimson Phoenix. What are you doing here?'")
		lu.assertEquals(E.optionSids(t[1]), { "s_d157e1de" }, "the one reply (C-2)")
		lu.assertFalse(t[1].stop, "off_track waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(opens(E.pilot({ squadron = squadron, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })), "off_track", squadron .. " pilot with four _04 skills")
		lu.assertEquals(opens(E.pilot({ squadron = squadron, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, master = true })), "off_track", squadron .. " pilot with the master skill")
	end

	lu.assertEquals(opens(E.pilot({ squadron = "none" })), "off_track", "a Rebel pilot with no squadron")
end

-- E4 precedes E5 to E24
-- AC-3
function TestUfwolGates:test_off_track_comes_before_the_grounded_ready_and_mission_gates()
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", ulvawopM4Paid = false })), "off_track", "E4 precedes not_ready")
	lu.assertEquals(opens(E.pilot({ squadron = "vortex", mission = { [1] = "active" } })), "off_track", "E4 precedes on_mission")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", otherQuest = "story" })), "off_track", "E4 precedes on_mission (a datapad mission)")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", mission = { [1] = "failed_head" } })), "off_track", "E4 precedes the failure screens")
	lu.assertEquals(opens(E.rewardPilot(1, "won_a", { squadron = "havoc" })), "off_track", "E4 precedes the reward screens")
	lu.assertEquals(opens(E.pilot({ squadron = "vortex", missions = 4, t3 = 4 })), "off_track", "a Vortex tier 3 graduate with the flag and a paid key is never handed to Ufwol")
end

-- E5 (D-8, user): a grounded Crimson pilot is refused with s_4a4a0211, in a screen of its own, and the walk grants nothing
-- AC-3
function TestUfwolGates:test_a_crimson_pilot_with_rebel_standing_minus_one_opens_grounded_which_ends_and_grants_nothing()
	local player = E.pilot({ standing = -1, met = true })
	local before = E.snapshot(player)
	local chains, grants = E.recordChainStarts(), E.recordGrants()
	local spies = E.spyDuties()
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "grounded" }, "standing -1")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_4a4a0211", "'I don't think that you belong here, soldier.'")
	lu.assertEquals(E.optionSids(t[1]), {}, "no reply")
	lu.assertTrue(t[1].stop, "grounded ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(chains, {}, "no mission started")
	lu.assertEquals(grants, {}, "no skill granted")
	lu.assertEquals(E.startedDuties(spies), {}, "no duty started")
	lu.assertEquals(E.snapshot(player).status, before.status, "no status key written")
	lu.assertEquals(E.snapshot(player).standing, -1, "standing unchanged")
	lu.assertEquals(E.snapshot(player).flag, before.flag, "EKER_PILOT_KEY untouched")
end

-- E5: the boundary and the three kinds of grounding
-- AC-3
function TestUfwolGates:test_standing_zero_with_rebel_faction_is_not_grounded_and_a_non_rebel_faction_is()
	lu.assertNotEquals(opens(E.pilot({ standing = 0, met = true })), "grounded", "standing exactly 0, Rebel faction")
	lu.assertNotEquals(opens(E.pilot({ standing = 100, met = true })), "grounded", "standing 100")
	lu.assertEquals(opens(E.pilot({ standing = -1, met = true })), "grounded", "standing -1")
	lu.assertEquals(opens(E.pilot({ standing = 0, faction = "neutral", met = true })), "grounded", "standing 0 but neutral faction")
	lu.assertEquals(opens(E.pilot({ standing = 0, faction = "imperial", met = true })), "grounded", "Imperial faction")
end

-- E5 precedes E6 to E24: a grounded pilot is offered nothing, re-granted nothing, paid nothing and trained in nothing
-- AC-3
function TestUfwolGates:test_grounded_comes_before_the_ready_mission_failure_reward_offer_and_training_gates()
	local cases = {
		["not ready (three _03 skills)"] = E.pilot({ standing = -1, t3 = 3 }),
		["Ulvaw'op's M4 unpaid"] = E.pilot({ standing = -1, ulvawopM4Paid = false }),
		["an active Ufwol chain member"] = E.pilot({ standing = -1, met = true, ufwolActive = E.M1[1] }),
		["a duty running"] = E.pilot({ standing = -1, met = true, duty = E.DUTIES[2] }),
		["a datapad mission of another trainer"] = E.pilot({ standing = -1, met = true, otherQuest = "story" }),
		["mission 1 failed"] = E.rewardPilot(1, "failed_head", { standing = -1 }),
		["mission 1 won and unpaid"] = E.rewardPilot(1, "won_a", { standing = -1 }),
		["an offer pending"] = E.offerPilot(2, { standing = -1 }),
		["1,000,000 XP and a _04 skill pending training"] = E.pilot({ standing = -1, met = true, t4 = { 1 }, paid = { 1 }, xp = XP }),
		["the first meeting pending"] = E.pilot({ standing = -1 }),
		["four skills, M4 paid"] = E.graduate({ standing = -1 }),
		["the master skill"] = E.graduate({ standing = -1, master = true }),
	}

	for label, player in pairs(cases) do
		lu.assertEquals(opens(player), "grounded", label .. ": E5 precedes E6-E24")

		local chains, grants = E.recordChainStarts(), E.recordGrants()
		local spies = E.spyDuties()
		local before = E.snapshot(player)
		local t = E.talk(player)

		lu.assertEquals(E.ids(t), { "grounded" }, label .. ": the walk")
		lu.assertTrue(t[1].stop, label .. ": grounded ends")
		lu.assertEquals(#t[1].options, 0, label .. ": no option")
		lu.assertEquals(chains, {}, label .. ": no mission started")
		lu.assertEquals(grants, {}, label .. ": no skill granted")
		lu.assertEquals(E.startedDuties(spies), {}, label .. ": no duty started")
		lu.assertEquals(E.snapshot(player), before, label .. ": nothing set, paid, granted or raised")
		E.restore()
	end
end

-- E5: no payment on a grounded pilot who has a won mission
-- AC-3, AC-7
function TestUfwolGates:test_a_grounded_pilot_with_a_won_mission_is_not_paid()
	local player = E.rewardPilot(1, "won_a", { standing = -1 })
	local rewards = H.spyOn(E.quest(E.HEADS[1]), "rewardPlayer")

	E.talk(player)
	lu.assertEquals(#rewards, 0, "rewardPlayer was not called")
	lu.assertEquals(E.paid(player, 1), nil, "the :reward key is not set")
	lu.assertEquals(player.bankCredits, 0, "no credits")
end

-- E4 precedes E5: a grounded Vortex or Havoc pilot keeps JF's off-track path (R-7)
-- AC-3
function TestUfwolGates:test_a_grounded_vortex_or_havoc_pilot_opens_off_track_not_grounded()
	lu.assertEquals(opens(E.pilot({ squadron = "vortex", standing = -1, met = true })), "off_track", "grounded Vortex pilot")
	lu.assertEquals(opens(E.pilot({ squadron = "havoc", standing = -1, met = true })), "off_track", "grounded Havoc pilot")
	lu.assertEquals(opens(E.pilot({ squadron = "none", standing = -1 })), "off_track", "grounded pilot without a squadron")
end

-- E6 (JF:5879; Q-B1 = A)
-- AC-3
function TestUfwolGates:test_a_crimson_pilot_who_is_not_ready_opens_not_ready_which_ends()
	local t = talk(E.pilot({ ulvawopM4Paid = false }))

	lu.assertEquals(E.ids(t), { "not_ready" }, "four _03 skills and the flag, Ulvaw'op's M4 unpaid")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_46ccc483", "'I think you've got work to do for Ulvaw'op, soldier.'")
	lu.assertEquals(E.optionSids(t[1]), {}, "no reply")
	lu.assertTrue(t[1].stop, "not_ready ends")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	lu.assertEquals(opens(E.pilot({ flag = false })), "not_ready", "four _03 skills, Ulvaw'op's M4 paid, no EKER_PILOT_KEY")
	lu.assertEquals(opens(E.pilot({ t3 = 3 })), "not_ready", "Ulvaw'op's M4 paid but only three _03 skills")
	lu.assertEquals(opens(E.pilot({ t3 = 0, missions = 0 })), "not_ready", "no _03 skill")
end

-- E6: the ready check reads Ulvaw'op's tatooine_rebel_tier3_4:reward key (Q-B1 = A)
-- AC-3, AC-9
function TestUfwolGates:test_the_ready_gate_reads_ulvawops_mission_4_reward_key()
	local player = E.pilot({ ulvawopM4Paid = false })

	lu.assertEquals(opens(player), "not_ready", "reward key absent")
	H.setQuestStatus(player, E.TIER3_M4_REWARD, "1")
	lu.assertEquals(opens(player), "intro", "the tatooine_rebel_tier3_4:reward key opens the first meeting")
end

-- E6: any set flag value is ready (the values 1, 2 and 3: Q-B1 = A "set (any value)")
-- AC-3, AC-9
function TestUfwolGates:test_flag_values_1_2_and_3_are_all_ready_for_tier_4()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()
		lu.assertEquals(opens(E.pilot({ flag = flag })), "intro", "flag " .. flag)
	end
end

-- E6 precedes E7 to E24
-- AC-3
function TestUfwolGates:test_not_ready_comes_before_on_mission_the_failures_the_rewards_the_meeting_and_the_offers()
	lu.assertEquals(opens(E.pilot({ ulvawopM4Paid = false, mission = { [1] = "active" } })), "not_ready", "E6 precedes on_mission")
	lu.assertEquals(opens(E.pilot({ ulvawopM4Paid = false, mission = { [1] = "failed_head" } })), "not_ready", "E6 precedes m1_failed")
	lu.assertEquals(opens(E.pilot({ ulvawopM4Paid = false, mission = { [1] = "won_a" } })), "not_ready", "E6 precedes m1_reward")
	lu.assertEquals(opens(E.pilot({ ulvawopM4Paid = false, met = true, t4 = { 1 } })), "not_ready", "E6 precedes the offers")
	lu.assertEquals(opens(E.pilot({ ulvawopM4Paid = false, met = true, xp = XP })), "not_ready", "E6 precedes the training")
end

-- E7 (JF:5886): any chain member of any mission
-- AC-3
function TestUfwolGates:test_a_pilot_flying_any_member_of_the_four_missions_opens_on_mission_which_ends()
	for n, chain in ipairs(E.CHAINS) do
		for _, global in ipairs(chain) do
			H.reset()

			local t = talk(E.pilot({ met = true, ufwolActive = global }))

			lu.assertEquals(E.ids(t), { "on_mission" }, "mission " .. n .. ": " .. global .. " active")
			lu.assertEquals(t[1].text, E.PREFIX .. "s_a86d6540", "'You've already got a mission. I suggest you do it.'")
			lu.assertEquals(E.optionSids(t[1]), {}, "no reply")
			lu.assertTrue(t[1].stop, "on_mission ends")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end
end

-- E7: any of the four Ufwol duties running (a duty has no :attempted key)
-- AC-3
function TestUfwolGates:test_a_pilot_flying_any_of_the_four_ufwol_duties_opens_on_mission()
	for k, global in ipairs(E.DUTIES) do
		H.reset()
		lu.assertEquals(opens(E.pilot({ met = true, duty = global })), "on_mission", "duty " .. k .. " (" .. global .. ") active")
	end
end

-- E7: a quest from another trainer in the datapad blocks too (SpaceHelpers:hasSpaceQuest)
-- AC-3
function TestUfwolGates:test_a_space_quest_of_another_trainer_in_the_datapad_opens_on_mission()
	lu.assertEquals(opens(E.pilot({ met = true, otherQuest = "story" })), "on_mission", "a story mission of another trainer in the datapad")
	lu.assertEquals(opens(E.pilot({ met = true, otherQuest = "duty" })), "on_mission", "a duty of another trainer in the datapad")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1 }, paid = {}, otherQuest = "story" })), "on_mission", "with a skill waiting for its mission")
	lu.assertEquals(opens(E.pilot({ otherQuest = "story" })), "on_mission", "before the first meeting: E7 precedes E12")
end

-- E7 precedes E8 to E24
-- AC-3
function TestUfwolGates:test_on_mission_comes_before_the_failures_the_rewards_the_meeting_and_the_offers()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "failed_head" }, duty = E.DUTIES[1] })), "on_mission", "mission 2 attempted and a duty running")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1 }, mission = { [1] = "active" } })), "on_mission", "mission 1 running")
	lu.assertEquals(opens(E.rewardPilot(2, "won_a", { ufwolActive = E.M3[1] })), "on_mission", "a reward owed, another mission running")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, mission = { [1] = "active" }, xp = XP })), "on_mission", "before the first meeting: E7 precedes E12")
end

-- E8 to E11: a mission attempted and neither won nor running opens its failure screen, for every failure outcome of I-8
-- AC-3, AC-6
for n = 1, 4 do
	local states = { "failed_head", "aborted", "failed_a", "failed_b" }

	if n == 1 then
		states = { "failed_head", "aborted", "failed_a", "failed_b", "won_b", "failed_c" }
	end

	for _, state in ipairs(states) do
		TestUfwolGates["test_mission_" .. n .. "_" .. state .. "_opens_m" .. n .. "_failed"] = function()
			local t = talk(E.rewardPilot(n, state))

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed" }, "mission " .. n .. " " .. state)
			lu.assertFalse(t[1].stop, "m" .. n .. "_failed waits for a reply")
			lu.assertEquals(#t[1].options, 2, "m" .. n .. "_failed: two replies")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-6: a head aborted from the datapad (the real abortQuest) is a failure too
	TestUfwolGates["test_mission_" .. n .. "_aborted_from_the_datapad_opens_m" .. n .. "_failed"] = function()
		local player = E.rewardPilot(n, "active")

		lu.assertEquals(opens(player), "on_mission", "while it flies")
		E.quest(E.HEADS[n]):abortQuest(player)
		lu.assertEquals(E.state(player, E.HEADS[n]), "none", "the abort ends the run")
		lu.assertEquals(opens(player), "m" .. n .. "_failed", "after the abort (abort is failure)")
	end
end

-- E8 to E11: the failure screens' lines (JF:5896-6021)
-- AC-3
function TestUfwolGates:test_the_four_failure_screens_show_the_jf_lines_and_replies()
	local want = {
		{ "s_8d9faecf", "m1_failed_b0933679", "m1_failed_afcb06fc", "s_a95ef734", "s_9fc24a78" },
		{ "s_9b578280", "m2_failed_e2a4b15e", "m2_failed_18e57f03", "s_1678be5a", "s_6912a453" },
		{ "s_6d4fe1fb", "m3_failed_45ae8603", "m3_failed_f3bbd7e7", "s_8c5f29f4", "s_63740522" },
		{ "s_eb925c97", "m4_failed_71854a18", "m4_failed_bbd20f83", "s_4479e343", "s_2022581b" },
	}

	for n = 1, 4 do
		H.reset()

		local t = talk(E.rewardPilot(n, "failed_head"))

		lu.assertEquals(t[1].text, E.PREFIX .. want[n][1], "mission " .. n .. ": the failure line")
		lu.assertEquals(E.optionSids(t[1]), { want[n][4], want[n][5] }, "mission " .. n .. ": the two replies")
		lu.assertEquals(E.linksOf(t[1]), { want[n][2], want[n][3] }, "mission " .. n .. ": the closing screens")
		E.restore()
	end
end

-- E8 to E11: the failures are checked in the order M1, M2, M3, M4
-- AC-3
function TestUfwolGates:test_the_failure_screens_come_in_the_order_m1_m2_m3_m4()
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

-- E8 to E11 precede the first meeting, the rewards and the offers
-- AC-3
function TestUfwolGates:test_the_failure_screens_precede_the_meeting_the_reward_and_offer_screens()
	lu.assertEquals(opens(E.pilot({ mission = { [1] = "failed_head" } })), "m1_failed", "a failure before the first meeting: E8 precedes E12")

	local player = E.pilot({ met = true, t4 = { 1, 2 }, paid = {}, mission = { [1] = "won_a" } })

	H.setQuestStatus(player, E.STATUS[2] .. ":attempted", "1")
	lu.assertEquals(opens(player), "m2_failed", "mission 1 won and unpaid, mission 2 attempted: E9 precedes E13")
end

-- E8 to E11: a won mission is not failed, a running one is on_mission
-- AC-3, AC-6
function TestUfwolGates:test_attempted_and_won_is_not_failed_and_attempted_and_running_is_on_mission()
	lu.assertEquals(opens(E.rewardPilot(1, "won_a")), "m1_reward", "attempted and won through the success child: the reward, not the failure")
	lu.assertEquals(opens(E.rewardPilot(1, "won_c")), "m1_reward", "attempted and won through the failure branch's end 1_c")
	lu.assertEquals(opens(E.rewardPilot(2, "won_b")), "m2_reward", "attempted and won through the failure child")
	lu.assertEquals(opens(E.rewardPilot(1, "active")), "on_mission", "attempted and running: E7 precedes E8")
	lu.assertEquals(opens(E.rewardPilot(1, "b_complete_c_active")), "on_mission", "the surprise attack of the failure branch is running")
end

-- E12 (JF:6398, moved by D-9): a ready pilot without the met key opens the first meeting, whatever the XP
-- AC-3
function TestUfwolGates:test_a_ready_pilot_without_the_met_key_opens_intro_with_no_xp_and_with_two_million()
	local t = talk(E.pilot({}))

	lu.assertEquals(E.ids(t), { "intro" }, "no XP")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_1ec8846c", "'Hello, pilot. Welcome to Rori. First time here?'")
	lu.assertEquals(E.optionSids(t[1]), { "s_9b43a7ee" }, "the one reply")
	lu.assertEquals(E.linksOf(t[1]), { E.MET_SCREEN }, "it leads to the line that sets the met key")
	lu.assertFalse(t[1].stop, "intro waits for the reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.pilot({ xp = 2 * XP })), "intro", "2,000,000 XP: the meeting comes before the training")
	lu.assertEquals(opens(E.pilot({ xp = XP })), "intro", "1,000,000 XP")
end

-- E12 precedes E13 to E24 (D-9): rewards, offers and training wait for the first meeting
-- AC-3
function TestUfwolGates:test_the_first_meeting_comes_before_the_rewards_the_offers_and_the_training()
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, mission = { [1] = "won_a" } })), "intro", "M1 won and unpaid, no met key: E12 precedes E13")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 } })), "intro", "one skill, no met key: E12 precedes E20")
	lu.assertEquals(opens(E.pilot({ t4 = { 1 }, paid = { 1 }, xp = XP })), "intro", "M1 paid, 1,000,000 XP, no met key: E12 precedes E21")
	lu.assertEquals(opens(E.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })), "intro", "a graduate who never met Ufwol: E12 precedes E23")
	lu.assertEquals(opens(E.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, master = true })), "intro", "with the master skill: E12 precedes E24")
end

-- E12: Ulvaw'op's graduate (four _03 skills, flag, M4 paid) opens intro, never not_ready (AC-9, Q-B1 = A)
-- AC-3, AC-9
function TestUfwolGates:test_ulvawops_tier_done_pilot_opens_intro()
	lu.assertEquals(opens(E.pilot({ flag = "3", t3 = 4, ulvawopM4Paid = true, pilotTier = 4 })), "intro", "tier 3 graduate")
	lu.assertEquals(opens(E.pilot({ pilotTier = 3 })), "intro", "tier 3 graduate left at pilot tier 3")
end

-- E13 to E16 (JF:6059-6192): "won" is JF's set, whatever the head did; M1 wins through 1_a or 1_c
-- AC-3, AC-7
for n = 1, 4 do
	local vias = { "won_a", "won_b" }

	if n == 1 then
		vias = { "won_a", "won_c" }
	end

	for _, via in ipairs(vias) do
		TestUfwolGates["test_mission_" .. n .. "_" .. via .. "_and_unpaid_opens_m" .. n .. "_reward"] = function()
			local t = talk(E.rewardPilot(n, via, {}))

			lu.assertEquals(E.ids(t), { "m" .. n .. "_reward" }, "mission " .. n .. " " .. via)
			lu.assertEquals(#t[1].options, 2, "m" .. n .. "_reward: two replies")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- E13 to E16: the smallest owed mission first; a paid mission is not owed
-- AC-3
function TestUfwolGates:test_the_smallest_owed_reward_screen_comes_first_and_a_paid_mission_is_not_owed()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, mission = { [1] = "won_a", [2] = "won_a" } })), "m1_reward", "missions 1 and 2 won and unpaid")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2 }, paid = { 1 }, mission = { [2] = "won_a" } })), "m2_reward", "mission 1 paid, mission 2 won and unpaid")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = { 1 }, paid = { 1 } })), "m1_reward", "a paid mission opens no reward")
end

-- E13 to E16 precede the offers and the training: a won mission is paid before anything else
-- AC-3
function TestUfwolGates:test_a_reward_owed_comes_before_the_offers_and_the_training()
	lu.assertEquals(opens(E.rewardPilot(1, "won_a", { xp = 2 * XP })), "m1_reward", "one skill, M1 won and unpaid, XP for training")
	lu.assertEquals(opens(E.rewardPilot(4, "won_a", { xp = 2 * XP })), "m4_reward", "four skills, M4 won and unpaid: the reward before the transfer")
end

-- E13 to E16: the reward lines (JF:6063-6195)
-- AC-3, AC-7
function TestUfwolGates:test_the_four_reward_screens_show_the_jf_lines()
	local want = { "s_831e2b3a", "s_6c524e01", "s_d5a98554", "s_bf1cdb65" }

	for n = 1, 4 do
		H.reset()

		local t = talk(E.rewardPilot(n, "won_a"))

		lu.assertEquals(t[1].text, E.PREFIX .. want[n], "mission " .. n .. ": the reward line")
		E.restore()
	end
end

-- E17 to E20 (JF:6233-6357): mission n is offered with n skills and mission n unpaid; the offer comes before the training
-- AC-3, AC-5
for n = 1, 4 do
	TestUfwolGates["test_a_pilot_with_" .. n .. "_tier_4_skills_and_missions_before_paid_opens_m" .. n .. "_offer"] = function()
		local t = talk(E.offerPilot(n))

		lu.assertEquals(E.ids(t), { "m" .. n .. "_offer" }, n .. " skills, missions 1.." .. (n - 1) .. " paid")
		lu.assertEquals(#t[1].options, 2, "m" .. n .. "_offer: two replies")
		lu.assertFalse(t[1].stop, "the offer waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(opens(E.offerPilot(n, { xp = 2 * XP })), "m" .. n .. "_offer", "the offer comes before the training (JF order)")
	end
end

-- E17 to E20: the offer lines (JF:6360, 6319, 6278, 6237)
-- AC-3, AC-5
function TestUfwolGates:test_the_four_offers_show_the_jf_lines()
	local want = { "s_37df0fba", "s_7b03d343", "s_49bf2ccb", "s_d30b6d26" }

	for n = 1, 4 do
		H.reset()

		local t = talk(E.offerPilot(n))

		lu.assertEquals(t[1].text, E.PREFIX .. want[n], "mission " .. n .. ": the offer line")
		E.restore()
	end
end

-- E17 to E20: n skills held and mission n unpaid, with the earlier missions paid; mission 1 needs at least one skill
-- AC-3, AC-5
function TestUfwolGates:test_mission_n_is_offered_only_with_n_skills_and_mission_1_with_at_least_one()
	lu.assertNotEquals(opens(E.offerPilot(2, { t4 = { 1 }, paid = { 1 } })), "m2_offer", "one skill: mission 2 is not offered")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 1 } })), "m2_offer", "three skills: mission 2 is not offered")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 2, 3 } })), "m1_offer", "n = 1: at least one skill and mission 1 unpaid")
	lu.assertNotEquals(opens(E.pilot({ met = true, t4 = {}, paid = {} })), "m1_offer", "no skill: mission 1 is not offered")
	lu.assertNotEquals(opens(E.offerPilot(3, { paid = { 1, 2, 3 } })), "m3_offer", "mission 3 paid: not offered again")
end

-- E21 (JF:6427): the training; the skill waits for no mission
-- AC-3, AC-8
function TestUfwolGates:test_a_ready_pilot_with_no_skill_and_1000000_xp_or_one_skill_with_its_mission_paid_opens_training()
	local t = talk(E.pilot({ met = true, xp = XP }))

	lu.assertEquals(E.ids(t), { "training" }, "no skill, 1,000,000 XP, the meeting heard")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_cb594529", "'Well soldier, you've earned the right to upgrade to a new skill...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.trainee({ 1 })), "training", "one skill, M1 paid, 1,000,000 XP")
	lu.assertEquals(opens(E.trainee({ 1, 2 })), "training", "two skills, M1 and M2 paid, 1,000,000 XP")
	lu.assertEquals(opens(E.trainee({ 1, 2, 3 })), "training", "three skills, M1 to M3 paid, 1,000,000 XP")
end

-- E22 (JF:6456): under 1,000,000 XP the training is not open: the duty menu
-- AC-3
function TestUfwolGates:test_a_ready_pilot_with_999999_xp_opens_tier4_incomplete_with_the_duty_menu()
	local t = talk(E.trainee({ 1 }, XP - 1))

	lu.assertEquals(E.ids(t), { "tier4_incomplete" }, "one skill, M1 paid, 999,999 XP")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_39a10eac", "'Well? Are you ready for a duty assignment?...'")
	lu.assertEquals(E.optionSids(t[1]), E.MENU_REPLIES, "the duty menu")
	lu.assertEquals(E.linksOf(t[1]), E.MENU_LINKS, "the four duties and the briefing again")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(E.pilot({ met = true, xp = XP - 1 })), "tier4_incomplete", "no skill, 999,999 XP")
	lu.assertEquals(opens(E.pilot({ met = true })), "tier4_incomplete", "no skill, no XP")
end

-- E23 (JF:6529): four skills and no master skill: the Burke transfer, on every talk
-- AC-3, AC-9
function TestUfwolGates:test_four_tier_4_skills_with_mission_4_paid_open_transfer_on_every_talk()
	for talkNo = 1, 3 do
		local t = talk(E.graduate())

		lu.assertEquals(E.ids(t), { "transfer" }, "talk " .. talkNo)
		lu.assertEquals(t[1].text, E.PREFIX .. "s_30a32651", "'Good, you're here. I have your orders...'")
		lu.assertEquals(E.optionSids(t[1]), { "s_1d23eb6a", "s_3cc21469" }, "the two questions")
		lu.assertFalse(t[1].stop, "the transfer waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		E.restore()
	end
end

-- E23: a pilot with four skills and mission 4 unpaid is held before the transfer (E7, E11, E16 or E17)
-- AC-3
function TestUfwolGates:test_four_skills_with_mission_4_unpaid_are_held_before_the_transfer()
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 } })), "m4_offer", "not yet flown: the offer (E17)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "flying (E7)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "failed_head" } })), "m4_failed", "failed (E11)")
	lu.assertEquals(opens(E.pilot({ met = true, t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won_a" } })), "m4_reward", "won, unpaid (E16)")
end

-- E24 (JF:6569): the master skill: the greeting and the duty menu
-- AC-3, AC-9
function TestUfwolGates:test_a_pilot_with_the_master_skill_opens_here_for_work_with_the_duty_menu()
	local t = talk(E.graduate({ master = true }))

	lu.assertEquals(E.ids(t), { "here_for_work" }, "master skill")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_233489bc", "'Glad to see that you made it back from your assignment with Admiral Burke...'")
	lu.assertEquals(E.optionSids(t[1]), E.MENU_REPLIES, "the duty menu")
	lu.assertEquals(E.linksOf(t[1]), E.MENU_LINKS, "the four duties and the briefing again")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- The session opens on the screen getInitialScreen picks (I-3)
-- AC-3
function TestUfwolGates:test_the_session_opens_on_the_screen_getInitialScreen_picks()
	E.stubChainStarts()
	lu.assertEquals(E.firstScreen(E.offerPilot(3)), "m3_offer", "session start")
	lu.assertEquals(opens(E.offerPilot(3)), "m3_offer", "getInitialScreen alone")
end

-- gateScreenId is the pure function behind getInitialScreen (Content contract 2)
-- AC-3
function TestUfwolGates:test_gate_screen_id_names_the_screen_getInitialScreen_opens_for_every_row()
	local pilots = {
		{ E.nonPilot(), "not_pilot" }, { E.pilot({ pilot = "imperial", faction = "imperial" }), "wrong_faction" }, { E.pilot({ squadron = "havoc" }), "off_track" },
		{ E.pilot({ standing = -1 }), "grounded" }, { E.pilot({ ulvawopM4Paid = false }), "not_ready" }, { E.pilot({ ufwolActive = E.M1[1] }), "on_mission" },
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
function TestUfwolGates:test_getInitialScreen_is_pure_for_every_kind_of_pilot()
	local pilots = {
		E.nonPilot(), E.pilot({ pilotTier = 3 }), E.pilot({ met = true, pilotTier = 3, xp = XP }), E.pilot({ pilot = "imperial", faction = "imperial" }), E.pilot({ squadron = "havoc" }),
		E.pilot({ squadron = "vortex", standing = -1 }), E.pilot({ standing = -1 }), E.pilot({ faction = "neutral" }), E.pilot({ standing = -1, t3 = 3 }), E.pilot({ ulvawopM4Paid = false }),
		E.pilot({ ufwolActive = E.M1[4] }), E.pilot({ otherQuest = "story" }), E.pilot({ duty = E.DUTIES[3] }), E.rewardPilot(1, "failed_head"), E.rewardPilot(1, "failed_c"),
		E.rewardPilot(3, "failed_b"), E.rewardPilot(1, "won_a"), E.rewardPilot(1, "won_c"), E.rewardPilot(4, "won_b", { xp = 200000 }), E.pilot({}), E.offerPilot(2, { inventory = { limit = 0 } }),
		E.trainee({ 1 }), E.trainee({ 1, 2, 3 }, XP - 1), E.graduate({ pilotTier = 4 }), E.graduate({ master = true }),
	}

	for i, player in ipairs(pilots) do
		opens(player)
		opens(player)
		lu.assertTrue(i > 0, "pilot " .. i)
	end
end

-- I-7: the gates and the first screens never write EKER_PILOT_KEY, whatever its value
-- AC-3, AC-9
function TestUfwolGates:test_the_gates_never_write_the_eker_pilot_key()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = E.pilot({ flag = flag })

		talk(player)
		talk(player, { "s_9b43a7ee" })
		lu.assertEquals(E.flag(player), flag, "EKER_PILOT_KEY after two talks with flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- The helpers the spec names (Content contract 2) and JF's won / failed rules (I-8)
---------------------------------------------------------------------------------------------

TestUfwolHelpers = {}

TestUfwolHelpers.setUp = setUp
TestUfwolHelpers.tearDown = tearDown

-- JF:28-95 and 120-179 transcribed over the abstract outcome of each quest of a mission: head, success child (a), failure child (b) and, for mission 1, the surprise attack (c).
-- "failed" is a failed or aborted run. failedMissionN: (head failed and the failure branch's end not won) or any child failed; won: M1 1_a or 1_c, M2-M4 either first-level child.
local OUTCOMES = {
	won_a = { head = "won", a = "won" }, failed_a = { head = "won", a = "failed" }, won_b = { head = "failed", b = "won" }, failed_b = { head = "failed", b = "failed" },
	failed_head = { head = "failed" }, aborted = { head = "failed" },
}

local M1_OUTCOMES = {
	won_a = { head = "won", a = "won" }, failed_a = { head = "won", a = "failed" }, failed_head = { head = "failed" }, aborted = { head = "failed" },
	failed_b = { head = "failed", b = "failed" }, won_b = { head = "failed", b = "won" }, won_c = { head = "failed", b = "won", c = "won" }, failed_c = { head = "failed", b = "won", c = "failed" },
}

-- n = 1: the failure branch's end is 1_c; n > 1: it is the failure child b
local function jfFailed(n, o)
	local branchEnd = o.b

	if n == 1 then
		branchEnd = o.c
	end

	return (o.head == "failed" and branchEnd ~= "won") or o.a == "failed" or o.b == "failed" or o.c == "failed"
end

local function jfWon(n, o)
	if n == 1 then
		return o.a == "won" or o.c == "won"
	end

	return o.a == "won" or o.b == "won"
end

-- I-8: for every reachable outcome of each mission, isWon / isFailed equal JF's predicates
-- AC-3, AC-6, AC-7
function TestUfwolHelpers:test_is_won_and_is_failed_equal_the_jf_predicates_over_every_reachable_outcome()
	local h = handler()
	local compared = 0

	for n = 1, 4 do
		for state, outcome in pairs(n == 1 and M1_OUTCOMES or OUTCOMES) do
			H.reset()

			local player = E.rewardPilot(n, state)

			lu.assertEquals(h:isWon(player, n), jfWon(n, outcome), "mission " .. n .. " " .. state .. ": isWon vs JF isGettingMissionNReward")
			lu.assertEquals(h:isFailed(player, n), jfFailed(n, outcome), "mission " .. n .. " " .. state .. ": isFailed vs JF failedMissionN")
			lu.assertFalse(h:isActive(player, n), "mission " .. n .. " " .. state .. ": nothing runs")
			lu.assertFalse(h:isWon(player, n) and h:isFailed(player, n), "mission " .. n .. " " .. state .. ": never both won and failed")
			compared = compared + 1
		end
	end

	lu.assertEquals(compared, 8 + 6 * 3, "outcomes compared (eight for mission 1, six for each of the others)")
end

-- I-8: a running quest is neither won nor failed through the helpers, and isActive sees both branches and 1_c
-- AC-3, AC-6
function TestUfwolHelpers:test_a_running_member_makes_the_chain_active_and_not_failed()
	local h = handler()

	for n = 1, 4 do
		for i, global in ipairs(E.CHAINS[n]) do
			H.reset()

			local player = E.pilot({ met = true, ufwolActive = global })

			H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. " member " .. i .. " (" .. global .. ") running: isActive")
			lu.assertTrue(h:isOnMission(player), "isOnMission")
			lu.assertFalse(h:isFailed(player, n), "attempted but running is not failed")
		end
	end
end

-- Content contract 2: isPaid is the :reward key; a mission never attempted is neither won, failed nor paid
-- AC-3, AC-7
function TestUfwolHelpers:test_is_paid_follows_the_reward_key_and_a_fresh_pilot_has_no_mission_state()
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
function TestUfwolHelpers:test_is_duty_active_sees_each_of_the_four_duties()
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
function TestUfwolHelpers:test_get_pilot_flag_is_the_key_value_or_nil()
	local h = handler()

	lu.assertEquals(h:getPilotFlag(E.pilot({ flag = "3" })), "3", "flag 3")
	lu.assertEquals(h:getPilotFlag(E.pilot({ flag = "1" })), "1", "flag 1")
	lu.assertNil(h:getPilotFlag(E.pilot({ flag = false })), "flag unset")

	local empty = E.pilot({ flag = false })

	H.setQuestStatus(empty, E.EKER_PILOT_KEY, "")
	lu.assertNil(h:getPilotFlag(empty), "flag empty")
end

-- Content contract 2: hasMet is the met key "1"; tier4Count counts the _04 skills; hasStatus reads the status keys of the quest string's name
-- AC-3, AC-4
function TestUfwolHelpers:test_has_met_reads_the_met_key_and_tier_4_count_counts_the_tier_4_skills()
	local h = handler()

	lu.assertFalse(h:hasMet(E.pilot({})), "no met key")
	lu.assertTrue(h:hasMet(E.pilot({ met = true })), "met key set")

	for count = 0, 4 do
		lu.assertEquals(h:tier4Count(E.pilot({ t4 = skills(count) })), count, count .. " _04 skills")
	end

	local player = E.pilot({ paid = { 2 } })

	lu.assertTrue(h:hasStatus(player, 2, ":reward"), "hasStatus(2, :reward)")
	lu.assertTrue(h:hasStatus(player, 2, ":attempted"), "hasStatus(2, :attempted)")
	lu.assertFalse(h:hasStatus(player, 1, ":attempted"), "hasStatus(1, :attempted)")
end

-- Content contract 2 (Q-B1 = A): isReadyForTier4 is the Ulvaw'op hand-off: four _03 skills, the flag set, Ulvaw'op's mission 4 paid
-- AC-3, AC-9
function TestUfwolHelpers:test_is_ready_for_tier_4_needs_four_tier_3_skills_the_flag_and_ulvawops_mission_4_reward()
	local h = handler()

	lu.assertTrue(h:isReadyForTier4(E.pilot({})), "four _03 skills, flag, Ulvaw'op's M4 paid")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ ulvawopM4Paid = false })), "Ulvaw'op's M4 unpaid")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:isReadyForTier4(E.pilot({ flag = false })), "no flag")
	lu.assertTrue(h:isReadyForTier4(E.pilot({ flag = "1" })), "flag 1")
end

-- AC-3: isReadyForTier4 agrees with ulvawopConvoHandler:isReadyForTier4 on every pilot
-- AC-3, AC-9
function TestUfwolHelpers:test_is_ready_for_tier_4_agrees_with_ulvawops_hand_off_on_every_pilot()
	local ulvawop = rawget(_G, "ulvawopConvoHandler")

	lu.assertNotNil(ulvawop, "ulvawopConvoHandler is loaded (screenplays/space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua)")
	lu.assertEquals(type(ulvawop.isReadyForTier4), "function", "ulvawopConvoHandler:isReadyForTier4")

	local h, compared = handler(), 0

	for _, t3 in ipairs({ 4, 3, 0 }) do
		for _, flag in ipairs({ "3", "2", "1", false }) do
			for _, paid in ipairs({ true, false }) do
				H.reset()

				local player = E.pilot({ t3 = t3, flag = flag, ulvawopM4Paid = paid, missions = paid and 4 or 3 })

				lu.assertEquals(h:isReadyForTier4(player), ulvawop:isReadyForTier4(player) == true, "t3=" .. t3 .. " flag=" .. tostring(flag) .. " M4 paid=" .. tostring(paid))
				compared = compared + 1
			end
		end
	end

	lu.assertEquals(compared, 24, "pilots compared")
end

-- Content contract 2: isGrounded (D-8): negative Rebel standing or a faction other than Rebel; false when the ghost is nil
-- AC-3
function TestUfwolHelpers:test_is_grounded_is_negative_standing_or_a_non_rebel_faction()
	local h = handler()

	lu.assertFalse(h:isGrounded(E.pilot({ standing = 0 })), "standing 0")
	lu.assertFalse(h:isGrounded(E.pilot({ standing = 100 })), "standing 100")
	lu.assertTrue(h:isGrounded(E.pilot({ standing = -1 })), "standing -1")
	lu.assertTrue(h:isGrounded(E.pilot({ faction = "neutral" })), "no faction")
	lu.assertTrue(h:isGrounded(E.pilot({ faction = "imperial" })), "Imperial faction")

	local noGhost = E.pilot({ standing = -1 })

	noGhost.ghost = nil
	lu.assertFalse(h:isGrounded(noGhost), "no ghost: false")
end

-- Content contract 2: canFlyNonTrackDuty (JF:215-222): TIER 3 done (unlike Vortex's tier 1), no quest, no mission running
-- AC-4
function TestUfwolHelpers:test_can_fly_non_track_duty_needs_tier_3_done_and_no_quest()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc" })), "tier 3 done, no quest")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", t3 = 3 })), "three _03 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", t3 = 0, missions = 0 })), "no _03 skill (only tier 2 complete)")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", otherQuest = "story" })), "a story mission in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", otherQuest = "duty" })), "a duty in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", duty = E.DUTIES[1] })), "an Ufwol duty running")
	lu.assertFalse(h:canFlyNonTrackDuty(E.pilot({ squadron = "havoc", ufwolActive = E.M2[1] })), "an Ufwol mission running")
end

-- Content contract 2: getOfferMission (JF's order 4, 3, 2, 1; count rule; n = 1 needs at least one skill; nil otherwise)
-- AC-3, AC-5
function TestUfwolHelpers:test_get_offer_mission_follows_the_count_rule_and_the_paid_keys()
	local h = handler()

	lu.assertNil(h:getOfferMission(E.pilot({ met = true })), "no skill")

	for n = 1, 4 do
		lu.assertEquals(h:getOfferMission(E.offerPilot(n)), n, n .. " skills, earlier missions paid")
	end

	lu.assertNil(h:getOfferMission(E.trainee({ 1 })), "one skill, M1 paid")
	lu.assertNil(h:getOfferMission(E.graduate()), "four skills, four missions paid")
	lu.assertEquals(h:getOfferMission(E.pilot({ met = true, t4 = { 1, 2, 3 }, paid = { 2, 3 } })), 1, "three skills, mission 1 unpaid: n = 1 needs at least one skill")
end

-- Content contract 2: isReadyForTraining (JF:104-111): tier 4 not complete, tier 3 complete, 1,000,000 XP
-- AC-3, AC-8
function TestUfwolHelpers:test_is_ready_for_training_needs_the_xp_an_incomplete_tier_4_and_a_complete_tier_3()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(E.pilot({ xp = XP })), "1,000,000 XP, no skill")
	lu.assertFalse(h:isReadyForTraining(E.pilot({ xp = XP - 1 })), "999,999 XP")
	lu.assertFalse(h:isReadyForTraining(E.graduate({ xp = 2 * XP })), "tier 4 complete")
	lu.assertFalse(h:isReadyForTraining(E.pilot({ xp = XP, t3 = 3 })), "tier 3 incomplete")
end

-- Content contract 2: getQuestString reads the squadron constants
-- AC-3
function TestUfwolHelpers:test_the_get_quest_string_helper_reads_the_squadron_constants()
	local h = handler()

	for n = 1, 4 do
		lu.assertEquals(h:getQuestString(n), CrimsonPhoenixSquadronScreenplay[E.MISSIONS[n].questString], "getQuestString(" .. n .. ")")
		lu.assertEquals(h:getQuestString(n), E.QUEST_STRINGS[E.MISSIONS[n].questString], "getQuestString(" .. n .. ") is the Part A constant")
	end
end
