-- Storm tier 3 part A: Captain Denner's four missions run through the fakes, split by split.
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (A-4, A-5; Data mapping 1; FD-3, FD-9; FD-5 withdrawn by Amendment A-2; R-7, R-9).
--
-- The oracle values are the spec's literals (storm_tier3_data.lua, proven equal to the SWG .tab fixtures by test_storm_tier3_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside
-- an event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own
-- completeQuest and pumps the split delay (the alert fires at the delay; the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL
-- ship template files (rebel_scout_fighter_tier3, rebel_scout_shuttle_tier3, rebel_command_shuttle_tier4), not a cargo set on the fake ship: the tier 2 tests
-- did that and missed a broken quest. Flying the survival and the battle is covered by their type features: this file stops at "active / spawned" for them.
-- The escort wave split itself (3 cleared waves, arrival rules, counter) is test_storm_tier3_missions_escort_wave.lua. The hostility of the real AI cannot
-- be checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local D = require("storm_tier3_data")

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

-- A fresh world with the static areas of every member of the mission's chain, and the pilot in an Imperial ship in space_endor
local function chain(n)
	H.reset()

	local members = D.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return D.flyer()
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Completes a member and pumps the split delay: the next member is not active just before the delay (`seconds`) and is active 2 s after the 5 % margin
local function completeAndSplit(player, global, nextGlobal, seconds)
	local q = quest(global)

	seconds = seconds or 5

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")

	if nextGlobal then
		local nq = quest(nextGlobal)

		pump((seconds - 1) * 1000, global .. " split delay")
		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active " .. (seconds - 1) .. " s after " .. global .. " completed (sideQuestDelay " .. seconds .. " s)")
		pump(3000, global .. " split start")
		lu.assertTrue(isActive(player, nq), nextGlobal .. ": active " .. (seconds + 2) .. " s after " .. global .. " completed")
	end
end

local function noMemberActive(player, n)
	for _, global in ipairs(D.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

local function spyShip(shipName, cargo, spawner)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = D.ZONE })
end

-- the cargo the server's ship template gives the ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FD-9)")

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

local function arrive(q, escort)
	local progress = readData(escort.objectID .. ":" .. q.className .. ":escortShipProgress:")

	for _ = 1, progress do
		H.enterArea(H.spawnedAreas()[1], escort)
	end
end

-- Waits for the next attack wave of an escort and destroys it; returns the number of its ships
local function clearNextWave(q, player)
	local before = #H.spawnedShips()

	for _ = 1, 130 do
		pump(1000, q.className .. " waiting for an attack wave")

		if #H.spawnedShips() > before then
			break
		end
	end

	local wave = {}

	for i = before + 1, #H.spawnedShips() do
		wave[#wave + 1] = H.spawnedShips()[i]
	end

	lu.assertTrue(#wave > 0, q.className .. ": an attack wave spawned")

	for _, ship in ipairs(wave) do
		H.destroyShip(ship, player.rootParent)
	end

	pump(0, q.className .. " wave cleared")

	return #wave
end

local function killsOf(player, shipName, count)
	for _ = 1, count do
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = shipName, zone = D.ZONE }))
	end
end

---------------------------------------------------------------------------------------------
-- A-4 (a): mission 1, escort and recovery
---------------------------------------------------------------------------------------------

TestStormT3Chain1 = {}

function TestStormT3Chain1:setUp() H.reset() end

function TestStormT3Chain1:tearDown() AC.tearDown() end

-- A-4 (a): started on the ground, nothing is set up until the pilot enters space_endor, then the engineer shuttle spawns
function TestStormT3Chain1:test_escort_1_started_on_the_ground_sets_nothing_up_until_endor_and_then_spawns_the_engineer_shuttle()
	chain(1)

	local q = quest(D.M1[1])
	local player = H.newPlayer({ zone = "tatooine", pilot = "imperial", parent = "starport" })

	q:startQuest(player, "")
	pump(5000, D.M1[1] .. " on the ground")
	lu.assertTrue(isActive(player, q), D.M1[1] .. ": active (the journal entry starts at once)")
	lu.assertEquals(#player.ghost.waypoints, 0, D.M1[1] .. ": no rendezvous waypoint on the ground")
	lu.assertEquals(#H.spawnedShips(), 0, D.M1[1] .. ": no ship on the ground")

	H.zoneSwitch(player, D.ZONE, { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") } })
	pump(5000, D.M1[1] .. " entered space_endor")
	lu.assertEquals(#player.ghost.waypoints, 1, D.M1[1] .. ": the rendezvous waypoint after entering space_endor")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(6000, D.M1[1] .. " escort spawn")
	lu.assertEquals(shipNames(H.spawnedShips()), { "imp_engineer_shuttle_tier3" }, D.M1[1] .. ": the escort ship")
	lu.assertEquals(H.spawnedShips()[1].zone, D.ZONE, D.M1[1] .. ": the escort ship zone")
end

-- A-4 (a), A-2 amendment (R-1), R-9: completing escort 1 starts recovery 1_a after the 20 s split delay (triggerDelay 15 + 5)
function TestStormT3Chain1:test_completing_escort_1_starts_recovery_1_a_after_twenty_seconds()
	local player = chain(1)
	local q = quest(D.M1[1])
	local recovery = quest(D.M1[2])

	flyEscort(q, player)
	lu.assertFalse(isActive(player, recovery), D.M1[2] .. ": not active during the escort")
	q:completeQuest(player, true)
	pump(0, D.M1[1] .. " completion")
	lu.assertTrue(isComplete(player, q), D.M1[1] .. ": complete")
	lu.assertFalse(isActive(player, recovery), D.M1[2] .. ": not active at once (R-1: SWG splits 20 s after completion)")
	pump(19000, D.M1[1] .. " split delay")
	lu.assertFalse(isActive(player, recovery), D.M1[2] .. ": not active 19 s after completion (sideQuestDelay 20)")
	pump(3000, D.M1[1] .. " split start")
	lu.assertTrue(isActive(player, recovery), D.M1[2] .. ": active 22 s after completion")
end

-- A-4 (a): the escort reaching its last point completes it and hands over to recovery 1_a after the 20 s split delay
function TestStormT3Chain1:test_escort_1_reaching_its_last_point_completes_and_hands_over_to_recovery_1_a()
	local player = chain(1)
	local q = quest(D.M1[1])
	local escort = flyEscort(q, player)

	arrive(q, escort)
	pump(2600, D.M1[1] .. " arrival")
	lu.assertTrue(isComplete(player, q), D.M1[1] .. ": complete after the escort reached its last point")
	pump(22000, D.M1[1] .. " split delay")
	lu.assertTrue(isActive(player, quest(D.M1[2])), D.M1[2] .. ": active after the 20 s split delay")
end

-- A-4 (a): recovery 1_a spawns the rebel shuttle with five escorts after its arrival delay (Core3 waits it twice)
function TestStormT3Chain1:test_recovery_1_a_spawns_the_controlled_shuttle_with_five_escorts_after_the_arrival_delay()
	local player = chain(1)
	local q = begin(player, D.M1[2])

	pump(14000, D.M1[2] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, D.M1[2] .. ": nothing spawned 14 s after the start (arrivalDelay 30)")
	pump(51000, D.M1[2] .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, D.M1[2] .. ": the recovery ship was spawned")
	lu.assertEquals(ship.shipName, "rebel_controlled_shuttle_tier3", D.M1[2] .. ": the recovery ship")
	lu.assertEquals(ship.zone, D.ZONE, D.M1[2] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "rebel_controlled_shuttle_tier3"), 1, D.M1[2] .. ": one shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_awing_tier3"), 4, D.M1[2] .. ": four A-wing escorts among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_bwing_tier3"), 1, D.M1[2] .. ": one B-wing escort among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 6, D.M1[2] .. ": the shuttle and five escorts")

	local p = pointOf("tatooine_imperial_tier3_recovery1_1")

	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, D.M1[2] .. ": one waypoint at the first pre-recovery point tatooine_imperial_tier3_recovery1_1")
end

-- A-4 (b): completing recovery 1_a starts inspect 1_b 5 s later; its one waypoint is at the rebel scout spawner
function TestStormT3Chain1:test_completing_recovery_1_a_starts_inspect_1_b_5_seconds_later_with_one_waypoint_at_the_scout_spawner()
	local player = chain(1)
	local s = pointOf("tatooine_imperial_tier3_rebscout_spawner")

	begin(player, D.M1[2])
	pump(60000, D.M1[2] .. " arrival")
	completeAndSplit(player, D.M1[2], D.M1[3])
	pump(2500, D.M1[3] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, D.M1[3] .. ": one waypoint at the spawner tatooine_imperial_tier3_rebscout_spawner")
end

-- A-4 (b), FD-9: inspecting and docking with the scout fighter carrying its template's cargo completes 1_b; rescue 1_c follows
function TestStormT3Chain1:test_inspecting_the_rebel_scout_fighter_with_its_templates_cargo_completes_1_b_and_starts_rescue_1_c()
	local player = chain(1)
	local q = begin(player, D.M1[3])

	inspectAndDock(player, q, "rebel_scout_fighter_tier3", "tatooine_imperial_tier3_rebscout_spawner")
	lu.assertEquals(templateCargo("rebel_scout_fighter_tier3"), "encrypted_rebel_data", "the template carries the inspect_cargo row encrypted_rebel_data")
	lu.assertTrue(isComplete(player, q), D.M1[3] .. ": complete after docking with the scout fighter")
	pump(3000, D.M1[3] .. " split delay")
	lu.assertFalse(isActive(player, quest(D.M1[4])), "rescue 1_c is not active 4 s after the dock")
	pump(3000, D.M1[3] .. " split start")
	lu.assertTrue(isActive(player, quest(D.M1[4])), "rescue 1_c is active 7 s after the dock")
end

-- A-4 (b): a ship with another cargo does not complete it
function TestStormT3Chain1:test_a_ship_with_another_cargo_does_not_complete_inspect_1_b()
	local player = chain(1)
	local q = begin(player, D.M1[3])

	pump(2500, D.M1[3] .. " setup")

	local target = spyShip("rebel_scout_fighter_tier3", "stolen_data", "tatooine_imperial_tier3_rebscout_spawner")
	local hash = getHashCode("stolen_data")

	H.inspect(player, target, hash)
	pump(0, D.M1[3] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, D.M1[3] .. " dock")
	lu.assertFalse(isComplete(player, q), D.M1[3] .. ": not complete with the wrong cargo")
end

-- A-4 (b): rescue 1_c spawns the freighter after 30 s; completing it starts delivery_no_pickup 1_d
function TestStormT3Chain1:test_rescue_1_c_spawns_the_light_freighter_after_30_seconds_and_completing_it_starts_delivery_1_d()
	local player = chain(1)

	begin(player, D.M1[4])
	pump(20000, D.M1[4] .. " before the arrival")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "imp_freighterlight_tier3"), 0, D.M1[4] .. ": no freighter 20 s after the start (targetArrivalDelay 30)")
	pump(20000, D.M1[4] .. " arrival")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "imp_freighterlight_tier3") >= 1, D.M1[4] .. ": imp_freighterlight_tier3 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, D.M1[4], D.M1[5])
end

-- A-4 (b): delivery_no_pickup 1_d delivers at the headquarters spawner; completing it leaves no mission 1 member active
function TestStormT3Chain1:test_delivery_1_d_sets_up_at_the_hq_point_and_completing_it_leaves_no_member_active_and_the_chain_end_complete()
	local player = chain(1)

	for _, global in ipairs({ D.M1[1], D.M1[2], D.M1[3], D.M1[4] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M1[5])

	deliveryArea(D.M1[5])

	local p = pointOf("tatooine_imperial_tier3_delivery1_hq_spawner")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M1[5] .. ": the delivery area (zone, x, z, y)")
	pump(10000, D.M1[5] .. " running")
	lu.assertTrue(isActive(player, q), D.M1[5] .. ": still active")
	completeAndSplit(player, D.M1[5], nil)
	pump(8000, D.M1[5] .. " after completion")
	noMemberActive(player, 1)
	lu.assertTrue(isComplete(player, q), D.M1[5] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-4 (c): mission 2
---------------------------------------------------------------------------------------------

TestStormT3Chain2 = {}

function TestStormT3Chain2:setUp() H.reset() end

function TestStormT3Chain2:tearDown() AC.tearDown() end

-- A-4 (c), FD-9: inspect 2 at its own spawner; the split to surprise 2_a takes 10 s (triggerDelay 5 + 5)
function TestStormT3Chain2:test_inspect_2_completes_with_the_scout_fighters_cargo_and_starts_surprise_2_a_ten_seconds_later()
	local player = chain(2)
	local q = begin(player, D.M2[1])
	local s = pointOf("tatooine_imperial_tier3_inspect2_spawner")

	pump(2500, D.M2[1] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, D.M2[1] .. ": one waypoint at the spawner tatooine_imperial_tier3_inspect2_spawner")
	inspectAndDock(player, q, "rebel_scout_fighter_tier3", "tatooine_imperial_tier3_inspect2_spawner")
	lu.assertTrue(isComplete(player, q), D.M2[1] .. ": complete after docking with the scout fighter")
	pump(5000, D.M2[1] .. " 6 s after the dock")
	lu.assertFalse(isActive(player, quest(D.M2[2])), "surprise 2_a is not active 6 s after the dock (the split is 10 s, not 5)")
	pump(3000, D.M2[1] .. " 9 s after the dock")
	lu.assertFalse(isActive(player, quest(D.M2[2])), "surprise 2_a is not active 9 s after the dock")
	pump(3500, D.M2[1] .. " 12.5 s after the dock")
	lu.assertTrue(isActive(player, quest(D.M2[2])), "surprise 2_a is active 12.5 s after the dock")
end

-- A-4 (c): the surprise attack spawns five A-wings; completing it starts inspect 2_b
function TestStormT3Chain2:test_surprise_2_a_spawns_five_awings_in_endor_and_completing_it_starts_inspect_2_b()
	local player = chain(2)

	begin(player, D.M2[2])
	pump(60000, D.M2[2] .. " attack")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "reb_awing_tier3"), 5, D.M2[2] .. ": reb_awing_tier3 among " .. table.concat(names, ", "))

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, D.ZONE, D.M2[2] .. ": " .. tostring(ship.shipName) .. " spawns in space_endor")
	end

	completeAndSplit(player, D.M2[2], D.M2[3])
end

-- A-4 (c), FD-9, R-7: inspect 2_b with the scout shuttle's real cargo (rebel_plans); the split takes 10 s
function TestStormT3Chain2:test_inspect_2_b_completes_with_the_scout_shuttles_cargo_and_starts_delivery_2_c_ten_seconds_later()
	local player = chain(2)
	local q = begin(player, D.M2[3])
	local s = pointOf("tatooine_imperial_tier3_inspect3_spawner")

	pump(2500, D.M2[3] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, D.M2[3] .. ": one waypoint at the spawner tatooine_imperial_tier3_inspect3_spawner")
	inspectAndDock(player, q, "rebel_scout_shuttle_tier3", "tatooine_imperial_tier3_inspect3_spawner")
	lu.assertEquals(templateCargo("rebel_scout_shuttle_tier3"), "rebel_plans", "the template carries the inspect_cargo row rebel_plans")
	lu.assertTrue(isComplete(player, q), D.M2[3] .. ": complete after docking with the shuttle")
	pump(8000, D.M2[3] .. " 9 s after the dock")
	lu.assertFalse(isActive(player, quest(D.M2[4])), "delivery 2_c is not active 9 s after the dock (the split is 10 s)")
	pump(3500, D.M2[3] .. " 12.5 s after the dock")
	lu.assertTrue(isActive(player, quest(D.M2[4])), "delivery 2_c is active 12.5 s after the dock")
end

-- A-4 (c): delivery_no_pickup 2_c delivers at its own point; completing it starts patrol 2_d
function TestStormT3Chain2:test_delivery_2_c_sets_up_at_its_point_and_completing_it_starts_patrol_2_d()
	local player = chain(2)

	begin(player, D.M2[4])
	deliveryArea(D.M2[4])

	local p = pointOf("tatooine_imperial_tier3_delivery2")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M2[4] .. ": the delivery area (zone, x, z, y)")
	completeAndSplit(player, D.M2[4], D.M2[5])
end

-- A-4 (c): patrol 2_d; reaching point 3 completes it 20 s later and starts the space battle
function TestStormT3Chain2:test_reaching_patrol_point_3_completes_patrol_2_d_20_seconds_later_and_starts_the_space_battle()
	local player = chain(2)
	local q = begin(player, D.M2[5])
	local battle = quest(D.M2[6])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, D.M2[5] .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, D.M2[5] .. " point 2")
	lu.assertTrue(isActive(player, q), D.M2[5] .. ": still active at point 2")
	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, D.M2[5] .. " point 3")
	pump(18000, D.M2[5] .. " 19 s after point 3")
	lu.assertFalse(isComplete(player, q), D.M2[5] .. ": not complete 19 s after point 3 (sideQuestDelay 20)")
	lu.assertFalse(isActive(player, battle), D.M2[6] .. ": not active 19 s after point 3")
	pump(3500, D.M2[5] .. " 22.5 s after point 3")
	lu.assertTrue(isComplete(player, q), D.M2[5] .. ": complete 22.5 s after point 3 (point 4 is never flown)")
	lu.assertTrue(isActive(player, battle), D.M2[6] .. ": the space battle is active")
end

-- A-4 (c): the battle is the chain end; completing it wins mission 2 with no member active
function TestStormT3Chain2:test_space_battle_2_e_is_active_and_completing_it_makes_the_chain_end_complete()
	local player = chain(2)

	for _, global in ipairs({ D.M2[1], D.M2[2], D.M2[3], D.M2[4], D.M2[5] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M2[6])

	pump(5000, D.M2[6] .. " setup")
	lu.assertTrue(isActive(player, q), D.M2[6] .. ": active")
	q:completeQuest(player, true)
	pump(8000, D.M2[6] .. " completion")
	lu.assertTrue(isComplete(player, q), D.M2[6] .. ": the chain end is complete")
	noMemberActive(player, 2)
end

---------------------------------------------------------------------------------------------
-- A-5 (a): mission 3
---------------------------------------------------------------------------------------------

TestStormT3Chain3 = {}

function TestStormT3Chain3:setUp() H.reset() end

function TestStormT3Chain3:tearDown() AC.tearDown() end

-- A-5 (a): delivery 3 runs in endor and completing it starts destroy 3_b
function TestStormT3Chain3:test_delivery_3_runs_in_endor_and_completing_it_starts_destroy_3_b()
	local player = chain(3)

	begin(player, D.M3[1])
	deliveryArea(D.M3[1])

	local p = pointOf("tatooine_imperial_tier3_delivery3_pickup")

	lu.assertEquals(lastAreaCall(), { D.ZONE, p[1], p[2], p[3] }, D.M3[1] .. ": the pickup area (zone, x, z, y)")
	completeAndSplit(player, D.M3[1], D.M3[2])
end

-- A-5 (a): five kills of the table's Rebel types complete destroy 3_b and start escort 3_a
function TestStormT3Chain3:test_five_kills_of_listed_rebel_types_complete_destroy_3_b_and_start_the_escort()
	local player = chain(3)
	local q = begin(player, D.M3[2])
	local escort = quest(D.M3[3])

	H.zoneSwitch(player, D.ZONE)
	pump(500, D.M3[2] .. " zone entry")
	lu.assertEquals(#player.ghost.waypoints, 0, D.M3[2] .. ": no waypoints (giveSpawnWaypoint 0, no spawner)")

	local types = quest(D.M3[2]).shipTypes

	lu.assertEquals(#types, 10, D.M3[2] .. ": ten listed types")

	for kill = 1, 5 do
		lu.assertFalse(isComplete(player, q), D.M3[2] .. ": not complete before kill " .. kill)
		killsOf(player, types[kill * 2 - 1], 1) -- five different listed types
		pump(1500, D.M3[2] .. " after kill " .. kill)
	end

	lu.assertTrue(isComplete(player, q), D.M3[2] .. ": complete after 5 kills of listed types")
	pump(4000, D.M3[2] .. " split")
	lu.assertTrue(isActive(player, escort), D.M3[3] .. ": the escort starts after the split")
end

-- A-5 (a): a kill of another type does not count
function TestStormT3Chain3:test_kills_of_unlisted_ships_do_not_count_for_destroy_3_b()
	local player = chain(3)
	local q = begin(player, D.M3[2])

	H.zoneSwitch(player, D.ZONE)
	pump(500, D.M3[2] .. " zone entry")
	killsOf(player, "reb_ykl37r_tier3", 6)
	killsOf(player, "imp_tie_interceptor_tier3", 6)
	pump(1500, D.M3[2] .. " after twelve unlisted kills")
	lu.assertFalse(isComplete(player, q), D.M3[2] .. ": twelve kills of ships the table does not list complete nothing")
	killsOf(player, "reb_xwing_tier3", 4)
	pump(1500, D.M3[2] .. " after four listed kills")
	lu.assertFalse(isComplete(player, q), D.M3[2] .. ": four listed kills are not enough")
	killsOf(player, "reb_z95_tier4", 1)
	pump(1500, D.M3[2] .. " after five listed kills")
	lu.assertTrue(isComplete(player, q), D.M3[2] .. ": the fifth listed kill completes it (the unlisted ones did not count)")
end

-- A-5 (a): three cleared waves of escort 3_a start surprise 3_d, which spawns six A-wings and starts survival 3_c
function TestStormT3Chain3:test_three_cleared_waves_start_surprise_3_d_with_six_awings_and_then_survival_3_c()
	local player = chain(3)
	local q = quest(D.M3[3])
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "imp_lambda_decoy_shuttle_tier3", D.M3[3] .. ": the decoy shuttle")

	for _ = 1, 3 do
		clearNextWave(q, player)
	end

	local before = #H.spawnedShips() -- the escort and the attack waves; everything after is the surprise attack's

	pump(12000, D.M3[3] .. " the hand-off")
	lu.assertTrue(isComplete(player, q), D.M3[3] .. ": complete after the hand-off")
	lu.assertTrue(isActive(player, quest(D.M3[4])), D.M3[4] .. ": active")
	pump(60000, D.M3[4] .. " attack")

	local names = {}

	for i = before + 1, #H.spawnedShips() do
		names[#names + 1] = H.spawnedShips()[i].shipName
	end

	lu.assertEquals(countOf(names, "reb_awing_tier3"), 6, D.M3[4] .. ": reb_awing_tier3 among " .. table.concat(names, ", "))
	completeAndSplit(player, D.M3[4], D.M3[5])
end

-- A-5 (a): survival 3_c gives a waypoint at its point; completing it makes the chain end complete
function TestStormT3Chain3:test_survival_3_c_is_active_at_its_point_and_completing_it_makes_the_chain_end_complete()
	local player = chain(3)

	for _, global in ipairs({ D.M3[1], D.M3[2], D.M3[3], D.M3[4] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M3[5])
	local p = pointOf("tatooine_imperial_tier3_survival1")

	pump(5000, D.M3[5] .. " start")
	lu.assertTrue(isActive(player, q), D.M3[5] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, D.M3[5] .. ": one waypoint at tatooine_imperial_tier3_survival1")
	completeAndSplit(player, D.M3[5], nil)
	pump(8000, D.M3[5] .. " after completion")
	noMemberActive(player, 3)
	lu.assertTrue(isComplete(player, q), D.M3[5] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-5 (b): mission 4
---------------------------------------------------------------------------------------------

TestStormT3Chain4 = {}

function TestStormT3Chain4:setUp() H.reset() end

function TestStormT3Chain4:tearDown() AC.tearDown() end

local function deployedShips(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

-- A-5 (b): assassinate 4 spawns the X-wing target and five escorts after 15 s at the first point
function TestStormT3Chain4:test_assassinate_4_spawns_a_target_and_five_xwing_escorts_after_15_seconds()
	local player = chain(4)

	begin(player, D.M4[1])
	pump(14000, D.M4[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, D.M4[1] .. ": nothing spawned 14 s after the start (arrivalDelay 15)")
	pump(3000, D.M4[1] .. " deployTargets")

	local ships = H.spawnedShips()
	local p = pointOf("tatooine_imperial_tier3_assassinate4_01")

	lu.assertEquals(shipNames(ships), { "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3" }, D.M4[1] .. ": the target and five escorts")
	lu.assertTrue(ships[1].isSquadronLeader, D.M4[1] .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, D.M4[1] .. ": the target spawns at targetPatrols[1] (tatooine_imperial_tier3_assassinate4_01)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, D.ZONE, D.M4[1] .. ": ship " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, D.M4[1] .. ": ship " .. i .. " belongs to the pilot")
	end
end

-- A-5 (b): mustDestroyEscort: the target alone does not complete it, all six ships do
function TestStormT3Chain4:test_killing_only_the_target_does_not_complete_assassinate_4_and_killing_all_six_does()
	local player = chain(4)
	local q = quest(D.M4[1])
	local ships = deployedShips(player, D.M4[1], 17000)

	lu.assertEquals(#ships, 6, D.M4[1] .. ": precondition: target and five escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, D.M4[1] .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), D.M4[1] .. ": not complete with the escorts alive")
	lu.assertTrue(isActive(player, q), D.M4[1] .. ": still active")

	for i = 2, 6 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, D.M4[1] .. " after ship " .. i)
	end

	pump(3000, D.M4[1] .. " after all six are destroyed")
	lu.assertTrue(isComplete(player, q), D.M4[1] .. ": complete after the target and all five escorts are destroyed")
	pump(5000, D.M4[1] .. " split")
	lu.assertTrue(isActive(player, quest(D.M4[2])), D.M4[2] .. ": rescue 4_a starts after the split")
end

-- A-5 (b): rescue 4_a has no arrival delay (targetArrivalDelay 0): the lambda shuttle is there well before rescue 1_c's 30 s
function TestStormT3Chain4:test_rescue_4_a_spawns_the_lambda_shuttle_without_an_arrival_delay_and_completing_it_starts_inspect_4_b()
	local player = chain(4)

	begin(player, D.M4[2])
	pump(10000, D.M4[2] .. " start")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "imp_lambda_shuttle_tier3") >= 1, D.M4[2] .. ": imp_lambda_shuttle_tier3 spawned within 10 s; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, D.M4[2], D.M4[3])
end

-- A-5 (b), FD-9: inspect 4_b with the command shuttle's real cargo (stolen_data); assassinate 4_c follows
function TestStormT3Chain4:test_inspect_4_b_completes_with_the_command_shuttles_cargo_and_starts_assassinate_4_c()
	local player = chain(4)
	local q = begin(player, D.M4[3])
	local s = pointOf("tatooine_imperial_tier3_inspect4_spawner")

	pump(2500, D.M4[3] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, D.M4[3] .. ": one waypoint at the spawner tatooine_imperial_tier3_inspect4_spawner")
	inspectAndDock(player, q, "rebel_command_shuttle_tier4", "tatooine_imperial_tier3_inspect4_spawner")
	lu.assertEquals(templateCargo("rebel_command_shuttle_tier4"), "stolen_data", "the template carries the inspect_cargo row stolen_data")
	lu.assertTrue(isComplete(player, q), D.M4[3] .. ": complete after docking with the command shuttle")
	pump(3000, D.M4[3] .. " split delay")
	lu.assertFalse(isActive(player, quest(D.M4[4])), "assassinate 4_c is not active 4 s after the dock")
	pump(3000, D.M4[3] .. " split start")
	lu.assertTrue(isActive(player, quest(D.M4[4])), "assassinate 4_c is active 7 s after the dock")
end

-- A-5 (b): assassinate 4_c spawns the command shuttle and six X-wings after 30 s; completing it makes the chain end complete
function TestStormT3Chain4:test_assassinate_4_c_spawns_the_command_shuttle_and_six_xwings_and_completing_it_makes_the_chain_end_complete()
	local player = chain(4)

	for _, global in ipairs({ D.M4[1], D.M4[2], D.M4[3] }) do
		D.setState(player, global, "complete")
	end

	local q = begin(player, D.M4[4])

	pump(28000, D.M4[4] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, D.M4[4] .. ": nothing spawned 28 s after the start (arrivalDelay 30)")
	pump(6000, D.M4[4] .. " deployTargets")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(names[1], "rebel_command_shuttle_tier4", D.M4[4] .. ": the target first")
	lu.assertEquals(countOf(names, "reb_xwing_tier3"), 6, D.M4[4] .. ": six X-wing escorts among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 7, D.M4[4] .. ": the target and six escorts")
	q:completeQuest(player, true)
	pump(8000, D.M4[4] .. " completion")
	lu.assertTrue(isComplete(player, q), D.M4[4] .. ": the chain end is complete")
	noMemberActive(player, 4)
end

return nil
