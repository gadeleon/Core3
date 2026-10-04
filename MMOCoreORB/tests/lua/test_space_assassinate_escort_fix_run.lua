-- Assassinate runs: journal tasks, in-zone start, leave-zone fail, failure split, escorts left at the win, key hygiene
-- (AC-4 to AC-8). Spec: .claude/work/space-assassinate-escort-fix/01-spec.md (SC-3 to SC-6, I-3 to I-5, I-8, D-10 to D-12).
--
-- SWG: script/space/quest_logic/assassinate.java:47-66 (grant), recovery.java:80-154 (zone entry), :100-104 (leave: no split),
-- assassinate.java:184-199 (the escape timer fails with the split), assassinate_ship.java:14-29 (the 1200 s warp-out).
--
--   in-zone start        -> arrival_phase_1 at once, deploy after arrivalDelay, one set of ships, journal tasks switched
--   leave the zone       -> failQuest 2000 ms later, "mission_abandoned" + "quest_failed", no failure split
--   20-minute timeout    -> "failed_escape", then the failure split (only #7 and #23 have one)
--   win with escorts left-> they keep flying, are no longer the run's, and warp out on their own 20-minute timer
--
-- Every quest is discovered at run time (questType == "assassinate") and gets its own test, named after the global.

local lu = require("luaunit")
local H = require("harness")
local S = require("space_assassinate_escort_fix_scenario")

S.load()

local GLOBALS = S.globals()

local ABANDONED = "@space/quest:mission_abandoned"
local ALERT = "@space/quest:quest_alert_s"

local function spawnCalls() return H.Engine.callsTo("spawnShipAgent") end

local function countId(player, id)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == id then
			n = n + 1
		end
	end

	return n
end

-- Started in the quest's zone and advanced past the deploy (at least arrivalDelay and 2 s, so these tests do not depend on the in-zone
-- timing that AC-6 pins). run.deployedAt is the time the first ship spawned.
local function atDeploy(global)
	local run = S.started(global)

	H.advance(math.max(run.q.arrivalDelay * 1000, 2000))

	run.ships = S.copyShips()
	run.target = run.ships[1]
	run.escorts = {}

	local spawns = H.Engine.timedCallsTo("spawnShipAgent")

	run.deployedAt = spawns[1] and spawns[1].t or H.now()

	for i = 2, #run.ships do
		run.escorts[#run.escorts + 1] = run.ships[i]
	end

	run.mark = #H.messageLog(run.player)

	lu.assertEquals(#run.ships, 1 + #run.q.assassinateSpawns.escorts, global .. ": precondition: the target and every escort spawned at arrivalDelay (" .. run.q.arrivalDelay .. " s)")

	return run
end

local function leave(run)
	H.zoneSwitch(run.player, S.otherZone(run.q), { ship = true })
end

---------------------------------------------------------------------------------------------
-- AC-5: journal tasks (SC-5, I-3, D-4)
---------------------------------------------------------------------------------------------

TestAssassinateJournalTasks = {}

function TestAssassinateJournalTasks:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-5
	TestAssassinateJournalTasks["test_" .. global .. "_switches_the_journal_tasks_when_the_pilot_enters_the_zone"] = function()
		local q = S.quest(global)
		local run = S.started(global, S.otherZone(q))
		local mde = S.mde(q)

		lu.assertTrue(S.taskActive(run, 0), global .. ": task 0 active while the pilot is outside the zone")
		lu.assertFalse(S.taskActive(run, 1) or S.taskActive(run, 2), global .. ": tasks 1 and 2 are not active yet")

		H.zoneSwitch(run.player, q.questZone, { ship = true })

		lu.assertTrue(S.taskComplete(run, 0), global .. ": task 0 complete at the entry")
		lu.assertTrue(S.taskActive(run, 1), global .. ": task 1 active at the entry")
		lu.assertEquals(S.taskActive(run, 2), mde, global .. ": task 2 active iff mustDestroyEscort (" .. tostring(mde) .. ")")
		lu.assertFalse(S.taskComplete(run, 1) or S.taskComplete(run, 2), global .. ": tasks 1 and 2 not complete yet")
	end

	-- AC-5
	TestAssassinateJournalTasks["test_" .. global .. "_switches_the_journal_tasks_right_after_an_in_zone_start"] = function()
		local q = S.quest(global)
		local run = S.started(global)
		local mde = S.mde(q)

		lu.assertTrue(S.taskComplete(run, 0), global .. ": task 0 complete right after startQuest")
		lu.assertTrue(S.taskActive(run, 1), global .. ": task 1 active right after startQuest")
		lu.assertEquals(S.taskActive(run, 2), mde, global .. ": task 2 active iff mustDestroyEscort (" .. tostring(mde) .. ")")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: in-zone start (SC-5, D-11, I-5)
---------------------------------------------------------------------------------------------

TestAssassinateInZoneStart = {}

function TestAssassinateInZoneStart:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-6
	TestAssassinateInZoneStart["test_" .. global .. "_announces_the_arrival_at_once_and_deploys_one_set_after_arrivalDelay"] = function()
		local q = S.quest(global)
		local run = S.started(global)
		local delay = q.arrivalDelay * 1000

		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_1")), 1, global .. ": arrival_phase_1 right after startQuest")
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_2")), 0, global .. ": arrival_phase_2 not yet")

		if delay > 0 then
			H.advance(delay - 1)
			lu.assertEquals(#spawnCalls(), 0, global .. ": spawnShipAgent calls 1 ms before arrivalDelay (" .. q.arrivalDelay .. " s)")
			H.advance(1)
		else
			H.advance(0)
		end

		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": spawnShipAgent calls at arrivalDelay")
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_2")), 1, global .. ": arrival_phase_2 at the deploy")

		H.advance(30000)
		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": no second set later")
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_1")), 1, global .. ": arrival_phase_1 is sent once")
	end

	-- AC-6, I-5
	TestAssassinateInZoneStart["test_" .. global .. "_adds_no_ships_for_a_same_zone_switch_before_the_deploy"] = function()
		local q = S.quest(global)
		local run = S.started(global)

		H.zoneSwitch(run.player, q.questZone, { ship = true })
		H.advance(q.arrivalDelay * 1000 + 30000)

		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": spawnShipAgent calls")
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_1")), 1, global .. ": arrival_phase_1 is sent once")
		lu.assertTrue(S.isActive(run), global .. ": still active")
	end

	-- AC-6, I-5
	TestAssassinateInZoneStart["test_" .. global .. "_adds_no_ships_for_a_same_zone_switch_after_the_deploy"] = function()
		local q = S.quest(global)
		local run = atDeploy(global)

		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": precondition: one set deployed")

		H.zoneSwitch(run.player, q.questZone, { ship = true })
		H.advance(30000)

		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": spawnShipAgent calls after a respawn in the zone")
		lu.assertTrue(S.isActive(run), global .. ": still active")
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_1")), 1, global .. ": arrival_phase_1 is sent once")
	end

	-- AC-6, I-5 (SC-5: one set of ships per run)
	TestAssassinateInZoneStart["test_" .. global .. "_a_second_deploy_spawns_and_schedules_nothing"] = function()
		local q = S.quest(global)
		local run = atDeploy(global)
		local events, spawned = #H.Engine.callsTo("createEvent"), #spawnCalls()
		local keys = H.Engine.sharedMemoryKeys()

		lu.assertEquals(spawned, 1 + #q.assassinateSpawns.escorts, global .. ": precondition: one set deployed")

		q:deployTargets(run.player)

		lu.assertEquals(#spawnCalls(), spawned, global .. ": spawnShipAgent calls after a second deployTargets")
		lu.assertEquals(#H.Engine.callsTo("createEvent"), events, global .. ": events queued by a second deployTargets")
		lu.assertEquals(#run.player.missionObjectLog, #run.ships, global .. ": space mission objects added")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), keys, global .. ": shared-memory keys")
	end

	-- AC-6
	TestAssassinateInZoneStart["test_" .. global .. "_fails_2000_ms_after_the_pilot_leaves_the_zone_and_the_ships_jump_out"] = function()
		local q = S.quest(global)
		local run = atDeploy(global)

		lu.assertEquals(#run.ships, 1 + #q.assassinateSpawns.escorts, global .. ": precondition: one set deployed")

		leave(run)
		H.advance(1999)
		lu.assertTrue(S.isActive(run), global .. ": still active 1999 ms after the switch")
		lu.assertEquals(S.take(run), {}, global .. ": nothing sent before the delay is over")
		H.advance(1)

		lu.assertFalse(S.isActive(run), global .. ": failed 2000 ms after the switch")
		lu.assertFalse(S.isComplete(run), global .. ": not complete")
		lu.assertEquals(S.take(run), {
			{ id = "@space/quest:duty_update_s", TO = ABANDONED },
			{ id = "@space/quest:quest_failed", TO = S.sid(q, "title") },
		}, global .. ": messages after the switch")

		for i, ship in ipairs(run.ships) do
			lu.assertTrue(ship.hyperspacing, global .. ": ship " .. i .. " is hyperspacing")
		end
	end
end

-- AC-6: leaving before the target arrives fails the run too, and the late deploy spawns nothing
for _, global in ipairs(GLOBALS) do
	if S.quest(global).arrivalDelay >= 3 then
		-- AC-6
		TestAssassinateInZoneStart["test_" .. global .. "_leaving_before_the_deploy_fails_the_run_and_spawns_nothing"] = function()
			local run = S.started(global)

			leave(run)
			H.advance(2000)
			lu.assertFalse(S.isActive(run), global .. ": failed 2000 ms after the switch")

			H.advance(run.q.arrivalDelay * 1000)
			lu.assertEquals(#spawnCalls(), 0, global .. ": spawnShipAgent calls: the deploy found the run over")
		end
	end
end

-- AC-6 (existing behavior, pinned): a quest started outside the zone deploys one set when the pilot arrives
TestAssassinateOutsideStart = {}

function TestAssassinateOutsideStart:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	TestAssassinateOutsideStart["test_" .. global .. "_started_outside_deploys_one_set_arrivalDelay_after_the_entry"] = function()
		local q = S.quest(global)
		local run = S.started(global, S.otherZone(q))

		H.advance(10000)
		lu.assertEquals(#spawnCalls(), 0, global .. ": nothing spawns while the pilot is outside")

		H.zoneSwitch(run.player, q.questZone, { ship = true })
		lu.assertEquals(countId(run.player, S.sid(q, "arrival_phase_1")), 1, global .. ": arrival_phase_1 at the entry")
		H.advance(q.arrivalDelay * 1000)
		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": spawnShipAgent calls at arrivalDelay after the entry")

		H.zoneSwitch(run.player, q.questZone, { ship = true })
		H.advance(30000)
		lu.assertEquals(#spawnCalls(), 1 + #q.assassinateSpawns.escorts, global .. ": a respawn in the zone adds no ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: failure split, leave vs timeout (SC-6, D-12, I-8)
---------------------------------------------------------------------------------------------

TestAssassinateFailureSplit = {}

function TestAssassinateFailureSplit:setUp() H.reset() end

local SPLITTERS = {}

for _, global in ipairs(GLOBALS) do
	if S.splitsOnFailure(S.quest(global)) then
		SPLITTERS[#SPLITTERS + 1] = global
	end
end

-- The split that must follow the timeout
local FAIL_SPLIT = {
	assassinate_corellia_privateer_tier4_3b = "space_battle_corellia_privateer_tier4_3c_lose",
	assassinate_corellia_rebel_tier4_2 = "rescue_corellia_rebel_tier4_2_b",
}

-- AC-7
function TestAssassinateFailureSplit:test_exactly_two_assassinations_split_on_failure()
	lu.assertEquals(SPLITTERS, { "assassinate_corellia_privateer_tier4_3b", "assassinate_corellia_rebel_tier4_2" }, "assassinations with a FAILURE or BIDIRECTIONAL split")
end

for _, global in ipairs(SPLITTERS) do
	-- AC-7, I-8
	TestAssassinateFailureSplit["test_" .. global .. "_leaving_the_zone_fails_without_any_split"] = function()
		local q = S.quest(global)
		local run = atDeploy(global)

		lu.assertEquals(S.failSplitTarget(q), FAIL_SPLIT[global], global .. ": precondition: the failure split target")

		leave(run)
		H.advance(60000)

		lu.assertFalse(S.isActive(run), global .. ": failed")
		lu.assertFalse(S.isComplete(run), global .. ": not complete")

		for _, name in ipairs(S.startQuestEvents()) do
			lu.assertNotEquals(name, S.failSplitTarget(q), global .. ": startQuest queued for the failure split " .. name)
			lu.assertNotEquals(name, S.splitTarget(q), global .. ": startQuest queued for the success split " .. name)
		end

		lu.assertEquals(S.startQuestEvents(), {}, global .. ": startQuest events")
		lu.assertEquals(S.take(run), {
			{ id = "@space/quest:duty_update_s", TO = ABANDONED },
			{ id = "@space/quest:quest_failed", TO = S.sid(q, "title") },
		}, global .. ": messages after leaving (no split alert)")
	end

	-- AC-7, D-12
	TestAssassinateFailureSplit["test_" .. global .. "_running_out_of_time_fails_and_starts_exactly_the_failure_split"] = function()
		local q = S.quest(global)
		local run = atDeploy(global)

		H.advance(q.failTimer * 60 * 1000 + 5000)

		lu.assertFalse(S.isActive(run), global .. ": failed")
		lu.assertFalse(S.isComplete(run), global .. ": not complete")
		lu.assertEquals(S.take(run), {
			{ id = S.sid(q, "failed_escape") },
			{ id = "@space/quest:duty_update_s", TO = ABANDONED },
			{ id = "@space/quest:quest_failed", TO = S.sid(q, "title") },
			{ id = ALERT, TO = S.sid(q, "split_quest_alert") },
		}, global .. ": messages after the deploy until 5 s past the timer")
		lu.assertEquals(S.startQuestEvents(), { FAIL_SPLIT[global] }, global .. ": startQuest events (the failure split only)")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: escorts alive at the win (SC-4, D-10)
---------------------------------------------------------------------------------------------

TestAssassinateSurvivingEscorts = {}

function TestAssassinateSurvivingEscorts:setUp() H.reset() end

local FALSE_QUESTS = {}

for _, global in ipairs(GLOBALS) do
	if S.mde(S.quest(global)) == false then
		FALSE_QUESTS[#FALSE_QUESTS + 1] = global
	end
end

local function winByTargetOnly(global)
	local run = atDeploy(global)

	S.kill(run, run.target)
	H.advance(1000)
	lu.assertTrue(S.isComplete(run), global .. ": precondition: the target kill won the mission")
	run.mark = #H.messageLog(run.player)

	return run
end

for _, global in ipairs(FALSE_QUESTS) do
	-- AC-4
	TestAssassinateSurvivingEscorts["test_" .. global .. "_leaves_the_escorts_flying_and_released_from_the_run"] = function()
		local run = winByTargetOnly(global)
		local q = run.q
		local missionObjects = S.missionObjectSet(run.player)

		lu.assertEquals(S.keysStartingWith(run.player.objectID .. q.className .. ":targetShips:"), {}, global .. ": the target ship vector is gone")

		for i, ship in ipairs(run.escorts) do
			local label = global .. ": escort " .. i

			lu.assertNotNil(getSceneObject(ship.objectID), label .. " is still in the world")
			lu.assertFalse(ship.hyperspacing, label .. " is not hyperspacing")
			lu.assertFalse(H.hasObserver(SHIPDESTROYED, q.className, "notifyShipDestroyed", ship), label .. " has no SHIPDESTROYED observer")
			lu.assertFalse(missionObjects[ship.objectID] == true, label .. " is not a space mission object of the pilot")
			lu.assertEquals(S.keysStartingWith(ship.objectID .. ":" .. q.className .. ":"), {}, label .. ": shared-memory keys")
		end
	end

	-- AC-4
	TestAssassinateSurvivingEscorts["test_" .. global .. "_ignores_the_death_of_an_escort_that_survived_the_win"] = function()
		local run = winByTargetOnly(global)
		local q = run.q
		local events, pending = #H.Engine.callsTo("createEvent"), #H.pendingEvents()
		local keys = H.Engine.sharedMemoryKeys()
		local tasks = { S.taskActive(run, 1), S.taskComplete(run, 1), S.taskActive(run, 2), S.taskComplete(run, 2) }

		H.destroyShip(run.escorts[1], nil)

		lu.assertEquals(S.take(run), {}, global .. ": no message")
		lu.assertEquals(#H.Engine.callsTo("createEvent"), events, global .. ": no event queued")
		lu.assertEquals(#H.pendingEvents(), pending, global .. ": pending events")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), keys, global .. ": shared-memory keys")
		lu.assertEquals({ S.taskActive(run, 1), S.taskComplete(run, 1), S.taskActive(run, 2), S.taskComplete(run, 2) }, tasks, global .. ": journal tasks")
		lu.assertTrue(S.isComplete(run), global .. ": still complete")
		lu.assertEquals(S.destroyedAllEffects(run.player), 0, global .. ": no effect")
	end

	-- AC-4
	TestAssassinateSurvivingEscorts["test_" .. global .. "_survivors_hyperspace_out_at_the_fail_timer_after_the_deploy"] = function()
		local run = winByTargetOnly(global)
		local q = run.q
		local due = run.deployedAt + q.failTimer * 60 * 1000

		H.advance(due - H.now() - 1)

		for i, ship in ipairs(run.escorts) do
			lu.assertFalse(ship.hyperspacing, global .. ": escort " .. i .. " is not hyperspacing 1 ms before deploy + failTimer")
		end

		H.advance(1)

		for i, ship in ipairs(run.escorts) do
			lu.assertTrue(ship.hyperspacing, global .. ": escort " .. i .. " hyperspaces at deploy + failTimer")
			lu.assertNotNil(getSceneObject(ship.objectID), global .. ": escort " .. i .. " is still in the world at the jump")
		end

		H.advance(1999)

		for i, ship in ipairs(run.escorts) do
			lu.assertNotNil(getSceneObject(ship.objectID), global .. ": escort " .. i .. " is still in the world 1999 ms after the jump")
		end

		H.advance(1)

		for i, ship in ipairs(run.escorts) do
			lu.assertNil(getSceneObject(ship.objectID), global .. ": escort " .. i .. " has left the world 2000 ms after the jump")
		end

		local others = {}

		for _, m in ipairs(S.take(run)) do
			if m.id ~= ALERT then -- the completion split's alert may still be due
				others[#others + 1] = m
			end
		end

		lu.assertEquals(others, {}, global .. ": the warp-out sends the pilot nothing")
		lu.assertTrue(S.isComplete(run), global .. ": the warp-out does not undo the win")
	end

	-- AC-4 (R-5): a survivor that died before the timer is left alone
	TestAssassinateSurvivingEscorts["test_" .. global .. "_a_survivor_killed_before_the_timer_is_skipped_by_the_warp_out"] = function()
		local run = winByTargetOnly(global)
		local q = run.q

		H.destroyShip(run.escorts[1], nil)
		H.advance(run.deployedAt + q.failTimer * 60 * 1000 - H.now() + 5000)

		lu.assertFalse(run.escorts[1].hyperspacing, global .. ": the dead escort was not sent to hyperspace")

		for i = 2, #run.escorts do
			lu.assertTrue(run.escorts[i].hyperspacing, global .. ": escort " .. i .. " hyperspaced")
		end
	end
end

for _, global in ipairs(GLOBALS) do
	-- AC-4: a live run's ships are the run's business at the timer, not the leftover warp-out's
	TestAssassinateSurvivingEscorts["test_" .. global .. "_ships_of_a_live_run_are_despawned_once_by_the_timeout_fail"] = function()
		local run = atDeploy(global)
		local q = run.q

		H.advance(run.deployedAt + q.failTimer * 60 * 1000 - H.now())

		for i, ship in ipairs(run.ships) do
			lu.assertFalse(ship.hyperspacing, global .. ": ship " .. i .. " is not hyperspacing at the timer itself (the fail runs 1 s later)")
		end

		H.advance(10000)
		lu.assertFalse(S.isActive(run), global .. ": failed by the timeout")

		for i, ship in ipairs(run.ships) do
			lu.assertTrue(ship.hyperspacing, global .. ": ship " .. i .. " hyperspaces")
		end

		local destroys = 0

		for _, c in ipairs(H.Engine.callsTo("createEvent")) do
			if c[3] == "delayedDestroyShipAgent" then
				destroys = destroys + 1
			end
		end

		lu.assertEquals(destroys, #run.ships, global .. ": delayedDestroyShipAgent events, one per ship")
	end
end

-- AC-4: after a fail, a reset or a datapad abort no warp-out event is pending (the ships were despawned with the run)
local END_PATHS = {
	fail = function(run)
		leave(run)
		H.advance(2000)
		lu.assertFalse(S.isActive(run), run.global .. ": precondition: failed by leaving the zone")
	end,
	reset = function(run)
		run.q:resetQuest(run.player)
		lu.assertFalse(S.isActive(run), run.global .. ": precondition: reset")
	end,
	abort = function(run)
		H.abortMission(run.player, run.q.questType, run.q.questName)
		lu.assertFalse(S.isActive(run), run.global .. ": precondition: aborted")
	end,
}

local PATH_NAMES = { "fail", "reset", "abort" }

for _, global in ipairs(GLOBALS) do
	for _, path in ipairs(PATH_NAMES) do
		-- AC-4
		TestAssassinateSurvivingEscorts["test_" .. global .. "_" .. path .. "_leaves_no_warp_out_event_pending"] = function()
			local run = atDeploy(global)

			END_PATHS[path](run)

			for _, e in ipairs(H.pendingEvents()) do
				lu.assertNotEquals(e.method, "warpOutLeftover", global .. ": warpOutLeftover pending after " .. path)
			end

			H.advance(25 * 60 * 1000)

			local destroys = 0

			for _, c in ipairs(H.Engine.callsTo("createEvent")) do
				if c[3] == "delayedDestroyShipAgent" then
					destroys = destroys + 1
				end
			end

			lu.assertEquals(destroys, #run.ships, global .. ": delayedDestroyShipAgent events after " .. path .. " (the ships leave once)")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: key hygiene on every way a run ends (I-4, SC-3)
---------------------------------------------------------------------------------------------

TestAssassinateKeyHygiene = {}

function TestAssassinateKeyHygiene:setUp() H.reset() end

-- A mid-run state with every counter key written, including a TotalKills key of an older run
local function midRun(global)
	local run = atDeploy(global)
	local pid, cls = run.player.objectID, run.q.className

	writeData(pid .. ":" .. cls .. ":TotalKills:", 2)
	S.kill(run, run.escorts[1])

	if S.mde(run.q) then
		S.kill(run, run.target)
		lu.assertTrue(S.hasKey(pid .. ":" .. cls .. ":TargetDestroyed:"), global .. ": precondition: TargetDestroyed written")
	end

	lu.assertTrue(S.hasKey(pid .. ":" .. cls .. ":EscortKills:"), global .. ": precondition: EscortKills written")
	lu.assertTrue(S.isActive(run), global .. ": precondition: the run is still going")

	return run
end

local HYGIENE_PATHS = {
	complete = function(run)
		for i = 2, #run.escorts do
			S.kill(run, run.escorts[i])
		end

		if not run.target.destroyed then
			S.kill(run, run.target)
		end

		H.advance(10000)
		lu.assertTrue(S.isComplete(run), run.global .. ": precondition: the mission is won")
	end,
	fail = END_PATHS.fail,
	reset = END_PATHS.reset,
	abort = END_PATHS.abort,
	timeout = function(run)
		H.advance(run.q.failTimer * 60 * 1000 + 5000)
		lu.assertFalse(S.isActive(run), run.global .. ": precondition: failed by the timeout")
		lu.assertFalse(S.isComplete(run), run.global .. ": precondition: not complete")
	end,
}

for _, global in ipairs(GLOBALS) do
	for _, path in ipairs({ "complete", "fail", "reset", "abort", "timeout" }) do
		-- AC-8, I-4
		TestAssassinateKeyHygiene["test_" .. global .. "_" .. path .. "_leaves_no_kill_counter_vector_or_ship_key_behind"] = function()
			local run = midRun(global)

			HYGIENE_PATHS[path](run)
			H.advance(5000)

			lu.assertEquals(S.runKeys(run), {}, global .. ": run keys left after " .. path)
		end
	end
end
