-- Duty rescue: leaving the zone ends the duty, failures, stale events, the second Lua VM and teardown
-- (space-quest-rescue-duty).
-- Spec: .claude/work/space-quest-rescue-duty/01-spec.md (AC-6, AC-7, AC-8, AC-9 I-6, I-4, I-5, I-7, Behavior 5 to 7).
-- Times are milliseconds on the harness clock.

local lu = require("luaunit")
local H = require("harness")
local DR = require("rescue_duty_scenario")

DR.load()
DR.snapshotVm()

local function secs(n) return n * 1000 end

local REP = DR.REP
local STAGE = { WARP = 1, DOCK = 2, DOCKED = 3, ESCORT = 4, ARRIVED = 5 }
local FAIL_MUSIC = "sound/music_themequest_fail_criminal.snd"

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

local function setOf(list)
	local s = {}

	for _, v in ipairs(list) do
		s[v] = true
	end

	return s
end

-- Builders for every stage a duty can be in when it ends. Each returns the scenario and the objects the end must clean.
local STATES = {
	-- setup done, the target has not warped in yet
	areaOnly = function()
		local sc = DR.fresh(REP):start()
		return sc, { area = sc:area() }
	end,
	waiting = function()
		local sc = DR.fresh(REP):toWaiting()
		H.advance(secs(2))
		return sc, { area = sc:area(), target = sc:target(), waypoint = sc:waypoints()[1] }
	end,
	docked = function()
		local sc = DR.fresh(REP):toDocked()
		return sc, { area = sc:area(), target = sc:target(), waypoint = sc:waypoints()[1] }
	end,
	escort = function()
		local sc = DR.fresh(REP)

		DR.alwaysFirstList(sc)
		sc:toEscort()
		sc:atEscort(secs(sc.o.period) + secs(5))

		return sc, { area = sc:area(), target = sc:target(), waypoint = sc:waypoints()[1], attackers = sc:wave(1).agents }
	end,
	-- 5 s after the first rescue's payment: the cleanup has run, the next rescue has not started
	between = function()
		local sc = DR.fresh(REP):toEscort()

		sc:arrived()
		sc:atArrival(secs(5))
		return sc, { area = nil }
	end,
	-- second rescue, waiting for the dock
	secondRescue = function()
		local sc = DR.fresh(REP):toEscort()

		sc:arrived()
		sc:nextRescue()
		sc:warp()
		H.advance(secs(2))
		return sc, { area = sc:area(), target = sc:target(), waypoint = sc:waypoints()[1] }
	end,
}

local STATE_NAMES = { "areaOnly", "waiting", "docked", "escort", "between", "secondRescue" }

-- The player's own entries of a message list in order, as "via:key".
local function sequence(sc)
	local out = {}

	for _, e in ipairs(sc:events()) do
		out[#out + 1] = e.via .. ":" .. e.key
	end

	return out
end

local function index(list, wanted)
	for i, v in ipairs(list) do
		if v == wanted then
			return i
		end
	end

	return nil
end

local function plainMessages(sc, name)
	local n = 0

	for _, e in ipairs(H.messageLog(sc.player)) do
		if e.id == "@spacequest/rescue_duty/" .. sc.name .. ":" .. name then
			n = n + 1
		end
	end

	return n
end

-- True if nothing of the duty is left: keys, waypoint status, observers, area, target, attackers.
local function assertCleaned(label, sc, objs)
	lu.assertEquals(sc:keyNames(), {}, label .. ": no duty shared-memory key remains (cycle, rewardShips, ... included)")
	lu.assertEquals(sc:strayKeys(), {}, label .. ": no stray key")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), label .. ": the waypointID quest status is removed")
	lu.assertEquals(#sc:waypoints(), 0, label .. ": no waypoint left")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), label .. ": ZONESWITCHED dropped")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), label .. ": SHIPDOCKED dropped")
	lu.assertFalse(sc:active(), label .. ": the journal quest is not active")
	lu.assertFalse(sc:complete(), label .. ": and not complete")

	if objs.area then
		lu.assertTrue(objs.area.destroyed == true, label .. ": the area is destroyed")
		lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", objs.area), 0, label .. ": ENTEREDAREA dropped")
	end

	if objs.target then
		lu.assertTrue(objs.target.hyperspacing, label .. ": the target is hyperspacing")
		lu.assertFalse(objs.target.dockable, label .. ": the target is not dockable")
		lu.assertEquals(#DR.destroyEvents(objs.target), 1, label .. ": the target has one delayed destroy")
		lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyTargetDestroyed", objs.target), 0, label .. ": SHIPDESTROYED dropped on the target")
	end

	for i, agent in ipairs(objs.attackers or {}) do
		lu.assertTrue(agent.hyperspacing, label .. ": attacker " .. i .. " is hyperspacing")
		lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), 0, label .. ": kill observer dropped on attacker " .. i)
	end

	for i, agent in ipairs(H.spawnedShips()) do
		lu.assertEquals(H.Engine.observerCount(SHIPDESTROYED, sc.className, "notifyTargetDestroyed", agent), 0, label .. ": no kill observer on ship " .. i)
	end
end

TestDutyLeaveZone = {}

function TestDutyLeaveZone:setUp() H.reset() end

-- AC-6
function TestDutyLeaveZone:test_leaving_ends_the_duty_after_the_observer_with_the_duty_ended_messages_in_every_stage()
	for _, stage in ipairs(STATE_NAMES) do
		local sc, objs = STATES[stage]()
		local paid = #sc:payments()
		local completion = sc:spyCompletion()

		H.zoneSwitch(sc.player, DR.ELSEWHERE)

		lu.assertTrue(sc:active(), stage .. ": nothing ends inside the ZONESWITCHED observer")
		lu.assertEquals(DR.count(sc:events(), "destroy_abandoned", "duty"), 0, stage .. ": no destroy_abandoned inside the observer")
		lu.assertEquals(#DR.createEvents("endDuty", sc.className), 1, stage .. ": exactly one endDuty event was scheduled")
		lu.assertEquals(DR.createEvents("endDuty", sc.className)[1][1], 0, stage .. ": endDuty is scheduled at 0 ms")

		H.advance(0)

		local seq = sequence(sc)
		local abandoned = index(seq, "duty:destroy_abandoned")
		local ended = index(seq, "ended:title")

		lu.assertNotNil(abandoned, stage .. ": the duty update destroy_abandoned was sent, got " .. table.concat(seq, ", "))
		lu.assertNotNil(ended, stage .. ": quest_ended was sent, got " .. table.concat(seq, ", "))
		lu.assertTrue(abandoned < ended, stage .. ": destroy_abandoned comes before quest_ended")
		lu.assertEquals(DR.only(sc:events(), "destroy_abandoned", "duty")[1].TO, "@space/quest:destroy_abandoned", stage .. ": duty update TO")
		lu.assertEquals(DR.only(sc:events(), "title", "ended")[1].TO, DR.title(REP), stage .. ": quest_ended TO is the duty title")
		lu.assertEquals(DR.count(sc:events(), "title", "failed"), 0, stage .. ": no quest_failed")
		lu.assertEquals(DR.count(sc:events(), "rescue_abandoned", "update"), 0, stage .. ": no rescue_abandoned")
		lu.assertEquals(DR.count(sc:events(), "mission_abandoned", "duty"), 0, stage .. ": no mission_abandoned")
		lu.assertEquals(#sc.player.failedMissions, 1, stage .. ": the datapad mission was removed (failQuestMission once)")
		lu.assertEquals(sc.player.failedMissions[1], H.questCrc("rescue_duty", REP), stage .. ": for this quest")
		assertCleaned(stage, sc, objs)
		lu.assertEquals(#sc:payments(), paid, stage .. ": credits already paid are not reversed, none added")
		lu.assertEquals(sc.player.bankCredits, 5000 * paid, stage .. ": bank total unchanged")
		lu.assertEquals(#completion.space + #completion.quest, 0, stage .. ": the journal is never completed")
	end
end

-- AC-6
function TestDutyLeaveZone:test_nothing_of_the_old_rescue_runs_after_the_duty_ended()
	for _, stage in ipairs(STATE_NAMES) do
		local sc = STATES[stage]()

		H.zoneSwitch(sc.player, DR.ELSEWHERE)
		H.advance(0)

		local areas, ships, payments, keys = #areaCalls(), #H.spawnedShips(), #sc:payments(), #H.Engine.sharedMemoryKeys()

		H.advance(secs(7200))
		lu.assertEquals(#areaCalls(), areas, stage .. ": no new area afterwards (the pending nextCycle is stale)")
		lu.assertEquals(#H.spawnedShips(), ships, stage .. ": nothing spawns afterwards")
		lu.assertEquals(#sc:payments(), payments, stage .. ": nothing is paid afterwards")
		lu.assertEquals(#H.Engine.sharedMemoryKeys(), keys, stage .. ": no key reappears")
		lu.assertEquals(DR.count(sc:events(), "title", "failed"), 0, stage .. ": no expiry failure afterwards")
		lu.assertFalse(sc:active(), stage .. ": still not active")
	end
end

-- AC-6
function TestDutyLeaveZone:test_after_leaving_the_duty_can_be_taken_again_with_a_fresh_run()
	for _, stage in ipairs({ "escort", "between" }) do
		local sc = STATES[stage]()
		local paid = #sc:payments()

		H.zoneSwitch(sc.player, DR.ELSEWHERE)
		H.advance(0)
		lu.assertFalse(sc:active(), stage .. ": ended")

		-- back in the quest zone, the trainer starts the duty again
		H.zoneSwitch(sc.player, DR.ZONE)

		local areasBefore = #areaCalls()
		local progressBefore = #DR.only(sc:events(), "title", "progress")

		sc:start()

		lu.assertTrue(sc:active(), stage .. ": startQuest activates the journal quest again")
		lu.assertEquals(#areaCalls(), areasBefore + 1, stage .. ": a fresh run sets up a new area")
		lu.assertEquals(sc:data("cycle"), 0, stage .. ": cycle 0 again")
		lu.assertEquals(#DR.only(sc:events(), "title", "progress"), progressBefore + 1, stage .. ": the in-progress message is sent again")
		lu.assertEquals(sc:data("stage"), STAGE.WARP, stage .. ": stage WARP")
		lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), stage .. ": ZONESWITCHED registered again")

		sc:warp()
		H.advance(5000)
		sc:dock():escort():arrived()
		lu.assertEquals(#sc:payments(), paid + 1, stage .. ": the new duty pays")
		lu.assertEquals(sc.player.bankCreditLog[#sc.player.bankCreditLog].amount, 5000, stage .. ": 5000 (no stale kill bonus)")
	end
end

-- AC-6, Behavior 7: before setup a zone switch to another zone does nothing
function TestDutyLeaveZone:test_a_zone_switch_before_setup_leaves_the_quest_active_and_ends_nothing()
	local sc = DR.fresh(REP, { zone = "space_naboo" })

	sc:start()
	lu.assertTrue(sc:active(), "active after startQuest in another zone")
	lu.assertEquals(#areaCalls(), 0, "no setup in the wrong zone")

	H.zoneSwitch(sc.player, DR.ELSEWHERE)
	H.advance(secs(5))
	lu.assertTrue(sc:active(), "a switch to yet another zone before setup leaves the quest active")
	lu.assertEquals(#sc:events(), 0, "no message")
	lu.assertEquals(#DR.createEvents("endDuty", sc.className), 0, "no endDuty")

	H.zoneSwitch(sc.player, DR.ZONE)
	H.advance(secs(2))
	lu.assertEquals(#areaCalls(), 1, "arriving in the quest zone sets the duty up (inherited checkSetup)")
	lu.assertTrue(sc:active(), "still active")
end

-- AC-6: a player without the quest
function TestDutyLeaveZone:test_the_zone_observer_ignores_a_player_without_the_quest()
	local sc = DR.fresh(REP)
	local result = sc.quest:enteredZone(sc.player, nil, getHashCode(DR.ELSEWHERE))

	lu.assertEquals(result, 1, "the observer is removed when the quest is not active")
	H.advance(secs(5))
	lu.assertEquals(#sc:events(), 0, "no message")
	lu.assertEquals(#DR.createEvents("endDuty", sc.className), 0, "no endDuty event")
end

-- AC-6: the observer keeps itself while the duty is active
function TestDutyLeaveZone:test_the_zone_observer_returns_0_for_a_set_up_duty()
	local sc = STATES.waiting()

	lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(DR.ELSEWHERE)), 0, "other zone")
	lu.assertEquals(sc.quest:enteredZone(sc.player, nil, getHashCode(DR.ZONE)), 0, "same zone (respawn)")
end

TestDutyFailures = {}

function TestDutyFailures:setUp() H.reset() end

local function assertFailedNotEnded(label, sc, paid)
	lu.assertEquals(DR.count(sc:events(), "title", "failed"), 1, label .. ": exactly one quest_failed")
	lu.assertEquals(DR.only(sc:events(), "title", "failed")[1].TO, DR.title(REP), label .. ": quest_failed TO is the duty title")
	lu.assertEquals(DR.count(sc:events(), "title", "ended"), 0, label .. ": no quest_ended")
	lu.assertEquals(DR.count(sc:events(), "destroy_abandoned", "duty"), 0, label .. ": no destroy_abandoned")
	lu.assertEquals(DR.count(sc:events(), "mission_abandoned", "duty"), 0, label .. ": no mission_abandoned")
	lu.assertEquals(DR.count(sc:events(), "rescue_abandoned", "update"), 0, label .. ": no rescue_abandoned")
	lu.assertFalse(sc:active(), label .. ": the journal quest is not active")
	lu.assertFalse(sc:complete(), label .. ": and not complete")
	lu.assertEquals(#sc:payments(), paid, label .. ": no reward for the current rescue")

	local music = 0

	for _, m in ipairs(sc.player.music) do
		if m == FAIL_MUSIC then
			music = music + 1
		end
	end

	lu.assertEquals(music, 1, label .. ": the fail music played once")
end

-- AC-7a (space-quest-player-ship-destroyed): the ship death fails the duty at once, in every stage; the respawn switch that
-- follows (a same-zone switch) is inert
function TestDutyFailures:test_a_ship_death_fails_the_duty_in_every_stage_and_the_respawn_switch_adds_nothing()
	for _, stage in ipairs(STATE_NAMES) do
		local sc, objs = STATES[stage]()
		local paid = #sc:payments()
		local completion = sc:spyCompletion()

		H.playerShipDestroyed(sc.player)
		H.advance(0)
		assertFailedNotEnded(stage, sc, paid)
		assertCleaned(stage, sc, objs)
		lu.assertEquals(#completion.space + #completion.quest, 0, stage .. ": the journal is never completed")

		local mark = #H.messageLog(sc.player)

		H.zoneSwitch(sc.player, DR.ZONE)
		H.advance(secs(10))
		lu.assertEquals(#H.messageLog(sc.player), mark, stage .. ": the respawn switch sends nothing")
		assertFailedNotEnded(stage, sc, paid)
	end
end

-- AC-7a: a same-zone switch alone leaves a set-up duty alone in every stage
function TestDutyFailures:test_a_same_zone_switch_alone_does_not_fail_the_duty_in_any_stage()
	for _, stage in ipairs(STATE_NAMES) do
		local sc = STATES[stage]()
		local mark = #sc:events()

		H.zoneSwitch(sc.player, DR.ZONE)
		H.advance(0)
		lu.assertTrue(sc:active(), stage .. ": still active")
		lu.assertEquals(DR.count(sc:events(), "title", "failed"), 0, stage .. ": no quest_failed")
		lu.assertEquals(DR.count(sc:events(), "title", "ended"), 0, stage .. ": no quest_ended")
	end
end

-- AC-7b
function TestDutyFailures:test_destroying_the_target_fails_the_duty_after_failed_destroy_in_every_stage()
	local builders = {
		DOCK = function() return STATES.waiting() end,
		DOCKED = function() return STATES.docked() end,
		ESCORT = function() return STATES.escort() end,
		SECOND_RESCUE = function() return STATES.secondRescue() end,
	}

	for _, stage in ipairs({ "DOCK", "DOCKED", "ESCORT", "SECOND_RESCUE" }) do
		local sc, objs = builders[stage]()
		local paid = #sc:payments()
		local t = sc:target()

		H.destroyShip(t, nil)
		lu.assertTrue(sc:active(), stage .. ": nothing fails inside the SHIPDESTROYED observer")
		lu.assertEquals(DR.count(sc:events(), "failed_destroy", "update"), 0, stage .. ": no failed_destroy inside the observer")

		H.advance(0)

		local seq = sequence(sc)
		local lost = index(seq, "update:failed_destroy")
		local failed = index(seq, "failed:title")

		lu.assertNotNil(lost, stage .. ": failed_destroy update sent, got " .. table.concat(seq, ", "))
		lu.assertNotNil(failed, stage .. ": quest_failed sent")
		lu.assertTrue(lost < failed, stage .. ": failed_destroy comes first")
		lu.assertEquals(DR.only(sc:events(), "failed_destroy", "update")[1].TO, "@spacequest/rescue_duty/" .. REP .. ":failed_destroy", stage .. ": failed_destroy TO")
		assertFailedNotEnded(stage, sc, paid)
		objs.target = nil
		assertCleaned(stage, sc, objs)
	end
end

-- AC-7b: the first rescue's target dying after arrival does not fail the duty
function TestDutyFailures:test_a_target_destroyed_after_its_arrival_does_not_fail_the_duty()
	local sc = DR.fresh(REP):toEscort()

	sc:arrived()

	local old = sc:target()

	H.destroyShip(old, nil)
	H.advance(0)
	lu.assertTrue(sc:active(), "the duty goes on: the arrived target dying is not a loss")
	lu.assertEquals(DR.count(sc:events(), "failed_destroy", "update"), 0, "no failed_destroy")
	sc:nextRescue()
	lu.assertEquals(#areaCalls(), 2, "the next rescue still starts")
end

-- AC-7c
function TestDutyFailures:test_the_target_expires_3600_seconds_after_the_warp_in_with_warpout_failure()
	local sc = DR.fresh(REP):toWaiting()
	local paid = #sc:payments()

	H.advance(secs(3600) - 1)
	lu.assertTrue(sc:active(), "still active one ms before the expiry")
	H.advance(1)

	lu.assertEquals(H.now(), sc.tWarp + secs(3600), "the clock is at warp-in + 3600 s")

	local seq = sequence(sc)
	local warp = index(seq, "message:warpout_failure")
	local failed = index(seq, "failed:title")

	lu.assertNotNil(warp, "warpout_failure sent, got " .. table.concat(seq, ", "))
	lu.assertNotNil(failed, "quest_failed sent")
	lu.assertTrue(warp < failed, "warpout_failure comes first")
	assertFailedNotEnded("expiry", sc, paid)
end

-- AC-7c, AC-8: the second rescue expires 3600 s after its own warp-in
function TestDutyFailures:test_the_second_rescue_has_its_own_expiry_and_the_first_ones_does_nothing()
	local sc = DR.fresh(REP):toEscort()

	sc:arrived()

	local firstWarp = sc.tWarp

	sc:nextRescue()
	sc:warp()

	local secondWarp = sc.tWarp

	lu.assertTrue(secondWarp > firstWarp, "the second warp is later")

	H.advance(firstWarp + secs(3600) + secs(1) - H.now())
	lu.assertTrue(sc:active(), "the first rescue's expiry time passed: nothing happens")
	lu.assertEquals(DR.count(sc:events(), "warpout_failure", "message"), 0, "no warpout_failure")

	H.advance(secondWarp + secs(3600) - H.now())
	lu.assertFalse(sc:active(), "the second rescue expired at its own warp-in + 3600 s")
	lu.assertEquals(DR.count(sc:events(), "warpout_failure", "message"), 1, "one warpout_failure")
	lu.assertEquals(DR.count(sc:events(), "title", "failed"), 1, "one quest_failed")
	lu.assertEquals(#sc:payments(), 1, "only the first rescue was paid")
end

-- AC-7: after a failure the duty can be taken again from a clean state
function TestDutyFailures:test_after_a_failure_the_duty_can_be_started_again_with_cycle_zero()
	local sc = STATES.secondRescue()

	H.playerShipDestroyed(sc.player)
	H.advance(0)
	lu.assertFalse(sc:active(), "failed")
	lu.assertEquals(sc:keyNames(), {}, "no key (cycle included) remains")

	local progress = #DR.only(sc:events(), "title", "progress")

	sc:start()
	lu.assertTrue(sc:active(), "active again")
	lu.assertEquals(#DR.only(sc:events(), "title", "progress"), progress + 1, "in-progress sent again for the new duty")
	lu.assertEquals(sc:data("cycle"), 0, "cycle 0")
end

-- AC-7: failQuest honors notifyClient "false" and does not touch a quest that is not active
function TestDutyFailures:test_fail_quest_with_notify_false_is_silent_and_an_inactive_quest_is_left_alone()
	local sc = STATES.waiting()
	local music = #sc.player.music

	sc.quest:failQuest(sc.player, "false")
	lu.assertFalse(sc:active(), "failed")
	lu.assertEquals(DR.count(sc:events(), "title", "failed"), 0, "no quest_failed message with notifyClient 'false'")
	lu.assertEquals(#sc.player.music, music, "no fail music")

	local events = #sc:events()
	local missions = #sc.player.failedMissions

	sc.quest:failQuest(sc.player, "true")
	lu.assertEquals(#sc:events(), events, "a second failQuest sends nothing")
	lu.assertEquals(#sc.player.failedMissions, missions, "and removes no mission")
end

TestDutyStaleEvents = {}

function TestDutyStaleEvents:setUp() H.reset() end

-- A snapshot of everything an event could change.
local function world(sc)
	return {
		keys = H.Engine.sharedMemoryKeys(),
		values = {
			runID = sc:data("runID"), stage = sc:data("stage"), cycle = sc:data("cycle"), targetID = sc:data("targetID"),
			areaID = sc:data("areaID"), waveCount = sc:data("waveCount"), rewardShips = sc:data("rewardShips"),
			killsPending = sc:data("killsPending"),
		},
		areas = #areaCalls(),
		ships = #H.spawnedShips(),
		messages = #sc.player.messageLog,
		payments = #sc:payments(),
		taunts = #sc.player.tauntLog,
		waypoints = #sc.player.ghost.waypoints + #sc.player.ghost.removedWaypoints,
		active = sc:active(),
		tasks = { sc:taskActive(1), sc:taskActive(2), sc:taskComplete(1), sc:taskComplete(2) },
		observers = #H.Engine.observers,
	}
end

local STALE_METHODS = { "refreshWaypoint", "launchWave", "targetExpired", "startEscort", "endCycle", "nextCycle", "warpTarget", "rescueArrived", "targetLost",
	"abandonRun", "endDuty", "finishQuest" }

-- AC-8
function TestDutyStaleEvents:test_every_event_of_the_previous_rescue_does_nothing_once_the_next_rescue_runs()
	local stagesOfSecond = {
		WARP = function(sc) end,
		DOCK = function(sc) sc:warp() end,
		DOCKED = function(sc) sc:warp(); H.advance(5000); sc:dock() end,
		ESCORT = function(sc) sc:warp(); H.advance(5000); sc:dock(); sc:escort() end,
		ARRIVED = function(sc) sc:rescue() end,
	}

	for _, stage in ipairs({ "WARP", "DOCK", "DOCKED", "ESCORT", "ARRIVED" }) do
		H.reset()

		local sc = DR.fresh(REP)

		DR.alwaysFirstList(sc)
		sc:toEscort()
		sc:atEscort(secs(sc.o.period) + secs(5))
		sc:arrived()

		local oldToken = string.format("%d", sc:runID())
		local oldTarget = sc:target()

		sc:nextRescue()
		stagesOfSecond[stage](sc)
		lu.assertNotEquals(string.format("%d", sc:runID()), oldToken, stage .. ": the second rescue has a new token")

		local before = world(sc)

		for _, method in ipairs(STALE_METHODS) do
			local ok, err = pcall(function() sc.quest[method](sc.quest, sc.player, oldToken) end)

			lu.assertTrue(ok, stage .. ": " .. method .. " with the old token raises no error, got " .. tostring(err))
		end

		local ok, err = pcall(function() sc.quest:dockComplete(sc.player, oldToken .. ":" .. oldTarget.objectID) end)

		lu.assertTrue(ok, stage .. ": dockComplete with the old token raises no error, got " .. tostring(err))
		lu.assertEquals(world(sc), before, stage .. ": nothing changed after replaying the old rescue's events")
	end
end

-- AC-8
function TestDutyStaleEvents:test_the_cycle_end_and_next_events_ignore_a_rescue_that_has_not_arrived()
	local stages = {
		WARP = function() return DR.fresh(REP):start() end,
		DOCK = function() return DR.fresh(REP):toWaiting() end,
		DOCKED = function() return DR.fresh(REP):toDocked() end,
		ESCORT = function() return DR.fresh(REP):toEscort() end,
	}

	for _, stage in ipairs({ "WARP", "DOCK", "DOCKED", "ESCORT" }) do
		local sc = stages[stage]()
		local token = string.format("%d", sc:runID())
		local before = world(sc)

		sc.quest:endCycle(sc.player, token)
		sc.quest:nextCycle(sc.player, token)
		lu.assertEquals(world(sc), before, stage .. ": endCycle and nextCycle with the current token do nothing before the arrival")
		lu.assertTrue(sc:active(), stage .. ": still active")
	end
end

-- AC-8: the natural pending events
function TestDutyStaleEvents:test_no_wave_of_the_first_rescue_spawns_during_the_second_rescue()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period) + secs(10))
	sc:arrived()

	-- the first rescue's chain would launch its second wave at escort + 2 x period
	sc:nextRescue()
	sc:warp()
	H.advance(5000)
	sc:dock():escort()

	sc:atEscort(secs(sc.o.period) - 1)
	lu.assertEquals(#sc:attackWaves(), 1, "only the first rescue's wave exists before the second rescue's first launch")

	sc:atEscort(secs(sc.o.period))
	lu.assertEquals(#sc:attackWaves(), 2, "the second rescue's own first wave comes attackPeriod after its escort start")
	lu.assertEquals(sc:wave(2).t, sc.tEscort + secs(sc.o.period), "at exactly that time")
end

-- AC-8: the stale wave chain during the second rescue's escort
function TestDutyStaleEvents:test_a_stale_launch_wave_does_not_fire_while_the_second_rescue_escorts()
	local sc = DR.fresh(REP)

	DR.alwaysFirstList(sc)
	sc:toEscort()
	sc:atEscort(secs(sc.o.period) + secs(5))

	local firstEscort = sc.tEscort
	local staleLaunch = firstEscort + secs(sc.o.period) * 2

	sc:arrived()
	sc:nextRescue()
	sc:warp()
	H.advance(5000)
	sc:dock():escort()

	lu.assertTrue(sc.tEscort < staleLaunch, "the second rescue is already escorting when the first rescue's chain would launch (sanity)")
	H.advance(staleLaunch + secs(1) - H.now())
	lu.assertEquals(#sc:attackWaves(), 1, "no wave spawned at the first rescue's chain time")
end

-- AC-8: the waypoint refresh chain belongs to one rescue
function TestDutyStaleEvents:test_the_waypoint_refresh_runs_once_per_period_in_the_second_rescue()
	local sc = DR.fresh(REP):toEscort()

	sc:arrived()
	sc:nextRescue()
	sc:warp()

	local function added() return #sc.player.ghost.waypoints + #sc.player.ghost.removedWaypoints end

	local before = added()
	local start = H.now()

	H.advance(secs(60))

	-- first refresh waypointFirstDelay after the warp, then every 30 s: +1 s, +31 s
	lu.assertEquals(added() - before, 2, "two refreshes in the 60 s after the warp-in (" .. (H.now() - start) .. " ms)")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint at a time")
end

-- AC-8
function TestDutyStaleEvents:test_next_cycle_does_not_start_a_rescue_when_the_journal_quest_was_ended_meanwhile()
	local sc = DR.fresh(REP):toEscort()

	sc:arrived()
	SpaceHelpers:failSpaceQuest(sc.player, "rescue_duty", REP, false)
	H.advance(secs(30))
	lu.assertEquals(#areaCalls(), 1, "no new area")
	lu.assertEquals(#DR.targetSpawns(sc), 1, "no new target")
	lu.assertEquals(#sc:payments(), 1, "no extra payment")
	lu.assertEquals(#DR.errorLogs(), 0, "no error logged")
end

TestDutySecondVm = {}

function TestDutySecondVm:setUp() H.reset() end

-- Two rescues with kills and a draw for the second; the reset hook runs at the marked points.
local function twoRescues(vm)
	H.reset()
	math.randomseed(7) -- the sphere sampler draws its angles from math.random; both runs must see the same sequence

	local sc = DR.fresh(REP)
	local function hop() if vm then DR.resetVm() end end

	DR.alwaysFirstList(sc)
	DR.draws(sc, 3, 4)
	sc:toWaiting()
	hop()
	H.advance(5000)
	sc:dock()
	hop()
	sc:escort()
	sc:atEscort(secs(sc.o.period))
	hop()
	DR.killWave(sc, sc:wave(1))
	H.advance(0)
	hop()
	sc:arrived()
	hop()
	sc:atArrival(secs(5))
	hop()
	DR.draws(sc, 2, 6)
	sc:nextRescue()
	hop()
	sc:warp()
	hop()
	H.advance(5000)
	sc:dock()
	hop()
	sc:escort()
	hop()
	sc:atEscort(secs(sc.o.period))
	hop()
	DR.killSome(sc, sc:wave(2), 4)
	H.advance(0)
	hop()
	sc:arrived()
	hop()
	sc:atArrival(secs(30))

	local spawns = {}

	for i, s in ipairs(DR.spawns()) do
		spawns[i] = { s.t, s.name, s.zone, s.x, s.z, s.y }
	end

	local taunts = {}

	for i, t in ipairs(sc:taunts()) do
		taunts[i] = { t.t, t.key }
	end

	local events = {}

	for i, e in ipairs(sc:events()) do
		events[i] = { e.t, e.via, e.key, e.TO, e.DI }
	end

	local payments = {}

	for i, p in ipairs(sc:payments()) do
		payments[i] = { p.t, p.amount, p.notify }
	end

	return { spawns = spawns, taunts = taunts, events = events, payments = payments, keys = H.Engine.sharedMemoryKeys(), areas = #areaCalls() }
end

-- AC-8
function TestDutySecondVm:test_two_rescues_produce_the_same_spawns_payments_and_messages_when_every_event_runs_in_a_fresh_vm()
	local plain = twoRescues(false)
	local hopping = twoRescues(true)

	lu.assertEquals(plain.payments, { { plain.payments[1][1], 6200, true }, { plain.payments[2][1], 6200, true } },
		"sanity: both rescues paid 5000 + 4 x 300 in the plain run")
	lu.assertEquals(hopping.spawns, plain.spawns, "spawns (time, ship, zone, position)")
	lu.assertEquals(hopping.payments, plain.payments, "payments")
	lu.assertEquals(hopping.events, plain.events, "messages")
	lu.assertEquals(hopping.taunts, plain.taunts, "taunts")
	lu.assertEquals(hopping.keys, plain.keys, "shared-memory keys")
	lu.assertEquals(hopping.areas, plain.areas, "areas")
end

-- AC-8
function TestDutySecondVm:test_ending_the_duty_in_a_fresh_vm_cleans_everything()
	for _, stage in ipairs({ "escort", "between", "secondRescue" }) do
		local sc, objs = STATES[stage]()

		DR.resetVm()
		H.zoneSwitch(sc.player, DR.ELSEWHERE)
		DR.resetVm()
		H.advance(0)
		assertCleaned(stage, sc, objs)
		lu.assertEquals(DR.count(sc:events(), "title", "ended"), 1, stage .. ": quest_ended once")
	end
end

TestDutyTeardown = {}

function TestDutyTeardown:setUp() H.reset() end

-- AC-8, I-4, I-5
function TestDutyTeardown:test_reset_quest_clears_everything_in_every_stage_without_a_lua_error()
	for _, stage in ipairs(STATE_NAMES) do
		local sc, objs = STATES[stage]()
		local ok, err = pcall(function() sc.quest:resetQuest(sc.player) end)

		lu.assertTrue(ok, stage .. ": resetQuest raises no error, got " .. tostring(err))
		assertCleaned(stage, sc, objs)
		lu.assertEquals(DR.count(sc:events(), "title", "failed"), 0, stage .. ": a reset sends no failure message")
		lu.assertEquals(DR.count(sc:events(), "title", "ended"), 0, stage .. ": nor an ended message")
		H.advance(secs(7200))
		lu.assertEquals(sc:keyNames(), {}, stage .. ": nothing reappears later")
		lu.assertEquals(#DR.errorLogs(), 0, stage .. ": no error logged")
	end
end

-- I-5
function TestDutyTeardown:test_fail_reset_and_end_raise_no_error_for_a_player_who_never_started_or_never_set_up()
	for _, name in ipairs(DR.NAMES) do
		H.reset()

		local quest = H.expectGlobal(DR.global(name))
		local fresh = H.newPlayer({ zone = DR.ZONE, ship = {}, pilot = "rebel" })
		local elsewhere = H.newPlayer({ zone = "space_naboo", ship = {}, pilot = "rebel" })

		quest:startQuest(elsewhere, "")

		for who, player in pairs({ neverStarted = fresh, neverSetUp = elsewhere }) do
			for _, call in ipairs({
				function() quest:failQuest(player, "true") end,
				function() quest:failQuest(player, "false") end,
				function() quest:resetQuest(player) end,
				function() quest:endDuty(player, "12345") end,
				function() quest:endDuty(player, "") end,
				function() quest:endCycle(player, "12345") end,
				function() quest:nextCycle(player, "12345") end,
				function() quest:cleanUpQuestData(player) end,
				function() quest:abandonRun(player, "12345") end,
			}) do
				local ok, err = pcall(call)

				lu.assertTrue(ok, name .. " " .. who .. ": no Lua error, got " .. tostring(err))
			end
		end

		lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, name .. ": nothing written")
		lu.assertEquals(#DR.errorLogs(), 0, name .. ": nothing logged as an error")
	end
end

-- AC-8: an end event with a token that is not the current run's does not end the duty
function TestDutyTeardown:test_end_duty_with_a_wrong_or_missing_token_does_nothing()
	local sc = STATES.waiting()
	local messages = #sc.player.messageLog

	sc.quest:endDuty(sc.player, "")
	sc.quest:endDuty(sc.player, "12345")
	sc.quest:endDuty(sc.player, nil)
	lu.assertTrue(sc:active(), "still active")
	lu.assertEquals(#sc.player.messageLog, messages, "no message")
end

-- I-6
function TestDutyTeardown:test_a_whole_duty_never_completes_its_journal_quest_on_any_path()
	local paths = {
		function()
			local sc = DR.fresh(REP)
			local c = sc:spyCompletion()

			sc:toEscort()
			sc:arrived()
			sc:nextRescue()
			sc:rescue()
			H.advance(secs(60))
			return sc, c
		end,
		function()
			local sc = DR.fresh(REP)
			local c = sc:spyCompletion()

			sc:toEscort()
			sc:arrived()
			H.zoneSwitch(sc.player, DR.ELSEWHERE)
			H.advance(secs(30))
			return sc, c
		end,
		function()
			local sc = DR.fresh(REP)
			local c = sc:spyCompletion()

			sc:toWaiting()
			H.destroyShip(sc:target(), nil)
			H.advance(secs(30))
			return sc, c
		end,
		function()
			local sc = DR.fresh(REP)
			local c = sc:spyCompletion()

			sc:toWaiting()
			H.advance(secs(3700))
			return sc, c
		end,
		function()
			local sc = DR.fresh(REP)
			local c = sc:spyCompletion()

			sc:toEscort()
			H.zoneSwitch(sc.player, DR.ZONE)
			H.advance(secs(30))
			return sc, c
		end,
		function()
			local sc = DR.fresh(DR.CORSEC)
			local c = sc:spyCompletion()

			sc:toEscort()
			sc:arrived()
			sc:nextRescue()
			sc.quest:resetQuest(sc.player)
			H.advance(secs(30))
			return sc, c
		end,
	}

	for i, build in ipairs(paths) do
		H.reset()

		local sc, c = build()

		lu.assertEquals(#c.space, 0, "path " .. i .. ": SpaceHelpers:completeSpaceQuest was never called")
		lu.assertEquals(#c.quest, 0, "path " .. i .. ": completeQuest was never called")
		lu.assertEquals(#c.finish, 0, "path " .. i .. ": finishQuest was never called")
		lu.assertFalse(sc:complete(), "path " .. i .. ": the journal quest is not complete")
		lu.assertEquals(#DR.createEvents("finishQuest"), 0, "path " .. i .. ": finishQuest was never scheduled")
	end
end

-- I-4: keys always carry the duty's prefix, in every stage
function TestDutyTeardown:test_every_key_the_duty_writes_has_the_player_and_class_prefix_in_every_stage()
	for _, stage in ipairs(STATE_NAMES) do
		local sc = STATES[stage]()

		lu.assertEquals(sc:strayKeys(), {}, stage .. ": no key outside <playerID>:<className>:")
		lu.assertTrue(#sc:keyNames() > 0, stage .. ": the duty holds keys while it runs")
	end
end
