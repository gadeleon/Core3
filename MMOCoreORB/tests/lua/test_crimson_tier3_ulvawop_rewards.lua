-- Arnecio Ulvaw'op: the four mission rewards (25000 credits, a ship component, +100 Rebel standing) are paid once, on display of the reward screen.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-6; invariant I-4; Source inventory 3; Conversation flow 3 (table H); FU-5; D-4; JU:240-271).
--
-- The amounts are JU's rewardForQuestN (fixtures/script/conversation/tatooine_rebel_tier3.java:240-271). The oracle tests derive the expected credits, items and standing
-- from that fixture and compare them with the four head tables of Part A (PA D-6); every payment test compares against the derived values.
-- Credits are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Rebel standing.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local CS = require("harness.client_strings")

T.loadConversation()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- JU: for each rewardForQuestN function: type, name, credits, item, standing. Returned by mission number.
local function juRewards()
	local java = readFile(H.FIXTURES .. T.JAVA)
	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("tatooine_rebel_tier3_action_rewardForQuest(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
		local questType, questName, credits, item = body:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_REBEL, ([%d%.]+)f%)")
		local guard = body:match('!space_quest%.hasReceivedReward%(player, "([^"]+)", "([^"]+)"%)')

		out[words[word]] = { type = questType, name = questName, credits = tonumber(credits), item = item, standing = tonumber(standing), guarded = guard ~= nil }
	end

	return out
end

local JU = juRewards()

TestUlvawopRewardsOracle = {}

function TestUlvawopRewardsOracle:setUp()
	H.reset()
	T.load()
end

-- AC-6 (the oracle itself): JU pays 25000 credits, its own ship component and +100 Rebel standing per mission, guarded by hasReceivedReward
function TestUlvawopRewardsOracle:test_the_ju_reward_actions_are_25000_credits_the_listed_component_and_100_standing()
	for n = 1, 4 do
		local r = JU[n]

		lu.assertNotNil(r, "JU rewardForQuest" .. n)
		lu.assertEquals(r.credits, T.CREDITS, "JU mission " .. n .. ": credits")
		lu.assertEquals(r.item, T.ITEM_ROOT .. T.ITEMS[n], "JU mission " .. n .. ": item")
		lu.assertEquals(r.standing, T.STANDING + 0.0, "JU mission " .. n .. ": Rebel standing")
		lu.assertTrue(r.guarded, "JU mission " .. n .. ": guarded by hasReceivedReward")
		lu.assertEquals(r.type .. "_" .. r.name, T.HEADS[n], "JU mission " .. n .. ": the quest it pays is the head of the chain")
	end
end

-- AC-6 (Part A, PA D-6): the four head tables carry JU's credits and item, so paying through the head pays what JU pays
function TestUlvawopRewardsOracle:test_the_head_tables_carry_the_ju_credits_and_items()
	for n = 1, 4 do
		local head = T.quest(T.HEADS[n])

		lu.assertEquals(head.creditReward, JU[n].credits, T.HEADS[n] .. ": creditReward")
		lu.assertEquals(head.itemReward[1].item, JU[n].item, T.HEADS[n] .. ": itemReward")
	end
end

TestUlvawopRewards = {}

TestUlvawopRewards.setUp = setUp

for n, m in ipairs(T.MISSIONS) do
	-- AC-6, I-4: the reward screen pays credits, the item and standing, once; it is the first screen
	TestUlvawopRewards["test_" .. m.reward .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
		local player = T.rewardPilot(n)
		local t = T.talk(player)

		lu.assertEquals(t[1].id, m.reward, "first screen")
		lu.assertEquals(player.bankCredits, JU[n].credits, m.reward .. ": bank credits (JU)")
		lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
		lu.assertEquals(T.items(player), { JU[n].item }, m.reward .. ": giveItem templates (JU)")
		lu.assertEquals(T.standing(player), JU[n].standing, m.reward .. ": Rebel standing (JU)")
		lu.assertEquals(T.paid(player, n), "1", m.reward .. ": the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-6, I-4: the same screen shown again before a skill is chosen pays nothing
	TestUlvawopRewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = T.rewardPilot(n)

		for visit = 1, 3 do
			local t = T.talk(player)

			lu.assertEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen shows again until a skill is chosen")
		end

		lu.assertEquals(player.bankCredits, JU[n].credits, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#T.items(player), 1, m.reward .. ": items after three visits")
		lu.assertEquals(T.standing(player), JU[n].standing, m.reward .. ": standing after three visits")
	end

	-- AC-6: a mission that was paid before pays nothing
	TestUlvawopRewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = T.rewardPilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		T.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#T.items(player), 0, m.reward .. ": items")
		lu.assertEquals(T.standing(player), 0, m.reward .. ": standing")
	end

	-- AC-6: the reward item is paid to any species
	TestUlvawopRewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = T.rewardPilot(n, { species = SPECIES_WOOKIEE })

		T.drive(player, m.reward)
		lu.assertEquals(T.items(player), { JU[n].item }, "giveItem templates for a Wookiee")
	end

	-- AC-6: the reward item uses the overload, so a full inventory still receives it
	TestUlvawopRewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = T.rewardPilot(n, { inventory = { limit = 0 } })

		T.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- AC-6: the payment is the mission's own
	TestUlvawopRewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = T.rewardPilot(n)
		local before = {}

		for other = 1, 4 do
			before[other] = T.paid(player, other)
		end

		T.drive(player, m.reward)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(T.paid(player, other), before[other], "mission " .. other .. " :reward is unchanged")
			end
		end
	end

	-- AC-6: the decline reaches on_mission, which ends; the pilot was paid once and granted nothing
	TestUlvawopRewards["test_declining_the_training_on_" .. m.reward .. "_reaches_on_mission_after_one_payment_and_grants_nothing"] = function()
		local player = T.rewardPilot(n)
		local t = T.talk(player, { T.DECLINE_REPLY })

		lu.assertEquals(T.ids(t), { m.reward, "on_mission" }, "screens shown")
		lu.assertTrue(t[2].stop, "on_mission ends")
		lu.assertEquals(#t[2].options, 0, "on_mission offers no reply")
		lu.assertEquals(t[2].text, T.PREFIX .. "s_329414b2", "the decline's target line (D-6)")
		lu.assertEquals(player.bankCredits, JU[n].credits, "paid once")
		lu.assertEquals(#T.free() + #T.bought(), 0, "no skill granted by the decline")
		lu.assertEquals(#T.held3(player), n - 1, "the tier 3 skills held are unchanged")

		-- the next talk shows the same reward screen and pays nothing (R-4)
		local again = T.talk(player)

		lu.assertEquals(again[1].id, m.reward, "the next talk reopens the reward screen")
		lu.assertEquals(player.bankCredits, JU[n].credits, "no second payment")
		lu.assertEquals(#T.items(player), 1, "no second item")
		lu.assertEquals(T.standing(player), JU[n].standing, "no second standing gain")
	end
end

-- AC-6, I-4: only the four reward screens pay (JU pays on the reward lines themselves)
function TestUlvawopRewards:test_no_other_screen_pays()
	for _, row in ipairs(T.SCREENS) do
		if T.REWARD_SCREENS[row.id] == nil then
			H.reset()

			local player = T.pilot({ missions = 2, t3 = 2 })

			T.spyStarts()

			local keys = { T.paid(player, 3), T.paid(player, 4) }

			T.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
			lu.assertEquals(#T.items(player), 0, row.id .. ": items")
			lu.assertEquals(T.standing(player), 0, row.id .. ": standing")
			lu.assertEquals({ T.paid(player, 3), T.paid(player, 4) }, keys, row.id .. ": no :reward key")
		end
	end
end

-- AC-6: the debrief walk from the reward screen to a trained screen pays once
function TestUlvawopRewards:test_a_pilot_who_picks_a_topic_was_paid_exactly_once()
	for n = 1, 4 do
		H.reset()

		local player = T.rewardPilot(n)
		local t = T.talk(player, { T.TRAIN[n].reply })

		lu.assertEquals(T.ids(t), { "m" .. n .. "_reward", T.TRAIN[n].trained }, "mission " .. n .. ": screens shown")
		lu.assertEquals(player.bankCredits, JU[n].credits, "bank credits")
		lu.assertEquals(T.items(player), { JU[n].item }, "giveItem templates")
		lu.assertEquals(T.standing(player), JU[n].standing, "Rebel standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end
end

-- AC-6, AC-8, FU-6: mission 4 won and unpaid with all four skills held still shows m4_reward, pays once, offers only the decline, and the hand-off waits until it is paid
function TestUlvawopRewards:test_mission_4_with_four_skills_and_the_reward_unpaid_shows_m4_reward_and_pays_once()
	local player = T.pilot({ missions = 3, t3 = 4, state = "won" })
	local t = T.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, JU[4].credits, "bank credits")
	lu.assertEquals(T.items(player), { JU[4].item }, "the reactor")
	lu.assertEquals(T.optionSids(t[1]), { T.DECLINE_REPLY }, "no topic is left to choose: only the decline")
	lu.assertEquals(T.linksOf(t[1]), { "on_mission" }, "the decline links to on_mission")
	lu.assertEquals(T.talk(player)[1].id, "handoff", "paid now, all four skills: the hand-off")
	lu.assertEquals(player.bankCredits, JU[4].credits, "bank credits after the second visit")
	lu.assertEquals(#T.items(player), 1, "items after the second visit")
end

-- AC-6: a reward screen grants no skill on display
function TestUlvawopRewards:test_a_reward_screen_grants_no_skill_on_display()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local player = T.rewardPilot(n)

		T.drive(player, m.reward)
		lu.assertEquals(#T.free() + #T.bought(), 0, m.reward .. ": no skill")
		lu.assertEquals(#T.held3(player), n - 1, m.reward .. ": the tier 3 skills held are unchanged")
	end
end

-- AC-6: m1_reward is not a name screen (its line carries no %TU); none of the reward screens sets a parameter
function TestUlvawopRewards:test_the_reward_screens_carry_no_name_parameter()
	for n = 1, 4 do
		H.reset()

		local t = T.talk(T.rewardPilot(n))

		lu.assertNil(t[1].params.TU, "m" .. n .. "_reward: no text parameter")
	end
end

-- AC-6: the reward lines are JU's (JU:8332, 8362, 8392, 8423)
function TestUlvawopRewards:test_the_reward_lines_are_the_ju_lines()
	local want = { "s_8bd6bf55", "s_fa6e2383", "s_f72b6d44", "s_f9044504" }

	for n = 1, 4 do
		H.reset()
		lu.assertEquals(T.talk(T.rewardPilot(n))[1].text, T.PREFIX .. want[n], "mission " .. n .. ": the reward line")
	end
end

-- AC-6: pay once across the whole career, four missions (the sum, not just each screen)
function TestUlvawopRewards:test_four_missions_pay_four_times_and_no_more()
	local player = T.pilot({})

	for n = 1, 4 do
		for _, global in ipairs(T.CHAINS[n]) do
			T.setState(player, global, "complete")
		end

		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")
		T.talk(player, { T.TRAIN[n].reply })
		T.talk(player)
	end

	lu.assertEquals(player.bankCredits, 4 * T.CREDITS, "four rewards paid once each")
	lu.assertEquals(T.standing(player), 4 * T.STANDING, "four times +100 standing")
	lu.assertEquals(#T.items(player), 4, "four ship components")
	lu.assertEquals(T.items(player), { JU[1].item, JU[2].item, JU[3].item, JU[4].item }, "the four items in order")
end
