-- Kiizete: wiring (AC-1).
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (AC-1; Content contract 1, 2, 3 and 4; D-10).
--
-- The template and the handler load through the server's include order, her mobile template names the conversation and is conversable and
-- invulnerable, the two include lines sit at lines 96 and 145 and nothing above them moved, and the squadron object has the two flag keys.

local lu = require("luaunit")
local H = require("harness")
local K = require("vortex_tier1_kiizete_data")

K.load()

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function linesOf(text)
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

TestVortexKiizeteWiring = {}

function TestVortexKiizeteWiring:setUp() H.reset() end

-- AC-1
function TestVortexKiizeteWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	K.requireConversation(lu)

	local t = H.conversationTemplateTable(K.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, K.HANDLER, K.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", K.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", K.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, K.HANDLER)

	for _, name in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isImperial", "isOnFirstMission", "hasWonMissionOne", "hasFailedMissionOne" }) do
		lu.assertEquals(type(h[name]), "function", K.HANDLER .. ":" .. name)
	end
end

-- AC-1: her mobile template names the conversation and gets the V3-FX mask
function TestVortexKiizeteWiring:test_kiizete_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/kiizete.lua", "kiizete")

	lu.assertNotNil(npc, "mobile/space/kiizete.lua registers kiizete")
	lu.assertEquals(npc.conversationTemplate, "kiizete_convo_template", "kiizete: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "kiizete: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "kiizete: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & AIENABLED, AIENABLED, "kiizete: optionsBitmask lacks AIENABLED")
	lu.assertEquals(npc.optionsBitmask & JTLINTERESTING, JTLINTERESTING, "kiizete: optionsBitmask lacks JTLINTERESTING")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "kiizete: optionsBitmask (the V3-FX mask)")
end

-- AC-1: only the two fields change; her identity stays
function TestVortexKiizeteWiring:test_kiizete_keeps_her_identity_fields()
	local npc = H.loadCreatureTemplate("space/kiizete.lua", "kiizete")

	lu.assertNotNil(npc, "mobile/space/kiizete.lua registers kiizete")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:kiizete", "kiizete: objectName")
	lu.assertEquals(npc.faction, "rebel", "kiizete: faction")
	lu.assertEquals(npc.pvpBitmask, NONE, "kiizete: pvpBitmask")
end

-- AC-1, D-10: the template include sits uncommented at line 96, after the vrovel placeholder; lines 91-95 are unchanged
function TestVortexKiizeteWiring:test_the_template_include_is_uncommented_at_line_96_and_lines_91_to_95_are_unchanged()
	local text = readFile(H.SCRIPTS .. "mobile/conversations/space/space_conversations.lua")
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/vortex_squadron/kiizete_convo%.lua"%)'), 1, "space_conversations.lua: kiizete_convo include occurrences (commented or not)")
	lu.assertEquals(lines[96], 'includeFile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua")', "space_conversations.lua line 96")
	lu.assertEquals(lines[91], "-- Vortex Squadron", "space_conversations.lua line 91")
	lu.assertEquals(lines[92], '--includeFile("conversations/space/rebel/vortex_squadron/evin_convo.lua")', "space_conversations.lua line 92")
	lu.assertEquals(lines[93], '--includeFile("conversations/space/rebel/vortex_squadron/ezkiel_convo.lua")', "space_conversations.lua line 93")
	lu.assertEquals(lines[94], 'includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")', "space_conversations.lua line 94")
	lu.assertEquals(lines[95], '--includeFile("conversations/space/rebel/vortex_squadron/vrovel_convo.lua")', "space_conversations.lua line 95")
end

-- AC-1, D-10: the handler include sits uncommented at line 145; the squadron include still loads first; lines 138-144 are unchanged
function TestVortexKiizeteWiring:test_the_handler_include_is_uncommented_at_line_145_and_lines_138_to_144_are_unchanged()
	local text = readFile(H.SCRIPTS .. "screenplays/space/screenplays.lua")
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler%.lua"%)'), 1, "screenplays.lua: kiizeteConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[145], 'includeFile("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua")', "screenplays.lua line 145")
	lu.assertEquals(lines[138], "-- Vortex Squadron", "screenplays.lua line 138")
	lu.assertEquals(lines[139], 'includeFile("space/squadrons/VortexSquadronScreenplay.lua")', "screenplays.lua line 139 (the squadron include loads first)")
	lu.assertEquals(lines[140], "", "screenplays.lua line 140")
	lu.assertEquals(lines[141], '--includeFile("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua")', "screenplays.lua line 141")
	lu.assertEquals(lines[142], '--includeFile("space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua")', "screenplays.lua line 142")
	lu.assertEquals(lines[143], 'includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")', "screenplays.lua line 143")
	lu.assertEquals(lines[144], '--includeFile("space/conversations/rebel/vortex_squadron/vrovelConvoHandler.lua")', "screenplays.lua line 144")
end

-- AC-1: the squadron object has the two keys of Content contract 1
function TestVortexKiizeteWiring:test_the_squadron_object_has_the_two_flag_keys()
	K.load()

	local sq = K.squadron()

	lu.assertEquals(sq.KIIZETE_IMP_ASKING_KEY, K.IMP_KEY, "VortexSquadronScreenplay.KIIZETE_IMP_ASKING_KEY")
	lu.assertEquals(sq.KIIZETE_Q1_DISCUSSED_KEY, K.Q1_KEY, "VortexSquadronScreenplay.KIIZETE_Q1_DISCUSSED_KEY")
	lu.assertEquals(sq.VORTEX_PILOT_KEY, "VortexSquadronScreenplay:vortexPilot", "VORTEX_PILOT_KEY is untouched")
end

-- AC-1: the three functions of Content contract 1 exist and treat a missing player as nothing
function TestVortexKiizeteWiring:test_the_flag_functions_exist_and_a_nil_player_is_harmless()
	K.load()

	local sq = K.squadron()

	lu.assertEquals(type(sq.hasKiizeteFlag), "function", "VortexSquadronScreenplay:hasKiizeteFlag")
	lu.assertEquals(type(sq.setKiizeteFlag), "function", "VortexSquadronScreenplay:setKiizeteFlag")
	lu.assertEquals(type(sq.onKiizeteLoggedOut), "function", "VortexSquadronScreenplay:onKiizeteLoggedOut")
	lu.assertEquals(sq:hasKiizeteFlag(nil, K.IMP_KEY), false, "hasKiizeteFlag(nil) is false")
	lu.assertEquals(pcall(sq.setKiizeteFlag, sq, nil, K.IMP_KEY), true, "setKiizeteFlag(nil) returns early")
	lu.assertEquals(#H.Engine.callsTo("createObserver"), 0, "setKiizeteFlag(nil) creates no observer")
	lu.assertEquals(sq:onKiizeteLoggedOut(nil), 1, "onKiizeteLoggedOut(nil) returns 1")
end

-- AC-1, I-6: the source comments of Content contract 1 sit in the squadron file
function TestVortexKiizeteWiring:test_the_squadron_file_carries_the_two_contract_comments()
	local text = readFile(H.SCRIPTS .. require("vortex_tier1_data").SQUADRON_FILE)

	lu.assertNotNil(text:find("-- Kiizete (naboo_rebel_tier1_kiizete.java): SWG utils.setScriptVar flags, kept in server memory and cleared at logout (feature vortex-tier1-kiizete)", 1, true), "keys comment")
	lu.assertNotNil(text:find("-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)", 1, true), "functions comment")
end
