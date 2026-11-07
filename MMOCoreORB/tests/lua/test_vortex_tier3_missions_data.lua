-- Vortex tier 3 part A (Brother Ezkiel's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/vortex-tier3-ezkiel-missions/01-spec.md (A-1, A-2, A-3; invariants I-1 .. I-8; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of vortex_tier3_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local V1 = require("vortex_tier1_data")
local V2 = require("vortex_tier2_data")
local R = require("surprise_replay")

W.load()

local function quest(global) return W.quest(global) end

local function fixtureOf(global)
	local id = W.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return W.IDENTITY[global].type .. "/" .. W.IDENTITY[global].name end

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
	space_dantooine = "space_zones/buildout/space_dantooine.vortex_tier3_points.tab",
	space_endor = "space_zones/buildout/space_endor.vortex_tier3_points.tab",
	space_dathomir = "space_zones/buildout/space_dathomir.vortex_tier3_points.tab",
}

local ZONES = { "space_dantooine", "space_endor", "space_dathomir" }

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
-- The oracle itself
---------------------------------------------------------------------------------------------

TestEzkielFixtures = {}

function TestEzkielFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 20 fixtures are the four chains of the spec, member by member in their zones (triggerArg names the next member; the chain end splits nothing)
function TestEzkielFixtures:test_the_twenty_fixtures_form_the_four_chains_of_the_spec()
	local n = 0

	for c, chain in ipairs(W.CHAINS) do
		for i, global in ipairs(chain) do
			local rec = fixtureOf(global)

			n = n + 1
			lu.assertEquals(rec:get("questZone"), W.IDENTITY[global].zone, label(global) .. ": questZone")

			if i < #chain then
				local nid = W.IDENTITY[chain[i + 1]]

				lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(global) .. ": triggerEvent")
				lu.assertEquals(rec:get("triggerArg"), nid.type .. ":" .. nid.name, label(global) .. ": triggerArg (mission " .. c .. ", the next chain member)")
			else
				lu.assertTrue(rec:get("triggerEvent") == nil or rec:get("triggerEvent") == "none", label(global) .. ": the chain end splits nothing, got " .. tostring(rec:get("triggerEvent")))
			end
		end
	end

	lu.assertEquals(n, 20, "fixtures")
end

-- A-2 (the oracle itself): FV-1 and FV-2, the values of the split rows the spec builds on
function TestEzkielFixtures:test_the_split_rows_carry_the_values_the_spec_lists()
	-- success splits: { condition, triggerDelay (a missing column reads 0) }
	local success = {
		[W.M1[1]] = 0, [W.M1[2]] = 10, [W.M1[3]] = 0, [W.M1[4]] = 10,
		[W.M2[1]] = 0, [W.M2[2]] = 0, [W.M2[4]] = 7,
		[W.M3[2]] = 0, [W.M3[3]] = 0,
		[W.M4[1]] = 0, [W.M4[3]] = 0, [W.M4[4]] = 0,
	}

	for global, delay in pairs(success) do
		local rec = fixtureOf(global)

		lu.assertEquals(rec:get("triggerSplitCondition"), "success", label(global) .. ": triggerSplitCondition")
		lu.assertEquals(rec:num("triggerDelay") or 0, delay, label(global) .. ": triggerDelay")
	end

	-- patrol splits: { triggerOn, triggerDelay }
	local patrols = { [W.M2[3]] = { 3, 10 }, [W.M3[1]] = { 3, 8 }, [W.M3[4]] = { 2, 10 }, [W.M4[2]] = { 3, 9 } }

	for global, want in pairs(patrols) do
		local rec = fixtureOf(global)

		lu.assertEquals({ rec:get("triggerSplitCondition"), rec:num("triggerOn"), rec:num("triggerEndsMission"), rec:num("triggerDelay") }, { "triggerOn", want[1], 1, want[2] }, label(global))
	end

	-- R-5: mission 3's second patrol is the only triggerOn 2 of the tier
	local twos = 0

	for global in pairs(patrols) do
		if fixtureOf(global):num("triggerOn") == 2 then
			twos = twos + 1
		end
	end

	lu.assertEquals(twos, 1, "patrols that split at nav point 2 (R-5)")
	lu.assertEquals(fixtureOf(W.M2[2]):num("targetArrivalDelay"), 0, "rescue 2_a targetArrivalDelay")
	lu.assertEquals(fixtureOf(W.M2[2]):num("numResponses"), 3, "rescue 2_a numResponses")
	lu.assertEquals(fixtureOf(W.M1[2]):num("numResponses"), 2, "escort 1_a numResponses")
	lu.assertEquals(fixtureOf(W.M4[4]):num("numResponses"), 2, "recovery 4_c numResponses")
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the Core3 patrol point files hold (48 nav points)
function TestEzkielFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(W.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 48, "spec nav points")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points and spawners; Core3's values are their truncated values
function TestEzkielFixtures:test_the_buildout_excerpts_pin_every_point_and_both_inspect_spawners()
	for _, zone in ipairs(ZONES) do
		local navs, spawners = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(W.POINTS[zone]), zone .. ": nav_name rows of the excerpt")
		lu.assertEquals(sortedKeys(spawners), sortedKeys(W.SPAWNERS[zone] or {}), zone .. ": strSpawnerName rows of the excerpt")

		for name, xyz in pairs(W.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end

		for name, xyz in pairs(W.SPAWNERS[zone] or {}) do
			lu.assertEquals({ spawners[name].x, spawners[name].z, spawners[name].y }, xyz, zone .. ": buildout truncated, spawner " .. name)
		end
	end

	local da = buildout("space_dantooine")
	local dt = buildout("space_dathomir")

	lu.assertEquals(da.naboo_rebel_tier3_battle_point.forward, W.FORWARD2, "battle 2 forward = fltKX/fltKY/fltKZ of BODA row 182")
	lu.assertEquals(dt.naboo_rebel_tier3_rebel_vs_imperial.forward, W.FORWARD4, "battle 4 forward = fltKX/fltKY/fltKZ of BODT row 157")
end

-- A-2, I-2 (the oracle itself): both inspect spawners exist in Core3's spawner table at the spec positions and spawn only their quest ship
function TestEzkielFixtures:test_the_two_inspect_spawners_exist_in_the_core3_spawner_table_with_only_their_quest_ship()
	local spawners = H.spawners("space_dantooine")
	local ships = { naboo_rebel_tier3_inspect_target = "naboo_tier3_imperial_spy", naboo_rebel_tier3_pirate_leader_inspect = "blacklight_pirate_fighter_quest" }

	for name, xyz in pairs(W.SPAWNERS.space_dantooine) do
		local s = spawners[name]

		lu.assertNotNil(s, "space_dantooine_spawner.lua: spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)
		lu.assertEquals(s.shipSpawns, { ships[name] }, "spawner ships " .. name)
	end
end

-- A-2, I-8 (the oracle itself): the client journal knows every quest
function TestEzkielFixtures:test_the_client_quest_name_table_lists_the_twenty_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(W.GLOBALS) do
		local name = "spacequest/" .. W.IDENTITY[global].type .. "/" .. W.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

-- A-2, I-5 (the oracle itself): the two inspect_cargo tables are one canTransfer-1 row each, and SWG's space_mobile cargo column names them
function TestEzkielFixtures:test_the_two_inspect_cargo_fixtures_have_one_transferable_row_and_space_mobile_names_them()
	local tab = H.fixture("space_mobile/space_mobile.vortex_tier3_inspect.tab")
	local cargoOf = {}

	for _, rec in ipairs(tab.records) do
		cargoOf[rec:get("strIndex")] = rec:get("cargo")
	end

	lu.assertEquals(#tab.records, 2, "space_mobile excerpt rows (SMT 98, 1146)")

	for ship, info in pairs(W.CARGO_SHIPS) do
		lu.assertEquals(cargoOf[ship], info.cargo, "space_mobile.tab cargo column of " .. ship)

		local rows = H.fixture("spacequest/inspect_cargo/" .. info.cargo .. ".tab").records
		local transferable = {}

		for _, rec in ipairs(rows) do
			if rec:num("canTransfer") == 1 then
				transferable[#transferable + 1] = rec:get("name")
			end
		end

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. info.cargo .. ".tab rows")
		lu.assertEquals(transferable, { info.cargo }, "the rows with canTransfer 1 in inspect_cargo/" .. info.cargo .. ".tab")
	end
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestEzkielWiring = {}

function TestEzkielWiring:setUp() H.reset() end

-- A-1, I-1
function TestEzkielWiring:test_the_squadron_file_registers_the_twenty_quests_with_start_true()
	for _, global in ipairs(W.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#W.GLOBALS, 20, "tier 3 globals")
end

-- A-1: Content contract 1 order, after the 17 tier 1-2 globals
function TestEzkielWiring:test_the_twenty_quests_are_registered_in_the_contract_order_after_the_seventeen_earlier_quests()
	local order = {}

	for _, global in ipairs(W.EARLIER_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(W.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 37, "17 tier 1-2 + 20 tier 3 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1: the squadron object has the twenty constants and the reset; every earlier field is unchanged
function TestEzkielWiring:test_the_squadron_screenplay_has_the_twenty_constants_the_reset_and_every_earlier_field()
	local sq = W.squadron()

	for field, want in pairs(W.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field)
	end

	lu.assertEquals(#W.QUEST_STRING_FIELDS, 20, "constants")

	for field, want in pairs(V2.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 2, unchanged)")
	end

	for field, want in pairs(V1.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.VORTEX_PILOT_KEY, W.VORTEX_PILOT_KEY, "VORTEX_PILOT_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_IMP_ASKING_KEY, "VortexSquadronScreenplay:kiizeteImpIsAsking", "KIIZETE_IMP_ASKING_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_Q1_DISCUSSED_KEY, "VortexSquadronScreenplay:kiizeteQ1Discussed", "KIIZETE_Q1_DISCUSSED_KEY unchanged")
	lu.assertEquals(type(sq.resetV3fxQuests), "function", "resetV3fxQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetVrovelQuests), "function", "resetVrovelQuests (tier 2, unchanged)")
	lu.assertEquals(type(sq.hasKiizeteFlag), "function", "hasKiizeteFlag (unchanged)")
	lu.assertEquals(type(sq.resetEzkielQuests), "function", "VortexSquadronScreenplay:resetEzkielQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetEzkielQuests, sq, nil), true, "resetEzkielQuests(nil) returns early")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestEzkielTables = {}

function TestEzkielTables:setUp() H.reset() end

-- A-2, I-1
function TestEzkielTables:test_the_twenty_tables_keep_their_identity_and_zone()
	for _, global in ipairs(W.GLOBALS) do
		local q = quest(global)
		local id = W.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestEzkielTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = W.expected()

	for _, global in ipairs(W.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestEzkielTables:test_no_table_defines_a_function()
	for _, global in ipairs(W.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2: the delays of every chain, in the spec's words (M1 5 / 15 / 5 / 15, M2 5 / 5 / PATROL_POINT 3 at 10 / 12, M3 PATROL_POINT 3 at 8 / 5 / 5 / PATROL_POINT 2 at 10, M4 5 / PATROL_POINT 3 at 9 / 5 / 5)
function TestEzkielTables:test_the_split_types_and_delays_of_the_four_chains_are_the_ones_of_the_acceptance_criterion()
	local C, P = W.SPLIT_COMPLETION, W.SPLIT_PATROL_POINT
	local want = {
		{ { C, 5 }, { C, 15 }, { C, 5 }, { C, 15 } },
		{ { C, 5 }, { C, 5 }, { P, 10, 3 }, { C, 12 } },
		{ { P, 8, 3 }, { C, 5 }, { C, 5 }, { P, 10, 2 } },
		{ { C, 5 }, { P, 9, 3 }, { C, 5 }, { C, 5 } },
	}

	for m, chain in ipairs(W.CHAINS) do
		for i = 1, 4 do
			local q = quest(chain[i])
			local w = want[m][i]

			lu.assertEquals({ q.sideQuestSplitType, q.sideQuestDelay }, { w[1], w[2] }, chain[i] .. ": sideQuestSplitType, sideQuestDelay")

			if w[3] then
				lu.assertEquals(q.sideQuestPatrolStart, w[3], chain[i] .. ": sideQuestPatrolStart (R-5: mission 3's second patrol splits at point 2)")
			else
				lu.assertNil(rawget(q, "sideQuestPatrolStart"), chain[i] .. ": no patrol trigger on a COMPLETION split")
			end
		end
	end
end

-- A-2, I-6: exactly the 16 non-end tables split and name the next chain member; each child names its parent; the chain ends do not split
function TestEzkielTables:test_exactly_the_sixteen_non_end_tables_split_and_name_the_next_chain_member()
	local splitting = 0

	for m, chain in ipairs(W.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)

			if i < #chain then
				local nid = W.IDENTITY[chain[i + 1]]

				splitting = splitting + 1
				lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, nid.type, nid.name }, global .. ": sideQuest, sideQuestType, sideQuestName (mission " .. m .. ")")
			else
				lu.assertEquals({ q.sideQuest, q.sideQuestType }, { false, "" }, global .. ": the chain end splits nothing")
				lu.assertNil(rawget(q, "sideQuestName"), global .. ": the chain end names no split")
			end

			if i > 1 then
				local pid = W.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splitting, 16, "tables with sideQuest = true")
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in order
function TestEzkielTables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(W.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-7: credits and items on the four heads only (25000 + the Source inventory item, any species)
function TestEzkielTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local heads = {}

	for n, global in ipairs(W.HEADS) do
		heads[global] = n
	end

	for _, global in ipairs(W.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), 25000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = W.ITEM_ROOT .. W.ITEMS[n] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 22 distinct ships of FV-6) and every item an object template (4)
function TestEzkielTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(W.GLOBALS) do
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

	for i, s in ipairs(W.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 20 tables (FV-6)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 20 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. W.SHIP_DIR .. name .. ".lua"), W.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: recovery 4_c's appearance is a client mobile template the server knows
function TestEzkielTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(quest(W.M4[4]).recoveryConversationMobile, W.DROID_MOBILE, W.M4[4] .. ": recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. W.DROID_MOBILE .. '"', 1, true), W.DROID_MOBILE .. " is not in object/mobile/objects.lua")
end

-- A-2, D-2: rescue 2_a carries no appearance key (SWG's rescueAppearance is dropped)
function TestEzkielTables:test_rescue_2_a_carries_no_appearance_key()
	local q = quest(W.M2[2])

	for _, key in ipairs({ "rescueAppearance", "recoveryConversationMobile", "appearance" }) do
		lu.assertNil(rawget(q, key), W.M2[2] .. ": " .. key)
	end
end

-- A-2, I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestEzkielTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in readFile(H.FIXTURES .. "misc/quest_crc_string_table.names"):gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(W.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestEzkielConformance = {}

function TestEzkielConformance:setUp() H.reset() end

-- A-2, I-4, I-6: zone, split target and delay from each fixture (success: triggerDelay + 5; triggerOn patrol: PATROL_POINT, triggerDelay, point = triggerOn)
function TestEzkielConformance:test_every_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	for _, global in ipairs(W.GLOBALS) do
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
				lu.assertEquals(q.questType, "patrol", l .. ": precondition: only patrols split on triggerOn in this tier")
				lu.assertEquals(q.sideQuestSplitType, ST.PATROL_POINT, l .. ": PATROL_POINT (triggerOn, triggerEndsMission 1)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, patrol.java:365-390 keeps it)")
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

-- A-2, I-2, I-4: escort 1_a (numResponses 2 gives 2 of each key, FV-5)
function TestEzkielConformance:test_escort_1_a_maps_ship_points_attack_lists_delay_and_taunts()
	local q, rec = quest(W.M1[2]), fixtureOf(W.M1[2])
	local l = label(W.M1[2])

	lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
		l .. ": escortPoints (escortPath, zoneName, numbered from 1, radius 250)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: random, as Core3's escort")
	lu.assertEquals({ #q.attackShips, q.attackDelay }, { 3, 80 }, l .. ": 3 attack lists, delay 80")
end

-- A-2, I-2, I-4: recovery 4_c (Core3's recovery cycles its lists in order, as the fixture's sequential)
function TestEzkielConformance:test_recovery_4_c_maps_ships_paths_attack_lists_appearance_and_taunts()
	local q, rec = quest(W.M4[4]), fixtureOf(W.M4[4])
	local l = label(W.M4[4])

	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
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
	lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints, #q.attackShips, #q.escortShips }, { 4, 4, 2, 3 }, l .. ": 4 + 4 points, 2 attack lists, 3 escorts")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential, as Core3's recovery")
end

-- A-2, I-2, I-4: the two inspects (cargo needs SC-1 to be completable, A-3)
function TestEzkielConformance:test_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	local _, spawners = buildout("space_dantooine")

	for _, global in ipairs({ W.M1[4], W.M2[5] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
		local s = spawners[spawnName]

		lu.assertNotNil(s, l .. ": the buildout excerpt has the spawner " .. spawnName)
		lu.assertEquals(zone, q.questZone, l .. ": the validSpawns zone is the quest zone")
		lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
		lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns (zone prefix dropped, buildout position truncated)")
		lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
		lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
	end

	lu.assertEquals(quest(W.M1[4]).cargo, "experiment_information", "inspect 1_c: cargo")
	lu.assertEquals(quest(W.M2[5]).cargo, "leader_location", "inspect 2_d: cargo")
end

-- A-2, I-2, I-4: rescue 2_a (rescueAppearance dropped, D-2)
function TestEzkielConformance:test_rescue_2_a_maps_path_target_attack_lists_and_responses()
	local q, rec = quest(W.M2[2]), fixtureOf(W.M2[2])
	local l = label(W.M2[2])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals({ q.targetArrivalDelay, q.numResponses }, { 0, 3 }, l .. ": no arrival delay, 3 responses")
end

-- A-2, I-2, I-4: delivery_no_pickup 1_d and delivery 4_d (single zone: no pickupZone / deliveryZone)
function TestEzkielConformance:test_deliveries_map_ships_points_attack_lists_period_and_order()
	for _, global in ipairs({ W.M1[5], W.M4[5] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")

		if W.IDENTITY[global].type == "delivery" then
			lu.assertEquals(q.pickupShip, rec:get("pickupShip"), l .. ": pickupShip")
			lu.assertEquals(q.pickupPoint, mapped(rec, "pickupPoint")[1], l .. ": pickupPoint")
		else
			lu.assertNil(rawget(q, "pickupPoint"), l .. ": a delivery_no_pickup has no pickup")
		end

		lu.assertNil(rawget(q, "pickupZone"), l .. ": single zone: no pickupZone")
		lu.assertNil(rawget(q, "deliveryZone"), l .. ": single zone: no deliveryZone")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	end
end

-- A-2, I-4: the two surprise attacks (R.runs of the SWG spawn loop replay)
function TestEzkielConformance:test_surprise_attacks_map_ship_count_and_zone()
	for _, global in ipairs({ W.M2[4], W.M3[2] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = R.runs(R.replay(W.IDENTITY[global].name)) }, l .. ": surpriseAttackShips (the SWG spawn loop, zone)")
		lu.assertEquals(q.surpriseAttackShips.spawns, { { count = rec:num("shipCount"), shipName = rec:get("shipType") } }, l .. ": surpriseAttackShips spawns (shipType, shipCount)")
	end

	lu.assertEquals(quest(W.M2[4]).surpriseAttackShips.spawns, { { count = 4, shipName = "blacklight_fighter_tier3" } }, "surprise 2_c: 4 blacklight_fighter_tier3")
	lu.assertEquals(quest(W.M3[2]).surpriseAttackShips.spawns, { { count = 4, shipName = "blacklight_assassin_tier3" } }, "surprise 3_a: 4 blacklight_assassin_tier3")
end

-- A-2, I-2, I-4: the four patrols (laps is not mapped; R-4: the points after the trigger are stored, never flown)
function TestEzkielConformance:test_patrols_map_the_four_nav_points_numbered_with_radius_150()
	for _, global in ipairs({ W.M2[3], W.M3[1], W.M3[4], W.M4[2] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), l .. ": patrolPoints (navPoints, patrolNumber, radius 150)")
		lu.assertEquals(#q.patrolPoints, 4, l .. ": four points")
	end
end

-- A-2, I-2, I-4: battles 2 and 4 (enemyArrivalDist -100, forward from fltK*)
function TestEzkielConformance:test_battles_map_point_forward_timers_distances_and_forces()
	for _, spec in ipairs({ { W.M2[1], "space_dantooine" }, { W.M4[1], "space_dathomir" } }) do
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
		lu.assertEquals({ #q.allyForce, #q.enemyForce, q.enemyArrivalDist }, { 4, 7, -100 }, l .. ": 4 allies, 7 enemies, enemyArrivalDist -100")
	end
end

-- A-2, I-2, I-4: survivals 1_b, 3_b and 4_b
function TestEzkielConformance:test_survivals_map_point_timers_attack_lists_and_order_from_their_fixtures()
	local lists = { [W.M1[3]] = 4, [W.M3[3]] = 4, [W.M4[3]] = 3 }

	for global, count in pairs(lists) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
		lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
		lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
		lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
		lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..N, column-wise)")
		lu.assertEquals(#q.attackShipLists, count, l .. ": attack lists")

		for i, list in ipairs(q.attackShipLists) do
			lu.assertEquals(#list, 3, l .. ": attack list " .. i .. " has three ships")
		end

		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	end
end

-- A-2, I-2, I-4: assassinates 1 and 3_d (mustDestroyEscort 0 / 1; failTimer is Core3's 20)
function TestEzkielConformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ W.M1[1], W.M3[5] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals({ quest(W.M1[1]).mustDestroyEscort, quest(W.M3[5]).mustDestroyEscort }, { false, true }, "assassinate 1 and 3_d: mustDestroyEscort false / true")
	lu.assertEquals({ #quest(W.M1[1]).assassinateSpawns.escorts, #quest(W.M3[5]).assassinateSpawns.escorts }, { 2, 5 }, "assassinate 1 and 3_d: 2 and 5 escorts")
	lu.assertEquals(quest(W.M1[1]).targetPatrols[1].patrolPointName, "corellia_imperial_tier4_recovery1_2", "assassinate 1: the first path point")
end

---------------------------------------------------------------------------------------------
-- I-5: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestEzkielCargo = {}

function TestEzkielCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. W.SHIP_DIR .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/" .. W.SHIP_DIR .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- A-3, I-5, FV-3: SC-1
function TestEzkielCargo:test_each_inspect_target_template_file_carries_the_swg_cargo_as_a_cargo_string()
	for ship, info in pairs(W.CARGO_SHIPS) do
		local src = templateSource(ship)

		lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), info.cargo, ship .. ".lua cargoString must be the inspect_cargo row of SWG's space_mobile cargo column (SMT row " .. info.smt .. ")")
		lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), info.cargo, ship .. ".lua questLoot (names the inspect_cargo table) stays")
	end
end

-- A-3, I-5: the loaded templates have it too, and the targets stay what they were
function TestEzkielCargo:test_the_loaded_target_templates_have_the_cargo_string_and_keep_their_loot_name()
	for ship, info in pairs(W.CARGO_SHIPS) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, W.SHIP_DIR .. ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, info.cargo, ship .. ": cargoString")
		lu.assertEquals(t.questLoot, info.cargo, ship .. ": questLoot is unchanged")
	end

	lu.assertEquals(H.shipTemplate("naboo_tier3_imperial_spy").aggressive, 0, "naboo_tier3_imperial_spy: aggressive is unchanged (R-2)")
end

-- A-3, I-5: each quest's cargo equals its ship's cargo string, and the two targets differ
function TestEzkielCargo:test_each_inspect_quest_cargo_equals_its_ships_cargo_string()
	local spy = H.shipTemplate("naboo_tier3_imperial_spy")
	local pirate = H.shipTemplate("blacklight_pirate_fighter_quest")

	for ship, info in pairs(W.CARGO_SHIPS) do
		lu.assertEquals(quest(info.quest).shipList, { ship }, info.quest .. ": shipList")
	end

	lu.assertNotNil(spy, "naboo_tier3_imperial_spy template")
	lu.assertNotNil(pirate, "blacklight_pirate_fighter_quest template")
	lu.assertEquals(quest(W.M1[4]).cargo, spy.cargoString, "inspect 1_c: the quest cargo equals the spy's cargoString")
	lu.assertEquals(quest(W.M2[5]).cargo, pirate.cargoString, "inspect 2_d: the quest cargo equals the pirate fighter's cargoString")
	lu.assertNotEquals(spy.cargoString, pirate.cargoString, "the two targets carry different cargo")
end

return nil
