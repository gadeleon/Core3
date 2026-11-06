-- Inquisition tier 4 (Ja'ce Yiaso): the four missions run through the fakes, split by split.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-3, AC-4; Data mapping 1; FJ-6, FJ-8; R-2, R-3).
--
-- The oracle values are the spec's literals (inquisition_tier4_data.lua) and the SWG fixtures; the quest tables are driven through the harness's
-- fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an event shows up as "no Lua
-- error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and pumps the
-- split delay (the alert fires at the delay, the next quest starts at delay * 1.05); the first surprise attack is also completed the real way,
-- by destroying its six pulsars. The inspect step uses the cargo of the REAL ship template file (ship_mobile/ships/crystal_smuggler_yt1300_tier4.lua),
-- not a cargo set on the fake ship (FJ-6). Flying the survival, the battle and the escort is covered by their type features: this file stops at
-- "active / spawned" for them. The hostility of the real AI cannot be checked here; see the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local J4 = require("inquisition_tier4_data")

J4.load()

local function quest(global) return J4.quest(global) end

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

local function tally(list)
	local out = {}

	for _, name in ipairs(list) do
		out[name] = (out[name] or 0) + 1
	end

	return out
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

local function handler() return rawget(_G, J4.HANDLER) end

-- A fresh world with every member of the mission's chain started (static areas), and an Imperial pilot in a ship in the mission's zone
local function chain(n)
	H.reset()

	local members = J4.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		local q = quest(global)

		if q.preRecoveryPoints ~= nil then
			AC.resolveRecoveryPoints(q)
		end
	end

	local player = DRS.player(quest(members[1]), { pilot = "imperial" })

	H.setQuestStatus(player, J4.MISSIONS[n].status .. ":attempted", 1)

	return player
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Completes a member and pumps the split delay (seconds, default 5): the next member is not active a second before and is active 2 s after
local function completeAndSplit(player, global, nextGlobal, delay)
	local q = quest(global)

	delay = delay or 5
	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")

	if nextGlobal then
		local nq = quest(nextGlobal)

		pump((delay - 1) * 1000, global .. " split delay")
		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active " .. (delay - 1) .. " s after " .. global .. " completed (sideQuestDelay " .. delay .. " s)")
		pump(3000, global .. " split start")
		lu.assertTrue(isActive(player, nq), nextGlobal .. ": active " .. (delay + 2) .. " s after " .. global .. " completed")
	end
end

-- the cargo the server's ship template gives the inspect ship (read from the real template file)
local function templateCargo()
	local t = H.shipTemplate(J4.INSPECT_SHIP)

	lu.assertNotNil(t, "ship_mobile/ships/" .. J4.INSPECT_SHIP .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, J4.INSPECT_SHIP .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FJ-6)")

	return t.cargoString
end

-- inspect + dock with the inspect ship carrying `cargo`, then let the quest see it
local function inspectAndDock(player, cargo, label)
	local target = H.worldAgent({ shipName = J4.INSPECT_SHIP, cargo = cargo, spawner = J4.SPAWNER.name, zone = "space_dathomir" })
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, label .. " inspect")
	H.dock(player, target, hash)
	pump(0, label .. " dock")
	pump(1000, label .. " after the dock")
end

-- Starts a recovery member and lets its ship arrive (Core3 waits arrivalDelay twice: setupRecover, then spawnRecoveryShip); returns the quest and the ship
local function recoveryShip(player, global)
	local q = begin(player, global)

	pump(70000, global .. " arrival")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, global .. ": the recovery ship was spawned")

	return q, ship
end

local function noMemberActive(player, n)
	for _, global in ipairs(J4.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): patrol 1 and its trigger
---------------------------------------------------------------------------------------------

TestInquisitionT4Patrol1 = {}

function TestInquisitionT4Patrol1:setUp() H.reset() end

function TestInquisitionT4Patrol1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestInquisitionT4Patrol1:test_the_patrol_starts_active_with_a_waypoint_at_point_1_and_three_points()
	local player = chain(1)
	local q = begin(player, J4.M1[1])
	local p1 = J4.POINTS.naboo_imperial_tier4_patrol1_1

	lu.assertTrue(isActive(player, q), J4.M1[1] .. ": active")
	lu.assertEquals(#q.patrolPoints, 3, "three patrol points")
	lu.assertNotNil(waypointAt(player, p1[1], p1[2], p1[3]), J4.M1[1] .. ": a waypoint at naboo_imperial_tier4_patrol1_1")
end

-- AC-3 (a), R-2: reaching point 2 and waiting 25 s completes the patrol and starts inspect 1_a about a second later; point 3 is never flown
function TestInquisitionT4Patrol1:test_reaching_point_2_and_waiting_25_seconds_completes_the_patrol_and_starts_the_inspect_a_second_later()
	local player = chain(1)
	local q = begin(player, J4.M1[1])
	local inspect = quest(J4.M1[2])

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, J4.M1[1] .. " point 1")
	pump(30000, J4.M1[1] .. " waiting at point 1")
	lu.assertFalse(isActive(player, inspect), "point 1 does not start the split")
	lu.assertFalse(isComplete(player, q), "point 1 does not complete the patrol")

	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(24000, J4.M1[1] .. " 24 s after point 2")
	lu.assertFalse(isComplete(player, q), "the patrol is not complete 24 s after point 2 (sideQuestDelay 25 s)")
	lu.assertFalse(isActive(player, inspect), "inspect 1_a is not active 24 s after point 2")
	pump(1500, J4.M1[1] .. " 25.5 s after point 2")
	lu.assertTrue(isComplete(player, q), "the patrol is complete 25.5 s after point 2")
	pump(1500, J4.M1[1] .. " 27 s after point 2")
	lu.assertTrue(isActive(player, inspect), "inspect 1_a is active about 1 s after the patrol completed")
	pump(4000, J4.M1[2] .. " setup")
	lu.assertNotNil(waypointAt(player, J4.SPAWNER.x, J4.SPAWNER.z, J4.SPAWNER.y), J4.M1[2] .. ": a waypoint at the spawner " .. J4.SPAWNER.name)
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): inspect 1_a with the real ship template cargo, the surprise attack, the delivery
---------------------------------------------------------------------------------------------

TestInquisitionT4Chain1 = {}

function TestInquisitionT4Chain1:setUp() H.reset() end

function TestInquisitionT4Chain1:tearDown() AC.tearDown() end

-- AC-3 (b), FJ-6: one waypoint at the spawner; the template's cargo completes the inspect; the surprise attack starts 15 s later
function TestInquisitionT4Chain1:test_inspecting_the_crystal_smuggler_with_its_templates_cargo_completes_1_a_and_starts_the_surprise_attack_15_seconds_later()
	local player = chain(1)
	local q = begin(player, J4.M1[2])
	local surprise = quest(J4.M1[3])

	pump(2500, J4.M1[2] .. " setup")

	local n = 0

	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == J4.SPAWNER.x and w.z == J4.SPAWNER.z and w.y == J4.SPAWNER.y then
			n = n + 1
		end
	end

	lu.assertEquals(n, 1, "one waypoint at the spawner")

	local cargo = templateCargo()

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")
	inspectAndDock(player, cargo, J4.M1[2])
	lu.assertTrue(isComplete(player, q), J4.M1[2] .. ": complete after docking with the crystal smuggler")
	pump(9000, J4.M1[2] .. " 10 s after the dock")
	lu.assertFalse(isActive(player, surprise), "surprise 1_b is not active 10 s after the dock (the split is 15 s, not 5)")
	pump(4000, J4.M1[2] .. " 14 s after the dock")
	lu.assertFalse(isActive(player, surprise), "surprise 1_b is not active 14 s after the dock")
	pump(3500, J4.M1[2] .. " 17.5 s after the dock")
	lu.assertTrue(isActive(player, surprise), "surprise 1_b is active 17.5 s after the dock")
end

-- AC-3 (b): a ship with another cargo does not complete it
function TestInquisitionT4Chain1:test_a_ship_with_another_cargo_does_not_complete_the_inspect()
	local player = chain(1)
	local q = begin(player, J4.M1[2])

	pump(2500, J4.M1[2] .. " setup")
	inspectAndDock(player, "stolen_data", J4.M1[2])
	lu.assertFalse(isComplete(player, q), J4.M1[2] .. ": not complete with the wrong cargo")
end

-- AC-3 (b), FJ-8: the surprise attack spawns six pulsars; destroying them starts the delivery 5 s later
function TestInquisitionT4Chain1:test_the_surprise_attack_spawns_six_pulsars_and_destroying_them_starts_the_delivery_five_seconds_later()
	local player = chain(1)
	local q = begin(player, J4.M1[3])

	pump(5000, J4.M1[3] .. " spawn")

	local ships = H.spawnedShips()
	local names = shipNames(ships)

	lu.assertEquals(countOf(names, "coynite_merc_pulsar_tier4"), 6, J4.M1[3] .. ": pulsars among " .. table.concat(names, ", "))
	lu.assertEquals(#names, 6, J4.M1[3] .. ": only the six pulsars")

	for _, s in ipairs(ships) do
		H.destroyShip(s, player.rootParent)
		pump(500, J4.M1[3] .. " after a kill")
	end

	pump(1000, J4.M1[3] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), J4.M1[3] .. ": complete after the six kills")

	local dnp = quest(J4.M1[4])

	pump(2000, J4.M1[3] .. " 3.5 s after")
	lu.assertFalse(isActive(player, dnp), "delivery 1_c is not active 3.5 s after the last kill")
	pump(4000, J4.M1[3] .. " 7.5 s after")
	lu.assertTrue(isActive(player, dnp), "delivery 1_c is active 7.5 s after the last kill")
end

-- AC-3 (b): the delivery sets up at Vrke's pickup point and completing it leaves no member active and wins mission 1
function TestInquisitionT4Chain1:test_delivery_1_c_runs_and_completing_it_leaves_no_member_active_and_wins_mission_1()
	local player = chain(1)

	for _, global in ipairs({ J4.M1[1], J4.M1[2], J4.M1[3] }) do
		J4.setState(player, global, "complete")
	end

	local q = begin(player, J4.M1[4])

	lu.assertTrue(isActive(player, q), J4.M1[4] .. ": active")
	pump(3000, J4.M1[4] .. " setup")
	lu.assertTrue(#H.spawnedAreas() >= 1, "the delivery area was spawned")
	pump(10000, J4.M1[4] .. " running")
	lu.assertTrue(isActive(player, q), J4.M1[4] .. ": still active")
	completeAndSplit(player, J4.M1[4], nil)
	pump(8000, J4.M1[4] .. " after completion")
	noMemberActive(player, 1)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
	lu.assertFalse(handler():isActive(player, 1), "mission 1 is no longer running")
end

-- AC-3: the chain by completions from inspect 1_a on: the member starts follow one another with the split delays 15, 5, 5
function TestInquisitionT4Chain1:test_the_chain_runs_from_the_inspect_with_the_split_delays_15_5_5()
	local player = chain(1)

	J4.setState(player, J4.M1[1], "complete")
	begin(player, J4.M1[2])
	pump(2500, J4.M1[2] .. " setup")
	completeAndSplit(player, J4.M1[2], J4.M1[3], 15)
	pump(5000, J4.M1[3] .. " spawn")
	completeAndSplit(player, J4.M1[3], J4.M1[4], 5)
	pump(3000, J4.M1[4] .. " setup")
	completeAndSplit(player, J4.M1[4], nil)
	pump(8000, J4.M1[4] .. " after completion")
	noMemberActive(player, 1)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): mission 2
---------------------------------------------------------------------------------------------

TestInquisitionT4Chain2 = {}

function TestInquisitionT4Chain2:setUp() H.reset() end

function TestInquisitionT4Chain2:tearDown() AC.tearDown() end

-- AC-3 (c): the heavy crystal smuggler alone
function TestInquisitionT4Chain2:test_recovery_2_spawns_the_heavy_crystal_smuggler_alone_after_its_arrival_delay()
	local player = chain(2)
	local q = quest(J4.M2[1])

	q:startQuest(player, "")
	pump(0, J4.M2[1] .. " start")
	pump(14000, J4.M2[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, J4.M2[1] .. ": nothing spawned 14 s after the start (arrivalDelay 30)")

	local player2 = chain(2)
	local _, ship = recoveryShip(player2, J4.M2[1])
	local names = shipNames(H.spawnedShips())

	lu.assertEquals(ship.shipName, "crystal_smuggler_heavy_tier4", J4.M2[1] .. ": the recovery ship")
	lu.assertEquals(ship.zone, "space_dathomir", J4.M2[1] .. ": the recovery ship zone")
	lu.assertEquals(#names, 1, J4.M2[1] .. ": no escorts, only the smuggler among " .. table.concat(names, ", "))
end

-- AC-3 (c): recovery > rescue (imp_lambda_recon_tier4) > surprise attack > recovery 2_c (neutron tier 5 with 4 escorts) > won
function TestInquisitionT4Chain2:test_recovery_rescue_surprise_and_recovery_follow_each_other_and_the_mission_is_won()
	local player = chain(2)

	recoveryShip(player, J4.M2[1])
	completeAndSplit(player, J4.M2[1], J4.M2[2])
	pump(70000, J4.M2[2] .. " arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "imp_lambda_recon_tier4") >= 1, J4.M2[2] .. ": imp_lambda_recon_tier4 spawned; ships: " .. table.concat(names, ", "))
	completeAndSplit(player, J4.M2[2], J4.M2[3])
	pump(5000, J4.M2[3] .. " spawn")
	completeAndSplit(player, J4.M2[3], J4.M2[4])
	pump(3000, J4.M2[4] .. " start")
	completeAndSplit(player, J4.M2[4], nil)
	pump(8000, J4.M2[4] .. " after completion")
	noMemberActive(player, 2)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

-- AC-3 (c): the second surprise attack
function TestInquisitionT4Chain2:test_surprise_2_b_spawns_six_pulsars()
	local player = chain(2)

	begin(player, J4.M2[3])
	pump(5000, J4.M2[3] .. " spawn")
	lu.assertEquals(countOf(shipNames(H.spawnedShips()), "coynite_merc_pulsar_tier4"), 6, J4.M2[3] .. ": pulsars")
end

-- AC-3 (c): recovery 2_c: the Coynite neutron (tier 5) and four pulsar escorts
function TestInquisitionT4Chain2:test_recovery_2_c_spawns_the_neutron_tier_5_with_four_pulsar_escorts()
	local player = chain(2)
	local _, ship = recoveryShip(player, J4.M2[4])
	local names = shipNames(H.spawnedShips())

	lu.assertEquals(ship.shipName, "coynite_merc_neutron_tier5", J4.M2[4] .. ": the recovery ship")
	lu.assertEquals(countOf(names, "coynite_merc_pulsar_tier4"), 4, J4.M2[4] .. ": pulsar escorts among " .. table.concat(names, ", "))
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 3
---------------------------------------------------------------------------------------------

TestInquisitionT4Chain3 = {}

function TestInquisitionT4Chain3:setUp() H.reset() end

function TestInquisitionT4Chain3:tearDown() AC.tearDown() end

-- AC-4 (a): the survival starts at its transmission point
function TestInquisitionT4Chain3:test_survival_3_gives_a_waypoint_at_its_transmission_point()
	local player = chain(3)

	begin(player, J4.M3[1])
	pump(5000, J4.M3[1] .. " start")

	local p = J4.POINTS.naboo_imperial_tier4_survival1

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), J4.M3[1] .. ": a waypoint at naboo_imperial_tier4_survival1")
	lu.assertTrue(isActive(player, quest(J4.M3[1])), J4.M3[1] .. ": active")
end

-- AC-4 (a): survival > delivery > assassinate (the mothership with 9 escorts) > won
function TestInquisitionT4Chain3:test_survival_delivery_and_assassinate_follow_each_other_and_the_mission_is_won()
	local player = chain(3)

	begin(player, J4.M3[1])
	pump(60000, J4.M3[1] .. " running")
	completeAndSplit(player, J4.M3[1], J4.M3[2])
	pump(10000, J4.M3[2] .. " running")
	completeAndSplit(player, J4.M3[2], J4.M3[3])
	pump(40000, J4.M3[3] .. " deployTargets")

	local names = shipNames(H.spawnedShips())
	local want = tally(J4.fixtureOf(J4.M3[3]):list("targetEscort"))

	want.coynite_mothership_tier4 = 1
	lu.assertEquals(tally(names), want, J4.M3[3] .. ": the ships spawned (" .. table.concat(names, ", ") .. ")")
	lu.assertEquals(#names, 10, "the mothership and nine escorts")

	local target, escorts = nil, {}

	for _, s in ipairs(H.spawnedShips()) do
		if s.shipName == "coynite_mothership_tier4" then
			target = s
		else
			escorts[#escorts + 1] = s
		end
	end

	local q = quest(J4.M3[3])

	H.destroyShip(target, player.rootParent)
	pump(5000, J4.M3[3] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive (mustDestroyEscort)")

	for _, s in ipairs(escorts) do
		H.destroyShip(s, player.rootParent)
		pump(1500, J4.M3[3] .. " after a kill")
	end

	pump(5000, J4.M3[3] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), J4.M3[3] .. ": complete after the target and the escorts")
	pump(8000, J4.M3[3] .. " after completion")
	noMemberActive(player, 3)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
	lu.assertFalse(handler():isFailed(player, 3), "mission 3 is not failed")
end

-- AC-4 (a): a failed assassinate 3_b makes the mission failed and starts nothing
function TestInquisitionT4Chain3:test_a_failed_assassinate_3_b_makes_mission_3_failed_and_starts_nothing()
	local player = chain(3)

	for _, global in ipairs({ J4.M3[1], J4.M3[2] }) do
		J4.setState(player, global, "complete")
	end

	local q = begin(player, J4.M3[3])

	pump(40000, J4.M3[3] .. " deployTargets")
	q:failQuest(player, true)
	pump(10000, J4.M3[3] .. " after the failure")
	lu.assertFalse(isComplete(player, q), "3_b is not complete")
	noMemberActive(player, 3)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isFailed(player, 3), "mission 3 is failed (attempted, not won, not running)")
	lu.assertFalse(handler():isWon(player, 3), "mission 3 is not won")
	lu.assertEquals(J4.firstScreen(J4.pilot({ mission = { [3] = "attempted" }, paid = { 1, 2 }, t4 = { 1, 2, 3 }, met = true })), "m3_failed", "the failure line")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 4
---------------------------------------------------------------------------------------------

TestInquisitionT4Chain4 = {}

function TestInquisitionT4Chain4:setUp() H.reset() end

function TestInquisitionT4Chain4:tearDown() AC.tearDown() end

-- AC-4 (b), R-1: an escort as a story head, started by startSpaceQuestChain, spawns the prison shuttle once the pilot reaches the rendezvous point
function TestInquisitionT4Chain4:test_the_escort_head_starts_through_start_space_quest_chain_and_spawns_the_prison_shuttle()
	local player = chain(4)

	lu.assertTrue(SpaceHelpers:startSpaceQuestChain(player, nil, J4.M4[1]), "startSpaceQuestChain returns true: the head is active")
	pump(2500, J4.M4[1] .. " setup")

	local eq = quest(J4.M4[1])
	local start = readData(player.objectID .. eq.className .. ":startPoint:")

	lu.assertNotNil(start, J4.M4[1] .. ": setup chose a start point")
	H.enterArea(AC.areaByNumber(eq, start), player.rootParent)
	pump(12000, J4.M4[1] .. " escort ship arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "dathomir_prison_shuttle_tier4") >= 1, J4.M4[1] .. ": dathomir_prison_shuttle_tier4 spawned; ships: " .. table.concat(names, ", "))
end

-- AC-4 (b): the prison-break shuttle and five pulsar escorts
function TestInquisitionT4Chain4:test_recovery_4_a_spawns_the_prison_break_shuttle_with_five_pulsar_escorts()
	local player = chain(4)
	local _, ship = recoveryShip(player, J4.M4[2])
	local names = shipNames(H.spawnedShips())

	lu.assertEquals(ship.shipName, "dathomir_prison_break_shuttle_tier4", J4.M4[2] .. ": the recovery ship")
	lu.assertEquals(ship.zone, "space_dathomir", J4.M4[2] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "coynite_merc_pulsar_tier4"), 5, J4.M4[2] .. ": pulsar escorts among " .. table.concat(names, ", "))
end

-- AC-4 (b): the two assassinations: the prison-break shuttle with its escorts, from the fixtures
function TestInquisitionT4Chain4:test_assassinate_4_b_and_4_c_spawn_the_shuttle_with_the_escorts_of_their_fixtures()
	for _, global in ipairs({ J4.M4[3], J4.M4[4] }) do
		local player = chain(4)

		begin(player, global)
		pump(40000, global .. " deployTargets")

		local names = shipNames(H.spawnedShips())
		local want = tally(J4.fixtureOf(global):list("targetEscort"))

		want.dathomir_prison_break_shuttle_tier4 = 1
		lu.assertEquals(tally(names), want, global .. ": the ships spawned (" .. table.concat(names, ", ") .. ")")
	end
end

-- AC-4 (b): the space battle: TIE fighters and interceptors against the Coynfury force
function TestInquisitionT4Chain4:test_battle_4_d_spawns_the_tie_allies_and_the_coynite_force_of_its_fixture()
	local player = chain(4)

	begin(player, J4.M4[5])
	pump(100000, J4.M4[5] .. " arrivals")

	local names = shipNames(H.spawnedShips())
	local rec = J4.fixtureOf(J4.M4[5])
	local want = tally(rec:list("allyForce"))

	for name, n in pairs(tally(rec:list("enemyForce"))) do
		want[name] = (want[name] or 0) + n
	end

	for name, n in pairs(want) do
		lu.assertEquals(countOf(names, name), n, "force ship " .. name .. " among " .. table.concat(names, ", "))
	end

	lu.assertEquals(countOf(names, "imp_tie_fighter_tier4"), 3, "allies: TIE fighters")
	lu.assertEquals(countOf(names, "imp_tie_interceptor_tier4"), 4, "allies: TIE interceptors")
	lu.assertEquals(countOf(names, "coynite_coynfury_tier4"), 1, "enemies: the Coynfury")
end

-- AC-4 (b): the whole chain by completions; completing 4_d makes mission 4 won
function TestInquisitionT4Chain4:test_the_chain_runs_from_the_escort_to_the_space_battle_and_mission_4_is_won()
	local player = chain(4)

	begin(player, J4.M4[1])
	pump(2500, J4.M4[1] .. " setup")
	completeAndSplit(player, J4.M4[1], J4.M4[2])
	pump(70000, J4.M4[2] .. " arrival")
	completeAndSplit(player, J4.M4[2], J4.M4[3])
	pump(40000, J4.M4[3] .. " deployTargets")
	completeAndSplit(player, J4.M4[3], J4.M4[4])
	pump(40000, J4.M4[4] .. " deployTargets")
	completeAndSplit(player, J4.M4[4], J4.M4[5])
	pump(100000, J4.M4[5] .. " arrivals")
	completeAndSplit(player, J4.M4[5], nil)
	pump(8000, J4.M4[5] .. " after completion")
	noMemberActive(player, 4)
	J4.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end

---------------------------------------------------------------------------------------------
-- AC-4 (c): the duties
---------------------------------------------------------------------------------------------

TestInquisitionT4DutyRuns = {}

function TestInquisitionT4DutyRuns:setUp() H.reset() end

function TestInquisitionT4DutyRuns:tearDown() AC.tearDown() end

-- AC-4 (c): each duty screen starts exactly its duty global once and, in a ship, a running duty makes the pilot "on a mission"
function TestInquisitionT4DutyRuns:test_each_duty_screen_starts_its_duty_once_and_a_running_duty_makes_is_on_mission_true()
	J4.requireConversation(lu)

	for _, d in ipairs(J4.DUTY_MENU) do
		H.reset()

		local q = quest(d.global)
		local player = J4.pilot({ met = true, inShip = true, zone = q.questZone })

		lu.assertFalse(handler():isOnMission(player), d.global .. ": not on a mission before")
		J4.drive(player, d.screen)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": active after its screen")
		lu.assertTrue(handler():isOnMission(player), d.global .. ": a running duty makes isOnMission true")
	end
end
