-- Captain Kaydine (RSF tier 2) duties at run time: what each duty option starts, routing to on_mission, the duty rules on the accept
-- screens, and the mission 4 reward that now comes before completed_kaydine.
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (AC-5, AC-6, AC-9, Conversation flow C1-C3, C10, invariant I-3).
--
-- The pilot builder (trainer_fixes_data.lua) seeds the migration marker "3", so none of these tests depends on migration; the migration
-- is in test_rsf_tier2_kaydine_duties_migration.lua. A tier 2 pilot "routed to here_for_work" has won and been paid for all four missions
-- (T.player(tr, 4, ...) with escort 15 complete and its :reward key set) and does not hold all four skills.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_duties_data")
local DR = require("duty_rules_scenario")

T.load()

local tr = T.TRAINERS.kaydine

local R14, E15 = "recovery_naboo_privateer_14", "escort_naboo_privateer_15"
local SKILLS_02 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }
local TIER1_DUTY = "destroy_duty_naboo_privateer_6"

-- A pilot who has finished the four missions and was paid (routes to here_for_work); opts as T.player
local function veteran(opts)
	opts = opts or {}

	local complete = { E15 }

	for _, g in ipairs(opts.complete or {}) do
		complete[#complete + 1] = g
	end

	return T.player(tr, 4, { complete = complete, active = opts.active, skills = opts.skills, zone = opts.zone, ship = opts.ship,
		questStatus = { ["naboo_privateer_15:reward"] = "1" } })
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Kaydine shows a first screen")
	return transcript[1].id
end

-- startQuest on every quest global replaced by a recorder: list of { global, player, npc }
local function spyStarts()
	local log = {}

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function(self, pPlayer, pNpc) log[#log + 1] = { global = name, player = pPlayer, npc = pNpc } end)
	end

	return log
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

-- Drives a conversation with an npc we keep, so the startQuest arguments can be compared
local function talk(player, choices)
	local npc = H.newNpc({ name = "Trainer" })

	return H.converse({ template = tr.template, player = player, npc = npc, choices = choices }), npc
end

---------------------------------------------------------------------------------------------
-- AC-5: the duty options start SWG's duties
---------------------------------------------------------------------------------------------

TestKaydineDutyGrants = {}

function TestKaydineDutyGrants:setUp() H.reset() end

-- AC-5 (setup): the pilot used below is routed to here_for_work
function TestKaydineDutyGrants:test_a_tier_2_pilot_who_finished_the_missions_is_routed_to_here_for_work()
	lu.assertEquals(firstScreen(veteran()), "here_for_work", "first screen")
end

for _, m in ipairs(D.MENU) do
	-- AC-5, C10
	TestKaydineDutyGrants["test_option_" .. m.option .. "_on_duty_options_starts_only_" .. m.global .. "_once_and_sends_no_plain_message"] = function()
		local player = veteran()
		local starts = spyStarts()
		local rewards = T.spyRewards()
		local transcript, npc = talk(player, { "s_4a1d2431", m.option })

		lu.assertEquals(ids(transcript), { "here_for_work", "duty_options", m.screen }, "screens")
		lu.assertTrue(transcript[3].stop, m.screen .. " ends the conversation")
		lu.assertEquals(#starts, 1, "startQuest calls on any quest")
		lu.assertEquals(starts[1].global, m.global, "the quest started")
		lu.assertTrue(starts[1].player == player and starts[1].npc == npc, m.global .. ": startQuest(player, npc)")
		lu.assertEquals(rewards.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(plainMessages(player), {}, "plain-text system messages")
	end

	-- AC-5: the same options on the mission 3 duty line
	TestKaydineDutyGrants["test_option_" .. m.option .. "_on_the_mission_3_duty_line_starts_only_" .. m.global .. "_once"] = function()
		local player = T.player(tr, 3, { complete = { R14 } })
		local starts = spyStarts()
		local transcript, npc = talk(player, { 0, "s_6114e8b7", m.option })

		lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "mission3_reward_duty", m.screen }, "screens")
		lu.assertEquals(#starts, 1, "startQuest calls on any quest")
		lu.assertEquals(starts[1].global, m.global, "the quest started")
		lu.assertTrue(starts[1].player == player and starts[1].npc == npc, m.global .. ": startQuest(player, npc)")
		lu.assertEquals(plainMessages(player), {}, "plain-text system messages")
	end
end

-- AC-5: entering the greeting and the menu starts nothing
function TestKaydineDutyGrants:test_the_greeting_and_the_menu_start_nothing()
	local player = veteran()
	local starts = spyStarts()
	local transcript = talk(player, { "s_4a1d2431" })

	lu.assertEquals(ids(transcript), { "here_for_work", "duty_options" }, "screens")
	lu.assertEquals(#starts, 0, "startQuest calls")
	lu.assertEquals(plainMessages(player), {}, "plain-text system messages")
end

-- AC-5, I-3: the k-th option of the duty menu starts the quest RSF's TIER2_QUEST_STRING_DUTY_k names
function TestKaydineDutyGrants:test_the_kth_option_starts_the_quest_of_the_kth_duty_constant()
	for k, m in ipairs(D.MENU) do
		H.reset()

		local dutyString = RsfSquadronScreenplay["TIER2_QUEST_STRING_DUTY_" .. k]

		lu.assertNotNil(dutyString, "TIER2_QUEST_STRING_DUTY_" .. k)

		local starts = spyStarts()

		talk(veteran(), { "s_4a1d2431", k - 1 })
		lu.assertEquals(#starts, 1, "option " .. k .. ": startQuest calls")
		lu.assertEquals(starts[1].global, dutyString.type .. "_" .. dutyString.name, "option " .. k .. ": the quest started is TIER2_QUEST_STRING_DUTY_" .. k)
		lu.assertEquals(starts[1].global, m.global, "option " .. k .. ": the quest started is the duty menu's " .. k .. "th")
	end
end

-- AC-5: the real startQuest (no spies) makes the duty active with one flagged datapad mission, for each option
function TestKaydineDutyGrants:test_the_real_start_makes_exactly_the_chosen_duty_active_with_one_flagged_mission()
	for _, m in ipairs(D.MENU) do
		H.reset()

		local player = veteran()

		talk(player, { "s_4a1d2431", m.option })
		H.advance(0)

		for _, other in ipairs(D.GLOBALS) do
			lu.assertEquals(T.state(player, other), other == m.global and "active" or "none", m.global .. " chosen: journal state of " .. other)
		end

		lu.assertEquals(#player.datapad.items, 1, m.global .. ": datapad missions")
		lu.assertEquals(#DR.flaggedMissions(player), 1, m.global .. ": flagged duty missions")
		lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 0, m.global .. ": duty_already messages")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: routing and the duty rules
---------------------------------------------------------------------------------------------

TestKaydineDutyRouting = {}

function TestKaydineDutyRouting:setUp() H.reset() end

for _, global in ipairs(D.GLOBALS) do
	-- AC-6, C1
	TestKaydineDutyRouting["test_" .. global .. "_running_shows_on_mission"] = function()
		local player = veteran({ active = { global } })
		local starts = spyStarts()

		lu.assertEquals(firstScreen(player), "on_mission", global .. ": first screen")
		lu.assertEquals(#starts, 0, "startQuest calls")
	end

	-- AC-6, C1: a running duty also wins over a pending reward screen
	TestKaydineDutyRouting["test_" .. global .. "_running_wins_over_the_mission_4_reward"] = function()
		local player = T.player(tr, 4, { complete = { E15 }, active = { global } })

		lu.assertEquals(firstScreen(player), "on_mission", global .. ": first screen")
	end

	-- AC-6: a completed entry of the duty does not keep the pilot on the mission
	TestKaydineDutyRouting["test_" .. global .. "_only_completed_does_not_show_on_mission"] = function()
		local player = veteran({ complete = { global } })

		lu.assertEquals(firstScreen(player), "here_for_work", global .. ": first screen with a completed entry")
	end
end

-- AC-6: a pilot with no duty entry at all and a pilot who has finished the missions see the same greeting
function TestKaydineDutyRouting:test_a_cleared_duty_entry_does_not_show_on_mission()
	local player = veteran()

	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": setup: no entry")
	end

	lu.assertEquals(firstScreen(player), "here_for_work", "first screen")
end

for _, m in ipairs(D.MENU) do
	-- AC-6: another duty (RSF tier 1 destroy duty 6 does not route to on_mission) refuses the second one
	TestKaydineDutyRouting["test_holding_another_duty_refuses_" .. m.global .. "_with_duty_already_but_shows_the_accept_line"] = function()
		local player = veteran()

		DR.holdDuty(player, TIER1_DUTY)
		lu.assertEquals(firstScreen(player), "here_for_work", "setup: a held tier 1 duty does not route to on_mission")

		local before = DR.snapshot(player)
		local transcript = talk(player, { "s_4a1d2431", m.option })

		lu.assertEquals(ids(transcript), { "here_for_work", "duty_options", m.screen }, "the accept line is shown")
		lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, "@space/quest:duty_already messages")
		lu.assertEquals(#player.datapad.items, 1, "datapad missions")
		lu.assertEquals(#DR.flaggedMissions(player), 1, "flagged duty missions")
		lu.assertEquals(T.state(player, m.global), "none", m.global .. ": journal state")
		lu.assertEquals(DR.snapshot(player).createObserver, before.createObserver, "no observer created")
	end

	-- AC-6: the same on the mission 3 duty line
	TestKaydineDutyRouting["test_holding_another_duty_refuses_" .. m.global .. "_from_the_mission_3_duty_line_too"] = function()
		local player = T.player(tr, 3, { complete = { R14 } })

		DR.holdDuty(player, TIER1_DUTY)

		local transcript = talk(player, { 0, "s_6114e8b7", m.option })

		lu.assertEquals(transcript[#transcript].id, m.screen, "last screen")
		lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, "@space/quest:duty_already messages")
		lu.assertEquals(#player.datapad.items, 1, "datapad missions")
		lu.assertEquals(T.state(player, m.global), "none", m.global .. ": journal state")
	end

	-- AC-6: after the duty ended it can be taken again (and is not refused)
	TestKaydineDutyRouting["test_" .. m.global .. "_can_be_taken_again_after_it_ended"] = function()
		local player = veteran()

		talk(player, { "s_4a1d2431", m.option })
		H.advance(0)
		lu.assertEquals(T.state(player, m.global), "active", "first start")

		H.expectGlobal(m.global, "Kaydine duty quest table"):failQuest(player, "true")
		H.advance(0)
		lu.assertEquals(T.state(player, m.global) ~= "active", true, "the duty is no longer active after failQuest")
		lu.assertEquals(#player.datapad.items, 0, "datapad missions after the end")
		lu.assertEquals(firstScreen(player), "here_for_work", "Kaydine after the end")

		talk(player, { "s_4a1d2431", m.option })
		H.advance(0)
		lu.assertEquals(T.state(player, m.global), "active", "second start")
		lu.assertEquals(#player.datapad.items, 1, "datapad missions after the second start")
		lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 0, "duty_already messages")
	end
end

-- AC-6: a completed entry of escort 9 does not block a retake either
function TestKaydineDutyRouting:test_a_completed_entry_of_the_duty_is_cleared_and_taken_again()
	local player = veteran({ complete = { D.ESCORT } })

	talk(player, { "s_4a1d2431", "s_9b73da8" })
	H.advance(0)
	lu.assertEquals(T.state(player, D.ESCORT), "active", "state after the retake")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions")
end

---------------------------------------------------------------------------------------------
-- AC-9: the mission 4 reward comes before completed_kaydine (D-8)
---------------------------------------------------------------------------------------------

TestKaydineMission4RewardGate = {}

function TestKaydineMission4RewardGate:setUp() H.reset() end

-- AC-9: three visits of a pilot with all four skills and an unpaid mission 4
function TestKaydineMission4RewardGate:test_an_unpaid_mission_4_is_paid_once_then_completed_kaydine_raises_the_tier_and_a_third_visit_pays_nothing()
	local player = T.player(tr, 4, { complete = { E15 }, skills = SKILLS_02 })
	local rec = T.spyRewards()

	lu.assertEquals(player.ghost:getPilotTier(), 2, "setup: pilot tier")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_15:reward"), "setup: 15:reward unset")

	-- visit 1: the reward screen is first, the tier is not raised by routing
	lu.assertEquals(firstScreen(player), "mission4_complete", "first screen, visit 1")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after routing, visit 1")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls on the first screen")

	-- following s_588f56b2 pays mission 4
	local transcript = T.converse(tr, player, { "s_588f56b2" })

	lu.assertEquals(ids(transcript), { "mission4_complete", "mission4_reward" }, "screens, visit 1")
	lu.assertEquals(rec.rewards, { E15 }, "rewardPlayer calls after mission4_reward")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_15:reward"), "1", "15:reward after the payment")

	-- visit 2: completed_kaydine, the tier is raised to 3
	lu.assertEquals(firstScreen(player), "completed_kaydine", "first screen, visit 2")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after visit 2")

	-- visit 3: nothing is paid again
	lu.assertEquals(firstScreen(player), "completed_kaydine", "first screen, visit 3")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after visit 3")
	lu.assertEquals(rec.rewards, { E15 }, "rewardPlayer calls over three visits")
end

-- AC-9: with 15:reward set (migrated veterans too) the first screen is completed_kaydine as before
function TestKaydineMission4RewardGate:test_a_paid_mission_4_with_all_four_skills_shows_completed_kaydine_and_raises_the_tier()
	local player = T.player(tr, 4, { complete = { E15 }, skills = SKILLS_02, questStatus = { ["naboo_privateer_15:reward"] = "1" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "completed_kaydine", "first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-9: the unpaid case without the skills is the reward screen too (unchanged)
function TestKaydineMission4RewardGate:test_an_unpaid_mission_4_without_the_skills_shows_mission4_complete()
	local player = T.player(tr, 4, { complete = { E15 } })

	lu.assertEquals(firstScreen(player), "mission4_complete", "first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

-- AC-9: a tier 2 pilot with the skills but only mission 3 won does not reach completed_kaydine (the win is escort 15)
function TestKaydineMission4RewardGate:test_a_pilot_with_all_skills_who_has_not_won_mission_4_is_not_completed_kaydine()
	local player = T.player(tr, 3, { complete = { R14 }, skills = SKILLS_02, questStatus = { ["naboo_privateer_14:reward"] = "1" } })

	lu.assertNotEquals(firstScreen(player), "completed_kaydine", "first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

-- AC-9, C1: a running duty still wins over the reward
function TestKaydineMission4RewardGate:test_a_running_duty_wins_over_the_unpaid_mission_4_reward()
	local player = T.player(tr, 4, { complete = { E15 }, skills = SKILLS_02, active = { D.DESTROY } })

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
end
