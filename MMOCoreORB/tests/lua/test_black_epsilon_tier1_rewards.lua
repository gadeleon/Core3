-- Hakassha Sireen: the four mission rewards (credits, item by species, Imperial standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-8, AC-5; invariant I-9, D-4; Conversation flow 2 (C-4, C-5, C-6) and 3 (table H)).
--
-- The amounts are J's (corellia_imperial_trainer_1.java:394-522); the items by species are the spec's. Credits are the bank credits of the
-- fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

B.load()

local function setUp()
	H.reset()
	B.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, credits = 100, standing = 25, screens = { "mission1_won" } },
	{ n = 2, credits = 200, standing = 50, screens = { "mission2_reward", "mission2_reward_pay" } },
	{ n = 3, credits = 500, standing = 50, screens = { "mission3_reward", "mission3_reward_bandolier" } },
	{ n = 4, credits = 1000, standing = 75, screens = { "mission4_reward_head", "mission4_reward", "mission4_pay_head", "mission4_pay" } },
}

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

-- the item each group gives to each species (nil = none)
local function itemFor(n, species)
	if n == 3 then
		if species == SPECIES_WOOKIEE then
			return B.WOOKIEE_BANDOLIER
		elseif species == SPECIES_ITHORIAN then
			return B.ITHORIAN_BANDOLIER
		end

		return B.TIE_SUIT
	elseif n == 4 then
		return B.TIE_HELMET
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

local function standing(player) return player.ghost.factionStanding.imperial end

-- The group's pilot: missions before n paid, mission n won and unpaid
local function pilot(n, species, extra)
	local o = { paid = n - 1, state = "won", species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return B.pilot(o)
end

TestBlackEpsilonT1Rewards = {}

TestBlackEpsilonT1Rewards.setUp = setUp

-- AC-8, I-9: any reward screen of the group pays credits, the item and standing, once
for _, g in ipairs(GROUPS) do
	for _, screen in ipairs(g.screens) do
		for _, sp in ipairs(SPECIES) do
			-- AC-8
			TestBlackEpsilonT1Rewards["test_" .. screen .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
				local player = pilot(g.n, sp.id)
				local item = itemFor(g.n, sp.id)

				B.drive(player, screen)
				lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits")
				lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
				lu.assertEquals(items(player), item and { item } or {}, screen .. " (" .. sp.name .. "): giveItem templates")
				lu.assertEquals(standing(player), g.standing, screen .. ": Imperial standing")
				lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_" .. g.n .. ":reward"), "1", screen .. ": the :reward key")
			end
		end

		-- AC-8, I-9: the same screen shown again
		TestBlackEpsilonT1Rewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			for _ = 1, 3 do
				B.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits after three visits")
			lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, screen .. ": items after three visits")
			lu.assertEquals(standing(player), g.standing, screen .. ": standing after three visits")
		end

		-- AC-8: a mission that was paid before pays nothing
		TestBlackEpsilonT1Rewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			H.setQuestStatus(player, "corellia_imperial_" .. g.n .. ":reward", 1)
			B.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#items(player), 0, screen .. ": items")
			lu.assertEquals(standing(player), 0, screen .. ": standing")
		end
	end

	-- AC-8, I-9: a second screen of the group
	TestBlackEpsilonT1Rewards["test_the_reward_screens_of_mission_" .. g.n .. "_share_one_payment"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _, screen in ipairs(g.screens) do
			B.drive(player, screen)
		end

		lu.assertEquals(player.bankCredits, g.credits, "bank credits after every reward screen of the group")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, "items")
		lu.assertEquals(standing(player), g.standing, "standing")
	end

	-- AC-8: the first screen of a won mission does not pay
	TestBlackEpsilonT1Rewards["test_the_mission_" .. g.n .. "_offer_of_the_reward_does_not_pay_before_a_reward_screen"] = function()
		if g.n == 1 then
			return -- mission1_won is the reward screen of mission 1
		end

		local player = pilot(g.n, SPECIES_HUMAN)
		local t = B.talk(player)

		lu.assertEquals(t[1].id, "mission" .. g.n .. "_won", "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertNil(H.getQuestStatus(player, "corellia_imperial_" .. g.n .. ":reward"), "no :reward key yet")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestBlackEpsilonT1Rewards:test_a_full_inventory_still_receives_the_mission_4_helmet()
	local player = pilot(4, SPECIES_HUMAN, { inventory = { limit = 0 } })

	B.drive(player, "mission4_reward")
	lu.assertEquals(#player.inventory.items, 1, "the helmet lands in the full inventory")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
end

-- AC-8: M1 gives no item, M2 none
function TestBlackEpsilonT1Rewards:test_missions_1_and_2_give_no_item()
	for n = 1, 2 do
		local player = pilot(n, SPECIES_HUMAN)

		B.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "mission " .. n .. ": giveItem calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: routing through the conditional links C-4, C-5, C-6 (species) and the pay walk
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1RewardRoutes = {}

TestBlackEpsilonT1RewardRoutes.setUp = setUp

-- C-4 .. C-6
local ROUTES = {
	-- mission 4, "For the Emperor." path
	{ name = "m4_close_human", n = 4, species = SPECIES_HUMAN, choices = { "s_b224e12", "s_15799d85", "s_b9b27823" },
		ids = { "mission4_won", "mission4_won_close", "mission4_reward", "mission4_reward_end" } },
	{ name = "m4_close_zabrak", n = 4, species = SPECIES_ZABRAK, choices = { "s_b224e12", "s_15799d85", "s_b9b27823" },
		ids = { "mission4_won", "mission4_won_close", "mission4_reward", "mission4_reward_end" } },
	{ name = "m4_close_wookiee", n = 4, species = SPECIES_WOOKIEE, choices = { "s_b224e12", "s_15799d85", "s_c6aae4cb", "s_b9b27823" },
		ids = { "mission4_won", "mission4_won_close", "mission4_reward_head", "mission4_cranial", "mission4_reward_end" } },
	{ name = "m4_close_ithorian", n = 4, species = SPECIES_ITHORIAN, choices = { "s_b224e12", "s_15799d85", "s_c6aae4cb", "s_b9b27823" },
		ids = { "mission4_won", "mission4_won_close", "mission4_reward_head", "mission4_cranial", "mission4_reward_end" } },
	-- mission 4, "toast" path
	{ name = "m4_toast_human", n = 4, species = SPECIES_HUMAN, choices = { "s_6372912d", "s_659a2365", "s_1cca067", "s_614b71f0" },
		ids = { "mission4_won", "mission4_won_toast", "mission4_pay", "mission4_helmet", "mission4_pay_end" } },
	{ name = "m4_toast_wookiee", n = 4, species = SPECIES_WOOKIEE, choices = { "s_6372912d", "s_659a2365", "s_c6aae4cb", "s_b9b27823" },
		ids = { "mission4_won", "mission4_won_toast", "mission4_pay_head", "mission4_cranial", "mission4_reward_end" } },
	-- mission 3
	{ name = "m3_human", n = 3, species = SPECIES_HUMAN, choices = { "s_dd5ca133", "s_34ac7110", "s_fc27931b" },
		ids = { "mission3_won", "mission3_casualties", "mission3_reward", "mission3_reward_end" } },
	{ name = "m3_zabrak", n = 3, species = SPECIES_ZABRAK, choices = { "s_dd5ca133", "s_34ac7110", "s_fc27931b" },
		ids = { "mission3_won", "mission3_casualties", "mission3_reward", "mission3_reward_end" } },
	{ name = "m3_wookiee", n = 3, species = SPECIES_WOOKIEE, choices = { "s_dd5ca133", "s_34ac7110", "s_fc27931b" },
		ids = { "mission3_won", "mission3_casualties", "mission3_reward_bandolier", "mission3_reward_end" } },
	{ name = "m3_ithorian", n = 3, species = SPECIES_ITHORIAN, choices = { "s_dd5ca133", "s_34ac7110", "s_fc27931b" },
		ids = { "mission3_won", "mission3_casualties", "mission3_reward_bandolier", "mission3_reward_end" } },
	-- mission 2
	{ name = "m2_big_guns", n = 2, species = SPECIES_HUMAN, choices = { "s_fa187bb6", "s_386d47c9", "s_ee39efb1" },
		ids = { "mission2_won", "mission2_big_guns", "mission2_reward_pay", "mission2_reward_pay_end" } },
	{ name = "m2_message", n = 2, species = SPECIES_HUMAN, choices = { "s_36eb0383", "s_67ded17", "s_f6629a2e" },
		ids = { "mission2_won", "mission2_reward", "mission2_superiors", "mission2_reward_end" } },
	-- mission 1
	{ name = "m1_won", n = 1, species = SPECIES_HUMAN, choices = { "s_334f003c" }, ids = { "mission1_won", "mission1_answers" } },
}

for _, r in ipairs(ROUTES) do
	-- AC-8, AC-5
	TestBlackEpsilonT1RewardRoutes["test_route_" .. r.name .. "_pays_once_by_species"] = function()
		local player = pilot(r.n, r.species)
		local t = B.talk(player, r.choices)
		local g = GROUPS[r.n]
		local item = itemFor(r.n, r.species)

		lu.assertEquals(B.ids(t), r.ids, "screens shown")
		lu.assertEquals(player.bankCredits, g.credits, "bank credits")
		lu.assertEquals(items(player), item and { item } or {}, "giveItem templates")
		lu.assertEquals(standing(player), g.standing, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end
end

-- AC-8: a pilot with all four skills and mission 4 won but unpaid opens mission4_won and is paid
function TestBlackEpsilonT1RewardRoutes:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_won_and_is_paid()
	local player = B.pilot({ paid = 3, state = "won", tier = 4 })
	local t = B.talk(player, { "s_b224e12", "s_15799d85", "s_b9b27823" })

	lu.assertEquals(t[1].id, "mission4_won", "first screen")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { B.TIE_HELMET }, "the helmet")
	lu.assertEquals(standing(player), 75, "standing")

	local again = B.firstScreen(player)

	lu.assertEquals(again, "tier_done", "paid: the next visit opens tier_done (G11)")
	lu.assertEquals(player.bankCredits, 1000, "no second payment")
end

-- AC-8: after payment the offer for the next mission opens
function TestBlackEpsilonT1RewardRoutes:test_after_each_payment_the_next_visit_offers_the_next_mission()
	local want = { "mission2_offer", "mission3_offer", "mission4_offer" }

	for n = 1, 3 do
		local player = pilot(n, SPECIES_HUMAN)

		B.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(B.firstScreen(player), want[n], "first screen after mission " .. n .. " was paid")
	end

	local player = pilot(4, SPECIES_HUMAN)

	B.drive(player, "mission4_reward")
	lu.assertEquals(B.firstScreen(player), "training_offer", "first screen after mission 4 was paid (no skill yet)")
end
