-- Lt. Akal Colzet: the four mission rewards (credits, item by species, Imperial standing) are paid once, on display of a pay screen.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-8, AC-5; invariant I-9; Conversation flow 2 (C-3 .. C-8) and 3 (table H); D-7).
--
-- The amounts are J's (tatooine_imperial_trainer_1.java:345-467); the items by species are the spec's. Credits are the bank credits of the
-- fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local I = require("storm_tier1_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, credits = 100, standing = 25, screens = { "mission1_pay_hazard", "mission1_pay_yawn", "mission1_pay_ego" } },
	{ n = 2, credits = 200, standing = 50, screens = { "mission2_pay_dutiful", "mission2_pay_calm", "mission2_pay_patronizing" } },
	{ n = 3, credits = 500, standing = 50, screens = { "mission3_pay_bandolier", "mission3_pay", "mission3_pay_embarrassment", "mission3_pay_wear", "mission3_pay_too_large", "mission3_pay_surprising" } },
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

TestStormT1Rewards = {}

TestStormT1Rewards.setUp = setUp

-- AC-8, I-9: any pay screen of the group pays credits, the item and standing, once
for _, g in ipairs(GROUPS) do
	for _, screen in ipairs(g.screens) do
		for _, sp in ipairs(SPECIES) do
			-- AC-8
			TestStormT1Rewards["test_" .. screen .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
				local player = pilot(g.n, sp.id)
				local item = itemFor(g.n, sp.id)

				I.drive(player, screen)
				lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits")
				lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
				lu.assertEquals(items(player), item and { item } or {}, screen .. " (" .. sp.name .. "): giveItem templates")
				lu.assertEquals(standing(player), g.standing, screen .. ": Imperial standing")
				lu.assertEquals(H.getQuestStatus(player, "tatooine_imperial_" .. g.n .. ":reward"), "1", screen .. ": the :reward key")
			end
		end

		-- AC-8, I-9: the same screen shown again
		TestStormT1Rewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			for _ = 1, 3 do
				I.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits after three visits")
			lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, screen .. ": items after three visits")
			lu.assertEquals(standing(player), g.standing, screen .. ": standing after three visits")
		end

		-- AC-8: a mission that was paid before pays nothing
		TestStormT1Rewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(g.n, SPECIES_HUMAN)

			H.setQuestStatus(player, "tatooine_imperial_" .. g.n .. ":reward", 1)
			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#items(player), 0, screen .. ": items")
			lu.assertEquals(standing(player), 0, screen .. ": standing")
		end
	end

	-- AC-8, I-9: a second screen of the group (one screen of each route)
	TestStormT1Rewards["test_the_pay_screens_of_mission_" .. g.n .. "_share_one_payment"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _, screen in ipairs(g.screens) do
			I.drive(player, screen)
		end

		lu.assertEquals(player.bankCredits, g.credits, "bank credits after every pay screen of the group")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, "items")
		lu.assertEquals(standing(player), g.standing, "standing")
	end

	-- AC-8: the first screen of a won mission does not pay
	TestStormT1Rewards["test_the_mission_" .. g.n .. "_won_screen_does_not_pay_before_a_pay_screen"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)
		local t = I.talk(player)

		lu.assertEquals(t[1].id, "mission" .. g.n .. "_won", "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#items(player), 0, "items")
		lu.assertEquals(standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, "tatooine_imperial_" .. g.n .. ":reward"), "no :reward key yet")
	end
end

-- AC-8: payment is always the chain head's: nothing is paid for the surprise attack or the escort
function TestStormT1Rewards:test_the_split_children_are_never_paid_separately()
	for n, extra in pairs({ [1] = I.S1, [3] = I.E3 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(player.bankCredits, GROUPS[n].credits, "mission " .. n .. " (" .. extra .. " child): credits paid once, not twice")
		lu.assertEquals(#player.bankCreditLog, 1, "mission " .. n .. ": one credit grant")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestStormT1Rewards:test_a_full_inventory_still_receives_the_mission_4_helmet_and_the_mission_3_suit()
	for _, n in ipairs({ 3, 4 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")
	end
end

-- AC-8: M1 gives no item, M2 none
function TestStormT1Rewards:test_missions_1_and_2_give_no_item()
	for n = 1, 2 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "mission " .. n .. ": giveItem calls")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: routing through the conditional links C-3 .. C-8 (species and head shape) and the pay walks
---------------------------------------------------------------------------------------------

TestStormT1RewardRoutes = {}

TestStormT1RewardRoutes.setUp = setUp

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
		add("m4_asset_" .. sp, 4, sp, { "s_4d7a1ae4", "s_c01da9e4", "s_87e1d305" }, { "mission4_won", "mission4_asset", "mission4_sneer", "mission4_wear_it" })
		-- mission 4, "impressive" path (C-8)
		add("m4_impressive_" .. sp, 4, sp, { "s_2a1af001", "s_ce681825", "s_cd024d84" }, { "mission4_won", "mission4_impressive", "mission4_pay_bold", "mission4_suits" })
		-- mission 3 (C-3, C-4, C-5)
		add("m3_proud_" .. sp, 3, sp, { "s_52b712dc", "s_d09c1ecb", "s_69d5148f" }, { "mission3_won", "mission3_proud", "mission3_pay", "mission3_officer" })
		add("m3_uncharacteristic_" .. sp, 3, sp, { "s_85414d61", "s_61f0326", "s_713afe89", "s_a0129ea3" }, { "mission3_won", "mission3_uncharacteristic", "mission3_owe", "mission3_pay_wear", "mission3_obstinate" })
		add("m3_glorious_" .. sp, 3, sp, { "s_39aba3b6", "s_2bca7dec", "s_c0ce49d6" }, { "mission3_won", "mission3_glorious", "mission3_pay_surprising", "mission3_next_mission" })
	end

	for _, sp in ipairs(WEIRD) do
		add("m4_masterful_" .. sp, 4, sp, { "s_e12b6418", "s_d09c1ecb", "s_c6aae4cb", "s_987445c9" }, { "mission4_won", "mission4_masterful", "mission4_pay_head", "mission4_cranial", "mission4_earned" })
		add("m4_asset_" .. sp, 4, sp, { "s_4d7a1ae4", "s_c01da9e4", "s_87e1d305" }, { "mission4_won", "mission4_asset", "mission4_sneer_head", "mission4_cant_wear" })
		add("m4_impressive_" .. sp, 4, sp, { "s_2a1af001", "s_ce681825", "s_c6aae4cb", "s_987445c9" }, { "mission4_won", "mission4_impressive", "mission4_pay_head", "mission4_cranial", "mission4_earned" })
		add("m3_proud_" .. sp, 3, sp, { "s_52b712dc", "s_d09c1ecb", "s_69d5148f" }, { "mission3_won", "mission3_proud", "mission3_pay_bandolier", "mission3_officer" })
		add("m3_uncharacteristic_" .. sp, 3, sp, { "s_85414d61", "s_61f0326", "s_713afe89", "s_a0129ea3" }, { "mission3_won", "mission3_uncharacteristic", "mission3_owe", "mission3_pay_embarrassment", "mission3_obstinate" })
		add("m3_glorious_" .. sp, 3, sp, { "s_39aba3b6", "s_2bca7dec", "s_c0ce49d6" }, { "mission3_won", "mission3_glorious", "mission3_pay_too_large", "mission3_next_mission" })
	end

	-- mission 2, species independent
	add("m2_dutiful", 2, SPECIES_HUMAN, { "s_96c14c06", "s_987445c9" }, { "mission2_won", "mission2_pay_dutiful", "mission2_success" })
	add("m2_calm", 2, SPECIES_HUMAN, { "s_5f418636", "s_a607dd0f" }, { "mission2_won", "mission2_pay_calm", "mission2_wear_told" })
	add("m2_patronizing", 2, SPECIES_HUMAN, { "s_838b6daf", "s_d07b11b5" }, { "mission2_won", "mission2_pay_patronizing", "mission2_ahem" })
	-- mission 1
	add("m1_pirates", 1, SPECIES_HUMAN, { "s_ee91723f", "s_b3753189", "s_987445c9" }, { "mission1_won", "mission1_pirates", "mission1_pay_hazard", "mission1_another_duty" })
	add("m1_brag", 1, SPECIES_HUMAN, { "s_263baa57", "s_7baeb853", "s_23600775" }, { "mission1_won", "mission1_brag", "mission1_bounty_hunter", "mission1_pay_yawn" })
	add("m1_purged", 1, SPECIES_HUMAN, { "s_d92fcf8d", "s_7ef9666e", "s_39f8ff3b" }, { "mission1_won", "mission1_purged", "mission1_pay_ego", "mission1_good_day" })

	return out
end

for _, r in ipairs(routes()) do
	-- AC-8, AC-5
	TestStormT1RewardRoutes["test_route_" .. r.name .. "_pays_once_by_species"] = function()
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
function TestStormT1RewardRoutes:test_other_species_take_the_weird_head_routes()
	local rodian = rawget(_G, "SPECIES_RODIAN")

	lu.assertNotNil(rodian, "precondition: SPECIES_RODIAN is a harness constant")

	local t = I.talk(pilot(4, rodian), { "s_e12b6418", "s_d09c1ecb" })

	lu.assertEquals(t[3].id, "mission4_pay_head", "a Rodian is neither SPECIES_HUMAN nor SPECIES_ZABRAK")

	t = I.talk(pilot(3, rodian), { "s_52b712dc", "s_d09c1ecb" })
	lu.assertEquals(t[3].id, "mission3_pay", "a Rodian wears the flight suit: only Wookiees and Ithorians take the bandolier")
end

-- AC-8: a pilot with all four skills and mission 4 won but unpaid opens mission4_won and is paid
function TestStormT1RewardRoutes:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_won_and_is_paid()
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
function TestStormT1RewardRoutes:test_after_each_payment_the_next_visit_offers_the_next_mission()
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
