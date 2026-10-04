-- Viopa (Havoc tier 2): the off-track duty offer and the refusal for a rebel pilot of another squadron.
-- Spec: .claude/work/space-offtrack-duty-gates/01-spec.md (AC-4 .. AC-6, I-3 .. I-6, D-3, D-9, D-10, D-11).

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local O = require("space_offtrack_duty_gates_data")
local DE = require("space_trainer_dead_ends_data")

O.load()

local V = O.V
local GATE = O.GATE_K
local INTRODUCED = "viopa_rebel_1:introduced"

local function ask(player, more)
	local choices = { GATE }

	for _, c in ipairs(more or {}) do
		choices[#choices + 1] = c
	end

	return O.converse(O.VIOPA, player, choices, "Viopa")
end

local function second(player)
	local transcript = ask(player)

	return transcript[2] and transcript[2].id
end

local function open(extra)
	extra = extra or {}
	extra.skills = extra.skills or O.REBEL_TIER1

	return O.pilot(extra)
end

-- Every proper subset of size 3 and the single-skill pilots: the skill rule is "all four"
local function shortSkills()
	local rows = {}

	for k, skill in ipairs(O.REBEL_TIER1) do
		rows[#rows + 1] = { "without " .. skill, O.allBut(O.REBEL_TIER1, k) }
		rows[#rows + 1] = { "only " .. skill, { skill } }
	end

	rows[#rows + 1] = { "no tier 1 skill", {} }

	return rows
end

---------------------------------------------------------------------------------------------
-- AC-4: the offer
---------------------------------------------------------------------------------------------

TestViopaOffTrackOffer = {}

function TestViopaOffTrackOffer:setUp() H.reset() end

-- AC-4
function TestViopaOffTrackOffer:test_a_clean_off_track_pilot_with_all_tier_1_skills_is_offered_the_elective_duties()
	local transcript = ask(open())

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_offer" }, "screens")
	lu.assertEquals(transcript[2].text, V .. "s_9d922723", "non_havoc_duty_offer: leftDialog")
	lu.assertFalse(transcript[2].stop, "non_havoc_duty_offer: the conversation goes on")
	lu.assertEquals(O.pairsOf(transcript[2]), { { "s_e84d85e2", "non_havoc_duty_options" }, { "s_e87a40f8", "non_havoc_duty_decline" } }, "non_havoc_duty_offer: options")
end

-- AC-4
function TestViopaOffTrackOffer:test_sounds_great_shows_the_four_duty_replies_in_swg_order()
	local transcript = ask(open(), { "s_e84d85e2" })

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_offer", "non_havoc_duty_options" }, "screens")
	lu.assertEquals(transcript[3].text, V .. "s_565951d5", "non_havoc_duty_options: leftDialog")
	lu.assertFalse(transcript[3].stop, "non_havoc_duty_options: the conversation goes on")
	lu.assertEquals(O.pairsOf(transcript[3]), O.VIOPA_MENU, "non_havoc_duty_options: options")
end

-- AC-4: tier 2 skills on top do not close the gate
function TestViopaOffTrackOffer:test_higher_tier_skills_on_top_do_not_close_the_gate()
	local skills = O.concat(O.REBEL_TIER1, { "pilot_rebel_navy_starships_02" })

	lu.assertEquals(second(open({ skills = skills })), "non_havoc_duty_offer", "second screen")
end

-- AC-4
function TestViopaOffTrackOffer:test_pilots_of_every_other_rebel_squadron_get_the_offer()
	for name, squadron in pairs({ crimson = rawget(_G, "CRIMSON_PHOENIX_SQUADRON"), vortex = rawget(_G, "VORTEX_SQUADRON"), other = 99 }) do
		H.reset()
		lu.assertEquals(second(open({ squadron = squadron })), "non_havoc_duty_offer", name .. " pilot: second screen")
	end
end

-- AC-4: finished missions do not close the gate, only active ones
function TestViopaOffTrackOffer:test_completed_quests_of_viopa_do_not_close_the_gate()
	lu.assertEquals(second(open({ complete = O.VIOPA_ACTIVE })), "non_havoc_duty_offer", "second screen with every Viopa quest complete")
end

-- AC-9: the gate screen shows exactly one reply in both gate states
function TestViopaOffTrackOffer:test_the_gate_screen_shows_exactly_the_one_reply_in_both_gate_states()
	for label, player in pairs({ open = open(), closed = O.pilot({}) }) do
		local transcript = ask(player)

		lu.assertEquals(transcript[1].id, "non_havoc_pilot", label .. ": first screen")
		lu.assertEquals(transcript[1].text, V .. "s_148ee1c2", label .. ": non_havoc_pilot line")
		lu.assertEquals(#transcript[1].options, 1, label .. ": number of replies on non_havoc_pilot")
		lu.assertEquals(O.sidOf(transcript[1].options[1].text), GATE, label .. ": the reply")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: the refusal
---------------------------------------------------------------------------------------------

TestViopaOffTrackRefusal = {}

function TestViopaOffTrackRefusal:setUp() H.reset() end

local function assertRefused(player, label)
	local spies = G.spies(player)
	local transcript = ask(player)

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_no_missions" }, label .. ": screens")
	lu.assertEquals(transcript[2].text, V .. "s_990019e5", label .. ": refusal line")
	lu.assertTrue(transcript[2].stop, label .. ": the refusal ends the conversation")
	lu.assertEquals(transcript[2].options, {}, label .. ": the refusal has no replies")
	lu.assertEquals(spies.starts, {}, label .. ": quests started")
end

-- AC-5 (a): the rule is all four, so one, two and three skills all fail
function TestViopaOffTrackRefusal:test_a_pilot_missing_any_tier_1_skill_gets_the_refusal()
	for _, row in ipairs(shortSkills()) do
		H.reset()
		assertRefused(O.pilot({ skills = row[2] }), row[1])
	end
end

-- AC-5 (a): the pilot with exactly two skills
function TestViopaOffTrackRefusal:test_a_pilot_with_exactly_two_tier_1_skills_gets_the_refusal()
	assertRefused(O.pilot({ skills = { O.REBEL_TIER1[1], O.REBEL_TIER1[2] } }), "two tier 1 skills")
end

-- AC-5 (a): tier 2 skills do not stand in for the tier 1 ones
function TestViopaOffTrackRefusal:test_tier_2_skills_do_not_replace_missing_tier_1_skills()
	assertRefused(O.pilot({ skills = O.concat(O.allBut(O.REBEL_TIER1, 1), { "pilot_rebel_navy_droid_02" }) }), "tier 2 droid instead of tier 1 droid")
end

-- AC-5 (b)
function TestViopaOffTrackRefusal:test_a_duty_mission_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "duty" }), "duty mission in the datapad")
end

-- AC-5 (b)
function TestViopaOffTrackRefusal:test_a_story_mission_of_another_squadron_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "story" }), "other squadron's story mission in the datapad")
end

-- AC-5 (b), D-10: a Havoc story mission closes it too, and the pilot still sees the off-track greeting first
function TestViopaOffTrackRefusal:test_a_havoc_story_mission_in_the_datapad_closes_the_gate_after_the_off_track_greeting()
	assertRefused(open({ datapad = "havoc" }), "Havoc story mission in the datapad")
end

-- AC-5 (c): journal-only state, datapad empty (so only isOnMission can close the gate)
function TestViopaOffTrackRefusal:test_each_chain_or_duty_of_viopa_that_is_journal_active_closes_the_gate()
	for _, g in ipairs(O.VIOPA_ACTIVE) do
		H.reset()
		assertRefused(open({ active = { g } }), g .. " active")
	end
end

-- AC-5, D-10: getInitialScreen is unchanged, the datapad pilot is greeted by non_havoc_pilot, not another_mission
function TestViopaOffTrackRefusal:test_a_datapad_pilot_is_still_greeted_by_the_off_track_screen()
	local transcript = O.converse(O.VIOPA, open({ datapad = "story" }), {}, "Viopa")

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot" }, "greeting")
end

-- AC-5, I-4: the gate decides from the trainer's own function
function TestViopaOffTrackRefusal:test_the_handler_answers_can_fly_non_track_duty_like_the_link()
	lu.assertEquals(type(viopaConvoHandler.canFlyNonTrackDuty), "function", "viopaConvoHandler:canFlyNonTrackDuty")
	lu.assertEquals(type(viopaConvoHandler.isOnMission), "function", "viopaConvoHandler:isOnMission")

	local states = {
		{ "open", function() return open() end },
		{ "three skills", function() return O.pilot({ skills = O.allBut(O.REBEL_TIER1, 4) }) end },
		{ "no skill", function() return O.pilot({}) end },
		{ "datapad", function() return open({ datapad = "story" }) end },
		{ "journal", function() return open({ active = { O.VIOPA_ACTIVE[6] } }) end },
	}

	for _, s in ipairs(states) do
		H.reset()
		lu.assertEquals(viopaConvoHandler:canFlyNonTrackDuty(s[2]()), second(s[2]()) == "non_havoc_duty_offer", s[1] .. ": canFlyNonTrackDuty vs the link")
	end

	H.reset()
	lu.assertTrue(viopaConvoHandler:isOnMission(O.pilot({ active = { "recovery_duty_viopa_rebel_7" } })), "isOnMission with the recovery duty active")
	lu.assertTrue(viopaConvoHandler:isOnMission(O.pilot({ active = { "assassinate_viopa_rebel_4" } })), "isOnMission with chain 4 active")
	lu.assertFalse(viopaConvoHandler:isOnMission(open()), "isOnMission with nothing active")
end

-- AC-5, I-4
function TestViopaOffTrackRefusal:test_can_fly_non_track_duty_checks_the_datapad_and_the_tier_1_rule()
	local text = O.readFile(O.SOURCES.viopa[2])
	local s = text:find("function viopaConvoHandler:canFlyNonTrackDuty", 1, true)

	lu.assertNotNil(s, "definition of viopaConvoHandler:canFlyNonTrackDuty")

	local body = text:sub(s, text:find("\nend\n", s, true))

	lu.assertNotNil(body:find("not SpaceHelpers:hasSpaceQuest(pPlayer)", 1, true), "canFlyNonTrackDuty has the datapad clause")
	lu.assertNotNil(body:find("SpaceHelpers:hasCompletedPilotTier(pPlayer, \"rebel_navy\", 1)", 1, true), "canFlyNonTrackDuty has the all-four tier 1 rule")
	lu.assertNotNil(body:find("not self:isOnMission(pPlayer)", 1, true), "canFlyNonTrackDuty has the own-quests clause")
end

---------------------------------------------------------------------------------------------
-- AC-6: the duties, the decline and D-3 (no :introduced key)
---------------------------------------------------------------------------------------------

TestViopaOffTrackDuties = {}

function TestViopaOffTrackDuties:setUp() H.reset() end

local DUTY_WALKS = {
	{ "s_e02126d9", "intro_recovery_duty", O.VIOPA_RECOVERY, "recovery_duty", "viopa_rebel_7" },
	{ "s_cd3e2b38", "intro_escort_duty", O.VIOPA_ESCORT, "escort_duty", "viopa_rebel_5" },
	{ "s_1dfeca09", "intro_destroy_duty", O.VIOPA_DESTROY, "destroy_duty", "viopa_rebel_6" },
}

-- AC-6, I-5, D-3
function TestViopaOffTrackDuties:test_each_duty_reply_starts_only_its_duty_and_writes_nothing()
	for _, row in ipairs(DUTY_WALKS) do
		H.reset()

		local player = open()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		local transcript = ask(player, { "s_e84d85e2", row[1] })

		lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_offer", "non_havoc_duty_options", row[2] }, row[2] .. ": screens")
		lu.assertTrue(transcript[4].stop, row[2] .. " ends the conversation")
		lu.assertEquals(spies.starts, { row[3] }, row[2] .. ": quests started")
		lu.assertNil(H.getQuestStatus(player, INTRODUCED), row[2] .. ": " .. INTRODUCED)
		DE.noOtherEffects(spies, before, row[2])
	end
end

-- AC-6: the real starts, no spies
function TestViopaOffTrackDuties:test_the_real_duty_starts_work_for_a_pilot_of_another_squadron()
	for _, row in ipairs(DUTY_WALKS) do
		H.reset()

		local player = open({ squadron = rawget(_G, "VORTEX_SQUADRON") })

		ask(player, { "s_e84d85e2", row[1] })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, row[4], row[5]), row[4] .. "/" .. row[5] .. " active")
		lu.assertNil(H.getQuestStatus(player, INTRODUCED), row[4] .. ": " .. INTRODUCED)
	end
end

-- AC-6: "I have some quick things I need to fix first." starts nothing
function TestViopaOffTrackDuties:test_the_fix_things_first_reply_ends_on_intro_duty_goodbye_and_starts_nothing()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_e84d85e2", "s_cd1a5817" })

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_offer", "non_havoc_duty_options", "intro_duty_goodbye" }, "screens")
	lu.assertTrue(transcript[4].stop, "intro_duty_goodbye ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertNil(H.getQuestStatus(player, INTRODUCED), INTRODUCED)
	DE.noOtherEffects(spies, before, "intro_duty_goodbye")
end

-- AC-6: the decline
function TestViopaOffTrackDuties:test_i_would_rather_not_ends_on_the_decline_and_starts_nothing()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_e87a40f8" })

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_offer", "non_havoc_duty_decline" }, "screens")
	lu.assertEquals(transcript[3].text, V .. "s_39e697de", "non_havoc_duty_decline: leftDialog")
	lu.assertTrue(transcript[3].stop, "non_havoc_duty_decline ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertNil(H.getQuestStatus(player, INTRODUCED), INTRODUCED)
	DE.noOtherEffects(spies, before, "decline")
end

-- AC-6: the offer and the briefing alone grant nothing
function TestViopaOffTrackDuties:test_the_offer_and_the_briefing_alone_start_nothing()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()

	ask(player, { "s_e84d85e2" })
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written")
end

-- D-3: the off-track briefing is not accept_intro; a Havoc pilot's accept_intro still marks the introduction
function TestViopaOffTrackDuties:test_a_havoc_pilots_accept_intro_still_writes_the_introduced_key()
	local player = H.newPlayer({
		pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), faction = rawget(_G, "FACTIONREBEL"), pilotTier = 1,
		skills = O.concat({ "pilot_rebel_novice" }, O.REBEL_TIER1), experience = { space_combat_general = 0 },
	})
	local transcript = O.converse(O.VIOPA, player, { 0, 0 }, "Viopa")

	lu.assertEquals(G.ids(transcript), { "introduction", "intro_yes_milady", "accept_intro" }, "on-track introduction")
	lu.assertEquals(H.getQuestStatus(player, INTRODUCED), "1", INTRODUCED)
end

---------------------------------------------------------------------------------------------
-- I-3, I-6: template shape and on-track routing
---------------------------------------------------------------------------------------------

TestViopaTemplateShape = {}

function TestViopaTemplateShape:setUp() H.reset() end

local function requireScreen(id)
	return DE.requireScreen(O.VIOPA, id)
end

-- I-3 (C-3): the static link already fails closed
function TestViopaTemplateShape:test_the_static_gate_link_is_the_refusal()
	local s = requireScreen("non_havoc_pilot")

	lu.assertEquals(DE.staticOptions(s), { { V .. GATE, "non_havoc_no_missions" } }, "non_havoc_pilot: static options")
	lu.assertEquals(s.leftDialog, V .. "s_148ee1c2", "non_havoc_pilot: leftDialog")
	lu.assertEquals(s.stopConversation, "false", "non_havoc_pilot: stopConversation")
end

-- I-3: without the handler's re-pointing nobody reaches the offer
function TestViopaTemplateShape:test_the_handler_is_what_opens_the_offer()
	local passThrough = setmetatable({
		runScreenHandlers = function(self, pTemplate, pPlayer, pNpc, option, pScreen) return LuaConversationScreen(pScreen):cloneScreen() end,
	}, { __index = viopaConvoHandler })
	local ok, transcript = pcall(H.converse, { template = O.VIOPA, player = open(), npc = H.newNpc({ name = "Viopa" }), choices = { GATE }, handler = passThrough })

	lu.assertTrue(ok, "conversation with a pass-through handler: " .. tostring(transcript))
	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_no_missions" }, "screens without the re-pointing")
end

-- C-3
function TestViopaTemplateShape:test_the_four_new_screens_have_the_spec_values()
	for _, row in ipairs(O.VIOPA_SCREENS) do
		local s = requireScreen(row.id)
		local expected = {}

		for i, o in ipairs(row.options) do
			expected[i] = { V .. o[1], o[2] }
		end

		lu.assertEquals(s.leftDialog, V .. row.sid, row.id .. ": leftDialog")
		lu.assertEquals(s.animation, row.animation, row.id .. ": animation")
		lu.assertEquals(s.stopConversation, row.stop, row.id .. ": stopConversation")
		lu.assertEquals(DE.staticOptions(s), expected, row.id .. ": options")
	end
end

-- D-3: the off-track briefing has the text and replies of accept_intro, but it is its own screen
function TestViopaTemplateShape:test_the_off_track_briefing_is_a_copy_of_accept_intro_not_accept_intro()
	local copy, original = requireScreen("non_havoc_duty_options"), requireScreen("accept_intro")

	lu.assertEquals(copy.leftDialog, original.leftDialog, "same briefing text")
	lu.assertEquals(DE.staticOptions(copy), DE.staticOptions(original), "same four replies")
	lu.assertNotEquals(copy.id, original.id, "a separate screen")
end

-- I-6: a Havoc pilot is routed as before
function TestViopaTemplateShape:test_a_havoc_pilot_does_not_see_the_off_track_gate()
	local player = H.newPlayer({
		pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), faction = rawget(_G, "FACTIONREBEL"), pilotTier = 1,
		skills = O.concat({ "pilot_rebel_novice" }, O.REBEL_TIER1), experience = { space_combat_general = 0 },
	})

	lu.assertEquals(O.converse(O.VIOPA, player, {}, "Viopa")[1].id, "introduction", "first screen of a Havoc pilot with tier 1 done")
end

-- I-6: neutral and imperial pilots are routed as before
function TestViopaTemplateShape:test_other_pilots_are_routed_as_before()
	lu.assertEquals(O.converse(O.VIOPA, O.pilot({ kind = "neutral" }), {}, "Viopa")[1].id, "neutral_pilot", "neutral pilot")

	H.reset()
	lu.assertEquals(O.converse(O.VIOPA, H.newPlayer({ pilot = "imperial", skills = { "pilot_imperial_navy_novice" } }), {}, "Viopa")[1].id, "imperial_pilot", "imperial pilot")
end
