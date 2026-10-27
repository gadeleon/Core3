-- Black Epsilon tier 2 (Prisk Kith'Vys): the opening, the four story missions, the final and the four duties run through the fakes.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-3, AC-4; Data mapping 1; R-2).
--
-- The oracle values are the spec's literals (black_epsilon_tier2_data.lua); the quest tables are driven through the harness's fakes,
-- never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside an event shows up as
-- "no Lua error" and not as a later, unrelated assertion. The Imperial-vs-Rebel hostility of the real AI cannot be checked here; see the
-- in-game checklist of the spec. Flying the survival is covered by space-quest-stub-survival: this file stops at "active".

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local P = require("black_epsilon_tier2_data")

P.load()

local function quest(global) return P.quest(global) end

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

---------------------------------------------------------------------------------------------
-- AC-3 (a): the opening, recovery 16
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Recovery = {}

function TestBlackEpsilonT2Recovery:setUp() H.reset() end

function TestBlackEpsilonT2Recovery:tearDown() AC.tearDown() end

-- AC-3 (a)
function TestBlackEpsilonT2Recovery:test_nothing_spawns_before_the_arrival_delay_and_the_first_pre_recovery_waypoint_is_given()
	local q = quest(P.OPENING)

	AC.resolveRecoveryPoints(q)
	q:start()

	local player = DRS.player(q, { pilot = "imperial" })

	q:startQuest(player, "")
	pump(0, P.OPENING .. " start")
	pump(19000, P.OPENING .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, P.OPENING .. ": nothing spawned 19 s after the start (arrivalDelay 20)")
	lu.assertTrue(isActive(player, q), P.OPENING .. ": active")
end

-- AC-3 (a)
function TestBlackEpsilonT2Recovery:test_the_black_epsilon_freighter_and_two_hidden_dagger_enforcers_spawn_after_the_arrival_delay()
	local q = quest(P.OPENING)
	local run = DRS.startRecoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	pump(10000, P.OPENING .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "freighterheavy_black_epsilon_tier2", P.OPENING .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_corellia", P.OPENING .. ": the recovery ship zone")

	local count = 0

	for _, n in ipairs(names) do
		if n == "hidden_daggers_enforcer_tier2" then
			count = count + 1
		end
	end

	lu.assertEquals(count, 2, P.OPENING .. ": hidden_daggers_enforcer_tier2 escorts among " .. table.concat(names, ", "))
	lu.assertTrue(isActive(run.player, q), P.OPENING .. ": active")
end

-- AC-3 (a): the pilot is sent to the first pre-recovery point
function TestBlackEpsilonT2Recovery:test_the_pilot_gets_a_waypoint_at_the_first_pre_recovery_point()
	local q = quest(P.OPENING)
	local run = DRS.startRecoveryRun(q, DRS.player(q, { pilot = "imperial" }))

	pump(10000, P.OPENING .. " after the ship arrived")

	local p1 = P.POINTS.corellia_imperial_patrol_1

	lu.assertNotNil(waypointAt(run.player, p1[1], p1[2], p1[3]), P.OPENING .. ": a waypoint at corellia_imperial_patrol_1")
end

---------------------------------------------------------------------------------------------
-- AC-3 (b): assassinate 12
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Assassinate12 = {}

function TestBlackEpsilonT2Assassinate12:setUp() H.reset() end

-- AC-3 (b)
function TestBlackEpsilonT2Assassinate12:test_the_diplomat_and_four_xwings_spawn_at_the_first_point_after_30_seconds()
	local q, player = started(P.A12)

	pump(29000, P.A12 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, P.A12 .. ": nothing spawned 29 s after the start (arrivalDelay 30)")
	pump(4000, P.A12 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "rebel_diplomat_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2" }, P.A12 .. ": spawned ships, target first")
	lu.assertTrue(ships[1].isSquadronLeader, P.A12 .. ": the target leads the squadron")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, P.POINTS.corellia_imperial_tier2_assassinate_1, P.A12 .. ": the target spawns at targetPatrols[1]")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, P.A12 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_corellia", P.A12 .. ": ship " .. i .. " zone")
	end
end

-- AC-3 (b): mustDestroyEscort = true
function TestBlackEpsilonT2Assassinate12:test_destroying_only_the_target_does_not_complete_the_quest()
	local q, player = started(P.A12)

	pump(34000, P.A12 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 5, P.A12 .. ": precondition: target and four escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(5000, P.A12 .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), P.A12 .. ": not complete with the escorts alive")
	lu.assertTrue(isActive(player, q), P.A12 .. ": still active")
end

-- AC-3 (b)
function TestBlackEpsilonT2Assassinate12:test_destroying_the_target_and_all_four_escorts_completes_the_quest()
	local q, player = started(P.A12)

	pump(34000, P.A12 .. " deployTargets")

	local ships = H.spawnedShips()

	for i = 1, 5 do
		lu.assertFalse(isComplete(player, q), P.A12 .. ": not complete before kill " .. i)
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, P.A12 .. " after kill " .. i)
	end

	pump(3000, P.A12 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), P.A12 .. ": complete after the target and the escorts")
	lu.assertFalse(isActive(player, q), P.A12 .. ": no longer active")
end

-- AC-3 (b): the escorts first, the target last
function TestBlackEpsilonT2Assassinate12:test_killing_the_escorts_first_and_the_target_last_completes_the_quest()
	local q, player = started(P.A12)

	pump(34000, P.A12 .. " deployTargets")

	local ships = H.spawnedShips()

	for _, i in ipairs({ 2, 3, 4, 5, 1 }) do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, P.A12 .. " after a kill")
	end

	pump(3000, P.A12 .. " after the last kill")
	lu.assertTrue(isComplete(player, q), P.A12 .. ": complete")
end

---------------------------------------------------------------------------------------------
-- AC-3 (c): inspect 13
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Inspect13 = {}

function TestBlackEpsilonT2Inspect13:setUp() H.reset() end

-- AC-3 (c)
function TestBlackEpsilonT2Inspect13:test_the_pilot_gets_one_waypoint_at_the_inspect_spawner()
	local q, player = started(P.I13)

	lu.assertEquals(#player.ghost.waypoints, 0, P.I13 .. ": no waypoint at the start")
	pump(2500, P.I13 .. " setupInspection and the notice")
	lu.assertEquals(#player.ghost.waypoints, 1, P.I13 .. ": waypoints handed out (one valid spawner)")

	local w = player.ghost.waypoints[1]

	lu.assertEquals(w.planet, "space_corellia", P.I13 .. ": waypoint planet")
	lu.assertEquals({ w.x, w.z, w.y }, P.SPAWNERS.corellia_imperial_tier2_inspect_freighter, P.I13 .. ": waypoint x z y (corellia_imperial_tier2_inspect_freighter)")
	lu.assertTrue(isActive(player, q), P.I13 .. ": active")
end

-- AC-3 (c): the cargo is the dossier
function TestBlackEpsilonT2Inspect13:test_inspecting_a_spy_smuggler_with_the_dossier_completes_the_quest_on_dock()
	local q, player = started(P.I13)

	pump(2500, P.I13 .. " setup")

	local target = H.worldAgent({ shipName = "rebel_spysmuggler_tier2", cargo = "personnel_dossier", spawner = "corellia_imperial_tier2_inspect_freighter", zone = "space_corellia" })
	local hash = getHashCode("personnel_dossier")

	H.inspect(player, target, hash)
	pump(0, P.I13 .. " inspect")
	H.dock(player, target, hash)
	pump(0, P.I13 .. " dock")
	pump(3000, P.I13 .. " after the dock")
	lu.assertTrue(isComplete(player, q), P.I13 .. ": complete after docking with the dossier freighter")
end

---------------------------------------------------------------------------------------------
-- AC-3 (d): patrol 15 and its surprise attack
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Patrol15 = {}

function TestBlackEpsilonT2Patrol15:setUp() H.reset() end

function TestBlackEpsilonT2Patrol15:tearDown() AC.tearDown() end

-- AC-3 (d)
function TestBlackEpsilonT2Patrol15:test_reaching_point_4_and_waiting_20_seconds_spawns_two_reb_xwing_tier2_and_killing_both_completes_both_quests()
	local q, player = started(P.P15)
	local s15 = quest(P.S15)

	lu.assertTrue(isActive(player, q), P.P15 .. ": precondition: active after startQuest")

	for point = 1, 3 do
		H.enterArea(AC.areaByNumber(q, point), player.rootParent)
		pump(500, P.P15 .. " point " .. point)
	end

	lu.assertEquals(#H.spawnedShips(), 0, P.P15 .. ": no attacker before point 4")
	pump(30000, P.P15 .. " waiting at point 3")
	lu.assertEquals(#H.spawnedShips(), 0, P.P15 .. ": point 3 does not start the split")

	H.enterArea(AC.areaByNumber(q, 4), player.rootParent)
	pump(500, P.P15 .. " point 4")
	lu.assertEquals(#H.spawnedShips(), 0, P.P15 .. ": no attacker at once")
	pump(18000, P.P15 .. " split delay")
	lu.assertEquals(#H.spawnedShips(), 0, P.P15 .. ": still no attacker 18.5 s after point 4 (sideQuestDelay is 20 s)")
	pump(8000, P.P15 .. " surprise attack start")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "reb_xwing_tier2", "reb_xwing_tier2" }, P.S15 .. ": spawned attackers")
	lu.assertTrue(isActive(player, s15), P.S15 .. ": active once the split started it")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_corellia", P.S15 .. ": attacker " .. i .. " zone")
		lu.assertEquals(ship.missionOwner, player, P.S15 .. ": attacker " .. i .. " belongs to the pilot")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(1500, P.S15 .. " after kill 1")
	lu.assertFalse(isComplete(player, s15), P.S15 .. ": not complete after 1 of 2 kills")

	H.destroyShip(ships[2], player.rootParent)
	pump(3000, P.S15 .. " after kill 2")

	lu.assertTrue(isComplete(player, s15), P.S15 .. ": complete after both attackers are destroyed")
	lu.assertTrue(isComplete(player, q), P.P15 .. ": the patrol is complete")
	lu.assertFalse(isActive(player, q), P.P15 .. ": the patrol is no longer active")
end

---------------------------------------------------------------------------------------------
-- AC-3 (e): assassinate 17 and the survival
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Assassinate17 = {}

function TestBlackEpsilonT2Assassinate17:setUp() H.reset() end

-- AC-3 (e), R-2
function TestBlackEpsilonT2Assassinate17:test_the_unmanned_xwing_spawns_alone_at_the_first_point_after_20_seconds_without_a_lua_error()
	local q, player = started(P.A17)

	pump(19000, P.A17 .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, P.A17 .. ": nothing spawned 19 s after the start (arrivalDelay 20)")
	pump(4000, P.A17 .. " deployTargets (no escorts)")

	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "reb_unmaned_xwing_tier2" }, P.A17 .. ": spawned ships (no escort)")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, P.POINTS.corellia_imperial_tier3_leg_1_recovery_recover_2, P.A17 .. ": the target spawns at targetPatrols[1]")
	lu.assertEquals(ships[1].missionOwner, player, P.A17 .. ": the target belongs to the pilot")
end

-- AC-3 (e): mustDestroyEscort = false, no escorts: the target kill completes the quest, and 5 s later the survival is active
function TestBlackEpsilonT2Assassinate17:test_destroying_the_target_completes_17_and_five_seconds_later_the_survival_is_active_at_the_ambush_point()
	local q, player = started(P.A17)
	local survival = quest(P.FINAL)

	pump(24000, P.A17 .. " deployTargets")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 1, P.A17 .. ": precondition: the target")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, P.A17 .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), P.A17 .. ": complete")
	lu.assertFalse(isActive(player, survival), P.FINAL .. ": not active at once")
	pump(3000, P.A17 .. " split delay")
	lu.assertFalse(isActive(player, survival), P.FINAL .. ": not active 3 s after the completion (sideQuestDelay 5 s)")
	pump(8000, P.FINAL .. " start")
	lu.assertTrue(isActive(player, survival), P.FINAL .. ": active once the split started it")

	local p = P.POINTS.rebel_ambush_point

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), P.FINAL .. ": a waypoint at rebel_ambush_point")
end

---------------------------------------------------------------------------------------------
-- AC-4: the destroy duties 8 and 10
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2DestroyDuties = {}

function TestBlackEpsilonT2DestroyDuties:setUp() H.reset() end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function startedDuty(global)
	local q, player = started(global)
	local area = getSceneObject(readData(dataKey(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

local DESTROY = {
	[P.DUTY8] = { lists = { repeated("hidden_daggers_eliminator_tier2", 2), repeated("hidden_daggers_killer_tier2", 2) }, boss = "hidden_daggers_executioner_tier3", levels = 3 },
	[P.DUTY10] = { lists = { repeated("reb_xwing_tier2", 2), repeated("reb_z95_tier2", 2) }, boss = "reb_xwing_tier3", levels = 4 },
}

for _, global in ipairs({ P.DUTY8, P.DUTY10 }) do
	local d = DESTROY[global]
	local allowed = set({ d.lists[1][1], d.lists[2][1] })

	-- AC-4: the first wave draws only from the table's ship lists
	TestBlackEpsilonT2DestroyDuties["test_" .. global .. "_first_wave_ships_come_only_from_its_ship_types"] = function()
		local q, player, area = startedDuty(global)

		H.enterArea(area, player.rootParent)
		pump(4500, global .. " spawnAttackWave (4 s after entering the area)")

		local ships = H.spawnedShips()

		lu.assertTrue(#ships >= 1, global .. ": the first wave spawned")

		for i, ship in ipairs(ships) do
			lu.assertTrue(allowed[ship.shipName] == true, global .. ": wave ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
			lu.assertEquals(ship.missionOwner, player, global .. ": wave ship " .. i .. " belongs to the pilot")
		end
	end

	-- AC-4: a later wave of a later level
	TestBlackEpsilonT2DestroyDuties["test_" .. global .. "_a_later_wave_spawns_only_its_ship_types"] = function()
		local q, player, area = startedDuty(global)

		H.enterArea(area, player.rootParent)
		pump(500, global .. " entering")
		writeData(dataKey(q, player, "CurrentLevel:"), 1)
		pump(4000, global .. " spawnAttackWave")

		local ships = H.spawnedShips()

		lu.assertTrue(#ships >= 2, global .. ": a bigger wave at level 2")

		for i, ship in ipairs(ships) do
			lu.assertTrue(allowed[ship.shipName] == true, global .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		end
	end

	-- AC-4: the boss wave
	TestBlackEpsilonT2DestroyDuties["test_" .. global .. "_the_boss_wave_spawns_the_boss_ship_first"] = function()
		local q, player, area = startedDuty(global)

		writeData(dataKey(q, player, "bossLevel:"), 1)
		H.enterArea(area, player.rootParent)
		pump(4500, global .. " spawnAttackWave (boss)")

		local ships = H.spawnedShips()

		lu.assertEquals(ships[1] and ships[1].shipName, d.boss, global .. ": the first ship of the boss wave")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), global .. ": the boss has the boss kill observer")

		for i = 2, #ships do
			lu.assertTrue(allowed[ships[i].shipName] == true, global .. ": boss squad ship " .. i .. " '" .. tostring(ships[i].shipName) .. "' is one of the table's ships")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: the escort duties 9 and 11
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2EscortDuties = {}

function TestBlackEpsilonT2EscortDuties:setUp() H.reset() end

function TestBlackEpsilonT2EscortDuties:tearDown() AC.tearDown() end

local ESCORT = {
	[P.DUTY9] = {
		ships = { "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" },
		attackers = { "hutt_pirate_s01_tier2", "hutt_fighter_s02_tier2", "hutt_pirate_s02_tier2" },
		points = 9,
	},
	[P.DUTY11] = {
		ships = { "imp_freighterheavy_tier2", "imp_freightermedium_tier2", "imp_freighterlight_tier2" },
		attackers = { "reb_xwing_tier2", "reb_ywing_tier2", "reb_z95_tier2" },
		points = 5,
	},
}

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
local function escortAtItsLastArea(global, kills)
	local q, player = started(global)
	local agent = spawnShipAgent(ESCORT[global].ships[1], "space_corellia", 0, 0, 0, player.rootParent)
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

for _, global in ipairs({ P.DUTY9, P.DUTY11 }) do
	-- AC-4: 2500 + 200 per kill, without a Lua error
	for kills, want in pairs({ [0] = 2500, [1] = 2700, [2] = 2900, [5] = 3500 }) do
		TestBlackEpsilonT2EscortDuties["test_" .. global .. "_leg_payout_after_" .. kills .. "_kills_is_" .. want] = function()
			lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set")

			local q, player, agent, area = escortAtItsLastArea(global, kills)
			local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

			lu.assertTrue(ok, global .. ": the leg payout raised a Lua error: " .. tostring(err))
			lu.assertEquals(payouts(player), { want }, global .. ": @space/quest:escort_reward DI (2500 + 200 x " .. kills .. " kills)")
			lu.assertEquals(player.bankCredits, want, global .. ": credits added to the bank")
		end
	end

	-- AC-4: the escort is one of the table's freighters
	TestBlackEpsilonT2EscortDuties["test_" .. global .. "_each_of_the_three_freighters_can_be_the_escort"] = function()
		for pick, want in ipairs(ESCORT[global].ships) do
			lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set")

			local q, player = started(global)

			H.Engine.queueRandom(1, 3, pick)
			pump(2500, global .. " setupEscort")

			local start = readData(player.objectID .. q.className .. ":startPoint:")

			H.enterArea(AC.areaByNumber(q, start), player.rootParent)
			pump(6000, global .. " spawnEscortShip")

			local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

			lu.assertNotNil(agent, global .. " draw " .. pick .. ": the escort spawned")
			lu.assertEquals(agent.shipName, want, global .. ": escort ship for draw " .. pick)
		end
	end

	-- AC-4: the attack wave after 120 s is one of the table's lists
	TestBlackEpsilonT2EscortDuties["test_" .. global .. "_the_attack_wave_after_120_seconds_comes_from_its_attack_lists"] = function()
		lu.assertTrue((quest(global).attackDelay or 0) > 0, global .. ": attackDelay must be set")

		local run = AC.escortRun(global)
		local agent = run.escortAgent

		lu.assertNotNil(agent, global .. ": the escort ship spawned")
		pump(5000, global .. " assignEscortPoints")

		local before = #H.spawnedShips()

		pump(121 * 1000, global .. " spawnAttackWave (attackDelay 120 s)")

		local allowed = set(ESCORT[global].attackers)
		local n = 0

		for i, ship in ipairs(H.spawnedShips()) do
			if i > before and ship ~= agent then
				n = n + 1
				lu.assertTrue(allowed[ship.shipName] == true, global .. ": attacker " .. n .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
			end
		end

		lu.assertTrue(n >= 1, global .. ": an attack wave spawned after 120 s")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: one duty at a time
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2DutyGuard = {}

function TestBlackEpsilonT2DutyGuard:setUp() H.reset() end

-- AC-4
function TestBlackEpsilonT2DutyGuard:test_a_second_duty_is_refused_while_the_first_is_running()
	for _, pair in ipairs({ { P.DUTY8, P.DUTY9 }, { P.DUTY10, P.DUTY11 }, { P.DUTY9, P.DUTY8 }, { P.DUTY11, P.DUTY10 } }) do
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
