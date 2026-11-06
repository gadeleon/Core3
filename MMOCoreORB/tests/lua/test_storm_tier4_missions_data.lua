-- Storm tier 4 part A (Admiral Kilnstrider's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (A-1, A-2; invariants I-1 .. I-8; Content contract 1 to 3; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of storm_tier4_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local D3 = require("storm_tier3_data")
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

local function allLines(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
	end

	return out
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function indexOf(list, wanted, from)
	for i = from or 1, #list do
		if trim(list[i]) == wanted then
			return i
		end
	end
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

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. zone)
	return p
end

-- a column of points as the .tab lists them: { zone, name, x, z, y } per cell (the coordinates come from Core3's patrol point file)
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

local function attackLists(rec, count)
	local lists = {}

	for i = 1, count or rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

-- the rows of a buildout excerpt: nav_name -> { x, z, y, forward }, strSpawnerName -> { x, z, y }
local function buildout(zone)
	local tab = H.fixture("space_zones/buildout/" .. zone .. ".storm_tier4_points.tab")
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

local function tauntsOf(rec, fields)
	-- FA-5: numResponses N >= 1 gives N, 0 gives the client file's count 5
	local m = rec:num("numResponses") or 0

	if m == 0 then
		m = 5
	end

	local out = {}

	for _, f in ipairs(fields) do
		out[f] = m
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestKilnstriderFixtures = {}

function TestKilnstriderFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 16 story fixtures are the four chains of the spec, member by member; the ends split nothing
function TestKilnstriderFixtures:test_the_sixteen_story_fixtures_form_the_four_chains_of_the_spec()
	local n = 0

	for c, chain in ipairs(D.CHAINS) do
		for i, global in ipairs(chain) do
			local rec = fixtureOf(global)

			n = n + 1
			lu.assertEquals(rec:get("questZone"), D.IDENTITY[global].zone, label(global) .. ": questZone")

			if i < #chain then
				local nid = D.IDENTITY[chain[i + 1]]

				lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(global) .. ": triggerEvent")
				lu.assertEquals(rec:get("triggerArg"), nid.type .. ":" .. nid.name, label(global) .. ": triggerArg (mission " .. c .. ", the next chain member)")
			else
				lu.assertEquals(rec:get("triggerEvent"), "none", label(global) .. ": the chain end splits nothing")
			end
		end
	end

	lu.assertEquals(n, 16, "story fixtures")

	for _, global in ipairs(D.DUTIES) do
		lu.assertEquals(fixtureOf(global):get("questZone"), "space_endor", label(global) .. ": questZone")
	end
end

-- A-2, FA-1 (the oracle itself): no failure split anywhere, and every delay but patrol 1's is 0, so COMPLETION is delay + 5 = 5
function TestKilnstriderFixtures:test_every_split_is_a_success_or_end_split_with_no_delay_except_the_patrol_one()
	for _, global in ipairs(D.STORY) do
		local rec = fixtureOf(global)

		if rec:get("triggerEvent") == "splitquest" then
			local cond = rec:get("triggerSplitCondition")

			if global == D.M1[1] then
				lu.assertEquals({ cond, rec:num("triggerOn"), rec:num("triggerEndsMission"), rec:num("triggerDelay") }, { "triggerOn", 3, 1, 20 }, "patrol/tatooine_imperial_tier4_1")
			else
				lu.assertTrue(cond == "success" or rec:num("triggerOn") == -1, label(global) .. ": the split fires on success or at the end, not on failure (FA-1); condition " .. tostring(cond))
				lu.assertEquals(rec:num("triggerDelay") or 0, 0, label(global) .. ": triggerDelay (every COMPLETION split is 0 + 5 = 5 s)")
			end
		end
	end
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the patrol point files hold today (71 nav points)
function TestKilnstriderFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for name, xyz in pairs(D.POINTS) do
		local zone = D.POINT_ZONE(name)
		local p = point(zone, name)

		n = n + 1
		lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
	end

	lu.assertEquals(n, 71, "spec nav points (52 Endor + 19 Dantooine)")
end

-- A-2, I-2 (the oracle itself): the buildout excerpts hold exactly the 71 points and the one spawner; the spec's values are their truncated values
function TestKilnstriderFixtures:test_the_buildout_excerpts_pin_every_point_and_the_inspect_spawner()
	local endorNavs, endorSpawners = buildout("space_endor")
	local danNavs, danSpawners = buildout("space_dantooine")
	local want = { endor = {}, dantooine = {} }

	for name in pairs(D.POINTS) do
		want[D.POINT_ZONE(name) == D.ZONE and "endor" or "dantooine"][name] = true
	end

	lu.assertEquals(sortedKeys(endorNavs), sortedKeys(want.endor), "nav_name rows of the space_endor excerpt")
	lu.assertEquals(sortedKeys(danNavs), sortedKeys(want.dantooine), "nav_name rows of the space_dantooine excerpt")
	lu.assertEquals(sortedKeys(endorSpawners), sortedKeys(D.SPAWNERS), "strSpawnerName rows of the space_endor excerpt")
	lu.assertEquals(sortedKeys(danSpawners), {}, "no spawner row in the space_dantooine excerpt")

	for name, xyz in pairs(D.POINTS) do
		local row = (D.POINT_ZONE(name) == D.ZONE and endorNavs or danNavs)[name]

		lu.assertEquals({ row.x, row.z, row.y }, xyz, "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end

	for name, xyz in pairs(D.SPAWNERS) do
		lu.assertEquals({ endorSpawners[name].x, endorSpawners[name].z, endorSpawners[name].y }, xyz, "buildout fltPX/fltPY/fltPZ truncated, spawner " .. name)
	end

	lu.assertEquals(endorNavs.tatooine_imperial_tier4_spacebattle1.forward, D.FORWARD_1B, "battle 1_b forward = fltKX/fltKY/fltKZ of BOE row 314")
	lu.assertEquals(endorNavs.tatooine_imperial_tier4_spacebattle2.forward, D.FORWARD_3B, "battle 3_b forward = fltKX/fltKY/fltKZ of BOE row 406")
end

-- A-2, I-2 (the oracle itself): the excerpt rows are the clone's rows at the lines the spec names (skipped when the clone is not on this machine)
function TestKilnstriderFixtures:test_the_excerpts_equal_the_swg_source_rows_when_the_clone_is_present()
	local root = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/"
	local cases = {
		{ "space_zones/buildout/space_endor.tab", "space_zones/buildout/space_endor.storm_tier4_points.tab",
			{ 4, 6, 47, 48, 49, 59, 66, 67, 71, 73, 79, 86, 139, 142, 143, 160, 201, 204, 210, 212, 213, 220, 221, 223, 224, 227, 258, 260, 261, 264, 265, 266, 281, 287,
				293, 298, 299, 306, 308, 310, 312, 313, 314, 316, 317, 318, 372, 373, 398, 400, 401, 405, 406 } },
		{ "space_zones/buildout/space_dantooine.tab", "space_zones/buildout/space_dantooine.storm_tier4_points.tab",
			{ 36, 42, 61, 217, 235, 239, 255, 305, 306, 314, 357, 360, 371, 379, 380, 381, 383, 398, 401 } },
		{ "space_mobile/space_mobile.tab", "space_mobile/space_mobile.storm_tier4_inspect.tab", { 1442 } },
	}
	local checked = 0

	for _, case in ipairs(cases) do
		local clone = readFile(root .. case[1])
		local excerpt = readFile(H.FIXTURES .. case[2])

		lu.assertNotNil(excerpt, case[2])

		if clone ~= nil then
			local cloneLines, excerptLines = {}, {}

			for line in clone:gmatch("([^\n]*)\n") do
				cloneLines[#cloneLines + 1] = line
			end

			for line in excerpt:gmatch("([^\n]*)\n") do
				excerptLines[#excerptLines + 1] = line
			end

			local want = { cloneLines[1], cloneLines[2] }

			for _, n in ipairs(case[3]) do
				want[#want + 1] = cloneLines[n]
			end

			lu.assertEquals(excerptLines, want, case[2] .. ": header rows and the spec's rows of the clone")
			checked = checked + 1
		end
	end

	if checked == 0 then
		lu.skip("the SWG-Source clone is not on this machine")
	end
end

-- A-2, I-2 (the oracle itself): the inspect spawner exists in Core3's endor spawner table at the spec's position and spawns only its quest ship
function TestKilnstriderFixtures:test_the_inspect_spawner_exists_in_the_core3_spawner_table_with_only_its_quest_ship()
	local spawners = H.spawners("space_endor")

	for name, xyz in pairs(D.SPAWNERS) do
		local s = spawners[name]

		lu.assertNotNil(s, "space_endor_spawner.lua: spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "spawner position " .. name)
		lu.assertEquals(s.shipSpawns, { "rebel_endscout_tier4" }, "spawner ships " .. name)
	end
end

-- A-2, I-7 (the oracle itself): the client journal knows the 20 quests, and exactly one more tatooine_imperial_tier4 line, the client-only orphan
function TestKilnstriderFixtures:test_the_client_quest_name_table_lists_the_twenty_quests_and_the_orphan_recovery_2_c()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set, matching = {}, 0

	for line in text:gmatch("[^\n]+") do
		set[line] = true

		if line:find("tatooine_imperial_tier4", 1, true) then
			matching = matching + 1
		end
	end

	for _, global in ipairs(D.GLOBALS) do
		local name = "spacequest/" .. D.IDENTITY[global].type .. "/" .. D.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end

	lu.assertEquals(matching, 21, "lines with tatooine_imperial_tier4 in the client quest table (the 20 and the orphan)")
	lu.assertTrue(set["spacequest/recovery/tatooine_imperial_tier4_2_c"] == true, "precondition: the client-only orphan recovery/tatooine_imperial_tier4_2_c is in the client table")
	lu.assertNil(rawget(_G, "recovery_tatooine_imperial_tier4_2_c"), "the orphan recovery/tatooine_imperial_tier4_2_c is not ported (the live 2_c is delivery_no_pickup)")
end

-- A-2, I-8 (the oracle itself): the inspect cargo table has one canTransfer-1 row, and SWG's space_mobile cargo column names it
function TestKilnstriderFixtures:test_the_inspect_cargo_fixture_has_one_transferable_row_and_space_mobile_names_it()
	local tab = H.fixture("space_mobile/space_mobile.storm_tier4_inspect.tab")

	lu.assertEquals(#tab.records, 1, "space_mobile excerpt rows (SMT 1442)")
	lu.assertEquals(tab.records[1]:get("strIndex"), D.CARGO_SHIP.ship, "space_mobile.tab row 1442")
	lu.assertEquals(tab.records[1]:get("cargo"), D.CARGO_SHIP.cargo, "space_mobile.tab cargo column of " .. D.CARGO_SHIP.ship)

	local rows = H.fixture("spacequest/inspect_cargo/" .. D.CARGO_SHIP.cargo .. ".tab").records
	local transferable = {}

	for _, rec in ipairs(rows) do
		if rec:num("canTransfer") == 1 then
			transferable[#transferable + 1] = rec:get("name")
		end
	end

	lu.assertEquals(#rows, 1, "inspect_cargo/" .. D.CARGO_SHIP.cargo .. ".tab rows")
	lu.assertEquals(transferable, { D.CARGO_SHIP.cargo }, "the rows with canTransfer 1 in inspect_cargo/" .. D.CARGO_SHIP.cargo .. ".tab")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestKilnstriderWiring = {}

function TestKilnstriderWiring:setUp() H.reset() end

-- A-1, I-1
function TestKilnstriderWiring:test_the_squadron_file_registers_the_twenty_quests_with_start_true()
	for _, global in ipairs(D.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#D.GLOBALS, 20, "tier 4 globals")
end

-- A-1, I-1: Content contract 1 order, after the 40 earlier Storm globals (which keep start = true)
function TestKilnstriderWiring:test_the_twenty_quests_are_registered_in_the_contract_order_after_the_forty_earlier_storm_quests()
	local earlier = {}

	for _, list in ipairs({ T.TIER1_GLOBALS, T.GLOBALS, A.GLOBALS, D3.GLOBALS }) do
		for _, global in ipairs(list) do
			earlier[#earlier + 1] = global
		end
	end

	lu.assertEquals(#earlier, 40, "the 8 + 6 + 6 + 20 earlier Storm globals")

	local last = -1

	for _, global in ipairs(earlier) do
		local reg = H.registered(global)

		lu.assertNotNil(reg, global .. ": an earlier Storm quest is still registered")
		lu.assertTrue(reg.start, global .. ": still registered with start = true")

		if reg.order > last then
			last = reg.order
		end
	end

	local previous = last

	for _, global in ipairs(D.GLOBALS) do
		quest(global)

		local reg = H.registered(global)

		lu.assertNotNil(reg, global .. ": registerScreenPlay was not called")
		lu.assertTrue(reg.order > previous, global .. " is registered after the previous quest (Content contract 1 order, after the 20 tier 3 globals)")
		previous = reg.order
	end
end

-- A-1: the squadron object has the 20 constants and the met key, and every earlier field is unchanged
function TestKilnstriderWiring:test_the_squadron_screenplay_has_the_twenty_constants_the_met_key_and_every_earlier_field()
	local sq = D.squadron()

	for field, want in pairs(D.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field)
	end

	lu.assertEquals(#D.QUEST_STRING_FIELDS, 20, "constants")

	-- the constants are the 20 quests in D.GLOBALS order
	for i, field in ipairs(D.QUEST_STRING_FIELDS) do
		local id = D.IDENTITY[D.GLOBALS[i]]

		lu.assertEquals(sq[field], { type = id.type, name = id.name }, "StormSquadronScreenplay." .. field .. " is quest " .. i .. " of the contract order")
	end

	lu.assertEquals(sq.TIER4_MET_KEY, "StormSquadronScreenplay:metTier4", "TIER4_MET_KEY")

	for field, want in pairs(D3.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (Denner, unchanged)")
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
	lu.assertEquals(type(sq.resetColzetQuests), "function", "resetColzetQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetOberhaurQuests), "function", "resetOberhaurQuests (unchanged)")
	lu.assertEquals(type(sq.resetAlozenQuests), "function", "resetAlozenQuests (unchanged)")
	lu.assertEquals(type(sq.resetDennerQuests), "function", "resetDennerQuests (unchanged)")
	lu.assertEquals(type(sq.resetKilnstriderQuests), "function", "StormSquadronScreenplay:resetKilnstriderQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetKilnstriderQuests, sq, nil), true, "resetKilnstriderQuests(nil) returns early")
end

-- A-1: resetKilnstriderQuests is defined directly after resetDennerQuests, before the Nym technicians comment (file text)
function TestKilnstriderWiring:test_the_reset_sits_directly_after_denners_reset_in_the_squadron_file()
	local list = allLines(readFile(H.SCRIPTS .. D.SQUADRON_FILE))
	local denner = indexOf(list, "function StormSquadronScreenplay:resetDennerQuests(pPlayer)")
	local kilnstrider = indexOf(list, "function StormSquadronScreenplay:resetKilnstriderQuests(pPlayer)")
	local nym = indexOf(list, "-- The Nym fuel technicians on Lok (Morv and two decoys) grant the Kimogila's Claw (feature storm-tier2-nym-technicians)")

	lu.assertNotNil(denner, "resetDennerQuests")
	lu.assertNotNil(kilnstrider, "function StormSquadronScreenplay:resetKilnstriderQuests(pPlayer)")
	lu.assertNotNil(nym, "the Nym technicians comment")
	lu.assertTrue(denner < kilnstrider and kilnstrider < nym, "resetKilnstriderQuests sits between resetDennerQuests and the Nym technicians comment")

	-- no other function between the two resets
	for i = denner + 1, kilnstrider - 1 do
		lu.assertNil(list[i]:match("^function "), "line " .. i .. ": '" .. list[i] .. "' sits between resetDennerQuests and resetKilnstriderQuests")
	end
end

-- A-1, SC-1: space_helpers' Storm branch calls the reset exactly once, directly after Denner's, and no other branch calls it (file text)
function TestKilnstriderWiring:test_the_storm_branch_of_surrender_pilot_calls_the_reset_once_after_denners_and_no_other_branch_does()
	local text = readFile(H.SCRIPTS .. "utils/space_helpers.lua")
	local list = allLines(text)
	local calls = {}

	for i, line in ipairs(list) do
		if line:find("resetKilnstriderQuests", 1, true) then
			calls[#calls + 1] = i
		end
	end

	lu.assertEquals(#calls, 1, "lines of space_helpers.lua mentioning resetKilnstriderQuests")

	local denner = indexOf(list, "StormSquadronScreenplay:resetDennerQuests(pPlayer)")
	local inquisition = indexOf(list, "elseif (pilotSquadron == INQUISITION_SQUADRON) then")

	lu.assertNotNil(denner, "Denner's reset call")
	lu.assertNotNil(inquisition, "the Inquisition branch")
	lu.assertEquals(list[denner + 1], "", "a blank line after Denner's reset")
	lu.assertEquals(list[denner + 2], "\t\t-- Tier 4", "the comment")
	lu.assertEquals(list[denner + 3], "\t\tStormSquadronScreenplay:resetKilnstriderQuests(pPlayer)", "Kilnstrider's reset")
	lu.assertEquals(calls[1], denner + 3, "the only mention is directly after Denner's reset")
	lu.assertEquals(inquisition, denner + 4, "the Storm branch ends with Kilnstrider's reset")
end

-- A-1: rebel_endscout_tier4.lua has the cargoString line directly after its questLoot line (file text)
function TestKilnstriderWiring:test_the_endscout_ship_file_has_the_cargo_string_line_directly_after_the_quest_loot()
	local list = allLines(readFile(H.SCRIPTS .. "ship_mobile/ships/rebel_endscout_tier4.lua"))
	local loot = indexOf(list, 'questLoot = "rebel_battle_plans",')

	lu.assertNotNil(loot, "the questLoot line")
	lu.assertEquals(trim(list[loot + 1]):sub(1, #'cargoString = "rebel_battle_plans",'), 'cargoString = "rebel_battle_plans",', "the line after questLoot")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-5, I-6, I-7)
---------------------------------------------------------------------------------------------

TestKilnstriderTables = {}

function TestKilnstriderTables:setUp() H.reset() end

-- A-2, I-1
function TestKilnstriderTables:test_the_twenty_tables_keep_their_identity_and_zone()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local id = D.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2: Appendix B, every key, nothing else
function TestKilnstriderTables:test_each_table_equals_the_contract_and_sets_no_other_key()
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
function TestKilnstriderTables:test_no_table_defines_a_function()
	for _, global in ipairs(D.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-6: exactly the 12 non-end story tables split to the next chain member (COMPLETION, 5 s; patrol 1 PATROL_POINT at 3, 20 s)
function TestKilnstriderTables:test_exactly_the_twelve_non_end_story_tables_split_and_name_the_next_chain_member()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
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
				local want = (global == D.M1[1]) and { ST.PATROL_POINT, 20 } or { ST.COMPLETION, 5 }

				lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { nextId.type, nextId.name }, global .. ": sideQuestType, sideQuestName (mission " .. c .. ")")
				lu.assertEquals({ q.sideQuestSplitType, q.sideQuestDelay }, want, global .. ": sideQuestSplitType, sideQuestDelay")
				lu.assertNotEquals(q.sideQuestSplitType, ST.BIDIRECTIONAL, global .. ": not BIDIRECTIONAL")
				lu.assertNotEquals(q.sideQuestSplitType, ST.ATTACK_WAVE, global .. ": not ATTACK_WAVE")
			end

			if i > 1 then
				local pid = D.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splits, 12, "split tables")
	lu.assertEquals({ #D.M1, #D.M2, #D.M3, #D.M4 }, { 5, 4, 3, 4 }, "chain lengths (5, 4, 3, 4)")
	lu.assertEquals(quest(D.M1[1]).sideQuestPatrolStart, 3, "patrol 1: sideQuestPatrolStart")
	lu.assertEquals(quest(D.M1[1]).sideQuestDelay, 20, "patrol 1: sideQuestDelay keeps SWG's triggerDelay 20")

	for _, global in ipairs(D.GLOBALS) do
		if global ~= D.M1[1] then
			lu.assertNil(rawget(quest(global), "sideQuestPatrolStart"), global .. ": sideQuestPatrolStart is patrol 1's alone")
		end
	end
end

-- A-2, I-6: the four duties start no side quest
function TestKilnstriderTables:test_the_four_duties_have_no_side_quest_and_no_parent()
	for _, global in ipairs(D.DUTIES) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest, false, global .. ": sideQuest")
		lu.assertEquals(q.sideQuestType, "", global .. ": sideQuestType")
		lu.assertNil(rawget(q, "parentQuest"), global .. ": no parent")
	end
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order (5, 4, 3 and 4 members)
function TestKilnstriderTables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(D.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end
end

-- A-2, I-5: credits and items only on the four heads, with the Content contract 3 literals; the duties carry only their own pay
function TestKilnstriderTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local heads = { [D.M1[1]] = 1, [D.M2[1]] = 2, [D.M3[1]] = 3, [D.M4[1]] = 4 }
	local duties = { [D.DUTIES[1]] = 300, [D.DUTIES[2]] = 5000, [D.DUTIES[3]] = 5000, [D.DUTIES[4]] = 5000 }

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), D.REWARDS[n].credits, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = D.REWARDS[n].item } }, global .. ": itemReward (any species)")
		elseif duties[global] then
			lu.assertEquals(rawget(q, "creditReward"), duties[global], global .. ": the duty's own creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": a duty has no itemReward")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- A-2, I-3: every ship the tables name has a ship template (the 26 distinct ships) and every item an object template (4)
function TestKilnstriderTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "shipTypes", "attackShipLists", "allyForce", "enemyForce", "recoverShips", "targetShipTypes" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "deliveryShip", "pickupShip", "targetShipType", "bossShip" }) do
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
	lu.assertEquals(#want, 26, "spec ships")
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 20 tables")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 20 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: the recovery conversation mobile is a client template the server knows
function TestKilnstriderTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")

	for _, global in ipairs({ D.M2[1], D.M2[2] }) do
		local q = quest(global)

		lu.assertEquals(q.recoveryConversationMobile, D.OFFICER_MOBILE, global .. ": recoveryConversationMobile")
		lu.assertNotNil(text:find('"' .. tostring(q.recoveryConversationMobile) .. '"', 1, true), tostring(q.recoveryConversationMobile) .. " is not in object/mobile/objects.lua")
	end
end

-- A-2, I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestKilnstriderTables:test_every_quest_is_in_the_client_quest_name_table()
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

-- A-2: the particulars the acceptance criterion names, as anchors on the spec literals (a misparsed fixture cannot move them)
function TestKilnstriderTables:test_the_named_particulars_of_the_acceptance_criterion_hold()
	local patrol = quest(D.M1[1])

	lu.assertEquals({ patrol.sideQuestPatrolStart, patrol.sideQuestDelay, #patrol.patrolPoints }, { 3, 20, 4 }, "patrol 1: start 3, delay 20, four points")
	lu.assertEquals(quest(D.M1[2]).surpriseAttackShips, { zone = "space_endor", spawns = { { count = 5, shipName = "reb_awing_tier4" } } }, "surprise 1_a")
	lu.assertEquals(quest(D.M2[1]).recoveryConversationMobile, "object/mobile/shared_space_comm_imperial_officer_02.iff", "recovery 2: recoveryConversationMobile")
	lu.assertEquals(quest(D.M2[2]).recoveryConversationMobile, "object/mobile/shared_space_comm_imperial_officer_02.iff", "recovery 2_a: recoveryConversationMobile")
	lu.assertNil(rawget(quest(D.M4[3]), "recoveryConversationMobile"), "recovery 4_b does not set recoveryConversationMobile")
	lu.assertEquals(quest(D.M4[3]).recoveryConversationMobile, "", "recovery 4_b reads the base's empty string")
	lu.assertEquals(quest(D.M2[2]).tauntData, { panicCount = 5, thanksCount = 5 }, "recovery 2_a: tauntData 5/5 (numResponses 0, FA-5)")

	local names = {}

	for i, p in ipairs(quest(D.M4[2]).targetPatrols) do
		names[i] = p.patrolPointName
	end

	lu.assertEquals(names, { "tatooine_imperial_tier4_assassinate2_1", "tatooine_imperial_tier4_assassinate2_3", "tatooine_imperial_tier4_assassinate2_4" }, "assassinate 4_a: SWG's own list skips assassinate2_2")
	lu.assertEquals(#quest(D.M4[4]).assassinateSpawns.escorts, 11, "assassinate 4_c: eleven escorts")
	lu.assertEquals(quest(D.M4[4]).assassinateSpawns.target, "rebel_command_vessel_tier4", "assassinate 4_c: the target")
	lu.assertEquals(quest(D.M4[4]).mustDestroyEscort, true, "assassinate 4_c: mustDestroyEscort")

	local destroy = quest(D.DUTIES[1])

	lu.assertEquals({ #destroy.shipTypes, destroy.totalLevels, destroy.bossShip }, { 8, 5, "red_skull_pirate_heavy_tier5" }, "destroy duty: 8 lists, 5 levels, boss")
	lu.assertEquals({ #quest(D.DUTIES[2]).escortShips, #quest(D.DUTIES[2]).escortPoints }, { 4, 9 }, "escort duty: 4 ships, 9 points")
	lu.assertEquals(quest(D.M1[3]).battlePoint.forward, { x = -0.162564, z = -0.321512, y = -0.932847 }, "battle 1_b: forward")
	lu.assertEquals(quest(D.M3[3]).battlePoint.forward, { x = -0.699074, z = -0.273777, y = -0.660562 }, "battle 3_b: forward")
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestKilnstriderConformance = {}

function TestKilnstriderConformance:setUp() H.reset() end

-- A-2, I-4, I-6: every story quest: zone, split target and delay from triggerArg (COMPLETION: triggerDelay + 5; the PATROL_POINT split keeps triggerDelay and
-- names the point in triggerOn)
function TestKilnstriderConformance:test_every_story_table_takes_zone_and_split_target_and_delay_from_its_fixture()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

	for _, global in ipairs(D.STORY) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
			local delay = rec:num("triggerDelay") or 0

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

			if global == D.M1[1] then
				lu.assertEquals(q.sideQuestSplitType, ST.PATROL_POINT, l .. ": PATROL_POINT (triggerOn 3, triggerEndsMission 1)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay, the patrol point split keeps it)")
			else
				lu.assertEquals(q.sideQuestSplitType, ST.COMPLETION, l .. ": COMPLETION")
				lu.assertEquals(q.sideQuestDelay, delay + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:600)")
			end
		else
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

-- A-2, I-2, I-4: patrol 1
function TestKilnstriderConformance:test_patrol_1_maps_the_four_nav_points_numbered_with_radius_150()
	local q, rec = quest(D.M1[1]), fixtureOf(D.M1[1])
	local l = label(D.M1[1])

	lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), l .. ": patrolPoints (navPoints, patrolNumber, radius 150)")
	lu.assertEquals(#q.patrolPoints, 4, l .. ": four points (laps 1 is not mapped)")
end

-- A-2, I-4: surprise attack 1_a
function TestKilnstriderConformance:test_surprise_attack_1_a_maps_ship_count_and_zone()
	local q, rec = quest(D.M1[2]), fixtureOf(D.M1[2])

	lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } }, label(D.M1[2]) .. ": surpriseAttackShips (shipType, shipCount, questZone)")
end

-- A-2, I-2, I-4: the two space battles
function TestKilnstriderConformance:test_battles_map_point_forward_timers_distances_and_forces()
	local navs = buildout("space_endor")

	for _, global in ipairs({ D.M1[3], D.M3[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
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
	end

	lu.assertEquals({ #quest(D.M1[3]).allyForce, #quest(D.M1[3]).enemyForce }, { 6, 10 }, "battle 1_b: 6 allies and 10 enemies")
	lu.assertEquals({ #quest(D.M3[3]).allyForce, #quest(D.M3[3]).enemyForce }, { 6, 11 }, "battle 3_b: 6 allies and 11 enemies")
end

-- A-2, I-2, I-4: inspect 1_c
function TestKilnstriderConformance:test_inspect_1_c_maps_ship_spawner_waypoint_flag_and_cargo()
	local _, spawners = buildout("space_endor")
	local q, rec = quest(D.M1[4]), fixtureOf(D.M1[4])
	local l = label(D.M1[4])
	local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
	local s = spawners[spawnName]

	lu.assertNotNil(s, l .. ": the buildout excerpt has the spawner " .. spawnName)
	lu.assertEquals(zone, q.questZone, l .. ": the validSpawns zone is the quest zone")
	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns (zone prefix dropped, buildout position truncated)")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
end

-- A-2, I-2, I-4: the three delivery_no_pickup / delivery tables
function TestKilnstriderConformance:test_deliveries_map_ships_points_attack_lists_period_and_order()
	for _, global in ipairs({ D.M1[5], D.M2[3], D.M2[4] }) do
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
end

-- A-2, I-2, I-4: the three recoveries (the points carry escortNumber and radius 250, no zoneName; the recovery path is renumbered from 1; the officer mobile
-- is mapped for 2 and 2_a only)
function TestKilnstriderConformance:test_recoveries_map_ships_paths_attack_lists_appearance_and_taunts()
	local radius = function(i) return { escortNumber = i, radius = 250 } end

	for _, global in ipairs({ D.M2[1], D.M2[2], D.M4[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
		lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
		lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", radius), l .. ": preRecoveryPoints (escortPath, no zoneName, numbered from 1)")
		lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints (recoveryPath, renumbered from 1)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses; 0 gives the client count 5, FA-5)")

		local appearance = rec:get("recoveryAppearance")

		if appearance ~= nil then
			lu.assertEquals(q.recoveryConversationMobile, (appearance:gsub("^object/mobile/", "object/mobile/shared_")), l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
		else
			lu.assertNil(rawget(q, "recoveryConversationMobile"), l .. ": no recoveryAppearance, so recoveryConversationMobile is not set")
		end
	end

	lu.assertEquals({ #quest(D.M2[1]).escortShips, #quest(D.M2[2]).escortShips, #quest(D.M4[3]).escortShips }, { 5, 6, 7 }, "escort counts of recovery 2, 2_a and 4_b")
	lu.assertEquals({ #quest(D.M2[1]).recoveryPoints, #quest(D.M4[3]).recoveryPoints }, { 3, 3 }, "recovery points of recovery 2 and 4_b")
end

-- A-2, I-2, I-4: escort 3
function TestKilnstriderConformance:test_escort_3_maps_ship_points_attack_lists_delay_and_taunts()
	local q, rec = quest(D.M3[1]), fixtureOf(D.M3[1])
	local l = label(D.M3[1])

	lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPath, zoneName, numbered from 1, radius 250)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..4, column-wise)")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential (Core3 picks a list at random)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	lu.assertEquals(#q.escortPoints, 5, l .. ": five escort points")
end

-- A-2, I-2, I-4: rescue 3_a
function TestKilnstriderConformance:test_rescue_3_a_maps_path_target_attack_lists_and_responses()
	local q, rec = quest(D.M3[2]), fixtureOf(D.M3[2])
	local l = label(D.M3[2])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
end

-- A-2, I-2, I-4: the three assassinates (the target patrols are in file order; 4_a skips assassinate2_2)
function TestKilnstriderConformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ D.M4[1], D.M4[2], D.M4[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals({ #quest(D.M4[1]).assassinateSpawns.escorts, #quest(D.M4[2]).assassinateSpawns.escorts, #quest(D.M4[4]).assassinateSpawns.escorts }, { 6, 6, 11 }, "escorts of assassinate 4, 4_a and 4_c")
	lu.assertEquals({ #quest(D.M4[1]).targetPatrols, #quest(D.M4[2]).targetPatrols, #quest(D.M4[4]).targetPatrols }, { 4, 3, 4 }, "target patrols of assassinate 4, 4_a and 4_c")
end

-- A-2, I-4: the destroy duty (numResponses 0 is not mapped)
function TestKilnstriderConformance:test_destroy_duty_maps_waves_rounds_levels_boss_reward_and_ship_lists()
	local q, rec = quest(D.DUTIES[1]), fixtureOf(D.DUTIES[1])
	local l = label(D.DUTIES[1])
	local lists = {}

	for i = 1, rec:num("shipTypes") do
		lists[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), l .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), l .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), l .. ": totalLevels (levelsPerDuty)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.shipTypes, lists, l .. ": shipTypes (shipType1..8, column-wise)")
	lu.assertEquals(#q.shipTypes, 8, l .. ": eight ship lists")
	lu.assertNil(rawget(q, "numResponses"), l .. ": numResponses 0 is not mapped")
end

-- A-2, I-2, I-4: the escort duty
function TestKilnstriderConformance:test_escort_duty_maps_ships_points_attack_lists_pay_and_taunts()
	local q, rec = quest(D.DUTIES[2]), fixtureOf(D.DUTIES[2])
	local l = label(D.DUTIES[2])

	lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPoints", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPoints, zoneName, numbered from 1, radius 250)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
	lu.assertEquals({ #q.escortShips, #q.escortPoints }, { 4, 9 }, l .. ": four escort ships, nine points")
end

-- A-2, I-2, I-4: the recovery duty
function TestKilnstriderConformance:test_recovery_duty_maps_ships_paths_attack_lists_pay_and_taunts()
	local q, rec = quest(D.DUTIES[3]), fixtureOf(D.DUTIES[3])
	local l = label(D.DUTIES[3])
	local radius = function(i) return { escortNumber = i, radius = 250 } end

	lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), l .. ": recoverShips (targetShipTypes)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", radius), l .. ": preRecoveryPoints (escortPath, numbered from 1)")
	lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints (recoveryPath, renumbered from 1)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (column-wise)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses)")
end

-- A-2, I-2, I-4: the rescue duty
function TestKilnstriderConformance:test_rescue_duty_maps_path_targets_attack_lists_pay_and_responses()
	local q, rec = quest(D.DUTIES[4]), fixtureOf(D.DUTIES[4])
	local l = label(D.DUTIES[4])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipTypes, rec:list("targetShipTypes"), l .. ": targetShipTypes")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: sequential")
	lu.assertEquals(q.attackListType, 0, l .. ": attackListType (0 = SEQUENTIAL)")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
end

---------------------------------------------------------------------------------------------
-- I-8: the inspect cargo, read from the REAL ship template file (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestKilnstriderCargo = {}

function TestKilnstriderCargo:setUp() H.reset() end

-- A-2, I-8, FA-4
function TestKilnstriderCargo:test_the_endscout_ship_template_file_carries_the_quest_cargo_as_a_cargo_string()
	local info = D.CARGO_SHIP
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. info.ship .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. info.ship .. ".lua to exist")
	local src = readFile(path):gsub("%-%-[^\n]*", "")

	lu.assertEquals(src:match('cargoString%s*=%s*"(.-)"'), info.cargo, info.ship .. ".lua cargoString must equal the quest cargo (SWG space_mobile.tab row " .. info.smt .. " cargo column)")
	lu.assertEquals(src:match('questLoot%s*=%s*"(.-)"'), info.cargo, info.ship .. ".lua questLoot (names the inspect_cargo table) stays")
end

-- A-2, I-8: the loaded template (what the server registers) has it too, and the rest of the template did not move
function TestKilnstriderCargo:test_the_loaded_endscout_template_has_the_cargo_string_and_keeps_its_loot_name()
	local info = D.CARGO_SHIP
	local t = H.shipTemplate(info.ship)

	lu.assertNotNil(t, "ship_mobile/ships/" .. info.ship .. ".lua registers a template")
	lu.assertEquals(t.cargoString, info.cargo, info.ship .. ": cargoString")
	lu.assertEquals(t.questLoot, info.cargo, info.ship .. ": questLoot is unchanged")
end

return nil
