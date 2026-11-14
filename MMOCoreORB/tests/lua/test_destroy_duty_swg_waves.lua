-- Destroy duties follow SWG for the commander wing (L commanders at level L), the commander taunts, the wave ship rows (by round)
-- and leaving the quest zone (the duty ends as won, without pay). Builds on space-destroy-duty-five-levels (pay and rounds unchanged).
-- Spec: .claude/work/space-destroy-duty-swg-waves/01-spec.md (AC-1 .. AC-10, I-1 .. I-6)
-- The nine "level two boss squad" tests of the squadron runtime files were rewritten for AC-3 (see 02-test-plan.md).

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
local VICTORY_MUSIC = "sound/music_themequest_victory_rebel.snd"
local FAIL_MUSIC = "sound/music_themequest_fail_criminal.snd"

local DUTIES = {}

for _, name in ipairs(H.questGlobals()) do
	if rawget(_G, name).questType == "destroy_duty" then
		DUTIES[#DUTIES + 1] = name
	end
end

---------------------------------------------------------------------------------------------
-- Helpers (the first block mirrors test_destroy_duty_five_levels.lua, which keeps its own copies)
---------------------------------------------------------------------------------------------

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

local function started(global, opts)
	local q = H.expectGlobal(global, "destroy duty quest table")
	local player = AC.started(q, opts)
	local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

	if not (opts and opts.zone) then
		lu.assertNotNil(area, global .. ": startQuest in the quest zone spawns a target area")
	end

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

-- "<id>", "<id> DI=<n>", "<id> TO=<id>" of one logged message
local function tokenOf(msg)
	local out = msg.id or ("plain:" .. tostring(msg.plain))

	if msg.DI ~= nil then out = out .. " DI=" .. tostring(msg.DI) end
	if msg.TO ~= nil then out = out .. " TO=" .. tostring(msg.TO) end

	return out
end

local function tokensSince(player, mark)
	local log = H.messageLog(player)
	local out = {}

	for i = mark + 1, #log do
		out[#out + 1] = tokenOf(log[i])
	end

	return out
end

local function joined(list) return table.concat(list, " | ") end

local function dataGone(key)
	local v = readData(key)

	return v == nil or v == 0
end

-- The five-levels commander kill setup: a mission-owned agent that is the only attack ship left, CurrentLevel seeded to `level0`
local function commander(q, player, level0)
	local boss = spawnShipAgent(q.bossShip, q.questZone, 0, 0, 0)

	ShipAiAgent(boss):setMissionOwner(player)
	writeStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:", { SceneObject(boss):getObjectID() })
	writeData(keyOf(q, player, "CurrentLevel:"), level0)
	createObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", boss)

	return boss
end

-- Spawns wave 1 in the area, seeds the state so that the wave about to die is the last of the round, kills it (five-levels roundEnd)
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

	for _, ship in ipairs(ships) do
		if not ship.destroyed then
			H.destroyShip(ship, player.rootParent)
		end
	end

	return q, player
end

local function needMethod(q, name)
	lu.assertEquals(type(q[name]), "function", q.className .. ": expected SpaceDutyDestroyScreenplay:" .. name .. " to exist (spec Content contract)")
end

-- Seeds the level-L commander wing, enters the area and steps the clock until the wing is there.
-- Returns q, player, the ships, the time they appeared (within 100 ms)
local function spawnWing(global, L, opts)
	local q, player, area = started(global, opts)

	writeData(keyOf(q, player, "CurrentLevel:"), L - 1)
	writeData(keyOf(q, player, "bossLevel:"), 1)
	H.enterArea(area, player.rootParent)

	local t0

	for _ = 1, 60 do
		pump(100, global .. " commander wing L=" .. L)

		if #H.spawnedShips() > 0 then
			t0 = H.now()
			break
		end
	end

	return q, player, H.spawnedShips(), t0
end

local function bossTaunts(player)
	local out = {}

	for _, t in ipairs(H.tauntLog(player)) do
		if tostring(t.msg):find("dd_boss_taunt_", 1, true) then
			out[#out + 1] = t
		end
	end

	return out
end

local function attackShipIDs(q, player)
	local out = {}

	for _, id in ipairs(readStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:")) do
		out[#out + 1] = tonumber(id)
	end

	return out
end

local function contains(list, v)
	for _, x in ipairs(list) do
		if x == v then return true end
	end

	return false
end

TestDestroyDutySwgWaves = {}

function TestDestroyDutySwgWaves:setUp() H.reset() end

function TestDestroyDutySwgWaves:tearDown() AC.tearDown() end

---------------------------------------------------------------------------------------------
-- AC-1: shipTypes equal the .tab columns (I-1)
---------------------------------------------------------------------------------------------

-- AC-1
function TestDestroyDutySwgWaves:test_every_duty_ship_table_equals_its_tab_columns()
	lu.assertEquals(#DUTIES, 31, "destroy duty globals over the nine squadrons")

	local problems = each(function(global)
		local q = rawget(_G, global)
		local rec = H.questFixture("destroy_duty", q.questName)

		if #q.shipTypes ~= rec:num("shipTypes") then
			return "shipTypes has " .. #q.shipTypes .. " columns, the .tab says " .. rec:num("shipTypes")
		end

		for k = 1, rec:num("shipTypes") do
			local want, got = rec:list("shipType" .. k), q.shipTypes[k]

			if joined(got) ~= joined(want) then
				return "column " .. k .. " is [" .. joined(got) .. "], the .tab has [" .. joined(want) .. "]"
			end
		end
	end)

	lu.assertEquals(problems, {}, "duties whose shipTypes differ from the .tab")
end

-- AC-1: the three corrected tables, literally (Content contract 8)
function TestDestroyDutySwgWaves:test_the_three_corrected_ship_tables_are_the_swg_columns()
	local cases = {
		destroy_duty_corellia_privateer_6 = { { "hidden_daggers_enforcer_tier1", "hidden_daggers_eliminator_tier1" } },
		destroy_duty_viopa_rebel_6 = {
			{ "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_fighter_tier2" },
			{ "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2" },
			{ "imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2" },
		},
		destroy_duty_corellia_rebel_tier4_1 = {
			{ "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4" },
			{ "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_vehement_tier4" },
		},
	}

	for global, want in pairs(cases) do
		local q = H.expectGlobal(global, "destroy duty quest table")

		lu.assertEquals(q.shipTypes, want, global .. ": shipTypes")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: wave ship types (I-2)
---------------------------------------------------------------------------------------------

-- The name SWG's rule gives ship i (1-based) of a wave in round r (0-based within the level), computed from the .tab, not from the Lua table
local function oracleName(rec, i, round)
	local n = rec:num("shipTypes")
	local col = rec:list("shipType" .. (((i - 1) % n) + 1))
	local row = round % #rec:list("shipType1")

	return col[(row % #col) + 1]
end

-- Flies level 1 completely (rounds 0..totalRounds, every ship killed) and round 0 of level 2.
-- Returns rec[level][round][wave] = { ship names in spawn order }, and a problem string when the flight went wrong
local function recordWaves(global)
	local q, player = started(global)
	local killed = {}
	local rec = { {}, {} }

	for level = 1, 2 do
		local round = 0

		for _ = 1, q.totalRounds + 3 do
			local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

			if area == nil then
				return rec, "level " .. level .. ": no target area"
			end

			H.enterArea(area, player.rootParent)
			pump(4500, global .. " level " .. level .. " wave 1")

			if hasCommander(q, newShips(killed)) then
				killNewShips(player, killed)
				pump(7000, global .. " after the level " .. level .. " commander")

				break
			end

			rec[level][round] = {}

			for wave = 1, q.totalWaves do
				local names = {}

				for _, ship in ipairs(newShips(killed)) do
					names[#names + 1] = ship.shipName
				end

				rec[level][round][wave] = names

				if killNewShips(player, killed) == 0 then
					return rec, "level " .. level .. " round " .. round .. " wave " .. wave .. ": no ships spawned"
				end

				pump(6000, global .. " level " .. level .. " after wave " .. wave)
			end

			pump(6000, global .. " level " .. level .. " next target")

			round = round + 1

			if level == 2 then
				return rec
			end
		end
	end

	return rec
end

local function mismatchesAgainstOracle(global)
	local q = rawget(_G, global)
	local rec = H.questFixture("destroy_duty", q.questName)
	local waves, problem = recordWaves(global)

	if problem then
		return problem
	end

	local checks = 0

	for level = 1, 2 do
		for round, perWave in pairs(waves[level]) do
			for wave, names in ipairs(perWave) do
				local want = {}

				for i = 1, wave + (level - 1) do
					want[i] = oracleName(rec, i, round)
				end

				checks = checks + 1

				if joined(names) ~= joined(want) then
					return "level " .. level .. " round " .. round .. " wave " .. wave .. ": ships [" .. joined(names) .. "], SWG rule gives [" .. joined(want) .. "]"
				end
			end
		end
	end

	if #waves[1] ~= q.totalRounds or waves[2][0] == nil then
		return "flight recorded " .. (#waves[1] + 1) .. " rounds of level 1 and " .. tostring(waves[2][0] ~= nil) .. " for level 2 round 0"
	end

	return nil
end

-- AC-2 (I-2): one test per duty
for _, global in ipairs(DUTIES) do
	TestDestroyDutySwgWaves["test_the_wave_ships_of_" .. global .. "_follow_the_round_row_and_ship_column_rule"] = function()
		local problem = mismatchesAgainstOracle(global)

		lu.assertNil(problem, global .. ": wave ship types (I-2)")
	end
end

-- AC-2: corellia_privateer_6, the extra round wraps (D-12)
function TestDestroyDutySwgWaves:test_corellia_privateer_6_rounds_fly_enforcer_then_eliminator_then_enforcer()
	local waves, problem = recordWaves("destroy_duty_corellia_privateer_6")

	lu.assertNil(problem, "flight")

	local expectRows = { [0] = "hidden_daggers_enforcer_tier1", [1] = "hidden_daggers_eliminator_tier1", [2] = "hidden_daggers_enforcer_tier1" }

	for round = 0, 2 do
		for wave, names in ipairs(waves[1][round]) do
			for i, name in ipairs(names) do
				lu.assertEquals(name, expectRows[round], "corellia_privateer_6 level 1 round " .. round .. " wave " .. wave .. " ship " .. i)
			end
		end
	end

	lu.assertEquals(waves[2][0][1][1], "hidden_daggers_enforcer_tier1", "corellia_privateer_6 level 2 round 0 uses row 0 again")
end

-- AC-2: viopa_rebel_6, the interceptor leads round 2 (1-based)
function TestDestroyDutySwgWaves:test_viopa_rebel_6_round_two_waves_lead_with_a_tie_interceptor()
	local waves, problem = recordWaves("destroy_duty_viopa_rebel_6")

	lu.assertNil(problem, "flight")

	local fighter, interceptor = "imp_tie_fighter_tier2", "imp_tie_interceptor_tier2"

	for wave, names in ipairs(waves[1][0]) do
		for i, name in ipairs(names) do
			lu.assertEquals(name, fighter, "viopa_rebel_6 round 1 wave " .. wave .. " ship " .. i .. " (row 0 is all fighters)")
		end
	end

	lu.assertEquals(waves[1][1][1], { interceptor }, "viopa_rebel_6 round 2 wave 1")
	lu.assertEquals(waves[1][1][3], { interceptor, fighter, fighter }, "viopa_rebel_6 round 2 wave 3")
end

-- AC-2: corellia_privateer_9, the third round (index 2) wraps per column (D-4)
function TestDestroyDutySwgWaves:test_corellia_privateer_9_third_round_ship_two_wraps_to_the_first_row_of_its_column()
	local q = H.expectGlobal("destroy_duty_corellia_privateer_9", "destroy duty quest table")
	local rec = H.questFixture("destroy_duty", q.questName)
	local waves, problem = recordWaves("destroy_duty_corellia_privateer_9")

	lu.assertNil(problem, "flight")

	local col2 = rec:list("shipType2")

	lu.assertEquals(waves[1][2][2][2], col2[(2 % #col2) + 1], "corellia_privateer_9 round 3 wave 2 ship 2")
end

---------------------------------------------------------------------------------------------
-- AC-3: the commander wing (I-3)
---------------------------------------------------------------------------------------------

local function wingProblem(global, L)
	local q, player, ships = spawnWing(global, L)

	if #ships ~= L then
		return "level " .. L .. ": " .. #ships .. " ships spawned, expected " .. L
	end

	local ids = attackShipIDs(q, player)

	for i, ship in ipairs(ships) do
		if ship.shipName ~= q.bossShip then
			return "level " .. L .. " ship " .. i .. " is " .. tostring(ship.shipName) .. ", expected the boss ship " .. q.bossShip
		end

		if not H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ship) then
			return "level " .. L .. " ship " .. i .. " has no commander kill observer"
		end

		local owner, aggro = false, false

		for _, entry in ipairs(ship.aggroLog) do
			if entry.name == "setMissionOwner" and entry.args[1] == player then owner = true end
			if entry.name == "addExclusiveAggro" and entry.args[1] == player then aggro = true end
		end

		if not owner then return "level " .. L .. " ship " .. i .. ": setMissionOwner(player) not called" end
		if not aggro then return "level " .. L .. " ship " .. i .. ": addExclusiveAggro(player) not called" end
		if not contains(ids, ship.objectID) then return "level " .. L .. " ship " .. i .. " is not in attackShips:" end
	end

	if #ids ~= L then
		return "level " .. L .. ": attackShips: holds " .. #ids .. " ids"
	end

	local detected = 0

	for _, msg in ipairs(H.messageLog(player)) do
		if msg.id == prefix(q) .. "boss_detected" then detected = detected + 1 end
	end

	if detected ~= 1 then
		return "level " .. L .. ": boss_detected sent " .. detected .. " times"
	end

	local lastFlags = {}

	for _, entry in ipairs(player.missionObjectLog) do
		lastFlags[#lastFlags + 1] = tostring(entry.last)
	end

	local wantFlags = {}

	for i = 1, L do wantFlags[i] = tostring(i == L) end

	if joined(lastFlags) ~= joined(wantFlags) then
		return "level " .. L .. ": addSpaceMissionObject last flags [" .. joined(lastFlags) .. "], expected [" .. joined(wantFlags) .. "]"
	end

	return nil
end

-- AC-3 (I-3): one test per level
for L = 1, 5 do
	TestDestroyDutySwgWaves["test_a_level_" .. L .. "_wing_is_" .. L .. "_boss_ships_with_observer_aggro_and_one_boss_detected"] = function()
		local problems = each(function(global) return wingProblem(global, L) end)

		lu.assertEquals(problems, {}, "duties with a wrong level " .. L .. " commander wing")
	end
end

-- AC-3: killing the commanders one at a time; the level ends with the last one
local function wingKillProblem(global, L)
	local q, player, ships = spawnWing(global, L)

	if #ships ~= L then
		return "level " .. L .. ": " .. #ships .. " ships spawned, expected " .. L
	end

	for k = 1, L - 1 do
		local mark = #H.messageLog(player)

		H.destroyShip(ships[k], player.rootParent)

		local got = joined(tokensSince(player, mark))
		local want = SPACE_QUEST .. "destroy_duty_targets_remaining DI=" .. (L - k)

		if got ~= want then
			return "level " .. L .. " after kill " .. k .. ": messages [" .. got .. "], expected [" .. want .. "]"
		end

		if readData(keyOf(q, player, "CurrentLevel:")) ~= L - 1 then
			return "level " .. L .. " after kill " .. k .. ": CurrentLevel is " .. tostring(readData(keyOf(q, player, "CurrentLevel:"))) .. ", expected " .. (L - 1)
		end

		if not isActive(player, q) then return "level " .. L .. " after kill " .. k .. ": the duty ended" end
	end

	local mark = #H.messageLog(player)

	H.destroyShip(ships[L], player.rootParent)

	local sawBossDead = false

	for _, tok in ipairs(tokensSince(player, mark)) do
		if tok == SPACE_QUEST .. "destroy_duty_boss_dead" then sawBossDead = true end
	end

	if not sawBossDead then return "level " .. L .. ": no destroy_duty_boss_dead after the last commander" end

	if L < 5 then
		if not isActive(player, q) then return "level " .. L .. ": the duty ended after the last commander" end
		if readData(keyOf(q, player, "CurrentLevel:")) ~= L then return "level " .. L .. ": CurrentLevel did not advance" end
	else
		if isActive(player, q) or not isComplete(player, q) then return "level 5: the duty did not complete" end
	end

	return nil
end

for L = 1, 5 do
	TestDestroyDutySwgWaves["test_killing_a_level_" .. L .. "_wing_reports_the_remaining_commanders_and_ends_the_level_with_the_last"] = function()
		local problems = each(function(global) return wingKillProblem(global, L) end)

		lu.assertEquals(problems, {}, "duties with a wrong level " .. L .. " wing kill sequence")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: commander taunts (I-4)
---------------------------------------------------------------------------------------------

local function tauntProblem(global, L)
	local q, player, ships, t0 = spawnWing(global, L)

	if #ships ~= L then return "level " .. L .. ": " .. #ships .. " ships spawned" end

	if #bossTaunts(player) ~= 0 then return "level " .. L .. ": a dd_boss_taunt_ is logged at spawn" end

	local pending = 0

	for _, ev in ipairs(H.pendingEvents()) do
		if ev.method == "sendBossTaunt" then
			pending = pending + 1

			if ev.screenplay ~= q.className then return "sendBossTaunt event is for " .. tostring(ev.screenplay) end
			if tostring(ev.args) ~= tostring(L) then return "sendBossTaunt event argument is '" .. tostring(ev.args) .. "', expected '" .. L .. "'" end
		end
	end

	if pending ~= L then return "level " .. L .. ": " .. pending .. " sendBossTaunt events queued, expected " .. L end

	pump(2800, global .. " before the taunts")

	if #bossTaunts(player) ~= 0 then return "level " .. L .. ": a taunt arrived before 3 s" end

	pump(400, global .. " the taunts")

	local taunts = bossTaunts(player)

	if #taunts ~= L then return "level " .. L .. ": " .. #taunts .. " taunts after 3 s, expected " .. L end

	local seen = {}

	for _, t in ipairs(taunts) do
		if t.msg ~= prefix(q) .. "dd_boss_taunt_" .. L then return "level " .. L .. ": taunt '" .. tostring(t.msg) .. "'" end
		if seen[t.ship] then return "level " .. L .. ": one commander taunted twice" end
		seen[t.ship] = true
		if not contains(ships, t.ship) then return "level " .. L .. ": a taunt came from a ship that is not in the wing" end
	end

	pump(10000, global .. " later")

	if #bossTaunts(player) ~= L then return "level " .. L .. ": more taunts later" end

	return nil
end

-- AC-4 (I-4)
for L = 1, 5 do
	TestDestroyDutySwgWaves["test_every_level_" .. L .. "_commander_taunts_dd_boss_taunt_" .. L .. "_three_seconds_after_it_spawns"] = function()
		local problems = each(function(global) return tauntProblem(global, L) end)

		lu.assertEquals(problems, {}, "duties with wrong level " .. L .. " commander taunts")
	end
end

-- AC-4: a commander destroyed before 3 s sends none
function TestDestroyDutySwgWaves:test_a_commander_destroyed_before_its_taunt_sends_none()
	local problems = each(function(global)
		local q, player, ships = spawnWing(global, 3)

		pump(1000, global)
		H.destroyShip(ships[2], player.rootParent)
		pump(2400, global)

		local taunts = bossTaunts(player)

		if #taunts ~= 2 then return #taunts .. " taunts, expected 2 (one commander died)" end

		for _, t in ipairs(taunts) do
			if t.ship == ships[2] then return "the destroyed commander taunted" end
		end
	end)

	lu.assertEquals(problems, {}, "duties where a dead commander taunted")
end

-- AC-4: the duty ended before 3 s: aborted, abandoned directly, or by leaving the zone
function TestDestroyDutySwgWaves:test_no_commander_taunts_when_the_duty_was_aborted_before_3_seconds()
	local problems = each(function(global)
		local q, player = spawnWing(global, 3)

		pump(1000, global)
		q:abortQuest(player)
		pump(5000, global)

		if #bossTaunts(player) ~= 0 then return #bossTaunts(player) .. " taunts after an abort" end
	end)

	lu.assertEquals(problems, {}, "duties that taunted after an abort")
end

function TestDestroyDutySwgWaves:test_no_commander_taunts_when_the_duty_was_abandoned_before_3_seconds()
	local problems = each(function(global)
		local q, player = spawnWing(global, 3)

		needMethod(q, "abandonDuty")
		pump(500, global)
		q:abandonDuty(player)
		pump(5000, global)

		if #bossTaunts(player) ~= 0 then return #bossTaunts(player) .. " taunts after abandonDuty" end
	end)

	lu.assertEquals(problems, {}, "duties that taunted after abandonDuty")
end

function TestDestroyDutySwgWaves:test_no_commander_taunts_when_the_pilot_left_the_zone_before_3_seconds()
	local problems = each(function(global)
		local q, player = spawnWing(global, 3)

		pump(500, global)
		H.zoneSwitch(player, "corellia")
		pump(6000, global)

		if #bossTaunts(player) ~= 0 then return #bossTaunts(player) .. " taunts after leaving the zone" end
	end)

	lu.assertEquals(problems, {}, "duties that taunted after the pilot left")
end

-- AC-4 (contract 2): sendBossTaunt guards, driven directly
function TestDestroyDutySwgWaves:test_send_boss_taunt_does_nothing_for_a_nil_ship_a_dropped_ship_or_an_inactive_duty()
	local q, player, ships = spawnWing("destroy_duty_naboo_privateer_6", 2)

	needMethod(q, "sendBossTaunt")

	-- nil pointer
	q:sendBossTaunt(nil, "2")
	lu.assertEquals(#bossTaunts(player), 0, "nil boss")

	-- a ship that is no longer in attackShips:
	deleteStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:")
	q:sendBossTaunt(ships[1], "2")
	lu.assertEquals(#bossTaunts(player), 0, "boss not in attackShips:")

	-- a listed ship taunts
	writeStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:", { ships[1].objectID })
	q:sendBossTaunt(ships[1], "2")
	lu.assertEquals(#bossTaunts(player), 1, "a listed commander of an active duty taunts")
	lu.assertEquals(bossTaunts(player)[1].msg, prefix(q) .. "dd_boss_taunt_2", "taunt id")

	-- the duty is no longer active
	local crc = H.questCrc(q.questType, q.questName)

	player.ghost.journalActive[crc] = nil
	q:sendBossTaunt(ships[1], "2")
	lu.assertEquals(#bossTaunts(player), 1, "inactive duty")
end

-- AC-4 (contract 3): the wave taunt stays, once per wave, taunt_1..5
function TestDestroyDutySwgWaves:test_a_regular_wave_still_sends_one_wave_taunt_and_never_a_boss_taunt()
	local problems = each(function(global)
		local q, player, area = started(global)

		H.enterArea(area, player.rootParent)
		pump(4500, global)
		pump(5000, global)

		local taunts = H.tauntLog(player)

		if #taunts ~= 1 then return #taunts .. " taunts for the first wave, expected 1" end
		if not tostring(taunts[1].msg):match("^" .. prefix(q):gsub("%p", "%%%0") .. "taunt_[1-5]$") then return "wave taunt id '" .. tostring(taunts[1].msg) .. "'" end
	end)

	lu.assertEquals(problems, {}, "duties with a wrong wave taunt")
end

---------------------------------------------------------------------------------------------
-- AC-5 .. AC-8: leaving the quest zone ends the duty as won
---------------------------------------------------------------------------------------------

local OTHER_ZONE = "space_nowhere"

-- The states of AC-5 (a) and AC-6 (b) .. (e). Each returns q, player with the duty in that state, the player still in the quest zone
local STATES = {}

STATES.a_mid_wave = function(global)
	local q, player, area = started(global)

	H.enterArea(area, player.rootParent)
	pump(4500, global .. " wave")

	return q, player
end

STATES.b_between_rounds_location_pending = function(global)
	local q, player = roundEnd(global, 0, 0)

	if eventCount("getTargetLocation") ~= 1 then error("precondition: getTargetLocation not pending") end

	return q, player
end

STATES.b_between_rounds_area_ready = function(global)
	local q, player = roundEnd(global, 0, 0)

	pump(6000, global .. " next target")

	if getSceneObject(readData(keyOf(q, player, "targetArea:"))) == nil then error("precondition: no next target area") end

	return q, player
end

STATES.c_commander_announced_not_spawned = function(global)
	local q, player = started(global)

	writeData(keyOf(q, player, "CurrentLevel:"), 1)
	writeData(keyOf(q, player, "bossLevel:"), 1)

	return q, player
end

STATES.d_during_the_wing = function(global)
	local q, player, ships = spawnWing(global, 3)

	H.destroyShip(ships[1], player.rootParent)

	return q, player
end

STATES.e_between_levels = function(global)
	local q, player = started(global)
	local boss = commander(q, player, 1)

	H.destroyShip(boss, player.rootParent)

	if eventCount("getTargetLocation") ~= 1 then error("precondition: getTargetLocation not pending after the commander") end

	return q, player
end

local STATE_NAMES = { "a_mid_wave", "b_between_rounds_location_pending", "b_between_rounds_area_ready", "c_commander_announced_not_spawned",
	"d_during_the_wing", "e_between_levels" }

local DUTY_KEYS = { "CurrentWave:", "CurrentRound:", "CurrentLevel:", "DestroyKillCount:", "bossLevel:", "targetArea:" }

-- Leaves the zone from the given state and pumps; returns a problem string or nil. Also returns the snapshot used.
local function leaveProblem(global, state, zone)
	local q, player = STATES[state](global)

	local alive = {}

	for _, ship in ipairs(H.spawnedShips()) do
		if not ship.destroyed then alive[#alive + 1] = ship end
	end

	local bank = player.bankCredits
	local mark, musicMark = #H.messageLog(player), #player.music
	local areaID = readData(keyOf(q, player, "targetArea:"))
	local waypointCount = #player.ghost.waypoints
	local spawnedBefore = #H.spawnedShips()

	H.zoneSwitch(player, zone or OTHER_ZONE)

	-- scheduled as a 2 s event, not run at once, and never failQuest
	local abandonEvents, failEvents, due = 0, 0, nil

	for _, ev in ipairs(H.pendingEvents()) do
		if ev.method == "abandonDuty" and ev.screenplay == q.className then
			abandonEvents = abandonEvents + 1
			due = ev.due
		elseif ev.method == "failQuest" and ev.screenplay == q.className then
			failEvents = failEvents + 1
		end
	end

	if abandonEvents ~= 1 then return "[" .. state .. "] " .. abandonEvents .. " abandonDuty events queued by leaving the zone, expected 1" end
	if failEvents ~= 0 then return "[" .. state .. "] leaving the zone queued failQuest" end
	if due ~= H.now() + 2000 then return "[" .. state .. "] abandonDuty is due at " .. tostring(due) .. ", expected now + 2000 = " .. (H.now() + 2000) end

	pump(2000, global .. " abandon")

	local got = joined(tokensSince(player, mark))
	local want = joined({
		SPACE_QUEST .. "duty_update_s TO=" .. SPACE_QUEST .. "destroy_abandoned",
		SPACE_QUEST .. "quest_ended TO=" .. prefix(q) .. "title",
	})

	if got ~= want then return "[" .. state .. "] messages [" .. got .. "], expected [" .. want .. "]" end

	if player.music[#player.music] ~= VICTORY_MUSIC then return "[" .. state .. "] last music is " .. tostring(player.music[#player.music]) end

	for i = musicMark + 1, #player.music do
		if player.music[i] == FAIL_MUSIC then return "[" .. state .. "] the fail music was played" end
	end

	if not isComplete(player, q) then return "[" .. state .. "] the journal entry is not complete" end
	if isActive(player, q) then return "[" .. state .. "] the journal entry is still active" end
	if #player.datapad.items ~= 0 then return "[" .. state .. "] " .. #player.datapad.items .. " datapad mission(s) left" end
	if #player.ghost.waypoints ~= 0 then return "[" .. state .. "] waypoint left" end
	if areaID ~= nil and areaID ~= 0 and getSceneObject(areaID) ~= nil then return "[" .. state .. "] the target area still exists" end
	if H.hasObserver(ZONESWITCHED, q.className, "enteredZone", player) then return "[" .. state .. "] the ZONESWITCHED observer is still there" end

	for _, key in ipairs(DUTY_KEYS) do
		if not dataGone(keyOf(q, player, key)) then return "[" .. state .. "] key " .. key .. " left (" .. tostring(readData(keyOf(q, player, key))) .. ")" end
	end

	if #readStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:") ~= 0 then return "[" .. state .. "] attackShips: left" end

	for _, ship in ipairs(alive) do
		if not contains(player.removedMissionObjects, ship.objectID) then return "[" .. state .. "] an attack ship was not removed as a mission object" end
	end

	if player.bankCredits ~= bank then return "[" .. state .. "] the bank changed by " .. (player.bankCredits - bank) end

	pump(2000, global .. " ships leave")

	for _, ship in ipairs(alive) do
		if not ship.destroyed then return "[" .. state .. "] an attack ship is still in the world 2 s after the abandon" end
	end

	-- nothing further
	local messages, ships, taunts = #H.messageLog(player), #H.spawnedShips(), #H.tauntLog(player)

	pump(10000, global .. " quiet")

	if #H.messageLog(player) ~= messages then return "[" .. state .. "] a message arrived later: " .. joined(tokensSince(player, messages)) end
	if #H.spawnedShips() ~= ships or ships ~= spawnedBefore then return "[" .. state .. "] ships spawned after the abandon" end
	if #H.tauntLog(player) ~= taunts then return "[" .. state .. "] a taunt arrived later" end
	if player.bankCredits ~= bank then return "[" .. state .. "] credits arrived later" end

	return nil
end

-- AC-5 (I-5)
function TestDestroyDutySwgWaves:test_leaving_the_zone_mid_wave_ends_the_duty_as_won_without_pay_for_every_duty()
	local problems = each(function(global) return leaveProblem(global, "a_mid_wave") end)

	lu.assertEquals(problems, {}, "duties whose leave-zone outcome is not the SWG abandon")
end

-- AC-6a: a switch to a ground zone (a launch, a landing) is leaving the quest zone too
function TestDestroyDutySwgWaves:test_a_switch_to_a_ground_zone_ends_the_duty_as_won_too()
	local problems = each(function(global) return leaveProblem(global, "a_mid_wave", "corellia") end)

	lu.assertEquals(problems, {}, "duties that did not end as won on a switch to a ground zone")
end

-- AC-6 (I-5): the same outcome in every in-progress state
for _, state in ipairs(STATE_NAMES) do
	if state ~= "a_mid_wave" then
		TestDestroyDutySwgWaves["test_leaving_the_zone_in_state_" .. state .. "_ends_the_duty_as_won_without_pay_for_every_duty"] = function()
			local problems = each(function(global) return leaveProblem(global, state) end)

			lu.assertEquals(problems, {}, "duties whose leave-zone outcome in state " .. state .. " is not the SWG abandon")
		end
	end
end

-- AC-5: the abandon is not sent as soon as the pilot leaves, only after 2 s (no early outcome)
function TestDestroyDutySwgWaves:test_nothing_happens_before_the_two_second_delay()
	local q, player = STATES.a_mid_wave("destroy_duty_naboo_privateer_6")
	local mark = #H.messageLog(player)

	H.zoneSwitch(player, OTHER_ZONE)
	pump(1900, "before the delay")

	lu.assertEquals(joined(tokensSince(player, mark)), "", "messages before 2 s")
	lu.assertTrue(isActive(player, q), "still active at 1.9 s")
end

---------------------------------------------------------------------------------------------
-- AC-7: no change elsewhere
---------------------------------------------------------------------------------------------

local function unchangedProblem(global, build, switchZone, label)
	local q, player = build(global)

	local mark, bank = #H.messageLog(player), player.bankCredits
	local ships = #H.spawnedShips()

	H.zoneSwitch(player, switchZone(q))
	pump(10000, global .. " " .. label)

	if joined(tokensSince(player, mark)) ~= "" then return label .. ": messages arrived: " .. joined(tokensSince(player, mark)) end
	if not isActive(player, q) then return label .. ": the duty is no longer active" end
	if isComplete(player, q) then return label .. ": the entry is complete" end
	if #player.datapad.items ~= 1 then return label .. ": the datapad holds " .. #player.datapad.items .. " missions" end
	if player.bankCredits ~= bank then return label .. ": the bank changed" end
	if #H.spawnedShips() ~= ships then return label .. ": ships spawned or removed" end
	if not H.hasObserver(ZONESWITCHED, q.className, "enteredZone", player) then return label .. ": the zone observer is gone" end

	return nil
end

-- AC-7
function TestDestroyDutySwgWaves:test_a_switch_to_the_quest_zone_itself_changes_nothing()
	local problems = each(function(global)
		return unchangedProblem(global, STATES.a_mid_wave, function(q) return q.questZone end, "respawn in the quest zone")
	end)

	lu.assertEquals(problems, {}, "duties changed by a switch to the quest zone")
end

-- AC-7
function TestDestroyDutySwgWaves:test_a_switch_to_another_zone_before_the_quest_zone_was_reached_changes_nothing()
	local problems = each(function(global)
		return unchangedProblem(global, function(g)
			local q, player = started(g, { zone = "space_nowhere_start" })

			if SpaceHelpers:isSpaceQuestTaskComplete(player, q.questType, q.questName, 0) then error("precondition: task 0 is complete outside the quest zone") end

			return q, player
		end, function() return "space_elsewhere" end, "switch before task 0")
	end)

	lu.assertEquals(problems, {}, "duties changed by a switch before task 0")
end

-- AC-7
function TestDestroyDutySwgWaves:test_a_switch_while_in_the_sorosuub_yacht_changes_nothing()
	local problems = each(function(global)
		return unchangedProblem(global, function(g)
			local q, player = STATES.a_mid_wave(g)

			player.rootParent.objectName = "player_sorosuub_space_yacht"

			return q, player
		end, function() return OTHER_ZONE end, "switch in the yacht")
	end)

	lu.assertEquals(problems, {}, "duties changed by a yacht switch")
end

---------------------------------------------------------------------------------------------
-- AC-8: after abandoning
---------------------------------------------------------------------------------------------

local function afterAbandonProblem(global, state, otherGlobal)
	local q, player = STATES[state](global)

	H.zoneSwitch(player, OTHER_ZONE)
	pump(2000, global .. " abandon")

	if SpaceHelpers:hasSpaceQuest(player) then return "[" .. state .. "] hasSpaceQuest is true after the abandon" end

	local mark = #H.messageLog(player)

	q:abortQuest(player)

	if #H.messageLog(player) ~= mark then return "[" .. state .. "] abortQuest sent " .. joined(tokensSince(player, mark)) end
	if not isComplete(player, q) then return "[" .. state .. "] abortQuest cleared the completed entry" end

	-- a different duty can be taken at once
	local other = H.expectGlobal(otherGlobal, "destroy duty quest table")

	other:start()

	local mark2 = #H.messageLog(player)

	other:startQuest(player, "")
	H.advance(0)

	for _, tok in ipairs(tokensSince(player, mark2)) do
		if tok:find("duty_already", 1, true) then return "[" .. state .. "] taking " .. otherGlobal .. " answered duty_already" end
	end

	if not isActive(player, other) then return "[" .. state .. "] " .. otherGlobal .. " did not start" end

	other:abortQuest(player)

	-- the same duty again, from the quest zone
	H.zoneSwitch(player, q.questZone)

	local mark3 = #H.messageLog(player)

	q:startQuest(player, "")
	H.advance(0)

	for _, tok in ipairs(tokensSince(player, mark3)) do
		if tok:find("duty_already", 1, true) then return "[" .. state .. "] the same duty answered duty_already" end
	end

	if not isActive(player, q) then return "[" .. state .. "] the same duty did not start again" end
	if not dataGone(keyOf(q, player, "CurrentLevel:")) then return "[" .. state .. "] CurrentLevel is not 0 on the re-take" end

	local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

	if area == nil then return "[" .. state .. "] no target area on the re-take" end

	local before = #H.spawnedShips()

	H.enterArea(area, player.rootParent)
	pump(4500, global .. " re-take wave")

	local fresh = {}

	for i = before + 1, #H.spawnedShips() do fresh[#fresh + 1] = H.spawnedShips()[i] end

	if #fresh ~= 1 then return "[" .. state .. "] the first wave of the re-take has " .. #fresh .. " ships, expected 1" end
	if H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", fresh[1]) then return "[" .. state .. "] the re-take opened with a commander" end

	local rec = H.questFixture("destroy_duty", q.questName)

	if fresh[1].shipName ~= oracleName(rec, 1, 0) then return "[" .. state .. "] the re-take opened with " .. tostring(fresh[1].shipName) .. ", expected " .. oracleName(rec, 1, 0) end

	return nil
end

-- AC-8 (I-6): one test per state
for _, state in ipairs(STATE_NAMES) do
	TestDestroyDutySwgWaves["test_after_abandoning_in_state_" .. state .. "_the_pilot_can_abort_take_it_again_and_take_another_duty"] = function()
		local problems = {}

		for i, global in ipairs(DUTIES) do
			local ok, result = pcall(afterAbandonProblem, global, state, DUTIES[(i % #DUTIES) + 1])

			if not ok then
				problems[#problems + 1] = global .. ": raised " .. tostring(result)
			elseif result then
				problems[#problems + 1] = global .. ": " .. result
			end
		end

		lu.assertEquals(problems, {}, "duties that misbehave after an abandon in state " .. state)
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: bossLevel: is cleared by every teardown (S1)
---------------------------------------------------------------------------------------------

local TEARDOWNS = {
	abortQuest = function(q, player) q:abortQuest(player) end,
	failQuest = function(q, player) q:failQuest(player, "true") end,
	completeQuest = function(q, player) q:completeQuest(player, "true") end,
}

for _, name in ipairs({ "abortQuest", "failQuest", "completeQuest" }) do
	TestDestroyDutySwgWaves["test_" .. name .. "_clears_the_boss_level_and_a_re_take_opens_with_a_regular_wave"] = function()
		local problems = each(function(global)
			local q, player = started(global)

			writeData(keyOf(q, player, "bossLevel:"), 1)
			TEARDOWNS[name](q, player)

			if not dataGone(keyOf(q, player, "bossLevel:")) then return name .. " left bossLevel: = " .. tostring(readData(keyOf(q, player, "bossLevel:"))) end

			H.zoneSwitch(player, q.questZone)
			q:startQuest(player, "")
			H.advance(0)

			local area = getSceneObject(readData(keyOf(q, player, "targetArea:")))

			if area == nil then return "no target area on the re-take" end

			local before = #H.spawnedShips()

			H.enterArea(area, player.rootParent)
			pump(4500, global .. " re-take")

			local ships = H.spawnedShips()

			if #ships ~= before + 1 then return "the re-take spawned " .. (#ships - before) .. " ships, expected 1" end
			if H.hasObserver(SHIPDESTROYED, q.className, "notifyBossShipDestroyed", ships[#ships]) then return "the re-take opened with a commander" end
			if not H.hasObserver(SHIPDESTROYED, q.className, "notifyAttackShipDestroyed", ships[#ships]) then return "the re-take's first ship has no wave kill observer" end
		end)

		lu.assertEquals(problems, {}, "duties that kept bossLevel: after " .. name)
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: client strings
---------------------------------------------------------------------------------------------

-- AC-10
function TestDestroyDutySwgWaves:test_the_client_has_the_boss_taunts_and_title_of_every_duty_and_the_new_global_strings()
	local global_ids = CS.sids("space/quest")

	lu.assertNotNil(global_ids, "fixture space/quest")

	for _, id in ipairs({ "destroy_abandoned", "duty_update_s", "quest_ended", "destroy_duty_targets_remaining" }) do
		lu.assertTrue(global_ids[id] == true, "space/quest:" .. id)
	end

	for _, global in ipairs(DUTIES) do
		local q = rawget(_G, global)
		local ids = CS.sids("spacequest/destroy_duty/" .. q.questName)

		lu.assertNotNil(ids, global .. ": client fixture")

		for n = 1, 5 do
			lu.assertTrue(ids["dd_boss_taunt_" .. n] == true, global .. ": dd_boss_taunt_" .. n)
		end

		lu.assertTrue(ids["title"] == true, global .. ": title")
	end
end

-- AC-10: every id the new flows send resolves
function TestDestroyDutySwgWaves:test_every_string_id_the_wing_taunt_and_abandon_flows_send_resolves_in_the_client()
	local problems = each(function(global)
		local q0 = rawget(_G, global)
		local logs, taunts = {}, {}

		local function collect(player)
			for _, msg in ipairs(H.messageLog(player)) do logs[#logs + 1] = msg.id; logs[#logs + 1] = msg.TO or "" end
			for _, t in ipairs(H.tauntLog(player)) do taunts[#taunts + 1] = t.msg end
		end

		for _, L in ipairs({ 1, 5 }) do
			local _, p = spawnWing(global, L)

			pump(4000, global)
			collect(p)
		end

		local _, p = STATES.a_mid_wave(global)

		H.zoneSwitch(p, OTHER_ZONE)
		pump(2000, global)
		collect(p)

		local own, ghost = CS.sids("spacequest/destroy_duty/" .. q0.questName), CS.sids("space/quest")
		local missing, seen = {}, {}

		local function check(str)
			local file, id = tostring(str):match("^@([%w_/]+):([%w_]+)$")

			if file and not seen[str] then
				seen[str] = true

				local set = (file == "space/quest") and ghost or CS.sids(file)

				if set == nil or not set[id] then missing[#missing + 1] = str end
			end
		end

		for _, str in ipairs(logs) do check(str) end
		for _, str in ipairs(taunts) do check(str) end

		if own == nil then return "no client fixture for the quest" end

		if #missing > 0 then
			table.sort(missing)

			return "ids the client lacks: " .. table.concat(missing, ", ")
		end
	end)

	lu.assertEquals(problems, {}, "duties that send a string id the pre-CU client lacks")
end

---------------------------------------------------------------------------------------------
-- space-quest-player-ship-destroyed AC-9: a destroyed player ship fails the duty (Mission Failed), pays nothing
-- (the death calls <questType>_<name>:playerShipDestroyed, H.playerShipDestroyed; the respawn switch is inert)
---------------------------------------------------------------------------------------------

local function shipDeathProblem(global, state)
	local q, player = STATES[state](global)

	local alive = {}

	for _, ship in ipairs(H.spawnedShips()) do
		if not ship.destroyed then alive[#alive + 1] = ship end
	end

	local bank = player.bankCredits
	local mark, musicMark = #H.messageLog(player), #player.music
	local areaID = readData(keyOf(q, player, "targetArea:"))

	H.playerShipDestroyed(player)
	pump(10000, global .. " ship death")

	local failed, bad = 0, {}

	for _, token in ipairs(tokensSince(player, mark)) do
		if token == SPACE_QUEST .. "quest_failed TO=" .. prefix(q) .. "title" then
			failed = failed + 1
		else
			bad[#bad + 1] = token
		end
	end

	if failed ~= 1 then return "[" .. state .. "] " .. failed .. " quest_failed messages with the duty title, expected 1" end
	if #bad > 0 then return "[" .. state .. "] other messages after the death: " .. joined(bad) end

	local fails = 0

	for i = musicMark + 1, #player.music do
		if player.music[i] == FAIL_MUSIC then fails = fails + 1 else return "[" .. state .. "] unexpected music " .. tostring(player.music[i]) end
	end

	if fails ~= 1 then return "[" .. state .. "] the fail music played " .. fails .. " times, expected 1" end
	if isActive(player, q) then return "[" .. state .. "] the journal entry is still active" end
	if isComplete(player, q) then return "[" .. state .. "] the journal entry is complete (the duty must fail, not end as won)" end
	if #player.datapad.items ~= 0 then return "[" .. state .. "] " .. #player.datapad.items .. " datapad mission(s) left" end
	if areaID ~= nil and areaID ~= 0 and getSceneObject(areaID) ~= nil then return "[" .. state .. "] the target area still exists" end
	if H.hasObserver(ZONESWITCHED, q.className, "enteredZone", player) then return "[" .. state .. "] the ZONESWITCHED observer is still there" end

	for _, key in ipairs(DUTY_KEYS) do
		if not dataGone(keyOf(q, player, key)) then return "[" .. state .. "] key " .. key .. " left" end
	end

	if #readStringVectorSharedMemory(player.objectID .. q.className .. ":attackShips:") ~= 0 then return "[" .. state .. "] attackShips: left" end

	for _, ship in ipairs(alive) do
		if not ship.destroyed then return "[" .. state .. "] an attack ship is still in the world" end
	end

	if player.bankCredits ~= bank then return "[" .. state .. "] the bank changed by " .. (player.bankCredits - bank) end

	-- the respawn (a switch to the zone the pilot is in) and two hours later add nothing
	local after = #H.messageLog(player)

	H.zoneSwitch(player, player.zone)
	pump(7200 * 1000, global .. " 2 h")

	if #H.messageLog(player) ~= after then return "[" .. state .. "] a message arrived after the death: " .. joined(tokensSince(player, after)) end
	if player.bankCredits ~= bank then return "[" .. state .. "] credits arrived later" end

	return nil
end

-- AC-9
for _, state in ipairs(STATE_NAMES) do
	TestDestroyDutySwgWaves["test_a_ship_death_in_state_" .. state .. "_fails_every_duty_with_mission_failed_and_no_pay"] = function()
		local problems = each(function(global) return shipDeathProblem(global, state) end)

		lu.assertEquals(#DUTIES, 31, "the 31 destroy duties")

		-- a missing hook fails all 31 the same way: show the first two and the count
		if #problems > 2 then
			problems = { problems[1], problems[2], string.format("... %d duties in all", #problems) }
		end

		lu.assertEquals(problems, {}, "duties whose ship death in state " .. state .. " is not the SWG fail")
	end
end

-- AC-9: the comment at the leave-zone branch no longer claims that losing the ship ends the duty as won
function TestDestroyDutySwgWaves:test_the_leave_zone_comment_no_longer_mentions_losing_the_ship()
	local f = assert(io.open(H.SCRIPTS .. "screenplays/space/SpaceDutyDestroyScreenplay.lua", "r"))
	local text = f:read("a")

	f:close()
	lu.assertNil(text:find("losing the ship", 1, true), "SpaceDutyDestroyScreenplay.lua still says 'losing the ship'")
	lu.assertNotNil(text:find("-- Leaving the zone ends the duty as won without pay (destroy_duty.java:100-108)", 1, true),
		"the comment of the leave-zone branch (C7)")
end
