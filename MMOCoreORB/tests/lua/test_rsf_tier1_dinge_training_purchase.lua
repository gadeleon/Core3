-- Dinge (RSF tier 1) SWG training: the free first skill, the greeting and prompts, the three purchases (one skill per visit, through the
-- XP-deducting grant), the guard and its fallback, the tier 1 -> 2 hand-off to Kaydine, the skill cost fixture and the five-visit scenario.
-- Spec: .claude/work/rsf-tier1-dinge-training/01-spec.md (AC-4 .. AC-7; Content contract 2; invariants I-4, I-5; D-3, D-4, D-5, D-8, D-13), re-pinned to the
-- pre-NGE one-click training by .claude/work/space-convo-client-strings-dinge/01-spec.md (AC-7 .. AC-9; D-4, D-5, D-6, D-9; Appendix A: 67 tests of this file):
-- the choice is made on first_training (free) or more_training (paid) and ends on trained_<x> ("Good choice.", s_cd72f93); the lesson step and the train_<x>
-- prompt-and-confirm screens are gone. Every guard (skill held, XP gone, engine refuses), the tier 1 -> 2 raise and "one skill per visit" are asserted as before.
--
-- The harness fake charges nothing by itself. Tests that look at XP switch on H.Engine.config.skillXpCosts with the XP_COST of every tier 1
-- skill read from fixtures/skill/skills.pilot_neutral_01.tab (7500 space_combat_general), which makes the fake refuse and charge like
-- SkillManager::awardSkill. H.Engine.callsTo("awardSkill") is the free grant (the pilot's pick on first_training since pilot-training-free-choice),
-- callsTo("skillManagerAwardSkill") the XP-deducting one. The fake fulfillsSkillPrerequisitesAndXp always says yes, so the engine-refusal
-- case replaces LuaSkillManager (R-5).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")
local K = require("rsf_tier2_kaydine_training_data") -- K.drive: start a conversation on a given screen
local C = require("pilot_training_free_choice_data") -- pilot-training-free-choice: the choice replaces s_141 and s_143

T.load()

local tr = T.TRAINERS.dinge
local P = D.PREFIX
local COST = 7500
local WIN = { 1, 2, 3, 4 }
local REAL_SKILL_MANAGER = LuaSkillManager

local function costs()
	local out = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_01.tab").records) do
		local name = rec:get("NAME")

		if name:match("^pilot_neutral_%a+_01$") then
			out[name] = rec:num("XP_COST")
		end
	end

	H.Engine.config.skillXpCosts = out
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function texts(options)
	local out = {}

	for i, o in ipairs(options) do
		out[i] = o.text
	end

	return out
end

-- M4 won and paid, `skills` held, `amount` space XP
local function pilot(skills, amount)
	return T.player(tr, 4, { win = WIN, skills = skills, experience = { space_combat_general = amount } })
end

local function free() return H.Engine.callsTo("awardSkill") end
local function bought() return H.Engine.callsTo("skillManagerAwardSkill") end

local function held(player)
	local out = {}

	for _, skill in ipairs(D.SKILLS) do
		if CreatureObject(player):hasSkill(skill) then
			out[#out + 1] = skill
		end
	end

	return out
end

-- The first skills of SWG's order, `count` of them
local function firstSkills(count)
	local out = {}

	for i = 1, count do
		out[i] = D.SKILLS[i]
	end

	return out
end

-- The first screen a pilot in this state would get, built independently of the pilot under test
local function freshFirstScreen(skills, amount)
	return T.converse(tr, pilot(skills, amount))[1].id
end

local function withEngineRefusal()
	LuaSkillManager = function()
		local real = REAL_SKILL_MANAGER()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = real })
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the first training (free)
---------------------------------------------------------------------------------------------

TestDingeFirstTraining = {}

function TestDingeFirstTraining:setUp() H.reset() end
function TestDingeFirstTraining:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-4; F2 AC-7: first_training shows s_5e36283d with the four choice replies right away (no s_139 / lesson step)
function TestDingeFirstTraining:test_first_training_shows_s_5e36283d_with_the_four_choice_replies_and_no_lesson_step()
	local transcript = T.converse(tr, pilot({}, 0))

	lu.assertEquals(ids(transcript), { "first_training" }, "screens")
	lu.assertEquals(transcript[1].text, P .. "s_5e36283d", "first_training: NPC line")
	lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.DINGE, {}, "closing"), "first_training: options (reply, link)")
	lu.assertFalse(transcript[1].stop, "first_training does not end the conversation")

	for _, o in ipairs(transcript[1].options) do
		lu.assertNotEquals(o.text, P .. "s_139", "the NGE lesson reply is not offered")
		lu.assertNotEquals(o.link, "first_training_lesson", "no link to the deleted lesson")
	end
end

-- AC-4, I-5: nothing is granted while first_training is displayed
function TestDingeFirstTraining:test_nothing_is_granted_while_first_training_is_displayed()
	costs()

	local player = pilot({}, COST)
	local transcript = T.converse(tr, player)

	lu.assertEquals(ids(transcript), { "first_training" }, "screens")
	lu.assertEquals(#free(), 0, "awardSkill calls")
	lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
	lu.assertEquals(held(player), {}, "tier 1 skills held")
	lu.assertEquals(exp(player), COST, "space_combat_general")
end

-- AC-4, D-13; F2 AC-7: the first reply (starships, nothing held) grants starships once through the free path and charges nothing; the conversation ends
-- on trained_starships ("Good choice.")
for _, amount in ipairs({ 0, COST, 3 * COST }) do
	TestDingeFirstTraining["test_choosing_the_first_reply_grants_starships_01_once_for_free_with_" .. amount .. "_xp_and_ends_on_trained_starships"] = function()
		costs()

		local player = pilot({}, amount)
		local transcript = T.converse(tr, player, { 0 })

		lu.assertEquals(ids(transcript), { "first_training", "trained_starships" }, "screens")
		lu.assertEquals(transcript[2].text, P .. "s_cd72f93", "trained_starships: NPC line (Good choice.)")
		lu.assertTrue(transcript[2].stop, "trained_starships ends the conversation")
		lu.assertEquals(transcript[2].options, {}, "trained_starships: options")

		local calls = free()

		lu.assertEquals(#calls, 1, "awardSkill calls")
		lu.assertTrue(calls[1][1] == player, "awardSkill player")
		lu.assertEquals(calls[1][2], "pilot_neutral_starships_01", "awardSkill skill")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(held(player), { "pilot_neutral_starships_01" }, "tier 1 skills held (no other skill is granted)")
		lu.assertEquals(exp(player), amount, "space_combat_general is unchanged")
		lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier stays 1")
	end
end

-- AC-4, I-4: the grant is announced once
function TestDingeFirstTraining:test_the_free_grant_sends_one_skill_learned_message()
	local player = pilot({}, 0)
	local before = #H.messageLog(player)

	T.converse(tr, player, { 0, 0 })

	local log = H.messageLog(player)

	lu.assertEquals(#free(), 1, "awardSkill calls (the message belongs to the free grant)")
	lu.assertEquals(#log - before, 1, "system messages")
	lu.assertEquals(log[#log].TO, "@skl_n:pilot_neutral_starships_01", "skill named in the message")
end

-- AC-4, D-4: a pilot who holds any tier 1 skill when a reply is chosen gets nothing and sees the fresh first screen
for _, skill in ipairs(D.SKILLS) do
	for _, amount in ipairs({ 0, COST }) do
		TestDingeFirstTraining["test_holding_" .. skill:match("_(%a+)_01$") .. "_when_a_choice_reply_is_chosen_with_" .. amount .. "_xp_grants_nothing_and_restarts_the_conversation"] = function()
			costs()

			local player = pilot({}, amount)
			local transcript = T.converse(tr, player, {
				function(p) p.skills[skill] = true end, -- the skill arrives while first_training is shown
				0,
			})

			lu.assertEquals(transcript[1].id, "first_training", "first screen")
			lu.assertEquals(#free(), 0, "awardSkill calls")
			lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
			lu.assertEquals(held(player), { skill }, "tier 1 skills held")
			lu.assertEquals(exp(player), amount, "space_combat_general")
			lu.assertEquals(#transcript, 2, "screens")
			lu.assertEquals(transcript[2].id, freshFirstScreen({ skill }, amount), "second screen is the fresh first screen of that pilot")
			lu.assertNotEquals(transcript[2].id, "trained_starships", "no success line for a skill that was not granted")
		end
	end
end

-- AC-4, D-4: with a tier 1 skill held, the handler does not even call grantSpaceSkill; otherwise exactly one free call for starships
function TestDingeFirstTraining:test_the_choice_calls_grant_space_skill_once_with_deduct_false_for_starships_and_never_when_a_skill_is_held()
	local player = pilot({}, COST)
	local calls = H.spyOn(SpaceHelpers, "grantSpaceSkill")

	T.converse(tr, player, { 0 })
	lu.assertEquals(#calls, 1, "grantSpaceSkill calls")
	lu.assertEquals({ calls[1].args[2], calls[1].args[3] }, { "pilot_neutral_starships_01", false }, "grantSpaceSkill (skill, deductExperience)")

	H.reset()

	local holder = pilot({}, COST)
	local calls2 = H.spyOn(SpaceHelpers, "grantSpaceSkill")

	T.converse(tr, holder, { function(p) p.skills[D.SKILLS[3]] = true end, 0 })
	lu.assertEquals(#calls2, 0, "grantSpaceSkill calls when a skill is held at the moment of choosing")
end

-- AC-4: first_training reached again after the grant grants nothing (exactly once); it then offers the three skills still missing
function TestDingeFirstTraining:test_choosing_a_reply_twice_grants_one_skill()
	costs()

	local player = pilot({}, COST)

	T.converse(tr, player, { 0 })
	lu.assertEquals(#free(), 1, "awardSkill calls after the first conversation")

	K.drive(tr, player, "first_training", { 0 })
	lu.assertEquals(#free(), 1, "awardSkill calls after choosing on first_training again")
	lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
	lu.assertEquals(held(player), { "pilot_neutral_starships_01" }, "tier 1 skills held")
	lu.assertEquals(exp(player), COST, "space_combat_general")
end

-- AC-4: the free path is closed to a pilot who holds only a later skill (D-8)
function TestDingeFirstTraining:test_first_training_gives_a_pilot_who_already_holds_droid_nothing_free()
	costs()

	local player = pilot({ D.SKILLS[4] }, COST)

	K.drive(tr, player, "first_training", { 0 })
	lu.assertEquals(#free(), 0, "awardSkill calls")
	lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
	lu.assertEquals(held(player), { D.SKILLS[4] }, "tier 1 skills held")
end

-- AC-4, I-4: nothing but a reply on first_training grants for free (the same replies on more_training are the paid path)
function TestDingeFirstTraining:test_the_free_path_is_used_for_nothing_else()
	for i, c in ipairs(C.DINGE) do
		H.reset()
		costs()

		local player = pilot({}, 4 * COST)

		K.drive(tr, player, "more_training", { i - 1 })
		lu.assertEquals(#free(), 0, c.x .. " on more_training: awardSkill calls")
		lu.assertEquals(#bought(), 1, c.x .. " on more_training: skillManagerAwardSkill calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: greeting and closing lines
---------------------------------------------------------------------------------------------

TestDingeMoreTraining = {}

function TestDingeMoreTraining:setUp() H.reset() end
function TestDingeMoreTraining:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-5; F2 AC-8: the greeting offers the choice replies of the missing skills, each linking straight to its trained_<x> screen
function TestDingeMoreTraining:test_more_training_greets_the_pilot_by_name_with_the_choice_replies_of_the_missing_skills()
	local transcript = T.converse(tr, pilot({ D.SKILLS[1] }, COST))

	lu.assertEquals(transcript[1].id, "more_training", "first screen")
	lu.assertEquals(transcript[1].text, P .. "s_122b0165", "more_training: NPC line")
	lu.assertEquals(transcript[1].params.TU, "Ace", "more_training: %TU")
	lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.DINGE, C.set({ D.SKILLS[1] }), "closing"), "more_training: options (reply, link)")
	lu.assertFalse(transcript[1].stop, "more_training does not end the conversation")
end

-- AC-5, E-PN2; F2 AC-8: for every 1 to 3 skill subset the replies are the missing skills' in SWG order and the first one links to the trained_<x> screen of the first
-- skill the pilot lacks
for _, list in ipairs(D.subsets()) do
	local first
	local held_ = C.set(list)

	for _, t in ipairs(D.TRAINING) do
		if not held_[t.skill] and first == nil then first = t.closing end
	end

	TestDingeMoreTraining["test_more_training_for_a_pilot_holding_" .. D.label(list) .. "_offers_the_missing_skills_starting_with_" .. first] = function()
		local transcript = T.converse(tr, pilot(list, COST))

		lu.assertEquals(ids(transcript), { "more_training" }, "screens")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.DINGE, held_, "closing"), "more_training: options (reply, link)")
		lu.assertEquals(transcript[1].options[1].link, first, "more_training: link of the first reply")
	end
end

-- AC-5; F2 D-9: every trained_<x> screen shows "Good choice.", has no options and ends the conversation; it is reached by the natural walk (the pilot holds the
-- skills before it in SWG order) with one click on the choice reply
for k, t in ipairs(D.TRAINING) do
	TestDingeMoreTraining["test_" .. t.closing .. "_shows_s_cd72f93_good_choice_with_no_options_and_ends_the_conversation"] = function()
		costs()

		local list = k == 1 and { D.SKILLS[2], D.SKILLS[3], D.SKILLS[4] } or firstSkills(k - 1)
		local transcript = T.converse(tr, pilot(list, COST), { C.DINGE[k].sid })

		lu.assertEquals(ids(transcript), { "more_training", t.closing }, "screens")
		lu.assertEquals(transcript[2].text, P .. "s_cd72f93", t.closing .. ": NPC line")
		lu.assertEquals(transcript[2].options, {}, t.closing .. ": options")
		lu.assertTrue(transcript[2].stop, t.closing .. " ends the conversation")
	end
end

-- AC-5, I-5: nothing is granted while more_training is displayed
function TestDingeMoreTraining:test_nothing_is_granted_while_more_training_is_displayed()
	costs()

	for _, list in ipairs(D.subsets()) do
		H.reset()
		costs()

		local player = pilot(list, 3 * COST)
		local transcript = T.converse(tr, player)

		lu.assertEquals(#transcript, 1, D.label(list) .. ": screens")
		lu.assertEquals(#free(), 0, D.label(list) .. ": awardSkill calls")
		lu.assertEquals(#bought(), 0, D.label(list) .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#held(player), #list, D.label(list) .. ": tier 1 skills held")
		lu.assertEquals(exp(player), 3 * COST, D.label(list) .. ": space_combat_general")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the purchase and the hand-off
---------------------------------------------------------------------------------------------

TestDingeTrainingPurchase = {}

function TestDingeTrainingPurchase:setUp() H.reset() end
function TestDingeTrainingPurchase:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- The skills held before the purchase of each x: the natural walk, except starships (a legacy pilot who holds weapons only, D-8)
local PRIOR = {
	starships = { "pilot_neutral_weapons_01" },
	weapons = { "pilot_neutral_starships_01" },
	procedures = { "pilot_neutral_starships_01", "pilot_neutral_weapons_01" },
	droid = { "pilot_neutral_starships_01", "pilot_neutral_weapons_01", "pilot_neutral_procedures_01" },
}

for k, t in ipairs(D.TRAINING) do
	local c = C.DINGE[k]

	-- AC-6: one XP-deducting grant, exactly 7500 XP, the closing line
	TestDingeTrainingPurchase["test_choosing_" .. c.sid .. "_on_more_training_buys_" .. t.skill .. "_once_for_7500_xp_and_ends_on_" .. t.closing] = function()
		costs()

		local player = pilot(PRIOR[t.x], 3 * COST)
		local transcript = T.converse(tr, player, { c.sid })

		lu.assertEquals(ids(transcript), { "more_training", t.closing }, "screens")
		lu.assertEquals(transcript[2].text, P .. "s_cd72f93", t.closing .. ": NPC line (Good choice.)")
		lu.assertTrue(transcript[2].stop, t.closing .. " ends the conversation")
		lu.assertEquals(transcript[2].options, {}, t.closing .. ": options")

		local calls = bought()

		lu.assertEquals(#calls, 1, "skillManagerAwardSkill calls")
		lu.assertTrue(calls[1][1] == player, "skillManagerAwardSkill player")
		lu.assertEquals(calls[1][2], t.skill, "skillManagerAwardSkill skill")
		lu.assertEquals(#free(), 0, "awardSkill (free grant) calls")
		lu.assertEquals(exp(player), 2 * COST, "space_combat_general after the purchase (3 x 7500 - 7500)")
		lu.assertEquals(#held(player), #PRIOR[t.x] + 1, "number of tier 1 skills held")
		lu.assertTrue(CreatureObject(player):hasSkill(t.skill), t.skill .. ": held")
	end

	-- AC-6, I-4: the reply of one skill buys that skill only, whatever else the pilot lacks
	TestDingeTrainingPurchase["test_choosing_the_reply_of_" .. t.x .. "_on_more_training_with_no_skill_buys_only_" .. t.x] = function()
		costs()

		local player = pilot({}, 10 * COST)

		K.drive(tr, player, "more_training", { c.sid })
		lu.assertEquals(#bought(), 1, "more_training: skillManagerAwardSkill calls")
		lu.assertEquals(bought()[1][2], t.skill, "more_training: skill")
		lu.assertEquals(#free(), 0, "more_training: awardSkill calls")
		lu.assertEquals(held(player), { t.skill }, "more_training: tier 1 skills held")
		lu.assertEquals(exp(player), 9 * COST, "more_training: space_combat_general")
	end

	-- AC-6: each conversation buys one skill; the skill just bought is not offered again, so a second conversation buys a different one
	TestDingeTrainingPurchase["test_choosing_the_reply_of_" .. t.x .. "_on_more_training_buys_one_skill_per_conversation_and_never_the_same_twice"] = function()
		costs()

		local player = pilot({}, 10 * COST)

		K.drive(tr, player, "more_training", { c.sid })
		lu.assertEquals(#bought(), 1, "skillManagerAwardSkill calls after the first conversation")
		lu.assertEquals(exp(player), 9 * COST, "space_combat_general (charged once)")

		local second = K.drive(tr, player, "more_training", { 0 })

		for _, o in ipairs(second[1].options) do
			lu.assertNotEquals(o.text, c.reply, "the reply of the skill just bought is offered again")
		end

		lu.assertEquals(#bought(), 2, "skillManagerAwardSkill calls after the second conversation")
		lu.assertNotEquals(bought()[2][2], t.skill, "the second conversation buys a different skill")
		lu.assertEquals(exp(player), 8 * COST, "space_combat_general (charged once per conversation)")
		lu.assertEquals(#held(player), 2, "tier 1 skills held")
	end

	-- AC-6: the pilot already owns the skill when the choice is made
	TestDingeTrainingPurchase["test_choosing_the_reply_of_" .. t.x .. "_for_a_skill_already_held_grants_nothing_and_restarts_the_conversation"] = function()
		costs()

		local list = PRIOR[t.x]
		local player = pilot(list, 3 * COST)
		local transcript = T.converse(tr, player, {
			function(p) p.skills[t.skill] = true end, -- the skill arrives while more_training is shown
			c.sid,
		})

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertEquals(exp(player), 3 * COST, "space_combat_general")
		lu.assertEquals(#transcript, 2, "screens")
		lu.assertNotEquals(transcript[2].id, t.closing, "no success line for a skill that was not bought")

		local want = {}

		for i, s in ipairs(list) do want[i] = s end
		want[#want + 1] = t.skill
		lu.assertEquals(transcript[2].id, freshFirstScreen(want, 3 * COST), "second screen is the fresh first screen of that pilot")
	end

	-- AC-6, D-3: the XP is gone at the moment of choosing
	TestDingeTrainingPurchase["test_choosing_the_reply_of_" .. t.x .. "_after_the_xp_is_gone_grants_nothing_and_restarts_the_conversation"] = function()
		costs()

		local player = pilot(PRIOR[t.x], COST)
		local transcript = T.converse(tr, player, {
			function(p) p.ghost.experience.space_combat_general = COST - 1 end,
			c.sid,
		})

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertFalse(CreatureObject(player):hasSkill(t.skill), t.skill .. " held")
		lu.assertEquals(exp(player), COST - 1, "space_combat_general")
		lu.assertEquals(#transcript, 2, "screens")
		lu.assertEquals(transcript[2].id, "duty_missions", "second screen: the start logic runs again for a pilot with less than 7500 XP")
	end

	-- AC-6, D-4, R-5: the engine would refuse
	TestDingeTrainingPurchase["test_choosing_the_reply_of_" .. t.x .. "_when_the_engine_refuses_grants_nothing_and_sends_no_skill_learned_message"] = function()
		costs()

		local player = pilot(PRIOR[t.x], 3 * COST)

		withEngineRefusal()

		local messages = #H.messageLog(player)
		local transcript = T.converse(tr, player, { c.sid })

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#transcript, 2, "screens")
		lu.assertNotEquals(transcript[2].id, t.closing, "no success line for a skill the engine refused")
		lu.assertEquals(transcript[2].id, "more_training", "second screen: the start logic runs again")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertEquals(#H.messageLog(player), messages, "system messages (no 'skill learned')")
		lu.assertEquals(exp(player), 3 * COST, "space_combat_general")
		lu.assertFalse(CreatureObject(player):hasSkill(t.skill), t.skill .. " held")
	end
end

-- AC-6, D-4: the guard is the handler's own: grantSpaceSkill is not even called when the skill is held, the XP is short or the engine refuses
-- (SpaceHelpers:grantSpaceSkill has a hasSkill check of its own, which must not be what makes these cases safe)
function TestDingeTrainingPurchase:test_the_guard_stops_the_call_to_grant_space_skill_in_the_three_refusal_cases_and_the_normal_case_makes_one_paid_call()
	costs()

	local cases = {
		{ "skill held", function(p) p.skills[D.SKILLS[2]] = true end, false },
		{ "xp gone", function(p) p.ghost.experience.space_combat_general = COST - 1 end, false },
		{ "engine refuses", function() withEngineRefusal() end, false },
		{ "nothing wrong", function() end, true },
	}

	for _, case in ipairs(cases) do
		H.reset()
		costs()
		LuaSkillManager = REAL_SKILL_MANAGER

		local player = pilot({ D.SKILLS[1] }, 3 * COST)
		local calls = H.spyOn(SpaceHelpers, "grantSpaceSkill")

		T.converse(tr, player, { case[2], C.DINGE[2].sid })

		if case[3] then
			lu.assertEquals(#calls, 1, case[1] .. ": grantSpaceSkill calls")
			lu.assertEquals({ calls[1].args[2], calls[1].args[3] }, { D.SKILLS[2], true }, case[1] .. ": grantSpaceSkill (skill, deductExperience)")
		else
			lu.assertEquals(#calls, 0, case[1] .. ": grantSpaceSkill calls")
		end
	end
end

-- AC-6, D-5: the first three paid purchases leave the tier alone
function TestDingeTrainingPurchase:test_the_first_three_purchases_leave_the_pilot_tier_at_1()
	costs()

	local player = pilot({}, 10 * COST)

	for i = 1, 3 do
		K.drive(tr, player, "more_training", { C.DINGE[i + 1].sid })
		lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier after paid skill " .. i)
	end

	lu.assertEquals(#held(player), 3, "tier 1 skills held")
end

-- AC-6, D-5
function TestDingeTrainingPurchase:test_the_fourth_skill_raises_the_pilot_tier_to_2_and_kaydine_then_talks_to_the_pilot()
	costs()

	local kaydine = T.TRAINERS.kaydine
	local player = pilot(firstSkills(3), COST)

	lu.assertEquals(player.ghost:getPilotTier(), 1, "setup: pilot tier")
	lu.assertEquals(T.converse(kaydine, player)[1].id, "not_ready_tier2", "setup: Kaydine turns a tier 1 pilot away")

	local transcript = T.converse(tr, player, { C.DINGE[4].sid })

	lu.assertEquals(ids(transcript), { "more_training", "trained_droid" }, "screens")
	lu.assertEquals(bought()[1][2], "pilot_neutral_droid_01", "skill bought")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after the fourth skill")
	lu.assertNotEquals(T.converse(kaydine, player)[1].id, "not_ready_tier2", "Kaydine's first screen")
end

-- AC-6, D-5: the tier is raised once; the next Dinge visit shows completed_tier1 and go_to_tier2 does not raise it again
function TestDingeTrainingPurchase:test_the_tier_is_raised_once_and_the_next_visit_shows_completed_tier1_then_go_to_tier2()
	costs()

	local player = pilot(firstSkills(3), COST)

	T.converse(tr, player, { 0, 0 })
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after the fourth skill")

	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "completed_tier1", "go_to_tier2" }, "screens of the next visit")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after go_to_tier2 (not raised twice)")
end

-- AC-6; F2 AC-8: a choice made by a pilot who is already past tier 1 leaves the tier alone
function TestDingeTrainingPurchase:test_a_choice_made_by_a_pilot_past_tier_1_does_not_raise_the_tier_again()
	costs()

	local player = pilot(firstSkills(3), 2 * COST)

	player.ghost.pilotTier = 2
	K.drive(tr, player, "more_training", { C.DINGE[4].sid })
	lu.assertEquals(#bought(), 1, "skillManagerAwardSkill calls")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

---------------------------------------------------------------------------------------------
-- AC-6 (conformance): the skill costs in SWG's skills.tab
---------------------------------------------------------------------------------------------

TestDingeTrainingSkillCost = {}

function TestDingeTrainingSkillCost:setUp() H.reset() end

local function skillRecords()
	local byName = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_01.tab").records) do
		byName[rec:get("NAME")] = rec
	end

	return byName
end

-- AC-6 (fixture sanity)
function TestDingeTrainingSkillCost:test_the_fixture_holds_the_novice_box_and_the_four_tier_1_neutral_pilot_skills()
	local byName = skillRecords()

	lu.assertNotNil(byName["pilot_neutral_novice"], "fixtures/skill/skills.pilot_neutral_01.tab: row pilot_neutral_novice")

	for _, skill in ipairs(D.SKILLS) do
		lu.assertNotNil(byName[skill], "fixtures/skill/skills.pilot_neutral_01.tab: row " .. skill)
	end
end

-- AC-6
function TestDingeTrainingSkillCost:test_every_tier_1_skill_costs_7500_space_combat_general_and_needs_the_novice_box()
	local byName = skillRecords()

	for _, skill in ipairs(D.SKILLS) do
		lu.assertEquals(byName[skill]:get("XP_TYPE"), "space_combat_general", skill .. ": XP_TYPE")
		lu.assertEquals(byName[skill]:num("XP_COST"), 7500, skill .. ": XP_COST")
		lu.assertEquals(byName[skill]:get("SKILLS_REQUIRED"), "pilot_neutral_novice", skill .. ": SKILLS_REQUIRED")
	end
end

-- AC-6: the novice box (the signup grant) costs no XP
function TestDingeTrainingSkillCost:test_the_novice_box_costs_no_xp()
	lu.assertEquals(skillRecords()["pilot_neutral_novice"]:num("XP_COST"), 0, "pilot_neutral_novice: XP_COST")
end

-- AC-6: the threshold Core3 checks before a purchase is exactly the XP_COST of the fixture
function TestDingeTrainingSkillCost:test_has_experience_for_training_1_switches_at_the_xp_cost_of_every_skill()
	local byName = skillRecords()

	for _, skill in ipairs(D.SKILLS) do
		local cost = byName[skill]:num("XP_COST")
		local below = H.newPlayer({ pilot = "neutral", experience = { space_combat_general = cost - 1 } })
		local exact = H.newPlayer({ pilot = "neutral", experience = { space_combat_general = cost } })

		lu.assertFalse(SpaceHelpers:hasExperienceForTraining(below, 1), skill .. ": hasExperienceForTraining(1) at XP_COST - 1")
		lu.assertTrue(SpaceHelpers:hasExperienceForTraining(exact, 1), skill .. ": hasExperienceForTraining(1) at XP_COST")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: one skill per visit
---------------------------------------------------------------------------------------------

TestDingeTrainingVisits = {}

function TestDingeTrainingVisits:setUp() H.reset() end
function TestDingeTrainingVisits:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- One visit: option 1 everywhere (one click now ends the conversation, so the further 0s are never used); returns the transcript and the engine calls it made
local function visit(player)
	local freeBefore, boughtBefore = #free(), #bought()
	local transcript = T.converse(tr, player, { 0, 0, 0 })

	return transcript, #free() - freeBefore, #bought() - boughtBefore
end

-- AC-7; F2 AC-9: picking the first reply each visit
function TestDingeTrainingVisits:test_with_22500_xp_five_visits_grant_starships_free_then_weapons_procedures_droid_paid_and_end_on_completed_tier1()
	costs()

	local player = pilot({}, 22500)

	lu.assertEquals(exp(player), 22500, "setup: space_combat_general")

	local transcript, nFree, nBought = visit(player)

	lu.assertEquals(ids(transcript), { "first_training", "trained_starships" }, "visit 1: screens")
	lu.assertEquals({ nFree, nBought }, { 1, 0 }, "visit 1: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(held(player), { "pilot_neutral_starships_01" }, "visit 1: skills held")
	lu.assertEquals(exp(player), 22500, "visit 1: space_combat_general (starships is free)")
	lu.assertEquals(free()[1][2], "pilot_neutral_starships_01", "visit 1: free skill")

	local expect = {
		{ "weapons", "pilot_neutral_weapons_01", 15000 },
		{ "procedures", "pilot_neutral_procedures_01", 7500 },
		{ "droid", "pilot_neutral_droid_01", 0 },
	}

	for i, e in ipairs(expect) do
		transcript, nFree, nBought = visit(player)

		lu.assertEquals(ids(transcript), { "more_training", "trained_" .. e[1] }, "visit " .. (i + 1) .. ": screens")
		lu.assertEquals({ nFree, nBought }, { 0, 1 }, "visit " .. (i + 1) .. ": awardSkill, skillManagerAwardSkill calls")
		lu.assertEquals(bought()[i][2], e[2], "visit " .. (i + 1) .. ": skill bought")
		lu.assertEquals(#held(player), i + 1, "visit " .. (i + 1) .. ": skills held")
		lu.assertEquals(exp(player), e[3], "visit " .. (i + 1) .. ": space_combat_general")
	end

	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after the fourth skill")

	transcript = visit(player)
	lu.assertEquals(transcript[1].id, "completed_tier1", "visit 5: first screen")
	lu.assertEquals(#free(), 1, "total awardSkill calls")
	lu.assertEquals(#bought(), 3, "total skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general at the end")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier at the end")
end

-- AC-7: 7500 XP buys one skill; the third visit shows the duty menu and grants nothing
function TestDingeTrainingVisits:test_with_only_7500_xp_the_third_visit_shows_duty_missions_and_grants_nothing()
	costs()

	local player = pilot({}, COST)
	local t1, f1, b1 = visit(player)
	local t2, f2, b2 = visit(player)

	lu.assertEquals(ids(t1), { "first_training", "trained_starships" }, "visit 1: screens")
	lu.assertEquals({ f1, b1 }, { 1, 0 }, "visit 1: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(ids(t2), { "more_training", "trained_weapons" }, "visit 2: screens")
	lu.assertEquals({ f2, b2 }, { 0, 1 }, "visit 2: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general after visit 2")

	local freeBefore, boughtBefore = #free(), #bought()
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "duty_missions", "visit 3: first screen")
	lu.assertEquals(#free() - freeBefore, 0, "visit 3: awardSkill calls")
	lu.assertEquals(#bought() - boughtBefore, 0, "visit 3: skillManagerAwardSkill calls")
	lu.assertEquals(#held(player), 2, "skills held")
end

-- AC-7: no conversation ever grants two skills, whichever choices the pilot makes
function TestDingeTrainingVisits:test_no_conversation_grants_two_skills_even_when_option_1_is_chosen_on_every_screen_ten_times()
	costs()

	local player = pilot({}, 10 * COST)

	for i = 1, 10 do
		local _, nFree, nBought = visit(player)

		lu.assertTrue(nFree + nBought <= 1, "visit " .. i .. ": grants " .. nFree + nBought)
	end

	lu.assertEquals(#held(player), 4, "skills held after ten visits")
	lu.assertEquals(exp(player), 10 * COST - 3 * COST, "space_combat_general (three paid skills)")
end
