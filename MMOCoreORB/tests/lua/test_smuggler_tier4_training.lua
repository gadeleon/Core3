-- Nirame Sakute: one-click, free-choice tier 4 training bought with 1,000,000 XP (FN-1, D-3, D-6, I-10).
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-10; Conversation flow 2 (C-1) and 4; FN-1, FN-2; D-3, D-6, D-10; I-10).
--
-- The menu `ready_train` lists one topic reply per missing _04 skill, in table order (starships, weapons, procedures, droid). The skill is bought through
-- SpaceHelpers:grantSpaceSkill(player, skill, true) in getNextConversationScreen when the last screen was ready_train and the chosen reply is a topic. The fake
-- charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_neutral_04.tab (1,000,000 each). Guards are tested through hooks:
-- functions between two choices that change the pilot while the menu is shown. Mission 1 shows the chosen skill's own answer screen (m1_trained_<skill>).

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local CS = require("harness.client_strings")

N.load()

local TRAIN = N.TRAIN
local COST = N.XP_COST

local function setUp()
	H.reset()
	N.requireConversation(lu)
	N.useSkillCosts()
end

local function tearDown() N.restore() end

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

	return N.pilot(o)
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

-- every order of the four skills (24)
local function permutations()
	local out = {}

	local function walk(prefix, rest)
		if #rest == 0 then
			out[#out + 1] = prefix
			return
		end

		for i = 1, #rest do
			local p, r = {}, {}

			for _, v in ipairs(prefix) do
				p[#p + 1] = v
			end

			p[#p + 1] = rest[i]

			for k, v in ipairs(rest) do
				if k ~= i then
					r[#r + 1] = v
				end
			end

			walk(p, r)
		end
	end

	walk({}, { 1, 2, 3, 4 })

	return out
end

-- The screen shown after the purchase when mission n is next, for the skill i (D-6): mission 1 the skill's own answer, then the post-training openings
local function trainedScreen(n, i)
	if n == 1 then
		return TRAIN[i].trained
	end

	return N.TRAINED_BRIEFS[n]
end

local TRAINED_SID = { m1_trained_starships = "s_bdae1e2f", m1_trained_weapons = "s_c40a86d2", m1_trained_procedures = "s_e3cee4d9", m1_trained_droid = "s_b00344d",
	m2_brief_trained = "s_10c507d9", m3_brief = "s_50335ae8", m4_brief_trained = "s_1bfa482b" }

---------------------------------------------------------------------------------------------
-- The menu (C-1)
---------------------------------------------------------------------------------------------

TestSmugglerT4TrainingMenu = {}

TestSmugglerT4TrainingMenu.setUp = setUp
TestSmugglerT4TrainingMenu.tearDown = tearDown

-- AC-10, FN-1: a pilot with the XP and no skill gets the menu of four topics
function TestSmugglerT4TrainingMenu:test_a_pilot_with_the_xp_gets_a_menu_of_four_topics_in_table_order()
	local t = N.talk(pilot({}))

	lu.assertEquals(N.ids(t), { "ready_train" }, "screens shown")
	lu.assertEquals(t[1].text, N.PREFIX .. "s_9a63e564", "the menu line")
	lu.assertEquals(N.optionSids(t[1]), { "s_842279cd", "s_dbb3b0b0", "s_ee28691a", "s_71d852f5" }, "menu replies, in table order")
	lu.assertEquals(N.linksOf(t[1]), { "m1_trained_starships", "m1_trained_weapons", "m1_trained_procedures", "m1_trained_droid" }, "the static link of each topic is its answer screen")
	lu.assertFalse(t[1].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the menu lists exactly the missing skills, in table order
function TestSmugglerT4TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, label = {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
		end

		local t = N.talk(pilot(have))

		lu.assertEquals(N.ids(t), { "ready_train" }, label .. ": screens shown")
		lu.assertEquals(N.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertFalse(t[1].stop, label .. ": the menu waits")
	end
end

-- AC-10, C-1: with no skill left the screen ends (unreachable through the gates)
function TestSmugglerT4TrainingMenu:test_with_every_skill_held_the_menu_has_no_option_and_ends()
	local t = N.drive(pilot({ 1, 2, 3, 4 }), "ready_train")

	lu.assertEquals(N.optionSids(t[1]), {}, "replies")
	lu.assertTrue(t[1].stop, "the screen ends the conversation")
end

-- AC-10: showing the menu or a post-training screen alone grants nothing
function TestSmugglerT4TrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local grants = N.recordGrants()
	local player = pilot({})

	N.talk(player)

	for _, id in ipairs({ "m1_trained_starships", "m1_trained_weapons", "m1_trained_procedures", "m1_trained_droid", "m2_brief_trained", "m3_brief", "m4_brief_trained" }) do
		N.drive(player, id)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#N.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestSmugglerT4TrainingGrant = {}

TestSmugglerT4TrainingGrant.setUp = setUp
TestSmugglerT4TrainingGrant.tearDown = tearDown

-- AC-10, FN-1, D-3, D-6: the topic buys the skill (1,000,000 XP) and shows the answer of mission 1 (the skill's own) or the opening of the next mission, for all 16 combinations
for n = 1, 4 do
	for i, x in ipairs(TRAIN) do
		local shown = trainedScreen(n, i)

		TestSmugglerT4TrainingGrant["test_choosing_" .. x.x .. "_before_mission_" .. n .. "_buys_the_skill_charges_1000000_xp_and_shows_" .. shown] = function()
			local grants = N.recordGrants()
			local player = pilot(others(n - 1, i), COST + 500000)
			local before = #N.held(player)
			local t = N.talk(player, { x.reply })

			lu.assertEquals(N.ids(t), { "ready_train", shown }, "screens shown")
			lu.assertEquals(t[2].text, N.PREFIX .. TRAINED_SID[shown], shown .. ": the post-training line")
			lu.assertFalse(t[2].stop, shown .. " continues into the briefing")
			lu.assertEquals(grants, { { skill = x.skill, deduct = true } }, "grantSpaceSkill(player, skill, true) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#N.held(player), before + 1, "_04 skills held")
			lu.assertEquals(exp(player), 500000, "space XP after the purchase (1,000,000 charged)")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 1, "XP-charging grants")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free grants (every tier 4 skill is bought)")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-10, I-10: one skill per mission: after the grant the talk shows the ready prompt of the next mission, never the menu
function TestSmugglerT4TrainingGrant:test_after_a_grant_the_next_talk_is_the_ready_prompt_and_the_menu_is_gone_until_the_mission_is_won()
	local player = pilot({}, 2 * COST)

	N.talk(player, { TRAIN[1].reply })
	lu.assertEquals(exp(player), COST, "XP left")
	lu.assertEquals(N.firstScreen(player), "ready", "the skill waits for mission 1")

	-- mission 1 accepted and running
	N.setMission(player, 1, "active")
	lu.assertEquals(N.firstScreen(player), "busy", "mission 1 running")

	-- mission 1 won and paid: the menu is back (1,000,000 XP left)
	N.setMission(player, 1, "paid")
	lu.assertEquals(N.firstScreen(player), "ready_train", "mission 1 won and paid, 1,000,000 XP left")
end

-- AC-10, I-10: a second choice before the mission is done grants nothing
function TestSmugglerT4TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = N.recordGrants()
	local player = pilot({}, 3 * COST)

	N.drive(player, "ready_train", { TRAIN[1].reply })
	N.drive(player, "ready_train", { TRAIN[2].reply })
	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(N.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "only one purchase charged")
end

-- AC-10, I-10: all 24 orders: the menu shows exactly the missing skills in table order whatever was chosen before, one purchase per mission
function TestSmugglerT4TrainingGrant:test_all_24_orders_of_choices_work_and_each_costs_1000000_xp()
	for _, order in ipairs(permutations()) do
		H.reset()
		N.restore()
		setUp()

		local label = "order " .. table.concat(order, ",")
		local grants = N.recordGrants()
		local player = N.pilot({ xp = 4 * COST, met = true })
		local have = {}

		for k, i in ipairs(order) do
			local want = {}

			for _, m in ipairs(missing(have)) do
				want[#want + 1] = TRAIN[m].reply
			end

			local t = N.talk(player)

			lu.assertEquals(N.ids(t), { "ready_train" }, label .. ", step " .. k .. ": the menu")
			lu.assertEquals(N.optionSids(t[1]), want, label .. ", step " .. k .. ": the topics are exactly the missing skills")

			t = N.talk(player, { TRAIN[i].reply })
			lu.assertEquals(N.ids(t), { "ready_train", trainedScreen(k, i) }, label .. ", step " .. k .. ": the screens after choosing " .. TRAIN[i].x)
			have[#have + 1] = i
			lu.assertEquals(#N.held(player), k, label .. ", step " .. k .. ": skills held (the count equals the next mission number)")
			lu.assertEquals(exp(player), (4 - k) * COST, label .. ", step " .. k .. ": XP")
			lu.assertEquals(N.firstScreen(player), "ready", label .. ", step " .. k .. ": no menu until the mission is won")
			N.setMission(player, k, "paid")
		end

		lu.assertEquals(#grants, 4, label .. ": grantSpaceSkill calls")
		lu.assertEquals(player.ghost.pilotTier, 5, label .. ": pilot tier after the fourth skill")
		lu.assertEquals(exp(player), 0, label .. ": XP left")
	end
end

-- AC-10, D-10: the fourth skill raises pilot tier 4 to 5, and only then
function TestSmugglerT4TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_4_to_5()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = pilot(others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 4, "precondition: pilot tier 4")
		N.talk(player, { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 5, x.x .. " as the fourth skill: pilot tier")
	end
end

-- AC-10: the first three skills leave the tier alone
function TestSmugglerT4TrainingGrant:test_the_first_three_skills_do_not_raise_the_pilot_tier()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(others(n - 1, 4))

		N.talk(player, { TRAIN[4].reply })
		lu.assertEquals(player.ghost.pilotTier, 4, "skill " .. n .. ": pilot tier")
	end
end

-- AC-10, D-10: a pilot still at tier 3 (Beissa's raise missed) is raised to 4 by the purchase
function TestSmugglerT4TrainingGrant:test_a_pilot_at_tier_3_is_raised_to_4_by_the_purchase()
	local player = pilot({}, COST, { pilotTier = 3 })

	N.talk(player, { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the first skill")
end

-- AC-10: the fourth skill of a pilot whose four missions are all won has no mission to show: the gates decide
function TestSmugglerT4TrainingGrant:test_the_fourth_skill_with_every_mission_won_shows_the_gates_screen()
	local grants = N.recordGrants()
	local player = N.pilot({ t4 = { 1, 2, 3 }, paid = { 1, 2, 3, 4 }, xp = COST, met = true })
	local t = N.talk(player, { TRAIN[4].reply })

	lu.assertEquals(grants, { { skill = TRAIN[4].skill, deduct = true } }, "the skill is bought")
	lu.assertEquals(N.ids(t), { "ready_train", "transfer" }, "no next mission: getInitialScreen (a graduate without the master skill)")
	lu.assertEquals(player.ghost.pilotTier, 5, "pilot tier")
end

-- AC-10 (the whole talk): menu, topic, answer, the brief's route, grant of the mission
function TestSmugglerT4TrainingGrant:test_the_whole_talk_buys_a_skill_and_walks_into_the_first_mission()
	local grants = N.recordGrants()
	local spies = N.spyStarts()
	local player = pilot({})
	local walk = { TRAIN[2].reply }

	for _, sid in ipairs(N.GRANT_PATHS.m1_accept_a[2]) do
		walk[#walk + 1] = sid
	end

	local t = N.talk(player, walk)

	lu.assertEquals(t[1].id, "ready_train", "the menu")
	lu.assertEquals(t[2].id, "m1_trained_weapons", "the answer")
	lu.assertEquals(t[#t].id, "m1_accept_a", "the grant")
	lu.assertEquals(grants, { { skill = TRAIN[2].skill, deduct = true } }, "grantSpaceSkill calls")
	lu.assertEquals(N.started(spies), { N.MISSIONS[1].head }, "the mission started once")
	lu.assertEquals(H.getQuestStatus(player, N.MISSIONS[1].status .. ":attempted"), "1", "attempted key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the post-training openings of missions 2 and 4 lead to a grant of their mission
function TestSmugglerT4TrainingGrant:test_the_trained_openings_of_missions_2_and_4_walk_into_their_missions()
	local cases = {
		{ n = 2, have = { 1 }, skill = 2, replies = { "s_908cfde5", "s_85c8a240", "s_4bef9ff9" }, grant = "m2_accept" },
		{ n = 4, have = { 1, 2, 3 }, skill = 4, replies = { "s_2836e6b5", "s_4f268deb", "s_877810f1", "s_da3439a6", "s_4ca03ddb", "s_30860224" }, grant = "m4_accept_b" },
	}

	for _, c in ipairs(cases) do
		H.reset()
		setUp()

		local spies = N.spyStarts()
		local walk = { TRAIN[c.skill].reply }

		for _, sid in ipairs(c.replies) do
			walk[#walk + 1] = sid
		end

		local t = N.talk(pilot(c.have), walk)

		lu.assertEquals(t[2].id, N.TRAINED_BRIEFS[c.n], "mission " .. c.n .. ": the opening")
		lu.assertEquals(t[#t].id, c.grant, "mission " .. c.n .. ": the grant reached from the opening")
		lu.assertEquals(N.started(spies), { N.MISSIONS[c.n].head }, "mission " .. c.n .. ": started")
	end
end

---------------------------------------------------------------------------------------------
-- The guards (I-10)
---------------------------------------------------------------------------------------------

TestSmugglerT4TrainingGuards = {}

TestSmugglerT4TrainingGuards.setUp = setUp
TestSmugglerT4TrainingGuards.tearDown = tearDown

-- AC-10: below the XP the choice grants nothing and routes by the gates
function TestSmugglerT4TrainingGuards:test_a_choice_below_1000000_xp_grants_nothing_and_routes_by_the_gates()
	local grants = N.recordGrants()
	local player = pilot({}, COST - 1)
	local t = N.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "tier4_incomplete", "routed by the gates: under the XP, the duty menu screen")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#N.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST - 1, "XP unchanged")
end

-- AC-10: a ready mission (a skill waiting for its mission) blocks the choice
function TestSmugglerT4TrainingGuards:test_a_choice_while_a_skill_waits_for_its_mission_grants_nothing_and_routes_to_ready()
	local grants = N.recordGrants()
	local player = pilot({}, 3 * COST, { t4 = { 1 } })
	local t = N.drive(player, "ready_train", { TRAIN[2].reply })

	lu.assertEquals(t[#t].id, "ready", "routed by the gates: the ready prompt")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(N.held(player), { TRAIN[1].skill }, "_04 skills held")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
end

-- AC-10: tier 3 not complete blocks the choice
function TestSmugglerT4TrainingGuards:test_a_choice_without_the_tier_3_skills_grants_nothing()
	local grants = N.recordGrants()
	local player = pilot({}, 2 * COST, { t3 = { 1, 2, 3 } })
	local t = N.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(t[#t].id, "not_ready", "routed by the gates")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the "skill already held" guard, isolated. Every other guard is true: mission 1 paid, the XP enough, no ready mission, tier 3 done, tier 4 open, the skill
-- manager says yes. The weapons skill is granted while the menu is shown, then its topic is chosen through its reply text.
function TestSmugglerT4TrainingGuards:test_a_skill_already_held_is_not_granted_again_and_the_screen_is_the_gates_not_a_brief()
	local grants = N.recordGrants()
	local player = N.pilot({ paid = { 1 }, xp = 3 * COST, met = true })
	local t = N.talk(player, { function(p) p.skills[TRAIN[2].skill] = true end, 1 })

	lu.assertEquals(t[1].id, "ready_train", "the menu was shown")
	lu.assertEquals(N.optionSids(t[1]), { "s_842279cd", "s_dbb3b0b0", "s_ee28691a", "s_71d852f5" }, "the weapons topic was on the menu (index 1)")
	lu.assertEquals(#t, 2, "one more screen")
	lu.assertEquals(t[2].id, "ready_train", "the screen is getInitialScreen's (the menu again), not an answer or a brief")
	lu.assertEquals(N.optionSids(t[2]), { "s_842279cd", "s_ee28691a", "s_71d852f5" }, "the weapons topic is gone from the new menu")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
	lu.assertEquals(exp(player), 3 * COST, "XP unchanged")
	lu.assertEquals(N.held(player), { TRAIN[2].skill }, "_04 skills held (the hook's one)")
end

-- AC-10: the same for every skill
function TestSmugglerT4TrainingGuards:test_each_skill_held_meanwhile_is_refused_in_turn()
	for i, x in ipairs(TRAIN) do
		H.reset()
		N.restore()
		setUp()

		local grants = N.recordGrants()
		local player = N.pilot({ paid = { 1 }, xp = 3 * COST, met = true })
		local t = N.talk(player, { function(p) p.skills[x.skill] = true end, i - 1 })

		lu.assertEquals(grants, {}, x.x .. ": grantSpaceSkill calls")
		lu.assertEquals(t[#t].id, "ready_train", x.x .. ": the gates' screen")
		lu.assertEquals(exp(player), 3 * COST, x.x .. ": XP unchanged")
	end
end

-- AC-10: the skill manager says no (prerequisites or XP): nothing is granted
function TestSmugglerT4TrainingGuards:test_a_failing_prerequisite_and_xp_check_grants_nothing()
	local grants = N.recordGrants()
	local orig = LuaSkillManager

	LuaSkillManager = function()
		local manager = orig()

		return setmetatable({ fulfillsSkillPrerequisitesAndXp = function() return false end }, { __index = manager })
	end

	local player = pilot({}, 2 * COST)
	local ok, t = pcall(N.drive, player, "ready_train", { TRAIN[1].reply })

	LuaSkillManager = orig
	lu.assertTrue(ok, "no Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "ready_train", "the gates' screen, not an answer")
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#N.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end

-- AC-10: the purchase fails in the engine (costs more than the pilot has): the skill is not held, so no answer is shown
function TestSmugglerT4TrainingGuards:test_a_purchase_the_engine_refuses_shows_the_gates_screen_not_an_answer()
	local costs = N.useSkillCosts()

	costs[TRAIN[1].skill] = 2 * COST

	local player = pilot({}, COST)
	local t = N.drive(player, "ready_train", { TRAIN[1].reply })

	lu.assertEquals(#N.held(player), 0, "_04 skills held")
	lu.assertEquals(exp(player), COST, "XP unchanged")
	lu.assertEquals(t[#t].id, "ready_train", "no answer for a skill that was not bought: the gates' screen")
end

-- AC-10: an answer or opening reached from another screen never grants
function TestSmugglerT4TrainingGuards:test_a_trained_screen_shown_alone_grants_nothing()
	local grants = N.recordGrants()
	local player = pilot({})

	for _, id in ipairs({ "m1_trained_starships", "m2_brief_trained", "m4_brief_trained" }) do
		local t = N.drive(player, id)

		lu.assertFalse(t[1].stop, id .. ": waits for a reply")
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
end

-- AC-10: a reply on another screen is routed by the default handler, whatever its text
function TestSmugglerT4TrainingGuards:test_a_topic_reply_text_on_another_screen_grants_nothing()
	local grants = N.recordGrants()
	local player = pilot({ 1 }, 2 * COST)

	N.drive(player, "ready", { "s_8be640b8" })
	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(exp(player), 2 * COST, "XP unchanged")
end
