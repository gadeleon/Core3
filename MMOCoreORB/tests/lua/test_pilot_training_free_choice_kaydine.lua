-- Captain Kaydine (RSF tier 2): the pilot chooses which missing tier 2 skill to train (pre-NGE free choice).
-- Spec: .claude/work/pilot-training-free-choice/01-spec.md (AC-1, AC-2, AC-3; Content contract 1; invariants I-2 .. I-5; D-2, D-3, D-5).
--
-- The choice replies are the answer key of pilot_training_free_choice_data.lua (copied from the spec). The purchase prompts, the 16 intro
-- walks and the career scenario come from rsf_tier2_kaydine_training_data.lua. Choices are made by reply sid, so an out-of-order pick does not
-- depend on the order of the list.
--
-- space-convo-client-strings-kaydine (.claude/work/space-convo-client-strings-kaydine/01-spec.md, D-1, Appendix A): the training is one click. The choice on
-- ready_train_pilot buys the skill and shows the intro trained_<x>_mission<N> straight away (no train_<x> prompt, no buy reply); hooks that change the pilot
-- between the greeting and the purchase now come before the choice.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local K = require("rsf_tier2_kaydine_training_data")
local C = require("pilot_training_free_choice_data")

T.load()

local tr = T.TRAINERS.kaydine
local XP = 60000
local REAL_SKILL_MANAGER = LuaSkillManager
local CHOICES = C.KAYDINE

local function costs()
	local out = {}

	for _, skill in ipairs(K.SKILLS) do
		out[skill] = XP
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

local function grants() return H.Engine.callsTo("skillManagerAwardSkill") end

-- The pilot about to be offered mission n (missions 1..n-1 won and paid, n not attempted) who holds `held` and has `amount` space XP
local function pilot(n, held, amount)
	return T.player(tr, n, { attempted = false, baseSkills = held, experience = { space_combat_general = amount } })
end

-- A trainee holding `held`: one mission won per skill held, so canTrain is true
local function trainee(held, amount)
	return pilot(#held + 1, held, amount or 10 * XP)
end

local function spyStarts()
	local log = {}

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function() log[#log + 1] = name end)
	end

	return log
end

---------------------------------------------------------------------------------------------
-- AC-1: the greeting offers one reply per missing skill
---------------------------------------------------------------------------------------------

TestKaydineFreeChoiceGreeting = {}

function TestKaydineFreeChoiceGreeting:setUp() H.reset() end
function TestKaydineFreeChoiceGreeting:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-1: the template carries no static option, so no fixed-order remnant is left
function TestKaydineFreeChoiceGreeting:test_the_static_ready_train_pilot_screen_has_no_options_and_keeps_its_line_and_animation()
	local screen

	for _, s in ipairs(H.conversationTemplateTable("kaydine_convo_template").screens) do
		if s.id == "ready_train_pilot" then
			screen = s
		end
	end

	lu.assertNotNil(screen, "kaydine_convo_template: screen ready_train_pilot")
	lu.assertEquals(screen.options, {}, "ready_train_pilot: static options")
	lu.assertEquals(screen.leftDialog, K.PREFIX .. "s_76e6f264", "ready_train_pilot: leftDialog")
	lu.assertEquals(screen.stopConversation, "false", "ready_train_pilot: stopConversation")
	lu.assertEquals(screen.animation, "salute1", "ready_train_pilot: animation")
end

-- AC-1, I-2: every proper subset of held skills
for _, held in ipairs(C.properSubsets(CHOICES)) do
	TestKaydineFreeChoiceGreeting["test_the_greeting_offers_exactly_the_choice_replies_of_the_missing_skills_in_order_when_holding_" .. C.label(held):gsub("[^%w]+", "_")] = function()
		local player = trainee(held)
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, "ready_train_pilot", C.label(held) .. ": first screen")
		lu.assertEquals(transcript[1].text, K.PREFIX .. "s_76e6f264", C.label(held) .. ": greeting")
		lu.assertEquals(transcript[1].params.TU, player.name, C.label(held) .. ": %TU is the pilot's first name")
		lu.assertFalse(transcript[1].stop, C.label(held) .. ": the greeting does not end the conversation")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, C.set(held)), C.label(held) .. ": options (reply, link)")
		lu.assertEquals(#transcript[1].options, 4 - #held, C.label(held) .. ": number of options")
		lu.assertEquals(#grants(), 0, C.label(held) .. ": skillManagerAwardSkill calls while the greeting is shown")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, C.label(held) .. ": awardSkill calls")
	end
end

-- AC-1, I-5: showing the choice grants, pays, starts and writes nothing
function TestKaydineFreeChoiceGreeting:test_showing_the_greeting_grants_pays_starts_and_writes_nothing()
	for _, held in ipairs(C.properSubsets(CHOICES)) do
		H.reset()
		costs()

		local player = trainee(held)
		local rec = T.spyAllQuests()
		local before = exp(player)
		local keys = {}

		for n = 1, 4 do
			keys[n] = { H.getQuestStatus(player, K.KEYS[n] .. ":attempted"), H.getQuestStatus(player, K.KEYS[n] .. ":reward") }
		end

		T.converse(tr, player)

		lu.assertEquals(#rec.skills, 0, C.label(held) .. ": grantSpaceSkill calls")
		lu.assertEquals(rec.starts, {}, C.label(held) .. ": startQuest calls")
		lu.assertEquals(rec.rewards, {}, C.label(held) .. ": rewardPlayer calls")
		lu.assertEquals(exp(player), before, C.label(held) .. ": XP")

		for n = 1, 4 do
			lu.assertEquals({ H.getQuestStatus(player, K.KEYS[n] .. ":attempted"), H.getQuestStatus(player, K.KEYS[n] .. ":reward") }, keys[n], K.KEYS[n] .. ": :attempted / :reward")
		end
	end
end

-- AC-1: no reply is ever offered for a held skill, and the retired single reply is gone
function TestKaydineFreeChoiceGreeting:test_the_retired_single_reply_s_187_is_never_offered_and_a_held_skill_is_never_offered()
	for _, held in ipairs(C.properSubsets(CHOICES)) do
		local transcript = T.converse(tr, trainee(held))
		local heldSet = C.set(held)

		for _, o in ipairs(transcript[1].options) do
			lu.assertNotEquals(o.text, K.PREFIX .. "s_187", C.label(held) .. ": the fixed-order reply")

			for _, row in ipairs(CHOICES) do
				if o.text == row.reply then
					lu.assertFalse(heldSet[row.skill] == true, C.label(held) .. ": reply offered for the held skill " .. row.skill)
				end
			end
		end
	end
end

-- AC-1, space-convo-client-strings-kaydine D-1: the reply buys its skill once and leads straight to the mission 1 intro of that skill (there is no prompt screen)
function TestKaydineFreeChoiceGreeting:test_every_reply_buys_its_skill_once_and_leads_to_the_mission_1_intro_of_the_skill()
	for _, row in ipairs(CHOICES) do
		H.reset()
		costs()

		local player = trainee({})
		local transcript = T.converse(tr, player, { row.sid })

		lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_" .. row.x .. "_mission1" }, row.x .. ": screens")
		lu.assertEquals(#grants(), 1, row.x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(grants()[1][2], row.skill, row.x .. ": skill bought")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, row.x .. ": awardSkill calls")
		lu.assertEquals(exp(player), 9 * XP, row.x .. ": XP after the purchase")
	end
end

-- AC-1: mission3_reward's s_45d20070 arrives on the greeting with the same choice
function TestKaydineFreeChoiceGreeting:test_a_pilot_who_can_train_arrives_from_mission_3_reward_on_the_greeting_with_the_choice_of_the_missing_skills()
	for _, held in ipairs({ { K.SKILLS[1], K.SKILLS[2], K.SKILLS[3] }, { K.SKILLS[4] }, {} }) do
		H.reset()

		local player = T.player(tr, 3, { complete = { "recovery_naboo_privateer_14" }, baseSkills = held, experience = { space_combat_general = XP } })
		local transcript = T.converse(tr, player, { 0, "s_45d20070" })

		lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "ready_train_pilot" }, C.label(held) .. ": screens")
		lu.assertEquals(transcript[3].text, K.PREFIX .. "s_76e6f264", C.label(held) .. ": greeting")
		lu.assertEquals(C.pairsOf(transcript[3]), C.expected(CHOICES, C.set(held)), C.label(held) .. ": options on the greeting reached from mission3_reward")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: any-order purchase
---------------------------------------------------------------------------------------------

TestKaydineFreeChoicePurchase = {}

function TestKaydineFreeChoicePurchase:setUp() H.reset() end
function TestKaydineFreeChoicePurchase:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- The n - 1 skills other than x the pilot holds: the latest ones in SWG order, so a skill that precedes x is missing wherever possible
local function heldFor(x, n)
	local out = {}

	for i = #CHOICES, 1, -1 do
		if CHOICES[i].x ~= x and #out < n - 1 then
			out[#out + 1] = CHOICES[i].skill
		end
	end

	return out
end

for _, row in ipairs(K.INTRO) do
	local choice
	local x, n = row.x, row.n

	for _, c in ipairs(CHOICES) do
		if c.x == x then
			choice = c
		end
	end

	-- AC-2
	TestKaydineFreeChoicePurchase["test_choosing_" .. x .. "_with_" .. (n - 1) .. "_other_skills_buys_it_once_shows_" .. row.id .. "_and_grants_mission_" .. n] = function()
		costs()

		local held = heldFor(x, n)
		local player = pilot(n, held, 3 * XP)
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local choices = { choice.sid }

		for _ = 1, #row.walk - 1 do
			choices[#choices + 1] = 0
		end

		local transcript = T.converse(tr, player, choices)
		local expected = { "ready_train_pilot" }

		for _, id in ipairs(row.walk) do
			expected[#expected + 1] = id
		end

		lu.assertEquals(ids(transcript), expected, row.id .. " (holding " .. C.label(held) .. "): screens")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, C.set(held)), row.id .. ": the greeting's choice")

		local calls = grants()

		lu.assertEquals(#calls, 1, row.id .. ": skillManagerAwardSkill calls")
		lu.assertTrue(calls[1][1] == player, row.id .. ": skillManagerAwardSkill player")
		lu.assertEquals(calls[1][2], choice.skill, row.id .. ": skill bought")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, row.id .. ": awardSkill (free grant) calls")
		lu.assertEquals(exp(player), 2 * XP, row.id .. ": space_combat_general after one purchase")
		lu.assertEquals(SpaceHelpers:getPilotTierSkillCount(player, "neutral", 2), n, row.id .. ": tier 2 skills held")
		lu.assertEquals(#chains, 1, row.id .. ": startSpaceQuestChain calls")
		lu.assertEquals(chains[1].args[3], K.HEADS[n], row.id .. ": mission granted")
		lu.assertEquals(H.getQuestStatus(player, K.KEYS[n] .. ":attempted"), "1", row.id .. ": :attempted")
	end
end

-- AC-2: the droid-first example of the spec (one click: no prompt screen)
function TestKaydineFreeChoicePurchase:test_a_pilot_with_no_skill_who_picks_droid_gets_the_droid_mission_1_intro()
	costs()

	local player = pilot(1, {}, XP)
	local transcript = T.converse(tr, player, { C.KAYDINE[4].sid })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "trained_droid_mission1" }, "screens")
	lu.assertEquals(grants()[1][2], "pilot_neutral_droid_02", "skill bought")
	lu.assertEquals(exp(player), 0, "space_combat_general")
end

-- AC-2, I-3: the result depends on the skill picked and the skill count, not on which other skills are held
function TestKaydineFreeChoicePurchase:test_the_intro_depends_on_the_picked_skill_and_the_mission_not_on_the_other_skills_held()
	for _, row in ipairs(CHOICES) do
		for n = 1, 4 do
			local seen = {}

			-- every set of n - 1 other skills
			for mask = 0, 15 do
				local held = {}

				for i, c in ipairs(CHOICES) do
					if c.x ~= row.x and mask & (1 << (i - 1)) ~= 0 then
						held[#held + 1] = c.skill
					end
				end

				if #held == n - 1 then
					H.reset()
					costs()

					local transcript = T.converse(tr, pilot(n, held, 3 * XP), { row.sid })

					seen[#seen + 1] = transcript[#transcript].id
					lu.assertEquals(transcript[#transcript].id, "trained_" .. row.x .. "_mission" .. n, row.x .. " as skill " .. n .. " holding " .. C.label(held))
					lu.assertEquals(#grants(), 1, row.x .. " holding " .. C.label(held) .. ": skillManagerAwardSkill calls")
				end
			end

			lu.assertTrue(#seen >= 1, row.x .. " mission " .. n .. ": at least one held set was tried")
		end
	end
end

-- AC-2: the guard cases of the purchase hold for an out-of-order pick (skill held, XP gone, engine refuses)
function TestKaydineFreeChoicePurchase:test_the_guards_hold_for_a_droid_first_pick()
	costs()

	local droid = C.KAYDINE[4]

	-- the skill arrives while the greeting is shown
	local player = pilot(1, {}, 3 * XP)

	T.converse(tr, player, { function(p) p.skills[droid.skill] = true end, droid.sid })
	lu.assertEquals(#grants(), 0, "skill already held: skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 3 * XP, "skill already held: XP")

	-- the XP is gone at the moment of buying
	H.reset()
	costs()
	player = pilot(1, {}, XP)

	local transcript = T.converse(tr, player, { function(p) p.ghost.experience.space_combat_general = XP - 1 end, droid.sid })

	lu.assertEquals(#grants(), 0, "XP gone: skillManagerAwardSkill calls")
	lu.assertFalse(CreatureObject(player):hasSkill(droid.skill), "XP gone: droid held")
	lu.assertEquals(transcript[#transcript].id, "here_for_work", "XP gone: the fresh first screen")

	-- the engine refuses
	H.reset()
	costs()
	player = pilot(1, {}, 3 * XP)
	LuaSkillManager = function()
		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = REAL_SKILL_MANAGER() })
	end
	transcript = T.converse(tr, player, { droid.sid })
	lu.assertEquals(#grants(), 0, "engine refuses: skillManagerAwardSkill calls")
	lu.assertFalse(CreatureObject(player):hasSkill(droid.skill), "engine refuses: droid held")
	lu.assertNotEquals(transcript[#transcript].id, "trained_droid_mission1", "engine refuses: no intro for a skill that was not bought")
end

-- AC-2, I-4: a prompt buys only its own skill whatever else is missing; repeating the prompt buys nothing more
function TestKaydineFreeChoicePurchase:test_each_pick_buys_only_the_picked_skill_and_repeating_it_buys_nothing_more()
	for _, row in ipairs(CHOICES) do
		H.reset()
		costs()

		local player = trainee({})

		T.converse(tr, player, { row.sid, 0 })
		lu.assertEquals(#grants(), 1, row.x .. ": skillManagerAwardSkill calls after the first conversation")
		lu.assertEquals(exp(player), 9 * XP, row.x .. ": XP after one purchase")

		for _, other in ipairs(CHOICES) do
			lu.assertEquals(CreatureObject(player):hasSkill(other.skill), other.x == row.x, row.x .. ": " .. other.skill .. " held")
		end

		K.drive(tr, player, row.screen, { 0 })
		lu.assertEquals(#grants(), 1, row.x .. ": skillManagerAwardSkill calls after choosing on the prompt again")
		lu.assertEquals(exp(player), 9 * XP, row.x .. ": XP charged once")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: an out-of-order career
---------------------------------------------------------------------------------------------

TestKaydineFreeChoiceCareer = {}

function TestKaydineFreeChoiceCareer:setUp() H.reset() end
function TestKaydineFreeChoiceCareer:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

local function winAll(player, n)
	for _, g in ipairs(K.WON[n]) do
		T.setState(player, g, "complete")
	end
end

-- AC-3
function TestKaydineFreeChoiceCareer:test_picking_the_last_reply_every_visit_trains_droid_procedures_weapons_starships_one_skill_per_visit()
	costs()

	local player = T.player(tr, 1, { attempted = false, baseSkills = {}, experience = { space_combat_general = 4 * XP } })
	local starts = spyStarts()
	local order = { 4, 3, 2, 1 } -- droid, procedures, weapons, starships

	for k, idx in ipairs(order) do
		local pick = CHOICES[idx]
		local row
		local before = #grants()
		local startsBefore = #starts

		for _, r in ipairs(K.INTRO) do
			if r.x == pick.x and r.n == k then
				row = r
			end
		end

		-- the reply picked is the last one the greeting offers
		local greeting = T.converse(tr, player)

		lu.assertEquals(greeting[1].id, "ready_train_pilot", "visit " .. k .. ": first screen")
		lu.assertEquals(greeting[1].options[#greeting[1].options].text, pick.reply, "visit " .. k .. ": the last reply offered")
		lu.assertEquals(#greeting[1].options, 5 - k, "visit " .. k .. ": number of replies offered")

		local choices = { pick.sid }

		for _ = 1, #row.walk - 1 do
			choices[#choices + 1] = 0
		end

		local transcript = T.converse(tr, player, choices)

		lu.assertEquals(transcript[2].id, "trained_" .. pick.x .. "_mission" .. k, "visit " .. k .. ": intro")
		lu.assertEquals(transcript[#transcript].id, row.grant, "visit " .. k .. ": last screen (the grant)")
		lu.assertEquals(#grants() - before, 1, "visit " .. k .. ": skills bought")
		lu.assertEquals(grants()[#grants()][2], pick.skill, "visit " .. k .. ": skill bought")
		lu.assertEquals(#starts - startsBefore, 1, "visit " .. k .. ": missions started")
		lu.assertEquals(starts[#starts], K.HEADS[k], "visit " .. k .. ": mission started")
		lu.assertEquals(exp(player), (4 - k) * XP, "visit " .. k .. ": space_combat_general")

		-- the pilot flies and wins the mission and is paid
		for _, g in ipairs(K.WON[k]) do
			T.setState(player, g, "active")
		end

		lu.assertEquals(T.converse(tr, player)[1].id, "on_mission", "visit " .. k .. ": first screen while the mission runs")
		winAll(player, k)

		local reward = T.converse(tr, player, k == 2 and {} or { 0 })

		lu.assertEquals(reward[1].id, ({ "mission1_complete", "mission2_reward", "mission3_complete", "mission4_complete" })[k], "visit " .. k .. ": first screen after the win")
		lu.assertEquals(H.getQuestStatus(player, K.KEYS[k] .. ":reward"), "1", "visit " .. k .. ": :reward")
		lu.assertEquals(#grants() - before, 1, "visit " .. k .. ": skills bought including the reward conversation")
	end

	lu.assertEquals(T.converse(tr, player)[1].id, "completed_kaydine", "first screen after mission 4 is paid")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")

	for _, skill in ipairs(K.SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " held")
	end

	lu.assertEquals(#grants(), 4, "total skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "total awardSkill calls")
end

-- AC-3: the tier is raised only by the fourth skill, whichever it is
function TestKaydineFreeChoiceCareer:test_the_pilot_tier_rises_to_3_only_with_the_fourth_skill_whichever_skill_it_is()
	for _, last in ipairs(CHOICES) do
		H.reset()
		costs()

		local held = {}

		for _, c in ipairs(CHOICES) do
			if c.x ~= last.x then
				held[#held + 1] = c.skill
			end
		end

		local player = T.player(tr, 4, { complete = { "escort_naboo_privateer_15" }, baseSkills = held, experience = { space_combat_general = XP }, questStatus = { ["naboo_privateer_15:reward"] = "1" } })

		lu.assertEquals(player.ghost:getPilotTier(), 2, last.x .. ": setup, pilot tier")
		T.converse(tr, player, { last.sid, 0 })
		lu.assertEquals(#grants(), 1, last.x .. ": skills bought")
		lu.assertEquals(player.ghost:getPilotTier(), 3, last.x .. ": pilot tier after the fourth skill")
		lu.assertEquals(T.converse(tr, player)[1].id, "completed_kaydine", last.x .. ": the next first screen")
	end
end

-- AC-3, D-3: the skill-count gate is unchanged: a pilot with fewer skills than missions can still train, one with enough is offered the mission
function TestKaydineFreeChoiceCareer:test_the_skill_count_gate_still_decides_between_the_mission_offer_and_the_choice()
	-- s = N: the mission is offered, not the choice
	for n = 1, 4 do
		H.reset()

		local held = {}

		for i = 1, n do
			held[i] = CHOICES[5 - i].skill -- droid first
		end

		lu.assertEquals(T.converse(tr, pilot(n, held, 10 * XP))[1].id, "mission" .. n .. "_ready", "s = N = " .. n .. ": first screen")
	end

	-- s = N - 1: the choice
	for n = 1, 4 do
		H.reset()

		local held = {}

		for i = 1, n - 1 do
			held[i] = CHOICES[5 - i].skill
		end

		local transcript = T.converse(tr, pilot(n, held, 10 * XP))

		lu.assertEquals(transcript[1].id, "ready_train_pilot", "s = N - 1, N = " .. n .. ": first screen")
		lu.assertEquals(#transcript[1].options, 4 - (n - 1), "s = N - 1, N = " .. n .. ": number of replies")
	end

	-- too little XP: the duty greeting, no choice
	H.reset()
	lu.assertEquals(T.converse(tr, pilot(2, { CHOICES[4].skill }, XP - 1))[1].id, "here_for_work", "XP one short: first screen")
end
