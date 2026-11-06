-- Storm tier 4 part A: Admiral Kilnstrider's four missions and four duties run through the fakes, split by split.
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (A-3, A-4; Data mapping 1; FA-2, FA-4; R-1).
--
-- The oracle values are the spec's literals (storm_tier4_data.lua, proven equal to the SWG .tab fixtures by test_storm_tier4_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and
-- pumps the split delay (the alert fires at the delay; the next quest starts at delay * 1.05). The three parent -> child pairs that are new to Core3
-- (space_battle -> inspect 1_b -> 1_c, recovery -> delivery 2_a -> 2_b, rescue -> space_battle 3_a -> 3_b) are shown to start nothing before the delay and the
-- child after it. The inspect step uses the cargo of the REAL ship template file (rebel_endscout_tier4), not a cargo set on the fake ship: the tier 2 tests did
-- that and missed a broken quest. Flying a space battle is covered by its type feature: this file stops at "active / spawned" for it. The hostility of the
-- real AI cannot be checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local D = require("storm_tier4_data")

D.load()

local function quest(global) return D.quest(global) end

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

local function pointOf(name)
	local p = D.POINTS[name] or D.SPAWNERS[name]

	assert(p ~= nil, "no spec point " .. name)
	return p
end

-- the active areas the quest spawned (static point areas are tagged with the quest's className)
local function areasOf(q)
	local n = 0

	for _, area in ipairs(H.spawnedAreas()) do
		if readData(area.objectID .. ":" .. q.className) ~= nil and readData(area.objectID .. ":" .. q.className) ~= 0 then
			n = n + 1
		end
	end

	return n
end

-- A fresh world with the static areas of every member of the chain, and the pilot in an Imperial ship in the chain's zone
local function chain(members, zone)
	H.reset()

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" or quest(global).questType == "recovery_duty" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return D.flyer(zone)
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Completes a member and pumps the split delay: the next member is not active at once nor 4 s after the completion (sideQuestDelay 5 s) and is active 7 s after it
-- (the alert fires at 5 s, the quest starts at 5 * 1.05 s)
local function completeAndSplit(player, global, nextGlobal)
	local q = quest(global)

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")

	if nextGlobal then
		local nq = quest(nextGlobal)

		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active at once after " .. global .. " completed")
		pump(4000, global .. " split delay")
		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active 4 s after " .. global .. " completed (sideQuestDelay 5 s)")
		pump(3000, global .. " split start")
		lu.assertTrue(isActive(player, nq), nextGlobal .. ": active 7 s after " .. global .. " completed")
	end
end

local function noMemberActive(player, members)
	for _, global in ipairs(members) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no member of the chain is active")
	end
end

local function spyShip(shipName, cargo, spawner, zone)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = zone or D.ZONE })
end

-- the cargo the server's ship template gives the ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FA-4)")

	return t.cargoString
end

-- Inspects and docks with a ship carrying the template's cargo
local function inspectAndDock(player, q, shipName, spawner)
	pump(2500, q.className .. " setup")

	local cargo = templateCargo(shipName)
	local target = spyShip(shipName, cargo, spawner)
	local hash = getHashCode(cargo)

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")
	H.inspect(player, target, hash)
	pump(0, q.className .. " inspect")
	H.dock(player, target, hash)
	pump(0, q.className .. " dock")
	pump(1000, q.className .. " after the dock")
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

-- Escort legs: startQuest in the zone, setupEscort (2 s), the start area, the escort ship (5 s) and its points (5 s later). Returns the escort ship.
local function flyEscort(q, player)
	q:startQuest(player, "")
	pump(2500, q.className .. " setup")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertTrue(start >= 1, q.className .. ": setupEscort chose a start point")
	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, q.className .. " escort spawn")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, q.className .. ": the escort ship spawned")

	return escort
end

---------------------------------------------------------------------------------------------
-- A-3 (a): mission 1, patrol, surprise attack, battle, inspect, delivery
---------------------------------------------------------------------------------------------

TestStormT4Chain1 = {}

function TestStormT4Chain1:setUp() H.reset() end

function TestStormT4Chain1:tearDown() AC.tearDown() end

-- A-3 (a): patrol 1 starts with four points; reaching point 3 completes it 20 s later and starts the surprise attack
function TestStormT4Chain1:test_patrol_1_has_four_points_and_reaching_point_3_ends_it_and_starts_surprise_1_a_20_seconds_later()
	local player = chain(D.M1)
	local q = begin(player, D.M1[1])
	local surprise = quest(D.M1[2])

	lu.assertEquals(areasOf(q), 4, D.M1[1] .. ": four patrol point areas")
	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, D.M1[1] .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, D.M1[1] .. " point 2")
	lu.assertTrue(isActive(player, q), D.M1[1] .. ": still active at point 2")
	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, D.M1[1] .. " point 3")
	pump(18000, D.M1[1] .. " 19 s after point 3")
	lu.assertFalse(isComplete(player, q), D.M1[1] .. ": not complete 19 s after point 3 (sideQuestDelay 20)")
	lu.assertFalse(isActive(player, surprise), D.M1[2] .. ": not active 19 s after point 3")
	pump(3500, D.M1[1] .. " 22.5 s after point 3")
	lu.assertTrue(isComplete(player, q), D.M1[1] .. ": complete 22.5 s after point 3 (point 4 is never flown)")
	lu.assertTrue(isActive(player, surprise), D.M1[2] .. ": surprise attack 1_a is active")
end

-- A-3 (a): the surprise attack spawns five A-wings in endor; destroying them completes it and starts the battle 5 s later
function TestStormT4Chain1:test_surprise_1_a_spawns_five_awings_and_destroying_them_starts_space_battle_1_b_five_seconds_later()
	local player = chain(D.M1)
	local q = begin(player, D.M1[2])

	pump(60000, D.M1[2] .. " attack")

	local ships = {}

	for i, ship in ipairs(H.spawnedShips()) do
		ships[i] = ship
	end

	local names = shipNames(ships)

	lu.assertEquals(countOf(names, "reb_awing_tier4"), 5, D.M1[2] .. ": reb_awing_tier4 among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 5, D.M1[2] .. ": nothing but the five A-wings")

	for _, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, D.ZONE, D.M1[2] .. ": " .. tostring(ship.shipName) .. " spawns in space_endor")
	end

	for _, ship in ipairs(ships) do
		H.destroyShip(ship, player.rootParent)
	end

	pump(0, D.M1[2] .. " all five destroyed")
	lu.assertTrue(isComplete(player, q), D.M1[2] .. ": complete once the five A-wings are destroyed")
	lu.assertFalse(isActive(player, quest(D.M1[3])), D.M1[3] .. ": not active at once")
	pump(4000, D.M1[2] .. " split delay")
	lu.assertFalse(isActive(player, quest(D.M1[3])), D.M1[3] .. ": not active 4 s after the last A-wing died (sideQuestDelay 5 s)")
	pump(3000, D.M1[2] .. " split start")
	lu.assertTrue(isActive(player, quest(D.M1[3])), D.M1[3] .. ": space battle 1_b is active 7 s after the last A-wing died")
end

-- A-3 (a), FA-2: completing space battle 1_b starts inspect 1_c 5 s later and not earlier (first battle -> inspect pair)
function TestStormT4Chain1:test_completing_space_battle_1_b_starts_inspect_1_c_five_seconds_later_and_not_earlier()
	local player = chain(D.M1)

	begin(player, D.M1[3])
	pump(5000, D.M1[3] .. " setup")
	lu.assertTrue(isActive(player, quest(D.M1[3])), D.M1[3] .. ": active")
	lu.assertFalse(isActive(player, quest(D.M1[4])), D.M1[4] .. ": not active while the battle runs")
	completeAndSplit(player, D.M1[3], D.M1[4])
	lu.assertFalse(isActive(player, quest(D.M1[5])), D.M1[5] .. ": the delivery is not started with the inspect")
end

-- A-3 (a): inspect 1_c gives exactly one waypoint, at the endscout spawner
function TestStormT4Chain1:test_inspect_1_c_gives_exactly_one_waypoint_at_the_endscout_spawner()
	local player = chain(D.M1)
	local s = pointOf("tatooine_imperial_tier4_endscout1")

	begin(player, D.M1[4])
	pump(2500, D.M1[4] .. " setup")
	lu.assertEquals(#player.ghost.waypoints, 1, D.M1[4] .. ": one waypoint")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, D.M1[4] .. ": the waypoint is at the spawner tatooine_imperial_tier4_endscout1")
end

-- A-3 (a), FA-4: inspecting and docking with the endscout carrying its template's cargo completes 1_c; delivery 1_d is active 5 s later
function TestStormT4Chain1:test_inspecting_the_endscout_with_its_templates_cargo_completes_1_c_and_starts_delivery_1_d_five_seconds_later()
	local player = chain(D.M1)
	local q = begin(player, D.M1[4])

	inspectAndDock(player, q, "rebel_endscout_tier4", "tatooine_imperial_tier4_endscout1")
	lu.assertEquals(templateCargo("rebel_endscout_tier4"), "rebel_battle_plans", "the template carries the inspect_cargo row rebel_battle_plans")
	lu.assertTrue(isComplete(player, q), D.M1[4] .. ": complete after docking with the endscout")
	lu.assertFalse(isActive(player, quest(D.M1[5])), D.M1[5] .. ": not active 1 s after the dock")
	pump(3000, D.M1[4] .. " split delay")
	lu.assertFalse(isActive(player, quest(D.M1[5])), D.M1[5] .. ": not active 4 s after the dock")
	pump(3000, D.M1[4] .. " split start")
	lu.assertTrue(isActive(player, quest(D.M1[5])), D.M1[5] .. ": active 7 s after the dock")
end

-- A-3 (a): a ship with another cargo does not complete it
function TestStormT4Chain1:test_a_ship_with_another_cargo_does_not_complete_inspect_1_c()
	local player = chain(D.M1)
	local q = begin(player, D.M1[4])

	pump(2500, D.M1[4] .. " setup")

	local target = spyShip("rebel_endscout_tier4", "stolen_data", "tatooine_imperial_tier4_endscout1")
	local hash = getHashCode("stolen_data")

	H.inspect(player, target, hash)
	pump(0, D.M1[4] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, D.M1[4] .. " dock")
	lu.assertFalse(isComplete(player, q), D.M1[4] .. ": not complete with the wrong cargo")
end

-- A-3 (a): delivery_no_pickup 1_d delivers at the delivery1 point; completing it leaves no mission 1 member active and the chain end complete
function TestStormT4Chain1:test_delivery_1_d_sets_up_at_its_point_and_completing_it_leaves_no_member_active_and_the_chain_end_complete()
	local player = chain(D.M1)

	for _, global in ipairs({ D.M1[1], D.M1[2], D.M1[3], D.M1[4] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M1[5])

	deliveryArea(D.M1[5])

	local p = pointOf("tatooine_imperial_tier4_delivery1")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M1[5] .. ": the delivery area (zone, x, z, y)")
	pump(10000, D.M1[5] .. " running")
	lu.assertTrue(isActive(player, q), D.M1[5] .. ": still active")
	completeAndSplit(player, D.M1[5], nil)
	pump(8000, D.M1[5] .. " after completion")
	noMemberActive(player, D.M1)
	lu.assertTrue(isComplete(player, q), D.M1[5] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-3 (b): mission 2, recovery, recovery, delivery, delivery (no pickup)
---------------------------------------------------------------------------------------------

TestStormT4Chain2 = {}

function TestStormT4Chain2:setUp() H.reset() end

function TestStormT4Chain2:tearDown() AC.tearDown() end

-- A-3 (b): recovery 2 spawns the Bothan Spynet shuttle with five escorts after its arrival delay (Core3 waits it twice)
function TestStormT4Chain2:test_recovery_2_spawns_the_spynet_shuttle_with_five_escorts_after_the_arrival_delay()
	local player = chain(D.M2)
	local q = begin(player, D.M2[1])

	pump(14000, D.M2[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, D.M2[1] .. ": nothing spawned 14 s after the start (arrivalDelay 30)")
	pump(51000, D.M2[1] .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, D.M2[1] .. ": the recovery ship was spawned")
	lu.assertEquals(ship.shipName, "bothan_spynet_shuttle_tier4", D.M2[1] .. ": the recovery ship")
	lu.assertEquals(ship.zone, D.ZONE, D.M2[1] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "bothan_spynet_shuttle_tier4"), 1, D.M2[1] .. ": one shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "bothan_spynet_fighter_tier4"), 5, D.M2[1] .. ": five fighter escorts among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 6, D.M2[1] .. ": the shuttle and five escorts")

	local p = pointOf("tatooine_imperial_tier4_recovery1_1")

	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, D.M2[1] .. ": one waypoint at the first pre-recovery point tatooine_imperial_tier4_recovery1_1")
end

-- A-3 (b): completing recovery 2 starts recovery 2_a 5 s later
function TestStormT4Chain2:test_completing_recovery_2_starts_recovery_2_a_five_seconds_later()
	local player = chain(D.M2)

	begin(player, D.M2[1])
	pump(60000, D.M2[1] .. " arrival")
	completeAndSplit(player, D.M2[1], D.M2[2])
end

-- A-3 (b), FA-2: completing recovery 2_a starts delivery 2_b 5 s later and not earlier (first recovery -> delivery pair)
function TestStormT4Chain2:test_completing_recovery_2_a_starts_delivery_2_b_five_seconds_later_and_not_earlier()
	local player = chain(D.M2)
	local q = begin(player, D.M2[2])

	pump(60000, D.M2[2] .. " arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "bothan_spynet_shuttle_tier4"), 1, D.M2[2] .. ": one shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "bothan_spynet_fighter_tier4"), 6, D.M2[2] .. ": six fighter escorts among " .. table.concat(names, ", "))
	lu.assertTrue(isActive(player, q), D.M2[2] .. ": active")
	lu.assertFalse(isActive(player, quest(D.M2[3])), D.M2[3] .. ": not active while the recovery runs")
	completeAndSplit(player, D.M2[2], D.M2[3])
end

-- A-3 (b): delivery 2_b picks up at pickup1 with the medium freighter and delivers with the light one; completing it starts delivery_no_pickup 2_c 5 s later
function TestStormT4Chain2:test_delivery_2_b_runs_pickup1_with_the_medium_freighter_and_hands_over_to_delivery_2_c_five_seconds_later()
	local player = chain(D.M2)

	begin(player, D.M2[3])

	local area = deliveryArea(D.M2[3])
	local p = pointOf("tatooine_imperial_tier4_pickup1")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M2[3] .. ": the pickup area (zone, x, z, y)")
	H.enterArea(area, player.rootParent)
	pump(8000, D.M2[3] .. " pickup arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "imp_freightermedium_tier4"), 1, D.M2[3] .. ": the pickup ship among " .. table.concat(names, ", "))
	completeAndSplit(player, D.M2[3], D.M2[4])
end

-- A-3 (b): delivery_no_pickup 2_c delivers at deliver2; completing it leaves no mission 2 member active and the chain end complete
function TestStormT4Chain2:test_delivery_2_c_sets_up_at_its_point_and_completing_it_leaves_no_member_active_and_the_chain_end_complete()
	local player = chain(D.M2)

	for _, global in ipairs({ D.M2[1], D.M2[2], D.M2[3] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M2[4])

	deliveryArea(D.M2[4])

	local p = pointOf("tatooine_imperial_tier4_deliver2")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M2[4] .. ": the delivery area (zone, x, z, y)")
	completeAndSplit(player, D.M2[4], nil)
	pump(8000, D.M2[4] .. " after completion")
	noMemberActive(player, D.M2)
	lu.assertTrue(isComplete(player, q), D.M2[4] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-4 (a): mission 3, escort, rescue, space battle
---------------------------------------------------------------------------------------------

TestStormT4Chain3 = {}

function TestStormT4Chain3:setUp() H.reset() end

function TestStormT4Chain3:tearDown() AC.tearDown() end

-- A-4 (a): escort 3 flies the inquisitor shuttle; completing it starts rescue 3_a 5 s later
function TestStormT4Chain3:test_escort_3_flies_the_inquisitor_shuttle_and_completing_it_starts_rescue_3_a_five_seconds_later()
	local player = chain(D.M3)
	local q = quest(D.M3[1])
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "imp_lambda_inquisitor_shuttle_tier4", D.M3[1] .. ": the escort ship")
	lu.assertEquals(escort.zone, D.ZONE, D.M3[1] .. ": the escort ship zone")
	lu.assertFalse(isActive(player, quest(D.M3[2])), D.M3[2] .. ": not active during the escort")
	completeAndSplit(player, D.M3[1], D.M3[2])
end

-- A-4 (a): a failed escort 3 starts nothing and leaves no mission 3 member active
function TestStormT4Chain3:test_a_failed_escort_3_starts_nothing_and_leaves_no_member_active()
	local player = chain(D.M3)
	local q = quest(D.M3[1])

	flyEscort(q, player)
	q:failQuest(player, "")
	pump(30000, D.M3[1] .. " after the failure")
	lu.assertFalse(isComplete(player, q), D.M3[1] .. ": not complete")
	noMemberActive(player, D.M3)

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.method, "startQuest", "a pending startQuest event of " .. tostring(e.screenplay) .. " after the failure")
	end
end

-- A-4 (a): rescue 3_a spawns the lambda shuttle after 30 s
function TestStormT4Chain3:test_rescue_3_a_spawns_the_lambda_shuttle_after_30_seconds()
	local player = chain(D.M3)

	begin(player, D.M3[2])
	pump(20000, D.M3[2] .. " before the arrival")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "imp_lambda_shuttle_tier4"), 0, D.M3[2] .. ": no shuttle 20 s after the start (targetArrivalDelay 30)")
	pump(20000, D.M3[2] .. " arrival")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "imp_lambda_shuttle_tier4") >= 1, D.M3[2] .. ": imp_lambda_shuttle_tier4 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
end

-- A-4 (a), FA-2: completing rescue 3_a starts space battle 3_b 5 s later and not earlier (first rescue -> battle pair)
function TestStormT4Chain3:test_completing_rescue_3_a_starts_space_battle_3_b_five_seconds_later_and_not_earlier()
	local player = chain(D.M3)

	begin(player, D.M3[2])
	pump(45000, D.M3[2] .. " arrival")
	lu.assertTrue(isActive(player, quest(D.M3[2])), D.M3[2] .. ": active")
	lu.assertFalse(isActive(player, quest(D.M3[3])), D.M3[3] .. ": not active while the rescue runs")
	completeAndSplit(player, D.M3[2], D.M3[3])
end

-- A-4 (a): space battle 3_b is the chain end; completing it leaves no mission 3 member active and the end complete
function TestStormT4Chain3:test_space_battle_3_b_is_active_and_completing_it_makes_the_chain_end_complete()
	local player = chain(D.M3)

	for _, global in ipairs({ D.M3[1], D.M3[2] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M3[3])

	pump(5000, D.M3[3] .. " setup")
	lu.assertTrue(isActive(player, q), D.M3[3] .. ": active")
	q:completeQuest(player, true)
	pump(8000, D.M3[3] .. " completion")
	lu.assertTrue(isComplete(player, q), D.M3[3] .. ": the chain end is complete")
	noMemberActive(player, D.M3)
end

---------------------------------------------------------------------------------------------
-- A-4 (b): mission 4 in Dantooine
---------------------------------------------------------------------------------------------

TestStormT4Chain4 = {}

function TestStormT4Chain4:setUp() H.reset() end

function TestStormT4Chain4:tearDown() AC.tearDown() end

local function deployed(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

-- A-4 (b): assassinate 4 spawns the shuttle target and six fighters in Dantooine at the first point; completing it starts 4_a 5 s later
function TestStormT4Chain4:test_assassinate_4_spawns_the_target_and_six_escorts_in_dantooine_and_completing_it_starts_4_a_five_seconds_later()
	local player = chain(D.M4, D.ZONE_M4)
	local ships = deployed(player, D.M4[1], 40000)
	local p = pointOf("tatooine_imperial_tier4_assassinate1_1")

	lu.assertEquals(shipNames(ships), { "bothan_spynet_shuttle_tier4", "bothan_spynet_fighter_tier4", "bothan_spynet_fighter_tier4", "bothan_spynet_fighter_tier4",
		"bothan_spynet_fighter_tier4", "bothan_spynet_fighter_tier4", "bothan_spynet_fighter_tier4" }, D.M4[1] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, D.M4[1] .. ": the target spawns at targetPatrols[1] (tatooine_imperial_tier4_assassinate1_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, D.ZONE_M4, D.M4[1] .. ": ship " .. i .. " zone")
	end

	completeAndSplit(player, D.M4[1], D.M4[2])
end

-- A-4 (b): assassinate 4_a spawns at assassinate2_1 and completing it starts recovery 4_b 5 s later
function TestStormT4Chain4:test_assassinate_4_a_spawns_at_assassinate2_1_and_completing_it_starts_recovery_4_b_five_seconds_later()
	local player = chain(D.M4, D.ZONE_M4)
	local ships = deployed(player, D.M4[2], 40000)
	local p = pointOf("tatooine_imperial_tier4_assassinate2_1")

	lu.assertEquals(#ships, 7, D.M4[2] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, D.M4[2] .. ": the target spawns at targetPatrols[1] (tatooine_imperial_tier4_assassinate2_1)")
	completeAndSplit(player, D.M4[2], D.M4[3])
end

-- A-4 (b): recovery 4_b spawns the shuttle with seven escorts in Dantooine; completing it starts assassinate 4_c 5 s later
function TestStormT4Chain4:test_recovery_4_b_spawns_the_shuttle_with_seven_escorts_and_completing_it_starts_assassinate_4_c_five_seconds_later()
	local player = chain(D.M4, D.ZONE_M4)
	local q = begin(player, D.M4[3])

	pump(60000, D.M4[3] .. " arrival")

	local names = shipNames(H.spawnedShips())
	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, D.M4[3] .. ": the recovery ship was spawned")
	lu.assertEquals(ship.zone, D.ZONE_M4, D.M4[3] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "bothan_spynet_shuttle_tier4"), 1, D.M4[3] .. ": one shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "bothan_spynet_fighter_tier4"), 7, D.M4[3] .. ": seven fighter escorts among " .. table.concat(names, ", "))
	completeAndSplit(player, D.M4[3], D.M4[4])
end

-- A-4 (b): assassinate 4_c spawns the command vessel with eleven escorts; killing the vessel alone does not complete it, killing all twelve does; the end
-- leaves no mission 4 member active
function TestStormT4Chain4:test_assassinate_4_c_spawns_the_command_vessel_with_eleven_escorts_and_must_destroy_them_all()
	local player = chain(D.M4, D.ZONE_M4)

	for _, global in ipairs({ D.M4[1], D.M4[2], D.M4[3] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M4[4])

	pump(28000, D.M4[4] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, D.M4[4] .. ": nothing spawned 28 s after the start (arrivalDelay 30)")
	pump(10000, D.M4[4] .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	local names = shipNames(ships)

	lu.assertEquals(names[1], "rebel_command_vessel_tier4", D.M4[4] .. ": the target first")
	lu.assertEquals(#names, 12, D.M4[4] .. ": the target and eleven escorts")
	lu.assertEquals(countOf(names, "reb_xwing_tier4"), 3, D.M4[4] .. ": three X-wings")
	lu.assertEquals(countOf(names, "reb_bwing_tier3"), 3, D.M4[4] .. ": three B-wings")
	lu.assertEquals(countOf(names, "reb_ywing_tier4"), 3, D.M4[4] .. ": three Y-wings")
	lu.assertEquals(countOf(names, "rebel_command_vessel_weak_tier2"), 2, D.M4[4] .. ": two weak command vessels")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, D.M4[4] .. " after the vessel is destroyed")
	lu.assertFalse(isComplete(player, q), D.M4[4] .. ": not complete with the escorts alive (mustDestroyEscort)")

	for i = 2, #ships do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, D.M4[4] .. " after ship " .. i)
	end

	pump(8000, D.M4[4] .. " after all twelve are destroyed")
	lu.assertTrue(isComplete(player, q), D.M4[4] .. ": the chain end is complete")
	noMemberActive(player, D.M4)
end

---------------------------------------------------------------------------------------------
-- A-4 (c): the four duties
---------------------------------------------------------------------------------------------

TestStormT4Duties = {}

function TestStormT4Duties:setUp() H.reset() end

function TestStormT4Duties:tearDown() AC.tearDown() end

-- A-4 (c): each duty global starts once, is reported active, and starts no side quest
function TestStormT4Duties:test_each_duty_starts_once_is_active_and_starts_no_side_quest()
	for _, global in ipairs(D.DUTIES) do
		local player = chain({ global })
		local q = quest(global)
		local others = {}

		for _, g in ipairs(D.GLOBALS) do
			if g ~= global then
				others[g] = H.spyOn(quest(g), "startQuest")
			end
		end

		q:startQuest(player, "")
		pump(60000, global .. " running")
		lu.assertTrue(isActive(player, q), global .. ": reported active by SpaceHelpers:isSpaceQuestActive")

		for g, calls in pairs(others) do
			lu.assertEquals(#calls, 0, global .. ": started " .. g .. " (a duty starts no side quest)")
		end

		H.restoreSpies()
	end
end

return nil
