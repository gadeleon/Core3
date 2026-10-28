-- Nin Gursawe: the four mission rewards (10000 credits, a ship component, +150 Imperial standing) are paid once, on display of a reward screen.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-9, AC-5; invariants I-5, I-9; Content contract 3; Conversation flow 1 (P12 .. P15) and 4 (table H)).
--
-- The amounts are J's (corellia_imperial_tier4.java:334-365). Credits are the bank credits of the fake pilot, items the giveItem calls on its
-- inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

-- the first reply of each reward screen (Appendix A) and the debrief walks to their end
local GROUPS = {
	{ n = 1, reward = "m1_reward", stem = "corellia_imperial_tier4_1",
		walks = {
			{ ids = { "m1_reward", "m1_message", "m1_beyond", "m1_direction" }, replies = { "s_fd6077a1", "s_40cb88ec", "s_42c52a5" } },
			{ ids = { "m1_reward", "m1_message", "m1_theories", "m1_origin" }, replies = { "s_fd6077a1", "s_6465b813", "s_592140" } },
			{ ids = { "m1_reward", "m1_message", "m1_clue", "m1_dantooine" }, replies = { "s_fd6077a1", "s_68d65b58", "s_b5e3a1" } },
		} },
	{ n = 2, reward = "m2_reward", stem = "corellia_imperial_tier4_2",
		walks = {
			{ ids = { "m2_reward", "m2_business", "m2_orders", "m2_standby" }, replies = { "s_dcc126b1", "s_d56d9c26", "s_47e47c9e" } },
			{ ids = { "m2_reward", "m2_better", "m2_standby" }, replies = { "s_f83729d0", "s_e3d62b89" } },
			{ ids = { "m2_reward", "m2_unstoppable", "m2_prerogative" }, replies = { "s_6d6d19f4", "s_ce9d7377" } },
		} },
	{ n = 3, reward = "m3_reward", stem = "corellia_imperial_tier4_3",
		walks = {
			{ ids = { "m3_reward", "m3_dathomir", "m3_crew" }, replies = { "s_bb5f90b1", "s_c0036582" } },
			{ ids = { "m3_reward", "m3_decoding" }, replies = { "s_14c473a" } },
		} },
	{ n = 4, reward = "m4_reward", stem = "corellia_imperial_tier4_4",
		walks = {
			{ ids = { "m4_reward", "m4_jedi", "m4_goodbye" }, replies = { "s_d129b116", "s_fe20f03e" } },
			{ ids = { "m4_reward", "m4_figured", "m4_goodbye" }, replies = { "s_85e8b1c4", "s_8778fe46" } },
		} },
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

-- The group's pilot: mission n won and unpaid, the earlier missions paid with their skills, past the intro
local function pilot(g, species, extra)
	local t4, paid = {}, {}

	for i = 1, g.n - 1 do
		t4[i] = i
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, mission = { [g.n] = "won" }, species = species, keys = { intro = true, met = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

TestBlackEpsilonT4Rewards = {}

TestBlackEpsilonT4Rewards.setUp = setUp

for _, g in ipairs(GROUPS) do
	for _, sp in ipairs(SPECIES) do
		-- AC-9, I-5: the reward screen pays credits, the item (any species) and standing
		TestBlackEpsilonT4Rewards["test_" .. g.reward .. "_pays_mission_" .. g.n .. "_to_a_" .. sp.name] = function()
			local player = pilot(g, sp.id)

			T.drive(player, g.reward)
			lu.assertEquals(player.bankCredits, T.CREDITS, g.reward .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, g.reward .. ": addBankCredits calls")
			lu.assertEquals(items(player), { T.ITEMS[g.n] }, g.reward .. " (" .. sp.name .. "): giveItem templates")
			lu.assertEquals(standing(player), T.STANDING, g.reward .. ": Imperial standing")
			lu.assertEquals(H.getQuestStatus(player, g.stem .. ":reward"), "1", g.reward .. ": the :reward key")
		end
	end

	-- AC-9, I-9: the same screen shown again
	TestBlackEpsilonT4Rewards["test_" .. g.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		for _ = 1, 3 do
			T.drive(player, g.reward)
		end

		lu.assertEquals(player.bankCredits, T.CREDITS, g.reward .. ": bank credits after three visits")
		lu.assertEquals(#items(player), 1, g.reward .. ": items after three visits")
		lu.assertEquals(standing(player), T.STANDING, g.reward .. ": standing after three visits")
	end

	-- AC-9: a mission that was paid before pays nothing
	TestBlackEpsilonT4Rewards["test_" .. g.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(g, SPECIES_HUMAN)

		H.setQuestStatus(player, g.stem .. ":reward", 1)
		T.drive(player, g.reward)
		lu.assertEquals(player.bankCredits, 0, g.reward .. ": bank credits")
		lu.assertEquals(#items(player), 0, g.reward .. ": items")
		lu.assertEquals(standing(player), 0, g.reward .. ": standing")
	end

	-- AC-9: the first screen of the talk is the reward screen; it pays on display; the next talk does not show it again and pays nothing
	TestBlackEpsilonT4Rewards["test_" .. g.reward .. "_opens_first_pays_once_and_the_next_talk_does_not_show_it"] = function()
		local player = pilot(g, SPECIES_HUMAN)
		local first = T.talk(player)

		lu.assertEquals(T.ids(first), { g.reward }, "first screen")
		lu.assertEquals(player.bankCredits, T.CREDITS, "the reward screen pays on display")
		lu.assertEquals(items(player), { T.ITEMS[g.n] }, "the item")
		lu.assertEquals(standing(player), T.STANDING, "standing")

		local again = T.talk(player)

		lu.assertNotEquals(again[1].id, g.reward, "the next talk does not show the reward screen again")
		lu.assertEquals(player.bankCredits, T.CREDITS, "bank credits after the second talk")
		lu.assertEquals(#items(player), 1, "items after the second talk")
		lu.assertEquals(standing(player), T.STANDING, "standing after the second talk")
	end

	-- AC-9, AC-5: the debrief walks end and pay once
	for i, w in ipairs(g.walks) do
		TestBlackEpsilonT4Rewards["test_" .. g.reward .. "_debrief_walk_" .. i .. "_ends_and_pays_once"] = function()
			local player = pilot(g, SPECIES_HUMAN)
			local t = T.talk(player, w.replies)

			lu.assertEquals(T.ids(t), w.ids, "screens shown")
			lu.assertTrue(t[#t].stop, "the debrief ends the conversation")
			lu.assertEquals(player.bankCredits, T.CREDITS, "the walk pays once")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-9, D-14: the :reward key belongs to this mission only
	TestBlackEpsilonT4Rewards["test_paying_mission_" .. g.n .. "_sets_only_its_own_reward_key"] = function()
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

-- AC-9, I-9: the four reward screens share nothing
function TestBlackEpsilonT4Rewards:test_the_four_rewards_add_up_and_each_pays_once()
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

-- AC-9: the reward is paid through the mission head's reward call (credits and item come from the head table)
function TestBlackEpsilonT4Rewards:test_each_reward_is_the_head_tables_reward_player()
	for _, g in ipairs(GROUPS) do
		H.reset()

		local head = T.MISSIONS[g.n].head
		local spy = H.spyOn(T.quest(head), "rewardPlayer")

		T.drive(pilot(g, SPECIES_HUMAN), g.reward)
		lu.assertEquals(#spy, 1, head .. ": rewardPlayer calls")
	end
end

-- AC-9: the reward items use the overload, so a full inventory still receives them (9034fa3254)
function TestBlackEpsilonT4Rewards:test_a_full_inventory_still_receives_every_reward_item()
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

-- AC-9, I-5: every other screen pays nothing (the briefs, grants, failures, intro, training and hand-off screens)
function TestBlackEpsilonT4Rewards:test_no_other_screen_pays()
	for _, row in ipairs(T.SCREENS) do
		if not row.action:match("^pay") then
			H.reset()
			T.spyStarts()

			local player = T.pilot({ mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" }, keys = { intro = true, met = true } })

			T.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
			lu.assertEquals(#items(player), 0, row.id .. ": items")
			lu.assertEquals(standing(player), 0, row.id .. ": standing")
		end
	end
end

-- AC-9, D-5: the reward comes before the tier-done screens: all skills held, mission 4 won and unpaid, the first screen is the reward
function TestBlackEpsilonT4Rewards:test_the_fourth_reward_comes_before_the_transfer_and_the_duty_menu()
	local player = T.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" }, keys = { intro = true, met = true } })

	lu.assertEquals(T.firstScreen(player), "m4_reward", "the first screen")
	lu.assertEquals(player.bankCredits, T.CREDITS, "paid on display")
	lu.assertEquals(items(player), { T.ITEMS[4] }, "the reactor")
end
