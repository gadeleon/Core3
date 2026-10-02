-- Self-tests for the space harness pieces: event clock, observers, ship/area/waypoint fakes,
-- datapad and journal task fakes. Written for the survival slice (space-quest-stub-survival).

local lu = require("luaunit")
local H = require("harness")

H.boot()

-- A throwaway screenplay global the clock and observers can call into.
HarnessProbe = {
	log = {},
}

function HarnessProbe:note(pObject, args)
	self.log[#self.log + 1] = { t = H.now(), method = "note", pObject = pObject, args = args }
end

function HarnessProbe:chain(pObject, args)
	self.log[#self.log + 1] = { t = H.now(), method = "chain", args = args }
	createEvent(500, "HarnessProbe", "note", pObject, "from chain")
end

function HarnessProbe:observed(pObject, pArg, a, b)
	self.log[#self.log + 1] = { t = H.now(), method = "observed", pObject = pObject, pArg = pArg, a = a, b = b,
		zoneAtFire = pObject.zone, parentAtFire = pObject.rootParent }
	return 0
end

function HarnessProbe:removeMe(pObject)
	self.log[#self.log + 1] = { t = H.now(), method = "removeMe" }
	return 1
end

function HarnessProbe:noReturn(pObject)
end

function HarnessProbe:explode(pObject)
	error("boom")
end

TestHarnessClock = {}

function TestHarnessClock:setUp()
	H.reset()
	HarnessProbe.log = {}
end

function TestHarnessClock:test_events_do_not_run_until_time_is_advanced()
	createEvent(1000, "HarnessProbe", "note", "p", "a")

	lu.assertEquals(#HarnessProbe.log, 0)
	lu.assertEquals(H.now(), 0)
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 1, "createEvent is still recorded")
end

function TestHarnessClock:test_advance_runs_due_events_and_moves_now()
	createEvent(1000, "HarnessProbe", "note", "p", "a")

	H.advance(999)
	lu.assertEquals(#HarnessProbe.log, 0)
	lu.assertEquals(H.now(), 999)

	H.advance(1)
	lu.assertEquals(#HarnessProbe.log, 1)
	lu.assertEquals(HarnessProbe.log[1].t, 1000, "the event sees now == its due time")
	lu.assertEquals(HarnessProbe.log[1].pObject, "p")
	lu.assertEquals(HarnessProbe.log[1].args, "a")
end

function TestHarnessClock:test_events_run_in_due_order_with_ties_in_creation_order()
	createEvent(300, "HarnessProbe", "note", nil, "third")
	createEvent(100, "HarnessProbe", "note", nil, "first")
	createEvent(300, "HarnessProbe", "note", nil, "fourth")
	createEvent(200, "HarnessProbe", "note", nil, "second")

	H.advance(1000)

	local order = {}

	for i, e in ipairs(HarnessProbe.log) do
		order[i] = e.args
	end

	lu.assertEquals(order, { "first", "second", "third", "fourth" })
end

function TestHarnessClock:test_events_created_while_running_are_relative_to_their_creation_time()
	createEvent(1000, "HarnessProbe", "chain", nil, "start")

	H.advance(1200)
	lu.assertEquals(#HarnessProbe.log, 1, "the chained event is due at 1500")

	H.advance(300)
	lu.assertEquals(#HarnessProbe.log, 2)
	lu.assertEquals(HarnessProbe.log[2].t, 1500)
end

function TestHarnessClock:test_pending_events_lists_what_has_not_run()
	createEvent(2000, "HarnessProbe", "note", nil, "b")
	createEvent(1000, "HarnessProbe", "note", nil, "a")

	local pending = H.pendingEvents()

	lu.assertEquals(#pending, 2)
	lu.assertEquals(pending[1].due, 1000)
	lu.assertEquals(pending[2].method, "note")

	H.advance(1000)
	lu.assertEquals(#H.pendingEvents(), 1)
end

function TestHarnessClock:test_an_event_for_an_unknown_screenplay_fails_loudly()
	createEvent(10, "NoSuchScreenplayGlobal", "startQuest", nil, "")

	lu.assertErrorMsgContains("unknown screenplay global 'NoSuchScreenplayGlobal'", function() H.advance(10) end)
end

function TestHarnessClock:test_an_event_for_an_undefined_method_fails_loudly()
	createEvent(10, "HarnessProbe", "noSuchMethod", nil, "")

	lu.assertErrorMsgContains("undefined method HarnessProbe:noSuchMethod", function() H.advance(10) end)
end

function TestHarnessClock:test_an_error_inside_an_event_names_the_event()
	createEvent(10, "HarnessProbe", "explode", nil, "")

	lu.assertErrorMsgContains("HarnessProbe:explode", function() H.advance(10) end)
end

function TestHarnessClock:test_reset_clears_the_queue_and_the_clock()
	createEvent(10, "HarnessProbe", "note", nil, "")
	H.advance(5)
	H.reset()

	lu.assertEquals(H.now(), 0)
	lu.assertEquals(#H.pendingEvents(), 0)
end

function TestHarnessClock:test_timed_calls_carry_the_time_of_the_call()
	H.advance(250)
	createEvent(10, "HarnessProbe", "note", nil, "")

	lu.assertEquals(H.Engine.timedCallsTo("createEvent")[1].t, 250)
end

TestHarnessObservers = {}

function TestHarnessObservers:setUp()
	H.reset()
	HarnessProbe.log = {}
end

function TestHarnessObservers:test_create_has_and_drop_observer()
	local player = H.newPlayer({})

	lu.assertFalse(hasObserver(ZONESWITCHED, "HarnessProbe", "observed", player))

	createObserver(ZONESWITCHED, "HarnessProbe", "observed", player, 1)
	lu.assertTrue(hasObserver(ZONESWITCHED, "HarnessProbe", "observed", player))
	lu.assertFalse(hasObserver(SHIPDESTROYED, "HarnessProbe", "observed", player), "event type is part of the key")
	lu.assertFalse(hasObserver(ZONESWITCHED, "HarnessProbe", "observed", H.newPlayer({})), "so is the object")

	dropObserver(ZONESWITCHED, "HarnessProbe", "observed", player)
	lu.assertFalse(hasObserver(ZONESWITCHED, "HarnessProbe", "observed", player))
	lu.assertEquals(#H.Engine.callsTo("dropObserver"), 1, "dropObserver is recorded")
end

function TestHarnessObservers:test_zone_switch_sets_the_zone_and_fires_zoneswitched_with_the_hash()
	local player = H.newPlayer({ zone = "space_lok", ship = true })
	createObserver(ZONESWITCHED, "HarnessProbe", "observed", player, 1)

	H.zoneSwitch(player, "space_endor")

	lu.assertEquals(player.zone, "space_endor")
	lu.assertEquals(player.rootParent.zone, "space_endor")
	lu.assertEquals(#HarnessProbe.log, 1)
	lu.assertEquals(HarnessProbe.log[1].pObject, player)
	lu.assertNil(HarnessProbe.log[1].pArg, "second observer argument is nil for ZONESWITCHED")
	lu.assertEquals(HarnessProbe.log[1].a, getHashCode("space_endor"))
end

function TestHarnessObservers:test_zone_switch_fires_before_the_player_moves_like_the_server()
	local player = H.newPlayer({ zone = "tatooine", ship = false, parent = "starport" })
	local building = player.rootParent
	createObserver(ZONESWITCHED, "HarnessProbe", "observed", player, 1)

	H.zoneSwitch(player, "space_lok", { ship = { objectName = "player_sorosuub_space_yacht" } })

	lu.assertEquals(HarnessProbe.log[1].zoneAtFire, "tatooine", "observers see the old zone")
	lu.assertEquals(HarnessProbe.log[1].parentAtFire, building, "and the old root parent (the starport)")
	lu.assertEquals(player.zone, "space_lok")
	lu.assertEquals(player.rootParent.objectName, "player_sorosuub_space_yacht", "afterwards the player sits in the new ship")
	lu.assertEquals(player.rootParent.pilot, player)
	lu.assertEquals(player.rootParent.zone, "space_lok")
end

function TestHarnessObservers:test_enter_area_fires_the_area_observer_with_the_ship()
	local area = spawnSpaceActiveArea("space_lok", "object/space_active_area.iff", 1, 2, 3, 150)
	local ship = H.newShip({})
	createObserver(ENTEREDAREA, "HarnessProbe", "observed", area)

	H.enterArea(area, ship)

	lu.assertEquals(#HarnessProbe.log, 1)
	lu.assertEquals(HarnessProbe.log[1].pObject, area)
	lu.assertEquals(HarnessProbe.log[1].pArg, ship)
end

function TestHarnessObservers:test_a_handler_returning_1_is_removed()
	local player = H.newPlayer({})
	createObserver(ZONESWITCHED, "HarnessProbe", "removeMe", player)

	H.fireObservers(ZONESWITCHED, player)
	H.fireObservers(ZONESWITCHED, player)

	lu.assertEquals(#HarnessProbe.log, 1, "removed after the first call")
	lu.assertFalse(hasObserver(ZONESWITCHED, "HarnessProbe", "removeMe", player))
end

function TestHarnessObservers:test_a_handler_that_returns_no_number_is_an_error()
	local player = H.newPlayer({})
	createObserver(ZONESWITCHED, "HarnessProbe", "noReturn", player)

	lu.assertErrorMsgContains("requires a number", function() H.fireObservers(ZONESWITCHED, player) end)
end

function TestHarnessObservers:test_destroy_ship_fires_shipdestroyed_then_removes_the_ship()
	local ship = H.newShip({})
	local agent = spawnShipAgent("blacksun_fighter_tier3", "space_lok", 1, 2, 3, ship)
	createObserver(SHIPDESTROYED, "HarnessProbe", "observed", agent)

	lu.assertEquals(getSceneObject(agent:getObjectID()), agent)
	lu.assertTrue(H.destroyShip(agent, ship))

	lu.assertEquals(#HarnessProbe.log, 1)
	lu.assertEquals(HarnessProbe.log[1].pArg, ship, "killer ship is passed through")
	lu.assertNil(getSceneObject(agent:getObjectID()), "a destroyed agent is gone from the world")
	lu.assertFalse(hasObserver(SHIPDESTROYED, "HarnessProbe", "observed", agent))
	lu.assertFalse(H.destroyShip(agent, ship), "second destroy is a no-op")
	lu.assertEquals(#HarnessProbe.log, 1)
end

TestHarnessSpaceFakes = {}

function TestHarnessSpaceFakes:setUp()
	H.reset()
end

function TestHarnessSpaceFakes:test_add_waypoint_records_x_z_y_in_core3_argument_order()
	local player = H.newPlayer({})
	local id = PlayerObject(player.ghost):addWaypoint("space_lok", "Mission Objective", "", 10, 20, 30, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	local wp = player.ghost.waypoints[1]

	lu.assertEquals(#player.ghost.waypoints, 1)
	lu.assertEquals({ wp.x, wp.z, wp.y }, { 10, 20, 30 }, "x, z (height), y")
	lu.assertEquals(wp.planet, "space_lok")
	lu.assertEquals(wp.name, "Mission Objective")
	lu.assertEquals(wp.color, WAYPOINT_SPACE)
	lu.assertEquals(wp.special, WAYPOINTQUESTTASK)
	lu.assertEquals(getSceneObject(id), wp, "the returned id resolves through getSceneObject")

	WaypointObject(getSceneObject(id)):setQuestDetails("details")
	lu.assertEquals(wp.questDetails, "details")
end

function TestHarnessSpaceFakes:test_add_waypoint_with_the_wrong_argument_count_errors_like_the_binding_would_fail()
	local player = H.newPlayer({})

	lu.assertErrorMsgContains("10 or 11 arguments", function()
		PlayerObject(player.ghost):addWaypoint("space_lok", "n", "", 10, 20, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	end)
end

function TestHarnessSpaceFakes:test_remove_waypoint_removes_it_and_tolerates_nil()
	local player = H.newPlayer({})
	local id = PlayerObject(player.ghost):addWaypoint("space_lok", "n", "", 1, 2, 3, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)

	PlayerObject(player.ghost):removeWaypoint(nil, true)
	lu.assertEquals(#player.ghost.waypoints, 1)

	PlayerObject(player.ghost):removeWaypoint(id, true)
	lu.assertEquals(#player.ghost.waypoints, 0)
	lu.assertEquals(#player.ghost.removedWaypoints, 1)
	lu.assertNil(getSceneObject(id))
end

function TestHarnessSpaceFakes:test_clear_quest_waypoint_removes_the_stored_waypoint()
	local player = H.newPlayer({})
	local id = PlayerObject(player.ghost):addWaypoint("space_lok", "n", "", 1, 2, 3, WAYPOINT_SPACE, true, true, WAYPOINTQUESTTASK)
	setQuestStatus(player.objectID .. ":some_quest:waypointID", id)

	SpaceHelpers:clearQuestWaypoint(player, "some_quest")

	lu.assertEquals(#player.ghost.waypoints, 0)
	lu.assertNil(getQuestStatus(player.objectID .. ":some_quest:waypointID"))
end

function TestHarnessSpaceFakes:test_a_player_with_a_ship_reports_the_ship_zone_position_and_pilot()
	local player = H.newPlayer({ zone = "space_lok", ship = { x = 5, z = 6, y = 7 } })
	local ship = SceneObject(player):getRootParent()

	lu.assertEquals(SceneObject(player):getZoneName(), "space_lok")
	lu.assertTrue(SceneObject(ship):isShipObject())
	lu.assertTrue(SceneObject(ship):isPlayerShip())
	lu.assertEquals(ShipObject(ship):getPilot(), player)
	lu.assertEquals({ SceneObject(ship):getWorldPositionX(), SceneObject(ship):getWorldPositionZ(), SceneObject(ship):getWorldPositionY() }, { 5, 6, 7 })
	lu.assertEquals(SceneObject(player):getWorldPositionZ(), 6, "the player inside a ship has the ship position")
	lu.assertFalse(SpaceHelpers:isInYacht(player))
end

function TestHarnessSpaceFakes:test_a_player_without_a_ship_or_in_the_yacht_counts_as_in_yacht()
	lu.assertTrue(SpaceHelpers:isInYacht(H.newPlayer({ zone = "space_lok" })), "no root parent")
	lu.assertTrue(SpaceHelpers:isInYacht(H.newPlayer({ zone = "space_lok", ship = { objectName = "player_sorosuub_space_yacht" } })))
end

function TestHarnessSpaceFakes:test_spawn_point_in_front_of_ship_is_deterministic_and_recorded()
	local ship = H.newShip({ x = 100, z = 200, y = 300 })

	lu.assertEquals(ShipObject(ship):getSpawnPointInFrontOfShip(1000, 1200), { 1100, 207, 1500 })
	lu.assertEquals(ship.spawnPointCalls, { { 1000, 1200 } })
end

function TestHarnessSpaceFakes:test_spawn_ship_agent_returns_a_recording_fake_agent()
	local ship = H.newShip({})
	local player = H.newPlayer({})
	local first = spawnShipAgent("a", "space_lok", 1, 2, 3, ship)
	local second = spawnShipAgent("b", "space_lok", 4, 5, 6, ship)

	lu.assertEquals(H.Engine.callsTo("spawnShipAgent")[1][1], "a")
	lu.assertEquals(H.spawnedShips(), { first, second })
	lu.assertFalse(SceneObject(first):isPlayerShip())
	lu.assertTrue(SceneObject(first):isShipObject())
	lu.assertNotEquals(SceneObject(first):getObjectID(), SceneObject(second):getObjectID())

	ShipAiAgent(first):setMissionOwner(player)
	ShipAiAgent(first):addSpaceFactionEnemy(77)
	ShipAiAgent(first):engageShipTarget(ship)
	ShipAiAgent(first):createSquadron()
	ShipAiAgent(second):assignToSquadron(first)
	ShipObject(second):setHyperspacing(true)
	SceneObject(second):setPosition(9, 8, 7)

	lu.assertEquals(ShipAiAgent(first):getMissionOwnerID(), player.objectID)
	lu.assertEquals(first.factionEnemies, { 77 })
	lu.assertEquals(first.engaged, { ship })
	lu.assertTrue(first.isSquadronLeader)
	lu.assertEquals(second.squadronLeader, first)
	lu.assertTrue(second.hyperspacing)
	lu.assertEquals({ second.x, second.z, second.y }, { 9, 8, 7 })
end

function TestHarnessSpaceFakes:test_spawn_space_active_area_returns_a_fake_area()
	local area = spawnSpaceActiveArea("space_lok", "object/space_active_area.iff", 1, 2, 3, 150)

	lu.assertTrue(SceneObject(area):isActiveArea())
	lu.assertEquals(H.Engine.callsTo("spawnSpaceActiveArea")[1], table.pack("space_lok", "object/space_active_area.iff", 1, 2, 3, 150))

	SceneObject(area):destroyObjectFromWorld()
	lu.assertTrue(area.destroyed)
	lu.assertNil(getSceneObject(area.objectID))
end

function TestHarnessSpaceFakes:test_mission_objects_are_added_and_removed_on_the_player()
	local player = H.newPlayer({})

	CreatureObject(player):addSpaceMissionObject(11, false)
	CreatureObject(player):addSpaceMissionObject(12, true)
	CreatureObject(player):removeSpaceMissionObject(11, false)

	lu.assertEquals(player.missionObjects, { 12 })
	lu.assertEquals(player.removedMissionObjects, { 11 })
	lu.assertEquals(player.removedMissionObjectLog, { { id = 11, notify = false } })
end

function TestHarnessSpaceFakes:test_play_effect_is_recorded_with_the_time()
	local player = H.newPlayer({})
	H.advance(40)

	CreatureObject(player):playEffect("clienteffect/x.cef", "")

	lu.assertEquals(player.effects, { { t = 40, file = "clienteffect/x.cef", arg = "" } })
end

function TestHarnessSpaceFakes:test_message_log_normalises_plain_and_string_id_messages()
	local player = H.newPlayer({})
	H.advance(5)

	CreatureObject(player):sendSystemMessage("@spacequest/survival/q:outofrange")
	SpaceHelpers:sendQuestUpdate(player, "@spacequest/survival/q:found_loc")
	local trans = LuaStringIdChatParameter("@spacequest/survival/q:trans_update")
	trans:setDI(40)
	CreatureObject(player):sendSystemMessage(trans:_getObject())

	lu.assertEquals(H.messageLog(player), {
		{ t = 5, id = "@spacequest/survival/q:outofrange", plain = true },
		{ t = 5, id = "@space/quest:quest_update_s", TO = "@spacequest/survival/q:found_loc", plain = false },
		{ t = 5, id = "@spacequest/survival/q:trans_update", DI = 40, plain = false },
	})
end

function TestHarnessSpaceFakes:test_journal_tasks_move_from_active_to_complete_and_clear_with_the_quest()
	local player = H.newPlayer({})
	local crc = H.questCrc("survival", "q")

	PlayerObject(player.ghost):activateJournalQuest(crc, false)
	PlayerObject(player.ghost):activateJournalQuestTask(crc, 1, true)
	lu.assertTrue(PlayerObject(player.ghost):isJournalQuestTaskActive(crc, 1))
	lu.assertFalse(PlayerObject(player.ghost):isJournalQuestTaskComplete(crc, 1))

	PlayerObject(player.ghost):completeJournalQuestTask(crc, 1, false)
	lu.assertFalse(PlayerObject(player.ghost):isJournalQuestTaskActive(crc, 1))
	lu.assertTrue(PlayerObject(player.ghost):isJournalQuestTaskComplete(crc, 1))

	PlayerObject(player.ghost):clearJournalQuest(crc, false)
	lu.assertFalse(PlayerObject(player.ghost):isJournalQuestTaskComplete(crc, 1))
end

function TestHarnessSpaceFakes:test_activate_space_quest_runs_end_to_end_against_the_datapad_fakes()
	local player = H.newPlayer({})

	SpaceHelpers:activateSpaceQuest(player, nil, "survival", "q", false)

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "survival", "q"))
	lu.assertEquals(#player.datapad.items, 1, "a mission object was given to the datapad")
	lu.assertEquals(player.datapad.items[1].questName, "q")
end

function TestHarnessSpaceFakes:test_string_vector_shared_memory_stores_strings_and_returns_copies()
	writeStringVectorSharedMemory("k", { 1001, 1002 })

	local v = readStringVectorSharedMemory("k")
	lu.assertEquals(v, { "1001", "1002" }, "the server stores strings")

	v[1] = "changed"
	lu.assertEquals(readStringVectorSharedMemory("k"), { "1001", "1002" })

	deleteStringVectorSharedMemory("k")
	lu.assertEquals(readStringVectorSharedMemory("k"), {})
end

function TestHarnessSpaceFakes:test_shared_memory_keys_lists_every_kind_with_its_key()
	writeSharedMemory("1:a:", 5)
	writeSharedMemoryString("1:b:", "x")
	writeStringVectorSharedMemory("1:c:", { 1 })

	lu.assertEquals(H.Engine.sharedMemoryKeys(), { "StringVector|1:c:", "String|1:b:", "|1:a:" })
end

function TestHarnessSpaceFakes:test_random_override_is_cleared_by_reset()
	H.Engine.nextRandom = 3
	H.reset()

	lu.assertEquals(getRandomNumber(1, 5), 1)
end
