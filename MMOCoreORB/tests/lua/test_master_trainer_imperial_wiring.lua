-- Imperial master trainer (Grand Admiral Declann): the server load order wires the quest file, the template, the handler and the NPC.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-1; Content contract 1 and 3).
--
-- Include positions are read as text from the two include files, as the tier 4 wiring tests do.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")

M.load()

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function linesOf(text)
	local out = {}

	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = (line:gsub("\r$", ""))
	end

	return out
end

local function countOf(lines, wanted)
	local n = 0

	for _, l in ipairs(lines) do
		if l == wanted then
			n = n + 1
		end
	end

	return n
end

local function indexOf(lines, wanted)
	for i, l in ipairs(lines) do
		if l == wanted then
			return i
		end
	end
end

TestMasterTrainerImperialWiring = {}

function TestMasterTrainerImperialWiring:setUp() H.reset() end

-- AC-1
function TestMasterTrainerImperialWiring:test_the_quest_file_registers_the_two_quests_with_start_true_and_the_screenplay_with_start_false()
	for _, global in ipairs(M.GLOBALS) do
		M.quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called. Load problems: " .. M.problems())
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	M.mts()
	lu.assertNotNil(H.registered("MasterTrainerScreenplay"), "MasterTrainerScreenplay: registerScreenPlay was not called")
	lu.assertEquals(H.registered("MasterTrainerScreenplay").start, false, "MasterTrainerScreenplay: registered with start = false")
end

-- AC-1, Content contract 1
function TestMasterTrainerImperialWiring:test_the_screenplay_object_has_the_quest_strings_and_the_two_cross_trainer_keys()
	local mts = M.mts()

	for key, want in pairs(M.MTS_CONSTANTS) do
		lu.assertEquals(rawget(mts, key), want, "MasterTrainerScreenplay." .. key)
	end

	lu.assertEquals(type(mts.resetDeclannQuests), "function", "MasterTrainerScreenplay:resetDeclannQuests")
end

-- AC-1: the template and the handler
function TestMasterTrainerImperialWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	M.requireConversation(lu)

	local t = H.conversationTemplateTable(M.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, M.HANDLER, M.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", M.TEMPLATE .. ": templateType")

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isPaid", "payMission", "grantMaster" }) do
		lu.assertEquals(type(rawget(_G, M.HANDLER)[fn]), "function", M.HANDLER .. ":" .. fn)
	end
end

-- AC-1, Content contract 2: the handler's tables
function TestMasterTrainerImperialWiring:test_the_handler_names_the_missions_start_screens_reward_screens_standing_and_master_skill()
	local h = M.handler()

	lu.assertEquals(h.MISSIONS, {
		{ head = "destroy_master_imperial_1", questString = "QUEST_STRING_IMPERIAL_1" },
		{ head = "destroy_master_imperial_2", questString = "QUEST_STRING_IMPERIAL_2" },
	}, M.HANDLER .. ".MISSIONS")
	lu.assertEquals(h.START_SCREENS, M.STARTS, M.HANDLER .. ".START_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, { m1_reward = 1, master_grant = 2 }, M.HANDLER .. ".REWARD_SCREENS")
	lu.assertEquals(h.STANDING, { 200, 400 }, M.HANDLER .. ".STANDING")
	lu.assertEquals(h.MASTER_SKILL, "pilot_imperial_navy_master", M.HANDLER .. ".MASTER_SKILL")
	lu.assertEquals(h.MASTER_SCREEN, "master_grant", M.HANDLER .. ".MASTER_SCREEN")
end

-- AC-1: Declann
function TestMasterTrainerImperialWiring:test_declann_uses_the_template_and_has_the_conversable_mask()
	-- the creature file merges attack groups of creatureskills.lua, which the harness does not load: empty ones stand in
	for _, group in ipairs({ "brawlermaster", "marksmanmaster" }) do
		if rawget(_G, group) == nil then
			rawset(_G, group, {})
		end
	end

	local npc = H.loadCreatureTemplate("space/nial_declann.lua", "nial_declann")

	lu.assertNotNil(npc, "mobile/space/nial_declann.lua registers nial_declann")
	lu.assertEquals(npc.conversationTemplate, "nial_declann_convo_template", "nial_declann: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "nial_declann: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "nial_declann: optionsBitmask")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:nial_declann", "nial_declann: objectName is unchanged")
end

-- AC-1: screenplays.lua, directly after Storm's include
function TestMasterTrainerImperialWiring:test_screenplays_lua_includes_the_quest_file_and_the_handler_once_after_the_storm_include()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")

	lu.assertNotNil(text, "screenplays/space/screenplays.lua")

	local lines = linesOf(text)
	local mts = 'includeFile("space/squadrons/MasterTrainerScreenplay.lua")'
	local handler = 'includeFile("space/conversations/imperial/nialDeclannConvoHandler.lua")'

	lu.assertEquals(countOf(lines, mts), 1, "screenplays.lua: uncommented MasterTrainerScreenplay include")
	lu.assertEquals(countOf(lines, handler), 1, "screenplays.lua: uncommented nialDeclannConvoHandler include")

	for _, l in ipairs(lines) do
		lu.assertFalse(l:find("%-%-%s*includeFile%(\"space/squadrons/MasterTrainerScreenplay") ~= nil, "screenplays.lua: commented MasterTrainerScreenplay include")
		lu.assertFalse(l:find("%-%-%s*includeFile%(\"space/conversations/imperial/nialDeclann") ~= nil, "screenplays.lua: commented nialDeclannConvoHandler include")
	end

	-- storm-tier2-alozen: Alozen's handler include follows technician 3's, so the anchor is hers (storm-tier2-nym-technicians: technician 3's include sat there before)
	local storm = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")')

	lu.assertNotNil(storm, "screenplays.lua: the alozenConvoHandler include (storm-tier2-alozen)")
	lu.assertEquals({ lines[storm + 1], lines[storm + 2], lines[storm + 3], lines[storm + 4], lines[storm + 5] },
		{ "", "-- Master Trainers", mts, "", handler }, "screenplays.lua: the five lines directly after the last Nym technician handler include")
end

-- AC-1: space_conversations.lua, directly after the Imperial Pilot comment
function TestMasterTrainerImperialWiring:test_space_conversations_includes_the_template_once_directly_after_the_imperial_pilot_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")

	lu.assertNotNil(text, "mobile/conversations/space/space_conversations.lua")

	local lines = linesOf(text)
	local include = 'includeFile("conversations/space/imperial/nial_declann_convo.lua")'

	lu.assertEquals(countOf(lines, include), 1, "space_conversations.lua: uncommented nial_declann_convo include")

	for _, l in ipairs(lines) do
		lu.assertFalse(l:find("%-%-%s*includeFile%(\"conversations/space/imperial/nial_declann") ~= nil, "space_conversations.lua: commented nial_declann_convo include")
	end

	local comment = indexOf(lines, "-- Imperial Pilot")

	lu.assertNotNil(comment, "space_conversations.lua: the '-- Imperial Pilot' comment")
	lu.assertEquals(lines[comment + 1], include, "space_conversations.lua: the include directly after '-- Imperial Pilot'")
end

-- AC-1: the Black Epsilon include-position tests still hold (they look at the lines after '-- Black Epsilon Squadron')
function TestMasterTrainerImperialWiring:test_the_black_epsilon_includes_stay_under_their_comment()
	local lines = linesOf(readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua"))
	local be = indexOf(lines, "-- Black Epsilon Squadron")

	lu.assertNotNil(be, "space_conversations.lua: the '-- Black Epsilon Squadron' comment")
	lu.assertEquals(lines[be + 1], 'includeFile("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua")', "space_conversations.lua: Hakassha stays first")
	lu.assertEquals(lines[be + 4], 'includeFile("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua")', "space_conversations.lua: Nin Gursawe stays fourth")
end

-- AC-1: the three new files exist where the includes point
function TestMasterTrainerImperialWiring:test_the_three_new_production_files_exist()
	for _, path in ipairs({ M.MTS_FILE, M.TEMPLATE_FILE, M.HANDLER_FILE }) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path), "bin/scripts/" .. path .. " does not exist")
	end
end

-- Content contract 1: header comment
function TestMasterTrainerImperialWiring:test_the_quest_file_header_names_the_source_the_feature_and_the_rebel_trainer()
	local text = readFile(H.SCRIPTS .. M.MTS_FILE)

	lu.assertNotNil(text, "bin/scripts/" .. M.MTS_FILE)

	local head = text:sub(1, 900)

	lu.assertNotNil(head:find("master_imperial_1", 1, true), "MTS header names the SWG-Source quests")
	lu.assertNotNil(head:find("space-master-trainer-imperial", 1, true), "MTS header names the feature")
	lu.assertNotNil(head:lower():find("rebel", 1, true), "MTS header says the Rebel master trainer adds its quests here")
end
