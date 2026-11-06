-- Field Commander Alozen: the duties, the one-click bought training of the remaining tier 2 skills, the pilot tier 2 -> 3 step and the on-mission closure.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-9; Conversation flow 2 (C-3, C-4), 3 (H) and 3.4; FA-1, FA-2; D-6, D-8; I-10, I-12).
--
-- The menu lists one topic reply per missing tier 2 skill, in table order (starships, weapons, procedures, droid), then "Let me think about this for a bit".
-- The skill is bought through skillManagerAwardSkill (the XP is charged; no tier 2 skill is free) in getNextConversationScreen when the chosen link is a
-- trained screen of training_menu. Alozen sells at most the four skills of tier 2, only after M2 is paid; the fourth one raises the pilot tier from 2 to 3.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown. The fake charges XP only with
-- H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_02.tab (60000 each).

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local CS = require("harness.client_strings")

A.load()

local TRAIN = A.TRAIN
local COST = A.TRAINING_COST

local savedSkillManager

local function setUp()
	H.reset()
	A.requireConversation(lu)
	A.useSkillCosts()
	savedSkillManager = rawget(_G, "LuaSkillManager")
end

local function tearDown()
	rawset(_G, "LuaSkillManager", savedSkillManager)
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function boughtBy(player)
	local out = {}

	for _, call in ipairs(A.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function freeBy(player)
	local out = {}

	for _, call in ipairs(A.free()) do
		if call[1] == player and call[2]:find("^pilot_imperial_navy_%a+_02$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(boughtBy(player), {}, label .. ": bought grants")
	lu.assertEquals(freeBy(player), {}, label .. ": free grants")
end

-- the T.TRAIN indexes not in `have`
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

-- a pilot ready for the offer: M2 paid, the given tier 2 skills, the XP
local function pilot(have, xp, extra)
	local o = { m = 2, t2 = have or {}, xp = xp or COST }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return A.pilot(o)
end

local OFFER_REPLY = "s_7eed59f9"
local READY_FOR_TRAINING = "s_b0d3b474"
local DUTY_MENU_REPLY = "s_5a7ec1e4"

-- The replies from the first screen to the menu
local function toMenu() return { OFFER_REPLY } end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestAlozenTrainingMenu = {}

TestAlozenTrainingMenu.setUp = setUp
TestAlozenTrainingMenu.tearDown = tearDown

-- AC-9: the offer and the menu with the topics of the two missing skills
function TestAlozenTrainingMenu:test_a_pilot_with_two_tier_2_skills_gets_the_offer_and_a_menu_of_the_two_missing_topics_plus_think_about_it()
	local t = A.talk(pilot({ 1, 2 }), toMenu())

	lu.assertEquals(A.ids(t), { "training_offer", "training_menu" }, "screens shown")
	lu.assertEquals(t[2].text, A.PREFIX .. "s_2172d08a", "the menu line")
	lu.assertEquals(A.optionSids(t[2]), { "s_e73e5d21", "s_c76594d7", A.LATER }, "menu replies, in table order, then 'Let me think about this'")
	lu.assertEquals(A.linksOf(t[2]), { "trained_procedures", "trained_droid", "training_later" }, "menu links")
	lu.assertFalse(t[2].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: the menu lists exactly the missing skills, in table order
function TestAlozenTrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs({ {}, { 1 }, { 2 }, { 3 }, { 4 }, { 1, 2 }, { 3, 4 }, { 2, 4 }, { 1, 3 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
		H.reset()
		A.useSkillCosts()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].trained
		end

		want[#want + 1] = A.LATER
		links[#links + 1] = "training_later"

		local t = A.talk(pilot(have), toMenu())

		lu.assertEquals(A.ids(t), { "training_offer", "training_menu" }, label .. ": screens shown")
		lu.assertEquals(A.optionSids(t[2]), want, label .. ": menu replies")
		lu.assertEquals(A.linksOf(t[2]), links, label .. ": menu links")
	end
end

-- AC-9: "Let me think about this for a bit" ends without a grant
function TestAlozenTrainingMenu:test_think_about_it_ends_the_conversation_without_a_grant()
	local player = pilot({ 1, 2 })
	local t = A.talk(player, { OFFER_REPLY, A.LATER })

	lu.assertEquals(A.ids(t), { "training_offer", "training_menu", "training_later" }, "screens shown")
	lu.assertTrue(t[3].stop, "training_later ends")
	noGrant(player, "think about it")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: showing the menu or a trained screen alone grants nothing
function TestAlozenTrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({ 1, 2 })

	A.talk(player, toMenu())
	noGrant(player, "menu shown")

	for _, x in ipairs(TRAIN) do
		A.drive(player, x.trained)
		noGrant(player, x.trained .. " displayed alone")
	end

	A.drive(player, "trained_report")
	noGrant(player, "trained_report displayed alone")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is untouched")
end

-- C-3: without the XP the offer's reply says so
function TestAlozenTrainingMenu:test_the_offer_reply_leads_to_the_refusal_with_too_little_xp()
	local player = pilot({ 1, 2 }, COST - 1)
	local t = A.drive(player, "training_offer", { OFFER_REPLY })

	lu.assertEquals(A.ids(t), { "training_offer", "training_not_ready" }, "screens shown")
	lu.assertTrue(t[2].stop, "training_not_ready ends")
	noGrant(player, "not ready")
end

-- C-3: through the duty menu a ready pilot reaches the same menu, an unready one the refusal
function TestAlozenTrainingMenu:test_the_duty_menu_reply_leads_a_ready_pilot_to_the_menu_and_an_unready_one_to_the_refusal()
	local ready = A.drive(pilot({ 1, 2 }), "duty_menu", { READY_FOR_TRAINING })

	lu.assertEquals(A.ids(ready), { "duty_menu", "training_menu" }, "ready: screens shown")
	lu.assertEquals(A.optionSids(ready[2]), { "s_e73e5d21", "s_c76594d7", A.LATER }, "ready: menu replies")

	local unready = A.drive(pilot({ 1, 2 }, COST - 1), "duty_menu", { READY_FOR_TRAINING })

	lu.assertEquals(A.ids(unready), { "duty_menu", "training_not_ready" }, "unready: screens shown")

	local done = A.drive(pilot({ 1, 2, 3, 4 }), "duty_menu", { READY_FOR_TRAINING })

	lu.assertEquals(A.ids(done), { "duty_menu", "training_not_ready" }, "all four skills held: nothing to train")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestAlozenTrainingGrant = {}

TestAlozenTrainingGrant.setUp = setUp
TestAlozenTrainingGrant.tearDown = tearDown

-- AC-9, FA-1: every missing topic buys its skill, charges 60000 XP and shows the trained line, which leads to the report line
for idx, x in ipairs(TRAIN) do
	TestAlozenTrainingGrant["test_choosing_" .. x.x .. "_buys_the_skill_charges_the_xp_and_shows_" .. x.trained] = function()
		local others = missing({ idx })
		local have = { others[1], others[2] }
		local player = pilot(have)
		local t = A.talk(player, { OFFER_REPLY, x.reply, A.TRAINED_REPLY })

		lu.assertEquals(A.ids(t), { "training_offer", "training_menu", x.trained, "trained_report" }, "screens shown")
		lu.assertEquals(t[3].text, A.PREFIX .. x.trainedSid, x.trained .. ": the topic description")
		lu.assertEquals(A.optionSids(t[3]), { A.TRAINED_REPLY }, x.trained .. ": the one reply")
		lu.assertEquals(t[4].text, A.PREFIX .. "s_9c0c10ef", "the closing line")
		lu.assertTrue(t[4].stop, "trained_report ends the conversation")
		lu.assertEquals(boughtBy(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(freeBy(player), {}, "free grants (every tier 2 skill is bought)")
		lu.assertEquals(#A.held(player), 3, "tier 2 skills held")
		lu.assertEquals(exp(player), 0, "space XP after the purchase")
		lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier stays 2 on the third skill")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: with two skills, every first and second purchase works; the pilot tier rises with the second only; the next talks follow
function TestAlozenTrainingGrant:test_two_purchases_complete_tier_2_in_every_order_and_raise_the_pilot_tier_only_on_the_second()
	for _, firstSkill in ipairs({ 3, 4 }) do
		local secondSkill = firstSkill == 3 and 4 or 3

		for _, order in ipairs({ { firstSkill, secondSkill }, { secondSkill, firstSkill } }) do
			H.reset()
			A.useSkillCosts()

			local player = pilot({ 1, 2 }, 2 * COST)
			local label = "buying " .. TRAIN[order[1]].x .. " then " .. TRAIN[order[2]].x

			lu.assertEquals(A.firstScreen(player), "training_offer", label .. ": the first talk opens the offer")

			local first = A.talk(player, { OFFER_REPLY, TRAIN[order[1]].reply })

			lu.assertEquals(first[#first].id, TRAIN[order[1]].trained, label .. ": the first purchase")
			lu.assertEquals(player.ghost.pilotTier, 2, label .. ": the pilot tier stays 2 after the third skill")
			lu.assertEquals(A.firstScreen(player), "training_offer", label .. ": the next talk opens the offer again")

			local second = A.talk(player, { OFFER_REPLY, TRAIN[order[2]].reply })

			lu.assertEquals(second[#second].id, TRAIN[order[2]].trained, label .. ": the second purchase")
			lu.assertEquals(boughtBy(player), { TRAIN[order[1]].skill, TRAIN[order[2]].skill }, label .. ": the skills bought")
			lu.assertEquals(exp(player), 0, label .. ": two prices paid")
			lu.assertEquals(#A.held(player), 4, label .. ": all four tier 2 skills held")
			lu.assertEquals(player.ghost.pilotTier, 3, label .. ": the fourth skill raises the pilot tier to 3")
			lu.assertEquals(A.firstScreen(player), "m3_offer", label .. ": the next talk opens the mission 3 offer")
			lu.assertEquals(player.ghost.pilotTier, 3, label .. ": talking again changes nothing")
		end
	end
end

-- AC-9: a pilot who holds none, one or three skills reaches four the same way
function TestAlozenTrainingGrant:test_the_pilot_tier_rises_on_the_fourth_skill_from_any_starting_set()
	for _, have in ipairs({ { 1, 2, 3 }, { 2, 3, 4 }, { 1, 3, 4 }, { 1, 2, 4 } }) do
		H.reset()
		A.useSkillCosts()

		local i = missing(have)[1]
		local player = pilot(have)
		local t = A.talk(player, { OFFER_REPLY, TRAIN[i].reply })

		lu.assertEquals(t[#t].id, TRAIN[i].trained, "holding " .. table.concat(have, ",") .. ": the trained screen")
		lu.assertEquals(player.ghost.pilotTier, 3, "holding " .. table.concat(have, ",") .. ": the pilot tier")
		lu.assertEquals(A.firstScreen(player), "m3_offer", "holding " .. table.concat(have, ",") .. ": the next talk")
	end
end

-- AC-9, I-10: one reply buys one skill
function TestAlozenTrainingGrant:test_one_choice_buys_exactly_one_skill()
	local player = pilot({ 1 }, 3 * COST)

	A.talk(player, { OFFER_REPLY, TRAIN[2].reply })
	lu.assertEquals(boughtBy(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-9: nothing can be bought a second time in a visit
function TestAlozenTrainingGrant:test_the_visit_ends_on_trained_report_after_a_purchase()
	local player = pilot({ 1 }, 3 * COST)
	local t = A.talk(player, { OFFER_REPLY, TRAIN[2].reply, A.TRAINED_REPLY })

	lu.assertTrue(t[#t].stop, "the visit ends on trained_report")
	lu.assertEquals(#boughtBy(player), 1, "one purchase")
end

-- I-10: the oracle table. A topic is granted iff M2 is paid, tier 1 is complete, fewer than four tier 2 skills are held, the XP is there. Everything else
-- leaves the pilot as he was and opens his first screen. The pilot tier changes only on the grant that makes the fourth skill, only from 2 to 3.
function TestAlozenTrainingGrant:test_the_grant_follows_the_training_limits_for_every_state()
	local states = {}

	for _, m in ipairs({ 0, 1, 2 }) do
		for _, have in ipairs({ {}, { 1, 2 }, { 3 }, { 1, 2, 3 }, { 2, 3, 4 } }) do
			for _, xp in ipairs({ 0, COST - 1, COST }) do
				for _, t1 in ipairs({ true, false }) do
					states[#states + 1] = { m = m, have = have, xp = xp, t1 = t1 }
				end
			end
		end
	end

	local granted, refused = 0, 0

	for _, s in ipairs(states) do
		for _, i in ipairs(missing(s.have)) do
			H.reset()
			A.useSkillCosts()

			local expect = s.m >= 2 and s.t1 and s.xp >= COST
			local player = A.pilot({ m = s.m, t2 = s.have, xp = s.xp, t1 = s.t1 })
			local label = "M" .. s.m .. " paid, holding " .. table.concat(s.have, ",") .. ", xp " .. s.xp .. ", tier 1 " .. tostring(s.t1) .. ", topic " .. TRAIN[i].x
			local pilotTier = player.ghost.pilotTier
			local firstScreen = LuaConversationScreen(rawget(_G, A.HANDLER):getInitialScreen(player, A.npc(), H.conversationTemplate(A.TEMPLATE))):getScreenID()
			local t = A.drive(player, "training_menu", { TRAIN[i].reply })

			lu.assertEquals(#freeBy(player), 0, label .. ": free grants")

			if expect then
				granted = granted + 1
				lu.assertEquals(boughtBy(player), { TRAIN[i].skill }, label .. ": the skill is bought")
				lu.assertEquals(t[#t].id, TRAIN[i].trained, label .. ": the trained screen")
				lu.assertEquals(exp(player), s.xp - COST, label .. ": XP charged")
				lu.assertEquals(player.ghost.pilotTier, #s.have == 3 and 3 or pilotTier, label .. ": the pilot tier")
			else
				refused = refused + 1
				lu.assertEquals(boughtBy(player), {}, label .. ": nothing is bought")
				lu.assertEquals(exp(player), s.xp, label .. ": no XP charged")
				lu.assertEquals(#A.held(player), #s.have, label .. ": tier 2 skills held")
				lu.assertNotEquals(t[#t].id, TRAIN[i].trained, label .. ": the trained screen is not shown")
				lu.assertEquals(t[#t].id, firstScreen, label .. ": the pilot's first screen follows")
				lu.assertEquals(player.ghost.pilotTier, pilotTier, label .. ": the pilot tier is unchanged")
			end
		end
	end

	lu.assertTrue(granted > 0 and refused > 0, "the table covers grants (" .. granted .. ") and refusals (" .. refused .. ")")
end

-- I-10: the pilot tier changes only from 2 to 3
function TestAlozenTrainingGrant:test_the_pilot_tier_is_raised_only_from_2_to_3()
	for _, tier in ipairs({ 0, 1, 3, 4 }) do
		H.reset()
		A.useSkillCosts()

		local player = pilot({ 1, 2, 3 }, COST, { pilotTier = tier })

		A.drive(player, "training_menu", { TRAIN[4].reply })
		lu.assertEquals(boughtBy(player), { TRAIN[4].skill }, "pilot tier " .. tier .. ": the skill is bought")
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. ": unchanged by the fourth skill")
	end
end

-- I-10: the state changes while the menu is shown
function TestAlozenTrainingGrant:test_losing_the_xp_while_the_menu_is_shown_grants_nothing()
	local player = pilot({ 1, 2 })
	local t = A.talk(player, { OFFER_REPLY, function(p) p.ghost.experience.space_combat_general = COST - 1 end, "s_e73e5d21" })

	noGrant(player, "xp lost")
	lu.assertEquals(exp(player), COST - 1, "no XP charged")
	lu.assertNotEquals(t[#t].id, "trained_procedures", "the trained screen is not shown")
	lu.assertNotNil(t[#t].id, "a screen follows")
end

-- I-10: the engine refuses (prerequisites or XP): nothing is granted and no trained line is shown
function TestAlozenTrainingGrant:test_an_engine_refusal_grants_nothing_and_shows_no_trained_screen()
	local player = pilot({ 1, 2 })
	local t = A.talk(player, { OFFER_REPLY, function()
		rawset(_G, "LuaSkillManager", function()
			return {
				fulfillsSkillPrerequisitesAndXp = function() return false end,
				awardSkill = function() error("awardSkill must not be called when the engine refuses") end,
			}
		end)
	end, "s_e73e5d21" })

	noGrant(player, "engine refusal")
	lu.assertEquals(#A.held(player), 2, "no new tier 2 skill held")
	lu.assertNotEquals(t[#t].id, "trained_procedures", "the trained screen is not shown")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is unchanged")
end

-- I-10: a skill already held is not bought again (the menu is stale)
function TestAlozenTrainingGrant:test_a_skill_that_becomes_held_while_the_menu_is_shown_is_not_bought()
	local player = pilot({ 1, 2 })
	local t = A.talk(player, { OFFER_REPLY, function(p) p.skills[TRAIN[3].skill] = true end, "s_e73e5d21" })

	lu.assertEquals(boughtBy(player), {}, "nothing is bought for a skill the pilot already holds")
	lu.assertEquals(freeBy(player), {}, "nothing is granted free")
	lu.assertEquals(exp(player), COST, "no price paid")
	lu.assertNotNil(t[#t].id, "a screen follows")
end

---------------------------------------------------------------------------------------------
-- The duties (AC-9)
---------------------------------------------------------------------------------------------

TestAlozenDuties = {}

TestAlozenDuties.setUp = setUp
TestAlozenDuties.tearDown = tearDown

local DUTIES = {
	{ reply = "s_8a202d7b", screen = "duty_raiders", global = A.DUTY1 },
	{ reply = "s_d5ee9adc", screen = "duty_escort", global = A.DUTY3 },
	{ reply = "s_5950b85e", screen = "duty_salvage", global = A.DUTY2 },
}

-- AC-9: the duty menu replies and links
function TestAlozenDuties:test_the_duty_menu_on_track_lists_the_three_duties_and_the_training_reply()
	local t = A.talk(A.pilot({ m = 2 }), { DUTY_MENU_REPLY })

	lu.assertEquals(A.ids(t), { "duty_block", "duty_menu" }, "screens shown")
	lu.assertEquals(A.optionSids(t[2]), { "s_8a202d7b", "s_d5ee9adc", "s_5950b85e", READY_FOR_TRAINING }, "duty_menu replies")
	lu.assertEquals(A.linksOf(t[2]), { "duty_raiders", "duty_escort", "duty_salvage", "training_not_ready" }, "duty_menu links without the XP")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9, C-3: with the XP the training reply links to the menu
function TestAlozenDuties:test_the_training_reply_of_the_duty_menu_links_to_the_menu_for_a_ready_pilot()
	local t = A.drive(pilot({ 1, 2 }), "duty_menu")

	lu.assertEquals(A.linksOf(t[1]), { "duty_raiders", "duty_escort", "duty_salvage", "training_menu" }, "duty_menu links with the XP")
end

-- AC-9: each duty reply starts exactly its duty
for _, d in ipairs(DUTIES) do
	TestAlozenDuties["test_the_" .. d.screen .. "_reply_starts_exactly_" .. d.global] = function()
		local starts = A.spyStarts()
		local player = A.pilot({ m = 2 })
		local t = A.talk(player, { DUTY_MENU_REPLY, d.reply })

		lu.assertEquals(A.ids(t), { "duty_block", "duty_menu", d.screen }, "screens shown")
		lu.assertTrue(t[3].stop, d.screen .. " ends the conversation")
		lu.assertEquals(A.startedGlobals(starts), { d.global .. " x1" }, "only that duty starts")
		lu.assertEquals(starts[d.global][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-9: the duty starts on display of its screen, not before
	TestAlozenDuties["test_the_duty_menu_alone_starts_no_duty_for_" .. d.screen] = function()
		local starts = A.spyStarts()

		A.talk(A.pilot({ m = 2 }), { DUTY_MENU_REPLY })
		lu.assertEquals(A.startedGlobals(starts), {}, "startQuest calls at the menu")
	end
end

-- AC-9: the duty menu is also reached from the M2 walk
function TestAlozenDuties:test_the_m2_won_walk_reaches_the_same_duty_menu_and_starts_a_duty()
	local starts = A.spyStarts()
	local t = A.talk(A.pilot({ m = 1, state = "won" }), { "s_5365b13d", "s_57c8489e", DUTY_MENU_REPLY, "s_d5ee9adc" })

	lu.assertEquals(A.ids(t), { "m2_won", "m2_processing", "m2_buy_time", "duty_menu", "duty_escort" }, "screens shown")
	lu.assertEquals(A.startedGlobals(starts), { A.DUTY3 .. " x1" }, "the escort duty starts")
end

-- AC-9, A6: a pilot already on a quest never reaches a duty screen
function TestAlozenDuties:test_a_pilot_on_a_quest_never_reaches_a_duty_screen()
	local builds = {
		function() return A.pilot({ m = 2, datapad = "story" }) end,
		function() return A.pilot({ m = 2, datapad = "duty" }) end,
		function() return A.pilot({ m = 1, state = "active" }) end,
		function()
			local p = A.pilot({ m = 2 })

			A.setState(p, A.DUTY1, "active")
			return p
		end,
	}

	for i, build in ipairs(builds) do
		H.reset()

		local starts = A.spyStarts()
		local t = A.talk(build(), {})

		lu.assertEquals(A.ids(t), { "on_mission" }, "pilot " .. i .. ": the only screen")
		lu.assertEquals(#t[1].options, 0, "pilot " .. i .. ": no reply")
		lu.assertEquals(A.startedGlobals(starts), {}, "pilot " .. i .. ": nothing starts")
	end
end
