-- Inquisitor Fa'Zoll: the four mission rewards (5000 credits, a ship component, +75 Imperial standing) are paid once, on display of a pay screen.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-9, AC-11, AC-5; invariant I-9; Conversation flow 3 (table H) and 4; D-10, D-19).
--
-- The amounts are J2's (naboo_imperial_trainer_2.java:199-274, checked against the fixture in test_inquisition_tier2_data.lua). Credits are the bank
-- credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, global = I.M1, screens = { "m1_pay" }, won = "m1_won", walkEnd = "m1_bite_to_eat" },
	{ n = 2, global = I.M2, screens = { "m2_pay" }, won = "m2_won", walkEnd = "m2_duty_briefing" },
	{ n = 3, global = I.M3, screens = { "m3_pay" }, won = "m3_won", walkEnd = "m3_pay" },
	{ n = 4, global = I.M4, screens = { "m4_pay" }, won = "m4_won", walkEnd = "m4_farewell" },
}

local function standing(player) return player.ghost.factionStanding.imperial end

-- The group's pilot: missions before n paid, mission n won and unpaid, the skills the story needs at that point
local function pilot(n, extra)
	local o = { paid = n - 1, state = "won" }

	if n == 3 then
		o.t2 = { 1 }
	elseif n == 4 then
		o.t2 = { 1, 2, 3, 4 }
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

-- The reply sids from the won screen to the last screen of the pay walk
local function payWalk(g)
	local queue, seen = { { id = g.won, replies = {}, ids = { g.won } } }, { [g.won] = true }

	while #queue > 0 do
		local cur = table.remove(queue, 1)

		if cur.id == g.walkEnd then
			return cur.replies, cur.ids
		end

		for _, o in ipairs(I.screenRow(cur.id).options) do
			if not seen[o[2]] then
				seen[o[2]] = true

				local replies, ids = { table.unpack(cur.replies) }, { table.unpack(cur.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]
				queue[#queue + 1] = { id = o[2], replies = replies, ids = ids }
			end
		end
	end

	error("no walk to " .. g.walkEnd)
end

TestInquisitionT2Rewards = {}

TestInquisitionT2Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	for _, screen in ipairs(g.screens) do
		-- AC-9, I-9: the pay screen pays credits, the item and standing, once
		TestInquisitionT2Rewards["test_" .. screen .. "_pays_mission_" .. g.n] = function()
			local player = pilot(g.n)

			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, I.CREDITS, screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
			lu.assertEquals(I.items(player), { I.ITEMS[g.global] }, screen .. ": giveItem templates")
			lu.assertEquals(standing(player), I.STANDING, screen .. ": Imperial standing")
			lu.assertEquals(H.getQuestStatus(player, I.STATUS[g.n] .. ":reward"), "1", screen .. ": the :reward key")
		end

		-- AC-9, I-9: the same screen shown again
		TestInquisitionT2Rewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(g.n)

			for _ = 1, 3 do
				I.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, I.CREDITS, screen .. ": bank credits after three visits")
			lu.assertEquals(#I.items(player), 1, screen .. ": items after three visits")
			lu.assertEquals(standing(player), I.STANDING, screen .. ": standing after three visits")
		end

		-- AC-9: a mission that was paid before pays nothing
		TestInquisitionT2Rewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(g.n)

			H.setQuestStatus(player, I.STATUS[g.n] .. ":reward", 1)
			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#I.items(player), 0, screen .. ": items")
			lu.assertEquals(standing(player), 0, screen .. ": standing")
		end
	end

	-- AC-9: the first screen of a won mission does not pay
	TestInquisitionT2Rewards["test_the_mission_" .. g.n .. "_won_screen_does_not_pay_before_the_pay_screen"] = function()
		local player = pilot(g.n)
		local t = I.talk(player)

		lu.assertEquals(t[1].id, g.won, "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#I.items(player), 0, "items")
		lu.assertEquals(standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, I.STATUS[g.n] .. ":reward"), "no :reward key yet")
	end

	-- AC-9: the walk from the won screen reaches the pay screen and pays once
	TestInquisitionT2Rewards["test_the_mission_" .. g.n .. "_won_walk_pays_once_and_ends_where_the_story_goes_on"] = function()
		local replies, ids = payWalk(g)
		local player = pilot(g.n)
		local t = I.talk(player, replies)

		lu.assertEquals(I.ids(t), ids, "screens shown")
		lu.assertEquals(player.bankCredits, I.CREDITS, "bank credits")
		lu.assertEquals(I.items(player), { I.ITEMS[g.global] }, "giveItem templates")
		lu.assertEquals(standing(player), I.STANDING, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end

	-- AC-9: the reward item is paid to any species (any-species entry)
	TestInquisitionT2Rewards["test_mission_" .. g.n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = pilot(g.n, { species = SPECIES_WOOKIEE })

		I.drive(player, g.screens[1])
		lu.assertEquals(I.items(player), { I.ITEMS[g.global] }, "giveItem templates for a Wookiee")
	end

	-- AC-9: the reward item uses the overload, so a full inventory still receives it (9034fa3254)
	TestInquisitionT2Rewards["test_mission_" .. g.n .. "_item_reaches_a_full_inventory"] = function()
		local player = pilot(g.n, { inventory = { limit = 0 } })

		I.drive(player, g.screens[1])
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end
end

-- AC-9: M2's walk continues to the duty menu and M3's pay screen offers it
function TestInquisitionT2Rewards:test_mission_2_walk_ends_at_the_duty_briefing_whose_replies_lead_to_the_duties()
	local _, ids = payWalk(GROUPS[2])
	local t = I.talk(pilot(2), (payWalk(GROUPS[2])))

	lu.assertEquals(ids[#ids], "m2_duty_briefing", "the walk's last screen")
	lu.assertEquals(I.ids(t), { "m2_won", "m2_promotion", "m2_pay", "m2_local_command", "m2_emperor_commands", "m2_discretion", "m2_duty_briefing" }, "screens shown")
	lu.assertEquals(I.linksOf(t[#t]), { "duty_brief_police", "duty_menu" }, "m2_duty_briefing links")
	lu.assertEquals(t[2].params.TU, "Ace", "m2_promotion: %NU")
end

-- AC-9
function TestInquisitionT2Rewards:test_mission_3_pay_screen_offers_the_duty_briefing_and_the_duty_menu()
	local t = I.talk(pilot(3), { "s_96db4fc7", "s_369ec9fc" })

	lu.assertEquals(I.ids(t), { "m3_won", "m3_traitor", "m3_pay" }, "screens shown")
	lu.assertEquals(I.optionSids(t[3]), { "s_b2a924ab", "s_ac71da57" }, "m3_pay replies")
	lu.assertEquals(I.linksOf(t[3]), { "duty_brief_police", "duty_menu" }, "m3_pay links")
end

-- AC-9: the payment is the head's, nothing else pays
function TestInquisitionT2Rewards:test_a_pay_screen_pays_only_its_own_missions_reward()
	local player = pilot(2)

	I.drive(player, "m2_pay")
	lu.assertEquals(I.items(player), { I.ITEMS[I.M2] }, "mission 2 item")
	lu.assertEquals(H.getQuestStatus(player, I.STATUS[1] .. ":reward"), "1", "mission 1 stays paid")
	lu.assertNil(H.getQuestStatus(player, I.STATUS[3] .. ":reward"), "mission 3 stays unpaid")
	lu.assertNil(H.getQuestStatus(player, I.STATUS[4] .. ":reward"), "mission 4 stays unpaid")
end

-- AC-9: after each payment the next visit offers what comes next
function TestInquisitionT2Rewards:test_after_each_payment_the_next_visit_opens_the_next_screen()
	local want = { "m2_offer", "duty_after_m2", "duty_after_m3" }

	for n = 1, 3 do
		H.reset()

		local player = pilot(n)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(I.firstScreen(player), want[n], "first screen after mission " .. n .. " was paid")
	end

	local player = pilot(4)

	I.drive(player, "m4_pay")
	lu.assertEquals(I.firstScreen(player), "report_to_vrke", "first screen after mission 4 was paid with all four skills")
end

-- AC-9: mission 3 paid with all four skills opens the mission 4 offer
function TestInquisitionT2Rewards:test_after_mission_3_with_all_four_skills_the_next_visit_opens_m4_offer()
	local player = pilot(3, { t2 = { 1, 2, 3, 4 } })

	I.drive(player, "m3_pay")
	lu.assertEquals(I.firstScreen(player), "m4_offer", "first screen")
end

-- AC-11: mission 4 won with all four skills: m4_won -> pay -> farewell, paid once
function TestInquisitionT2Rewards:test_mission_4_won_with_all_four_skills_walks_to_the_farewell_and_pays_once()
	local player = pilot(4)
	local t = I.talk(player, { "s_97d51490", "s_1bac802d" })

	lu.assertEquals(I.ids(t), { "m4_won", "m4_pay", "m4_farewell" }, "screens shown")
	lu.assertTrue(t[3].stop, "m4_farewell ends the conversation")
	lu.assertEquals(I.optionSids(t[1]), { "s_97d51490" }, "m4_won reply with all four skills")
	lu.assertEquals(player.bankCredits, I.CREDITS, "bank credits")
	lu.assertEquals(I.items(player), { I.ITEMS[I.M4] }, "the dual projector")
	lu.assertEquals(standing(player), I.STANDING, "standing")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11, D-19: without all four skills the reply is the training one and nothing is paid
function TestInquisitionT2Rewards:test_mission_4_won_without_all_four_skills_leads_to_more_training_and_pays_nothing()
	local player = pilot(4, { t2 = { 1, 2, 3 }, xp = I.TRAINING_COST })
	local t = I.talk(player, { "s_c104d444" })

	lu.assertEquals(I.ids(t), { "m4_won", "m4_more_training" }, "screens shown")
	lu.assertEquals(I.optionSids(t[1]), { "s_c104d444" }, "m4_won reply: 'I think I need more training though.'")
	lu.assertEquals(I.linksOf(t[1]), { "m4_more_training" }, "m4_won link")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#I.items(player), 0, "items")
	lu.assertEquals(standing(player), 0, "standing")
	lu.assertNil(H.getQuestStatus(player, I.STATUS[4] .. ":reward"), "no :reward key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-11: a pilot with no tier 2 skill at all is offered the same reply
function TestInquisitionT2Rewards:test_mission_4_won_with_no_tier_2_skill_offers_only_the_training_reply()
	local t = I.talk(pilot(4, { t2 = {} }))

	lu.assertEquals(I.optionSids(t[1]), { "s_c104d444" }, "m4_won replies")
end
