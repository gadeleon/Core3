-- Brother Ezkiel: wiring (AC-1).
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-1; Content contract 2 (handler fields) and 3; Source inventory 1; I-8).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable, the two
-- include lines sit at lines 93 and 142 uncommented (once each) while Evin stays commented, and the handler has the helpers and tables the spec names.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")

W.loadConversation()

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

TestEzkielWiring = {}

function TestEzkielWiring:setUp() H.reset() end

-- AC-1
function TestEzkielWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	W.requireConversation(lu)

	local t = H.conversationTemplateTable(W.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, W.HANDLER, W.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", W.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", W.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, W.HANDLER)

	for _, name in ipairs({
		"getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isPaid", "isOnMission", "getPilotFlag", "isReadyForTier3",
		"isReadyForTier4", "getRewardMission", "raisePilotTier",
	}) do
		lu.assertEquals(type(h[name]), "function", W.HANDLER .. ":" .. name)
	end
end

-- AC-1, Content contract 2: the handler's tables (the contract the display actions and the training grant read)
function TestEzkielWiring:test_the_handler_carries_the_mission_training_and_screen_tables_of_the_contract()
	W.requireConversation(lu)

	local h = rawget(_G, W.HANDLER)

	for n = 1, 4 do
		local m = h.MISSIONS[n]

		lu.assertNotNil(m, W.HANDLER .. ".MISSIONS[" .. n .. "]")
		lu.assertEquals(m.head, W.HEADS[n], "MISSIONS[" .. n .. "].head")
		lu.assertEquals(m.endString, W.MISSIONS[n].endString, "MISSIONS[" .. n .. "].endString")
		lu.assertEquals(m.standing, 100, "MISSIONS[" .. n .. "].standing")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, "TRAIN_CHOICES entries")

	for i, t in ipairs(W.TRAIN) do
		local c = h.TRAIN_CHOICES[i]
		local flat = { c.skill or c[1], c.reply or c[2], c.screen or c.trained or c[3] }

		lu.assertEquals(flat, { t.skill, W.PREFIX .. t.reply, t.trained }, "TRAIN_CHOICES[" .. i .. "] (skill, topic reply, trained screen)")
	end

	lu.assertEquals(h.START_SCREENS, W.START_SCREENS, "START_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, W.REWARD_SCREENS, "REWARD_SCREENS")

	local names = {}

	for id in pairs(h.NAME_SCREENS) do
		names[#names + 1] = type(id) == "number" and h.NAME_SCREENS[id] or id
	end

	local want = {}

	for i, id in ipairs(W.NAME_SCREENS) do
		want[i] = id
	end

	table.sort(names)
	table.sort(want)
	lu.assertEquals(names, want, "NAME_SCREENS")
end

-- AC-1: his mobile template names the conversation and gets the Vrovel mask
function TestEzkielWiring:test_ezkiel_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/ezkiel.lua", "ezkiel")

	lu.assertNotNil(npc, "mobile/space/ezkiel.lua registers ezkiel")
	lu.assertEquals(npc.conversationTemplate, "ezkiel_convo_template", "ezkiel: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "ezkiel: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "ezkiel: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "ezkiel: optionsBitmask (Vrovel's mask)")
end

-- AC-1: only the two fields change; his identity stays
function TestEzkielWiring:test_ezkiel_keeps_his_identity_fields()
	local npc = H.loadCreatureTemplate("space/ezkiel.lua", "ezkiel")

	lu.assertNotNil(npc, "mobile/space/ezkiel.lua registers ezkiel")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:ezkiel", "ezkiel: objectName")
	lu.assertEquals(npc.faction, "rebel", "ezkiel: faction")
	lu.assertEquals(npc.socialGroup, "rebel", "ezkiel: socialGroup")
	lu.assertEquals(npc.pvpBitmask, NONE, "ezkiel: pvpBitmask")
	lu.assertEquals(npc.templates, { "object/mobile/space_rebel_tier3_ezkiel.iff" }, "ezkiel: templates")
	lu.assertEquals(npc.level, 100, "ezkiel: level")
end

-- AC-1, Content contract 3: the template include sits uncommented once at line 93; Evin stays commented; the lines around keep their places
function TestEzkielWiring:test_the_template_include_is_uncommented_once_at_line_93_and_evin_stays_commented()
	local text = readFile(H.SCRIPTS .. W.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/vortex_squadron/ezkiel_convo%.lua"%)'), 1, "space_conversations.lua: ezkiel_convo include occurrences (commented or not)")
	lu.assertEquals(lines[93], W.TEMPLATE_INCLUDE, "space_conversations.lua line 93")
	lu.assertEquals(lines[91], "-- Vortex Squadron", "space_conversations.lua line 91")
	lu.assertEquals(lines[92], '--includeFile("conversations/space/rebel/vortex_squadron/evin_convo.lua")', "space_conversations.lua line 92 (Evin stays commented)")
	lu.assertEquals(lines[94], 'includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")', "space_conversations.lua line 94")
	lu.assertEquals(lines[95], 'includeFile("conversations/space/rebel/vortex_squadron/vrovel_convo.lua")', "space_conversations.lua line 95")
	lu.assertEquals(lines[96], 'includeFile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua")', "space_conversations.lua line 96")
end

-- AC-1, Content contract 3: the handler include sits uncommented once at line 142; Evin stays commented; the squadron include loads first
function TestEzkielWiring:test_the_handler_include_is_uncommented_once_at_line_142_and_evin_stays_commented()
	local text = readFile(H.SCRIPTS .. W.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/vortex_squadron/ezkielConvoHandler%.lua"%)'), 1, "screenplays.lua: ezkielConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[142], W.HANDLER_INCLUDE, "screenplays.lua line 142")
	lu.assertEquals(lines[139], 'includeFile("space/squadrons/VortexSquadronScreenplay.lua")', "screenplays.lua line 139 (the squadron include loads first)")
	lu.assertEquals(lines[141], '--includeFile("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua")', "screenplays.lua line 141 (Evin stays commented)")
	lu.assertEquals(lines[143], 'includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")', "screenplays.lua line 143")
	lu.assertEquals(lines[144], 'includeFile("space/conversations/rebel/vortex_squadron/vrovelConvoHandler.lua")', "screenplays.lua line 144")
	lu.assertEquals(lines[145], 'includeFile("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua")', "screenplays.lua line 145")
end

-- AC-1: Part B adds no key and does not touch the squadron object's flag key
function TestEzkielWiring:test_the_squadron_object_keeps_the_vortex_pilot_key()
	lu.assertEquals(W.squadron().VORTEX_PILOT_KEY, "VortexSquadronScreenplay:vortexPilot", "VORTEX_PILOT_KEY is untouched")
end

-- AC-1: the two files are the server's: the handler file defines the global the template names, the template file registers the template (loaded by their own files)
function TestEzkielWiring:test_the_template_and_handler_files_are_the_ones_the_includes_name()
	for _, path in ipairs({ W.TEMPLATE_FILE, W.HANDLER_FILE }) do
		local f = io.open(H.SCRIPTS .. path, "r")

		lu.assertNotNil(f, path .. " exists under bin/scripts (the include lines name it)")

		if f then
			f:close()
		end
	end
end
