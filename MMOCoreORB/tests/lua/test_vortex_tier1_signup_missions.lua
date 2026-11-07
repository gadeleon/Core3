-- V3-FX: sign-up, the four mission offers, briefings, failures and restarts (an abort is a failure), the brush-offs with the droid's sparks and the duty hand-outs.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (AC-5, AC-6, AC-7; Conversation flow 3 (table H) and 4; Appendix A; FI-1, FI-4, FI-5, FI-8; D-6, D-10, D-13).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (vortex_tier1_screens_data.lua)
-- unless a conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("vortex_tier1_data")
local CS = require("harness.client_strings")

I.load()

local HEADS = { I.P1, I.M2, I.P3, I.A4 }
local ALL = { I.P1, I.S1, I.M2, I.P3, I.E3, I.A4, I.DUTY6, I.DUTY7 }

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

-- The screens an Appendix A graph shows when `choices` (reply sids) are followed from screen `first`
local function follow(first, choices)
	local ids = { first }

	for _, sid in ipairs(choices) do
		local row = I.screenRow(ids[#ids])

		lu.assertNotNil(row, "Appendix A has no screen '" .. tostring(ids[#ids]) .. "'")

		local link

		for _, o in ipairs(row.options) do
			if o[1] == sid then
				link = o[2]
			end
		end

		lu.assertNotNil(link, "Appendix A: screen '" .. row.id .. "' has no reply " .. sid)
		ids[#ids + 1] = link
	end

	return ids
end

local function spyAll(globals)
	local spies = {}

	for _, g in ipairs(globals) do
		spies[g] = H.spyOn(I.quest(g), "startQuest")
	end

	return spies
end

local function started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

-- Runs a walk: the screens shown, the quests started, the client strings of the transcript
local function walk(w)
	local spies = spyAll(ALL)
	local player = I.pilot(w.pilot)
	local t = I.talk(player, w.choices)
	local ids = w.ids or follow(w.first, w.choices)

	lu.assertEquals(I.ids(t), ids, w.name .. ": screens shown")
	lu.assertEquals(started(spies), w.starts or {}, w.name .. ": quests started")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings of the transcript (AC-5)")

	return t, player
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-7: sign-up
---------------------------------------------------------------------------------------------

-- exactly one grantStarterShip(player, "rebel")
local function assertOneShip(player)
	local calls = H.Engine.callsTo("grantStarterShip")

	lu.assertEquals(#calls, 1, "grantStarterShip calls")
	lu.assertTrue(calls[1][1] == player and calls[1][2] == "rebel", "the starter ship is a rebel one for the pilot")
end

local function novice(player)
	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2] == I.NOVICE then
			return true
		end
	end

	return false
end

TestVortexT1SignUp = {}

TestVortexT1SignUp.setUp = setUp

-- a Rebel-faction player who is no pilot yet
local function nonPilot(o)
	o = o or {}
	o.pilot, o.squadron, o.pilotTier = false, false, 0

	return I.pilot(o)
end

local REPLY_SHIP, REPLY_THANKS = "s_a42932d7", "s_fc27931b"

-- The seven ways to an oath screen: { name, replies up to and including the one that shows the oath, the oath screen }
local OATHS = {
	{ name = "sign_money_splendid", choices = { "s_78679b31", "s_99dfe276", "s_2bf47615" }, oath = "oath_splendid", via = { "recruitment", "recruit_sign", "recruit_money" } },
	{ name = "sign_money_how_much_glorious", choices = { "s_78679b31", "s_99dfe276", "s_1d2430a3", "s_104b565a" }, oath = "oath_glorious", via = { "recruitment", "recruit_sign", "recruit_money", "recruit_how_much" } },
	{ name = "sign_teach_excellent_choice", choices = { "s_78679b31", "s_b0643db5", "s_e096316d" }, oath = "oath_excellent_choice", via = { "recruitment", "recruit_sign", "recruit_teach" } },
	{ name = "sign_teach_welcome", choices = { "s_78679b31", "s_b0643db5", "s_7ed5fec3" }, oath = "oath_welcome", via = { "recruitment", "recruit_sign", "recruit_teach" } },
	{ name = "fly_great_day", choices = { "s_1a0322d9", "s_546aa4f5" }, oath = "oath_great_day", via = { "recruitment", "recruit_fly" } },
	{ name = "fly_obligations_rebel_program", choices = { "s_1a0322d9", "s_f91d81c7", "s_d002385f" }, oath = "oath_rebel_program", via = { "recruitment", "recruit_fly", "recruit_obligations" } },
	{ name = "ready_space_navy", choices = { "s_616cd1dd", "s_31d45080" }, oath = "oath_space_navy", via = { "recruitment", "recruit_ready" } },
}

for _, w in ipairs(OATHS) do
	local ids = concat(w.via, { w.oath })

	-- AC-7: each oath screen grants the novice box, the squadron and tier 1; C-2 shows the ship grant for a pilot without a ship
	TestVortexT1SignUp["test_the_" .. w.name .. "_route_grants_the_box_the_squadron_tier_1_and_one_rebel_ship_to_a_pilot_without_a_ship"] = function()
		local player = nonPilot({ ship = false })
		local t = I.talk(player, concat(w.choices, { REPLY_SHIP, REPLY_THANKS }))

		lu.assertEquals(I.ids(t), concat(ids, { "recruit_ship_granted", "first_assignment" }), "screens shown")
		lu.assertEquals(I.optionSids(t[#ids]), { REPLY_SHIP }, "the oath screen's one reply without a ship: 'I will need a starship.'")
		lu.assertTrue(novice(player), "the novice box pilot_rebel_navy_novice was granted free (awardSkill)")
		lu.assertEquals(player.ghost.squadronType, VORTEX_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
		assertOneShip(player)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: a pilot who still has a ship goes straight to first_assignment and gets none; the oath's reply is "Thanks."
	TestVortexT1SignUp["test_the_" .. w.name .. "_route_skips_the_ship_grant_for_a_pilot_with_a_ship"] = function()
		local player = nonPilot()
		local t = I.talk(player, concat(w.choices, { REPLY_THANKS }))

		lu.assertEquals(I.ids(t), concat(ids, { "first_assignment" }), "screens shown")
		lu.assertEquals(I.optionSids(t[#ids]), { REPLY_THANKS }, "the oath screen's one reply with a ship: 'Thanks.'")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship")
		lu.assertTrue(novice(player), "the novice box was still granted")
		lu.assertEquals(player.ghost.squadronType, VORTEX_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	end

	-- AC-7: nothing is granted before the oath screen
	TestVortexT1SignUp["test_the_" .. w.name .. "_route_grants_nothing_before_the_oath"] = function()
		local player = nonPilot({ ship = false })

		I.talk(player, { table.unpack(w.choices, 1, #w.choices - 1) })
		lu.assertFalse(novice(player), "no novice box before the oath")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron before the oath")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	end
end

-- AC-7: all seven oath screens are covered by those walks, and they are the oaths of Appendix A
function TestVortexT1SignUp:test_the_seven_walks_reach_the_seven_oath_screens_of_appendix_a()
	local oaths = {}

	for _, w in ipairs(OATHS) do
		oaths[#oaths + 1] = w.oath
		lu.assertEquals(follow("recruitment", w.choices)[#w.choices + 1], w.oath, w.name .. ": the walk ends on its oath screen in Appendix A")
	end

	table.sort(oaths)
	lu.assertEquals(oaths, { "oath_excellent_choice", "oath_glorious", "oath_great_day", "oath_rebel_program", "oath_space_navy", "oath_splendid", "oath_welcome" }, "the seven oath screens")
end

-- AC-7: the whole sign-up of a pilot without a ship, through the first mission
function TestVortexT1SignUp:test_a_rebel_non_pilot_without_a_ship_signs_up_gets_the_box_the_squadron_the_ship_and_mission_1()
	local choices = { "s_616cd1dd", "s_31d45080", REPLY_SHIP, REPLY_THANKS, "s_d731f764", "s_3a8fb4dd" }
	local player = nonPilot({ ship = false })
	local spies = spyAll(HEADS)
	local t = I.talk(player, choices)

	lu.assertEquals(I.ids(t), { "recruitment", "recruit_ready", "oath_space_navy", "recruit_ship_granted", "first_assignment", "m1_health", "m1_frontier" }, "screens shown")
	lu.assertTrue(novice(player), "the novice box was granted free")
	lu.assertEquals(player.ghost.squadronType, VORTEX_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	assertOneShip(player)
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: a pilot who already holds a higher pilot tier keeps it
function TestVortexT1SignUp:test_the_oath_does_not_lower_a_higher_pilot_tier()
	local player = nonPilot({ pilotTier = 2 })

	player.ghost.pilotTier = 2
	I.talk(player, { "s_616cd1dd", "s_31d45080" })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier stays 2 (raised to 1 only if below)")
end

-- AC-7: no route refuses: every reply of every recruitment screen leads on (no screen of the sign-up ends before the oath or the first assignment)
function TestVortexT1SignUp:test_no_sign_up_screen_before_the_oath_ends_the_conversation()
	for _, id in ipairs({ "recruitment", "recruit_sign", "recruit_money", "recruit_how_much", "recruit_teach", "recruit_fly", "recruit_obligations", "recruit_ready" }) do
		lu.assertFalse(I.screenRow(id).stop, id .. " does not end the conversation")
		lu.assertTrue(#I.screenRow(id).options >= 1, id .. " has a reply")
	end
end

-- AC-7: the lost-ship branch (a member who lost the ship)
function TestVortexT1SignUp:test_a_member_who_lost_the_ship_gets_one_new_starter_ship_on_display()
	local player = I.pilot({ ship = false })
	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "lost_ship" }, "screens shown")
	lu.assertTrue(t[1].stop, "lost_ship ends")
	assertOneShip(player)
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the grant on display needs the pilot to lack a certified ship
function TestVortexT1SignUp:test_the_ship_grant_screens_give_nothing_to_a_pilot_who_has_a_ship()
	for _, screen in ipairs({ "recruit_ship_granted", "lost_ship" }) do
		H.reset()
		I.drive(I.pilot(), screen)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, screen .. ": a pilot with a certified ship gets no second one")
	end
end

-- AC-7: the ship-grant screens give one rebel ship to a pilot without one
function TestVortexT1SignUp:test_the_ship_grant_screens_give_one_rebel_starter_ship_to_a_pilot_without_one()
	for _, screen in ipairs({ "recruit_ship_granted", "lost_ship" }) do
		H.reset()

		local player = I.pilot({ ship = false })

		I.drive(player, screen)
		assertOneShip(player)
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: mission offers, briefings and starts
---------------------------------------------------------------------------------------------

TestVortexT1Offers = {}

TestVortexT1Offers.setUp = setUp

local WALKS = {
	{ name = "mission_1_health_then_frontier", pilot = {}, first = "mission1_offer", choices = { "s_d731f764", "s_3a8fb4dd" }, starts = { I.P1 } },
	{ name = "mission_1_frontier_good_day", pilot = {}, first = "mission1_offer", choices = { "s_d731f764", "s_3a8fb4dd", "s_116bd775" }, starts = { I.P1 } },
	{ name = "mission_1_frontier_pirates_merchants", pilot = {}, first = "mission1_offer", choices = { "s_d731f764", "s_3a8fb4dd", "s_afdd3bc5", "s_c713935d", "s_116bd775" }, starts = { I.P1 } },
	{ name = "mission_1_glorious", pilot = {}, first = "mission1_offer", choices = { "s_90377ed4", "s_c7939f2f", "s_2adb435", "s_7a27e11", "s_123652f8" }, starts = { I.P1 } },
	{ name = "mission_1_four_point", pilot = {}, first = "mission1_offer", choices = { "s_b04f2893", "s_658f174d", "s_93470245", "s_92e1301f" }, starts = { I.P1 } },
	{ name = "mission_1_training_loop_then_accept", pilot = {}, first = "mission1_offer", choices = { "s_fb1c19c1", "s_fb1c19c1", "s_90377ed4" }, starts = { I.P1 } },
	{ name = "mission_2_why_not", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_c92d07b4", "s_1728f71a", "s_6c620e99", "s_8b4893d6" }, starts = { I.M2 } },
	{ name = "mission_2_um_yes", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_b2d473c6", "s_cbe69427", "s_97e129cd", "s_49bfaf2" }, starts = { I.M2 } },
	{ name = "mission_2_good_to_hear", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_6fb5a316", "s_1809c6fc", "s_8995f223", "s_2d4bb338" }, starts = { I.M2 } },
	{ name = "mission_2_training_loop", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_fb1c19c1", "s_fb1c19c1", "s_c92d07b4" }, starts = { I.M2 } },
	{ name = "mission_3_thank_maker", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_3f1a842c" }, starts = { I.P3 } },
	{ name = "mission_3_good_luck", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_b2d473c6" }, starts = { I.P3 } },
	{ name = "mission_3_critical_agreed", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_1e626caa", "s_d0233b4b" }, starts = { I.P3 } },
	{ name = "mission_3_training_loop", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_fb1c19c1", "s_fb1c19c1", "s_3f1a842c" }, starts = { I.P3 } },
	{ name = "mission_4_splendid_job", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_ebc0661b", "s_bf1a0f3e" }, starts = { I.A4 } },
	{ name = "mission_4_splendid_details", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_ebc0661b", "s_6a150013" }, starts = { I.A4 } },
	{ name = "mission_4_rally_yes_sir", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_6b490480", "s_87a8cca7", "s_a30c1a53" }, starts = { I.A4 } },
	{ name = "mission_4_tie_forces", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_a994ca63", "s_cf04e474", "s_d779178a", "s_6aadaf18" }, starts = { I.A4 } },
	{ name = "mission_4_word_loop", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_7478cd28", "s_7478cd28", "s_ebc0661b" }, starts = { I.A4 } },
}

for _, w in ipairs(WALKS) do
	-- AC-7
	TestVortexT1Offers["test_walk_" .. w.name] = function()
		walk(w)
	end
end

-- AC-7: first_assignment (after the oath) offers the same four mission 1 routes as mission1_offer
function TestVortexT1Offers:test_first_assignment_offers_the_four_mission_1_routes()
	local t = I.drive(I.pilot(), "first_assignment")

	lu.assertEquals(I.optionSids(t[1]), { "s_d731f764", "s_90377ed4", "s_b04f2893", "s_fb1c19c1" }, "replies")
	lu.assertEquals(I.linksOf(t[1]), { "m1_health", "m1_glorious", "m1_four_point", "m1_not_yet" }, "links")
	lu.assertEquals(#I.sparks(), 0, "no sparks")
end

-- AC-7: the exact last screens of the accepted routes end the conversation
function TestVortexT1Offers:test_the_briefing_endings_end_the_conversation()
	for _, last in ipairs({ "m1_good_day", "m1_delightful", "m1_certain", "m2_irrepressible", "m2_name_alliance", "m2_thank_you", "m3_thank_maker", "m3_good_luck", "m3_agreed", "m4_job", "m4_details",
		"m4_yes_sir", "m4_honor" }) do
		H.reset()
		lu.assertTrue(I.drive(I.pilot({ paid = 0 }), last)[1].stop, last .. " ends the conversation")
	end
end

-- AC-7: m4_yes_sir is the rejoin of SWG's s_282: it shows the line that closes the sibling m2 salute route and ends
function TestVortexT1Offers:test_m4_yes_sir_shows_the_same_client_line_as_m2_name_alliance()
	local a = I.drive(I.pilot({ paid = 3 }), "m4_yes_sir")
	local b = I.drive(I.pilot({ paid = 1 }), "m2_name_alliance")

	lu.assertEquals(a[1].text, I.PREFIX .. "s_81770bc2", "m4_yes_sir")
	lu.assertEquals(b[1].text, I.PREFIX .. "s_81770bc2", "m2_name_alliance")
end

-- AC-7: mission 1 won and unpaid is answered by the report routes (the pay itself is tested in the reward file)
function TestVortexT1Offers:test_mission_1_won_reports_lead_on_to_the_next_assignment_after_payment()
	local player = I.pilot({ state = "won" })
	local t = I.talk(player, { "s_1f6a762c" })

	lu.assertEquals(I.ids(t), { "mission1_won", "m1_superior" }, "screens shown")
	lu.assertEquals(I.firstScreen(player), "mission2_offer", "the next talk offers mission 2")
end

-- AC-7: the won screens of missions 2 and 3 lead to short answers
function TestVortexT1Offers:test_the_mission_2_and_3_report_replies_end_in_their_short_answers()
	walk({ name = "m2 yes indeed", pilot = { paid = 1, state = "won" }, first = "mission2_won", choices = { "s_c1013aa7" } })
	walk({ name = "m2 welcome", pilot = { paid = 1, state = "won" }, first = "mission2_won", choices = { "s_f0b6493f" } })
	walk({ name = "m1 attacked", pilot = { state = "won" }, first = "mission1_won", choices = { "s_85fcdc55", "s_73edb45" } })
end

---------------------------------------------------------------------------------------------
-- AC-7: failures and restarts (D-10: the failure screen restarts the mission on display)
---------------------------------------------------------------------------------------------

TestVortexT1Failures = {}

TestVortexT1Failures.setUp = setUp

local FAILS = {
	{ n = 1, screen = "mission1_failed", accept = { "s_d731f764", "s_3a8fb4dd" } },
	{ n = 2, screen = "mission2_failed", accept = { "s_c92d07b4" } },
	{ n = 3, screen = "mission3_failed", accept = { "s_3f1a842c" } },
	{ n = 4, screen = "mission4_failed", accept = { "s_ebc0661b" } },
}

for _, f in ipairs(FAILS) do
	-- AC-7: the failure screen itself restarts the mission and sets :attempted
	TestVortexT1Failures["test_mission_" .. f.n .. "_failed_restarts_the_mission_on_display"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = I.talk(player)

		lu.assertEquals(I.ids(t), { f.screen }, "first screen")
		lu.assertEquals(started(spies), { HEADS[f.n] }, "the head of mission " .. f.n .. " started once, on display")
		lu.assertEquals(spies[HEADS[f.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_" .. f.n .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: with the real head and a pilot in a ship the mission is running after the failure screen
	TestVortexT1Failures["test_mission_" .. f.n .. "_failed_makes_the_real_head_quest_active"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed", inShip = true, zone = "space_naboo" })

		I.quest(HEADS[f.n]):start()
		I.talk(player)
		lu.assertEquals(I.state(player, HEADS[f.n]), "active", HEADS[f.n] .. ": journal entry after the failure screen")
	end

	-- AC-7 (FI-1): a second start screen in the same walk does not start a second run (the chain is active)
	TestVortexT1Failures["test_mission_" .. f.n .. "_failed_then_an_accept_route_starts_only_one_run"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed", inShip = true, zone = "space_naboo" })
		local q = I.quest(HEADS[f.n])
		local calls = 0
		local original = q.startQuest

		q:start()
		q.startQuest = function(self, ...)
			calls = calls + 1

			return original(self, ...)
		end

		local t = I.talk(player, f.accept)

		q.startQuest = original
		lu.assertEquals(I.ids(t)[1], f.screen, "first screen")
		lu.assertTrue(#t >= 2, "the accept route was followed")
		lu.assertEquals(calls, 1, "startQuest calls: the failure screen started it, the accept route was refused while it is active")
		lu.assertEquals(I.state(player, HEADS[f.n]), "active", "the run is active")
	end
end

-- AC-7: the failed screens of missions 1..4 show the same menu as the offers (routes into the briefings)
function TestVortexT1Failures:test_the_failed_screens_offer_the_same_routes_as_the_offers()
	for n, pair in ipairs({ { "mission1_failed", "mission1_offer" }, { "mission2_failed", "mission2_offer" }, { "mission3_failed", "mission3_offer" }, { "mission4_failed", "mission4_offer" } }) do
		local a = I.drive(I.pilot({ paid = n - 1, state = "failed" }), pair[1])
		local b = I.drive(I.pilot({ paid = n - 1 }), pair[2])

		lu.assertEquals(I.optionSids(a[1]), I.optionSids(b[1]), pair[1] .. " replies equal " .. pair[2] .. "'s")
		lu.assertEquals(I.linksOf(a[1]), I.linksOf(b[1]), pair[1] .. " links equal " .. pair[2] .. "'s")
	end
end

-- AC-7: a running chain is never restarted underneath the pilot
function TestVortexT1Failures:test_a_start_screen_does_not_restart_a_running_mission()
	local player = I.pilot({ state = "active" })
	local spies = spyAll(HEADS)

	I.drive(player, "m1_frontier")
	lu.assertEquals(started(spies), {}, "mission 1 is active: no second start")
end

-- AC-7: the retry clears the failed run's leftover journal entries before starting (every member of the chain)
function TestVortexT1Failures:test_the_restart_clears_the_failed_runs_leftover_journal_entries_before_starting()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")

	local spies = spyAll(HEADS)

	I.talk(player)
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 restarted")
	lu.assertEquals(I.state(player, I.P1), "none", "the stale patrol entry is cleared")
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack entry is cleared")

	H.reset()

	local p3 = I.pilot({ paid = 2, state = "failed" })

	I.setState(p3, I.P3, "complete")
	spyAll(HEADS)
	I.talk(p3)
	lu.assertEquals(I.state(p3, I.P3), "none", "the stale mission 3 patrol entry is cleared")
	lu.assertEquals(I.state(p3, I.E3), "none", "the stale mission 3 escort entry is cleared")
end

---------------------------------------------------------------------------------------------
-- AC-7: every start screen sets :attempted and starts its chain head (table H)
---------------------------------------------------------------------------------------------

TestVortexT1Starts = {}

TestVortexT1Starts.setUp = setUp

local STARTS = {
	{ screen = "mission1_failed", n = 1 }, { screen = "m1_frontier", n = 1 }, { screen = "m1_glorious", n = 1 }, { screen = "m1_four_point", n = 1 },
	{ screen = "mission2_failed", n = 2 }, { screen = "m2_why_not", n = 2 }, { screen = "m2_um_yes", n = 2 }, { screen = "m2_good_to_hear", n = 2 },
	{ screen = "mission3_failed", n = 3 }, { screen = "m3_thank_maker", n = 3 }, { screen = "m3_good_luck", n = 3 }, { screen = "m3_critical", n = 3 },
	{ screen = "mission4_failed", n = 4 }, { screen = "m4_splendid", n = 4 }, { screen = "m4_rally", n = 4 }, { screen = "m4_tie_forces", n = 4 },
}

for _, s in ipairs(STARTS) do
	-- AC-7
	TestVortexT1Starts["test_" .. s.screen .. "_sets_attempted_and_starts_mission_" .. s.n] = function()
		local player = I.pilot({ paid = s.n - 1 })
		local spies = spyAll(HEADS)
		local t = I.drive(player, s.screen)

		lu.assertEquals(t[1].stop, I.screenRow(s.screen).stop, s.screen .. ": ends the conversation as Appendix A says")
		lu.assertEquals(started(spies), { HEADS[s.n] }, "quests started")
		lu.assertEquals(spies[HEADS[s.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_" .. s.n .. ":attempted"), "1", ":attempted of mission " .. s.n)
	end

	-- AC-7: the real head runs (the pilot sits in a ship in the quest zone)
	TestVortexT1Starts["test_" .. s.screen .. "_makes_the_real_head_quest_active"] = function()
		local player = I.pilot({ paid = s.n - 1, inShip = true, zone = "space_naboo" })
		local q = I.quest(HEADS[s.n])

		q:start()
		I.drive(player, s.screen)
		lu.assertEquals(I.state(player, HEADS[s.n]), "active", HEADS[s.n] .. ": journal entry after " .. s.screen)
	end
end

-- AC-7: the start screens leave the other missions' :attempted alone
function TestVortexT1Starts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = I.pilot({ paid = 1 })

	spyAll(HEADS)
	I.drive(player, "m2_why_not")
	lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_rebel_3:attempted"), "mission 3")
	lu.assertNil(H.getQuestStatus(player, "naboo_rebel_4:attempted"), "mission 4")
end

-- AC-7: showing a non-start screen of an offer starts nothing
function TestVortexT1Starts:test_the_offer_and_briefing_screens_before_the_accept_start_nothing()
	local spies = spyAll(HEADS)

	for _, screen in ipairs({ "mission1_offer", "first_assignment", "m1_health", "m1_not_yet", "m1_pirates", "mission2_offer", "m2_thin", "m2_not_so_fast", "mission3_offer", "m3_not_yet", "m3_agreed",
		"mission4_offer", "m4_job", "m4_know_pilot", "m4_word" }) do
		I.drive(I.pilot({ paid = 0 }), screen)
	end

	lu.assertEquals(started(spies), {}, "quests started by those screens")
end

---------------------------------------------------------------------------------------------
-- AC-7: an abort is a failure (FI-4); the datapad abort and the plain failure open the same screen; a lost surprise attack too (D-6)
---------------------------------------------------------------------------------------------

TestVortexT1Abort = {}

TestVortexT1Abort.setUp = setUp

function TestVortexT1Abort:tearDown() AC.tearDown() end

local ABORTS = {
	{ n = 1, accept = "m1_frontier", failed = "mission1_failed" },
	{ n = 2, accept = "m2_why_not", failed = "mission2_failed" },
	{ n = 3, accept = "m3_good_luck", failed = "mission3_failed" },
	{ n = 4, accept = "m4_splendid", failed = "mission4_failed" },
}

-- a pilot in a ship in space_naboo whose mission n was started by the accept screen
local function running(a)
	local player = I.pilot({ paid = a.n - 1, inShip = true, zone = "space_naboo" })
	local q = I.quest(HEADS[a.n])

	q:start()
	I.drive(player, a.accept)
	lu.assertEquals(I.state(player, HEADS[a.n]), "active", "precondition: mission " .. a.n .. " is running")

	return q, player
end

for _, a in ipairs(ABORTS) do
	-- AC-7
	TestVortexT1Abort["test_aborting_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)

		q:abortQuest(player)
		lu.assertEquals(I.state(player, HEADS[a.n]), "none", "the run ended without a completed entry")
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end

	-- AC-7: the datapad path
	TestVortexT1Abort["test_the_datapad_abort_of_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)
		local id = I.IDENTITY[HEADS[a.n]]

		H.abortMission(player, id.type, id.name)
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end

	-- AC-7: the failure screen after an abort restarts the run
	TestVortexT1Abort["test_the_failure_screen_after_aborting_mission_" .. a.n .. "_starts_the_real_run_again"] = function()
		local q, player = running(a)

		q:abortQuest(player)
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk opens the failure screen")
		lu.assertEquals(I.state(player, HEADS[a.n]), "active", "mission " .. a.n .. " runs again after the failure screen showed")
		lu.assertEquals(I.firstScreen(player), a.n == 1 and "first_mission_help" or "on_mission", "the next talk while it runs")
	end
end

-- AC-7: a mission 2 run that failed (not aborted) opens the same screen
function TestVortexT1Abort:test_a_mission_2_run_that_failed_without_an_abort_opens_mission2_failed()
	local q, player = running(ABORTS[2])

	q:failQuest(player, true)
	lu.assertEquals(I.state(player, I.M2), "none", "the run ended")
	lu.assertEquals(I.firstScreen(player), "mission2_failed", "the next talk")
end

-- AC-7: no marker key exists: the abort writes no :aborted status
function TestVortexT1Abort:test_aborting_mission_2_leaves_no_aborted_marker()
	local q, player = running(ABORTS[2])

	q:abortQuest(player)
	lu.assertNil(H.getQuestStatus(player, "naboo_rebel_2:aborted"), "no aborted marker (FI-4: abort is failure)")
end

-- AC-7, D-6 (FI-5): the patrol is won, the surprise attack starts and is failed: the next talk opens mission1_failed (SWG would show the offer)
function TestVortexT1Abort:test_a_lost_surprise_attack_opens_mission1_failed()
	local q, player = running(ABORTS[1])
	local s1 = I.quest(I.S1)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	H.advance(14000)
	lu.assertTrue(I.state(player, I.S1) == "active", "precondition: the surprise attack started after point 2 and 13 s")

	s1:failQuest(player, true)
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack run ended")
	lu.assertEquals(I.firstScreen(player), "mission1_failed", "the next talk: the failure line, not the first-mission offer (D-6)")
end

---------------------------------------------------------------------------------------------
-- AC-5, AC-6, D-13 (FI-8): the brush-offs and the droid's sparks
---------------------------------------------------------------------------------------------

TestVortexT1BrushOffs = {}

TestVortexT1BrushOffs.setUp = setUp

-- the sparks the droid plays: playClientEffectLoc(player, file, zone name, x, z, y, cell id) at the NPC's position
local function assertSparks(player, n, label)
	local calls = I.sparks()

	lu.assertEquals(#calls, n, label .. ": playClientEffectLoc calls")

	for i, c in ipairs(calls) do
		lu.assertEquals({ c[1], c[2], c[3], c[4], c[5], c[6], c[7] },
			{ player, I.SPARKS_EFFECT, I.NPC_AT.zone, I.NPC_AT.x, I.NPC_AT.z, I.NPC_AT.y, I.NPC_AT.parentID }, label .. ": arguments of call " .. i .. " (player, effect, zone, x, z, y, cell)")
		lu.assertEquals(c.n, 7, label .. ": seven arguments (the binding reads seven stack slots)")
	end
end

-- AC-6, D-13
function TestVortexT1BrushOffs:test_no_jtl_plays_the_sparks_once()
	H.Engine.config.jtlEnabled = false

	local player = I.pilot()
	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "no_jtl" }, "screens shown")
	assertSparks(player, 1, "no_jtl")
end

-- AC-6, D-13, R-2: the effect carries the droid's own cell, not a constant 0
function TestVortexT1BrushOffs:test_the_sparks_are_played_in_the_droids_cell()
	H.Engine.config.jtlEnabled = false

	local at = { zone = I.NPC_AT.zone, x = 12.5, z = 1.25, y = -7.75, parentID = 1234567 }
	local player = I.pilot()
	local t = I.talk(player, nil, at)
	local calls = I.sparks()

	lu.assertEquals(I.ids(t), { "no_jtl" }, "screens shown")
	lu.assertEquals(#calls, 1, "playClientEffectLoc calls")
	lu.assertEquals({ calls[1][1], calls[1][2], calls[1][3], calls[1][4], calls[1][5], calls[1][6], calls[1][7] },
		{ player, I.SPARKS_EFFECT, at.zone, at.x, at.z, at.y, at.parentID }, "arguments (player, effect, zone, x, z, y, cell)")
end

-- AC-6, D-13
function TestVortexT1BrushOffs:test_a_privateer_pilot_asking_about_training_sees_the_sparks_on_privateer_training_only()
	local player = I.pilot({ pilot = "neutral", squadron = false })
	local t = I.talk(player, { "s_1a53f653" })

	lu.assertEquals(I.ids(t), { "privateer_pilot", "privateer_training" }, "screens shown")
	assertSparks(player, 1, "privateer_training")

	H.reset()

	local other = I.pilot({ pilot = "neutral", squadron = false })

	I.talk(other, { "s_b26194cb" })
	lu.assertEquals(#I.sparks(), 0, "privateer_doing: no sparks")
	H.reset()
	I.talk(I.pilot({ pilot = "neutral", squadron = false }), { "s_ca776e30" })
	lu.assertEquals(#I.sparks(), 0, "privateer_who: no sparks")
end

-- AC-6: the rest of the privateer branch
function TestVortexT1BrushOffs:test_the_privateer_branch_walks_to_its_endings()
	walk({ name = "privateer smuggler", pilot = { pilot = "neutral", squadron = false }, first = "privateer_pilot", choices = { "s_1a53f653", "s_f60c8a5" } })
	walk({ name = "privateer forget", pilot = { pilot = "neutral", squadron = false }, first = "privateer_pilot", choices = { "s_1a53f653", "s_900f01d1" } })
	walk({ name = "privateer doing", pilot = { pilot = "neutral", squadron = false }, first = "privateer_pilot", choices = { "s_b26194cb" } })
	walk({ name = "privateer who", pilot = { pilot = "neutral", squadron = false }, first = "privateer_pilot", choices = { "s_ca776e30" } })
end

-- AC-6, D-13
function TestVortexT1BrushOffs:test_an_imperial_asking_for_answers_sees_the_sparks_on_imperial_answers_only()
	local player = I.pilot({ pilot = false, faction = "imperial", squadron = false })
	local t = I.talk(player, { "s_c16bab26" })

	lu.assertEquals(I.ids(t), { "imperial_pilot", "imperial_answers" }, "screens shown")
	assertSparks(player, 1, "imperial_answers")

	H.reset()
	I.talk(I.pilot({ pilot = false, faction = "imperial", squadron = false }), { "s_a425f33d" })
	lu.assertEquals(#I.sparks(), 0, "imperial_no_use: no sparks")
	H.reset()
	I.talk(I.pilot({ pilot = false, faction = "imperial", squadron = false }), { "s_9f6cf52" })
	lu.assertEquals(#I.sparks(), 0, "imperial_glare: no sparks")
end

-- AC-6
function TestVortexT1BrushOffs:test_the_imperial_branch_walks_to_its_endings()
	walk({ name = "imperial no use", pilot = { pilot = false, faction = "imperial", squadron = false }, first = "imperial_pilot", choices = { "s_a425f33d" } })
	walk({ name = "imperial glare", pilot = { pilot = false, faction = "imperial", squadron = false }, first = "imperial_pilot", choices = { "s_9f6cf52" } })
end

-- D-13: nothing else sparks: no other screen of Appendix A plays the effect
function TestVortexT1BrushOffs:test_no_other_screen_plays_the_effect()
	local sparkling = { no_jtl = true, privateer_training = true, imperial_answers = true }

	for _, row in ipairs(I.SCREENS) do
		H.reset()
		spyAll(ALL)
		I.drive(I.pilot({ paid = 4, tier = 1, xp = 99999 }), row.id)
		lu.assertEquals(#I.sparks(), sparkling[row.id] and 1 or 0, "screen '" .. row.id .. "': playClientEffectLoc calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: duties
---------------------------------------------------------------------------------------------

TestVortexT1Duties = {}

TestVortexT1Duties.setUp = setUp

local DUTY_PILOT = { paid = 4, tier = 1 }

-- AC-7: the destroy duty on track, by gender
function TestVortexT1Duties:test_a_pilot_after_mission_4_starts_the_destroy_duty_by_gender()
	for gender, screen in pairs({ [0] = "destroy_duty_male", [1] = "destroy_duty_female" }) do
		H.reset()

		local t = walk({ name = "destroy duty, gender " .. gender, pilot = { paid = 4, tier = 1, gender = gender }, ids = { "duty_missions", "duty_menu", screen },
			choices = { "s_4ffd4b9d", "s_cf63ee80" }, starts = { I.DUTY6 } })

		lu.assertTrue(t[#t].stop, screen .. " ends")
	end
end

-- AC-7
function TestVortexT1Duties:test_a_pilot_after_mission_4_starts_the_escort_duty()
	local t = walk({ name = "escort duty", pilot = DUTY_PILOT, first = "duty_missions", choices = { "s_4ffd4b9d", "s_a66ff602" }, starts = { I.DUTY7 } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "escort_duty" }, "screens shown")
	lu.assertTrue(t[#t].stop, "escort_duty ends")
end

-- AC-7: the duty explanation leads back to the same three replies and on to a duty
function TestVortexT1Duties:test_the_duty_explanation_leads_back_to_the_menu_and_a_duty()
	walk({ name = "duty explained", pilot = DUTY_PILOT, ids = { "duty_missions", "duty_explained", "duty_menu", "destroy_duty_male" }, choices = { "s_6106187c", "s_4ffd4b9d", "s_cf63ee80" }, starts = { I.DUTY6 } })
end

-- AC-7: the menu alone starts nothing, and only the duty screens start duties
function TestVortexT1Duties:test_the_menu_and_the_explanation_start_nothing()
	walk({ name = "menu only", pilot = DUTY_PILOT, first = "duty_missions", choices = { "s_4ffd4b9d" } })
	walk({ name = "explanation only", pilot = DUTY_PILOT, first = "duty_missions", choices = { "s_6106187c" } })
end

-- AC-7: the ground-forces branch of the duty screen
function TestVortexT1Duties:test_the_ground_forces_branch_ends_at_the_recruiter()
	local t = walk({ name = "enlist ground", pilot = DUTY_PILOT, first = "duty_missions", choices = { "s_761039fa", "s_e5f13c4" } })

	lu.assertEquals(I.ids(t), { "duty_missions", "enlist_ground", "enlist_recruiter" }, "screens shown")
	lu.assertTrue(t[3].stop, "enlist_recruiter ends")
end

-- AC-7: the real duty starts when the pilot sits in a ship in the quest zone
function TestVortexT1Duties:test_the_duty_screens_start_the_real_duties()
	for screen, global in pairs({ destroy_duty_male = I.DUTY6, destroy_duty_female = I.DUTY6, escort_duty = I.DUTY7 }) do
		H.reset()

		local player = I.pilot({ paid = 4, tier = 1, inShip = true, zone = "space_naboo" })

		I.quest(global):start()
		I.drive(player, screen)
		lu.assertEquals(I.state(player, global), "active", global .. ": journal entry after " .. screen)
	end
end

-- AC-7: a pilot with a running duty never reaches the duty screens (G9)
function TestVortexT1Duties:test_a_pilot_on_a_duty_opens_on_mission_and_starts_no_second_duty()
	local spies = spyAll({ I.DUTY6, I.DUTY7 })
	local t = I.talk(I.pilot({ paid = 4, tier = 1, duty = I.DUTY6 }))

	lu.assertEquals(I.ids(t), { "on_mission" }, "screens shown")
	lu.assertEquals(started(spies), {}, "nothing starts")
end

-- AC-10 (FI-9): graduates are offered no duties
function TestVortexT1Duties:test_graduates_reach_no_duty_screen()
	local seen = {}
	local queue = { { "graduated" } }

	while #queue > 0 do
		local path = table.remove(queue)
		local id = path[#path]

		if not seen[id] then
			seen[id] = true

			for _, o in ipairs(I.screenRow(id).options) do
				queue[#queue + 1] = { o[2] }
			end
		end
	end

	for id in pairs(seen) do
		lu.assertFalse(id:find("duty") ~= nil or id == "enlist_ground" or id == "duty_menu", "graduated reaches '" .. id .. "'")
	end
end
