-- Shamdon Kree: the four mission rewards (5000 credits and a ship component each) paid once, on the greeting (mission 1) or on the reply (missions 2-4),
-- the "another assignment?" follow-up (C-5), and the tier 2 "bad news" with the pilot tier 3 (Q1 = A).
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-9, AC-10 Shamdon half; Conversation flow 2 (C-4, C-5), 3 (table H), 5, 6; FS-4, FS-5, FS-6; D-7, D-10; I-5).
--
-- The amounts and items are SHJ's (parsed from the fixture by smuggler_tier2_data.lua M.shamdonRewards). Credits are the bank credits of the fake pilot,
-- items the giveItem calls on its inventory.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local CS = require("harness.client_strings")

M.load()

local spies

local function setUp()
	H.reset()
	M.requireConversation(lu)
	spies = {}

	for _, g in ipairs(M.questTables()) do
		spies[g] = H.spyOn(rawget(_G, g), "startQuest")
	end
end

local function items(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if call[1] == player.inventory then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function itemOf(n)
	local id = M.IDENTITY[M.HEADS[n]]

	return M.shamdonRewards()[id.type .. "/" .. id.name].item
end

local function reachable(n) return M.trainFor(n).x end

-- Mission n won and unpaid; the missions before it (in number) paid; its skill held (a partial career: the others are not bought)
local function winner(n, extra)
	local missions = { [n] = "won" }

	local o = { skills2 = { reachable(n) }, missions = missions }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

-- Mission n won and unpaid, the other three paid, all four skills held: finishing mission n completes tier 2
local function finisher(n, extra)
	local missions = {}

	for k = 1, 4 do
		missions[k] = k == n and "won" or "paid"
	end

	local o = { all4 = true, missions = missions }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

local function paidOnce(player, n, label)
	lu.assertEquals(player.bankCredits, M.MISSION_CREDITS, label .. ": bank credits")
	lu.assertEquals(#player.bankCreditLog, 1, label .. ": addBankCredits calls")
	lu.assertEquals(items(player), { itemOf(n) }, label .. ": giveItem templates")
	lu.assertEquals(H.getQuestStatus(player, M.STATUS_NAMES[n] .. ":reward"), "1", label .. ": the :reward key")
end

local function notPaid(player, n, label)
	lu.assertEquals(player.bankCredits, 0, label .. ": bank credits")
	lu.assertEquals(#items(player), 0, label .. ": items")
	lu.assertNil(H.getQuestStatus(player, M.STATUS_NAMES[n] .. ":reward"), label .. ": the :reward key")
end

---------------------------------------------------------------------------------------------
-- AC-9: when each reward is paid
---------------------------------------------------------------------------------------------

TestSmugglerT2Rewards = {}

TestSmugglerT2Rewards.setUp = setUp

-- AC-9, D-7: mission 1 pays on the greeting
function TestSmugglerT2Rewards:test_m1_reward_pays_mission_1_on_display()
	local player = winner(1)
	local t = M.talk(player)

	lu.assertEquals(M.ids(t), { "m1_reward" }, "first screen")
	paidOnce(player, 1, "m1_reward")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9, I-5: shown three times pays once
function TestSmugglerT2Rewards:test_m1_reward_shown_three_times_pays_once()
	local player = winner(1)

	for _ = 1, 3 do
		M.drive(player, "m1_reward")
	end

	paidOnce(player, 1, "three displays")
end

-- AC-9: the item is the same for every species (species = {-1})
function TestSmugglerT2Rewards:test_the_item_is_given_to_every_species()
	for _, species in ipairs({ SPECIES_HUMAN, SPECIES_ZABRAK, SPECIES_WOOKIEE, SPECIES_ITHORIAN }) do
		H.reset()

		local player = winner(1, { species = species })

		M.talk(player)
		paidOnce(player, 1, "species " .. species)
	end
end

-- AC-9: a mission paid before pays nothing
function TestSmugglerT2Rewards:test_a_paid_key_stops_the_payment()
	local player = winner(1)

	H.setQuestStatus(player, M.STATUS_NAMES[1] .. ":reward", 1)
	M.drive(player, "m1_reward")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#items(player), 0, "items")
end

-- AC-9: the reward screens of missions 2-4 pay nothing on display
function TestSmugglerT2Rewards:test_the_reward_screens_of_missions_2_to_4_pay_nothing_on_display()
	for _, c in ipairs({ { 2, "m2_reward" }, { 3, "m3_reward" }, { 4, "m4_reward" } }) do
		local player = winner(c[1])
		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { c[2] }, "first screen of mission " .. c[1])
		notPaid(player, c[1], c[2] .. " display")
	end
end

-- AC-9: m3_eliminate is a step before the payment
function TestSmugglerT2Rewards:test_m3_reward_and_its_first_reply_pay_nothing_the_second_reply_pays()
	local player = winner(3)
	local t = M.talk(player, { "s_1fe46aff" })

	lu.assertEquals(M.ids(t), { "m3_reward", "m3_eliminate" }, "walk")
	notPaid(player, 3, "m3_eliminate display")

	local paid = M.talk(player, { "s_1fe46aff", "s_8179979d" })

	lu.assertEquals(M.ids(paid), { "m3_reward", "m3_eliminate", "m3_paid_naturally" }, "walk to the paid screen")
	paidOnce(player, 3, "m3_paid_naturally")
end

-- AC-9, D-7: missions 2-4 pay on the reply, for each reply
local REPLIES = {
	{ n = 2, path = {}, replies = { { "s_4362ba26", "m2_paid" }, { "s_43f63a81", "m2_paid" }, { "s_9f5f269", "m2_paid" } }, first = "m2_reward" },
	{ n = 3, path = { "s_1fe46aff" }, replies = { { "s_8179979d", "m3_paid_naturally" }, { "s_d70dba34", "m3_paid_yes" } }, first = "m3_reward", middle = "m3_eliminate" },
	{ n = 4, path = {}, replies = { { "s_eca7c053", "m4_paid_fine" }, { "s_766563c7", "m4_paid_handle" } }, first = "m4_reward" },
}

for _, g in ipairs(REPLIES) do
	for _, r in ipairs(g.replies) do
		TestSmugglerT2Rewards["test_mission_" .. g.n .. "_pays_5000_and_its_item_on_the_reply_" .. r[1]] = function()
			local player = winner(g.n)
			local choices = {}

			for _, c in ipairs(g.path) do
				choices[#choices + 1] = c
			end

			choices[#choices + 1] = r[1]

			local t = M.talk(player, choices)
			local want = { g.first }

			if g.middle then
				want[#want + 1] = g.middle
			end

			want[#want + 1] = r[2]
			lu.assertEquals(M.ids(t), want, "walk")
			paidOnce(player, g.n, r[2])
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-9, I-5: the same reply three times (the talk restarted on the reward screen each time) pays once
	TestSmugglerT2Rewards["test_mission_" .. g.n .. "_replied_to_three_times_pays_once"] = function()
		local player = winner(g.n)

		for _ = 1, 3 do
			local choices = {}

			for _, c in ipairs(g.path) do
				choices[#choices + 1] = c
			end

			choices[#choices + 1] = g.replies[1][1]
			M.drive(player, g.first, choices)
		end

		paidOnce(player, g.n, "three replies")
	end

	-- AC-9, R-6: the window closed before the reply: unpaid, the same reward screen the next time
	TestSmugglerT2Rewards["test_closing_the_window_on_the_mission_" .. g.n .. "_reward_screens_pays_nothing_and_the_next_talk_opens_the_same_screen"] = function()
		local player = winner(g.n)
		local choices = {}

		for _, c in ipairs(g.path) do
			choices[#choices + 1] = c
		end

		M.talk(player, choices)
		notPaid(player, g.n, "window closed")
		lu.assertEquals(M.firstScreen(player), g.first, "the next talk opens the same reward screen")
		notPaid(player, g.n, "second display")
	end
end

-- AC-9, I-5: a paid key stops the second payment of every reply path
function TestSmugglerT2Rewards:test_a_paid_key_stops_the_payment_on_the_reply()
	for n = 2, 4 do
		local player = winner(n)

		H.setQuestStatus(player, M.STATUS_NAMES[n] .. ":reward", 1)
		M.drive(player, "m" .. n .. "_reward", n == 3 and { "s_1fe46aff", "s_8179979d" } or { n == 2 and "s_4362ba26" or "s_eca7c053" })
		lu.assertEquals(player.bankCredits, 0, "mission " .. n .. ": bank credits")
	end
end

-- AC-9: only the reward of its own mission is paid
function TestSmugglerT2Rewards:test_a_reward_pays_only_its_own_mission()
	local rewards = {}

	for n = 1, 4 do
		rewards[n] = H.spyOn(M.quest(M.HEADS[n]), "rewardPlayer")
	end

	local player = winner(2)

	M.talk(player, { "s_4362ba26" })
	lu.assertEquals({ #rewards[1], #rewards[2], #rewards[3], #rewards[4] }, { 0, 1, 0, 0 }, "rewardPlayer calls of missions 1-4")
	lu.assertEquals(rewards[2][1].args[1], player, "rewardPlayer gets the pilot")
end

-- AC-9: payMission is idempotent and sets the key (direct call)
function TestSmugglerT2Rewards:test_payMission_pays_once_and_sets_the_key()
	for n = 1, 4 do
		H.reset()

		local rewards = H.spyOn(M.quest(M.HEADS[n]), "rewardPlayer")
		local player = winner(n)

		M.handler():payMission(player, n)
		M.handler():payMission(player, n)
		lu.assertEquals(#rewards, 1, "mission " .. n .. ": rewardPlayer calls after two payMission")
		lu.assertEquals(H.getQuestStatus(player, M.STATUS_NAMES[n] .. ":reward"), "1", "mission " .. n .. ": key")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9, C-4, C-5: the follow-up
---------------------------------------------------------------------------------------------

-- AC-9: with all four skills every reply leads to bad_news_reply (and the payment still happens)
function TestSmugglerT2Rewards:test_with_all_four_skills_every_reply_leads_to_bad_news_reply()
	local paths = {
		{ 1, { "s_bc000879" }, { "m1_reward", "bad_news_reply" } },
		{ 1, { "s_34e4d30" }, { "m1_reward", "bad_news_reply" } },
		{ 2, { "s_4362ba26" }, { "m2_reward", "bad_news_reply" } },
		{ 2, { "s_43f63a81" }, { "m2_reward", "bad_news_reply" } },
		{ 2, { "s_9f5f269" }, { "m2_reward", "bad_news_reply" } },
		{ 3, { "s_1fe46aff", "s_8179979d" }, { "m3_reward", "m3_eliminate", "bad_news_reply" } },
		{ 3, { "s_1fe46aff", "s_d70dba34" }, { "m3_reward", "m3_eliminate", "bad_news_reply" } },
		{ 4, { "s_eca7c053" }, { "m4_reward", "bad_news_reply" } },
		{ 4, { "s_766563c7" }, { "m4_reward", "bad_news_reply" } },
	}

	for _, p in ipairs(paths) do
		H.reset()

		local player = finisher(p[1])
		local t = M.talk(player, p[2])

		lu.assertEquals(M.ids(t), p[3], "mission " .. p[1] .. " via " .. table.concat(p[2], ","))
		paidOnce(player, p[1], "mission " .. p[1])
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9, C-4: m1_reward's two replies are rebuilt for a graduate and keep the defaults otherwise
function TestSmugglerT2Rewards:test_m1_reward_replies_lead_to_the_nothing_and_doubt_lines_unless_tier_2_is_complete()
	local t = M.drive(winner(1), "m1_reward")

	lu.assertEquals(M.optionSids(t[1]), { "s_bc000879", "s_34e4d30" }, "m1_reward replies")
	lu.assertEquals(M.linksOf(t[1]), { "m1_reward_nothing", "m1_reward_doubt" }, "m1_reward links")

	local g = M.drive(finisher(1), "m1_reward")

	lu.assertEquals(M.optionSids(g[1]), { "s_bc000879", "s_34e4d30" }, "m1_reward replies (graduate)")
	lu.assertEquals(M.linksOf(g[1]), { "bad_news_reply", "bad_news_reply" }, "m1_reward links (graduate)")
end

-- AC-9, C-5: the "another assignment?" screens offer Sure (training) with the XP and a skill to buy, Ok (duty menu) otherwise, plus the no reply
local ANOTHER = {
	{ screen = "m1_reward_nothing", n = 1, no = { "s_d6695e83", "come_back" } },
	{ screen = "m1_reward_doubt", n = 1, no = { "s_d6695e83", "come_back" } },
	{ screen = "m2_paid", n = 2, no = { "s_d6695e83", "come_back" } },
	{ screen = "m3_paid_naturally", n = 3, no = { "s_d6695e83", "come_back_soon" } },
	{ screen = "m3_paid_yes", n = 3, no = { "s_d6695e83", "come_back_soon" } },
	{ screen = "m4_paid_fine", n = 4, no = { "s_360d8728", "come_back" } },
	{ screen = "m4_paid_handle", n = 4, no = { "s_360d8728", "come_back" } },
}

for _, a in ipairs(ANOTHER) do
	-- AC-9, C-5, FS-5
	TestSmugglerT2Rewards["test_" .. a.screen .. "_offers_sure_when_the_pilot_can_buy_a_skill"] = function()
		local player = M.pilot({ skills2 = { reachable(a.n) }, missions = { [a.n] = "paid" }, xp = 60000 })
		local t = M.drive(player, a.screen)

		lu.assertEquals(M.optionSids(t[1]), { "s_8be640b8", a.no[1] }, a.screen .. ": replies")
		lu.assertEquals(M.linksOf(t[1]), { "training", a.no[2] }, a.screen .. ": links (Sure goes to the screen getInitialScreen returns)")
	end

	-- AC-9, C-5
	TestSmugglerT2Rewards["test_" .. a.screen .. "_offers_ok_when_the_pilot_cannot_buy_a_skill"] = function()
		for _, o in ipairs({
			{ skills2 = { reachable(a.n) }, missions = { [a.n] = "paid" }, xp = 59999 },
			{ skills2 = { reachable(a.n), a.n == 1 and "droid" or "starships" }, missions = { [a.n] = "paid" }, xp = 60000 }, -- another skill is waiting for its mission
		}) do
			local t = M.drive(M.pilot(o), a.screen)

			lu.assertEquals(M.optionSids(t[1]), { "s_895d093", a.no[1] }, a.screen .. ": replies")
			lu.assertEquals(M.linksOf(t[1]), { "duty_menu", a.no[2] }, a.screen .. ": links")
		end
	end
end

-- AC-9: Sure leads on to the training, Ok to the duty menu and its duties, the no reply ends the talk
function TestSmugglerT2Rewards:test_the_follow_up_walks()
	local player = M.pilot({ skills2 = { "droid" }, missions = { [2] = "won" }, xp = 60000 })
	local t = M.talk(player, { "s_4362ba26", "s_8be640b8" })

	lu.assertEquals(M.ids(t), { "m2_reward", "m2_paid", "training" }, "m2 then Sure")
	paidOnce(player, 2, "m2")

	local ok = M.pilot({ skills2 = { "weapons" }, missions = { [3] = "won" }, xp = 0 })
	local u = M.talk(ok, { "s_1fe46aff", "s_d70dba34", "s_895d093" })

	lu.assertEquals(M.ids(u), { "m3_reward", "m3_eliminate", "m3_paid_yes", "duty_menu" }, "m3 then Ok")
	lu.assertEquals(M.optionSids(u[4]), { "s_c631f8da", "s_6ff30da7", "s_93ba78e7" }, "duty_menu replies")
	lu.assertEquals(M.linksOf(u[4]), { "duty_escort", "duty_recovery", "duty_destroy" }, "duty_menu links")

	local no = M.talk(M.pilot({ skills2 = { "weapons" }, missions = { [3] = "won" } }), { "s_1fe46aff", "s_8179979d", "s_d6695e83" })

	lu.assertEquals(M.ids(no), { "m3_reward", "m3_eliminate", "m3_paid_naturally", "come_back_soon" }, "m3 then No")
	lu.assertTrue(no[4].stop, "come_back_soon ends the conversation")

	local no4 = M.talk(M.pilot({ skills2 = { "procedures" }, missions = { [4] = "won" } }), { "s_eca7c053", "s_360d8728" })

	lu.assertEquals(M.ids(no4), { "m4_reward", "m4_paid_fine", "come_back" }, "m4 then No")
	lu.assertTrue(no4[3].stop, "come_back ends the conversation")
end

-- AC-9: the duty menu starts the three duties
function TestSmugglerT2Rewards:test_the_duty_menu_starts_each_duty_once()
	local cases = { { "s_c631f8da", "duty_escort", M.DUTY_ESCORT }, { "s_6ff30da7", "duty_recovery", M.DUTY_RECOVERY }, { "s_93ba78e7", "duty_destroy", M.DUTY_DESTROY } }

	for _, c in ipairs(cases) do
		H.reset()
		spies = {}

		for _, g in ipairs(M.questTables()) do
			spies[g] = H.spyOn(rawget(_G, g), "startQuest")
		end

		local player = M.pilot({ skills2 = { "starships" }, missions = { [1] = "won" } })
		local t = M.talk(player, { "s_bc000879", "s_895d093", c[1] })

		lu.assertEquals(M.ids(t), { "m1_reward", "m1_reward_nothing", "duty_menu", c[2] }, "walk to " .. c[2])
		lu.assertTrue(t[4].stop, c[2] .. " ends the conversation")
		lu.assertEquals(#spies[c[3]], 1, c[3] .. ":startQuest calls")
		lu.assertEquals(spies[c[3]][1].args[1], player, c[3] .. ":startQuest gets the pilot")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: the tier 2 "bad news" and pilot tier 3 (Q1 = A)
---------------------------------------------------------------------------------------------

TestSmugglerT2BadNews = {}

TestSmugglerT2BadNews.setUp = setUp

-- the four walks from bad_news / bad_news_reply to see_karrde: { replies, ids after the entry screen }
local ROUTES = {
	{ { "s_1c8bddbb", "s_ff5b4126", "s_114c29a9", "s_725573da" }, { "jabba_thug", "competitors", "too_successful", "see_karrde" } },
	{ { "s_1c8bddbb", "s_71a8cc01", "s_8a24761e", "s_114c29a9", "s_725573da" }, { "jabba_thug", "death_mark", "competitors", "too_successful", "see_karrde" } },
	{ { "s_1c8bddbb", "s_ff5b4126", "s_114c29a9", "s_474f9205", "s_725573da" }, { "jabba_thug", "competitors", "too_successful", "naive", "see_karrde" } },
	{ { "s_1c8bddbb", "s_71a8cc01", "s_8a24761e", "s_114c29a9", "s_474f9205", "s_725573da" }, { "jabba_thug", "death_mark", "competitors", "too_successful", "naive", "see_karrde" } },
}

-- AC-10: both Jabba routes, with and without the naive detour, end on see_karrde (which ends the talk)
function TestSmugglerT2BadNews:test_every_route_from_bad_news_ends_on_see_karrde()
	for i, r in ipairs(ROUTES) do
		H.reset()

		local want = { "bad_news" }

		for _, id in ipairs(r[2]) do
			want[#want + 1] = id
		end

		local t = M.talk(M.pilot({ all4 = true }), r[1])

		lu.assertEquals(M.ids(t), want, "route " .. i)
		lu.assertTrue(t[#t].stop, "see_karrde ends the conversation (route " .. i .. ")")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of route " .. i)
	end
end

-- AC-10: the same routes from bad_news_reply
function TestSmugglerT2BadNews:test_every_route_from_bad_news_reply_ends_on_see_karrde()
	for i, r in ipairs(ROUTES) do
		H.reset()

		local want = { "bad_news_reply" }

		for _, id in ipairs(r[2]) do
			want[#want + 1] = id
		end

		local t = M.drive(M.pilot({ all4 = true }), "bad_news_reply", r[1])

		lu.assertEquals(M.ids(t), want, "route " .. i)
		lu.assertTrue(t[#t].stop, "see_karrde ends the conversation (route " .. i .. ")")
	end
end

-- AC-10, Q1 = A, D-10: pilot tier 3 on the bad news, once
function TestSmugglerT2BadNews:test_the_bad_news_sets_pilot_tier_3_once()
	for _, screen in ipairs({ "bad_news", "bad_news_reply" }) do
		H.reset()

		local player = M.pilot({ all4 = true })

		lu.assertEquals(player.ghost.pilotTier, 2, "precondition: pilot tier 2")
		M.drive(player, screen)
		lu.assertEquals(player.ghost.pilotTier, 3, screen .. ": pilot tier after the first display")
		M.drive(player, screen)
		M.drive(player, screen)
		lu.assertEquals(player.ghost.pilotTier, 3, screen .. ": pilot tier after three displays")
	end
end

-- AC-10, Q1 = A: the tier moves only from 2 and only for a graduate
function TestSmugglerT2BadNews:test_the_bad_news_leaves_other_tiers_and_incomplete_pilots_alone()
	for _, tier in ipairs({ 1, 3, 4 }) do
		local player = M.pilot({ all4 = true, pilotTier = tier })

		M.drive(player, "bad_news")
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. " after bad_news")
	end

	for _, screen in ipairs({ "bad_news", "bad_news_reply" }) do
		local player = M.pilot({ tier2 = 3, missions = { [1] = "paid", [2] = "paid", [3] = "paid" } })

		M.drive(player, screen)
		lu.assertEquals(player.ghost.pilotTier, 2, screen .. " shown to a pilot with three tier 2 skills")
	end
end

-- AC-10: the last reward of the tier leads to bad_news_reply and then the tier is 3
function TestSmugglerT2BadNews:test_the_last_reward_reply_sets_pilot_tier_3_through_bad_news_reply()
	local player = finisher(4)

	M.talk(player, { "s_eca7c053" })
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the last reward")
	paidOnce(player, 4, "mission 4")
end

-- AC-10: after pilot tier 3 the graduate still hears the bad news
function TestSmugglerT2BadNews:test_a_tier_3_graduate_still_opens_bad_news()
	local player = M.pilot({ all4 = true })

	M.drive(player, "bad_news")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
	lu.assertEquals(M.firstScreen(player), "bad_news", "the next talk")
end

-- AC-10: bad_news pays nothing and starts nothing
function TestSmugglerT2BadNews:test_the_bad_news_walks_pay_nothing_and_start_nothing()
	local player = M.pilot({ all4 = true })

	M.talk(player, ROUTES[4][1])
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#items(player), 0, "items")

	for g, calls in pairs(spies) do
		lu.assertEquals(#calls, 0, g .. ":startQuest calls")
	end
end
