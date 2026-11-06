-- Inspect quest start, setup, zone switches and missing data (space-quest-inspect-cargo).
-- Spec: .claude/work/space-quest-inspect-cargo/01-spec.md (AC-3, AC-6, AC-7, Behavior 1-3). Times are on the
-- harness clock. Expected numbers come from the SWG-Source fixtures and the Core3 spawner tables through
-- inspect_scenario.lua, never from the quest tables under test.

local lu = require("luaunit")
local H = require("harness")
local I = require("inspect_scenario")

I.load()

local REP = I.REP

local function label(name) return "inspect/" .. name end

---------------------------------------------------------------------------------------------
-- AC-3: start and setup
---------------------------------------------------------------------------------------------

TestInspectStart = {}

function TestInspectStart:setUp() H.reset() end

-- AC-3
function TestInspectStart:test_start_activates_task_0_at_once_and_nothing_else_happens_before_one_second()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)

		sc.quest:startQuest(sc.player, "")

		lu.assertTrue(sc:active(), label(name) .. ": the journal quest is active")
		lu.assertTrue(sc:taskActive(0), label(name) .. ": task 0 is active at once")
		lu.assertFalse(sc:taskActive(1), label(name) .. ": task 1 is not active yet")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": no waypoint yet")

		H.advance(I.SETUP_DELAY - 1)

		lu.assertTrue(sc:taskActive(0) and not sc:taskComplete(0), label(name) .. ": task 0 still active 1 ms before setup")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": still no waypoint 1 ms before setup")
		lu.assertEquals(sc:observerCount(INSPECTEDSHIP, "inspectedShip"), 0, label(name) .. ": no INSPECTEDSHIP observer before setup")
		lu.assertEquals(sc:observerCount(SHIPDOCKED, "dockedShip"), 0, label(name) .. ": no SHIPDOCKED observer before setup")
	end
end

-- AC-3 (Behavior 1)
function TestInspectStart:test_start_creates_exactly_one_zone_observer_even_when_started_twice()
	local sc = I.fresh(REP)

	sc:start()
	sc:start()

	lu.assertEquals(sc:observerCount(ZONESWITCHED, "enteredZone"), 1, "exactly one ZONESWITCHED observer")
end

-- AC-3 (Behavior 1)
function TestInspectStart:test_an_empty_string_npc_is_treated_as_no_npc()
	local sc = I.fresh(REP)
	local ok, err = pcall(function() sc.quest:startQuest(sc.player, "") end)

	lu.assertTrue(ok, "startQuest(player, \"\") raises no error: " .. tostring(err))
	lu.assertTrue(sc:active(), "the quest is active")
end

TestInspectSetup = {}

function TestInspectSetup:setUp() H.reset() end

-- AC-3
function TestInspectSetup:test_setup_at_one_second_completes_task_0_activates_task_1_and_one_task_per_spawner()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		lu.assertTrue(sc:taskComplete(0), label(name) .. ": task 0 complete")
		lu.assertTrue(sc:taskActive(1), label(name) .. ": task 1 (quest_inspect) active")
		lu.assertFalse(sc:taskActive(2), label(name) .. ": task 2 (quest_dock) not active before the cargo is found")

		for i = 1, #sc.o.spawns do
			lu.assertTrue(sc:taskActive(I.FIRST_SPAWN_TASK + i - 1), label(name) .. ": task " .. (I.FIRST_SPAWN_TASK + i - 1) .. " (possible target location " .. i .. ") active")
		end

		lu.assertFalse(sc:taskActive(I.FIRST_SPAWN_TASK + #sc.o.spawns), label(name) .. ": no task beyond the last spawner")
	end
end

-- AC-3
function TestInspectSetup:test_the_representative_quest_activates_tasks_3_4_and_5()
	local sc = I.fresh(REP):toSetup()

	lu.assertEquals(sc:tasks(), { [0] = "c", "a", "-", "a", "a", "a", "-", "-", "-" }, "task states 0..8")
end

-- AC-3
function TestInspectSetup:test_one_waypoint_per_valid_spawner_at_the_spawner_coordinates_in_tab_order()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()
		local wps = sc:waypoints()

		lu.assertEquals(#wps, #sc.o.spawns, label(name) .. ": number of waypoints")

		for i, s in ipairs(sc.o.spawns) do
			local w = wps[i]

			lu.assertNotNil(w, label(name) .. ": waypoint " .. i)
			lu.assertEquals(w.planet, sc.o.zone, label(name) .. ": waypoint " .. i .. " planet")
			lu.assertEquals(w.name, I.WAYPOINT_NAME, label(name) .. ": waypoint " .. i .. " name")
			lu.assertEquals(w.questDetails, I.WAYPOINT_DETAILS, label(name) .. ": waypoint " .. i .. " details")
			lu.assertEquals(w.color, WAYPOINT_SPACE, label(name) .. ": waypoint " .. i .. " color")
			lu.assertEquals(w.special, WAYPOINTQUESTTASK, label(name) .. ": waypoint " .. i .. " special type")
			lu.assertEquals({ w.x, w.z, w.y }, { s.x, s.z, s.y }, label(name) .. ": waypoint " .. i .. " x z y (" .. s.spawnName .. ")")
		end
	end
end

-- AC-3
function TestInspectSetup:test_the_waypoint_ids_are_stored_in_the_waypoint_vector_of_the_class()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()
		local ids = {}

		for i, w in ipairs(sc:waypoints()) do
			ids[i] = w.objectID
		end

		lu.assertEquals(sc:vector(), ids, label(name) .. ": <playerID>:<className>:waypointVector")
	end
end

-- AC-3
function TestInspectSetup:test_setup_adds_exactly_one_inspect_and_one_dock_observer_and_keeps_the_zone_observer()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, label(name) .. ": observers of the class on the player")
		lu.assertTrue(H.hasObserver(INSPECTEDSHIP, sc.className, "inspectedShip", sc.player), label(name) .. ": INSPECTEDSHIP -> inspectedShip")
		lu.assertTrue(H.hasObserver(SHIPDOCKED, sc.className, "dockedShip", sc.player), label(name) .. ": SHIPDOCKED -> dockedShip")
	end
end

-- AC-3
function TestInspectSetup:test_the_waypoint_notice_comes_one_second_after_setup_with_the_number_of_waypoints()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 0, label(name) .. ": no notice at t=1 s")

		H.advance(I.NOTICE_DELAY - 1)

		lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 0, label(name) .. ": no notice 1 ms before t=2 s")

		H.advance(1)

		local notice = sc:msgs(I.MSG_WAYPOINTS)

		lu.assertEquals(#notice, 1, label(name) .. ": one inspect_target_waypoints message at t=2 s")
		lu.assertEquals(notice[1].DI, #sc.o.spawns, label(name) .. ": DI = number of waypoints")
		lu.assertEquals(notice[1].t, I.SETUP_DELAY + I.NOTICE_DELAY, label(name) .. ": sent at t=2 s")

		H.advance(60000)
		lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 1, label(name) .. ": and only once")
	end
end

-- AC-3
function TestInspectSetup:test_a_single_spawner_quest_gets_exactly_one_waypoint_at_nyms_boys_and_task_3()
	local sc = I.fresh(I.SINGLE):toSetup()

	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertEquals({ sc:waypoints()[1].x, sc:waypoints()[1].z, sc:waypoints()[1].y }, { 3719, -2284, -1151 }, "at nyms_boys")
	lu.assertTrue(sc:taskActive(3), "task 3 active")
	lu.assertFalse(sc:taskActive(4), "task 4 not active")
end

-- AC-3
function TestInspectSetup:test_setup_adds_no_waypoint_when_give_spawn_waypoint_is_not_1_but_still_sets_up()
	H.reset()

	local q = SpaceInspectScreenplay:new {
		className = "inspect_adhoc_nowaypoint", questName = "adhoc_nowaypoint", questType = "inspect", questZone = "space_endor",
		shipList = { "huttsmuggler" }, validSpawns = { { spawnName = "hutt_smuggler_01", x = 1, z = 2, y = 3 } }, giveSpawnWaypoint = 0, cargo = "sector_recon_data",
	}

	rawset(_G, "inspect_adhoc_nowaypoint", q)
	I.checkRewrite(q, "ad hoc quest")

	local player = H.newPlayer({ zone = "space_endor", ship = {}, pilot = "rebel" })

	q:startQuest(player, "")
	H.advance(5000)

	lu.assertEquals(#player.ghost.waypoints, 0, "no waypoint")
	lu.assertTrue(SpaceHelpers:isSpaceQuestTaskComplete(player, "inspect", "adhoc_nowaypoint", 0), "task 0 complete")
	lu.assertTrue(SpaceHelpers:isSpaceQuestTaskActive(player, "inspect", "adhoc_nowaypoint", 1), "task 1 active")
	lu.assertEquals(#I.msgs(player, I.MSG_WAYPOINTS), 0, "no notice")
	lu.assertTrue(H.hasObserver(INSPECTEDSHIP, "inspect_adhoc_nowaypoint", "inspectedShip", player), "INSPECTEDSHIP observer")
end

---------------------------------------------------------------------------------------------
-- AC-3: where the player is when the quest starts
---------------------------------------------------------------------------------------------

TestInspectStartElsewhere = {}

function TestInspectStartElsewhere:setUp() H.reset() end

local function assertOnlyTask0(label, sc)
	lu.assertTrue(sc:active(), label .. ": active")
	lu.assertTrue(sc:taskActive(0), label .. ": task 0 active")
	lu.assertFalse(sc:taskComplete(0), label .. ": task 0 not complete")
	lu.assertFalse(sc:taskActive(1), label .. ": task 1 not active")
	lu.assertEquals(#sc:waypoints(), 0, label .. ": no waypoint")
	lu.assertEquals(sc:observerCount(INSPECTEDSHIP, "inspectedShip"), 0, label .. ": no INSPECTEDSHIP observer")
	lu.assertEquals(sc:observerCount(SHIPDOCKED, "dockedShip"), 0, label .. ": no SHIPDOCKED observer")
end

-- AC-3
function TestInspectStartElsewhere:test_a_player_on_the_ground_gets_task_0_only()
	local sc = I.fresh(REP, { zone = "corellia", ship = false })

	sc:start()
	H.advance(10000)

	assertOnlyTask0("on the ground", sc)
	lu.assertEquals(sc:observerCount(ZONESWITCHED, "enteredZone"), 1, "the zone observer is waiting for the quest zone")
end

-- AC-3
function TestInspectStartElsewhere:test_a_player_in_another_space_zone_gets_task_0_only()
	local sc = I.fresh(REP, { zone = "space_lok" })

	sc:start()
	H.advance(10000)

	assertOnlyTask0("in another space zone", sc)
end

-- AC-3
function TestInspectStartElsewhere:test_a_player_in_the_yacht_in_the_quest_zone_gets_task_0_only()
	local sc = I.fresh(REP, { ship = { objectName = "player_sorosuub_space_yacht" } })

	sc:start()
	H.advance(10000)

	assertOnlyTask0("in the yacht", sc)
end

-- AC-3
function TestInspectStartElsewhere:test_setup_happens_one_second_after_entering_the_quest_zone_in_a_ship()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name, { zone = "space_nowhere" })

		sc:start()
		H.advance(5000)
		H.zoneSwitch(sc.player, sc.o.zone, { ship = {} })
		H.advance(I.SETUP_DELAY - 1)

		lu.assertFalse(sc:taskComplete(0), label(name) .. ": not set up 1 ms before the delay")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": no waypoint yet")

		H.advance(1)

		lu.assertTrue(sc:taskComplete(0), label(name) .. ": set up 1 s after the zone entry")
		lu.assertTrue(sc:taskActive(1), label(name) .. ": task 1 active")
		lu.assertEquals(#sc:waypoints(), #sc.o.spawns, label(name) .. ": one waypoint per spawner")
		lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, label(name) .. ": observers")
	end
end

-- AC-3
function TestInspectStartElsewhere:test_taking_off_from_the_ground_into_the_quest_zone_sets_the_quest_up()
	local sc = I.fresh(REP, { zone = "corellia", ship = false })

	sc.player.rootParent = nil
	sc:start()
	H.zoneSwitch(sc.player, sc.o.zone, { ship = {} })
	H.advance(I.SETUP_DELAY)

	lu.assertTrue(sc:taskComplete(0), "set up")
	lu.assertEquals(#sc:waypoints(), 3, "three waypoints")
end

-- AC-3
function TestInspectStartElsewhere:test_entering_the_quest_zone_in_the_yacht_does_not_set_the_quest_up()
	local sc = I.fresh(REP, { zone = "space_lok" })

	sc:start()
	H.zoneSwitch(sc.player, sc.o.zone, { ship = { objectName = "player_sorosuub_space_yacht" } })
	H.advance(10000)

	assertOnlyTask0("entered the zone in the yacht", sc)
end

-- AC-3
function TestInspectStartElsewhere:test_two_zone_entries_before_setup_produce_one_setup()
	local sc = I.fresh(REP, { zone = "space_lok" })

	sc:start()
	H.zoneSwitch(sc.player, sc.o.zone, { ship = {} })
	H.advance(300)
	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(10000)

	lu.assertEquals(#sc:waypoints(), 3, "three waypoints, not six")
	lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, "one observer each")
	lu.assertEquals(#sc:vector(), 3, "three ids in the vector")
	lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 1, "one waypoint notice")
	lu.assertTrue(sc:active(), "the second entry before setup does not abandon the quest")
end

-- AC-3 (Behavior 2: setup re-checks its own preconditions)
function TestInspectStartElsewhere:test_setup_does_nothing_when_the_player_left_the_zone_before_it_ran()
	local sc = I.fresh(REP):start()

	sc.player.zone = "space_lok"
	sc.player.rootParent.zone = "space_lok"
	H.advance(10000)

	lu.assertFalse(sc:taskComplete(0), "task 0 not complete")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint")
	lu.assertEquals(sc:observerCount(INSPECTEDSHIP, "inspectedShip"), 0, "no INSPECTEDSHIP observer")
end

-- AC-3 (Behavior 2)
function TestInspectStartElsewhere:test_setup_called_twice_acts_once()
	local sc = I.fresh(REP):toSetup()

	sc.quest:setupInspection(sc.player)
	sc.quest:setupInspection(sc.player)

	lu.assertEquals(#sc:waypoints(), 3, "three waypoints")
	lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, "one observer each")
end

---------------------------------------------------------------------------------------------
-- AC-6: zone switches
---------------------------------------------------------------------------------------------

TestInspectZoneSwitch = {}

function TestInspectZoneSwitch:setUp() H.reset() end

-- AC-6
function TestInspectZoneSwitch:test_a_switch_to_another_zone_after_setup_fails_nothing_inside_the_observer_and_returns_0()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()
		local before = sc:snapshot()
		local failEvents = #I.createEvents("failQuest")

		lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode("space_nowhere")), 0, label(name) .. ": enteredZone returns 0")
		lu.assertEquals(sc:snapshot(), before, label(name) .. ": nothing changed inside the observer")
		lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 0, label(name) .. ": no abandon message inside the observer")
		lu.assertEquals(#I.createEvents("failQuest"), failEvents, label(name) .. ": no failQuest event is created, the failure goes through abandonInspection")
	end
end

-- AC-6
function TestInspectZoneSwitch:test_a_switch_to_another_zone_after_setup_abandons_the_quest_in_the_next_event()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		H.zoneSwitch(sc.player, "space_nowhere")
		lu.assertTrue(sc:active(), label(name) .. ": still active right after the observer ran")

		H.advance(0)

		lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 1, label(name) .. ": inspect_abandoned sent once")
		lu.assertFalse(sc:active(), label(name) .. ": the quest is not active")
		lu.assertFalse(sc:complete(), label(name) .. ": and not complete")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": waypoints removed")
		lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, label(name) .. ": observers dropped")
	end
end

-- AC-6
function TestInspectZoneSwitch:test_a_switch_to_the_same_zone_after_setup_a_respawn_abandons_the_quest_too()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		H.zoneSwitch(sc.player, sc.o.zone)
		lu.assertTrue(sc:active(), label(name) .. ": still active right after the observer ran")

		H.advance(0)

		lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 1, label(name) .. ": inspect_abandoned sent once")
		lu.assertFalse(sc:active(), label(name) .. ": the quest is not active")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": waypoints removed")
		lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, label(name) .. ": observers dropped")
	end
end

-- AC-6
function TestInspectZoneSwitch:test_two_switches_before_the_event_runs_abandon_the_quest_once()
	local sc = I.fresh(REP):toSetup()

	sc.quest:enteredZone(sc.player, nil, getHashCode("space_nowhere"))
	sc.quest:enteredZone(sc.player, nil, getHashCode("space_lok"))
	H.advance(10000)

	lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 1, "inspect_abandoned once")
	lu.assertFalse(sc:active(), "not active")
end

-- AC-6
function TestInspectZoneSwitch:test_a_switch_to_another_zone_before_setup_leaves_the_quest_active_with_task_0_active()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name, { zone = "space_nowhere" })

		sc:start()

		lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode("space_other")), 0, label(name) .. ": returns 0")
		H.zoneSwitch(sc.player, "space_other")
		H.advance(10000)

		lu.assertTrue(sc:active(), label(name) .. ": still active")
		lu.assertTrue(sc:taskActive(0), label(name) .. ": task 0 still active")
		lu.assertFalse(sc:taskComplete(0), label(name) .. ": task 0 not complete")
		lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 0, label(name) .. ": no abandon message")
		lu.assertEquals(sc:observerCount(ZONESWITCHED, "enteredZone"), 1, label(name) .. ": the zone observer stays")
	end
end

-- AC-6
function TestInspectZoneSwitch:test_the_zone_observer_returns_1_for_a_quest_that_is_not_active()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)

		lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode("space_nowhere")), 1, label(name) .. ": unknown quest state")

		sc:toSetup()
		sc.quest:failQuest(sc.player, "true")

		lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(sc.o.zone)), 1, label(name) .. ": after the quest failed")
	end
end

-- AC-6
function TestInspectZoneSwitch:test_abandon_inspection_acts_only_on_an_active_quest()
	local sc = I.fresh(REP)
	local ok, err = pcall(function() sc.quest:abandonInspection(sc.player, "") end)

	lu.assertTrue(ok, "abandonInspection on a never-started quest raises no error: " .. tostring(err))
	lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 0, "nothing sent")
end

-- AC-6
function TestInspectZoneSwitch:test_failing_the_tier_3_mission_2_quest_creates_no_parent_fail_event_and_keeps_the_side_quest_fail()
	local name = "corellia_privateer_tier3_2"
	local sc = I.fresh(name):toSetup()

	SpaceHelpers:activateSpaceQuest(sc.player, nil, "survival", "corellia_privateer_tier3_2_a", false)
	sc.quest:failQuest(sc.player, "true")

	local fails = I.createEvents("failQuest")
	local targets = {}

	for _, args in ipairs(fails) do
		targets[#targets + 1] = args[2]
	end

	lu.assertEquals(targets, { "survival_corellia_privateer_tier3_2_a" }, "the only failQuest event goes to the active side quest (no event to the empty parent '_')")
	lu.assertEquals(fails[1][5], "false", "with notify false, as before")
end

---------------------------------------------------------------------------------------------
-- AC-7: missing data
---------------------------------------------------------------------------------------------

TestInspectMissingData = {}

function TestInspectMissingData:setUp() H.reset() end

local function assertCleanFailure(label, quest, player)
	local ok, err = pcall(function()
		quest:startQuest(player, "")
		H.advance(10000)
	end)

	lu.assertTrue(ok, label .. ": raises no Lua error, got " .. tostring(err))

	local named = false

	for _, msg in ipairs(I.errorLogs()) do
		if msg:find(quest.className, 1, true) then
			named = true
		end
	end

	lu.assertTrue(named, label .. ": an LT_ERROR line naming " .. quest.className .. " was logged, got " .. #I.errorLogs() .. " error lines")
	lu.assertEquals(#player.ghost.waypoints, 0, label .. ": no waypoint")
	lu.assertFalse(H.hasObserver(INSPECTEDSHIP, quest.className, "inspectedShip", player), label .. ": no INSPECTEDSHIP observer")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, quest.className, "dockedShip", player), label .. ": no SHIPDOCKED observer")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, quest.questType, quest.questName), label .. ": the quest ends not active")
end

-- the failure is reported to the player exactly once (inspect_abandoned)
local function assertAbandonedOnce(label, player)
	lu.assertEquals(#I.msgs(player, I.MSG_ABANDONED), 1, label .. ": inspect_abandoned messages sent")
end

-- AC-7
function TestInspectMissingData:test_an_ad_hoc_quest_with_an_empty_cargo_fails_cleanly_at_setup()
	local q = SpaceInspectScreenplay:new {
		className = "inspect_adhoc_nocargo", questName = "adhoc_nocargo", questType = "inspect", questZone = "space_naboo",
		shipList = { "naboo_diplomatic_corps_bad_tier3" }, validSpawns = { { spawnName = "naboo_privateer_tier3_leg_3_inspect", x = 3151, z = 3183, y = 4026 } },
		giveSpawnWaypoint = 1, cargo = "",
	}

	rawset(_G, "inspect_adhoc_nocargo", q)
	I.checkRewrite(q, "ad hoc quest")
	lu.assertFalse(q:hasQuestData(), "hasQuestData")
	local player = H.newPlayer({ zone = "space_naboo", ship = {}, pilot = "rebel" })

	assertCleanFailure("ad hoc quest without cargo", q, player)
	assertAbandonedOnce("ad hoc quest without cargo", player)
end

-- AC-7
function TestInspectMissingData:test_an_ad_hoc_quest_with_an_empty_ship_list_fails_cleanly_at_setup()
	-- storm-tier2-oberhaur: an empty validSpawns no longer fails (SWG inspect.java: it means "any spawner"); see test_storm_tier2_inspect_shared.lua
	local variants = {
		noShips = { shipList = {}, validSpawns = { { spawnName = "a", x = 1, z = 2, y = 3 } } },
	}

	for key, v in pairs(variants) do
		H.reset()

		local q = SpaceInspectScreenplay:new {
			className = "inspect_adhoc_" .. key, questName = "adhoc_" .. key, questType = "inspect", questZone = "space_endor",
			shipList = v.shipList, validSpawns = v.validSpawns, giveSpawnWaypoint = 1, cargo = "sector_recon_data",
		}

		rawset(_G, "inspect_adhoc_" .. key, q)
		I.checkRewrite(q, "ad hoc quest " .. key)
		lu.assertFalse(q:hasQuestData(), key .. ": hasQuestData")
		local player = H.newPlayer({ zone = "space_endor", ship = {}, pilot = "rebel" })

		assertCleanFailure(key, q, player)
		assertAbandonedOnce(key, player)
	end
end

-- AC-7
function TestInspectMissingData:test_has_quest_data_is_true_for_the_five_quests()
	for _, name in ipairs(I.NAMES) do
		lu.assertTrue(I.fresh(name).quest:hasQuestData(), label(name) .. ": hasQuestData")
	end
end

-- AC-7
function TestInspectMissingData:test_a_quest_with_data_logs_no_error_at_setup()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()

		lu.assertEquals(I.errorLogs(), {}, label(name) .. ": no LT_ERROR line")
		lu.assertTrue(sc:active(), label(name) .. ": still active")
	end
end
