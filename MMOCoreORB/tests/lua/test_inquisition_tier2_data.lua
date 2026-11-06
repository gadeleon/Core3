-- Inquisition tier 2 (Inquisitor Fa'Zoll): wiring and quest data on SWG-Source's payloads.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-1, AC-2; invariants I-1 .. I-7; Data mapping 1 and 2; Appendix B).
--
-- The oracle is the SWG-Source .tab copies in fixtures/spacequest/<type>/ and the spec literals of inquisition_tier2_data.lua, never the
-- Core3 tables under test. The literals are repeated as anchors, so a misparsed fixture cannot make a wrong table look right.

local lu = require("luaunit")
local H = require("harness")
local I = require("inquisition_tier2_data")

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

local function label(global) return I.IDENTITY[global].type .. "/" .. I.IDENTITY[global].name end

---------------------------------------------------------------------------------------------
-- The oracle itself
---------------------------------------------------------------------------------------------

TestInquisitionT2Fixtures = {}

function TestInquisitionT2Fixtures:setUp() H.reset() end

-- AC-2 (the oracle itself): the seven fixtures carry the values the spec lists
function TestInquisitionT2Fixtures:test_the_fixtures_carry_the_values_the_spec_lists()
	local i1 = H.questFixture("inspect", "naboo_imperial_tier2_1")

	lu.assertEquals({ i1:get("questZone"), i1:list("shipList"), i1:list("validSpawns"), i1:num("giveSpawnWaypoint"), i1:get("cargo"), i1:get("triggerEvent") },
		{ "space_naboo", { "mercenary_courier_tier2" }, { "space_naboo:naboo_imperial_tier2_inspect1_spawner" }, 1, "encrypted_documents", "none" }, "inspect/naboo_imperial_tier2_1")

	local s2 = H.questFixture("survival", "naboo_imperial_tier2_2")

	lu.assertEquals({ s2:get("questZone"), s2:list("transmissionPoint"), s2:num("totalTransmissionTime"), s2:num("timesToUpdateProgress"), s2:num("transmissionStartDelay"), s2:num("delayToFirstAttack"),
		s2:num("attackPeriod"), s2:get("attackListType"), #s2:list("attackShips1"), #s2:list("attackShips2"), #s2:list("attackShips3") },
		{ "space_dantooine", { "space_dantooine:naboo_imperial_tier2_survival1" }, 300, 10, 60, 10, 60, "sequential", 3, 3, 3 }, "survival/naboo_imperial_tier2_2")

	local r3 = H.questFixture("recovery", "naboo_imperial_tier2_3")

	lu.assertEquals({ r3:get("questZone"), r3:get("targetShipType"), r3:num("targetArrivalDelay"), r3:num("targetRecoverTime"), r3:list("targetEscort"), #r3:list("escortPath"), #r3:list("recoveryPath"),
		r3:num("numAttackShipLists"), r3:num("attackPeriod"), r3:num("numResponses"), r3:get("triggerEvent") },
		{ "space_naboo", "colonel_hend_shuttle_tier3", 25, 30, { "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2", "reb_z95_tier2" }, 4, 3, 2, 120, 5, "none" }, "recovery/naboo_imperial_tier2_3")

	local a4 = H.questFixture("assassinate", "naboo_imperial_tier2_4")

	lu.assertEquals({ a4:get("questZone"), a4:get("targetShipType"), a4:num("targetArrivalDelay"), #a4:list("escortPath"), a4:list("targetEscort"), a4:num("mustDestroyEscort") },
		{ "space_dantooine", "colonel_hend_shuttle_tier3", 45, 5, { "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier2", "reb_xwing_tier3" }, 1 }, "assassinate/naboo_imperial_tier2_4")

	local d1 = H.questFixture("recovery_duty", "naboo_imperial_tier2_recoveryduty")

	lu.assertEquals({ d1:get("targetShipTypes"), d1:num("targetArrivalDelay"), d1:num("targetRecoverTime"), d1:list("targetEscort"), d1:get("recoveryAppearance"), #d1:list("escortPath"), #d1:list("recoveryPath"),
		d1:num("attackPeriod"), d1:num("numResponses"), d1:num("reward"), d1:num("killReward") },
		{ "naboo_miner_transport_tier2", 20, 30, { "naboo_miner_fighter_tier2", "naboo_miner_fighter_tier2", "naboo_miner_fighter_tier2" }, "object/mobile/space_comm_imperial_tiefighter_01.iff", 4, 4, 120, 5, 2500, 200 },
		"recovery_duty/naboo_imperial_tier2_recoveryduty")

	local d2 = H.questFixture("escort_duty", "naboo_imperial_tier2_escortduty")

	lu.assertEquals({ d2:list("escortShipTypes"), #d2:list("escortPoints"), d2:num("numAttackShipLists"), d2:num("attackPeriod"), d2:num("numResponses"), d2:num("reward"), d2:num("killReward") },
		{ { "imp_freightermedium_tier2", "imp_freighterlight_tier2", "imp_freighterheavy_tier2" }, 6, 3, 120, 5, 2500, 200 }, "escort_duty/naboo_imperial_tier2_escortduty")

	local d3 = H.questFixture("destroy_duty", "naboo_imperial_tier2_destroyduty")

	lu.assertEquals({ d3:get("questZone"), d3:num("wavesPerRound"), d3:num("roundsPerLevel"), d3:num("levelsPerDuty"), d3:num("shipTypes"), d3:list("shipType1"), d3:get("bossType"), d3:num("reward") },
		{ "space_dantooine", 3, 2, 5, 1, { "reb_xwing_tier2", "reb_xwing_tier2" }, "reb_xwing_tier3", 200 }, "destroy_duty/naboo_imperial_tier2_destroyduty")
end

-- I-2 (the oracle itself): the spec's point and spawner literals are what the patrol point files and spawner tables hold today
function TestInquisitionT2Fixtures:test_the_spec_points_and_spawners_equal_the_core3_point_files()
	for zone, points in pairs(I.POINTS) do
		for name, xyz in pairs(points) do
			local p = point(zone, name)

			lu.assertEquals({ p.x, p.z, p.y }, xyz, zone .. " patrol point " .. name)
		end
	end

	for zone, spawners in pairs(I.SPAWNERS) do
		for name, xyz in pairs(spawners) do
			local s = H.spawners(zone)[name]

			lu.assertNotNil(s, zone .. " spawner " .. name)
			lu.assertEquals({ s.x, s.z, s.y }, xyz, zone .. " spawner " .. name)
		end
	end

	lu.assertEquals(#sortedKeys(I.POINTS.space_naboo), 21, "spec naboo nav points")
	lu.assertEquals(#sortedKeys(I.POINTS.space_dantooine), 6, "spec dantooine nav points")
end

-- I-2 (the oracle itself): the buildout excerpts hold exactly the points and the spawner of the tables, and Core3's points are their truncated values
function TestInquisitionT2Fixtures:test_the_buildout_excerpts_pin_every_point_and_spawner_of_the_tables()
	for zone, file in pairs({ space_naboo = "space_naboo.inquisition_tier2_points.tab", space_dantooine = "space_dantooine.inquisition_tier2_points.tab" }) do
		local tab = H.fixture("space_zones/buildout/" .. file)
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

		lu.assertEquals(sortedKeys(navs), sortedKeys(I.POINTS[zone]), zone .. ": nav_name rows of the excerpt")
		lu.assertEquals(sortedKeys(spawners), sortedKeys(I.SPAWNERS[zone] or {}), zone .. ": strSpawnerName rows of the excerpt")

		for name, xyz in pairs(I.POINTS[zone]) do
			lu.assertEquals(xyz, navs[name], zone .. ": buildout fltPX/fltPY/fltPZ truncated, nav point " .. name)
		end

		for name, xyz in pairs(I.SPAWNERS[zone] or {}) do
			lu.assertEquals(xyz, spawners[name], zone .. ": buildout fltPX/fltPY/fltPZ truncated, spawner " .. name)
		end
	end
end

-- I-5 (the oracle itself): the reward amounts and items are the giveReward lines of the SWG trainer script (J2:199-274)
function TestInquisitionT2Fixtures:test_the_reward_literals_match_the_give_reward_lines_of_the_swg_trainer_script()
	local java = readFile(H.FIXTURES .. "script/conversation/naboo_imperial_trainer_2.java")

	lu.assertNotNil(java, "fixtures/script/conversation/naboo_imperial_trainer_2.java")

	local found = {}

	for questType, questName, credits, rest in java:gmatch('giveReward%(player, "([^"]+)", "([^"]+)", (%d+)([^%)]*)%)') do
		local key = questType .. "_" .. questName

		found[key] = found[key] or {}
		found[key][#found[key] + 1] = { tonumber(credits), rest:match('"([^"]+)"') }
	end

	for n, global in ipairs(I.MISSIONS) do
		local id = I.IDENTITY[global]
		local entries = found[id.type .. "_" .. id.name]

		lu.assertNotNil(entries, "J2 giveReward for " .. id.type .. "/" .. id.name)
		lu.assertEquals(#entries, 1, "J2 giveReward calls for mission " .. n)
		lu.assertEquals(entries[1][1], I.CREDITS, "J2 giveReward credits, mission " .. n)
		lu.assertEquals(entries[1][2], I.ITEMS[global], "J2 giveReward item, mission " .. n)
	end
end

-- AC-2 (the oracle itself): the client journal knows every quest
function TestInquisitionT2Fixtures:test_the_client_quest_name_table_lists_the_seven_quests()
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

TestInquisitionT2Wiring = {}

function TestInquisitionT2Wiring:setUp() H.reset() end

-- AC-1
function TestInquisitionT2Wiring:test_the_squadron_file_registers_the_seven_quests_with_start_true()
	for _, global in ipairs(I.GLOBALS) do
		quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end
end

-- AC-1
function TestInquisitionT2Wiring:test_the_seven_quests_are_registered_in_the_contract_order_after_the_eight_tier_1_quests()
	local order = {}

	for _, global in ipairs(I.TIER1_GLOBALS) do
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for _, global in ipairs(I.GLOBALS) do
		quest(global)
		order[#order + 1] = { global, H.registered(global) and H.registered(global).order or -1 }
	end

	for i = 2, #order do
		lu.assertTrue(order[i][2] > order[i - 1][2], order[i][1] .. " is registered after " .. order[i - 1][1] .. " (Content contract 1 order)")
	end
end

-- AC-1
function TestInquisitionT2Wiring:test_the_squadron_screenplay_has_the_section_2_constants_the_reset_and_the_unchanged_tier_1_fields()
	local sq = H.expectGlobal("InquisitionSquadronScreenplay", "squadron screenplay object")

	lu.assertNotNil(H.registered("InquisitionSquadronScreenplay"), "InquisitionSquadronScreenplay: registerScreenPlay was not called")
	lu.assertFalse(H.registered("InquisitionSquadronScreenplay").start, "InquisitionSquadronScreenplay: registered with start = false")
	lu.assertEquals(pcall(sq.start, sq), true, "InquisitionSquadronScreenplay:start runs")

	for field, want in pairs(I.QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "InquisitionSquadronScreenplay." .. field)
	end

	for field, want in pairs(I.TIER1_QUEST_STRINGS) do
		lu.assertEquals(sq[field], want, "InquisitionSquadronScreenplay." .. field .. " (tier 1, unchanged)")
	end

	lu.assertEquals(sq.SERIES_COMPLETE_KEY, I.SERIES_SUFFIX, "InquisitionSquadronScreenplay.SERIES_COMPLETE_KEY")
	lu.assertEquals(sq.INQUISITORIAL_AGENT_KEY, I.AGENT_SUFFIX, "InquisitionSquadronScreenplay.INQUISITORIAL_AGENT_KEY")
	lu.assertEquals(type(sq.resetBarnQuests), "function", "InquisitionSquadronScreenplay:resetBarnQuests")
	lu.assertEquals(type(sq.resetFaZollQuests), "function", "InquisitionSquadronScreenplay:resetFaZollQuests (Content contract 2)")
	lu.assertEquals(pcall(sq.resetFaZollQuests, sq, nil), true, "resetFaZollQuests(nil) returns early")
end

-- AC-1
function TestInquisitionT2Wiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	I.requireConversation(lu)

	local t = H.conversationTemplateTable(I.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, I.HANDLER, I.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", I.TEMPLATE .. ": templateType")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getInitialScreen), "function", I.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(rawget(_G, I.HANDLER).runScreenHandlers), "function", I.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(rawget(_G, I.HANDLER).getNextConversationScreen), "function", I.HANDLER .. ":getNextConversationScreen")
end

-- AC-1
function TestInquisitionT2Wiring:test_fa_zoll_uses_the_template_and_has_barns_options_mask()
	local npc = H.loadCreatureTemplate("space/fa_zoll.lua", "fa_zoll")

	lu.assertNotNil(npc, "mobile/space/fa_zoll.lua registers fa_zoll")
	lu.assertEquals(npc.conversationTemplate, "fa_zoll_convo_template", "fa_zoll: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "fa_zoll: optionsBitmask (Barn's mask, J2:4274-4276)")
end

-- AC-1
function TestInquisitionT2Wiring:test_the_template_include_line_is_uncommented_exactly_once_directly_after_barns()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/inquisition_squadron/fa_zoll_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented fa_zoll_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented fa_zoll_convo include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the barn_sinkko_convo include")
	lu.assertEquals((lines[at + 1] or ""):gsub("^%s+", ""), 'includeFile("conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua")', "space_conversations.lua: the fa_zoll include directly after Barn's")
end

-- AC-1
function TestInquisitionT2Wiring:test_the_handler_include_line_follows_barns_handler_include_exactly_once_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/inquisition_squadron/faZollConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented faZollConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented faZollConvoHandler include")

	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	local at

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: Barn's handler include")
	lu.assertEquals(lines[at + 1], 'includeFile("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua")', "screenplays.lua: Fa'Zoll's handler include, directly after Barn's")
end

-- AC-1: the T1 wiring pin (Barn's include at squadron + 2) holds
function TestInquisitionT2Wiring:test_barns_handler_include_is_still_two_lines_after_the_squadron_include()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
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
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua")', "screenplays.lua: Barn's handler include at squadron + 2")
end

---------------------------------------------------------------------------------------------
-- Identity, the whole tables, no extra keys (AC-2, I-1, I-3, I-6)
---------------------------------------------------------------------------------------------

TestInquisitionT2Tables = {}

function TestInquisitionT2Tables:setUp() H.reset() end

-- AC-2, I-1
function TestInquisitionT2Tables:test_the_seven_tables_keep_their_identity_and_zone()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)
		local id = I.IDENTITY[global]

		lu.assertEquals(q.className, global, global .. ": className")
		lu.assertEquals(q.className, q.questType .. "_" .. q.questName, global .. ": className == questType_questName")
		lu.assertEquals({ q.questType, q.questName }, { id.type, id.name }, global .. ": questType, questName")
		lu.assertEquals(q.questZone, id.zone, global .. ": questZone")
		lu.assertTrue(inherits(q, rawget(_G, id.class)), global .. ": is a " .. id.class)
	end
end

-- AC-2: Appendix B, every key, nothing else
function TestInquisitionT2Tables:test_each_table_equals_the_contract_and_sets_no_other_key()
	local want = I.expected()

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(sortedKeys(dataKeys(q)), sortedKeys(want[global]), global .. ": own data keys")

		for key, value in pairs(want[global]) do
			lu.assertEquals(rawget(q, key), value, global .. ": " .. key)
		end
	end
end

-- Content contract 1: no function overrides
function TestInquisitionT2Tables:test_no_table_defines_a_function()
	for _, global in ipairs(I.GLOBALS) do
		lu.assertEquals(functionKeys(quest(global)), {}, global .. ": function-valued own fields")
	end
end

-- AC-2, I-6: nothing splits, nothing has a parent
function TestInquisitionT2Tables:test_no_table_splits_or_has_a_parent()
	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(q.sideQuest and true or false, false, global .. ": sideQuest")
		lu.assertNil(rawget(q, "parentQuest"), global .. ": parentQuest")
		lu.assertNil(rawget(q, "sideQuestName"), global .. ": sideQuestName")
	end
end

-- AC-2, I-6: credits and items only on the four heads and the duties
function TestInquisitionT2Tables:test_credits_and_items_sit_on_the_four_mission_heads_and_the_duties_only()
	local pays = { [I.M1] = 5000, [I.M2] = 5000, [I.M3] = 5000, [I.M4] = 5000, [I.DUTY1] = 2500, [I.DUTY2] = 2500, [I.DUTY3] = 200 }

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)

		lu.assertEquals(rawget(q, "creditReward") or 0, pays[global], global .. ": creditReward")

		if I.ITEMS[global] then
			lu.assertEquals(rawget(q, "itemReward"), { { species = { -1 }, item = I.ITEMS[global] } }, global .. ": itemReward (any species)")
		else
			lu.assertNil(rawget(q, "itemReward"), global .. ": itemReward")
		end
	end
end

-- I-3: every ship the tables name has a ship template and every item an object template (11 ships, 4 items)
function TestInquisitionT2Tables:test_every_ship_and_item_the_tables_name_has_a_template_file()
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
	end

	lu.assertEquals(#sortedKeys(ships), 11, "distinct ships in the 7 tables: " .. table.concat(sortedKeys(ships), ", "))
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

-- I-3: the recovery duty's conversation mobile is a client template the server knows
function TestInquisitionT2Tables:test_the_recovery_duty_appearance_is_a_known_client_mobile_template()
	local q = quest(I.DUTY1)
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")
	lu.assertNotNil(text:find('"' .. q.recoveryConversationMobile .. '"', 1, true), q.recoveryConversationMobile .. " is not in object/mobile/objects.lua")
end

-- I-7: the client resolves each journal entry through misc/quest_crc_string_table
function TestInquisitionT2Tables:test_every_quest_is_in_the_client_quest_name_table()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")
	local set = {}

	for line in text:gmatch("[^\n]+") do
		set[line] = true
	end

	for _, global in ipairs(I.GLOBALS) do
		local q = quest(global)
		local name = "spacequest/" .. q.questType .. "/" .. q.questName

		lu.assertTrue(set[name] == true, name .. " is not in the client quest table")
	end
end

---------------------------------------------------------------------------------------------
-- Conformance to the .tab fixtures (Data mapping 1, I-2, I-4)
---------------------------------------------------------------------------------------------

TestInquisitionT2Conformance = {}

function TestInquisitionT2Conformance:setUp() H.reset() end

-- recovery-style path of the pilot: escortNumber = i, radius 250, no zoneName (Kaydine F3 D-6); the recovery path is renumbered from 1
local function recoveryPath(q, rec, l, field, column)
	local out = {}

	for i, p in ipairs(pointsOf(rec, column)) do
		lu.assertEquals(p.zone, q.questZone, l .. ": " .. column .. " zone equals questZone")
		out[i] = { patrolPointName = p.name, x = p.x, z = p.z, y = p.y, escortNumber = i, radius = 250 }
	end

	lu.assertEquals(q[field], out, l .. ": " .. field .. " (" .. column .. ", no zoneName, renumbered from 1)")
end

-- AC-2, I-2, I-4: inspect/naboo_imperial_tier2_1.tab
function TestInquisitionT2Conformance:test_inspect_1_maps_ship_spawner_waypoint_flag_and_cargo()
	local q, rec = quest(I.M1), fixtureOf(I.M1)
	local l = label(I.M1)
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

-- AC-2, I-2, I-4: survival/naboo_imperial_tier2_2.tab
function TestInquisitionT2Conformance:test_survival_2_maps_point_timers_attack_lists_and_order_from_its_fixture()
	local q, rec = quest(I.M2), fixtureOf(I.M2)
	local l = label(I.M2)
	local zone, name = H.Tab.splitNavPoint(rec:list("transmissionPoint")[1])
	local p = point(zone, name)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(zone, q.questZone, l .. ": transmissionPoint zone equals questZone")
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

-- AC-2, I-2, I-4: recovery/naboo_imperial_tier2_3.tab
function TestInquisitionT2Conformance:test_recovery_3_maps_ships_paths_attack_lists_and_taunts_from_its_fixture()
	local q, rec = quest(I.M3), fixtureOf(I.M3)
	local l = label(I.M3)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipType"), l .. ": recoverShip (targetShipType)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	recoveryPath(q, rec, l, "preRecoveryPoints", "escortPath")
	recoveryPath(q, rec, l, "recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
	lu.assertEquals(rawget(q, "recoveryConversationMobile"), nil, l .. ": no recoveryAppearance column, so recoveryConversationMobile stays the type default")
end

-- AC-2, I-2, I-4: assassinate/naboo_imperial_tier2_4.tab
function TestInquisitionT2Conformance:test_assassinate_4_maps_target_escorts_delay_and_path()
	local q, rec = quest(I.M4), fixtureOf(I.M4)
	local l = label(I.M4)
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

-- AC-2, I-2, I-4: recovery_duty/naboo_imperial_tier2_recoveryduty.tab
function TestInquisitionT2Conformance:test_recovery_duty_maps_ship_escorts_paths_appearance_taunts_and_pay()
	local q, rec = quest(I.DUTY1), fixtureOf(I.DUTY1)
	local l = label(I.DUTY1)

	lu.assertEquals(q.questZone, rec:get("questZone"), l .. ": questZone")
	lu.assertEquals(q.recoverShip, rec:get("targetShipTypes"), l .. ": recoverShip (the one-cell targetShipTypes)")
	lu.assertEquals(q.arrivalDelay, rec:num("targetArrivalDelay"), l .. ": arrivalDelay (targetArrivalDelay)")
	lu.assertEquals(q.recoveryDelay, rec:num("targetRecoverTime"), l .. ": recoveryDelay (targetRecoverTime)")
	lu.assertEquals(q.escortShips, rec:list("targetEscort"), l .. ": escortShips (targetEscort)")
	recoveryPath(q, rec, l, "preRecoveryPoints", "escortPath")
	recoveryPath(q, rec, l, "recoveryPoints", "recoveryPath")
	lu.assertEquals(q.attackDelay, rec:num("attackPeriod"), l .. ": attackDelay (attackPeriod)")
	lu.assertEquals(q.attackShips, attackLists(rec), l .. ": attackShips (attackShips1..numAttackShipLists, column-wise)")
	lu.assertEquals(q.recoveryConversationMobile, (rec:get("recoveryAppearance"):gsub("^object/mobile/", "object/mobile/shared_")), l .. ": recoveryConversationMobile (recoveryAppearance with the shared_ prefix)")
	lu.assertEquals(q.creditReward, rec:num("reward"), l .. ": creditReward (reward)")
	lu.assertEquals(q.creditKillBonus, rec:num("killReward"), l .. ": creditKillBonus (killReward)")

	local m = math.max(rec:num("numResponses") or 0, 1)

	lu.assertEquals(q.numResponses, rec:num("numResponses"), l .. ": numResponses")
	lu.assertEquals(q.tauntData, { panicCount = m, thanksCount = m }, l .. ": tauntData (max(numResponses, 1))")
end

-- AC-2, I-2, I-4: escort_duty/naboo_imperial_tier2_escortduty.tab
function TestInquisitionT2Conformance:test_escort_duty_maps_ships_path_attack_lists_delay_taunts_and_pay()
	local q, rec = quest(I.DUTY2), fixtureOf(I.DUTY2)
	local l = label(I.DUTY2)
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

-- AC-2, I-4: destroy_duty/naboo_imperial_tier2_destroyduty.tab
function TestInquisitionT2Conformance:test_destroy_duty_maps_waves_rounds_levels_boss_ship_types_and_pay()
	local q, rec = quest(I.DUTY3), fixtureOf(I.DUTY3)
	local l = label(I.DUTY3)
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

---------------------------------------------------------------------------------------------
-- FI-1: the inspect ship's cargo, read from the real template file (I-5)
---------------------------------------------------------------------------------------------

TestInquisitionT2Cargo = {}

function TestInquisitionT2Cargo:setUp() H.reset() end

-- The template file without comments
local function templateSource(shipName)
	local path = H.SCRIPTS .. "ship_mobile/ships/" .. shipName .. ".lua"

	lu.assertTrue(H.fileExists(path), "expected ship template bin/scripts/ship_mobile/ships/" .. shipName .. ".lua to exist")

	local src = readFile(path)

	return (src:gsub("%-%-[^\n]*", ""))
end

-- AC-2, I-5, FI-1
function TestInquisitionT2Cargo:test_every_inspect_ship_template_file_carries_the_quest_cargo_as_a_transferable_cargo_string()
	local q = quest(I.M1)

	lu.assertEquals(q.shipList, { "mercenary_courier_tier2" }, "inspect 1 shipList")

	for _, ship in ipairs(q.shipList) do
		local src = templateSource(ship)
		local cargoString = src:match('cargoString%s*=%s*"(.-)"')
		local questLoot = src:match('questLoot%s*=%s*"(.-)"')

		lu.assertEquals(cargoString, q.cargo, ship .. ".lua cargoString must equal the quest cargo (SWG space_mobile.tab cargo column)")
		lu.assertEquals(questLoot, "encrypted_documents", ship .. ".lua questLoot (names the inspect_cargo table) stays")

		local rows = H.fixture("spacequest/inspect_cargo/" .. questLoot .. ".tab").records

		lu.assertEquals(#rows, 1, "inspect_cargo/" .. questLoot .. ".tab rows")
		lu.assertEquals({ rows[1]:get("name"), rows[1]:num("canTransfer") }, { q.cargo, 1 }, ship .. ": cargo is the canTransfer = 1 row of the table")
	end
end

-- AC-2, I-5: the loaded template (what the server registers) has it too, and nothing else of the template moved
function TestInquisitionT2Cargo:test_the_loaded_courier_template_has_the_cargo_string_and_is_otherwise_unchanged()
	local t = H.shipTemplate("mercenary_courier_tier2")

	lu.assertNotNil(t, "ship_mobile/ships/mercenary_courier_tier2.lua registers a template")
	lu.assertEquals(t.cargoString, "encrypted_documents", "mercenary_courier_tier2: cargoString")
	lu.assertEquals(t.questLoot, "encrypted_documents", "mercenary_courier_tier2: questLoot is unchanged")
	lu.assertEquals(t.template, "hutt_light_s01_tier2", "mercenary_courier_tier2: template is unchanged")
	lu.assertEquals(t.pilotTemplate, "light_fighter_tier2", "mercenary_courier_tier2: pilotTemplate is unchanged")
end
