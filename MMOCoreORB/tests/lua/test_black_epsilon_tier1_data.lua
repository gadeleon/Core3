-- Black Epsilon tier 1 (Hakassha Sireen): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of black_epsilon_tier1_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local R = require("surprise_replay")

B.load()

local function quest(global) return B.quest(global) end

local function fixtureOf(global)
	local id = B.IDENTITY[global]

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

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Fixtures = {}

function TestBlackEpsilonT1Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the seven fixtures carry the values the spec lists
function TestBlackEpsilonT1Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local p1 = H.questFixture("patrol", "corellia_imperial_1")

	lu.assertEquals({ p1:get("questZone"), p1:list("navPoints"), p1:num("triggerOn"), p1:num("triggerDelay"), p1:get("triggerArg") },
		{ "space_corellia", { "space_corellia:imperial_1", "space_corellia:imperial_2", "space_corellia:imperial_3" }, 2, 10, "destroy_surpriseattack:corellia_imperial_1" }, "patrol/corellia_imperial_1")

	local s1 = H.questFixture("destroy_surpriseattack", "corellia_imperial_1")

	lu.assertEquals({ s1:list("shipType"), s1:list("shipCount") }, { { "reb_xwing_tier1" }, { "2" } }, "destroy_surpriseattack/corellia_imperial_1")

	local d2 = H.questFixture("destroy", "corellia_imperial_2")

	lu.assertEquals({ d2:list("shipList"), #d2:list("validSpawns"), d2:num("killCount"), d2:num("spawnsForWaypointsOnly") }, { { "reb_xwing_cadet_tier1" }, 4, 4, 1 }, "destroy/corellia_imperial_2")

	local e3 = H.questFixture("escort", "corellia_imperial_3")

	lu.assertEquals({ e3:get("escortShipType"), #e3:list("escortPath"), e3:num("numAttackShipLists"), e3:num("attackPeriod"), e3:get("attackListType"), e3:num("numResponses") },
		{ "imp_freightermedium_explosives_tier1", 4, 2, 90, "sequential", 5 }, "escort/corellia_imperial_3")

	local a4 = H.questFixture("assassinate", "corellia_imperial_4")

	lu.assertEquals({ a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "reb_bwing_prototype_tier2", 15, 4, { "reb_xwing_tier1" }, 0 }, "assassinate/corellia_imperial_4")

	local d6 = H.questFixture("destroy_duty", "corellia_imperial_6")

	lu.assertEquals({ d6:num("wavesPerRound"), d6:num("roundsPerLevel"), d6:num("levelsPerDuty"), d6:num("shipTypes"), d6:get("bossType"), d6:num("numResponses"), d6:num("reward") },
		{ 3, 2, 5, 1, "reb_bwing_prototype_tier2", 5, 100 }, "destroy_duty/corellia_imperial_6")

	local e7 = H.questFixture("escort_duty", "corellia_imperial_7")

	lu.assertEquals({ #e7:list("escortShipTypes"), #e7:list("escortPoints"), e7:num("numAttackShipLists"), e7:num("attackPeriod"), e7:num("numResponses"), e7:num("reward"), e7:num("killReward") },
		{ 3, 4, 1, 120, 5, 1000, 100 }, "escort_duty/corellia_imperial_7")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestBlackEpsilonT1Fixtures:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for name, xyz in pairs(B.POINTS) do
		local p = point("space_corellia", name)

		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_corellia patrol point " .. name)
	end

	for name, xyz in pairs(B.SPAWNERS) do
		local s = H.spawners("space_corellia")[name]

		lu.assertNotNil(s, "space_corellia spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "space_corellia spawner " .. name)
	end

	lu.assertEquals(#sortedKeys(B.POINTS), 15, "spec nav points")
	lu.assertEquals(#sortedKeys(B.SPAWNERS), 4, "spec spawners")
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J:394-522)
function TestBlackEpsilonT1Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_imperial_trainer_1.java")

	lu.assertNotNil(java, "fixtures/script/conversation/corellia_imperial_trainer_1.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.destroy_surpriseattack_corellia_imperial_1, { { 100, nil } }, "J giveRewardMission1 (SWG pays it on the surprise attack; Core3 pays it on the chain head)")
	lu.assertEquals(found.destroy_corellia_imperial_2, { { 200, nil } }, "J giveRewardMission2")
	lu.assertEquals(found.escort_corellia_imperial_3, { { 500, "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff" }, { 500, "object/tangible/wearables/bandolier/double_bandolier.iff" },
		{ 500, "object/tangible/wearables/bandolier/ith_double_bandolier.iff" } }, "J giveRewardMission3 (human, Wookiee, Ithorian in the file order)")
	lu.assertEquals(found.assassinate_corellia_imperial_4, { { 1000, "object/tangible/wearables/helmet/helmet_tie_fighter.iff" } }, "J giveRewardMission4")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Wiring = {}

function TestBlackEpsilonT1Wiring:setUp() H.reset() end

-- AC-1
function TestBlackEpsilonT1Wiring:test_the_squadron_file_registers_the_seven_quests_with_start_true()
	for _, global in ipairs(B.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestBlackEpsilonT1Wiring:test_the_squadron_screenplay_is_registered_without_start_and_has_the_section_2_constants()
	local sq = H.expectGlobal("BlackEpsilonSquadronScreenplay", "squadron screenplay object")

	lu.assertNotNil(H.registered("BlackEpsilonSquadronScreenplay"), "BlackEpsilonSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("BlackEpsilonSquadronScreenplay").start, "BlackEpsilonSquadronScreenplay: registered with start = false")
	lu.assertEquals(sq.screenplayName, "BlackEpsilonSquadronScreenplay", "screenplayName")
	lu.assertEquals(type(sq.start), "function", "BlackEpsilonSquadronScreenplay:start")
	lu.assertEquals(pcall(sq.start, sq), true, "BlackEpsilonSquadronScreenplay:start runs")

	for field, want in pairs(B.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "BlackEpsilonSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, B.SERIES_SUFFIX, "BlackEpsilonSquadronScreenplay.SERIES_COMPLETE_KEY")
	lu.assertEquals(sq.WORKING_FOR_PRISK_KEY, B.PRISK_SUFFIX, "BlackEpsilonSquadronScreenplay.WORKING_FOR_PRISK_KEY")
	lu.assertEquals(type(sq.resetHakasshaQuests), "function", "BlackEpsilonSquadronScreenplay:resetHakasshaQuests")
	lu.assertEquals(pcall(sq.resetHakasshaQuests, sq, nil), true, "resetHakasshaQuests(nil) returns early")
end

-- AC-1
function TestBlackEpsilonT1Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	B.requireConversation(lu)

	local t = H.conversationTemplateTable(B.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, B.HANDLER, B.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", B.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, B.HANDLER).getInitialScreen), "function", B.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, B.HANDLER).runScreenHandlers), "function", B.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, B.HANDLER).getNextConversationScreen), "function", B.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestBlackEpsilonT1Wiring:test_hakassha_sireen_uses_the_template_and_has_the_conversable_mask()
	local npc = H.loadCreatureTemplate("space/hakassha_sireen.lua", "hakassha_sireen")

	lu.assertNotNil(npc, "mobile/space/hakassha_sireen.lua registers hakassha_sireen")
	lu.assertEquals(npc.conversationTemplate, "hakassha_convo_template", "hakassha_sireen: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "hakassha_sireen: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "hakassha_sireen: optionsBitmask (Kreezo's mask)")
end

-- AC-1
function TestBlackEpsilonT1Wiring:test_the_template_include_line_is_uncommented_exactly_once_under_the_black_epsilon_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/black_epsilon_squadron/hakassha_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented hakassha_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented hakassha_convo include")

	local comment = text:find("-- Black Epsilon Squadron", 1, true)
	local include = text:find("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua", 1, true)
	local nextComment = text:find("-- Imperial Inquisition Squadron", comment or 1, true)

	lu.assertTrue(comment ~= nil and include ~= nil and include > comment and include < nextComment, "space_conversations.lua: the include sits under '-- Black Epsilon Squadron'")
end

-- AC-1
function TestBlackEpsilonT1Wiring:test_the_handler_include_line_follows_the_squadron_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented hakasshaConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented hakasshaConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/BlackEpsilonSquadronScreenplay.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: the BlackEpsilonSquadronScreenplay include")
	lu.assertEquals(lines[at + 1], "", "screenplays.lua: a blank line after the squadron include")
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua")', "screenplays.lua: the handler include, directly after the blank line")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Tables = {}

function TestBlackEpsilonT1Tables:setUp() H.reset() end

-- AC-2, I-1
function TestBlackEpsilonT1Tables:test_the_seven_tables_keep_their_identity_and_zone()
	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)
		local id = B.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_corellia", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestBlackEpsilonT1Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	lu.assertEquals(type(SPECIES_ITHORIAN), "number", "precondition: SPECIES_ITHORIAN is a harness constant")

	local want = B.expected()

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2, I-6
function TestBlackEpsilonT1Tables:test_only_patrol_1_splits_and_it_splits_at_point_2_after_10_seconds()
	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, global == B.P1, global .. ": sideQuest")
	end

	local p1 = quest(B.P1)

	lu.assertEquals({ p1.sideQuestType, p1.sideQuestName }, { "destroy_surpriseattack", "corellia_imperial_1" }, B.P1 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p1.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, B.P1 .. ": sideQuestSplitType")
	lu.assertEquals({ p1.sideQuestPatrolStart, p1.sideQuestDelay }, { 2, 10 }, B.P1 .. ": sideQuestPatrolStart, sideQuestDelay (the .tab triggerDelay, not Havoc's 20)")

	local s1 = quest(B.S1)

	lu.assertEquals({ s1.parentQuest, s1.parentQuestType, s1.parentQuestName }, { B.P1, "patrol", "corellia_imperial_1" }, B.S1 .. ": parent fields")
end

-- AC-2, I-5
function TestBlackEpsilonT1Tables:test_credits_and_items_sit_on_the_heads_and_the_surprise_attack_pays_nothing()
	local pays = { [B.P1] = 100, [B.M2] = 200, [B.E3] = 500, [B.A4] = 1000, [B.DUTY6] = 100, [B.DUTY7] = 1000 }

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if global ~= B.E3 and global ~= B.A4 then
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end

	lu.assertEquals(rawget(quest(B.S1), "creditReward") or 0, 0, B.S1 .. ": the surprise attack pays no credits (SWG pays on it, Core3 on the chain head)")
end

-- AC-2, I-5: the three species entries come in this order
function TestBlackEpsilonT1Tables:test_mission_3_items_are_wookiee_ithorian_then_the_tie_flight_suit_in_that_order()
	lu.assertEquals(quest(B.E3).itemReward, {
		{ species = { SPECIES_WOOKIEE }, item = "object/tangible/wearables/bandolier/double_bandolier.iff" },
		{ species = { SPECIES_ITHORIAN }, item = "object/tangible/wearables/bandolier/ith_double_bandolier.iff" },
		{ species = { -1 }, item = "object/tangible/wearables/bodysuit/bodysuit_tie_fighter.iff" },
	}, B.E3 .. ": itemReward")
end

-- I-3: every ship the tables name has a ship template and every item an object template
function TestBlackEpsilonT1Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(B.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes" }) do
			walk(rawget(q, field), ships)
		end

		walk(rawget(q, "bossShip"), ships)

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
		end
	end

	for _, spawn in ipairs(quest(B.S1).surpriseAttackShips.spawns) do
		ships[spawn.shipName] = true
	end

	ships[quest(B.A4).assassinateSpawns.target] = true
	walk(quest(B.A4).assassinateSpawns.escorts, ships)

	lu.assertEquals(#sortedKeys(ships), 10, "distinct ships in the 7 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 7 tables: " .. table.concat(sortedKeys(items), ", "))

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
function TestBlackEpsilonT1Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(B.GLOBALS) do
		local id = B.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1Conformance = {}

function TestBlackEpsilonT1Conformance:setUp() H.reset() end

-- AC-2, I-4: patrol/corellia_imperial_1.tab
function TestBlackEpsilonT1Conformance:test_patrol_1_maps_points_and_split_from_its_fixture()
	local q, rec = quest(B.P1), fixtureOf(B.P1)
	local points = {}

	for i, p in ipairs(pointsOf(rec, "navPoints")) do
		points[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
	end

	local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertEquals(q.questZone, rec:get("questZone"), "patrol/corellia_imperial_1: questZone")
	lu.assertEquals(q.patrolPoints, points, "patrol/corellia_imperial_1: patrolPoints (navPoints)")
	lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), "patrol/corellia_imperial_1: sideQuestPatrolStart (triggerOn)")
	lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), "patrol/corellia_imperial_1: sideQuestDelay (triggerDelay)")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, "patrol/corellia_imperial_1: sideQuestType, sideQuestName (triggerArg)")
end

-- AC-2, I-4: destroy_surpriseattack/corellia_imperial_1.tab, by replaying SWG's spawn loop
function TestBlackEpsilonT1Conformance:test_surprise_attack_1_equals_the_replay_of_the_swg_spawn_loop()
	local q = quest(B.S1)

	lu.assertEquals(q.surpriseAttackShips, { zone = H.questFixture("destroy_surpriseattack", "corellia_imperial_1"):get("questZone"), spawns = R.runs(R.replay("corellia_imperial_1")) },
		"destroy_surpriseattack/corellia_imperial_1: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.replay("corellia_imperial_1"), { "reb_xwing_tier1", "reb_xwing_tier1" }, "the replay itself: 2 x reb_xwing_tier1")
end

-- AC-2, I-2, I-4: destroy/corellia_imperial_2.tab
function TestBlackEpsilonT1Conformance:test_destroy_2_maps_ships_kills_and_spawners()
	local q, rec = quest(B.M2), fixtureOf(B.M2)
	local label = "destroy/corellia_imperial_2"

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

-- AC-2, I-2, I-4: escort/corellia_imperial_3.tab and escort_duty/corellia_imperial_7.tab
function TestBlackEpsilonT1Conformance:test_escort_3_and_escort_duty_7_map_ships_path_attack_lists_delay_and_taunts()
	for _, global in ipairs({ B.E3, B.DUTY7 }) do
		local q, rec = quest(global), fixtureOf(global)
		local label = B.IDENTITY[global].type .. "/" .. q.questName
		local shipsColumn = global == B.E3 and "escortShipType" or "escortShipTypes"
		local pathColumn = global == B.E3 and "escortPath" or "escortPoints"
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

	local d7, rec = quest(B.DUTY7), fixtureOf(B.DUTY7)

	lu.assertEquals(d7.creditReward, rec:num("reward"), "escort_duty/corellia_imperial_7: creditReward (reward)")
	lu.assertEquals(d7.creditKillBonus, rec:num("killReward"), "escort_duty/corellia_imperial_7: creditKillBonus (killReward)")
	lu.assertEquals(quest(B.E3).parentQuest or "", "", "escort/corellia_imperial_3: a chain head, no parent (FH-5: no patrol parent)")
end

-- AC-2, I-2, I-4: assassinate/corellia_imperial_4.tab
function TestBlackEpsilonT1Conformance:test_assassinate_4_maps_target_escorts_delay_and_path()
	local q, rec = quest(B.A4), fixtureOf(B.A4)
	local label = "assassinate/corellia_imperial_4"
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

-- AC-2, I-4: destroy_duty/corellia_imperial_6.tab
function TestBlackEpsilonT1Conformance:test_destroy_duty_6_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(B.DUTY6), fixtureOf(B.DUTY6)
	local label = "destroy_duty/corellia_imperial_6"
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
	lu.assertNil(rawget(q, "minDistance"), label .. ": minDistance stays the type default (D-9)")
	lu.assertNil(rawget(q, "maxDistance"), label .. ": maxDistance stays the type default (D-9)")
end
