-- Field Commander Alozen: the three story missions (start, failure, retry), the three payments, the relic briefing and the Denner hand-off.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-7 (M1), AC-8, AC-10; Conversation flow 3 (table H) and 4; FA-4; D-12; I-9).
--
-- The amounts are J2b's (checked against the fixture in test_storm_tier2_alozen_data.lua). Credits are the bank credits of the fake pilot, items the
-- giveItem calls on its inventory, standing the ghost's Imperial standing. A failed and an aborted mission leave the same state (:attempted, no journal
-- entry active or complete), so one builder state ("failed") stands for both (FA-9).

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local CS = require("harness.client_strings")

A.load()

local function setUp()
	H.reset()
	A.requireConversation(lu)
end

local function standing(player) return player.ghost.factionStanding.imperial end

---------------------------------------------------------------------------------------------
-- Starting the missions
---------------------------------------------------------------------------------------------

TestAlozenStarts = {}

TestAlozenStarts.setUp = setUp

-- screen, quest global, mission number, pilot options that make the screen reachable
local STARTS = {
	{ screen = "m1_accept", global = A.M1, n = 1, pilot = { m = 0 }, from = "greeting" },
	{ screen = "m1_retry", global = A.M1, n = 1, pilot = { m = 0, state = "failed" }, from = "m1_failed" },
	{ screen = "m2_start", global = A.M2, n = 2, pilot = { m = 1 }, from = "m2_start" },
	{ screen = "m2_retry", global = A.M2, n = 2, pilot = { m = 1, state = "failed" }, from = "m2_failed" },
	{ screen = "m3_accept", global = A.M3, n = 3, pilot = { m = 2, t2 = { 1, 2, 3, 4 } }, from = "m3_offer" },
	{ screen = "m3_retry", global = A.M3, n = 3, pilot = { m = 2, state = "failed" }, from = "m3_failed" },
}

for _, s in ipairs(STARTS) do
	-- AC-7, AC-8, AC-10: a start screen sets its :attempted key and starts its head, once
	TestAlozenStarts["test_" .. s.screen .. "_starts_mission_" .. s.n .. "_and_sets_attempted"] = function()
		local starts = A.spyStarts()
		local player = A.pilot(s.pilot)

		A.drive(player, s.screen)
		lu.assertEquals(H.getQuestStatus(player, A.STATUS[s.n] .. ":attempted"), "1", s.screen .. ": the :attempted key")
		lu.assertEquals(#starts[s.global], 1, s.screen .. ": startQuest calls of " .. s.global)
		lu.assertEquals(starts[s.global][1].args[1], player, s.screen .. ": startQuest got the pilot")
		lu.assertEquals(A.startedGlobals(starts), { s.global .. " x1" }, s.screen .. ": no other quest starts")
		lu.assertNil(H.getQuestStatus(player, A.STATUS[s.n] .. ":reward"), s.screen .. ": no :reward key")
		lu.assertEquals(player.bankCredits, 0, s.screen .. ": no credits")
	end

	-- AC-7, AC-8, AC-10: the walk to the start screen starts nothing before it
	TestAlozenStarts["test_the_walk_to_" .. s.screen .. "_starts_nothing_before_it"] = function()
		local starts = A.spyStarts()
		local player = A.pilot(s.pilot)
		local replies, ids = A.walkTo(s.from, s.screen)

		lu.assertNotNil(replies, "Appendix A has a walk from " .. s.from .. " to " .. s.screen)

		if #replies > 0 then
			local t = A.talk(player, { table.unpack(replies, 1, #replies - 1) })

			lu.assertEquals(A.ids(t), { table.unpack(ids, 1, #ids - 1) }, "screens before the start screen")
			lu.assertEquals(A.startedGlobals(starts), {}, "nothing started before " .. s.screen)

			if not s.screen:find("retry") then
				lu.assertNil(H.getQuestStatus(player, A.STATUS[s.n] .. ":attempted"), "no :attempted key before " .. s.screen)
			end
		end
	end
end

-- AC-7: the first talk of the arrival walk starts M1 at its end only
function TestAlozenStarts:test_the_oberhaur_reply_walks_the_briefing_to_m1_accept_through_13_screens()
	local starts = A.spyStarts()
	local player = A.pilot()
	local replies, ids = A.walkTo("greeting", "m1_accept")

	lu.assertEquals(#ids, 13, "Appendix A screens from the greeting to m1_accept")
	lu.assertEquals(replies[1], "s_2eaae5bc", "the first reply is the Oberhaur reply")

	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertEquals(A.ids(t)[2], "m1_late", "the first briefing screen")
	lu.assertTrue(t[#t].stop, "m1_accept ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M1 .. " x1" }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[1] .. ":attempted"), "1", "M1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the failure walk, a failed or aborted mission
function TestAlozenStarts:test_a_failed_or_aborted_mission_1_walks_to_the_retry_which_restarts_it()
	local starts = A.spyStarts()
	local player = A.pilot({ state = "failed" })
	local replies, ids = A.walkTo("m1_failed", "m1_retry")
	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertEquals(ids, { "m1_failed", "m1_no_relic", "m1_advice", "m1_retry" }, "Appendix A walk")
	lu.assertTrue(t[#t].stop, "m1_retry ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M1 .. " x1" }, "mission 1 restarted once")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[1] .. ":attempted"), "1", ":attempted stays")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-8
function TestAlozenStarts:test_a_failed_or_aborted_mission_2_walks_to_the_retry_which_restarts_it()
	local starts = A.spyStarts()
	local player = A.pilot({ m = 1, state = "failed" })
	local replies, ids = A.walkTo("m2_failed", "m2_retry")
	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertEquals(ids, { "m2_failed", "m2_only_pilot", "m2_my_way", "m2_reprimand", "m2_retry" }, "Appendix A walk")
	lu.assertTrue(t[#t].stop, "m2_retry ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M2 .. " x1" }, "mission 2 restarted once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10
function TestAlozenStarts:test_the_mission_3_offer_walks_through_six_briefing_screens_to_the_accept_screen()
	local starts = A.spyStarts()
	local player = A.pilot({ m = 2, t2 = { 1, 2, 3, 4 } })
	local replies, ids = A.walkTo("m3_offer", "m3_accept")

	lu.assertEquals(ids, { "m3_offer", "m3_scan_results", "m3_gunboat", "m3_disable", "m3_boarding", "m3_omega", "m3_accept" }, "Appendix A walk")

	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertTrue(t[#t].stop, "m3_accept ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M3 .. " x1" }, "mission 3 started once")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[3] .. ":attempted"), "1", "M3 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10
function TestAlozenStarts:test_a_failed_or_aborted_mission_3_walks_to_the_retry_which_restarts_it()
	local starts = A.spyStarts()
	local player = A.pilot({ m = 2, state = "failed" })
	local t = A.talk(player, A.walkTo("m3_failed", "m3_retry"))

	lu.assertEquals(A.ids(t), { "m3_failed", "m3_another_crack", "m3_retry" }, "screens shown")
	lu.assertTrue(t[3].stop, "m3_retry ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M3 .. " x1" }, "mission 3 restarted once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-8: the pilot who left before m2_start gets it on the next talk and M2 starts
function TestAlozenStarts:test_m2_never_started_opens_m2_start_which_starts_it_on_the_next_talk()
	local starts = A.spyStarts()
	local player = A.pilot({ m = 1 })
	local t = A.talk(player)

	lu.assertEquals(A.ids(t), { "m2_start" }, "first screen")
	lu.assertEquals(A.startedGlobals(starts), { A.M2 .. " x1" }, "M2 starts when m2_start is shown")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[2] .. ":attempted"), "1", "M2 :attempted")
end

-- AC-7, AC-8, AC-10: really started, the journal entry is active (a ship in the quest zone)
function TestAlozenStarts:test_the_start_screens_leave_the_journal_entry_active_in_a_ship_in_yavin_4()
	for _, s in ipairs({ { "m1_accept", A.M1, { m = 0 } }, { "m2_start", A.M2, { m = 1 } }, { "m3_accept", A.M3, { m = 2, t2 = { 1, 2, 3, 4 } } } }) do
		H.reset()
		A.quest(s[2]):start()

		local opts = { inShip = true, zone = "space_yavin4" }

		for k, v in pairs(s[3]) do
			opts[k] = v
		end

		local player = A.pilot(opts)
		local ok, err = pcall(function()
			A.drive(player, s[1])
			H.advance(0)
		end)

		lu.assertTrue(ok, s[1] .. ": raised a Lua error: " .. tostring(err))
		lu.assertEquals(A.state(player, s[2]), "active", s[1] .. ": the journal entry of " .. s[2])
	end
end

---------------------------------------------------------------------------------------------
-- The three payments (I-9)
---------------------------------------------------------------------------------------------

-- n, head, the screen that pays, the won screen, the screen the won walk ends on, the first screen of the next talk, the item (M1 only), the pilot builder
local GROUPS = {
	{ n = 1, global = A.M1, screen = "m1_pay", won = "m1_won", walkEnd = "m2_start", next = "m2_start", item = A.ITEM, pilot = { m = 0, state = "won" } },
	{ n = 2, global = A.M2, screen = "m2_won", won = "m2_won", walkEnd = "m2_buy_time", next = "duty_block", pilot = { m = 1, state = "won" } },
	{ n = 3, global = A.M3, screen = "m3_pay", won = "m3_won", walkEnd = "m3_pay", next = "denner_transfer", pilot = { m = 2, state = "won", t2 = { 1, 2, 3, 4 } } },
}

local function pilot(g, extra)
	local o = {}

	for k, v in pairs(g.pilot) do
		o[k] = v
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return A.pilot(o)
end

TestAlozenRewards = {}

TestAlozenRewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	-- AC-8, AC-10, I-9: the pay screen pays credits, the item (M1) and standing, once
	TestAlozenRewards["test_" .. g.screen .. "_pays_mission_" .. g.n] = function()
		local player = pilot(g)

		A.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, A.CREDITS, g.screen .. ": bank credits")
		lu.assertEquals(#player.bankCreditLog, 1, g.screen .. ": addBankCredits calls")
		lu.assertEquals(A.items(player), g.item and { g.item } or {}, g.screen .. ": giveItem templates")
		lu.assertEquals(standing(player), A.STANDING[g.n], g.screen .. ": Imperial standing")
		lu.assertEquals(H.getQuestStatus(player, A.STATUS[g.n] .. ":reward"), "1", g.screen .. ": the :reward key")
	end

	-- I-9: the same screen shown again
	TestAlozenRewards["test_" .. g.screen .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g)

		for _ = 1, 3 do
			A.drive(player, g.screen)
		end

		lu.assertEquals(player.bankCredits, A.CREDITS, g.screen .. ": bank credits after three visits")
		lu.assertEquals(#A.items(player), g.item and 1 or 0, g.screen .. ": items after three visits")
		lu.assertEquals(standing(player), A.STANDING[g.n], g.screen .. ": standing after three visits")
	end

	-- I-9: a mission that was paid before pays nothing
	TestAlozenRewards["test_" .. g.screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g)

		H.setQuestStatus(player, A.STATUS[g.n] .. ":reward", 1)
		A.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, 0, g.screen .. ": bank credits")
		lu.assertEquals(#A.items(player), 0, g.screen .. ": items")
		lu.assertEquals(standing(player), 0, g.screen .. ": standing")
	end

	-- AC-8, AC-10: the walk from the won screen pays once and ends where the story goes on
	TestAlozenRewards["test_the_mission_" .. g.n .. "_won_walk_pays_once_and_ends_where_the_story_goes_on"] = function()
		local replies, ids = A.walkTo(g.won, g.walkEnd)

		lu.assertNotNil(replies, "Appendix A has a walk from " .. g.won .. " to " .. g.walkEnd)

		local player = pilot(g)
		local t = A.talk(player, replies)

		lu.assertEquals(A.ids(t), ids, "screens shown")
		lu.assertEquals(player.bankCredits, A.CREDITS, "bank credits")
		lu.assertEquals(A.items(player), g.item and { g.item } or {}, "giveItem templates")
		lu.assertEquals(standing(player), A.STANDING[g.n], "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end

	-- I-9: the pilot who walks away after the pay screen is paid, and the next talk opens what comes next
	TestAlozenRewards["test_after_mission_" .. g.n .. "_is_paid_the_next_visit_opens_" .. g.next] = function()
		local player = pilot(g)

		A.drive(player, g.screen)
		lu.assertEquals(A.firstScreen(player), g.next, "first screen after the payment")
		lu.assertEquals(player.bankCredits, A.CREDITS, "the next talk pays nothing more")
	end

	-- I-9: a pay screen pays only its own mission
	TestAlozenRewards["test_" .. g.screen .. "_sets_no_other_missions_reward_key"] = function()
		local player = pilot(g)

		A.drive(player, g.screen)

		for n = 1, 3 do
			if n > g.n then
				lu.assertNil(H.getQuestStatus(player, A.STATUS[n] .. ":reward"), "mission " .. n .. " stays unpaid")
			end
		end
	end
end

-- AC-8, I-9: the item is M1's only (M2 and M3 are credit-only)
for _, g in ipairs({ GROUPS[1] }) do
	-- AC-8: the item is paid to any species
	TestAlozenRewards["test_mission_1_pays_the_same_item_to_a_wookiee"] = function()
		local player = pilot(g, { species = SPECIES_WOOKIEE })

		A.drive(player, g.screen)
		lu.assertEquals(A.items(player), { g.item }, "giveItem templates for a Wookiee")
	end

	-- AC-8: the item uses the overload, so a full inventory still receives it
	TestAlozenRewards["test_mission_1_item_reaches_a_full_inventory"] = function()
		local player = pilot(g, { inventory = { limit = 0 } })

		A.drive(player, g.screen)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end
end

-- AC-8: the first screen of a won M1 and M3 does not pay (the pay screen does); M2 pays on its won screen
function TestAlozenRewards:test_the_won_screens_of_mission_1_and_3_do_not_pay_before_the_pay_screen()
	for _, g in ipairs({ GROUPS[1], GROUPS[3] }) do
		local player = pilot(g)
		local t = A.talk(player)

		lu.assertEquals(t[1].id, g.won, "first screen")
		lu.assertEquals(player.bankCredits, 0, g.won .. ": bank credits")
		lu.assertEquals(#A.items(player), 0, g.won .. ": items")
		lu.assertEquals(standing(player), 0, g.won .. ": standing")
		lu.assertNil(H.getQuestStatus(player, A.STATUS[g.n] .. ":reward"), g.won .. ": no :reward key yet")
	end
end

-- AC-8: M2 pays when m2_won is shown, even as the first screen
function TestAlozenRewards:test_mission_2_pays_on_the_first_screen_it_is_shown()
	local player = pilot(GROUPS[2])
	local t = A.talk(player)

	lu.assertEquals(A.ids(t), { "m2_won" }, "first screen")
	lu.assertEquals(t[1].params.TU, "Ace", "m2_won: %NU")
	lu.assertEquals(player.bankCredits, A.CREDITS, "bank credits")
	lu.assertEquals(standing(player), 50, "Imperial standing")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[2] .. ":reward"), "1", "the :reward key")
end

-- AC-8: M1's walk continues through the region line into the M2 start, which starts M2
function TestAlozenRewards:test_the_mission_1_walk_ends_on_m2_start_which_starts_escort_5()
	local starts = A.spyStarts()
	local player = pilot(GROUPS[1])
	local replies, ids = A.walkTo("m1_won", "m2_start")
	local t = A.talk(player, replies)

	lu.assertEquals(ids, { "m1_won", "m1_pay", "m1_region", "m2_start" }, "Appendix A walk")
	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertTrue(t[4].stop, "m2_start ends the conversation")
	lu.assertEquals(A.startedGlobals(starts), { A.M2 .. " x1" }, "M2 starts")
	lu.assertEquals(H.getQuestStatus(player, A.STATUS[2] .. ":attempted"), "1", "M2 :attempted")
	lu.assertNil(H.getQuestStatus(player, A.STATUS[2] .. ":reward"), "M2 is not paid")
	lu.assertEquals(player.bankCredits, A.CREDITS, "only M1 is paid")
end

-- AC-8: after M2's pay, the relic briefing runs to its end, or the duty menu
function TestAlozenRewards:test_mission_2_offers_the_relic_briefing_and_the_duty_menu()
	local player = pilot(GROUPS[2])
	local replies, ids = A.walkTo("m2_won", "relic_refine")

	lu.assertEquals(ids, { "m2_won", "m2_processing", "m2_buy_time", "relic_core", "relic_mon_cal", "relic_lid", "relic_refine" }, "Appendix A walk")

	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertTrue(t[#t].stop, "relic_refine ends the conversation")
	lu.assertEquals(player.bankCredits, A.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

	H.reset()

	local menu = A.talk(pilot(GROUPS[2]), { "s_5365b13d", "s_57c8489e", "s_5a7ec1e4" })

	lu.assertEquals(A.ids(menu), { "m2_won", "m2_processing", "m2_buy_time", "duty_menu" }, "the duty menu from the M2 walk")
end

-- AC-10: mission 3's won walk names Denner and sets the interface key
function TestAlozenRewards:test_the_mission_3_won_walk_pays_names_denner_and_sets_the_tier_3_interface_key()
	local player = pilot(GROUPS[3])
	local replies, ids = A.walkTo("m3_won", "m3_pay")

	lu.assertEquals(ids, { "m3_won", "m3_transferred", "m3_priority_alpha", "m3_not_privy", "m3_pay" }, "Appendix A walk")

	local t = A.talk(player, replies)

	lu.assertEquals(A.ids(t), ids, "screens shown")
	lu.assertTrue(t[#t].stop, "m3_pay ends the conversation")
	lu.assertEquals(H.getQuestStatus(player, "imperial_ss_6:reward"), "1", "<playerID>imperial_ss_6:reward (Denner's interface)")
	lu.assertEquals(player.bankCredits, A.CREDITS, "paid once")
end

-- AC-10: every later talk opens denner_transfer and grants nothing
function TestAlozenRewards:test_after_the_hand_off_every_talk_opens_denner_transfer_and_grants_nothing()
	local player = pilot(GROUPS[3])

	A.drive(player, "m3_pay")

	for _ = 1, 3 do
		local t = A.talk(player)

		lu.assertEquals(A.ids(t), { "denner_transfer" }, "later talk")
	end

	lu.assertEquals(player.bankCredits, A.CREDITS, "credits unchanged")
	lu.assertEquals(standing(player), 50, "standing unchanged")
	lu.assertEquals(#A.free() + #A.bought(), 0, "no skill granted")
end
