-- Vortex tier 4 part A: Brother Extok Evin's four missions and four duties run through the fakes, split by split, both ways.
-- Spec: .claude/work/vortex-tier4-extok-evin/01-spec.md (A-3, A-4, A-5; Data mapping 1; FE-1, FE-2, FE-3, FE-5; D-3, D-7; R-1, R-7).
--
-- The oracle values are the spec's literals (vortex_tier4_data.lua, proven equal to the SWG .tab fixtures by test_vortex_tier4_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. For a split the test completes (or fails) the head through its own completeQuest /
-- failQuest and pumps the split delay: the alert fires at the delay and the next quest starts at delay * 1.05, so "not active 1 s before the delay" and "active
-- 2 s after it" bracket the delay. Every split also shows that the OTHER branch is never started (no startQuest event queued for it, not active). Flying the
-- battles and the survivals is covered by their type features: this file stops at "active / spawned" for them. The hostility of the real AI (R-4) cannot be
-- checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local E = require("vortex_tier4_data")

E.load()

local function quest(global) return E.quest(global) end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function shipNames(ships)
	local out = {}

	for i, ship in ipairs(ships) do
		out[i] = ship.shipName
	end

	return out
end

local function countOf(names, wanted)
	local n = 0

	for _, name in ipairs(names) do
		if name == wanted then
			n = n + 1
		end
	end

	return n
end

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local function waypointsAt(player, x, z, y)
	local n = 0

	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == x and w.z == z and w.y == y then
			n = n + 1
		end
	end

	return n
end

local function pointOf(zone, name)
	local p = E.POINTS[zone][name]

	assert(p ~= nil, "no spec point " .. name .. " in " .. zone)
	return p
end

-- A fresh world with the static areas of every member of the list, and the pilot in a Rebel ship in the first member's zone (or `zone`)
local function world(members, zone)
	H.reset()

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery_duty" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return E.flyer(zone or E.IDENTITY[members[1]].zone)
end

local function chain(n) return world(E.CHAINS[n]) end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Number of startQuest events queued (since the last reset) for `global`
local function startEventsFor(global)
	local n = 0

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[2] == global and c[3] == "startQuest" then
			n = n + 1
		end
	end

	return n
end

-- Brackets a split: `child` is not active 1 s before `seconds` and is active 2 s after it; `other` (the other branch) is never started
local function assertSplit(player, from, child, other, seconds)
	local nq = quest(child)

	pump((seconds - 1) * 1000, from .. " split delay")
	lu.assertFalse(isActive(player, nq), child .. ": not active " .. (seconds - 1) .. " s after " .. from .. " ended (sideQuestDelay " .. seconds .. " s)")
	pump(3000, from .. " split start")
	lu.assertTrue(isActive(player, nq), child .. ": active " .. (seconds + 2) .. " s after " .. from .. " ended")

	if other then
		lu.assertFalse(isActive(player, quest(other)), other .. ": the other branch is not active after " .. from .. " split to " .. child)
		lu.assertEquals(startEventsFor(other), 0, other .. ": no startQuest was queued for the other branch of " .. from)
	end
end

-- Completes a member through its own completeQuest, then brackets the split to `child` (and never `other`)
local function completeAndSplit(player, global, child, other, seconds)
	local q = quest(global)

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")
	assertSplit(player, global, child, other, seconds or 5)
end

-- Fails a member through its own failQuest ("true"), then brackets the split to `child` (and never `other`)
local function failAndSplit(player, global, child, other, seconds)
	local q = quest(global)

	pump(0, global .. " before failure")
	q:failQuest(player, "true")
	pump(0, global .. " failure")
	lu.assertFalse(isActive(player, q), global .. ": no longer active after failQuest")
	lu.assertFalse(isComplete(player, q), global .. ": a failed quest is not complete")
	assertSplit(player, global, child, other, seconds or 5)
end

local function noMemberActive(player, n)
	for _, global in ipairs(E.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

-- A delivery leg: the setup (2 s); returns the active area spawned
local function deliveryArea(label)
	pump(2000, label .. " setup")

	local areas = H.spawnedAreas()

	lu.assertTrue(#areas >= 1, label .. ": the delivery area was spawned")

	return areas[#areas]
end

local function lastAreaCall()
	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local c = calls[#calls]

	return { c[1], c[3], c[4], c[5] }
end

-- An escort leg whose quest is already started: setupEscort (2 s), the start area, the escort ship (5 s). Returns the escort ship.
local function flyStartedEscort(q, player)
	pump(2500, q.className .. " setup")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertTrue(start >= 1, q.className .. ": setupEscort chose a start point")
	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, q.className .. " escort spawn")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, q.className .. ": the escort ship spawned")

	return escort
end

local function copyShips()
	local out = {}

	for i, s in ipairs(H.spawnedShips()) do
		out[i] = s
	end

	return out
end

-- starts the quest and lets the targets deploy; returns the spawned ships in spawn order
local function deployedShips(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	return copyShips()
end

local F, I, A = "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_advanced_tier4"

---------------------------------------------------------------------------------------------
-- A-3 (a) and (b): mission 1 in space_endor
---------------------------------------------------------------------------------------------

TestEvinChain1 = {}

function TestEvinChain1:setUp() H.reset() end

function TestEvinChain1:tearDown() AC.tearDown() end

-- A-3 (a): survival 1 is active at its point with a waypoint
function TestEvinChain1:test_survival_1_is_active_at_its_point_with_a_waypoint()
	local player = chain(1)
	local q = begin(player, E.M1[1])
	local p = pointOf("space_endor", "naboo_rebel_tier4_1_survival")

	pump(12000, E.M1[1] .. " start")
	lu.assertTrue(isActive(player, q), E.M1[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, E.M1[1] .. ": one waypoint at naboo_rebel_tier4_1_survival")
end

-- A-3 (a), FE-1: completing survival 1 starts assassinate 1_a 5 s later and never escort 1_b; the target spawns with eight escorts after 5 s; killing the target
-- alone completes 1_a and no mission 1 member is left active
function TestEvinChain1:test_completing_survival_1_starts_assassinate_1_a_after_five_seconds_and_killing_its_target_alone_completes_it()
	local player = chain(1)

	begin(player, E.M1[1])
	pump(2000, E.M1[1] .. " setup")
	completeAndSplit(player, E.M1[1], E.M1[2], E.M1[3], 5)

	local q = quest(E.M1[2])

	pump(12000, E.M1[2] .. " deployTargets")

	local ships = copyShips()
	local names = shipNames(ships)

	lu.assertEquals(names, { "tieadvanced_inquisitor_tier4", A, A, F, F, F, F, F, F }, E.M1[2] .. ": the target and eight escorts, " .. table.concat(names, ", "))

	local p = pointOf("space_endor", "naboo_rebel_tier4_1_a_assassin_1")

	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, E.M1[2] .. ": the target spawns at targetPatrols[1] (naboo_rebel_tier4_1_a_assassin_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", E.M1[2] .. ": ship " .. i .. " zone")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(8000, E.M1[2] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), E.M1[2] .. ": complete with the escorts still alive (mustDestroyEscort false)")
	noMemberActive(player, 1)
	lu.assertEquals(startEventsFor(E.M1[3]), 0, E.M1[3] .. ": escort 1_b was never started on the won branch")
end

-- A-3 (b), FE-1, FE-3: failing survival 1 starts escort 1_b 5 s later and never assassinate 1_a; completing 1_b leaves no member active and 1_b complete
function TestEvinChain1:test_failing_survival_1_starts_escort_1_b_after_five_seconds_and_completing_it_ends_the_mission()
	local player = chain(1)

	begin(player, E.M1[1])
	pump(2000, E.M1[1] .. " setup")
	failAndSplit(player, E.M1[1], E.M1[3], E.M1[2], 5)

	local q = quest(E.M1[3])
	local escort = flyStartedEscort(q, player)

	lu.assertEquals(escort.shipName, "reb_freightermedium_tier4", E.M1[3] .. ": the escorted ship")
	lu.assertEquals(escort.zone, "space_endor", E.M1[3] .. ": the escorted ship zone")
	q:completeQuest(player, true)
	pump(8000, E.M1[3] .. " after completion")
	lu.assertTrue(isComplete(player, q), E.M1[3] .. ": the failure end is complete")
	noMemberActive(player, 1)
	lu.assertFalse(isActive(player, quest(E.M1[2])), E.M1[2] .. ": assassinate 1_a was never started")
end

---------------------------------------------------------------------------------------------
-- A-4 (a), (b): mission 2 in space_yavin4, the failure branch crosses into space_dathomir (FE-2)
---------------------------------------------------------------------------------------------

TestEvinChain2 = {}

function TestEvinChain2:setUp() H.reset() end

function TestEvinChain2:tearDown() AC.tearDown() end

-- A-4 (a): assassinate 2 spawns Uvqolo and six escorts after 10 s at its first point
function TestEvinChain2:test_assassinate_2_spawns_uvqolo_and_six_escorts_after_ten_seconds_at_its_first_point()
	local player = chain(2)

	begin(player, E.M2[1])
	pump(8000, E.M2[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, E.M2[1] .. ": nothing spawned 8 s after the start (arrivalDelay 10)")
	pump(7000, E.M2[1] .. " deployTargets")

	local ships = copyShips()
	local p = pointOf("space_yavin4", "naboo_rebel_tier4_2_assassin_1")

	lu.assertEquals(shipNames(ships), { "tieaggressor_uvqolo", A, A, I, I, I, I }, E.M2[1] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, E.M2[1] .. ": the target spawns at targetPatrols[1]")
end

-- A-4 (a), FE-1: completing assassinate 2 (the target alone: mustDestroyEscort false) starts battle 2_a 5 s later and never surprise 2_b; battle 2_a ends the mission
function TestEvinChain2:test_completing_assassinate_2_starts_battle_2_a_after_five_seconds_and_never_surprise_2_b()
	local player = chain(2)
	local ships = deployedShips(player, E.M2[1], 14000)

	lu.assertEquals(#ships, 7, E.M2[1] .. ": precondition: the target and six escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, E.M2[1] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, quest(E.M2[1])), E.M2[1] .. ": complete with the escorts still alive")
	assertSplit(player, E.M2[1], E.M2[2], E.M2[3], 5)

	local battle = quest(E.M2[2])
	local p = pointOf("space_yavin4", "naboo_rebel_tier4_2_a_battle_point")

	pump(2000, E.M2[2] .. " setup")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, E.M2[2] .. ": one waypoint at naboo_rebel_tier4_2_a_battle_point")
	battle:completeQuest(player, true)
	pump(8000, E.M2[2] .. " completion")
	lu.assertTrue(isComplete(player, battle), E.M2[2] .. ": the success end is complete")
	noMemberActive(player, 2)
end

-- A-4 (b), FE-3: the 20-minute timeout fail of assassinate 2 starts surprise 2_b 5 s later (nine interceptor guards) and never battle 2_a
function TestEvinChain2:test_the_timeout_fail_of_assassinate_2_starts_surprise_2_b_after_five_seconds_with_nine_guards_and_never_battle_2_a()
	local player = chain(2)
	local q = quest(E.M2[1])

	deployedShips(player, E.M2[1], 14000)
	lu.assertTrue(isActive(player, q), E.M2[1] .. ": precondition: running")
	pump(20 * 60 * 1000 - 20000, E.M2[1] .. " just before the timer")

	local waited = 0

	while isActive(player, q) and waited < 60000 do
		pump(500, E.M2[1] .. " waiting for the timeout")
		waited = waited + 500
	end

	lu.assertFalse(isActive(player, q), E.M2[1] .. ": failed by the timeout")
	lu.assertFalse(isComplete(player, q), E.M2[1] .. ": a timed-out run is not complete")
	assertSplit(player, E.M2[1], E.M2[3], E.M2[2], 5)
	pump(60000, E.M2[3] .. " attack")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "tieinterceptor_inquisitor_guard"), 9, E.M2[3] .. ": nine guards among " .. table.concat(names, ", "))
end

-- A-4 (b), FE-3, D-7: leaving the zone fails assassinate 2 without any split (SWG passes no split on a zone exit)
function TestEvinChain2:test_leaving_the_zone_fails_assassinate_2_and_starts_neither_child()
	local player = chain(2)
	local q = quest(E.M2[1])

	deployedShips(player, E.M2[1], 14000)
	H.zoneSwitch(player, "space_naboo", { ship = true })
	pump(60000, E.M2[1] .. " after leaving the zone")
	lu.assertFalse(isActive(player, q), E.M2[1] .. ": failed")
	lu.assertFalse(isComplete(player, q), E.M2[1] .. ": not complete")

	for _, child in ipairs({ E.M2[2], E.M2[3], E.M2[4] }) do
		lu.assertEquals(startEventsFor(child), 0, child .. ": no startQuest queued after a leave-zone fail")
		lu.assertFalse(isActive(player, quest(child)), child .. ": not active after a leave-zone fail")
	end
end

-- A-4 (b), FE-2, D-3: destroying the nine guards starts assassinate 2_c 10 s later (not 5); in space_yavin4 it is active and spawns nothing; entering
-- space_dathomir spawns Uvqolo and six escorts after 10 s; completing 2_c ends the mission
function TestEvinChain2:test_destroying_the_guards_starts_assassinate_2_c_after_ten_seconds_and_it_runs_when_the_pilot_enters_dathomir()
	local player = chain(2)
	local surprise = begin(player, E.M2[3])

	pump(60000, E.M2[3] .. " attack")

	local guards = copyShips()

	lu.assertEquals(shipNames(guards), { "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard",
		"tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard",
		"tieinterceptor_inquisitor_guard", "tieinterceptor_inquisitor_guard" }, E.M2[3] .. ": the nine guards")

	for i, ship in ipairs(guards) do
		lu.assertEquals(ship.zone, "space_yavin4", E.M2[3] .. ": guard " .. i .. " zone")
	end

	for i = 1, 8 do
		H.destroyShip(guards[i], player.rootParent)
		pump(500, E.M2[3] .. " after kill " .. i)
		lu.assertFalse(isComplete(player, surprise), E.M2[3] .. ": not complete after " .. i .. " of 9 kills")
	end

	H.destroyShip(guards[9], player.rootParent)
	pump(1500, E.M2[3] .. " after kill 9")
	lu.assertTrue(isComplete(player, surprise), E.M2[3] .. ": complete after all nine guards are destroyed")

	local c = quest(E.M2[4])

	pump(5000, E.M2[3] .. " 6.5 s after the last kill")
	lu.assertFalse(isActive(player, c), E.M2[4] .. ": not active 6.5 s after the last kill (the split is 10 s: triggerDelay 5 + 5, not 5)")
	pump(2000, E.M2[3] .. " 8.5 s after the last kill")
	lu.assertFalse(isActive(player, c), E.M2[4] .. ": not active 8.5 s after the last kill")
	pump(5000, E.M2[3] .. " 13.5 s after the last kill")
	lu.assertTrue(isActive(player, c), E.M2[4] .. ": active 13.5 s after the last kill")

	-- FE-2: the pilot is still in space_yavin4, so nothing spawns for 2_c
	local before = #H.spawnedShips()

	pump(30000, E.M2[4] .. " while the pilot is still in space_yavin4")
	lu.assertEquals(#H.spawnedShips(), before, E.M2[4] .. ": nothing spawned while the pilot is in space_yavin4")
	lu.assertTrue(isActive(player, c), E.M2[4] .. ": still active")

	H.zoneSwitch(player, "space_dathomir", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(9000, E.M2[4] .. " entered space_dathomir")
	lu.assertEquals(#H.spawnedShips(), before, E.M2[4] .. ": nothing spawned 9 s after entering space_dathomir (arrivalDelay 10)")
	pump(5000, E.M2[4] .. " deployTargets")

	local ships = {}

	for i, s in ipairs(copyShips()) do
		if i > before then
			ships[#ships + 1] = s
		end
	end
	local p = pointOf("space_dathomir", "naboo_rebel_tier4_2_c_assassin_1")

	lu.assertEquals(shipNames(ships), { "tieaggressor_uvqolo", A, A, I, I, I, I }, E.M2[4] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, E.M2[4] .. ": the target spawns at targetPatrols[1] (naboo_rebel_tier4_2_c_assassin_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dathomir", E.M2[4] .. ": ship " .. i .. " zone")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(8000, E.M2[4] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, c), E.M2[4] .. ": complete (mustDestroyEscort false)")
	noMemberActive(player, 2)
end

---------------------------------------------------------------------------------------------
-- A-3 (c): mission 3 in space_dathomir
---------------------------------------------------------------------------------------------

TestEvinChain3 = {}

function TestEvinChain3:setUp() H.reset() end

function TestEvinChain3:tearDown() AC.tearDown() end

-- A-3 (c): rescue 3 spawns the Vortex spy after 5 s; completing it starts assassinate 3_a 5 s later and never delivery 3_b
function TestEvinChain3:test_completing_rescue_3_starts_assassinate_3_a_after_five_seconds_and_never_delivery_3_b()
	local player = chain(3)

	begin(player, E.M3[1])
	pump(10000, E.M3[1] .. " start")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "tie_vortex_spy") >= 1, E.M3[1] .. ": tie_vortex_spy spawned within 10 s; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, E.M3[1], E.M3[2], E.M3[3], 5)
end

-- A-3 (c): failing rescue 3 starts delivery_no_pickup 3_b 5 s later and never assassinate 3_a; completing 3_b ends the mission
function TestEvinChain3:test_failing_rescue_3_starts_delivery_3_b_after_five_seconds_and_completing_it_ends_the_mission()
	local player = chain(3)

	begin(player, E.M3[1])
	pump(10000, E.M3[1] .. " start")
	failAndSplit(player, E.M3[1], E.M3[3], E.M3[2], 5)

	local q = quest(E.M3[3])

	deliveryArea(E.M3[3])

	local p = pointOf("space_dathomir", "naboo_rebel_tier4_3_b_delivery")

	lu.assertEquals(lastAreaCall(), { "space_dathomir", p[1], p[2], p[3] }, E.M3[3] .. ": the delivery area (zone, x, z, y)")
	q:completeQuest(player, true)
	pump(8000, E.M3[3] .. " after completion")
	lu.assertTrue(isComplete(player, q), E.M3[3] .. ": the failure end is complete")
	noMemberActive(player, 3)
	lu.assertFalse(isActive(player, quest(E.M3[2])), E.M3[2] .. ": assassinate 3_a was never started")
end

-- A-3 (c): assassinate 3_a (mustDestroyEscort true): killing only the target does not complete it, killing all seven does; the mission ends with no member active
function TestEvinChain3:test_assassinate_3_a_needs_the_target_and_every_escort_destroyed()
	local player = chain(3)
	local q = quest(E.M3[2])
	local ships = deployedShips(player, E.M3[2], 14000)
	local p = pointOf("space_dathomir", "naboo_rebel_tier4_3_a_assassin_1")

	lu.assertEquals(shipNames(ships), { "tiedecimator_inquisitor", A, A, I, I, I, I }, E.M3[2] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, E.M3[2] .. ": the target spawns at targetPatrols[1]")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, E.M3[2] .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), E.M3[2] .. ": not complete with the escorts alive (mustDestroyEscort)")

	for i = 2, #ships do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, E.M3[2] .. " after ship " .. i)
	end

	pump(8000, E.M3[2] .. " after all seven are destroyed")
	lu.assertTrue(isComplete(player, q), E.M3[2] .. ": complete once everything is destroyed")
	noMemberActive(player, 3)
end

---------------------------------------------------------------------------------------------
-- A-4 (c): mission 4 in space_dathomir
---------------------------------------------------------------------------------------------

TestEvinChain4 = {}

function TestEvinChain4:setUp() H.reset() end

function TestEvinChain4:tearDown() AC.tearDown() end

-- A-4 (c): battle 4 sets up at its point: a waypoint, nothing for 100 s, then the nine Inquisition enemies (120 s) and five Rebel allies (150 s), all in space_dathomir
function TestEvinChain4:test_battle_4_sets_up_at_its_point_with_five_allies_and_nine_enemies()
	local player = chain(4)
	local q = begin(player, E.M4[1])
	local p = pointOf("space_dathomir", "naboo_rebel_tier4_4_battle_point")

	pump(5000, E.M4[1] .. " setup")
	lu.assertTrue(isActive(player, q), E.M4[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, E.M4[1] .. ": one waypoint at naboo_rebel_tier4_4_battle_point")
	lu.assertEquals(#H.spawnedShips(), 0, E.M4[1] .. ": nothing spawned 5 s after the start")
	pump(150000, E.M4[1] .. " both forces arrived")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 14, E.M4[1] .. ": 5 allies + 9 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_awing_tier4"), 2, E.M4[1] .. ": two A-wings")
	lu.assertEquals(countOf(all, "reb_xwing_tier4"), 3, E.M4[1] .. ": three X-wings")
	lu.assertEquals(countOf(all, "tiedecimator_inquisitor"), 1, E.M4[1] .. ": one decimator")
	lu.assertEquals(countOf(all, "tieinterceptor_inquisitor_guard"), 2, E.M4[1] .. ": two guards")
	lu.assertEquals(countOf(all, F), 5, E.M4[1] .. ": five fighters")
	lu.assertEquals(countOf(all, "imp_tie_aggressor_tier4"), 1, E.M4[1] .. ": one aggressor")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dathomir", E.M4[1] .. ": " .. tostring(ship.shipName) .. " zone")
	end
end

-- A-4 (c): winning battle 4 starts battle 4_a 5 s later and never survival 4_b; completing 4_a leaves no member active and 4_a complete
function TestEvinChain4:test_winning_battle_4_starts_battle_4_a_after_five_seconds_and_never_survival_4_b()
	local player = chain(4)

	begin(player, E.M4[1])
	pump(5000, E.M4[1] .. " setup")
	completeAndSplit(player, E.M4[1], E.M4[2], E.M4[3], 5)

	local q = quest(E.M4[2])

	pump(5000, E.M4[2] .. " setup")
	q:completeQuest(player, true)
	pump(8000, E.M4[2] .. " completion")
	lu.assertTrue(isComplete(player, q), E.M4[2] .. ": the success end is complete")
	noMemberActive(player, 4)
end

-- A-4 (c): losing battle 4 (failQuest "true") starts survival 4_b 5 s later and never battle 4_a; completing 4_b leaves no member active and 4_b complete
function TestEvinChain4:test_losing_battle_4_starts_survival_4_b_after_five_seconds_and_never_battle_4_a()
	local player = chain(4)

	begin(player, E.M4[1])
	pump(5000, E.M4[1] .. " setup")
	failAndSplit(player, E.M4[1], E.M4[3], E.M4[2], 5)

	local q = quest(E.M4[3])
	local p = pointOf("space_dathomir", "naboo_rebel_tier4_4_b_survival")

	pump(8000, E.M4[3] .. " setup")
	lu.assertTrue(isActive(player, q), E.M4[3] .. ": still active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, E.M4[3] .. ": one waypoint at naboo_rebel_tier4_4_b_survival")
	q:completeQuest(player, true)
	pump(8000, E.M4[3] .. " completion")
	lu.assertTrue(isComplete(player, q), E.M4[3] .. ": the failure end is complete")
	noMemberActive(player, 4)
end

---------------------------------------------------------------------------------------------
-- A-5: the four duties and the same-name tables
---------------------------------------------------------------------------------------------

TestEvinDuties = {}

function TestEvinDuties:setUp() H.reset() end

function TestEvinDuties:tearDown() AC.tearDown() end

-- A-5: each duty global starts once, is reported active by type and name, starts no side quest and sets no <name>:* status key
function TestEvinDuties:test_each_duty_starts_once_is_active_by_type_and_starts_no_side_quest_and_sets_no_key()
	for _, global in ipairs(E.DUTIES) do
		local player = world({ global })
		local q = quest(global)
		local others = {}

		for _, g in ipairs(E.GLOBALS) do
			if g ~= global then
				others[g] = H.spyOn(quest(g), "startQuest")
			end
		end

		q:startQuest(player, "")
		pump(60000, global .. " running")
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, "naboo_rebel_tier4_1"), global .. ": reported active by SpaceHelpers:isSpaceQuestActive(type, name)")

		for g, calls in pairs(others) do
			lu.assertEquals(#calls, 0, global .. ": started " .. g .. " (a duty starts no side quest)")
		end

		lu.assertEquals(E.keysNamed(player, "naboo_rebel_tier4_1"), {}, global .. ": a duty run sets no <playerID>naboo_rebel_tier4_1:* key (I-10)")

		for _, other in ipairs(E.DUTIES) do
			if other ~= global then
				lu.assertFalse(isActive(player, quest(other)), global .. ": started " .. other)
			end
		end

		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "survival", "naboo_rebel_tier4_1"), global .. ": the same-name survival head is not active")
		H.restoreSpies()
	end
end

-- A-5, I-8, R-7: with survival 1 complete, starting then clearing the destroy duty leaves survival 1 complete
function TestEvinDuties:test_starting_and_clearing_the_destroy_duty_leaves_the_same_name_survival_complete()
	local player = world({ E.DUTIES[1] })

	E.setState(player, E.M1[1], "complete")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "survival", "naboo_rebel_tier4_1"), "precondition: survival 1 complete")
	quest(E.DUTIES[1]):startQuest(player, "")
	pump(2000, E.DUTIES[1] .. " start")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "destroy_duty", "naboo_rebel_tier4_1"), "the destroy duty is active")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "survival", "naboo_rebel_tier4_1"), "survival 1 stays complete while the duty is active")
	SpaceHelpers:clearSpaceQuest(player, "destroy_duty", "naboo_rebel_tier4_1", false)
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "destroy_duty", "naboo_rebel_tier4_1"), "the destroy duty is cleared")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "survival", "naboo_rebel_tier4_1"), "survival 1 stays complete after the duty is cleared")
end

-- A-5, I-8, R-7: with the escort duty active, failing survival 1 leaves the escort duty active
function TestEvinDuties:test_failing_survival_1_leaves_an_active_escort_duty_active()
	local player = world({ E.M1[1], E.DUTIES[2] }, "space_endor")

	H.spyOn(quest(E.M1[3]), "startQuest")
	begin(player, E.M1[1])
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "survival", "naboo_rebel_tier4_1"), "precondition: survival 1 active")
	E.setState(player, E.DUTIES[2], "active")
	quest(E.M1[1]):failQuest(player, "true")
	pump(500, E.M1[1] .. " failure")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "survival", "naboo_rebel_tier4_1"), "survival 1 no longer active")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "escort_duty", "naboo_rebel_tier4_1"), "the escort duty stays active (journal state is per type and name)")
end

-- A-5, I-8: the five same-name journal entries are independent: setting one changes no other
function TestEvinDuties:test_the_five_same_name_journal_entries_are_independent()
	local player = world({ E.M1[1] })
	local same = { E.M1[1], E.DUTIES[1], E.DUTIES[2], E.DUTIES[3], E.DUTIES[4] }

	for _, global in ipairs(same) do
		E.setState(player, global, "active")

		for _, other in ipairs(same) do
			local want = other == global and "active" or "none"

			lu.assertEquals(E.state(player, other), want, other .. ": journal state while only " .. global .. " is active")
			lu.assertEquals(SpaceHelpers:isSpaceQuestActive(player, E.IDENTITY[other].type, E.IDENTITY[other].name) == true, other == global,
				other .. ": SpaceHelpers:isSpaceQuestActive while only " .. global .. " is active")
		end

		E.setState(player, global, "none")
	end
end

return nil
