-- Brother Vrovel: the four mission rewards (5000 credits, a ship component, +75 Rebel standing) are paid once; mission 4 also writes VORTEX_PILOT_KEY "3".
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-6; Conversation flow 3 (table H, REWARD_SCREENS); Data mapping 1; FV-6; D-8; I-4, I-7).
--
-- The amounts are J2's (dantooine_rebel_trainer_2.java:365-423: giveRewardMission1..4), proved below against the fixture; the items sit on the Part A
-- head tables and are paid by <head>:rewardPlayer. M1 and M3 pay on the won gate screen, M2 and M4 on their reply screens (FV-6).

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function item(n) return V.ITEM_ROOT .. V.ITEMS[n] end

-- the J2 reward functions: n -> { type, name, credits, item, standing, flag }
local function swgRewards()
	local text = readFile(H.FIXTURES .. "script/conversation/dantooine_rebel_trainer_2.java")
	local out = {}

	for n = 1, 4 do
		local from = text:find("action_giveRewardMission" .. n .. "(obj_id player, obj_id npc)", 1, true)
		local body = from and text:sub(from, (text:find("public void", from + 1, true) or #text + 1) - 1)

		lu.assertNotNil(body, "J2: giveRewardMission" .. n)

		local type_, name, credits, template = body:match('space_quest%.giveReward%(player, "([%w_]+)", "([%w_]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_REBEL, ([%d%.]+)f%)")
		local flag = body:match('setSpaceFlag%(player, "vortexPilot", (%d+)%)')

		out[n] = { type = type_, name = name, credits = tonumber(credits), item = template, standing = tonumber(standing), flag = flag }
	end

	return out
end

TestVrovelRewardData = {}

function TestVrovelRewardData:setUp() H.reset() end

-- AC-6: the values derive from the J2 fixture: 5000 credits, the component, +75 standing; only mission 4 sets the flag (3), the hand-in sets 2
function TestVrovelRewardData:test_the_swg_reward_functions_give_5000_credits_a_component_and_75_standing_and_mission_4_sets_flag_3()
	local rewards = swgRewards()

	for n = 1, 4 do
		lu.assertEquals(rewards[n].type, V.MISSIONS[n].wonType, "J2 giveRewardMission" .. n .. ": quest type")
		lu.assertEquals(rewards[n].name, V.MISSIONS[n].wonName, "J2 giveRewardMission" .. n .. ": quest name")
		lu.assertEquals(rewards[n].credits, V.CREDITS, "J2 giveRewardMission" .. n .. ": credits")
		lu.assertEquals(rewards[n].item, item(n), "J2 giveRewardMission" .. n .. ": item")
		lu.assertEquals(rewards[n].standing, 75.0, "J2 giveRewardMission" .. n .. ": Rebel standing")
		lu.assertEquals(rewards[n].flag, n == 4 and "3" or nil, "J2 giveRewardMission" .. n .. ": vortexPilot flag")
	end

	local text = readFile(H.FIXTURES .. "script/conversation/dantooine_rebel_trainer_2.java")

	lu.assertNotNil(text:match('action_setVortexPilot%(obj_id player, obj_id npc%).-setSpaceFlag%(player, "vortexPilot", 2%)'), "J2 setVortexPilot writes 2")
end

-- AC-6: the Part A head tables carry the same credits and item
function TestVrovelRewardData:test_the_head_tables_carry_the_j2_reward()
	local rewards = swgRewards()

	for n = 1, 4 do
		local q = V.quest(V.HEADS[n])

		lu.assertEquals(q.creditReward, rewards[n].credits, V.HEADS[n] .. ": creditReward")
		lu.assertEquals(#q.itemReward, 1, V.HEADS[n] .. ": itemReward entries")
		lu.assertEquals(q.itemReward[1].item, rewards[n].item, V.HEADS[n] .. ": itemReward template")
	end
end

TestVrovelRewards = {}

TestVrovelRewards.setUp = setUp

-- the pilot of mission n: missions before n paid, mission n won and unpaid, the n skills held
local function pilot(n, extra)
	local o = { missions = n - 1, t2 = n, state = "won" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return V.pilot(o)
end

-- the replies that lead to a pay screen of a mission, from its won screen (M2 and M4 pay on the reply)
local REPLY = { [2] = { m2_pay_rest = "s_fe92f35f", m2_pay_bonus = "s_235bfb27" }, [4] = { m4_pay_close_call = "s_f931eb62", m4_pay_impressed = "s_7363d4a2" } }

local function payScreens(n)
	local out = {}

	for screen, mission in pairs(V.REWARD_SCREENS) do
		if mission == n then
			out[#out + 1] = screen
		end
	end

	table.sort(out)
	return out
end

for n = 1, 4 do
	for _, screen in ipairs(payScreens(n)) do
		-- AC-6, I-4: the pay screen pays credits, the item and the standing, and sets the :reward key
		TestVrovelRewards["test_" .. screen .. "_pays_mission_" .. n .. "_credits_item_and_standing"] = function()
			local player = pilot(n)
			local t = V.drive(player, screen)

			lu.assertEquals(t[1].id, screen, "the screen")
			lu.assertEquals(player.bankCredits, V.CREDITS, screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
			lu.assertEquals(V.items(player), { item(n) }, screen .. ": giveItem templates")
			lu.assertEquals(V.standing(player), 75, screen .. ": Rebel standing")
			lu.assertEquals(H.getQuestStatus(player, V.STATUS[n] .. ":reward"), "1", screen .. ": the :reward key")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		-- AC-6: the payment is the head's rewardPlayer, called once with the pilot
		TestVrovelRewards["test_" .. screen .. "_pays_through_the_head_rewardPlayer_once"] = function()
			local player = pilot(n)
			local calls = H.spyOn(V.quest(V.HEADS[n]), "rewardPlayer")

			V.drive(player, screen)
			V.drive(player, screen)
			lu.assertEquals(#calls, 1, V.HEADS[n] .. ":rewardPlayer calls after two displays")
			lu.assertEquals(calls[1].args[1], player, "rewardPlayer got the pilot")
		end

		-- AC-6, I-4: shown three times it pays once
		TestVrovelRewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(n)

			for _ = 1, 3 do
				V.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, V.CREDITS, screen .. ": bank credits after three visits")
			lu.assertEquals(#V.items(player), 1, screen .. ": items after three visits")
			lu.assertEquals(V.standing(player), 75, screen .. ": standing after three visits")
		end

		-- AC-6, I-4: a mission paid before pays nothing
		TestVrovelRewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(n)

			H.setQuestStatus(player, V.STATUS[n] .. ":reward", 1)
			V.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#V.items(player), 0, screen .. ": items")
			lu.assertEquals(V.standing(player), 0, screen .. ": standing")
		end

		-- AC-6: the standing is added to what the pilot has
		TestVrovelRewards["test_" .. screen .. "_adds_75_to_the_standing_the_pilot_has"] = function()
			local player = pilot(n, { standing = 100 })

			V.drive(player, screen)
			lu.assertEquals(V.standing(player), 175, screen .. ": Rebel standing")
		end

		-- AC-6: the other missions' :reward keys stay untouched
		TestVrovelRewards["test_" .. screen .. "_sets_only_its_own_reward_key"] = function()
			local player = pilot(n)

			V.drive(player, screen)

			for k = n + 1, 4 do
				lu.assertNil(H.getQuestStatus(player, V.STATUS[k] .. ":reward"), "mission " .. k .. " :reward")
			end
		end
	end

	-- AC-6: the reward item overload still delivers to a full inventory
	TestVrovelRewards["test_mission_" .. n .. "_item_lands_in_a_full_inventory"] = function()
		local player = pilot(n, { inventory = { limit = 0 } })

		V.drive(player, payScreens(n)[1])
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end
end

-- AC-6: M1 and M3 pay on their won gate screen (on display, no reply needed); the first talk after the win pays
for _, g in ipairs({ { n = 1, screen = "m1_won" }, { n = 3, screen = "m3_won" } }) do
	TestVrovelRewards["test_the_first_talk_after_winning_mission_" .. g.n .. "_opens_" .. g.screen .. "_and_pays"] = function()
		local player = pilot(g.n)
		local t = V.talk(player)

		lu.assertEquals(t[1].id, g.screen, "first screen")
		lu.assertEquals(player.bankCredits, V.CREDITS, "bank credits on the gate screen")
		lu.assertEquals(V.standing(player), 75, "standing")
		lu.assertEquals(H.getQuestStatus(player, V.STATUS[g.n] .. ":reward"), "1", "the :reward key")
		lu.assertEquals(V.items(player), { item(g.n) }, "the item")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-6, FV-6: M2 and M4 pay on the reply screens, not on the won gate screen
for _, g in ipairs({ { n = 2, screen = "m2_won" }, { n = 4, screen = "m4_won" } }) do
	TestVrovelRewards["test_the_first_talk_after_winning_mission_" .. g.n .. "_opens_" .. g.screen .. "_and_pays_nothing_yet"] = function()
		local player = pilot(g.n)
		local t = V.talk(player)

		lu.assertEquals(t[1].id, g.screen, "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits on the gate screen")
		lu.assertEquals(V.standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, V.STATUS[g.n] .. ":reward"), "the :reward key")
		lu.assertEquals(#V.items(player), 0, "items")
		lu.assertEquals(V.optionSids(t[1]), g.n == 2 and { "s_fe92f35f", "s_235bfb27" } or { "s_f931eb62", "s_7363d4a2" }, "the two replies of the won screen")
	end

	-- AC-6: closing the won screen without a reply pays nothing; the next talk shows it again
	TestVrovelRewards["test_closing_" .. g.screen .. "_without_a_reply_pays_nothing_and_it_shows_again"] = function()
		local player = pilot(g.n)

		V.talk(player)
		lu.assertEquals(player.bankCredits, 0, "after the first talk")
		lu.assertEquals(V.firstScreen(player), g.screen, "the second talk shows the won screen again")
		lu.assertEquals(player.bankCredits, 0, "after the second talk")
	end

	-- AC-6: each reply pays through the walk
	for screen, reply in pairs(REPLY[g.n]) do
		TestVrovelRewards["test_the_reply_to_" .. g.screen .. "_that_leads_to_" .. screen .. "_pays_once"] = function()
			local player = pilot(g.n)
			local t = V.talk(player, { reply })

			lu.assertEquals(V.ids(t), { g.screen, screen }, "the walk")
			lu.assertEquals(player.bankCredits, V.CREDITS, "bank credits")
			lu.assertEquals(V.standing(player), 75, "standing")
			lu.assertEquals(V.items(player), { item(g.n) }, "items")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-6: a paid mission's won screen is not shown again (the gate tests won and unpaid)
function TestVrovelRewards:test_a_paid_mission_is_not_shown_as_won_again()
	local player = pilot(2)

	V.drive(player, "m2_pay_rest")
	lu.assertNotEquals(V.firstScreen(player), "m2_won", "after the payment")
end

-- AC-6, I-4: no other screen pays
function TestVrovelRewards:test_no_other_screen_pays()
	for _, row in ipairs(V.SCREENS) do
		if V.REWARD_SCREENS[row.id] == nil then
			H.reset()

			-- every mission won and unpaid, so a stray payment on any screen would show
			local player = V.pilot({ missions = 0, t2 = 4, state = "won", privileged = true, xp = 999999 })

			for n = 2, 4 do
				for _, global in ipairs(V.CHAINS[n]) do
					V.setState(player, global, "complete")
				end
			end

			V.spyStarts()
			V.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, "screen '" .. row.id .. "': bank credits")
			lu.assertEquals(#V.items(player), 0, "screen '" .. row.id .. "': items")
			lu.assertEquals(V.standing(player), 0, "screen '" .. row.id .. "': standing")

			for n = 1, 4 do
				lu.assertNil(H.getQuestStatus(player, V.STATUS[n] .. ":reward"), "screen '" .. row.id .. "': mission " .. n .. " :reward")
			end
		end
	end
end

-- AC-6: opening the conversation pays nothing for M2 and M4 and only the gate screens' own payment for M1 and M3
function TestVrovelRewards:test_the_gate_decision_alone_pays_nothing()
	for n = 1, 4 do
		H.reset()

		local player = pilot(n)
		local pScreen = V.handler():getInitialScreen(player, V.npc(), H.conversationTemplate(V.TEMPLATE))

		lu.assertNotNil(pScreen, "mission " .. n .. ": a screen")
		lu.assertEquals(player.bankCredits, 0, "mission " .. n .. ": getInitialScreen pays nothing")
		lu.assertEquals(V.standing(player), 0, "mission " .. n .. ": standing")
	end
end

---------------------------------------------------------------------------------------------
-- Mission 4 and the flag "3" (I-4, I-7)
---------------------------------------------------------------------------------------------

TestVrovelMission4 = {}

TestVrovelMission4.setUp = setUp

for _, screen in ipairs({ "m4_pay_close_call", "m4_pay_impressed" }) do
	-- AC-6, I-7: the M4 payment writes VORTEX_PILOT_KEY "3" (from "1" or "2")
	TestVrovelMission4["test_" .. screen .. "_writes_flag_3"] = function()
		for _, flag in ipairs({ "1", "2" }) do
			H.reset()

			local player = pilot(4, { graduated = flag })

			V.drive(player, screen)
			lu.assertEquals(V.flag(player), "3", screen .. ": the flag after the payment (was " .. flag .. ")")
		end
	end

	-- I-4: "3" is written only inside the pay guard: a paid mission leaves the flag alone
	TestVrovelMission4["test_" .. screen .. "_leaves_the_flag_alone_when_the_reward_was_paid_before"] = function()
		local player = pilot(4, { graduated = "2" })

		H.setQuestStatus(player, V.STATUS[4] .. ":reward", 1)
		V.drive(player, screen)
		lu.assertEquals(V.flag(player), "2", screen .. ": the flag of a pilot whose mission 4 was paid")
	end
end

-- AC-6: after the M4 payment the next talk opens the hand-off to Ezkiel
function TestVrovelMission4:test_the_next_talk_after_the_mission_4_payment_opens_the_hand_off()
	local player = pilot(4)

	V.talk(player, { "s_f931eb62" })
	lu.assertEquals(V.flag(player), "3", "the flag")
	lu.assertEquals(V.firstScreen(player), "ezkiel_handoff", "the next talk")
end

-- I-7: the other pay screens leave the flag alone
function TestVrovelMission4:test_the_other_pay_screens_do_not_write_the_flag()
	for _, screen in ipairs({ "m1_won", "m2_pay_rest", "m2_pay_bonus", "m3_won" }) do
		H.reset()

		local n = V.REWARD_SCREENS[screen]
		local player = pilot(n, { graduated = "2" })

		V.drive(player, screen)
		lu.assertEquals(V.flag(player), "2", screen .. ": the flag")
	end
end

-- AC-6: the whole run of M1: won -> paid -> "it was a setup" -> m1_not_yet -> duties
function TestVrovelRewards:test_the_mission_1_won_walk_pays_on_display_and_leads_to_the_duty_menu()
	local player = pilot(1)
	local t = V.talk(player, { "s_266422af", "s_b8b49994", "s_9d33db7" })

	lu.assertEquals(V.ids(t), { "m1_won", "m1_setup", "m1_not_yet", "duty_menu" }, "the walk")
	lu.assertEquals(player.bankCredits, V.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end
