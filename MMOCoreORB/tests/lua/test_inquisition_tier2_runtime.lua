-- Inquisition tier 2 (Inquisitor Fa'Zoll): the four story missions and the three duties run through the fakes.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-3, AC-4; Data mapping 1; FI-1; R-3).
--
-- The oracle values are the spec's literals (inquisition_tier2_data.lua) and the SWG fixtures; the quest tables are driven through the harness's
-- fakes, never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside an event shows up as
-- "no Lua error" and not as a later, unrelated assertion. The cargo of the inspect ship is read from the REAL ship template file
-- (ship_mobile/ships/mercenary_courier_tier2.lua), not set on the fake ship. The Imperial-vs-Rebel hostility of the real AI cannot be checked
-- here; see the in-game checklist of the spec.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local S = require("survival_scenario")
local I = require("inquisition_tier2_data")

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

local function waypointAt(player, x, z, y)
	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == x and w.z == z and w.y == y then
			return w
		end
	end
end

local function xyz(zone, name)
	local p = I.POINTS[zone][name]

	return p[1], p[2], p[3]
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): inspect 1
---------------------------------------------------------------------------------------------

TestInquisitionT2Inspect1 = {}

function TestInquisitionT2Inspect1:setUp() H.reset() end

-- the cargo the server's ship template gives the courier (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FI-1)")

	return t.cargoString
end

local SPAWNER = "naboo_imperial_tier2_inspect1_spawner"

local function courier(cargo)
	return H.worldAgent({ shipName = "mercenary_courier_tier2", cargo = cargo, spawner = SPAWNER, zone = "space_naboo" })
end

-- AC-3 (a)
function TestInquisitionT2Inspect1:test_the_pilot_gets_one_waypoint_at_the_inspect_spawner()
	local q, player = started(I.M1)

	lu.assertEquals(#player.ghost.waypoints, 0, I.M1 .. ": no waypoint at the start")
	pump(2500, I.M1 .. " setupInspection and the notice")
	lu.assertEquals(#player.ghost.waypoints, 1, I.M1 .. ": waypoints handed out (one valid spawner)")

	local w = player.ghost.waypoints[1]
	local s = I.SPAWNERS.space_naboo[SPAWNER]

	lu.assertEquals(w.planet, "space_naboo", I.M1 .. ": waypoint planet")
	lu.assertEquals({ w.x, w.z, w.y }, s, I.M1 .. ": waypoint x z y (" .. SPAWNER .. ")")
	lu.assertTrue(isActive(player, q), I.M1 .. ": active")
end

-- AC-3 (a), FI-1: inspecting a courier with the template's cargo completes the quest on dock
function TestInquisitionT2Inspect1:test_inspecting_a_courier_with_its_templates_cargo_completes_the_quest_on_dock()
	local q, player = started(I.M1)

	pump(2500, I.M1 .. " setup")

	local cargo = templateCargo("mercenary_courier_tier2")

	lu.assertEquals(cargo, q.cargo, "the template's cargoString equals the quest cargo")

	local target = courier(cargo)
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, I.M1 .. " inspect")
	H.dock(player, target, hash)
	pump(0, I.M1 .. " dock")
	pump(3000, I.M1 .. " after the dock")
	lu.assertTrue(isComplete(player, q), I.M1 .. ": complete after docking with the courier")
	lu.assertFalse(isActive(player, q), I.M1 .. ": no longer active")
end

-- AC-3 (a): another cargo does not complete it
function TestInquisitionT2Inspect1:test_a_courier_with_another_cargo_does_not_complete_the_quest()
	local q, player = started(I.M1)

	pump(2500, I.M1 .. " setup")

	local target = courier("kill_orders")
	local hash = getHashCode("kill_orders")

	H.inspect(player, target, hash)
	pump(0, I.M1 .. " inspect")
	H.dock(player, target, hash)
	pump(3000, I.M1 .. " dock")
	lu.assertFalse(isComplete(player, q), I.M1 .. ": not complete with the wrong cargo")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): survival 2 in Dantooine
---------------------------------------------------------------------------------------------

TestInquisitionT2Survival2 = {}

function TestInquisitionT2Survival2:setUp() H.reset() end

local function secs(n) return n * 1000 end

local function survival()
	H.reset()

	return S.new("naboo_imperial_tier2_2"):start():arrive()
end

-- AC-3 (b)
function TestInquisitionT2Survival2:test_the_transmission_starts_60_seconds_after_the_ship_reaches_the_point()
	local sc = survival()

	lu.assertEquals(sc.o.zone, "space_dantooine", "the survival is flown in Dantooine")
	sc:at(secs(60) - 1)
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 0, "nothing at 59.999 s")
	sc:at(secs(60))
	lu.assertEquals(S.count(sc:events(), "transmission_start", "message"), 1, "transmission_start at 60 s")
	lu.assertTrue(sc:active(), "active")
end

-- AC-3 (b): the first wave is attackShipLists[1], launched 5 s after the first-attack announcement at 10 s
function TestInquisitionT2Survival2:test_the_first_wave_is_three_xwings_launched_15_seconds_after_arrival()
	local sc = survival()

	sc:at(secs(15) - 1)
	lu.assertEquals(#S.spawns(), 0, "no ship before the launch")
	sc:at(secs(15))

	local waves = S.waves()

	lu.assertEquals(#waves, 1, "waves launched")
	lu.assertEquals(S.names(waves[1]), repeated("reb_xwing_tier2", 3), "the first wave is the first attack list")
	lu.assertEquals(waves[1].spawns[1].zone, "space_dantooine", "the wave spawns in the pilot's zone")
end

-- AC-3 (b): completing the transmission completes the quest at 365 s (60 + 10 x 30 + 5)
function TestInquisitionT2Survival2:test_the_quest_completes_after_the_transmission_and_gives_no_follow_up()
	local sc = survival()

	sc:at(secs(364))
	lu.assertTrue(sc:active(), "still active at 364 s")
	lu.assertFalse(sc:complete(), "not complete at 364 s")
	sc:at(secs(365))
	H.advance(secs(10))
	lu.assertTrue(sc:complete(), "complete after the transmission")
	lu.assertFalse(sc:active(), "no longer active")
	lu.assertEquals(S.called(sc.spies.start), {}, "no follow-up quest")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): recovery 3
---------------------------------------------------------------------------------------------

TestInquisitionT2Recovery3 = {}

function TestInquisitionT2Recovery3:setUp() H.reset() end

function TestInquisitionT2Recovery3:tearDown() AC.tearDown() end

-- AC-3 (c)
function TestInquisitionT2Recovery3:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(I.M3)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, I.M3 .. " start")
	pump(24000, I.M3 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, I.M3 .. ": nothing spawned 24 s after the start (arrivalDelay 25)")
	lu.assertTrue(isActive(player, q), I.M3 .. ": active")
end

-- Starts the recovery and pumps well past the arrival delay (Core3 waits the delay twice: Kaydine F3), then returns the run
local function recoveryRun3()
	local q = quest(I.M3)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, I.M3 .. " start")
	pump(60000, I.M3 .. " after the arrival delay")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))

	lu.assertNotNil(ship, I.M3 .. ": the recovery ship was spawned within 60 s (arrivalDelay 25)")

	return { quest = q, player = player, ship = ship }
end

-- AC-3 (c)
function TestInquisitionT2Recovery3:test_colonel_hends_shuttle_and_four_z95s_spawn_after_the_arrival_delay()
	local run = recoveryRun3()

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "colonel_hend_shuttle_tier3", I.M3 .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_naboo", I.M3 .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "reb_z95_tier2"), 4, I.M3 .. ": reb_z95_tier2 escorts among " .. table.concat(names, ", "))
	lu.assertTrue(isActive(run.player, run.quest), I.M3 .. ": active")
end

-- AC-3 (c): the pilot is sent to the first pre-recovery point
function TestInquisitionT2Recovery3:test_the_pilot_gets_a_waypoint_at_the_first_pre_recovery_point()
	local run = recoveryRun3()
	lu.assertNotNil(waypointAt(run.player, xyz("space_naboo", "naboo_imperial_tier2_recovery1_1")), I.M3 .. ": a waypoint at naboo_imperial_tier2_recovery1_1")
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): assassinate 4 in Dantooine
---------------------------------------------------------------------------------------------

TestInquisitionT2Assassinate4 = {}

function TestInquisitionT2Assassinate4:setUp() H.reset() end

-- AC-3 (d)
function TestInquisitionT2Assassinate4:test_the_shuttle_and_its_four_escorts_spawn_at_the_first_point_after_45_seconds()
	local q, player = started(I.M4)

	pump(44000, I.M4 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, I.M4 .. ": nothing spawned 44 s after the start (arrivalDelay 45)")
	pump(4000, I.M4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "colonel_hend_shuttle_tier3", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" }, I.M4 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, I.M4 .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, I.POINTS.space_dantooine.naboo_imperial_tier2_assassinate1_1, I.M4 .. ": the target spawns at targetPatrols[1]")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, I.M4 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_dantooine", I.M4 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (d): mustDestroyEscort = true
function TestInquisitionT2Assassinate4:test_destroying_only_the_target_does_not_complete_the_quest()
	local q, player = started(I.M4)

	pump(49000, I.M4 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 5, I.M4 .. ": precondition: target and four escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(5000, I.M4 .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), I.M4 .. ": not complete with the escorts alive")
	lu.assertTrue(isActive(player, q), I.M4 .. ": still active")
end

-- AC-3 (d)
function TestInquisitionT2Assassinate4:test_destroying_the_target_and_all_four_escorts_completes_the_quest()
	local q, player = started(I.M4)

	pump(49000, I.M4 .. " deployTargets")

	local ships = H.spawnedShips()

	for i = 1, 5 do
		lu.assertFalse(isComplete(player, q), I.M4 .. ": not complete before kill " .. i)
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, I.M4 .. " after kill " .. i)
	end

	pump(3000, I.M4 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), I.M4 .. ": complete after the target and the escorts")
	lu.assertFalse(isActive(player, q), I.M4 .. ": no longer active")
end

-- AC-3 (d): the escorts first, the target last
function TestInquisitionT2Assassinate4:test_killing_the_escorts_first_and_the_target_last_completes_the_quest()
	local q, player = started(I.M4)

	pump(49000, I.M4 .. " deployTargets")

	local ships = H.spawnedShips()

	for _, i in ipairs({ 2, 3, 4, 5, 1 }) do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, I.M4 .. " after a kill")
	end

	pump(3000, I.M4 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), I.M4 .. ": complete")
end

---------------------------------------------------------------------------------------------
-- AC-4: the recovery duty
---------------------------------------------------------------------------------------------

TestInquisitionT2RecoveryDuty = {}

function TestInquisitionT2RecoveryDuty:setUp() H.reset() end

function TestInquisitionT2RecoveryDuty:tearDown() AC.tearDown() end

-- AC-4
function TestInquisitionT2RecoveryDuty:test_the_miner_transport_and_three_miner_fighters_spawn_and_the_pilot_gets_the_first_waypoint()
	local q = quest(I.DUTY1)
	local run = DRS.startRecoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	pump(10000, I.DUTY1 .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "naboo_miner_transport_tier2", I.DUTY1 .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_naboo", I.DUTY1 .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "naboo_miner_fighter_tier2"), 3, I.DUTY1 .. ": naboo_miner_fighter_tier2 escorts among " .. table.concat(names, ", "))
	lu.assertNotNil(waypointAt(run.player, xyz("space_naboo", "naboo_imperial_tier2_recoveryduty_1")), I.DUTY1 .. ": a waypoint at naboo_imperial_tier2_recoveryduty_1")
	lu.assertTrue(isActive(run.player, q), I.DUTY1 .. ": active")
end

-- AC-4: nothing spawns before the arrival delay (20 s)
function TestInquisitionT2RecoveryDuty:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(I.DUTY1)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, I.DUTY1 .. " start")
	pump(19000, I.DUTY1 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, I.DUTY1 .. ": nothing spawned 19 s after the start (arrivalDelay 20)")
end

---------------------------------------------------------------------------------------------
-- AC-4: the destroy duty in Dantooine
---------------------------------------------------------------------------------------------

TestInquisitionT2DestroyDuty = {}

function TestInquisitionT2DestroyDuty:setUp() H.reset() end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty(global)
	local q, player = started(global)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

local ALLOWED = set({ "reb_xwing_tier2" })

-- AC-4: the first wave draws only from the table's ship list
function TestInquisitionT2DestroyDuty:test_the_first_wave_ships_come_only_from_its_ship_list()
	local q, player, area = startedDuty(I.DUTY3)

	H.enterArea(area, player.rootParent)
	pump(4500, I.DUTY3 .. " spawnAttackWave (4 s after entering the area)")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, I.DUTY3 .. ": the first wave spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(ALLOWED[ship.shipName] == true, I.DUTY3 .. ": wave ship " .. i .. " '" .. tostring(ship.shipName) .. "' is the table's ship")
		lu.assertEquals(ship.missionOwner, player, I.DUTY3 .. ": wave ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_dantooine", I.DUTY3 .. ": wave ship " .. i .. " zone")
	end
end

-- AC-4: a later wave of a later level
function TestInquisitionT2DestroyDuty:test_a_later_wave_spawns_only_its_ship_types()
	local q, player, area = startedDuty(I.DUTY3)

	H.enterArea(area, player.rootParent)
	pump(500, I.DUTY3 .. " entering")
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	pump(4000, I.DUTY3 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 2, I.DUTY3 .. ": a bigger wave at level 2")

	for i, ship in ipairs(ships) do
		lu.assertTrue(ALLOWED[ship.shipName] == true, I.DUTY3 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is the table's ship")
	end
end

-- AC-4: the boss wave
function TestInquisitionT2DestroyDuty:test_the_boss_wave_spawns_the_boss_ship_first()
	local q, player, area = startedDuty(I.DUTY3)

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, I.DUTY3 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "reb_xwing_tier3", I.DUTY3 .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), I.DUTY3 .. ": the boss has the boss kill observer")

	for i = 2, #ships do
		lu.assertTrue(ALLOWED[ships[i].shipName] == true, I.DUTY3 .. ": boss squad ship " .. i .. " '" .. tostring(ships[i].shipName) .. "' is the table's ship")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the escort duty
---------------------------------------------------------------------------------------------

TestInquisitionT2EscortDuty = {}

function TestInquisitionT2EscortDuty:setUp() H.reset() end

function TestInquisitionT2EscortDuty:tearDown() AC.tearDown() end

local FREIGHTERS = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }
local ATTACKERS = set({ "reb_xwing_tier2", "reb_ywing_tier2", "reb_z95_tier2" })

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
	local q, player = started(I.DUTY2)
	local agent = spawnShipAgent(FREIGHTERS[1], q.questZone, 0, 0, 0, player.rootParent)
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
	TestInquisitionT2EscortDuty["test_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		lu.assertTrue((quest(I.DUTY2).attackDelay or 0) > 0, I.DUTY2 .. ": attackDelay must be set")

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, I.DUTY2 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, I.DUTY2 .. ": @space/quest:escort_reward DI (2500 + 200 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, I.DUTY2 .. ": credits added to the bank")
	end
end

-- AC-4: the escort is one of the table's freighters
function TestInquisitionT2EscortDuty:test_each_of_the_three_freighters_can_be_the_escort()
	for pick, want in ipairs(FREIGHTERS) do
		lu.assertTrue((quest(I.DUTY2).attackDelay or 0) > 0, I.DUTY2 .. ": attackDelay must be set")

		local q, player = started(I.DUTY2)

		H.Engine.queueRandom(1, 3, pick)
		pump(2500, I.DUTY2 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, I.DUTY2 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, I.DUTY2 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, I.DUTY2 .. ": escort ship for draw " .. pick)
	end
end

-- AC-4: the attack wave after 120 s is one of the table's lists
function TestInquisitionT2EscortDuty:test_the_attack_wave_after_120_seconds_comes_from_its_attack_lists()
	lu.assertTrue((quest(I.DUTY2).attackDelay or 0) > 0, I.DUTY2 .. ": attackDelay must be set")

	local run = AC.escortRun(I.DUTY2)
	local agent = run.escortAgent

	lu.assertNotNil(agent, I.DUTY2 .. ": the escort ship spawned")
	pump(5000, I.DUTY2 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, I.DUTY2 .. " spawnAttackWave (attackDelay 120 s)")

	local n = 0

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= agent then
			n = n + 1
			lu.assertTrue(ATTACKERS[ship.shipName] == true, I.DUTY2 .. ": attacker " .. n .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end

	lu.assertTrue(n >= 1, I.DUTY2 .. ": an attack wave spawned after 120 s")
end

---------------------------------------------------------------------------------------------
-- AC-4: one duty at a time
---------------------------------------------------------------------------------------------

TestInquisitionT2DutyGuard = {}

function TestInquisitionT2DutyGuard:setUp() H.reset() end

function TestInquisitionT2DutyGuard:tearDown() AC.tearDown() end

-- AC-4
function TestInquisitionT2DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	for _, pair in ipairs({ { I.DUTY2, I.DUTY1 }, { I.DUTY3, I.DUTY2 }, { I.DUTY1, I.DUTY3 }, { I.DUTY2, I.DUTY3 } }) do
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
