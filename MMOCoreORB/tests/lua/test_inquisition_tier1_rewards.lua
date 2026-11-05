-- Lt. Barn Sinkko: the four mission rewards (credits, item by species, Imperial standing) are paid once, on display of a pay screen.
-- Spec: .claude/work/inquisition-tier1-barn-sinkko/01-spec.md (AC-8, AC-5; invariant I-9; Conversation flow 2 (C-3 .. C-8) and 3 (table H); D-7).
--
-- The amounts are J's (naboo_imperial_trainer_1.java:423-476); the items by species are the spec's. Credits are the bank credits of the
-- fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier1_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, credits = 100, standing = 25, screens = { "mission1_pay_wing", "mission1_pay_money", "mission1_pay_sure" } },
	{ n = 2, credits = 200, standing = 50, screens = { "mission2_pay_honored", "mission2_pay_philosophy", "mission2_pay_combat" } },
	{ n = 3, credits = 500, standing = 50, screens = { "mission3_pay", "mission3_pay_bandolier", "mission3_credited", "mission3_credited_bandolier", "mission3_army", "mission3_army_bandolier" } },
	{ n = 4, credits = 1000, standing = 75, screens = { "mission4_pay_head", "mission4_pay", "mission4_pay_bold", "mission4_sneer_head", "mission4_sneer" } },
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
			return I.WOOKIEE_BANDOLIER
		elseif species == SPECIES_ITHORIAN then
			return I.ITHORIAN_BANDOLIER
		end

		return I.TIE_SUIT
	elseif n == 4 then
		return I.TIE_HELMET
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

	return I.pilot(o)
end

TestInquisitionT1Rewards = {}

TestInquisitionT1Rewards.setUp = setUp

-- AC-8, I-9: any pay screen of the group pays credits, the item and standing, once
for _, g in ipairs(GROUPS) do
	for _, screen in ipairs(g.screens) do
		for _, sp in ipairs(SPECIES) do
			-- AC-8
			TestInquisitionT1Rewards["test_" .. screen .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
				local player = pilot(g.n, sp.id)
				local item = itemFor(g.n, sp.id)

				I.drive(player, screen)
				lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits")
				lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
				lu.assertEquals(items(player), item and { item } or {}, screen .. " (" .. sp.name .. "): giveItem templates")
				lu.assertEquals(standing(player), g.standing, screen .. ": Imperial standing")
				lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_" .. g.n .. ":reward"), "1", screen .. ": the :reward key")
			end
		end

		-- AC-8, I-9: the same screen shown again
		TestInquisitionT1Rewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			for _ = 1, 3 do
				I.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits after three visits")
			lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, screen .. ": items after three visits")
			lu.assertEquals(standing(player), g.standing, screen .. ": standing after three visits")
		end

		-- AC-8: a mission that was paid before pays nothing
		TestInquisitionT1Rewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			H.setQuestStatus(player, "naboo_imperial_" .. g.n .. ":reward", 1)
			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#items(player), 0, screen .. ": items")
			lu.assertEquals(standing(player), 0, screen .. ": standing")
		end
	end

	-- AC-8, I-9: a second screen of the group (one screen of each route)
	TestInquisitionT1Rewards["test_the_pay_screens_of_mission_" .. g.n .. "_share_one_payment"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _, screen in ipairs(g.screens) do
			I.drive(player, screen)
		end

		lu.assertEquals(player.bankCredits, g.credits, "bank credits after every pay screen of the group")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, "items")
		lu.assertEquals(standing(player), g.standing, "standing")
	end

	-- AC-8: the first screen of a won mission does not pay
	TestInquisitionT1Rewards["test_the_mission_" .. g.n .. "_won_screen_does_not_pay_before_a_pay_screen"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)
		local t = I.talk(player)

		lu.assertEquals(t[1].id, "mission" .. g.n .. "_won", "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#items(player), 0, "items")
		lu.assertEquals(standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, "naboo_imperial_" .. g.n .. ":reward"), "no :reward key yet")
	end
end

-- AC-8: payment is always the chain head's: nothing is paid for the surprise attack or the escort
function TestInquisitionT1Rewards:test_the_split_children_are_never_paid_separately()
	for n, extra in pairs({ [1] = I.S1, [3] = I.E3 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(player.bankCredits, GROUPS[n].credits, "mission " .. n .. " (" .. extra .. " child): credits paid once, not twice")
		lu.assertEquals(#player.bankCreditLog, 1, "mission " .. n .. ": one credit grant")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestInquisitionT1Rewards:test_a_full_inventory_still_receives_the_mission_4_helmet_and_the_mission_3_suit()
	for _, n in ipairs({ 3, 4 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")
	end
end

-- AC-8: M1 gives no item, M2 none
function TestInquisitionT1Rewards:test_missions_1_and_2_give_no_item()
	for n = 1, 2 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "mission " .. n .. ": giveItem calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: routing through the conditional links C-3 .. C-8 (species and head shape) and the pay walks
---------------------------------------------------------------------------------------------

TestInquisitionT1RewardRoutes = {}

TestInquisitionT1RewardRoutes.setUp = setUp

local WEIRD = { SPECIES_WOOKIEE, SPECIES_ITHORIAN }
local NORMAL = { SPECIES_HUMAN, SPECIES_ZABRAK }

local speciesName = {}

for _, s in ipairs(SPECIES) do
	speciesName[s.id] = s.name
end

local function routes()
	local out = {}

	local function add(name, n, species, choices, ids)
		out[#out + 1] = { name = name:gsub("_%d+$", "_" .. speciesName[species]), n = n, species = species, choices = choices, ids = ids }
	end

	for _, sp in ipairs(NORMAL) do
		-- mission 4, "masterful" path (C-6), normal head
		add("m4_masterful_" .. sp, 4, sp, { "s_e12b6418", "s_d09c1ecb", "s_987445c9" }, { "mission4_won", "mission4_masterful", "mission4_pay", "mission4_earned" })
		-- mission 4, "asset" path (C-7)
		add("m4_asset_" .. sp, 4, sp, { "s_4d7a1ae4", "s_c01da9e4", "s_6f5e007c" }, { "mission4_won", "mission4_asset", "mission4_sneer", "mission4_wear_it" })
		-- mission 4, "impressive" path (C-8)
		add("m4_impressive_" .. sp, 4, sp, { "s_2a1af001", "s_ce681825", "s_cd024d84" }, { "mission4_won", "mission4_impressive", "mission4_pay_bold", "mission4_suits" })
		-- mission 3 (C-3, C-4, C-5)
		add("m3_solved_" .. sp, 3, sp, { "s_fe5a7681", "s_30e39201", "s_729d0338" }, { "mission3_won", "mission3_solved", "mission3_pay", "mission3_next_phase" })
		add("m3_decisive_" .. sp, 3, sp, { "s_c0265f54", "s_3e7988c1", "s_30e39201", "s_cb0c70a2", "s_6456f762", "s_9c80b7c7" },
			{ "mission3_won", "mission3_decisive", "mission3_pleased", "mission3_payment_wait", "mission3_credited", "mission3_difficult", "mission3_report" })
		add("m3_stupid_" .. sp, 3, sp, { "s_43d18dec", "s_61eba7c4", "s_f02428e4", "s_89bc583c" }, { "mission3_won", "mission3_stupid", "mission3_intellect", "mission3_army", "mission3_next_phase" })
	end

	for _, sp in ipairs(WEIRD) do
		add("m4_masterful_" .. sp, 4, sp, { "s_e12b6418", "s_d09c1ecb", "s_c6aae4cb", "s_987445c9" }, { "mission4_won", "mission4_masterful", "mission4_pay_head", "mission4_cranial", "mission4_earned" })
		add("m4_asset_" .. sp, 4, sp, { "s_4d7a1ae4", "s_c01da9e4", "s_6f5e007c" }, { "mission4_won", "mission4_asset", "mission4_sneer_head", "mission4_cant_wear" })
		add("m4_impressive_" .. sp, 4, sp, { "s_2a1af001", "s_ce681825", "s_c6aae4cb", "s_987445c9" }, { "mission4_won", "mission4_impressive", "mission4_pay_head", "mission4_cranial", "mission4_earned" })
		add("m3_solved_" .. sp, 3, sp, { "s_fe5a7681", "s_30e39201", "s_729d0338" }, { "mission3_won", "mission3_solved", "mission3_pay_bandolier", "mission3_next_phase" })
		add("m3_decisive_" .. sp, 3, sp, { "s_c0265f54", "s_3e7988c1", "s_30e39201", "s_cb0c70a2", "s_6456f762", "s_9c80b7c7" },
			{ "mission3_won", "mission3_decisive", "mission3_pleased", "mission3_payment_wait", "mission3_credited_bandolier", "mission3_difficult", "mission3_report" })
		add("m3_stupid_" .. sp, 3, sp, { "s_43d18dec", "s_61eba7c4", "s_f02428e4", "s_89bc583c" }, { "mission3_won", "mission3_stupid", "mission3_intellect", "mission3_army_bandolier", "mission3_next_phase" })
	end

	-- mission 2, species independent
	add("m2_honored", 2, SPECIES_HUMAN, { "s_f9081167", "s_987445c9" }, { "mission2_won", "mission2_pay_honored", "mission2_frontline" })
	add("m2_mercenary", 2, SPECIES_HUMAN, { "s_5c314851", "s_fe48d61f", "s_5e2a2bb1", "s_f79f892a" }, { "mission2_won", "mission2_mercenary", "mission2_pay_philosophy", "mission2_drink", "mission2_hmph" })
	add("m2_combat", 2, SPECIES_HUMAN, { "s_e80d813e", "s_987445c9" }, { "mission2_won", "mission2_pay_combat", "mission2_predisposed" })
	-- mission 1
	add("m1_attacked", 1, SPECIES_HUMAN, { "s_3a1ddc14", "s_add5962c", "s_987445c9" }, { "mission1_won", "mission1_attacked", "mission1_pay_wing", "mission1_rebel_problem" })
	add("m1_stirring", 1, SPECIES_HUMAN, { "s_da5219a7", "s_f5559c6a", "s_8bc18758", "s_fc27931b", "s_efa5623a" },
		{ "mission1_won", "mission1_stirring", "mission1_disturbing", "mission1_pay_money", "mission1_thank_you_sir", "mission1_look_into" })
	add("m1_easy_prey", 1, SPECIES_HUMAN, { "s_a6069c84", "s_8c85a270", "s_a5bc9cf4", "s_987445c9" }, { "mission1_won", "mission1_easy_prey", "mission1_adjutant", "mission1_pay_sure", "mission1_look_into" })

	return out
end

for _, r in ipairs(routes()) do
	-- AC-8, AC-5
	TestInquisitionT1RewardRoutes["test_route_" .. r.name .. "_pays_once_by_species"] = function()
		local player = pilot(r.n, r.species)
		local t = I.talk(player, r.choices)
		local g = GROUPS[r.n]
		local item = itemFor(r.n, r.species)

		lu.assertEquals(I.ids(t), r.ids, "screens shown")
		lu.assertEquals(player.bankCredits, g.credits, "bank credits")
		lu.assertEquals(items(player), item and { item } or {}, "giveItem templates")
		lu.assertEquals(standing(player), g.standing, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
		lu.assertTrue(t[#t].stop, "the route ends the conversation")
	end
end

-- AC-8: other heads follow the species rule (neither human nor zabrak is "weird")
function TestInquisitionT1RewardRoutes:test_other_species_take_the_weird_head_routes()
	local rodian = rawget(_G, "SPECIES_RODIAN")

	lu.assertNotNil(rodian, "precondition: SPECIES_RODIAN is a harness constant")

	local t = I.talk(pilot(4, rodian), { "s_e12b6418", "s_d09c1ecb" })

	lu.assertEquals(t[3].id, "mission4_pay_head", "a Rodian is neither SPECIES_HUMAN nor SPECIES_ZABRAK")

	t = I.talk(pilot(3, rodian), { "s_fe5a7681", "s_30e39201" })
	lu.assertEquals(t[3].id, "mission3_pay", "a Rodian wears the flight suit: only Wookiees and Ithorians take the bandolier")
end

-- AC-8: a pilot with all four skills and mission 4 won but unpaid opens mission4_won and is paid
function TestInquisitionT1RewardRoutes:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_won_and_is_paid()
	local player = I.pilot({ paid = 3, state = "won", tier = 4 })
	local t = I.talk(player, { "s_e12b6418", "s_d09c1ecb", "s_987445c9" })

	lu.assertEquals(t[1].id, "mission4_won", "first screen")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { I.TIE_HELMET }, "the helmet")
	lu.assertEquals(standing(player), 75, "standing")

	local again = I.firstScreen(player)

	lu.assertEquals(again, "tier_done", "paid: the next visit opens tier_done (G12)")
	lu.assertEquals(player.bankCredits, 1000, "no second payment")
end

-- AC-8: after payment the offer for the next mission opens
function TestInquisitionT1RewardRoutes:test_after_each_payment_the_next_visit_offers_the_next_mission()
	local want = { "mission2_offer", "mission3_offer", "mission4_offer" }

	for n = 1, 3 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(I.firstScreen(player), want[n], "first screen after mission " .. n .. " was paid")
	end

	local player = pilot(4, SPECIES_HUMAN)

	I.drive(player, "mission4_pay")
	lu.assertEquals(I.firstScreen(player), "training_offer", "first screen after mission 4 was paid (no skill yet)")
end
