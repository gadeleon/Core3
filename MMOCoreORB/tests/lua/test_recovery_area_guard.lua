-- The shared recovery guard: an area entry by a recovery ship that has not been captured does nothing, for EVERY recovery quest of every
-- squadron; a captured ship still walks its recovery points and completes the quest once after the last one.
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (AC-10, Shared code changes, invariant I-8, D-13; gap report item 19).
--
-- The set of quests is discovered at run time: every loaded quest global whose class chain reaches SpaceRecoveryScreenplay (CorSec, Havoc and RSF
-- loaded). The spec lists 11 today; the test asserts at least 11, so a silently empty loop fails, and builds one test per quest named after it.
--
-- "Captured" is the state SpaceRecoveryScreenplay:assignRecoveryPoints leaves: recoveryShipProgress = number of recovery points (:717).
-- "Not captured" leaves the key unset.

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")
local M = require("migration_scenario")

H.boot()
H.loadSpaceQuestTypes()
DR.loadSquadrons()

local function reaches(q, class)
	local mt = getmetatable(q)

	for _ = 1, 10 do
		if mt == nil then
			return false
		end

		if mt == class then
			return true
		end

		mt = getmetatable(mt)
	end

	return false
end

-- Sorted global names of every loaded quest table of the recovery family
local function recoveryGlobals()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		if reaches(rawget(_G, name), SpaceRecoveryScreenplay) then
			out[#out + 1] = name
		end
	end

	return out
end

local GLOBALS = recoveryGlobals()

local function progressKey(run) return run.ship.objectID .. ":" .. run.quest.className .. ":recoveryShipProgress:" end

local function progress(run) return readData(progressKey(run)) end

local function pendingMethods()
	local out = {}

	for _, e in ipairs(H.pendingEvents()) do
		out[#out + 1] = e.method
	end

	table.sort(out)
	return out
end

local function countOf(list, value)
	local n = 0

	for _, v in ipairs(list) do
		if v == value then
			n = n + 1
		end
	end

	return n
end

-- Everything an area entry could change that the guard promises to leave alone
local function observable(run)
	local p = run.player

	return {
		state = M.snapshot(p),
		messages = #H.messageLog(p),
		taunts = #H.tauntLog(p),
		music = #p.music,
		events = pendingMethods(),
		eventCalls = #H.Engine.callsTo("createEvent"),
		progress = progress(run),
	}
end

-- The coordinates of the waypoint stored for the quest, or nil
local function waypointOf(run)
	local id = tonumber(H.getQuestStatus(run.player, ":" .. run.quest.className .. ":waypointID"))

	if id == nil then
		return nil
	end

	local wp = getSceneObject(id)

	return wp and { wp.x, wp.z, wp.y } or nil
end

local function distance(a, b)
	return math.sqrt((a.x - b.x) ^ 2 + (a.z - b.z) ^ 2 + (a.y - b.y) ^ 2)
end

---------------------------------------------------------------------------------------------
-- I-8: the set
---------------------------------------------------------------------------------------------

TestRecoveryGuardSet = {}

function TestRecoveryGuardSet:setUp() H.reset() end

-- AC-10, I-8: today CorSec 2, Havoc 5 and RSF 4 (with the new duty)
function TestRecoveryGuardSet:test_at_least_11_recovery_quest_globals_are_found_in_all_three_squadrons()
	lu.assertTrue(#GLOBALS >= 11, "recovery quest globals found: " .. #GLOBALS .. " (" .. table.concat(GLOBALS, ", ") .. ")")

	local bySquadron = { corellia_privateer = 0, corellia_rebel = 0, viopa_rebel = 0, naboo_privateer = 0 }

	for _, name in ipairs(GLOBALS) do
		for key in pairs(bySquadron) do
			if name:find(key, 1, true) then
				bySquadron[key] = bySquadron[key] + 1
			end
		end
	end

	lu.assertTrue(bySquadron.corellia_privateer >= 2, "CorSec recovery quests: " .. bySquadron.corellia_privateer)
	lu.assertTrue(bySquadron.naboo_privateer >= 4, "RSF recovery quests: " .. bySquadron.naboo_privateer)
	lu.assertTrue(bySquadron.corellia_rebel + bySquadron.viopa_rebel >= 5, "Havoc recovery quests: " .. (bySquadron.corellia_rebel + bySquadron.viopa_rebel))
end

-- AC-10, I-8: the new RSF duty is one of them
function TestRecoveryGuardSet:test_recovery_duty_naboo_privateer_10_is_in_the_set()
	local found = false

	for _, name in ipairs(GLOBALS) do
		found = found or name == "recovery_duty_naboo_privateer_10"
	end

	lu.assertTrue(found, "recovery_duty_naboo_privateer_10 is a loaded recovery quest (rsf-tier2-kaydine-duties)")
end

---------------------------------------------------------------------------------------------
-- AC-10: one test pair per quest, named after the quest
---------------------------------------------------------------------------------------------

TestRecoveryGuard = {}

function TestRecoveryGuard:setUp() H.reset() end

function TestRecoveryGuard:tearDown() DR.restoreRecoveryTables() end

local function startRun(global)
	local q = H.expectGlobal(global, "recovery quest table")
	local run = DR.startRecoveryRun(q)

	lu.assertEquals(#run.areas, #q.recoveryPoints, global .. ": one active area per recovery point")
	lu.assertTrue(#run.areas >= 1, global .. ": at least one recovery area")
	lu.assertTrue(DR.active(run.player, q), global .. ": the quest is active after the target arrived")
	lu.assertEquals(progress(run), 0, global .. ": recoveryShipProgress is unset before capture")
	return run
end

for _, global in ipairs(GLOBALS) do
	-- AC-10: before capture, no area entry has any effect
	TestRecoveryGuard["test_" .. global .. "_ignores_every_recovery_area_entry_before_capture"] = function()
		local run = startRun(global)
		local before = observable(run)

		for i, area in ipairs(run.areas) do
			H.enterArea(area, run.ship)

			lu.assertTrue(DR.active(run.player, run.quest), global .. ": the quest is still active after area " .. i)
			lu.assertEquals(countOf(pendingMethods(), "completeQuest"), 0, global .. ": no completeQuest event after area " .. i)
			lu.assertEquals(countOf(pendingMethods(), "failQuest"), 0, global .. ": no failQuest event after area " .. i)
			lu.assertEquals(observable(run), before, global .. ": task changes, waypoint, messages, taunts, events and shared memory after area " .. i)
		end

		-- and the quest does not finish later on either
		H.advance(2000)
		lu.assertTrue(DR.active(run.player, run.quest), global .. ": the quest is still active two seconds after the area entries")
		lu.assertEquals(progress(run), 0, global .. ": recoveryShipProgress stays unset")
	end

	-- AC-10: a captured ship walks its points and completes once after the last one
	TestRecoveryGuard["test_" .. global .. "_captured_ship_moves_the_waypoint_and_completes_once_after_the_last_point"] = function()
		local run = startRun(global)
		local q = run.quest
		local n = #q.recoveryPoints

		-- capture, the way assignRecoveryPoints leaves the ship
		writeData(progressKey(run), n)

		for i = 1, n - 1 do
			H.enterArea(run.areas[i], run.ship)

			lu.assertTrue(DR.active(run.player, q), global .. ": still active after recovery point " .. i)
			lu.assertEquals(progress(run), n - i, global .. ": recoveryShipProgress after recovery point " .. i)
			lu.assertEquals(countOf(pendingMethods(), "completeQuest"), 0, global .. ": no completeQuest event after recovery point " .. i)

			local next = q.recoveryPoints[i + 1]

			lu.assertEquals(waypointOf(run), { next.x, next.z, next.y }, global .. ": the waypoint moves to recovery point " .. (i + 1))
		end

		local taunts = #H.tauntLog(run.player)

		H.enterArea(run.areas[n], run.ship)
		lu.assertEquals(countOf(pendingMethods(), "completeQuest"), 1, global .. ": exactly one completeQuest event after the last recovery point")
		lu.assertEquals(#H.tauntLog(run.player), taunts + 1, global .. ": the completion taunt")

		H.advance(1000)
		lu.assertFalse(DR.active(run.player, q), global .. ": the quest is over after the completeQuest event")
		lu.assertEquals(countOf(pendingMethods(), "completeQuest"), 0, global .. ": the completeQuest event ran")
	end
end

-- AC-10: the entry order does not matter before capture (the last area first)
for _, global in ipairs(GLOBALS) do
	TestRecoveryGuard["test_" .. global .. "_ignores_the_last_recovery_area_entered_first_before_capture"] = function()
		local run = startRun(global)
		local before = observable(run)

		H.enterArea(run.areas[#run.areas], run.ship)
		lu.assertEquals(observable(run), before, global .. ": state after entering the last area first")
		lu.assertTrue(DR.active(run.player, run.quest), global .. ": still active")
	end
end

-- AC-10: an attack ship in an area never counts (unchanged), captured or not
for _, global in ipairs(GLOBALS) do
	TestRecoveryGuard["test_" .. global .. "_ignores_a_ship_that_is_not_the_recovery_ship"] = function()
		local run = startRun(global)
		local other = spawnShipAgent(run.quest.escortShips[1] or "x", run.quest.questZone, 0, 0, 0)

		ShipAiAgent(other):setMissionOwner(run.player)
		writeData(progressKey(run), #run.quest.recoveryPoints)

		local before = observable(run)

		H.enterArea(run.areas[1], other)
		lu.assertEquals(observable(run), before, global .. ": state after another ship entered area 1")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: recovery_duty_naboo_privateer_10 shares its first point between the escort path and the recovery path
---------------------------------------------------------------------------------------------

TestRecoveryGuardRsfDuty = {}

function TestRecoveryGuardRsfDuty:setUp() H.reset() end

function TestRecoveryGuardRsfDuty:tearDown() DR.restoreRecoveryTables() end

-- AC-10, D-13: the target spawns inside recovery area 1, which is why the guard exists
function TestRecoveryGuardRsfDuty:test_the_target_spawns_inside_recovery_area_1_and_entering_it_before_capture_does_nothing()
	local q = H.expectGlobal("recovery_duty_naboo_privateer_10", "recovery duty quest table (rsf-tier2-kaydine-duties)")
	local run = DR.startRecoveryRun(q)
	local area = run.areas[1]

	lu.assertNotNil(area, "recovery area 1 was spawned")
	lu.assertEquals(q.recoveryPoints[1].patrolPointName, q.preRecoveryPoints[1].patrolPointName, "recovery point 1 is also pre-recovery point 1 (SWG data)")
	lu.assertEquals(area.radius, 250, "recovery area 1 radius")
	lu.assertTrue(distance(run.ship, area) <= area.radius, "the target spawns inside recovery area 1: distance " .. string.format("%.1f", distance(run.ship, area)) .. " of radius " .. area.radius)

	local before = observable(run)

	H.enterArea(area, run.ship)
	lu.assertEquals(observable(run), before, "state after the target 'entered' recovery area 1 before capture")
	lu.assertTrue(DR.active(run.player, q), "the duty is still active")
	lu.assertEquals(countOf(pendingMethods(), "completeQuest"), 0, "no completeQuest event")
end
