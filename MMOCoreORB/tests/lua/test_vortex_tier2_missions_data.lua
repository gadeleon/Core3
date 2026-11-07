-- Vortex tier 2 part A (Brother Vrovel's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (A-1, A-2; invariants I-1 .. I-8; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of vortex_tier2_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local V1 = require("vortex_tier1_data")
local R = require("surprise_replay")

V.load()

local function quest(global) return V.quest(global) end

local function fixtureOf(global)
	local id = V.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return V.IDENTITY[global].type .. "/" .. V.IDENTITY[global].name end

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
	space_lok = "space_zones/buildout/space_lok.vortex_tier2_points.tab",
	space_yavin4 = "space_zones/buildout/space_yavin4.vortex_tier2_points.tab",
	space_dantooine = "space_zones/buildout/space_dantooine.vortex_tier2_points.tab",
}

local ZONES = { "space_lok", "space_yavin4", "space_dantooine" }

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

TestVrovelFixtures = {}

function TestVrovelFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 9 fixtures are in their zones and only escort 1 and inspect 1 split
function TestVrovelFixtures:test_the_nine_fixtures_are_in_their_zones_and_only_escort_1_and_inspect_1_split()
	for _, global in ipairs(V.GLOBALS) do
		local rec = fixtureOf(global)

		lu.assertEquals(rec:get("questZone"), V.IDENTITY[global].zone, label(global) .. ": questZone")

		if global == V.E1 then
			lu.assertEquals({ rec:get("triggerEvent"), rec:get("triggerArg") }, { "splitquest", "inspect:vortex_mission_1" }, label(global) .. ": split target")
		elseif global == V.I1 then
			lu.assertEquals({ rec:get("triggerEvent"), rec:get("triggerArg") }, { "splitquest", "destroy_surpriseattack:vortex_mission_1" }, label(global) .. ": split target")
		else
			lu.assertTrue(rec:get("triggerEvent") == nil or rec:get("triggerEvent") == "none", label(global) .. ": triggerEvent is none (or the duty tables' missing column), got " .. tostring(rec:get("triggerEvent")))
		end
	end
end

-- A-2 (the oracle itself): FV-1 and FV-2, the values of the two split rows the spec builds on
function TestVrovelFixtures:test_the_two_split_rows_carry_the_values_the_spec_lists()
	local e1 = fixtureOf(V.E1)

	lu.assertEquals({ e1:get("triggerSplitCondition"), e1:num("triggerOn"), e1:num("triggerEndsMission"), e1:num("triggerDelay"), e1:num("destroyIsSuccess") },
		{ "success", 1, 1, 3, 0 }, "escort/vortex_mission_1")

	local i1 = fixtureOf(V.I1)

	lu.assertEquals({ i1:get("triggerSplitCondition"), i1:num("triggerOn"), i1:num("triggerEndsMission"), i1:num("triggerDelay"), i1:get("cargo") },
		{ "triggerOn", 1, 1, 2, "placeholder" }, "inspect/vortex_mission_1")
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the patrol point files hold (29 nav points)
function TestVrovelFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(V.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 29, "spec nav points")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points and spawners; Core3's values are their truncated values
function TestVrovelFixtures:test_the_buildout_excerpts_pin_every_point_and_both_inspect_spawners()
	for _, zone in ipairs(ZONES) do
		local navs, spawners = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(V.POINTS[zone]), zone .. ": nav_name rows of the excerpt")
		lu.assertEquals(sortedKeys(spawners), sortedKeys(V.SPAWNERS[zone] or {}), zone .. ": strSpawnerName rows of the excerpt")

		for name, xyz in pairs(V.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end

		for name, xyz in pairs(V.SPAWNERS[zone] or {}) do
			lu.assertEquals({ spawners[name].x, spawners[name].z, spawners[name].y }, xyz, zone .. ": buildout truncated, spawner " .. name)
		end
	end
end

-- A-2, I-2 (the oracle itself): both inspect spawners exist in Core3's spawner tables at the spec positions and spawn only their quest ship
function TestVrovelFixtures:test_the_two_inspect_spawners_exist_in_the_core3_spawner_tables_with_only_their_quest_ship()
	for zone, byName in pairs(V.SPAWNERS) do
		for name, xyz in pairs(byName) do
			local s = H.spawners(zone)[name]

			lu.assertNotNil(s, zone .. "_spawner.lua: spawner " .. name)
			lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)
		end
	end

	lu.assertEquals(H.spawners("space_lok").vortex_mission_1_shuttle.shipSpawns, { "vortex_mission_1_shuttle" }, "spawner ships vortex_mission_1_shuttle")
	lu.assertEquals(H.spawners("space_dantooine").vortex_mission_4_shuttle.shipSpawns, { "squad_vortex_mission_4" }, "spawner ships vortex_mission_4_shuttle (a squadron: shuttle and 3 guards)")
end

-- A-2, I-8 (the oracle itself): the client journal knows every quest
function TestVrovelFixtures:test_the_client_quest_name_table_lists_the_nine_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(V.GLOBALS) do
		local name = "spacequest/" .. V.IDENTITY[global].type .. "/" .. V.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

-- A-2, I-5, D-1 (the oracle itself): the two inspect_cargo tables are one canTransfer-1 row each, and SWG's space_mobile cargo column names them
function TestVrovelFixtures:test_the_two_inspect_cargo_fixtures_have_one_transferable_row_and_space_mobile_names_them()
	local tab = H.fixture("space_mobile/space_mobile.vortex_tier2_inspect.tab")
	local cargoOf = {}

	for _, rec in ipairs(tab.records) do
		cargoOf[rec:get("strIndex")] = rec:get("cargo")
	end

	lu.assertEquals(#tab.records, 2, "space_mobile excerpt rows (SMT 1903, 1906)")

	for ship, info in pairs(V.CARGO_SHIPS) do
		lu.assertEquals(cargoOf[ship], info.smtCargo, "space_mobile.tab cargo column of " .. ship)

		local rows = H.fixture("spacequest/inspect_cargo/" .. info.smtCargo .. ".tab").records
		local transferable = {}

		for _, rec in ipairs(rows) do
			if rec:num("canTransfer") == 1 then
				transferable[#transferable + 1] = rec:get("name")
			end
		end

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. info.smtCargo .. ".tab rows")
		lu.assertEquals(transferable, { info.cargo }, "the rows with canTransfer 1 in inspect_cargo/" .. info.smtCargo .. ".tab")
	end
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestVrovelWiring = {}

function TestVrovelWiring:setUp() H.reset() end

-- A-1, I-1
function TestVrovelWiring:test_the_squadron_file_registers_the_nine_quests_with_start_true()
	for _, global in ipairs(V.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#V.GLOBALS, 9, "tier 2 globals")
end

-- A-1: Content contract 1 order, after the eight tier 1 globals
function TestVrovelWiring:test_the_nine_quests_are_registered_in_the_contract_order_after_the_eight_tier_1_quests()
	local order = {}

	for _, global in ipairs(V.TIER1_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(V.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 17, "8 tier 1 + 9 tier 2 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1: the squadron object has the nine constants and the reset; every earlier field is unchanged
function TestVrovelWiring:test_the_squadron_screenplay_has_the_nine_constants_the_reset_and_every_earlier_field()
	local sq = V.squadron()

	for field, want in pairs(V.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field)
	end

	lu.assertEquals(#V.QUEST_STRING_FIELDS, 9, "constants")

	for field, want in pairs(V1.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.VORTEX_PILOT_KEY, V.VORTEX_PILOT_KEY, "VORTEX_PILOT_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_IMP_ASKING_KEY, "VortexSquadronScreenplay:kiizeteImpIsAsking", "KIIZETE_IMP_ASKING_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_Q1_DISCUSSED_KEY, "VortexSquadronScreenplay:kiizeteQ1Discussed", "KIIZETE_Q1_DISCUSSED_KEY unchanged")
	lu.assertEquals(type(sq.resetV3fxQuests), "function", "resetV3fxQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.hasKiizeteFlag), "function", "hasKiizeteFlag (unchanged)")
	lu.assertEquals(type(sq.resetVrovelQuests), "function", "VortexSquadronScreenplay:resetVrovelQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetVrovelQuests, sq, nil), true, "resetVrovelQuests(nil) returns early")
end

-- A-1, SC-1: the shared quest logic and the inspect type know the new split type and its default
function TestVrovelWiring:test_space_quest_logic_has_the_inspection_split_type_after_attack_wave_and_a_zero_default()
	quest(V.I1)

	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	lu.assertEquals({ ST.NONE, ST.COMPLETION, ST.FAILURE, ST.BIDIRECTIONAL, ST.PATROL_POINT, ST.ATTACK_WAVE }, { 0, 1, 2, 3, 4, 5 }, "the existing split types keep their values")
	lu.assertEquals(ST.INSPECTION, 6, "SIDE_QUEST_SPLIT_TYPES.INSPECTION")
	lu.assertEquals(SpaceQuestLogic.sideQuestInspectCount, 0, "SpaceQuestLogic.sideQuestInspectCount default")
	lu.assertEquals(SpaceInspectScreenplay.sideQuestInspectCount, 0, "an inspect table inherits the default 0")
	lu.assertEquals(type(SpaceInspectScreenplay.countInspection), "function", "SpaceInspectScreenplay:countInspection")
	lu.assertEquals(type(SpaceInspectScreenplay.triggerInspectionSplit), "function", "SpaceInspectScreenplay:triggerInspectionSplit")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestVrovelTables = {}

function TestVrovelTables:setUp() H.reset() end

-- A-2, I-1
function TestVrovelTables:test_the_nine_tables_keep_their_identity_and_zone()
	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)
		local id = V.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestVrovelTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = V.expected()

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestVrovelTables:test_no_table_defines_a_function()
	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-6: exactly escort 1 (COMPLETION, 8) and inspect 1 (INSPECTION, count 1, delay 2) split; each child names its parent
function TestVrovelTables:test_exactly_escort_1_and_inspect_1_split_and_each_child_names_its_parent()
	local splitting = {}

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)

		if q.sideQuest then
			splitting[#splitting + 1] = global
		else
			lu.assertEquals(q.sideQuestType, "", global .. ": no split type")
			lu.assertNil(rawget(q, "sideQuestName"), global .. ": names no split")
		end
	end

	lu.assertEquals(splitting, { V.E1, V.I1 }, "the tables with sideQuest = true")
	lu.assertEquals({ quest(V.E1).sideQuestType, quest(V.E1).sideQuestName, quest(V.E1).sideQuestSplitType, quest(V.E1).sideQuestDelay },
		{ "inspect", "vortex_mission_1", 1, 8 }, "escort 1: split to inspect 1, COMPLETION, 8 s (FV-1: triggerDelay 3 + 5)")
	lu.assertEquals({ quest(V.I1).sideQuestType, quest(V.I1).sideQuestName, quest(V.I1).sideQuestSplitType, quest(V.I1).sideQuestInspectCount, quest(V.I1).sideQuestDelay },
		{ "destroy_surpriseattack", "vortex_mission_1", 6, 1, 2 }, "inspect 1: split to surprise 1, INSPECTION, count 1, 2 s (FV-2)")

	local parents = { [V.I1] = V.E1, [V.S1] = V.I1 }

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)

		if parents[global] then
			local pid = V.IDENTITY[parents[global]]

			lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { parents[global], pid.type, pid.name }, global .. ": parent fields")
		else
			lu.assertNil(rawget(q, "parentQuest"), global .. ": has no parent")
		end
	end
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks mission 1 in order and returns every other head alone
function TestVrovelTables:test_get_space_quest_chain_returns_mission_1_in_order_and_the_other_heads_themselves()
	for n, chain in ipairs(V.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-7: credits and items on the four heads only; the three duties carry their .tab reward and no item
function TestVrovelTables:test_credits_and_items_sit_on_the_four_mission_heads_only_and_the_duties_pay_their_reward()
	local heads = { [V.E1] = 1, [V.E2] = 2, [V.R3] = 3, [V.I4] = 4 }
	local duties = { [V.DUTY5] = 2500, [V.DUTY6] = 200, [V.DUTY7] = 2500 }

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), 5000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = V.ITEM_ROOT .. V.ITEMS[n] } }, global .. ": itemReward (any species)")
		else
			lu.assertEquals(rawget(q, "creditReward"), duties[global], global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 15 distinct ships of FV-6) and every item an object template (4)
function TestVrovelTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(V.GLOBALS) do
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

	for i, s in ipairs(V.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 9 tables (FV-6)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 9 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. V.SHIP_DIR .. name .. ".lua"), V.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: both recovery appearances are client templates the server knows
function TestVrovelTables:test_the_recovery_appearances_are_known_client_mobile_templates()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")

	for global, want in pairs({ [V.R3] = V.PRISONER_MOBILE, [V.DUTY7] = V.DROID_MOBILE }) do
		lu.assertEquals(quest(global).recoveryConversationMobile, want, global .. ": recoveryConversationMobile")
		lu.assertNotNil(text:find('"' .. want .. '"', 1, true), want .. " is not in object/mobile/objects.lua")
	end
end

-- A-2, I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestVrovelTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in readFile(H.FIXTURES .. "misc/quest_crc_string_table.names"):gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestVrovelConformance = {}

function TestVrovelConformance:setUp() H.reset() end

-- A-2, I-4, I-6: zone, split target and delay from each fixture (success: triggerDelay + 5; triggerOn inspect: triggerDelay, count = triggerOn)
function TestVrovelConformance:test_every_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	for _, global in ipairs(V.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

			if rec:get("triggerSplitCondition") == "success" then
				lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, l .. ": COMPLETION (triggerSplitCondition success)")
				lu.assertEquals(q.sideQuestDelay, delay + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:600)")
			else
				lu.assertEquals(rec:get("triggerSplitCondition"), "triggerOn", l .. ": precondition: the split fires on the trigger count")
				lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION, l .. ": INSPECTION (triggerOn, triggerEndsMission 1)")
				lu.assertEquals(q.sideQuestInspectCount, rec:num("triggerOn"), l .. ": sideQuestInspectCount (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, inspect.java:268 keeps it)")
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

-- A-2, I-4: the three escorts and the escort duty (FV-8: numResponses 5 gives 5 of each key)
function TestVrovelConformance:test_escorts_map_ship_points_attack_lists_delay_and_taunts()
	for _, global in ipairs({ V.E1, V.E2, V.DUTY5 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local ships = V.IDENTITY[global].type == "escort_duty" and rec:list("escortShipTypes") or { rec:get("escortShipType") }
		local pathColumn = V.IDENTITY[global].type == "escort_duty" and "escortPoints" or "escortPath"

		lu.assertEquals(q.escortShips, ships, l .. ": escortShips (escortShipType / escortShipTypes)")
		lu.assertEquals(q.escortPoints, mapped(rec, pathColumn, function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (" .. pathColumn .. ", zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	end

	-- FV-5: escort 1 is sequential with one list (a random pick cannot differ); escort 2 and escort duty 5 are random, as Core3's escort
	lu.assertEquals(fixtureOf(V.E1):get("attackListType"), "sequential", "escort 1: precondition: sequential")
	lu.assertEquals(fixtureOf(V.E2):get("attackListType"), "random", "escort 2: precondition: random")
	lu.assertEquals(fixtureOf(V.DUTY5):get("attackListType"), "random", "escort duty 5: precondition: random")
	lu.assertEquals(#quest(V.E1).attackShips, 1, "escort 1: one attack list")
	lu.assertEquals(quest(V.E1).attackShips[1], { "corsair_raider_tier2", "corsair_raider_tier2" }, "escort 1: the one list is two corsair raiders")

	for _, global in ipairs({ V.E2, V.DUTY5 }) do
		lu.assertEquals(#quest(global).attackShips, 3, global .. ": three attack lists")
	end

	lu.assertEquals({ quest(V.DUTY5).creditReward, quest(V.DUTY5).creditKillBonus }, { 2500, 200 }, "escort duty 5: reward and killReward")
	lu.assertEquals({ fixtureOf(V.DUTY5):num("reward"), fixtureOf(V.DUTY5):num("killReward") }, { 2500, 200 }, "escort duty 5: the fixture's reward and killReward")
end

-- A-2, I-2, I-4: recovery 3 and recovery duty 7 (Core3's recovery cycles its lists in order; duty 7's `random` is lossy, FV-5)
function TestVrovelConformance:test_recoveries_map_ships_paths_attack_lists_appearance_and_taunts()
	for _, global in ipairs({ V.R3, V.DUTY7 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local shipColumn = global == V.R3 and "targetShipType" or "targetShipTypes"

		if global == V.R3 then
			lu.assertEquals(q.recoverShip, rec:get(shipColumn), l .. ": recoverShip (targetShipType)")
		else
			lu.assertEquals(q.recoverShips, rec:list(shipColumn), l .. ": recoverShips (targetShipTypes)")
		end

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
	end

	lu.assertEquals({ #quest(V.R3).preRecoveryPoints, #quest(V.R3).recoveryPoints, #quest(V.R3).attackShips }, { 4, 3, 3 }, "recovery 3: 4 + 3 points, 3 attack lists")
	lu.assertEquals({ #quest(V.DUTY7).preRecoveryPoints, #quest(V.DUTY7).recoveryPoints, #quest(V.DUTY7).attackShips }, { 5, 3, 2 }, "recovery duty 7: 5 + 3 points, 2 attack lists")
	lu.assertEquals(fixtureOf(V.R3):get("attackListType"), "sequential", "recovery 3: precondition: sequential, as Core3's recovery")
	lu.assertEquals(quest(V.DUTY7).numResponses, fixtureOf(V.DUTY7):num("numResponses"), "recovery duty 7: numResponses")
	lu.assertNil(rawget(quest(V.R3), "numResponses"), "recovery 3: numResponses is not set (tauntData only)")
	lu.assertEquals({ quest(V.DUTY7).creditReward, quest(V.DUTY7).creditKillBonus }, { fixtureOf(V.DUTY7):num("reward"), fixtureOf(V.DUTY7):num("killReward") }, "recovery duty 7: reward and killReward")
end

-- A-2, I-2, I-4: the two inspects (inspect 1's cargo is SWG's literal `placeholder`)
function TestVrovelConformance:test_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	for _, global in ipairs({ V.I1, V.I4 }) do
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

	lu.assertEquals(quest(V.I1).cargo, "placeholder", "inspect 1: cargo is SWG's literal placeholder (FV-2)")
	lu.assertEquals(quest(V.I4).cargo, "ship_starting_coordinates", "inspect 4: cargo")
end

-- A-2, I-4: surprise 1 (R.runs of the SWG spawn loop replay)
function TestVrovelConformance:test_surprise_1_maps_ship_count_and_zone()
	local q, rec = quest(V.S1), fixtureOf(V.S1)

	lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = R.runs(R.replay("vortex_mission_1")) }, "surprise 1: surpriseAttackShips (the SWG spawn loop, zone)")
	lu.assertEquals(q.surpriseAttackShips.spawns, { { count = 2, shipName = "imp_tie_interceptor_tier2" } }, "surprise 1: 2 imp_tie_interceptor_tier2")
end

-- A-2, I-4: destroy duty 6 (Core3's wave picker draws from shipTypes[1] only; the other lists are stored, R-4)
function TestVrovelConformance:test_destroy_duty_6_maps_levels_rounds_waves_ship_lists_boss_and_reward()
	local q, rec = quest(V.DUTY6), fixtureOf(V.DUTY6)
	local lists = {}

	for i = 1, rec:num("shipTypes") do
		lists[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), "destroy duty 6: totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), "destroy duty 6: totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), "destroy duty 6: totalLevels (levelsPerDuty)")
	lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { 3, 2, 5 }, "destroy duty 6: 3 / 2 / 5")
	lu.assertEquals(q.shipTypes, lists, "destroy duty 6: shipTypes (shipType1..shipTypes, column-wise)")
	lu.assertEquals(#q.shipTypes, 3, "destroy duty 6: 3 ship lists")
	lu.assertEquals(q.bossShip, rec:get("bossType"), "destroy duty 6: bossShip (bossType)")
	lu.assertEquals(q.creditReward, rec:num("reward"), "destroy duty 6: creditReward (reward)")
end

---------------------------------------------------------------------------------------------
-- I-5: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestVrovelCargo = {}

function TestVrovelCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. V.SHIP_DIR .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/" .. V.SHIP_DIR .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- A-2, I-5, FV-3: SC-2
function TestVrovelCargo:test_each_inspect_shuttle_template_file_carries_the_swg_cargo_as_a_cargo_string()
	for ship, info in pairs(V.CARGO_SHIPS) do
		lu.assertEquals(quest(info.quest).shipList, { ship }, info.quest .. ": shipList")

		local src = templateSource(ship)

		lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), info.cargo, ship .. ".lua cargoString must be the inspect_cargo row of SWG's space_mobile cargo column " .. info.smtCargo .. " (SMT row " .. info.smt .. ")")
		lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), info.smtCargo, ship .. ".lua questLoot (names the inspect_cargo table) stays")
	end
end

-- A-2, I-5: the loaded templates have it too, and the shuttles stay non-aggressive
function TestVrovelCargo:test_the_loaded_shuttle_templates_have_the_cargo_string_and_keep_their_loot_name()
	for ship, info in pairs(V.CARGO_SHIPS) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, V.SHIP_DIR .. ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, info.cargo, ship .. ": cargoString")
		lu.assertEquals(t.questLoot, info.smtCargo, ship .. ": questLoot is unchanged")
		lu.assertEquals(t.aggressive, 0, ship .. ": aggressive is unchanged")
	end
end

-- A-2, I-5: inspect 4's cargo equals its shuttle's cargo string; inspect 1's quest cargo deliberately does not (FV-2)
function TestVrovelCargo:test_inspect_4_cargo_equals_its_shuttles_cargo_and_inspect_1_deliberately_differs()
	local s4 = H.shipTemplate("vortex_mission_4_shuttle")
	local s1 = H.shipTemplate("vortex_mission_1_shuttle")

	lu.assertNotNil(s4, "vortex_mission_4_shuttle template")
	lu.assertNotNil(s1, "vortex_mission_1_shuttle template")
	lu.assertEquals(quest(V.I4).cargo, s4.cargoString, "inspect 4: the quest cargo equals the shuttle's cargoString")
	lu.assertEquals(s1.cargoString, "ship_signature_data", "vortex_mission_1_shuttle: cargoString (IC/vortex_mission_1)")
	lu.assertNotEquals(quest(V.I1).cargo, s1.cargoString, "inspect 1: the quest cargo 'placeholder' differs from the shuttle's cargo (FV-2)")
end

return nil
