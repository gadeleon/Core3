-- Storm tier 2 part 3 (Field Commander Alozen): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Content contract 1, 2, 4; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of storm_tier2_alozen_data.lua, never the Core3 tables under
-- test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")

A.load()

local function quest(global) return A.quest(global) end

local function fixtureOf(global)
	local id = A.IDENTITY[global]

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

local function point(name)
	local p = H.patrolPoints("space_yavin4")[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in space_yavin4")
	return p
end

local function pointsOf(rec, column)
	local out = {}

	for i, value in ipairs(rec:list(column)) do
		local zone, name = H.Tab.splitNavPoint(value)
		local p = point(name)

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

local function label(global) return A.IDENTITY[global].type .. "/" .. A.IDENTITY[global].name end

local function linesOf(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

local function indexOf(lines, wanted)
	for i, l in ipairs(lines) do
		if l:gsub("^%s+", ""):gsub("%s+$", "") == wanted then
			return i
		end
	end
end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestAlozenFixtures = {}

function TestAlozenFixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the six fixtures carry the values the spec lists
function TestAlozenFixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local i4 = H.questFixture("inspect", "imperial_ss_4")

	lu.assertEquals({ i4:get("questZone"), i4:list("shipList"), i4:list("validSpawns"), i4:num("giveSpawnWaypoint"), i4:get("cargo"), i4:get("triggerEvent") },
		{ "space_yavin4", { "rebel_agent_tier3" }, { "space_yavin4:tatooine_imperial_tier2_inspect_rebagent" }, 1, "yavin_activity_log", "none" }, "inspect/imperial_ss_4")

	local e5 = H.questFixture("escort", "imperial_ss_5")

	lu.assertEquals({ e5:get("questZone"), e5:get("escortShipType"), #e5:list("escortPath"), e5:num("numAttackShipLists"), e5:list("attackShips1"), e5:list("attackShips2"), e5:num("attackPeriod"), e5:num("numResponses"),
		e5:get("triggerEvent") },
		{ "space_yavin4", "imperial_scan_freighter_tier2", 3, 2, { "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" }, { "reb_ywing_tier3", "reb_z95_tier2", "reb_z95_tier2" }, 120, 5, "none" },
		"escort/imperial_ss_5")

	local r6 = H.questFixture("recovery", "imperial_ss_6")

	lu.assertEquals({ r6:get("questZone"), r6:get("targetShipType"), r6:num("targetArrivalDelay"), r6:num("targetRecoverTime"), r6:list("targetEscort"), #r6:list("escortPath"), #r6:list("recoveryPath"),
		r6:num("numAttackShipLists"), r6:num("attackPeriod"), r6:num("numResponses"), r6:get("recoveryAppearance"), r6:get("triggerEvent") },
		{ "space_yavin4", "twilight_sun_tier1", 20, 30, { "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2" }, 3, 3, 2, 120, 5, "object/mobile/space_comm_imperial_ace_01.iff", "none" },
		"recovery/imperial_ss_6")

	local d2a = H.questFixture("destroy_duty", "lok_imperial_ss_2a")

	lu.assertEquals({ d2a:get("questZone"), d2a:num("wavesPerRound"), d2a:num("roundsPerLevel"), d2a:num("levelsPerDuty"), d2a:num("shipTypes"), d2a:list("shipType1"), d2a:list("shipType2"), d2a:get("bossType"), d2a:num("reward") },
		{ "space_yavin4", 3, 2, 5, 2, { "deathstar_debris_guardian_tier2", "deathstar_debris_guardian_tier2" }, { "deathstar_debris_fanatic_tier2", "deathstar_debris_fanatic_tier2" },
			"deathstar_debris_priest_tier3", 200 }, "destroy_duty/lok_imperial_ss_2a")

	local d2b = H.questFixture("recovery_duty", "lok_imperial_ss_2b")

	lu.assertEquals({ d2b:list("targetShipTypes"), d2b:num("targetArrivalDelay"), d2b:num("targetRecoverTime"), #d2b:list("targetEscort"), d2b:get("recoveryAppearance"), #d2b:list("escortPath"), #d2b:list("recoveryPath"),
		d2b:num("attackPeriod"), d2b:num("numResponses"), d2b:num("reward"), d2b:num("killReward") },
		{ { "deathstar_debris_freighter_tier2" }, 30, 60, 4, nil, 6, 6, 90, 5, 2500, 200 }, "recovery_duty/lok_imperial_ss_2b")

	local d2c = H.questFixture("escort_duty", "lok_imperial_ss_2c")

	lu.assertEquals({ d2c:list("escortShipTypes"), #d2c:list("escortPoints"), d2c:num("numAttackShipLists"), d2c:num("attackPeriod"), d2c:num("numResponses"), d2c:num("reward"), d2c:num("killReward") },
		{ { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }, 6, 2, 120, 5, 2500, 200 }, "escort_duty/lok_imperial_ss_2c")
end

-- AC-2, I-5 (the oracle itself): the Rebel agent's cargo table holds yavin_activity_log as its one transferable row
function TestAlozenFixtures:test_the_inspect_cargo_fixture_has_one_transferable_row_yavin_activity_log()
	local rows = H.fixture("spacequest/inspect_cargo/yavin_rebel.tab").records
	local transferable = {}

	for _, rec in ipairs(rows) do
		if rec:num("canTransfer") == 1 then
			transferable[#transferable + 1] = rec:get("name")
		end
	end

	lu.assertEquals(#rows, 3, "inspect_cargo/yavin_rebel.tab rows")
	lu.assertEquals(transferable, { "yavin_activity_log" }, "the rows with canTransfer 1")
end

-- I-2 (the oracle itself): the spec's point literals are what the patrol point file holds today
function TestAlozenFixtures:test_the_spec_points_equal_the_core3_patrol_point_file()
	local n = 0

	for name, xyz in pairs(A.POINTS) do
		local p = point(name)

		n = n + 1
		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_yavin4 patrol point " .. name)
	end

	lu.assertEquals(n, 27, "spec nav points")
end

-- I-2 (the oracle itself): the buildout excerpt holds exactly the 27 points and the spawner; Core3's points are their truncated values
function TestAlozenFixtures:test_the_buildout_excerpt_pins_every_point_and_the_inspect_spawner()
	local tab = H.fixture("space_zones/buildout/space_yavin4.storm_tier2_alozen_points.tab")
	local navs, spawners = {}, {}

	for _, rec in ipairs(tab.records) do
		local nav = (rec:get("strObjVars") or ""):match("nav_name|4|([^|]+)|")
		local spawner = (rec:get("strObjVars") or ""):match("strSpawnerName|4|([^|]+)|")

		if nav ~= nil then
			navs[nav] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		end

		if spawner ~= nil then
			spawners[spawner] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		end
	end

	lu.assertEquals(sortedKeys(navs), sortedKeys(A.POINTS), "nav_name rows of the excerpt")

	for name, xyz in pairs(A.POINTS) do
		lu.assertEquals(xyz, navs[name], "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end

	lu.assertEquals(spawners, { [A.SPAWNER.spawnName] = { A.SPAWNER.x, A.SPAWNER.z, A.SPAWNER.y } }, "the inspect spawner row (BOY:56)")
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestAlozenFixtures:test_the_client_quest_name_table_lists_the_six_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(A.GLOBALS) do
		local id = A.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

-- AC-6 (the oracle itself): the reward lines of the SWG trainer script (M1 J2b:267-274, M2 :279-286, M3 :323-330)
function TestAlozenFixtures:test_the_reward_literals_match_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_imperial_trainer_2b.java")

	lu.assertNotNil(java, "fixtures/script/conversation/tatooine_imperial_trainer_2b.java")

	local found = {}

	for line in (java .. "\n"):gmatch("([^\n]*)\n") do
		local questType, questName, credits, rest = line:match('space_quest%.giveReward%(player, "([^"]+)", "([^"]+)", (%d+)(.*)%)')

		if questType ~= nil then
			found[questType .. "_" .. questName] = { tonumber(credits), rest:match('^, "([^"]+)"') }
		end
	end

	lu.assertEquals(found["inspect_imperial_ss_4"] and found["inspect_imperial_ss_4"][1], 5000, "J2b M1 credits")
	lu.assertEquals(found["inspect_imperial_ss_4"] and found["inspect_imperial_ss_4"][2], A.ITEM, "J2b M1 item")
	lu.assertEquals(found["escort_imperial_ss_5"] and found["escort_imperial_ss_5"][1], 5000, "J2b M2 credits")
	lu.assertEquals(found["recovery_imperial_ss_6"] and found["recovery_imperial_ss_6"][1], 5000, "J2b M3 credits")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 75%.0f%)"), 1, "J2b pays +75 once (M1)")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 50%.0f%)"), 2, "J2b pays +50 twice (M2, M3)")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestAlozenWiring = {}

function TestAlozenWiring:setUp() H.reset() end

-- AC-1, I-1
function TestAlozenWiring:test_the_squadron_file_registers_the_six_quests_with_start_true()
	for _, global in ipairs(A.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestAlozenWiring:test_the_six_quests_are_registered_in_the_contract_order_after_the_six_oberhaur_quests()
	local order = {}

	for _, global in ipairs(T.GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(A.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- AC-1
function TestAlozenWiring:test_the_squadron_screenplay_has_the_section_2_constants_the_reset_and_every_earlier_field()
	local sq = A.squadron()

	for field, want in pairs(A.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field)
	end

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (Oberhaur, unchanged)")
	end

	for field, want in pairs(T.TIER1_QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, T.SERIES_SUFFIX, "SERIES_COMPLETE_KEY unchanged")
	lu.assertEquals(sq.TIER2_INITIATE_KEY, T.INITIATE_SUFFIX, "TIER2_INITIATE_KEY unchanged")
	lu.assertEquals(sq.TIER2_ALOZEN_KEY, T.ALOZEN_SUFFIX, "TIER2_ALOZEN_KEY unchanged")
	lu.assertEquals(sq.TRANSFER_FORM_SIGNATURE, T.SIGNATURE_KEY, "TRANSFER_FORM_SIGNATURE unchanged")
	lu.assertEquals(type(sq.resetColzetQuests), "function", "resetColzetQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetOberhaurQuests), "function", "resetOberhaurQuests (unchanged)")
	lu.assertEquals(type(sq.resetAlozenQuests), "function", "StormSquadronScreenplay:resetAlozenQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetAlozenQuests, sq, nil), true, "resetAlozenQuests(nil) returns early")
end

-- AC-1
function TestAlozenWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	A.requireConversation(lu)

	local t = H.conversationTemplateTable(A.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, A.HANDLER, A.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", A.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", A.TEMPLATE .. ": initialScreen")

	local h = rawget(_G, A.HANDLER)

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isOnMission", "canFlyNonTrackDuty", "tier2Count", "isPaid", "isReadyForTraining" }) do
		lu.assertEquals(type(h[fn]), "function", A.HANDLER .. ":" .. fn)
	end
end

-- AC-1
function TestAlozenWiring:test_alozen_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/alozen.lua", "alozen")

	lu.assertNotNil(npc, "mobile/space/alozen.lua registers alozen")
	lu.assertEquals(npc.conversationTemplate, "alozen_convo_template", "alozen: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "alozen: optionsBitmask (alozen.java, Oberhaur's and Barlow's mask)")
	lu.assertEquals(npc.creatureBitmask, PACK, "alozen: creatureBitmask unchanged")
	lu.assertEquals(npc.templates, { "object/mobile/space_imperial_tier2_tatooine_alozen.iff" }, "alozen: template unchanged")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:alozen", "alozen: the client name is kept (D-4)")
end

-- AC-1, D-13: the spawn row keeps its line, and gets the Imperial mood
function TestAlozenWiring:test_the_spawn_row_at_line_32_has_the_imperial_mood()
	local lines = linesOf(readFile(H.SCRIPTS .. A.SPAWN_FILE))

	lu.assertEquals(lines[32], '\t\t{"alozen", 300, 0.003, 0.125, -5.558, 0, 8735518, "npc_imperial"},', "yavin4_imperial_base.lua:32")
	lu.assertEquals(lines[33], '\t\t{"barlow", 60, 4028.91, 37, -6201.62, 150, 0, "npc_imperial"},', "yavin4_imperial_base.lua:33 (Barlow's row, unchanged but for the comma before Denner's row (storm-tier3-denner))")
end

-- AC-1
function TestAlozenWiring:test_the_template_include_line_is_uncommented_exactly_once_as_the_last_line_after_the_third_technicians()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/storm_squadron/alozen_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented alozen_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented alozen_convo include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua")')

	lu.assertNotNil(at, "space_conversations.lua: the nym_technician_3 include")
	lu.assertEquals(lines[at + 1] and lines[at + 1]:gsub("^%s+", ""), 'includeFile("conversations/space/imperial/storm_squadron/alozen_convo.lua")', "space_conversations.lua: Alozen's include directly after technician 3's")

	local last = #lines

	while last > 1 and lines[last]:gsub("%s+", "") == "" do
		last = last - 1
	end

	lu.assertEquals((tostring(lines[at + 2]):gsub("^%s+", "")), 'includeFile("conversations/space/imperial/storm_squadron/denner_convo.lua")', "space_conversations.lua: Denner's include directly after Alozen's (storm-tier3-denner)")
	lu.assertEquals(last, at + 2, "space_conversations.lua: Denner's include is the last line of the file (storm-tier3-denner)")
end

-- AC-1
function TestAlozenWiring:test_the_handler_include_line_follows_technician_3s_exactly_once_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/storm_squadron/alozenConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented alozenConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented alozenConvoHandler include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/nymTechnician3ConvoHandler.lua")')

	lu.assertNotNil(at, "screenplays.lua: technician 3's handler include")
	lu.assertEquals(lines[at + 1], 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")', "screenplays.lua: Alozen's handler include, directly after technician 3's")
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")', "screenplays.lua: Denner's handler include follows Alozen's (storm-tier3-denner)")
	lu.assertEquals(lines[at + 3], "", "screenplays.lua: the blank line follows Denner's include (storm-tier3-denner)")
	lu.assertEquals(lines[at + 4], "-- Master Trainers", "screenplays.lua: the Master Trainers block follows (storm-tier3-denner)")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-6)
---------------------------------------------------------------------------------------------

TestAlozenTables = {}

function TestAlozenTables:setUp() H.reset() end

-- AC-2, I-1
function TestAlozenTables:test_the_six_tables_keep_their_identity_and_zone()
	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)
		local id = A.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone (all six are space_yavin4, even the lok_ duties)")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestAlozenTables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = A.expected()

	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestAlozenTables:test_no_table_defines_a_function()
	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- AC-2, I-6: nothing splits, nothing has a parent
function TestAlozenTables:test_no_table_splits_or_has_a_parent()
	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, false, global .. ": sideQuest")
		lu.assertNil(rawget(q, "parentQuest"), global .. ": parentQuest")
		lu.assertNil(rawget(q, "sideQuestName"), global .. ": sideQuestName")
	end
end

-- AC-2, I-6: credits on the three heads, an item only on inspect 4, duty pay per .tab
function TestAlozenTables:test_credits_and_the_item_sit_where_the_contract_puts_them()
	local pays = { [A.M1] = 5000, [A.M2] = 5000, [A.M3] = 5000, [A.DUTY1] = 200, [A.DUTY2] = 2500, [A.DUTY3] = 2500 }

	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global], global .. ": creditReward")

		if global == A.M1 then
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = A.ITEM } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and the item an object template (16 ships, 1 item)
function TestAlozenTables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes", "shipList" }) do
			walk(rawget(q, field), ships)
		end

		for _, field in ipairs({ "recoverShip", "bossShip" }) do
			if rawget(q, field) then
				ships[q[field]] = true
			end
		end

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end
	end

	lu.assertEquals(#sortedKeys(ships), 16, "distinct ships in the 6 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(sortedKeys(items), { A.ITEM }, "items in the 6 tables")

	for _, name in ipairs(sortedKeys(ships)) do
		local f = io.open(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua", "r")

		lu.assertNotNil(f, "ship_mobile/ships/" .. name .. ".lua does not exist")

		if f then
			f:close()
		end
	end

	for _, path in ipairs(sortedKeys(items)) do
		local f = io.open(H.SCRIPTS .. path:gsub("%.iff$", ".lua"), "r")

		lu.assertNotNil(f, path .. ": no object template under bin/scripts")

		if f then
			f:close()
		end
	end
end

-- I-3: the recovery's conversation mobile is a client template the server knows
function TestAlozenTables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local q = quest(A.M3)
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertNotNil(text:find('"' .. tostring(q.recoveryConversationMobile) .. '"', 1, true), tostring(q.recoveryConversationMobile) .. " is not in object/mobile/objects.lua")
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestAlozenTables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")
	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(A.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestAlozenConformance = {}

function TestAlozenConformance:setUp() H.reset() end

-- recovery-style path: escortNumber = i, radius 250, no zoneName; numbered from 1
local function recoveryPath(q, rec, l, field, column)
	local out = {}

	for i, p in ipairs(pointsOf(rec, column)) do
		lu.assertEquals(p.zone, q.questZone, l .. ": " .. column .. " zone equals questZone")
		out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q[field], out, l .. ": " .. field .. " (" .. column .. ", no zoneName, numbered from 1)")
end

local function escortPoints(q, rec, l, column)
	local out = {}

	for i, p in ipairs(pointsOf(rec, column)) do
		out[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q.escortPoints, out, l .. ": escortPoints (" .. column .. ", zoneName, numbered from 1, radius 250)")
end

local function tauntsOf(rec, fields)
	local m = math.max(rec:num("numResponses") or 0, 1)
	local out = {}

	for _, f in ipairs(fields) do
		out[f] = m
	end

	return out
end

-- AC-2, I-4: inspect/imperial_ss_4.tab
function TestAlozenConformance:test_inspect_4_maps_ship_the_spawner_waypoint_flag_and_cargo()
	local q, rec = quest(A.M1), fixtureOf(A.M1)
	local l = label(A.M1)
	local zone, spawnName = H.Tab.splitNavPoint(rec:list("validSpawns")[1])
	local buildout = H.fixture("space_zones/buildout/space_yavin4.storm_tier2_alozen_points.tab")
	local at

	for _, r in ipairs(buildout.records) do
		if (r:get("strObjVars") or ""):find("strSpawnerName|4|" .. spawnName .. "|", 1, true) then
			at = { x = trunc(r:num("fltPX")), z = trunc(r:num("fltPY")), y = trunc(r:num("fltPZ")) }
		end
	end

	lu.assertNotNil(at, l .. ": the buildout excerpt has the spawner " .. spawnName)
	lu.assertEquals(zone, q.questZone, l .. ": the validSpawns zone is the quest zone")
	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(q.validSpawns, { { spawnName = spawnName, x = at.x, z = at.z, y = at.y } }, l .. ": validSpawns (zone prefix dropped, buildout position truncated)")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
end

-- AC-2, I-2, I-4: escort/imperial_ss_5.tab
function TestAlozenConformance:test_escort_5_maps_ship_points_attack_lists_delay_and_taunts()
	local q, rec = quest(A.M2), fixtureOf(A.M2)
	local l = label(A.M2)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.escortShips, { rec:get("escortShipType") }, l .. ": escortShips (escortShipType)")
	escortPoints(q, rec, l, "escortPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: recovery/imperial_ss_6.tab
function TestAlozenConformance:test_recovery_6_maps_ships_paths_attack_lists_appearance_and_taunts()
	local q, rec = quest(A.M3), fixtureOf(A.M3)
	local l = label(A.M3)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	recoveryPath(q, rec, l, "preRecoveryPoints", "escortPath")
	recoveryPath(q, rec, l, "recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")), l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-4: destroy_duty/lok_imperial_ss_2a.tab
function TestAlozenConformance:test_destroy_duty_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(A.DUTY1), fixtureOf(A.DUTY1)
	local l = label(A.DUTY1)
	local shipTypes = {}

	for i = 1, rec:num("shipTypes") do
		shipTypes[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), l .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), l .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), l .. ": totalLevels (levelsPerDuty)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
	lu.assertEquals(q.shipTypes, shipTypes, l .. ": shipTypes (shipType1..shipTypes)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
end

-- AC-2, I-2, I-4: recovery_duty/lok_imperial_ss_2b.tab
function TestAlozenConformance:test_recovery_duty_maps_ship_escorts_paths_taunts_and_pay()
	local q, rec = quest(A.DUTY2), fixtureOf(A.DUTY2)
	local l = label(A.DUTY2)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(#rec:list("targetShipTypes"), 1, l .. ": precondition: a single target cell")
	lu.assertEquals(q.recoverShip, rec:list("targetShipTypes")[1], l .. ": recoverShip (the one targetShipTypes cell)")
	lu.assertNil(rawget(q, "recoverShips"), l .. ": no recoverShips list for a single cell")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	recoveryPath(q, rec, l, "preRecoveryPoints", "escortPath")
	recoveryPath(q, rec, l, "recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertNil(rawget(q, "recoveryConversationMobile"), l .. ": no recoveryAppearance column, so recoveryConversationMobile is not set")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "panicCount", "thanksCount" }), l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: escort_duty/lok_imperial_ss_2c.tab
function TestAlozenConformance:test_escort_duty_maps_ships_path_attack_lists_delay_taunts_and_pay()
	local q, rec = quest(A.DUTY3), fixtureOf(A.DUTY3)
	local l = label(A.DUTY3)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes, in this order)")
	escortPoints(q, rec, l, "escortPoints")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.tauntData, tauntsOf(rec, { "goodbyeCount", "reasonCount", "tauntCount", "thanksCount" }), l .. ": tauntData (max(numResponses, 1))")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
end

---------------------------------------------------------------------------------------------
-- I-5: the Rebel agent's cargo, read from the real template file
---------------------------------------------------------------------------------------------

TestAlozenCargo = {}

function TestAlozenCargo:setUp() H.reset() end

local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	return (readFile(path):gsub("%-%-[^\n]*", ""))
end

-- AC-2, I-5
function TestAlozenCargo:test_the_rebel_agent_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	local q = quest(A.M1)

	lu.assertEquals(q.shipList, { "rebel_agent_tier3" }, "inspect 4 shipList")

	local src = templateSource("rebel_agent_tier3")
	local cargoString = src:match('cargoString%s*=%s*"(.-)"')
	local questLoot = src:match('questLoot%s*=%s*"(.-)"')

	lu.assertEquals(cargoString, q.cargo, "rebel_agent_tier3.lua cargoString must equal the quest cargo (SWG space_mobile.tab:1431 cargo table yavin_rebel)")
	lu.assertEquals(questLoot, "yavin_rebel", "rebel_agent_tier3.lua questLoot (names the inspect_cargo table) stays")

	local transferable = {}

	for _, rec in ipairs(H.fixture("spacequest/inspect_cargo/" .. questLoot .. ".tab").records) do
		if rec:get("name") == q.cargo then
			transferable[#transferable + 1] = rec:num("canTransfer")
		end
	end

	lu.assertEquals(transferable, { 1 }, "cargo is a canTransfer = 1 row of the table")
end

-- AC-2, I-5: the loaded template (what the server registers) has it too
function TestAlozenCargo:test_the_loaded_rebel_agent_template_has_the_cargo_string_and_keeps_its_loot_name()
	local t = H.shipTemplate("rebel_agent_tier3")

	lu.assertNotNil(t, "ship_mobile/ships/rebel_agent_tier3.lua registers a template")
	lu.assertEquals(t.cargoString, "yavin_activity_log", "rebel_agent_tier3: cargoString")
	lu.assertEquals(t.questLoot, "yavin_rebel", "rebel_agent_tier3: questLoot is unchanged")
end

return nil
