-- Crimson Phoenix tier 4 part A (General Ufwol's missions): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol-missions/01-spec.md (A-1, A-2; invariants I-1 .. I-8, I-10; Content contract 1 and 2; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of crimson_tier4_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right. The four duties share the name
-- tatooine_rebel_tier4_1 with the mission 1 battle head: every fixture is therefore read by type AND name (H.questFixture(type, name)).

local lu = require("luaunit")
local H = require("harness")
local U = require("crimson_tier4_data")
local C = require("crimson_tier1_data")
local E = require("crimson_tier2_data")
local T = require("crimson_tier3_data")

U.load()

local CLONE = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/"

local function quest(global) return U.quest(global) end

local function fixtureOf(global)
	local id = U.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function label(global) return U.IDENTITY[global].type .. "/" .. U.IDENTITY[global].name end

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

local ZONES = { "space_dathomir", "space_endor", "space_yavin4", "space_dantooine" }

local function excerptPath(zone) return "space_zones/buildout/" .. zone .. ".crimson_tier4_points.tab" end

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
-- The oracle itself (these pass before the implementation: they prove the spec literals equal the fixtures and Core3's existing point files)
---------------------------------------------------------------------------------------------

TestUfwolFixtures = {}

function TestUfwolFixtures:setUp() H.reset() end

-- A-2 (the oracle itself): the 13 story fixtures are the four missions of the spec, member by member in their zones: the head names the success child in
-- triggerArg and the failure child in triggerArg2 (both ways), patrol 1_b names surprise 1_c (triggerOn 5), the other ends split nothing, the duties are not chains
function TestUfwolFixtures:test_the_seventeen_fixtures_form_the_four_missions_and_four_duties_of_the_spec()
	for m, b in ipairs(U.BRANCHES) do
		local rec = fixtureOf(b.head)
		local s, f = U.IDENTITY[b.success], U.IDENTITY[b.failure]

		lu.assertEquals(rec:get("triggerEvent"), "splitquest", label(b.head) .. ": triggerEvent (mission " .. m .. ")")
		lu.assertEquals(rec:get("triggerSplitCondition"), "both", label(b.head) .. ": triggerSplitCondition (both ways)")
		lu.assertEquals(rec:get("triggerArg"), s.type .. ":" .. s.name, label(b.head) .. ": triggerArg (the success child)")
		lu.assertEquals(rec:get("triggerArg2"), f.type .. ":" .. f.name, label(b.head) .. ": triggerArg2 (the failure child)")
		lu.assertNil(rec:num("triggerDelay"), label(b.head) .. ": no triggerDelay column on a head (reads 0, sideQuestDelay 5)")
	end

	local patrol = fixtureOf(U.M1[3])

	lu.assertEquals({ patrol:get("triggerEvent"), patrol:get("triggerSplitCondition"), patrol:get("triggerArg"), patrol:num("triggerOn"), patrol:num("triggerDelay"), patrol:num("triggerEndsMission") },
		{ "splitquest", "triggerOn", "destroy_surpriseattack:tatooine_rebel_tier4_1_c", 5, 5, 1 }, label(U.M1[3]) .. ": a triggerOn split at nav point 5 after triggerDelay 5")

	lu.assertEquals(fixtureOf(U.M2[2]):get("questZone"), "space_dathomir", label(U.M2[2]) .. ": questZone (the pickup zone)")
	lu.assertEquals(fixtureOf(U.M4[3]):get("questZone"), "space_dathomir", label(U.M4[3]) .. ": questZone (the cross-zone failure split, FF-2)")
	lu.assertEquals(fixtureOf(U.M4[1]):get("questZone"), "space_endor", label(U.M4[1]) .. ": questZone")

	local ends = { U.M1[2], U.M1[4], U.M2[2], U.M2[3], U.M3[2], U.M3[3], U.M4[2], U.M4[3] }

	for _, global in ipairs(ends) do
		local ev = fixtureOf(global):get("triggerEvent")

		lu.assertTrue(ev == nil or ev == "none", label(global) .. ": an end splits nothing, got triggerEvent " .. tostring(ev))
	end

	for _, global in ipairs(U.DUTIES) do
		local ev = fixtureOf(global):get("triggerEvent")

		lu.assertTrue(ev == nil or ev == "none", label(global) .. ": a duty splits nothing, got triggerEvent " .. tostring(ev))
	end

	for _, global in ipairs(U.GLOBALS) do
		lu.assertEquals(fixtureOf(global):get("questZone"), U.IDENTITY[global].zone, label(global) .. ": questZone")
	end
end

-- A-2 (the oracle itself): delivery 2_a picks up in Dathomir and delivers in Yavin 4 (the zone prefixes of its two points)
function TestUfwolFixtures:test_the_delivery_fixture_crosses_from_dathomir_to_yavin_4()
	local rec = fixtureOf(U.M2[2])

	lu.assertEquals((H.Tab.splitNavPoint(rec:list("pickupPoint")[1])), "space_dathomir", label(U.M2[2]) .. ": pickupPoint zone")
	lu.assertEquals((H.Tab.splitNavPoint(rec:list("deliveryPoint")[1])), "space_yavin4", label(U.M2[2]) .. ": deliveryPoint zone")
end

-- A-2 (the oracle itself): the five fixtures named tatooine_rebel_tier4_1 are five different files
function TestUfwolFixtures:test_the_five_tatooine_rebel_tier4_1_fixtures_are_five_different_files()
	local seen = {}

	for _, global in ipairs({ U.M1[1], U.DUTIES[1], U.DUTIES[2], U.DUTIES[3], U.DUTIES[4] }) do
		local id = U.IDENTITY[global]
		local text = readFile(H.FIXTURES .. "spacequest/" .. id.type .. "/" .. id.name .. ".tab")

		lu.assertNotNil(text, "fixtures/spacequest/" .. id.type .. "/" .. id.name .. ".tab")
		lu.assertNil(seen[text], id.type .. "/" .. id.name .. ": identical to " .. tostring(seen[text]))
		seen[text] = id.type
		lu.assertEquals(id.name, "tatooine_rebel_tier4_1", global .. ": name")
	end

	lu.assertEquals(#U.GLOBALS, 17, "tables")
end

-- A-2, I-2 (the oracle itself): the 17 fixtures are byte copies of the SWG-Source files (skipped when the research clone is absent)
function TestUfwolFixtures:test_the_seventeen_fixtures_are_byte_copies_of_the_swg_source_tabs()
	if readFile(CLONE .. "spacequest/space_battle/tatooine_rebel_tier4_1.tab") == nil then
		lu.skip("the SWG-Source research clone is absent")
	end

	for _, global in ipairs(U.GLOBALS) do
		local id = U.IDENTITY[global]
		local rel = "spacequest/" .. id.type .. "/" .. id.name .. ".tab"

		lu.assertEquals(readFile(H.FIXTURES .. rel), readFile(CLONE .. rel), "fixtures/" .. rel .. " equals the SWG-Source file")
	end
end

-- A-2, I-2 (the oracle itself): the spec's point literals are what the Core3 patrol point files hold (62 nav points)
function TestUfwolFixtures:test_the_spec_points_equal_the_core3_patrol_point_files()
	local n = 0

	for _, zone in ipairs(ZONES) do
		for name, xyz in pairs(U.POINTS[zone]) do
			local p = point(zone, name)

			n = n + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	lu.assertEquals(n, 62, "spec nav points")
end

-- A-2, I-2 (the oracle itself): each buildout excerpt holds exactly the zone's points; Core3's values are their truncated values; the three forwards
function TestUfwolFixtures:test_the_buildout_excerpts_pin_every_point_and_the_three_battle_forwards()
	for _, zone in ipairs(ZONES) do
		local navs = buildout(zone)

		lu.assertEquals(sortedKeys(navs), sortedKeys(U.POINTS[zone]), zone .. ": nav_name rows of the excerpt")

		for name, xyz in pairs(U.POINTS[zone]) do
			lu.assertEquals({ navs[name].x, navs[name].z, navs[name].y }, xyz, zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end
	end

	lu.assertEquals(buildout("space_dathomir").tatooine_rebel_tier4_1_battle_point.forward, U.FORWARD_1, "battle 1 forward = fltKX/fltKY/fltKZ of BODT row 413")
	lu.assertEquals(buildout("space_endor").tatooine_rebel_tier4_3_battle_point.forward, U.FORWARD_3, "battle 3 forward = fltKX/fltKY/fltKZ of BOEN row 60")
	lu.assertEquals(buildout("space_dathomir").tatooine_rebel_tier4_4_b_battle_point.forward, U.FORWARD_4B, "battle 4_b forward = fltKX/fltKY/fltKZ of BODT row 428")
end

-- A-2, I-2 (the oracle itself): the excerpts are the header rows plus rows of the SWG-Source buildout, byte for byte (skipped without the clone)
function TestUfwolFixtures:test_the_buildout_excerpt_rows_are_rows_of_the_swg_source_buildouts()
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

		lu.assertEquals(n, 2 + #sortedKeys(U.POINTS[zone]), zone .. ": excerpt lines (2 header rows + the nav points)")
	end
end

-- A-2, I-7 (the oracle itself): the client journal knows each of the 17 and has exactly 17 tatooine_rebel_tier4 lines and no tier 5 or master entry
function TestUfwolFixtures:test_the_client_quest_name_table_lists_the_seventeen_quests_and_no_tier_5_or_master()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set, tier4, tier5, master = {}, 0, 0, 0

	for line in text:gmatch("[^\r\n]+") do
		set[line] = true

		if line:find("tatooine_rebel_tier4", 1, true) then
			tier4 = tier4 + 1
		end

		if line:find("tatooine_rebel_tier5", 1, true) then
			tier5 = tier5 + 1
		end

		if line:find("tatooine_rebel_master", 1, true) then
			master = master + 1
		end
	end

	for _, global in ipairs(U.GLOBALS) do
		local name = "spacequest/" .. U.IDENTITY[global].type .. "/" .. U.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end

	lu.assertEquals(tier4, 17, "lines containing tatooine_rebel_tier4")
	lu.assertEquals(tier5, 0, "lines containing tatooine_rebel_tier5 (FF-6: not ported)")
	lu.assertEquals(master, 0, "lines containing tatooine_rebel_master (FF-6: dead SWG code)")
end

---------------------------------------------------------------------------------------------
-- A-1: wiring
---------------------------------------------------------------------------------------------

TestUfwolWiring = {}

function TestUfwolWiring:setUp() H.reset() end

-- A-1, I-1
function TestUfwolWiring:test_the_squadron_file_registers_the_seventeen_quests_with_start_true()
	for _, global in ipairs(U.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#U.GLOBALS, 17, "tier 4 globals")
end

-- A-1: Content contract 1 order, after the 33 tier 1-3 globals
function TestUfwolWiring:test_the_seventeen_quests_are_registered_in_the_contract_order_after_the_thirty_three_earlier_quests()
	local order = {}

	for _, global in ipairs(U.TIER3_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(U.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	lu.assertEquals(#order, 50, "33 tier 1-3 + 17 tier 4 globals")

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- A-1, I-1: no global for the dead SWG names
function TestUfwolWiring:test_no_global_exists_for_tatooine_rebel_tier5_or_tatooine_rebel_master()
	U.load()
	lu.assertEquals(#H.questGlobals() >= 50, true, "precondition: the squadron files registered quest globals. Load problems: " .. U.problems())

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		lu.assertNotEquals(q.questName, "tatooine_rebel_tier5", name .. ": tatooine_rebel_tier5 is never granted (FF-6)")
		lu.assertNotEquals(q.questName, "tatooine_rebel_master", name .. ": tatooine_rebel_master is dead code in SWG (D-10)")
	end
end

-- A-1: the squadron object has the seventeen constants, the met key and the reset; every earlier field is unchanged
function TestUfwolWiring:test_the_squadron_screenplay_has_the_seventeen_constants_the_met_key_the_reset_and_every_earlier_field()
	local sq = U.squadron()

	for field, want in pairs(U.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field)
	end

	lu.assertEquals(#U.QUEST_STRING_FIELDS, 17, "constants")
	lu.assertEquals(sq.TIER4_MET_KEY, "CrimsonPhoenixSquadronScreenplay:metTier4", "CrimsonPhoenixSquadronScreenplay.TIER4_MET_KEY")

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 3, unchanged)")
	end

	for field, want in pairs(E.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 2, unchanged)")
	end

	for field, want in pairs(C.QUEST_STRINGS or {}) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.EKER_PILOT_KEY, U.EKER_PILOT_KEY, "EKER_PILOT_KEY unchanged")
	lu.assertEquals(sq.EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "EKER_PILOT_KEY text unchanged")

	for _, fn in ipairs({ "resetSocunaQuests", "resetEkerQuests", "resetUlvawopQuests" }) do
		lu.assertEquals(type(sq[fn]), "function", fn .. " (earlier, unchanged)")
	end

	lu.assertEquals(type(sq.resetUfwolQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetUfwolQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetUfwolQuests, sq, nil), true, "resetUfwolQuests(nil) returns early")
end

-- A-1, Content contract 1: the section comment and the group comments (file text; no behavior)
function TestUfwolWiring:test_the_tier_4_section_and_mission_comments_are_present()
	local text = readFile(H.SCRIPTS .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua") or ""

	for _, want in ipairs({
		"Tier 4 -- General Ufwol (Rori, Rebel outpost; Dathomir, Endor, Yavin 4 and Dantooine systems)",
		"Trainer: General Ufwol (conversation ufwolConvoHandler), Rori Rebel outpost (screenplays/cities/rori_rebel_outpost.lua:49). 17 quest tables for the 13 SWG-Source names tatooine_rebel_tier4_1..4",
		"feature crimson-phoenix-tier4-ufwol-missions",
		"Mission 2's delivery picks up in Dathomir and delivers in Yavin 4 (deliveryZone); mission 4's failure split hands off from Endor to Dathomir (space_battle tatooine_rebel_tier4_4_b)",
		"-- Mission 1: Space battle > Assassinate (won) or Patrol > Surprise attack (lost)",
		"-- Mission 2: Recovery > Delivery (Dathomir to Yavin 4) (won) or Survival (lost)",
		"-- Mission 3: Space battle > Assassinate (won) or Assassinate (lost)",
		"-- Mission 4: Assassinate > Survival (won) or Space battle in Dathomir (lost)",
		"-- General Ufwol Duty Missions",
		"-- Tier 4 (Ufwol); N is the trainer script's mission number",
		"TIER4_MET_KEY = \"CrimsonPhoenixSquadronScreenplay:metTier4\"",
		"-- Clears General Ufwol's quests, journal entries and keys (surrender)",
	}) do
		lu.assertNotNil(text:find(want, 1, true), "CrimsonPhoenixSquadronScreenplay.lua lacks the text: " .. want)
	end

	-- crimson-phoenix-tier4-ufwol: the header names the conversation now
	lu.assertNil(text:find("General Ufwol (no conversation yet)", 1, true), "CSP:1132 still says 'General Ufwol (no conversation yet)'")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (A-2, I-1, I-3, I-5, I-6, I-8, I-10)
---------------------------------------------------------------------------------------------

TestUfwolTables = {}

function TestUfwolTables:setUp() H.reset() end

-- A-2, I-1
function TestUfwolTables:test_the_seventeen_tables_keep_their_identity_and_zone()
	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)
		local id = U.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- A-2, I-1: 13 distinct names, 17 distinct globals, 17 distinct journal entries (FF-5)
function TestUfwolTables:test_there_are_thirteen_names_and_seventeen_globals_and_journal_entries()
	local names, globals, entries = {}, {}, {}

	for _, global in ipairs(U.GLOBALS) do
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
function TestUfwolTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = U.expected()

	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestUfwolTables:test_no_table_defines_a_function()
	for _, global in ipairs(U.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- A-2, I-10: no table sets a status key as data (the keys are the handler's, Part B)
function TestUfwolTables:test_no_table_carries_a_status_key_field()
	for _, global in ipairs(U.GLOBALS) do
		for key in pairs(dataKeys(quest(global))) do
			lu.assertNil(tostring(key):find("[Ss]tatus"), global .. ": " .. tostring(key) .. " looks like a status key")
		end
	end
end

-- A-2, I-6: exactly the four heads are BIDIRECTIONAL at 5 s; patrol 1_b is the only PATROL_POINT table (point 5, 5 s); no other split type exists
function TestUfwolTables:test_the_four_heads_are_bidirectional_at_five_seconds_and_patrol_1_b_is_the_only_patrol_point_split()
	local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES
	local bidirectional, patrolPoint, splitting = {}, {}, {}

	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)
		local t = rawget(q, "sideQuestSplitType")

		if q.sideQuest == true then
			splitting[#splitting + 1] = global
		end

		if t == ST.BIDIRECTIONAL then
			bidirectional[#bidirectional + 1] = global
		elseif t == ST.PATROL_POINT then
			patrolPoint[#patrolPoint + 1] = global
		else
			lu.assertNil(t, global .. ": sideQuestSplitType (no COMPLETION, FAILURE, ATTACK_WAVE or INSPECTION split in this tier)")
		end
	end

	lu.assertEquals(bidirectional, U.HEADS, "the BIDIRECTIONAL tables, in contract order")
	lu.assertEquals(patrolPoint, { U.M1[3] }, "the PATROL_POINT tables")
	lu.assertEquals(splitting, { U.M1[1], U.M1[3], U.M2[1], U.M3[1], U.M4[1] }, "the only tables with sideQuest = true")

	for _, b in ipairs(U.BRANCHES) do
		local q, s, f = quest(b.head), U.IDENTITY[b.success], U.IDENTITY[b.failure]

		lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, s.type, s.name }, b.head .. ": the success split")
		lu.assertEquals({ q.sideFailQuestType, q.sideFailQuestName }, { f.type, f.name }, b.head .. ": the failure split")
		lu.assertEquals(q.sideQuestDelay, 5, b.head .. ": sideQuestDelay (SWG triggerDelay 0 + 5, both ways)")
	end

	local p = quest(U.M1[3])

	lu.assertEquals({ p.sideQuestType, p.sideQuestName, p.sideQuestPatrolStart, p.sideQuestDelay }, { "destroy_surpriseattack", "tatooine_rebel_tier4_1_c", 5, 5 },
		U.M1[3] .. ": PATROL_POINT at nav point 5, 5 s, to surprise 1_c")
	lu.assertEquals(#p.patrolPoints, 6, U.M1[3] .. ": six patrol points (the sixth is never flown)")
end

-- A-2, I-6: every child names its parent; failure children name the head they split from, surprise 1_c names patrol 1_b; the ends and duties split nothing
function TestUfwolTables:test_every_child_names_its_parent_and_the_eight_ends_and_four_duties_do_not_split()
	local parents = {
		[U.M1[2]] = U.M1[1], [U.M1[3]] = U.M1[1], [U.M1[4]] = U.M1[3],
		[U.M2[2]] = U.M2[1], [U.M2[3]] = U.M2[1],
		[U.M3[2]] = U.M3[1], [U.M3[3]] = U.M3[1],
		[U.M4[2]] = U.M4[1], [U.M4[3]] = U.M4[1],
	}
	local ends = { U.M1[2], U.M1[4], U.M2[2], U.M2[3], U.M3[2], U.M3[3], U.M4[2], U.M4[3] }

	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)
		local parent = parents[global]

		if parent then
			local pid = U.IDENTITY[parent]

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

	lu.assertEquals(#ends, 8, "ends: 1_a, 1_c, 2_a, 2_b, 3_a, 3_b, 4_a, 4_b (13 story tables less 4 heads less patrol 1_b; the spec text says seven, it lists eight)")

	for _, global in ipairs(U.DUTIES) do
		lu.assertEquals({ quest(global).sideQuest, quest(global).sideQuestType }, { false, "" }, global .. ": a duty splits nothing")
	end
end

-- A-2, I-6: SpaceHelpers:getSpaceQuestChain returns 4, 3, 3 and 3 members in contract order (success branch before the failure branch)
function TestUfwolTables:test_get_space_quest_chain_returns_each_mission_in_contract_order()
	for n, chain in ipairs(U.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #U.M1, #U.M2, #U.M3, #U.M4 }, { 4, 3, 3, 3 }, "members per mission")
end

-- A-2, I-6: only delivery 2_a sets deliveryZone (space_yavin4), and no table sets pickupZone
function TestUfwolTables:test_only_delivery_2_a_sets_a_delivery_zone_and_no_table_sets_a_pickup_zone()
	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)

		lu.assertNil(rawget(q, "pickupZone"), global .. ": pickupZone")

		if global == U.M2[2] then
			lu.assertEquals({ q.questZone, rawget(q, "deliveryZone") }, { "space_dathomir", "space_yavin4" }, global .. ": questZone (the pickup zone), deliveryZone")
		else
			lu.assertNil(rawget(q, "deliveryZone"), global .. ": deliveryZone")
		end
	end
end

-- A-2, I-5: credits and items on the four heads only (10000 + the Source inventory item, any species); the nine children set neither; duties only their own pay
function TestUfwolTables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)
		local reward = U.REWARDS[global]

		if reward then
			lu.assertEquals(rawget(q, "creditReward"), 10000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = reward.item } }, global .. ": itemReward (any species)")
		elseif U.IDENTITY[global].type:find("_duty") then
			lu.assertNil(rawget(q, "itemReward"), global .. ": a duty pays no item")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(U.REWARDS[U.M1[1]].item, "object/tangible/ship/components/shield_generator/shd_mission_reward_rebel_taim_military_grade.iff", "mission 1 item")
	lu.assertEquals(U.REWARDS[U.M2[1]].item, "object/tangible/ship/components/droid_interface/ddi_mission_reward_rebel_novaldex_low_latency.iff", "mission 2 item")
	lu.assertEquals(U.REWARDS[U.M3[1]].item, "object/tangible/ship/components/booster/bst_mission_reward_rebel_qualdex_halcyon.iff", "mission 3 item")
	lu.assertEquals(U.REWARDS[U.M4[1]].item, "object/tangible/ship/components/weapon/wpn_mission_reward_rebel_incom_tricannon.iff", "mission 4 item")
end

-- A-2, I-3: every ship the tables name has a ship template (the 18 distinct ships of FF-7) and every item an object template (4)
function TestUfwolTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "attackShipLists", "allyForce", "enemyForce", "recoverShips", "targetShipTypes", "shipTypes" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "targetShipType", "deliveryShip", "pickupShip", "bossShip", "recoverShip" }) do
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

	for i, s in ipairs(U.SHIPS) do
		want[i] = s
	end

	table.sort(want)
	lu.assertEquals(sortedKeys(ships), want, "distinct ships in the 17 tables (FF-7)")
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 17 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. U.SHIP_DIR .. name .. ".lua"), U.SHIP_DIR .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- A-2, I-3: both recovery appearances are client mobile templates the server knows
function TestUfwolTables:test_the_recovery_appearances_are_known_client_mobile_templates()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(quest(U.M2[1]).recoveryConversationMobile, U.DROID_MOBILE, U.M2[1] .. ": recoveryConversationMobile")
	lu.assertEquals(quest(U.DUTIES[3]).recoveryConversationMobile, U.PRISONER_MOBILE, U.DUTIES[3] .. ": recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. U.DROID_MOBILE .. '"', 1, true), U.DROID_MOBILE .. " is not in object/mobile/objects.lua")
	lu.assertNotNil(text:find('"' .. U.PRISONER_MOBILE .. '"', 1, true), U.PRISONER_MOBILE .. " is not in object/mobile/objects.lua")
end

-- A-2, I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestUfwolTables:test_every_quest_is_in_the_client_quest_name_table()
	local set = {}

	for line in readFile(H.FIXTURES .. "misc/quest_crc_string_table.names"):gmatch("[^\r\n]+") do
		set[line] = true
	end

	for _, global in ipairs(U.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

-- The conformance tests run twice: against the production tables (TestUfwolConformance) and against the spec literals of crimson_tier4_data.lua
-- (TestUfwolSpecLiterals), so a typo in a literal fails here before it can make a wrong table look right.
local function defineConformance(Tc, quest)
	function Tc:setUp() H.reset() end

	-- A-2, I-4, I-6: zone, split type, targets and delay from each fixture (both: BIDIRECTIONAL, triggerArg / triggerArg2, triggerDelay + 5;
	-- triggerOn: PATROL_POINT, triggerOn as the start point and triggerDelay as is)
	function Tc:test_every_table_takes_zone_and_both_split_targets_and_delay_from_its_fixture()
		local ST = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES

		for _, global in ipairs(U.GLOBALS) do
			local q, rec = quest(global), fixtureOf(global)
			local l = label(global)

			lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

			if rec:get("triggerEvent") == "splitquest" then
				local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))
				local condition = rec:get("triggerSplitCondition")

				lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

				if condition == "both" then
					local failType, failName = H.Tab.splitQuestRef(rec:get("triggerArg2"))

					lu.assertEquals(q.sideQuestSplitType, ST.BIDIRECTIONAL, l .. ": BIDIRECTIONAL (triggerSplitCondition both)")
					lu.assertEquals({ q.sideFailQuestType, q.sideFailQuestName }, { failType, failName }, l .. ": sideFailQuestType, sideFailQuestName (triggerArg2)")
					lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:498-509 and 581-602)")
				else
					lu.assertEquals(condition, "triggerOn", l .. ": precondition: the only other split condition of this tier")
					lu.assertEquals(q.questType, "patrol", l .. ": precondition: only the patrol splits on triggerOn")
					lu.assertEquals(q.sideQuestSplitType, ST.PATROL_POINT, l .. ": PATROL_POINT (triggerOn, triggerEndsMission 1)")
					lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
					lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay") or 0, l .. ": sideQuestDelay (triggerDelay, no +5 on a patrol split)")
					lu.assertNil(rawget(q, "sideFailQuestType"), l .. ": a patrol split has no failure target")
				end
			else
				lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (no split)")
				lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
			end
		end
	end

	-- A-2, I-2, I-4: the three battles and battle 4_b (forward from fltK*)
	function Tc:test_battles_map_point_forward_timers_distances_and_forces()
		local sizes = { [U.M1[1]] = { 5, 9, "space_dathomir" }, [U.M3[1]] = { 4, 9, "space_endor" }, [U.M4[3]] = { 4, 10, "space_dathomir" } }

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

	-- A-2, I-2, I-4: the four assassinates (mustDestroyEscort 0 / 0 / 1 / 0; failTimer is Core3's 20)
	function Tc:test_assassinates_map_target_escorts_delay_path_and_flag()
		local sizes = { [U.M1[2]] = { 6, 5, 5 }, [U.M3[2]] = { 8, 5, 5 }, [U.M3[3]] = { 5, 6, 5 }, [U.M4[1]] = { 6, 6, 10 } }

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

		lu.assertEquals({ quest(U.M1[2]).mustDestroyEscort, quest(U.M3[2]).mustDestroyEscort, quest(U.M3[3]).mustDestroyEscort, quest(U.M4[1]).mustDestroyEscort },
			{ false, false, true, false }, "assassinate 1_a, 3_a, 3_b and 4: mustDestroyEscort")
		lu.assertEquals(quest(U.M4[1]).assassinateSpawns.target, "imp_decimator_tier4", "assassinate 4: the target")
		lu.assertEquals(quest(U.M3[2]).assassinateSpawns.target, "lambdashuttle_station_commander", "assassinate 3_a: the target")
	end

	-- A-2, I-2, I-4: patrol 1_b (laps and specialTarget are not mapped; the sixth point is stored, never flown)
	function Tc:test_patrol_1_b_maps_the_six_nav_points_numbered_with_radius_150()
		local q, rec = quest(U.M1[3]), fixtureOf(U.M1[3])
		local l = label(U.M1[3])

		lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), l .. ": patrolPoints (navPoints, patrolNumber, radius 150)")
		lu.assertEquals(#q.patrolPoints, 6, l .. ": six points")
	end

	-- A-2, I-4: surprise 1_c (six interceptors in the quest zone)
	function Tc:test_surprise_1_c_maps_ship_count_and_zone()
		local q, rec = quest(U.M1[4]), fixtureOf(U.M1[4])
		local l = label(U.M1[4])

		lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } },
			l .. ": surpriseAttackShips (shipType, shipCount, zone)")
		lu.assertEquals(q.surpriseAttackShips.spawns, { { count = 6, shipName = "imp_tie_interceptor_tier4" } }, l .. ": 6 imp_tie_interceptor_tier4")
	end

	-- A-2, I-2, I-4: recovery 2 (Core3's recovery cycles its lists in order; SWG's random is not modelled, D-11)
	function Tc:test_recovery_2_maps_ships_paths_attack_lists_appearance_and_taunts()
		local q, rec = quest(U.M2[1]), fixtureOf(U.M2[1])
		local l = label(U.M2[1])

		lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
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
		lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints, #q.attackShips, #q.escortShips }, { 6, 4, 2, 9 }, l .. ": 6 + 4 points, 2 attack lists, 9 escorts")
		lu.assertEquals({ q.arrivalDelay, q.recoveryDelay, q.attackDelay }, { 10, 30, 45 }, l .. ": delays")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: random (not modelled, D-11)")
	end

	-- A-2, I-2, I-4: delivery 2_a crosses zones: the pickup is in the questZone, the drop-off in the zone prefix of the deliveryPoint
	function Tc:test_delivery_2_a_maps_ships_points_attack_lists_period_order_and_both_zones()
		local q, rec = quest(U.M2[2]), fixtureOf(U.M2[2])
		local l = label(U.M2[2])
		local pickupZone = H.Tab.splitNavPoint(rec:list("pickupPoint")[1])
		local deliveryZone = H.Tab.splitNavPoint(rec:list("deliveryPoint")[1])

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.pickupShip, rec:get("pickupShip"), l .. ": pickupShip")
		lu.assertEquals(q.pickupPoint, mapped(rec, "pickupPoint")[1], l .. ": pickupPoint")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint (looked up in the point's own zone, space_yavin4)")
		lu.assertEquals(pickupZone, q.questZone, l .. ": the pickup point's zone is the questZone (so no pickupZone)")
		lu.assertNil(rawget(q, "pickupZone"), l .. ": no pickupZone")
		lu.assertEquals({ pickupZone, deliveryZone, rawget(q, "deliveryZone") }, { "space_dathomir", "space_yavin4", "space_yavin4" }, l .. ": deliveryZone (the deliveryPoint's zone prefix)")
		lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, l .. ": attackListType RANDOM")
		lu.assertEquals({ #q.attackShipLists, q.attackPeriod }, { 3, 45 }, l .. ": 3 lists, period 45")
	end

	-- A-2, I-2, I-4: survivals 2_b and 4_a
	function Tc:test_survivals_map_point_timers_attack_lists_and_order_from_their_fixtures()
		for _, global in ipairs({ U.M2[3], U.M4[2] }) do
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

		lu.assertEquals({ quest(U.M2[3]).totalTransmissionTime, quest(U.M2[3]).timesToUpdateProgress, quest(U.M2[3]).attackPeriod }, { 240, 4, 50 }, "survival 2_b: 240 / 4 / 50")
		lu.assertEquals({ quest(U.M4[2]).totalTransmissionTime, quest(U.M4[2]).timesToUpdateProgress, quest(U.M4[2]).attackPeriod }, { 360, 6, 55 }, "survival 4_a: 360 / 6 / 55")
	end

	-- A-2, I-4: the destroy duty (reward -> creditReward; numResponses is not mapped)
	function Tc:test_the_destroy_duty_maps_levels_rounds_waves_boss_lists_and_pay()
		local q, rec = quest(U.DUTIES[1]), fixtureOf(U.DUTIES[1])
		local l = label(U.DUTIES[1])

		lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { rec:num("wavesPerRound"), rec:num("roundsPerLevel"), rec:num("levelsPerDuty") }, l .. ": totalWaves, totalRounds, totalLevels")
		lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { 4, 3, 5 }, l .. ": 4 waves, 3 rounds, 5 levels")
		lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
		lu.assertEquals(q.shipTypes, attackLists(rec, rec:num("shipTypes"), "shipType"), l .. ": shipTypes (shipType1..N, column-wise)")
		lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
		lu.assertNil(rawget(q, "numResponses"), l .. ": numResponses is not mapped")
	end

	-- A-2, I-4: the escort duty (one ship, picked at random as SWG)
	function Tc:test_the_escort_duty_maps_ships_points_lists_delay_taunts_and_pay()
		local q, rec = quest(U.DUTIES[2]), fixtureOf(U.DUTIES[2])
		local l = label(U.DUTIES[2])

		lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes)")
		lu.assertEquals(q.escortPoints, mapped(rec, "escortPoints", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end),
			l .. ": escortPoints (zoneName, numbered from 1, radius 250)")
		lu.assertEquals(q.attackShips, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShips (column-wise)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (numResponses)")
		lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus (reward, killReward)")
		lu.assertEquals({ #q.escortShips, #q.escortPoints, q.attackDelay, q.creditReward, q.creditKillBonus }, { 1, 5, 45, 5000, 300 }, l .. ": 1 ship, 5 points, 45 s, 5000, 300")
	end

	-- A-2, I-4: the recovery duty (random lists run in order in Core3's recovery)
	function Tc:test_the_recovery_duty_maps_ships_paths_lists_appearance_taunts_and_pay()
		local q, rec = quest(U.DUTIES[3]), fixtureOf(U.DUTIES[3])
		local l = label(U.DUTIES[3])

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
		lu.assertEquals({ #q.preRecoveryPoints, #q.recoveryPoints, #q.attackShips, #q.escortShips }, { 4, 4, 3, 3 }, l .. ": 4 + 4 points, 3 attack lists, 3 escorts")
	end

	-- A-2, I-4: the rescue duty (four points, two target types)
	function Tc:test_the_rescue_duty_maps_path_targets_lists_period_order_responses_and_pay()
		local q, rec = quest(U.DUTIES[4]), fixtureOf(U.DUTIES[4])
		local l = label(U.DUTIES[4])

		lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
		lu.assertEquals(q.targetShipTypes, rec:list("targetShipTypes"), l .. ": targetShipTypes")
		lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
		lu.assertEquals(q.attackShipLists, attackLists(rec, rec:num("numAttackShipLists")), l .. ": attackShipLists (column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "random", l .. ": precondition: the fixture is random")
		lu.assertEquals(q.attackListType, 1, l .. ": attackListType (random = 1)")
		lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
		lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus")
		lu.assertEquals({ #q.recoveryPath, #q.targetShipTypes, #q.attackShipLists }, { 4, 2, 3 }, l .. ": 4 points, 2 target types, 3 attack lists")
	end
end

TestUfwolConformance = {}
defineConformance(TestUfwolConformance, function(global) return U.quest(global) end)

TestUfwolSpecLiterals = {}
defineConformance(TestUfwolSpecLiterals, function(global) return U.expected()[global] end)

return nil
