-- Lt. Colonel Barlow: which screen a pilot opens on (gate table B) and that opening a conversation changes nothing.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-5, invariant I-4; Conversation flow 1; FB-6, FB-7; D-3, D-4, D-5).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is the Vrke data file's V.pilot
-- (question / spoke set the two Barlow keys). An Inquisition pilot is an Imperial pilot in INQUISITION_SQUADRON; a Black Epsilon pilot is an Imperial pilot
-- in BLACK_EPSILON_SQUADRON; J3B's isCorrectFaction is "has pilot_imperial_navy_novice" (FB-7), which the fake derives from the `pilot` field.

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")
local CS = require("harness.client_strings")

B.load()

TestBarlowGates = {}

function TestBarlowGates:setUp()
	H.reset()
	B.requireConversation(lu)
end

local function handler() return rawget(_G, B.HANDLER) end

local NON_PILOT = { pilot = false, squadron = false, tier1 = 0, t2 = 0, t2paid4 = false }

-- the single stop screen of a gate: its sid and J3B's NPC animation
local GATE_LINES = {
	restricted = { "s_127f71ad", "wave_on_dismissing" },
	already_spoke = { "s_f813490a", "wave_finger_warning" },
	not_requested = { "s_4355764f", "wave_on_dismissing" },
}

-- B0
-- AC-5
function TestBarlowGates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = B.pilot({ question = true }), B.npc(), H.conversationTemplate(B.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- B1
-- AC-5
function TestBarlowGates:test_jtl_disabled_opens_restricted_even_with_the_question_key()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(B.firstScreen(B.pilot({ question = true })), "restricted", "JTL disabled")
end

-- B1
-- AC-5
function TestBarlowGates:test_a_pilot_without_a_player_object_opens_restricted()
	local player = B.pilot({ question = true })

	player.ghost = nil
	lu.assertEquals(B.firstScreen(player), "restricted", "ghost is nil")
end

-- B2 (J3B:4618)
-- AC-5
function TestBarlowGates:test_a_non_pilot_a_rebel_pilot_and_a_freelance_pilot_open_restricted()
	local builders = {
		non_pilot = function(o) o = o or {} for k, v in pairs(NON_PILOT) do o[k] = v end return B.pilot(o) end,
		rebel = function(o) o = o or {} o.pilot, o.faction, o.squadron = "rebel", "rebel", false return B.pilot(o) end,
		neutral = function(o) o = o or {} o.pilot, o.squadron = "neutral", false return B.pilot(o) end,
	}

	for name, build in pairs(builders) do
		lu.assertEquals(B.firstScreen(build()), "restricted", name .. ": no keys")
		lu.assertEquals(B.firstScreen(build({ question = true })), "restricted", name .. ": the question key does not help (B2 precedes B3)")
		lu.assertEquals(B.firstScreen(build({ spoke = true })), "restricted", name .. ": the spoke key does not help")
	end
end

-- B1, B2: the stop screen is one window with the J3B animation and the client line
-- AC-5
function TestBarlowGates:test_restricted_is_one_stop_screen_with_the_dismissing_wave()
	local t = B.talk(B.pilot({ pilot = "rebel", faction = "rebel", squadron = false }))

	lu.assertEquals(B.ids(t), { "restricted" }, "Rebel pilot walk")
	lu.assertEquals(t[1].text, B.PREFIX .. GATE_LINES.restricted[1], "'This is a restricted area. I suggest that you move along...'")
	lu.assertTrue(t[1].stop, "restricted ends the conversation")
	lu.assertEquals(#t[1].options, 0, "restricted offers no reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B3 (J3B:4625)
-- AC-5
function TestBarlowGates:test_an_inquisition_pilot_with_the_question_key_opens_the_interview()
	local t = B.talk(B.pilot({ question = true }))

	lu.assertEquals(B.ids(t), { "interview" }, "first screen")
	lu.assertEquals(t[1].text, B.PREFIX .. "s_a72db7d9", "'Yes? What do you want? I am extremely busy.'")
	lu.assertFalse(t[1].stop, "the interview goes on")

	local sids = {}

	for i, o in ipairs(t[1].options) do
		sids[i] = o.text
	end

	lu.assertEquals(sids, { B.PREFIX .. "s_40f102e4", B.PREFIX .. "s_ca59425a" }, "the two openings")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B3: the question key wins over the spoke key, and over negative standing (D-5)
-- AC-5
function TestBarlowGates:test_the_question_key_wins_over_the_spoke_key_and_over_negative_standing()
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, spoke = true })), "interview", "question and spoke")
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, standing = -1 })), "interview", "standing -1 (no grounded gate at Barlow)")
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, standing = -500, ship = false })), "interview", "standing -500 and no certified ship")
end

-- B3: Barlow does not look at the squadron, the tier or the missions (J3B has no such check)
-- AC-5
function TestBarlowGates:test_the_interview_does_not_depend_on_squadron_tier_or_mission_state()
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, squadron = BLACK_EPSILON_SQUADRON })), "interview", "Black Epsilon pilot with the key")
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, squadron = false })), "interview", "Imperial pilot with no squadron")
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, pilotTier = 1 })), "interview", "pilot tier 1")
	lu.assertEquals(B.firstScreen(B.pilot({ question = true, paid = { 1 }, t3 = { 1 } })), "interview", "after mission 1 and the first skill, as Vrke sends them")
end

-- B4 (J3B:4665)
-- AC-5
function TestBarlowGates:test_an_inquisition_pilot_with_only_the_spoke_key_opens_already_spoke()
	local t = B.talk(B.pilot({ spoke = true }))

	lu.assertEquals(B.ids(t), { "already_spoke" }, "first screen")
	lu.assertEquals(t[1].text, B.PREFIX .. GATE_LINES.already_spoke[1], "'You again? I don't know anything else...'")
	lu.assertTrue(t[1].stop, "already_spoke ends the conversation")
	lu.assertEquals(#t[1].options, 0, "already_spoke offers no reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B5 (J3B:4672)
-- AC-5
function TestBarlowGates:test_an_inquisition_pilot_with_neither_key_and_a_black_epsilon_pilot_open_not_requested()
	for name, player in pairs({
		inquisition = B.pilot(),
		inquisition_before_mission_1 = B.pilot({ tier1 = 4, t2 = 4, mission = {} }),
		black_epsilon = B.pilot({ squadron = BLACK_EPSILON_SQUADRON }),
		no_squadron = B.pilot({ squadron = false }),
	}) do
		local t = B.talk(player)

		lu.assertEquals(B.ids(t), { "not_requested" }, name .. ": first screen")
		lu.assertEquals(t[1].text, B.PREFIX .. GATE_LINES.not_requested[1], name .. ": 'I do not recall requesting your presence?...'")
		lu.assertTrue(t[1].stop, name .. ": not_requested ends the conversation")
		lu.assertEquals(#t[1].options, 0, name .. ": not_requested offers no reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, name .. ": client strings")
	end
end

-- I-4: getInitialScreen is side-effect free for every pilot of AC-5
-- AC-5
function TestBarlowGates:test_opening_a_conversation_changes_no_state_for_any_gate_pilot()
	local builders = {
		function() return B.pilot() end,
		function() return B.pilot(NON_PILOT) end,
		function() return B.pilot({ pilot = "rebel", faction = "rebel", squadron = false }) end,
		function() return B.pilot({ pilot = "neutral", squadron = false }) end,
		function() return B.pilot({ squadron = BLACK_EPSILON_SQUADRON }) end,
		function() return B.pilot({ question = true }) end,
		function() return B.pilot({ spoke = true }) end,
		function() return B.pilot({ question = true, spoke = true }) end,
		function() return B.pilot({ question = true, standing = -1 }) end,
		function() return B.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, spoke = true, pilotTier = 4 }) end,
	}

	for i, build in ipairs(builders) do
		H.reset()

		local player = build()
		local log, restore = B.spyWrites()
		local calls, tier, squadron, standing = #H.Engine.calls, player.ghost.pilotTier, player.ghost.squadronType, player.ghost.factionStanding.imperial
		local keys = B.keys(player)
		local screen = handler():getInitialScreen(player, B.npc(), H.conversationTemplate(B.TEMPLATE))

		restore()
		lu.assertNotNil(screen, "pilot " .. i .. ": a first screen")
		lu.assertEquals(log, {}, "pilot " .. i .. " (" .. tostring(screen and screen.id) .. "): quest status writes")
		lu.assertEquals(B.keys(player), keys, "pilot " .. i .. ": the Barlow keys")
		lu.assertEquals(#H.Engine.calls, calls, "pilot " .. i .. ": engine side effects")
		lu.assertEquals({ player.ghost.pilotTier, player.ghost.squadronType, player.ghost.factionStanding.imperial }, { tier, squadron, standing }, "pilot " .. i .. ": tier, squadron, standing")
	end
end

return nil
