-- Inquisition tier 1 (Lt. Barn Sinkko): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/inquisition-tier1-barn-sinkko/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of inquisition_tier1_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier1_data")
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

-- the data keys of a table: function-valued fields (the abort override) are not data
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

TestInquisitionT1Fixtures = {}

function TestInquisitionT1Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the eight fixtures carry the values the spec lists
function TestInquisitionT1Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = H.questFixture("patrol", "naboo_imperial_1")

	lu.assertEquals({ p1:get("questZone"), p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg") },
		{ "space_naboo", { "space_naboo:imperial_1", "space_naboo:imperial_2", "space_naboo:imperial_3" }, 2, 10, "destroy_surpriseattack:naboo_imperial_1" }, "patrol/naboo_imperial_1")

	local s1 = H.questFixture("destroy_surpriseattack", "naboo_imperial_1")

	lu.assertEquals({ s1:list("shipType"), s1:list("shipCount") }, { { "reb_xwing_tier1" }, { "2" } }, "destroy_surpriseattack/naboo_imperial_1")

	local d2 = H.questFixture("destroy", "naboo_imperial_2")

	lu.assertEquals({ d2:list("shipList"), #d2:list("validSpawns"), d2:num("killCount"), d2:num("spawnsForWaypointsOnly") }, { { "reb_xwing_cadet_tier1" }, 5, 4, 1 }, "destroy/naboo_imperial_2")

	local p3 = H.questFixture("patrol", "naboo_imperial_3")

	lu.assertEquals({ #p3:list("navPoints"), p3:num("triggerOn"), p3:num("triggerDelay"), p3:get("triggerArg") }, { 4, 3, 20, "escort:naboo_imperial_3" }, "patrol/naboo_imperial_3")

	local e3 = H.questFixture("escort", "naboo_imperial_3")

	lu.assertEquals({ e3:get("escortShipType"), #e3:list("escortPath"), e3:num("numAttackShipLists"), e3:num("attackPeriod"), e3:get("attackListType"), e3:num("numResponses") },
		{ "imp_freighterheavy_e62_tier1", 4, 2, 90, "sequential", 5 }, "escort/naboo_imperial_3")

	local a4 = H.questFixture("assassinate", "naboo_imperial_4")

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "reb_xwing_leader_tier2", 15, 4, { "reb_xwing_tier1" }, 0 }, "assassinate/naboo_imperial_4")

	local d6 = H.questFixture("destroy_duty", "naboo_imperial_6")

	lu.assertEquals({ d6:num("wavesPerRound"), d6:num("roundsPerLevel"), d6:num("levelsPerDuty"), d6:num("shipTypes"), d6:get("bossType"), d6:num("numResponses"), d6:num("reward") },
		{ 3, 2, 5, 2, "reb_xwing_tier2", 5, 100 }, "destroy_duty/naboo_imperial_6")

	local e7 = H.questFixture("escort_duty", "naboo_imperial_7")

	lu.assertEquals({ #e7:list("escortShipTypes"), #e7:list("escortPoints"), e7:num("numAttackShipLists"), e7:num("attackPeriod"), e7:num("numResponses"), e7:num("reward"), e7:num("killReward") },
		{ 6, 3, 2, 90, 5, 1000, 100 }, "escort_duty/naboo_imperial_7")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestInquisitionT1Fixtures:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for name, xyz in pairs(I.POINTS) do
		local p = point("space_naboo", name)

		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_naboo patrol point " .. name)
	end

	for name, xyz in pairs(I.SPAWNERS) do
		local s = H.spawners("space_naboo")[name]

		lu.assertNotNil(s, "space_naboo spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "space_naboo spawner " .. name)
	end

	lu.assertEquals(#sortedKeys(I.POINTS), 15, "spec nav points")
	lu.assertEquals(#sortedKeys(I.SPAWNERS), 5, "spec spawners")
end

-- I-2 (the oracle itself): the buildout excerpt holds exactly the 15 nav points and 5 spawners, and Core3's points are its truncated values
function TestInquisitionT1Fixtures:test_the_buildout_excerpt_pins_every_point_and_spawner_of_the_tables()
	local tab = H.fixture("space_zones/buildout/space_naboo.inquisition_tier1_points.tab")
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

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J:423-476)
function TestInquisitionT1Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_imperial_trainer_1.java")

	lu.assertNotNil(java, "fixtures/script/conversation/naboo_imperial_trainer_1.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.destroy_surpriseattack_naboo_imperial_1, { { 100, nil } }, "J giveRewardMission1 (SWG pays it on the surprise attack; Core3 pays it on the chain head)")
	lu.assertEquals(found.destroy_naboo_imperial_2, { { 200, nil } }, "J giveRewardMission2")
	lu.assertEquals(#(found.escort_naboo_imperial_3 or {}), 3, "J giveRewardMission3 pays on the escort, three species variants")

	local items = {}

	for i, entry in ipairs(found.escort_naboo_imperial_3 or {}) do
		lu.assertEquals(entry[1], 500, "J giveRewardMission3 credits, variant " .. i)
		items[#items + 1] = entry[2]
	end

	table.sort(items)
	lu.assertEquals(items, { I.WOOKIEE_BANDOLIER, I.ITHORIAN_BANDOLIER, I.TIE_SUIT }, "J giveRewardMission3 items (any order)")
	lu.assertEquals(found.assassinate_naboo_imperial_4, { { 1000, I.TIE_HELMET } }, "J giveRewardMission4")
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestInquisitionT1Fixtures:test_the_client_quest_name_table_lists_the_eight_quests()
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

TestInquisitionT1Wiring = {}

function TestInquisitionT1Wiring:setUp() H.reset() end

-- AC-1
function TestInquisitionT1Wiring:test_the_squadron_file_registers_the_eight_quests_with_start_true()
	for _, global in ipairs(I.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestInquisitionT1Wiring:test_the_eight_quests_are_registered_in_the_contract_order()
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
function TestInquisitionT1Wiring:test_the_squadron_screenplay_is_registered_without_start_and_has_the_section_2_constants()
	local sq = H.expectGlobal("InquisitionSquadronScreenplay", "squadron screenplay object")

	lu.assertNotNil(H.registered("InquisitionSquadronScreenplay"), "InquisitionSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("InquisitionSquadronScreenplay").start, "InquisitionSquadronScreenplay: registered with start = false")
	lu.assertEquals(sq.screenplayName, "InquisitionSquadronScreenplay", "screenplayName")
	lu.assertEquals(type(sq.start), "function", "InquisitionSquadronScreenplay:start")
	lu.assertEquals(pcall(sq.start, sq), true, "InquisitionSquadronScreenplay:start runs")

	for field, want in pairs(I.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "InquisitionSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, I.SERIES_SUFFIX, "InquisitionSquadronScreenplay.SERIES_COMPLETE_KEY")
	lu.assertEquals(sq.INQUISITORIAL_AGENT_KEY, I.AGENT_SUFFIX, "InquisitionSquadronScreenplay.INQUISITORIAL_AGENT_KEY")
	lu.assertEquals(type(sq.resetBarnQuests), "function", "InquisitionSquadronScreenplay:resetBarnQuests")
	lu.assertEquals(pcall(sq.resetBarnQuests, sq, nil), true, "resetBarnQuests(nil) returns early")
end

-- AC-1
function TestInquisitionT1Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	I.requireConversation(lu)

	local t = H.conversationTemplateTable(I.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, I.HANDLER, I.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", I.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getInitialScreen), "function", I.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, I.HANDLER).runScreenHandlers), "function", I.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getNextConversationScreen), "function", I.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestInquisitionT1Wiring:test_barn_sinkko_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/barn_sinkko.lua", "barn_sinkko")

	lu.assertNotNil(npc, "mobile/space/barn_sinkko.lua registers barn_sinkko")
	lu.assertEquals(npc.conversationTemplate, "barn_sinkko_convo_template", "barn_sinkko: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "barn_sinkko: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "barn_sinkko: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "barn_sinkko: optionsBitmask (the Dravis mask)")
end

-- AC-1
function TestInquisitionT1Wiring:test_the_template_include_line_is_uncommented_exactly_once_under_the_inquisition_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented barn_sinkko_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented barn_sinkko_convo include")

	local comment = text:find("-- Imperial Inquisition Squadron", 1, true)
	local include = text:find("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua", 1, true)
	local nextComment = text:find("-- Storm Squadron", comment or 1, true)

	lu.assertTrue(comment ~= nil and include ~= nil and include > comment and include < nextComment, "space_conversations.lua: the include sits under '-- Imperial Inquisition Squadron'")
end

-- AC-1
function TestInquisitionT1Wiring:test_the_handler_include_line_follows_the_squadron_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented barnSinkkoConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented barnSinkkoConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/InquisitionSquadronScreenplay.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: the InquisitionSquadronScreenplay include")
	lu.assertEquals(lines[at + 1], "", "screenplays.lua: a blank line after the squadron include")
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua")', "screenplays.lua: the handler include, directly after the blank line")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestInquisitionT1Tables = {}

function TestInquisitionT1Tables:setUp() H.reset() end

-- AC-2, I-1
function TestInquisitionT1Tables:test_the_eight_tables_keep_their_identity_and_zone()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)
		local id = I.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_naboo", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestInquisitionT1Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
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

-- D-6: the only function a table defines is the abort override of mission 2
function TestInquisitionT1Tables:test_only_destroy_2_defines_a_function_and_it_is_abortQuest()
	for _, global in ipairs(I.GLOBALS) do
		local want = global == I.M2 and { "abortQuest" } or {}

		lu.assertEquals(functionKeys(quest(global)), want, global .. ": function-valued own fields")
	end
end

-- AC-2, I-6
function TestInquisitionT1Tables:test_only_patrol_1_and_patrol_3_split_and_they_split_at_points_2_and_3_after_10_and_20_seconds()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, global == I.P1 or global == I.P3, global .. ": sideQuest")
	end

	local p1 = quest(I.P1)

	lu.assertEquals({ p1.sideQuestType, p1.sideQuestName }, { "destroy_surpriseattack", "naboo_imperial_1" }, I.P1 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p1.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, I.P1 .. ": sideQuestSplitType")
	lu.assertEquals({ p1.sideQuestPatrolStart, p1.sideQuestDelay }, { 2, 10 }, I.P1 .. ": sideQuestPatrolStart, sideQuestDelay")

	local p3 = quest(I.P3)

	lu.assertEquals({ p3.sideQuestType, p3.sideQuestName }, { "escort", "naboo_imperial_3" }, I.P3 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p3.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, I.P3 .. ": sideQuestSplitType")
	lu.assertEquals({ p3.sideQuestPatrolStart, p3.sideQuestDelay }, { 3, 20 }, I.P3 .. ": sideQuestPatrolStart, sideQuestDelay")

	local s1, e3 = quest(I.S1), quest(I.E3)

	lu.assertEquals({ s1.parentQuest, s1.parentQuestType, s1.parentQuestName }, { I.P1, "patrol", "naboo_imperial_1" }, I.S1 .. ": parent fields")
	lu.assertEquals({ e3.parentQuest, e3.parentQuestType, e3.parentQuestName }, { I.P3, "patrol", "naboo_imperial_3" }, I.E3 .. ": parent fields")
end

-- AC-2, I-5
function TestInquisitionT1Tables:test_credits_and_items_sit_on_the_heads_and_the_surprise_attack_and_escort_pay_nothing()
	local pays = { [I.P1] = 100, [I.M2] = 200, [I.P3] = 500, [I.A4] = 1000, [I.DUTY6] = 100, [I.DUTY7] = 1000 }

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if global ~= I.P3 and global ~= I.A4 then
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(rawget(quest(I.S1), "creditReward") or 0, 0, I.S1 .. ": the surprise attack pays no credits")
	lu.assertEquals(rawget(quest(I.E3), "creditReward") or 0, 0, I.E3 .. ": the escort pays no credits (Core3 pays on the patrol head, D-7)")
end

-- AC-2, I-5: the three species entries come in this order
function TestInquisitionT1Tables:test_mission_3_items_are_wookiee_ithorian_then_the_tie_flight_suit_in_that_order()
	lu.assertEquals(quest(I.P3).itemReward, {
		{ species = { SPECIES_WOOKIEE }, item = "object/tangible/wearables/bandolier/double_bandolier.iff" },
		{ species = { SPECIES_ITHORIAN }, item = "object/tangible/wearables/bandolier/ith_double_bandolier.iff" },
		{ species = { -1 }, item = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff" },
	}, I.P3 .. ": itemReward")
end

-- I-3: every ship the tables name has a ship template and every item an object template (13 ships, 4 items)
function TestInquisitionT1Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	lu.assertEquals(#sortedKeys(ships), 13, "distinct ships in the 8 tables: " .. table.concat(sortedKeys(ships), ", "))
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

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestInquisitionT1Conformance = {}

function TestInquisitionT1Conformance:setUp() H.reset() end

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
	lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), label .. ": sideQuestDelay (triggerDelay)")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, label .. ": sideQuestType, sideQuestName (triggerArg)")
end

-- AC-2, I-4: patrol/naboo_imperial_1.tab
function TestInquisitionT1Conformance:test_patrol_1_maps_points_and_split_from_its_fixture()
	patrolConformance(I.P1)
end

-- AC-2, I-4: patrol/naboo_imperial_3.tab
function TestInquisitionT1Conformance:test_patrol_3_maps_points_and_split_from_its_fixture()
	patrolConformance(I.P3)
end

-- AC-2, I-4: destroy_surpriseattack/naboo_imperial_1.tab, by replaying SWG's spawn loop
function TestInquisitionT1Conformance:test_surprise_attack_1_equals_the_replay_of_the_swg_spawn_loop()
	local q = quest(I.S1)

	lu.assertEquals(q.surpriseAttackShips, { zone = H.questFixture("destroy_surpriseattack", "naboo_imperial_1"):get("questZone"), spawns = R.runs(R.replay("naboo_imperial_1")) },
		"destroy_surpriseattack/naboo_imperial_1: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.replay("naboo_imperial_1"), { "reb_xwing_tier1", "reb_xwing_tier1" }, "the replay itself: 2 x reb_xwing_tier1")
end

-- AC-2, I-2, I-4: destroy/naboo_imperial_2.tab
function TestInquisitionT1Conformance:test_destroy_2_maps_ships_kills_and_the_five_spawners()
	local q, rec = quest(I.M2), fixtureOf(I.M2)
	local label = "destroy/naboo_imperial_2"

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.shipTypes, rec:list("shipList"), label .. ": shipTypes (shipList)")
	lu.assertEquals(q.killsRequired, rec:num("killCount"), label .. ": killsRequired (killCount)")

	local spawns = rec:list("validSpawns")

	lu.assertEquals(#q.shipLocations, #spawns, label .. ": number of shipLocations")

	for i, value in ipairs(spawns) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, label .. ": spawner " .. spawnName .. " in " .. zone)
		lu.assertEquals(zone, q.questZone, label .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.shipLocations[i], { spawnName = spawnName, x = s.x, z = s.z, y = s.y }, label .. ": shipLocations[" .. i .. "] (" .. spawnName .. ")")
	end
end

-- AC-2, I-2, I-4: escort/naboo_imperial_3.tab and escort_duty/naboo_imperial_7.tab
function TestInquisitionT1Conformance:test_escort_3_and_escort_duty_7_map_ships_path_attack_lists_delay_and_taunts()
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

	lu.assertEquals(d7.creditReward, rec:num("reward"), "escort_duty/naboo_imperial_7: creditReward (reward)")
	lu.assertEquals(d7.creditKillBonus, rec:num("killReward"), "escort_duty/naboo_imperial_7: creditKillBonus (killReward)")
end

-- AC-2, I-2, I-4: assassinate/naboo_imperial_4.tab
function TestInquisitionT1Conformance:test_assassinate_4_maps_target_escorts_delay_and_path()
	local q, rec = quest(I.A4), fixtureOf(I.A4)
	local label = "assassinate/naboo_imperial_4"
	local path = {}

	for i, p in ipairs(pointsOf(rec, "escortPath")) do
		path[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
		lu.assertEquals(p.zone, q.questZone, label .. ": escortPath zone equals questZone")
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), label .. ": questZone")
	lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, label .. ": assassinateSpawns (targetShipType, targetEscort)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), label .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.targetPatrols, path, label .. ": targetPatrols (escortPath, in file order)")
	lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, label .. ": mustDestroyEscort")
	lu.assertEquals(q.failTimer, 20, label .. ": failTimer (Core3-only)")
end

-- AC-2, I-4: destroy_duty/naboo_imperial_6.tab
function TestInquisitionT1Conformance:test_destroy_duty_6_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(I.DUTY6), fixtureOf(I.DUTY6)
	local label = "destroy_duty/naboo_imperial_6"
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
