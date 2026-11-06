-- Commander Oberhaur: the duties, the one-click bought training of the two tier 2 skills he teaches, and the on-mission closure.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-11; Conversation flow 2 (C-3, C-4), 3 (H) and 3.4; FI-2, FI-3, FI-4; D-7, D-8; I-10).
--
-- The menu lists one topic reply per missing tier 2 skill, in table order (starships, weapons, procedures, droid), then "Let me think about this for a bit".
-- The skill is bought through skillManagerAwardSkill (the XP is charged; no tier 2 skill is free) in getNextConversationScreen when the chosen link is a
-- trained screen of training_menu. Oberhaur grants at most two skills: none before M2 is paid, a second only after the Claw is paid, and never a third.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown. The fake charges XP only with
-- H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_02.tab (60000 each).

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")

T.load()

local TRAIN = T.TRAIN
local COST = T.TRAINING_COST

local savedSkillManager

local function setUp()
	H.reset()
	T.requireConversation(lu)
	T.useSkillCosts()
	savedSkillManager = rawget(_G, "LuaSkillManager")
end

local function tearDown()
	rawset(_G, "LuaSkillManager", savedSkillManager)
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function bought(player)
	local out = {}

	for _, call in ipairs(T.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function free(player)
	local out = {}

	for _, call in ipairs(T.free()) do
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

-- the TRAIN indexes of the skills not in `have`
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

-- a pilot ready for the offer: M2 paid and no skill yet, or the Claw paid with one skill (FI-3)
local function pilot(have, xp, extra)
	local o = { paid = (#(have or {}) > 0) and 3 or 2, t2 = have or {}, xp = xp or COST }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

-- The replies from the first screen to the menu
local function toMenu() return { "s_a4faf714" } end

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestStormT2TrainingMenu = {}

TestStormT2TrainingMenu.setUp = setUp
TestStormT2TrainingMenu.tearDown = tearDown

-- AC-11, FI-2: the offer and the menu with the four topics
function TestStormT2TrainingMenu:test_a_pilot_with_no_tier_2_skill_gets_the_offer_and_a_menu_of_four_topics_plus_think_about_it()
	local t = T.talk(pilot({}), toMenu())

	lu.assertEquals(T.ids(t), { "training_offer", "training_menu" }, "screens shown")
	lu.assertEquals(t[2].text, T.PREFIX .. "s_44d66989", "the menu line")
	lu.assertEquals(T.optionSids(t[2]), { "s_594a07fa", "s_dbb5bf46", "s_e73e5d21", "s_c76594d7", T.LATER }, "menu replies, in table order, then 'Let me think about this'")
	lu.assertEquals(T.linksOf(t[2]), { "trained_starships", "trained_weapons", "trained_procedures", "trained_droid", "training_later" }, "menu links")
	lu.assertFalse(t[2].stop, "the menu waits for a reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: the menu lists exactly the missing skills, in table order (no skill: M2 paid; one skill: the Claw paid)
function TestStormT2TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs({ {}, { 1 }, { 2 }, { 3 }, { 4 } }) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].trained
		end

		want[#want + 1] = T.LATER
		links[#links + 1] = "training_later"

		local t = T.talk(pilot(have), toMenu())

		lu.assertEquals(T.ids(t), { "training_offer", "training_menu" }, label .. ": screens shown")
		lu.assertEquals(T.optionSids(t[2]), want, label .. ": menu replies")
		lu.assertEquals(T.linksOf(t[2]), links, label .. ": menu links")
	end
end

-- AC-11: "Let me think about this for a bit" ends without a grant
function TestStormT2TrainingMenu:test_think_about_it_ends_the_conversation_without_a_grant()
	local player = pilot({})
	local t = T.talk(player, { "s_a4faf714", T.LATER })

	lu.assertEquals(T.ids(t), { "training_offer", "training_menu", "training_later" }, "screens shown")
	lu.assertTrue(t[3].stop, "training_later ends")
	noGrant(player, "think about it")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: showing the menu or a trained screen alone grants nothing
function TestStormT2TrainingMenu:test_showing_the_menu_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({})

	T.talk(player, { "s_a4faf714" })
	noGrant(player, "menu shown")

	for _, x in ipairs(TRAIN) do
		T.drive(player, x.trained)
		noGrant(player, x.trained .. " displayed alone")
	end

	T.drive(player, "trained_report")
	noGrant(player, "trained_report displayed alone")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

-- C-3: without the XP the offer's reply says so
function TestStormT2TrainingMenu:test_the_training_reply_says_not_ready_without_the_xp()
	local player = pilot({}, COST - 1)
	local t = T.talk(player, { T.DUTY_MENU_REPLY, T.READY_FOR_TRAINING, "s_89bc583c" })

	lu.assertEquals(T.ids(t), { "duty_after_m2", "duty_menu", "training_not_ready", "training_report_back" }, "screens shown")
	lu.assertTrue(t[4].stop, "training_report_back ends")
	lu.assertEquals(t[3].params.TU, "Ace", "training_not_ready: %NU")
	noGrant(player, "not ready")
end

-- AC-11: through the duty menu a ready pilot reaches the same menu
function TestStormT2TrainingMenu:test_the_duty_menu_reply_leads_a_ready_pilot_to_the_training_menu()
	local t = T.drive(pilot({}), "duty_menu", { T.READY_FOR_TRAINING })

	lu.assertEquals(T.ids(t), { "duty_menu", "training_menu" }, "screens shown")
	lu.assertEquals(T.optionSids(t[2]), { "s_594a07fa", "s_dbb5bf46", "s_e73e5d21", "s_c76594d7", T.LATER }, "menu replies")
end

-- AC-11: too little XP at the offer
function TestStormT2TrainingMenu:test_the_offer_reply_leads_to_the_refusal_with_too_little_xp()
	local t = T.drive(pilot({}, COST - 1), "training_offer", { "s_a4faf714" })

	lu.assertEquals(T.ids(t), { "training_offer", "training_not_ready" }, "screens shown")
end

---------------------------------------------------------------------------------------------
-- The purchase
---------------------------------------------------------------------------------------------

TestStormT2TrainingGrant = {}

TestStormT2TrainingGrant.setUp = setUp
TestStormT2TrainingGrant.tearDown = tearDown

-- AC-11, FI-2: the topic buys the skill, charges 60000 XP and shows the trained line, which leads to the report line
for _, x in ipairs(TRAIN) do
	TestStormT2TrainingGrant["test_choosing_" .. x.x .. "_buys_the_skill_charges_the_xp_and_shows_" .. x.trained] = function()
		local player = pilot({})
		local pilotTier = player.ghost.pilotTier
		local t = T.talk(player, { "s_a4faf714", x.reply, T.THANK_YOU })

		lu.assertEquals(T.ids(t), { "training_offer", "training_menu", x.trained, "trained_report" }, "screens shown")
		lu.assertEquals(t[3].text, T.PREFIX .. x.trainedSid, x.trained .. ": the topic description")
		lu.assertEquals(T.optionSids(t[3]), { T.THANK_YOU }, x.trained .. ": the one reply")
		lu.assertEquals(t[4].text, T.PREFIX .. "s_9c0c10ef", "the closing line")
		lu.assertTrue(t[4].stop, "trained_report ends the conversation")
		lu.assertEquals(bought(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(free(player), {}, "free grants (every tier 2 skill is bought)")
		lu.assertEquals(T.held(player), { x.skill }, "tier 2 skills held")
		lu.assertEquals(exp(player), 0, "space XP after the purchase")
		lu.assertEquals(player.ghost.pilotTier, pilotTier, "the pilot tier never changes (FI-3)")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-11: after the first skill the next talk opens the Morv offer, not the training offer
function TestStormT2TrainingGrant:test_the_next_talk_after_the_first_purchase_opens_m3_offer()
	for _, x in ipairs(TRAIN) do
		H.reset()
		T.useSkillCosts()

		local player = pilot({}, 3 * COST)

		T.talk(player, { "s_a4faf714", x.reply })
		lu.assertEquals(T.firstScreen(player), "m3_offer", x.x .. ": the next talk")
		lu.assertEquals(#bought(player), 1, x.x .. ": no second skill bought")
	end
end

-- AC-11: with one skill and the Claw paid, the next talk offers training again and a second purchase works
function TestStormT2TrainingGrant:test_with_one_skill_and_the_claw_paid_a_second_purchase_works_and_the_next_talk_opens_alozen_orders()
	for first = 1, 4 do
		for second = 1, 4 do
			if first ~= second then
				H.reset()
				T.useSkillCosts()

				local player = pilot({ first }, 2 * COST)

				lu.assertEquals(T.firstScreen(player), "training_offer", "holding " .. TRAIN[first].x .. ": the offer")

				local t = T.talk(player, { "s_a4faf714", TRAIN[second].reply, T.THANK_YOU })

				lu.assertEquals(T.ids(t), { "training_offer", "training_menu", TRAIN[second].trained, "trained_report" }, "screens shown")
				lu.assertEquals(bought(player), { TRAIN[second].skill }, "the second skill is bought")
				lu.assertEquals(exp(player), COST, "one price paid")
				lu.assertEquals(#T.held(player), 2, "two tier 2 skills held")
				lu.assertEquals(T.firstScreen(player), "alozen_orders", "with two skills the Yavin orders open")
			end
		end
	end
end

-- AC-11, I-10: one reply buys one skill
function TestStormT2TrainingGrant:test_one_choice_buys_exactly_one_skill()
	local player = pilot({}, 3 * COST)

	T.talk(player, { "s_a4faf714", "s_dbb5bf46" })
	lu.assertEquals(bought(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-11: nothing can be bought a second time
function TestStormT2TrainingGrant:test_a_second_choice_in_the_same_visit_is_not_possible_after_the_trained_screens()
	local player = pilot({}, 3 * COST)
	local t = T.talk(player, { "s_a4faf714", "s_dbb5bf46", T.THANK_YOU })

	lu.assertTrue(t[#t].stop, "the visit ends on trained_report")
	lu.assertEquals(#bought(player), 1, "one purchase")
end

-- I-10: the oracle table. A topic is granted iff M2 is paid, tier 1 is complete, fewer than two tier 2 skills are held, the XP is there and
-- (the Claw is paid or no tier 2 skill is held yet). Everything else leaves the pilot as he was and opens his first screen.
function TestStormT2TrainingGrant:test_the_grant_follows_the_training_limits_for_every_state()
	local states = {}

	for _, paid in ipairs({ 0, 1, 2, 3 }) do
		for _, have in ipairs({ {}, { 1 }, { 3 }, { 1, 2 }, { 2, 4 }, { 1, 2, 3 } }) do
			for _, xp in ipairs({ 0, COST - 1, COST, 3 * COST }) do
				for _, t1 in ipairs({ true, false }) do
					states[#states + 1] = { paid = paid, have = have, xp = xp, t1 = t1 }
				end
			end
		end
	end

	local granted, refused = 0, 0

	for _, s in ipairs(states) do
		for _, i in ipairs(missing(s.have)) do
			H.reset()
			T.useSkillCosts()

			local expect = s.paid >= 2 and s.t1 and #s.have < 2 and s.xp >= COST and (s.paid >= 3 or #s.have == 0)
			local player = T.pilot({ paid = s.paid, t2 = s.have, xp = s.xp, t1 = s.t1 })
			local label = "paid " .. s.paid .. ", holding " .. table.concat(s.have, ",") .. ", xp " .. s.xp .. ", tier 1 " .. tostring(s.t1) .. ", topic " .. TRAIN[i].x
			local pilotTier = player.ghost.pilotTier
			local t = T.drive(player, "training_menu", { TRAIN[i].reply })

			lu.assertEquals(#free(player), 0, label .. ": free grants")

			if expect then
				granted = granted + 1
				lu.assertEquals(bought(player), { TRAIN[i].skill }, label .. ": the skill is bought")
				lu.assertEquals(t[#t].id, TRAIN[i].trained, label .. ": the trained screen")
				lu.assertEquals(exp(player), s.xp - COST, label .. ": XP charged")
			else
				refused = refused + 1
				lu.assertEquals(bought(player), {}, label .. ": nothing is bought")
				lu.assertEquals(exp(player), s.xp, label .. ": no XP charged")
				lu.assertEquals(#T.held(player), #s.have, label .. ": tier 2 skills held")
				lu.assertNotEquals(t[#t].id, TRAIN[i].trained, label .. ": the trained screen is not shown")
				lu.assertEquals(t[#t].id, T.firstScreen(player), label .. ": the pilot's first screen follows")
			end

			lu.assertEquals(player.ghost.pilotTier, pilotTier, label .. ": the pilot tier never changes")
		end
	end

	lu.assertTrue(granted > 0 and refused > 0, "the table covers grants (" .. granted .. ") and refusals (" .. refused .. ")")
end

-- I-10: the state changes while the menu is shown
function TestStormT2TrainingGrant:test_losing_the_xp_while_the_menu_is_shown_grants_nothing()
	local player = pilot({})
	local t = T.talk(player, { "s_a4faf714", function(p) p.ghost.experience.space_combat_general = COST - 1 end, "s_594a07fa" })

	noGrant(player, "xp lost")
	lu.assertEquals(exp(player), COST - 1, "no XP charged")
	lu.assertNotEquals(t[#t].id, "trained_starships", "the trained screen is not shown")
	lu.assertNotNil(t[#t].id, "a screen follows")
end

-- I-10: the engine refuses (prerequisites or XP): nothing is granted and no trained line is shown
function TestStormT2TrainingGrant:test_an_engine_refusal_grants_nothing_and_shows_no_trained_screen()
	local player = pilot({})
	local t = T.talk(player, { "s_a4faf714", function()
		rawset(_G, "LuaSkillManager", function()
			return {
				fulfillsSkillPrerequisitesAndXp = function() return false end,
				awardSkill = function() error("awardSkill must not be called when the engine refuses") end,
			}
		end)
	end, "s_594a07fa" })

	noGrant(player, "engine refusal")
	lu.assertEquals(T.held(player), {}, "no tier 2 skill held")
	lu.assertNotEquals(t[#t].id, "trained_starships", "the trained screen is not shown")
end

-- I-10: a skill already held is not bought again (the menu is stale)
function TestStormT2TrainingGrant:test_a_skill_that_becomes_held_while_the_menu_is_shown_is_not_bought()
	local player = pilot({})
	local t = T.talk(player, { "s_a4faf714", function(p) p.skills[TRAIN[1].skill] = true end, "s_594a07fa" })

	lu.assertEquals(bought(player), {}, "nothing is bought for a skill the pilot already holds")
	lu.assertEquals(free(player), {}, "nothing is granted free")
	lu.assertEquals(exp(player), COST, "no price paid")
	lu.assertNotNil(t[#t].id, "a screen follows")
end

---------------------------------------------------------------------------------------------
-- The duties (AC-11)
---------------------------------------------------------------------------------------------

TestStormT2Duties = {}

TestStormT2Duties.setUp = setUp
TestStormT2Duties.tearDown = tearDown

local DUTIES = {
	{ reply = "s_45f4f7db", screen = "duty_fleet", global = T.DUTY1, after = "duty_fleet_aces" },
	{ reply = "s_a6363375", screen = "duty_smugglers", global = T.DUTY2, after = "duty_smugglers_guard" },
	{ reply = "s_721e2818", screen = "duty_pirates", global = T.DUTY3, after = "duty_pirates_alive" },
}

-- AC-11: the duty menu replies and links
function TestStormT2Duties:test_the_duty_menu_on_track_lists_the_three_duties_and_the_training_reply()
	local t = T.talk(T.pilot({ paid = 2 }), { T.DUTY_MENU_REPLY })

	lu.assertEquals(T.ids(t), { "duty_after_m2", "duty_menu" }, "screens shown")
	lu.assertEquals(T.optionSids(t[2]), { "s_45f4f7db", "s_a6363375", "s_721e2818", T.READY_FOR_TRAINING }, "duty_menu replies")
	lu.assertEquals(T.linksOf(t[2]), { "duty_fleet", "duty_smugglers", "duty_pirates", "training_not_ready" }, "duty_menu links without the XP")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: each duty reply starts exactly its duty
for _, d in ipairs(DUTIES) do
	TestStormT2Duties["test_the_" .. d.screen .. "_reply_starts_exactly_" .. d.global] = function()
		local starts = {}

		for _, g in ipairs(T.GLOBALS) do
			starts[g] = H.spyOn(T.quest(g), "startQuest")
		end

		local player = T.pilot({ paid = 2 })
		local t = T.talk(player, { T.DUTY_MENU_REPLY, d.reply, "s_b6b25f13" })

		lu.assertEquals(T.ids(t), { "duty_after_m2", "duty_menu", d.screen, d.after }, "screens shown")
		lu.assertTrue(t[4].stop, d.after .. " ends the conversation")

		for _, g in ipairs(T.GLOBALS) do
			lu.assertEquals(#starts[g], g == d.global and 1 or 0, "startQuest calls of " .. g)
		end

		lu.assertEquals(starts[d.global][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-11: the duty starts on display of its screen, not before
	TestStormT2Duties["test_the_duty_menu_alone_starts_no_duty_for_" .. d.screen] = function()
		local starts = {}

		for _, g in ipairs(T.GLOBALS) do
			starts[g] = H.spyOn(T.quest(g), "startQuest")
		end

		T.talk(T.pilot({ paid = 2 }), { T.DUTY_MENU_REPLY })

		for _, g in ipairs(T.GLOBALS) do
			lu.assertEquals(#starts[g], 0, "startQuest calls of " .. g .. " at the menu")
		end
	end
end

-- AC-11: the briefing walk
function TestStormT2Duties:test_the_duty_briefing_walks_to_the_duty_menu()
	local t = T.talk(T.pilot({ paid = 2 }), { "s_b2a924ab", "s_5102164f", "s_45fa29cc", T.DUTY_MENU_REPLY })

	lu.assertEquals(T.ids(t), { "duty_after_m2", "duty_briefing", "duty_briefing_smugglers", "duty_briefing_pirates", "duty_menu" }, "screens shown")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11, O6: a pilot already on a quest never reaches the duty menu
function TestStormT2Duties:test_a_pilot_on_a_quest_never_reaches_a_duty_screen()
	local reachable = { on_mission = true, on_mission_outstanding = true, travel_capable = true, travel_carry_on = true, travel_need_ship = true, travel_why = true,
		travel_where = true, travel_handle = true, travel_launch = true, travel_begone = true, travel_vendor = true, travel_not_nice = true, travel_planetary_map = true }

	for _, build in ipairs({
		function() return T.pilot({ paid = 2, duty = T.DUTY1 }) end,
		function() return T.pilot({ paid = 2, datapad = "story", ships = { "object/intangible/ship/tieadvanced_pcd.iff" } }) end,
		function() return T.pilot({ paid = 1, state = "active" }) end,
	}) do
		local queue, visited = { {} }, {}

		while #queue > 0 do
			local path = table.remove(queue, 1)

			H.reset()

			local starts = {}

			for _, g in ipairs(T.GLOBALS) do
				starts[g] = H.spyOn(T.quest(g), "startQuest")
			end

			local t = T.talk(build(), path)
			local last = t[#t]

			lu.assertTrue(reachable[last.id] == true, "screen '" .. last.id .. "' reached from on_mission along " .. table.concat(path, ","))

			for _, g in ipairs(T.GLOBALS) do
				lu.assertEquals(#starts[g], 0, g .. " started along " .. table.concat(path, ","))
			end

			if not visited[last.id] then
				visited[last.id] = true

				for k = 0, #last.options - 1 do
					local nextPath = { table.unpack(path) }

					nextPath[#nextPath + 1] = k
					queue[#queue + 1] = nextPath
				end
			end
		end
	end
end
