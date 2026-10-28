-- Black Epsilon tier 4 (Nin Gursawe): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7, I-11; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of black_epsilon_tier4_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local Swgjava = require("harness.swgjava")

T.load()

local function quest(global) return T.quest(global) end

local function fixtureOf(global) return T.fixtureOf(global) end

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

local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

-- zone -> { nav = name -> {x, z, y, forward}, spawner = name -> {x, z, y}, rows = n } from the buildout extract of this feature
local function extract(zone)
	local out = { nav = {}, spawner = {}, rows = 0 }

	for _, rec in ipairs(H.fixture("space_zones/buildout/" .. zone .. ".black_epsilon_tier4_points.tab").records) do
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

local function linesOf(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Fixtures = {}

function TestBlackEpsilonT4Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the fixtures carry the values the spec lists
function TestBlackEpsilonT4Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = fixtureOf(T.M1[1])

	lu.assertEquals({ #p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg"), p1:get("questZone") },
		{ 4, 3, 25, "inspect:corellia_imperial_tier4_1_a", "space_dantooine" }, "patrol/corellia_imperial_tier4_1")

	local p3 = fixtureOf(T.M3[3])

	lu.assertEquals({ #p3:list("navPoints"), p3:num("triggerOn"), p3:num("triggerDelay"), p3:get("triggerArg"), p3:get("questZone") },
		{ 4, 3, 20, "inspect:corellia_imperial_tier4_3_c", "space_dathomir" }, "patrol/corellia_imperial_tier4_3_b")

	for _, c in ipairs(T.INSPECTS) do
		local i = fixtureOf(c.global)

		lu.assertEquals({ i:list("shipList"), i:list("validSpawns"), i:num("giveSpawnWaypoint"), i:get("cargo") },
			{ { c.ship }, { c.spawner.zone .. ":" .. c.spawner.name }, 1, c.cargo }, "inspect fixture " .. c.global)
	end

	local s1 = fixtureOf(T.M1[3])

	lu.assertEquals({ s1:num("totalTransmissionTime"), s1:num("timesToUpdateProgress"), s1:num("transmissionStartDelay"), s1:num("delayToFirstAttack"), s1:num("attackPeriod"), s1:get("attackListType") },
		{ 600, 20, 30, 45, 100, "sequential" }, "survival/corellia_imperial_tier4_1_b")

	local r2 = fixtureOf(T.M2[1])

	lu.assertEquals({ r2:get("targetShipType"), r2:num("targetArrivalDelay"), r2:num("targetRecoverTime"), #r2:list("targetEscort"), r2:num("attackPeriod"), r2:num("numResponses") },
		{ "deserted_freighter_tier4", 15, 30, 0, 120, 5 }, "recovery/corellia_imperial_tier4_2")

	local d2 = fixtureOf(T.M2[3])

	lu.assertEquals({ d2:get("deliveryShip"), d2:list("deliveryPoint"), d2:num("attackPeriod"), d2:get("attackListType") },
		{ "imp_lambda_shuttle_tier4", { "space_dantooine:corellia_imperial_tier4_delivery1" }, 90, "sequential" }, "delivery_no_pickup/corellia_imperial_tier4_2_b")

	local e3 = fixtureOf(T.M3[1])

	lu.assertEquals({ e3:list("escortShipType"), #e3:list("escortPath"), e3:num("numResponses"), e3:num("attackPeriod") },
		{ { "imperial_drop_ship_tier4" }, 5, 0, 120 }, "escort/corellia_imperial_tier4_3 (numResponses 0: D-12)")

	local r3 = fixtureOf(T.M3[2])

	lu.assertEquals({ r3:get("targetShipType"), r3:num("targetArrivalDelay"), #r3:list("recoveryPath"), r3:num("numResponses"), r3:num("attackPeriod") },
		{ "imperial_drop_ship_tier4", 0, 4, 5, 120 }, "rescue/corellia_imperial_tier4_3_a")

	local a4 = fixtureOf(T.M4[1])

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("targetEscort"), a4:num("mustDestroyEscort"), #a4:list("escortPath") },
		{ "neja_bertolo_tier5", 30, 7, 1, 4 }, "assassinate/corellia_imperial_tier4_4")

	local r4 = fixtureOf(T.M4[2])

	lu.assertEquals({ r4:get("targetShipType"), r4:num("targetArrivalDelay"), r4:num("targetRecoverTime"), #r4:list("targetEscort"), r4:num("attackPeriod"), r4:get("attackListType") },
		{ "velocity_smuggler_tier4", 10, 30, 7, 120, "random" }, "recovery/corellia_imperial_tier4_4_a")

	local u4 = fixtureOf(T.M4[3])

	lu.assertEquals({ u4:get("shipType"), u4:num("shipCount"), u4:num("triggerDelay"), u4:get("triggerArg") },
		{ "velocity_merc_heavy_fighter_tier4", 8, 5, "space_battle:corellia_imperial_tier4_4_c" }, "destroy_surpriseattack/corellia_imperial_tier4_4_b")

	local b4 = fixtureOf(T.M4[4])

	lu.assertEquals({ b4:num("damageMultiplier"), b4:num("allyArrivalDelay"), b4:num("enemyArrivalDelay"), b4:num("allyOriginDist"), b4:num("enemyOriginDist"), b4:num("allyArrivalDist"),
		b4:num("enemyArrivalDist"), #b4:list("allyForce"), #b4:list("enemyForce") }, { 4, 30, 90, 400, -400, 300, 300, 5, 11 }, "space_battle/corellia_imperial_tier4_4_c")

	local d4 = fixtureOf(T.M4[5])

	lu.assertEquals({ d4:get("targetShipType"), d4:num("targetArrivalDelay"), #d4:list("targetEscort"), d4:num("mustDestroyEscort"), #d4:list("escortPath") },
		{ "onli_shien_tier5", 15, 9, 1, 3 }, "assassinate/corellia_imperial_tier4_4_d")

	local du1 = fixtureOf(T.DUTIES[1])

	lu.assertEquals({ du1:num("wavesPerRound"), du1:num("roundsPerLevel"), du1:num("levelsPerDuty"), du1:get("bossType"), du1:num("reward") },
		{ 3, 5, 8, "velocity_merc_captain_tier5", 300 }, "destroy_duty/corellia_imperial_tier4_1")

	for _, g in ipairs({ T.DUTIES[2], T.DUTIES[3], T.DUTIES[4] }) do
		local d = fixtureOf(g)

		lu.assertEquals({ d:num("reward"), d:num("killReward"), d:num("numResponses"), d:num("attackPeriod") }, { 5000, 300, 5, 120 }, "duty fixture " .. g)
	end
end

-- Appendix B (the oracle itself): the attack list sizes
function TestBlackEpsilonT4Fixtures:test_the_attack_lists_have_the_sizes_appendix_b_lists()
	for global, want in pairs(T.LIST_SIZES) do
		local rec, got = fixtureOf(global), {}
		local n = rec:num("numAttackShipLists") or 4
		local column = global:match("^destroy_duty") and "shipType" or "attackShips"

		for i = 1, n do
			got[i] = #rec:list(column .. i)
		end

		lu.assertEquals(got, want, global .. ": attack list sizes")
	end
end

-- I-2 (the oracle itself): the spec's point literals are what the patrol point files and the buildout extracts hold
function TestBlackEpsilonT4Fixtures:test_the_spec_points_equal_the_core3_point_files_and_the_buildout_extracts()
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

	lu.assertEquals(total, 53, "spec points (27 in space_dantooine: 12 story + 15 duty, 26 in space_dathomir)")
	lu.assertEquals(extract("space_dantooine").rows, 29, "rows of the space_dantooine extract (27 nav points and 2 spawners)")
	lu.assertEquals(extract("space_dathomir").rows, 27, "rows of the space_dathomir extract (26 nav points and 1 spawner)")
end

-- I-2 (the oracle itself): the three inspect spawners
function TestBlackEpsilonT4Fixtures:test_the_spec_spawners_equal_the_core3_spawner_files_and_the_buildout_extracts()
	for _, sp in ipairs(T.SPAWNERS) do
		local s = H.spawners(sp.zone)[sp.name]

		lu.assertNotNil(s, sp.zone .. " spawner " .. sp.name)
		lu.assertEquals({ s.x, s.z, s.y }, { sp.x, sp.z, sp.y }, sp.zone .. " spawner " .. sp.name)

		local row = extract(sp.zone).spawner[sp.name]

		lu.assertEquals(row and { row.x, row.z, row.y }, { sp.x, sp.z, sp.y }, sp.zone .. " buildout extract: spawner row " .. sp.name)
	end
end

-- AC-2 (the oracle itself): the battle forward axis
function TestBlackEpsilonT4Fixtures:test_the_battle_forward_axis_is_the_buildout_k_axis()
	local row = extract("space_dathomir").nav.corellia_imperial_tier4_battle1

	lu.assertEquals(row.forward, T.FORWARD, "fltKX, fltKY, fltKZ of the battle point")
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script
function TestBlackEpsilonT4Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_imperial_tier4.java")

	lu.assertNotNil(java, "fixtures/script/conversation/corellia_imperial_tier4.java")

	local found = {}

	for questType, questName, credits, path in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		found[questType .. "_" .. questName] = { tonumber(credits), path }
	end

	lu.assertEquals(found.patrol_corellia_imperial_tier4_1, { T.CREDITS, T.ITEMS[1] }, "J giveReward 1")
	lu.assertEquals(found.recovery_corellia_imperial_tier4_2, { T.CREDITS, T.ITEMS[2] }, "J giveReward 2")
	lu.assertEquals(found.escort_corellia_imperial_tier4_3, { T.CREDITS, T.ITEMS[3] }, "J giveReward 3")
	lu.assertEquals(found.assassinate_corellia_imperial_tier4_4, { T.CREDITS, T.ITEMS[4] }, "J giveReward 4")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 150%.0f%)"), 4, "J: +150 Imperial standing, once per reward")
	lu.assertEquals(countMatches(java, 'skill%.purchaseSkill%(player, "pilot_imperial_navy_%a+_04"%)'), 4, "J: the four tier 4 skills are bought with purchaseSkill (XP charged)")
end

-- Correction 1 / D-2 (the oracle itself): J has no call site of the master mission or master grant
function TestBlackEpsilonT4Fixtures:test_the_swg_script_never_calls_the_master_mission_or_master_grant()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_imperial_tier4.java")

	for _, name in ipairs({ "grantMasterMission", "rewardForMasterMission", "failedMasterMission", "isGettingMasterMissionReward" }) do
		local calls = 0

		for line in java:gmatch("[^\n]+") do
			if line:find(name, 1, true) and not line:find("public ", 1, true) then
				calls = calls + 1
			end
		end

		lu.assertEquals(calls, 0, "call sites of " .. name .. " in corellia_imperial_tier4.java")
	end
end

-- AC-5 (the oracle itself): the answer key parses
function TestBlackEpsilonT4Fixtures:test_the_swg_script_parses_the_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_tier4.java")

	lu.assertEquals(#graph.order, 176, "NPC lines parsed from corellia_imperial_tier4.java")
end

-- the tier 4 skills fixture: 1,000,000 XP each, the four _03 skills required
function TestBlackEpsilonT4Fixtures:test_the_skills_fixture_prices_each_tier_4_skill_at_one_million_xp_and_requires_the_tier_3_skills()
	local rows = H.fixture("skill/skills.pilot_imperial_navy_04.tab").records
	local costs = T.useSkillCosts()

	lu.assertEquals(#rows, 4, "skills.pilot_imperial_navy_04.tab rows")

	for _, t in ipairs(T.TRAIN) do
		lu.assertEquals(costs[t.skill], 1000000, t.skill .. ": XP_COST")
	end

	for _, rec in ipairs(rows) do
		local req = rec:get("SKILLS_REQUIRED")

		for _, s in ipairs(T.TIER3_SKILLS) do
			lu.assertNotNil(req:find(s, 1, true), rec:get("NAME") .. " requires " .. s)
		end
	end
end

-- I-11 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo
function TestBlackEpsilonT4Fixtures:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local mobs = {}

	for _, rec in ipairs(H.fixture("space_mobile/space_mobile.corellia_imperial_tier4_inspect.tab").records) do
		mobs[rec:get("strIndex")] = rec:get("cargo")
	end

	for _, c in ipairs(T.INSPECTS) do
		local rows = H.fixture("spacequest/inspect_cargo/" .. c.cargo .. ".tab").records

		lu.assertEquals(mobs[c.ship], c.cargo, "space_mobile.tab cargo column of " .. c.ship)
		lu.assertEquals(#rows, 1, c.cargo .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { c.cargo, 1 }, c.cargo .. ".tab row")
		lu.assertEquals(fixtureOf(c.global):get("cargo"), rows[1]:get("name"), c.global .. ": the inspect quest cargo is that row")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Wiring = {}

function TestBlackEpsilonT4Wiring:setUp() H.reset() end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_squadron_file_registers_the_nineteen_tier_4_quests_with_start_true()
	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#T.GLOBALS, 19, "tier 4 globals")
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_thirty_three_tier_1_to_3_quests_are_still_registered()
	for _, global in ipairs(T.OLDER_GLOBALS) do
		H.expectGlobal(global, "tier 1-3 quest table")
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#T.OLDER_GLOBALS, 33, "tier 1-3 globals")
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_squadron_screenplay_has_the_tier_4_constants_and_the_reset()
	local sq = H.expectGlobal("BlackEpsilonSquadronScreenplay", "squadron screenplay object")

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "BlackEpsilonSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "corellia_imperial_1" }, "tier 1 QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.TIER2_QUEST_STRING_1, { type = "assassinate", name = "corellia_imperial_12" }, "tier 2 TIER2_QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.TIER3_QUEST_STRING_1, { type = "patrol", name = "corellia_imperial_tier3_1" }, "tier 3 TIER3_QUEST_STRING_1 is unchanged")
	lu.assertEquals(type(sq.resetHaymirQuests), "function", "resetHaymirQuests")
	lu.assertEquals(type(sq.resetNinGursaweQuests), "function", "BlackEpsilonSquadronScreenplay:resetNinGursaweQuests")
	lu.assertEquals(pcall(sq.resetNinGursaweQuests, sq, nil), true, "resetNinGursaweQuests(nil) returns early")
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	T.requireConversation(lu)

	local t = H.conversationTemplateTable(T.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, T.HANDLER, T.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", T.TEMPLATE .. ": templateType")

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isPaid", "isOnMission", "canFlyNonTrackDuty",
		"getNextMission", "getReadyMission", "isReadyForTraining" }) do
		lu.assertEquals(type(rawget(_G, T.HANDLER)[fn]), "function", T.HANDLER .. ":" .. fn)
	end
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_insurgent_uses_the_template_and_has_the_conversable_mask()
	-- insurgent.lua merges two attack groups of creatureskills.lua, which the harness does not load: empty ones stand in
	for _, group in ipairs({ "brawlermaster", "marksmanmaster" }) do
		if rawget(_G, group) == nil then
			rawset(_G, group, {})
		end
	end

	local npc = H.loadCreatureTemplate("space/insurgent.lua", "insurgent")

	lu.assertNotNil(npc, "mobile/space/insurgent.lua registers insurgent")
	lu.assertEquals(npc.conversationTemplate, "nin_gursawe_convo_template", "insurgent: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "insurgent: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "insurgent: optionsBitmask (Haymir's mask)")
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_template_include_line_follows_the_haymir_include_exactly_once_under_the_black_epsilon_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented nin_gursawe_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented nin_gursawe_convo include")

	local comment = text:find("-- Black Epsilon Squadron", 1, true)
	local include = text:find("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua", 1, true)
	local nextComment = text:find("-- Imperial Inquisition Squadron", comment or 1, true)

	lu.assertTrue(comment ~= nil and include ~= nil and include > comment and include < nextComment, "space_conversations.lua: the include sits under '-- Black Epsilon Squadron'")

	local lines, at = linesOf(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the haymir_convo include")
	lu.assertEquals(lines[at + 1] and lines[at + 1]:match("^%s*(.-)%s*$"), 'includeFile("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua")',
		"space_conversations.lua: the nin_gursawe_convo include directly after the haymir_convo include")
end

-- AC-1
function TestBlackEpsilonT4Wiring:test_the_handler_include_line_follows_the_haymir_handler_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented ninGursaweConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented ninGursaweConvoHandler include")

	local lines, squadron, hakassha, prisk, haymir = linesOf(text), nil, nil, nil, nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/BlackEpsilonSquadronScreenplay.lua")', 1, true) then
			squadron = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua")', 1, true) then
			hakassha = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua")', 1, true) then
			prisk = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler.lua")', 1, true) then
			haymir = i
		end
	end

	lu.assertNotNil(squadron, "screenplays.lua: the BlackEpsilonSquadronScreenplay include")
	lu.assertEquals(hakassha, squadron + 2, "screenplays.lua: the Hakassha handler include stays 2 lines after the squadron include (tier 1 pin)")
	lu.assertEquals(prisk, hakassha + 1, "screenplays.lua: the Prisk handler include stays directly after Hakassha's (tier 2 pin)")
	lu.assertEquals(haymir, prisk + 1, "screenplays.lua: the Haymir handler include stays directly after Prisk's (tier 3 pin)")
	lu.assertEquals(lines[haymir + 1], 'includeFile("space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler.lua")',
		"screenplays.lua: the Nin Gursawe handler include, directly after the Haymir one, no blank line")
end

-- AC-1, FN-5: the three inspect ships' template files carry the cargo line directly after questLoot
function TestBlackEpsilonT4Wiring:test_the_three_inspect_ship_templates_carry_the_cargo_string_line_directly_after_quest_loot()
	for _, c in ipairs(T.INSPECTS) do
		local text = readFile(H.SCRIPTS .. "ship_mobile/ships/" .. c.ship .. ".lua")

		lu.assertNotNil(text, c.ship .. ".lua exists")

		local loot = text:find('questLoot = "' .. c.cargo .. '",\n', 1, true)

		lu.assertNotNil(loot, c.ship .. ".lua: the questLoot line (" .. c.cargo .. ")")
		lu.assertEquals(text:sub(loot):match('^[^\n]*\n%s*([^\n]*)\n'), 'cargoString = "' .. c.cargo .. '",', c.ship .. ".lua: cargoString directly after questLoot")
	end
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Tables = {}

function TestBlackEpsilonT4Tables:setUp() H.reset() end

-- AC-2, I-1
function TestBlackEpsilonT4Tables:test_the_nineteen_tables_keep_their_identity_and_zone()
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
function TestBlackEpsilonT4Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
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
function TestBlackEpsilonT4Tables:test_exactly_the_eleven_non_end_story_tables_split_and_name_the_next_chain_member()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local ends = { [T.M1[3]] = true, [T.M2[3]] = true, [T.M3[4]] = true, [T.M4[5]] = true }
	local patrols = { [T.M1[1]] = { 3, 25 }, [T.M3[3]] = { 3, 20 } }
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

				if patrols[global] then
					lu.assertEquals(q.sideQuestSplitType, PATROL_POINT, global .. ": PATROL_POINT")
					lu.assertEquals({ q.sideQuestPatrolStart, q.sideQuestDelay }, patrols[global], global .. ": sideQuestPatrolStart, sideQuestDelay (the .tab triggerOn, triggerDelay)")
				else
					lu.assertEquals(q.sideQuestSplitType, COMPLETION, global .. ": COMPLETION (triggerSplitCondition success)")
					lu.assertEquals(q.sideQuestDelay, global == T.M4[3] and 10 or 5, global .. ": sideQuestDelay (triggerDelay + 5; the surprise attack's triggerDelay is 5)")
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

	lu.assertEquals(splits, 11, "split tables")

	for _, global in ipairs(T.DUTIES) do
		lu.assertEquals(quest(global).sideQuest, false, global .. ": a duty does not split")
	end
end

-- AC-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order
function TestBlackEpsilonT4Tables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(T.CHAINS) do
		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #T.M1, #T.M2, #T.M3, #T.M4 }, { 3, 3, 4, 5 }, "chain lengths (3, 3, 4, 5)")
end

-- AC-2, I-5: credits and items only on the four heads (and the duties' own pay fields)
function TestBlackEpsilonT4Tables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local items = { [T.M1[1]] = T.ITEMS[1], [T.M2[1]] = T.ITEMS[2], [T.M3[1]] = T.ITEMS[3], [T.M4[1]] = T.ITEMS[4] }
	local duties = { [T.DUTIES[1]] = 300, [T.DUTIES[2]] = 5000, [T.DUTIES[3]] = 5000, [T.DUTIES[4]] = 5000 }

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		if items[global] then
			lu.assertEquals(rawget(q, "creditReward"), 10000, global .. ": creditReward")
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = items[global] } }, global .. ": itemReward (any species)")
		elseif duties[global] then
			lu.assertEquals(rawget(q, "creditReward"), duties[global], global .. ": the duty's own creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		else
			lu.assertNil(rawget(q, "creditReward"), global .. ": creditReward")
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template
function TestBlackEpsilonT4Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "attackShipLists", "allyForce", "enemyForce", "shipTypes", "targetShipTypes" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "deliveryShip", "targetShipType", "bossShip" }) do
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

		if rawget(q, "surpriseAttackShips") then
			for _, s in ipairs(q.surpriseAttackShips.spawns) do
				ships[s.shipName] = true
			end
		end
	end

	lu.assertEquals(#sortedKeys(ships), 22, "distinct ships in the 19 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 19 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestBlackEpsilonT4Tables:test_every_quest_is_in_the_client_quest_name_table()
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

TestBlackEpsilonT4Conformance = {}

function TestBlackEpsilonT4Conformance:setUp() H.reset() end

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

-- AC-2, I-4: every story quest: zone, split target and delay from triggerArg
function TestBlackEpsilonT4Conformance:test_every_table_takes_zone_and_split_target_from_its_fixture()
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
			lu.assertEquals(q.sideQuest, false, l .. ": sideQuest (triggerEvent none or a duty)")
			lu.assertEquals(q.sideQuestType, "", l .. ": sideQuestType")
		end
	end
end

-- AC-2, I-2, I-4: the two patrols
function TestBlackEpsilonT4Conformance:test_the_patrols_map_their_four_points_in_file_order()
	for _, global in ipairs({ T.M1[1], T.M3[3] }) do
		local q, rec = quest(global), fixtureOf(global)

		lu.assertEquals(q.patrolPoints, mapped(rec, "navPoints", function(i) return { patrolNumber = i, radius = 150 } end), label(global) .. ": patrolPoints (navPoints)")
	end
end

-- AC-2, I-2, I-4: the three inspects
function TestBlackEpsilonT4Conformance:test_the_inspects_map_ship_spawner_waypoint_flag_and_cargo()
	for _, c in ipairs(T.INSPECTS) do
		local q, rec = quest(c.global), fixtureOf(c.global)
		local l = label(c.global)
		local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, l .. ": spawner " .. spawnName)
		lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
		lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = s.x, z = s.z, y = s.y } }, l .. ": validSpawns")
		lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
		lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
	end
end

-- AC-2, I-2, I-4: survival 1_b
function TestBlackEpsilonT4Conformance:test_survival_1_b_maps_point_timers_attack_lists_and_order()
	local q, rec = quest(T.M1[3]), fixtureOf(T.M1[3])
	local l = label(T.M1[3])

	lu.assertEquals(q.transmissionPoint, mapped(rec, "transmissionPoint")[1], l .. ": transmissionPoint")
	lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
	lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
	lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
	lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(q.attackShipLists, T.attackLists(rec), l .. ": attackShipLists (attackShips1..6, column-wise)")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- AC-2, I-2, I-4: the two recoveries (recovery 2 has no escorts)
function TestBlackEpsilonT4Conformance:test_recoveries_map_ships_paths_attack_lists_and_taunts_from_their_fixtures()
	for _, global in ipairs({ T.M2[1], T.M4[2] }) do
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
		lu.assertEquals(q.attackShips, T.attackLists(rec), l .. ": attackShips (attackShips1..n, column-wise)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
		lu.assertNil(rawget(q, "recoveryConversationMobile"), l .. ": recoveryConversationMobile stays the type default")
	end

	lu.assertEquals(quest(T.M2[1]).escortShips, {}, "recovery_corellia_imperial_tier4_2: escortShips is the empty list (its column is empty)")
	lu.assertEquals(#quest(T.M4[2]).escortShips, 7, "recovery_corellia_imperial_tier4_4_a: seven escorts")
end

-- AC-2, I-2, I-4: delivery 2_b
function TestBlackEpsilonT4Conformance:test_delivery_2_b_maps_ship_point_attack_lists_period_and_order()
	local q, rec = quest(T.M2[3]), fixtureOf(T.M2[3])
	local l = label(T.M2[3])

	lu.assertEquals(q.deliveryShip, rec:get("deliveryShip"), l .. ": deliveryShip")
	lu.assertEquals(q.deliveryPoint, mapped(rec, "deliveryPoint")[1], l .. ": deliveryPoint")
	lu.assertEquals(q.attackShipLists, T.attackLists(rec), l .. ": attackShipLists (attackShips1..4, column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- AC-2, I-2, I-4, D-12: escort 3 (numResponses 0 in SWG, five of each taunt here)
function TestBlackEpsilonT4Conformance:test_escort_3_maps_ship_path_attack_lists_and_five_taunts_of_each_kind()
	local q, rec = quest(T.M3[1]), fixtureOf(T.M3[1])
	local l = label(T.M3[1])

	lu.assertEquals(q.escortShips, rec:list("escortShipType"), l .. ": escortShips (escortShipType)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPath", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints (escortPath)")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, T.attackLists(rec), l .. ": attackShips (attackShips1..4)")
	lu.assertEquals(rec:num("numResponses"), 0, l .. ": precondition: SWG's numResponses is 0")
	lu.assertEquals(q.tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, l .. ": tauntData (5 of each: the client files have _1.._5, D-12)")
end

-- AC-2, I-2, I-4: rescue 3_a
function TestBlackEpsilonT4Conformance:test_rescue_3_a_maps_path_target_attack_lists_and_responses()
	local q, rec = quest(T.M3[2]), fixtureOf(T.M3[2])
	local l = label(T.M3[2])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipType, rec:get("targetShipType"), l .. ": targetShipType")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, T.attackLists(rec), l .. ": attackShipLists (column-wise)")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
end

-- AC-2, I-2, I-4: the two assassinates
function TestBlackEpsilonT4Conformance:test_assassinates_map_target_escorts_delay_path_and_flag()
	for _, global in ipairs({ T.M4[1], T.M4[5] }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)

		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, mapped(rec, "escortPath"), l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals(#quest(T.M4[1]).assassinateSpawns.escorts, 7, "assassinate 4: seven escorts")
	lu.assertEquals(#quest(T.M4[5]).assassinateSpawns.escorts, 9, "assassinate 4_d: nine escorts")
end

-- AC-2, I-2, I-4: the surprise attack
function TestBlackEpsilonT4Conformance:test_surprise_attack_4_b_maps_ship_and_count()
	local q, rec = quest(T.M4[3]), fixtureOf(T.M4[3])
	local l = label(T.M4[3])

	lu.assertEquals(q.surpriseAttackShips, { zone = rec:get("questZone"), spawns = { { count = rec:num("shipCount"), shipName = rec:get("shipType") } } }, l .. ": surpriseAttackShips")
	lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay") + 5, l .. ": sideQuestDelay (triggerDelay 5 + 5)")
end

-- AC-2, I-2, I-4: battle 4_c
function TestBlackEpsilonT4Conformance:test_battle_4_c_maps_point_forward_timers_distances_and_forces()
	local q, rec = quest(T.M4[4]), fixtureOf(T.M4[4])
	local l = label(T.M4[4])
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

-- AC-2, I-4: destroy duty 1
function TestBlackEpsilonT4Conformance:test_destroy_duty_1_maps_waves_rounds_levels_ships_boss_and_pay()
	local q, rec = quest(T.DUTIES[1]), fixtureOf(T.DUTIES[1])
	local l = label(T.DUTIES[1])

	lu.assertEquals({ q.totalWaves, q.totalRounds, q.totalLevels }, { rec:num("wavesPerRound"), rec:num("roundsPerLevel"), rec:num("levelsPerDuty") }, l .. ": totalWaves, totalRounds, totalLevels")
	lu.assertEquals(q.shipTypes, T.attackLists(rec, rec:num("shipTypes"), "shipType"), l .. ": shipTypes (shipType1..4, column-wise)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
end

-- AC-2, I-4: escort duty 2
function TestBlackEpsilonT4Conformance:test_escort_duty_2_maps_ships_points_attack_lists_pay_and_taunts()
	local q, rec = quest(T.DUTIES[2]), fixtureOf(T.DUTIES[2])
	local l = label(T.DUTIES[2])

	lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes)")
	lu.assertEquals(q.escortPoints, mapped(rec, "escortPoints", function(i, p) return { zoneName = p.zone, escortNumber = i, radius = 250 } end), l .. ": escortPoints")
	lu.assertEquals(q.attackShips, T.attackLists(rec), l .. ": attackShips")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay")
	lu.assertEquals({ q.creditReward, q.creditKillBonus }, { rec:num("reward"), rec:num("killReward") }, l .. ": creditReward, creditKillBonus")

	local m = rec:num("numResponses")

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, l .. ": tauntData (numResponses)")
end

-- AC-2, I-4: recovery duty 3
function TestBlackEpsilonT4Conformance:test_recovery_duty_3_maps_ship_delays_escorts_paths_attack_lists_pay_and_taunts()
	local q, rec = quest(T.DUTIES[3]), fixtureOf(T.DUTIES[3])
	local l = label(T.DUTIES[3])
	local radius = function(i) return { escortNumber = i, radius = 250 } end

	lu.assertEquals(q.recoverShip, rec:get("targetShipTypes"), l .. ": recoverShip (targetShipTypes, a single type)")
	lu.assertEquals({ q.arrivalDelay, q.recoveryDelay }, { rec:num("targetArrivalDelay"), rec:num("targetRecoverTime") }, l .. ": arrivalDelay, recoveryDelay")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	lu.assertEquals(q.preRecoveryPoints, mapped(rec, "escortPath", radius), l .. ": preRecoveryPoints")
	lu.assertEquals(q.recoveryPoints, mapped(rec, "recoveryPath", radius), l .. ": recoveryPoints")
	lu.assertEquals(q.attackShips, T.attackLists(rec), l .. ": attackShips")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay")
	lu.assertEquals({ q.creditReward, q.creditKillBonus, q.numResponses }, { rec:num("reward"), rec:num("killReward"), rec:num("numResponses") }, l .. ": creditReward, creditKillBonus, numResponses")
	lu.assertEquals(q.tauntData, { panicCount = 5, thanksCount = 5 }, l .. ": tauntData")
end

-- AC-2, I-4: rescue duty 4
function TestBlackEpsilonT4Conformance:test_rescue_duty_4_maps_path_ships_attack_lists_pay_and_responses()
	local q, rec = quest(T.DUTIES[4]), fixtureOf(T.DUTIES[4])
	local l = label(T.DUTIES[4])

	lu.assertEquals(q.recoveryPath, mapped(rec, "recoveryPath"), l .. ": recoveryPath (plain points)")
	lu.assertEquals(q.targetShipTypes, rec:list("targetShipTypes"), l .. ": targetShipTypes")
	lu.assertEquals(q.targetArrivalDelay, rec:num("targetArrivalDelay"), l .. ": targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, T.attackLists(rec), l .. ": attackShipLists")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, 0, l .. ": attackListType (0, sequential)")
	lu.assertEquals({ q.creditReward, q.creditKillBonus, q.numResponses }, { rec:num("reward"), rec:num("killReward"), rec:num("numResponses") }, l .. ": creditReward, creditKillBonus, numResponses")
end

---------------------------------------------------------------------------------------------
-- I-11: the inspect cargo, read from the REAL ship template files (not a cargo set on a fake)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Cargo = {}

function TestBlackEpsilonT4Cargo:setUp() H.reset() end

-- AC-2, I-11
function TestBlackEpsilonT4Cargo:test_each_inspect_ship_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	for _, c in ipairs(T.INSPECTS) do
		local q = quest(c.global)

		lu.assertEquals(q.shipList, { c.ship }, c.global .. " shipList")

		local src = templateSource(c.ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, c.ship .. ".lua cargoString must equal the quest cargo")
		lu.assertEquals(questLoot, c.cargo, c.ship .. ".lua questLoot (names the inspect_cargo table)")

		local rows = H.fixture("spacequest/inspect_cargo/" .. questLoot .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. questLoot .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { q.cargo, 1 }, c.ship .. ": cargo is the canTransfer = 1 row of the table")
	end
end

-- AC-2, I-11: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestBlackEpsilonT4Cargo:test_the_loaded_inspect_ship_templates_have_the_cargo_string_and_the_cargo_of_the_space_mobile_row()
	local mobs = {}

	for _, rec in ipairs(H.fixture("space_mobile/space_mobile.corellia_imperial_tier4_inspect.tab").records) do
		mobs[rec:get("strIndex")] = rec:get("cargo")
	end

	for _, c in ipairs(T.INSPECTS) do
		local t = H.shipTemplate(c.ship)

		lu.assertNotNil(t, "ship_mobile/ships/" .. c.ship .. ".lua registers a template")
		lu.assertEquals(t.cargoString, c.cargo, c.ship .. ": cargoString")
		lu.assertEquals(t.cargoString, mobs[c.ship], c.ship .. ": cargoString equals the SWG space_mobile.tab cargo column")
		lu.assertEquals(t.questLoot, c.cargo, c.ship .. ": questLoot is unchanged")
	end
end
