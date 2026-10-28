-- Black Epsilon tier 4 (Nin Gursawe): the four missions run through the fakes, split by split.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-3, AC-4; Data mapping 1; FN-5; R-1).
--
-- The oracle values are the spec's literals (black_epsilon_tier4_data.lua) and the SWG fixtures; the quest tables are driven through the harness's
-- fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an event shows up as "no Lua
-- error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and pumps the
-- split delay (the alert fires at the delay, the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL ship template
-- files (ship_mobile/ships/<ship>.lua), not a cargo set on the fake ship: the tier 2 runtime test did that and missed a broken quest. Flying the
-- survival, the battle and the escort is covered by their type features: this file stops at "active / spawned" for them.
-- The hostility of the real AI cannot be checked here; see the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local T = require("black_epsilon_tier4_data")

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

-- name -> count of a list
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

-- A fresh world with every member of the mission's chain started (static areas), and an Imperial pilot in a ship in the mission's zone
local function chain(n)
	H.reset()

	local members = T.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		local q = quest(global)

		if q.preRecoveryPoints ~= nil then
			AC.resolveRecoveryPoints(q)
		end
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

local function handler() return rawget(_G, T.HANDLER) end

-- the cargo the server's ship template gives the inspect ship (read from the real template file)
local function templateCargo(ship)
	local t = H.shipTemplate(ship)

	lu.assertNotNil(t, "ship_mobile/ships/" .. ship .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, ship .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FN-5)")

	return t.cargoString
end

local function inspectShip(c, cargo)
	return H.worldAgent({ shipName = c.ship, cargo = cargo, spawner = c.spawner.name, zone = c.spawner.zone })
end

-- inspect + dock with the ship of `c` carrying `cargo`, then let the quest see it
local function inspectAndDock(player, c, cargo, label)
	local target = inspectShip(c, cargo)
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, label .. " inspect")
	H.dock(player, target, hash)
	pump(0, label .. " dock")
	pump(1000, label .. " after the dock")
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): patrol 1 and its trigger
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Patrol1 = {}

function TestBlackEpsilonT4Patrol1:setUp() H.reset() end

function TestBlackEpsilonT4Patrol1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestBlackEpsilonT4Patrol1:test_the_patrol_starts_active_with_a_waypoint_at_point_1()
	local player = chain(1)
	local q = begin(player, T.M1[1])
	local p1 = T.POINTS.space_dantooine.corellia_imperial_tier4_patrol1_1

	lu.assertTrue(isActive(player, q), T.M1[1] .. ": active")
	lu.assertNotNil(waypointAt(player, p1[1], p1[2], p1[3]), T.M1[1] .. ": a waypoint at corellia_imperial_tier4_patrol1_1")
end

-- AC-3 (a): 25 s after reaching point 3 the patrol is complete; about 1 s later inspect 1_a is active with its waypoint
function TestBlackEpsilonT4Patrol1:test_reaching_point_3_and_waiting_25_seconds_completes_the_patrol_and_starts_the_inspect_a_second_later()
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
	pump(24000, T.M1[1] .. " 24 s after point 3")
	lu.assertFalse(isComplete(player, q), "the patrol is not complete 24 s after point 3 (sideQuestDelay 25 s)")
	lu.assertFalse(isActive(player, inspect), "inspect 1_a is not active 24 s after point 3")
	pump(1500, T.M1[1] .. " 25.5 s after point 3")
	lu.assertTrue(isComplete(player, q), "the patrol is complete 25.5 s after point 3")
	pump(1500, T.M1[1] .. " 27 s after point 3")
	lu.assertTrue(isActive(player, inspect), "inspect 1_a is active about 1 s after the patrol completed")
	pump(4000, T.M1[2] .. " setup")

	local s = T.SPAWNERS[1]

	lu.assertNotNil(waypointAt(player, s.x, s.z, s.y), T.M1[2] .. ": a waypoint at the spawner " .. s.name)
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): inspect 1_a with the real ship template cargo, then the survival
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Chain1 = {}

function TestBlackEpsilonT4Chain1:setUp() H.reset() end

function TestBlackEpsilonT4Chain1:tearDown() AC.tearDown() end

-- AC-3 (b), FN-5
function TestBlackEpsilonT4Chain1:test_inspecting_and_docking_with_the_captains_ship_carrying_its_templates_cargo_completes_1_a_and_starts_the_survival_5_seconds_later()
	local player = chain(1)
	local c = T.INSPECTS[1]
	local q = begin(player, T.M1[2])
	local survival = quest(T.M1[3])

	pump(2500, T.M1[2] .. " setup")

	local cargo = templateCargo(c.ship)

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")
	inspectAndDock(player, c, cargo, T.M1[2])
	lu.assertTrue(isComplete(player, q), T.M1[2] .. ": complete after docking with the captain's ship")
	pump(3000, T.M1[2] .. " split delay")
	lu.assertFalse(isActive(player, survival), "survival 1_b is not active 4 s after the dock")
	pump(3000, T.M1[2] .. " split start")
	lu.assertTrue(isActive(player, survival), "survival 1_b is active 7 s after the dock")
end

-- AC-3 (b): a ship with another cargo does not complete it
function TestBlackEpsilonT4Chain1:test_a_ship_with_another_cargo_does_not_complete_the_quest()
	local player = chain(1)
	local q = begin(player, T.M1[2])

	pump(2500, T.M1[2] .. " setup")
	inspectAndDock(player, T.INSPECTS[1], "stolen_data", T.M1[2])
	lu.assertFalse(isComplete(player, q), T.M1[2] .. ": not complete with the wrong cargo")
end

-- AC-3 (b): the cargo of another mission's ship does not complete it either
function TestBlackEpsilonT4Chain1:test_the_cargo_of_another_missions_inspect_does_not_complete_1_a()
	local player = chain(1)
	local q = begin(player, T.M1[2])

	pump(2500, T.M1[2] .. " setup")
	inspectAndDock(player, T.INSPECTS[1], T.INSPECTS[2].cargo, T.M1[2])
	lu.assertFalse(isComplete(player, q), T.M1[2] .. ": not complete with inspect2's cargo")
end

-- AC-3 (b): the survival waits at the Dantooine point, and completing it wins the mission
function TestBlackEpsilonT4Chain1:test_survival_1_b_gives_a_waypoint_at_its_point_and_its_completion_leaves_no_member_active_and_the_mission_won()
	local player = chain(1)

	for _, global in ipairs({ T.M1[1], T.M1[2] }) do
		T.setState(player, global, "complete")
	end

	begin(player, T.M1[3])
	pump(5000, T.M1[3] .. " start")

	local p = T.POINTS.space_dantooine.corellia_imperial_tier4_survival1

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), T.M1[3] .. ": a waypoint at corellia_imperial_tier4_survival1")
	pump(60000, T.M1[3] .. " running")
	completeAndSplit(player, T.M1[3], nil)
	pump(8000, T.M1[3] .. " after completion")

	for _, global in ipairs(T.M1) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 1 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): mission 2
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Chain2 = {}

function TestBlackEpsilonT4Chain2:setUp() H.reset() end

function TestBlackEpsilonT4Chain2:tearDown() AC.tearDown() end

-- AC-3 (c): the deserted freighter, no escorts
function TestBlackEpsilonT4Chain2:test_recovery_2_spawns_the_deserted_freighter_alone_after_its_arrival_delay()
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

	lu.assertEquals(run.ship.shipName, "deserted_freighter_tier4", T.M2[1] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_dantooine", T.M2[1] .. ": the recovery ship zone")
	lu.assertEquals(#names, 1, T.M2[1] .. ": no escorts, only the freighter among " .. table.concat(names, ", "))
end

-- AC-3 (c): the chain recovery > inspect 2_a (template cargo) > delivery > won
function TestBlackEpsilonT4Chain2:test_recovery_inspect_and_delivery_follow_each_other_and_the_mission_is_won()
	local player = chain(2)
	local c = T.INSPECTS[2]

	begin(player, T.M2[1])
	pump(60000, T.M2[1] .. " arrival")
	completeAndSplit(player, T.M2[1], T.M2[2])
	pump(2500, T.M2[2] .. " setup")

	local q = quest(T.M2[2])
	local cargo = templateCargo(c.ship)

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")

	local s = T.SPAWNERS[2]

	lu.assertNotNil(waypointAt(player, s.x, s.z, s.y), T.M2[2] .. ": a waypoint at the spawner " .. s.name)
	inspectAndDock(player, c, cargo, T.M2[2])
	lu.assertTrue(isComplete(player, q), T.M2[2] .. ": complete after docking with the group leader's ship")
	pump(3000, T.M2[2] .. " split delay")
	lu.assertFalse(isActive(player, quest(T.M2[3])), "delivery 2_b is not active 4 s after the dock")
	pump(3000, T.M2[2] .. " split start")
	lu.assertTrue(isActive(player, quest(T.M2[3])), "delivery 2_b is active 7 s after the dock")
	pump(10000, T.M2[3] .. " setup")
	completeAndSplit(player, T.M2[3], nil)
	pump(8000, T.M2[3] .. " after completion")

	for _, global in ipairs(T.M2) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 2 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

-- AC-3 (c): the wrong cargo does not complete 2_a
function TestBlackEpsilonT4Chain2:test_a_ship_with_another_cargo_does_not_complete_inspect_2_a()
	local player = chain(2)
	local q = begin(player, T.M2[2])

	pump(2500, T.M2[2] .. " setup")
	inspectAndDock(player, T.INSPECTS[2], T.INSPECTS[1].cargo, T.M2[2])
	lu.assertFalse(isComplete(player, q), T.M2[2] .. ": not complete with inspect1's cargo")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 3 in Dathomir
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Chain3 = {}

function TestBlackEpsilonT4Chain3:setUp() H.reset() end

function TestBlackEpsilonT4Chain3:tearDown() AC.tearDown() end

-- AC-4 (a), R-1: an escort as a story head, started by startSpaceQuestChain, spawns the drop ship once the pilot reaches the rendezvous point
function TestBlackEpsilonT4Chain3:test_the_escort_head_starts_through_start_space_quest_chain_and_spawns_the_drop_ship()
	local player = chain(3)

	lu.assertTrue(SpaceHelpers:startSpaceQuestChain(player, nil, T.M3[1]), "startSpaceQuestChain returns true: the head is active")
	pump(2500, T.M3[1] .. " setup")

	local eq = quest(T.M3[1])
	local start = readData(player.objectID .. eq.className .. ":startPoint:")

	lu.assertNotNil(start, T.M3[1] .. ": setup chose a start point")
	H.enterArea(AC.areaByNumber(eq, start), player.rootParent)
	pump(12000, T.M3[1] .. " escort ship arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "imperial_drop_ship_tier4") >= 1, T.M3[1] .. ": imperial_drop_ship_tier4 spawned; ships: " .. table.concat(names, ", "))
end

-- AC-4 (a), R-1: escort > rescue > patrol (a patrol in mid-chain) > inspect 3_c with the real template cargo > won
function TestBlackEpsilonT4Chain3:test_escort_rescue_patrol_and_inspect_follow_each_other_and_the_mission_is_won()
	local player = chain(3)
	local c = T.INSPECTS[3]

	begin(player, T.M3[1])
	pump(2500, T.M3[1] .. " setup")
	completeAndSplit(player, T.M3[1], T.M3[2])
	pump(20000, T.M3[2] .. " running")
	completeAndSplit(player, T.M3[2], T.M3[3])

	-- patrol 3_b: points 1 and 2 do nothing, 20 s after point 3 the patrol is complete and inspect 3_c follows
	local pq = quest(T.M3[3])
	local inspect = quest(T.M3[4])

	for point = 1, 2 do
		H.enterArea(AC.areaByNumber(pq, point), player.rootParent)
		pump(500, T.M3[3] .. " point " .. point)
	end

	pump(30000, T.M3[3] .. " waiting at point 2")
	lu.assertFalse(isComplete(player, pq), "points 1 and 2 do not complete patrol 3_b")
	H.enterArea(AC.areaByNumber(pq, 3), player.rootParent)
	pump(19000, T.M3[3] .. " 19 s after point 3")
	lu.assertFalse(isComplete(player, pq), "patrol 3_b is not complete 19 s after point 3 (sideQuestDelay 20 s)")
	pump(1500, T.M3[3] .. " 20.5 s after point 3")
	lu.assertTrue(isComplete(player, pq), "patrol 3_b is complete 20.5 s after point 3")
	pump(1500, T.M3[3] .. " 22 s after point 3")
	lu.assertTrue(isActive(player, inspect), "inspect 3_c is active about 1 s after the patrol completed")
	pump(4000, T.M3[4] .. " setup")

	local s = T.SPAWNERS[3]

	lu.assertNotNil(waypointAt(player, s.x, s.z, s.y), T.M3[4] .. ": a waypoint at the spawner " .. s.name)

	local cargo = templateCargo(c.ship)

	lu.assertEquals(cargo, inspect.cargo, "the template's cargoString equals the quest cargo")
	inspectAndDock(player, c, cargo, T.M3[4])
	lu.assertTrue(isComplete(player, inspect), T.M3[4] .. ": complete after docking with the commander's ship")
	pump(8000, T.M3[4] .. " after completion")

	for _, global in ipairs(T.M3) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 3 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
end

-- AC-4 (a): the rescue spawns the drop ship to be rescued
function TestBlackEpsilonT4Chain3:test_rescue_3_a_spawns_the_drop_ship()
	local player = chain(3)

	begin(player, T.M3[2])
	pump(20000, T.M3[2] .. " arrival")

	local names = shipNames(H.spawnedShips())

	lu.assertTrue(countOf(names, "imperial_drop_ship_tier4") >= 1, T.M3[2] .. ": imperial_drop_ship_tier4 spawned; ships: " .. table.concat(names, ", "))
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 4 in Dathomir
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Chain4 = {}

function TestBlackEpsilonT4Chain4:setUp() H.reset() end

function TestBlackEpsilonT4Chain4:tearDown() AC.tearDown() end

-- AC-4 (b): Nej'a Bertolo and seven escorts
function TestBlackEpsilonT4Chain4:test_assassinate_4_spawns_neja_bertolo_with_the_seven_escorts_of_its_fixture()
	local player = chain(4)

	begin(player, T.M4[1])
	pump(40000, T.M4[1] .. " deployTargets")

	local names = shipNames(H.spawnedShips())
	local want = tally(T.fixtureOf(T.M4[1]):list("targetEscort"))

	want.neja_bertolo_tier5 = 1
	lu.assertEquals(tally(names), want, T.M4[1] .. ": the ships spawned (" .. table.concat(names, ", ") .. ")")
	lu.assertEquals(#names, 8, "the target and seven escorts")
end

-- AC-4 (b): the smuggler and seven escorts
function TestBlackEpsilonT4Chain4:test_recovery_4_a_spawns_the_velocity_smuggler_with_seven_escorts()
	local player = chain(4)
	local run = DRS.startRecoveryRun(quest(T.M4[2]), player)

	pump(10000, T.M4[2] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())
	local want = tally(T.fixtureOf(T.M4[2]):list("targetEscort"))

	lu.assertEquals(run.ship.shipName, "velocity_smuggler_tier4", T.M4[2] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_dathomir", T.M4[2] .. ": the recovery ship zone")

	for name, n in pairs(want) do
		lu.assertEquals(countOf(names, name), n, T.M4[2] .. ": " .. name .. " escorts among " .. table.concat(names, ", "))
	end
end

-- AC-4 (b): the surprise attack spawns eight heavy fighters once the pilot is in the zone, and leads to the battle after 10 s
function TestBlackEpsilonT4Chain4:test_the_surprise_attack_spawns_eight_heavy_fighters_and_the_battle_follows_after_ten_seconds()
	local player = chain(4)

	begin(player, T.M4[3])
	pump(5000, T.M4[3] .. " spawn")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "velocity_merc_heavy_fighter_tier4"), 8, T.M4[3] .. ": heavy fighters among " .. table.concat(names, ", "))
	completeAndSplit(player, T.M4[3], T.M4[4], 10)
end

-- AC-4 (b): the battle: five TIE interceptors on the Imperial side, Tiberus Anderlock and the Velocity fighters of the fixture against it
function TestBlackEpsilonT4Chain4:test_battle_4_c_spawns_the_tie_allies_and_the_velocity_force()
	local player = chain(4)

	begin(player, T.M4[4])
	pump(100000, T.M4[4] .. " arrivals")

	local names = shipNames(H.spawnedShips())
	local rec = T.fixtureOf(T.M4[4])

	lu.assertEquals(countOf(names, "imp_tie_interceptor_tier4"), 5, "allies among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "tiberus_anderlock_tier5"), 1, "Tiberus Anderlock among " .. table.concat(names, ", "))

	for name, n in pairs(tally(rec:list("enemyForce"))) do
		lu.assertEquals(countOf(names, name), n, "enemy " .. name .. " among " .. table.concat(names, ", "))
	end
end

-- AC-4 (b): the whole chain, then Onli Shi'en and nine escorts
function TestBlackEpsilonT4Chain4:test_the_chain_runs_to_assassinate_4_d_and_killing_the_target_and_all_escorts_wins_the_mission()
	local player = chain(4)

	begin(player, T.M4[1])
	pump(40000, T.M4[1] .. " deployTargets")
	completeAndSplit(player, T.M4[1], T.M4[2])
	pump(60000, T.M4[2] .. " arrival")
	completeAndSplit(player, T.M4[2], T.M4[3])
	pump(5000, T.M4[3] .. " spawn")
	completeAndSplit(player, T.M4[3], T.M4[4], 10)
	pump(100000, T.M4[4] .. " arrivals")
	completeAndSplit(player, T.M4[4], T.M4[5])
	local alreadyThere = #H.spawnedShips()

	pump(40000, T.M4[5] .. " deployTargets")

	local target, escorts, names = nil, {}, {}

	for i, s in ipairs(H.spawnedShips()) do
		if i > alreadyThere then
			names[#names + 1] = s.shipName
		end

		if i > alreadyThere then
			if s.shipName == "onli_shien_tier5" then
				target = s
			else
				escorts[#escorts + 1] = s
			end
		end
	end

	lu.assertNotNil(target, "Onli Shi'en among " .. table.concat(names, ", "))
	lu.assertEquals(#escorts, 9, T.M4[5] .. ": the nine escorts of the fixture among the ships spawned for 4_d: " .. table.concat(names, ", "))

	local q = quest(T.M4[5])

	H.destroyShip(target, player.rootParent)
	pump(5000, T.M4[5] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive (mustDestroyEscort)")

	for _, s in ipairs(escorts) do
		H.destroyShip(s, player.rootParent)
		pump(1500, T.M4[5] .. " after a kill")
	end

	pump(5000, T.M4[5] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), T.M4[5] .. ": complete after the target and the escorts")
	pump(8000, T.M4[5] .. " after completion")

	for _, global in ipairs(T.M4) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission 4 member is active")
	end

	T.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end
