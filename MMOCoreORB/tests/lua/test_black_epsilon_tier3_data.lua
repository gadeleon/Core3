-- Black Epsilon tier 3 (Haymir Rendundi): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7, I-11; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of black_epsilon_tier3_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local Swgjava = require("harness.swgjava")

T.load()

local function quest(global) return T.quest(global) end

local function fixtureOf(global)
	local id = T.IDENTITY[global]

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

local function attackLists(rec)
	local lists = {}

	for i = 1, rec:num("numAttackShipLists") do
		lists[i] = rec:list("attackShips" .. i)
	end

	return lists
end

local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

-- zone -> { nav = name -> {x, z, y, forward}, spawner = name -> {x, z, y}, rows = n } from the buildout extract of this feature
local function extract(zone)
	local out = { nav = {}, spawner = {}, rows = 0 }

	for _, rec in ipairs(H.fixture("space_zones/buildout/" .. zone .. ".black_epsilon_tier3_points.tab").records) do
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

	local f = io.open(path, "r")
	local src = f:read("a")

	f:close()
	return (src:gsub("%-%-[^\n]*", ""))
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Fixtures = {}

function TestBlackEpsilonT3Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the fourteen fixtures carry the values the spec lists
function TestBlackEpsilonT3Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = fixtureOf(T.M1[1])

	lu.assertEquals({ #p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:num("triggerEndsMission"), p1:get("triggerArg"), p1:get("questZone") },
		{ 4, 3, 20, 1, "inspect:corellia_imperial_tier3_1_a", "space_yavin4" }, "patrol/corellia_imperial_tier3_1")

	local i1 = fixtureOf(T.M1[2])

	lu.assertEquals({ i1:list("shipList"), i1:list("validSpawns"), i1:num("giveSpawnWaypoint"), i1:get("cargo"), i1:get("triggerArg") },
		{ { "reb_yavinspy_tier4" }, { "space_yavin4:corellia_imperial_tier3_officerinspect" }, 1, "joint_operations_plans", "delivery_no_pickup:corellia_imperial_tier3_1_b" },
		"inspect/corellia_imperial_tier3_1_a")

	local d1 = fixtureOf(T.M1[3])

	lu.assertEquals({ d1:get("deliveryShip"), d1:list("deliveryPoint"), d1:num("attackPeriod"), d1:get("attackListType"), d1:get("triggerArg") },
		{ "imp_lambda_shuttle_tier3", { "space_yavin4:naboo_imperial_tier3_delivery1_dropoff" }, 90, "sequential", "recovery:corellia_imperial_tier3_1_c" },
		"delivery_no_pickup/corellia_imperial_tier3_1_b")

	local r1 = fixtureOf(T.M1[4])

	lu.assertEquals({ r1:get("targetShipType"), r1:num("targetArrivalDelay"), r1:num("targetRecoverTime"), #r1:list("targetEscort"), r1:get("triggerEvent") },
		{ "reb_ywingleader_tier4", 20, 15, 4, "none" }, "recovery/corellia_imperial_tier3_1_c")

	local r2 = fixtureOf(T.M2[1])

	lu.assertEquals({ r2:get("targetShipType"), r2:num("targetArrivalDelay"), r2:num("targetRecoverTime"), r2:num("numAttackShipLists"), r2:get("attackListType"), r2:get("triggerArg") },
		{ "huttsmuggler_tier3", 15, 30, 3, "random", "survival:corellia_imperial_tier3_2_a" }, "recovery/corellia_imperial_tier3_2")

	local s2 = fixtureOf(T.M2[2])

	lu.assertEquals({ s2:num("totalTransmissionTime"), s2:num("timesToUpdateProgress"), s2:num("transmissionStartDelay"), s2:num("delayToFirstAttack"), s2:num("attackPeriod") },
		{ 300, 10, 25, 45, 90 }, "survival/corellia_imperial_tier3_2_a")

	local e2 = fixtureOf(T.M2[3])

	lu.assertEquals({ e2:list("escortShipType"), #e2:list("escortPath"), e2:num("numResponses"), e2:get("triggerArg") },
		{ { "imp_huttsmuggler_tier3" }, 4, 5, "space_battle:corellia_imperial_tier3_2_c" }, "escort/corellia_imperial_tier3_2_b")

	local b2 = fixtureOf(T.M2[4])

	lu.assertEquals({ b2:num("damageMultiplier"), b2:num("allyArrivalDelay"), b2:num("enemyArrivalDelay"), b2:num("allyOriginDist"), b2:num("enemyOriginDist"), b2:num("allyArrivalDist"),
		b2:num("enemyArrivalDist"), #b2:list("allyForce"), #b2:list("enemyForce") }, { 5, 30, 90, 400, -400, 200, 300, 4, 8 }, "space_battle/corellia_imperial_tier3_2_c")

	local r3 = fixtureOf(T.M3[1])

	lu.assertEquals({ r3:get("targetShipType"), r3:num("targetArrivalDelay"), #r3:list("recoveryPath"), r3:num("numAttackShipLists"), r3:num("numResponses"), r3:get("triggerArg") },
		{ "imp_freightermedium_tier3", 15, 4, 2, 5, "assassinate:corellia_imperial_tier3_3_a" }, "rescue/corellia_imperial_tier3_3")

	for _, c in ipairs({ { T.M3[2], "reb_emissary_tier4", 7, 1 }, { T.M4[2], "nym_patrol_craft_tier4", 5, 0 }, { T.M4[4], "nym_karthakk_queen_tier4", 5, 1 } }) do
		local a = fixtureOf(c[1])

		lu.assertEquals({ a:get("targetShipType"), a:num("targetArrivalDelay"), #a:list("targetEscort"), a:num("mustDestroyEscort") }, { c[2], 20, c[3], c[4] }, "assassinate fixture " .. c[1])
	end

	local r4 = fixtureOf(T.M4[1])

	lu.assertEquals({ r4:get("questZone"), r4:get("targetShipType"), r4:num("targetRecoverTime"), #r4:list("targetEscort"), r4:num("attackPeriod"), r4:get("triggerArg") },
		{ "space_lok", "nym_smuggle_transport_capture_tier4", 30, 7, 120, "assassinate:corellia_imperial_tier3_4_a" }, "recovery/corellia_imperial_tier3_4")

	local s4 = fixtureOf(T.M4[3])

	lu.assertEquals({ s4:num("totalTransmissionTime"), s4:num("timesToUpdateProgress"), s4:num("attackPeriod"), s4:get("triggerArg") },
		{ 600, 20, 120, "assassinate:corellia_imperial_tier3_4_c" }, "survival/corellia_imperial_tier3_4_b")
end

-- I-2 (the oracle itself): the spec's point literals are what the patrol point files and the buildout extracts hold
function TestBlackEpsilonT3Fixtures:test_the_spec_points_equal_the_core3_point_files_and_the_buildout_extracts()
	local total = 0

	for zone, points in pairs(T.POINTS) do
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

	lu.assertEquals(total, 42, "spec points (30 in space_yavin4, 12 in space_lok)")

	local s = H.spawners("space_yavin4")[T.SPAWNER.name]

	lu.assertNotNil(s, "space_yavin4 spawner " .. T.SPAWNER.name)
	lu.assertEquals({ s.x, s.z, s.y }, { T.SPAWNER.x, T.SPAWNER.z, T.SPAWNER.y }, "space_yavin4 spawner " .. T.SPAWNER.name)

	local row = extract("space_yavin4").spawner[T.SPAWNER.name]

	lu.assertEquals(row and { row.x, row.z, row.y }, { T.SPAWNER.x, T.SPAWNER.z, T.SPAWNER.y }, "space_yavin4 buildout extract: spawner row")
	lu.assertEquals(extract("space_yavin4").rows, 31, "rows of the space_yavin4 extract (30 nav points and the spawner)")
	lu.assertEquals(extract("space_lok").rows, 12, "rows of the space_lok extract")
end

-- AC-2 (the oracle itself): the battle forward axis
function TestBlackEpsilonT3Fixtures:test_the_battle_forward_axis_is_the_buildout_k_axis()
	local row = extract("space_yavin4").nav.corellia_imperial_tier3_leg_2_space_battle

	lu.assertEquals(row.forward, T.FORWARD, "fltKX, fltKY, fltKZ of the battle point")
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script
function TestBlackEpsilonT3Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_imperial_tier3.java")

	lu.assertNotNil(java, "fixtures/script/conversation/corellia_imperial_tier3.java")

	local found = {}

	for questType, questName, credits, path in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		found[questType .. "_" .. questName] = { tonumber(credits), path }
	end

	lu.assertEquals(found.patrol_corellia_imperial_tier3_1, { T.CREDITS, T.ITEMS[1] }, "J giveReward 1")
	lu.assertEquals(found.recovery_corellia_imperial_tier3_2, { T.CREDITS, T.ITEMS[2] }, "J giveReward 2")
	lu.assertEquals(found.rescue_corellia_imperial_tier3_3, { T.CREDITS, T.ITEMS[3] }, "J giveReward 3")
	lu.assertEquals(found.recovery_corellia_imperial_tier3_4, { T.CREDITS, T.ITEMS[4] }, "J giveReward 4")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 100%.0f%)"), 4, "J: +100 Imperial standing, once per reward")
	lu.assertEquals(countMatches(java, 'noisyGrantSkill%(player, "pilot_imperial_navy_%a+_03"%)'), 4, "J: the four tier 3 skills are granted by noisyGrantSkill (no XP)")
end

-- AC-5 (the oracle itself): the answer key parses
function TestBlackEpsilonT3Fixtures:test_the_swg_script_parses_the_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_tier3.java")

	lu.assertTrue(#graph.order >= 70, "NPC lines parsed from corellia_imperial_tier3.java: " .. #graph.order)
end

-- I-11 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo
function TestBlackEpsilonT3Fixtures:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local mob = H.fixture("space_mobile/space_mobile.reb_yavinspy_tier4.tab").records[1]
	local rows = H.fixture("spacequest/inspect_cargo/joint_operations_plan.tab").records

	lu.assertEquals(mob:get("strIndex"), "reb_yavinspy_tier4", "the excerpt row is the spy ship")
	lu.assertEquals(mob:get("cargo"), "joint_operations_plan", "space_mobile.tab cargo column (names the inspect_cargo table)")
	lu.assertEquals(#rows, 1, "joint_operations_plan.tab rows")
	lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { "joint_operations_plans", 1 }, "joint_operations_plan.tab row")
	lu.assertEquals(fixtureOf(T.M1[2]):get("cargo"), rows[1]:get("name"), "the inspect quest cargo is that row")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Wiring = {}

function TestBlackEpsilonT3Wiring:setUp() H.reset() end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_squadron_file_registers_the_fourteen_tier_3_quests_with_start_true()
	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#T.GLOBALS, 14, "tier 3 globals")
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_nineteen_tier_1_and_2_quests_are_still_registered()
	for _, global in ipairs(T.OLDER_GLOBALS) do
		H.expectGlobal(global, "tier 1/2 quest table")
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#T.OLDER_GLOBALS, 19, "tier 1-2 globals")
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_squadron_screenplay_has_the_tier_3_constants_and_the_reset()
	local sq = H.expectGlobal("BlackEpsilonSquadronScreenplay", "squadron screenplay object")

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "BlackEpsilonSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "corellia_imperial_1" }, "tier 1 QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.TIER2_QUEST_STRING_1, { type = "assassinate", name = "corellia_imperial_12" }, "tier 2 TIER2_QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.SERIES_COMPLETE_KEY, T.SERIES_SUFFIX, "SERIES_COMPLETE_KEY is unchanged")
	lu.assertEquals(type(sq.resetPriskQuests), "function", "resetPriskQuests")
	lu.assertEquals(type(sq.resetHaymirQuests), "function", "BlackEpsilonSquadronScreenplay:resetHaymirQuests")
	lu.assertEquals(pcall(sq.resetHaymirQuests, sq, nil), true, "resetHaymirQuests(nil) returns early")
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	T.requireConversation(lu)

	local t = H.conversationTemplateTable(T.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, T.HANDLER, T.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", T.TEMPLATE .. ": templateType")

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isOnMission", "getRewardMission" }) do
		lu.assertEquals(type(rawget(_G, T.HANDLER)[fn]), "function", T.HANDLER .. ":" .. fn)
	end
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_haymir_rendundi_uses_the_template_and_has_the_conversable_mask()
	local npc = H.loadCreatureTemplate("space/haymir_rendundi.lua", "haymir_rendundi")

	lu.assertNotNil(npc, "mobile/space/haymir_rendundi.lua registers haymir_rendundi")
	lu.assertEquals(npc.conversationTemplate, "haymir_convo_template", "haymir_rendundi: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "haymir_rendundi: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "haymir_rendundi: optionsBitmask (Hakassha's and Prisk's mask)")
end

local function linesOf(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_template_include_line_follows_the_prisk_include_exactly_once_under_the_black_epsilon_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/black_epsilon_squadron/haymir_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented haymir_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented haymir_convo include")

	local comment = text:find("-- Black Epsilon Squadron", 1, true)
	local include = text:find("conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua", 1, true)
	local nextComment = text:find("-- Imperial Inquisition Squadron", comment or 1, true)

	lu.assertTrue(comment ~= nil and include ~= nil and include > comment and include < nextComment, "space_conversations.lua: the include sits under '-- Black Epsilon Squadron'")

	local lines, at = linesOf(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the prisk_convo include")
	lu.assertEquals(lines[at + 1] and lines[at + 1]:match("^%s*(.-)%s*$"), 'includeFile("conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua")',
		"space_conversations.lua: the haymir_convo include directly after the prisk_convo include")
end

-- AC-1
function TestBlackEpsilonT3Wiring:test_the_handler_include_line_follows_the_prisk_handler_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented haymirConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented haymirConvoHandler include")

	local lines, squadron, hakassha, prisk = linesOf(text), nil, nil, nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/BlackEpsilonSquadronScreenplay.lua")', 1, true) then
			squadron = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua")', 1, true) then
			hakassha = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua")', 1, true) then
			prisk = i
		end
	end

	lu.assertNotNil(squadron, "screenplays.lua: the BlackEpsilonSquadronScreenplay include")
	lu.assertEquals(hakassha, squadron + 2, "screenplays.lua: the Hakassha handler include stays 2 lines after the squadron include (tier 1 pin)")
	lu.assertEquals(prisk, hakassha + 1, "screenplays.lua: the Prisk handler include stays directly after Hakassha's (tier 2 pin)")
	lu.assertEquals(lines[prisk + 1], 'includeFile("space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler.lua")',
		"screenplays.lua: the Haymir handler include, directly after the Prisk one, no blank line")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Tables = {}

function TestBlackEpsilonT3Tables:setUp() H.reset() end

-- AC-2, I-1
function TestBlackEpsilonT3Tables:test_the_fourteen_tables_keep_their_identity_and_zone()
	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local id = T.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestBlackEpsilonT3Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = T.expected()

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2, I-6: split wiring
function TestBlackEpsilonT3Tables:test_exactly_the_ten_non_end_tables_split_and_name_the_next_chain_member()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local ends = { [T.M1[4]] = true, [T.M2[4]] = true, [T.M3[2]] = true, [T.M4[4]] = true }
	local splits = 0

	for _, chain in ipairs(T.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)

			lu.assertEquals(q.sideQuest and true or false, ends[global] == nil, global .. ": sideQuest")

			if ends[global] then
				lu.assertEquals(q.sideQuestType, "", global .. ": the chain end has no split type")
			else
				splits = splits + 1

				local nextId = T.IDENTITY[chain[i + 1]]

				lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { nextId.type, nextId.name }, global .. ": sideQuestType, sideQuestName")

				if global == T.M1[1] then
					lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, global .. ": PATROL_POINT")
					lu.assertEquals({ q.sideQuestPatrolStart, q.sideQuestDelay }, { 3, 20 }, global .. ": sideQuestPatrolStart, sideQuestDelay (the .tab triggerOn 3, triggerDelay 20)")
				else
					lu.assertEquals(q.sideQuestSplitType, COMPLETION, global .. ": COMPLETION (triggerSplitCondition success)")
					lu.assertEquals(q.sideQuestDelay, 5, global .. ": sideQuestDelay (triggerDelay 0 + 5)")
				end
			end

			if i > 1 then
				local pid = T.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splits, 10, "split tables")
end

-- AC-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order
function TestBlackEpsilonT3Tables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(T.CHAINS) do
		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #T.M1, #T.M2, #T.M3, #T.M4 }, { 4, 4, 2, 4 }, "chain lengths (4, 4, 2, 4)")
end

-- AC-2, I-5: credits and items only on the four heads
function TestBlackEpsilonT3Tables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local items = { [T.M1[1]] = T.ITEMS[1], [T.M2[1]] = T.ITEMS[2], [T.M3[1]] = T.ITEMS[3], [T.M4[1]] = T.ITEMS[4] }

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		if items[global] then
			lu.assertEquals(rawget(q, "creditReward"), 25000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = items[global] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template
function TestBlackEpsilonT3Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "attackShipLists", "allyForce", "enemyForce" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "deliveryShip", "targetShipType" }) do
			if rawget(q, field) then
				ships[q[field]] = true
			end
		end

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end

		if rawget(q, "assassinateSpawns") then
			ships[q.assassinateSpawns.target] = true
			walk(q.assassinateSpawns.escorts, ships)
		end
	end

	lu.assertEquals(#sortedKeys(ships), 26, "distinct ships in the 14 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 14 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestBlackEpsilonT3Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(T.GLOBALS) do
		local id = T.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Conformance = {}

function TestBlackEpsilonT3Conformance:setUp() H.reset() end

local function label(global) return T.IDENTITY[global].type .. "/" .. T.IDENTITY[global].name end

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

-- AC-2, I-4: every quest: zone, split target and delay from triggerArg
function TestBlackEpsilonT3Conformance:test_every_table_takes_zone_and_split_target_from_its_fixture()
	for _, global in ipairs(T.GLOBALS) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")

		if rec:get("triggerEvent") == "splitquest" then
			local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

			lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName }, { true, splitType, splitName }, l .. ": sideQuest, sideQuestType, sideQuestName (triggerArg)")

			if rec:get("triggerSplitCondition") == "success" then
				lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, l .. ": COMPLETION")
				lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, l .. ": sideQuestDelay (triggerDelay + 5)")
			else
				lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, l .. ": PATROL_POINT (triggerOn)")
				lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
				lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), l .. ": sideQuestDelay (triggerDelay)")
			end
		else
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

-- AC-2, I-2, I-4: patrol 1
function TestBlackEpsilonT3Conformance:test_patrol_1_maps_the_four_points_in_file_order()
	local q, rec = quest(T.M1[1]), fixtureOf(T.M1[1])

	lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), label(T.M1[1]) .. ": patrolPoints (navPoints)")
end

-- AC-2, I-2, I-4: inspect 1_a
function TestBlackEpsilonT3Conformance:test_inspect_1_a_maps_ship_spawner_waypoint_flag_and_cargo()
	local q, rec = quest(T.M1[2]), fixtureOf(T.M1[2])
	local l = label(T.M1[2])
	local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
	local s = H.spawners(zone)[spawnName]

	lu.assertNotNil(s, l .. ": spawner " .. spawnName)
	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
end

-- AC-2, I-2, I-4: delivery 1_b
function TestBlackEpsilonT3Conformance:test_delivery_1_b_maps_ship_point_attack_lists_period_and_order()
	local q, rec = quest(T.M1[3]), fixtureOf(T.M1[3])
	local l = label(T.M1[3])

	lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
	lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- AC-2, I-2, I-4: the three recoveries
function TestBlackEpsilonT3Conformance:test_recoveries_map_ships_paths_attack_lists_and_taunts_from_their_fixtures()
	for _, global in ipairs({ T.M1[4], T.M2[1], T.M4[1] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local radius = function(i) return { escortNumber = i, radius = 250 } end

		lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
		lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
		lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", radius), l .. ": preRecoveryPoints (escortPath, no zoneName)")
		lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints (recoveryPath, no zoneName)")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
		lu.assertNil(rawget(q, "recoveryConversationMobile"), l .. ": recoveryConversationMobile stays the type default")
	end

	lu.assertEquals(#quest(T.M2[1]).attackShips, 3, "recovery_corellia_imperial_tier3_2: three attack lists (its .tab attackListType random becomes the in-order cycle)")
end

-- AC-2, I-2, I-4: survival 2_a and 4_b
function TestBlackEpsilonT3Conformance:test_survivals_map_point_timers_attack_lists_and_order_from_their_fixtures()
	for _, global in ipairs({ T.M2[2], T.M4[3] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
		lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
		lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
		lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
		lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
		lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
		lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..2, column-wise)")
		lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
		lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	end

	lu.assertEquals(quest(T.M4[3]).transmissionPoint.x, -4511, "the Lok survival point is the Lok one, not the Yavin 4 point of the same name")
end

-- AC-2, I-2, I-4: escort 2_b
function TestBlackEpsilonT3Conformance:test_escort_2_b_maps_ship_path_with_swgs_spelling_attack_list_and_taunts()
	local q, rec = quest(T.M2[3]), fixtureOf(T.M2[3])
	local l = label(T.M2[3])

	lu.assertEquals(q.escortShips, rec:list("escortShipType"), l .. ": escortShips (escortShipType)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPath)")
	lu.assertEquals(q.escortPoints[3].patrolPointName, "corellis_imperial_tier3_leg_2_rescue_3", l .. ": SWG's own spelling is kept (D-11)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: battle 2_c
function TestBlackEpsilonT3Conformance:test_battle_2_c_maps_point_forward_timers_distances_and_forces()
	local q, rec = quest(T.M2[4]), fixtureOf(T.M2[4])
	local l = label(T.M2[4])
	local zone, name = H.Tab.splitNavPoint(rec:list("battlePoint")[1])
	local row = extract(zone).nav[name]

	lu.assertNotNil(row, l .. ": buildout extract row of " .. name)
	lu.assertEquals(q.battlePoint, { patrolPointName = name, x = row.x, z = row.z, y = row.y, forward = row.forward }, l .. ": battlePoint (nav point + fltKX/fltKY/fltKZ as forward x/z/y)")

	for field, column in pairs({ damageMultiplier = "damageMultiplier", allyArrivalDelay = "allyArrivalDelay", enemyArrivalDelay = "enemyArrivalDelay", allyOriginDist = "allyOriginDist",
		enemyOriginDist = "enemyOriginDist", allyArrivalDist = "allyArrivalDist", enemyArrivalDist = "enemyArrivalDist" }) do
		lu.assertEquals(q[field], rec:num(column), l .. ": " .. field)
	end

	lu.assertEquals(q.allyForce, rec:list("allyForce"), l .. ": allyForce")
	lu.assertEquals(q.enemyForce, rec:list("enemyForce"), l .. ": enemyForce")
end

-- AC-2, I-2, I-4: rescue 3
function TestBlackEpsilonT3Conformance:test_rescue_3_maps_path_target_attack_lists_and_responses()
	local q, rec = quest(T.M3[1]), fixtureOf(T.M3[1])
	local l = label(T.M3[1])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
end

-- AC-2, I-2, I-4: the three assassinates
function TestBlackEpsilonT3Conformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ T.M3[2], T.M4[2], T.M4[4] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals(quest(T.M4[4]).targetPatrols[1].patrolPointName, "corellia_tier3_assassinate2_1", "SWG's own name is kept (D-11)")
	lu.assertEquals(quest(T.M4[4]).targetPatrols[1].x, 2767, "the Lok point, not the Yavin 4 point of the same name")
end

---------------------------------------------------------------------------------------------
-- I-11: the inspect cargo, read from the REAL ship template file (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Cargo = {}

function TestBlackEpsilonT3Cargo:setUp() H.reset() end

-- AC-2, I-11
function TestBlackEpsilonT3Cargo:test_the_spy_ship_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	local q = quest(T.M1[2])

	lu.assertEquals(q.shipList, { "reb_yavinspy_tier4" }, "inspect 1_a shipList")

	for _, ship in ipairs(q.shipList) do
		local src = templateSource(ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, ship .. ".lua cargoString must equal the quest cargo")
		lu.assertEquals(questLoot, "joint_operations_plan", ship .. ".lua questLoot (names the inspect_cargo table)")

		local rows = H.fixture("spacequest/inspect_cargo/" .. questLoot .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. questLoot .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { q.cargo, 1 }, ship .. ": cargo is the canTransfer = 1 row of the table")
	end
end

-- AC-2, I-11: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestBlackEpsilonT3Cargo:test_the_loaded_spy_ship_template_has_the_cargo_string()
	local t = H.shipTemplate("reb_yavinspy_tier4")

	lu.assertNotNil(t, "ship_mobile/ships/reb_yavinspy_tier4.lua registers a template")
	lu.assertEquals(t.cargoString, "joint_operations_plans", "reb_yavinspy_tier4: cargoString")
	lu.assertEquals(t.questLoot, "joint_operations_plan", "reb_yavinspy_tier4: questLoot is unchanged")
	lu.assertEquals(t.template, "awing_tier4", "reb_yavinspy_tier4: template is unchanged")
	lu.assertEquals(t.pilotTemplate, "light_fighter_tier4", "reb_yavinspy_tier4: pilotTemplate is unchanged")
end
