-- Black Epsilon tier 3 (Haymir Rendundi): the four missions run through the fakes, split by split.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-3, AC-4; Data mapping 1; FH-5; R-1).
--
-- The oracle values are the spec's literals (black_epsilon_tier3_data.lua); the quest tables are driven through the harness's fakes, never
-- read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an event shows up as "no Lua error"
-- and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and pumps the split
-- delay (5 s; the alert fires at the delay, the next quest starts at delay * 1.05). The inspect step uses the cargo of the REAL ship template
-- file (ship_mobile/ships/reb_yavinspy_tier4.lua), not a cargo set on the fake ship: the tier 2 runtime test did that and missed a broken
-- quest. Flying the survival, the battle and the escort is covered by their type features: this file stops at "active / spawned" for them.
-- The hostility of the real AI cannot be checked here; see the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local T = require("black_epsilon_tier3_data")

T.load()

local function quest(global) return T.quest(global) end

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

-- A fresh world with every member of the mission's chain started (static areas), and an Imperial pilot in a ship in the mission's zone
local function chain(n)
	H.reset()

	local members = T.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		AC.resolveRecoveryPoints(quest(global))
	end

	return DRS.player(quest(members[1]), { pilot = "imperial" })
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

local function handler() return rawget(_G, T.HANDLER) end

---------------------------------------------------------------------------------------------
-- AC-3 (a): patrol 1 and its trigger
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Patrol1 = {}

function TestBlackEpsilonT3Patrol1:setUp() H.reset() end

function TestBlackEpsilonT3Patrol1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestBlackEpsilonT3Patrol1:test_the_patrol_starts_active_with_a_waypoint_at_point_1()
	local player = chain(1)
	local q = begin(player, T.M1[1])
	local p1 = T.POINTS.space_yavin4.corellia_imperial_tier3_leg_2_escort_1

	lu.assertTrue(isActive(player, q), T.M1[1] .. ": active")
	lu.assertNotNil(waypointAt(player, p1[1], p1[2], p1[3]), T.M1[1] .. ": a waypoint at corellia_imperial_tier3_leg_2_escort_1")
end

-- AC-3 (a): 20 s after reaching point 3 the patrol is complete; about 1 s later inspect 1_a is active with its waypoint
function TestBlackEpsilonT3Patrol1:test_reaching_point_3_and_waiting_20_seconds_completes_the_patrol_and_starts_the_inspect_a_second_later()
	local player = chain(1)
	local q = begin(player, T.M1[1])
	local inspect = quest(T.M1[2])

	for point = 1, 2 do
		H.enterArea(AC.areaByNumber(q, point), player.rootParent)
		pump(500, T.M1[1] .. " point " .. point)
	end

	pump(30000, T.M1[1] .. " waiting at point 2")
	lu.assertFalse(isActive(player, inspect), "points 1 and 2 do not start the split")
	lu.assertFalse(isComplete(player, q), "points 1 and 2 do not complete the patrol")

	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(19000, T.M1[1] .. " 19 s after point 3")
	lu.assertFalse(isComplete(player, q), "the patrol is not complete 19 s after point 3 (sideQuestDelay 20 s)")
	lu.assertFalse(isActive(player, inspect), "inspect 1_a is not active 19 s after point 3")
	pump(1500, T.M1[1] .. " 20.5 s after point 3")
	lu.assertTrue(isComplete(player, q), "the patrol is complete 20.5 s after point 3")
	pump(1500, T.M1[1] .. " 22 s after point 3")
	lu.assertTrue(isActive(player, inspect), "inspect 1_a is active about 1 s after the patrol completed")
	pump(4000, T.M1[2] .. " setup")

	local s = T.SPAWNER

	lu.assertNotNil(waypointAt(player, s.x, s.z, s.y), T.M1[2] .. ": a waypoint at the spawner " .. s.name)
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): inspect 1_a with the real ship template cargo
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Inspect1 = {}

function TestBlackEpsilonT3Inspect1:setUp() H.reset() end

local function spyShip(cargo)
	return H.worldAgent({ shipName = "reb_yavinspy_tier4", cargo = cargo, spawner = T.SPAWNER.name, zone = "space_yavin4" })
end

-- the cargo the server's ship template gives reb_yavinspy_tier4 (read from the real template file)
local function templateCargo()
	local t = H.shipTemplate("reb_yavinspy_tier4")

	lu.assertNotNil(t, "ship_mobile/ships/reb_yavinspy_tier4.lua registers a template")
	lu.assertNotNil(t.cargoString, "reb_yavinspy_tier4.lua has no cargoString: the inspect quest can never match the ship's cargo (FH-5)")

	return t.cargoString
end

-- AC-3 (b), FH-5
function TestBlackEpsilonT3Inspect1:test_inspecting_and_docking_with_the_spy_ship_carrying_its_templates_cargo_completes_the_quest_and_starts_the_delivery_5_seconds_later()
	local player = chain(1)
	local q = begin(player, T.M1[2])
	local delivery = quest(T.M1[3])

	pump(2500, T.M1[2] .. " setup")

	local cargo = templateCargo()
	local target = spyShip(cargo)
	local hash = getHashCode(cargo)

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")
	H.inspect(player, target, hash)
	pump(0, T.M1[2] .. " inspect")
	H.dock(player, target, hash)
	pump(0, T.M1[2] .. " dock")
	pump(1000, T.M1[2] .. " after the dock")
	lu.assertTrue(isComplete(player, q), T.M1[2] .. ": complete after docking with the spy ship")
	pump(3000, T.M1[2] .. " split delay")
	lu.assertFalse(isActive(player, delivery), "delivery 1_b is not active 4 s after the dock")
	pump(3000, T.M1[2] .. " split start")
	lu.assertTrue(isActive(player, delivery), "delivery 1_b is active 7 s after the dock")
end

-- AC-3 (b): a ship with another cargo does not complete it
function TestBlackEpsilonT3Inspect1:test_a_ship_with_another_cargo_does_not_complete_the_quest()
	local player = chain(1)
	local q = begin(player, T.M1[2])

	pump(2500, T.M1[2] .. " setup")

	local target = spyShip("stolen_data")
	local hash = getHashCode("stolen_data")

	H.inspect(player, target, hash)
	pump(0, T.M1[2] .. " inspect")
	H.dock(player, target, hash)
	pump(3000, T.M1[2] .. " dock")
	lu.assertFalse(isComplete(player, q), T.M1[2] .. ": not complete with the wrong cargo")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): delivery 1_b and recovery 1_c
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Chain1 = {}

function TestBlackEpsilonT3Chain1:setUp() H.reset() end

function TestBlackEpsilonT3Chain1:tearDown() AC.tearDown() end

-- AC-3 (c)
function TestBlackEpsilonT3Chain1:test_delivery_1_b_starts_without_an_error_and_its_completion_starts_recovery_1_c_after_5_seconds()
	local player = chain(1)
	local q = begin(player, T.M1[3])

	lu.assertTrue(isActive(player, q), T.M1[3] .. ": active")
	pump(10000, T.M1[3] .. " setup")
	lu.assertTrue(isActive(player, q), T.M1[3] .. ": still active")
	completeAndSplit(player, T.M1[3], T.M1[4])
end

-- AC-3 (c)
function TestBlackEpsilonT3Chain1:test_completing_recovery_1_c_leaves_no_mission_1_member_active_and_the_mission_won()
	local player = chain(1)

	for _, global in ipairs({ T.M1[1], T.M1[2], T.M1[3] }) do
		T.setState(player, global, "complete")
	end

	local q = begin(player, T.M1[4])

	lu.assertTrue(isActive(player, q), T.M1[4] .. ": active")
	pump(60000, T.M1[4] .. " arrival")
	completeAndSplit(player, T.M1[4], nil)
	pump(8000, T.M1[4] .. " after completion")

	for _, global in ipairs(T.M1) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 1 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
end

-- AC-3 (c): the recovery run spawns the Y-wing leader and its four escorts
function TestBlackEpsilonT3Chain1:test_recovery_1_c_spawns_the_ywing_leader_with_four_escorts()
	local player = chain(1)
	local q = quest(T.M1[4])
	local run = DRS.startRecoveryRun(q, player)

	pump(10000, T.M1[4] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "reb_ywingleader_tier4", T.M1[4] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_yavin4", T.M1[4] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "reb_xwing_tier3") + countOf(names, "reb_ywing_tier3"), 4, T.M1[4] .. ": escorts among " .. table.concat(names, ", "))
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): mission 2
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Chain2 = {}

function TestBlackEpsilonT3Chain2:setUp() H.reset() end

function TestBlackEpsilonT3Chain2:tearDown() AC.tearDown() end

-- AC-3 (d)
function TestBlackEpsilonT3Chain2:test_recovery_2_spawns_the_hutt_smuggler_with_four_skiffs_after_its_arrival_delay()
	local player = chain(2)
	local q = quest(T.M2[1])

	q:startQuest(player, "")
	pump(0, T.M2[1] .. " start")
	pump(14000, T.M2[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, T.M2[1] .. ": nothing spawned 14 s after the start (arrivalDelay 15)")

	H.reset()

	local player2 = chain(2)
	local run = DRS.startRecoveryRun(quest(T.M2[1]), player2)

	pump(10000, T.M2[1] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "huttsmuggler_tier3", T.M2[1] .. ": the recovery ship")
	lu.assertEquals(countOf(names, "huttskiff_tier3"), 4, T.M2[1] .. ": huttskiff_tier3 escorts among " .. table.concat(names, ", "))
end

-- AC-3 (d): the whole chain, each step through its own completion
function TestBlackEpsilonT3Chain2:test_recovery_survival_escort_and_battle_follow_each_other_and_the_mission_is_won()
	local player = chain(2)

	begin(player, T.M2[1])
	pump(60000, T.M2[1] .. " arrival")
	completeAndSplit(player, T.M2[1], T.M2[2])
	pump(60000, T.M2[2] .. " running")
	completeAndSplit(player, T.M2[2], T.M2[3])
	pump(2500, T.M2[3] .. " setup")

	-- the pilot reaches the rendezvous point and the escorted ship arrives (5-11 s)
	local eq = quest(T.M2[3])
	local start = readData(player.objectID .. eq.className .. ":startPoint:")

	lu.assertNotNil(start, T.M2[3] .. ": setup chose a start point")
	H.enterArea(AC.areaByNumber(eq, start), player.rootParent)
	pump(12000, T.M2[3] .. " escort ship arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "imp_huttsmuggler_tier3") >= 1, T.M2[3] .. ": the escorted imp_huttsmuggler_tier3 spawned; ships: " .. table.concat(names, ", "))
	completeAndSplit(player, T.M2[3], T.M2[4])
	pump(10000, T.M2[4] .. " running")
	completeAndSplit(player, T.M2[4], nil)
	pump(8000, T.M2[4] .. " after completion")

	for _, global in ipairs(T.M2) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 2 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

-- AC-3 (d): the survival waits at the Yavin 4 point
function TestBlackEpsilonT3Chain2:test_survival_2_a_gives_a_waypoint_at_its_yavin_4_transmission_point()
	local player = chain(2)

	begin(player, T.M2[2])
	pump(5000, T.M2[2] .. " start")

	local p = T.POINTS.space_yavin4.corellia_imperial_tier3_survival1

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), T.M2[2] .. ": a waypoint at corellia_imperial_tier3_survival1")
end

-- AC-3 (d): the battle starts with the Hutt allies and the Nym force
function TestBlackEpsilonT3Chain2:test_battle_2_c_spawns_hutt_allies_and_the_nym_force()
	local player = chain(2)

	begin(player, T.M2[4])
	pump(100000, T.M2[4] .. " arrivals")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "hutt_fighter_s02_tier4"), 4, "allies among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "nym_enforcer_tier4"), 7, "enemy enforcers among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "nym_enforcer_captain_tier4"), 1, "enemy captain among " .. table.concat(names, ", "))
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 3
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Chain3 = {}

function TestBlackEpsilonT3Chain3:setUp() H.reset() end

function TestBlackEpsilonT3Chain3:tearDown() AC.tearDown() end

-- AC-4 (a), R-1: a rescue as a story head, started by startSpaceQuestChain
function TestBlackEpsilonT3Chain3:test_the_rescue_head_starts_through_start_space_quest_chain_and_spawns_the_freighter_after_15_seconds()
	local player = chain(3)

	lu.assertTrue(SpaceHelpers:startSpaceQuestChain(player, nil, T.M3[1]), "startSpaceQuestChain returns true: the head is active")
	pump(0, T.M3[1] .. " start")
	lu.assertEquals(#H.spawnedShips(), 0, "no ship at once")
	pump(20000, T.M3[1] .. " arrival")
	lu.assertTrue(countOf(shipNames(H.spawnedShips()), "imp_freightermedium_tier3") >= 1, T.M3[1] .. ": imp_freightermedium_tier3 spawned; ships: " .. table.concat(shipNames(H.spawnedShips()), ", "))
end

-- AC-4 (a)
function TestBlackEpsilonT3Chain3:test_completing_the_rescue_starts_the_assassination_which_spawns_the_emissary_and_seven_escorts()
	local player = chain(3)

	begin(player, T.M3[1])
	pump(20000, T.M3[1] .. " arrival")
	completeAndSplit(player, T.M3[1], T.M3[2])
	pump(40000, T.M3[2] .. " deployTargets")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "reb_emissary_tier4"), 1, "emissary among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "reb_xwing_tier3"), 3, "x-wing escorts")
	lu.assertEquals(countOf(names, "reb_bwing_tier3"), 1, "b-wing escort")
	lu.assertEquals(countOf(names, "reb_awing_tier3"), 3, "a-wing escorts")
end

-- AC-4 (a): mustDestroyEscort = true
function TestBlackEpsilonT3Chain3:test_the_target_alone_does_not_complete_assassinate_3_a_but_target_and_escorts_do_and_the_mission_is_won()
	local player = chain(3)
	local q = quest(T.M3[2])

	begin(player, T.M3[2])
	pump(40000, T.M3[2] .. " deployTargets")

	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	lu.assertEquals(#ships, 8, "precondition: the emissary and seven escorts")

	local target
	local rest = {}

	for _, s in ipairs(ships) do
		if s.shipName == "reb_emissary_tier4" then
			target = s
		else
			rest[#rest + 1] = s
		end
	end

	H.destroyShip(target, player.rootParent)
	pump(5000, T.M3[2] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive")

	for _, s in ipairs(rest) do
		H.destroyShip(s, player.rootParent)
		pump(1500, T.M3[2] .. " after a kill")
	end

	pump(5000, T.M3[2] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), "complete after the target and all escorts")
	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 4 in Lok
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Chain4 = {}

function TestBlackEpsilonT3Chain4:setUp() H.reset() end

function TestBlackEpsilonT3Chain4:tearDown() AC.tearDown() end

-- AC-4 (b)
function TestBlackEpsilonT3Chain4:test_recovery_4_spawns_the_nym_transport_with_seven_fighters_in_lok()
	local player = chain(4)
	local run = DRS.startRecoveryRun(quest(T.M4[1]), player)

	pump(10000, T.M4[1] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "nym_smuggle_transport_capture_tier4", T.M4[1] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_lok", T.M4[1] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "nym_fighter_tier3"), 7, T.M4[1] .. ": nym_fighter_tier3 escorts among " .. table.concat(names, ", "))
end

-- AC-4 (b): mustDestroyEscort = false: the target kill alone completes 4_a
function TestBlackEpsilonT3Chain4:test_assassinate_4_a_completes_on_the_target_kill_alone_and_survival_4_b_follows_at_the_lok_point()
	local player = chain(4)
	local q = quest(T.M4[2])

	begin(player, T.M4[2])
	pump(40000, T.M4[2] .. " deployTargets")

	local target

	for _, s in ipairs(H.spawnedShips()) do
		if s.shipName == "nym_patrol_craft_tier4" then
			target = s
		end
	end

	lu.assertNotNil(target, "the nym_patrol_craft_tier4 spawned among " .. table.concat(shipNames(H.spawnedShips()), ", "))
	H.destroyShip(target, player.rootParent)
	pump(1500, T.M4[2] .. " after the target")
	lu.assertTrue(isComplete(player, q), "complete on the target kill alone")
	pump(3000, T.M4[2] .. " split delay")
	lu.assertFalse(isActive(player, quest(T.M4[3])), "survival 4_b is not active 4.5 s after the kill")
	pump(4000, T.M4[2] .. " split start")
	lu.assertTrue(isActive(player, quest(T.M4[3])), "survival 4_b is active 7.5 s after the kill")
	pump(5000, T.M4[3] .. " start")

	local p = T.POINTS.space_lok.corellia_imperial_tier3_survival1

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), T.M4[3] .. ": a waypoint at the Lok corellia_imperial_tier3_survival1")
end

-- AC-4 (b): the whole chain, then the Karthakk queen
function TestBlackEpsilonT3Chain4:test_the_chain_runs_to_assassinate_4_c_and_killing_the_queen_and_her_escorts_wins_the_mission()
	local player = chain(4)

	begin(player, T.M4[1])
	pump(60000, T.M4[1] .. " arrival")
	completeAndSplit(player, T.M4[1], T.M4[2])
	completeAndSplit(player, T.M4[2], T.M4[3])
	pump(60000, T.M4[3] .. " running")
	completeAndSplit(player, T.M4[3], T.M4[4])
	pump(40000, T.M4[4] .. " deployTargets")

	local ships, names = {}, {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
		names[i] = s.shipName
	end

	lu.assertEquals(countOf(names, "nym_karthakk_queen_tier4"), 1, "the queen among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "nym_fighter_tier3") >= 3 and countOf(names, "nym_enforcer_tier3") >= 2, true, "her escorts among " .. table.concat(names, ", "))

	for _, s in ipairs(ships) do
		if s.shipName == "nym_karthakk_queen_tier4" or s.shipName == "nym_enforcer_tier3" or s.shipName == "nym_fighter_tier3" then
			H.destroyShip(s, player.rootParent)
			pump(1500, T.M4[4] .. " after a kill")
		end
	end

	pump(5000, T.M4[4] .. " after the last kill")
	lu.assertTrue(isComplete(player, quest(T.M4[4])), T.M4[4] .. ": complete")

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end
