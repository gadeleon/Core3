-- Capt. Rikkh's Recovery Duty starts recovery_duty/corellia_privateer_12 on both paths (on track and off track) and says SWG's line.
-- Spec: .claude/work/space-recovery-duty-fixes/01-spec.md (AC-5, AC-10, Content contract C-5, Conversation flow, D-3, D-6, D-12).
-- The off-track start with spies is also in test_space_trainer_dead_ends_rikkh.lua (S-1); here the starts are real.

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local D = require("space_trainer_dead_ends_data")
local DR = require("duty_rules_scenario")

D.load()

local Q = D.Q
local DUTY12 = "recovery_duty_corellia_privateer_12"
local HANDLER = "screenplays/space/conversations/neutral/corsec_squadron/rikkhConvoHandler.lua"
local GATE = "s_b978843d"
local CLOSING = Q .. "s_44bc6772"

-- SWG choice sids of the walk: "Recovery Duty", then the reply under the briefing
local RECOVERY, REPLY = "s_28ea80d", "s_9f5f269"

local function npc() return H.newNpc({ name = "Capt. Rikkh" }) end

-- A CorSec pilot with the four tier 1 skills, no tier 2 skill and no quest: Rikkh's first screen is here_for_work
local function onTrackPilot()
	return D.pilot({ skills = D.TIER1, squadron = rawget(_G, "CORSEC_SQUADRON") })
end

-- An off-track pilot of another squadron with all four tier 1 skills and an empty datapad
local function offTrackPilot()
	return D.pilot({ skills = D.TIER1 })
end

local function talk(player, choices)
	return D.converse(D.RIKKH, player, choices, npc())
end

local function plain(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.plain then
			out[#out + 1] = m.id
		end
	end

	return out
end

-- plain-text messages that are not string ids (a hard-coded English sentence)
local function hardCodedText(player)
	local out = {}

	for _, id in ipairs(plain(player)) do
		if id:sub(1, 1) ~= "@" then
			out[#out + 1] = id
		end
	end

	return out
end

local function assertStarted(player, transcript, screens, label)
	lu.assertEquals(D.ids(transcript), screens, label .. ": screens")

	local last = transcript[#transcript]

	lu.assertTrue(last.stop, label .. ": accept_duty_recovery ends the conversation")
	lu.assertEquals(last.text, CLOSING, label .. ": the closing line is SWG's s_44bc6772")
	lu.assertEquals(hardCodedText(player), {}, label .. ": hard-coded system messages")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "recovery_duty", "corellia_privateer_12"), label .. ": recovery_duty/corellia_privateer_12 is journal-active")
	lu.assertEquals(#DR.flaggedMissions(player), 1, label .. ": one duty mission in the datapad")
end

---------------------------------------------------------------------------------------------
-- AC-5: the two paths start the duty for real
---------------------------------------------------------------------------------------------

TestRikkhRecoveryDuty = {}

function TestRikkhRecoveryDuty:setUp() H.reset() end

-- AC-5 (a): on track, through good_duty
function TestRikkhRecoveryDuty:test_a_corsec_pilot_starts_recovery_duty_12_through_good_duty()
	local player = onTrackPilot()
	local transcript = talk(player, { "s_e107077e", RECOVERY, REPLY })

	assertStarted(player, transcript, { "here_for_work", "good_duty", "recovery_duty", "accept_duty_recovery" }, "on track via good_duty")
end

-- AC-5 (a): on track, through no_duty and lots_to_do
function TestRikkhRecoveryDuty:test_a_corsec_pilot_starts_recovery_duty_12_through_no_duty_and_lots_to_do()
	local player = onTrackPilot()
	local transcript = talk(player, { "s_c545bb40", "s_f613ccdb", RECOVERY, REPLY })

	assertStarted(player, transcript, { "here_for_work", "no_duty", "lots_to_do", "recovery_duty", "accept_duty_recovery" }, "on track via lots_to_do")
end

-- AC-5 (b): off track
function TestRikkhRecoveryDuty:test_an_off_track_pilot_starts_recovery_duty_12()
	local player = offTrackPilot()
	local transcript = talk(player, { GATE, RECOVERY, REPLY })

	assertStarted(player, transcript, { "pilot_not_corsec", "non_corsec_duty_options", "recovery_duty", "accept_duty_recovery" }, "off track")
end

-- AC-5 (a): the on-track start goes through quest start of the rebuilt duty
function TestRikkhRecoveryDuty:test_the_accept_screen_calls_start_quest_of_recovery_duty_12_once()
	local player = onTrackPilot()
	local spies = G.spies(player)
	local transcript = talk(player, { "s_e107077e", RECOVERY, REPLY })

	lu.assertEquals(D.ids(transcript)[4], "accept_duty_recovery", "last screen")
	lu.assertEquals(spies.starts, { DUTY12 }, "quests started")
	lu.assertEquals(spies.startSelf[1], rawget(_G, DUTY12), "startQuest was called on the recovery_duty_corellia_privateer_12 table")
end

-- AC-5, D-3: the briefing alone grants nothing (the grant happens on the accept screen, like Rikkh's other duties)
function TestRikkhRecoveryDuty:test_the_briefing_alone_starts_nothing_on_either_path()
	for label, build in pairs({ onTrack = onTrackPilot, offTrack = offTrackPilot }) do
		H.reset()

		local player = build()
		local spies = G.spies(player)
		local choices = label == "onTrack" and { "s_e107077e", RECOVERY } or { GATE, RECOVERY }
		local transcript = talk(player, choices)

		lu.assertEquals(D.ids(transcript)[#transcript], "recovery_duty", label .. ": last screen")
		lu.assertEquals(spies.starts, {}, label .. ": quests started")
	end
end

-- AC-5: with another duty active nothing new starts, and the player gets the refusal message, not a second duty
function TestRikkhRecoveryDuty:test_with_another_duty_active_nothing_new_starts()
	local player = onTrackPilot()
	local held = DR.holdDuty(player, "destroy_duty_naboo_privateer_6")
	local transcript = talk(player, { "s_e107077e", RECOVERY, REPLY })

	lu.assertEquals(D.ids(transcript)[#transcript], "accept_duty_recovery", "last screen")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "recovery_duty", "corellia_privateer_12"), "recovery_duty/corellia_privateer_12 is journal-active")
	lu.assertEquals(#DR.flaggedMissions(player), 1, "duty missions in the datapad")
	lu.assertEquals(DR.flaggedMissions(player)[1], held, "the one duty mission is the one the pilot already held")
	lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, "@space/quest:duty_already messages")
	lu.assertEquals(hardCodedText(player), {}, "hard-coded system messages")
end

-- AC-5: after a start Rikkh sends the pilot to on_mission, not to the duty menu again
function TestRikkhRecoveryDuty:test_after_the_start_rikkh_treats_the_pilot_as_on_a_mission()
	local player = onTrackPilot()

	talk(player, { "s_e107077e", RECOVERY, REPLY })
	lu.assertTrue(rikkhConvoHandler:isOnMission(player), "isOnMission after the recovery duty started")
	lu.assertEquals(D.ids(talk(player, {}))[1], "on_mission", "first screen on the next visit")
end

---------------------------------------------------------------------------------------------
-- AC-5, AC-10: the template and the handler source
---------------------------------------------------------------------------------------------

TestRikkhRecoveryDutyContent = {}

function TestRikkhRecoveryDutyContent:setUp() H.reset() end

-- AC-5 (C-5, OQ-4): the line on accept_duty_recovery
function TestRikkhRecoveryDutyContent:test_accept_duty_recovery_shows_swgs_closing_line_and_ends_the_conversation()
	local screen = D.screen(D.RIKKH, "accept_duty_recovery")

	lu.assertNotNil(screen, "screen accept_duty_recovery")
	lu.assertEquals(screen.leftDialog, CLOSING, "accept_duty_recovery: leftDialog")
	lu.assertEquals(screen.stopConversation, "true", "accept_duty_recovery: stopConversation")
	lu.assertEquals(screen.animation, "applause_polite", "accept_duty_recovery: animation")
	lu.assertEquals(#screen.options, 0, "accept_duty_recovery: options")
end

-- AC-5 (D-6): the reply under the briefing stays "No problem" (s_9f5f269), which the client has
function TestRikkhRecoveryDutyContent:test_the_recovery_duty_briefing_keeps_its_reply_and_link()
	local screen = D.screen(D.RIKKH, "recovery_duty")

	lu.assertNotNil(screen, "screen recovery_duty")
	lu.assertEquals(screen.leftDialog, Q .. "s_8cd19baf", "recovery_duty: leftDialog")
	lu.assertEquals(#screen.options, 1, "recovery_duty: number of options")
	lu.assertEquals(screen.options[1], { Q .. REPLY, "accept_duty_recovery" }, "recovery_duty: the one option")
end

-- AC-10 (I-5): no hard-coded English placeholder in the handler, and it starts the rebuilt duty
function TestRikkhRecoveryDutyContent:test_the_handler_has_no_placeholder_text_and_calls_the_rebuilt_duty()
	local text = D.readFile(HANDLER)

	lu.assertNil(text:lower():find("not implemented", 1, true), "rikkhConvoHandler.lua: 'not implemented' text")
	lu.assertNil(text:find("Recovery Duty Missions", 1, true), "rikkhConvoHandler.lua: the placeholder sentence")
	lu.assertNotNil(text:find("\n%s*recovery_duty_corellia_privateer_12:startQuest%(pPlayer, pNpc%)"), "rikkhConvoHandler.lua: an uncommented recovery_duty_corellia_privateer_12:startQuest(pPlayer, pNpc) call")
end
