-- Captain Kaydine (RSF tier 2) SWG training: the purchase (one skill per choice, through the XP-deducting grant), the mission introductions
-- and their grants, the full four-visit scenario and the fallback for legacy pilots.
-- Spec: .claude/work/rsf-tier2-kaydine-training/01-spec.md (AC-5 .. AC-8; Content contract 2; invariants I-4, I-5; D-3, D-4, D-5).
--
-- The harness fake charges nothing by itself. Tests that look at XP switch on H.Engine.config.skillXpCosts (every tier 2 skill costs 60000
-- space_combat_general, the XP_COST of fixtures/skill/skills.pilot_neutral_02.tab), which makes the fake refuse and charge like SkillManager:awardSkill.
-- H.Engine.callsTo("skillManagerAwardSkill") is the XP-deducting grant, callsTo("awardSkill") the free one.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_training_data")

T.load()

local tr = T.TRAINERS.kaydine
local XP = 60000
local E15 = "escort_naboo_privateer_15"
local REAL_SKILL_MANAGER = LuaSkillManager

local function skills(count)
	local out = {}

	for i = 1, count do
		out[i] = D.SKILLS[i]
	end

	return out
end

local function costs()
	local table_ = {}

	for _, skill in ipairs(D.SKILLS) do
		table_[skill] = XP
	end

	H.Engine.config.skillXpCosts = table_
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

-- The pilot about to be offered mission n with `skillList` as tier 2 skills and `amount` space XP; missions 1..n-1 won and paid
local function pilot(n, skillList, amount)
	return T.player(tr, n, { attempted = false, baseSkills = skillList, experience = { space_combat_general = amount } })
end

local function grants() return H.Engine.callsTo("skillManagerAwardSkill") end

-- startQuest of every quest global recorded (the real chain helper runs, so :attempted and the chain head behave); list of head names
local function spyStarts()
	local log = {}

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "startQuest", function() log[#log + 1] = name end)
	end

	return log
end

local function attemptedKeys(player)
	local out = {}

	for n = 1, 4 do
		out[n] = H.getQuestStatus(player, D.KEYS[n] .. ":attempted")
	end

	return out
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

---------------------------------------------------------------------------------------------
-- AC-5: the purchase
---------------------------------------------------------------------------------------------

TestKaydineTrainingPurchase = {}

function TestKaydineTrainingPurchase:setUp() H.reset() end

function TestKaydineTrainingPurchase:tearDown() LuaSkillManager = REAL_SKILL_MANAGER end

for k, t in ipairs(D.TRAINING) do
	-- AC-5, AC-6: SWG order, one XP-deducting grant, exactly 60000 XP, the intro of the mission the new skill count unlocks
	TestKaydineTrainingPurchase["test_choosing_" .. t.optionSid .. "_on_" .. t.screen .. "_buys_" .. t.skill .. "_once_for_60000_xp_and_shows_the_mission_" .. k .. "_intro"] = function()
		costs()

		local player = pilot(k, skills(k - 1), 3 * XP)
		local transcript = T.converse(tr, player, { 0, 0 })

		lu.assertEquals(ids(transcript), { "ready_train_pilot", t.screen, "trained_" .. t.x .. "_mission" .. k }, "screens")

		local calls = grants()

		lu.assertEquals(#calls, 1, "skillManagerAwardSkill calls")
		lu.assertTrue(calls[1][1] == player, "skillManagerAwardSkill player")
		lu.assertEquals(calls[1][2], t.skill, "skillManagerAwardSkill skill")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill (free grant) calls")
		lu.assertEquals(exp(player), 2 * XP, "space_combat_general after the purchase (3 x 60000 - 60000)")
		lu.assertEquals(SpaceHelpers:getPilotTierSkillCount(player, "neutral", 2), k, "tier 2 skills held")

		for i, skill in ipairs(D.SKILLS) do
			lu.assertEquals(CreatureObject(player):hasSkill(skill), i <= k, skill .. ": held")
		end
	end
end

-- AC-5: the pilot already owns the skill when the choice is made
function TestKaydineTrainingPurchase:test_choosing_the_option_for_a_skill_the_pilot_already_has_grants_nothing_and_charges_nothing()
	costs()

	local player = pilot(1, {}, 3 * XP)
	local transcript = T.converse(tr, player, {
		0,
		function(p) p.skills[D.SKILLS[1]] = true end, -- the skill arrives while the prompt is shown
		0,
	})

	lu.assertEquals(transcript[2].id, "train_starships", "second screen")
	lu.assertEquals(#grants(), 0, "skillManagerAwardSkill calls")
	lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "awardSkill calls")
	lu.assertEquals(exp(player), 3 * XP, "space_combat_general")
end

-- AC-5, AC-8: the XP is gone at the moment of choosing
function TestKaydineTrainingPurchase:test_choosing_the_option_after_the_xp_is_gone_grants_nothing_and_falls_back_to_the_first_screen_logic()
	costs()

	local player = pilot(1, {}, XP)
	local starts = spyStarts()
	local transcript = T.converse(tr, player, {
		0,
		function(p) p.ghost.experience.space_combat_general = XP - 1 end,
		0,
	})

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_starships", "here_for_work" }, "screens (D-3: the start logic runs again)")
	lu.assertEquals(#grants(), 0, "skillManagerAwardSkill calls")
	lu.assertFalse(CreatureObject(player):hasSkill(D.SKILLS[1]), "starships_02 held")
	lu.assertEquals(exp(player), XP - 1, "space_combat_general")
	lu.assertEquals(starts, {}, "startQuest calls")
end

-- AC-5, D-4: the engine would refuse (prerequisites missing): no grant call, no "skill learned" message
function TestKaydineTrainingPurchase:test_choosing_the_option_when_the_prerequisites_are_missing_grants_nothing_and_sends_no_skill_learned_message()
	costs()

	local player = pilot(1, {}, 3 * XP)

	LuaSkillManager = function()
		local real = REAL_SKILL_MANAGER()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = real })
	end

	local messages = #H.messageLog(player)
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(transcript[2].id, "train_starships", "second screen")
	lu.assertEquals(#grants(), 0, "skillManagerAwardSkill calls")
	lu.assertEquals(#H.messageLog(player), messages, "system messages (no 'skill learned')")
	lu.assertEquals(exp(player), 3 * XP, "space_combat_general")
end

-- AC-5, I-4: choosing the same prompt again buys nothing more
function TestKaydineTrainingPurchase:test_choosing_the_option_on_the_prompt_twice_buys_one_skill()
	costs()

	local player = pilot(1, {}, 10 * XP)

	T.converse(tr, player, { 0, 0 })
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls after the first conversation")

	D.drive(tr, player, "train_starships", { 0 })
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls after choosing on train_starships again")
	lu.assertEquals(exp(player), 9 * XP, "space_combat_general (charged once)")
end

-- AC-5, I-4: the prompt of one skill buys that skill only, whatever else the pilot lacks
function TestKaydineTrainingPurchase:test_each_prompt_buys_only_its_own_skill()
	costs()

	for _, t in ipairs(D.TRAINING) do
		H.reset()
		costs()

		local player = pilot(1, {}, 10 * XP)

		D.drive(tr, player, t.screen, { 0 })

		lu.assertEquals(#grants(), 1, t.screen .. ": skillManagerAwardSkill calls")
		lu.assertEquals(grants()[1][2], t.skill, t.screen .. ": skill")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, t.screen .. ": awardSkill calls")

		for _, skill in ipairs(D.SKILLS) do
			lu.assertEquals(CreatureObject(player):hasSkill(skill), skill == t.skill, t.screen .. ": " .. skill .. " held")
		end
	end
end

-- AC-5
function TestKaydineTrainingPurchase:test_the_fourth_purchase_raises_the_pilot_tier_to_3_and_dulios_then_talks_to_the_pilot()
	costs()

	local dulios = T.TRAINERS.dulios
	local player = T.player(tr, 4, { attempted = false, baseSkills = skills(3), experience = { space_combat_general = 2 * XP } })

	lu.assertEquals(player.ghost:getPilotTier(), 2, "setup: pilot tier")
	lu.assertEquals(T.converse(dulios, player)[1].id, "not_tier3", "setup: Dulios turns a tier 2 pilot away")

	H.Engine.calls = {}

	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_droid", "trained_droid_mission4" }, "screens")
	lu.assertEquals(grants()[1][2], "pilot_neutral_droid_02", "skill bought")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after the fourth skill")
	lu.assertNotEquals(T.converse(dulios, player)[1].id, "not_tier3", "Dulios's first screen")
end

-- AC-5: the first three purchases leave the tier alone
function TestKaydineTrainingPurchase:test_the_first_three_purchases_leave_the_pilot_tier_at_2()
	costs()

	local player = pilot(1, {}, 10 * XP)

	for i = 1, 3 do
		D.drive(tr, player, D.TRAINING[i].screen, { 0 })
		lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after skill " .. i)
	end
end

-- AC-5, I-4: entering any screen without choosing on a prompt buys nothing
function TestKaydineTrainingPurchase:test_entering_any_screen_of_the_template_buys_nothing()
	costs()

	for _, screen in ipairs(H.conversationTemplateTable(tr.template).screens) do
		H.reset()
		costs()

		local player = pilot(1, {}, 10 * XP)
		local tmpl = H.conversationTemplate(tr.template)

		handler():runScreenHandlers(tmpl, player, H.newNpc({}), 0, LuaConversationTemplate(tmpl):getScreen(screen.id))
		lu.assertEquals(#grants(), 0, screen.id .. ": skillManagerAwardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, screen.id .. ": awardSkill calls")
		lu.assertEquals(exp(player), 10 * XP, screen.id .. ": space_combat_general")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: the 16 introductions and the grants behind them
---------------------------------------------------------------------------------------------

TestKaydineTrainingIntro = {}

function TestKaydineTrainingIntro:setUp() H.reset() end

-- The N - 1 tier 2 skills other than x, in SWG order
local function skillsBefore(x, n)
	local out = {}

	for _, t in ipairs(D.TRAINING) do
		if t.x ~= x and #out < n - 1 then
			out[#out + 1] = t.skill
		end
	end

	return out
end

-- Drives the purchase on train_<x> and then option `route` of the intro and option 1 afterwards; snapshots the state after every screen
local function walkIntro(row, gender, secondChoice)
	costs()

	local player = pilot(row.n, skillsBefore(row.x, row.n), 3 * XP)

	player.gender = gender or 0

	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local rewards = T.spyRewards()
	local snaps = {}
	local choices = { 0 }
	-- one hook before every move from an intro screen to the next one: it sees the state right after that screen was shown
	local steps = secondChoice and #D.ROUTE_B or (#row.walk - 1)

	for i = 1, steps do
		choices[#choices + 1] = function() snaps[#snaps + 1] = { chains = #chains, attempted = H.getQuestStatus(player, D.KEYS[row.n] .. ":attempted"), rewards = #rewards.rewards, grants = #grants() } end
		choices[#choices + 1] = (i == 1 and secondChoice) and 1 or 0
	end

	local transcript = D.drive(tr, player, "train_" .. row.x, choices)

	return player, transcript, chains, snaps, rewards
end

for _, row in ipairs(D.INTRO) do
	-- AC-6
	TestKaydineTrainingIntro["test_buying_" .. row.x .. "_with_" .. (row.n - 1) .. "_skills_shows_" .. row.id .. "_and_option_1_walks_to_the_grant_on_" .. row.grant] = function()
		local player, transcript, chains, snaps = walkIntro(row)
		local expected = { "train_" .. row.x }

		for _, id in ipairs(row.walk) do
			expected[#expected + 1] = id
		end

		lu.assertEquals(ids(transcript), expected, row.id .. ": screens")
		lu.assertEquals(#chains, 1, row.id .. ": startSpaceQuestChain calls over the whole walk")
		lu.assertEquals(chains[1].args[3], D.HEADS[row.n], row.id .. ": chain started")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[row.n] .. ":attempted"), "1", row.id .. ": " .. D.KEYS[row.n] .. ":attempted")
		lu.assertEquals(#grants(), 1, row.id .. ": skillManagerAwardSkill calls (the purchase only)")

		-- the snapshots are taken after every screen from the intro to the one before the grant screen
		lu.assertEquals(#snaps, #row.walk - 1, row.id .. ": snapshots")

		for i = 1, #snaps do
			lu.assertEquals(snaps[i].chains, 0, row.id .. ": startSpaceQuestChain calls before the grant screen (after " .. ids(transcript)[i + 1] .. ")")
			lu.assertNil(snaps[i].attempted, row.id .. ": :attempted before the grant screen (after " .. ids(transcript)[i + 1] .. ")")
			lu.assertEquals(snaps[i].rewards, 0, row.id .. ": rewardPlayer calls before the grant screen")
			lu.assertEquals(snaps[i].grants, 1, row.id .. ": skillManagerAwardSkill calls after " .. ids(transcript)[i + 1])
		end
	end
end

-- AC-6: starships, mission 1, second route, male and female
for _, gender in ipairs({ 0, 1 }) do
	local label = gender == 0 and "male" or "female"
	local grant = gender == 0 and "mission1_intro_accept_male" or "mission1_intro_accept"

	TestKaydineTrainingIntro["test_the_s_248_route_of_the_starships_intro_ends_on_" .. grant .. "_for_a_" .. label .. "_pilot_and_grants_mission_1_once"] = function()
		local row = D.INTRO[1]
		local player, transcript, chains, snaps = walkIntro(row, gender, true)
		local expected = { "train_starships" }

		for _, id in ipairs(D.ROUTE_B) do
			expected[#expected + 1] = id
		end

		expected[#expected + 1] = grant

		lu.assertEquals(ids(transcript), expected, label .. ": screens")
		lu.assertEquals(#chains, 1, label .. ": startSpaceQuestChain calls")
		lu.assertEquals(chains[1].args[3], D.HEADS[1], label .. ": chain started")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[1] .. ":attempted"), "1", label .. ": :attempted")

		for i = 1, #snaps do
			lu.assertEquals(snaps[i].chains, 0, label .. ": startSpaceQuestChain calls after " .. ids(transcript)[i + 1])
		end
	end
end

-- AC-6: the s_226 route, female pilot, ends on mission1_accept (the convo feature's brief)
function TestKaydineTrainingIntro:test_the_s_226_route_of_the_starships_intro_ends_on_mission1_accept_for_a_female_pilot()
	local row = D.INTRO[1]
	local player, transcript, chains = walkIntro(row, 1)

	lu.assertEquals(transcript[#transcript].id, "mission1_accept", "last screen")
	lu.assertEquals(#chains, 1, "startSpaceQuestChain calls")
	lu.assertEquals(H.getQuestStatus(player, D.KEYS[1] .. ":attempted"), "1", ":attempted")
end

-- AC-6, E-T3: the option of mission1_intro_b4 is re-pointed at the male screen only for male pilots
function TestKaydineTrainingIntro:test_mission1_intro_b4_links_the_male_ending_to_male_pilots_and_the_other_ending_to_female_pilots()
	for gender, link in pairs({ [0] = "mission1_intro_accept_male", [1] = "mission1_intro_accept" }) do
		H.reset()

		local player = pilot(1, {}, 3 * XP)

		player.gender = gender

		local transcript = D.drive(tr, player, "mission1_intro_b4", {})

		lu.assertEquals(#transcript[1].options, 1, "gender " .. gender .. ": number of options")
		lu.assertEquals(transcript[1].options[1].text, D.PREFIX .. "s_264", "gender " .. gender .. ": option text")
		lu.assertEquals(transcript[1].options[1].link, link, "gender " .. gender .. ": link")
	end
end

-- AC-6, I-5: the mission 1 end screens start the real chain, once, with the head active
function TestKaydineTrainingIntro:test_the_two_mission_1_end_screens_make_the_head_of_mission_1_active()
	for _, id in ipairs({ "mission1_intro_accept", "mission1_intro_accept_male" }) do
		H.reset()

		local player = T.player(tr, 1, { attempted = false })
		local tmpl = H.conversationTemplate(tr.template)

		handler():runScreenHandlers(tmpl, player, H.newNpc({}), 0, LuaConversationTemplate(tmpl):getScreen(id))
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[1] .. ":attempted"), "1", id .. ": :attempted")
		lu.assertEquals(T.state(player, D.HEADS[1]), "active", id .. ": " .. D.HEADS[1])
	end
end

-- AC-6 (legacy order): the intro follows the next mission, and out of order skills reach the same intros
function TestKaydineTrainingIntro:test_a_pilot_who_holds_the_other_skills_out_of_order_sees_the_intro_of_the_skill_he_buys()
	costs()

	local player = pilot(3, { D.SKILLS[4], D.SKILLS[2] }, 3 * XP) -- droid and weapons held, starships and procedures missing
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_starships", "trained_starships_mission3" }, "screens")
	lu.assertEquals(grants()[1][2], "pilot_neutral_starships_02", "skill bought")
end

-- AC-6, E-T5: the intro follows the next mission (N), offered when the skill count is at least N. A legacy pilot who holds more skills than his
-- missions need (s > N after the purchase) sees the intro of mission N, never one of a mission he has already won
function TestKaydineTrainingIntro:test_a_pilot_ahead_of_his_missions_sees_the_intro_of_the_next_mission_not_of_the_skill_count()
	local cases = {
		{ 1, { 1 }, 2, "trained_weapons_mission1" },
		{ 2, { 1, 2 }, 3, "trained_procedures_mission2" },
		{ 2, { 2, 4 }, 1, "trained_starships_mission2" },
		{ 3, { 1, 2, 3 }, 4, "trained_droid_mission3" },
	}

	for _, c in ipairs(cases) do
		H.reset()
		costs()

		local held = {}

		for _, i in ipairs(c[2]) do
			held[#held + 1] = D.SKILLS[i]
		end

		local player = pilot(c[1], held, 3 * XP)
		local transcript = D.drive(tr, player, D.TRAINING[c[3]].screen, { 0 })

		lu.assertEquals(ids(transcript), { D.TRAINING[c[3]].screen, c[4] }, "mission " .. c[1] .. " next, " .. #held .. " skills held, buying " .. D.SKILLS[c[3]])
		lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: one skill per visit
---------------------------------------------------------------------------------------------

TestKaydineTrainingScenario = {}

function TestKaydineTrainingScenario:setUp() H.reset() end

local function winAll(player, n)
	for _, g in ipairs(D.WON[n]) do
		T.setState(player, g, "complete")
	end
end

-- AC-7
function TestKaydineTrainingScenario:test_four_trainings_buy_one_skill_each_in_swg_order_and_grant_the_matching_mission()
	costs()

	local player = T.player(tr, 1, { attempted = false, baseSkills = {}, experience = { space_combat_general = 4 * XP } })
	local starts = spyStarts()
	local greetings = 0

	for k, t in ipairs(D.TRAINING) do
		local before = #grants()
		local startsBefore = #starts
		local walk = D.INTRO[(k - 1) * 4 + k].walk -- the canonical intro of skill k for mission k
		local choices = {}

		for _ = 1, #walk + 1 do
			choices[#choices + 1] = 0
		end

		local transcript = T.converse(tr, player, choices)

		if transcript[1].id == "ready_train_pilot" then
			greetings = greetings + 1
		end

		lu.assertEquals(transcript[1].id, "ready_train_pilot", "training " .. k .. ": first screen")
		lu.assertNotNil(transcript[3], "training " .. k .. ": the conversation reached the intro (screens: " .. table.concat(ids(transcript), ", ") .. ")")
		lu.assertEquals(transcript[3].id, "trained_" .. t.x .. "_mission" .. k, "training " .. k .. ": intro")
		lu.assertEquals(transcript[#transcript].id, walk[#walk], "training " .. k .. ": last screen (the grant)")
		lu.assertEquals(#grants() - before, 1, "training " .. k .. ": skills bought in the conversation")
		lu.assertEquals(grants()[#grants()][2], t.skill, "training " .. k .. ": skill bought")
		lu.assertEquals(#starts - startsBefore, 1, "training " .. k .. ": missions started in the conversation")
		lu.assertEquals(starts[#starts], D.HEADS[k], "training " .. k .. ": mission started")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[k] .. ":attempted"), "1", "training " .. k .. ": :attempted")
		lu.assertEquals(exp(player), (4 - k) * XP, "training " .. k .. ": space_combat_general")

		-- the pilot flies and wins the mission; the head's chain is complete, then the reward is collected
		for _, g in ipairs(D.WON[k]) do
			T.setState(player, g, "active")
		end

		lu.assertEquals(T.converse(tr, player)[1].id, "on_mission", "training " .. k .. ": first screen while the mission runs")
		winAll(player, k)

		local rewardBefore = #grants()
		local reward = T.converse(tr, player, k == 2 and {} or { 0 })

		lu.assertEquals(reward[1].id, ({ "mission1_complete", "mission2_reward", "mission3_complete", "mission4_complete" })[k], "training " .. k .. ": first screen after the win")
		lu.assertEquals(#grants(), rewardBefore, "training " .. k .. ": skills bought while the reward is collected")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[k] .. ":reward"), "1", "training " .. k .. ": :reward")
	end

	lu.assertEquals(greetings, 4, "conversations that began on the training greeting")
	lu.assertEquals(T.converse(tr, player)[1].id, "completed_kaydine", "first screen after mission 4 is paid")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")

	for _, skill in ipairs(D.SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill .. " held")
	end
end

-- AC-7: leaving after the purchase keeps the offer for the next visit and buys nothing
function TestKaydineTrainingScenario:test_leaving_after_a_purchase_shows_the_mission_offer_next_time_and_buys_nothing()
	for k, t in ipairs(D.TRAINING) do
		H.reset()
		costs()

		local player = pilot(k, skills(k - 1), 10 * XP)
		local transcript = T.converse(tr, player, { 0, 0 })

		lu.assertEquals(transcript[#transcript].id, "trained_" .. t.x .. "_mission" .. k, "training " .. k .. ": the pilot leaves on the intro")

		local before = #grants()

		for visit = 1, 2 do
			local next = T.converse(tr, player)

			lu.assertEquals(next[1].id, "mission" .. k .. "_ready", "training " .. k .. ": first screen of visit " .. visit)
		end

		lu.assertEquals(#grants(), before, "training " .. k .. ": skills bought on the later visits")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[k] .. ":attempted"), nil, "training " .. k .. ": :attempted (nothing was granted)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: the fallback for pilots with nothing to be introduced to (D-3)
---------------------------------------------------------------------------------------------

TestKaydineTrainingFallback = {}

function TestKaydineTrainingFallback:setUp() H.reset() end

-- AC-8: s = 1, mission 2 won, XP for two skills: the purchase leaves s < N
function TestKaydineTrainingFallback:test_a_pilot_still_behind_after_the_purchase_sees_the_training_greeting_again_and_nothing_starts()
	costs()

	local player = pilot(3, { D.SKILLS[1] }, 2 * XP)
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local before = attemptedKeys(player)
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_weapons", "ready_train_pilot" }, "screens")
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls")
	lu.assertEquals(grants()[1][2], "pilot_neutral_weapons_02", "skill bought")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls (a won mission is never granted again)")
	lu.assertEquals(attemptedKeys(player), before, ":attempted keys")
	lu.assertEquals(exp(player), XP, "space_combat_general")
end

-- AC-8: one more choice buys one more skill, never two at once
function TestKaydineTrainingFallback:test_each_choice_on_a_prompt_buys_at_most_one_skill_even_when_the_greeting_comes_back()
	costs()

	local player = pilot(3, { D.SKILLS[1] }, 2 * XP)
	local transcript = T.converse(tr, player, { 0, 0, 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_weapons", "ready_train_pilot", "train_procedures", "trained_procedures_mission3" }, "screens")
	lu.assertEquals(#grants(), 2, "skillManagerAwardSkill calls over the conversation (one per choice)")
	lu.assertEquals({ grants()[1][2], grants()[2][2] }, { "pilot_neutral_weapons_02", "pilot_neutral_procedures_02" }, "skills bought, in order")
end

-- AC-8: the fourth skill after mission 4 is paid: the finished screen
function TestKaydineTrainingFallback:test_the_last_skill_after_a_paid_mission_4_leads_to_completed_kaydine_and_tier_3()
	costs()

	local player = T.player(tr, 4, { complete = { E15 }, baseSkills = skills(3), experience = { space_combat_general = XP }, questStatus = { ["naboo_privateer_15:reward"] = "1" } })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_droid", "completed_kaydine" }, "screens")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls")
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls")
end

-- AC-8: no XP left for the next skill: the duty greeting
function TestKaydineTrainingFallback:test_a_paid_pilot_with_two_skills_who_buys_the_third_with_the_last_xp_is_sent_to_here_for_work()
	costs()

	local player = T.player(tr, 4, { complete = { E15 }, baseSkills = skills(2), experience = { space_combat_general = XP }, questStatus = { ["naboo_privateer_15:reward"] = "1" } })
	local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(ids(transcript), { "ready_train_pilot", "train_procedures", "here_for_work" }, "screens")
	lu.assertEquals(#chains, 0, "startSpaceQuestChain calls")
	lu.assertEquals(#grants(), 1, "skillManagerAwardSkill calls")
	lu.assertEquals(exp(player), 0, "space_combat_general")
end

-- AC-8: the fallback is the first screen a new conversation would show
function TestKaydineTrainingFallback:test_the_fallback_screen_equals_the_first_screen_of_the_next_visit()
	costs()

	local player = pilot(3, { D.SKILLS[1] }, 2 * XP)
	local transcript = T.converse(tr, player, { 0, 0 })

	lu.assertEquals(transcript[#transcript].id, T.converse(tr, player)[1].id, "fallback screen vs first screen of the next conversation")
end
