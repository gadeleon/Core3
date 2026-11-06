-- Storm tier 2, the Nym technicians: the server load order, the include lines, the three NPC templates and the squadron object.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-1; Content contract 1, 2, 4; I-7; E-1, E-2, D-6).

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end
local H = require("harness")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

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

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

local function indexOf(lines, wanted)
	for i, l in ipairs(lines) do
		if l:gsub("^%s+", "") == wanted then
			return i
		end
	end
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

TestStormNymWiring = {}

function TestStormNymWiring:setUp() H.reset() end

-- AC-1: the three templates are registered with their luaClassHandler, the three handler globals exist
for n = 1, 3 do
	local c = N.CONVOS[n]

	-- AC-1
	TestStormNymWiring["test_" .. c.template .. "_is_registered_with_its_handler_class"] = function()
		local t = H.conversationTemplateTable(c.template)

		lu.assertNotNil(t, c.template .. " is not registered by addConversationTemplate (" .. c.templateFile .. "). Load problems: " .. N.errors(n))
		lu.assertEquals(t.luaClassHandler, c.handler, c.template .. ": luaClassHandler")
		lu.assertEquals(t.templateType, "Lua", c.template .. ": templateType")
	end

	-- AC-1
	TestStormNymWiring["test_" .. c.handler .. "_is_a_conversation_handler_with_the_three_entry_points"] = function()
		local handler = rawget(_G, c.handler)

		lu.assertNotNil(handler, c.handler .. " is not defined (" .. c.handlerFile .. "). Load problems: " .. N.errors(n))
		lu.assertEquals(type(handler.getInitialScreen), "function", c.handler .. ":getInitialScreen")
		lu.assertEquals(type(handler.runScreenHandlers), "function", c.handler .. ":runScreenHandlers")
		lu.assertEquals(handler.getNextConversationScreen, conv_handler.getNextConversationScreen, c.handler .. ": no getNextConversationScreen override (the default link following)")
	end

	-- AC-1: Content contract 2/3 file layout
	TestStormNymWiring["test_the_files_of_conversation_" .. n .. "_exist_at_the_contract_paths"] = function()
		lu.assertNotNil(readFile(H.SCRIPTS .. c.templateFile), c.templateFile)
		lu.assertNotNil(readFile(H.SCRIPTS .. c.handlerFile), c.handlerFile)
	end
end

-- AC-1: space_conversations.lua, the three template lines directly after Oberhaur's, once each, uncommented
function TestStormNymWiring:test_the_three_template_includes_follow_oberhaurs_directly_once_each()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")

	lu.assertNotNil(text, "mobile/conversations/space/space_conversations.lua")

	for n = 1, 3 do
		local line = 'includeFile%("' .. N.CONVOS[n].templateRel:gsub("%.", "%%.") .. '"%)'

		lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented nym_technician_" .. n .. "_convo include")
		lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented nym_technician_" .. n .. "_convo include")
	end

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("conversations/space/imperial/storm_squadron/oberhaur_convo.lua")')

	lu.assertNotNil(at, "space_conversations.lua: the oberhaur_convo include")

	for n = 1, 3 do
		lu.assertEquals(trim(lines[at + n] or ""), 'includeFile("' .. N.CONVOS[n].templateRel .. '")', "space_conversations.lua: technician " .. n .. "'s include, directly after Oberhaur's and the earlier technicians'")
	end

	local last = #lines

	while last > 1 and trim(lines[last]) == "" do
		last = last - 1
	end

	-- storm-tier2-alozen: Alozen's include follows technician 3's and is the last line now
	lu.assertEquals(trim(lines[at + 4] or ""), 'includeFile("conversations/space/imperial/storm_squadron/alozen_convo.lua")', "space_conversations.lua: Alozen's include directly after technician 3's (storm-tier2-alozen)")
	lu.assertEquals(trim(lines[at + 5] or ""), 'includeFile("conversations/space/imperial/storm_squadron/denner_convo.lua")', "space_conversations.lua: Denner's include directly after Alozen's (storm-tier3-denner)")
	lu.assertEquals(last, at + 5, "space_conversations.lua: Denner's include is the last line of the file (technician 3's was before storm-tier2-alozen, Alozen's before storm-tier3-denner)")
end

-- AC-1: screenplays.lua, the three handler lines directly after Oberhaur's, no blank line, then the blank line and the Master Trainers block
function TestStormNymWiring:test_the_three_handler_includes_follow_oberhaurs_directly_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")

	lu.assertNotNil(text, "screenplays/space/screenplays.lua")

	for n = 1, 3 do
		local line = 'includeFile%("' .. N.CONVOS[n].handlerRel:gsub("%.", "%%.") .. '"%)'

		lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented nymTechnician" .. n .. "ConvoHandler include")
		lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented nymTechnician" .. n .. "ConvoHandler include")
	end

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua")')

	lu.assertNotNil(at, "screenplays.lua: Oberhaur's handler include")

	for n = 1, 3 do
		lu.assertEquals(lines[at + n], 'includeFile("' .. N.CONVOS[n].handlerRel .. '")', "screenplays.lua: technician " .. n .. "'s handler include, directly after Oberhaur's and the earlier technicians'")
	end

	-- storm-tier2-alozen: Alozen's handler include follows technician 3's, so the blank line and the Master Trainers block move down by one
	lu.assertEquals(lines[at + 4], 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")', "screenplays.lua: Alozen's include follows technician 3's (storm-tier2-alozen)")
	lu.assertEquals(lines[at + 5], 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")', "screenplays.lua: Denner's include follows Alozen's (storm-tier3-denner)")
	lu.assertEquals(lines[at + 6], "", "screenplays.lua: the blank line follows Denner's include (storm-tier3-denner)")
	lu.assertEquals(lines[at + 7], "-- Master Trainers", "screenplays.lua: the Master Trainers block follows")
end

-- AC-1, D-6, E-1: nym_fuel_tech / _2 / _3 are conversable, invulnerable and attach technician n's template; the rest of the template is as it was
local NPC_REST = {
	objectName = "@npc_spawner_n:nym_fuel_tech",
	socialGroup = "imperial",
	faction = "imperial",
	level = 100,
	chanceHit = 1,
	damageMin = 645,
	damageMax = 1000,
	baseXp = 9429,
	baseHAM = 24000,
	baseHAMmax = 30000,
	armor = 0,
	resists = { 0, 0, 0, 0, 0, 0, 0, 0, -1 },
	meatType = "",
	meatAmount = 0,
	hideType = "",
	hideAmount = 0,
	boneType = "",
	boneAmount = 0,
	milk = 0,
	tamingChance = 0,
	ferocity = 0,
	lootGroups = {},
	primaryWeapon = "unarmed",
	secondaryWeapon = "none",
	primaryAttacks = {},
	secondaryAttacks = {},
}

for n = 1, 3 do
	local c = N.CONVOS[n]

	-- AC-1, D-6
	TestStormNymWiring["test_" .. c.npcName .. "_is_conversable_invulnerable_and_attaches_" .. c.template] = function()
		local t = H.loadCreatureTemplate(c.mobileFile, c.npcName)

		lu.assertNotNil(t, c.mobileFile .. " registers " .. c.npcName)
		lu.assertEquals(t.conversationTemplate, c.template, c.npcName .. ": conversationTemplate")
		lu.assertEquals(t.optionsBitmask, AIENABLED + CONVERSABLE + INVULNERABLE, c.npcName .. ": optionsBitmask (D-6: no JTLINTERESTING)")
	end

	-- AC-1: only those two fields differ from the template as it was
	TestStormNymWiring["test_" .. c.npcName .. "_changes_nothing_but_the_options_and_the_conversation"] = function()
		local t = H.loadCreatureTemplate(c.mobileFile, c.npcName)

		lu.assertNotNil(t, c.mobileFile .. " registers " .. c.npcName)

		local expected = {}

		for k, v in pairs(NPC_REST) do
			expected[k] = v
		end

		expected.mobType = MOB_NPC
		expected.pvpBitmask = NONE
		expected.creatureBitmask = PACK
		expected.diet = HERBIVORE
		expected.templates = { c.client }
		expected.optionsBitmask = t.optionsBitmask
		expected.conversationTemplate = t.conversationTemplate

		local got = {}

		for k, v in pairs(t) do
			got[k] = v
		end

		lu.assertEquals(got, expected, c.npcName .. ": template fields other than optionsBitmask and conversationTemplate")
	end
end

-- AC-1, I-7, E-1: the buildout excerpt (SWG tatooine.tab rows 36, 37, 56) says script N belongs to template N; it is byte-identical to the SWG file
function TestStormNymWiring:test_the_buildout_excerpt_attaches_conversation_n_to_template_n()
	local path = H.FIXTURES .. "space_zones/buildout/tatooine.nym_technicians.tab"
	local text = readFile(path)

	lu.assertNotNil(text, path)

	local scripts = {}

	for line in text:gmatch("[^\n]+") do
		local object, script = line:match("^(object/mobile/dressed_nym_technician_%d%.iff)\t.*\t(script%.conversation%.nym_technician_%d,script%.space%.characters%.technician)")

		if object ~= nil then
			scripts[object] = script
		end
	end

	for n = 1, 3 do
		lu.assertEquals(scripts[N.CONVOS[n].client], "script.conversation.nym_technician_" .. n .. ",script.space.characters.technician", "buildout script column of " .. N.CONVOS[n].client)
	end

	lu.assertEquals(select(2, text:gsub("\n", "\n")), 5, "the excerpt holds the two header rows and rows 36, 37, 56")
end

-- AC-1, E-1: the excerpt is a byte copy of the SWG rows
function TestStormNymWiring:test_the_buildout_excerpt_is_a_byte_copy_of_the_swg_rows()
	local swg = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/space_zones/buildout/tatooine.tab"
	local source = readFile(swg)

	if source == nil then
		lu.skip(swg .. " is not on this machine")
	end

	local rows = {}

	for line in source:gmatch("[^\n]*\n") do
		rows[#rows + 1] = line
	end

	local want = rows[1] .. rows[2] .. rows[36] .. rows[37] .. rows[56]

	lu.assertEquals(readFile(H.FIXTURES .. "space_zones/buildout/tatooine.nym_technicians.tab"), want, "tatooine.nym_technicians.tab versus SWG tatooine.tab lines 1, 2, 36, 37, 56")
end

-- AC-1, E-2: the Zabrak is technician 3 (zab_f, gender 1); technician 1 is the Rodian male, 2 the human male
function TestStormNymWiring:test_the_client_templates_give_technician_3_the_zabrak_appearance()
	local text = readFile(H.SCRIPTS .. "object/mobile/objects.lua")

	lu.assertNotNil(text, "object/mobile/objects.lua")

	local want = { [1] = { "rod_m", 0 }, [2] = { "hum_m", 0 }, [3] = { "zab_f", 1 } }

	for n = 1, 3 do
		local block = text:match('object_mobile_shared_dressed_nym_technician_' .. n .. ' = SharedCreatureObjectTemplate:new {(.-)\nObjectTemplates:addClientTemplate')

		lu.assertNotNil(block, "client template of dressed_nym_technician_" .. n)
		contains(block, 'appearanceFilename = "appearance/' .. want[n][1] .. '.sat"', "technician " .. n .. ": appearance")
		contains(block, "gender = " .. want[n][2] .. ",", "technician " .. n .. ": gender")
	end
end

-- AC-1: Lok's stronghold spawns are unchanged (NS:115-117), and the Zabrak stands in the stronghold building's cell 6595514
function TestStormNymWiring:test_the_stronghold_still_spawns_the_three_technicians_where_it_did()
	local text = readFile(H.SCRIPTS .. "screenplays/cities/lok_nym_stronghold.lua")

	lu.assertNotNil(text, "screenplays/cities/lok_nym_stronghold.lua")

	local lines = linesOf(text)

	lu.assertEquals(trim(lines[115]), '{"nym_fuel_tech", 60, 374.599, 11.9876, 4986.77, 31.5798, 0, "neutral"},', "lok_nym_stronghold.lua:115")
	lu.assertEquals(trim(lines[116]), '{"nym_fuel_tech_2", 60, 481.309, 23.0, 4961.29, 173, 0, "neutral"},', "lok_nym_stronghold.lua:116")
	lu.assertEquals(trim(lines[117]), '{"nym_fuel_tech_3", 60, -23.933, 4.223, -37.526, 0, 6595514, "neutral"},', "lok_nym_stronghold.lua:117")
end

-- AC-1: the squadron object
function TestStormNymWiring:test_the_squadron_has_the_tip_key_and_the_three_claw_functions()
	local SS = N.squadron(lu)

	lu.assertEquals(SS.TIER2_MORV_TIP_KEY, "StormSquadronScreenplay:spokeToMorv", "StormSquadronScreenplay.TIER2_MORV_TIP_KEY")
	lu.assertEquals(SS.TIER2_FINDING_AGENT_KEY, "StormSquadronScreenplay:findingAgent", "the existing finding key stays")
end
