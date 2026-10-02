-- Rescue attack waves aimed at the rescued ship (space-quest-rescue-docking).
-- Spec: .claude/work/space-quest-rescue-docking/01-spec.md (AC-7, Behavior 8, Content contract: hook
-- overrides). The wave rules are the shared SpaceAttackWaves mixin's; these tests pin what rescue changes:
-- the anchor is the target ship, waves run only in the escort stage, and the panic and thanks taunts.
-- Times are milliseconds. Expected lists and periods come from the SWG-Source fixtures.

local lu = require("luaunit")
local H = require("harness")
local R = require("rescue_scenario")

R.load()

local function secs(n) return n * 1000 end

local REP = R.REP  -- period 50, RANDOM, 3 lists of 6, 5 responses
local RSF = R.RSF  -- period 110, SEQUENTIAL, 4 lists of 3, 3 responses

local ATTACK_NOTIFY = "attack_notify"
local ATTACK_STOPPED = "attack_stopped"

local function launchTimes(sc)
	local out = {}

	for i, w in ipairs(R.attackWaves(sc)) do
		out[i] = w.t
	end

	return out
end

TestRescueWavesAimedAtTheTarget = {}

function TestRescueWavesAimedAtTheTarget:setUp() H.reset() end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_no_attack_ship_spawns_before_the_escort_stage()
	for _, name in ipairs(R.NAMES) do
		local waiting = R.fresh(name):toWaiting()

		H.advance(secs(600))
		lu.assertEquals(#waiting:attackSpawns(), 0, name .. ": no attack ship in 600 s while the target waits to be docked")

		local docked = R.fresh(name):toDocked()

		docked:atDock(secs(9))
		lu.assertEquals(#docked:attackSpawns(), 0, name .. ": no attack ship between the dock and the escort start")
	end
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_the_first_wave_comes_one_period_after_the_escort_start_from_the_random_list()
	local sc = R.fresh(REP):toEscort()

	H.Engine.nextRandom = 2

	sc:atEscort(secs(sc.o.period) - 1)
	lu.assertEquals(#sc:attackSpawns(), 0, "no wave one ms early")

	sc:atEscort(secs(sc.o.period))

	local waves = sc:attackWaves()

	lu.assertEquals(#waves, 1, "one wave")
	lu.assertEquals(waves[1].t, sc.tEscort + secs(50), "launched 50 s after the escort start")
	lu.assertEquals(R.names(waves[1]), sc.o.lists[2], "list 2 (getRandomNumber returned 2), 6 ships")
	lu.assertEquals(#waves[1].agents, 6, "six ships")
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_every_wave_ship_spawns_ahead_of_the_target_and_engages_it_not_the_player()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()

	H.Engine.nextRandom = 2
	sc:atEscort(secs(50))

	local wave = R.wave(sc, 1)

	lu.assertEquals(t.spawnPointCalls, { { 1000, 1200 } }, "getSpawnPointInFrontOfShip(1000, 1200) was asked of the target")
	lu.assertEquals(sc.ship.spawnPointCalls, {}, "the player's ship was not asked for a spawn point")

	for i, s in ipairs(wave.spawns) do
		local agent = wave.agents[i]

		lu.assertEquals(s.target, t, "ship " .. i .. ": spawnShipAgent's last argument is the rescue target")
		lu.assertEquals(s.zone, sc.o.zone, "ship " .. i .. ": zone")
		lu.assertTrue(math.abs(s.x - (t.x + 1000)) <= 150, "ship " .. i .. ": x within 150 of the point ahead of the target, got " .. s.x)
		lu.assertEquals(s.z, t.z + 7, "ship " .. i .. ": z is the spawn point's")
		lu.assertTrue(math.abs(s.y - (t.y + 1200)) <= 150, "ship " .. i .. ": y within 150 of the point ahead of the target, got " .. s.y)
		lu.assertEquals(agent.engaged, { t }, "ship " .. i .. ": engages the rescue target and nothing else")
		lu.assertEquals(agent.factionEnemies, { sc.ship.factionHash }, "ship " .. i .. ": enemy of the player's faction")
		lu.assertEquals(agent.missionOwner, sc.player, "ship " .. i .. ": mission owner is the player")
		lu.assertTrue(H.hasObserver(SHIPDESTROYED, sc.className, "notifyAttackShipDestroyed", agent), "ship " .. i .. ": SHIPDESTROYED observer")
	end
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_a_wave_of_six_forms_one_squadron()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(50))

	local agents = R.wave(sc, 1).agents
	local leaders = {}

	for _, a in ipairs(agents) do
		if a.isSquadronLeader then
			leaders[#leaders + 1] = a
		end
	end

	lu.assertEquals(#leaders, 1, "one squadron leader")

	for i, a in ipairs(agents) do
		if a ~= leaders[1] then
			lu.assertEquals(a.squadronLeader, leaders[1], "ship " .. i .. " is assigned to the leader")
		end
	end
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_the_player_is_notified_and_the_target_panics_with_a_numbered_phrase()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()

	H.Engine.nextRandom = 2
	sc:atEscort(secs(50))

	lu.assertEquals(R.count(sc:events(), ATTACK_NOTIFY, "message"), 1, "attack_notify once")
	lu.assertEquals(R.effects(sc.player, R.WAVE_EFFECT), 1, "ui_quest_spawn_wave.cef once")
	lu.assertEquals(R.tauntTimes(sc:taunts(), "panic_2"), { sc.tEscort + secs(50) }, "panic_2 taunt at the launch (the same nextRandom)")

	for _, e in ipairs(sc:taunts()) do
		if e.key == "panic_2" then
			lu.assertEquals(e.ship, t, "the panic taunt comes from the rescue target")
		end
	end
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_the_panic_phrase_number_is_in_the_range_one_to_num_responses()
	local sc = R.fresh(RSF):toEscort()

	sc:atEscort(secs(110))
	lu.assertEquals(R.tauntTimes(sc:taunts(), "panic_1"), { sc.tEscort + secs(110) }, "with the minimum random, panic_1")

	H.reset()
	sc = R.fresh(RSF):toEscort()
	H.Engine.nextRandom = 3
	sc:atEscort(secs(110))
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "panic_3"), 1, "with the maximum random for 3 responses, panic_3")
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_each_kill_reports_the_ships_left_and_the_last_one_ends_the_wave_with_a_thanks_taunt()
	local sc = R.fresh(REP):toEscort()
	local t = sc:target()

	H.Engine.nextRandom = 2
	sc:atEscort(secs(50))

	local wave = R.wave(sc, 1)

	for i = 1, 5 do
		H.destroyShip(wave.agents[i], sc.ship)
	end

	local remaining = {}

	for _, e in ipairs(sc:events()) do
		if e.key == "targets_remaining" then
			remaining[#remaining + 1] = e.DI
		end
	end

	lu.assertEquals(remaining, { 5, 4, 3, 2, 1 }, "destroy_duty_targets_remaining with DI = ships still alive")
	lu.assertEquals(R.count(sc:events(), ATTACK_STOPPED, "message"), 0, "no attack_stopped while a ship lives")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "thanks_2"), 0, "no thanks while a ship lives")

	H.destroyShip(wave.agents[6], sc.ship)

	lu.assertEquals(R.count(sc:events(), ATTACK_STOPPED, "message"), 1, "attack_stopped after the last kill")
	lu.assertEquals(R.effects(sc.player, "clienteffect/ui_quest_destroyed_wave.cef"), 1, "ui_quest_destroyed_wave.cef once")

	local thanks = R.tauntTimes(sc:taunts(), "thanks_2")

	lu.assertEquals(#thanks, 1, "thanks_2 taunt (getRandomNumber returned 2)")

	for _, e in ipairs(sc:taunts()) do
		if e.key == "thanks_2" then
			lu.assertEquals(e.ship, t, "the thanks taunt comes from the rescue target")
		end
	end
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_kills_never_complete_or_fail_the_quest_and_waves_keep_coming()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(50))
	R.killWave(sc, R.wave(sc, 1))
	sc:atEscort(secs(100))
	R.killWave(sc, R.wave(sc, 2))
	sc:atEscort(secs(150))

	lu.assertEquals(#sc:attackWaves(), 3, "a third wave launched")
	lu.assertTrue(sc:active(), "still active")
	lu.assertFalse(sc:complete(), "not complete")
	lu.assertEquals(R.count(sc:events(), "failed_destroy"), 0, "no failure message")
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_with_two_live_waves_the_next_period_spawns_nothing_until_one_is_cleared()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(100))
	lu.assertEquals(#sc:attackWaves(), 2, "two live waves at 100 s")

	sc:atEscort(secs(150))
	lu.assertEquals(#sc:attackWaves(), 2, "the cap holds the third wave at 150 s")

	R.killWave(sc, R.wave(sc, 1))
	H.advance(0)

	local waves = sc:attackWaves()

	lu.assertEquals(#waves, 3, "the held wave launched after the first was cleared")
	lu.assertEquals(waves[3].t, sc.tEscort + secs(150), "at the time of the last kill")
	lu.assertEquals(R.count(sc:events(), ATTACK_STOPPED, "message"), 0, "no attack_stopped, the held wave took over")
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_sequential_lists_launch_every_period_in_turn_and_wrap_around()
	local sc = R.fresh(RSF):toEscort()
	local o = sc.o

	for i = 1, 5 do
		sc:atEscort(secs(o.period * i) - 1)
		lu.assertEquals(#sc:attackWaves(), i - 1, "no wave " .. i .. " one ms early")

		sc:atEscort(secs(o.period * i))

		local waves = sc:attackWaves()

		lu.assertEquals(#waves, i, "wave " .. i .. " launched")
		lu.assertEquals(R.names(waves[i]), o.lists[(i - 1) % 4 + 1], "wave " .. i .. " ship list (sequential, wrapping after 4 lists)")

		R.killWave(sc, waves[i])
	end

	lu.assertEquals(launchTimes(sc), { sc.tEscort + secs(110), sc.tEscort + secs(220), sc.tEscort + secs(330), sc.tEscort + secs(440), sc.tEscort + secs(550) },
		"launch times 110, 220, 330, 440, 550 s after the escort start")
	lu.assertEquals(R.count(sc:events(), ATTACK_NOTIFY, "message"), 5, "attack_notify once per wave")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "panic_1"), 5, "a panic taunt per wave")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "thanks_1"), 5, "a thanks taunt per cleared wave")
end

-- AC-7
function TestRescueWavesAimedAtTheTarget:test_a_wave_of_three_does_not_form_a_squadron()
	local sc = R.fresh(RSF):toEscort()

	sc:atEscort(secs(110))

	for i, a in ipairs(R.wave(sc, 1).agents) do
		lu.assertFalse(a.isSquadronLeader, "ship " .. i .. ": three ships do not form a squadron")
		lu.assertNil(a.squadronLeader, "ship " .. i .. ": not assigned to a leader")
	end
end

-- Behavior 8: the anchor
function TestRescueWavesAimedAtTheTarget:test_the_wave_anchor_is_the_target_only_in_the_escort_stage()
	local sc = R.fresh(REP):toWaiting()
	local t = sc:target()

	lu.assertNil(sc.quest:getWaveAnchor(sc.player), "stage DOCK: no anchor")

	sc:dock(t)
	lu.assertNil(sc.quest:getWaveAnchor(sc.player), "stage DOCKED: no anchor")

	sc:escort()
	lu.assertEquals(sc.quest:getWaveAnchor(sc.player), t, "stage ESCORT: the rescue target")

	sc:arrive()
	H.advance(0)
	lu.assertNil(sc.quest:getWaveAnchor(sc.player), "stage ARRIVED: no anchor")
end

-- Behavior 8: a wave that comes due in the 3 s between arrival and completion spawns nothing
function TestRescueWavesAimedAtTheTarget:test_a_wave_due_between_arrival_and_completion_spawns_nothing()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(49))
	sc:arrive()
	H.advance(secs(2))

	lu.assertEquals(#sc:attackSpawns(), 0, "the wave due at escort + 50 s found no anchor")
	lu.assertEquals(#R.tauntTimes(sc:taunts(), "panic_1"), 0, "and no panic taunt")

	H.advance(secs(2))

	lu.assertTrue(sc:complete(), "the quest completed")
	lu.assertEquals(#sc:attackSpawns(), 0, "still no attack ship")
end

-- Behavior 8 / AC-9: no wave outlives the quest
function TestRescueWavesAimedAtTheTarget:test_no_wave_launches_after_the_quest_completes()
	local sc = R.fresh(REP):toEscort()

	sc:atEscort(secs(50))

	local wave = R.wave(sc, 1)

	sc:atEscort(secs(70))
	sc:arrive()
	H.advance(secs(5))
	lu.assertTrue(sc:complete(), "precondition: completed")

	local launches = #sc:attackWaves()

	H.advance(secs(3600))

	lu.assertEquals(#sc:attackWaves(), launches, "no wave after completion")

	for i, agent in ipairs(wave.agents) do
		lu.assertTrue(agent.destroyed or #R.destroyEvents(agent) == 1, "attack ship " .. i .. " is removed by the cleanup")
	end
end
