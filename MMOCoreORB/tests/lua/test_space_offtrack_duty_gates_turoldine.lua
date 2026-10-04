-- Turoldine (CorSec tier 4): the off-track duty briefing and the refusal for a neutral pilot of another squadron.
-- Spec: .claude/work/space-offtrack-duty-gates/01-spec.md (AC-7, AC-8, I-3 .. I-6, D-6, D-11).

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local O = require("space_offtrack_duty_gates_data")
local DE = require("space_trainer_dead_ends_data")

O.load()

local TU = O.TU
local GATE = O.GATE_T
local BASE_FILES = O.SOURCES.turoldine

local function ask(player, more)
	local choices = { GATE }

	for _, c in ipairs(more or {}) do
		choices[#choices + 1] = c
	end

	return O.converse(O.TUROLDINE, player, choices, "Turoldine")
end

local function second(player)
	local transcript = ask(player)

	return transcript[2] and transcript[2].id
end

-- Tier 1, 2 and 3 skills of the neutral profession: the tier 3 graduate
local TIER3_GRAD = O.concat(O.NEUTRAL_TIER1, O.NEUTRAL_TIER2, O.NEUTRAL_TIER3)

local function open(extra)
	extra = extra or {}
	extra.kind = "neutral"
	extra.skills = extra.skills or TIER3_GRAD

	return O.pilot(extra)
end

---------------------------------------------------------------------------------------------
-- AC-7: the offer and the duties
---------------------------------------------------------------------------------------------

TestTuroldineOffTrackOffer = {}

function TestTuroldineOffTrackOffer:setUp() H.reset() end

-- AC-7
function TestTuroldineOffTrackOffer:test_a_clean_tier_3_graduate_of_another_squadron_is_sent_to_the_duty_briefing()
	local transcript = ask(open())

	lu.assertEquals(G.ids(transcript), { "pilot_not_corsec", "here_for_work" }, "screens")
	lu.assertEquals(transcript[2].text, TU .. "s_3d991214", "here_for_work: leftDialog")
	lu.assertFalse(transcript[2].stop, "here_for_work: the conversation goes on")
end

-- AC-7: the gate needs the tier 3 skills only; tier 1 and 2 are not asked for
function TestTuroldineOffTrackOffer:test_only_the_four_tier_3_skills_are_needed()
	lu.assertEquals(second(open({ skills = O.NEUTRAL_TIER3 })), "here_for_work", "second screen with the tier 3 skills alone")
end

-- AC-7
function TestTuroldineOffTrackOffer:test_pilots_of_every_other_squadron_get_the_briefing()
	for name, squadron in pairs({ rsf = rawget(_G, "RSF_SQUADRON"), smuggler = rawget(_G, "SMUGGLER_SQUADRON"), other = 99 }) do
		H.reset()
		lu.assertEquals(second(open({ squadron = squadron })), "here_for_work", name .. " pilot: second screen")
	end
end

-- AC-7: finished missions do not close the gate, only active ones
function TestTuroldineOffTrackOffer:test_completed_quests_of_turoldine_do_not_close_the_gate()
	lu.assertEquals(second(open({ complete = O.TUROLDINE_ACTIVE })), "here_for_work", "second screen with every Turoldine quest complete")
end

-- AC-7, AC-9: the gate screen shows exactly one reply in both gate states
function TestTuroldineOffTrackOffer:test_the_gate_screen_shows_exactly_the_one_reply_in_both_gate_states()
	for label, player in pairs({ open = open(), closed = open({ skills = {} }) }) do
		local transcript = ask(player)

		lu.assertEquals(transcript[1].id, "pilot_not_corsec", label .. ": first screen")
		lu.assertEquals(transcript[1].text, TU .. "s_32f5282f", label .. ": pilot_not_corsec line")
		lu.assertEquals(#transcript[1].options, 1, label .. ": number of replies on pilot_not_corsec")
		lu.assertEquals(O.sidOf(transcript[1].options[1].text), GATE, label .. ": the reply")
	end
end

-- AC-7: the briefing chain to the duty menu
function TestTuroldineOffTrackOffer:test_the_briefing_chain_reaches_the_duty_menu()
	local replies = {}

	for i = 1, #O.TUROLDINE_CHAIN do
		replies[i] = O.TUROLDINE_CHAIN[i][1]
	end

	local ids = { "pilot_not_corsec" }

	for _, step in ipairs(O.TUROLDINE_CHAIN) do
		ids[#ids + 1] = step[2]
	end

	local transcript = O.converse(O.TUROLDINE, open(), replies, "Turoldine")

	lu.assertEquals(G.ids(transcript), ids, "screens")
end

local function walkToDuty(player, reply)
	return O.converse(O.TUROLDINE, player, { GATE, "s_a490d2c6", "s_6ce4e96f", "s_2de6d84d", "s_362a48e0", reply }, "Turoldine")
end

-- AC-7, I-5
function TestTuroldineOffTrackOffer:test_each_duty_reply_starts_only_its_duty_and_writes_nothing()
	for _, row in ipairs(O.TUROLDINE_DUTIES) do
		H.reset()

		local player = open()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		local transcript = walkToDuty(player, row[1])

		lu.assertEquals(transcript[#transcript].id, row[2], row[2] .. ": last screen")
		lu.assertTrue(transcript[#transcript].stop, row[2] .. " ends the conversation")
		lu.assertEquals(spies.starts, { row[3] }, row[2] .. ": quests started")
		DE.noOtherEffects(spies, before, row[2])
	end
end

-- AC-7: the real starts, no spies
function TestTuroldineOffTrackOffer:test_the_real_duty_starts_work_for_a_pilot_of_another_squadron()
	for _, row in ipairs(O.TUROLDINE_DUTIES) do
		H.reset()

		local player = open({ squadron = rawget(_G, "RSF_SQUADRON") })

		walkToDuty(player, row[1])

		local quest = H.expectGlobal(row[3], "quest table")

		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, quest.questType, quest.questName), row[3] .. " active")
	end
end

-- AC-7: the briefing alone grants nothing
function TestTuroldineOffTrackOffer:test_the_briefing_alone_starts_nothing()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()

	O.converse(O.TUROLDINE, player, { GATE, "s_a490d2c6", "s_6ce4e96f", "s_2de6d84d", "s_362a48e0" }, "Turoldine")
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written")
end

---------------------------------------------------------------------------------------------
-- AC-8: the refusal
---------------------------------------------------------------------------------------------

TestTuroldineOffTrackRefusal = {}

function TestTuroldineOffTrackRefusal:setUp() H.reset() end

local function assertRefused(player, label)
	local spies = G.spies(player)
	local transcript = ask(player)

	lu.assertEquals(G.ids(transcript), { "pilot_not_corsec", "non_corsec_no_missions" }, label .. ": screens")
	lu.assertEquals(transcript[2].text, TU .. "s_784ca15", label .. ": refusal line")
	lu.assertTrue(transcript[2].stop, label .. ": the refusal ends the conversation")
	lu.assertEquals(transcript[2].options, {}, label .. ": the refusal has no replies")
	lu.assertEquals(spies.starts, {}, label .. ": quests started")
end

-- AC-8 (a): one, two and three tier 3 skills all fail
function TestTuroldineOffTrackRefusal:test_a_pilot_missing_any_tier_3_skill_gets_the_refusal()
	for k, skill in ipairs(O.NEUTRAL_TIER3) do
		H.reset()
		assertRefused(open({ skills = O.concat(O.NEUTRAL_TIER1, O.NEUTRAL_TIER2, O.allBut(O.NEUTRAL_TIER3, k)) }), "without " .. skill)
		H.reset()
		assertRefused(open({ skills = O.concat(O.NEUTRAL_TIER1, O.NEUTRAL_TIER2, { skill }) }), "only " .. skill .. " of tier 3")
	end
end

-- AC-8 (a): the tier 2 graduate
function TestTuroldineOffTrackRefusal:test_a_tier_2_graduate_gets_the_refusal()
	assertRefused(open({ skills = O.concat(O.NEUTRAL_TIER1, O.NEUTRAL_TIER2) }), "tier 1 and 2 complete")
end

-- AC-8 (a)
function TestTuroldineOffTrackRefusal:test_a_pilot_without_any_skill_gets_the_refusal()
	assertRefused(open({ skills = {} }), "no skills")
end

-- AC-8 (b)
function TestTuroldineOffTrackRefusal:test_a_duty_mission_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "duty" }), "duty mission in the datapad")
end

-- AC-8 (b)
function TestTuroldineOffTrackRefusal:test_a_story_mission_of_another_squadron_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "story" }), "other squadron's story mission in the datapad")
end

-- AC-8 (c): journal-only state, datapad empty (so only isOnMission can close the gate)
function TestTuroldineOffTrackRefusal:test_each_chain_or_duty_of_turoldine_that_is_journal_active_closes_the_gate()
	for _, g in ipairs(O.TUROLDINE_ACTIVE) do
		H.reset()
		assertRefused(open({ active = { g } }), g .. " active")
	end
end

-- AC-8, I-4: the gate decides from the trainer's own function
function TestTuroldineOffTrackRefusal:test_the_handler_answers_can_fly_non_track_duty_like_the_link()
	lu.assertEquals(type(turoldineConvoHandler.canFlyNonTrackDuty), "function", "turoldineConvoHandler:canFlyNonTrackDuty")
	lu.assertEquals(type(turoldineConvoHandler.isOnMission), "function", "turoldineConvoHandler:isOnMission")

	local states = {
		{ "open", function() return open() end },
		{ "three tier 3 skills", function() return open({ skills = O.concat(O.NEUTRAL_TIER1, O.NEUTRAL_TIER2, O.allBut(O.NEUTRAL_TIER3, 2)) }) end },
		{ "no skill", function() return open({ skills = {} }) end },
		{ "datapad", function() return open({ datapad = "story" }) end },
		{ "journal", function() return open({ active = { O.TUROLDINE_ACTIVE[7] } }) end },
	}

	for _, s in ipairs(states) do
		H.reset()
		lu.assertEquals(turoldineConvoHandler:canFlyNonTrackDuty(s[2]()), second(s[2]()) == "here_for_work", s[1] .. ": canFlyNonTrackDuty vs the link")
	end

	H.reset()
	lu.assertTrue(turoldineConvoHandler:isOnMission(open({ skills = {}, active = { "rescue_duty_corellia_privateer_tier4_1" } })), "isOnMission with the rescue duty active")
	lu.assertTrue(turoldineConvoHandler:isOnMission(open({ skills = {}, active = { "space_battle_corellia_privateer_tier4_3a" } })), "isOnMission with chain 3 active")
	lu.assertFalse(turoldineConvoHandler:isOnMission(open()), "isOnMission with nothing active")
end

-- AC-8, I-4
function TestTuroldineOffTrackRefusal:test_can_fly_non_track_duty_checks_the_datapad_and_the_tier_3_rule()
	local text = O.readFile(BASE_FILES[2])
	local s = text:find("function turoldineConvoHandler:canFlyNonTrackDuty", 1, true)

	lu.assertNotNil(s, "definition of turoldineConvoHandler:canFlyNonTrackDuty")

	local body = text:sub(s, text:find("\nend\n", s, true))

	lu.assertNotNil(body:find("not SpaceHelpers:hasSpaceQuest(pPlayer)", 1, true), "canFlyNonTrackDuty has the datapad clause")
	lu.assertNotNil(body:find("SpaceHelpers:hasCompletedPilotTier(pPlayer, \"neutral\", 3)", 1, true), "canFlyNonTrackDuty has the all-four tier 3 rule")
	lu.assertNotNil(body:find("not self:isOnMission(pPlayer)", 1, true), "canFlyNonTrackDuty has the own-quests clause")
end

---------------------------------------------------------------------------------------------
-- I-3, I-6: template shape and on-track routing
---------------------------------------------------------------------------------------------

TestTuroldineTemplateShape = {}

function TestTuroldineTemplateShape:setUp() H.reset() end

local function requireScreen(id)
	return DE.requireScreen(O.TUROLDINE, id)
end

-- I-3 (C-5): the static link already fails closed
function TestTuroldineTemplateShape:test_the_static_gate_link_is_the_refusal()
	local s = requireScreen("pilot_not_corsec")

	lu.assertEquals(DE.staticOptions(s), { { TU .. GATE, "non_corsec_no_missions" } }, "pilot_not_corsec: static options")
	lu.assertEquals(s.leftDialog, TU .. "s_32f5282f", "pilot_not_corsec: leftDialog")
	lu.assertEquals(s.animation, "rub_chin_thoughtful", "pilot_not_corsec: animation")
	lu.assertEquals(s.stopConversation, "false", "pilot_not_corsec: stopConversation")
end

-- I-3: without the handler's re-pointing nobody reaches the briefing
function TestTuroldineTemplateShape:test_the_handler_is_what_opens_the_briefing()
	local passThrough = setmetatable({
		runScreenHandlers = function(self, pTemplate, pPlayer, pNpc, option, pScreen) return LuaConversationScreen(pScreen):cloneScreen() end,
	}, { __index = turoldineConvoHandler })
	local ok, transcript = pcall(H.converse, { template = O.TUROLDINE, player = open(), npc = H.newNpc({ name = "Turoldine" }), choices = { GATE }, handler = passThrough })

	lu.assertTrue(ok, "conversation with a pass-through handler: " .. tostring(transcript))
	lu.assertEquals(G.ids(transcript), { "pilot_not_corsec", "non_corsec_no_missions" }, "screens without the re-pointing")
end

-- C-5
function TestTuroldineTemplateShape:test_the_refusal_screen_has_the_spec_values()
	for _, row in ipairs(O.TUROLDINE_SCREENS) do
		local s = requireScreen(row.id)

		lu.assertEquals(s.leftDialog, TU .. row.sid, row.id .. ": leftDialog")
		lu.assertEquals(s.animation, row.animation, row.id .. ": animation")
		lu.assertEquals(s.stopConversation, row.stop, row.id .. ": stopConversation")
		lu.assertEquals(DE.staticOptions(s), {}, row.id .. ": options")
	end
end

-- C-5, D-6: the briefing screen is unchanged and keeps its animation
function TestTuroldineTemplateShape:test_here_for_work_keeps_its_line_and_animation()
	local s = requireScreen("here_for_work")

	lu.assertEquals(s.leftDialog, TU .. "s_3d991214", "here_for_work: leftDialog")
	lu.assertEquals(s.animation, "nod_head_once", "here_for_work: animation")
end

-- I-6: a CorSec pilot is routed as before
function TestTuroldineTemplateShape:test_a_corsec_pilot_does_not_see_the_off_track_gate()
	local corsec = open({ squadron = rawget(_G, "CORSEC_SQUADRON") })

	lu.assertNotEquals(O.converse(O.TUROLDINE, corsec, {}, "Turoldine")[1].id, "pilot_not_corsec", "a CorSec pilot is not sent to the off-track gate")
end

-- I-6: non-pilots and other professions are routed as before
function TestTuroldineTemplateShape:test_a_rebel_pilot_still_gets_not_pilot()
	lu.assertEquals(O.converse(O.TUROLDINE, O.pilot({ kind = "rebel" }), {}, "Turoldine")[1].id, "not_pilot", "rebel pilot")
end
