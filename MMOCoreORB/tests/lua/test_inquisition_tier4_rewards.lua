-- Ja'ce Yiaso: the four mission rewards (10000 credits, a ship component, +150 Imperial standing) are paid once, where J pays.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-9, AC-5; invariants I-5, I-9, I-12; finding 3; D-5; Conversation flow 3; Appendix A and D).
--
-- The amounts are J's (naboo_imperial_tier4.java:288-319). Missions 2 and 3 pay on display of the reward gate screen (J:6620, 6672); missions 1 and 4
-- pay on the reply screens (5 and 3 pay screens); leaving before the pay screen leaves the mission unpaid and the next talk opens the reward again.
-- Credits are the bank credits of the fake pilot, items the giveItem calls on its inventory, standing the ghost's Imperial standing.

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local function setUp()
	H.reset()
	J4.requireConversation(lu)
end

local function items(player) return J4.items(player) end

local function standing(player) return player.ghost.factionStanding.imperial end

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

-- The pilot of mission n: n won and unpaid, the earlier missions paid with their skills
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

	return J4.pilot(o)
end

-- the pay paths of Appendix D: n -> list of { grant, from, replies }
local PAY = { {}, {}, {}, {} }

for _, p in ipairs(J4.PATHS) do
	if p.kind:match("^pay") then
		local n = tonumber(p.kind:match("(%d)$"))

		PAY[n][#PAY[n] + 1] = p
	end
end

TestInquisitionT4Rewards = {}

TestInquisitionT4Rewards.setUp = setUp

for n = 1, 4 do
	local stem = J4.MISSIONS[n].status
	local reward = J4.MISSIONS[n].reward

	for _, p in ipairs(PAY[n]) do
		for _, sp in ipairs(SPECIES) do
			-- AC-9, I-5: the pay path pays credits, the item (any species) and standing, on the pay screen
			TestInquisitionT4Rewards["test_mission_" .. n .. "_pay_path_to_" .. p.grant .. "_pays_to_a_" .. sp.name] = function()
				local player = pilot(n, sp.id)

				J4.drive(player, p.from, p.replies)
				lu.assertEquals(player.bankCredits, J4.CREDITS, p.grant .. ": bank credits")
				lu.assertEquals(#player.bankCreditLog, 1, p.grant .. ": addBankCredits calls")
				lu.assertEquals(items(player), { J4.ITEMS[n] }, p.grant .. " (" .. sp.name .. "): giveItem templates")
				lu.assertEquals(standing(player), J4.STANDING, p.grant .. ": Imperial standing")
				lu.assertEquals(H.getQuestStatus(player, stem .. ":reward"), "1", p.grant .. ": the :reward key")
			end
		end

		-- AC-9: nothing is paid before the pay screen
		if #p.replies > 0 then
			TestInquisitionT4Rewards["test_mission_" .. n .. "_pay_path_to_" .. p.grant .. "_pays_nothing_before_the_pay_screen"] = function()
				local player = pilot(n, SPECIES_HUMAN)
				local replies = {}

				for i = 1, #p.replies - 1 do
					replies[i] = p.replies[i]
				end

				local t = J4.drive(player, p.from, replies)

				lu.assertNotEquals(t[#t].id, p.grant, "the shorter path stops before the pay screen")
				lu.assertEquals(player.bankCredits, 0, "bank credits before the pay screen")
				lu.assertEquals(#items(player), 0, "items before the pay screen")
				lu.assertEquals(standing(player), 0, "standing before the pay screen")
				lu.assertNil(H.getQuestStatus(player, stem .. ":reward"), "no :reward key before the pay screen")
			end
		end

		-- AC-9, I-9: the pay screen shown again pays nothing more
		TestInquisitionT4Rewards["test_mission_" .. n .. "_" .. p.grant .. "_shown_three_times_pays_once"] = function()
			local player = pilot(n, SPECIES_HUMAN)

			for _ = 1, 3 do
				J4.drive(player, p.grant)
			end

			lu.assertEquals(player.bankCredits, J4.CREDITS, p.grant .. ": bank credits after three visits")
			lu.assertEquals(#items(player), 1, p.grant .. ": items after three visits")
			lu.assertEquals(standing(player), J4.STANDING, p.grant .. ": standing after three visits")
		end

		-- AC-9: the pay path through the whole talk: the first screen is the reward screen, the walk ends on the pay screen
		if #p.replies > 0 then
			TestInquisitionT4Rewards["test_mission_" .. n .. "_whole_talk_to_" .. p.grant .. "_opens_the_reward_and_pays_at_the_end"] = function()
				local player = pilot(n, SPECIES_HUMAN)
				local t = J4.talk(player, p.replies)

				lu.assertEquals(t[1].id, reward, "the first screen")
				lu.assertEquals(t[#t].id, p.grant, "the last screen")
				lu.assertEquals(player.bankCredits, J4.CREDITS, "paid once")
				lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			end
		end
	end

	-- AC-9: a mission that was paid before pays nothing
	TestInquisitionT4Rewards["test_mission_" .. n .. "_pays_nothing_when_the_reward_key_is_set"] = function()
		local player = pilot(n, SPECIES_HUMAN)

		H.setQuestStatus(player, stem .. ":reward", 1)

		for _, p in ipairs(PAY[n]) do
			J4.drive(player, p.grant)
		end

		J4.drive(player, reward)
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#items(player), 0, "items")
		lu.assertEquals(standing(player), 0, "standing")
	end

end

-- AC-9, D-5: missions 2 and 3 pay on display of the reward gate screen
function TestInquisitionT4Rewards:test_missions_2_and_3_pay_when_the_reward_screen_is_displayed()
	for _, n in ipairs({ 2, 3 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)
		local t = J4.talk(player)

		lu.assertEquals(J4.ids(t), { "m" .. n .. "_reward" }, "mission " .. n .. ": first screen")
		lu.assertEquals(player.bankCredits, J4.CREDITS, "mission " .. n .. ": paid on display")
		lu.assertEquals(items(player), { J4.ITEMS[n] }, "mission " .. n .. ": the item")
		lu.assertEquals(standing(player), J4.STANDING, "mission " .. n .. ": standing")

		local again = J4.talk(player)

		lu.assertNotEquals(again[1].id, "m" .. n .. "_reward", "mission " .. n .. ": the next talk does not show the reward again")
		lu.assertEquals(player.bankCredits, J4.CREDITS, "mission " .. n .. ": bank credits after the second talk")
		lu.assertEquals(#items(player), 1, "mission " .. n .. ": items after the second talk")
	end
end

-- AC-9, D-5, finding 3: missions 1 and 4 pay nothing on display of the reward screen
function TestInquisitionT4Rewards:test_missions_1_and_4_pay_nothing_on_display_of_the_reward_screen()
	for _, n in ipairs({ 1, 4 }) do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)
		local t = J4.talk(player)

		lu.assertEquals(J4.ids(t), { "m" .. n .. "_reward" }, "mission " .. n .. ": first screen")
		lu.assertEquals(player.bankCredits, 0, "mission " .. n .. ": nothing paid on display")
		lu.assertEquals(#items(player), 0, "mission " .. n .. ": no item")
		lu.assertNil(H.getQuestStatus(player, J4.MISSIONS[n].status .. ":reward"), "mission " .. n .. ": no :reward key")
	end
end

-- AC-9: leaving before the pay screen leaves the mission unpaid and the next talk opens the reward again
function TestInquisitionT4Rewards:test_leaving_before_the_pay_screen_leaves_the_mission_unpaid_and_the_next_talk_opens_the_reward_again()
	-- mission 1: one reply into the dialogue (no pay screen yet), then the pilot walks away
	local player = pilot(1, SPECIES_HUMAN)
	local t = J4.talk(player, { PAY[1][1].replies[1] })

	lu.assertEquals(#t, 2, "mission 1: one reply, one more screen")
	lu.assertEquals(t[2].id, "m1_reward_crystals", "mission 1: the screen after the first reply")
	lu.assertEquals(player.bankCredits, 0, "mission 1: unpaid")
	lu.assertEquals(J4.firstScreen(player), "m1_reward", "mission 1: the next talk opens the reward again")
	lu.assertEquals(player.bankCredits, 0, "mission 1: still unpaid")

	-- mission 4: the pilot leaves at the reward screen
	H.reset()

	local p4 = pilot(4, SPECIES_HUMAN)

	lu.assertEquals(J4.ids(J4.talk(p4)), { "m4_reward" }, "mission 4: the reward screen")
	lu.assertEquals(p4.bankCredits, 0, "mission 4: unpaid")
	lu.assertEquals(J4.firstScreen(p4), "m4_reward", "mission 4: the next talk opens the reward again")
end

-- AC-9, I-5: the four rewards add up and each pays once
function TestInquisitionT4Rewards:test_the_four_rewards_add_up_and_each_pays_once()
	local player = J4.pilot({ met = true, mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

	for _ = 1, 2 do
		for _, n in ipairs({ 1, 2, 3, 4 }) do
			J4.drive(player, PAY[n][1].grant)
		end
	end

	lu.assertEquals(player.bankCredits, 4 * J4.CREDITS, "bank credits")
	lu.assertEquals(items(player), { J4.ITEMS[1], J4.ITEMS[2], J4.ITEMS[3], J4.ITEMS[4] }, "items in mission order")
	lu.assertEquals(standing(player), 4 * J4.STANDING, "standing")
end

-- AC-9: the reward is paid through the mission head's reward call (credits and item come from the head table)
function TestInquisitionT4Rewards:test_each_reward_is_the_head_tables_reward_player()
	for n = 1, 4 do
		H.reset()

		local head = J4.MISSIONS[n].head
		local spy = H.spyOn(J4.quest(head), "rewardPlayer")

		J4.drive(pilot(n, SPECIES_HUMAN), PAY[n][1].grant)
		lu.assertEquals(#spy, 1, head .. ": rewardPlayer calls")
	end
end

-- AC-9: the reward items use the overload, so a full inventory still receives them
function TestInquisitionT4Rewards:test_a_full_inventory_still_receives_every_reward_item()
	for n = 1, 4 do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN, { inventory = { limit = 0 } })

		J4.drive(player, PAY[n][1].grant)
		lu.assertEquals(#player.inventory.items, 1, "mission " .. n .. ": the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "mission " .. n .. ": nothing is destroyed")

		local calls = H.Engine.callsTo("giveItem")

		lu.assertEquals(#calls, 1, "mission " .. n .. ": giveItem calls")
		lu.assertIs(calls[1][4], true, "mission " .. n .. ": the overload flag")
	end
end

-- AC-9, I-5: every other screen pays nothing (the briefs, grants, failures, intro, training and hand-off screens)
function TestInquisitionT4Rewards:test_no_other_screen_pays()
	for _, row in ipairs(J4.SCREENS) do
		if J4.PAYS[row.id] == nil and row.id ~= "m2_reward" and row.id ~= "m3_reward" then
			H.reset()
			J4.spyStarts()

			local player = J4.pilot({ met = true, mission = { [1] = "won", [2] = "won", [3] = "won", [4] = "won" } })

			J4.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, row.id .. ": bank credits")
			lu.assertEquals(#items(player), 0, row.id .. ": items")
			lu.assertEquals(standing(player), 0, row.id .. ": standing")
		end
	end
end

-- AC-9, D-5: the reward comes before the graduation screens: all skills held, mission 4 won and unpaid, the first screen is the reward
function TestInquisitionT4Rewards:test_the_fourth_reward_comes_before_the_transfer_and_the_duty_menu()
	local player = J4.pilot({ t4 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" }, met = true })

	lu.assertEquals(J4.firstScreen(player), "m4_reward", "the first screen")
	lu.assertEquals(player.bankCredits, 0, "nothing paid until a pay screen")
	J4.drive(player, "m4_reward_finished")
	lu.assertEquals(items(player), { J4.ITEMS[4] }, "the reactor")
	lu.assertEquals(J4.firstScreen(player), "transfer", "after the payment the graduate gets the transfer")
end

-- AC-9: paying mission n sets only its own reward key
function TestInquisitionT4Rewards:test_paying_one_mission_sets_only_its_own_reward_key()
	for n = 1, 4 do
		H.reset()

		local player = pilot(n, SPECIES_HUMAN)

		J4.drive(player, PAY[n][1].grant)

		for m = 1, 4 do
			local want = (m < n or m == n) and "1" or nil

			lu.assertEquals(H.getQuestStatus(player, J4.MISSIONS[m].status .. ":reward"), want, "mission " .. n .. " paid: the :reward key of mission " .. m)
		end
	end
end
