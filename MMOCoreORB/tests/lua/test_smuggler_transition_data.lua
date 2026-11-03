-- Smuggler transition (Talon Karrde): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source files in fixtures/ (the two tat_priv_quest_trans .tab copies, the space_lok buildout excerpt, the Shamdon script).
-- smuggler_transition_data.lua T.expected() derives every mapped field from them, never from the Core3 tables under test. The first class
-- (TestSmugglerTransOracle) needs no production code and is green from the start; it proves the fixtures say what the spec relies on and that the
-- Core3 point file already holds the buildout values.

local lu = require("luaunit")
local H = require("harness")
local T = require("smuggler_transition_data")

T.load()

local readFile = T.readFile

local function quest(global) return T.quest(global) end

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

local SWG_BUILDOUT = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/space_zones/buildout/space_lok.tab"
local SWG_DIR = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

---------------------------------------------------------------------------------------------
-- The oracle itself (green without production code)
---------------------------------------------------------------------------------------------

TestSmugglerTransOracle = {}

function TestSmugglerTransOracle:setUp() H.reset() end

-- AC-2 (the oracle itself): the fixture facts the spec relies on, as anchors so a misparsed fixture cannot make a wrong table look right
function TestSmugglerTransOracle:test_the_fixtures_carry_the_values_the_spec_lists()
	local pat, asn = T.patrolFixture(), T.assassinateFixture()

	lu.assertEquals({ pat:get("questZone"), pat:list("navPoints"), pat:num("laps"), pat:get("triggerEvent"), pat:get("triggerSplitCondition"), pat:get("triggerArg"), pat:num("triggerDelay") },
		{ "space_lok", { "space_lok:corellia_privateer_tier3_recovery_point_5" }, 1, "splitquest", "success", "assassinate:tat_priv_quest_trans", 2 }, "patrol/tat_priv_quest_trans")

	lu.assertEquals({ asn:get("questZone"), asn:get("targetShipType"), asn:num("targetArrivalDelay"), asn:list("targetEscort"), asn:get("targetAttackMode"), asn:num("mustDestroyEscort"), asn:get("triggerEvent") },
		{ "space_lok", "corsair_behemoth_tier2", 5, { "corsair_manowar_tier1", "corsair_manowar_tier1", "corsair_manowar_tier1" }, "returnfire", 1, "none" }, "assassinate/tat_priv_quest_trans")

	lu.assertEquals(asn:list("escortPath"), { "space_lok:corellia_privateer_tier3_recovery_point_7", "space_lok:hostage_recovery_4", "space_lok:lok_imp_escort_duty_7", "space_lok:lok_imp_recovery_4" },
		"assassinate/tat_priv_quest_trans: escortPath")
end

-- AC-2 (the oracle itself): the 5 points, and the order of the assassinate path
function TestSmugglerTransOracle:test_the_buildout_excerpt_holds_the_five_nav_points_with_the_values_the_spec_lists()
	local nav = T.buildout()

	lu.assertEquals(sortedKeys(nav), { "corellia_privateer_tier3_recovery_point_5", "corellia_privateer_tier3_recovery_point_7", "hostage_recovery_4", "lok_imp_escort_duty_7", "lok_imp_recovery_4" },
		"nav_name rows of the excerpt")
	lu.assertEquals(nav.corellia_privateer_tier3_recovery_point_5, { 4692, -604, 3823 }, "patrol point (fltPX 4692.62, fltPY -604.47, fltPZ 3823.40 truncated)")
	lu.assertEquals(nav.corellia_privateer_tier3_recovery_point_7, { 5133, -1919, 2853 }, "assassinate 1")
	lu.assertEquals(nav.hostage_recovery_4, { -6637, 2449, -2060 }, "assassinate 2")
	lu.assertEquals(nav.lok_imp_escort_duty_7, { 4763, -1727, 3174 }, "assassinate 3")
	lu.assertEquals(nav.lok_imp_recovery_4, { 1411, -1579, 134 }, "assassinate 4")
end

-- AC-2 (the oracle itself): the excerpt's 5 rows equal the SWG clone rows, and its 2 header rows the clone's
function TestSmugglerTransOracle:test_the_buildout_excerpt_rows_equal_the_swg_clone_rows()
	local clone = readFile(SWG_BUILDOUT)

	if clone == nil then
		lu.skip("the SWG-Source research clone is not at " .. SWG_BUILDOUT)
	end

	local excerpt = readFile(H.FIXTURES .. "space_zones/buildout/space_lok.smuggler_transition_points.tab")

	lu.assertNotNil(excerpt, "fixtures/space_zones/buildout/space_lok.smuggler_transition_points.tab")

	local cloneLines = {}

	for line in clone:gmatch("[^\n]*\n") do
		cloneLines[line] = true
	end

	local n = 0

	for line in excerpt:gmatch("[^\n]*\n") do
		n = n + 1
		lu.assertTrue(cloneLines[line] == true, "excerpt line " .. n .. " is not a line of the SWG space_lok.tab (CRLF kept)")
	end

	lu.assertEquals(n, 7, "excerpt lines: 2 header rows and 5 nav_name rows")
end

-- AC-2 (the oracle itself): the fixture copies are the research clone's files byte for byte
function TestSmugglerTransOracle:test_the_fixture_copies_equal_the_research_clone_files()
	local files = {
		{ "spacequest/patrol/" .. T.NAME .. ".tab", "datatables/spacequest/patrol/" .. T.NAME .. ".tab" },
		{ "spacequest/assassinate/" .. T.NAME .. ".tab", "datatables/spacequest/assassinate/" .. T.NAME .. ".tab" },
		{ "script/conversation/tatooine_privateer_trainer_2.java", "script/conversation/tatooine_privateer_trainer_2.java" },
		{ "script/conversation/tatooine_privateer_trainer_shamdon.java", "script/conversation/tatooine_privateer_trainer_shamdon.java" },
	}

	for _, f in ipairs(files) do
		local source = readFile(SWG_DIR .. f[2])

		if source == nil then
			lu.skip("the SWG-Source research clone has no " .. f[2])
		end

		lu.assertEquals(readFile(H.FIXTURES .. f[1]), source, "fixtures/" .. f[1] .. " versus the research clone")
	end
end

-- AC-2, I-2 (the oracle itself): Core3's patrol point file already holds the buildout values (truncated toward zero) for the five points
function TestSmugglerTransOracle:test_the_core3_point_file_equals_the_buildout_excerpt_truncated()
	local points = H.patrolPoints("space_lok")

	for name, xyz in pairs(T.buildout()) do
		lu.assertNotNil(points[name], "space_lok patrol point " .. name)
		lu.assertEquals({ points[name].x, points[name].z, points[name].y }, xyz, "space_lok patrol point " .. name .. " (ship_mobile/patrol_points/space_lok.lua) versus the buildout")
	end
end

-- AC-2, I-5 (the oracle itself): Shamdon's script pays 5000 for the assassinate, and nothing in Karrde's script pays at all
function TestSmugglerTransOracle:test_shamdon_pays_5000_for_the_assassinate_and_karrde_pays_nothing()
	lu.assertEquals(T.shamdonReward(), 5000, "SHJ giveReward(player, \"assassinate\", \"tat_priv_quest_trans\", N)")

	local k = readFile(H.FIXTURES .. "script/conversation/tatooine_privateer_trainer_2.java")

	lu.assertNotNil(k, "fixtures/script/conversation/tatooine_privateer_trainer_2.java")
	lu.assertNil(k:find("giveReward", 1, true), "K calls giveReward")
	lu.assertNil(k:find("grantItem", 1, true), "K grants an item")
end

-- I-3 (the oracle itself): the ships the .tab files name have template files
function TestSmugglerTransOracle:test_the_ships_of_the_fixtures_have_template_files()
	local asn = T.assassinateFixture()
	local ships = { asn:get("targetShipType") }

	for _, s in ipairs(asn:list("targetEscort")) do
		ships[#ships + 1] = s
	end

	for _, name in ipairs(ships) do
		lu.assertNotNil(readFile(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua"), "ship_mobile/ships/" .. name .. ".lua")
	end
end

-- I-7 (the oracle itself): the client journal knows both quests (this is why they can be granted at all)
function TestSmugglerTransOracle:test_both_quests_are_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")

	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(T.GLOBALS) do
		local id = T.IDENTITY[global]

		lu.assertTrue(set["spacequest/" .. id.type .. "/" .. id.name] == true, "spacequest/" .. id.type .. "/" .. id.name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestSmugglerTransWiring = {}

function TestSmugglerTransWiring:setUp() H.reset() end

-- AC-1
function TestSmugglerTransWiring:test_the_squadron_file_registers_the_two_quests_with_start_true()
	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1: Content contract 1: the section after the tier 1 duty tables, before the squadron object, patrol first
function TestSmugglerTransWiring:test_the_two_globals_sit_after_the_duty_tables_and_before_the_squadron_object_in_the_contract_order()
	local text = readFile(H.SCRIPTS .. T.SQUADRON_FILE)

	lu.assertNotNil(text, T.SQUADRON_FILE)

	local duty = text:find('registerScreenPlay("escort_duty_tatooine_privateer_7", true)', 1, true)
	local squadron = text:find("\nSmugglerSquadronScreenplay = ScreenPlay:new", 1, true)

	lu.assertNotNil(duty, T.SQUADRON_FILE .. ": the last tier 1 duty registration")
	lu.assertNotNil(squadron, T.SQUADRON_FILE .. ": the squadron object")

	local last = duty

	for _, global in ipairs(T.GLOBALS) do
		local at = text:find("\n" .. global .. " = ", 1, true)

		lu.assertNotNil(at, T.SQUADRON_FILE .. ": no global " .. global)
		lu.assertTrue(at > last, T.SQUADRON_FILE .. ": " .. global .. " is out of the Content contract 1 order (after the duties, patrol before assassinate)")
		lu.assertTrue(at < squadron, T.SQUADRON_FILE .. ": " .. global .. " must come before the squadron object")
		last = at

		local reg = text:find('registerScreenPlay("' .. global .. '", true)', 1, true)

		lu.assertTrue(reg ~= nil and reg > at, T.SQUADRON_FILE .. ": registerScreenPlay for " .. global .. " follows its table")
	end

	lu.assertNotNil(text:find("Transition -- Talon Karrde (Lok)", 1, true), T.SQUADRON_FILE .. ": the section comment 'Transition -- Talon Karrde (Lok)'")
	lu.assertEquals(countMatches(text, 'local SpaceHelpers = require%("utils%.space_helpers"%)'), 1, T.SQUADRON_FILE .. ": one SpaceHelpers require (the first line is unchanged)")
end

-- AC-1: Content contract 2
function TestSmugglerTransWiring:test_the_squadron_object_has_the_transition_constants_and_methods()
	local sq = T.squadron()

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "SmugglerSquadronScreenplay." .. field)
	end

	lu.assertEquals(type(sq.hasWonTransQuest), "function", "SmugglerSquadronScreenplay:hasWonTransQuest")
	lu.assertEquals(type(sq.resetKarrdeQuests), "function", "SmugglerSquadronScreenplay:resetKarrdeQuests")
	lu.assertEquals(pcall(sq.resetKarrdeQuests, sq, nil), true, "resetKarrdeQuests(nil) returns early")
	lu.assertEquals(sq.hasWonTransQuest(sq, nil), false, "hasWonTransQuest(nil) is false")

	-- tier 1 stays as it was
	lu.assertEquals(type(sq.resetDravisQuests), "function", "SmugglerSquadronScreenplay:resetDravisQuests still exists")
	lu.assertEquals(sq.QUEST_STRING_1, { type = "patrol", name = "tatooine_privateer_1" }, "tier 1 constants stay")
end

-- AC-1: Content contract 2: the section comments of the new methods
function TestSmugglerTransWiring:test_the_constants_follow_the_duty_constants_under_the_transition_comment()
	local text = readFile(H.SCRIPTS .. T.SQUADRON_FILE)

	lu.assertNotNil(text:find("-- Transition (Talon Karrde) Quest Strings", 1, true), T.SQUADRON_FILE .. ": '-- Transition (Talon Karrde) Quest Strings'")

	local duty4 = text:find("QUEST_STRING_DUTY_4 = ", 1, true)
	local trans = text:find("QUEST_STRING_TRANS = ", 1, true)
	local side = text:find("QUEST_STRING_TRANS_SIDE = ", 1, true)
	local reset = text:find("function SmugglerSquadronScreenplay:resetKarrdeQuests", 1, true)
	local resetDravis = text:find("function SmugglerSquadronScreenplay:resetDravisQuests", 1, true)

	lu.assertTrue(duty4 ~= nil and trans ~= nil and trans > duty4, "QUEST_STRING_TRANS follows the tier 1 duty constants")
	lu.assertTrue(side ~= nil and trans ~= nil and side > trans, "QUEST_STRING_TRANS_SIDE follows QUEST_STRING_TRANS")
	lu.assertTrue(reset ~= nil and resetDravis ~= nil and reset > resetDravis, "resetKarrdeQuests follows resetDravisQuests")
end

-- AC-1
function TestSmugglerTransWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	T.requireConversation(lu)

	local t = H.conversationTemplateTable(T.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, T.HANDLER, T.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", T.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, T.HANDLER).getInitialScreen), "function", T.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, T.HANDLER).runScreenHandlers), "function", T.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, T.HANDLER).getNextConversationScreen), "function", T.HANDLER .. ":getNextConversationScreen")
end

-- AC-1: the handler adds no getNextConversationScreen of its own (Content contract 3)
function TestSmugglerTransWiring:test_the_handler_has_no_next_screen_override()
	T.requireConversation(lu)

	lu.assertNil(rawget(rawget(_G, T.HANDLER), "getNextConversationScreen"), T.HANDLER .. " overrides getNextConversationScreen")
end

-- AC-1
function TestSmugglerTransWiring:test_karrde_uses_the_template_and_has_the_conversable_invulnerable_mask()
	local npc = H.loadCreatureTemplate("space/talon_karrde.lua", "talon_karrde")

	lu.assertNotNil(npc, "mobile/space/talon_karrde.lua registers talon_karrde")
	lu.assertEquals(npc.conversationTemplate, T.TEMPLATE, "talon_karrde: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "talon_karrde: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "talon_karrde: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "talon_karrde: optionsBitmask (the Dravis mask)")
end

-- AC-1: the template include sits directly after Dravis' under '-- Smuggler Squadron', exactly once, uncommented
function TestSmugglerTransWiring:test_the_template_include_line_follows_the_dravis_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = T.INCLUDE_TEMPLATE:gsub("%p", "%%%0")

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented talon_karrde_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented talon_karrde_convo include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l == 'includeFile("conversations/space/neutral/smuggler_squadron/dravis_convo.lua")' then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the dravis_convo include")
	lu.assertEquals(lines[at + 1], T.INCLUDE_TEMPLATE, "space_conversations.lua: the Karrde include, directly after the Dravis include")
end

-- AC-1: the handler include sits directly after Dravis' handler include
function TestSmugglerTransWiring:test_the_handler_include_line_follows_the_dravis_handler_include_exactly_once()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = T.INCLUDE_HANDLER:gsub("%p", "%%%0")

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented talonKarrdeConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented talonKarrdeConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l == 'includeFile("space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua")' then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: the dravisConvoHandler include")
	lu.assertEquals(lines[at + 1], T.INCLUDE_HANDLER, "screenplays.lua: the Karrde handler include, directly after the Dravis handler include")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-5, I-6)
---------------------------------------------------------------------------------------------

TestSmugglerTransTables = {}

function TestSmugglerTransTables:setUp() H.reset() end

-- AC-2, I-1
function TestSmugglerTransTables:test_the_two_tables_keep_their_identity_and_zone()
	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local id = T.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, "space_lok", global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestSmugglerTransTables:test_each_table_equals_the_fixture_derived_contract_and_sets_no_other_key()
	local want = T.expected()

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(ownKeys(q)), sortedKeys(want[global]), global .. ": own keys (Appendix B)")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- AC-2: the explicit numbers of the AC, so a failure names the field even when the derivation above changes
function TestSmugglerTransTables:test_the_patrol_has_one_point_and_a_two_second_split_and_the_assassinate_three_escorts()
	local pat, asn = quest(T.PATROL), quest(T.ASSASSINATE)

	lu.assertEquals(#pat.patrolPoints, 1, T.PATROL .. ": number of patrolPoints")
	lu.assertEquals(pat.sideQuestDelay, 2, T.PATROL .. ": sideQuestDelay")
	lu.assertEquals(pat.patrolPoints[1], { patrolPointName = "corellia_privateer_tier3_recovery_point_5", x = 4692, z = -604, y = 3823, patrolNumber = 1, radius = 150 }, T.PATROL .. ": patrolPoints[1]")
	lu.assertEquals(asn.assassinateSpawns, { target = "corsair_behemoth_tier2", escorts = { "corsair_manowar_tier1", "corsair_manowar_tier1", "corsair_manowar_tier1" } }, T.ASSASSINATE .. ": assassinateSpawns")
	lu.assertEquals(asn.arrivalDelay, 5, T.ASSASSINATE .. ": arrivalDelay")
	lu.assertEquals(#asn.targetPatrols, 4, T.ASSASSINATE .. ": number of targetPatrols")
	lu.assertEquals(asn.creditReward, 5000, T.ASSASSINATE .. ": creditReward (SHJ giveReward)")
end

-- AC-2, I-6: the patrol is the head of a completion split, the assassinate names its parent
function TestSmugglerTransWiring:test_the_patrol_splits_on_completion_into_the_assassinate_and_the_chain_is_exactly_the_two()
	local pat, asn = quest(T.PATROL), quest(T.ASSASSINATE)

	lu.assertTrue(pat.sideQuest, T.PATROL .. ": sideQuest")
	lu.assertEquals(pat.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, T.PATROL .. ": sideQuestSplitType (the .tab splits on success)")
	lu.assertEquals({ pat.sideQuestType, pat.sideQuestName }, { "assassinate", T.NAME }, T.PATROL .. ": the child")
	lu.assertEquals({ asn.parentQuest, asn.parentQuestType, asn.parentQuestName }, { T.PATROL, "patrol", T.NAME }, T.ASSASSINATE .. ": parent fields")
	lu.assertEquals(asn.sideQuest, false, T.ASSASSINATE .. ": sideQuest")

	local chain = SpaceHelpers:getSpaceQuestChain(T.PATROL)

	lu.assertEquals(chain, { { global = T.PATROL, type = "patrol", name = T.NAME }, { global = T.ASSASSINATE, type = "assassinate", name = T.NAME } }, "getSpaceQuestChain(" .. T.PATROL .. ")")
end

-- AC-2, I-5: nothing but the assassinate carries a reward, and no item
function TestSmugglerTransTables:test_only_the_assassinate_carries_the_5000_and_neither_table_has_an_item()
	lu.assertEquals(rawget(quest(T.PATROL), "creditReward") or 0, 0, T.PATROL .. ": creditReward (K pays nothing)")
	lu.assertNil(rawget(quest(T.PATROL), "itemReward"), T.PATROL .. ": itemReward")
	lu.assertNil(rawget(quest(T.ASSASSINATE), "itemReward"), T.ASSASSINATE .. ": itemReward")
end

-- I-3: every ship the tables name has a ship template
function TestSmugglerTransTables:test_every_ship_the_tables_name_has_a_template_file()
	local asn = quest(T.ASSASSINATE)
	local ships = { asn.assassinateSpawns.target }

	for _, s in ipairs(asn.assassinateSpawns.escorts) do
		ships[#ships + 1] = s
	end

	for _, name in ipairs(ships) do
		local f = io.open(H.SCRIPTS .. "ship_mobile/ships/" .. name .. ".lua", "r")

		lu.assertNotNil(f, "ship_mobile/ships/" .. name .. ".lua does not exist")
		f:close()
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4): production versus the derived values, point by point
---------------------------------------------------------------------------------------------

TestSmugglerTransConformance = {}

function TestSmugglerTransConformance:setUp() H.reset() end

-- AC-2, I-2: every point of both tables is a Core3 patrol point with the same x, z, y, in .tab order
function TestSmugglerTransConformance:test_every_patrol_and_target_point_resolves_in_the_space_lok_point_file_with_the_same_coordinates()
	local points = H.patrolPoints("space_lok")
	local want = T.expected()

	local function check(label, list)
		for i, p in ipairs(list) do
			lu.assertNotNil(points[p.patrolPointName], label .. "[" .. i .. "]: " .. tostring(p.patrolPointName) .. " is not a space_lok patrol point")
			lu.assertEquals({ p.x, p.z, p.y }, { points[p.patrolPointName].x, points[p.patrolPointName].z, points[p.patrolPointName].y }, label .. "[" .. i .. "] " .. tostring(p.patrolPointName))
		end
	end

	check(T.PATROL .. ".patrolPoints", quest(T.PATROL).patrolPoints)
	check(T.ASSASSINATE .. ".targetPatrols", quest(T.ASSASSINATE).targetPatrols)

	local names = {}

	for i, p in ipairs(quest(T.ASSASSINATE).targetPatrols) do
		names[i] = p.patrolPointName
	end

	lu.assertEquals(names, { "corellia_privateer_tier3_recovery_point_7", "hostage_recovery_4", "lok_imp_escort_duty_7", "lok_imp_recovery_4" },
		"assassinate/tat_priv_quest_trans: targetPatrols in .tab order (the target spawns at the first)")
	lu.assertEquals(#want[T.ASSASSINATE].targetPatrols, 4, "fixture-derived targetPatrols")
end

-- AC-2, I-4: the mapped fields, table by table, with the quest name and the field in the message
function TestSmugglerTransConformance:test_every_mapped_field_of_both_tables_equals_the_value_derived_from_its_fixture()
	local want = T.expected()
	local fields = {
		[T.PATROL] = { "questZone", "sideQuest", "sideQuestType", "sideQuestName", "sideQuestSplitType", "sideQuestDelay", "patrolPoints" },
		[T.ASSASSINATE] = { "questZone", "creditReward", "arrivalDelay", "mustDestroyEscort", "assassinateSpawns", "targetPatrols" },
	}

	for _, global in ipairs(T.GLOBALS) do
		local id = T.IDENTITY[global]

		for _, key in ipairs(fields[global]) do
			lu.assertEquals(rawget(quest(global), key), want[global][key], id.type .. "/" .. id.name .. ": " .. key)
		end
	end
end

-- AC-2: no table sets the fields the .tab leaves inert or the base class defaults
function TestSmugglerTransConformance:test_the_tables_leave_the_inert_columns_and_the_quest_type_defaults_alone()
	local pat, asn = quest(T.PATROL), quest(T.ASSASSINATE)

	lu.assertNil(rawget(pat, "sideQuestPatrolStart"), T.PATROL .. ": sideQuestPatrolStart (triggerOn is inert for a success split)")
	lu.assertNil(rawget(pat, "parentQuest"), T.PATROL .. ": parentQuest")
	lu.assertNil(rawget(asn, "sideQuestName"), T.ASSASSINATE .. ": sideQuestName")
end
