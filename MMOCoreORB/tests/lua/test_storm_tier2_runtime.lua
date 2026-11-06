-- Storm Squadron tier 2 (Commander Oberhaur): recovery 2, assassinate 3 and the three duties run through the fakes (inspect 1 is in
-- test_storm_tier2_inspect_shared.lua).
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-3 (b), (c), AC-4; Data mapping 1; R-3).
--
-- The oracle values are the spec's literals (storm_tier2_data.lua, proven equal to the SWG .tab fixtures by test_storm_tier2_data.lua); the quest tables
-- are driven through the harness's fakes, never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. The real AI's hostility between Imperial pilots and the Nym ships (R-3) cannot
-- be checked here; see the in-game checklist of the spec.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local T = require("storm_tier2_data")

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

local function repeated(name, count)
	local out = {}

	for i = 1, count do
		out[i] = name
	end

	return out
end

local function set(list)
	local out = {}

	for _, v in ipairs(list) do
		out[v] = true
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

local function waypointAt(player, name)
	local p = T.POINTS[name]

	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == p[1] and w.z == p[2] and w.y == p[3] then
			return w
		end
	end
end

local function tearDown() AC.tearDown() end

-- Starts a recovery quest and pumps past the arrival delay (Core3 waits it twice), then returns the run RF.capture and RF.pay take
local function recoveryRun(q, player)
	H.Engine.config.rejectEmptyShipName = true
	AC.resolveRecoveryPoints(q)
	q:start()
	q:startQuest(player, "")
	pump(0, q.className .. " start")
	pump((2 * q.arrivalDelay + 5) * 1000, q.className .. " after the arrival delay")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, q.className .. ": the recovery ship was spawned within " .. (2 * q.arrivalDelay + 5) .. " s")

	local areas = H.spawnedAreas()

	return { quest = q, player = player, ship = ship, areas = areas, last = areas[#areas], global = q.className, pid = player.objectID }
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): recovery 2
---------------------------------------------------------------------------------------------

TestStormT2Recovery2 = {}

function TestStormT2Recovery2:setUp() H.reset() end
TestStormT2Recovery2.tearDown = tearDown

-- AC-3 (b)
function TestStormT2Recovery2:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(T.M2)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, T.M2 .. " start")
	pump(14000, T.M2 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, T.M2 .. ": nothing spawned 14 s after the start (arrivalDelay 15)")
	lu.assertTrue(isActive(player, q), T.M2 .. ": active")
end

-- AC-3 (b)
function TestStormT2Recovery2:test_the_prison_ship_and_three_enforcers_spawn_after_the_arrival_delay()
	local q = quest(T.M2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))
	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "nym_prison_ship_tier2", T.M2 .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_lok", T.M2 .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "nym_enforcer_tier2"), 3, T.M2 .. ": nym_enforcer_tier2 escorts among " .. table.concat(names, ", "))
	lu.assertEquals(run.ship.missionOwner, run.player, T.M2 .. ": the prison ship belongs to the pilot")
	lu.assertTrue(isActive(run.player, q), T.M2 .. ": active")
end

-- AC-3 (b): the pilot is sent to the first pre-recovery point
function TestStormT2Recovery2:test_the_pilot_gets_a_waypoint_at_the_first_pre_recovery_point()
	local q = quest(T.M2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	lu.assertNotNil(waypointAt(run.player, "hostage_escort_1"), T.M2 .. ": a waypoint at hostage_escort_1")
end

-- AC-3 (b): a captured prison ship, taken through all five recovery areas, completes the mission
function TestStormT2Recovery2:test_capturing_the_prison_ship_and_bringing_it_through_the_recovery_areas_completes_the_mission()
	local q = quest(T.M2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)
	RF.finish(run)
	pump(3000, T.M2 .. " after the last recovery area")
	lu.assertTrue(isComplete(run.player, q), T.M2 .. ": complete")
	lu.assertFalse(isActive(run.player, q), T.M2 .. ": no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): assassinate 3, started directly (no conversation grants it in this feature)
---------------------------------------------------------------------------------------------

TestStormT2Assassinate3 = {}

function TestStormT2Assassinate3:setUp() H.reset() end
TestStormT2Assassinate3.tearDown = tearDown

-- AC-3 (c)
function TestStormT2Assassinate3:test_the_capo_ship_and_three_escorts_spawn_at_the_first_point_after_30_seconds()
	local q, player = started(T.M3)

	pump(29000, T.M3 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, T.M3 .. ": nothing spawned 29 s after the start (arrivalDelay 30)")
	pump(5000, T.M3 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "nym_capo_ship_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2" }, T.M3 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, T.M3 .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, T.POINTS.hostage_escort_1, T.M3 .. ": the target spawns at targetPatrols[1]")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, T.M3 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_lok", T.M3 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (c): mustDestroyEscort = true
function TestStormT2Assassinate3:test_destroying_only_the_target_does_not_complete_the_quest()
	local q, player = started(T.M3)

	pump(35000, T.M3 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 4, T.M3 .. ": precondition: target and three escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(5000, T.M3 .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), T.M3 .. ": not complete with the escorts alive")
	lu.assertTrue(isActive(player, q), T.M3 .. ": still active")
end

-- AC-3 (c)
function TestStormT2Assassinate3:test_destroying_the_target_and_all_three_escorts_completes_the_quest()
	local q, player = started(T.M3)

	pump(35000, T.M3 .. " deployTargets")

	local ships = H.spawnedShips()

	for i = 1, 4 do
		lu.assertFalse(isComplete(player, q), T.M3 .. ": not complete before kill " .. i)
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, T.M3 .. " after kill " .. i)
	end

	pump(3000, T.M3 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), T.M3 .. ": complete after the target and the escorts")
	lu.assertFalse(isActive(player, q), T.M3 .. ": no longer active")
end

-- AC-3 (c): the escorts first, the target last
function TestStormT2Assassinate3:test_killing_the_escorts_first_and_the_target_last_completes_the_quest()
	local q, player = started(T.M3)

	pump(35000, T.M3 .. " deployTargets")

	local ships = H.spawnedShips()

	for _, i in ipairs({ 2, 3, 4, 1 }) do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, T.M3 .. " after a kill")
	end

	pump(3000, T.M3 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), T.M3 .. ": complete")
end

---------------------------------------------------------------------------------------------
-- AC-4: the destroy duty in Lok
---------------------------------------------------------------------------------------------

TestStormT2DestroyDuty = {}

function TestStormT2DestroyDuty:setUp() H.reset() end
TestStormT2DestroyDuty.tearDown = tearDown

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty(global)
	local q, player = started(global)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

local DESTROY_SHIPS = set({ "nym_fighter_tier2", "nym_enforcer_tier2", "nym_blastboat_tier2" })

-- AC-4: the first wave draws only from the table's ship lists
function TestStormT2DestroyDuty:test_the_first_wave_ships_come_only_from_its_ship_lists()
	local q, player, area = startedDuty(T.DUTY1)

	H.enterArea(area, player.rootParent)
	pump(4500, T.DUTY1 .. " spawnAttackWave (4 s after entering the area)")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, T.DUTY1 .. ": the first wave spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(DESTROY_SHIPS[ship.shipName] == true, T.DUTY1 .. ": wave ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertEquals(ship.missionOwner, player, T.DUTY1 .. ": wave ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_lok", T.DUTY1 .. ": wave ship " .. i .. " zone")
	end
end

-- AC-4: a later wave of each later level
function TestStormT2DestroyDuty:test_a_wave_of_each_level_spawns_only_its_ship_types()
	for level = 0, 4 do
		local q, player, area = startedDuty(T.DUTY1)

		H.enterArea(area, player.rootParent)
		pump(500, T.DUTY1 .. " entering")
		writeData(dataKey(q, player, "CurrentLevel:"), level)
		pump(4000, T.DUTY1 .. " spawnAttackWave")

		local ships = H.spawnedShips()

		lu.assertTrue(#ships >= 1, T.DUTY1 .. ": a wave at level " .. (level + 1))

		for i, ship in ipairs(ships) do
			lu.assertTrue(DESTROY_SHIPS[ship.shipName] == true, T.DUTY1 .. ": level " .. (level + 1) .. " ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end
end

-- AC-4: the boss wave
function TestStormT2DestroyDuty:test_the_boss_wave_spawns_the_boss_ship_first()
	local q, player, area = startedDuty(T.DUTY1)

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, T.DUTY1 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "nym_fighter_tier3", T.DUTY1 .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), T.DUTY1 .. ": the boss has the boss kill observer")

	for i = 2, #ships do
		lu.assertTrue(DESTROY_SHIPS[ships[i].shipName] == true, T.DUTY1 .. ": boss squad ship " .. i .. " '" .. tostring(ships[i].shipName) .. "' is one of the table's ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the recovery duty
---------------------------------------------------------------------------------------------

TestStormT2RecoveryDuty = {}

function TestStormT2RecoveryDuty:setUp() H.reset() end

function TestStormT2RecoveryDuty:tearDown()
	AC.tearDown()
	H.Engine.config.rejectEmptyShipName = nil
end

local FREIGHTERS_RECOVERY = { "nym_freighterheavy_tier2", "nym_freighterlight_tier2", "nym_freightermedium_tier2" }
local RECOVERY_ATTACKERS = set({ "nym_fighter_tier2", "nym_bomber_tier2", "nym_blastboat_tier2" })

local function dutyPaid(run, amount, label)
	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 1, label .. ": addBankCredits calls")
	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, amount, label .. ": credits")
	lu.assertEquals(#pay.messages, 1, label .. ": @space/quest:recovery_reward messages")
	lu.assertEquals(pay.messages[1] and pay.messages[1].DI, amount, label .. ": recovery_reward DI")
end

-- AC-4: nothing spawns before the arrival delay (30 s)
function TestStormT2RecoveryDuty:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(T.DUTY2)

	H.Engine.config.rejectEmptyShipName = true
	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, T.DUTY2 .. " start")
	pump(29000, T.DUTY2 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, T.DUTY2 .. ": nothing spawned 29 s after the start (arrivalDelay 30)")
end

-- AC-4: each of the three freighters can be the target, with three enforcers
for pick, name in ipairs(FREIGHTERS_RECOVERY) do
	TestStormT2RecoveryDuty["test_draw_" .. pick .. "_makes_" .. name .. "_the_target_with_three_enforcers"] = function()
		local q = quest(T.DUTY2)

		H.Engine.setRandom(1, 3, pick)

		local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))
		local escorts = {}

		lu.assertEquals(run.ship.shipName, name, T.DUTY2 .. ": the target for draw " .. pick)
		lu.assertEquals(run.ship.zone, "space_lok", T.DUTY2 .. ": the target zone")
		lu.assertEquals(run.ship.missionOwner, run.player, T.DUTY2 .. ": the target belongs to the pilot")

		for _, ship in ipairs(H.spawnedShips()) do
			if ship ~= run.ship then
				escorts[#escorts + 1] = ship.shipName
			end
		end

		lu.assertEquals(escorts, repeated("nym_enforcer_tier2", 3), T.DUTY2 .. ": the escorts of the target")
		lu.assertNotNil(waypointAt(run.player, "lok_imp_pirate_1"), T.DUTY2 .. ": a waypoint at lok_imp_pirate_1")
	end
end

-- AC-4: pays 2500 with no kills
function TestStormT2RecoveryDuty:test_a_capture_without_kills_pays_2500()
	local q = quest(T.DUTY2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)
	RF.finish(run)
	dutyPaid(run, 2500, T.DUTY2 .. " no kills")
end

-- AC-4: pays 2500 + 200 per kill of the first wave
function TestStormT2RecoveryDuty:test_a_capture_after_killing_the_first_wave_pays_2500_plus_200_per_kill()
	local q = quest(T.DUTY2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)

	local wave = RF.wave(run)

	lu.assertEquals(#wave, 2, T.DUTY2 .. ": the first wave is attack list 1 (2 ships)")

	for i, ship in ipairs(wave) do
		lu.assertTrue(RECOVERY_ATTACKERS[ship.shipName] == true, T.DUTY2 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end

	RF.killAll(run, wave)
	RF.finish(run)
	dutyPaid(run, 2500 + 200 * 2, T.DUTY2 .. " two kills")
end

---------------------------------------------------------------------------------------------
-- AC-4: the escort duty
---------------------------------------------------------------------------------------------

TestStormT2EscortDuty = {}

function TestStormT2EscortDuty:setUp() H.reset() end
TestStormT2EscortDuty.tearDown = tearDown

local FREIGHTERS_ESCORT = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }
local ESCORT_ATTACKERS = set({ "nym_fighter_tier2", "nym_enforcer_tier2" })

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
	local q, player = started(T.DUTY3)
	local agent = spawnShipAgent(FREIGHTERS_ESCORT[1], q.questZone, 0, 0, 0, player.rootParent)
	local area = spawnSpaceActiveArea(q.questZone, "object/active_area.iff", 0, 0, 0, 250)
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
	TestStormT2EscortDuty["test_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		lu.assertTrue((quest(T.DUTY3).attackDelay or 0) > 0, T.DUTY3 .. ": attackDelay must be set")

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, T.DUTY3 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, T.DUTY3 .. ": @space/quest:escort_reward DI (2500 + 200 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, T.DUTY3 .. ": credits added to the bank")
	end
end

-- AC-4: the escort is one of the table's Imperial freighters
function TestStormT2EscortDuty:test_each_of_the_three_freighters_can_be_the_escort()
	for pick, want in ipairs(FREIGHTERS_ESCORT) do
		lu.assertTrue((quest(T.DUTY3).attackDelay or 0) > 0, T.DUTY3 .. ": attackDelay must be set")

		local q, player = started(T.DUTY3)

		H.Engine.queueRandom(1, 3, pick)
		pump(2500, T.DUTY3 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, T.DUTY3 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, T.DUTY3 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, T.DUTY3 .. ": escort ship for draw " .. pick)
		lu.assertEquals(agent.zone, "space_lok", T.DUTY3 .. ": escort zone")
	end
end

-- AC-4: the attack wave after 120 s is one of the table's lists
function TestStormT2EscortDuty:test_the_attack_wave_after_120_seconds_comes_from_its_attack_lists()
	lu.assertTrue((quest(T.DUTY3).attackDelay or 0) > 0, T.DUTY3 .. ": attackDelay must be set")

	local run = AC.escortRun(T.DUTY3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, T.DUTY3 .. ": the escort ship spawned")
	pump(5000, T.DUTY3 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, T.DUTY3 .. " spawnAttackWave (attackDelay 120 s)")

	local n = 0

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= agent then
			n = n + 1
			lu.assertTrue(ESCORT_ATTACKERS[ship.shipName] == true, T.DUTY3 .. ": attacker " .. n .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end

	lu.assertTrue(n >= 1, T.DUTY3 .. ": an attack wave spawned after 120 s")
end

---------------------------------------------------------------------------------------------
-- AC-4: one duty at a time
---------------------------------------------------------------------------------------------

TestStormT2DutyGuard = {}

function TestStormT2DutyGuard:setUp() H.reset() end
TestStormT2DutyGuard.tearDown = tearDown

-- AC-4
function TestStormT2DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	for _, pair in ipairs({ { T.DUTY3, T.DUTY1 }, { T.DUTY1, T.DUTY3 }, { T.DUTY3, T.DUTY2 }, { T.DUTY1, T.DUTY2 } }) do
		local first, player = started(pair[1])
		local second = quest(pair[2])

		lu.assertTrue(isActive(player, first), pair[1] .. ": precondition: running")

		second:start()
		second:startQuest(player, "")
		H.advance(0)

		lu.assertFalse(isActive(player, second), pair[2] .. ": refused by the one-duty guard")
		lu.assertTrue(isActive(player, first), pair[1] .. ": still running")
		lu.assertTrue(#DRS.messages(player, DRS.MSG_DUTY_ALREADY) >= 1, "the pilot was told '@space/quest:duty_already'")
	end
end

-- AC-4: a duty held in the datapad refuses every duty of the tier
function TestStormT2DutyGuard:test_a_duty_held_in_the_datapad_refuses_each_of_the_three_duties()
	for _, global in ipairs(T.DUTIES) do
		H.reset()

		local q = quest(global)

		q:start()

		local player = DRS.player(q, { pilot = "imperial" })

		DRS.holdDuty(player, "held_by_test")
		q:startQuest(player, "")
		H.advance(0)
		lu.assertFalse(isActive(player, q), global .. ": journal entry activated although a duty is held")
	end
end
