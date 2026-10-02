-- Delivery attack waves (space-quest-stub-delivery).
-- Spec: .claude/work/space-quest-stub-delivery/01-spec.md (AC-8, Behavior 2, 7 and 9). The wave rules
-- are survival's (slice 1 AC-6, AC-7), so these tests pin the delivery-specific timing, the squadron
-- and cap behavior through the SpaceAttackWaves mixin, and the targets-remaining message.
-- Expected lists and periods come from the SWG-Source fixtures through delivery_scenario.lua.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")

D.load()

local function secs(n) return n * 1000 end

local ENDOR = { "delivery", "corellia_rebel_tier3_3" }          -- period 80, SEQUENTIAL, 2 lists of 3
local NO_PICKUP = { "delivery_no_pickup", "corellia_rebel_tier4_2_a" } -- period 45, RANDOM, 3 lists of 6
local CORSEC_3 = { "delivery", "corellia_privateer_tier3_3" }   -- 0 lists, period 60

local function fresh(q, opts) return D.fresh(q[1], q[2], opts) end

local ATTACK_NOTIFY = "attack_notify"

local function launchTimes(sc)
	local out = {}

	for i, w in ipairs(D.attackWaves(sc)) do
		out[i] = w.t
	end

	return out
end

TestDeliveryWavesTiming = {}

function TestDeliveryWavesTiming:setUp() H.reset() end

-- AC-8
function TestDeliveryWavesTiming:test_no_attack_ship_spawns_before_the_pickup_dock()
	local sc = fresh(ENDOR):start():arrive()

	sc:at(secs(600))

	lu.assertEquals(#D.attackSpawns(sc), 0, "no attack ship in 600 s without a dock")
	lu.assertEquals(#sc:transports(), 1, "the pickup transport is there")
end

-- AC-8
function TestDeliveryWavesTiming:test_waves_launch_every_period_after_the_pickup_dock_using_the_lists_in_turn()
	local sc = fresh(ENDOR):toFirstDock()
	local o = sc.o

	for i = 1, 3 do
		sc:atDock(secs(o.period * i) - 1)
		lu.assertEquals(#D.attackWaves(sc), i - 1, "no wave " .. i .. " one ms early")

		sc:atDock(secs(o.period * i))

		local waves = D.attackWaves(sc)

		lu.assertEquals(#waves, i, "wave " .. i .. " launched")
		lu.assertEquals(waves[i].t, sc.tDock + secs(o.period * i), "wave " .. i .. " launch time")
		lu.assertEquals(D.names(waves[i]), o.lists[(i - 1) % 2 + 1], "wave " .. i .. " ship list (sequential, wrapping)")

		D.killWave(sc, waves[i])
	end

	lu.assertEquals(launchTimes(sc), { sc.tDock + secs(80), sc.tDock + secs(160), sc.tDock + secs(240) }, "launch times 80, 160, 240 s after the dock")
	lu.assertEquals(D.count(sc:events(), ATTACK_NOTIFY, "message"), 3, "attack_notify once per wave")
	lu.assertEquals(D.effects(sc.player, D.WAVE_EFFECT), 3, "ui_quest_spawn_wave.cef once per wave")
	lu.assertEquals(D.count(sc:events(), "first_attack"), 0, "delivery has no first_attack update")
end

-- AC-8
function TestDeliveryWavesTiming:test_wave_ships_are_owned_hostile_and_target_the_players_ship()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	local wave = D.wave(sc, 1)

	lu.assertEquals(#wave.agents, 3, "three ships in the first list")

	for i, agent in ipairs(wave.agents) do
		lu.assertEquals(agent.missionOwner, sc.player, "ship " .. i .. ": mission owner")
		lu.assertEquals(agent.factionEnemies, { sc.ship.factionHash }, "ship " .. i .. ": enemy of the player's faction")
		lu.assertEquals(agent.engaged, { sc.ship }, "ship " .. i .. ": engages the player's ship")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), "ship " .. i .. ": SHIPDESTROYED observer")
		lu.assertFalse(agent.isSquadronLeader, "ship " .. i .. ": three ships do not form a squadron")
	end
end

-- AC-8
function TestDeliveryWavesTiming:test_waves_continue_through_the_delivery_leg_and_while_the_delivery_transport_waits()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(2))
	sc:arrive()
	sc:at(secs(6))

	local t = sc:transport()

	sc:atDock(secs(80))
	D.killWave(sc, D.wave(sc, 1))
	sc:atDock(secs(160))

	lu.assertEquals(#D.attackWaves(sc), 2, "the second wave still launched while the delivery transport waits")
	lu.assertTrue(sc:active(), "kills never complete or fail the quest")
	lu.assertEquals(t.dockableCalls, { true }, "waves do not touch the transport")
end

-- AC-8
function TestDeliveryWavesTiming:test_waves_stop_when_the_quest_completes_and_the_attack_ships_are_removed()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	local wave = D.wave(sc, 1)

	sc:atDock(secs(95))
	sc:arrive()
	sc:at(secs(10))
	sc:dock()
	sc:atDock(secs(2))
	lu.assertTrue(sc:complete(), "precondition: completed")

	local launches = #D.attackWaves(sc)

	H.advance(secs(3600))

	lu.assertEquals(#D.attackWaves(sc), launches, "no wave launches after completion")

	for i, agent in ipairs(wave.agents) do
		lu.assertTrue(agent.destroyed, "attack ship " .. i .. " is removed by the cleanup")
	end
end

-- AC-8
function TestDeliveryWavesTiming:test_a_quest_with_no_attack_lists_never_spawns_an_attack_ship()
	local sc = fresh(CORSEC_3):start():arrive():at(secs(10))

	sc:dock()
	sc:atDock(secs(2))
	sc:arrive()
	sc:at(secs(10))
	sc:dock()
	H.advance(secs(3600))

	lu.assertEquals(#D.attackSpawns(sc), 0, "no attack ship ever, although attackPeriod is 60")
	lu.assertTrue(sc:complete(), "the quest itself completed")
end

TestDeliveryWavesNoPickup = {}

function TestDeliveryWavesNoPickup:setUp() H.reset() end

-- AC-8
function TestDeliveryWavesNoPickup:test_the_first_wave_launches_55_seconds_after_setup_with_the_random_list_and_forms_a_squadron()
	local sc = fresh(NO_PICKUP)

	H.Engine.nextRandom = 2 -- after fresh(): H.reset() clears it

	sc.quest:startQuest(sc.player, "")

	local tSetup = H.now()

	H.advance(secs(55) - 1)
	lu.assertEquals(#D.attackWaves(sc), 0, "no wave before 55 s")

	H.advance(1)

	local waves = D.attackWaves(sc)

	lu.assertEquals(#waves, 1, "one wave at 55 s (10 s + the 45 s period)")
	lu.assertEquals(waves[1].t, tSetup + secs(55), "launch time")
	lu.assertEquals(D.names(waves[1]), sc.o.lists[2], "list 2 (getRandomNumber returned 2)")
	lu.assertEquals(#waves[1].agents, 6, "six ships")
	lu.assertTrue(waves[1].agents[1].isSquadronLeader, "the first ship leads a squadron")

	for i = 2, 6 do
		lu.assertEquals(waves[1].agents[i].squadronLeader, waves[1].agents[1], "ship " .. i .. " is assigned to the squadron leader")
	end
end

-- AC-8
function TestDeliveryWavesNoPickup:test_the_wave_timer_starts_at_setup_not_at_arrival_and_repeats_every_period()
	local sc = fresh(NO_PICKUP)

	sc.quest:startQuest(sc.player, "")

	local tSetup = H.now()

	H.advance(secs(55))
	D.killWave(sc, D.wave(sc, 1))
	H.advance(secs(45))
	D.killWave(sc, D.wave(sc, 2))
	H.advance(secs(45))

	lu.assertEquals(launchTimes(sc), { tSetup + secs(55), tSetup + secs(100), tSetup + secs(145) }, "launches at 55, 100 and 145 s after setup, with no arrival at all")
end

TestDeliveryWavesKills = {}

function TestDeliveryWavesKills:setUp() H.reset() end

-- AC-8
function TestDeliveryWavesKills:test_each_kill_reports_the_targets_left_and_the_last_kill_reports_the_wave_cleared()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	local wave = D.wave(sc, 1)

	H.destroyShip(wave.agents[1], sc.ship)

	local remaining = D.only(sc:events(), "targets_remaining")

	lu.assertEquals(#remaining, 1, "one remaining message after the first kill")
	lu.assertEquals(remaining[1].DI, 2, "DI = 2 ships left")

	H.destroyShip(wave.agents[2], sc.ship)
	remaining = D.only(sc:events(), "targets_remaining")
	lu.assertEquals(#remaining, 2, "two remaining messages after the second kill")
	lu.assertEquals(remaining[2].DI, 1, "DI = 1 ship left")
	lu.assertEquals(D.count(sc:events(), "attack_stopped"), 0, "not cleared yet")

	H.destroyShip(wave.agents[3], sc.ship)
	lu.assertEquals(#D.only(sc:events(), "targets_remaining"), 2, "no remaining message on the last kill")
	lu.assertEquals(D.count(sc:events(), "attack_stopped", "message"), 1, "attack_stopped on the last kill")
	lu.assertEquals(D.effects(sc.player, "clienteffect/ui_quest_destroyed_wave.cef"), 1, "ui_quest_destroyed_wave.cef on the last kill")
	lu.assertTrue(sc:active(), "kills never complete the quest")
end

-- AC-8
function TestDeliveryWavesKills:test_the_remaining_message_is_sent_by_the_hook_with_the_player_and_the_count()
	local sc = fresh(ENDOR):toFirstDock()
	local calls = H.spyOn(sc.quest, "notifyTargetsRemaining")

	sc:atDock(secs(80))
	H.destroyShip(D.wave(sc, 1).agents[1], sc.ship)

	lu.assertEquals(#calls, 1, "notifyTargetsRemaining called once")
	lu.assertEquals(calls[1].args[1], sc.player, "with the player")
	lu.assertEquals(calls[1].args[2], 2, "and the number of attack ships alive")
end

-- AC-8
function TestDeliveryWavesKills:test_a_kill_inside_the_observer_spawns_and_destroys_nothing()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(80))

	local before = #D.spawns()

	H.destroyShip(D.wave(sc, 1).agents[1], sc.ship)

	lu.assertEquals(#D.spawns(), before, "nothing spawned by a kill")
	lu.assertTrue(sc:active(), "quest active")
end

-- AC-8
function TestDeliveryWavesKills:test_with_two_live_waves_the_next_period_waits_and_a_cleared_wave_launches_it_through_a_0_ms_event()
	local sc = fresh(ENDOR):toFirstDock()

	sc:atDock(secs(160))

	local waves = { D.wave(sc, 1), D.wave(sc, 2) }

	sc:atDock(secs(250))
	lu.assertEquals(#D.attackWaves(sc), 2, "the 240 s launch waited: two waves are live (cap 2)")

	local before = #D.spawns()

	-- killing the first wave: the messages count all attack ships alive (3 of wave 2 + the wave's own)
	H.destroyShip(waves[1].agents[1], sc.ship)
	H.destroyShip(waves[1].agents[2], sc.ship)
	lu.assertEquals(#D.spawns(), before, "still waiting while the wave has a live ship")

	H.destroyShip(waves[1].agents[3], sc.ship)
	lu.assertEquals(#D.spawns(), before, "nothing is spawned inside the SHIPDESTROYED observer")

	local killTime = H.now()

	H.advance(0)

	local after = D.attackWaves(sc)

	lu.assertEquals(#after, 3, "the waiting wave launched through a 0 ms event")
	lu.assertEquals(after[3].t, killTime, "at the time of the kill")
	lu.assertEquals(D.names(after[3]), sc.o.lists[1], "third launch uses list 1 again (sequential)")

	local di = {}

	for _, e in ipairs(D.only(sc:events(), "targets_remaining")) do
		di[#di + 1] = e.DI
	end

	lu.assertEquals(di, { 5, 4, 3 }, "targets remaining counts every attack ship of the run that is alive, and not the last kill of a run")
	lu.assertEquals(D.count(sc:events(), "attack_stopped"), 0, "no attack_stopped while another wave is live or launching")
end
