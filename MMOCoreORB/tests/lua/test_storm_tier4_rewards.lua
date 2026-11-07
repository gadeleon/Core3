-- Admiral Kilnstrider: the four mission rewards (10000 credits, a ship component, +150 Imperial standing) are paid once, on display of the reward screen.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-6; invariant I-5; Source inventory 2; Conversation flow 3 (table H); D-5, D-20; J:312-343).
--
-- The amounts are J's rewardForMissionN (fixtures/script/conversation/tatooine_imperial_tier4.java:312-343); the first tests derive the expected credits,
-- items and standing from that fixture, check Part A's data (D.REWARDS and the SSP head fields) against them (D-20), and every payment test compares
-- against the derived values. Credits are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

local J = D.javaRewards()

-- the pilot a reward screen opens for: missions 1..n-1 won and paid, n skills held, mission n won and unpaid
local function rewardPilot(n, extra)
	local t4, paid = {}, {}

	for i = 1, math.min(n, 4) do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true, mission = { [n] = "won" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

TestStormT4RewardsOracle = {}

function TestStormT4RewardsOracle:setUp() H.reset() end

-- B-6 (the oracle itself), D-20: J pays 10000 credits, its own ship component and +150 Imperial standing per mission, guarded by hasReceivedReward,
-- on the head of the chain
function TestStormT4RewardsOracle:test_the_j_reward_actions_are_10000_credits_the_listed_component_and_150_standing_on_the_chain_head()
	for n = 1, 4 do
		local r = J[n]

		lu.assertNotNil(r, "J rewardForMission" .. n)
		lu.assertEquals(r.credits, D.CREDITS, "J mission " .. n .. ": credits")
		lu.assertEquals(r.item, D.REWARDS[n].item, "J mission " .. n .. ": item")
		lu.assertEquals(r.standing, D.STANDING + 0.0, "J mission " .. n .. ": Imperial standing")
		lu.assertTrue(r.guarded, "J mission " .. n .. ": guarded by hasReceivedReward")
		lu.assertEquals(r.type .. "_" .. r.name, D.MISSIONS[n].head, "J mission " .. n .. ": the quest it pays is the head of the chain")
	end
end

-- B-6, D-20: Part A's spec literals agree with J (a mismatch is a Part A / spec defect, not something to paper over)
function TestStormT4RewardsOracle:test_part_a_data_agrees_with_j()
	for n = 1, 4 do
		lu.assertEquals(D.REWARDS[n].credits, J[n].credits, "storm_tier4_data D.REWARDS[" .. n .. "].credits vs J")
		lu.assertEquals(D.REWARDS[n].item, J[n].item, "storm_tier4_data D.REWARDS[" .. n .. "].item vs J")
	end
end

-- B-6, D-20: the SSP head tables pay what J pays
function TestStormT4RewardsOracle:test_the_squadron_head_tables_pay_what_j_pays()
	for n = 1, 4 do
		local head = D.quest(D.MISSIONS[n].head)

		lu.assertEquals(head.creditReward, J[n].credits, D.MISSIONS[n].head .. ": creditReward vs J")
		lu.assertEquals(head.itemReward, { { species = { -1 }, item = J[n].item } }, D.MISSIONS[n].head .. ": itemReward vs J (any species)")
	end
end

TestStormT4Rewards = {}

TestStormT4Rewards.setUp = setUp

for n, m in ipairs(D.MISSIONS) do
	-- B-6, I-5: the reward screen pays credits, the item and standing, once; it is the first screen
	TestStormT4Rewards["test_" .. m.reward .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
		local player = rewardPilot(n)
		local t = D.talk(player)

		lu.assertEquals(t[1].id, m.reward, "first screen")
		lu.assertEquals(player.bankCredits, J[n].credits, m.reward .. ": bank credits (J)")
		lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
		lu.assertEquals(D.items(player), { J[n].item }, m.reward .. ": giveItem templates (J)")
		lu.assertEquals(D.standingOf(player), J[n].standing, m.reward .. ": Imperial standing (J)")
		lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", m.reward .. ": the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- B-6: the head's rewardPlayer and the ghost's increaseFactionStanding are what pay (spied)
	TestStormT4Rewards["test_" .. m.reward .. "_pays_through_the_heads_reward_player_and_the_ghosts_standing"] = function()
		local head = D.quest(m.head)
		local rewards = H.spyOn(head, "rewardPlayer")
		local player = rewardPilot(n)
		local standing = H.spyOn(player.ghost, "increaseFactionStanding")

		D.talk(player)
		lu.assertEquals(#rewards, 1, m.head .. ": rewardPlayer calls")
		lu.assertEquals(rewards[1].args[1], player, m.head .. ": rewardPlayer is called for the talking pilot")
		lu.assertEquals(#standing, 1, "increaseFactionStanding calls")
		lu.assertEquals({ standing[1].args[1], standing[1].args[2] }, { "imperial", 150 }, "increaseFactionStanding(\"imperial\", 150)")
	end

	-- B-6, I-5: the same screen shown again pays nothing
	TestStormT4Rewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = rewardPilot(n)

		D.talk(player)

		for visit = 2, 3 do
			local t = D.talk(player)

			lu.assertNotEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen is gone once paid")
		end

		D.drive(player, m.reward)
		D.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, J[n].credits, m.reward .. ": bank credits after the screen is shown five times")
		lu.assertEquals(#D.items(player), 1, m.reward .. ": items after five displays")
		lu.assertEquals(D.standingOf(player), J[n].standing, m.reward .. ": standing after five displays")
	end

	-- B-6: a mission that was paid before pays nothing
	TestStormT4Rewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = rewardPilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		D.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#D.items(player), 0, m.reward .. ": items")
		lu.assertEquals(D.standingOf(player), 0, m.reward .. ": standing")
	end

	-- B-6: the reward item is paid to any species
	TestStormT4Rewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = rewardPilot(n, { species = SPECIES_WOOKIEE })

		D.drive(player, m.reward)
		lu.assertEquals(D.items(player), { J[n].item }, "giveItem templates for a Wookiee")
	end

	-- B-6: the reward item uses the overload, so a full inventory still receives it
	TestStormT4Rewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = rewardPilot(n, { inventory = { limit = 0 } })

		D.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- B-6: the replies after the reward screen pay nothing more and start nothing
	TestStormT4Rewards["test_the_closing_lines_of_" .. m.reward .. "_pay_and_start_nothing_more"] = function()
		local spies = D.spyStarts()
		local row = D.screenRow(m.reward)

		for i, o in ipairs(row.options) do
			H.reset()
			spies = D.spyStarts()

			local player = rewardPilot(n)
			local t = D.talk(player, { o[1] })

			lu.assertEquals(D.ids(t), { m.reward, o[2] }, "reply " .. i .. ": screens shown")
			lu.assertTrue(t[2].stop, o[2] .. " ends the conversation")
			lu.assertEquals(player.bankCredits, J[n].credits, "reply " .. i .. ": bank credits (paid once, on display)")
			lu.assertEquals(#D.items(player), 1, "reply " .. i .. ": items")
			lu.assertEquals(D.standingOf(player), J[n].standing, "reply " .. i .. ": standing")
			lu.assertEquals(D.started(spies), {}, "reply " .. i .. ": nothing started")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- B-6: only the four reward screens pay (each its own mission, tested above): no other screen does
	TestStormT4Rewards["test_no_screen_but_the_reward_screen_pays_for_mission_" .. n] = function()
		for _, row in ipairs(D.SCREENS) do
			if D.PAYS[row.id] == nil then
				H.reset()

				local player = rewardPilot(n)

				D.spyStarts()
				D.drive(player, row.id)
				lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
				lu.assertEquals(#D.items(player), 0, row.id .. ": items")
				lu.assertEquals(D.standingOf(player), 0, row.id .. ": standing")
				lu.assertNil(H.getQuestStatus(player, m.status .. ":reward"), row.id .. ": no :reward key of mission " .. n)
			end
		end
	end

	-- B-6: the payment is the mission's own
	TestStormT4Rewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = rewardPilot(n)
		local before = {}

		for other = 1, 4 do
			before[other] = H.getQuestStatus(player, D.MISSIONS[other].status .. ":reward")
		end

		D.drive(player, m.reward)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(H.getQuestStatus(player, D.MISSIONS[other].status .. ":reward"), before[other], "mission " .. other .. " :reward is unchanged")
			end
		end

		lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", "mission " .. n .. " :reward is set")
	end
end

-- B-6: the skills and the pilot tier are untouched by a payment
function TestStormT4Rewards:test_a_reward_screen_grants_no_skill_and_leaves_the_tier_alone()
	for n, m in ipairs(D.MISSIONS) do
		H.reset()

		local player = rewardPilot(n)
		local tier = player.ghost.pilotTier

		D.drive(player, m.reward)
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, m.reward .. ": no skill")
		lu.assertEquals(#D.held4(player), n, m.reward .. ": the _04 skills held are unchanged")
		lu.assertEquals(player.ghost.pilotTier, tier, m.reward .. ": pilot tier")
	end
end

-- B-6, B-8: mission 4 won and unpaid with all four skills still shows m4_reward, pays once, then the transfer follows
function TestStormT4Rewards:test_mission_4_with_four_skills_shows_m4_reward_pays_once_and_the_next_talk_is_the_transfer()
	local player = D.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" }, met = true })
	local t = D.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, J[4].credits, "bank credits")
	lu.assertEquals(D.items(player), { J[4].item }, "the reactor")
	lu.assertEquals(D.talk(player)[1].id, "transfer", "paid now, four skills: the hand-off")
	lu.assertEquals(player.bankCredits, J[4].credits, "bank credits after the second visit")
	lu.assertEquals(#D.items(player), 1, "items after the second visit")
end

-- B-6: the %NU / %TU of the reward screens is the pilot's first name
function TestStormT4Rewards:test_the_name_reward_screens_greet_the_pilot_by_first_name()
	for _, id in ipairs({ "m1_reward", "m2_reward", "m3_reward" }) do
		local t = D.drive(D.pilot({ met = true, t4 = { 1, 2, 3 } }), id)

		lu.assertEquals(t[1].params.TU, "Ace", id .. ": the name token")
	end
end
