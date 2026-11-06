-- Inquisitor Vrke: the four missions run through the fakes, split by split, including the three in-chain zone changes.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-3, AC-4; Data mapping 1; FV-9, FV-10; R-3, R-4).
--
-- The oracle values are the spec's literals (inquisition_tier3_data.lua); the quest tables are driven through the harness's fakes, never read for
-- expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an event shows up as "no Lua error" and not as a later,
-- unrelated assertion. For chain steps the test completes the member through its own completeQuest and pumps the split delay (the alert fires at the
-- delay; the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL ship template files (mercenary_spy_fighter_tier4,
-- shinss_yacht_tier3, rebel_spyfreighter_tier3), not a cargo set on the fake ship: the tier 2 runtime test did that and missed a broken quest.
-- Flying the survival, the battle and the escort is covered by their type features: this file stops at "active / spawned" for them.
-- The hostility of the real AI cannot be checked here; see the in-game checklist (R-4).

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local V = require("inquisition_tier3_data")

V.load()

local function quest(global) return V.quest(global) end

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

local function handler() return rawget(_G, V.HANDLER) end

-- An Imperial pilot in an Imperial-faction ship in `zone`
local function newPlayer(zone)
	return V.pilot({ zone = zone, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y, factionHash = getHashCode("imperial") } })
end

-- A fresh world with the static areas of every member of the mission's chain, and the pilot in `zone` (default the head's zone)
local function chain(n, zone)
	H.reset()

	local members = V.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return newPlayer(zone or quest(members[1]).questZone)
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
	for _, global in ipairs(V.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

local function spyShip(shipName, cargo, spawner, zone)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = zone })
end

-- the cargo the server's ship template gives the ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FV-9)")

	return t.cargoString
end

-- Inspects and docks with a ship carrying the template's cargo; returns the quest's completion state
local function inspectAndDock(player, q, shipName, spawner, zone)
	pump(2500, q.className .. " setup")

	local cargo = templateCargo(shipName)
	local target = spyShip(shipName, cargo, spawner, zone)
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

local Z = { N = "space_naboo", Y = "space_yavin4", D = "space_dathomir" }

---------------------------------------------------------------------------------------------
-- AC-3 (a): recovery 1 in Naboo
---------------------------------------------------------------------------------------------

TestInquisitionT3Chain1 = {}

function TestInquisitionT3Chain1:setUp() H.reset() end

function TestInquisitionT3Chain1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestInquisitionT3Chain1:test_recovery_1_spawns_hends_yacht_without_escorts_and_gives_the_first_pre_recovery_waypoint()
	local player = chain(1)
	local q = begin(player, V.M1[1])

	-- Core3 waits arrivalDelay twice (setupRecover, then spawnRecoveryShip), so the yacht is there by 2 * 30 s
	pump(65000, V.M1[1] .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())
	local p1 = V.POINTS[Z.N].naboo_imperial_tier3_recovery1_1

	lu.assertNotNil(ship, V.M1[1] .. ": the recovery ship was spawned")
	lu.assertEquals(ship.shipName, "colonel_hend_yacht_tier3", V.M1[1] .. ": the recovery ship")
	lu.assertEquals(ship.zone, Z.N, V.M1[1] .. ": the recovery ship zone")
	lu.assertEquals(names, { "colonel_hend_yacht_tier3" }, V.M1[1] .. ": the ships spawned (no escorts): " .. table.concat(names, ", "))
	lu.assertEquals(waypointsAt(player, p1[1], p1[2], p1[3]), 1, V.M1[1] .. ": one waypoint at the first pre-recovery point naboo_imperial_tier3_recovery1_1")
end

-- AC-3 (a): nothing spawns before the arrival delay
function TestInquisitionT3Chain1:test_recovery_1_spawns_nothing_just_after_its_start()
	local player = chain(1)
	local q = quest(V.M1[1])

	q:startQuest(player, "")
	pump(0, V.M1[1] .. " start")
	pump(14000, V.M1[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, V.M1[1] .. ": nothing spawned 14 s after the start (arrivalDelay 30)")
end

-- AC-3 (b), FV-10: completing recovery 1 starts inspect 1_a 5 s later; in Naboo it sets nothing up, entering Yavin 4 gives one waypoint at the spawner
function TestInquisitionT3Chain1:test_inspect_1_a_starts_in_naboo_without_a_setup_and_sets_up_on_entering_yavin_4()
	local player = chain(1)
	local inspect = quest(V.M1[2])
	local s = V.SPAWNERS[Z.Y].naboo_imperial_tier3_inspect1_spawner

	begin(player, V.M1[1])
	pump(60000, V.M1[1] .. " arrival")
	completeAndSplit(player, V.M1[1], V.M1[2])
	pump(15000, V.M1[2] .. " in Naboo")
	lu.assertTrue(isActive(player, inspect), V.M1[2] .. ": active (the journal entry starts at once)")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 0, V.M1[2] .. ": no waypoint at the Yavin 4 spawner while the pilot is in Naboo")

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.method, "setupInspection", V.M1[2] .. ": no inspect setup is pending while the pilot is in Naboo")
	end

	H.zoneSwitch(player, Z.Y)
	pump(6000, V.M1[2] .. " entered Yavin 4")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, V.M1[2] .. ": one waypoint at the spawner naboo_imperial_tier3_inspect1_spawner after entering Yavin 4")
	lu.assertTrue(isActive(player, inspect), V.M1[2] .. ": still active")
end

-- AC-3 (c), FV-9
function TestInquisitionT3Chain1:test_inspecting_and_docking_with_the_spy_fighter_carrying_its_templates_cargo_completes_1_a_and_starts_the_delivery_5_seconds_later()
	local player = chain(1, Z.Y)
	local q = begin(player, V.M1[2])

	inspectAndDock(player, q, "mercenary_spy_fighter_tier4", "naboo_imperial_tier3_inspect1_spawner", Z.Y)
	lu.assertTrue(isComplete(player, q), V.M1[2] .. ": complete after docking with the spy fighter")
	pump(3000, V.M1[2] .. " split delay")
	lu.assertFalse(isActive(player, quest(V.M1[3])), "delivery 1_b is not active 4 s after the dock")
	pump(3000, V.M1[2] .. " split start")
	lu.assertTrue(isActive(player, quest(V.M1[3])), "delivery 1_b is active 7 s after the dock")
end

-- AC-3 (c): a ship with another cargo does not complete it
function TestInquisitionT3Chain1:test_a_ship_with_another_cargo_does_not_complete_inspect_1_a()
	local player = chain(1, Z.Y)
	local q = begin(player, V.M1[2])

	pump(2500, V.M1[2] .. " setup")

	local target = spyShip("mercenary_spy_fighter_tier4", "stolen_data", "naboo_imperial_tier3_inspect1_spawner", Z.Y)
	local hash = getHashCode("stolen_data")

	H.inspect(player, target, hash)
	pump(0, V.M1[2] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, V.M1[2] .. " dock")
	lu.assertFalse(isComplete(player, q), V.M1[2] .. ": not complete with the wrong cargo")
end

-- AC-3 (c)
function TestInquisitionT3Chain1:test_delivery_1_b_sets_up_at_its_dropoff_and_completing_it_leaves_no_member_active_and_wins_mission_1()
	local player = chain(1, Z.Y)

	for _, global in ipairs({ V.M1[1], V.M1[2] }) do
		V.setState(player, global, "complete")
	end

	local q = begin(player, V.M1[3])

	lu.assertTrue(isActive(player, q), V.M1[3] .. ": active")
	deliveryArea(V.M1[3])

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local p = V.POINTS[Z.Y].naboo_imperial_tier3_delivery1_dropoff

	lu.assertEquals({ calls[#calls][1], calls[#calls][3], calls[#calls][4], calls[#calls][5] }, { Z.Y, p[1], p[2], p[3] }, V.M1[3] .. ": the delivery area (zone, x, z, y)")
	pump(10000, V.M1[3] .. " running")
	lu.assertTrue(isActive(player, q), V.M1[3] .. ": still active")
	completeAndSplit(player, V.M1[3], nil)
	pump(8000, V.M1[3] .. " after completion")
	noMemberActive(player, 1)
	V.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
	lu.assertFalse(handler():isActive(player, 1), "mission 1 is no longer running")
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): mission 2
---------------------------------------------------------------------------------------------

TestInquisitionT3Chain2 = {}

function TestInquisitionT3Chain2:setUp() H.reset() end

function TestInquisitionT3Chain2:tearDown() AC.tearDown() end

-- AC-3 (d), FV-9: inspect 2 with the Shinss yacht's real cargo; the split takes 15 s (triggerDelay 10 + 5)
function TestInquisitionT3Chain2:test_inspect_2_completes_with_the_shinss_yacht_cargo_and_starts_survival_2_a_fifteen_seconds_later()
	local player = chain(2)
	local q = begin(player, V.M2[1])
	local s = V.SPAWNERS[Z.Y].naboo_imperial_tier3_shinssyacht_spawner

	pump(2500, V.M2[1] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, V.M2[1] .. ": one waypoint at the spawner naboo_imperial_tier3_shinssyacht_spawner")
	inspectAndDock(player, q, "shinss_yacht_tier3", "naboo_imperial_tier3_shinssyacht_spawner", Z.Y)
	lu.assertTrue(isComplete(player, q), V.M2[1] .. ": complete after docking with the yacht")
	pump(9000, V.M2[1] .. " 10 s after the dock")
	lu.assertFalse(isActive(player, quest(V.M2[2])), "survival 2_a is not active 10 s after the dock (the split is 15 s, not 5)")
	pump(3000, V.M2[1] .. " 13 s after the dock")
	lu.assertFalse(isActive(player, quest(V.M2[2])), "survival 2_a is not active 13 s after the dock")
	pump(4500, V.M2[1] .. " 17.5 s after the dock")
	lu.assertTrue(isActive(player, quest(V.M2[2])), "survival 2_a is active 17.5 s after the dock")
end

-- AC-3 (d): a ship with another cargo does not complete it
function TestInquisitionT3Chain2:test_a_ship_with_another_cargo_does_not_complete_inspect_2()
	local player = chain(2)
	local q = begin(player, V.M2[1])

	pump(2500, V.M2[1] .. " setup")

	local target = spyShip("shinss_yacht_tier3", "pirate_data", "naboo_imperial_tier3_shinssyacht_spawner", Z.Y)
	local hash = getHashCode("pirate_data")

	H.inspect(player, target, hash)
	pump(0, V.M2[1] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, V.M2[1] .. " dock")
	lu.assertFalse(isComplete(player, q), V.M2[1] .. ": not complete with the wrong cargo")
end

-- AC-3 (d): the survival waits at the Yavin 4 point and splits to the delivery on completion
function TestInquisitionT3Chain2:test_survival_2_a_gives_a_waypoint_at_its_transmission_point_and_completing_it_starts_delivery_2_b()
	local player = chain(2)

	begin(player, V.M2[2])
	pump(5000, V.M2[2] .. " start")

	local p = V.POINTS[Z.Y].naboo_imperial_tier3_survival1

	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, V.M2[2] .. ": one waypoint at naboo_imperial_tier3_survival1")
	completeAndSplit(player, V.M2[2], V.M2[3])
end

-- AC-3 (d): delivery 2_b picks the shuttle up and delivers it in Yavin 4; completing it starts recovery 2_c
function TestInquisitionT3Chain2:test_delivery_2_b_runs_in_yavin_4_and_completing_it_starts_recovery_2_c()
	local player = chain(2)

	begin(player, V.M2[3])
	deliveryArea(V.M2[3])

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local p = V.POINTS[Z.Y].corellis_imperial_tier3_leg_2_rescue_3

	lu.assertEquals({ calls[#calls][1], calls[#calls][3], calls[#calls][4], calls[#calls][5] }, { Z.Y, p[1], p[2], p[3] }, V.M2[3] .. ": the pickup area (zone, x, z, y)")
	completeAndSplit(player, V.M2[3], V.M2[4])
end

-- AC-3 (d), FV-10: recovery 2_c started in Yavin 4 spawns nothing; entering Dathomir spawns the shuttle with 5 escorts
function TestInquisitionT3Chain2:test_recovery_2_c_spawns_nothing_in_yavin_4_and_the_shuttle_with_five_escorts_on_entering_dathomir()
	local player = chain(2, Z.Y)

	begin(player, V.M2[4])
	pump(90000, V.M2[4] .. " in Yavin 4")
	lu.assertEquals(#H.spawnedShips(), 0, V.M2[4] .. ": nothing spawned while the pilot is in Yavin 4")
	lu.assertTrue(isActive(player, quest(V.M2[4])), V.M2[4] .. ": active")
	H.zoneSwitch(player, Z.D)
	pump(90000, V.M2[4] .. " entered Dathomir")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "shinss_escape_shuttle_tier3"), 1, V.M2[4] .. ": the escape shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "shinss_escort_fighters_tier3"), 5, V.M2[4] .. ": the five escort fighters among " .. table.concat(names, ", "))
end

-- AC-3 (d): completing recovery 2_c wins mission 2
function TestInquisitionT3Chain2:test_completing_recovery_2_c_leaves_no_member_active_and_wins_mission_2()
	local player = chain(2, Z.D)

	for _, global in ipairs({ V.M2[1], V.M2[2], V.M2[3] }) do
		V.setState(player, global, "complete")
	end

	begin(player, V.M2[4])
	pump(90000, V.M2[4] .. " arrival")
	completeAndSplit(player, V.M2[4], nil)
	pump(8000, V.M2[4] .. " after completion")
	noMemberActive(player, 2)
	V.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 3
---------------------------------------------------------------------------------------------

TestInquisitionT3Chain3 = {}

function TestInquisitionT3Chain3:setUp() H.reset() end

function TestInquisitionT3Chain3:tearDown() AC.tearDown() end

-- AC-4 (a)
function TestInquisitionT3Chain3:test_delivery_3_runs_in_dathomir_and_completing_it_starts_the_surprise_attack()
	local player = chain(3)

	begin(player, V.M3[1])
	deliveryArea(V.M3[1])

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local p = V.POINTS[Z.D].naboo_imperial_tier3_delivery3_pickup

	lu.assertEquals({ calls[#calls][1], calls[#calls][3], calls[#calls][4], calls[#calls][5] }, { Z.D, p[1], p[2], p[3] }, V.M3[1] .. ": the pickup area (zone, x, z, y)")
	completeAndSplit(player, V.M3[1], V.M3[2])
end

-- AC-4 (a): the surprise attack spawns seven X-wings in Dathomir
function TestInquisitionT3Chain3:test_surprise_attack_3_a_spawns_seven_xwings_in_dathomir_and_completing_it_starts_the_rescue()
	local player = chain(3)

	begin(player, V.M3[2])
	pump(60000, V.M3[2] .. " attack")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "reb_xwing_tier3"), 7, V.M3[2] .. ": reb_xwing_tier3 among " .. table.concat(names, ", "))

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, Z.D, V.M3[2] .. ": " .. tostring(ship.shipName) .. " spawns in Dathomir")
	end

	completeAndSplit(player, V.M3[2], V.M3[3])
end

-- AC-4 (a): the rescue spawns the lambda after 15 s
function TestInquisitionT3Chain3:test_rescue_3_b_spawns_the_lambda_shuttle_after_15_seconds_and_completing_it_starts_inspect_3_c()
	local player = chain(3)

	begin(player, V.M3[3])
	pump(0, V.M3[3] .. " start")
	lu.assertEquals(#H.spawnedShips(), 0, "no ship at once")
	pump(10000, V.M3[3] .. " before the arrival")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "imp_lambda_shuttle_tier3"), 0, V.M3[3] .. ": no lambda 10 s after the start (targetArrivalDelay 15)")
	pump(10000, V.M3[3] .. " arrival")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "imp_lambda_shuttle_tier3") >= 1, V.M3[3] .. ": imp_lambda_shuttle_tier3 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, V.M3[3], V.M3[4])
end

-- AC-4 (a), FV-9: inspect 3_c with the spy freighter's real cargo (the inspect_cargo row rebel_plans)
function TestInquisitionT3Chain3:test_inspect_3_c_completes_with_the_spy_freighter_cargo_and_starts_delivery_3_d_5_seconds_later()
	local player = chain(3)
	local q = begin(player, V.M3[4])
	local s = V.SPAWNERS[Z.D].naboo_imperial_tier3_inspect3_spawner

	pump(2500, V.M3[4] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, V.M3[4] .. ": one waypoint at the spawner naboo_imperial_tier3_inspect3_spawner")
	inspectAndDock(player, q, "rebel_spyfreighter_tier3", "naboo_imperial_tier3_inspect3_spawner", Z.D)
	lu.assertEquals(templateCargo("rebel_spyfreighter_tier3"), "rebel_plans", "the template carries the inspect_cargo row rebel_plans, not the questLoot name rebel_plans_impt3")
	lu.assertTrue(isComplete(player, q), V.M3[4] .. ": complete after docking with the freighter")
	pump(3000, V.M3[4] .. " split delay")
	lu.assertFalse(isActive(player, quest(V.M3[5])), "delivery 3_d is not active 4 s after the dock")
	pump(3000, V.M3[4] .. " split start")
	lu.assertTrue(isActive(player, quest(V.M3[5])), "delivery 3_d is active 7 s after the dock")
end

-- AC-4 (a), FV-10: delivery_no_pickup 3_d started in Dathomir sets nothing up; entering Naboo sets it up at its drop-off; completing it wins mission 3
function TestInquisitionT3Chain3:test_delivery_3_d_sets_nothing_up_in_dathomir_and_sets_up_on_entering_naboo_and_completing_it_wins_mission_3()
	local player = chain(3)

	for _, global in ipairs({ V.M3[1], V.M3[2], V.M3[3], V.M3[4] }) do
		V.setState(player, global, "complete")
	end

	local q = begin(player, V.M3[5])
	local areasBefore, shipsBefore = #H.spawnedAreas(), #H.spawnedShips()

	pump(20000, V.M3[5] .. " in Dathomir")
	lu.assertTrue(isActive(player, q), V.M3[5] .. ": active (the journal entry starts at once)")
	lu.assertEquals(#H.spawnedAreas(), areasBefore, V.M3[5] .. ": no delivery area while the pilot is in Dathomir")
	lu.assertEquals(#H.spawnedShips(), shipsBefore, V.M3[5] .. ": no ship while the pilot is in Dathomir")
	H.zoneSwitch(player, Z.N)
	pump(5000, V.M3[5] .. " entered Naboo")
	lu.assertEquals(#H.spawnedAreas(), areasBefore + 1, V.M3[5] .. ": the delivery area is spawned on entering Naboo")

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local p = V.POINTS[Z.N].naboo_imperial_tier3_delivery4

	lu.assertEquals({ calls[#calls][1], calls[#calls][3], calls[#calls][4], calls[#calls][5] }, { Z.N, p[1], p[2], p[3] }, V.M3[5] .. ": the delivery area (zone, x, z, y)")
	completeAndSplit(player, V.M3[5], nil)
	pump(8000, V.M3[5] .. " after completion")
	noMemberActive(player, 3)
	V.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 4 in Dathomir
---------------------------------------------------------------------------------------------

TestInquisitionT3Chain4 = {}

function TestInquisitionT3Chain4:setUp() H.reset() end

function TestInquisitionT3Chain4:tearDown() AC.tearDown() end

local function deployedShips(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

-- AC-4 (b): Breckon's shuttle and five escorts after 30 s
function TestInquisitionT3Chain4:test_assassinate_4_spawns_breckons_shuttle_and_five_escorts_after_30_seconds()
	local player = chain(4)
	local q = begin(player, V.M4[1])

	pump(25000, V.M4[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, V.M4[1] .. ": nothing spawned 25 s after the start (arrivalDelay 30)")
	pump(15000, V.M4[1] .. " deployTargets")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "general_breckon_shuttle_tier4"), 1, "Breckon's shuttle among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "breckon_escort_fighter_tier3"), 5, "the escorts among " .. table.concat(names, ", "))
	lu.assertTrue(isActive(player, q), V.M4[1] .. ": active")
end

-- AC-4 (b): mustDestroyEscort = true: the target alone does not complete it; the target and all escorts do, and start escort 4_a
function TestInquisitionT3Chain4:test_the_target_alone_does_not_complete_assassinate_4_but_target_and_escorts_do_and_start_escort_4_a()
	local player = chain(4)
	local q = quest(V.M4[1])
	local ships = deployedShips(player, V.M4[1])

	lu.assertEquals(#ships, 6, "precondition: Breckon's shuttle and five escorts")

	local target, rest = nil, {}

	for _, s in ipairs(ships) do
		if s.shipName == "general_breckon_shuttle_tier4" then
			target = s
		else
			rest[#rest + 1] = s
		end
	end

	H.destroyShip(target, player.rootParent)
	pump(5000, V.M4[1] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive")

	for _, s in ipairs(rest) do
		H.destroyShip(s, player.rootParent)
		pump(1500, V.M4[1] .. " after a kill")
	end

	pump(5000, V.M4[1] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), "complete after the target and all escorts")
	pump(3000, V.M4[1] .. " split start")
	lu.assertTrue(isActive(player, quest(V.M4[2])), "escort 4_a is active 5 s after the last kill")
end

-- AC-4 (b): escort 4_a spawns the prison shuttle; its split takes 15 s
function TestInquisitionT3Chain4:test_escort_4_a_spawns_the_prison_shuttle_and_starts_the_battle_fifteen_seconds_after_completion()
	local player = chain(4)
	local eq = begin(player, V.M4[2])

	pump(2500, V.M4[2] .. " setup")

	local start = readData(player.objectID .. eq.className .. ":startPoint:")

	lu.assertNotNil(start, V.M4[2] .. ": setup chose a start point")
	H.enterArea(AC.areaByNumber(eq, start), player.rootParent)
	pump(12000, V.M4[2] .. " escort ship arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "dathomir_prison_shuttle_tier4") >= 1, V.M4[2] .. ": the escorted dathomir_prison_shuttle_tier4 spawned; ships: " .. table.concat(names, ", "))

	local q = quest(V.M4[3])

	pump(0, V.M4[2] .. " before completion")
	eq:completeQuest(player, true)
	pump(0, V.M4[2] .. " completion")
	lu.assertTrue(isComplete(player, eq), V.M4[2] .. ": complete")
	pump(10000, V.M4[2] .. " 10 s after completion")
	lu.assertFalse(isActive(player, q), "battle 4_b is not active 10 s after escort 4_a completed (the split is 15 s, not 5)")
	pump(3000, V.M4[2] .. " 13 s after completion")
	lu.assertFalse(isActive(player, q), "battle 4_b is not active 13 s after escort 4_a completed")
	pump(4500, V.M4[2] .. " 17.5 s after completion")
	lu.assertTrue(isActive(player, q), "battle 4_b is active 17.5 s after escort 4_a completed")
end

-- AC-4 (b): the battle brings the TIE allies and the Rebel force; completing it starts assassinate 4_c
function TestInquisitionT3Chain4:test_battle_4_b_spawns_tie_allies_and_the_rebel_force_and_completing_it_starts_assassinate_4_c()
	local player = chain(4)

	begin(player, V.M4[3])
	pump(100000, V.M4[3] .. " arrivals")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "imp_tie_interceptor_tier3"), 3, "TIE interceptor allies among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "imp_tie_fighter_tier3"), 2, "TIE fighter allies among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_xwing_tier3"), 4, "enemy X-wings among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_awing_tier3"), 5, "enemy A-wings among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_ywing_tier3"), 1, "enemy Y-wing among " .. table.concat(names, ", "))
	completeAndSplit(player, V.M4[3], V.M4[4])
end

-- AC-4 (b): the Price of Liberty and six X-wings; killing all of them wins mission 4
function TestInquisitionT3Chain4:test_assassinate_4_c_spawns_the_price_of_liberty_with_six_xwings_and_killing_them_all_wins_mission_4()
	local player = chain(4)
	local ships = deployedShips(player, V.M4[4])
	local names = shipNames(ships)

	lu.assertEquals(countOf(names, "reb_priceofliberty_tier3"), 1, "the Price of Liberty among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_xwing_tier3"), 6, "the X-wing escorts among " .. table.concat(names, ", "))

	for _, s in ipairs(ships) do
		H.destroyShip(s, player.rootParent)
		pump(1500, V.M4[4] .. " after a kill")
	end

	pump(5000, V.M4[4] .. " after the last kill")
	lu.assertTrue(isComplete(player, quest(V.M4[4])), V.M4[4] .. ": complete")
	pump(8000, V.M4[4] .. " after completion")
	noMemberActive(player, 4)
	V.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end
