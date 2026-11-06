-- Storm Squadron tier 2 part 3 (Field Commander Alozen): the three missions and the three duties run through the fakes.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-3, AC-4; Data mapping 1; R-3, R-6).
--
-- The oracle values are the spec's literals (storm_tier2_alozen_data.lua, proven equal to the SWG .tab fixtures by test_storm_tier2_alozen_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside
-- an event shows up as "no Lua error" and not as a later, unrelated assertion. The real AI's hostility (R-3) cannot be checked here; see the in-game
-- checklist of the spec.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local I = require("inspect_scenario")
local A = require("storm_tier2_alozen_data")

A.load()
I.load()

local function quest(global) return A.quest(global) end

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

local function newShips(before, skip)
	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= skip then
			out[#out + 1] = ship
		end
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

local function waypointAt(player, name)
	local p = A.POINTS[name]

	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == p[1] and w.z == p[2] and w.y == p[3] then
			return w
		end
	end
end

local function tearDown() AC.tearDown() end

---------------------------------------------------------------------------------------------
-- AC-3 (a): inspect 4, the Rebel agent
---------------------------------------------------------------------------------------------

TestAlozenInspect4 = {}

function TestAlozenInspect4:setUp() H.reset() end

local function freshInspect()
	quest(A.M1)

	local player = H.newPlayer({ zone = "space_yavin4", ship = {}, pilot = "imperial" })

	return I.fresh("imperial_ss_4", { player = player })
end

-- AC-3 (a)
function TestAlozenInspect4:test_the_mission_starts_and_adds_one_waypoint_at_the_spawner()
	local sc = freshInspect():toSetup()

	lu.assertTrue(sc:active(), "the quest is active")
	lu.assertEquals(I.errorLogs(), {}, "no LT_ERROR line")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")

	local w = sc:waypoints()[1]

	lu.assertEquals({ w.planet, w.x, w.z, w.y }, { "space_yavin4", A.SPAWNER.x, A.SPAWNER.z, A.SPAWNER.y }, "the waypoint is at the spawner tatooine_imperial_tier2_inspect_rebagent")
	lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, "observers on the player")
end

-- AC-3 (a): the Rebel agent from the spawner reports the cargo; docking completes
function TestAlozenInspect4:test_inspecting_a_rebel_agent_from_the_spawner_reports_the_cargo_and_docking_completes_the_mission()
	local sc = freshInspect():toSetup()
	local ship = sc:target(1)

	lu.assertEquals(ship.shipName, "rebel_agent_tier3", "the target is the Rebel agent")
	lu.assertEquals(sc:hash(), getHashCode("yavin_activity_log"), "the quest cargo hash")
	sc:inspect(ship)
	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, "inspect_found_cargo messages")
	lu.assertTrue(sc:taskActive(2), "the dock task is active")
	sc:dock(ship)
	lu.assertTrue(sc:complete(), "the mission is complete after docking")
	lu.assertFalse(sc:active(), "no longer active")
	lu.assertEquals(I.errorLogs(), {}, "no LT_ERROR line")
end

-- AC-3 (a): the same ship from another spawner is not a target
function TestAlozenInspect4:test_a_rebel_agent_from_another_spawner_is_not_a_target()
	local sc = freshInspect():toSetup()
	local other = sc:target(1, { spawner = "some_other_spawner" })

	lu.assertFalse(sc.quest:isQuestTarget(other), "isQuestTarget")
	sc:inspect(other)
	sc:dock(other)
	lu.assertFalse(sc:complete(), "docking it does not complete the mission")
	lu.assertTrue(sc:active(), "the mission keeps running")

	local none = sc:target(1, { spawner = false })

	lu.assertFalse(sc.quest:isQuestTarget(none), "a ship with no SpawnerName key")
end

-- AC-3 (a): another template from the right spawner is not a target (the spawner holds seven ship types)
function TestAlozenInspect4:test_another_ship_template_from_the_spawner_is_not_a_target()
	local sc = freshInspect():toSetup()

	for _, name in ipairs({ "reb_xwing_tier2", "reb_xwing_tier3", "reb_ywing_tier3", "reb_z95_tier3", "reb_bwing_tier3", "reb_awing_tier3" }) do
		local other = sc:target(1, { shipName = name })

		lu.assertFalse(sc.quest:isQuestTarget(other), name .. ": isQuestTarget")
	end

	local other = sc:target(1, { shipName = "reb_xwing_tier2" })

	sc:inspect(other)
	sc:dock(other)
	lu.assertFalse(sc:complete(), "docking another ship does not complete the mission")
end

-- AC-3 (a): a Rebel agent with another cargo does not count
function TestAlozenInspect4:test_a_rebel_agent_that_carries_another_cargo_does_not_complete_the_mission()
	local sc = freshInspect():toSetup()
	local ship = sc:target(1, { cargo = "unfinished_flight_log" })

	sc:dock(ship, getHashCode("unfinished_flight_log"))
	lu.assertFalse(sc:complete(), "wrong cargo")
	lu.assertTrue(sc:active(), "still active")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): escort 5, the scan freighter
---------------------------------------------------------------------------------------------

TestAlozenEscort5 = {}

function TestAlozenEscort5:setUp() H.reset() end
TestAlozenEscort5.tearDown = tearDown

local SCAN_POINTS = { "yavin_rebel_region_scan_1", "yavin_rebel_region_scan_2", "yavin_rebel_region_scan_3" }

local function assertDelay(global)
	lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds, 0 by default)")
end

-- AC-3 (b): the rendezvous waypoint is one of the three scan regions
function TestAlozenEscort5:test_the_pilot_is_sent_to_one_of_the_three_scan_regions()
	assertDelay(A.M2)

	local q, player = started(A.M2)

	pump(2500, A.M2 .. " setupEscort")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertTrue(start ~= nil and start >= 1 and start <= 3, A.M2 .. ": the start point is one of 3, got " .. tostring(start))
	lu.assertNotNil(waypointAt(player, SCAN_POINTS[start]), A.M2 .. ": a waypoint at " .. tostring(SCAN_POINTS[start]))
end

-- AC-3 (b)
function TestAlozenEscort5:test_the_scan_freighter_spawns_in_yavin_4_for_the_pilot()
	assertDelay(A.M2)

	local run = AC.escortRun(A.M2)
	local agent = run.escortAgent

	lu.assertNotNil(agent, A.M2 .. ": the escort ship spawned")
	lu.assertEquals(agent.shipName, "imperial_scan_freighter_tier2", A.M2 .. ": the escort ship")
	lu.assertEquals(agent.zone, "space_yavin4", A.M2 .. ": the escort ship zone")
	lu.assertTrue(isActive(run.player, quest(A.M2)), A.M2 .. ": active")
end

-- AC-3 (b): after 120 s a wave of one of the two lists
function TestAlozenEscort5:test_the_first_attack_wave_after_120_seconds_is_one_of_the_two_lists()
	assertDelay(A.M2)

	local run = AC.escortRun(A.M2)
	local agent = run.escortAgent

	lu.assertNotNil(agent, A.M2 .. ": the escort ship spawned")
	pump(5000, A.M2 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, A.M2 .. " spawnAttackWave (attackDelay 120 s)")

	local joined = table.concat(sorted(shipNames(newShips(before, agent))), ",")
	local list1 = table.concat(sorted({ "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" }), ",")
	local list2 = table.concat(sorted({ "reb_ywing_tier3", "reb_z95_tier2", "reb_z95_tier2" }), ",")

	lu.assertTrue(joined == list1 or joined == list2, A.M2 .. ": the wave is list 1 or list 2, got " .. joined)
end

-- AC-3 (b): both lists can be drawn
function TestAlozenEscort5:test_the_random_pick_can_draw_either_list()
	assertDelay(A.M2)

	local seen = {}

	for _, pick in ipairs({ 1, 2 }) do
		AC.tearDown()

		local run = AC.escortRun(A.M2)

		lu.assertNotNil(run.escortAgent, A.M2 .. ": the escort ship spawned")
		pump(5000, A.M2 .. " assignEscortPoints")
		H.Engine.nextRandom = pick

		local before = #H.spawnedShips()

		pump(121 * 1000, A.M2 .. " spawnAttackWave pick " .. pick)
		seen[#seen + 1] = table.concat(sorted(shipNames(newShips(before, run.escortAgent))), ",")
	end

	lu.assertEquals(seen, { "reb_xwing_tier2,reb_xwing_tier2,reb_xwing_tier3", "reb_ywing_tier3,reb_z95_tier2,reb_z95_tier2" }, "the waves of draw 1 and draw 2")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): recovery 6, the Twilight Sun
---------------------------------------------------------------------------------------------

TestAlozenRecovery6 = {}

function TestAlozenRecovery6:setUp() H.reset() end

function TestAlozenRecovery6:tearDown()
	AC.tearDown()
	H.Engine.config.rejectEmptyShipName = nil
end

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

-- AC-3 (c)
function TestAlozenRecovery6:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(A.M3)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, A.M3 .. " start")
	pump(19000, A.M3 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, A.M3 .. ": nothing spawned 19 s after the start (arrivalDelay 20)")
	lu.assertTrue(isActive(player, q), A.M3 .. ": active")
end

-- AC-3 (c)
function TestAlozenRecovery6:test_the_twilight_sun_and_four_z95s_spawn_after_the_arrival_delay()
	local q = quest(A.M3)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))
	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "twilight_sun_tier1", A.M3 .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_yavin4", A.M3 .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "reb_z95_tier2"), 4, A.M3 .. ": reb_z95_tier2 escorts among " .. table.concat(names, ", "))
	lu.assertEquals(run.ship.missionOwner, run.player, A.M3 .. ": the Twilight Sun belongs to the pilot")
	lu.assertTrue(isActive(run.player, q), A.M3 .. ": active")
end

-- AC-3 (c): the pilot is sent to the first pre-recovery point
function TestAlozenRecovery6:test_the_pilot_gets_a_waypoint_at_the_first_pre_recovery_point()
	local q = quest(A.M3)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	lu.assertNotNil(waypointAt(run.player, "tatooine_imperial_twilight_1"), A.M3 .. ": a waypoint at tatooine_imperial_twilight_1")
end

-- AC-3 (c): the attack wave after capture is one of the two lists
function TestAlozenRecovery6:test_the_attack_wave_after_the_capture_is_one_of_the_two_lists()
	local q = quest(A.M3)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)

	local wave = RF.wave(run)
	local joined = table.concat(sorted(shipNames(wave)), ",")

	lu.assertTrue(joined == "reb_xwing_tier2,reb_xwing_tier2,reb_xwing_tier2" or joined == "reb_xwing_tier2,reb_xwing_tier2,reb_ywing_tier2", A.M3 .. ": the wave is list 1 or list 2, got " .. joined)
end

-- AC-3 (c): a captured ship, taken through all three recovery areas, completes the mission
function TestAlozenRecovery6:test_capturing_the_twilight_sun_and_bringing_it_through_the_recovery_areas_completes_the_mission()
	local q = quest(A.M3)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)
	RF.finish(run)
	pump(3000, A.M3 .. " after the last recovery area")
	lu.assertTrue(isComplete(run.player, q), A.M3 .. ": complete")
	lu.assertFalse(isActive(run.player, q), A.M3 .. ": no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-4: the destroy duty (Debris Cult, FA-8)
---------------------------------------------------------------------------------------------

TestAlozenDestroyDuty = {}

function TestAlozenDestroyDuty:setUp() H.reset() end
TestAlozenDestroyDuty.tearDown = tearDown

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty(global)
	local q, player = started(global)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

local DESTROY_SHIPS = set({ "deathstar_debris_guardian_tier2", "deathstar_debris_fanatic_tier2" })

-- AC-4: the first wave draws only from the table's ship lists
function TestAlozenDestroyDuty:test_the_first_wave_ships_come_only_from_its_ship_lists()
	local q, player, area = startedDuty(A.DUTY1)

	H.enterArea(area, player.rootParent)
	pump(4500, A.DUTY1 .. " spawnAttackWave (4 s after entering the area)")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships >= 1, A.DUTY1 .. ": the first wave spawned")

	for i, ship in ipairs(ships) do
		lu.assertTrue(DESTROY_SHIPS[ship.shipName] == true, A.DUTY1 .. ": wave ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertEquals(ship.missionOwner, player, A.DUTY1 .. ": wave ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_yavin4", A.DUTY1 .. ": wave ship " .. i .. " zone")
	end
end

-- AC-4: a wave of each level
function TestAlozenDestroyDuty:test_a_wave_of_each_level_spawns_only_its_ship_types()
	for level = 0, 4 do
		local q, player, area = startedDuty(A.DUTY1)

		H.enterArea(area, player.rootParent)
		pump(500, A.DUTY1 .. " entering")
		writeData(dataKey(q, player, "CurrentLevel:"), level)
		pump(4000, A.DUTY1 .. " spawnAttackWave")

		local ships = H.spawnedShips()

		lu.assertTrue(#ships >= 1, A.DUTY1 .. ": a wave at level " .. (level + 1))

		for i, ship in ipairs(ships) do
			lu.assertTrue(DESTROY_SHIPS[ship.shipName] == true, A.DUTY1 .. ": level " .. (level + 1) .. " ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end
end

-- AC-4: the boss wave
function TestAlozenDestroyDuty:test_the_boss_wave_spawns_the_boss_ship_first()
	local q, player, area = startedDuty(A.DUTY1)

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, A.DUTY1 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "deathstar_debris_priest_tier3", A.DUTY1 .. ": the first ship of the boss wave")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), A.DUTY1 .. ": the boss has the boss kill observer")

	for i = 2, #ships do
		lu.assertTrue(DESTROY_SHIPS[ships[i].shipName] == true, A.DUTY1 .. ": boss squad ship " .. i .. " '" .. tostring(ships[i].shipName) .. "' is one of the table's ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the recovery duty
---------------------------------------------------------------------------------------------

TestAlozenRecoveryDuty = {}

function TestAlozenRecoveryDuty:setUp() H.reset() end

function TestAlozenRecoveryDuty:tearDown()
	AC.tearDown()
	H.Engine.config.rejectEmptyShipName = nil
end

local RECOVERY_ATTACKERS = set({ "deathstar_debris_scavenger_tier2", "deathstar_debris_fanatic_tier2" })

local function dutyPaid(run, amount, label)
	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 1, label .. ": addBankCredits calls")
	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, amount, label .. ": credits")
	lu.assertEquals(#pay.messages, 1, label .. ": @space/quest:recovery_reward messages")
	lu.assertEquals(pay.messages[1] and pay.messages[1].DI, amount, label .. ": recovery_reward DI")
end

-- AC-4: nothing spawns before the arrival delay (30 s)
function TestAlozenRecoveryDuty:test_nothing_spawns_before_the_arrival_delay()
	local q = quest(A.DUTY2)

	H.Engine.config.rejectEmptyShipName = true
	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, A.DUTY2 .. " start")
	pump(29000, A.DUTY2 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, A.DUTY2 .. ": nothing spawned 29 s after the start (arrivalDelay 30)")
end

-- AC-4: the Debris Cult freighter with four guardians
function TestAlozenRecoveryDuty:test_the_debris_cult_freighter_spawns_with_four_guardians()
	local q = quest(A.DUTY2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))
	local escorts = {}

	lu.assertEquals(run.ship.shipName, "deathstar_debris_freighter_tier2", A.DUTY2 .. ": the target")
	lu.assertEquals(run.ship.zone, "space_yavin4", A.DUTY2 .. ": the target zone")
	lu.assertEquals(run.ship.missionOwner, run.player, A.DUTY2 .. ": the target belongs to the pilot")

	for _, ship in ipairs(H.spawnedShips()) do
		if ship ~= run.ship then
			escorts[#escorts + 1] = ship.shipName
		end
	end

	lu.assertEquals(escorts, repeated("deathstar_debris_guardian_tier2", 4), A.DUTY2 .. ": the escorts of the target")
	lu.assertNotNil(waypointAt(run.player, "yavin_imp_scavenger_1"), A.DUTY2 .. ": a waypoint at yavin_imp_scavenger_1")
end

-- AC-4: pays 2500 with no kills
function TestAlozenRecoveryDuty:test_a_capture_without_kills_pays_2500()
	local q = quest(A.DUTY2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)
	RF.finish(run)
	dutyPaid(run, 2500, A.DUTY2 .. " no kills")
end

-- AC-4: pays 2500 + 200 per kill of the first wave
function TestAlozenRecoveryDuty:test_a_capture_after_killing_the_first_wave_pays_2500_plus_200_per_kill()
	local q = quest(A.DUTY2)
	local run = recoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	RF.capture(run)

	local wave = RF.wave(run)

	lu.assertEquals(#wave, 2, A.DUTY2 .. ": the first wave is attack list 1 (2 ships)")

	for i, ship in ipairs(wave) do
		lu.assertTrue(RECOVERY_ATTACKERS[ship.shipName] == true, A.DUTY2 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end

	RF.killAll(run, wave)
	RF.finish(run)
	dutyPaid(run, 2500 + 200 * 2, A.DUTY2 .. " two kills")
end

---------------------------------------------------------------------------------------------
-- AC-4: the escort duty
---------------------------------------------------------------------------------------------

TestAlozenEscortDuty = {}

function TestAlozenEscortDuty:setUp() H.reset() end
TestAlozenEscortDuty.tearDown = tearDown

local FREIGHTERS_ESCORT = { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }
local ESCORT_ATTACKERS = set({ "deathstar_debris_fanatic_tier2", "deathstar_debris_guardian_tier2" })

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
	local q, player = started(A.DUTY3)
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
	TestAlozenEscortDuty["test_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
		lu.assertTrue((quest(A.DUTY3).attackDelay or 0) > 0, A.DUTY3 .. ": attackDelay must be set")

		local q, player, agent, area = escortAtItsLastArea(kills)
		local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

		lu.assertTrue(ok, A.DUTY3 .. ": the leg payout raised a Lua error: " .. tostring(err))
		lu.assertEquals(payouts(player), { want }, A.DUTY3 .. ": @space/quest:escort_reward DI (2500 + 200 x " .. kills .. " kills)")
		lu.assertEquals(player.bankCredits, want, A.DUTY3 .. ": credits added to the bank")
	end
end

-- AC-4: the escort is one of the table's Imperial freighters
function TestAlozenEscortDuty:test_each_of_the_three_freighters_can_be_the_escort()
	for pick, want in ipairs(FREIGHTERS_ESCORT) do
		lu.assertTrue((quest(A.DUTY3).attackDelay or 0) > 0, A.DUTY3 .. ": attackDelay must be set")

		local q, player = started(A.DUTY3)

		H.Engine.queueRandom(1, 3, pick)
		pump(2500, A.DUTY3 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, A.DUTY3 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, A.DUTY3 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, A.DUTY3 .. ": escort ship for draw " .. pick)
		lu.assertEquals(agent.zone, "space_yavin4", A.DUTY3 .. ": escort zone")
	end
end

-- AC-4: the attack wave after 120 s is one of the table's lists
function TestAlozenEscortDuty:test_the_attack_wave_after_120_seconds_comes_from_its_attack_lists()
	lu.assertTrue((quest(A.DUTY3).attackDelay or 0) > 0, A.DUTY3 .. ": attackDelay must be set")

	local run = AC.escortRun(A.DUTY3)
	local agent = run.escortAgent

	lu.assertNotNil(agent, A.DUTY3 .. ": the escort ship spawned")
	pump(5000, A.DUTY3 .. " assignEscortPoints")

	local before = #H.spawnedShips()

	pump(121 * 1000, A.DUTY3 .. " spawnAttackWave (attackDelay 120 s)")

	local n = 0

	for i, ship in ipairs(newShips(before, agent)) do
		n = n + 1
		lu.assertTrue(ESCORT_ATTACKERS[ship.shipName] == true, A.DUTY3 .. ": attacker " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
	end

	lu.assertTrue(n >= 1, A.DUTY3 .. ": an attack wave spawned after 120 s")
end

---------------------------------------------------------------------------------------------
-- AC-4: one duty at a time
---------------------------------------------------------------------------------------------

TestAlozenDutyGuard = {}

function TestAlozenDutyGuard:setUp() H.reset() end
TestAlozenDutyGuard.tearDown = tearDown

-- AC-4
function TestAlozenDutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	for _, pair in ipairs({ { A.DUTY3, A.DUTY1 }, { A.DUTY1, A.DUTY3 }, { A.DUTY3, A.DUTY2 }, { A.DUTY1, A.DUTY2 } }) do
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

-- AC-4: a duty held in the datapad refuses each of the three
function TestAlozenDutyGuard:test_a_duty_held_in_the_datapad_refuses_each_of_the_three_duties()
	for _, global in ipairs(A.DUTIES) do
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

return nil
