-- Delivery failure paths, teardown and stale events (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (AC-9, AC-10, I-4, I-5, I-8, Behavior 3,
-- 10, 11, decisions D-5, D-9, D-10). Times are milliseconds.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")

D.load()
D.snapshotVm()

local function secs(n) return n * 1000 end

local ELSEWHERE = "space_tatooine"
local ENDOR = { "delivery", "corellia_rebel_tier3_3" }
local LOK_2A = { "delivery", "corellia_rebel_tier3_2_a" }   -- has a parent quest (inspect_corellia_rebel_tier3_2)
local NO_PICKUP = { "delivery_no_pickup", "corellia_rebel_tier4_2_a" }

local function fresh(q, opts) return D.fresh(q[1], q[2], opts) end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

TestDeliveryTransportLost = {}

function TestDeliveryTransportLost:setUp() H.reset() end

-- AC-9
function TestDeliveryTransportLost:test_destroying_the_waiting_pickup_transport_fails_the_quest_after_the_observer_returns()
	local sc = fresh(LOK_2A):toFirstTransport()
	local t = sc:transport()

	H.destroyShip(t, nil)

	lu.assertTrue(sc:active(), "nothing fails inside the SHIPDESTROYED observer")
	lu.assertEquals(D.count(sc:events(), "failed_destroyed"), 0, "no failed_destroyed update inside the observer")

	H.advance(0)

	lu.assertEquals(D.count(sc:events(), "failed_destroyed", "update"), 1, "failed_destroyed update sent")
	lu.assertFalse(sc:active(), "the journal quest is no longer active")
	lu.assertFalse(sc:complete(), "and not complete")
	lu.assertEquals(#D.createEvents("failQuest", "inspect_corellia_rebel_tier3_2"), 1, "the parent's failQuest event was created")
end

-- AC-9
function TestDeliveryTransportLost:test_destroying_the_waiting_delivery_transport_fails_the_quest()
	local sc = fresh(ENDOR):toFirstDock()

	sc:toDeliveryTransport()

	local d = sc:transport()

	H.destroyShip(d, nil)
	lu.assertTrue(sc:active(), "nothing fails inside the observer")

	H.advance(0)

	lu.assertEquals(D.count(sc:events(), "failed_destroyed", "update"), 1, "failed_destroyed update")
	lu.assertFalse(sc:active(), "quest failed")
end

-- AC-9 (Behavior 10)
function TestDeliveryTransportLost:test_notify_transport_destroyed_returns_1_in_every_case()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()
	local stray = spawnShipAgent("imp_tie_fighter_tier3", sc.o.zone, 1, 2, 3, sc.ship)

	ShipAiAgent(stray):setMissionOwner(sc.player)

	lu.assertEquals(sc.quest:notifyTransportDestroyed(stray, nil), 1, "a ship that is not the stored transport")
	H.advance(secs(5))
	lu.assertTrue(sc:active(), "a stray destroyed ship does not fail the quest")

	lu.assertEquals(sc.quest:notifyTransportDestroyed(t, nil), 1, "the stored transport")
	lu.assertTrue(sc:active(), "scheduled, not immediate")
	H.advance(0)
	lu.assertFalse(sc:active(), "failed through the scheduled event")
end

-- AC-9 (Behavior 10)
function TestDeliveryTransportLost:test_a_destroyed_transport_with_no_owner_changes_nothing()
	local sc = fresh(ENDOR):toFirstTransport()
	local orphan = spawnShipAgent(sc.o.pickupShip, sc.o.zone, 1, 2, 3, sc.ship)

	lu.assertEquals(sc.quest:notifyTransportDestroyed(orphan, nil), 1, "returns 1")
	H.advance(secs(5))
	lu.assertTrue(sc:active(), "quest unaffected")
end

-- AC-9
function TestDeliveryTransportLost:test_a_transport_destroyed_after_the_quest_ended_does_nothing()
	local sc = fresh(ENDOR):toFirstTransport()
	local t = sc:transport()

	sc.quest:failQuest(sc.player, "false")
	lu.assertEquals(sc.quest:notifyTransportDestroyed(t, nil), 1, "returns 1")
	H.advance(secs(5))

	lu.assertEquals(D.count(sc:events(), "failed_destroyed"), 0, "no failed_destroyed for an ended quest")
end

TestDeliveryAbandon = {}

function TestDeliveryAbandon:setUp() H.reset() end

local function abandonAfter(sc)
	H.zoneSwitch(sc.player, ELSEWHERE)
	H.advance(secs(5))
end

-- AC-9
function TestDeliveryAbandon:test_leaving_the_zone_after_setup_but_before_arrival_abandons_the_quest()
	local sc = fresh(ENDOR):start()

	abandonAfter(sc)

	lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 1, "@space/quest:mission_abandoned update")
	lu.assertFalse(sc:active(), "quest failed")
end

-- AC-9
function TestDeliveryAbandon:test_leaving_the_zone_after_arrival_while_the_transport_waits_abandons_the_quest()
	local sc = fresh(ENDOR):toFirstTransport()

	abandonAfter(sc)

	lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 1, "mission_abandoned update")
	lu.assertFalse(sc:active(), "quest failed")
	lu.assertEquals(sc:transport().dockableCalls, { true, false }, "the waiting transport is released (I-8)")
end

-- AC-9
function TestDeliveryAbandon:test_leaving_the_zone_during_the_delivery_leg_abandons_the_quest()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(2))
	abandonAfter(sc)

	lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 1, "mission_abandoned update")
	lu.assertFalse(sc:active(), "quest failed")
end

-- AC-8 (space-quest-player-ship-destroyed, D-14): the respawn after a ship death is a same-zone switch; it is inert
-- (the death itself failed the quest through playerShipDestroyed)
function TestDeliveryAbandon:test_a_same_zone_switch_after_setup_leaves_the_run_alone()
	local sc = fresh(ENDOR):start():arrive()
	local sent = #sc:events()

	H.zoneSwitch(sc.player, sc.o.zone)
	H.advance(secs(5))

	lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 0, "no mission_abandoned update")
	lu.assertTrue(sc:active(), "the quest is still active")
	lu.assertEquals(#sc:events(), sent, "nothing was sent by the same-zone switch")
end

-- AC-9
function TestDeliveryAbandon:test_abandoning_fails_the_parent_quest_where_there_is_one()
	local sc = fresh(LOK_2A):start()

	abandonAfter(sc)

	lu.assertEquals(#D.createEvents("failQuest", "inspect_corellia_rebel_tier3_2"), 1, "parent failQuest event")
end

-- AC-9
function TestDeliveryAbandon:test_switching_to_another_zone_before_setup_keeps_the_quest_active()
	local sc = fresh(ENDOR, { zone = ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.zoneSwitch(sc.player, "space_corellia")
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "quest still active")
	lu.assertEquals(D.count(sc:events(), "mission_abandoned"), 0, "no abandon message")
	lu.assertEquals(#areaCalls(), 0, "and no setup in the wrong zone")
end

-- AC-9
function TestDeliveryAbandon:test_zone_switch_events_for_an_inactive_quest_are_ignored_and_remove_the_observer()
	local sc = fresh(ENDOR):start()

	sc.quest:failQuest(sc.player, "false")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "observer dropped by failQuest")

	local result = sc.quest:enteredZone(sc.player, nil, getHashCode(ELSEWHERE))

	lu.assertEquals(result, 1, "enteredZone returns 1 for an inactive quest (removes the observer)")
end

local ENDINGS = {
	complete = function(sc) sc.quest:completeQuest(sc.player, "true") end,
	fail = function(sc) sc.quest:failQuest(sc.player, "true") end,
	reset = function(sc) sc.quest:resetQuest(sc.player) end,
}

local ENDING_NAMES = { "complete", "fail", "reset" }

-- Builds a mid-run state. Returns the scenario plus the objects the teardown must clean.
local STATES = {
	-- waiting dockable pickup transport, no wave yet
	waitingTransport = function()
		local sc = fresh(ENDOR):toFirstTransport()
		return sc, { transport = sc:transport() }
	end,
}

-- A run with the delivery transport waiting and one live wave.
local function transportAndWave()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(2))
	sc:arrive()
	sc:at(secs(6))

	local t = sc:transport()

	sc:atDock(secs(80))

	return sc, { transport = t, wave = D.wave(sc, 1) }
end

-- A run with the delivery area, a live wave, and no transport waiting.
local function areaAndWave()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	return sc, { area = sc:area(), wave = D.wave(sc, 1), waypoint = sc:waypoints()[1] }
end

-- A run with the first rendezvous area still waiting for the player.
local function areaOnly()
	local sc = fresh(ENDOR):start()

	return sc, { area = sc:area(), waypoint = sc:waypoints()[1] }
end

TestDeliveryTeardown = {}

function TestDeliveryTeardown:setUp() H.reset() end

local function assertTransportCleaned(sc, t, ending)
	local label = ending .. ": transport"

	lu.assertEquals(t.dockableCalls, { true, false }, label .. " dockableCalls ends with false (I-8)")
	lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyTransportDestroyed", t), label .. " SHIPDESTROYED observer dropped")
	lu.assertEquals(#D.removedAsMissionObject(sc.player, t), 1, label .. " removed as a mission object")
	lu.assertTrue(t.hyperspacing, label .. " setHyperspacing(true)")
	lu.assertEquals(#D.destroyEvents(t), 1, label .. " one delayedDestroyShipAgent event")
	lu.assertEquals(D.destroyEvents(t)[1].delay, 2000, label .. " destroyed 2 s later")
end

local function assertWaveCleaned(sc, wave, ending)
	for i, agent in ipairs(wave.agents) do
		local label = ending .. ": attack ship " .. i

		lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), label .. " SHIPDESTROYED observer dropped")
		lu.assertEquals(#D.removedAsMissionObject(sc.player, agent), 1, label .. " removed as a mission object")
		lu.assertEquals(#D.destroyEvents(agent), 1, label .. " one delayedDestroyShipAgent event")
	end
end

local function assertCommonCleaned(sc, ending)
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), ending .. ": ZONESWITCHED observer dropped")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, sc.className, "notifyDocked", sc.player), ending .. ": SHIPDOCKED observer dropped")
	lu.assertEquals(#sc:waypoints(), 0, ending .. ": waypoint removed")
	lu.assertNil(H.getQuestStatus(sc.player, ":" .. sc.className .. ":waypointID"), ending .. ": waypointID quest status removed (I-4)")
	lu.assertEquals(D.memoryKeys(), {}, ending .. ": no shared-memory key left (I-4)")
	lu.assertEquals(D.strayKeys(sc.player, sc.className), {}, ending .. ": every key was under <playerID>:<className>: (I-4)")
end

-- AC-10
function TestDeliveryTeardown:test_ending_with_a_waiting_transport_releases_it_and_cleans_everything()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = STATES.waitingTransport()

		ENDINGS[ending](sc)

		assertTransportCleaned(sc, objects.transport, ending)
		assertCommonCleaned(sc, ending)
		H.reset()
	end
end

-- AC-10
function TestDeliveryTeardown:test_ending_with_a_waiting_transport_and_a_live_wave_cleans_both()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = transportAndWave()

		ENDINGS[ending](sc)

		assertTransportCleaned(sc, objects.transport, ending)
		assertWaveCleaned(sc, objects.wave, ending)
		assertCommonCleaned(sc, ending)
		H.reset()
	end
end

-- AC-10
function TestDeliveryTeardown:test_ending_with_the_rendezvous_area_and_a_live_wave_destroys_the_area_and_the_wave()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = areaAndWave()

		ENDINGS[ending](sc)

		lu.assertTrue(objects.area.destroyed, ending .. ": area destroyed")
		lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", objects.area), 0, ending .. ": area observer dropped")
		assertWaveCleaned(sc, objects.wave, ending)
		assertCommonCleaned(sc, ending)
		H.reset()
	end
end

-- AC-10
function TestDeliveryTeardown:test_ending_while_the_first_area_waits_destroys_the_area_and_the_waypoint()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = areaOnly()

		ENDINGS[ending](sc)

		lu.assertTrue(objects.area.destroyed, ending .. ": area destroyed")
		lu.assertEquals(H.Engine.observerCount(ENTEREDAREA, sc.className, "notifyEnteredQuestArea", objects.area), 0, ending .. ": area observer dropped")
		lu.assertTrue(objects.waypoint.destroyed, ending .. ": waypoint object removed")
		assertCommonCleaned(sc, ending)
		H.reset()
	end
end

-- AC-10
function TestDeliveryTeardown:test_pumping_the_remaining_events_after_an_ending_sends_no_message_and_spawns_nothing()
	local builders = { waitingTransport = STATES.waitingTransport, transportAndWave = transportAndWave, areaAndWave = areaAndWave, areaOnly = areaOnly }

	for stateName, build in pairs(builders) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc = build()

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

			local before, spawnsBefore, areasBefore, tauntsBefore = quiet(), #D.spawns(), #areaCalls(), #sc:taunts()

			H.advance(secs(3600))

			lu.assertEquals(quiet(), before, stateName .. " " .. ending .. ": no delivery message after the ending")
			lu.assertEquals(#D.spawns(), spawnsBefore, stateName .. " " .. ending .. ": no ship spawned after the ending")
			lu.assertEquals(#areaCalls(), areasBefore, stateName .. " " .. ending .. ": no area spawned after the ending")
			lu.assertEquals(#sc:taunts(), tauntsBefore, stateName .. " " .. ending .. ": no taunt after the ending")
			lu.assertEquals(D.memoryKeys(), {}, stateName .. " " .. ending .. ": still no shared-memory key")
			H.reset()
		end
	end
end

-- AC-10
function TestDeliveryTeardown:test_a_late_dock_with_the_old_transport_after_an_ending_changes_nothing()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc, objects = STATES.waitingTransport()
		local t = objects.transport

		ENDINGS[ending](sc)

		lu.assertEquals(sc.quest:notifyDocked(sc.player, t, 0), 0, ending .. ": notifyDocked ignores the old transport")
		H.dock(sc.player, t)
		H.advance(secs(60))

		lu.assertEquals(#sc:taunts(), 0, ending .. ": no taunt")
		lu.assertEquals(t.dockableCalls, { true, false }, ending .. ": dockable not touched again")
		lu.assertEquals(D.memoryKeys(), {}, ending .. ": no key written")
		H.reset()
	end
end

-- AC-10, D-10: a transport that was already released is left alone
function TestDeliveryTeardown:test_a_transport_that_already_departs_is_not_touched_by_the_ending()
	for _, ending in ipairs(ENDING_NAMES) do
		local sc = fresh(ENDOR):toFirstDock()
		local released = sc:transport()

		sc:atDock(secs(5))
		ENDINGS[ending](sc)

		lu.assertEquals(released.dockableCalls, { true, false }, ending .. ": released transport's dockableCalls unchanged")
		lu.assertEquals(#D.destroyEvents(released), 0, ending .. ": no destroy event from the ending (it has its own 15 s timer)")
		lu.assertFalse(released.hyperspacing, ending .. ": not hyperspaced early")

		sc:atDock(secs(15))
		lu.assertTrue(released.hyperspacing, ending .. ": departs on its own at 15 s")
		H.reset()
	end
end

TestDeliveryRestart = {}

function TestDeliveryRestart:setUp()
	H.reset()
	D.resetVm()
end

-- Fails run 1 `failAfter` ms after its arrival, restarts (optionally "on another VM") and plays
-- run 2 through to the end with docks.
local function failThenRestart(failAfter, otherVm)
	local sc = fresh(ENDOR):start():arrive()

	sc:at(failAfter)
	sc.quest:failQuest(sc.player, "true")
	lu.assertFalse(sc:active(), "precondition: run 1 failed")

	if otherVm then
		D.resetVm()
	end

	sc:start()
	sc:arrive()

	local secondT0 = sc.t0

	sc:at(secs(6))
	sc:at(secs(10))
	sc:dock()
	sc:atDock(secs(2))
	sc:arrive()
	sc:at(secs(10))
	sc:dock()
	sc:atDock(secs(2))
	H.advance(secs(300))

	return sc, secondT0
end

-- AC-10
function TestDeliveryRestart:test_stale_timers_of_a_failed_run_do_not_act_on_a_restarted_run()
	local sc, secondT0 = failThenRestart(secs(1), false)
	local pickups = {}

	for _, s in ipairs(D.spawns()) do
		if s.name == sc.o.pickupShip then
			pickups[#pickups + 1] = s.t
		end
	end

	lu.assertEquals(#sc:transports(), 2, "one pickup transport and one delivery transport, none from run 1's warp timer")
	lu.assertEquals(pickups[1], secondT0 + secs(6), "the pickup transport spawns 6 s after the second arrival, not earlier from run 1's timer")
	lu.assertEquals(#D.tauntTimes(sc:taunts(), "hello_p"), 1, "one hello_p taunt in total")
	lu.assertTrue(sc:complete(), "the second run completed")
	lu.assertEquals(#D.createEvents("startQuest", "assassinate_corellia_rebel_tier3_3_a"), 1, "the completion split fired once")
end

-- AC-10
function TestDeliveryRestart:test_the_same_scenario_on_a_second_lua_vm_gives_the_same_result()
	local sc, secondT0 = failThenRestart(secs(1), true)

	lu.assertEquals(#sc:transports(), 2, "one transport per leg")
	lu.assertEquals(D.spawns()[1].t, secondT0 + secs(6), "first transport spawns 6 s after the second arrival")
	lu.assertEquals(#D.tauntTimes(sc:taunts(), "hello_p"), 1, "one hello_p")
	lu.assertTrue(sc:complete(), "the second run completed")
	lu.assertEquals(#D.createEvents("startQuest", "assassinate_corellia_rebel_tier3_3_a"), 1, "the completion split fired once")
end

-- AC-10: a restart after a failure in the delivery leg, with waves of run 1 still scheduled
function TestDeliveryRestart:test_waves_of_a_failed_run_do_not_continue_into_the_next_run()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	local firstWave = D.wave(sc, 1)

	sc.quest:failQuest(sc.player, "true")
	D.resetVm()

	local before = #D.attackSpawns(sc)

	H.advance(secs(85))
	lu.assertEquals(#D.attackSpawns(sc), before, "run 1's next launch timer (at 160 s after its dock) did nothing")

	sc:start():arrive()
	sc:at(secs(10))
	sc:dock()

	local t0 = sc.tDock

	H.advance(secs(80) - 1)
	lu.assertEquals(#D.attackSpawns(sc), before, "no wave before the new run's own period")

	H.advance(1)

	lu.assertEquals(#D.attackWaves(sc), 2, "exactly one new wave, at the new run's first period")
	lu.assertEquals(D.wave(sc, 2).t, t0 + secs(80), "launched 80 s after the second run's dock")
	lu.assertTrue(firstWave.agents[1].destroyed, "run 1's attack ships were removed")
end

-- AC-10: every step handled by a different Lua VM (no run state in Lua variables)
function TestDeliveryRestart:test_a_full_run_where_every_step_runs_on_a_fresh_vm_completes_with_waves()
	local sc = fresh(ENDOR)

	D.resetVm()
	sc:start()
	D.resetVm()
	sc:arrive()
	sc:at(secs(6))
	D.resetVm()
	sc:at(secs(10))
	sc:dock()
	D.resetVm()
	sc:atDock(secs(2))
	D.resetVm()
	sc:arrive()
	sc:at(secs(6))
	D.resetVm()
	sc:atDock(secs(80))
	D.resetVm()
	D.killWave(sc, D.wave(sc, 1))
	D.resetVm()
	sc:dock()
	D.resetVm()
	sc:atDock(secs(2))
	H.advance(secs(30))

	lu.assertTrue(sc:complete(), "completed although every step ran on a fresh VM")
	lu.assertEquals(#sc:transports(), 2, "one transport per leg")
	lu.assertEquals(D.tauntTimes(sc:taunts(), "docking_complete_pickup")[1] ~= nil, true, "pickup docking taunt")
	lu.assertEquals(#D.attackWaves(sc), 1, "the wave launched once, at the pickup dock plus the period")
	lu.assertEquals(D.memoryKeys(), {}, "nothing left")
end

TestDeliverySafeTeardown = {}

function TestDeliverySafeTeardown:setUp() H.reset() end

-- I-5
function TestDeliverySafeTeardown:test_ending_a_quest_that_never_started_raises_no_error()
	for _, q in ipairs(D.QUESTS) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local sc = D.new(q[1], q[2])

			ENDINGS[ending](sc)
			ENDINGS[ending](sc)
			H.advance(secs(60))

			lu.assertEquals(D.memoryKeys(), {}, q[2] .. " " .. ending .. ": nothing written for a player who never started")
			lu.assertEquals(#H.spawnedAreas(), 0, q[2] .. " " .. ending .. ": no area created by ending a quest")
			lu.assertEquals(#D.spawns(), 0, q[2] .. " " .. ending .. ": no ship created by ending a quest")
		end
	end
end

-- I-5
function TestDeliverySafeTeardown:test_ending_a_quest_that_was_started_but_never_set_up_or_arrived_raises_no_error()
	for _, q in ipairs(D.QUESTS) do
		for _, ending in ipairs(ENDING_NAMES) do
			H.reset()

			local waiting = D.new(q[1], q[2], { zone = ELSEWHERE })

			waiting.quest:startQuest(waiting.player, "")
			ENDINGS[ending](waiting)
			H.advance(secs(60))
			lu.assertEquals(D.memoryKeys(), {}, q[2] .. " " .. ending .. " (not set up): no key left")

			H.reset()

			local setUp = D.new(q[1], q[2]):start()

			ENDINGS[ending](setUp)
			ENDINGS[ending](setUp)
			H.advance(secs(60))

			lu.assertEquals(D.memoryKeys(), {}, q[2] .. " " .. ending .. " (set up, never arrived): no key left")
			lu.assertEquals(#setUp:waypoints(), 0, q[2] .. " " .. ending .. ": no waypoint left")
			lu.assertEquals(#D.spawns(), 0, q[2] .. " " .. ending .. ": no ship spawned")
		end
	end
end

-- I-5
function TestDeliverySafeTeardown:test_ending_a_quest_twice_after_a_full_run_raises_no_error()
	for _, ending in ipairs(ENDING_NAMES) do
		H.reset()

		local sc = fresh(NO_PICKUP):start():arrive():at(secs(10))

		sc:dock()
		ENDINGS[ending](sc)
		ENDINGS[ending](sc)
		H.advance(secs(60))

		lu.assertEquals(D.memoryKeys(), {}, ending .. ": no key left")
	end
end

-- I-4: a dockable transport is never left dockable when the run ends in any way
function TestDeliverySafeTeardown:test_every_quest_leaves_no_dockable_transport_behind_when_failed_mid_run()
	for _, q in ipairs(D.QUESTS) do
		H.reset()

		local sc = fresh(q):start():arrive():at(secs(6))

		sc.quest:failQuest(sc.player, "true")

		for i, t in ipairs(sc:transports()) do
			lu.assertFalse(ShipAiAgent(t):isDockable(), q[2] .. ": transport " .. i .. " is not dockable after the failure")
		end

		lu.assertEquals(#sc:transports(), 1, q[2] .. ": the transport had spawned")
	end
end
