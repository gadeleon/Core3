-- Crimson Phoenix tier 3 part A: Arnecio Ulvaw'op's four missions run through the fakes, split by split.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop-missions/01-spec.md (A-3, A-4; Data mapping 1; FU-1, FU-2, FU-3, FU-4; R-1, R-5).
--
-- The oracle values are the spec's literals (crimson_tier3_data.lua, proven equal to the SWG .tab fixtures by test_crimson_tier3_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and
-- pumps the split delay (the alert fires at the delay; the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL ship template files
-- (tatooine_tier3_2_inspect_xwing), not a cargo set on the fake ship. Flying the survivals and the battles is covered by their type features: this file stops
-- at "active / spawned" for them. The hostility of the real AI (R-3) cannot be checked here; it is on the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local D = require("delivery_scenario")
local T = require("crimson_tier3_data")

T.load()
D.load()

local function quest(global) return T.quest(global) end

local function secs(n) return n * 1000 end

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
	local p = T.POINTS[zone][name] or (T.SPAWNERS[zone] or {})[name]

	assert(p ~= nil, "no spec point " .. name .. " in " .. zone)
	return p
end

local function victories(player)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_won" then
			n = n + 1
		end
	end

	return n
end

-- A fresh world with the static areas of every member of the mission's chain, and the pilot in a Rebel ship in `zone` (default the head's zone)
local function chain(n, zone)
	H.reset()

	local members = T.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return T.flyer(zone or T.IDENTITY[members[1]].zone)
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
	for _, global in ipairs(T.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

-- the cargo the server's ship template gives the ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FU-3, SC-1)")

	return t.cargoString
end

-- Inspects and docks with a ship carrying the template's cargo
local function inspectAndDock(player, q, shipName, spawner)
	pump(2500, q.className .. " setup")

	local cargo = templateCargo(shipName)
	local target = H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = q.questZone })
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, q.className .. " inspect")
	H.dock(player, target, hash)
	pump(0, q.className .. " dock")

	return cargo
end

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

local function flyPatrolTo(q, player, point)
	for n = 1, point do
		H.enterArea(AC.areaByNumber(q, n), player.rootParent)
		pump(500, q.className .. " point " .. n)
	end
end

local function deployedShips(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

---------------------------------------------------------------------------------------------
-- A-3 (a): mission 1
---------------------------------------------------------------------------------------------

TestUlvawopChain1 = {}

function TestUlvawopChain1:setUp() H.reset() end

function TestUlvawopChain1:tearDown() AC.tearDown() end

-- A-3 (a): started on the ground, recovery 1 sets nothing up until the pilot enters space_dathomir
function TestUlvawopChain1:test_recovery_1_started_on_the_ground_sets_nothing_up_until_dathomir()
	chain(1)

	local q = quest(T.M1[1])
	local player = H.newPlayer({ zone = "tatooine", pilot = "rebel", parent = "starport" })

	q:startQuest(player, "")
	pump(60000, T.M1[1] .. " on the ground")
	lu.assertTrue(isActive(player, q), T.M1[1] .. ": active (the journal entry starts at once)")
	lu.assertEquals(#H.spawnedShips(), 0, T.M1[1] .. ": no ship on the ground")

	H.zoneSwitch(player, "space_dathomir", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(120000, T.M1[1] .. " entered space_dathomir")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(#names >= 1, T.M1[1] .. ": something spawned after the pilot entered space_dathomir")
	lu.assertEquals(countOf(names, "lambdashuttle_rebel_tier3_1_officer"), 1, T.M1[1] .. ": the officer's shuttle spawned among " .. table.concat(names, ", "))

	for i, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dathomir", T.M1[1] .. ": ship " .. i .. " zone")
	end
end

-- A-3 (a), FU-4: completing recovery 1 starts delivery 1_a after 5 s, not before
function TestUlvawopChain1:test_completing_recovery_1_starts_delivery_1_a_after_five_seconds()
	local player = chain(1)

	begin(player, T.M1[1])
	completeAndSplit(player, T.M1[1], T.M1[2], 5)
end

-- A-3 (a), FU-4: completing delivery 1_a starts survival 1_b after 10 s (triggerDelay 5 + 5), not 5
function TestUlvawopChain1:test_completing_delivery_1_a_starts_survival_1_b_after_ten_seconds()
	local player = chain(1)
	local q = begin(player, T.M1[2])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier3_1_a_pickup")

	deliveryArea(T.M1[2])
	lu.assertEquals(lastAreaCall(), { "space_dathomir", p[1], p[2], p[3] }, T.M1[2] .. ": the pickup area (zone, x, z, y)")
	lu.assertFalse(isActive(player, quest(T.M1[3])), T.M1[3] .. ": not active during the delivery")
	completeAndSplit(player, T.M1[2], T.M1[3], 10)
	lu.assertFalse(isActive(player, q), T.M1[2] .. ": no longer active")
end

-- A-3 (a): survival 1_b is active at its point with a waypoint; completing it starts escort 1_c 5 s later
function TestUlvawopChain1:test_survival_1_b_is_active_at_its_point_and_completing_it_starts_escort_1_c_five_seconds_later()
	local player = chain(1)
	local q = begin(player, T.M1[3])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier3_1_b_survival")

	pump(5000, T.M1[3] .. " start")
	lu.assertTrue(isActive(player, q), T.M1[3] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, T.M1[3] .. ": one waypoint at tatooine_rebel_tier3_1_b_survival")
	completeAndSplit(player, T.M1[3], T.M1[4], 5)
end

-- A-3 (a): escort 1_c spawns the spies' lambda shuttle; completing it leaves no mission 1 member active and the chain end complete
function TestUlvawopChain1:test_escort_1_c_spawns_the_spies_shuttle_and_completing_it_leaves_no_member_active_and_the_chain_end_complete()
	local player = chain(1)

	for _, global in ipairs({ T.M1[1], T.M1[2], T.M1[3] }) do
		T.setState(player, global, "complete")
	end

	local q = quest(T.M1[4])
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "lambdashuttle_rebel_tier3_1_a_spies", T.M1[4] .. ": the escorted ship")
	lu.assertEquals(escort.zone, "space_dathomir", T.M1[4] .. ": the escorted ship zone")
	lu.assertTrue(isActive(player, q), T.M1[4] .. ": active")
	completeAndSplit(player, T.M1[4], nil)
	pump(8000, T.M1[4] .. " after completion")
	noMemberActive(player, 1)
	lu.assertTrue(isComplete(player, q), T.M1[4] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-3 (b), (c): mission 2
---------------------------------------------------------------------------------------------

TestUlvawopChain2 = {}

function TestUlvawopChain2:setUp() H.reset() end

function TestUlvawopChain2:tearDown() AC.tearDown() end

-- A-3 (b): inspect 2 gives one waypoint per suspect spawner
function TestUlvawopChain2:test_inspect_2_gives_one_waypoint_per_suspect_spawner()
	local player = chain(2)

	begin(player, T.M2[1])
	pump(2500, T.M2[1] .. " setup")

	for name, xyz in pairs(T.SPAWNERS.space_dathomir) do
		lu.assertEquals(waypointsAt(player, xyz[1], xyz[2], xyz[3]), 1, T.M2[1] .. ": one waypoint at the spawner " .. name)
	end

	lu.assertEquals(#player.ghost.waypoints, 2, T.M2[1] .. ": two waypoints in all")
end

-- A-3 (b), FU-3: inspecting and docking with a suspect (the template's real cargo string) completes inspect 2, whichever of the four it is
function TestUlvawopChain2:test_inspecting_and_docking_with_any_of_the_four_suspects_completes_inspect_2()
	for _, ship in ipairs(T.SUSPECT_ORDER) do
		local player = chain(2)
		local q = begin(player, T.M2[1])
		local cargo = inspectAndDock(player, q, ship, "tatooine_rebel_tier3_2_suspect_1")

		lu.assertEquals(cargo, "thermal_bomb", ship .. ": the template carries the thermal bomb")
		lu.assertTrue(isComplete(player, q), T.M2[1] .. ": complete after docking with " .. ship)
	end
end

-- A-3 (b): a ship without cargo does not complete inspect 2 (the engine raises no INSPECTEDSHIP for it: only the dock arrives, with no cargo hash)
function TestUlvawopChain2:test_a_decoy_without_cargo_does_not_complete_inspect_2()
	local player = chain(2)
	local q = begin(player, T.M2[1])

	pump(2500, T.M2[1] .. " setup")

	local decoy = H.worldAgent({ shipName = "reb_awing_tier4", spawner = "tatooine_rebel_tier3_2_suspect_1", zone = "space_dathomir" })

	H.dock(player, decoy, 0)
	pump(3000, T.M2[1] .. " after the dock")
	lu.assertFalse(isComplete(player, q), T.M2[1] .. ": not complete after docking with a decoy")
	lu.assertTrue(isActive(player, q), T.M2[1] .. ": still active")
end

-- A-3 (b): a ship with another cargo does not complete inspect 2
function TestUlvawopChain2:test_a_ship_with_another_cargo_does_not_complete_inspect_2()
	local player = chain(2)
	local q = begin(player, T.M2[1])

	pump(2500, T.M2[1] .. " setup")

	local target = H.worldAgent({ shipName = "tatooine_tier3_2_inspect_xwing", cargo = "medical_supplies", spawner = "tatooine_rebel_tier3_2_suspect_2", zone = "space_dathomir" })
	local hash = getHashCode("medical_supplies")

	H.inspect(player, target, hash)
	pump(0, T.M2[1] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, T.M2[1] .. " dock")
	lu.assertFalse(isComplete(player, q), T.M2[1] .. ": not complete with the wrong cargo")
end

-- A-3 (b), FU-4: surprise 2_a is active 8 s after the dock (triggerDelay 3 + 5), not before, and spawns three interceptors in space_dathomir
function TestUlvawopChain2:test_surprise_2_a_is_active_eight_seconds_after_the_dock_and_spawns_three_interceptors()
	local player = chain(2)
	local q = begin(player, T.M2[1])
	local surprise = quest(T.M2[2])

	inspectAndDock(player, q, "tatooine_tier3_2_inspect_xwing", "tatooine_rebel_tier3_2_suspect_2")
	lu.assertTrue(isComplete(player, q), T.M2[1] .. ": complete after the dock")
	pump(6500, T.M2[1] .. " 6.5 s after the dock")
	lu.assertFalse(isActive(player, surprise), T.M2[2] .. ": not active 6.5 s after the dock (the split is 8 s: triggerDelay 3 + 5)")
	pump(3000, T.M2[1] .. " 9.5 s after the dock")
	lu.assertTrue(isActive(player, surprise), T.M2[2] .. ": active 9.5 s after the dock")
	pump(60000, T.M2[2] .. " attack")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3" }, T.M2[2] .. ": spawned attackers")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dathomir", T.M2[2] .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, T.M2[2] .. ": attacker " .. i .. " belongs to the pilot")
	end
end

-- A-3 (c), FU-1: destroying the interceptors starts assassinate 2_b 8 s later; in space_dathomir it is active and spawns nothing; entering space_dantooine
-- spawns the inquisitor and three guards after 10 s; killing the target alone completes it; battle 2_c is active 5 s later
function TestUlvawopChain2:test_destroying_the_interceptors_starts_assassinate_2_b_which_runs_when_the_pilot_enters_dantooine_and_hands_off_to_battle_2_c()
	local player = chain(2)
	local surprise = begin(player, T.M2[2])
	local assassinate = quest(T.M2[3])

	pump(60000, T.M2[2] .. " attack")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	lu.assertEquals(#ships, 3, T.M2[2] .. ": precondition: three attackers")

	for i = 1, 3 do
		H.destroyShip(ships[i], player.rootParent)
		pump(500, T.M2[2] .. " after kill " .. i)
	end

	pump(1000, T.M2[2] .. " after the last kill")
	lu.assertTrue(isComplete(player, surprise), T.M2[2] .. ": complete after all three attackers are destroyed")
	pump(5000, T.M2[2] .. " 6.5 s after the last kill")
	lu.assertFalse(isActive(player, assassinate), T.M2[3] .. ": not active 6.5 s after the last kill (the split is 8 s)")
	pump(3000, T.M2[2] .. " 9.5 s after the last kill")
	lu.assertTrue(isActive(player, assassinate), T.M2[3] .. ": active 9.5 s after the last kill")

	-- FU-1: the pilot is still in space_dathomir, so nothing spawns for 2_b
	local before = #H.spawnedShips()

	pump(30000, T.M2[3] .. " while the pilot is still in space_dathomir")
	lu.assertEquals(#H.spawnedShips(), before, T.M2[3] .. ": nothing spawned while the pilot is in space_dathomir")
	lu.assertTrue(isActive(player, assassinate), T.M2[3] .. ": still active")

	H.zoneSwitch(player, "space_dantooine", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(9000, T.M2[3] .. " entered space_dantooine")
	lu.assertEquals(#H.spawnedShips(), before, T.M2[3] .. ": nothing spawned 9 s after entering space_dantooine (arrivalDelay 10)")
	pump(5000, T.M2[3] .. " deployTargets")

	local spawned = {}

	for i, s in ipairs(H.spawnedShips()) do
		if i > before then
			spawned[#spawned + 1] = s
		end
	end

	local p = pointOf("space_dantooine", "tatooine_tier3_2_b_escape_1")

	lu.assertEquals(shipNames(spawned), { "tatooine_tier3_2_b_inquisitor", "tatooine_tier3_2_b_guard", "tatooine_tier3_2_b_guard", "tatooine_tier3_2_b_guard" },
		T.M2[3] .. ": the target and three guards")
	lu.assertEquals({ spawned[1].x, spawned[1].z, spawned[1].y }, p, T.M2[3] .. ": the target spawns at targetPatrols[1] (tatooine_tier3_2_b_escape_1)")

	for i, ship in ipairs(spawned) do
		lu.assertEquals(ship.zone, "space_dantooine", T.M2[3] .. ": ship " .. i .. " zone")
	end

	H.destroyShip(spawned[1], player.rootParent)
	pump(1500, T.M2[3] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, assassinate), T.M2[3] .. ": complete with the guards alive (mustDestroyEscort false)")
	pump(2000, T.M2[3] .. " 3.5 s after the kill")
	lu.assertFalse(isActive(player, quest(T.M2[4])), T.M2[4] .. ": not active 3.5 s after the kill (the split is 5 s)")
	pump(3000, T.M2[3] .. " 6.5 s after the kill")
	lu.assertTrue(isActive(player, quest(T.M2[4])), T.M2[4] .. ": active 6.5 s after the kill")
end

-- A-3 (c): the pilot leaving for the wrong zone does not start the assassinate run (it waits for space_dantooine)
function TestUlvawopChain2:test_assassinate_2_b_started_in_dathomir_is_active_and_waits_for_dantooine()
	local player = chain(2)
	local q = begin(player, T.M2[3])

	pump(40000, T.M2[3] .. " in space_dathomir")
	lu.assertTrue(isActive(player, q), T.M2[3] .. ": active")
	lu.assertEquals(#H.spawnedShips(), 0, T.M2[3] .. ": nothing spawned in space_dathomir")
end

-- A-3 (c): battle 2_c sets up in space_dantooine at its point; completing it makes the chain end complete with no member active
function TestUlvawopChain2:test_battle_2_c_sets_up_in_dantooine_and_completing_it_makes_the_chain_end_complete()
	local player = T.flyer("space_dantooine")

	H.reset()
	for _, global in ipairs(T.M2) do
		quest(global):start()
	end

	player = T.flyer("space_dantooine")

	for _, global in ipairs({ T.M2[1], T.M2[2], T.M2[3] }) do
		T.setState(player, global, "complete")
	end

	local q = begin(player, T.M2[4])
	local p = pointOf("space_dantooine", "tatooine_rebel_tier3_2_c_battlepoint")

	pump(5000, T.M2[4] .. " setup")
	lu.assertTrue(isActive(player, q), T.M2[4] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, T.M2[4] .. ": one waypoint at tatooine_rebel_tier3_2_c_battlepoint")
	pump(90000, T.M2[4] .. " arrivals")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(#names, 9, T.M2[4] .. ": 3 allies + 6 enemies among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_bwing_tier3"), 3, T.M2[4] .. ": three reb_bwing_tier3 allies")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dantooine", T.M2[4] .. ": " .. tostring(ship.shipName) .. " zone")
	end

	completeAndSplit(player, T.M2[4], nil)
	pump(8000, T.M2[4] .. " after completion")
	noMemberActive(player, 2)
	lu.assertTrue(isComplete(player, q), T.M2[4] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-4 (a): mission 3
---------------------------------------------------------------------------------------------

TestUlvawopChain3 = {}

function TestUlvawopChain3:setUp() H.reset() end

function TestUlvawopChain3:tearDown() AC.tearDown() end

local function spawnNames(name)
	local out = {}

	for _, s in ipairs(D.spawns()) do
		if s.name == name then
			out[#out + 1] = s.zone
		end
	end

	return out
end

-- A-4 (a), FU-2: delivery 3 sets up its pickup in space_lok with the nym smuggler
function TestUlvawopChain3:test_delivery_3_sets_up_its_pickup_in_lok_with_the_nym_smuggler()
	quest(T.M3[1])

	local sc = D.fresh("delivery", "tatooine_rebel_tier3_3"):start()
	local p = pointOf("space_lok", "tatooine_rebel_tier3_3_pickup")
	local area = H.Engine.callsTo("spawnSpaceActiveArea")[1]

	lu.assertEquals({ area[1], area[3], area[4], area[5] }, { "space_lok", p[1], p[2], p[3] }, "the pickup area (zone, x, z, y)")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertEquals(sc:waypoints()[1].planet, "space_lok", "pickup waypoint planet")
	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnNames("nym_smuggler"), { "space_lok" }, "the pickup transport and its zone")
	lu.assertTrue(sc:active(), "delivery 3 is active")
end

-- A-4 (a), FU-2: after the pickup the delivery leg is in space_dathomir at the delivery point, with the YT-1300
function TestUlvawopChain3:test_after_the_pickup_the_delivery_leg_is_in_dathomir_at_the_delivery_point_with_the_yt1300()
	quest(T.M3[1])

	local sc = D.fresh("delivery", "tatooine_rebel_tier3_3"):toFirstDock()
	local p = pointOf("space_dathomir", "tatooine_rebel_tier3_3_delivery")

	sc:atDock(secs(2))

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")

	lu.assertEquals(#calls, 2, "the delivery leg area exists 2 s after the dock")
	lu.assertEquals({ calls[2][1], calls[2][3], calls[2][4], calls[2][5] }, { "space_dathomir", p[1], p[2], p[3] }, "the delivery area (zone, x, z, y)")
	lu.assertEquals(#sc:waypoints(), 1, "one live waypoint: the delivery point")
	lu.assertEquals(sc:waypoints()[1].planet, "space_dathomir", "delivery waypoint planet")

	H.zoneSwitch(sc.player, "space_dathomir")
	pump(0, "zone switch")
	lu.assertTrue(sc:active(), "the quest survives lok -> dathomir on leg 2")
	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnNames("smuggler_yt1300_tier2"), { "space_dathomir" }, "the delivery transport and its zone")
	sc:dock()
	sc:atDock(secs(3))
	lu.assertTrue(sc:complete(), "delivery 3 is complete after the delivery dock")
end

-- A-4 (a), FU-2: a switch to any other zone on leg 2 fails the quest
function TestUlvawopChain3:test_a_switch_to_another_zone_on_leg_2_fails_delivery_3()
	quest(T.M3[1])

	local sc = D.fresh("delivery", "tatooine_rebel_tier3_3"):toFirstDock()

	sc:atDock(secs(2))
	H.zoneSwitch(sc.player, "space_dantooine")
	pump(0, "zone switch")
	lu.assertFalse(sc:active(), "lok -> dantooine on leg 2 ends delivery 3")
end

-- A-4 (a), FU-4: completing delivery 3 starts battle 3_a after 8 s (triggerDelay 3 + 5)
function TestUlvawopChain3:test_completing_delivery_3_starts_battle_3_a_after_eight_seconds()
	local player = chain(3)

	begin(player, T.M3[1])
	pump(2000, T.M3[1] .. " setup")
	completeAndSplit(player, T.M3[1], T.M3[2], 8)
end

-- A-4 (a): battle 3_a sets up in space_dathomir: a waypoint at its point, three X-wing allies after 110 s and the eight enemies after 140 s; completing it
-- starts escort 3_b 5 s later
function TestUlvawopChain3:test_battle_3_a_sets_up_in_dathomir_and_completing_it_starts_escort_3_b_five_seconds_later()
	local player = chain(3, "space_dathomir")
	local q = begin(player, T.M3[2])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier3_3_a_battlepoint")

	pump(5000, T.M3[2] .. " setup")
	lu.assertTrue(isActive(player, q), T.M3[2] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, T.M3[2] .. ": one waypoint at tatooine_rebel_tier3_3_a_battlepoint")
	lu.assertEquals(#H.spawnedShips(), 0, T.M3[2] .. ": nothing spawned 5 s after the start (allyArrivalDelay 110)")
	pump(110000, T.M3[2] .. " allies arrive")
	lu.assertEquals(shipNames(H.spawnedShips()), { "reb_xwing_tier3", "reb_xwing_tier3", "reb_xwing_tier3" }, T.M3[2] .. ": the allies that arrive first")
	pump(40000, T.M3[2] .. " enemies arrive")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 11, T.M3[2] .. ": 3 allies + 8 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "lambdashuttle_advanced_recon"), 1, T.M3[2] .. ": one lambdashuttle_advanced_recon enemy")
	lu.assertEquals(countOf(all, "imp_lambda_shuttle_tier3"), 1, T.M3[2] .. ": one imp_lambda_shuttle_tier3 enemy")
	lu.assertEquals(countOf(all, "imp_tie_fighter_tier3"), 6, T.M3[2] .. ": six imp_tie_fighter_tier3 enemies")
	completeAndSplit(player, T.M3[2], T.M3[3], 5)
end

-- A-4 (a), FU-4: escort 3_b spawns the YT-1300; completing it starts survival 3_c after 8 s
function TestUlvawopChain3:test_escort_3_b_spawns_the_yt1300_and_completing_it_starts_survival_3_c_after_eight_seconds()
	local player = chain(3, "space_dathomir")
	local q = quest(T.M3[3])
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "tatooine_rebel_3_3_b_smuggler_yt1300_tier3", T.M3[3] .. ": the escorted ship")
	lu.assertEquals(escort.zone, "space_dathomir", T.M3[3] .. ": the escorted ship zone")
	completeAndSplit(player, T.M3[3], T.M3[4], 8)
end

-- A-4 (a), FU-10: survival 3_c is active at tatooine_tier3_3_b_escort_4 with a waypoint; completing it makes the chain end complete with no member active
function TestUlvawopChain3:test_survival_3_c_is_active_at_the_last_escort_point_and_completing_it_makes_the_chain_end_complete()
	local player = chain(3, "space_dathomir")

	for _, global in ipairs({ T.M3[1], T.M3[2], T.M3[3] }) do
		T.setState(player, global, "complete")
	end

	local q = begin(player, T.M3[4])
	local p = pointOf("space_dathomir", "tatooine_tier3_3_b_escort_4")

	pump(5000, T.M3[4] .. " start")
	lu.assertTrue(isActive(player, q), T.M3[4] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, T.M3[4] .. ": one waypoint at tatooine_tier3_3_b_escort_4")
	completeAndSplit(player, T.M3[4], nil)
	pump(8000, T.M3[4] .. " after completion")
	noMemberActive(player, 3)
	lu.assertTrue(isComplete(player, q), T.M3[4] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-4 (b): mission 4
---------------------------------------------------------------------------------------------

TestUlvawopChain4 = {}

function TestUlvawopChain4:setUp() H.reset() end

function TestUlvawopChain4:tearDown() AC.tearDown() end

-- A-4 (b): assassinate 4 in space_endor spawns imp_tie_advanced_tier4 and six escorts after 10 s; killing the target alone completes it and patrol 4_a starts 5 s later
function TestUlvawopChain4:test_assassinate_4_spawns_the_advanced_tie_and_six_escorts_and_the_target_alone_completes_it()
	local player = chain(4)
	local q = quest(T.M4[1])

	begin(player, T.M4[1])
	pump(9000, T.M4[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, T.M4[1] .. ": nothing spawned 9 s after the start (arrivalDelay 10)")
	pump(5000, T.M4[1] .. " deployTargets")

	local ships = H.spawnedShips()
	local p = pointOf("space_endor", "tatooine_rebel_tier3_4_escort_1")

	lu.assertEquals(shipNames(ships), { "imp_tie_advanced_tier4", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3",
		"imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3" }, T.M4[1] .. ": the target and six escorts")
	lu.assertTrue(ships[1].isSquadronLeader, T.M4[1] .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, T.M4[1] .. ": the target spawns at targetPatrols[1] (tatooine_rebel_tier3_4_escort_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", T.M4[1] .. ": ship " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, T.M4[1] .. ": ship " .. i .. " belongs to the pilot")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(1500, T.M4[1] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), T.M4[1] .. ": complete with the escorts alive (mustDestroyEscort false)")
	pump(2000, T.M4[1] .. " 3.5 s after the kill")
	lu.assertFalse(isActive(player, quest(T.M4[2])), T.M4[2] .. ": not active 3.5 s after the kill (the split is 5 s)")
	pump(3000, T.M4[1] .. " 6.5 s after the kill")
	lu.assertTrue(isActive(player, quest(T.M4[2])), T.M4[2] .. ": active 6.5 s after the kill")
end

-- A-4 (b), FU-4, R-5: patrol 4_a has no split at point 2 and none at point 3 before 4 s; 4 s after point 3 it is complete without a client notification and
-- surprise 4_b is active; point 4 is never flown
function TestUlvawopChain4:test_patrol_4_a_hands_off_four_seconds_after_point_3_without_a_notification_and_never_needs_point_4()
	local player = chain(4)
	local q = begin(player, T.M4[2])
	local surprise = quest(T.M4[3])

	flyPatrolTo(q, player, 2)
	lu.assertTrue(isActive(player, q), T.M4[2] .. ": still active at point 2")
	pump(15000, T.M4[2] .. " 15 s after point 2")
	lu.assertFalse(isActive(player, surprise), T.M4[3] .. ": the split does not fire at point 2")
	lu.assertFalse(isComplete(player, q), T.M4[2] .. ": not complete at point 2")
	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, T.M4[2] .. " point 3")
	pump(2500, T.M4[2] .. " 3 s after point 3")
	lu.assertFalse(isComplete(player, q), T.M4[2] .. ": not complete 3 s after point 3 (sideQuestDelay 4, no +5)")
	lu.assertFalse(isActive(player, surprise), T.M4[3] .. ": not active 3 s after point 3")
	pump(2500, T.M4[2] .. " 5.5 s after point 3")
	lu.assertTrue(isComplete(player, q), T.M4[2] .. ": complete 5.5 s after point 3 (point 4 is never flown)")
	lu.assertTrue(isActive(player, surprise), T.M4[3] .. ": surprise 4_b is active")
	lu.assertEquals(victories(player), 0, T.M4[2] .. ": no 'Mission Successful' notification for the patrol")
end

-- A-4 (b): surprise 4_b spawns three advanced TIEs in space_endor; destroying them starts delivery_no_pickup 4_c 8 s later
function TestUlvawopChain4:test_surprise_4_b_spawns_three_advanced_ties_and_destroying_them_starts_delivery_4_c_after_eight_seconds()
	local player = chain(4)
	local q = begin(player, T.M4[3])

	pump(60000, T.M4[3] .. " attack")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	lu.assertEquals(shipNames(ships), { "imp_tie_advanced_tier3", "imp_tie_advanced_tier3", "imp_tie_advanced_tier3" }, T.M4[3] .. ": spawned attackers")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", T.M4[3] .. ": attacker " .. i .. " zone")
	end

	for i = 1, 3 do
		H.destroyShip(ships[i], player.rootParent)
		pump(500, T.M4[3] .. " after kill " .. i)
	end

	pump(1000, T.M4[3] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), T.M4[3] .. ": complete after all three attackers are destroyed")
	pump(5000, T.M4[3] .. " 6.5 s after the last kill")
	lu.assertFalse(isActive(player, quest(T.M4[4])), T.M4[4] .. ": not active 6.5 s after the last kill (the split is 8 s)")
	pump(3000, T.M4[3] .. " 9.5 s after the last kill")
	lu.assertTrue(isActive(player, quest(T.M4[4])), T.M4[4] .. ": active 9.5 s after the last kill")
end

-- A-4 (b): delivery_no_pickup 4_c delivers at its point with rebel_smuggler_tier3; completing it starts battle 4_d 8 s later
function TestUlvawopChain4:test_delivery_4_c_delivers_at_its_point_with_the_rebel_smuggler_and_completing_it_starts_battle_4_d_after_eight_seconds()
	local player = chain(4)

	begin(player, T.M4[4])

	local area = deliveryArea(T.M4[4])
	local p = pointOf("space_endor", "tatooine_rebel_tier3_4_c_delivery")

	lu.assertEquals(lastAreaCall(), { "space_endor", p[1], p[2], p[3] }, T.M4[4] .. ": the delivery area (zone, x, z, y)")
	H.enterArea(area, player.rootParent)
	pump(8000, T.M4[4] .. " transport warps in")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "rebel_smuggler_tier3"), 1, T.M4[4] .. ": the rebel_smuggler_tier3 transport spawned")
	completeAndSplit(player, T.M4[4], T.M4[5], 8)
end

-- A-4 (b): battle 4_d sets up in space_endor with five X-wing allies; completing it makes the chain end complete with no member active
function TestUlvawopChain4:test_battle_4_d_sets_up_in_endor_and_completing_it_makes_the_chain_end_complete()
	local player = chain(4)

	for _, global in ipairs({ T.M4[1], T.M4[2], T.M4[3], T.M4[4] }) do
		T.setState(player, global, "complete")
	end

	local q = begin(player, T.M4[5])
	local p = pointOf("space_endor", "tatooine_rebel_tier3_4_d_battlepoint")

	pump(5000, T.M4[5] .. " setup")
	lu.assertTrue(isActive(player, q), T.M4[5] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, T.M4[5] .. ": one waypoint at tatooine_rebel_tier3_4_d_battlepoint")
	pump(70000, T.M4[5] .. " arrivals")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 12, T.M4[5] .. ": 5 allies + 7 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_xwing_tier3"), 5, T.M4[5] .. ": five reb_xwing_tier3 allies")
	lu.assertEquals(countOf(all, "imp_tie_aggressor_tier3"), 1, T.M4[5] .. ": one imp_tie_aggressor_tier3 enemy")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_endor", T.M4[5] .. ": " .. tostring(ship.shipName) .. " zone")
	end

	completeAndSplit(player, T.M4[5], nil)
	pump(8000, T.M4[5] .. " after completion")
	noMemberActive(player, 4)
	lu.assertTrue(isComplete(player, q), T.M4[5] .. ": the chain end is complete")
end

return nil
