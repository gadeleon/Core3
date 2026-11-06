-- Lt. Akal Colzet: sign-up, the four mission offers, briefings, failures and retries (an abort is a failure) and the duty hand-outs.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-5, AC-7; Conversation flow 3 (table H) and 4; Appendix A; FI-4).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (storm_tier1_screens_data.lua)
-- unless a conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("storm_tier1_data")
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

-- exactly one grantStarterShip(player, "imperial")
local function assertOneShip(player)
	local calls = H.Engine.callsTo("grantStarterShip")

	lu.assertEquals(#calls, 1, "grantStarterShip calls")
	lu.assertTrue(calls[1][1] == player and calls[1][2] == "imperial", "the starter ship is an imperial one for the pilot")
end

local function novice(player)
	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2] == I.NOVICE then
			return true
		end
	end

	return false
end

TestStormT1SignUp = {}

TestStormT1SignUp.setUp = setUp

local function nonPilot(o)
	o = o or {}
	o.pilot, o.squadron, o.pilotTier = false, false, 0

	return I.pilot(o)
end

-- The ways to an oath screen (each of the three routes, with its branches): { choices up to and including the reply that shows the oath, ids shown, the oath screen,
-- the reply that leaves it, the ship-grant screen C-2 shows, the reply that leaves that }
local ROUTE_A = { oath = "recruit_sworn", leave = "s_987445c9", ship = "recruit_ship_granted", shipLeave = "s_987445c9" }
local ROUTE_B = { oath = "recruit_sworn_pay", leave = "s_860c425d", ship = "recruit_ship_granted_bust", shipLeave = "s_7796b57c" }
local ROUTE_C = { oath = "recruit_sworn_will", leave = "s_670201ae", ship = "recruit_ship_granted", shipLeave = "s_987445c9" }

local function merge(a, b)
	for k, v in pairs(b) do
		a[k] = v
	end

	return a
end

local OATHS = {
	merge({ name = "navy_direct", choices = { "s_11fcdd9f", "s_c124ad4f", "s_68c831e7" }, ids = { "recruitment", "recruit_navy", "recruit_sure", "recruit_sworn" } }, ROUTE_A),
	merge({ name = "navy_via_volunteers", choices = { "s_11fcdd9f", "s_388cfea9", "s_22564d44", "s_68c831e7" }, ids = { "recruitment", "recruit_navy", "recruit_volunteers", "recruit_sure", "recruit_sworn" } }, ROUTE_A),
	merge({ name = "pay_direct", choices = { "s_42bfca2f", "s_8df7dba2", "s_3d5b4720", "s_5c4e4259", "s_e92da88" },
		ids = { "recruitment", "recruit_pay", "recruit_scum", "recruit_outsource", "recruit_pay_sure", "recruit_sworn_pay" } }, ROUTE_B),
	merge({ name = "pay_via_patriot", choices = { "s_42bfca2f", "s_9ef7bea1", "s_a4622f42", "s_3d5b4720", "s_5c4e4259", "s_e92da88" },
		ids = { "recruitment", "recruit_pay", "recruit_patriot", "recruit_scum", "recruit_outsource", "recruit_pay_sure", "recruit_sworn_pay" } }, ROUTE_B),
	merge({ name = "stare_direct", choices = { "s_5e6be58d", "s_13a199af", "s_bc1c993d", "s_7611fee0" }, ids = { "recruitment", "recruit_stare", "recruit_greatest", "recruit_honored", "recruit_sworn_will" } }, ROUTE_C),
	merge({ name = "stare_via_doctrine", choices = { "s_5e6be58d", "s_cbfb3200", "s_5cd3c77", "s_21309acb", "s_c3e56b53", "s_eee17bb3", "s_7611fee0" },
		ids = { "recruitment", "recruit_stare", "recruit_doctrine", "recruit_faith", "recruit_no_inquisitor", "recruit_busy", "recruit_honored", "recruit_sworn_will" } }, ROUTE_C),
	merge({ name = "stare_doctrine_then_greatest", choices = { "s_5e6be58d", "s_cbfb3200", "s_5cd3c77", "s_21309acb", "s_c3e56b53", "s_13a199af", "s_bc1c993d", "s_7611fee0" },
		ids = { "recruitment", "recruit_stare", "recruit_doctrine", "recruit_faith", "recruit_no_inquisitor", "recruit_busy", "recruit_greatest", "recruit_honored", "recruit_sworn_will" } }, ROUTE_C),
}

for _, w in ipairs(OATHS) do
	-- AC-7: each oath screen grants the novice box, the squadron and tier 1; C-2 shows the ship grant for a pilot without a ship
	TestStormT1SignUp["test_the_" .. w.name .. "_route_grants_the_box_the_squadron_tier_1_and_one_tie_to_a_pilot_without_a_ship"] = function()
		local player = nonPilot({ ship = false })
		local t = I.talk(player, concat(w.choices, { w.leave, w.shipLeave }))

		lu.assertEquals(I.ids(t), concat(w.ids, { w.ship, "first_assignment" }), "screens shown")
		lu.assertTrue(novice(player), "the novice box pilot_imperial_navy_novice was granted free (awardSkill)")
		lu.assertEquals(player.ghost.squadronType, STORM_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
		assertOneShip(player)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: a pilot who still has a ship goes straight to first_assignment and gets none
	TestStormT1SignUp["test_the_" .. w.name .. "_route_skips_the_ship_grant_for_a_pilot_with_a_ship"] = function()
		local player = nonPilot()
		local t = I.talk(player, concat(w.choices, { w.leave }))

		lu.assertEquals(I.ids(t), concat(w.ids, { "first_assignment" }), "screens shown")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship")
		lu.assertTrue(novice(player), "the novice box was still granted")
		lu.assertEquals(player.ghost.squadronType, STORM_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	end

	-- AC-7: nothing is granted before the oath screen
	TestStormT1SignUp["test_the_" .. w.name .. "_route_grants_nothing_before_the_oath"] = function()
		local player = nonPilot({ ship = false })

		I.talk(player, { table.unpack(w.choices, 1, #w.choices - 1) })
		lu.assertFalse(novice(player), "no novice box before the oath")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron before the oath")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	end
end

-- AC-7: the whole sign-up of a pilot without a ship, through the first mission
function TestStormT1SignUp:test_an_imperial_non_pilot_without_a_ship_signs_up_gets_the_box_the_squadron_the_tie_and_mission_1()
	local choices = { "s_11fcdd9f", "s_c124ad4f", "s_68c831e7", "s_987445c9", "s_987445c9", "s_aaa6ec13", "s_16244233", "s_a8c82b1c", "s_83d1f7de" }
	local player = nonPilot({ ship = false })
	local spies = spyAll(HEADS)
	local t = I.talk(player, choices)

	lu.assertEquals(I.ids(t), { "recruitment", "recruit_navy", "recruit_sure", "recruit_sworn", "recruit_ship_granted", "first_assignment", "mission1_salute", "mission1_overstep", "mission1_pcr", "mission1_accept" },
		"screens shown")
	lu.assertTrue(novice(player), "the novice box was granted free")
	lu.assertEquals(player.ghost.squadronType, STORM_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	assertOneShip(player)
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: a pilot who already holds a higher pilot tier keeps it
function TestStormT1SignUp:test_the_oath_does_not_lower_a_higher_pilot_tier()
	local player = nonPilot({ pilotTier = 2 })

	player.ghost.pilotTier = 2
	I.talk(player, { "s_11fcdd9f", "s_c124ad4f", "s_68c831e7" })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier stays 2 (raised to 1 only if below)")
end

-- AC-7: every refusal ending grants nothing
local REFUSALS = {
	{ name = "recruit_declined_after_sure", choices = { "s_11fcdd9f", "s_c124ad4f", "s_37eb1d12" }, last = "recruit_declined" },
	{ name = "recruit_declined_after_volunteers", choices = { "s_11fcdd9f", "s_388cfea9", "s_37eb1d12" }, last = "recruit_declined" },
	{ name = "recruit_thrown_out", choices = { "s_42bfca2f", "s_8df7dba2", "s_3d5b4720", "s_5c4e4259", "s_65dcd253" }, last = "recruit_thrown_out" },
	{ name = "recruit_not_will", choices = { "s_5e6be58d", "s_13a199af", "s_bc1c993d", "s_5c709097" }, last = "recruit_not_will" },
	{ name = "recruit_other_things", choices = { "s_5e6be58d", "s_13a199af", "s_b737f77e" }, last = "recruit_other_things" },
}

for _, r in ipairs(REFUSALS) do
	-- AC-7
	TestStormT1SignUp["test_the_refusal_" .. r.name .. "_ends_and_grants_nothing"] = function()
		local player = nonPilot({ ship = false })
		local t = I.talk(player, r.choices)

		lu.assertEquals(t[#t].id, r.last, "last screen")
		lu.assertTrue(t[#t].stop, r.last .. " ends the conversation")
		lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier unchanged")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the lost-ship branch (a member who lost the ship)
function TestStormT1SignUp:test_a_member_who_lost_the_ship_gets_one_new_starter_ship()
	local player = I.pilot({ ship = false })
	local t = I.talk(player, { "s_7d477c70", "s_8efde2ae" })

	lu.assertEquals(I.ids(t), { "lost_ship", "lost_ship_confirm", "lost_ship_granted" }, "screens shown")
	lu.assertTrue(t[3].stop, "lost_ship_granted ends")
	assertOneShip(player)
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7
function TestStormT1SignUp:test_declining_the_replacement_ship_grants_nothing()
	local player = I.pilot({ ship = false })
	local t = I.talk(player, { "s_7d477c70", "s_169df3bb" })

	lu.assertEquals(I.ids(t), { "lost_ship", "lost_ship_confirm", "lost_ship_declined" }, "screens shown")
	lu.assertTrue(t[3].stop, "lost_ship_declined ends")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
end

-- AC-7: the grant on display needs the pilot to lack a certified ship
function TestStormT1SignUp:test_the_ship_grant_screens_give_nothing_to_a_pilot_who_has_a_ship()
	for _, screen in ipairs({ "recruit_ship_granted", "recruit_ship_granted_bust", "lost_ship_granted" }) do
		H.reset()
		I.drive(I.pilot(), screen)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, screen .. ": a pilot with a certified ship gets no second one")
	end
end

-- AC-7: the ship-grant screens give one ship to a pilot without one
function TestStormT1SignUp:test_the_ship_grant_screens_give_one_imperial_starter_ship_to_a_pilot_without_one()
	for _, screen in ipairs({ "recruit_ship_granted", "recruit_ship_granted_bust", "lost_ship_granted" }) do
		H.reset()

		local player = I.pilot({ ship = false })

		I.drive(player, screen)
		assertOneShip(player)
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: mission offers, briefings and starts
---------------------------------------------------------------------------------------------

TestStormT1Offers = {}

TestStormT1Offers.setUp = setUp

local WALKS = {
	{ name = "mission_1_first_assignment_salute", pilot = {}, first = "mission1_offer", choices = { "s_aaa6ec13", "s_16244233", "s_a8c82b1c", "s_83d1f7de", "s_a3b6d1bc" }, starts = { I.P1 } },
	{ name = "mission_1_dont_salute", pilot = {}, first = "mission1_offer", choices = { "s_2a1015e6", "s_d51ef84a", "s_976cba8a", "s_780a9b6f", "s_78dbec92" }, starts = { I.P1 } },
	{ name = "mission_1_for_the_emperor", pilot = {}, first = "mission1_offer", choices = { "s_8cd3467e", "s_83ea480b", "s_66ac46dc", "s_2562a051" }, starts = { I.P1 } },
	{ name = "mission_1_ready_for_training_loop", pilot = {}, first = "mission1_offer", choices = { "s_f43f3569", "s_f43f3569", "s_aaa6ec13", "s_16244233", "s_a8c82b1c", "s_83d1f7de" }, starts = { I.P1 } },
	{ name = "mission_2_first_route", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_a1088c08", "s_c08929f2" }, starts = { I.M2 } },
	{ name = "mission_2_spice_route", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_ae6ab110", "s_3ca32099" }, starts = { I.M2 } },
	{ name = "mission_2_destined_route", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_d8a302bc", "s_25d6b961" }, starts = { I.M2 } },
	{ name = "mission_2_no_training_loop", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_d9d4feec", "s_d9d4feec", "s_a1088c08" }, starts = { I.M2 } },
	{ name = "mission_3_not_fail_route", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_6d8d3e00", "s_8efde2ae", "s_60c81a4c", "s_83d1f7de", "s_16f8c58a" }, starts = { I.P3 } },
	{ name = "mission_3_team_route", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_63380f34", "s_627065f5", "s_d7816410", "s_16c1201f", "s_76de9d3f", "s_78dbec92" }, starts = { I.P3 } },
	{ name = "mission_3_specops_route", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_da07fb7a", "s_f3852d77", "s_b2995db3", "s_84047858", "s_989ea72c", "s_e4e8b551", "s_22451e60" }, starts = { I.P3 } },
	{ name = "mission_3_no_training_loop", pilot = { paid = 2 }, first = "mission3_offer", choices = { "s_f43f3569", "s_f43f3569", "s_6d8d3e00" } },
	{ name = "mission_4_located_route", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_8efde2ae", "s_83d1f7de", "s_2c3d0c07" }, starts = { I.A4 } },
	{ name = "mission_4_special_route", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_b2b35c1f", "s_f4fa11bb", "s_7e347138" }, starts = { I.A4 } },
	{ name = "mission_4_worthy_route", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_523f6698", "s_6942ec7e", "s_a2d4dd9d" }, starts = { I.A4 } },
	{ name = "mission_4_no_training_loop", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_9237617f", "s_9237617f", "s_8efde2ae", "s_83d1f7de" }, starts = { I.A4 } },
}

for _, w in ipairs(WALKS) do
	-- AC-7
	TestStormT1Offers["test_walk_" .. w.name] = function()
		w.pilot = w.pilot or {}
		walk(w)
	end
end

-- AC-7: first_assignment (after the oath) offers the same four mission 1 routes as mission1_offer
function TestStormT1Offers:test_first_assignment_offers_the_four_mission_1_routes()
	local t = I.drive(I.pilot(), "first_assignment")

	lu.assertEquals(I.optionSids(t[1]), { "s_aaa6ec13", "s_2a1015e6", "s_8cd3467e", "s_f43f3569" }, "replies")
	lu.assertEquals(I.linksOf(t[1]), { "mission1_salute", "mission1_no_salute", "mission1_emperor", "mission1_prove" }, "links")
end

-- AC-7: the exact last screens of the accepted routes end the conversation
function TestStormT1Offers:test_the_briefing_endings_end_the_conversation()
	for _, last in ipairs({ "mission1_good_luck", "mission1_disgrace", "mission1_report", "mission2_spirit", "mission2_overconfidence", "mission2_enthusiasm", "mission3_excellent",
		"mission3_report", "mission3_serve", "mission4_guide", "mission4_bounty", "mission4_report" }) do
		H.reset()
		lu.assertTrue(I.drive(I.pilot({ paid = 0 }), last)[1].stop, last .. " ends the conversation")
	end
end

-- AC-7: mission 1 won and unpaid is answered by the report routes (the pay itself is tested in the reward file)
function TestStormT1Offers:test_mission_1_won_reports_lead_on_to_the_next_assignment_after_payment()
	local player = I.pilot({ state = "won" })
	local t = I.talk(player, { "s_ee91723f", "s_b3753189", "s_987445c9" })

	lu.assertEquals(I.ids(t), { "mission1_won", "mission1_pirates", "mission1_pay_hazard", "mission1_another_duty" }, "screens shown")
	lu.assertEquals(I.firstScreen(player), "mission2_offer", "the next talk offers mission 2")
end

-- AC-7: the ground-forces branch of the duty screen
function TestStormT1Offers:test_the_ground_forces_branch_ends_at_the_recruiter()
	local t = walk({ name = "enlist ground", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_cdbce743", "s_f195b141" } })

	lu.assertEquals(I.ids(t), { "duty_missions", "enlist_ground", "enlist_recruiter" }, "screens shown")
	lu.assertTrue(t[3].stop, "enlist_recruiter ends")
	lu.assertEquals(t[1].options[4] and t[1].options[4].text, I.PREFIX .. "s_cdbce743", "the ground reply is the fourth reply of duty_missions")
end

---------------------------------------------------------------------------------------------
-- AC-7: failures and retries
---------------------------------------------------------------------------------------------

TestStormT1Failures = {}

TestStormT1Failures.setUp = setUp

local FAILS = {
	{ n = 1, screen = "mission1_failed", retry = { "s_16fc739e", "s_59c8db72" }, later = { "s_16fc739e", "s_cb99174" }, retryId = "mission1_retry", laterId = "mission1_later" },
	{ n = 2, screen = "mission2_failed", retry = { "s_1768c7c4" }, later = { "s_19288eda" }, retryId = "mission2_retry", laterId = "mission2_rethink" },
	{ n = 3, screen = "mission3_failed", retry = { "s_d4dd5a28", "s_28586fd5" }, later = { "s_d4dd5a28", "s_668cac00" }, retryId = "mission3_retry", laterId = "mission3_later" },
	{ n = 4, screen = "mission4_failed", retry = { "s_248cfc90", "s_28586fd5" }, later = { "s_248cfc90", "s_3de840b5" }, retryId = "mission4_retry", laterId = "mission4_later" },
}

for _, f in ipairs(FAILS) do
	-- AC-7
	TestStormT1Failures["test_mission_" .. f.n .. "_failed_opens_the_failure_screen_and_the_retry_restarts_the_mission"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = I.talk(player, f.retry)

		lu.assertEquals(t[1].id, f.screen, "first screen")
		lu.assertEquals(t[#t].id, f.retryId, "last screen")
		lu.assertTrue(t[#t].stop, f.retryId .. " ends the conversation")
		lu.assertEquals(started(spies), { HEADS[f.n] }, "the head of mission " .. f.n .. " started once")
		lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_" .. f.n .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7
	TestStormT1Failures["test_mission_" .. f.n .. "_failed_and_later_ends_without_a_restart"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = I.talk(player, f.later)

		lu.assertEquals(t[#t].id, f.laterId, "last screen")
		lu.assertTrue(t[#t].stop, f.laterId .. " ends the conversation")
		lu.assertEquals(started(spies), {}, "nothing started")
	end
end

-- AC-7: mission 1's second retry line restarts it as well
function TestStormT1Failures:test_mission_1_retry_again_restarts_the_mission()
	local player = I.pilot({ state = "failed" })
	local spies = spyAll(HEADS)
	local t = I.talk(player, { "s_16fc739e", "s_f91b288f" })

	lu.assertEquals(I.ids(t), { "mission1_failed", "mission1_no_excuses", "mission1_retry_again" }, "screens shown")
	lu.assertTrue(t[3].stop, "mission1_retry_again ends")
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 started once")
end

-- AC-7: "clearing a stale run first"
function TestStormT1Failures:test_the_retry_clears_the_failed_runs_leftover_journal_entries_before_starting()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")

	local spies = spyAll(HEADS)

	I.drive(player, "mission1_retry")
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 restarted")
	lu.assertEquals(I.state(player, I.P1), "none", "the stale patrol entry is cleared")
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack entry is cleared")
end

-- AC-7: the same for mission 3's two entries
function TestStormT1Failures:test_the_mission_3_retry_clears_the_patrol_and_the_escort_entries()
	local player = I.pilot({ paid = 2, state = "failed" })

	I.setState(player, I.P3, "complete")
	I.setState(player, I.E3, "complete")

	local spies = spyAll(HEADS)

	I.drive(player, "mission3_retry")
	lu.assertEquals(started(spies), { I.P3 }, "mission 3 restarted")
	lu.assertEquals(I.state(player, I.P3), "none", "the stale patrol entry is cleared")
	lu.assertEquals(I.state(player, I.E3), "none", "the stale escort entry is cleared")
end

-- AC-7: a running chain is never restarted underneath the pilot
function TestStormT1Failures:test_a_start_screen_does_not_restart_a_running_mission()
	local player = I.pilot({ state = "active" })
	local spies = spyAll(HEADS)

	I.drive(player, "mission1_accept")
	lu.assertEquals(started(spies), {}, "mission 1 is active: no second start")
end

---------------------------------------------------------------------------------------------
-- AC-7: every start screen sets :attempted and starts its chain head (table H)
---------------------------------------------------------------------------------------------

TestStormT1Starts = {}

TestStormT1Starts.setUp = setUp

local STARTS = {
	{ screen = "mission1_accept", n = 1 }, { screen = "mission1_accept_patrol_only", n = 1 }, { screen = "mission1_accept_warrior", n = 1 },
	{ screen = "mission1_retry", n = 1 }, { screen = "mission1_retry_again", n = 1 },
	{ screen = "mission2_accept", n = 2 }, { screen = "mission2_accept_spice", n = 2 }, { screen = "mission2_accept_destined", n = 2 }, { screen = "mission2_retry", n = 2 },
	{ screen = "mission3_accept", n = 3 }, { screen = "mission3_accept_briefing", n = 3 }, { screen = "mission3_accept_petty", n = 3 }, { screen = "mission3_retry", n = 3 },
	{ screen = "mission4_accept", n = 4 }, { screen = "mission4_accept_bounty", n = 4 }, { screen = "mission4_worthy", n = 4 }, { screen = "mission4_retry", n = 4 },
}

-- the start screens that carry a reply do not end the conversation
local STARTS_WITH_REPLY = {
	mission1_accept = true, mission1_accept_patrol_only = true, mission1_accept_warrior = true,
	mission2_accept = true, mission2_accept_spice = true, mission2_accept_destined = true,
	mission3_accept = true, mission3_accept_briefing = true, mission3_accept_petty = true,
	mission4_accept = true, mission4_accept_bounty = true, mission4_worthy = true,
}

for _, s in ipairs(STARTS) do
	-- AC-7
	TestStormT1Starts["test_" .. s.screen .. "_sets_attempted_and_starts_mission_" .. s.n] = function()
		local player = I.pilot({ paid = s.n - 1 })
		local spies = spyAll(HEADS)
		local t = I.drive(player, s.screen)

		lu.assertEquals(t[1].stop, not STARTS_WITH_REPLY[s.screen], s.screen .. ": ends the conversation unless a reply follows")
		lu.assertEquals(started(spies), { HEADS[s.n] }, "quests started")
		lu.assertEquals(spies[HEADS[s.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_" .. s.n .. ":attempted"), "1", ":attempted of mission " .. s.n)
	end

	-- AC-7: the real head runs (the pilot sits in a ship in the quest zone)
	TestStormT1Starts["test_" .. s.screen .. "_makes_the_real_head_quest_active"] = function()
		local player = I.pilot({ paid = s.n - 1, inShip = true, zone = "space_tatooine" })
		local q = I.quest(HEADS[s.n])

		q:start()
		I.drive(player, s.screen)
		lu.assertEquals(I.state(player, HEADS[s.n]), "active", HEADS[s.n] .. ": journal entry after " .. s.screen)
	end
end

-- AC-7: the start screens leave the other missions' :attempted alone
function TestStormT1Starts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = I.pilot({ paid = 1 })

	spyAll(HEADS)
	I.drive(player, "mission2_accept")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertNil(H.getQuestStatus(player, "tatooine_imperial_3:attempted"), "mission 3")
	lu.assertNil(H.getQuestStatus(player, "tatooine_imperial_4:attempted"), "mission 4")
end

-- AC-7: showing a non-start screen of an offer starts nothing
function TestStormT1Starts:test_the_offer_and_briefing_screens_before_the_accept_start_nothing()
	local spies = spyAll(HEADS)

	for _, screen in ipairs({ "mission1_offer", "mission1_salute", "mission1_pcr", "mission2_offer", "mission3_offer", "mission3_not_fail", "mission3_team", "mission4_offer", "mission4_located", "mission4_special", "mission1_failed", "mission2_failed" }) do
		I.drive(I.pilot({ paid = 0 }), screen)
	end

	lu.assertEquals(started(spies), {}, "quests started by those screens")
end

---------------------------------------------------------------------------------------------
-- AC-7: an abort is a failure (FI-4); the datapad abort and the plain failure open the same screen
---------------------------------------------------------------------------------------------

TestStormT1Abort = {}

TestStormT1Abort.setUp = setUp

function TestStormT1Abort:tearDown() AC.tearDown() end

local ABORTS = {
	{ n = 1, accept = "mission1_accept", failed = "mission1_failed", retry = "mission1_retry" },
	{ n = 2, accept = "mission2_accept", failed = "mission2_failed", retry = "mission2_retry" },
	{ n = 3, accept = "mission3_accept", failed = "mission3_failed", retry = "mission3_retry" },
	{ n = 4, accept = "mission4_accept", failed = "mission4_failed", retry = "mission4_retry" },
}

-- a pilot in a ship in space_tatooine whose mission n was started by the accept screen
local function running(a)
	local player = I.pilot({ paid = a.n - 1, inShip = true, zone = "space_tatooine" })
	local q = I.quest(HEADS[a.n])

	q:start()
	I.drive(player, a.accept)
	lu.assertEquals(I.state(player, HEADS[a.n]), "active", "precondition: mission " .. a.n .. " is running")

	return q, player
end

for _, a in ipairs(ABORTS) do
	-- AC-7
	TestStormT1Abort["test_aborting_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)

		q:abortQuest(player)
		lu.assertEquals(I.state(player, HEADS[a.n]), "none", "the run ended without a completed entry")
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end

	-- AC-7: the datapad path
	TestStormT1Abort["test_the_datapad_abort_of_mission_" .. a.n .. "_makes_the_next_talk_open_" .. a.failed] = function()
		local q, player = running(a)
		local id = I.IDENTITY[HEADS[a.n]]

		H.abortMission(player, id.type, id.name)
		lu.assertEquals(I.firstScreen(player), a.failed, "the next talk")
	end

	-- AC-7: the retry after an abort restarts the run
	TestStormT1Abort["test_the_retry_after_aborting_mission_" .. a.n .. "_starts_the_real_run_again"] = function()
		local q, player = running(a)

		q:abortQuest(player)
		I.drive(player, a.retry)
		lu.assertEquals(I.state(player, HEADS[a.n]), "active", "mission " .. a.n .. " runs again")
		lu.assertEquals(I.firstScreen(player), a.n == 1 and "first_mission_help" or "on_mission", "the next talk while it runs")
	end
end

-- AC-7: a mission 2 run that failed (not aborted) opens the same screen
function TestStormT1Abort:test_a_mission_2_run_that_failed_without_an_abort_opens_mission2_failed()
	local q, player = running(ABORTS[2])

	q:failQuest(player, true)
	lu.assertEquals(I.state(player, I.M2), "none", "the run ended")
	lu.assertEquals(I.firstScreen(player), "mission2_failed", "the next talk")
end

-- AC-7: no marker key exists any more: the abort writes no :aborted status
function TestStormT1Abort:test_aborting_mission_2_leaves_no_aborted_marker()
	local q, player = running(ABORTS[2])

	q:abortQuest(player)
	lu.assertNil(H.getQuestStatus(player, "tatooine_imperial_2:aborted"), "no aborted marker (FI-4: abort is failure)")
end

---------------------------------------------------------------------------------------------
-- AC-7: duties
---------------------------------------------------------------------------------------------

TestStormT1Duties = {}

TestStormT1Duties.setUp = setUp

-- AC-7: the destroy duty on track
function TestStormT1Duties:test_a_pilot_after_mission_4_starts_the_destroy_duty()
	local t = walk({ name = "destroy duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_259013cd", "s_a490d2c6" }, starts = { I.DUTY6 } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertTrue(t[#t].stop, "duty_accepted ends")
end

-- AC-7
function TestStormT1Duties:test_a_pilot_after_mission_4_starts_the_escort_duty()
	local t = walk({ name = "escort duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_79ab4bbe", "s_a490d2c6" }, starts = { I.DUTY7 } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "escort_duty", "duty_accepted" }, "screens shown")
end

-- AC-7
function TestStormT1Duties:test_declining_a_duty_starts_nothing()
	walk({ name = "duty later", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_5ebce168" } })
	walk({ name = "duty explained, done for now", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_1091c96a" } })
end

-- AC-7: the duty explanation leads back to the menu
function TestStormT1Duties:test_the_duty_explanation_leads_to_the_duty_menu_and_a_duty()
	walk({ name = "duty explained", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_2d5d4bf0", "s_259013cd", "s_a490d2c6" }, starts = { I.DUTY6 } })
end

-- AC-7: "no training XP" ends the conversation
function TestStormT1Duties:test_the_no_training_reply_of_the_duty_screen_ends_the_conversation()
	local t = walk({ name = "no training xp", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_3b3aabc1" } })

	lu.assertTrue(t[2].stop, "no_training_xp ends")
end

-- AC-7: the off-track non-member's duty
function TestStormT1Duties:test_an_off_track_pilot_with_a_tier_1_skill_flies_a_duty_for_colzet()
	walk({ name = "off-track destroy duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_e814cf37", "s_259013cd", "s_a490d2c6" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty", "duty_accepted" }, starts = { I.DUTY6 } })
	walk({ name = "off-track escort duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_e814cf37", "s_79ab4bbe", "s_a490d2c6" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "escort_duty", "duty_accepted" }, starts = { I.DUTY7 } })
	walk({ name = "off-track declined", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_e87a40f8" },
		ids = { "non_member", "non_member_duty_offer", "non_member_declined" } })
end

-- AC-7: the duty menu's own decline
function TestStormT1Duties:test_duty_later_ends_without_a_start()
	local t = walk({ name = "duty menu later", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_5ebce168" } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "duty_later" }, "screens shown")
	lu.assertTrue(t[3].stop, "duty_later ends")
end

-- AC-7: the real duty starts when the pilot sits in a ship in the quest zone
function TestStormT1Duties:test_the_duty_screens_start_the_real_duties()
	for screen, global in pairs({ destroy_duty = I.DUTY6, escort_duty = I.DUTY7 }) do
		H.reset()

		local player = I.pilot({ paid = 4, tier = 1, inShip = true, zone = "space_tatooine" })

		I.quest(global):start()
		I.drive(player, screen)
		lu.assertEquals(I.state(player, global), "active", global .. ": journal entry after " .. screen)
	end
end
