-- Prisk Kith'Vys: the four mission rewards (5000 credits, a ship component, +75 Imperial standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-8, AC-5; invariants I-5, I-9; Content contract 3; Conversation flow 1 (P18 .. P21) and 3 (table H)).
--
-- The amounts are J's (corellia_imperial_trainer_2.java:284-292, 353-379). Credits are the bank credits of the fake pilot, items the giveItem
-- calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local CS = require("harness.client_strings")

P.load()

local function setUp()
	H.reset()
	P.requireConversation(lu)
end

-- n = the mission number; skill = the TRAIN index that leads to it
local GROUPS = {
	{ n = 1, skill = 1, won = "m12_won", reward = "m12_reward", reply = "s_59894e66", stem = "corellia_imperial_12" },
	{ n = 2, skill = 4, won = "m13_won", reward = "m13_reward", reply = "s_d4374209", stem = "corellia_imperial_13" },
	{ n = 3, skill = 2, won = "m14_won", reward = "m14_reward", reply = "s_16439d46", stem = "corellia_imperial_14" },
	{ n = 4, skill = 3, won = "m15_won", reward = "m15_reward", reply = "s_8e613fca", stem = "corellia_imperial_15" },
}

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

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

-- The group's pilot: mission n won and unpaid, its skill held
local function pilot(g, species, extra)
	local o = { opening = "won", t2 = { g.skill }, mission = { [g.n] = "won" }, species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return P.pilot(o)
end

TestBlackEpsilonT2Rewards = {}

TestBlackEpsilonT2Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8, I-5: the reward screen pays credits, the item (any species) and standing
		TestBlackEpsilonT2Rewards["test_" .. g.reward .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
			local player = pilot(g, sp.id)

			P.drive(player, g.reward)
			lu.assertEquals(player.bankCredits, P.CREDITS, g.reward .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, g.reward .. ": addBankCredits calls")
			lu.assertEquals(items(player), { P.ITEMS[g.n] }, g.reward .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), P.STANDING, g.reward .. ": Imperial standing")
			lu.assertEquals(H.getQuestStatus(player, g.stem .. ":reward"), "1", g.reward .. ": the :reward key")
		end
	end

	-- AC-8, I-9: the same screen shown again
	TestBlackEpsilonT2Rewards["test_" .. g.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		for _ = 1, 3 do
			P.drive(player, g.reward)
		end

		lu.assertEquals(player.bankCredits, P.CREDITS, g.reward .. ": bank credits after three visits")
		lu.assertEquals(#items(player), 1, g.reward .. ": items after three visits")
		lu.assertEquals(standing(player), P.STANDING, g.reward .. ": standing after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestBlackEpsilonT2Rewards["test_" .. g.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		H.setQuestStatus(player, g.stem .. ":reward", 1)
		P.drive(player, g.reward)
		lu.assertEquals(player.bankCredits, 0, g.reward .. ": bank credits")
		lu.assertEquals(#items(player), 0, g.reward .. ": items")
		lu.assertEquals(standing(player), 0, g.reward .. ": standing")
	end

	-- AC-8: the won screen alone does not pay; the reply shows the reward screen, which pays
	TestBlackEpsilonT2Rewards["test_" .. g.won .. "_opens_first_and_its_reply_shows_" .. g.reward .. "_which_pays_once"] = function()
		local player = pilot(g, SPECIES_HUMAN)
		local first = P.talk(player)

		lu.assertEquals(P.ids(first), { g.won }, "first screen")
		lu.assertEquals(P.optionSids(first[1]), { g.reply }, g.won .. ": the one reply")
		lu.assertEquals(player.bankCredits, 0, "the won screen pays nothing")
		lu.assertNil(H.getQuestStatus(player, g.stem .. ":reward"), "no :reward key yet")

		local t = P.talk(player, { g.reply })

		lu.assertEquals(P.ids(t), { g.won, g.reward }, "screens shown")
		lu.assertTrue(t[2].stop, g.reward .. " ends the conversation")
		lu.assertEquals(player.bankCredits, P.CREDITS, "bank credits")
		lu.assertEquals(items(player), { P.ITEMS[g.n] }, "the item")
		lu.assertEquals(standing(player), P.STANDING, "standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings (AC-5)")

		-- the next visit shows no won screen and pays nothing
		local again = P.firstScreen(player)

		lu.assertNotEquals(again, g.won, "the next visit")
		lu.assertEquals(player.bankCredits, P.CREDITS, "bank credits after the second visit")
		lu.assertEquals(#items(player), 1, "items after the second visit")
		lu.assertEquals(standing(player), P.STANDING, "standing after the second visit")
	end

	-- AC-8, D-11: the :reward key belongs to this mission only
	TestBlackEpsilonT2Rewards["test_paying_mission_" .. g.n .. "_sets_only_its_own_reward_key"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		P.drive(player, g.reward)

		for _, other in ipairs(GROUPS) do
			if other.n ~= g.n then
				lu.assertNil(H.getQuestStatus(player, other.stem .. ":reward"), "the :reward key of mission " .. other.n)
			end
		end
	end
end

-- AC-8, I-9: the four reward screens share nothing
function TestBlackEpsilonT2Rewards:test_the_four_rewards_add_up_and_each_pays_once()
	local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

	for _ = 1, 2 do
		for _, g in ipairs(GROUPS) do
			P.drive(player, g.reward)
		end
	end

	lu.assertEquals(player.bankCredits, 4 * P.CREDITS, "bank credits")
	lu.assertEquals(items(player), { P.ITEMS[1], P.ITEMS[2], P.ITEMS[3], P.ITEMS[4] }, "items in mission order")
	lu.assertEquals(standing(player), 4 * P.STANDING, "standing")
end

-- AC-8: mission 4 counts as won only when the patrol and its surprise attack are both complete
function TestBlackEpsilonT2Rewards:test_mission_15_with_only_the_patrol_complete_pays_nothing_and_is_not_won()
	local player = P.pilot({ opening = "won", t2 = { 3 }, mission = { [4] = "won4patrol" } })
	local t = P.talk(player)

	lu.assertEquals(t[1].id, "m15_retry", "first screen: the patrol alone is not a win")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#items(player), 0, "items")
end

-- AC-8: the won screen for mission 4 once both are complete
function TestBlackEpsilonT2Rewards:test_mission_15_with_patrol_and_split_complete_opens_m15_won()
	local player = P.pilot({ opening = "won", t2 = { 3 }, mission = { [4] = "won" } })

	lu.assertEquals(P.firstScreen(player), "m15_won", "first screen")
end

-- AC-8, I-9: the reward is keyed to the mission's own name (M15 is corellia_imperial_15, not the split)
function TestBlackEpsilonT2Rewards:test_the_mission_15_reward_key_is_the_patrols_name_not_the_splits()
	local player = pilot(GROUPS[4], SPECIES_HUMAN)

	P.drive(player, "m15_reward")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_15:reward"), "1", "corellia_imperial_15:reward")
	lu.assertNil(H.getQuestStatus(player, "corellia_imperial_15_split:reward"), "corellia_imperial_15_split:reward")
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestBlackEpsilonT2Rewards:test_a_full_inventory_still_receives_every_reward_item()
	for _, g in ipairs(GROUPS) do
		H.reset()

		local player = pilot(g, SPECIES_HUMAN, { inventory = { limit = 0 } })

		P.drive(player, g.reward)
		lu.assertEquals(#player.inventory.items, 1, g.reward .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, g.reward .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, g.reward .. ": giveItem calls")
		lu.assertIs(calls[1][4], true, g.reward .. ": the overload flag")
	end
end

-- AC-8, I-5: the opening and the duties pay nothing through a conversation
function TestBlackEpsilonT2Rewards:test_the_opening_the_final_and_the_duty_screens_pay_nothing()
	for _, id in ipairs({ "opening_accept", "opening_retry", "final_accept", "final_retry", "tour_complete", "duty_pirates", "duty_merchant", "duty_rebels", "duty_security" }) do
		H.reset()

		P.spyStarts()

		local player = P.pilot({ opening = "won", t2 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })

		P.drive(player, id)
		lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
		lu.assertEquals(#items(player), 0, id .. ": items")
		lu.assertEquals(standing(player), 0, id .. ": standing")
	end
end
