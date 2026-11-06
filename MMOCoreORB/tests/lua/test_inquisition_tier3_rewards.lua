-- Inquisitor Vrke: the four mission rewards (25000 credits, a ship component, +100 Imperial standing) are paid once, on display of the reward screen.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-8; invariant I-11; Conversation flow 3 (table H) and 4; D-10; J3:239-270).
--
-- The amounts are J3's (naboo_imperial_tier3.java:239-270, checked against the fixture in test_inquisition_tier3_data.lua). Credits are the bank
-- credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

V.load()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

local function standing(player) return player.ghost.factionStanding.imperial end

-- Mission n won and unpaid, the missions before it paid with their skills chosen (count n - 1), Barlow done
local function pilot(n, extra)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid, mission = { [n] = "won" }, spoke = n >= 2 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return V.pilot(o)
end

-- The reply path from the reward screen to the first training screen (breadth first over Appendix A)
local function walkToTraining(n)
	local start = V.MISSIONS[n].reward
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local id = table.remove(queue, 1)

		if V.TRAINING_SCREENS[id] then
			return found[id].replies, found[id].ids
		end

		for _, o in ipairs(V.screenRow(id).options) do
			if found[o[2]] == nil then
				local ids, replies = { table.unpack(found[id].ids) }, { table.unpack(found[id].replies) }

				ids[#ids + 1] = o[2]
				replies[#replies + 1] = o[1]
				found[o[2]] = { ids = ids, replies = replies }
				queue[#queue + 1] = o[2]
			end
		end
	end

	error("no walk from " .. start .. " to a training screen")
end

TestInquisitionT3Rewards = {}

TestInquisitionT3Rewards.setUp = setUp

for n, m in ipairs(V.MISSIONS) do
	-- AC-8, I-11: the reward screen pays credits, the item and standing, once; it is the first screen
	TestInquisitionT3Rewards["test_" .. m.reward .. "_is_the_first_screen_and_pays_mission_" .. n] = function()
		local player = pilot(n)
		local t = V.talk(player)

		lu.assertEquals(t[1].id, m.reward, "first screen")
		lu.assertEquals(player.bankCredits, V.CREDITS, m.reward .. ": bank credits")
		lu.assertEquals(#player.bankCreditLog, 1, m.reward .. ": addBankCredits calls")
		lu.assertEquals(V.items(player), { V.ITEMS[n] }, m.reward .. ": giveItem templates")
		lu.assertEquals(standing(player), V.STANDING, m.reward .. ": Imperial standing (+100)")
		lu.assertEquals(H.getQuestStatus(player, m.status .. ":reward"), "1", m.reward .. ": the :reward key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8, I-11: the same screen shown again before a skill is chosen pays nothing
	TestInquisitionT3Rewards["test_" .. m.reward .. "_shown_three_times_pays_once"] = function()
		local player = pilot(n)

		for visit = 1, 3 do
			local t = V.talk(player)

			lu.assertEquals(t[1].id, m.reward, "visit " .. visit .. ": the reward screen shows again until a skill is chosen")
		end

		lu.assertEquals(player.bankCredits, V.CREDITS, m.reward .. ": bank credits after three visits")
		lu.assertEquals(#V.items(player), 1, m.reward .. ": items after three visits")
		lu.assertEquals(standing(player), V.STANDING, m.reward .. ": standing after three visits")
	end

	-- AC-8: a mission that was paid before pays nothing
	TestInquisitionT3Rewards["test_" .. m.reward .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(n)

		H.setQuestStatus(player, m.status .. ":reward", 1)
		V.drive(player, m.reward)
		lu.assertEquals(player.bankCredits, 0, m.reward .. ": bank credits")
		lu.assertEquals(#V.items(player), 0, m.reward .. ": items")
		lu.assertEquals(standing(player), 0, m.reward .. ": standing")
	end

	-- AC-8: the reward item is paid to any species
	TestInquisitionT3Rewards["test_mission_" .. n .. "_pays_the_same_item_to_a_wookiee"] = function()
		local player = pilot(n, { species = SPECIES_WOOKIEE })

		V.drive(player, m.reward)
		lu.assertEquals(V.items(player), { V.ITEMS[n] }, "giveItem templates for a Wookiee")
	end

	-- AC-8: the reward item uses the overload, so a full inventory still receives it
	TestInquisitionT3Rewards["test_mission_" .. n .. "_item_reaches_a_full_inventory"] = function()
		local player = pilot(n, { inventory = { limit = 0 } })

		V.drive(player, m.reward)
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end

	-- AC-8: the debrief walk from the reward screen reaches the training screen and pays once
	TestInquisitionT3Rewards["test_the_mission_" .. n .. "_debrief_walk_reaches_a_training_screen_and_pays_once"] = function()
		local replies, ids = walkToTraining(n)
		local player = pilot(n)
		local t = V.talk(player, replies)

		lu.assertEquals(V.ids(t), ids, "screens shown")
		lu.assertTrue(V.TRAINING_SCREENS[t[#t].id] == n, "the walk ends on a mission " .. n .. " training screen (" .. t[#t].id .. ")")
		lu.assertEquals(player.bankCredits, V.CREDITS, "bank credits")
		lu.assertEquals(V.items(player), { V.ITEMS[n] }, "giveItem templates")
		lu.assertEquals(standing(player), V.STANDING, "Imperial standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript")
	end

	-- AC-8, I-11: only the reward screen pays; the other screens of the debrief do not
	TestInquisitionT3Rewards["test_no_other_screen_of_the_mission_" .. n .. "_debrief_pays"] = function()
		local _, ids = walkToTraining(n)

		for _, id in ipairs(ids) do
			if id ~= m.reward then
				H.reset()

				local player = pilot(n)

				V.drive(player, id)
				lu.assertEquals(player.bankCredits, 0, id .. ": bank credits")
				lu.assertEquals(#V.items(player), 0, id .. ": items")
				lu.assertEquals(standing(player), 0, id .. ": standing")
				lu.assertNil(H.getQuestStatus(player, m.status .. ":reward"), id .. ": no :reward key")
			end
		end
	end

	-- AC-8: the payment is the mission's own
	TestInquisitionT3Rewards["test_the_mission_" .. n .. "_reward_changes_only_its_own_reward_key"] = function()
		local player = pilot(n)
		local before = {}

		for other = 1, 4 do
			before[other] = H.getQuestStatus(player, V.MISSIONS[other].status .. ":reward")
		end

		V.drive(player, m.reward)

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(H.getQuestStatus(player, V.MISSIONS[other].status .. ":reward"), before[other], "mission " .. other .. " :reward is unchanged")
			end
		end
	end
end

-- AC-8, V15: mission 4 won and unpaid with all four skills held still shows m4_reward, pays once, and the tour is not complete until it is paid
function TestInquisitionT3Rewards:test_mission_4_with_four_skills_and_the_reward_unpaid_shows_m4_reward_and_pays_once()
	local player = V.pilot({ paid = { 1, 2, 3 }, t3 = { 1, 2, 3, 4 }, mission = { [4] = "won" }, spoke = true })
	local t = V.talk(player)

	lu.assertEquals(t[1].id, "m4_reward", "first screen")
	lu.assertEquals(player.bankCredits, V.CREDITS, "bank credits")
	lu.assertEquals(V.items(player), { V.ITEMS[4] }, "the megadrive")
	lu.assertEquals(V.talk(player)[1].id, "tour_complete", "paid now, all four skills: the tour is complete")
	lu.assertEquals(player.bankCredits, V.CREDITS, "bank credits after the second visit")
	lu.assertEquals(#V.items(player), 1, "items after the second visit")
end

-- AC-8: the Barlow keys and the skills are untouched by a payment
function TestInquisitionT3Rewards:test_a_reward_screen_grants_no_skill_and_sets_no_barlow_key()
	for n, m in ipairs(V.MISSIONS) do
		H.reset()

		local player = pilot(n)

		V.drive(player, m.reward)
		lu.assertEquals(#V.free() + #V.bought(), 0, m.reward .. ": no skill")
		lu.assertNil(H.getQuestStatus(player, V.QUESTION_SUFFIX), m.reward .. ": QUESTION_BARLOW_KEY stays unset")
	end
end
