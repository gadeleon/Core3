-- Rescue failure paths, teardown, stale events and the second Lua VM (space-quest-rescue-docking).
-- Spec: .claude/work/space-quest-rescue-docking/01-spec.md (AC-8, AC-9, I-4, I-5, I-6, Behavior 3, 10 to 12,
-- decisions D-5). Times are milliseconds.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")

R.load()
R.snapshotVm()

local function secs(n) return n * 1000 end

local REP = R.REP      -- has a parent quest (assassinate_corellia_rebel_tier4_2)
local RSF = R.RSF
local SPLIT = R.SPLIT
local ELSEWHERE = "space_tatooine"
local S = require("survival_scenario")

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

local function failureEvents(sc) return R.count(sc:events(), "failed_destroy", "update") end

TestRescueTargetLost = {}

function TestRescueTargetLost:setUp() H.reset() end

-- Builds the three stages a destroyed target can be in.
local STAGE_BUILDERS = {
	DOCK = function(name) return R.fresh(name):toWaiting() end,
	DOCKED = function(name) return R.fresh(name):toDocked() end,
	ESCORT = function(name) return R.fresh(name):toEscort() end,
}

local STAGE_NAMES = { "DOCK", "DOCKED", "ESCORT" }

-- AC-8a
function TestRescueTargetLost:test_destroying_the_target_fails_the_quest_after_the_observer_returns_in_every_stage()
	for _, stage in ipairs(STAGE_NAMES) do
		H.reset()

		local sc = STAGE_BUILDERS[stage](REP)
		local t = sc:target()

		H.destroyShip(t, nil)

		lu.assertTrue(sc:active(), stage .. ": nothing fails inside the SHIPDESTROYED observer")
		lu.assertEquals(failureEvents(sc), 0, stage .. ": no failed_destroy inside the observer")

		H.advance(0)

		lu.assertEquals(failureEvents(sc), 1, stage .. ": failed_destroy update sent")
		lu.assertFalse(sc:active(), stage .. ": the journal quest is no longer active")
		lu.assertFalse(sc:complete(), stage .. ": and not complete")
		lu.assertEquals(#R.createEvents("failQuest", "assassinate_corellia_rebel_tier4_2"), 1, stage .. ": the parent's failQuest event was created")
	end
end

-- AC-8a
function TestRescueTargetLost:test_the_destroyed_observer_always_returns_1()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()
	local stray = spawnShipAgent("imp_tie_fighter_tier3", sc.o.zone, 1, 2, 3, sc.ship)

	ShipAiAgent(stray):setMissionOwner(sc.player)

	lu.assertEquals(sc.quest:notifyTargetDestroyed(stray, nil), 1, "a ship that is not the stored target")
	H.advance(secs(5))
	lu.assertTrue(sc:active(), "a stray destroyed ship does not fail the quest")

	local orphan = spawnShipAgent(sc.o.targetShip, sc.o.zone, 1, 2, 3, sc.ship)

	lu.assertEquals(sc.quest:notifyTargetDestroyed(orphan, nil), 1, "a ship with no owner")
	H.advance(secs(5))
	lu.assertTrue(sc:active(), "still active")

	lu.assertEquals(sc.quest:notifyTargetDestroyed(t, nil), 1, "the stored target")
	lu.assertTrue(sc:active(), "scheduled, not immediate")
	H.advance(0)
	lu.assertFalse(sc:active(), "failed through the scheduled event")
end

-- AC-8a
function TestRescueTargetLost:test_destroying_the_target_after_arrival_does_not_fail_the_quest()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()

	sc:arrive()
	H.advance(0)

	lu.assertEquals(sc.quest:notifyTargetDestroyed(t, nil), 1, "returns 1 in stage ARRIVED")
	H.destroyShip(t, nil)
	H.advance(secs(10))

	lu.assertEquals(failureEvents(sc), 0, "no failed_destroy after arrival")
	lu.assertTrue(sc:complete(), "the quest completed")
	lu.assertEquals(#R.createEvents("failQuest", "assassinate_corellia_rebel_tier4_2"), 0, "no parent failure")
end

-- AC-8a
function TestRescueTargetLost:test_a_destroyed_target_after_the_quest_ended_does_nothing()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	sc.quest:failQuest(sc.player, "false")
	lu.assertEquals(sc.quest:notifyTargetDestroyed(t, nil), 1, "returns 1")
	H.advance(secs(5))

	lu.assertEquals(failureEvents(sc), 0, "no failed_destroy for an ended quest")
end

-- AC-8a, AC-9 same tick (delivery review R-2)
function TestRescueTargetLost:test_a_dock_and_the_targets_destruction_in_the_same_tick_fail_the_quest_once_and_no_escort_starts()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.dock(sc.player, t)
	H.destroyShip(t, nil)
	H.advance(0)
	H.advance(secs(120))

	lu.assertEquals(failureEvents(sc), 1, "failed_destroy exactly once")
	lu.assertFalse(sc:active(), "the quest is failed")
	lu.assertEquals(#R.createEvents("failQuest", "assassinate_corellia_rebel_tier4_2"), 1, "the parent was failed once")

	for _, call in ipairs(t.callLog) do
		lu.assertNotEquals(call.name, "repairShipAgent", "no startEscort acted")
		lu.assertNotEquals(call.name, "assignFixedPatrolPointsTable", "no startEscort acted")
		lu.assertNotEquals(call.name, "setEscort", "no startEscort acted")
	end

	lu.assertEquals(#R.attackSpawns(sc), 0, "no attack wave")
end

TestRescueAbandon = {}

function TestRescueAbandon:setUp() H.reset() end

local function abandon(sc, zone)
	H.zoneSwitch(sc.player, zone or ELSEWHERE)
end

-- AC-8b
function TestRescueAbandon:test_a_zone_switch_after_setup_abandons_the_quest_after_the_observer_returns_in_every_stage()
	for _, stage in ipairs({ "WARP", "DOCK", "DOCKED", "ESCORT" }) do
		H.reset()

		local sc

		if stage == "WARP" then
			sc = R.fresh(REP):start()
		else
			sc = STAGE_BUILDERS[stage](REP)
		end

		abandon(sc)

		lu.assertTrue(sc:active(), stage .. ": nothing fails inside the ZONESWITCHED observer")
		lu.assertEquals(R.count(sc:events(), "rescue_abandoned"), 0, stage .. ": no abandon message inside the observer")

		H.advance(0)

		lu.assertEquals(R.count(sc:events(), "rescue_abandoned", "update"), 1, stage .. ": @space/quest:rescue_abandoned update")
		lu.assertFalse(sc:active(), stage .. ": the quest is no longer active")
		lu.assertEquals(failureEvents(sc), 0, stage .. ": no failed_destroy message of failQuest's own")
		lu.assertEquals(#R.createEvents("failQuest", "assassinate_corellia_rebel_tier4_2"), 1, stage .. ": the parent was failed")
	end
end

-- AC-8 (space-quest-player-ship-destroyed, D-14): the respawn after a ship death is a same-zone switch; it is inert
function TestRescueAbandon:test_a_same_zone_switch_after_setup_leaves_the_run_alone()
	local sc = R.fresh(REP):toWaiting()
	local sent = #sc:events()

	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(0)

	lu.assertEquals(R.count(sc:events(), "rescue_abandoned", "update"), 0, "no rescue_abandoned update")
	lu.assertTrue(sc:active(), "the quest is still active")
	lu.assertEquals(#sc:events(), sent, "nothing was sent by the same-zone switch")
end

-- AC-8b
function TestRescueAbandon:test_switching_to_another_zone_before_setup_leaves_the_quest_active()
	local sc = R.fresh(REP, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.zoneSwitch(sc.player, "space_lok")
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "quest still active")
	lu.assertEquals(R.count(sc:events(), "rescue_abandoned"), 0, "no abandon message")
	lu.assertEquals(#areaCalls(), 0, "and no setup in the wrong zone")
end

-- AC-8b
function TestRescueAbandon:test_abandoning_ends_the_run_cleanly()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()

	abandon(sc)
	H.advance(secs(10))

	lu.assertEquals(t.dockableCalls[#t.dockableCalls], false, "the target is not left dockable")
	lu.assertEquals(R.memoryKeys(), {}, "no shared-memory key left")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint left")
end

TestRescueSpawnFailureAndExpiry = {}

function TestRescueSpawnFailureAndExpiry:setUp() H.reset() end

-- AC-8c
function TestRescueSpawnFailureAndExpiry:test_a_target_that_cannot_be_spawned_logs_an_error_and_fails_the_quest()
	local sc = R.fresh(REP):start()

	H.Engine.config.spawnFails = true
	sc:warp()
	H.advance(secs(10))

	lu.assertTrue(#R.errorLogs() >= 1, "an LT_ERROR line was logged")
	lu.assertFalse(sc:active(), "the quest is failed")
	lu.assertEquals(#H.spawnedShips(), 0, "no ship exists")
	lu.assertEquals(R.memoryKeys(), {}, "nothing left behind")
	lu.assertEquals(#sc:waypoints(), 0, "no waypoint")
	lu.assertTrue(sc:area().destroyed, "the destination area was destroyed")
end

-- AC-8d
function TestRescueSpawnFailureAndExpiry:test_a_target_not_brought_home_within_an_hour_of_the_warp_in_fails_the_quest()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	H.advance(R.TARGET_LIFETIME - 1)
	lu.assertTrue(sc:active(), "still active 1 ms before the lifetime")
	lu.assertEquals(R.count(sc:events(), "warpout_failure"), 0, "no warpout_failure yet")

	H.advance(1)

	lu.assertEquals(R.count(sc:events(), "warpout_failure", "message"), 1, "@space/quest:warpout_failure system message")
	lu.assertFalse(sc:active(), "the quest is failed")
	lu.assertEquals(failureEvents(sc), 0, "expiry has no failed_destroy message")
	lu.assertEquals(t.dockableCalls[#t.dockableCalls], false, "the target was released")
	lu.assertEquals(H.now(), sc.tWarp + R.TARGET_LIFETIME, "an hour after the warp-in")
end

-- AC-8d
function TestRescueSpawnFailureAndExpiry:test_expiry_also_fails_a_docked_and_an_escorting_run()
	for _, stage in ipairs({ "DOCKED", "ESCORT" }) do
		H.reset()

		local sc = STAGE_BUILDERS[stage](REP)

		-- a wave of the escort is still alive; the lifetime counts from the warp-in
		H.advance(sc.tWarp + R.TARGET_LIFETIME - H.now())

		lu.assertEquals(R.count(sc:events(), "warpout_failure", "message"), 1, stage .. ": warpout_failure sent")
		lu.assertFalse(sc:active(), stage .. ": failed")
	end
end

-- AC-8d
function TestRescueSpawnFailureAndExpiry:test_the_expiry_timer_of_a_finished_run_does_nothing()
	local sc = R.fresh(REP):toEscort()

	sc:arrive()
	H.advance(secs(10))
	lu.assertTrue(sc:complete(), "precondition: completed")

	H.advance(R.TARGET_LIFETIME)

	lu.assertEquals(R.count(sc:events(), "warpout_failure"), 0, "no warpout_failure for a completed run")
	lu.assertTrue(sc:complete(), "still complete")
end

TestRescueEmptyData = {}

function TestRescueEmptyData:setUp() H.reset() end

local function startDuty(globalName)
	local quest = H.expectGlobal(globalName)
	local spies = S.isolate(globalName)
	local player = H.newPlayer({ zone = quest.questZone, ship = {}, pilot = "rebel" })

	return quest, player, spies
end

local function assertCleanFailure(label, quest, player)
	local ok, err = pcall(function()
		quest:startQuest(player, "")
		H.advance(secs(120))
	end)

	lu.assertTrue(ok, label .. ": raises no Lua error, got " .. tostring(err))
	lu.assertTrue(#R.errorLogs() >= 1, label .. ": an LT_ERROR line was logged")
	lu.assertEquals(#areaCalls(), 0, label .. ": no area spawned")
	lu.assertEquals(#H.spawnedShips(), 0, label .. ": no ship spawned")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, quest.questType, quest.questName), label .. ": the quest ends not active")
end

-- AC-8e
-- Revised by space-quest-rescue-duty (spec, Shared code changes 3): the duty rescue globals now hold valid data,
-- so the "empty data" examples are synthetic tables with the same checks.
function TestRescueEmptyData:test_the_unchanged_duty_rescue_quests_fail_cleanly_at_setup()
	local variants = {
		rescueEmptyPath = { class = SpaceRescueScreenplay, questType = "rescue", fields = { recoveryPath = {}, targetShipType = "reb_diplomat_tier4" } },
		rescueEmptyTarget = { class = SpaceRescueScreenplay, questType = "rescue", fields = { recoveryPath = { { patrolPointName = "p1", x = 1, z = 2, y = 3 } }, targetShipType = "" } },
		dutyEmptyPath = { class = SpaceDutyRescueScreenplay, questType = "rescue_duty", fields = { recoveryPath = {}, targetShipTypes = { "reb_xwing_tier4" } } },
		dutyEmptyTargets = { class = SpaceDutyRescueScreenplay, questType = "rescue_duty", fields = { recoveryPath = { { patrolPointName = "p1", x = 1, z = 2, y = 3 } }, targetShipTypes = {} } },
	}

	for variant, v in pairs(variants) do
		H.reset()

		local quest = v.class:new(v.fields)

		quest.className = "test_empty_" .. variant
		quest.questName = "corellia_rebel_tier4_1"
		quest.questType = v.questType
		quest.questZone = "space_dantooine"
		quest.attackShipLists = {}
		quest.attackPeriod = 60
		quest.attackListType = 1
		quest.numResponses = 5
		rawset(_G, quest.className, quest)

		local player = H.newPlayer({ zone = "space_dantooine", ship = {}, pilot = "rebel" })

		assertCleanFailure(variant, quest, player)
		rawset(_G, quest.className, nil)
	end
end

-- AC-8e
function TestRescueEmptyData:test_a_rescue_quest_with_an_empty_path_or_an_empty_target_fails_cleanly()
	local variants = {
		emptyPath = function(q) q.recoveryPath = {} end,
		emptyTarget = function(q) q.targetShipType = "" end,
	}

	for variant, mutate in pairs(variants) do
		H.reset()

		local quest = SpaceRescueScreenplay:new {
			className = "test_rescue_" .. variant, questName = "corellia_rebel_tier4_2_b", questType = "rescue", questZone = "space_dathomir",
			recoveryPath = { { patrolPointName = "p1", x = 1, z = 2, y = 3 } }, targetShipType = "reb_diplomat_tier4",
			attackShipLists = {}, attackPeriod = 50, attackListType = 1, numResponses = 5,
		}

		mutate(quest)
		rawset(_G, quest.className, quest)

		local player = H.newPlayer({ zone = "space_dathomir", ship = {}, pilot = "rebel" })

		assertCleanFailure(variant, quest, player)
		rawset(_G, quest.className, nil)
	end
end

-- AC-8e: a failed setup leaves nothing behind
-- Revised by space-quest-rescue-duty (spec, Shared code changes 3): a synthetic empty duty replaces the duty global.
function TestRescueEmptyData:test_a_failed_setup_leaves_no_observer_or_key()
	local quest = SpaceDutyRescueScreenplay:new {
		className = "test_empty_duty_keys", questName = "corellia_rebel_tier4_1", questType = "rescue_duty", questZone = "space_dantooine",
		recoveryPath = {}, targetShipTypes = {}, attackShipLists = {}, attackPeriod = 60, attackListType = 1, numResponses = 5,
	}

	rawset(_G, quest.className, quest)

	local player = H.newPlayer({ zone = "space_dantooine", ship = {}, pilot = "rebel" })
	local ok, err = pcall(function()
		quest:startQuest(player, "")
		H.advance(secs(120))
	end)

	lu.assertTrue(ok, "raises no Lua error, got " .. tostring(err))
	lu.assertFalse(H.hasObserver(ZONESWITCHED, quest.className, "enteredZone", player), "ZONESWITCHED observer dropped")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, quest.className, "notifyDocked", player), "no SHIPDOCKED observer")
	lu.assertEquals(R.memoryKeys(), {}, "no shared-memory key")
	rawset(_G, quest.className, nil)
end

---------------------------------------------------------------------------------------------
-- Teardown
---------------------------------------------------------------------------------------------

local ENDINGS = {
	complete = function(sc) sc.quest:completeQuest(sc.player, "true") end,
	fail = function(sc) sc.quest:failQuest(sc.player, "true") end,
	reset = function(sc) sc.quest:resetQuest(sc.player) end,
}

local ENDING_NAMES = { "complete", "fail", "reset" }

-- Builds a mid-run state. Returns the scenario plus the objects the teardown must clean.
local STATES = {
	-- the area exists, the target has not warped in yet
	areaOnly = function()
		local sc = R.fresh(REP):start()
		return sc, { area = sc:area() }
	end,
	-- waiting dockable target, no wave
	waitingTarget = function()
		local sc = R.fresh(REP):toWaiting()
		H.advance(secs(2))
		return sc, { area = sc:area(), target = sc:target(), waypoint = sc:waypoints()[1] }
	end,
	-- escort with one live wave
	escortAndWave = function()
		local sc = R.fresh(REP):toEscort()

		sc:atEscort(secs(50))
		return sc, { area = sc:area(), target = sc:target(), wave = R.wave(sc, 1), waypoint = sc:waypoints()[1] }
	end,
}

local STATE_NAMES = { "areaOnly", "waitingTarget", "escortAndWave" }

TestRescueTeardown = {}

function TestRescueTeardown:setUp() H.reset() end

local function assertTargetCleaned(sc, t, ending)
	local label = ending .. ": target"

	lu.assertEquals(t.dockableCalls[#t.dockableCalls], false, label .. " dockableCalls ends with false (I-6)")
	lu.assertFalse(ShipAiAgent(t):isDockable(), label .. " is not dockable")
	lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTargetDestroyed", t), label .. " SHIPDESTROYED observer dropped")
	lu.assertEquals(#R.removedAsMissionObject(sc.player, t), 1, label .. " removed as a mission object")
	lu.assertTrue(t.hyperspacing, label .. " setHyperspacing(true)")
	lu.assertEquals(#R.destroyEvents(t), 1, label .. " one delayedDestroyShipAgent event")
	lu.assertEquals(R.destroyEvents(t)[1].delay, 2000, label .. " destroyed 2 s later")
end

local function assertWaveCleaned(sc, wave, ending)
	for i, agent in ipairs(wave.agents) do
		local label = ending .. ": attack ship " .. i

		lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), label .. " SHIPDESTROYED observer dropped")
		lu.assertEquals(#R.removedAsMissionObject(sc.player, agent), 1, label .. " removed as a mission object")
		lu.assertEquals(#R.destroyEvents(agent), 1, label .. " one delayedDestroyShipAgent event")
	end
end

local function assertCommonCleaned(sc, objects, ending)
	lu.assertTrue(objects.area.destroyed, ending .. ": destination area destroyed")
	lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", objects.area), 0, ending .. ": area observer dropped")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), ending .. ": ZONESWITCHED observer dropped")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), ending .. ": SHIPDOCKED observer dropped")
	lu.assertEquals(#sc:waypoints(), 0, ending .. ": waypoint removed")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), ending .. ": waypointID quest status removed (I-4)")
	lu.assertEquals(R.memoryKeys(), {}, ending .. ": no shared-memory key left (I-4)")
	lu.assertEquals(R.strayKeys(sc.player, sc.className), {}, ending .. ": every key was under <playerID>:<className>: (I-4)")
end

-- AC-9
function TestRescueTeardown:test_ending_a_run_cleans_everything_in_every_state()
	for _, stateName in ipairs(STATE_NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc, objects = STATES[stateName]()
			local label = stateName .. " " .. ending

			ENDINGS[ending](sc)

			assertCommonCleaned(sc, objects, label)

			if objects.target ~= nil then
				assertTargetCleaned(sc, objects.target, label)
			end

			if objects.wave ~= nil then
				assertWaveCleaned(sc, objects.wave, label)
			end

			if objects.waypoint ~= nil then
				lu.assertTrue(objects.waypoint.destroyed, label .. ": waypoint object removed")
			end

			H.reset()
		end
	end
end

-- AC-9
function TestRescueTeardown:test_pumping_the_remaining_events_after_an_ending_sends_nothing_and_spawns_nothing()
	for _, stateName in ipairs(STATE_NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc = STATES[stateName]()

			ENDINGS[ending](sc)

			local function quiet()
				local out = {}

				for _, e in ipairs(sc:events()) do
					if e.key ~= "split_quest_alert" then
						out[#out + 1] = e.key .. "@" .. e.via
					end
				end

				return out
			end

			local label = stateName .. " " .. ending
			local before, spawnsBefore, areasBefore, tauntsBefore = quiet(), #R.spawns(), #areaCalls(), #sc:taunts()

			H.advance(secs(7200))

			lu.assertEquals(quiet(), before, label .. ": no rescue message after the ending")
			lu.assertEquals(#R.spawns(), spawnsBefore, label .. ": no ship spawned after the ending")
			lu.assertEquals(#areaCalls(), areasBefore, label .. ": no area spawned after the ending")
			lu.assertEquals(#sc:taunts(), tauntsBefore, label .. ": no taunt after the ending")
			lu.assertEquals(#sc:waypoints(), 0, label .. ": no waypoint added after the ending")
			lu.assertEquals(R.memoryKeys(), {}, label .. ": still no shared-memory key")
			H.reset()
		end
	end
end

-- AC-9
function TestRescueTeardown:test_a_late_dock_with_the_old_target_after_an_ending_changes_nothing()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = STATES.waitingTarget()
		local t = objects.target

		ENDINGS[ending](sc)

		local calls = #t.callLog

		lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 0, ending .. ": notifyDocked ignores the old target")
		H.dock(sc.player, t)
		H.advance(secs(60))

		lu.assertEquals(#sc:taunts(), 0, ending .. ": no taunt")
		lu.assertEquals(#t.callLog, calls, ending .. ": the target is not touched again")
		lu.assertEquals(R.memoryKeys(), {}, ending .. ": no key written")
		H.reset()
	end
end

-- AC-9
function TestRescueTeardown:test_a_late_arrival_in_the_old_area_after_an_ending_changes_nothing()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = STATES.escortAndWave()
		local t = objects.target

		ENDINGS[ending](sc)

		local before = #sc:events()

		H.enterArea(objects.area, t)
		H.advance(secs(60))

		lu.assertEquals(#sc:events(), before, ending .. ": no message from a late arrival")
		H.reset()
	end
end

-- Content contract: the signature change
function TestRescueTeardown:test_clean_up_quest_data_takes_the_player_and_clears_the_run()
	local sc, objects = STATES.escortAndWave()

	lu.assertTrue(#R.memoryKeys() > 0, "precondition: the run keeps state")

	local ok, err = pcall(function() sc.quest:cleanUpQuestData(sc.player) end)

	lu.assertTrue(ok, "cleanUpQuestData(pPlayer) raises no error: " .. tostring(err))
	lu.assertEquals(R.memoryKeys(), {}, "all run state removed")
	lu.assertEquals(objects.target.dockableCalls[#objects.target.dockableCalls], false, "the target is released")
	lu.assertEquals(#R.destroyEvents(objects.target), 1, "the target is scheduled for removal")
end

-- AC-9: a target that already left is left alone
function TestRescueTeardown:test_ending_after_the_target_is_gone_raises_no_error()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = STATES.waitingTarget()

		H.Fakes.destroy(objects.target)

		local ok, err = pcall(function() ENDINGS[ending](sc) end)

		lu.assertTrue(ok, ending .. ": raises no error for a vanished target: " .. tostring(err))
		lu.assertEquals(R.memoryKeys(), {}, ending .. ": no key left")
		H.reset()
	end
end

TestRescueRestart = {}

function TestRescueRestart:setUp()
	H.reset()
	R.resetVm()
end

-- Fails run 1 `failAfter` ms after its start, restarts (optionally "on another VM") and plays run 2
-- through to the end with the dock and the arrival.
local function failThenRestart(name, failAfter, otherVm)
	local sc = R.fresh(name):start()

	H.advance(failAfter)
	sc.quest:failQuest(sc.player, "true")
	lu.assertFalse(sc:active(), "precondition: run 1 failed")

	if otherVm then
		R.resetVm()
	end

	local firstTargets = #sc:targets()

	sc:start()
	sc:warp()
	H.advance(secs(5))
	sc:dock()
	sc:escort()
	sc:atEscort(secs(20))
	sc:arrive()
	H.advance(secs(10))
	H.advance(secs(300))

	return sc, firstTargets
end

-- AC-9
function TestRescueRestart:test_stale_timers_of_a_failed_run_do_not_act_on_a_restarted_run()
	local sc, firstTargets = failThenRestart(REP, secs(1), false)

	lu.assertEquals(firstTargets, 0, "run 1 failed before its target warped in")
	lu.assertEquals(#sc:targets(), 1, "exactly one target in total, none from run 1's warp timer")
	lu.assertEquals(R.spawns()[1].t, sc.tStart + secs(sc.o.arrivalDelay), "the target spawned at the second start plus the arrival delay")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "rescue_phase_2"), 1, "one rescue_phase_2 taunt")
	lu.assertTrue(sc:complete(), "the second run completed")
	lu.assertEquals(R.count(sc:events(), "recovery_success", "update"), 1, "recovery_success once")
end

-- AC-9
function TestRescueRestart:test_the_same_scenario_on_a_second_lua_vm_gives_the_same_result()
	local sc = failThenRestart(REP, secs(1), true)

	lu.assertEquals(#sc:targets(), 1, "one target in total")
	lu.assertEquals(R.spawns()[1].t, sc.tStart + secs(sc.o.arrivalDelay), "spawn time")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "rescue_phase_2"), 1, "one rescue_phase_2")
	lu.assertTrue(sc:complete(), "the second run completed")
end

-- AC-9
function TestRescueRestart:test_a_restart_after_a_failure_with_a_waiting_target_spawns_one_target_per_run()
	local sc = R.fresh(REP):toWaiting()
	local first = sc:target()

	sc.quest:failQuest(sc.player, "true")
	R.resetVm()
	sc:start()
	sc:warp()
	H.advance(secs(5))
	sc:dock()
	sc:escort()
	sc:arrive()
	H.advance(secs(10))

	lu.assertEquals(#sc:targets(), 2, "one target per run")
	lu.assertTrue(first.destroyed or #R.destroyEvents(first) == 1, "run 1's target was released and scheduled for removal")
	lu.assertEquals(first.dockableCalls, { true, false }, "run 1's target was released once")
	lu.assertTrue(sc:complete(), "the second run completed")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "rescue_phase_2"), 1, "one rescue_phase_2 taunt in total")
	lu.assertEquals(R.memoryKeys(), {}, "nothing left")
end

-- AC-9: waves of a failed run do not continue into the next run
function TestRescueRestart:test_waves_of_a_failed_run_do_not_continue_into_the_next_run()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(50))

	local firstWave = R.wave(sc, 1)

	sc.quest:failQuest(sc.player, "true")
	R.resetVm()

	local before = #sc:attackSpawns()

	H.advance(secs(60))
	lu.assertEquals(#sc:attackSpawns(), before, "run 1's next launch timer did nothing")

	sc:start()
	sc:warp()
	H.advance(secs(5))
	sc:dock()
	sc:escort()

	local t0 = sc.tEscort

	H.advance(secs(50) - 1)
	lu.assertEquals(#sc:attackSpawns(), before, "no wave before the new run's own period")

	H.advance(1)

	lu.assertEquals(#sc:attackWaves(), 2, "exactly one new wave, at the new run's first period")
	lu.assertEquals(R.wave(sc, 2).t, t0 + secs(50), "launched 50 s after the second run's escort start")
	lu.assertTrue(firstWave.agents[1].destroyed or #R.destroyEvents(firstWave.agents[1]) == 1, "run 1's attack ships were removed")
end

-- AC-9: every step handled by a different Lua VM (no run state in Lua variables)
function TestRescueRestart:test_a_full_run_where_every_step_runs_on_a_fresh_vm_completes_with_waves()
	local sc = R.fresh(REP)

	R.resetVm()
	sc:start()
	R.resetVm()
	sc:warp()
	R.resetVm()
	H.advance(secs(5))
	R.resetVm()
	sc:dock()
	R.resetVm()
	sc:escort()
	R.resetVm()
	sc:atEscort(secs(50))
	R.resetVm()
	R.killWave(sc, R.wave(sc, 1))
	R.resetVm()
	sc:atEscort(secs(90))
	R.resetVm()
	sc:arrive()
	R.resetVm()
	H.advance(secs(30))

	lu.assertTrue(sc:complete(), "completed although every step ran on a fresh VM")
	lu.assertEquals(#sc:targets(), 1, "one target")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "rescue_phase_2"), 1, "dock taunt")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "complete"), 1, "arrival taunt")
	lu.assertEquals(R.memoryKeys(), {}, "nothing left")
end

TestRescueSafeTeardown = {}

function TestRescueSafeTeardown:setUp() H.reset() end

-- I-5
function TestRescueSafeTeardown:test_ending_a_quest_that_never_started_raises_no_error()
	for _, name in ipairs(R.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local sc = R.new(name)

			ENDINGS[ending](sc)
			ENDINGS[ending](sc)
			H.advance(secs(60))

			lu.assertEquals(R.memoryKeys(), {}, name .. " " .. ending .. ": nothing written for a player who never started")
			lu.assertEquals(#H.spawnedAreas(), 0, name .. " " .. ending .. ": no area created by ending a quest")
			lu.assertEquals(#R.spawns(), 0, name .. " " .. ending .. ": no ship created by ending a quest")
		end
	end
end

-- I-5: Havoc's quest reset calls resetQuest on both rescue quests for every player
function TestRescueSafeTeardown:test_reset_quest_on_a_quest_the_player_never_had_raises_no_error()
	for _, name in ipairs(R.NAMES) do
		H.reset()

		local sc = R.new(name)

		lu.assertTrue(pcall(function() sc.quest:resetQuest(sc.player) end), name .. ": resetQuest")
		lu.assertEquals(R.memoryKeys(), {}, name .. ": nothing written")
	end
end

-- I-5
function TestRescueSafeTeardown:test_ending_a_quest_started_but_not_set_up_or_before_the_warp_raises_no_error()
	for _, name in ipairs(R.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local waiting = R.new(name, { zone = ELSEWHERE })

			waiting.quest:startQuest(waiting.player, "")
			ENDINGS[ending](waiting)
			H.advance(secs(60))
			lu.assertEquals(R.memoryKeys(), {}, name .. " " .. ending .. " (not set up): no key left")

			H.reset()

			local setUp = R.new(name)

			setUp.quest:startQuest(setUp.player, "")
			ENDINGS[ending](setUp)
			ENDINGS[ending](setUp)
			H.advance(secs(60))

			lu.assertEquals(R.memoryKeys(), {}, name .. " " .. ending .. " (set up, target never warped): no key left")
			lu.assertEquals(#setUp:waypoints(), 0, name .. " " .. ending .. ": no waypoint left")
			lu.assertEquals(#R.spawns(), 0, name .. " " .. ending .. ": no ship spawned after the ending")
		end
	end
end

-- I-5
function TestRescueSafeTeardown:test_ending_a_quest_twice_after_a_full_run_raises_no_error()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc = R.fresh(SPLIT):toEscort()

		sc:arrive()
		H.advance(secs(1))
		ENDINGS[ending](sc)
		ENDINGS[ending](sc)
		H.advance(secs(60))

		lu.assertEquals(R.memoryKeys(), {}, ending .. ": no key left")
	end
end

-- I-6: a target is never left dockable when the run ends in any way
function TestRescueSafeTeardown:test_every_quest_leaves_no_dockable_target_behind_when_failed_mid_run()
	for _, name in ipairs(R.NAMES) do
		H.reset()

		local sc = R.fresh(name):toWaiting()

		sc.quest:failQuest(sc.player, "true")

		for i, t in ipairs(sc:targets()) do
			lu.assertFalse(ShipAiAgent(t):isDockable(), name .. ": target " .. i .. " is not dockable after the failure")
		end

		lu.assertEquals(#sc:targets(), 1, name .. ": the target had spawned")
	end
end

-- Content contract: failQuest keeps its guard
function TestRescueSafeTeardown:test_fail_quest_on_an_inactive_quest_does_nothing_and_fires_no_split_or_parent_events()
	local sc = R.fresh(REP)

	sc.quest:failQuest(sc.player, "true")
	H.advance(secs(5))

	lu.assertEquals(#R.createEvents("failQuest"), 0, "no parent failure for a quest the player never had")
end

-- Content contract: completion keeps the reward-free completion path and the split
function TestRescueSafeTeardown:test_the_failure_of_a_quest_with_a_completion_split_does_not_start_the_split_quest()
	local sc = R.fresh(SPLIT):toWaiting()

	sc.quest:failQuest(sc.player, "true")
	H.advance(secs(5))

	lu.assertEquals(#R.createEvents("startQuest", "assassinate_corellia_rebel_tier4_4_a"), 0, "a completion split does not fire on failure")
end
