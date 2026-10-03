-- Survival quest start, setup and arrival (space-quest-stub-survival).
-- Spec: .claude/work/space-quest-stub-survival/01-spec.md (AC-2, AC-3, AC-4, Behavior 1 to 3).
-- Expected numbers come from the SWG-Source fixtures through survival_scenario.lua, not from the
-- Core3 tables under test.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

S.load()

local AREA_TEMPLATE = "object/space_active_area.iff"
local ELSEWHERE = "space_tatooine"

-- Shorthand for the waypoint list of a scenario's player.
local function waypoints(sc) return sc.player.ghost.waypoints end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

TestSurvivalNoAutoComplete = {}

function TestSurvivalNoAutoComplete:setUp()
	H.reset()
end

-- AC-2
function TestSurvivalNoAutoComplete:test_started_in_the_zone_with_no_arrival_the_quest_stays_active_for_an_hour()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name):start()

		H.advance(3600 * 1000)

		lu.assertTrue(sc:active(), name .. ": journal quest still active after 3600 s without arrival")
		lu.assertFalse(sc:complete(), name .. ": journal quest must not be complete")
		lu.assertEquals(#S.createEvents("completeQuest"), 0, name .. ": no completeQuest event was ever created")
		lu.assertEquals(S.called(sc.spies.start), {}, name .. ": no follow-up quest was started")
	end
end

-- AC-2
function TestSurvivalNoAutoComplete:test_started_elsewhere_the_quest_stays_active_for_an_hour()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name, { zone = ELSEWHERE })

		sc.quest:startQuest(sc.player, "")
		H.advance(3600 * 1000)

		lu.assertTrue(sc:active(), name .. ": journal quest still active")
		lu.assertFalse(sc:complete(), name .. ": journal quest must not be complete")
		lu.assertEquals(#S.createEvents("completeQuest"), 0, name .. ": no completeQuest event was ever created")
	end
end

-- rsf-tier3-renames: the two RSF placeholder tests (auto-complete after 500 ms, empty npc argument) were removed
-- with the placeholder; destroy_surpriseattack 4c-4e replace it.

TestSurvivalSetup = {}

function TestSurvivalSetup:setUp()
	H.reset()
end

-- AC-3
function TestSurvivalSetup:test_started_in_the_quest_zone_sets_up_tasks_waypoint_area_and_found_loc()
	for _, name in ipairs(S.NAMES) do
		H.reset()

		local sc = S.new(name):start()
		local o, q = sc.o, "survival/" .. name

		lu.assertTrue(sc:active(), q .. ": journal quest active")
		lu.assertTrue(sc:taskComplete(0), q .. ": task 0 complete")
		lu.assertTrue(sc:taskActive(1), q .. ": task 1 active")
		lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), q .. ": ZONESWITCHED observer registered")
		lu.assertEquals(H.Engine.observerCount(ZONESWITCHED, sc.className, "enteredZone", sc.player), 1, q .. ": exactly one ZONESWITCHED observer")

		local wps = waypoints(sc)

		lu.assertEquals(#wps, 1, q .. ": exactly one waypoint")
		lu.assertEquals(wps[1].planet, o.zone, q .. ": waypoint planet")
		lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { o.x, o.z, o.y }, q .. ": waypoint x, z, y at the transmission point")
		lu.assertEquals(wps[1].color, WAYPOINT_SPACE, q .. ": waypoint color")
		lu.assertEquals(wps[1].name, "Mission Objective", q .. ": waypoint name (survival.java:132)")
		lu.assertEquals(wps[1].special, WAYPOINTQUESTTASK, q .. ": waypoint special type")
		lu.assertEquals(wps[1].questDetails, "@spacequest/survival/" .. name .. ":title_d", q .. ": waypoint quest details")
		lu.assertEquals(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), tostring(wps[1].objectID), q .. ": waypoint id stored for clearQuestWaypoint")

		local calls = areaCalls()

		lu.assertEquals(#calls, 1, q .. ": exactly one spawnSpaceActiveArea call")
		lu.assertEquals({ calls[1][1], calls[1][2], calls[1][3], calls[1][4], calls[1][5], calls[1][6] },
			{ o.zone, AREA_TEMPLATE, o.x, o.z, o.y, 150 }, q .. ": spawnSpaceActiveArea(zone, template, x, z, y, radius)")
		lu.assertEquals(H.Engine.observersOn(sc:area(), ENTEREDAREA), { { type = ENTEREDAREA, sp = sc.className, method = "notifyEnteredQuestArea" } },
			q .. ": one ENTEREDAREA observer on the area")

		lu.assertEquals(S.count(sc:events(), "found_loc", "update"), 1, q .. ": one found_loc update")
		lu.assertEquals(S.count(sc:events(), "arrived_at_loc"), 0, q .. ": no arrival yet")
	end
end

-- AC-3
function TestSurvivalSetup:test_started_elsewhere_nothing_is_set_up_until_the_player_enters_the_zone()
	for _, name in ipairs(S.NAMES) do
		H.reset()

		local sc = S.new(name, { zone = ELSEWHERE })
		local q = "survival/" .. name

		sc.quest:startQuest(sc.player, "")
		H.advance(2000)

		lu.assertTrue(sc:active(), q .. ": journal quest active")
		lu.assertFalse(sc:taskComplete(0), q .. ": task 0 not complete yet")
		lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), q .. ": waiting for ZONESWITCHED")
		lu.assertEquals(#waypoints(sc), 0, q .. ": no waypoint")
		lu.assertEquals(#areaCalls(), 0, q .. ": no area")
		lu.assertEquals(S.count(sc:events(), "found_loc"), 0, q .. ": no found_loc")

		H.zoneSwitch(sc.player, sc.o.zone)
		H.advance(2000)

		lu.assertTrue(sc:taskComplete(0), q .. ": task 0 complete after entering the zone")
		lu.assertTrue(sc:taskActive(1), q .. ": task 1 active after entering the zone")
		lu.assertEquals(#waypoints(sc), 1, q .. ": one waypoint")
		lu.assertEquals(#areaCalls(), 1, q .. ": one area")
		lu.assertEquals(S.count(sc:events(), "found_loc", "update"), 1, q .. ": one found_loc")
	end
end

-- AC-3
function TestSurvivalSetup:test_entering_another_zone_first_does_nothing()
	local sc = S.fresh("corellia_rebel_tier4_1", { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.zoneSwitch(sc.player, "space_endor")
	H.advance(2000)

	lu.assertEquals(#waypoints(sc), 0, "no waypoint for the wrong zone")
	lu.assertEquals(#areaCalls(), 0, "no area for the wrong zone")
	lu.assertFalse(sc:taskComplete(0), "task 0 untouched")
	lu.assertTrue(sc:active(), "journal quest active")
end

-- AC-3
function TestSurvivalSetup:test_entering_the_zone_again_before_arrival_adds_nothing()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()

	H.zoneSwitch(sc.player, sc.o.zone)
	H.zoneSwitch(sc.player, ELSEWHERE)
	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(5000)

	lu.assertEquals(#waypoints(sc), 1, "still one waypoint")
	lu.assertEquals(#areaCalls(), 1, "still one area")
	lu.assertEquals(S.count(sc:events(), "found_loc"), 1, "still one found_loc")
	lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", sc:area()), 1, "still one area observer")
	lu.assertTrue(sc:active(), "quest still active")
end

-- AC-3
function TestSurvivalSetup:test_a_player_in_the_yacht_gets_no_setup_in_or_on_entering_the_zone()
	local sc = S.fresh("corellia_rebel_tier4_1", { ship = { objectName = "player_sorosuub_space_yacht" } })

	sc.quest:startQuest(sc.player, "")
	H.advance(2000)

	lu.assertEquals(#waypoints(sc), 0, "no waypoint in the yacht")
	lu.assertEquals(#areaCalls(), 0, "no area in the yacht")
	lu.assertFalse(sc:taskComplete(0), "task 0 untouched")

	H.zoneSwitch(sc.player, ELSEWHERE)
	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(2000)

	lu.assertEquals(#waypoints(sc), 0, "still nothing after a zone switch in the yacht")
	lu.assertEquals(#areaCalls(), 0, "still no area")
	lu.assertTrue(sc:active(), "journal quest active")
end

-- AC-3
function TestSurvivalSetup:test_a_player_without_a_ship_gets_no_setup()
	local sc = S.fresh("corellia_rebel_tier4_1", { ship = false })

	sc.quest:startQuest(sc.player, "")
	H.advance(2000)

	lu.assertEquals(#waypoints(sc), 0, "no waypoint without a ship")
	lu.assertEquals(#areaCalls(), 0, "no area without a ship")
	lu.assertTrue(sc:active(), "journal quest active")
end

-- AC-3
function TestSurvivalSetup:test_the_zone_observer_is_registered_once_even_if_the_quest_is_started_twice()
	local sc = S.fresh("corellia_rebel_tier4_1", { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	sc.quest:startQuest(sc.player, "")

	lu.assertEquals(H.Engine.observerCount(ZONESWITCHED, sc.className, "enteredZone", sc.player), 1)
end

-- AC-3 (Behavior 1)
function TestSurvivalSetup:test_start_events_pass_an_empty_string_npc_like_the_trainers_do()
	local sc = S.fresh("corellia_rebel_tier4_1")

	createEvent(100, sc.className, "startQuest", sc.player, "")
	H.advance(2100)

	lu.assertTrue(sc:active(), "started through an event with args ''")
	lu.assertEquals(#waypoints(sc), 1)
end

TestSurvivalGroundLaunch = {}

function TestSurvivalGroundLaunch:setUp()
	H.reset()
end

-- A player on the ground (in a starport) who takes the quest and then launches. The server fires
-- ZONESWITCHED before it moves the player (PlayerSpaceZoneComponent::switchZone), so inside the
-- observer the player is still in the starport and the ship does not exist yet.
local function groundPlayerWithQuest(opts)
	local sc = S.fresh("corellia_rebel_tier4_1", opts)

	sc.quest:startQuest(sc.player, "")
	H.advance(2000)
	lu.assertEquals(#waypoints(sc), 0, "precondition: nothing is set up on the ground")
	return sc
end

-- AC-3, R-3
function TestSurvivalGroundLaunch:test_launching_the_yacht_from_a_starport_gets_no_setup()
	local sc = groundPlayerWithQuest({ zone = "tatooine", ship = false, player = H.newPlayer({ zone = "tatooine", parent = "starport" }) })

	H.zoneSwitch(sc.player, sc.o.zone, { ship = { objectName = "player_sorosuub_space_yacht" } })
	H.advance(5000)

	lu.assertEquals(#waypoints(sc), 0, "no waypoint for a yacht")
	lu.assertEquals(#areaCalls(), 0, "no area for a yacht")
	lu.assertFalse(sc:taskComplete(0), "task 0 untouched")
	lu.assertEquals(S.count(sc:events(), "found_loc"), 0, "no found_loc")
	lu.assertTrue(sc:active(), "the quest stays active")
end

-- AC-3, R-3
function TestSurvivalGroundLaunch:test_launching_a_combat_ship_from_a_starport_sets_the_quest_up_within_two_seconds()
	local sc = groundPlayerWithQuest({ zone = "tatooine", ship = false, player = H.newPlayer({ zone = "tatooine", parent = "starport" }) })

	H.zoneSwitch(sc.player, sc.o.zone, { ship = { x = sc.o.x, z = sc.o.z, y = sc.o.y } })
	H.advance(2000)

	lu.assertTrue(sc:taskComplete(0), "task 0 complete")
	lu.assertTrue(sc:taskActive(1), "task 1 active")
	lu.assertEquals(#waypoints(sc), 1, "one waypoint")
	lu.assertEquals(#areaCalls(), 1, "one area")
	lu.assertEquals(S.count(sc:events(), "found_loc", "update"), 1, "one found_loc")
end

-- AC-3, R-3 (a launch with no building parent, e.g. an outdoor terminal)
function TestSurvivalGroundLaunch:test_launching_a_combat_ship_with_no_root_parent_sets_the_quest_up()
	local sc = groundPlayerWithQuest({ zone = "tatooine", ship = false })

	H.zoneSwitch(sc.player, sc.o.zone, { ship = { x = sc.o.x, z = sc.o.z, y = sc.o.y } })
	H.advance(2000)

	lu.assertEquals(#waypoints(sc), 1, "one waypoint")
	lu.assertEquals(#areaCalls(), 1, "one area")
end

-- AC-3, R-3
function TestSurvivalGroundLaunch:test_launching_to_another_zone_from_a_starport_sets_nothing_up()
	local sc = groundPlayerWithQuest({ zone = "tatooine", ship = false, player = H.newPlayer({ zone = "tatooine", parent = "starport" }) })

	H.zoneSwitch(sc.player, ELSEWHERE, { ship = {} })
	H.advance(5000)

	lu.assertEquals(#waypoints(sc), 0, "no waypoint in the wrong zone")
	lu.assertEquals(#areaCalls(), 0, "no area in the wrong zone")
	lu.assertTrue(sc:active(), "quest active")
end

TestSurvivalArrival = {}

function TestSurvivalArrival:setUp()
	H.reset()
end

-- AC-4
function TestSurvivalArrival:test_the_players_own_ship_entering_the_area_starts_the_mission_for_every_quest()
	for _, name in ipairs(S.NAMES) do
		H.reset()

		local sc = S.new(name):start()
		local q = "survival/" .. name

		lu.assertFalse(sc:taskComplete(1), q .. ": task 1 open before arrival")

		sc:arrive()

		local events = sc:events()

		lu.assertEquals(S.count(events, "title", "progress"), 1, q .. ": quest_in_progress message with TO title")
		lu.assertEquals(S.count(events, "arrived_at_loc", "update"), 1, q .. ": arrived_at_loc update")
		lu.assertTrue(sc:taskComplete(1), q .. ": task 1 complete")
		lu.assertTrue(sc:taskActive(2), q .. ": task 2 active")
		lu.assertTrue(sc:active(), q .. ": still active")
	end
end

-- AC-4
function TestSurvivalArrival:test_an_ai_ship_entering_the_area_does_not_arrive()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()
	local ai = spawnShipAgent("blacksun_fighter_s03_tier4", sc.o.zone, 0, 0, 0)

	H.enterArea(sc:area(), ai)
	H.advance(400 * 1000)

	lu.assertEquals(S.count(sc:events(), "arrived_at_loc"), 0, "no arrival")
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 0, "no transmission")
	lu.assertFalse(sc:taskComplete(1), "task 1 still open")
	lu.assertTrue(sc:active(), "quest still active")
end

-- AC-4
function TestSurvivalArrival:test_a_player_ship_without_a_pilot_does_not_arrive_and_does_not_error()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()
	local empty = H.newShip({ pilot = nil })

	H.enterArea(sc:area(), empty)
	H.advance(400 * 1000)

	lu.assertEquals(S.count(sc:events(), "arrived_at_loc"), 0, "no arrival")
	lu.assertTrue(sc:active(), "quest still active")
end

-- AC-4
function TestSurvivalArrival:test_another_players_ship_without_the_quest_does_not_arrive_for_anyone()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()
	local other = H.newPlayer({ zone = sc.o.zone, ship = {} })

	H.enterArea(sc:area(), other.rootParent)
	H.advance(400 * 1000)

	lu.assertEquals(S.count(sc:events(), "arrived_at_loc"), 0, "owner did not arrive")
	lu.assertEquals(S.count(S.events(other, sc.name), "arrived_at_loc"), 0, "the other player got nothing")
	lu.assertEquals(#S.events(other, sc.name), 0, "the other player got no survival message at all")
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 0, "no transmission")
end

-- AC-4
function TestSurvivalArrival:test_a_second_player_on_the_same_quest_arrives_only_in_their_own_area()
	local first = S.fresh("corellia_rebel_tier4_1"):start()
	local second = S.new("corellia_rebel_tier4_1", { spies = first.spies }):start()
	local areas = H.spawnedAreas()

	lu.assertEquals(#areas, 2, "one area per player")

	-- second's ship flies into first's area
	H.enterArea(areas[1], second.ship)
	H.advance(2000)

	lu.assertEquals(S.count(first:events(), "arrived_at_loc"), 0, "first did not arrive")
	lu.assertEquals(S.count(second:events(), "arrived_at_loc"), 0, "second did not arrive in someone else's area")

	-- second's own area
	second:arrive(areas[2])

	lu.assertEquals(S.count(second:events(), "arrived_at_loc"), 1, "second arrived in their own area")
	lu.assertEquals(S.count(first:events(), "arrived_at_loc"), 0, "first still waiting")
	lu.assertFalse(first:taskComplete(1), "first's task 1 still open")
end

-- AC-4
function TestSurvivalArrival:test_a_second_entry_by_the_owner_does_not_start_a_second_timeline()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	H.enterArea(sc:area(), sc.ship)
	H.advance(400 * 1000)

	local events = sc:events()

	lu.assertEquals(S.count(events, "title", "progress"), 1, "one in-progress message")
	lu.assertEquals(S.count(events, "arrived_at_loc"), 1, "one arrival update")
	lu.assertEquals(S.count(events, "transmission_start"), 1, "one transmission_start")
	lu.assertEquals(S.count(events, "transmission_received"), 1, "one transmission_received")
	lu.assertEquals(S.count(events, "mission_complete"), 1, "one mission_complete")
end

-- AC-4
function TestSurvivalArrival:test_entering_the_area_without_the_quest_active_does_nothing()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()

	-- The player gave the quest up some other way; the area is still around.
	SpaceHelpers:failSpaceQuest(sc.player, "survival", sc.name, false)
	H.enterArea(sc:area(), sc.ship)
	H.advance(400 * 1000)

	lu.assertEquals(S.count(sc:events(), "arrived_at_loc"), 0, "no arrival for an inactive quest")
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 0, "no transmission")
	lu.assertFalse(sc:active(), "quest not revived")
end

-- Content contract: observers are registered under the quest instance's className
function TestSurvivalArrival:test_observers_and_events_are_registered_under_the_quest_instance_name()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	H.advance(30 * 1000)

	lu.assertEquals(sc.className, "survival_corellia_rebel_tier4_1")

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.screenplay, "SpaceSurvivalScreenplay", "pending event " .. e.method .. " must target the quest instance, not the shared class")
	end
end
