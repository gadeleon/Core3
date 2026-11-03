-- Smuggler transition: the single-point patrol completes at its point (SC-1), the 21 existing patrols are unaffected, and the whole chain runs.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-3, AC-4; Shared code changes SC-1; FK-6, FK-7; D-11; I-5, I-6; R-1, R-2).
--
-- Oracle values: smuggler_transition_data.lua T.expected() (derived from the SWG .tab and buildout fixtures). The quest tables are driven through the
-- harness fakes (event clock, observers, spawned ships); each scenario pumps the event clock inside pcall so a Lua error inside an event shows up as
-- "no Lua error" and not as a later, unrelated assertion. Completions are counted by a wrapper that calls the original (H.spyOn would not), restored in tearDown.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DR = require("duty_rules_scenario")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")

T.load()

local function quest(global) return T.quest(global) end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local wrapped = {}

-- Counts the calls of q:method while still running the original; returns the list of argument lists ({ pPlayer, notifyClient }).
local function countCalls(q, method)
	local calls = {}
	local original = q[method]

	wrapped[#wrapped + 1] = { q = q, method = method, own = rawget(q, method) }

	rawset(q, method, function(self, ...)
		calls[#calls + 1] = { ... }

		return original(self, ...)
	end)

	return calls
end

local function unwrap()
	for i = #wrapped, 1, -1 do
		local w = wrapped[i]

		rawset(w.q, w.method, w.own)
	end

	wrapped = {}
end

local function tearDown()
	unwrap()
	AC.tearDown()
end

local function ship() return { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y } end

-- A Smuggler in a ship in the quest zone who starts `global` (the quest's own startQuest, as a trainer does)
local function started(global)
	local q = quest(global)

	H.reset()
	q:start()

	local player = S.pilot({ zone = q.questZone, inShip = ship() })

	q:startQuest(player, "")
	H.advance(0)

	return q, player
end

local function alertsOf(player, questType, questName)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.TO == "@spacequest/" .. questType .. "/" .. questName .. ":split_quest_alert" then
			out[#out + 1] = m
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-3: the single-point patrol (SC-1)
---------------------------------------------------------------------------------------------

TestSmugglerTransPatrol = {}

function TestSmugglerTransPatrol:setUp() H.reset() end
TestSmugglerTransPatrol.tearDown = tearDown

-- AC-3: reaching the only point completes the patrol once; the alert comes at 2 s and the assassinate starts at 2.1 s
function TestSmugglerTransPatrol:test_reaching_the_only_point_completes_the_patrol_once_and_splits_at_two_seconds()
	local q = quest(T.PATROL)
	local asn = quest(T.ASSASSINATE)

	H.reset()
	q:start()

	local starts = H.spyOn(asn, "startQuest", function() return H.now() end)
	local player = S.pilot({ zone = T.ZONE, inShip = ship() })

	q:startQuest(player, "")
	H.advance(0)
	lu.assertTrue(isActive(player, q), T.PATROL .. ": precondition: active after startQuest")

	local completes = countCalls(q, "completeQuest")
	local t0 = H.now()

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(10, T.PATROL .. " point 1")

	lu.assertEquals(#completes, 1, T.PATROL .. ": completeQuest calls after reaching its only point")
	lu.assertEquals(completes[1][2], "false", T.PATROL .. ": completeQuest notifyClient (a split patrol sends the alert instead)")
	lu.assertTrue(isComplete(player, q), T.PATROL .. ": complete")
	lu.assertFalse(isActive(player, q), T.PATROL .. ": no longer active")
	lu.assertEquals(#starts, 0, T.ASSASSINATE .. ": not started before the split delay")

	pump(2200, T.PATROL .. " split")

	local alerts = alertsOf(player, "patrol", T.NAME)

	lu.assertEquals(#alerts, 1, T.PATROL .. ": split_quest_alert messages")
	lu.assertEquals(alerts[1].t - t0, 2000, T.PATROL .. ": ms from arrival to the split_quest_alert")
	lu.assertEquals(#starts, 1, T.ASSASSINATE .. ": startQuest calls")
	lu.assertEquals(starts[1].snapshot - t0, 2100, T.ASSASSINATE .. ": ms from arrival to startQuest (sideQuestDelay x 1050)")
	lu.assertEquals(#completes, 1, T.PATROL .. ": completeQuest calls in total")
end

-- AC-3: the waypoint of the point is gone once the patrol is complete
function TestSmugglerTransPatrol:test_the_rendezvous_waypoint_is_removed_on_arrival()
	local q, player = started(T.PATROL)
	local want = T.expected()[T.PATROL].patrolPoints[1]

	lu.assertEquals(#player.ghost.waypoints, 1, "waypoints after startQuest in space_lok")
	lu.assertEquals({ player.ghost.waypoints[1].x, player.ghost.waypoints[1].z, player.ghost.waypoints[1].y }, { want.x, want.z, want.y }, "the waypoint is the rendezvous point")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(100, T.PATROL .. " arrival")
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints after arrival")
end

-- AC-3: entering the area again, or entering it without the quest, completes and splits nothing
function TestSmugglerTransPatrol:test_a_second_entry_and_a_pilot_without_the_quest_change_nothing()
	local q, player = started(T.PATROL)
	local asn = quest(T.ASSASSINATE)
	local starts = H.spyOn(asn, "startQuest")
	local completes = countCalls(q, "completeQuest")
	local area = AC.areaByNumber(q, 1)
	local stranger = S.pilot({ zone = T.ZONE, inShip = ship() })

	H.enterArea(area, stranger.rootParent)
	pump(100, "a pilot without the quest enters")
	lu.assertEquals(#completes, 0, "completeQuest calls for a pilot without the quest")
	lu.assertFalse(isComplete(stranger, q), "the stranger's patrol is not complete")

	H.enterArea(area, player.rootParent)
	pump(100, "first entry")
	H.enterArea(area, player.rootParent)
	H.enterArea(area, player.rootParent)
	pump(5000, "re-entries and the split")

	lu.assertEquals(#completes, 1, T.PATROL .. ": completeQuest calls after three entries")
	lu.assertEquals(#starts, 1, T.ASSASSINATE .. ": startQuest calls after three entries")
	lu.assertEquals(#alertsOf(player, "patrol", T.NAME), 1, "split_quest_alert messages")
end

-- AC-3 / SC-1: a patrol without a split completes at its last point, with the completion message (sideQuest false -> notifyClient "true")
function TestSmugglerTransPatrol:test_a_patrol_without_a_split_completes_at_its_last_point()
	local synth = SpacePatrolScreenplay:new {
		className = "patrol_trans_synthetic",
		questName = "trans_synthetic",
		questType = "patrol",
		questZone = T.ZONE,
		sideQuest = false,
		sideQuestType = "",
		patrolPoints = {
			{ patrolPointName = "a", x = 1000, z = 0, y = 1000, patrolNumber = 1, radius = 150 },
			{ patrolPointName = "b", x = 2000, z = 0, y = 2000, patrolNumber = 2, radius = 150 },
		},
	}

	rawset(_G, "patrol_trans_synthetic", synth)

	local ok, err = pcall(function()
		H.reset()
		synth:start()

		local player = S.pilot({ zone = T.ZONE, inShip = ship() })

		synth:startQuest(player, "")
		H.advance(0)

		local completes = countCalls(synth, "completeQuest")

		H.enterArea(AC.areaByNumber(synth, 1), player.rootParent)
		pump(100, "point 1")
		lu.assertEquals(#completes, 0, "completeQuest calls after the first of two points")
		lu.assertTrue(isActive(player, synth), "still active after the first of two points")
		H.enterArea(AC.areaByNumber(synth, 2), player.rootParent)
		pump(100, "point 2")
		lu.assertEquals(#completes, 1, "completeQuest calls after the last point")
		lu.assertEquals(completes[1][2], "true", "completeQuest notifyClient (no split: the pilot is told)")
		lu.assertTrue(isComplete(player, synth), "complete")
	end)

	rawset(_G, "patrol_trans_synthetic", nil)
	unwrap()
	AC.tearDown()
	lu.assertTrue(ok, tostring(err))
end

---------------------------------------------------------------------------------------------
-- AC-3: the existing patrols do not change (D-11): completion only through their split
---------------------------------------------------------------------------------------------

TestSmugglerTransExistingPatrols = {}

function TestSmugglerTransExistingPatrols:setUp() H.reset() end
TestSmugglerTransExistingPatrols.tearDown = tearDown

-- every loaded patrol quest except the new one, by global name
local EXISTING = {}

for _, name in ipairs(H.questGlobals()) do
	local q = rawget(_G, name)

	if q.questType == "patrol" and name ~= T.PATROL then
		EXISTING[#EXISTING + 1] = name
	end
end

-- AC-3: the guard itself: 21 existing patrols, all split at an earlier point than the last
function TestSmugglerTransExistingPatrols:test_there_are_21_existing_patrols_all_splitting_at_a_point_before_the_last()
	lu.assertEquals(#EXISTING, 21, "patrol quests loaded besides " .. T.PATROL)

	for _, name in ipairs(EXISTING) do
		local q = rawget(_G, name)

		lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, name .. ": sideQuestSplitType")
		lu.assertTrue(q.sideQuestPatrolStart >= 1 and q.sideQuestPatrolStart < #q.patrolPoints, name .. ": sideQuestPatrolStart " .. tostring(q.sideQuestPatrolStart) .. " versus " .. #q.patrolPoints .. " points")
	end
end

for _, name in ipairs(EXISTING) do
	-- AC-3: all points back to back, the last one inside the split delay: no completion until the delay, then exactly one, and the child starts once
	TestSmugglerTransExistingPatrols["test_" .. name .. "_completes_once_through_its_own_split_and_not_at_its_last_point"] = function()
		local q = rawget(_G, name)

		H.reset()
		q:start()

		local spies = AC.isolate(q)
		local player = S.pilot({ zone = q.questZone, inShip = ship() })

		q:startQuest(player, "")
		H.advance(0)

		local completes = countCalls(q, "completeQuest")
		local child = q.sideQuestType .. "_" .. q.sideQuestName

		for i = 1, #q.patrolPoints do
			H.enterArea(AC.areaByNumber(q, i), player.rootParent)
			pump(50, name .. " point " .. i)
		end

		lu.assertEquals(#completes, 0, name .. ": completeQuest calls right after the last point (the split delay has not run out)")
		lu.assertTrue(isActive(player, q), name .. ": still active inside the split delay")

		-- a repeated entry of the last point changes nothing either
		H.enterArea(AC.areaByNumber(q, #q.patrolPoints), player.rootParent)
		pump(q.sideQuestDelay * 1000 + 3000, name .. " split")

		lu.assertEquals(#completes, 1, name .. ": completeQuest calls in total")
		lu.assertEquals(completes[1][2], "false", name .. ": completeQuest notifyClient")
		lu.assertTrue(isComplete(player, q), name .. ": complete")
		lu.assertEquals(#spies.start[child], 1, name .. ": " .. child .. ":startQuest calls")
	end
end

-- AC-3: the named case: patrol_tatooine_privateer_1, points 2 and 3 within its 20 s, then the real surprise attack once
function TestSmugglerTransExistingPatrols:test_tatooine_privateer_1_reaching_points_2_and_3_inside_the_delay_starts_the_surprise_attack_exactly_once()
	local q, player = started(S.P1)
	local s1 = quest(S.S1)
	local completes = countCalls(q, "completeQuest")
	local starts = countCalls(s1, "startQuest")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, "point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, "point 2")
	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, "point 3")

	lu.assertEquals(#completes, 0, S.P1 .. ": completeQuest calls after point 3 (inside the 20 s)")
	lu.assertTrue(isActive(player, q), S.P1 .. ": still active after point 3")

	pump(25000, "split delay")

	lu.assertEquals(#completes, 1, S.P1 .. ": completeQuest calls in total")
	lu.assertEquals(#starts, 1, S.S1 .. ": startQuest calls")
	lu.assertEquals(#H.spawnedShips(), 3, "attackers spawned by the one surprise attack")
	lu.assertTrue(isComplete(player, q), S.P1 .. ": complete")
	lu.assertTrue(isActive(player, s1), S.S1 .. ": active")
end

---------------------------------------------------------------------------------------------
-- AC-4: the whole chain
---------------------------------------------------------------------------------------------

TestSmugglerTransChain = {}

function TestSmugglerTransChain:setUp() H.reset() end
TestSmugglerTransChain.tearDown = tearDown

-- A tier-1-complete Smuggler in a ship in space_lok, granted the quest by Karrde (the real conversation, job_details)
local function granted()
	H.reset()
	quest(T.PATROL):start()
	quest(T.ASSASSINATE):start()

	local player = T.pilot({ zone = T.ZONE, inShip = ship() })

	T.drive(player, "job_details")
	H.advance(0)

	return player
end

local function shipNames(ships)
	local out = {}

	for i, s in ipairs(ships) do
		out[i] = s.shipName
	end

	return out
end

-- AC-4: grant, waypoint, arrival, the split, the assassinate's arrival 5 s later
function TestSmugglerTransChain:test_the_granted_patrol_shows_the_waypoint_completes_on_arrival_and_the_corsairs_arrive_5_seconds_after_the_assassinate_starts()
	local player = granted()
	local want = T.expected()
	local pat, asn = quest(T.PATROL), quest(T.ASSASSINATE)

	lu.assertTrue(isActive(player, pat), T.PATROL .. ": active after the grant")
	lu.assertEquals(#player.ghost.waypoints, 1, "the rendezvous waypoint appears (the pilot is in space_lok)")

	H.enterArea(AC.areaByNumber(pat, 1), player.rootParent)
	pump(2150, "split")
	lu.assertTrue(isComplete(player, pat), T.PATROL .. ": complete")
	lu.assertTrue(isActive(player, asn), T.ASSASSINATE .. ": active after the split")
	lu.assertEquals(#H.spawnedShips(), 0, "no corsair yet")

	pump(4000, "before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, "no corsair 4 s after the assassinate starts (arrivalDelay 5)")
	pump(2000, "deployTargets")

	local ships = H.spawnedShips()
	local t = want[T.ASSASSINATE].targetPatrols[1]

	lu.assertEquals(shipNames(ships), { "corsair_behemoth_tier2", "corsair_manowar_tier1", "corsair_manowar_tier1", "corsair_manowar_tier1" }, T.ASSASSINATE .. ": spawned ships, target first")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { t.x, t.z, t.y }, T.ASSASSINATE .. ": the target spawns at targetPatrols[1] (" .. t.patrolPointName .. ")")

	for i, s in ipairs(ships) do
		lu.assertEquals(s.zone, T.ZONE, T.ASSASSINATE .. ": ship " .. i .. " zone")
		lu.assertEquals(s.missionOwner, player, T.ASSASSINATE .. ": ship " .. i .. " belongs to the pilot")
	end
end

local function toCorsairs()
	local player = granted()

	H.enterArea(AC.areaByNumber(quest(T.PATROL), 1), player.rootParent)
	pump(8200, "split and arrival")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 4, "precondition: the Behemoth and three Man O'Wars")

	return player, ships
end

-- AC-4: mustDestroyEscort
function TestSmugglerTransChain:test_destroying_only_the_behemoth_does_not_complete_the_assassinate()
	local player, ships = toCorsairs()
	local asn = quest(T.ASSASSINATE)

	H.destroyShip(ships[1], player.rootParent)
	pump(3000, "the Behemoth is destroyed")
	lu.assertFalse(isComplete(player, asn), T.ASSASSINATE .. ": not complete with three Man O'Wars alive")
	lu.assertTrue(isActive(player, asn), T.ASSASSINATE .. ": still active")
	lu.assertFalse(T.squadron():hasWonTransQuest(player), "hasWonTransQuest with the assassinate unfinished")
end

-- AC-4: the win, I-5 (nothing pays), and Karrde's reaction
function TestSmugglerTransChain:test_destroying_all_four_completes_the_chain_pays_nothing_and_karrde_opens_trans_won()
	local player, ships = toCorsairs()
	local asn, pat = quest(T.ASSASSINATE), quest(T.PATROL)
	local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
	local rewards = { H.spyOn(pat, "rewardPlayer"), H.spyOn(asn, "rewardPlayer") }
	local items0 = #H.Engine.callsTo("giveItem")

	for i = 1, 3 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, "kill " .. i)
		lu.assertFalse(isComplete(player, asn), T.ASSASSINATE .. ": not complete after " .. i .. " of 4 kills")
	end

	H.destroyShip(ships[4], player.rootParent)
	pump(3000, "kill 4")

	lu.assertTrue(isComplete(player, asn), T.ASSASSINATE .. ": complete after all four are destroyed")
	lu.assertTrue(isComplete(player, pat), T.PATROL .. ": complete")
	lu.assertTrue(T.squadron():hasWonTransQuest(player), "hasWonTransQuest")
	lu.assertEquals(#credits, 0, "SpaceHelpers:spaceCreditReward calls (Shamdon pays, next feature)")
	lu.assertEquals({ #rewards[1], #rewards[2] }, { 0, 0 }, "rewardPlayer calls on the patrol and the assassinate")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), items0, "giveItem calls")
	lu.assertEquals(player.bankCredits or 0, 0, "credits paid")
	lu.assertNil(H.getQuestStatus(player, T.REWARD), ":reward (only Shamdon writes it)")

	lu.assertEquals(T.firstScreen(player), "trans_won", "Karrde's first screen after the win")
	lu.assertEquals(S.firstScreen(player), "tier_done", "Dravis' first screen after the win")
end

-- AC-4, AC-6: a patrol failed for real sends the pilot back to Karrde's retry
function TestSmugglerTransChain:test_a_failed_patrol_opens_trans_failed_and_a_retry_runs_the_chain_again()
	local player = granted()
	local pat = quest(T.PATROL)

	pat:failQuest(player, "false")
	pump(500, "failQuest")
	lu.assertFalse(isActive(player, pat), T.PATROL .. ": not active after failQuest")
	lu.assertEquals(T.firstScreen(player), "trans_failed", "Karrde after a failed patrol")

	local t = T.talk(player, { "s_a60a995b" })

	pump(0, "retry")
	lu.assertEquals(T.ids(t), { "trans_failed", "trans_retry" }, "screens shown")
	lu.assertTrue(isActive(player, pat), T.PATROL .. ": active again after the retry")
end

-- AC-4, AC-6: aborting the mission at the datapad sends the pilot back to Karrde's retry
function TestSmugglerTransChain:test_an_aborted_patrol_opens_trans_failed()
	local player = granted()

	H.abortMission(player, "patrol", T.NAME)
	pump(500, "abort")
	lu.assertFalse(isActive(player, quest(T.PATROL)), T.PATROL .. ": not active after the abort")
	lu.assertEquals(T.firstScreen(player), "trans_failed", "Karrde after an abort")
end

-- AC-4, AC-6, R-2: the assassinate failing sends the pilot back too, and the retry starts the patrol over
function TestSmugglerTransChain:test_a_failed_assassinate_opens_trans_failed_and_the_retry_restarts_the_patrol()
	local player = toCorsairs()
	local asn, pat = quest(T.ASSASSINATE), quest(T.PATROL)

	asn:failQuest(player, "false")
	pump(500, "failQuest")
	lu.assertFalse(isActive(player, asn), T.ASSASSINATE .. ": not active after failQuest")
	lu.assertEquals(T.firstScreen(player), "trans_failed", "Karrde after a failed assassinate")

	T.talk(player, { "s_a60a995b" })
	pump(0, "retry")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", T.ASSASSINATE .. ": cleared by the retry")
	lu.assertTrue(isActive(player, pat), T.PATROL .. ": active again")
end
