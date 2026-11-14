-- The C++ hook of a destroyed player ship, checked statically (the harness cannot run C++): DestroyShipTask case 0 hands every officer
-- aboard a task that calls <questType>_<questName>:playerShipDestroyed for each space mission on their datapad.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-2, AC-1, AC-10, C1, C2, C9, D-2, D-3)
-- The ninja build, the gtest (PlayerShipDestroyedNoticeTest.*) and the in-game checklist are the other gates of AC-2.

local lu = require("luaunit")
local H = require("harness")

local TASK = H.ROOT .. "/src/server/zone/objects/ship/events/DestroyShipTask.h"
local HEADER = H.ROOT .. "/src/server/zone/objects/ship/events/PlayerShipDestroyedNotice.h"
local GTEST = H.ROOT .. "/src/tests/PlayerShipDestroyedNoticeTest.cpp"

local function read(path)
	local f = io.open(path, "r")

	lu.assertNotNil(f, "cannot read " .. path .. " (C1/C2/C9 of the spec)")

	local text = f:read("a")

	f:close()

	return text
end

-- The text of `case 0: {` up to `case 1: {` of DestroyShipTask::run
local function case0()
	local src = read(TASK)
	local first = src:find("case 0: {", 1, true)

	lu.assertNotNil(first, "DestroyShipTask::run: case 0 not found")

	local last = src:find("case 1: {", first, true)

	lu.assertNotNil(last, "DestroyShipTask::run: case 1 not found")

	return src:sub(first, last - 1)
end

local function mustFind(body, needle, from, what)
	local at = body:find(needle, from or 1, true)

	lu.assertNotNil(at, (what or "DestroyShipTask case 0") .. ": expected to find `" .. needle .. "`")

	return at
end

TestDestroyShipTaskHook = {}

-- AC-2 (C2 1)
function TestDestroyShipTaskHook:test_case_0_reads_the_destroying_bit_before_anything_else()
	local body = case0()
	local first = mustFind(body, "bool wasDestroying = ship->isDestroying();")
	local before = body:sub(#"case 0: {" + 1, first - 1)

	lu.assertNil(before:find("[%w_]+%s*%("), "a call comes before `bool wasDestroying = ship->isDestroying();`: " .. before:gsub("%s+", " "))
	lu.assertTrue(first < mustFind(body, "setOptionBit(OptionBitmask::DESTROYING, true)"), "wasDestroying is read before the DESTROYING bit is set")
end

-- AC-2 (C2 2): after the DestroyShipMessage broadcast, before the persistence branch
function TestDestroyShipTaskHook:test_the_notice_comes_after_the_destroy_message_and_before_the_persistence_branch()
	local body = case0()
	local broadcast = mustFind(body, "ship->broadcastMessage(msg, false);")
	local gate = mustFind(body, "PlayerShipDestroyedNotice::shouldNotify(ship->isPlayerShip(), wasDestroying)")
	local persistence = mustFind(body, "if (pilot == nullptr && ship->getPersistenceLevel() == 0)")

	lu.assertTrue(broadcast < gate, "the notice comes after the DestroyShipMessage broadcast")
	lu.assertTrue(gate < persistence, "the notice comes before the persistence branch")
end

-- AC-2 (C2 2): the officers, in the seats of C1
function TestDestroyShipTaskHook:test_the_officer_ids_come_from_the_four_seats_and_pob_picks_the_form()
	local body = case0()
	local officers = mustFind(body, "PlayerShipDestroyedNotice::getOfficerIDs(")
	local statement = body:sub(officers, officers + 700)

	lu.assertNotNil(statement:find("ship->isPobShip()", 1, true), "isPobShip() picks the form")

	local at = 1

	for _, seat in ipairs({ "getPilot", "getShipOperator", "getTurretOperatorTop", "getTurretOperatorBottom" }) do
		local found = mustFind(statement, seat, at, "getOfficerIDs arguments")

		at = found + 1 -- pilot, operations, turret top, turret bottom, in that order
	end
end

-- AC-2 (C2 2): one task per officer, named
function TestDestroyShipTaskHook:test_each_officer_gets_its_own_task_named_player_ship_destroyed_lambda()
	local body = case0()
	local run = mustFind(body, "Core::getTaskManager()->executeTask(")
	local named = mustFind(body, '"PlayerShipDestroyedLambda"', run)
	local loop = mustFind(body, "for (", mustFind(body, "PlayerShipDestroyedNotice::getOfficerIDs("))

	lu.assertTrue(loop < run and run < named, "the task is created inside a loop over the officer ids")
end

-- AC-2 (C2 3): the lambda
function TestDestroyShipTaskHook:test_the_lambda_resolves_the_officer_locks_only_the_player_and_snapshots_the_datapad()
	local body = case0()
	-- everything from the officer ids to the task name: the lambda is written inline or in a variable before the executeTask call
	local from = mustFind(body, "PlayerShipDestroyedNotice::getOfficerIDs(")

	mustFind(body, "Core::getTaskManager()->executeTask(", from)

	local lambda = body:sub(from, mustFind(body, '"PlayerShipDestroyedLambda"', from))

	mustFind(lambda, "getObject(", 1, "the lambda")
	mustFind(lambda, "isPlayerCreature()", 1, "the lambda")
	lu.assertNotNil(lambda:find("== nullptr", 1, true), "the lambda returns on a null officer")

	local lock = mustFind(lambda, "Locker lock(member)", 1, "the lambda")
	local datapad = mustFind(lambda, "getDatapad()", lock, "the lambda")
	local quest = mustFind(lambda, "PlayerShipDestroyedNotice::getQuestScreenplay(", datapad, "the lambda")

	lu.assertTrue(lock < datapad and datapad < quest, "lock, then the datapad walk, then the screenplay names")
	mustFind(lambda, "getQuestType()", datapad, "the lambda")
	mustFind(lambda, "getQuestName()", datapad, "the lambda")

	lu.assertNil(lambda:find("Locker sLock", 1, true), "the lambda does not hold the ship lock (D-3)")
	lu.assertNil(lambda:find("Locker lock(ship", 1, true), "the lambda does not lock the ship (D-3)")

	-- the Lua calls come after the snapshot: they run once the datapad walk is over
	local create = mustFind(lambda, 'createFunction(', quest, "the lambda")
	local call = mustFind(lambda, "callFunction()", create, "the lambda")
	local statement = lambda:sub(create, call)

	lu.assertNotNil(statement:find('"playerShipDestroyed"', 1, true), "createFunction names \"playerShipDestroyed\"")
	lu.assertNotNil(statement:find("<< member", 1, true), "the officer is the argument")

	local _, pushes = statement:gsub("<<", "")

	lu.assertEquals(pushes, 1, "exactly one argument is pushed")
	mustFind(lambda, "DirectorManager::instance()->getLuaInstance()", 1, "the lambda")
end

-- AC-2 (C2 3): a Lua error in one quest does not stop the others (handleMissionAbort's guards)
function TestDestroyShipTaskHook:test_each_lua_call_is_guarded_and_logged_with_the_screenplay_name()
	local body = case0()
	-- everything from the officer ids to the task name: the lambda is written inline or in a variable before the executeTask call
	local from = mustFind(body, "PlayerShipDestroyedNotice::getOfficerIDs(")

	mustFind(body, "Core::getTaskManager()->executeTask(", from)

	local lambda = body:sub(from, mustFind(body, '"PlayerShipDestroyedLambda"', from))
	local try = mustFind(lambda, "try {", 1, "the lambda")
	local create = mustFind(lambda, "createFunction(", 1, "the lambda")
	local panic = mustFind(lambda, "catch (const LuaPanicException&", create, "the lambda")
	local general = mustFind(lambda, "catch (Exception&", panic, "the lambda")

	lu.assertTrue(try < create, "createFunction is inside the try")
	lu.assertNotNil(lambda:sub(panic, general):find("error()", 1, true), "the panic handler logs with error()")
	lu.assertNotNil(lambda:sub(general):find("error()", 1, true), "the generic handler logs with error()")

	-- the try is inside the loop over the missions, so one failing quest does not skip the rest
	local loop = lambda:sub(1, try):match(".*()for %(")

	lu.assertNotNil(loop, "a loop over the quest names comes before the try")
end

-- AC-2 (C2 4): nothing else in case 0 changes
function TestDestroyShipTaskHook:test_the_rest_of_the_destroy_task_keeps_its_timings_and_zone_switch()
	local src = read(TASK)

	lu.assertNotNil(src:find("reschedule(5000);", 1, true), "case 0 still reschedules 5 s")
	lu.assertNotNil(src:find("(6000 + System::random(2000))", 1, true), "the zone switch lambda keeps its 6-8 s")
	lu.assertNotNil(src:find('shipMember->switchZone(zoneName, memberPosition.getX()', 1, true), "the respawn zone switch")
	lu.assertNotNil(src:find("returnFromBattlefield(ship, pilot, zone->getZoneName())", 1, true), "the battlefield return")
	lu.assertNotNil(src:find('#include "server/zone/objects/ship/events/PlayerShipDestroyedNotice.h"', 1, true), "includes the notice helper")
end

---------------------------------------------------------------------------------------------
-- C1 / C9: the pure helper and its gtest exist, shaped like ShipFactionAttackRule.h
---------------------------------------------------------------------------------------------

TestPlayerShipDestroyedNoticeFiles = {}

-- AC-1 (C1)
function TestPlayerShipDestroyedNoticeFiles:test_the_helper_is_header_only_and_pure()
	local src = read(HEADER)

	lu.assertNotNil(src:find("class PlayerShipDestroyedNotice", 1, true), "class PlayerShipDestroyedNotice")
	lu.assertNotNil(src:find("static bool shouldNotify(bool isPlayerShip, bool wasDestroying)", 1, true), "shouldNotify")
	lu.assertNotNil(src:find("static Vector<uint64> getOfficerIDs(bool isPobShip, uint64 pilotID, uint64 operationsID, uint64 turretTopID, uint64 turretBottomID)", 1, true), "getOfficerIDs")
	lu.assertNotNil(src:find("static String getQuestScreenplay(const String& questType, const String& questName)", 1, true), "getQuestScreenplay")
	lu.assertNotNil(src:find('#include "system/platform.h"', 1, true), "includes system/platform.h")

	for include in src:gmatch('#include%s+["<]([^">]+)[">]') do
		lu.assertNotNil(include:find("^system/") or include:find("^engine/"), "a pure helper includes only engine headers, not " .. include)
	end
end

-- C9
function TestPlayerShipDestroyedNoticeFiles:test_the_gtest_file_exists_in_the_tests_directory_the_cmake_glob_reads()
	local src = read(GTEST)

	lu.assertNotNil(src:find("PlayerShipDestroyedNoticeTest", 1, true), "a test class PlayerShipDestroyedNoticeTest (the engine gate filter name)")
	lu.assertNotNil(src:find("PlayerShipDestroyedNotice.h", 1, true), "includes the helper")
end
