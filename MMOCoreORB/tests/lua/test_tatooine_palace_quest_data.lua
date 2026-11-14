-- Tatooine station palace access: wiring and quest data on SWG-Source's payloads (the four bounty quests and the Hutt recovery duty).
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-1, AC-4, AC-12; invariants I-1 .. I-4 and I-8; Data mapping; Content contract N-1, C-1, C-5, includes).
--
-- The oracle is the SWG-Source files in fixtures/ (the 5 spacequest .tab copies and the two buildout excerpts). tatooine_palace_data.lua P.expected() derives every
-- mapped field from them, never from the Core3 tables under test. The first class (TestPalaceOracle) needs no production code and is green from the start; it
-- proves the fixtures say what the spec relies on.

local lu = require("luaunit")
local H = require("harness")
local P = require("tatooine_palace_data")

P.load()

local G = P.GLOBALS

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

local function lines(text)
	local out = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = l
	end

	return out
end

local function indexOfLine(text, wanted)
	for i, l in ipairs(lines(text)) do
		if l == wanted then
			return i
		end
	end
end

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestPalaceOracle = {}

function TestPalaceOracle:setUp() H.reset() end

-- AC-1 (oracle): the 5 .tab copies and the two java scripts are the research clone's files byte for byte
function TestPalaceOracle:test_the_fixture_copies_equal_the_research_clone_files()
	local SWG = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

	if P.readFile(SWG .. "datatables/spacequest/rescue/" .. P.IDENTITY[G[1]].name .. ".tab") == nil then
		lu.skip("the SWG-Source research clone is not present")
	end

	local pairsOf = {}

	for _, global in ipairs(G) do
		local id = P.IDENTITY[global]

		pairsOf[#pairsOf + 1] = { H.FIXTURES .. "spacequest/" .. id.type .. "/" .. id.name .. ".tab", SWG .. "datatables/spacequest/" .. id.type .. "/" .. id.name .. ".tab" }
	end

	pairsOf[#pairsOf + 1] = { H.FIXTURES .. "script/conversation/generic_newbie_pilot_info_jabbas_palace.java", SWG .. "script/conversation/generic_newbie_pilot_info_jabbas_palace.java" }
	pairsOf[#pairsOf + 1] = { H.FIXTURES .. "script/space/special_loot/palace_access_doc.java", SWG .. "script/space/special_loot/palace_access_doc.java" }

	for _, p in ipairs(pairsOf) do
		local copy, original = P.readFile(p[1]), P.readFile(p[2])

		lu.assertNotNil(copy, p[1] .. " is missing")
		lu.assertNotNil(original, p[2] .. " is missing")
		lu.assertTrue(copy == original, p[1] .. " differs from " .. p[2])
	end
end

-- AC-1 (oracle): the buildout excerpts hold every nav point the 5 tables name, with the rows the spec cites
function TestPalaceOracle:test_the_buildout_excerpts_hold_all_the_named_nav_points()
	for _, global in ipairs(G) do
		local rec = P.fixtureOf(global)

		for _, column in ipairs({ "recoveryPath", "escortPath", "deliveryPoint", "battlePoint" }) do
			for _, value in ipairs(rec:list(column)) do
				local zone, name = H.Tab.splitNavPoint(value)

				lu.assertNotNil(P.buildout(zone).nav[name], global .. ": " .. column .. " " .. value .. " is in the buildout excerpt")
			end
		end
	end
end

-- AC-1 (oracle): the chain triggers of the fixtures are the ones Data mapping describes
function TestPalaceOracle:test_the_fixture_triggers_are_the_spec_chain()
	local function trig(i, col) return P.fixtureOf(G[i]):get(col) end

	lu.assertEquals({ trig(1, "triggerEvent"), trig(1, "triggerSplitCondition"), trig(1, "triggerArg") }, { "splitquest", "success", "delivery_no_pickup:" .. P.IDENTITY[G[2]].name }, "quest 1")
	lu.assertEquals({ trig(2, "triggerEvent"), trig(2, "triggerSplitCondition"), trig(2, "triggerArg") }, { "splitquest", "success", "space_battle:" .. P.IDENTITY[G[3]].name }, "quest 2")
	lu.assertEquals({ trig(3, "triggerEvent"), trig(3, "triggerSplitCondition"), trig(3, "triggerArg"), trig(3, "triggerArg2") },
		{ "splitquest", "both", "assassinate:" .. P.IDENTITY[G[4]].name, "assassinate:" .. P.IDENTITY[G[4]].name }, "quest 3")
	lu.assertEquals(trig(4, "triggerEvent"), "none", "quest 4")
	lu.assertEquals(P.fixtureOf(G[4]):num("autoReward"), 10000, "quest 4 autoReward")
end

-- AC-1 (oracle): the fixture-derived values are the numbers the spec's Data mapping prints (so the derivation itself is checked)
function TestPalaceOracle:test_the_derivation_reproduces_the_spec_literals()
	local want = P.expected()

	lu.assertEquals(want[G[1]].recoveryPath[4], { patrolPointName = "tatooine_station_hutt_palace_access_rescue_4", x = -686, z = -3396, y = 1450 }, "quest 1: point 4")
	lu.assertEquals(#want[G[1]].attackShipLists[1], 4, "quest 1: list 1 has 4 ships")
	lu.assertEquals(want[G[2]].deliveryPoint, { patrolPointName = "tatooine_station_hutt_palace_access_quest_delivery_point", x = -1267, z = 6104, y = 5748 }, "quest 2: delivery point")
	lu.assertEquals(want[G[3]].battlePoint.forward, { x = 0.396131, z = -0.018721, y = -0.918003 }, "quest 3: forward")
	lu.assertEquals(#want[G[3]].enemyForce, 5, "quest 3: five enemies")
	lu.assertEquals(want[G[4]].targetPatrols[4], { patrolPointName = "tatooine_station_hutt_access_assassinate_4", x = 169, z = 6390, y = -939 }, "quest 4: point 4")
	lu.assertEquals(want[G[4]].mustDestroyEscort, false, "quest 4: mustDestroyEscort")
	lu.assertEquals(want[G[5]].recoveryPoints[3], { patrolPointName = "tatooine_station_hutt_recovery_duty_7", x = 6935, z = -5165, y = -1852, escortNumber = 3, radius = 250 }, "duty: recovery point 3")
	lu.assertEquals(want[G[5]].recoveryConversationMobile, "object/mobile/shared_dressed_hutt_expedition_force_member.iff", "duty: conversation mobile")
end

---------------------------------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------------------------------

TestPalaceWiring = {}

function TestPalaceWiring:setUp() H.reset() end

-- AC-1, I-1: the feature file loads
function TestPalaceWiring:test_the_feature_screenplay_file_loads_without_error()
	local problems = {}

	for _, e in ipairs(P.loadErrors) do
		if e:find(P.FEATURE_FILE, 1, true) then
			problems[#problems + 1] = e
		end
	end

	lu.assertEquals(problems, {}, "load errors of screenplays/" .. P.FEATURE_FILE .. " (N-1)")
end

-- AC-1, I-1: className, questType, questName, zone, class and registerScreenPlay(global, true) of each of the 5 tables
function TestPalaceWiring:test_each_table_has_its_identity_class_and_is_registered_as_a_start_screenplay()
	for _, global in ipairs(G) do
		local q = P.quest(global)
		local id = P.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.questType, id.type, global .. ": questType")
		lu.assertEquals(q.questName, id.name, global .. ": questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)

		local reg = H.registered(global)

		lu.assertNotNil(reg, global .. ": registerScreenPlay(" .. global .. ", true) ran")
		lu.assertEquals(reg and reg.start, true, global .. ": registered with start = true")
	end
end

-- AC-1 (N-1): the station screenplay object and its constants
function TestPalaceWiring:test_the_station_screenplay_registers_without_start_and_has_the_contract_constants()
	local sp = P.screenplay()
	local reg = H.registered(P.SCREENPLAY)

	lu.assertNotNil(reg, "registerScreenPlay(TatooineStationPalaceAccessScreenplay, false) ran")
	lu.assertEquals(reg and reg.start, false, "registered with start = false")
	lu.assertEquals(sp.QUEST_HEAD, P.QUEST_HEAD, "QUEST_HEAD")
	lu.assertEquals(sp.QUEST_STRINGS, P.QUEST_STRINGS, "QUEST_STRINGS")
	lu.assertEquals(sp.ACCESS_KEY, P.ACCESS_KEY, "ACCESS_KEY")
	lu.assertEquals(sp.ACCESS_DOC, P.ACCESS_DOC, "ACCESS_DOC")
	lu.assertEquals(sp.SIGNATURE_KEY, P.SIGNATURE_KEY, "SIGNATURE_KEY")
	lu.assertEquals(sp.TRAVEL_POINT, "jabbas_palace", "TRAVEL_POINT")
	lu.assertEquals(sp.HUTT_DUTY, P.HUTT_DUTY, "HUTT_DUTY")
	lu.assertEquals(sp.HUTT_DUTY_STRING, P.HUTT_DUTY_STRING, "HUTT_DUTY_STRING")
end

-- AC-1 (N-1): the functions handler tests call
function TestPalaceWiring:test_the_station_screenplay_has_the_contract_functions()
	local sp = P.screenplay()

	for _, fn in ipairs({ "hasPalaceAccess", "grantPalaceAccess", "getAccessDoc", "getDocSignature", "removeAccessDocs", "isOfferEligible", "startBounty", "isHuttWorkEligible", "startHuttDuty" }) do
		lu.assertEquals(type(sp[fn]), "function", "TatooineStationPalaceAccessScreenplay:" .. fn)
	end
end

-- AC-5, AC-6 (N-1): the menu component's five functions
function TestPalaceWiring:test_the_document_menu_component_has_the_contract_functions()
	local c = P.menuComponent()

	for _, fn in ipairs({ "fillObjectMenuResponse", "handleObjectMenuSelect", "showDoc", "readCallback", "signCallback" }) do
		lu.assertEquals(type(c[fn]), "function", "PalaceAccessDocMenuComponent:" .. fn)
	end
end

-- AC-1 (N-1): quest 4 overrides completeQuest at file scope
function TestPalaceWiring:test_quest_4_has_its_own_completeQuest_and_the_other_quests_do_not()
	local q4 = P.quest(G[4])

	lu.assertNotNil(rawget(q4, "completeQuest"), G[4] .. ": its own completeQuest function (N-1, R-7)")
	lu.assertNotNil(rawget(q4, "autoRewardCredits"), G[4] .. ": its own autoRewardCredits field")

	for i = 1, 3 do
		lu.assertNil(rawget(P.quest(G[i]), "completeQuest"), G[i] .. ": no completeQuest override")
	end
end

-- AC-8 (C-5): the travel point
function TestPalaceWiring:test_the_station_travel_points_hold_jabbas_palace()
	local station = H.expectGlobal("SpaceStationScreenPlay", "spacestation.lua")

	lu.assertEquals(station.travelPoints.jabbas_palace, { "tatooine", -6171, 90, -6382 }, "travelPoints.jabbas_palace (SWG launch_locations.tab:32)")
	lu.assertEquals(station.travelPoints.coronet, { "corellia", -66, 28, -4705 }, "an existing travel point is untouched")
end

-- AC-1 (Includes): the three new include lines, in the places the spec names
function TestPalaceWiring:test_the_include_lines_are_in_the_space_loader_files_in_the_specified_places()
	local screenplays = P.readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local conversations = P.readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")

	lu.assertNotNil(screenplays, "screenplays/space/screenplays.lua")
	lu.assertNotNil(conversations, "mobile/conversations/space/space_conversations.lua")

	local feature = indexOfLine(screenplays, 'includeFile("' .. P.FEATURE_FILE .. '")')
	local yavin = indexOfLine(screenplays, 'includeFile("space/spacestations/spacestation_yavin4_conv_handler.lua")')

	lu.assertNotNil(feature, 'screenplays/space/screenplays.lua includes "' .. P.FEATURE_FILE .. '"')
	lu.assertNotNil(yavin, "the yavin4 station handler include is still there")
	lu.assertEquals(feature, yavin + 1, "the feature file is included right after spacestation_yavin4_conv_handler.lua")

	local handler = indexOfLine(screenplays, 'includeFile("' .. P.PILOT_HANDLER_FILE .. '")')
	local nirame = indexOfLine(screenplays, 'includeFile("space/conversations/neutral/smuggler_squadron/nirameSakuteConvoHandler.lua")')

	lu.assertNotNil(handler, 'screenplays/space/screenplays.lua includes "' .. P.PILOT_HANDLER_FILE .. '"')
	lu.assertNotNil(nirame, "Nirame's handler include is still there")
	lu.assertTrue(handler ~= nil and nirame ~= nil and handler > nirame, "the pilot handler is included after the last Smuggler handler (Nirame)")

	local template = indexOfLine(conversations, 'includeFile("' .. P.PILOT_TEMPLATE_FILE .. '")')
	local niraTemplate = indexOfLine(conversations, 'includeFile("conversations/space/neutral/smuggler_squadron/nirame_sakute_convo.lua")')

	lu.assertNotNil(template, 'space_conversations.lua includes "' .. P.PILOT_TEMPLATE_FILE .. '"')
	lu.assertTrue(template ~= nil and niraTemplate ~= nil and template > niraTemplate, "the pilot template is included after the last Smuggler template (Nirame)")
end

---------------------------------------------------------------------------------------------
-- Quest data (AC-1, AC-12)
---------------------------------------------------------------------------------------------

TestPalaceQuestData = {}

function TestPalaceQuestData:setUp() H.reset() end

-- AC-1, AC-12, I-1: every mapped field of every table equals the value derived from its fixture, with the quest and field in the message
function TestPalaceQuestData:test_every_mapped_field_equals_the_value_derived_from_its_fixture()
	local want = P.expected()

	for _, global in ipairs(G) do
		local id = P.IDENTITY[global]
		local q = P.quest(global)

		for key, value in pairs(want[global]) do
			lu.assertEquals(q[key], value, id.type .. "/" .. id.name .. ": " .. key)
		end
	end
end

-- AC-1: the spec's explicit numbers, so a failure names the field even when the derivation above changes
function TestPalaceQuestData:test_quest_1_rescue_has_the_data_mapping_numbers()
	local q = P.quest(G[1])

	lu.assertEquals(q.recoveryPath, {
		{ patrolPointName = "tatooine_station_hutt_palace_access_rescue_1", x = 4527, z = -1839, y = 2143 },
		{ patrolPointName = "tatooine_station_hutt_palace_access_rescue_2", x = 2576, z = -2002, y = 1586 },
		{ patrolPointName = "tatooine_station_hutt_palace_access_rescue_3", x = 1128, z = -2914, y = 1754 },
		{ patrolPointName = "tatooine_station_hutt_palace_access_rescue_4", x = -686, z = -3396, y = 1450 },
	}, "quest 1: recoveryPath")
	lu.assertEquals(q.targetShipType, "huttsmuggler_tier3", "quest 1: targetShipType")
	lu.assertEquals(q.targetArrivalDelay, 10, "quest 1: targetArrivalDelay")
	lu.assertEquals(q.attackShipLists, {
		{ "imp_tie_bomber_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3" },
		{ "imp_tie_interceptor_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3", "imp_tie_fighter_tier3" },
	}, "quest 1: attackShipLists")
	lu.assertEquals(q.attackPeriod, 90, "quest 1: attackPeriod")
	lu.assertEquals(q.attackListType, SpaceRescueScreenplay.ATTACK_LIST_TYPES.RANDOM, "quest 1: attackListType random")
	lu.assertEquals(q.numResponses, 5, "quest 1: numResponses")
	lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName, q.sideQuestSplitType, q.sideQuestDelay },
		{ true, "delivery_no_pickup", "tatooine_station_hutt_palace_access_quest_2", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, 5 }, "quest 1: split to quest 2")
	lu.assertEquals({ q.creditReward, q.itemReward }, { 0, {} }, "quest 1: no reward")
end

-- AC-1
function TestPalaceQuestData:test_quest_2_delivery_no_pickup_has_the_data_mapping_numbers()
	local q = P.quest(G[2])

	lu.assertEquals(q.deliveryPoint, { patrolPointName = "tatooine_station_hutt_palace_access_quest_delivery_point", x = -1267, z = 6104, y = 5748 }, "quest 2: deliveryPoint")
	lu.assertEquals(q.deliveryShip, "smuggler_yt1300_tier3", "quest 2: deliveryShip")
	lu.assertEquals(q.attackShipLists, { { "vylukh_clan_soldier_tier3", "vylukh_clan_soldier_tier3" }, { "vylukh_clan_elite_tier3", "vylukh_clan_elite_tier3" } }, "quest 2: attackShipLists")
	lu.assertEquals(q.attackPeriod, 120, "quest 2: attackPeriod")
	lu.assertEquals(q.attackListType, SpaceDeliveryScreenplay.ATTACK_LIST_TYPES.RANDOM, "quest 2: attackListType random")
	lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName, q.sideQuestSplitType, q.sideQuestDelay },
		{ true, "space_battle", "tatooine_station_hutt_palace_access_quest_3", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, 5 }, "quest 2: split to quest 3")
end

-- AC-1
function TestPalaceQuestData:test_quest_3_space_battle_has_the_data_mapping_numbers()
	local q = P.quest(G[3])

	lu.assertEquals(q.battlePoint, {
		patrolPointName = "tatooine_station_hutt_palace_access_battle_point", x = 801, z = 6389, y = 2157,
		forward = { x = 0.396131, z = -0.018721, y = -0.918003 },
	}, "quest 3: battlePoint incl. forward (buildout fltKX, fltKY, fltKZ)")
	lu.assertEquals({ q.damageMultiplier, q.allyArrivalDelay, q.enemyArrivalDelay }, { 6, 30, 40 }, "quest 3: damageMultiplier, allyArrivalDelay, enemyArrivalDelay")
	lu.assertEquals({ q.allyOriginDist, q.enemyOriginDist, q.allyArrivalDist, q.enemyArrivalDist }, { 100, -500, 800, 500 }, "quest 3: origin and arrival distances")
	lu.assertEquals(q.allyForce, { "valarian_smuggler_tier2", "valarian_smuggler_tier2" }, "quest 3: allyForce")
	lu.assertEquals(q.enemyForce, { "hutt_fighter_s02_tier3", "hutt_heavy_s02_tier3", "hutt_fighter_s02_tier2", "hutt_fighter_s02_tier2", "hutt_fighter_s02_tier2" }, "quest 3: enemyForce (row order kept)")
	lu.assertEquals({ q.sideQuest, q.sideQuestType, q.sideQuestName, q.sideFailQuestType, q.sideFailQuestName, q.sideQuestSplitType, q.sideQuestDelay },
		{ true, "assassinate", "tatooine_station_hutt_palace_access_quest_4", "assassinate", "tatooine_station_hutt_palace_access_quest_4", SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, 5 },
		"quest 3: bidirectional split to quest 4 on win and on loss")
end

-- AC-1
function TestPalaceQuestData:test_quest_4_assassinate_has_the_data_mapping_numbers()
	local q = P.quest(G[4])

	lu.assertEquals(q.targetPatrols, {
		{ patrolPointName = "tatooine_station_hutt_access_assassinate_1", x = 992, z = 6370, y = 909 },
		{ patrolPointName = "tatooine_station_hutt_access_assassinate_2", x = 966, z = 6111, y = -478 },
		{ patrolPointName = "tatooine_station_hutt_access_assassinate_3", x = 921, z = 5801, y = -1918 },
		{ patrolPointName = "tatooine_station_hutt_access_assassinate_4", x = 169, z = 6390, y = -939 },
	}, "quest 4: targetPatrols")
	lu.assertEquals(q.assassinateSpawns, { target = "hutt_quest_hortrix_steelarm_tier3", escorts = { "hutt_pirate_s02_tier2", "hutt_pirate_s02_tier2" } }, "quest 4: assassinateSpawns")
	lu.assertEquals(q.arrivalDelay, 5, "quest 4: arrivalDelay")
	lu.assertEquals(q.mustDestroyEscort, false, "quest 4: mustDestroyEscort is false, not 0")
	lu.assertEquals(q.failTimer, 20, "quest 4: failTimer (type default)")
	lu.assertEquals(q.sideQuest, false, "quest 4: starts nothing")
	lu.assertEquals(q.autoRewardCredits, 10000, "quest 4: autoRewardCredits")
	lu.assertEquals(q.creditReward, 0, "quest 4: creditReward (the reward is the auto reward)")
end

-- AC-12
function TestPalaceQuestData:test_the_duty_has_the_data_mapping_numbers()
	local q = P.quest(G[5])

	lu.assertEquals(q.preRecoveryPoints, {
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_1", x = 3796, z = -5228, y = 490, escortNumber = 1, radius = 250 },
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_2", x = 2853, z = -5640, y = -623, escortNumber = 2, radius = 250 },
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_3", x = 2667, z = -6221, y = -1908, escortNumber = 3, radius = 250 },
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_4", x = 1212, z = -5888, y = -2603, escortNumber = 4, radius = 250 },
	}, "duty: preRecoveryPoints (4)")
	lu.assertEquals(q.recoveryPoints, {
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_5", x = 3485, z = -5917, y = -4160, escortNumber = 1, radius = 250 },
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_6", x = 5688, z = -5517, y = -3706, escortNumber = 2, radius = 250 },
		{ patrolPointName = "tatooine_station_hutt_recovery_duty_7", x = 6935, z = -5165, y = -1852, escortNumber = 3, radius = 250 },
	}, "duty: recoveryPoints (3)")
	lu.assertEquals(q.recoverShips, { "freighterheavy_tier2", "freighterlight_tier2", "freightermedium_tier2" }, "duty: recoverShips")
	lu.assertEquals(q.escortShips, { "mercenary_guard_tier2", "mercenary_guard_tier1", "mercenary_guard_tier1" }, "duty: escortShips")
	lu.assertEquals({ #q.attackShips[1], #q.attackShips[2], #q.attackShips[3], #q.attackShips }, { 2, 3, 4, 3 }, "duty: attack list sizes 2, 3, 4 and three lists")
	lu.assertEquals(q.attackShips[1], { "valarian_bomber_tier1_tatooine", "valarian_bomber_tier2" }, "duty: attackShips[1]")
	lu.assertEquals(q.attackShips[3], { "mos_eisley_police", "mos_eisley_police", "mos_eisley_police", "mos_eisley_police" }, "duty: attackShips[3]")
	lu.assertEquals({ q.arrivalDelay, q.recoveryDelay, q.attackDelay }, { 10, 30, 70 }, "duty: arrivalDelay, recoveryDelay, attackDelay")
	lu.assertEquals({ q.creditReward, q.creditKillBonus, q.numResponses }, { 1000, 100, 5 }, "duty: creditReward, creditKillBonus, numResponses")
	lu.assertEquals(q.tauntData, { panicCount = 5, thanksCount = 5 }, "duty: tauntData")
	lu.assertEquals(q.recoveryConversationMobile, "object/mobile/shared_dressed_hutt_expedition_force_member.iff", "duty: recoveryConversationMobile")
	lu.assertEquals({ q.sideQuest, q.sideQuestType }, { false, "" }, "duty: no split")
end

-- I-2: the patrol points a table names exist in the patrol point files with equal coordinates
function TestPalaceQuestData:test_every_named_patrol_point_exists_in_its_zone_with_equal_coordinates()
	local function check(global, zone, point)
		local file = H.patrolPoints(zone)[point.patrolPointName]

		lu.assertNotNil(file, global .. ": patrol point " .. point.patrolPointName .. " in ship_mobile/patrol_points/" .. zone .. ".lua")
		lu.assertEquals({ file.x, file.z, file.y }, { point.x, point.z, point.y }, global .. ": " .. point.patrolPointName .. " x, z, y")
	end

	local q1, q2, q3, q4, duty = P.quest(G[1]), P.quest(G[2]), P.quest(G[3]), P.quest(G[4]), P.quest(G[5])

	for _, p in ipairs(q1.recoveryPath) do check(G[1], "space_tatooine", p) end
	check(G[2], "space_yavin4", q2.deliveryPoint)
	check(G[3], "space_yavin4", q3.battlePoint)
	for _, p in ipairs(q4.targetPatrols) do check(G[4], "space_yavin4", p) end
	for _, p in ipairs(duty.preRecoveryPoints) do check(G[5], "space_tatooine", p) end
	for _, p in ipairs(duty.recoveryPoints) do check(G[5], "space_tatooine", p) end
end

-- I-3: every ship template a table names has a file under ship_mobile/ships
function TestPalaceQuestData:test_every_ship_a_table_names_has_a_ship_template()
	local function names(...)
		local out = {}

		for _, v in ipairs({ ... }) do
			if type(v) == "string" then
				out[#out + 1] = v
			elseif type(v) == "table" then
				for _, n in ipairs(names(table.unpack(v))) do
					out[#out + 1] = n
				end
			end
		end

		return out
	end

	local q1, q2, q3, q4, duty = P.quest(G[1]), P.quest(G[2]), P.quest(G[3]), P.quest(G[4]), P.quest(G[5])
	local used = {
		[G[1]] = names(q1.targetShipType, q1.attackShipLists),
		[G[2]] = names(q2.deliveryShip, q2.attackShipLists),
		[G[3]] = names(q3.allyForce, q3.enemyForce),
		[G[4]] = names(q4.assassinateSpawns.target, q4.assassinateSpawns.escorts),
		[G[5]] = names(duty.recoverShips, duty.escortShips, duty.attackShips),
	}

	for _, global in ipairs(G) do
		lu.assertTrue(#used[global] > 0, global .. ": names ships")

		for _, ship in ipairs(used[global]) do
			lu.assertNotNil(H.shipTemplate(ship), global .. ": ship_mobile/ships/" .. ship .. ".lua exists")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The chain (I-4, I-8)
---------------------------------------------------------------------------------------------

TestPalaceChain = {}

function TestPalaceChain:setUp() H.reset() end

-- I-4: the chain from quest 1 is exactly the four tables in order
function TestPalaceChain:test_the_chain_of_quest_1_is_the_four_tables_in_order()
	for _, global in ipairs(G) do
		P.quest(global)
	end

	local chain = SpaceHelpers:getSpaceQuestChain(P.QUEST_HEAD)
	local got = {}

	for i, c in ipairs(chain) do
		got[i] = c.global
	end

	lu.assertEquals(got, P.CHAIN, "getSpaceQuestChain(" .. P.QUEST_HEAD .. ")")
	lu.assertEquals(chain[4] and { chain[4].type, chain[4].name }, { "assassinate", "tatooine_station_hutt_palace_access_quest_4" }, "the chain ends with quest 4")
end

-- I-4: every child names its predecessor; only quest 1 has no parent
function TestPalaceChain:test_each_child_names_its_predecessor_and_only_quest_1_has_no_parent()
	lu.assertEquals(P.quest(G[1]).parentQuest or "", "", "quest 1: no parentQuest")

	for i = 2, 4 do
		local q, parent = P.quest(G[i]), P.IDENTITY[G[i - 1]]

		lu.assertEquals({ q.parentQuest, q.parentQuestType, q.parentQuestName }, { G[i - 1], parent.type, parent.name }, G[i] .. ": parentQuest, parentQuestType, parentQuestName")
	end
end

-- I-8: the duty is in no chain
function TestPalaceChain:test_the_duty_is_in_no_chain()
	for _, global in ipairs(G) do
		P.quest(global)
	end

	local chain = SpaceHelpers:getSpaceQuestChain(P.HUTT_DUTY)

	lu.assertEquals(#chain, 1, "getSpaceQuestChain(" .. P.HUTT_DUTY .. ") is the duty alone")
	lu.assertEquals(chain[1] and chain[1].global, P.HUTT_DUTY, "the one member is the duty")

	for i = 1, 4 do
		local q = P.quest(G[i])

		for _, field in ipairs({ "sideQuestName", "sideFailQuestName", "parentQuestName" }) do
			lu.assertNotEquals(q[field], P.IDENTITY[G[5]].name, G[i] .. ": " .. field .. " does not name the duty")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The drop path (AC-4)
---------------------------------------------------------------------------------------------

TestPalaceDropPath = {}

function TestPalaceDropPath:setUp() H.reset() end

-- AC-4
function TestPalaceDropPath:test_hortrix_drops_the_palace_loot_group_every_time()
	local ship = H.shipTemplate("hutt_quest_hortrix_steelarm_tier3")

	lu.assertNotNil(ship, "ship_mobile/ships/hutt_quest_hortrix_steelarm_tier3.lua registers a template")
	lu.assertEquals(ship.lootChance, 1, "lootChance")
	lu.assertTrue(ship.lootRolls >= 1, "lootRolls >= 1 (got " .. tostring(ship.lootRolls) .. ")")
	lu.assertEquals(ship.lootTable, "space_hortrix_steelarm_quest", "lootTable")
end

local function runLoot(rel, env)
	local chunk, err = loadfile(H.SCRIPTS .. rel, "t", setmetatable(env, { __index = _G }))

	lu.assertNotNil(chunk, "cannot load " .. rel .. ": " .. tostring(err))
	chunk()
end

-- AC-4: the group holds one item, the document
function TestPalaceDropPath:test_the_loot_group_holds_only_the_palace_access_doc_item()
	local groups = {}

	runLoot("loot/groups/space/story_loot/space_hortrix_steelarm_quest.lua", { addLootGroupTemplate = function(name, t) groups[name] = t end })

	local group = groups["space_hortrix_steelarm_quest"]

	lu.assertNotNil(group, "the file registers the loot group space_hortrix_steelarm_quest")
	lu.assertEquals(#group.lootItems, 1, "one item in the group")
	lu.assertEquals(group.lootItems[1].itemTemplate, "space_palace_access_doc", "the item")
end

-- AC-4: the item is the document template
function TestPalaceDropPath:test_the_loot_item_is_the_document_object_template()
	local items = {}

	runLoot("loot/items/space/mission_objects/space_palace_access_doc.lua", { addLootItemTemplate = function(name, t) items[name] = t end })

	local item = items["space_palace_access_doc"]

	lu.assertNotNil(item, "the file registers the loot item space_palace_access_doc")
	lu.assertEquals(item.directObjectTemplate, P.ACCESS_DOC, "directObjectTemplate")
end

-- AC-4, C-1: the document's object template names the menu component
function TestPalaceDropPath:test_the_document_object_template_names_the_menu_component()
	local captured = {}

	runLoot("object/tangible/space/mission_objects/palace_access_doc.lua", {
		ObjectTemplates = { addTemplate = function(_, template, path) captured[path] = template end },
		object_tangible_space_mission_objects_shared_palace_access_doc = { new = function(_, t) return t end },
	})

	local template = captured[P.ACCESS_DOC]

	lu.assertNotNil(template, "the file registers " .. P.ACCESS_DOC)
	lu.assertEquals(template.objectMenuComponent, "PalaceAccessDocMenuComponent", "palace_access_doc: objectMenuComponent")
end
