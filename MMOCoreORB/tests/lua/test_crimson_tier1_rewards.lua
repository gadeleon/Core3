-- Da'la Socuna: the four mission rewards (credits, item by species, Rebel standing) are paid once, on every leaf of the report (SWG pays on the report replies, FI-1).
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-8, AC-5; invariant I-9; Conversation flow 2 (C-3) and 3 (table H); D-9, D-10, FI-1, FI-7).
--
-- The amounts are J's (tatooine_rebel_trainer_1.java:283-330: 100/200/500/1000 credits, standing +25/+50/+50/+75); the items by species are the spec's
-- (the one named exception: the flight suit is bodysuit_s14, D-9). Credits are the bank credits of the fake pilot, items the giveItem calls on its
-- inventory, standing the ghost's Rebel standing. The pay screens are the leaves of table H; m4r_thrilling pays nothing (as SWG).

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local CS = require("harness.client_strings")

I.load()

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local GROUPS = {
	{ n = 1, credits = 100, standing = 25, report = "mission1_report", screens = { "m1r_probably", "m1r_lucky", "m1r_consider", "m1r_we_wait", "m1r_digest", "m1r_bad_news" } },
	{ n = 2, credits = 200, standing = 50, report = "mission2_report", screens = { "m2r_best", "m2r_outstanding", "m2r_anticipated" } },
	{ n = 3, credits = 500, standing = 50, report = "mission3_report", screens = { "m3r_lucky", "m3r_outstanding", "m3r_beautifully" } },
	{ n = 4, credits = 1000, standing = 75, report = "mission4_report", screens = { "m4r_dismissed", "m4r_great_work", "m4r_honor" } },
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

local function spyAll()
	for _, g in ipairs(I.GLOBALS) do
		H.spyOn(I.quest(g), "startQuest")
	end
end

TestCrimsonT1Rewards = {}

TestCrimsonT1Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	for _, screen in ipairs(g.screens) do
		-- AC-8, I-9: any pay screen pays credits, the item and standing, once
		TestCrimsonT1Rewards["test_" .. screen .. "_pays_mission_" .. g.n] = function()
			local player = pilot(g.n, SPECIES_HUMAN)
			local item = itemFor(g.n, SPECIES_HUMAN)

			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, g.credits, screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
			lu.assertEquals(items(player), item and { item } or {}, screen .. ": giveItem templates")
			lu.assertEquals(standing(player), g.standing, screen .. ": Rebel standing")
			lu.assertEquals(H.getQuestStatus(player, I.statusName(g.n) .. ":reward"), "1", screen .. ": the :reward key")
		end
	end

	-- AC-8: the species decide the item of mission 3 (every pay screen of the group, one species each)
	for _, sp in ipairs(SPECIES) do
		TestCrimsonT1Rewards["test_mission_" .. g.n .. "_pays_a_" .. sp.name .. "_the_item_of_its_species"] = function()
			lu.assertNotNil(sp.id, "precondition: the species constant for " .. sp.name)

			local player = pilot(g.n, sp.id)
			local item = itemFor(g.n, sp.id)

			I.drive(player, g.screens[1])
			lu.assertEquals(player.bankCredits, g.credits, "bank credits")
			lu.assertEquals(items(player), item and { item } or {}, g.screens[1] .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), g.standing, "Rebel standing")
		end
	end

	-- AC-8, I-9: showing every pay screen of the mission in turn pays once
	TestCrimsonT1Rewards["test_all_pay_screens_of_mission_" .. g.n .. "_shown_in_turn_pay_once"] = function()
		local player = pilot(g.n, SPECIES_HUMAN)

		for _ = 1, 2 do
			for _, screen in ipairs(g.screens) do
				I.drive(player, screen)
			end
		end

		lu.assertEquals(player.bankCredits, g.credits, "bank credits after every pay screen twice")
		lu.assertEquals(#player.bankCreditLog, 1, "one credit grant")
		lu.assertEquals(#items(player), itemFor(g.n, SPECIES_HUMAN) and 1 or 0, "items")
		lu.assertEquals(standing(player), g.standing, "standing")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestCrimsonT1Rewards["test_the_pay_screens_of_mission_" .. g.n .. "_pay_nothing_when_the_reward_key_is_set"] = function()
		for _, screen in ipairs(g.screens) do
			H.reset()

			local player = pilot(g.n, SPECIES_HUMAN)

			H.setQuestStatus(player, I.statusName(g.n) .. ":reward", 1)
			I.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#items(player), 0, screen .. ": items")
			lu.assertEquals(standing(player), 0, screen .. ": standing")
		end
	end

	-- AC-8: the first talk after the win is the report; the rest of it is walked through the routes of Appendix A
	TestCrimsonT1Rewards["test_the_first_talk_after_winning_mission_" .. g.n .. "_opens_the_report_and_every_route_pays_once"] = function()
		local first = I.talk(pilot(g.n, SPECIES_HUMAN))

		lu.assertEquals(first[1].id, g.report, "first screen")
		lu.assertEquals(CS.transcriptUnresolved(first), {}, "client strings")

		-- every leaf of the report: follow each route to an ending and check the pay
		local function walk(prefix, id)
			local row = I.screenRow(id)

			if row.stop then
				local player = pilot(g.n, SPECIES_HUMAN)
				local t = I.talk(player, prefix)
				local pays = id ~= "m4r_thrilling"

				lu.assertEquals(t[#t].id, id, "route " .. table.concat(prefix, ",") .. ": last screen")
				lu.assertEquals(player.bankCredits, pays and g.credits or 0, "route to " .. id .. ": bank credits")
				lu.assertEquals(standing(player), pays and g.standing or 0, "route to " .. id .. ": standing")

				return
			end

			for _, o in ipairs(row.options) do
				if o[2] ~= id then
					local nextPrefix = { table.unpack(prefix) }

					nextPrefix[#nextPrefix + 1] = o[1]
					walk(nextPrefix, o[2])
				end
			end
		end

		walk({}, g.report)
	end
end

-- AC-8, I-9: the same screen shown again
function TestCrimsonT1Rewards:test_a_pay_screen_shown_three_times_pays_once()
	local player = pilot(1, SPECIES_HUMAN)

	for _ = 1, 3 do
		I.drive(player, "m1r_lucky")
	end

	lu.assertEquals(player.bankCredits, 100, "bank credits after three visits")
	lu.assertEquals(standing(player), 25, "standing after three visits")
end

-- AC-8: m4r_thrilling pays nothing (as SWG), so the next talk opens mission4_report again, and a later pay screen still pays
function TestCrimsonT1Rewards:test_m4r_thrilling_pays_nothing_and_the_next_talk_opens_mission4_report_again()
	local player = pilot(4, SPECIES_HUMAN)
	local t = I.talk(player, { "s_a8b44679", "s_3f30cd7b" })

	lu.assertEquals(I.ids(t), { "mission4_report", "m4r_didnt_catch", "m4r_thrilling" }, "screens shown")
	lu.assertTrue(t[3].stop, "m4r_thrilling ends the conversation")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#items(player), 0, "items")
	lu.assertEquals(standing(player), 0, "standing")
	lu.assertNil(H.getQuestStatus(player, "tatooine_rebel_4:reward"), "no :reward key")
	lu.assertEquals(I.firstScreen(player), "mission4_report", "the next talk: the report again")

	local t2 = I.talk(player, { "s_ce2c09ec" })

	lu.assertEquals(I.ids(t2), { "mission4_report", "m4r_great_work" }, "the second talk's route")
	lu.assertEquals(player.bankCredits, 1000, "paid on the second talk")
end

-- AC-8, I-5: only the 17 pay screens pay; the report gates, the answers in front of them and everything else pay nothing
function TestCrimsonT1Rewards:test_no_other_screen_pays()
	local paying = {}

	for _, g in ipairs(GROUPS) do
		for _, screen in ipairs(g.screens) do
			paying[screen] = true
		end
	end

	for _, row in ipairs(I.SCREENS) do
		if not paying[row.id] then
			H.reset()
			spyAll()

			local player = pilot(1, SPECIES_HUMAN, { xp = 99999 })

			I.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, "screen '" .. row.id .. "': bank credits")
			lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "screen '" .. row.id .. "': items")
			lu.assertEquals(standing(player), 0, "screen '" .. row.id .. "': standing")
		end
	end
end

-- AC-8: payment is always the chain head's: nothing is paid for the surprise attack or the escort
function TestCrimsonT1Rewards:test_the_split_children_are_never_paid_separately()
	for n, child in pairs({ [1] = I.S1, [3] = I.E3 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(player.bankCredits, GROUPS[n].credits, "mission " .. n .. " (" .. child .. " child): credits paid once, not twice")
		lu.assertEquals(#player.bankCreditLog, 1, "mission " .. n .. ": one credit grant")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestCrimsonT1Rewards:test_a_full_inventory_still_receives_the_mission_3_suit_and_the_mission_4_armor()
	for _, n in ipairs({ 3, 4 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")
	end
end

-- D-9 (named exception): the default mission 3 item is the substitute for SWG's rebel_bodysuit_s14
function TestCrimsonT1Rewards:test_the_default_mission_3_item_is_bodysuit_s14_not_swgs_rebel_bodysuit()
	local player = pilot(3, SPECIES_HUMAN)

	I.drive(player, "m3r_lucky")
	lu.assertEquals(items(player), { "object/tangible/wearables/bodysuit/bodysuit_s14.iff" }, "D-9: SWG's object/tangible/wearables/bodysuit/rebel_bodysuit_s14.iff is in no pre-NGE archive and has no Core3 template")
end

-- AC-8: after each payment the next mission's offer opens
function TestCrimsonT1Rewards:test_after_each_payment_the_next_visit_offers_the_next_mission()
	local want = { "mission2_offer", "mission3_offer", "mission4_offer" }

	for n = 1, 3 do
		local player = pilot(n, SPECIES_HUMAN)

		I.drive(player, GROUPS[n].screens[1])
		lu.assertEquals(I.firstScreen(player), want[n], "first screen after mission " .. n .. " was paid")
	end

	local player = pilot(4, SPECIES_HUMAN)

	I.drive(player, "m4r_dismissed")
	lu.assertEquals(I.firstScreen(player), "training_first", "first screen after mission 4 was paid (no skill yet)")
end

-- AC-8, FI-7: a pilot with all four skills and mission 4 won but unpaid opens mission4_report and is paid on a pay screen
function TestCrimsonT1Rewards:test_a_pilot_with_all_four_skills_and_an_unpaid_mission_4_opens_mission4_report()
	local player = I.pilot({ paid = 3, state = "won", tier = 4 })
	local t = I.talk(player, { "s_ce2c09ec" })

	lu.assertEquals(I.ids(t), { "mission4_report", "m4r_great_work" }, "screens shown")
	lu.assertEquals(player.bankCredits, 1000, "bank credits")
	lu.assertEquals(items(player), { I.ARMOR }, "the armor")
	lu.assertEquals(standing(player), 75, "standing")
	lu.assertEquals(I.firstScreen(player), "tier_done", "paid: the next visit opens tier_done (G12)")
	lu.assertEquals(player.bankCredits, 1000, "no second payment")
end

---------------------------------------------------------------------------------------------
-- AC-8: the helper and routing through the conditional link C-3
---------------------------------------------------------------------------------------------

TestCrimsonT1RewardRoutes = {}

TestCrimsonT1RewardRoutes.setUp = setUp

-- C-3
function TestCrimsonT1RewardRoutes:test_the_species_helper()
	local h = rawget(_G, I.HANDLER)

	lu.assertTrue(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_WOOKIEE })), "Wookiee")
	lu.assertTrue(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_ITHORIAN })), "Ithorian")
	lu.assertFalse(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_HUMAN })), "human")
	lu.assertFalse(h:isWookieeOrIthorian(I.pilot({ species = SPECIES_ZABRAK })), "Zabrak")
end

-- C-3: "What's this?" on the three M3 pay screens names the item by species
for _, screen in ipairs({ "m3r_lucky", "m3r_outstanding", "m3r_beautifully" }) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8
		TestCrimsonT1RewardRoutes["test_" .. screen .. "_leads_a_" .. sp.name .. "_to_the_right_item_line"] = function()
			local player = pilot(3, sp.id)
			local t = I.drive(player, screen, { "s_8be95ab4" })
			local weird = sp.id == SPECIES_WOOKIEE or sp.id == SPECIES_ITHORIAN
			local want = weird and "m3r_bandolier" or "m3r_flightsuit"

			lu.assertEquals(I.ids(t), { screen, want }, "screens shown")
			lu.assertTrue(t[2].stop, want .. " ends the conversation")
			lu.assertEquals(player.bankCredits, 500, "bank credits")
			lu.assertEquals(items(player), { itemFor(3, sp.id) }, "giveItem templates")
			lu.assertEquals(standing(player), 50, "standing")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-8: through the real report the routes of mission 3 pay once and end on an item line
function TestCrimsonT1RewardRoutes:test_the_mission_3_report_routes_reach_the_item_lines()
	local player = pilot(3, SPECIES_WOOKIEE)
	local t = I.talk(player, { "s_766563c7", "s_8be95ab4" })

	lu.assertEquals(I.ids(t), { "mission3_report", "m3r_lucky", "m3r_bandolier" }, "a Wookiee's route")
	lu.assertEquals(player.bankCredits, 500, "bank credits")
	lu.assertEquals(items(player), { I.WOOKIEE_BANDOLIER }, "the bandolier")

	H.reset()

	local human = pilot(3, SPECIES_HUMAN)
	local t2 = I.talk(human, { "s_9109c202", "s_8be95ab4" })

	lu.assertEquals(I.ids(t2), { "mission3_report", "m3r_beautifully", "m3r_flightsuit" }, "a human's route")
	lu.assertEquals(items(human), { I.FLIGHT_SUIT }, "the flight suit")
end
