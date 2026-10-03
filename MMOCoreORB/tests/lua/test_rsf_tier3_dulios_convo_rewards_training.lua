-- Dulios (RSF tier 3): the reward screens pay once and offer one free choice per missing tier 3 skill (D-4, E-1), the training screens
-- grant the chosen skill for free and raise the tier on the fourth, and the D-5 fallthrough (4f complete, skills missing) shows the
-- mission 4 reward screen instead of the dead-end "wrong turn" line.
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (AC-6, AC-7, AC-8, invariants I-4, I-6, Conversation flow C7, C10, D-3, D-4, D-5).
-- Answer key: rsf_tier3_dulios_convo_data.lua (TRAIN_CHOICES, REWARD_SCREENS, heads). Players are built with trainer_fixes_data.lua T.player.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier3_dulios_convo_data")

T.load()

local tr = T.TRAINERS.dulios
local P = D.PREFIX

local XP = "space_combat_general"

-- A pilot who won mission n (its whole chain complete) and holds `held` tier 3 skills (default: n - 1 of them, the builder's own)
local function rewardPilot(n, opts)
	opts = opts or {}
	opts.complete = opts.complete or tr.chains[n]

	if opts.attempted == nil then
		opts.attempted = false
	end

	return T.player(tr, n, opts)
end

local function handler() return H.expectGlobal("duliosConvoHandler", "Dulios conversation handler") end

-- What getInitialScreen alone returns (the engine calls runScreenHandlers on it afterwards; this does not)
local function initialScreenId(player)
	local pScreen = handler():getInitialScreen(player, H.newNpc({}), H.conversationTemplate(tr.template))

	lu.assertNotNil(pScreen, "getInitialScreen returned no screen")
	return LuaConversationScreen(pScreen):getScreenID()
end

local function rewarded(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":reward") end

local function sidOfOption(o) return (o.text or ""):match(":(s_[%w_]+)$") end

-- The option list the choice screen must show for a pilot holding `held` (a set skill -> true): { {sid, link}, ... } in TRAIN_CHOICES order.
-- `plain` forces the non-_final links.
local function expectedOptions(held, plain)
	local missing = {}

	for _, entry in ipairs(D.TRAIN_CHOICES) do
		if not held[entry[1]] then
			missing[#missing + 1] = entry
		end
	end

	local out = {}

	for i, entry in ipairs(missing) do
		out[i] = { entry[2], entry[3] .. ((#missing == 1 and not plain) and "_final" or "") }
	end

	return out
end

local function optionsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { sidOfOption(o), o.link }
	end

	return out
end

local function heldSet(player)
	local held = {}

	for _, entry in ipairs(D.TRAIN_CHOICES) do
		if player:hasSkill(entry[1]) then
			held[entry[1]] = true
		end
	end

	return held
end

local function setOf(list)
	local set = {}

	for _, v in ipairs(list) do set[v] = true end

	return set
end

local function skillCount(held)
	local n = 0

	for _ in pairs(held) do n = n + 1 end

	return n
end

---------------------------------------------------------------------------------------------
-- AC-6: the reward screens
---------------------------------------------------------------------------------------------

TestDuliosRewardScreens = {}

function TestDuliosRewardScreens:setUp() H.reset() end

for n = 1, 4 do
	local id, head = D.COMPLETE[n], D.HEADS[n]

	-- AC-6, I-4: getInitialScreen alone returns the reward screen and pays nothing
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_get_initial_screen_returns_" .. id .. "_and_pays_nothing"] = function()
		local player = rewardPilot(n)
		local rec = T.spyAllQuests()
		local before = H.getQuestStatus(player, D.KEYS[n] .. ":reward")

		lu.assertEquals(initialScreenId(player), id, "mission " .. n .. ": getInitialScreen")
		lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls from getInitialScreen")
		lu.assertEquals(rec.starts, {}, "mission " .. n .. ": startQuest calls from getInitialScreen")
		lu.assertEquals(#rec.skills, 0, "mission " .. n .. ": grantSpaceSkill calls from getInitialScreen")
		lu.assertEquals(rewarded(player, n), before, "mission " .. n .. ": :reward written by getInitialScreen")
	end

	-- AC-6: the first screen of the conversation pays the head once and sets :reward
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_the_first_screen_" .. id .. "_pays_the_head_once_and_sets_the_reward_key"] = function()
		local player = rewardPilot(n)
		local rec = T.spyRewards()
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")

		lu.assertNil(rewarded(player, n), "precondition: :reward unset")

		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, id, "mission " .. n .. ": first screen")
		lu.assertFalse(transcript[1].stop, "mission " .. n .. ": the reward screen offers the choices")
		lu.assertEquals(rec.rewards, { head }, "mission " .. n .. ": rewardPlayer calls (the mission head)")
		lu.assertEquals(rewarded(player, n), "1", "mission " .. n .. ": :reward")

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(rewarded(player, other), other < n and "1" or nil, "mission " .. n .. ": :reward of mission " .. other)
			end
		end
	end

	-- AC-6, E-1: one choice option per missing skill, in TRAIN_CHOICES order
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_the_reward_screen_offers_one_choice_per_missing_tier_3_skill_in_order"] = function()
		local player = rewardPilot(n)
		local held = heldSet(player)
		local transcript = T.converse(tr, player)

		lu.assertEquals(skillCount(held), n - 1, "precondition: tier 3 skills held")
		lu.assertEquals(transcript[1].id, id, "mission " .. n .. ": first screen")
		lu.assertEquals(optionsOf(transcript[1]), expectedOptions(held), "mission " .. n .. ": options (choice sid, training screen)")
		lu.assertEquals(#transcript[1].options, 4 - (n - 1), "mission " .. n .. ": number of choices")
	end

	-- AC-6: a second visit before training shows the reward screen again and pays nothing
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_a_second_visit_before_training_shows_" .. id .. "_again_and_pays_nothing"] = function()
		local player = rewardPilot(n)
		local rec = T.spyRewards()

		T.converse(tr, player)

		local second = T.converse(tr, player)

		lu.assertEquals(second[1].id, id, "mission " .. n .. ": second visit")
		lu.assertEquals(rec.rewards, { head }, "mission " .. n .. ": rewardPlayer calls over two visits")
		lu.assertEquals(optionsOf(second[1]), expectedOptions(heldSet(player)), "mission " .. n .. ": options of the second visit")
	end

	-- AC-6: :reward already "1": nothing is paid
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_with_the_reward_key_already_set_pays_nothing"] = function()
		local player = rewardPilot(n, { questStatus = { [D.KEYS[n] .. ":reward"] = "1" } })
		local rec = T.spyRewards()
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, id, "mission " .. n .. ": first screen")
		lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls")
		lu.assertEquals(#credits, 0, "mission " .. n .. ": spaceCreditReward calls")
		lu.assertEquals(optionsOf(transcript[1]), expectedOptions(heldSet(player)), "mission " .. n .. ": options")
	end

	-- AC-6: the real rewardPlayer: 25,000 credits and the mission's component (F1), through the reward screen
	TestDuliosRewardScreens["test_mission_" .. n .. "_won_the_reward_screen_grants_25000_credits_once"] = function()
		local player = rewardPilot(n)
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local items = H.spyOn(SpaceHelpers, "spaceItemReward")

		T.converse(tr, player)
		T.converse(tr, player)

		lu.assertEquals(#credits, 1, "mission " .. n .. ": spaceCreditReward calls over two visits")
		lu.assertEquals(credits[1] and credits[1].args[2], 25000, "mission " .. n .. ": credit amount")
		lu.assertEquals(#items, 1, "mission " .. n .. ": spaceItemReward calls over two visits")
	end
end

-- AC-6: only the reward screens pay; their header line is never used for another mission (the old arrangement shuffled them)
function TestDuliosRewardScreens:test_each_win_shows_its_own_reward_screen_and_pays_only_its_own_head()
	for n = 1, 4 do
		H.reset()

		local player = rewardPilot(n)
		local rec = T.spyRewards()
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, D.COMPLETE[n], "mission " .. n .. ": first screen")
		lu.assertEquals(rec.rewards, { D.HEADS[n] }, "mission " .. n .. ": heads paid")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: the choice and the training (D-4: free choice, as today)
---------------------------------------------------------------------------------------------

TestDuliosTrainingChoice = {}

function TestDuliosTrainingChoice:setUp() H.reset() end

-- Every set of 0..3 tier 3 skills held; the mission whose reward screen the pilot sees is (count + 1)
local STATES = {}

for mask = 0, 15 do
	local held, names = {}, {}

	for i, entry in ipairs(D.TRAIN_CHOICES) do
		if mask & (1 << (i - 1)) ~= 0 then
			held[#held + 1] = entry[1]
			names[#names + 1] = entry[3]:gsub("^train_", "")
		end
	end

	if #held <= 3 then
		STATES[#STATES + 1] = { skills = held, n = #held + 1, label = (#held == 0) and "no_skill" or ("holding_" .. table.concat(names, "_and_")) }
	end
end

for _, st in ipairs(STATES) do
	local n = st.n
	local function pilot(extra)
		extra = extra or {}
		extra.baseSkills = st.skills
		return rewardPilot(n, extra)
	end

	-- AC-7: the options are exactly the choice sids of the missing skills, in order; _final links only when exactly one is missing
	TestDuliosTrainingChoice["test_on_complete_mission" .. n .. "_" .. st.label .. "_the_options_are_the_missing_skills_in_order_with_final_only_for_the_last"] = function()
		local player = pilot()
		local transcript = T.converse(tr, player)

		lu.assertEquals(transcript[1].id, D.COMPLETE[n], st.label .. ": first screen")
		lu.assertEquals(optionsOf(transcript[1]), expectedOptions(setOf(st.skills)), st.label .. ": options")
	end

	for i, entry in ipairs(expectedOptions(setOf(st.skills))) do
		local choice = i - 1
		local skill
		local screenId = entry[2]

		for _, c in ipairs(D.TRAIN_CHOICES) do
			if c[3] == (entry[2]:gsub("_final$", "")) then
				skill = c[1]
			end
		end

		-- AC-7: choosing an option grants exactly that skill once through grantSpaceSkill(p, skill, false) and ends
		TestDuliosTrainingChoice["test_on_complete_mission" .. n .. "_" .. st.label .. "_choosing_" .. screenId .. "_calls_grant_space_skill_once_free_and_ends"] = function()
			local player = pilot()
			local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")
			local rec = T.spyRewards()
			local transcript = T.converse(tr, player, { choice })

			lu.assertEquals(#transcript, 2, "screens shown")
			lu.assertEquals(transcript[2].id, screenId, "second screen")
			lu.assertTrue(transcript[2].stop, "the training screen ends the conversation")
			lu.assertEquals(#skills, 1, "grantSpaceSkill calls")
			lu.assertEquals(skills[1].args[2], skill, "granted skill")
			lu.assertEquals(skills[1].args[3], false, "deductExperience argument")
			lu.assertEquals(rec.rewards, { D.HEADS[n] }, "rewardPlayer calls (the reward screen's only)")
		end

		-- AC-7: the real grant: the skill arrives through the free grant, no XP is checked or deducted (0 and 200000 XP)
		for _, xp in ipairs({ 0, 200000 }) do
			TestDuliosTrainingChoice["test_on_complete_mission" .. n .. "_" .. st.label .. "_choosing_" .. screenId .. "_with_" .. xp .. "_xp_grants_the_skill_and_spends_no_xp"] = function()
				local player = pilot({ experience = { [XP] = xp } })
				local costs = {}

				for _, c in ipairs(D.TRAIN_CHOICES) do costs[c[1]] = 200000 end

				H.Engine.config.skillXpCosts = costs

				local heldBefore = heldSet(player)

				lu.assertFalse(player:hasSkill(skill), "precondition: " .. skill .. " not held")
				T.converse(tr, player, { choice })

				lu.assertTrue(player:hasSkill(skill), "the pilot holds " .. skill)
				lu.assertEquals(skillCount(heldSet(player)), skillCount(heldBefore) + 1, "tier 3 skills held after the choice")
				lu.assertEquals(player.ghost:getExperience(XP), xp, XP .. " after the choice")
				lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-deducting grants")
			end
		end
	end

	-- AC-7: the tier: the fourth skill raises a tier 3 pilot to 4, the next visit shows completed_dulios and pays nothing;
	-- after a mission 1-3 skill the next visit shows the next mission's offer (one skill per win), the tier stays 3
	if n == 4 then
		TestDuliosTrainingChoice["test_on_complete_mission4_" .. st.label .. "_the_last_skill_raises_the_tier_to_4_and_the_next_visit_is_completed_dulios"] = function()
			local player = pilot()
			local rec = T.spyRewards()

			lu.assertEquals(player.ghost:getPilotTier(), 3, "precondition: tier")
			T.converse(tr, player, { 0 })
			lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after the fourth skill")

			local again = T.converse(tr, player)

			lu.assertEquals(again[1].id, "completed_dulios", "next visit")
			lu.assertEquals(rec.rewards, { D.HEADS[4] }, "rewardPlayer calls over both visits")
			lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after the next visit")
		end
	else
		TestDuliosTrainingChoice["test_on_complete_mission" .. n .. "_" .. st.label .. "_the_next_visit_shows_the_next_mission_offer_and_the_tier_stays_3"] = function()
			local player = pilot()
			local rec = T.spyRewards()

			T.converse(tr, player, { 0 })
			lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after skill " .. n)

			local again = T.converse(tr, player)

			lu.assertEquals(again[1].id, D.OFFER[n + 1], "next visit")
			lu.assertEquals(rec.rewards, { D.HEADS[n] }, "rewardPlayer calls over both visits")
		end
	end
end

-- AC-7: the XP is irrelevant to the offer too (no screen checks it): a pilot with 0 XP sees the same options as one with 200000
function TestDuliosTrainingChoice:test_the_options_do_not_depend_on_the_pilots_xp()
	local seen = {}

	for _, xp in ipairs({ 0, 199999, 200000 }) do
		H.reset()
		seen[#seen + 1] = optionsOf(T.converse(tr, rewardPilot(2, { experience = { [XP] = xp } }))[1])
	end

	lu.assertEquals(seen[2], seen[1], "options at 199999 XP vs 0 XP")
	lu.assertEquals(seen[3], seen[1], "options at 200000 XP vs 0 XP")
	lu.assertEquals(#seen[1], 3, "options at 0 XP")
end

---------------------------------------------------------------------------------------------
-- AC-8: the fallthrough (D-5)
---------------------------------------------------------------------------------------------

TestDuliosFallthrough = {}

function TestDuliosFallthrough:setUp() H.reset() end

-- A veteran: 4f complete, one tier 3 skill, mission 2's chain not complete, so no complete_mission{n} condition holds
local function veteran(opts)
	opts = opts or {}
	opts.win = opts.win or { 1 }
	opts.complete = tr.chains[4]
	opts.attempted = false

	if opts.baseSkills == nil then
		opts.baseSkills = { "pilot_neutral_starships_03" }
	end

	return T.player(tr, 2, opts)
end

-- AC-8: the first screen is complete_mission4, it pays the mission 4 head only if 4a:reward is unset
function TestDuliosFallthrough:test_a_veteran_with_4f_complete_and_one_skill_gets_complete_mission4_and_is_paid_for_mission_4_once()
	local player = veteran()
	local rec = T.spyRewards()

	lu.assertNil(rewarded(player, 4), "precondition: 4a:reward unset")
	lu.assertEquals(initialScreenId(player), "complete_mission4", "getInitialScreen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls from getInitialScreen")

	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, { D.HEADS[4] }, "rewardPlayer calls")
	lu.assertEquals(rewarded(player, 4), "1", "4a:reward")

	T.converse(tr, player)
	lu.assertEquals(rec.rewards, { D.HEADS[4] }, "rewardPlayer calls over two visits")
end

-- AC-8: 4a:reward already set: nothing is paid
function TestDuliosFallthrough:test_a_veteran_whose_4a_reward_key_is_set_gets_complete_mission4_and_is_not_paid()
	local player = veteran({ questStatus = { [D.KEYS[4] .. ":reward"] = "1" } })
	local rec = T.spyRewards()
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-8: the options link to the non-_final training screens while more than one skill is missing, the tier stays 3
function TestDuliosFallthrough:test_the_veterans_choices_are_the_three_missing_skills_with_plain_training_links()
	local transcript = T.converse(tr, veteran())

	lu.assertEquals(optionsOf(transcript[1]), { { "s_a70b470e", "train_components" }, { "s_da0e8cd0", "train_techniques" }, { "s_c28a300f", "train_programming" } }, "options")
end

-- AC-8: the chosen skill is granted and the tier stays 3 (the pilot does not hear the "assigned to Imler" line)
function TestDuliosFallthrough:test_choosing_a_skill_as_a_veteran_grants_it_free_and_leaves_the_tier_at_3()
	for i, entry in ipairs({ "pilot_neutral_weapons_03", "pilot_neutral_procedures_03", "pilot_neutral_droid_03" }) do
		H.reset()

		local player = veteran({ experience = { [XP] = 0 } })
		local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")
		local transcript = T.converse(tr, player, { i - 1 })

		lu.assertEquals(#transcript, 2, entry .. ": screens shown")
		lu.assertEquals(transcript[2].id, ({ "train_components", "train_techniques", "train_programming" })[i], entry .. ": second screen")
		lu.assertEquals(#skills, 1, entry .. ": grantSpaceSkill calls")
		lu.assertEquals(skills[1].args[2], entry, entry .. ": granted skill")
		lu.assertEquals(skills[1].args[3], false, entry .. ": deductExperience")
		lu.assertEquals(player.ghost:getPilotTier(), 3, entry .. ": pilot tier")
	end
end

-- AC-8: a veteran can finish tier 3: three choices over three visits, one M4 payment, tier 4 and completed_dulios at the end
function TestDuliosFallthrough:test_a_veteran_finishes_tier_3_with_one_mission_4_payment_and_ends_on_completed_dulios()
	local player = veteran()
	local rec = T.spyRewards()
	local seen = {}

	for visit = 1, 3 do
		local transcript = T.converse(tr, player, { 0 })

		seen[#seen + 1] = transcript[1].id .. ">" .. transcript[#transcript].id
	end

	lu.assertEquals(seen, { "complete_mission4>train_components", "complete_mission4>train_techniques", "complete_mission4>train_programming_final" }, "visits")
	lu.assertEquals(rec.rewards, { D.HEADS[4] }, "rewardPlayer calls over three visits")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after the fourth skill")
	lu.assertEquals(T.converse(tr, player)[1].id, "completed_dulios", "next visit")
end

-- AC-8: the last missing skill is offered with the _final link even on the fallthrough (count 3), like every other screen
function TestDuliosFallthrough:test_a_veteran_with_three_skills_and_no_mission_3_win_gets_the_final_link()
	local player = veteran({ baseSkills = { "pilot_neutral_starships_03", "pilot_neutral_weapons_03", "pilot_neutral_procedures_03" } })
	local transcript = T.converse(tr, player)

	-- 4f complete and three skills: the C7 mission 4 condition applies; either way the screen is complete_mission4 with one _final link
	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(optionsOf(transcript[1]), { { "s_c28a300f", "train_programming_final" } }, "options")
end

-- AC-8: a veteran with no tier 3 skill and no earlier win gets the same screen with four plain links
function TestDuliosFallthrough:test_a_veteran_with_no_skill_gets_complete_mission4_with_four_plain_links()
	local player = veteran({ win = {}, baseSkills = {} })
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "complete_mission4", "first screen")
	lu.assertEquals(optionsOf(transcript[1]), {
		{ "s_aa766bd6", "train_warships" }, { "s_a70b470e", "train_components" }, { "s_da0e8cd0", "train_techniques" }, { "s_c28a300f", "train_programming" },
	}, "options")
end

-- AC-8: with all four skills, completed_dulios still wins and pays nothing
function TestDuliosFallthrough:test_a_veteran_with_all_four_skills_still_gets_completed_dulios_and_pays_nothing()
	local player = veteran({ baseSkills = { "pilot_neutral_starships_03", "pilot_neutral_weapons_03", "pilot_neutral_procedures_03", "pilot_neutral_droid_03" } })
	local rec = T.spyRewards()
	local transcript = T.converse(tr, player)

	lu.assertEquals(transcript[1].id, "completed_dulios", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end
