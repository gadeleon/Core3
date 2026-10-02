-- Delivery docking, the delivery leg and completion (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (AC-5, AC-6, AC-7, I-8, Behavior 6 to 8).
-- The docking event is the engine's SHIPDOCKED notify on the player creature, fired with
-- (target ship, cargo hash) by H.dock, followed by the 0 ms events.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")

D.load()

local function secs(n) return n * 1000 end

local ENDOR = { "delivery", "corellia_rebel_tier3_3" }
local NO_PICKUP = { "delivery_no_pickup", "corellia_rebel_tier4_2_a" }

local function fresh(q, opts) return D.fresh(q[1], q[2], opts) end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

-- Another ship that is not the transport: an attack-style agent owned by the player.
local function strayShip(sc)
	local agent = spawnShipAgent("imp_tie_fighter_tier3", sc.o.zone, 1, 2, 3, sc.ship)

	ShipAiAgent(agent):setMissionOwner(sc.player)
	return agent
end

TestDeliveryDockEvent = {}

function TestDeliveryDockEvent:setUp() H.reset() end

-- AC-5
function TestDeliveryDockEvent:test_docking_changes_nothing_inside_the_observer_and_the_observer_returns_1()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "notifyDocked returns 1 for the waiting transport")
	lu.assertEquals(#sc:taunts(), 0, "no taunt inside the observer")
	lu.assertTrue(sc:taskActive(2), "task 2 still active inside the observer")
	lu.assertEquals(t.dockableCalls, { true }, "the transport is still dockable inside the observer (setDockable takes the agent lock)")
	lu.assertEquals(#areaCalls(), 1, "no delivery area yet")
end

-- AC-5
function TestDeliveryDockEvent:test_the_engine_removes_the_docking_observer_after_it_returns_1()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	H.dock(sc.player, t)

	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "SHIPDOCKED observer is gone after the dock")
	lu.assertEquals(#sc:taunts(), 0, "nothing happened before the 0 ms events")
	lu.assertTrue(sc:taskActive(2), "task 2 still active before the 0 ms events")
end

-- AC-5
function TestDeliveryDockEvent:test_docking_with_the_transport_completes_the_pickup_leg()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	sc:at(10000)
	sc:dock(t)

	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup"), { sc.tDock }, "docking_complete_pickup taunt at dock completion")
	lu.assertEquals(sc:taunts()[#sc:taunts()].ship, t, "taunted by the transport")
	lu.assertTrue(sc:taskComplete(2), "task 2 complete")
	lu.assertTrue(sc:taskActive(3), "task 3 active")
	lu.assertEquals(t.dockableCalls, { true, false }, "dockable while waiting, cleared at dock completion")
	lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTransportDestroyed", t), "SHIPDESTROYED observer dropped from the released transport")
	lu.assertEquals(D.removedAsMissionObject(sc.player, t), { { id = t.objectID, notify = true } }, "removed as a mission object")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "SHIPDOCKED observer dropped")
	lu.assertEquals(readData(sc.quest:dataKey(sc.player.objectID, "transportID")), 0, "transportID forgotten")
end

-- AC-5
function TestDeliveryDockEvent:test_docking_with_another_ship_changes_nothing_returns_0_and_keeps_the_observer()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()
	local stray = strayShip(sc)

	lu.assertEquals(sc.quest:notifyDocked(sc.player, stray, 0), 0, "notifyDocked returns 0 for another ship")

	H.dock(sc.player, stray)
	H.advance(0)

	lu.assertEquals(#sc:taunts(), 0, "no taunt")
	lu.assertTrue(sc:taskActive(2), "task 2 still active")
	lu.assertEquals(t.dockableCalls, { true }, "transport still dockable")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "the observer stays")

	H.advance(secs(10))
	H.dock(sc.player, t)
	H.advance(0)

	lu.assertTrue(sc:taskComplete(2), "docking with the real transport afterwards still works")
end

-- AC-5
function TestDeliveryDockEvent:test_docking_with_the_target_of_another_players_run_changes_nothing()
	local first = fresh(ENDOR):toFirstTransport()
	local second = D.new(ENDOR[1], ENDOR[2], { spies = first.spies })

	second:start()
	second:arrive()
	second:at(6000)

	local theirs = second:transport()

	H.dock(first.player, theirs)
	H.advance(0)

	lu.assertEquals(D.tauntTimes(first:taunts(), "docking_complete_pickup"), {}, "no docking_complete taunt for the first player")
	lu.assertTrue(first:taskActive(2), "first player's task 2 still active")
	lu.assertEquals(theirs.dockableCalls, { true }, "the other player's transport stays dockable")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, first.className, "notifyDocked", first.player), "first player's observer stays")
	lu.assertTrue(second:taskActive(2), "second player's quest is untouched")
end

-- AC-5
function TestDeliveryDockEvent:test_two_dock_notifies_in_the_same_tick_complete_the_leg_once()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	sc.tDock = H.now()
	sc.quest:notifyDocked(sc.player, t, 0)
	sc.quest:notifyDocked(sc.player, t, 0)
	H.advance(0)
	H.advance(secs(2))

	lu.assertEquals(#D.tauntTimes(sc:taunts(), "docking_complete_pickup"), 1, "one docking_complete_pickup taunt")
	lu.assertEquals(#areaCalls(), 2, "one delivery-leg area (plus the pickup area)")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertEquals(t.dockableCalls, { true, false }, "released once")
end

-- AC-5
function TestDeliveryDockEvent:test_without_a_dock_the_transport_waits_dockable_and_the_quest_waits_at_task_2()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	H.advance(secs(600))

	lu.assertEquals(t.dockableCalls, { true }, "still dockable after 600 s")
	lu.assertFalse(t.destroyed or false, "the transport is still there")
	lu.assertTrue(sc:taskActive(2), "task 2 still active")
	lu.assertTrue(sc:active(), "quest active")
	lu.assertEquals(#D.spawns(), 1, "no second transport")
end

-- AC-5 (Behavior 6): a dock with no waiting transport (before warp-in) does nothing
function TestDeliveryDockEvent:test_a_dock_before_any_transport_exists_does_nothing()
	local sc = fresh(ENDOR):start()

	lu.assertEquals(type(sc.quest.notifyDocked), "function", "quest defines notifyDocked")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, strayShip(sc), 0), 0, "no transport waiting: returns 0")
	H.advance(secs(5))
	lu.assertEquals(#sc:taunts(), 0, "no taunt")
	lu.assertTrue(sc:taskActive(1), "task 1 still active")
end

-- AC-5 (Behavior 6): the cargo hash is ignored
function TestDeliveryDockEvent:test_the_cargo_hash_does_not_matter()
	for _, hash in ipairs({ 0, 12345, -7 }) do
		H.reset()

		local sc = fresh(ENDOR):toFirstTransport()

		H.dock(sc.player, sc:transport(), hash)
		H.advance(0)

		lu.assertTrue(sc:taskComplete(2), "cargo hash " .. hash .. ": leg completed")
	end
end

TestDeliveryDeliveryLeg = {}

function TestDeliveryDeliveryLeg:setUp() H.reset() end

-- AC-6
function TestDeliveryDeliveryLeg:test_the_released_pickup_transport_hyperspaces_at_15_s_and_is_destroyed_2_s_later()
	local sc = fresh(ENDOR):toFirstDock()
	local t = sc:transport()

	sc:atDock(secs(15) - 1)
	lu.assertFalse(t.hyperspacing, "not hyperspacing at 14.999 s")

	sc:atDock(secs(15))
	lu.assertTrue(t.hyperspacing, "setHyperspacing(true) at 15 s")
	lu.assertEquals(D.destroyEvents(t), { { t = sc.tDock + secs(15), delay = 2000 } }, "a delayedDestroyShipAgent event 2 s later")
	lu.assertFalse(t.destroyed or false, "still there at 15 s")

	sc:atDock(secs(17))
	lu.assertTrue(t.destroyed, "destroyed at 17 s")
	lu.assertTrue(sc:active(), "the departure does not fail the quest")
end

-- AC-6
function TestDeliveryDeliveryLeg:test_destroying_the_released_transport_does_not_fail_the_quest()
	local sc = fresh(ENDOR):toFirstDock()
	local t = sc:transport()

	sc:atDock(secs(1))
	H.destroyShip(t, nil)
	H.advance(secs(60))

	lu.assertTrue(sc:active(), "quest still active after the released transport was destroyed")
	lu.assertEquals(D.count(sc:events(), "failed_destroyed"), 0, "no failed_destroyed update")
end

-- AC-6
function TestDeliveryDeliveryLeg:test_two_seconds_after_the_dock_the_delivery_rendezvous_appears()
	local sc = fresh(ENDOR):toFirstDock()
	local o = sc.o

	sc:atDock(1999)
	lu.assertEquals(#areaCalls(), 1, "no delivery area at 1.999 s")

	sc:atDock(2000)

	local calls = areaCalls()

	lu.assertEquals(#calls, 2, "one new area")
	lu.assertEquals({ calls[2][1], calls[2][2], calls[2][3], calls[2][4], calls[2][5], calls[2][6] },
		{ o.zone, D.AREA_TEMPLATE, o.delivery.x, o.delivery.z, o.delivery.y, 150 }, "delivery area zone, template, position, radius")
	lu.assertTrue(H.hasObserver(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", sc:area()), "ENTEREDAREA observer on the new area")

	local wps = sc:waypoints()

	lu.assertEquals(#wps, 1, "exactly one waypoint")
	lu.assertEquals(wps[1].name, "Delivery Rendezvous", "waypoint name")
	lu.assertEquals({ wps[1].x, wps[1].z, wps[1].y }, { o.delivery.x, o.delivery.z, o.delivery.y }, "waypoint position")
	lu.assertNotNil(tostring(wps[1].questDetails):find("rendezvous2_d", 1, true), "quest details mention rendezvous2_d")
	lu.assertEquals(D.times(sc:events(), "found_loc_d", "update"), { sc.tDock + 2000 }, "found_loc_d update at +2 s")
	lu.assertEquals(D.count(sc:events(), "title", "progress"), 1, "no second in-progress message")
	lu.assertTrue(sc:taskActive(3), "task 3 still active (no task change)")
	lu.assertEquals(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), tostring(wps[1].objectID), "waypointID status points at the new waypoint")
end

-- AC-6 (Behavior 2): the run token survives the leg change, the area id does not
function TestDeliveryDeliveryLeg:test_the_run_token_stays_the_first_area_and_the_area_id_follows_the_leg()
	local sc = fresh(ENDOR):start()
	local first = sc:area()

	sc:arrive():at(10000):dock():atDock(2000)

	local id = sc.player.objectID

	lu.assertEquals(readData(sc.quest:dataKey(id, "runID")), first.objectID, "runID is still the first area")
	lu.assertEquals(readData(sc.quest:dataKey(id, "areaID")), sc:area().objectID, "areaID is the delivery area")
	lu.assertNotEquals(sc:area().objectID, first.objectID, "different areas")
end

-- AC-6
function TestDeliveryDeliveryLeg:test_arriving_at_the_delivery_point_and_the_delivery_transport_warp_in()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(2000)
	sc:arrive()

	lu.assertEquals(D.times(sc:events(), "arrived_at_delivery", "update"), { sc.t0 }, "arrived_at_delivery update")
	lu.assertTrue(sc:taskComplete(3), "task 3 complete")
	lu.assertTrue(sc:taskActive(4), "task 4 active")

	sc:at(5999)
	lu.assertEquals(#sc:transports(), 1, "no delivery transport before 6 s")

	sc:at(6000)

	local transports = sc:transports()
	local d = transports[#transports]

	lu.assertEquals(#transports, 2, "pickup transport plus delivery transport")
	lu.assertEquals(d.shipName, "reb_gunboat_tier3", "the delivery ship")
	lu.assertEquals(D.spawns()[#D.spawns()].t, sc.t0 + 6000, "spawned 6 s after arrival")
	lu.assertEquals(D.spawns()[#D.spawns()].target, sc.ship, "targeting the player's ship")

	local dist = D.distance(D.spawns()[#D.spawns()], sc.o.delivery)

	lu.assertTrue(dist >= 99.999 and dist <= 200.001, "100-200 m from the delivery point, was " .. dist)
	lu.assertEquals(d.missionOwner, sc.player, "owned by the player")
	lu.assertEquals(d.dockableCalls, { true }, "dockable")
	lu.assertEquals(d.factionAllies, { sc.ship.factionHash }, "ally of the player's faction")
	lu.assertEquals(H.Engine.observerCount(SHIPDOCKED, sc.className, "notifyDocked", sc.player), 1, "a new SHIPDOCKED observer on the player")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTransportDestroyed", d), "SHIPDESTROYED observer on the delivery transport")
	lu.assertEquals(#sc:waypoints(), 0, "delivery waypoint removed")

	sc:at(7999)
	lu.assertEquals(D.tauntTimes(sc:taunts(), "hello_d"), {}, "no hello_d before 8 s")

	sc:at(8000)
	lu.assertEquals(D.tauntTimes(sc:taunts(), "hello_d"), { sc.t0 + 8000 }, "hello_d at +8 s")
	lu.assertEquals(D.effects(sc.player, D.SPAWN_EFFECT), 2, "spawn effect played for each transport")
end

-- AC-6
function TestDeliveryDeliveryLeg:test_a_docking_with_the_old_pickup_transport_cannot_complete_the_delivery_leg()
	local sc = fresh(ENDOR):toFirstDock()
	local pickup = sc:transport()

	sc:atDock(2000)
	sc:arrive():at(6000)

	lu.assertEquals(sc.quest:notifyDocked(sc.player, pickup, 0), 0, "the released pickup transport is no longer a valid dock target")
	H.advance(0)
	lu.assertTrue(sc:taskActive(4), "task 4 still active")
	lu.assertEquals(D.count(sc:events(), "mission_complete"), 0, "nothing completed")
end

TestDeliveryCompletion = {}

function TestDeliveryCompletion:setUp() H.reset() end

local function toDeliveryDock(q)
	local sc = fresh(q or ENDOR):toFirstDock()

	sc:toDeliveryTransport()
	sc.pickupTransport = sc:transports()[1]
	sc.deliveryTransport = sc:transport()
	sc:at(10000)
	sc:dock()

	return sc
end

-- AC-7
function TestDeliveryCompletion:test_docking_with_the_delivery_transport_taunts_and_releases_it()
	local sc = toDeliveryDock()
	local d = sc.deliveryTransport

	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_delivery"), { sc.tDock }, "docking_complete_delivery taunt at dock completion")
	lu.assertTrue(sc:taskComplete(4), "task 4 complete")
	lu.assertEquals(d.dockableCalls, { true, false }, "delivery transport released")
	lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTransportDestroyed", d), "SHIPDESTROYED observer dropped")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), "SHIPDOCKED observer dropped")
	lu.assertTrue(sc:active(), "the quest completes 2 s later, not at the dock")
end

-- AC-7
function TestDeliveryCompletion:test_the_quest_completes_two_seconds_after_the_delivery_dock_and_the_split_starts()
	local sc = toDeliveryDock()

	sc:atDock(1999)
	lu.assertTrue(sc:active(), "still active at 1.999 s")
	lu.assertFalse(sc:complete(), "not complete at 1.999 s")

	sc:atDock(2000)
	lu.assertTrue(sc:complete(), "journal quest complete at +2 s")
	lu.assertFalse(sc:active(), "no longer active")

	H.advance(secs(10))
	lu.assertEquals(D.called(sc.spies.start), { "assassinate_corellia_rebel_tier3_3_a" }, "the completion split started the assassinate quest")
	lu.assertEquals(#D.createEvents("startQuest", "assassinate_corellia_rebel_tier3_3_a"), 1, "one startQuest event for the side quest")
end

-- AC-7
function TestDeliveryCompletion:test_the_delivery_transport_departs_at_15_s_and_cleanup_does_not_touch_it()
	local sc = toDeliveryDock()
	local d = sc.deliveryTransport

	sc:atDock(2000)
	lu.assertEquals(d.dockableCalls, { true, false }, "completion cleanup does not set dockable again")
	lu.assertFalse(d.hyperspacing, "not hyperspacing yet after completion")
	lu.assertEquals(D.destroyEvents(d), {}, "completion cleanup schedules no destruction for the released transport")

	sc:atDock(secs(15))
	lu.assertTrue(d.hyperspacing, "setHyperspacing(true) at +15 s")

	sc:atDock(secs(17))
	lu.assertTrue(d.destroyed, "destroyed at +17 s")
	lu.assertEquals(#D.destroyEvents(d), 1, "exactly one destruction event")
end

-- AC-7, I-4
function TestDeliveryCompletion:test_nothing_is_left_after_completion()
	local sc = toDeliveryDock()

	sc:atDock(2000)

	lu.assertEquals(D.memoryKeys(), {}, "no shared-memory key left")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), "waypointID quest status removed")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED observer dropped")
end

-- AC-7
function TestDeliveryCompletion:test_a_late_delivery_dock_after_completion_does_not_complete_twice()
	local sc = toDeliveryDock()

	sc:atDock(2000)
	H.dock(sc.player, sc.deliveryTransport)
	H.advance(secs(60))

	lu.assertEquals(#D.createEvents("startQuest", "assassinate_corellia_rebel_tier3_3_a"), 1, "the split fired once")
	lu.assertEquals(#D.tauntTimes(sc:taunts(), "docking_complete_delivery"), 1, "one delivery taunt")
end

-- AC-7: the no-pickup mapping
function TestDeliveryCompletion:test_the_no_pickup_quest_runs_tasks_0_1_2_and_completes_two_seconds_after_the_dock()
	local sc = fresh(NO_PICKUP):start()

	lu.assertTrue(sc:taskComplete(0) and sc:taskActive(1), "setup: 0 complete, 1 active")

	sc:arrive()
	lu.assertTrue(sc:taskComplete(1) and sc:taskActive(2), "arrival: 1 complete, 2 active")

	sc:at(10000)
	sc:dock()

	local d = sc:transport()

	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_delivery"), { sc.tDock }, "docking_complete_delivery taunt")
	lu.assertTrue(sc:taskComplete(2), "dock: task 2 complete")
	lu.assertTrue(sc:active(), "still active until +2 s")

	sc:atDock(2000)
	lu.assertTrue(sc:complete(), "complete 2 s after the dock")

	H.advance(secs(20))
	lu.assertEquals(D.called(sc.spies.start), {}, "no side quest: no split started")
	lu.assertEquals(#D.createEvents("startQuest"), 0, "no startQuest event at all")
	lu.assertEquals(d.dockableCalls, { true, false }, "transport released once")
	lu.assertTrue(d.destroyed, "transport gone after its own departure timer")
end

-- AC-7: the no-pickup quest never spawns a pickup ship
function TestDeliveryCompletion:test_the_no_pickup_quest_spawns_only_the_delivery_transport_among_non_attack_ships()
	local sc = fresh(NO_PICKUP):start():arrive():at(10000):dock():atDock(secs(60))

	local names = {}

	for _, s in ipairs(D.spawns()) do
		names[s.name] = (names[s.name] or 0) + 1
	end

	lu.assertEquals(names.rebel_smuggler_tier3, 1, "one rebel_smuggler_tier3")

	for name in pairs(names) do
		lu.assertNotEquals(name, "", "no spawn with an empty ship name")
		lu.assertFalse(name:find("rebel_smuggler", 1, true) ~= nil and name ~= "rebel_smuggler_tier3", "no other smuggler: " .. name)
	end

	lu.assertEquals(#sc:transports(), 1, "exactly one transport")
end

-- AC-7: all six quests run end to end
function TestDeliveryCompletion:test_every_quest_runs_from_start_to_completion_by_docking()
	for _, q in ipairs(D.QUESTS) do
		H.reset()

		local sc = fresh(q):start()

		sc:arrive()
		sc:at(secs(6))

		if sc.o.hasPickup then
			sc:at(secs(10))
			sc:dock()
			sc:atDock(secs(2))
			sc:arrive()
			sc:at(secs(6))
		end

		sc:at(secs(10))
		sc:dock()
		sc:atDock(secs(2))
		H.advance(secs(30))

		lu.assertTrue(sc:complete(), q[2] .. ": journal quest complete")
		lu.assertEquals(#sc:transports(), sc.o.hasPickup and 2 or 1, q[2] .. ": one transport per leg")

		for i, t in ipairs(sc:transports()) do
			lu.assertEquals(t.dockableCalls, { true, false }, q[2] .. ": transport " .. i .. " dockableCalls (I-8)")
		end

		lu.assertEquals(D.memoryKeys(), {}, q[2] .. ": no shared-memory key left")
	end
end

TestDeliveryDockRaces = {}

function TestDeliveryDockRaces:setUp() H.reset() end

local function failedCount(sc) return D.count(sc:events(), "failed_destroyed", "update") end

-- AC-5, AC-9 (review R-2): the dock is notified, then the transport is destroyed before the 0 ms events run.
-- The destroyed ship is gone when dockComplete runs, so the destruction wins: exactly one failure.
function TestDeliveryDockRaces:test_dock_then_destruction_in_the_same_tick_fails_the_quest_exactly_once()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "dock accepted")
	H.destroyShip(t, nil)
	H.advance(0)
	H.advance(secs(60))

	lu.assertEquals(failedCount(sc), 1, "one failed_destroyed update")
	lu.assertFalse(sc:active(), "quest failed")
	lu.assertFalse(sc:complete(), "not completed")
	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup"), {}, "no docking_complete taunt for a destroyed ship")
	lu.assertEquals(#areaCalls(), 1, "no delivery leg was set up")
	lu.assertEquals(D.memoryKeys(), {}, "one cleanup, nothing left")
end

-- AC-5, AC-9 (review R-2): the destruction is notified first, then the dock, before the events run
function TestDeliveryDockRaces:test_destruction_then_dock_in_the_same_tick_fails_the_quest_exactly_once()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	lu.assertEquals(sc.quest:notifyTransportDestroyed(t, nil), 1, "destruction accepted")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "dock accepted too (the quest is still active inside the tick)")
	H.advance(0)
	H.advance(secs(60))

	lu.assertEquals(failedCount(sc), 1, "one failed_destroyed update")
	lu.assertFalse(sc:active(), "quest failed")
	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup"), {}, "the stale dock does nothing after the failure")
	lu.assertEquals(#areaCalls(), 1, "no delivery leg")
	lu.assertEquals(D.memoryKeys(), {}, "nothing left")
	lu.assertEquals(#D.createEvents("failQuest", "inspect_corellia_rebel_tier3_2"), 0, "no stray parent failure for a quest without one")
end

-- AC-5 (review R-2): the dock event runs first, the transport still exists when the destruction is notified.
-- The leg completes and the late transportLost must not fail the quest.
function TestDeliveryDockRaces:test_dock_released_transport_then_destruction_in_the_same_tick_completes_the_leg_and_does_not_fail()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	sc.tDock = H.now()
	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "dock accepted")
	lu.assertEquals(sc.quest:notifyTransportDestroyed(t, nil), 1, "destruction accepted in the same tick")
	H.advance(0)
	H.advance(secs(2))

	lu.assertEquals(failedCount(sc), 0, "no failed_destroyed after a successful dock")
	lu.assertTrue(sc:active(), "quest still active")
	lu.assertEquals(#D.tauntTimes(sc:taunts(), "docking_complete_pickup"), 1, "one docking taunt")
	lu.assertTrue(sc:taskComplete(2) and sc:taskActive(3), "pickup leg completed")
	lu.assertEquals(t.dockableCalls, { true, false }, "released exactly once")
	lu.assertEquals(#areaCalls(), 2, "the delivery leg was set up")
end

-- AC-5 (review R-2): a dock notified after the quest ended (journal inactive, run data still around) is ignored
function TestDeliveryDockRaces:test_a_dock_notified_after_the_quest_ended_is_refused_and_schedules_nothing()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	-- end the journal quest without the screenplay cleanup, so transportID is still stored
	SpaceHelpers:failSpaceQuest(sc.player, sc.questType, sc.name, false)
	lu.assertFalse(sc:active(), "precondition: quest inactive")
	lu.assertNotEquals(readData(sc.quest:dataKey(sc.player.objectID, "transportID")), 0, "precondition: transport still stored")

	local before = #D.createEvents("dockComplete")

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 0, "refused")
	lu.assertEquals(#D.createEvents("dockComplete"), before, "no dockComplete event scheduled")
	H.advance(0)
	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup"), {}, "no taunt")
	lu.assertEquals(t.dockableCalls, { true }, "transport untouched")
end

-- AC-5 (review R-2): a dock after a normal ending (observer gone, data deleted) is refused too
function TestDeliveryDockRaces:test_a_dock_after_a_failure_with_cleanup_is_refused_without_errors()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	sc.quest:failQuest(sc.player, "true")
	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 0, "refused")
	H.dock(sc.player, t)
	H.advance(secs(60))

	lu.assertEquals(#D.tauntTimes(sc:taunts(), "docking_complete_pickup"), 0, "no taunt")
	lu.assertEquals(D.memoryKeys(), {}, "nothing written")
end

-- AC-5 (review R-2): the quest ends between the dock notify and the deferred work (journal inactive, run data not yet cleaned)
function TestDeliveryDockRaces:test_the_quest_ending_between_the_dock_notify_and_the_deferred_work_stops_the_leg()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 1, "dock accepted")
	SpaceHelpers:failSpaceQuest(sc.player, sc.questType, sc.name, false)
	H.advance(0)
	H.advance(secs(60))

	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup"), {}, "no taunt for an inactive quest")
	lu.assertEquals(t.dockableCalls, { true }, "transport not released by the stale dock")
	lu.assertEquals(#areaCalls(), 1, "no delivery leg")
end
