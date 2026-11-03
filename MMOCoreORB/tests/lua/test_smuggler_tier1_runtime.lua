-- Smuggler tier 1 (Dravis): the four story missions and the four duties run through the fakes.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-3, AC-4; Data mapping 1; R-2).
--
-- The oracle values are the spec's literals (smuggler_tier1_data.lua, proven equal to the SWG .tab fixtures by test_smuggler_tier1_data.lua); the
-- quest tables are driven through the harness's fakes, never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua
-- error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. R-2 (the real AI's hostility toward `smuggler` ships) cannot be
-- checked here; see the in-game checklist of the spec. The pilot is a Smuggler in a ship, so the attack waves target the `smuggler` faction.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DR = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local S = require("smuggler_tier1_data")

S.load()

local function quest(global) return S.quest(global) end

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

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local function newPlayer(q)
	-- smuggler-tier2-shamdon SC-1/SC-2: the attack waves read the ship's faction; a tier 1 Smuggler's launched ship carries "smuggler" (C++ resetShipFaction)
	return S.pilot({ zone = q.questZone, inShip = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = getHashCode("smuggler") } })
end

-- A Smuggler in a ship in the quest zone who starts `global` (the quest's own startQuest, as a trainer does)
local function started(global)
	local q = quest(global)

	H.reset()
	q:start()

	local player = newPlayer(q)

	q:startQuest(player, "")
	H.advance(0)

	return q, player
end

local function teardown()
	AC.tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- SpaceEscortScreenplay reschedules its attack wave every attackDelay seconds (default 0): a missing delay is a failure here, not a hang.
local function assertDelay(global)
	lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds, 0 by default)")
end

-- The escort run of AC.escortRun with a Smuggler: setupEscort (2 s), the start area, the escort ship (5-11 s)
local function escortRun(global)
	assertDelay(global)

	local q, player = started(global)

	H.advance(2500)

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	H.advance(6000)

	return { q = q, player = player, escortAgent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:")) }
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

local function hasValue(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): mission 1, the patrol and its surprise attack
---------------------------------------------------------------------------------------------

TestSmugglerT1Mission1 = {}

function TestSmugglerT1Mission1:setUp() H.reset() end
function TestSmugglerT1Mission1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestSmugglerT1Mission1:test_reaching_point_2_and_waiting_20_seconds_spawns_three_blacksun_fighters_and_killing_all_completes_both_quests()
	local q, player = started(S.P1)
	local s1 = quest(S.S1)

	lu.assertTrue(isActive(player, q), S.P1 .. ": precondition: active after startQuest")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, S.P1 .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, S.P1 .. " point 2")
	lu.assertEquals(#H.spawnedShips(), 0, S.P1 .. ": no attacker right after point 2")

	pump(18000, S.P1 .. " split delay")
	lu.assertEquals(#H.spawnedShips(), 0, S.P1 .. ": still no attacker 18.5 s after point 2 (sideQuestDelay is 20 s)")

	pump(8000, S.P1 .. " surprise attack start")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier1" }, S.S1 .. ": spawned attackers")
	lu.assertTrue(isActive(player, s1), S.S1 .. ": active once the split started it")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_tatooine", S.S1 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, S.S1 .. ": attacker " .. i .. " belongs to the pilot")
	end

	for k = 1, 2 do
		H.destroyShip(ships[k], player.rootParent)
		pump(1500, S.S1 .. " after kill " .. k)
		lu.assertFalse(isComplete(player, s1), S.S1 .. ": not complete after " .. k .. " of 3 kills")
	end

	H.destroyShip(ships[3], player.rootParent)
	pump(3000, S.S1 .. " after kill 3")

	lu.assertTrue(isComplete(player, s1), S.S1 .. ": complete after all three attackers are destroyed")
	lu.assertTrue(isComplete(player, q), S.P1 .. ": the patrol is complete")
	lu.assertFalse(isActive(player, q), S.P1 .. ": the patrol is no longer active")
end

-- AC-3 (a): the split needs point 2
function TestSmugglerT1Mission1:test_no_surprise_attack_before_point_2()
	local q, player = started(S.P1)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(40000, S.P1 .. " waiting at point 1")
	lu.assertEquals(#H.spawnedShips(), 0, S.P1 .. ": no attacker when point 2 was never reached")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): mission 2, destroy
---------------------------------------------------------------------------------------------

TestSmugglerT1Mission2 = {}

function TestSmugglerT1Mission2:setUp() H.reset() end

-- AC-3 (b)
function TestSmugglerT1Mission2:test_the_pilot_gets_four_waypoints_and_four_kills_of_listed_black_sun_types_complete_the_quest()
	local q, player = started(S.M2)

	H.zoneSwitch(player, q.questZone)
	pump(500, S.M2 .. " zone entry")
	lu.assertEquals(#player.ghost.waypoints, 4, S.M2 .. ": waypoints handed out (one per spawner, no blacksun_guards_2)")

	-- the first, a middle and the last cell of the 32-entry list, and the duplicated one
	local kills = { "blacksun_ace_s04_tier1", "blacksun_marauder_tier2", "blacksun_fighter_s01_tier2_tatooine", "blacksun_fighter_s02_tier3_dantooine" }

	for k, shipName in ipairs(kills) do
		lu.assertFalse(isComplete(player, q), S.M2 .. ": not complete before kill " .. k)

		local agent = H.worldAgent({ shipName = shipName, zone = q.questZone })

		H.fireObservers(DESTROYEDSHIP, player, agent)
		pump(1500, S.M2 .. " after kill " .. k)
	end

	lu.assertTrue(isComplete(player, q), S.M2 .. ": complete after 4 kills of ships of the table")
end

-- AC-3 (b): only the table's ships count
function TestSmugglerT1Mission2:test_kills_of_other_ships_do_not_count()
	local q, player = started(S.M2)

	H.zoneSwitch(player, q.questZone)

	for _, shipName in ipairs({ "blacksun_ace_s04_tier3", "blacksun_fighter_s01_tier3", "blacksun_dark_eclipse_tier1", "reb_xwing_tier1", "valarian_gunship_tier1" }) do
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = shipName, zone = q.questZone }))
	end

	pump(1500, S.M2 .. " after five kills of unlisted ships")
	lu.assertFalse(isComplete(player, q), S.M2 .. ": kills of ships the table does not list complete nothing")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): mission 3, patrol then escort
---------------------------------------------------------------------------------------------

TestSmugglerT1Mission3 = {}

function TestSmugglerT1Mission3:setUp() H.reset() end
function TestSmugglerT1Mission3:tearDown() AC.tearDown() end

-- AC-3 (c): the split starts the escort after point 2 and 20 s
function TestSmugglerT1Mission3:test_reaching_point_2_of_the_patrol_starts_escort_3_after_20_seconds()
	local q, player = started(S.P3)
	local e3 = quest(S.E3)

	e3:start()
	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, S.P3 .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(18500, S.P3 .. " 18.5 s after point 2")
	lu.assertFalse(isActive(player, e3), S.E3 .. ": not started 18.5 s after point 2 (sideQuestDelay is 20 s)")
	pump(8000, S.P3 .. " split")
	lu.assertTrue(isActive(player, e3), S.E3 .. ": started by the split")
end

-- AC-3 (c)
function TestSmugglerT1Mission3:test_the_hutt_light_freighter_spawns_at_one_of_the_four_escort_points()
	local run = escortRun(S.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, S.E3 .. ": the escort ship spawned")
	lu.assertEquals(agent.shipName, "hutt_freighterlight_tier1", S.E3 .. ": the escort ship")
	lu.assertEquals(agent.zone, "space_tatooine", S.E3 .. ": the escort ship zone")
	lu.assertTrue(isActive(run.player, run.q), S.E3 .. ": active")
end

-- AC-3 (c): the first wave comes from one of the two attack lists after 90 s
function TestSmugglerT1Mission3:test_the_first_attack_wave_after_90_seconds_is_one_of_the_two_black_sun_lists()
	local run = escortRun(S.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, S.E3 .. ": the escort ship spawned")
	pump(5000, S.E3 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(91 * 1000, S.E3 .. " spawnAttackWave (attackDelay 90 s)")

	local attackers = newShips(before, agent)
	local names = sorted(shipNames(attackers))

	lu.assertTrue(table.concat(names, ",") == "blacksun_fighter_s01_tier1,blacksun_fighter_s02_tier1" or table.concat(names, ",") == "blacksun_marauder_tier1,blacksun_marauder_tier1,blacksun_vehement_tier1",
		S.E3 .. ": the wave is list 1 or list 2, got " .. table.concat(names, ","))

	for i, ship in ipairs(attackers) do
		lu.assertTrue(hasValue(ship.factionEnemies, getHashCode("smuggler")), S.E3 .. ": attacker " .. i .. " is hostile to the smuggler faction of the pilot")
	end
end

-- AC-3 (c): both lists can be drawn (the random pick is the fake's)
function TestSmugglerT1Mission3:test_the_random_pick_can_draw_either_list()
	local seen = {}

	for _, pick in ipairs({ 1, 2 }) do
		teardown()

		local run = escortRun(S.E3)

		lu.assertNotNil(run.escortAgent, S.E3 .. ": the escort ship spawned")
		pump(5000, S.E3 .. " assignEscortPoints")
		H.Engine.nextRandom = pick

		local before = #H.spawnedShips()

		pump(91 * 1000, S.E3 .. " spawnAttackWave pick " .. pick)
		seen[#seen + 1] = #newShips(before, run.escortAgent)
	end

	lu.assertEquals(seen, { 2, 3 }, "attackers of draw 1 (list 1: 2 ships) and draw 2 (list 2: 3 ships)")
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): mission 4, assassinate
---------------------------------------------------------------------------------------------

TestSmugglerT1Mission4 = {}

function TestSmugglerT1Mission4:setUp() H.reset() end

-- AC-3 (d)
function TestSmugglerT1Mission4:test_the_ace_and_two_escorts_spawn_at_the_first_point_after_12_seconds()
	local q, player = started(S.A4)

	pump(11000, S.A4 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, S.A4 .. ": nothing spawned 11 s after the start (arrivalDelay 12)")

	pump(4000, S.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "blacksun_ace_s04_tier1", "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1" }, S.A4 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, S.A4 .. ": the target leads the squadron")
	lu.assertEquals(ships[2].squadronLeader, ships[1], S.A4 .. ": escort 1 flies in the target's squadron")
	lu.assertEquals(ships[3].squadronLeader, ships[1], S.A4 .. ": escort 2 flies in the target's squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { 2634, -5262, 1718 }, S.A4 .. ": the target spawns at targetPatrols[1] (anchorhead_supply_patrol_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, S.A4 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_tatooine", S.A4 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (d): mustDestroyEscort = true
function TestSmugglerT1Mission4:test_destroying_only_the_target_does_not_complete_the_quest()
	local q, player = started(S.A4)

	pump(15000, S.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 3, S.A4 .. ": precondition: target and two escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, S.A4 .. " after the target is destroyed")

	lu.assertFalse(isComplete(player, q), S.A4 .. ": not complete with both escorts alive")
	lu.assertTrue(isActive(player, q), S.A4 .. ": still active")
end

-- AC-3 (d)
function TestSmugglerT1Mission4:test_destroying_the_target_and_both_escorts_completes_the_quest()
	local q, player = started(S.A4)

	pump(15000, S.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 3, S.A4 .. ": precondition: target and two escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, S.A4 .. " target")
	H.destroyShip(ships[2], player.rootParent)
	pump(1500, S.A4 .. " escort 1")
	lu.assertFalse(isComplete(player, q), S.A4 .. ": not complete with one escort alive")
	H.destroyShip(ships[3], player.rootParent)
	pump(3000, S.A4 .. " escort 2")

	lu.assertTrue(isComplete(player, q), S.A4 .. ": complete when all three are destroyed")
	lu.assertFalse(isActive(player, q), S.A4 .. ": no longer active")
end

-- AC-3 (d): the order does not matter
function TestSmugglerT1Mission4:test_destroying_the_escorts_first_then_the_target_completes_the_quest()
	local q, player = started(S.A4)

	pump(15000, S.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	H.destroyShip(ships[2], player.rootParent)
	pump(1500, S.A4 .. " escort 1")
	H.destroyShip(ships[3], player.rootParent)
	pump(1500, S.A4 .. " escort 2")
	lu.assertFalse(isComplete(player, q), S.A4 .. ": not complete with the target alive")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, S.A4 .. " target")
	lu.assertTrue(isComplete(player, q), S.A4 .. ": complete when all three are destroyed")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): the two destroy duties
---------------------------------------------------------------------------------------------

TestSmugglerT1DestroyDuties = {}

function TestSmugglerT1DestroyDuties:setUp() H.reset() end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDestroyDuty(global)
	local q, player = started(global)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
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

local DESTROY_DUTIES = {
	{ global = S.DUTY6, boss = "blacksun_marauder_tier2" },
	{ global = S.DUTY8, boss = "blacksun_ace_s04_tier1" },
}

for _, d in ipairs(DESTROY_DUTIES) do
	-- AC-4 (a)
	TestSmugglerT1DestroyDuties["test_" .. d.global .. "_first_wave_comes_from_its_own_ship_lists"] = function()
		local q, player, area = startedDestroyDuty(d.global)
		local allowed = unionOf(S.expected()[d.global].shipTypes)

		H.enterArea(area, player.rootParent)
		pump(4500, d.global .. " spawnAttackWave (4 s after entering the area)")

		local ships = H.spawnedShips()

		lu.assertTrue(#ships >= 1, d.global .. ": wave 1 spawned")

		for i, ship in ipairs(ships) do
			lu.assertTrue(allowed[ship.shipName] == true, d.global .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
			lu.assertEquals(ship.missionOwner, player, d.global .. ": ship " .. i .. " belongs to the pilot")
		end
	end

	-- AC-4 (a): a later wave
	TestSmugglerT1DestroyDuties["test_" .. d.global .. "_a_later_wave_spawns_only_ships_of_the_table"] = function()
		local q, player, area = startedDestroyDuty(d.global)
		local allowed = unionOf(S.expected()[d.global].shipTypes)

		H.enterArea(area, player.rootParent)
		pump(500, d.global .. " entering")
		writeData(dataKey(q, player, "CurrentLevel:"), 1)
		pump(4000, d.global .. " spawnAttackWave")

		local ships = H.spawnedShips()

		lu.assertEquals(#ships, 2, d.global .. ": wave 1 of level 2 has wave + level - 1 = 2 ships")

		for i, ship in ipairs(ships) do
			lu.assertTrue(allowed[ship.shipName] == true, d.global .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end

	-- AC-4 (a): the boss
	TestSmugglerT1DestroyDuties["test_" .. d.global .. "_boss_wave_spawns_" .. d.boss .. "_first"] = function()
		local q, player, area = startedDestroyDuty(d.global)

		writeData(dataKey(q, player, "bossLevel:"), 1)
		H.enterArea(area, player.rootParent)
		pump(4500, d.global .. " spawnAttackWave (boss)")

		local ships = H.spawnedShips()

		lu.assertEquals(ships[1] and ships[1].shipName, d.boss, d.global .. ": the first ship of the boss wave")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), d.global .. ": the boss has the boss kill observer")
	end

	-- AC-4 (a): level 2 boss squad
	TestSmugglerT1DestroyDuties["test_" .. d.global .. "_the_level_two_boss_squad_is_the_boss_and_one_ship_of_the_table"] = function()
		local q, player, area = startedDestroyDuty(d.global)
		local allowed = unionOf(S.expected()[d.global].shipTypes)

		writeData(dataKey(q, player, "bossLevel:"), 1)
		writeData(dataKey(q, player, "CurrentLevel:"), 1)
		H.enterArea(area, player.rootParent)
		pump(4500, d.global .. " spawnAttackWave (level 2 boss)")

		local ships = H.spawnedShips()

		lu.assertEquals(#ships, 2, d.global .. ": level 2 boss squad size")
		lu.assertEquals(ships[1].shipName, d.boss, d.global .. ": the boss leads")
		lu.assertTrue(allowed[ships[2].shipName] == true, d.global .. ": the second ship '" .. tostring(ships[2].shipName) .. "' is one of the table's ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): escort duty 7
---------------------------------------------------------------------------------------------

TestSmugglerT1EscortDuty = {}

function TestSmugglerT1EscortDuty:setUp() H.reset() end
function TestSmugglerT1EscortDuty:tearDown() AC.tearDown() end

local function payouts(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:escort_reward" then
			out[#out + 1] = m.DI
		end
	end

	return out
end

-- The state a running duty leaves when its escort reaches the last area, built by hand (no event is pumped, so attackDelay has no say)
local function escortAtItsLastArea(kills)
	local q, player = started(S.DUTY7)
	local agent = spawnShipAgent("hutt_freightermedium_tier1", "space_tatooine", 0, 0, 0, player.rootParent)
	local area = spawnSpaceActiveArea("space_tatooine", "object/active_area.iff", 0, 0, 0, 250)
	local prefix = q.className

	writeData(agent.objectID .. ":" .. prefix .. ":escorterID:", player.objectID)
	writeData(player.objectID .. ":" .. prefix .. ":escortID:", agent.objectID)
	writeData(agent.objectID .. ":" .. prefix .. ":escortShipProgress:", 1)

	if kills > 0 then
		writeData(player.objectID .. ":" .. prefix .. ":" .. ":EscortKillCount:", kills)
	end

	return q, player, agent, area
end

-- AC-4 (b): 1000 + 100 per kill, without a Lua error
for kills, want in pairs({ [0] = 1000, [1] = 1100, [2] = 1200, [5] = 1500 }) do
	TestSmugglerT1EscortDuty["test_the_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		assertDelay(S.DUTY7)

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, S.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, S.DUTY7 .. ": @space/quest:escort_reward DI (1000 + 100 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, S.DUTY7 .. ": credits added to the bank")
	end
end

-- AC-4 (b): the escort is one of the two Hutt freighters
function TestSmugglerT1EscortDuty:test_each_of_the_two_hutt_freighters_can_be_the_escort()
	local names = { "hutt_freightermedium_tier1", "hutt_freighterheavy_tier1" }

	for pick, want in ipairs(names) do
		assertDelay(S.DUTY7)

		local q, player = started(S.DUTY7)

		H.Engine.queueRandom(1, 2, pick)
		pump(2500, S.DUTY7 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, S.DUTY7 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, S.DUTY7 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, S.DUTY7 .. ": escort ship for draw " .. pick)
	end
end

-- AC-4 (b): the attack wave after 90 s is a list of the table
function TestSmugglerT1EscortDuty:test_the_attack_wave_after_90_seconds_is_one_of_the_two_black_sun_lists()
	local run = escortRun(S.DUTY7)
	local agent = run.escortAgent

	lu.assertNotNil(agent, S.DUTY7 .. ": the escort ship spawned")
	pump(5000, S.DUTY7 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(91 * 1000, S.DUTY7 .. " spawnAttackWave (attackDelay 90 s)")

	local attackers = newShips(before, agent)
	local allowed = unionOf(S.expected()[S.DUTY7].attackShips)

	lu.assertTrue(#attackers >= 1, S.DUTY7 .. ": an attack wave spawned after 90 s")

	for i, ship in ipairs(attackers) do
		lu.assertTrue(allowed[ship.shipName] == true, S.DUTY7 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4 (c): recovery duty 5
---------------------------------------------------------------------------------------------

TestSmugglerT1RecoveryDuty = {}

function TestSmugglerT1RecoveryDuty:setUp() H.reset() end
function TestSmugglerT1RecoveryDuty:tearDown() teardown() end

-- Core3's recovery types wait arrivalDelay for the arrival message (setupRecover) and again for the ship (spawnRecoveryShip), so the ship comes
-- 2 x 35 s after the start; the table's arrivalDelay is the SWG targetArrivalDelay (35). The window below is that behavior plus a margin.
local ARRIVAL = 35

-- AC-4 (c): nothing before the arrival delay, the Valarian freighter within two arrival delays
function TestSmugglerT1RecoveryDuty:test_the_valarian_mining_freighter_spawns_after_the_35_second_arrival_delay()
	local q = quest(S.DUTY5)

	lu.assertEquals(q.arrivalDelay, ARRIVAL, S.DUTY5 .. ": arrivalDelay is the .tab targetArrivalDelay")
	H.Engine.config.rejectEmptyShipName = true
	q:start()

	local player = newPlayer(q)

	q:startQuest(player, "")
	H.advance(0)
	pump((ARRIVAL - 1) * 1000, S.DUTY5 .. " before the arrival delay")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertNotEquals(ship.shipName, "valarian_freighterlight_mining_tier1", S.DUTY5 .. ": the target spawned before 35 s")
	end

	pump((ARRIVAL + 6) * 1000, S.DUTY5 .. " arrival")

	local found = false

	for _, ship in ipairs(H.spawnedShips()) do
		if ship.shipName == "valarian_freighterlight_mining_tier1" then
			found = true
			lu.assertEquals(ship.missionOwner, player, S.DUTY5 .. ": the target belongs to the pilot")
			lu.assertEquals(ship.zone, "space_tatooine", S.DUTY5 .. ": the target zone")
		end
	end

	lu.assertTrue(found, S.DUTY5 .. ": valarian_freighterlight_mining_tier1 spawned within two arrival delays of the start")
end

-- The recovery run of DR.startRecoveryRun, with the wait of two arrival delays (DR.startRecoveryRun waits arrivalDelay + 20 s, enough for the shorter
-- arrival delays of the other duties but not for 35 s)
local function startRecoveryRun(q, player)
	H.Engine.config.rejectEmptyShipName = true
	q:start()
	q:startQuest(player, "")
	H.advance(0)
	H.advance((2 * q.arrivalDelay + 5) * 1000)

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, q.className .. ": the recovery ship was spawned")

	local areas = H.spawnedAreas()

	return { quest = q, player = player, ship = ship, areas = areas, last = areas[#areas], global = q.className, pid = player.objectID }
end

local function dutyPaid(run, amount, label)
	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 1, label .. ": addBankCredits calls")
	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, amount, label .. ": credits")
	lu.assertEquals(#pay.messages, 1, label .. ": @space/quest:recovery_reward messages")
	lu.assertEquals(pay.messages[1] and pay.messages[1].DI, amount, label .. ": recovery_reward DI")
end

-- AC-4 (c): pays 1000 with no kills
function TestSmugglerT1RecoveryDuty:test_a_capture_without_kills_pays_1000()
	local q = quest(S.DUTY5)
	local run = startRecoveryRun(q, newPlayer(q))

	lu.assertEquals(run.ship.shipName, "valarian_freighterlight_mining_tier1", S.DUTY5 .. ": the captured ship")
	RF.capture(run)
	RF.finish(run)
	dutyPaid(run, 1000, S.DUTY5 .. " no kills")
end

-- AC-4 (c): pays 1000 + 100 per kill of the first wave
function TestSmugglerT1RecoveryDuty:test_a_capture_after_killing_the_first_wave_pays_1000_plus_100_per_kill()
	local q = quest(S.DUTY5)
	local run = startRecoveryRun(q, newPlayer(q))
	local allowed = unionOf(S.expected()[S.DUTY5].attackShips)

	RF.capture(run)

	local wave = RF.wave(run)

	lu.assertEquals(#wave, 2, S.DUTY5 .. ": the first wave is attack list 1 (2 ships)")

	for i, ship in ipairs(wave) do
		lu.assertTrue(allowed[ship.shipName] == true, S.DUTY5 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertTrue(hasValue(ship.factionEnemies, getHashCode("smuggler")), S.DUTY5 .. ": attacker " .. i .. " is hostile to the smuggler faction of the pilot")
	end

	RF.killAll(run, wave)
	RF.finish(run)
	dutyPaid(run, 1000 + 100 * 2, S.DUTY5 .. " two kills")
end

---------------------------------------------------------------------------------------------
-- AC-4 (d): one duty at a time
---------------------------------------------------------------------------------------------

TestSmugglerT1DutyGuard = {}

function TestSmugglerT1DutyGuard:setUp() H.reset() end

-- AC-4 (d)
function TestSmugglerT1DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	local d6, player = started(S.DUTY6)

	lu.assertTrue(isActive(player, d6), S.DUTY6 .. ": precondition: running")

	for _, other in ipairs({ S.DUTY8, S.DUTY7, S.DUTY5 }) do
		local q = quest(other)

		q:start()
		q:startQuest(player, "")
		H.advance(0)

		lu.assertFalse(isActive(player, q), other .. ": refused by the one-duty guard")
	end

	lu.assertTrue(isActive(player, d6), S.DUTY6 .. ": still running")
	lu.assertTrue(#DR.messages(player, DR.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
end
