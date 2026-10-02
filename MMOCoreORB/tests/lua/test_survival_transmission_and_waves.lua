-- Survival transmission timeline, completion, attack waves and the two-wave cap
-- (space-quest-stub-survival). Spec: .claude/work/space-quest-stub-survival/01-spec.md
-- (AC-5, AC-6, AC-7, Behavior 4 to 6). Expected numbers come from the SWG-Source fixtures through
-- survival_scenario.lua; times below are milliseconds after arrival unless named otherwise.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")

S.load()

local function secs(n) return n * 1000 end

-- The transmission timeline the spec derives from the .tab: list of { t, key, via, DI } relative
-- to arrival, covering transmission_start .. mission_complete.
local function expectedTimeline(o)
	local step = o.total // o.updates
	local out = { { t = secs(o.transStart), key = "transmission_start", via = "message" } }

	for k = 1, o.updates - 1 do
		out[#out + 1] = { t = secs(o.transStart + k * step), key = "trans_update", via = "message", DI = (100 * k * step) // o.total }
	end

	local received = o.transStart + o.updates * step

	out[#out + 1] = { t = secs(received), key = "transmission_received", via = "message" }
	out[#out + 1] = { t = secs(received + 5), key = "mission_complete", via = "update" }

	return out, secs(received + 5)
end

local TIMELINE_KEYS = { transmission_start = true, trans_update = true, transmission_received = true, mission_complete = true }

local function actualTimeline(sc)
	local out = {}

	for _, e in ipairs(sc:events()) do
		if TIMELINE_KEYS[e.key] then
			out[#out + 1] = { t = e.t - sc.t0, key = e.key, via = e.via, DI = e.DI }
		end
	end

	return out
end

TestSurvivalTransmission = {}

function TestSurvivalTransmission:setUp()
	H.reset()
end

-- AC-5
function TestSurvivalTransmission:test_every_quest_follows_the_transmission_timeline_computed_from_its_tab_row()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name):start():arrive()
		local timeline, doneAt = expectedTimeline(sc.o)

		sc:at(doneAt + 1000)

		lu.assertEquals(actualTimeline(sc), timeline, name .. ": transmission timeline (t ms after arrival, key, delivery, DI)")
		lu.assertEquals(S.count(sc:events(), "outofrange"), 0, name .. ": the ship never left, so no range warning")
	end
end

-- AC-5
function TestSurvivalTransmission:test_corellia_rebel_tier4_1_progress_percentages_are_20_40_60_80()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	sc:at(secs(320))

	local updates = S.only(sc:events(), "trans_update", "message")
	local di = {}

	for i, e in ipairs(updates) do
		di[i] = e.DI
	end

	lu.assertEquals(di, { 20, 40, 60, 80 }, "trans_update DI values")
	lu.assertEquals(S.times(sc:events(), "trans_update"), { secs(2 + 70), secs(2 + 130), secs(2 + 190), secs(2 + 250) }, "at 70, 130, 190, 250 s after arrival (arrival was at t = 2 s)")
end

-- AC-5
function TestSurvivalTransmission:test_corellia_rebel_tier4_1_completes_between_314_and_315_seconds()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	sc:at(secs(9) + 999)
	lu.assertEquals(S.count(sc:events(), "transmission_start"), 0, "nothing at 9.999 s")
	sc:at(secs(10))
	lu.assertEquals(S.count(sc:events(), "transmission_start", "message"), 1, "transmission_start at 10 s")

	sc:at(secs(310) - 1)
	lu.assertEquals(S.count(sc:events(), "transmission_received"), 0, "not yet at 309.999 s")
	sc:at(secs(310))
	lu.assertEquals(S.count(sc:events(), "transmission_received", "message"), 1, "transmission_received at 310 s")

	sc:at(secs(314))
	lu.assertTrue(sc:active(), "quest still active at 314 s")
	lu.assertFalse(sc:complete(), "not complete at 314 s")
	lu.assertEquals(S.count(sc:events(), "mission_complete"), 0, "no mission_complete yet")

	sc:at(secs(315))
	lu.assertEquals(S.count(sc:events(), "mission_complete", "update"), 1, "mission_complete update by 315 s")
	lu.assertTrue(sc:taskComplete(2), "task 2 complete")
	lu.assertTrue(sc:complete(), "journal quest complete")
	lu.assertFalse(sc:active(), "no longer active")
end

-- AC-5
function TestSurvivalTransmission:test_corellia_rebel_tier4_1_completion_starts_the_battle_split()
	local sc = S.fresh("corellia_rebel_tier4_1"):start():arrive()

	sc:at(secs(315))
	H.advance(secs(10))

	lu.assertEquals(S.called(sc.spies.start), { "space_battle_corellia_rebel_tier4_1_a" }, "completion split starts battle 1_a only")
	lu.assertEquals(S.called(sc.spies.fail), {}, "no failure split")
end

-- AC-5
function TestSurvivalTransmission:test_completing_through_the_transmission_runs_the_existing_complete_quest_split_for_every_quest()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name):start():arrive()
		local _, doneAt = expectedTimeline(sc.o)
		local q = sc.quest
		local SPLIT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

		sc:at(doneAt)
		H.advance(secs(10))

		lu.assertTrue(sc:complete(), name .. ": complete")

		if q.sideQuest and (q.sideQuestSplitType == SPLIT.COMPLETION or q.sideQuestSplitType == SPLIT.BIDIRECTIONAL) then
			lu.assertEquals(S.called(sc.spies.start), { q.sideQuestType .. "_" .. q.sideQuestName }, name .. ": completion split")
		else
			lu.assertEquals(S.called(sc.spies.start), {}, name .. ": no follow-up quest")
		end
	end
end

-- AC-5
function TestSurvivalTransmission:test_the_transmission_does_not_start_before_arrival()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()

	H.advance(secs(400))

	lu.assertEquals(#S.only(sc:events(), "transmission_start"), 0)
	lu.assertEquals(#S.spawns(), 0, "and no attack ships either")
end

-- AC-5 (arrival at a non-zero time keeps the timeline relative to arrival)
function TestSurvivalTransmission:test_a_late_arrival_shifts_the_whole_timeline()
	local sc = S.fresh("corellia_rebel_tier4_1"):start()

	H.advance(secs(500))
	sc:arrive()
	sc:at(secs(320))

	local timeline = expectedTimeline(sc.o)

	lu.assertEquals(actualTimeline(sc), timeline, "timeline relative to a late arrival")
end

TestSurvivalWaves = {}

function TestSurvivalWaves:setUp()
	H.reset()
end

-- Checks everything a launched wave must have, against the scenario's list `list`.
local function assertWave(sc, wave, list, label)
	local o = sc.o
	local player = sc.player

	lu.assertEquals(S.names(wave), list, label .. ": ship names in list order")

	local usedRange = false

	for _, call in ipairs(sc.ship.spawnPointCalls) do
		if call[1] == 1000 and call[2] == 1200 then
			usedRange = true
		end
	end

	lu.assertTrue(usedRange, label .. ": spawn point asked for 1000 to 1200 m in front of the player's ship")

	local front = sc.ship:getSpawnPointInFrontOfShip(1000, 1200) -- deterministic fake; asked after the check above

	for i, s in ipairs(wave.spawns) do
		local agent = wave.agents[i]
		local ship = label .. " ship " .. i .. " (" .. s.name .. ")"

		lu.assertEquals(s.zone, o.zone, ship .. ": spawn zone")
		lu.assertEquals(s.target, sc.ship, ship .. ": spawnShipAgent target is the player's ship (faces the player)")
		lu.assertTrue(math.abs(s.x - front[1]) <= 150, ship .. ": x within 150 of the spawn point")
		lu.assertTrue(math.abs(s.y - front[3]) <= 150, ship .. ": y within 150 of the spawn point")
		lu.assertEquals(s.z, front[2], ship .. ": z (height) is not spread")

		lu.assertEquals(agent.missionOwner, player, ship .. ": mission owner")
		lu.assertEquals(agent.factionEnemies, { sc.ship:getShipFactionHash() }, ship .. ": enemy of the player's ship faction")
		lu.assertEquals(agent.engaged, { sc.ship }, ship .. ": engages the player's ship")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), ship .. ": SHIPDESTROYED observer")
	end

	-- mission objects: every id once, in order, only the last one flagged
	local log = player.missionObjectLog
	local tail = {}

	for i = #wave.agents, 1, -1 do
		tail[i] = log[#log - (#wave.agents - i)]
	end

	for i, agent in ipairs(wave.agents) do
		local entry = tail[i]

		lu.assertNotNil(entry, label .. " ship " .. i .. ": addSpaceMissionObject call")
		lu.assertEquals(entry.id, agent.objectID, label .. " ship " .. i .. ": mission object id")
		lu.assertEquals(entry.last and true or false, i == #wave.agents, label .. " ship " .. i .. ": 'last' flag only on the final ship")
	end

	-- squadron: only lists of 4 or more
	if #list >= 4 then
		lu.assertTrue(wave.agents[1].isSquadronLeader, label .. ": first ship creates the squadron")
		lu.assertNil(wave.agents[1].squadronLeader, label .. ": the leader is not assigned to itself")

		for i = 2, #list do
			lu.assertEquals(wave.agents[i].squadronLeader, wave.agents[1], label .. " ship " .. i .. ": assigned to the first ship's squadron")
			lu.assertFalse(wave.agents[i].isSquadronLeader, label .. " ship " .. i .. ": not a second leader")
		end
	else
		for i = 1, #list do
			lu.assertFalse(wave.agents[i].isSquadronLeader, label .. " ship " .. i .. ": no squadron for a list under 4")
			lu.assertNil(wave.agents[i].squadronLeader, label .. " ship " .. i .. ": no squadron for a list under 4")
		end
	end
end

local function destroyAll(wave, killer)
	for _, agent in ipairs(wave.agents) do
		H.destroyShip(agent, killer)
	end
end

-- AC-6
function TestSurvivalWaves:test_first_attack_update_then_first_launch_five_seconds_later_for_every_quest()
	for _, name in ipairs(S.NAMES) do
		local sc = S.fresh(name):start():arrive()
		local o = sc.o

		sc:at(secs(o.firstAttack) - 1)
		lu.assertEquals(S.count(sc:events(), "first_attack"), 0, name .. ": no first_attack before " .. o.firstAttack .. " s")
		lu.assertEquals(#S.spawns(), 0, name .. ": no ships before the first attack")

		sc:at(secs(o.firstAttack))
		lu.assertEquals(S.times(sc:events(), "first_attack", "update"), { sc.t0 + secs(o.firstAttack) }, name .. ": first_attack update at delayToFirstAttack")
		lu.assertEquals(#S.spawns(), 0, name .. ": ships come 5 s after the announcement")

		sc:at(secs(o.firstAttack + 5) - 1)
		lu.assertEquals(#S.spawns(), 0, name .. ": still no ships 1 ms before the launch")

		sc:at(secs(o.firstAttack + 5))

		local waves = S.waves()

		lu.assertEquals(#waves, 1, name .. ": one wave launched")
		assertWave(sc, waves[1], o.lists[1], name .. " wave 1")
	end
end

-- AC-6
function TestSurvivalWaves:test_sequential_quest_cycles_through_its_lists_every_attack_period()
	local sc = S.fresh("corellia_rebel_tier3_2_b"):start():arrive()
	local o = sc.o
	local launches = { 10, 110, 210, 310, 410, 510 }
	local order = { 1, 2, 3, 4, 5, 1 }

	lu.assertEquals(o.period, 100, "fixture attackPeriod")

	sc:at(secs(5) - 1)
	lu.assertEquals(S.count(sc:events(), "first_attack"), 0, "no first_attack at 4.999 s")
	sc:at(secs(5))
	lu.assertEquals(S.times(sc:events(), "first_attack", "update"), { sc.t0 + secs(5) }, "first_attack at 5 s")

	for i, t in ipairs(launches) do
		sc:at(secs(t) - 1)
		lu.assertEquals(#S.waves(), i - 1, "wave " .. i .. ": not launched 1 ms early")

		sc:at(secs(t))

		local waves = S.waves()

		lu.assertEquals(#waves, i, "wave " .. i .. ": launched at " .. t .. " s")
		lu.assertEquals(waves[i].t, sc.t0 + secs(t), "wave " .. i .. ": launch time")
		assertWave(sc, waves[i], o.lists[order[i]], "wave " .. i .. " (list " .. order[i] .. ")")
		lu.assertEquals(S.times(sc:events(), "attack_notify", "message")[i], sc.t0 + secs(t), "wave " .. i .. ": attack_notify message")
		lu.assertEquals(S.count(sc:events(), "attack_notify"), i, "wave " .. i .. ": exactly one attack_notify per launch")
		lu.assertEquals(S.effects(sc.player, S.SPAWN_EFFECT), i, "wave " .. i .. ": one ui_quest_spawn_wave effect per launch")

		destroyAll(waves[i], sc.ship)
	end

	lu.assertTrue(sc:active(), "killing every wave never completes or fails the quest")
	lu.assertFalse(sc:complete(), "not complete")
end

-- AC-6
function TestSurvivalWaves:test_random_quest_launches_the_list_the_random_number_picks()
	for pick = 1, 4 do
		local sc = S.fresh("corellia_rebel_tier4_1")

		H.Engine.nextRandom = pick
		sc:start():arrive()
		sc:at(secs(10))

		local waves = S.waves()

		lu.assertEquals(#waves, 1, "pick " .. pick .. ": first wave launched")
		assertWave(sc, waves[1], sc.o.lists[pick], "random pick " .. pick)

		destroyAll(waves[1], sc.ship)
		sc:at(secs(70))

		waves = S.waves()
		lu.assertEquals(#waves, 2, "pick " .. pick .. ": second wave launched after attackPeriod 60 s")
		lu.assertEquals(S.names(waves[2]), sc.o.lists[pick], "pick " .. pick .. ": the same pick gives the same list again")
	end
end

-- AC-6
function TestSurvivalWaves:test_random_quest_spawns_ships_in_the_picked_list_order_with_a_squadron()
	local sc = S.fresh("corellia_rebel_tier4_1")

	H.Engine.nextRandom = 3
	sc:start():arrive()
	sc:at(secs(10))

	lu.assertEquals(S.names(S.waves()[1]), {
		"blacksun_fighter_s03_tier4", "blacksun_fighter_s03_tier4", "blacksun_marauder_tier4", "blacksun_fighter_s03_tier4",
	}, "list 3 of corellia_rebel_tier4_1 (spec Attack lists)")
end

-- AC-6
function TestSurvivalWaves:test_a_player_ship_far_from_the_point_still_gets_waves_in_front_of_the_ship()
	local sc = S.fresh("corellia_rebel_tier3_2_b"):start():arrive()

	-- 1500 m away, in range of the 2000 m limit
	sc:placeShip(1500, 0, 0)
	sc:at(secs(10))

	local wave = S.waves()[1]
	local front = sc.ship:getSpawnPointInFrontOfShip(1000, 1200)

	lu.assertNotNil(wave, "wave launched")
	lu.assertTrue(math.abs(wave.spawns[1].x - front[1]) <= 150, "spawn is relative to the ship, not to the transmission point")
end

TestSurvivalWaveCap = {}

function TestSurvivalWaveCap:setUp()
	H.reset()
end

-- Starts corellia_rebel_tier3_2_b (3-ship lists 1 and 2, then 3, 4, 5; period 100 s; first launch
-- at 10 s) and arrives. Nothing is killed by the helper.
local function arrived2b()
	return S.fresh("corellia_rebel_tier3_2_b"):start():arrive()
end

-- AC-7
function TestSurvivalWaveCap:test_with_two_live_waves_the_next_period_spawns_nothing()
	local sc = arrived2b()

	sc:at(secs(110))
	lu.assertEquals(#S.waves(), 2, "two waves launched")
	local ships = #S.spawns()

	sc:at(secs(210))
	lu.assertEquals(#S.spawns(), ships, "no ship at 210 s: two waves are still alive")
	lu.assertEquals(S.count(sc:events(), "attack_notify"), 2, "no attack_notify for the blocked launch")
	lu.assertEquals(S.effects(sc.player, S.SPAWN_EFFECT), 2, "no spawn effect for the blocked launch")

	sc:at(secs(599))
	lu.assertEquals(#S.spawns(), ships, "and nothing at all until the transmission ends: the blocked launch does not reschedule itself")
	lu.assertTrue(sc:active(), "the quest is not failed by the cap")
end

-- AC-7
function TestSurvivalWaveCap:test_killing_one_whole_wave_launches_the_pending_wave_at_once_and_periods_restart_from_then()
	local sc = arrived2b()

	sc:at(secs(110))

	local waves = S.waves()
	local first, second = waves[1], waves[2]

	sc:at(secs(350))
	lu.assertEquals(#S.waves(), 2, "still two waves, a launch is pending")

	-- partial kill of the first wave does not free a slot
	H.destroyShip(first.agents[1], sc.ship)
	H.destroyShip(first.agents[2], sc.ship)
	H.advance(0)
	lu.assertEquals(#S.waves(), 2, "two of three ships down: the wave is still alive")

	-- last ship of the first wave: the pending launch happens now (list 3)
	H.destroyShip(first.agents[3], sc.ship)
	H.advance(0)

	waves = S.waves()
	lu.assertEquals(#waves, 3, "the pending wave launched")
	lu.assertEquals(waves[3].t, sc.t0 + secs(350), "immediately, at the time of the kill")
	assertWave(sc, waves[3], sc.o.lists[3], "the pending wave is list 3 (the blocked launches did not consume lists)")

	-- kill the second wave: nothing is pending, nothing spawns
	destroyAll(second, sc.ship)
	H.advance(0)
	sc:at(secs(449))
	lu.assertEquals(#S.waves(), 3, "no spawn between the kill and one period after the immediate launch (no polling timer survived)")

	sc:at(secs(450))
	waves = S.waves()
	lu.assertEquals(#waves, 4, "launches resume one attackPeriod after the immediate launch")
	lu.assertEquals(waves[4].t, sc.t0 + secs(450), "at 450 s")
	assertWave(sc, waves[4], sc.o.lists[4], "wave 4 (list 4, four ships, forms a squadron)")
end

-- AC-7, R-2: the SHIPDESTROYED handler runs while ShipManager holds the destroyed ship's lock;
-- spawning and engaging from inside it can deadlock against a thread hitting that ship
function TestSurvivalWaveCap:test_the_pending_launch_is_deferred_out_of_the_destroyed_ship_handler()
	local sc = arrived2b()

	sc:at(secs(350))

	local first = S.waves()[1]

	for i = 1, #first.agents - 1 do
		H.destroyShip(first.agents[i], sc.ship)
	end

	local spawnsBefore = #S.spawns()
	local engagesBefore = 0

	for _, agent in ipairs(H.spawnedShips()) do
		engagesBefore = engagesBefore + #agent.engaged
	end

	H.destroyShip(first.agents[#first.agents], sc.ship)

	lu.assertEquals(#S.spawns(), spawnsBefore, "no ship is spawned inside the SHIPDESTROYED handler")

	local engagesNow = 0

	for _, agent in ipairs(H.spawnedShips()) do
		engagesNow = engagesNow + #agent.engaged
	end

	lu.assertEquals(engagesNow, engagesBefore, "no ship is told to engage inside the handler either")

	H.advance(0)

	lu.assertEquals(#S.waves(), 3, "the pending wave launches from a zero-delay event")
	lu.assertEquals(S.waves()[3].t, sc.t0 + secs(350), "at the same time as the kill")
end

-- AC-7
function TestSurvivalWaveCap:test_killing_a_wave_when_no_launch_is_pending_spawns_nothing()
	local sc = arrived2b()

	sc:at(secs(10))
	destroyAll(S.waves()[1], sc.ship)
	H.advance(0)
	sc:at(secs(109))

	lu.assertEquals(#S.waves(), 1, "no extra wave after a kill")

	sc:at(secs(110))
	lu.assertEquals(#S.waves(), 2, "the periodic launch still happens on time")
	lu.assertEquals(S.names(S.waves()[2]), sc.o.lists[2], "and uses the next list")
end

-- AC-7
function TestSurvivalWaveCap:test_attack_stopped_is_sent_once_when_the_last_live_ship_of_the_run_dies()
	local sc = arrived2b()

	sc:at(secs(110))

	local waves = S.waves()

	-- first wave dies completely: the second is still alive
	destroyAll(waves[1], sc.ship)
	lu.assertEquals(S.count(sc:events(), "attack_stopped"), 0, "ships of the second wave are alive")
	lu.assertEquals(S.effects(sc.player, S.DESTROYED_EFFECT), 0, "no destroyed-wave effect yet")

	-- the pending-free kill of the first wave did not launch anything (no launch was pending)
	-- second wave: two of three die
	H.destroyShip(waves[2].agents[1], sc.ship)
	H.destroyShip(waves[2].agents[3], sc.ship)
	lu.assertEquals(S.count(sc:events(), "attack_stopped"), 0, "one ship is still alive")

	H.destroyShip(waves[2].agents[2], sc.ship)

	lu.assertEquals(S.count(sc:events(), "attack_stopped", "message"), 1, "attack_stopped message once")
	lu.assertEquals(S.effects(sc.player, S.DESTROYED_EFFECT), 1, "one ui_quest_destroyed_wave effect")
	lu.assertTrue(sc:active(), "killing every attacker does not complete the quest")
	lu.assertFalse(sc:complete(), "not complete")

	-- the next periodic wave launches normally and can be cleared again
	sc:at(secs(210))
	lu.assertEquals(#S.waves(), 3, "wave 3 at 210 s")
	destroyAll(S.waves()[3], sc.ship)
	lu.assertEquals(S.count(sc:events(), "attack_stopped"), 2, "a second attack_stopped for the new wave")
	lu.assertEquals(S.effects(sc.player, S.DESTROYED_EFFECT), 2, "and a second effect")
end

-- AC-7
function TestSurvivalWaveCap:test_destroyed_attack_ships_are_removed_from_the_players_mission_objects()
	local sc = arrived2b()

	sc:at(secs(10))

	local wave = S.waves()[1]
	local id = wave.agents[1].objectID

	H.destroyShip(wave.agents[1], sc.ship)

	for _, listed in ipairs(sc.player.missionObjects) do
		lu.assertNotEquals(listed, id, "the destroyed ship is no longer a mission object")
	end

	lu.assertEquals(#sc.player.missionObjects, 2, "the other two ships still are")

	local notified
	for _, r in ipairs(sc.player.removedMissionObjectLog) do
		if r.id == id then
			notified = r.notify
		end
	end

	lu.assertEquals(notified, true, "the client is told when a killed ship stops being a mission object (DutyDestroy parity)")
end

-- AC-7
function TestSurvivalWaveCap:test_killing_ships_in_any_order_never_fails_the_quest()
	local sc = arrived2b()

	sc:at(secs(110))

	local waves = S.waves()

	H.destroyShip(waves[2].agents[3], nil)
	H.destroyShip(waves[1].agents[2], sc.ship)
	H.destroyShip(waves[2].agents[1], sc.ship)
	H.destroyShip(waves[1].agents[1], nil)
	H.destroyShip(waves[2].agents[2], sc.ship)
	H.destroyShip(waves[1].agents[3], sc.ship)
	H.advance(secs(1))

	lu.assertTrue(sc:active(), "quest active after every attacker died")
	lu.assertEquals(S.called(sc.spies.fail), {}, "no failure was propagated")
	lu.assertEquals(S.count(sc:events(), "attack_stopped"), 1, "attack_stopped once")
end
