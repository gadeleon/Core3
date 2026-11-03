-- Smuggler tier 4 (Nirame Sakute): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7 and I-11; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source files in fixtures/ (the 16 spacequest .tab copies, the four buildout excerpts, the space_mobile and skills excerpts, the
-- inspect_cargo table and Nirame's script). smuggler_tier4_data.lua N.expected() derives every mapped field from them, never from the Core3 tables under
-- test. The first class (TestSmugglerT4Oracle) needs no production code and is green from the start; it proves the fixtures say what the spec relies on.

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")

N.load()

local readFile = N.readFile

local function quest(global) return N.quest(global) end

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

local function ownKeys(q)
	local own = {}

	for k, v in pairs(q) do
		own[k] = v
	end

	return own
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

local function lines(text)
	local out = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = l
	end

	return out
end

local function visit(v, fn)
	if type(v) == "string" then
		fn(v)
	elseif type(v) == "table" then
		for _, x in ipairs(v) do
			visit(x, fn)
		end
	end
end

local SWG_SPACEQUEST = N.SWG_DIR .. "datatables/spacequest/"
local G = N.GLOBALS

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT4Oracle = {}

function TestSmugglerT4Oracle:setUp() H.reset() end

-- AC-2 (the oracle itself): the 16 .tab copies, the inspect_cargo table and NJ are the research clone's files byte for byte
function TestSmugglerT4Oracle:test_the_fixture_copies_equal_the_research_clone_files()
	if readFile(SWG_SPACEQUEST .. "inspect_cargo/valarian_freight_plans.tab") == nil then
		lu.skip("the SWG-Source research clone is not present")
	end

	local pairsOf = {}

	for _, global in ipairs(G) do
		local id = N.IDENTITY[global]

		pairsOf[#pairsOf + 1] = { H.FIXTURES .. "spacequest/" .. id.type .. "/" .. id.name .. ".tab", SWG_SPACEQUEST .. id.type .. "/" .. id.name .. ".tab" }
	end

	pairsOf[#pairsOf + 1] = { H.FIXTURES .. "spacequest/inspect_cargo/valarian_freight_plans.tab", SWG_SPACEQUEST .. "inspect_cargo/valarian_freight_plans.tab" }
	pairsOf[#pairsOf + 1] = { N.NJ, N.SWG_DIR .. "script/conversation/tatooine_privateer_tier4.java" }

	for _, p in ipairs(pairsOf) do
		local copy, original = readFile(p[1]), readFile(p[2])

		lu.assertNotNil(copy, p[1] .. " is missing")
		lu.assertNotNil(original, p[2] .. " is missing")
		lu.assertTrue(copy == original, p[1] .. " differs from " .. p[2])
	end
end

-- AC-2 (the oracle itself): the fixture facts the spec relies on, as anchors so a misparsed fixture cannot make a wrong table look right
function TestSmugglerT4Oracle:test_the_fixtures_carry_the_values_the_spec_lists()
	local d1 = N.fixtureOf(G[1])

	lu.assertEquals({ d1:get("questZone"), d1:get("pickupPoint"), d1:get("deliveryPoint") },
		{ "space_lok", "space_lok:tatooine_privateer_tier4_leg_1_delivery_pickup", "space_dantooine:corellia_privateer_tier3_rescue_3" }, "delivery 1a: zones")
	lu.assertEquals({ d1:get("pickupShip"), d1:get("deliveryShip"), d1:num("numAttackShipLists"), d1:num("attackPeriod"), d1:get("attackListType") },
		{ "nym_freightermedium_tier4", "hutt_transport_tier4", 3, 75, "sequential" }, "delivery 1a")
	lu.assertEquals({ d1:get("triggerEvent"), d1:get("triggerArg") }, { "splitquest", "delivery_no_pickup:tatooine_privateer_tier4_1b" }, "delivery 1a: split")

	local r2a = N.fixtureOf(G[3])

	lu.assertEquals({ r2a:get("targetShipType"), r2a:num("targetArrivalDelay"), r2a:num("targetRecoverTime"), r2a:num("attackPeriod"), r2a:num("numResponses") },
		{ "blacksun_transport_tier4", 11, 18, 90, 2 }, "recovery 2a")
	lu.assertEquals(#r2a:list("targetEscort"), 4, "recovery 2a: targetEscort")
	lu.assertEquals(#N.fixtureOf(G[4]):list("targetEscort"), 0, "recovery 2b: no escorts")
	lu.assertEquals(N.fixtureOf(G[5]):num("totalTransmissionTime"), 3, "survival 2c: totalTransmissionTime (R-5)")

	local i3a = N.fixtureOf(G[6])

	lu.assertEquals({ i3a:list("shipList"), i3a:get("cargo"), i3a:num("giveSpawnWaypoint") }, { { "valarian_gunship_inspect_tier4", "valarian_gunship_inspect" }, "freight_plans", 1 }, "inspect 3a")

	local a3b = N.fixtureOf(G[7])

	lu.assertEquals({ a3b:get("triggerSplitCondition"), a3b:get("triggerArg"), a3b:get("triggerArg2") },
		{ "both", "recovery:tatooine_privateer_tier4_3c", "destroy_surpriseattack:tatooine_privateer_tier4_3c_sa" }, "assassinate 3b: both")
	lu.assertEquals({ a3b:get("targetShipType"), a3b:num("targetArrivalDelay"), a3b:num("mustDestroyEscort") }, { "valarian_gunship_tier5", 7, 1 }, "assassinate 3b")
	lu.assertEquals(N.fixtureOf(G[8]):list("shipCount"), { "5" }, "surprise 3c_sa: shipCount is 5 on row 1 only (FN-7)")
	lu.assertEquals(#N.fixtureOf(G[8]):list("shipType"), 5, "surprise 3c_sa: five listed types")
	lu.assertEquals({ N.fixtureOf(G[9]):num("targetArrivalDelay"), N.fixtureOf(G[9]):get("triggerEvent") }, { 2, "none" }, "recovery 3c")
	lu.assertEquals(N.fixtureOf(G[12]):list("escortPath")[1], N.fixtureOf(G[12]):list("escortPath")[2], "assassinate 4c: the duplicate first point is SWG's")
	lu.assertEquals({ N.fixtureOf(G[13]):num("numResponses"), N.fixtureOf(G[14]):num("numResponses"), N.fixtureOf(G[15]):num("numResponses") }, { 2, 0, 3 }, "duty numResponses (escort, rescue, recovery)")
	lu.assertEquals({ N.fixtureOf(G[13]):num("reward"), N.fixtureOf(G[13]):num("killReward") }, { 5000, 400 }, "escort duty pay")
	lu.assertEquals({ N.fixtureOf(G[16]):num("wavesPerRound"), N.fixtureOf(G[16]):num("roundsPerLevel"), N.fixtureOf(G[16]):num("levelsPerDuty"), N.fixtureOf(G[16]):num("reward") },
		{ 2, 2, 3, 300 }, "destroy duty")
end

-- AC-2, I-5 (the oracle itself): NJ pays 10000 and one component for each of the four missions (the master quest of J is dead code and pays no item)
function TestSmugglerT4Oracle:test_the_script_rewards_are_10000_and_one_mission_reward_component_each()
	local rw = N.rewards()
	local base = "object/tangible/ship/components/"
	local want = {
		["delivery/tatooine_privateer_tier4_1a"] = base .. "booster/bst_mission_reward_neutral_mandal_q_series.iff",
		["recovery/tatooine_privateer_tier4_2a"] = base .. "weapon/wpn_mission_reward_neutral_borstel_disruptor.iff",
		["inspect/tatooine_privateer_tier4_3a"] = base .. "shield_generator/shd_mission_reward_neutral_armek_plasma_web.iff",
		["assassinate/tatooine_privateer_tier4_4a"] = base .. "engine/eng_mission_reward_neutral_haor_chall_military.iff",
	}

	lu.assertEquals(#sortedKeys(rw), 4, "giveReward calls with an item in NJ")

	for key, item in pairs(want) do
		lu.assertEquals(rw[key], { credits = 10000, item = item }, "NJ giveReward " .. key)
	end
end

-- AC-2, I-2 (the oracle itself): the four excerpts hold the rows the spec lists (17 + 29 + 1 spawner + 2 + 8 = 57)
function TestSmugglerT4Oracle:test_the_buildout_excerpts_hold_the_rows_the_spec_lists()
	local total = 0

	for zone, want in pairs({ lok = { nav = 17, spawners = 0 }, dantooine = { nav = 29, spawners = 1 }, tatooine = { nav = 2, spawners = 0 }, endor = { nav = 8, spawners = 0 } }) do
		local b = N.buildout(zone)
		local n = 0

		for _ in pairs(b.nav) do
			n = n + 1
		end

		lu.assertEquals(n, want.nav, zone .. ": nav_name rows")
		lu.assertEquals(#b.spawners, want.spawners, zone .. ": spawner rows")
		lu.assertEquals(#H.fixture("space_zones/buildout/space_" .. zone .. ".smuggler_tier4_points.tab").records, want.nav + want.spawners, zone .. ": data rows")
		total = total + want.nav + want.spawners
	end

	lu.assertEquals(total, 57, "excerpt data rows in the four files")

	local d = N.buildout("dantooine")

	lu.assertEquals({ d.spawners[1].name, d.spawners[1][1], d.spawners[1][2], d.spawners[1][3] }, { "tatooine_privateer_tier4_leg_3_inspect", 7456, -1625, 1458 }, "the spawner row (7456.95 -1625.04 1458.62 truncated)")
end

-- AC-2 (the oracle itself): each excerpt row is a row of the SWG clone (CRLF kept) after the clone's two header rows; the space_mobile and skills excerpts too
function TestSmugglerT4Oracle:test_the_excerpt_rows_equal_the_swg_clone_rows()
	local mobile = readFile(N.SWG_DIR .. "datatables/space_mobile/space_mobile.tab")
	local skills = readFile(N.SWG_DIR .. "../../../sys.shared/compiled/game/datatables/skill/skills.tab")

	if mobile == nil or skills == nil then
		lu.skip("the SWG-Source research clone is not present")
	end

	for _, zone in ipairs(N.ZONES) do
		local clone = readFile(N.SWG_DIR .. "datatables/space_zones/buildout/space_" .. zone .. ".tab")

		if clone == nil then
			lu.skip("the SWG-Source research clone is not present")
		end

		local set = {}

		for i, l in ipairs(lines(clone)) do
			set[l] = set[l] or i
		end

		local exLines = lines(readFile(H.FIXTURES .. "space_zones/buildout/space_" .. zone .. ".smuggler_tier4_points.tab"))

		lu.assertEquals(exLines[#exLines], "", zone .. ": excerpt ends with a newline")

		for i = 1, #exLines - 1 do
			lu.assertNotNil(set[exLines[i]], zone .. ": excerpt line " .. i .. " is not a line of the clone (CRLF kept)")
		end

		lu.assertEquals(set[exLines[1]], 1, zone .. ": excerpt header row 1")
		lu.assertEquals(set[exLines[2]], 2, zone .. ": excerpt header row 2")
	end

	local mlines = lines(mobile)
	local ex = lines(readFile(H.FIXTURES .. "space_mobile/space_mobile.valarian_gunship_inspect.tab"))

	lu.assertEquals({ ex[1], ex[2], ex[3], ex[4] }, { mlines[1], mlines[2], mlines[1858], mlines[1859] }, "space_mobile excerpt = rows 1, 2, 1858, 1859 of space_mobile.tab")

	local slines = lines(skills)
	local sk = lines(readFile(H.FIXTURES .. "skill/skills.pilot_neutral_04.tab"))

	lu.assertEquals({ sk[1], sk[2], sk[3], sk[4], sk[5], sk[6] }, { slines[1], slines[2], slines[646], slines[650], slines[654], slines[658] },
		"skills excerpt = rows 1, 2, 646, 650, 654, 658 of skills.tab")
end

-- AC-2, I-2 (the oracle itself): Core3's patrol point files already hold the buildout values (truncated toward zero) for the 56 points
function TestSmugglerT4Oracle:test_the_core3_point_files_equal_the_buildout_excerpts_truncated()
	local n = 0

	for _, zone in ipairs(N.ZONES) do
		local points = H.patrolPoints("space_" .. zone)

		for name, xyz in pairs(N.buildout(zone).nav) do
			n = n + 1
			lu.assertNotNil(points[name], "space_" .. zone .. ": no Core3 patrol point " .. name)
			lu.assertEquals({ points[name].x, points[name].z, points[name].y }, { xyz[1], xyz[2], xyz[3] }, "space_" .. zone .. ":" .. name .. " (Core3 point file vs buildout)")
		end
	end

	lu.assertEquals(n, 56, "nav points checked")
end

-- AC-2, I-3 (the oracle itself): the ships and items the fixtures name exist in Core3 (32 distinct ship names, 4 items)
function TestSmugglerT4Oracle:test_the_ships_and_reward_items_of_the_fixtures_exist()
	local ships = {}

	for _, global in ipairs(G) do
		local rec = N.fixtureOf(global)

		for _, col in ipairs({ "pickupShip", "deliveryShip", "targetShipType", "targetShipTypes", "targetEscort", "shipList", "shipType", "escortShipTypes", "bossType",
			"attackShips1", "attackShips2", "attackShips3", "attackShips4", "shipType1", "shipType2", "shipType3", "shipType4" }) do
			for _, v in ipairs(rec:list(col)) do
				ships[v] = true
			end
		end
	end

	local n = 0

	for name in pairs(ships) do
		n = n + 1
		lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	lu.assertEquals(n, 32, "distinct ship names in the 16 fixtures")

	for key, rw in pairs(N.rewards()) do
		lu.assertNotNil(readFile(H.SCRIPTS .. rw.item:gsub("%.iff$", ".lua")), key .. ": " .. rw.item .. " has no object file")
	end
end

-- I-7 (the oracle itself): the client journal knows the 16 quests
function TestSmugglerT4Oracle:test_all_16_quests_are_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(G) do
		local id = N.IDENTITY[global]

		lu.assertTrue(set["spacequest/" .. id.type .. "/" .. id.name] == true, "spacequest/" .. id.type .. "/" .. id.name .. " is not in the client quest table")
	end
end

-- I-11 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo, canTransfer 1
function TestSmugglerT4Oracle:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local byShip = {}

	for _, rec in ipairs(H.fixture("space_mobile/space_mobile.valarian_gunship_inspect.tab").records) do
		byShip[rec:get("strIndex")] = rec
	end

	local cargo = N.fixtureOf(G[6]):get("cargo")

	lu.assertEquals(cargo, "freight_plans", "inspect 3a: quest cargo")

	for _, ship in ipairs({ "valarian_gunship_inspect_tier4", "valarian_gunship_inspect" }) do
		lu.assertNotNil(byShip[ship], "the space_mobile excerpt has no row " .. ship)
		lu.assertEquals(byShip[ship]:get("cargo"), "valarian_freight_plans", ship .. ": space_mobile cargo column")
	end

	local row
	local names = {}

	for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/valarian_freight_plans.tab").records) do
		names[#names + 1] = rec:get("name")

		if rec:get("name") == cargo then
			row = rec
		end
	end

	lu.assertNotNil(row, "valarian_freight_plans: has no row " .. cargo .. " (rows " .. table.concat(names, ",") .. ")")
	lu.assertEquals(row:num("canTransfer"), 1, "valarian_freight_plans/freight_plans: canTransfer")
	lu.assertEquals(#names, 1, "valarian_freight_plans: one row")
end

-- AC-10 (the oracle itself): each tier 4 skill needs the four _03 skills' XP type and 1,000,000 XP, 4000 credits (D-3)
function TestSmugglerT4Oracle:test_the_skills_excerpt_prices_the_four_tier_4_skills_at_1000000_xp()
	local seen = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_neutral_04.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_neutral_%a+_04$") then
			seen[name] = { rec:get("XP_TYPE"), rec:num("XP_COST"), rec:num("MONEY_REQUIRED") }
		end
	end

	for _, t in ipairs(N.TRAIN) do
		lu.assertEquals(seen[t.skill], { "space_combat_general", 1000000, 4000 }, t.skill .. ": XP_TYPE, XP_COST, MONEY_REQUIRED")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestSmugglerT4Wiring = {}

function TestSmugglerT4Wiring:setUp() H.reset() end

-- AC-1
function TestSmugglerT4Wiring:test_the_squadron_file_registers_the_16_quests_with_start_true_and_keeps_the_older_ones()
	for _, global in ipairs(G) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	local text = readFile(H.SCRIPTS .. N.SQUADRON_FILE)

	lu.assertEquals(countMatches(text, 'registerScreenPlay%('), 53, N.SQUADRON_FILE .. ": registerScreenPlay calls (37 before: 36 quests and the squadron object; + 16)")
	lu.assertNotNil(H.registered("SmugglerSquadronScreenplay"), "SmugglerSquadronScreenplay is still registered")
	lu.assertNotNil(H.registered("recovery_tatooine_privateer_tier3_1"), "a tier 3 table is still registered")
	lu.assertNotNil(H.registered("assassinate_tatooine_privateer_tier2_1a"), "a tier 2 table is still registered")
	lu.assertNotNil(H.registered("patrol_tatooine_privateer_1"), "a tier 1 table is still registered")
end

-- AC-1: Content contract 1: the section after the tier 3 tables, before the squadron object, in table order, each table followed by its registration
function TestSmugglerT4Wiring:test_the_16_globals_sit_after_the_tier_3_tables_and_before_the_squadron_object_in_the_contract_order()
	local text = readFile(H.SCRIPTS .. N.SQUADRON_FILE)

	lu.assertNotNil(text, N.SQUADRON_FILE)

	local tier3 = text:find('registerScreenPlay("rescue_tatooine_privateer_tier3_4_d", true)', 1, true)
	local squadron = text:find("\nSmugglerSquadronScreenplay = ScreenPlay:new", 1, true)

	lu.assertNotNil(tier3, N.SQUADRON_FILE .. ": the last tier 3 registration")
	lu.assertNotNil(squadron, N.SQUADRON_FILE .. ": the squadron object")

	local last = tier3

	for _, global in ipairs(G) do
		local at = text:find("\n" .. global .. " = ", 1, true)

		lu.assertNotNil(at, N.SQUADRON_FILE .. ": no global " .. global)
		lu.assertTrue(at > last, N.SQUADRON_FILE .. ": " .. global .. " is out of the Content contract 1 order (after the tier 3 tables)")
		lu.assertTrue(at < squadron, N.SQUADRON_FILE .. ": " .. global .. " must come before the squadron object")

		local reg = text:find('registerScreenPlay("' .. global .. '", true)', 1, true)

		lu.assertTrue(reg ~= nil and reg > at, N.SQUADRON_FILE .. ": registerScreenPlay for " .. global .. " follows its table")
		last = reg
	end

	lu.assertNotNil(text:find("Tier 4 -- Nirame Sakute (Dathomir Trade Outpost; Lok, Dantooine, Tatooine, Endor)", 1, true), N.SQUADRON_FILE .. ": the section comment")
end

-- AC-1: Content contract 1: the header sentence
function TestSmugglerT4Wiring:test_the_header_comment_names_tier_4_as_ported()
	local text = readFile(H.SCRIPTS .. N.SQUADRON_FILE)

	lu.assertNotNil(text:find("Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame.", 1, true), N.SQUADRON_FILE .. ": the tier 4 header sentence")
	lu.assertNil(text:find("Tier 4 is not ported yet.", 1, true), N.SQUADRON_FILE .. ": the old 'Tier 4 is not ported yet.'")
end

-- AC-1: Content contract 2
function TestSmugglerT4Wiring:test_the_squadron_object_has_the_tier_4_constants_and_the_reset()
	local sq = N.squadron()

	for field, want in pairs(N.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "SmugglerSquadronScreenplay." .. field)
	end

	lu.assertEquals(type(sq.resetNirameQuests), "function", "SmugglerSquadronScreenplay:resetNirameQuests")
	lu.assertEquals(pcall(sq.resetNirameQuests, sq, nil), true, "resetNirameQuests(nil) returns early")

	-- tiers 1 to 3 and the transition stay as they were
	for _, name in ipairs({ "resetDravisQuests", "resetKarrdeQuests", "resetShamdonQuests", "resetBeissaQuests", "hasCompletedTier2Series" }) do
		lu.assertEquals(type(sq[name]), "function", name .. " still exists")
	end

	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "tatooine_privateer_1" }, "tier 1 constants stay")
	lu.assertEquals(sq.TIER3_QUEST_STRING_1, { type = "recovery", name = "tatooine_privateer_tier3_1" }, "tier 3 constants stay")
end

-- AC-1: Content contract 2: comments and order of the new constants and the reset
function TestSmugglerT4Wiring:test_the_constants_follow_the_tier_3_constants_and_the_reset_follows_resetBeissaQuests()
	local text = readFile(H.SCRIPTS .. N.SQUADRON_FILE)

	lu.assertNotNil(text:find("-- Tier 4 (Nirame Sakute) Quest Strings, SWG mission order; SIDEk = the k-th split child on success, FAIL1 = the failure child", 1, true),
		"comment '-- Tier 4 (Nirame Sakute) Quest Strings, ...'")
	lu.assertNotNil(text:find("-- Tier 4 Duty Quest Strings (SWG duty menu order)", 1, true), "comment '-- Tier 4 Duty Quest Strings (SWG duty menu order)'")
	lu.assertNotNil(text:find("-- Nirame has met the pilot (SWG space flag metTier4); quest status <playerID> .. key = \"1\"", 1, true), "comment on TIER4_MET_KEY")

	local s44 = text:find("TIER3_QUEST_STRING_4_SIDE4 = ", 1, true)
	local s1 = text:find("TIER4_QUEST_STRING_1 = ", 1, true)
	local d4 = text:find("TIER4_QUEST_STRING_DUTY_4 = ", 1, true)
	local met = text:find("TIER4_MET_KEY = ", 1, true)
	local resetBeissa = text:find("function SmugglerSquadronScreenplay:resetBeissaQuests", 1, true)
	local reset = text:find("function SmugglerSquadronScreenplay:resetNirameQuests", 1, true)

	lu.assertTrue(s44 ~= nil and s1 ~= nil and s1 > s44, "TIER4_QUEST_STRING_1 follows the tier 3 constants")
	lu.assertTrue(d4 ~= nil and d4 > s1 and met ~= nil and met > d4, "the constants are in SWG mission order, then the duties, then the met key")
	lu.assertTrue(resetBeissa ~= nil and reset ~= nil and reset > resetBeissa, "resetNirameQuests follows resetBeissaQuests")
	lu.assertNotNil(text:find("Tier 4 -- Nirame Sakute", 1, true), "the method section comment 'Tier 4 -- Nirame Sakute'")
	lu.assertNil(text:find("LEGACY_MIGRATION_STEPS", 1, true), "no LEGACY_MIGRATION_STEPS: nothing is renamed")
end

-- AC-1
function TestSmugglerT4Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	N.requireConversation(lu)

	local t = H.conversationTemplateTable(N.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, N.HANDLER, N.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", N.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, N.HANDLER).getInitialScreen), "function", N.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, N.HANDLER).runScreenHandlers), "function", N.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, N.HANDLER).getNextConversationScreen), "function", N.HANDLER .. ":getNextConversationScreen")
end

-- AC-1: the handler's tables and helpers (Content contract 3) that the tests call directly
function TestSmugglerT4Wiring:test_the_handler_has_the_tables_and_helpers_of_the_content_contract()
	N.requireConversation(lu)

	local h = N.handler()

	for _, name in ipairs({ "getQuestString", "hasStatus", "hasKey", "setKey", "isWon", "isActive", "isFailed", "isPaid", "isOnMission", "canFlyNonTrackDuty",
		"getNextMission", "getReadyMission", "isReadyForTraining", "payMission", "raisePilotTier", "getLastScreenID" }) do
		lu.assertEquals(type(h[name]), "function", N.HANDLER .. ":" .. name)
	end

	lu.assertEquals(#h.MISSIONS, 4, N.HANDLER .. ".MISSIONS")

	for n = 1, 4 do
		local m, want = h.MISSIONS[n], N.MISSIONS[n]

		lu.assertEquals({ m.head or m[1], m.questString or m[2], m.endString or m[3] }, { want.head, want.questString, want.endString }, N.HANDLER .. ".MISSIONS[" .. n .. "] (head, questString, endString)")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, N.HANDLER .. ".TRAIN_CHOICES")

	for i, t in ipairs(N.TRAIN) do
		local c = h.TRAIN_CHOICES[i]

		lu.assertEquals({ c.skill or c[1], c.topic or c[2], c.trained or c[3] }, { t.skill, N.PREFIX .. t.reply, t.trained }, N.HANDLER .. ".TRAIN_CHOICES[" .. i .. "] (skill, topic, trained)")
	end

	lu.assertEquals(h.TRAINED_BRIEFS, N.TRAINED_BRIEFS, N.HANDLER .. ".TRAINED_BRIEFS")
	lu.assertEquals(h.REWARD_SCREENS, N.REWARD_SCREENS, N.HANDLER .. ".REWARD_SCREENS")
	lu.assertEquals(h.START_SCREENS, N.START_SCREENS, N.HANDLER .. ".START_SCREENS (14 screens)")
	lu.assertEquals(h.DUTY_SCREENS, N.DUTY_SCREENS, N.HANDLER .. ".DUTY_SCREENS")
	lu.assertEquals(h.MET_SCREENS, N.MET_SCREENS, N.HANDLER .. ".MET_SCREENS")
	lu.assertEquals(h.TIER_SCREENS, N.TIER_SCREENS, N.HANDLER .. ".TIER_SCREENS")
end

-- AC-1: the NPC
function TestSmugglerT4Wiring:test_nirame_uses_the_template_and_has_the_conversable_invulnerable_mask()
	local npc = H.loadCreatureTemplate("space/nirame_sakute.lua", "nirame_sakute")

	lu.assertNotNil(npc, "mobile/space/nirame_sakute.lua registers nirame_sakute")
	lu.assertEquals(npc.conversationTemplate, N.TEMPLATE, "nirame_sakute: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "nirame_sakute: optionsBitmask (the Beissa mask)")
end

-- AC-1: the include line sits directly after Beissa's, exactly once, uncommented
local function includeAfter(file, beissaLine, line, label)
	local text = readFile(H.SCRIPTS .. file)
	local pattern = line:gsub("%p", "%%%0")

	lu.assertEquals(countMatches(text, "\n%s*" .. pattern), 1, file .. ": uncommented " .. label .. " include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. pattern), 0, file .. ": commented " .. label .. " include")

	local at

	for i, l in ipairs(lines(text)) do
		if l == beissaLine then
			at = i
		end
	end

	lu.assertNotNil(at, file .. ": the Beissa include")
	lu.assertEquals(lines(text)[at + 1], line, file .. ": the " .. label .. " include, directly after the Beissa include")
end

function TestSmugglerT4Wiring:test_the_template_include_line_follows_the_beissa_include_exactly_once()
	includeAfter("mobile/conversations/space/space_conversations.lua", N.BEISSA_INCLUDE_TEMPLATE, N.INCLUDE_TEMPLATE, "nirame_sakute_convo")
end

function TestSmugglerT4Wiring:test_the_handler_include_line_follows_the_beissa_handler_include_exactly_once()
	includeAfter("screenplays/space/screenplays.lua", N.BEISSA_INCLUDE_HANDLER, N.INCLUDE_HANDLER, "nirameSakuteConvoHandler")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestSmugglerT4Tables = {}

function TestSmugglerT4Tables:setUp() H.reset() end

-- AC-2, I-1
function TestSmugglerT4Tables:test_the_16_tables_keep_their_identity_and_zone()
	for _, global in ipairs(G) do
		local q = quest(global)
		local id = N.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertEquals(q.questZone, N.fixtureOf(global):get("questZone"), global .. ": questZone equals the fixture")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2, I-4: Appendix B, every key, nothing else
function TestSmugglerT4Tables:test_each_table_equals_the_fixture_derived_contract_and_sets_no_other_key()
	local want = N.expected()

	for _, global in ipairs(G) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys (Appendix B)")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2: the explicit numbers of the AC, so a failure names the field even when the derivation above changes
function TestSmugglerT4Tables:test_the_explicit_numbers_of_the_acceptance_criterion()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION

	for _, i in ipairs({ 1, 3, 4, 6, 8, 10, 11 }) do
		lu.assertEquals(quest(G[i]).sideQuestSplitType, COMPLETION, G[i] .. ": COMPLETION split")
		lu.assertEquals(quest(G[i]).sideQuestDelay, 5, G[i] .. ": split delay 5 s")
	end

	local b = quest(G[7])

	lu.assertEquals(b.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, G[7] .. ": BIDIRECTIONAL")
	lu.assertEquals({ b.sideQuestType, b.sideQuestName, b.sideFailQuestType, b.sideFailQuestName, b.sideQuestDelay },
		{ "recovery", "tatooine_privateer_tier4_3c", "destroy_surpriseattack", "tatooine_privateer_tier4_3c_sa", 5 }, G[7] .. ": success and failure children")
	lu.assertEquals(quest(G[8]).surpriseAttackShips, { zone = "space_tatooine", spawns = { { count = 5, shipName = "valarian_gunship_tier5" } } }, G[8] .. ": five gunships, no bombers (FN-7)")
	lu.assertEquals(quest(G[1]).deliveryZone, "space_dantooine", G[1] .. ": deliveryZone")
	lu.assertNil(rawget(quest(G[1]), "pickupZone"), G[1] .. ": pickupZone is not set (it equals questZone)")
	lu.assertEquals(quest(G[4]).escortShips, {}, G[4] .. ": recovery 2b has no escorts")
	lu.assertEquals(quest(G[14]).numResponses, 5, G[14] .. ": rescue duty numResponses (FN-8)")
	lu.assertEquals(quest(G[13]).tauntData, { goodbyeCount = 2, reasonCount = 2, tauntCount = 2, thanksCount = 2 }, G[13] .. ": tauntData")
	lu.assertEquals(quest(G[15]).numResponses, 3, G[15] .. ": recovery duty numResponses")
	lu.assertEquals(#quest(G[12]).targetPatrols, 4, G[12] .. ": four target patrol points")
	lu.assertEquals(quest(G[12]).targetPatrols[1].patrolPointName, quest(G[12]).targetPatrols[2].patrolPointName, G[12] .. ": the duplicate first point is SWG's, kept")
	lu.assertEquals(quest(G[5]).totalTransmissionTime, 3, G[5] .. ": SWG's 3-second transmission is kept (R-5)")
	lu.assertEquals(quest(G[6]).cargo, "freight_plans", G[6] .. ": cargo")
	lu.assertEquals(quest(G[6]).validSpawns, { { spawnName = "tatooine_privateer_tier4_leg_3_inspect", x = 7456, z = -1625, y = 1458 } }, G[6] .. ": validSpawns")
	lu.assertEquals(quest(G[1]).attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, G[1] .. ": attackListType SEQUENTIAL")
	lu.assertEquals(quest(G[2]).attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, G[2] .. ": attackListType RANDOM")
	lu.assertEquals(quest(G[7]).mustDestroyEscort, true, G[7] .. ": mustDestroyEscort")
end

-- AC-2, I-5: the four heads pay 10000 and exactly one item; the children pay nothing
function TestSmugglerT4Tables:test_rewards_are_on_the_four_heads_only()
	local rewards = N.rewards()

	for n, global in ipairs(N.HEADS) do
		local q = quest(global)
		local id = N.IDENTITY[global]
		local rw = rewards[id.type .. "/" .. id.name]

		lu.assertEquals(q.creditReward, 10000, global .. ": creditReward (mission " .. n .. ")")
		lu.assertEquals(#q.itemReward, 1, global .. ": itemReward entries")
		lu.assertEquals(q.itemReward[1], { species = { -1 }, item = rw.item }, global .. ": itemReward[1] (NJ)")
	end

	local head = {}

	for _, g in ipairs(N.HEADS) do
		head[g] = true
	end

	for _, global in ipairs(N.STORY) do
		if not head[global] then
			lu.assertNil(rawget(quest(global), "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(quest(global), "itemReward"), global .. ": itemReward")
		end
	end
end

-- AC-2, I-6: exactly the 8 non-end story tables split, each naming its child and its parent; 3b is the only BIDIRECTIONAL table; duties do not split
function TestSmugglerT4Tables:test_split_wiring_and_chain_order()
	local ends = { [G[2]] = true, [G[5]] = true, [G[9]] = true, [G[12]] = true, [G[8]] = false }
	local splits = 0

	for _, global in ipairs(N.STORY) do
		local q = quest(global)

		if ends[global] then
			lu.assertEquals(rawget(q, "sideQuest"), false, global .. ": sideQuest (chain end)")
			lu.assertEquals(rawget(q, "sideQuestType"), "", global .. ": sideQuestType (chain end)")
		else
			splits = splits + 1
			lu.assertEquals(rawget(q, "sideQuest"), true, global .. ": sideQuest")
		end
	end

	lu.assertEquals(splits, 8, "story tables that split")

	local children = {
		[G[1]] = G[2], [G[3]] = G[4], [G[4]] = G[5], [G[6]] = G[7], [G[7]] = G[9], [G[8]] = G[9], [G[10]] = G[11], [G[11]] = G[12],
	}

	for parent, child in pairs(children) do
		local cid, q = N.IDENTITY[child], quest(parent)

		lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { cid.type, cid.name }, parent .. ": names the success child")
	end

	local parentOf = {
		[G[2]] = G[1], [G[4]] = G[3], [G[5]] = G[4], [G[7]] = G[6], [G[8]] = G[7], [G[9]] = G[7], [G[11]] = G[10], [G[12]] = G[11],
	}

	for child, parent in pairs(parentOf) do
		local pid = N.IDENTITY[parent]
		local q = quest(child)

		lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { parent, pid.type, pid.name }, child .. ": names its parent (3c and 3c_sa name 3b)")
	end

	for _, head in ipairs(N.HEADS) do
		lu.assertNil(rawget(quest(head), "parentQuest"), head .. ": a head has no parent")
	end

	local bidirectional = 0

	for _, global in ipairs(G) do
		if rawget(quest(global), "sideQuestSplitType") == SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL then
			bidirectional = bidirectional + 1
		end
	end

	lu.assertEquals(bidirectional, 1, "BIDIRECTIONAL tables (3b only)")

	for _, global in ipairs(N.DUTIES) do
		lu.assertEquals(rawget(quest(global), "sideQuest"), false, global .. ": duties do not split")
	end

	for n, chain in ipairs(N.CHAINS) do
		local members = {}

		for i, m in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			members[i] = m.global
		end

		table.sort(members)

		local want = {}

		for i, g in ipairs(chain) do
			want[i] = g
		end

		table.sort(want)
		lu.assertEquals(members, want, "mission " .. n .. ": getSpaceQuestChain(head) returns the members (3c_sa once)")
	end

	lu.assertEquals({ #SpaceHelpers:getSpaceQuestChain(G[1]), #SpaceHelpers:getSpaceQuestChain(G[3]), #SpaceHelpers:getSpaceQuestChain(G[6]), #SpaceHelpers:getSpaceQuestChain(G[10]) },
		{ 2, 3, 4, 3 }, "chain lengths")
end

-- I-3: every ship string, including nested lists, names a ship template; every item an object file
function TestSmugglerT4Tables:test_every_ship_and_item_the_tables_name_exists()
	local seen = {}

	for _, global in ipairs(G) do
		local q = quest(global)

		for _, key in ipairs({ "escortShips", "recoverShip", "recoverShips", "attackShips", "attackShipLists", "shipList", "deliveryShip", "pickupShip", "targetShipTypes",
			"shipTypes", "bossShip" }) do
			visit(rawget(q, key), function(name)
				seen[name] = true
				lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), global .. "." .. key .. ": ship_mobile/ships/" .. name .. ".lua does not exist")
			end)
		end

		if q.assassinateSpawns then
			visit({ q.assassinateSpawns.target, q.assassinateSpawns.escorts }, function(name)
				seen[name] = true
				lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), global .. ".assassinateSpawns: ship_mobile/ships/" .. name .. ".lua does not exist")
			end)
		end

		if q.surpriseAttackShips then
			for _, s in ipairs(q.surpriseAttackShips.spawns) do
				seen[s.shipName] = true
				lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. s.shipName .. ".lua"), global .. ".surpriseAttackShips: " .. s.shipName)
			end
		end

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			lu.assertNotNil(readFile(H.SCRIPTS .. entry.item:gsub("%.iff$", ".lua")), global .. ".itemReward: " .. entry.item .. " has no object file")
		end
	end

	local n = 0

	for _ in pairs(seen) do
		n = n + 1
	end

	lu.assertEquals(n, 32, "distinct ship names the 16 tables use")

	local serverObjects = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	for _, global in ipairs({ G[3], G[4], G[9] }) do
		local mobile = quest(global).recoveryConversationMobile

		lu.assertNotNil(serverObjects and serverObjects:find(mobile, 1, true), "object/mobile/objects.lua includes " .. tostring(mobile))
	end

	lu.assertEquals({ quest(G[3]).recoveryConversationMobile, quest(G[4]).recoveryConversationMobile, quest(G[9]).recoveryConversationMobile },
		{ "object/mobile/shared_dressed_black_sun_guard.iff", "object/mobile/shared_dressed_imperial_major_m.iff", "object/mobile/shared_dressed_tatooine_valarian_henchman.iff" },
		"the three recovery appearances")
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4): production versus the derived values, point by point
---------------------------------------------------------------------------------------------

TestSmugglerT4Conformance = {}

function TestSmugglerT4Conformance:setUp() H.reset() end

local POINT_LISTS = {
	{ "targetPatrols", "escortPath" }, { "escortPoints", "escortPoints" }, { "preRecoveryPoints", "escortPath" }, { "recoveryPoints", "recoveryPath" },
	{ "recoveryPath", "recoveryPath" }, { "pickupPoint", "pickupPoint", true }, { "deliveryPoint", "deliveryPoint", true }, { "transmissionPoint", "transmissionPoint", true },
}

-- AC-2, I-2: every point of every table is a Core3 patrol point of ITS zone (the zone prefix of the .tab value) with the same x, z, y, names and order of the .tab lists
function TestSmugglerT4Conformance:test_every_point_resolves_in_its_zone_point_file_with_the_same_coordinates_in_tab_order()
	local checked, fromTabs = 0, 0

	for _, global in ipairs(G) do
		local q = quest(global)
		local rec = N.fixtureOf(global)

		for _, l in ipairs(POINT_LISTS) do
			local value = rawget(q, l[1])

			if value ~= nil then
				local list = l[3] and { value } or value
				local want, zones = {}, {}

				for i, v in ipairs(rec:list(l[2])) do
					local zone, name = H.Tab.splitNavPoint(v)

					want[i], zones[i] = name, zone
					fromTabs = fromTabs + 1
				end

				local got = {}

				for i, p in ipairs(list) do
					checked = checked + 1
					got[i] = p.patrolPointName

					local zonePoints = H.patrolPoints(zones[i] or q.questZone)

					lu.assertNotNil(zonePoints[p.patrolPointName], global .. "." .. l[1] .. "[" .. i .. "]: " .. tostring(p.patrolPointName) .. " is not a " .. tostring(zones[i]) .. " patrol point")
					lu.assertEquals({ p.x, p.z, p.y }, { zonePoints[p.patrolPointName].x, zonePoints[p.patrolPointName].z, zonePoints[p.patrolPointName].y },
						global .. "." .. l[1] .. "[" .. i .. "] " .. tostring(p.patrolPointName))

					for _, numKey in ipairs({ "escortNumber", "patrolNumber" }) do
						if p[numKey] ~= nil then
							lu.assertEquals(p[numKey], i, global .. "." .. l[1] .. "[" .. i .. "]: " .. numKey .. " is 1-based")
						end
					end
				end

				lu.assertEquals(got, want, global .. "." .. l[1] .. ": point names in .tab order")
			end
		end
	end

	lu.assertEquals(checked, fromTabs, "points checked equals the point cells of the .tab lists")
	lu.assertEquals(checked, 60, "points checked (delivery 1 + 1, 1b 1, recovery 5 + 4, 5 + 4 and 4 + 4, survival 1, assassinate 2 + 5 + 4 + 4, escort duty 3, rescue duty 4, recovery duty 5 + 3)")
end

-- AC-2, I-2: delivery 1a's pickup is in space_lok and its delivery point in the delivery zone; the point files hold them under those zones
function TestSmugglerT4Conformance:test_delivery_1a_points_are_in_their_own_zones()
	local q = quest(G[1])

	lu.assertNotNil(H.patrolPoints("space_lok")[q.pickupPoint.patrolPointName], "the pickup point is a space_lok point")
	lu.assertNotNil(H.patrolPoints(q.deliveryZone)[q.deliveryPoint.patrolPointName], "the delivery point is a " .. tostring(q.deliveryZone) .. " point")
	lu.assertNil(H.patrolPoints("space_lok")[q.deliveryPoint.patrolPointName], "and not a space_lok point")
end

-- AC-2, I-2: the escort points carry the zone, recovery points do not; radii
function TestSmugglerT4Conformance:test_point_extras_zone_and_radius()
	for i, p in ipairs(quest(G[13]).escortPoints) do
		lu.assertEquals({ p.zoneName, p.radius }, { "space_lok", 250 }, G[13] .. ".escortPoints[" .. i .. "] (zoneName, radius)")
	end

	for _, g in ipairs({ G[3], G[4], G[9], G[15] }) do
		for _, key in ipairs({ "preRecoveryPoints", "recoveryPoints" }) do
			for i, p in ipairs(quest(g)[key]) do
				lu.assertNil(p.zoneName, g .. "." .. key .. "[" .. i .. "].zoneName")
				lu.assertEquals(p.radius, 250, g .. "." .. key .. "[" .. i .. "].radius")
			end
		end
	end
end

-- AC-2, I-2: the inspect spawner is the excerpt row, which Core3's spawner file also holds
function TestSmugglerT4Conformance:test_inspect_spawner_matches_the_excerpt_and_the_core3_spawner_file()
	local text = readFile(H.SCRIPTS .. "screenplays/space/spawning/space_dantooine_spawner.lua")
	local spawners = H.spawners("space_dantooine")
	local v = quest(G[6]).validSpawns[1]
	local row = N.buildout("dantooine").spawners[1]

	lu.assertEquals({ v.spawnName, v.x, v.z, v.y }, { row.name, row[1], row[2], row[3] }, G[6] .. ".validSpawns[1] equals the excerpt row")
	lu.assertNotNil(spawners[v.spawnName], G[6] .. ".validSpawns[1]: Core3 has no spawner " .. v.spawnName)
	lu.assertNotNil(text:find('spawnName = "' .. v.spawnName .. '", spawnType = SHIP_SPAWN_SINGLE, x = ' .. v.x .. ", z = " .. v.z .. ", y = " .. v.y .. ",", 1, true),
		G[6] .. ".validSpawns[1]: space_dantooine_spawner.lua has no " .. v.spawnName .. " at " .. v.x .. ", " .. v.z .. ", " .. v.y)
end

-- AC-2, I-4: the mapped fields, quest by quest, with the quest name and the field in the message
function TestSmugglerT4Conformance:test_every_mapped_field_equals_the_value_derived_from_its_fixture()
	local want = N.expected()

	for _, global in ipairs(G) do
		local id = N.IDENTITY[global]

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(quest(global), key), value, id.type .. "/" .. id.name .. ": " .. key)
		end
	end
end

-- AC-2: the Core3-only values: failTimer 20 on the four assassinates, none elsewhere
function TestSmugglerT4Conformance:test_the_assassinates_carry_failTimer_20_and_nothing_else_does()
	for _, global in ipairs(G) do
		local want = N.IDENTITY[global].type == "assassinate" and 20 or nil

		lu.assertEquals(rawget(quest(global), "failTimer"), want, global .. ": failTimer")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2, I-11: the inspect cargo on the two ship templates
---------------------------------------------------------------------------------------------

TestSmugglerT4Cargo = {}

function TestSmugglerT4Cargo:setUp() H.reset() end

-- I-11: the template files carry the quest cargo as a cargoString, on the line directly after questLoot
function TestSmugglerT4Cargo:test_the_valarian_inspect_template_files_carry_the_quest_cargo_directly_after_questLoot()
	for _, key in ipairs({ "tier4", "plain" }) do
		local file = N.SHIP_FILES[key]
		local src = readFile(H.SCRIPTS .. file)

		lu.assertNotNil(src, file)

		local l = lines(src)
		local at

		for i, line in ipairs(l) do
			if line:find('questLoot = "valarian_freight_plans",', 1, true) then
				at = i
			end
		end

		lu.assertNotNil(at, file .. ": questLoot valarian_freight_plans")
		lu.assertEquals(l[at + 1]:match('^%s*cargoString = "([^"]*)",'), "freight_plans", file .. ": cargoString on the line after questLoot")
		lu.assertEquals(quest(G[6]).cargo, "freight_plans", G[6] .. ": cargo equals the template's cargoString")
		lu.assertEquals(countMatches(src, "cargoString"), 1, file .. ": one cargoString")
	end
end

-- I-11: the loaded templates have the cargo strings (the real ship_mobile registration)
function TestSmugglerT4Cargo:test_the_loaded_templates_have_the_cargo_strings()
	lu.assertEquals(H.shipTemplate("valarian_gunship_inspect_tier4").cargoString, "freight_plans", "valarian_gunship_inspect_tier4: cargoString")
	lu.assertEquals(H.shipTemplate("valarian_gunship_inspect").cargoString, "freight_plans", "valarian_gunship_inspect: cargoString")
end

---------------------------------------------------------------------------------------------
-- Coverage of the SWG-Source quest names: asserted by test_smuggler_tier2_data.lua (230 of 925; tatooine_privateer 43 of 44)
---------------------------------------------------------------------------------------------

TestSmugglerT4Coverage = {}

function TestSmugglerT4Coverage:setUp() H.reset() end

-- AC-2: the 13 names are SWG quest names (in swgsource_quests.txt) and each questName string is defined as often as it has tables (the name _1 has four duty tables)
function TestSmugglerT4Coverage:test_the_13_names_are_swg_quest_names_and_each_is_defined_once_per_table()
	local swg = readFile("/home/swgemu/swg-source-research/swgsource_quests.txt")

	if swg == nil then
		lu.skip("the SWG-Source research clone has no swgsource_quests.txt")
	end

	local set = {}

	for name in swg:gmatch("[^\r\n]+") do
		set[name] = true
	end

	local pipe = io.popen("grep -rhoE 'questName[[:space:]]*=[[:space:]]*\"tatooine_privateer_tier4[a-z0-9_]*\"' --include=*.lua '" .. H.SCRIPTS .. "' 2>/dev/null")
	local output = pipe:read("a")

	pipe:close()

	local count = {}

	for name in output:gmatch('"([^"]+)"') do
		count[name] = (count[name] or 0) + 1
	end

	local want = {}

	for _, global in ipairs(G) do
		local name = N.IDENTITY[global].name

		want[name] = (want[name] or 0) + 1
	end

	local names = 0

	for name, n in pairs(want) do
		names = names + 1
		lu.assertTrue(set[name] == true, name .. " is not an SWG-Source quest name")
		lu.assertEquals(count[name], n, "questName \"" .. name .. "\" definitions under bin/scripts")
	end

	lu.assertEquals(names, 13, "distinct tier 4 quest names")
end
