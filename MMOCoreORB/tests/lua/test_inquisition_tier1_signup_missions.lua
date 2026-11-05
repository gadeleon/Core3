-- Lt. Barn Sinkko: sign-up, the four mission offers, briefings, failures and retries, mission 2's abort marker and the duty hand-outs.
-- Spec: .claude/work/inquisition-tier1-barn-sinkko/01-spec.md (AC-5, AC-7; Conversation flow 3 (table H) and 4; Appendix A; D-6, D-9).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (inquisition_tier1_screens_data.lua)
-- unless a conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local I = require("inquisition_tier1_data")
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

TestInquisitionT1SignUp = {}

TestInquisitionT1SignUp.setUp = setUp

local function nonPilot(o)
	o = o or {}
	o.pilot, o.squadron, o.pilotTier = false, false, 0

	return I.pilot(o)
end

-- The four ways to an oath screen: { choices up to and including the reply that shows the oath, ids shown, the oath screen, the reply that leaves it }
local OATHS = {
	{ name = "sign_up_direct", choices = { "s_b00e89d5", "s_88f723eb", "s_37650e5c" }, ids = { "recruitment", "recruit_sign_up", "recruit_sure", "recruit_sworn" }, oath = "recruit_sworn", leave = "s_987445c9" },
	{ name = "sign_up_via_volunteers", choices = { "s_b00e89d5", "s_388cfea9", "s_519c6a35", "s_37650e5c" },
		ids = { "recruitment", "recruit_sign_up", "recruit_volunteers", "recruit_sure", "recruit_sworn" }, oath = "recruit_sworn", leave = "s_987445c9" },
	{ name = "pay", choices = { "s_6df58958", "s_9c2b0ed7", "s_798ef1b", "s_e565620f", "s_b7bdfe36" },
		ids = { "recruitment", "recruit_pay", "recruit_noncombat", "recruit_why", "recruit_pay_sure", "recruit_sworn_pay" }, oath = "recruit_sworn_pay", leave = "s_f774e399" },
	{ name = "bust_rebel_heads", choices = { "s_6fc304c8", "s_cf68a5b5", "s_bc7d6b01", "s_c297a8d4", "s_6e71a8bb", "s_a9f55c8c" },
		ids = { "recruitment", "recruit_bust", "recruit_combat", "recruit_great_pilot", "recruit_most", "recruit_fly_shoot", "recruit_sworn_pay" }, oath = "recruit_sworn_pay", leave = "s_f774e399" },
}

for _, w in ipairs(OATHS) do
	-- AC-7: each oath screen grants the novice box, the squadron and tier 1; C-2 shows the ship grant for a pilot without a ship
	TestInquisitionT1SignUp["test_the_" .. w.name .. "_route_grants_the_box_the_squadron_tier_1_and_one_tie_to_a_pilot_without_a_ship"] = function()
		local player = nonPilot({ ship = false })
		local t = I.talk(player, concat(w.choices, { w.leave, "s_987445c9" }))

		lu.assertEquals(I.ids(t), concat(w.ids, { "recruit_ship_granted", "first_assignment" }), "screens shown")
		lu.assertTrue(novice(player), "the novice box pilot_imperial_navy_novice was granted free (awardSkill)")
		lu.assertEquals(player.ghost.squadronType, INQUISITION_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
		assertOneShip(player)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: a pilot who still has a ship goes straight to first_assignment and gets none
	TestInquisitionT1SignUp["test_the_" .. w.name .. "_route_skips_the_ship_grant_for_a_pilot_with_a_ship"] = function()
		local player = nonPilot()
		local t = I.talk(player, concat(w.choices, { w.leave }))

		lu.assertEquals(I.ids(t), concat(w.ids, { "first_assignment" }), "screens shown")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship")
		lu.assertTrue(novice(player), "the novice box was still granted")
		lu.assertEquals(player.ghost.squadronType, INQUISITION_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	end

	-- AC-7: nothing is granted before the oath screen
	TestInquisitionT1SignUp["test_the_" .. w.name .. "_route_grants_nothing_before_the_oath"] = function()
		local player = nonPilot({ ship = false })

		I.talk(player, { table.unpack(w.choices, 1, #w.choices - 1) })
		lu.assertFalse(novice(player), "no novice box before the oath")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron before the oath")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
	end
end

-- AC-7: the whole sign-up of a pilot without a ship, through the first mission
function TestInquisitionT1SignUp:test_an_imperial_non_pilot_without_a_ship_signs_up_gets_the_box_the_squadron_the_tie_and_mission_1()
	local choices = { "s_b00e89d5", "s_88f723eb", "s_37650e5c", "s_987445c9", "s_987445c9", "s_b6b25f13", "s_6047677", "s_a8c82b1c" }
	local player = nonPilot({ ship = false })
	local spies = spyAll(HEADS)
	local t = I.talk(player, choices)

	lu.assertEquals(I.ids(t), { "recruitment", "recruit_sign_up", "recruit_sure", "recruit_sworn", "recruit_ship_granted", "first_assignment", "mission1_test", "mission1_coords", "mission1_accept" }, "screens shown")
	lu.assertTrue(novice(player), "the novice box was granted free")
	lu.assertEquals(player.ghost.squadronType, INQUISITION_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
	assertOneShip(player)
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: a pilot who already holds a higher pilot tier keeps it
function TestInquisitionT1SignUp:test_the_oath_does_not_lower_a_higher_pilot_tier()
	local player = nonPilot({ pilotTier = 2 })

	player.ghost.pilotTier = 2
	I.talk(player, { "s_b00e89d5", "s_88f723eb", "s_37650e5c" })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier stays 2 (raised to 1 only if below)")
end

-- AC-7: every refusal ending grants nothing
local REFUSALS = {
	{ name = "sign_up_declined", choices = { "s_b00e89d5", "s_88f723eb", "s_37eb1d12" }, last = "recruit_declined" },
	{ name = "volunteers_declined", choices = { "s_b00e89d5", "s_388cfea9", "s_37eb1d12" }, last = "recruit_declined" },
	{ name = "pay_declined", choices = { "s_6df58958", "s_9c2b0ed7", "s_798ef1b", "s_e565620f", "s_f967fcee" }, last = "recruit_pay_declined" },
	{ name = "colzet", choices = { "s_6fc304c8", "s_cf68a5b5", "s_bc7d6b01", "s_c297a8d4", "s_6e71a8bb", "s_9d7bc2d3" }, last = "recruit_colzet" },
}

for _, r in ipairs(REFUSALS) do
	-- AC-7
	TestInquisitionT1SignUp["test_the_refusal_" .. r.name .. "_ends_and_grants_nothing"] = function()
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
function TestInquisitionT1SignUp:test_a_member_who_lost_the_ship_gets_one_new_starter_ship()
	local player = I.pilot({ ship = false })
	local t = I.talk(player, { "s_7d477c70", "s_8efde2ae" })

	lu.assertEquals(I.ids(t), { "lost_ship", "lost_ship_confirm", "lost_ship_granted" }, "screens shown")
	lu.assertTrue(t[3].stop, "lost_ship_granted ends")
	assertOneShip(player)
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7
function TestInquisitionT1SignUp:test_declining_the_replacement_ship_grants_nothing()
	local player = I.pilot({ ship = false })
	local t = I.talk(player, { "s_7d477c70", "s_169df3bb" })

	lu.assertEquals(I.ids(t), { "lost_ship", "lost_ship_confirm", "lost_ship_declined" }, "screens shown")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
end

-- AC-7: the grant on display needs the pilot to lack a certified ship
function TestInquisitionT1SignUp:test_the_ship_grant_screens_give_nothing_to_a_pilot_who_has_a_ship()
	for _, screen in ipairs({ "recruit_ship_granted", "lost_ship_granted" }) do
		H.reset()
		I.drive(I.pilot(), screen)
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, screen .. ": a pilot with a certified ship gets no second one")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: mission offers, briefings and starts
---------------------------------------------------------------------------------------------

TestInquisitionT1Offers = {}

TestInquisitionT1Offers.setUp = setUp

local WALKS = {
	{ name = "mission_1_offer_test_route", pilot = {}, first = "mission1_offer", choices = { "s_b6b25f13", "s_6047677", "s_a8c82b1c" }, starts = { I.P1 } },
	{ name = "mission_1_offer_credits_route", pilot = {}, first = "mission1_offer", choices = { "s_9bd7e7db", "s_bd5ec97c", "s_59c8db72", "s_d06e1eb", "s_a8c82b1c" }, starts = { I.P1 } },
	{ name = "mission_1_offer_what_route", pilot = {}, first = "mission1_offer", choices = { "s_5bc07030", "s_c7ca1c2c", "s_bb8aff15", "s_8efde2ae" }, starts = { I.P1 } },
	{ name = "mission_1_offer_train_when_loop", pilot = {}, first = "mission1_offer", choices = { "s_b39049de", "s_b39049de", "s_b6b25f13", "s_6047677", "s_a8c82b1c" }, starts = { I.P1 } },
	{ name = "mission_2_offer_orders", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_78d92576", "s_4aa87431", "s_6f12f083" }, starts = { I.M2 } },
	{ name = "mission_2_offer_pay", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_48d418c", "s_de1d8561" }, starts = { I.M2 } },
	{ name = "mission_2_offer_cocky", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_5ee0d552", "s_44a60f99" }, starts = { I.M2 } },
	{ name = "mission_2_offer_no_training_loop", pilot = { paid = 1 }, first = "mission2_offer", choices = { "s_8c9c5f1a", "s_8c9c5f1a", "s_78d92576", "s_4aa87431", "s_6f12f083" }, starts = { I.M2 } },
	{ name = "mission_3_offer_direct", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_37b6c92d", "s_df1a0b2a", "s_8a2b78b3", "s_b24a6589", "s_dca3d46b", "s_4aa87431" }, starts = { I.P3 } },
	{ name = "mission_3_offer_flee_route", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_37b6c92d", "s_df1a0b2a", "s_8a2b78b3", "s_b24a6589", "s_dca3d46b", "s_1598dcb2", "s_71ab0619" }, starts = { I.P3 } },
	{ name = "mission_3_offer_no_coward_route", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_37b6c92d", "s_df1a0b2a", "s_8a2b78b3", "s_b24a6589", "s_dca3d46b", "s_b0ef8499", "s_2ddcdfff" }, starts = { I.P3 } },
	{ name = "mission_3_offer_almost_ready_loop", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_8c9c5f1a", "s_8c9c5f1a", "s_37b6c92d", "s_df1a0b2a", "s_8a2b78b3", "s_b24a6589", "s_dca3d46b", "s_4aa87431" }, starts = { I.P3 } },
	{ name = "mission_4_offer_direct", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_651c4d7a", "s_78d92576", "s_4aa87431", "s_ea112eca" }, starts = { I.A4 } },
	{ name = "mission_4_offer_underestimate", pilot = { paid = 3 }, first = "mission4_offer", choices = { "s_651c4d7a", "s_78d92576", "s_7e347138", "s_e034da9" }, starts = { I.A4 } },
	{ name = "mission_4_offer_train_after_loop", pilot = { paid = 3 }, first = "mission4_offer",
		choices = { "s_651c4d7a", "s_78d92576", "s_7478cd28", "s_7478cd28", "s_4aa87431", "s_ea112eca" }, starts = { I.A4 } },
}

for _, w in ipairs(WALKS) do
	-- AC-7
	TestInquisitionT1Offers["test_walk_" .. w.name] = function()
		w.pilot = w.pilot or {}
		walk(w)
	end
end

-- AC-7: the exact last screens of the accepted routes end the conversation
function TestInquisitionT1Offers:test_every_accept_route_ends_the_conversation()
	for _, accept in ipairs({ "mission1_accept", "mission1_accept_sloppy", "mission1_accept_orders", "mission2_accept", "mission2_accept_pay", "mission2_accept_cocky",
		"mission3_accept", "mission3_accept_credits", "mission3_accept_priority", "mission4_accept", "mission4_accept_mind" }) do
		H.reset()
		lu.assertTrue(I.drive(I.pilot({ paid = 0 }), accept)[1].stop, accept .. " ends the conversation")
	end
end

-- AC-7: mission 1 won and unpaid is answered by the report routes (the pay itself is tested in the reward file)
function TestInquisitionT1Offers:test_mission_1_won_reports_lead_on_to_the_next_assignment_after_payment()
	local player = I.pilot({ state = "won" })
	local t = I.talk(player, { "s_3a1ddc14", "s_add5962c", "s_987445c9" })

	lu.assertEquals(I.ids(t), { "mission1_won", "mission1_attacked", "mission1_pay_wing", "mission1_rebel_problem" }, "screens shown")
	lu.assertEquals(I.firstScreen(player), "mission2_offer", "the next talk offers mission 2")
end

-- AC-7, D-9: the ground-forces branch of the duty screen
function TestInquisitionT1Offers:test_the_ground_forces_branch_ends_at_the_recruiter()
	local t = walk({ name = "enlist ground", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_47925d97", "s_8efde2ae" } })

	lu.assertEquals(I.ids(t), { "duty_missions", "enlist_ground", "enlist_recruiter" }, "screens shown")
	lu.assertTrue(t[3].stop, "enlist_recruiter ends")
	lu.assertEquals(t[1].options[4] and t[1].options[4].text, I.PREFIX .. "s_47925d97", "the ground reply is the fourth reply of duty_missions")
end

---------------------------------------------------------------------------------------------
-- AC-7: failures and retries
---------------------------------------------------------------------------------------------

TestInquisitionT1Failures = {}

TestInquisitionT1Failures.setUp = setUp

local FAILS = {
	{ n = 1, screen = "mission1_failed", retry = { "s_16fc739e", "s_59c8db72" }, later = { "s_16fc739e", "s_cb99174" }, retryId = "mission1_retry", laterId = "mission1_later" },
	{ n = 2, screen = "mission2_failed", retry = { "s_f9660223", "s_4aa87431" }, later = { "s_19288eda" }, retryId = "mission2_retry", laterId = "mission2_rethink" },
	{ n = 3, screen = "mission3_failed", retry = { "s_b6b25f13" }, later = { "s_668cac00" }, retryId = "mission3_retry", laterId = "mission3_later" },
	{ n = 4, screen = "mission4_failed", retry = { "s_59d306ec", "s_e034da9" }, later = { "s_59d306ec", "s_3de840b5" }, retryId = "mission4_retry", laterId = "mission4_later" },
}

for _, f in ipairs(FAILS) do
	-- AC-7
	TestInquisitionT1Failures["test_mission_" .. f.n .. "_failed_opens_the_failure_screen_and_the_retry_restarts_the_mission"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = I.talk(player, f.retry)

		lu.assertEquals(t[1].id, f.screen, "first screen")
		lu.assertEquals(t[#t].id, f.retryId, "last screen")
		lu.assertEquals(started(spies), { HEADS[f.n] }, "the head of mission " .. f.n .. " started once")
		lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_" .. f.n .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7
	TestInquisitionT1Failures["test_mission_" .. f.n .. "_failed_and_later_ends_without_a_restart"] = function()
		local player = I.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = I.talk(player, f.later)

		lu.assertEquals(t[#t].id, f.laterId, "last screen")
		lu.assertTrue(t[#t].stop, f.laterId .. " ends the conversation")
		lu.assertEquals(started(spies), {}, "nothing started")
	end
end

-- AC-7 (FI-5): the aborted branch has the same two endings
function TestInquisitionT1Failures:test_mission_2_aborted_retry_restarts_the_mission_and_rethink_does_not()
	local player = I.pilot({ paid = 1, state = "aborted" })
	local spies = spyAll(HEADS)
	local t = I.talk(player, { "s_29ad976e", "s_4aa87431" })

	lu.assertEquals(I.ids(t), { "mission2_aborted", "mission2_aborted_orders", "mission2_aborted_retry" }, "screens shown")
	lu.assertEquals(started(spies), { I.M2 }, "mission 2 started once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	H.reset()

	local other = I.pilot({ paid = 1, state = "aborted" })

	spies = spyAll(HEADS)
	t = I.talk(other, { "s_19288eda" })
	lu.assertEquals(I.ids(t), { "mission2_aborted", "mission2_rethink" }, "screens shown")
	lu.assertTrue(t[2].stop, "mission2_rethink ends")
	lu.assertEquals(started(spies), {}, "nothing started")
	lu.assertEquals(H.getQuestStatus(other, I.ABORTED_SUFFIX), "1", "the marker stays until a mission 2 start")
end

-- AC-7: "clearing a stale run first"
function TestInquisitionT1Failures:test_the_retry_clears_the_failed_runs_leftover_journal_entries_before_starting()
	local player = I.pilot({ state = "failed" })

	I.setState(player, I.P1, "complete")

	local spies = spyAll(HEADS)

	I.drive(player, "mission1_retry")
	lu.assertEquals(started(spies), { I.P1 }, "mission 1 restarted")
	lu.assertEquals(I.state(player, I.P1), "none", "the stale patrol entry is cleared")
	lu.assertEquals(I.state(player, I.S1), "none", "the surprise attack entry is cleared")
end

-- AC-7: the same for mission 3's two entries
function TestInquisitionT1Failures:test_the_mission_3_retry_clears_the_patrol_and_the_escort_entries()
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
function TestInquisitionT1Failures:test_a_start_screen_does_not_restart_a_running_mission()
	local player = I.pilot({ state = "active" })
	local spies = spyAll(HEADS)

	I.drive(player, "mission1_accept")
	lu.assertEquals(started(spies), {}, "mission 1 is active: no second start")
end

---------------------------------------------------------------------------------------------
-- AC-7: every start screen sets :attempted and starts its chain head (table H)
---------------------------------------------------------------------------------------------

TestInquisitionT1Starts = {}

TestInquisitionT1Starts.setUp = setUp

local STARTS = {
	{ screen = "mission1_accept", n = 1 }, { screen = "mission1_accept_sloppy", n = 1 }, { screen = "mission1_accept_orders", n = 1 }, { screen = "mission1_retry", n = 1 },
	{ screen = "mission2_accept", n = 2 }, { screen = "mission2_accept_pay", n = 2 }, { screen = "mission2_accept_cocky", n = 2 }, { screen = "mission2_retry", n = 2 },
	{ screen = "mission2_aborted_retry", n = 2 },
	{ screen = "mission3_accept", n = 3 }, { screen = "mission3_accept_credits", n = 3 }, { screen = "mission3_accept_priority", n = 3 }, { screen = "mission3_retry", n = 3 },
	{ screen = "mission4_accept", n = 4 }, { screen = "mission4_accept_mind", n = 4 }, { screen = "mission4_retry", n = 4 },
}

for _, s in ipairs(STARTS) do
	-- AC-7
	TestInquisitionT1Starts["test_" .. s.screen .. "_sets_attempted_and_starts_mission_" .. s.n] = function()
		local player = I.pilot({ paid = s.n - 1 })
		local spies = spyAll(HEADS)
		local t = I.drive(player, s.screen)

		lu.assertTrue(t[1].stop, s.screen .. " ends the conversation")
		lu.assertEquals(started(spies), { HEADS[s.n] }, "quests started")
		lu.assertEquals(spies[HEADS[s.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_" .. s.n .. ":attempted"), "1", ":attempted of mission " .. s.n)
	end

	-- AC-7: the real head runs (the pilot sits in a ship in the quest zone)
	TestInquisitionT1Starts["test_" .. s.screen .. "_makes_the_real_head_quest_active"] = function()
		local player = I.pilot({ paid = s.n - 1, inShip = true, zone = "space_naboo" })
		local q = I.quest(HEADS[s.n])

		q:start()
		I.drive(player, s.screen)
		lu.assertEquals(I.state(player, HEADS[s.n]), "active", HEADS[s.n] .. ": journal entry after " .. s.screen)
	end
end

-- AC-7: mission 2's start screens clear the aborted marker; other missions' starts leave it alone
for _, screen in ipairs({ "mission2_accept", "mission2_accept_pay", "mission2_accept_cocky", "mission2_retry", "mission2_aborted_retry" }) do
	TestInquisitionT1Starts["test_" .. screen .. "_removes_the_aborted_marker"] = function()
		local player = I.pilot({ paid = 1, state = "aborted" })

		spyAll(HEADS)
		lu.assertEquals(H.getQuestStatus(player, I.ABORTED_SUFFIX), "1", "precondition: the marker is set")
		I.drive(player, screen)
		lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), screen .. ": the aborted marker")
	end
end

-- AC-7: the start screens leave the other missions' :attempted alone
function TestInquisitionT1Starts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = I.pilot({ paid = 1 })

	spyAll(HEADS)
	I.drive(player, "mission2_accept")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_imperial_3:attempted"), "mission 3")
	lu.assertNil(H.getQuestStatus(player, "naboo_imperial_4:attempted"), "mission 4")
end

---------------------------------------------------------------------------------------------
-- AC-7: mission 2's abort marker (D-6, FI-5)
---------------------------------------------------------------------------------------------

TestInquisitionT1Abort = {}

TestInquisitionT1Abort.setUp = setUp

function TestInquisitionT1Abort:tearDown() AC.tearDown() end

-- a pilot in a ship in space_naboo whose mission 2 was started by the accept screen
local function runningMission2()
	local player = I.pilot({ paid = 1, inShip = true, zone = "space_naboo" })
	local q = I.quest(I.M2)

	q:start()
	I.drive(player, "mission2_accept")
	lu.assertEquals(I.state(player, I.M2), "active", "precondition: mission 2 is running")

	return q, player
end

-- AC-7
function TestInquisitionT1Abort:test_aborting_a_running_mission_2_sets_the_marker_ends_the_run_and_barn_opens_mission2_aborted()
	local q, player = runningMission2()

	q:abortQuest(player)
	lu.assertEquals(H.getQuestStatus(player, I.ABORTED_SUFFIX), "1", "the aborted marker")
	lu.assertEquals(I.state(player, I.M2), "none", "the run ended without a completed entry")
	lu.assertEquals(I.firstScreen(player), "mission2_aborted", "the next talk")
end

-- AC-7: the datapad abort path
function TestInquisitionT1Abort:test_the_datapad_abort_of_mission_2_sets_the_marker()
	local q, player = runningMission2()

	H.abortMission(player, "destroy", "naboo_imperial_2")
	lu.assertEquals(H.getQuestStatus(player, I.ABORTED_SUFFIX), "1", "the aborted marker")
	lu.assertEquals(I.firstScreen(player), "mission2_aborted", "the next talk")
end

-- AC-7: an inactive abort sets nothing
function TestInquisitionT1Abort:test_aborting_a_mission_2_that_is_not_running_sets_nothing()
	local player = I.pilot({ paid = 1 })
	local q = I.quest(I.M2)

	q:abortQuest(player)
	lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), "the aborted marker")
end

-- AC-7: other quests' aborts do not set Barn's marker
function TestInquisitionT1Abort:test_aborting_mission_1_sets_no_marker()
	local player = I.pilot({ inShip = true, zone = "space_naboo" })
	local q = I.quest(I.P1)

	q:start()
	I.drive(player, "mission1_accept")
	lu.assertEquals(I.state(player, I.P1), "active", "precondition: mission 1 is running")
	q:abortQuest(player)
	lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), "the aborted marker")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertEquals(I.firstScreen(player), "mission1_failed", "an aborted mission 1 is a failed one")
end

-- AC-7: a mission 2 that ended without an abort opens mission2_failed
function TestInquisitionT1Abort:test_a_mission_2_run_that_failed_without_an_abort_opens_mission2_failed()
	local q, player = runningMission2()

	q:failQuest(player, true)
	lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), "no marker")
	lu.assertEquals(I.state(player, I.M2), "none", "the run ended")
	lu.assertEquals(I.firstScreen(player), "mission2_failed", "the next talk")
end

-- AC-7: either retry screen clears the marker and restarts the run
function TestInquisitionT1Abort:test_the_retry_after_an_abort_clears_the_marker_and_the_real_run_starts_again()
	local q, player = runningMission2()

	q:abortQuest(player)
	I.drive(player, "mission2_aborted_retry")
	lu.assertNil(H.getQuestStatus(player, I.ABORTED_SUFFIX), "marker cleared")
	lu.assertEquals(I.state(player, I.M2), "active", "mission 2 runs again")
	lu.assertEquals(I.firstScreen(player), "on_mission", "the next talk while it runs")
end

-- AC-7: the marker is cleared when the new run is won
function TestInquisitionT1Abort:test_a_won_mission_2_after_an_abort_opens_mission2_won()
	local player = I.pilot({ paid = 1, state = "won", aborted = true })

	lu.assertEquals(I.firstScreen(player), "mission2_won", "won beats a stale marker")
end

---------------------------------------------------------------------------------------------
-- AC-7: duties
---------------------------------------------------------------------------------------------

TestInquisitionT1Duties = {}

TestInquisitionT1Duties.setUp = setUp

-- AC-7: the destroy duty on track
function TestInquisitionT1Duties:test_a_pilot_after_mission_4_starts_the_destroy_duty()
	local t = walk({ name = "destroy duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_87bb7015", "s_a490d2c6" }, starts = { I.DUTY6 } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertTrue(t[#t].stop, "duty_accepted ends")
end

-- AC-7
function TestInquisitionT1Duties:test_a_pilot_after_mission_4_starts_the_escort_duty()
	local t = walk({ name = "escort duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_79ab4bbe", "s_a490d2c6" }, starts = { I.DUTY7 } })

	lu.assertEquals(I.ids(t), { "duty_missions", "duty_menu", "escort_duty", "duty_accepted" }, "screens shown")
end

-- AC-7
function TestInquisitionT1Duties:test_declining_a_duty_starts_nothing()
	walk({ name = "duty later", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_5ebce168" } })
	walk({ name = "duty explained, done for now", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_1091c96a" } })
end

-- AC-7: the duty explanation leads back to the menu
function TestInquisitionT1Duties:test_the_duty_explanation_leads_to_the_duty_menu_and_a_duty()
	walk({ name = "duty explained", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_2d5d4bf0", "s_87bb7015", "s_a490d2c6" }, starts = { I.DUTY6 } })
end

-- AC-7: "no training XP" ends the conversation
function TestInquisitionT1Duties:test_the_no_training_reply_of_the_duty_screen_ends_the_conversation()
	local t = walk({ name = "no training xp", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_3b3aabc1" } })

	lu.assertTrue(t[2].stop, "no_training_xp ends")
end

-- AC-7: the off-track non-member's duty
function TestInquisitionT1Duties:test_an_off_track_pilot_with_a_tier_1_skill_flies_a_duty_for_barn()
	walk({ name = "off-track destroy duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_2692ee30", "s_87bb7015", "s_a490d2c6" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty", "duty_accepted" }, starts = { I.DUTY6 } })
	walk({ name = "off-track escort duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_2692ee30", "s_79ab4bbe", "s_a490d2c6" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "escort_duty", "duty_accepted" }, starts = { I.DUTY7 } })
	walk({ name = "off-track declined", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_4854758d", "s_90ce1297" },
		ids = { "non_member", "non_member_duty_offer", "non_member_declined" } })
end

-- AC-7: the help loop reaches every help screen
function TestInquisitionT1Duties:test_the_first_mission_help_walks_through_all_its_screens()
	local t = walk({ name = "help loop", pilot = { state = "active" }, first = "first_mission_help", choices = { "s_69a4eec5", "s_60c4f974", "s_4358efe9" },
		ids = { "first_mission_help", "help_return", "help_where", "help_ship" } })

	lu.assertEquals(#t, 4, "screens")
	lu.assertFalse(t[4].stop, "the help loop never ends by itself")
	walk({ name = "help loop restarts", pilot = { state = "active" }, first = "first_mission_help", choices = { "s_4358efe9", "s_4358efe9", "s_69a4eec5", "s_60c4f974" },
		ids = { "first_mission_help", "help_ship", "help_ship", "help_return", "help_where" } })
end
