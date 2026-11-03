-- Smuggler tier 3 (Beissa): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7 and I-11; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source files in fixtures/ (the 17 spacequest .tab copies, the two buildout excerpts, the space_mobile excerpt, the two inspect_cargo
-- tables and Beissa's script). smuggler_tier3_data.lua B.expected() derives every mapped field from them, never from the Core3 tables under test. The
-- first class (TestSmugglerT3Oracle) needs no production code and is green from the start; it proves the fixtures say what the spec relies on.

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")

B.load()

local readFile = B.readFile

local function quest(global) return B.quest(global) end

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

local SWG_SPACEQUEST = B.SWG_DIR .. "datatables/spacequest/"

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerT3Oracle = {}

function TestSmugglerT3Oracle:setUp() H.reset() end

-- AC-2 (the oracle itself): the 17 .tab copies, the two inspect_cargo tables and BJ are the research clone's files byte for byte
function TestSmugglerT3Oracle:test_the_fixture_copies_equal_the_research_clone_files()
	if readFile(SWG_SPACEQUEST .. "inspect_cargo/witchblood_rallyinfo.tab") == nil then
		lu.skip("the SWG-Source research clone is not present")
	end

	local pairsOf = {}

	for _, global in ipairs(B.GLOBALS) do
		local id = B.IDENTITY[global]

		pairsOf[#pairsOf + 1] = { H.FIXTURES .. "spacequest/" .. id.type .. "/" .. id.name .. ".tab", SWG_SPACEQUEST .. id.type .. "/" .. id.name .. ".tab" }
	end

	for _, n in ipairs({ "witchblood_rallyinfo", "witchblood_baseinfo" }) do
		pairsOf[#pairsOf + 1] = { H.FIXTURES .. "spacequest/inspect_cargo/" .. n .. ".tab", SWG_SPACEQUEST .. "inspect_cargo/" .. n .. ".tab" }
	end

	pairsOf[#pairsOf + 1] = { B.BJ, B.SWG_DIR .. "script/conversation/tatooine_privateer_tier3.java" }

	for _, p in ipairs(pairsOf) do
		local copy, original = readFile(p[1]), readFile(p[2])

		lu.assertNotNil(copy, p[1] .. " is missing")
		lu.assertNotNil(original, p[2] .. " is missing")
		lu.assertTrue(copy == original, p[1] .. " differs from " .. p[2])
	end
end

-- AC-2 (the oracle itself): the fixture facts the spec relies on, as anchors so a misparsed fixture cannot make a wrong table look right
function TestSmugglerT3Oracle:test_the_fixtures_carry_the_values_the_spec_lists()
	local function row(global, ...) return { B.fixtureOf(global):get("questZone"), ... } end
	local q = B.GLOBALS

	local r1 = B.fixtureOf(q[1])

	lu.assertEquals({ r1:get("targetShipType"), r1:num("targetArrivalDelay"), r1:num("targetRecoverTime"), r1:num("attackPeriod"), r1:num("numAttackShipLists"), r1:num("numResponses") },
		{ "smuggler_freighterheavy_tier3", 12, 32, 90, 2, 2 }, "recovery/tatooine_privateer_tier3_1")
	lu.assertEquals(r1:list("targetEscort"), { "valarian_gunship_tier3", "valarian_gunship_tier3", "valarian_bomber_tier3" }, "recovery/tatooine_privateer_tier3_1: targetEscort")
	lu.assertEquals(#r1:list("escortPath"), 5, "recovery/tatooine_privateer_tier3_1: escortPath")
	lu.assertEquals(#r1:list("recoveryPath"), 3, "recovery/tatooine_privateer_tier3_1: recoveryPath")
	lu.assertEquals(B.fixtureOf(q[4]):num("mustDestroyEscort"), 0, "assassinate/tatooine_privateer_tier3_1_c: mustDestroyEscort")
	lu.assertEquals(B.fixtureOf(q[2]):num("mustDestroyEscort"), 1, "assassinate/tatooine_privateer_tier3_1_a: mustDestroyEscort")
	lu.assertEquals(B.fixtureOf(q[6]):get("cargo"), "rally_point_info", "inspect/tatooine_privateer_tier3_2: cargo")
	lu.assertEquals(B.fixtureOf(q[7]):get("cargo"), "hidden_base_info", "inspect/tatooine_privateer_tier3_2_a: cargo")
	lu.assertEquals({ B.fixtureOf(q[8]):num("totalTransmissionTime"), B.fixtureOf(q[8]):num("attackPeriod") }, { 310, 80 }, "survival/tatooine_privateer_tier3_2_b")
	lu.assertEquals({ B.fixtureOf(q[13]):num("triggerOn"), B.fixtureOf(q[13]):num("triggerDelay") }, { 2, 8 }, "patrol/tatooine_privateer_tier3_4")
	lu.assertEquals({ B.fixtureOf(q[16]):num("triggerOn"), B.fixtureOf(q[16]):num("triggerDelay") }, { 2, 7 }, "patrol/tatooine_privateer_tier3_4_c")
	lu.assertEquals(B.fixtureOf(q[14]):num("enemyArrivalDist"), -100, "space_battle/tatooine_privateer_tier3_4_a: enemyArrivalDist")
	lu.assertEquals(B.fixtureOf(q[17]):get("attackListType"), "random", "rescue/tatooine_privateer_tier3_4_d: attackListType")
	lu.assertEquals(#B.fixtureOf(q[12]):list("escortPath"), 5, "escort/tatooine_privateer_tier3_3_c: escortPath")
	lu.assertEquals(row(q[1])[1], "space_yavin4", "recovery zone")
end

-- AC-2, I-5 (the oracle itself): BJ pays 25000 and one component for each of the four missions
function TestSmugglerT3Oracle:test_the_script_rewards_are_25000_and_one_mission_reward_component_each()
	local rw = B.rewards()
	local want = {
		["recovery/tatooine_privateer_tier3_1"] = "object/tangible/ship/components/reactor/rct_mission_reward_neutral_subpro_military.iff",
		["inspect/tatooine_privateer_tier3_2"] = "object/tangible/ship/components/engine/eng_mission_reward_neutral_mandal_inferno.iff",
		["delivery_no_pickup/tatooine_privateer_tier3_3"] = "object/tangible/ship/components/weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff",
		["patrol/tatooine_privateer_tier3_4"] = "object/tangible/ship/components/armor/arm_mission_reward_neutral_kse_handcrafted.iff",
	}

	lu.assertEquals(#sortedKeys(rw), 4, "giveReward calls in BJ")

	for key, item in pairs(want) do
		lu.assertEquals(rw[key], { credits = 25000, item = item }, "BJ giveReward " .. key)
	end
end

-- AC-2, I-2 (the oracle itself): the two excerpts hold the 12 + 22 rows the spec lists
function TestSmugglerT3Oracle:test_the_buildout_excerpts_hold_the_rows_the_spec_lists()
	for zone, want in pairs({ yavin4 = { nav = 12, spawners = 0 }, dathomir = { nav = 19, spawners = 3 } }) do
		local b = B.buildout(zone)
		local n = 0

		for _ in pairs(b.nav) do
			n = n + 1
		end

		lu.assertEquals(n, want.nav, zone .. ": nav_name rows")
		lu.assertEquals(#b.spawners, want.spawners, zone .. ": spawner rows")
		lu.assertEquals(#H.fixture("space_zones/buildout/space_" .. zone .. ".smuggler_tier3_points.tab").records, want.nav + want.spawners, zone .. ": data rows")
	end

	local d = B.buildout("dathomir")

	lu.assertEquals({ d.spawners[1].name, d.spawners[1][1], d.spawners[1][2], d.spawners[1][3] }, { "tier3_privateer_witchblood_inspect_01", 6228, -6411, -5797 }, "first spawner row")
	lu.assertEquals({ d.spawners[2].name, d.spawners[2][1], d.spawners[2][2], d.spawners[2][3] }, { "tier3_privateer_witchblood_inspect_02", -808, -379, 1892 }, "second spawner row")
	lu.assertEquals({ d.spawners[3].name, d.spawners[3][1], d.spawners[3][2], d.spawners[3][3] }, { "tier3_privateer_witchblood_inspect_01", -1662, 721, -313 }, "third spawner row")
	lu.assertEquals({ d.nav.tier3_privateer_battle_01[1], d.nav.tier3_privateer_battle_01[2], d.nav.tier3_privateer_battle_01[3] }, { 2311, -1341, -2779 }, "battle_01 point")
	lu.assertEquals(d.nav.tier3_privateer_battle_01.forward, { x = 0.092084, z = 0.173348, y = -0.980546 }, "battle_01 forward")
	lu.assertEquals(d.nav.tier3_privateer_battle_02.forward, { x = 0.474276, z = -0.799720, y = 0.368118 }, "battle_02 forward")
end

-- AC-2 (the oracle itself): each excerpt row is a row of the SWG clone (CRLF kept), after the clone's two header rows
function TestSmugglerT3Oracle:test_the_buildout_excerpt_rows_and_the_space_mobile_excerpt_equal_the_swg_clone_rows()
	local clone = {
		yavin4 = readFile(B.SWG_DIR .. "datatables/space_zones/buildout/space_yavin4.tab"),
		dathomir = readFile(B.SWG_DIR .. "datatables/space_zones/buildout/space_dathomir.tab"),
	}
	local mobile = readFile(B.SWG_DIR .. "datatables/space_mobile/space_mobile.tab")

	if clone.yavin4 == nil or clone.dathomir == nil or mobile == nil then
		lu.skip("the SWG-Source research clone is not present")
	end

	for zone, text in pairs(clone) do
		local set = {}

		for i, l in ipairs(lines(text)) do
			set[l] = set[l] or i
		end

		local ex = readFile(H.FIXTURES .. "space_zones/buildout/space_" .. zone .. ".smuggler_tier3_points.tab")
		local exLines = lines(ex)

		lu.assertEquals(exLines[#exLines], "", zone .. ": excerpt ends with a newline")

		for i = 1, #exLines - 1 do
			lu.assertNotNil(set[exLines[i]], zone .. ": excerpt line " .. i .. " is not a line of the clone (CRLF kept)")
		end

		lu.assertEquals(set[exLines[1]], 1, zone .. ": excerpt header row 1")
		lu.assertEquals(set[exLines[2]], 2, zone .. ": excerpt header row 2")
	end

	local mlines = lines(mobile)
	local ex = lines(readFile(H.FIXTURES .. "space_mobile/space_mobile.dath_witchblood_clan_tier3.tab"))

	lu.assertEquals({ ex[1], ex[2], ex[3], ex[4] }, { mlines[1], mlines[2], mlines[534], mlines[540] }, "space_mobile excerpt = rows 1, 2, 534, 540 of space_mobile.tab")
end

-- AC-2, I-2 (the oracle itself): Core3's patrol point files already hold the buildout values (truncated toward zero) for the 31 points
function TestSmugglerT3Oracle:test_the_core3_point_files_equal_the_buildout_excerpts_truncated()
	local n = 0

	for zone, b in pairs({ space_yavin4 = B.buildout("yavin4"), space_dathomir = B.buildout("dathomir") }) do
		local points = H.patrolPoints(zone)

		for name, xyz in pairs(b.nav) do
			n = n + 1
			lu.assertNotNil(points[name], zone .. ": no Core3 patrol point " .. name)
			lu.assertEquals({ points[name].x, points[name].z, points[name].y }, { xyz[1], xyz[2], xyz[3] }, zone .. ":" .. name .. " (Core3 point file vs buildout)")
		end
	end

	lu.assertEquals(n, 31, "nav points checked")
end

-- AC-2, I-3 (the oracle itself): the ships and items the fixtures name exist in Core3 (27 distinct ship names, 4 items)
function TestSmugglerT3Oracle:test_the_ships_and_reward_items_of_the_fixtures_exist()
	local ships = {}

	for _, global in ipairs(B.GLOBALS) do
		local rec = B.fixtureOf(global)

		for _, col in ipairs({ "targetShipType", "targetEscort", "shipList", "deliveryShip", "escortShipType", "allyForce", "enemyForce", "shipType",
			"attackShips1", "attackShips2", "attackShips3" }) do
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

	lu.assertEquals(n, 27, "distinct ship names in the 17 fixtures")

	for key, rw in pairs(B.rewards()) do
		lu.assertNotNil(readFile(H.SCRIPTS .. rw.item:gsub("%.iff$", ".lua")), key .. ": " .. rw.item .. " has no object file")
	end
end

-- I-7 (the oracle itself): the client journal knows the 17 quests
function TestSmugglerT3Oracle:test_all_17_quests_are_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(B.GLOBALS) do
		local id = B.IDENTITY[global]

		lu.assertTrue(set["spacequest/" .. id.type .. "/" .. id.name] == true, "spacequest/" .. id.type .. "/" .. id.name .. " is not in the client quest table")
	end
end

-- I-11 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo, canTransfer 1
function TestSmugglerT3Oracle:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local mobile = H.fixture("space_mobile/space_mobile.dath_witchblood_clan_tier3.tab")
	local byShip = {}

	for _, rec in ipairs(mobile.records) do
		byShip[rec:get("strIndex")] = rec
	end

	local cases = {
		{ ship = "dath_witchblood_clan_soldier_tier3", table = "witchblood_rallyinfo", quest = B.GLOBALS[6], cargo = "rally_point_info" },
		{ ship = "dath_witchblood_clan_punisher_tier3", table = "witchblood_baseinfo", quest = B.GLOBALS[7], cargo = "hidden_base_info" },
	}

	for _, c in ipairs(cases) do
		lu.assertEquals(byShip[c.ship]:get("cargo"), c.table, c.ship .. ": space_mobile cargo column")

		local row
		local names = {}

		for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/" .. c.table .. ".tab").records) do
			names[#names + 1] = rec:get("name")

			if rec:get("name") == c.cargo then
				row = rec
			end
		end

		lu.assertNotNil(row, c.table .. ": has no row " .. c.cargo .. " (rows " .. table.concat(names, ",") .. ")")
		lu.assertEquals(row:num("canTransfer"), 1, c.table .. "/" .. c.cargo .. ": canTransfer")
		lu.assertEquals(B.fixtureOf(c.quest):get("cargo"), c.cargo, c.quest .. ": quest cargo")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestSmugglerT3Wiring = {}

function TestSmugglerT3Wiring:setUp() H.reset() end

-- AC-1
function TestSmugglerT3Wiring:test_the_squadron_file_registers_the_17_quests_with_start_true_and_keeps_the_older_ones()
	for _, global in ipairs(B.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	local text = readFile(H.SCRIPTS .. B.SQUADRON_FILE)

	lu.assertEquals(countMatches(text, 'registerScreenPlay%('), 53, B.SQUADRON_FILE .. ": registerScreenPlay calls (20 before: 19 quests and the squadron object; + 17 tier 3; + 16 tier 4 by smuggler-tier4-nirame)")
	lu.assertNotNil(H.registered("SmugglerSquadronScreenplay"), "SmugglerSquadronScreenplay is still registered")
	lu.assertNotNil(H.registered("assassinate_tatooine_privateer_tier2_1a"), "a tier 2 table is still registered")
	lu.assertNotNil(H.registered("patrol_tat_priv_quest_trans"), "a transition table is still registered")
	lu.assertNotNil(H.registered("patrol_tatooine_privateer_1"), "a tier 1 table is still registered")
end

-- AC-1: Content contract 1: the section after the tier 2 tables, before the squadron object, in table order, each table followed by its registration
function TestSmugglerT3Wiring:test_the_17_globals_sit_after_the_tier_2_tables_and_before_the_squadron_object_in_the_contract_order()
	local text = readFile(H.SCRIPTS .. B.SQUADRON_FILE)

	lu.assertNotNil(text, B.SQUADRON_FILE)

	local tier2 = text:find('registerScreenPlay("destroy_duty_tatooine_privateer_tier2_1", true)', 1, true)
	local squadron = text:find("\nSmugglerSquadronScreenplay = ScreenPlay:new", 1, true)

	lu.assertNotNil(tier2, B.SQUADRON_FILE .. ": the last tier 2 registration")
	lu.assertNotNil(squadron, B.SQUADRON_FILE .. ": the squadron object")

	local last = tier2

	for _, global in ipairs(B.GLOBALS) do
		local at = text:find("\n" .. global .. " = ", 1, true)

		lu.assertNotNil(at, B.SQUADRON_FILE .. ": no global " .. global)
		lu.assertTrue(at > last, B.SQUADRON_FILE .. ": " .. global .. " is out of the Content contract 1 order (after the tier 2 tables)")
		lu.assertTrue(at < squadron, B.SQUADRON_FILE .. ": " .. global .. " must come before the squadron object")

		local reg = text:find('registerScreenPlay("' .. global .. '", true)', 1, true)

		lu.assertTrue(reg ~= nil and reg > at, B.SQUADRON_FILE .. ": registerScreenPlay for " .. global .. " follows its table")
		last = reg
	end

	lu.assertNotNil(text:find("Tier 3 -- Beissa (Jabba's Palace; Yavin 4, Dathomir)", 1, true), B.SQUADRON_FILE .. ": the section comment")
end

-- AC-1: Content contract 1: the header comment
function TestSmugglerT3Wiring:test_the_header_comment_names_tier_3_and_tier_4_as_ported()
	local text = readFile(H.SCRIPTS .. B.SQUADRON_FILE)

	lu.assertNotNil(text:find("smuggler-tier3-beissa", 1, true), B.SQUADRON_FILE .. ": the header names the feature smuggler-tier3-beissa")
	lu.assertNotNil(text:find("tatooine_privateer_tier3", 1, true), B.SQUADRON_FILE .. ": the header names tatooine_privateer_tier3")
	-- smuggler-tier4-nirame: the sentence "Tier 4 is not ported yet." became "Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame."
	lu.assertNil(text:find("Tier 4 is not ported yet.", 1, true), B.SQUADRON_FILE .. ": the old 'Tier 4 is not ported yet.'")
	lu.assertNotNil(text:find("Tier 4 (trainer Nirame Sakute, tatooine_privateer_tier4) is ported by feature smuggler-tier4-nirame.", 1, true), B.SQUADRON_FILE .. ": the tier 4 header sentence")
	lu.assertNil(text:find("Tiers 3-4 are not ported yet.", 1, true), B.SQUADRON_FILE .. ": the old 'Tiers 3-4 are not ported yet.'")
end

-- AC-1: Content contract 2
function TestSmugglerT3Wiring:test_the_squadron_object_has_the_tier_3_constants_and_the_reset()
	local sq = B.squadron()

	for field, want in pairs(B.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "SmugglerSquadronScreenplay." .. field)
	end

	lu.assertEquals(type(sq.resetBeissaQuests), "function", "SmugglerSquadronScreenplay:resetBeissaQuests")
	lu.assertEquals(pcall(sq.resetBeissaQuests, sq, nil), true, "resetBeissaQuests(nil) returns early")

	-- tiers 1 and 2 and the transition stay as they were
	for _, name in ipairs({ "resetDravisQuests", "resetKarrdeQuests", "resetShamdonQuests", "hasCompletedTier2Series" }) do
		lu.assertEquals(type(sq[name]), "function", name .. " still exists")
	end

	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "tatooine_privateer_1" }, "tier 1 constants stay")
	lu.assertEquals(sq.TIER2_QUEST_STRING_1, { type = "assassinate", name = "tatooine_privateer_tier2_1a" }, "tier 2 constants stay")
end

-- AC-1: Content contract 2: comments and order of the new constants and the reset
function TestSmugglerT3Wiring:test_the_constants_follow_the_tier_2_constants_and_the_reset_follows_resetShamdonQuests()
	local text = readFile(H.SCRIPTS .. B.SQUADRON_FILE)

	lu.assertNotNil(text:find("-- Tier 3 (Beissa) Quest Strings, SWG mission order; SIDEk = the k-th split child", 1, true), "comment '-- Tier 3 (Beissa) Quest Strings, SWG mission order; SIDEk = the k-th split child'")

	local d3 = text:find("TIER2_QUEST_STRING_DUTY_3 = ", 1, true)
	local s1 = text:find("TIER3_QUEST_STRING_1 = ", 1, true)
	local s44 = text:find("TIER3_QUEST_STRING_4_SIDE4 = ", 1, true)
	local resetShamdon = text:find("function SmugglerSquadronScreenplay:resetShamdonQuests", 1, true)
	local reset = text:find("function SmugglerSquadronScreenplay:resetBeissaQuests", 1, true)

	lu.assertTrue(d3 ~= nil and s1 ~= nil and s1 > d3, "TIER3_QUEST_STRING_1 follows the tier 2 duty constants")
	lu.assertTrue(s1 ~= nil and s44 ~= nil and s44 > s1, "the constants are in SWG mission order")
	lu.assertTrue(resetShamdon ~= nil and reset ~= nil and reset > resetShamdon, "resetBeissaQuests follows resetShamdonQuests")
	lu.assertNotNil(text:find("Tier 3 -- Beissa", 1, true), "the method section comment 'Tier 3 -- Beissa'")
	lu.assertNil(text:find("LEGACY_MIGRATION_STEPS", 1, true), "no LEGACY_MIGRATION_STEPS: nothing is renamed")
end

-- AC-1
function TestSmugglerT3Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	B.requireConversation(lu)

	local t = H.conversationTemplateTable(B.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, B.HANDLER, B.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", B.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, B.HANDLER).getInitialScreen), "function", B.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, B.HANDLER).runScreenHandlers), "function", B.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, B.HANDLER).getNextConversationScreen), "function", B.HANDLER .. ":getNextConversationScreen")
end

-- AC-1: the handler's tables and helpers (Content contract 3) that the tests call directly
function TestSmugglerT3Wiring:test_the_handler_has_the_tables_and_helpers_of_the_content_contract()
	B.requireConversation(lu)

	local h = B.handler()

	for _, name in ipairs({ "getQuestString", "hasStatus", "isWon", "isActive", "isFailed", "isOnMission", "getRewardMission", "payMission", "raisePilotTier", "getLastScreenID" }) do
		lu.assertEquals(type(h[name]), "function", B.HANDLER .. ":" .. name)
	end

	lu.assertEquals(#h.MISSIONS, 4, B.HANDLER .. ".MISSIONS")

	for n = 1, 4 do
		local m, want = h.MISSIONS[n], B.MISSIONS[n]

		lu.assertEquals({ m.head or m[1], m.questString or m[2], m.endString or m[3] }, { want.head, want.questString, want.endString }, B.HANDLER .. ".MISSIONS[" .. n .. "] (head, questString, endString)")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, B.HANDLER .. ".TRAIN_CHOICES")

	for i, t in ipairs(B.TRAIN) do
		local c = h.TRAIN_CHOICES[i]

		lu.assertEquals({ c.skill or c[1], c.reply or c[2] }, { t.skill, B.PREFIX .. t.reply }, B.HANDLER .. ".TRAIN_CHOICES[" .. i .. "] (skill, topic reply)")
	end

	lu.assertEquals(h.REWARD_SCREENS, { m1_reward = 1, m2_reward = 2, m3_reward = 3, m4_reward = 4 }, B.HANDLER .. ".REWARD_SCREENS")
	lu.assertEquals(h.START_SCREENS, B.START_SCREENS, B.HANDLER .. ".START_SCREENS (13 screens)")
end

-- AC-1
function TestSmugglerT3Wiring:test_beissa_uses_the_template_and_has_the_conversable_invulnerable_mask()
	local npc = H.loadCreatureTemplate("space/beissa.lua", "beissa")

	lu.assertNotNil(npc, "mobile/space/beissa.lua registers beissa")
	lu.assertEquals(npc.conversationTemplate, B.TEMPLATE, "beissa: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "beissa: optionsBitmask (the Shamdon mask)")
end

-- AC-1: the include line sits directly after Shamdon's, exactly once, uncommented
local function includeAfter(file, shamdonLine, line, label)
	local text = readFile(H.SCRIPTS .. file)
	local pattern = line:gsub("%p", "%%%0")

	lu.assertEquals(countMatches(text, "\n%s*" .. pattern), 1, file .. ": uncommented " .. label .. " include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. pattern), 0, file .. ": commented " .. label .. " include")

	local at

	for i, l in ipairs(lines(text)) do
		if l == shamdonLine then
			at = i
		end
	end

	lu.assertNotNil(at, file .. ": the Shamdon include")
	lu.assertEquals(lines(text)[at + 1], line, file .. ": the " .. label .. " include, directly after the Shamdon include")
end

function TestSmugglerT3Wiring:test_the_template_include_line_follows_the_shamdon_include_exactly_once()
	includeAfter("mobile/conversations/space/space_conversations.lua", B.SHAMDON_INCLUDE_TEMPLATE, B.INCLUDE_TEMPLATE, "beissa_convo")
end

function TestSmugglerT3Wiring:test_the_handler_include_line_follows_the_shamdon_handler_include_exactly_once()
	includeAfter("screenplays/space/screenplays.lua", B.SHAMDON_INCLUDE_HANDLER, B.INCLUDE_HANDLER, "beissaConvoHandler")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestSmugglerT3Tables = {}

function TestSmugglerT3Tables:setUp() H.reset() end

-- AC-2, I-1
function TestSmugglerT3Tables:test_the_17_tables_keep_their_identity_and_zone()
	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)
		local id = B.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertEquals(q.questZone, B.fixtureOf(global):get("questZone"), global .. ": questZone equals the fixture")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2, I-4: Appendix B, every key, nothing else
function TestSmugglerT3Tables:test_each_table_equals_the_fixture_derived_contract_and_sets_no_other_key()
	local want = B.expected()

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys (Appendix B)")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2: the explicit numbers of the AC, so a failure names the field even when the derivation above changes
function TestSmugglerT3Tables:test_the_explicit_numbers_of_the_acceptance_criterion()
	local g = B.GLOBALS

	lu.assertEquals({ quest(g[13]).sideQuestPatrolStart, quest(g[13]).sideQuestDelay, quest(g[13]).sideQuestType }, { 2, 8, "space_battle" }, g[13] .. ": patrol split at point 2 after 8 s")
	lu.assertEquals({ quest(g[16]).sideQuestPatrolStart, quest(g[16]).sideQuestDelay, quest(g[16]).sideQuestType }, { 2, 7, "rescue" }, g[16] .. ": patrol split at point 2 after 7 s")

	for _, i in ipairs({ 1, 2, 3, 4, 6, 7, 9, 10, 11, 14, 15 }) do
		lu.assertEquals(quest(g[i]).sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, g[i] .. ": COMPLETION split")
		lu.assertEquals(quest(g[i]).sideQuestDelay, 5, g[i] .. ": split delay 5 s")
	end

	lu.assertEquals(quest(g[4]).mustDestroyEscort, false, g[4] .. ": mustDestroyEscort")
	lu.assertEquals({ quest(g[2]).mustDestroyEscort, quest(g[3]).mustDestroyEscort }, { true, true }, "assassinate 1_a and 1_b: mustDestroyEscort")
	lu.assertEquals(#quest(g[6]).validSpawns, 2, g[6] .. ": two validSpawns")
	lu.assertEquals({ quest(g[6]).validSpawns[1].spawnName, quest(g[6]).validSpawns[2].spawnName }, { "tier3_privateer_witchblood_inspect_01", "tier3_privateer_witchblood_inspect_01" }, g[6] .. ": both named _01")
	lu.assertEquals(#quest(g[7]).validSpawns, 1, g[7] .. ": one validSpawn")
	lu.assertEquals({ quest(g[14]).enemyArrivalDist, quest(g[15]).enemyArrivalDist }, { -100, -100 }, "battle 4_a / 4_b: enemyArrivalDist")
	lu.assertEquals(quest(g[17]).attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM, g[17] .. ": attackListType RANDOM")
	lu.assertEquals(quest(g[12]).attackDelay, 90, g[12] .. ": attackDelay")
	lu.assertEquals(quest(g[1]).recoverShip, "smuggler_freighterheavy_tier3", g[1] .. ": recoverShip")
	lu.assertEquals(quest(g[1]).escortShips, { "valarian_gunship_tier3", "valarian_gunship_tier3", "valarian_bomber_tier3" }, g[1] .. ": escortShips")
	lu.assertEquals(quest(g[1]).recoveryConversationMobile, "object/mobile/shared_dressed_criminal_smuggler_human_female_01.iff", g[1] .. ": recoveryConversationMobile")
	lu.assertEquals(quest(g[5]).surpriseAttackShips, { zone = "space_yavin4", spawns = { { count = 1, shipName = "valarian_replacement_3_tier3" } } }, g[5] .. ": surpriseAttackShips")
end

-- AC-2, I-5: the four heads pay 25000 and exactly one item; the children pay nothing
function TestSmugglerT3Tables:test_rewards_are_on_the_four_heads_only()
	local rewards = B.rewards()

	for n, global in ipairs(B.HEADS) do
		local q = quest(global)
		local id = B.IDENTITY[global]
		local rw = rewards[id.type .. "/" .. id.name]

		lu.assertEquals(q.creditReward, 25000, global .. ": creditReward (mission " .. n .. ")")
		lu.assertEquals(#q.itemReward, 1, global .. ": itemReward entries")
		lu.assertEquals(q.itemReward[1], { species = { -1 }, item = rw.item }, global .. ": itemReward[1] (BJ)")
	end

	local head = {}

	for _, g in ipairs(B.HEADS) do
		head[g] = true
	end

	for _, global in ipairs(B.GLOBALS) do
		if not head[global] then
			lu.assertNil(rawget(quest(global), "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(quest(global), "itemReward"), global .. ": itemReward")
		end
	end
end

-- AC-2, I-6: exactly the 13 non-end tables split, each naming its child and its parent; the chains are 5, 3, 4, 5 long in order
function TestSmugglerT3Tables:test_split_wiring_and_chain_order()
	local ends = { [B.GLOBALS[5]] = true, [B.GLOBALS[8]] = true, [B.GLOBALS[12]] = true, [B.GLOBALS[17]] = true }
	local splits = 0

	for n, chain in ipairs(B.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)

			if ends[global] then
				lu.assertEquals(rawget(q, "sideQuest"), false, global .. ": sideQuest (chain end)")
				lu.assertEquals(rawget(q, "sideQuestType"), "", global .. ": sideQuestType (chain end)")
			else
				splits = splits + 1

				local nextId = B.IDENTITY[chain[i + 1]]

				lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, nextId.type, nextId.name }, global .. ": names the next chain member")
			end

			if i > 1 then
				local pid = B.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": names its parent")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end

		local members = {}

		for i, m in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			members[i] = m.global
		end

		lu.assertEquals(members, chain, "mission " .. n .. ": getSpaceQuestChain(head) returns the members in chain order")
	end

	lu.assertEquals(splits, 13, "tables that split")
	lu.assertEquals({ #B.CHAINS[1], #B.CHAINS[2], #B.CHAINS[3], #B.CHAINS[4] }, { 5, 3, 4, 5 }, "chain lengths")
end

-- I-3: every ship string, including nested lists, names a ship template; every item an object file
function TestSmugglerT3Tables:test_every_ship_and_item_the_tables_name_exists()
	local seen = {}

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		for _, key in ipairs({ "escortShips", "recoverShip", "attackShips", "attackShipLists", "shipList", "deliveryShip", "targetShipType", "allyForce", "enemyForce" }) do
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

	lu.assertEquals(n, 27, "distinct ship names the 17 tables use")

	local serverObjects = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(serverObjects and serverObjects:find("shared_dressed_criminal_smuggler_human_female_01.iff", 1, true), "object/mobile/objects.lua includes the recovery conversation mobile")
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4): production versus the derived values, point by point
---------------------------------------------------------------------------------------------

TestSmugglerT3Conformance = {}

function TestSmugglerT3Conformance:setUp() H.reset() end

local POINT_LISTS = {
	{ "targetPatrols", { "escortPath" } }, { "escortPoints", { "escortPath" } }, { "preRecoveryPoints", { "escortPath" } }, { "recoveryPoints", { "recoveryPath" } },
	{ "patrolPoints", { "navPoints" } }, { "recoveryPath", { "recoveryPath" } },
}

-- AC-2, I-2: every point of every table is a Core3 patrol point of its zone with the same x, z, y, names and order of the .tab lists, numbering 1-based
function TestSmugglerT3Conformance:test_every_point_resolves_in_its_zone_point_file_with_the_same_coordinates_in_tab_order()
	local checked = 0

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)
		local rec = B.fixtureOf(global)
		local zonePoints = H.patrolPoints(q.questZone)

		for _, l in ipairs(POINT_LISTS) do
			local list = rawget(q, l[1])

			if list ~= nil then
				local want = {}

				for i, value in ipairs(rec:list(l[2][1])) do
					local _, name = H.Tab.splitNavPoint(value)

					want[i] = name
				end

				local got = {}

				for i, p in ipairs(list) do
					checked = checked + 1
					got[i] = p.patrolPointName
					lu.assertNotNil(zonePoints[p.patrolPointName], global .. "." .. l[1] .. "[" .. i .. "]: " .. tostring(p.patrolPointName) .. " is not a " .. q.questZone .. " patrol point")
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

	lu.assertEquals(checked, 34, "points checked (5 + 3 recovery, 12 assassinate, 5 escort, 3 + 3 patrol, 3 rescue)")
end

-- AC-2, I-2: the escort points carry the zone, recovery points do not; radii
function TestSmugglerT3Conformance:test_point_extras_zone_and_radius()
	for i, p in ipairs(quest(B.GLOBALS[12]).escortPoints) do
		lu.assertEquals({ p.zoneName, p.radius }, { "space_dathomir", 250 }, B.GLOBALS[12] .. ".escortPoints[" .. i .. "] (zoneName, radius)")
	end

	for _, key in ipairs({ "preRecoveryPoints", "recoveryPoints" }) do
		for i, p in ipairs(quest(B.GLOBALS[1])[key]) do
			lu.assertNil(p.zoneName, B.GLOBALS[1] .. "." .. key .. "[" .. i .. "].zoneName")
			lu.assertEquals(p.radius, 250, B.GLOBALS[1] .. "." .. key .. "[" .. i .. "].radius")
		end
	end

	for _, g in ipairs({ B.GLOBALS[13], B.GLOBALS[16] }) do
		for i, p in ipairs(quest(g).patrolPoints) do
			lu.assertEquals(p.radius, 150, g .. ".patrolPoints[" .. i .. "].radius")
		end
	end
end

-- AC-2, I-2: the battle forward vectors are the excerpt's fltK values; the three validSpawns are the excerpt spawner rows, which Core3's spawner file also holds
function TestSmugglerT3Conformance:test_battle_forward_and_inspect_spawners_match_the_excerpts_and_the_core3_spawner_file()
	local d = B.buildout("dathomir")

	lu.assertEquals(quest(B.GLOBALS[14]).battlePoint.forward, d.nav.tier3_privateer_battle_01.forward, B.GLOBALS[14] .. ": battlePoint.forward")
	lu.assertEquals(quest(B.GLOBALS[15]).battlePoint.forward, d.nav.tier3_privateer_battle_02.forward, B.GLOBALS[15] .. ": battlePoint.forward")

	local text = readFile(H.SCRIPTS .. "screenplays/space/spawning/space_dathomir_spawner.lua")
	local spawners = H.spawners("space_dathomir")

	for _, global in ipairs({ B.GLOBALS[6], B.GLOBALS[7] }) do
		for i, v in ipairs(quest(global).validSpawns) do
			lu.assertNotNil(spawners[v.spawnName], global .. ".validSpawns[" .. i .. "]: Core3 has no spawner " .. v.spawnName)
			lu.assertNotNil(text:find('spawnName = "' .. v.spawnName .. '", spawnType = SHIP_SPAWN_SINGLE, x = ' .. v.x .. ", z = " .. v.z .. ", y = " .. v.y .. ",", 1, true),
				global .. ".validSpawns[" .. i .. "]: space_dathomir_spawner.lua has no " .. v.spawnName .. " at " .. v.x .. ", " .. v.z .. ", " .. v.y)
		end
	end
end

-- AC-2, I-4: the mapped fields, quest by quest, with the quest name and the field in the message
function TestSmugglerT3Conformance:test_every_mapped_field_equals_the_value_derived_from_its_fixture()
	local want = B.expected()

	for _, global in ipairs(B.GLOBALS) do
		local id = B.IDENTITY[global]

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(quest(global), key), value, id.type .. "/" .. id.name .. ": " .. key)
		end
	end
end

-- AC-2: the Core3-only values: failTimer 20 on the three assassinates, none elsewhere
function TestSmugglerT3Conformance:test_the_assassinates_carry_failTimer_20_and_nothing_else_does()
	for _, global in ipairs(B.GLOBALS) do
		local want = B.IDENTITY[global].type == "assassinate" and 20 or nil

		lu.assertEquals(rawget(quest(global), "failTimer"), want, global .. ": failTimer")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2, I-11: the inspect cargo on the two ship templates
---------------------------------------------------------------------------------------------

TestSmugglerT3Cargo = {}

function TestSmugglerT3Cargo:setUp() H.reset() end

-- I-11: the template files carry the quest cargo as a cargoString, on the line directly after questLoot
function TestSmugglerT3Cargo:test_the_witchblood_template_files_carry_the_quest_cargo_directly_after_questLoot()
	local cases = {
		{ file = B.SHIP_FILES.soldier, loot = "witchblood_rallyinfo", cargo = "rally_point_info", quest = B.GLOBALS[6] },
		{ file = B.SHIP_FILES.punisher, loot = "witchblood_baseinfo", cargo = "hidden_base_info", quest = B.GLOBALS[7] },
	}

	for _, c in ipairs(cases) do
		local src = readFile(H.SCRIPTS .. c.file)

		lu.assertNotNil(src, c.file)

		local l = lines(src)
		local at

		for i, line in ipairs(l) do
			if line:find('questLoot = "' .. c.loot .. '",', 1, true) then
				at = i
			end
		end

		lu.assertNotNil(at, c.file .. ": questLoot " .. c.loot)
		lu.assertEquals(l[at + 1]:match('^%s*cargoString = "([^"]*)",'), c.cargo, c.file .. ": cargoString on the line after questLoot")
		lu.assertEquals(quest(c.quest).cargo, c.cargo, c.quest .. ": cargo equals the template's cargoString")
		lu.assertEquals(countMatches(src, "cargoString"), 1, c.file .. ": one cargoString")
	end
end

-- I-11: the loaded templates have the cargo strings (the real ship_mobile registration)
function TestSmugglerT3Cargo:test_the_loaded_templates_have_the_cargo_strings()
	lu.assertEquals(H.shipTemplate("dath_witchblood_clan_soldier_tier3").cargoString, "rally_point_info", "dath_witchblood_clan_soldier_tier3: cargoString")
	lu.assertEquals(H.shipTemplate("dath_witchblood_clan_punisher_tier3").cargoString, "hidden_base_info", "dath_witchblood_clan_punisher_tier3: cargoString")
end

---------------------------------------------------------------------------------------------
-- Coverage of the SWG-Source quest names (spec "Coverage"): asserted by test_smuggler_tier2_data.lua (230 of 925; tatooine_privateer 43 of 44 since smuggler-tier4-nirame)
---------------------------------------------------------------------------------------------

TestSmugglerT3Coverage = {}

function TestSmugglerT3Coverage:setUp() H.reset() end

-- AC-2: the 17 names are SWG quest names (in swgsource_quests.txt) and each questName string appears once under bin/scripts
function TestSmugglerT3Coverage:test_the_17_names_are_swg_quest_names_and_each_is_defined_once()
	local swg = readFile("/home/swgemu/swg-source-research/swgsource_quests.txt")

	if swg == nil then
		lu.skip("the SWG-Source research clone has no swgsource_quests.txt")
	end

	local set = {}

	for name in swg:gmatch("[^\r\n]+") do
		set[name] = true
	end

	local pipe = io.popen("grep -rhoE 'questName[[:space:]]*=[[:space:]]*\"tatooine_privateer_tier3[a-z0-9_]*\"' --include=*.lua '" .. H.SCRIPTS .. "' 2>/dev/null")
	local output = pipe:read("a")

	pipe:close()

	local count = {}

	for name in output:gmatch('"([^"]+)"') do
		count[name] = (count[name] or 0) + 1
	end

	for _, global in ipairs(B.GLOBALS) do
		local name = B.IDENTITY[global].name

		lu.assertTrue(set[name] == true, name .. " is not an SWG-Source quest name")
		lu.assertEquals(count[name], 1, "questName \"" .. name .. "\" definitions under bin/scripts")
	end
end
