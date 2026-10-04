-- Kreezo (Havoc tier 1): the off-track duty offer and the refusal for a rebel pilot of another squadron.
-- Spec: .claude/work/space-offtrack-duty-gates/01-spec.md (AC-1 .. AC-3, I-3 .. I-6, D-8, D-11).

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local O = require("space_offtrack_duty_gates_data")

O.load()

local K = O.K
local GATE = O.GATE_K

local function ask(player, more)
	local choices = { GATE }

	for _, c in ipairs(more or {}) do
		choices[#choices + 1] = c
	end

	return O.converse(O.KREEZO, player, choices, "Kreezo")
end

local function second(player)
	local transcript = ask(player)

	return transcript[2] and transcript[2].id
end

local OPEN = { O.REBEL_TIER1[1] }

local function open(extra)
	extra = extra or {}
	extra.skills = extra.skills or OPEN

	return O.pilot(extra)
end

---------------------------------------------------------------------------------------------
-- AC-1: the offer
---------------------------------------------------------------------------------------------

TestKreezoOffTrackOffer = {}

function TestKreezoOffTrackOffer:setUp() H.reset() end

-- AC-1
function TestKreezoOffTrackOffer:test_a_clean_off_track_pilot_with_one_tier_1_skill_is_offered_the_two_duties()
	local transcript = ask(open())

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_options" }, "screens")
	lu.assertEquals(transcript[2].text, K .. "s_64977077", "non_havoc_duty_options: leftDialog")
	lu.assertFalse(transcript[2].stop, "non_havoc_duty_options: the conversation goes on")
	lu.assertEquals(O.pairsOf(transcript[2]), { { "s_d3ba53db", "non_havoc_destroy_duty" }, { "s_b17f599d", "non_havoc_escort_duty" } }, "non_havoc_duty_options: options")
end

-- AC-1: Kreezo's rule is "any one tier 1 skill", whichever it is
function TestKreezoOffTrackOffer:test_each_of_the_four_tier_1_skills_alone_opens_the_gate()
	for _, skill in ipairs(O.REBEL_TIER1) do
		H.reset()
		lu.assertEquals(G.ids(ask(open({ skills = { skill } })))[2], "non_havoc_duty_options", skill .. ": second screen")
	end
end

-- AC-1
function TestKreezoOffTrackOffer:test_all_four_tier_1_skills_open_the_gate_too()
	lu.assertEquals(G.ids(ask(open({ skills = O.REBEL_TIER1 })))[2], "non_havoc_duty_options", "second screen")
end

-- AC-1
function TestKreezoOffTrackOffer:test_pilots_of_every_other_rebel_squadron_get_the_menu()
	for name, squadron in pairs({ crimson = rawget(_G, "CRIMSON_PHOENIX_SQUADRON"), vortex = rawget(_G, "VORTEX_SQUADRON"), other = 99 }) do
		H.reset()
		lu.assertEquals(G.ids(ask(open({ squadron = squadron })))[2], "non_havoc_duty_options", name .. " pilot: second screen")
	end
end

-- AC-1: finished missions do not close the gate, only active ones
function TestKreezoOffTrackOffer:test_completed_quests_of_kreezo_do_not_close_the_gate()
	local player = open({ complete = O.KREEZO_ACTIVE })

	lu.assertEquals(G.ids(ask(player))[2], "non_havoc_duty_options", "second screen with every Kreezo quest complete")
end

-- AC-1, AC-9: the gate screen shows exactly one reply in both gate states
function TestKreezoOffTrackOffer:test_the_gate_screen_shows_exactly_the_one_reply_in_both_gate_states()
	for label, player in pairs({ open = open(), closed = O.pilot({}) }) do
		local transcript = ask(player)

		lu.assertEquals(transcript[1].id, "non_havoc_pilot", label .. ": first screen")
		lu.assertEquals(transcript[1].text, K .. "s_535b6177", label .. ": non_havoc_pilot line")
		lu.assertEquals(#transcript[1].options, 1, label .. ": number of replies on non_havoc_pilot")
		lu.assertEquals(O.sidOf(transcript[1].options[1].text), GATE, label .. ": the reply")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: the refusal
---------------------------------------------------------------------------------------------

TestKreezoOffTrackRefusal = {}

function TestKreezoOffTrackRefusal:setUp() H.reset() end

local function assertRefused(player, label)
	local spies = G.spies(player)
	local transcript = ask(player)

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_no_missions" }, label .. ": screens")
	lu.assertEquals(transcript[2].text, K .. "s_150b3020", label .. ": refusal line")
	lu.assertTrue(transcript[2].stop, label .. ": the refusal ends the conversation")
	lu.assertEquals(transcript[2].options, {}, label .. ": the refusal has no replies")
	lu.assertEquals(spies.starts, {}, label .. ": quests started")
end

-- AC-2 (a)
function TestKreezoOffTrackRefusal:test_a_pilot_without_any_tier_1_skill_gets_the_refusal()
	assertRefused(O.pilot({}), "no tier 1 skill")
end

-- AC-2 (a): a higher-tier skill is not a tier 1 skill
function TestKreezoOffTrackRefusal:test_a_pilot_with_only_a_tier_2_skill_gets_the_refusal()
	assertRefused(O.pilot({ skills = { "pilot_rebel_navy_starships_02" } }), "tier 2 skill only")
end

-- AC-2 (a): another profession's tier 1 skill does not count
function TestKreezoOffTrackRefusal:test_a_pilot_with_only_a_neutral_tier_1_skill_gets_the_refusal()
	assertRefused(O.pilot({ skills = { "pilot_neutral_starships_01" } }), "neutral tier 1 skill only")
end

-- AC-2 (b)
function TestKreezoOffTrackRefusal:test_a_duty_mission_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "duty" }), "duty mission in the datapad")
end

-- AC-2 (b)
function TestKreezoOffTrackRefusal:test_a_story_mission_of_another_squadron_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "story" }), "other squadron's story mission in the datapad")
end

-- AC-2 (b): from any squadron, including Kreezo's own
function TestKreezoOffTrackRefusal:test_a_havoc_story_mission_in_the_datapad_closes_the_gate()
	assertRefused(open({ datapad = "havoc" }), "Havoc story mission in the datapad")
end

-- AC-2 (c): journal-only state, datapad empty (so only isOnMission can close the gate)
function TestKreezoOffTrackRefusal:test_each_chain_or_duty_of_kreezo_that_is_journal_active_closes_the_gate()
	for _, g in ipairs(O.KREEZO_ACTIVE) do
		H.reset()
		assertRefused(open({ active = { g } }), g .. " active")
	end
end

-- AC-2, I-4: the gate decides from the trainer's own function
function TestKreezoOffTrackRefusal:test_the_handler_answers_can_fly_non_track_duty_like_the_link()
	lu.assertEquals(type(kreezoConvoHandler.canFlyNonTrackDuty), "function", "kreezoConvoHandler:canFlyNonTrackDuty")
	lu.assertEquals(type(kreezoConvoHandler.isOnMission), "function", "kreezoConvoHandler:isOnMission")

	local states = {
		{ "open", function() return open() end },
		{ "all four skills", function() return open({ skills = O.REBEL_TIER1 }) end },
		{ "no skill", function() return O.pilot({}) end },
		{ "datapad", function() return open({ datapad = "story" }) end },
		{ "journal", function() return open({ active = { O.KREEZO_ACTIVE[3] } }) end },
	}

	for _, s in ipairs(states) do
		H.reset()
		lu.assertEquals(kreezoConvoHandler:canFlyNonTrackDuty(s[2]()), second(s[2]()) == "non_havoc_duty_options", s[1] .. ": canFlyNonTrackDuty vs the link")
	end

	H.reset()
	lu.assertTrue(kreezoConvoHandler:isOnMission(O.pilot({ active = { "escort_duty_corellia_rebel_7" } })), "isOnMission with the escort duty active")
	lu.assertTrue(kreezoConvoHandler:isOnMission(O.pilot({ active = { "assassinate_corellia_rebel_4" } })), "isOnMission with chain 4 active")
	lu.assertFalse(kreezoConvoHandler:isOnMission(open()), "isOnMission with nothing active")
end

-- AC-2, I-4: the datapad clause is part of the function (SWG: !space_quest.hasQuest)
function TestKreezoOffTrackRefusal:test_can_fly_non_track_duty_checks_the_datapad_and_the_tier_1_rule()
	local text = O.readFile(O.SOURCES.kreezo[2])
	local s = text:find("function kreezoConvoHandler:canFlyNonTrackDuty", 1, true)

	lu.assertNotNil(s, "definition of kreezoConvoHandler:canFlyNonTrackDuty")

	local body = text:sub(s, text:find("\nend\n", s, true))

	lu.assertNotNil(body:find("not SpaceHelpers:hasSpaceQuest(pPlayer)", 1, true), "canFlyNonTrackDuty has the datapad clause")
	lu.assertNotNil(body:find("SpaceHelpers:hasPilotTierSkill(pPlayer, \"rebel_navy\", 1)", 1, true), "canFlyNonTrackDuty has the tier 1 skill rule")
	lu.assertNotNil(body:find("not self:isOnMission(pPlayer)", 1, true), "canFlyNonTrackDuty has the own-quests clause")
end

---------------------------------------------------------------------------------------------
-- AC-3: the duties
---------------------------------------------------------------------------------------------

TestKreezoOffTrackDuties = {}

function TestKreezoOffTrackDuties:setUp() H.reset() end

-- AC-3, I-5
function TestKreezoOffTrackDuties:test_the_patrol_roster_reply_starts_only_the_destroy_duty()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_d3ba53db" })

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_options", "non_havoc_destroy_duty" }, "screens")
	lu.assertEquals(transcript[3].text, K .. "s_dc243da2", "non_havoc_destroy_duty: leftDialog")
	lu.assertTrue(transcript[3].stop, "non_havoc_destroy_duty ends the conversation")
	lu.assertEquals(spies.starts, { O.KREEZO_DESTROY }, "quests started")
	require("space_trainer_dead_ends_data").noOtherEffects(spies, before, "destroy duty")
end

-- AC-3, I-5
function TestKreezoOffTrackDuties:test_the_transport_reply_starts_only_the_escort_duty()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_b17f599d" })

	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_duty_options", "non_havoc_escort_duty" }, "screens")
	lu.assertEquals(transcript[3].text, K .. "s_b282cc98", "non_havoc_escort_duty: leftDialog")
	lu.assertTrue(transcript[3].stop, "non_havoc_escort_duty ends the conversation")
	lu.assertEquals(spies.starts, { O.KREEZO_ESCORT }, "quests started")
	require("space_trainer_dead_ends_data").noOtherEffects(spies, before, "escort duty")
end

-- AC-3: the real starts, no spies
function TestKreezoOffTrackDuties:test_the_real_duty_starts_work_for_a_pilot_of_another_squadron()
	for _, row in ipairs({ { "s_d3ba53db", "destroy_duty", "corellia_rebel_6" }, { "s_b17f599d", "escort_duty", "corellia_rebel_7" } }) do
		H.reset()

		local player = open({ squadron = rawget(_G, "VORTEX_SQUADRON") })

		ask(player, { row[1] })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, row[2], row[3]), row[2] .. "/" .. row[3] .. " active")
	end
end

-- AC-3: the offer alone grants nothing
function TestKreezoOffTrackDuties:test_the_offer_alone_starts_nothing()
	local player = open()
	local spies = G.spies(player)
	local before = G.statusSnapshot()

	ask(player)
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written")
end

---------------------------------------------------------------------------------------------
-- I-3, I-6: template shape and on-track routing
---------------------------------------------------------------------------------------------

TestKreezoTemplateShape = {}

function TestKreezoTemplateShape:setUp() H.reset() end

local function requireScreen(id)
	local t = H.conversationTemplateTable(O.KREEZO)

	for _, s in ipairs(t.screens) do
		if s.id == id then
			return s
		end
	end

	lu.fail(O.KREEZO .. ": expected screen '" .. id .. "' to be defined")
end

local function staticOptions(s)
	local out = {}

	for i, o in ipairs(s.options or {}) do
		out[i] = { o[1], o[2] }
	end

	return out
end

-- I-3 (C-1): the static link already fails closed
function TestKreezoTemplateShape:test_the_static_gate_link_is_the_refusal()
	local s = requireScreen("non_havoc_pilot")

	lu.assertEquals(staticOptions(s), { { K .. GATE, "non_havoc_no_missions" } }, "non_havoc_pilot: static options")
	lu.assertEquals(s.leftDialog, K .. "s_535b6177", "non_havoc_pilot: leftDialog")
	lu.assertEquals(s.stopConversation, "false", "non_havoc_pilot: stopConversation")
end

-- I-3: without the handler's re-pointing nobody reaches the offer
function TestKreezoTemplateShape:test_the_handler_is_what_opens_the_offer()
	local passThrough = setmetatable({
		runScreenHandlers = function(self, pTemplate, pPlayer, pNpc, option, pScreen) return LuaConversationScreen(pScreen):cloneScreen() end,
	}, { __index = kreezoConvoHandler })
	local ok, transcript = pcall(H.converse, { template = O.KREEZO, player = open(), npc = H.newNpc({ name = "Kreezo" }), choices = { GATE }, handler = passThrough })

	lu.assertTrue(ok, "conversation with a pass-through handler: " .. tostring(transcript))
	lu.assertEquals(G.ids(transcript), { "non_havoc_pilot", "non_havoc_no_missions" }, "screens without the re-pointing")
end

-- C-1
function TestKreezoTemplateShape:test_the_four_new_screens_have_the_spec_values()
	for _, row in ipairs(O.KREEZO_SCREENS) do
		local s = requireScreen(row.id)
		local expected = {}

		for i, o in ipairs(row.options) do
			expected[i] = { K .. o[1], o[2] }
		end

		lu.assertEquals(s.leftDialog, K .. row.sid, row.id .. ": leftDialog")
		lu.assertEquals(s.animation, row.animation, row.id .. ": animation")
		lu.assertEquals(s.stopConversation, row.stop, row.id .. ": stopConversation")
		lu.assertEquals(staticOptions(s), expected, row.id .. ": options")
	end
end

-- I-6: on-track pilots keep the existing menu, and its duties still start
function TestKreezoTemplateShape:test_a_havoc_pilot_keeps_the_on_track_duty_menu_and_its_duties()
	for _, row in ipairs({ { "s_46fa0a69", "destroy_duty", "corellia_rebel_6" }, { "s_5c625403", "escort_duty", "corellia_rebel_7" } }) do
		H.reset()

		local player = H.newPlayer({
			pilot = "rebel", squadronType = rawget(_G, "HAVOC_SQUADRON"), faction = rawget(_G, "FACTIONREBEL"), pilotTier = 1,
			skills = { "pilot_rebel_novice", O.REBEL_TIER1[1] }, experience = { space_combat_general = 0 },
		})
		local transcript = O.converse(O.KREEZO, player, { "s_b4be0022", row[1] }, "Kreezo")

		lu.assertEquals(G.ids(transcript), { "duty_missions", "request_duty", row[2] }, "on-track screens")
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, row[2], row[3]), row[2] .. "/" .. row[3] .. " active")
	end
end

-- I-6: neutral and imperial pilots are routed as before
function TestKreezoTemplateShape:test_other_pilots_are_routed_as_before()
	local neutral = O.converse(O.KREEZO, O.pilot({ kind = "neutral" }), {}, "Kreezo")

	lu.assertEquals(neutral[1].id, "neutral_pilot", "neutral pilot")

	H.reset()

	local imperial = O.converse(O.KREEZO, H.newPlayer({ pilot = "imperial", skills = { "pilot_imperial_navy_novice" } }), {}, "Kreezo")

	lu.assertEquals(imperial[1].id, "imperial_pilot", "imperial pilot")
end
