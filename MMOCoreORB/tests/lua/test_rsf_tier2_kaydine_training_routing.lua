-- Captain Kaydine (RSF tier 2) SWG training: the first screen (routing with the skill-count gate of D-11), the helper functions, the greeting and
-- the purchase prompts, and the mission 3 reward link.
-- Spec: .claude/work/rsf-tier2-kaydine-training/01-spec.md (AC-3, AC-4, AC-9; Content contract 2; D-6, D-11).
--
-- Pilots come from the trainer-fixes builder (trainer_fixes_data.lua): T.player(tr, n, opts) is a pilot whose missions 1..n-1 are won and paid;
-- opts.baseSkills sets the tier 2 skills, opts.experience the space XP, opts.attempted = false leaves mission n unattempted.
-- Migration is done in every pilot here (the builder seeds the marker "3").

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_training_data")
local C = require("pilot_training_free_choice_data") -- pilot-training-free-choice: the choice replaces SWG's single reply s_187

T.load()

local tr = T.TRAINERS.kaydine
local E15 = "escort_naboo_privateer_15"
local R14 = "recovery_naboo_privateer_14"
local XP = 60000

local function skills(count)
	local out = {}

	for i = 1, count do
		out[i] = D.SKILLS[i]
	end

	return out
end

local function xp(n) return { space_combat_general = n } end

-- The pilot who is about to be offered mission n: missions 1..n-1 won and paid, mission n not attempted, `s` tier 2 skills (SWG order), `exp` space XP
local function pilot(n, s, exp, opts)
	opts = opts or {}

	return T.player(tr, n, { attempted = opts.attempted or false, baseSkills = opts.baseSkills or skills(s), experience = xp(exp), complete = opts.complete,
		skills = opts.skills, questStatus = opts.questStatus })
end

-- Mission 4 won and paid, s skills
local function veteran(s, exp)
	return T.player(tr, 4, { complete = { E15 }, baseSkills = skills(s), experience = xp(exp), questStatus = { ["naboo_privateer_15:reward"] = "1" } })
end

-- The handler with the helpers the spec names; a missing one is a clean failure
local function handler()
	local kh = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")

	for _, name in ipairs({ "getNextMission", "canTrain", "getLastScreenID", "getNextConversationScreen" }) do
		lu.assertEquals(type(kh[name]), "function", "kaydineConvoHandler:" .. name .. " must be defined (rsf-tier2-kaydine-training)")
	end

	lu.assertEquals(type(rawget(kh, "getNextConversationScreen")), "function", "kaydineConvoHandler must override getNextConversationScreen")
	return kh
end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function firstScreen(player, choices)
	local transcript = T.converse(tr, player, choices)

	lu.assertNotNil(transcript[1], "Kaydine shows a first screen")
	return transcript[1].id
end

---------------------------------------------------------------------------------------------
-- The helpers the spec names (Content contract 2)
---------------------------------------------------------------------------------------------

TestKaydineTrainingHelpers = {}

function TestKaydineTrainingHelpers:setUp() H.reset() end

-- AC-3 (getNextMission)
function TestKaydineTrainingHelpers:test_get_next_mission_is_the_first_mission_not_won_by_the_precedence_of_f4()
	local cases = {
		{ "nothing started", pilot(1, 0, 0), 1 },
		{ "1a alone complete is not the win of mission 1", T.player(tr, 1, { complete = { "assassinate_naboo_privateer_tier2_1a" } }), 1 },
		{ "1a and 1b complete without 1c", T.player(tr, 1, { complete = { "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b" } }), 1 },
		{ "1c complete wins mission 1", T.player(tr, 1, { complete = { "assassinate_naboo_privateer_tier2_1c" } }), 2 },
		{ "mission 1 won and paid", pilot(2, 1, 0), 2 },
		{ "mission 2 won", T.player(tr, 2, { complete = { "destroy_naboo_privateer_13" } }), 3 },
		{ "mission 3 won", T.player(tr, 3, { complete = { R14 } }), 4 },
		{ "mission 4 won", T.player(tr, 4, { complete = { E15 } }), 5 },
		{ "only mission 4 won (the highest win decides)", T.player(tr, 1, { complete = { E15 } }), 5 },
		{ "mission 3 won with mission 1 not won", T.player(tr, 1, { complete = { R14 } }), 4 },
	}

	for _, c in ipairs(cases) do
		lu.assertEquals(handler():getNextMission(c[2]), c[3], "getNextMission: " .. c[1])
	end
end

-- AC-3 (canTrain)
function TestKaydineTrainingHelpers:test_can_train_needs_xp_an_open_tier_and_fewer_skills_than_the_next_mission_number()
	local cases = {
		{ "no skill, enough XP", pilot(1, 0, XP), true },
		{ "no skill, XP one short", pilot(1, 0, XP - 1), false },
		{ "one skill, mission 1 next (s = N)", pilot(1, 1, XP), false },
		{ "s = N - 1 for N = 2", pilot(2, 1, XP), true },
		{ "s = N - 1 for N = 3", pilot(3, 2, XP), true },
		{ "s = N - 2 for N = 4", pilot(4, 2, XP), true },
		{ "s = N for N = 4 (mission 4 is offered)", pilot(4, 4, XP), false },
		{ "mission 4 won, three skills", veteran(3, XP), true },
		{ "mission 4 won, three skills, XP one short", veteran(3, XP - 1), false },
		{ "mission 4 won, tier 2 complete", veteran(4, 10 * XP), false },
	}

	for _, c in ipairs(cases) do
		lu.assertEquals(handler():canTrain(c[2]), c[3], "canTrain: " .. c[1])
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: the first screen
---------------------------------------------------------------------------------------------

TestKaydineTrainingRouting = {}

function TestKaydineTrainingRouting:setUp() H.reset() end

-- AC-3 (a)
function TestKaydineTrainingRouting:test_a_pilot_with_no_tier_2_skill_and_the_xp_is_sent_to_training()
	lu.assertEquals(firstScreen(pilot(1, 0, XP)), "ready_train_pilot", "first screen")
	lu.assertEquals(firstScreen(pilot(1, 0, 10 * XP)), "ready_train_pilot", "first screen with more XP")
end

-- AC-3 (b)
function TestKaydineTrainingRouting:test_a_pilot_with_no_tier_2_skill_and_too_little_xp_gets_the_duty_greeting()
	lu.assertEquals(firstScreen(pilot(1, 0, XP - 1)), "here_for_work", "first screen, XP one short")
	lu.assertEquals(firstScreen(pilot(1, 0, 0)), "here_for_work", "first screen, no XP")
end

for n = 1, 4 do
	-- AC-3 (c)
	TestKaydineTrainingRouting["test_a_pilot_one_skill_short_of_mission_" .. n .. "_and_the_xp_is_sent_to_training"] = function()
		lu.assertEquals(firstScreen(pilot(n, n - 1, XP)), "ready_train_pilot", "s = " .. (n - 1) .. ": first screen")
	end

	-- AC-3 (d)
	TestKaydineTrainingRouting["test_a_pilot_one_skill_short_of_mission_" .. n .. "_with_too_little_xp_gets_here_for_work_not_the_offer"] = function()
		lu.assertEquals(firstScreen(pilot(n, n - 1, XP - 1)), "here_for_work", "s = " .. (n - 1) .. ", low XP: first screen")
	end

	-- AC-3 (e)
	TestKaydineTrainingRouting["test_a_pilot_with_the_skills_for_mission_" .. n .. "_is_offered_it_whatever_the_xp"] = function()
		for _, s in ipairs({ n, 4 }) do
			for _, exp in ipairs({ 0, XP, 10 * XP }) do
				H.reset()
				lu.assertEquals(firstScreen(pilot(n, s, exp)), "mission" .. n .. "_ready", "s = " .. s .. ", XP " .. exp .. ": first screen")
			end
		end
	end
end

-- AC-3 (f), D-6, T1: the failure line comes before training, and it re-grants the mission (Revision 2: for mission 1 too, with s = 0)
for n = 1, 4 do
	TestKaydineTrainingRouting["test_mission_" .. n .. "_attempted_and_not_won_shows_the_failure_line_before_training_and_re_grants_it"] = function()
		local player = pilot(n, n - 1, 10 * XP, { attempted = true })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")

		lu.assertTrue(handler():canTrain(player), "setup: the pilot could train")
		lu.assertEquals(firstScreen(player), "mission" .. n .. "_failed", "first screen")
		lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
		lu.assertEquals(chains[1].args[3], D.HEADS[n], "re-granted chain")
	end
end

-- AC-3 (f'), Revision 2, K:111-114: no failure screen is skill-gated; mission 1 attempted and not won with no tier 2 skill and too little XP
function TestKaydineTrainingRouting:test_mission_1_attempted_and_not_won_with_no_skill_and_low_xp_shows_the_failure_line_and_re_grants_it()
	for _, exp in ipairs({ 0, XP - 1 }) do
		H.reset()

		local player = pilot(1, 0, exp, { attempted = true })
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")

		lu.assertEquals(firstScreen(player), "mission1_failed", "XP " .. exp .. ": first screen (not here_for_work)")
		lu.assertEquals(#chains, 1, "XP " .. exp .. ": startSpaceQuestChain calls")
		lu.assertEquals(chains[1].args[3], D.HEADS[1], "XP " .. exp .. ": re-granted chain")
	end
end

-- AC-3 (f) for mission 1 with a skill
function TestKaydineTrainingRouting:test_mission_1_attempted_and_not_won_with_a_skill_shows_the_failure_line_before_training()
	local player = pilot(1, 1, 10 * XP, { attempted = true })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")

	lu.assertEquals(firstScreen(player), "mission1_failed", "first screen")
	lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
	lu.assertEquals(chains[1].args[3], D.HEADS[1], "re-granted chain")
end

-- AC-3 (g)
function TestKaydineTrainingRouting:test_a_pilot_with_three_skills_who_won_and_was_paid_mission_4_is_sent_to_the_last_training()
	lu.assertEquals(firstScreen(veteran(3, XP)), "ready_train_pilot", "first screen")
end

-- AC-3 (h)
function TestKaydineTrainingRouting:test_a_pilot_with_three_skills_who_won_and_was_paid_mission_4_with_low_xp_gets_here_for_work()
	lu.assertEquals(firstScreen(veteran(3, XP - 1)), "here_for_work", "first screen")
end

-- AC-3 (g) legacy: a pilot who is behind on skills as well
function TestKaydineTrainingRouting:test_mission_4_paid_and_only_one_skill_is_still_sent_to_training_with_the_xp()
	lu.assertEquals(firstScreen(veteran(1, XP)), "ready_train_pilot", "first screen")
	lu.assertEquals(firstScreen(veteran(1, XP - 1)), "here_for_work", "first screen, low XP")
end

-- AC-3, D-11: a pilot behind on skills with too little XP gets the duty screen, however many missions they won
function TestKaydineTrainingRouting:test_a_pilot_two_skills_behind_with_too_little_xp_gets_the_duty_greeting()
	for n = 3, 4 do
		H.reset()
		lu.assertEquals(firstScreen(pilot(n, n - 2, XP - 1)), "here_for_work", "mission " .. n .. " next, s = " .. (n - 2) .. ", low XP: first screen")
		H.reset()
		lu.assertEquals(firstScreen(pilot(n, n - 2, XP)), "ready_train_pilot", "mission " .. n .. " next, s = " .. (n - 2) .. ", enough XP: first screen")
	end
end

-- AC-3, AC-10: the screens before the training block keep their order (C1-C6)
function TestKaydineTrainingRouting:test_an_active_mission_a_pending_reward_and_the_finished_tier_still_win_over_training()
	lu.assertEquals(firstScreen(T.player(tr, 2, { attempted = false, baseSkills = skills(1), experience = xp(10 * XP), active = { "destroy_naboo_privateer_13" } })), "on_mission", "active mission")
	lu.assertEquals(firstScreen(T.player(tr, 3, { complete = { R14 }, baseSkills = skills(2), experience = xp(10 * XP) })), "mission3_complete", "pending reward of mission 3")
	lu.assertEquals(firstScreen(veteran(4, 10 * XP)), "completed_kaydine", "all four skills, mission 4 paid")
end

---------------------------------------------------------------------------------------------
-- AC-4: the greeting and the purchase prompts
---------------------------------------------------------------------------------------------

TestKaydineTrainingGreeting = {}

function TestKaydineTrainingGreeting:setUp() H.reset() end

-- The pilot who lacks `x` and is about to buy it: SWG order, so the skills before it are held. Out of order sets are listed too.
local FIRST_MISSING = {
	{ "none held", {}, "train_starships" },
	{ "starships held", { 1 }, "train_weapons" },
	{ "starships and weapons held", { 1, 2 }, "train_procedures" },
	{ "starships, weapons and procedures held", { 1, 2, 3 }, "train_droid" },
	{ "only weapons held", { 2 }, "train_starships" },
	{ "starships and procedures held", { 1, 3 }, "train_weapons" },
	{ "starships, weapons and droid held", { 1, 2, 4 }, "train_procedures" },
	{ "only droid held", { 4 }, "train_starships" },
	{ "weapons, procedures and droid held", { 2, 3, 4 }, "train_starships" },
}

local function holding(indexes)
	local out = {}

	for _, i in ipairs(indexes) do
		out[#out + 1] = D.SKILLS[i]
	end

	return out
end

-- A pilot who holds `indexes`, has won as many missions as skills (so canTrain is true), and has the XP
local function trainee(indexes, exp)
	local s = #indexes

	return pilot(s + 1, s, exp or 10 * XP, { baseSkills = holding(indexes) })
end

-- AC-4; superseded by pilot-training-free-choice (AC-1): the greeting offers the choice of the missing skills instead of the single reply s_187
function TestKaydineTrainingGreeting:test_the_greeting_is_s_76e6f264_with_the_pilot_name_and_the_four_choice_replies()
	local player = trainee({})
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "ready_train_pilot", "first screen")
	lu.assertEquals(transcript[1].text, D.PREFIX .. "s_76e6f264", "greeting")
	lu.assertEquals(transcript[1].params.TU, player.name, "%TU is the pilot's first name")
	lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.KAYDINE, {}), "options (reply, link)")
end

for i, case in ipairs(FIRST_MISSING) do
	-- AC-4; superseded by pilot-training-free-choice (AC-1): the first reply is the first missing skill in SWG's order, and the held skills are not offered
	TestKaydineTrainingGreeting["test_the_greeting_offers_the_choice_of_the_missing_skills_starting_with_" .. case[3] .. "_when_" .. case[1]:gsub("[^%w]+", "_")] = function()
		local held = {}

		for _, i in ipairs(case[2]) do
			held[D.SKILLS[i]] = true
		end

		local transcript = T.converse(tr, trainee(case[2]))

		lu.assertEquals(transcript[1].id, "ready_train_pilot", case[1] .. ": first screen")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.KAYDINE, held), case[1] .. ": options (reply, link)")
		lu.assertEquals(transcript[1].options[1].link, case[3], case[1] .. ": link of the first reply (the first missing skill)")
	end
end

-- AC-4: choosing the first reply shows the prompt of the first missing skill, with its line and its one option, and nothing is granted
function TestKaydineTrainingGreeting:test_each_purchase_prompt_shows_its_line_and_one_option_and_grants_nothing()
	local byScreen = {}

	for _, t in ipairs(D.TRAINING) do
		byScreen[t.screen] = t
	end

	for _, case in ipairs(FIRST_MISSING) do
		H.reset()

		local player = trainee(case[2])
		local rec = T.spyAllQuests()
		local before = player.ghost.experience.space_combat_general
		local transcript = T.converse(tr, player, { 0 })
		local t = byScreen[case[3]]

		lu.assertEquals(ids(transcript), { "ready_train_pilot", case[3] }, case[1] .. ": screens")
		lu.assertEquals(transcript[2].text, D.PREFIX .. t.promptSid, case[1] .. ": " .. case[3] .. " line")
		lu.assertEquals(#transcript[2].options, 1, case[1] .. ": " .. case[3] .. " number of options")
		lu.assertEquals(transcript[2].options[1].text, D.PREFIX .. t.optionSid, case[1] .. ": " .. case[3] .. " option text")
		lu.assertEquals(#rec.skills, 0, case[1] .. ": grantSpaceSkill calls while the prompt is shown")
		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, case[1] .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, case[1] .. ": awardSkill calls")
		lu.assertEquals(player.ghost.experience.space_combat_general, before, case[1] .. ": XP")
		lu.assertEquals(rec.starts, {}, case[1] .. ": startQuest calls")
	end
end

-- AC-4: the greeting and the prompts start and pay nothing and set no mission key
function TestKaydineTrainingGreeting:test_showing_the_greeting_writes_no_mission_key()
	local player = trainee({ 1, 2 })
	local before = {}

	for n = 1, 4 do
		before[n] = { H.getQuestStatus(player, D.KEYS[n] .. ":attempted"), H.getQuestStatus(player, D.KEYS[n] .. ":reward") }
	end

	T.converse(tr, player, { 0 })

	for n = 1, 4 do
		lu.assertEquals({ H.getQuestStatus(player, D.KEYS[n] .. ":attempted"), H.getQuestStatus(player, D.KEYS[n] .. ":reward") }, before[n], D.KEYS[n] .. ": :attempted / :reward")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: the mission 3 reward leads to the new greeting
---------------------------------------------------------------------------------------------

TestKaydineTrainingMission3Reward = {}

function TestKaydineTrainingMission3Reward:setUp() H.reset() end

local function optionPairs(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { o.text, o.link }
	end

	return out
end

local function m3pilot(s, exp)
	return T.player(tr, 3, { complete = { R14 }, baseSkills = skills(s), experience = xp(exp) })
end

-- AC-9; the greeting's single option is replaced by the choice (pilot-training-free-choice AC-1)
function TestKaydineTrainingMission3Reward:test_a_pilot_who_can_train_is_offered_s_45d20070_to_the_greeting_and_arrives_on_it()
	local transcript = T.converse(tr, m3pilot(3, XP), { 0, "s_45d20070" })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "ready_train_pilot" }, "screens")
	lu.assertEquals(optionPairs(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_45d20070", "ready_train_pilot" } }, "mission3_reward options")
	lu.assertEquals(transcript[3].text, D.PREFIX .. "s_76e6f264", "greeting")
	lu.assertEquals(C.pairsOf(transcript[3]), C.expected(C.KAYDINE, { [D.SKILLS[1]] = true, [D.SKILLS[2]] = true, [D.SKILLS[3]] = true }), "greeting: options (starships, weapons, procedures held: the droid reply only)")
end

-- AC-9, D-8, D-11: a pilot who is behind on skills can train too
function TestKaydineTrainingMission3Reward:test_a_pilot_two_skills_short_is_offered_the_training_after_mission_3()
	local transcript = T.converse(tr, m3pilot(1, XP), { 0 })

	lu.assertEquals(optionPairs(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_45d20070", "ready_train_pilot" } }, "mission3_reward options")
end

-- AC-9: not enough XP
function TestKaydineTrainingMission3Reward:test_a_pilot_without_the_xp_is_offered_the_duty_line_instead()
	local transcript = T.converse(tr, m3pilot(3, XP - 1), { 0 })

	lu.assertEquals(optionPairs(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_6114e8b7", "mission3_reward_duty" } }, "mission3_reward options")
end

-- AC-9: nothing left to train
function TestKaydineTrainingMission3Reward:test_a_pilot_with_all_four_skills_is_offered_the_duty_line_instead()
	local transcript = T.converse(tr, m3pilot(4, 10 * XP), { 0 })

	lu.assertEquals(optionPairs(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_6114e8b7", "mission3_reward_duty" } }, "mission3_reward options")
end
