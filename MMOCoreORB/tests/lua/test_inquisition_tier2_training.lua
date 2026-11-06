-- Inquisitor Fa'Zoll: one-click, free-choice tier 2 training (FF-1, FF-2, FF-3, D-6, D-7, D-8): a topic reply on `training_menu` buys the skill at once.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-10, AC-11, AC-5, I-10; Conversation flow 1 (F15, F16), 2 (C-4, C-5) and 3.4; FF-1 .. FF-4; D-6, D-7, D-19).
--
-- The menu lists one topic reply per missing tier 2 skill, in table order (starships, weapons, procedures, droid), then "Let me think about this for a bit".
-- The skill is bought through skillManagerAwardSkill (the XP is charged; no tier 2 skill is free) in getNextConversationScreen when the chosen link is a
-- trained screen of training_menu or m4_more_training. Guards are tested through hooks, functions between two choices that change the pilot while a
-- screen is shown. The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_02.tab (60000 each).

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")

I.load()

local TRAIN = I.TRAIN
local COST = I.TRAINING_COST

local function setUp()
	H.reset()
	I.requireConversation(lu)
	I.useSkillCosts()
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function bought(player)
	local out = {}

	for _, call in ipairs(I.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function free(player)
	local out = {}

	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2]:find("^pilot_imperial_navy_%a+_02$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(bought(player), {}, label .. ": bought grants")
	lu.assertEquals(free(player), {}, label .. ": free grants")
end

-- all proper subsets of the four skills (indexes in table order), the empty one included
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

-- a pilot with M1 and M2 paid, the tier 2 skills `have` and `xp`; with skills, M3 is paid too, as the only way to a second skill (FF-3)
local function pilot(have, xp, extra)
	local o = { paid = (#(have or {}) > 0) and 3 or 2, t2 = have or {}, xp = xp or COST }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

-- The replies from the first screen to the menu: the training offer for the first skill, the duty menu once M3 is paid
local function toMenu(have)
	if #have == 0 then
		return { "s_c1bc23b4" }
	end

	return { "s_ac71da57", I.READY_FOR_TRAINING }
end

local function menuIds(have)
	if #have == 0 then
		return { "training_offer", "training_menu" }
	end

	return { "duty_after_m3", "duty_menu", "training_menu" }
end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestInquisitionT2TrainingMenu = {}

TestInquisitionT2TrainingMenu.setUp = setUp

-- AC-10, FF-1: the offer and the menu with the four topics
function TestInquisitionT2TrainingMenu:test_a_pilot_with_no_tier_2_skill_gets_the_offer_and_a_menu_of_four_topics_plus_think_about_it()
	local t = I.talk(pilot({}), toMenu({}))

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu" }, "screens shown")
	lu.assertEquals(t[2].text, I.PREFIX .. I.MENU_LINE, "the menu line")
	lu.assertEquals(I.optionSids(t[2]), { "s_594a07fa", "s_be30f309", "s_e73e5d21", "s_c76594d7", I.LATER }, "menu replies, in table order, then 'Let me think about this'")
	lu.assertEquals(I.linksOf(t[2]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid", "training_later" }, "menu links")
	lu.assertFalse(t[2].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the menu lists exactly the missing skills, in table order, from the offer (no skill) and the duty menu (M3 paid)
function TestInquisitionT2TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].trained
		end

		want[#want + 1] = I.LATER
		links[#links + 1] = "training_later"

		local t = I.talk(pilot(have), toMenu(have))

		lu.assertEquals(I.ids(t), menuIds(have), label .. ": screens shown")
		lu.assertEquals(I.optionSids(t[#t]), want, label .. ": menu replies")
		lu.assertEquals(I.linksOf(t[#t]), links, label .. ": menu links")
	end
end

-- AC-10: "Let me think about this for a bit" ends without a grant
function TestInquisitionT2TrainingMenu:test_think_about_it_ends_the_conversation_without_a_grant()
	local player = pilot({})
	local t = I.talk(player, { "s_c1bc23b4", I.LATER })

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu", "training_later" }, "screens shown")
	lu.assertTrue(t[3].stop, "training_later ends")
	noGrant(player, "think about it")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: showing the menu or a trained screen alone grants nothing
function TestInquisitionT2TrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({})

	I.talk(player, { "s_c1bc23b4" })
	noGrant(player, "menu shown")

	for _, x in ipairs(TRAIN) do
		I.drive(player, x.trained)
		noGrant(player, x.trained .. " displayed alone")
	end

	lu.assertEquals(exp(player), COST, "no XP charged")
end

-- AC-10: without the XP the duty menu's training option says so
function TestInquisitionT2TrainingMenu:test_the_duty_menu_training_option_says_not_ready_without_the_xp()
	local player = pilot({ 1 }, COST - 1)
	local t = I.talk(player, { "s_ac71da57", I.READY_FOR_TRAINING, "s_89bc583c" })

	lu.assertEquals(I.ids(t), { "duty_after_m3", "duty_menu", "training_not_ready", "training_not_ready_report" }, "screens shown")
	lu.assertTrue(t[4].stop, "training_not_ready_report ends")
	lu.assertEquals(t[3].params.TU, "Ace", "training_not_ready: %NU")
	noGrant(player, "not ready")
end

-- AC-10, C-4: the duty menu of an on-track pilot lists the three duties and the training option
function TestInquisitionT2TrainingMenu:test_the_duty_menu_of_an_inquisition_pilot_lists_the_three_duties_and_the_training_option()
	local t = I.talk(pilot({}, 0, { paid = 2 }), { "s_ac71da57" })

	lu.assertEquals(I.ids(t), { "duty_after_m2", "duty_menu" }, "screens shown")
	lu.assertEquals(I.optionSids(t[2]), { "s_e84f3a62", "s_e6765c30", "s_f0a7a4ef", I.READY_FOR_TRAINING }, "duty_menu replies")
	lu.assertEquals(I.linksOf(t[2]), { "duty_police", "duty_escort", "duty_insurgents", "training_not_ready" }, "duty_menu links without the XP")
end

-- AC-10, C-4: after M3 the duty menu links the menu when ready
function TestInquisitionT2TrainingMenu:test_the_duty_menu_links_the_training_menu_when_the_pilot_is_ready()
	local t = I.talk(pilot({ 1 }, COST), { "s_ac71da57" })

	lu.assertEquals(I.linksOf(t[2]), { "duty_police", "duty_escort", "duty_insurgents", "training_menu" }, "duty_menu links with the XP and M3 paid")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestInquisitionT2TrainingGrant = {}

TestInquisitionT2TrainingGrant.setUp = setUp

-- AC-10, FF-1, FF-2: the topic buys the skill, charges 60000 XP and shows the trained line, which leads to the report line
for _, x in ipairs(TRAIN) do
	TestInquisitionT2TrainingGrant["test_choosing_" .. x.x .. "_buys_the_skill_charges_the_xp_and_shows_" .. x.trained] = function()
		local player = pilot({})
		local t = I.talk(player, { "s_c1bc23b4", x.reply, I.THANK_YOU })

		lu.assertEquals(I.ids(t), { "training_offer", "training_menu", x.trained, "trained_report" }, "screens shown")
		lu.assertEquals(t[3].text, I.PREFIX .. x.trainedSid, x.trained .. ": the topic description")
		lu.assertEquals(I.optionSids(t[3]), { I.THANK_YOU }, x.trained .. ": the one reply")
		lu.assertEquals(t[4].text, I.PREFIX .. "s_8e4bd7c1", "the closing line")
		lu.assertTrue(t[4].stop, "trained_report ends the conversation")
		lu.assertEquals(bought(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(free(player), {}, "free grants (every tier 2 skill is bought)")
		lu.assertEquals(I.held(player), { x.skill }, "tier 2 skills held")
		lu.assertEquals(exp(player), 0, "space XP after the purchase")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-10: after the first skill the next talk opens the mission 3 offer, not the training offer
function TestInquisitionT2TrainingGrant:test_the_next_talk_after_the_first_purchase_opens_m3_offer()
	for _, x in ipairs(TRAIN) do
		H.reset()
		I.useSkillCosts()

		local player = pilot({}, 3 * COST)

		I.talk(player, { "s_c1bc23b4", x.reply })
		lu.assertEquals(I.firstScreen(player), "m3_offer", x.x .. ": the next talk")
		lu.assertEquals(#bought(player), 1, x.x .. ": no second skill bought")
	end
end

-- AC-10: each skill is charged 60000 whatever is held
function TestInquisitionT2TrainingGrant:test_each_purchase_charges_60000_xp_from_the_pilots_balance()
	for _, have in ipairs({ {}, { 1 }, { 2, 3 }, { 1, 3, 4 } }) do
		for _, i in ipairs(missing(have)) do
			H.reset()
			I.useSkillCosts()

			local player = pilot(have, 150000)
			local path = toMenu(have)

			path[#path + 1] = TRAIN[i].reply

			local t = I.talk(player, path)

			lu.assertEquals(t[#t].id, TRAIN[i].trained, "holding " .. table.concat(have, ",") .. " buying " .. TRAIN[i].x .. ": last screen")
			lu.assertEquals(bought(player), { TRAIN[i].skill }, "skillManagerAwardSkill calls")
			lu.assertEquals(exp(player), 150000 - COST, "space XP after the purchase")
			lu.assertTrue(CreatureObject(player):hasSkill(TRAIN[i].skill), "the skill is held")
		end
	end
end

-- AC-10: one reply buys one skill
function TestInquisitionT2TrainingGrant:test_one_choice_buys_exactly_one_skill()
	local player = pilot({}, 3 * COST)

	I.talk(player, { "s_c1bc23b4", "s_be30f309" })
	lu.assertEquals(bought(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-10, D-6: the fourth skill raises the pilot tier 2 to 3, and only then
function TestInquisitionT2TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_2_to_3()
	local player = pilot({ 1, 2, 3 })

	lu.assertEquals(player.ghost.pilotTier, 2, "precondition: pilot tier 2")

	local path = toMenu({ 1, 2, 3 })

	path[#path + 1] = "s_c76594d7"
	I.talk(player, path)
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the fourth skill")
	lu.assertEquals(I.firstScreen(player), "m4_offer", "the next talk offers mission 4 (all four skills, M3 paid)")
end

-- AC-10
function TestInquisitionT2TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	local player = pilot({ 1, 2 })
	local path = toMenu({ 1, 2 })

	path[#path + 1] = "s_e73e5d21"
	I.talk(player, path)
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the third skill")
end

-- AC-10: a pilot already at tier 3 keeps it
function TestInquisitionT2TrainingGrant:test_a_pilot_at_tier_3_is_not_raised_again()
	local player = pilot({ 1, 2, 3 }, COST, { pilotTier = 3 })
	local path = toMenu({ 1, 2, 3 })

	path[#path + 1] = "s_c76594d7"
	I.talk(player, path)
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
end

-- AC-10, FF-3: the four skills over four visits, M3 flown and paid after the first
function TestInquisitionT2TrainingGrant:test_the_four_skills_can_be_trained_in_a_reversed_order_over_four_visits()
	local player = pilot({}, 4 * COST)
	local order = { 4, 3, 2, 1 }

	-- visit 1: the training offer (M2 paid, no skill)
	local t = I.talk(player, { "s_c1bc23b4", TRAIN[order[1]].reply })

	lu.assertEquals(t[#t].id, TRAIN[order[1]].trained, "visit 1: last screen")
	lu.assertEquals(I.firstScreen(player), "m3_offer", "between visit 1 and 2: mission 3 is offered")

	-- mission 3 is flown and paid
	H.setQuestStatus(player, I.STATUS[3] .. ":attempted", "1")
	H.setQuestStatus(player, I.STATUS[3] .. ":reward", "1")
	I.setState(player, I.M3, "complete")

	for visit = 2, 4 do
		t = I.talk(player, { "s_ac71da57", I.READY_FOR_TRAINING, TRAIN[order[visit]].reply })
		lu.assertEquals(t[#t].id, TRAIN[order[visit]].trained, "visit " .. visit .. ": last screen")
	end

	lu.assertEquals(bought(player), { TRAIN[4].skill, TRAIN[3].skill, TRAIN[2].skill, TRAIN[1].skill }, "skills bought in the order chosen")
	lu.assertEquals(exp(player), 0, "four prices paid")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the fourth skill")
	lu.assertEquals(I.firstScreen(player), "m4_offer", "all four skills and M3 paid: the mission 4 offer")
end

-- AC-10: with too little XP the pilot is not offered the first training
function TestInquisitionT2TrainingGrant:test_with_too_little_xp_the_first_screen_is_the_duty_screen()
	lu.assertEquals(I.firstScreen(pilot({}, COST - 1)), "duty_after_m2", "no skill, 59999 XP")
end

---------------------------------------------------------------------------------------------
-- Mission 4 won without all four skills: m4_more_training (AC-11, D-19)
---------------------------------------------------------------------------------------------

TestInquisitionT2MoreTraining = {}

TestInquisitionT2MoreTraining.setUp = setUp

-- a pilot whose M4 is won and unpaid, with the skills `have`
local function m4pilot(have, xp, extra)
	local o = { paid = 3, state = "won", t2 = have, xp = xp or COST }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

-- AC-11
function TestInquisitionT2MoreTraining:test_the_more_training_menu_lists_the_missing_skills_in_table_order_and_think_about_it()
	for _, have in ipairs(subsets()) do
		if #have >= 1 then
			H.reset()
			I.useSkillCosts()

			local want, links = {}, {}

			for _, i in ipairs(missing(have)) do
				want[#want + 1] = TRAIN[i].reply
				links[#links + 1] = TRAIN[i].trained
			end

			want[#want + 1] = I.LATER
			links[#links + 1] = "training_later"

			local t = I.talk(m4pilot(have), { I.M4_MORE_TRAINING_REPLY })

			lu.assertEquals(I.ids(t), { "m4_won", "m4_more_training" }, "holding " .. table.concat(have, ",") .. ": screens shown")
			lu.assertEquals(I.optionSids(t[2]), want, "holding " .. table.concat(have, ",") .. ": menu replies")
			lu.assertEquals(I.linksOf(t[2]), links, "holding " .. table.concat(have, ",") .. ": menu links")
			lu.assertEquals(t[2].text, I.PREFIX .. "s_7be3e248", "the m4_more_training line")
		end
	end
end

-- AC-11: the fourth skill from m4_won completes the tier; the next talk pays
function TestInquisitionT2MoreTraining:test_buying_the_last_skill_there_raises_the_tier_and_the_next_talk_offers_the_pay_reply()
	local player = m4pilot({ 1, 2, 3 })
	local t = I.talk(player, { I.M4_MORE_TRAINING_REPLY, "s_c76594d7" })

	lu.assertEquals(I.ids(t), { "m4_won", "m4_more_training", "trained_droid" }, "screens shown")
	lu.assertEquals(bought(player), { TRAIN[4].skill }, "bought")
	lu.assertEquals(exp(player), 0, "XP charged")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
	lu.assertEquals(player.bankCredits, 0, "the mission is not paid by the training")

	local again = I.talk(player, { "s_97d51490", "s_1bac802d" })

	lu.assertEquals(I.ids(again), { "m4_won", "m4_pay", "m4_farewell" }, "the next talk")
	lu.assertEquals(player.bankCredits, I.CREDITS, "paid now")
end

-- AC-11, I-10: from m4_more_training a pilot with M3 paid and one skill may buy (FF-3 ties the one-skill rule to M3)
function TestInquisitionT2MoreTraining:test_a_second_skill_is_bought_from_m4_more_training_because_mission_3_is_paid()
	local player = m4pilot({ 1 })
	local t = I.talk(player, { I.M4_MORE_TRAINING_REPLY, "s_be30f309" })

	lu.assertEquals(t[#t].id, "trained_weapons", "last screen")
	lu.assertEquals(bought(player), { TRAIN[2].skill }, "bought")
end

-- AC-11: without the XP nothing is bought and the pilot is routed by the gates
function TestInquisitionT2MoreTraining:test_without_the_xp_nothing_is_bought_and_the_gates_route_the_pilot_back_to_m4_won()
	local player = m4pilot({ 1, 2, 3 }, 0)
	local t = I.talk(player, { I.M4_MORE_TRAINING_REPLY, "s_c76594d7" })

	lu.assertEquals(t[#t].id, "m4_won", "routed by the gates")
	noGrant(player, "no XP")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[4].skill), "the skill is not held")
end

---------------------------------------------------------------------------------------------
-- Guards that fail while the menu is shown (hooks)
---------------------------------------------------------------------------------------------

TestInquisitionT2TrainingGuards = {}

TestInquisitionT2TrainingGuards.setUp = setUp

-- AC-10
function TestInquisitionT2TrainingGuards:test_xp_that_is_gone_before_the_choice_buys_nothing_and_the_gates_route_the_pilot()
	local player = pilot({})
	local t = I.talk(player, { "s_c1bc23b4", function(p) p.ghost.experience.space_combat_general = 0 end, "s_be30f309" })

	lu.assertEquals(t[#t].id, "duty_after_m2", "routed by the gates: M2 paid, no XP")
	noGrant(player, "xp gone")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
end

-- AC-10: a skill the pilot got meanwhile is not bought again and costs nothing
function TestInquisitionT2TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_bought_again()
	local player = pilot({})
	local t = I.talk(player, { "s_c1bc23b4", function(p) p.skills[TRAIN[2].skill] = true end, "s_be30f309" })

	noGrant(player, "skill already held")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertTrue(t[#t].id == "m3_offer" or t[#t].id == TRAIN[2].trained, "the pilot is routed by the gates or shown the trained line, got " .. t[#t].id)
end

-- AC-10, I-10: one skill held with mission 3 unpaid: the menu cannot be used for a second skill
function TestInquisitionT2TrainingGuards:test_a_second_skill_is_refused_while_mission_3_is_unpaid()
	local player = I.pilot({ paid = 2, t2 = { 1 }, xp = 3 * COST })
	local t = I.drive(player, "training_menu", { "s_be30f309" })

	noGrant(player, "second skill, M3 unpaid")
	lu.assertEquals(exp(player), 3 * COST, "no XP charged")
	lu.assertEquals(t[#t].id, "m3_offer", "routed by the gates: mission 3 is next")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the weapons skill is not held")
end

-- AC-10, I-10: mission 2 unpaid: no skill whatever the XP
function TestInquisitionT2TrainingGuards:test_no_skill_is_bought_while_mission_2_is_unpaid()
	for _, paid in ipairs({ 0, 1 }) do
		H.reset()
		I.useSkillCosts()

		local player = I.pilot({ paid = paid, xp = 3 * COST })
		local t = I.drive(player, "training_menu", { "s_594a07fa" })

		noGrant(player, "M2 unpaid (paid=" .. paid .. ")")
		lu.assertEquals(exp(player), 3 * COST, "no XP charged")
		lu.assertEquals(t[#t].id, paid == 0 and "m1_offer" or "m2_offer", "routed by the gates")
	end
end

-- AC-10: the engine refuses the purchase when the prerequisites are not met
function TestInquisitionT2TrainingGuards:test_when_the_engine_refuses_the_purchase_the_pilot_gets_no_trained_screen()
	local real = LuaSkillManager

	LuaSkillManager = function()
		return { fulfillsSkillPrerequisitesAndXp = function() return false end, awardSkill = real().awardSkill }
	end

	local player = pilot({})
	local ok, t = pcall(I.talk, player, { "s_c1bc23b4", "s_be30f309" })

	LuaSkillManager = real
	lu.assertTrue(ok, "talking raised a Lua error: " .. tostring(t))
	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates: still ready for training")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
	lu.assertEquals(bought(player), {}, "no purchase attempted")
end

-- AC-10: a tier 1 skill lost meanwhile
function TestInquisitionT2TrainingGuards:test_a_tier_1_skill_lost_meanwhile_grants_nothing()
	local player = pilot({})
	local t = I.talk(player, { "s_c1bc23b4", function(p) p.skills[I.TIER1_SKILLS[1]] = nil end, "s_594a07fa" })

	noGrant(player, "tier 1 skill lost")
	lu.assertEquals(t[#t].id, "duty_after_m2", "routed by the gates: three tier 1 skills")
end

-- AC-10: mission 2 taken away meanwhile
function TestInquisitionT2TrainingGuards:test_the_mission_2_reward_taken_away_meanwhile_grants_nothing()
	local player = pilot({})
	local t = I.talk(player, { "s_c1bc23b4", function(p) H.setQuestStatus(p, I.STATUS[2] .. ":reward", nil) end, "s_594a07fa" })

	noGrant(player, "M2 reward gone")
	lu.assertNotEquals(t[#t].id, "trained_starships", "no trained screen")
end

---------------------------------------------------------------------------------------------
-- Handler rule helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestInquisitionT2TrainingRule = {}

TestInquisitionT2TrainingRule.setUp = setUp

local function h() return rawget(_G, I.HANDLER) end

-- AC-10, I-10
function TestInquisitionT2TrainingRule:test_isReadyForTraining_follows_the_rule()
	lu.assertTrue(h():isReadyForTraining(I.pilot({ paid = 2, xp = COST })), "M2 paid, no skill, 60000 XP")
	lu.assertTrue(h():isReadyForTraining(I.pilot({ paid = 3, t2 = { 1 }, xp = COST })), "one skill, M3 paid")
	lu.assertTrue(h():isReadyForTraining(I.pilot({ paid = 3, t2 = { 1, 2, 3 }, xp = COST })), "three skills, M3 paid")
	lu.assertFalse(h():isReadyForTraining(I.pilot({ paid = 2, xp = COST - 1 })), "59999 XP")
	lu.assertFalse(h():isReadyForTraining(I.pilot({ paid = 1, xp = 10 * COST })), "M2 unpaid")
	lu.assertFalse(h():isReadyForTraining(I.pilot({ paid = 2, t2 = { 1 }, xp = 10 * COST })), "one skill, M3 unpaid (FF-3)")
	lu.assertFalse(h():isReadyForTraining(I.pilot({ paid = 3, t2 = { 1, 2, 3, 4 }, xp = 10 * COST })), "all four: nothing left")
	lu.assertFalse(h():isReadyForTraining(I.pilot({ paid = 2, xp = COST, t1 = false })), "tier 1 not complete")
end

-- AC-10: hasCompletedTierTwo
function TestInquisitionT2TrainingRule:test_hasCompletedTierTwo_is_true_only_with_all_four_tier_2_skills()
	for _, have in ipairs(subsets()) do
		lu.assertFalse(h():hasCompletedTierTwo(I.pilot({ t2 = have })), "holding " .. table.concat(have, ","))
	end

	lu.assertTrue(h():hasCompletedTierTwo(I.pilot({ t2 = { 1, 2, 3, 4 } })), "holding all four")
end

-- AC-10, AC-11: the topic table of the handler is the client's pairing (FF-2)
function TestInquisitionT2TrainingRule:test_the_topic_screens_pair_each_skill_with_its_own_description()
	local pairs = {
		trained_starships = { "s_594a07fa", "s_486da900" },
		trained_weapons = { "s_be30f309", "s_241a34a1" },
		trained_procedures = { "s_e73e5d21", "s_c4880407" },
		trained_droid = { "s_c76594d7", "s_31804e15" },
	}

	for _, x in ipairs(TRAIN) do
		local t = I.drive(pilot({}), x.trained)

		lu.assertEquals(t[1].text, I.PREFIX .. pairs[x.trained][2], x.trained .. ": the description")
		lu.assertEquals(x.reply, pairs[x.trained][1], x.trained .. ": the topic reply")
	end
end
