-- Black Epsilon tier 1 (Hakassha Sireen): the four story missions and the two duties run through the fakes.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-3, AC-4; Data mapping 1).
--
-- The oracle values are the spec's literals (black_epsilon_tier1_data.lua); the quest tables are driven through the harness's fakes,
-- never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside an event shows up as
-- "no Lua error" and not as a later, unrelated assertion. R-6 (Imperial-vs-Rebel hostility of the real AI) cannot be checked here; see the
-- in-game checklist of the spec.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local B = require("black_epsilon_tier1_data")

B.load()

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

---------------------------------------------------------------------------------------------
-- AC-3 (a): mission 1, the patrol and its surprise attack
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Mission1 = {}

function TestBlackEpsilonT1Mission1:setUp() H.reset() end

function TestBlackEpsilonT1Mission1:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestBlackEpsilonT1Mission1:test_reaching_point_2_and_waiting_10_seconds_spawns_two_reb_xwing_tier1_and_killing_both_completes_both_quests()
	local q, player = started(B.P1)
	local s1 = quest(B.S1)

	lu.assertTrue(isActive(player, q), B.P1 .. ": precondition: active after startQuest")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	pump(500, B.P1 .. " point 1")
	H.enterArea(AC.areaByNumber(q, 2), player.rootParent)
	pump(500, B.P1 .. " point 2")
	lu.assertEquals(#H.spawnedShips(), 0, B.P1 .. ": no attacker before the 10 s split delay")

	pump(9000, B.P1 .. " split delay")
	lu.assertEquals(#H.spawnedShips(), 0, B.P1 .. ": still no attacker 9.5 s after point 2 (sideQuestDelay is 10 s)")

	pump(7000, B.P1 .. " surprise attack start")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "reb_xwing_tier1", "reb_xwing_tier1" }, B.S1 .. ": spawned attackers")
	lu.assertTrue(isActive(player, s1), B.S1 .. ": active once the split started it")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_corellia", B.S1 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, B.S1 .. ": attacker " .. i .. " belongs to the pilot")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(1500, B.S1 .. " after kill 1")
	lu.assertFalse(isComplete(player, s1), B.S1 .. ": not complete after 1 of 2 kills")

	H.destroyShip(ships[2], player.rootParent)
	pump(3000, B.S1 .. " after kill 2")

	lu.assertTrue(isComplete(player, s1), B.S1 .. ": complete after both attackers are destroyed")
	lu.assertTrue(isComplete(player, q), B.P1 .. ": the patrol is complete")
	lu.assertFalse(isActive(player, q), B.P1 .. ": the patrol is no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): mission 2, destroy
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Mission2 = {}

function TestBlackEpsilonT1Mission2:setUp() H.reset() end

-- AC-3 (b)
function TestBlackEpsilonT1Mission2:test_the_pilot_gets_four_waypoints_and_four_cadet_kills_complete_the_quest()
	local q, player = started(B.M2)

	H.zoneSwitch(player, q.questZone)
	pump(500, B.M2 .. " zone entry")
	lu.assertEquals(#player.ghost.waypoints, 4, B.M2 .. ": waypoints handed out (one per spawner)")

	for kill = 1, 4 do
		lu.assertFalse(isComplete(player, q), B.M2 .. ": not complete before kill " .. kill)

		local agent = H.worldAgent({ shipName = "reb_xwing_cadet_tier1", zone = q.questZone })

		H.fireObservers(DESTROYEDSHIP, player, agent)
		pump(1500, B.M2 .. " after kill " .. kill)
	end

	lu.assertTrue(isComplete(player, q), B.M2 .. ": complete after 4 kills of reb_xwing_cadet_tier1")
end

-- AC-3 (b): only the table's ship counts
function TestBlackEpsilonT1Mission2:test_kills_of_other_ships_do_not_count()
	local q, player = started(B.M2)

	H.zoneSwitch(player, q.questZone)

	for _ = 1, 5 do
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "reb_xwing_tier1", zone = q.questZone }))
	end

	pump(1500, B.M2 .. " after five reb_xwing_tier1 kills")
	lu.assertFalse(isComplete(player, q), B.M2 .. ": five kills of a ship the table does not list complete nothing")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): mission 3, escort
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Mission3 = {}

function TestBlackEpsilonT1Mission3:setUp() H.reset() end

function TestBlackEpsilonT1Mission3:tearDown() AC.tearDown() end

-- SpaceEscortScreenplay reschedules its attack wave every attackDelay seconds (default 0): a missing delay is a failure here, not a hang.
local function assertDelay(global)
	lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds, 0 by default)")
end

-- AC-3 (c)
function TestBlackEpsilonT1Mission3:test_the_explosives_freighter_spawns_at_one_of_the_four_escort_points()
	assertDelay(B.E3)

	local run = AC.escortRun(B.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, B.E3 .. ": the escort ship spawned")
	lu.assertEquals(agent.shipName, "imp_freightermedium_explosives_tier1", B.E3 .. ": the escort ship")
	lu.assertEquals(agent.zone, "space_corellia", B.E3 .. ": the escort ship zone")
	lu.assertTrue(isActive(run.player, run.q), B.E3 .. ": active")
end

-- AC-3 (c): the first wave comes from one of the two attack lists after 90 s
function TestBlackEpsilonT1Mission3:test_the_first_attack_wave_after_90_seconds_is_one_of_the_two_corsec_fighter_lists()
	assertDelay(B.E3)

	local run = AC.escortRun(B.E3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, B.E3 .. ": the escort ship spawned")
	pump(5000, B.E3 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(91 * 1000, B.E3 .. " spawnAttackWave (attackDelay 90 s)")

	local attackers = {}

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= agent then
			attackers[#attackers + 1] = ship
		end
	end

	lu.assertTrue(#attackers == 1 or #attackers == 2, B.E3 .. ": the wave is list 1 (2 ships) or list 2 (1 ship), got " .. #attackers)

	for i, ship in ipairs(attackers) do
		lu.assertEquals(ship.shipName, "reb_corsec_fighter_tier1", B.E3 .. ": attacker " .. i)
	end
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): mission 4, assassinate
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Mission4 = {}

function TestBlackEpsilonT1Mission4:setUp() H.reset() end

-- AC-3 (d)
function TestBlackEpsilonT1Mission4:test_the_target_and_one_escort_spawn_at_the_first_point_after_15_seconds()
	local q, player = started(B.A4)

	pump(14000, B.A4 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, B.A4 .. ": nothing spawned 14 s after the start (arrivalDelay 15)")

	pump(3000, B.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "reb_bwing_prototype_tier2", "reb_xwing_tier1" }, B.A4 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, B.A4 .. ": the target leads the squadron")
	lu.assertEquals(ships[2].squadronLeader, ships[1], B.A4 .. ": the escort flies in the target's squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { 3102, 2928, -6841 }, B.A4 .. ": the target spawns at targetPatrols[1] (corellia_imperial_tier2_assassinate_5)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, B.A4 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_corellia", B.A4 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (d): mustDestroyEscort = false
function TestBlackEpsilonT1Mission4:test_destroying_only_the_target_completes_the_quest()
	local q, player = started(B.A4)

	pump(17000, B.A4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, B.A4 .. ": precondition: target and escort")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, B.A4 .. " after the target is destroyed")

	lu.assertTrue(isComplete(player, q), B.A4 .. ": complete with the escort still alive")
	lu.assertFalse(isActive(player, q), B.A4 .. ": no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): destroy duty 6
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1DestroyDuty = {}

function TestBlackEpsilonT1DestroyDuty:setUp() H.reset() end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty6()
	local q, player = started(B.DUTY6)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, B.DUTY6 .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

-- AC-4 (a)
function TestBlackEpsilonT1DestroyDuty:test_the_first_wave_is_one_reb_bwing_tier1()
	local q, player, area = startedDuty6()

	H.enterArea(area, player.rootParent)
	pump(4500, B.DUTY6 .. " spawnAttackWave (4 s after entering the area)")

	lu.assertEquals(shipNames(H.spawnedShips()), { "reb_bwing_tier1" }, B.DUTY6 .. ": ships of wave 1 of level 1")
	lu.assertEquals(H.spawnedShips()[1].missionOwner, player, B.DUTY6 .. ": the wave ship belongs to the pilot")
end

-- AC-4 (a): a bigger wave draws only the table's ship
function TestBlackEpsilonT1DestroyDuty:test_a_later_wave_spawns_only_reb_bwing_tier1()
	local q, player, area = startedDuty6()

	H.enterArea(area, player.rootParent)
	pump(500, B.DUTY6 .. " entering")
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	pump(4000, B.DUTY6 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, B.DUTY6 .. ": wave 1 of level 2 has wave + level - 1 = 2 ships")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.shipName, "reb_bwing_tier1", B.DUTY6 .. ": ship " .. i)
	end
end

-- AC-4 (a): the boss wave
function TestBlackEpsilonT1DestroyDuty:test_the_boss_wave_spawns_the_prototype_first()
	local q, player, area = startedDuty6()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, B.DUTY6 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "reb_bwing_prototype_tier2", B.DUTY6 .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), B.DUTY6 .. ": the boss has the boss kill observer")
end

-- AC-4 (a): level 2 brings the boss and one escort of the table
function TestBlackEpsilonT1DestroyDuty:test_the_level_two_boss_squad_is_the_prototype_and_one_reb_bwing_tier1()
	local q, player, area = startedDuty6()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, B.DUTY6 .. " spawnAttackWave (level 2 boss)")

	lu.assertEquals(shipNames(H.spawnedShips()), { "reb_bwing_prototype_tier2", "reb_bwing_tier1" }, B.DUTY6 .. ": level 2 boss squad")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): escort duty 7
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1EscortDuty = {}

function TestBlackEpsilonT1EscortDuty:setUp() H.reset() end

function TestBlackEpsilonT1EscortDuty:tearDown() AC.tearDown() end

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
	local q, player = started(B.DUTY7)
	local agent = spawnShipAgent("imp_freighterheavy_tier1", "space_corellia", 0, 0, 0, player.rootParent)
	local area = spawnSpaceActiveArea("space_corellia", "object/active_area.iff", 0, 0, 0, 250)
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
	TestBlackEpsilonT1EscortDuty["test_the_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		lu.assertTrue((quest(B.DUTY7).attackDelay or 0) > 0, B.DUTY7 .. ": attackDelay must be set")

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, B.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, B.DUTY7 .. ": @space/quest:escort_reward DI (1000 + 100 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, B.DUTY7 .. ": credits added to the bank")
	end
end

-- AC-4 (b): the escort is one of the three tier 1 freighters
function TestBlackEpsilonT1EscortDuty:test_each_of_the_three_freighters_can_be_the_escort()
	local names = { "imp_freighterheavy_tier1", "imp_freightermedium_tier1", "imp_freighterlight_tier1" }

	for pick, want in ipairs(names) do
		lu.assertTrue((quest(B.DUTY7).attackDelay or 0) > 0, B.DUTY7 .. ": attackDelay must be set")

		local q, player = started(B.DUTY7)

		H.Engine.queueRandom(1, 3, pick)
		pump(2500, B.DUTY7 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, B.DUTY7 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, B.DUTY7 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, B.DUTY7 .. ": escort ship for draw " .. pick)
	end
end

-- AC-4 (b): the attack wave after 120 s is the list of the table
function TestBlackEpsilonT1EscortDuty:test_the_attack_wave_after_120_seconds_is_an_xwing_or_ywing_tier1_list()
	lu.assertTrue((quest(B.DUTY7).attackDelay or 0) > 0, B.DUTY7 .. ": attackDelay must be set")

	local run = AC.escortRun(B.DUTY7)
	local agent = run.escortAgent

	lu.assertNotNil(agent, B.DUTY7 .. ": the escort ship spawned")
	pump(5000, B.DUTY7 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, B.DUTY7 .. " spawnAttackWave (attackDelay 120 s)")

	local allowed = { reb_xwing_tier1 = true, reb_ywing_tier1 = true }
	local n = 0

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= agent then
			n = n + 1
			lu.assertTrue(allowed[ship.shipName] == true, B.DUTY7 .. ": attacker " .. n .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end

	lu.assertTrue(n >= 1, B.DUTY7 .. ": an attack wave spawned after 120 s")
end

---------------------------------------------------------------------------------------------
-- AC-4 (c): one duty at a time
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1DutyGuard = {}

function TestBlackEpsilonT1DutyGuard:setUp() H.reset() end

-- AC-4 (c)
function TestBlackEpsilonT1DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	local d6, player = started(B.DUTY6)
	local d7 = quest(B.DUTY7)

	lu.assertTrue(isActive(player, d6), B.DUTY6 .. ": precondition: running")

	d7:start()
	d7:startQuest(player, "")
	H.advance(0)

	lu.assertFalse(isActive(player, d7), B.DUTY7 .. ": refused by the one-duty guard")
	lu.assertTrue(isActive(player, d6), B.DUTY6 .. ": still running")
	lu.assertTrue(#DRS.messages(player, DRS.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
end
