-- Inquisition tier 4 (Grand Inquisitor Ja'ce Yiaso): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7, I-11; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of inquisition_tier4_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local Swgjava = require("harness.swgjava")

J4.load()

local function quest(global) return J4.quest(global) end

local function fixtureOf(global) return J4.fixtureOf(global) end

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

local function point(name)
	local p = H.patrolPoints("space_dathomir")[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in space_dathomir")
	return p
end

local function trunc(v) return v < 0 and math.ceil(v) or math.floor(v) end

-- name -> {x, z, y, forward}, spawner -> {x, z, y}, rows = n from the buildout extract of this feature
local function extract()
	local out = { nav = {}, spawner = {}, rows = 0 }

	for _, rec in ipairs(H.fixture("space_zones/buildout/space_dathomir.inquisition_tier4_points.tab").records) do
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

TestInquisitionT4Fixtures = {}

function TestInquisitionT4Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the fixtures carry the values the spec lists
function TestInquisitionT4Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = fixtureOf(J4.M1[1])

	lu.assertEquals({ #p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg"), p1:get("questZone") },
		{ 3, 2, 25, "inspect:naboo_imperial_tier4_1_a", "space_dathomir" }, "patrol/naboo_imperial_tier4_1")

	local i1 = fixtureOf(J4.M1[2])

	lu.assertEquals({ i1:list("shipList"), i1:list("validSpawns"), i1:num("giveSpawnWaypoint"), i1:get("cargo"), i1:num("triggerDelay"), i1:get("triggerArg") },
		{ { J4.INSPECT_SHIP }, { "space_dathomir:" .. J4.SPAWNER.name }, 1, J4.CARGO, 10, "destroy_surpriseattack:naboo_imperial_tier4_1_b" }, "inspect/naboo_imperial_tier4_1_a")

	for _, g in ipairs({ J4.M1[3], J4.M2[3] }) do
		local s = fixtureOf(g)

		lu.assertEquals({ s:get("shipType"), s:num("shipCount"), s:num("triggerDelay") }, { "coynite_merc_pulsar_tier4", 6, 0 }, "surprise attack fixture " .. g)
	end

	local d1 = fixtureOf(J4.M1[4])

	lu.assertEquals({ d1:get("deliveryShip"), d1:list("deliveryPoint"), d1:num("attackPeriod"), d1:get("attackListType") },
		{ "imp_lambda_shuttle_tier4", { "space_dathomir:naboo_imperial_tier3_delivery3_pickup" }, 90, "sequential" }, "delivery_no_pickup/naboo_imperial_tier4_1_c")

	local r2 = fixtureOf(J4.M2[1])

	lu.assertEquals({ r2:get("targetShipType"), r2:num("targetArrivalDelay"), r2:num("targetRecoverTime"), #r2:list("targetEscort"), r2:num("attackPeriod"), r2:num("numResponses") },
		{ "crystal_smuggler_heavy_tier4", 30, 30, 0, 120, 5 }, "recovery/naboo_imperial_tier4_2")

	local a2 = fixtureOf(J4.M2[2])

	lu.assertEquals({ a2:get("targetShipType"), a2:num("targetArrivalDelay"), #a2:list("recoveryPath"), a2:num("numResponses"), a2:num("attackPeriod") },
		{ "imp_lambda_recon_tier4", 30, 4, 5, 120 }, "rescue/naboo_imperial_tier4_2_a")

	local c2 = fixtureOf(J4.M2[4])

	lu.assertEquals({ c2:get("targetShipType"), #c2:list("targetEscort"), #c2:list("escortPath"), #c2:list("recoveryPath") },
		{ "coynite_merc_neutron_tier5", 4, 4, 3 }, "recovery/naboo_imperial_tier4_2_c")

	local s3 = fixtureOf(J4.M3[1])

	lu.assertEquals({ s3:get("transmissionPoint"), s3:num("totalTransmissionTime"), s3:num("timesToUpdateProgress"), s3:num("transmissionStartDelay"), s3:num("delayToFirstAttack"), s3:num("attackPeriod"), s3:get("attackListType") },
		{ "space_dathomir:naboo_imperial_tier4_survival1", 600, 20, 15, 30, 90, "sequential" }, "survival/naboo_imperial_tier4_3")

	local d3 = fixtureOf(J4.M3[2])

	lu.assertEquals({ d3:get("deliveryShip"), d3:list("deliveryPoint"), d3:num("attackPeriod") }, { "imp_lambda_shuttle_tier4", { "space_dathomir:naboo_imperial_tier4_delivery2" }, 60 }, "delivery_no_pickup/naboo_imperial_tier4_3_a")

	local a3 = fixtureOf(J4.M3[3])

	lu.assertEquals({ a3:get("targetShipType"), a3:num("targetArrivalDelay"), #a3:list("targetEscort"), a3:num("mustDestroyEscort"), #a3:list("escortPath") },
		{ "coynite_mothership_tier4", 30, 9, 1, 4 }, "assassinate/naboo_imperial_tier4_3_b")

	local e4 = fixtureOf(J4.M4[1])

	lu.assertEquals({ e4:list("escortShipType"), #e4:list("escortPath"), e4:num("numResponses"), e4:num("attackPeriod") },
		{ { "dathomir_prison_shuttle_tier4" }, 5, 0, 120 }, "escort/naboo_imperial_tier4_4 (numResponses 0: FJ-7)")

	local r4 = fixtureOf(J4.M4[2])

	lu.assertEquals({ r4:get("targetShipType"), r4:num("targetArrivalDelay"), r4:num("targetRecoverTime"), #r4:list("targetEscort"), r4:num("attackPeriod") },
		{ "dathomir_prison_break_shuttle_tier4", 30, 30, 5, 120 }, "recovery/naboo_imperial_tier4_4_a")

	for global, want in pairs({ [J4.M4[3]] = { 5, 4 }, [J4.M4[4]] = { 8, 4 } }) do
		local a = fixtureOf(global)

		lu.assertEquals({ a:get("targetShipType"), #a:list("targetEscort"), a:num("mustDestroyEscort"), #a:list("escortPath") }, { "dathomir_prison_break_shuttle_tier4", want[1], 1, want[2] }, "assassinate fixture " .. global)
	end

	local b4 = fixtureOf(J4.M4[5])

	lu.assertEquals({ b4:num("damageMultiplier"), b4:num("allyArrivalDelay"), b4:num("enemyArrivalDelay"), b4:num("allyOriginDist"), b4:num("enemyOriginDist"), b4:num("allyArrivalDist"),
		b4:num("enemyArrivalDist"), #b4:list("allyForce"), #b4:list("enemyForce") }, { 2, 30, 90, 400, -400, 300, 300, 7, 11 }, "space_battle/naboo_imperial_tier4_4_d")

	local du1 = fixtureOf(J4.DUTIES[1])

	lu.assertEquals({ du1:num("wavesPerRound"), du1:num("roundsPerLevel"), du1:num("levelsPerDuty"), du1:get("bossType"), du1:num("reward") },
		{ 3, 5, 8, "coynite_merc_captain_tier5", 300 }, "destroy_duty/naboo_imperial_tier4_1")

	for _, g in ipairs({ J4.DUTIES[2], J4.DUTIES[3], J4.DUTIES[4] }) do
		local d = fixtureOf(g)

		lu.assertEquals({ d:num("reward"), d:num("killReward"), d:num("numResponses"), d:num("attackPeriod") }, { 5000, 300, 5, 120 }, "duty fixture " .. g)
	end
end

-- Appendix B (the oracle itself): the attack list sizes
function TestInquisitionT4Fixtures:test_the_attack_lists_have_the_sizes_appendix_b_lists()
	for global, want in pairs(J4.LIST_SIZES) do
		local rec, got = fixtureOf(global), {}
		local n = rec:num("numAttackShipLists") or 4
		local column = global:match("^destroy_duty") and "shipType" or "attackShips"

		for i = 1, n do
			got[i] = #rec:list(column .. i)
		end

		lu.assertEquals(got, want, global .. ": attack list sizes")
	end
end

-- I-2 (the oracle itself): the spec's point literals are what the patrol point file and the buildout extract hold
function TestInquisitionT4Fixtures:test_the_spec_points_equal_the_core3_point_file_and_the_buildout_extract()
	local ex = extract()
	local total = 0

	for name, xyz in pairs(J4.POINTS) do
		local p = point(name)
		local row = ex.nav[name]

		total = total + 1
		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_dathomir patrol point file: " .. name)
		lu.assertNotNil(row, "buildout extract has no row for " .. name)
		lu.assertEquals({ row.x, row.z, row.y }, xyz, "buildout extract (truncated toward zero): " .. name)
	end

	lu.assertEquals(total, 61, "spec points (60 tier 4 points and Vrke's pickup point)")
	lu.assertEquals(ex.rows, 62, "rows of the extract (61 nav points and the spawner)")
end

-- I-2 (the oracle itself): the inspect spawner
function TestInquisitionT4Fixtures:test_the_spec_spawner_equals_the_core3_spawner_file_and_the_buildout_extract()
	local sp = J4.SPAWNER
	local s = H.spawners("space_dathomir")[sp.name]

	lu.assertNotNil(s, "space_dathomir spawner " .. sp.name)
	lu.assertEquals({ s.x, s.z, s.y }, { sp.x, sp.z, sp.y }, "spawner " .. sp.name)

	local row = extract().spawner[sp.name]

	lu.assertEquals(row and { row.x, row.z, row.y }, { sp.x, sp.z, sp.y }, "buildout extract: spawner row " .. sp.name)
end

-- AC-2 (the oracle itself): the battle forward axis
function TestInquisitionT4Fixtures:test_the_battle_forward_axis_is_the_buildout_k_axis()
	local row = extract().nav.naboo_imperial_tier4_spacebattle1

	lu.assertEquals(row.forward, J4.FORWARD, "fltKX, fltKY, fltKZ of the battle point")
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script
function TestInquisitionT4Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_imperial_tier4.java")

	lu.assertNotNil(java, "fixtures/script/conversation/naboo_imperial_tier4.java")

	local found = {}

	for questType, questName, credits, path in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		found[questType .. "_" .. questName] = { tonumber(credits), path }
	end

	lu.assertEquals(found.patrol_naboo_imperial_tier4_1, { J4.CREDITS, J4.ITEMS[1] }, "J giveReward 1")
	lu.assertEquals(found.recovery_naboo_imperial_tier4_2, { J4.CREDITS, J4.ITEMS[2] }, "J giveReward 2")
	lu.assertEquals(found.survival_naboo_imperial_tier4_3, { J4.CREDITS, J4.ITEMS[3] }, "J giveReward 3")
	lu.assertEquals(found.escort_naboo_imperial_tier4_4, { J4.CREDITS, J4.ITEMS[4] }, "J giveReward 4")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 150%.0f%)"), 4, "J: +150 Imperial standing, once per reward")
	lu.assertEquals(countMatches(java, 'skill%.purchaseSkill%(player, "pilot_imperial_navy_%a+_04"%)'), 4, "J: the four tier 4 skills are bought with purchaseSkill (XP charged)")
end

-- Finding 1 / D-2 (the oracle itself): J has no call site of the master mission or master grant
function TestInquisitionT4Fixtures:test_the_swg_script_never_calls_the_master_mission_or_master_grant()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_imperial_tier4.java")

	for _, name in ipairs({ "grantMasterMission", "rewardForMasterMission", "failedMasterMission", "isGettingMasterMissionReward" }) do
		local calls = 0

		for line in java:gmatch("[^\n]+") do
			if line:find(name, 1, true) and not line:find("public ", 1, true) then
				calls = calls + 1
			end
		end

		lu.assertEquals(calls, 0, "call sites of " .. name .. " in naboo_imperial_tier4.java")
	end
end

-- AC-5 (the oracle itself): the answer key parses
function TestInquisitionT4Fixtures:test_the_swg_script_parses_the_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_imperial_tier4.java")

	lu.assertTrue(#graph.order > 150, "NPC lines parsed from naboo_imperial_tier4.java: " .. #graph.order)
end

-- the tier 4 skills fixture: 1,000,000 XP each, the four _03 skills required
function TestInquisitionT4Fixtures:test_the_skills_fixture_prices_each_tier_4_skill_at_one_million_xp_and_requires_the_tier_3_skills()
	local rows = H.fixture("skill/skills.pilot_imperial_navy_04.tab").records
	local costs = J4.useSkillCosts()

	lu.assertEquals(#rows, 4, "skills.pilot_imperial_navy_04.tab rows")

	for _, t in ipairs(J4.TRAIN) do
		lu.assertEquals(costs[t.skill], 1000000, t.skill .. ": XP_COST")
	end

	for _, rec in ipairs(rows) do
		local req = rec:get("SKILLS_REQUIRED")

		for _, s in ipairs(J4.TIER3_SKILLS) do
			lu.assertNotNil(req:find(s, 1, true), rec:get("NAME") .. " requires " .. s)
		end
	end
end

-- I-11 (the oracle itself): the SWG cargo chain: space_mobile cargo -> inspect_cargo row == the quest cargo
function TestInquisitionT4Fixtures:test_the_space_mobile_cargo_resolves_through_inspect_cargo_to_the_quest_cargo()
	local mobs = {}

	for _, rec in ipairs(H.fixture("space_mobile/space_mobile.inquisition_tier4_inspect.tab").records) do
		mobs[rec:get("strIndex")] = rec:get("cargo")
	end

	local rows = H.fixture("spacequest/inspect_cargo/" .. J4.CARGO .. ".tab").records

	lu.assertEquals(mobs[J4.INSPECT_SHIP], J4.CARGO, "space_mobile.tab cargo column of " .. J4.INSPECT_SHIP)
	lu.assertEquals(#rows, 1, J4.CARGO .. ".tab rows")
	lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { J4.CARGO, 1 }, J4.CARGO .. ".tab row")
	lu.assertEquals(fixtureOf(J4.M1[2]):get("cargo"), rows[1]:get("name"), "the inspect quest cargo is that row")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestInquisitionT4Wiring = {}

function TestInquisitionT4Wiring:setUp() H.reset() end

-- AC-1
function TestInquisitionT4Wiring:test_the_squadron_file_registers_the_twenty_tier_4_quests_with_start_true_in_table_order()
	local orders = {}

	for _, global in ipairs(J4.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
		orders[#orders + 1] = H.registered(global).order
	end

	for i = 2, #orders do
		lu.assertTrue(orders[i] > orders[i - 1], J4.GLOBALS[i] .. ": registered after " .. J4.GLOBALS[i - 1])
	end

	lu.assertEquals(#J4.GLOBALS, 20, "tier 4 globals")
end

-- AC-1
function TestInquisitionT4Wiring:test_the_thirty_one_tier_1_to_3_quests_are_still_registered_before_the_tier_4_quests()
	for _, global in ipairs(J4.OLDER_GLOBALS) do
		H.expectGlobal(global, "tier 1-3 quest table")
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	lu.assertEquals(#J4.OLDER_GLOBALS, 31, "tier 1-3 globals")

	if J4.GLOBALS[1] and H.registered(J4.GLOBALS[1]) then
		lu.assertTrue(H.registered(J4.GLOBALS[1]).order > H.registered("assassinate_naboo_imperial_tier3_4_c").order, "tier 4 registers after tier 3")
	end
end

-- AC-1
function TestInquisitionT4Wiring:test_the_squadron_screenplay_has_the_tier_4_constants_and_the_reset()
	local sq = H.expectGlobal("InquisitionSquadronScreenplay", "squadron screenplay object")

	for field, want in pairs(J4.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "InquisitionSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.TIER3_QUEST_STRING_1, { type = "recovery", name = "naboo_imperial_tier3_1" }, "tier 3 TIER3_QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.SPOKE_TO_BARLOW_KEY, J4.SPOKE_SUFFIX, "SPOKE_TO_BARLOW_KEY is unchanged")
	lu.assertEquals(type(sq.resetVrkeQuests), "function", "resetVrkeQuests")
	lu.assertEquals(type(sq.resetJaceYiasoQuests), "function", "InquisitionSquadronScreenplay:resetJaceYiasoQuests")
	lu.assertEquals(pcall(sq.resetJaceYiasoQuests, sq, nil), true, "resetJaceYiasoQuests(nil) returns early")
end

-- AC-1
function TestInquisitionT4Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	J4.requireConversation(lu)

	local t = H.conversationTemplateTable(J4.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, J4.HANDLER, J4.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", J4.TEMPLATE .. ": templateType")

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "getQuestString", "hasStatus", "hasKey", "setKey", "isWon", "isActive", "isFailed", "isPaid",
		"isOnMission", "isGrounded", "canFlyNonTrackDuty", "getNextMission", "getReadyMission", "isReadyForTraining", "payMission", "raisePilotTier", "getLastScreenID" }) do
		lu.assertEquals(type(rawget(_G, J4.HANDLER)[fn]), "function", J4.HANDLER .. ":" .. fn)
	end
end

-- AC-1: Ja'ce's NPC template
function TestInquisitionT4Wiring:test_jace_uses_the_template_and_has_the_conversable_invulnerable_mask()
	for _, group in ipairs({ "brawlermaster", "marksmanmaster" }) do
		if rawget(_G, group) == nil then
			rawset(_G, group, {})
		end
	end

	local npc = H.loadCreatureTemplate("space/jace_yiaso.lua", "jace_yiaso")

	lu.assertNotNil(npc, "mobile/space/jace_yiaso.lua registers jace_yiaso")
	lu.assertEquals(npc.conversationTemplate, "jace_yiaso_convo_template", "jace_yiaso: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "jace_yiaso: optionsBitmask")
end

-- AC-1
function TestInquisitionT4Wiring:test_the_template_include_line_directly_follows_the_barlow_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/inquisition_squadron/jace_yiaso_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented jace_yiaso_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented jace_yiaso_convo include")

	local lines, at = linesOf(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/inquisition_squadron/barlow_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the barlow_convo include")
	lu.assertEquals(lines[at + 1] and lines[at + 1]:match("^%s*(.-)%s*$"), 'includeFile("conversations/space/imperial/inquisition_squadron/jace_yiaso_convo.lua")',
		"space_conversations.lua: the jace_yiaso_convo include directly after the barlow_convo include")
end

-- AC-1
function TestInquisitionT4Wiring:test_the_handler_include_line_directly_follows_the_barlow_handler_include_exactly_once_without_a_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/inquisition_squadron/jaceYiasoConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented jaceYiasoConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented jaceYiasoConvoHandler include")

	local lines, barlow = linesOf(text), nil

	for i, l in ipairs(lines) do
		if l == 'includeFile("space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua")' then
			barlow = i
		end
	end

	lu.assertNotNil(barlow, "screenplays.lua: the barlowConvoHandler include")
	lu.assertEquals(lines[barlow + 1], 'includeFile("space/conversations/imperial/inquisition_squadron/jaceYiasoConvoHandler.lua")',
		"screenplays.lua: the Ja'ce handler include, directly after Barlow's, no blank line")
end

-- AC-1, SC-2, FJ-6: the inspect ship carries the cargo line directly after questLoot
function TestInquisitionT4Wiring:test_the_crystal_smuggler_template_carries_the_cargo_string_line_directly_after_quest_loot()
	local text = readFile(H.SCRIPTS .. J4.SHIP_FILE)

	lu.assertNotNil(text, J4.SHIP_FILE .. " exists")

	local loot = text:find('questLoot = "glowing_crystals",\n', 1, true)

	lu.assertNotNil(loot, J4.SHIP_FILE .. ": the questLoot line (glowing_crystals)")
	lu.assertEquals(text:sub(loot):match('^[^\n]*\n%s*([^\n]*)\n'):match("^(.-)%s*%-%-"), 'cargoString = "glowing_crystals",', J4.SHIP_FILE .. ": cargoString directly after questLoot")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestInquisitionT4Tables = {}

function TestInquisitionT4Tables:setUp() H.reset() end

-- AC-2, I-1
function TestInquisitionT4Tables:test_the_twenty_tables_keep_their_identity_and_zone()
	for _, global in ipairs(J4.GLOBALS) do
		local q = quest(global)
		local id = J4.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_dathomir", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestInquisitionT4Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = J4.expected()

	for _, global in ipairs(J4.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2: the literals the brief singles out
function TestInquisitionT4Tables:test_the_singled_out_values_hold()
	local p1 = quest(J4.M1[1])

	lu.assertEquals({ p1.sideQuestPatrolStart, p1.sideQuestDelay, #p1.patrolPoints }, { 2, 25, 3 }, "patrol 1: sideQuestPatrolStart, sideQuestDelay, points")
	lu.assertEquals(quest(J4.M1[2]).sideQuestDelay, 15, "inspect 1_a: sideQuestDelay (triggerDelay 10 + 5)")

	for _, g in ipairs({ J4.M1[3], J4.M2[3] }) do
		lu.assertEquals(quest(g).surpriseAttackShips, { zone = "space_dathomir", spawns = { { count = 6, shipName = "coynite_merc_pulsar_tier4" } } }, g .. ": surpriseAttackShips")
	end

	lu.assertEquals(quest(J4.M2[1]).escortShips, {}, "recovery 2: no escorts")
	lu.assertEquals(quest(J4.DUTIES[3]).escortShips, {}, "recovery duty: no escorts")
	lu.assertEquals(quest(J4.M4[1]).tauntData, { goodbyeCount = 5, reasonCount = 5, tauntCount = 5, thanksCount = 5 }, "escort 4: tauntData all 5 (FJ-7)")
	lu.assertEquals(quest(J4.DUTIES[3]).recoverShips, { "rogue_imperial_shuttle_tier4", "rogue_imperial_tiebomber_tier4" }, "recovery duty: the two rogue types")

	local names = {}

	for _, p in ipairs(quest(J4.DUTIES[3]).preRecoveryPoints) do
		names[#names + 1] = p.patrolPointName
	end

	lu.assertEquals(names, { "naboo_imperial_tier4_recoveryduty1_1", "naboo_imperial_tier4_recoveryduty1_2", "naboo_imperial_tier4_recoveryduty1_4", "naboo_imperial_tier4_recoveryduty1_5" },
		"recovery duty: preRecoveryPoints skip recoveryduty1_3")
	lu.assertEquals(quest(J4.M4[5]).battlePoint.forward, J4.FORWARD, "battle 4_d: forward")
	lu.assertEquals(quest(J4.M4[5]).damageMultiplier, 2, "battle 4_d: damageMultiplier stored")
end

-- AC-2, I-6: split wiring
function TestInquisitionT4Tables:test_exactly_the_twelve_non_end_story_tables_split_and_name_the_next_chain_member()
	local COMPLETION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION
	local PATROL_POINT = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT
	local ends = { [J4.M1[4]] = true, [J4.M2[4]] = true, [J4.M3[3]] = true, [J4.M4[5]] = true }
	local splits = 0

	for _, chain in ipairs(J4.CHAINS) do
		for i, global in ipairs(chain) do
			local q = quest(global)

			lu.assertEquals(q.sideQuest and true or false, ends[global] == nil, global .. ": sideQuest")

			if ends[global] then
				lu.assertEquals(q.sideQuestType, "", global .. ": the chain end has no split type")
			else
				splits = splits + 1

				local nextId = J4.IDENTITY[chain[i + 1]]

				lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { nextId.type, nextId.name }, global .. ": sideQuestType, sideQuestName")
				lu.assertNotEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, global .. ": no table is BIDIRECTIONAL")

				if global == J4.M1[1] then
					lu.assertEquals(q.sideQuestSplitType, PATROL_POINT, global .. ": PATROL_POINT (the only one)")
					lu.assertEquals({ q.sideQuestPatrolStart, q.sideQuestDelay }, { 2, 25 }, global .. ": sideQuestPatrolStart, sideQuestDelay")
				else
					lu.assertEquals(q.sideQuestSplitType, COMPLETION, global .. ": COMPLETION (triggerSplitCondition success)")
					lu.assertEquals(q.sideQuestDelay, global == J4.M1[2] and 15 or 5, global .. ": sideQuestDelay (triggerDelay + 5; inspect 1_a's triggerDelay is 10)")
				end
			end

			if i > 1 then
				local pid = J4.IDENTITY[chain[i - 1]]

				lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { chain[i - 1], pid.type, pid.name }, global .. ": parent fields")
			else
				lu.assertNil(rawget(q, "parentQuest"), global .. ": a head has no parent")
			end
		end
	end

	lu.assertEquals(splits, 12, "split tables")

	for _, global in ipairs(J4.DUTIES) do
		lu.assertEquals(quest(global).sideQuest, false, global .. ": a duty does not split")
	end
end

-- AC-2, I-6: every split of the fixtures names the next chain member (the oracle derived from the .tab files)
function TestInquisitionT4Tables:test_every_tab_split_names_the_next_chain_member_and_the_ends_split_nowhere()
	for _, chain in ipairs(J4.CHAINS) do
		for i, global in ipairs(chain) do
			local rec = fixtureOf(global)
			local arg = rec:get("triggerArg")

			if i == #chain then
				lu.assertTrue(arg == nil or arg == "" or rec:get("triggerEvent") == "none", global .. ": the chain end has triggerEvent none")
			else
				local nid = J4.IDENTITY[chain[i + 1]]

				lu.assertEquals(arg, nid.type .. ":" .. nid.name, global .. ": triggerArg is the next chain member")
				lu.assertEquals(rec:get("questZone"), "space_dathomir", global .. ": questZone")
			end
		end
	end
end

-- AC-2, I-6: SpaceHelpers:getSpaceQuestChain walks each mission in chain order
function TestInquisitionT4Tables:test_get_space_quest_chain_returns_each_mission_in_chain_order()
	for n, chain in ipairs(J4.CHAINS) do
		local got = {}

		for i, entry in ipairs(SpaceHelpers:getSpaceQuestChain(chain[1])) do
			got[i] = entry.global
		end

		lu.assertEquals(got, chain, "mission " .. n .. ": chain members from " .. chain[1])
	end

	lu.assertEquals({ #J4.M1, #J4.M2, #J4.M3, #J4.M4 }, { 4, 4, 3, 5 }, "chain lengths (4, 4, 3, 5)")
end

-- AC-2, I-5: credits and items only on the four heads (and the duties' own pay fields)
function TestInquisitionT4Tables:test_credits_and_items_sit_on_the_four_mission_heads_only()
	local items = { [J4.M1[1]] = J4.ITEMS[1], [J4.M2[1]] = J4.ITEMS[2], [J4.M3[1]] = J4.ITEMS[3], [J4.M4[1]] = J4.ITEMS[4] }
	local duties = { [J4.DUTIES[1]] = 300, [J4.DUTIES[2]] = 5000, [J4.DUTIES[3]] = 5000, [J4.DUTIES[4]] = 5000 }

	for _, global in ipairs(J4.GLOBALS) do
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
function TestInquisitionT4Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(J4.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipList", "attackShipLists", "allyForce", "enemyForce", "shipTypes", "targetShipTypes", "recoverShips" }) do
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

	lu.assertEquals(#sortedKeys(ships), 23, "distinct ships in the 20 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 20 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua does not exist")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path .. ": no object template under bin/scripts")
	end
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestInquisitionT4Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(J4.GLOBALS) do
		local id = J4.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestInquisitionT4Conformance = {}

function TestInquisitionT4Conformance:setUp() H.reset() end

-- the points of a .tab column, mapped through the Core3 point file
local function pointNames(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)

		out[i] = { zone = zone, name = name }
	end

	return out
end

local function namesOf(points)
	local out = {}

	for i, p in ipairs(points or {}) do
		out[i] = p.patrolPointName
	end

	return out
end

-- I-2, I-4: every table's point lists carry the .tab names in file order, with Core3's coordinates
function TestInquisitionT4Conformance:test_point_lists_carry_the_tab_names_in_file_order_with_the_core3_coordinates()
	local checks = {
		{ J4.M1[1], "patrolPoints", "navPoints" },
		{ J4.M2[2], "recoveryPath", "recoveryPath" },
		{ J4.M2[1], "preRecoveryPoints", "escortPath" },
		{ J4.M2[1], "recoveryPoints", "recoveryPath", 3 },
		{ J4.M2[4], "preRecoveryPoints", "escortPath" },
		{ J4.M2[4], "recoveryPoints", "recoveryPath" },
		{ J4.M3[3], "targetPatrols", "escortPath" },
		{ J4.M4[1], "escortPoints", "escortPath" },
		{ J4.M4[2], "preRecoveryPoints", "escortPath" },
		{ J4.M4[2], "recoveryPoints", "recoveryPath" },
		{ J4.M4[3], "targetPatrols", "escortPath" },
		{ J4.M4[4], "targetPatrols", "escortPath" },
		{ J4.DUTIES[2], "escortPoints", "escortPoints" },
		{ J4.DUTIES[3], "preRecoveryPoints", "escortPath" },
		{ J4.DUTIES[3], "recoveryPoints", "recoveryPath" },
		{ J4.DUTIES[4], "recoveryPath", "recoveryPath" },
	}

	for _, c in ipairs(checks) do
		local global, field, column = c[1], c[2], c[3]
		local q = quest(global)
		local want = pointNames(fixtureOf(global), column)

		if c[4] then
			lu.assertEquals(#want, c[4], global .. ": the .tab " .. column .. " has " .. c[4] .. " points")
		end

		local got = rawget(q, field)

		lu.assertEquals(#got, #want, global .. ": " .. field .. " count")

		for i, w in ipairs(want) do
			local p = point(w.name)

			lu.assertEquals({ got[i].patrolPointName, got[i].x, got[i].z, got[i].y }, { w.name, p.x, p.z, p.y }, global .. ": " .. field .. "[" .. i .. "]")
		end
	end
end

-- I-2: point flags per quest type
function TestInquisitionT4Conformance:test_point_flags_follow_the_quest_type()
	local function flags(global, field, want)
		for i, p in ipairs(rawget(quest(global), field)) do
			for k, v in pairs(want) do
				lu.assertEquals(p[k], v == "i" and i or v, global .. ": " .. field .. "[" .. i .. "]." .. k)
			end
		end
	end

	flags(J4.M1[1], "patrolPoints", { radius = 150, patrolNumber = "i" })
	flags(J4.M2[1], "preRecoveryPoints", { radius = 250, escortNumber = "i" })
	flags(J4.M2[1], "recoveryPoints", { radius = 250, escortNumber = "i" })
	flags(J4.M4[1], "escortPoints", { radius = 250, escortNumber = "i", zoneName = "space_dathomir" })
	flags(J4.DUTIES[2], "escortPoints", { radius = 250, escortNumber = "i", zoneName = "space_dathomir" })
	flags(J4.DUTIES[3], "recoveryPoints", { radius = 250, escortNumber = "i" })

	for _, g in ipairs({ J4.M2[2], J4.DUTIES[4] }) do
		for i, p in ipairs(quest(g).recoveryPath) do
			lu.assertNil(p.radius, g .. ": recoveryPath[" .. i .. "] has no radius")
			lu.assertNil(p.escortNumber, g .. ": recoveryPath[" .. i .. "] has no escortNumber")
		end
	end
end

-- Data mapping 1: the recovery duty keeps SWG's gap (recoveryduty1_3 is skipped) and renumbers 1..4
function TestInquisitionT4Conformance:test_the_recovery_duty_renumbers_its_pre_recovery_points_over_the_skipped_point()
	local pre = quest(J4.DUTIES[3]).preRecoveryPoints

	lu.assertEquals(namesOf(pre), { "naboo_imperial_tier4_recoveryduty1_1", "naboo_imperial_tier4_recoveryduty1_2", "naboo_imperial_tier4_recoveryduty1_4", "naboo_imperial_tier4_recoveryduty1_5" }, "names")

	for i, p in ipairs(pre) do
		lu.assertEquals(p.escortNumber, i, "escortNumber of pre point " .. i)
	end
end

-- Data mapping 1: the attack waves come from the .tab columns, one inner list per column
function TestInquisitionT4Conformance:test_attack_lists_take_one_inner_list_per_tab_column()
	local cases = {
		{ J4.M1[4], "attackShipLists", 2 }, { J4.M2[1], "attackShips", 3 }, { J4.M2[2], "attackShipLists", 3 }, { J4.M2[4], "attackShips", 3 },
		{ J4.M3[1], "attackShipLists", 6 }, { J4.M3[2], "attackShipLists", 4 }, { J4.M4[1], "attackShips", 4 }, { J4.M4[2], "attackShips", 2 },
		{ J4.DUTIES[2], "attackShips", 2 }, { J4.DUTIES[3], "attackShips", 2 }, { J4.DUTIES[4], "attackShipLists", 3 },
	}

	for _, c in ipairs(cases) do
		local rec, got = fixtureOf(c[1]), rawget(quest(c[1]), c[2])

		lu.assertEquals(#got, c[3], c[1] .. ": " .. c[2] .. " lists")

		for i = 1, c[3] do
			lu.assertEquals(got[i], rec:list("attackShips" .. i), c[1] .. ": " .. c[2] .. "[" .. i .. "]")
		end
	end

	local rec, got = fixtureOf(J4.DUTIES[1]), quest(J4.DUTIES[1]).shipTypes

	for i = 1, 4 do
		lu.assertEquals(got[i], rec:list("shipType" .. i), J4.DUTIES[1] .. ": shipTypes[" .. i .. "]")
	end
end

-- Data mapping 1: assassinate targets and escorts, forces and escorts from the .tab columns
function TestInquisitionT4Conformance:test_assassinates_forces_and_escorts_come_from_the_tab_columns()
	for _, g in ipairs({ J4.M3[3], J4.M4[3], J4.M4[4] }) do
		local rec, q = fixtureOf(g), quest(g)

		lu.assertEquals(q.assassinateSpawns.target, rec:get("targetShipType"), g .. ": target")
		lu.assertEquals(q.assassinateSpawns.escorts, rec:list("targetEscort"), g .. ": escorts (SWG order)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), g .. ": arrivalDelay")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, g .. ": mustDestroyEscort")
	end

	for _, g in ipairs({ J4.M2[4], J4.M4[2] }) do
		lu.assertEquals(quest(g).escortShips, fixtureOf(g):list("targetEscort"), g .. ": escortShips")
	end

	local b, rec = quest(J4.M4[5]), fixtureOf(J4.M4[5])

	lu.assertEquals({ b.allyForce, b.enemyForce }, { rec:list("allyForce"), rec:list("enemyForce") }, "battle 4_d: forces in SWG order")
	lu.assertEquals(b.allyForce, { "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4", "imp_tie_interceptor_tier4" },
		"battle 4_d: the ally force (3 fighters, 4 interceptors)")
	lu.assertEquals(b.enemyForce[1], "coynite_coynfury_tier4", "battle 4_d: the Coynfury leads the enemy force")
end

---------------------------------------------------------------------------------------------
-- I-11: the inspect cargo
---------------------------------------------------------------------------------------------

TestInquisitionT4Cargo = {}

function TestInquisitionT4Cargo:setUp() H.reset() end

-- I-11, FJ-6
function TestInquisitionT4Cargo:test_the_ship_template_file_carries_the_quest_cargo_as_a_cargo_string()
	local t = H.shipTemplate(J4.INSPECT_SHIP)

	lu.assertNotNil(t, J4.SHIP_FILE .. " registers a template")
	lu.assertEquals(t.cargoString, J4.CARGO, J4.INSPECT_SHIP .. ": cargoString (read from the real template)")
	lu.assertEquals(t.cargoString, quest(J4.M1[2]).cargo, "the template cargo equals inspect 1_a's cargo")
	lu.assertEquals(t.questLoot, J4.CARGO, J4.INSPECT_SHIP .. ": questLoot stays")
end
