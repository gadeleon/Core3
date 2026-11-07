-- Brother Vrovel: the duty list, the three duties, the one-duty guard and the routes into the list.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-8; Conversation flow 1 (V25), 3 (table H, DUTY_SCREENS) and 4; FV-8, FV-9; I-5).
--
-- duty_menu offers escort (escort_duty_vortex_mission_5), "Hijacking Imperial ships" (recovery_duty_vortex_mission_7) and "Not many can stand
-- toe-to-toe" (destroy_duty_vortex_mission_6), in J2's order, or later. A duty starts on its screen's display through <global>:startQuest(player, npc);
-- the quest's own guard refuses a second duty.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local DRS = require("duty_rules_scenario")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

TestVrovelDuties = {}

TestVrovelDuties.setUp = setUp

-- AC-8: the duty offer leads to the menu with the three duties in J2's order and the "later" reply
function TestVrovelDuties:test_the_duty_offer_leads_to_the_duty_menu_with_the_three_duties_and_later()
	local t = V.talk(V.pilot({ graduated = "2" }), { "s_9b43a7ee" })

	lu.assertEquals(V.ids(t), { "duty_offer", "duty_menu" }, "the walk")
	lu.assertEquals(V.optionSids(t[2]), { "s_9828194f", "s_a7fb8221", "s_948462ad", "s_cd1a5817" }, "escort, recovery, destroy, later")
	lu.assertEquals(V.linksOf(t[2]), { "duty_escort", "duty_recovery", "duty_destroy", "duty_menu_later" }, "links")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-8: the three duty screens start the three duties (spied heads) and end
for _, d in ipairs({
	{ reply = "s_9828194f", screen = "duty_escort", global = V.DUTY5 },
	{ reply = "s_a7fb8221", screen = "duty_recovery", global = V.DUTY7 },
	{ reply = "s_948462ad", screen = "duty_destroy", global = V.DUTY6 },
}) do
	TestVrovelDuties["test_" .. d.screen .. "_starts_" .. d.global .. "_and_only_it"] = function()
		local player = V.pilot({ graduated = "2" })
		local spies = V.spyStarts()
		local t = V.talk(player, { "s_9b43a7ee", d.reply })

		lu.assertEquals(V.ids(t), { "duty_offer", "duty_menu", d.screen }, "the walk")
		lu.assertTrue(t[3].stop, d.screen .. " ends the conversation")
		lu.assertEquals(V.startedCount(spies), { [d.global] = 1 }, "duties started")
		lu.assertEquals(spies[d.global][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(t[3].params.TU, "Ace", "the first name")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		-- a duty grant pays nothing and sets no mission status key
		lu.assertEquals(player.bankCredits, 0, "bank credits")

		for n = 1, 4 do
			lu.assertNil(H.getQuestStatus(player, V.STATUS[n] .. ":attempted"), "mission " .. n .. " :attempted")
		end
	end

	-- AC-8: the real duty runs (a pilot in a ship in the quest zone) and the next talk is on_mission
	TestVrovelDuties["test_" .. d.screen .. "_makes_the_real_duty_active_and_the_next_talk_on_mission"] = function()
		local player = V.pilot({ graduated = "2", inShip = true, zone = "space_dantooine" })

		V.quest(d.global):start()
		V.drive(player, d.screen)
		lu.assertEquals(V.state(player, d.global), "active", d.global .. ": journal entry after " .. d.screen)
		lu.assertEquals(V.firstScreen(player), "on_mission", "the next talk")
	end
end

-- AC-8, I-5: a second duty is refused by the one-duty guard (real quests): the first keeps running and the pilot is told
function TestVrovelDuties:test_a_second_duty_is_refused_while_the_first_is_running()
	local player = V.pilot({ graduated = "2", inShip = true, zone = "space_dantooine" })

	for _, g in ipairs(V.DUTIES) do
		V.quest(g):start()
	end

	V.drive(player, "duty_escort")
	lu.assertEquals(V.state(player, V.DUTY5), "active", "precondition: the escort duty runs")

	V.drive(player, "duty_destroy")
	H.advance(0)
	lu.assertEquals(V.state(player, V.DUTY6), "none", V.DUTY6 .. ": refused")
	lu.assertEquals(V.state(player, V.DUTY5), "active", V.DUTY5 .. ": still running")
	lu.assertTrue(#DRS.messages(player, DRS.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
end

-- AC-8: the menu alone, the later replies and the offer's "later" start nothing
function TestVrovelDuties:test_the_menu_and_the_later_replies_start_nothing()
	for _, choices in ipairs({ { "s_9b43a7ee" }, { "s_9b43a7ee", "s_cd1a5817" }, { "s_6b054777" } }) do
		H.reset()

		local player = V.pilot({ graduated = "2" })
		local spies = V.spyStarts()
		local t = V.talk(player, choices)

		lu.assertEquals(V.startedCount(spies), {}, "path " .. table.concat(choices, ", ") .. ": quests started")

		if choices[2] == "s_cd1a5817" then
			lu.assertEquals(t[#t].id, "duty_menu_later", "the later reply")
			lu.assertTrue(t[#t].stop, "duty_menu_later ends")
		elseif choices[1] == "s_6b054777" then
			lu.assertEquals(t[#t].id, "duty_later", "the offer's later reply")
			lu.assertTrue(t[#t].stop, "duty_later ends")
		end
	end
end

-- AC-8: duty_menu is reachable from the offer, the three hand-in acceptances, m1_not_yet, m1_attitude, m3_duty_work and off_track_duties
function TestVrovelDuties:test_the_duty_menu_is_reachable_from_every_route_the_spec_names()
	local routes = {
		{ name = "duty_offer", pilot = { graduated = "2" }, start = nil, choices = { "s_9b43a7ee" }, via = "duty_offer" },
		{ name = "handin_dont_salute", pilot = { graduated = "1" }, start = "handin_dont_salute", choices = { "s_60e93806" } },
		{ name = "handin_promise", pilot = { graduated = "1" }, start = "handin_promise", choices = { "s_22a1e2bb" } },
		{ name = "handin_pay", pilot = { graduated = "1" }, start = "handin_pay", choices = { "s_33f02b70" } },
		{ name = "m1_not_yet", pilot = { graduated = "2", missions = 0, t2 = 1 }, start = "m1_not_yet", choices = { "s_9d33db7" } },
		{ name = "m1_attitude", pilot = { graduated = "2", missions = 0, t2 = 1 }, start = "m1_attitude", choices = { "s_aaf61b87" } },
		{ name = "m3_duty_work", pilot = { graduated = "2", missions = 2, t2 = 3 }, start = "m3_duty_work", choices = { "s_e02f4f90" } },
		{ name = "off_track_duties", pilot = { squadron = HAVOC_SQUADRON }, start = "off_track_duties", choices = { "s_52917b0d" } },
	}

	for _, r in ipairs(routes) do
		H.reset()
		V.spyStarts()

		local t = r.start and V.drive(V.pilot(r.pilot), r.start, r.choices) or V.talk(V.pilot(r.pilot), r.choices)

		lu.assertEquals(t[#t].id, "duty_menu", r.name .. ": the route ends on the duty menu")
	end
end

-- AC-8: the routes in the walks the spec names (m1_won -> m1_setup -> m1_not_yet -> duties; m1_not_yet -> m1_attitude -> duties; m3_won -> m3_duty_work -> duties)
function TestVrovelDuties:test_the_duty_menu_is_reachable_through_the_mission_walks()
	local m1 = V.talk(V.pilot({ missions = 0, t2 = 1, state = "won" }), { "s_266422af", "s_b8b49994", "s_dcc384fa", "s_aaf61b87" })

	lu.assertEquals(V.ids(m1), { "m1_won", "m1_setup", "m1_not_yet", "m1_attitude", "duty_menu" }, "mission 1 walk through the attitude line")

	H.reset()

	local m3 = V.talk(V.pilot({ missions = 2, t2 = 3, state = "won" }), { "s_93f5b2e2", "s_e02f4f90" })

	lu.assertEquals(V.ids(m3), { "m3_won", "m3_duty_work", "duty_menu" }, "mission 3 walk")
end

-- AC-8, FV-8: after the mission 4 reward every visit goes to Ezkiel; Vrovel starts no duty for a graduate
function TestVrovelDuties:test_a_tier_2_graduate_gets_no_duty_from_vrovel()
	local player = V.pilot({ missions = 4, t2 = 4, graduated = "3" })
	local spies = V.spyStarts()
	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "ezkiel_handoff" }, "the graduate's visit")
	lu.assertEquals(V.startedCount(spies), {}, "quests started")
end

-- AC-8, I-5: only the three duty screens (and the GM duty screens) start a duty
function TestVrovelDuties:test_no_other_screen_starts_a_duty()
	for _, row in ipairs(V.SCREENS) do
		if V.DUTY_SCREENS[row.id] == nil then
			H.reset()

			local player = V.pilot({ graduated = "2", xp = 999999, privileged = true })
			local spies = V.spyStarts()

			V.drive(player, row.id)

			for _, g in ipairs(V.DUTIES) do
				lu.assertEquals(#spies[g], 0, "screen '" .. row.id .. "': " .. g .. " started")
			end
		end
	end
end

-- AC-8 (FV-9): an off-track pilot without four _01 skills, or with any space quest, gets off_track_no_missions and no duty
function TestVrovelDuties:test_an_off_track_pilot_without_tier_1_done_or_with_a_quest_gets_no_duty()
	for _, o in ipairs({ { squadron = HAVOC_SQUADRON, t1 = 3 }, { squadron = HAVOC_SQUADRON, t1 = 0 }, { squadron = HAVOC_SQUADRON, datapad = "story" }, { squadron = HAVOC_SQUADRON, datapad = "duty" } }) do
		H.reset()

		local spies = V.spyStarts()
		local t = V.talk(V.pilot(o), { "s_c23a0a19" })

		lu.assertEquals(V.ids(t), { "off_track", "off_track_no_missions" }, "off-track pilot " .. tostring(o.t1 or o.datapad))
		lu.assertEquals(V.startedCount(spies), {}, "quests started")
	end
end

-- AC-8: the off-track duty route starts a duty for a pilot who qualifies, through the same duty screens
function TestVrovelDuties:test_an_off_track_pilot_who_qualifies_can_start_a_duty()
	local player = V.pilot({ squadron = HAVOC_SQUADRON })
	local spies = V.spyStarts()
	local t = V.talk(player, { "s_c23a0a19", "s_52917b0d", "s_a7fb8221" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_duties", "duty_menu", "duty_recovery" }, "the walk")
	lu.assertEquals(V.startedCount(spies), { [V.DUTY7] = 1 }, "duties started")
end

-- AC-8: the off-track "no" reply says goodbye and starts nothing
function TestVrovelDuties:test_the_off_track_goodbye_starts_nothing()
	local spies = V.spyStarts()
	local t = V.talk(V.pilot({ squadron = HAVOC_SQUADRON }), { "s_c23a0a19", "s_28f9c5ec" })

	lu.assertEquals(V.ids(t), { "off_track", "off_track_duties", "off_track_goodbye" }, "the walk")
	lu.assertTrue(t[3].stop, "off_track_goodbye ends")
	lu.assertEquals(V.startedCount(spies), {}, "quests started")
end
