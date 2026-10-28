-- Burke: the Mission 1 grant, the failure retries, the Mission 1 reward and the Mission 2 grant (table H).
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (AC-6, AC-7, AC-8; invariants I-7, I-9; Conversation flow 2 and 3; Appendix D).
--
-- A start screen sets `master_rebel_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (wrapped here, the original runs).
-- The quests' startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local DRS = require("duty_rules_scenario")
local M = require("master_trainer_rebel_data")
local CS = require("harness.client_strings")

M.load()

local function setUp()
	H.reset()
	M.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, M.MISSIONS[n].status .. ":attempted") end
local function reward(player, n) return H.getQuestStatus(player, M.MISSIONS[n].status .. ":reward") end

-- Wraps SpaceHelpers.startSpaceQuestChain: records the head of each call and runs the original. Restored by H.reset()? No: restore in tearDown.
local origChain

local function recordChains()
	local calls = {}

	origChain = origChain or SpaceHelpers.startSpaceQuestChain

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, head)
		calls[#calls + 1] = head

		return origChain(self, pPlayer, pNpc, head)
	end

	return calls
end

local function restoreChains()
	if origChain ~= nil then
		SpaceHelpers.startSpaceQuestChain = origChain
	end
end

-- the pilot whose first screen is `gate`, and the state it needs
local STATE = {
	intro = {},
	m1_failed = { mission = { [1] = "failed" } },
	m1_won = { mission = { [1] = "won" } },
	m2_brief = { paid = { 1 } },
	m2_failed = { paid = { 1 }, mission = { [2] = "failed" } },
	m2_won = { paid = { 1 }, mission = { [2] = "won" } },
}

local function pilotFor(gate, extra)
	local o = {}

	for k, v in pairs(STATE[gate]) do
		o[k] = v
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

-- the last screen of every option path from `gate`, with the number of start calls and heads
local function routes(gate)
	local out = {}

	for _, p in ipairs(M.paths(gate)) do
		out[#out + 1] = p
	end

	return out
end

TestMasterTrainerRebelGrants = {}

TestMasterTrainerRebelGrants.setUp = setUp

function TestMasterTrainerRebelGrants:tearDown() restoreChains() end

-- AC-6, AC-8, AC-9: every action screen of Appendix D is reached by its path, from a pilot whose first screen is the path's start
function TestMasterTrainerRebelGrants:test_each_appendix_d_path_reaches_its_action_screen()
	for _, p in ipairs(M.PATHS) do
		H.reset()
		M.spyStarts()

		local player = pilotFor(p.from)
		local t = M.talk(player, p.replies)
		local ids = M.ids(t)

		lu.assertEquals(ids[1], p.from, p.screen .. ": first screen")
		lu.assertNotNil(table.concat(ids, ","):find(p.screen, 1, true), p.screen .. ": the path " .. table.concat(ids, " > ") .. " reaches the action screen")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, p.screen .. ": client strings")
	end
end

-- AC-6: m1_accept sets the key and starts mission 1 exactly once through startSpaceQuestChain
function TestMasterTrainerRebelGrants:test_m1_accept_sets_the_attempted_key_and_starts_mission_1_once_through_the_chain_helper()
	local calls = recordChains()
	local spies = M.spyStarts()
	local player = M.pilot({})
	local t = M.talk(player, M.PATHS[1].replies)

	lu.assertEquals(M.ids(t)[#t], "m1_accept", "Appendix D's path ends on m1_accept")
	lu.assertEquals(attempted(player, 1), "1", "master_rebel_1:attempted")
	lu.assertNil(attempted(player, 2), "master_rebel_2:attempted stays unset")
	lu.assertEquals(calls, { "destroy_master_rebel_1" }, "startSpaceQuestChain calls")
	lu.assertEquals(M.started(spies), { "destroy_master_rebel_1" }, "startQuest calls")
end

-- AC-6, I-9: every route from intro either declines (nothing happens) or grants mission 1 once and nothing else, whatever the replies
function TestMasterTrainerRebelGrants:test_every_route_from_intro_starts_mission_1_once_or_declines_and_starts_nothing_else_and_pays_nothing()
	local all = routes("intro")

	lu.assertEquals(#all, 9, "intro has nine routes: three openings to the volunteer line, then the decline or two Kessel branches")

	local declines, grants = 0, 0

	for _, p in ipairs(all) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()
		local player = M.pilot({})
		local t = M.talk(player, p.replies)
		local label = "route " .. table.concat(p.ids, " > ")
		local last = p.ids[#p.ids]

		lu.assertEquals(M.ids(t), p.ids, label .. ": screens shown")

		if last == "decline" then
			declines = declines + 1
			lu.assertEquals(calls, {}, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(M.started(spies), {}, label .. ": startQuest calls")
			lu.assertNil(attempted(player, 1), label .. ": :attempted")
		else
			grants = grants + 1
			lu.assertEquals(last, "m1_accept", label .. ": the route ends on the grant screen")
			lu.assertEquals(calls, { "destroy_master_rebel_1" }, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(M.started(spies), { "destroy_master_rebel_1" }, label .. ": startQuest calls")
			lu.assertEquals(attempted(player, 1), "1", label .. ": :attempted")
		end

		lu.assertNil(attempted(player, 2), label .. ": mission 2 untouched")
		lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
		lu.assertEquals(M.standing(player), 0, label .. ": standing")
		lu.assertEquals(#M.itemsGiven(player), 0, label .. ": items")
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, label .. ": skills granted")
		restoreChains()
	end

	lu.assertEquals(declines, 3, "routes that decline")
	lu.assertEquals(grants, 6, "routes that accept")
end

-- AC-6: the decline route starts nothing, sets nothing, and the next talk opens intro again
function TestMasterTrainerRebelGrants:test_declining_starts_nothing_and_the_next_talk_opens_intro()
	local calls = recordChains()
	local spies = M.spyStarts()
	local player = M.pilot({})
	local p = M.PATHS[9]

	lu.assertEquals(p.screen, "decline", "Appendix D: the decline path")

	local t = M.talk(player, p.replies)

	lu.assertEquals(M.ids(t)[#t], "decline", "the route ends on decline")
	lu.assertTrue(t[#t].stop, "decline ends the conversation")
	lu.assertEquals(calls, {}, "startSpaceQuestChain calls")
	lu.assertEquals(M.started(spies), {}, "startQuest calls")
	lu.assertNil(attempted(player, 1), "master_rebel_1:attempted")
	lu.assertNil(attempted(player, 2), "master_rebel_2:attempted")
	lu.assertEquals(M.talk(player)[1].id, "intro", "the next talk")
end

-- AC-6: the intro itself starts nothing and sets nothing
function TestMasterTrainerRebelGrants:test_the_screens_before_the_grant_start_nothing()
	local calls = recordChains()
	local spies = M.spyStarts()
	local player = M.pilot({})

	M.talk(player, { "s_81f189ef", "s_ad709e77", "s_32062da9", "s_85b8ffbd", "s_22d87576", "s_c97cb0b8", "s_6d976791", "s_1fd64638" })
	lu.assertEquals(calls, {}, "startSpaceQuestChain calls before the grant screen")
	lu.assertEquals(M.started(spies), {}, "startQuest calls before the grant screen")
	lu.assertNil(attempted(player, 1), ":attempted before the grant screen")
end

-- AC-6: a real start in a ship
function TestMasterTrainerRebelGrants:test_the_grant_really_starts_mission_1_for_a_pilot_in_a_ship()
	local player = M.pilot({ inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

	M.talk(player, M.PATHS[1].replies)
	H.advance(0)

	lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "active", "mission 1 journal state")
	lu.assertEquals(M.state(player, "destroy_master_rebel_2"), "none", "mission 2 journal state")
end

-- AC-6: showing the grant screen twice does not start twice
function TestMasterTrainerRebelGrants:test_the_grant_screen_shown_twice_starts_mission_1_only_once()
	local player = M.pilot({ inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

	M.talk(player, M.PATHS[1].replies)
	H.advance(0)

	local before = #H.Engine.callsTo("createObserver")

	M.drive(player, "m1_accept")
	H.advance(0)
	lu.assertEquals(#H.Engine.callsTo("createObserver"), before, "no second observer: the running mission is not started again")
	lu.assertEquals(M.state(player, "destroy_master_rebel_1"), "active", "still active")
end

-- AC-7: m1_failed -> either retry restarts mission 1 once
function TestMasterTrainerRebelGrants:test_each_mission_1_retry_restarts_mission_1_once()
	for _, p in ipairs({ M.PATHS[2], M.PATHS[3] }) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()
		local player = pilotFor("m1_failed")
		local t = M.talk(player, p.replies)

		lu.assertEquals(M.ids(t)[1], "m1_failed", p.screen .. ": first screen")
		lu.assertEquals(calls, { "destroy_master_rebel_1" }, p.screen .. ": startSpaceQuestChain calls")
		lu.assertEquals(M.started(spies), { "destroy_master_rebel_1" }, p.screen .. ": startQuest calls")
		lu.assertEquals(attempted(player, 1), "1", p.screen .. ": :attempted")
		restoreChains()
	end
end

-- AC-7: m2_failed -> either retry restarts mission 2 once
function TestMasterTrainerRebelGrants:test_each_mission_2_retry_restarts_mission_2_once()
	for _, p in ipairs({ M.PATHS[6], M.PATHS[7] }) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()
		local player = pilotFor("m2_failed")
		local t = M.talk(player, p.replies)

		lu.assertEquals(M.ids(t)[1], "m2_failed", p.screen .. ": first screen")
		lu.assertEquals(calls, { "destroy_master_rebel_2" }, p.screen .. ": startSpaceQuestChain calls")
		lu.assertEquals(M.started(spies), { "destroy_master_rebel_2" }, p.screen .. ": startQuest calls")
		lu.assertEquals(attempted(player, 2), "1", p.screen .. ": :attempted")
		restoreChains()
	end
end

-- AC-7: every route of the failure dialogues restarts its mission once (RJ offers no quit reply)
function TestMasterTrainerRebelGrants:test_every_failure_route_restarts_its_mission_once()
	for gate, mission in pairs({ m1_failed = 1, m2_failed = 2 }) do
		lu.assertEquals(#routes(gate), 2, gate .. ": two routes")

		for _, p in ipairs(routes(gate)) do
			H.reset()

			local calls = recordChains()
			local spies = M.spyStarts()
			local player = pilotFor(gate)
			local t = M.talk(player, p.replies)
			local label = gate .. " route " .. table.concat(p.ids, " > ")

			lu.assertEquals(M.ids(t), p.ids, label .. ": screens shown")
			lu.assertEquals(calls, { M.MISSIONS[mission].head }, label .. ": startSpaceQuestChain calls")
			lu.assertEquals(M.started(spies), { M.MISSIONS[mission].head }, label .. ": startQuest calls")
			lu.assertEquals(attempted(player, mission), "1", label .. ": :attempted")
			lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
			lu.assertEquals(#M.itemsGiven(player), 0, label .. ": items")
			restoreChains()
		end
	end
end

-- AC-7: closing the window on a failure screen (the line itself or one of the steps before the retry) starts nothing, and the next talk opens the same failure screen
function TestMasterTrainerRebelGrants:test_closing_on_a_failure_screen_starts_nothing_and_the_next_talk_opens_the_same_failure_screen()
	local stops = {
		{ gate = "m1_failed", replies = {} },
		{ gate = "m1_failed", replies = { "s_4c9055c9" } },
		{ gate = "m1_failed", replies = { "s_4c9055c9", "s_e228ef89" } },
		{ gate = "m1_failed", replies = { "s_ed30fff8" } },
		{ gate = "m2_failed", replies = {} },
		{ gate = "m2_failed", replies = { "s_d4d47c04" } },
		{ gate = "m2_failed", replies = { "s_eb02d65" } },
	}

	for _, q in ipairs(stops) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()
		local player = pilotFor(q.gate)
		local t = M.talk(player, q.replies)
		local label = q.gate .. " closed after " .. #q.replies .. " replies"

		lu.assertEquals(#t, #q.replies + 1, label .. ": screens shown")
		lu.assertFalse(t[#t].stop, label .. ": the last screen shown is not an end screen")
		lu.assertEquals(calls, {}, label .. ": startSpaceQuestChain calls")
		lu.assertEquals(M.started(spies), {}, label .. ": startQuest calls")
		lu.assertEquals(M.talk(player)[1].id, q.gate, label .. ": the next talk opens the same failure screen")
		restoreChains()
	end
end

-- AC-7: retries are not paid and set no reward key
function TestMasterTrainerRebelGrants:test_a_retry_pays_nothing_and_sets_no_reward_key()
	local player = pilotFor("m1_failed")

	M.spyStarts()
	M.talk(player, M.PATHS[2].replies)
	lu.assertNil(reward(player, 1), "master_rebel_1:reward")
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
end

-- AC-8: m2_accept sets the key and starts mission 2 once, every route
function TestMasterTrainerRebelGrants:test_every_route_from_m2_brief_starts_mission_2_once_and_nothing_else()
	local all = routes("m2_brief")

	lu.assertEquals(#all, 4, "m2_brief has four routes: two openings, two corvette branches")

	for _, p in ipairs(all) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()
		local player = pilotFor("m2_brief")
		local t = M.talk(player, p.replies)
		local label = "route " .. table.concat(p.ids, " > ")

		lu.assertEquals(M.ids(t), p.ids, label .. ": screens shown")
		lu.assertEquals(calls, { "destroy_master_rebel_2" }, label .. ": startSpaceQuestChain calls")
		lu.assertEquals(M.started(spies), { "destroy_master_rebel_2" }, label .. ": startQuest calls")
		lu.assertEquals(attempted(player, 2), "1", label .. ": master_rebel_2:attempted")
		lu.assertEquals(attempted(player, 1), "1", label .. ": master_rebel_1:attempted stays")
		lu.assertEquals(player.bankCredits or 0, 0, label .. ": credits")
		lu.assertEquals(#M.itemsGiven(player), 0, label .. ": items")
		restoreChains()
	end
end

-- AC-8: after the grant, the next talk is on the master mission
function TestMasterTrainerRebelGrants:test_after_the_grants_the_next_talk_opens_on_master_mission()
	local player = M.pilot({ inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = "space_light1" })

	M.talk(player, M.PATHS[1].replies)
	H.advance(0)

	local again = M.talk(player)

	lu.assertEquals(again[1].id, "on_master_mission", "the next talk with mission 1 running")
end

-- Table H: only the six start screens start a quest
function TestMasterTrainerRebelGrants:test_only_the_six_start_screens_start_a_quest()
	for _, row in ipairs(M.SCREENS) do
		H.reset()

		local calls = recordChains()
		local spies = M.spyStarts()

		M.drive(M.pilot({ paid = { 1 }, mission = { [2] = "won" } }), row.id)

		local n = M.STARTS[row.id]

		if n then
			lu.assertEquals(calls, { M.MISSIONS[n].head }, row.id .. ": startSpaceQuestChain calls")
		else
			lu.assertEquals(calls, {}, row.id .. ": startSpaceQuestChain calls (not a start screen)")
			lu.assertEquals(M.started(spies), {}, row.id .. ": startQuest calls (not a start screen)")
		end

		restoreChains()
	end
end

---------------------------------------------------------------------------------------------
-- Mission 1 reward (AC-8, I-7)
---------------------------------------------------------------------------------------------

TestMasterTrainerRebelReward = {}

TestMasterTrainerRebelReward.setUp = setUp

local SPECIES = {
	{ name = "human", id = SPECIES_HUMAN },
	{ name = "zabrak", id = SPECIES_ZABRAK },
	{ name = "wookiee", id = SPECIES_WOOKIEE },
	{ name = "ithorian", id = SPECIES_ITHORIAN },
}

for _, sp in ipairs(SPECIES) do
	-- AC-8, I-7: m1_reward pays 25000, the jacket (any species) and +200 Rebel
	TestMasterTrainerRebelReward["test_m1_reward_pays_the_credits_the_jacket_and_standing_to_a_" .. sp.name] = function()
		local player = pilotFor("m1_won", { species = sp.id })

		M.drive(player, "m1_reward")
		lu.assertEquals(player.bankCredits, 25000, "bank credits")
		lu.assertEquals(#player.bankCreditLog, 1, "addBankCredits calls")
		lu.assertEquals(M.itemsGiven(player), { "object/tangible/wearables/jacket/jacket_ace_rebel.iff" }, sp.name .. ": giveItem templates")
		lu.assertEquals(M.standing(player), 200, "Rebel standing")
		lu.assertEquals(reward(player, 1), "1", "master_rebel_1:reward")
		lu.assertNil(reward(player, 2), "master_rebel_2:reward stays unset")
	end
end

-- AC-8: through the real route
function TestMasterTrainerRebelReward:test_the_m1_won_route_pays_on_m1_reward_once()
	for _, p in ipairs(routes("m1_won")) do
		H.reset()

		local player = pilotFor("m1_won")
		local t = M.talk(player, p.replies)
		local label = "route " .. table.concat(p.ids, " > ")

		lu.assertEquals(M.ids(t), p.ids, label .. ": screens shown")
		lu.assertEquals(player.bankCredits, 25000, label .. ": credits")
		lu.assertEquals(#M.itemsGiven(player), 1, label .. ": items")
		lu.assertEquals(M.standing(player), 200, label .. ": standing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
	end

	lu.assertEquals(#routes("m1_won"), 1, "m1_won has one route")
end

-- AC-8, I-7: pays once
function TestMasterTrainerRebelReward:test_m1_reward_shown_three_times_pays_once()
	local player = pilotFor("m1_won")

	for _ = 1, 3 do
		M.drive(player, "m1_reward")
	end

	lu.assertEquals(player.bankCredits, 25000, "credits after three visits")
	lu.assertEquals(#M.itemsGiven(player), 1, "items after three visits")
	lu.assertEquals(M.standing(player), 200, "standing after three visits")
end

-- AC-8, I-7: a paid mission pays nothing
function TestMasterTrainerRebelReward:test_m1_reward_pays_nothing_when_the_reward_key_is_set()
	local player = pilotFor("m1_won")

	H.setQuestStatus(player, "master_rebel_1:reward", 1)
	M.drive(player, "m1_reward")
	lu.assertEquals(player.bankCredits or 0, 0, "credits")
	lu.assertEquals(#M.itemsGiven(player), 0, "items")
	lu.assertEquals(M.standing(player), 0, "standing")
end

-- AC-8: the first talk opens m1_won, the route pays, the next talk opens the mission 2 briefing
function TestMasterTrainerRebelReward:test_after_the_reward_the_next_talk_opens_m2_brief_and_pays_nothing()
	local player = pilotFor("m1_won")
	local t = M.talk(player, M.PATHS[4].replies)

	lu.assertEquals(M.ids(t), { "m1_won", "m1_corvette", "m1_outer_rim", "m1_reward" }, "the route")
	lu.assertEquals(player.bankCredits, 25000, "paid on display of m1_reward")

	local again = M.talk(player)

	lu.assertEquals(again[1].id, "m2_brief", "the next talk")
	lu.assertEquals(player.bankCredits, 25000, "credits after the second talk")
	lu.assertEquals(#M.itemsGiven(player), 1, "items after the second talk")
	lu.assertEquals(M.standing(player), 200, "standing after the second talk")
end

-- AC-8: close on m1_reward, before the later screens: still paid, still opens m2_brief
function TestMasterTrainerRebelReward:test_closing_on_m1_reward_keeps_the_payment_and_the_next_talk_opens_m2_brief()
	local player = pilotFor("m1_won")

	M.talk(player, M.PATHS[4].replies)
	lu.assertEquals(M.talk(player)[1].id, "m2_brief", "next talk")
end

-- AC-8, I-7: a full inventory still receives the jacket (the 4-argument giveItem overload)
function TestMasterTrainerRebelReward:test_a_full_inventory_still_receives_the_jacket_through_the_overload()
	local player = pilotFor("m1_won", { inventory = { limit = 0 } })

	M.drive(player, "m1_reward")
	lu.assertEquals(#player.inventory.items, 1, "the jacket lands in the full inventory")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")

	local calls = H.Engine.callsTo("giveItem")

	lu.assertEquals(#calls, 1, "giveItem calls")
	lu.assertEquals(calls[1].n, 4, "giveItem argument count (the overload form)")
	lu.assertIs(calls[1][4], true, "the overload flag")
end

-- AC-8, I-7: the reward is paid through the head's rewardPlayer
function TestMasterTrainerRebelReward:test_the_payment_goes_through_the_heads_reward_player_once()
	local spy = H.spyOn(M.quest("destroy_master_rebel_1"), "rewardPlayer")

	M.drive(pilotFor("m1_won"), "m1_reward")
	lu.assertEquals(#spy, 1, "destroy_master_rebel_1:rewardPlayer calls")
end

-- AC-8, I-7: no other screen but the two reward screens pays
function TestMasterTrainerRebelReward:test_no_other_screen_pays_credits_items_or_standing()
	for _, row in ipairs(M.SCREENS) do
		if row.id ~= "m1_reward" and row.id ~= "master_grant" then
			H.reset()
			M.spyStarts()

			local player = M.pilot({ paid = { 1 }, mission = { [2] = "won" } })

			M.drive(player, row.id)
			lu.assertEquals(player.bankCredits or 0, 0, row.id .. ": bank credits")
			lu.assertEquals(#M.itemsGiven(player), 0, row.id .. ": items")
			lu.assertEquals(M.standing(player), 0, row.id .. ": standing")
		end
	end
end

-- AC-8: payMission and isPaid on the handler
function TestMasterTrainerRebelReward:test_pay_mission_pays_unless_paid_and_marks_the_reward_key()
	local h = M.handler()
	local player = pilotFor("m1_won")
	local ghost = LuaPlayerObject(player.ghost)

	lu.assertFalse(h:isPaid(player, 1), "isPaid before")
	h:payMission(player, ghost, 1)
	lu.assertTrue(h:isPaid(player, 1), "isPaid after")
	lu.assertEquals(player.bankCredits, 25000, "credits")
	h:payMission(player, ghost, 1)
	lu.assertEquals(player.bankCredits, 25000, "credits after a second call")
	lu.assertEquals(M.standing(player), 200, "standing after a second call")
end

-- AC-8: the handler's state helpers
function TestMasterTrainerRebelReward:test_handler_state_helpers_read_the_journal_and_the_keys()
	local h = M.handler()
	local fresh = M.pilot({})
	local won = pilotFor("m1_won")
	local failed = pilotFor("m1_failed")
	local active = M.pilot({ mission = { [1] = "active" } })

	lu.assertFalse(h:isWon(fresh, 1), "fresh: isWon")
	lu.assertFalse(h:isActive(fresh, 1), "fresh: isActive")
	lu.assertFalse(h:isFailed(fresh, 1), "fresh: isFailed")
	lu.assertTrue(h:isWon(won, 1), "won: isWon")
	lu.assertFalse(h:isFailed(won, 1), "won: isFailed (attempted but won)")
	lu.assertTrue(h:isFailed(failed, 1), "failed: isFailed")
	lu.assertFalse(h:isActive(failed, 1), "failed: isActive")
	lu.assertTrue(h:isActive(active, 1), "active: isActive")
	lu.assertFalse(h:isFailed(active, 1), "active: isFailed (attempted, not won, but running)")
	lu.assertFalse(h:isWon(won, 2), "won 1: mission 2 not won")
end
