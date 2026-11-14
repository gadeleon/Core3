-- Persistent master mission quest type: the type, its wiring and the stock SpaceDestroyScreenplay.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-1, AC-2; Content contract 1 to 4; I-1, I-8).
--
-- The engine load gate (the real server loads the scripts) is not a Lua test; see 02-test-plan.md.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local SMD_FILE = "bin/scripts/screenplays/space/SpaceMasterDestroyScreenplay.lua"
local SDS_FILE = "bin/scripts/screenplays/space/SpaceDestroyScreenplay.lua"
local SCREENPLAYS = "bin/scripts/screenplays/space/screenplays.lua"
local SDS_STOCK_COMMIT = "48a226cb6d"

local function inherits(q, class)
	local mt = getmetatable(q)

	for _ = 1, 8 do
		if mt == nil then
			return false
		end

		if mt == class or mt.__index == class then
			return true
		end

		mt = getmetatable(mt.__index)
	end

	return false
end

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function smd() return H.expectGlobal("SpaceMasterDestroyScreenplay", SMD_FILE .. " must define the global SpaceMasterDestroyScreenplay (feature space-master-mission-quest-type)") end

TestMasterMissionQuestTypeType = {}

function TestMasterMissionQuestTypeType:setUp() H.reset() end

-- AC-1
function TestMasterMissionQuestTypeType:test_the_quest_type_file_exists()
	lu.assertNotNil(readFile(SMD_FILE), SMD_FILE .. " does not exist")
end

-- AC-1
function TestMasterMissionQuestTypeType:test_space_master_destroy_screenplay_is_a_space_quest_logic_registered_without_autostart()
	local q = smd()

	lu.assertTrue(inherits(q, SpaceQuestLogic), "SpaceMasterDestroyScreenplay inherits SpaceQuestLogic")
	lu.assertFalse(inherits(q, SpaceDestroyScreenplay), "SpaceMasterDestroyScreenplay does not inherit SpaceDestroyScreenplay (D-2)")
	lu.assertEquals(rawget(q, "className"), "SpaceMasterDestroyScreenplay", "className")

	local reg = H.registered("SpaceMasterDestroyScreenplay")

	lu.assertNotNil(reg, "registerScreenPlay(\"SpaceMasterDestroyScreenplay\", false) was not called")
	lu.assertEquals(reg.start, false, "registered with start = false")
end

-- AC-1: the three observers' handler names are fixed by the migration of persisted observers
function TestMasterMissionQuestTypeType:test_the_handlers_and_events_the_persisted_observers_call_exist()
	local q = smd()

	for _, name in ipairs({ "enteredZone", "onLoggedIn", "notifyDestroyedShip", "remindProgress", "completeQuest", "resetQuest",
		"startQuest", "arrive", "getKillCount", "ensureObservers", "dropObservers", "clearProgress" }) do
		lu.assertEquals(type(q[name]), "function", "SpaceMasterDestroyScreenplay:" .. name)
	end

	lu.assertEquals(q.REMINDER_DELAY, 5, "REMINDER_DELAY (seconds)")
end

-- AC-1: no own abortQuest (the shared SpaceQuestLogic one is used) and no own failQuest (nothing can fail a master mission)
function TestMasterMissionQuestTypeType:test_it_has_no_own_abort_quest_or_fail_quest()
	local q = smd()

	lu.assertNil(rawget(q, "abortQuest"), "SpaceMasterDestroyScreenplay must not define abortQuest (the shared SpaceQuestLogic:abortQuest is the hook)")
	lu.assertNil(rawget(q, "failQuest"), "SpaceMasterDestroyScreenplay must not define failQuest")
	lu.assertIs(q.abortQuest, SpaceQuestLogic.abortQuest, "abortQuest is the inherited SpaceQuestLogic one")
	lu.assertIs(q.failQuest, SpaceQuestLogic.failQuest, "failQuest is the inherited (no-op) SpaceQuestLogic one")
end

-- AC-1: screenplays.lua includes the type exactly once, directly after the SDS include
function TestMasterMissionQuestTypeType:test_screenplays_lua_includes_the_type_once_directly_after_the_destroy_type()
	local text = readFile(SCREENPLAYS)

	lu.assertNotNil(text, SCREENPLAYS)

	local include = 'includeFile("space/SpaceMasterDestroyScreenplay.lua")'
	local _, n = text:gsub(include:gsub("%p", "%%%0"), "")

	lu.assertEquals(n, 1, SCREENPLAYS .. ": number of SpaceMasterDestroyScreenplay includes")

	local lines = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = line
	end

	for i, line in ipairs(lines) do
		if line:find('includeFile("space/SpaceDestroyScreenplay.lua")', 1, true) then
			lu.assertEquals(lines[i + 1], include, "the line directly after the SpaceDestroyScreenplay include")
			return
		end
	end

	lu.fail("the SpaceDestroyScreenplay include is missing from " .. SCREENPLAYS)
end

-- AC-1, I-1: the harness loads the type at the same position as screenplays.lua (the quest-type list mirrors it)
function TestMasterMissionQuestTypeType:test_the_harness_quest_type_list_has_the_type_directly_after_the_destroy_type()
	local text = readFile("tests/lua/harness/init.lua")

	lu.assertNotNil(text:find('"SpaceDestroyScreenplay", "SpaceMasterDestroyScreenplay"', 1, true), "harness/init.lua SPACE_QUEST_TYPES")
end

-- AC-1, I-1: the four tables
for _, case in ipairs(S.CASES) do
	for _, global in ipairs({ case.ONE, case.TWO }) do
		TestMasterMissionQuestTypeType["test_" .. global .. "_is_a_master_destroy_quest_that_does_not_set_the_old_field"] = function()
			local q = S.quest(case, global)

			lu.assertTrue(inherits(q, smd()), global .. ": inherits SpaceMasterDestroyScreenplay")
			lu.assertFalse(inherits(q, SpaceDestroyScreenplay), global .. ": does not inherit SpaceDestroyScreenplay")
			lu.assertNil(rawget(q, "failOnLeaveZone"), global .. ": failOnLeaveZone")
			lu.assertEquals(rawget(q, "questZone"), "space_light1", global .. ": questZone")
			lu.assertNil(q.failOnLeaveZone, global .. ": no inherited failOnLeaveZone either")

			local reg = H.registered(global)

			lu.assertNotNil(reg, global .. ": registered")
			lu.assertEquals(reg.start, true, global .. ": registered with start = true")
		end
	end
end

-- AC-1, I-1: fixture conformance of the three data fields the type reads
for _, case in ipairs(S.CASES) do
	for n, global in ipairs({ case.ONE, case.TWO }) do
		TestMasterMissionQuestTypeType["test_" .. global .. "_reads_its_zone_ships_and_kill_count_from_the_swg_fixture"] = function()
			local q = S.quest(case, global)
			local rec = case.M.fixtureOf(global)

			lu.assertEquals(rawget(q, "questZone"), rec:get("questZone"), global .. ": questZone")
			lu.assertEquals(rawget(q, "shipTypes"), rec:list("shipList"), global .. ": shipTypes = shipList")
			lu.assertEquals(rawget(q, "killsRequired"), rec:num("killCount"), global .. ": killsRequired = killCount")
			lu.assertEquals(rec:num("killVariance"), 0, global .. ": killVariance is 0 (the quest reads no variance)")
			lu.assertEquals(rawget(q, "killsRequired"), n == 1 and 30 or 1, global .. ": 30 kills (mission 1) / 1 kill (mission 2)")
		end
	end
end

-- AC-2, I-8: SDS is the stock commit before the A-1 hunks. space-quest-player-ship-destroyed (C4) adds exactly one function to it,
-- SpaceDestroyScreenplay:isRunInProgress; nothing else may differ.
function TestMasterMissionQuestTypeType:test_space_destroy_screenplay_is_the_stock_commit_plus_only_the_run_check()
	local problems, why = require("psd_pins").problems(SDS_STOCK_COMMIT, SDS_FILE, { runCheck = "SpaceDestroyScreenplay" })

	if problems == nil then
		lu.skip("git cannot show " .. SDS_STOCK_COMMIT .. ": " .. tostring(why))
	end

	lu.assertEquals(problems, {}, SDS_FILE .. " differs from " .. SDS_STOCK_COMMIT .. " by more than the isRunInProgress function")
end

-- AC-2, I-8: no file under bin/scripts mentions the opt-in field any more
function TestMasterMissionQuestTypeType:test_no_script_mentions_fail_on_leave_zone()
	local rc, out = shell("grep -rIl failOnLeaveZone bin/scripts")

	lu.assertEquals(rc, 1, "grep found failOnLeaveZone in: " .. out)
end

-- AC-2: SDS itself has no such field or branch
function TestMasterMissionQuestTypeType:test_space_destroy_screenplay_has_no_fail_on_leave_zone_field()
	lu.assertNil(SpaceDestroyScreenplay.failOnLeaveZone, "SpaceDestroyScreenplay.failOnLeaveZone")
end

-- AC-2: the stock destroy quests still fail on leaving the zone (the existing c4/c5 tests keep running; this is the table-driven twin)
for _, global in ipairs({ "destroy_corellia_imperial_2", "destroy_corellia_rebel_2" }) do
	TestMasterMissionQuestTypeType["test_" .. global .. "_still_fails_on_leaving_its_zone"] = function()
		local case = global:find("imperial") and S.CASES[1] or S.CASES[2]
		local q = case.M.quest(global)

		H.reset()

		local player = S.pilot(case, { zone = q.questZone })

		q:startQuest(player, "")
		H.advance(0)
		H.zoneSwitch(player, q.questZone)
		S.pump(500, "zone entry")
		H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = q.shipTypes[1], zone = q.questZone }))
		S.pump(1500, "first kill")
		lu.assertTrue(S.isActive(player, q), global .. ": precondition: active")
		H.zoneSwitch(player, "space_lok")
		S.pump(5000, "leaving the zone")
		lu.assertFalse(S.isActive(player, q), global .. ": fails on leaving its zone")
		lu.assertNil(rawget(q, "failOnLeaveZone"), global .. ": the table does not set the field")
	end
end
