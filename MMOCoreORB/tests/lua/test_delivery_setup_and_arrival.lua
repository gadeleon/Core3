-- Delivery quest start, setup, arrival and transport warp-in (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (AC-2, AC-3, AC-4, Behavior 1 to 5).
-- Expected numbers come from the SWG-Source fixtures through delivery_scenario.lua, not from the
-- Core3 tables under test. Times are milliseconds.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")

D.load()

local function secs(n) return n * 1000 end

local ELSEWHERE = "space_tatooine"
local PICKUP_QUEST = { "delivery", "corellia_rebel_tier3_3" }       -- Havoc tier 3 mission 3 (Endor), 2 lists, SEQ
local NO_PICKUP = { "delivery_no_pickup", "corellia_rebel_tier4_2_a" }

local function fresh(q, opts) return D.fresh(q[1], q[2], opts) end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

TestDeliveryNoAutoComplete = {}

function TestDeliveryNoAutoComplete:setUp() H.reset() end

-- AC-2
function TestDeliveryNoAutoComplete:test_started_in_the_zone_with_no_arrival_every_quest_stays_active_for_an_hour()
	for _, q in ipairs(D.QUESTS) do
		local sc = fresh(q):start()

		H.advance(secs(3600))

		lu.assertTrue(sc:active(), q[2] .. ": journal quest still active after 3600 s without arrival")
		lu.assertFalse(sc:complete(), q[2] .. ": journal quest must not be complete")
		lu.assertEquals(#D.createEvents("completeQuest"), 0, q[2] .. ": no completeQuest event was ever created")
		lu.assertEquals(#sc:transports(), 0, q[2] .. ": no transport was spawned")
		lu.assertEquals(D.called(sc.spies.start), {}, q[2] .. ": no follow-up quest was started")
	end
end

-- AC-2
function TestDeliveryNoAutoComplete:test_started_in_another_zone_every_quest_stays_active_for_an_hour()
	for _, q in ipairs(D.QUESTS) do
		local sc = fresh(q, { zone = ELSEWHERE })

		sc.quest:startQuest(sc.player, "")
		H.advance(secs(3600))

		lu.assertTrue(sc:active(), q[2] .. ": journal quest still active")
		lu.assertEquals(#D.createEvents("completeQuest"), 0, q[2] .. ": no completeQuest event")
		lu.assertEquals(#D.spawns(), 0, q[2] .. ": no ship spawned")
	end
end

TestDeliverySetup = {}

function TestDeliverySetup:setUp() H.reset() end

local function checkSetup(q)
	local sc = fresh(q):start()
	local o = sc.o
	local first = o.pickup or o.delivery
	local wpName = o.hasPickup and "Pickup Rendezvous" or "Delivery Rendezvous"
	local foundKey = o.hasPickup and "found_loc_p" or "found_loc_d"
	local label = q[2]

	lu.assertTrue(sc:taskComplete(0), label .. ": task 0 complete")
	lu.assertTrue(sc:taskActive(1), label .. ": task 1 active")

	local wps = sc:waypoints()

	lu.assertEquals(#wps, 1, label .. ": exactly one waypoint")
	lu.assertEquals(wps[1].name, wpName, label .. ": waypoint name")
	lu.assertEquals(wps[1].planet, o.zone, label .. ": waypoint planet")
	lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { first.x, first.z, first.y }, label .. ": waypoint position")
	lu.assertEquals(wps[1].color, WAYPOINT_SPACE, label .. ": WAYPOINT_SPACE")
	lu.assertEquals(wps[1].special, WAYPOINTQUESTTASK, label .. ": WAYPOINTQUESTTASK")
	lu.assertEquals(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), tostring(wps[1].objectID), label .. ": waypointID quest status")

	local expectedDetails = o.hasPickup and "rendezvous1_d" or "rendezvous2_d"

	lu.assertNotNil(wps[1].questDetails, label .. ": waypoint has quest details")
	lu.assertNotNil(tostring(wps[1].questDetails):find(expectedDetails, 1, true), label .. ": quest details mention " .. expectedDetails .. ", got " .. tostring(wps[1].questDetails))

	local calls = areaCalls()

	lu.assertEquals(#calls, 1, label .. ": one spawnSpaceActiveArea call")
	lu.assertEquals({ calls[1][1], calls[1][2], calls[1][3], calls[1][4], calls[1][5], calls[1][6] },
		{ o.zone, D.AREA_TEMPLATE, first.x, first.z, first.y, 150 }, label .. ": area zone, template, position, radius")
	lu.assertTrue(H.hasObserver(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", sc:area()), label .. ": ENTEREDAREA observer on the area")
	lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", sc:area()), 1, label .. ": exactly one ENTEREDAREA observer")

	local events = sc:events()

	lu.assertEquals(D.count(events, "title", "progress"), 1, label .. ": one in-progress message with the title")
	lu.assertEquals(D.count(events, foundKey, "update"), 1, label .. ": one " .. foundKey .. " update")
	lu.assertEquals(D.count(events, "found_loc_d", "update") + D.count(events, "found_loc_p", "update"), 1, label .. ": no other found_loc update")
end

-- AC-3
function TestDeliverySetup:test_setup_runs_for_every_quest_started_in_its_zone_and_ship()
	for _, q in ipairs(D.QUESTS) do
		H.reset()
		checkSetup(q)
	end
end

-- AC-3
function TestDeliverySetup:test_no_pickup_quest_goes_straight_to_the_delivery_rendezvous()
	local sc = fresh(NO_PICKUP):start()
	local wps = sc:waypoints()

	lu.assertEquals(#wps, 1, "one waypoint after setup")
	lu.assertEquals(wps[1].name, "Delivery Rendezvous", "waypoint name")
	lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { 5242, 4462, -48 }, "the spec table's deliveryPoint coordinates")
	lu.assertEquals(D.count(sc:events(), "found_loc_p"), 0, "no pickup message")
end

-- AC-3, Behavior 2: the run token is the first area's id, stored apart from the current leg's area id
function TestDeliverySetup:test_the_run_token_and_current_area_id_are_stored_under_the_player_and_class()
	local sc = fresh(PICKUP_QUEST):start()
	local area = sc:area()

	lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "runID")), area.objectID, "runID = first area's object id")
	lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "areaID")), area.objectID, "areaID = current leg's area id")
end

-- AC-3
function TestDeliverySetup:test_starting_on_the_ground_does_nothing_until_the_player_switches_into_the_zone_plus_one_second()
	local sc = fresh(PICKUP_QUEST, { zone = ELSEWHERE, ship = false })

	sc.player.rootParent = H.Fakes.newContainer({ objectName = "starport" })
	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))

	lu.assertEquals(#areaCalls(), 0, "no area while on the ground")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint while on the ground")
	lu.assertFalse(sc:taskComplete(0), "task 0 not complete")
	lu.assertTrue(sc:active(), "quest is active")

	H.zoneSwitch(sc.player, sc.o.zone, { ship = {} })
	sc.ship = sc.player.rootParent

	lu.assertEquals(#areaCalls(), 0, "setup is deferred, nothing inside the ZONESWITCHED observer")

	H.advance(999)
	lu.assertEquals(#areaCalls(), 0, "still nothing at 999 ms")

	H.advance(1)
	lu.assertEquals(#areaCalls(), 1, "one area 1 s after the switch")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertTrue(sc:taskComplete(0), "task 0 complete")
	lu.assertTrue(sc:taskActive(1), "task 1 active")
end

-- AC-3
function TestDeliverySetup:test_starting_in_another_space_zone_does_nothing_until_the_player_enters_the_quest_zone()
	local sc = fresh(PICKUP_QUEST, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))
	lu.assertEquals(#areaCalls(), 0, "no area while elsewhere")

	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(secs(1))

	lu.assertEquals(#areaCalls(), 1, "one area after entering the quest zone")
	lu.assertEquals(D.count(sc:events(), "title", "progress"), 1, "one in-progress message")
end

-- AC-3
function TestDeliverySetup:test_a_second_entry_before_setup_adds_nothing()
	local sc = fresh(PICKUP_QUEST, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(300)
	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(secs(5))

	lu.assertEquals(#areaCalls(), 1, "one area")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertEquals(D.count(sc:events(), "title", "progress"), 1, "one in-progress message")
	lu.assertEquals(D.count(sc:events(), "found_loc_p", "update"), 1, "one found_loc_p update")
end

-- AC-3 (Behavior 2): the yacht cannot fly the mission
function TestDeliverySetup:test_a_player_in_the_yacht_gets_no_setup()
	local sc = fresh(PICKUP_QUEST, { ship = { objectName = "player_sorosuub_space_yacht" } })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))

	lu.assertEquals(#areaCalls(), 0, "no area in the yacht")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint in the yacht")
end

-- AC-3
function TestDeliverySetup:test_start_quest_accepts_nil_and_empty_string_for_the_npc()
	for _, npc in ipairs({ "", false }) do
		H.reset()

		local sc = fresh(PICKUP_QUEST)

		sc.quest:startQuest(sc.player, npc or nil)
		H.advance(secs(2))

		lu.assertTrue(sc:active(), "active with npc = " .. tostring(npc))
		lu.assertEquals(#areaCalls(), 1, "one area with npc = " .. tostring(npc))
	end
end

-- AC-3 (Behavior 1): one ZONESWITCHED observer, even when started twice
function TestDeliverySetup:test_start_registers_one_zone_switch_observer_even_when_started_twice()
	local sc = fresh(PICKUP_QUEST)

	sc.quest:startQuest(sc.player, "")
	sc.quest:startQuest(sc.player, "")

	lu.assertEquals(H.Engine.observerCount(ZONESWITCHED, sc.className, "enteredZone", sc.player), 1, "ZONESWITCHED observer count")
end

TestDeliveryArrival = {}

function TestDeliveryArrival:setUp() H.reset() end

-- AC-4
function TestDeliveryArrival:test_arrival_updates_the_journal_and_schedules_the_warp_in_without_spawning_inside_the_observer()
	local sc = fresh(PICKUP_QUEST):start():arrive()

	lu.assertEquals(D.times(sc:events(), "arrived_at_pickup", "update"), { sc.t0 }, "arrived_at_pickup update at arrival")
	lu.assertTrue(sc:taskComplete(1), "task 1 complete")
	lu.assertTrue(sc:taskActive(2), "task 2 active")
	lu.assertEquals(#D.spawns(), 0, "nothing is spawned inside the ENTEREDAREA observer")
	lu.assertEquals(#D.createEvents("completeQuest"), 0, "arrival does not complete the quest")
end

-- AC-4
function TestDeliveryArrival:test_the_pickup_transport_warps_in_6_seconds_after_arrival_at_the_pickup_point()
	local sc = fresh(PICKUP_QUEST):start():arrive()

	sc:at(5999)
	lu.assertEquals(#D.spawns(), 0, "no transport at 5999 ms")

	sc:at(6000)

	local spawns = D.spawns()

	lu.assertEquals(#spawns, 1, "exactly one spawn at 6 s")
	lu.assertEquals(spawns[1].t, sc.t0 + 6000, "spawn time")
	lu.assertEquals(spawns[1].name, "nym_smuggler", "pickup ship template")
	lu.assertEquals(spawns[1].zone, "space_endor", "zone")
	lu.assertEquals(spawns[1].target, sc.ship, "the player's ship is the spawn target")

	local d = D.distance(spawns[1], sc.o.pickup)

	lu.assertTrue(d >= 99.999 and d <= 200.001, "transport is 100-200 m from the pickup point, was " .. d)
end

-- AC-4
function TestDeliveryArrival:test_the_warp_in_delay_is_5_plus_getRandomNumber_1_5()
	local sc = fresh(PICKUP_QUEST)

	H.Engine.nextRandom = 5 -- after fresh(): H.reset() clears it
	sc:start():arrive()

	sc:at(9999)
	lu.assertEquals(#D.spawns(), 0, "nothing before 10 s with nextRandom = 5")

	sc:at(10000)
	lu.assertEquals(#D.spawns(), 1, "spawn at 10 s")
	lu.assertEquals(D.spawns()[1].t, sc.t0 + 10000, "spawn time")
end

-- AC-4
function TestDeliveryArrival:test_the_transport_is_owned_allied_dockable_and_tracked()
	local sc = fresh(PICKUP_QUEST):start():arrive():at(6000)
	local t = sc:transport()
	local factionHash = sc.ship.factionHash

	lu.assertEquals(t.missionOwner, sc.player, "mission owner = the player (docking is owner-only)")
	lu.assertEquals(t.factionAllies, { factionHash }, "addSpaceFactionAlly(player faction)")
	lu.assertEquals(t.removedFactionEnemies, { factionHash }, "removeSpaceFactionEnemy(player faction)")
	lu.assertTrue(ShipAiAgent(t):isDockable(), "isDockable()")
	lu.assertEquals(t.dockableCalls, { true }, "dockableCalls while waiting (I-8)")
	lu.assertEquals(sc.player.missionObjectLog, { { id = t.objectID, last = true } }, "added as a mission object with notify true")
	lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyTransportDestroyed", t), 1, "exactly one SHIPDESTROYED observer on the transport")
	lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "transportID")), t.objectID, "transportID stored")
end

-- AC-4
function TestDeliveryArrival:test_warp_in_cleans_up_the_rendezvous_and_registers_the_docking_observer_once()
	local sc = fresh(PICKUP_QUEST):start()
	local area = sc:area()
	local wp = sc:waypoints()[1]

	sc:arrive()
	sc:at(6000)

	lu.assertEquals(D.effects(sc.player, D.SPAWN_EFFECT), 1, "ui_quest_spawn_escort.cef played once")
	lu.assertEquals(#sc:waypoints(), 0, "waypoint removed")
	lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", area), 0, "area observer dropped")
	lu.assertTrue(area.destroyed, "pickup area destroyed")
	lu.assertTrue(wp.destroyed, "waypoint object gone")
	lu.assertEquals(H.Engine.observerCount(SHIPDOCKED, sc.className, "notifyDocked", sc.player), 1, "exactly one SHIPDOCKED observer on the player creature")
end

-- AC-4
function TestDeliveryArrival:test_the_transport_says_hello_2_seconds_after_it_warps_in()
	local sc = fresh(PICKUP_QUEST):start():arrive():at(7999)

	lu.assertEquals(#sc:taunts(), 0, "no taunt yet")

	sc:at(8000)

	lu.assertEquals(D.tauntTimes(sc:taunts(), "hello_p"), { sc.t0 + 8000 }, "hello_p taunt")
	lu.assertEquals(sc:taunts()[1].ship, sc:transport(), "taunted by the transport")
end

-- AC-4
function TestDeliveryArrival:test_an_ai_ship_entering_the_area_gives_no_arrival_effects()
	local sc = fresh(PICKUP_QUEST):start()

	H.enterArea(sc:area(), H.newShip({ playerShip = false }))
	H.advance(secs(30))

	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup"), 0, "no arrival update")
	lu.assertEquals(#D.spawns(), 0, "no transport")
	lu.assertTrue(sc:taskActive(1), "task 1 still active")
end

-- AC-4
function TestDeliveryArrival:test_another_players_ship_entering_the_area_gives_no_arrival_effects()
	local sc = fresh(PICKUP_QUEST):start()
	local other = H.newPlayer({ zone = sc.o.zone, ship = {}, pilot = "rebel" })

	H.enterArea(sc:area(), other.rootParent)
	H.advance(secs(30))

	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup"), 0, "no arrival update for the owner")
	lu.assertEquals(D.count(D.events(other, "delivery", "corellia_rebel_tier3_3"), "arrived_at_pickup"), 0, "none for the other player either")
	lu.assertEquals(#D.spawns(), 0, "no transport")
end

-- AC-4
function TestDeliveryArrival:test_an_area_that_is_not_the_stored_one_gives_no_arrival_effects()
	local sc = fresh(PICKUP_QUEST):start()
	local stray = H.Fakes.newActiveArea({ zone = sc.o.zone, x = 1, z = 2, y = 3, radius = 150 })

	lu.assertEquals(type(sc.quest.notifyEnteredQuestArea), "function", "quest defines notifyEnteredQuestArea")
	createObserver(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", stray)
	H.enterArea(stray, sc.ship)
	H.advance(secs(30))

	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup"), 0, "no arrival update")
	lu.assertEquals(#D.spawns(), 0, "no transport")
end

-- AC-4
function TestDeliveryArrival:test_a_second_entry_gives_no_second_arrival_and_no_second_transport()
	local sc = fresh(PICKUP_QUEST):start():arrive()
	local area = sc:area()

	H.enterArea(area, sc.ship)
	sc:at(secs(2))
	H.enterArea(area, sc.ship)
	sc:at(secs(60))

	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup", "update"), 1, "one arrival update")
	lu.assertEquals(#D.spawns(), 1, "one transport")
end

-- AC-4, Behavior 4: a player whose quest is not active does nothing, whoever flies into the area
function TestDeliveryArrival:test_arrival_after_the_quest_was_failed_does_nothing()
	local sc = fresh(PICKUP_QUEST):start()
	local area = sc:area()

	sc.quest:failQuest(sc.player, "false")
	H.enterArea(area, sc.ship)
	H.advance(secs(30))

	lu.assertEquals(#D.spawns(), 0, "no transport for an inactive quest")
	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup"), 0, "no arrival update")
end

-- AC-4, Behavior 5: spawn failure
function TestDeliveryArrival:test_a_failed_transport_spawn_fails_the_quest_instead_of_stranding_the_player()
	local sc = fresh(PICKUP_QUEST):start():arrive()

	H.Engine.config.spawnFails = true
	sc:at(secs(10))

	lu.assertFalse(sc:active(), "the quest is failed when the transport cannot be spawned")
	lu.assertEquals(#sc:waypoints(), 0, "waypoint removed")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, "no run data left")
end

-- AC-4 (Behavior 4): the delivery-only quest arrives at the delivery rendezvous
function TestDeliveryArrival:test_no_pickup_arrival_uses_arrived_at_delivery_and_tasks_1_and_2()
	local sc = fresh(NO_PICKUP):start():arrive()

	lu.assertEquals(D.times(sc:events(), "arrived_at_delivery", "update"), { sc.t0 }, "arrived_at_delivery update")
	lu.assertEquals(D.count(sc:events(), "arrived_at_pickup"), 0, "no pickup arrival message")
	lu.assertTrue(sc:taskComplete(1), "task 1 complete")
	lu.assertTrue(sc:taskActive(2), "task 2 active")

	sc:at(6000)

	local spawns = D.spawns()

	lu.assertEquals(#spawns, 1, "one transport")
	lu.assertEquals(spawns[1].name, "rebel_smuggler_tier3", "the delivery ship")
	lu.assertEquals(D.tauntTimes(sc:taunts(), "hello_d"), {}, "no hello yet at 6 s")

	sc:at(8000)
	lu.assertEquals(D.tauntTimes(sc:taunts(), "hello_d"), { sc.t0 + 8000 }, "hello_d at 8 s")
end
