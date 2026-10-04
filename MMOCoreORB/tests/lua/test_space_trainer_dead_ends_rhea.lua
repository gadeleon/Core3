-- Sgt. Rhea (CorSec tier 1): the off-track duty offer, the refusal and the "I need to take care of some things first" end screen.
-- Spec: .claude/work/space-trainer-dead-ends/01-spec.md (AC-1 .. AC-4, AC-8, invariants I-3 .. I-6).

local lu = require("luaunit")
local H = require("harness")
local G = require("rsf_gate_screens_data")
local D = require("space_trainer_dead_ends_data")

D.load()

local P = D.P
local GATE = "s_c1ff5062"
local DUTY6, DUTY7 = "destroy_duty_corellia_privateer_6", "escort_duty_corellia_privateer_7"

-- Talk to Rhea, ask for a mission, then follow `more`
local function ask(player, more)
	local choices = { GATE }

	for _, c in ipairs(more or {}) do
		choices[#choices + 1] = c
	end

	return D.converse(D.RHEA, player, choices, H.newNpc({ name = "Sgt. Rhea" }))
end

local function offered(player)
	return D.ids(ask(player))[2] == "not_corsec_duty_missions"
end

---------------------------------------------------------------------------------------------
-- AC-1: the offer
---------------------------------------------------------------------------------------------

TestRheaOffTrackOffer = {}

function TestRheaOffTrackOffer:setUp() H.reset() end

-- AC-1
function TestRheaOffTrackOffer:test_a_pilot_with_all_four_tier_1_skills_is_offered_the_duty_menu()
	local transcript = ask(D.pilot({ skills = D.TIER1 }))

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions" }, "screens")
	lu.assertEquals(transcript[2].text, P .. "s_dadaabf", "not_corsec_duty_missions: leftDialog")
	lu.assertFalse(transcript[2].stop, "not_corsec_duty_missions: the conversation goes on")
	lu.assertEquals(D.pairsOf(transcript[2]), D.RHEA_MENU, "not_corsec_duty_missions: options")
end

-- AC-1
function TestRheaOffTrackOffer:test_any_one_tier_1_skill_is_enough_for_the_duty_menu()
	for i, skill in ipairs(D.TIER1) do
		H.reset()

		local transcript = ask(D.pilot({ skills = { skill } }))

		lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions" }, "screens with only " .. skill)
		lu.assertEquals(D.pairsOf(transcript[2]), D.RHEA_MENU, "options with only " .. skill)
	end
end

-- AC-1
function TestRheaOffTrackOffer:test_pilots_of_every_other_squadron_get_the_menu()
	for name, squadron in pairs({ rsf = rawget(_G, "RSF_SQUADRON"), smuggler = rawget(_G, "SMUGGLER_SQUADRON"), other = 99 }) do
		H.reset()

		lu.assertEquals(D.ids(ask(D.pilot({ skills = { D.TIER1[1] }, squadron = squadron })))[2], "not_corsec_duty_missions", name .. " pilot: second screen")
	end
end

-- AC-1: finished missions and duties do not close the gate, only active ones
function TestRheaOffTrackOffer:test_completed_missions_of_rhea_do_not_close_the_gate()
	local player = D.pilot({ skills = D.TIER1, complete = D.RHEA_ACTIVE })

	lu.assertEquals(D.ids(ask(player))[2], "not_corsec_duty_missions", "second screen with every Rhea quest complete")
end

-- AC-8, I-3: the gate screen shows exactly one reply, whichever way the gate goes
function TestRheaOffTrackOffer:test_the_gate_screen_shows_exactly_the_one_reply_in_both_gate_states()
	for label, player in pairs({ open = D.pilot({ skills = D.TIER1 }), closed = D.pilot({}) }) do
		local transcript = ask(player)

		lu.assertEquals(D.pairsOf(transcript[1])[1] and D.pairsOf(transcript[1])[1][1], GATE, label .. ": the reply")
		lu.assertEquals(#transcript[1].options, 1, label .. ": number of replies on non_corsec_pilot")
		lu.assertEquals(transcript[1].text, P .. "s_ff684aed", label .. ": non_corsec_pilot line")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: the refusal
---------------------------------------------------------------------------------------------

TestRheaOffTrackRefusal = {}

function TestRheaOffTrackRefusal:setUp() H.reset() end

local function assertRefused(player, label)
	local spies = G.spies(player)
	local transcript = ask(player)

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "no_missions" }, label .. ": screens")
	lu.assertEquals(transcript[2].text, P .. "s_5b8a384b", label .. ": refusal line")
	lu.assertTrue(transcript[2].stop, label .. ": the refusal ends the conversation")
	lu.assertEquals(spies.starts, {}, label .. ": quests started")
end

-- AC-2 (a)
function TestRheaOffTrackRefusal:test_a_pilot_without_a_tier_1_skill_gets_the_refusal()
	assertRefused(D.pilot({}), "no tier 1 skill")
end

-- AC-2 (a)
function TestRheaOffTrackRefusal:test_tier_2_skills_alone_do_not_count_as_tier_1()
	assertRefused(D.pilot({ skills = { D.TIER2[1], D.TIER2[3] } }), "tier 2 skills only")
end

-- AC-2 (b)
function TestRheaOffTrackRefusal:test_a_duty_mission_in_the_datapad_closes_the_gate()
	assertRefused(D.pilot({ skills = D.TIER1, datapad = "duty" }), "duty mission in the datapad")
end

-- AC-2 (b)
function TestRheaOffTrackRefusal:test_a_story_mission_of_another_squadron_in_the_datapad_closes_the_gate()
	assertRefused(D.pilot({ skills = D.TIER1, datapad = "story" }), "other squadron's story mission in the datapad")
end

-- AC-2 (c): journal-only state, datapad empty (so only isOnMission can close the gate)
function TestRheaOffTrackRefusal:test_each_quest_of_rhea_that_is_journal_active_closes_the_gate()
	for _, q in ipairs(D.RHEA_ACTIVE) do
		H.reset()
		assertRefused(D.pilot({ skills = D.TIER1, active = { q } }), q[1] .. "/" .. q[2] .. " active")
	end
end

-- AC-2, I-4: the gate decides from the trainer's own function
function TestRheaOffTrackRefusal:test_the_handler_answers_can_fly_non_track_duty_like_the_link()
	lu.assertEquals(type(rheaConvoHandler.canFlyNonTrackDuty), "function", "rheaConvoHandler:canFlyNonTrackDuty")
	lu.assertEquals(type(rheaConvoHandler.isOnMission), "function", "rheaConvoHandler:isOnMission")

	local states = {
		{ "open", function() return D.pilot({ skills = D.TIER1 }) end },
		{ "one skill", function() return D.pilot({ skills = { D.TIER1[2] } }) end },
		{ "no skill", function() return D.pilot({}) end },
		{ "datapad", function() return D.pilot({ skills = D.TIER1, datapad = "duty" }) end },
		{ "journal", function() return D.pilot({ skills = D.TIER1, active = { D.RHEA_ACTIVE[7] } }) end },
	}

	for _, s in ipairs(states) do
		H.reset()

		local player = s[2]()
		local can = rheaConvoHandler:canFlyNonTrackDuty(player)

		lu.assertEquals(can, offered(s[2]()), s[1] .. ": canFlyNonTrackDuty vs the link")
	end

	H.reset()
	lu.assertTrue(rheaConvoHandler:isOnMission(D.pilot({ active = { D.RHEA_ACTIVE[8] } })), "isOnMission with the escort duty active")
	lu.assertFalse(rheaConvoHandler:isOnMission(D.pilot({ skills = D.TIER1 })), "isOnMission with nothing active")
end

---------------------------------------------------------------------------------------------
-- AC-3: the off-track duties
---------------------------------------------------------------------------------------------

TestRheaOffTrackDuties = {}

function TestRheaOffTrackDuties:setUp() H.reset() end

local function menuPlayer()
	return D.pilot({ skills = { D.TIER1[1] } })
end

-- AC-3
function TestRheaOffTrackDuties:test_the_pirate_leaders_start_destroy_duty_6()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_1a7f1a1b", "s_9e417b37" })

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", "what_missions", "destroy_duty" }, "screens")
	lu.assertTrue(transcript[4].stop, "destroy_duty ends the conversation")
	lu.assertEquals(spies.starts, { DUTY6 }, "quests started")
	D.noOtherEffects(spies, before, "pirate leaders")
end

-- AC-3
function TestRheaOffTrackDuties:test_escorting_merchants_start_escort_duty_7()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_1a7f1a1b", "s_221daf73" })

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", "what_missions", "escort_duty" }, "screens")
	lu.assertTrue(transcript[4].stop, "escort_duty ends the conversation")
	lu.assertEquals(spies.starts, { DUTY7 }, "quests started")
	D.noOtherEffects(spies, before, "escorting merchants")
end

-- AC-3: the real start, no spies: a pilot of another squadron can run the duty
function TestRheaOffTrackDuties:test_the_real_destroy_duty_start_works_for_a_pilot_of_another_squadron()
	local player = menuPlayer()

	ask(player, { "s_1a7f1a1b", "s_9e417b37" })

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "destroy_duty", "corellia_privateer_6"), "destroy_duty/corellia_privateer_6 active")
end

-- AC-3
function TestRheaOffTrackDuties:test_not_right_now_ends_on_not_right_now_and_starts_nothing()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()
	local transcript = ask(player, { "s_2883b989" })

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", "not_right_now" }, "screens")
	lu.assertTrue(transcript[3].stop, "not_right_now ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
	D.noOtherEffects(spies, before, "not right now")
end

-- AC-3
function TestRheaOffTrackDuties:test_nothing_right_now_on_the_mission_list_ends_on_not_right_now()
	local player = menuPlayer()
	local spies = G.spies(player)
	local transcript = ask(player, { "s_1a7f1a1b", "s_c35e70d2" })

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", "what_missions", "not_right_now" }, "screens")
	lu.assertEquals(spies.starts, {}, "quests started")
end

-- AC-3
function TestRheaOffTrackDuties:test_what_is_a_duty_mission_and_training_show_the_same_four_options()
	for reply, screen in pairs({ s_6106187c = "what_is_duty", s_6276c98 = "about_training" }) do
		H.reset()

		local player = menuPlayer()
		local spies = G.spies(player)
		local transcript = ask(player, { reply })

		lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", screen }, reply .. ": screens")
		lu.assertEquals(D.pairsOf(transcript[3]), D.RHEA_MENU, screen .. ": options")
		lu.assertFalse(transcript[3].stop, screen .. ": the conversation goes on")
		lu.assertEquals(spies.starts, {}, screen .. ": quests started")
	end
end

-- AC-3, I-5: wandering around the whole menu changes nothing but the chosen duty
function TestRheaOffTrackDuties:test_browsing_the_menu_has_no_side_effect()
	local player = menuPlayer()
	local spies = G.spies(player)
	local before = G.statusSnapshot()

	local transcript = ask(player, { "s_6106187c", "s_6276c98", "s_1a7f1a1b", "s_c35e70d2" })

	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "not_corsec_duty_missions", "what_is_duty", "about_training", "what_missions", "not_right_now" }, "screens")
	lu.assertEquals(spies.starts, {}, "quests started")
	D.noOtherEffects(spies, before, "browsing")
end

---------------------------------------------------------------------------------------------
-- AC-4: the "I need to take care of some things first" end screen
---------------------------------------------------------------------------------------------

TestRheaINeedTo = {}

function TestRheaINeedTo:setUp() H.reset() end

local JOIN, RIDICULOUS, SIGN_UP = "s_370822d1", "s_64b308bc", "s_e107077e"
local LATER = "s_68660d24"

-- Walk a new recruit to the "first assignment?" question and answer "I need to take care of some things first."
local function recruitLater(certifiedShip, tail)
	local player = H.newPlayer({ certifiedShip = certifiedShip, factionStanding = { corsec = 50 } })
	local spies = G.spies(player)
	local before

	local choices = { JOIN, RIDICULOUS, SIGN_UP }

	for _, c in ipairs(tail) do
		choices[#choices + 1] = c
	end

	choices[#choices + 1] = function() before = G.statusSnapshot() end
	choices[#choices + 1] = LATER

	local transcript = D.converse(D.RHEA, player, choices, H.newNpc({ name = "Sgt. Rhea" }))

	return transcript, player, spies, before
end

-- AC-4
function TestRheaINeedTo:test_the_template_has_the_closing_screen_with_the_client_line()
	local s = D.requireScreen(D.RHEA, "i_need_to")

	lu.assertEquals(s.leftDialog, P .. "s_c697d2d5", "i_need_to: leftDialog")
	lu.assertEquals(s.stopConversation, "true", "i_need_to: stopConversation")
	lu.assertEquals(D.staticOptions(s), {}, "i_need_to: options")
	lu.assertTrue(s.animation == nil or s.animation == "", "i_need_to: no animation, got " .. tostring(s.animation))
end

-- AC-4
function TestRheaINeedTo:test_thank_you_and_yes_ship_still_link_their_second_reply_to_i_need_to()
	for _, id in ipairs({ "thank_you", "yes_ship" }) do
		local s = D.requireScreen(D.RHEA, id)

		lu.assertEquals(D.staticOptions(s)[2], { P .. LATER, "i_need_to" }, id .. ": option 2")
	end
end

-- AC-4
function TestRheaINeedTo:test_a_shipless_recruit_who_needs_time_ends_on_i_need_to()
	local transcript, player, spies, before = recruitLater(false, { "s_5091cb8e", "s_b9b27823" })

	lu.assertEquals(D.ids(transcript), { "recruitment", "yes_join", "ridiculous", "maybe_great", "no_ship", "thank_you", "i_need_to" }, "screens")
	lu.assertEquals(transcript[7].text, P .. "s_c697d2d5", "i_need_to line")
	lu.assertTrue(transcript[7].stop, "i_need_to ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertEquals(#spies.chains, 0, "patrol_corellia_privateer_1 (startSpaceQuestChain) started")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written by the last step")
end

-- AC-4
function TestRheaINeedTo:test_a_recruit_with_a_certified_ship_who_needs_time_ends_on_i_need_to()
	local transcript, player, spies, before = recruitLater(true, { "s_90ec63e0" })

	lu.assertEquals(D.ids(transcript), { "recruitment", "yes_join", "ridiculous", "maybe_great", "yes_ship", "i_need_to" }, "screens")
	lu.assertEquals(transcript[6].text, P .. "s_c697d2d5", "i_need_to line")
	lu.assertTrue(transcript[6].stop, "i_need_to ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
	lu.assertEquals(#spies.chains, 0, "patrol_corellia_privateer_1 (startSpaceQuestChain) started")
	lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, "quest status keys written by the last step")
end

---------------------------------------------------------------------------------------------
-- AC-8, I-3, I-6: template shape
---------------------------------------------------------------------------------------------

TestRheaTemplateShape = {}

function TestRheaTemplateShape:setUp() H.reset() end

-- AC-8, I-3 (D-1 / C-1): the static link fails closed, the handler opens the offer
function TestRheaTemplateShape:test_the_static_gate_link_is_the_refusal()
	local s = D.requireScreen(D.RHEA, "non_corsec_pilot")

	lu.assertEquals(D.staticOptions(s), { { P .. GATE, "no_missions" } }, "non_corsec_pilot: static options")
	lu.assertEquals(s.leftDialog, P .. "s_ff684aed", "non_corsec_pilot: leftDialog")
	lu.assertEquals(s.stopConversation, "false", "non_corsec_pilot: stopConversation")
	lu.assertEquals(s.animation, "point_accusingly", "non_corsec_pilot: animation")
end

-- AC-8, I-3: without the handler's re-pointing nobody reaches the offer
function TestRheaTemplateShape:test_the_handler_is_what_opens_the_offer()
	local player = D.pilot({ skills = D.TIER1 })
	local passThrough = setmetatable({
		runScreenHandlers = function(self, pTemplate, pPlayer, pNpc, option, pScreen) return LuaConversationScreen(pScreen):cloneScreen() end,
	}, { __index = rheaConvoHandler })
	local ok, transcript = pcall(H.converse, { template = D.RHEA, player = player, npc = H.newNpc({ name = "Sgt. Rhea" }), choices = { GATE }, handler = passThrough })

	lu.assertTrue(ok, "conversation with a pass-through handler: " .. tostring(transcript))
	lu.assertEquals(D.ids(transcript), { "non_corsec_pilot", "no_missions" }, "screens without the re-pointing")
end

-- AC-1, C-2
function TestRheaTemplateShape:test_not_corsec_duty_missions_is_the_menu_with_its_old_line_and_animation()
	local s = D.requireScreen(D.RHEA, "not_corsec_duty_missions")

	lu.assertEquals(s.leftDialog, P .. "s_dadaabf", "leftDialog")
	lu.assertEquals(s.animation, "nod_head_once", "animation")
	lu.assertEquals(s.stopConversation, "false", "stopConversation")
	lu.assertEquals(D.staticOptions(s), D.asOptions(P, D.RHEA_MENU), "options")
end

-- AC-2, C-1: the refusal screen exists and ends the conversation
function TestRheaTemplateShape:test_no_missions_is_the_refusal_line_and_ends_the_conversation()
	local s = D.requireScreen(D.RHEA, "no_missions")

	lu.assertEquals(s.leftDialog, P .. "s_5b8a384b", "leftDialog")
	lu.assertEquals(s.stopConversation, "true", "stopConversation")
	lu.assertEquals(D.staticOptions(s), {}, "options")
end

-- I-6: the screens Rhea's CorSec pilots use keep their definitions
function TestRheaTemplateShape:test_the_corsec_duty_menu_is_unchanged()
	local s = D.requireScreen(D.RHEA, "duty_missions")

	lu.assertEquals(s.leftDialog, P .. "s_a48c20c8", "duty_missions: leftDialog")
	lu.assertEquals(D.staticOptions(s), D.asOptions(P, D.RHEA_MENU), "duty_missions: options")

	for _, id in ipairs({ "what_is_duty", "about_training" }) do
		lu.assertEquals(D.staticOptions(D.requireScreen(D.RHEA, id)), D.asOptions(P, D.RHEA_MENU), id .. ": options")
	end

	local nrn = D.requireScreen(D.RHEA, "not_right_now")

	lu.assertEquals(nrn.leftDialog, P .. "s_27d40413", "not_right_now: leftDialog")
	lu.assertEquals(nrn.stopConversation, "true", "not_right_now: stopConversation")
end

-- I-6: a CorSec pilot is routed as before
function TestRheaTemplateShape:test_a_corsec_pilot_still_gets_the_corsec_first_screens()
	local corsec = D.pilot({ skills = D.TIER1, squadron = rawget(_G, "CORSEC_SQUADRON") })

	lu.assertNotEquals(D.ids(D.converse(D.RHEA, corsec, {}))[1], "non_corsec_pilot", "a CorSec pilot is not sent to the off-track gate")
end
