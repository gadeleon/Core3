-- Storm Squadron tier 1 (Lt. Akal Colzet): the four story missions and the two duties run through the fakes.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-3, AC-4; Data mapping 1; D-7).
--
-- The oracle values are the spec's literals (storm_tier1_data.lua, proven equal to the SWG .tab fixtures by test_storm_tier1_data.lua);
-- the quest tables are driven through the harness's fakes, never read for expected values. Each scenario pumps the event clock inside pcall first,
-- so a Lua error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. The real AI's hostility between Imperial
-- pilots and the Bestine pirates cannot be checked here; see the in-game checklist of the spec.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local I = require("storm_tier1_data")

I.load()

local function quest(global) return I.quest(global) end

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

-- An Imperial pilot in a ship in the quest zone who starts `global` (the quest's own startQuest, as a trainer does)
local function started(global)
	local q = quest(global)

	H.reset()
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	H.advance(0)

	return q, player
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

local function unionOf(lists)
	local set = {}

	for _, list in ipairs(lists) do
		for _, name in ipairs(list) do
			set[name] = true
		end
	end

	return set
end

-- SpaceEscortScreenplay reschedules its attack wave every attackDelay seconds (default 0): a missing delay is a failure here, not a hang.
local function assertDelay(global)
	lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds, 0 by default)")
end

-- The escort run of AC.escortRun: setupEscort (2 s), the start area, the escort ship (5-11 s)
local function escortRun(global)
	assertDelay(global)

	local q, player = started(global)

	H.advance(2500)

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	H.advance(6000)

	return { q = q, player = player, escortAgent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:")) }
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): mission 1, the patrol and its surprise attack
---------------------------------------------------------------------------------------------

TestStormT1Mission1 = {}

function TestStormT1Mission1:setUp() H.reset() end

function TestStormT1Mission1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestStormT1Mission1:test_reaching_point_2_and_waiting_10_seconds_spawns_three_bestine_pirates_and_killing_all_three_completes_both_quests()
	local q, player = started(I.P1)
	local s1 = quest(I.S1)

	lu.assertTrue(isActive(player, q), I.P1 .. ": precondition: active after startQuest")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, I.P1 .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, I.P1 .. " point 2")
	lu.assertEquals(#H.spawnedShips(), 0, I.P1 .. ": no attacker before the 10 s split delay")

	pump(9000, I.P1 .. " split delay")
	lu.assertEquals(#H.spawnedShips(), 0, I.P1 .. ": still no attacker 9.5 s after point 2 (sideQuestDelay is 10 s)")

	pump(7000, I.P1 .. " surprise attack start")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "bestine_pirate_tier1", "bestine_pirate_tier1", "bestine_pirate_tier1" }, I.S1 .. ": spawned attackers")
	lu.assertTrue(isActive(player, s1), I.S1 .. ": active once the split started it")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_tatooine", I.S1 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, I.S1 .. ": attacker " .. i .. " belongs to the pilot")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(1500, I.S1 .. " after kill 1")
	lu.assertFalse(isComplete(player, s1), I.S1 .. ": not complete after 1 of 3 kills")

	H.destroyShip(ships[2], player.rootParent)
	pump(1500, I.S1 .. " after kill 2")
	lu.assertFalse(isComplete(player, s1), I.S1 .. ": not complete after 2 of 3 kills")

	H.destroyShip(ships[3], player.rootParent)
	pump(3000, I.S1 .. " after kill 3")

	lu.assertTrue(isComplete(player, s1), I.S1 .. ": complete after all three attackers are destroyed")
	lu.assertTrue(isComplete(player, q), I.P1 .. ": the patrol is complete")
	lu.assertFalse(isActive(player, q), I.P1 .. ": the patrol is no longer active")
end

-- AC-3 (a): no surprise attack before point 2
function TestStormT1Mission1:test_no_surprise_attack_before_point_2()
	local q, player = started(I.P1)

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(30000, I.P1 .. " point 1 only")
	lu.assertEquals(#H.spawnedShips(), 0, I.P1 .. ": no attacker when point 2 was never reached")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): mission 2, destroy
---------------------------------------------------------------------------------------------

TestStormT1Mission2 = {}

function TestStormT1Mission2:setUp() H.reset() end

-- AC-3 (b)
function TestStormT1Mission2:test_the_pilot_gets_four_waypoints_and_four_pirate_kills_complete_the_quest()
	local q, player = started(I.M2)

	H.zoneSwitch(player, q.questZone)
	pump(500, I.M2 .. " zone entry")
	lu.assertEquals(#player.ghost.waypoints, 4, I.M2 .. ": waypoints handed out (one per spawner)")

	for kill = 1, 4 do
		lu.assertFalse(isComplete(player, q), I.M2 .. ": not complete before kill " .. kill)

		local agent = H.worldAgent({ shipName = "bestine_pirate_tier1", zone = q.questZone })

		H.fireObservers(DESTROYEDSHIP, player, agent)
		pump(1500, I.M2 .. " after kill " .. kill)
	end

	lu.assertTrue(isComplete(player, q), I.M2 .. ": complete after 4 kills of bestine_pirate_tier1")
end

-- AC-3 (b): only the table's ship counts
function TestStormT1Mission2:test_kills_of_other_ships_do_not_count()
	local q, player = started(I.M2)

	H.zoneSwitch(player, q.questZone)

	for _ = 1, 5 do
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "reb_xwing_tier1", zone = q.questZone }))
	end

	pump(1500, I.M2 .. " after five reb_xwing_tier1 kills")
	lu.assertFalse(isComplete(player, q), I.M2 .. ": five kills of a ship the table does not list complete nothing")
end

-- AC-3 (b): three kills leave the quest running
function TestStormT1Mission2:test_three_kills_leave_the_quest_running()
	local q, player = started(I.M2)

	H.zoneSwitch(player, q.questZone)
	pump(500, I.M2 .. " zone entry")

	for _ = 1, 3 do
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "bestine_pirate_tier1", zone = q.questZone }))
	end

	pump(1500, I.M2 .. " after three kills")
	lu.assertTrue(isActive(player, q), I.M2 .. ": still running after three kills")
	lu.assertFalse(isComplete(player, q), I.M2 .. ": not complete after three of four kills")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): mission 3, patrol then escort
---------------------------------------------------------------------------------------------

TestStormT1Mission3 = {}

function TestStormT1Mission3:setUp() H.reset() end

function TestStormT1Mission3:tearDown() AC.tearDown() end

-- AC-3 (c): the split starts the escort after point 3 and 20 s
function TestStormT1Mission3:test_reaching_point_3_of_the_patrol_starts_escort_3_after_20_seconds()
	local q, player = started(I.P3)
	local e3 = quest(I.E3)

	e3:start()

	for point = 1, 2 do
		H.enterArea(AC.areaByNumber(q, point), player.rootParent)
		pump(500, I.P3 .. " point " .. point)
	end

	pump(30000, I.P3 .. " 30 s after point 2")
	lu.assertFalse(isActive(player, e3), I.E3 .. ": not started by point 2 (sideQuestPatrolStart is 3)")

	H.enterArea(AC.areaByNumber(q, 3), player.rootParent)
	pump(500, I.P3 .. " point 3")
	pump(18500, I.P3 .. " 19 s after point 3")
	lu.assertFalse(isActive(player, e3), I.E3 .. ": not started 19 s after point 3 (sideQuestDelay is 20 s)")
	pump(8000, I.P3 .. " split")
	lu.assertTrue(isActive(player, e3), I.E3 .. ": started by the split")
end

-- AC-3 (c)
function TestStormT1Mission3:test_the_heavy_freighter_spawns_at_one_of_the_five_escort_points()
	local run = escortRun(I.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, I.E3 .. ": the escort ship spawned")
	lu.assertEquals(agent.shipName, "imp_freighterheavy_tatooine_tier1", I.E3 .. ": the escort ship")
	lu.assertEquals(agent.zone, "space_tatooine", I.E3 .. ": the escort ship zone")
	lu.assertTrue(isActive(run.player, run.q), I.E3 .. ": active")
end

-- AC-3 (c): the first wave comes from one of the two attack lists after 90 s
function TestStormT1Mission3:test_the_first_attack_wave_after_90_seconds_is_one_of_the_two_pirate_lists()
	local run = escortRun(I.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, I.E3 .. ": the escort ship spawned")
	pump(5000, I.E3 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(91 * 1000, I.E3 .. " spawnAttackWave (attackDelay 90 s)")

	local names = sorted(shipNames(newShips(before, agent)))
	local joined = table.concat(names, ",")

	lu.assertTrue(joined == "bestine_pirate_tier1,bestine_pirate_tier1" or joined == "bestine_pirate_leader_tier1", I.E3 .. ": the wave is list 1 (two pirates) or list 2 (the pirate leader), got " .. joined)
end

-- AC-3 (c): both lists can be drawn (the random pick is the fake's)
function TestStormT1Mission3:test_the_random_pick_can_draw_either_list()
	local seen = {}

	for _, pick in ipairs({ 1, 2 }) do
		AC.tearDown()

		local run = escortRun(I.E3)

		lu.assertNotNil(run.escortAgent, I.E3 .. ": the escort ship spawned")
		pump(5000, I.E3 .. " assignEscortPoints")
		H.Engine.nextRandom = pick

		local before = #H.spawnedShips()

		pump(91 * 1000, I.E3 .. " spawnAttackWave pick " .. pick)
		seen[#seen + 1] = #newShips(before, run.escortAgent)
	end

	lu.assertEquals(seen, { 2, 1 }, "attackers of draw 1 (list 1: two ships) and draw 2 (list 2: one ship)")
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): mission 4, assassinate
---------------------------------------------------------------------------------------------

TestStormT1Mission4 = {}

function TestStormT1Mission4:setUp() H.reset() end

-- AC-3 (d)
function TestStormT1Mission4:test_the_pirate_leader_and_one_pirate_spawn_at_the_first_point_after_15_seconds()
	local q, player = started(I.A4)

	pump(14000, I.A4 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, I.A4 .. ": nothing spawned 14 s after the start (arrivalDelay 15)")

	pump(3000, I.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "bestine_pirate_leader_tier1", "bestine_pirate_tier1" }, I.A4 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, I.A4 .. ": the target leads the squadron")
	lu.assertEquals(ships[2].squadronLeader, ships[1], I.A4 .. ": the escort flies in the target's squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { -1994, -5029, 4770 }, I.A4 .. ": the target spawns at targetPatrols[1] (corellia_imperial_tier3_leg_4_assasinate_two_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, I.A4 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_tatooine", I.A4 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (d): mustDestroyEscort = false
function TestStormT1Mission4:test_destroying_only_the_target_completes_the_quest()
	local q, player = started(I.A4)

	pump(17000, I.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, I.A4 .. ": precondition: target and escort")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, I.A4 .. " after the target is destroyed")

	lu.assertTrue(isComplete(player, q), I.A4 .. ": complete with the escort still alive")
	lu.assertFalse(isActive(player, q), I.A4 .. ": no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): destroy duty 6
---------------------------------------------------------------------------------------------

TestStormT1DestroyDuty = {}

function TestStormT1DestroyDuty:setUp() H.reset() end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty6()
	local q, player = started(I.DUTY6)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, I.DUTY6 .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

-- AC-4 (a)
function TestStormT1DestroyDuty:test_the_first_wave_comes_only_from_the_pirate_ship_list()
	local q, player, area = startedDuty6()
	local allowed = unionOf(I.expected()[I.DUTY6].shipTypes)

	H.enterArea(area, player.rootParent)
	pump(4500, I.DUTY6 .. " spawnAttackWave (4 s after entering the area)")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, I.DUTY6 .. ": wave 1 spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(allowed[ship.shipName] == true, I.DUTY6 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertEquals(ship.missionOwner, player, I.DUTY6 .. ": the wave ship belongs to the pilot")
	end
end

-- AC-4 (a): a bigger wave draws only the table's ships
function TestStormT1DestroyDuty:test_a_later_wave_spawns_only_ships_of_the_table()
	local q, player, area = startedDuty6()
	local allowed = unionOf(I.expected()[I.DUTY6].shipTypes)

	H.enterArea(area, player.rootParent)
	pump(500, I.DUTY6 .. " entering")
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	pump(4000, I.DUTY6 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, I.DUTY6 .. ": wave 1 of level 2 has wave + level - 1 = 2 ships")

	for i, ship in ipairs(ships) do
		lu.assertTrue(allowed[ship.shipName] == true, I.DUTY6 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

-- AC-4 (a): the boss wave
function TestStormT1DestroyDuty:test_the_boss_wave_spawns_the_pirate_leader_first()
	local q, player, area = startedDuty6()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, I.DUTY6 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "bestine_pirate_leader_tier1", I.DUTY6 .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), I.DUTY6 .. ": the boss has the boss kill observer")
end

-- AC-4 (a): level 2 brings the boss and one escort of the table
function TestStormT1DestroyDuty:test_the_level_two_boss_squad_is_the_boss_and_one_ship_of_the_table()
	local q, player, area = startedDuty6()
	local allowed = unionOf(I.expected()[I.DUTY6].shipTypes)

	writeData(dataKey(q, player, "bossLevel:"), 1)
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, I.DUTY6 .. " spawnAttackWave (level 2 boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, I.DUTY6 .. ": level 2 boss squad size")
	lu.assertEquals(ships[1].shipName, "bestine_pirate_leader_tier1", I.DUTY6 .. ": the boss leads")
	lu.assertTrue(allowed[ships[2].shipName] == true, I.DUTY6 .. ": the second ship '" .. tostring(ships[2].shipName) .. "' is one of the table's ships")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): escort duty 7
---------------------------------------------------------------------------------------------

TestStormT1EscortDuty = {}

function TestStormT1EscortDuty:setUp() H.reset() end

function TestStormT1EscortDuty:tearDown() AC.tearDown() end

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
	local q, player = started(I.DUTY7)
	local agent = spawnShipAgent("imp_freighterheavy_tier1", "space_tatooine", 0, 0, 0, player.rootParent)
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
	TestStormT1EscortDuty["test_the_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		assertDelay(I.DUTY7)

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, I.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, I.DUTY7 .. ": @space/quest:escort_reward DI (1000 + 100 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, I.DUTY7 .. ": credits added to the bank")
	end
end

-- AC-4 (b): the escort is one of the six freighters, in the table's order
function TestStormT1EscortDuty:test_each_of_the_six_freighters_can_be_the_escort()
	local names = I.expected()[I.DUTY7].escortShips

	for pick, want in ipairs(names) do
		assertDelay(I.DUTY7)

		local q, player = started(I.DUTY7)

		H.Engine.queueRandom(1, #names, pick)
		pump(2500, I.DUTY7 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, I.DUTY7 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, I.DUTY7 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, I.DUTY7 .. ": escort ship for draw " .. pick)
	end
end

-- AC-4 (b): the attack wave after 100 s is a list of the table
function TestStormT1EscortDuty:test_the_attack_wave_after_100_seconds_is_one_of_the_two_lists()
	local run = escortRun(I.DUTY7)
	local agent = run.escortAgent

	lu.assertNotNil(agent, I.DUTY7 .. ": the escort ship spawned")
	pump(5000, I.DUTY7 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(80 * 1000, I.DUTY7 .. " 80 s later")
	lu.assertEquals(#newShips(before, agent), 0, I.DUTY7 .. ": no attack wave well before the 100 s attackDelay")
	pump(20 * 1000, I.DUTY7 .. " spawnAttackWave (attackDelay 100 s)")

	local attackers = newShips(before, agent)
	local allowed = unionOf(I.expected()[I.DUTY7].attackShips)

	lu.assertTrue(#attackers >= 1, I.DUTY7 .. ": an attack wave spawned after 100 s")

	for i, ship in ipairs(attackers) do
		lu.assertTrue(allowed[ship.shipName] == true, I.DUTY7 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4 (c): one duty at a time
---------------------------------------------------------------------------------------------

TestStormT1DutyGuard = {}

function TestStormT1DutyGuard:setUp() H.reset() end

-- AC-4 (c)
function TestStormT1DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	local d6, player = started(I.DUTY6)
	local d7 = quest(I.DUTY7)

	lu.assertTrue(isActive(player, d6), I.DUTY6 .. ": precondition: running")

	d7:start()
	d7:startQuest(player, "")
	H.advance(0)

	lu.assertFalse(isActive(player, d7), I.DUTY7 .. ": refused by the one-duty guard")
	lu.assertTrue(isActive(player, d6), I.DUTY6 .. ": still running")
	lu.assertTrue(#DRS.messages(player, DRS.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
end
