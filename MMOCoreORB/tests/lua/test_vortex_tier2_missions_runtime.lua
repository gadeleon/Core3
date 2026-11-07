-- Vortex tier 2 part A: Brother Vrovel's four missions and three duties run through the fakes.
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (A-4, A-5; Data mapping 1; FV-1 to FV-4; R-2, R-3).
--
-- The oracle values are the spec's literals (vortex_tier2_data.lua, proven equal to the SWG .tab fixtures by test_vortex_tier2_missions_data.lua);
-- the quest tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua
-- error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. The inspect steps use the cargo of the REAL ship template
-- files, not a cargo set on the fake ship. The INSPECTION split on its own (windows, aborts, existing inspects) is test_vortex_tier2_missions_inspection.lua.
-- The hostility of the real AI cannot be checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local V = require("vortex_tier2_data")

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

local function sorted(list)
	local out = {}

	for i, v in ipairs(list) do
		out[i] = v
	end

	table.sort(out)
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

local function unionOf(lists)
	local set = {}

	for _, list in ipairs(lists) do
		for _, name in ipairs(list) do
			set[name] = true
		end
	end

	return set
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

local REBEL_SHIP = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") }

-- A fresh world with the static areas of every member of the chain, and the pilot in a Rebel ship in the chain's zone
local function chain(members)
	H.reset()

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" or quest(global).questType == "recovery_duty" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return V.flyer(V.IDENTITY[members[1]].zone)
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- the cargo the server's ship template gives the ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never see the ship's cargo (FV-3, SC-2)")

	return t.cargoString
end

local function spyShip(shipName, cargo, spawner, zone)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = zone })
end

-- Escort legs: startQuest in the zone, setupEscort (2 s), the start area, the escort ship (5-11 s later). Returns the escort ship.
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

local function newShips(before, skip)
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= skip then
			out[#out + 1] = ship
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- A-4: mission 1 (escort -> inspect -> surprise attack)
---------------------------------------------------------------------------------------------

TestVrovelMission1 = {}

function TestVrovelMission1:setUp() H.reset() end

function TestVrovelMission1:tearDown() AC.tearDown() end

-- A-4: started on the ground, nothing is set up until the pilot enters space_lok, then Finn Darktrin's ship spawns
function TestVrovelMission1:test_escort_1_started_on_the_ground_sets_nothing_up_until_lok_and_then_spawns_the_darktrin_ship()
	chain(V.M1)

	local q = quest(V.E1)
	local player = H.newPlayer({ zone = "dantooine", pilot = "rebel", parent = "starport" })

	q:startQuest(player, "")
	pump(5000, V.E1 .. " on the ground")
	lu.assertTrue(isActive(player, q), V.E1 .. ": active (the journal entry starts at once)")
	lu.assertEquals(#player.ghost.waypoints, 0, V.E1 .. ": no rendezvous waypoint on the ground")
	lu.assertEquals(#H.spawnedShips(), 0, V.E1 .. ": no ship on the ground")

	H.zoneSwitch(player, "space_lok", { ship = REBEL_SHIP })
	pump(5000, V.E1 .. " entered space_lok")
	lu.assertEquals(#player.ghost.waypoints, 1, V.E1 .. ": the rendezvous waypoint after entering space_lok")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(6000, V.E1 .. " escort spawn")
	lu.assertEquals(shipNames(H.spawnedShips()), { "vortex_mission_1_finn_darktrin" }, V.E1 .. ": the escort ship")
	lu.assertEquals(H.spawnedShips()[1].zone, "space_lok", V.E1 .. ": the escort ship zone")
end

-- A-4, FV-1, R-2: completing escort 1 starts inspect 1 after the 8 s split delay (triggerDelay 3 + 5)
function TestVrovelMission1:test_completing_escort_1_starts_inspect_1_after_eight_seconds()
	local player = chain(V.M1)
	local q, inspect = quest(V.E1), quest(V.I1)

	flyEscort(q, player)
	lu.assertFalse(isActive(player, inspect), V.I1 .. ": not active during the escort")
	q:completeQuest(player, true)
	pump(0, V.E1 .. " completion")
	lu.assertTrue(isComplete(player, q), V.E1 .. ": complete")
	lu.assertFalse(isActive(player, inspect), V.I1 .. ": not active at once")
	pump(7000, V.E1 .. " split delay")
	lu.assertFalse(isActive(player, inspect), V.I1 .. ": not active 7 s after completion (sideQuestDelay 8)")
	pump(3000, V.E1 .. " split start")
	lu.assertTrue(isActive(player, inspect), V.I1 .. ": active 10 s after completion")
end

-- A-4: the escort reaching its last point completes it and hands over to inspect 1
function TestVrovelMission1:test_escort_1_reaching_its_last_point_completes_and_hands_over_to_inspect_1()
	local player = chain(V.M1)
	local q = quest(V.E1)
	local escort = flyEscort(q, player)
	local progress = readData(escort.objectID .. ":" .. q.className .. ":escortShipProgress:")

	for _ = 1, progress do
		H.enterArea(H.spawnedAreas()[1], escort)
	end

	pump(2600, V.E1 .. " arrival")
	lu.assertTrue(isComplete(player, q), V.E1 .. ": complete after the escort reached its last point")
	pump(10000, V.E1 .. " split delay")
	lu.assertTrue(isActive(player, quest(V.I1)), V.I1 .. ": active after the 8 s split delay")
end

-- A-4: inspect 1 gives one waypoint, at the vortex_mission_1_shuttle spawner
function TestVrovelMission1:test_inspect_1_gives_one_waypoint_at_the_lok_shuttle_spawner()
	local player = chain(V.M1)
	local s = V.SPAWNERS.space_lok.vortex_mission_1_shuttle

	begin(player, V.I1)
	pump(2500, V.I1 .. " setup")
	lu.assertEquals(#player.ghost.waypoints, 1, V.I1 .. ": one waypoint")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, V.I1 .. ": the waypoint is at the vortex_mission_1_shuttle spawner")
end

-- A-4, A-3, FV-3: inspecting the Lok shuttle (its real template cargo) starts surprise 1 two seconds later; it spawns exactly two interceptors
function TestVrovelMission1:test_inspecting_the_lok_shuttle_starts_surprise_1_which_spawns_exactly_two_interceptors()
	local player = chain(V.M1)
	local q, surprise = begin(player, V.I1), quest(V.S1)

	pump(2500, V.I1 .. " setup")

	local cargo = templateCargo("vortex_mission_1_shuttle")
	local target = spyShip("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle", "space_lok")

	lu.assertEquals(cargo, "ship_signature_data", "the template carries the inspect_cargo row ship_signature_data")
	H.inspect(player, target, getHashCode(cargo))
	pump(0, V.I1 .. " inspect")
	pump(1800, V.I1 .. " inside the window")
	lu.assertTrue(isActive(player, q), V.I1 .. ": still active 1.8 s after the inspection")
	lu.assertFalse(isActive(player, surprise), V.S1 .. ": not active inside the window")
	pump(2200, V.I1 .. " after the split")
	lu.assertTrue(isComplete(player, q), V.I1 .. ": complete 4 s after the inspection, without docking")
	lu.assertTrue(isActive(player, surprise), V.S1 .. ": active 4 s after the inspection")
	pump(60000, V.S1 .. " attack")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(names, { "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2" }, V.S1 .. ": the spawned ships (the target shuttle is a world agent, not spawned by the quest)")

	for i, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_lok", V.S1 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, V.S1 .. ": attacker " .. i .. " belongs to the pilot")
	end
end

-- A-4: destroying both interceptors completes surprise 1; no mission 1 member stays active and the chain end is complete
function TestVrovelMission1:test_destroying_both_interceptors_completes_the_chain_end_and_leaves_no_member_active()
	local player = chain(V.M1)

	V.setState(player, V.E1, "complete")
	V.setState(player, V.I1, "complete")

	local q = begin(player, V.S1)

	pump(60000, V.S1 .. " attack")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	lu.assertEquals(#ships, 2, V.S1 .. ": two attackers")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, V.S1 .. " after kill 1")
	lu.assertFalse(isComplete(player, q), V.S1 .. ": not complete after 1 of 2 kills")
	H.destroyShip(ships[2], player.rootParent)
	pump(8000, V.S1 .. " after kill 2")
	lu.assertTrue(isComplete(player, q), V.S1 .. ": the chain end is complete after both interceptors are destroyed")

	for _, global in ipairs(V.M1) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 1 member is active")
	end
end

-- A-4: the whole mission in one run: escort -> (8 s) inspect -> (first inspection + 2 s) surprise
function TestVrovelMission1:test_the_whole_chain_runs_from_the_escort_to_the_surprise_attack_without_a_lua_error()
	local player = chain(V.M1)
	local q = quest(V.E1)

	flyEscort(q, player)
	q:completeQuest(player, true)
	pump(11000, "escort 1 split")
	lu.assertTrue(isActive(player, quest(V.I1)), V.I1 .. ": active")
	pump(2500, V.I1 .. " setup")

	local cargo = templateCargo("vortex_mission_1_shuttle")

	H.inspect(player, spyShip("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle", "space_lok"), getHashCode(cargo))
	pump(5000, V.I1 .. " split")
	lu.assertTrue(isComplete(player, quest(V.I1)), V.I1 .. ": complete")
	lu.assertTrue(isActive(player, quest(V.S1)), V.S1 .. ": active")
end

---------------------------------------------------------------------------------------------
-- A-5: missions 2 to 4
---------------------------------------------------------------------------------------------

TestVrovelMissions2To4 = {}

function TestVrovelMissions2To4:setUp() H.reset() end

function TestVrovelMissions2To4:tearDown() AC.tearDown() end

-- A-5 (a): escort 2 spawns the scientist; the first wave comes after the 60 s attack delay and is one of the three lists
function TestVrovelMissions2To4:test_escort_2_spawns_the_scientist_and_its_first_wave_after_60_seconds_is_one_of_the_three_lists()
	local player = chain({ V.E2 })
	local q = quest(V.E2)
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "vortex_mission_2_scientist", V.E2 .. ": the escort ship")
	lu.assertEquals(escort.zone, "space_yavin4", V.E2 .. ": the escort ship zone")

	local before = #H.spawnedShips()

	pump(40000, V.E2 .. " 40 s later")
	lu.assertEquals(#newShips(before, escort), 0, V.E2 .. ": no attack wave 40 s after the escort spawned (attackDelay 60)")

	for _ = 1, 40 do
		pump(1000, V.E2 .. " waiting for the wave")

		if #newShips(before, escort) > 0 then
			break
		end
	end

	local wave = shipNames(newShips(before, escort))
	local lists = V.expected()[V.E2].attackShips
	local match = false

	for _, list in ipairs(lists) do
		if table.concat(sorted(list), ",") == table.concat(sorted(wave), ",") then
			match = true
		end
	end

	lu.assertTrue(match, V.E2 .. ": the wave '" .. table.concat(wave, ",") .. "' is one of the three attack lists")
end

-- A-5 (a): completing escort 2 ends the mission (no split)
function TestVrovelMissions2To4:test_completing_escort_2_starts_no_other_quest()
	local player = chain({ V.E2 })
	local q = quest(V.E2)
	local starts = {}

	for _, global in ipairs(V.GLOBALS) do
		if global ~= V.E2 then
			starts[global] = H.spyOn(quest(global), "startQuest")
		end
	end

	flyEscort(q, player)
	q:completeQuest(player, true)
	pump(30000, V.E2 .. " completion")
	lu.assertTrue(isComplete(player, q), V.E2 .. ": complete")

	for global, calls in pairs(starts) do
		lu.assertEquals(#calls, 0, V.E2 .. ": started " .. global .. " (a single-quest mission splits nothing)")
	end
end

-- A-5 (b), R-3: recovery 3 spawns the prison transport with one guard after its arrival delay
function TestVrovelMissions2To4:test_recovery_3_spawns_the_prison_transport_with_one_guard_after_the_arrival_delay()
	local player = chain({ V.R3 })
	local q = begin(player, V.R3)

	pump(14000, V.R3 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, V.R3 .. ": nothing spawned 14 s after the start")
	pump(50000, V.R3 .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, V.R3 .. ": the recovery ship was spawned")
	lu.assertEquals(ship.shipName, "prison_transport_imperial", V.R3 .. ": the recovery ship")
	lu.assertEquals(ship.zone, "space_yavin4", V.R3 .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "prison_transport_imperial"), 1, V.R3 .. ": one transport among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "vortex_mission_4_guard"), 1, V.R3 .. ": one guard among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 2, V.R3 .. ": the transport and its guard: " .. table.concat(names, ", "))

	local p = V.POINTS.space_yavin4.vortex_mission_3_1

	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, V.R3 .. ": one waypoint at the first pre-recovery point vortex_mission_3_1")
end

-- A-5 (b): completing recovery 3 ends the mission
function TestVrovelMissions2To4:test_completing_recovery_3_is_the_end_of_mission_3()
	local player = chain({ V.R3 })
	local q = begin(player, V.R3)

	pump(60000, V.R3 .. " arrival")
	q:completeQuest(player, true)
	pump(10000, V.R3 .. " completion")
	lu.assertTrue(isComplete(player, q), V.R3 .. ": complete")
	lu.assertFalse(isActive(player, q), V.R3 .. ": no longer active")
end

-- A-5 (c), FV-4: inspect 4 gives one waypoint at the Dantooine shuttle spawner
function TestVrovelMissions2To4:test_inspect_4_gives_one_waypoint_at_the_dantooine_shuttle_spawner()
	local player = chain({ V.I4 })
	local s = V.SPAWNERS.space_dantooine.vortex_mission_4_shuttle

	begin(player, V.I4)
	pump(2500, V.I4 .. " setup")
	lu.assertEquals(#player.ghost.waypoints, 1, V.I4 .. ": one waypoint")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, V.I4 .. ": the waypoint is at the vortex_mission_4_shuttle spawner")
end

-- A-5 (c), FV-3, FV-4: inspecting and docking with the Dantooine shuttle (its real template cargo) completes inspect 4
function TestVrovelMissions2To4:test_inspecting_and_docking_with_the_dantooine_shuttle_completes_inspect_4()
	local player = chain({ V.I4 })
	local q = begin(player, V.I4)

	pump(2500, V.I4 .. " setup")

	local cargo = templateCargo("vortex_mission_4_shuttle")
	local target = spyShip("vortex_mission_4_shuttle", cargo, "vortex_mission_4_shuttle", "space_dantooine")
	local hash = getHashCode(cargo)

	lu.assertEquals(cargo, "ship_starting_coordinates", "the template carries the inspect_cargo row ship_starting_coordinates")
	H.inspect(player, target, hash)
	pump(0, V.I4 .. " inspect")
	lu.assertTrue(isActive(player, q), V.I4 .. ": inspecting alone does not complete it")
	H.dock(player, target, hash)
	pump(0, V.I4 .. " dock")
	pump(1000, V.I4 .. " after the dock")
	lu.assertTrue(isComplete(player, q), V.I4 .. ": complete after docking with the shuttle")
end

-- A-5 (c): inspecting the Lok shuttle does not complete inspect 4 (a different cargo)
function TestVrovelMissions2To4:test_the_lok_shuttle_does_not_complete_inspect_4()
	local player = chain({ V.I4 })
	local q = begin(player, V.I4)

	pump(2500, V.I4 .. " setup")

	local cargo = templateCargo("vortex_mission_1_shuttle")
	local target = spyShip("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle", "space_dantooine")
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, V.I4 .. " inspect")
	H.dock(player, target, hash)
	pump(3000, V.I4 .. " dock")
	lu.assertFalse(isComplete(player, q), V.I4 .. ": not complete with the Lok shuttle's cargo")
	lu.assertTrue(isActive(player, q), V.I4 .. ": still active")
end

---------------------------------------------------------------------------------------------
-- A-5 (d): the three duties
---------------------------------------------------------------------------------------------

TestVrovelDuties = {}

function TestVrovelDuties:setUp() H.reset() end

function TestVrovelDuties:tearDown() AC.tearDown() end

local function startedDuty(global)
	local q = quest(global)

	H.reset()
	q:start()

	if q.questType == "recovery_duty" then
		AC.resolveRecoveryPoints(q)
	end

	local player = DRS.player(q, { pilot = "rebel" })

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q, player
end

-- A-5 (d): each duty starts and is reported active
function TestVrovelDuties:test_each_duty_starts_once_is_active_and_starts_no_side_quest()
	for _, global in ipairs(V.DUTIES) do
		local q = quest(global)
		local others = {}

		H.reset()

		for _, g in ipairs(V.GLOBALS) do
			if g ~= global then
				others[g] = H.spyOn(quest(g), "startQuest")
			end
		end

		q:start()

		if q.questType == "recovery_duty" then
			AC.resolveRecoveryPoints(q)
		end

		local player = DRS.player(q, { pilot = "rebel" })

		q:startQuest(player, "")
		pump(60000, global .. " running")
		lu.assertTrue(isActive(player, q), global .. ": reported active by SpaceHelpers:isSpaceQuestActive")

		for g, calls in pairs(others) do
			lu.assertEquals(#calls, 0, global .. ": started " .. g .. " (a duty starts no side quest)")
		end

		H.restoreSpies()
	end
end

-- A-5 (d): destroy duty 6 spawns waves from the first ship list only, and the boss wave leads with the boss
function TestVrovelDuties:test_destroy_duty_6_waves_come_from_the_first_ship_list_and_the_boss_wave_leads_with_the_boss()
	local q, player = startedDuty(V.DUTY6)
	local area = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":targetArea:"))
	local first = unionOf({ V.expected()[V.DUTY6].shipTypes[1] })

	lu.assertNotNil(area, V.DUTY6 .. ": startQuest in the quest zone spawns a target area")
	H.enterArea(area, player.rootParent)
	pump(4500, V.DUTY6 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, V.DUTY6 .. ": wave 1 spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(first[ship.shipName] == true, V.DUTY6 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is from shipTypes[1] (Core3's wave picker, R-4)")
		lu.assertEquals(ship.zone, "space_dantooine", V.DUTY6 .. ": wave ship " .. i .. " zone")
	end

	H.reset()

	local q2, p2 = startedDuty(V.DUTY6)

	writeData(p2.objectID .. ":" .. q2.className .. ":bossLevel:", 1)
	H.enterArea(getSceneObject(readData(p2.objectID .. ":" .. q2.className .. ":targetArea:")), p2.rootParent)
	pump(4500, V.DUTY6 .. " spawnAttackWave (boss)")
	lu.assertEquals(H.spawnedShips()[1] and H.spawnedShips()[1].shipName, "imp_tie_interceptor_tier3", V.DUTY6 .. ": the first ship of the boss wave is the boss")
end

-- A-5 (d): escort duty 5 spawns one of its two smugglers; its first wave comes from the listed attack ships
function TestVrovelDuties:test_escort_duty_5_spawns_one_of_the_two_smugglers_and_attacks_only_with_listed_ships()
	local q, player = startedDuty(V.DUTY5)
	local want = V.expected()[V.DUTY5]

	pump(2500, V.DUTY5 .. " setupEscort")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, V.DUTY5 .. " spawnEscortShip")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, V.DUTY5 .. ": the escort spawned")
	lu.assertTrue(unionOf({ want.escortShips })[escort.shipName] == true, V.DUTY5 .. ": the escort '" .. tostring(escort.shipName) .. "' is one of the two smugglers")

	local before = #H.spawnedShips()
	local allowed = unionOf(want.attackShips)

	for _ = 1, 100 do
		pump(1000, V.DUTY5 .. " waiting for the wave")

		if #newShips(before, escort) > 0 then
			break
		end
	end

	local attackers = newShips(before, escort)

	lu.assertTrue(#attackers >= 1, V.DUTY5 .. ": an attack wave spawned")

	for i, ship in ipairs(attackers) do
		lu.assertTrue(allowed[ship.shipName] == true, V.DUTY5 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

-- A-5 (d): recovery duty 7 spawns one of its three target ships with its two escorts
function TestVrovelDuties:test_recovery_duty_7_spawns_a_listed_target_with_two_fighter_escorts()
	local q, player = startedDuty(V.DUTY7)
	local want = V.expected()[V.DUTY7]

	pump(65000, V.DUTY7 .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, V.DUTY7 .. ": the recovery ship was spawned")
	lu.assertTrue(unionOf({ want.recoverShips })[ship.shipName] == true, V.DUTY7 .. ": the target '" .. tostring(ship.shipName) .. "' is one of the three listed ships")
	lu.assertEquals(ship.zone, "space_dantooine", V.DUTY7 .. ": the target zone")
	lu.assertEquals(countOf(names, "imp_tie_fighter_tier2") >= 2, true, V.DUTY7 .. ": the two fighter escorts among " .. table.concat(names, ", "))

	local allowed = unionOf({ want.recoverShips, want.escortShips })

	for i, name in ipairs(names) do
		lu.assertTrue(allowed[name] == true, V.DUTY7 .. ": ship " .. i .. " '" .. tostring(name) .. "' is one of the table's ships")
	end
end

-- A-5 (d): a second duty is refused while the first runs (one duty at a time)
function TestVrovelDuties:test_a_second_duty_is_refused_while_the_first_is_running()
	local d5, player = startedDuty(V.DUTY5)
	local d6 = quest(V.DUTY6)

	lu.assertTrue(isActive(player, d5), V.DUTY5 .. ": precondition: running")
	d6:start()
	d6:startQuest(player, "")
	pump(5000, V.DUTY6 .. " refused start")
	lu.assertFalse(isActive(player, d6), V.DUTY6 .. ": refused while another duty is held")
	lu.assertTrue(isActive(player, d5), V.DUTY5 .. ": still running")
end

-- A-5 (d): each duty is refused while another duty is held
function TestVrovelDuties:test_every_duty_is_refused_while_another_duty_is_held()
	for _, global in ipairs(V.DUTIES) do
		H.reset()

		local q = quest(global)

		q:start()

		local player = DRS.player(q, { pilot = "rebel" })

		DRS.holdDuty(player, "held_by_test")
		q:startQuest(player, "")
		pump(0, global .. " refused start")
		lu.assertFalse(isActive(player, q), global .. ": refused while another duty is held")
	end
end

return nil
