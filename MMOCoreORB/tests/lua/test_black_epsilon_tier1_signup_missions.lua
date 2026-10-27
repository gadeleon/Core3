-- Hakassha Sireen: sign-up, the four mission offers, briefings, failures and retries, and the duty hand-outs.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-5, AC-7; Conversation flow 3 (table H) and 4; Appendix A).
--
-- Every walk is a list of reply sids (the client lines); the screens shown come from the Appendix A graph (black_epsilon_tier1_screens_data.lua)
-- unless a conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the chain heads'
-- startQuest (H.spyOn does not call the original), and the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

B.load()

local HEADS = { B.P1, B.M2, B.E3, B.A4 }

local function setUp()
	H.reset()
	B.requireConversation(lu)
end

-- The screens an Appendix A graph shows when `choices` (reply sids) are followed from screen `first`
local function follow(first, choices)
	local ids = { first }

	for _, sid in ipairs(choices) do
		local row = B.screenRow(ids[#ids])

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
		spies[g] = H.spyOn(B.quest(g), "startQuest")
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
	local spies = spyAll({ B.P1, B.S1, B.M2, B.E3, B.A4, B.DUTY6, B.DUTY7 })
	local player = B.pilot(w.pilot)
	local t = B.talk(player, w.choices)
	local ids = w.ids or follow(w.first, w.choices)

	lu.assertEquals(B.ids(t), ids, w.name .. ": screens shown")
	lu.assertEquals(started(spies), w.starts or {}, w.name .. ": quests started")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings of the transcript (AC-5)")

	return t, player
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

TestBlackEpsilonT1SignUp = {}

TestBlackEpsilonT1SignUp.setUp = setUp

local PRE_SWEAR = { "s_11bb9c43", "s_be86775e", "s_df871c0b" } -- recruitment, recruit_pilot, recruit_baggage -> recruit_agency
local BRIEF = { "s_c023d5a9", "s_ac893f3a", "s_ccf66c81", "s_c261b36a", "s_d1613a21", "s_2d4c3812", "s_38909ce3" } -- mission1_brief -> mission1_accept

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function novice(player)
	for _, call in ipairs(B.free()) do
		if call[1] == player and call[2] == B.NOVICE then
			return true
		end
	end

	return false
end

-- AC-7: the whole sign-up of a pilot without a ship, to the first mission
function TestBlackEpsilonT1SignUp:test_an_imperial_non_pilot_without_a_ship_signs_up_gets_the_box_the_squadron_the_tie_and_mission_1()
	local choices = concat(PRE_SWEAR, { "s_62027e5", "s_845e6ef5", "s_4ecd165f", "s_3e8986a7", "s_4b5d9495" }, BRIEF)
	local player = B.pilot({ pilot = false, squadron = false, ship = false, pilotTier = 0 })
	local spies = spyAll(HEADS)
	local t = B.talk(player, choices)

	lu.assertEquals(B.ids(t), { "recruitment", "recruit_pilot", "recruit_baggage", "recruit_agency", "recruit_swear", "recruit_sworn", "recruit_ship_granted", "recruit_business",
		"mission1_brief", "mission1_rumors", "mission1_lesson", "mission1_reason", "mission1_spy", "mission1_kill", "mission1_answers_later", "mission1_accept" }, "screens shown")
	lu.assertTrue(novice(player), "the novice box pilot_imperial_navy_novice was granted free (awardSkill)")
	lu.assertEquals(player.ghost.squadronType, BLACK_EPSILON_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
	assertOneShip(player)
	lu.assertEquals(started(spies), { B.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: a pilot who still has a ship sees recruit_has_ship and gets none
function TestBlackEpsilonT1SignUp:test_a_non_pilot_with_a_ship_sees_recruit_has_ship_and_gets_no_ship()
	local choices = concat(PRE_SWEAR, { "s_62027e5", "s_845e6ef5", "s_4ecd165f", "s_3e8986a7", "s_4b5d9495" })
	local player = B.pilot({ pilot = false, squadron = false, pilotTier = 0 })
	local t = B.talk(player, choices)

	lu.assertEquals(B.ids(t), { "recruitment", "recruit_pilot", "recruit_baggage", "recruit_agency", "recruit_swear", "recruit_sworn", "recruit_has_ship", "recruit_business", "mission1_brief" }, "screens shown")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship")
	lu.assertTrue(novice(player), "the novice box was still granted")
	lu.assertEquals(player.ghost.squadronType, BLACK_EPSILON_SQUADRON, "squadron type")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: no grant before the oath
function TestBlackEpsilonT1SignUp:test_nothing_is_granted_before_the_oath_screen()
	local player = B.pilot({ pilot = false, squadron = false, pilotTier = 0 })

	B.talk(player, concat(PRE_SWEAR, { "s_62027e5" }))
	lu.assertFalse(novice(player), "no novice box before recruit_sworn")
	lu.assertEquals(player.ghost.squadronType, 0, "no squadron before recruit_sworn")
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-7: the longer ways to the oath
local SWEAR_WALKS = {
	{ name = "via_secrets", pre = { "s_e749e2cd", "s_11816971" }, ids = { "recruit_agency", "recruit_secrets", "recruit_swear" } },
	{ name = "via_pay", pre = { "s_92a51c16", "s_11816971" }, ids = { "recruit_agency", "recruit_pay", "recruit_swear" } },
	{ name = "via_pay_then_secrets", pre = { "s_92a51c16", "s_e749e2cd", "s_11816971" }, ids = { "recruit_agency", "recruit_pay", "recruit_secrets", "recruit_swear" } },
	{ name = "via_secrets_then_pay", pre = { "s_e749e2cd", "s_32fca1d6", "s_11816971" }, ids = { "recruit_agency", "recruit_secrets", "recruit_pay", "recruit_swear" } },
}

for _, w in ipairs(SWEAR_WALKS) do
	-- AC-7
	TestBlackEpsilonT1SignUp["test_the_oath_is_reachable_" .. w.name] = function()
		local player = B.pilot({ pilot = false, squadron = false, pilotTier = 0 })
		local t = B.talk(player, concat(PRE_SWEAR, w.pre, { "s_845e6ef5", "s_4ecd165f" }))
		local want = concat({ "recruitment", "recruit_pilot", "recruit_baggage" }, w.ids, { "recruit_sworn", "recruit_has_ship" })

		lu.assertEquals(B.ids(t), want, "screens shown")
		lu.assertTrue(novice(player), "the box is granted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the zabrak detour ("Swear? That seems a little extreme.")
function TestBlackEpsilonT1SignUp:test_the_extreme_detour_leads_back_to_the_oath_and_grants_after_it()
	local player = B.pilot({ pilot = false, squadron = false, pilotTier = 0 })
	local t = B.talk(player, concat(PRE_SWEAR, { "s_62027e5", "s_2fb75072", "s_7c7f3198", "s_702795f8", "s_423667ed", "s_4ecd165f" }))

	lu.assertEquals(B.ids(t), { "recruitment", "recruit_pilot", "recruit_baggage", "recruit_agency", "recruit_swear", "recruit_extreme", "recruit_zabrak", "recruit_swear_again", "recruit_sworn", "recruit_has_ship" }, "screens shown")
	lu.assertTrue(novice(player), "the box is granted at recruit_sworn")
	lu.assertEquals(player.ghost.squadronType, BLACK_EPSILON_SQUADRON, "squadron type")
end

-- AC-7: every refusal ending grants nothing
local REFUSALS = {
	{ name = "keep_skin", choices = { "s_11bb9c43", "s_8417be65" }, last = "recruit_keep_skin" },
	{ name = "not_interested", choices = concat(PRE_SWEAR, { "s_d80177b5" }), last = "recruit_not_interested" },
	{ name = "refused_at_the_oath", choices = concat(PRE_SWEAR, { "s_62027e5", "s_7b9b2577" }), last = "recruit_refused" },
	{ name = "refused_after_the_detour", choices = concat(PRE_SWEAR, { "s_62027e5", "s_2fb75072", "s_7c7f3198", "s_702795f8", "s_54328ce3" }), last = "recruit_refused" },
}

for _, r in ipairs(REFUSALS) do
	-- AC-7
	TestBlackEpsilonT1SignUp["test_the_refusal_" .. r.name .. "_ends_and_grants_nothing"] = function()
		local player = B.pilot({ pilot = false, squadron = false, ship = false, pilotTier = 0 })
		local t = B.talk(player, r.choices)

		lu.assertEquals(t[#t].id, r.last, "last screen")
		lu.assertTrue(t[#t].stop, r.last .. " ends the conversation")
		lu.assertEquals(#B.free() + #B.bought(), 0, "no skill granted")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier unchanged")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the lost-ship branch (a pilot who destroyed the control device)
function TestBlackEpsilonT1SignUp:test_a_member_who_lost_the_ship_gets_one_new_starter_ship()
	local player = B.pilot({ ship = false })
	local t = B.talk(player, { "s_ca2a7f20", "s_67e76bed" })

	lu.assertEquals(B.ids(t), { "lost_ship", "lost_ship_business", "lost_ship_granted" }, "screens shown")
	lu.assertTrue(t[3].stop, "lost_ship_granted ends")
	assertOneShip(player)
end

-- AC-7
function TestBlackEpsilonT1SignUp:test_declining_the_replacement_ship_grants_nothing()
	local player = B.pilot({ ship = false })
	local t = B.talk(player, { "s_ca2a7f20", "s_7f96a397" })

	lu.assertEquals(B.ids(t), { "lost_ship", "lost_ship_business", "lost_ship_declined" }, "screens shown")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
end

---------------------------------------------------------------------------------------------
-- AC-7: mission offers, briefings and starts
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Offers = {}

TestBlackEpsilonT1Offers.setUp = setUp

local WALKS = {
	{ name = "mission_1_offer_direct", pilot = {}, first = "mission1_offer", choices = concat({ "s_96682689" }, BRIEF), starts = { B.P1 } },
	{ name = "mission_1_offer_train_later", pilot = {}, first = "mission1_offer", choices = concat({ "s_2c9c30a0", "s_5bd69df6" }, BRIEF), starts = { B.P1 } },
	{ name = "mission_2_offer_through_the_agency_loop", pilot = { paid = 1 }, first = "mission2_offer",
		choices = { "s_87f86e3e", "s_8879f039", "s_fe85123f", "s_d2e23af2", "s_1adbadc4", "s_86c66182", "s_ef85b67c", "s_ec3c3e1d", "s_1ff4247a" }, starts = { B.M2 } },
	{ name = "mission_2_offer_not_yet", pilot = { paid = 1 }, first = "mission2_offer",
		choices = { "s_192ddc14", "s_87f86e3e", "s_8879f039", "s_fe85123f", "s_d2e23af2", "s_1adbadc4", "s_86c66182", "s_ef85b67c", "s_ec3c3e1d", "s_1ff4247a" }, starts = { B.M2 } },
	{ name = "mission_3_offer_direct", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_7a80cd06", "s_1ca122f0", "s_dd67013", "s_b1fa2372", "s_995b811", "s_9265da40" }, starts = { B.E3 } },
	{ name = "mission_3_offer_ambitious_then_excessive", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_4d31f286", "s_7c1600a", "s_1ca122f0", "s_dd67013", "s_b1fa2372", "s_32ab69ab", "s_6d2bb136", "s_9265da40" }, starts = { B.E3 } },
	{ name = "mission_3_second_guess_leaves_no_choice", pilot = { paid = 2 }, first = "mission3_offer",
		choices = { "s_7a80cd06", "s_1ca122f0", "s_dd67013", "s_b1fa2372", "s_32ab69ab", "s_13bbdfe7", "s_644da0b1" }, starts = { B.E3 } },
	{ name = "mission_4_offer_direct", pilot = { paid = 3 }, first = "mission4_offer",
		choices = { "s_55f35dd9", "s_801033a0", "s_34089768", "s_c261cfae" }, starts = { B.A4 } },
	{ name = "mission_4_offer_training_deal", pilot = { paid = 3 }, first = "mission4_offer",
		choices = { "s_5da44265", "s_55f35dd9", "s_801033a0", "s_34089768", "s_c261cfae" }, starts = { B.A4 } },
}

for _, w in ipairs(WALKS) do
	-- AC-7
	TestBlackEpsilonT1Offers["test_walk_" .. w.name] = function()
		w.pilot = w.pilot or {}
		walk(w)
	end
end

-- AC-7: mission 1 won and unpaid starts the agency loop, which ends at mission 2 (the won screen pays; see the reward tests)
function TestBlackEpsilonT1Offers:test_mission_1_won_leads_through_the_agency_questions_to_mission_2()
	local t, player = walk({ name = "mission 1 won, then mission 2", pilot = { state = "won" }, first = "mission1_won",
		choices = { "s_334f003c", "s_87f86e3e", "s_8879f039", "s_fe85123f", "s_d2e23af2", "s_1adbadc4", "s_86c66182", "s_ef85b67c", "s_ec3c3e1d", "s_1ff4247a" }, starts = { B.M2 } })

	lu.assertEquals(t[#t].id, "mission2_accept", "last screen")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_2:attempted"), "1", "mission 2 :attempted")
end

-- AC-7: the agency loop answers every question and returns to a choice (twin links)
local AGENCY_FIRST = { "s_87f86e3e", "s_8879f039", "s_fe85123f" }

function TestBlackEpsilonT1Offers:test_the_agency_loop_can_be_walked_through_every_question_before_the_assignment()
	local choices = concat(AGENCY_FIRST, { "s_1f78cffa", "s_70edc281", "s_10499a33", "s_da3e5ec3", "s_f1f8a5ca", "s_485d8416", "s_3c26f38a", "s_ff1e8d6a", "s_e1ea9c75", "s_747c5a79", "s_1930ad3a", "s_d2e23af2" })
	local ids = { "mission2_offer", "agency_navy_army", "agency_overt_force", "agency_black_epsilon", "agency_join", "agency_zabrak", "agency_trust", "agency_test", "agency_sincere",
		"agency_rewarding", "agency_purpose", "agency_corellia", "agency_invade", "agency_mandalore", "agency_dagger", "agency_next_assignment" }

	walk({ name = "agency loop", pilot = { paid = 1 }, ids = ids, choices = choices })
	lu.assertEquals(follow("mission2_offer", choices), ids, "the Appendix A graph agrees with the walk")
end

-- AC-7: the agency loop's last step is mission 2, from whichever question was asked last (killer branch)
function TestBlackEpsilonT1Offers:test_the_killer_branch_of_the_agency_loop_returns_to_the_choice()
	walk({ name = "killer branch", pilot = { paid = 1 }, first = "mission2_offer",
		choices = { "s_87f86e3e", "s_8879f039", "s_fe85123f", "s_10499a33", "s_da3e5ec3", "s_f1f8a5ca", "s_48f07357", "s_d2e23af2" } })
end

---------------------------------------------------------------------------------------------
-- AC-7: failures and retries
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Failures = {}

TestBlackEpsilonT1Failures.setUp = setUp

local FAILS = {
	{ n = 1, screen = "mission1_failed", retry = { "s_88da6887", "s_97d43fda" }, later = { "s_88da6887", "s_593d4b61" }, retryId = "mission1_retry", laterId = "mission1_later" },
	{ n = 2, screen = "mission2_failed", retry = { "s_28490f70" }, later = { "s_96c066fe" }, retryId = "mission2_retry", laterId = "mission2_later" },
	{ n = 3, screen = "mission3_failed", retry = { "s_fad19320", "s_25042a7a" }, later = { "s_fad19320", "s_8fdf4d92" }, retryId = "mission3_retry", laterId = "mission3_later" },
	{ n = 4, screen = "mission4_failed", retry = { "s_64a94075", "s_ffba9145" }, later = { "s_64a94075", "s_15588832" }, retryId = "mission4_retry", laterId = "mission4_later" },
}

for _, f in ipairs(FAILS) do
	-- AC-7
	TestBlackEpsilonT1Failures["test_mission_" .. f.n .. "_failed_opens_the_failure_screen_and_the_retry_restarts_the_mission"] = function()
		local player = B.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = B.talk(player, f.retry)

		lu.assertEquals(t[1].id, f.screen, "first screen")
		lu.assertEquals(t[#t].id, f.retryId, "last screen")
		lu.assertEquals(started(spies), { HEADS[f.n] }, "the head of mission " .. f.n .. " started once")
		lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_" .. f.n .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7
	TestBlackEpsilonT1Failures["test_mission_" .. f.n .. "_failed_and_later_ends_without_a_restart"] = function()
		local player = B.pilot({ paid = f.n - 1, state = "failed" })
		local spies = spyAll(HEADS)
		local t = B.talk(player, f.later)

		lu.assertEquals(t[#t].id, f.laterId, "last screen")
		lu.assertTrue(t[#t].stop, f.laterId .. " ends the conversation")
		lu.assertEquals(started(spies), {}, "nothing started")
	end
end

-- AC-7: "clearing a stale run first"
function TestBlackEpsilonT1Failures:test_the_retry_clears_the_failed_runs_leftover_journal_entries_before_starting()
	local player = B.pilot({ state = "failed" })

	B.setState(player, B.P1, "complete")

	local spies = spyAll(HEADS)

	B.drive(player, "mission1_retry")
	lu.assertEquals(started(spies), { B.P1 }, "mission 1 restarted")
	lu.assertEquals(B.state(player, B.P1), "none", "the stale patrol entry is cleared")
	lu.assertEquals(B.state(player, B.S1), "none", "the surprise attack entry is cleared")
end

-- AC-7: a running chain is never restarted underneath the pilot
function TestBlackEpsilonT1Failures:test_a_start_screen_does_not_restart_a_running_mission()
	local player = B.pilot({ state = "active" })
	local spies = spyAll(HEADS)

	B.drive(player, "mission1_accept")
	lu.assertEquals(started(spies), {}, "mission 1 is active: no second start")
end

---------------------------------------------------------------------------------------------
-- AC-7: every start screen sets :attempted and starts its chain head (table H)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Starts = {}

TestBlackEpsilonT1Starts.setUp = setUp

local STARTS = {
	{ screen = "mission1_accept", n = 1 }, { screen = "mission1_retry", n = 1 },
	{ screen = "mission2_accept", n = 2 }, { screen = "mission2_retry", n = 2 },
	{ screen = "mission3_accept", n = 3 }, { screen = "mission3_accept_no_choice", n = 3 }, { screen = "mission3_retry", n = 3 },
	{ screen = "mission4_accept", n = 4 }, { screen = "mission4_retry", n = 4 },
}

for _, s in ipairs(STARTS) do
	-- AC-7
	TestBlackEpsilonT1Starts["test_" .. s.screen .. "_sets_attempted_and_starts_mission_" .. s.n] = function()
		local player = B.pilot({ paid = s.n - 1 })
		local spies = spyAll(HEADS)
		local t = B.drive(player, s.screen)

		lu.assertTrue(t[1].stop, s.screen .. " ends the conversation")
		lu.assertEquals(started(spies), { HEADS[s.n] }, "quests started")
		lu.assertEquals(spies[HEADS[s.n]][1].args[1], player, "startQuest got the pilot")
		lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_" .. s.n .. ":attempted"), "1", ":attempted of mission " .. s.n)
	end

	-- AC-7: the real head runs (the pilot sits in a ship in the quest zone)
	TestBlackEpsilonT1Starts["test_" .. s.screen .. "_makes_the_real_head_quest_active"] = function()
		local player = B.pilot({ paid = s.n - 1, inShip = true, zone = "space_corellia" })
		local q = B.quest(HEADS[s.n])

		q:start()
		B.drive(player, s.screen)
		lu.assertEquals(B.state(player, HEADS[s.n]), "active", HEADS[s.n] .. ": journal entry after " .. s.screen)
	end
end

-- AC-7: the start screens leave the other missions' :attempted alone
function TestBlackEpsilonT1Starts:test_a_start_screen_sets_only_its_own_attempted_key()
	local player = B.pilot({ paid = 1 })

	spyAll(HEADS)
	B.drive(player, "mission2_accept")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:attempted"), "1", "mission 1 stays attempted")
	lu.assertNil(H.getQuestStatus(player, "corellia_imperial_3:attempted"), "mission 3")
	lu.assertNil(H.getQuestStatus(player, "corellia_imperial_4:attempted"), "mission 4")
end

---------------------------------------------------------------------------------------------
-- AC-7: duties
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Duties = {}

TestBlackEpsilonT1Duties.setUp = setUp

-- AC-7: the destroy duty on track
function TestBlackEpsilonT1Duties:test_a_pilot_after_mission_4_starts_the_destroy_duty()
	local t = walk({ name = "destroy duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_13e807c3", "s_7839f2d4" }, starts = { B.DUTY6 } })

	lu.assertEquals(B.ids(t), { "duty_missions", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertTrue(t[#t].stop, "duty_accepted ends")
end

-- AC-7
function TestBlackEpsilonT1Duties:test_a_pilot_after_mission_4_starts_the_escort_duty()
	local t = walk({ name = "escort duty", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_79ab4bbe", "s_80d8485c" }, starts = { B.DUTY7 } })

	lu.assertEquals(B.ids(t), { "duty_missions", "duty_menu", "escort_duty", "duty_accepted" }, "screens shown")
end

-- AC-7
function TestBlackEpsilonT1Duties:test_declining_a_duty_starts_nothing()
	walk({ name = "duty later", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_2d5d4bf0", "s_5ebce168" } })
	walk({ name = "duty explained, done for now", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_1091c96a" } })
end

-- AC-7: the duty explanation leads back to the menu
function TestBlackEpsilonT1Duties:test_the_duty_explanation_leads_to_the_duty_menu_and_a_duty()
	walk({ name = "duty explained", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_6a128385", "s_b789ed1e", "s_13e807c3", "s_7839f2d4" }, starts = { B.DUTY6 } })
end

-- AC-7: "no training XP" and "enlist in the ground forces" end the conversation
function TestBlackEpsilonT1Duties:test_the_training_and_ground_replies_of_the_duty_screen_end_the_conversation()
	local t = walk({ name = "no training xp", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_943c7ba6" } })

	lu.assertTrue(t[2].stop, "no_training_xp ends")

	t = walk({ name = "enlist ground", pilot = { paid = 4, tier = 1 }, first = "duty_missions", choices = { "s_761039fa" } })
	lu.assertTrue(t[2].stop, "enlist_ground ends")
end

-- AC-7: the off-track non-member's duty
function TestBlackEpsilonT1Duties:test_an_off_track_pilot_with_a_tier_1_skill_flies_a_duty_for_hakassha()
	walk({ name = "off-track destroy duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_29e5ec7", "s_b789ed1e", "s_13e807c3", "s_7839f2d4" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "destroy_duty", "duty_accepted" }, starts = { B.DUTY6 } })
	walk({ name = "off-track escort duty", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_29e5ec7", "s_b789ed1e", "s_79ab4bbe", "s_80d8485c" },
		ids = { "non_member", "non_member_duty_offer", "duty_menu", "escort_duty", "duty_accepted" }, starts = { B.DUTY7 } })
	walk({ name = "off-track declined", pilot = { squadron = false, tier = 1 }, first = "non_member", choices = { "s_29e5ec7", "s_1acdc4ba" },
		ids = { "non_member", "non_member_duty_offer", "non_member_declined" } })
end

-- AC-7: the help loop reaches every help screen
function TestBlackEpsilonT1Duties:test_the_first_mission_help_walks_through_all_its_screens()
	local choices = { "s_85dd7d6c", "s_4738e99f", "s_32c46e00", "s_f8b02865", "s_4358efe9" }
	local t = walk({ name = "help loop", pilot = { state = "active" }, first = "first_mission_help", choices = choices,
		ids = { "first_mission_help", "help_return", "help_station", "help_where", "help_what", "help_ship" } })

	lu.assertEquals(#t, 6, "screens")
	walk({ name = "help understood", pilot = { state = "active" }, first = "first_mission_help", choices = { "s_85dd7d6c", "s_9288900f", "s_4358efe9" },
		ids = { "first_mission_help", "help_return", "help_understood", "help_ship" } })
end
