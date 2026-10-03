-- A datapad abort ends the run of every quest type: journal, datapad, observers, waypoints, ships, areas and keys.
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md (AC-4, I-3)
--
-- Every test builds a running quest of one type (abort_cleanup_scenario.lua), aborts it through H.abortMission
-- (the order of the new handleMissionAbort) and pumps events past every delayed teardown.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")

AC.load()

-- Types whose run owns active areas that must leave the world (the static areas of patrol, escort and recovery stay by design)
local OWN_AREAS = { survival = true, delivery = true, delivery_no_pickup = true, rescue = true, rescue_duty = true, destroy_duty = true }

-- Types that leave their ships in place, as SWG does
local SHIPS_STAY = { destroy_surpriseattack = true }

local SETTLE = 10 * 1000 -- past every 2 s delayedDestroyShipAgent and the shorter teardown events

TestAbortEndsRun = {}

function TestAbortEndsRun:setUp() H.reset() end
function TestAbortEndsRun:tearDown() AC.tearDown() end

-- One test per quest type; the run is built and aborted in the same way
for _, entry in ipairs(AC.TYPES) do
	-- AC-4
	TestAbortEndsRun["test_aborting_a_running_" .. entry.type .. "_ends_its_run"] = function()
		local run = AC.build(entry.type)

		lu.assertEquals(run.className, entry.name, "the builder runs " .. entry.name)

		local mission = AC.abort(run)

		H.advance(SETTLE)

		AC.assertI3(run)

		lu.assertEquals(AC.ownKeys(run.player, run.className), {}, entry.name .. ": shared-memory keys of the run")

		if not SHIPS_STAY[entry.type] then
			lu.assertEquals(AC.shipProblems(), {}, entry.name .. ": ships")
		end

		if OWN_AREAS[entry.type] then
			for i, area in ipairs(H.spawnedAreas()) do
				lu.assertTrue(area.destroyed == true, string.format("%s: spawned area #%d is still in the world", entry.name, i))
			end
		end

		-- the C++ marks the mission aborted before anything else, and removes it last
		lu.assertTrue(mission:isAborted(), entry.name .. ": the mission was aborted")
	end
end

---------------------------------------------------------------------------------------------
-- Type specific details named by AC-4
---------------------------------------------------------------------------------------------

TestAbortEndsRunDetails = {}

function TestAbortEndsRunDetails:setUp() H.reset() end
function TestAbortEndsRunDetails:tearDown() AC.tearDown() end

-- AC-4 (destroy): no DESTROYEDSHIP observer on the player, no kill count
function TestAbortEndsRunDetails:test_aborting_a_destroy_drops_the_ship_destroyed_observer_and_the_kill_count()
	local run = AC.build("destroy")
	local p, key = run.player, run.player.objectID .. ":" .. run.className .. ":killCount"

	lu.assertTrue(H.hasObserver(DESTROYEDSHIP, run.className, "notifyDestroyedShip", p), "precondition: the DESTROYEDSHIP observer")
	lu.assertTrue(readData(key) > 0, "precondition: a kill is counted")

	AC.abort(run)

	lu.assertFalse(H.hasObserver(DESTROYEDSHIP, run.className, "notifyDestroyedShip", p), "DESTROYEDSHIP observer")
	lu.assertEquals(readData(key), 0, ":killCount")
	lu.assertEquals(#p.ghost.waypoints, 0, "the target waypoints")
end

-- AC-4 (patrol): the progress key <playerID>:<className> is absent
function TestAbortEndsRunDetails:test_aborting_a_patrol_deletes_the_progress_key_and_the_waypoint()
	local run = AC.build("patrol")
	local p = run.player
	local key = p.objectID .. ":" .. run.className

	lu.assertEquals(readData(key), 1, "precondition: one patrol point reached")
	lu.assertEquals(#p.ghost.waypoints, 1, "precondition: the next patrol point waypoint")

	AC.abort(run)

	lu.assertEquals(readData(key), 0, "progress key " .. key)
	lu.assertEquals(#p.ghost.waypoints, 0, "waypoints")
end

-- AC-4 (surprise attack): the :Count key is absent; the ships stay in the world, as in SWG
function TestAbortEndsRunDetails:test_aborting_a_surprise_attack_deletes_the_count_and_leaves_the_ships()
	local run = AC.build("destroy_surpriseattack")
	local key = run.player.objectID .. run.className .. ":Count"

	lu.assertEquals(readData(key), 4, "precondition: four attackers")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertEquals(readData(key), 0, "Count key " .. key)
	lu.assertEquals(#H.spawnedShips(), 4, "ships spawned")

	for i, ship in ipairs(H.spawnedShips()) do
		lu.assertFalse(ship.destroyed == true, "attacker #" .. i .. " stays in the world (D-7)")
	end
end

-- AC-4 (destroy duty): attack ships are removed, level keys absent, the target area destroyed
function TestAbortEndsRunDetails:test_aborting_a_destroy_duty_removes_the_attackers_the_level_keys_and_the_area()
	local run = AC.build("destroy_duty")
	local p, class = run.player, run.className
	local prefix = p.objectID .. ":" .. class .. ":"

	lu.assertTrue(#H.spawnedShips() >= 1, "precondition: an attack wave is out")
	lu.assertEquals(readData(prefix .. "CurrentWave:"), 1, "precondition: wave 1")
	lu.assertFalse(run.area.destroyed == true, "precondition: the target area exists")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. class .. ":attackShips:"), {}, "attackShips vector")

	for _, level in ipairs({ "CurrentWave:", "CurrentRound:", "CurrentLevel:", "DestroyKillCount:", "targetArea:" }) do
		lu.assertEquals(readData(prefix .. level), 0, level .. " key")
	end

	lu.assertTrue(run.area.destroyed == true, "the target area is destroyed")
	lu.assertEquals(AC.shipProblems(), {}, "attack ships")
	lu.assertEquals(p.missionObjects, {}, "the attack ships are no longer mission objects")
end

-- AC-4 (escort, escort duty, recovery, recovery duty, assassinate): the ships are gone and so are the quest data keys
function TestAbortEndsRunDetails:test_aborting_an_escort_despawns_the_escort_ship_and_drops_its_data()
	local run = AC.build("escort")
	local escort = run.escortAgent

	lu.assertNotNil(escort, "precondition: the escort ship is out")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertTrue(escort.destroyed == true, "the escort ship left the world")
	lu.assertEquals(readData(run.player.objectID .. ":" .. run.className .. ":escortID:"), 0, "escortID key")
	lu.assertEquals(readData(run.player.objectID .. ":" .. run.className .. ":location:"), 0, "location key")
end

function TestAbortEndsRunDetails:test_aborting_an_escort_duty_despawns_the_escort_ship_and_drops_its_data()
	local run = AC.build("escort_duty")
	local escort = run.escortAgent

	lu.assertNotNil(escort, "precondition: the escort ship is out")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertTrue(escort.destroyed == true, "the escort ship left the world")
	lu.assertEquals(readData(run.player.objectID .. ":" .. run.className .. ":escortID:"), 0, "escortID key")
end

function TestAbortEndsRunDetails:test_aborting_a_recovery_despawns_the_recovery_ship_and_its_escorts()
	local run = AC.build("recovery")
	local ship = run.recoveryRun.ship
	local p, class = run.player, run.className

	lu.assertTrue(#H.spawnedShips() >= 2, "precondition: the recovery ship and its escorts")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertTrue(ship.destroyed == true, "the recovery ship left the world")
	lu.assertEquals(readData(p.objectID .. class .. ":recoveryShip:"), 0, "recoveryShip key")
	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. class .. ":spawnedShips:"), {}, "spawnedShips vector")
	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. class .. ":attackShips:"), {}, "attackShips vector")
	lu.assertEquals(AC.shipProblems(), {}, "ships")
end

function TestAbortEndsRunDetails:test_aborting_a_recovery_duty_despawns_the_recovery_ship_and_its_escorts()
	local run = AC.build("recovery_duty")
	local ship = run.recoveryRun.ship
	local p, class = run.player, run.className

	lu.assertTrue(#H.spawnedShips() >= 2, "precondition: the recovery ship and its escorts")

	AC.abort(run)
	H.advance(SETTLE)

	lu.assertTrue(ship.destroyed == true, "the recovery ship left the world")
	lu.assertEquals(readData(p.objectID .. class .. ":recoveryShip:"), 0, "recoveryShip key")
	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. class .. ":spawnedShips:"), {}, "spawnedShips vector")
	lu.assertEquals(AC.shipProblems(), {}, "ships")
end

function TestAbortEndsRunDetails:test_aborting_an_assassinate_despawns_the_target_ships_and_cancels_the_timeout()
	local run = AC.build("assassinate")
	local p, class = run.player, run.className

	lu.assertTrue(#H.spawnedShips() >= 1, "precondition: the target ships")
	lu.assertEquals(#readStringVectorSharedMemory(p.objectID .. class .. ":targetShips:") >= 1, true, "precondition: the target ship vector")

	AC.abort(run)

	lu.assertEquals(readStringVectorSharedMemory(p.objectID .. class .. ":targetShips:"), {}, "targetShips vector")

	for _, e in ipairs(H.pendingEvents()) do
		lu.assertNotEquals(e.method, "failAssassination", "the fail timer is still queued")
	end

	H.advance(SETTLE)

	lu.assertEquals(AC.shipProblems(), {}, "ships")
end
