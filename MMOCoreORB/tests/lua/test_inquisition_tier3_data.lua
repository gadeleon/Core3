-- Inquisition tier 3 (Inquisitor Vrke): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-1, AC-2; invariants I-1 .. I-8; Data mapping 1 and 2; Appendix B; FV-9).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of inquisition_tier3_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local Swgjava = require("harness.swgjava")

V.load()

local function quest(global) return V.quest(global) end

local function fixtureOf(global)
	local id = V.IDENTITY[global]

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

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
end

-- the points of a .tab column as { zone, name, x, z, y } from the Core3 patrol point files
local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		out[i] = { zone = zone, name = name, x = p.x, z = p.z, y = p.y }
	end

	return out
end

-- attackShips1..numAttackShipLists, column-wise, the filled columns only (escort 4_a declares 5 and fills 4: FV-12)
local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		local list = rec:list("attackShips" .. i)

		if #list > 0 then
			lists[#lists + 1] = list
		end
	end

	return lists
end

local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

-- zone -> { nav = name -> {x, z, y, forward}, spawner = name -> {x, z, y}, rows = n } from the buildout extract of this feature
local function extract(zone)
	local out = { nav = {}, spawner = {}, rows = 0 }

	for _, rec in ipairs(H.fixture("space_zones/buildout/" .. zone .. ".inquisition_tier3_points.tab").records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawner = vars:match("strSpawnerName|4|([^|]+)|")
		local xyz = { x = trunc(rec:num("fltPX")), z = trunc(rec:num("fltPY")), y = trunc(rec:num("fltPZ")) }

		out.rows = out.rows + 1

		if nav then
			xyz.forward = { x = rec:num("fltKX"), z = rec:num("fltKY"), y = rec:num("fltKZ") }
			out.nav[nav] = xyz
		elseif spawner then
			out.spawner[spawner] = xyz
		end
	end

	return out
end

-- The ship template file without comments
local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	local src = readFile(path)

	return (src:gsub("%-%-[^\n]*", ""))
end

local function label(global) return V.IDENTITY[global].type .. "/" .. V.IDENTITY[global].name end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestInquisitionT3Fixtures = {}

function TestInquisitionT3Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the 16 fixtures carry the chain wiring and the anchor values the spec lists
function TestInquisitionT3Fixtures:test_the_fixtures_carry_the_chain_wiring_the_spec_lists()
	-- global -> { zone, triggerEvent, triggerSplitCondition, triggerArg, triggerOn, triggerDelay }
	local want = {
		[V.M1[1]] = { "space_naboo", "splitquest", "triggerOn", "inspect:naboo_imperial_tier3_1_a", -1, nil },
		[V.M1[2]] = { "space_yavin4", "splitquest", "success", "delivery_no_pickup:naboo_imperial_tier3_1_b", -1, 0 },
		[V.M1[3]] = { "space_yavin4", "none", "triggerOn", nil, 0, 0 },
		[V.M2[1]] = { "space_yavin4", "splitquest", "success", "survival:naboo_imperial_tier3_2_a", -1, 10 },
		[V.M2[2]] = { "space_yavin4", "splitquest", "triggerOn", "delivery:naboo_imperial_tier3_2_b", -1, nil },
		[V.M2[3]] = { "space_yavin4", "splitquest", "success", "recovery:naboo_imperial_tier3_2_c", -1, 0 },
		[V.M2[4]] = { "space_dathomir", "none", nil, nil, nil, nil },
		[V.M3[1]] = { "space_dathomir", "splitquest", "success", "destroy_surpriseattack:naboo_imperial_tier3_3_a", -1, nil },
		[V.M3[2]] = { "space_dathomir", "splitquest", "success", "rescue:naboo_imperial_tier3_3_b", -1, 0 },
		[V.M3[3]] = { "space_dathomir", "splitquest", "success", "inspect:naboo_imperial_tier3_3_c", -1, nil },
		[V.M3[4]] = { "space_dathomir", "splitquest", "success", "delivery_no_pickup:naboo_imperial_tier3_3_d", -1, nil },
		[V.M3[5]] = { "space_naboo", "none", nil, nil, nil, nil },
		[V.M4[1]] = { "space_dathomir", "splitquest", "success", "escort:naboo_imperial_tier3_4_a", -1, nil },
		[V.M4[2]] = { "space_dathomir", "splitquest", "success", "space_battle:naboo_imperial_tier3_4_b", -1, 10 },
		[V.M4[3]] = { "space_dathomir", "splitquest", "success", "assassinate:naboo_imperial_tier3_4_c", -1, nil },
		[V.M4[4]] = { "space_dathomir", "none", "triggerOn", nil, 0, nil },
	}

	for _, global in ipairs(V.GLOBALS) do
		local rec = fixtureOf(global)
		local w = want[global]
		local l = label(global)

		lu.assertEquals(rec:get("questZone"), w[1], l .. ": questZone")
		lu.assertEquals(rec:get("triggerEvent"), w[2], l .. ": triggerEvent")

		if w[3] ~= nil then
			lu.assertEquals(rec:get("triggerSplitCondition"), w[3], l .. ": triggerSplitCondition")
		end

		if w[4] ~= nil then
			lu.assertEquals(rec:get("triggerArg"), w[4], l .. ": triggerArg")
		end

		if w[5] ~= nil then
			lu.assertEquals(rec:num("triggerOn"), w[5], l .. ": triggerOn")
		end

		if w[6] ~= nil then
			lu.assertEquals(rec:num("triggerDelay"), w[6], l .. ": triggerDelay")
		end
	end
end

-- AC-2 (the oracle itself): the type-specific anchor values of the fixtures
function TestInquisitionT3Fixtures:test_the_fixtures_carry_the_payload_anchors_the_spec_lists()
	local r1 = fixtureOf(V.M1[1])

	lu.assertEquals({ r1:get("targetShipType"), r1:num("targetArrivalDelay"), r1:num("targetRecoverTime"), r1:list("targetEscort"), #r1:list("escortPath"), #r1:list("recoveryPath"),
		r1:get("recoveryAppearance"), r1:num("numResponses"), r1:num("attackPeriod"), #attackLists(r1) },
		{ "colonel_hend_yacht_tier3", 30, 30, {}, 5, 2, "object/mobile/space_comm_imperial_officer_01.iff", 5, 90, 2 }, "recovery/naboo_imperial_tier3_1")

	lu.assertEquals(r1:list("escortPath")[1], "space_naboo:naboo_imperial_tier3_recovery1_1", "recovery 1 escortPath[1]")
	lu.assertEquals(r1:list("escortPath")[5], "space_naboo:corellia_imperial_tier3_leg_4_assassinate_one_1", "recovery 1 escortPath[5] (SWG's own fifth point, D-11)")
	lu.assertEquals(r1:list("recoveryPath")[1], "space_naboo:naboo_imperial_tier3_recovery1_5", "recovery 1 recoveryPath[1]")

	local i1 = fixtureOf(V.M1[2])

	lu.assertEquals({ i1:list("shipList"), i1:list("validSpawns"), i1:num("giveSpawnWaypoint"), i1:get("cargo") },
		{ { "mercenary_spy_fighter_tier4" }, { "space_yavin4:naboo_imperial_tier3_inspect1_spawner" }, 1, "pirate_data" }, "inspect/naboo_imperial_tier3_1_a")

	local d1 = fixtureOf(V.M1[3])

	lu.assertEquals({ d1:get("deliveryShip"), d1:list("deliveryPoint"), d1:num("attackPeriod"), d1:num("numAttackShipLists") },
		{ "imp_freightermedium_tier3", { "space_yavin4:naboo_imperial_tier3_delivery1_dropoff" }, 90, 4 }, "delivery_no_pickup/naboo_imperial_tier3_1_b")

	local i2 = fixtureOf(V.M2[1])

	lu.assertEquals({ i2:list("shipList"), i2:list("validSpawns"), i2:get("cargo") },
		{ { "shinss_yacht_tier3" }, { "space_yavin4:naboo_imperial_tier3_shinssyacht_spawner" }, "shinss_personal_logs" }, "inspect/naboo_imperial_tier3_2")

	local s2 = fixtureOf(V.M2[2])

	lu.assertEquals({ s2:num("totalTransmissionTime"), s2:num("timesToUpdateProgress"), s2:num("transmissionStartDelay"), s2:num("delayToFirstAttack"), s2:num("attackPeriod"), #attackLists(s2) },
		{ 600, 20, 45, 45, 90, 5 }, "survival/naboo_imperial_tier3_2_a")

	local c2 = fixtureOf(V.M2[4])

	lu.assertEquals({ c2:get("targetShipType"), c2:num("targetArrivalDelay"), c2:num("targetRecoverTime"), #c2:list("targetEscort"), c2:list("targetEscort")[1], #c2:list("escortPath"), #c2:list("recoveryPath"), c2:get("recoveryAppearance") },
		{ "shinss_escape_shuttle_tier3", 15, 30, 5, "shinss_escort_fighters_tier3", 5, 3, nil }, "recovery/naboo_imperial_tier3_2_c")

	local p3 = fixtureOf(V.M3[2])

	lu.assertEquals({ p3:get("shipType"), p3:num("shipCount"), p3:get("questZone") }, { "reb_xwing_tier3", 7, "space_dathomir" }, "destroy_surpriseattack/naboo_imperial_tier3_3_a")

	local r3 = fixtureOf(V.M3[3])

	lu.assertEquals({ r3:get("targetShipType"), r3:num("targetArrivalDelay"), #r3:list("recoveryPath"), r3:num("numResponses"), r3:num("numAttackShipLists") },
		{ "imp_lambda_shuttle_tier3", 15, 4, 5, 3 }, "rescue/naboo_imperial_tier3_3_b")

	local i3 = fixtureOf(V.M3[4])

	lu.assertEquals({ i3:list("shipList"), i3:list("validSpawns"), i3:get("cargo") },
		{ { "rebel_spyfreighter_tier3" }, { "space_dathomir:naboo_imperial_tier3_inspect3_spawner" }, "rebel_plans" }, "inspect/naboo_imperial_tier3_3_c")

	local a4 = fixtureOf(V.M4[1])

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("targetEscort"), a4:list("targetEscort")[1], #a4:list("escortPath"), a4:num("mustDestroyEscort") },
		{ "general_breckon_shuttle_tier4", 30, 5, "breckon_escort_fighter_tier3", 4, 1 }, "assassinate/naboo_imperial_tier3_4")

	local e4 = fixtureOf(V.M4[2])

	lu.assertEquals({ e4:list("escortShipType"), #e4:list("escortPath"), e4:num("numAttackShipLists"), #attackLists(e4), e4:num("attackPeriod"), e4:num("numResponses") },
		{ { "dathomir_prison_shuttle_tier4" }, 4, 5, 4, 120, 0 }, "escort/naboo_imperial_tier3_4_a (FV-11, FV-12)")

	local b4 = fixtureOf(V.M4[3])

	lu.assertEquals({ b4:list("battlePoint"), b4:num("damageMultiplier"), b4:num("allyArrivalDist"), #b4:list("allyForce"), #b4:list("enemyForce") },
		{ { "space_dathomir:naboo_imperial_tier3_spacebattle1" }, 5, 300, 5, 10 }, "space_battle/naboo_imperial_tier3_4_b")

	local c4 = fixtureOf(V.M4[4])

	lu.assertEquals({ c4:get("targetShipType"), #c4:list("targetEscort"), c4:list("escortPath")[1], c4:num("mustDestroyEscort") },
		{ "reb_priceofliberty_tier3", 6, "space_dathomir:naboo_imperial_tier4_recoveryduty1_4", 1 }, "assassinate/naboo_imperial_tier3_4_c")
end

-- FV-8 (the oracle itself): the orphan inspect table is not copied, and the chain tables never name it
function TestInquisitionT3Fixtures:test_the_orphan_inspect_2_b_is_not_part_of_the_chain()
	lu.assertEquals(H.fileExists(H.FIXTURES .. "spacequest/inspect/naboo_imperial_tier3_2_b.tab"), false, "the orphan inspect/naboo_imperial_tier3_2_b.tab is not a fixture of this feature")

	for _, global in ipairs(V.GLOBALS) do
		lu.assertNotEquals(fixtureOf(global):get("triggerArg"), "inspect:naboo_imperial_tier3_2_b", label(global) .. ": no table splits to the orphan")
	end
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files, spawner tables and buildout excerpts hold
function TestInquisitionT3Fixtures:test_the_spec_points_equal_the_core3_point_files_and_the_buildout_extracts()
	local total = 0

	for zone, points in pairs(V.POINTS) do
		local ex = extract(zone)

		for name, xyz in pairs(points) do
			local p = point(zone, name)
			local row = ex.nav[name]

			total = total + 1
			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point file: " .. name)
			lu.assertNotNil(row, zone .. " buildout extract has no row for " .. name)
			lu.assertEquals({ row.x, row.z, row.y }, xyz, zone .. " buildout extract (truncated toward zero): " .. name)
		end
	end

	lu.assertEquals(total, 8 + 3 + 27, "spec nav points (8 Naboo, 3 Yavin 4, 27 Dathomir)")

	local spawners = 0

	for zone, list in pairs(V.SPAWNERS) do
		for name, xyz in pairs(list) do
			local s = H.spawners(zone)[name]
			local row = extract(zone).spawner[name]

			spawners = spawners + 1
			lu.assertNotNil(s, zone .. " spawner " .. name)
			lu.assertEquals({ s.x, s.z, s.y }, xyz, zone .. " spawner " .. name)
			lu.assertEquals(row and { row.x, row.z, row.y }, xyz, zone .. " buildout extract: spawner " .. name)
		end
	end

	lu.assertEquals(spawners, 3, "spec inspect spawners")
	lu.assertEquals(extract("space_naboo").rows, 8, "rows of the space_naboo extract (8 nav points)")
	lu.assertEquals(extract("space_yavin4").rows, 5, "rows of the space_yavin4 extract (3 nav points and 2 spawners)")
	lu.assertEquals(extract("space_dathomir").rows, 28, "rows of the space_dathomir extract (27 nav points and the spawner)")
end

-- AC-2 (the oracle itself): the battle forward axis
function TestInquisitionT3Fixtures:test_the_battle_forward_axis_is_the_buildout_k_axis()
	local row = extract("space_dathomir").nav.naboo_imperial_tier3_spacebattle1

	lu.assertEquals(row.forward, V.FORWARD, "fltKX, fltKY, fltKZ of the battle point")
end

-- I-7 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J3:239-270)
function TestInquisitionT3Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_imperial_tier3.java")

	lu.assertNotNil(java, "fixtures/script/conversation/naboo_imperial_tier3.java")

	local found = {}

	for questType, questName, credits, path in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		found[questType .. "_" .. questName] = { tonumber(credits), path }
	end

	lu.assertEquals(found.recovery_naboo_imperial_tier3_1, { V.CREDITS, V.ITEMS[1] }, "J3 giveReward 1")
	lu.assertEquals(found.inspect_naboo_imperial_tier3_2, { V.CREDITS, V.ITEMS[2] }, "J3 giveReward 2")
	lu.assertEquals(found.delivery_naboo_imperial_tier3_3, { V.CREDITS, V.ITEMS[3] }, "J3 giveReward 3")
	lu.assertEquals(found.assassinate_naboo_imperial_tier3_4, { V.CREDITS, V.ITEMS[4] }, "J3 giveReward 4")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 100%.0f%)"), 4, "J3: +100 Imperial standing, once per reward")
	lu.assertEquals(countMatches(java, 'noisyGrantSkill%(player, "pilot_imperial_navy_%a+_03"%)'), 4, "J3: the four tier 3 skills are granted by noisyGrantSkill (no XP)")
	lu.assertEquals(countMatches(java, 'space_flags%.setSpaceFlag%(player, "questionBarlow", 1%)'), 1, "J3 defines sentToBarlow (FV-2)")
	lu.assertEquals(countMatches(java, "action_sentToBarlow%("), 1, "J3 never calls sentToBarlow (FV-2: only its definition names it)")
end

-- AC-2 (the oracle itself): the SWG script parses
function TestInquisitionT3Fixtures:test_the_swg_script_parses_the_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_imperial_tier3.java")

	lu.assertTrue(#graph.order >= 150, "NPC lines parsed from naboo_imperial_tier3.java: " .. #graph.order)
end

-- AC-2 / I-5 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo (FV-9)
function TestInquisitionT3Fixtures:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local mobiles = {}

	for _, rec in ipairs(H.fixture("space_mobile/space_mobile.inquisition_tier3_inspect.tab").records) do
		mobiles[rec:get("strIndex")] = rec
	end

	-- ship -> { space_mobile cargo column, inspect_cargo row name, the inspect quest }
	local want = {
		mercenary_spy_fighter_tier4 = { "pirate_data", "pirate_data", V.M1[2] },
		shinss_yacht_tier3 = { "shinss_personal_logs", "shinss_personal_logs", V.M2[1] },
		rebel_spyfreighter_tier3 = { "rebel_plans_impt3", "rebel_plans", V.M3[4] },
	}

	for ship, w in pairs(want) do
		local rec = mobiles[ship]

		lu.assertNotNil(rec, "the space_mobile excerpt has a row for " .. ship)
		lu.assertEquals(rec:get("cargo"), w[1], ship .. ": space_mobile.tab cargo column (names the inspect_cargo table)")

		local rows = H.fixture("spacequest/inspect_cargo/" .. w[1] .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. w[1] .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { w[2], 1 }, "inspect_cargo/" .. w[1] .. ".tab row (canTransfer 1)")
		lu.assertEquals(fixtureOf(w[3]):get("cargo"), w[2], ship .. ": the inspect quest cargo is that row")
	end
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestInquisitionT3Fixtures:test_the_client_quest_name_table_lists_the_sixteen_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(V.GLOBALS) do
		local id = V.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestInquisitionT3Wiring = {}

function TestInquisitionT3Wiring:setUp() H.reset() end

-- AC-1
function TestInquisitionT3Wiring:test_the_squadron_file_registers_the_sixteen_tier_3_quests_with_start_true()
	for _, global in ipairs(V.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1: the 16 globals register in the contract order, after the 15 tier 1-2 globals
function TestInquisitionT3Wiring:test_the_sixteen_quests_register_in_the_contract_order_after_the_fifteen_older_quests()
	local order = {}

	for _, global in ipairs(V.OLDER_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(V.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- AC-1
function TestInquisitionT3Wiring:test_the_squadron_screenplay_has_the_tier_3_constants_both_barlow_keys_and_the_reset_with_tiers_1_and_2_unchanged()
	quest(V.GLOBALS[1])

	local sq = H.expectGlobal("InquisitionSquadronScreenplay", "squadron screenplay object")

	lu.assertNotNil(H.registered("InquisitionSquadronScreenplay"), "InquisitionSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("InquisitionSquadronScreenplay").start, "InquisitionSquadronScreenplay: registered with start = false")
	lu.assertEquals(pcall(sq.start, sq), true, "InquisitionSquadronScreenplay:start runs")

	for field, want in pairs(V.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "InquisitionSquadronScreenplay." .. field)
	end

	-- tier 1 and tier 2 fields are unchanged (the values T1 and T2 pin)
	lu.assertEquals(sq.QUEST_STRING_4, { type = "assassinate", name = "naboo_imperial_4" }, "InquisitionSquadronScreenplay.QUEST_STRING_4 (tier 1, unchanged)")
	lu.assertEquals(sq.TIER2_QUEST_STRING_4, { type = "assassinate", name = "naboo_imperial_tier2_4" }, "InquisitionSquadronScreenplay.TIER2_QUEST_STRING_4 (tier 2, unchanged)")
	lu.assertEquals(sq.TIER2_QUEST_STRING_DUTY_3, { type = "destroy_duty", name = "naboo_imperial_tier2_destroyduty" }, "InquisitionSquadronScreenplay.TIER2_QUEST_STRING_DUTY_3 (tier 2, unchanged)")
	lu.assertEquals(sq.SERIES_COMPLETE_KEY, V.SERIES_SUFFIX, "InquisitionSquadronScreenplay.SERIES_COMPLETE_KEY (unchanged)")
	lu.assertEquals(sq.INQUISITORIAL_AGENT_KEY, V.AGENT_SUFFIX, "InquisitionSquadronScreenplay.INQUISITORIAL_AGENT_KEY (unchanged)")

	lu.assertEquals(sq.QUESTION_BARLOW_KEY, V.QUESTION_SUFFIX, "InquisitionSquadronScreenplay.QUESTION_BARLOW_KEY")
	lu.assertEquals(sq.SPOKE_TO_BARLOW_KEY, V.SPOKE_SUFFIX, "InquisitionSquadronScreenplay.SPOKE_TO_BARLOW_KEY")
	lu.assertEquals(type(sq.resetBarnQuests), "function", "InquisitionSquadronScreenplay:resetBarnQuests")
	lu.assertEquals(type(sq.resetFaZollQuests), "function", "InquisitionSquadronScreenplay:resetFaZollQuests")
	lu.assertEquals(type(sq.resetVrkeQuests), "function", "InquisitionSquadronScreenplay:resetVrkeQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetVrkeQuests, sq, nil), true, "resetVrkeQuests(nil) returns early")
end

-- AC-1
function TestInquisitionT3Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	V.requireConversation(lu)

	local t = H.conversationTemplateTable(V.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, V.HANDLER, V.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", V.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, V.HANDLER).getInitialScreen), "function", V.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, V.HANDLER).runScreenHandlers), "function", V.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, V.HANDLER).getNextConversationScreen), "function", V.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestInquisitionT3Wiring:test_vrke_uses_the_template_and_has_fa_zolls_options_mask()
	local npc = H.loadCreatureTemplate("space/vrke.lua", "vrke")

	lu.assertNotNil(npc, "mobile/space/vrke.lua registers vrke")
	lu.assertEquals(npc.conversationTemplate, "vrke_convo_template", "vrke: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "vrke: optionsBitmask (Fa'Zoll's mask, J3:6647-6649)")
end

local function fileLines(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

-- AC-1: the template include is uncommented exactly once, directly after Fa'Zoll's
function TestInquisitionT3Wiring:test_the_template_include_line_is_uncommented_exactly_once_directly_after_fa_zolls()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/inquisition_squadron/vrke_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented vrke_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented vrke_convo include")

	local lines, at = fileLines(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the fa_zoll_convo include")
	lu.assertEquals((lines[at + 1] or ""):gsub("^%s+", ""), 'includeFile("conversations/space/imperial/inquisition_squadron/vrke_convo.lua")', "space_conversations.lua: the vrke include directly after Fa'Zoll's")
end

-- AC-1: the handler include follows Fa'Zoll's handler include with no blank line
function TestInquisitionT3Wiring:test_the_handler_include_line_follows_fa_zolls_handler_include_exactly_once_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/inquisition_squadron/vrkeConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented vrkeConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented vrkeConvoHandler include")

	local lines, at = fileLines(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: Fa'Zoll's handler include")
	lu.assertEquals(lines[at + 1], 'includeFile("space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua")', "screenplays.lua: Vrke's handler include, directly after Fa'Zoll's")
end

-- AC-1: the T1 / T2 position pins keep holding
function TestInquisitionT3Wiring:test_barns_and_fa_zolls_handler_includes_keep_their_positions()
	local lines, squadron = fileLines(readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/InquisitionSquadronScreenplay.lua")', 1, true) then
			squadron = i
		end
	end

	lu.assertNotNil(squadron, "screenplays.lua: the InquisitionSquadronScreenplay include")
	lu.assertEquals(lines[squadron + 2], 'includeFile("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua")', "Barn's handler include at squadron + 2")
	lu.assertEquals(lines[squadron + 3], 'includeFile("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua")', "Fa'Zoll's handler include directly after Barn's")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-6, I-7)
---------------------------------------------------------------------------------------------

TestInquisitionT3Tables = {}

function TestInquisitionT3Tables:setUp() H.reset() end

-- AC-2, I-1
function TestInquisitionT3Tables:test_the_sixteen_tables_keep_their_identity_and_zone()
	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)
		local id = V.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end

	lu.assertEquals(#V.GLOBALS, 16, "tier 3 globals")
end

-- AC-2: Appendix B, every key, nothing else
function TestInquisitionT3Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
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
function TestInquisitionT3Tables:test_no_table_defines_a_function()
	for _, global in ipairs(V.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- AC-2, I-6: exactly the 12 non-end tables split to the next chain member
function TestInquisitionT3Tables:test_exactly_the_twelve_non_end_tables_split_and_name_the_next_chain_member()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local delays = { [V.M2[1]] = 15, [V.M4[2]] = 15 }
	local splits = 0

	for _, chain in ipairs(V.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)
			local isEnd = (i == #chain)

			lu.assertEquals(q.sideQuest and true or false, not isEnd, global .. ": sideQuest")

			if isEnd then
				lu.assertEquals(q.sideQuestType, "", global .. ": the chain end has no split type")
				lu.assertNil(rawget(q, "sideQuestName"), global .. ": the chain end names no split")
			else
				splits = splits + 1

				local nextId = V.IDENTITY[chain[i + 1]]

				lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { nextId.type, nextId.name }, global .. ": sideQuestType, sideQuestName")
				lu.assertEquals(q.sideQuestSplitType, COMPLETION, global .. ": COMPLETION (success, or triggerOn -1)")
				lu.assertEquals(q.sideQuestDelay, delays[global] or 5, global .. ": sideQuestDelay (triggerDelay + 5: 15 for inspect 2 and escort 4_a, 5 otherwise)")
			end

			if i > 1 then
				local pid = V.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splits, 12, "split tables")
end

-- AC-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order
function TestInquisitionT3Tables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(V.CHAINS) do
		quest(chain[1])

		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #V.M1, #V.M2, #V.M3, #V.M4 }, { 3, 4, 5, 4 }, "chain lengths (3, 4, 5, 4)")
end

-- AC-2, I-7: credits and items only on the four heads
function TestInquisitionT3Tables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local heads = { [V.M1[1]] = 1, [V.M2[1]] = 2, [V.M3[1]] = 3, [V.M4[1]] = 4 }

	for _, global in ipairs(V.GLOBALS) do
		local q = quest(global)
		local n = heads[global]

		if n then
			lu.assertEquals(rawget(q, "creditReward"), V.CREDITS, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = V.ITEMS[n] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template (22 ships, 4 items)
function TestInquisitionT3Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "attackShipLists", "allyForce", "enemyForce" }) do
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

	lu.assertEquals(#sortedKeys(ships), 22, "distinct ships in the 16 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 16 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- I-3: recovery 1's conversation mobile is a client template the server knows
function TestInquisitionT3Tables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local q = quest(V.M1[1])
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertEquals(q.recoveryConversationMobile, V.OFFICER_MOBILE, "recovery 1: recoveryConversationMobile")
	lu.assertNotNil(text:find('"' .. q.recoveryConversationMobile .. '"', 1, true), tostring(q.recoveryConversationMobile) .. " is not in object/mobile/objects.lua")
end

-- I-8: the client resolves each journal entry through misc/quest_crc_string_table
function TestInquisitionT3Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")
	local set = {}

	for line in text:gmatch("[^\n]+") do
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

TestInquisitionT3Conformance = {}

function TestInquisitionT3Conformance:setUp() H.reset() end

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

-- AC-2, I-4, I-6: every quest: zone, split target and delay from triggerArg (success or triggerOn -1: COMPLETION, triggerDelay + 5)
function TestInquisitionT3Conformance:test_every_table_takes_zone_and_split_target_from_its_fixture()
	for _, global in ipairs(V.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")
			lu.assertTrue(rec:get("triggerSplitCondition") == "success" or rec:num("triggerOn") == -1, l .. ": precondition: the split fires on success (space_quest.java:583-589)")
			lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, l .. ": COMPLETION")
			lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, l .. ": sideQuestDelay (triggerDelay + 5, space_quest.java:600)")
		else
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

-- AC-2, I-2, I-4: the three recoveries' sibling, recovery 1 and 2_c
function TestInquisitionT3Conformance:test_recoveries_map_ships_paths_attack_lists_and_taunts_from_their_fixtures()
	for _, global in ipairs({ V.M1[1], V.M2[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local radius = function(i) return { escortNumber = i, radius = 250 } end

		lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
		lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")

				local pre = mapped(rec, "escortPath", radius)

		for i, p in ipairs(q.preRecoveryPoints) do
			lu.assertEquals(p.escortNumber, i, l .. ": preRecoveryPoints[" .. i .. "].escortNumber")
			lu.assertEquals(p.radius, 250, l .. ": preRecoveryPoints[" .. i .. "].radius")
			lu.assertNil(p.zoneName, l .. ": preRecoveryPoints[" .. i .. "] has no zoneName")
		end

		for i, p in ipairs(pre) do
			lu.assertEquals(q.preRecoveryPoints[i], p, l .. ": preRecoveryPoints[" .. i .. "] (escortPath, renumbered from 1)")
		end

		lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints (recoveryPath, renumbered from 1, no zoneName)")
	end

	-- recovery 1: SWG's own fifth pre-recovery point (D-11), no escorts, the officer mobile with the shared_ prefix
	local q1, r1 = quest(V.M1[1]), fixtureOf(V.M1[1])

	lu.assertEquals(#q1.preRecoveryPoints, 5, "recovery 1: five pre-recovery points")
	lu.assertEquals(q1.preRecoveryPoints[5].patrolPointName, "corellia_imperial_tier3_leg_4_assassinate_one_1", "recovery 1: the fifth pre-recovery point is SWG's own (D-11)")
	lu.assertEquals(#r1:list("escortPath"), 5, "precondition: the .tab escortPath has 5 points, the fifth being SWG's own name")
	lu.assertEquals(q1.escortShips, {}, "recovery 1: escortShips")
	lu.assertEquals(q1.recoveryConversationMobile, (r1:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")), "recovery 1: recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertNil(rawget(quest(V.M2[4]), "recoveryConversationMobile"), "recovery 2_c: no appearance column, so the type default stays")
end

-- AC-2, I-2, I-4: the three inspects
function TestInquisitionT3Conformance:test_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	for _, global in ipairs({ V.M1[2], V.M2[1], V.M3[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, l .. ": spawner " .. spawnName)
		lu.assertEquals(zone, q.questZone, l .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
		lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns")
		lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
		lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
	end
end

-- AC-2, I-2, I-4: the two delivery_no_pickup and the two delivery tables
function TestInquisitionT3Conformance:test_deliveries_map_ships_points_attack_lists_period_and_order()
	for _, global in ipairs({ V.M1[3], V.M2[3], V.M3[1], V.M3[5] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
		lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")

		if V.IDENTITY[global].type == "delivery" then
			lu.assertEquals(q.pickupShip, rec:get("pickupShip"), l .. ": pickupShip")
			lu.assertEquals(q.pickupPoint, mapped(rec, "pickupPoint")[1], l .. ": pickupPoint")
		else
			lu.assertNil(rawget(q, "pickupPoint"), l .. ": a delivery_no_pickup has no pickup")
		end

		lu.assertNil(rawget(q, "pickupZone"), l .. ": single zone: no pickupZone")
		lu.assertNil(rawget(q, "deliveryZone"), l .. ": single zone: no deliveryZone")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..numAttackShipLists, column-wise)")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	end

	lu.assertEquals(quest(V.M2[3]).pickupPoint.patrolPointName, "corellis_imperial_tier3_leg_2_rescue_3", "delivery 2_b: SWG's own spelling is kept (D-11)")
end

-- AC-2, I-2, I-4: survival 2_a
function TestInquisitionT3Conformance:test_survival_2_a_maps_point_timers_attack_lists_and_order_from_its_fixture()
	local q, rec = quest(V.M2[2]), fixtureOf(V.M2[2])
	local l = label(V.M2[2])

	lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
	lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
	lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
	lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
	lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..5, column-wise)")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- AC-2: surprise attack 3_a
function TestInquisitionT3Conformance:test_surprise_attack_3_a_maps_ship_count_and_zone()
	local q, rec = quest(V.M3[2]), fixtureOf(V.M3[2])
	local l = label(V.M3[2])

	lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } }, l .. ": surpriseAttackShips (shipType, shipCount, questZone)")
end

-- AC-2, I-2, I-4: rescue 3_b
function TestInquisitionT3Conformance:test_rescue_3_b_maps_path_target_attack_lists_and_responses()
	local q, rec = quest(V.M3[3]), fixtureOf(V.M3[3])
	local l = label(V.M3[3])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
end

-- AC-2, I-2, I-4: the two assassinates
function TestInquisitionT3Conformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ V.M4[1], V.M4[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals(quest(V.M4[4]).targetPatrols[1].patrolPointName, "naboo_imperial_tier4_recoveryduty1_4", "assassinate 4_c: SWG's own names are kept (D-11)")
end

-- AC-2, I-2, I-4, FV-11, FV-12: escort 4_a
function TestInquisitionT3Conformance:test_escort_4_a_maps_ship_path_four_attack_lists_and_taunt_counts_of_five()
	local q, rec = quest(V.M4[2]), fixtureOf(V.M4[2])
	local l = label(V.M4[2])

	lu.assertEquals(q.escortShips, rec:list("escortShipType"), l .. ": escortShips (escortShipType)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPath)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (the four filled columns, FV-12)")
	lu.assertEquals(#q.attackShips, 4, l .. ": four attack lists although numAttackShipLists is 5")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(m, 1, "precondition: numResponses 0 gives max(0, 1) = 1")
	lu.assertEquals(q.tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, l .. ": tauntData (the client file has _1.._5 of each key, FV-11)")
end

-- AC-2, I-2, I-4: battle 4_b
function TestInquisitionT3Conformance:test_battle_4_b_maps_point_forward_timers_distances_and_forces()
	local q, rec = quest(V.M4[3]), fixtureOf(V.M4[3])
	local l = label(V.M4[3])
	local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
	local row = extract(zone).nav[name]

	lu.assertNotNil(row, l .. ": buildout extract row of " .. name)
	lu.assertEquals(q.battlePoint, { patrolPointName = name, x = row.x, z = row.z, y = row.y, forward = row.forward }, l .. ": battlePoint (nav point + fltKX/fltKY/fltKZ as forward x/z/y)")

	for field, column in pairs({ damageMultiplier = "damageMultiplier", allyArrivalDelay = "allyArrivalDelay", enemyArrivalDelay = "enemyArrivalDelay", allyOriginDist = "allyOriginDist",
		enemyOriginDist = "enemyOriginDist", allyArrivalDist = "allyArrivalDist", enemyArrivalDist = "enemyArrivalDist" }) do
		lu.assertEquals(q[field], rec:num(column), l .. ": " .. field)
	end

	lu.assertEquals(q.allyForce, rec:list("allyForce"), l .. ": allyForce")
	lu.assertEquals(q.enemyForce, rec:list("enemyForce"), l .. ": enemyForce (SWG order)")
end

---------------------------------------------------------------------------------------------
-- I-5, FV-9: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestInquisitionT3Cargo = {}

function TestInquisitionT3Cargo:setUp() H.reset() end

-- ship -> { inspect quest global, questLoot, the cargoString line text }
local SHIPS = {
	{ ship = "mercenary_spy_fighter_tier4", quest = V.M1[2], questLoot = "pirate_data", cargoRow = "pirate_data", cargoTable = "pirate_data", template = "hutt_medium_s01_tier4", pilot = "medium_fighter_tier4" },
	{ ship = "shinss_yacht_tier3", quest = V.M2[1], questLoot = "shinss_personal_logs", cargoRow = "shinss_personal_logs", cargoTable = "shinss_personal_logs", template = "lambdashuttle_tier3", pilot = "bomber_tier3" },
	{ ship = "rebel_spyfreighter_tier3", quest = V.M3[4], questLoot = "rebel_plans_impt3", cargoRow = "rebel_plans", cargoTable = "rebel_plans_impt3", template = "ykl37r_tier3", pilot = "heavy_tier4" },
}

-- AC-2, I-5, FV-9
function TestInquisitionT3Cargo:test_every_inspect_ship_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	for _, s in ipairs(SHIPS) do
		local q = quest(s.quest)

		lu.assertEquals(q.shipList, { s.ship }, s.quest .. ": shipList")

		local src = templateSource(s.ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, s.ship .. ".lua cargoString must equal the quest cargo (SWG space_mobile.tab cargo column, resolved through inspect_cargo)")
		lu.assertEquals(cargoString, s.cargoRow, s.ship .. ".lua cargoString is the inspect_cargo row name")
		lu.assertEquals(questLoot, s.questLoot, s.ship .. ".lua questLoot (names the inspect_cargo table) stays")

		local rows = H.fixture("spacequest/inspect_cargo/" .. s.cargoTable .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. s.cargoTable .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { q.cargo, 1 }, s.ship .. ": cargo is the canTransfer = 1 row of the table")
	end
end

-- AC-2, I-5: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestInquisitionT3Cargo:test_the_loaded_inspect_ship_templates_have_the_cargo_string_and_are_otherwise_unchanged()
	for _, s in ipairs(SHIPS) do
		local t = H.shipTemplate(s.ship)

		lu.assertNotNil(t, "ship_mobile/ships/" .. s.ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, s.cargoRow, s.ship .. ": cargoString")
		lu.assertEquals(t.questLoot, s.questLoot, s.ship .. ": questLoot is unchanged")
		lu.assertEquals(t.template, s.template, s.ship .. ": template is unchanged")
		lu.assertEquals(t.pilotTemplate, s.pilot, s.ship .. ": pilotTemplate is unchanged")
	end
end
