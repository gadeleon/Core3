-- Storm tier 2 (Commander Oberhaur): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of storm_tier2_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")

T.load()

local function quest(global) return T.quest(global) end

local function fixtureOf(global)
	local id = T.IDENTITY[global]

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

local function point(name)
	local p = H.patrolPoints("space_lok")[name]

	assert(p ~= nil, "patrol point " .. tostring(name) .. " not found in space_lok")
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

local function label(global) return T.IDENTITY[global].type .. "/" .. T.IDENTITY[global].name end

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

TestStormT2Fixtures = {}

function TestStormT2Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the six fixtures carry the values the spec lists
function TestStormT2Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local i1 = H.questFixture("inspect", "imperial_ss_1")

	lu.assertEquals({ i1:get("questZone"), i1:list("shipList"), i1:list("validSpawns"), i1:num("giveSpawnWaypoint"), i1:get("cargo"), i1:get("triggerEvent"), i1:num("triggerOn") },
		{ "space_lok", { "nym_lieutenant_tier2" }, {}, 0, "hostage_orders", "none", -1 }, "inspect/imperial_ss_1")

	local r2 = H.questFixture("recovery", "imperial_ss_2")

	lu.assertEquals({ r2:get("questZone"), r2:get("targetShipType"), r2:num("targetArrivalDelay"), r2:num("targetRecoverTime"), r2:list("targetEscort"), #r2:list("escortPath"), #r2:list("recoveryPath"),
		r2:num("numAttackShipLists"), r2:num("attackPeriod"), r2:num("numResponses"), r2:get("recoveryAppearance"), r2:get("triggerEvent") },
		{ "space_lok", "nym_prison_ship_tier2", 15, 30, { "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2" }, 5, 5, 2, 120, 5, "object/mobile/space_comm_imperial_officer_01.iff", "none" },
		"recovery/imperial_ss_2")

	local a3 = H.questFixture("assassinate", "imperial_ss_3")

	lu.assertEquals({ a3:get("questZone"), a3:get("targetShipType"), a3:num("targetArrivalDelay"), #a3:list("escortPath"), a3:list("targetEscort"), a3:num("mustDestroyEscort"), a3:get("triggerEvent") },
		{ "space_lok", "nym_capo_ship_tier2", 30, 5, { "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2" }, 1, "none" }, "assassinate/imperial_ss_3")

	local d1 = H.questFixture("destroy_duty", "lok_imperial_ss_1a")

	lu.assertEquals({ d1:get("questZone"), d1:num("wavesPerRound"), d1:num("roundsPerLevel"), d1:num("levelsPerDuty"), d1:num("shipTypes"), d1:list("shipType1"), d1:list("shipType2"), d1:list("shipType3"),
		d1:get("bossType"), d1:num("reward") },
		{ "space_lok", 3, 2, 5, 3, { "nym_fighter_tier2", "nym_fighter_tier2" }, { "nym_enforcer_tier2", "nym_enforcer_tier2" }, { "nym_blastboat_tier2", "nym_blastboat_tier2" }, "nym_fighter_tier3", 200 },
		"destroy_duty/lok_imperial_ss_1a")

	local d2 = H.questFixture("recovery_duty", "lok_imperial_ss_1b")

	lu.assertEquals({ d2:list("targetShipTypes"), d2:num("targetArrivalDelay"), d2:num("targetRecoverTime"), d2:list("targetEscort"), d2:get("recoveryAppearance"), #d2:list("escortPath"), #d2:list("recoveryPath"),
		d2:num("attackPeriod"), d2:num("numResponses"), d2:num("reward"), d2:num("killReward") },
		{ { "nym_freighterheavy_tier2", "nym_freighterlight_tier2", "nym_freightermedium_tier2" }, 30, 30, { "nym_enforcer_tier2", "nym_enforcer_tier2", "nym_enforcer_tier2" }, nil, 6, 6, 90, 5, 2500, 200 },
		"recovery_duty/lok_imperial_ss_1b")

	local d3 = H.questFixture("escort_duty", "lok_imperial_ss_1c")

	lu.assertEquals({ d3:list("escortShipTypes"), #d3:list("escortPoints"), d3:num("numAttackShipLists"), d3:num("attackPeriod"), d3:num("numResponses"), d3:num("reward"), d3:num("killReward") },
		{ { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }, 6, 2, 120, 5, 2500, 200 }, "escort_duty/lok_imperial_ss_1c")
end

-- AC-2, I-5 (the oracle itself): the Lieutenant's cargo table holds the one transferable row hostage_orders
function TestStormT2Fixtures:test_the_inspect_cargo_fixture_has_one_transferable_row()
	local rows = H.fixture("spacequest/inspect_cargo/imperial_ss_1.tab").records

	lu.assertEquals(#rows, 1, "inspect_cargo/imperial_ss_1.tab rows")
	lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { "hostage_orders", 1 }, "the row")
end

-- I-2 (the oracle itself): the spec's point literals are what the patrol point file holds today
function TestStormT2Fixtures:test_the_spec_points_equal_the_core3_patrol_point_file()
	local n = 0

	for name, xyz in pairs(T.POINTS) do
		local p = point(name)

		n = n + 1
		lu.assertEquals({ p.x, p.z, p.y }, xyz, "space_lok patrol point " .. name)
	end

	lu.assertEquals(n, 28, "spec nav points")
end

-- I-2 (the oracle itself): the buildout excerpt holds exactly the 28 points, and Core3's points are their truncated values
function TestStormT2Fixtures:test_the_buildout_excerpt_pins_every_point_of_the_tables()
	local tab = H.fixture("space_zones/buildout/space_lok.storm_tier2_points.tab")
	local navs = {}

	for _, rec in ipairs(tab.records) do
		local nav = (rec:get("strObjVars") or ""):match("nav_name|4|([^|]+)|")

		if nav ~= nil then
			navs[nav] = { trunc(rec:num("fltPX")), trunc(rec:num("fltPY")), trunc(rec:num("fltPZ")) }
		end
	end

	lu.assertEquals(sortedKeys(navs), sortedKeys(T.POINTS), "nav_name rows of the excerpt")

	for name, xyz in pairs(T.POINTS) do
		lu.assertEquals(xyz, navs[name], "buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
	end
end

-- I-6 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J2:274, 286, 316)
function TestStormT2Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/tatooine_imperial_trainer_2.java")

	lu.assertNotNil(java, "fixtures/script/conversation/tatooine_imperial_trainer_2.java")

	local found = {}

	for questType, questName, credits, item in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+), "([^"]+)"%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), item }
	end

	for n, global in ipairs(T.MISSIONS) do
		local id = T.IDENTITY[global]
		local entries = found[id.type .. "_" .. id.name]

		lu.assertNotNil(entries, "J2 giveReward for " .. id.type .. "/" .. id.name)
		lu.assertEquals(#entries, 1, "J2 giveReward calls for mission " .. n)
		lu.assertEquals(entries[1][1], T.CREDITS, "J2 giveReward credits, mission " .. n)
		lu.assertEquals(entries[1][2], T.ITEMS[global], "J2 giveReward item, mission " .. n)
	end

	lu.assertEquals(countMatches(java, "addFactionStanding%(player, factions%.FACTION_IMPERIAL, 75%.0f%)"), 3, "J2 pays +75 Imperial standing three times")
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestStormT2Fixtures:test_the_client_quest_name_table_lists_the_six_quests()
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
-- AC-1: wiring
---------------------------------------------------------------------------------------------

TestStormT2Wiring = {}

function TestStormT2Wiring:setUp() H.reset() end

-- AC-1, I-1
function TestStormT2Wiring:test_the_squadron_file_registers_the_six_quests_with_start_true()
	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestStormT2Wiring:test_the_six_quests_are_registered_in_the_contract_order_after_the_eight_tier_1_quests()
	local order = {}

	for _, global in ipairs(T.TIER1_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(T.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- AC-1
function TestStormT2Wiring:test_the_squadron_screenplay_has_the_section_2_constants_the_reset_and_the_unchanged_tier_1_fields()
	local sq = T.squadron()

	lu.assertNotNil(H.registered("StormSquadronScreenplay"), "StormSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("StormSquadronScreenplay").start, "StormSquadronScreenplay: registered with start = false")
	lu.assertEquals(pcall(sq.start, sq), true, "StormSquadronScreenplay:start runs")

	for field, want in pairs(T.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field)
	end

	for field, want in pairs(T.TIER1_QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "StormSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, T.SERIES_SUFFIX, "StormSquadronScreenplay.SERIES_COMPLETE_KEY (tier 1, unchanged)")
	lu.assertEquals(sq.TRANSFER_FORM, T.TRANSFER_FORM, "StormSquadronScreenplay.TRANSFER_FORM (tier 1, unchanged)")
	lu.assertEquals(sq.TIER2_INITIATE_KEY, T.INITIATE_SUFFIX, "StormSquadronScreenplay.TIER2_INITIATE_KEY")
	lu.assertEquals(sq.TIER2_FINDING_AGENT_KEY, T.FINDING_SUFFIX, "StormSquadronScreenplay.TIER2_FINDING_AGENT_KEY")
	lu.assertEquals(sq.TIER2_ALOZEN_KEY, T.ALOZEN_SUFFIX, "StormSquadronScreenplay.TIER2_ALOZEN_KEY")
	lu.assertEquals(sq.TRANSFER_FORM_SIGNATURE, T.SIGNATURE_KEY, "StormSquadronScreenplay.TRANSFER_FORM_SIGNATURE")
	lu.assertEquals(type(sq.resetColzetQuests), "function", "StormSquadronScreenplay:resetColzetQuests (tier 1, unchanged)")
	lu.assertEquals(type(sq.resetOberhaurQuests), "function", "StormSquadronScreenplay:resetOberhaurQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetOberhaurQuests, sq, nil), true, "resetOberhaurQuests(nil) returns early")
	lu.assertEquals(type(sq.getTransferForm), "function", "StormSquadronScreenplay:getTransferForm (Content contract 3)")
	lu.assertEquals(type(sq.getTransferFormSignature), "function", "StormSquadronScreenplay:getTransferFormSignature (Content contract 3)")
end

-- AC-1: the menu component's four functions
function TestStormT2Wiring:test_the_form_menu_component_has_the_section_3_functions()
	local c = T.menuComponent()

	for _, fn in ipairs({ "fillObjectMenuResponse", "handleObjectMenuSelect", "showForm", "readCallback", "signCallback" }) do
		lu.assertEquals(type(c[fn]), "function", "StormTransferFormMenuComponent:" .. fn)
	end
end

-- AC-1
function TestStormT2Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	T.requireConversation(lu)

	local t = H.conversationTemplateTable(T.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, T.HANDLER, T.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", T.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, T.HANDLER).getInitialScreen), "function", T.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, T.HANDLER).runScreenHandlers), "function", T.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, T.HANDLER).getNextConversationScreen), "function", T.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestStormT2Wiring:test_oberhaur_uses_the_template_and_has_colzets_options_mask()
	local npc = H.loadCreatureTemplate("space/oberhaur.lua", "oberhaur")

	lu.assertNotNil(npc, "mobile/space/oberhaur.lua registers oberhaur")
	lu.assertEquals(npc.conversationTemplate, "oberhaur_convo_template", "oberhaur: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "oberhaur: optionsBitmask (oberhaur.java, Colzet's mask)")
	lu.assertEquals(npc.templates, { "object/mobile/space_imperial_tier2_tatooine_oberhaur.iff" }, "oberhaur: template unchanged")
end

-- AC-1: the form's object template names the menu component
function TestStormT2Wiring:test_the_transfer_form_object_template_names_the_menu_component()
	local captured = {}
	local env = setmetatable({
		ObjectTemplates = { addTemplate = function(_, template, path) captured[path] = template end },
		object_tangible_space_mission_objects_shared_transfer_auth = { new = function(_, t) return t end },
	}, { __index = _G })

	local chunk, err = loadfile(H.SCRIPTS .. T.FORM_OBJECT_FILE, "t", env)

	lu.assertNotNil(chunk, "cannot load " .. T.FORM_OBJECT_FILE .. ": " .. tostring(err))
	chunk()

	local template = captured["object/tangible/space/mission_objects/transfer_auth.iff"]

	lu.assertNotNil(template, T.FORM_OBJECT_FILE .. " registers object/tangible/space/mission_objects/transfer_auth.iff")
	lu.assertEquals(template.objectMenuComponent, "StormTransferFormMenuComponent", "transfer_auth: objectMenuComponent")
	lu.assertEquals(sortedKeys(template), { "objectMenuComponent" }, "transfer_auth: nothing else is set in the file's table")
end

-- AC-1
function TestStormT2Wiring:test_the_template_include_line_is_uncommented_exactly_once_directly_after_colzets()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/storm_squadron/oberhaur_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented oberhaur_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented oberhaur_convo include")

	local lines = linesOf(text)
	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/storm_squadron/akal_colzet_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the akal_colzet_convo include")
	lu.assertEquals((lines[at + 1] or ""):gsub("^%s+", ""), 'includeFile("conversations/space/imperial/storm_squadron/oberhaur_convo.lua")', "space_conversations.lua: the oberhaur include directly after Colzet's")
end

-- AC-1
function TestStormT2Wiring:test_the_handler_include_line_follows_colzets_handler_include_exactly_once_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/storm_squadron/oberhaurConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented oberhaurConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented oberhaurConvoHandler include")

	local lines = linesOf(text)
	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: Colzet's handler include")
	lu.assertEquals(lines[at + 1], 'includeFile("space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua")', "screenplays.lua: Oberhaur's handler include, directly after Colzet's")
	-- storm-tier2-nym-technicians: the three technician handler includes now follow Oberhaur's directly (the blank line and the Master Trainers block move down by three)
	for n = 1, 3 do
		lu.assertEquals(lines[at + 1 + n], 'includeFile("space/conversations/imperial/storm_squadron/nymTechnician' .. n .. 'ConvoHandler.lua")', "screenplays.lua: technician " .. n .. "'s include, directly after Oberhaur's and the earlier technicians'")
	end

	-- storm-tier2-alozen: Alozen's handler include follows technician 3's, so the blank line and the Master Trainers block move down by one
	lu.assertEquals(lines[at + 5], 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")', "screenplays.lua: Alozen's include follows the last technician's (storm-tier2-alozen)")
	lu.assertEquals(lines[at + 6], 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")', "screenplays.lua: Denner's include follows Alozen's (storm-tier3-denner)")
	lu.assertEquals(lines[at + 7], "", "screenplays.lua: the blank line follows Denner's include (storm-tier3-denner)")
	lu.assertEquals(lines[at + 8], "-- Master Trainers", "screenplays.lua: the Master Trainers block follows")
end

-- AC-1: the T1 pin (Colzet's handler include directly after the squadron include and a blank line) holds
function TestStormT2Wiring:test_colzets_handler_include_is_still_two_lines_after_the_squadron_include()
	local lines = linesOf(readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua"))
	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/squadrons/StormSquadronScreenplay.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: the StormSquadronScreenplay include")
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua")', "screenplays.lua: Colzet's handler include at squadron + 2")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-6)
---------------------------------------------------------------------------------------------

TestStormT2Tables = {}

function TestStormT2Tables:setUp() H.reset() end

-- AC-2, I-1
function TestStormT2Tables:test_the_six_tables_keep_their_identity_and_zone()
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
function TestStormT2Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = T.expected()

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestStormT2Tables:test_no_table_defines_a_function()
	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- AC-2, I-6: nothing splits, nothing has a parent
function TestStormT2Tables:test_no_table_splits_or_has_a_parent()
	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, false, global .. ": sideQuest")
		lu.assertNil(rawget(q, "parentQuest"), global .. ": parentQuest")
		lu.assertNil(rawget(q, "sideQuestName"), global .. ": sideQuestName")
	end
end

-- AC-2, I-6: credits and items only on the three story heads and the duties
function TestStormT2Tables:test_credits_and_items_sit_on_the_three_mission_heads_and_the_duties_only()
	local pays = { [T.M1] = 5000, [T.M2] = 5000, [T.M3] = 5000, [T.DUTY1] = 200, [T.DUTY2] = 2500, [T.DUTY3] = 2500 }

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global], global .. ": creditReward")

		if T.ITEMS[global] then
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = T.ITEMS[global] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template (14 ships, 3 items)
function TestStormT2Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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

		for _, field in ipairs({ "escortShips", "attackShips", "shipTypes", "shipList", "recoverShips" }) do
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
	end

	lu.assertEquals(#sortedKeys(ships), 14, "distinct ships in the 6 tables: " .. table.concat(sortedKeys(ships), ", "))
	lu.assertEquals(#sortedKeys(items), 3, "distinct items in the 6 tables: " .. table.concat(sortedKeys(items), ", "))

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

-- I-3: the recovery's conversation mobile is a client template the server knows
function TestStormT2Tables:test_the_recovery_appearance_is_a_known_client_mobile_template()
	local q = quest(T.M2)
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertNotNil(text:find('"' .. tostring(q.recoveryConversationMobile) .. '"', 1, true), tostring(q.recoveryConversationMobile) .. " is not in object/mobile/objects.lua")
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestStormT2Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")
	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(T.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestStormT2Conformance = {}

function TestStormT2Conformance:setUp() H.reset() end

-- recovery-style path of the pilot: escortNumber = i, radius 250, no zoneName; the recovery path is numbered from 1
local function recoveryPath(q, rec, l, field, column)
	local out = {}

	for i, p in ipairs(pointsOf(rec, column)) do
		lu.assertEquals(p.zone, q.questZone, l .. ": " .. column .. " zone equals questZone")
		out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q[field], out, l .. ": " .. field .. " (" .. column .. ", no zoneName, numbered from 1)")
end

-- AC-2, I-4: inspect/imperial_ss_1.tab
function TestStormT2Conformance:test_inspect_1_maps_ship_the_empty_spawner_list_waypoint_flag_and_cargo()
	local q, rec = quest(T.M1), fixtureOf(T.M1)
	local l = label(T.M1)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.shipList, rec:list("shipList"), l .. ": shipList")
	lu.assertEquals(q.validSpawns, {}, l .. ": validSpawns (the column is empty, so any spawner counts, FI-7)")
	lu.assertEquals(#rec:list("validSpawns"), 0, l .. ": precondition: the fixture column is empty")
	lu.assertEquals(q.giveSpawnWaypoint, rec:num("giveSpawnWaypoint"), l .. ": giveSpawnWaypoint")
	lu.assertEquals(q.cargo, rec:get("cargo"), l .. ": cargo")
end

-- AC-2, I-2, I-4: recovery/imperial_ss_2.tab
function TestStormT2Conformance:test_recovery_2_maps_ships_paths_attack_lists_appearance_and_taunts_from_its_fixture()
	local q, rec = quest(T.M2), fixtureOf(T.M2)
	local l = label(T.M2)

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

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: assassinate/imperial_ss_3.tab
function TestStormT2Conformance:test_assassinate_3_maps_target_escorts_delay_and_path()
	local q, rec = quest(T.M3), fixtureOf(T.M3)
	local l = label(T.M3)
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

-- AC-2, I-4: destroy_duty/lok_imperial_ss_1a.tab
function TestStormT2Conformance:test_destroy_duty_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(T.DUTY1), fixtureOf(T.DUTY1)
	local l = label(T.DUTY1)
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
	lu.assertNil(rawget(q, "minDistance"), l .. ": minDistance stays the type default")
	lu.assertNil(rawget(q, "maxDistance"), l .. ": maxDistance stays the type default")
end

-- AC-2, I-2, I-4: recovery_duty/lok_imperial_ss_1b.tab
function TestStormT2Conformance:test_recovery_duty_maps_ships_escorts_paths_taunts_and_pay()
	local q, rec = quest(T.DUTY2), fixtureOf(T.DUTY2)
	local l = label(T.DUTY2)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.recoverShips, rec:list("targetShipTypes"), l .. ": recoverShips (the three-cell targetShipTypes column)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	recoveryPath(q, rec, l, "preRecoveryPoints", "escortPath")
	recoveryPath(q, rec, l, "recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertNil(rawget(q, "recoveryConversationMobile"), l .. ": no recoveryAppearance column, so recoveryConversationMobile stays the type default")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: escort_duty/lok_imperial_ss_1c.tab
function TestStormT2Conformance:test_escort_duty_maps_ships_path_attack_lists_delay_taunts_and_pay()
	local q, rec = quest(T.DUTY3), fixtureOf(T.DUTY3)
	local l = label(T.DUTY3)
	local points = {}

	for i, p in ipairs(pointsOf(rec, "escortPoints")) do
		points[i] = { patrolPointName = p.name, zoneName = p.zone, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.escortShips, rec:list("escortShipTypes"), l .. ": escortShips (escortShipTypes, in this order)")
	lu.assertEquals(q.escortPoints, points, l .. ": escortPoints")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { goodbyeCount = m, reasonCount = m, tauntCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")
end

---------------------------------------------------------------------------------------------
-- FI-8: the inspect ship's cargo, read from the real template file (I-5)
---------------------------------------------------------------------------------------------

TestStormT2Cargo = {}

function TestStormT2Cargo:setUp() H.reset() end

-- The template file without comments
local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	local src = readFile(path)

	return (src:gsub("%-%-[^\n]*", ""))
end

-- AC-2, I-5, FI-8
function TestStormT2Cargo:test_the_lieutenant_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	local q = quest(T.M1)

	lu.assertEquals(q.shipList, { "nym_lieutenant_tier2" }, "inspect 1 shipList")

	for _, ship in ipairs(q.shipList) do
		local src = templateSource(ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, ship .. ".lua cargoString must equal the quest cargo (SWG space_mobile.tab:1277 cargo column)")
		lu.assertEquals(questLoot, "imperial_ss_1", ship .. ".lua questLoot (names the inspect_cargo table) stays")

		local rows = H.fixture("spacequest/inspect_cargo/" .. questLoot .. ".tab").records

		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { q.cargo, 1 }, ship .. ": cargo is the canTransfer = 1 row of the table")
	end
end

-- AC-2, I-5: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestStormT2Cargo:test_the_loaded_lieutenant_template_has_the_cargo_string_and_keeps_its_loot_name()
	local t = H.shipTemplate("nym_lieutenant_tier2")

	lu.assertNotNil(t, "ship_mobile/ships/nym_lieutenant_tier2.lua registers a template")
	lu.assertEquals(t.cargoString, "hostage_orders", "nym_lieutenant_tier2: cargoString")
	lu.assertEquals(t.questLoot, "imperial_ss_1", "nym_lieutenant_tier2: questLoot is unchanged")
end
