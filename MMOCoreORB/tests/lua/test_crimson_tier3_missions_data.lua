-- Crimson Phoenix tier 3 part A (Arnecio Ulvaw'op's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop-missions/01-spec.md (A-1, A-2; invariants I-1 .. I-8; Content contract 1 to 3; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of crimson_tier3_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")
local R = require("surprise_replay")

T.load()

local function quest(global) return T.quest(global) end

local function fixtureOf(global)
	local id = T.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return T.IDENTITY[global].type .. "/" .. T.IDENTITY[global].name end

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

local function dataKeys(q)
	local own = {}

	for k, v in pairs(q) do
		if type(v) ~= "function" then
			own[k] = v
		end
	end

	return own
end

local function functionKeys(q)
	local out = {}

	for k, v in pairs(q) do
		if type(v) == "function" then
			out[#out + 1] = tostring(k)
		end
	end

	table.sort(out)
	return out
end

local function inherits(q, class)
	local mt = getmetatable(q)

	for _ = 1, 8 do
		if mt == nil then
			return false
		end

		if mt == class or mt.__index == class then
			return true
		end

		mt = getmetatable(mt.__index)
	end

	return false
end

local function trunc(v) return v >= 0 and math.floor(v) or -math.floor(-v) end

local EXCERPTS = {
	space_dathomir = "space_zones/buildout/space_dathomir.crimson_tier3_points.tab",
	space_dantooine = "space_zones/buildout/space_dantooine.crimson_tier3_points.tab",
	space_endor = "space_zones/buildout/space_endor.crimson_tier3_points.tab",
	space_lok = "space_zones/buildout/space_lok.crimson_tier3_points.tab",
}

local ZONES = { "space_dathomir", "space_dantooine", "space_endor", "space_lok" }

-- the rows of a zone's buildout excerpt: nav_name -> { x, z, y, forward }, strSpawnerName -> { x, z, y }
local function buildout(zone)
	local tab = H.fixture(EXCERPTS[zone])
	local navs, spawners = {}, {}

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawn = vars:match("strSpawnerName|4|([^|]+)|")
		local row = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")),
			forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") } }

		if nav ~= nil then
			navs[nav] = row
		end

		if spawn ~= nil then
			spawners[spawn] = row
		end
	end

	return navs, spawners
end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. zone)
	return p
end

-- the points of a list column: { zone, name, x, z, y }
local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		out[i] = { zone = zone, name = name, x = p.x, z = p.z, y = p.y }
	end

	return out
end

-- a column of points as the quest tables store them, with `extra` fields (a function of the index)
local function mapped(rec, column, extra)
	local out = {}

	for i, p in ipairs(pointsOf(rec, column)) do
		local t = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }

		for k, v in pairs(extra and extra(i, p) or {}) do
			t[k] = v
		end

		out[i] = t
	end

	return out
end

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

local function realRadius(i) return { escortNumber = i, radius = 250 } end

---------------------------------------------------------------------------------------------
-- The oracle itself (these pass before the implementation: they prove the spec literals equal the fixtures and Core3's existing point files)
---------------------------------------------------------------------------------------------

TestUlvawopFixtures = {}

function TestUlvawopFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 17 fixtures are the four chains of the spec, member by member in their zones (triggerArg names the next member; the chain end splits nothing)
function TestUlvawopFixtures:test_the_seventeen_fixtures_form_the_four_chains_of_the_spec()
	local n = 0

	for c, chain in ipairs(T.CHAINS) do
		for i, global in ipairs(chain) do
			local rec = fixtureOf(global)

			n = n + 1
			lu.assertEquals(rec:get("questZone"), T.IDENTITY[global].zone, label(global) .. ": questZone")

			if i < #chain then
				local nid = T.IDENTITY[chain[i + 1]]

				lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(global) .. ": triggerEvent")
				lu.assertEquals(rec:get("triggerArg"), nid.type .. ":" .. nid.name, label(global) .. ": triggerArg (mission " .. c .. ", the next chain member)")
			else
				lu.assertTrue(rec:get("triggerEvent") == nil or rec:get("triggerEvent") == "none", label(global) .. ": the chain end splits nothing, got " .. tostring(rec:get("triggerEvent")))
			end
		end
	end

	lu.assertEquals(n, 17, "fixtures")
	lu.assertEquals({ #T.M1, #T.M2, #T.M3, #T.M4 }, { 4, 4, 4, 5 }, "chain lengths")
end

-- A-2 (the oracle itself): FU-4, the values of the split rows the spec builds on (a missing triggerDelay column reads 0)
function TestUlvawopFixtures:test_the_split_rows_carry_the_values_the_spec_lists()
	local success = {
		[T.M1[1]] = 0, [T.M1[2]] = 5, [T.M1[3]] = 0,
		[T.M2[1]] = 3, [T.M2[2]] = 3, [T.M2[3]] = 0,
		[T.M3[1]] = 3, [T.M3[2]] = 0, [T.M3[3]] = 3,
		[T.M4[1]] = 0, [T.M4[3]] = 3, [T.M4[4]] = 3,
	}

	for global, delay in pairs(success) do
		local rec = fixtureOf(global)

		lu.assertEquals(rec:get("triggerSplitCondition"), "success", label(global) .. ": triggerSplitCondition")
		lu.assertEquals(rec:num("triggerDelay") or 0, delay, label(global) .. ": triggerDelay")
	end

	local rec = fixtureOf(T.M4[2])

	lu.assertEquals({ rec:get("triggerSplitCondition"), rec:num("triggerOn"), rec:num("triggerEndsMission"), rec:num("triggerDelay") }, { "triggerOn", 3, 1, 4 }, label(T.M4[2]))
	lu.assertEquals(fixtureOf(T.M1[1]):num("numResponses"), 5, "recovery 1 numResponses")
	lu.assertEquals(fixtureOf(T.M1[4]):num("numResponses"), 5, "escort 1_c numResponses")
	lu.assertEquals(fixtureOf(T.M3[3]):num("numResponses"), 5, "escort 3_b numResponses")
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the Core3 patrol point files hold (45 nav points)
function TestUlvawopFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(T.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 43, "spec nav points (23 + 7 + 1 + 12)")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points and spawners; Core3's values are their truncated values
function TestUlvawopFixtures:test_the_buildout_excerpts_pin_every_point_and_both_suspect_spawners()
	for _, zone in ipairs(ZONES) do
		local navs, spawners = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(T.POINTS[zone]), zone .. ": nav_name rows of the excerpt")
		lu.assertEquals(sortedKeys(spawners), sortedKeys(T.SPAWNERS[zone] or {}), zone .. ": strSpawnerName rows of the excerpt")

		for name, xyz in pairs(T.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end

		for name, xyz in pairs(T.SPAWNERS[zone] or {}) do
			lu.assertEquals({ spawners[name].x, spawners[name].z, spawners[name].y }, xyz, zone .. ": buildout truncated, spawner " .. name)
		end
	end

	lu.assertEquals(buildout("space_dantooine").tatooine_rebel_tier3_2_c_battlepoint.forward, T.FORWARD_2C, "battle 2_c forward = fltKX/fltKY/fltKZ of BODA row 52")
	lu.assertEquals(buildout("space_dathomir").tatooine_rebel_tier3_3_a_battlepoint.forward, T.FORWARD_3A, "battle 3_a forward = fltKX/fltKY/fltKZ of BODT row 241")
	lu.assertEquals(buildout("space_endor").tatooine_rebel_tier3_4_d_battlepoint.forward, T.FORWARD_4D, "battle 4_d forward = fltKX/fltKY/fltKZ of BOEN row 392")
end

-- A-2, I-2 (the oracle itself): both suspect spawners exist in Core3's spawner table at the spec positions and list the four suspects and the decoys
function TestUlvawopFixtures:test_the_two_suspect_spawners_exist_in_the_core3_spawner_table_and_list_all_four_suspects()
	local spawners = H.spawners("space_dathomir")

	for name, xyz in pairs(T.SPAWNERS.space_dathomir) do
		local s = spawners[name]

		lu.assertNotNil(s, "space_dathomir_spawner.lua: spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)

		local ships = {}

		for _, ship in ipairs(s.shipSpawns) do
			ships[ship] = true
		end

		for _, suspect in ipairs(T.SUSPECT_ORDER) do
			lu.assertTrue(ships[suspect] == true, name .. ": shipSpawns lists " .. suspect)
		end
	end
end

-- A-2, I-8 (the oracle itself): the client journal knows every quest
function TestUlvawopFixtures:test_the_client_quest_name_table_lists_the_seventeen_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(T.GLOBALS) do
		local name = "spacequest/" .. T.IDENTITY[global].type .. "/" .. T.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

-- A-2, I-5 (the oracle itself): SWG's space_mobile cargo column names inspect_cargo/tatooine_tier3_2_inspect for all four suspects, and the table has
-- thermal_bomb twice with canTransfer 1 (2 of 7 rows)
function TestUlvawopFixtures:test_space_mobile_names_the_cargo_table_and_it_has_the_thermal_bomb_as_a_transferable_row()
	local tab = H.fixture("space_mobile/space_mobile.crimson_tier3_inspect.tab")
	local cargoOf = {}

	for _, rec in ipairs(tab.records) do
		cargoOf[rec:get("strIndex")] = rec:get("cargo")
	end

	lu.assertEquals(#tab.records, 4, "space_mobile excerpt rows (SMT 1755-1758)")

	for ship in pairs(T.SUSPECTS) do
		lu.assertEquals(cargoOf[ship], T.CARGO_TABLE, "space_mobile.tab cargo column of " .. ship)
	end

	local rows = H.fixture("spacequest/inspect_cargo/" .. T.CARGO_TABLE .. ".tab").records
	local transferable = {}

	for _, rec in ipairs(rows) do
		if rec:num("canTransfer") == 1 then
			transferable[#transferable + 1] = rec:get("name")
		end
	end

	lu.assertEquals(#rows, 7, "inspect_cargo/" .. T.CARGO_TABLE .. ".tab rows")
	lu.assertEquals(transferable, { "thermal_bomb", "thermal_bomb" }, "the rows with canTransfer 1")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestUlvawopWiring = {}

function TestUlvawopWiring:setUp() H.reset() end

-- A-1, I-1
function TestUlvawopWiring:test_the_squadron_file_registers_the_seventeen_quests_with_start_true()
	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#T.GLOBALS, 17, "tier 3 globals")
end

-- A-1: Content contract 1 order, after the 16 tier 1-2 globals
function TestUlvawopWiring:test_the_seventeen_quests_are_registered_in_the_contract_order_after_the_sixteen_earlier_quests()
	local order = {}

	for _, global in ipairs(T.EARLIER_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 33, "16 tier 1-2 + 17 tier 3 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1: the squadron object has the seventeen constants and the reset; every earlier field is unchanged
function TestUlvawopWiring:test_the_squadron_screenplay_has_the_seventeen_constants_the_reset_and_every_earlier_field()
	local sq = T.squadron()

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field)
	end

	lu.assertEquals(#T.QUEST_STRING_FIELDS, 17, "constants")

	for field, want in pairs(E.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 2, unchanged)")
	end

	for field, want in pairs(C.QUEST_STRINGS or {}) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.EKER_PILOT_KEY, T.EKER_PILOT_KEY, "EKER_PILOT_KEY unchanged")
	lu.assertEquals(sq.EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "EKER_PILOT_KEY text unchanged")
	lu.assertEquals(type(sq.resetSocunaQuests), "function", "resetSocunaQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetEkerQuests), "function", "resetEkerQuests (tier 2, unchanged)")
	lu.assertEquals(type(sq.resetUlvawopQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests (Content contract 3)")
	lu.assertEquals(pcall(sq.resetUlvawopQuests, sq, nil), true, "resetUlvawopQuests(nil) returns early")
end

-- A-1, D-8: the two comment lines of Content contract 2 (the file text; no behavior)
function TestUlvawopWiring:test_the_two_stale_comment_lines_read_as_the_contract_says()
	local text = readFile(H.SCRIPTS .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua")

	lu.assertNotNil(text, "CrimsonPhoenixSquadronScreenplay.lua")
	lu.assertNil(text:find("Trainer: Major Eker (no conversation yet)", 1, true), "CSP:268 still says 'Major Eker (no conversation yet)'")
	lu.assertNotNil(text:find("\tTrainer: Major Eker (conversation ekerConvoHandler), Yavin 4 labor outpost (screenplays/cities/yavin4_labor_outpost.lua:18)", 1, true),
		"CSP:268: 'Trainer: Major Eker (conversation ekerConvoHandler), Yavin 4 labor outpost (...'")
	lu.assertNotNil(text:find('\t-- SWG\'s ekerPilot space flag ("1" from Da\'la Socuna; Major Eker reads it as set and writes "2" on the hand-in and "3" with mission 4\'s reward; tier 3 reads it as set)', 1, true),
		"CSP:581: the EKER_PILOT_KEY comment")
	lu.assertNil(text:find('tier 2 reads it as set and writes "2")', 1, true), "CSP:581 still has the old comment")
end

-- A-1, Content contract 1: the section comment and the mission lines
function TestUlvawopWiring:test_the_tier_3_section_and_mission_comments_are_present()
	local text = readFile(H.SCRIPTS .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua") or ""

	for _, want in ipairs({
		"Tier 3 -- Arnecio Ulvaw'op (Dathomir, science outpost; Dathomir, Dantooine, Lok and Endor systems)",
		"-- Mission 1: Recovery > Delivery > Survival > Escort",
		"-- Mission 2: Inspect > Surprise attack > Assassinate (Dantooine) > Space battle (Dantooine)",
		"-- Mission 3: Delivery (Lok to Dathomir) > Space battle > Escort > Survival",
		"-- Mission 4: Assassinate > Patrol > Surprise attack > Delivery (no pickup) > Space battle",
		"-- Tier 3 (Ulvaw'op); N is the trainer script's mission number",
	}) do
		lu.assertNotNil(text:find(want, 1, true), "CrimsonPhoenixSquadronScreenplay.lua lacks the comment: " .. want)
	end
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestUlvawopTables = {}

function TestUlvawopTables:setUp() H.reset() end

-- A-2, I-1
function TestUlvawopTables:test_the_seventeen_tables_keep_their_identity_and_zone()
	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local id = T.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestUlvawopTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = T.expected()

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestUlvawopTables:test_no_table_defines_a_function()
	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, FU-4: the delays of every chain, in the spec's words (M1 5 / 10 / 5, M2 8 / 8 / 5, M3 8 / 5 / 8, M4 5 / PATROL_POINT 3 at 4 / 8 / 8)
function TestUlvawopTables:test_the_split_types_and_delays_of_the_four_chains_are_the_ones_of_the_acceptance_criterion()
	local C1, P = T.SPLIT_COMPLETION, T.SPLIT_PATROL_POINT
	local want = {
		{ { C1, 5 }, { C1, 10 }, { C1, 5 } },
		{ { C1, 8 }, { C1, 8 }, { C1, 5 } },
		{ { C1, 8 }, { C1, 5 }, { C1, 8 } },
		{ { C1, 5 }, { P, 4, 3 }, { C1, 8 }, { C1, 8 } },
	}

	for m, chain in ipairs(T.CHAINS) do
		for i = 1, #want[m] do
			local q = quest(chain[i])
			local w = want[m][i]

			lu.assertEquals({ q.sideQuestSplitType, q.sideQuestDelay }, { w[1], w[2] }, chain[i] .. ": sideQuestSplitType, sideQuestDelay")

			if w[3] then
				lu.assertEquals(q.sideQuestPatrolStart, w[3], chain[i] .. ": sideQuestPatrolStart (R-5: the trigger is point 3; point 4 is never flown)")
			else
				lu.assertNil(rawget(q, "sideQuestPatrolStart"), chain[i] .. ": no patrol trigger on a COMPLETION split")
			end
		end
	end
end

-- A-2, I-6: exactly the 13 non-end tables split and name the next chain member; each child names its parent; the chain ends do not split
function TestUlvawopTables:test_exactly_the_thirteen_non_end_tables_split_and_name_the_next_chain_member()
	local splitting = 0

	for m, chain in ipairs(T.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)

			if i < #chain then
				local nid = T.IDENTITY[chain[i + 1]]

				splitting = splitting + 1
				lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, nid.type, nid.name }, global .. ": sideQuest, sideQuestType, sideQuestName (mission " .. m .. ")")
			else
				lu.assertEquals({ q.sideQuest, q.sideQuestType }, { false, "" }, global .. ": the chain end splits nothing")
				lu.assertNil(rawget(q, "sideQuestName"), global .. ": the chain end names no split")
			end

			if i > 1 then
				local pid = T.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splitting, 13, "tables with sideQuest = true")
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in order (4, 4, 4 and 5 members)
function TestUlvawopTables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(T.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-6: only delivery 3 sets deliveryZone, and no table sets pickupZone
function TestUlvawopTables:test_only_delivery_3_sets_a_delivery_zone_and_no_table_sets_a_pickup_zone()
	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertNil(rawget(q, "pickupZone"), global .. ": pickupZone")

		if global == T.M3[1] then
			lu.assertEquals({ q.questZone, rawget(q, "deliveryZone") }, { "space_lok", "space_dathomir" }, global .. ": questZone (the pickup zone), deliveryZone")
		else
			lu.assertNil(rawget(q, "deliveryZone"), global .. ": deliveryZone")
		end
	end
end

-- A-2, I-7: credits and items on the four heads only (25000 + the Source inventory item, any species)
function TestUlvawopTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local heads = {}

	for n, global in ipairs(T.HEADS) do
		heads[global] = n
	end

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), 25000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = T.ITEM_ROOT .. T.ITEMS[n] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 23 distinct ships of FU-7) and every item an object template (4)
function TestUlvawopTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
	local ships, items = {}, {}

	local function walk(value, into)
		if type(value) == "string" then
			into[value] = true
		elseif type(value) == "table" then
			for _, v in ipairs(value) do
				walk(v, into)
			end
		end
	end

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "attackShipLists", "shipList", "allyForce", "enemyForce" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "targetShipType", "deliveryShip", "pickupShip" }) do
			if rawget(q, field) then
				ships[q[field]] = true
			end
		end

		if rawget(q, "assassinateSpawns") then
			ships[q.assassinateSpawns.target] = true
			walk(q.assassinateSpawns.escorts, ships)
		end

		if rawget(q, "surpriseAttackShips") then
			for _, spawn in ipairs(q.surpriseAttackShips.spawns) do
				ships[spawn.shipName] = true
			end
		end

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end
	end

	local want = {}

	for i, s in ipairs(T.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 17 tables (FU-7)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 17 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. T.SHIP_DIR .. name .. ".lua"), T.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: recovery 1's appearance is a client mobile template the server knows
function TestUlvawopTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(quest(T.M1[1]).recoveryConversationMobile, T.DROID_MOBILE, T.M1[1] .. ": recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. T.DROID_MOBILE .. '"', 1, true), T.DROID_MOBILE .. " is not in object/mobile/objects.lua")
end

-- A-2, I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestUlvawopTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in (readFile(H.FIXTURES .. "misc/quest_crc_string_table.names") or ""):gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestUlvawopConformance = {}

function TestUlvawopConformance:setUp() H.reset() end

-- A-2, I-4, I-6: zone, split target and delay from each fixture (success: triggerDelay + 5; triggerOn patrol: PATROL_POINT, triggerDelay, point = triggerOn)
function TestUlvawopConformance:test_every_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	for _, global in ipairs(T.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

			if rec:get("triggerSplitCondition") == "success" then
				lu.assertEquals(q.sideQuestSplitType, ST.COMPLETION, l .. ": COMPLETION (triggerSplitCondition success)")
				lu.assertEquals(q.sideQuestDelay, delay + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:600)")
			else
				lu.assertEquals(rec:get("triggerSplitCondition"), "triggerOn", l .. ": precondition: the split fires on the trigger count")
				lu.assertEquals(q.questType, "patrol", l .. ": precondition: only the patrol splits on triggerOn in this tier")
				lu.assertEquals(q.sideQuestSplitType, ST.PATROL_POINT, l .. ": PATROL_POINT (triggerOn, triggerEndsMission 1)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, no +5 on a patrol split)")
			end
		else
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

local function tauntsOf(rec, fields)
	local m = rec:num("numResponses")
	local out = {}

	for _, f in ipairs(fields) do
		out[f] = m
	end

	return out
end

-- A-2, I-2, I-4: recovery 1 (Core3's recovery cycles its lists in order; SWG's random is not modelled, D-5)
function TestUlvawopConformance:test_recovery_1_maps_ships_paths_attack_lists_appearance_and_taunts()
	local q, rec = quest(T.M1[1]), fixtureOf(T.M1[1])
	local l = label(T.M1[1])

	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", realRadius), l .. ": preRecoveryPoints (escortPath, no zoneName, numbered from 1)")
	lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", realRadius), l .. ": recoveryPoints (recoveryPath, numbered from 1)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
	lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")),
		l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints, #q.attackShips, #q.escortShips }, { 6, 4, 2, 2 }, l .. ": 6 + 4 points, 2 attack lists, 2 escorts")
	lu.assertEquals({ q.arrivalDelay, q.recoveryDelay, q.attackDelay }, { 10, 30, 60 }, l .. ": delays")
	lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: random (not modelled, D-5)")
end

-- A-2, I-2, I-4: the two escorts (numResponses 5 gives 5 of each key, FU-6; escort points carry the quest zone)
function TestUlvawopConformance:test_escorts_map_ship_points_attack_lists_delay_and_taunts()
	for _, global in ipairs({ T.M1[4], T.M3[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
		lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (escortPath, zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: random, as Core3's escort")
		lu.assertEquals({ #q.attackShips, #q.escortPoints }, { 3, 4 }, l .. ": 3 attack lists, 4 points")
	end

	lu.assertEquals({ quest(T.M1[4]).attackDelay, quest(T.M3[3]).attackDelay }, { 45, 50 }, "escort 1_c and 3_b attackDelay")
end

-- A-2, I-2, I-4: inspect 2 (cargo needs SC-1 to be completable, A-3)
function TestUlvawopConformance:test_inspect_2_maps_ships_spawners_waypoint_flag_and_cargo()
	local _, spawners = buildout("space_dathomir")
	local q, rec = quest(T.M2[1]), fixtureOf(T.M2[1])
	local l = label(T.M2[1])
	local valid = {}

	for i, value in ipairs(rec:list("validSpawns")) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = spawners[spawnName]

		lu.assertNotNil(s, l .. ": the buildout excerpt has the spawner " .. spawnName)
		lu.assertEquals(zone, q.questZone, l .. ": the validSpawns zone is the quest zone")
		valid[i] = { spawnName = spawnName, x = s.x, z = s.z, y = s.y }
	end

	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(q.validSpawns, valid, l .. ": validSpawns (zone prefix dropped, buildout positions truncated)")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
	lu.assertEquals({ #q.shipList, #q.validSpawns, q.cargo }, { 4, 2, "thermal_bomb" }, l .. ": 4 ships, 2 spawners, thermal_bomb")
end

-- A-2, I-2, I-4: delivery 1_a (same zone) and delivery 3 (Lok to Dathomir): zones come from the point prefixes
function TestUlvawopConformance:test_deliveries_map_ships_points_attack_lists_period_order_and_zones()
	for _, global in ipairs({ T.M1[2], T.M3[1] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local pickupZone = H.Tab.splitNavPoint(rec:list("pickupPoint")[1])
		local deliveryZone = H.Tab.splitNavPoint(rec:list("deliveryPoint")[1])

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.pickupShip, rec:get("pickupShip"), l .. ": pickupShip")
		lu.assertEquals(q.pickupPoint, mapped(rec, "pickupPoint")[1], l .. ": pickupPoint")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")
		lu.assertEquals(pickupZone, q.questZone, l .. ": the pickup point's zone is the questZone (so no pickupZone)")
		lu.assertNil(rawget(q, "pickupZone"), l .. ": no pickupZone")

		if deliveryZone ~= q.questZone then
			lu.assertEquals(rawget(q, "deliveryZone"), deliveryZone, l .. ": deliveryZone (the deliveryPoint's zone prefix)")
		else
			lu.assertNil(rawget(q, "deliveryZone"), l .. ": single zone: no deliveryZone")
		end

		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
	end

	local three = fixtureOf(T.M3[1])

	lu.assertEquals(three:get("questZone"), "space_lok", "delivery 3: precondition questZone space_lok")
	lu.assertEquals((H.Tab.splitNavPoint(three:list("deliveryPoint")[1])), "space_dathomir", "delivery 3: precondition deliveryPoint in space_dathomir")
	lu.assertEquals(rawget(quest(T.M3[1]), "deliveryZone"), "space_dathomir", "delivery 3: deliveryZone")
	lu.assertEquals(rawget(quest(T.M1[2]), "deliveryZone"), nil, "delivery 1_a: no deliveryZone")
end

-- A-2, I-2, I-4: delivery_no_pickup 4_c
function TestUlvawopConformance:test_delivery_no_pickup_4_c_maps_ship_point_attack_lists_period_and_order()
	local q, rec = quest(T.M4[4]), fixtureOf(T.M4[4])
	local l = label(T.M4[4])

	lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
	lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")
	lu.assertNil(rawget(q, "pickupPoint"), l .. ": a delivery_no_pickup has no pickup")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
	lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
end

-- A-2, I-2, I-4: the two surprise attacks (R.runs of the SWG spawn loop replay)
function TestUlvawopConformance:test_surprise_attacks_map_ship_count_and_zone()
	for _, global in ipairs({ T.M2[2], T.M4[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = R.runs(R.replay(T.IDENTITY[global].name)) }, l .. ": surpriseAttackShips (the SWG spawn loop, zone)")
		lu.assertEquals(q.surpriseAttackShips.spawns, { { count = rec:num("shipCount"), shipName = rec:get("shipType") } }, l .. ": surpriseAttackShips spawns (shipType, shipCount)")
	end

	lu.assertEquals(quest(T.M2[2]).surpriseAttackShips, { zone = "space_dathomir", spawns = { { count = 3, shipName = "imp_tie_interceptor_tier3" } } }, "surprise 2_a")
	lu.assertEquals(quest(T.M4[3]).surpriseAttackShips, { zone = "space_endor", spawns = { { count = 3, shipName = "imp_tie_advanced_tier3" } } }, "surprise 4_b")
end

-- A-2, I-2, I-4: the patrol (laps is not mapped; R-5: point 4 is stored, never flown)
function TestUlvawopConformance:test_patrol_4_a_maps_the_four_nav_points_numbered_with_radius_150()
	local q, rec = quest(T.M4[2]), fixtureOf(T.M4[2])
	local l = label(T.M4[2])

	lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), l .. ": patrolPoints (navPoints, patrolNumber, radius 150)")
	lu.assertEquals(#q.patrolPoints, 4, l .. ": four points")
end

-- A-2, I-2, I-4: battles 2_c, 3_a and 4_d (enemyArrivalDist -200 / -100 / -150, forward from fltK*)
function TestUlvawopConformance:test_battles_map_point_forward_timers_distances_and_forces()
	local ends = { -200, -100, -150 }
	local counts = { { 3, 6 }, { 3, 8 }, { 5, 7 } }

	for i, spec in ipairs({ { T.M2[4], "space_dantooine" }, { T.M3[2], "space_dathomir" }, { T.M4[5], "space_endor" } }) do
		local global, zoneName = spec[1], spec[2]
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
		local row = buildout(zoneName)[name]

		lu.assertEquals(zone, zoneName, l .. ": battlePoint zone")
		lu.assertNotNil(row, l .. ": the buildout excerpt has " .. name)
		lu.assertEquals(q.battlePoint, { patrolPointName = name, x = row.x, z = row.z, y = row.y, forward = row.forward }, l .. ": battlePoint (nav point + fltKX/fltKY/fltKZ as forward x/z/y)")

		for _, field in ipairs({ "damageMultiplier", "allyArrivalDelay", "enemyArrivalDelay", "allyOriginDist", "enemyOriginDist", "allyArrivalDist", "enemyArrivalDist" }) do
			lu.assertEquals(q[field], rec:num(field), l .. ": " .. field)
		end

		lu.assertEquals(q.allyForce, rec:list("allyForce"), l .. ": allyForce")
		lu.assertEquals(q.enemyForce, rec:list("enemyForce"), l .. ": enemyForce (SWG order)")
		lu.assertEquals({ #q.allyForce, #q.enemyForce, q.enemyArrivalDist }, { counts[i][1], counts[i][2], ends[i] }, l .. ": allies, enemies, enemyArrivalDist")
	end
end

-- A-2, I-2, I-4: survivals 1_b and 3_c (3_c's point is escort 3_b's last point, FU-10)
function TestUlvawopConformance:test_survivals_map_point_timers_attack_lists_and_order_from_their_fixtures()
	local updates = { [T.M1[3]] = 3, [T.M3[4]] = 4 }

	for global, times in pairs(updates) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
		lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
		lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
		lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
		lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..N, column-wise)")
		lu.assertEquals(#q.attackShipLists, 3, l .. ": attack lists")
		lu.assertEquals(q.timesToUpdateProgress, times, l .. ": timesToUpdateProgress anchor")

		for i, list in ipairs(q.attackShipLists) do
			lu.assertEquals(#list, 3, l .. ": attack list " .. i .. " has three ships")
		end

		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType SEQUENTIAL")
	end

	lu.assertEquals(quest(T.M3[4]).transmissionPoint.patrolPointName, "tatooine_tier3_3_b_escort_4", "survival 3_c: transmissionPoint is escort 3_b's last point (FU-10)")
end

-- A-2, I-2, I-4: assassinates 2_b and 4 (mustDestroyEscort 0; failTimer is Core3's 20)
function TestUlvawopConformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ T.M2[3], T.M4[1] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
		lu.assertEquals(#q.targetPatrols, 6, l .. ": six path points")
	end

	lu.assertEquals({ quest(T.M2[3]).mustDestroyEscort, quest(T.M4[1]).mustDestroyEscort }, { false, false }, "assassinate 2_b and 4: mustDestroyEscort false")
	lu.assertEquals({ #quest(T.M2[3]).assassinateSpawns.escorts, #quest(T.M4[1]).assassinateSpawns.escorts }, { 3, 6 }, "assassinate 2_b and 4: 3 and 6 escorts")
	lu.assertEquals(quest(T.M2[3]).targetPatrols[1].patrolPointName, "tatooine_tier3_2_b_escape_1", "assassinate 2_b: the first path point (a space_dantooine point)")
end

---------------------------------------------------------------------------------------------
-- I-5: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestUlvawopCargo = {}

function TestUlvawopCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. T.SHIP_DIR .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/" .. T.SHIP_DIR .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- A-2, I-5, FU-3: SC-1, the four template files
function TestUlvawopCargo:test_each_suspect_template_file_carries_the_thermal_bomb_as_a_cargo_string()
	for _, ship in ipairs(T.SUSPECT_ORDER) do
		local src = templateSource(ship)

		lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), T.CARGO, ship .. ".lua cargoString must be the thermal_bomb row of inspect_cargo/" .. T.CARGO_TABLE .. " (SMT row " .. T.SUSPECTS[ship].smt .. ")")
		lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), T.CARGO_TABLE, ship .. ".lua questLoot (names the inspect_cargo table) stays")
	end
end

-- A-2, I-5: the loaded templates have it too, and the suspects keep their loot name; the Rebel decoys carry no cargo
function TestUlvawopCargo:test_the_loaded_suspect_templates_have_the_cargo_string_and_the_decoys_have_none()
	for _, ship in ipairs(T.SUSPECT_ORDER) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, T.SHIP_DIR .. ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, T.CARGO, ship .. ": cargoString")
		lu.assertEquals(t.questLoot, T.CARGO_TABLE, ship .. ": questLoot is unchanged")
	end

	for _, decoy in ipairs({ "reb_awing_tier4", "reb_bwing_tier4" }) do
		local t = H.shipTemplate(decoy)

		lu.assertNotNil(t, decoy .. " template")
		lu.assertTrue(t.cargoString == nil or t.cargoString == "", decoy .. ": no cargoString (the decoys carry no cargo, R-2), got " .. tostring(t.cargoString))
	end
end

-- A-2, I-5: the quest cargo equals each suspect's cargo string, and it is a canTransfer-1 row of the cargo table named by questLoot and SMT
function TestUlvawopCargo:test_the_quest_cargo_equals_every_suspects_cargo_string_and_is_a_transferable_row()
	local q = quest(T.M2[1])
	local rows = H.fixture("spacequest/inspect_cargo/" .. T.CARGO_TABLE .. ".tab").records
	local transferable = {}

	for _, rec in ipairs(rows) do
		if rec:num("canTransfer") == 1 then
			transferable[rec:get("name")] = true
		end
	end

	lu.assertEquals(q.shipList, T.SUSPECT_ORDER, T.M2[1] .. ": shipList")

	for _, ship in ipairs(q.shipList) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, ship .. " template")
		lu.assertEquals(q.cargo, t.cargoString, T.M2[1] .. ": the quest cargo equals " .. ship .. "'s cargoString")
		lu.assertTrue(transferable[t.cargoString] == true, ship .. ": " .. tostring(t.cargoString) .. " is a canTransfer-1 row of inspect_cargo/" .. T.CARGO_TABLE)
	end
end

return nil
