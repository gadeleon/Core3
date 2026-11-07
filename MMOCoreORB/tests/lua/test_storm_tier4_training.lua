-- Admiral Kilnstrider: one-click, free-choice tier 4 training bought with 1,000,000 XP (FK-1, D-3, D-10, I-10).
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-7; Conversation flow 2 (C-1) and 4; FK-1, FK-2, FK-3; D-3, D-10; I-10).
--
-- The menu `ready_train` lists one topic reply per missing _04 skill, in table order (starships, weapons, procedures, droid). The skill is bought
-- through SpaceHelpers:grantSpaceSkill(player, skill, true) in getNextConversationScreen when the last screen was ready_train and the chosen reply
-- is a topic; the answer is TRAINED_BRIEFS[getNextMission] (m2_brief_trained for the second skill). The fake charges XP only with
-- H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_04.tab (1,000,000 each). Guards are tested through hooks: functions
-- between two choices that change the pilot while the menu is shown.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")

D.loadConversation()

local TRAIN = D.TRAIN
local COST = D.TRAIN_COST

local function setUp()
	H.reset()
	D.requireConversation(lu)
	D.useSkillCosts()
end

local function tearDown() D.restore() end

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

	return D.pilot(o)
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

-- the screen shown after the purchase of the n-th skill and its client line (FK-2: the second skill shows the twin of the M2 head)
local BRIEFS = {
	{ id = "m1_brief", sid = "s_f10afb8" },
	{ id = "m2_brief_trained", sid = "s_71874e85" },
	{ id = "m3_brief", sid = "s_66bd8046" },
	{ id = "m4_brief", sid = "s_fee3d28f" },
}

---------------------------------------------------------------------------------------------
-- The menu (C-1)
---------------------------------------------------------------------------------------------

TestStormT4TrainingMenu = {}

TestStormT4TrainingMenu.setUp = setUp

-- B-7: a pilot with the XP and no skill gets the menu of four topics
function TestStormT4TrainingMenu:test_a_pilot_with_the_xp_gets_a_menu_of_four_topics_in_table_order()
	local t = D.talk(pilot({}))

	lu.assertEquals(D.ids(t), { "ready_train" }, "screens shown")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_d1e73984", "the menu line")
	lu.assertEquals(D.optionSids(t[1]), { "s_a50d5eb4", "s_2c2ce09e", "s_a5d7d28d", "s_97682588" }, "menu replies, in table order")
	lu.assertEquals(D.linksOf(t[1]), { "m1_brief", "m1_brief", "m1_brief", "m1_brief" }, "the first mission's head for a pilot with none won (C-1)")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-7, C-1: the links lead to the head of the next mission (m2_brief_trained for the second skill)
function TestStormT4TrainingMenu:test_the_menu_links_lead_to_the_opening_of_the_next_unwon_mission()
	for n = 1, 4 do
		local t = D.talk(pilot(others(n - 1, 4)))

		lu.assertEquals(t[1].id, "ready_train", "mission " .. n .. ": the menu")

		for i, link in ipairs(D.linksOf(t[1])) do
			lu.assertEquals(link, BRIEFS[n].id, "mission " .. n .. ": link " .. i)
		end
	end
end

-- B-7: the menu lists exactly the missing skills, in table order
function TestStormT4TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, label = {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
		end

		local t = D.talk(pilot(have))

		lu.assertEquals(D.ids(t), { "ready_train" }, label .. ": screens shown")
		lu.assertEquals(D.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertFalse(t[1].stop, label .. ": the menu waits")
	end
end

-- B-7, C-1: with no skill left the screen ends (unreachable through the gates)
function TestStormT4TrainingMenu:test_with_every_skill_held_the_menu_has_no_option_and_ends()
	local t = D.drive(pilot({ 1, 2, 3, 4 }), "ready_train")

	lu.assertEquals(D.optionSids(t[1]), {}, "replies")
	lu.assertTrue(t[1].stop, "the screen ends the conversation")
end

-- B-7: showing the menu or a trained opening alone grants nothing
function TestStormT4TrainingMenu:test_showing_the_menu_or_a_trained_opening_alone_grants_nothing()
	local grants = D.recordGrants()
	local player = pilot({})

	D.talk(player)

	for _, b in ipairs(BRIEFS) do
		D.drive(player, b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#D.held4(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "no XP charged")
	D.restore()
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestStormT4TrainingGrant = {}

TestStormT4TrainingGrant.setUp = setUp
TestStormT4TrainingGrant.tearDown = tearDown

-- B-7, FK-1, D-3: the topic buys the skill (1,000,000 XP) and shows the opening of the next unwon mission, all four skills as the first choice
-- and all four missions
for n = 1, 4 do
	for i, x in ipairs(TRAIN) do
		TestStormT4TrainingGrant["test_choosing_" .. x.x .. "_before_mission_" .. n .. "_buys_the_skill_charges_1000000_xp_and_shows_" .. BRIEFS[n].id] = function()
			local grants = D.recordGrants()
			local player = pilot(others(n - 1, i), COST + 500000)
			local before = #D.held4(player)
			local t = D.talk(player, { x.reply })

			lu.assertEquals(D.ids(t), { "ready_train", BRIEFS[n].id }, "screens shown")
			lu.assertEquals(t[2].text, D.PREFIX .. BRIEFS[n].sid, BRIEFS[n].id .. ": the opening line")
			lu.assertFalse(t[2].stop, BRIEFS[n].id .. " continues into the briefing")
			lu.assertEquals(grants, { { skill = x.skill, deduct = true } }, "grantSpaceSkill(player, skill, true) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#D.held4(player), before + 1, "_04 skills held")
			lu.assertEquals(exp(player), 500000, "space XP after the purchase (1,000,000 charged)")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "XP-charging grants")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants (every tier 4 skill is bought)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- B-7, FK-2: the second skill shows the twin of the M2 head with the pilot's first name
function TestStormT4TrainingGrant:test_the_second_skill_shows_the_trained_m2_head_with_the_first_name()
	local t = D.talk(pilot({ 1 }), { TRAIN[2].reply })

	lu.assertEquals(t[2].id, "m2_brief_trained", "the opening")
	lu.assertEquals(t[2].params.TU, "Ace", "%NU of s_71874e85")
	lu.assertEquals(D.optionSids(t[2]), { "s_c782ced7", "s_dd2ae025" }, "the replies of the M2 head")
end

-- B-7, I-10: one skill per mission: after the grant the talk shows the ready prompt of the next mission, never the menu
function TestStormT4TrainingGrant:test_after_a_grant_the_next_talk_is_the_ready_prompt_and_the_menu_is_gone_until_the_mission_is_won()
	local player = pilot({}, 2 * COST)

	D.talk(player, { TRAIN[1].reply })
	lu.assertEquals(exp(player), COST, "XP left")
	lu.assertEquals(D.firstScreen(player), "ready", "the skill waits for mission 1")

	-- mission 1 accepted and running
	D.setState(player, D.M1[1], "active")
	H.setQuestStatus(player, D.STATUS[1] .. ":attempted", 1)
	lu.assertEquals(D.firstScreen(player), "on_mission", "mission 1 running")

	-- mission 1 won and paid: the menu is back (1,000,000 XP left)
	D.setState(player, D.M1[1], "none")

	for _, g in ipairs(D.M1) do
		D.setState(player, g, "complete")
	end

	H.setQuestStatus(player, D.STATUS[1] .. ":reward", 1)
	lu.assertEquals(D.firstScreen(player), "ready_train", "mission 1 won and paid, 1,000,000 XP left")
end

-- B-7, I-10: a second choice before the mission is done grants nothing
function TestStormT4TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = D.recordGrants()
	local player = pilot({}, 3 * COST)

	D.drive(player, "ready_train", { TRAIN[1].reply })
	D.drive(player, "ready_train", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(D.held4(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "only one purchase charged")
end

-- B-7, D-10: the fourth skill raises pilot tier 4 to 5, and only then
function TestStormT4TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_4_to_5()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = pilot(others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 4, "precondition: pilot tier 4")
		D.talk(player, { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 5, x.x .. " as the fourth skill: pilot tier")
	end
end

-- B-7: the first three skills leave the tier alone
function TestStormT4TrainingGrant:test_the_first_three_skills_do_not_raise_the_pilot_tier()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(others(n - 1, 4))

		D.talk(player, { TRAIN[4].reply })
		lu.assertEquals(player.ghost.pilotTier, 4, "skill " .. n .. ": pilot tier")
	end
end

-- B-7, D-10: a pilot still at tier 3 with the four _03 skills is raised to 4 by the training
function TestStormT4TrainingGrant:test_a_tier_3_pilot_with_the_four_tier_3_skills_is_raised_to_tier_4_by_the_first_purchase()
	local player = pilot({}, COST, { pilotTier = 3 })

	D.talk(player, { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the first purchase")
end

-- B-7: the training does not set the met key (R-6: a pilot who always had the XP meets Kilnstrider later)
function TestStormT4TrainingGrant:test_the_purchase_does_not_set_the_met_key()
	local player = pilot({}, COST, { met = false })

	lu.assertEquals(D.firstScreen(player), "ready_train", "G17 before G18")
	D.talk(player, { TRAIN[1].reply })
	lu.assertFalse(D.hasKey(player, D.MET_KEY), "the met key")
end

-- B-7 (the whole talk): menu, topic, opening, route, grant of the mission
function TestStormT4TrainingGrant:test_the_whole_talk_buys_a_skill_and_walks_into_the_first_mission()
	local grants = D.recordGrants()
	local spies = D.spyStarts()
	local player = pilot({})
	local t = D.talk(player, { TRAIN[2].reply, "s_9cc5ad7c", "s_ebe5a831", "s_e604f53", "s_adfa15d1", "s_4621ec24" })

	lu.assertEquals(D.ids(t), { "ready_train", "m1_brief", "m1_emperor", "m1_shoot", "m1_exactly", "m1_your_concern", "m1_accept_hope" }, "screens shown")
	lu.assertEquals(grants, { { skill = TRAIN[2].skill, deduct = true } }, "grantSpaceSkill calls")
	lu.assertEquals(D.started(spies), { D.M1[1] }, "the mission started once")
	lu.assertEquals(H.getQuestStatus(player, D.STATUS[1] .. ":attempted"), "1", "attempted key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-7 (the whole talk): the second skill walks the trained head into mission 2
function TestStormT4TrainingGrant:test_the_second_skill_walks_the_trained_head_into_mission_2()
	local spies = D.spyStarts()
	local player = pilot({ 1 }, COST)
	local t = D.talk(player, { TRAIN[3].reply, "s_dd2ae025", "s_b2da1ce2", "s_6a85372e", "s_2c4789b" })

	lu.assertEquals(D.ids(t), { "ready_train", "m2_brief_trained", "m2_listen", "m2_answer", "m2_leaving", "m2_accept_dismissed" }, "screens shown")
	lu.assertEquals(D.started(spies), { D.M2[1] }, "mission 2 started once")
end

-- B-7, I-10: all 24 orders: the topics offered are exactly the missing skills whatever the order of earlier choices
function TestStormT4TrainingGrant:test_all_24_orders_of_choice_offer_exactly_the_missing_skills_and_end_with_all_four_and_tier_5()
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
			local t = D.talk(player, { TRAIN[choice].reply })

			lu.assertEquals(D.optionSids(t[1]), want, label .. ", step " .. step .. ": the menu offers exactly the missing skills")
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

TestStormT4TrainingGuards = {}

TestStormT4TrainingGuards.setUp = setUp
TestStormT4TrainingGuards.tearDown = tearDown

-- B-7: below the XP the choice grants nothing and routes by the gates
function TestStormT4TrainingGuards:test_a_choice_below_1000000_xp_grants_nothing_and_routes_by_the_gates()
	local grants = D.recordGrants()
	local player = pilot({}, COST - 1)
	local t = D.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "tier4_incomplete", "routed by the gates: under the XP, the duty menu screen")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#D.held4(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST - 1, "XP unchanged")
end

-- B-7: a ready mission (a skill waiting for its mission) blocks the choice
function TestStormT4TrainingGuards:test_a_choice_while_a_skill_waits_for_its_mission_grants_nothing_and_routes_to_ready()
	local grants = D.recordGrants()
	local player = pilot({}, 3 * COST, { t4 = { 1 } })
	local t = D.drive(player, "ready_train", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "ready", "routed by the gates: the ready prompt")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(D.held4(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
end

-- B-7: tier 3 not complete blocks the choice
function TestStormT4TrainingGuards:test_a_choice_without_the_tier_3_skills_grants_nothing()
	local grants = D.recordGrants()
	local player = pilot({}, 2 * COST, { t3 = { 1, 2, 3 } })
	local t = D.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "not_ready", "routed by the gates")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- B-7: the "skill already held" guard, isolated. Every other guard is true: mission 1 paid, the XP enough, no ready mission, tier 3 done, tier 4 open,
-- the skill manager says yes. The weapons skill is granted while the menu is shown, then its topic is chosen by index.
function TestStormT4TrainingGuards:test_a_skill_already_held_is_not_granted_again_and_the_screen_is_the_gates_not_an_opening()
	local grants = D.recordGrants()
	local player = D.pilot({ paid = { 1 }, xp = 3 * COST, met = true })
	local t = D.talk(player, { function(p) p.skills[TRAIN[2].skill] = true end, 1 })

	lu.assertEquals(t[1].id, "ready_train", "the menu was shown")
	lu.assertEquals(D.optionSids(t[1]), { "s_a50d5eb4", "s_2c2ce09e", "s_a5d7d28d", "s_97682588" }, "the weapons topic was on the menu (index 1)")
	lu.assertEquals(#t, 2, "one more screen")
	lu.assertEquals(t[2].id, "ready_train", "the screen is getInitialScreen's (the menu again), not an opening")
	lu.assertEquals(D.optionSids(t[2]), { "s_a50d5eb4", "s_a5d7d28d", "s_97682588" }, "the weapons topic is gone from the new menu")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[2].id, b.id, "not " .. b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
	lu.assertEquals(D.held4(player), { TRAIN[2].skill }, "_04 skills held (the hook's one)")
end

-- B-7: each skill held meanwhile is refused in turn
function TestStormT4TrainingGuards:test_each_skill_held_meanwhile_is_refused_in_turn()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local grants = D.recordGrants()
		local player = D.pilot({ paid = { 1 }, xp = 3 * COST, met = true })

		D.talk(player, { function(p) p.skills[x.skill] = true end, i - 1 })
		lu.assertEquals(grants, {}, x.x .. ": grantSpaceSkill calls")
		lu.assertEquals(exp(player), 3 * COST, x.x .. ": XP unchanged")
		D.restore()
	end
end

-- B-7: the skill manager says no (prerequisites or XP): nothing is granted
function TestStormT4TrainingGuards:test_a_failing_prerequisite_and_xp_check_grants_nothing()
	local grants = D.recordGrants()
	local orig = LuaSkillManager

	LuaSkillManager = function()
		local manager = orig()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = manager })
	end

	local player = pilot({}, 2 * COST)
	local ok, t = pcall(D.drive, player, "ready_train", { TRAIN[1].reply })

	LuaSkillManager = orig
	lu.assertTrue(ok, "no Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "ready_train", "the gates' screen, not an opening")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#D.held4(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- B-7: the purchase fails in the engine (costs more than the pilot has): the skill is not held, so no opening is shown
function TestStormT4TrainingGuards:test_a_purchase_the_engine_refuses_shows_the_gates_screen_not_an_opening()
	local costs = D.useSkillCosts()

	costs[TRAIN[1].skill] = 2 * COST

	local player = pilot({}, COST)
	local t = D.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(#D.held4(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "XP unchanged")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[#t].id, b.id, "no " .. b.id .. " for a skill that was not bought")
	end
end

-- B-7: a reply on another screen is routed by the default handler, whatever its text
function TestStormT4TrainingGuards:test_a_topic_reply_text_on_another_screen_grants_nothing()
	local grants = D.recordGrants()
	local player = pilot({}, 2 * COST)

	D.drive(player, "ready", { "s_52917b0d" })
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- B-7: a pilot who has the XP but is grounded never reaches the menu (the wanted gate comes first), so no skill is sold to him
function TestStormT4TrainingGuards:test_a_grounded_pilot_is_not_offered_the_training()
	local grants = D.recordGrants()
	local player = pilot({}, 2 * COST, { standing = -1 })
	local t = D.talk(player)

	lu.assertEquals(D.ids(t), { "wanted" }, "the wanted gate")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end
