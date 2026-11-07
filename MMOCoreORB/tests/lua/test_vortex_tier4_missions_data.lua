-- Vortex tier 4 part A (Brother Extok Evin's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/vortex-tier4-extok-evin/01-spec.md (A-1, A-2; invariants I-1 .. I-8, I-10; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of vortex_tier4_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right. The four duties share the name
-- naboo_rebel_tier4_1 with the mission 1 survival head: every fixture is therefore read by type AND name (H.questFixture(type, name)).

local lu = require("luaunit")
local H = require("harness")
local E = require("vortex_tier4_data")
local V1 = require("vortex_tier1_data")
local V2 = require("vortex_tier2_data")
local W = require("vortex_tier3_data")

E.load()

local CLONE = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/"

local function quest(global) return E.quest(global) end

local function fixtureOf(global)
	local id = E.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return E.IDENTITY[global].type .. "/" .. E.IDENTITY[global].name end

local function readFile(path)
	local f = io.open(path, "rb")

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

local ZONES = { "space_endor", "space_yavin4", "space_dathomir", "space_dantooine" }

local function excerptPath(zone) return "space_zones/buildout/" .. zone .. ".vortex_tier4_points.tab" end

-- the rows of a zone's buildout excerpt: nav_name -> { x, z, y, forward }
local function buildout(zone)
	local tab = H.fixture(excerptPath(zone))
	local navs = {}

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")

		if nav ~= nil then
			navs[nav] = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")),
				forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") } }
		end
	end

	return navs
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

local function attackLists(rec, count, prefix)
	local lists = {}

	for i = 1, count do
		lists[i] = rec:list((prefix or "attackShips") .. i)
	end

	return lists
end

local function realRadius(i) return { escortNumber = i, radius = 250 } end

local function tauntsOf(rec, fields)
	local m = rec:num("numResponses")
	local out = {}

	for _, f in ipairs(fields) do
		out[f] = m
	end

	return out
end

local function allLines(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\r?\n") do
		out[#out + 1] = line
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestEvinFixtures = {}

function TestEvinFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 13 story fixtures are the four missions of the spec, member by member in their zones: the head names the success child in
-- triggerArg and the failure child in triggerArg2 (both ways), surprise 2_b names 2_c (success), the other ends split nothing, the duties are not chains
function TestEvinFixtures:test_the_seventeen_fixtures_form_the_four_missions_and_four_duties_of_the_spec()
	for m, b in ipairs(E.BRANCHES) do
		local rec = fixtureOf(b.head)
		local s, f = E.IDENTITY[b.success], E.IDENTITY[b.failure]

		lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(b.head) .. ": triggerEvent (mission " .. m .. ")")
		lu.assertEquals(rec:get("triggerSplitCondition"), "both", label(b.head) .. ": triggerSplitCondition (both ways)")
		lu.assertEquals(rec:get("triggerArg"), s.type .. ":" .. s.name, label(b.head) .. ": triggerArg (the success child)")
		lu.assertEquals(rec:get("triggerArg2"), f.type .. ":" .. f.name, label(b.head) .. ": triggerArg2 (the failure child)")
		lu.assertNil(rec:num("triggerDelay"), label(b.head) .. ": no triggerDelay column on a head (reads 0, sideQuestDelay 5)")
	end

	local surprise = fixtureOf(E.M2[3])

	lu.assertEquals({ surprise:get("triggerEvent"), surprise:get("triggerSplitCondition"), surprise:get("triggerArg"), surprise:num("triggerDelay") },
		{ "splitquest", "success", "assassinate:naboo_rebel_tier4_2_c", 5 }, label(E.M2[3]) .. ": a success split to assassinate 2_c after triggerDelay 5")
	lu.assertEquals(fixtureOf(E.M2[4]):get("questZone"), "space_dathomir", label(E.M2[4]) .. ": questZone (the cross-zone split, FE-2)")
	lu.assertEquals(fixtureOf(E.M2[3]):get("questZone"), "space_yavin4", label(E.M2[3]) .. ": questZone")

	local ends = { E.M1[2], E.M1[3], E.M2[2], E.M2[4], E.M3[2], E.M3[3], E.M4[2], E.M4[3] }

	for _, global in ipairs(ends) do
		local ev = fixtureOf(global):get("triggerEvent")

		lu.assertTrue(ev == nil or ev == "none", label(global) .. ": an end splits nothing, got triggerEvent " .. tostring(ev))
	end

	for _, global in ipairs(E.DUTIES) do
		local ev = fixtureOf(global):get("triggerEvent")

		lu.assertTrue(ev == nil or ev == "none", label(global) .. ": a duty splits nothing, got triggerEvent " .. tostring(ev))
	end

	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(fixtureOf(global):get("questZone"), E.IDENTITY[global].zone, label(global) .. ": questZone")
	end
end

-- A-2 (the oracle itself): the five fixtures named naboo_rebel_tier4_1 are five different files
function TestEvinFixtures:test_the_five_naboo_rebel_tier4_1_fixtures_are_five_different_files()
	local seen = {}

	for _, global in ipairs({ E.M1[1], E.DUTIES[1], E.DUTIES[2], E.DUTIES[3], E.DUTIES[4] }) do
		local id = E.IDENTITY[global]
		local text = readFile(H.FIXTURES .. "spacequest/" .. id.type .. "/" .. id.name .. ".tab")

		lu.assertNotNil(text, "fixtures/spacequest/" .. id.type .. "/" .. id.name .. ".tab")
		lu.assertNil(seen[text], id.type .. "/" .. id.name .. ": identical to " .. tostring(seen[text]))
		seen[text] = id.type
		lu.assertEquals(id.name, "naboo_rebel_tier4_1", global .. ": name")
	end

	lu.assertEquals(#E.GLOBALS, 17, "tables")
end

-- A-2, I-2 (the oracle itself): the 17 fixtures are byte copies of the SWG-Source files (skipped when the research clone is absent)
function TestEvinFixtures:test_the_seventeen_fixtures_are_byte_copies_of_the_swg_source_tabs()
	if readFile(CLONE .. "spacequest/survival/naboo_rebel_tier4_1.tab") == nil then
		lu.skip("the SWG-Source research clone is absent")
	end

	for _, global in ipairs(E.GLOBALS) do
		local id = E.IDENTITY[global]
		local rel = "spacequest/" .. id.type .. "/" .. id.name .. ".tab"

		lu.assertEquals(readFile(H.FIXTURES .. rel), readFile(CLONE .. rel), "fixtures/" .. rel .. " equals the SWG-Source file")
	end
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the Core3 patrol point files hold (57 nav points)
function TestEvinFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(E.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 57, "spec nav points")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points; Core3's values are their truncated values; the three forwards
function TestEvinFixtures:test_the_buildout_excerpts_pin_every_point_and_the_three_battle_forwards()
	for _, zone in ipairs(ZONES) do
		local navs = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(E.POINTS[zone]), zone .. ": nav_name rows of the excerpt")

		for name, xyz in pairs(E.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end
	end

	lu.assertEquals(buildout("space_yavin4").naboo_rebel_tier4_2_a_battle_point.forward, E.FORWARD_2A, "battle 2_a forward = fltKX/fltKY/fltKZ of BOYV row 128")
	lu.assertEquals(buildout("space_dathomir").naboo_rebel_tier4_4_battle_point.forward, E.FORWARD_4, "battle 4 forward = fltKX/fltKY/fltKZ of BODT row 163")
	lu.assertEquals(buildout("space_dathomir").naboo_rebel_tier4_4_a_battle_point.forward, E.FORWARD_4A, "battle 4_a forward = fltKX/fltKY/fltKZ of BODT row 169")
end

-- A-2, I-2 (the oracle itself): the excerpts are the header rows plus rows of the SWG-Source buildout, byte for byte (skipped without the clone)
function TestEvinFixtures:test_the_buildout_excerpt_rows_are_rows_of_the_swg_source_buildouts()
	if readFile(CLONE .. "space_zones/buildout/space_endor.tab") == nil then
		lu.skip("the SWG-Source research clone is absent")
	end

	for _, zone in ipairs(ZONES) do
		local clone = {}

		for i, line in ipairs(allLines(readFile(CLONE .. "space_zones/buildout/" .. zone .. ".tab"))) do
			clone[line] = i
		end

		local rows = allLines(readFile(H.FIXTURES .. excerptPath(zone)))
		local last, n = 0, 0

		for i, line in ipairs(rows) do
			if line ~= "" then
				n = n + 1
				lu.assertNotNil(clone[line], zone .. ": excerpt line " .. i .. " is not a line of the SWG-Source buildout")

				if i > 2 then
					lu.assertTrue(clone[line] > last, zone .. ": excerpt line " .. i .. " is out of file order")
					last = clone[line]
				end
			end
		end

		lu.assertEquals(n, 2 + #sortedKeys(E.POINTS[zone]), zone .. ": excerpt lines (2 header rows + the nav points)")
	end
end

-- A-2, I-7 (the oracle itself): the client journal knows each of the 17 and has exactly 17 naboo_rebel_tier4 lines and no naboo_rebel_tier5
function TestEvinFixtures:test_the_client_quest_name_table_lists_the_seventeen_quests_and_no_tier_5()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set, tier4, tier5 = {}, 0, 0

	for line in text:gmatch("[^\r\n]+") do
		set[line] = true

		if line:find("naboo_rebel_tier4", 1, true) then
			tier4 = tier4 + 1
		end

		if line:find("naboo_rebel_tier5", 1, true) then
			tier5 = tier5 + 1
		end
	end

	for _, global in ipairs(E.GLOBALS) do
		local name = "spacequest/" .. E.IDENTITY[global].type .. "/" .. E.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end

	lu.assertEquals(tier4, 17, "lines containing naboo_rebel_tier4")
	lu.assertEquals(tier5, 0, "lines containing naboo_rebel_tier5 (FE-6: not ported)")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestEvinWiring = {}

function TestEvinWiring:setUp() H.reset() end

-- A-1, I-1
function TestEvinWiring:test_the_squadron_file_registers_the_seventeen_quests_with_start_true()
	for _, global in ipairs(E.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#E.GLOBALS, 17, "tier 4 globals")
end

-- A-1: Content contract 1 order, after the 37 tier 1-3 globals
function TestEvinWiring:test_the_seventeen_quests_are_registered_in_the_contract_order_after_the_thirty_seven_earlier_quests()
	local order = {}

	for _, global in ipairs(E.TIER3_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(E.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 54, "37 tier 1-3 + 17 tier 4 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1, I-1: no global for the dead SWG names
function TestEvinWiring:test_no_global_exists_for_naboo_rebel_tier5_or_naboo_rebel_master()
	E.load()

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		lu.assertNotEquals(q.questName, "naboo_rebel_tier5", name .. ": naboo_rebel_tier5 is never granted (FE-6)")
		lu.assertNotEquals(q.questName, "naboo_rebel_master", name .. ": naboo_rebel_master is dead code in SWG (D-10)")
	end
end

-- A-1: the squadron object has the seventeen constants, the met key and the reset; every earlier field is unchanged
function TestEvinWiring:test_the_squadron_screenplay_has_the_seventeen_constants_the_met_key_the_reset_and_every_earlier_field()
	local sq = E.squadron()

	for field, want in pairs(E.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field)
	end

	lu.assertEquals(#E.QUEST_STRING_FIELDS, 17, "constants")
	lu.assertEquals(sq.TIER4_MET_KEY, "VortexSquadronScreenplay:metTier4", "VortexSquadronScreenplay.TIER4_MET_KEY")

	for field, want in pairs(W.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 3, unchanged)")
	end

	for field, want in pairs(V2.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 2, unchanged)")
	end

	for field, want in pairs(V1.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "VortexSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.VORTEX_PILOT_KEY, E.VORTEX_PILOT_KEY, "VORTEX_PILOT_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_IMP_ASKING_KEY, "VortexSquadronScreenplay:kiizeteImpIsAsking", "KIIZETE_IMP_ASKING_KEY unchanged")
	lu.assertEquals(sq.KIIZETE_Q1_DISCUSSED_KEY, "VortexSquadronScreenplay:kiizeteQ1Discussed", "KIIZETE_Q1_DISCUSSED_KEY unchanged")

	for _, fn in ipairs({ "resetV3fxQuests", "resetVrovelQuests", "resetEzkielQuests", "hasKiizeteFlag" }) do
		lu.assertEquals(type(sq[fn]), "function", fn .. " (earlier, unchanged)")
	end

	lu.assertEquals(type(sq.resetEvinQuests), "function", "VortexSquadronScreenplay:resetEvinQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetEvinQuests, sq, nil), true, "resetEvinQuests(nil) returns early")
end

-- A-1: the header comment of the squadron file (the one changed line)
function TestEvinWiring:test_the_squadron_file_header_names_tiers_2_to_4()
	local text = readFile(H.SCRIPTS .. E.SQUADRON_FILE)

	lu.assertNotNil(text, E.SQUADRON_FILE)

	local head = {}

	for i, line in ipairs(allLines(text)) do
		if i <= 30 then
			head[#head + 1] = line
		end
	end

	local joined = "\n" .. table.concat(head, "\n") .. "\n"

	lu.assertNotNil(joined:find("\n\tTiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are below\n", 1, true),
		"the header line '\\tTiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are below' in the first 30 lines")
	lu.assertNil(joined:find("tier 4 (Brother Extok Evin) is not ported yet", 1, true), "the old 'not ported yet' header line is gone")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-5, I-6, I-8, I-10)
---------------------------------------------------------------------------------------------

TestEvinTables = {}

function TestEvinTables:setUp() H.reset() end

-- A-2, I-1
function TestEvinTables:test_the_seventeen_tables_keep_their_identity_and_zone()
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

-- A-2, I-1: 13 distinct names, 17 distinct globals, 17 distinct journal entries (FE-5)
function TestEvinTables:test_there_are_thirteen_names_and_seventeen_globals_and_journal_entries()
	local names, globals, entries = {}, {}, {}

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)

		names[q.questName] = true
		globals[q.className] = true
		entries[q.questType .. "/" .. q.questName] = true
	end

	lu.assertEquals(#sortedKeys(names), 13, "distinct quest names")
	lu.assertEquals(#sortedKeys(globals), 17, "distinct globals")
	lu.assertEquals(#sortedKeys(entries), 17, "distinct journal entries (type and name)")
end

-- A-2: Appendix B, every key, nothing else
function TestEvinTables:test_each_table_equals_the_contract_and_sets_no_other_key()
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
function TestEvinTables:test_no_table_defines_a_function()
	for _, global in ipairs(E.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-10: no table sets a status key as data (the keys are the handler's, Part B)
function TestEvinTables:test_no_table_carries_a_status_key_field()
	for _, global in ipairs(E.GLOBALS) do
		for key in pairs(dataKeys(quest(global))) do
			lu.assertNil(tostring(key):find("[Ss]tatus"), global .. ": " .. tostring(key) .. " looks like a status key")
		end
	end
end

-- A-2, I-6: exactly the four heads are BIDIRECTIONAL at 5 s; surprise 2_b is the only COMPLETION table (10 s); no other split type exists
function TestEvinTables:test_the_four_heads_are_bidirectional_at_five_seconds_and_surprise_2_b_is_the_only_completion_split_at_ten()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local bidirectional, completion = {}, {}

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local t = rawget(q, "sideQuestSplitType")

		if t == ST.BIDIRECTIONAL then
			bidirectional[#bidirectional + 1] = global
		elseif t == ST.COMPLETION then
			completion[#completion + 1] = global
		else
			lu.assertNil(t, global .. ": sideQuestSplitType (no FAILURE, PATROL_POINT, ATTACK_WAVE or INSPECTION split in this tier)")
		end
	end

	lu.assertEquals(bidirectional, E.HEADS, "the BIDIRECTIONAL tables, in contract order")
	lu.assertEquals(completion, { E.M2[3] }, "the COMPLETION tables")

	for _, b in ipairs(E.BRANCHES) do
		local q, s, f = quest(b.head), E.IDENTITY[b.success], E.IDENTITY[b.failure]

		lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, s.type, s.name }, b.head .. ": the success split")
		lu.assertEquals({ q.sideFailQuestType, q.sideFailQuestName }, { f.type, f.name }, b.head .. ": the failure split")
		lu.assertEquals(q.sideQuestDelay, 5, b.head .. ": sideQuestDelay (SWG triggerDelay 0 + 5, both ways)")
	end

	lu.assertEquals({ quest(E.M2[3]).sideQuestType, quest(E.M2[3]).sideQuestName, quest(E.M2[3]).sideQuestDelay }, { "assassinate", "naboo_rebel_tier4_2_c", 10 },
		E.M2[3] .. ": the split to assassinate 2_c after triggerDelay 5 + 5")
end

-- A-2, I-6: every child names its parent; failure children name the head they split from; the ends and the duties split nothing
function TestEvinTables:test_every_child_names_its_parent_and_the_eight_ends_and_four_duties_do_not_split()
	local parents = {
		[E.M1[2]] = E.M1[1], [E.M1[3]] = E.M1[1], [E.M2[2]] = E.M2[1], [E.M2[3]] = E.M2[1], [E.M2[4]] = E.M2[3],
		[E.M3[2]] = E.M3[1], [E.M3[3]] = E.M3[1], [E.M4[2]] = E.M4[1], [E.M4[3]] = E.M4[1],
	}
	local ends = { E.M1[2], E.M1[3], E.M2[2], E.M2[4], E.M3[2], E.M3[3], E.M4[2], E.M4[3] }

	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local parent = parents[global]

		if parent then
			local pid = E.IDENTITY[parent]

			lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { parent, pid.type, pid.name }, global .. ": parent fields")
		else
			lu.assertNil(rawget(q, "parentQuest"), global .. ": a head or duty has no parent")
		end
	end

	for _, global in ipairs(ends) do
		lu.assertEquals({ quest(global).sideQuest, quest(global).sideQuestType }, { false, "" }, global .. ": an end splits nothing")
		lu.assertNil(rawget(quest(global), "sideQuestName"), global .. ": an end names no split")
		lu.assertNil(rawget(quest(global), "sideFailQuestType"), global .. ": an end has no failure split")
	end

	for _, global in ipairs(E.DUTIES) do
		lu.assertEquals({ quest(global).sideQuest, quest(global).sideQuestType }, { false, "" }, global .. ": a duty splits nothing")
	end
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain returns 3, 4, 3 and 3 members in contract order (success branch before the failure branch)
function TestEvinTables:test_get_space_quest_chain_returns_each_mission_in_contract_order()
	for n, chain in ipairs(E.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #E.M1, #E.M2, #E.M3, #E.M4 }, { 3, 4, 3, 3 }, "members per mission")
end

-- A-2, I-5: credits and items on the four heads only (10000 + the Source inventory item, any species); the nine children set neither; duties only their own pay
function TestEvinTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	for _, global in ipairs(E.GLOBALS) do
		local q = quest(global)
		local reward = E.REWARDS[global]

		if reward then
			lu.assertEquals(rawget(q, "creditReward"), 10000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = reward.item } }, global .. ": itemReward (any species)")
		elseif E.IDENTITY[global].type:find("_duty") then
			lu.assertNil(rawget(q, "itemReward"), global .. ": a duty pays no item")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(E.REWARDS[E.M1[1]].item, "object/tangible/ship/components/shield_generator/shd_mission_reward_rebel_taim_military_grade.iff", "mission 1 item")
	lu.assertEquals(E.REWARDS[E.M2[1]].item, "object/tangible/ship/components/droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff", "mission 2 item")
	lu.assertEquals(E.REWARDS[E.M3[1]].item, "object/tangible/ship/components/booster/bst_mission_reward_rebel_qualdex_halcyon.iff", "mission 3 item")
	lu.assertEquals(E.REWARDS[E.M4[1]].item, "object/tangible/ship/components/weapon/wpn_mission_reward_rebel_incom_tricannon.iff", "mission 4 item")
end

-- A-2, I-3: every ship the tables name has a ship template (the 26 distinct ships of FE-8) and every item an object template (4)
function TestEvinTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

		for _, field in ipairs({ "escortShips", "attackShips", "attackShipLists", "allyForce", "enemyForce", "recoverShips", "targetShipTypes", "shipTypes" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "targetShipType", "deliveryShip", "bossShip" }) do
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

	for i, s in ipairs(E.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 17 tables (FE-8)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 17 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. E.SHIP_DIR .. name .. ".lua"), E.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: the recovery duty's appearance is a client mobile template the server knows
function TestEvinTables:test_the_recovery_duty_appearance_is_a_known_client_mobile_template()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(quest(E.DUTIES[3]).recoveryConversationMobile, E.DROID_MOBILE, E.DUTIES[3] .. ": recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. E.DROID_MOBILE .. '"', 1, true), E.DROID_MOBILE .. " is not in object/mobile/objects.lua")
end

-- A-2, I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestEvinTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in readFile(H.FIXTURES .. "misc/quest_crc_string_table.names"):gmatch("[^\r\n]+") do
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

-- The conformance tests run twice: against the production tables (TestEvinConformance) and against the spec literals of vortex_tier4_data.lua
-- (TestEvinSpecLiterals), so a typo in a literal fails here before it can make a wrong table look right.
local function defineConformance(T, quest)
	function T:setUp() H.reset() end

	-- A-2, I-4, I-6: zone, split type, targets and delay from each fixture (both: BIDIRECTIONAL, triggerArg / triggerArg2, triggerDelay + 5; success: COMPLETION)
	function T:test_every_table_takes_zone_and_both_split_targets_and_delay_from_its_fixture()
		local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

		for _, global in ipairs(E.GLOBALS) do
			local q, rec = quest(global), fixtureOf(global)
			local l = label(global)

			lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

			if rec:get("triggerEvent") == "splitquest" then
				local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
				local delay = (rec:num("triggerDelay") or 0) + 5
				local condition = rec:get("triggerSplitCondition")

				lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

				if condition == "both" then
					local failType, failName = H.Tab.splitQuestRef(rec:get("triggerArg2"))

					lu.assertEquals(q.sideQuestSplitType, ST.BIDIRECTIONAL, l .. ": BIDIRECTIONAL (triggerSplitCondition both)")
					lu.assertEquals({ q.sideFailQuestType, q.sideFailQuestName }, { failType, failName }, l .. ": sideFailQuestType, sideFailQuestName (triggerArg2)")
				else
					lu.assertEquals(condition, "success", l .. ": precondition: the only other split condition of this tier")
					lu.assertEquals(q.sideQuestSplitType, ST.COMPLETION, l .. ": COMPLETION (triggerSplitCondition success)")
					lu.assertNil(rawget(q, "sideFailQuestType"), l .. ": a success split has no failure target")
				end

				lu.assertEquals(q.sideQuestDelay, delay, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:498-509 and 581-602)")
			else
				lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (no split)")
				lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
			end
		end
	end

	-- A-2, I-2, I-4: survival 1 and 4_b
	function T:test_survivals_map_point_timers_attack_lists_and_order_from_their_fixtures()
		for _, global in ipairs({ E.M1[1], E.M4[3] }) do
			local q, rec = quest(global), fixtureOf(global)
			local l = label(global)

			lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")

			for _, field in ipairs({ "totalTransmissionTime", "timesToUpdateProgress", "transmissionStartDelay", "delayToFirstAttack", "attackPeriod" }) do
				lu.assertEquals(q[field], rec:num(field), l .. ": " .. field)
			end

			lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (attackShips1..N, column-wise)")
			lu.assertEquals(#q.attackShipLists, 4, l .. ": four attack lists")

			for i, list in ipairs(q.attackShipLists) do
				lu.assertEquals(#list, 6, l .. ": attack list " .. i .. " has six ships")
			end

			lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
			lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
		end

		lu.assertEquals({ quest(E.M1[1]).totalTransmissionTime, quest(E.M1[1]).timesToUpdateProgress, quest(E.M1[1]).attackPeriod }, { 360, 6, 55 }, "survival 1: 360 / 6 / 55")
		lu.assertEquals({ quest(E.M4[3]).totalTransmissionTime, quest(E.M4[3]).timesToUpdateProgress, quest(E.M4[3]).attackPeriod }, { 240, 4, 45 }, "survival 4_b: 240 / 4 / 45")
	end

	-- A-2, I-2, I-4: the four assassinates (mustDestroyEscort 0 / 0 / 0 / 1; failTimer is Core3's 20)
	function T:test_assassinates_map_target_escorts_delay_path_and_flag()
		local sizes = { [E.M1[2]] = { 8, 6, 5 }, [E.M2[1]] = { 6, 6, 10 }, [E.M2[4]] = { 6, 5, 10 }, [E.M3[2]] = { 6, 5, 10 } }

		for global, want in pairs(sizes) do
			local q, rec = quest(global), fixtureOf(global)
			local l = label(global)

			lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
			lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
			lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order, plain points)")
			lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
			lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
			lu.assertEquals({ #q.assassinateSpawns.escorts, #q.targetPatrols, q.arrivalDelay }, want, l .. ": escorts, patrol points, arrivalDelay")
		end

		lu.assertEquals({ quest(E.M1[2]).mustDestroyEscort, quest(E.M3[2]).mustDestroyEscort }, { false, true }, "assassinate 1_a and 3_a: mustDestroyEscort false / true")
		lu.assertEquals(quest(E.M2[4]).questZone, "space_dathomir", "assassinate 2_c is in space_dathomir")
		lu.assertEquals(quest(E.M2[4]).targetPatrols[1].patrolPointName, "naboo_rebel_tier4_2_c_assassin_1", "assassinate 2_c: the first path point")
	end

	-- A-2, I-2, I-4: escort 1_b (numResponses 5 gives 5 of each key; Core3's escort has no list type, the fixture is random)
	function T:test_escort_1_b_maps_ship_points_attack_lists_delay_and_taunts()
		local q, rec = quest(E.M1[3]), fixtureOf(E.M1[3])
		local l = label(E.M1[3])

		lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
		lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (escortPath, zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShips (attackShips1..N, column-wise)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
		lu.assertEquals({ #q.attackShips, q.attackDelay, #q.escortPoints }, { 4, 45, 4 }, l .. ": 4 attack lists, delay 45, 4 points")
	end

	-- A-2, I-2, I-4: battles 2_a, 4 and 4_a (forward from fltK*)
	function T:test_battles_map_point_forward_timers_distances_and_forces()
		local sizes = { [E.M2[2]] = { 4, 10, "space_yavin4" }, [E.M4[1]] = { 5, 9, "space_dathomir" }, [E.M4[2]] = { 4, 9, "space_dathomir" } }

		for global, want in pairs(sizes) do
			local q, rec = quest(global), fixtureOf(global)
			local l = label(global)
			local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
			local row = buildout(want[3])[name]

			lu.assertEquals(zone, want[3], l .. ": battlePoint zone")
			lu.assertNotNil(row, l .. ": the buildout excerpt has " .. name)
			lu.assertEquals(q.battlePoint, { patrolPointName = name, x = row.x, z = row.z, y = row.y, forward = row.forward }, l .. ": battlePoint (nav point + fltKX/fltKY/fltKZ as forward x/z/y)")

			for _, field in ipairs({ "damageMultiplier", "allyArrivalDelay", "enemyArrivalDelay", "allyOriginDist", "enemyOriginDist", "allyArrivalDist", "enemyArrivalDist" }) do
				lu.assertEquals(q[field], rec:num(field), l .. ": " .. field)
			end

			lu.assertEquals(q.allyForce, rec:list("allyForce"), l .. ": allyForce")
			lu.assertEquals(q.enemyForce, rec:list("enemyForce"), l .. ": enemyForce (SWG order)")
			lu.assertEquals({ #q.allyForce, #q.enemyForce }, { want[1], want[2] }, l .. ": allies, enemies")
		end
	end

	-- A-2, I-4: surprise 2_b (the SWG spawn: 9 interceptor guards in the quest zone)
	function T:test_surprise_2_b_maps_ship_count_and_zone()
		local q, rec = quest(E.M2[3]), fixtureOf(E.M2[3])
		local l = label(E.M2[3])

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } },
			l .. ": surpriseAttackShips (shipType, shipCount, zone)")
		lu.assertEquals(q.surpriseAttackShips.spawns, { { count = 9, shipName = "tieinterceptor_inquisitor_guard" } }, l .. ": 9 tieinterceptor_inquisitor_guard")
	end

	-- A-2, I-2, I-4: rescue 3 (a plain path, random lists, 5 responses)
	function T:test_rescue_3_maps_path_target_attack_lists_and_responses()
		local q, rec = quest(E.M3[1]), fixtureOf(E.M3[1])
		local l = label(E.M3[1])

		lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
		lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
		lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
		lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
		lu.assertEquals({ q.targetShipType, q.targetArrivalDelay, q.numResponses, #q.recoveryPath }, { "tie_vortex_spy", 5, 5, 4 }, l .. ": tie_vortex_spy, 5 s, 5 responses, 4 points")
	end

	-- A-2, I-2, I-4: delivery_no_pickup 3_b (single zone: no deliveryZone)
	function T:test_delivery_3_b_maps_ship_point_attack_lists_period_and_order()
		local q, rec = quest(E.M3[3]), fixtureOf(E.M3[3])
		local l = label(E.M3[3])

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")
		lu.assertNil(rawget(q, "pickupPoint"), l .. ": a delivery_no_pickup has no pickup")
		lu.assertNil(rawget(q, "deliveryZone"), l .. ": single zone: no deliveryZone")
		lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
		lu.assertEquals({ #q.attackShipLists, q.attackPeriod }, { 4, 60 }, l .. ": 4 lists, period 60")
	end

	-- A-2, I-4: the destroy duty (reward -> creditReward; numResponses is not mapped)
	function T:test_the_destroy_duty_maps_levels_rounds_waves_boss_lists_and_pay()
		local q, rec = quest(E.DUTIES[1]), fixtureOf(E.DUTIES[1])
		local l = label(E.DUTIES[1])

		lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { rec:num("wavesPerRound"), rec:num("roundsPerLevel"), rec:num("levelsPerDuty") }, l .. ": totalWaves, totalRounds, totalLevels")
		lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { 4, 3, 5 }, l .. ": 4 waves, 3 rounds, 5 levels")
		lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
		lu.assertEquals(q.shipTypes, attackLists(rec, rec:num("shipTypes"), "shipType"), l .. ": shipTypes (shipType1..N, column-wise)")
		lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
		lu.assertNil(rawget(q, "numResponses"), l .. ": numResponses is not mapped")
	end

	-- A-2, I-4: the escort duty (one ship picked at random, as SWG)
	function T:test_the_escort_duty_maps_ships_points_lists_delay_taunts_and_pay()
		local q, rec = quest(E.DUTIES[2]), fixtureOf(E.DUTIES[2])
		local l = label(E.DUTIES[2])

		lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes)")
		lu.assertEquals(q.escortPoints, mapped(rec, "escortPoints", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackShips, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShips (column-wise)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
		lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus (reward, killReward)")
		lu.assertEquals({ #q.escortShips, #q.escortPoints, q.attackDelay, q.creditReward, q.creditKillBonus }, { 5, 5, 50, 5000, 300 }, l .. ": 5 ships, 5 points, 50 s, 5000, 300")
	end

	-- A-2, I-4: the recovery duty (random lists run in order in Core3's recovery, V3A FV-4)
	function T:test_the_recovery_duty_maps_ships_paths_lists_appearance_taunts_and_pay()
		local q, rec = quest(E.DUTIES[3]), fixtureOf(E.DUTIES[3])
		local l = label(E.DUTIES[3])

		lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), l .. ": recoverShips (targetShipTypes)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
		lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
		lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", realRadius), l .. ": preRecoveryPoints (escortPath, no zoneName, numbered from 1)")
		lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", realRadius), l .. ": recoveryPoints (recoveryPath, renumbered from 1)")
		lu.assertEquals(q.attackShips, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShips (column-wise)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")),
			l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (numResponses)")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
		lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus")
		lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints, #q.attackShips, #q.escortShips }, { 6, 4, 3, 3 }, l .. ": 6 + 4 points, 3 attack lists, 3 escorts")
	end

	-- A-2, I-4: the rescue duty (six points, the sixth Ezkiel's naboo_rebel_tier3_rescue_3: SWG's own list)
	function T:test_the_rescue_duty_maps_path_targets_lists_period_order_responses_and_pay()
		local q, rec = quest(E.DUTIES[4]), fixtureOf(E.DUTIES[4])
		local l = label(E.DUTIES[4])

		lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
		lu.assertEquals(q.recoveryPath[6].patrolPointName, "naboo_rebel_tier3_rescue_3", l .. ": the sixth point")
		lu.assertEquals(q.targetShipTypes, rec:list("targetShipTypes"), l .. ": targetShipTypes")
		lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
		lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, 1, l .. ": attackListType (random = 1)")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
		lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus")
		lu.assertEquals({ #q.recoveryPath, #q.targetShipTypes, #q.attackShipLists }, { 6, 3, 3 }, l .. ": 6 points, 3 target types, 3 attack lists")
	end
end

TestEvinConformance = {}
defineConformance(TestEvinConformance, function(global) return E.quest(global) end)

TestEvinSpecLiterals = {}
defineConformance(TestEvinSpecLiterals, function(global) return E.expected()[global] end)

return nil
