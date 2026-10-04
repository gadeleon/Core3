-- Capt. Rikkh (CorSec tier 2): the off-track duty offer and the refusal for a pilot of another squadron.
-- Spec: .claude/work/space-trainer-dead-ends/01-spec.md (AC-5 .. AC-8, D-9, invariants I-3 .. I-6).

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local D = require("space_trainer_dead_ends_data")

D.load()

local Q = D.Q
local GATE = "s_b978843d"
local DUTY9, DUTY10, DUTY11 = "destroy_duty_corellia_privateer_9", "escort_duty_corellia_privateer_10", "destroy_duty_corellia_privateer_11"
local PLACEHOLDER = "Recovery Duty Missions are not implemented yet!"

local function ask(player, more)
	local choices = { GATE }

	for _, c in ipairs(more or {}) do
		choices[#choices + 1] = c
	end

	return D.converse(D.RIKKH, player, choices, H.newNpc({ name = "Capt. Rikkh" }))
end

local function offered(player)
	return D.ids(ask(player))[2] == "non_corsec_duty_options"
end

local function plainMessages(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.plain then
			out[#out + 1] = m.id
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-5: the offer
---------------------------------------------------------------------------------------------

TestRikkhOffTrackOffer = {}

function TestRikkhOffTrackOffer:setUp() H.reset() end

-- AC-5
function TestRikkhOffTrackOffer:test_a_pilot_with_all_four_tier_1_skills_is_offered_the_four_duties()
	local transcript = ask(D.pilot({ skills = D.TIER1 }))

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options" }, "screens")
	lu.assertEquals(transcript[2].text, Q .. "s_285c3698", "non_corsec_duty_options: leftDialog")
	lu.assertFalse(transcript[2].stop, "non_corsec_duty_options: the conversation goes on")
	lu.assertEquals(D.pairsOf(transcript[2]), D.RIKKH_MENU, "non_corsec_duty_options: options")
end

-- AC-5: the pilot may have more than the tier 1 skills
function TestRikkhOffTrackOffer:test_tier_2_skills_on_top_do_not_close_the_gate()
	local skills = {}

	for _, s in ipairs(D.TIER1) do skills[#skills + 1] = s end
	for _, s in ipairs(D.TIER2) do skills[#skills + 1] = s end

	lu.assertEquals(D.ids(ask(D.pilot({ skills = skills })))[2], "non_corsec_duty_options", "second screen")
end

-- AC-5
function TestRikkhOffTrackOffer:test_pilots_of_every_other_squadron_get_the_menu()
	for name, squadron in pairs({ rsf = rawget(_G, "RSF_SQUADRON"), smuggler = rawget(_G, "SMUGGLER_SQUADRON"), other = 99 }) do
		H.reset()

		lu.assertEquals(D.ids(ask(D.pilot({ skills = D.TIER1, squadron = squadron })))[2], "non_corsec_duty_options", name .. " pilot: second screen")
	end
end

-- AC-5: finished missions do not close the gate, only active ones
function TestRikkhOffTrackOffer:test_completed_missions_of_rikkh_do_not_close_the_gate()
	local player = D.pilot({ skills = D.TIER1, complete = D.RIKKH_ACTIVE })

	lu.assertEquals(D.ids(ask(player))[2], "non_corsec_duty_options", "second screen with every Rikkh quest complete")
end

-- AC-8: the gate screen shows exactly one reply in both gate states
function TestRikkhOffTrackOffer:test_the_gate_screen_shows_exactly_the_one_reply_in_both_gate_states()
	for label, player in pairs({ open = D.pilot({ skills = D.TIER1 }), closed = D.pilot({ skills = D.firstSkills(1) }) }) do
		local transcript = ask(player)

		lu.assertEquals(#transcript[1].options, 1, label .. ": number of replies on pilot_not_corsec")
		lu.assertEquals(D.pairsOf(transcript[1])[1] and D.pairsOf(transcript[1])[1][1], GATE, label .. ": the reply")
		lu.assertEquals(transcript[1].text, Q .. "s_87bedbc6", label .. ": pilot_not_corsec line")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the refusal
---------------------------------------------------------------------------------------------

TestRikkhOffTrackRefusal = {}

function TestRikkhOffTrackRefusal:setUp() H.reset() end

local function assertRefused(player, label)
	local spies = G.spies(player)
	local transcript = ask(player)

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_missions" }, label .. ": screens")
	lu.assertEquals(transcript[2].text, Q .. "s_7b7fb169", label .. ": refusal line")
	lu.assertTrue(transcript[2].stop, label .. ": the refusal ends the conversation")
	lu.assertEquals(spies.starts, {}, label .. ": quests started")
end

-- AC-6 (a)
function TestRikkhOffTrackRefusal:test_a_pilot_missing_any_one_tier_1_skill_gets_the_refusal()
	for k, skill in ipairs(D.TIER1) do
		H.reset()
		assertRefused(D.pilot({ skills = D.allBut(k) }), "without " .. skill)
	end
end

-- AC-6 (a): one skill passes Rhea's gate and fails Rikkh's
function TestRikkhOffTrackRefusal:test_a_pilot_with_exactly_one_tier_1_skill_gets_the_refusal()
	for i, skill in ipairs(D.TIER1) do
		H.reset()
		assertRefused(D.pilot({ skills = { skill } }), "only " .. skill)
	end
end

-- AC-6 (a)
function TestRikkhOffTrackRefusal:test_a_pilot_without_any_tier_1_skill_gets_the_refusal()
	assertRefused(D.pilot({}), "no tier 1 skill")
end

-- AC-6 (b)
function TestRikkhOffTrackRefusal:test_a_duty_mission_in_the_datapad_closes_the_gate()
	assertRefused(D.pilot({ skills = D.TIER1, datapad = "duty" }), "duty mission in the datapad")
end

-- AC-6 (b)
function TestRikkhOffTrackRefusal:test_a_story_mission_of_another_squadron_in_the_datapad_closes_the_gate()
	assertRefused(D.pilot({ skills = D.TIER1, datapad = "story" }), "other squadron's story mission in the datapad")
end

-- AC-6 (c): journal-only state, datapad empty (so only isOnMission can close the gate)
function TestRikkhOffTrackRefusal:test_each_quest_of_rikkh_that_is_journal_active_closes_the_gate()
	for _, q in ipairs(D.RIKKH_ACTIVE) do
		H.reset()
		assertRefused(D.pilot({ skills = D.TIER1, active = { q } }), q[1] .. "/" .. q[2] .. " active")
	end
end

-- AC-6, I-4: the gate decides from the trainer's own function
function TestRikkhOffTrackRefusal:test_the_handler_answers_can_fly_non_track_duty_like_the_link()
	lu.assertEquals(type(rikkhConvoHandler.canFlyNonTrackDuty), "function", "rikkhConvoHandler:canFlyNonTrackDuty")
	lu.assertEquals(type(rikkhConvoHandler.isOnMission), "function", "rikkhConvoHandler:isOnMission")

	local states = {
		{ "open", function() return D.pilot({ skills = D.TIER1 }) end },
		{ "three skills", function() return D.pilot({ skills = D.firstSkills(3) }) end },
		{ "no skill", function() return D.pilot({}) end },
		{ "datapad", function() return D.pilot({ skills = D.TIER1, datapad = "story" }) end },
		{ "journal", function() return D.pilot({ skills = D.TIER1, active = { D.RIKKH_ACTIVE[5] } }) end },
	}

	for _, s in ipairs(states) do
		H.reset()
		lu.assertEquals(rikkhConvoHandler:canFlyNonTrackDuty(s[2]()), offered(s[2]()), s[1] .. ": canFlyNonTrackDuty vs the link")
	end

	H.reset()
	lu.assertTrue(rikkhConvoHandler:isOnMission(D.pilot({ active = { D.RIKKH_ACTIVE[8] } })), "isOnMission with the recovery duty active")
	lu.assertFalse(rikkhConvoHandler:isOnMission(D.pilot({ skills = D.TIER1 })), "isOnMission with nothing active")
end

---------------------------------------------------------------------------------------------
-- AC-7: the off-track duties
---------------------------------------------------------------------------------------------

TestRikkhOffTrackDuties = {}

function TestRikkhOffTrackDuties:setUp() H.reset() end

local function menuPlayer()
	return D.pilot({ skills = D.TIER1 })
end

-- Pick the n-th (0-based) duty then its accept reply
local function takeDuty(player, index, acceptSid)
	return ask(player, { index, acceptSid })
end

-- AC-7
function TestRikkhOffTrackDuties:test_the_first_destroy_duty_starts_corellia_privateer_9()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = takeDuty(player, 0, "s_d24a2285")

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options", "destroy_duty1", "accept_duty_destroy1" }, "screens")
	lu.assertTrue(transcript[4].stop, "accept_duty_destroy1 ends the conversation")
	lu.assertEquals(spies.starts, { DUTY9 }, "quests started")
	D.noOtherEffects(spies, before, "destroy duty 1")
end

-- AC-7
function TestRikkhOffTrackDuties:test_the_escort_duty_starts_corellia_privateer_10()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = takeDuty(player, "s_56e162f2", "s_3b83352c")

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options", "escort_duty", "accept_duty_escort" }, "screens")
	lu.assertTrue(transcript[4].stop, "accept_duty_escort ends the conversation")
	lu.assertEquals(spies.starts, { DUTY10 }, "quests started")
	D.noOtherEffects(spies, before, "escort duty")
end

-- AC-7: both destroy options carry the same sid, so the second one is picked by index
function TestRikkhOffTrackDuties:test_the_second_destroy_duty_starts_corellia_privateer_11()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = takeDuty(player, 2, "s_52467dab")

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options", "destroy_duty2", "accept_duty_destroy2" }, "screens")
	lu.assertTrue(transcript[4].stop, "accept_duty_destroy2 ends the conversation")
	lu.assertEquals(spies.starts, { DUTY11 }, "quests started")
	D.noOtherEffects(spies, before, "destroy duty 2")
end

-- AC-7: the real starts, no spies
function TestRikkhOffTrackDuties:test_the_real_duty_starts_work_for_a_pilot_of_another_squadron()
	for _, row in ipairs({ { 0, "s_d24a2285", "destroy_duty", "corellia_privateer_9" }, { 1, "s_3b83352c", "escort_duty", "corellia_privateer_10" }, { 2, "s_52467dab", "destroy_duty", "corellia_privateer_11" } }) do
		H.reset()

		local player = menuPlayer()

		takeDuty(player, row[1], row[2])
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, row[3], row[4]), row[3] .. "/" .. row[4] .. " active")
	end
end

-- AC-7, D-9: Recovery Duty is offered and behaves as for a CorSec pilot today (placeholder, no quest)
function TestRikkhOffTrackDuties:test_recovery_duty_shows_the_placeholder_and_starts_no_quest()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = takeDuty(player, 3, "s_9f5f269")

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options", "recovery_duty", "accept_duty_recovery" }, "screens")
	lu.assertTrue(transcript[4].stop, "accept_duty_recovery ends the conversation")
	lu.assertEquals(plainMessages(player), { PLACEHOLDER }, "system messages")
	lu.assertEquals(spies.starts, {}, "quests started")
	D.noOtherEffects(spies, before, "recovery duty")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "recovery_duty", "corellia_privateer_12"), "recovery_duty/corellia_privateer_12 active")
end

-- AC-7: closing the window on a briefing grants nothing
function TestRikkhOffTrackDuties:test_a_briefing_alone_starts_nothing()
	local player = menuPlayer()
	local spies = G.spies(player)
	local transcript = ask(player, { 0 })

	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_duty_options", "destroy_duty1" }, "screens")
	lu.assertEquals(spies.starts, {}, "quests started")
end

---------------------------------------------------------------------------------------------
-- AC-8, I-3, I-6: template shape
---------------------------------------------------------------------------------------------

TestRikkhTemplateShape = {}

function TestRikkhTemplateShape:setUp() H.reset() end

-- AC-8, I-3 (C-5): the static link already fails closed
function TestRikkhTemplateShape:test_the_static_gate_link_is_the_refusal()
	local s = D.requireScreen(D.RIKKH, "pilot_not_corsec")

	lu.assertEquals(D.staticOptions(s), { { Q .. GATE, "non_corsec_missions" } }, "pilot_not_corsec: static options")
	lu.assertEquals(s.leftDialog, Q .. "s_87bedbc6", "pilot_not_corsec: leftDialog")
	lu.assertEquals(s.animation, "wave2", "pilot_not_corsec: animation")
	lu.assertEquals(s.stopConversation, "false", "pilot_not_corsec: stopConversation")
end

-- AC-8, I-3: without the handler's re-pointing nobody reaches the offer
function TestRikkhTemplateShape:test_the_handler_is_what_opens_the_offer()
	local passThrough = setmetatable({
		runScreenHandlers = function(self, pTemplate, pPlayer, pNpc, option, pScreen) return LuaConversationScreen(pScreen):cloneScreen() end,
	}, { __index = rikkhConvoHandler })
	local ok, transcript = pcall(H.converse, { template = D.RIKKH, player = D.pilot({ skills = D.TIER1 }), npc = H.newNpc({ name = "Capt. Rikkh" }), choices = { GATE }, handler = passThrough })

	lu.assertTrue(ok, "conversation with a pass-through handler: " .. tostring(transcript))
	lu.assertEquals(D.ids(transcript), { "pilot_not_corsec", "non_corsec_missions" }, "screens without the re-pointing")
end

-- AC-5, C-5
function TestRikkhTemplateShape:test_non_corsec_duty_options_is_the_four_duty_menu()
	local s = D.requireScreen(D.RIKKH, "non_corsec_duty_options")

	lu.assertEquals(s.leftDialog, Q .. "s_285c3698", "leftDialog")
	lu.assertEquals(s.animation, "explain", "animation")
	lu.assertEquals(s.stopConversation, "false", "stopConversation")
	lu.assertEquals(D.staticOptions(s), D.asOptions(Q, D.RIKKH_MENU), "options")
end

-- AC-6, C-5
function TestRikkhTemplateShape:test_non_corsec_missions_is_the_refusal_and_ends_the_conversation()
	local s = D.requireScreen(D.RIKKH, "non_corsec_missions")

	lu.assertEquals(s.leftDialog, Q .. "s_7b7fb169", "leftDialog")
	lu.assertEquals(s.animation, "slow_down", "animation")
	lu.assertEquals(s.stopConversation, "true", "stopConversation")
	lu.assertEquals(D.staticOptions(s), {}, "options")
end

-- I-6: the on-track duty menus keep their four options
function TestRikkhTemplateShape:test_the_corsec_duty_menus_are_unchanged()
	for _, id in ipairs({ "good_duty", "lots_to_do" }) do
		lu.assertEquals(D.staticOptions(D.requireScreen(D.RIKKH, id)), D.asOptions(Q, D.RIKKH_MENU), id .. ": options")
	end
end

-- I-6: a CorSec pilot is routed as before
function TestRikkhTemplateShape:test_a_corsec_pilot_does_not_see_the_off_track_gate()
	local corsec = D.pilot({ skills = D.TIER1, squadron = rawget(_G, "CORSEC_SQUADRON") })

	lu.assertNotEquals(D.ids(D.converse(D.RIKKH, corsec, {}))[1], "pilot_not_corsec", "a CorSec pilot is not sent to the off-track gate")
end
