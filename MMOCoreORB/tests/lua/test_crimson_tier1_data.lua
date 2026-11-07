-- Crimson Phoenix Squadron tier 1 (Da'la Socuna): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of crimson_tier1_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local I = require("crimson_tier1_data")
local R = require("surprise_replay")

I.load()

local function quest(global) return I.quest(global) end

local function fixtureOf(global)
	local id = I.IDENTITY[global]

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

-- the data keys of a table: function-valued fields are not data
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
-- The oracle itself
---------------------------------------------------------------------------------------------

TestCrimsonT1Fixtures = {}

function TestCrimsonT1Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the eight fixtures carry the values the spec lists
function TestCrimsonT1Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = H.questFixture("patrol", "tatooine_rebel_1")

	lu.assertEquals({ p1:get("questZone"), p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg") },
		{ "space_tatooine", { "space_tatooine:anchorhead_supply_patrol_1", "space_tatooine:anchorhead_supply_patrol_2", "space_tatooine:anchorhead_supply_patrol_3" }, 2, 12, "destroy_surpriseattack:tatooine_rebel_1" }, "patrol/tatooine_rebel_1")

	local s1 = H.questFixture("destroy_surpriseattack", "tatooine_rebel_1")

	lu.assertEquals({ s1:list("shipType"), s1:list("shipCount") }, { { "imp_tie_fighter_tier1" }, { "3" } }, "destroy_surpriseattack/tatooine_rebel_1")

	local d3 = H.questFixture("destroy", "tatooine_rebel_3")

	lu.assertEquals({ d3:list("shipList"), d3:list("validSpawns"), d3:num("killCount"), d3:num("spawnsForWaypointsOnly") },
		{ { "imp_tie_fighter_tier1", "imp_tie_fighter_tier2", "imp_tie_fighter_tier3", "imp_tie_fighter_tier4", "imp_tie_fighter_tier2_tatooine" },
			{ "space_tatooine:anchorhead_tie_rally_alpha", "space_tatooine:imp_base_defense_03", "space_tatooine:imperial_base_guard_1", "space_tatooine:imperial_squad_1" }, 4, 1 }, "destroy/tatooine_rebel_3")

	local p2 = H.questFixture("patrol", "tatooine_rebel_2")

	lu.assertEquals({ p2:list("navPoints"), p2:num("triggerOn"), p2:num("triggerDelay"), p2:get("triggerArg") },
		{ { "space_tatooine:anchorhead_armed_recon_1", "space_tatooine:anchorhead_armed_recon_2", "space_tatooine:anchorhead_armed_recon_3" }, 2, 10, "escort:tatooine_rebel_2" }, "patrol/tatooine_rebel_2")

	local e2 = H.questFixture("escort", "tatooine_rebel_2")

	lu.assertEquals({ e2:get("escortShipType"), #e2:list("escortPath"), e2:num("numAttackShipLists"), e2:num("attackPeriod"), e2:num("numResponses") },
		{ "reb_freightermedium_tier1", 3, 1, 90, 5 }, "escort/tatooine_rebel_2")

	local a4 = H.questFixture("assassinate", "tatooine_rebel_4")

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "imp_tie_fighter_veteran_tier2", 10, 4, { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" }, 0 }, "assassinate/tatooine_rebel_4")

	local d6 = H.questFixture("destroy_duty", "tatooine_rebel_6")

	lu.assertEquals({ d6:num("wavesPerRound"), d6:num("roundsPerLevel"), d6:num("levelsPerDuty"), d6:num("shipTypes"), d6:get("bossType"), d6:num("reward") },
		{ 3, 2, 5, 1, "imp_tie_fighter_tier2", 100 }, "destroy_duty/tatooine_rebel_6")

	local e7 = H.questFixture("escort_duty", "tatooine_rebel_7")

	lu.assertEquals({ #e7:list("escortShipTypes"), #e7:list("escortPoints"), e7:num("numAttackShipLists"), e7:num("attackPeriod"), e7:num("numResponses"), e7:num("reward"), e7:num("killReward") },
		{ 3, 4, 1, 100, 5, 1000, 100 }, "escort_duty/tatooine_rebel_7")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestCrimsonT1Fixtures:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for name, xyz in pairs(I.POINTS) do
		local p = point("space_tatooine", name)

		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_tatooine patrol point " .. name)
	end

	for name, xyz in pairs(I.SPAWNERS) do
		local s = H.spawners("space_tatooine")[name]

		lu.assertNotNil(s, "space_tatooine spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "space_tatooine spawner " .. name)
	end

	lu.assertEquals(#sortedKeys(I.POINTS), 13, "spec nav points")
	lu.assertEquals(#sortedKeys(I.SPAWNERS), 4, "spec spawners")
end

-- I-2 (the oracle itself): the buildout excerpt holds exactly the 13 nav points and 4 spawners, and Core3's points are its truncated values
function TestCrimsonT1Fixtures:test_the_buildout_excerpt_pins_every_point_and_spawner_of_the_tables()
	local tab = H.fixture("space_zones/buildout/space_tatooine.crimson_phoenix_tier1_points.tab")
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

	lu.assertEquals(sortedKeys(navs), sortedKeys(I.POINTS), "nav_name rows of the excerpt")
	lu.assertEquals(sortedKeys(spawners), sortedKeys(I.SPAWNERS), "strSpawnerName rows of the excerpt")

	for name, xyz in pairs(I.POINTS) do
		lu.assertEquals(xyz, navs[name], "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end

	for name, xyz in pairs(I.SPAWNERS) do
		lu.assertEquals(xyz, spawners[name], "buildout fltPX/fltPY/fltPZ truncated, spawner " .. name)
	end
end

-- I-5 (the oracle itself): the reward amounts and items are the reward_quest actions of the SWG trainer script (J:283-330)
function TestCrimsonT1Fixtures:test_the_reward_literals_match_the_reward_actions_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_rebel_trainer_1.java")

	lu.assertNotNil(java, "fixtures/script/conversation/tatooine_rebel_trainer_1.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.destroy_surpriseattack_tatooine_rebel_1, { { 100, nil } }, "J reward M1 (SWG pays it on the surprise attack; Core3 pays it on the chain head)")
	lu.assertEquals(found.destroy_tatooine_rebel_3, { { 200, nil } }, "J reward M2")
	lu.assertEquals(#(found.escort_tatooine_rebel_2 or {}), 3, "J reward M3 pays on the escort, three species variants")

	local items = {}

	for i, entry in ipairs(found.escort_tatooine_rebel_2 or {}) do
		lu.assertEquals(entry[1], 500, "J reward M3 credits, variant " .. i)
		items[#items + 1] = entry[2]
	end

	table.sort(items)
	local wantItems = { I.WOOKIEE_BANDOLIER, I.ITHORIAN_BANDOLIER, I.SWG_FLIGHT_SUIT }

	table.sort(wantItems)
	lu.assertEquals(items, wantItems, "J reward M3 items (any order); the default is rebel_bodysuit_s14, the one named exception (D-9)")
	lu.assertEquals(found.assassinate_tatooine_rebel_4, { { 1000, I.ARMOR } }, "J reward M4")
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestCrimsonT1Fixtures:test_the_client_quest_name_table_lists_the_eight_quests()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(I.GLOBALS) do
		local id = I.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestCrimsonT1Wiring = {}

function TestCrimsonT1Wiring:setUp() H.reset() end

-- AC-1
function TestCrimsonT1Wiring:test_the_squadron_file_registers_the_eight_quests_with_start_true()
	for _, global in ipairs(I.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestCrimsonT1Wiring:test_the_eight_quests_are_registered_in_the_contract_order()
	local order = {}

	for _, global in ipairs(I.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- AC-1
function TestCrimsonT1Wiring:test_the_squadron_screenplay_is_registered_without_start_and_has_the_section_2_constants()
	I.load()
	quest(I.P1)

	local sq = I.squadron()

	lu.assertNotNil(H.registered("CrimsonPhoenixSquadronScreenplay"), "CrimsonPhoenixSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("CrimsonPhoenixSquadronScreenplay").start, "CrimsonPhoenixSquadronScreenplay: registered with start = false")
	lu.assertEquals(sq.screenplayName, "CrimsonPhoenixSquadronScreenplay", "screenplayName")
	lu.assertEquals(type(sq.start), "function", "CrimsonPhoenixSquadronScreenplay:start")
	lu.assertEquals(pcall(sq.start, sq), true, "CrimsonPhoenixSquadronScreenplay:start runs")

	for field, want in pairs(I.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "CrimsonPhoenixSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.EKER_PILOT_KEY, I.EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY")
	lu.assertEquals(type(sq.resetSocunaQuests), "function", "CrimsonPhoenixSquadronScreenplay:resetSocunaQuests")
	lu.assertEquals(pcall(sq.resetSocunaQuests, sq, nil), true, "resetSocunaQuests(nil) returns early")
end

-- AC-1
function TestCrimsonT1Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	I.requireConversation(lu)

	local t = H.conversationTemplateTable(I.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, I.HANDLER, I.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", I.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getInitialScreen), "function", I.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, I.HANDLER).runScreenHandlers), "function", I.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getNextConversationScreen), "function", I.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestCrimsonT1Wiring:test_da_la_socuna_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/da_la_socuna.lua", "da_la_socuna")

	lu.assertNotNil(npc, "mobile/space/da_la_socuna.lua registers da_la_socuna")
	lu.assertEquals(npc.conversationTemplate, "socuna_convo_template", "da_la_socuna: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "da_la_socuna: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "da_la_socuna: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "da_la_socuna: optionsBitmask (the Colzet / V3-FX mask)")
end

local function linesOf(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

-- AC-1: the template include sits uncommented at line 80 of space_conversations.lua, the other three Crimson Phoenix placeholders stay commented
function TestCrimsonT1Wiring:test_the_template_include_is_uncommented_at_line_80_and_the_other_three_stay_commented()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo%.lua"%)'), 1, "space_conversations.lua: socuna_convo include occurrences (commented or not)")
	lu.assertEquals(lines[80], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")', "space_conversations.lua line 80")

	lu.assertEquals(lines[79], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua")', "space_conversations.lua line 79: uncommented by crimson-phoenix-tier2-eker-convo")

	for _, n in ipairs({ 81, 82 }) do
		lu.assertTrue((lines[n] or ""):match("^%-%-%s*includeFile%(\"conversations/space/rebel/crimson_phoenix_squadron/[a-z_]+%.lua\"%)$") ~= nil, "space_conversations.lua line " .. n .. ": still a commented Crimson Phoenix placeholder" .. " (" .. tostring(lines[n]) .. ")")
	end
end

-- AC-1: the handler include sits uncommented at line 125 of screenplays.lua, the other three stay commented, no line moved
function TestCrimsonT1Wiring:test_the_handler_include_is_uncommented_at_line_125_and_the_other_three_stay_commented()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler%.lua"%)'), 1, "screenplays.lua: socunaConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[125], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")', "screenplays.lua line 125")

	lu.assertEquals(lines[124], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua")', "screenplays.lua line 124: uncommented by crimson-phoenix-tier2-eker-convo")

	for _, n in ipairs({ 126, 127 }) do
		lu.assertTrue((lines[n] or ""):match("^%-%-%s*includeFile%(\"space/conversations/rebel/crimson_phoenix_squadron/[A-Za-z]+ConvoHandler%.lua\"%)$") ~= nil, "screenplays.lua line " .. n .. ": still a commented Crimson Phoenix placeholder" .. " (" .. tostring(lines[n]) .. ")")
	end
end

-- Scope (broker check): the broker's waypoint names Da'la Socuna and the trainer that stands at the Mos Espa cantina is the one with the conversation
function TestCrimsonT1Wiring:test_the_broker_waypoint_and_the_spawn_name_the_same_trainer()
	I.load()

	local player = H.newPlayer({ name = "Ace" })

	SpaceHelpers:addCrimsonSquadWaypoint(player)

	local wp = player.ghost.waypoints[1]

	lu.assertNotNil(wp, "addCrimsonSquadWaypoint adds a waypoint")
	lu.assertEquals({ wp.planet, wp.name, wp.x, wp.z, wp.y }, { "tatooine", "@npc_spawner_n:da_la_socuna", -3002, 0, 2202 }, "the broker's Tatooine contact waypoint")

	local spawns = readFile(H.SCRIPTS .. "screenplays/cities/tatooine_mos_espa.lua")

	lu.assertNotNil(spawns:find('{"da_la_socuna",60,-29.7168,-0.519991,7.77728,54.7476,1256068, "conversation"}', 1, true), "tatooine_mos_espa.lua spawns da_la_socuna in the cantina with the conversation option")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestCrimsonT1Tables = {}

function TestCrimsonT1Tables:setUp() H.reset() end

-- AC-2, I-1
function TestCrimsonT1Tables:test_the_eight_tables_keep_their_identity_and_zone()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)
		local id = I.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_tatooine", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestCrimsonT1Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	lu.assertEquals(type(SPECIES_ITHORIAN), "number", "precondition: SPECIES_ITHORIAN is a harness constant")

	local want = I.expected()

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no table overrides a function
function TestCrimsonT1Tables:test_no_table_defines_a_function()
	for _, global in ipairs(I.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields (No table overrides a function)")
	end
end

-- AC-2, I-6
function TestCrimsonT1Tables:test_only_patrol_1_and_patrol_2_split_and_they_split_at_point_2_after_12_and_10_seconds()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, global == I.P1 or global == I.P3, global .. ": sideQuest")
	end

	local p1 = quest(I.P1)

	lu.assertEquals({ p1.sideQuestType, p1.sideQuestName }, { "destroy_surpriseattack", "tatooine_rebel_1" }, I.P1 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p1.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, I.P1 .. ": sideQuestSplitType")
	lu.assertEquals({ p1.sideQuestPatrolStart, p1.sideQuestDelay }, { 2, 12 }, I.P1 .. ": sideQuestPatrolStart, sideQuestDelay")

	local p3 = quest(I.P3)

	lu.assertEquals({ p3.sideQuestType, p3.sideQuestName }, { "escort", "tatooine_rebel_2" }, I.P3 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p3.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, I.P3 .. ": sideQuestSplitType")
	lu.assertEquals({ p3.sideQuestPatrolStart, p3.sideQuestDelay }, { 2, 10 }, I.P3 .. ": sideQuestPatrolStart, sideQuestDelay")

	local s1, e3 = quest(I.S1), quest(I.E3)

	lu.assertEquals({ s1.parentQuest, s1.parentQuestType, s1.parentQuestName }, { I.P1, "patrol", "tatooine_rebel_1" }, I.S1 .. ": parent fields")
	lu.assertEquals({ e3.parentQuest, e3.parentQuestType, e3.parentQuestName }, { I.P3, "patrol", "tatooine_rebel_2" }, I.E3 .. ": parent fields")
end

-- AC-2, I-5
function TestCrimsonT1Tables:test_credits_and_items_sit_on_the_heads_and_the_surprise_attack_and_escort_pay_nothing()
	local pays = { [I.P1] = 100, [I.M2] = 200, [I.P3] = 500, [I.A4] = 1000, [I.DUTY6] = 100, [I.DUTY7] = 1000 }

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if global ~= I.P3 and global ~= I.A4 then
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(rawget(quest(I.S1), "creditReward") or 0, 0, I.S1 .. ": the surprise attack pays no credits")
	lu.assertEquals(rawget(quest(I.E3), "creditReward") or 0, 0, I.E3 .. ": the escort pays no credits (Core3 pays on the patrol head)")
end

-- AC-2, I-5, I-4 (the named exception): the three species entries come in this order; the default item is bodysuit_s14, not SWG's rebel_bodysuit_s14
function TestCrimsonT1Tables:test_mission_3_items_are_wookiee_ithorian_then_the_flight_suit_with_the_named_substitution()
	lu.assertEquals(quest(I.P3).itemReward, {
		{ species = { SPECIES_WOOKIEE }, item = "object/tangible/wearables/bandolier/multipocket_bandolier.iff" },
		{ species = { SPECIES_ITHORIAN }, item = "object/tangible/wearables/bandolier/ith_multipocket_bandolier.iff" },
		{ species = { -1 }, item = "object/tangible/wearables/bodysuit/bodysuit_s14.iff" },
	}, I.P3 .. ": itemReward (D-9: SWG's rebel_bodysuit_s14.iff is in no pre-NGE archive and has no Core3 template, so the user's Havoc decision TR D-11 applies: bodysuit_s14)")

	local swg = io.open(H.SCRIPTS .. "object/tangible/wearables/bodysuit/rebel_bodysuit_s14.lua", "r")

	lu.assertNil(swg, "object/tangible/wearables/bodysuit/rebel_bodysuit_s14.lua exists: the D-9 substitution would no longer be needed")
end

-- I-3: every ship the tables name has a ship template and every item an object template (9 ships, 4 items)
function TestCrimsonT1Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes" }) do
			walk(rawget(q, field), ships)
		end

		walk(rawget(q, "bossShip"), ships)

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end
	end

	for _, spawn in ipairs(quest(I.S1).surpriseAttackShips.spawns) do
		ships[spawn.shipName] = true
	end

	ships[quest(I.A4).assassinateSpawns.target] = true
	walk(quest(I.A4).assassinateSpawns.escorts, ships)

	lu.assertEquals(#sortedKeys(ships), 9, "distinct ships in the 8 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 8 tables: " .. table.concat(sortedKeys(items), ", "))

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

-- Data mapping 1 (factions checked 2026-11-07): the tie fighters of the tables are Imperial ships hostile to Rebels
function TestCrimsonT1Tables:test_the_attackers_are_imperial_ships_that_fight_rebels()
	for _, name in ipairs({ "imp_tie_fighter_tier1", "imp_tie_fighter_veteran_tier2" }) do
		local t = H.shipTemplate(name)

		lu.assertEquals(t.spaceFaction, "imperial", name .. ": spaceFaction")

		local enemies = {}

		for _, f in ipairs(t.enemyFactions or {}) do
			enemies[f] = true
		end

		lu.assertTrue(enemies.rebel == true, name .. ": rebel is an enemy faction")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestCrimsonT1Conformance = {}

function TestCrimsonT1Conformance:setUp() H.reset() end

local function patrolConformance(global)
	local q, rec = quest(global), fixtureOf(global)
	local label = "patrol/" .. q.questName
	local points = {}

	for i, p in ipairs(pointsOf(rec, "navPoints")) do
		points[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
	end

	local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.patrolPoints, points, label .. ": patrolPoints (navPoints)")
	lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), label .. ": sideQuestPatrolStart (triggerOn)")
	lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), label .. ": sideQuestDelay (triggerDelay, kept on PATROL_POINT splits)")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, label .. ": sideQuestType, sideQuestName (triggerArg)")
end

-- AC-2, I-4: patrol/tatooine_rebel_1.tab
function TestCrimsonT1Conformance:test_patrol_1_maps_points_and_split_from_its_fixture()
	patrolConformance(I.P1)
end

-- AC-2, I-4: patrol/tatooine_rebel_2.tab
function TestCrimsonT1Conformance:test_patrol_2_maps_points_and_split_from_its_fixture()
	patrolConformance(I.P3)
end

-- AC-2, I-4: destroy_surpriseattack/tatooine_rebel_1.tab, by replaying SWG's spawn loop
function TestCrimsonT1Conformance:test_surprise_attack_1_equals_the_replay_of_the_swg_spawn_loop()
	local q = quest(I.S1)

	lu.assertEquals(q.surpriseAttackShips, { zone = H.questFixture("destroy_surpriseattack", "tatooine_rebel_1"):get("questZone"), spawns = R.runs(R.replay("tatooine_rebel_1")) },
		"destroy_surpriseattack/tatooine_rebel_1: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.replay("tatooine_rebel_1"), { "imp_tie_fighter_tier1", "imp_tie_fighter_tier1", "imp_tie_fighter_tier1" }, "the replay itself: 3 x imp_tie_fighter_tier1")
	lu.assertEquals(R.runs(R.replay("tatooine_rebel_1")), { { count = 3, shipName = "imp_tie_fighter_tier1" } }, "the runs")
end

-- AC-2, I-2, I-4: destroy/tatooine_rebel_3.tab
function TestCrimsonT1Conformance:test_destroy_3_maps_ships_kills_and_the_four_spawners()
	local q, rec = quest(I.M2), fixtureOf(I.M2)
	local label = "destroy/tatooine_rebel_3"

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), label .. ": shipTypes (shipList)")
	lu.assertEquals(#q.shipTypes, 5, label .. ": five ship types")
	lu.assertEquals(q.killsRequired, rec:num("killCount"), label .. ": killsRequired (killCount)")

	local spawns = rec:list("validSpawns")

	lu.assertEquals(#q.shipLocations, #spawns, label .. ": number of shipLocations")
	lu.assertEquals(#spawns, 4, label .. ": four valid spawns")

	for i, value in ipairs(spawns) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, label .. ": spawner " .. spawnName .. " in " .. zone)
		lu.assertEquals(zone, q.questZone, label .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.shipLocations[i], { spawnName = spawnName, x = s.x, z = s.z, y = s.y }, label .. ": shipLocations[" .. i .. "] (" .. spawnName .. ")")
	end
end

-- AC-2, I-2, I-4: escort/tatooine_rebel_2.tab and escort_duty/tatooine_rebel_7.tab
function TestCrimsonT1Conformance:test_escort_2_and_escort_duty_7_map_ships_path_attack_lists_delay_and_taunts()
	for _, global in ipairs({ I.E3, I.DUTY7 }) do
		local q, rec = quest(global), fixtureOf(global)
		local label = I.IDENTITY[global].type .. "/" .. q.questName
		local shipsColumn = global == I.E3 and "escortShipType" or "escortShipTypes"
		local pathColumn = global == I.E3 and "escortPath" or "escortPoints"
		local points = {}

		for i, p in ipairs(pointsOf(rec, pathColumn)) do
			points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
		lu.assertEquals(q.escortShips, rec:list(shipsColumn), label .. ": escortShips (" .. shipsColumn .. ")")
		lu.assertEquals(q.escortPoints, points, label .. ": escortPoints (" .. pathColumn .. ")")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), label .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), label .. ": attackShips (attackShips1..numAttackShipLists)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, label .. ": tauntData (max(numResponses, 1))")
	end

	local d7, rec = quest(I.DUTY7), fixtureOf(I.DUTY7)

	lu.assertEquals(d7.creditReward, rec:num("reward"), "escort_duty/tatooine_rebel_7: creditReward (reward)")
	lu.assertEquals(d7.creditKillBonus, rec:num("killReward"), "escort_duty/tatooine_rebel_7: creditKillBonus (killReward)")
	lu.assertEquals(quest(I.E3).attackDelay, 90, "escort/tatooine_rebel_2: attackDelay")
	lu.assertEquals(d7.attackDelay, 100, "escort_duty/tatooine_rebel_7: attackDelay")
	lu.assertEquals(#d7.escortPoints, 4, "escort_duty/tatooine_rebel_7: four escort points")
end

-- AC-2, I-2, I-4: assassinate/tatooine_rebel_4.tab
function TestCrimsonT1Conformance:test_assassinate_4_maps_target_escorts_delay_and_path()
	local q, rec = quest(I.A4), fixtureOf(I.A4)
	local label = "assassinate/tatooine_rebel_4"
	local path = {}

	for i, p in ipairs(pointsOf(rec, "escortPath")) do
		path[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
		lu.assertEquals(p.zone, q.questZone, label .. ": escortPath zone equals questZone")
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, label .. ": assassinateSpawns (targetShipType, targetEscort)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.targetPatrols, path, label .. ": targetPatrols (escortPath, in file order)")
	lu.assertEquals(#q.targetPatrols, 4, label .. ": four target patrol points")
	lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, label .. ": mustDestroyEscort")
	lu.assertEquals(q.failTimer, 20, label .. ": failTimer (Core3-only)")
end

-- AC-2, I-4: destroy_duty/tatooine_rebel_6.tab
function TestCrimsonT1Conformance:test_destroy_duty_6_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(I.DUTY6), fixtureOf(I.DUTY6)
	local label = "destroy_duty/tatooine_rebel_6"
	local shipTypes = {}

	for i = 1, rec:num("shipTypes") do
		shipTypes[i] = rec:list("shipType" .. i)
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), label .. ": totalWaves (wavesPerRound)")
	lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), label .. ": totalRounds (roundsPerLevel)")
	lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), label .. ": totalLevels (levelsPerDuty)")
	lu.assertEquals(q.bossShip, rec:get("bossType"), label .. ": bossShip (bossType)")
	lu.assertEquals(q.shipTypes, shipTypes, label .. ": shipTypes (shipType1..shipTypes)")
	lu.assertEquals(q.creditReward, rec:num("reward"), label .. ": creditReward (reward)")
	lu.assertNil(rawget(q, "minDistance"), label .. ": minDistance stays the type default")
	lu.assertNil(rawget(q, "maxDistance"), label .. ": maxDistance stays the type default")
end
