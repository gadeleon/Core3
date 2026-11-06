-- Captain Denner: which screen a pilot opens on (gate table G), the refusal walks, the wanted chain, the failure/reward/offer ordering and purity.
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-3, B-4 (ordering), B-7 (tour_complete); Conversation flow 1; FD-7, FD-8, FD-11; D-5, D-6, D-7; I-13).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is storm_tier3_data.lua D.pilot
-- (a Storm pilot who finished tier 2: all four tier 2 skills, Alozen's M3 paid; missions = Denner's missions won and paid; t3 = the tier 3 skills held;
-- won / failed / attempted = the state of one mission). getInitialScreen is side-effect free (I-13): every pilot opened here is checked against a snapshot.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

D.loadConversation()

local function handler() return rawget(_G, D.HANDLER) end

local function squadron(name) return rawget(_G, name) end

local function snapshot(player)
	return {
		state = M.snapshot(player), effects = M.sideEffects(player), credits = player.bankCredits, standing = D.standing(player),
		pilotTier = player.ghost.pilotTier, skills = D.held3(player), inventory = #(player.inventory and player.inventory.items or {}), engineCalls = #H.Engine.calls,
	}
end

-- The first screen the gates pick (getInitialScreen alone, without the display actions of runScreenHandlers); also checks I-13 for this pilot
local function opens(player)
	local before = snapshot(player)
	local pScreen = handler():getInitialScreen(player, D.npc(), H.conversationTemplate(D.TEMPLATE))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")

	local first = LuaConversationScreen(pScreen):getScreenID()

	lu.assertEquals(snapshot(player), before, "getInitialScreen changed the state of the pilot who opened '" .. first .. "' (I-13)")
	return first
end

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

TestStormT3Gates = {}

TestStormT3Gates.setUp = setUp

-- G0
-- B-3
function TestStormT3Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = D.pilot(), D.npc(), H.conversationTemplate(D.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- G1
-- B-3
function TestStormT3Gates:test_jtl_disabled_or_a_missing_player_object_opens_not_pilot()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(D.pilot()), "not_pilot", "JTL disabled")
	H.Engine.config.jtlEnabled = true

	local player = D.pilot()

	player.ghost = nil
	lu.assertEquals(D.firstScreen(player), "not_pilot", "ghost is nil")
end

-- G2 (FD-7: J3 checks isPilot before isCorrectFaction)
-- B-3
function TestStormT3Gates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = D.talk(D.pilot({ pilot = false, squadron = false, t1 = false, t2 = {}, m = 0 }))

	lu.assertEquals(D.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_43b48713", "'I am not sure who you are...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G2
-- B-3
function TestStormT3Gates:test_a_rebel_faction_non_pilot_opens_not_pilot()
	local o = { pilot = false, squadron = false, t1 = false, t2 = {}, m = 0 }

	lu.assertEquals(opens(D.pilot({ pilot = false, faction = "rebel", squadron = false, t1 = false, t2 = {}, m = 0 })), "not_pilot", "Rebel-faction non-pilot")
	lu.assertEquals(opens(D.pilot({ pilot = false, faction = "neutral", squadron = false, t1 = false, t2 = {}, m = 0 })), "not_pilot", "non-pilot without a faction")
	lu.assertEquals(opens(D.pilot({ pilot = false, standing = -5, squadron = false, t1 = false, t2 = {}, m = 0 })), "not_pilot", "G2 precedes the wanted gate")
	lu.assertEquals(opens(D.pilot(o)), "not_pilot", "plain non-pilot")
end

-- G3
-- B-3
function TestStormT3Gates:test_a_rebel_pilot_and_a_privateer_open_wrong_faction_whose_two_replies_end_the_conversation()
	local t1 = D.talk(D.pilot({ pilot = "rebel", faction = "rebel", squadron = false }), { "s_b40f340" })

	lu.assertEquals(D.ids(t1), { "wrong_faction", "wrong_faction_74df4" }, "Rebel pilot, first reply")
	lu.assertEquals(t1[1].text, D.PREFIX .. "s_e6e2ab99", "'You are not here on Imperial business. Leave now.'")
	lu.assertTrue(t1[2].stop, "wrong_faction_74df4 ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t1), {}, "client strings")

	local t2 = D.talk(D.pilot({ pilot = "neutral", squadron = false }), { "s_86137261" })

	lu.assertEquals(D.ids(t2), { "wrong_faction", "wrong_faction_540bd108" }, "privateer, second reply")
	lu.assertTrue(t2[2].stop, "wrong_faction_540bd108 ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t2), {}, "client strings")
	lu.assertEquals(opens(D.pilot({ pilot = "neutral", faction = "neutral", squadron = false })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(D.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "wrong_faction", "Rebel pilot without a faction")
	lu.assertEquals(opens(D.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "wrong_faction", "G3 precedes the wanted gate (the grounded gate covers Imperials only)")
	lu.assertEquals(opens(D.pilot({ pilot = "rebel", faction = "rebel", squadron = false, m = 0 })), "wrong_faction", "G3 precedes not_ready")
end

-- G4 (FD-8)
-- B-3
function TestStormT3Gates:test_a_storm_pilot_without_alozens_mission_3_paid_or_without_all_tier_2_skills_opens_not_ready()
	local t = D.talk(D.pilot({ m = 2, state = "won" }))

	lu.assertEquals(D.ids(t), { "not_ready" }, "four tier 2 skills, Alozen's M3 won but unpaid")
	lu.assertTrue(t[1].stop, "not_ready ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_ready offers no reply")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_846bd129", "'I am afraid that you are not ready for the rigors...'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(D.pilot({ t2 = { 1, 2, 3 } })), "not_ready", "M3 paid but only three tier 2 skills")
	lu.assertEquals(opens(D.pilot({ t2 = { 1, 2 }, m = 3 })), "not_ready", "two tier 2 skills")
	lu.assertEquals(opens(D.pilot({ m = 0 })), "not_ready", "no Alozen mission paid")
	lu.assertEquals(opens(D.pilot({ m = 2, state = "failed" })), "not_ready", "Alozen's M3 failed")
end

-- G4: the ready check is the skills plus the reward key, not Oberhaur's or Alozen's flags alone
-- B-3
function TestStormT3Gates:test_the_ready_gate_reads_the_imperial_ss_6_reward_key()
	local player = D.pilot({ m = 2, state = "won" })

	lu.assertEquals(opens(player), "not_ready", "M3 won, key absent")
	H.setQuestStatus(player, D.TIER2_M3_REWARD, 1)
	lu.assertEquals(opens(player), "m1_offer", "the imperial_ss_6:reward key opens the offer")
end

-- G4 precedes the track check (D-7)
-- B-3
function TestStormT3Gates:test_a_black_epsilon_pilot_with_tier_2_done_but_no_imperial_ss_6_reward_opens_not_ready_and_a_paid_one_opens_off_track()
	lu.assertEquals(opens(D.pilot({ squadron = squadron("BLACK_EPSILON_SQUADRON"), m = 0 })), "not_ready", "Black Epsilon pilot, no reward key")
	lu.assertEquals(opens(D.pilot({ squadron = squadron("INQUISITION_SQUADRON") })), "off_track", "Inquisition pilot with the reward key set")
end

-- G5 (FD-11)
-- B-3
function TestStormT3Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track_whose_one_line_ends_the_conversation()
	local t = D.talk(D.pilot({ squadron = squadron("BLACK_EPSILON_SQUADRON") }))

	lu.assertEquals(D.ids(t), { "off_track" }, "Black Epsilon pilot with the reward key")
	lu.assertTrue(t[1].stop, "off_track ends the conversation")
	lu.assertEquals(#t[1].options, 0, "off_track offers no reply")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_f06f4a8", "'You are not assigned to this Squadron, pilot.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(D.pilot({ squadron = squadron("INQUISITION_SQUADRON") })), "off_track", "Inquisition pilot")
	lu.assertEquals(opens(D.pilot({ squadron = false })), "off_track", "Imperial pilot without a squadron")
	lu.assertEquals(opens(D.pilot({ squadron = squadron("BLACK_EPSILON_SQUADRON"), standing = -1 })), "off_track", "G5 precedes the wanted gate")
	lu.assertEquals(opens(D.pilot({ squadron = false, datapad = "story" })), "off_track", "G5 precedes on_mission")
	lu.assertEquals(opens(D.pilot({ squadron = false, missions = 1, t3 = { 1 } })), "off_track", "G5 precedes the state screens")
end

-- G6 (D-6)
-- B-3
function TestStormT3Gates:test_negative_imperial_standing_opens_wanted()
	lu.assertEquals(opens(D.pilot({ standing = -1 })), "wanted", "Storm pilot, standing -1")
	lu.assertEquals(opens(D.pilot({ standing = -50, missions = 1, t3 = { 1 } })), "wanted", "standing -50 after mission 1")
	lu.assertEquals(opens(D.pilot({ standing = -1, active = D.M1[2] })), "wanted", "G6 precedes on_mission")
	lu.assertEquals(opens(D.pilot({ standing = -1, datapad = "story" })), "wanted", "G6 precedes a datapad quest")
	lu.assertEquals(opens(D.pilot({ standing = -1, failed = 1 })), "wanted", "G6 precedes the failure screens")
	lu.assertEquals(opens(D.pilot({ standing = 0 })), "m1_offer", "standing 0 is served normally")
end

-- G6 (D-6): a Storm pilot whose Imperial faction is gone
-- B-3
function TestStormT3Gates:test_a_storm_pilot_whose_imperial_faction_is_gone_opens_wanted()
	lu.assertEquals(opens(D.pilot({ faction = "neutral" })), "wanted", "standing 0, no faction")
	lu.assertEquals(opens(D.pilot({ faction = "rebel" })), "wanted", "standing 0, Rebel faction")
	lu.assertEquals(opens(D.pilot({ faction = "neutral", missions = 2, t3 = { 1, 2 } })), "wanted", "G6 precedes the offers")
end

-- G6 vs the earlier gates
-- B-3
function TestStormT3Gates:test_the_wanted_gate_follows_not_ready()
	lu.assertEquals(opens(D.pilot({ standing = -1, m = 0 })), "not_ready", "G4 precedes G6")
	lu.assertEquals(opens(D.pilot({ standing = -1, t2 = { 1, 2, 3 } })), "not_ready", "three tier 2 skills and standing -1")
end

-- B-3: the wanted walk runs its three lines with the name and grants nothing
function TestStormT3Gates:test_the_wanted_walk_runs_its_three_lines_with_the_name_and_grants_nothing()
	local player = D.pilot({ standing = -3 })
	local t = D.talk(player, { "s_5814e23b", "s_6efcdb6b", "s_40dea799" })

	lu.assertEquals(D.ids(t), { "wanted", "wanted_78b0ecc0", "wanted_2ec9494f", "wanted_cd3a54f7" }, "screens shown")
	lu.assertTrue(t[4].stop, "wanted_cd3a54f7 ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "wanted: %TU")
	lu.assertEquals(t[4].params.TU, "Ace", "wanted_cd3a54f7: %TU")
	lu.assertEquals(#D.free() + #D.bought(), 0, "no skill granted")
	lu.assertEquals(#D.items(player), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest started")
	lu.assertEquals(D.standing(player), -3, "the standing is untouched")
	lu.assertEquals(H.getQuestStatus(player, D.STATUS[1] .. ":attempted"), nil, "no mission marked attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- B-3: the gate lifts at 0
function TestStormT3Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = D.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "m1_offer", "standing 0")
end

-- G7
-- B-3
function TestStormT3Gates:test_an_active_tier_3_member_or_any_datapad_space_quest_opens_on_mission()
	local t = D.talk(D.pilot({ active = D.M1[2] }))

	lu.assertEquals(D.ids(t), { "on_mission" }, "mission 1's recovery running")
	lu.assertTrue(t[1].stop, "on_mission ends the conversation")
	lu.assertEquals(#t[1].options, 0, "on_mission offers no reply")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_89af090b", "'You are on assignment, soldier.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	for n = 1, 4 do
		for _, global in ipairs(D.CHAINS[n]) do
			lu.assertEquals(opens(D.pilot({ missions = n - 1, t3 = D.t3(n - 1), active = global })), "on_mission", global .. " active")
		end
	end

	lu.assertEquals(opens(D.pilot({ datapad = "duty" })), "on_mission", "a duty from another trainer in the datapad")
	lu.assertEquals(opens(D.pilot({ datapad = "story" })), "on_mission", "a story mission in the datapad")
end

-- G7 precedes the later gates
-- B-3
function TestStormT3Gates:test_on_mission_precedes_the_failure_reward_and_offer_screens()
	lu.assertEquals(opens(D.pilot({ datapad = "story", failed = 1 })), "on_mission", "G7 precedes m1_failed")
	lu.assertEquals(opens(D.pilot({ datapad = "story", missions = 0, won = 1 })), "on_mission", "G7 precedes m1_reward")
	lu.assertEquals(opens(D.pilot({ datapad = "duty", missions = 4, t3 = { 1, 2, 3, 4 } })), "on_mission", "G7 precedes tour_complete")
end

-- G8, B-7
function TestStormT3Gates:test_four_skills_and_mission_4_paid_open_tour_complete()
	local player = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } })

	lu.assertEquals(opens(player), "tour_complete", "all four missions paid, four tier 3 skills")
	lu.assertEquals(opens(D.pilot({ missions = 3, won = 4, t3 = { 1, 2, 3, 4 } })), "m4_reward", "mission 4 won but unpaid: the reward comes first (D-5)")
end

-- G9-G12: the failure screens, in J3's order 4, 2, 3, 1
-- B-3, B-4
for _, row in ipairs({
	{ failed = 4, missions = 3, t3 = { 1, 2, 3 }, want = "m4_failed" },
	{ failed = 2, missions = 1, t3 = { 1 }, want = "m2_failed" },
	{ failed = 3, missions = 2, t3 = { 1, 2 }, want = "m3_failed" },
	{ failed = 1, missions = 0, t3 = {}, want = "m1_failed" },
}) do
	TestStormT3Gates["test_a_failed_mission_" .. row.failed .. "_opens_" .. row.want] = function()
		local o = { missions = row.missions, t3 = row.t3, failed = row.failed }

		lu.assertEquals(opens(D.pilot(o)), row.want, "mission " .. row.failed .. " attempted and not won or running")
	end
end

-- G9-G12: J3 checks 4, then 2, 3, 1
-- B-3
function TestStormT3Gates:test_several_failed_missions_open_the_failure_screens_in_the_order_4_2_3_1()
	local function openFor(list)
		local o = { attempted = nil }
		local player = D.pilot(o)

		for _, n in ipairs(list) do
			H.setQuestStatus(player, D.STATUS[n] .. ":attempted", 1)
		end

		return opens(player)
	end

	lu.assertEquals(openFor({ 2, 3 }), "m2_failed", "2 before 3")
	lu.assertEquals(openFor({ 3, 1 }), "m3_failed", "3 before 1")
	lu.assertEquals(openFor({ 1, 4 }), "m4_failed", "4 before 1")
	lu.assertEquals(openFor({ 2, 1 }), "m2_failed", "2 before 1")
	lu.assertEquals(openFor({ 1, 2, 3, 4 }), "m4_failed", "4 first of all")
end

-- G9-G12: a won or running mission is not failed, an aborted one (attempted, nothing else) is
-- B-3, B-4
function TestStormT3Gates:test_attempted_alone_is_failed_but_attempted_and_won_is_not()
	lu.assertEquals(opens(D.pilot({ attempted = 1 })), "m1_failed", "attempted, nothing complete or running")
	lu.assertEquals(opens(D.pilot({ won = 1 })), "m1_reward", "attempted and won: the reward, not the failure")
	lu.assertEquals(opens(D.pilot({ attempted = 1, active = D.M1[3] })), "on_mission", "attempted and running: on_mission (G7 precedes G9)")
end

-- G9-G12 precede the rewards and the offers
-- B-3
function TestStormT3Gates:test_the_failure_screens_precede_the_reward_and_offer_screens()
	local player = D.pilot({ won = 1, attempted = 2 })

	lu.assertEquals(opens(player), "m2_failed", "mission 1 won and unpaid, mission 2 attempted: G10 precedes G13")
end

-- G13-G16
-- B-3
for n = 1, 4 do
	TestStormT3Gates["test_mission_" .. n .. "_won_and_unpaid_with_fewer_than_" .. n .. "_skills_opens_m" .. n .. "_reward"] = function()
		lu.assertEquals(opens(D.rewardPilot(n)), "m" .. n .. "_reward", "mission " .. n .. " won, count " .. (n - 1))
	end

	-- the count rule (the 9034fa3254 rule): mission n paid with its skill unchosen reopens on the reward screen; no later offer comes first
	TestStormT3Gates["test_mission_" .. n .. "_paid_with_its_skill_unchosen_still_opens_m" .. n .. "_reward_before_any_later_offer"] = function()
		local player = D.pilot({ missions = n, t3 = D.t3(n - 1) })

		lu.assertEquals(opens(player), "m" .. n .. "_reward", "mission " .. n .. " paid, count " .. (n - 1))
	end
end

-- G13-G16: the smallest owed mission first
-- B-3
function TestStormT3Gates:test_the_smallest_owed_reward_screen_comes_first()
	local player = D.pilot({ won = 1 })

	for _, global in ipairs(D.CHAINS[2]) do
		D.setState(player, global, "complete")
	end

	lu.assertEquals(opens(player), "m1_reward", "missions 1 and 2 won, no skill chosen")
end

-- G17-G20, B-4: mission n+1 is offered only after mission n's skill is chosen
-- B-3, B-4
for n = 0, 3 do
	TestStormT3Gates["test_a_pilot_with_" .. n .. "_missions_won_and_" .. n .. "_skills_chosen_opens_m" .. (n + 1) .. "_offer"] = function()
		lu.assertEquals(opens(D.pilot({ missions = n, t3 = D.t3(n) })), "m" .. (n + 1) .. "_offer", n .. " missions paid, " .. n .. " skills")
	end
end

-- G17: a pilot with no tier 3 state at all
-- B-3
function TestStormT3Gates:test_a_pilot_with_no_quest_state_opens_the_first_offer_and_the_walk_greets_him()
	local t = D.talk(D.pilot({}))

	lu.assertEquals(D.ids(t), { "m1_offer" }, "first screen")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_e5e51881", "'Field Commander Alozen tells me that you're ready to serve under my command.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- G21: every pilot built above ends on a screen; a pilot who holds all four skills and has all four paid ends on tour_complete
-- B-3, B-7
function TestStormT3Gates:test_the_default_gate_is_tour_complete()
	lu.assertEquals(opens(D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 }, pilotTier = 3 })), "tour_complete", "all four won and paid, pilot tier not raised yet")
end

-- I-13: opening the conversation through the full session shows the same screen as getInitialScreen alone
-- B-3
function TestStormT3Gates:test_the_session_opens_on_the_screen_getInitialScreen_picks()
	local player = D.pilot({ missions = 2, t3 = { 1, 2 } })

	lu.assertEquals(D.firstScreen(player), "m3_offer", "session start")
	lu.assertEquals(opens(D.pilot({ missions = 2, t3 = { 1, 2 } })), "m3_offer", "getInitialScreen alone")
end
