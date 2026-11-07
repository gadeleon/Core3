-- Storm tier 4 part B (Admiral Kilnstrider's conversation): wiring, the NPC and the spawn.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-1; Content contract 2 (NPC) and 3; FK-8; Q-2 = A).
--
-- The oracle for the spawn is the SWG-Source payloads in fixtures/space_content/npc_spawners.storm_tier4_kilnstrider.tab and
-- fixtures/buildout/endor/endor_6_3_ws.storm_tier4_kilnstrider.tab (byte copies of rows 1-2/85 and 1-2/158/161/163 of the SWG files), never the Core3 files under test.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")

D.loadConversation()

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
		if (l:gsub("^%s+", "")) == wanted then
			return i
		end
	end
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

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

local NPCS = H.FIXTURES .. "space_content/npc_spawners.storm_tier4_kilnstrider.tab"
local GBE = H.FIXTURES .. "buildout/endor/endor_6_3_ws.storm_tier4_kilnstrider.tab"

TestStormT4Wiring = {}

function TestStormT4Wiring:setUp() H.reset() end

-- B-1
function TestStormT4Wiring:test_kilnstrider_convo_template_is_registered_with_its_handler_class_and_the_handler_global_exists()
	D.requireConversation(lu)

	local t = H.conversationTemplateTable(D.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, D.HANDLER, D.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", D.TEMPLATE .. ": templateType")
	lu.assertNotNil(rawget(_G, D.HANDLER), D.HANDLER .. " is defined after the handler file loads")
end

-- B-1
function TestStormT4Wiring:test_kilnstrider_is_conversable_invulnerable_and_attaches_the_template()
	local t = H.loadCreatureTemplate("space/kilnstrider.lua", "kilnstrider")

	lu.assertNotNil(t, "mobile/space/kilnstrider.lua registers kilnstrider")
	lu.assertEquals(t.conversationTemplate, D.TEMPLATE, "kilnstrider: conversationTemplate")
	lu.assertEquals(t.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "kilnstrider: optionsBitmask (J:3954-3976 OnInitialize/OnAttach)")
end

-- B-1: only those two fields differ from the template as it was at the base (288da0c8ea)
function TestStormT4Wiring:test_kilnstrider_changes_nothing_but_the_options_and_the_conversation()
	local t = H.loadCreatureTemplate("space/kilnstrider.lua", "kilnstrider")

	lu.assertNotNil(t, "mobile/space/kilnstrider.lua registers kilnstrider")

	local expected = {
		objectName = "@npc_spawner_n:kilnstrider", socialGroup = "imperial", faction = "imperial", mobType = MOB_NPC,
		level = 178, chanceHit = 12.25, damageMin = 1020, damageMax = 1750, baseXp = 16794, baseHAM = 200000, baseHAMmax = 200000, armor = 2,
		resists = { 75, 75, 90, 80, 45, 45, 100, 70, -1 }, meatType = "", meatAmount = 0, hideType = "", hideAmount = 0,
		boneType = "", boneAmount = 0, milk = 0, tamingChance = 0, ferocity = 0, pvpBitmask = NONE, creatureBitmask = PACK,
		diet = HERBIVORE, templates = { "object/mobile/space_imperial_tier4_tatooine_kilnstrider.iff" }, lootGroups = {},
		primaryWeapon = "unarmed", secondaryWeapon = "none", primaryAttacks = {}, secondaryAttacks = {},
		optionsBitmask = t.optionsBitmask, conversationTemplate = t.conversationTemplate,
	}

	local got = {}

	for k, v in pairs(t) do
		got[k] = v
	end

	lu.assertEquals(got, expected, "kilnstrider: template fields other than optionsBitmask and conversationTemplate")
end

-- B-1: the template include is uncommented exactly once and is the last line, directly after Denner's
function TestStormT4Wiring:test_the_template_include_is_uncommented_exactly_once_as_the_last_line_directly_after_denners()
	local text = readFile(H.SCRIPTS .. D.CONVOS_FILE)

	lu.assertNotNil(text, D.CONVOS_FILE)

	local line = escape(D.TEMPLATE_INCLUDE)

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented kilnstrider_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented kilnstrider_convo include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("conversations/space/imperial/storm_squadron/denner_convo.lua")')

	lu.assertNotNil(at, "space_conversations.lua: Denner's include")
	lu.assertEquals(trim(lines[at + 1] or ""), D.TEMPLATE_INCLUDE, "space_conversations.lua: Kilnstrider's include directly after Denner's")

	local last = #lines

	while last > 1 and trim(lines[last]) == "" do
		last = last - 1
	end

	lu.assertEquals(last, at + 1, "space_conversations.lua: Kilnstrider's include is the last line of the file")
end

-- B-1: the handler include directly follows Denner's, then a blank line, then the Master Trainers block
function TestStormT4Wiring:test_the_handler_include_follows_denners_exactly_once_then_a_blank_line_and_the_master_trainers_block()
	local text = readFile(H.SCRIPTS .. D.SCREENPLAYS_FILE)

	lu.assertNotNil(text, D.SCREENPLAYS_FILE)

	local line = escape(D.HANDLER_INCLUDE)

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented kilnstriderConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented kilnstriderConvoHandler include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")')

	lu.assertNotNil(at, "screenplays.lua: Denner's handler include")
	lu.assertEquals(lines[at + 1], D.HANDLER_INCLUDE, "screenplays.lua: Kilnstrider's handler include, directly after Denner's")
	lu.assertEquals(lines[at + 2], "", "screenplays.lua: the blank line follows Kilnstrider's include")
	lu.assertEquals(lines[at + 3], "-- Master Trainers", "screenplays.lua: the Master Trainers block follows")
end

-- B-1, Q-2 = A: the spawn is the line that was at the base
function TestStormT4Wiring:test_the_spawn_line_is_unchanged()
	local lines = linesOf(readFile(H.SCRIPTS .. D.SPAWN_FILE))

	lu.assertEquals(trim(lines[78] or ""), D.SPAWN_LINE, "endor_research_outpost.lua:78")
	lu.assertEquals(countMatches(table.concat(lines, "\n"), 'spawnMobile%("endor", "kilnstrider"'), 1, "endor_research_outpost.lua: one Kilnstrider spawn")
end

-- B-1, FK-8: the spawn is what SWG's spawner says (NPCS row 85 + GBE rows 163, 161, 158), within 0.5 m
function TestStormT4Wiring:test_the_spawn_matches_the_swg_spawner_of_the_fixture_excerpts()
	local npcs = tabRows(NPCS)
	local gbe = tabRows(GBE)

	lu.assertEquals(npcs[1][3], "sidName", "npc_spawners excerpt: header")
	lu.assertEquals(#npcs, 3, "npc_spawners excerpt: two header rows and the Kilnstrider row")

	local spawner = npcs[3]

	lu.assertEquals(spawner[1], "8466084", "NPCS row 85: strObjId")
	lu.assertEquals(spawner[3], "kilnstrider", "NPCS row 85: sidName (the template name of the spawn)")
	lu.assertEquals(spawner[5], "object/mobile/space_imperial_tier4_tatooine_kilnstrider.iff", "NPCS row 85: strTemplate (Core3 kilnstrider.lua template)")
	lu.assertEquals(spawner[6], "conversation.tatooine_imperial_tier4", "NPCS row 85: strScript1 (the conversation file the template's strings come from)")

	local byId = {}

	for i = 3, #gbe do
		byId[gbe[i][1]] = gbe[i]
	end

	-- GBE: 9925364 building, 9925367 its cell index 3, 8466084 the spawner in cell 9925367
	local building, cell, spawn = byId["9925364"], byId["9925367"], byId["8466084"]

	lu.assertNotNil(building, "GBE row 158: the building 9925364")
	lu.assertNotNil(cell, "GBE row 161: the cell 9925367")
	lu.assertNotNil(spawn, "GBE row 163: the spawner 8466084")
	lu.assertEquals(building[3], "object/building/corellia/ply_corl_house_m_s01_fp1.iff", "GBE row 158: server_template_crc")
	lu.assertEquals(cell[2], "9925364", "GBE row 161: the cell belongs to building 9925364")
	lu.assertEquals(cell[4], "3", "GBE row 161: cell_index")
	lu.assertEquals(spawn[3], "object/tangible/space/content_infrastructure/ground_npc_spawner.iff", "GBE row 163: server_template_crc")
	lu.assertEquals(spawn[2], "9925367", "GBE row 163: the spawner's container is the cell")

	local row = readFile(H.SCRIPTS .. D.SPAWN_FILE):match('spawnMobile%("endor", "kilnstrider",([^)]*)%)')

	lu.assertNotNil(row, "endor_research_outpost.lua: the Kilnstrider spawnMobile call")

	local respawn, x, z, y, heading, cellId = row:match("^%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*(%d+)%s*$")

	lu.assertNotNil(cellId, "endor_research_outpost.lua: could not parse '" .. tostring(row) .. "'")
	lu.assertEquals(cellId, spawn[2], "spawn: cell = GBE container")

	local px, py, pz = tonumber(spawn[5]), tonumber(spawn[6]), tonumber(spawn[7])
	local dx, dz, dy = tonumber(x) - px, tonumber(z) - py, tonumber(y) - pz
	local distance = math.sqrt(dx * dx + dz * dz + dy * dy)

	lu.assertTrue(distance <= 0.5, "spawn: within 0.5 m of GBE row 163 (" .. px .. ", " .. py .. ", " .. pz .. "), got " .. distance)
	lu.assertEquals(tonumber(respawn), 60, "spawn: respawn")
end

-- B-1: the template's string file is the spawner's conversation script
function TestStormT4Wiring:test_the_spawner_script_names_the_string_file_the_template_uses()
	local npcs = tabRows(NPCS)
	local script = npcs[3][6]:gsub("^conversation%.", "conversation/")

	lu.assertEquals(D.PREFIX, "@" .. script .. ":", "NPCS row 85 strScript1 vs the template's leftDialog prefix")
end
