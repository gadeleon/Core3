-- Storm tier 2: the shared SpaceInspectScreenplay change (an empty validSpawns means "any spawner") and inspect/imperial_ss_1 running through it.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-5, AC-3 (a); Shared code changes; FI-7; D-14; R-5).
--
-- SWG's inspect.java gives no waypoints and skips the spawner match when the validSpawns column is empty (INSP:97, 108-111, 315-328). Core3 used to
-- fail such a quest at setup and to reject every ship; the five older inspect tables and every squadron table have a non-empty list and must behave
-- exactly as before. The edit of test_inspect_setup_and_zone.lua (the `noSpawns` variant is gone) is listed in the test plan.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local I = require("inspect_scenario")

T.load()
I.load()

local NAME = "imperial_ss_1"

local adhocCount = 0

-- An ad hoc inspect table, registered as a global like every quest
local function adhoc(fields)
	adhocCount = adhocCount + 1

	local name = "adhoc_" .. adhocCount
	local q = SpaceInspectScreenplay:new {
		className = "inspect_" .. name, questName = name, questType = "inspect", questZone = fields.zone or "space_lok",
		shipList = fields.shipList or { "nym_lieutenant_tier2" }, validSpawns = fields.validSpawns or {}, giveSpawnWaypoint = fields.giveSpawnWaypoint or 0,
		cargo = fields.cargo or "hostage_orders",
	}

	rawset(_G, "inspect_" .. name, q)

	return q
end

local function agent(shipName, spawner)
	return H.worldAgent({ shipName = shipName, cargo = "hostage_orders", spawner = spawner, zone = "space_lok" })
end

---------------------------------------------------------------------------------------------
-- AC-5: hasQuestData and isQuestTarget
---------------------------------------------------------------------------------------------

TestStormT2InspectShared = {}

function TestStormT2InspectShared:setUp() H.reset() end

-- AC-5
function TestStormT2InspectShared:test_a_table_with_an_empty_valid_spawns_has_quest_data()
	I.checkRewrite(adhoc({}), "ad hoc quest")
	lu.assertTrue(adhoc({}):hasQuestData(), "ship list and cargo are enough")
end

-- AC-5
function TestStormT2InspectShared:test_an_empty_ship_list_or_an_empty_cargo_still_has_no_quest_data()
	lu.assertFalse(adhoc({ shipList = {} }):hasQuestData(), "no ships")
	lu.assertFalse(adhoc({ cargo = "" }):hasQuestData(), "no cargo")
	lu.assertFalse(adhoc({ shipList = {}, validSpawns = { { spawnName = "a", x = 1, z = 2, y = 3 } } }):hasQuestData(), "no ships, with a spawner")
	lu.assertFalse(adhoc({ cargo = "", validSpawns = { { spawnName = "a", x = 1, z = 2, y = 3 } } }):hasQuestData(), "no cargo, with a spawner")
end

-- AC-5
function TestStormT2InspectShared:test_an_empty_valid_spawns_accepts_a_listed_ship_from_any_spawner()
	local q = adhoc({})

	lu.assertTrue(q:isQuestTarget(agent("nym_lieutenant_tier2", "nym_lieutenant_1")), "spawner nym_lieutenant_1")
	lu.assertTrue(q:isQuestTarget(agent("nym_lieutenant_tier2", "nym_lieutenant_lokstation_spawner")), "spawner nym_lieutenant_lokstation_spawner")
	lu.assertTrue(q:isQuestTarget(agent("nym_lieutenant_tier2", "some_squadron_spawner_that_is_in_no_list")), "any other spawner name")
	lu.assertTrue(q:isQuestTarget(agent("nym_lieutenant_tier2", nil)), "a ship with no SpawnerName key at all")
end

-- AC-5
function TestStormT2InspectShared:test_an_empty_valid_spawns_still_rejects_an_unlisted_ship_and_a_non_ship()
	local q = adhoc({})

	lu.assertFalse(q:isQuestTarget(agent("nym_fighter_tier2", "nym_lieutenant_1")), "another ship template")
	lu.assertFalse(q:isQuestTarget(agent("nym_lieutenant_tier3", "nym_lieutenant_1")), "another Lieutenant")
	lu.assertFalse(q:isQuestTarget(nil), "nil")
	lu.assertFalse(q:isQuestTarget(H.newPlayer({})), "a player is not a ship agent")
end

-- AC-5: a table with spawners behaves as at 85cfb1dc28
function TestStormT2InspectShared:test_a_non_empty_valid_spawns_still_requires_a_listed_spawner()
	local q = adhoc({ validSpawns = { { spawnName = "listed_spawner", x = 1, z = 2, y = 3 } } })

	lu.assertTrue(q:hasQuestData(), "hasQuestData")
	lu.assertTrue(q:isQuestTarget(agent("nym_lieutenant_tier2", "listed_spawner")), "a listed ship from the listed spawner")
	lu.assertFalse(q:isQuestTarget(agent("nym_lieutenant_tier2", "unlisted_spawner")), "a listed ship from an unlisted spawner")
	lu.assertFalse(q:isQuestTarget(agent("nym_lieutenant_tier2", nil)), "a listed ship with no SpawnerName")
	lu.assertFalse(q:isQuestTarget(agent("nym_fighter_tier2", "listed_spawner")), "an unlisted ship from the listed spawner")
end

-- AC-5: the five older quests keep a non-empty list and are unchanged by the edit
function TestStormT2InspectShared:test_the_five_older_inspect_tables_still_reject_a_listed_ship_from_an_unlisted_spawner()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)
		local ship = sc:target(1, { spawner = "no_such_spawner_in_any_list" })

		lu.assertFalse(sc.quest:isQuestTarget(ship), name .. ": a listed ship from an unlisted spawner")
		lu.assertTrue(sc.quest:isQuestTarget(sc:target(1)), name .. ": a listed ship from its first spawner")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: setup with an empty list
---------------------------------------------------------------------------------------------

TestStormT2InspectSetup = {}

function TestStormT2InspectSetup:setUp() H.reset() end

local function startAdhoc(q, label)
	local player = H.newPlayer({ zone = q.questZone, ship = {}, pilot = "imperial" })

	local ok, err = pcall(function()
		q:startQuest(player, "")
		H.advance(10000)
	end)

	lu.assertTrue(ok, label .. ": raises no Lua error, got " .. tostring(err))

	return player
end

-- AC-5, AC-3 (a)
function TestStormT2InspectSetup:test_a_table_with_an_empty_valid_spawns_sets_up_without_failing_and_gives_no_waypoint()
	local q = adhoc({ giveSpawnWaypoint = 1 })

	I.checkRewrite(q, "ad hoc quest")

	local player = startAdhoc(q, "empty validSpawns")

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), "the quest is still active")
	lu.assertEquals(I.errorLogs(), {}, "no LT_ERROR line")
	lu.assertEquals(#player.ghost.waypoints, 0, "no waypoint (zero spawns)")
	lu.assertEquals(#I.msgs(player, I.MSG_WAYPOINTS), 0, "no waypoint notice")
	lu.assertEquals(#I.msgs(player, I.MSG_ABANDONED), 0, "no abandoned message")
	lu.assertTrue(H.hasObserver(INSPECTEDSHIP, q.className, "inspectedShip", player), "the INSPECTEDSHIP observer is registered")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, q.className, "dockedShip", player), "the SHIPDOCKED observer is registered")
end

-- AC-5: a missing ship list or cargo fails cleanly, and the error text no longer names validSpawns
function TestStormT2InspectSetup:test_an_empty_ship_list_or_cargo_still_fails_cleanly_at_setup_and_the_log_does_not_name_valid_spawns()
	for key, fields in pairs({ noShips = { shipList = {} }, noCargo = { cargo = "" } }) do
		H.reset()

		local q = adhoc(fields)
		local player = startAdhoc(q, key)

		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), key .. ": the quest ends not active")
		lu.assertEquals(#I.msgs(player, I.MSG_ABANDONED), 1, key .. ": inspect_abandoned messages sent")
		lu.assertFalse(H.hasObserver(INSPECTEDSHIP, q.className, "inspectedShip", player), key .. ": no INSPECTEDSHIP observer")

		local named = false

		for _, msg in ipairs(I.errorLogs()) do
			if msg:find(q.className, 1, true) then
				named = true
				lu.assertNil(msg:find("validSpawns", 1, true), key .. ": the error text must not name validSpawns any more: " .. msg)
			end
		end

		lu.assertTrue(named, key .. ": an LT_ERROR line naming " .. q.className)
	end
end

---------------------------------------------------------------------------------------------
-- AC-3 (a): inspect/imperial_ss_1 itself
---------------------------------------------------------------------------------------------

TestStormT2InspectRun = {}

function TestStormT2InspectRun:setUp() H.reset() end

local function fresh()
	T.quest(T.M1)
	return I.fresh(NAME)
end

-- AC-3 (a)
function TestStormT2InspectRun:test_the_mission_starts_without_failing_and_adds_no_waypoint()
	local sc = fresh():toSetup()

	lu.assertTrue(sc:active(), "the quest is active")
	lu.assertEquals(I.errorLogs(), {}, "no LT_ERROR line")
	lu.assertEquals(sc:waypoints(), {}, "no waypoint")
	lu.assertEquals(sc:vector(), {}, "no waypoint ids stored")
	lu.assertEquals(sc:observers(), { zone = 1, inspect = 1, dock = 1 }, "observers on the player")

	sc:notice()
	lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 0, "no waypoint notice")
	lu.assertTrue(sc:active(), "still active after the notice time")
end

-- AC-3 (a)
function TestStormT2InspectRun:test_a_lieutenant_from_any_spawner_reports_the_cargo_found_and_docking_completes_the_mission()
	for _, spawner in ipairs({ "nym_lieutenant_1", "nym_lieutenant_lokstation_spawner", "nym_lieutenant_2", "nym_lieutenant_3", "a_spawner_the_list_never_named" }) do
		local sc = fresh():toSetup()
		local ship = sc:target(1, { spawner = spawner })

		sc:inspect(ship)
		lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, spawner .. ": inspect_found_cargo messages")
		lu.assertTrue(sc:taskActive(2), spawner .. ": the dock task is active")

		sc:dock(ship)
		lu.assertTrue(sc:complete(), spawner .. ": the mission is complete after docking")
		lu.assertFalse(sc:active(), spawner .. ": no longer active")
		lu.assertEquals(I.errorLogs(), {}, spawner .. ": no LT_ERROR line")
	end
end

-- AC-3 (a)
function TestStormT2InspectRun:test_another_ship_template_is_not_a_target()
	local sc = fresh():toSetup()
	local other = sc:target(1, { shipName = "nym_fighter_tier2", spawner = "nym_lieutenant_1" })

	sc:inspect(other)
	sc:dock(other)
	lu.assertFalse(sc:complete(), "docking another ship does not complete the mission")
	lu.assertTrue(sc:active(), "the mission keeps running")
end

-- AC-3 (a): a Lieutenant without the cargo does not count
function TestStormT2InspectRun:test_a_lieutenant_that_carries_another_cargo_does_not_complete_the_mission()
	local sc = fresh():toSetup()
	local ship = sc:target(1, { spawner = "nym_lieutenant_1", cargo = "something_else" })

	sc:dock(ship, getHashCode("something_else"))
	lu.assertFalse(sc:complete(), "wrong cargo")
	lu.assertTrue(sc:active(), "still active")
end
