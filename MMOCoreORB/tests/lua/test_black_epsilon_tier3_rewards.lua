-- Haymir Rendundi: the four mission rewards (25000 credits, a ship component, +100 Imperial standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-8, AC-5; invariants I-5, I-9; Content contract 3; Conversation flow 1 (P12 .. P15) and 3 (table H)).
--
-- The amounts are J's (corellia_imperial_tier3.java:220-251). Credits are the bank credits of the fake pilot, items the giveItem calls on its
-- inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

-- the first reply of each reward screen (Appendix A) and the walk to the training screen
local GROUPS = {
	{ n = 1, reward = "m1_reward", reply = "s_b200234c", stem = "corellia_imperial_tier3_1", walk = { "s_b200234c", "s_2c7b60e", "s_72418db3", "s_8c751827", "s_8efde2ae" },
		ids = { "m1_reward", "m1_debrief", "m1_need_to_know", "m1_storm", "m1_why_not_assault", "m1_training" } },
	{ n = 2, reward = "m2_reward", reply = "s_a6944d2", stem = "corellia_imperial_tier3_2", walk = { "s_a6944d2", "s_b779a3", "s_107391a2" },
		ids = { "m2_reward", "m2_thanks", "m2_beautiful", "m2_training" } },
	{ n = 3, reward = "m3_reward", reply = "s_657cb9bd", stem = "corellia_imperial_tier3_3", walk = { "s_657cb9bd", "s_1c74e041", "s_f7a9cb6c" },
		ids = { "m3_reward", "m3_resolve", "m3_find_out", "m3_training" } },
	{ n = 4, reward = "m4_reward", reply = "s_84bc2cb6", stem = "corellia_imperial_tier3_4", walk = { "s_84bc2cb6" },
		ids = { "m4_reward", "m4_training" } },
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

-- The group's pilot: mission n won and unpaid, n - 1 skills chosen
local function pilot(g, species, extra)
	local t3, paid = {}, {}

	for i = 1, g.n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid, mission = { [g.n] = "won" }, species = species }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

TestBlackEpsilonT3Rewards = {}

TestBlackEpsilonT3Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-8, I-5: the reward screen pays credits, the item (any species) and standing
		TestBlackEpsilonT3Rewards["test_" .. g.reward .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
			local player = pilot(g, sp.id)

			T.drive(player, g.reward)
			lu.assertEquals(player.bankCredits, T.CREDITS, g.reward .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, g.reward .. ": addBankCredits calls")
			lu.assertEquals(items(player), { T.ITEMS[g.n] }, g.reward .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), T.STANDING, g.reward .. ": Imperial standing")
			lu.assertEquals(H.getQuestStatus(player, g.stem .. ":reward"), "1", g.reward .. ": the :reward key")
		end
	end

	-- AC-8, I-9: the same screen shown again
	TestBlackEpsilonT3Rewards["test_" .. g.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		for _ = 1, 3 do
			T.drive(player, g.reward)
		end

		lu.assertEquals(player.bankCredits, T.CREDITS, g.reward .. ": bank credits after three visits")
		lu.assertEquals(#items(player), 1, g.reward .. ": items after three visits")
		lu.assertEquals(standing(player), T.STANDING, g.reward .. ": standing after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestBlackEpsilonT3Rewards["test_" .. g.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		H.setQuestStatus(player, g.stem .. ":reward", 1)
		T.drive(player, g.reward)
		lu.assertEquals(player.bankCredits, 0, g.reward .. ": bank credits")
		lu.assertEquals(#items(player), 0, g.reward .. ": items")
		lu.assertEquals(standing(player), 0, g.reward .. ": standing")
	end

	-- AC-8: the first screen of the talk is the reward screen; it pays on display, and a second visit before choosing shows it again for nothing
	TestBlackEpsilonT3Rewards["test_" .. g.reward .. "_opens_first_pays_once_and_opens_again_for_nothing"] = function()
		local player = pilot(g, SPECIES_HUMAN)
		local first = T.talk(player)

		lu.assertEquals(T.ids(first), { g.reward }, "first screen")
		lu.assertEquals(player.bankCredits, T.CREDITS, "the reward screen pays on display")
		lu.assertEquals(items(player), { T.ITEMS[g.n] }, "the item")
		lu.assertEquals(standing(player), T.STANDING, "standing")

		local again = T.talk(player)

		lu.assertEquals(T.ids(again), { g.reward }, "the next visit, before a skill is chosen, shows the reward screen again")
		lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits after the second visit")
		lu.assertEquals(#items(player), 1, "items after the second visit")
		lu.assertEquals(standing(player), T.STANDING, "standing after the second visit")
	end

	-- AC-8, AC-5: the reward walk leads to this mission's training screen
	TestBlackEpsilonT3Rewards["test_" .. g.reward .. "_walk_leads_to_the_training_screen"] = function()
		local player = pilot(g, SPECIES_HUMAN)
		local t = T.talk(player, g.walk)

		lu.assertEquals(T.ids(t), g.ids, "screens shown")
		lu.assertEquals(player.bankCredits, T.CREDITS, "the walk pays once")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings (AC-5)")
	end

	-- AC-8, D-9: the :reward key belongs to this mission only
	TestBlackEpsilonT3Rewards["test_paying_mission_" .. g.n .. "_sets_only_its_own_reward_key"] = function()
		local player = pilot(g, SPECIES_HUMAN)
		local before = {}

		for _, other in ipairs(GROUPS) do
			before[other.n] = H.getQuestStatus(player, other.stem .. ":reward")
		end

		T.drive(player, g.reward)

		for _, other in ipairs(GROUPS) do
			if other.n ~= g.n then
				lu.assertEquals(H.getQuestStatus(player, other.stem .. ":reward"), before[other.n], "the :reward key of mission " .. other.n .. " is unchanged")
			end
		end
	end
end

-- AC-8, I-9: the four reward screens share nothing
function TestBlackEpsilonT3Rewards:test_the_four_rewards_add_up_and_each_pays_once()
	local player = T.pilot({ mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

	for _ = 1, 2 do
		for _, g in ipairs(GROUPS) do
			T.drive(player, g.reward)
		end
	end

	lu.assertEquals(player.bankCredits, 4 * T.CREDITS, "bank credits")
	lu.assertEquals(items(player), { T.ITEMS[1], T.ITEMS[2], T.ITEMS[3], T.ITEMS[4] }, "items in mission order")
	lu.assertEquals(standing(player), 4 * T.STANDING, "standing")
end

-- AC-8: the reward is paid through the mission head's reward call (credits and item come from the head table)
function TestBlackEpsilonT3Rewards:test_each_reward_is_the_head_tables_reward_player()
	for _, g in ipairs(GROUPS) do
		H.reset()

		local head = T.MISSIONS[g.n].head
		local spy = H.spyOn(T.quest(head), "rewardPlayer")

		T.drive(pilot(g, SPECIES_HUMAN), g.reward)
		lu.assertEquals(#spy, 1, head .. ": rewardPlayer calls")
	end
end

-- AC-8: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestBlackEpsilonT3Rewards:test_a_full_inventory_still_receives_every_reward_item()
	for _, g in ipairs(GROUPS) do
		H.reset()

		local player = pilot(g, SPECIES_HUMAN, { inventory = { limit = 0 } })

		T.drive(player, g.reward)
		lu.assertEquals(#player.inventory.items, 1, g.reward .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, g.reward .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, g.reward .. ": giveItem calls")
		lu.assertIs(calls[1][4], true, g.reward .. ": the overload flag")
	end
end

-- AC-8, I-5: the offers, accepts, failure and hand-off screens pay nothing through a conversation
function TestBlackEpsilonT3Rewards:test_no_other_screen_pays()
	for _, id in ipairs({ "m1_offer", "m1_accept", "m2_accept", "m3_accept", "m4_accept", "m1_failed", "m1_retry", "m4_retry_promise", "on_mission", "tour_complete",
		"m1_debrief", "m1_training", "m4_training", "trained_starships", "trained_droid", "insurgent_dantooine" }) do
		H.reset()
		T.spyStarts()

		local player = T.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })

		T.drive(player, id)
		lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
		lu.assertEquals(#items(player), 0, id .. ": items")
		lu.assertEquals(standing(player), 0, id .. ": standing")
	end
end
