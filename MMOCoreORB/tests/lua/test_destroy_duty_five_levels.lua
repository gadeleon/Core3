-- Destroy duties run five levels (SWG destroy_duty.java:61 hard-codes levelsPerDuty = 5), whatever the .tab column says.
-- Core3's pay and round count stay: round end = creditReward x kills, commander of level 1-4 = 9 x creditReward,
-- level-5 commander = one 75 x creditReward completion bonus, totalRounds + 1 rounds per level.
-- Spec: .claude/work/space-destroy-duty-five-levels/01-spec.md (AC-1 .. AC-9, I-1 .. I-5)
-- AC-8 (re-take after completion) lives in test_duty_rules_retake.lua (superseded test updated to levelsPerDuty - 1).

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local CS = require("harness.client_strings")

H.boot()
H.loadSpaceQuestTypes()

local SQUADRONS = { "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "InquisitionSquadronScreenplay",
	"CrimsonPhoenixSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "VortexSquadronScreenplay", "SmugglerSquadronScreenplay",
	"StormSquadronScreenplay" }

for _, name in ipairs(SQUADRONS) do
	H.loadSquadron(name)
end

local SPACE_QUEST = "@space/quest:"

local function dutyGlobals()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		if rawget(_G, name).questType == "destroy_duty" then
			out[#out + 1] = name
		end
	end

	return out
end

local DUTIES = dutyGlobals()

local function prefix(q) return "@spacequest/destroy_duty/" .. q.questName .. ":" end

local function keyOf(q, player, name) return player.objectID .. ":" .. q.className .. ":" .. name end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	if not ok then
		lu.fail(label .. ": " .. tostring(err))
	end
end

local function isComplete(player, q)
	local ghost = CreatureObject(player):getPlayerObject()

	return PlayerObject(ghost):isJournalQuestComplete(H.questCrc(q.questType, q.questName))
end

local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

-- A started duty in its zone with its first target area
local function started(global)
	local q = H.expectGlobal(global, "destroy duty quest table")
	local player = AC.started(q)
	local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

	lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")

	return q, player, area
end

local function eventCount(method)
	local n = 0

	for _, ev in ipairs(H.pendingEvents()) do
		if ev.method == method then
			n = n + 1
		end
	end

	return n
end

-- Messages of the duty flow only, as comparable tokens: "<id>", "<id> DI=<n>", "<id> TO=<id>"
local function token(q, msg)
	local id = msg.id
	local p = prefix(q)
	local shown = id == SPACE_QUEST .. "destroy_duty_boss_dead" or id == SPACE_QUEST .. "destroy_duty_boss_reward"
		or id == SPACE_QUEST .. "destroy_duty_complete_reward" or id == SPACE_QUEST .. "destroy_duty_round_reward"
		or id == SPACE_QUEST .. "destroy_duty_level_boss_dead" or id == p .. "duty_update" or id == p .. "complete"
		or id == p .. "level_boss" or id == p .. "level_increase"

	if not shown then
		return nil
	end

	local out = id

	if msg.DI ~= nil then out = out .. " DI=" .. tostring(msg.DI) end
	if msg.TO ~= nil then out = out .. " TO=" .. tostring(msg.TO) end

	return out
end

local function tokensSince(q, player, mark)
	local log = H.messageLog(player)
	local out = {}

	for i = mark + 1, #log do
		local t = token(q, log[i])

		if t then
			out[#out + 1] = t
		end
	end

	return out
end

local function dutyUpdate(q, id) return prefix(q) .. "duty_update TO=" .. prefix(q) .. id end

-- The commander kill, the way the quest sets it up (test_duty_rules_retake.lua): a mission-owned agent that is the only
-- attack ship left, CurrentLevel seeded to `level0`, the commander kill observer. Returns the commander.
local function commander(q, player, level0)
	local boss = spawnShipAgent(q.bossShip, q.questZone, 0, 0, 0)

	ShipAiAgent(boss):setMissionOwner(player)
	writeStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:", { SceneObject(boss):getObjectID() })
	writeData(keyOf(q, player, "CurrentLevel:"), level0)
	createObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", boss)

	return boss
end

-- Kills the commander at CurrentLevel level0; returns the tokens, the bank delta, the getTargetLocation events queued by the kill
local function commanderKill(global, level0)
	local q, player = started(global)
	local boss = commander(q, player, level0)
	local mark, bank, events = #H.messageLog(player), player.bankCredits, eventCount("getTargetLocation")

	H.destroyShip(boss, player.rootParent)

	return q, player, tokensSince(q, player, mark), player.bankCredits - bank, eventCount("getTargetLocation") - events, mark
end

local function each(fn)
	local problems = {}

	for _, global in ipairs(DUTIES) do
		local ok, result = pcall(fn, global)

		if not ok then
			problems[#problems + 1] = global .. ": raised " .. tostring(result)
		elseif result ~= nil then
			problems[#problems + 1] = global .. ": " .. result
		end
	end

	return problems
end

TestDestroyDutyFiveLevels = {}

function TestDestroyDutyFiveLevels:setUp() H.reset() end

function TestDestroyDutyFiveLevels:tearDown() AC.tearDown() end

---------------------------------------------------------------------------------------------
-- AC-1
---------------------------------------------------------------------------------------------

-- AC-1
function TestDestroyDutyFiveLevels:test_there_are_31_destroy_duties()
	lu.assertEquals(#DUTIES, 31, "destroy duty globals over the nine squadrons")
end

-- AC-1 (I-1)
function TestDestroyDutyFiveLevels:test_the_base_duty_runs_five_levels_and_no_table_overrides_it()
	local base = H.expectGlobal("SpaceDutyDestroyScreenplay", "destroy duty quest type")

	lu.assertEquals(base.levelsPerDuty, 5, "SpaceDutyDestroyScreenplay.levelsPerDuty (destroy_duty.java:61)")

	local problems = {}

	for _, global in ipairs(DUTIES) do
		local q = rawget(_G, global)

		lu.assertEquals(q.levelsPerDuty, 5, global .. ": levelsPerDuty (inherited)")

		if rawget(q, "levelsPerDuty") ~= nil then
			problems[#problems + 1] = global .. " defines its own levelsPerDuty"
		end
	end

	lu.assertEquals(problems, {}, "tables that override levelsPerDuty")
end

-- AC-1: the .tab column is still mirrored into totalLevels (no effect on the flow)
function TestDestroyDutyFiveLevels:test_total_levels_still_mirrors_the_tab_column()
	for _, global in ipairs(DUTIES) do
		local q = rawget(_G, global)
		local rec = H.questFixture("destroy_duty", q.questName)

		lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), global .. ": totalLevels vs .tab levelsPerDuty")
	end
end

-- AC-1: the 31 fixtures are present, one per duty
function TestDestroyDutyFiveLevels:test_every_duty_has_its_swg_tab_fixture()
	for _, global in ipairs(DUTIES) do
		local q = rawget(_G, global)
		local rec = H.questFixture("destroy_duty", q.questName)

		lu.assertNotNil(rec, global .. ": fixture")
		lu.assertEquals(rec:num("wavesPerRound"), q.totalWaves, global .. ": wavesPerRound vs totalWaves")
		lu.assertEquals(rec:num("roundsPerLevel"), q.totalRounds, global .. ": roundsPerLevel vs totalRounds")
		lu.assertEquals(rec:num("reward"), q.creditReward, global .. ": reward vs creditReward")
	end
end

-- AC-1 (contract 2): the flow no longer reads totalLevels
function TestDestroyDutyFiveLevels:test_the_flow_does_not_read_total_levels()
	local path = H.SCRIPTS .. "screenplays/space/SpaceDutyDestroyScreenplay.lua"
	local f = assert(io.open(path, "r"))
	local lines = {}

	for line in f:lines() do
		if line:find("totalLevels", 1, true) and not line:match("^%s*totalLevels%s*=") and not line:match("^%s*%-%-") then
			lines[#lines + 1] = line
		end
	end

	f:close()

	lu.assertEquals(lines, {}, "SpaceDutyDestroyScreenplay.lua lines that read totalLevels (only its field declaration and comments may name it)")
end

---------------------------------------------------------------------------------------------
-- AC-2 .. AC-5: the commander kills
---------------------------------------------------------------------------------------------

-- AC-2 (I-2)
function TestDestroyDutyFiveLevels:test_a_commander_of_level_one_to_four_keeps_every_duty_active_and_advances_the_level()
	local problems = each(function(global)
		for level = 1, 4 do
			local q, player, _, _, events = commanderKill(global, level - 1)

			if not isActive(player, q) then return "level " .. level .. ": the duty ended after the commander" end
			if isComplete(player, q) then return "level " .. level .. ": the journal entry is complete" end
			if readData(keyOf(q, player, "CurrentLevel:")) ~= level then
				return "level " .. level .. ": CurrentLevel reads " .. tostring(readData(keyOf(q, player, "CurrentLevel:")))
			end
			if events ~= 1 then return "level " .. level .. ": " .. events .. " getTargetLocation events queued, expected 1" end
		end
	end)

	lu.assertEquals(problems, {}, "duties that did not go on after a level 1-4 commander")
end

-- AC-3 (I-2)
function TestDestroyDutyFiveLevels:test_the_level_five_commander_completes_every_duty()
	local problems = each(function(global)
		local q, player, _, _, events = commanderKill(global, 4)

		if isActive(player, q) then return "still active after the level 5 commander" end
		if not isComplete(player, q) then return "journal entry not complete" end
		if events ~= 0 then return events .. " getTargetLocation events queued after completion" end
		local area = readData(keyOf(q, player, "targetArea:"))
		if area ~= nil and area ~= 0 then return "target area key still set" end
		if #player.ghost.waypoints ~= 0 then return "waypoint left" end
	end)

	lu.assertEquals(problems, {}, "duties that did not complete at the level 5 commander")
end

-- AC-3: the 8-level tables
function TestDestroyDutyFiveLevels:test_the_eight_level_tables_complete_at_level_five()
	for _, global in ipairs({ "destroy_duty_naboo_imperial_tier4_1", "destroy_duty_corellia_imperial_tier4_1" }) do
		local q = H.expectGlobal(global, "destroy duty quest table")

		lu.assertEquals(q.totalLevels, 8, global .. ": precondition: the .tab says 8 levels")

		local _, player = commanderKill(global, 4)

		lu.assertTrue(isComplete(player, q), global .. ": complete after the level 5 commander")
	end
end

-- AC-4 (I-3)
function TestDestroyDutyFiveLevels:test_a_level_one_to_four_commander_sends_boss_dead_then_the_nine_fold_bonus_then_the_duty_update()
	local problems = each(function(global)
		for level = 1, 4 do
			local q, player, tokens, bank, _, mark = commanderKill(global, level - 1)
			local pay = 9 * q.creditReward
			local expected = {
				SPACE_QUEST .. "destroy_duty_boss_dead",
				SPACE_QUEST .. "destroy_duty_boss_reward DI=" .. pay,
				dutyUpdate(q, "level_boss_dead"),
			}

			if bank ~= pay then return "level " .. level .. ": bank rose by " .. bank .. ", expected " .. pay end

			local got = table.concat(tokens, " | ")
			local want = table.concat(expected, " | ")

			if got ~= want then return "level " .. level .. ": messages [" .. got .. "], expected [" .. want .. "]" end

			pump(10000, global .. " level " .. level .. " after the commander")

			got = table.concat(tokensSince(q, player, mark), " | ")

			if got:find(SPACE_QUEST .. "destroy_duty_level_boss_dead", 1, true) then
				return "level " .. level .. ": the global @space/quest:destroy_duty_level_boss_dead was sent: [" .. got .. "]"
			end
		end
	end)

	lu.assertEquals(problems, {}, "duties with a wrong level 1-4 commander payout or messages")
end

-- AC-5 (I-3)
function TestDestroyDutyFiveLevels:test_the_level_five_commander_sends_boss_dead_then_complete_then_one_75_fold_bonus()
	local problems = each(function(global)
		local q, player, tokens, bank, _, mark = commanderKill(global, 4)
		local pay = 75 * q.creditReward
		local expected = {
			SPACE_QUEST .. "destroy_duty_boss_dead",
			dutyUpdate(q, "complete"),
			SPACE_QUEST .. "destroy_duty_complete_reward DI=" .. pay,
		}

		if bank ~= pay then return "bank rose by " .. bank .. ", expected " .. pay end

		local got, want = table.concat(tokens, " | "), table.concat(expected, " | ")

		if got ~= want then return "messages [" .. got .. "], expected [" .. want .. "]" end

		pump(10000, global .. " after the level 5 commander")

		tokens = tokensSince(q, player, mark)
		got = table.concat(tokens, " | ")

		if got ~= want then return "after 10 s the messages are [" .. got .. "], expected [" .. want .. "] (once each, no boss_reward, no bare complete)" end
		if player.bankCredits ~= pay then return "after 10 s the bank is " .. player.bankCredits .. ", expected " .. pay end
	end)

	lu.assertEquals(problems, {}, "duties with a wrong completion payout or messages")
end

---------------------------------------------------------------------------------------------
-- AC-7: round ends
---------------------------------------------------------------------------------------------

-- Spawns wave 1 in the area, seeds the state so that the wave about to die is the last of the round, kills it.
-- Returns the tokens, the bank delta, the ships killed and the player
local function roundEnd(global, round, level0)
	local q, player, area = started(global)

	writeData(keyOf(q, player, "CurrentLevel:"), level0)
	H.enterArea(area, player.rootParent)
	pump(4500, global .. " spawnAttackWave")

	local ships = H.spawnedShips()

	lu.assertTrue(#ships > 0, global .. ": the first wave spawned")

	writeData(keyOf(q, player, "CurrentWave:"), q.totalWaves)
	writeData(keyOf(q, player, "CurrentRound:"), round)
	writeData(keyOf(q, player, "DestroyKillCount:"), 0)

	local mark, bank, n = #H.messageLog(player), player.bankCredits, 0

	for _, ship in ipairs(ships) do
		if not ship.destroyed then
			n = n + 1
			H.destroyShip(ship, player.rootParent)
		end
	end

	return q, player, tokensSince(q, player, mark), player.bankCredits - bank, n
end

-- AC-7
function TestDestroyDutyFiveLevels:test_a_mid_level_round_end_pays_the_round_and_sends_level_increase()
	local problems = each(function(global)
		local q0 = rawget(_G, global)

		for _, round in ipairs({ 0, q0.totalRounds - 1 }) do
			local q, player, tokens, bank, n = roundEnd(global, round, 0)
			local pay = q.creditReward * n
			local expected = {
				SPACE_QUEST .. "destroy_duty_round_reward DI=" .. pay,
				dutyUpdate(q, "level_increase"),
			}
			local got, want = table.concat(tokens, " | "), table.concat(expected, " | ")

			if got ~= want then return "CurrentRound " .. round .. ": messages [" .. got .. "], expected [" .. want .. "]" end
			if bank ~= pay then return "CurrentRound " .. round .. ": bank rose by " .. bank .. ", expected " .. pay end
		end
	end)

	lu.assertEquals(problems, {}, "duties with a wrong mid-level round end")
end

-- AC-7
function TestDestroyDutyFiveLevels:test_the_last_round_of_a_level_pays_the_round_and_announces_the_commander_without_level_increase()
	local problems = each(function(global)
		local q0 = rawget(_G, global)

		for _, level0 in ipairs({ 0, 4 }) do
			local q, player, tokens, bank, n = roundEnd(global, q0.totalRounds, level0)
			local pay = q.creditReward * n
			local expected = {
				SPACE_QUEST .. "destroy_duty_round_reward DI=" .. pay,
				prefix(q) .. "level_boss TO=" .. prefix(q) .. "boss_title_" .. (level0 + 1),
			}
			local got, want = table.concat(tokens, " | "), table.concat(expected, " | ")

			if got ~= want then return "CurrentLevel " .. level0 .. ": messages [" .. got .. "], expected [" .. want .. "]" end
			if bank ~= pay then return "CurrentLevel " .. level0 .. ": bank rose by " .. bank .. ", expected " .. pay end
			if readData(keyOf(q, player, "bossLevel:")) ~= 1 then return "CurrentLevel " .. level0 .. ": bossLevel is not 1" end
		end
	end)

	lu.assertEquals(problems, {}, "duties with a wrong last-round end")
end

---------------------------------------------------------------------------------------------
-- AC-6: the whole duty
---------------------------------------------------------------------------------------------

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

local function newShips(killed)
	local out = {}

	for _, ship in ipairs(H.spawnedShips()) do
		if not killed[ship] and not ship.destroyed then
			out[#out + 1] = ship
		end
	end

	return out
end

local function hasCommander(q, ships)
	for _, ship in ipairs(ships) do
		if H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ship) then
			return true
		end
	end

	return false
end

-- Flies the whole duty; returns { commanders = n, rounds = { per level }, kills = total wave kills, player, problem = string | nil }
local function flyDuty(global)
	local q, player = started(global)
	local killed = {}
	local run = { commanders = 0, rounds = {}, kills = 0, player = player, q = q }

	for level = 1, 8 do
		local rounds = 0
		local ended = false

		for _ = 1, q.totalRounds + 3 do
			local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

			if area == nil then
				run.problem = "level " .. level .. ": no target area"
				return run
			end

			H.enterArea(area, player.rootParent)
			pump(4500, global .. " level " .. level .. " wave 1")

			if hasCommander(q, newShips(killed)) then
				run.commanders = run.commanders + 1
				killNewShips(player, killed)
				pump(7000, global .. " after the level " .. level .. " commander")
				ended = true
				break
			end

			rounds = rounds + 1

			for wave = 1, q.totalWaves do
				local n = killNewShips(player, killed)

				if n == 0 then
					run.problem = "level " .. level .. " round " .. rounds .. " wave " .. wave .. ": no ships spawned"
					return run
				end

				run.kills = run.kills + n
				pump(6000, global .. " level " .. level .. " after wave " .. wave)
			end

			pump(6000, global .. " level " .. level .. " next target")
		end

		run.rounds[level] = rounds

		if not ended then
			run.problem = "level " .. level .. ": no commander after " .. rounds .. " rounds"
			return run
		end

		if not isActive(player, q) then
			break
		end
	end

	return run
end

local function expectedPay(q)
	local W, R = q.totalWaves, q.totalRounds
	local K = 15 * W + 5 * W * (W - 1) / 2

	return q.creditReward * ((R + 1) * K + 111)
end

-- AC-6 (I-4): one test per duty, so a failure names it
for _, global in ipairs(DUTIES) do
	TestDestroyDutyFiveLevels["test_the_whole_duty_" .. global .. "_runs_five_levels_and_pays_the_perfect_run_total"] = function()
		local run = flyDuty(global)
		local q, player = run.q, run.player

		lu.assertNil(run.problem, global .. ": the run")
		lu.assertEquals(run.commanders, 5, global .. ": commander wings")
		lu.assertEquals(run.rounds, { q.totalRounds + 1, q.totalRounds + 1, q.totalRounds + 1, q.totalRounds + 1, q.totalRounds + 1 },
			global .. ": non-commander rounds per level (totalRounds + 1)")
		lu.assertFalse(isActive(player, q), global .. ": not active after the fifth commander")
		lu.assertTrue(isComplete(player, q), global .. ": complete after the fifth commander")
		lu.assertEquals(player.bankCredits, expectedPay(q), global .. ": bank after a perfect run")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: every string id resolves in the pre-CU client
---------------------------------------------------------------------------------------------

-- AC-9 (I-5)
function TestDestroyDutyFiveLevels:test_every_string_id_the_duty_flow_sends_resolves_in_the_client()
	local problems = each(function(global)
		local q0 = rawget(_G, global)
		local seen = {}
		local logs = {}

		local function collect(player)
			for _, msg in ipairs(H.messageLog(player)) do
				logs[#logs + 1] = msg
			end
		end

		for _, level0 in ipairs({ 0, 4 }) do
			local _, p = commanderKill(global, level0)
			collect(p)
		end

		for _, round in ipairs({ 0, q0.totalRounds }) do
			local _, p = roundEnd(global, round, 4)
			collect(p)
		end

		local own = CS.sids("spacequest/destroy_duty/" .. q0.questName)
		local global_ids = CS.sids("space/quest")

		if own == nil then return "no client fixture for spacequest/destroy_duty/" .. q0.questName end
		if global_ids == nil then return "no client fixture for space/quest" end

		local function check(str)
			local file, id = tostring(str):match("^@([%w_/]+):([%w_]+)$")

			if file and not seen[str] then
				seen[str] = true

				local set = (file == "space/quest") and global_ids or CS.sids(file)

				if set == nil or not set[id] then
					return str
				end
			end
		end

		local missing = {}

		for _, msg in ipairs(logs) do
			for _, str in ipairs({ msg.id, msg.TO or "" }) do
				local bad = check(str)

				if bad then
					missing[#missing + 1] = bad
				end
			end
		end

		if #missing > 0 then
			table.sort(missing)
			return "ids the client lacks: " .. table.concat(missing, ", ")
		end
	end)

	lu.assertEquals(problems, {}, "duties that send a string id the pre-CU client lacks")
end

-- AC-9: the 31 client fixtures exist and hold the five commander titles
function TestDestroyDutyFiveLevels:test_every_duty_has_five_commander_titles_in_the_client()
	for _, global in ipairs(DUTIES) do
		local q = rawget(_G, global)
		local ids = CS.sids("spacequest/destroy_duty/" .. q.questName)

		lu.assertNotNil(ids, global .. ": client fixture")

		for level = 1, 5 do
			lu.assertTrue(ids["boss_title_" .. level] == true, global .. ": boss_title_" .. level)
		end

		for _, id in ipairs({ "duty_update", "level_increase", "level_boss_dead", "complete" }) do
			lu.assertTrue(ids[id] == true, global .. ": " .. id)
		end

		lu.assertNil(ids["boss_title_6"], global .. ": the client has no boss_title_6")
	end
end

