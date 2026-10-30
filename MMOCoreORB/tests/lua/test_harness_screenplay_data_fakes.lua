-- Harness additions of space-master-mission-quest-type: screenplay data fakes, the persistence argument recorded on observers, H.simulateRestart.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (Test strategy hints, harness additions 1 to 4).
--
-- These tests check the fakes against DirectorManager.cpp (DM:949, 1217, 1256 for the data, DM:3294 for lua_tointeger) so that the quest tests can trust them.

local lu = require("luaunit")
local H = require("harness")

H.boot()

TestHarnessScreenplayDataFakes = {}

function TestHarnessScreenplayDataFakes:setUp() H.reset() end

local function player() return H.newPlayer({ name = "Ace" }) end

function TestHarnessScreenplayDataFakes:test_read_returns_an_empty_string_when_nothing_is_stored()
	lu.assertEquals(readScreenPlayData(player(), "Sp", "killCount"), "")
end

function TestHarnessScreenplayDataFakes:test_write_stores_the_value_as_a_string_per_player_screenplay_and_variable()
	local a, b = player(), player()

	writeScreenPlayData(a, "Sp", "killCount", 12)
	writeScreenPlayData(a, "Sp", "other", "x")
	writeScreenPlayData(a, "Other", "killCount", "z")

	lu.assertEquals(readScreenPlayData(a, "Sp", "killCount"), "12")
	lu.assertEquals(readScreenPlayData(a, "Sp", "other"), "x")
	lu.assertEquals(readScreenPlayData(a, "Other", "killCount"), "z")
	lu.assertEquals(readScreenPlayData(b, "Sp", "killCount"), "", "another player")
end

function TestHarnessScreenplayDataFakes:test_delete_removes_one_variable_and_clear_removes_the_screenplay()
	local p = player()

	writeScreenPlayData(p, "Sp", "a", "1")
	writeScreenPlayData(p, "Sp", "b", "2")
	writeScreenPlayData(p, "Other", "a", "3")
	deleteScreenPlayData(p, "Sp", "a")
	lu.assertEquals({ readScreenPlayData(p, "Sp", "a"), readScreenPlayData(p, "Sp", "b") }, { "", "2" })
	clearScreenPlayData(p, "Sp")
	lu.assertEquals({ readScreenPlayData(p, "Sp", "b"), readScreenPlayData(p, "Other", "a") }, { "", "3" })
end

function TestHarnessScreenplayDataFakes:test_a_non_player_stores_nothing()
	local npc = H.newNpc({ name = "Npc" })

	writeScreenPlayData(npc, "Sp", "a", "1")
	lu.assertEquals(readScreenPlayData(npc, "Sp", "a"), "")
	lu.assertEquals(readScreenPlayData(nil, "Sp", "a"), "")
end

function TestHarnessScreenplayDataFakes:test_the_data_lives_on_the_ghost_and_survives_a_simulated_restart()
	local p = player()

	writeScreenPlayData(p, "Sp", "a", "5")
	H.simulateRestart()
	lu.assertEquals(readScreenPlayData(p, "Sp", "a"), "5")
	H.reset()
	lu.assertEquals(readScreenPlayData(player(), "Sp", "a"), "", "a new harness state starts empty")
end

function TestHarnessScreenplayDataFakes:test_create_observer_records_the_persistence_argument_as_given()
	local p = player()

	createObserver(ZONESWITCHED, "Sp", "one", p, 1)
	createObserver(ZONESWITCHED, "Sp", "two", p, true)
	createObserver(ZONESWITCHED, "Sp", "three", p)

	lu.assertEquals(H.Engine.observerPersistence(ZONESWITCHED, "Sp", "one", p), 1)
	lu.assertEquals(math.type(H.Engine.observerPersistence(ZONESWITCHED, "Sp", "one", p)), "integer")
	lu.assertEquals(H.Engine.observerPersistence(ZONESWITCHED, "Sp", "two", p), true)
	lu.assertNil(H.Engine.observerPersistence(ZONESWITCHED, "Sp", "three", p))
	lu.assertNil(H.Engine.observerPersistence(ZONESWITCHED, "Sp", "missing", p), "no such observer")
end

-- DM:3294: lua_tointeger turns true, false and nil into 0 (transient); integers and numbers that read as one convert
function TestHarnessScreenplayDataFakes:test_a_restart_keeps_exactly_the_observers_lua_tointeger_makes_persistent()
	local p = player()
	local cases = { { "int", 1, true }, { "two", 2, true }, { "float", 1.0, true }, { "text", "1", true },
		{ "zero", 0, false }, { "true", true, false }, { "false", false, false }, { "nil", nil, false }, { "table", {}, false } }

	for _, c in ipairs(cases) do
		createObserver(DESTROYEDSHIP, "Sp", c[1], p, c[2])
	end

	H.simulateRestart()

	for _, c in ipairs(cases) do
		lu.assertEquals(H.hasObserver(DESTROYEDSHIP, "Sp", c[1], p), c[3], "persistence argument " .. c[1])
	end
end

function TestHarnessScreenplayDataFakes:test_a_restart_clears_shared_memory_and_pending_events_and_keeps_players_and_journal()
	local p = player()

	writeData("a:b", 3)
	writeStringData("a:s", "x")
	createEvent(5000, "Sp", "later", p, "")
	p.ghost.journalActive[1234] = true
	p.zone = "space_light1"

	H.simulateRestart()

	lu.assertEquals(H.Engine.sharedMemoryKeys(), {})
	lu.assertEquals(#H.pendingEvents(), 0)
	lu.assertEquals(readData("a:b"), 0)
	lu.assertTrue(p.ghost.journalActive[1234], "journal state stays")
	lu.assertEquals(p.zone, "space_light1", "the player stays where it is")
	lu.assertEquals(getSceneObject(p.objectID), p, "the player is still in the registry")
end

function TestHarnessScreenplayDataFakes:test_the_logged_in_event_constant_exists()
	lu.assertEquals(type(LOGGEDIN), "number")
	lu.assertNotEquals(LOGGEDIN, ZONESWITCHED)
	lu.assertNotEquals(LOGGEDIN, DESTROYEDSHIP)
end
