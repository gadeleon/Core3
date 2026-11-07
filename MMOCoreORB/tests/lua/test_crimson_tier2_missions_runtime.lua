-- Crimson Phoenix tier 2 part A: Major Eker's four missions and three duties run through the fakes.
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (A-3, A-4, A-5; Data mapping 1; FC-1 to FC-8; R-1 to R-3).
--
-- The oracle values are the spec's literals (crimson_tier2_data.lua, proven equal to the SWG .tab fixtures by test_crimson_tier2_missions_data.lua);
-- the quest tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua
-- error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. The inspect steps use the cargo of the REAL ship template
-- files, not a cargo set on the fake ship. The INSPECTION split on its own (windows, aborts) is test_crimson_tier2_missions_inspection.lua.
-- The hostility of the real AI cannot be checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local E = require("crimson_tier2_data")

E.load()

local function quest(global) return E.quest(global) end

local REBEL_HASH = getHashCode("rebel")

-- the templates of the reward items handed out so far (mission and datapad objects are not rewards)
local function rewardItems()
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if type(call[2]) == "string" and call[2]:find("^object/tangible/") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

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

	return E.flyer(E.IDENTITY[members[1]].zone)
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
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never see the ship's cargo (FC-2, SC-1)")

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
-- A-3, A-4: mission 3 (inspect -> surprise attack), then the other missions
---------------------------------------------------------------------------------------------

TestEkerMission3 = {}

function TestEkerMission3:setUp() H.reset() end

function TestEkerMission3:tearDown() AC.tearDown() end

-- A-3: started on the ground, nothing is set up until the pilot enters space_lok, then one waypoint at the spawner
function TestEkerMission3:test_inspect_15_started_on_the_ground_sets_nothing_up_until_lok_and_then_gives_one_waypoint_at_the_spawner()
	chain(E.M3)

	local q = quest(E.I15)
	local s = E.SPAWNERS.space_lok.yavin_rebel_mission_3
	local player = H.newPlayer({ zone = "yavin4", pilot = "rebel", parent = "starport" })

	q:startQuest(player, "")
	pump(5000, E.I15 .. " on the ground")
	lu.assertTrue(isActive(player, q), E.I15 .. ": active (the journal entry starts at once)")
	lu.assertEquals(#player.ghost.waypoints, 0, E.I15 .. ": no waypoint on the ground")

	H.zoneSwitch(player, "space_lok", { ship = REBEL_SHIP })
	pump(5000, E.I15 .. " entered space_lok")
	lu.assertEquals(#player.ghost.waypoints, 1, E.I15 .. ": one waypoint after entering space_lok")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, E.I15 .. ": the waypoint is at the yavin_rebel_mission_3 spawner")
end

-- A-3, FC-2: inspecting the Lok shuttle (its real template cargo) starts surprise 15 five seconds later; it spawns exactly three interceptors
function TestEkerMission3:test_inspecting_the_lok_shuttle_starts_surprise_15_which_spawns_exactly_three_interceptors()
	local player = chain(E.M3)
	local q, surprise = begin(player, E.I15), quest(E.S15)

	pump(2500, E.I15 .. " setup")

	local cargo = templateCargo("yavin_mission_3_shuttle")
	local target = spyShip("yavin_mission_3_shuttle", cargo, "yavin_rebel_mission_3", "space_lok")

	lu.assertEquals(cargo, "bomb_trigger", "the template carries the inspect_cargo row bomb_trigger")
	H.inspect(player, target, getHashCode(cargo))
	pump(0, E.I15 .. " inspect")
	pump(4800, E.I15 .. " inside the window")
	lu.assertTrue(isActive(player, q), E.I15 .. ": still active 4.8 s after the inspection")
	lu.assertFalse(isActive(player, surprise), E.S15 .. ": not active inside the window")
	pump(400, E.I15 .. " after the split")
	lu.assertTrue(isComplete(player, q), E.I15 .. ": complete 5.2 s after the inspection, without docking")
	pump(2000, E.S15 .. " start")
	lu.assertTrue(isActive(player, surprise), E.S15 .. ": active after the split")
	pump(60000, E.S15 .. " attack")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(names, { "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2", "imp_tie_interceptor_tier2" }, E.S15 .. ": the spawned ships (the target shuttle is a world agent, not spawned by the quest)")

	for i, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_lok", E.S15 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, E.S15 .. ": attacker " .. i .. " belongs to the pilot")
	end
end

-- A-3: destroying the three interceptors completes surprise 15; no mission 3 member stays active; nothing is paid by any step
function TestEkerMission3:test_destroying_the_three_interceptors_completes_the_chain_end_leaves_no_member_active_and_pays_nothing()
	local player = chain(E.M3)

	E.setState(player, E.I15, "complete")

	local q = begin(player, E.S15)

	pump(60000, E.S15 .. " attack")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	lu.assertEquals(#ships, 3, E.S15 .. ": three attackers")

	for k = 1, 3 do
		H.destroyShip(ships[k], player.rootParent)
		pump(1500, E.S15 .. " after kill " .. k)

		if k < 3 then
			lu.assertFalse(isComplete(player, q), E.S15 .. ": not complete after " .. k .. " of 3 kills")
		end
	end

	pump(8000, E.S15 .. " after kill 3")
	lu.assertTrue(isComplete(player, q), E.S15 .. ": the chain end is complete after all three interceptors are destroyed")

	for _, global in ipairs(E.M3) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 3 member is active")
	end

	lu.assertEquals(player.bankCredits or 0, 0, "credits paid by the chain end")
	lu.assertEquals(rewardItems(), {}, "reward items handed out (rewards are the trainer's)")
end

-- A-3: the whole mission in one run: inspect -> (first inspection + 5 s) surprise -> 3 kills, with no Lua error and nothing paid
function TestEkerMission3:test_the_whole_chain_runs_from_the_inspect_to_the_last_kill_without_a_lua_error_and_pays_nothing()
	local player = chain(E.M3)

	begin(player, E.I15)
	pump(2500, E.I15 .. " setup")

	local cargo = templateCargo("yavin_mission_3_shuttle")

	H.inspect(player, spyShip("yavin_mission_3_shuttle", cargo, "yavin_rebel_mission_3", "space_lok"), getHashCode(cargo))
	pump(8000, E.I15 .. " split")
	lu.assertTrue(isComplete(player, quest(E.I15)), E.I15 .. ": complete")
	lu.assertTrue(isActive(player, quest(E.S15)), E.S15 .. ": active")
	pump(60000, E.S15 .. " attack")

	for _, ship in ipairs({ table.unpack(H.spawnedShips()) }) do
		H.destroyShip(ship, player.rootParent)
		pump(1500, E.S15 .. " kill")
	end

	pump(8000, E.S15 .. " end")
	lu.assertTrue(isComplete(player, quest(E.S15)), E.S15 .. ": complete")
	lu.assertEquals(player.bankCredits or 0, 0, "credits paid")
	lu.assertEquals(rewardItems(), {}, "reward items handed out")
end

TestEkerMissions124 = {}

function TestEkerMissions124:setUp() H.reset() end

function TestEkerMissions124:tearDown() AC.tearDown() end

-- A-4 (a): escort 13 spawns the freighter in space_yavin4; the first wave comes after the 80 s attack delay and is one of the two lists
function TestEkerMissions124:test_escort_13_spawns_the_freighter_and_its_first_wave_after_80_seconds_is_one_of_the_two_lists()
	local player = chain({ E.E13 })
	local q = quest(E.E13)
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "yavin_mission_1_freighter", E.E13 .. ": the escort ship")
	lu.assertEquals(escort.zone, "space_yavin4", E.E13 .. ": the escort ship zone")

	local before = #H.spawnedShips()

	pump(60000, E.E13 .. " 60 s later")
	lu.assertEquals(#newShips(before, escort), 0, E.E13 .. ": no attack wave 60 s after the escort spawned (attackDelay 80)")

	for _ = 1, 40 do
		pump(1000, E.E13 .. " waiting for the wave")

		if #newShips(before, escort) > 0 then
			break
		end
	end

	local wave = shipNames(newShips(before, escort))
	local match = false

	for _, list in ipairs(E.expected()[E.E13].attackShips) do
		if table.concat(sorted(list), ",") == table.concat(sorted(wave), ",") then
			match = true
		end
	end

	lu.assertTrue(match, E.E13 .. ": the wave '" .. table.concat(wave, ",") .. "' is one of the two attack lists")
end

-- A-4 (a), A-4 (c): completing an escort ends its mission (no split)
function TestEkerMissions124:test_completing_escort_13_starts_no_other_quest()
	local player = chain({ E.E13 })
	local q = quest(E.E13)
	local starts = {}

	for _, global in ipairs(E.GLOBALS) do
		if global ~= E.E13 then
			starts[global] = H.spyOn(quest(global), "startQuest")
		end
	end

	flyEscort(q, player)
	q:completeQuest(player, true)
	pump(30000, E.E13 .. " completion")
	lu.assertTrue(isComplete(player, q), E.E13 .. ": complete")

	for global, calls in pairs(starts) do
		lu.assertEquals(#calls, 0, E.E13 .. ": started " .. global .. " (a single-quest mission splits nothing)")
	end
end

-- A-4 (b): inspect 14 gives one waypoint at the Yavin 4 shuttle spawner
function TestEkerMissions124:test_inspect_14_gives_one_waypoint_at_the_yavin_shuttle_spawner()
	local player = chain({ E.I14 })
	local s = E.SPAWNERS.space_yavin4.yavin_rebel_2_shuttle

	begin(player, E.I14)
	pump(2500, E.I14 .. " setup")
	lu.assertEquals(#player.ghost.waypoints, 1, E.I14 .. ": one waypoint")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, E.I14 .. ": the waypoint is at the yavin_rebel_2_shuttle spawner")
end

-- A-4 (b), FC-2, FC-3: inspecting and docking with the Yavin shuttle (its real template cargo) completes inspect 14, and it never splits
function TestEkerMissions124:test_inspecting_and_docking_with_the_yavin_shuttle_completes_inspect_14_and_starts_nothing()
	local player = chain({ E.I14 })
	local q = begin(player, E.I14)
	local starts = {}

	for _, global in ipairs(E.GLOBALS) do
		if global ~= E.I14 then
			starts[global] = H.spyOn(quest(global), "startQuest")
		end
	end

	pump(2500, E.I14 .. " setup")

	local cargo = templateCargo("yavin_mission_2_shuttle")
	local target = spyShip("yavin_mission_2_shuttle", cargo, "yavin_rebel_2_shuttle", "space_yavin4")
	local hash = getHashCode(cargo)

	lu.assertEquals(cargo, "patrol_routes", "the template carries the inspect_cargo row patrol_routes")
	H.inspect(player, target, hash)
	pump(0, E.I14 .. " inspect")
	lu.assertTrue(isActive(player, q), E.I14 .. ": inspecting alone does not complete it")
	H.dock(player, target, hash)
	pump(0, E.I14 .. " dock")
	pump(30000, E.I14 .. " after the dock")
	lu.assertTrue(isComplete(player, q), E.I14 .. ": complete after docking with the shuttle")

	for global, calls in pairs(starts) do
		lu.assertEquals(#calls, 0, E.I14 .. ": started " .. global .. " (inspect 14 never splits)")
	end
end

-- A-4 (b): inspecting the Lok shuttle (bomb_trigger) does not complete inspect 14 (a different cargo) and does not split it
function TestEkerMissions124:test_the_lok_shuttle_does_not_complete_inspect_14()
	local player = chain({ E.I14 })
	local q = begin(player, E.I14)

	pump(2500, E.I14 .. " setup")

	local cargo = templateCargo("yavin_mission_3_shuttle")
	local target = spyShip("yavin_mission_3_shuttle", cargo, "yavin_rebel_mission_3", "space_yavin4")
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, E.I14 .. " inspect")
	H.dock(player, target, hash)
	pump(30000, E.I14 .. " dock")
	lu.assertFalse(isComplete(player, q), E.I14 .. ": not complete with the Lok shuttle's cargo")
	lu.assertTrue(isActive(player, q), E.I14 .. ": still active")
end

-- A-4 (c): escort 16 spawns the Nym smuggler in space_lok with the pilot's ship faction as its own and the pilot's faction as an ally; first wave after 70 s
function TestEkerMissions124:test_escort_16_spawns_the_nym_smuggler_in_lok_with_the_pilots_faction_and_its_first_wave_comes_after_70_seconds()
	local player = chain({ E.E16 })
	local q = quest(E.E16)
	local escort = flyEscort(q, player)

	lu.assertEquals(escort.shipName, "nym_smuggler", E.E16 .. ": the escort ship")
	lu.assertEquals(escort.zone, "space_lok", E.E16 .. ": the escort ship zone")
	lu.assertEquals(escort.shipFactionString, "rebel", E.E16 .. ": the escort carries the pilot's ship faction")
	lu.assertEquals(escort.factionAllies, { REBEL_HASH }, E.E16 .. ": the pilot's faction is the escort's ally")

	local before = #H.spawnedShips()

	pump(50000, E.E16 .. " 50 s later")
	lu.assertEquals(#newShips(before, escort), 0, E.E16 .. ": no attack wave 50 s after the escort spawned (attackDelay 70)")

	for _ = 1, 40 do
		pump(1000, E.E16 .. " waiting for the wave")

		if #newShips(before, escort) > 0 then
			break
		end
	end

	local wave = shipNames(newShips(before, escort))
	local match = false

	for _, list in ipairs(E.expected()[E.E16].attackShips) do
		if table.concat(sorted(list), ",") == table.concat(sorted(wave), ",") then
			match = true
		end
	end

	lu.assertTrue(match, E.E16 .. ": the wave '" .. table.concat(wave, ",") .. "' is one of the two attack lists")
end

---------------------------------------------------------------------------------------------
-- A-5: the three duties
---------------------------------------------------------------------------------------------

TestEkerDuties = {}

function TestEkerDuties:setUp() H.reset() end

function TestEkerDuties:tearDown() AC.tearDown() end

local function dutyPlayer(q)
	return H.newPlayer({
		zone = q.questZone,
		pilot = "rebel",
		ship = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y, factionHash = REBEL_HASH },
	})
end

local function startedDuty(global)
	local q = quest(global)

	H.reset()
	q:start()

	if q.questType == "recovery_duty" then
		AC.resolveRecoveryPoints(q)
	end

	local player = dutyPlayer(q)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q, player
end

-- A-5: each duty starts in space_yavin4, is reported active and starts no side quest
function TestEkerDuties:test_each_duty_starts_once_is_active_and_starts_no_side_quest()
	for _, global in ipairs(E.DUTIES) do
		local q = quest(global)
		local others = {}

		H.reset()

		for _, g in ipairs(E.GLOBALS) do
			if g ~= global then
				others[g] = H.spyOn(quest(g), "startQuest")
			end
		end

		q:start()

		if q.questType == "recovery_duty" then
			AC.resolveRecoveryPoints(q)
		end

		local player = dutyPlayer(q)

		q:startQuest(player, "")
		pump(60000, global .. " running")
		lu.assertEquals(q.questZone, "space_yavin4", global .. ": zone")
		lu.assertTrue(isActive(player, q), global .. ": reported active by SpaceHelpers:isSpaceQuestActive")

		for g, calls in pairs(others) do
			lu.assertEquals(#calls, 0, global .. ": started " .. g .. " (a duty starts no side quest)")
		end

		H.restoreSpies()
	end
end

-- A-5, FC-5: destroy duty 9's waves are Hutt ships from the one list, every agent gets the pilot's ship faction as an enemy, and the boss wave leads with the boss
function TestEkerDuties:test_destroy_duty_9_spawns_only_hutt_ships_hostile_to_the_pilots_faction_and_the_boss_wave_leads_with_the_boss()
	local q, player = startedDuty(E.DUTY9)
	local area = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":targetArea:"))
	local first = unionOf({ E.expected()[E.DUTY9].shipTypes[1] })

	lu.assertNotNil(area, E.DUTY9 .. ": startQuest in the quest zone spawns a target area")
	H.enterArea(area, player.rootParent)
	pump(4500, E.DUTY9 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, E.DUTY9 .. ": wave 1 spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(first[ship.shipName] == true, E.DUTY9 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is from the one Hutt list")
		lu.assertEquals(ship.zone, "space_yavin4", E.DUTY9 .. ": wave ship " .. i .. " zone")
		lu.assertEquals(ship.factionEnemies, { REBEL_HASH }, E.DUTY9 .. ": ship " .. i .. " has the pilot's ship faction as an enemy (FC-5)")
	end

	H.reset()

	local q2, p2 = startedDuty(E.DUTY9)

	writeData(p2.objectID .. ":" .. q2.className .. ":bossLevel:", 1)
	H.enterArea(getSceneObject(readData(p2.objectID .. ":" .. q2.className .. ":targetArea:")), p2.rootParent)
	pump(4500, E.DUTY9 .. " spawnAttackWave (boss)")

	local boss = H.spawnedShips()[1]

	lu.assertEquals(boss and boss.shipName, "hutt_pirate_s02_tier3", E.DUTY9 .. ": the first ship of the boss wave is the boss")
	lu.assertEquals(boss and boss.factionEnemies, { REBEL_HASH }, E.DUTY9 .. ": the boss has the pilot's ship faction as an enemy (FC-5)")
end

-- A-5: escort duty 10 spawns one of its five freighters; its first wave comes from the listed attack ships
function TestEkerDuties:test_escort_duty_10_spawns_one_of_its_freighters_and_attacks_only_with_listed_ships()
	local q, player = startedDuty(E.DUTY10)
	local want = E.expected()[E.DUTY10]

	pump(2500, E.DUTY10 .. " setupEscort")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, E.DUTY10 .. " spawnEscortShip")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, E.DUTY10 .. ": the escort spawned")
	lu.assertTrue(unionOf({ want.escortShips })[escort.shipName] == true, E.DUTY10 .. ": the escort '" .. tostring(escort.shipName) .. "' is one of the listed freighters")

	local before = #H.spawnedShips()
	local allowed = unionOf(want.attackShips)

	for _ = 1, 100 do
		pump(1000, E.DUTY10 .. " waiting for the wave")

		if #newShips(before, escort) > 0 then
			break
		end
	end

	local attackers = newShips(before, escort)

	lu.assertTrue(#attackers >= 1, E.DUTY10 .. ": an attack wave spawned")

	for i, ship in ipairs(attackers) do
		lu.assertTrue(allowed[ship.shipName] == true, E.DUTY10 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

-- A-5: recovery duty 12 spawns one of its three target ships with escorts, only ships of its lists
function TestEkerDuties:test_recovery_duty_12_spawns_a_listed_target_with_fighter_escorts_and_only_listed_ships()
	local q, player = startedDuty(E.DUTY12)
	local want = E.expected()[E.DUTY12]

	pump(65000, E.DUTY12 .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, E.DUTY12 .. ": the recovery ship was spawned")
	lu.assertTrue(unionOf({ want.recoverShips })[ship.shipName] == true, E.DUTY12 .. ": the target '" .. tostring(ship.shipName) .. "' is one of the three listed ships")
	lu.assertEquals(ship.zone, "space_yavin4", E.DUTY12 .. ": the target zone")
	lu.assertTrue(countOf(names, "imp_tie_fighter_tier2") >= 2, E.DUTY12 .. ": the two fighter escorts among " .. table.concat(names, ", "))

	local allowed = unionOf({ want.recoverShips, want.escortShips })

	for i, name in ipairs(names) do
		lu.assertTrue(allowed[name] == true, E.DUTY12 .. ": ship " .. i .. " '" .. tostring(name) .. "' is one of the table's ships")
	end
end

-- A-5: a second duty is refused while the first runs (one duty at a time)
function TestEkerDuties:test_a_second_duty_is_refused_while_the_first_is_running()
	local d10, player = startedDuty(E.DUTY10)
	local d9 = quest(E.DUTY9)

	lu.assertTrue(isActive(player, d10), E.DUTY10 .. ": precondition: running")
	d9:start()
	d9:startQuest(player, "")
	pump(5000, E.DUTY9 .. " refused start")
	lu.assertFalse(isActive(player, d9), E.DUTY9 .. ": refused while another duty is held")
	lu.assertTrue(isActive(player, d10), E.DUTY10 .. ": still running")
end

-- A-5: each duty is refused while another duty is held
function TestEkerDuties:test_every_duty_is_refused_while_another_duty_is_held()
	for _, global in ipairs(E.DUTIES) do
		H.reset()

		local q = quest(global)

		q:start()

		local player = dutyPlayer(q)

		DRS.holdDuty(player, "held_by_test")
		q:startQuest(player, "")
		pump(0, global .. " refused start")
		lu.assertFalse(isActive(player, q), global .. ": refused while another duty is held")
	end
end

return nil
