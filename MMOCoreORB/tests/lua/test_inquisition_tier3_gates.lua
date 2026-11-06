-- Inquisitor Vrke: which screen a pilot opens on (gate table V), the refusal walks, the wanted dialogue, the Barlow hand-shake and the hand-off to tier 4.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-6, AC-10; Conversation flow 1; FV-2, FV-3, FV-4; D-4, D-5, D-6, D-8, D-14; I-12).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- inquisition_tier3_data.lua V.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys, count of _03 skills).
-- Default pilot: an Inquisition pilot with the four tier 1 and four tier 2 skills, Fa'Zoll's mission 4 paid, pilot tier 3, no tier 3 state.

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

V.load()

TestInquisitionT3Gates = {}

function TestInquisitionT3Gates:setUp()
	H.reset()
	V.requireConversation(lu)
end

local function opens(player) return V.firstScreen(player) end

local function handler() return rawget(_G, V.HANDLER) end

local function blackEpsilon() return rawget(_G, "BLACK_EPSILON_SQUADRON") end

-- V0
-- AC-6
function TestInquisitionT3Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = V.pilot(), V.npc(), H.conversationTemplate(V.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- V1 (D-14)
-- AC-6
function TestInquisitionT3Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(V.pilot()), "not_pilot", "JTL disabled")
end

-- AC-6
function TestInquisitionT3Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = V.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- V2 (FV-3)
-- AC-6
function TestInquisitionT3Gates:test_a_non_pilot_opens_the_three_line_not_pilot_chain_which_ends_on_the_last_line()
	local t = V.talk(V.pilot({ pilot = false, squadron = false, tier1 = 0, t2 = 0, t2paid4 = false }), { "s_5ff8baab", "s_60495432" })

	lu.assertEquals(V.ids(t), { "not_pilot", "not_pilot_57d96aed", "not_pilot_ed26944d" }, "non-pilot walk")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_e1b0c231", "'I have more important things to do right now than to speak with you.'")
	lu.assertTrue(t[3].stop, "not_pilot_ed26944d ends the conversation")
	lu.assertEquals(#t[3].options, 0, "the last line offers no reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- V2 (D-4): a Rebel-faction non-pilot is still a non-pilot
-- AC-6
function TestInquisitionT3Gates:test_a_rebel_faction_non_pilot_opens_not_pilot()
	lu.assertEquals(opens(V.pilot({ pilot = false, faction = "rebel", squadron = false, tier1 = 0, t2 = 0 })), "not_pilot", "Rebel-faction non-pilot")
	lu.assertEquals(opens(V.pilot({ pilot = false, faction = "neutral", squadron = false, tier1 = 0, t2 = 0 })), "not_pilot", "non-pilot without faction")
	lu.assertEquals(opens(V.pilot({ pilot = false, standing = -5, squadron = false, tier1 = 0, t2 = 0 })), "not_pilot", "V2 precedes the wanted gate")
end

-- V3 (FV-3)
-- AC-6
function TestInquisitionT3Gates:test_a_rebel_pilot_and_a_freelance_pilot_open_wrong_faction_which_ends_after_one_reply()
	local t = V.talk(V.pilot({ pilot = "rebel", faction = "rebel", squadron = false }), { "s_1f64a6b3" })

	lu.assertEquals(V.ids(t), { "wrong_faction", "wrong_faction_788cbcfb" }, "Rebel pilot walk")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_b6c9b83b", "'How did you get in here? ...'")
	lu.assertTrue(t[2].stop, "wrong_faction_788cbcfb ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(V.pilot({ pilot = "neutral", faction = "neutral", squadron = false })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(V.pilot({ pilot = "neutral", squadron = false })), "wrong_faction", "freelance pilot, Imperial faction")
	lu.assertEquals(opens(V.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "wrong_faction", "V3 precedes the wanted gate")
	lu.assertEquals(opens(V.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "wrong_faction", "Rebel pilot without faction")
end

-- V4
-- AC-6
function TestInquisitionT3Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track_whose_three_lines_end_the_conversation()
	local t = V.talk(V.pilot({ squadron = blackEpsilon() }), { "s_b48bd0a4", "s_e7435914" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_8f1228f6", "off_track_54e4328d" }, "Black Epsilon pilot walk")
	lu.assertTrue(t[3].stop, "off_track_54e4328d ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(opens(V.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "Storm Squadron pilot")
	lu.assertEquals(opens(V.pilot({ squadron = false })), "off_track", "Imperial pilot without a squadron")
	lu.assertEquals(opens(V.pilot({ squadron = blackEpsilon(), standing = -1 })), "off_track", "V4 precedes the wanted gate")
	lu.assertEquals(opens(V.pilot({ squadron = blackEpsilon(), t2paid4 = false })), "off_track", "V4 precedes not_ready")
	lu.assertEquals(opens(V.pilot({ squadron = false, datapad = "story" })), "off_track", "V4 precedes on_mission")
end

-- V5 (D-6)
-- AC-6
function TestInquisitionT3Gates:test_negative_imperial_standing_opens_wanted()
	lu.assertEquals(opens(V.pilot({ standing = -1 })), "wanted", "Inquisition pilot, standing -1")
	lu.assertEquals(opens(V.pilot({ standing = -1, t2paid4 = false })), "wanted", "V5 precedes not_ready")
	lu.assertEquals(opens(V.pilot({ standing = -1, mission = { [1] = "active" } })), "wanted", "V5 precedes on_mission")
	lu.assertEquals(opens(V.pilot({ standing = -1, datapad = "story" })), "wanted", "V5 precedes a datapad quest")
	lu.assertEquals(opens(V.pilot({ standing = 0 })), "m1_offer", "standing 0 is served normally")
end

-- V5 (D-6): a pilot whose Imperial faction is gone
-- AC-6
function TestInquisitionT3Gates:test_an_imperial_pilot_whose_faction_is_gone_opens_wanted()
	lu.assertEquals(opens(V.pilot({ faction = "neutral" })), "wanted", "standing 0, no faction")
	lu.assertEquals(opens(V.pilot({ faction = "rebel" })), "wanted", "standing 0, Rebel faction")
	lu.assertEquals(opens(V.pilot({ faction = "neutral", t2paid4 = false })), "wanted", "V5 precedes not_ready")
	lu.assertEquals(opens(V.pilot({ faction = "neutral", paid = { 1 }, t3 = { 1 } })), "wanted", "V5 precedes the later gates")
end

-- AC-6: the wanted walk leads through its three lines and grants nothing
function TestInquisitionT3Gates:test_the_wanted_walk_runs_its_three_lines_with_the_name_and_grants_nothing()
	local player = V.pilot({ standing = -3 })
	local t = V.talk(player, { "s_dbd88d67", "s_77e48d5b" })

	lu.assertEquals(V.ids(t), { "wanted", "wanted_14ef7b20", "wanted_29eb9a6b" }, "screens shown")
	lu.assertTrue(t[3].stop, "wanted_29eb9a6b ends the conversation")
	lu.assertEquals(t[3].params.TU, "Ace", "wanted_29eb9a6b: %TU")
	lu.assertEquals(#V.free() + #V.bought(), 0, "no skill granted")
	lu.assertEquals(#V.items(player), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- AC-6: the gate lifts at 0
function TestInquisitionT3Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = V.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "m1_offer", "standing 0")
end

-- V6 (D-5, FV-4)
-- AC-6
function TestInquisitionT3Gates:test_tier_2_without_fa_zolls_mission_4_paid_or_with_a_skill_missing_opens_not_ready()
	lu.assertEquals(opens(V.pilot({ t2paid4 = false })), "not_ready", "all four _02 skills, Fa'Zoll's mission 4 unpaid")
	lu.assertEquals(opens(V.pilot({ t2 = 3 })), "not_ready", "mission 4 paid, three _02 skills")
	lu.assertEquals(opens(V.pilot({ t2 = 0 })), "not_ready", "mission 4 paid, no _02 skill")
	lu.assertEquals(opens(V.pilot({ t2 = 0, t2paid4 = false, tier1 = 4 })), "not_ready", "a tier 1 graduate")
	lu.assertEquals(opens(V.pilot({ t2paid4 = false, datapad = "story" })), "not_ready", "V6 precedes on_mission")
	lu.assertEquals(opens(V.pilot({ t2 = 3, mission = { [1] = "failed" } })), "not_ready", "V6 precedes the failure screens")
end

-- AC-6: the not_ready walks
function TestInquisitionT3Gates:test_the_not_ready_walks_run_to_their_two_endings()
	local t = V.talk(V.pilot({ t2paid4 = false }), { "s_8367fc83", "s_268fe491" })

	lu.assertEquals(V.ids(t), { "not_ready", "not_ready_f3a00a53", "not_ready_b9fc0fde" }, "first walk")
	lu.assertTrue(t[3].stop, "not_ready_b9fc0fde ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	local t2 = V.talk(V.pilot({ t2paid4 = false }), { "s_1ba9577c" })

	lu.assertEquals(V.ids(t2), { "not_ready", "not_ready_3c1e05f" }, "second walk")
	lu.assertTrue(t2[2].stop, "not_ready_3c1e05f ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t2), {}, "client strings")
end

-- AC-6: the pair Fa'Zoll hands over with is exactly the pair Vrke accepts (D-5)
function TestInquisitionT3Gates:test_a_pilot_ready_by_fa_zolls_rule_is_not_sent_back()
	lu.assertEquals(opens(V.pilot({ t2 = 4, t2paid4 = true })), "m1_offer", "tier 2 done, mission 4 paid")
	lu.assertEquals(opens(V.pilot({ t2 = 4, t2paid4 = true, xp = 500000 })), "m1_offer", "with XP to spare")
	lu.assertEquals(opens(V.pilot({ t2 = 4, t2paid4 = true, series = false, agent = false })), "m1_offer", "Barn's and Fa'Zoll's flags are not read")
end

-- V7
-- AC-6
function TestInquisitionT3Gates:test_a_running_mission_or_any_datapad_space_quest_opens_on_mission()
	for n = 1, 4 do
		local paid = {}

		for k = 1, n - 1 do
			paid[k] = k
		end

		lu.assertEquals(opens(V.pilot({ paid = paid, t3 = (n > 1) and { 1 } or nil, mission = { [n] = "active" }, question = false })), "on_mission", "mission " .. n .. " active")
	end

	lu.assertEquals(opens(V.pilot({ duty = V.M2[3] })), "on_mission", "a middle member of mission 2's chain active (the chain is running, not just its head)")
	lu.assertEquals(opens(V.pilot({ duty = V.M3[5] })), "on_mission", "the last member of mission 3's chain active")
	lu.assertEquals(opens(V.pilot({ datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(V.pilot({ datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(V.pilot({ paid = { 1 }, t3 = { 1 }, datapad = "duty" })), "on_mission", "V7 precedes the offers")
	lu.assertEquals(opens(V.pilot({ mission = { [1] = "won" }, datapad = "story" })), "on_mission", "V7 precedes the reward screens")
	lu.assertEquals(opens(V.pilot({ mission = { [1] = "failed" }, datapad = "story" })), "on_mission", "V7 precedes the failure screens")
	lu.assertTrue(handler():isOnMission(V.pilot({ mission = { [3] = "active" } })), "isOnMission: mission 3 active")
	lu.assertFalse(handler():isOnMission(V.pilot({ mission = { [3] = "won" } })), "isOnMission: a won mission is not a running one")
end

-- V8-V11
-- AC-6, AC-7
function TestInquisitionT3Gates:test_a_mission_attempted_and_not_won_or_running_opens_its_failed_screen()
	local skillsFor = { [1] = {}, [2] = { 1 }, [3] = { 1, 2 }, [4] = { 1, 2, 3 } }

	for n = 1, 4 do
		local paid = {}

		for k = 1, n - 1 do
			paid[k] = k
		end

		local mk = function(state) return V.pilot({ paid = paid, t3 = skillsFor[n], mission = { [n] = state } }) end

		lu.assertEquals(opens(mk("failed")), "m" .. n .. "_failed", "mission " .. n .. " attempted, nothing complete")
		lu.assertEquals(opens(mk("attempted")), "m" .. n .. "_failed", "mission " .. n .. ": an abort leaves just :attempted, which counts as failed")
		lu.assertEquals(opens(mk("partial")), "m" .. n .. "_failed", "mission " .. n .. ": the head complete but not the chain end counts as failed")
	end

	-- a different mission's failure outranks a pending reward of another? the failure screens come first (V8-V11 precede V12-V15)
	lu.assertEquals(opens(V.pilot({ mission = { [1] = "won", [2] = "failed" }, t3 = { 1 } })), "m2_failed", "V8-V11 precede V12-V15: mission 2 failed while 1 is won")
end

-- V12-V15 (J3 collectingQuestNReward; HS D-5)
-- AC-6, AC-8
function TestInquisitionT3Gates:test_a_won_mission_with_fewer_than_n_tier_3_skills_opens_its_reward_screen()
	lu.assertEquals(opens(V.pilot({ mission = { [1] = "won" } })), "m1_reward", "M1 won, no _03 skill")
	lu.assertEquals(opens(V.pilot({ paid = { 1 }, t3 = {}, question = false })), "m1_reward", "M1 paid but the skill not chosen: the reward screen comes again")
	lu.assertEquals(opens(V.pilot({ paid = { 1 }, t3 = { 1 }, mission = { [2] = "won" }, question = false, spoke = true })), "m2_reward", "M2 won, one skill")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2 }, t3 = { 1, 2 }, mission = { [3] = "won" }, spoke = true })), "m3_reward", "M3 won, two skills")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2, 3 }, mission = { [4] = "won" }, spoke = true })), "m4_reward", "M4 won, three skills")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2, 3, 4 }, mission = { [4] = "won" }, spoke = true })), "m4_reward", "M4 won and unpaid, four skills: the reward still comes first (V15 widened)")
	lu.assertEquals(opens(V.pilot({ mission = { [1] = "won" }, question = true, t3 = { 1 } })), "barlow_pending", "M1 won, one skill, question set: no reward screen (count >= n)")
end

-- V12-V15: the 9034fa3254 rule, both ways round
-- AC-6, AC-7
function TestInquisitionT3Gates:test_a_won_mission_is_never_hidden_by_a_later_offer_and_the_next_offer_waits_for_the_skill()
	lu.assertEquals(opens(V.pilot({ paid = { 1 }, t3 = {}, question = true })), "m1_reward", "M1 paid, skill unchosen, question set: the reward screen, not barlow_pending")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2 }, t3 = { 1 }, spoke = true })), "m2_reward", "M2 won and paid, only one skill: not m3_offer")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2 }, spoke = true })), "m3_reward", "M3 won and paid, two skills: not m4_offer")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3 }, spoke = true })), "m4_reward", "M4 won and paid, three skills: not tour_complete")
end

-- V16 / V18-V20
-- AC-6, AC-7
function TestInquisitionT3Gates:test_the_offers_open_when_the_previous_mission_is_paid_and_its_skill_chosen()
	local t = V.talk(V.pilot({}))

	lu.assertEquals(V.ids(t), { "m1_offer" }, "tier 2 done, nothing started")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_5d47c3ad", "'I understand you served under Inquisitor Fa'Zoll.'")
	lu.assertEquals(V.optionSids(t[1]), { "s_4d169c0a", "s_8d10c144" }, "m1_offer replies")
	lu.assertEquals(opens(V.pilot({ paid = { 1 }, t3 = { 1 }, spoke = true })), "m2_offer", "M1 paid, one skill, Barlow done")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2 }, t3 = { 1, 2 }, spoke = true })), "m3_offer", "M2 paid, two skills")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2, 3 }, spoke = true })), "m4_offer", "M3 paid, three skills")
end

-- V21 (AC-10)
-- AC-6, AC-10
function TestInquisitionT3Gates:test_all_four_missions_won_and_paid_with_four_skills_opens_tour_complete()
	local player = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, pilotTier = 3 })
	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "tour_complete" }, "everything done")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_b41ba13c", "'And so, our time together is done.'")
	lu.assertEquals(V.optionSids(t[1]), { "s_23e0dd3", "s_9b43a7ee" }, "tour_complete replies")
	lu.assertEquals(V.linksOf(t[1]), { "jace_unfortunate", "jace_elders" }, "tour_complete links")
	lu.assertEquals(opens(V.pilot({ mission = { [4] = "won" }, paid = { 1, 2, 3 }, t3 = { 1, 2, 3, 4 } })), "m4_reward", "M4 won and unpaid: tour_complete needs paid(4)")
end

-- AC-6: every gate screen exists in the template and in Appendix A
function TestInquisitionT3Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(V.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_pilot", "wrong_faction", "off_track", "wanted", "not_ready", "on_mission", "m1_failed", "m2_failed", "m3_failed", "m4_failed", "m1_reward", "m2_reward",
		"m3_reward", "m4_reward", "m1_offer", "barlow_pending", "m2_offer", "m3_offer", "m4_offer", "tour_complete" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(V.TEMPLATE)):getScreen(id), V.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

---------------------------------------------------------------------------------------------
-- I-12: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestInquisitionT3PureGates = {}

function TestInquisitionT3PureGates:setUp()
	H.reset()
	V.requireConversation(lu)
end

local function handlerOf() return rawget(_G, V.HANDLER) end

local function effects(player)
	local out = {}

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip", "createEvent", "createObserver" }) do
		out[fn] = #H.Engine.callsTo(fn)
	end

	out.bank = player.bankCredits
	out.standing = player.ghost and player.ghost.factionStanding.imperial
	out.squadron = player.ghost and player.ghost.squadronType
	out.pilotTier = player.ghost and player.ghost.pilotTier

	for _, suffix in ipairs(V.KEYS) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	for _, suffix in ipairs({ V.QUESTION_SUFFIX, V.SPOKE_SUFFIX, V.SERIES_SUFFIX, V.AGENT_SUFFIX, V.TIER2_M4_REWARD }) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	for _, skill in ipairs(V.TIER1_SKILLS) do
		out[skill] = CreatureObject(player):hasSkill(skill)
	end

	for _, skill in ipairs(V.TIER2_SKILLS) do
		out[skill] = CreatureObject(player):hasSkill(skill)
	end

	for _, t in ipairs(V.TRAIN) do
		out[t.skill] = CreatureObject(player):hasSkill(t.skill)
	end

	for _, global in ipairs(V.GLOBALS) do
		out[global] = V.state(player, global)
	end

	return out
end

-- I-12, AC-6
function TestInquisitionT3PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return V.pilot() end,
		function() return V.pilot({ pilot = false, squadron = false, tier1 = 0, t2 = 0 }) end,
		function() return V.pilot({ pilot = "rebel", faction = "rebel", squadron = false }) end,
		function() return V.pilot({ pilot = "neutral", squadron = false }) end,
		function() return V.pilot({ squadron = blackEpsilon() }) end,
		function() return V.pilot({ squadron = false }) end,
		function() return V.pilot({ standing = -1 }) end,
		function() return V.pilot({ faction = "neutral" }) end,
		function() return V.pilot({ t2paid4 = false }) end,
		function() return V.pilot({ t2 = 3 }) end,
		function() return V.pilot({ mission = { [1] = "active" } }) end,
		function() return V.pilot({ datapad = "story" }) end,
		function() return V.pilot({ mission = { [1] = "failed" } }) end,
		function() return V.pilot({ mission = { [1] = "won" } }) end,
		function() return V.pilot({ paid = { 1 }, t3 = { 1 }, question = true }) end,
		function() return V.pilot({ paid = { 1 }, t3 = { 1 }, spoke = true }) end,
		function() return V.pilot({ paid = { 1 }, t3 = {} }) end,
		function() return V.pilot({ paid = { 1 }, t3 = { 1 }, mission = { [2] = "won" }, spoke = true }) end,
		function() return V.pilot({ paid = { 1 }, t3 = { 1 }, mission = { [2] = "failed" }, spoke = true }) end,
		function() return V.pilot({ paid = { 1, 2 }, t3 = { 1, 2 }, spoke = true }) end,
		function() return V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2, 3 }, spoke = true }) end,
		function() return V.pilot({ paid = { 1, 2, 3 }, mission = { [4] = "won" }, t3 = { 1, 2, 3, 4 }, spoke = true }) end,
		function() return V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true }) end,
		function() return V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true, pilotTier = 3 }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local before = effects(player)
		local screen = handlerOf():getInitialScreen(player, V.npc(), H.conversationTemplate(V.TEMPLATE))

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertEquals(effects(player), before, "pilot " .. i .. " (" .. tostring(screen and screen.id) .. "): getInitialScreen changed state")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: the Barlow hand-shake and the hand-off to tier 4
---------------------------------------------------------------------------------------------

TestInquisitionT3Barlow = {}

function TestInquisitionT3Barlow:setUp()
	H.reset()
	V.requireConversation(lu)
end

-- V17
-- AC-10
function TestInquisitionT3Barlow:test_with_mission_1_won_one_skill_and_the_question_key_the_first_screen_is_barlow_pending()
	local player = V.pilot({ paid = { 1 }, t3 = { 1 }, question = true })
	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "barlow_pending" }, "first screen")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_577a942", "'Have you finished your questioning of Lieutenant Colonel Barlow about Colonel Hend?'")
	lu.assertEquals(V.optionSids(t[1]), { "s_e35bf94e", "s_69d78804" }, "barlow_pending replies")
	lu.assertEquals(V.linksOf(t[1]), { "barlow_pending_53d34239", "barlow_pending_370a9fe4" }, "barlow_pending links")
end

-- AC-10: both replies end without changing state
function TestInquisitionT3Barlow:test_both_replies_of_barlow_pending_end_the_conversation_without_changing_state()
	local walks = {
		{ { "s_e35bf94e" }, { "barlow_pending", "barlow_pending_53d34239" } },
		{ { "s_69d78804", "s_bca78274" }, { "barlow_pending", "barlow_pending_370a9fe4", "barlow_pending_6ffd0979" } },
	}

	for i, w in ipairs(walks) do
		H.reset()

		local player = V.pilot({ paid = { 1 }, t3 = { 1 }, question = true })
		local before = effects(player)
		local t = V.talk(player, w[1])

		lu.assertEquals(V.ids(t), w[2], "walk " .. i .. ": screens shown")
		lu.assertTrue(t[#t].stop, "walk " .. i .. ": " .. t[#t].id .. " ends the conversation")
		lu.assertEquals(effects(player), before, "walk " .. i .. ": state is unchanged")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "walk " .. i .. ": client strings")
	end
end

-- V17 / V18 (Barlow's effect, set by the test)
-- AC-10
function TestInquisitionT3Barlow:test_with_the_question_key_cleared_and_the_spoke_key_set_the_first_screen_is_m2_offer()
	local player = V.pilot({ paid = { 1 }, t3 = { 1 }, question = true })

	lu.assertEquals(opens(player), "barlow_pending", "before Barlow")

	-- Barlow's interview: clears QUESTION_BARLOW_KEY and sets SPOKE_TO_BARLOW_KEY
	removeQuestStatus(player.objectID .. V.QUESTION_SUFFIX)
	setQuestStatus(player.objectID .. V.SPOKE_SUFFIX, 1)

	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "m2_offer" }, "after Barlow")
	lu.assertEquals(t[1].text, V.PREFIX .. "s_b1d44e0a", "'So what did you learn from Barlow?'")
end

-- AC-10: mission 1 not won ignores the question key (V16 precedes V17)
function TestInquisitionT3Barlow:test_the_question_key_does_not_matter_before_mission_1_is_won()
	lu.assertEquals(opens(V.pilot({ question = true })), "m1_offer", "question set, mission 1 not started")
end

-- AC-10
function TestInquisitionT3Barlow:test_tour_complete_shows_only_when_mission_4_is_paid()
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3 }, mission = { [4] = "won" }, t3 = { 1, 2, 3, 4 } })), "m4_reward", "M4 unpaid")
	lu.assertEquals(opens(V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 } })), "tour_complete", "M4 paid")
end

-- AC-10: tour_complete clears the spoke key and raises the pilot to tier 4
function TestInquisitionT3Barlow:test_tour_complete_clears_the_spoke_key_and_raises_a_tier_3_pilot_with_four_skills_to_tier_4()
	local player = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true, question = false, pilotTier = 3 })

	lu.assertTrue(V.hasKey(player, V.SPOKE_SUFFIX), "precondition: the spoke key is set")

	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "tour_complete" }, "screens shown")
	lu.assertFalse(V.hasKey(player, V.SPOKE_SUFFIX), "the spoke key is cleared (SWG removeTalkedToBarlow)")
	lu.assertNil(H.getQuestStatus(player, V.SPOKE_SUFFIX), "the spoke key is removed")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier 3 -> 4")

	-- a second visit does not raise it again
	V.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier stays 4")
end

-- AC-10 (HS D-10): a pilot already at tier 4 or above is not raised again, a tier 2 pilot is not raised by tour_complete
function TestInquisitionT3Barlow:test_tour_complete_raises_the_tier_only_when_it_is_3_or_less_and_all_four_skills_are_held()
	local p4 = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, pilotTier = 4 })

	V.talk(p4)
	lu.assertEquals(p4.ghost.pilotTier, 4, "tier 4 stays 4")

	local p5 = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, pilotTier = 5 })

	V.talk(p5)
	lu.assertEquals(p5.ghost.pilotTier, 5, "tier 5 stays 5")
end

-- AC-10: the two hand-off lines name Grand Inquisitor Ja'ce Yiaso and end the conversation
function TestInquisitionT3Barlow:test_the_two_replies_end_on_jace_unfortunate_and_jace_elders()
	local player = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true })
	local t1 = V.talk(player, { "s_23e0dd3" })

	lu.assertEquals(V.ids(t1), { "tour_complete", "jace_unfortunate" }, "first reply")
	lu.assertTrue(t1[2].stop, "jace_unfortunate ends the conversation")
	lu.assertStrContains(require("inquisition_tier3_client_text")[V.screenRow("jace_unfortunate").sid], "Ja'ce Yiaso", false, "the line names Grand Inquisitor Ja'ce Yiaso")
	lu.assertEquals(CS.transcriptUnresolved(t1), {}, "client strings")

	local t2 = V.talk(V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true }), { "s_9b43a7ee" })

	lu.assertEquals(V.ids(t2), { "tour_complete", "jace_elders" }, "second reply")
	lu.assertTrue(t2[2].stop, "jace_elders ends the conversation")
	lu.assertEquals(t2[2].params.TU, "Ace", "jace_elders: %NU")
	lu.assertEquals(CS.transcriptUnresolved(t2), {}, "client strings")
end
