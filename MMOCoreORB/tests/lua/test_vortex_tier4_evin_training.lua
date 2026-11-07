-- Brother Extok Evin: one-click, free-choice tier 4 training bought with 1,000,000 XP; missions alternate with skills; the pilot tier (AC-8).
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (AC-8; Conversation flow 1 (E17-E21), 2 (C-1) and 4; FE-1; D-4, D-5, D-10; I-6).
--
-- The `training` screen lists one topic reply per missing _04 skill, in table order (starships, weapons, procedures, droid). The skill is bought through
-- SpaceHelpers:grantSpaceSkill(player, skill, true) in getNextConversationScreen when the last screen was `training`, the chosen reply is a topic, the gates would open `training`
-- now and the skill manager agrees; the answer is the topic's trained screen, which ends. The fake charges XP only with H.Engine.config.skillXpCosts, set from
-- fixtures/skill/skills.pilot_rebel_navy_04.tab (1,000,000 each). Guards are tested through hooks: functions between two choices that change the pilot while the menu is shown.

local lu = require("luaunit")
local H = require("harness")
local E = require("vortex_tier4_data")
local CS = require("harness.client_strings")

E.loadConversation()

local TRAIN = E.TRAIN
local COST = E.TRAIN_COST

local function setUp()
	H.reset()
	E.requireConversation(lu)
	E.useSkillCosts()
end

local function tearDown() E.restore() end

-- all subsets of the four skills (indexes in table order) except the full one
local function subsets()
	local out = {}

	for mask = 0, 14 do
		local s = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				s[#s + 1] = i
			end
		end

		out[#out + 1] = s
	end

	return out
end

local function missing(have)
	local held = {}

	for _, i in ipairs(have) do
		held[i] = true
	end

	local out = {}

	for i = 1, 4 do
		if not held[i] then
			out[#out + 1] = i
		end
	end

	return out
end

-- the n - 1 skills held before the n-th, none of them `skip`
local function others(count, skip)
	local out = {}

	for i = 1, 4 do
		if i ~= skip and #out < count then
			out[#out + 1] = i
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The menu (C-1)
---------------------------------------------------------------------------------------------

TestEvinTrainingMenu = {}

TestEvinTrainingMenu.setUp = setUp
TestEvinTrainingMenu.tearDown = tearDown

-- AC-8: a pilot with the XP and no skill gets the menu of four topics
function TestEvinTrainingMenu:test_a_pilot_with_the_xp_gets_a_menu_of_four_topics_in_table_order()
	local t = E.talk(E.trainee({}))

	lu.assertEquals(E.ids(t), { "training" }, "screens shown")
	lu.assertEquals(t[1].text, E.PREFIX .. "s_5dbf1a94", "the menu line")
	lu.assertEquals(E.optionSids(t[1]), { "s_f4d84e3", "s_dbb3b0b0", "s_d0f87f24", "s_71d852f5" }, "menu replies, in table order")
	lu.assertEquals(E.linksOf(t[1]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid" }, "each topic leads to its trained screen")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-8: the menu lists exactly the missing skills, in table order
function TestEvinTrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].trained
		end

		local t = E.talk(E.trainee(have))

		lu.assertEquals(E.ids(t), { "training" }, label .. ": screens shown")
		lu.assertEquals(E.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertEquals(E.linksOf(t[1]), links, label .. ": links")
		lu.assertFalse(t[1].stop, label .. ": the menu waits")
	end
end

-- AC-8, C-1: with no skill left the screen ends (unreachable through the gates)
function TestEvinTrainingMenu:test_with_every_skill_held_the_menu_has_no_option_and_ends()
	local t = E.drive(E.trainee({ 1, 2, 3, 4 }), "training")

	lu.assertEquals(E.optionSids(t[1]), {}, "replies")
	lu.assertTrue(t[1].stop, "the screen ends the conversation")
end

-- AC-8: showing the menu or a trained screen alone grants nothing
function TestEvinTrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local grants = E.recordGrants()
	local player = E.trainee({})

	E.talk(player)

	for _, x in ipairs(TRAIN) do
		E.drive(player, x.trained)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#E.held4(player), 0, "_04 skills held")
	lu.assertEquals(E.exp(player), COST, "no XP charged")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestEvinTrainingGrant = {}

TestEvinTrainingGrant.setUp = setUp
TestEvinTrainingGrant.tearDown = tearDown

-- AC-8, FE-1, D-4: the topic buys the skill (1,000,000 XP) and shows its trained line, which ends; all four skills as the first choice, before every mission
for n = 1, 4 do
	for i, x in ipairs(TRAIN) do
		TestEvinTrainingGrant["test_choosing_" .. x.x .. "_as_skill_" .. n .. "_buys_the_skill_charges_1000000_xp_and_shows_" .. x.trained] = function()
			local grants = E.recordGrants()
			local player = E.trainee(others(n - 1, i), COST + 500000)
			local before = #E.held4(player)
			local t = E.talk(player, { x.reply })

			lu.assertEquals(E.ids(t), { "training", x.trained }, "screens shown")
			lu.assertEquals(t[2].text, E.PREFIX .. x.trainedSid, x.trained .. ": the trained line")
			lu.assertTrue(t[2].stop, x.trained .. " ends the conversation")
			lu.assertEquals(grants, { { skill = x.skill, deduct = true } }, "grantSpaceSkill(player, skill, true) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#E.held4(player), before + 1, "_04 skills held")
			lu.assertEquals(E.exp(player), 500000, "space XP after the purchase (1,000,000 charged)")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "XP-charging grants")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants (every tier 4 skill is bought)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-8, I-6: one skill per mission: after the grant the next talk is the offer of the next mission, never the menu
function TestEvinTrainingGrant:test_after_a_grant_the_next_talk_is_the_offer_and_the_menu_is_back_only_when_the_mission_is_paid()
	local player = E.trainee({}, 2 * COST)

	E.talk(player, { TRAIN[1].reply })
	lu.assertEquals(E.exp(player), COST, "XP left")
	lu.assertEquals(E.firstScreen(player), "m1_offer", "the skill waits for mission 1")

	-- mission 1 accepted and running
	E.setState(player, E.M1[1], "active")
	H.setQuestStatus(player, E.STATUS[1] .. ":attempted", 1)
	lu.assertEquals(E.firstScreen(player), "on_mission", "mission 1 running")

	-- mission 1 won and paid: the menu is back (1,000,000 XP left)
	E.setState(player, E.M1[1], "none")

	for _, g in ipairs({ E.M1[1], E.M1[2] }) do
		E.setState(player, g, "complete")
	end

	lu.assertEquals(E.firstScreen(player), "m1_reward", "mission 1 won and unpaid")
	lu.assertEquals(E.firstScreen(player), "training", "mission 1 paid on display: the menu is back (1,000,000 XP left)")
end

-- AC-8, I-6: a second choice before the mission is done grants nothing
function TestEvinTrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = E.recordGrants()
	local player = E.trainee({}, 3 * COST)

	E.drive(player, "training", { TRAIN[1].reply })
	E.drive(player, "training", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(E.held4(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(E.exp(player), 2 * COST, "only one purchase charged")
end

-- AC-8, D-10: the fourth skill raises pilot tier 4 to 5, and only then
function TestEvinTrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_4_to_5()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = E.trainee(others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 4, "precondition: pilot tier 4")
		E.talk(player, { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 5, x.x .. " as the fourth skill: pilot tier")
	end
end

-- AC-8: the first three skills leave the tier alone
function TestEvinTrainingGrant:test_the_first_three_skills_do_not_raise_the_pilot_tier()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = E.trainee(others(n - 1, 4))

		E.talk(player, { TRAIN[4].reply })
		lu.assertEquals(player.ghost.pilotTier, 4, "skill " .. n .. ": pilot tier")
	end
end

-- AC-8, D-10: a pilot still at tier 3 with the four _03 skills is raised to 4 by the first purchase
function TestEvinTrainingGrant:test_a_tier_3_pilot_with_the_four_tier_3_skills_is_raised_to_tier_4_by_the_first_purchase()
	local player = E.trainee({}, COST, { pilotTier = 3 })

	E.talk(player, { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the first purchase")
end

-- AC-8, D-10: the same pilot is raised to 4 by the first mission start and the first duty
function TestEvinTrainingGrant:test_a_tier_3_pilot_is_raised_to_tier_4_by_the_first_start_screen_and_the_first_duty_screen()
	E.stubChainStarts()
	E.spyDuties()

	for id in pairs(E.START_SCREENS) do
		H.reset()

		local player = E.pilot({ met = true, pilotTier = 3 })

		E.drive(player, id)
		lu.assertEquals(player.ghost.pilotTier, 4, id .. ": pilot tier")
	end

	for id in pairs(E.DUTY_SCREENS) do
		H.reset()

		local player = E.pilot({ met = true, pilotTier = 3 })

		E.drive(player, id)
		lu.assertEquals(player.ghost.pilotTier, 4, id .. ": pilot tier (a duty raises 3 to 4 and stops there)")
	end
end

-- AC-8, D-10: only the action screens raise; the gates and the plain screens do not
function TestEvinTrainingGrant:test_the_duty_menu_of_an_unfinished_pilot_does_not_raise_the_tier()
	local player = E.pilot({ met = true, pilotTier = 3 })

	E.drive(player, "tier4_incomplete")
	lu.assertEquals(player.ghost.pilotTier, 3, "tier4_incomplete is not an action screen")
	E.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 3, "the gates are pure")
end

-- AC-8: the purchase does not set the met key (a pilot who always had the XP meets Evin first)
function TestEvinTrainingGrant:test_the_purchase_does_not_set_the_met_key()
	local player = E.trainee({}, COST, { met = false })

	lu.assertEquals(E.firstScreen(player), "intro", "E12 before E21")
	E.drive(player, "training", { TRAIN[1].reply })
	lu.assertFalse(E.hasMet(player), "the met key")
end

-- AC-8: the whole talk: menu, topic, trained line; then the offer, its route, the grant of the mission
function TestEvinTrainingGrant:test_the_whole_walk_buys_a_skill_and_then_the_offer_starts_the_first_mission()
	local grants = E.recordGrants()
	local chains = E.stubChainStarts()
	local player = E.trainee({})
	local t = E.talk(player, { TRAIN[2].reply })

	lu.assertEquals(E.ids(t), { "training", "trained_weapons" }, "screens shown")
	lu.assertEquals(grants, { { skill = TRAIN[2].skill, deduct = true } }, "grantSpaceSkill calls")
	lu.assertEquals(chains, {}, "no mission starts at the training")

	local offer = E.talk(player, E.OFFER_PATHS[2].replies)

	lu.assertEquals(offer[1].id, "m1_offer", "the next talk opens the offer")
	lu.assertEquals(offer[#offer].id, "m1_accept_df1c8925", "the accept screen")
	lu.assertEquals(chains, { E.HEADS[1] }, "the mission started once")
end

-- AC-8, I-6: all 24 orders: the topics offered are exactly the missing skills whatever the order of earlier choices; the k-th grant is followed by mission k's offer
function TestEvinTrainingGrant:test_all_24_orders_of_choice_offer_exactly_the_missing_skills_and_end_with_all_four_and_tier_5()
	local function permutations(list)
		local out = {}

		local function go(k)
			if k > #list then
				out[#out + 1] = { table.unpack(list) }
				return
			end

			for i = k, #list do
				list[k], list[i] = list[i], list[k]
				go(k + 1)
				list[k], list[i] = list[i], list[k]
			end
		end

		go(1)
		return out
	end

	local orders = permutations({ 1, 2, 3, 4 })

	lu.assertEquals(#orders, 24, "orders")

	for _, order in ipairs(orders) do
		local label = "order " .. table.concat(order, "")
		local have = {}

		for step, choice in ipairs(order) do
			H.reset()
			setUp()

			local want = {}

			for _, i in ipairs(missing(have)) do
				want[#want + 1] = TRAIN[i].reply
			end

			local player = E.trainee(have, 2 * COST)
			local t = E.talk(player, { TRAIN[choice].reply })

			lu.assertEquals(E.optionSids(t[1]), want, label .. ", step " .. step .. ": the menu offers exactly the missing skills")
			lu.assertEquals(t[2].id, TRAIN[choice].trained, label .. ", step " .. step .. ": the trained screen")
			lu.assertEquals(E.exp(player), COST, label .. ", step " .. step .. ": 1,000,000 XP charged")
			lu.assertTrue(CreatureObject(player):hasSkill(TRAIN[choice].skill), label .. ", step " .. step .. ": the pilot holds the chosen skill")
			lu.assertEquals(E.firstScreen(player), "m" .. step .. "_offer", label .. ", step " .. step .. ": the next talk is mission " .. step .. "'s offer")
			have[#have + 1] = choice

			if step == 4 then
				lu.assertEquals(player.ghost.pilotTier, 5, label .. ": pilot tier 5 after the fourth skill")
			end
		end
	end
end

-- AC-8: the whole alternation: meet, skill, M1, skill, M2, skill, M3, skill, M4, transfer; the fourth skill raises the tier once
function TestEvinTrainingGrant:test_the_walk_meet_skill_mission_four_times_reaches_the_transfer()
	local chains = E.stubChainStarts()
	local player = E.pilot({ xp = 4 * COST + 250000 })

	-- the first meeting
	lu.assertEquals(E.talk(player, { "s_4265144c" })[2].id, E.MET_SCREEN, "the meeting")
	lu.assertTrue(E.hasMet(player), "met")

	local order = { 3, 1, 4, 2 }

	for step = 1, 4 do
		local screens = E.talk(player, { TRAIN[order[step]].reply })

		lu.assertEquals(E.ids(screens), { "training", TRAIN[order[step]].trained }, "step " .. step .. ": the training")
		lu.assertEquals(player.ghost.pilotTier, step == 4 and 5 or 4, "step " .. step .. ": pilot tier")

		local offer = E.talk(player, E.OFFER_PATHS[(step - 1) * 2 + 1].replies)

		lu.assertEquals(offer[1].id, "m" .. step .. "_offer", "step " .. step .. ": the offer")
		lu.assertEquals(offer[#offer].id, E.MISSIONS[step].accepts[1], "step " .. step .. ": the accept screen")

		-- the pilot flies and wins the mission through the success child; the next talk pays it
		for _, global in ipairs({ E.CHAINS[step][1], E.CHAINS[step][2] }) do
			E.setState(player, global, "complete")
		end

		lu.assertEquals(E.firstScreen(player), "m" .. step .. "_reward", "step " .. step .. ": the reward")
		lu.assertEquals(E.paid(player, step), "1", "step " .. step .. ": paid")
	end

	lu.assertEquals(chains, { E.HEADS[1], E.HEADS[2], E.HEADS[3], E.HEADS[4] }, "the four missions started once each")
	lu.assertEquals(E.firstScreen(player), "transfer", "four skills, four missions paid")
	lu.assertEquals(E.exp(player), 250000, "XP left after four purchases")
	lu.assertEquals(player.bankCredits, 40000, "four rewards")
end

---------------------------------------------------------------------------------------------
-- The guards (I-6)
---------------------------------------------------------------------------------------------

TestEvinTrainingGuards = {}

TestEvinTrainingGuards.setUp = setUp
TestEvinTrainingGuards.tearDown = tearDown

-- AC-8: below the XP the choice grants nothing and routes by the gates
function TestEvinTrainingGuards:test_a_choice_below_1000000_xp_grants_nothing_and_routes_by_the_gates()
	local grants = E.recordGrants()
	local player = E.trainee({}, COST - 1)
	local t = E.drive(player, "training", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "tier4_incomplete", "routed by the gates: under the XP, the duty menu screen")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#E.held4(player), 0, "_04 skills held")
	lu.assertEquals(E.exp(player), COST - 1, "XP unchanged")
end

-- AC-8: an offer waiting for its mission blocks the choice
function TestEvinTrainingGuards:test_a_choice_while_a_skill_waits_for_its_mission_grants_nothing_and_routes_to_the_offer()
	local grants = E.recordGrants()
	local player = E.pilot({ met = true, t4 = { 1 }, xp = 3 * COST })
	local t = E.drive(player, "training", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "m1_offer", "routed by the gates: the offer")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(E.held4(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(E.exp(player), 3 * COST, "XP unchanged")
end

-- AC-8: a reward owed blocks the choice
function TestEvinTrainingGuards:test_a_choice_while_a_reward_is_owed_grants_nothing()
	local grants = E.recordGrants()
	local player = E.rewardPilot(1, "won_a", { xp = 3 * COST })

	E.stubChainStarts()
	E.drive(player, "training", { TRAIN[2].reply })
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(E.held4(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(E.exp(player), 3 * COST, "XP unchanged")
end

-- AC-8: tier 3 not complete blocks the choice
function TestEvinTrainingGuards:test_a_choice_without_the_tier_3_skills_grants_nothing()
	local grants = E.recordGrants()
	local player = E.trainee({}, 2 * COST, { t3 = 3 })
	local t = E.drive(player, "training", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "not_ready", "routed by the gates")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(E.exp(player), 2 * COST, "XP unchanged")
end

-- AC-8: the "skill already held" guard, isolated. Every other guard stays true: the hook grants the weapons skill and pays mission 2 while the menu is shown, so the gates still open
-- `training` (two skills, missions 1 and 2 paid, the XP enough, tier 3 done, tier 4 open) and the skill manager says yes. Then the weapons topic is chosen.
function TestEvinTrainingGuards:test_a_skill_already_held_is_not_granted_again_and_the_screen_is_the_gates_not_a_trained_line()
	local grants = E.recordGrants()
	local player = E.pilot({ paid = { 1 }, t4 = { 1 }, xp = 3 * COST, met = true })
	local t = E.talk(player, {
		function(p)
			p.skills[TRAIN[2].skill] = true
			H.setQuestStatus(p, E.STATUS[2] .. ":reward", "1")
		end,
		TRAIN[2].reply,
	})

	lu.assertEquals(t[1].id, "training", "the menu was shown")
	lu.assertEquals(E.optionSids(t[1]), { "s_dbb3b0b0", "s_d0f87f24", "s_71d852f5" }, "the weapons topic was on the menu (the starships skill is held)")
	lu.assertEquals(#t, 2, "one more screen")
	lu.assertEquals(t[2].id, "training", "the screen is the gates' (the menu again), not a trained line")
	lu.assertEquals(E.optionSids(t[2]), { "s_d0f87f24", "s_71d852f5" }, "the weapons topic is gone from the new menu")

	for _, x in ipairs(TRAIN) do
		lu.assertNotEquals(t[2].id, x.trained, "not " .. x.trained)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(E.exp(player), 3 * COST, "XP unchanged")
	lu.assertEquals(E.held4(player), { TRAIN[1].skill, TRAIN[2].skill }, "_04 skills held (the hook's one)")
end

-- AC-8: each skill held meanwhile is refused in turn (the hook grants it and pays mission 1, so the gates still open the menu; the topic is chosen by its reply sid)
function TestEvinTrainingGuards:test_each_skill_held_meanwhile_is_refused_in_turn()
	for _, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local grants = E.recordGrants()
		local player = E.trainee({}, 3 * COST)

		E.talk(player, {
			function(p)
				p.skills[x.skill] = true
				H.setQuestStatus(p, E.STATUS[1] .. ":reward", "1")
			end,
			x.reply,
		})
		lu.assertEquals(grants, {}, x.x .. ": grantSpaceSkill calls")
		lu.assertEquals(E.exp(player), 3 * COST, x.x .. ": XP unchanged")
		E.restore()
	end
end

-- AC-8: the skill manager says no (prerequisites or XP): nothing is granted
function TestEvinTrainingGuards:test_a_failing_prerequisite_and_xp_check_grants_nothing()
	local grants = E.recordGrants()
	local orig = LuaSkillManager

	LuaSkillManager = function()
		local manager = orig()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = manager })
	end

	local player = E.trainee({}, 2 * COST)
	local ok, t = pcall(E.drive, player, "training", { TRAIN[1].reply })

	LuaSkillManager = orig
	lu.assertTrue(ok, "no Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "training", "the gates' screen, not a trained line")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#E.held4(player), 0, "_04 skills held")
	lu.assertEquals(E.exp(player), 2 * COST, "XP unchanged")
end

-- AC-8: the purchase fails in the engine (costs more than the pilot has): the skill is not held, so no trained line is shown
function TestEvinTrainingGuards:test_a_purchase_the_engine_refuses_shows_the_gates_screen_not_a_trained_line()
	local costs = E.useSkillCosts()

	costs[TRAIN[1].skill] = 2 * COST

	local player = E.trainee({}, COST)
	local t = E.drive(player, "training", { TRAIN[1].reply })

	lu.assertEquals(#E.held4(player), 0, "_04 skills held")
	lu.assertEquals(E.exp(player), COST, "XP unchanged")

	for _, x in ipairs(TRAIN) do
		lu.assertNotEquals(t[#t].id, x.trained, "no " .. x.trained .. " for a skill that was not bought")
	end
end

-- I-6: a skill grant happens only on a trained screen chosen from `training`: no reply of any other screen grants one
function TestEvinTrainingGuards:test_no_reply_on_any_other_screen_grants_a_skill()
	local grants = E.recordGrants()

	E.stubChainStarts()
	E.spyDuties()

	for _, row in ipairs(E.SCREENS) do
		if row.id ~= "training" then
			for i = 1, #row.options do
				H.reset()

				local player = E.trainee({}, 3 * COST)

				E.drive(player, row.id, { i - 1 })
			end
		end
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls over every reply of every screen but training")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill") + #H.Engine.callsTo("awardSkill"), 0, "skills granted")
end

-- AC-8: a grounded pilot who has the XP never reaches the menu, so no skill is sold to him
function TestEvinTrainingGuards:test_a_grounded_pilot_is_not_offered_the_training()
	local grants = E.recordGrants()
	local player = E.trainee({}, 2 * COST, { standing = -1 })
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "grounded" }, "the grounded gate")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end

-- AC-8: the pilot tier changes only upward: a pilot above 5 is left alone, and tier 5 is not reached with fewer than four skills
function TestEvinTrainingGuards:test_the_pilot_tier_only_moves_up_and_only_when_the_tier_is_complete()
	local player = E.graduate({ pilotTier = 6 })

	E.talk(player)
	lu.assertEquals(player.ghost.pilotTier, 6, "a higher tier stays")

	local three = E.trainee({ 1, 2, 3 }, 0, { pilotTier = 4 })

	E.drive(three, "transfer")
	lu.assertEquals(three.ghost.pilotTier, 4, "transfer with three skills does not raise past 4")
end
