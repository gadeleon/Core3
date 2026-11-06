-- Commander Oberhaur: missions 1 and 2 (start, failure, retry), the three payments, the Morv briefing, the Claw report and the Alozen orders.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-10, AC-12; Conversation flow 3 (table H) and 4; FI-1, FI-10; D-15; I-9, I-10).
--
-- The Kimogila's Claw (assassinate_imperial_ss_3) is never granted here (Q-1 = A: the Nym technicians feature does that), so its win is written into the
-- journal. The amounts are J2's (checked against the fixture in test_storm_tier2_data.lua). Credits are the bank credits of the fake pilot, items the
-- giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function standing(player) return player.ghost.factionStanding.imperial end

-- Spies startQuest on every quest table; returns the call lists by global
local function spyStarts()
	local starts = {}

	for _, g in ipairs(T.GLOBALS) do
		starts[g] = H.spyOn(T.quest(g), "startQuest")
	end

	return starts
end

local function startedGlobals(starts)
	local out = {}

	for _, g in ipairs(T.GLOBALS) do
		if #starts[g] > 0 then
			out[#out + 1] = g .. " x" .. #starts[g]
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Starting missions 1 and 2
---------------------------------------------------------------------------------------------

TestStormT2Starts = {}

TestStormT2Starts.setUp = setUp

local STARTS = {
	{ screen = "m1_accept", global = T.M1, n = 1, paid = 0 },
	{ screen = "m1_retry", global = T.M1, n = 1, paid = 0 },
	{ screen = "m2_accept", global = T.M2, n = 2, paid = 1 },
	{ screen = "m2_retry", global = T.M2, n = 2, paid = 1 },
}

for _, s in ipairs(STARTS) do
	-- AC-10: a start screen sets its :attempted key and starts its head, once
	TestStormT2Starts["test_" .. s.screen .. "_starts_mission_" .. s.n .. "_and_sets_attempted"] = function()
		local starts = spyStarts()
		local player = T.pilot({ paid = s.paid })

		T.drive(player, s.screen)
		lu.assertEquals(H.getQuestStatus(player, T.STATUS[s.n] .. ":attempted"), "1", s.screen .. ": the :attempted key")
		lu.assertEquals(#starts[s.global], 1, s.screen .. ": startQuest calls of " .. s.global)
		lu.assertEquals(starts[s.global][1].args[1], player, s.screen .. ": startQuest got the pilot")
		lu.assertEquals(startedGlobals(starts), { s.global .. " x1" }, s.screen .. ": no other quest starts")
		lu.assertNil(H.getQuestStatus(player, T.STATUS[s.n] .. ":reward"), s.screen .. ": no :reward key")
		lu.assertEquals(player.bankCredits, 0, s.screen .. ": no credits")
	end

	-- AC-10: only the start screen starts it
	TestStormT2Starts["test_the_walk_to_" .. s.screen .. "_starts_nothing_before_it"] = function()
		local starts = spyStarts()
		local player = T.pilot({ paid = s.paid, state = s.screen:find("retry") and "failed" or nil })
		local replies, ids = T.walkTo(s.screen:find("retry") and (s.n == 1 and "m1_failed" or "m2_failed") or (s.n == 1 and "m1_offer" or "m2_offer"), s.screen)

		lu.assertNotNil(replies, "Appendix A has a walk to " .. s.screen)

		local partial = { table.unpack(replies, 1, #replies - 1) }
		local t = T.talk(player, partial)

		lu.assertEquals(T.ids(t), { table.unpack(ids, 1, #ids - 1) }, "screens before the start screen")
		lu.assertEquals(startedGlobals(starts), {}, "nothing started before " .. s.screen)
		if not s.screen:find("retry") then
			lu.assertNil(H.getQuestStatus(player, T.STATUS[s.n] .. ":attempted"), "no :attempted key before " .. s.screen)
		end
	end
end

-- AC-10: really started, the journal entry is active (a ship in the quest zone)
function TestStormT2Starts:test_the_start_screens_leave_the_journal_entry_active_in_a_ship_in_lok()
	for _, s in ipairs({ { "m1_accept", T.M1, 0 }, { "m2_accept", T.M2, 1 } }) do
		H.reset()
		T.quest(s[2]):start()

		local player = T.pilot({ paid = s[3], inShip = true, zone = "space_lok" })

		T.drive(player, s[1])
		H.advance(0)
		lu.assertEquals(T.state(player, s[2]), "active", s[1] .. ": the journal entry of " .. s[2])
	end
end

-- AC-10: the whole M1 briefing walk, with its three-question loop
function TestStormT2Starts:test_the_mission_1_briefing_walks_through_the_question_loop_to_the_accept_screen()
	local starts = spyStarts()
	local player = T.pilot({})
	local t = T.talk(player, { "s_a787fa2e", "s_5102164f", "s_7a761694", "s_f1f7e3da", "s_61657d0f", "s_36fb7ae1", "s_712ea0b5", "s_36fb7ae1", "s_d1be90a9" })

	lu.assertEquals(T.ids(t), { "m1_offer", "m1_lok_operation", "m1_rebel_link", "m1_agent_missed", "m1_compromised", "m1_no_demands", "m1_who_is_nym", "m1_hostages", "m1_who_is_nym", "m1_plan" }, "screens shown")

	for _, i in ipairs({ 6, 7, 8, 9 }) do
		lu.assertEquals(T.optionSids(t[i]), { "s_d1be90a9", "s_36fb7ae1", "s_712ea0b5" }, "the three questions on " .. t[i].id)
		lu.assertEquals(T.linksOf(t[i]), { "m1_plan", "m1_who_is_nym", "m1_hostages" }, "their links on " .. t[i].id)
	end

	lu.assertEquals(startedGlobals(starts), {}, "nothing started yet")

	local done = T.talk(player, { "s_a787fa2e", "s_5102164f", "s_7a761694", "s_f1f7e3da", "s_61657d0f", "s_d1be90a9", "s_8efde2ae", "s_2c4789b" })

	lu.assertEquals(T.ids(done), { "m1_offer", "m1_lok_operation", "m1_rebel_link", "m1_agent_missed", "m1_compromised", "m1_no_demands", "m1_plan", "m1_accept", "m1_return" }, "the full walk")
	lu.assertTrue(done[9].stop, "m1_return ends the conversation")
	lu.assertEquals(startedGlobals(starts), { T.M1 .. " x1" }, "mission 1 started once")
	lu.assertEquals(CS.transcriptUnresolved(done), {}, "client strings")
end

-- AC-10: the M2 briefing walk
function TestStormT2Starts:test_the_mission_2_briefing_walks_to_the_accept_screen_which_ends()
	local starts = spyStarts()
	local player = T.pilot({ paid = 1 })
	local t = T.talk(player, { "s_b6b25f13", "s_61657d0f", "s_d55f2579", "s_1940763a", "s_bc375f79", "s_8efde2ae" })

	lu.assertEquals(T.ids(t), { "m2_offer", "m2_decrypted", "m2_ransom", "m2_flight_plan", "m2_escort", "m2_protect", "m2_accept" }, "screens shown")
	lu.assertTrue(t[7].stop, "m2_accept ends the conversation")
	lu.assertEquals(startedGlobals(starts), { T.M2 .. " x1" }, "mission 2 started once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the failure walks
function TestStormT2Starts:test_a_failed_or_aborted_mission_1_walks_to_the_retry_which_restarts_it()
	for _, state in ipairs({ "failed", "attempted" }) do
		H.reset()

		local starts = spyStarts()
		local player = T.pilot({ state = state })
		local t = T.talk(player, { "s_29d0a2db", "s_8efde2ae" })

		lu.assertEquals(T.ids(t), { "m1_failed", "m1_retry", "m1_retry_luck" }, state .. ": screens shown")
		lu.assertTrue(t[3].stop, "m1_retry_luck ends the conversation")
		lu.assertEquals(startedGlobals(starts), { T.M1 .. " x1" }, state .. ": mission 1 restarted once")
		lu.assertEquals(H.getQuestStatus(player, T.STATUS[1] .. ":attempted"), "1", state .. ": :attempted stays")
	end
end

-- AC-10
function TestStormT2Starts:test_a_failed_or_aborted_mission_2_walks_to_the_retry_which_restarts_it()
	for _, state in ipairs({ "failed", "attempted" }) do
		H.reset()

		local starts = spyStarts()
		local player = T.pilot({ paid = 1, state = state })
		local t = T.talk(player, { "s_8efde2ae" })

		lu.assertEquals(T.ids(t), { "m2_failed", "m2_retry" }, state .. ": screens shown")
		lu.assertTrue(t[2].stop, "m2_retry ends the conversation")
		lu.assertEquals(startedGlobals(starts), { T.M2 .. " x1" }, state .. ": mission 2 restarted once")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, state .. ": client strings")
	end
end

-- AC-10: the Lok travel help from the accept screen follows C-1
function TestStormT2Starts:test_how_do_i_get_to_lok_leads_to_the_capable_help_only_with_a_bought_ship()
	spyStarts()

	local tie = T.talk(T.pilot({ ships = { "object/intangible/ship/tieadvanced_pcd.iff" } }), { "s_a787fa2e", "s_5102164f", "s_7a761694", "s_f1f7e3da", "s_61657d0f", "s_d1be90a9", "s_8efde2ae", "s_401fdcbd" })

	lu.assertEquals(tie[#tie].id, "travel_capable", "a bought TIE")
	lu.assertEquals(T.optionSids(tie[8]), { "s_2c4789b", "s_401fdcbd" }, "m1_accept replies")

	H.reset()

	local basic = T.talk(T.pilot({ ships = { "object/intangible/ship/basic_tiefighter_pcd.iff" } }), { "s_a787fa2e", "s_5102164f", "s_7a761694", "s_f1f7e3da", "s_61657d0f", "s_d1be90a9", "s_8efde2ae", "s_401fdcbd" })

	lu.assertEquals(basic[#basic].id, "travel_need_ship", "only the starter TIE")
	lu.assertEquals(CS.transcriptUnresolved(basic), {}, "client strings")
end

---------------------------------------------------------------------------------------------
-- The three payments (I-9)
---------------------------------------------------------------------------------------------

local GROUPS = {
	{ n = 1, global = T.M1, screen = "m1_pay", won = "m1_won", walkEnd = "m1_bite_to_eat", next = "m2_offer" },
	{ n = 2, global = T.M2, screen = "m2_outstanding", won = "m2_won", walkEnd = "duty_after_m2", next = "duty_after_m2" },
	{ n = 3, global = T.M3, screen = "claw_pay", won = "claw_won", walkEnd = "duty_menu", next = "claw_duties" },
}

-- The group's pilot: missions before n paid, mission n won and unpaid
local function pilot(n, extra)
	local o = { paid = n - 1, state = "won" }

	if n == 3 then
		o.t2 = { 1 }
		o.finding = true
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

TestStormT2Rewards = {}

TestStormT2Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	-- AC-10, AC-12, I-9: the pay screen pays credits, the item and standing, once
	TestStormT2Rewards["test_" .. g.screen .. "_pays_mission_" .. g.n] = function()
		local player = pilot(g.n)

		T.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, T.CREDITS, g.screen .. ": bank credits")
		lu.assertEquals(#player.bankCreditLog, 1, g.screen .. ": addBankCredits calls")
		lu.assertEquals(T.items(player), { T.ITEMS[g.global] }, g.screen .. ": giveItem templates")
		lu.assertEquals(standing(player), T.STANDING, g.screen .. ": Imperial standing")
		lu.assertEquals(H.getQuestStatus(player, T.STATUS[g.n] .. ":reward"), "1", g.screen .. ": the :reward key")
	end

	-- I-9: the same screen shown again
	TestStormT2Rewards["test_" .. g.screen .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g.n)

		for _ = 1, 3 do
			T.drive(player, g.screen)
		end

		lu.assertEquals(player.bankCredits, T.CREDITS, g.screen .. ": bank credits after three visits")
		lu.assertEquals(#T.items(player), 1, g.screen .. ": items after three visits")
		lu.assertEquals(standing(player), T.STANDING, g.screen .. ": standing after three visits")
	end

	-- I-9: a mission that was paid before pays nothing
	TestStormT2Rewards["test_" .. g.screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g.n)

		H.setQuestStatus(player, T.STATUS[g.n] .. ":reward", 1)
		T.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, 0, g.screen .. ": bank credits")
		lu.assertEquals(#T.items(player), 0, g.screen .. ": items")
		lu.assertEquals(standing(player), 0, g.screen .. ": standing")
	end

	-- AC-10: the first screen of a won mission does not pay
	TestStormT2Rewards["test_the_mission_" .. g.n .. "_won_screen_does_not_pay_before_the_pay_screen"] = function()
		local player = pilot(g.n)
		local t = T.talk(player)

		lu.assertEquals(t[1].id, g.won, "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#T.items(player), 0, "items")
		lu.assertEquals(standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, T.STATUS[g.n] .. ":reward"), "no :reward key yet")
	end

	-- AC-10: the walk from the won screen reaches the pay screen and pays once
	TestStormT2Rewards["test_the_mission_" .. g.n .. "_won_walk_pays_once_and_ends_where_the_story_goes_on"] = function()
		local replies, ids = T.walkTo(g.won, g.walkEnd)

		lu.assertNotNil(replies, "Appendix A has a walk from " .. g.won .. " to " .. g.walkEnd)

		local player = pilot(g.n)
		local t = T.talk(player, replies)

		lu.assertEquals(T.ids(t), ids, "screens shown")
		lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits")
		lu.assertEquals(T.items(player), { T.ITEMS[g.global] }, "giveItem templates")
		lu.assertEquals(standing(player), T.STANDING, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end

	-- I-9: the reward item is paid to any species
	TestStormT2Rewards["test_mission_" .. g.n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = pilot(g.n, { species = SPECIES_WOOKIEE })

		T.drive(player, g.screen)
		lu.assertEquals(T.items(player), { T.ITEMS[g.global] }, "giveItem templates for a Wookiee")
	end

	-- I-9: the reward item uses the overload, so a full inventory still receives it (9034fa3254)
	TestStormT2Rewards["test_mission_" .. g.n .. "_item_reaches_a_full_inventory"] = function()
		local player = pilot(g.n, { inventory = { limit = 0 } })

		T.drive(player, g.screen)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- AC-10: after the payment the next visit opens what comes next
	TestStormT2Rewards["test_after_mission_" .. g.n .. "_is_paid_the_next_visit_opens_" .. g.next] = function()
		local player = pilot(g.n)

		T.drive(player, g.screen)
		lu.assertEquals(T.firstScreen(player), g.next, "first screen after the payment")
	end

	-- I-9: a pay screen pays only its own mission
	TestStormT2Rewards["test_" .. g.screen .. "_sets_no_other_missions_reward_key"] = function()
		local player = pilot(g.n)

		T.drive(player, g.screen)

		for n = 1, 3 do
			if n ~= g.n and n > g.n then
				lu.assertNil(H.getQuestStatus(player, T.STATUS[n] .. ":reward"), "mission " .. n .. " stays unpaid")
			end
		end
	end
end

-- AC-10: M1's pay screen continues to the bite to eat, M2's walk through the promotion lines to the duty screen
function TestStormT2Rewards:test_mission_1_and_2_walks_show_the_expected_screens()
	local t1 = T.talk(pilot(1), { "s_f432c46f", "s_22a1fc52", T.THANK_YOU })

	lu.assertEquals(T.ids(t1), { "m1_won", "m1_manifest", "m1_pay", "m1_bite_to_eat" }, "mission 1 walk")
	lu.assertTrue(t1[4].stop, "m1_bite_to_eat ends the conversation")
	lu.assertEquals(t1[1].params.TU, "Ace", "m1_won: %NU")

	H.reset()

	local t2 = T.talk(pilot(2), (T.walkTo("m2_won", "duty_after_m2")))

	lu.assertEquals(T.ids(t2), { "m2_won", "m2_outstanding", "m2_promotion", "m2_pay_increase", "m2_lok_ops", "m2_threat", "m2_same_page", "duty_after_m2" }, "mission 2 walk")
	lu.assertEquals(t2[3].params.TU, "Ace", "m2_promotion: %NU")
	lu.assertEquals(T.optionSids(t2[8]), { "s_b2a924ab", "s_ac71da57" }, "duty_after_m2 replies")
	lu.assertEquals(T.linksOf(t2[8]), { "duty_briefing", "duty_menu" }, "duty_after_m2 links")
end

---------------------------------------------------------------------------------------------
-- The Claw (AC-12): the Morv briefing, the report, the key
---------------------------------------------------------------------------------------------

TestStormT2Claw = {}

TestStormT2Claw.setUp = setUp

-- AC-12: m3_offer sets the finding key on m3_codephrase, grants no quest
function TestStormT2Claw:test_the_morv_briefing_sets_the_finding_key_on_the_code_phrase_and_grants_no_quest()
	local starts = spyStarts()
	local player = T.pilot({ paid = 2, t2 = { 1 } })
	local t = T.talk(player, { "s_6abf6436", "s_fb7f6474", "s_edeedb42", "s_746fbd0c" })

	lu.assertEquals(T.ids(t), { "m3_offer", "m3_agent_report", "m3_find_out", "m3_codephrase", "m3_good_luck" }, "screens shown")
	lu.assertTrue(t[5].stop, "m3_good_luck ends the conversation")
	lu.assertEquals(t[1].params.TU, "Ace", "m3_offer: %NU")
	lu.assertEquals(t[5].params.TU, "Ace", "m3_good_luck: %NU")
	lu.assertEquals(H.getQuestStatus(player, T.FINDING_SUFFIX), "1", "the finding-agent key")
	lu.assertEquals(startedGlobals(starts), {}, "no quest is started (Q-1 = A)")
	lu.assertEquals(T.state(player, T.M3), "none", "the Claw is not in the journal")
	lu.assertNil(H.getQuestStatus(player, T.STATUS[3] .. ":attempted"), "no :attempted key for the Claw")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-12: the key is not set before the code phrase
function TestStormT2Claw:test_the_finding_key_is_not_set_before_the_code_phrase_screen()
	local player = T.pilot({ paid = 2, t2 = { 1 } })

	T.talk(player, { "s_6abf6436", "s_fb7f6474" })
	lu.assertNil(H.getQuestStatus(player, T.FINDING_SUFFIX), "after m3_find_out")
	T.drive(player, "m3_offer")
	lu.assertNil(H.getQuestStatus(player, T.FINDING_SUFFIX), "after m3_offer")
	T.drive(player, "m3_codephrase")
	lu.assertEquals(H.getQuestStatus(player, T.FINDING_SUFFIX), "1", "on m3_codephrase")
end

-- AC-12: the next talk
function TestStormT2Claw:test_after_the_briefing_every_talk_opens_find_morv_until_the_claw_is_won()
	local player = T.pilot({ paid = 2, t2 = { 1 } })

	T.talk(player, { "s_6abf6436", "s_fb7f6474", "s_edeedb42", "s_746fbd0c" })
	lu.assertEquals(T.firstScreen(player), "find_morv", "next talk")
	lu.assertEquals(T.firstScreen(player), "find_morv", "and the one after")

	T.setState(player, T.M3, "complete")
	lu.assertEquals(T.firstScreen(player), "claw_won", "once the Claw is won")
end

-- AC-12: the Claw report: pays once, clears the finding key, goes on to the duty menu
function TestStormT2Claw:test_the_claw_report_pays_clears_the_finding_key_and_goes_on_to_the_duty_menu()
	local player = pilot(3)
	local t = T.talk(player, { "s_e44ffcd2", "s_198d54a6", "s_94999d7b", T.DUTY_MENU_REPLY })

	lu.assertEquals(T.ids(t), { "claw_won", "claw_impressive", "claw_pay", "claw_next_step", "duty_menu" }, "screens shown")
	lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits")
	lu.assertEquals(T.items(player), { T.ITEMS[T.M3] }, "the ion booster")
	lu.assertEquals(standing(player), T.STANDING, "standing")
	lu.assertEquals(H.getQuestStatus(player, T.STATUS[3] .. ":reward"), "1", "the :reward key")
	lu.assertNil(H.getQuestStatus(player, T.FINDING_SUFFIX), "the finding key is cleared (J2 removeSpaceFlag('ss'))")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-12, I-9: the key stays cleared and nothing is paid again
function TestStormT2Claw:test_a_second_claw_report_pays_nothing_and_does_not_set_the_finding_key_again()
	local player = pilot(3)

	T.drive(player, "claw_pay")
	T.drive(player, "claw_pay")
	lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits")
	lu.assertNil(H.getQuestStatus(player, T.FINDING_SUFFIX), "the finding key")
end

-- AC-12: a Claw that failed or was aborted leaves the key set: back to Morv
function TestStormT2Claw:test_a_claw_that_was_not_won_keeps_the_pilot_at_find_morv()
	local player = T.pilot({ paid = 2, t2 = { 1 }, finding = true })

	lu.assertEquals(T.firstScreen(player), "find_morv", "finding set, no Claw")
	T.setState(player, T.M3, "active")
	lu.assertEquals(T.firstScreen(player), "on_mission", "an active Claw is a running mission")
end

-- AC-12: the claw_duties screen offers the duties only
function TestStormT2Claw:test_claw_duties_and_claw_next_step_offer_the_duty_menu_only()
	local t = T.talk(T.pilot({ paid = 3, t2 = { 1 } }), { T.DUTY_MENU_REPLY })

	lu.assertEquals(T.ids(t), { "claw_duties", "duty_menu" }, "screens shown")
	lu.assertEquals(T.optionSids(t[1]), { T.DUTY_MENU_REPLY }, "claw_duties has no briefing reply (the Claw is paid)")
end

---------------------------------------------------------------------------------------------
-- The Alozen orders (AC-12)
---------------------------------------------------------------------------------------------

TestStormT2Alozen = {}

TestStormT2Alozen.setUp = setUp

local ORDERS = { T.THANK_YOU, "s_72d41043", "s_de381f95", "s_6598178f", "s_8efde2ae" }

-- AC-12, D-8
function TestStormT2Alozen:test_the_orders_walk_sets_the_alozen_key_on_the_last_orders_screen_and_changes_nothing_else()
	local player = T.pilot({ paid = 3, t2 = { 1, 2 } })
	local pilotTier = player.ghost.pilotTier
	local t = T.talk(player, ORDERS)

	lu.assertEquals(T.ids(t), { "alozen_orders", "yavin_reassigned", "yavin_training", "yavin_salvage", "yavin_alozen", "yavin_ground_pounder" }, "screens shown")
	lu.assertTrue(t[6].stop, "yavin_ground_pounder ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, T.ALOZEN_SUFFIX), "1", "the Alozen key")
	lu.assertEquals(#T.held(player), 2, "no skill granted or taken")
	lu.assertEquals(#T.free() + #T.bought(), 0, "no grant call")
	lu.assertEquals(player.ghost.pilotTier, pilotTier, "the pilot tier stays (Alozen raises it, not Oberhaur)")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-12
function TestStormT2Alozen:test_the_alozen_key_is_not_set_before_yavin_alozen()
	local player = T.pilot({ paid = 3, t2 = { 1, 2 } })

	T.talk(player, { T.THANK_YOU, "s_72d41043", "s_de381f95" })
	T.drive(player, "alozen_orders")
	T.drive(player, "yavin_reassigned")
	T.drive(player, "yavin_salvage")
	lu.assertNil(H.getQuestStatus(player, T.ALOZEN_SUFFIX), "before yavin_alozen")
	T.drive(player, "yavin_alozen")
	lu.assertEquals(H.getQuestStatus(player, T.ALOZEN_SUFFIX), "1", "on yavin_alozen")
end

-- AC-12: every later talk
function TestStormT2Alozen:test_every_later_talk_opens_report_to_alozen_whatever_the_pilot_does()
	local player = T.pilot({ paid = 3, t2 = { 1, 2 } })

	T.talk(player, ORDERS)

	for i = 1, 3 do
		lu.assertEquals(T.firstScreen(player), "report_to_alozen", "talk " .. i)
	end

	player.ghost.experience.space_combat_general = 10 * T.TRAINING_COST
	lu.assertEquals(T.firstScreen(player), "report_to_alozen", "with XP to spare")
end

-- AC-12, FI-4: a pilot with three skills (bought elsewhere) is sent on too
function TestStormT2Alozen:test_a_pilot_with_three_skills_and_the_claw_paid_gets_the_orders_too()
	local player = T.pilot({ paid = 3, t2 = { 1, 2, 3 } })

	T.talk(player, ORDERS)
	lu.assertEquals(H.getQuestStatus(player, T.ALOZEN_SUFFIX), "1", "the Alozen key")
	lu.assertEquals(T.firstScreen(player), "report_to_alozen", "next talk")
end
