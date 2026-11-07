-- V3-FX: the four mission rewards (credits, item by species, Rebel standing) are paid once, on display of the won screen.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (AC-8, AC-5; invariant I-9; Conversation flow 2 (C-3) and 3 (table H); D-9, D-10, FI-1, FI-7).
--
-- The amounts are J's (naboo_rebel_trainer_1.java:272-314: 100/200/500/1000 credits, standing +25/+50/+50/+75); the items by species are the spec's
-- (the one named exception: the flight suit is bodysuit_s14, D-9). Credits are the bank credits of the fake pilot, items the giveItem calls on its
-- inventory, standing the ghost's Rebel standing. SWG pays on the gate line: the won screen pays on display (D-10).

local lu = require("luaunit")
local H = require("harness")
local I = require("vortex_tier1_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, credits = 100, standing = 25, screen = "mission1_won" },
	{ n = 2, credits = 200, standing = 50, screen = "mission2_won" },
	{ n = 3, credits = 500, standing = 50, screen = "mission3_won" },
	{ n = 4, credits = 1000, standing = 75, screen = "mission4_won" },
}

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
	{ name = "rodian", id = rawget(_G, "SPECIES_RODIAN") },
}

-- the item each mission gives to each species (nil = none)
local function itemFor(n, species)
	if n == 3 then
		if species == SPECIES_WOOKIEE then
			return I.WOOKIEE_BANDOLIER
		elseif species == SPECIES_ITHORIAN then
			return I.ITHORIAN_BANDOLIER
		end

		return I.FLIGHT_SUIT
	elseif n == 4 then
		return I.ARMOR
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

local function standing(player) return player.ghost.factionStanding.rebel end

-- The group's pilot: missions before n paid, mission n won and unpaid
local function pilot(n, species, extra)
	local o = { paid = n - 1, state = "won", species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return I.pilot(o)
end

TestVortexT1Rewards = {}

TestVortexT1Rewards.setUp = setUp

-- AC-8, I-9: the won screen pays credits, the item and standing, once
for _, g in ipairs(GROUPS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8
		TestVortexT1Rewards["test_" .. g.screen .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
			lu.assertNotNil(sp.id, "precondition: the species constant for " .. sp.name)

			local player = pilot(g.n, sp.id)
			local item = itemFor(g.n, sp.id)

			I.drive(player, g.screen)
			lu.assertEquals(player.bankCredits, g.credits, g.screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, g.screen .. ": addBankCredits calls")
			lu.assertEquals(items(player), item and { item } or {}, g.screen .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), g.standing, g.screen .. ": Rebel standing")
			lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_" .. g.n .. ":reward"), "1", g.screen .. ": the :reward key")
		end
	end

	-- AC-8, I-9: the same screen shown again
	TestVortexT1Rewards["test_" .. g.screen .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _ = 1, 3 do
			I.drive(player, g.screen)
		end

		lu.assertEquals(player.bankCredits, g.credits, g.screen .. ": bank credits after three visits")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, g.screen .. ": items after three visits")
		lu.assertEquals(standing(player), g.standing, g.screen .. ": standing after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestVortexT1Rewards["test_" .. g.screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		H.setQuestStatus(player, "naboo_rebel_" .. g.n .. ":reward", 1)
		I.drive(player, g.screen)
		lu.assertEquals(player.bankCredits, 0, g.screen .. ": bank credits")
		lu.assertEquals(#items(player), 0, g.screen .. ": items")
		lu.assertEquals(standing(player), 0, g.screen .. ": standing")
	end

	-- AC-8: the first talk after the win is the pay screen
	TestVortexT1Rewards["test_the_first_talk_after_winning_mission_" .. g.n .. "_opens_the_won_screen_and_pays"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)
		local t = I.talk(player)

		lu.assertEquals(t[1].id, g.screen, "first screen")
		lu.assertEquals(player.bankCredits, g.credits, "bank credits")
		lu.assertEquals(standing(player), g.standing, "standing")
		lu.assertEquals(H.getQuestStatus(player, "naboo_rebel_" .. g.n .. ":reward"), "1", "the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the other missions' keys and the unpaid later missions stay untouched
	TestVortexT1Rewards["test_" .. g.screen .. "_sets_only_its_own_reward_key"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		I.drive(player, g.screen)

		for k = g.n + 1, 4 do
			lu.assertNil(H.getQuestStatus(player, "naboo_rebel_" .. k .. ":reward"), "mission " .. k .. " :reward")
		end
	end
end

-- AC-8: only the four won screens pay; the answers behind them and the offers pay nothing
function TestVortexT1Rewards:test_no_other_screen_pays()
	local paying = { mission1_won = true, mission2_won = true, mission3_won = true, mission4_won = true }

	for _, row in ipairs(I.SCREENS) do
		if not paying[row.id] then
			H.reset()

			for _, g in ipairs(I.GLOBALS) do
				H.spyOn(I.quest(g), "startQuest")
			end

			local player = pilot(1, SPECIES_HUMAN, { xp = 99999 })

			I.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, "screen '" .. row.id .. "': bank credits")
			lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "screen '" .. row.id .. "': items")
			lu.assertEquals(standing(player), 0, "screen '" .. row.id .. "': standing")
		end
	end
end

-- AC-8: payment is always the chain head's: nothing is paid for the surprise attack or the escort
function TestVortexT1Rewards:test_the_split_children_are_never_paid_separately()
	for n, child in pairs({ [1] = I.S1, [3] = I.E3 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screen)
		lu.assertEquals(player.bankCredits, GROUPS[n].credits, "mission " .. n .. " (" .. child .. " child): credits paid once, not twice")
		lu.assertEquals(#player.bankCreditLog, 1, "mission " .. n .. ": one credit grant")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestVortexT1Rewards:test_a_full_inventory_still_receives_the_mission_3_suit_and_the_mission_4_armor()
	for _, n in ipairs({ 3, 4 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		I.drive(player, GROUPS[n].screen)
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")
	end
end

-- AC-8: M1 gives no item, M2 none
function TestVortexT1Rewards:test_missions_1_and_2_give_no_item()
	for n = 1, 2 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screen)
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "mission " .. n .. ": giveItem calls")
	end
end

-- D-9 (named exception): the default mission 3 item is the substitute for SWG's rebel_bodysuit_s14
function TestVortexT1Rewards:test_the_default_mission_3_item_is_bodysuit_s14_not_swgs_rebel_bodysuit()
	local player = pilot(3, SPECIES_HUMAN)

	I.drive(player, "mission3_won")
	lu.assertEquals(items(player), { "object/tangible/wearables/bodysuit/bodysuit_s14.iff" }, "D-9: SWG's object/tangible/wearables/bodysuit/rebel_bodysuit_s14.iff is in no pre-NGE archive and has no Core3 template")
end

---------------------------------------------------------------------------------------------
-- AC-8: the helpers and routing through the conditional link C-3
---------------------------------------------------------------------------------------------

TestVortexT1RewardRoutes = {}

TestVortexT1RewardRoutes.setUp = setUp

-- C-3
function TestVortexT1RewardRoutes:test_the_species_and_gender_helpers()
	local h = rawget(_G, I.HANDLER)

	lu.assertTrue(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_WOOKIEE })), "Wookiee")
	lu.assertTrue(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_ITHORIAN })), "Ithorian")
	lu.assertFalse(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_HUMAN })), "human")
	lu.assertFalse(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_ZABRAK })), "Zabrak")
	lu.assertTrue(h:isMale(I.pilot({ gender = 0 })), "gender 0")
	lu.assertFalse(h:isMale(I.pilot({ gender = 1 })), "gender 1")
end

-- C-3: the two replies of mission3_won name the item by species
local M3_ROUTES = {
	{ reply = "s_9561a5a9", normal = "m3_flightsuit", weird = "m3_bandolier" },
	{ reply = "s_27a8c796", normal = "m3_thanks_flightsuit", weird = "m3_thanks_bandolier" },
}

for _, r in ipairs(M3_ROUTES) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8
		TestVortexT1RewardRoutes["test_mission3_won_reply_" .. r.reply .. "_leads_a_" .. sp.name .. "_to_the_right_item_line"] = function()
			local player = pilot(3, sp.id)
			local t = I.talk(player, { r.reply })
			local weird = sp.id == SPECIES_WOOKIEE or sp.id == SPECIES_ITHORIAN
			local want = weird and r.weird or r.normal

			lu.assertEquals(I.ids(t), { "mission3_won", want }, "screens shown")
			lu.assertTrue(t[2].stop, want .. " ends the conversation")
			lu.assertEquals(player.bankCredits, 500, "bank credits")
			lu.assertEquals(items(player), { itemFor(3, sp.id) }, "giveItem templates")
			lu.assertEquals(standing(player), 50, "standing")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-8: the won screens of missions 1, 2 and 4 route as Appendix A says and pay once
function TestVortexT1RewardRoutes:test_the_other_won_screens_pay_once_on_every_route()
	local routes = {
		{ n = 1, choices = { "s_1f6a762c" }, ids = { "mission1_won", "m1_superior" } },
		{ n = 1, choices = { "s_85fcdc55", "s_7d4a858e" }, ids = { "mission1_won", "m1_attacked", "m1_exciting" } },
		{ n = 2, choices = { "s_c1013aa7" }, ids = { "mission2_won", "m2_yes_indeed" } },
		{ n = 2, choices = { "s_6b490480" }, ids = { "mission2_won", "m2_affirmative" } },
		{ n = 2, choices = { "s_f0b6493f" }, ids = { "mission2_won", "m2_welcome" } },
	}

	for i, r in ipairs(routes) do
		H.reset()

		local player = pilot(r.n, SPECIES_HUMAN)
		local t = I.talk(player, r.choices)

		lu.assertEquals(I.ids(t), r.ids, "route " .. i .. ": screens shown")
		lu.assertEquals(player.bankCredits, GROUPS[r.n].credits, "route " .. i .. ": bank credits")
		lu.assertEquals(#player.bankCreditLog, 1, "route " .. i .. ": one credit grant")
		lu.assertEquals(standing(player), GROUPS[r.n].standing, "route " .. i .. ": standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "route " .. i .. ": client strings")
	end
end

-- AC-8: mission 4's won screen pays the credits and the armor and ends
function TestVortexT1RewardRoutes:test_mission_4_won_pays_the_credits_and_the_armor_and_ends()
	local player = pilot(4, SPECIES_HUMAN)
	local t = I.talk(player)

	lu.assertEquals(I.ids(t), { "mission4_won" }, "screens shown")
	lu.assertTrue(t[1].stop, "mission4_won ends the conversation")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { I.ARMOR }, "the Incom ultralight armor")
	lu.assertEquals(standing(player), 75, "standing")
end

-- AC-8, FI-7: a pilot with all four skills and mission 4 won but unpaid opens mission4_won and is paid
function TestVortexT1RewardRoutes:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_won_and_is_paid()
	local player = I.pilot({ paid = 3, state = "won", tier = 4 })
	local t = I.talk(player)

	lu.assertEquals(t[1].id, "mission4_won", "first screen")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { I.ARMOR }, "the armor")
	lu.assertEquals(standing(player), 75, "standing")
	lu.assertEquals(I.firstScreen(player), "tier_done", "paid: the next visit opens tier_done (G12)")
	lu.assertEquals(player.bankCredits, 1000, "no second payment")
end

-- AC-8: after each payment the next mission's offer opens
function TestVortexT1RewardRoutes:test_after_each_payment_the_next_visit_offers_the_next_mission()
	local want = { "mission2_offer", "mission3_offer", "mission4_offer" }

	for n = 1, 3 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screen)
		lu.assertEquals(I.firstScreen(player), want[n], "first screen after mission " .. n .. " was paid")
	end

	local player = pilot(4, SPECIES_HUMAN)

	I.drive(player, "mission4_won")
	lu.assertEquals(I.firstScreen(player), "training_first", "first screen after mission 4 was paid (no skill yet)")
end
