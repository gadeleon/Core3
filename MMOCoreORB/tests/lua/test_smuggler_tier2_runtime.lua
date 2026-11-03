-- Smuggler tier 2 (Shamdon): the four story missions and the three duties run through the fakes.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-3, AC-4; Data mapping 1; FS-7; R-2).
--
-- The oracle values come from the SWG .tab fixtures (smuggler_tier2_data.lua M.expected, proven equal to the files by test_smuggler_tier2_data.lua); the
-- quest tables are driven through the harness's fakes, never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua
-- error inside an event shows up as "no Lua error" and not as a later, unrelated assertion. R-2 (the real AI's hostility toward `valarian` ships) cannot
-- be checked here; see the in-game checklist of the spec. The pilot is a Smuggler of tier 2: its ship carries the faction `valarian` (C++ resetShipFaction).

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DR = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local M = require("smuggler_tier2_data")

M.load()

local WANT = M.expected()
local VALARIAN = getHashCode("valarian")

local function quest(global) return M.quest(global) end

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

-- A Smuggler of tier 2 in a ship in the quest zone: the ship carries the faction valarian
local function newPlayer(q)
	return M.pilot({ zone = q.questZone, inShip = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = VALARIAN } })
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

local function unionOf(lists)
	local set = {}

	for _, list in ipairs(lists) do
		for _, name in ipairs(list) do
			set[name] = true
		end
	end

	return set
end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

---------------------------------------------------------------------------------------------
-- AC-3: the assassinate missions
---------------------------------------------------------------------------------------------

TestSmugglerT2Assassinate = {}

function TestSmugglerT2Assassinate:setUp() H.reset() end
function TestSmugglerT2Assassinate:tearDown() AC.tearDown() end

-- AC-3: mission 1 spawns the Behemoth with 2 raiders after 24 s at the first point
function TestSmugglerT2Assassinate:test_mission_1_spawns_the_behemoth_and_two_raiders_at_the_first_point_after_24_seconds()
	local q, player = started(M.A1)

	pump(23000, M.A1 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, M.A1 .. ": nothing spawned 23 s after the start (arrivalDelay 24)")
	pump(4000, M.A1 .. " deployTargets")

	local ships = H.spawnedShips()
	local first = WANT[M.A1].targetPatrols[1]

	lu.assertEquals(shipNames(ships), { "corsair_behemoth_tier3", "corsair_raider_tier2", "corsair_raider_tier2" }, M.A1 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, M.A1 .. ": the target leads the squadron")
	lu.assertEquals(ships[2].squadronLeader, ships[1], M.A1 .. ": escort 1 flies in the target's squadron")
	lu.assertEquals(ships[3].squadronLeader, ships[1], M.A1 .. ": escort 2 flies in the target's squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { first.x, first.z, first.y }, M.A1 .. ": the target spawns at targetPatrols[1] (" .. first.patrolPointName .. ")")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, M.A1 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_lok", M.A1 .. ": ship " .. i .. " zone")
	end
end

-- AC-3: mission 1 needs all three destroyed (mustDestroyEscort)
function TestSmugglerT2Assassinate:test_mission_1_needs_the_behemoth_and_both_raiders()
	local q, player = started(M.A1)

	pump(28000, M.A1 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 3, M.A1 .. ": precondition: target and two escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, M.A1 .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), M.A1 .. ": not complete with both escorts alive")
	lu.assertTrue(isActive(player, q), M.A1 .. ": still active")
	H.destroyShip(ships[2], player.rootParent)
	pump(1500, M.A1 .. " escort 1")
	lu.assertFalse(isComplete(player, q), M.A1 .. ": not complete with one escort alive")
	H.destroyShip(ships[3], player.rootParent)
	pump(3000, M.A1 .. " escort 2")
	lu.assertTrue(isComplete(player, q), M.A1 .. ": complete when all three are destroyed")
	lu.assertFalse(isActive(player, q), M.A1 .. ": no longer active")
end

-- AC-3: mission 2 spawns its TIE target and three escorts at once at the first point, and needs all four
function TestSmugglerT2Assassinate:test_mission_2_spawns_the_tie_interceptor_and_three_fighters_at_once_and_needs_all_four()
	local q, player = started(M.A2)

	pump(500, M.A2 .. " deployTargets")

	local ships = H.spawnedShips()
	local first = WANT[M.A2].targetPatrols[1]

	lu.assertEquals(shipNames(ships), { "imp_tie_interceptor_tier3", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2" }, M.A2 .. ": spawned ships, target first")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { first.x, first.z, first.y }, M.A2 .. ": the target spawns at targetPatrols[1] (" .. first.patrolPointName .. ")")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, M.A2 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_dantooine", M.A2 .. ": ship " .. i .. " zone")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(3000, M.A2 .. " target")
	lu.assertFalse(isComplete(player, q), M.A2 .. ": not complete with the escorts alive")

	for i = 2, 4 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, M.A2 .. " escort " .. (i - 1))
	end

	pump(3000, M.A2 .. " completion")
	lu.assertTrue(isComplete(player, q), M.A2 .. ": complete when all four are destroyed")
end

-- AC-3: mission 3 spawns the Black Sun ace with three fighters at once and completes on the ace alone
function TestSmugglerT2Assassinate:test_mission_3_completes_when_only_the_ace_is_destroyed()
	local q, player = started(M.A3)

	pump(500, M.A3 .. " deployTargets")

	local ships = H.spawnedShips()
	local first = WANT[M.A3].targetPatrols[1]

	lu.assertEquals(shipNames(ships), { "blacksun_ace_s04_tier2", "blacksun_fighter_s01_tier2", "blacksun_fighter_s02_tier2", "blacksun_fighter_s03_tier2" }, M.A3 .. ": spawned ships, target first")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, { first.x, first.z, first.y }, M.A3 .. ": the target spawns at targetPatrols[1] (" .. first.patrolPointName .. ")")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, M.A3 .. " after the ace is destroyed")
	lu.assertTrue(isComplete(player, q), M.A3 .. ": complete with the escorts alive (mustDestroyEscort 0)")
	lu.assertFalse(isActive(player, q), M.A3 .. ": no longer active")
end

-- AC-3: mission 3, escorts alone do not complete it
function TestSmugglerT2Assassinate:test_mission_3_is_not_complete_while_the_ace_lives()
	local q, player = started(M.A3)

	pump(500, M.A3 .. " deployTargets")

	local ships = H.spawnedShips()

	for i = 2, 4 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, M.A3 .. " escort " .. (i - 1))
	end

	pump(3000, M.A3 .. " after the escorts")
	lu.assertFalse(isComplete(player, q), M.A3 .. ": not complete while the ace lives")
end

---------------------------------------------------------------------------------------------
-- AC-3: mission 4, the Valarian escort
---------------------------------------------------------------------------------------------

TestSmugglerT2Mission4 = {}

function TestSmugglerT2Mission4:setUp() H.reset() end
function TestSmugglerT2Mission4:tearDown() AC.tearDown() end

-- AC-3: the escort ship is the Valarian light mining freighter, flown for the pilot
function TestSmugglerT2Mission4:test_the_escort_is_the_valarian_mining_freighter_of_tier_3()
	local run = escortRun(M.E4)

	lu.assertNotNil(run.escortAgent, M.E4 .. ": the escort ship spawned")
	lu.assertEquals(run.escortAgent.shipName, "valarian_freighterlight_mining_tier3", M.E4 .. ": the escort ship")
	lu.assertEquals(run.escortAgent.zone, "space_tatooine", M.E4 .. ": zone")
	lu.assertTrue(isActive(run.player, run.q), M.E4 .. ": active")
end

-- AC-3: nothing attacks before the first wave delay (120 s)
function TestSmugglerT2Mission4:test_no_wave_before_120_seconds_and_the_first_wave_comes_after_120_seconds()
	local run = escortRun(M.E4)
	local agent = run.escortAgent

	lu.assertNotNil(agent, M.E4 .. ": the escort ship spawned")
	pump(5000, M.E4 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(90 * 1000, M.E4 .. " before the first wave")
	lu.assertEquals(#newShips(before, agent), 0, M.E4 .. ": no attacker 95 s after the escort set out")
	pump(30 * 1000, M.E4 .. " spawnAttackWave (attackDelay 120 s)")
	lu.assertTrue(#newShips(before, agent) >= 2, M.E4 .. ": an attack wave spawned after 120 s")
end

-- AC-3: the wave is one of the five Hutt lists (each draw picks its list)
function TestSmugglerT2Mission4:test_the_first_wave_is_one_of_the_five_hutt_lists_and_each_list_can_be_drawn()
	local lists = WANT[M.E4].attackShips

	lu.assertEquals(#lists, 5, "attack lists of the fixture")

	for pick = 1, #lists do
		teardown()
		assertDelay(M.E4)

		local run = escortRun(M.E4) -- starts with H.reset(): the draw is fixed afterwards
		local agent = run.escortAgent

		lu.assertNotNil(agent, M.E4 .. ": the escort ship spawned (draw " .. pick .. ")")
		pump(5000, M.E4 .. " assignEscortPoints")
		H.Engine.setRandom(1, #lists, pick)

		local before = #H.spawnedShips()

		pump(121 * 1000, M.E4 .. " spawnAttackWave pick " .. pick)

		local attackers = newShips(before, agent)

		lu.assertEquals(sorted(shipNames(attackers)), sorted(lists[pick]), M.E4 .. ": the wave of draw " .. pick .. " is attack list " .. pick)

		for i, ship in ipairs(attackers) do
			lu.assertTrue(hasValue(ship.factionEnemies, VALARIAN), M.E4 .. ": attacker " .. i .. " of draw " .. pick .. " is hostile to the valarian faction of the tier 2 ship")
			lu.assertTrue(hasValue(ship.removedFactionAllies or {}, VALARIAN), M.E4 .. ": attacker " .. i .. " of draw " .. pick .. " lost its valarian alliance")
			lu.assertFalse(hasValue(ship.factionEnemies, getHashCode("smuggler")), M.E4 .. ": attacker " .. i .. " of draw " .. pick .. " is not told to hate the squadron faction smuggler")
		end
	end
end

-- AC-3: a lost pilot in the wrong zone starts nothing: the mission is in space_tatooine
function TestSmugglerT2Mission4:test_the_mission_is_flown_in_space_tatooine()
	lu.assertEquals(quest(M.E4).questZone, "space_tatooine", "questZone")
end

---------------------------------------------------------------------------------------------
-- AC-4: the destroy duty
---------------------------------------------------------------------------------------------

TestSmugglerT2DestroyDuty = {}

function TestSmugglerT2DestroyDuty:setUp() H.reset() end

local function startedDestroyDuty()
	local q, player = started(M.DUTY_DESTROY)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, M.DUTY_DESTROY .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

-- AC-4: the first wave comes from the duty's own two lists
function TestSmugglerT2DestroyDuty:test_the_first_wave_comes_only_from_the_two_black_sun_lists()
	local q, player, area = startedDestroyDuty()
	local allowed = unionOf(WANT[M.DUTY_DESTROY].shipTypes)

	lu.assertEquals(#WANT[M.DUTY_DESTROY].shipTypes, 2, "ship lists of the fixture")
	H.enterArea(area, player.rootParent)
	pump(4500, M.DUTY_DESTROY .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, M.DUTY_DESTROY .. ": wave 1 spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(allowed[ship.shipName] == true, M.DUTY_DESTROY .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertEquals(ship.missionOwner, player, M.DUTY_DESTROY .. ": ship " .. i .. " belongs to the pilot")
	end
end

-- AC-4: a later wave
function TestSmugglerT2DestroyDuty:test_a_later_wave_spawns_only_ships_of_the_table()
	local q, player, area = startedDestroyDuty()
	local allowed = unionOf(WANT[M.DUTY_DESTROY].shipTypes)

	H.enterArea(area, player.rootParent)
	pump(500, M.DUTY_DESTROY .. " entering")
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	pump(4000, M.DUTY_DESTROY .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, M.DUTY_DESTROY .. ": wave 1 of level 2 has wave + level - 1 = 2 ships")

	for i, ship in ipairs(ships) do
		lu.assertTrue(allowed[ship.shipName] == true, M.DUTY_DESTROY .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end
end

-- AC-4: the boss
function TestSmugglerT2DestroyDuty:test_the_boss_wave_spawns_blacksun_marauder_tier3_first()
	local q, player, area = startedDestroyDuty()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, M.DUTY_DESTROY .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "blacksun_marauder_tier3", M.DUTY_DESTROY .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), M.DUTY_DESTROY .. ": the boss has the boss kill observer")
end

-- AC-4: level 2 boss squad
function TestSmugglerT2DestroyDuty:test_the_level_two_boss_squad_is_the_boss_and_one_ship_of_the_table()
	local q, player, area = startedDestroyDuty()
	local allowed = unionOf(WANT[M.DUTY_DESTROY].shipTypes)

	writeData(dataKey(q, player, "bossLevel:"), 1)
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, M.DUTY_DESTROY .. " spawnAttackWave (level 2 boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, M.DUTY_DESTROY .. ": level 2 boss squad size")
	lu.assertEquals(ships[1].shipName, "blacksun_marauder_tier3", M.DUTY_DESTROY .. ": the boss leads")
	lu.assertTrue(allowed[ships[2].shipName] == true, M.DUTY_DESTROY .. ": the second ship '" .. tostring(ships[2].shipName) .. "' is one of the table's ships")
end

---------------------------------------------------------------------------------------------
-- AC-4: the escort duty
---------------------------------------------------------------------------------------------

TestSmugglerT2EscortDuty = {}

function TestSmugglerT2EscortDuty:setUp() H.reset() end
function TestSmugglerT2EscortDuty:tearDown() AC.tearDown() end

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
	local q, player = started(M.DUTY_ESCORT)
	local agent = spawnShipAgent("valarian_freighterlight_mining_tier2", "space_lok", 0, 0, 0, player.rootParent)
	local area = spawnSpaceActiveArea("space_lok", "object/active_area.iff", 0, 0, 0, 250)
	local prefix = q.className

	writeData(agent.objectID .. ":" .. prefix .. ":escorterID:", player.objectID)
	writeData(player.objectID .. ":" .. prefix .. ":escortID:", agent.objectID)
	writeData(agent.objectID .. ":" .. prefix .. ":escortShipProgress:", 1)

	if kills > 0 then
		writeData(player.objectID .. ":" .. prefix .. ":" .. ":EscortKillCount:", kills)
	end

	return q, player, agent, area
end

-- AC-4: 2500 + 200 per kill, without a Lua error
for kills, want in pairs({ [0] = 2500, [1] = 2700, [2] = 2900, [5] = 3500 }) do
	TestSmugglerT2EscortDuty["test_the_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		assertDelay(M.DUTY_ESCORT)

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, M.DUTY_ESCORT .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, M.DUTY_ESCORT .. ": @space/quest:escort_reward DI (2500 + 200 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, M.DUTY_ESCORT .. ": credits added to the bank")
	end
end

-- AC-4: the escort ship is the Valarian light mining freighter of tier 2
function TestSmugglerT2EscortDuty:test_the_escort_is_the_valarian_mining_freighter_of_tier_2()
	assertDelay(M.DUTY_ESCORT)

	local run = escortRun(M.DUTY_ESCORT)

	lu.assertNotNil(run.escortAgent, M.DUTY_ESCORT .. ": the escort spawned")
	lu.assertEquals(run.escortAgent.shipName, "valarian_freighterlight_mining_tier2", M.DUTY_ESCORT .. ": escort ship")
	lu.assertEquals(run.escortAgent.zone, "space_lok", M.DUTY_ESCORT .. ": zone")
end

-- AC-4: the attack wave after 120 s is a list of the table and hates the ship's faction
function TestSmugglerT2EscortDuty:test_the_attack_wave_after_120_seconds_is_one_of_the_three_corsair_lists()
	local run = escortRun(M.DUTY_ESCORT)
	local agent = run.escortAgent

	lu.assertNotNil(agent, M.DUTY_ESCORT .. ": the escort ship spawned")
	pump(5000, M.DUTY_ESCORT .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, M.DUTY_ESCORT .. " spawnAttackWave (attackDelay 120 s)")

	local attackers = newShips(before, agent)
	local allowed = unionOf(WANT[M.DUTY_ESCORT].attackShips)

	lu.assertTrue(#attackers >= 1, M.DUTY_ESCORT .. ": an attack wave spawned after 120 s")

	for i, ship in ipairs(attackers) do
		lu.assertTrue(allowed[ship.shipName] == true, M.DUTY_ESCORT .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertTrue(hasValue(ship.factionEnemies, VALARIAN), M.DUTY_ESCORT .. ": attacker " .. i .. " is hostile to the valarian faction of the pilot's ship")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the recovery duty
---------------------------------------------------------------------------------------------

TestSmugglerT2RecoveryDuty = {}

function TestSmugglerT2RecoveryDuty:setUp() H.reset() end
function TestSmugglerT2RecoveryDuty:tearDown() teardown() end

-- The recovery run of DR.startRecoveryRun, with the wait of two arrival delays (the ship comes after the arrival message, then after the arrival delay again)
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

-- AC-4: one of the three freighters spawns after the arrival delay of 12 s
function TestSmugglerT2RecoveryDuty:test_a_freighter_spawns_after_the_12_second_arrival_delay()
	local q = quest(M.DUTY_RECOVERY)

	lu.assertEquals(q.arrivalDelay, 12, M.DUTY_RECOVERY .. ": arrivalDelay is the .tab targetArrivalDelay")
	H.Engine.config.rejectEmptyShipName = true
	q:start()

	local player = newPlayer(q)

	q:startQuest(player, "")
	H.advance(0)
	pump((q.arrivalDelay - 1) * 1000, M.DUTY_RECOVERY .. " before the arrival delay")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertNil(ship.shipName:match("^freighter%a+_tier3$"), M.DUTY_RECOVERY .. ": the target spawned before 12 s")
	end

	pump((q.arrivalDelay + 6) * 1000, M.DUTY_RECOVERY .. " arrival")

	local found
	local targets = unionOf({ WANT[M.DUTY_RECOVERY].recoverShips })

	for _, ship in ipairs(H.spawnedShips()) do
		if targets[ship.shipName] then
			found = ship
		end
	end

	lu.assertNotNil(found, M.DUTY_RECOVERY .. ": one of the three freighters spawned within two arrival delays of the start")
	lu.assertEquals(found.missionOwner, player, M.DUTY_RECOVERY .. ": the target belongs to the pilot")
	lu.assertEquals(found.zone, "space_dantooine", M.DUTY_RECOVERY .. ": the target zone")
end

-- AC-4: each of the three freighters can be the target, with four TIE escorts
for pick, name in ipairs({ "freighterheavy_tier3", "freighterlight_tier3", "freightermedium_tier3" }) do
	TestSmugglerT2RecoveryDuty["test_draw_" .. pick .. "_makes_" .. name .. "_the_target_with_four_tie_fighter_escorts"] = function()
		local q = quest(M.DUTY_RECOVERY)

		H.Engine.setRandom(1, 3, pick)

		local run = startRecoveryRun(q, newPlayer(q))
		local escorts = {}

		lu.assertEquals(run.ship.shipName, name, M.DUTY_RECOVERY .. ": the target for draw " .. pick)

		for _, ship in ipairs(H.spawnedShips()) do
			if ship ~= run.ship then
				escorts[#escorts + 1] = ship.shipName
			end
		end

		lu.assertEquals(escorts, { "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2" }, M.DUTY_RECOVERY .. ": the escorts of the target")
	end
end

-- AC-4: pays 2500 with no kills
function TestSmugglerT2RecoveryDuty:test_a_capture_without_kills_pays_2500()
	local q = quest(M.DUTY_RECOVERY)
	local run = startRecoveryRun(q, newPlayer(q))

	RF.capture(run)
	RF.finish(run)
	dutyPaid(run, 2500, M.DUTY_RECOVERY .. " no kills")
end

-- AC-4: pays 2500 + 200 per kill of the first wave (draw 1: four TIE fighters)
function TestSmugglerT2RecoveryDuty:test_a_capture_after_killing_the_first_wave_pays_2500_plus_200_per_kill()
	local q = quest(M.DUTY_RECOVERY)

	H.Engine.setRandom(1, 3, 1)

	local run = startRecoveryRun(q, newPlayer(q))
	local allowed = unionOf(WANT[M.DUTY_RECOVERY].attackShips)

	RF.capture(run)

	local wave = RF.wave(run)

	lu.assertEquals(#wave, 4, M.DUTY_RECOVERY .. ": the first wave is attack list 1 (4 ships)")

	for i, ship in ipairs(wave) do
		lu.assertTrue(allowed[ship.shipName] == true, M.DUTY_RECOVERY .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertTrue(hasValue(ship.factionEnemies, VALARIAN), M.DUTY_RECOVERY .. ": attacker " .. i .. " is hostile to the valarian faction of the pilot's ship")
	end

	RF.killAll(run, wave)
	RF.finish(run)
	dutyPaid(run, 2500 + 200 * 4, M.DUTY_RECOVERY .. " four kills")
end

---------------------------------------------------------------------------------------------
-- AC-4: the one-duty guard
---------------------------------------------------------------------------------------------

TestSmugglerT2DutyGuard = {}

function TestSmugglerT2DutyGuard:setUp() H.reset() end
function TestSmugglerT2DutyGuard:tearDown() teardown() end

-- AC-4: a second duty is refused while one is held (the datapad flag), whatever the pair
function TestSmugglerT2DutyGuard:test_a_second_duty_is_refused_for_every_duty_of_the_tier()
	for _, global in ipairs(M.DUTIES) do
		H.reset()

		local q = quest(global)

		q:start()

		local player = newPlayer(q)

		DR.holdDuty(player, "held_by_test")

		local before = DR.snapshot(player)

		q:startQuest(player, "")
		H.advance(0)
		lu.assertFalse(DR.active(player, q), global .. ": journal entry activated although a duty is held")

		local after = DR.snapshot(player)

		for _, fn in ipairs(DR.SPAWN_CALLS) do
			lu.assertEquals(after[fn], before[fn], global .. ": a refused start makes no " .. fn .. " call")
		end

		lu.assertEquals(after.missions, before.missions, global .. ": datapad missions")
		lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 1, global .. ": the refusal message " .. DR.MSG_DUTY_ALREADY)
	end
end

-- AC-4: after the first duty started, starting another refuses
function TestSmugglerT2DutyGuard:test_starting_the_escort_duty_then_the_destroy_duty_refuses_the_second()
	local first, player = started(M.DUTY_ESCORT)

	lu.assertTrue(DR.active(player, first), M.DUTY_ESCORT .. ": active")

	local second = quest(M.DUTY_DESTROY)

	second:start()
	second:startQuest(player, "")
	H.advance(0)
	lu.assertFalse(DR.active(player, second), M.DUTY_DESTROY .. ": refused while the escort duty is held")
end

---------------------------------------------------------------------------------------------
-- A mission through the trainer: really started by the briefing, then Shamdon is busy, then the reward
---------------------------------------------------------------------------------------------

TestSmugglerT2Chain = {}

function TestSmugglerT2Chain:setUp()
	H.reset()
	M.requireConversation(lu)
	M.useSkillCosts()
end

function TestSmugglerT2Chain:tearDown() AC.tearDown() end

-- AC-3, AC-8, AC-9: weapons training -> mission 3 starts for real -> Shamdon is busy -> the ace dies -> the reward screen pays
function TestSmugglerT2Chain:test_weapons_training_starts_mission_3_for_real_and_the_win_leads_to_its_reward()
	local q = quest(M.A3)

	q:start()

	local player = M.pilot({ zone = q.questZone, inShip = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = VALARIAN }, xp = 60000 })
	local t = M.talk(player, { "s_197f4f94", M.YES })

	lu.assertEquals(M.ids(t), { "training", "trained_weapons", "m3_brief" }, "walk")
	H.advance(0)
	lu.assertTrue(isActive(player, q), M.A3 .. ": active after the briefing")
	lu.assertEquals(M.firstScreen(player), "busy", "Shamdon while the mission runs")
	pump(500, M.A3 .. " deployTargets")

	local ships = H.spawnedShips()

	H.destroyShip(ships[1], player.rootParent)
	pump(3000, M.A3 .. " completion")
	lu.assertTrue(isComplete(player, q), M.A3 .. ": complete")
	lu.assertEquals(M.firstScreen(player), "m3_reward", "Shamdon after the win")
end

-- AC-3, AC-6: a failed assassinate (left unfinished, journal cleared) is offered again as a retry that starts it for real
function TestSmugglerT2Chain:test_a_retry_starts_the_mission_for_real()
	local q = quest(M.A2)

	q:start()

	local player = M.pilot({ zone = q.questZone, inShip = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = VALARIAN }, skills2 = { "droid" }, missions = { [2] = "attempted" } })
	local t = M.talk(player)

	lu.assertEquals(M.ids(t), { "m2_retry" }, "first screen")
	H.advance(0)
	lu.assertTrue(isActive(player, q), M.A2 .. ": active after the retry")
	lu.assertEquals(M.firstScreen(player), "busy", "Shamdon while the retry runs")
end

-- AC-3, AC-6 (R-1): the retry goes through SpaceHelpers:startSpaceQuestChain (it clears the failed run's journal entries
-- first); a bare startQuest on the head would leave a stale entry in place and refuse to start
function TestSmugglerT2Chain:test_a_retry_starts_the_mission_through_the_chain_helper()
	local q = quest(M.A2)

	q:start()

	local player = M.pilot({ zone = q.questZone, inShip = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = VALARIAN }, skills2 = { "droid" }, missions = { [2] = "attempted" } })
	local original = SpaceHelpers.startSpaceQuestChain
	local heads = {}

	SpaceHelpers.startSpaceQuestChain = function(self, pPlayer, pNpc, headGlobal)
		heads[#heads + 1] = headGlobal
		return original(self, pPlayer, pNpc, headGlobal)
	end

	local ok, err = pcall(function()
		local t = M.talk(player)

		lu.assertEquals(M.ids(t), { "m2_retry" }, "first screen")
		H.advance(0)
	end)

	SpaceHelpers.startSpaceQuestChain = original
	assert(ok, err)
	lu.assertEquals(heads, { M.A2 }, "m2_retry: heads started through SpaceHelpers:startSpaceQuestChain")
	lu.assertTrue(isActive(player, q), M.A2 .. ": active after the retry")
end
