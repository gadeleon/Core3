-- Crimson Phoenix tier 2 part A (Major Eker's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (A-1, A-2; invariants I-1 .. I-8; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of crimson_tier2_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local C = require("crimson_tier1_data")
local R = require("surprise_replay")

E.load()

local function quest(global) return E.quest(global) end

local function fixtureOf(global)
	local id = E.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return E.IDENTITY[global].type .. "/" .. E.IDENTITY[global].name end

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
	space_lok = "space_zones/buildout/space_lok.crimson_tier2_points.tab",
	space_yavin4 = "space_zones/buildout/space_yavin4.crimson_tier2_points.tab",
}

local ZONES = { "space_yavin4", "space_lok" }

-- the rows of a zone's buildout excerpt: nav_name -> { x, z, y }, strSpawnerName -> { x, z, y }
local function buildout(zone)
	local tab = H.fixture(EXCERPTS[zone])
	local navs, spawners = {}, {}

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawn = vars:match("strSpawnerName|4|([^|]+)|")
		local row = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")) }

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
-- The oracle itself
---------------------------------------------------------------------------------------------

TestEkerFixtures = {}

function TestEkerFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 8 fixtures are in their zones and only inspect 15 splits
function TestEkerFixtures:test_the_eight_fixtures_are_in_their_zones_and_only_inspect_15_splits()
	for _, global in ipairs(E.GLOBALS) do
		local rec = fixtureOf(global)

		lu.assertEquals(rec:get("questZone"), E.IDENTITY[global].zone, label(global) .. ": questZone")

		if global == E.I15 then
			lu.assertEquals({ rec:get("triggerEvent"), rec:get("triggerArg") }, { "splitquest", "destroy_surpriseattack:yavin_rebel_15" }, label(global) .. ": split target")
		else
			lu.assertTrue(rec:get("triggerEvent") == nil or rec:get("triggerEvent") == "none", label(global) .. ": triggerEvent is none (or the duty tables' missing column), got " .. tostring(rec:get("triggerEvent")))
		end
	end
end

-- A-2 (the oracle itself): FC-1, the values of the split row the spec builds on
function TestEkerFixtures:test_the_split_row_carries_the_values_the_spec_lists()
	local i15 = fixtureOf(E.I15)

	lu.assertEquals({ i15:get("triggerSplitCondition"), i15:num("triggerOn"), i15:num("triggerEndsMission"), i15:num("triggerDelay"), i15:get("cargo") },
		{ "triggerOn", 1, 1, 5, "placeholder" }, "inspect/yavin_rebel_15")
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the patrol point files hold (21 nav points)
function TestEkerFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(E.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 21, "spec nav points")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points and spawners; Core3's values are their truncated values
function TestEkerFixtures:test_the_buildout_excerpts_pin_every_point_and_both_inspect_spawners()
	for _, zone in ipairs(ZONES) do
		local navs, spawners = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(E.POINTS[zone]), zone .. ": nav_name rows of the excerpt")
		lu.assertEquals(sortedKeys(spawners), sortedKeys(E.SPAWNERS[zone] or {}), zone .. ": strSpawnerName rows of the excerpt")

		for name, xyz in pairs(E.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end

		for name, xyz in pairs(E.SPAWNERS[zone] or {}) do
			lu.assertEquals({ spawners[name].x, spawners[name].z, spawners[name].y }, xyz, zone .. ": buildout truncated, spawner " .. name)
		end
	end
end

-- A-2, I-2 (the oracle itself): both inspect spawners exist in Core3's spawner tables at the spec positions and spawn their quest shuttle (directly or in a squadron)
function TestEkerFixtures:test_the_two_inspect_spawners_exist_in_the_core3_spawner_tables_and_spawn_their_shuttle()
	for zone, byName in pairs(E.SPAWNERS) do
		for name, xyz in pairs(byName) do
			local s = H.spawners(zone)[name]

			lu.assertNotNil(s, zone .. "_spawner.lua: spawner " .. name)
			lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)
		end
	end

	local function spawnsShip(zone, spawnerName, ship)
		for _, entry in ipairs(H.spawners(zone)[spawnerName].shipSpawns) do
			if entry == ship then
				return true
			end

			local squad = H.squadrons()[entry]

			for _, member in ipairs(squad and squad[2] or {}) do
				if member == ship then
					return true
				end
			end
		end

		return false
	end

	lu.assertTrue(spawnsShip("space_yavin4", "yavin_rebel_2_shuttle", "yavin_mission_2_shuttle"), "spawner yavin_rebel_2_shuttle spawns yavin_mission_2_shuttle")
	lu.assertTrue(spawnsShip("space_lok", "yavin_rebel_mission_3", "yavin_mission_3_shuttle"), "spawner yavin_rebel_mission_3 spawns yavin_mission_3_shuttle (directly or via squad_yavin_rebel_3)")
end

-- A-2, I-8 (the oracle itself): the client journal knows every quest
function TestEkerFixtures:test_the_client_quest_name_table_lists_the_eight_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(E.GLOBALS) do
		local name = "spacequest/" .. E.IDENTITY[global].type .. "/" .. E.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

-- A-2, I-5, FC-2 (the oracle itself): SWG's space_mobile cargo column names the two cargo tables; yavin_mission_2 has one transferable row, yavin_mission_3 one
-- non-transferable row (D-7), and inspect_cargo/yavin_rebel_14 (named after the quest) mirrors yavin_mission_2
function TestEkerFixtures:test_the_inspect_cargo_fixtures_and_space_mobile_name_the_two_shuttle_cargos()
	local tab = H.fixture("space_mobile/space_mobile.crimson_tier2_inspect.tab")
	local cargoOf = {}

	for _, rec in ipairs(tab.records) do
		cargoOf[rec:get("strIndex")] = rec:get("cargo")
	end

	lu.assertEquals(#tab.records, 2, "space_mobile excerpt rows (SMT 1944, 1945)")

	for ship, info in pairs(E.CARGO_SHIPS) do
		lu.assertEquals(cargoOf[ship], info.smtCargo, "space_mobile.tab cargo column of " .. ship)

		local rows = H.fixture("spacequest/inspect_cargo/" .. info.smtCargo .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. info.smtCargo .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { info.cargo, info.canTransfer }, "inspect_cargo/" .. info.smtCargo .. ".tab: name, canTransfer")
	end

	local own = H.fixture("spacequest/inspect_cargo/yavin_rebel_14.tab").records

	lu.assertEquals({ #own, own[1]:get("name"), own[1]:num("canTransfer") }, { 1, "patrol_routes", 1 }, "inspect_cargo/yavin_rebel_14.tab")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestEkerWiring = {}

function TestEkerWiring:setUp() H.reset() end

-- A-1, I-1
function TestEkerWiring:test_the_squadron_file_registers_the_eight_quests_with_start_true()
	for _, global in ipairs(E.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#E.GLOBALS, 8, "tier 2 globals")
end

-- A-1: Content contract 1 order, after the eight tier 1 globals
function TestEkerWiring:test_the_eight_quests_are_registered_in_the_contract_order_after_the_eight_tier_1_quests()
	local order = {}

	for _, global in ipairs(E.TIER1_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(E.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 16, "8 tier 1 + 8 tier 2 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1: the squadron object has the eight constants and the reset; every earlier field is unchanged
function TestEkerWiring:test_the_squadron_screenplay_has_the_eight_constants_the_reset_and_every_earlier_field()
	local sq = E.squadron()

	for field, want in pairs(E.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field)
	end

	lu.assertEquals(#E.QUEST_STRING_FIELDS, 8, "constants")

	for field, want in pairs(C.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.EKER_PILOT_KEY, E.EKER_PILOT_KEY, "EKER_PILOT_KEY unchanged")
	lu.assertEquals(type(sq.resetSocunaQuests), "function", "resetSocunaQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetEkerQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetEkerQuests (Content contract 2). Load problems: " .. E.problems())
	lu.assertEquals(pcall(sq.resetEkerQuests, sq, nil), true, "resetEkerQuests(nil) returns early")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestEkerTables = {}

function TestEkerTables:setUp() H.reset() end

-- A-2, I-1
function TestEkerTables:test_the_eight_tables_keep_their_identity_and_zone()
	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local id = E.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestEkerTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = E.expected()

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestEkerTables:test_no_table_defines_a_function()
	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-6: exactly inspect 15 (INSPECTION, count 1, delay 5) splits; surprise 15 names it as its parent and nothing else has a parent
function TestEkerTables:test_exactly_inspect_15_splits_and_surprise_15_names_it_as_its_parent()
	local splitting = {}

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)

		if q.sideQuest then
			splitting[#splitting + 1] = global
		else
			lu.assertEquals(q.sideQuestType, "", global .. ": no split type")
			lu.assertNil(rawget(q, "sideQuestName"), global .. ": names no split")
		end

		if global == E.S15 then
			lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { E.I15, "inspect", "yavin_rebel_15" }, global .. ": parent fields")
		else
			lu.assertNil(rawget(q, "parentQuest"), global .. ": has no parent")
		end
	end

	lu.assertEquals(splitting, { E.I15 }, "the tables with sideQuest = true")
	lu.assertEquals({ quest(E.I15).sideQuestType, quest(E.I15).sideQuestName, quest(E.I15).sideQuestSplitType, quest(E.I15).sideQuestInspectCount, quest(E.I15).sideQuestDelay },
		{ "destroy_surpriseattack", "yavin_rebel_15", 6, 1, 5 }, "inspect 15: split to surprise 15, INSPECTION, count 1, 5 s (FC-1)")
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks mission 3 in order and returns every other head alone
function TestEkerTables:test_get_space_quest_chain_returns_mission_3_in_order_and_the_other_heads_themselves()
	for n, chain in ipairs(E.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-7: credits and items on the four heads only; the three duties carry their .tab reward and no item
function TestEkerTables:test_credits_and_items_sit_on_the_four_mission_heads_only_and_the_duties_pay_their_reward()
	local heads = { [E.E13] = 1, [E.I14] = 2, [E.I15] = 3, [E.E16] = 4 }
	local duties = { [E.DUTY12] = 2500, [E.DUTY10] = 2500, [E.DUTY9] = 200 }

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), 5000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = E.ITEM_ROOT .. E.ITEMS[n] } }, global .. ": itemReward (any species)")
		elseif duties[global] then
			lu.assertEquals(rawget(q, "creditReward"), duties[global], global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward (surprise 15 is the chain end: no reward)")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 16 distinct ships of FC-6) and every item an object template (4)
function TestEkerTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "shipTypes", "recoverShips" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "bossShip" }) do
			if rawget(q, field) then
				ships[q[field]] = true
			end
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

	for i, s in ipairs(E.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 8 tables (FC-6)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 8 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. E.SHIP_DIR .. name .. ".lua"), E.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: the recovery appearance is a client template the server knows
function TestEkerTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(quest(E.DUTY12).recoveryConversationMobile, E.DROID_MOBILE, E.DUTY12 .. ": recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. E.DROID_MOBILE .. '"', 1, true), E.DROID_MOBILE .. " is not in object/mobile/objects.lua")
end

-- A-2, I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestEkerTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in readFile(H.FIXTURES .. "misc/quest_crc_string_table.names"):gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestEkerConformance = {}

function TestEkerConformance:setUp() H.reset() end

-- A-2, I-4, I-6: zone, split target and delay from each fixture (triggerOn inspect: triggerDelay, count = triggerOn)
function TestEkerConformance:test_every_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	for _, global in ipairs(E.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")
			lu.assertEquals(rec:get("triggerSplitCondition"), "triggerOn", l .. ": precondition: the split fires on the trigger count")
			lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION, l .. ": INSPECTION (triggerOn, triggerEndsMission 1)")
			lu.assertEquals(q.sideQuestInspectCount, rec:num("triggerOn"), l .. ": sideQuestInspectCount (triggerOn)")
			lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, inspect.java:268 keeps it)")
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

-- A-2, I-4: the two escorts and the escort duty (FC-8: numResponses 5 gives 5 of each key; FC-4 the lossy lists)
function TestEkerConformance:test_escorts_map_ship_points_attack_lists_delay_and_taunts()
	for _, global in ipairs({ E.E13, E.E16, E.DUTY10 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local duty = E.IDENTITY[global].type == "escort_duty"
		local ships = duty and rec:list("escortShipTypes") or { rec:get("escortShipType") }
		local pathColumn = duty and "escortPoints" or "escortPath"

		lu.assertEquals(q.escortShips, ships, l .. ": escortShips (escortShipType / escortShipTypes)")
		lu.assertEquals(q.escortPoints, mapped(rec, pathColumn, function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (" .. pathColumn .. ", zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	end

	-- FC-4: escorts 13 and 16 are sequential with two lists (Core3's escort draws at random: lossy), escort duty 10 is random (as Core3)
	lu.assertEquals(fixtureOf(E.E13):get("attackListType"), "sequential", "escort 13: precondition: sequential")
	lu.assertEquals(fixtureOf(E.E16):get("attackListType"), "sequential", "escort 16: precondition: sequential")
	lu.assertEquals(fixtureOf(E.DUTY10):get("attackListType"), "random", "escort duty 10: precondition: random")
	lu.assertEquals({ #quest(E.E13).escortPoints, #quest(E.E13).attackShips, quest(E.E13).attackDelay }, { 4, 2, 80 }, "escort 13: 4 points, 2 attack lists, 80 s")
	lu.assertEquals({ #quest(E.E16).escortPoints, #quest(E.E16).attackShips, quest(E.E16).attackDelay }, { 4, 2, 70 }, "escort 16: 4 points, 2 attack lists, 70 s")
	lu.assertEquals({ #quest(E.DUTY10).escortShips, #quest(E.DUTY10).escortPoints, #quest(E.DUTY10).attackShips }, { 5, 5, 3 }, "escort duty 10: 5 ships (the duplicate kept, FC-7), 5 points, 3 lists")
	lu.assertEquals(quest(E.DUTY10).escortShips[4], quest(E.DUTY10).escortShips[5], "escort duty 10: reb_ykl37r_tier2 listed twice (D-4)")
	lu.assertEquals({ quest(E.DUTY10).creditReward, quest(E.DUTY10).creditKillBonus }, { fixtureOf(E.DUTY10):num("reward"), fixtureOf(E.DUTY10):num("killReward") }, "escort duty 10: reward and killReward")
	lu.assertEquals({ quest(E.DUTY10).creditReward, quest(E.DUTY10).creditKillBonus }, { 2500, 200 }, "escort duty 10: 2500 / 200")
end

-- A-2, I-2, I-4: recovery duty 12 (`sequential`, as Core3's recovery cycle)
function TestEkerConformance:test_recovery_duty_12_maps_ships_paths_attack_lists_appearance_and_taunts()
	local q, rec = quest(E.DUTY12), fixtureOf(E.DUTY12)
	local l = label(E.DUTY12)

	lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), l .. ": recoverShips (targetShipTypes)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", realRadius), l .. ": preRecoveryPoints (escortPath, no zoneName, numbered from 1)")
	lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", realRadius), l .. ": recoveryPoints (recoveryPath, renumbered from 1)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
	lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")),
		l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": reward and killReward")
	lu.assertEquals({ #q.recoverShips, #q.escortShips, #q.preRecoveryPoints, #q.recoveryPoints }, { 3, 2, 4, 4 }, l .. ": 3 recover ships, 2 escorts, 4 + 4 points")
	lu.assertEquals({ q.creditReward, q.creditKillBonus }, { 2500, 200 }, l .. ": 2500 / 200")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential, as Core3's recovery")
end

-- A-2, I-2, I-4: the two inspects (inspect 15's cargo is SWG's literal `placeholder`)
function TestEkerConformance:test_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	for _, global in ipairs({ E.I14, E.I15 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
		local _, spawners = buildout(zone)
		local s = spawners[spawnName]

		lu.assertNotNil(s, l .. ": the buildout excerpt has the spawner " .. spawnName)
		lu.assertEquals(zone, q.questZone, l .. ": the validSpawns zone is the quest zone")
		lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
		lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns (zone prefix dropped, buildout position truncated)")
		lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
		lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
	end

	lu.assertEquals(quest(E.I14).cargo, "patrol_routes", "inspect 14: cargo")
	lu.assertEquals(quest(E.I15).cargo, "placeholder", "inspect 15: cargo is SWG's literal placeholder (FC-1)")
end

-- A-2, I-4: surprise 15 (R.runs of the SWG spawn loop replay)
function TestEkerConformance:test_surprise_15_maps_ship_count_and_zone()
	local q, rec = quest(E.S15), fixtureOf(E.S15)

	lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = R.runs(R.replay("yavin_rebel_15")) }, "surprise 15: surpriseAttackShips (the SWG spawn loop, zone)")
	lu.assertEquals(q.surpriseAttackShips.spawns, { { count = 3, shipName = "imp_tie_interceptor_tier2" } }, "surprise 15: 3 imp_tie_interceptor_tier2")
	lu.assertEquals(q.surpriseAttackShips.zone, "space_lok", "surprise 15: zone")
end

-- A-2, I-4: destroy duty 9 (one list, so Core3's shipTypes[1] rule loses nothing)
function TestEkerConformance:test_destroy_duty_9_maps_levels_rounds_waves_ship_list_boss_and_reward()
	local q, rec = quest(E.DUTY9), fixtureOf(E.DUTY9)
	local lists = {}

	for i = 1, rec:num("shipTypes") do
		lists[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), "destroy duty 9: totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), "destroy duty 9: totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), "destroy duty 9: totalLevels (levelsPerDuty)")
	lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { 1, 4, 5 }, "destroy duty 9: 1 / 4 / 5")
	lu.assertEquals(q.shipTypes, lists, "destroy duty 9: shipTypes (shipType1..shipTypes, column-wise)")
	lu.assertEquals(#q.shipTypes, 1, "destroy duty 9: one Hutt ship list")
	lu.assertEquals(#q.shipTypes[1], 3, "destroy duty 9: 3 ships in the list")
	lu.assertEquals(q.bossShip, rec:get("bossType"), "destroy duty 9: bossShip (bossType)")
	lu.assertEquals(q.creditReward, rec:num("reward"), "destroy duty 9: creditReward (reward)")
	lu.assertEquals(q.creditReward, 200, "destroy duty 9: 200")
end

---------------------------------------------------------------------------------------------
-- I-5: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestEkerCargo = {}

function TestEkerCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. E.SHIP_DIR .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/" .. E.SHIP_DIR .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- A-2, I-5, FC-2: SC-1
function TestEkerCargo:test_each_inspect_shuttle_template_file_carries_the_swg_cargo_as_a_cargo_string()
	for ship, info in pairs(E.CARGO_SHIPS) do
		lu.assertEquals(quest(info.quest).shipList, { ship }, info.quest .. ": shipList")

		local src = templateSource(ship)

		lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), info.cargo, ship .. ".lua cargoString must be the inspect_cargo row of SWG's space_mobile cargo column " .. info.smtCargo .. " (SMT row " .. info.smt .. ")")
		lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), info.smtCargo, ship .. ".lua questLoot (names the inspect_cargo table) stays")
	end
end

-- A-2, I-5: the loaded templates have it too, and the shuttles stay non-aggressive
function TestEkerCargo:test_the_loaded_shuttle_templates_have_the_cargo_string_and_keep_their_loot_name()
	for ship, info in pairs(E.CARGO_SHIPS) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, E.SHIP_DIR .. ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, info.cargo, ship .. ": cargoString")
		lu.assertEquals(t.questLoot, info.smtCargo, ship .. ": questLoot is unchanged")
		lu.assertEquals(t.aggressive, 0, ship .. ": aggressive is unchanged")
	end
end

-- A-2, I-5: inspect 14's cargo equals its shuttle's cargo string; inspect 15's quest cargo deliberately does not (FC-1)
function TestEkerCargo:test_inspect_14_cargo_equals_its_shuttles_cargo_and_inspect_15_deliberately_differs()
	local s2 = H.shipTemplate("yavin_mission_2_shuttle")
	local s3 = H.shipTemplate("yavin_mission_3_shuttle")

	lu.assertNotNil(s2, "yavin_mission_2_shuttle template")
	lu.assertNotNil(s3, "yavin_mission_3_shuttle template")
	lu.assertEquals(quest(E.I14).cargo, s2.cargoString, "inspect 14: the quest cargo equals the shuttle's cargoString")
	lu.assertEquals(s3.cargoString, "bomb_trigger", "yavin_mission_3_shuttle: cargoString (IC/yavin_mission_3, canTransfer 0, D-7)")
	lu.assertNotEquals(quest(E.I15).cargo, s3.cargoString, "inspect 15: the quest cargo 'placeholder' differs from the shuttle's cargo (FC-1)")
end

return nil
