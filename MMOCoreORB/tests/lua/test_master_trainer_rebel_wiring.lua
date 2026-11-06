-- Rebel master trainer (Admiral Willham Burke): the server load order wires the quest tables, the template, the handler and the NPC.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (AC-1; Content contract 1 and 3).
--
-- Include positions are read as text from the two include files, as the tier 4 wiring tests do.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")

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

TestMasterTrainerRebelWiring = {}

function TestMasterTrainerRebelWiring:setUp() H.reset() end

-- AC-1
function TestMasterTrainerRebelWiring:test_the_quest_file_registers_the_two_rebel_quests_with_start_true_next_to_the_imperial_ones()
	for _, global in ipairs(M.GLOBALS) do
		M.quest(global)
		lu.assertNotNil(H.registered(global), global .. ": registerScreenPlay was not called. Load problems: " .. M.problems())
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	for _, global in ipairs({ "destroy_master_imperial_1", "destroy_master_imperial_2" }) do
		lu.assertNotNil(H.registered(global), global .. ": the Imperial quests stay registered")
		lu.assertTrue(H.registered(global).start, global .. ": registered with start = true")
	end

	M.mts()
	lu.assertNotNil(H.registered("MasterTrainerScreenplay"), "MasterTrainerScreenplay: registerScreenPlay was not called")
	lu.assertEquals(H.registered("MasterTrainerScreenplay").start, false, "MasterTrainerScreenplay: registered with start = false")
end

-- AC-1, Content contract 1
function TestMasterTrainerRebelWiring:test_the_screenplay_object_has_the_rebel_quest_strings_the_imperial_ones_and_the_two_keys_unchanged()
	local mts = M.mts()

	for key, want in pairs(M.MTS_CONSTANTS) do
		lu.assertEquals(rawget(mts, key), want, "MasterTrainerScreenplay." .. key)
	end

	lu.assertEquals(type(mts.resetBurkeQuests), "function", "MasterTrainerScreenplay:resetBurkeQuests")
	lu.assertEquals(type(mts.resetDeclannQuests), "function", "MasterTrainerScreenplay:resetDeclannQuests stays")
end

-- AC-1: the template and the handler
function TestMasterTrainerRebelWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	M.requireConversation(lu)

	local t = H.conversationTemplateTable(M.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, M.HANDLER, M.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", M.TEMPLATE .. ": templateType")

	for _, fn in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isPaid", "payMission", "grantMaster" }) do
		lu.assertEquals(type(rawget(_G, M.HANDLER)[fn]), "function", M.HANDLER .. ":" .. fn)
	end
end

-- AC-1, Content contract 2: the handler's tables
function TestMasterTrainerRebelWiring:test_the_handler_names_the_missions_start_screens_reward_screens_standing_and_master_skill()
	local h = M.handler()

	lu.assertEquals(h.MISSIONS, {
		{ head = "destroy_master_rebel_1", questString = "QUEST_STRING_REBEL_1" },
		{ head = "destroy_master_rebel_2", questString = "QUEST_STRING_REBEL_2" },
	}, M.HANDLER .. ".MISSIONS")
	lu.assertEquals(h.START_SCREENS, M.STARTS, M.HANDLER .. ".START_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, { m1_reward = 1, master_grant = 2 }, M.HANDLER .. ".REWARD_SCREENS")
	lu.assertEquals(h.STANDING, { 200, 400 }, M.HANDLER .. ".STANDING")
	lu.assertEquals(h.MASTER_SKILL, "pilot_rebel_navy_master", M.HANDLER .. ".MASTER_SKILL")
	lu.assertEquals(h.MASTER_SCREEN, "master_grant", M.HANDLER .. ".MASTER_SCREEN")
end

-- AC-1: Burke
function TestMasterTrainerRebelWiring:test_burke_uses_the_template_and_has_the_conversable_mask()
	-- the creature file merges attack groups of creatureskills.lua, which the harness does not load: empty ones stand in
	for _, group in ipairs({ "brawlermaster", "marksmanmaster" }) do
		if rawget(_G, group) == nil then
			rawset(_G, group, {})
		end
	end

	local npc = H.loadCreatureTemplate("space/willham_burke.lua", "willham_burke")

	lu.assertNotNil(npc, "mobile/space/willham_burke.lua registers willham_burke")
	lu.assertEquals(npc.conversationTemplate, "willham_burke_convo_template", "willham_burke: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "willham_burke: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + CONVERSABLE + JTLINTERESTING, "willham_burke: optionsBitmask")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:willham_burke", "willham_burke: objectName is unchanged")
end

-- AC-1: screenplays.lua, directly after Declann's handler include (the Imperial five lines after Storm stay)
function TestMasterTrainerRebelWiring:test_screenplays_lua_includes_burkes_handler_once_directly_after_declanns_handler()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")

	lu.assertNotNil(text, "screenplays/space/screenplays.lua")

	local lines = linesOf(text)
	local mts = 'includeFile("space/squadrons/MasterTrainerScreenplay.lua")'
	local declann = 'includeFile("space/conversations/imperial/nialDeclannConvoHandler.lua")'
	local burke = 'includeFile("space/conversations/rebel/willhamBurkeConvoHandler.lua")'

	lu.assertEquals(countOf(lines, burke), 1, "screenplays.lua: uncommented willhamBurkeConvoHandler include")

	for _, l in ipairs(lines) do
		lu.assertFalse(l:find("%-%-%s*includeFile%(\"space/conversations/rebel/willhamBurke") ~= nil, "screenplays.lua: commented willhamBurkeConvoHandler include")
	end

	-- storm-tier2-oberhaur: Oberhaur's handler include follows Colzet's, so the anchor is his include (storm-tier1-akal-colzet: Colzet's sat there before)
	local storm = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua")')

	lu.assertNotNil(storm, "screenplays.lua: the oberhaurConvoHandler include (storm-tier2-oberhaur)")
	lu.assertEquals({ lines[storm + 1], lines[storm + 2], lines[storm + 3], lines[storm + 4], lines[storm + 5] },
		{ "", "-- Master Trainers", mts, "", declann }, "screenplays.lua: the five Imperial lines directly after Oberhaur's handler include are unchanged")
	lu.assertEquals(lines[storm + 6], burke, "screenplays.lua: the Burke include directly after Declann's")
end

-- AC-1: space_conversations.lua, directly after the Rebel Pilot comment
function TestMasterTrainerRebelWiring:test_space_conversations_includes_the_template_once_directly_after_the_rebel_pilot_comment()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")

	lu.assertNotNil(text, "mobile/conversations/space/space_conversations.lua")

	local lines = linesOf(text)
	local include = 'includeFile("conversations/space/rebel/willham_burke_convo.lua")'

	lu.assertEquals(countOf(lines, include), 1, "space_conversations.lua: uncommented willham_burke_convo include")

	for _, l in ipairs(lines) do
		lu.assertFalse(l:find("%-%-%s*includeFile%(\"conversations/space/rebel/willham_burke") ~= nil, "space_conversations.lua: commented willham_burke_convo include")
	end

	local comment = indexOf(lines, "-- Rebel Pilot")

	lu.assertNotNil(comment, "space_conversations.lua: the '-- Rebel Pilot' comment")
	lu.assertEquals(lines[comment + 1], include, "space_conversations.lua: the include directly after '-- Rebel Pilot'")
	lu.assertEquals(countOf(lines, 'includeFile("conversations/space/imperial/nial_declann_convo.lua")'), 1, "space_conversations.lua: Declann's include stays")
end

-- AC-1: the Black Epsilon include-position tests still hold (they look at the lines after '-- Black Epsilon Squadron')
function TestMasterTrainerRebelWiring:test_the_black_epsilon_includes_stay_under_their_comment()
	local lines = linesOf(readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua"))
	local be = indexOf(lines, "-- Black Epsilon Squadron")

	lu.assertNotNil(be, "space_conversations.lua: the '-- Black Epsilon Squadron' comment")
	lu.assertEquals(lines[be + 1], 'includeFile("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua")', "space_conversations.lua: Hakassha stays first")
	lu.assertEquals(lines[be + 4], 'includeFile("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua")', "space_conversations.lua: Nin Gursawe stays fourth")
end

-- AC-1: the two new production files exist where the includes point
function TestMasterTrainerRebelWiring:test_the_two_new_production_files_exist()
	for _, path in ipairs({ M.TEMPLATE_FILE, M.HANDLER_FILE }) do
		lu.assertTrue(H.fileExists(H.SCRIPTS .. path), "bin/scripts/" .. path .. " does not exist")
	end
end

-- Content contract 1: the quest file header (one inserted line after line 6; the old lines stay)
function TestMasterTrainerRebelWiring:test_the_quest_file_header_names_burkes_quests_and_the_feature()
	local text = readFile(H.SCRIPTS .. M.MTS_FILE)

	lu.assertNotNil(text, "bin/scripts/" .. M.MTS_FILE)

	local head = linesOf(text)

	lu.assertEquals(head[6], "\t(feature space-master-trainer-imperial). The Rebel master trainer adds its quests to this file.", "MTS header line 6 stays as is")
	lu.assertEquals(head[7], "\tAdmiral Burke's quests, ported from SWG-Source destroy/master_rebel_1 and master_rebel_2 (feature space-master-trainer-rebel).", "MTS header line 7 is the inserted line")
end
