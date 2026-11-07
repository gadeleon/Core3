-- Brother Vrovel: wiring (AC-1).
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-1; Content contract 1 and 3; Source inventory 1; I-8).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable,
-- the two include lines sit at lines 95 and 144 uncommented (once each) while Evin and Ezkiel stay commented, and the handler has the helpers the spec names.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")

V.loadConversation()

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

TestVrovelWiring = {}

function TestVrovelWiring:setUp() H.reset() end

-- AC-1
function TestVrovelWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	V.requireConversation(lu)

	local t = H.conversationTemplateTable(V.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, V.HANDLER, V.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", V.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", V.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, V.HANDLER)

	for _, name in ipairs({ "getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isOnMission", "canFlyNonTrackDuty", "tier2Count", "getPilotFlag", "isReadyForTraining", "isTester" }) do
		lu.assertEquals(type(h[name]), "function", V.HANDLER .. ":" .. name)
	end
end

-- AC-1: his mobile template names the conversation and gets the V3-FX mask
function TestVrovelWiring:test_vrovel_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/vrovel.lua", "vrovel")

	lu.assertNotNil(npc, "mobile/space/vrovel.lua registers vrovel")
	lu.assertEquals(npc.conversationTemplate, "vrovel_convo_template", "vrovel: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "vrovel: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "vrovel: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "vrovel: optionsBitmask (the V3-FX mask)")
end

-- AC-1: only the two fields change; his identity stays
function TestVrovelWiring:test_vrovel_keeps_his_identity_fields()
	local npc = H.loadCreatureTemplate("space/vrovel.lua", "vrovel")

	lu.assertNotNil(npc, "mobile/space/vrovel.lua registers vrovel")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:vrovel", "vrovel: objectName")
	lu.assertEquals(npc.faction, "rebel", "vrovel: faction")
	lu.assertEquals(npc.pvpBitmask, NONE, "vrovel: pvpBitmask")
	lu.assertEquals(npc.templates, { "object/mobile/space_rebel_tier2_vrovel.iff" }, "vrovel: templates")
end

-- AC-1, Content contract 1: the template include sits uncommented at line 95; Evin and Ezkiel stay commented; the lines above and below keep their places
function TestVrovelWiring:test_the_template_include_is_uncommented_once_at_line_95_and_evin_and_ezkiel_stay_commented()
	local text = readFile(H.SCRIPTS .. V.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/vortex_squadron/vrovel_convo%.lua"%)'), 1, "space_conversations.lua: vrovel_convo include occurrences (commented or not)")
	lu.assertEquals(lines[95], 'includeFile("conversations/space/rebel/vortex_squadron/vrovel_convo.lua")', "space_conversations.lua line 95")
	lu.assertEquals(lines[91], "-- Vortex Squadron", "space_conversations.lua line 91")
	lu.assertEquals(lines[92], 'includeFile("conversations/space/rebel/vortex_squadron/evin_convo.lua")', "space_conversations.lua line 92: uncommented by vortex-tier4-extok-evin-convo")
	lu.assertEquals(lines[93], 'includeFile("conversations/space/rebel/vortex_squadron/ezkiel_convo.lua")', "space_conversations.lua line 93 (Ezkiel: uncommented by vortex-tier3-ezkiel)")
	lu.assertEquals(lines[94], 'includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")', "space_conversations.lua line 94")
	lu.assertEquals(lines[96], 'includeFile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua")', "space_conversations.lua line 96")
end

-- AC-1, Content contract 1: the handler include sits uncommented at line 144; Evin and Ezkiel stay commented
function TestVrovelWiring:test_the_handler_include_is_uncommented_once_at_line_144_and_evin_and_ezkiel_stay_commented()
	local text = readFile(H.SCRIPTS .. V.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/vortex_squadron/vrovelConvoHandler%.lua"%)'), 1, "screenplays.lua: vrovelConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[144], 'includeFile("space/conversations/rebel/vortex_squadron/vrovelConvoHandler.lua")', "screenplays.lua line 144")
	lu.assertEquals(lines[139], 'includeFile("space/squadrons/VortexSquadronScreenplay.lua")', "screenplays.lua line 139 (the squadron include loads first)")
	lu.assertEquals(lines[141], 'includeFile("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua")', "screenplays.lua line 141: uncommented by vortex-tier4-extok-evin-convo")
	lu.assertEquals(lines[142], 'includeFile("space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua")', "screenplays.lua line 142 (Ezkiel: uncommented by vortex-tier3-ezkiel)")
	lu.assertEquals(lines[143], 'includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")', "screenplays.lua line 143")
	lu.assertEquals(lines[145], 'includeFile("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua")', "screenplays.lua line 145")
end

-- AC-1: Part B adds no status key and does not touch the squadron object's flag key
function TestVrovelWiring:test_the_squadron_object_keeps_the_vortex_pilot_key()
	lu.assertEquals(V.squadron().VORTEX_PILOT_KEY, "VortexSquadronScreenplay:vortexPilot", "VORTEX_PILOT_KEY is untouched")
end
