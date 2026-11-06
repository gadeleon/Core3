-- Ja'ce Yiaso: one-click, free-choice tier 4 training bought with 1,000,000 XP (FJ-1, D-3, D-10, I-10).
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-10; Conversation flow 2 (C-1) and 4; FJ-1, FJ-4; D-3, D-10; I-10).
--
-- The menu `ready_train` lists one topic reply per missing _04 skill, in table order (starships, weapons, procedures, droid). The skill is bought
-- through SpaceHelpers:grantSpaceSkill(player, skill, true) in getNextConversationScreen when the last screen was ready_train and the chosen reply
-- is a topic; the answer is TRAINED_BRIEFS[getNextMission]. The fake charges XP only with H.Engine.config.skillXpCosts, set from
-- fixtures/skill/skills.pilot_imperial_navy_04.tab (1,000,000 each). Guards are tested through hooks: functions between two choices that change
-- the pilot while the menu is shown.

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local TRAIN = J4.TRAIN
local COST = J4.TRAIN_COST

local function setUp()
	H.reset()
	J4.requireConversation(lu)
	J4.useSkillCosts()
end

local function tearDown() J4.restore() end

local function exp(player) return player.ghost.experience.space_combat_general end

-- a pilot with the skills `have` (TRAIN indexes), their missions won and paid, `xp` XP, past the first meeting
local function pilot(have, xp, extra)
	local paid = {}

	for i = 1, #have do
		paid[i] = i
	end

	local o = { t4 = have, paid = paid, xp = xp or COST, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return J4.pilot(o)
end

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

-- the trained opening of mission n and its client line
local BRIEFS = {
	{ id = "m1_brief_trained", sid = "s_490da0e3" },
	{ id = "m2_brief_trained", sid = "s_cacb4480" },
	{ id = "m3_brief_trained", sid = "s_aa21cdc1" },
	{ id = "m4_brief_trained", sid = "s_72c7b032" },
}

---------------------------------------------------------------------------------------------
-- The menu (C-1)
---------------------------------------------------------------------------------------------

TestInquisitionT4TrainingMenu = {}

TestInquisitionT4TrainingMenu.setUp = setUp

-- AC-10: a pilot with the XP and no skill gets the menu of four topics
function TestInquisitionT4TrainingMenu:test_a_pilot_with_the_xp_gets_a_menu_of_four_topics_in_table_order()
	local t = J4.talk(pilot({}))

	lu.assertEquals(J4.ids(t), { "ready_train" }, "screens shown")
	lu.assertEquals(t[1].text, J4.PREFIX .. "s_5dce257f", "the menu line")
	lu.assertEquals(J4.optionSids(t[1]), { "s_d8355c02", "s_96a0374a", "s_d8efd03b", "s_7e1308bc" }, "menu replies, in table order")
	lu.assertEquals(J4.linksOf(t[1]), { "m1_brief_trained", "m1_brief_trained", "m1_brief_trained", "m1_brief_trained" }, "static default links (the grant routes by reply text)")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the menu lists exactly the missing skills, in table order
function TestInquisitionT4TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, label = {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
		end

		local t = J4.talk(pilot(have))

		lu.assertEquals(J4.ids(t), { "ready_train" }, label .. ": screens shown")
		lu.assertEquals(J4.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertFalse(t[1].stop, label .. ": the menu waits")
	end
end

-- AC-10, C-1: with no skill left the screen ends (unreachable through the gates)
function TestInquisitionT4TrainingMenu:test_with_every_skill_held_the_menu_has_no_option_and_ends()
	local t = J4.drive(pilot({ 1, 2, 3, 4 }), "ready_train")

	lu.assertEquals(J4.optionSids(t[1]), {}, "replies")
	lu.assertTrue(t[1].stop, "the screen ends the conversation")
end

-- AC-10: showing the menu or a trained opening alone grants nothing
function TestInquisitionT4TrainingMenu:test_showing_the_menu_or_a_trained_opening_alone_grants_nothing()
	local grants = J4.recordGrants()
	local player = pilot({})

	J4.talk(player)

	for _, b in ipairs(BRIEFS) do
		J4.drive(player, b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#J4.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "no XP charged")
	J4.restore()
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestInquisitionT4TrainingGrant = {}

TestInquisitionT4TrainingGrant.setUp = setUp
TestInquisitionT4TrainingGrant.tearDown = tearDown

-- AC-10, FJ-1, D-3: the topic buys the skill (1,000,000 XP) and shows the trained opening of the next unwon mission, all four skills as the first choice
-- and all four missions
for n = 1, 4 do
	for i, x in ipairs(TRAIN) do
		TestInquisitionT4TrainingGrant["test_choosing_" .. x.x .. "_before_mission_" .. n .. "_buys_the_skill_charges_1000000_xp_and_shows_" .. BRIEFS[n].id] = function()
			local grants = J4.recordGrants()
			local player = pilot(others(n - 1, i), COST + 500000)
			local before = #J4.held(player)
			local t = J4.talk(player, { x.reply })

			lu.assertEquals(J4.ids(t), { "ready_train", BRIEFS[n].id }, "screens shown")
			lu.assertEquals(t[2].text, J4.PREFIX .. BRIEFS[n].sid, BRIEFS[n].id .. ": the opening line")
			lu.assertFalse(t[2].stop, BRIEFS[n].id .. " continues into the briefing")
			lu.assertEquals(grants, { { skill = x.skill, deduct = true } }, "grantSpaceSkill(player, skill, true) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#J4.held(player), before + 1, "_04 skills held")
			lu.assertEquals(exp(player), 500000, "space XP after the purchase (1,000,000 charged)")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "XP-charging grants")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants (every tier 4 skill is bought)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-10, I-10: one skill per mission: after the grant the talk shows the ready prompt of the next mission, never the menu
function TestInquisitionT4TrainingGrant:test_after_a_grant_the_next_talk_is_the_ready_prompt_and_the_menu_is_gone_until_the_mission_is_won()
	local player = pilot({}, 2 * COST)

	J4.talk(player, { TRAIN[1].reply })
	lu.assertEquals(exp(player), COST, "XP left")
	lu.assertEquals(J4.firstScreen(player), "ready", "the skill waits for mission 1")

	-- mission 1 accepted and running
	J4.setState(player, J4.M1[1], "active")
	H.setQuestStatus(player, "naboo_imperial_tier4_1:attempted", 1)
	lu.assertEquals(J4.firstScreen(player), "on_mission", "mission 1 running")

	-- mission 1 won and paid: the menu is back (1,000,000 XP left)
	J4.setState(player, J4.M1[1], "none")

	for _, g in ipairs(J4.M1) do
		J4.setState(player, g, "complete")
	end

	H.setQuestStatus(player, "naboo_imperial_tier4_1:reward", 1)
	lu.assertEquals(J4.firstScreen(player), "ready_train", "mission 1 won and paid, 1,000,000 XP left")
end

-- AC-10, I-10: a second choice before the mission is done grants nothing
function TestInquisitionT4TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = J4.recordGrants()
	local player = pilot({}, 3 * COST)

	J4.drive(player, "ready_train", { TRAIN[1].reply })
	J4.drive(player, "ready_train", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(J4.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "only one purchase charged")
end

-- AC-10, D-10: the fourth skill raises pilot tier 4 to 5, and only then
function TestInquisitionT4TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_4_to_5()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = pilot(others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 4, "precondition: pilot tier 4")
		J4.talk(player, { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 5, x.x .. " as the fourth skill: pilot tier")
	end
end

-- AC-10: the first three skills leave the tier alone
function TestInquisitionT4TrainingGrant:test_the_first_three_skills_do_not_raise_the_pilot_tier()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(others(n - 1, 4))

		J4.talk(player, { TRAIN[4].reply })
		lu.assertEquals(player.ghost.pilotTier, 4, "skill " .. n .. ": pilot tier")
	end
end

-- AC-10, D-10: a pilot still at tier 3 with the four _03 skills is raised to 4 by the training
function TestInquisitionT4TrainingGrant:test_a_tier_3_pilot_with_the_four_tier_3_skills_is_raised_to_tier_4_by_the_first_purchase()
	local player = pilot({}, COST, { pilotTier = 3 })

	J4.talk(player, { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the first purchase")
end

-- AC-10 (the whole talk): menu, topic, opening, route, grant of the mission
function TestInquisitionT4TrainingGrant:test_the_whole_talk_buys_a_skill_and_walks_into_the_first_mission()
	local grants = J4.recordGrants()
	local spies = J4.spyStarts()
	local player = pilot({})
	local t = J4.talk(player, { TRAIN[2].reply, "s_b3a26c61", "s_898acaac", "s_14c99313", "s_2732abfa" })

	lu.assertEquals(J4.ids(t), { "ready_train", "m1_brief_trained", "m1_eager", "m1_task", "m1_forbidden", "m1_accept_stay" }, "screens shown")
	lu.assertEquals(grants, { { skill = TRAIN[2].skill, deduct = true } }, "grantSpaceSkill calls")
	lu.assertEquals(J4.started(spies), { J4.M1[1] }, "the mission started once")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_tier4_1:attempted"), "1", "attempted key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10, I-10: all 24 orders: the topics offered are exactly the missing skills whatever the order of earlier choices
function TestInquisitionT4TrainingGrant:test_all_24_orders_of_choice_offer_exactly_the_missing_skills_and_end_with_all_four_and_tier_5()
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

			local player = pilot(have, 2 * COST)
			local t = J4.talk(player, { TRAIN[choice].reply })

			lu.assertEquals(J4.optionSids(t[1]), want, label .. ", step " .. step .. ": the menu offers exactly the missing skills")
			lu.assertEquals(t[2].id, BRIEFS[step].id, label .. ", step " .. step .. ": the opening of mission " .. step)
			lu.assertEquals(exp(player), COST, label .. ", step " .. step .. ": 1,000,000 XP charged")
			lu.assertTrue(CreatureObject(player):hasSkill(TRAIN[choice].skill), label .. ", step " .. step .. ": the pilot holds the chosen skill")
			have[#have + 1] = choice

			if step == 4 then
				lu.assertEquals(player.ghost.pilotTier, 5, label .. ": pilot tier 5 after the fourth skill")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- The guards (I-10)
---------------------------------------------------------------------------------------------

TestInquisitionT4TrainingGuards = {}

TestInquisitionT4TrainingGuards.setUp = setUp
TestInquisitionT4TrainingGuards.tearDown = tearDown

-- AC-10: below the XP the choice grants nothing and routes by the gates
function TestInquisitionT4TrainingGuards:test_a_choice_below_1000000_xp_grants_nothing_and_routes_by_the_gates()
	local grants = J4.recordGrants()
	local player = pilot({}, COST - 1)
	local t = J4.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "tier4_incomplete", "routed by the gates: under the XP, the duty menu screen")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#J4.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST - 1, "XP unchanged")
end

-- AC-10: a ready mission (a skill waiting for its mission) blocks the choice
function TestInquisitionT4TrainingGuards:test_a_choice_while_a_skill_waits_for_its_mission_grants_nothing_and_routes_to_ready()
	local grants = J4.recordGrants()
	local player = pilot({}, 3 * COST, { t4 = { 1 } })
	local t = J4.drive(player, "ready_train", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "ready", "routed by the gates: the ready prompt")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(J4.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
end

-- AC-10: tier 3 not complete blocks the choice
function TestInquisitionT4TrainingGuards:test_a_choice_without_the_tier_3_skills_grants_nothing()
	local grants = J4.recordGrants()
	local player = pilot({}, 2 * COST, { t3 = 3 })
	local t = J4.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "not_ready", "routed by the gates")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the "skill already held" guard, isolated. Every other guard is true: mission 1 paid, the XP enough, no ready mission, tier 3 done, tier 4 open,
-- the skill manager says yes. The weapons skill is granted while the menu is shown, then its topic is chosen by index.
function TestInquisitionT4TrainingGuards:test_a_skill_already_held_is_not_granted_again_and_the_screen_is_the_gates_not_an_opening()
	local grants = J4.recordGrants()
	local player = J4.pilot({ paid = { 1 }, xp = 3 * COST, met = true })
	local t = J4.talk(player, { function(p) p.skills[TRAIN[2].skill] = true end, 1 })

	lu.assertEquals(t[1].id, "ready_train", "the menu was shown")
	lu.assertEquals(J4.optionSids(t[1]), { "s_d8355c02", "s_96a0374a", "s_d8efd03b", "s_7e1308bc" }, "the weapons topic was on the menu (index 1)")
	lu.assertEquals(#t, 2, "one more screen")
	lu.assertEquals(t[2].id, "ready_train", "the screen is getInitialScreen's (the menu again), not an opening")
	lu.assertEquals(J4.optionSids(t[2]), { "s_d8355c02", "s_d8efd03b", "s_7e1308bc" }, "the weapons topic is gone from the new menu")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[2].id, b.id, "not " .. b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
	lu.assertEquals(J4.held(player), { TRAIN[2].skill }, "_04 skills held (the hook's one)")
end

-- AC-10: each skill held meanwhile is refused in turn
function TestInquisitionT4TrainingGuards:test_each_skill_held_meanwhile_is_refused_in_turn()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local grants = J4.recordGrants()
		local player = J4.pilot({ paid = { 1 }, xp = 3 * COST, met = true })

		J4.talk(player, { function(p) p.skills[x.skill] = true end, i - 1 })
		lu.assertEquals(grants, {}, x.x .. ": grantSpaceSkill calls")
		lu.assertEquals(exp(player), 3 * COST, x.x .. ": XP unchanged")
		J4.restore()
	end
end

-- AC-10: the skill manager says no (prerequisites or XP): nothing is granted
function TestInquisitionT4TrainingGuards:test_a_failing_prerequisite_and_xp_check_grants_nothing()
	local grants = J4.recordGrants()
	local orig = LuaSkillManager

	LuaSkillManager = function()
		local manager = orig()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = manager })
	end

	local player = pilot({}, 2 * COST)
	local ok, t = pcall(J4.drive, player, "ready_train", { TRAIN[1].reply })

	LuaSkillManager = orig
	lu.assertTrue(ok, "no Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "ready_train", "the gates' screen, not an opening")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#J4.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the purchase fails in the engine (costs more than the pilot has): the skill is not held, so no opening is shown
function TestInquisitionT4TrainingGuards:test_a_purchase_the_engine_refuses_shows_the_gates_screen_not_an_opening()
	local costs = J4.useSkillCosts()

	costs[TRAIN[1].skill] = 2 * COST

	local player = pilot({}, COST)
	local t = J4.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(#J4.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "XP unchanged")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[#t].id, b.id, "no " .. b.id .. " for a skill that was not bought")
	end
end

-- AC-10: a reply on another screen is routed by the default handler, whatever its text
function TestInquisitionT4TrainingGuards:test_a_topic_reply_text_on_another_screen_grants_nothing()
	local grants = J4.recordGrants()
	local player = pilot({}, 2 * COST)

	J4.drive(player, "ready", { "s_52917b0d" })
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end
