-- Nin Gursawe: one-click, free-choice tier 4 training bought with 1,000,000 XP (FN-1, D-3, I-10).
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-10; Conversation flow 2 (C-1) and 3; FN-1, FN-2; D-3, D-11; I-10).
--
-- The menu `ready_train` lists one topic reply per missing _04 skill, in table order (starships, weapons, procedures, droid). The skill is bought
-- through SpaceHelpers:grantSpaceSkill(player, skill, true) in getNextConversationScreen when the last screen was ready_train and the chosen reply
-- is a topic. The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_04.tab (1,000,000
-- each). Guards are tested through hooks: functions between two choices that change the pilot while the menu is shown.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")

T.load()

local TRAIN = T.TRAIN
local COST = T.TRAIN_COST

local function setUp()
	H.reset()
	T.requireConversation(lu)
	T.useSkillCosts()
end

local function tearDown() T.restore() end

local function exp(player) return player.ghost.experience.space_combat_general end

-- a pilot with the skills `have` (TRAIN indexes), their missions won and paid, `xp` XP, past the intro and the briefing
local function pilot(have, xp, extra)
	local paid = {}

	for i = 1, #have do
		paid[i] = i
	end

	local o = { t4 = have, paid = paid, xp = xp or COST, keys = { intro = true, met = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
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

-- the post-training brief of mission n and its client line
local BRIEFS = {
	{ id = "m1_brief_trained", sid = "s_e3a57b46" },
	{ id = "m2_brief_trained", sid = "s_8ba804b8" },
	{ id = "m3_brief", sid = "s_4faccfdf" },
	{ id = "m4_brief_trained", sid = "s_4c99c2f5" },
}

---------------------------------------------------------------------------------------------
-- The menu (C-1)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4TrainingMenu = {}

TestBlackEpsilonT4TrainingMenu.setUp = setUp
TestBlackEpsilonT4TrainingMenu.tearDown = tearDown

-- AC-10, FN-1: a pilot with the XP and no skill gets the menu of four topics
function TestBlackEpsilonT4TrainingMenu:test_a_pilot_with_the_xp_gets_a_menu_of_four_topics_in_table_order()
	local t = T.talk(pilot({}))

	lu.assertEquals(T.ids(t), { "ready_train" }, "screens shown")
	lu.assertEquals(t[1].text, T.PREFIX .. "s_2afc3f27", "the menu line")
	lu.assertEquals(T.optionSids(t[1]), { "s_c17d1a82", "s_6560cc1a", "s_bfe54df0", "s_588da3c3" }, "menu replies, in table order")
	lu.assertEquals(T.linksOf(t[1]), { "m1_brief_trained", "m1_brief_trained", "m1_brief_trained", "m1_brief_trained" }, "static default links (the grant routes by reply text)")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the menu lists exactly the missing skills, in table order
function TestBlackEpsilonT4TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, label = {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
		end

		local t = T.talk(pilot(have))

		lu.assertEquals(T.ids(t), { "ready_train" }, label .. ": screens shown")
		lu.assertEquals(T.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertFalse(t[1].stop, label .. ": the menu waits")
	end
end

-- AC-10, C-1: with no skill left the screen ends (unreachable through the gates)
function TestBlackEpsilonT4TrainingMenu:test_with_every_skill_held_the_menu_has_no_option_and_ends()
	local t = T.drive(pilot({ 1, 2, 3, 4 }), "ready_train")

	lu.assertEquals(T.optionSids(t[1]), {}, "replies")
	lu.assertTrue(t[1].stop, "the screen ends the conversation")
end

-- AC-10: showing the menu or a post-training brief alone grants nothing
function TestBlackEpsilonT4TrainingMenu:test_showing_the_menu_or_a_brief_alone_grants_nothing()
	local grants = T.recordGrants()
	local player = pilot({})

	T.talk(player)

	for _, b in ipairs(BRIEFS) do
		T.drive(player, b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4TrainingGrant = {}

TestBlackEpsilonT4TrainingGrant.setUp = setUp
TestBlackEpsilonT4TrainingGrant.tearDown = tearDown

-- AC-10, FN-1, D-3: the topic buys the skill (1,000,000 XP) and shows the post-training brief of the first unwon mission, for all four missions
for n = 1, 4 do
	for i, x in ipairs(TRAIN) do
		TestBlackEpsilonT4TrainingGrant["test_choosing_" .. x.x .. "_before_mission_" .. n .. "_buys_the_skill_charges_1000000_xp_and_shows_" .. BRIEFS[n].id] = function()
			local grants = T.recordGrants()
			local player = pilot(others(n - 1, i), COST + 500000)
			local before = #T.held(player)
			local t = T.talk(player, { x.reply })

			lu.assertEquals(T.ids(t), { "ready_train", BRIEFS[n].id }, "screens shown")
			lu.assertEquals(t[2].text, T.PREFIX .. BRIEFS[n].sid, BRIEFS[n].id .. ": the post-training line")
			lu.assertFalse(t[2].stop, BRIEFS[n].id .. " continues into the briefing")
			lu.assertEquals(grants, { { skill = x.skill, deduct = true } }, "grantSpaceSkill(player, skill, true) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#T.held(player), before + 1, "_04 skills held")
			lu.assertEquals(exp(player), 500000, "space XP after the purchase (1,000,000 charged)")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "XP-charging grants")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants (every tier 4 skill is bought)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-10, I-10: one skill per mission: after the grant the talk shows the ready prompt of the next mission, never the menu
function TestBlackEpsilonT4TrainingGrant:test_after_a_grant_the_next_talk_is_the_ready_prompt_and_the_menu_is_gone_until_the_mission_is_won()
	local player = pilot({}, 2 * COST)

	T.talk(player, { TRAIN[1].reply })
	lu.assertEquals(exp(player), COST, "XP left")
	lu.assertEquals(T.firstScreen(player), "ready", "the skill waits for mission 1")

	-- mission 1 accepted and running
	T.setState(player, T.M1[1], "active")
	H.setQuestStatus(player, "corellia_imperial_tier4_1:attempted", 1)
	lu.assertEquals(T.firstScreen(player), "on_mission", "mission 1 running")

	-- mission 1 won and paid: the menu is back (1,000,000 XP left)
	T.setState(player, T.M1[1], "none")

	for _, g in ipairs(T.M1) do
		T.setState(player, g, "complete")
	end

	H.setQuestStatus(player, "corellia_imperial_tier4_1:reward", 1)
	lu.assertEquals(T.firstScreen(player), "ready_train", "mission 1 won and paid, 1,000,000 XP left")
end

-- AC-10, I-10: a second choice before the mission is done grants nothing
function TestBlackEpsilonT4TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = T.recordGrants()
	local player = pilot({}, 3 * COST)

	T.drive(player, "ready_train", { TRAIN[1].reply })
	T.drive(player, "ready_train", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(T.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "only one purchase charged")
end

-- AC-10, D-11: the fourth skill raises pilot tier 4 to 5, and only then
function TestBlackEpsilonT4TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_4_to_5()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = pilot(others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 4, "precondition: pilot tier 4")
		T.talk(player, { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 5, x.x .. " as the fourth skill: pilot tier")
	end
end

-- AC-10: the first three skills leave the tier alone
function TestBlackEpsilonT4TrainingGrant:test_the_first_three_skills_do_not_raise_the_pilot_tier()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(others(n - 1, 4))

		T.talk(player, { TRAIN[4].reply })
		lu.assertEquals(player.ghost.pilotTier, 4, "skill " .. n .. ": pilot tier")
	end
end

-- AC-10 (the whole talk): menu, topic, brief, route, grant of the mission
function TestBlackEpsilonT4TrainingGrant:test_the_whole_talk_buys_a_skill_and_walks_into_the_first_mission()
	local grants = T.recordGrants()
	local spies = T.spyStarts()
	local player = pilot({})
	local t = T.talk(player, { TRAIN[2].reply, "s_a476ea3d", "s_7423a2e5", "s_4d7b8699", "s_9205783d" })

	lu.assertEquals(T.ids(t), { "ready_train", "m1_brief_trained", "s_9ce82616", "s_79bf4ef1", "s_6a902b99", "m1_accept_a" }, "screens shown")
	lu.assertEquals(grants, { { skill = TRAIN[2].skill, deduct = true } }, "grantSpaceSkill calls")
	lu.assertEquals(T.started(spies), { T.M1[1] }, "the mission started once")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_tier4_1:attempted"), "1", "attempted key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

---------------------------------------------------------------------------------------------
-- The guards (I-10)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4TrainingGuards = {}

TestBlackEpsilonT4TrainingGuards.setUp = setUp
TestBlackEpsilonT4TrainingGuards.tearDown = tearDown

-- AC-10: below the XP the choice grants nothing and routes by the gates
function TestBlackEpsilonT4TrainingGuards:test_a_choice_below_1000000_xp_grants_nothing_and_routes_by_the_gates()
	local grants = T.recordGrants()
	local player = pilot({}, COST - 1)
	local t = T.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "tier4_incomplete", "routed by the gates: under the XP, the duty menu screen")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST - 1, "XP unchanged")
end

-- AC-10: a ready mission (a skill waiting for its mission) blocks the choice
function TestBlackEpsilonT4TrainingGuards:test_a_choice_while_a_skill_waits_for_its_mission_grants_nothing_and_routes_to_ready()
	local grants = T.recordGrants()
	local player = pilot({}, 3 * COST, { t4 = { 1 } })
	local t = T.drive(player, "ready_train", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "ready", "routed by the gates: the ready prompt")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(T.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
end

-- AC-10: tier 3 not complete blocks the choice
function TestBlackEpsilonT4TrainingGuards:test_a_choice_without_the_tier_3_skills_grants_nothing()
	local grants = T.recordGrants()
	local player = pilot({}, 2 * COST, { t3 = 3 })
	local t = T.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "not_ready", "routed by the gates")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the "skill already held" guard, isolated. Every other guard is true: mission 1 won and paid, the XP enough, no ready mission, tier 3 done,
-- tier 4 open, the skill manager says yes. The weapons skill is granted while the menu is shown, then its topic is chosen through its reply text.
function TestBlackEpsilonT4TrainingGuards:test_a_skill_already_held_is_not_granted_again_and_the_screen_is_the_gates_not_a_brief()
	local grants = T.recordGrants()
	local player = T.pilot({ paid = { 1 }, xp = 3 * COST, keys = { intro = true, met = true } })
	local t = T.talk(player, { function(p) p.skills[TRAIN[2].skill] = true end, 1 })

	lu.assertEquals(t[1].id, "ready_train", "the menu was shown")
	lu.assertEquals(T.optionSids(t[1]), { "s_c17d1a82", "s_6560cc1a", "s_bfe54df0", "s_588da3c3" }, "the weapons topic was on the menu (index 1)")
	lu.assertEquals(#t, 2, "one more screen")
	lu.assertEquals(t[2].id, "ready_train", "the screen is getInitialScreen's (the menu again), not a brief")
	lu.assertEquals(T.optionSids(t[2]), { "s_c17d1a82", "s_bfe54df0", "s_588da3c3" }, "the weapons topic is gone from the new menu")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[2].id, b.id, "not " .. b.id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
	lu.assertEquals(T.held(player), { TRAIN[2].skill }, "_04 skills held (the hook's one)")
end

-- AC-10: the same, with the held skill chosen by reply sid through the live menu of a stale screen
function TestBlackEpsilonT4TrainingGuards:test_each_skill_held_meanwhile_is_refused_in_turn()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local grants = T.recordGrants()
		local player = T.pilot({ paid = { 1 }, xp = 3 * COST, keys = { intro = true, met = true } })

		-- the pilot holds skill i meanwhile, which also satisfies "the skill of mission 1" (count 1 < next mission 2)
		local t = T.talk(player, { function(p) p.skills[x.skill] = true end, i - 1 })

		lu.assertEquals(grants, {}, x.x .. ": grantSpaceSkill calls")
		lu.assertEquals(t[#t].id, "ready_train", x.x .. ": the gates' screen")
		lu.assertEquals(exp(player), 3 * COST, x.x .. ": XP unchanged")
		T.restore()
	end
end

-- AC-10: the skill manager says no (prerequisites or XP): nothing is granted
function TestBlackEpsilonT4TrainingGuards:test_a_failing_prerequisite_and_xp_check_grants_nothing()
	local grants = T.recordGrants()
	local orig = LuaSkillManager

	LuaSkillManager = function()
		local manager = orig()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = manager })
	end

	local player = pilot({}, 2 * COST)
	local ok, t = pcall(T.drive, player, "ready_train", { TRAIN[1].reply })

	LuaSkillManager = orig
	lu.assertTrue(ok, "no Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "ready_train", "the gates' screen, not a brief")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#T.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the purchase fails in the engine (costs more than the pilot has): the skill is not held, so no brief is shown
function TestBlackEpsilonT4TrainingGuards:test_a_purchase_the_engine_refuses_shows_the_gates_screen_not_a_brief()
	local costs = T.useSkillCosts()

	costs[TRAIN[1].skill] = 2 * COST

	local player = pilot({}, COST)
	local t = T.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(#T.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "XP unchanged")

	for _, b in ipairs(BRIEFS) do
		lu.assertNotEquals(t[#t].id, b.id, "no " .. b.id .. " for a skill that was not bought")
	end
end

-- AC-10: a trained brief reached from another screen never grants
function TestBlackEpsilonT4TrainingGuards:test_a_post_training_brief_shown_alone_grants_nothing()
	local grants = T.recordGrants()
	local player = pilot({})

	for _, b in ipairs(BRIEFS) do
		local t = T.drive(player, b.id)

		lu.assertFalse(t[1].stop, b.id .. ": waits for a reply")
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end

-- AC-10: a reply on another screen is routed by the default handler, whatever its text
function TestBlackEpsilonT4TrainingGuards:test_a_topic_reply_text_on_another_screen_grants_nothing()
	local grants = T.recordGrants()
	local player = pilot({}, 2 * COST)

	T.drive(player, "ready", { "s_36a4e374" })
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end
