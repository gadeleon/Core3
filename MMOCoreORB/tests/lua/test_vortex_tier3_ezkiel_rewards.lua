-- Brother Ezkiel: the four mission rewards (25000 credits, a ship component, +100 Rebel standing) are paid once, on display of the reward screen.
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-6; invariant I-4; Source inventory 3; Conversation flow 3 (table H); FV-2, FV-3; D-5; J3:232-263).
--
-- The amounts are J3's rewardForQuestN (fixtures/script/conversation/naboo_rebel_tier3.java:232-263). The oracle tests derive the expected credits, items and standing
-- from that fixture and compare them with the four head tables of Part A (PA D-6); every payment test compares against the derived values.
-- Credits are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Rebel standing.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local CS = require("harness.client_strings")

W.loadConversation()

local function setUp()
	H.reset()
	W.requireConversation(lu)
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- J3: for each rewardForQuestN function: type, name, credits, item, standing. Returned by mission number.
local function j3Rewards()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_rebel_tier3.java")
	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("naboo_rebel_tier3_action_rewardForQuest(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
		local questType, questName, credits, item = body:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_REBEL, ([%d%.]+)f%)")
		local guard = body:match('!space_quest%.hasReceivedReward%(player, "([^"]+)", "([^"]+)"%)')

		out[words[word]] = { type = questType, name = questName, credits = tonumber(credits), item = item, standing = tonumber(standing), guarded = guard ~= nil }
	end

	return out
end

local J3 = j3Rewards()

TestEzkielRewardsOracle = {}

function TestEzkielRewardsOracle:setUp()
	H.reset()
	W.load()
end

-- AC-6 (the oracle itself): J3 pays 25000 credits, its own ship component and +100 Rebel standing per mission, guarded by hasReceivedReward
function TestEzkielRewardsOracle:test_the_j3_reward_actions_are_25000_credits_the_listed_component_and_100_standing()
	for n = 1, 4 do
		local r = J3[n]

		lu.assertNotNil(r, "J3 rewardForQuest" .. n)
		lu.assertEquals(r.credits, W.CREDITS, "J3 mission " .. n .. ": credits")
		lu.assertEquals(r.item, W.ITEM_ROOT .. W.ITEMS[n], "J3 mission " .. n .. ": item")
		lu.assertEquals(r.standing, W.STANDING + 0.0, "J3 mission " .. n .. ": Rebel standing")
		lu.assertTrue(r.guarded, "J3 mission " .. n .. ": guarded by hasReceivedReward")
		lu.assertEquals(r.type .. "_" .. r.name, W.HEADS[n], "J3 mission " .. n .. ": the quest it pays is the head of the chain")
	end
end

-- AC-6 (Part A, PA D-6): the four head tables carry J3's credits and item, so paying through the head pays what J3 pays
function TestEzkielRewardsOracle:test_the_head_tables_carry_the_j3_credits_and_items()
	for n = 1, 4 do
		local head = W.quest(W.HEADS[n])

		lu.assertEquals(head.creditReward, J3[n].credits, W.HEADS[n] .. ": creditReward")
		lu.assertEquals(head.itemReward[1].item, J3[n].item, W.HEADS[n] .. ": itemReward")
	end
end

TestEzkielRewards = {}

TestEzkielRewards.setUp = setUp

for n, m in ipairs(W.MISSIONS) do
	-- AC-6, I-4: the reward screen pays credits, the item and standing, once; it is the first screen
	TestEzkielRewards["test_" .. m.reward .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
		local player = W.rewardPilot(n)
		local t = W.talk(player)

		lu.assertEquals(t[1].id, m.reward, "first screen")
		lu.assertEquals(player.bankCredits, J3[n].credits, m.reward .. ": bank credits (J3)")
		lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
		lu.assertEquals(W.items(player), { J3[n].item }, m.reward .. ": giveItem templates (J3)")
		lu.assertEquals(W.standing(player), J3[n].standing, m.reward .. ": Rebel standing (J3)")
		lu.assertEquals(W.paid(player, n), "1", m.reward .. ": the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-6, I-4: the same screen shown again before a skill is chosen pays nothing
	TestEzkielRewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = W.rewardPilot(n)

		for visit = 1, 3 do
			local t = W.talk(player)

			lu.assertEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen shows again until a skill is chosen")
		end

		lu.assertEquals(player.bankCredits, J3[n].credits, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#W.items(player), 1, m.reward .. ": items after three visits")
		lu.assertEquals(W.standing(player), J3[n].standing, m.reward .. ": standing after three visits")
	end

	-- AC-6: a mission that was paid before pays nothing
	TestEzkielRewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = W.rewardPilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		W.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#W.items(player), 0, m.reward .. ": items")
		lu.assertEquals(W.standing(player), 0, m.reward .. ": standing")
	end

	-- AC-6: the reward item is paid to any species
	TestEzkielRewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = W.rewardPilot(n, { species = SPECIES_WOOKIEE })

		W.drive(player, m.reward)
		lu.assertEquals(W.items(player), { J3[n].item }, "giveItem templates for a Wookiee")
	end

	-- AC-6: the reward item uses the overload, so a full inventory still receives it
	TestEzkielRewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = W.rewardPilot(n, { inventory = { limit = 0 } })

		W.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- AC-6: the payment is the mission's own
	TestEzkielRewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = W.rewardPilot(n)
		local before = {}

		for other = 1, 4 do
			before[other] = W.paid(player, other)
		end

		W.drive(player, m.reward)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(W.paid(player, other), before[other], "mission " .. other .. " :reward is unchanged")
			end
		end
	end
end

-- AC-6, I-4: only the four reward screens pay (FV-2: J3 pays on the reward lines themselves)
function TestEzkielRewards:test_no_other_screen_pays()
	for _, row in ipairs(W.SCREENS) do
		if W.REWARD_SCREENS[row.id] == nil then
			H.reset()

			local player = W.pilot({ missions = 2, t3 = 2 })

			W.spyStarts()

			local keys = { W.paid(player, 3), W.paid(player, 4) }

			W.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
			lu.assertEquals(#W.items(player), 0, row.id .. ": items")
			lu.assertEquals(W.standing(player), 0, row.id .. ": standing")
			lu.assertEquals({ W.paid(player, 3), W.paid(player, 4) }, keys, row.id .. ": no :reward key")
		end
	end
end

-- AC-6: the debrief walk from the reward screen to a trained screen pays once
function TestEzkielRewards:test_a_pilot_who_picks_a_topic_was_paid_exactly_once()
	for n = 1, 4 do
		H.reset()

		local player = W.rewardPilot(n)
		local t = W.talk(player, { W.TRAIN[n].reply })

		lu.assertEquals(W.ids(t), { "m" .. n .. "_reward", W.TRAIN[n].trained }, "mission " .. n .. ": screens shown")
		lu.assertEquals(player.bankCredits, J3[n].credits, "bank credits")
		lu.assertEquals(W.items(player), { J3[n].item }, "giveItem templates")
		lu.assertEquals(W.standing(player), J3[n].standing, "Rebel standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end
end

-- AC-6, AC-8, FV-4: mission 4 won and unpaid with all four skills held still shows m4_reward, pays once, and the hand-off waits until it is paid
function TestEzkielRewards:test_mission_4_with_four_skills_and_the_reward_unpaid_shows_m4_reward_and_pays_once()
	local player = W.pilot({ missions = 3, t3 = 4, state = "won" })
	local t = W.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, J3[4].credits, "bank credits")
	lu.assertEquals(W.items(player), { J3[4].item }, "the reactor")
	lu.assertEquals(#t[1].options, 0, "no topic is left to choose")
	lu.assertTrue(t[1].stop, "m4_reward stops when no skill is missing")
	lu.assertEquals(W.talk(player)[1].id, "tier_done", "paid now, all four skills: the work is done")
	lu.assertEquals(player.bankCredits, J3[4].credits, "bank credits after the second visit")
	lu.assertEquals(#W.items(player), 1, "items after the second visit")
end

-- AC-6: a reward screen grants no skill on display
function TestEzkielRewards:test_a_reward_screen_grants_no_skill_on_display()
	for n, m in ipairs(W.MISSIONS) do
		H.reset()

		local player = W.rewardPilot(n)

		W.drive(player, m.reward)
		lu.assertEquals(#W.free() + #W.bought(), 0, m.reward .. ": no skill")
		lu.assertEquals(#W.held3(player), n - 1, m.reward .. ": the tier 3 skills held are unchanged")
	end
end

-- AC-6: the %TU of m1_reward is the pilot's first name (the others carry no token)
function TestEzkielRewards:test_m1_reward_greets_the_pilot_by_first_name()
	local t = W.talk(W.rewardPilot(1))

	lu.assertEquals(t[1].params.TU, "Ace", "m1_reward: %NU")
	lu.assertEquals(t[1].text, W.PREFIX .. "s_eeb2051f", "m1_reward line")
end

-- AC-6: pay once across the whole career, four missions (the sum, not just each screen)
function TestEzkielRewards:test_four_missions_pay_four_times_and_no_more()
	local player = W.pilot({})

	for n = 1, 4 do
		for _, global in ipairs(W.CHAINS[n]) do
			W.setState(player, global, "complete")
		end

		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")
		W.talk(player, { W.TRAIN[n].reply })
		W.talk(player)
	end

	lu.assertEquals(player.bankCredits, 4 * W.CREDITS, "four rewards paid once each")
	lu.assertEquals(W.standing(player), 4 * W.STANDING, "four times +100 standing")
	lu.assertEquals(#W.items(player), 4, "four ship components")
	lu.assertEquals(W.items(player), { J3[1].item, J3[2].item, J3[3].item, J3[4].item }, "the four items in order")
end
