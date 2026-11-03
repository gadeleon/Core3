-- Dravis: the four mission rewards (credits, item by species, no faction standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-8, AC-5; invariant I-9, D-4; Conversation flow 2 (C-3) and 3 (table H)).
--
-- The amounts and items are J's (tatooine_privateer_trainer_1.java:188-247, pinned against the fixture in test_smuggler_tier1_data.lua). Credits
-- are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's faction standing.

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

S.load()

local function setUp()
	H.reset()
	S.requireConversation(lu)
end

local function spyAllStarts()
	for _, g in ipairs(S.GLOBALS) do
		H.spyOn(S.quest(g), "startQuest")
	end
end

local GROUPS = {
	{ n = 1, credits = 100, screen = "mission1_reward", replies = { "s_676c343f", "s_ff2a95e8" }, next = "mission2_offer" },
	{ n = 2, credits = 200, screen = "mission2_reward", replies = { "s_b9b27823", "s_d0cc72e0" }, next = "mission3_offer" },
	{ n = 3, credits = 500, screen = "mission3_reward", replies = { "s_98d00f66", "s_60225cc9" }, next = "mission4_offer" },
	{ n = 4, credits = 1000, screen = "mission4_reward", replies = { "s_fc27931b", "s_481c3940" }, next = "first_training" },
}

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

-- the item each group gives to each species (nil = none): M3 the mercenary bandolier, the Ithorian one for an Ithorian; M4 the blaster for all
local function itemFor(n, species)
	if n == 3 then
		return species == SPECIES_ITHORIAN and S.ITHORIAN_BANDOLIER or S.HUMAN_BANDOLIER
	elseif n == 4 then
		return S.BLASTER
	end

	return nil
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

local function standing(player) return { player.ghost.factionStanding.rebel, player.ghost.factionStanding.imperial } end

-- The group's pilot: missions before n paid, mission n won and unpaid
local function pilot(n, species, extra)
	local o = { paid = n - 1, state = "won", species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return S.pilot(o)
end

TestSmugglerT1Rewards = {}

TestSmugglerT1Rewards.setUp = setUp

-- AC-8, I-9: the reward screen pays credits, the item and no standing, once
for _, g in ipairs(GROUPS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8
		TestSmugglerT1Rewards["test_" .. g.screen .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
			local player = pilot(g.n, sp.id)
			local item = itemFor(g.n, sp.id)

			S.drive(player, g.screen)
			lu.assertEquals(player.bankCredits, g.credits, g.screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, g.screen .. ": addBankCredits calls")
			lu.assertEquals(items(player), item and { item } or {}, g.screen .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), { 0, 0 }, g.screen .. ": faction standing (J gives none)")
			lu.assertEquals(H.getQuestStatus(player, S.STATUS_NAMES[g.n] .. ":reward"), "1", g.screen .. ": the :reward key")
		end
	end

	-- AC-8, I-9: shown again
	TestSmugglerT1Rewards["test_" .. g.screen .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _ = 1, 3 do
			S.drive(player, g.screen)
		end

		lu.assertEquals(player.bankCredits, g.credits, g.screen .. ": bank credits after three visits")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, g.screen .. ": items after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestSmugglerT1Rewards["test_" .. g.screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		H.setQuestStatus(player, S.STATUS_NAMES[g.n] .. ":reward", 1)
		S.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, 0, g.screen .. ": bank credits")
		lu.assertEquals(#items(player), 0, g.screen .. ": items")
	end

	-- AC-8: the first screen of a won mission is the reward screen and pays on that display
	TestSmugglerT1Rewards["test_a_pilot_with_mission_" .. g.n .. "_won_is_paid_by_the_first_screen_alone"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)
		local t = S.talk(player)

		lu.assertEquals(S.ids(t), { g.screen }, "first screen")
		lu.assertEquals(player.bankCredits, g.credits, "bank credits")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8 (I-9): the amounts of one mission are not paid by another mission's screen
function TestSmugglerT1Rewards:test_a_reward_screen_pays_only_its_own_mission()
	local player = pilot(2, SPECIES_HUMAN)

	S.drive(player, "mission1_reward")
	lu.assertEquals(player.bankCredits, 0, "mission 1 is already paid: its screen pays nothing")
	S.drive(player, "mission2_reward")
	lu.assertEquals(player.bankCredits, 200, "mission 2's screen pays 200")
	lu.assertNil(H.getQuestStatus(player, S.STATUS_NAMES[3] .. ":reward"), "mission 3's key is untouched")
end

-- AC-8: the items use the overload, so a full inventory still receives them (9034fa3254)
function TestSmugglerT1Rewards:test_a_full_inventory_still_receives_the_mission_3_bandolier_and_the_mission_4_blaster()
	for n = 3, 4 do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		S.drive(player, GROUPS[n].screen)
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")
	end
end

-- AC-8: M1 gives no item, M2 none
function TestSmugglerT1Rewards:test_missions_1_and_2_give_no_item()
	for n = 1, 2 do
		local player = pilot(n, SPECIES_HUMAN)

		S.drive(player, GROUPS[n].screen)
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "mission " .. n .. ": giveItem calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: the reply links (C-3)
---------------------------------------------------------------------------------------------

TestSmugglerT1RewardLinks = {}

TestSmugglerT1RewardLinks.setUp = setUp

-- AC-8, C-3: each reply of the screen links to the screen the gates choose after payment
for _, g in ipairs(GROUPS) do
	TestSmugglerT1RewardLinks["test_every_reply_of_" .. g.screen .. "_leads_to_" .. g.next] = function()
		local player = pilot(g.n, SPECIES_HUMAN)
		local t = S.drive(player, g.screen)

		lu.assertEquals(S.optionSids(t[1]), g.replies, g.screen .. ": replies")
		lu.assertEquals(S.linksOf(t[1]), { g.next, g.next }, g.screen .. ": links evaluated after the payment")

		for _, reply in ipairs(g.replies) do
			H.reset()

			local p = pilot(g.n, SPECIES_HUMAN)
			local walkT = S.talk(p, { reply })

			lu.assertEquals(S.ids(walkT), { g.screen, g.next }, "reply " .. reply)
			lu.assertEquals(p.bankCredits, g.credits, "reply " .. reply .. ": paid once, not again by the next screen")
			lu.assertEquals(CS.transcriptUnresolved(walkT), {}, "reply " .. reply .. ": client strings")
		end
	end
end

-- AC-8, C-3: the replies lead where the gates lead, for a pilot in another state than the usual one
function TestSmugglerT1RewardLinks:test_the_links_follow_the_gates_after_payment_not_a_fixed_target()
	local p = pilot(1, SPECIES_HUMAN)

	-- mission 2 was already attempted and failed before mission 1's reward was collected: the gates then say mission2_retry
	H.setQuestStatus(p, S.STATUS_NAMES[2] .. ":attempted", "1")
	spyAllStarts()
	lu.assertEquals(S.linksOf(S.drive(p, "mission1_reward")[1]), { "mission2_retry", "mission2_retry" }, "links when the gates would say mission2_retry")
end

-- AC-8 (J:10778): on mission4_reward "When will you teach me to fly?" is offered only to a pilot with no tier 1 skill
function TestSmugglerT1RewardLinks:test_the_teach_me_to_fly_reply_is_offered_only_when_the_pilot_has_no_tier_1_skill()
	local none = S.drive(pilot(4, SPECIES_HUMAN), "mission4_reward")

	lu.assertEquals(S.optionSids(none[1]), { "s_fc27931b", "s_481c3940" }, "no tier 1 skill: both replies")

	H.reset()

	local skilled = S.drive(pilot(4, SPECIES_HUMAN, { tier = 1 }), "mission4_reward")

	lu.assertEquals(S.optionSids(skilled[1]), { "s_fc27931b" }, "one tier 1 skill: only Thanks.")
	lu.assertEquals(S.linksOf(skilled[1]), { "duty_missions" }, "with one skill and no XP the gates say duty_missions")

	H.reset()

	local xp = S.drive(pilot(4, SPECIES_HUMAN, { tier = 1, xp = 7500 }), "mission4_reward")

	lu.assertEquals(S.linksOf(xp[1]), { "more_training" }, "with one skill and the XP the gates say more_training")

	H.reset()

	local all = S.drive(pilot(4, SPECIES_HUMAN, { tier = 4 }), "mission4_reward")

	lu.assertEquals(S.linksOf(all[1]), { "tier_done" }, "with all four skills the gates say tier_done")
end

-- AC-8: a pilot with all four skills and mission 4 won but unpaid opens mission4_reward and is paid
function TestSmugglerT1RewardLinks:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_reward_and_is_paid()
	local player = pilot(4, SPECIES_HUMAN, { tier = 4 })
	local t = S.talk(player, { "s_fc27931b" })

	lu.assertEquals(S.ids(t), { "mission4_reward", "tier_done" }, "screens shown")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { S.BLASTER }, "the blaster")
	lu.assertEquals(S.firstScreen(player), "tier_done", "paid: the next visit opens tier_done (G21)")
	lu.assertEquals(player.bankCredits, 1000, "no second payment")
end

-- AC-8: after each payment the next visit offers the next mission
function TestSmugglerT1RewardLinks:test_after_each_payment_the_next_visit_offers_the_next_mission()
	for n = 1, 4 do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		S.drive(player, GROUPS[n].screen)
		lu.assertEquals(S.firstScreen(player), GROUPS[n].next, "first screen after mission " .. n .. " was paid")
	end
end
