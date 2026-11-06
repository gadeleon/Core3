-- Inquisitor Fa'Zoll: which screen a pilot opens on (gate table F), the conditional links C-1 and C-2, the wanted dialogue and the off-track closure.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-6; Conversation flow 1 and 2; FF-7, FF-8; D-4, D-5, D-7, D-8, D-16, D-19; I-11, I-12).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- inquisition_tier2_data.lua I.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).
-- Default pilot: an Inquisition pilot with the four tier 1 skills, pilot tier 2, Barn's series flag and Fa'Zoll's agent flag.

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")

I.load()

local COST = I.TRAINING_COST

TestInquisitionT2Gates = {}

function TestInquisitionT2Gates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function opens(player) return I.firstScreen(player) end

local function handler() return rawget(_G, I.HANDLER) end

local BLACK_EPSILON = function() return rawget(_G, "BLACK_EPSILON_SQUADRON") end

-- F0
-- AC-6
function TestInquisitionT2Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = I.pilot(), I.npc(), H.conversationTemplate(I.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- F1 (D-16)
-- AC-6
function TestInquisitionT2Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(I.pilot()), "not_pilot", "JTL disabled")
end

-- AC-6
function TestInquisitionT2Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = I.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- F2
-- AC-6
function TestInquisitionT2Gates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = I.talk(I.pilot({ pilot = false, squadron = false, t1 = false }))

	lu.assertEquals(I.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, I.PREFIX .. "s_21772e5a", "'I'm sorry, I can't help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- F3 (D-4)
-- AC-6
function TestInquisitionT2Gates:test_rebel_faction_or_a_rebel_pilot_opens_not_pilot()
	lu.assertEquals(opens(I.pilot({ pilot = false, faction = "rebel", squadron = false, t1 = false })), "not_pilot", "Rebel-faction non-pilot")
	lu.assertEquals(opens(I.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "not_pilot", "Rebel pilot")
	lu.assertEquals(opens(I.pilot({ faction = "rebel" })), "not_pilot", "Inquisition pilot with Rebel faction")
	lu.assertEquals(opens(I.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "not_pilot", "Rebel pilot with Rebel faction")
end

-- F4 (D-4)
-- AC-6
function TestInquisitionT2Gates:test_a_privateer_opens_not_pilot()
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false })), "not_pilot", "privateer, Imperial faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "not_pilot", "privateer, no faction")
	lu.assertEquals(opens(I.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "not_pilot", "F4 precedes the wanted gate")
end

-- F5 (D-5, FF-7)
-- AC-6
function TestInquisitionT2Gates:test_negative_imperial_standing_opens_wanted()
	lu.assertEquals(opens(I.pilot({ standing = -1 })), "wanted", "Inquisition pilot, standing -1")
	lu.assertEquals(opens(I.pilot({ standing = -1, squadron = false })), "wanted", "F5 precedes the track check")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 1, state = "active" })), "wanted", "F5 precedes on_mission")
	lu.assertEquals(opens(I.pilot({ standing = -1, paid = 4, t2 = { 1, 2, 3, 4 } })), "wanted", "F5 precedes report_to_vrke")
	lu.assertEquals(opens(I.pilot({ standing = 0 })), "m1_offer", "standing 0 is served normally")
end

-- F5 (D-5): a pilot whose faction is gone
-- AC-6
function TestInquisitionT2Gates:test_an_imperial_pilot_whose_faction_is_gone_opens_wanted()
	lu.assertEquals(opens(I.pilot({ faction = "neutral" })), "wanted", "standing 0, no faction")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", squadron = false })), "wanted", "a pilot of no squadron without Imperial faction: F5 precedes F6")
	lu.assertEquals(opens(I.pilot({ faction = "neutral", paid = 3, state = "won" })), "wanted", "F5 precedes m4_won")
end

-- AC-6: the wanted walk leads through its five lines and grants nothing
function TestInquisitionT2Gates:test_the_wanted_walk_runs_its_five_lines_with_the_name_and_grants_nothing()
	local player = I.pilot({ standing = -3 })
	local t = I.talk(player, { "s_2313ac9e", "s_97222fa4", "s_a7cceea9", "s_f8b02865", "s_1ad5c0e0" })

	lu.assertEquals(I.ids(t), { "wanted", "wanted_not_trusted", "wanted_defected", "wanted_redeem", "wanted_two_things", "wanted_go_away" }, "screens shown")
	lu.assertTrue(t[6].stop, "wanted_go_away ends the conversation")
	lu.assertEquals(t[2].params.TU, "Ace", "wanted_not_trusted: %TU")
	lu.assertEquals(t[5].params.TU, "Ace", "wanted_two_things: %TU")
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- AC-6: the gate lifts at 0
function TestInquisitionT2Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = I.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "m2_offer", "standing 0")
end

-- F6
-- AC-6
function TestInquisitionT2Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track()
	lu.assertEquals(opens(I.pilot({ squadron = BLACK_EPSILON() })), "off_track", "Black Epsilon pilot")
	lu.assertEquals(opens(I.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "Storm Squadron pilot")
	lu.assertEquals(opens(I.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(I.pilot({ squadron = false, paid = 4, t2 = { 1, 2, 3, 4 } })), "off_track", "F6 precedes report_to_vrke")
	lu.assertEquals(opens(I.pilot({ squadron = false, datapad = "story" })), "off_track", "F6 precedes on_mission")
end

-- F7
-- AC-6
function TestInquisitionT2Gates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	lu.assertEquals(opens(I.pilot({ state = "active" })), "on_mission", "mission 1 active")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "active", t2 = { 1 } })), "on_mission", "mission 3 active")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "active", t2 = { 1, 2, 3, 4 } })), "on_mission", "mission 4 active")
	lu.assertEquals(opens(I.pilot({ paid = 2, duty = I.DUTY1 })), "on_mission", "recovery duty active")
	lu.assertEquals(opens(I.pilot({ paid = 2, duty = I.DUTY2 })), "on_mission", "escort duty active")
	lu.assertEquals(opens(I.pilot({ paid = 2, duty = I.DUTY3 })), "on_mission", "destroy duty active")
	lu.assertEquals(opens(I.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(I.pilot({ paid = 2, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(I.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
	lu.assertEquals(opens(I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 }, datapad = "duty" })), "on_mission", "F7 precedes report_to_vrke")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", datapad = "story" })), "on_mission", "F7 precedes m4_won")
end

-- F8
-- AC-6, AC-11
function TestInquisitionT2Gates:test_tier_2_done_and_mission_4_paid_opens_report_to_vrke()
	local t = I.talk(I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 } }))

	lu.assertEquals(I.ids(t), { "report_to_vrke" }, "tier 2 done, mission 4 paid")
	lu.assertEquals(I.optionSids(t[1]), { "s_3ba5368f", "s_f2cf68b3" }, "report_to_vrke replies")
	lu.assertEquals(I.linksOf(t[1]), { "vrke_goodbye", "vrke_dont_wait" }, "report_to_vrke links")
	lu.assertEquals(opens(I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 }, xp = 500000 })), "report_to_vrke", "with XP to spare")
	lu.assertEquals(opens(I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 }, agent = false })), "report_to_vrke", "F8 precedes the sign-up gates")
end

-- F9 (D-19)
-- AC-6, AC-11
function TestInquisitionT2Gates:test_mission_4_won_and_unpaid_opens_m4_won_with_or_without_all_the_skills()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", t2 = { 1, 2, 3, 4 } })), "m4_won", "all four skills")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", t2 = { 1, 2 } })), "m4_won", "two skills: F9 precedes the training gates")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", agent = false })), "m4_won", "F9 precedes the sign-up gates")
end

-- F10
-- AC-6, AC-8
function TestInquisitionT2Gates:test_mission_4_attempted_and_not_won_opens_m4_failed()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "failed", t2 = { 1, 2, 3, 4 } })), "m4_failed", "attempted, nothing complete, nothing active")
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "attempted", t2 = { 1, 2, 3, 4 } })), "m4_failed", "an abort leaves just :attempted, which counts as failed")
end

-- F11 (D-7, D-19)
-- AC-6, AC-11
function TestInquisitionT2Gates:test_all_four_skills_and_mission_3_paid_open_m4_offer()
	lu.assertEquals(opens(I.pilot({ paid = 3, t2 = { 1, 2, 3, 4 } })), "m4_offer", "all four skills, M3 paid")
end

-- F11: the 9034fa3254 rule, both ways round
-- AC-6
function TestInquisitionT2Gates:test_all_four_skills_with_mission_3_unpaid_do_not_open_m4_offer()
	local player = I.pilot({ paid = 2, t2 = { 1, 2, 3, 4 } })

	lu.assertEquals(opens(player), "m3_offer", "four skills, M2 paid, M3 not started")
	lu.assertNotEquals(opens(I.pilot({ paid = 2, state = "won", t2 = { 1, 2, 3, 4 } })), "m4_offer", "four skills, M3 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "won", t2 = { 1, 2, 3, 4 } })), "m3_won", "the won screen comes first")
end

-- F12
-- AC-6
function TestInquisitionT2Gates:test_mission_3_paid_without_all_four_skills_opens_duty_after_m3()
	lu.assertEquals(opens(I.pilot({ paid = 3, t2 = { 1, 2, 3 } })), "duty_after_m3", "three skills")
	lu.assertEquals(opens(I.pilot({ paid = 3, t2 = { 1 }, xp = COST })), "duty_after_m3", "one skill, XP for the next: F12 precedes the training offer")
end

-- F13 / F14
-- AC-6, AC-8
function TestInquisitionT2Gates:test_mission_3_won_and_unpaid_or_failed_open_their_screens()
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "won", t2 = { 1 } })), "m3_won", "M3 won, unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "failed", t2 = { 1 } })), "m3_failed", "M3 attempted, nothing complete")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "won", t2 = { 1 }, xp = COST })), "m3_won", "F13 precedes the training offer")
end

-- F15 (D-7)
-- AC-6
function TestInquisitionT2Gates:test_a_tier_2_skill_with_mission_2_paid_opens_m3_offer()
	for i = 1, 4 do
		lu.assertEquals(opens(I.pilot({ paid = 2, t2 = { i } })), "m3_offer", "holding only skill " .. I.TRAIN[i].x)
	end

	lu.assertEquals(opens(I.pilot({ paid = 2, t2 = { 1, 2, 3 } })), "m3_offer", "three skills, M3 not started")
end

-- F15: a skill held with M2 unpaid does not open m3_offer
-- AC-6
function TestInquisitionT2Gates:test_a_tier_2_skill_held_with_mission_2_unpaid_does_not_open_m3_offer()
	lu.assertEquals(opens(I.pilot({ paid = 1, t2 = { 1 } })), "m2_offer", "M1 paid, M2 not started")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "won", t2 = { 1 } })), "m2_won", "M2 won and unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "failed", t2 = { 2 } })), "m2_failed", "M2 failed")
end

-- F16
-- AC-6, AC-10
function TestInquisitionT2Gates:test_mission_2_paid_and_the_xp_for_a_first_skill_open_the_training_offer()
	local t = I.talk(I.pilot({ paid = 2, xp = COST }))

	lu.assertEquals(I.ids(t), { "training_offer" }, "M2 paid, no tier 2 skill, 60000 XP")
	lu.assertEquals(I.optionSids(t[1]), { "s_c1bc23b4" }, "training_offer reply")
	lu.assertEquals(I.linksOf(t[1]), { "training_menu" }, "training_offer link")
	lu.assertEquals(opens(I.pilot({ paid = 2, xp = 10 * COST })), "training_offer", "plenty of XP")
end

-- F16 / F17
-- AC-6, AC-10
function TestInquisitionT2Gates:test_mission_2_paid_with_too_little_xp_or_no_tier_1_opens_the_duty_screen()
	lu.assertEquals(opens(I.pilot({ paid = 2, xp = COST - 1 })), "duty_after_m2", "59999 XP")
	lu.assertEquals(opens(I.pilot({ paid = 2 })), "duty_after_m2", "no XP")
	lu.assertEquals(opens(I.pilot({ paid = 2, xp = COST, t1 = false })), "duty_after_m2", "tier 1 not complete: not ready for training")
	lu.assertEquals(opens(I.pilot({ paid = 2, xp = COST, skills = { I.TIER1_SKILLS[1] }, t1 = false })), "duty_after_m2", "one tier 1 skill only")
end

-- F18 / F19
-- AC-6, AC-8
function TestInquisitionT2Gates:test_mission_2_won_and_unpaid_or_failed_open_their_screens()
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "won" })), "m2_won", "M2 won, unpaid")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "failed" })), "m2_failed", "M2 attempted, nothing complete")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "attempted" })), "m2_failed", "an abort from the datapad counts as failed")
end

-- F20
-- AC-6
function TestInquisitionT2Gates:test_mission_1_paid_opens_m2_offer()
	lu.assertEquals(opens(I.pilot({ paid = 1 })), "m2_offer", "M1 paid")
end

-- F21 / F22 / F23
-- AC-6, AC-8
function TestInquisitionT2Gates:test_mission_1_won_failed_or_not_started_open_their_screens()
	lu.assertEquals(opens(I.pilot({ state = "won" })), "m1_won", "M1 won, unpaid")
	lu.assertEquals(opens(I.pilot({ state = "failed" })), "m1_failed", "M1 attempted, nothing complete")
	lu.assertEquals(opens(I.pilot({})), "m1_offer", "signed up, nothing started")
	lu.assertEquals(opens(I.pilot({ state = "won", agent = false })), "m1_won", "F21 precedes the sign-up gate")
end

-- F23 / F24
-- AC-6, AC-7
function TestInquisitionT2Gates:test_without_the_agent_flag_the_pilot_opens_the_greeting()
	lu.assertEquals(opens(I.pilot({ agent = false })), "greeting", "graduate of Barn, not yet signed up")
	lu.assertEquals(opens(I.pilot({ agent = false, series = false })), "greeting", "no series flag either")
end

-- AC-6: every gate screen exists in the template and in Appendix A
function TestInquisitionT2Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(I.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_pilot", "wanted", "off_track", "on_mission", "report_to_vrke", "m4_won", "m4_failed", "m4_offer", "duty_after_m3", "m3_won", "m3_failed", "m3_offer",
		"training_offer", "duty_after_m2", "m2_won", "m2_failed", "m2_offer", "m1_won", "m1_failed", "m1_offer", "greeting" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(I.TEMPLATE)):getScreen(id), I.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

-- AC-6: every won-and-unpaid mission reaches its won screen before any later offer (the 9034fa3254 rule)
function TestInquisitionT2Gates:test_a_won_mission_is_never_hidden_by_a_later_offer()
	lu.assertEquals(opens(I.pilot({ paid = 3, state = "won", t2 = { 1, 2, 3, 4 } })), "m4_won", "M4")
	lu.assertEquals(opens(I.pilot({ paid = 2, state = "won", t2 = { 1, 2, 3, 4 } })), "m3_won", "M3")
	lu.assertEquals(opens(I.pilot({ paid = 1, state = "won", t2 = { 1 } })), "m2_won", "M2")
	lu.assertEquals(opens(I.pilot({ state = "won", agent = true })), "m1_won", "M1")
end

---------------------------------------------------------------------------------------------
-- I-11: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestInquisitionT2PureGates = {}

function TestInquisitionT2PureGates:setUp()
	H.reset()
	I.requireConversation(lu)
end

local function effects(player)
	local out = {}

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip", "createEvent", "createObserver" }) do
		out[fn] = #H.Engine.callsTo(fn)
	end

	out.bank = player.bankCredits
	out.standing = player.ghost and player.ghost.factionStanding.imperial
	out.squadron = player.ghost and player.ghost.squadronType
	out.pilotTier = player.ghost and player.ghost.pilotTier

	for _, suffix in ipairs(I.statusKeys()) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	out[I.SERIES_SUFFIX] = H.getQuestStatus(player, I.SERIES_SUFFIX)
	out[I.AGENT_SUFFIX] = H.getQuestStatus(player, I.AGENT_SUFFIX)

	for _, skill in ipairs(I.TIER1_SKILLS) do
		out[skill] = CreatureObject(player):hasSkill(skill)
	end

	for _, t in ipairs(I.TRAIN) do
		out[t.skill] = CreatureObject(player):hasSkill(t.skill)
	end

	return out
end

-- I-11, AC-6
function TestInquisitionT2PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return I.pilot() end,
		function() return I.pilot({ agent = false }) end,
		function() return I.pilot({ agent = false, series = false }) end,
		function() return I.pilot({ pilot = false, squadron = false, t1 = false }) end,
		function() return I.pilot({ faction = "rebel" }) end,
		function() return I.pilot({ pilot = "neutral", squadron = false }) end,
		function() return I.pilot({ standing = -1 }) end,
		function() return I.pilot({ faction = "neutral" }) end,
		function() return I.pilot({ squadron = BLACK_EPSILON() }) end,
		function() return I.pilot({ squadron = false }) end,
		function() return I.pilot({ paid = 1, state = "active" }) end,
		function() return I.pilot({ paid = 1, datapad = "story" }) end,
		function() return I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 } }) end,
		function() return I.pilot({ paid = 3, state = "won", t2 = { 1, 2, 3, 4 } }) end,
		function() return I.pilot({ paid = 3, state = "won", t2 = { 1 } }) end,
		function() return I.pilot({ paid = 3, state = "failed" }) end,
		function() return I.pilot({ paid = 3, t2 = { 1, 2, 3, 4 } }) end,
		function() return I.pilot({ paid = 3, t2 = { 1, 2 } }) end,
		function() return I.pilot({ paid = 2, state = "won", t2 = { 1 } }) end,
		function() return I.pilot({ paid = 2, state = "failed", t2 = { 1 } }) end,
		function() return I.pilot({ paid = 2, t2 = { 1 } }) end,
		function() return I.pilot({ paid = 2, xp = COST }) end,
		function() return I.pilot({ paid = 2 }) end,
		function() return I.pilot({ paid = 1, state = "won" }) end,
		function() return I.pilot({ paid = 1, state = "failed" }) end,
		function() return I.pilot({ paid = 1 }) end,
		function() return I.pilot({ state = "won" }) end,
		function() return I.pilot({ state = "failed" }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local before = effects(player)
		local screen = handler():getInitialScreen(player, I.npc(), H.conversationTemplate(I.TEMPLATE))

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertEquals(effects(player), before, "pilot " .. i .. " (" .. tostring(screen and screen.id) .. "): getInitialScreen changed state")
	end
end

---------------------------------------------------------------------------------------------
-- C-1 and the off-track closure (D-8, I-12)
---------------------------------------------------------------------------------------------

TestInquisitionT2OffTrack = {}

function TestInquisitionT2OffTrack:setUp()
	H.reset()
	I.requireConversation(lu)
end

local ASK = "s_4854758d"

local function offTrack(o)
	o = o or {}
	o.squadron = o.squadron == nil and BLACK_EPSILON() or o.squadron

	return I.pilot(o)
end

-- C-1
-- AC-6
function TestInquisitionT2OffTrack:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_all_four_tier_1_skills_and_flies_nothing()
	local t = I.talk(offTrack(), { ASK })

	lu.assertEquals(I.ids(t), { "off_track", "off_track_duties" }, "all four tier 1 skills, no mission, empty datapad")
	lu.assertEquals(I.optionSids(t[2]), { "s_b2a924ab", "s_ac71da57" }, "off_track_duties replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-1
-- AC-6
function TestInquisitionT2OffTrack:test_the_request_is_refused_without_all_four_tier_1_skills()
	local t = I.talk(offTrack({ t1 = false, skills = { I.TIER1_SKILLS[1], I.TIER1_SKILLS[2], I.TIER1_SKILLS[3] } }), { ASK })

	lu.assertEquals(I.ids(t), { "off_track", "off_track_no_missions" }, "three tier 1 skills")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends the conversation")
	lu.assertEquals(I.ids(I.talk(offTrack({ t1 = false }), { ASK })), { "off_track", "off_track_no_missions" }, "no tier 1 skill")
end

-- C-1
-- AC-6
function TestInquisitionT2OffTrack:test_the_request_is_refused_with_any_space_quest_in_the_datapad()
	lu.assertEquals(I.ids(I.talk(offTrack({ datapad = "story" }), { ASK })), { "off_track", "off_track_no_missions" }, "a story mission in the datapad")
	lu.assertEquals(I.ids(I.talk(offTrack({ datapad = "duty" }), { ASK })), { "off_track", "off_track_no_missions" }, "a duty in the datapad")
end

-- C-1
-- AC-6
function TestInquisitionT2OffTrack:test_the_request_is_refused_while_one_of_fa_zolls_quests_is_active()
	for _, g in ipairs(I.DUTIES) do
		lu.assertEquals(I.ids(I.talk(offTrack({ duty = g }), { ASK })), { "off_track", "off_track_no_missions" }, g .. " is active")
	end

	lu.assertEquals(I.ids(I.talk(offTrack({ paid = 1, state = "active" }), { ASK })), { "off_track", "off_track_no_missions" }, "his mission 2 is active")
end

-- C-1: helper agreement (the spec names canFlyNonTrackDuty and isOnMission as public helpers)
-- AC-6
function TestInquisitionT2OffTrack:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(offTrack()), "all four tier 1 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ t1 = false })), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ t1 = false, skills = { I.TIER1_SKILLS[1] } })), "one tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ datapad = "story" })), "datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ duty = I.DUTY2 })), "his escort duty active")

	for n = 0, 3 do
		lu.assertTrue(h:isOnMission(I.pilot({ paid = n, state = "active" })), "mission " .. (n + 1) .. " active")
	end

	for _, g in ipairs(I.DUTIES) do
		lu.assertTrue(h:isOnMission(I.pilot({ duty = g })), g .. " active")
	end

	lu.assertFalse(h:isOnMission(I.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(I.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")
end

-- C-1 / C-4 (D-8): the off-track duty menu has the three duties and no training option, and the duties start
-- AC-6, AC-10
function TestInquisitionT2OffTrack:test_the_off_track_duty_menu_offers_the_three_duties_only_and_starts_them()
	local spies = {}

	for _, g in ipairs(I.DUTIES) do
		spies[g] = H.spyOn(I.quest(g), "startQuest")
	end

	local t = I.talk(offTrack(), { ASK, "s_ac71da57" })

	lu.assertEquals(I.ids(t), { "off_track", "off_track_duties", "duty_menu" }, "screens shown")
	lu.assertEquals(I.optionSids(t[3]), { "s_e84f3a62", "s_e6765c30", "s_f0a7a4ef" }, "duty_menu replies: no 'I'm ready for training'")
	lu.assertEquals(I.linksOf(t[3]), { "duty_police", "duty_escort", "duty_insurgents" }, "duty_menu links")

	local expect = { { "s_e84f3a62", "duty_police", I.DUTY1 }, { "s_e6765c30", "duty_escort", I.DUTY2 }, { "s_f0a7a4ef", "duty_insurgents", I.DUTY3 } }

	for _, e in ipairs(expect) do
		local got = I.talk(offTrack(), { ASK, "s_ac71da57", e[1] })

		lu.assertEquals(got[4].id, e[2], e[1] .. ": the duty screen")
	end

	for _, e in ipairs(expect) do
		lu.assertEquals(#spies[e[3]], 1, e[3] .. ": started once")
	end
end

-- I-12: everything reachable from off_track
-- AC-6
function TestInquisitionT2OffTrack:test_every_screen_reachable_from_off_track_is_in_the_closure_and_only_the_duties_start()
	local starts = {}

	for _, g in ipairs(I.GLOBALS) do
		starts[g] = H.spyOn(I.quest(g), "startQuest")
	end

	local seen = {}

	-- one pilot who may be offered the duties, one who may not (a space quest in the datapad)
	for _, build in ipairs({ function() return offTrack() end, function() return offTrack({ datapad = "story" }) end }) do
		local queue, visited = { {} }, {}

		while #queue > 0 do
			local path = table.remove(queue, 1)

			H.reset()
			for _, g in ipairs(I.GLOBALS) do
				starts[g] = H.spyOn(I.quest(g), "startQuest")
			end

			local t = I.talk(build(), path)
			local last = t[#t]

			seen[last.id] = true

			if not visited[last.id] then
				visited[last.id] = true

				for k = 0, #last.options - 1 do
					local nextPath = { table.unpack(path) }

					nextPath[#nextPath + 1] = k
					queue[#queue + 1] = nextPath
				end
			end

			lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted along " .. table.concat(path, ","))

			for _, g in ipairs(I.MISSIONS) do
				lu.assertEquals(#starts[g], 0, g .. ": a story mission started along " .. table.concat(path, ","))
			end
		end
	end

	local got = {}

	for id in pairs(seen) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, { "duty_brief_freighters", "duty_brief_insurgents", "duty_brief_police", "duty_escort", "duty_escort_warned", "duty_insurgents", "duty_insurgents_blessing", "duty_menu",
		"duty_police", "duty_police_guard", "off_track", "off_track_duties", "off_track_no_missions" }, "screens reachable from off_track")
end

---------------------------------------------------------------------------------------------
-- C-2: the sign-up refusal (the series flag)
---------------------------------------------------------------------------------------------

TestInquisitionT2Greeting = {}

function TestInquisitionT2Greeting:setUp()
	H.reset()
	I.requireConversation(lu)
end

-- AC-7
function TestInquisitionT2Greeting:test_the_greeting_has_the_three_options_and_the_info_loops_return_to_the_same_three()
	local t = I.talk(I.pilot({ agent = false }), { "s_6396820e", "s_b2101d5b", "s_3ce84ec1" })

	lu.assertEquals(I.ids(t), { "greeting", "inquisition_info", "inquisition_duties", "rebellion_info" }, "screens shown")
	lu.assertEquals(I.optionSids(t[1]), { "s_6396820e", "s_3ce84ec1", "s_696a6a00" }, "greeting replies")
	lu.assertEquals(I.optionSids(t[3]), { "s_6396820e", "s_3ce84ec1", "s_696a6a00" }, "inquisition_duties replies")
	lu.assertEquals(I.optionSids(t[4]), { "s_6396820e", "s_3ce84ec1", "s_696a6a00" }, "rebellion_info replies")
	lu.assertEquals(I.linksOf(t[1]), { "inquisition_info", "rebellion_info", "sign_up" }, "greeting links with the series flag")
	lu.assertEquals(I.linksOf(t[3]), { "inquisition_info", "rebellion_info", "sign_up" }, "inquisition_duties links with the series flag")
	lu.assertEquals(I.linksOf(t[4]), { "inquisition_info", "rebellion_info", "sign_up" }, "rebellion_info links with the series flag")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-2
-- AC-7
function TestInquisitionT2Greeting:test_the_third_option_leads_to_not_recruiting_without_the_series_flag_and_sets_nothing()
	local player = I.pilot({ agent = false, series = false })
	local t = I.talk(player, { "s_696a6a00" })

	lu.assertEquals(I.ids(t), { "greeting", "not_recruiting" }, "screens shown")
	lu.assertTrue(t[2].stop, "not_recruiting ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), nil, "the agent flag stays unset")
	lu.assertEquals(I.linksOf(I.talk(I.pilot({ agent = false, series = false }))[1]), { "inquisition_info", "rebellion_info", "not_recruiting" }, "greeting links without the series flag")

	for _, via in ipairs({ { "s_6396820e", "s_b2101d5b" }, { "s_3ce84ec1" } }) do
		local walked = I.talk(I.pilot({ agent = false, series = false }), { table.unpack(via) })
		local last = walked[#walked]

		lu.assertEquals(I.linksOf(last)[3], "not_recruiting", "third link of " .. last.id .. " without the series flag")
	end
end
