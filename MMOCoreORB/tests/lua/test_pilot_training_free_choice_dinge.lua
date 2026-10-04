-- Dinge (RSF tier 1): the pilot chooses which missing tier 1 skill to train, including the free first skill (pre-NGE free choice).
-- Spec: .claude/work/pilot-training-free-choice/01-spec.md (AC-4 .. AC-7; Content contract 2; invariants I-2 .. I-5; D-2, D-6, D-9),
-- re-pinned to the pre-NGE one-click training by .claude/work/space-convo-client-strings-dinge/01-spec.md (D-4, D-5, D-6, D-9; AC-7 .. AC-9):
-- the choice is made on first_training (free) or more_training (paid) and the conversation ends on the "Good choice." screen trained_<x>.
-- The lesson step (s_139/s_140) and the train_<x> prompt-and-confirm screens (s_144 .. s_147) are gone; every grant guard is unchanged.
--
-- The choice replies are the answer key of pilot_training_free_choice_data.lua (copied from the spec). The SWG lines of the prompts and closing
-- lines come from rsf_tier1_dinge_training_data.lua. The fake charges XP only with H.Engine.config.skillXpCosts set (see costs()).
-- H.Engine.callsTo("awardSkill") is the free grant, callsTo("skillManagerAwardSkill") the XP-deducting one.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier1_dinge_training_data")
local K = require("rsf_tier2_kaydine_training_data") -- K.drive: start a conversation on a given screen
local C = require("pilot_training_free_choice_data")

T.load()

local tr = T.TRAINERS.dinge
local P = D.PREFIX
local COST = 7500
local WIN = { 1, 2, 3, 4 }
local REAL_SKILL_MANAGER = LuaSkillManager
local CHOICES = C.DINGE

local function costs()
	local out = {}

	for _, skill in ipairs(D.SKILLS) do
		out[skill] = COST
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

local function row(x)
	for _, c in ipairs(CHOICES) do
		if c.x == x then
			return c
		end
	end
end

local function templateScreen(id)
	for _, s in ipairs(H.conversationTemplateTable("dinge_convo_template").screens) do
		if s.id == id then
			return s
		end
	end
end

local function freshFirstScreen(skills, amount)
	return T.converse(tr, pilot(skills, amount))[1].id
end

local function withEngineRefusal()
	LuaSkillManager = function()
		local real = REAL_SKILL_MANAGER()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = real })
	end
end

-- The 14 subsets of 1 to 3 tier 1 skills as lists of skill names, in SWG order
local function subsets()
	return D.subsets()
end

---------------------------------------------------------------------------------------------
-- AC-4: more_training offers a choice
---------------------------------------------------------------------------------------------

TestDingeFreeChoiceMoreTraining = {}

function TestDingeFreeChoiceMoreTraining:setUp() H.reset() end
function TestDingeFreeChoiceMoreTraining:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-4: the template carries no static option, so no fixed-order remnant is left
function TestDingeFreeChoiceMoreTraining:test_the_static_more_training_screen_has_no_options_and_keeps_its_line_and_animation()
	local screen = templateScreen("more_training")

	lu.assertNotNil(screen, "dinge_convo_template: screen more_training")
	lu.assertEquals(screen.options, {}, "more_training: static options")
	lu.assertEquals(screen.leftDialog, P .. "s_122b0165", "more_training: leftDialog")
	lu.assertEquals(screen.stopConversation, "false", "more_training: stopConversation")
	lu.assertEquals(screen.animation, "explain", "more_training: animation")
end

-- AC-4, I-2: each of the 14 subsets
for _, list in ipairs(subsets()) do
	TestDingeFreeChoiceMoreTraining["test_more_training_for_a_pilot_holding_" .. D.label(list) .. "_offers_the_choice_replies_of_the_missing_skills_in_order"] = function()
		costs()

		local player = pilot(list, 3 * COST)
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(transcript[1].text, P .. "s_122b0165", "more_training: NPC line")
		lu.assertEquals(transcript[1].params.TU, "Ace", "more_training: %TU")
		lu.assertFalse(transcript[1].stop, "more_training does not end the conversation")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, C.set(list), "closing"), "more_training: options (reply, link)")
		lu.assertEquals(#transcript[1].options, 4 - #list, "more_training: number of options")
		lu.assertEquals(#free(), 0, "awardSkill calls on display")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls on display")
		lu.assertEquals(#held(player), #list, "tier 1 skills held")
		lu.assertEquals(exp(player), 3 * COST, "space_combat_general")
	end
end

-- AC-4: the retired single reply is gone
function TestDingeFreeChoiceMoreTraining:test_the_retired_single_reply_s_143_is_never_offered()
	for _, list in ipairs(subsets()) do
		for _, o in ipairs(T.converse(tr, pilot(list, COST))[1].options) do
			lu.assertNotEquals(o.text, P .. "s_143", D.label(list) .. ": the fixed-order reply")
		end
	end
end

-- AC-8 (F2 D-9): every reply ends on the "Good choice." line of its skill right away (no prompt-and-confirm step)
function TestDingeFreeChoiceMoreTraining:test_every_reply_ends_the_conversation_on_good_choice_of_its_skill_without_a_prompt()
	for _, c in ipairs(CHOICES) do
		H.reset()
		costs()

		-- a pilot holding one other skill, so more_training is the first screen
		local other = c.x == "starships" and "pilot_neutral_weapons_01" or "pilot_neutral_starships_01"
		local transcript = T.converse(tr, pilot({ other }, COST), { c.sid })

		lu.assertEquals(ids(transcript), { "more_training", c.closing }, c.x .. ": screens")
		lu.assertEquals(transcript[2].text, P .. "s_cd72f93", c.x .. ": Good choice. line")
		lu.assertEquals(transcript[2].options, {}, c.x .. ": options")
		lu.assertTrue(transcript[2].stop, c.x .. ": the conversation ends")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: the paid purchase, any skill
---------------------------------------------------------------------------------------------

TestDingeFreeChoicePurchase = {}

function TestDingeFreeChoicePurchase:setUp() H.reset() end
function TestDingeFreeChoicePurchase:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- Every set of 1 to 3 skills other than x
local function othersOf(x)
	local out = {}

	for mask = 1, 15 do
		local list = {}

		for i, c in ipairs(CHOICES) do
			if c.x ~= x and mask & (1 << (i - 1)) ~= 0 then
				list[#list + 1] = c.skill
			end
		end

		-- the mask bit of x itself is never set above; keep each set once
		local seen = false

		for _, o in ipairs(out) do
			if table.concat(o, ",") == table.concat(list, ",") then
				seen = true
			end
		end

		if #list >= 1 and not seen then
			out[#out + 1] = list
		end
	end

	return out
end

for _, c in ipairs(CHOICES) do
	-- AC-5, I-3, I-4: whichever other skills are held, the pick buys that skill once for 7500 XP and ends on its closing line
	TestDingeFreeChoicePurchase["test_picking_" .. c.x .. "_buys_pilot_neutral_" .. c.x .. "_01_once_for_7500_xp_and_ends_on_" .. c.closing .. "_whatever_else_is_held"] = function()
		for _, list in ipairs(othersOf(c.x)) do
			H.reset()
			costs()

			local player = pilot(list, 3 * COST)
			local transcript = T.converse(tr, player, { c.sid })

			lu.assertEquals(ids(transcript), { "more_training", c.closing }, D.label(list) .. " held: screens")
			lu.assertEquals(transcript[2].text, P .. "s_cd72f93", D.label(list) .. " held: " .. c.closing .. " line")
			lu.assertTrue(transcript[2].stop, D.label(list) .. " held: " .. c.closing .. " ends the conversation")
			lu.assertEquals(transcript[2].options, {}, D.label(list) .. " held: " .. c.closing .. " options")

			local calls = bought()

			lu.assertEquals(#calls, 1, D.label(list) .. " held: skillManagerAwardSkill calls")
			lu.assertTrue(calls[1][1] == player, D.label(list) .. " held: skillManagerAwardSkill player")
			lu.assertEquals(calls[1][2], c.skill, D.label(list) .. " held: skill bought")
			lu.assertEquals(#free(), 0, D.label(list) .. " held: awardSkill (free grant) calls")
			lu.assertEquals(exp(player), 2 * COST, D.label(list) .. " held: space_combat_general after the purchase")
			lu.assertEquals(#held(player), #list + 1, D.label(list) .. " held: number of tier 1 skills held")
			lu.assertTrue(CreatureObject(player):hasSkill(c.skill), D.label(list) .. " held: " .. c.skill .. " held")
		end
	end
end

-- AC-5: the example of the spec (droid held, procedures picked)
function TestDingeFreeChoicePurchase:test_a_pilot_holding_droid_who_picks_procedures_gets_procedures_and_pays_once()
	costs()

	local player = pilot({ "pilot_neutral_droid_01" }, COST)
	local transcript = T.converse(tr, player, { C.DINGE[3].sid })

	lu.assertEquals(ids(transcript), { "more_training", "trained_procedures" }, "screens")
	lu.assertEquals(#bought(), 1, "skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general")
end

-- AC-5, guards: the skill arrives while the prompt is shown / the XP is gone / the engine refuses; for a pick that is not the first missing skill
for _, c in ipairs(CHOICES) do
	local other = c.x == "starships" and "pilot_neutral_weapons_01" or "pilot_neutral_starships_01"

	-- AC-5
	TestDingeFreeChoicePurchase["test_picking_" .. c.x .. "_for_a_skill_that_arrived_meanwhile_grants_nothing_and_shows_the_fresh_first_screen"] = function()
		costs()

		local player = pilot({ other }, 3 * COST)
		local transcript = T.converse(tr, player, { function(p) p.skills[c.skill] = true end, c.sid }) -- the skill arrives while more_training is shown

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertEquals(exp(player), 3 * COST, "space_combat_general")
		lu.assertEquals(#transcript, 2, "screens")
		lu.assertNotEquals(transcript[2].id, c.closing, "no success line for a skill that was not bought")
		lu.assertEquals(transcript[2].id, freshFirstScreen({ other, c.skill }, 3 * COST), "second screen is the fresh first screen of that pilot")
	end

	-- AC-5
	TestDingeFreeChoicePurchase["test_picking_" .. c.x .. "_after_the_xp_is_gone_grants_nothing_and_shows_the_fresh_first_screen"] = function()
		costs()

		local player = pilot({ other }, COST)
		local transcript = T.converse(tr, player, { function(p) p.ghost.experience.space_combat_general = COST - 1 end, c.sid }) -- the XP is gone while more_training is shown

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertFalse(CreatureObject(player):hasSkill(c.skill), c.skill .. " held")
		lu.assertEquals(exp(player), COST - 1, "space_combat_general")
		lu.assertEquals(transcript[2].id, "duty_missions", "second screen: the start logic runs again for a pilot with less than 7500 XP")
	end

	-- AC-5
	TestDingeFreeChoicePurchase["test_picking_" .. c.x .. "_when_the_engine_refuses_grants_nothing_and_sends_no_skill_learned_message"] = function()
		costs()

		local player = pilot({ other }, 3 * COST)

		withEngineRefusal()

		local messages = #H.messageLog(player)
		local transcript = T.converse(tr, player, { c.sid })

		lu.assertEquals(transcript[1].id, "more_training", "first screen")
		lu.assertEquals(#transcript, 2, "screens")
		lu.assertNotEquals(transcript[#transcript].id, c.closing, "no success line for a skill the engine refused")
		lu.assertEquals(transcript[2].id, freshFirstScreen({ other }, 3 * COST), "second screen is the fresh first screen of that pilot")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertEquals(#H.messageLog(player), messages, "system messages (no 'skill learned')")
		lu.assertEquals(exp(player), 3 * COST, "space_combat_general")
		lu.assertFalse(CreatureObject(player):hasSkill(c.skill), c.skill .. " held")
	end
end

-- AC-5, I-4: the guard is the handler's own: the paid grant is one call with deductExperience true, whichever skill is picked
function TestDingeFreeChoicePurchase:test_the_paid_pick_makes_exactly_one_grant_space_skill_call_with_deduct_true()
	for _, c in ipairs(CHOICES) do
		H.reset()
		costs()

		local other = c.x == "starships" and "pilot_neutral_weapons_01" or "pilot_neutral_starships_01"
		local calls = H.spyOn(SpaceHelpers, "grantSpaceSkill")

		T.converse(tr, pilot({ other }, 3 * COST), { c.sid })
		lu.assertEquals(#calls, 1, c.x .. ": grantSpaceSkill calls")
		lu.assertEquals({ calls[1].args[2], calls[1].args[3] }, { c.skill, true }, c.x .. ": grantSpaceSkill (skill, deductExperience)")
	end
end

-- AC-5: the first three paid skills leave the pilot tier at 1, the fourth raises it to 2, whichever order they come in
function TestDingeFreeChoicePurchase:test_the_fourth_skill_raises_the_pilot_tier_to_2_whichever_skill_it_is()
	for _, last in ipairs(CHOICES) do
		H.reset()
		costs()

		local others = {}

		for _, c in ipairs(CHOICES) do
			if c.x ~= last.x then
				others[#others + 1] = c.skill
			end
		end

		local player = pilot(others, COST)

		lu.assertEquals(player.ghost:getPilotTier(), 1, last.x .. ": setup, pilot tier")

		local transcript = T.converse(tr, player, { last.sid })

		lu.assertEquals(ids(transcript), { "more_training", last.closing }, last.x .. ": screens")
		lu.assertEquals(player.ghost:getPilotTier(), 2, last.x .. ": pilot tier after the fourth skill")
		lu.assertEquals(T.converse(tr, player)[1].id, "completed_tier1", last.x .. ": the next first screen")
	end
end

-- AC-5: the first three purchases in a reversed order leave the tier alone
function TestDingeFreeChoicePurchase:test_three_paid_skills_picked_last_first_leave_the_pilot_tier_at_1()
	costs()

	local player = pilot({ "pilot_neutral_starships_01" }, 10 * COST)

	for i, x in ipairs({ "droid", "procedures", "weapons" }) do
		local c = row(x)

		T.converse(tr, player, { c.sid, 0 })
		lu.assertEquals(#bought(), i, x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(player.ghost:getPilotTier(), i == 3 and 2 or 1, "pilot tier after paid skill " .. i)
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the free first skill is the pilot's choice
---------------------------------------------------------------------------------------------

TestDingeFreeChoiceFirstTraining = {}

function TestDingeFreeChoiceFirstTraining:setUp() H.reset() end
function TestDingeFreeChoiceFirstTraining:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- AC-7 (F2 D-4): first_training has no static option (the handler adds the choices); the lesson and first_training_done screens are gone
function TestDingeFreeChoiceFirstTraining:test_first_training_has_no_static_option_and_the_lesson_and_first_training_done_do_not_exist()
	local screen = templateScreen("first_training")

	lu.assertNotNil(screen, "dinge_convo_template: screen first_training")
	lu.assertEquals(screen.options, {}, "first_training: static options")
	lu.assertEquals(screen.leftDialog, P .. "s_5e36283d", "first_training: leftDialog")
	lu.assertEquals(screen.stopConversation, "false", "first_training: stopConversation")
	lu.assertEquals(screen.animation, "explain", "first_training: animation")
	lu.assertNil(templateScreen("first_training_lesson"), "dinge_convo_template: screen first_training_lesson must be deleted")
	lu.assertNil(templateScreen("first_training_done"), "dinge_convo_template: screen first_training_done must be deleted")

	for _, s in ipairs(H.conversationTemplateTable("dinge_convo_template").screens) do
		for _, sid in ipairs({ "s_139", "s_140", "s_142" }) do
			lu.assertNotEquals(s.leftDialog, P .. sid, "screen " .. tostring(s.id) .. " must not show " .. sid)
		end
	end
end

-- AC-7: first_training lists the four choice replies, all four on every reachable path
for _, amount in ipairs({ 0, COST, 3 * COST }) do
	TestDingeFreeChoiceFirstTraining["test_first_training_offers_the_four_choice_replies_linking_to_the_closing_lines_with_" .. amount .. "_xp"] = function()
		costs()

		local player = pilot({}, amount)
		local transcript = T.converse(tr, player)

		lu.assertEquals(ids(transcript), { "first_training" }, "screens")
		lu.assertEquals(transcript[1].text, P .. "s_5e36283d", "first_training: NPC line")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(CHOICES, {}, "closing"), "first_training: options (reply, link)")
		lu.assertEquals(#transcript[1].options, 4, "first_training: number of options")
		lu.assertFalse(transcript[1].stop, "first_training does not end the conversation")

		-- I-4: nothing is granted while the screen is displayed
		lu.assertEquals(#free(), 0, "awardSkill calls")
		lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
		lu.assertEquals(held(player), {}, "tier 1 skills held")
		lu.assertEquals(exp(player), amount, "space_combat_general")
	end
end

-- AC-6: the retired replies are never offered on the lesson (kept as it was: first_training now leads straight to the closing line, so there is no lesson)
function TestDingeFreeChoiceFirstTraining:test_the_retired_reply_s_141_is_not_offered_on_the_lesson()
	local transcript = T.converse(tr, pilot({}, 0), { 0 })

	for _, o in ipairs(transcript[2].options) do
		lu.assertNotEquals(o.text, P .. "s_141", "the single fixed-order reply")
	end
end

-- AC-7: the retired replies are never offered on first_training (the old single reply s_139 and the lesson reply s_141)
function TestDingeFreeChoiceFirstTraining:test_the_retired_replies_s_139_and_s_141_are_not_offered_on_first_training()
	for _, o in ipairs(T.converse(tr, pilot({}, 0))[1].options) do
		lu.assertNotEquals(o.text, P .. "s_139", "the NGE lesson reply")
		lu.assertNotEquals(o.text, P .. "s_141", "the single fixed-order reply")
	end
end

-- AC-7: choosing reply k on first_training grants the k-th skill once, for free, and ends on its closing line
for _, amount in ipairs({ 0, COST, 3 * COST }) do
	for _, c in ipairs(CHOICES) do
		TestDingeFreeChoiceFirstTraining["test_choosing_" .. c.x .. "_grants_" .. c.skill .. "_once_for_free_with_" .. amount .. "_xp_and_ends_on_" .. c.closing] = function()
			costs()

			local player = pilot({}, amount)
			local transcript = T.converse(tr, player, { c.sid })

			lu.assertEquals(ids(transcript), { "first_training", c.closing }, "screens")
			lu.assertEquals(transcript[2].text, P .. "s_cd72f93", c.closing .. ": NPC line (Good choice.)")
			lu.assertTrue(transcript[2].stop, c.closing .. " ends the conversation")
			lu.assertEquals(transcript[2].options, {}, c.closing .. ": options")

			local calls = free()

			lu.assertEquals(#calls, 1, "awardSkill calls")
			lu.assertTrue(calls[1][1] == player, "awardSkill player")
			lu.assertEquals(calls[1][2], c.skill, "awardSkill skill")
			lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
			lu.assertEquals(held(player), { c.skill }, "tier 1 skills held (only the picked skill)")
			lu.assertEquals(exp(player), amount, "space_combat_general is unchanged")
			lu.assertEquals(player.ghost:getPilotTier(), 1, "pilot tier stays 1")
		end
	end
end

-- AC-7 (the spec's example): no skill, droid picked
function TestDingeFreeChoiceFirstTraining:test_the_fourth_reply_grants_droid_for_free_and_ends_on_trained_droid()
	local player = pilot({}, 0)
	local transcript = T.converse(tr, player, { 3 })

	lu.assertEquals(ids(transcript), { "first_training", "trained_droid" }, "screens")
	lu.assertEquals(#free(), 1, "awardSkill calls")
	lu.assertEquals(free()[1][2], "pilot_neutral_droid_01", "awardSkill skill")
end

-- AC-7, I-4: the grant is announced once and names the picked skill
function TestDingeFreeChoiceFirstTraining:test_the_free_grant_sends_one_skill_learned_message_naming_the_picked_skill()
	for _, c in ipairs(CHOICES) do
		H.reset()

		local player = pilot({}, 0)
		local before = #H.messageLog(player)

		T.converse(tr, player, { c.sid })

		local log = H.messageLog(player)

		lu.assertEquals(#free(), 1, c.x .. ": awardSkill calls")
		lu.assertEquals(#log - before, 1, c.x .. ": system messages")
		lu.assertEquals(log[#log].TO, "@skl_n:" .. c.skill, c.x .. ": skill named in the message")
	end
end

-- AC-7, I-4: exactly one free grantSpaceSkill call for the picked skill, with deductExperience false
function TestDingeFreeChoiceFirstTraining:test_the_pick_calls_grant_space_skill_once_with_deduct_false_for_the_picked_skill()
	for _, c in ipairs(CHOICES) do
		H.reset()

		local calls = H.spyOn(SpaceHelpers, "grantSpaceSkill")

		T.converse(tr, pilot({}, COST), { c.sid })
		lu.assertEquals(#calls, 1, c.x .. ": grantSpaceSkill calls")
		lu.assertEquals({ calls[1].args[2], calls[1].args[3] }, { c.skill, false }, c.x .. ": grantSpaceSkill (skill, deductExperience)")
	end
end

-- AC-7: a pilot who holds any tier 1 skill when choosing gets nothing and sees the fresh first screen
for _, c in ipairs(CHOICES) do
	for _, heldSkill in ipairs(D.SKILLS) do
		for _, amount in ipairs({ 0, COST }) do
			TestDingeFreeChoiceFirstTraining["test_choosing_" .. c.x .. "_while_holding_" .. heldSkill:match("_(%a+)_01$") .. "_with_" .. amount .. "_xp_grants_nothing_and_restarts_the_conversation"] = function()
				costs()

				local player = pilot({}, amount)
				local calls = H.spyOn(SpaceHelpers, "grantSpaceSkill")
				local transcript = T.converse(tr, player, {
					function(p) p.skills[heldSkill] = true end, -- the skill arrives while first_training is shown
					c.sid,
				})

				lu.assertEquals(transcript[1].id, "first_training", "first screen")
				lu.assertEquals(#free(), 0, "awardSkill calls")
				lu.assertEquals(#bought(), 0, "skillManagerAwardSkill calls")
				lu.assertEquals(#calls, 0, "grantSpaceSkill calls")
				lu.assertEquals(held(player), { heldSkill }, "tier 1 skills held")
				lu.assertEquals(exp(player), amount, "space_combat_general")
				lu.assertEquals(#transcript, 2, "screens")
				lu.assertEquals(transcript[2].id, freshFirstScreen({ heldSkill }, amount), "second screen is the fresh first screen of that pilot")
				lu.assertNotEquals(transcript[2].id, c.closing, "no success line for a skill that was not granted")
			end
		end
	end
end

-- AC-7: choosing on first_training again after the grant grants nothing more
function TestDingeFreeChoiceFirstTraining:test_choosing_on_first_training_again_after_the_grant_grants_one_skill_in_all()
	for _, c in ipairs(CHOICES) do
		H.reset()
		costs()

		local player = pilot({}, COST)

		T.converse(tr, player, { c.sid })
		lu.assertEquals(#free(), 1, c.x .. ": awardSkill calls after the first conversation")

		-- first_training now offers the three skills still missing; every one of them is chosen in turn
		for i = 1, 3 do
			K.drive(tr, player, "first_training", { i - 1 })
		end

		lu.assertEquals(#free(), 1, c.x .. ": awardSkill calls after choosing on first_training again")
		lu.assertEquals(#bought(), 0, c.x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(held(player), { c.skill }, c.x .. ": tier 1 skills held")
		lu.assertEquals(exp(player), COST, c.x .. ": space_combat_general")
	end
end

-- AC-7, I-4: a pilot who already holds a later skill (legacy) gets nothing free from first_training
function TestDingeFreeChoiceFirstTraining:test_first_training_gives_a_pilot_who_already_holds_droid_nothing_free_whatever_is_picked()
	for i, c in ipairs(CHOICES) do
		H.reset()
		costs()

		local player = pilot({ D.SKILLS[4] }, COST)

		-- first_training offers the three skills the pilot lacks; picking the one at position i (or the last) must grant nothing
		K.drive(tr, player, "first_training", { math.min(i - 1, 2) })
		lu.assertEquals(#free(), 0, c.x .. ": awardSkill calls")
		lu.assertEquals(#bought(), 0, c.x .. ": skillManagerAwardSkill calls")
		lu.assertEquals(held(player), { D.SKILLS[4] }, c.x .. ": tier 1 skills held")
	end
end

-- AC-7, AC-8, I-4: nothing but a reply on first_training grants for free (the same reply on more_training is the paid path)
function TestDingeFreeChoiceFirstTraining:test_the_free_path_is_used_for_nothing_else()
	for i, c in ipairs(CHOICES) do
		H.reset()
		costs()

		K.drive(tr, pilot({}, 4 * COST), "more_training", { i - 1 })
		lu.assertEquals(#free(), 0, c.x .. " on more_training: awardSkill calls")
		lu.assertEquals(#bought(), 1, c.x .. " on more_training: skillManagerAwardSkill calls")
		lu.assertEquals(bought()[1][2], c.skill, c.x .. " on more_training: skill bought")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: an out-of-order career
---------------------------------------------------------------------------------------------

TestDingeFreeChoiceCareer = {}

function TestDingeFreeChoiceCareer:setUp() H.reset() end
function TestDingeFreeChoiceCareer:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

-- One visit that picks the last reply offered on the choice screen. Returns the transcript and the numbers of free and paid grants it made.
local function lastReplyVisit(player)
	local look = T.converse(tr, player)
	local choiceStep = look[1]

	lu.assertTrue(choiceStep.id == "first_training" or choiceStep.id == "more_training", "the visit reaches a choice screen, got " .. choiceStep.id)

	local reply = choiceStep.options[#choiceStep.options].text
	local freeBefore, boughtBefore = #free(), #bought()
	local transcript = T.converse(tr, player, { reply })

	return transcript, #free() - freeBefore, #bought() - boughtBefore, reply
end

-- AC-9
function TestDingeFreeChoiceCareer:test_picking_the_last_reply_everywhere_gets_droid_free_then_procedures_weapons_starships_paid_and_ends_with_no_xp_and_tier_2()
	costs()

	local player = pilot({}, 4 * COST - COST) -- 22500: one free skill and three paid ones

	lu.assertEquals(exp(player), 22500, "setup: space_combat_general")

	local transcript, nFree, nBought, reply = lastReplyVisit(player)

	lu.assertEquals(ids(transcript), { "first_training", "trained_droid" }, "visit 1: screens")
	lu.assertEquals(reply, C.DINGE[4].reply, "visit 1: the last reply offered")
	lu.assertEquals({ nFree, nBought }, { 1, 0 }, "visit 1: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(free()[1][2], "pilot_neutral_droid_01", "visit 1: free skill")
	lu.assertEquals(held(player), { "pilot_neutral_droid_01" }, "visit 1: skills held")
	lu.assertEquals(exp(player), 22500, "visit 1: space_combat_general (the first skill is free)")

	local expect = {
		{ "procedures", 15000 },
		{ "weapons", 7500 },
		{ "starships", 0 },
	}

	for i, e in ipairs(expect) do
		transcript, nFree, nBought, reply = lastReplyVisit(player)

		lu.assertEquals(ids(transcript), { "more_training", "trained_" .. e[1] }, "visit " .. (i + 1) .. ": screens")
		lu.assertEquals(reply, row(e[1]).reply, "visit " .. (i + 1) .. ": the last reply offered")
		lu.assertEquals({ nFree, nBought }, { 0, 1 }, "visit " .. (i + 1) .. ": awardSkill, skillManagerAwardSkill calls")
		lu.assertEquals(bought()[i][2], "pilot_neutral_" .. e[1] .. "_01", "visit " .. (i + 1) .. ": skill bought")
		lu.assertEquals(#held(player), i + 1, "visit " .. (i + 1) .. ": skills held")
		lu.assertEquals(exp(player), e[2], "visit " .. (i + 1) .. ": space_combat_general")
	end

	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after the fourth skill")
	lu.assertEquals(T.converse(tr, player)[1].id, "completed_tier1", "visit 5: first screen")
	lu.assertEquals(#free(), 1, "total awardSkill calls")
	lu.assertEquals(#bought(), 3, "total skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general at the end")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier at the end")
end

-- AC-9: no visit ever grants two skills, whatever is picked
function TestDingeFreeChoiceCareer:test_no_visit_grants_two_skills_whichever_reply_is_picked_each_time()
	for _, pickIndex in ipairs({ 0, 1, 2, 3 }) do
		H.reset()
		costs()

		local player = pilot({}, 10 * COST)

		for visit = 1, 6 do
			local look = T.converse(tr, player)
			local step = look[1]
			local n = #(step.options or {})
			local before = #free() + #bought()

			if step.id == "first_training" or step.id == "more_training" then
				T.converse(tr, player, { step.options[math.min(pickIndex, n - 1) + 1].text })
			else
				T.converse(tr, player, { 0 })
			end

			lu.assertTrue(#free() + #bought() - before <= 1, "pick " .. pickIndex .. ", visit " .. visit .. ": grants " .. (#free() + #bought() - before))
		end

		lu.assertEquals(#held(player), 4, "pick " .. pickIndex .. ": skills held after six visits")
		lu.assertEquals(#free(), 1, "pick " .. pickIndex .. ": free grants")
		lu.assertEquals(#bought(), 3, "pick " .. pickIndex .. ": paid grants")
		lu.assertEquals(exp(player), 10 * COST - 3 * COST, "pick " .. pickIndex .. ": space_combat_general (three paid skills)")
	end
end

-- AC-9: with 7500 XP only the free skill (the pick) is granted, the second visit buys one, the third shows the duty menu
function TestDingeFreeChoiceCareer:test_with_7500_xp_a_free_pick_then_one_paid_pick_then_the_duty_menu()
	costs()

	local player = pilot({}, COST)
	local t1, f1, b1 = lastReplyVisit(player)
	local t2, f2, b2 = lastReplyVisit(player)

	lu.assertEquals(ids(t1), { "first_training", "trained_droid" }, "visit 1: screens")
	lu.assertEquals({ f1, b1 }, { 1, 0 }, "visit 1: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(ids(t2), { "more_training", "trained_procedures" }, "visit 2: screens")
	lu.assertEquals({ f2, b2 }, { 0, 1 }, "visit 2: awardSkill, skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general after visit 2")
	lu.assertEquals(T.converse(tr, player)[1].id, "duty_missions", "visit 3: first screen")
	lu.assertEquals(#held(player), 2, "skills held")
end
