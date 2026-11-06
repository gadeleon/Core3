-- Captain Denner: the four mission rewards (25000 credits, a ship component, +100 Imperial standing) are paid once, on display of the reward screen.
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-5; invariant I-12; Source inventory 3; Conversation flow 3 (table H); D-5, D-9; J3:228-259).
--
-- The amounts are J3's rewardForQuestN (fixtures/script/conversation/tatooine_imperial_tier3.java:228-259); the first test derives the expected credits, items
-- and standing from that fixture, and every payment test compares against the derived values (PA D-A1). Credits are the bank credits of the fake pilot, items
-- the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

-- J3: for each rewardForQuestN function: type, name, credits, item, standing. Returned by mission number.
local function j3Rewards()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_imperial_tier3.java")
	local out = {}
	local words = { One = 1, Two = 2, Three = 3, Four = 4 }

	for word, body in java:gmatch("tatooine_imperial_tier3_action_rewardForQuest(%a+)%(obj_id player, obj_id npc%) throws InterruptedException%s*(%b{})") do
		local questType, questName, credits, item = body:match('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_IMPERIAL, ([%d%.]+)f%)")
		local guard = body:match('!space_quest%.hasReceivedReward%(player, "([^"]+)", "([^"]+)"%)')

		out[words[word]] = { type = questType, name = questName, credits = tonumber(credits), item = item, standing = tonumber(standing), guarded = guard ~= nil }
	end

	return out
end

local J3 = j3Rewards()

local walkToTraining = D.walkToTraining

TestStormT3RewardsOracle = {}

function TestStormT3RewardsOracle:setUp() H.reset() end

-- B-5 (the oracle itself): J3 pays 25000 credits, its own ship component and +100 Imperial standing per mission, guarded by hasReceivedReward
function TestStormT3RewardsOracle:test_the_j3_reward_actions_are_25000_credits_the_listed_component_and_100_standing()
	for n = 1, 4 do
		local r = J3[n]

		lu.assertNotNil(r, "J3 rewardForQuest" .. n)
		lu.assertEquals(r.credits, D.CREDITS, "J3 mission " .. n .. ": credits")
		lu.assertEquals(r.item, D.ITEMS[n], "J3 mission " .. n .. ": item")
		lu.assertEquals(r.standing, D.STANDING + 0.0, "J3 mission " .. n .. ": Imperial standing")
		lu.assertTrue(r.guarded, "J3 mission " .. n .. ": guarded by hasReceivedReward")
		lu.assertEquals(r.type .. "_" .. r.name, D.MISSIONS[n].head, "J3 mission " .. n .. ": the quest it pays is the head of the chain")
	end
end

TestStormT3Rewards = {}

TestStormT3Rewards.setUp = setUp

for n, m in ipairs(D.MISSIONS) do
	-- B-5, I-12: the reward screen pays credits, the item and standing, once; it is the first screen
	TestStormT3Rewards["test_" .. m.reward .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
		local player = D.rewardPilot(n)
		local t = D.talk(player)

		lu.assertEquals(t[1].id, m.reward, "first screen")
		lu.assertEquals(player.bankCredits, J3[n].credits, m.reward .. ": bank credits (J3)")
		lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
		lu.assertEquals(D.items(player), { J3[n].item }, m.reward .. ": giveItem templates (J3)")
		lu.assertEquals(D.standing(player), J3[n].standing, m.reward .. ": Imperial standing (J3)")
		lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", m.reward .. ": the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- B-5, I-12: the same screen shown again before a skill is chosen pays nothing
	TestStormT3Rewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = D.rewardPilot(n)

		for visit = 1, 3 do
			local t = D.talk(player)

			lu.assertEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen shows again until a skill is chosen")
		end

		lu.assertEquals(player.bankCredits, J3[n].credits, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#D.items(player), 1, m.reward .. ": items after three visits")
		lu.assertEquals(D.standing(player), J3[n].standing, m.reward .. ": standing after three visits")
	end

	-- B-5: a mission that was paid before pays nothing
	TestStormT3Rewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = D.rewardPilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		D.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#D.items(player), 0, m.reward .. ": items")
		lu.assertEquals(D.standing(player), 0, m.reward .. ": standing")
	end

	-- B-5: the reward item is paid to any species
	TestStormT3Rewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = D.rewardPilot(n, { species = SPECIES_WOOKIEE })

		D.drive(player, m.reward)
		lu.assertEquals(D.items(player), { J3[n].item }, "giveItem templates for a Wookiee")
	end

	-- B-5: the reward item uses the overload, so a full inventory still receives it
	TestStormT3Rewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = D.rewardPilot(n, { inventory = { limit = 0 } })

		D.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- B-5: the debrief walk from the reward screen reaches a training screen and pays once
	TestStormT3Rewards["test_the_mission_" .. n .. "_debrief_walk_reaches_a_training_screen_and_pays_once"] = function()
		local replies, ids = walkToTraining(n)
		local player = D.rewardPilot(n)
		local t = D.talk(player, replies)

		lu.assertEquals(D.ids(t), ids, "screens shown")
		lu.assertEquals(D.TRAINING_SCREENS[t[#t].id], n, "the walk ends on a mission " .. n .. " training screen (" .. t[#t].id .. ")")
		lu.assertEquals(player.bankCredits, J3[n].credits, "bank credits")
		lu.assertEquals(D.items(player), { J3[n].item }, "giveItem templates")
		lu.assertEquals(D.standing(player), J3[n].standing, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end

	-- B-5, I-12: only the reward screen pays; the other screens of the debrief do not
	TestStormT3Rewards["test_no_other_screen_of_the_mission_" .. n .. "_debrief_pays"] = function()
		local _, ids = walkToTraining(n)

		for _, id in ipairs(ids) do
			if id ~= m.reward then
				H.reset()

				local player = D.rewardPilot(n)

				D.drive(player, id)
				lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
				lu.assertEquals(#D.items(player), 0, id .. ": items")
				lu.assertEquals(D.standing(player), 0, id .. ": standing")
				lu.assertNil(H.getQuestStatus(player, m.status .. ":reward"), id .. ": no :reward key")
			end
		end
	end

	-- B-5: the payment is the mission's own
	TestStormT3Rewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = D.rewardPilot(n)
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
	end
end

-- B-5, B-7, D-5: mission 4 won and unpaid with all four skills held still shows m4_reward, pays once, and the tour is not complete until it is paid
function TestStormT3Rewards:test_mission_4_with_four_skills_and_the_reward_unpaid_shows_m4_reward_and_pays_once()
	local player = D.pilot({ missions = 3, t3 = { 1, 2, 3, 4 }, won = 4 })
	local t = D.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, J3[4].credits, "bank credits")
	lu.assertEquals(D.items(player), { J3[4].item }, "the megadrive")
	lu.assertEquals(D.talk(player)[1].id, "tour_complete", "paid now, all four skills: the tour is complete")
	lu.assertEquals(player.bankCredits, J3[4].credits, "bank credits after the second visit")
	lu.assertEquals(#D.items(player), 1, "items after the second visit")
end

-- B-5: the skills are untouched by a payment
function TestStormT3Rewards:test_a_reward_screen_grants_no_skill()
	for n, m in ipairs(D.MISSIONS) do
		H.reset()

		local player = D.rewardPilot(n)

		D.drive(player, m.reward)
		lu.assertEquals(#D.free() + #D.bought(), 0, m.reward .. ": no skill")
		lu.assertEquals(#D.held3(player), n - 1, m.reward .. ": the tier 3 skills held are unchanged")
	end
end

-- B-5: the %NU of m4_reward is the pilot's first name (the payment screen of the last mission)
function TestStormT3Rewards:test_m4_reward_greets_the_pilot_by_first_name()
	local t = D.talk(D.rewardPilot(4))

	lu.assertEquals(t[1].params.TU, "Ace", "m4_reward: %NU")
end
