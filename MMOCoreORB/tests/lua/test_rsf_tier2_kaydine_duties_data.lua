-- RSF Squadron tier 2 (Captain Kaydine) duties on SWG-Source's duty quests: the three duty tables, the deleted inventions, the constants,
-- the legacy data, the 9 real duty points and the 11 deleted invented points.
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (AC-1, AC-2, AC-3, Content contract 1, 2, 6, Data mapping, invariants I-1 .. I-4).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the buildout extract
-- fixtures/space_zones/buildout/space_naboo.rsf_tier2_duty_points.tab, never the Core3 tables under test. The literals of the spec's
-- Content contract (rsf_tier2_kaydine_duties_data.lua) are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier2_kaydine_duties_data")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local EXTRACT = "space_zones/buildout/space_naboo.rsf_tier2_duty_points.tab"
local PP_PATH = H.SCRIPTS .. "ship_mobile/patrol_points/space_naboo.lua"
local RSF_PATH = H.SCRIPTS .. "screenplays/space/squadrons/RsfSquadronScreenplay.lua"

local function quest(global) return H.expectGlobal(global, "RSF tier 2 Kaydine duty quest table (rsf-tier2-kaydine-duties)") end

local function fixtureOf(global)
	local id = D.IDENTITY[global]

	return H.questFixture(id.type, id.name)
end

local function point(zone, name)
	local p = H.patrolPoints(zone)[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in " .. tostring(zone))
	return p
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function readLines(path)
	local out = {}

	for line in (readFile(path) .. "\n"):gmatch("(.-)\r?\n") do
		out[#out + 1] = line
	end

	return out
end

local function stripComment(line) return (line:gsub("%-%-.*$", "")) end

-- Truncation toward zero, as Core3's coordinates truncate the buildout floats.
local function trunc(n)
	if n >= 0 then
		return math.floor(n)
	end

	return math.ceil(n)
end

local function sortedKeys(t)
	local keys = {}

	for k in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	table.sort(keys)
	return keys
end

-- The "zone:name" cells of a column as { name, x, z, y } rows read from the patrol point files
local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(zone, name)

		out[i] = { zone = zone, name = name, x = p.x, z = p.z, y = p.y }
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

-- nav point name -> { x, z, y } of the buildout extract, truncated toward zero
local function buildout()
	local navs, n = {}, 0

	for _, rec in ipairs(H.fixture(EXTRACT).records) do
		local nav = (rec:get("strObjVars") or ""):match("nav_name|4|([^|]+)|")

		if nav ~= nil then
			navs[nav] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
			n = n + 1
		end
	end

	return navs, n
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

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestRsfTier2DutyFixtures = {}

function TestRsfTier2DutyFixtures:setUp() H.reset() end

-- AC-1 .. AC-3 (the oracle itself)
function TestRsfTier2DutyFixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local e = H.questFixture("escort_duty", "naboo_privateer_9")

	lu.assertEquals({ e:get("questZone"), e:get("escortShipTypes"), #e:list("escortPoints"), e:num("numAttackShipLists"), e:num("attackPeriod"), e:num("numResponses"), e:num("reward"), e:num("killReward") },
		{ "space_naboo", "rsf_royal_kylantha_freighter_tier3", 4, 3, 120, 5, 2500, 200 }, "escort_duty/naboo_privateer_9")

	local r = H.questFixture("recovery_duty", "naboo_privateer_10")

	lu.assertEquals({ r:get("targetShipTypes"), r:num("targetArrivalDelay"), r:num("targetRecoverTime"), r:get("recoveryAppearance"), #r:list("escortPath"), #r:list("recoveryPath"), #r:list("targetEscort"), r:num("numAttackShipLists"), r:num("attackPeriod"), r:num("numResponses"), r:num("reward"), r:num("killReward") },
		{ "ndc_duty_transport_tier2", 20, 30, nil, 5, 3, 2, 1, 120, 5, 2500, 200 }, "recovery_duty/naboo_privateer_10")

	local d = H.questFixture("destroy_duty", "naboo_privateer_11")

	lu.assertEquals({ d:num("wavesPerRound"), d:num("roundsPerLevel"), d:num("levelsPerDuty"), d:num("shipTypes"), d:get("bossType"), d:num("numResponses"), d:num("reward") },
		{ 2, 2, 2, 3, "aynat_outlaw_tier3", 0, 200 }, "destroy_duty/naboo_privateer_11")

	local _, n = buildout()

	lu.assertEquals(n, 9, "nav_name rows in " .. EXTRACT)
end

-- AC-3 (the oracle itself): the extract holds exactly the 9 points of the spec, with the buildout floats
function TestRsfTier2DutyFixtures:test_the_buildout_extract_holds_the_nine_duty_points_of_the_spec()
	local navs = buildout()

	lu.assertEquals(sortedKeys(navs), sortedKeys(D.POINTS), "nav points in " .. EXTRACT)

	for name, xyz in pairs(D.POINTS) do
		lu.assertEquals(navs[name], xyz, EXTRACT .. ": " .. name .. " truncated x, z, y")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: the three duty tables
---------------------------------------------------------------------------------------------

TestRsfTier2DutyTables = {}

function TestRsfTier2DutyTables:setUp() H.reset() end

-- AC-1, I-1
function TestRsfTier2DutyTables:test_the_three_duties_are_registered_with_start_and_keep_their_identity()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local id = D.IDENTITY[global]

		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-1, I-1: Content contract 1, every key, nothing else (no dutyMissionLevel, no shipLocations, ...)
function TestRsfTier2DutyTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)
		local own = {}

		for k, v in pairs(q) do
			own[k] = v
		end

		lu.assertEquals(sortedKeys(own), sortedKeys(D.EXPECTED[global]), global .. ": own keys")

		for key, want in pairs(D.EXPECTED[global]) do
			lu.assertEquals(rawget(q, key), want, global .. ": " .. key)
		end
	end
end

-- AC-1
function TestRsfTier2DutyTables:test_destroy_duty_11_has_neither_dutyMissionLevel_nor_shipLocations_and_every_ship_type_is_a_list()
	local q = quest(D.DESTROY)

	lu.assertNil(rawget(q, "dutyMissionLevel"), D.DESTROY .. ": dutyMissionLevel")
	lu.assertNil(rawget(q, "shipLocations"), D.DESTROY .. ": shipLocations")
	lu.assertEquals(#q.shipTypes, 3, D.DESTROY .. ": number of ship lists")

	for i, ships in ipairs(q.shipTypes) do
		lu.assertEquals(type(ships), "table", D.DESTROY .. ": shipTypes[" .. i .. "] is a table")
	end
end

-- AC-1 (Data mapping): escort_duty/naboo_privateer_9.tab
function TestRsfTier2DutyTables:test_escort_duty_9_maps_ships_points_attack_lists_delay_pay_and_taunt_counts()
	local q = quest(D.ESCORT)
	local rec = fixtureOf(D.ESCORT)
	local points = {}

	for i, p in ipairs(pointsOf(rec, "escortPoints")) do
		points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), "escort_duty/naboo_privateer_9: questZone")
	lu.assertEquals(q.escortShips, { rec:get("escortShipTypes") }, "escort_duty/naboo_privateer_9: escortShips (escortShipTypes)")
	lu.assertEquals(q.escortPoints, points, "escort_duty/naboo_privateer_9: escortPoints")
	lu.assertEquals(#points, 4, "escort_duty/naboo_privateer_9: number of escort points (spec)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), "escort_duty/naboo_privateer_9: attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), "escort_duty/naboo_privateer_9: attackShips")
	lu.assertEquals(q.creditReward, rec:num("reward"), "escort_duty/naboo_privateer_9: creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), "escort_duty/naboo_privateer_9: creditKillBonus (killReward)")

	local m = rec:num("numResponses")

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, "escort_duty/naboo_privateer_9: tauntData (numResponses)")
end

-- AC-1 (Data mapping): recovery_duty/naboo_privateer_10.tab
function TestRsfTier2DutyTables:test_recovery_duty_10_maps_ship_escorts_points_attack_lists_delay_pay_and_taunt_counts()
	local q = quest(D.RECOVERY)
	local rec = fixtureOf(D.RECOVERY)
	local label = "recovery_duty/naboo_privateer_10"

	local function numbered(column)
		local out = {}

		for i, p in ipairs(pointsOf(rec, column)) do
			out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		return out
	end

	local escort = rec:get("targetEscort")

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipTypes"), label .. ": recoverShip (targetShipTypes)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), label .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.recoveryConversationMobile or "", rec:get("recoveryAppearance") or "", label .. ": recoveryConversationMobile (recoveryAppearance, empty)")
	lu.assertEquals(q.escortShips, { escort, escort }, label .. ": escortShips (targetEscort, twice)")
	lu.assertEquals(q.preRecoveryPoints, numbered("escortPath"), label .. ": preRecoveryPoints (escortPath)")
	lu.assertEquals(q.recoveryPoints, numbered("recoveryPath"), label .. ": recoveryPoints (recoveryPath)")
	lu.assertEquals(#q.preRecoveryPoints, 5, label .. ": number of pre-recovery points (spec)")
	lu.assertEquals(#q.recoveryPoints, 3, label .. ": number of recovery points (spec)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertEquals(q.killReward, rec:num("killReward"), label .. ": killReward")

	local m = rec:num("numResponses")

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, label .. ": tauntData (numResponses)")
end

-- AC-1 (Data mapping): destroy_duty/naboo_privateer_11.tab
function TestRsfTier2DutyTables:test_destroy_duty_11_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q = quest(D.DESTROY)
	local rec = fixtureOf(D.DESTROY)
	local label = "destroy_duty/naboo_privateer_11"
	local shipTypes = {}

	for i = 1, rec:num("shipTypes") do
		shipTypes[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), label .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), label .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), label .. ": totalLevels (levelsPerDuty)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), label .. ": bossShip (bossType)")
	lu.assertEquals(q.shipTypes, shipTypes, label .. ": shipTypes (columns shipType1..shipTypes)")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertNil(rawget(q, "tauntData"), label .. ": tauntData (numResponses is 0, dropped)")
end

-- AC-1: every ship the three tables name has a ship template (the engine gate checks the real load)
function TestRsfTier2DutyTables:test_every_ship_the_three_tables_name_has_a_ship_template()
	local seen = {}

	local function walk(value)
		if type(value) == "string" then
			seen[value] = true
		elseif type(value) == "table" then
			for _, v in ipairs(value) do
				walk(v)
			end
		end
	end

	for _, global in ipairs(D.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes" }) do
			walk(rawget(q, field))
		end

		walk(rawget(q, "recoverShip"))
		walk(rawget(q, "bossShip"))
	end

	local names = sortedKeys(seen)

	lu.assertEquals(#names, 7, "distinct ships named by the three tables: " .. table.concat(names, ", "))

	for _, name in ipairs(names) do
		lu.assertNotNil(H.shipTemplate(name), "ship template " .. name .. " exists in ship_mobile/ships")
	end
end

---------------------------------------------------------------------------------------------
-- AC-2: the deleted inventions, constants, legacy data, steps, no legacy reference
---------------------------------------------------------------------------------------------

TestRsfTier2DutyConstants = {}

function TestRsfTier2DutyConstants:setUp() H.reset() end

-- AC-2
function TestRsfTier2DutyConstants:test_the_three_invented_duty_globals_are_gone_and_not_registered()
	for _, legacy in ipairs(D.LEGACY) do
		lu.assertNil(rawget(_G, legacy.global), legacy.global .. ": the global still exists")
		lu.assertNil(H.registered(legacy.global), legacy.global .. ": still registered")
	end
end

-- AC-2, I-3
function TestRsfTier2DutyConstants:test_the_duty_strings_follow_the_menu_order_and_there_is_no_fourth()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_1, { type = "escort_duty", name = "naboo_privateer_9" }, "TIER2_QUEST_STRING_DUTY_1")
	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_2, { type = "recovery_duty", name = "naboo_privateer_10" }, "TIER2_QUEST_STRING_DUTY_2")
	lu.assertEquals(R.TIER2_QUEST_STRING_DUTY_3, { type = "destroy_duty", name = "naboo_privateer_11" }, "TIER2_QUEST_STRING_DUTY_3")
	lu.assertNil(R.TIER2_QUEST_STRING_DUTY_4, "TIER2_QUEST_STRING_DUTY_4 no longer exists")
end

-- AC-2
function TestRsfTier2DutyConstants:test_the_legacy_duty_data_equals_the_contract()
	local want = {}

	for i, legacy in ipairs(D.LEGACY) do
		want[i] = { type = legacy.type, name = legacy.name }
	end

	lu.assertEquals(RsfSquadronScreenplay.LEGACY_TIER2_DUTIES, want, "LEGACY_TIER2_DUTIES")
end

-- AC-2
function TestRsfTier2DutyConstants:test_the_migration_steps_are_the_three_names_and_each_is_a_function()
	local R = RsfSquadronScreenplay

	lu.assertEquals(R.LEGACY_MIGRATION_STEPS, { "migrateLegacyTier3", "migrateLegacyTier2", "migrateLegacyTier2Duties" }, "LEGACY_MIGRATION_STEPS")

	for k, name in ipairs(R.LEGACY_MIGRATION_STEPS) do
		lu.assertEquals(type(R[name]), "function", "LEGACY_MIGRATION_STEPS[" .. k .. "] = '" .. name .. "' must be a function on RsfSquadronScreenplay")
	end
end

-- The lines of RSF's LEGACY_TIER2_DUTIES block (assignment to the closing brace)
local function legacyBlockRange(lines)
	local from, depth

	for n, line in ipairs(lines) do
		local code = stripComment(line)

		if from == nil and code:find("LEGACY_TIER2_DUTIES", 1, true) and code:find("=", 1, true) then
			from, depth = n, 0
		end

		if from ~= nil then
			local _, opens = code:gsub("{", "")
			local _, closes = code:gsub("}", "")

			depth = depth + opens - closes

			if depth <= 0 then
				return from, n
			end
		end
	end

	return nil, nil
end

-- AC-2, I-4: no script under bin/scripts names a deleted duty, string or point (comments excluded). The screen ids accept_duty_destroy1 and
-- accept_duty_destroy2 are Kaydine's: CorSec's Rikkh legitimately has screens of the same names, so those two are only searched for in
-- Kaydine's files (the spec's I-4 says "bin/scripts"; that is wider than the intent, reported in the test plan).
function TestRsfTier2DutyConstants:test_no_script_names_a_deleted_duty_screen_string_or_invented_point()
	local needles = { "s_2e7b17f3" }

	for _, legacy in ipairs(D.LEGACY) do
		needles[#needles + 1] = legacy.global
	end

	for _, name in ipairs(D.INVENTED) do
		needles[#needles + 1] = name
	end

	local args = {}

	for _, needle in ipairs(needles) do
		args[#args + 1] = "-e " .. needle
	end

	local pipe = assert(io.popen("grep -rnF --include='*.lua' " .. table.concat(args, " ") .. " " .. H.SCRIPTS .. " 2>/dev/null"))
	local bad = {}

	for hit in pipe:lines() do
		local file, n, text = hit:match("^([^:]+):(%d+):(.*)$")

		if file ~= nil then
			local code = stripComment(text)

			for _, needle in ipairs(needles) do
				if code:find(needle, 1, true) then
					bad[#bad + 1] = file:sub(#H.SCRIPTS + 1) .. ":" .. n .. ": " .. needle
					break
				end
			end
		end
	end

	pipe:close()

	for _, path in ipairs({ "mobile/conversations/space/neutral/rsf_squadron/kaydine_convo.lua", "screenplays/space/conversations/neutral/rsf_squadron/kaydineConvoHandler.lua" }) do
		for n, line in ipairs(readLines(H.SCRIPTS .. path)) do
			local code = stripComment(line)

			for _, id in ipairs({ "accept_duty_destroy1", "accept_duty_destroy2" }) do
				if code:find(id, 1, true) then
					bad[#bad + 1] = path .. ":" .. n .. ": " .. id
				end
			end
		end
	end

	table.sort(bad)
	lu.assertEquals(bad, {}, "bin/scripts still names a deleted duty, screen id, string or invented point")
end

-- AC-2, I-4: the type/name pairs of the deleted duties occur only in the LEGACY_TIER2_DUTIES block of RSF
function TestRsfTier2DutyConstants:test_the_legacy_type_name_pairs_occur_only_in_the_legacy_block()
	local lines = readLines(RSF_PATH)
	local from, to = legacyBlockRange(lines)

	lu.assertNotNil(from, "RsfSquadronScreenplay.lua defines LEGACY_TIER2_DUTIES")

	local patterns = {}

	for _, legacy in ipairs(D.LEGACY) do
		patterns[#patterns + 1] = { '"' .. legacy.type .. '"', '"' .. legacy.name .. '"' }
	end

	local bad = {}
	local pipe = assert(io.popen("grep -rlE --include='*.lua' 'naboo_privateer_(9|10|12)\"' " .. H.SCRIPTS .. " 2>/dev/null"))

	for file in pipe:lines() do
		for n, line in ipairs(readLines(file)) do
			local code = stripComment(line)

			for _, pair in ipairs(patterns) do
				if code:find(pair[1], 1, true) and code:find(pair[2], 1, true) and not (file == RSF_PATH and n >= from and n <= to) then
					bad[#bad + 1] = file:sub(#H.SCRIPTS + 1) .. ":" .. n .. ": " .. code
				end
			end
		end
	end

	pipe:close()
	table.sort(bad)
	lu.assertEquals(bad, {}, "type/name pairs of a deleted duty outside the LEGACY_TIER2_DUTIES block")
end

---------------------------------------------------------------------------------------------
-- AC-3: the points
---------------------------------------------------------------------------------------------

TestRsfTier2DutyPoints = {}

function TestRsfTier2DutyPoints:setUp() H.reset() end

-- AC-3, I-2
function TestRsfTier2DutyPoints:test_the_nine_duty_points_in_core3_equal_the_truncated_buildout_values()
	local navs = buildout()

	for _, name in ipairs(sortedKeys(D.POINTS)) do
		lu.assertNotNil(navs[name], name .. " is in the buildout extract")

		local p = point("space_naboo", name)

		lu.assertEquals({ p.x, p.z, p.y }, navs[name], "space_naboo: " .. name .. " x/z/y equal the truncated buildout fltPX/fltPY/fltPZ")
		lu.assertEquals({ p.x, p.z, p.y }, D.POINTS[name], "space_naboo: " .. name .. " x/z/y equal the spec's Source inventory")
	end
end

-- AC-3, I-2: every point the three tables name resolves with the inlined coordinates, and they are the nine, in 12 uses
function TestRsfTier2DutyPoints:test_every_point_the_three_tables_use_resolves_with_its_inlined_coordinates()
	local navs = buildout()
	local seen, uses = {}, 0

	local function walk(global, q, value, path, visited)
		if type(value) ~= "table" or visited[value] then
			return
		end

		visited[value] = true

		if value.patrolPointName ~= nil then
			local p = point(value.zoneName or q.questZone, value.patrolPointName)

			uses = uses + 1
			lu.assertEquals({ value.x, value.z, value.y }, { p.x, p.z, p.y }, global .. ": " .. path .. " (" .. value.patrolPointName .. ") coordinates equal space_naboo.lua")
			lu.assertEquals({ value.x, value.z, value.y }, navs[value.patrolPointName], global .. ": " .. path .. " (" .. value.patrolPointName .. ") coordinates equal the truncated buildout")
			seen[value.patrolPointName] = true
		end

		for k, v in pairs(value) do
			walk(global, q, v, path .. "." .. tostring(k), visited)
		end
	end

	for _, global in ipairs(D.GLOBALS) do
		walk(global, quest(global), quest(global), "", {})
	end

	lu.assertEquals(sortedKeys(seen), sortedKeys(D.POINTS), "distinct patrol points named by the three tables")
	lu.assertEquals(uses, 12, "point uses in the three tables (4 escort + 5 pre-recovery + 3 recovery)")
end

-- AC-3, Content contract 6
function TestRsfTier2DutyPoints:test_none_of_the_eleven_invented_points_is_defined_or_named_in_the_file()
	local points = H.patrolPoints("space_naboo")
	local text = readFile(PP_PATH)

	for _, name in ipairs(D.INVENTED) do
		lu.assertNil(points[name], "space_naboo: " .. name .. " is still defined")
		lu.assertNil(text:find(name, 1, true), "space_naboo.lua still mentions " .. name)
	end

	lu.assertEquals(#D.INVENTED, 11, "invented points listed by the spec")
end

-- AC-3, Content contract 6: the four comment lines of the deleted block are gone
function TestRsfTier2DutyPoints:test_the_four_comment_lines_of_the_deleted_block_are_gone()
	local text = readFile(PP_PATH)

	for _, comment in ipairs(D.PP_COMMENTS) do
		lu.assertNil(text:find(comment, 1, true), "space_naboo.lua still has the comment '" .. comment .. "'")
	end
end

-- AC-3: the neighbours stay
function TestRsfTier2DutyPoints:test_privateer_escort_4_and_the_registration_call_remain()
	local text = readFile(PP_PATH)

	lu.assertNil(H.patrolPoints("space_naboo").privateer_escort_4, "privateer_escort_4 is gone (rsf-tier1-dinge-data)")
	lu.assertNil(H.patrolPoints("space_naboo").privateer_escort_1, "privateer_escort_1 is gone (rsf-tier1-dinge-data)")
	lu.assertNotNil(text:find("SpacePatrolPoints:addSpacePatrolPoints(space_naboo, \"space_naboo\")", 1, true), "addSpacePatrolPoints call")
	lu.assertNil(text:find("-- RSF Tier 1 Mission 3: Escort Freighter", 1, true), "the comment of the tier 1 escort block is gone (rsf-tier1-dinge-data)")
end

-- AC-3: no loaded quest global mentions an invented point at any depth
function TestRsfTier2DutyPoints:test_no_loaded_quest_global_contains_an_invented_point_name_at_any_depth()
	local set = {}

	for _, name in ipairs(D.INVENTED) do
		set[name] = true
	end

	local hits = {}

	local function walk(value, path, visited)
		if type(value) == "string" then
			if set[value] then
				hits[#hits + 1] = path .. " = " .. value
			end
		elseif type(value) == "table" and not visited[value] then
			visited[value] = true

			for k, v in pairs(value) do
				walk(v, path .. "." .. tostring(k), visited)
			end
		end
	end

	for _, name in ipairs(H.questGlobals()) do
		walk(rawget(_G, name), name, {})
	end

	table.sort(hits)
	lu.assertEquals(hits, {}, "invented duty point names in loaded quest globals")
end
