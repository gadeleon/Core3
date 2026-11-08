-- General Ufwol: the four mission rewards (10000 credits, a ship component, +150 Rebel standing) are paid once, on display of the reward screen (AC-7).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-7; invariant I-4; Source inventory 3; Conversation flow 3 (table H); FF-1, FF-2; D-3, D-7, D-11; JF:359-390).
--
-- The amounts are JF's rewardForMissionN (fixtures/script/conversation/tatooine_rebel_tier4.java:358-389). The oracle tests derive the expected credits, items and standing
-- from that fixture, check Part A's data (E.REWARDS and the head tables) and the handler's standing against them (D-11), and every payment test compares against the derived
-- values. "Won" is JF's: JF's set (mission 1: 1_a or 1_c; missions 2-4: either first-level child), so every payment test runs through both wins of its mission.
-- Credits are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Rebel standing.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function tearDown() E.restore() end

local J = E.javaRewards()

local function viasOf(n) return n == 1 and { "won_a", "won_c" } or { "won_a", "won_b" } end

TestUfwolRewardsOracle = {}

function TestUfwolRewardsOracle:setUp()
	H.reset()
	E.load()
end

-- AC-7 (the oracle itself), D-11: JF pays 10000 credits, its own ship component and +150 Rebel standing per mission, guarded by hasReceivedReward, on the head of the chain
function TestUfwolRewardsOracle:test_the_jf_reward_actions_are_10000_credits_the_listed_component_and_150_standing_on_the_chain_head()
	for n = 1, 4 do
		local r = J[n]

		lu.assertNotNil(r, "JF rewardForMission" .. n)
		lu.assertEquals(r.credits, 10000, "JF mission " .. n .. ": credits")
		lu.assertEquals(r.item, E.REWARDS[E.HEADS[n]].item, "JF mission " .. n .. ": item")
		lu.assertEquals(r.standing, E.STANDING + 0.0, "JF mission " .. n .. ": Rebel standing")
		lu.assertTrue(r.guarded, "JF mission " .. n .. ": guarded by hasReceivedReward")
		lu.assertEquals(r.type .. "_" .. r.name, E.HEADS[n], "JF mission " .. n .. ": the quest it pays is the head of the chain")
	end
end

-- AC-7, D-11: Part A's spec literals agree with JF (a mismatch is a Part A / spec defect, not something to paper over)
function TestUfwolRewardsOracle:test_part_a_data_agrees_with_jf()
	for n = 1, 4 do
		local head = E.HEADS[n]

		lu.assertEquals(E.REWARDS[head].credits, J[n].credits, "crimson_tier4_data E.REWARDS[" .. head .. "].credits vs JF")
		lu.assertEquals(E.REWARDS[head].item, J[n].item, "crimson_tier4_data E.REWARDS[" .. head .. "].item vs JF")
	end
end

-- AC-7, D-11: the head tables pay what JF pays
function TestUfwolRewardsOracle:test_the_head_tables_pay_what_jf_pays()
	for n = 1, 4 do
		local head = E.quest(E.HEADS[n])

		lu.assertEquals(head.creditReward, J[n].credits, E.HEADS[n] .. ": creditReward vs JF")
		lu.assertEquals(head.itemReward, { { species = { -1 }, item = J[n].item } }, E.HEADS[n] .. ": itemReward vs JF (any species)")
	end
end

-- AC-7, D-11: the handler's standing (MISSIONS[n].standing) is JF's +150
function TestUfwolRewardsOracle:test_the_handlers_standing_is_the_jf_standing()
	E.requireConversation(require("luaunit"))

	for n = 1, 4 do
		lu.assertEquals(rawget(_G, E.HANDLER).MISSIONS[n].standing + 0.0, J[n].standing, "MISSIONS[" .. n .. "].standing vs JF")
	end
end

TestUfwolRewards = {}

TestUfwolRewards.setUp = setUp
TestUfwolRewards.tearDown = tearDown

for n, m in ipairs(E.MISSIONS) do
	for _, via in ipairs(viasOf(n)) do
		-- AC-7, I-4: the reward screen pays credits, the item and standing, once; it is the first screen
		TestUfwolRewards["test_" .. m.reward .. "_through_" .. via .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
			local player = E.rewardPilot(n, via)
			local t = E.talk(player)

			lu.assertEquals(t[1].id, m.reward, "first screen")
			lu.assertEquals(player.bankCredits, J[n].credits, m.reward .. ": bank credits (JF)")
			lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
			lu.assertEquals(E.items(player), { J[n].item }, m.reward .. ": giveItem templates (JF)")
			lu.assertEquals(E.standing(player), J[n].standing, m.reward .. ": Rebel standing (JF)")
			lu.assertEquals(E.paid(player, n), "1", m.reward .. ": the :reward key")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-7: the head's rewardPlayer and the ghost's increaseFactionStanding are what pay (spied)
	TestUfwolRewards["test_" .. m.reward .. "_pays_through_the_heads_reward_player_and_the_ghosts_standing"] = function()
		local head = E.quest(m.head)
		local rewards = H.spyOn(head, "rewardPlayer")
		local player = E.rewardPilot(n)
		local standing = H.spyOn(player.ghost, "increaseFactionStanding")

		E.talk(player)
		lu.assertEquals(#rewards, 1, m.head .. ": rewardPlayer calls")
		lu.assertEquals(rewards[1].args[1], player, m.head .. ": rewardPlayer is called for the talking pilot")
		lu.assertEquals(#standing, 1, "increaseFactionStanding calls")
		lu.assertEquals({ standing[1].args[1], standing[1].args[2] }, { "rebel", 150 }, "increaseFactionStanding(\"rebel\", 150)")
	end

	-- AC-7, I-4: the same screen shown again pays nothing
	TestUfwolRewards["test_" .. m.reward .. "_shown_five_times_pays_once"] = function()
		local player = E.rewardPilot(n)

		E.talk(player)

		for visit = 2, 3 do
			local t = E.talk(player)

			lu.assertNotEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen is gone once paid")
		end

		E.drive(player, m.reward)
		E.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, J[n].credits, m.reward .. ": bank credits after the screen is shown five times")
		lu.assertEquals(#E.items(player), 1, m.reward .. ": items after five displays")
		lu.assertEquals(E.standing(player), J[n].standing, m.reward .. ": standing after five displays")
	end

	-- AC-7: the standing is added to what the pilot has
	TestUfwolRewards["test_" .. m.reward .. "_adds_150_to_the_existing_standing"] = function()
		local player = E.rewardPilot(n, "won_a", { standing = 100 })

		E.drive(player, m.reward)
		lu.assertEquals(E.standing(player), 250, "Rebel standing 100 + 150")
	end

	-- AC-7: a mission that was paid before pays nothing
	TestUfwolRewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = E.rewardPilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		E.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#E.items(player), 0, m.reward .. ": items")
		lu.assertEquals(E.standing(player), 0, m.reward .. ": standing")
	end

	-- AC-7: the reward item is paid to any species
	TestUfwolRewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = E.rewardPilot(n, "won_a", { species = SPECIES_WOOKIEE })

		E.drive(player, m.reward)
		lu.assertEquals(E.items(player), { J[n].item }, "giveItem templates for a Wookiee")
	end

	-- AC-7: the reward item uses the overload, so a full inventory still receives it
	TestUfwolRewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = E.rewardPilot(n, "won_a", { inventory = { limit = 0 } })

		E.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- AC-7: the replies after the reward screen pay nothing more and start nothing
	TestUfwolRewards["test_the_closing_lines_of_" .. m.reward .. "_pay_and_start_nothing_more"] = function()
		local row = E.screenRow(m.reward)

		for i, o in ipairs(row.options) do
			H.reset()

			local spies = E.spyDuties()
			local chains = E.stubChainStarts()
			local player = E.rewardPilot(n)
			local t = E.talk(player, { o[1] })

			lu.assertEquals(E.ids(t), { m.reward, o[2] }, "reply " .. i .. ": screens shown")
			lu.assertEquals(player.bankCredits, J[n].credits, "reply " .. i .. ": bank credits (paid once, on display)")
			lu.assertEquals(#E.items(player), 1, "reply " .. i .. ": items")
			lu.assertEquals(E.standing(player), J[n].standing, "reply " .. i .. ": standing")
			lu.assertEquals(chains, {}, "reply " .. i .. ": no chain started")
			lu.assertEquals(E.startedDuties(spies), {}, "reply " .. i .. ": no duty started")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end

	-- AC-7: the payment is the mission's own
	TestUfwolRewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = E.rewardPilot(n)
		local before = {}

		for other = 1, 4 do
			before[other] = E.paid(player, other)
		end

		E.drive(player, m.reward)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(E.paid(player, other), before[other], "mission " .. other .. " :reward is unchanged")
			end
		end

		lu.assertEquals(E.paid(player, n), "1", "mission " .. n .. " :reward is set")
	end

	-- AC-7: only the reward screen of mission n pays mission n
	TestUfwolRewards["test_no_screen_but_the_reward_screen_pays_for_mission_" .. n] = function()
		for _, row in ipairs(E.SCREENS) do
			if row.id ~= m.reward then
				H.reset()

				local player = E.rewardPilot(n)
				local expectPaid = E.REWARD_SCREENS[row.id] ~= nil

				E.spyDuties()
				E.stubChainStarts()
				E.drive(player, row.id)
				E.restore()

				if not expectPaid then
					lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
					lu.assertEquals(#E.items(player), 0, row.id .. ": items")
					lu.assertEquals(E.standing(player), 0, row.id .. ": standing")
					lu.assertNil(E.paid(player, n), row.id .. ": no :reward key of mission " .. n)
				else
					lu.assertNil(E.paid(player, n), row.id .. ": another mission's reward screen does not pay mission " .. n)
				end
			end
		end
	end
end

-- AC-7, D-3: mission 1 won through the failure branch's end 1_c (JF's isGettingMissionOneReward) pays like a win through 1_a; a patrol alone (1_b) pays nothing
function TestUfwolRewards:test_mission_1_pays_through_the_surprise_attack_and_not_through_the_patrol_alone()
	local won = E.rewardPilot(1, "won_c")
	local t = E.talk(won)

	lu.assertEquals(t[1].id, "m1_reward", "1_c won: first screen")
	lu.assertEquals(won.bankCredits, J[1].credits, "1_c won: bank credits")
	lu.assertEquals(E.items(won), { J[1].item }, "1_c won: item")
	lu.assertEquals(E.standing(won), 150, "1_c won: standing")
	lu.assertEquals(E.paid(won, 1), "1", "1_c won: the :reward key")

	H.reset()
	E.stubChainStarts()

	local patrol = E.rewardPilot(1, "won_b")

	lu.assertEquals(E.talk(patrol)[1].id, "m1_failed", "1_b complete, 1_c not won: the failure screen")
	lu.assertEquals(patrol.bankCredits, 0, "1_b alone pays nothing")
	lu.assertNil(E.paid(patrol, 1), "1_b alone sets no :reward key")
end

-- AC-7: a payment grants no skill and leaves the pilot tier alone
function TestUfwolRewards:test_a_reward_screen_grants_no_skill_and_leaves_the_tier_alone()
	for n, m in ipairs(E.MISSIONS) do
		H.reset()

		local player = E.rewardPilot(n)
		local tier = player.ghost.pilotTier

		E.drive(player, m.reward)
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, m.reward .. ": no skill")
		lu.assertEquals(#E.held4(player), n, m.reward .. ": the _04 skills held are unchanged")
		lu.assertEquals(player.ghost.pilotTier, tier, m.reward .. ": pilot tier")
	end
end

-- AC-7: mission 4 won and unpaid with all four skills shows m4_reward, pays once, then the transfer follows
function TestUfwolRewards:test_mission_4_with_four_skills_shows_m4_reward_pays_once_and_the_next_talk_is_the_transfer()
	local player = E.rewardPilot(4)
	local t = E.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, J[4].credits, "bank credits")
	lu.assertEquals(E.items(player), { J[4].item }, "the tri-cannon")
	lu.assertEquals(E.talk(player)[1].id, "transfer", "paid now, four skills: the hand-off")
	lu.assertEquals(player.bankCredits, J[4].credits, "bank credits after the second visit")
	lu.assertEquals(#E.items(player), 1, "items after the second visit")
end

-- AC-2, AC-7: the %TU of m2_reward is the pilot's first name; the other three reward lines carry no token
function TestUfwolRewards:test_the_name_reward_screens_greet_the_pilot_by_first_name()
	lu.assertEquals(E.talk(E.rewardPilot(2))[1].params.TU, "Ace", "m2_reward")

	for _, n in ipairs({ 1, 3, 4 }) do
		H.reset()
		lu.assertNil(E.talk(E.rewardPilot(n))[1].params.TU, "m" .. n .. "_reward")
	end
end

-- AC-7: pay once across the whole career, four missions (the sum, not just each screen)
function TestUfwolRewards:test_four_missions_pay_four_times_and_no_more()
	local player = E.pilot({ met = true })

	E.stubChainStarts()

	for n = 1, 4 do
		for _, global in ipairs(E.CHAINS[n]) do
			E.setState(player, global, "complete")
		end

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		player.skills[E.TRAIN[n].skill] = true
		E.talk(player)
		E.talk(player)
	end

	lu.assertEquals(player.bankCredits, 4 * 10000, "four rewards paid once each")
	lu.assertEquals(E.standing(player), 4 * 150, "four times +150 standing")
	lu.assertEquals(#E.items(player), 4, "four ship components")
	lu.assertEquals(E.items(player), { J[1].item, J[2].item, J[3].item, J[4].item }, "the four items in order")
end
