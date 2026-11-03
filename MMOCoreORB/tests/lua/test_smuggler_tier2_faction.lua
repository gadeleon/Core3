-- The escort and recovery attack waves mark the faction of the player's SHIP as their enemy (SC-1, SC-2), not the faction of the squadron.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-12; Shared code changes SC-1/SC-2; FS-7; D-11; R-2).
--
-- The oracle is the C++: FactionManager::getSpaceFactionBySquadron (src/server/zone/managers/faction/FactionManager.cpp), parsed here into a
-- squadron x tier -> faction table, the faction the server puts on a pilot's ship at every launch (ShipObjectImplementation::resetShipFaction). The fake
-- ship of each run carries that faction hash; one wave of each wave-spawning quest type is run, and its ships must hate that hash and lose their
-- alliance with it. Rows whose C++ faction equals the old Lua squadron faction (every squadron but a Smuggler above tier 1) must also match the old value,
-- which proves "no behavior change" for them.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DR = require("duty_rules_scenario")
local RF = require("recovery_fixes_scenario")
local M = require("smuggler_tier2_data")

M.load()

local CPP = "src/server/zone/managers/faction/FactionManager.cpp"

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

-- squadron global name -> { [tier 1..5] = faction string } from the C++ switch
local function parseCpp()
	local text = readFile(CPP)

	if text == nil then
		return nil
	end

	local body = text:match("String FactionManager::getSpaceFactionBySquadron%(int spaceSquadron, int tier%) {(.-)\nuint32 FactionManager::")

	assert(body ~= nil, CPP .. ": getSpaceFactionBySquadron not found")

	local rows, current, cases, inSwitch = {}, {}, {}, false
	local defaulted

	local function setAll(faction)
		for _, name in ipairs(current) do
			rows[name] = rows[name] or {}

			for tier = 1, 5 do
				rows[name][tier] = rows[name][tier] or faction
			end
		end
	end

	for line in (body .. "\n"):gmatch("([^\n]*)\n") do
		local names = {}

		for name in line:gmatch("spaceSquadron == PlayerManager::([%w_]+)") do
			names[#names + 1] = name
		end

		if #names > 0 then
			current, cases, inSwitch = names, {}, false
		elseif line:find("switch%s*%(tier%)") then
			inSwitch, cases, defaulted = true, {}, false
		elseif inSwitch then
			local case = line:match("case%s+(%d+)%s*:")
			local default = line:match("default%s*:")
			local ret = line:match('return%s+"([%w_]+)"')

			if case then
				cases[#cases + 1] = tonumber(case)
			elseif default then
				defaulted = true
			elseif ret then
				for _, name in ipairs(current) do
					rows[name] = rows[name] or {}

					for _, tier in ipairs(cases) do
						rows[name][tier] = ret
					end

					if defaulted then
						for tier = 1, 5 do
							rows[name][tier] = rows[name][tier] or ret
						end
					end
				end

				cases = {}
			end
		else
			local ret = line:match('return%s+"([%w_]+)"')

			if ret and #current > 0 then
				setAll(ret)
				current = {}
			end
		end
	end

	return rows
end

local ROWS = parseCpp()

local function requireCpp()
	if ROWS == nil then
		lu.skip(CPP .. " is not available (run from MMOCoreORB/)")
	end
end

local ORDER = { "CORSEC_SQUADRON", "RSF_SQUADRON", "SMUGGLER_SQUADRON", "BLACK_EPSILON_SQUADRON", "STORM_SQUADRON", "INQUISITION_SQUADRON", "CRIMSON_PHOENIX_SQUADRON", "VORTEX_SQUADRON", "HAVOC_SQUADRON" }

local function hasValue(list, value)
	for _, v in ipairs(list or {}) do
		if v == value then
			return true
		end
	end

	return false
end

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT2FactionOracle = {}

function TestSmugglerT2FactionOracle:setUp() H.reset() end

-- AC-12 (the oracle itself): the C++ table the spec's impact table states
function TestSmugglerT2FactionOracle:test_the_cpp_gives_each_squadron_and_tier_the_faction_of_the_impact_table()
	requireCpp()

	for _, name in ipairs(ORDER) do
		lu.assertNotNil(ROWS[name], CPP .. ": no rows for " .. name)
	end

	for tier = 1, 5 do
		lu.assertEquals(ROWS.CORSEC_SQUADRON[tier], "corsec", "CorSec tier " .. tier)
		lu.assertEquals(ROWS.RSF_SQUADRON[tier], "rsf", "RSF tier " .. tier)

		for _, name in ipairs({ "BLACK_EPSILON_SQUADRON", "STORM_SQUADRON", "INQUISITION_SQUADRON" }) do
			lu.assertEquals(ROWS[name][tier], "imperial", name .. " tier " .. tier)
		end

		for _, name in ipairs({ "HAVOC_SQUADRON", "VORTEX_SQUADRON", "CRIMSON_PHOENIX_SQUADRON" }) do
			lu.assertEquals(ROWS[name][tier], "rebel", name .. " tier " .. tier)
		end
	end

	lu.assertEquals({ ROWS.SMUGGLER_SQUADRON[1], ROWS.SMUGGLER_SQUADRON[2], ROWS.SMUGGLER_SQUADRON[3], ROWS.SMUGGLER_SQUADRON[4], ROWS.SMUGGLER_SQUADRON[5] },
		{ "smuggler", "valarian", "hutt", "hutt", "hutt" }, "Smuggler tiers 1-5")
end

-- AC-12 (the oracle itself): every squadron constant is a harness global
function TestSmugglerT2FactionOracle:test_every_squadron_of_the_cpp_is_a_harness_constant()
	requireCpp()

	for _, name in ipairs(ORDER) do
		lu.assertNotNil(rawget(_G, name), name .. " is a global")
	end
end

---------------------------------------------------------------------------------------------
-- The helper pair: old Lua value versus the C++ value
---------------------------------------------------------------------------------------------

TestSmugglerT2FactionRows = {}

function TestSmugglerT2FactionRows:setUp() H.reset() end

-- AC-12: for every row that keeps its behavior, the squadron faction the old Lua gave equals the ship faction (nothing changes)
function TestSmugglerT2FactionRows:test_the_rows_that_do_not_change_have_the_same_old_lua_and_cpp_value()
	requireCpp()

	for _, name in ipairs(ORDER) do
		for tier = 1, 5 do
			local old = SpaceHelpers:getPlayerSpaceFactionHash(H.newPlayer({ squadronType = rawget(_G, name), pilot = "neutral" }))
			local new = getHashCode(ROWS[name][tier])
			local changes = name == "SMUGGLER_SQUADRON" and tier >= 2

			if changes then
				lu.assertNotEquals(old, new, name .. " tier " .. tier .. ": the fix changes this row")
			else
				lu.assertEquals(new, old, name .. " tier " .. tier .. ": the ship faction equals the old squadron faction")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- One wave per quest type and row
---------------------------------------------------------------------------------------------

TestSmugglerT2FactionWaves = {}

function TestSmugglerT2FactionWaves:setUp() H.reset() end
function TestSmugglerT2FactionWaves:tearDown()
	AC.tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- the quests whose attack waves are fixed: story escort, escort duty, story recovery, recovery duty (SC-1 covers the first two, SC-2 the last two)
local ESCORTS = {
	{ kind = "story escort (Dravis mission 3)", global = "escort_tatooine_privateer_3" },
	{ kind = "story escort (Shamdon mission 4)", global = "escort_tatooine_privateer_tier2_4a" },
	{ kind = "escort duty (CorSec)", global = "escort_duty_corellia_privateer_7" },
	{ kind = "escort duty (RSF)", global = "escort_duty_naboo_privateer_7" },
	{ kind = "escort duty (Shamdon)", global = "escort_duty_tatooine_privateer_tier2_1" },
}

local RECOVERIES = {
	{ kind = "story recovery (CorSec tier 3)", global = "recovery_corellia_privateer_tier3_1" },
	{ kind = "recovery duty (CorSec)", global = "recovery_duty_corellia_privateer_12" },
	{ kind = "recovery duty (RSF)", global = "recovery_duty_naboo_privateer_10" },
	{ kind = "recovery duty (Shamdon)", global = "recovery_duty_tatooine_privateer_tier2_1" },
}

local function player(q, squadron, tier, hash)
	return H.newPlayer({
		name = "Ace", pilot = "neutral", squadronType = squadron, pilotTier = tier,
		zone = q.questZone, ship = { x = DR.CORNER.x, z = DR.CORNER.z, y = DR.CORNER.y, factionHash = hash },
		inventory = true,
	})
end

local function escortWave(global, squadron, tier, hash)
	local q = H.expectGlobal(global, "escort quest table")

	lu.assertTrue((q.attackDelay or 0) > 0, global .. ": attackDelay must be set (SpaceEscortScreenplay re-queues its attack wave every attackDelay seconds)")
	H.reset()
	q:start()

	local p = player(q, squadron, tier, hash)

	q:startQuest(p, "")
	H.advance(0)
	H.advance(2500)

	local start = readData(p.objectID .. q.className .. ":startPoint:")

	H.enterArea(AC.areaByNumber(q, start), p.rootParent)
	H.advance(6000)

	local agent = getSceneObject(readData(p.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(agent, global .. ": the escort ship spawned")
	H.advance(5000)

	local before = #H.spawnedShips()

	H.advance((q.attackDelay + 1) * 1000)

	local out = {}

	for i, ship in ipairs(H.spawnedShips()) do
		if i > before and ship ~= agent then
			out[#out + 1] = ship
		end
	end

	return out
end

local function recoveryWave(global, squadron, tier, hash)
	local q = H.expectGlobal(global, "recovery quest table")

	H.reset()

	local p = player(q, squadron, tier, hash)
	local run = RF.start(global, p)

	RF.capture(run)

	return RF.wave(run)
end

local function check(label, wave, hash)
	lu.assertTrue(#wave >= 1, label .. ": an attack wave spawned")

	for i, ship in ipairs(wave) do
		lu.assertTrue(hasValue(ship.factionEnemies, hash), label .. ": attacker " .. i .. " ('" .. tostring(ship.shipName) .. ") is hostile to the pilot's ship faction")
		lu.assertTrue(hasValue(ship.removedFactionAllies, hash), label .. ": attacker " .. i .. " lost its alliance with the pilot's ship faction")
	end
end

-- rows: every Smuggler tier, and tiers 1 and 5 of every other squadron
local ROWSET = {}

for tier = 1, 5 do
	ROWSET[#ROWSET + 1] = { "SMUGGLER_SQUADRON", tier }
end

for _, name in ipairs(ORDER) do
	if name ~= "SMUGGLER_SQUADRON" then
		ROWSET[#ROWSET + 1] = { name, 1 }
		ROWSET[#ROWSET + 1] = { name, 5 }
	end
end

for _, row in ipairs(ROWSET) do
	for _, e in ipairs(ESCORTS) do
		-- AC-12
		TestSmugglerT2FactionWaves["test_" .. e.global .. "_wave_hates_the_ship_faction_of_" .. row[1] .. "_tier_" .. row[2]] = function()
			requireCpp()

			local faction = ROWS[row[1]][row[2]]
			local hash = getHashCode(faction)

			check(e.kind .. " / " .. row[1] .. " tier " .. row[2] .. " (ship faction " .. faction .. ")", escortWave(e.global, rawget(_G, row[1]), row[2], hash), hash)
		end
	end

	for _, r in ipairs(RECOVERIES) do
		-- AC-12
		TestSmugglerT2FactionWaves["test_" .. r.global .. "_wave_hates_the_ship_faction_of_" .. row[1] .. "_tier_" .. row[2]] = function()
			requireCpp()

			local faction = ROWS[row[1]][row[2]]
			local hash = getHashCode(faction)

			check(r.kind .. " / " .. row[1] .. " tier " .. row[2] .. " (ship faction " .. faction .. ")", recoveryWave(r.global, rawget(_G, row[1]), row[2], hash), hash)
		end
	end
end

-- AC-12: the waves do not name the squadron faction when the ship carries another (a tier 2 Smuggler is `valarian`, not `smuggler`)
function TestSmugglerT2FactionWaves:test_a_tier_2_smuggler_wave_does_not_hate_the_smuggler_faction()
	requireCpp()

	local hash = getHashCode(ROWS.SMUGGLER_SQUADRON[2])
	local smuggler = getHashCode("smuggler")

	lu.assertEquals(ROWS.SMUGGLER_SQUADRON[2], "valarian", "C++ tier 2 faction")

	for _, e in ipairs({ ESCORTS[2], ESCORTS[3] }) do
		for i, ship in ipairs(escortWave(e.global, SMUGGLER_SQUADRON, 2, hash)) do
			lu.assertFalse(hasValue(ship.factionEnemies, smuggler), e.kind .. ": attacker " .. i .. " hates the squadron faction smuggler")
		end
	end

	for _, r in ipairs({ RECOVERIES[2], RECOVERIES[4] }) do
		for i, ship in ipairs(recoveryWave(r.global, SMUGGLER_SQUADRON, 2, hash)) do
			lu.assertFalse(hasValue(ship.factionEnemies, smuggler), r.kind .. ": attacker " .. i .. " hates the squadron faction smuggler")
		end
	end
end

-- AC-12: a tier 3 Smuggler's waves name hutt
function TestSmugglerT2FactionWaves:test_a_tier_3_smuggler_wave_hates_hutt()
	requireCpp()

	local hash = getHashCode("hutt")

	lu.assertEquals(ROWS.SMUGGLER_SQUADRON[3], "hutt", "C++ tier 3 faction")
	check("Shamdon M4 / tier 3", escortWave("escort_tatooine_privateer_tier2_4a", SMUGGLER_SQUADRON, 3, hash), hash)
	check("CorSec escort duty with a tier 3 Smuggler", escortWave("escort_duty_corellia_privateer_7", SMUGGLER_SQUADRON, 3, hash), hash)
end

-- AC-12: a ship that carries another faction than the squadron's (an admin's /setFaction, another player's ship) is what the waves hate
function TestSmugglerT2FactionWaves:test_the_wave_hates_whatever_faction_the_ship_carries()
	local hash = getHashCode("imperial")

	check("CorSec pilot in an imperial ship", escortWave("escort_duty_corellia_privateer_7", CORSEC_SQUADRON, 1, hash), hash)
	check("RSF pilot in an imperial ship", recoveryWave("recovery_duty_naboo_privateer_10", RSF_SQUADRON, 1, hash), hash)
end
