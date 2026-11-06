-- Storm tier 3 part A (Captain Denner's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (A-1, A-2; invariants I-1 .. I-8; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of storm_tier3_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")

D.load()

local function quest(global) return D.quest(global) end

local function fixtureOf(global)
	local id = D.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

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

local function label(global) return D.IDENTITY[global].type .. "/" .. D.IDENTITY[global].name end

local function point(name)
	local p = H.patrolPoints("space_endor")[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in space_endor")
	return p
end

local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(name)

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

-- the rows of the buildout excerpt: nav_name -> { x, z, y, forward }, strSpawnerName -> { x, z, y }
local function buildout()
	local tab = H.fixture("space_zones/buildout/space_endor.storm_tier3_points.tab")
	local navs, spawners = {}, {}

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawner = vars:match("strSpawnerName|4|([^|]+)|")
		local row = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")),
			forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") } }

		if nav ~= nil then
			navs[nav] = row
		end

		if spawner ~= nil then
			spawners[spawner] = row
		end
	end

	return navs, spawners
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestDennerFixtures = {}

function TestDennerFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 20 fixtures are the chains of the spec, member by member (triggerArg names the next member; the chain end has no split)
function TestDennerFixtures:test_the_twenty_fixtures_form_the_four_chains_of_the_spec()
	local n = 0

	for c, chain in ipairs(D.CHAINS) do
		for i, global in ipairs(chain) do
			local rec = fixtureOf(global)

			n = n + 1
			lu.assertEquals(rec:get("questZone"), "space_endor", label(global) .. ": questZone")

			if i < #chain then
				local nid = D.IDENTITY[chain[i + 1]]

				lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(global) .. ": triggerEvent")
				lu.assertEquals(rec:get("triggerArg"), nid.type .. ":" .. nid.name, label(global) .. ": triggerArg (mission " .. c .. ", the next chain member)")
			else
				lu.assertEquals(rec:get("triggerEvent"), "none", label(global) .. ": the chain end splits nothing")
			end
		end
	end

	lu.assertEquals(n, 20, "fixtures")
end

-- A-2 (the oracle itself): the values of the split rows the spec builds on (FD-3, FD-4; FD-5 withdrawn by Amendment A-2)
function TestDennerFixtures:test_the_split_rows_carry_the_values_the_spec_lists()
	local e1 = fixtureOf(D.M1[1])

	lu.assertEquals({ e1:get("triggerSplitCondition"), e1:num("triggerOn"), e1:num("triggerDelay"), e1:num("numResponses"), e1:num("attackPeriod") }, { "triggerOn", -1, 15, 2, 120 }, "escort/tatooine_imperial_tier3_1")

	local e3 = fixtureOf(D.M3[3])

	lu.assertEquals({ e3:get("triggerSplitCondition"), e3:num("triggerOn"), e3:num("triggerEndsMission"), e3:num("triggerDelay"), e3:num("destroyIsSuccess"), e3:num("attackPeriod"), e3:num("numResponses") },
		{ "triggerOn", 3, 1, 10, 1, 70, 5 }, "escort/tatooine_imperial_tier3_3_a")

	local p = fixtureOf(D.M2[5])

	lu.assertEquals({ p:get("triggerSplitCondition"), p:num("triggerOn"), p:num("triggerEndsMission"), p:num("triggerDelay") }, { "triggerOn", 3, 1, 20 }, "patrol/tatooine_imperial_tier3_2_d")
	lu.assertEquals({ fixtureOf(D.M2[1]):num("triggerDelay"), fixtureOf(D.M2[3]):num("triggerDelay") }, { 5, 5 }, "inspect 2 and inspect 2_b triggerDelay")
	lu.assertEquals(fixtureOf(D.M3[2]):num("killCount"), 5, "destroy 3_b killCount")
	lu.assertEquals(fixtureOf(D.M4[2]):num("targetArrivalDelay"), 0, "rescue 4_a targetArrivalDelay")
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the patrol point file holds today (33 nav points)
function TestDennerFixtures:test_the_spec_points_equal_the_core3_patrol_point_file()
	local n = 0

	for name, xyz in pairs(D.POINTS) do
		local p = point(name)

		n = n + 1
		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_endor patrol point " .. name)
	end

	lu.assertEquals(n, 33, "spec nav points")
end

-- A-2, I-2 (the oracle itself): the buildout excerpt holds exactly the 33 points and the 4 spawners; Core3's values are their truncated values
function TestDennerFixtures:test_the_buildout_excerpt_pins_every_point_and_the_four_inspect_spawners()
	local navs, spawners = buildout()

	lu.assertEquals(sortedKeys(navs), sortedKeys(D.POINTS), "nav_name rows of the excerpt")
	lu.assertEquals(sortedKeys(spawners), sortedKeys(D.SPAWNERS), "strSpawnerName rows of the excerpt")

	for name, xyz in pairs(D.POINTS) do
		lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end

	for name, xyz in pairs(D.SPAWNERS) do
		lu.assertEquals({ spawners[name].x, spawners[name].z, spawners[name].y }, xyz, "buildout fltPX/fltPY/fltPZ truncated, spawner " .. name)
	end

	lu.assertEquals(navs.tatooine_imperial_tier3_battle1_spawner.forward, D.FORWARD, "battle point forward = fltKX/fltKY/fltKZ of BOE row 159")
end

-- A-2, I-2 (the oracle itself): the four spawners exist in Core3's endor spawner table at the spec's positions and spawn only their quest ship
function TestDennerFixtures:test_the_four_inspect_spawners_exist_in_the_core3_spawner_table_with_only_their_quest_ship()
	local spawners = H.spawners("space_endor")
	local ships = {
		tatooine_imperial_tier3_rebscout_spawner = "rebel_scout_fighter_tier3", tatooine_imperial_tier3_inspect2_spawner = "rebel_scout_fighter_tier3",
		tatooine_imperial_tier3_inspect3_spawner = "rebel_scout_shuttle_tier3", tatooine_imperial_tier3_inspect4_spawner = "rebel_command_shuttle_tier4",
	}

	for name, xyz in pairs(D.SPAWNERS) do
		local s = spawners[name]

		lu.assertNotNil(s, "space_endor_spawner.lua: spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)
		lu.assertEquals(s.shipSpawns, { ships[name] }, "spawner ships " .. name)
	end
end

-- A-2, I-8 (the oracle itself): the client journal knows every quest
function TestDennerFixtures:test_the_client_quest_name_table_lists_the_twenty_quests_and_not_the_orphan_destroy_4()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(D.GLOBALS) do
		local name = "spacequest/" .. D.IDENTITY[global].type .. "/" .. D.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end

	lu.assertTrue(set["spacequest/destroy/tatooine_imperial_tier3_4"] == true, "precondition: the orphan destroy/tatooine_imperial_tier3_4 is in the client table (FD-6)")
	lu.assertNil(rawget(_G, "destroy_tatooine_imperial_tier3_4"), "FD-6: the orphan destroy/tatooine_imperial_tier3_4 is not ported")
end

-- A-2, I-5 (the oracle itself): the three cargo tables have one canTransfer-1 row, and SWG's space_mobile cargo column names it
function TestDennerFixtures:test_the_inspect_cargo_fixtures_have_one_transferable_row_and_space_mobile_names_it()
	local tab = H.fixture("space_mobile/space_mobile.storm_tier3_inspect.tab")
	local cargoOf = {}

	for _, rec in ipairs(tab.records) do
		cargoOf[rec:get("strIndex")] = rec:get("cargo")
	end

	for ship, info in pairs(D.CARGO_SHIPS) do
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

	lu.assertEquals(#tab.records, 3, "space_mobile excerpt rows (SMT 1434, 1462, 1464)")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestDennerWiring = {}

function TestDennerWiring:setUp() H.reset() end

-- A-1, I-1
function TestDennerWiring:test_the_squadron_file_registers_the_twenty_quests_with_start_true()
	for _, global in ipairs(D.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#D.GLOBALS, 20, "tier 3 globals")
end

-- A-1: Content contract 1 order, after the six Alozen globals
function TestDennerWiring:test_the_twenty_quests_are_registered_in_the_contract_order_after_the_six_alozen_quests()
	local order = {}

	for _, global in ipairs(D.ALOZEN_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(D.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 26, "6 Alozen + 20 tier 3 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1: the squadron object has the 20 constants, the reset, and every earlier field is unchanged
function TestDennerWiring:test_the_squadron_screenplay_has_the_twenty_constants_the_reset_and_every_earlier_field()
	local sq = D.squadron()

	for field, want in pairs(D.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field)
	end

	lu.assertEquals(#D.QUEST_STRING_FIELDS, 20, "constants")

	-- the constants are the 20 quests in chain order
	for i, field in ipairs(D.QUEST_STRING_FIELDS) do
		local id = D.IDENTITY[D.GLOBALS[i]]

		lu.assertEquals(sq[field], { type = id.type, name = id.name }, "StormSquadronScreenplay." .. field .. " is quest " .. i .. " of the chains (SIDEn follows chain order)")
	end

	for field, want in pairs(A.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (Alozen, unchanged)")
	end

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (Oberhaur, unchanged)")
	end

	for field, want in pairs(T.TIER1_QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, T.SERIES_SUFFIX, "SERIES_COMPLETE_KEY unchanged")
	lu.assertEquals(sq.TIER2_INITIATE_KEY, T.INITIATE_SUFFIX, "TIER2_INITIATE_KEY unchanged")
	lu.assertEquals(sq.TIER2_ALOZEN_KEY, T.ALOZEN_SUFFIX, "TIER2_ALOZEN_KEY unchanged")
	lu.assertEquals(sq.TRANSFER_FORM_SIGNATURE, T.SIGNATURE_KEY, "TRANSFER_FORM_SIGNATURE unchanged")
	lu.assertEquals(type(sq.resetColzetQuests), "function", "resetColzetQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetOberhaurQuests), "function", "resetOberhaurQuests (unchanged)")
	lu.assertEquals(type(sq.resetAlozenQuests), "function", "resetAlozenQuests (unchanged)")
	lu.assertEquals(type(sq.resetDennerQuests), "function", "StormSquadronScreenplay:resetDennerQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetDennerQuests, sq, nil), true, "resetDennerQuests(nil) returns early")
end

-- A-1, SC-1: the shared quest logic knows the new split type and its default
function TestDennerWiring:test_space_quest_logic_has_the_attack_wave_split_type_after_patrol_point_and_a_zero_default()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	lu.assertEquals({ ST.NONE, ST.COMPLETION, ST.FAILURE, ST.BIDIRECTIONAL, ST.PATROL_POINT }, { 0, 1, 2, 3, 4 }, "the existing split types keep their values")
	lu.assertEquals(ST.ATTACK_WAVE, 5, "SIDE_QUEST_SPLIT_TYPES.ATTACK_WAVE")
	lu.assertEquals(SpaceQuestLogic.sideQuestAttackWave, 0, "SpaceQuestLogic.sideQuestAttackWave default")
	lu.assertEquals(SpaceEscortScreenplay.sideQuestAttackWave, 0, "an escort table inherits the default 0")
	lu.assertEquals(type(SpaceEscortScreenplay.triggerAttackWaveSplit), "function", "SpaceEscortScreenplay:triggerAttackWaveSplit")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestDennerTables = {}

function TestDennerTables:setUp() H.reset() end

-- A-2, I-1
function TestDennerTables:test_the_twenty_tables_keep_their_identity_and_zone()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local id = D.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_endor", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestDennerTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = D.expected()

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestDennerTables:test_no_table_defines_a_function()
	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-6: exactly the 16 non-end tables split to the next chain member with the contract's split type and delay
function TestDennerTables:test_exactly_the_sixteen_non_end_tables_split_and_name_the_next_chain_member()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local special = {
		[D.M1[1]] = { ST.COMPLETION, 20 }, -- triggerDelay 15 + 5 (A-2 amendment: escort.java:95 fires nothing, space_quest.java:600 splits)
		[D.M2[1]] = { ST.COMPLETION, 10 }, [D.M2[3]] = { ST.COMPLETION, 10 }, -- triggerDelay 5 + 5
		[D.M2[5]] = { ST.PATROL_POINT, 20 }, -- keeps triggerDelay
		[D.M3[3]] = { ST.ATTACK_WAVE, 10 }, -- keeps triggerDelay (Q-2 = A)
	}
	local splits = 0

	for c, chain in ipairs(D.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)
			local isEnd = (i == #chain)

			lu.assertEquals(q.sideQuest and true or false, not isEnd, global .. ": sideQuest")

			if isEnd then
				lu.assertEquals(q.sideQuestType, "", global .. ": the chain end has no split type")
				lu.assertNil(rawget(q, "sideQuestName"), global .. ": the chain end names no split")
			else
				splits = splits + 1

				local nextId = D.IDENTITY[chain[i + 1]]
				local want = special[global] or { ST.COMPLETION, 5 }

				lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { nextId.type, nextId.name }, global .. ": sideQuestType, sideQuestName (mission " .. c .. ")")
				lu.assertEquals({ q.sideQuestSplitType, q.sideQuestDelay }, want, global .. ": sideQuestSplitType, sideQuestDelay")
			end

			if i > 1 then
				local pid = D.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splits, 16, "split tables")
	lu.assertEquals({ #D.M1, #D.M2, #D.M3, #D.M4 }, { 5, 6, 5, 4 }, "chain lengths (5, 6, 5, 4)")
end

-- A-2, I-6: only escort 3_a has the attack-wave count; it is 3
function TestDennerTables:test_only_escort_3_a_sets_the_attack_wave_count_and_it_is_three()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		if global == D.M3[3] then
			lu.assertEquals(rawget(q, "sideQuestAttackWave"), 3, global .. ": sideQuestAttackWave (FD-4: the .tab says 3)")
		else
			lu.assertNil(rawget(q, "sideQuestAttackWave"), global .. ": sideQuestAttackWave is not set")
		end
	end
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order (M3 runs 3, 3_b, 3_a, 3_d, 3_c)
function TestDennerTables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(D.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-6: the chain walk follows the ATTACK_WAVE split too
function TestDennerTables:test_the_chain_of_mission_3_passes_through_the_attack_wave_split()
	local chain = {}

	for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(quest(D.M3[1]).className)) do
		chain[i] = entry.global
	end

	lu.assertEquals(chain[3], D.M3[3], "the third member of mission 3 is the escort")
	lu.assertEquals(chain[4], D.M3[4], "the fourth member is the surprise attack the ATTACK_WAVE split starts")
end

-- A-2, I-7 (D-9): credits and items only on the four heads
function TestDennerTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local heads = { [D.M1[1]] = 1, [D.M2[1]] = 2, [D.M3[1]] = 3, [D.M4[1]] = 4 }

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), 25000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = D.ITEMS[n] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 20 distinct ships of FD-12) and every item an object template (4)
function TestDennerTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "shipTypes", "attackShipLists", "allyForce", "enemyForce" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "deliveryShip", "pickupShip", "targetShipType" }) do
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

	for i, s in ipairs(D.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 20 tables (FD-12)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 20 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: recovery 1_a's conversation mobile is a client template the server knows
function TestDennerTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local q = quest(D.M1[2])
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(q.recoveryConversationMobile, D.OFFICER_MOBILE, "recovery 1_a: recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. tostring(q.recoveryConversationMobile) .. '"', 1, true), tostring(q.recoveryConversationMobile) .. " is not in object/mobile/objects.lua")
end

-- A-2, I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestDennerTables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")
	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestDennerConformance = {}

function TestDennerConformance:setUp() H.reset() end

-- A-2, I-4, I-6: every quest: zone, split target and delay from triggerArg (COMPLETION: triggerDelay + 5, except escort 1; the PATROL_POINT and ATTACK_WAVE
-- splits keep triggerDelay and name the point or wave count in triggerOn)
function TestDennerConformance:test_every_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	for _, global in ipairs(D.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

			if global == D.M2[5] then
				lu.assertEquals(q.sideQuestSplitType, ST.PATROL_POINT, l .. ": PATROL_POINT (triggerOn 3, triggerEndsMission 1)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, escort/patrol point split keeps it)")
			elseif global == D.M3[3] then
				lu.assertEquals(q.sideQuestSplitType, ST.ATTACK_WAVE, l .. ": ATTACK_WAVE (triggerOn 3, triggerEndsMission 1, destroyIsSuccess 1)")
				lu.assertEquals(q.sideQuestAttackWave, rec:num("triggerOn"), l .. ": sideQuestAttackWave (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, escort.java:150-171)")
			else
				lu.assertTrue(rec:get("triggerSplitCondition") == "success" or rec:num("triggerOn") == -1, l .. ": precondition: the split fires on success or at the end (space_quest.java:583-589)")
				lu.assertEquals(q.sideQuestSplitType, ST.COMPLETION, l .. ": COMPLETION")

				lu.assertEquals(q.sideQuestDelay, delay + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:600; escort 1 included, no exception)")
			end
		else
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

local function tauntsOf(rec, fields)
	local m = math.max(rec:num("numResponses") or 0, 1)

	if (rec:num("numResponses") or 0) == 0 then
		m = 5
	end

	local out = {}

	for _, f in ipairs(fields) do
		out[f] = m
	end

	return out
end

-- A-2, I-4: the two escorts (FD-10: numResponses N >= 1 gives N, 0 gives the client count 5)
function TestDennerConformance:test_escorts_map_ship_points_attack_lists_delay_and_taunts()
	for _, global in ipairs({ D.M1[1], D.M3[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
		lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPath, zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	end

	lu.assertEquals(quest(D.M1[1]).tauntData, { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 }, "escort 1: tauntData 2/2/2/2 (FD-10)")
	lu.assertEquals(quest(D.M3[3]).tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, "escort 3_a: tauntData 5/5/5/5")

	-- escort 3_a flies the very same four points as escort 1
	lu.assertEquals(quest(D.M3[3]).escortPoints, quest(D.M1[1]).escortPoints, "escort 3_a: the same four escort points as escort 1")
end

-- A-2, I-2, I-4: recovery 1_a
function TestDennerConformance:test_recovery_1_a_maps_ships_paths_attack_lists_appearance_and_taunts()
	local q, rec = quest(D.M1[2]), fixtureOf(D.M1[2])
	local l = label(D.M1[2])
	local radius = function(i) return { escortNumber = i, radius = 250 } end

	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	lu.assertEquals(#q.escortShips, 5, l .. ": five escorts")
	lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", radius), l .. ": preRecoveryPoints (escortPath, no zoneName, numbered from 1)")
	lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints (recoveryPath, renumbered from 1)")
	lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints }, { 2, 3 }, l .. ": 2 + 3 points")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
	lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")), l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses 0 gives the client count 5, FD-10)")
end

-- A-2, I-2, I-4: the four inspects
function TestDennerConformance:test_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	local _, spawners = buildout()

	for _, global in ipairs({ D.M1[3], D.M2[1], D.M2[3], D.M4[3] }) do
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
end

-- A-2, I-2, I-4: rescue 1_c and 4_a
function TestDennerConformance:test_rescues_map_path_target_attack_lists_and_responses()
	for _, global in ipairs({ D.M1[4], D.M4[2] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
		lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
		lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	end

	lu.assertEquals(quest(D.M1[4]).targetArrivalDelay, 30, "rescue 1_c: targetArrivalDelay 30")
	lu.assertEquals(quest(D.M4[2]).targetArrivalDelay, 0, "rescue 4_a: targetArrivalDelay 0")
end

-- A-2, I-2, I-4: the three delivery_no_pickup and the delivery tables
function TestDennerConformance:test_deliveries_map_ships_points_attack_lists_period_and_order()
	for _, global in ipairs({ D.M1[5], D.M2[4], D.M3[1] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")

		if D.IDENTITY[global].type == "delivery" then
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

	lu.assertEquals(quest(D.M1[5]).deliveryPoint.patrolPointName, "tatooine_imperial_tier3_delivery1_hq_spawner", "dnp 1_d: SWG's own point name")
end

-- A-2, I-4: the two surprise attacks
function TestDennerConformance:test_surprise_attacks_map_ship_count_and_zone()
	for _, global in ipairs({ D.M2[2], D.M3[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } }, l .. ": surpriseAttackShips (shipType, shipCount, questZone)")
	end

	lu.assertEquals({ quest(D.M2[2]).surpriseAttackShips.spawns[1].count, quest(D.M3[4]).surpriseAttackShips.spawns[1].count }, { 5, 6 }, "surprise 2_a and 3_d: 5 and 6 ships")
end

-- A-2, I-2, I-4: patrol 2_d
function TestDennerConformance:test_patrol_2_d_maps_the_four_nav_points_numbered_with_radius_150()
	local q, rec = quest(D.M2[5]), fixtureOf(D.M2[5])
	local l = label(D.M2[5])

	lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), l .. ": patrolPoints (navPoints, patrolNumber, radius 150)")
	lu.assertEquals(#q.patrolPoints, 4, l .. ": four points (laps 1 is not mapped)")
end

-- A-2, I-2, I-4: battle 2_e
function TestDennerConformance:test_battle_2_e_maps_point_forward_timers_distances_and_forces()
	local q, rec = quest(D.M2[6]), fixtureOf(D.M2[6])
	local l = label(D.M2[6])
	local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
	local navs = buildout()
	local row = navs[name]

	lu.assertEquals(zone, "space_endor", l .. ": battlePoint zone")
	lu.assertNotNil(row, l .. ": the buildout excerpt has " .. name)
	lu.assertEquals(q.battlePoint, { patrolPointName = name, x = row.x, z = row.z, y = row.y, forward = row.forward }, l .. ": battlePoint (nav point + fltKX/fltKY/fltKZ as forward x/z/y)")

	for field, column in pairs({ damageMultiplier = "damageMultiplier", allyArrivalDelay = "allyArrivalDelay", enemyArrivalDelay = "enemyArrivalDelay", allyOriginDist = "allyOriginDist",
		enemyOriginDist = "enemyOriginDist", allyArrivalDist = "allyArrivalDist", enemyArrivalDist = "enemyArrivalDist" }) do
		lu.assertEquals(q[field], rec:num(column), l .. ": " .. field)
	end

	lu.assertEquals(q.allyForce, rec:list("allyForce"), l .. ": allyForce")
	lu.assertEquals(q.enemyForce, rec:list("enemyForce"), l .. ": enemyForce (SWG order)")
	lu.assertEquals({ #q.allyForce, #q.enemyForce }, { 6, 10 }, l .. ": 6 allies and 10 enemies")
end

-- A-2, I-4: destroy 3_b (killVariance 3 is dropped, no validSpawns gives an empty location list)
function TestDennerConformance:test_destroy_3_b_maps_kill_count_ship_types_and_no_locations()
	local q, rec = quest(D.M3[2]), fixtureOf(D.M3[2])
	local l = label(D.M3[2])

	lu.assertEquals(q.killsRequired, rec:num("killCount"), l .. ": killsRequired (killCount)")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), l .. ": shipTypes (shipList)")
	lu.assertEquals(#q.shipTypes, 10, l .. ": ten ship types")
	lu.assertEquals(#rec:list("validSpawns"), 0, l .. ": precondition: the fixture has no validSpawns")
	lu.assertEquals(q.shipLocations, {}, l .. ": shipLocations (no validSpawns)")
	lu.assertNil(rawget(q, "killVariance"), l .. ": killVariance is dropped")
end

-- A-2, I-2, I-4: survival 3_c
function TestDennerConformance:test_survival_3_c_maps_point_timers_attack_lists_and_order_from_its_fixture()
	local q, rec = quest(D.M3[5]), fixtureOf(D.M3[5])
	local l = label(D.M3[5])

	lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
	lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
	lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
	lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
	lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..5, column-wise)")
	lu.assertEquals(#q.attackShipLists, 5, l .. ": five lists")

	for i, list in ipairs(q.attackShipLists) do
		lu.assertEquals(#list, 5, l .. ": attack list " .. i .. " has five ships")
	end

	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- A-2, I-2, I-4: the two assassinates
function TestDennerConformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ D.M4[1], D.M4[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals({ #quest(D.M4[1]).assassinateSpawns.escorts, #quest(D.M4[4]).assassinateSpawns.escorts }, { 5, 6 }, "assassinate 4 and 4_c: 5 and 6 escorts")
end

---------------------------------------------------------------------------------------------
-- I-5: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestDennerCargo = {}

function TestDennerCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- A-2, I-5, FD-9
function TestDennerCargo:test_every_inspect_ship_template_file_carries_the_quest_cargo_as_a_cargo_string()
	for ship, info in pairs(D.CARGO_SHIPS) do
		for _, global in ipairs(info.quests) do
			lu.assertEquals(quest(global).shipList, { ship }, global .. ": shipList")
			lu.assertEquals(quest(global).cargo, info.cargo, global .. ": cargo")
		end

		local src = templateSource(ship)

		lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), info.cargo, ship .. ".lua cargoString must equal the quest cargo (SWG space_mobile.tab row " .. info.smt .. " cargo column)")
		lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), info.cargo, ship .. ".lua questLoot (names the inspect_cargo table) stays")
	end
end

-- A-2, I-5: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestDennerCargo:test_the_loaded_inspect_ship_templates_have_the_cargo_string_and_keep_their_loot_name()
	for ship, info in pairs(D.CARGO_SHIPS) do
		local t = H.shipTemplate(ship)

		lu.assertNotNil(t, "ship_mobile/ships/" .. ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, info.cargo, ship .. ": cargoString")
		lu.assertEquals(t.questLoot, info.cargo, ship .. ": questLoot is unchanged")
	end

	-- R-7: the shuttle stays non-aggressive with no enemy factions
	local shuttle = H.shipTemplate("rebel_scout_shuttle_tier3")

	lu.assertEquals(shuttle.aggressive, 0, "rebel_scout_shuttle_tier3: aggressive is unchanged")
	lu.assertNil(shuttle.enemyFactions, "rebel_scout_shuttle_tier3: no enemyFactions")
end

return nil
