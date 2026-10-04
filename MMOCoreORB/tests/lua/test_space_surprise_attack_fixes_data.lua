-- Surprise attacks (CorSec, RSF, Havoc): data conformance against SWG-Source and the three CorSec ship-list fixes.
-- Spec: .claude/work/space-surprise-attack-fixes/01-spec.md (AC-7, invariant I-1, decision D-5).
--
-- SWG's spawn loop (destroy_surpriseattack.java:80-130) only ever uses the first listed shipType when the later rows have an
-- empty or 0 shipCount, so corellia_privateer_1, _tier4_1c and _tier4_4c spawn one ship type in SWG. surprise_replay.lua replays
-- that loop on the .tab fixture; Core3's `spawns` must equal the result for all 19 tables.

local lu = require("luaunit")
local H = require("harness")
local R = require("surprise_replay")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local SWG_DIR = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/spacequest/destroy_surpriseattack/"

local GLOBALS = {}

for _, name in ipairs(H.questGlobals()) do
	if rawget(_G, name).questType == "destroy_surpriseattack" then
		GLOBALS[#GLOBALS + 1] = name
	end
end

local NEW_FIXTURES = {
	"corellia_privateer_tier3_1_c", "corellia_privateer_tier3_2_c", "corellia_privateer_tier4_1c", "corellia_privateer_tier4_4c",
	"corellia_rebel_1", "viopa_rebel_1", "corellia_rebel_tier3_1_b", "corellia_rebel_tier3_4_b",
}

local function readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")
	f:close()

	return text
end

TestSurpriseAttackFixesData = {}

function TestSurpriseAttackFixesData:setUp() H.reset() end

-- AC-7, I-1: spawns = SWG's runtime result, zones = the fixture's questZone, for every table
for _, global in ipairs(GLOBALS) do
	-- AC-7
	TestSurpriseAttackFixesData["test_" .. global .. "_spawns_what_swgs_spawn_loop_spawns_over_the_tab"] = function()
		local q = rawget(_G, global)
		local rec = H.questFixture("destroy_surpriseattack", q.questName)
		local name = "destroy_surpriseattack/" .. q.questName

		lu.assertEquals(q.surpriseAttackShips.spawns, R.runs(R.replay(q.questName)), name .. ": surpriseAttackShips.spawns")
		lu.assertEquals(q.questZone, rec:get("questZone"), name .. ": questZone")
		lu.assertEquals(q.surpriseAttackShips.zone, rec:get("questZone"), name .. ": surpriseAttackShips.zone")
	end
end

-- AC-7: the exact data of the three fixed tables
local FIXED = {
	{ "destroy_surpriseattack_corellia_privateer_1", { { count = 3, shipName = "blacksun_fighter_s01_tier1" } } },
	{ "destroy_surpriseattack_corellia_privateer_tier4_1c", { { count = 4, shipName = "blacksun_ace_s04_tier4" } } },
	{ "destroy_surpriseattack_corellia_privateer_tier4_4c", { { count = 5, shipName = "hidden_daggers_killer_tier4" } } },
}

for _, row in ipairs(FIXED) do
	local global, spawns = row[1], row[2]

	-- AC-7
	TestSurpriseAttackFixesData["test_" .. global .. "_has_exactly_the_swg_ship_list"] = function()
		lu.assertEquals(H.expectGlobal(global, "surprise attack quest table").surpriseAttackShips.spawns, spawns, global .. ": spawns")
	end

	-- AC-7
	TestSurpriseAttackFixesData["test_" .. global .. "_spawns_exactly_those_ships_when_started_in_its_zone"] = function()
		local q = H.expectGlobal(global, "surprise attack quest table")
		local player = H.newPlayer({ name = "Ace", zone = q.questZone, ship = true, pilot = "neutral" })

		q:startQuest(player, "")

		local names = {}

		for i, c in ipairs(H.Engine.callsTo("spawnShipAgent")) do
			names[i] = c[1]
		end

		local want = {}

		for _ = 1, spawns[1].count do
			want[#want + 1] = spawns[1].shipName
		end

		lu.assertEquals(names, want, global .. ": spawnShipAgent ship names in order")
	end
end

-- AC-7: the other 16 tables keep their ship lists (the replay equals today's data)
function TestSurpriseAttackFixesData:test_the_other_sixteen_tables_have_one_entry_per_swg_ship_run()
	local fixed = {}

	for _, row in ipairs(FIXED) do
		fixed[row[1]] = true
	end

	local checked = 0

	for _, global in ipairs(GLOBALS) do
		if not fixed[global] then
			local q = rawget(_G, global)

			lu.assertEquals(q.surpriseAttackShips.spawns, R.runs(R.replay(q.questName)), global .. ": spawns")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 16, "tables outside the three fixed ones")
end

-- AC-7: the 8 new fixtures are byte copies of SWG-Source (CRLF)
function TestSurpriseAttackFixesData:test_the_19_tab_and_sids_fixtures_exist()
	lu.assertEquals(#GLOBALS, 19, "surprise attack quest tables")

	for _, global in ipairs(GLOBALS) do
		local name = rawget(_G, global).questName
		local tab = readFile(H.FIXTURES .. "spacequest/destroy_surpriseattack/" .. name .. ".tab")
		local sids = readFile(H.FIXTURES .. "string/en/spacequest/destroy_surpriseattack/" .. name .. ".sids")

		lu.assertNotNil(tab, name .. ": fixtures/spacequest/destroy_surpriseattack/" .. name .. ".tab")
		lu.assertNotNil(sids, name .. ": fixtures/string/en/spacequest/destroy_surpriseattack/" .. name .. ".sids")
		lu.assertNil(sids:find("\r", 1, true), name .. ".sids: LF line endings")
	end
end

for _, name in ipairs(NEW_FIXTURES) do
	-- AC-7
	TestSurpriseAttackFixesData["test_fixture_" .. name .. "_is_a_byte_copy_of_swg_source"] = function()
		local copy = readFile(H.FIXTURES .. "spacequest/destroy_surpriseattack/" .. name .. ".tab")

		lu.assertNotNil(copy, name .. ".tab fixture")
		lu.assertNotNil(copy:find("\r\n", 1, true), name .. ".tab: CRLF line endings, as in SWG-Source")

		local original = readFile(SWG_DIR .. name .. ".tab")

		if original == nil then
			lu.skip("SWG-Source research clone not available: " .. SWG_DIR)
		end

		lu.assertTrue(copy == original, name .. ".tab: not byte-identical to SWG-Source")
	end
end
