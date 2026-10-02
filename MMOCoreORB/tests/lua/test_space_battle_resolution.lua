-- Space battle kills, win, lose, warp-out timeout and re-engagement (space-quest-stub-space-battle).
-- Spec: .claude/work/space-quest-stub-space-battle/01-spec.md (AC-6, AC-7, AC-8, AC-11, I-6, I-8, Behavior 7-10).

local lu = require("luaunit")
local H = require("harness")
local B = require("battle_scenario")

B.load()

local function secs(n) return n * 1000 end

local function allShips() return H.spawnedShips() end

local function messageCount(sc) return #H.messageLog(sc.player) end

-- A fresh scenario with both forces present; returns sc, allies, enemies.
local function battle(name)
	local sc = B.fresh(name):setup()
	local allies, enemies = sc:both()

	return sc, allies, enemies
end

TestSpaceBattleKills = {}

function TestSpaceBattleKills:setUp() H.reset() end

-- AC-6, I-6
function TestSpaceBattleKills:test_the_ship_destroyed_observer_only_defers_and_returns_1()
	local sc, allies, enemies = battle(B.WIN)
	local mem = B.memorySnapshot()
	local sizes = B.engageSizes(allShips())
	local sent = messageCount(sc)
	local effects = #sc.player.effects
	local adds = #sc.player.missionObjectLog
	local removes = #sc.player.removedMissionObjectLog
	local spawned = #H.spawnedShips()
	local events = #H.Engine.callsTo("createEvent")

	lu.assertEquals(sc.quest:notifyBattleShipDestroyed(enemies[1], sc.ship), 1, "the observer returns 1")

	lu.assertEquals(messageCount(sc), sent, "no message inside the observer")
	lu.assertEquals(#sc.player.effects, effects, "no effect inside the observer")
	lu.assertEquals(#sc.player.missionObjectLog, adds, "no mission object added inside the observer")
	lu.assertEquals(#sc.player.removedMissionObjectLog, removes, "no mission object removed inside the observer")
	lu.assertEquals(B.engageSizes(allShips()), sizes, "no engage call inside the observer")
	lu.assertEquals(#H.spawnedShips(), spawned, "no spawn inside the observer")
	lu.assertEquals(B.memorySnapshot(), mem, "no shared memory or quest status changed inside the observer")
	lu.assertTrue(sc:active(), "the journal quest is untouched inside the observer")
	lu.assertTrue(sc:taskActive(2), "task 2 untouched inside the observer")
	lu.assertTrue(#H.Engine.callsTo("createEvent") > events, "the observer created a deferred event")
end

-- AC-6, I-6
function TestSpaceBattleKills:test_a_destroyed_ship_changes_nothing_until_the_zero_ms_events_run()
	local sc, allies, enemies = battle(B.WIN)
	local mem = B.memorySnapshot()
	local sizes = B.engageSizes(allShips())
	local sent = messageCount(sc)

	H.destroyShip(enemies[1], sc.ship)

	lu.assertEquals(messageCount(sc), sent, "no message before the 0 ms events")
	lu.assertEquals(B.engageSizes(allShips()), sizes, "no engage call before the 0 ms events")
	lu.assertEquals(B.memorySnapshot(), mem, "no state change before the 0 ms events")
	lu.assertEquals(#sc.player.removedMissionObjectLog, 0, "the mission object is still there before the 0 ms events")

	H.advance(0)

	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5 }, "enemies_remain with DI 5 after the events")
	lu.assertEquals(sc.player.removedMissionObjectLog, { { id = enemies[1].objectID, notify = true } }, "the dead ship's mission object is removed with notify")
end

-- AC-6
function TestSpaceBattleKills:test_killing_the_enemies_counts_down_and_the_last_kill_sends_allies_win_instead_of_a_remaining_count()
	local sc, allies, enemies = battle(B.WIN)

	lu.assertEquals(#enemies, 6, "precondition: six enemies")

	for i = 1, 5 do
		sc:kill(enemies[i])
	end

	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5, 4, 3, 2, 1 }, "enemies_remain DI after each of the first five kills")
	lu.assertEquals(B.count(sc:events(), "allies_win"), 0, "no allies_win before the last enemy")

	local tKill = H.now()

	sc:kill(enemies[6])

	local win = B.only(sc:events(), "allies_win", "update")

	lu.assertEquals(#win, 1, "allies_win update sent once")
	lu.assertEquals(win[1].t, tKill, "allies_win is sent at the kill")
	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5, 4, 3, 2, 1 }, "the sixth kill sends no enemies_remain")
	lu.assertEquals(B.count(sc:events(), "enemies_win"), 0, "no enemies_win")
end

-- AC-6, Behavior 9
function TestSpaceBattleKills:test_the_quest_completes_two_seconds_after_the_last_enemy_dies_and_the_completion_split_runs()
	local sc, allies, enemies = battle(B.WIN)

	for i = 1, 6 do
		sc:kill(enemies[i])
	end

	H.advance(B.RESOLVE_DELAY - 1)
	lu.assertTrue(sc:active(), "still active 1999 ms after the last kill")
	lu.assertFalse(sc:complete(), "not complete 1999 ms after the last kill")
	lu.assertEquals(#B.createEvents("startQuest", "assassinate_corellia_privateer_tier4_3b"), 0, "the split quest is not scheduled yet")

	H.advance(1)

	lu.assertTrue(sc:complete(), "complete at 2000 ms")
	lu.assertFalse(sc:active(), "no longer active")
	lu.assertTrue(sc:taskComplete(2), "task 2 complete")
	lu.assertEquals(#B.createEvents("sendQuestAlert", "SpaceHelpers"), 1, "the split alert is scheduled")
	lu.assertEquals(#B.createEvents("startQuest", "assassinate_corellia_privateer_tier4_3b"), 1, "the assassinate split quest is scheduled")
end

-- AC-6, D-9
function TestSpaceBattleKills:test_killing_an_ally_between_the_last_enemy_and_the_win_sends_nothing_and_does_not_fail_the_quest()
	local sc, allies, enemies = battle(B.WIN)

	for i = 1, 6 do
		sc:kill(enemies[i])
	end

	local sent = messageCount(sc)

	sc:kill(allies[1])

	lu.assertEquals(messageCount(sc), sent, "the ally kill sends nothing once the battle is resolved")
	lu.assertTrue(sc:active(), "the quest is still active")

	H.advance(B.RESOLVE_DELAY)

	lu.assertTrue(sc:complete(), "the quest completes")
	lu.assertEquals(B.count(sc:events(), "enemies_win"), 0, "no enemies_win")
end

-- Behavior 7, D-9
function TestSpaceBattleKills:test_the_last_ally_dying_between_the_last_enemy_and_the_win_does_not_turn_the_win_into_a_loss()
	local sc, allies, enemies = battle(B.WIN)

	for i = 1, 6 do
		sc:kill(enemies[i])
	end

	for i = 1, 4 do
		sc:kill(allies[i])
	end

	H.advance(B.RESOLVE_DELAY)

	lu.assertTrue(sc:complete(), "the first resolution (the win) stands")
	lu.assertEquals(B.count(sc:events(), "enemies_win"), 0, "no enemies_win after allies_win")
	lu.assertEquals(B.count(sc:events(), "allies_win"), 1, "allies_win once")
end

-- Behavior 7
function TestSpaceBattleKills:test_ally_kills_report_allies_remaining_without_touching_the_enemy_count()
	local sc, allies, enemies = battle(B.WIN)

	sc:kill(allies[1])
	sc:kill(enemies[1])
	sc:kill(allies[2])

	lu.assertEquals(B.dis(sc:events(), "allies_remain"), { 3, 2 }, "allies_remain DI")
	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5 }, "enemies_remain DI")
	lu.assertEquals(#sc.player.removedMissionObjectLog, 3, "one removeSpaceMissionObject per dead ship")

	for i, e in ipairs(sc.player.removedMissionObjectLog) do
		lu.assertEquals(e.notify, true, "kill " .. i .. ": removeSpaceMissionObject notifies the client")
	end
end

-- Behavior 7
function TestSpaceBattleKills:test_a_ship_that_is_not_in_the_force_is_ignored()
	local sc, allies, enemies = battle(B.WIN)
	local stranger = H.worldAgent({ shipName = "blacksun_aggressor_tier4", zone = sc.o.zone })
	local events = #H.Engine.callsTo("createEvent")

	lu.assertEquals(sc.quest:notifyBattleShipDestroyed(stranger, sc.ship), 1, "the observer returns 1 for any ship")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), events, "a ship without a mission owner creates no event")

	local ownedStranger = H.worldAgent({ shipName = "blacksun_aggressor_tier4", zone = sc.o.zone })
	ownedStranger.missionOwner = sc.player

	sc.quest:notifyBattleShipDestroyed(ownedStranger, sc.ship)
	H.advance(0)

	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), {}, "a mission-owned ship of another quest changes no count")
	lu.assertEquals(B.dis(sc:events(), "allies_remain"), {}, "a mission-owned ship of another quest changes no count")
end

-- Behavior 7
function TestSpaceBattleKills:test_the_same_kill_delivered_twice_counts_once()
	local sc, allies, enemies = battle(B.WIN)

	sc.quest:notifyBattleShipDestroyed(enemies[1], sc.ship)
	sc.quest:notifyBattleShipDestroyed(enemies[1], sc.ship)
	H.advance(0)

	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5 }, "one enemies_remain for a duplicated notification")
end

-- Behavior 7: kills during setup (before the second force) still count
function TestSpaceBattleKills:test_a_kill_before_the_battle_starts_is_counted_and_engages_nobody()
	local sc = B.fresh(B.ALLIES_FIRST):setup()
	local allies = sc:allies()

	sc:kill(allies[1])

	lu.assertEquals(B.dis(sc:events(), "allies_remain"), { 2 }, "allies_remain after an early kill")
	lu.assertEquals(B.engageCount(allies), 0, "an early kill engages nobody")
end

-- Behavior 5 (RESOLVED stage), Behavior 7
function TestSpaceBattleKills:test_a_force_wiped_before_the_other_arrives_loses_and_the_late_arrival_spawns_nothing()
	local sc = B.fresh(B.ALLIES_FIRST):setup()
	local allies = sc:allies()

	-- 1 s before the enemy arrival (35 s): the loss is still pending (2 s) when the enemies are due
	sc:at(secs(sc.o.enemyDelay - 1))

	for _, ally in ipairs(allies) do
		sc:kill(ally)
	end

	lu.assertEquals(B.count(sc:events(), "enemies_win", "update"), 1, "enemies_win once the allies are gone, even before the enemies arrived")

	sc:at(secs(sc.o.enemyDelay))

	lu.assertEquals(#H.spawnedShips(), #allies, "the enemy arrival of a resolved battle spawns nothing")
	lu.assertEquals(B.count(sc:events(), "enemies_arrived"), 0, "no enemies_arrived")
	lu.assertEquals(B.count(sc:events(), "battle_started"), 0, "the battle never started")

	H.advance(B.RESOLVE_DELAY - 1000)
	lu.assertFalse(sc:active(), "the quest fails two seconds after the last ally died")
end

TestSpaceBattleLose = {}

function TestSpaceBattleLose:setUp() H.reset() end

-- AC-7
function TestSpaceBattleLose:test_killing_the_allies_counts_down_and_the_last_kill_sends_enemies_win()
	local sc, allies, enemies = battle(B.LOSE)

	lu.assertEquals(#allies, 5, "precondition: five allies")

	for i = 1, 4 do
		sc:kill(allies[i])
	end

	lu.assertEquals(B.dis(sc:events(), "allies_remain"), { 4, 3, 2, 1 }, "allies_remain DI after the first four kills")
	lu.assertEquals(B.count(sc:events(), "enemies_win"), 0, "no enemies_win yet")

	sc:kill(allies[5])

	lu.assertEquals(B.count(sc:events(), "enemies_win", "update"), 1, "enemies_win update sent")
	lu.assertEquals(B.dis(sc:events(), "allies_remain"), { 4, 3, 2, 1 }, "the fifth kill sends no allies_remain")
	lu.assertEquals(B.count(sc:events(), "allies_win"), 0, "no allies_win")
end

-- AC-7, Behavior 10
function TestSpaceBattleLose:test_the_quest_fails_two_seconds_later_and_the_failure_split_runs()
	local sc, allies, enemies = battle(B.LOSE)

	for i = 1, 5 do
		sc:kill(allies[i])
	end

	H.advance(B.RESOLVE_DELAY - 1)
	lu.assertTrue(sc:active(), "still active 1999 ms after the last ally dies")

	H.advance(1)

	lu.assertFalse(sc:active(), "no longer active at 2000 ms")
	lu.assertFalse(sc:complete(), "failed, not complete")
	lu.assertEquals(#B.createEvents("startQuest", "survival_corellia_rebel_tier4_3_b"), 1, "the failure split starts survival_corellia_rebel_tier4_3_b")
end

-- AC-7
function TestSpaceBattleLose:test_a_lost_child_battle_fails_its_parent_through_the_existing_event()
	local sc, allies, enemies = battle(B.CHILD)

	for _, ally in ipairs(allies) do
		sc:kill(ally)
	end

	H.advance(B.RESOLVE_DELAY)

	local events = B.createEvents("failQuest", "space_battle_corellia_rebel_tier4_3")

	lu.assertEquals(#events, 1, "one parent failure event")
	lu.assertEquals(events[1][1], 200, "the parent failure event is delayed 200 ms")
	lu.assertEquals(events[1][5], "false", "the parent is failed without a client notification")
	lu.assertFalse(sc:active(), "the child quest is no longer active")
end

-- D-9
function TestSpaceBattleLose:test_an_enemy_dying_after_the_allies_were_wiped_does_not_turn_the_loss_into_a_win()
	local sc, allies, enemies = battle(B.LOSE)

	for _, ally in ipairs(allies) do
		sc:kill(ally)
	end

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	H.advance(B.RESOLVE_DELAY)

	lu.assertFalse(sc:complete(), "not complete")
	lu.assertFalse(sc:active(), "failed")
	lu.assertEquals(B.count(sc:events(), "allies_win"), 0, "no allies_win after enemies_win")
end

TestSpaceBattleTimeout = {}

function TestSpaceBattleTimeout:setUp() H.reset() end

-- AC-8
function TestSpaceBattleTimeout:test_the_battle_fails_with_warpout_failure_1500_s_after_the_first_arrival()
	local sc = B.fresh(B.ALLIES_FIRST):setup()

	lu.assertEquals({ sc.o.allyDelay, sc.o.enemyDelay }, { 20, 35 }, "precondition: allies at 20 s, enemies at 35 s")

	sc:at(1520 * 1000 - 1)
	lu.assertTrue(sc:active(), "still active at 1519.999 s")
	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "no warpout_failure yet")

	H.advance(1)

	local fails = B.only(sc:events(), "warpout_failure", "message")

	lu.assertEquals(#fails, 1, "warpout_failure sent at 1520 s")
	lu.assertEquals(fails[1].t, 1520 * 1000, "warpout_failure time")
	lu.assertFalse(sc:active(), "the quest is no longer active")

	sc:at(1600 * 1000)
	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 1, "still one warpout_failure at 1600 s (the second force's timer does nothing)")
end

-- AC-8, D-10 (the timer is armed per force arrival)
function TestSpaceBattleTimeout:test_the_timeout_counts_from_the_first_force_arrival_not_from_the_battle_start()
	local sc = B.fresh(B.WIN):setup()

	lu.assertEquals({ sc.o.allyDelay, sc.o.enemyDelay }, { 60, 90 }, "precondition: allies at 60 s, enemies at 90 s")

	sc:at(secs(60 + 1500) - 1)
	lu.assertTrue(sc:active(), "still active 1 ms before the allies' timer")

	H.advance(1)

	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 1, "warpout_failure at the allies' timer (60 s + 1500 s)")
	lu.assertFalse(sc:active(), "the quest is no longer active")
end

-- AC-8
function TestSpaceBattleTimeout:test_a_battle_won_before_the_timeout_never_sends_warpout_failure()
	local sc, allies, enemies = battle(B.ALLIES_FIRST)

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	H.advance(B.RESOLVE_DELAY)
	lu.assertTrue(sc:complete(), "the battle was won")

	sc:at(1600 * 1000)

	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "no warpout_failure after a win")
	lu.assertTrue(sc:complete(), "still complete")
end

-- AC-8, Behavior 8 (RESOLVED stage)
function TestSpaceBattleTimeout:test_a_win_pending_when_the_timer_fires_is_not_failed_by_it()
	local sc, allies, enemies = battle(B.ALLIES_FIRST)

	sc:at(secs(1519))

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	sc:at(secs(1530))

	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "the first timer (1520 s) sees a resolved battle and does nothing")
	lu.assertTrue(sc:complete(), "the win lands at 1521 s")
end

-- AC-8, Behavior 8 (journal quest cleared externally)
function TestSpaceBattleTimeout:test_a_cleared_journal_quest_is_cleaned_up_silently_by_the_timer()
	local sc, allies, enemies = battle(B.ALLIES_FIRST)

	SpaceHelpers:failSpaceQuest(sc.player, "space_battle", sc.name, false)
	lu.assertFalse(sc:active(), "precondition: the journal quest was cleared")

	local sent = messageCount(sc)
	local destroyBefore = #B.destroyEvents()

	sc:at(1520 * 1000)

	lu.assertEquals(messageCount(sc), sent, "no message is sent by the cleanup")

	local events = B.destroyEvents()

	lu.assertEquals(#events - destroyBefore, #allies + #enemies, "every live force ship gets a delayedDestroyShipAgent event")

	local seen = {}

	for i = destroyBefore + 1, #events do
		seen[events[i].agent] = true
		lu.assertEquals(events[i].delay, 2000, "delayedDestroyShipAgent after 2 s")
	end

	for _, ship in ipairs(allShips()) do
		lu.assertTrue(seen[ship] == true, "ship " .. ship.objectID .. " is scheduled for destruction")
	end

	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no run key is left")
	lu.assertEquals(#sc:waypoints(), 0, "the waypoint is gone")
end

TestSpaceBattleReengage = {}

function TestSpaceBattleReengage:setUp() H.reset() end

local function assertOnly(grew, agent, target, label)
	lu.assertEquals(#grew, 1, label .. ": exactly one ship got a new engage call")
	lu.assertTrue(grew[1].agent == agent, label .. ": the ship that re-engaged")
	lu.assertEquals(#grew[1].new, 1, label .. ": one new call")
	lu.assertTrue(grew[1].new[1] == target, label .. ": its new target")
end

-- AC-11
function TestSpaceBattleReengage:test_the_initial_orders_match_the_spec_walkthrough()
	local sc, allies, enemies = battle(B.WIN)

	for i = 1, 4 do
		lu.assertEquals(B.targetsOf(allies[i]), { enemies[i] }, "ally " .. i .. " engages enemy " .. i)
	end

	local wantAllyIndex = { 1, 2, 3, 4, 1, 2 }

	for j = 1, 6 do
		lu.assertEquals(B.targetsOf(enemies[j]), { allies[wantAllyIndex[j]] }, "enemy " .. j .. " engages ally " .. wantAllyIndex[j])
	end
end

-- AC-11, I-6
function TestSpaceBattleReengage:test_a_kill_engages_nobody_inside_the_observer_and_the_attacker_re_engages_afterwards()
	local sc, allies, enemies = battle(B.WIN)
	local all = allShips()
	local sizes = B.engageSizes(all)

	H.destroyShip(enemies[1], sc.ship)
	lu.assertEquals(B.newEngages(all, sizes), {}, "no new engage call before the 0 ms events")

	H.advance(0)

	local grew = B.newEngages(all, sizes)

	assertOnly(grew, allies[1], enemies[6], "after E1 dies")
	lu.assertEquals(B.targetsOf(allies[1]), { enemies[1], enemies[6] }, "A1 was on E1 and is now on E6")
	B.assertEngageInvariant(allies, enemies, "after E1 dies")
end

-- AC-11
function TestSpaceBattleReengage:test_a_dead_ally_makes_only_the_enemies_that_targeted_it_re_engage_by_the_cursor_rule()
	local sc, allies, enemies = battle(B.WIN)
	local all = allShips()

	sc:kill(enemies[1])

	local sizes = B.engageSizes(all)

	sc:kill(allies[1])

	-- E1 (target A1) is dead; E5 is the only live enemy that targeted A1; live allies are A2-A4, ally cursor 6 -> A2
	assertOnly(B.newEngages(all, sizes), enemies[5], allies[2], "after A1 dies")
	B.assertEngageInvariant(allies, enemies, "after A1 dies")
end

-- AC-11
function TestSpaceBattleReengage:test_a_ship_nobody_targeted_causes_no_new_orders()
	local sc, allies, enemies = battle(B.WIN)
	local all = allShips()
	local sizes = B.engageSizes(all)

	sc:kill(enemies[5])

	lu.assertEquals(B.newEngages(all, sizes), {}, "E5 was nobody's target: no engage call")
	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5 }, "the kill is still counted")
end

-- AC-11
function TestSpaceBattleReengage:test_killing_every_enemy_keeps_the_invariant_and_the_last_kill_orders_nothing()
	local sc, allies, enemies = battle(B.WIN)
	local all = allShips()

	for i = 1, 5 do
		sc:kill(enemies[i])
		B.assertEngageInvariant(allies, enemies, "after enemy " .. i .. " dies")
	end

	local sizes = B.engageSizes(all)

	sc:kill(enemies[6])

	lu.assertEquals(B.newEngages(all, sizes), {}, "the last enemy's death orders nobody (stage RESOLVED)")
	B.assertEngageInvariant(allies, enemies, "after the last enemy dies")
end

-- AC-11
function TestSpaceBattleReengage:test_killing_every_ally_keeps_the_invariant_and_the_last_kill_orders_nothing()
	local sc, allies, enemies = battle(B.WIN)
	local all = allShips()

	for i = 1, 3 do
		sc:kill(allies[i])
		B.assertEngageInvariant(allies, enemies, "after ally " .. i .. " dies")
	end

	local sizes = B.engageSizes(all)

	sc:kill(allies[4])

	lu.assertEquals(B.newEngages(all, sizes), {}, "the last ally's death orders nobody")
end

-- AC-11, I-8 (alternating kills; every live ship that has orders points at a live opponent)
function TestSpaceBattleReengage:test_alternating_kills_never_leave_a_ship_pointed_at_a_dead_target()
	local sc, allies, enemies = battle(B.LOSE)

	for i = 1, 4 do
		sc:kill(enemies[i])
		B.assertEngageInvariant(allies, enemies, "after enemy " .. i)
		sc:kill(allies[i])
		B.assertEngageInvariant(allies, enemies, "after ally " .. i)
	end

	for i = 5, 9 do
		sc:kill(enemies[i])
		B.assertEngageInvariant(allies, enemies, "after enemy " .. i)
	end
end

-- AC-11, I-8: every engage call has one live ship of the opposing force of this run
function TestSpaceBattleReengage:test_every_engage_call_of_a_run_targets_a_live_opponent_at_the_time_of_the_call()
	local sc, allies, enemies = battle(B.WIN)
	local isAlly, isEnemy = {}, {}

	for _, a in ipairs(allies) do isAlly[a] = true end
	for _, e in ipairs(enemies) do isEnemy[e] = true end

	for i = 1, 3 do
		sc:kill(enemies[i])
		sc:kill(allies[i])
	end

	for _, a in ipairs(allies) do
		for k, entry in ipairs(a.engageLog) do
			lu.assertTrue(isEnemy[entry.target] == true, "ally call " .. k .. " targets an enemy of the run")
		end
	end

	for _, e in ipairs(enemies) do
		for k, entry in ipairs(e.engageLog) do
			lu.assertTrue(isAlly[entry.target] == true, "enemy call " .. k .. " targets an ally of the run")
		end
	end
end

-- Revised D-5: engage orders stop with the run
function TestSpaceBattleReengage:test_no_engage_call_is_made_after_the_run_ended()
	local sc, allies, enemies = battle(B.WIN)

	sc.quest:failQuest(sc.player, "false")

	local sizes = B.engageSizes(allShips())

	sc.quest:notifyBattleShipDestroyed(enemies[1], sc.ship)
	H.advance(secs(2000))

	lu.assertEquals(B.newEngages(allShips(), sizes), {}, "a late kill notification after the end orders nobody")
end

-- AC-6, I-4
function TestSpaceBattleKills:test_a_won_battle_leaves_no_keys_and_hands_the_survivors_to_the_cleanup()
	local sc, allies, enemies = battle(B.WIN)

	sc:kill(allies[1])

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	H.advance(B.RESOLVE_DELAY)

	lu.assertTrue(sc:complete(), "complete")
	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no run key is left")
	lu.assertEquals(B.strayKeys(sc.player, sc.className), {}, "no key outside <playerID>:<className>:")
	lu.assertEquals(#sc:waypoints(), 0, "the waypoint is gone")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "ZONESWITCHED dropped")

	local scheduled = {}

	for _, e in ipairs(B.destroyEvents()) do
		scheduled[e.agent] = true
	end

	for i = 2, 4 do
		lu.assertTrue(scheduled[allies[i]] == true, "surviving ally " .. i .. " is scheduled for destruction")
		lu.assertTrue(allies[i].hyperspacing, "surviving ally " .. i .. " is set hyperspacing")
	end

	lu.assertNil(scheduled[allies[1]], "the dead ally is not scheduled again")
end
