-- Dinge (RSF tier 1): where the conversation starts once training sits behind the story (D-12, J's order).
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (AC-3; Conversation flow T1-T3, C4, C5, C9-C17; D-12, D-6).
-- J's order: the four mission checks come first and read quest state only; training and the duty menu are offered once mission 4 is
-- won and paid. A pilot who holds a tier 1 skill with the story unfinished is offered the next story screen.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")

T.load()

local tr = T.TRAINERS.dinge

local M1, S1 = "patrol_naboo_privateer_1", "destroy_surpriseattack_naboo_privateer_1"
local M2 = "destroy_naboo_privateer_2"
local M3, E3 = "patrol_naboo_privateer_3", "escort_naboo_privateer_3"
local M4 = "assassinate_naboo_privateer_tier1_4a"
local DUTY6, DUTY7 = "destroy_duty_naboo_privateer_6", "escort_duty_naboo_privateer_7"

local WIN = { 1, 2, 3, 4 }

local function xp(n) return { space_combat_general = n } end

-- M4 won and paid, the given tier 1 skills and space XP
local function paid(skills, amount)
	return T.player(tr, 4, { win = WIN, skills = skills, experience = xp(amount) })
end

local function firstScreen(player)
	return T.converse(tr, player)[1].id
end

local function initialScreenId(player)
	local tmpl = H.conversationTemplate(tr.template)
	local handler = H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Dinge conversation handler")
	local pScreen = handler:getInitialScreen(player, H.newNpc({}), tmpl)

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")
	return LuaConversationScreen(pScreen):getScreenID()
end

TestDingeTrainingRouting = {}

function TestDingeTrainingRouting:setUp() H.reset() end

-- AC-3 (a), T1
for _, amount in ipairs({ 0, 7500 }) do
	TestDingeTrainingRouting["test_row_a_mission_4_paid_and_no_tier_1_skill_starts_on_first_training_with_" .. amount .. "_xp"] = function()
		lu.assertEquals(initialScreenId(paid({}, amount)), "first_training", "getInitialScreen")
		lu.assertEquals(firstScreen(paid({}, amount)), "first_training", "first screen of the conversation")
	end
end

-- AC-3 (b), T2 and (c), T3: every combination of 1 to 3 skills
for _, list in ipairs(D.subsets()) do
	local label = D.label(list)

	TestDingeTrainingRouting["test_row_b_mission_4_paid_with_" .. label .. "_and_7500_xp_starts_on_more_training"] = function()
		lu.assertEquals(initialScreenId(paid(list, 7500)), "more_training", "getInitialScreen")
		lu.assertEquals(firstScreen(paid(list, 7500)), "more_training", "first screen of the conversation")
	end

	TestDingeTrainingRouting["test_row_b_mission_4_paid_with_" .. label .. "_and_much_xp_starts_on_more_training"] = function()
		lu.assertEquals(firstScreen(paid(list, 90000)), "more_training", "first screen of the conversation")
	end

	TestDingeTrainingRouting["test_row_c_mission_4_paid_with_" .. label .. "_and_7499_xp_starts_on_duty_missions"] = function()
		lu.assertEquals(initialScreenId(paid(list, 7499)), "duty_missions", "getInitialScreen")
		lu.assertEquals(firstScreen(paid(list, 7499)), "duty_missions", "first screen of the conversation")
	end
end

-- AC-3 (d), C5: all four skills, in any story state with no chain active
-- Builders for the story states of F7's C9 to C17, each taking extra T.player options (skills, experience)
local function build(n, base)
	return function(extra)
		local opts = {}

		for k, v in pairs(base) do opts[k] = v end
		for k, v in pairs(extra or {}) do opts[k] = v end
		return T.player(tr, n, opts)
	end
end

local STATES = {
	{ "c9_mission_4_won_not_paid", build(4, { complete = tr.chains[4] }), "mission4_reward" },
	{ "c10_mission_4_attempted_and_not_won", build(4, {}), "mission4_failed" },
	{ "c10_mission_4_never_attempted", build(4, { attempted = false }), "mission4_offer" },
	{ "c11_mission_3_won_not_paid", build(3, { complete = tr.chains[3] }), "mission3_reward" },
	{ "c12_mission_3_attempted_and_not_won", build(3, {}), "mission3_failed" },
	{ "c12_mission_3_head_won_child_failed", build(3, { complete = { tr.chains[3][1] } }), "mission3_failed" },
	{ "c12_mission_3_never_attempted", build(3, { attempted = false }), "mission3_offer" },
	{ "c13_mission_2_won_not_paid", build(2, { complete = tr.chains[2] }), "mission2_reward" },
	{ "c14_mission_2_attempted_and_not_won", build(2, {}), "mission2_failed" },
	{ "c14_mission_2_never_attempted", build(2, { attempted = false }), "mission2_offer" },
	{ "c15_mission_1_won_not_paid", build(1, { complete = tr.chains[1] }), "mission1_reward" },
	{ "c16_mission_1_head_running", build(1, { active = { M1 } }), "mission1_active" },
	{ "c16_mission_1_surprise_attack_running", build(1, { complete = { M1 }, active = { S1 } }), "mission1_active" },
	{ "c17_mission_1_attempted_and_not_won", build(1, {}), "mission1_failed" },
	{ "c17_mission_1_head_won_child_failed", build(1, { complete = { tr.chains[1][1] } }), "mission1_failed" },
	{ "c17_mission_1_never_attempted", build(1, { attempted = false }), "mission1_offer" },
}

for _, state in ipairs(STATES) do
	local name, make, want = state[1], state[2], state[3]

	-- AC-3 (d)
	TestDingeTrainingRouting["test_row_d_all_four_skills_start_on_completed_tier1_in_state_" .. name] = function()
		lu.assertEquals(firstScreen(make({ skills = D.SKILLS })), "completed_tier1", name)
	end

	-- AC-3 (f): one skill and 7500 XP does not change the screen the story state gets
	TestDingeTrainingRouting["test_row_f_one_skill_and_7500_xp_does_not_skip_the_story_in_state_" .. name] = function()
		lu.assertEquals(firstScreen(make({})), want, name .. ": the screen of a pilot with no tier 1 skill")

		for _, skill in ipairs(D.SKILLS) do
			lu.assertEquals(firstScreen(make({ skills = { skill }, experience = xp(7500) })), want, name .. ": with " .. skill .. " and 7500 xp")
		end
	end

	-- AC-3 (f): three skills and no XP either
	TestDingeTrainingRouting["test_row_f_three_skills_and_no_xp_does_not_skip_the_story_in_state_" .. name] = function()
		lu.assertEquals(firstScreen(make({ skills = { D.SKILLS[1], D.SKILLS[2], D.SKILLS[3] }, experience = xp(0) })), want, name)
	end
end

-- AC-3 (e): mission 4 won and not paid, one skill: the pilot is paid first
for _, amount in ipairs({ 0, 7500 }) do
	TestDingeTrainingRouting["test_row_e_mission_4_won_not_paid_with_one_skill_and_" .. amount .. "_xp_starts_on_mission4_reward"] = function()
		local player = T.player(tr, 4, { complete = tr.chains[4], skills = { D.SKILLS[1] }, experience = xp(amount) })

		lu.assertEquals(initialScreenId(player), "mission4_reward", "getInitialScreen")
		lu.assertEquals(firstScreen(player), "mission4_reward", "first screen of the conversation")
	end
end

-- AC-3 (g), C4: a duty running with one skill
for _, duty in ipairs({ { "duty_6", DUTY6 }, { "duty_7", DUTY7 } }) do
	TestDingeTrainingRouting["test_row_g_" .. duty[1] .. "_active_with_one_skill_starts_on_has_mission"] = function()
		local player = T.player(tr, 4, { win = WIN, skills = { D.SKILLS[1] }, experience = xp(7500), active = { duty[2] } })

		lu.assertEquals(initialScreenId(player), "has_mission", "getInitialScreen")
		lu.assertEquals(firstScreen(player), "has_mission", "first screen of the conversation")
	end
end

-- AC-3 (g): the same holds for a pilot who has no skill yet
function TestDingeTrainingRouting:test_row_g_a_duty_running_without_a_skill_starts_on_has_mission_not_first_training()
	local player = T.player(tr, 4, { win = WIN, active = { DUTY6 } })

	lu.assertEquals(firstScreen(player), "has_mission", "first screen of the conversation")
end

-- AC-3, T3: a finished duty puts the pilot back on the training routing
function TestDingeTrainingRouting:test_a_pilot_with_a_finished_duty_and_no_skill_is_offered_first_training()
	local player = T.player(tr, 4, { win = WIN, complete = { DUTY6 } })

	lu.assertEquals(firstScreen(player), "first_training", "first screen of the conversation")
end

-- D-12: getInitialScreen alone grants nothing in any of the T1-T3 states (the grant is on the reply)
function TestDingeTrainingRouting:test_get_initial_screen_grants_no_skill_in_the_training_states()
	local states = { paid({}, 0), paid({}, 7500), paid({ D.SKILLS[1] }, 7500), paid({ D.SKILLS[1] }, 0) }

	for i, player in ipairs(states) do
		local before = {}

		for _, skill in ipairs(D.SKILLS) do
			before[skill] = CreatureObject(player):hasSkill(skill)
		end

		initialScreenId(player)
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "state " .. i .. ": awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "state " .. i .. ": skillManagerAwardSkill calls")

		for _, skill in ipairs(D.SKILLS) do
			lu.assertEquals(CreatureObject(player):hasSkill(skill), before[skill], "state " .. i .. ": " .. skill)
		end
	end
end
