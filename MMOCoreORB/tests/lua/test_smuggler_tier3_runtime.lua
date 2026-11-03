-- Smuggler tier 3 (Beissa): the four missions run through the fakes, split by split.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-3, AC-4; Data mapping 1; FB-6, FB-7, FB-8; R-1).
--
-- The oracle values are the SWG fixtures (smuggler_tier3_data.lua B.expected, proven equal to the tables by test_smuggler_tier3_data.lua) and the spec's
-- numbers; the quest tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a
-- Lua error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own
-- completeQuest and pumps the split delay (5 s; the alert fires at the delay, the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL
-- ship template files (ship_mobile/ships/dath_witchblood_clan_*_tier3.lua), not a cargo set on the fake ship: the tier 2 runtime tests did that and missed a
-- broken quest. Flying the survival, the battle and the escort is covered by their type features: this file stops at "active / spawned" for them.
-- The pilot is a Smuggler at pilot tier 3 whose launched ship carries the Hutt faction (C++ resetShipFaction, FB-7). The hostility of the real AI cannot be
-- checked here; see the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local B = require("smuggler_tier3_data")

B.load()

local G = B.GLOBALS

local function quest(global) return B.quest(global) end

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

local function waypointAt(player, x, z, y)
	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == x and w.z == z and w.y == y then
			return w
		end
	end
end

local function handler() return rawget(_G, B.HANDLER) end

-- A Smuggler graduate at pilot tier 3 in a Hutt-faction ship in the mission's zone
local function newPlayer(q)
	return B.pilot({ zone = q.questZone, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y, factionHash = getHashCode("hutt") } })
end

-- A fresh world with every member of the mission's chain started (static areas) and the pilot in a ship in the mission's zone
local function chain(n)
	H.reset()

	local members = B.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return newPlayer(quest(members[1]))
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Completes a member and pumps the split delay: the next member is not active at 4 s and is active at 7 s
local function completeAndSplit(player, global, nextGlobal)
	local q = quest(global)

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")

	if nextGlobal then
		local nq = quest(nextGlobal)

		pump(4000, global .. " split delay")
		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active 4 s after " .. global .. " completed (sideQuestDelay 5 s)")
		pump(3000, global .. " split start")
		lu.assertTrue(isActive(player, nq), nextGlobal .. ": active 7 s after " .. global .. " completed")
	end
end

-- A delivery leg: the setup (2 s), the pilot's ship enters the delivery area, the transport warps in (6 s)
local function deliveryArrive(player, label)
	pump(2000, label .. " setup")

	local areas = H.spawnedAreas()

	lu.assertTrue(#areas >= 1, label .. ": the delivery area was spawned")
	H.enterArea(areas[#areas], player.rootParent)
	pump(7000, label .. " warp-in")
end

local function noMemberActive(player, n)
	for _, global in ipairs(B.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

local function spawnedCopy()
	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): mission 1 (Yavin 4)
---------------------------------------------------------------------------------------------

TestSmugglerT3Chain1 = {}

function TestSmugglerT3Chain1:setUp() H.reset() end

function TestSmugglerT3Chain1:tearDown() AC.tearDown() end

-- AC-3 (a): the recovery run spawns the freighter with its three Valarian escorts
function TestSmugglerT3Chain1:test_recovery_1_spawns_the_heavy_freighter_with_three_valarian_escorts()
	local player = chain(1)
	local run = DRS.startRecoveryRun(quest(G[1]), player)

	pump(10000, G[1] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "smuggler_freighterheavy_tier3", G[1] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_yavin4", G[1] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "valarian_gunship_tier3"), 2, G[1] .. ": gunship escorts among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "valarian_bomber_tier3"), 1, G[1] .. ": bomber escorts among " .. table.concat(names, ", "))
end

-- AC-3 (a): completing the recovery starts assassinate 1_a 5 s later
function TestSmugglerT3Chain1:test_completing_recovery_1_starts_assassinate_1_a_five_seconds_later()
	local player = chain(1)

	begin(player, G[1])
	pump(60000, G[1] .. " arrival")
	completeAndSplit(player, G[1], G[2])
end

-- AC-3 (a): assassinate 1_a spawns the Valarian replacement with two bomber escorts; with mustDestroyEscort the target alone does not complete it
function TestSmugglerT3Chain1:test_assassinate_1_a_needs_the_target_and_both_escorts()
	local player = chain(1)
	local q = quest(G[2])

	begin(player, G[2])
	pump(40000, G[2] .. " deployTargets")

	local ships = spawnedCopy()
	local names = shipNames(ships)

	lu.assertEquals(countOf(names, "valarian_replacement_1_tier3"), 1, "the target among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "valarian_bomber_tier3"), 2, "the bomber escorts among " .. table.concat(names, ", "))

	local rest = {}

	for _, s in ipairs(ships) do
		if s.shipName == "valarian_replacement_1_tier3" then
			H.destroyShip(s, player.rootParent)
		else
			rest[#rest + 1] = s
		end
	end

	pump(5000, G[2] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive")

	for _, s in ipairs(rest) do
		H.destroyShip(s, player.rootParent)
		pump(1500, G[2] .. " after a kill")
	end

	pump(5000, G[2] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), "complete after the target and both escorts")
end

-- AC-3 (a): 1_a, 1_b, 1_c in turn start the next
function TestSmugglerT3Chain1:test_assassinates_1_a_1_b_1_c_start_the_next_member_five_seconds_after_their_completion()
	local player = chain(1)

	begin(player, G[2])
	pump(5000, G[2] .. " running")
	completeAndSplit(player, G[2], G[3])
	pump(5000, G[3] .. " running")
	completeAndSplit(player, G[3], G[4])
	pump(5000, G[4] .. " running")
	completeAndSplit(player, G[4], G[5])
end

-- AC-3 (a): mustDestroyEscort = false: killing only valarian_fighter_replacement completes 1_c
function TestSmugglerT3Chain1:test_assassinate_1_c_completes_when_only_the_fighter_replacement_is_destroyed()
	local player = chain(1)
	local q = quest(G[4])

	begin(player, G[4])
	pump(40000, G[4] .. " deployTargets")

	local target
	local names = shipNames(H.spawnedShips())

	for _, s in ipairs(H.spawnedShips()) do
		if s.shipName == "valarian_fighter_replacement" then
			target = s
		end
	end

	lu.assertNotNil(target, "valarian_fighter_replacement spawned among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "valarian_bomber_tier3"), 2, "two bomber escorts among " .. table.concat(names, ", "))
	H.destroyShip(target, player.rootParent)
	pump(1500, G[4] .. " after the target")
	lu.assertTrue(isComplete(player, q), "complete on the target kill alone")
end

-- AC-3 (a): the surprise attack spawns one valarian_replacement_3_tier3; destroying it ends the mission
function TestSmugglerT3Chain1:test_the_surprise_attack_1_d_spawns_one_replacement_and_destroying_it_wins_mission_1()
	local player = chain(1)

	for _, global in ipairs({ G[1], G[2], G[3], G[4] }) do
		B.setState(player, global, "complete")
	end

	local q = begin(player, G[5])

	lu.assertTrue(isActive(player, q), G[5] .. ": active")
	pump(30000, G[5] .. " spawn")

	local ships = spawnedCopy()
	local names = shipNames(ships)

	lu.assertEquals(names, { "valarian_replacement_3_tier3" }, G[5] .. ": the spawned ships")
	lu.assertEquals(ships[1].zone, "space_yavin4", G[5] .. ": zone")
	H.destroyShip(ships[1], player.rootParent)
	pump(5000, G[5] .. " after the kill")
	lu.assertTrue(isComplete(player, q), G[5] .. ": complete")
	noMemberActive(player, 1)
	B.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): mission 2 (Dathomir): the two inspects with the real ship template cargo, the survival
---------------------------------------------------------------------------------------------

TestSmugglerT3Chain2 = {}

function TestSmugglerT3Chain2:setUp() H.reset() end

function TestSmugglerT3Chain2:tearDown() AC.tearDown() end

-- the cargo the server's ship template gives the Witchblood ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FB-6)")

	return t.cargoString
end

local function witchblood(shipName, cargo, spawner)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = "space_dathomir" })
end

local function inspectAndDock(player, q, target, cargo)
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, q.className .. " inspect")
	H.dock(player, target, hash)
	pump(0, q.className .. " dock")
	pump(1000, q.className .. " after the dock")
end

-- AC-3 (b), FB-8: inspect 2 gives a "Possible Target Location" waypoint at each of the two spawner positions
function TestSmugglerT3Chain2:test_inspect_2_gives_two_target_location_waypoints_at_the_two_spawner_positions()
	local player = chain(2)
	local q = begin(player, G[6])

	H.zoneSwitch(player, "space_dathomir")
	pump(5000, G[6] .. " setup")
	lu.assertTrue(isActive(player, q), G[6] .. ": active")

	local d = B.buildout("dathomir")

	for _, i in ipairs({ 1, 3 }) do
		local sp = d.spawners[i]
		local w = waypointAt(player, sp[1], sp[2], sp[3])

		lu.assertNotNil(w, G[6] .. ": a waypoint at the " .. sp.name .. " position " .. sp[1] .. ", " .. sp[2] .. ", " .. sp[3])
	end

	lu.assertEquals(#player.ghost.waypoints, 2, G[6] .. ": waypoints")
end

-- AC-3 (b), FB-6, FB-8: inspecting and docking with a soldier carrying the template's cargo completes inspect 2; 5 s later inspect 2_a is active
function TestSmugglerT3Chain2:test_inspect_2_completes_with_the_soldier_templates_cargo_and_starts_inspect_2_a_five_seconds_later()
	local player = chain(2)
	local q = begin(player, G[6])
	local nextQ = quest(G[7])

	H.zoneSwitch(player, "space_dathomir")
	pump(2500, G[6] .. " setup")

	local cargo = templateCargo("dath_witchblood_clan_soldier_tier3")

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")

	for _, sp in ipairs(B.buildout("dathomir").spawners) do
		if sp.name == "tier3_privateer_witchblood_inspect_01" then
			-- both spawners carry the same name; either one gives a valid target
			H.reset()
			player = chain(2)
			q = begin(player, G[6])
			nextQ = quest(G[7])
			H.zoneSwitch(player, "space_dathomir")
			pump(2500, G[6] .. " setup")
			inspectAndDock(player, q, witchblood("dath_witchblood_clan_soldier_tier3", cargo, sp.name), cargo)
			lu.assertTrue(isComplete(player, q), G[6] .. ": complete after docking with the soldier")
			pump(3000, G[6] .. " split delay")
			lu.assertFalse(isActive(player, nextQ), G[7] .. ": not active 4 s after the dock")
			pump(3000, G[6] .. " split start")
			lu.assertTrue(isActive(player, nextQ), G[7] .. ": active 7 s after the dock")
		end
	end
end

-- AC-3 (b): a ship with another cargo does not complete it
function TestSmugglerT3Chain2:test_a_ship_with_another_cargo_does_not_complete_inspect_2()
	local player = chain(2)
	local q = begin(player, G[6])

	H.zoneSwitch(player, "space_dathomir")
	pump(2500, G[6] .. " setup")
	inspectAndDock(player, q, witchblood("dath_witchblood_clan_soldier_tier3", "kill_orders", "tier3_privateer_witchblood_inspect_01"), "kill_orders")
	pump(3000, G[6] .. " dock")
	lu.assertFalse(isComplete(player, q), G[6] .. ": not complete with the wrong cargo (kill_orders is another row of witchblood_rallyinfo)")
end

-- AC-3 (b), FB-6: inspect 2_a with the punisher template's cargo, then survival 2_b at tier3_privateer_battle_01
function TestSmugglerT3Chain2:test_inspect_2_a_completes_with_the_punisher_templates_cargo_and_survival_2_b_follows_at_the_battle_point()
	local player = chain(2)

	B.setState(player, G[6], "complete")

	local q = begin(player, G[7])

	H.zoneSwitch(player, "space_dathomir")
	pump(2500, G[7] .. " setup")

	local cargo = templateCargo("dath_witchblood_clan_punisher_tier3")

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")
	inspectAndDock(player, q, witchblood("dath_witchblood_clan_punisher_tier3", cargo, "tier3_privateer_witchblood_inspect_02"), cargo)
	lu.assertTrue(isComplete(player, q), G[7] .. ": complete after docking with the punisher")
	pump(3000, G[7] .. " split delay")
	lu.assertFalse(isActive(player, quest(G[8])), G[8] .. ": not active 4 s after the dock")
	pump(3000, G[7] .. " split start")
	lu.assertTrue(isActive(player, quest(G[8])), G[8] .. ": active 7 s after the dock")
	pump(5000, G[8] .. " start")

	local p = B.buildout("dathomir").nav.tier3_privateer_battle_01

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), G[8] .. ": a waypoint at tier3_privateer_battle_01")
end

-- AC-3 (b): the inspect 2_a waypoint is the _02 spawner position
function TestSmugglerT3Chain2:test_inspect_2_a_gives_a_waypoint_at_the_second_spawner()
	local player = chain(2)

	begin(player, G[7])
	H.zoneSwitch(player, "space_dathomir")
	pump(5000, G[7] .. " setup")

	local sp = B.buildout("dathomir").spawners[2]

	lu.assertEquals(sp.name, "tier3_privateer_witchblood_inspect_02", "precondition: the second excerpt spawner")
	lu.assertNotNil(waypointAt(player, sp[1], sp[2], sp[3]), G[7] .. ": a waypoint at " .. sp.name)
	lu.assertEquals(#player.ghost.waypoints, 1, G[7] .. ": waypoints")
end

-- AC-3 (b): completing survival 2_b makes mission 2 won
function TestSmugglerT3Chain2:test_completing_survival_2_b_wins_mission_2()
	local player = chain(2)

	B.setState(player, G[6], "complete")
	B.setState(player, G[7], "complete")
	begin(player, G[8])
	pump(5000, G[8] .. " start")
	completeAndSplit(player, G[8], nil)
	pump(8000, G[8] .. " after completion")
	noMemberActive(player, 2)
	B.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 3 (Dathomir): three deliveries, then the escort
---------------------------------------------------------------------------------------------

TestSmugglerT3Chain3 = {}

function TestSmugglerT3Chain3:setUp() H.reset() end

function TestSmugglerT3Chain3:tearDown() AC.tearDown() end

-- AC-4 (a), R-1: a delivery_no_pickup as a story head, started by startSpaceQuestChain
function TestSmugglerT3Chain3:test_the_delivery_head_starts_through_start_space_quest_chain_and_spawns_the_vip_shuttle()
	local player = chain(3)

	lu.assertTrue(SpaceHelpers:startSpaceQuestChain(player, nil, G[9]), "startSpaceQuestChain returns true: the head is active")
	pump(0, G[9] .. " start")
	deliveryArrive(player, G[9])
	lu.assertTrue(isActive(player, quest(G[9])), G[9] .. ": active")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "imp_vip_shuttle_tier3") >= 1, G[9] .. ": imp_vip_shuttle_tier3 spawned; ships: " .. table.concat(names, ", "))
end

-- AC-4 (a): 3, 3_a, 3_b in turn start the next 5 s later; 3_b's completion starts the escort 3_c
function TestSmugglerT3Chain3:test_the_deliveries_chain_into_the_escort_and_the_escort_wins_mission_3()
	local player = chain(3)

	begin(player, G[9])
	pump(3000, G[9] .. " setup")
	completeAndSplit(player, G[9], G[10])
	pump(3000, G[10] .. " setup")
	completeAndSplit(player, G[10], G[11])
	deliveryArrive(player, G[11])

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "lambdashuttle_inquisition_data_vessel") >= 1, G[11] .. ": the data vessel spawned; ships: " .. table.concat(names, ", "))
	completeAndSplit(player, G[11], G[12])
	pump(2500, G[12] .. " setup")

	local eq = quest(G[12])
	local start = readData(player.objectID .. eq.className .. ":startPoint:")

	lu.assertNotNil(start, G[12] .. ": setup chose a start point")
	lu.assertEquals(eq.attackDelay, 90, G[12] .. ": attackDelay")
	H.enterArea(AC.areaByNumber(eq, start), player.rootParent)
	pump(12000, G[12] .. " escort ship arrival")
	names = shipNames(H.spawnedShips())
	lu.assertTrue(countOf(names, "imp_vip_shuttle_tier3") >= 1, G[12] .. ": the escorted imp_vip_shuttle_tier3 spawned; ships: " .. table.concat(names, ", "))
	completeAndSplit(player, G[12], nil)
	pump(8000, G[12] .. " after completion")
	noMemberActive(player, 3)
	B.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 4 (Dathomir): patrol, two battles, patrol, rescue
---------------------------------------------------------------------------------------------

TestSmugglerT3Chain4 = {}

function TestSmugglerT3Chain4:setUp() H.reset() end

function TestSmugglerT3Chain4:tearDown() AC.tearDown() end

-- AC-4 (b): patrol 4 gives point 1
function TestSmugglerT3Chain4:test_patrol_4_starts_active_with_a_waypoint_at_point_1()
	local player = chain(4)
	local q = begin(player, G[13])
	local p1 = B.buildout("dathomir").nav.tier3_privateer_patrol_01

	lu.assertTrue(isActive(player, q), G[13] .. ": active")
	lu.assertNotNil(waypointAt(player, p1[1], p1[2], p1[3]), G[13] .. ": a waypoint at tier3_privateer_patrol_01")
end

-- AC-4 (b): 8 s after reaching point 2 the patrol is complete and space battle 4_a is active (no point 3 needed)
function TestSmugglerT3Chain4:test_reaching_point_2_and_waiting_8_seconds_completes_patrol_4_and_starts_battle_4_a()
	local player = chain(4)
	local q = begin(player, G[13])
	local battle = quest(G[14])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, G[13] .. " point 1")
	pump(30000, G[13] .. " waiting at point 1")
	lu.assertFalse(isComplete(player, q), "point 1 alone does not complete the patrol")
	lu.assertFalse(isActive(player, battle), "point 1 alone does not start the battle")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(6000, G[13] .. " 6 s after point 2")
	lu.assertFalse(isComplete(player, q), "the patrol is not complete 6 s after point 2 (sideQuestDelay 8 s)")
	lu.assertFalse(isActive(player, battle), "battle 4_a is not active 6 s after point 2")
	pump(4000, G[13] .. " 10 s after point 2")
	lu.assertTrue(isComplete(player, q), "the patrol is complete 10 s after point 2")
	pump(3000, G[13] .. " 13 s after point 2")
	lu.assertTrue(isActive(player, battle), "battle 4_a is active after the split delay")
end

-- AC-4 (b): the battle spawns the Hutt allies and the Rancor Clan force
function TestSmugglerT3Chain4:test_battle_4_a_spawns_hutt_allies_and_the_rancor_clan_force()
	local player = chain(4)

	begin(player, G[14])
	pump(100000, G[14] .. " arrivals")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "hutt_bomber_s02_tier3"), 2, "ally bombers among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "hutt_fighter_s02_tier3"), 2, "ally fighters among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "rancor_clan_ace_tier3"), 2, "enemy aces among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "rancor_clan_elite_tier3"), 2, "enemy elites among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "rancor_clan_gunship_tier3"), 2, "enemy gunships among " .. table.concat(names, ", "))
end

-- AC-4 (b): completing 4_a starts 4_b, completing 4_b starts patrol 4_c
function TestSmugglerT3Chain4:test_the_battles_chain_into_the_second_patrol()
	local player = chain(4)

	begin(player, G[14])
	pump(5000, G[14] .. " running")
	completeAndSplit(player, G[14], G[15])
	pump(100000, G[15] .. " arrivals")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "rancor_clan_gunship_tier4"), 3, "4_b enemy gunships among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "hutt_yt1300_tier3"), 1, "4_b ally freighter among " .. table.concat(names, ", "))
	completeAndSplit(player, G[15], G[16])
end

-- AC-4 (b): 7 s after patrol 4_c's point 2 rescue 4_d is active and spawns the VIP transport after 8 s
function TestSmugglerT3Chain4:test_patrol_4_c_splits_into_the_rescue_which_spawns_the_vip_transport_and_winning_it_wins_mission_4()
	local player = chain(4)
	local q = begin(player, G[16])
	local rescue = quest(G[17])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, G[16] .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(5000, G[16] .. " 5 s after point 2")
	lu.assertFalse(isComplete(player, q), "the patrol is not complete 5 s after point 2 (sideQuestDelay 7 s)")
	pump(3000, G[16] .. " 8 s after point 2")
	lu.assertTrue(isComplete(player, q), "the patrol is complete 8 s after point 2")
	pump(3000, G[16] .. " 11 s after point 2")
	lu.assertTrue(isActive(player, rescue), G[17] .. ": active after the split delay")
	pump(20000, G[17] .. " arrival")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "hutt_vip_transport_tier3") >= 1, G[17] .. ": hutt_vip_transport_tier3 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
	completeAndSplit(player, G[17], nil)
	pump(8000, G[17] .. " after completion")
	noMemberActive(player, 4)
	B.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end

-- AC-4 (b): a rescue as the child of a patrol also starts without the patrol (the member's own start)
function TestSmugglerT3Chain4:test_rescue_4_d_spawns_the_vip_transport_after_8_seconds()
	local player = chain(4)

	begin(player, G[17])
	pump(6000, G[17] .. " before the arrival delay")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "hutt_vip_transport_tier3"), 0, "nothing spawned 6 s after the start (targetArrivalDelay 8)")
	pump(15000, G[17] .. " after the arrival delay")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "hutt_vip_transport_tier3") >= 1, "hutt_vip_transport_tier3 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
end
