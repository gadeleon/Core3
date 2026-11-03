-- Smuggler tier 1 (Dravis): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of smuggler_tier1_data.lua, never the
-- Core3 tables under test. The first test class (TestSmugglerT1Oracle) derives every mapped field from the fixtures and requires the spec
-- literals to equal it, so a wrong spec literal fails there; it needs no production code and is green from the start.

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local R = require("surprise_replay")

S.load()

local function quest(global) return S.quest(global) end

local function fixtureOf(global)
	local id = S.IDENTITY[global]

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

local function trunc(v) return v >= 0 and math.floor(v) or -math.floor(-v) end

---------------------------------------------------------------------------------------------
-- The oracle itself: spec literals versus the SWG-Source fixtures and the Core3 point files
---------------------------------------------------------------------------------------------

TestSmugglerT1Oracle = {}

function TestSmugglerT1Oracle:setUp() H.reset() end

-- The table of a global as the Data mapping derives it from its fixture: only the fields the fixture decides
local function derive(global)
	local rec = fixtureOf(global)
	local id = S.IDENTITY[global]
	local out = { questZone = rec:get("questZone") }

	if id.type == "patrol" then
		local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

		out.patrolPoints = {}

		for i, p in ipairs(pointsOf(rec, "navPoints")) do
			out.patrolPoints[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
		end

		out.sideQuestPatrolStart = rec:num("triggerOn")
		out.sideQuestDelay = rec:num("triggerDelay")
		out.sideQuestType, out.sideQuestName = splitType, splitName
	elseif id.type == "destroy_surpriseattack" then
		out.surpriseAttackShips = { zone = rec:get("questZone"), spawns = R.runs(R.replay(id.name)) }
	elseif id.type == "destroy" then
		out.shipTypes = rec:list("shipList")
		out.killsRequired = rec:num("killCount")
		out.shipLocations = {}

		for _, value in ipairs(rec:list("validSpawns")) do
			local zone, spawnName = H.Tab.splitNavPoint(value)

			-- FS-8: blacksun_guards_2 exists in neither the SWG buildout nor the Core3 spawner table, so it is dropped
			if spawnName ~= "blacksun_guards_2" then
				local sp = H.spawners(zone)[spawnName]

				out.shipLocations[#out.shipLocations + 1] = { spawnName = spawnName, x = sp.x, z = sp.z, y = sp.y }
			end
		end
	elseif id.type == "escort" or id.type == "escort_duty" then
		local shipsColumn = id.type == "escort" and "escortShipType" or "escortShipTypes"
		local pathColumn = id.type == "escort" and "escortPath" or "escortPoints"
		local m = math.max(rec:num("numResponses") or 0, 1)

		out.escortShips = rec:list(shipsColumn)
		out.escortPoints = {}

		for i, p in ipairs(pointsOf(rec, pathColumn)) do
			out.escortPoints[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		out.attackDelay = rec:num("attackPeriod")
		out.attackShips = attackLists(rec)
		out.tauntData = { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }

		if id.type == "escort_duty" then
			out.creditReward = rec:num("reward")
			out.creditKillBonus = rec:num("killReward")
		end
	elseif id.type == "assassinate" then
		out.targetPatrols = {}

		for i, p in ipairs(pointsOf(rec, "escortPath")) do
			out.targetPatrols[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
		end

		out.assassinateSpawns = { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }
		out.arrivalDelay = rec:num("targetArrivalDelay")
		out.mustDestroyEscort = rec:num("mustDestroyEscort") == 1
	elseif id.type == "destroy_duty" then
		out.totalWaves = rec:num("wavesPerRound")
		out.totalRounds = rec:num("roundsPerLevel")
		out.totalLevels = rec:num("levelsPerDuty")
		out.bossShip = rec:get("bossType")
		out.creditReward = rec:num("reward")
		out.shipTypes = {}

		for i = 1, rec:num("shipTypes") do
			out.shipTypes[i] = rec:list("shipType" .. i)
		end
	elseif id.type == "recovery_duty" then
		out.recoverShip = rec:list("targetShipTypes")[1]
		out.arrivalDelay = rec:num("targetArrivalDelay")
		out.recoveryDelay = rec:num("targetRecoverTime")
		out.escortShips = rec:list("targetEscort")
		out.preRecoveryPoints, out.recoveryPoints = {}, {}

		for i, p in ipairs(pointsOf(rec, "escortPath")) do
			out.preRecoveryPoints[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		for i, p in ipairs(pointsOf(rec, "recoveryPath")) do
			out.recoveryPoints[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		out.attackShips = attackLists(rec)
		out.attackDelay = rec:num("attackPeriod")
		out.creditReward = rec:num("reward")
		out.creditKillBonus = rec:num("killReward")
		out.numResponses = rec:num("numResponses")
		out.tauntData = { panicCount = rec:num("numResponses"), thanksCount = rec:num("numResponses") }
	end

	return out
end

S.derive = derive

-- AC-2 (the oracle itself): every field the fixture decides is the spec literal
function TestSmugglerT1Oracle:test_the_spec_literals_equal_the_values_derived_from_the_swg_fixtures()
	local want = S.expected()

	for _, global in ipairs(S.GLOBALS) do
		for key, value in pairs(derive(global)) do
			lu.assertEquals(want[global][key], value, S.IDENTITY[global].type .. "/" .. S.IDENTITY[global].name .. ": " .. key .. " (spec literal versus the .tab)")
		end
	end
end

-- AC-2 (the oracle itself): the fixture facts the spec relies on, as anchors so a misparsed fixture cannot make a wrong table look right
function TestSmugglerT1Oracle:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = fixtureOf(S.P1)

	lu.assertEquals({ p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg") },
		{ { "space_tatooine:blacksun_patrol_1", "space_tatooine:blacksun_patrol_2", "space_tatooine:blacksun_patrol_3" }, 2, 20, "destroy_surpriseattack:tatooine_privateer_1" }, "patrol/tatooine_privateer_1")

	lu.assertEquals(R.replay("tatooine_privateer_1"), { "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier1", "blacksun_fighter_s01_tier1" }, "destroy_surpriseattack/tatooine_privateer_1: 3 fighters")

	local d2 = fixtureOf(S.M2)

	lu.assertEquals({ #d2:list("shipList"), d2:num("killCount"), #d2:list("validSpawns"), d2:list("validSpawns")[1] },
		{ 32, 4, 5, "space_tatooine:blacksun_guards_2" }, "destroy/tatooine_privateer_2 (blacksun_guards_2 is the first of five spawners)")

	local p3 = fixtureOf(S.P3)

	lu.assertEquals({ #p3:list("navPoints"), p3:num("triggerOn"), p3:num("triggerDelay"), p3:get("triggerArg") }, { 4, 2, 20, "escort:tatooine_privateer_3" }, "patrol/tatooine_privateer_3")

	local e3 = fixtureOf(S.E3)

	lu.assertEquals({ e3:get("escortShipType"), #e3:list("escortPath"), e3:num("numAttackShipLists"), e3:num("attackPeriod"), e3:get("attackListType"), e3:num("numResponses") },
		{ "hutt_freighterlight_tier1", 4, 2, 90, "sequential", 2 }, "escort/tatooine_privateer_3")

	local a4 = fixtureOf(S.A4)

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "blacksun_ace_s04_tier1", 12, 7, { "blacksun_fighter_s03_tier1", "blacksun_fighter_s02_tier1" }, 1 }, "assassinate/tatooine_privateer_tier1_4a")

	local d6 = fixtureOf(S.DUTY6)

	lu.assertEquals({ d6:num("wavesPerRound"), d6:num("roundsPerLevel"), d6:num("levelsPerDuty"), d6:num("shipTypes"), d6:get("bossType"), d6:num("reward") },
		{ 2, 2, 2, 3, "blacksun_marauder_tier2", 100 }, "destroy_duty/tatooine_privateer_6")

	local d8 = fixtureOf(S.DUTY8)

	lu.assertEquals({ d8:num("wavesPerRound"), d8:num("roundsPerLevel"), d8:num("levelsPerDuty"), d8:num("shipTypes"), d8:get("bossType"), d8:num("reward") },
		{ 2, 2, 2, 4, "blacksun_ace_s04_tier1", 100 }, "destroy_duty/tatooine_privateer_8")

	local r5 = fixtureOf(S.DUTY5)

	lu.assertEquals({ r5:list("targetShipTypes"), r5:num("targetArrivalDelay"), r5:num("targetRecoverTime"), #r5:list("escortPath"), #r5:list("recoveryPath"), r5:num("numAttackShipLists"), r5:num("attackPeriod"),
		r5:num("numResponses"), r5:num("reward"), r5:num("killReward") }, { { "valarian_freighterlight_mining_tier1" }, 35, 18, 5, 3, 3, 100, 2, 1000, 100 }, "recovery_duty/tatooine_privateer_5")

	local e7 = fixtureOf(S.DUTY7)

	lu.assertEquals({ e7:list("escortShipTypes"), #e7:list("escortPoints"), e7:num("numAttackShipLists"), e7:num("attackPeriod"), e7:num("numResponses"), e7:num("reward"), e7:num("killReward") },
		{ { "hutt_freightermedium_tier1", "hutt_freighterheavy_tier1" }, 3, 2, 90, 2, 1000, 100 }, "escort_duty/tatooine_privateer_7")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestSmugglerT1Oracle:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for name, xyz in pairs(S.POINTS) do
		local p = point("space_tatooine", name)

		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_tatooine patrol point " .. name)
	end

	for name, xyz in pairs(S.SPAWNERS) do
		local s = H.spawners("space_tatooine")[name]

		lu.assertNotNil(s, "space_tatooine spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "space_tatooine spawner " .. name)
	end

	lu.assertEquals(#sortedKeys(S.POINTS), 19, "nav points the ten tables use (the spec says 18; its own table lists 19)")
	lu.assertEquals(#sortedKeys(S.SPAWNERS), 4, "spec spawners")
end

-- I-2 (the oracle itself): the buildout excerpt holds exactly the 19 nav points and 4 spawners, and Core3's points are its truncated values
function TestSmugglerT1Oracle:test_the_buildout_excerpt_pins_every_point_and_spawner_of_the_tables()
	local tab = H.fixture("space_zones/buildout/space_tatooine.smuggler_tier1_points.tab")
	local navs, spawners = {}, {}

	for _, rec in ipairs(tab.records) do
		local vars = rec:get("strObjVars") or ""
		local nav = vars:match("nav_name|4|([^|]+)|")
		local spawn = vars:match("strSpawnerName|4|([^|]+)|")
		local xyz = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }

		if nav ~= nil then
			navs[nav] = xyz
		elseif spawn ~= nil then
			spawners[spawn] = xyz
		end
	end

	lu.assertEquals(sortedKeys(navs), sortedKeys(S.POINTS), "nav_name rows of the excerpt")
	lu.assertEquals(sortedKeys(spawners), sortedKeys(S.SPAWNERS), "strSpawnerName rows of the excerpt")

	for name, xyz in pairs(S.POINTS) do
		lu.assertEquals(xyz, navs[name], "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end

	for name, xyz in pairs(S.SPAWNERS) do
		lu.assertEquals(xyz, spawners[name], "buildout fltPX/fltPY/fltPZ truncated, spawner " .. name)
	end
end

-- I-3 (the oracle itself): the spec says 38 distinct ships and 3 items; its own literals agree, and every ship has a template file
function TestSmugglerT1Oracle:test_the_spec_literals_name_38_ships_that_all_have_template_files()
	local ships, items = {}, {}

	local function walk(value)
		if type(value) == "string" then
			ships[value] = true
		elseif type(value) == "table" then
			for _, v in ipairs(value) do
				walk(v)
			end
		end
	end

	for _, t in pairs(S.expected()) do
		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes", "bossShip", "recoverShip" }) do
			walk(t[field])
		end

		for _, entry in ipairs(t.itemReward or {}) do
			items[entry.item] = true
		end

		for _, spawn in ipairs((t.surpriseAttackShips or {}).spawns or {}) do
			ships[spawn.shipName] = true
		end

		if t.assassinateSpawns then
			ships[t.assassinateSpawns.target] = true
			walk(t.assassinateSpawns.escorts)
		end
	end

	lu.assertEquals(#sortedKeys(ships), 38, "distinct ships in the spec literals")
	lu.assertEquals(#sortedKeys(items), 3, "distinct items in the spec literals")

	for _, name in ipairs(sortedKeys(ships)) do
		lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua")
	end

	for _, path in ipairs(sortedKeys(items)) do
		lu.assertNotNil(readFile(H.SCRIPTS .. path:gsub("%.iff$", ".lua")), path)
	end
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script
function TestSmugglerT1Oracle:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_1.java")

	lu.assertNotNil(java, "fixtures/script/conversation/tatooine_privateer_trainer_1.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.patrol_tatooine_privateer_1, { { 100, nil } }, "J rewardForQuestOne")
	lu.assertEquals(found.destroy_tatooine_privateer_2, { { 200, nil } }, "J rewardForQuestTwo")
	lu.assertEquals(found.patrol_tatooine_privateer_3, { { 500, S.HUMAN_BANDOLIER }, { 500, S.ITHORIAN_BANDOLIER } }, "J rewardForQuestThree (non-Ithorian, then Ithorian)")
	lu.assertEquals(found.assassinate_tatooine_privateer_tier1_4a, { { 1000, S.BLASTER } }, "J rewardForQuestFour")

	local want = S.expected()

	lu.assertEquals(want[S.P1].creditReward, 100, "spec literal: mission 1")
	lu.assertEquals(want[S.M2].creditReward, 200, "spec literal: mission 2")
	lu.assertEquals(want[S.P3].creditReward, 500, "spec literal: mission 3")
	lu.assertEquals(want[S.A4].creditReward, 1000, "spec literal: mission 4")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestSmugglerT1Wiring = {}

function TestSmugglerT1Wiring:setUp() H.reset() end

-- AC-1
function TestSmugglerT1Wiring:test_the_squadron_file_registers_the_ten_quests_with_start_true()
	for _, global in ipairs(S.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestSmugglerT1Wiring:test_the_ten_globals_follow_the_squadron_require_in_the_contract_order()
	local text = readFile(H.SCRIPTS .. S.SQUADRON_FILE)

	lu.assertNotNil(text, S.SQUADRON_FILE)
	lu.assertNotNil(text:find('local SpaceHelpers = require("utils.space_helpers")', 1, true), S.SQUADRON_FILE .. ': starts with local SpaceHelpers = require("utils.space_helpers")')

	local last = 0

	for _, global in ipairs(S.GLOBALS) do
		local at = text:find("\n" .. global .. " = ", 1, true)

		lu.assertNotNil(at, S.SQUADRON_FILE .. ": no global " .. global)
		lu.assertTrue(at > last, S.SQUADRON_FILE .. ": " .. global .. " is out of the Content contract 1 order")
		last = at
		lu.assertNotNil(text:find('registerScreenPlay("' .. global .. '", true)', 1, true), S.SQUADRON_FILE .. ": registerScreenPlay for " .. global)
	end
end

-- AC-1
function TestSmugglerT1Wiring:test_the_squadron_screenplay_is_registered_without_start_and_has_the_section_2_constants()
	local sq = H.expectGlobal("SmugglerSquadronScreenplay", "squadron screenplay object. Load problems: " .. table.concat(S.loadErrors, " | "))

	lu.assertNotNil(H.registered("SmugglerSquadronScreenplay"), "SmugglerSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("SmugglerSquadronScreenplay").start, "SmugglerSquadronScreenplay: registered with start = false")
	lu.assertEquals(sq.screenplayName, "SmugglerSquadronScreenplay", "screenplayName")
	lu.assertEquals(type(sq.start), "function", "SmugglerSquadronScreenplay:start")
	lu.assertEquals(pcall(sq.start, sq), true, "SmugglerSquadronScreenplay:start runs")

	for field, want in pairs(S.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "SmugglerSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.MET_DRAVIS_KEY, S.MET_DRAVIS_KEY, "SmugglerSquadronScreenplay.MET_DRAVIS_KEY")
	lu.assertEquals(type(sq.resetDravisQuests), "function", "SmugglerSquadronScreenplay:resetDravisQuests")
	lu.assertEquals(pcall(sq.resetDravisQuests, sq, nil), true, "resetDravisQuests(nil) returns early")
end

-- AC-1
function TestSmugglerT1Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	S.requireConversation(lu)

	local t = H.conversationTemplateTable(S.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, S.HANDLER, S.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", S.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, S.HANDLER).getInitialScreen), "function", S.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, S.HANDLER).runScreenHandlers), "function", S.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, S.HANDLER).getNextConversationScreen), "function", S.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestSmugglerT1Wiring:test_dravis_uses_the_template_and_has_the_conversable_invulnerable_mask()
	local npc = H.loadCreatureTemplate("space/dravis.lua", "dravis")

	lu.assertNotNil(npc, "mobile/space/dravis.lua registers dravis")
	lu.assertEquals(npc.conversationTemplate, "dravis_convo_template", "dravis: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "dravis: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "dravis: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "dravis: optionsBitmask (the Rhea/Dinge mask)")
end

-- AC-1
function TestSmugglerT1Wiring:test_the_template_include_line_is_uncommented_exactly_once_under_the_smuggler_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/neutral/smuggler_squadron/dravis_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented dravis_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented dravis_convo include")

	local comment = text:find("-- Smuggler Squadron", 1, true)
	local include = text:find("conversations/space/neutral/smuggler_squadron/dravis_convo.lua", 1, true)

	lu.assertNotNil(comment, "space_conversations.lua: the '-- Smuggler Squadron' comment")
	lu.assertTrue(include ~= nil and include > comment, "space_conversations.lua: the include sits after '-- Smuggler Squadron'")

	local nextComment = text:find("\n%s*%-%- [%a ]+Squadron", comment + 1)

	lu.assertTrue(nextComment == nil or include < nextComment, "space_conversations.lua: the include sits under '-- Smuggler Squadron', before the next squadron comment")
end

-- AC-1
function TestSmugglerT1Wiring:test_the_handler_include_line_follows_the_squadron_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/neutral/smuggler_squadron/dravisConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented dravisConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented dravisConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/SmugglerSquadronScreenplay.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: the SmugglerSquadronScreenplay include")
	lu.assertEquals(lines[at + 1], "", "screenplays.lua: a blank line after the squadron include")
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua")', "screenplays.lua: the handler include, directly after the blank line")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestSmugglerT1Tables = {}

function TestSmugglerT1Tables:setUp() H.reset() end

-- AC-2, I-1
function TestSmugglerT1Tables:test_the_ten_tables_keep_their_identity_and_zone()
	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)
		local id = S.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_tatooine", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestSmugglerT1Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	lu.assertEquals(type(SPECIES_ITHORIAN), "number", "precondition: SPECIES_ITHORIAN is a harness constant")

	local want = S.expected()

	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2, I-6: only the two patrols split; the children name their patrol
function TestSmugglerT1Tables:test_only_the_two_patrols_split_both_at_point_2_after_20_seconds()
	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, global == S.P1 or global == S.P3, global .. ": sideQuest")
	end

	for _, g in ipairs({ S.P1, S.P3 }) do
		local q = quest(g)

		lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, g .. ": sideQuestSplitType")
		lu.assertEquals({ q.sideQuestPatrolStart, q.sideQuestDelay }, { 2, 20 }, g .. ": sideQuestPatrolStart, sideQuestDelay (the .tab triggerOn / triggerDelay)")
	end

	lu.assertEquals({ quest(S.P1).sideQuestType, quest(S.P1).sideQuestName }, { "destroy_surpriseattack", "tatooine_privateer_1" }, S.P1 .. ": the child")
	lu.assertEquals({ quest(S.P3).sideQuestType, quest(S.P3).sideQuestName }, { "escort", "tatooine_privateer_3" }, S.P3 .. ": the child")
	lu.assertEquals({ quest(S.S1).parentQuest, quest(S.S1).parentQuestType, quest(S.S1).parentQuestName }, { S.P1, "patrol", "tatooine_privateer_1" }, S.S1 .. ": parent fields")
	lu.assertEquals({ quest(S.E3).parentQuest, quest(S.E3).parentQuestType, quest(S.E3).parentQuestName }, { S.P3, "patrol", "tatooine_privateer_3" }, S.E3 .. ": parent fields")
end

-- AC-2, I-5: credits and items sit on the chain heads and the four duties
function TestSmugglerT1Tables:test_credits_and_items_sit_on_the_heads_and_the_children_pay_nothing()
	local pays = { [S.P1] = 100, [S.M2] = 200, [S.P3] = 500, [S.A4] = 1000, [S.DUTY6] = 100, [S.DUTY5] = 1000, [S.DUTY8] = 100, [S.DUTY7] = 1000 }

	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if global ~= S.P3 and global ~= S.A4 then
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(rawget(quest(S.S1), "creditReward") or 0, 0, S.S1 .. ": the surprise attack pays no credits")
	lu.assertEquals(rawget(quest(S.E3), "creditReward") or 0, 0, S.E3 .. ": the escort pays no credits")
end

-- AC-2, I-5: mission 3 lists the Ithorian bandolier first, then the catch-all
function TestSmugglerT1Tables:test_mission_3_items_are_ithorian_then_the_catch_all_bandolier_in_that_order()
	lu.assertEquals(quest(S.P3).itemReward, {
		{ species = { SPECIES_ITHORIAN }, item = S.ITHORIAN_BANDOLIER },
		{ species = { -1 }, item = S.HUMAN_BANDOLIER },
	}, S.P3 .. ": itemReward")
	lu.assertEquals(quest(S.A4).itemReward, { { species = { -1 }, item = S.BLASTER } }, S.A4 .. ": itemReward")
end

-- I-3: every ship the tables name has a ship template and every item an object template
function TestSmugglerT1Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes" }) do
			walk(rawget(q, field), ships)
		end

		walk(rawget(q, "bossShip"), ships)
		walk(rawget(q, "recoverShip"), ships)

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end
	end

	for _, spawn in ipairs(quest(S.S1).surpriseAttackShips.spawns) do
		ships[spawn.shipName] = true
	end

	ships[quest(S.A4).assassinateSpawns.target] = true
	walk(quest(S.A4).assassinateSpawns.escorts, ships)

	lu.assertEquals(#sortedKeys(ships), 38, "distinct ships in the 10 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 3, "distinct items in the 10 tables: " .. table.concat(sortedKeys(items), ", "))

	for _, name in ipairs(sortedKeys(ships)) do
		local f = io.open(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua", "r")

		lu.assertNotNil(f, "ship_mobile/ships/" .. name .. ".lua does not exist")
		f:close()
	end

	for _, path in ipairs(sortedKeys(items)) do
		local f = io.open(H.SCRIPTS .. path:gsub("%.iff$", ".lua"), "r")

		lu.assertNotNil(f, path .. ": no object template under bin/scripts")
		f:close()
	end
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestSmugglerT1Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(S.GLOBALS) do
		local id = S.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4): production versus the derived values
---------------------------------------------------------------------------------------------

TestSmugglerT1Conformance = {}

function TestSmugglerT1Conformance:setUp() H.reset() end

-- AC-2, I-4: every field the fixture decides, for every table (the table-driven core of the conformance)
function TestSmugglerT1Conformance:test_every_mapped_field_of_every_table_equals_the_value_derived_from_its_fixture()
	for _, global in ipairs(S.GLOBALS) do
		local q = quest(global)
		local label = S.IDENTITY[global].type .. "/" .. S.IDENTITY[global].name

		for key, value in pairs(derive(global)) do
			lu.assertEquals(rawget(q, key), value, label .. ": " .. key)
		end
	end
end

-- AC-2, I-4: destroy_surpriseattack/tatooine_privateer_1.tab by the replay of SWG's spawn loop
function TestSmugglerT1Conformance:test_surprise_attack_1_equals_the_replay_of_the_swg_spawn_loop()
	lu.assertEquals(quest(S.S1).surpriseAttackShips, { zone = "space_tatooine", spawns = R.runs(R.replay("tatooine_privateer_1")) },
		"destroy_surpriseattack/tatooine_privateer_1: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.runs(R.replay("tatooine_privateer_1")), { { count = 3, shipName = "blacksun_fighter_s01_tier1" } }, "the replay itself: 3 x blacksun_fighter_s01_tier1")
end

-- AC-2, I-2, FS-8: destroy 2 keeps four of the five spawners and all 32 ship cells
function TestSmugglerT1Conformance:test_destroy_2_drops_only_the_nonexistent_spawner_and_keeps_the_ship_list_verbatim()
	local q, rec = quest(S.M2), fixtureOf(S.M2)
	local names = {}

	for i, loc in ipairs(q.shipLocations) do
		names[i] = loc.spawnName
	end

	lu.assertEquals(names, { "blacksun_threat_2", "blacksun_pirates", "blacksun_n_stuff_1", "blacksun_threat_3" }, "destroy/tatooine_privateer_2: shipLocations names (no blacksun_guards_2)")
	lu.assertEquals(#q.shipTypes, 32, "destroy/tatooine_privateer_2: number of shipTypes")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), "destroy/tatooine_privateer_2: shipTypes (shipList, verbatim, duplicate kept)")
	lu.assertEquals(q.killsRequired, 4, "destroy/tatooine_privateer_2: killsRequired")
end

-- AC-2, I-2: assassinate 4 and recovery duty 5: the order of the path lists follows the .tab
function TestSmugglerT1Conformance:test_assassinate_4_and_recovery_duty_5_keep_the_tab_order_of_their_points()
	local names = {}

	for i, p in ipairs(quest(S.A4).targetPatrols) do
		names[i] = p.patrolPointName
	end

	lu.assertEquals(names, { "anchorhead_supply_patrol_1", "bestine_commerce_patrol_3", "bestine_security_patrol_2", "privateer_security_patrol_1", "imperial_escortduty_2", "blacksun_patrol_1", "anchorhead_armed_recon_1" },
		"assassinate/tatooine_privateer_tier1_4a: targetPatrols")

	local pre, rec = {}, {}

	for i, p in ipairs(quest(S.DUTY5).preRecoveryPoints) do
		pre[i] = p.patrolPointName
	end

	for i, p in ipairs(quest(S.DUTY5).recoveryPoints) do
		rec[i] = p.patrolPointName
	end

	lu.assertEquals(pre, { "anchorhead_supply_patrol_1", "bestine_security_escort_1", "bestine_security_patrol_2", "blacksun_patrol_3", "corellia_imperial_tier3_leg_4_assasinate_two_3" },
		"recovery_duty/tatooine_privateer_5: preRecoveryPoints")
	lu.assertEquals(rec, { "anchorhead_armed_recon_2", "privateer_security_patrol_3", "corellia_imperial_tier3_leg_4_assasinate_two_3" }, "recovery_duty/tatooine_privateer_5: recoveryPoints")
end

-- AC-2: the recovery duty's taunt data
function TestSmugglerT1Conformance:test_recovery_duty_5_has_two_panic_and_two_thanks_taunts()
	lu.assertEquals(quest(S.DUTY5).tauntData, { panicCount = 2, thanksCount = 2 }, "recovery_duty/tatooine_privateer_5: tauntData")
	lu.assertEquals(quest(S.DUTY5).numResponses, 2, "recovery_duty/tatooine_privateer_5: numResponses")
end

-- AC-2, I-1: the quest-type defaults stay: no table overrides the distances (as every earlier duty)
function TestSmugglerT1Conformance:test_destroy_duties_leave_the_distance_defaults_alone()
	for _, g in ipairs({ S.DUTY6, S.DUTY8 }) do
		lu.assertNil(rawget(quest(g), "minDistance"), g .. ": minDistance stays the type default")
		lu.assertNil(rawget(quest(g), "maxDistance"), g .. ": maxDistance stays the type default")
	end
end
