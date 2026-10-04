-- RSF Squadron tier 1 (Dinge): the three quests that could not be played before the data port now run.
--   mission 4 (assassinate naboo_privateer_tier1_4a): the deploy read self.assassinateSpawns, which the table never set;
--   destroy duty 6: a flat shipTypes list and no totalLevels / bossShip;
--   escort duty 7: no creditKillBonus, so the first leg payout after a kill did nil arithmetic.
-- Spec: .claude/work/rsf-tier1-dinge-data/01-spec.md (AC-5, AC-8).
--
-- The oracle values are the spec's literals (rsf_tier1_dinge_data.lua); the quest tables are driven through the harness's fakes,
-- never read for expected values. Each scenario pumps the event clock inside pcall first, so a Lua error inside an event shows up as
-- "no Lua error" and not as a later, unrelated assertion.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local D = require("rsf_tier1_dinge_data")

AC.load()

local function quest(global) return H.expectGlobal(global, "RSF tier 1 Dinge quest table (rsf-tier1-dinge-data)") end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function shipNames(ships)
	local out = {}

	for i, ship in ipairs(ships) do
		out[i] = ship.shipName
	end

	return out
end

local function isComplete(player, q)
	local ghost = CreatureObject(player):getPlayerObject()

	return PlayerObject(ghost):isJournalQuestComplete(H.questCrc(q.questType, q.questName))
end

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

---------------------------------------------------------------------------------------------
-- AC-5: mission 4 runs
---------------------------------------------------------------------------------------------

TestRsfTier1DingeMission4 = {}

function TestRsfTier1DingeMission4:setUp() H.reset() end

function TestRsfTier1DingeMission4:tearDown() AC.tearDown() end

local function startedMission4()
	local q = quest(D.A4)
	local player = AC.started(q)

	pump(2000, D.A4 .. " deployTargets (arrivalDelay 0: runs at startQuest; the 2 s pump covers the first update)")

	return q, player
end

-- AC-5
function TestRsfTier1DingeMission4:test_starting_mission_4_deploys_without_a_lua_error()
	local q = quest(D.A4)
	local player = AC.started(q)

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": precondition: the journal entry is active")
	pump(2000, D.A4 .. " deployTargets")
	pump(5000, D.A4 .. " the events after deployTargets (target location update)")
end

-- AC-5
function TestRsfTier1DingeMission4:test_exactly_four_ships_spawn_the_ace_first_and_three_escorts_in_order()
	local q, player = startedMission4()
	local ships = H.spawnedShips()

	lu.assertEquals(shipNames(ships), { "blacksun_ace_s04_tier1", "blacksun_fighter_s01_tier1", "blacksun_fighter_s02_tier1", "blacksun_bomber_s03_tier1" }, D.A4 .. ": spawned ships, in order")
	lu.assertTrue(ships[1].isSquadronLeader, D.A4 .. ": the target leads the squadron")

	for i = 2, 4 do
		lu.assertEquals(ships[i].squadronLeader, ships[1], D.A4 .. ": escort " .. (i - 1) .. " flies in the target's squadron")
	end

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.missionOwner, player, D.A4 .. ": ship " .. i .. " belongs to the pilot")
		lu.assertEquals(ship.zone, "space_naboo", D.A4 .. ": ship " .. i .. " zone")
	end
end

-- AC-5: the target appears at the first point of its path
function TestRsfTier1DingeMission4:test_the_target_spawns_at_the_first_target_patrol_point()
	startedMission4()

	local target = H.spawnedShips()[1]

	lu.assertNotNil(target, D.A4 .. ": a target ship spawned")
	lu.assertEquals({ target.x, target.z, target.y }, { -2934, 3049, -3022 }, D.A4 .. ": target x, z, y (naboo_imperial_escort_2)")
end

-- AC-5: all four ships follow the four-point path
function TestRsfTier1DingeMission4:test_every_ship_flies_the_four_point_path_in_file_order()
	startedMission4()

	local want = { "naboo_imperial_escort_2", "corellia_imperial_tier3_leg_4_assassinate_one_2", "naboo_imperial_tier2_escortduty_6", "naboo_imperial_tier2_recoveryduty_4" }

	lu.assertEquals(#H.spawnedShips(), 4, D.A4 .. ": number of ships")

	for i, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.patrolPointTables, { want }, D.A4 .. ": ship " .. i .. " (" .. tostring(ship.shipName) .. ") fixed patrol points")
	end
end

-- AC-5
function TestRsfTier1DingeMission4:test_the_quest_completes_when_the_target_and_all_three_escorts_are_destroyed()
	local q, player = startedMission4()
	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 4, D.A4 .. ": precondition: four ships")

	for i = 1, 3 do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, D.A4 .. " after kill " .. i)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": still active after " .. i .. " of 4 kills")
		lu.assertFalse(isComplete(player, q), D.A4 .. ": not complete after " .. i .. " of 4 kills")
	end

	H.destroyShip(ships[4], player.rootParent)
	pump(1500, D.A4 .. " after kill 4")

	lu.assertTrue(isComplete(player, q), D.A4 .. ": complete after all four ships are destroyed")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": no longer active")
end

-- AC-5: the escorts have to die too (mustDestroyEscort 1), not only the ace
function TestRsfTier1DingeMission4:test_killing_only_the_ace_does_not_complete_the_quest()
	local q, player = startedMission4()

	H.destroyShip(H.spawnedShips()[1], player.rootParent)
	pump(3000, D.A4 .. " after the ace is destroyed")

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": still active with three escorts alive")
	lu.assertFalse(isComplete(player, q), D.A4 .. ": not complete with three escorts alive")
end

-- AC-5: failTimer 20 minutes
function TestRsfTier1DingeMission4:test_the_fail_timer_is_twenty_minutes_after_the_deploy()
	local q, player = startedMission4()

	H.advance(20 * 60 * 1000 - 3000)
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": still active just before 20 minutes")

	pump(3000, D.A4 .. " failAssassination")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.A4 .. ": failed after 20 minutes")
end

---------------------------------------------------------------------------------------------
-- AC-8 (a): destroy duty 6
---------------------------------------------------------------------------------------------

TestRsfTier1DingeDestroyDuty6 = {}

function TestRsfTier1DingeDestroyDuty6:setUp() H.reset() end

function TestRsfTier1DingeDestroyDuty6:tearDown() AC.tearDown() end

local function startedDuty6()
	local q = quest(D.DUTY6)
	local player = AC.started(q)
	local key = player.objectID .. ":" .. q.className .. ":targetArea:"
	local area = getSceneObject(readData(key))

	lu.assertNotNil(area, D.DUTY6 .. ": startQuest in the quest zone spawns a target area")

	return q, player, area, key
end

local function dataKey(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

-- AC-8 (a)
function TestRsfTier1DingeDestroyDuty6:test_the_first_attack_wave_is_one_ship_of_the_first_ship_set()
	local q, player, area = startedDuty6()

	H.enterArea(area, player.rootParent)
	pump(4500, D.DUTY6 .. " spawnAttackWave (4 s after entering the area)")

	lu.assertEquals(shipNames(H.spawnedShips()), { "blacksun_fighter_s01_tier1" }, D.DUTY6 .. ": ships of wave 1 of level 1")
	lu.assertEquals(H.spawnedShips()[1].missionOwner, player, D.DUTY6 .. ": the wave ship belongs to the pilot")
end

-- AC-8 (a): a bigger wave draws only names the table lists, never nil or an unknown name
function TestRsfTier1DingeDestroyDuty6:test_a_later_wave_spawns_only_ships_the_table_lists()
	local q, player, area = startedDuty6()
	local known = {}

	for _, set in ipairs(D.expected()[D.DUTY6].shipTypes) do
		for _, name in ipairs(set) do
			known[name] = true
		end
	end

	H.enterArea(area, player.rootParent)
	pump(500, D.DUTY6 .. " entering")
	writeData(dataKey(q, player, "CurrentLevel:"), 1)

	pump(4000, D.DUTY6 .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertEquals(#ships, 2, D.DUTY6 .. ": wave 1 of level 2 has wave + level - 1 = 2 ships")

	for i, ship in ipairs(ships) do
		lu.assertTrue(known[ship.shipName] == true, D.DUTY6 .. ": ship " .. i .. " '" .. tostring(ship.shipName) .. "' is one of the table's ships")
		lu.assertTrue(io.open(H.SCRIPTS .. "ship_mobile/ships/" .. tostring(ship.shipName) .. ".lua", "r") ~= nil, D.DUTY6 .. ": ship " .. i .. " has a ship template")
	end
end

-- AC-8 (a): the boss wave
function TestRsfTier1DingeDestroyDuty6:test_the_boss_wave_spawns_the_marauder_first()
	local q, player, area = startedDuty6()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, D.DUTY6 .. " spawnAttackWave (boss)")

	local ships = H.spawnedShips()

	lu.assertEquals(ships[1] and ships[1].shipName, "blacksun_marauder_tier1", D.DUTY6 .. ": the first ship of the boss wave")
	lu.assertEquals(#ships, 1, D.DUTY6 .. ": the boss squad at level 1 is the boss alone")
	lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[1]), D.DUTY6 .. ": the boss has the boss kill observer")
end

-- AC-8 (a): level 2 brings the boss and one escort
function TestRsfTier1DingeDestroyDuty6:test_the_level_two_boss_squad_is_the_marauder_and_one_fighter_of_the_first_set()
	local q, player, area = startedDuty6()

	writeData(dataKey(q, player, "bossLevel:"), 1)
	writeData(dataKey(q, player, "CurrentLevel:"), 1)
	H.enterArea(area, player.rootParent)
	pump(4500, D.DUTY6 .. " spawnAttackWave (level 2 boss)")

	lu.assertEquals(shipNames(H.spawnedShips()), { "blacksun_marauder_tier1", "blacksun_fighter_s01_tier1" }, D.DUTY6 .. ": level 2 boss squad")
end

-- Kills every ship spawned since the last call, with the pilot's ship as killer; returns how many
local function killNewShips(player, killed)
	local n = 0

	for _, ship in ipairs(H.spawnedShips()) do
		if not killed[ship] and not ship.destroyed then
			killed[ship] = true
			H.destroyShip(ship, player.rootParent)
			n = n + 1
		end
	end

	return n
end

local function currentArea(q, player) return getSceneObject(readData(dataKey(q, player, "targetArea:"))) end

-- Plays one level: rounds of waves until the boss wave spawns (Core3 flies one round more than totalRounds). Returns the boss ship.
local function playLevel(q, player, killed, level)
	local label = D.DUTY6 .. " level " .. level

	for round = 1, q.totalRounds + 3 do
		local area = currentArea(q, player)

		lu.assertNotNil(area, label .. " round " .. round .. ": a target area exists")
		H.enterArea(area, player.rootParent)
		pump(4500, label .. " round " .. round .. " wave 1")

		for _, ship in ipairs(H.spawnedShips()) do
			if not killed[ship] and ship.shipName == q.bossShip then
				return ship
			end
		end

		for wave = 1, q.totalWaves do
			lu.assertTrue(killNewShips(player, killed) > 0, label .. " round " .. round .. " wave " .. wave .. ": ships spawned")
			pump(6000, label .. " round " .. round .. " after wave " .. wave)
		end

		pump(6000, label .. " round " .. round .. " next target")
	end

	return nil
end

-- AC-8 (a): the whole duty, two levels with a boss each, to the completion
function TestRsfTier1DingeDestroyDuty6:test_the_duty_runs_both_levels_with_their_bosses_and_completes_with_pay()
	local q, player = startedDuty6()
	local killed = {}

	lu.assertEquals({ q.totalLevels, q.totalRounds, q.totalWaves }, { 2, 2, 2 }, D.DUTY6 .. ": precondition: levels, rounds, waves")

	local boss1 = playLevel(q, player, killed, 1)

	lu.assertEquals(boss1 and boss1.shipName, "blacksun_marauder_tier1", D.DUTY6 .. ": the level 1 boss")
	killNewShips(player, killed)
	pump(7000, D.DUTY6 .. " after the level 1 boss")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.DUTY6 .. ": the duty goes on to level 2")

	local boss2 = playLevel(q, player, killed, 2)

	lu.assertEquals(boss2 and boss2.shipName, "blacksun_marauder_tier1", D.DUTY6 .. ": the level 2 boss")
	killNewShips(player, killed)
	pump(3000, D.DUTY6 .. " after the level 2 boss")

	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), D.DUTY6 .. ": the duty is over after the level 2 boss")
	lu.assertTrue(isComplete(player, q), D.DUTY6 .. ": completed")
	lu.assertTrue(player.bankCredits > 0, D.DUTY6 .. ": the pilot was paid")
end

---------------------------------------------------------------------------------------------
-- AC-8 (b): escort duty 7
---------------------------------------------------------------------------------------------

TestRsfTier1DingeEscortDuty7 = {}

function TestRsfTier1DingeEscortDuty7:setUp() H.reset() end

function TestRsfTier1DingeEscortDuty7:tearDown() AC.tearDown() end

-- SpaceEscortScreenplay reschedules its attack wave every attackDelay seconds (default 0). A table without an attackDelay would make the
-- event clock loop at one instant forever, so a missing delay is a failure here and not a hang.
local function assertNoZeroDelayLoop()
	lu.assertTrue((quest(D.DUTY7).attackDelay or 0) > 0, D.DUTY7 .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds, 0 by default)")
end

-- A started duty with its escort spawned and its points assigned (progress = number of legs); the escort ship, the pilot
local function runningDuty7()
	assertNoZeroDelayLoop()

	local run = AC.escortRun(D.DUTY7)

	pump(5000, D.DUTY7 .. " assignEscortPoints")

	local q, player, agent = run.q, run.player, run.escortAgent

	lu.assertNotNil(agent, D.DUTY7 .. ": precondition: the escort ship spawned")

	return q, player, agent
end

local function progress(q, agent) return readData(agent.objectID .. ":" .. q.className .. ":escortShipProgress:") end

local function nextArea(q, player)
	for _, area in ipairs(H.spawnedAreas()) do
		if not area.destroyed and readData(area.objectID .. ":" .. q.className) > 0 then
			return area
		end
	end
end

-- Lets the escort reach areas until the progress counter runs out (the final leg pays); returns the area it entered last
local function finishEscort(q, player, agent)
	local last

	for _ = 1, #q.escortPoints + 2 do
		if progress(q, agent) <= 0 and last ~= nil then
			break
		end

		local area = nextArea(q, player)

		lu.assertNotNil(area, D.DUTY7 .. ": an escort area to fly into")
		last = area
		H.enterArea(area, agent)

		if not SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) then
			break
		end
	end

	return last
end

local function payouts(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:escort_reward" then
			out[#out + 1] = m.DI
		end
	end

	return out
end

-- The state a running duty leaves when its escort reaches the last area of the run, built by hand: no event is pumped, so the
-- table's attackDelay has no say. The escort ship is `progress` areas short of the end.
local function escortAtItsLastArea(kills)
	local q = quest(D.DUTY7)
	local player = AC.started(q)
	local agent = spawnShipAgent("freighterheavy_tier2", "space_naboo", 0, 0, 0, player.rootParent)
	local area = spawnSpaceActiveArea("space_naboo", "object/active_area.iff", 0, 0, 0, 250)
	local prefix = q.className

	writeData(agent.objectID .. ":" .. prefix .. ":escorterID:", player.objectID)
	writeData(player.objectID .. ":" .. prefix .. ":escortID:", agent.objectID)
	writeData(agent.objectID .. ":" .. prefix .. ":escortShipProgress:", 1)

	if kills > 0 then
		writeData(player.objectID .. ":" .. prefix .. ":" .. ":EscortKillCount:", kills)
	end

	return q, player, agent, area
end

-- AC-8 (b): Red today: creditKillBonus is nil, so the first payout after a kill is nil arithmetic
function TestRsfTier1DingeEscortDuty7:test_the_payout_after_two_kills_is_2900_and_raises_no_lua_error()
	local q, player, agent, area = escortAtItsLastArea(2)
	local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2900 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500 + 200 x 2 kills)")
	lu.assertEquals(player.bankCredits, 2900, D.DUTY7 .. ": credits added to the bank")
end

-- AC-8 (b)
function TestRsfTier1DingeEscortDuty7:test_the_payout_after_one_kill_is_2700_and_raises_no_lua_error()
	local q, player, agent, area = escortAtItsLastArea(1)
	local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2700 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500 + 200 x 1 kill)")
end

-- AC-8 (b): no kills, the plain reward
function TestRsfTier1DingeEscortDuty7:test_the_payout_without_kills_is_2500()
	local q, player, agent, area = escortAtItsLastArea(0)
	local ok, err = pcall(q.notifyEnteredQuestArea, q, area, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": the leg payout raised a Lua error: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2500 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500, no kills)")
	lu.assertEquals(player.bankCredits, 2500, D.DUTY7 .. ": credits added to the bank")
end

-- AC-8 (b)
function TestRsfTier1DingeEscortDuty7:test_the_escort_is_one_of_the_three_tier_2_freighters()
	local q, player, agent = runningDuty7()

	lu.assertTrue(contains({ "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" }, agent.shipName), D.DUTY7 .. ": escort ship '" .. tostring(agent.shipName) .. "'")
end

-- AC-8 (b): each of the three freighters can be drawn
function TestRsfTier1DingeEscortDuty7:test_each_of_the_three_freighters_can_be_the_escort()
	for pick, want in ipairs({ "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" }) do
		assertNoZeroDelayLoop()

		local q = quest(D.DUTY7)
		local player = AC.started(q) -- resets the harness, so the draw is queued afterwards

		H.Engine.queueRandom(1, 3, pick)
		pump(2500, D.DUTY7 .. " setupEscort")

		local start = readData(player.objectID .. q.className .. ":startPoint:")

		H.enterArea(AC.areaByNumber(q, start), player.rootParent)
		pump(6000, D.DUTY7 .. " spawnEscortShip")

		local agent = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

		lu.assertNotNil(agent, D.DUTY7 .. " draw " .. pick .. ": the escort spawned")
		lu.assertEquals(agent.shipName, want, D.DUTY7 .. ": escort ship for draw " .. pick)
	end
end

-- AC-8 (b): the payout after kills is 2500 + 200 x kills, without a Lua error
function TestRsfTier1DingeEscortDuty7:test_the_leg_payout_after_two_kills_is_2500_plus_200_per_kill()
	local q, player, agent = runningDuty7()

	writeData(player.objectID .. ":" .. q.className .. ":" .. ":EscortKillCount:", 2)

	local ok, err = pcall(finishEscort, q, player, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": a Lua error while the escort reached its last area: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2900 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500 + 200 x 2)")
	lu.assertEquals(player.bankCredits, 2900, D.DUTY7 .. ": credits added to the bank")
end

-- AC-8 (b): one kill
function TestRsfTier1DingeEscortDuty7:test_the_leg_payout_after_one_kill_is_2700()
	local q, player, agent = runningDuty7()

	writeData(player.objectID .. ":" .. q.className .. ":" .. ":EscortKillCount:", 1)

	local ok, err = pcall(finishEscort, q, player, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": a Lua error while the escort reached its last area: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2700 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500 + 200 x 1)")
end

-- AC-8 (b): no kills pay the plain reward
function TestRsfTier1DingeEscortDuty7:test_the_leg_payout_without_kills_is_2500()
	local q, player, agent = runningDuty7()
	local ok, err = pcall(finishEscort, q, player, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": a Lua error while the escort reached its last area: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2500 }, D.DUTY7 .. ": @space/quest:escort_reward DI (2500, no kills)")
	lu.assertEquals(player.bankCredits, 2500, D.DUTY7 .. ": credits added to the bank")
end

-- AC-8 (b): a real kill of an attacker counts
function TestRsfTier1DingeEscortDuty7:test_killing_an_attacking_marauder_counts_towards_the_payout()
	local q, player, agent = runningDuty7()

	pump(90 * 1000, D.DUTY7 .. " spawnAttackWave (attackDelay 90 s)")

	local attackers = {}

	for _, ship in ipairs(H.spawnedShips()) do
		if ship ~= agent and ship.shipName == "blacksun_marauder_tier2" then
			attackers[#attackers + 1] = ship
		end
	end

	lu.assertEquals(#attackers, 2, D.DUTY7 .. ": the attack wave is two marauder_tier2")

	H.destroyShip(attackers[1], player.rootParent)

	local ok, err = pcall(finishEscort, q, player, agent)

	lu.assertTrue(ok, D.DUTY7 .. ": a Lua error while the escort reached its last area: " .. tostring(err))
	lu.assertEquals(payouts(player), { 2700 }, D.DUTY7 .. ": @space/quest:escort_reward DI after one real kill")
end
