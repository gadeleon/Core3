-- Black Epsilon tier 2 (Prisk Kith'Vys): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of black_epsilon_tier2_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local R = require("surprise_replay")
local Swgjava = require("harness.swgjava")

P.load()

local function quest(global) return P.quest(global) end

local function fixtureOf(global)
	local id = P.IDENTITY[global]

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

TestBlackEpsilonT2Fixtures = {}

function TestBlackEpsilonT2Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the twelve fixtures carry the values the spec lists
function TestBlackEpsilonT2Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local r16 = H.questFixture("recovery", "corellia_imperial_16")

	lu.assertEquals({ r16:get("questZone"), r16:get("targetShipType"), r16:num("targetArrivalDelay"), r16:num("targetRecoverTime"), r16:list("targetEscort"), #r16:list("escortPath"),
		#r16:list("recoveryPath"), r16:num("numAttackShipLists"), r16:num("attackPeriod"), r16:num("numResponses"), r16:get("triggerEvent") },
		{ "space_corellia", "freighterheavy_black_epsilon_tier2", 20, 30, { "hidden_daggers_enforcer_tier2", "hidden_daggers_enforcer_tier2" }, 5, 4, 2, 120, 5, "none" }, "recovery/corellia_imperial_16")

	local a12 = H.questFixture("assassinate", "corellia_imperial_12")

	lu.assertEquals({ a12:get("targetShipType"), a12:num("targetArrivalDelay"), #a12:list("escortPath"), #a12:list("targetEscort"), a12:num("mustDestroyEscort") },
		{ "rebel_diplomat_tier2", 30, 5, 4, 1 }, "assassinate/corellia_imperial_12")

	local i13 = H.questFixture("inspect", "corellia_imperial_13")

	lu.assertEquals({ i13:list("shipList"), i13:list("validSpawns"), i13:num("giveSpawnWaypoint"), i13:get("cargo") },
		{ { "rebel_spysmuggler_tier2" }, { "space_corellia:corellia_imperial_tier2_inspect_freighter" }, 1, "personnel_dossier" }, "inspect/corellia_imperial_13")

	local a14 = H.questFixture("assassinate", "corellia_imperial_14")

	lu.assertEquals({ a14:get("targetShipType"), a14:num("targetArrivalDelay"), #a14:list("escortPath"), #a14:list("targetEscort"), a14:num("mustDestroyEscort") },
		{ "reb_bomber_leader_tier3", 15, 4, 5, 1 }, "assassinate/corellia_imperial_14")

	local p15 = H.questFixture("patrol", "corellia_imperial_15")

	lu.assertEquals({ #p15:list("navPoints"), p15:num("triggerOn"), p15:num("triggerDelay"), p15:num("triggerEndsMission"), p15:get("triggerArg") },
		{ 5, 4, 20, 1, "destroy_surpriseattack:corellia_imperial_15_split" }, "patrol/corellia_imperial_15")

	local s15 = H.questFixture("destroy_surpriseattack", "corellia_imperial_15_split")

	lu.assertEquals({ s15:list("shipType"), s15:list("shipCount") }, { { "reb_xwing_tier2" }, { "2" } }, "destroy_surpriseattack/corellia_imperial_15_split")

	local a17 = H.questFixture("assassinate", "corellia_imperial_17")

	lu.assertEquals({ a17:get("targetShipType"), a17:num("targetArrivalDelay"), #a17:list("escortPath"), #a17:list("targetEscort"), a17:num("mustDestroyEscort"), a17:get("triggerSplitCondition"),
		a17:get("triggerArg"), a17:num("triggerDelay") }, { "reb_unmaned_xwing_tier2", 20, 3, 0, 0, "success", "survival:corellia_tier2_final", nil }, "assassinate/corellia_imperial_17")

	local fin = H.questFixture("survival", "corellia_tier2_final")

	lu.assertEquals({ fin:list("transmissionPoint"), fin:num("totalTransmissionTime"), fin:num("timesToUpdateProgress"), fin:num("transmissionStartDelay"), fin:num("delayToFirstAttack"),
		fin:num("numAttackShipLists"), fin:num("attackPeriod"), fin:get("attackListType") },
		{ { "space_corellia:rebel_ambush_point" }, 350, 6, 10, 20, 3, 90, "sequential" }, "survival/corellia_tier2_final")

	local d8 = H.questFixture("destroy_duty", "corellia_imperial_8")

	lu.assertEquals({ d8:num("wavesPerRound"), d8:num("roundsPerLevel"), d8:num("levelsPerDuty"), d8:num("shipTypes"), d8:get("bossType"), d8:num("reward") },
		{ 3, 2, 3, 2, "hidden_daggers_executioner_tier3", 200 }, "destroy_duty/corellia_imperial_8")

	local d10 = H.questFixture("destroy_duty", "corellia_imperial_10")

	lu.assertEquals({ d10:num("wavesPerRound"), d10:num("roundsPerLevel"), d10:num("levelsPerDuty"), d10:num("shipTypes"), d10:get("bossType"), d10:num("reward") },
		{ 4, 3, 4, 2, "reb_xwing_tier3", 200 }, "destroy_duty/corellia_imperial_10")

	for _, name in ipairs({ "corellia_imperial_9", "corellia_imperial_11" }) do
		local e = H.questFixture("escort_duty", name)

		lu.assertEquals({ e:num("reward"), e:num("killReward"), e:num("numResponses"), e:num("attackPeriod") }, { 2500, 200, 5, 120 }, "escort_duty/" .. name)
	end

	lu.assertEquals(#H.questFixture("escort_duty", "corellia_imperial_9"):list("escortPoints"), 9, "escort_duty/corellia_imperial_9: escortPoints")
	lu.assertEquals(#H.questFixture("escort_duty", "corellia_imperial_11"):list("escortPoints"), 5, "escort_duty/corellia_imperial_11: escortPoints")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestBlackEpsilonT2Fixtures:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for name, xyz in pairs(P.POINTS) do
		local p = point("space_corellia", name)

		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_corellia patrol point " .. name)
	end

	for name, xyz in pairs(P.SPAWNERS) do
		local s = H.spawners("space_corellia")[name]

		lu.assertNotNil(s, "space_corellia spawner " .. name)
		lu.assertEquals({ s.x, s.z, s.y }, xyz, "space_corellia spawner " .. name)
	end

	lu.assertEquals(#sortedKeys(P.POINTS), 37, "spec points")
	lu.assertEquals(#sortedKeys(P.SPAWNERS), 1, "spec spawners")
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J:284-292, 353-379)
function TestBlackEpsilonT2Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/corellia_imperial_trainer_2.java")

	lu.assertNotNil(java, "fixtures/script/conversation/corellia_imperial_trainer_2.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	lu.assertEquals(found.assassinate_corellia_imperial_12, { { 5000, P.ITEMS[1] } }, "J giveReward12")
	lu.assertEquals(found.inspect_corellia_imperial_13, { { 5000, P.ITEMS[2] } }, "J giveReward13")
	lu.assertEquals(found.assassinate_corellia_imperial_14, { { 5000, P.ITEMS[3] } }, "J giveReward14")
	lu.assertEquals(found.destroy_surpriseattack_corellia_imperial_15_split, { { 5000, P.ITEMS[4] } }, "J giveReward15 (SWG pays it on the split; Core3 pays it on the chain head)")
	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 75%.0f%)"), 4, "J: +75 Imperial standing, once per reward")
end

-- AC-2 (the oracle itself): the skills the SWG table prices at 60000 space XP each and requires the four _01 skills for
function TestBlackEpsilonT2Fixtures:test_the_tier_2_skill_excerpt_prices_each_skill_at_60000_xp_and_requires_the_four_tier_1_skills()
	local seen = {}

	for _, rec in ipairs(H.fixture("skill/skills.pilot_imperial_navy_02.tab").records) do
		local name = rec:get("NAME")

		if name ~= nil and name:match("^pilot_imperial_navy_%a+_02$") then
			seen[name] = true
			lu.assertEquals(rec:num("XP_COST"), 60000, name .. ": XP_COST")
			lu.assertEquals(rec:get("XP_TYPE"), "space_combat_general", name .. ": XP_TYPE")
			lu.assertEquals(rec:get("SKILLS_REQUIRED"), table.concat(P.TIER1_SKILLS, ","), name .. ": SKILLS_REQUIRED")
		end
	end

	lu.assertEquals(sortedKeys(seen), { "pilot_imperial_navy_droid_02", "pilot_imperial_navy_procedures_02", "pilot_imperial_navy_starships_02", "pilot_imperial_navy_weapons_02" }, "tier 2 skills in the excerpt")
end

-- AC-5 (the oracle itself): the answer key parses 93 NPC lines
function TestBlackEpsilonT2Fixtures:test_the_swg_script_parses_93_npc_lines()
	local graph = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_imperial_trainer_2.java")

	lu.assertEquals(#graph.order, 93, "NPC lines parsed from corellia_imperial_trainer_2.java")
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Wiring = {}

function TestBlackEpsilonT2Wiring:setUp() H.reset() end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_squadron_file_registers_the_twelve_tier_2_quests_with_start_true()
	for _, global in ipairs(P.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_seven_tier_1_quests_are_still_registered()
	for _, global in ipairs(P.TIER1_GLOBALS) do
		H.expectGlobal(global, "tier 1 quest table")
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_squadron_screenplay_has_the_tier_2_constants_and_keeps_the_tier_1_ones()
	local sq = H.expectGlobal("BlackEpsilonSquadronScreenplay", "squadron screenplay object")

	for field, want in pairs(P.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "BlackEpsilonSquadronScreenplay." .. field)
	end

	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "corellia_imperial_1" }, "tier 1 QUEST_STRING_1 is unchanged")
	lu.assertEquals(sq.SERIES_COMPLETE_KEY, P.SERIES_SUFFIX, "SERIES_COMPLETE_KEY is unchanged")
	lu.assertEquals(sq.WORKING_FOR_PRISK_KEY, P.PRISK_SUFFIX, "WORKING_FOR_PRISK_KEY is unchanged")
	lu.assertEquals(type(sq.resetHakasshaQuests), "function", "resetHakasshaQuests")
	lu.assertEquals(type(sq.resetPriskQuests), "function", "BlackEpsilonSquadronScreenplay:resetPriskQuests")
	lu.assertEquals(pcall(sq.resetPriskQuests, sq, nil), true, "resetPriskQuests(nil) returns early")
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	P.requireConversation(lu)

	local t = H.conversationTemplateTable(P.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, P.HANDLER, P.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", P.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, P.HANDLER).getInitialScreen), "function", P.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, P.HANDLER).runScreenHandlers), "function", P.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, P.HANDLER).getNextConversationScreen), "function", P.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_prisk_kith_vys_uses_the_template_and_has_the_conversable_mask()
	local npc = H.loadCreatureTemplate("space/prisk_kith_vys.lua", "prisk_kith_vys")

	lu.assertNotNil(npc, "mobile/space/prisk_kith_vys.lua registers prisk_kith_vys")
	lu.assertEquals(npc.conversationTemplate, "prisk_convo_template", "prisk_kith_vys: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "prisk_kith_vys: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "prisk_kith_vys: optionsBitmask (Hakassha's mask)")
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_template_include_line_follows_the_hakassha_include_exactly_once_under_the_black_epsilon_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/black_epsilon_squadron/prisk_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented prisk_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented prisk_convo include")

	local comment = text:find("-- Black Epsilon Squadron", 1, true)
	local include = text:find("conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua", 1, true)
	local nextComment = text:find("-- Imperial Inquisition Squadron", comment or 1, true)

	lu.assertTrue(comment ~= nil and include ~= nil and include > comment and include < nextComment, "space_conversations.lua: the include sits under '-- Black Epsilon Squadron'")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the hakassha_convo include")
	lu.assertEquals(lines[at + 1] and lines[at + 1]:match("^%s*(.-)%s*$"), 'includeFile("conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua")',
		"space_conversations.lua: the prisk_convo include directly after the hakassha_convo include")
end

-- AC-1
function TestBlackEpsilonT2Wiring:test_the_handler_include_line_follows_the_hakassha_handler_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented priskConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented priskConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local squadron, hakassha

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/BlackEpsilonSquadronScreenplay.lua")', 1, true) then
			squadron = i
		elseif l:find('includeFile("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua")', 1, true) then
			hakassha = i
		end
	end

	lu.assertNotNil(squadron, "screenplays.lua: the BlackEpsilonSquadronScreenplay include")
	lu.assertEquals(hakassha, squadron + 2, "screenplays.lua: the Hakassha handler include stays 2 lines after the squadron include (tier 1 pin)")
	lu.assertEquals(lines[hakassha + 1], 'includeFile("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua")', "screenplays.lua: the Prisk handler include, directly after the Hakassha one, no blank line")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Tables = {}

function TestBlackEpsilonT2Tables:setUp() H.reset() end

-- AC-2, I-1
function TestBlackEpsilonT2Tables:test_the_twelve_tables_keep_their_identity_and_zone()
	for _, global in ipairs(P.GLOBALS) do
		local q = quest(global)
		local id = P.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_corellia", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestBlackEpsilonT2Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = P.expected()

	for _, global in ipairs(P.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2, I-6
function TestBlackEpsilonT2Tables:test_only_patrol_15_and_assassinate_17_split()
	for _, global in ipairs(P.GLOBALS) do
		lu.assertEquals(quest(global).sideQuest and true or false, global == P.P15 or global == P.A17, global .. ": sideQuest")
	end

	local p15 = quest(P.P15)

	lu.assertEquals({ p15.sideQuestType, p15.sideQuestName }, { "destroy_surpriseattack", "corellia_imperial_15_split" }, P.P15 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(p15.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.PATROL_POINT, P.P15 .. ": sideQuestSplitType")
	lu.assertEquals({ p15.sideQuestPatrolStart, p15.sideQuestDelay }, { 4, 20 }, P.P15 .. ": sideQuestPatrolStart, sideQuestDelay (the .tab triggerOn 4, triggerDelay 20)")

	local a17 = quest(P.A17)

	lu.assertEquals({ a17.sideQuestType, a17.sideQuestName }, { "survival", "corellia_tier2_final" }, P.A17 .. ": sideQuestType, sideQuestName")
	lu.assertEquals(a17.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, P.A17 .. ": sideQuestSplitType (triggerSplitCondition success)")
	lu.assertEquals(a17.sideQuestDelay, 5, P.A17 .. ": sideQuestDelay (no triggerDelay: 0 + 5)")

	lu.assertEquals({ quest(P.S15).parentQuest, quest(P.S15).parentQuestType, quest(P.S15).parentQuestName }, { P.P15, "patrol", "corellia_imperial_15" }, P.S15 .. ": parent fields")
	lu.assertEquals({ quest(P.FINAL).parentQuest, quest(P.FINAL).parentQuestType, quest(P.FINAL).parentQuestName }, { P.A17, "assassinate", "corellia_imperial_17" }, P.FINAL .. ": parent fields")
end

-- AC-2, I-5: credits and items only on the four heads and the duties
function TestBlackEpsilonT2Tables:test_credits_and_items_sit_on_the_four_mission_heads_and_the_duties_only()
	local pays = { [P.A12] = 5000, [P.I13] = 5000, [P.A14] = 5000, [P.P15] = 5000, [P.DUTY8] = 200, [P.DUTY9] = 2500, [P.DUTY10] = 200, [P.DUTY11] = 2500 }
	local items = { [P.A12] = P.ITEMS[1], [P.I13] = P.ITEMS[2], [P.A14] = P.ITEMS[3], [P.P15] = P.ITEMS[4] }

	for _, global in ipairs(P.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global] or 0, global .. ": creditReward")

		if items[global] then
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = items[global] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template
function TestBlackEpsilonT2Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

	for _, global in ipairs(P.GLOBALS) do
		local q = quest(global)

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes", "shipList", "attackShipLists" }) do
			walk(rawget(q, field), ships)
		end

		if rawget(q, "recoverShip") then
			ships[q.recoverShip] = true
		end

		walk(rawget(q, "bossShip"), ships)

		for _, entry in ipairs(rawget(q, "itemReward") or {}) do
			items[entry.item] = true
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
	end

	lu.assertEquals(#sortedKeys(ships), 29, "distinct ships in the 12 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 4, "distinct items in the 12 tables: " .. table.concat(sortedKeys(items), ", "))

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
function TestBlackEpsilonT2Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(P.GLOBALS) do
		local id = P.IDENTITY[global]
		local name = "spacequest/" .. id.type .. "/" .. id.name

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Conformance = {}

function TestBlackEpsilonT2Conformance:setUp() H.reset() end

local function label(global) return P.IDENTITY[global].type .. "/" .. P.IDENTITY[global].name end

-- AC-2, I-4: recovery/corellia_imperial_16.tab
function TestBlackEpsilonT2Conformance:test_recovery_16_maps_ships_paths_attack_lists_and_taunts_from_its_fixture()
	local q, rec = quest(P.OPENING), fixtureOf(P.OPENING)
	local l = label(P.OPENING)

	local function path(field, column)
		local rows = pointsOf(rec, column)
		local out = {}

		for i, p in ipairs(rows) do
			lu.assertEquals(p.zone, q.questZone, l .. ": " .. column .. " zone equals questZone")
			out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		lu.assertEquals(q[field], out, l .. ": " .. field .. " (" .. column .. ", no zoneName)")
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	path("preRecoveryPoints", "escortPath")
	path("recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
	lu.assertEquals(rawget(q, "recoveryConversationMobile"), nil, l .. ": no recoveryAppearance column, so recoveryConversationMobile stays the type default")
end

-- AC-2, I-2, I-4: the three assassinate tables
function TestBlackEpsilonT2Conformance:test_assassinate_12_14_and_17_map_target_escorts_delay_and_path()
	for _, global in ipairs({ P.A12, P.A14, P.A17 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local path = {}

		for i, p in ipairs(pointsOf(rec, "escortPath")) do
			path[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y }
			lu.assertEquals(p.zone, q.questZone, l .. ": escortPath zone equals questZone")
		end

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
		lu.assertEquals(q.assassinateSpawns, { target = rec:get("targetShipType"), escorts = rec:list("targetEscort") }, l .. ": assassinateSpawns (targetShipType, targetEscort)")
		lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
		lu.assertEquals(q.targetPatrols, path, l .. ": targetPatrols (escortPath, in file order)")
		lu.assertEquals(q.mustDestroyEscort, rec:num("mustDestroyEscort") == 1, l .. ": mustDestroyEscort")
		lu.assertEquals(q.failTimer, 20, l .. ": failTimer (Core3-only)")
	end

	lu.assertEquals(quest(P.A17).assassinateSpawns.escorts, {}, P.A17 .. ": no targetEscort cells, so an empty escort list")
end

-- AC-2, I-2, I-4: inspect/corellia_imperial_13.tab
function TestBlackEpsilonT2Conformance:test_inspect_13_maps_ship_spawner_waypoint_flag_and_cargo()
	local q, rec = quest(P.I13), fixtureOf(P.I13)
	local l = label(P.I13)
	local spawns = rec:list("validSpawns")

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(#q.validSpawns, #spawns, l .. ": number of validSpawns")

	for i, value in ipairs(spawns) do
		local zone, spawnName = H.Tab.splitNavPoint(value)
		local s = H.spawners(zone)[spawnName]

		lu.assertNotNil(s, l .. ": spawner " .. spawnName .. " in " .. zone)
		lu.assertEquals(zone, q.questZone, l .. ": validSpawns zone equals questZone")
		lu.assertEquals(q.validSpawns[i], { spawnName = spawnName, x = s.x, z = s.z, y = s.y }, l .. ": validSpawns[" .. i .. "] (" .. spawnName .. ")")
	end

	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
end

-- AC-2, I-4: patrol/corellia_imperial_15.tab
function TestBlackEpsilonT2Conformance:test_patrol_15_maps_points_and_split_from_its_fixture()
	local q, rec = quest(P.P15), fixtureOf(P.P15)
	local l = label(P.P15)
	local points = {}

	for i, p in ipairs(pointsOf(rec, "navPoints")) do
		points[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, patrolNumber = i, radius = 150 }
	end

	local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.patrolPoints, points, l .. ": patrolPoints (navPoints)")
	lu.assertEquals(q.sideQuestPatrolStart, rec:num("triggerOn"), l .. ": sideQuestPatrolStart (triggerOn)")
	lu.assertEquals(q.sideQuestDelay, rec:num("triggerDelay"), l .. ": sideQuestDelay (triggerDelay)")
	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, l .. ": sideQuestType, sideQuestName (triggerArg)")
end

-- AC-2, I-4: destroy_surpriseattack/corellia_imperial_15_split.tab, by replaying SWG's spawn loop
function TestBlackEpsilonT2Conformance:test_surprise_attack_15_equals_the_replay_of_the_swg_spawn_loop()
	local q = quest(P.S15)

	lu.assertEquals(q.surpriseAttackShips, { zone = H.questFixture("destroy_surpriseattack", "corellia_imperial_15_split"):get("questZone"), spawns = R.runs(R.replay("corellia_imperial_15_split")) },
		"destroy_surpriseattack/corellia_imperial_15_split: surpriseAttackShips (replay of destroy_surpriseattack.java:78-128)")
	lu.assertEquals(R.replay("corellia_imperial_15_split"), { "reb_xwing_tier2", "reb_xwing_tier2" }, "the replay itself: 2 x reb_xwing_tier2")
end

-- AC-2, I-4: assassinate 17's success split
function TestBlackEpsilonT2Conformance:test_assassinate_17_splits_to_the_survival_on_success_after_5_seconds()
	local q, rec = quest(P.A17), fixtureOf(P.A17)
	local splitType, splitName = H.Tab.splitQuestRef(rec:get("triggerArg"))

	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { splitType, splitName }, "assassinate/corellia_imperial_17: sideQuestType, sideQuestName (triggerArg)")
	lu.assertEquals(q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, "assassinate/corellia_imperial_17: COMPLETION (triggerSplitCondition success)")
	lu.assertEquals(q.sideQuestDelay, (rec:num("triggerDelay") or 0) + 5, "assassinate/corellia_imperial_17: sideQuestDelay (triggerDelay + 5)")
end

-- AC-2, I-4: survival/corellia_tier2_final.tab
function TestBlackEpsilonT2Conformance:test_survival_final_maps_point_timers_attack_lists_and_order_from_its_fixture()
	local q, rec = quest(P.FINAL), fixtureOf(P.FINAL)
	local l = label(P.FINAL)
	local zone, name = H.Tab.splitNavPoint(rec:list("transmissionPoint")[1])
	local p = point(zone, name)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.transmissionPoint, { patrolPointName = name, x = p.x, z = p.z, y = p.y }, l .. ": transmissionPoint")
	lu.assertEquals(q.totalTransmissionTime, rec:num("totalTransmissionTime"), l .. ": totalTransmissionTime")
	lu.assertEquals(q.timesToUpdateProgress, rec:num("timesToUpdateProgress"), l .. ": timesToUpdateProgress")
	lu.assertEquals(q.transmissionStartDelay, rec:num("transmissionStartDelay"), l .. ": transmissionStartDelay")
	lu.assertEquals(q.delayToFirstAttack, rec:num("delayToFirstAttack"), l .. ": delayToFirstAttack")
	lu.assertEquals(q.attackPeriod, rec:num("attackPeriod"), l .. ": attackPeriod")
	lu.assertEquals(q.attackShipLists, attackLists(rec), l .. ": attackShipLists (attackShips1..3, column-wise)")
	lu.assertEquals(rec:get("attackListType"), "sequential", l .. ": precondition: the fixture is sequential")
	lu.assertEquals(q.attackListType, SpaceSurvivalScreenplay.ATTACK_LIST_TYPES.SEQUENTIAL, l .. ": attackListType")
end

-- AC-2, I-4: the two destroy duties
function TestBlackEpsilonT2Conformance:test_destroy_duties_8_and_10_map_waves_rounds_levels_boss_ship_types_and_pay()
	for _, global in ipairs({ P.DUTY8, P.DUTY10 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local shipTypes = {}

		for i = 1, rec:num("shipTypes") do
			shipTypes[i] = rec:list("shipType" .. i)
		end

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
		lu.assertEquals(q.totalWaves, rec:num("wavesPerRound"), l .. ": totalWaves (wavesPerRound)")
		lu.assertEquals(q.totalRounds, rec:num("roundsPerLevel"), l .. ": totalRounds (roundsPerLevel)")
		lu.assertEquals(q.totalLevels, rec:num("levelsPerDuty"), l .. ": totalLevels (levelsPerDuty)")
		lu.assertEquals(q.bossShip, rec:get("bossType"), l .. ": bossShip (bossType)")
		lu.assertEquals(q.shipTypes, shipTypes, l .. ": shipTypes (shipType1..shipTypes, column-wise)")
		lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
		lu.assertNil(rawget(q, "minDistance"), l .. ": minDistance stays the type default")
		lu.assertNil(rawget(q, "maxDistance"), l .. ": maxDistance stays the type default")
	end
end

-- AC-2, I-2, I-4: the two escort duties
function TestBlackEpsilonT2Conformance:test_escort_duties_9_and_11_map_ships_path_attack_lists_delay_taunts_and_pay()
	for _, global in ipairs({ P.DUTY9, P.DUTY11 }) do
		local q, rec = quest(global), fixtureOf(global)
		local l = label(global)
		local points = {}

		for i, p in ipairs(pointsOf(rec, "escortPoints")) do
			points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
		end

		lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
		lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes)")
		lu.assertEquals(q.escortPoints, points, l .. ": escortPoints")
		lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
		lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

		local m = math.max(rec:num("numResponses") or 0, 1)

		lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
		lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
		lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
	end
end
