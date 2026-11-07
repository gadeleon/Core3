-- Brother Extok Evin: wiring, the NPC and the spawn (AC-1).
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (AC-1; Content contract 2 (handler fields) and 3; Source inventory 1; finding 4; D-12).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable (every other field
-- unchanged), the two include lines sit at lines 92 and 141 uncommented (once each, no other line moved), the spawn is the line that was at the base, and it is where SWG's
-- spawner puts him. The oracle for the spawn is the SWG-Source payloads in fixtures/space_content/npc_spawners.vortex_tier4_evin.tab and
-- fixtures/buildout/talus/talus_5_3_ws.vortex_tier4_evin.tab (byte copies of rows 1-2/82 and 1-2/201/210/212 of the SWG files), never the Core3 files under test.

local lu = require("luaunit")
local H = require("harness")
local E = require("vortex_tier4_data")

E.loadConversation()

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

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- tab rows of a fixture: list of { cells... } (CRLF kept out)
local function tabRows(path)
	local text = readFile(path)

	lu.assertNotNil(text, path .. ": missing fixture")

	local rows = {}

	for _, line in ipairs(linesOf(text)) do
		if line ~= "" then
			local cells = {}

			for cell in (line .. "\t"):gmatch("([^\t]*)\t") do
				cells[#cells + 1] = cell
			end

			rows[#rows + 1] = cells
		end
	end

	return rows
end

-- a table given as a list or as a set: its sorted entries
local function entries(t)
	local out = {}

	for k, v in pairs(t) do
		out[#out + 1] = type(k) == "number" and v or k
	end

	table.sort(out)
	return out
end

local NPCS = H.FIXTURES .. "space_content/npc_spawners.vortex_tier4_evin.tab"
local GBT = H.FIXTURES .. "buildout/talus/talus_5_3_ws.vortex_tier4_evin.tab"

TestEvinWiring = {}

function TestEvinWiring:setUp() H.reset() end

-- AC-1
function TestEvinWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	E.requireConversation(lu)

	local t = H.conversationTemplateTable(E.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, E.HANDLER, E.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", E.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", E.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, E.HANDLER)

	for _, name in ipairs({
		"getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "getQuestString", "hasStatus", "getPilotFlag", "hasMet", "tier4Count", "isWon", "isActive", "isFailed",
		"isPaid", "isDutyActive", "isOnMission", "isGrounded", "canFlyNonTrackDuty", "isReadyForTier4", "getOfferMission", "isReadyForTraining", "gateScreenId", "payMission",
		"raisePilotTier", "getLastScreenID",
	}) do
		lu.assertEquals(type(h[name]), "function", E.HANDLER .. ":" .. name)
	end
end

-- AC-1, Content contract 2: the first line of the handler says where it comes from
function TestEvinWiring:test_the_first_line_of_the_handler_names_its_source()
	E.requireConversation(lu)

	local first = readFile(H.SCRIPTS .. E.HANDLER_FILE):match("^([^\n]*)")

	lu.assertEquals(first, "-- Brother Extok Evin (Vortex Squadron tier 4) conversation handler; ported from SWG-Source naboo_rebel_tier4.java. One-click, free-choice training bought with XP, missions alternating with skills, the duties and the hand-off to Admiral Willham Burke: pre-NGE client lines (feature vortex-tier4-extok-evin-convo).", "line 1 of " .. E.HANDLER_FILE)
end

-- AC-1, Content contract 2: the handler's tables (the contract the display actions and the training grant read)
function TestEvinWiring:test_the_handler_carries_the_mission_duty_training_and_screen_tables_of_the_contract()
	E.requireConversation(lu)

	local h = rawget(_G, E.HANDLER)

	for n = 1, 4 do
		local m, want = h.MISSIONS[n], E.MISSIONS[n]

		lu.assertNotNil(m, E.HANDLER .. ".MISSIONS[" .. n .. "]")
		lu.assertEquals(m.head, want.head, "MISSIONS[" .. n .. "].head")
		lu.assertEquals(m.questString, want.questString, "MISSIONS[" .. n .. "].questString")
		lu.assertEquals(m.wins, want.wins, "MISSIONS[" .. n .. "].wins (the two first-level children, J4:116-175)")
		lu.assertEquals(m.standing, 150, "MISSIONS[" .. n .. "].standing")
	end

	for screen, d in pairs(E.DUTY_SCREENS) do
		local got = h.DUTY_SCREENS[screen]

		lu.assertNotNil(got, E.HANDLER .. ".DUTY_SCREENS." .. screen)
		lu.assertEquals({ got.global or got[1], got.questString or got[2] }, { d.global, d.questString }, "DUTY_SCREENS." .. screen .. " (global, quest string)")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, "TRAIN_CHOICES entries")

	for i, t in ipairs(E.TRAIN) do
		local c = h.TRAIN_CHOICES[i]
		local flat = { c.skill or c[1], c.reply or c[2], c.screen or c.trained or c[3] }

		lu.assertEquals(flat, { t.skill, E.PREFIX .. t.reply, t.trained }, "TRAIN_CHOICES[" .. i .. "] (skill, topic reply, trained screen)")
	end

	lu.assertEquals(h.START_SCREENS, E.START_SCREENS, "START_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, E.REWARD_SCREENS, "REWARD_SCREENS")
	lu.assertEquals(h.MET_SCREEN, E.MET_SCREEN, "MET_SCREEN")
	lu.assertEquals(entries(h.TIER_SCREENS), entries(E.TIER_SCREENS), "TIER_SCREENS")

	local want = {}

	for i, id in ipairs(E.NAME_SCREENS) do
		want[i] = id
	end

	table.sort(want)
	lu.assertEquals(entries(h.NAME_SCREENS), want, "NAME_SCREENS")
end

-- AC-1: his mobile template names the conversation and gets Ezkiel's mask
function TestEvinWiring:test_evin_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/extok_evin.lua", "extok_evin")

	lu.assertNotNil(npc, "mobile/space/extok_evin.lua registers extok_evin")
	lu.assertEquals(npc.conversationTemplate, "evin_convo_template", "extok_evin: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "extok_evin: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "extok_evin: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "extok_evin: optionsBitmask (J4 OnInitialize/OnAttach: conversable, invulnerable)")
end

-- AC-1: only the two fields change; every other field stays
function TestEvinWiring:test_evin_keeps_every_other_field()
	local t = H.loadCreatureTemplate("space/extok_evin.lua", "extok_evin")

	lu.assertNotNil(t, "mobile/space/extok_evin.lua registers extok_evin")

	local expected = {
		objectName = "@npc_spawner_n:extok_evin", socialGroup = "rebel", faction = "rebel", mobType = MOB_NPC, level = 100, chanceHit = 1, damageMin = 645, damageMax = 1000,
		baseXp = 9429, baseHAM = 24000, baseHAMmax = 30000, armor = 0, resists = { 0, 0, 0, 0, 0, 0, 0, 0, -1 }, meatType = "", meatAmount = 0, hideType = "", hideAmount = 0,
		boneType = "", boneAmount = 0, milk = 0, tamingChance = 0, ferocity = 0, pvpBitmask = NONE, creatureBitmask = PACK, diet = HERBIVORE,
		templates = { "object/mobile/space_rebel_tier4_extok_evin.iff" }, lootGroups = {}, primaryWeapon = "unarmed", secondaryWeapon = "none", primaryAttacks = {}, secondaryAttacks = {},
		optionsBitmask = t.optionsBitmask, conversationTemplate = t.conversationTemplate,
	}

	local got = {}

	for k, v in pairs(t) do
		got[k] = v
	end

	lu.assertEquals(got, expected, "extok_evin: template fields other than optionsBitmask and conversationTemplate")
end

-- AC-1, Content contract 3: the template include sits uncommented once at line 92 (Ezkiel's follows at 93); no line moved
function TestEvinWiring:test_the_template_include_is_uncommented_once_at_line_92_and_no_other_line_moved()
	local text = readFile(H.SCRIPTS .. E.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/vortex_squadron/evin_convo%.lua"%)'), 1, "space_conversations.lua: evin_convo include occurrences (commented or not)")
	lu.assertEquals(countMatches(text, '%-%-%s*includeFile%("conversations/space/rebel/vortex_squadron/evin_convo%.lua"%)'), 0, "space_conversations.lua: commented evin_convo include")
	lu.assertEquals(lines[92], E.TEMPLATE_INCLUDE, "space_conversations.lua line 92")
	lu.assertEquals(lines[91], "-- Vortex Squadron", "space_conversations.lua line 91")
	lu.assertEquals(lines[93], 'includeFile("conversations/space/rebel/vortex_squadron/ezkiel_convo.lua")', "space_conversations.lua line 93")
	lu.assertEquals(lines[94], 'includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")', "space_conversations.lua line 94")
	lu.assertEquals(lines[95], 'includeFile("conversations/space/rebel/vortex_squadron/vrovel_convo.lua")', "space_conversations.lua line 95")
	lu.assertEquals(lines[96], 'includeFile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua")', "space_conversations.lua line 96")
end

-- AC-1, Content contract 3: the handler include sits uncommented once at line 141; the squadron include loads first (line 139)
function TestEvinWiring:test_the_handler_include_is_uncommented_once_at_line_141_after_the_squadron_include()
	local text = readFile(H.SCRIPTS .. E.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/vortex_squadron/evinConvoHandler%.lua"%)'), 1, "screenplays.lua: evinConvoHandler include occurrences (commented or not)")
	lu.assertEquals(countMatches(text, '%-%-%s*includeFile%("space/conversations/rebel/vortex_squadron/evinConvoHandler%.lua"%)'), 0, "screenplays.lua: commented evinConvoHandler include")
	lu.assertEquals(lines[141], E.HANDLER_INCLUDE, "screenplays.lua line 141")
	lu.assertEquals(lines[139], 'includeFile("space/squadrons/VortexSquadronScreenplay.lua")', "screenplays.lua line 139 (the squadron include loads first)")
	lu.assertEquals(lines[138], "-- Vortex Squadron", "screenplays.lua line 138")
	lu.assertEquals(lines[142], 'includeFile("space/conversations/rebel/vortex_squadron/ezkielConvoHandler.lua")', "screenplays.lua line 142")
	lu.assertEquals(lines[143], 'includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")', "screenplays.lua line 143")
	lu.assertEquals(lines[144], 'includeFile("space/conversations/rebel/vortex_squadron/vrovelConvoHandler.lua")', "screenplays.lua line 144")
	lu.assertEquals(lines[145], 'includeFile("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua")', "screenplays.lua line 145")
end

-- AC-1: the include lines name files that exist
function TestEvinWiring:test_the_template_and_handler_files_are_the_ones_the_includes_name()
	for _, path in ipairs({ E.TEMPLATE_FILE, E.HANDLER_FILE }) do
		local f = io.open(H.SCRIPTS .. path, "r")

		lu.assertNotNil(f, path .. " exists under bin/scripts (the include lines name it)")

		if f then
			f:close()
		end
	end
end

-- AC-1: Part B adds no key and does not touch the squadron object's flag key or met key
function TestEvinWiring:test_the_squadron_object_keeps_the_vortex_pilot_key_and_the_met_key()
	lu.assertEquals(E.squadron().VORTEX_PILOT_KEY, "VortexSquadronScreenplay:vortexPilot", "VORTEX_PILOT_KEY is untouched")
	lu.assertEquals(E.squadron().TIER4_MET_KEY, "VortexSquadronScreenplay:metTier4", "TIER4_MET_KEY is Part A's")
end

-- AC-1, D-12: the spawn is the line that was at the base
function TestEvinWiring:test_the_spawn_line_is_unchanged()
	local lines = linesOf(readFile(H.SCRIPTS .. E.SPAWN_FILE))

	lu.assertEquals(trim(lines[179] or ""), '{"extok_evin", 1, -24.0, 2.1, 73.8, 85, 3175573, "neutral"},', "talus_dearic.lua:179")
	lu.assertEquals(countMatches(table.concat(lines, "\n"), '"extok_evin"'), 1, "talus_dearic.lua: one Evin spawn")
end

-- AC-1, finding 4: the spawn is what SWG's spawner says (NPCS row 82 + GBT rows 212, 210, 201): the same cell, within 1.0 m
function TestEvinWiring:test_the_spawn_matches_the_swg_spawner_of_the_fixture_excerpts()
	local npcs = tabRows(NPCS)
	local gbt = tabRows(GBT)

	lu.assertEquals(npcs[1][3], "sidName", "npc_spawners excerpt: header")
	lu.assertEquals(#npcs, 3, "npc_spawners excerpt: two header rows and the Evin row")

	local spawner = npcs[3]

	lu.assertEquals(spawner[1], "2195677", "NPCS row 82: strObjId")
	lu.assertEquals(spawner[3], "extok_evin", "NPCS row 82: sidName (the template name of the spawn)")
	lu.assertEquals(spawner[5], "object/mobile/space_rebel_tier4_extok_evin.iff", "NPCS row 82: strTemplate (Core3 extok_evin.lua template)")
	lu.assertEquals(spawner[6], "conversation.naboo_rebel_tier4", "NPCS row 82: strScript1 (the conversation file the template's strings come from)")

	local byId = {}

	for i = 3, #gbt do
		byId[gbt[i][1]] = gbt[i]
	end

	-- GBT: 3175564 the theater, 3175573 its cell index 9, 2195677 the spawner in cell 3175573
	local building, cell, spawn = byId["3175564"], byId["3175573"], byId["2195677"]

	lu.assertNotNil(building, "GBT row 201: the building 3175564")
	lu.assertNotNil(cell, "GBT row 210: the cell 3175573")
	lu.assertNotNil(spawn, "GBT row 212: the spawner 2195677")
	lu.assertEquals(building[3], "object/building/corellia/guild_theater_corellia_s01.iff", "GBT row 201: server_template_crc")
	lu.assertEquals(cell[2], "3175564", "GBT row 210: the cell belongs to building 3175564")
	lu.assertEquals(cell[4], "9", "GBT row 210: cell_index")
	lu.assertEquals(spawn[3], "object/tangible/space/content_infrastructure/ground_npc_spawner.iff", "GBT row 212: server_template_crc")
	lu.assertEquals(spawn[2], "3175573", "GBT row 212: the spawner's container is the cell")

	local x, z, y, heading, cellId = readFile(H.SCRIPTS .. E.SPAWN_FILE):match('{"extok_evin",%s*1,%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*(%d+),')

	lu.assertNotNil(cellId, "talus_dearic.lua: could not parse the Evin spawn row")
	lu.assertEquals(cellId, spawn[2], "spawn: cell = GBT container")

	local px, py, pz = tonumber(spawn[5]), tonumber(spawn[6]), tonumber(spawn[7])
	local dx, dz, dy = tonumber(x) - px, tonumber(z) - py, tonumber(y) - pz
	local distance = math.sqrt(dx * dx + dz * dz + dy * dy)

	lu.assertTrue(distance <= 1.0, "spawn: within 1.0 m of GBT row 212 (" .. px .. ", " .. py .. ", " .. pz .. "), got " .. distance)
	lu.assertEquals(tonumber(heading), 85, "spawn: heading unchanged (D-12)")
end

-- AC-1: the template's string file is the spawner's conversation script
function TestEvinWiring:test_the_spawner_script_names_the_string_file_the_template_uses()
	local npcs = tabRows(NPCS)
	local script = npcs[3][6]:gsub("^conversation%.", "conversation/")

	lu.assertEquals(E.PREFIX, "@" .. script .. ":", "NPCS row 82 strScript1 vs the template's leftDialog prefix")
end
