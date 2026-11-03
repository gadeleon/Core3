-- Nirame Sakute: the four mission rewards (10000 credits and a ship component each, no faction standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-9, AC-6; invariants I-5, I-9; Content contract 3 (payMission); Conversation flow 1 (G10 .. G13) and 3 (table H)).
--
-- The amounts and items are NJ's (fixtures/script/conversation/tatooine_privateer_tier4.java:326-353, parsed by smuggler_tier4_data.lua N.rewards). Credits
-- are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's faction standing.

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local CS = require("harness.client_strings")

N.load()

local function setUp()
	H.reset()
	N.requireConversation(lu)
end

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

local function itemOf(n)
	local id = N.IDENTITY[N.HEADS[n]]

	return N.rewards()[id.type .. "/" .. id.name].item
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

-- The mission's pilot: mission n won and unpaid, missions 1..n-1 paid with their skills
local function pilot(n, species, extra)
	local t4, paid = {}, {}

	for i = 1, n - 1 do
		t4[i] = i
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, mission = { [n] = "won" }, species = species, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return N.pilot(o)
end

TestSmugglerT4Rewards = {}

TestSmugglerT4Rewards.setUp = setUp

for n, m in ipairs(N.MISSIONS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-9, I-5: the reward screen pays credits and the item (any species) and no standing
		TestSmugglerT4Rewards["test_" .. m.reward .. "_pays_mission_" .. n .. "_to_a_" .. sp.name] = function()
			local player = pilot(n, sp.id)
			local before = standing(player)

			N.drive(player, m.reward)
			lu.assertEquals(player.bankCredits, N.CREDITS, m.reward .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
			lu.assertEquals(items(player), { itemOf(n) }, m.reward .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), before, m.reward .. ": faction standing is not touched")
			lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", m.reward .. ": the :reward key")
		end
	end

	-- AC-9, I-5, I-9: the same screen shown again
	TestSmugglerT4Rewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(n, SPECIES_HUMAN)

		for _ = 1, 3 do
			N.drive(player, m.reward)
		end

		lu.assertEquals(player.bankCredits, N.CREDITS, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#items(player), 1, m.reward .. ": items after three visits")
	end

	-- AC-9: a mission that was paid before pays nothing
	TestSmugglerT4Rewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(n, SPECIES_HUMAN)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		N.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#items(player), 0, m.reward .. ": items")
	end

	-- AC-9: the first screen of the talk is the reward screen; it pays on display, and the next visit shows the next gate
	TestSmugglerT4Rewards["test_" .. m.reward .. "_opens_first_pays_once_and_the_next_visit_opens_the_next_gate"] = function()
		local player = pilot(n, SPECIES_HUMAN)
		local first = N.talk(player)

		lu.assertEquals(N.ids(first), { m.reward }, "first screen")
		lu.assertEquals(player.bankCredits, N.CREDITS, "the reward screen pays on display")
		lu.assertEquals(items(player), { itemOf(n) }, "the item")
		lu.assertEquals(CS.transcriptUnresolved(first), {}, "client strings (AC-6)")

		local again = N.talk(player)

		lu.assertNotEquals(again[1].id, m.reward, "the reward screen does not come back once the reward is paid")
		lu.assertEquals(player.bankCredits, N.CREDITS, "bank credits after the second visit")
		lu.assertEquals(#items(player), 1, "items after the second visit")
	end

	-- AC-9, D-12: the :reward key belongs to this mission only
	TestSmugglerT4Rewards["test_paying_mission_" .. n .. "_sets_only_its_own_reward_key"] = function()
		local player = pilot(n, SPECIES_HUMAN)
		local before = {}

		for k = 1, 4 do
			before[k] = H.getQuestStatus(player, N.MISSIONS[k].status .. ":reward")
		end

		N.drive(player, m.reward)

		for k = 1, 4 do
			if k ~= n then
				lu.assertEquals(H.getQuestStatus(player, N.MISSIONS[k].status .. ":reward"), before[k], "the :reward key of mission " .. k .. " is unchanged")
			end
		end
	end
end

-- AC-9, I-5: the four reward screens share nothing
function TestSmugglerT4Rewards:test_the_four_rewards_add_up_and_each_pays_once()
	local player = N.pilot({ mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

	for _ = 1, 2 do
		for _, m in ipairs(N.MISSIONS) do
			N.drive(player, m.reward)
		end
	end

	lu.assertEquals(player.bankCredits, 4 * N.CREDITS, "bank credits")
	lu.assertEquals(items(player), { itemOf(1), itemOf(2), itemOf(3), itemOf(4) }, "items in mission order")
end

-- AC-9: the reward is paid through the mission head's reward call (credits and item come from the head table)
function TestSmugglerT4Rewards:test_each_reward_is_the_head_tables_reward_player()
	for n, m in ipairs(N.MISSIONS) do
		H.reset()

		local spy = H.spyOn(N.quest(m.head), "rewardPlayer")

		local player = pilot(n, SPECIES_HUMAN)

		N.drive(player, m.reward)
		lu.assertEquals(#spy, 1, m.head .. ": rewardPlayer calls")
		lu.assertEquals(spy[1].args[1], player, m.head .. ": rewardPlayer gets the pilot")
	end
end

-- AC-9: a full inventory still receives the items (the overload flag)
function TestSmugglerT4Rewards:test_a_full_inventory_still_receives_every_reward_item()
	for n, m in ipairs(N.MISSIONS) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		N.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, m.reward .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, m.reward .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, m.reward .. ": giveItem calls")
		lu.assertIs(calls[1][4], true, m.reward .. ": the overload flag")
	end
end

-- AC-9: the four reward dialogues walk to their ends (J:1153-1356) and pay nothing more
function TestSmugglerT4Rewards:test_the_reward_dialogues_walk_to_their_ends()
	local walks = {
		{ 1, { "s_fc27931b" }, { "m1_reward", "m1_reward_anytime" } },
		{ 1, { "s_6e4cac2c" }, { "m1_reward", "m1_reward_sure" } },
		{ 2, { "s_fc27931b" }, { "m2_reward", "m2_reward_tide" } },
		{ 2, { "s_dcc126b1" }, { "m2_reward", "m2_reward_modesty" } },
		{ 3, { "s_dd67013", "s_f69cf191" }, { "m3_reward", "m3_reward_means", "m3_reward_ungrateful" } },
		{ 3, { "s_96c7f9b", "s_9cc12ff4", "s_f600815f" }, { "m3_reward", "m3_reward_happy", "m3_reward_pay", "m3_reward_now_happy" } },
		{ 4, { "s_d70dba34" }, { "m4_reward", "m4_reward_got_it" } },
		{ 4, { "s_677b3694" }, { "m4_reward", "m4_reward_everybody" } },
	}

	for i, w in ipairs(walks) do
		H.reset()

		local player = pilot(w[1], SPECIES_HUMAN)
		local t = N.talk(player, w[2])

		lu.assertEquals(N.ids(t), w[3], "walk " .. i)
		lu.assertTrue(t[#t].stop, "walk " .. i .. ": the last screen ends the conversation")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "walk " .. i .. ": client strings")
		lu.assertEquals(player.bankCredits, N.CREDITS, "walk " .. i .. ": paid once")
	end
end

-- AC-9, I-5: the briefs, grants, failure, hand-off and menu screens pay nothing through a conversation
function TestSmugglerT4Rewards:test_no_other_screen_pays()
	for _, id in ipairs({ "ready", "m1_brief", "m1_accept_a", "m2_accept", "m3_accept", "m4_accept_b", "m1_failed", "m1_retry_a", "m4_retry_b", "busy", "intro_busy", "duty_menu",
		"transfer", "transfer_where", "here_for_work", "m1_trained_droid", "m4_brief_trained" }) do
		H.reset()
		N.spyStarts()

		local player = N.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, met = true })

		N.drive(player, id)
		lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
		lu.assertEquals(#items(player), 0, id .. ": items")
	end
end
