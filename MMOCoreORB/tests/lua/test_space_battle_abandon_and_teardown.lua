-- Space battle abandon, teardown, stale events and the second-VM model (space-quest-stub-space-battle).
-- Spec: .claude/work/space-quest-stub-space-battle/01-spec.md (AC-9, AC-10, I-4, I-5, I-6, Behavior 4, 11, 12).

local lu = require("luaunit")
local H = require("harness")
local B = require("battle_scenario")

B.load()
B.snapshotVm()

local function secs(n) return n * 1000 end

local function spawnCalls() return H.Engine.callsTo("spawnShipAgent") end

local function messageCount(sc) return #H.messageLog(sc.player) end

-- Battle messages the player got, without the split alert a completion or failure split sends on purpose.
local function battleEventCount(sc)
	local n = 0

	for _, e in ipairs(sc:events()) do
		if e.key ~= "split_quest_alert" then
			n = n + 1
		end
	end

	return n
end

local function waypointKey(sc) return sc.player.objectID .. ":" .. sc.className .. ":waypointID" end

-- After the run ended: waypoint, observers, keys, force ships (the spec's Behavior 12).
local function assertTornDown(sc, ships, label)
	lu.assertEquals(#sc:waypoints(), 0, label .. ": the waypoint is removed")
	lu.assertNil(getQuestStatus(waypointKey(sc)), label .. ": the :waypointID quest status is gone")
	lu.assertFalse(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), label .. ": ZONESWITCHED is dropped")
	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, label .. ": no <playerID>:<className>: key remains")

	local scheduled = {}

	for _, e in ipairs(B.destroyEvents()) do
		scheduled[e.agent] = e.delay
	end

	local removed = {}

	for _, e in ipairs(sc.player.removedMissionObjectLog) do
		removed[e.id] = e.notify
	end

	for i, ship in ipairs(ships) do
		if not ship.destroyed then
			lu.assertFalse(H.hasObserver(SHIPDESTROYED, sc.className, "notifyBattleShipDestroyed", ship), label .. ": ship " .. i .. " SHIPDESTROYED observer dropped")
			lu.assertEquals(removed[ship.objectID], false, label .. ": ship " .. i .. " removeSpaceMissionObject(id, false)")
			lu.assertTrue(ship.hyperspacing, label .. ": ship " .. i .. " setHyperspacing(true)")
			lu.assertEquals(scheduled[ship], 2000, label .. ": ship " .. i .. " delayedDestroyShipAgent after 2 s")
		end
	end
end

local function assertNothingHappensAfterwards(sc, ships, label)
	local spawned = #spawnCalls()
	local battleEvents = battleEventCount(sc)

	H.advance(secs(4000))

	lu.assertEquals(#spawnCalls(), spawned, label .. ": no ship spawns after the end")
	lu.assertEquals(battleEventCount(sc), battleEvents, label .. ": no battle message after the end")

	for i, ship in ipairs(ships) do
		lu.assertTrue(ship.destroyed == true, label .. ": ship " .. i .. " is destroyed by its delayedDestroyShipAgent event")
	end
end

TestSpaceBattleAbandon = {}

function TestSpaceBattleAbandon:setUp() H.reset() end

local SWITCHES = {
	{ "another zone", function(sc) return B.THIRD_ZONE end },
	{ "the quest zone again (a respawn)", function(sc) return sc.o.zone end },
}

-- AC-9, I-6
function TestSpaceBattleAbandon:test_a_zone_change_after_setup_but_before_any_arrival_abandons_through_a_deferred_event()
	for _, name in ipairs(B.NAMES) do
		for _, switch in ipairs(SWITCHES) do
			local sc = B.fresh(name):setup()
			local label = name .. " / " .. switch[1]

			H.advance(secs(5))

			local sent = messageCount(sc)

			H.zoneSwitch(sc.player, switch[2](sc))

			lu.assertTrue(sc:active(), label .. ": the quest is still active right after the switch (the observer only defers)")
			lu.assertEquals(messageCount(sc), sent, label .. ": no message inside the observer")
			lu.assertEquals(#sc:waypoints(), 1, label .. ": the waypoint is untouched inside the observer")

			H.advance(0)

			lu.assertFalse(sc:active(), label .. ": no longer active after the 0 ms events")
			lu.assertEquals(B.count(sc:events(), "battle_abandoned", "update"), 1, label .. ": battle_abandoned update sent once")
			assertTornDown(sc, {}, label)
			assertNothingHappensAfterwards(sc, {}, label)
		end
	end
end

-- AC-9, I-6
function TestSpaceBattleAbandon:test_a_zone_change_after_both_forces_arrived_abandons_and_removes_the_ships()
	for _, name in ipairs({ B.WIN, B.LOSE, B.ALLIES_FIRST }) do
		for _, switch in ipairs(SWITCHES) do
			local sc = B.fresh(name):setup()
			local allies, enemies = sc:both()
			local ships = {}
			local label = name .. " / " .. switch[1]

			for _, s in ipairs(allies) do ships[#ships + 1] = s end
			for _, s in ipairs(enemies) do ships[#ships + 1] = s end

			local sent = messageCount(sc)

			H.zoneSwitch(sc.player, switch[2](sc))

			lu.assertTrue(sc:active(), label .. ": still active right after the switch")
			lu.assertEquals(messageCount(sc), sent, label .. ": no message inside the observer")

			H.advance(0)

			lu.assertFalse(sc:active(), label .. ": no longer active")
			lu.assertEquals(B.count(sc:events(), "battle_abandoned", "update"), 1, label .. ": battle_abandoned update sent once")
			lu.assertEquals(B.count(sc:events(), "enemies_win") + B.count(sc:events(), "allies_win"), 0, label .. ": an abandon is not a battle result")
			assertTornDown(sc, ships, label)
			assertNothingHappensAfterwards(sc, ships, label)
		end
	end
end

-- AC-9, Behavior 11: the abandon fails the quest without a client failure message of its own
function TestSpaceBattleAbandon:test_the_abandon_sends_only_the_battle_abandoned_update()
	local sc = B.fresh(B.WIN):setup()

	H.advance(secs(5))

	local sent = messageCount(sc)

	H.zoneSwitch(sc.player, B.THIRD_ZONE)
	H.advance(0)

	lu.assertEquals(#H.messageLog(sc.player) - sent, 1, "the abandon sends exactly one message (failQuest is called with notifyClient false)")

	local abandoned = 0

	for _, to in ipairs(B.updates(sc.player)) do
		if to == "@space/quest:battle_abandoned" then
			abandoned = abandoned + 1
		end
	end

	lu.assertEquals(abandoned, 1, "one battle_abandoned update")
	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "no warpout_failure for an abandon")
end

-- AC-9
function TestSpaceBattleAbandon:test_leaving_a_quest_that_was_never_set_up_changes_nothing()
	local sc = B.fresh(B.WIN, { zone = B.ELSEWHERE })

	sc.quest:startQuest(sc.player, "")
	H.advance(secs(5))
	H.zoneSwitch(sc.player, B.THIRD_ZONE)
	H.advance(secs(5))

	lu.assertTrue(sc:active(), "the quest stays active")
	lu.assertEquals(B.count(sc:events(), "battle_abandoned"), 0, "no abandon message")
end

TestSpaceBattleTeardown = {}

function TestSpaceBattleTeardown:setUp() H.reset() end

local ENDS = {
	{ "completeQuest", function(sc) sc.quest:completeQuest(sc.player, "true") end },
	{ "failQuest", function(sc) sc.quest:failQuest(sc.player, "true") end },
	{ "resetQuest", function(sc) sc.quest:resetQuest(sc.player) end },
}

-- AC-10, I-4
function TestSpaceBattleTeardown:test_complete_fail_and_reset_tear_down_both_forces_and_all_run_state()
	for _, name in ipairs({ B.WIN, B.LOSE, B.ALLIES_FIRST }) do
		for _, finish in ipairs(ENDS) do
			local sc = B.fresh(name):setup()
			local allies, enemies = sc:both()
			local ships = {}
			local label = name .. " / " .. finish[1]

			for _, s in ipairs(allies) do ships[#ships + 1] = s end
			for _, s in ipairs(enemies) do ships[#ships + 1] = s end

			lu.assertEquals(B.strayKeys(sc.player, sc.className), {}, label .. ": while running, every key starts with <playerID>:<className>:")
			lu.assertTrue(#B.runKeys(sc.player, sc.className) > 0, label .. ": precondition, the run has state")

			finish[2](sc)
			H.advance(0)

			assertTornDown(sc, ships, label)
			assertNothingHappensAfterwards(sc, ships, label)
		end
	end
end

-- AC-10
function TestSpaceBattleTeardown:test_ending_the_run_after_a_kill_leaves_the_dead_ship_alone()
	local sc = B.fresh(B.WIN):setup()
	local allies, enemies = sc:both()

	sc:kill(enemies[1])
	sc.quest:failQuest(sc.player, "false")
	H.advance(0)

	local scheduled = {}

	for _, e in ipairs(B.destroyEvents()) do
		scheduled[e.agent] = (scheduled[e.agent] or 0) + 1
	end

	lu.assertNil(scheduled[enemies[1]], "the dead enemy is not scheduled for destruction")

	for i = 2, 6 do
		lu.assertEquals(scheduled[enemies[i]], 1, "live enemy " .. i .. " is scheduled once")
	end

	for i = 1, 4 do
		lu.assertEquals(scheduled[allies[i]], 1, "live ally " .. i .. " is scheduled once")
	end

	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no run key remains")
end

-- AC-10
function TestSpaceBattleTeardown:test_ending_between_the_arrivals_stops_the_second_force_from_ever_spawning()
	for _, name in ipairs(B.NAMES) do
		local sc = B.fresh(name):setup()
		local o = sc.o
		local first = o.allyDelay < o.enemyDelay and sc:allies() or sc:enemies()
		local firstCount = #first

		sc.quest:failQuest(sc.player, "true")
		H.advance(0)

		assertTornDown(sc, first, name)
		assertNothingHappensAfterwards(sc, first, name)
		lu.assertEquals(#spawnCalls(), firstCount, name .. ": only the first force ever spawned")
	end
end

-- AC-10, I-5
function TestSpaceBattleTeardown:test_ending_a_quest_that_was_never_started_or_never_set_up_raises_no_error()
	for _, finish in ipairs(ENDS) do
		local fresh = B.fresh(B.WIN)

		lu.assertTrue(pcall(function() finish[2](fresh) end), finish[1] .. " on a player who never started the quest")
		H.advance(secs(10))

		local waiting = B.fresh(B.WIN, { zone = B.ELSEWHERE })

		waiting.quest:startQuest(waiting.player, "")
		H.advance(secs(2))
		lu.assertTrue(pcall(function() finish[2](waiting) end), finish[1] .. " on a quest that was never set up")
		H.advance(secs(10))

		lu.assertEquals(B.runKeys(waiting.player, waiting.className), {}, finish[1] .. ": no key left for a quest that never set up")
		lu.assertEquals(#spawnCalls(), 0, finish[1] .. ": nothing spawned")
	end
end

-- I-5
function TestSpaceBattleTeardown:test_clean_up_quest_data_takes_the_player_and_is_safe_on_an_empty_run()
	local sc = B.fresh(B.WIN)

	lu.assertTrue(pcall(function() sc.quest:cleanUpQuestData(sc.player) end), "cleanUpQuestData(pPlayer) on a player with no run")
end

TestSpaceBattleStaleEvents = {}

function TestSpaceBattleStaleEvents:setUp() H.reset() end

-- AC-10
function TestSpaceBattleStaleEvents:test_events_of_an_abandoned_run_do_nothing_after_the_quest_is_started_again()
	local sc = B.fresh(B.WIN):setup()
	local o = sc.o

	lu.assertEquals({ o.allyDelay, o.enemyDelay }, { 60, 90 }, "precondition: allies at 60 s, enemies at 90 s")

	local run1Allies = sc:allies()

	-- abandon (a same-zone respawn) and start again right away
	H.zoneSwitch(sc.player, o.zone)
	H.advance(0)
	lu.assertFalse(sc:active(), "precondition: run 1 was abandoned")

	sc:setup() -- run 2 at t = 60 s
	lu.assertEquals(sc.tSetup, secs(60), "run 2 starts at 60 s")

	-- run 1's enemy arrival (90 s) is due now; it must spawn nothing
	sc:at(secs(30))
	lu.assertEquals(#spawnCalls(), #o.allyForce, "at 90 s only run 1's allies exist: its enemy arrival did nothing")
	lu.assertEquals(B.count(sc:events(), "enemies_arrived"), 0, "no enemies_arrived from the stale arrival")

	-- a late kill notification of a run 1 ship changes nothing
	local sent = messageCount(sc)

	sc.quest:notifyBattleShipDestroyed(run1Allies[1], sc.ship)
	H.advance(0)
	lu.assertEquals(messageCount(sc), sent, "a stale kill of a run 1 ship sends nothing")

	-- run 2: one ally force at 120 s, one enemy force at 150 s
	local allies = sc:allies()
	lu.assertEquals(#spawnCalls(), 2 * #o.allyForce, "run 2's allies spawn once at 120 s")

	local enemies = sc:enemies()
	lu.assertEquals(#spawnCalls(), 2 * #o.allyForce + #o.enemyForce, "run 2's enemies spawn once at 150 s: no double spawn anywhere")
	lu.assertEquals(B.count(sc:events(), "battle_started"), 1, "the battle starts once, for run 2")

	-- the stale kill did not count: killing one run 2 ally leaves 3
	sc:kill(allies[1])
	lu.assertEquals(B.dis(sc:events(), "allies_remain"), { 3 }, "run 2's ally count is untouched by the stale kill")

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	H.advance(B.RESOLVE_DELAY)
	lu.assertTrue(sc:complete(), "run 2 resolves and wins")
end

-- AC-10
function TestSpaceBattleStaleEvents:test_an_abandon_before_the_first_arrival_leaves_no_arrival_that_can_spawn()
	local sc = B.fresh(B.WIN):setup()

	H.advance(secs(10))
	H.zoneSwitch(sc.player, B.THIRD_ZONE)
	H.advance(0)

	lu.assertFalse(sc:active(), "abandoned")

	H.advance(secs(3000))

	lu.assertEquals(#spawnCalls(), 0, "no stale arrival spawns anything")
	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "no stale timeout fires")
end

-- AC-10
function TestSpaceBattleStaleEvents:test_a_finished_run_ignores_its_pending_timers_and_a_new_run_gets_new_state()
	local sc = B.fresh(B.ALLIES_FIRST):setup()
	local allies, enemies = sc:both()

	for _, enemy in ipairs(enemies) do
		sc:kill(enemy)
	end

	H.advance(B.RESOLVE_DELAY)
	lu.assertTrue(sc:complete(), "run 1 won")

	H.advance(secs(1600))
	lu.assertEquals(B.count(sc:events(), "warpout_failure"), 0, "run 1's timers did nothing")
	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no key after run 1")
end

TestSpaceBattleSecondVm = {}

function TestSpaceBattleSecondVm:setUp() H.reset() end

-- AC-10
function TestSpaceBattleSecondVm:test_the_battle_starts_and_resolves_when_each_step_runs_in_a_fresh_vm()
	local sc = B.fresh(B.WIN)

	B.resetVm()
	sc:setup()

	B.resetVm()
	local allies = sc:allies()

	B.resetVm()
	local enemies = sc:enemies()

	lu.assertEquals(B.count(sc:events(), "battle_started", "update"), 1, "battle_started once")

	local allyTargets, enemyTargets = B.pairing(allies, enemies)

	for i, a in ipairs(allies) do
		lu.assertEquals(B.targetsOf(a), { allyTargets[i] }, "ally " .. i .. " target")
	end

	for j, e in ipairs(enemies) do
		lu.assertEquals(B.targetsOf(e), { enemyTargets[j] }, "enemy " .. j .. " target")
	end

	for i = 1, 6 do
		B.resetVm()
		sc:kill(enemies[i])
	end

	lu.assertEquals(B.dis(sc:events(), "enemies_remain"), { 5, 4, 3, 2, 1 }, "the count survives a fresh VM before every kill")

	B.resetVm()
	H.advance(B.RESOLVE_DELAY)

	lu.assertTrue(sc:complete(), "the win lands in a fresh VM")
	lu.assertEquals(B.runKeys(sc.player, sc.className), {}, "no key remains")
end

-- AC-10
function TestSpaceBattleSecondVm:test_a_lost_battle_and_a_warp_out_timeout_work_in_a_fresh_vm()
	local lost = B.fresh(B.LOSE)

	B.resetVm()
	lost:setup()

	B.resetVm()
	local allies = lost:both()

	for i = 1, 5 do
		B.resetVm()
		lost:kill(allies[i])
	end

	B.resetVm()
	H.advance(B.RESOLVE_DELAY)
	lu.assertFalse(lost:active(), "the loss lands in a fresh VM")

	local timed = B.fresh(B.ALLIES_FIRST)

	B.resetVm()
	timed:setup()

	B.resetVm()
	timed:at(secs(1520))

	lu.assertEquals(B.count(timed:events(), "warpout_failure"), 1, "the timeout fires in a fresh VM")
	lu.assertFalse(timed:active(), "the timeout failed the quest")
end
