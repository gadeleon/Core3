-- Vortex tier 3 part A: Brother Ezkiel's four missions run through the fakes, split by split.
-- Spec: .claude/work/vortex-tier3-ezkiel-missions/01-spec.md (A-3, A-4, A-5, A-6; Data mapping 1; FV-1, FV-2, FV-3; R-1, R-2, R-4, R-5).
--
-- The oracle values are the spec's literals (vortex_tier3_data.lua, proven equal to the SWG .tab fixtures by test_vortex_tier3_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and
-- pumps the split delay (the alert fires at the delay; the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL ship template files
-- (naboo_tier3_imperial_spy, blacklight_pirate_fighter_quest), not a cargo set on the fake ship. Flying the survivals and the battles is covered by their type
-- features: this file stops at "active / spawned" for them. The hostility of the real AI (R-1) cannot be checked here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local W = require("vortex_tier3_data")

W.load()

local function quest(global) return W.quest(global) end

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
	local p = W.POINTS[zone][name] or (W.SPAWNERS[zone] or {})[name]

	assert(p ~= nil, "no spec point " .. name .. " in " .. zone)
	return p
end

-- A fresh world with the static areas of every member of the mission's chain, and the pilot in a Rebel ship in the mission's zone
local function chain(n)
	H.reset()

	local members = W.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return W.flyer(W.IDENTITY[members[1]].zone)
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
	for _, global in ipairs(W.CHAINS[n]) do
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
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FV-3, SC-1)")

	return t.cargoString
end

-- Inspects and docks with a ship carrying the template's cargo (`as` is the ship the target is; default the quest's own)
local function inspectAndDock(player, q, shipName, spawner)
	pump(2500, q.className .. " setup")

	local cargo = templateCargo(shipName)
	local target = spyShip(shipName, cargo, spawner, q.questZone)
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, q.className .. " inspect")
	H.dock(player, target, hash)
	pump(0, q.className .. " dock")
	pump(1000, q.className .. " after the dock")

	return cargo
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

-- A patrol flown to its trigger point: point 1 .. `point`, each entered once
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
-- A-3: the two inspect targets (the template's real cargo string)
---------------------------------------------------------------------------------------------

TestEzkielInspectCargo = {}

function TestEzkielInspectCargo:setUp() H.reset() end

function TestEzkielInspectCargo:tearDown() AC.tearDown() end

-- A-3: inspecting and docking with the Imperial spy (its template's cargo) completes inspect 1_c; one waypoint at its spawner
function TestEzkielInspectCargo:test_inspecting_the_imperial_spy_with_its_templates_cargo_completes_inspect_1_c_and_gives_one_waypoint_at_the_spawner()
	local player = chain(1)
	local q = begin(player, W.M1[4])
	local s = pointOf("space_dantooine", "naboo_rebel_tier3_inspect_target")

	pump(2500, W.M1[4] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, W.M1[4] .. ": one waypoint at the spawner naboo_rebel_tier3_inspect_target")

	local cargo = inspectAndDock(player, q, "naboo_tier3_imperial_spy", "naboo_rebel_tier3_inspect_target")

	lu.assertEquals(cargo, "experiment_information", "the template carries the inspect_cargo row experiment_information")
	lu.assertTrue(isComplete(player, q), W.M1[4] .. ": complete after docking with the Imperial spy")
end

-- A-3: the pirate fighter's cargo does not complete inspect 1_c
function TestEzkielInspectCargo:test_inspecting_the_pirate_fighter_does_not_complete_inspect_1_c()
	local player = chain(1)
	local q = begin(player, W.M1[4])

	inspectAndDock(player, q, "blacklight_pirate_fighter_quest", "naboo_rebel_tier3_inspect_target")
	pump(3000, W.M1[4] .. " after the dock")
	lu.assertFalse(isComplete(player, q), W.M1[4] .. ": not complete with the pirate fighter's cargo (leader_location)")
	lu.assertTrue(isActive(player, q), W.M1[4] .. ": still active")
end

-- A-3: inspecting and docking with the pirate fighter (its template's cargo) completes inspect 2_d; one waypoint at its spawner
function TestEzkielInspectCargo:test_inspecting_the_pirate_fighter_with_its_templates_cargo_completes_inspect_2_d_and_gives_one_waypoint_at_the_spawner()
	local player = chain(2)
	local q = begin(player, W.M2[5])
	local s = pointOf("space_dantooine", "naboo_rebel_tier3_pirate_leader_inspect")

	pump(2500, W.M2[5] .. " setup")
	lu.assertEquals(waypointsAt(player, s[1], s[2], s[3]), 1, W.M2[5] .. ": one waypoint at the spawner naboo_rebel_tier3_pirate_leader_inspect")

	local cargo = inspectAndDock(player, q, "blacklight_pirate_fighter_quest", "naboo_rebel_tier3_pirate_leader_inspect")

	lu.assertEquals(cargo, "leader_location", "the template carries the inspect_cargo row leader_location")
	lu.assertTrue(isComplete(player, q), W.M2[5] .. ": complete after docking with the pirate fighter")
end

-- A-3: the Imperial spy's cargo does not complete inspect 2_d
function TestEzkielInspectCargo:test_inspecting_the_imperial_spy_does_not_complete_inspect_2_d()
	local player = chain(2)
	local q = begin(player, W.M2[5])

	inspectAndDock(player, q, "naboo_tier3_imperial_spy", "naboo_rebel_tier3_pirate_leader_inspect")
	pump(3000, W.M2[5] .. " after the dock")
	lu.assertFalse(isComplete(player, q), W.M2[5] .. ": not complete with the Imperial spy's cargo (experiment_information)")
	lu.assertTrue(isActive(player, q), W.M2[5] .. ": still active")
end

-- A-3: a ship with another cargo does not complete either inspect
function TestEzkielInspectCargo:test_a_ship_with_another_cargo_does_not_complete_inspect_1_c()
	local player = chain(1)
	local q = begin(player, W.M1[4])

	pump(2500, W.M1[4] .. " setup")

	local target = spyShip("naboo_tier3_imperial_spy", "stolen_data", "naboo_rebel_tier3_inspect_target", "space_dantooine")
	local hash = getHashCode("stolen_data")

	H.inspect(player, target, hash)
	pump(0, W.M1[4] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, W.M1[4] .. " dock")
	lu.assertFalse(isComplete(player, q), W.M1[4] .. ": not complete with the wrong cargo")
end

---------------------------------------------------------------------------------------------
-- A-4: mission 1
---------------------------------------------------------------------------------------------

TestEzkielChain1 = {}

function TestEzkielChain1:setUp() H.reset() end

function TestEzkielChain1:tearDown() AC.tearDown() end

-- A-4: started on the ground, nothing is set up until the pilot enters space_dantooine, then the target and two escorts spawn after 10 s
function TestEzkielChain1:test_assassinate_1_started_on_the_ground_sets_nothing_up_until_dantooine_and_then_spawns_the_target_and_two_escorts_after_ten_seconds()
	chain(1)

	local q = quest(W.M1[1])
	local player = H.newPlayer({ zone = "tatooine", pilot = "rebel", parent = "starport" })

	q:startQuest(player, "")
	pump(15000, W.M1[1] .. " on the ground")
	lu.assertTrue(isActive(player, q), W.M1[1] .. ": active (the journal entry starts at once)")
	lu.assertEquals(#H.spawnedShips(), 0, W.M1[1] .. ": no ship on the ground")

	H.zoneSwitch(player, "space_dantooine", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(9000, W.M1[1] .. " entered space_dantooine")
	lu.assertEquals(#H.spawnedShips(), 0, W.M1[1] .. ": nothing spawned 9 s after entering (arrivalDelay 10)")
	pump(5000, W.M1[1] .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "tieadvanced_inquisitor_tier3", "imp_tie_interceptor_tier3", "imp_tie_interceptor_tier3" }, W.M1[1] .. ": the target and two escorts")
	lu.assertTrue(ships[1].isSquadronLeader, W.M1[1] .. ": the target leads the squadron")

	local p = pointOf("space_dantooine", "corellia_imperial_tier4_recovery1_2")

	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, W.M1[1] .. ": the target spawns at targetPatrols[1] (corellia_imperial_tier4_recovery1_2)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dantooine", W.M1[1] .. ": ship " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, W.M1[1] .. ": ship " .. i .. " belongs to the pilot")
	end
end

-- A-4, FV-8: mustDestroyEscort false, the target alone completes assassinate 1 and escort 1_a follows 5 s later and spawns the Imperial spy
function TestEzkielChain1:test_killing_the_target_alone_completes_assassinate_1_and_the_escort_starts_five_seconds_later_with_the_imperial_spy()
	local player = chain(1)
	local q = quest(W.M1[1])
	local ships = deployedShips(player, W.M1[1], 14000)

	lu.assertEquals(#ships, 3, W.M1[1] .. ": precondition: target and two escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, W.M1[1] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), W.M1[1] .. ": complete with the escorts still alive (mustDestroyEscort false)")

	local escort = quest(W.M1[2])

	pump(2000, W.M1[1] .. " before the split")
	lu.assertFalse(isActive(player, escort), W.M1[2] .. ": not active 3.5 s after the kill (sideQuestDelay 5)")
	pump(5000, W.M1[1] .. " split start")
	lu.assertTrue(isActive(player, escort), W.M1[2] .. ": active after the split")

	pump(2500, W.M1[2] .. " setup")

	local start = readData(player.objectID .. escort.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(escort, start), player.rootParent)
	pump(11000, W.M1[2] .. " escort spawn")

	local spy = getSceneObject(readData(player.objectID .. ":" .. escort.className .. ":escortID:"))

	lu.assertNotNil(spy, W.M1[2] .. ": the escort ship spawned")
	lu.assertEquals(spy.shipName, "naboo_tier3_imperial_spy", W.M1[2] .. ": the escorted ship")
	lu.assertEquals(spy.zone, "space_dantooine", W.M1[2] .. ": the escorted ship zone")
end

-- A-4, FV-1: completing assassinate 1 starts escort 1_a 5 s later
function TestEzkielChain1:test_completing_assassinate_1_starts_escort_1_a_after_five_seconds()
	local player = chain(1)

	begin(player, W.M1[1])
	completeAndSplit(player, W.M1[1], W.M1[2], 5)
end

-- A-4, FV-1: completing escort 1_a starts survival 1_b after 15 s (triggerDelay 10 + 5)
function TestEzkielChain1:test_completing_escort_1_a_starts_survival_1_b_after_fifteen_seconds()
	local player = chain(1)
	local q = quest(W.M1[2])

	flyEscort(q, player)
	lu.assertFalse(isActive(player, quest(W.M1[3])), W.M1[3] .. ": not active during the escort")
	completeAndSplit(player, W.M1[2], W.M1[3], 15)
end

-- A-4: survival 1_b is active at its point with a waypoint; completing it starts inspect 1_c 5 s later
function TestEzkielChain1:test_survival_1_b_is_active_at_its_point_and_completing_it_starts_inspect_1_c_five_seconds_later()
	local player = chain(1)
	local q = begin(player, W.M1[3])
	local p = pointOf("space_dantooine", "naboo_rebel_tier3_survival_point")

	pump(5000, W.M1[3] .. " start")
	lu.assertTrue(isActive(player, q), W.M1[3] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M1[3] .. ": one waypoint at naboo_rebel_tier3_survival_point")
	completeAndSplit(player, W.M1[3], W.M1[4], 5)
end

-- A-4, FV-1: completing inspect 1_c (docking with the spy) starts delivery_no_pickup 1_d after 15 s (triggerDelay 10 + 5)
function TestEzkielChain1:test_completing_inspect_1_c_starts_delivery_1_d_after_fifteen_seconds()
	local player = chain(1)
	local q = begin(player, W.M1[4])

	inspectAndDock(player, q, "naboo_tier3_imperial_spy", "naboo_rebel_tier3_inspect_target")
	lu.assertTrue(isComplete(player, q), W.M1[4] .. ": complete after docking with the spy")
	pump(11000, W.M1[4] .. " 12 s after the dock")
	lu.assertFalse(isActive(player, quest(W.M1[5])), W.M1[5] .. ": not active 12 s after the dock (the split is 15 s, not 5 or 10)")
	pump(6500, W.M1[4] .. " 18.5 s after the dock")
	lu.assertTrue(isActive(player, quest(W.M1[5])), W.M1[5] .. ": active 18.5 s after the dock")
end

-- A-4: delivery_no_pickup 1_d delivers at its point; completing it leaves no mission 1 member active and the chain end complete
function TestEzkielChain1:test_delivery_1_d_sets_up_at_its_point_and_completing_it_leaves_no_member_active_and_the_chain_end_complete()
	local player = chain(1)

	for _, global in ipairs({ W.M1[1], W.M1[2], W.M1[3], W.M1[4] }) do
		W.setState(player, global, "complete")
	end

	local q = begin(player, W.M1[5])

	deliveryArea(W.M1[5])

	local p = pointOf("space_dantooine", "naboo_rebel_tier3_delivery_point_1")

	lu.assertEquals(lastAreaCall(), { "space_dantooine", p[1], p[2], p[3] }, W.M1[5] .. ": the delivery area (zone, x, z, y)")
	pump(10000, W.M1[5] .. " running")
	lu.assertTrue(isActive(player, q), W.M1[5] .. ": still active")
	completeAndSplit(player, W.M1[5], nil)
	pump(8000, W.M1[5] .. " after completion")
	noMemberActive(player, 1)
	lu.assertTrue(isComplete(player, q), W.M1[5] .. ": the chain end is complete")
end

---------------------------------------------------------------------------------------------
-- A-5: mission 2
---------------------------------------------------------------------------------------------

TestEzkielChain2 = {}

function TestEzkielChain2:setUp() H.reset() end

function TestEzkielChain2:tearDown() AC.tearDown() end

-- A-5: battle 2 sets up at its point: a waypoint there, the four Spynet allies after 80 s and the seven Blacklight enemies after 110 s, all in space_dantooine
function TestEzkielChain2:test_battle_2_sets_up_at_its_point_with_four_spynet_allies_and_seven_blacklight_enemies()
	local player = chain(2)
	local q = begin(player, W.M2[1])
	local p = pointOf("space_dantooine", "naboo_rebel_tier3_battle_point")

	pump(5000, W.M2[1] .. " setup")
	lu.assertTrue(isActive(player, q), W.M2[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M2[1] .. ": one waypoint at naboo_rebel_tier3_battle_point")
	lu.assertEquals(#H.spawnedShips(), 0, W.M2[1] .. ": nothing spawned 5 s after the start (allyArrivalDelay 80)")
	pump(80000, W.M2[1] .. " allies arrive")

	local allies = shipNames(H.spawnedShips())

	lu.assertEquals(sorted(allies), sorted(W.expected()[W.M2[1]].allyForce), W.M2[1] .. ": the allies that arrive first (spynet_assassin, 2 spynet_special_ops, spynet_bomber)")
	pump(30000, W.M2[1] .. " enemies arrive")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 11, W.M2[1] .. ": 4 allies + 7 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "blacklight_assassin_tier3"), 1, W.M2[1] .. ": one blacklight_assassin_tier3 enemy")
	lu.assertEquals(countOf(all, "blacklight_fighter_tier3"), 3, W.M2[1] .. ": three blacklight_fighter_tier3 enemies")
	lu.assertEquals(countOf(all, "blacklight_bomber_tier3"), 3, W.M2[1] .. ": three blacklight_bomber_tier3 enemies")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dantooine", W.M2[1] .. ": " .. tostring(ship.shipName) .. " zone")
	end
end

-- A-5, FV-1: completing battle 2 starts rescue 2_a 5 s later
function TestEzkielChain2:test_completing_battle_2_starts_rescue_2_a_five_seconds_later()
	local player = chain(2)

	begin(player, W.M2[1])
	pump(5000, W.M2[1] .. " setup")
	completeAndSplit(player, W.M2[1], W.M2[2], 5)
end

-- A-5: rescue 2_a spawns the Spynet fighter with no arrival delay; completing it starts patrol 2_b 5 s later
function TestEzkielChain2:test_rescue_2_a_spawns_the_spynet_fighter_without_an_arrival_delay_and_completing_it_starts_patrol_2_b()
	local player = chain(2)

	begin(player, W.M2[2])
	pump(10000, W.M2[2] .. " start")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "spynet_fighter_tier3") >= 1, W.M2[2] .. ": spynet_fighter_tier3 spawned within 10 s; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, W.M2[2], W.M2[3], 5)
end

-- A-5, FV-2: patrol 2_b; reaching point 3 completes it 10 s later (plain triggerDelay) and starts surprise 2_c; point 4 is never flown
function TestEzkielChain2:test_reaching_patrol_point_3_completes_patrol_2_b_ten_seconds_later_and_starts_surprise_2_c()
	local player = chain(2)
	local q = begin(player, W.M2[3])
	local surprise = quest(W.M2[4])

	flyPatrolTo(q, player, 2)
	lu.assertTrue(isActive(player, q), W.M2[3] .. ": still active at point 2")
	pump(15000, W.M2[3] .. " 15 s after point 2")
	lu.assertFalse(isActive(player, surprise), W.M2[4] .. ": the split does not fire at point 2")
	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, W.M2[3] .. " point 3")
	pump(8000, W.M2[3] .. " 8.5 s after point 3")
	lu.assertFalse(isComplete(player, q), W.M2[3] .. ": not complete 8.5 s after point 3 (sideQuestDelay 10)")
	lu.assertFalse(isActive(player, surprise), W.M2[4] .. ": not active 8.5 s after point 3")
	pump(3000, W.M2[3] .. " 11.5 s after point 3")
	lu.assertTrue(isComplete(player, q), W.M2[3] .. ": complete 11.5 s after point 3 (point 4 is never flown)")
	lu.assertTrue(isActive(player, surprise), W.M2[4] .. ": surprise 2_c is active")
end

-- A-5: surprise 2_c spawns four Blacklight fighters in space_dantooine; destroying them starts inspect 2_d 12 s later (triggerDelay 7 + 5)
function TestEzkielChain2:test_surprise_2_c_spawns_four_blacklight_fighters_and_destroying_them_starts_inspect_2_d_twelve_seconds_later()
	local player = chain(2)
	local q = begin(player, W.M2[4])

	pump(60000, W.M2[4] .. " attack")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3" }, W.M2[4] .. ": spawned attackers")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dantooine", W.M2[4] .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, W.M2[4] .. ": attacker " .. i .. " belongs to the pilot")
	end

	for i = 1, 3 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, W.M2[4] .. " after kill " .. i)
		lu.assertFalse(isComplete(player, q), W.M2[4] .. ": not complete after " .. i .. " of 4 kills")
	end

	H.destroyShip(ships[4], player.rootParent)
	pump(1500, W.M2[4] .. " after kill 4")
	lu.assertTrue(isComplete(player, q), W.M2[4] .. ": complete after all four attackers are destroyed")
	pump(7000, W.M2[4] .. " 8.5 s after the last kill")
	lu.assertFalse(isActive(player, quest(W.M2[5])), W.M2[5] .. ": not active 8.5 s after the last kill (the split is 12 s)")
	pump(5000, W.M2[4] .. " 13.5 s after the last kill")
	lu.assertTrue(isActive(player, quest(W.M2[5])), W.M2[5] .. ": active 13.5 s after the last kill")
end

-- A-5: completing the chain end (inspect 2_d) wins mission 2 with no member active
function TestEzkielChain2:test_completing_inspect_2_d_makes_the_chain_end_complete_with_no_member_active()
	local player = chain(2)

	for _, global in ipairs({ W.M2[1], W.M2[2], W.M2[3], W.M2[4] }) do
		W.setState(player, global, "complete")
	end

	local q = begin(player, W.M2[5])

	inspectAndDock(player, q, "blacklight_pirate_fighter_quest", "naboo_rebel_tier3_pirate_leader_inspect")
	pump(8000, W.M2[5] .. " after completion")
	lu.assertTrue(isComplete(player, q), W.M2[5] .. ": the chain end is complete")
	noMemberActive(player, 2)
end

---------------------------------------------------------------------------------------------
-- A-6 (a): mission 3
---------------------------------------------------------------------------------------------

TestEzkielChain3 = {}

function TestEzkielChain3:setUp() H.reset() end

function TestEzkielChain3:tearDown() AC.tearDown() end

-- A-6 (a), FV-2: patrol 3 in space_endor hands off at point 3 after 8 s to surprise 3_a
function TestEzkielChain3:test_patrol_3_hands_off_at_point_3_after_eight_seconds_to_surprise_3_a()
	local player = chain(3)
	local q = begin(player, W.M3[1])
	local surprise = quest(W.M3[2])

	flyPatrolTo(q, player, 3)
	pump(6500, W.M3[1] .. " 7 s after point 3")
	lu.assertFalse(isComplete(player, q), W.M3[1] .. ": not complete 7 s after point 3 (sideQuestDelay 8)")
	lu.assertFalse(isActive(player, surprise), W.M3[2] .. ": not active 7 s after point 3")
	pump(2500, W.M3[1] .. " 9.5 s after point 3")
	lu.assertTrue(isComplete(player, q), W.M3[1] .. ": complete 9.5 s after point 3")
	lu.assertTrue(isActive(player, surprise), W.M3[2] .. ": surprise 3_a is active")
end

-- A-6 (a): surprise 3_a spawns four Blacklight assassins in space_endor; completing it starts survival 3_b 5 s later
function TestEzkielChain3:test_surprise_3_a_spawns_four_blacklight_assassins_in_endor_and_completing_it_starts_survival_3_b()
	local player = chain(3)

	begin(player, W.M3[2])
	pump(60000, W.M3[2] .. " attack")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "blacklight_assassin_tier3", "blacklight_assassin_tier3", "blacklight_assassin_tier3", "blacklight_assassin_tier3" }, W.M3[2] .. ": spawned attackers")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", W.M3[2] .. ": attacker " .. i .. " zone")
	end

	completeAndSplit(player, W.M3[2], W.M3[3], 5)
end

-- A-6 (a): survival 3_b is active at its point; completing it starts patrol 3_c 5 s later
function TestEzkielChain3:test_survival_3_b_is_active_at_its_point_and_completing_it_starts_patrol_3_c()
	local player = chain(3)
	local q = begin(player, W.M3[3])
	local p = pointOf("space_endor", "naboo_rebel_tier3_blacklight_point")

	pump(5000, W.M3[3] .. " start")
	lu.assertTrue(isActive(player, q), W.M3[3] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M3[3] .. ": one waypoint at naboo_rebel_tier3_blacklight_point")
	completeAndSplit(player, W.M3[3], W.M3[4], 5)
end

-- A-6 (a), R-5: patrol 3_c hands off at point 2 (not 3) after 10 s to assassinate 3_d
function TestEzkielChain3:test_patrol_3_c_hands_off_at_point_2_after_ten_seconds_to_assassinate_3_d()
	local player = chain(3)
	local q = begin(player, W.M3[4])
	local assassinate = quest(W.M3[5])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(15000, W.M3[4] .. " 15 s after point 1")
	lu.assertFalse(isActive(player, assassinate), W.M3[5] .. ": the split does not fire at point 1")
	lu.assertTrue(isActive(player, q), W.M3[4] .. ": still active after point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, W.M3[4] .. " point 2")
	pump(8000, W.M3[4] .. " 8.5 s after point 2")
	lu.assertFalse(isComplete(player, q), W.M3[4] .. ": not complete 8.5 s after point 2 (sideQuestDelay 10)")
	lu.assertFalse(isActive(player, assassinate), W.M3[5] .. ": not active 8.5 s after point 2")
	pump(3000, W.M3[4] .. " 11.5 s after point 2")
	lu.assertTrue(isComplete(player, q), W.M3[4] .. ": complete 11.5 s after point 2 (points 3 and 4 are never flown)")
	lu.assertTrue(isActive(player, assassinate), W.M3[5] .. ": assassinate 3_d is active")
end

-- A-6 (a): assassinate 3_d spawns the pirate leader and five escorts after 10 s at its first point
function TestEzkielChain3:test_assassinate_3_d_spawns_the_pirate_leader_and_five_escorts_after_ten_seconds()
	local player = chain(3)

	begin(player, W.M3[5])
	pump(9000, W.M3[5] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, W.M3[5] .. ": nothing spawned 9 s after the start (arrivalDelay 10)")
	pump(4000, W.M3[5] .. " deployTargets")

	local ships = H.spawnedShips()
	local p = pointOf("space_endor", "naboo_rebel_tier3_assassin_path_1")

	lu.assertEquals(shipNames(ships), { "blacklight_pirate_leader", "blacklight_assassin_tier3", "blacklight_fighter_tier3", "blacklight_fighter_tier3", "blacklight_bomber_tier3", "blacklight_fighter_tier3" },
		W.M3[5] .. ": the target and five escorts")
	lu.assertTrue(ships[1].isSquadronLeader, W.M3[5] .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, W.M3[5] .. ": the target spawns at targetPatrols[1] (naboo_rebel_tier3_assassin_path_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", W.M3[5] .. ": ship " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, W.M3[5] .. ": ship " .. i .. " belongs to the pilot")
	end
end

-- A-6 (a), FV-8: mustDestroyEscort: the target alone does not complete 3_d, all six ships do; the chain end is complete and no member is active
function TestEzkielChain3:test_killing_only_the_target_does_not_complete_assassinate_3_d_and_killing_all_six_does()
	local player = chain(3)
	local q = quest(W.M3[5])

	for _, global in ipairs({ W.M3[1], W.M3[2], W.M3[3], W.M3[4] }) do
		W.setState(player, global, "complete")
	end

	local ships = deployedShips(player, W.M3[5], 14000)

	lu.assertEquals(#ships, 6, W.M3[5] .. ": precondition: target and five escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, W.M3[5] .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), W.M3[5] .. ": not complete with the escorts alive")
	lu.assertTrue(isActive(player, q), W.M3[5] .. ": still active")

	for i = 2, 6 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, W.M3[5] .. " after ship " .. i)
	end

	pump(8000, W.M3[5] .. " after all six are destroyed")
	lu.assertTrue(isComplete(player, q), W.M3[5] .. ": complete after the target and all five escorts are destroyed")
	noMemberActive(player, 3)
end

---------------------------------------------------------------------------------------------
-- A-6 (b): mission 4
---------------------------------------------------------------------------------------------

TestEzkielChain4 = {}

function TestEzkielChain4:setUp() H.reset() end

function TestEzkielChain4:tearDown() AC.tearDown() end

-- A-6 (b): battle 4 sets up in space_dathomir with four X-wing allies; completing it starts patrol 4_a 5 s later
function TestEzkielChain4:test_battle_4_sets_up_in_dathomir_and_completing_it_starts_patrol_4_a_five_seconds_later()
	local player = chain(4)
	local q = begin(player, W.M4[1])
	local p = pointOf("space_dathomir", "naboo_rebel_tier3_rebel_vs_imperial")

	pump(5000, W.M4[1] .. " setup")
	lu.assertTrue(isActive(player, q), W.M4[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M4[1] .. ": one waypoint at naboo_rebel_tier3_rebel_vs_imperial")
	pump(26000, W.M4[1] .. " enemies arrive")
	lu.assertEquals(sorted(shipNames(H.spawnedShips())), sorted(W.expected()[W.M4[1]].enemyForce), W.M4[1] .. ": the seven Imperial enemies first (enemyArrivalDelay 30, allies at 60)")
	pump(30000, W.M4[1] .. " allies arrive")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 11, W.M4[1] .. ": 7 enemies + 4 allies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_xwing_tier3"), 4, W.M4[1] .. ": four X-wing allies after allyArrivalDelay 60")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dathomir", W.M4[1] .. ": " .. tostring(ship.shipName) .. " zone")
	end

	completeAndSplit(player, W.M4[1], W.M4[2], 5)
end

-- A-6 (b), FV-2: patrol 4_a; reaching point 3 completes it 9 s later and starts survival 4_b
function TestEzkielChain4:test_reaching_patrol_point_3_completes_patrol_4_a_nine_seconds_later_and_starts_survival_4_b()
	local player = chain(4)
	local q = begin(player, W.M4[2])
	local survival = quest(W.M4[3])

	flyPatrolTo(q, player, 3)
	pump(7500, W.M4[2] .. " 8 s after point 3")
	lu.assertFalse(isComplete(player, q), W.M4[2] .. ": not complete 8 s after point 3 (sideQuestDelay 9)")
	lu.assertFalse(isActive(player, survival), W.M4[3] .. ": not active 8 s after point 3")
	pump(2500, W.M4[2] .. " 10.5 s after point 3")
	lu.assertTrue(isComplete(player, q), W.M4[2] .. ": complete 10.5 s after point 3")
	lu.assertTrue(isActive(player, survival), W.M4[3] .. ": survival 4_b is active")
end

-- A-6 (b): survival 4_b is active at its point; completing it starts recovery 4_c 5 s later
function TestEzkielChain4:test_survival_4_b_is_active_at_its_point_and_completing_it_starts_recovery_4_c()
	local player = chain(4)
	local q = begin(player, W.M4[3])
	local p = pointOf("space_dathomir", "naboo_rebel_tier3_inquisition_point")

	pump(5000, W.M4[3] .. " start")
	lu.assertTrue(isActive(player, q), W.M4[3] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M4[3] .. ": one waypoint at naboo_rebel_tier3_inquisition_point")
	completeAndSplit(player, W.M4[3], W.M4[4], 5)
end

-- A-6 (b): recovery 4_c spawns the experimental fighter and three interceptor escorts after its arrival delay (Core3 waits it twice); completing it starts delivery 4_d
function TestEzkielChain4:test_recovery_4_c_spawns_the_experimental_fighter_with_three_escorts_and_completing_it_starts_delivery_4_d()
	local player = chain(4)
	local q = begin(player, W.M4[4])

	pump(10000, W.M4[4] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, W.M4[4] .. ": nothing spawned 10 s after the start (arrivalDelay 15)")
	pump(40000, W.M4[4] .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, W.M4[4] .. ": the recovery ship was spawned")
	lu.assertEquals(ship.shipName, "imp_tie_experimental_fighter_tier3", W.M4[4] .. ": the recovery ship")
	lu.assertEquals(ship.zone, "space_dathomir", W.M4[4] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "imp_tie_experimental_fighter_tier3"), 1, W.M4[4] .. ": one experimental fighter among " .. table.concat(names, ", "))
	lu.assertTrue(countOf(names, "imp_tie_interceptor_tier3") >= 3, W.M4[4] .. ": at least three interceptor escorts among " .. table.concat(names, ", "))

	local p = pointOf("space_dathomir", "naboo_rebel_tier3_recover_imperial_1")

	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, W.M4[4] .. ": one waypoint at the first pre-recovery point naboo_rebel_tier3_recover_imperial_1")
	completeAndSplit(player, W.M4[4], W.M4[5], 5)
end

-- A-6 (b): delivery 4_d picks up at its pickup point; completing it makes the chain end complete with no member active
function TestEzkielChain4:test_delivery_4_d_sets_up_at_the_pickup_point_and_completing_it_makes_the_chain_end_complete()
	local player = chain(4)

	for _, global in ipairs({ W.M4[1], W.M4[2], W.M4[3], W.M4[4] }) do
		W.setState(player, global, "complete")
	end

	local q = begin(player, W.M4[5])

	deliveryArea(W.M4[5])

	local p = pointOf("space_dathomir", "naboo_rebel_tier3_pickup")

	lu.assertEquals(lastAreaCall(), { "space_dathomir", p[1], p[2], p[3] }, W.M4[5] .. ": the pickup area (zone, x, z, y)")
	completeAndSplit(player, W.M4[5], nil)
	pump(8000, W.M4[5] .. " after completion")
	noMemberActive(player, 4)
	lu.assertTrue(isComplete(player, q), W.M4[5] .. ": the chain end is complete")
end

return nil
