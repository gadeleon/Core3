-- Major Eker: the duty list, the three duties, the one-duty guard and the routes into the list.
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-8; Conversation flow 1 (E26), 3 (table H, DUTY_SCREENS) and 4; FE-13, FE-14; I-5).
--
-- duty_menu offers "steal Imperial ships" (recovery_duty_yavin_rebel_12), "escort smugglers" (escort_duty_yavin_rebel_10) and "destroy pirate patrols"
-- (destroy_duty_yavin_rebel_9), in JE's order, or later. A duty starts on its screen's display through <global>:startQuest(player, npc); the quest's own
-- guard refuses a second duty.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local DRS = require("duty_rules_scenario")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function P(o)
	local opts = { graduated = "2" }

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	return E.pilot(opts)
end

local MENU_REPLIES = { "s_73c783f8", "s_80e4843e", "s_46fb1c35", "s_6deac9a2" }

TestEkerDuties = {}

TestEkerDuties.setUp = setUp

-- AC-8: the duty offer leads to the menu with the three duties in JE's order and the "later" reply
function TestEkerDuties:test_the_duty_offer_leads_to_the_duty_menu_with_the_three_duties_and_later()
	local t = E.talk(P(), { "s_2bf9b1f7" })

	lu.assertEquals(E.ids(t), { "duty_offer", "duty_menu" }, "the walk")
	lu.assertEquals(E.optionSids(t[2]), MENU_REPLIES, "recovery, escort, destroy, later")
	lu.assertEquals(E.linksOf(t[2]), { "duty_recovery", "duty_escort", "duty_destroy", "duty_menu_later" }, "links")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-8: the three duty screens start the three duties (spied heads) and end
for _, d in ipairs({
	{ reply = "s_73c783f8", screen = "duty_recovery", global = E.DUTY12 },
	{ reply = "s_80e4843e", screen = "duty_escort", global = E.DUTY10 },
	{ reply = "s_46fb1c35", screen = "duty_destroy", global = E.DUTY9 },
}) do
	TestEkerDuties["test_" .. d.screen .. "_starts_" .. d.global .. "_and_only_it"] = function()
		local player = P()
		local spies = E.spyStarts()
		local t = E.talk(player, { "s_2bf9b1f7", d.reply })

		lu.assertEquals(E.ids(t), { "duty_offer", "duty_menu", d.screen }, "the walk")
		lu.assertTrue(t[3].stop, d.screen .. " ends the conversation")
		lu.assertEquals(E.startedCount(spies), { [d.global] = 1 }, "duties started")
		lu.assertEquals(spies[d.global][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		-- a duty grant pays nothing and sets no mission status key
		lu.assertEquals(player.bankCredits, 0, "bank credits")

		for n = 1, 4 do
			lu.assertNil(H.getQuestStatus(player, E.STATUS[n] .. ":attempted"), "mission " .. n .. " :attempted")
		end
	end

	-- AC-8: the real duty runs (a pilot in a ship in the quest zone) and the next talk is on_mission
	TestEkerDuties["test_" .. d.screen .. "_makes_the_real_duty_active_and_the_next_talk_on_mission"] = function()
		local player = P({ inShip = true, zone = "space_yavin4" })

		E.quest(d.global):start()
		E.drive(player, d.screen)
		lu.assertEquals(E.state(player, d.global), "active", d.global .. ": journal entry after " .. d.screen)
		lu.assertEquals(E.firstScreen(player), "on_mission", "the next talk")
	end
end

-- AC-8, I-5: a second duty is refused by the one-duty guard (real quests): the first keeps running and the pilot is told
function TestEkerDuties:test_a_second_duty_is_refused_while_the_first_is_running()
	local player = P({ inShip = true, zone = "space_yavin4" })

	for _, g in ipairs(E.DUTIES) do
		E.quest(g):start()
	end

	E.drive(player, "duty_escort")
	lu.assertEquals(E.state(player, E.DUTY10), "active", "precondition: the escort duty runs")

	E.drive(player, "duty_destroy")
	H.advance(0)
	lu.assertEquals(E.state(player, E.DUTY9), "none", E.DUTY9 .. ": refused")
	lu.assertEquals(E.state(player, E.DUTY10), "active", E.DUTY10 .. ": still running")
	lu.assertTrue(#DRS.messages(player, DRS.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
end

-- AC-8: the menu alone, the later replies and the offer's "later" start nothing
function TestEkerDuties:test_the_menu_and_the_later_replies_start_nothing()
	for _, choices in ipairs({ { "s_2bf9b1f7" }, { "s_2bf9b1f7", "s_6deac9a2" }, { "s_72c594c9" } }) do
		H.reset()

		local player = P()
		local spies = E.spyStarts()
		local t = E.talk(player, choices)

		lu.assertEquals(E.startedCount(spies), {}, "path " .. table.concat(choices, ", ") .. ": quests started")

		if choices[2] == "s_6deac9a2" then
			lu.assertEquals(t[#t].id, "duty_menu_later", "the later reply")
			lu.assertTrue(t[#t].stop, "duty_menu_later ends")
		elseif choices[1] == "s_72c594c9" then
			lu.assertEquals(t[#t].id, "duty_later", "the offer's later reply")
			lu.assertTrue(t[#t].stop, "duty_later ends for an ordinary pilot")
		end
	end
end

-- AC-8: the duty menu is reachable from the offer, the off-track offer, the mission walks, the training screens and the hand-in replies
function TestEkerDuties:test_the_duty_menu_is_reachable_from_every_route_the_spec_names()
	local routes = {
		{ name = "duty_offer", pilot = { graduated = "2" }, choices = { "s_2bf9b1f7" }, last = "duty_menu" },
		{ name = "off_track_duties", pilot = { squadron = HAVOC_SQUADRON }, start = "off_track_duties", choices = { "s_ca47d528" }, last = "duty_menu" },
		{ name = "m1_duties", pilot = { missions = 0, t2 = 1 }, start = "m1_duties", choices = { "s_b54697f" }, last = "duty_menu" },
		{ name = "m1_discipline", pilot = { missions = 0, t2 = 1 }, start = "m1_discipline", choices = { "s_aaf61b87" }, last = "duty_menu" },
		{ name = "m1_work_to_do", pilot = { missions = 0, t2 = 1 }, start = "m1_work_to_do", choices = { "s_53de9d8f" }, last = "duty_menu" },
		{ name = "m3_pay_war_not_over", pilot = { missions = 2, t2 = 3, state = "won" }, start = "m3_pay_war_not_over", choices = { "s_affe46cc" }, last = "duty_menu" },
		{ name = "training_find_out", pilot = { xp = E.XP_COST }, start = "training_find_out", choices = { "s_11e0bfe9" }, last = "duty_menu" },
		{ name = "training_free", pilot = { xp = E.XP_COST }, start = "training_free", choices = { "s_8a4cdaa1" }, last = "duty_menu" },
		{ name = "handin_is_that_right", pilot = { graduated = "1" }, start = "handin_is_that_right", choices = { "s_a9d63a81" }, last = "handin_duty_menu" },
		{ name = "handin_which_eker", pilot = { graduated = "1" }, start = "handin_which_eker", choices = { "s_8f9a3bf4" }, last = "handin_duty_menu" },
		{ name = "handin_defected", pilot = { graduated = "1" }, start = "handin_defected", choices = { "s_a9d63a81" }, last = "handin_duty_menu" },
		{ name = "handin_confession", pilot = { graduated = "1" }, start = "handin_confession", choices = { "s_a9d63a81" }, last = "handin_duty_menu" },
		{ name = "handin_heard_me", pilot = { graduated = "1" }, start = "handin_heard_me", choices = { "s_a9d63a81" }, last = "handin_duty_menu" },
	}

	for _, r in ipairs(routes) do
		H.reset()
		E.spyStarts()

		local player = P(r.pilot)
		local t = r.start and E.drive(player, r.start, r.choices) or E.talk(player, r.choices)

		lu.assertEquals(t[#t].id, r.last, r.name .. ": the route ends on the duty menu")
		lu.assertEquals(E.linksOf(t[#t]), { "duty_recovery", "duty_escort", "duty_destroy", "duty_menu_later" }, r.name .. ": the menu's links")
	end
end

-- AC-8: the duty menu reached through the mission walks the spec names (m1_won -> m1_refugee -> m1_duties -> duties; m3_won -> m3_pay_war_not_over -> duties)
function TestEkerDuties:test_the_duty_menu_is_reachable_through_the_mission_walks()
	local m1 = E.talk(P({ missions = 0, t2 = 1, state = "won" }), { "s_837615b6", "s_7f93598d", "s_53de9d8f" })

	lu.assertEquals(E.ids(m1), { "m1_won", "m1_refugee", "m1_work_to_do", "duty_menu" }, "mission 1 walk through the work-to-do line")

	H.reset()

	local m1b = E.talk(P({ missions = 0, t2 = 1, state = "won" }), { "s_837615b6", "s_e39ec30", "s_1b4c2d5d", "s_aaf61b87" })

	lu.assertEquals(E.ids(m1b), { "m1_won", "m1_refugee", "m1_duties", "m1_discipline", "duty_menu" }, "mission 1 walk through the discipline line")

	H.reset()

	local m3 = E.talk(P({ missions = 2, t2 = 3, state = "won" }), { "s_4471d2b", "s_affe46cc" })

	lu.assertEquals(E.ids(m3), { "m3_won", "m3_pay_war_not_over", "duty_menu" }, "mission 3 walk")
end

-- AC-8: after the mission 4 reward every visit is the hand-off; Eker starts no duty for a graduate
function TestEkerDuties:test_a_tier_2_graduate_gets_no_duty_from_eker()
	local player = P({ missions = 4, t2 = 4, graduated = "3" })
	local spies = E.spyStarts()
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "tier3_handoff" }, "the graduate's visit")
	lu.assertEquals(E.startedCount(spies), {}, "quests started")
end

-- AC-8, I-5: only the three duty screens (and the GM duty screens) start a duty
function TestEkerDuties:test_no_other_screen_starts_a_duty()
	for _, row in ipairs(E.SCREENS) do
		if E.DUTY_SCREENS[row.id] == nil then
			H.reset()

			local player = P({ xp = 999999, privileged = true })
			local spies = E.spyStarts()

			E.drive(player, row.id)

			for _, g in ipairs(E.DUTIES) do
				lu.assertEquals(#spies[g], 0, "screen '" .. row.id .. "': " .. g .. " started")
			end
		end
	end
end

-- AC-8: the duty screens start exactly the quests of E.DUTY_SCREENS (the GM ones included)
function TestEkerDuties:test_the_duty_screens_are_the_six_of_the_spec()
	local n = 0

	for screen, global in pairs(E.DUTY_SCREENS) do
		n = n + 1

		H.reset()

		local spies = E.spyStarts()

		E.drive(P({ privileged = true }), screen)
		lu.assertEquals(E.startedCount(spies), { [global] = 1 }, screen .. ": duties started")
		lu.assertTrue(E.screenRow(screen).stop, screen .. " ends")
	end

	lu.assertEquals(n, 6, "duty screens")
end

-- AC-8: an off-track pilot without four _01 skills, or with any space quest, gets off_track_no_missions and no duty
function TestEkerDuties:test_an_off_track_pilot_without_tier_1_done_or_with_a_quest_gets_no_duty()
	for _, o in ipairs({ { squadron = HAVOC_SQUADRON, t1 = 3 }, { squadron = HAVOC_SQUADRON, t1 = 0 }, { squadron = HAVOC_SQUADRON, datapad = "story" }, { squadron = HAVOC_SQUADRON, datapad = "duty" } }) do
		H.reset()

		local spies = E.spyStarts()
		local t = E.talk(P(o), { "s_1583743c" })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_no_missions" }, "off-track pilot " .. tostring(o.t1 or o.datapad))
		lu.assertEquals(E.startedCount(spies), {}, "quests started")
	end
end

-- AC-8: the off-track duty route starts a duty for a pilot who qualifies, through the same duty screens
function TestEkerDuties:test_an_off_track_pilot_who_qualifies_can_start_a_duty()
	local player = P({ squadron = HAVOC_SQUADRON })
	local spies = E.spyStarts()
	local t = E.talk(player, { "s_1583743c", "s_ca47d528", "s_73c783f8" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_duties", "duty_menu", "duty_recovery" }, "the walk")
	lu.assertEquals(E.startedCount(spies), { [E.DUTY12] = 1 }, "duties started")
end

-- AC-8: the off-track "no" reply says goodbye and starts nothing
function TestEkerDuties:test_the_off_track_goodbye_starts_nothing()
	local spies = E.spyStarts()
	local t = E.talk(P({ squadron = HAVOC_SQUADRON }), { "s_1583743c", "s_7115a155" })

	lu.assertEquals(E.ids(t), { "off_track", "off_track_duties", "off_track_goodbye" }, "the walk")
	lu.assertTrue(t[3].stop, "off_track_goodbye ends")
	lu.assertEquals(E.startedCount(spies), {}, "quests started")
end
