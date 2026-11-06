-- Lt. Colonel Barlow: the template and handler are registered, included once after Vrke's, and Barlow's NPC template converses.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-1; Content contract 2 and 3; D-11).

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")

B.load()

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function fileLines(text)
	local lines = {}

	for l in (text .. "\n"):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = l
	end

	return lines
end

local function countMatches(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

TestBarlowWiring = {}

function TestBarlowWiring:setUp() H.reset() end

-- AC-1
function TestBarlowWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	B.requireConversation(lu)

	local t = H.conversationTemplateTable(B.TEMPLATE)
	local handler = rawget(_G, B.HANDLER)

	lu.assertEquals(t.luaClassHandler, B.HANDLER, B.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", B.TEMPLATE .. ": templateType")
	lu.assertEquals(type(handler.getInitialScreen), "function", B.HANDLER .. ":getInitialScreen")
	lu.assertEquals(type(handler.runScreenHandlers), "function", B.HANDLER .. ":runScreenHandlers")
	lu.assertEquals(type(handler.getNextConversationScreen), "function", B.HANDLER .. ":getNextConversationScreen (inherited from conv_handler)")
	lu.assertEquals(rawget(handler, "getNextConversationScreen"), nil, B.HANDLER .. " has no getNextConversationScreen override (the static links drive the interview)")
end

-- Content contract 2: END_SCREENS is the five removeTalktoBarlow carriers
function TestBarlowWiring:test_the_handler_names_the_five_end_screens()
	B.requireConversation(lu)

	local want = {}

	for _, id in ipairs(B.END_SCREENS) do
		want[id] = true
	end

	lu.assertEquals(rawget(_G, B.HANDLER).END_SCREENS, want, B.HANDLER .. ".END_SCREENS")
end

-- Content contract 2: line 1 of the handler is a header comment and the handler requires space_helpers
function TestBarlowWiring:test_the_handler_starts_with_a_header_comment_and_requires_the_space_helpers()
	B.requireConversation(lu)

	local text = readFile(H.SCRIPTS .. B.HANDLER_FILE)
	local lines = fileLines(text)

	lu.assertEquals(lines[1]:sub(1, 2), "--", "line 1 is a comment")
	lu.assertStrContains(lines[1], "naboo_imperial_tier3_barlow.java", false, "line 1 names the java")
	lu.assertStrContains(lines[1], "inquisition-tier3-barlow", false, "line 1 names the feature")
	local requireAt = text:find('local SpaceHelpers = require("utils.space_helpers")', 1, true)
	local handlerAt = text:find("\nbarlowConvoHandler = conv_handler:new {}", 1, true)

	lu.assertNotNil(requireAt, "local SpaceHelpers = require(\"utils.space_helpers\")")
	lu.assertNotNil(handlerAt, "barlowConvoHandler = conv_handler:new {}")
	lu.assertTrue(requireAt < handlerAt, "the require comes before the handler table")
end

-- AC-1: the template include is uncommented exactly once, directly after Vrke's
function TestBarlowWiring:test_the_template_include_line_is_uncommented_exactly_once_directly_after_vrkes()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local line = 'includeFile%("conversations/space/imperial/inquisition_squadron/barlow_convo%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented barlow_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented barlow_convo include")

	local lines, at = fileLines(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("conversations/space/imperial/inquisition_squadron/vrke_convo.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "space_conversations.lua: the vrke_convo include")
	lu.assertEquals((lines[at + 1] or ""):gsub("^%s+", ""), 'includeFile("conversations/space/imperial/inquisition_squadron/barlow_convo.lua")', "space_conversations.lua: the barlow include directly after Vrke's")
end

-- AC-1: the handler include follows Vrke's handler include with no blank line
function TestBarlowWiring:test_the_handler_include_line_follows_vrkes_handler_include_exactly_once_with_no_blank_line()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local line = 'includeFile%("space/conversations/imperial/inquisition_squadron/barlowConvoHandler%.lua"%)'

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented barlowConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented barlowConvoHandler include")

	local lines, at = fileLines(text), nil

	for i, l in ipairs(lines) do
		if l:find('includeFile("space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua")', 1, true) then
			at = i
		end
	end

	lu.assertNotNil(at, "screenplays.lua: Vrke's handler include")
	lu.assertEquals(lines[at + 1], 'includeFile("space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua")', "screenplays.lua: Barlow's handler include, directly after Vrke's")
end

-- AC-1: Barlow's NPC template converses: the template name and the options mask
function TestBarlowWiring:test_barlow_uses_the_template_and_has_vrkes_options_mask()
	local npc = H.loadCreatureTemplate("space/barlow.lua", "barlow")

	lu.assertNotNil(npc, "mobile/space/barlow.lua registers barlow")
	lu.assertEquals(npc.conversationTemplate, "barlow_convo_template", "barlow: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "barlow: optionsBitmask (J3B OnAttach: conversable, invulnerable, space interesting)")
end

-- AC-1: the other fields of Barlow's template are unchanged
function TestBarlowWiring:test_barlows_other_template_fields_are_unchanged()
	local npc = H.loadCreatureTemplate("space/barlow.lua", "barlow")

	lu.assertNotNil(npc, "mobile/space/barlow.lua registers barlow")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:barlow", "objectName")
	lu.assertEquals(npc.faction, "imperial", "faction")
	lu.assertEquals(npc.socialGroup, "imperial", "socialGroup")
	lu.assertEquals(npc.pvpBitmask, NONE, "pvpBitmask")
	lu.assertEquals(npc.creatureBitmask, PACK, "creatureBitmask")
	lu.assertEquals(npc.templates, { "object/mobile/dressed_imperial_officer_m_5.iff" }, "templates")
	lu.assertEquals(npc.primaryWeapon, "unarmed", "primaryWeapon")
	lu.assertEquals(npc.secondaryWeapon, "none", "secondaryWeapon")
	lu.assertEquals(npc.level, 100, "level")
end

-- AC-1: the spawn row is unchanged
function TestBarlowWiring:test_the_spawn_row_at_line_33_is_unchanged()
	local lines = fileLines(readFile(H.SCRIPTS .. "screenplays/poi/yavin4_imperial_base.lua"))

	lu.assertEquals(lines[33], '\t\t{"barlow", 60, 4028.91, 37, -6201.62, 150, 0, "npc_imperial"}', "yavin4_imperial_base.lua:33")
end

return nil
