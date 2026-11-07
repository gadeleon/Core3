-- Major Eker: the four mission rewards (5000 credits, a ship component, +75 Rebel standing) are paid once; mission 4 also writes EKER_PILOT_KEY "3".
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-6; Conversation flow 3 (table H, REWARD_SCREENS); Data mapping 1; FE-6; D-8; I-4, I-7).
--
-- The amounts are JE's (yavin_rebel_trainer_2.java:398-461: giveRewardMission1..4), proved below against the fixture; the items sit on the Part A head
-- tables and are paid by <head>:rewardPlayer. M1 pays on its won gate screen, M2, M3 and M4 on their reply screens (FE-6).

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function item(n) return E.ITEM_ROOT .. E.ITEMS[n] end

-- the JE reward functions: n -> { type, name, credits, item, standing, flag }
local function swgRewards()
	local text = readFile(H.FIXTURES .. E.JAVA)
	local out = {}

	for n = 1, 4 do
		local from = text:find("action_giveRewardMission" .. n .. "(obj_id player, obj_id npc)", 1, true)
		local body = from and text:sub(from, (text:find("public ", from + 1, true) or #text + 1) - 1)

		lu.assertNotNil(body, "JE: giveRewardMission" .. n)

		local type_, name, credits, template = body:match('space_quest%.giveReward%(player, "([%w_]+)", "([%w_]+)", (%d+), "([^"]+)"%)')
		local standing = body:match("addFactionStanding%(player, factions%.FACTION_REBEL, ([%d%.]+)f%)")
		local flag = body:match('setSpaceFlag%(player, "ekerPilot", (%d+)%)')

		out[n] = { type = type_, name = name, credits = tonumber(credits), item = template, standing = tonumber(standing), flag = flag }
	end

	return out
end

TestEkerRewardData = {}

function TestEkerRewardData:setUp() H.reset() end

-- AC-6: the values of the spec are the values of the SWG script
function TestEkerRewardData:test_the_spec_reward_values_are_the_je_values()
	local rewards = swgRewards()

	for n = 1, 4 do
		lu.assertEquals(rewards[n].type, n == 3 and "destroy_surpriseattack" or E.MISSIONS[n].wonType, "JE giveRewardMission" .. n .. ": quest type")
		lu.assertEquals(rewards[n].name, E.MISSIONS[n].wonName, "JE giveRewardMission" .. n .. ": quest name")
		lu.assertEquals(rewards[n].credits, E.CREDITS, "JE giveRewardMission" .. n .. ": credits")
		lu.assertEquals(rewards[n].item, item(n), "JE giveRewardMission" .. n .. ": item")
		lu.assertEquals(rewards[n].standing, 75.0, "JE giveRewardMission" .. n .. ": Rebel standing")
		lu.assertEquals(rewards[n].flag, n == 4 and "3" or nil, "JE giveRewardMission" .. n .. ": ekerPilot flag")
	end

	local text = readFile(H.FIXTURES .. E.JAVA)

	lu.assertNotNil(text:match('action_makeEkerPilot%(obj_id player, obj_id npc%).-setSpaceFlag%(player, "ekerPilot", 2%)'), "JE makeEkerPilot writes 2")
end

-- AC-6: the Part A head tables carry the same credits and item
function TestEkerRewardData:test_the_head_tables_carry_the_je_reward()
	local rewards = swgRewards()

	for n = 1, 4 do
		local q = E.quest(E.HEADS[n])

		lu.assertEquals(q.creditReward, rewards[n].credits, E.HEADS[n] .. ": creditReward")
		lu.assertEquals(#q.itemReward, 1, E.HEADS[n] .. ": itemReward entries")
		lu.assertEquals(q.itemReward[1].item, rewards[n].item, E.HEADS[n] .. ": itemReward template")
	end
end

TestEkerRewards = {}

TestEkerRewards.setUp = setUp

-- the pilot of mission n: missions before n paid, mission n won and unpaid, the n skills held
local function pilot(n, extra)
	local o = { missions = n - 1, t2 = n, state = "won", graduated = "2" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return E.pilot(o)
end

-- the replies that lead to a pay screen of a mission from its won screen (M2, M3 and M4 pay on the reply)
local REPLY = {
	[2] = { m2_pay_good_work = "s_c48841", m2_pay_come_again = "s_8d66b6a5" },
	[3] = { m3_pay_another_post = "s_faf96c0a", m3_pay_war_not_over = "s_4471d2b" },
	[4] = { m4_pay_right_about_you = "s_ef170270", m4_pay_war_not_over = "s_21bdbf0f" },
}

local function payScreens(n)
	local out = {}

	for screen, mission in pairs(E.REWARD_SCREENS) do
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
		TestEkerRewards["test_" .. screen .. "_pays_mission_" .. n .. "_credits_item_and_standing"] = function()
			local player = pilot(n)
			local t = E.drive(player, screen)

			lu.assertEquals(t[1].id, screen, "the screen")
			lu.assertEquals(player.bankCredits, E.CREDITS, screen .. ": bank credits")
			lu.assertEquals(#player.bankCreditLog, 1, screen .. ": addBankCredits calls")
			lu.assertEquals(E.items(player), { item(n) }, screen .. ": giveItem templates")
			lu.assertEquals(E.standing(player), 75, screen .. ": Rebel standing")
			lu.assertEquals(H.getQuestStatus(player, E.STATUS[n] .. ":reward"), "1", screen .. ": the :reward key")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		-- AC-6: the payment is the head's rewardPlayer, called once with the pilot
		TestEkerRewards["test_" .. screen .. "_pays_through_the_head_rewardPlayer_once"] = function()
			local player = pilot(n)
			local calls = H.spyOn(E.quest(E.HEADS[n]), "rewardPlayer")

			E.drive(player, screen)
			E.drive(player, screen)
			lu.assertEquals(#calls, 1, E.HEADS[n] .. ":rewardPlayer calls after two displays")
			lu.assertEquals(calls[1].args[1], player, "rewardPlayer got the pilot")
		end

		-- AC-6, I-4: shown three times it pays once
		TestEkerRewards["test_" .. screen .. "_shown_three_times_pays_once"] = function()
			local player = pilot(n)

			for _ = 1, 3 do
				E.drive(player, screen)
			end

			lu.assertEquals(player.bankCredits, E.CREDITS, screen .. ": bank credits after three visits")
			lu.assertEquals(#E.items(player), 1, screen .. ": items after three visits")
			lu.assertEquals(E.standing(player), 75, screen .. ": standing after three visits")
		end

		-- AC-6, I-4: a mission paid before pays nothing
		TestEkerRewards["test_" .. screen .. "_pays_nothing_when_the_reward_key_is_set"] = function()
			local player = pilot(n)

			H.setQuestStatus(player, E.STATUS[n] .. ":reward", 1)
			E.drive(player, screen)
			lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
			lu.assertEquals(#E.items(player), 0, screen .. ": items")
			lu.assertEquals(E.standing(player), 0, screen .. ": standing")
		end

		-- AC-6: the standing is added to what the pilot has
		TestEkerRewards["test_" .. screen .. "_adds_75_to_the_standing_the_pilot_has"] = function()
			local player = pilot(n, { standing = 100 })

			E.drive(player, screen)
			lu.assertEquals(E.standing(player), 175, screen .. ": Rebel standing")
		end

		-- AC-6: the other missions' :reward keys stay untouched
		TestEkerRewards["test_" .. screen .. "_sets_only_its_own_reward_key"] = function()
			local player = pilot(n)

			E.drive(player, screen)

			for k = n + 1, 4 do
				lu.assertNil(H.getQuestStatus(player, E.STATUS[k] .. ":reward"), "mission " .. k .. " :reward")
			end
		end
	end

	-- AC-6: the reward item overload still delivers to a full inventory
	TestEkerRewards["test_mission_" .. n .. "_item_lands_in_a_full_inventory"] = function()
		local player = pilot(n, { inventory = { limit = 0 } })

		E.drive(player, payScreens(n)[1])
		lu.assertEquals(#player.inventory.items, 1, "the item lands in the full inventory")
		lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	end
end

-- AC-6: M1 pays on its won gate screen (on display, no reply needed); the first talk after the win pays
function TestEkerRewards:test_the_first_talk_after_winning_mission_1_opens_m1_won_and_pays()
	local player = pilot(1)
	local t = E.talk(player)

	lu.assertEquals(t[1].id, "m1_won", "first screen")
	lu.assertEquals(player.bankCredits, E.CREDITS, "bank credits on the gate screen")
	lu.assertEquals(E.standing(player), 75, "standing")
	lu.assertEquals(H.getQuestStatus(player, E.STATUS[1] .. ":reward"), "1", "the :reward key")
	lu.assertEquals(E.items(player), { item(1) }, "the item")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-6, FE-6: M2, M3 and M4 pay on the reply screens, not on the won gate screen
for _, g in ipairs({ { n = 2, screen = "m2_won" }, { n = 3, screen = "m3_won" }, { n = 4, screen = "m4_won" } }) do
	TestEkerRewards["test_the_first_talk_after_winning_mission_" .. g.n .. "_opens_" .. g.screen .. "_and_pays_nothing_yet"] = function()
		local player = pilot(g.n)
		local t = E.talk(player)

		lu.assertEquals(t[1].id, g.screen, "first screen")
		lu.assertEquals(player.bankCredits, 0, "bank credits on the gate screen")
		lu.assertEquals(E.standing(player), 0, "standing")
		lu.assertNil(H.getQuestStatus(player, E.STATUS[g.n] .. ":reward"), "the :reward key")
		lu.assertEquals(#E.items(player), 0, "items")
		lu.assertEquals(#t[1].options, 2, "the two replies of the won screen")
	end

	-- AC-6: closing the won screen without a reply pays nothing; the next talk shows it again
	TestEkerRewards["test_closing_" .. g.screen .. "_without_a_reply_pays_nothing_and_it_shows_again"] = function()
		local player = pilot(g.n)

		E.talk(player)
		lu.assertEquals(player.bankCredits, 0, "after the first talk")
		lu.assertEquals(E.firstScreen(player), g.screen, "the second talk shows the won screen again")
		lu.assertEquals(player.bankCredits, 0, "after the second talk")
		lu.assertNil(H.getQuestStatus(player, E.STATUS[g.n] .. ":reward"), "the :reward key")
	end

	-- AC-6: each reply pays through the walk
	for screen, reply in pairs(REPLY[g.n]) do
		TestEkerRewards["test_the_reply_to_" .. g.screen .. "_that_leads_to_" .. screen .. "_pays_once"] = function()
			local player = pilot(g.n)
			local t = E.talk(player, { reply })

			lu.assertEquals(E.ids(t), { g.screen, screen }, "the walk")
			lu.assertEquals(player.bankCredits, E.CREDITS, "bank credits")
			lu.assertEquals(E.standing(player), 75, "standing")
			lu.assertEquals(E.items(player), { item(g.n) }, "items")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-6: a paid mission's won screen is not shown again (the gate tests won and unpaid)
function TestEkerRewards:test_a_paid_mission_is_not_shown_as_won_again()
	local player = pilot(2)

	E.drive(player, "m2_pay_good_work")
	lu.assertNotEquals(E.firstScreen(player), "m2_won", "after the payment")
end

-- AC-6, I-4: no other screen pays
function TestEkerRewards:test_no_other_screen_pays()
	for _, row in ipairs(E.SCREENS) do
		if E.REWARD_SCREENS[row.id] == nil then
			H.reset()

			-- every mission won and unpaid, so a stray payment on any screen would show
			local player = E.pilot({ missions = 0, t2 = 4, state = "won", privileged = true, xp = 999999, graduated = "2" })

			for n = 2, 4 do
				for _, global in ipairs(E.CHAINS[n]) do
					E.setState(player, global, "complete")
				end
			end

			E.spyStarts()
			E.drive(player, row.id)
			lu.assertEquals(player.bankCredits, 0, "screen '" .. row.id .. "': bank credits")
			lu.assertEquals(#E.items(player), 0, "screen '" .. row.id .. "': items")
			lu.assertEquals(E.standing(player), 0, "screen '" .. row.id .. "': standing")

			for n = 1, 4 do
				lu.assertNil(H.getQuestStatus(player, E.STATUS[n] .. ":reward"), "screen '" .. row.id .. "': mission " .. n .. " :reward")
			end
		end
	end
end

-- AC-6: the gate decision alone pays nothing (M1 pays when its gate screen is displayed, not when the gate picks it)
function TestEkerRewards:test_the_gate_decision_alone_pays_nothing()
	for n = 1, 4 do
		H.reset()

		local player = pilot(n)
		local pScreen = E.handler():getInitialScreen(player, E.npc(), H.conversationTemplate(E.TEMPLATE))

		lu.assertNotNil(pScreen, "mission " .. n .. ": a screen")
		lu.assertEquals(player.bankCredits, 0, "mission " .. n .. ": getInitialScreen pays nothing")
		lu.assertEquals(E.standing(player), 0, "mission " .. n .. ": standing")
	end
end

---------------------------------------------------------------------------------------------
-- Mission 4 and the flag "3" (I-4, I-7)
---------------------------------------------------------------------------------------------

TestEkerMission4 = {}

TestEkerMission4.setUp = setUp

for _, screen in ipairs({ "m4_pay_right_about_you", "m4_pay_war_not_over" }) do
	-- AC-6, I-7: the M4 payment writes EKER_PILOT_KEY "3" (from "1" or "2")
	TestEkerMission4["test_" .. screen .. "_writes_flag_3"] = function()
		for _, flag in ipairs({ "1", "2" }) do
			H.reset()

			local player = pilot(4, { graduated = flag })

			E.drive(player, screen)
			lu.assertEquals(E.flag(player), "3", screen .. ": the flag after the payment (was " .. flag .. ")")
		end
	end

	-- I-4: "3" is written only inside the pay guard: a paid mission leaves the flag alone
	TestEkerMission4["test_" .. screen .. "_leaves_the_flag_alone_when_the_reward_was_paid_before"] = function()
		local player = pilot(4, { graduated = "2" })

		H.setQuestStatus(player, E.STATUS[4] .. ":reward", 1)
		E.drive(player, screen)
		lu.assertEquals(E.flag(player), "2", screen .. ": the flag of a pilot whose mission 4 was paid")
	end
end

-- AC-6: after the M4 payment the next talk opens the hand-off
function TestEkerMission4:test_the_next_talk_after_the_mission_4_payment_opens_the_hand_off()
	local player = pilot(4)

	E.talk(player, { "s_ef170270" })
	lu.assertEquals(E.flag(player), "3", "the flag")
	lu.assertEquals(E.firstScreen(player), "tier3_handoff", "the next talk")
end

-- I-7: the other pay screens leave the flag alone
function TestEkerMission4:test_the_other_pay_screens_do_not_write_the_flag()
	for _, screen in ipairs({ "m1_won", "m2_pay_good_work", "m2_pay_come_again", "m3_pay_another_post", "m3_pay_war_not_over" }) do
		H.reset()

		local n = E.REWARD_SCREENS[screen]
		local player = pilot(n, { graduated = "2" })

		E.drive(player, screen)
		lu.assertEquals(E.flag(player), "2", screen .. ": the flag")
	end
end

-- AC-6: the M1 won walk pays on display and leads on to the duty list
function TestEkerRewards:test_the_mission_1_won_walk_pays_on_display_and_leads_to_the_duty_menu()
	local player = pilot(1)
	local t = E.talk(player, { "s_837615b6", "s_e39ec30", "s_b54697f" })

	lu.assertEquals(E.ids(t), { "m1_won", "m1_refugee", "m1_duties", "duty_menu" }, "the walk")
	lu.assertEquals(player.bankCredits, E.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-6: the whole run of mission 2: won -> reply pays -> "uniform comes off" exchange ends
function TestEkerRewards:test_the_mission_2_come_again_walk_pays_on_the_reply_and_ends_the_exchange()
	local player = pilot(2)
	local t = E.talk(player, { "s_8d66b6a5", "s_bb847e4c", "s_d757b665" })

	lu.assertEquals(E.ids(t), { "m2_won", "m2_pay_come_again", "m2_uniform", "m2_dismissed" }, "the walk")
	lu.assertTrue(t[4].stop, "m2_dismissed ends")
	lu.assertEquals(player.bankCredits, E.CREDITS, "paid on the reply")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end
