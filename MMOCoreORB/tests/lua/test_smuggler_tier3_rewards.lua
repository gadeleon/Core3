-- Beissa: the four mission rewards (25000 credits and a ship component each, no faction standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-8, AC-5; invariants I-5, I-9; Content contract 3; Conversation flow 1 (B10 .. B13) and 3 (table H)).
--
-- The amounts and items are BJ's (fixtures/script/conversation/tatooine_privateer_tier3.java:216-243, parsed by smuggler_tier3_data.lua B.rewards). Credits
-- are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's faction standing.

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local CS = require("harness.client_strings")

B.load()

local function setUp()
	H.reset()
	B.requireConversation(lu)
end

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

local function itemOf(n)
	local id = B.IDENTITY[B.HEADS[n]]

	return B.rewards()[id.type .. "/" .. id.name].item
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

local function standing(player) return { player.ghost.factionStanding.imperial or 0, player.ghost.factionStanding.rebel or 0 } end

-- The mission's pilot: mission n won and unpaid, n - 1 skills chosen
local function pilot(n, species, extra)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid, mission = { [n] = "won" }, species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return B.pilot(o)
end

TestSmugglerT3Rewards = {}

TestSmugglerT3Rewards.setUp = setUp

for n, m in ipairs(B.MISSIONS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8, I-5: the reward screen pays credits and the item (any species) and no standing
		TestSmugglerT3Rewards["test_" .. m.reward .. "_pays_mission_" .. n .. "_to_a_" .. sp.name] = function()
			local player = pilot(n, sp.id)
			local before = standing(player)

			B.drive(player, m.reward)
			lu.assertEquals(player.bankCredits, B.CREDITS, m.reward .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
			lu.assertEquals(items(player), { itemOf(n) }, m.reward .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), before, m.reward .. ": faction standing is not touched")
			lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", m.reward .. ": the :reward key")
		end
	end

	-- AC-8, I-5, I-9: the same screen shown again
	TestSmugglerT3Rewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(n, SPECIES_HUMAN)

		for _ = 1, 3 do
			B.drive(player, m.reward)
		end

		lu.assertEquals(player.bankCredits, B.CREDITS, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#items(player), 1, m.reward .. ": items after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestSmugglerT3Rewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(n, SPECIES_HUMAN)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		B.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#items(player), 0, m.reward .. ": items")
	end

	-- AC-8: the first screen of the talk is the reward screen; it pays on display, and a second visit before choosing shows it again for nothing
	TestSmugglerT3Rewards["test_" .. m.reward .. "_opens_first_pays_once_and_opens_again_for_nothing"] = function()
		local player = pilot(n, SPECIES_HUMAN)
		local first = B.talk(player)

		lu.assertEquals(B.ids(first), { m.reward }, "first screen")
		lu.assertEquals(player.bankCredits, B.CREDITS, "the reward screen pays on display")
		lu.assertEquals(items(player), { itemOf(n) }, "the item")

		local again = B.talk(player)

		lu.assertEquals(B.ids(again), { m.reward }, "the next visit, before a skill is chosen, shows the reward screen again")
		lu.assertEquals(player.bankCredits, B.CREDITS, "bank credits after the second visit")
		lu.assertEquals(#items(player), 1, "items after the second visit")
		lu.assertEquals(CS.transcriptUnresolved(first), {}, "client strings (AC-5)")
	end

	-- AC-8, D-13: the :reward key belongs to this mission only
	TestSmugglerT3Rewards["test_paying_mission_" .. n .. "_sets_only_its_own_reward_key"] = function()
		local player = pilot(n, SPECIES_HUMAN)
		local before = {}

		for k = 1, 4 do
			before[k] = H.getQuestStatus(player, B.MISSIONS[k].status .. ":reward")
		end

		B.drive(player, m.reward)

		for k = 1, 4 do
			if k ~= n then
				lu.assertEquals(H.getQuestStatus(player, B.MISSIONS[k].status .. ":reward"), before[k], "the :reward key of mission " .. k .. " is unchanged")
			end
		end
	end
end

-- AC-8, I-5: the four reward screens share nothing
function TestSmugglerT3Rewards:test_the_four_rewards_add_up_and_each_pays_once()
	local player = B.pilot({ mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

	for _ = 1, 2 do
		for _, m in ipairs(B.MISSIONS) do
			B.drive(player, m.reward)
		end
	end

	lu.assertEquals(player.bankCredits, 4 * B.CREDITS, "bank credits")
	lu.assertEquals(items(player), { itemOf(1), itemOf(2), itemOf(3), itemOf(4) }, "items in mission order")
end

-- AC-8: the reward is paid through the mission head's reward call (credits and item come from the head table)
function TestSmugglerT3Rewards:test_each_reward_is_the_head_tables_reward_player()
	for n, m in ipairs(B.MISSIONS) do
		H.reset()

		local spy = H.spyOn(B.quest(m.head), "rewardPlayer")

		B.drive(pilot(n, SPECIES_HUMAN), m.reward)
		lu.assertEquals(#spy, 1, m.head .. ": rewardPlayer calls")
	end
end

-- AC-8: a full inventory still receives the items (the overload flag)
function TestSmugglerT3Rewards:test_a_full_inventory_still_receives_every_reward_item()
	for n, m in ipairs(B.MISSIONS) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		B.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, m.reward .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, m.reward .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, m.reward .. ": giveItem calls")
		lu.assertIs(calls[1][4], true, m.reward .. ": the overload flag")
	end
end

-- AC-8: the reward screen offers the topics (checked in full by the training tests) and the pay screen ends nothing
function TestSmugglerT3Rewards:test_a_reward_screen_lists_one_topic_per_missing_skill_and_does_not_end()
	for n, m in ipairs(B.MISSIONS) do
		H.reset()

		local t = B.drive(pilot(n, SPECIES_HUMAN), m.reward)

		lu.assertEquals(#t[1].options, 4 - (n - 1), m.reward .. ": topics (the missing skills)")
		lu.assertFalse(t[1].stop and true or false, m.reward .. " does not end the conversation")
	end
end

-- AC-8, I-5: the offers, accepts, failure and hand-off screens pay nothing through a conversation
function TestSmugglerT3Rewards:test_no_other_screen_pays()
	for _, id in ipairs({ "m1_offer", "m1_accept", "m2_accept", "m3_accept", "m4_accept", "m1_failed", "m1_retry_shut_up", "m4_retry_do_it", "busy", "tier_done",
		"done_wont_miss", "done_strange", "m1_trained", "m4_trained" }) do
		H.reset()
		B.spyStarts()

		local player = B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })

		B.drive(player, id)
		lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
		lu.assertEquals(#items(player), 0, id .. ": items")
	end
end
