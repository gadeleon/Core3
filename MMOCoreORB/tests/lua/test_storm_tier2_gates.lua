-- Commander Oberhaur: which screen a pilot opens on (gate table O), the conditional links C-1 .. C-3, the grounded walk and the off-track closure.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-8, AC-10 (travel); Conversation flow 1 and 2; FI-4, FI-5, FI-6, FI-9; D-5, D-6, D-8, D-9, D-10; I-11, I-12).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is storm_tier2_data.lua T.pilot; the
-- states are the spec's definitions (won / active / failed, :attempted and :reward keys). Default pilot: a Storm pilot with the four tier 1 skills, pilot
-- tier 2, Colzet's promotion flag and the initiate flag. Mission 3 is the Kimogila's Claw; no conversation grants it in this feature, so its win is
-- written into the journal.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")

T.load()

local COST = T.TRAINING_COST

local function opens(player) return T.firstScreen(player) end

local function handler() return rawget(_G, T.HANDLER) end

local BLACK_EPSILON = function() return rawget(_G, "BLACK_EPSILON_SQUADRON") end

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

TestStormT2Gates = {}

TestStormT2Gates.setUp = setUp

-- O0
-- AC-8
function TestStormT2Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = T.pilot(), T.npc(), H.conversationTemplate(T.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- O1
-- AC-8
function TestStormT2Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(T.pilot()), "not_pilot", "JTL disabled")
end

-- AC-8
function TestStormT2Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = T.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- O2
-- AC-8
function TestStormT2Gates:test_a_non_pilot_opens_not_pilot_which_ends_without_replies()
	local t = T.talk(T.pilot({ pilot = false, squadron = false, t1 = false }))

	lu.assertEquals(T.ids(t), { "not_pilot" }, "non-pilot")
	lu.assertTrue(t[1].stop, "not_pilot ends the conversation")
	lu.assertEquals(#t[1].options, 0, "not_pilot offers no reply")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_21772e5a", "'I'm sorry, I can't help you.'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- O3 (D-5)
-- AC-8
function TestStormT2Gates:test_rebel_faction_or_a_rebel_pilot_opens_not_pilot()
	lu.assertEquals(opens(T.pilot({ pilot = false, faction = "rebel", squadron = false, t1 = false })), "not_pilot", "Rebel-faction non-pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "not_pilot", "Rebel pilot")
	lu.assertEquals(opens(T.pilot({ faction = "rebel" })), "not_pilot", "Storm pilot with Rebel faction")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "not_pilot", "Rebel pilot with Rebel faction")
end

-- O4 (D-5)
-- AC-8
function TestStormT2Gates:test_a_privateer_opens_not_pilot()
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false })), "not_pilot", "privateer, Imperial faction")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "not_pilot", "privateer, no faction")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false, standing = -50 })), "not_pilot", "O4 precedes the grounded gate")
end

-- O5 (D-6)
-- AC-8
function TestStormT2Gates:test_negative_imperial_standing_opens_grounded()
	lu.assertEquals(opens(T.pilot({ standing = -1 })), "grounded", "Storm pilot, standing -1")
	lu.assertEquals(opens(T.pilot({ standing = -1, squadron = false })), "grounded", "O5 precedes the track check")
	lu.assertEquals(opens(T.pilot({ standing = -1, paid = 1, state = "active" })), "grounded", "O5 precedes on_mission")
	lu.assertEquals(opens(T.pilot({ standing = -1, paid = 3, t2 = { 1, 2 }, alozen = true })), "grounded", "O5 precedes report_to_alozen")
	lu.assertEquals(opens(T.pilot({ standing = 0 })), "m1_offer", "standing 0 is served normally")
end

-- O5 (D-6): a pilot whose faction is gone
-- AC-8
function TestStormT2Gates:test_an_imperial_pilot_whose_faction_is_gone_opens_grounded()
	lu.assertEquals(opens(T.pilot({ faction = "neutral" })), "grounded", "standing 0, no faction")
	lu.assertEquals(opens(T.pilot({ faction = "neutral", squadron = false })), "grounded", "a pilot of no squadron without Imperial faction: O5 precedes O7")
	lu.assertEquals(opens(T.pilot({ faction = "neutral", paid = 2, state = "won", t2 = { 1 } })), "grounded", "O5 precedes claw_won")
end

-- AC-8: the grounded walk runs its lines with the name and grants nothing
function TestStormT2Gates:test_the_grounded_walk_runs_its_lines_and_grants_nothing()
	local player = T.pilot({ standing = -3 })
	local t = T.talk(player, { "s_f3ce4b22", "s_a78a4ac3", "s_3ed9f29c", "s_ae06e68f", "s_2f84158b" })

	lu.assertEquals(T.ids(t), { "grounded", "grounded_reports", "grounded_shot", "grounded_serious", "grounded_prove", "grounded_figure_out" }, "screens shown")
	lu.assertTrue(t[6].stop, "grounded_figure_out ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "grounded: %TU")
	lu.assertEquals(t[6].params.TU, "Ace", "grounded_figure_out: %NU")
	lu.assertEquals(#T.free() + #T.bought(), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the grounded walk")
end

-- AC-8: the gate lifts at 0
function TestStormT2Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = T.pilot({ standing = -1, paid = 1 })

	lu.assertEquals(opens(player), "grounded", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "m2_offer", "standing 0")
end

-- O6
-- AC-8
function TestStormT2Gates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	lu.assertEquals(opens(T.pilot({ state = "active" })), "on_mission", "mission 1 active")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "active" })), "on_mission", "mission 2 active")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "active", t2 = { 1 } })), "on_mission", "the Claw active")
	lu.assertEquals(opens(T.pilot({ paid = 2, duty = T.DUTY1 })), "on_mission", "destroy duty active")
	lu.assertEquals(opens(T.pilot({ paid = 2, duty = T.DUTY2 })), "on_mission", "recovery duty active")
	lu.assertEquals(opens(T.pilot({ paid = 2, duty = T.DUTY3 })), "on_mission", "escort duty active")
	lu.assertEquals(opens(T.pilot({ paid = 1, datapad = "story" })), "on_mission", "a story mission in the datapad (SWG hasQuest)")
	lu.assertEquals(opens(T.pilot({ paid = 2, datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(T.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before mission 1")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2 }, alozen = true, datapad = "duty" })), "on_mission", "O6 precedes report_to_alozen")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1 }, datapad = "story" })), "on_mission", "O6 precedes claw_won")
end

-- O6 precedes O7: a pilot of another squadron with a datapad quest hears the on-mission line
-- AC-8
function TestStormT2Gates:test_a_pilot_of_another_squadron_with_a_datapad_quest_opens_on_mission_not_off_track()
	lu.assertEquals(opens(T.pilot({ squadron = BLACK_EPSILON(), datapad = "story" })), "on_mission", "Black Epsilon pilot with a story mission")
	lu.assertEquals(opens(T.pilot({ squadron = BLACK_EPSILON(), datapad = "duty" })), "on_mission", "Black Epsilon pilot with a duty")
	lu.assertEquals(opens(T.pilot({ squadron = false, datapad = "story" })), "on_mission", "pilot without a squadron")
end

-- O7
-- AC-8
function TestStormT2Gates:test_an_imperial_pilot_of_another_squadron_without_a_quest_opens_off_track()
	lu.assertEquals(opens(T.pilot({ squadron = BLACK_EPSILON() })), "off_track", "Black Epsilon pilot")
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })), "off_track", "Inquisition pilot")
	lu.assertEquals(opens(T.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(T.pilot({ squadron = false, paid = 3, t2 = { 1, 2 }, alozen = true })), "off_track", "O7 precedes report_to_alozen")
end

-- O8
-- AC-8, AC-12
function TestStormT2Gates:test_the_alozen_flag_opens_report_to_alozen()
	local t = T.talk(T.pilot({ paid = 3, t2 = { 1, 2 }, alozen = true }))

	lu.assertEquals(T.ids(t), { "report_to_alozen" }, "alozen flag")
	lu.assertTrue(t[1].stop, "report_to_alozen ends the conversation")
	lu.assertEquals(#t[1].options, 0, "no reply")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2 }, alozen = true, xp = 10 * COST })), "report_to_alozen", "with XP to spare")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2, 3 }, alozen = true })), "report_to_alozen", "O8 precedes alozen_orders")
	lu.assertEquals(opens(T.pilot({ alozen = true })), "report_to_alozen", "the flag alone is enough (it is the whole of J2's gate 7)")
end

-- O9 (D-8)
-- AC-8, AC-12
function TestStormT2Gates:test_two_or_more_tier_2_skills_and_the_claw_paid_open_alozen_orders()
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2 } })), "alozen_orders", "two skills, the Claw paid")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2, 3 } })), "alozen_orders", "three skills, the Claw paid (FI-4: not stuck on the duty line)")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1, 2, 3, 4 } })), "alozen_orders", "four skills, the Claw paid")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 3, 4 }, xp = 10 * COST })), "alozen_orders", "O9 precedes the training offer")
end

-- O9 (D-8): two skills with the Claw unpaid do not open alozen_orders
-- AC-8
function TestStormT2Gates:test_two_tier_2_skills_with_the_claw_unpaid_do_not_open_alozen_orders()
	lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { 1, 2 } })), "m3_offer", "two skills, M2 paid, Morv not briefed")
	lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { 1, 2 }, finding = true })), "find_morv", "two skills, Morv briefed")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1, 2 } })), "claw_won", "two skills, the Claw won and unpaid")
	lu.assertNotEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1, 2 }, finding = true })), "alozen_orders", "the Claw won, unpaid")
end

-- O10
-- AC-8, AC-11
function TestStormT2Gates:test_the_claw_paid_and_the_xp_for_a_second_skill_open_the_training_offer()
	local t = T.talk(T.pilot({ paid = 3, t2 = { 1 }, xp = COST }))

	lu.assertEquals(T.ids(t), { "training_offer" }, "the Claw paid, one skill, 60000 XP")
	lu.assertEquals(T.optionSids(t[1]), { "s_a4faf714" }, "training_offer reply")
	lu.assertEquals(T.linksOf(t[1]), { "training_menu" }, "training_offer link when the pilot can train")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- O10 / O11
-- AC-8, AC-11
function TestStormT2Gates:test_the_claw_paid_without_the_xp_or_with_nothing_to_train_opens_claw_duties()
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1 }, xp = COST - 1 })), "claw_duties", "59999 XP")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1 } })), "claw_duties", "no XP")
	lu.assertEquals(opens(T.pilot({ paid = 3, t2 = { 1 }, xp = COST, t1 = false })), "claw_duties", "tier 1 not complete: not ready for training")
end

-- O10: a Claw-paid pilot with no tier 2 skill at all can still buy a first one (isReadyForTraining: count2 == 0)
-- AC-8
function TestStormT2Gates:test_the_claw_paid_with_no_skill_and_xp_opens_the_training_offer()
	lu.assertEquals(opens(T.pilot({ paid = 3, xp = COST })), "training_offer", "the Claw paid, no tier 2 skill: the 'first' skill may still be bought")
end

-- O12
-- AC-8, AC-12
function TestStormT2Gates:test_the_claw_won_and_unpaid_opens_claw_won_whatever_follows()
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1 }, finding = true })), "claw_won", "after the Morv briefing")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1 } })), "claw_won", "without the finding flag")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1 }, xp = COST })), "claw_won", "O12 precedes the training offer")
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1 }, finding = true, alozen = true })), "report_to_alozen", "O8 precedes it")
end

-- O13
-- AC-8, AC-12
function TestStormT2Gates:test_the_finding_flag_opens_find_morv_until_the_claw_is_won()
	local t = T.talk(T.pilot({ paid = 2, t2 = { 1 }, finding = true }))

	lu.assertEquals(T.ids(t), { "find_morv" }, "briefed, the Claw not won")
	lu.assertTrue(t[1].stop, "find_morv ends the conversation")
	lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { 1 }, finding = true, xp = COST })), "find_morv", "O13 precedes the training offer")
	lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { 1 }, finding = true, state = "failed" })), "find_morv", "a failed or aborted Claw leaves the flag set: back to Morv (J2's behavior)")
end

-- O14 (D-8)
-- AC-8, AC-12
function TestStormT2Gates:test_a_tier_2_skill_with_mission_2_paid_opens_m3_offer()
	for i = 1, 4 do
		lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { i } })), "m3_offer", "holding only skill " .. T.TRAIN[i].x)
	end

	lu.assertEquals(opens(T.pilot({ paid = 2, t2 = { 1, 2 } })), "m3_offer", "two skills, the Claw not started")
end

-- O14 (FI-4): a skill held with M2 unpaid does not open m3_offer
-- AC-8
function TestStormT2Gates:test_a_tier_2_skill_held_with_mission_2_unpaid_does_not_open_m3_offer()
	lu.assertEquals(opens(T.pilot({ paid = 1, t2 = { 1 } })), "m2_offer", "M1 paid, M2 not started")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "won", t2 = { 1 } })), "m2_won", "M2 won and unpaid")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "failed", t2 = { 2 } })), "m2_failed", "M2 failed")
	lu.assertEquals(opens(T.pilot({ t2 = { 1 } })), "m1_offer", "M1 not done")
end

-- O15
-- AC-8, AC-11
function TestStormT2Gates:test_mission_2_paid_and_the_xp_for_a_first_skill_open_the_training_offer()
	local t = T.talk(T.pilot({ paid = 2, xp = COST }))

	lu.assertEquals(T.ids(t), { "training_offer" }, "M2 paid, no tier 2 skill, 60000 XP")
	lu.assertEquals(T.optionSids(t[1]), { "s_a4faf714" }, "training_offer reply")
	lu.assertEquals(T.linksOf(t[1]), { "training_menu" }, "training_offer link")
	lu.assertEquals(opens(T.pilot({ paid = 2, xp = 10 * COST })), "training_offer", "plenty of XP")
end

-- O15 / O16
-- AC-8, AC-11
function TestStormT2Gates:test_mission_2_paid_with_too_little_xp_or_no_tier_1_opens_the_duty_screen()
	lu.assertEquals(opens(T.pilot({ paid = 2, xp = COST - 1 })), "duty_after_m2", "59999 XP")
	lu.assertEquals(opens(T.pilot({ paid = 2 })), "duty_after_m2", "no XP")
	lu.assertEquals(opens(T.pilot({ paid = 2, xp = COST, t1 = false })), "duty_after_m2", "tier 1 not complete: not ready for training")
	lu.assertEquals(opens(T.pilot({ paid = 2, xp = COST, skills = { T.TIER1_SKILLS[1] }, t1 = false })), "duty_after_m2", "one tier 1 skill only")
end

-- O17 / O18
-- AC-8, AC-10
function TestStormT2Gates:test_mission_2_won_and_unpaid_or_failed_open_their_screens()
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "won" })), "m2_won", "M2 won, unpaid")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "failed" })), "m2_failed", "M2 attempted, nothing complete")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "attempted" })), "m2_failed", "an abort from the datapad counts as failed (FI-10)")
end

-- O19
-- AC-8
function TestStormT2Gates:test_mission_1_paid_opens_m2_offer()
	lu.assertEquals(opens(T.pilot({ paid = 1 })), "m2_offer", "M1 paid")
end

-- O20 / O21 / O22
-- AC-8, AC-10
function TestStormT2Gates:test_mission_1_won_failed_or_not_started_open_their_screens()
	lu.assertEquals(opens(T.pilot({ state = "won" })), "m1_won", "M1 won, unpaid")
	lu.assertEquals(opens(T.pilot({ state = "failed" })), "m1_failed", "M1 attempted, nothing complete")
	lu.assertEquals(opens(T.pilot({ state = "attempted" })), "m1_failed", "an abort leaves just :attempted, which counts as failed")
	lu.assertEquals(opens(T.pilot({})), "m1_offer", "applied, nothing started")
	lu.assertEquals(opens(T.pilot({ state = "won", initiate = false })), "m1_won", "O20 precedes the application gate")
end

-- O22 / O23
-- AC-8, AC-9
function TestStormT2Gates:test_without_the_initiate_flag_the_pilot_opens_the_greeting()
	lu.assertEquals(opens(T.pilot({ initiate = false })), "greeting", "Colzet's graduate, not yet applied")
	lu.assertEquals(opens(T.pilot({ initiate = false, series = false })), "greeting", "no promotion flag either")
end

-- AC-8: every gate screen exists in the template and in Appendix A
function TestStormT2Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(T.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_pilot", "grounded", "on_mission", "off_track", "report_to_alozen", "alozen_orders", "training_offer", "claw_duties", "claw_won", "find_morv", "m3_offer",
		"duty_after_m2", "m2_won", "m2_failed", "m2_offer", "m1_won", "m1_failed", "m1_offer", "greeting" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(T.TEMPLATE)):getScreen(id), T.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

-- AC-8: every won-and-unpaid mission reaches its won screen before any later offer (the 9034fa3254 rule)
function TestStormT2Gates:test_a_won_mission_is_never_hidden_by_a_later_offer()
	lu.assertEquals(opens(T.pilot({ paid = 2, state = "won", t2 = { 1, 2, 3, 4 } })), "claw_won", "the Claw")
	lu.assertEquals(opens(T.pilot({ paid = 1, state = "won", t2 = { 1 } })), "m2_won", "M2")
	lu.assertEquals(opens(T.pilot({ state = "won" })), "m1_won", "M1")
end

---------------------------------------------------------------------------------------------
-- I-11: getInitialScreen is side-effect free
---------------------------------------------------------------------------------------------

TestStormT2PureGates = {}

TestStormT2PureGates.setUp = setUp

local function effects(player)
	local out = {}

	for _, fn in ipairs({ "awardSkill", "skillManagerAwardSkill", "giveItem", "grantStarterShip", "createEvent", "createObserver", "destroyObjectFromWorld", "destroyObjectFromDatabase" }) do
		out[fn] = #H.Engine.callsTo(fn)
	end

	out.bank = player.bankCredits
	out.standing = player.ghost and player.ghost.factionStanding.imperial
	out.squadron = player.ghost and player.ghost.squadronType
	out.pilotTier = player.ghost and player.ghost.pilotTier
	out.forms = #(player.inventory and player.inventory.items or {})

	for _, suffix in ipairs(T.statusKeys()) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	for _, suffix in ipairs(T.FLAG_SUFFIXES) do
		out[suffix] = H.getQuestStatus(player, suffix)
	end

	out[T.SERIES_SUFFIX] = H.getQuestStatus(player, T.SERIES_SUFFIX)

	for _, skill in ipairs(T.TIER1_SKILLS) do
		out[skill] = CreatureObject(player):hasSkill(skill)
	end

	for _, t in ipairs(T.TRAIN) do
		out[t.skill] = CreatureObject(player):hasSkill(t.skill)
	end

	for _, form in ipairs(player.inventory and player.inventory.items or {}) do
		out["form" .. form.objectID] = form:getLuaStringData(T.SIGNATURE_KEY) .. "|" .. tostring(form.destroyed)
	end

	return out
end

-- I-11, AC-8
function TestStormT2PureGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return T.pilot() end,
		function() return T.pilot({ initiate = false, forms = { true } }) end,
		function() return T.pilot({ initiate = false, forms = { "Ace Starfire", "Ace Starfire" } }) end,
		function() return T.pilot({ initiate = false, series = false, forms = { "Ace Starfire" } }) end,
		function() return T.pilot({ pilot = false, squadron = false, t1 = false }) end,
		function() return T.pilot({ faction = "rebel" }) end,
		function() return T.pilot({ pilot = "neutral", squadron = false }) end,
		function() return T.pilot({ standing = -1 }) end,
		function() return T.pilot({ faction = "neutral" }) end,
		function() return T.pilot({ squadron = BLACK_EPSILON() }) end,
		function() return T.pilot({ squadron = false, datapad = "story" }) end,
		function() return T.pilot({ paid = 1, state = "active" }) end,
		function() return T.pilot({ paid = 1, datapad = "story" }) end,
		function() return T.pilot({ paid = 3, t2 = { 1, 2 }, alozen = true }) end,
		function() return T.pilot({ paid = 3, t2 = { 1, 2 } }) end,
		function() return T.pilot({ paid = 3, t2 = { 1 }, xp = COST }) end,
		function() return T.pilot({ paid = 3, t2 = { 1 } }) end,
		function() return T.pilot({ paid = 2, state = "won", t2 = { 1 }, finding = true }) end,
		function() return T.pilot({ paid = 2, t2 = { 1 }, finding = true }) end,
		function() return T.pilot({ paid = 2, t2 = { 1 } }) end,
		function() return T.pilot({ paid = 2, xp = COST }) end,
		function() return T.pilot({ paid = 2 }) end,
		function() return T.pilot({ paid = 1, state = "won" }) end,
		function() return T.pilot({ paid = 1, state = "failed" }) end,
		function() return T.pilot({ paid = 1 }) end,
		function() return T.pilot({ state = "won" }) end,
		function() return T.pilot({ state = "failed" }) end,
		function() return T.pilot({}) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local before = effects(player)
		local screen = handler():getInitialScreen(player, T.npc(), H.conversationTemplate(T.TEMPLATE))

		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertEquals(effects(player), before, "pilot " .. i .. " (" .. tostring(screen and screen.id) .. "): getInitialScreen changed state")
	end
end

---------------------------------------------------------------------------------------------
-- C-1: the travel help needs a certified, non-basic, non-yacht ship device (D-10)
---------------------------------------------------------------------------------------------

TestStormT2Travel = {}

TestStormT2Travel.setUp = setUp

local SHIP_DIR = "object/intangible/ship/"
local BASIC = SHIP_DIR .. "basic_tiefighter_pcd.iff"
local TIE = SHIP_DIR .. "tieadvanced_pcd.iff"
local YACHT = SHIP_DIR .. "sorosuub_space_yacht_pcd.iff"
local FREIGHTER = SHIP_DIR .. "ysf_2400_pcd.iff"

-- AC-10, D-10
function TestStormT2Travel:test_hasHyperspaceShip_needs_a_certified_pilot_and_a_non_basic_non_yacht_ship_device()
	local h = handler()

	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = {} })), "no ship device")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { BASIC } })), "only the basic starter ship")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { YACHT } })), "only the Sorosuub yacht")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { BASIC, YACHT } })), "basic ship and yacht")
	lu.assertTrue(h:hasHyperspaceShip(T.pilot({ ships = { TIE } })), "a bought TIE")
	lu.assertTrue(h:hasHyperspaceShip(T.pilot({ ships = { FREIGHTER } })), "a bought freighter")
	lu.assertTrue(h:hasHyperspaceShip(T.pilot({ ships = { BASIC, TIE } })), "basic and bought ships")
	lu.assertTrue(h:hasHyperspaceShip(T.pilot({ ships = { YACHT, FREIGHTER } })), "yacht and bought ship")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { TIE }, ship = false })), "a ship device without a certified pilot")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { "object/intangible/pet/tie_pcd.iff" } })), "a device outside object/intangible/ship/")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ ships = { SHIP_DIR .. "tieadvanced.iff" } })), "a ship template that is not a control device (_pcd.iff)")
	lu.assertFalse(h:hasHyperspaceShip(T.pilot({ datapad = "story" })), "a mission in the datapad is not a ship")
	lu.assertTrue(h:hasHyperspaceShip(T.pilot({ ships = { TIE }, datapad = "story" })), "a bought ship next to a mission")
end

-- C-1 on on_mission / s_8d17fc6e
-- AC-10
function TestStormT2Travel:test_on_mission_leads_to_the_capable_help_only_with_a_bought_ship()
	local function path(o)
		local t = T.talk(T.pilot(o), { "s_8d17fc6e" })

		return T.ids(t), t
	end

	local ids, t = path({ paid = 1, state = "active", ships = { TIE } })

	lu.assertEquals(ids, { "on_mission", "travel_capable" }, "a bought TIE")
	lu.assertEquals(T.optionSids(t[1]), { "s_a30c1a53", "s_8d17fc6e" }, "on_mission replies")
	lu.assertEquals(T.optionSids(t[2]), { "s_9288900f" }, "travel_capable reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals((path({ paid = 1, state = "active" })), { "on_mission", "travel_need_ship" }, "no ship device")
	lu.assertEquals((path({ paid = 1, state = "active", ships = { BASIC } })), { "on_mission", "travel_need_ship" }, "only the starter ship")
	lu.assertEquals((path({ paid = 1, state = "active", ships = { YACHT } })), { "on_mission", "travel_need_ship" }, "only the yacht")
end

-- AC-10: the first option of on_mission
function TestStormT2Travel:test_on_mission_outstanding_ends_the_conversation()
	local t = T.talk(T.pilot({ state = "active" }), { "s_a30c1a53" })

	lu.assertEquals(T.ids(t), { "on_mission", "on_mission_outstanding" }, "screens shown")
	lu.assertTrue(t[2].stop, "on_mission_outstanding ends the conversation")
end

-- AC-10: the travel help walks end where Appendix A says
function TestStormT2Travel:test_the_travel_help_branches_all_end_in_a_farewell()
	local ends = { travel_carry_on = true, travel_begone = true }

	for _, start in ipairs({ "travel_capable", "travel_need_ship", "travel_why", "travel_where", "travel_handle", "travel_launch", "travel_vendor", "travel_not_nice", "travel_planetary_map" }) do
		local seen, queue = { [start] = true }, { start }
		local reached = {}

		while #queue > 0 do
			local id = table.remove(queue, 1)
			local row = T.screenRow(id)

			if row.stop then
				reached[id] = true
			end

			for _, o in ipairs(row.options) do
				if not seen[o[2]] then
					seen[o[2]] = true
					queue[#queue + 1] = o[2]
				end
			end
		end

		for id in pairs(reached) do
			lu.assertTrue(ends[id] == true, start .. " reaches the end screen " .. id)
		end

		lu.assertNotNil(next(reached), start .. " reaches an end screen")
	end
end

---------------------------------------------------------------------------------------------
-- C-2, C-3 and the off-track closure (D-9, I-12)
---------------------------------------------------------------------------------------------

TestStormT2OffTrack = {}

TestStormT2OffTrack.setUp = setUp

local ASK = "s_4854758d"

local function offTrack(o)
	o = o or {}
	o.squadron = o.squadron == nil and BLACK_EPSILON() or o.squadron

	return T.pilot(o)
end

-- C-2
-- AC-8
function TestStormT2OffTrack:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_all_four_tier_1_skills_and_flies_nothing()
	local t = T.talk(offTrack(), { ASK })

	lu.assertEquals(T.ids(t), { "off_track", "off_track_duties" }, "all four tier 1 skills, no mission, empty datapad")
	lu.assertEquals(T.optionSids(t[2]), { "s_b2a924ab", "s_ac71da57" }, "off_track_duties replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- C-2
-- AC-8
function TestStormT2OffTrack:test_the_request_is_refused_without_all_four_tier_1_skills()
	local t = T.talk(offTrack({ t1 = false, skills = { T.TIER1_SKILLS[1], T.TIER1_SKILLS[2], T.TIER1_SKILLS[3] } }), { ASK })

	lu.assertEquals(T.ids(t), { "off_track", "off_track_no_missions" }, "three tier 1 skills")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends the conversation")
	lu.assertEquals(T.ids(T.talk(offTrack({ t1 = false }), { ASK })), { "off_track", "off_track_no_missions" }, "no tier 1 skill")
end

-- C-2: helper agreement (the spec names canFlyNonTrackDuty and isOnMission as public helpers)
-- AC-8
function TestStormT2OffTrack:test_the_helpers_canFlyNonTrackDuty_and_isOnMission_agree_with_the_rule()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(offTrack()), "all four tier 1 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ t1 = false })), "no tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ t1 = false, skills = { T.TIER1_SKILLS[1] } })), "one tier 1 skill")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ datapad = "story" })), "datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ datapad = "duty" })), "duty in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(offTrack({ duty = T.DUTY3 })), "his escort duty active")

	for n = 0, 2 do
		lu.assertTrue(h:isOnMission(T.pilot({ paid = n, state = "active" })), "mission " .. (n + 1) .. " active")
	end

	for _, g in ipairs(T.DUTIES) do
		lu.assertTrue(h:isOnMission(T.pilot({ duty = g })), g .. " active")
	end

	lu.assertFalse(h:isOnMission(T.pilot({ paid = 2 })), "nothing running")
	lu.assertFalse(h:isOnMission(T.pilot({ paid = 1, state = "won" })), "a won mission is not a running one")
end

-- C-3 (D-9): the off-track duty menu has the three duties and no training option, and the duties start
-- AC-8, AC-11
function TestStormT2OffTrack:test_the_off_track_duty_menu_offers_the_three_duties_only_and_starts_them()
	local expect = { { "s_45f4f7db", "duty_fleet", T.DUTY1 }, { "s_a6363375", "duty_smugglers", T.DUTY2 }, { "s_721e2818", "duty_pirates", T.DUTY3 } }
	local t = T.talk(offTrack(), { ASK, "s_ac71da57" })

	lu.assertEquals(T.ids(t), { "off_track", "off_track_duties", "duty_menu" }, "screens shown")
	lu.assertEquals(T.optionSids(t[3]), { "s_45f4f7db", "s_a6363375", "s_721e2818" }, "duty_menu replies: no 'I'm ready for training'")
	lu.assertEquals(T.linksOf(t[3]), { "duty_fleet", "duty_smugglers", "duty_pirates" }, "duty_menu links")

	for _, e in ipairs(expect) do
		H.reset()

		local spies = {}

		for _, g in ipairs(T.GLOBALS) do
			spies[g] = H.spyOn(T.quest(g), "startQuest")
		end

		local got = T.talk(offTrack(), { ASK, "s_ac71da57", e[1] })

		lu.assertEquals(got[4].id, e[2], e[1] .. ": the duty screen")

		for _, g in ipairs(T.GLOBALS) do
			lu.assertEquals(#spies[g], g == e[3] and 1 or 0, e[1] .. ": startQuest calls of " .. g)
		end
	end
end

-- I-12: everything reachable from off_track
-- AC-8
function TestStormT2OffTrack:test_every_screen_reachable_from_off_track_is_in_the_closure_and_only_the_duties_start()
	local seen = {}

	for _, build in ipairs({ function() return offTrack() end, function() return offTrack({ t1 = false }) end }) do
		local queue, visited = { {} }, {}

		while #queue > 0 do
			local path = table.remove(queue, 1)

			H.reset()

			local starts = {}

			for _, g in ipairs(T.GLOBALS) do
				starts[g] = H.spyOn(T.quest(g), "startQuest")
			end

			local player = build()
			local t = T.talk(player, path)
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

			lu.assertEquals(#T.free() + #T.bought(), 0, "no skill granted along " .. table.concat(path, ","))
			lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item along " .. table.concat(path, ","))

			for _, g in ipairs(T.MISSIONS) do
				lu.assertEquals(#starts[g], 0, g .. ": a story mission started along " .. table.concat(path, ","))
			end
		end
	end

	local got = {}

	for id in pairs(seen) do
		got[#got + 1] = id
	end

	table.sort(got)
	lu.assertEquals(got, { "duty_briefing", "duty_briefing_pirates", "duty_briefing_smugglers", "duty_fleet", "duty_fleet_aces", "duty_menu", "duty_pirates", "duty_pirates_alive",
		"duty_smugglers", "duty_smugglers_guard", "off_track", "off_track_duties", "off_track_no_missions" }, "screens reachable from off_track")
end

-- C-3: on track, the duty menu keeps the training reply, leading to the menu only when the pilot is ready
-- AC-11
function TestStormT2OffTrack:test_on_track_the_duty_menu_links_the_training_reply_by_readiness()
	local ready = T.drive(T.pilot({ paid = 2, xp = COST }), "duty_menu")

	lu.assertEquals(T.optionSids(ready[1]), { "s_45f4f7db", "s_a6363375", "s_721e2818", "s_b0d3b474" }, "duty_menu replies on track")
	lu.assertEquals(T.linksOf(ready[1]), { "duty_fleet", "duty_smugglers", "duty_pirates", "training_menu" }, "ready: the training reply leads to the menu")

	local notReady = T.drive(T.pilot({ paid = 2, xp = COST - 1 }), "duty_menu")

	lu.assertEquals(T.optionSids(notReady[1]), { "s_45f4f7db", "s_a6363375", "s_721e2818", "s_b0d3b474" }, "not ready: the reply stays")
	lu.assertEquals(T.linksOf(notReady[1]), { "duty_fleet", "duty_smugglers", "duty_pirates", "training_not_ready" }, "not ready: the reply leads to the refusal")

	local beforeM2 = T.drive(T.pilot({ paid = 1, xp = COST }), "duty_menu")

	lu.assertEquals(T.linksOf(beforeM2[1])[4], "training_not_ready", "M2 unpaid: not ready whatever the XP")
end

-- C-3 on training_offer / s_a4faf714
-- AC-11
function TestStormT2OffTrack:test_the_training_offer_reply_leads_to_the_menu_only_for_a_ready_pilot()
	lu.assertEquals(T.linksOf(T.drive(T.pilot({ paid = 2, xp = COST }), "training_offer")[1]), { "training_menu" }, "ready")
	lu.assertEquals(T.linksOf(T.drive(T.pilot({ paid = 2, xp = COST - 1 }), "training_offer")[1]), { "training_not_ready" }, "too little XP")
	lu.assertEquals(T.linksOf(T.drive(T.pilot({ paid = 2, t2 = { 1, 2 }, xp = COST }), "training_offer")[1]), { "training_not_ready" }, "two skills held")
	lu.assertEquals(T.linksOf(T.drive(T.pilot({ paid = 2, t2 = { 1 }, xp = COST }), "training_offer")[1]), { "training_not_ready" }, "one skill, the Claw unpaid")
end
