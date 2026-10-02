-- Space battle setup, force arrival and battle start (space-quest-stub-space-battle).
-- Spec: .claude/work/space-quest-stub-space-battle/01-spec.md (AC-2, AC-3, AC-4, AC-5, I-8, Behavior 1-6).
-- Numbers come from the SWG-Source fixtures through battle_scenario.lua (B.oracle), not from the Core3 tables.

local lu = require("luaunit")
local H = require("harness")
local B = require("battle_scenario")

B.load()

local function secs(n) return n * 1000 end

local function spawnCalls() return H.Engine.callsTo("spawnShipAgent") end

local function near(actual, expected, message)
	lu.assertAlmostEquals(actual, expected, 0.0001, message)
end

TestSpaceBattleNoStub = {}

function TestSpaceBattleNoStub:setUp() H.reset() end

-- AC-2
function TestSpaceBattleNoStub:test_a_started_battle_stays_active_for_1400_s_and_never_schedules_a_completion()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()

		H.advance(secs(1400))

		lu.assertTrue(sc:active(), name .. ": the journal quest is still active after 1400 s without kills")
		lu.assertFalse(sc:complete(), name .. ": not complete")
		lu.assertEquals(#B.createEvents("completeQuest"), 0, name .. ": no completeQuest event was ever created")
	end
end

TestSpaceBattleSetup = {}

function TestSpaceBattleSetup:setUp() H.reset() end

-- AC-3
function TestSpaceBattleSetup:test_starting_in_the_zone_completes_task_0_and_activates_task_1()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()

		lu.assertTrue(sc:active(), name .. ": the journal quest is active")
		lu.assertTrue(sc:taskComplete(0), name .. ": task 0 complete")
		lu.assertTrue(sc:taskActive(1), name .. ": task 1 (quest_findbattle) active")
		lu.assertFalse(sc:taskActive(0), name .. ": task 0 is no longer active")
		lu.assertFalse(sc:taskActive(2) or sc:taskComplete(2), name .. ": task 2 not touched yet")
	end
end

-- AC-3
function TestSpaceBattleSetup:test_setup_adds_exactly_one_space_waypoint_at_the_battle_point_and_remembers_it()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local o = sc.o
		local wps = sc:waypoints()

		lu.assertEquals(#wps, 1, name .. ": exactly one waypoint")

		local wp = wps[1]

		lu.assertEquals(wp.planet, o.zone, name .. ": waypoint planet")
		lu.assertEquals({ wp.x, wp.z, wp.y }, { o.point.x, o.point.z, o.point.y }, name .. ": waypoint (x, z, y) is the battle point")
		lu.assertEquals(wp.color, WAYPOINT_SPACE, name .. ": WAYPOINT_SPACE")
		lu.assertEquals(wp.special, WAYPOINTQUESTTASK, name .. ": WAYPOINTQUESTTASK")
		lu.assertEquals(wp.questDetails, "@spacequest/space_battle/" .. name .. ":title_d", name .. ": quest details")
		lu.assertEquals(getQuestStatus(sc.player.objectID .. ":" .. sc.className .. ":waypointID"), tostring(wp.objectID), name .. ": the waypoint id is kept as the :waypointID quest status")
	end
end

-- AC-3
function TestSpaceBattleSetup:test_setup_sends_the_in_progress_message_and_found_loc_once_each()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local events = sc:events()

		lu.assertEquals(B.count(events, "title", "progress"), 1, name .. ": one quest_in_progress message with the quest title")
		lu.assertEquals(B.count(events, "found_loc", "update"), 1, name .. ": one found_loc update")
		lu.assertEquals(B.count(events, "allies_arrived"), 0, name .. ": no arrival message yet")
		lu.assertEquals(B.count(events, "battle_started"), 0, name .. ": no battle start yet")
	end
end

-- AC-3
function TestSpaceBattleSetup:test_setup_adds_the_zone_observer_with_persistence_and_spawns_nothing_yet()
	local sc = B.fresh(B.WIN):setup()

	lu.assertEquals(H.Engine.observerCount(ZONESWITCHED, sc.className, "enteredZone", sc.player), 1, "exactly one ZONESWITCHED observer")
	lu.assertEquals(#spawnCalls(), 0, "no ship spawns at setup")

	local observers = H.Engine.callsTo("createObserver")

	lu.assertEquals(observers[1][1], ZONESWITCHED, "the first observer is ZONESWITCHED")
	lu.assertEquals(observers[1][5], 1, "ZONESWITCHED is created with persistence argument 1")
end

-- AC-3
function TestSpaceBattleSetup:test_starting_twice_keeps_one_observer_and_does_not_set_up_again()
	local sc = B.fresh(B.WIN):setup()

	sc.quest:startQuest(sc.player, "")
	H.advance(0)

	lu.assertEquals(H.Engine.observerCount(ZONESWITCHED, sc.className, "enteredZone", sc.player), 1, "still one ZONESWITCHED observer")
	lu.assertEquals(#sc:waypoints(), 1, "still one waypoint")
	lu.assertEquals(B.count(sc:events(), "found_loc", "update"), 1, "still one found_loc")
end

-- AC-3
function TestSpaceBattleSetup:test_start_in_another_zone_waits_for_the_quest_zone_plus_one_second()
	local sc = B.fresh(B.WIN, { zone = B.ELSEWHERE })
	local o = sc.o

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "the journal quest is active")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint in another zone")
	lu.assertFalse(sc:taskComplete(0), "task 0 not complete yet")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED observer registered")

	H.zoneSwitch(sc.player, o.zone, { ship = { x = o.point.x, z = o.point.z, y = o.point.y } })
	lu.assertEquals(#sc:waypoints(), 0, "nothing happens inside the observer")

	H.advance(secs(1) - 1)
	lu.assertEquals(#sc:waypoints(), 0, "nothing one ms before the 1 s check")

	H.advance(1)
	lu.assertEquals(#sc:waypoints(), 1, "set up 1 s after the zone switch")
	lu.assertTrue(sc:taskComplete(0), "task 0 complete")
	lu.assertTrue(sc:taskActive(1), "task 1 active")
end

-- AC-3
function TestSpaceBattleSetup:test_a_second_entry_before_the_check_runs_adds_no_second_waypoint_or_found_loc()
	local sc = B.fresh(B.WIN, { zone = B.ELSEWHERE })
	local o = sc.o

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))

	H.zoneSwitch(sc.player, o.zone)
	H.advance(300)
	H.zoneSwitch(sc.player, o.zone)
	H.advance(secs(2))

	lu.assertTrue(sc:active(), "still active (nothing was abandoned: the run did not exist at the second entry)")
	lu.assertEquals(#sc:waypoints(), 1, "two entries before setup produce one waypoint")
	lu.assertEquals(B.count(sc:events(), "found_loc", "update"), 1, "one found_loc")
	lu.assertEquals(B.count(sc:events(), "title", "progress"), 1, "one in-progress message")

	-- the first entry was at 5 s, so the one setup ran at 6 s; arrivals count from it
	sc.tSetup = secs(6)
	sc:at(secs(sc.o.allyDelay))
	lu.assertEquals(#sc:spawnedAt(sc.o.allyDelay), #sc.o.allyForce, "the allies spawn once, not once per entry")
	lu.assertEquals(#spawnCalls(), #sc.o.allyForce, "no second set of allies from the second entry")
end

-- AC-3
function TestSpaceBattleSetup:test_the_yacht_never_sets_up_but_a_ship_after_the_switch_does()
	local sc = B.fresh(B.WIN, { ship = { objectName = "player_sorosuub_space_yacht" } })
	local o = sc.o

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))
	lu.assertEquals(#sc:waypoints(), 0, "no setup in the yacht at start")
	lu.assertFalse(sc:taskComplete(0), "task 0 not complete in the yacht")

	H.zoneSwitch(sc.player, o.zone)
	H.advance(secs(5))
	lu.assertEquals(#sc:waypoints(), 0, "no setup after a zone switch that keeps the yacht")

	H.zoneSwitch(sc.player, o.zone, { ship = { x = o.point.x, z = o.point.z, y = o.point.y } })
	H.advance(secs(1))
	lu.assertEquals(#sc:waypoints(), 1, "set up once the player flies a ship")
end

-- AC-3, Behavior 4
function TestSpaceBattleSetup:test_a_zone_switch_to_a_third_zone_before_setup_changes_nothing()
	local sc = B.fresh(B.WIN, { zone = B.ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))

	local eventsBefore = #H.Engine.callsTo("createEvent")

	H.zoneSwitch(sc.player, B.THIRD_ZONE)
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "the quest stays active")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), eventsBefore, "no event was created")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED observer stays")
end

-- AC-3, Behavior 4
function TestSpaceBattleSetup:test_entered_zone_returns_1_for_an_inactive_quest_and_0_for_an_active_one()
	local sc = B.fresh(B.WIN, { zone = B.ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(B.THIRD_ZONE)), 0, "an active quest keeps the observer")

	sc.quest:failQuest(sc.player, "false")
	lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(sc.o.zone)), 1, "an inactive quest drops the observer")
end

-- AC-3, Behavior 1
function TestSpaceBattleSetup:test_an_empty_string_npc_works_like_no_npc()
	local sc = B.fresh(B.WIN)

	lu.assertTrue(pcall(function() sc.quest:startQuest(sc.player, "") end), "startQuest(player, \"\") raises no error")
	lu.assertTrue(sc:active(), "active")
end

TestSpaceBattleDataGuard = {}

function TestSpaceBattleDataGuard:setUp() H.reset() end

-- AC-3, Behavior 2
function TestSpaceBattleDataGuard:test_an_empty_enemy_force_logs_an_error_and_fails_the_quest_without_spawning_or_adding_a_waypoint()
	local sc = B.fresh(B.WIN)

	B.withFields(sc.global, { enemyForce = {} }, function()
		sc:start()
		H.advance(secs(2000))

		lu.assertTrue(#B.errorLogs() >= 1, "an LT_ERROR was logged")
		lu.assertTrue(B.errorLogs()[1]:find(sc.className, 1, true) ~= nil, "the error names the class: " .. tostring(B.errorLogs()[1]))
		lu.assertFalse(sc:active(), "the quest is not active afterwards")
		lu.assertEquals(#spawnCalls(), 0, "no ship was spawned")
		lu.assertEquals(#sc:waypoints(), 0, "no waypoint exists")
		lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no run key is left")
	end)
end

-- AC-3, Behavior 2
function TestSpaceBattleDataGuard:test_an_empty_ally_force_or_a_missing_battle_point_name_fails_the_same_way()
	local cases = {
		{ "empty allyForce", { allyForce = {} } },
		{ "battlePoint without a patrolPointName", { battlePoint = { x = 1, z = 2, y = 3 } } },
	}

	for _, case in ipairs(cases) do
		local sc = B.fresh(B.WIN)

		B.withFields(sc.global, case[2], function()
			sc:start()
			H.advance(secs(2000))

			lu.assertTrue(#B.errorLogs() >= 1, case[1] .. ": an LT_ERROR was logged")
			lu.assertFalse(sc:active(), case[1] .. ": the quest is not active afterwards")
			lu.assertEquals(#spawnCalls(), 0, case[1] .. ": no ship was spawned")
			lu.assertEquals(#sc:waypoints(), 0, case[1] .. ": no waypoint exists")
		end)
	end
end

TestSpaceBattleArrival = {}

function TestSpaceBattleArrival:setUp() H.reset() end

local function assertSpawnCalls(calls, force, zone, pos, label)
	lu.assertEquals(#calls, #force, label .. ": number of spawnShipAgent calls")

	for i, name in ipairs(force) do
		local c = calls[i]

		lu.assertEquals(c[1], name, label .. ": ship " .. i .. " template")
		lu.assertEquals(c[2], zone, label .. ": ship " .. i .. " zone")
		near(c[3], pos.x, label .. ": ship " .. i .. " x")
		near(c[4], pos.z, label .. ": ship " .. i .. " z")
		near(c[5], pos.y, label .. ": ship " .. i .. " y")
		lu.assertNil(c[6], label .. ": ship " .. i .. " is spawned with five arguments, no facing target")
	end
end

-- AC-4
function TestSpaceBattleArrival:test_each_force_spawns_at_its_arrival_delay_and_not_one_ms_earlier()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local o = sc.o
		local first, second = o.allyDelay, o.enemyDelay
		local firstCount, secondCount = #o.allyForce, #o.enemyForce

		if o.enemyDelay < o.allyDelay then
			first, second = o.enemyDelay, o.allyDelay
			firstCount, secondCount = #o.enemyForce, #o.allyForce
		end

		H.advance(secs(first) - 1)
		lu.assertEquals(#spawnCalls(), 0, name .. ": no ship one ms before the first arrival")

		H.advance(1)
		lu.assertEquals(#spawnCalls(), firstCount, name .. ": the first force spawns at its delay")

		H.advance(secs(second - first) - 1)
		lu.assertEquals(#spawnCalls(), firstCount, name .. ": nothing more one ms before the second arrival")

		H.advance(1)
		lu.assertEquals(#spawnCalls(), firstCount + secondCount, name .. ": the second force spawns at its delay")
	end
end

-- AC-4
function TestSpaceBattleArrival:test_allies_spawn_in_force_order_at_the_nav_point_plus_arrival_dist_times_forward()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()

		sc:allies()
		local calls = spawnCalls()
		local only = {}

		for i, c in ipairs(calls) do
			if H.Engine.timedCallsTo("spawnShipAgent")[i].t == secs(sc.o.allyDelay) then
				only[#only + 1] = c
			end
		end

		assertSpawnCalls(only, sc.o.allyForce, sc.o.zone, sc.o.allyPos, name .. " allies")
	end
end

-- AC-4
function TestSpaceBattleArrival:test_enemies_spawn_in_force_order_at_the_nav_point_plus_arrival_dist_times_forward()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()

		sc:enemies()
		local only = {}

		for i, c in ipairs(spawnCalls()) do
			if H.Engine.timedCallsTo("spawnShipAgent")[i].t == secs(sc.o.enemyDelay) then
				only[#only + 1] = c
			end
		end

		assertSpawnCalls(only, sc.o.enemyForce, sc.o.zone, sc.o.enemyPos, name .. " enemies")
	end
end

-- AC-4, Data mapping (Spawn position)
function TestSpaceBattleArrival:test_each_ship_gets_a_random_x_then_y_offset_and_z_is_unchanged()
	local sc = B.fresh(B.WIN):setup()
	local o = sc.o
	local n = #o.allyForce
	local draws = {}

	for i = 1, n do
		draws[#draws + 1] = -90 + i * 10  -- x offset of ship i
		draws[#draws + 1] = 70 - i * 5    -- y offset of ship i
	end

	H.Engine.nextRandom = nil
	H.Engine.queueRandom(-B.FORMATION_SPREAD, B.FORMATION_SPREAD, table.unpack(draws))

	sc:allies()

	local calls = spawnCalls()

	lu.assertEquals(#calls, n, "one spawn per ally")

	for i = 1, n do
		near(calls[i][3], o.allyPos.x + draws[2 * i - 1], "ship " .. i .. ": x = position + first draw")
		near(calls[i][4], o.allyPos.z, "ship " .. i .. ": z unchanged")
		near(calls[i][5], o.allyPos.y + draws[2 * i], "ship " .. i .. ": y = position + second draw")
	end
end

-- AC-4
function TestSpaceBattleArrival:test_allies_never_attack_the_player_and_are_marked_as_friends()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local allies = sc:allies()
		local h = SpaceHelpers:getPlayerShipFactionHash(sc.player)

		lu.assertTrue(h ~= 0, name .. ": precondition, the player's ship has a faction hash")

		for i, a in ipairs(allies) do
			lu.assertEquals(a.missionOwner, sc.player, name .. ": ally " .. i .. " setMissionOwner(player)")
			lu.assertEquals(a.removedFactionEnemies, { h }, name .. ": ally " .. i .. " removeSpaceFactionEnemy(h)")
			lu.assertEquals(a.factionAllies, { h }, name .. ": ally " .. i .. " addSpaceFactionAlly(h)")
			lu.assertEquals(a.factionEnemies, {}, name .. ": ally " .. i .. " never addSpaceFactionEnemy")
		end
	end
end

-- AC-4
function TestSpaceBattleArrival:test_enemies_are_hostile_to_the_player_and_get_no_ally_calls()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local enemies = sc:enemies()
		local h = SpaceHelpers:getPlayerShipFactionHash(sc.player)

		for i, e in ipairs(enemies) do
			lu.assertEquals(e.missionOwner, sc.player, name .. ": enemy " .. i .. " setMissionOwner(player)")
			lu.assertEquals(e.factionEnemies, { h }, name .. ": enemy " .. i .. " addSpaceFactionEnemy(h)")
			lu.assertEquals(e.factionAllies, {}, name .. ": enemy " .. i .. " no addSpaceFactionAlly")
			lu.assertEquals(e.removedFactionEnemies, {}, name .. ": enemy " .. i .. " no removeSpaceFactionEnemy")
		end
	end
end

-- AC-4
function TestSpaceBattleArrival:test_each_force_forms_a_squadron_led_by_its_first_ship()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local allies, enemies = sc:both()

		for side, force in pairs({ ally = allies, enemy = enemies }) do
			lu.assertTrue(force[1].isSquadronLeader, name .. ": first " .. side .. " calls createSquadron")
			lu.assertNil(force[1].squadronLeader, name .. ": first " .. side .. " is not assigned to a squadron")

			for i = 2, #force do
				lu.assertEquals(force[i].squadronLeader, force[1], name .. ": " .. side .. " " .. i .. " assignToSquadron(first)")
				lu.assertFalse(force[i].isSquadronLeader, name .. ": " .. side .. " " .. i .. " is not a squadron leader")
			end
		end
	end
end

-- AC-4
function TestSpaceBattleArrival:test_each_ship_is_added_as_a_mission_object_and_the_last_of_the_force_is_flagged()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local allies, enemies = sc:both()
		local adds = B.missionAdds(sc.player)
		local position, flag = {}, {}

		lu.assertEquals(#adds, #allies + #enemies, name .. ": one addSpaceMissionObject per ship")

		for i, add in ipairs(adds) do
			position[add.id] = i
			flag[add.id] = add.last
		end

		for side, force in pairs({ ally = allies, enemy = enemies }) do
			for i, ship in ipairs(force) do
				lu.assertNotNil(position[ship.objectID], name .. ": " .. side .. " " .. i .. " is a mission object")
				lu.assertEquals(flag[ship.objectID], i == #force, name .. ": " .. side .. " " .. i .. " isLast flag")

				if i > 1 then
					lu.assertTrue(position[ship.objectID] > position[force[i - 1].objectID], name .. ": " .. side .. " " .. i .. " is added after ship " .. (i - 1))
				end
			end
		end
	end
end

-- AC-4
function TestSpaceBattleArrival:test_every_force_ship_has_one_ship_destroyed_observer()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local allies, enemies = sc:both()

		for _, ship in ipairs(allies) do
			lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyBattleShipDestroyed", ship), 1, name .. ": ally SHIPDESTROYED observer")
		end

		for _, ship in ipairs(enemies) do
			lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyBattleShipDestroyed", ship), 1, name .. ": enemy SHIPDESTROYED observer")
		end
	end
end

-- AC-4
function TestSpaceBattleArrival:test_each_arrival_sends_its_update_and_effect_once()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local o = sc.o
		local sides = {
			ally = { key = "allies_arrived", effect = B.ALLY_EFFECT, delay = o.allyDelay },
			enemy = { key = "enemies_arrived", effect = B.ENEMY_EFFECT, delay = o.enemyDelay },
		}
		local order = o.allyDelay < o.enemyDelay and { "ally", "enemy" } or { "enemy", "ally" }

		lu.assertEquals(B.effects(sc.player, B.ALLY_EFFECT) + B.effects(sc.player, B.ENEMY_EFFECT), 0, name .. ": no spawn effect before an arrival")

		sc:at(secs(sides[order[1]].delay))
		lu.assertEquals(B.count(sc:events(), sides[order[1]].key, "update"), 1, name .. ": " .. sides[order[1]].key .. " once")
		lu.assertEquals(B.effects(sc.player, sides[order[1]].effect), 1, name .. ": " .. order[1] .. " spawn effect once")
		lu.assertEquals(B.count(sc:events(), sides[order[2]].key), 0, name .. ": " .. sides[order[2]].key .. " not yet")
		lu.assertEquals(B.effects(sc.player, sides[order[2]].effect), 0, name .. ": " .. order[2] .. " spawn effect not yet")

		sc:at(secs(sides[order[2]].delay))
		lu.assertEquals(B.count(sc:events(), sides[order[2]].key, "update"), 1, name .. ": " .. sides[order[2]].key .. " once")
		lu.assertEquals(B.effects(sc.player, sides[order[2]].effect), 1, name .. ": " .. order[2] .. " spawn effect once")

		H.advance(secs(1400))
		lu.assertEquals(B.count(sc:events(), "allies_arrived", "update"), 1, name .. ": allies_arrived stays at one")
		lu.assertEquals(B.count(sc:events(), "enemies_arrived", "update"), 1, name .. ": enemies_arrived stays at one")
		lu.assertEquals(B.effects(sc.player, B.ALLY_EFFECT), 1, name .. ": one friendly spawn effect in all")
		lu.assertEquals(B.effects(sc.player, B.ENEMY_EFFECT), 1, name .. ": one enemy spawn effect in all")
	end
end

-- AC-4, I-8
function TestSpaceBattleArrival:test_no_ship_is_engaged_before_the_second_force_has_arrived()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local o = sc.o
		local firstSecs = math.min(o.allyDelay, o.enemyDelay)

		sc:at(secs(firstSecs))

		local ships = H.spawnedShips()

		lu.assertTrue(#ships > 0, name .. ": precondition, the first force is present")
		lu.assertEquals(B.engageCount(ships), 0, name .. ": no engageShipTarget call before the second force arrives")
		lu.assertEquals(B.count(sc:events(), "battle_started"), 0, name .. ": no battle_started yet")
	end
end

-- AC-4, Behavior 5
function TestSpaceBattleArrival:test_a_failed_spawn_logs_an_error_and_fails_the_quest()
	local sc = B.fresh(B.WIN):setup()

	H.Engine.config.spawnFails = true
	H.advance(secs(sc.o.allyDelay))

	lu.assertTrue(#B.errorLogs() >= 1, "an LT_ERROR was logged at the first force arrival")
	lu.assertFalse(sc:active(), "the quest failed")

	H.Engine.config.spawnFails = false
	H.advance(secs(2000))
	lu.assertEquals(#H.spawnedShips(), 0, "nothing spawned afterwards (the run is over)")
	lu.assertEquals(B.count(sc:events(), "battle_started"), 0, "no battle")
end

-- AC-4, Behavior 5 (R-1): the arrival update and effect do not depend on the spawns; the failure follows them
function TestSpaceBattleArrival:test_a_force_whose_spawns_all_fail_still_sends_its_arrived_update_and_effect_then_fails_the_quest()
	local cases = {
		{ B.WIN, "allies_arrived", B.ALLY_EFFECT, B.ENEMY_EFFECT, "enemies_arrived", "allyDelay" },
		{ B.LOSE, "enemies_arrived", B.ENEMY_EFFECT, B.ALLY_EFFECT, "allies_arrived", "enemyDelay" },
	}

	for _, case in ipairs(cases) do
		local name, key, effect, otherEffect, otherKey, delayField = case[1], case[2], case[3], case[4], case[5], case[6]
		local sc = B.fresh(name):setup()

		H.Engine.config.spawnFails = true
		sc:at(secs(sc.o[delayField]))

		lu.assertEquals(#H.spawnedShips(), 0, name .. ": no ship exists")
		lu.assertEquals(#spawnCalls(), #(delayField == "allyDelay" and sc.o.allyForce or sc.o.enemyForce), name .. ": every template was tried")
		lu.assertEquals(B.count(sc:events(), key, "update"), 1, name .. ": " .. key .. " is sent even though nothing spawned")
		lu.assertEquals(B.effects(sc.player, effect), 1, name .. ": the spawn effect is played even though nothing spawned")
		lu.assertEquals(B.count(sc:events(), otherKey), 0, name .. ": nothing for the other force")
		lu.assertEquals(B.effects(sc.player, otherEffect), 0, name .. ": no effect for the other force")
		lu.assertTrue(#B.errorLogs() >= 1, name .. ": an LT_ERROR was logged")
		lu.assertFalse(sc:active(), name .. ": the quest failed")
		lu.assertEquals(B.count(sc:events(), "battle_started"), 0, name .. ": no battle started")
		lu.assertEquals(B.runKeys(sc.player, sc.className), {}, name .. ": no run key is left")

		H.Engine.config.spawnFails = false
		H.advance(secs(4000))
		lu.assertEquals(#H.spawnedShips(), 0, name .. ": nothing spawns afterwards")
		lu.assertEquals(B.count(sc:events(), otherKey), 0, name .. ": the other force never arrives (the run is over)")
	end
end

-- AC-4, edge: a single-ship force
function TestSpaceBattleArrival:test_a_one_ship_force_leads_its_own_squadron_and_flags_its_only_mission_object_as_last()
	local sc = B.fresh(B.WIN)

	B.withFields(sc.global, { allyForce = { "corsec_interceptor_tier4" } }, function()
		sc:setup()
		sc:at(secs(sc.o.allyDelay))

		local ships = sc:spawnedAt(sc.o.allyDelay)

		lu.assertEquals(#ships, 1, "one ally spawns")
		lu.assertTrue(ships[1].isSquadronLeader, "the only ally creates the squadron")
		lu.assertNil(ships[1].squadronLeader, "the only ally is not assigned to a squadron")
		lu.assertEquals(B.missionAdds(sc.player), { { id = ships[1].objectID, last = true } }, "its mission object is the last of the force")
	end)
end

TestSpaceBattleStart = {}

function TestSpaceBattleStart:setUp() H.reset() end

-- AC-5
function TestSpaceBattleStart:test_the_battle_starts_once_when_the_second_force_arrives()
	local sc = B.fresh(B.LOSE):setup()
	local o = sc.o

	lu.assertEquals({ o.enemyDelay, o.allyDelay }, { 30, 60 }, "precondition: enemies arrive first at 30 s, allies at 60 s")

	local enemies = sc:enemies()

	lu.assertEquals(B.count(sc:events(), "battle_started"), 0, "no battle_started at 30 s")
	lu.assertTrue(sc:taskActive(1), "task 1 is still active at 30 s")
	lu.assertFalse(sc:taskActive(2) or sc:taskComplete(2), "task 2 untouched at 30 s")
	lu.assertEquals(B.engageCount(enemies), 0, "no enemy engages anything at 30 s")

	local allies = sc:allies()
	local started = B.only(sc:events(), "battle_started", "update")

	lu.assertEquals(#started, 1, "battle_started sent once at 60 s")
	lu.assertEquals(started[1].t, secs(60), "battle_started time")
	lu.assertTrue(sc:taskComplete(1), "task 1 complete")
	lu.assertTrue(sc:taskActive(2), "task 2 (quest_helpallies) active")
	lu.assertEquals(#allies + #enemies, 15, "5 allies and 10 enemies are present")

	H.advance(secs(1400 - 60))
	lu.assertEquals(B.count(sc:events(), "battle_started"), 1, "battle_started stays at one without kills")
end

-- AC-5
function TestSpaceBattleStart:test_at_battle_start_each_ship_engages_one_ship_of_the_other_force_round_robin()
	local sc = B.fresh(B.LOSE):setup()

	local enemies = sc:enemies()
	local allies = sc:allies()

	for i, a in ipairs(allies) do
		lu.assertEquals(#a.engageLog, 1, "ally " .. i .. ": exactly one engageShipTarget call")
		lu.assertEquals(a.engageLog[1].t, secs(60), "ally " .. i .. ": engaged at battle start")
		lu.assertEquals(a.engageLog[1].target, enemies[i], "ally " .. i .. " engages enemy " .. i)
	end

	local wantAllyIndex = { 1, 2, 3, 4, 5, 1, 2, 3, 4, 5 }

	for j, e in ipairs(enemies) do
		lu.assertEquals(#e.engageLog, 1, "enemy " .. j .. ": exactly one engageShipTarget call")
		lu.assertEquals(e.engageLog[1].t, secs(60), "enemy " .. j .. ": engaged at battle start")
		lu.assertEquals(e.engageLog[1].target, allies[wantAllyIndex[j]], "enemy " .. j .. " engages ally " .. wantAllyIndex[j])
	end

	B.assertEngageInvariant(allies, enemies, "4_3 at battle start")
end

-- AC-5 (mirrored: the allies arrive first)
function TestSpaceBattleStart:test_when_the_allies_arrive_first_the_pairing_is_the_same_rule()
	local sc = B.fresh(B.ALLIES_FIRST):setup()

	lu.assertEquals({ sc.o.allyDelay, sc.o.enemyDelay }, { 20, 35 }, "precondition: allies at 20 s, enemies at 35 s")

	local allies = sc:allies()

	lu.assertEquals(B.engageCount(allies), 0, "no ally engages anything at 20 s")

	local enemies = sc:enemies()
	local started = B.only(sc:events(), "battle_started", "update")

	lu.assertEquals(#started, 1, "battle_started once")
	lu.assertEquals(started[1].t, secs(35), "battle_started at 35 s")

	for i = 1, 3 do
		lu.assertEquals(B.targetsOf(allies[i]), { enemies[i] }, "ally " .. i .. " engages enemy " .. i)
	end

	local wantAllyIndex = { 1, 2, 3, 1, 2, 3 }

	for j = 1, 6 do
		lu.assertEquals(B.targetsOf(enemies[j]), { allies[wantAllyIndex[j]] }, "enemy " .. j .. " engages ally " .. wantAllyIndex[j])
	end
end

-- AC-5, table-driven over all 13 (the round robin rule computed here from the spec)
function TestSpaceBattleStart:test_the_round_robin_pairing_holds_for_every_quest()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local allies, enemies = sc:both()
		local allyTargets, enemyTargets = B.pairing(allies, enemies)

		for i, a in ipairs(allies) do
			lu.assertEquals(B.targetsOf(a), { allyTargets[i] }, name .. ": ally " .. i .. " target")
		end

		for j, e in ipairs(enemies) do
			lu.assertEquals(B.targetsOf(e), { enemyTargets[j] }, name .. ": enemy " .. j .. " target")
		end

		B.assertEngageInvariant(allies, enemies, name)
	end
end

-- AC-5, I-8
function TestSpaceBattleStart:test_no_engage_call_is_made_after_battle_start_without_a_kill()
	local sc = B.fresh(B.LOSE):setup()
	local allies, enemies = sc:both()
	local before = B.engageCount(allies) + B.engageCount(enemies)

	H.advance(secs(1400))

	lu.assertEquals(B.engageCount(allies) + B.engageCount(enemies), before, "no further engage calls over 1400 s without kills")
end

-- AC-5
function TestSpaceBattleStart:test_a_kill_before_the_second_force_arrives_is_skipped_in_the_initial_pairing_and_engages_nobody()
	local sc = B.fresh(B.LOSE):setup()
	local enemies = sc:at(secs(40)):spawnedAt(sc.o.enemyDelay)

	lu.assertEquals(#enemies, 10, "precondition: 10 enemies present at 40 s")

	sc:kill(enemies[1])

	lu.assertEquals(B.engageCount(enemies), 0, "a kill before the battle starts engages nobody")
	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 9 }, "the kill still reports 9 enemies remaining")

	local allies = sc:allies()

	for i, a in ipairs(allies) do
		lu.assertEquals(B.targetsOf(a), { enemies[i + 1] }, "ally " .. i .. " engages enemy " .. (i + 1) .. " (enemy 1 is dead)")
	end

	local liveEnemies = B.alive(enemies)
	local wantAllyIndex = { 1, 2, 3, 4, 5, 1, 2, 3, 4 }

	for j, e in ipairs(liveEnemies) do
		lu.assertEquals(B.targetsOf(e), { allies[wantAllyIndex[j]] }, "live enemy " .. j .. " engages ally " .. wantAllyIndex[j])
	end

	lu.assertEquals(B.engageCount({ enemies[1] }), 0, "the dead enemy engages nothing")
	B.assertEngageInvariant(allies, enemies, "4_3 after an early kill")
end

-- Behavior 6
function TestSpaceBattleStart:test_a_battle_with_one_force_missing_a_scene_object_skips_that_pair_without_an_error()
	local sc = B.fresh(B.WIN):setup()
	local allies = sc:allies()

	-- the first ally vanishes from the world (a despawn) before the enemies arrive; its observer dies with it
	H.Fakes.destroy(allies[1])

	local ok, err = pcall(function() sc:enemies() end)

	lu.assertTrue(ok, "the battle start raises no error with a vanished ally: " .. tostring(err))
	lu.assertEquals(B.engageCount({ allies[1] }), 0, "the vanished ally engages nothing")
	lu.assertEquals(B.count(sc:events(), "battle_started", "update"), 1, "the battle still starts")
end
