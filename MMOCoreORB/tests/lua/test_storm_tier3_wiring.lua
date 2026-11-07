-- Storm tier 3 part B (Captain Denner's conversation): wiring and spawn.
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-1; Content contract 3; Source inventory 1; Q-1 = A; D-13).
--
-- The oracle is the SWG-Source payloads in fixtures/space_content/npc_spawners.storm_tier3_denner.tab and
-- fixtures/buildout/yavin4/yavin4_6_1_ws.storm_tier3_denner.tab (byte copies of rows 1-2/75 and 1-2/93/99/101 of the SWG files), never the Core3 files under test.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")

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

local NPCS = H.FIXTURES .. "space_content/npc_spawners.storm_tier3_denner.tab"
local GBY = H.FIXTURES .. "buildout/yavin4/yavin4_6_1_ws.storm_tier3_denner.tab"

TestStormT3Wiring = {}

function TestStormT3Wiring:setUp() H.reset() end

-- B-1
function TestStormT3Wiring:test_denner_convo_template_is_registered_with_its_handler_class_and_the_handler_global_exists()
	D.requireConversation(lu)

	local t = H.conversationTemplateTable(D.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, D.HANDLER, D.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", D.TEMPLATE .. ": templateType")
	lu.assertNotNil(rawget(_G, D.HANDLER), D.HANDLER .. " is defined after the handler file loads")
end

-- B-1
function TestStormT3Wiring:test_denner_is_conversable_invulnerable_and_attaches_the_template()
	local t = H.loadCreatureTemplate("space/denner.lua", "denner")

	lu.assertNotNil(t, "mobile/space/denner.lua registers denner")
	lu.assertEquals(t.conversationTemplate, D.TEMPLATE, "denner: conversationTemplate")
	lu.assertEquals(t.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "denner: optionsBitmask (J3:7684-7701; Alozen's and Vrke's mask)")
end

-- B-1: only those two fields differ from the template as it was at the base (540161018f)
function TestStormT3Wiring:test_denner_changes_nothing_but_the_options_and_the_conversation()
	local t = H.loadCreatureTemplate("space/denner.lua", "denner")

	lu.assertNotNil(t, "mobile/space/denner.lua registers denner")

	local expected = {
		objectName = "@npc_spawner_n:denner", socialGroup = "imperial", faction = "imperial", mobType = MOB_NPC,
		planetMapCategory = "trainer", planetMapSubCategory = "trainer_pilot_imperial", level = 100, chanceHit = 1,
		damageMin = 645, damageMax = 1000, baseXp = 9429, baseHAM = 24000, baseHAMmax = 30000, armor = 0,
		resists = { 0, 0, 0, 0, 0, 0, 0, 0, -1 }, meatType = "", meatAmount = 0, hideType = "", hideAmount = 0,
		boneType = "", boneAmount = 0, milk = 0, tamingChance = 0, ferocity = 0, pvpBitmask = NONE, creatureBitmask = PACK,
		diet = HERBIVORE, templates = { "object/mobile/space_imperial_tier3_yavin.iff" }, lootGroups = {},
		primaryWeapon = "unarmed", secondaryWeapon = "none", primaryAttacks = {}, secondaryAttacks = {},
		optionsBitmask = t.optionsBitmask, conversationTemplate = t.conversationTemplate,
	}

	local got = {}

	for k, v in pairs(t) do
		got[k] = v
	end

	lu.assertEquals(got, expected, "denner: template fields other than optionsBitmask and conversationTemplate")
end

-- B-1: the template include is uncommented exactly once and is the last line, directly after Alozen's
function TestStormT3Wiring:test_the_template_include_is_uncommented_exactly_once_as_the_last_line_directly_after_alozens()
	local text = readFile(H.SCRIPTS .. D.CONVOS_FILE)

	lu.assertNotNil(text, D.CONVOS_FILE)

	local line = escape(D.TEMPLATE_INCLUDE)

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "space_conversations.lua: uncommented denner_convo include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "space_conversations.lua: commented denner_convo include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("conversations/space/imperial/storm_squadron/alozen_convo.lua")')

	lu.assertNotNil(at, "space_conversations.lua: Alozen's include")
	lu.assertEquals(trim(lines[at + 1] or ""), D.TEMPLATE_INCLUDE, "space_conversations.lua: Denner's include directly after Alozen's")

	local last = #lines

	while last > 1 and trim(lines[last]) == "" do
		last = last - 1
	end

	-- storm-tier4-kilnstrider: Kilnstrider's include follows Denner's and is the last line now
	lu.assertEquals(trim(lines[at + 2] or ""), 'includeFile("conversations/space/imperial/storm_squadron/kilnstrider_convo.lua")', "space_conversations.lua: Kilnstrider's include directly after Denner's (storm-tier4-kilnstrider)")
	lu.assertEquals(last, at + 2, "space_conversations.lua: Kilnstrider's include follows Denner's and is the last line (storm-tier4-kilnstrider)")
end

-- B-1: the handler include directly follows Alozen's, then a blank line, then the Master Trainers block
function TestStormT3Wiring:test_the_handler_include_follows_alozens_exactly_once_then_a_blank_line_and_the_master_trainers_block()
	local text = readFile(H.SCRIPTS .. D.SCREENPLAYS_FILE)

	lu.assertNotNil(text, D.SCREENPLAYS_FILE)

	local line = escape(D.HANDLER_INCLUDE)

	lu.assertEquals(countMatches(text, "\n%s*" .. line), 1, "screenplays.lua: uncommented dennerConvoHandler include")
	lu.assertEquals(countMatches(text, "%-%-%s*" .. line), 0, "screenplays.lua: commented dennerConvoHandler include")

	local lines = linesOf(text)
	local at = indexOf(lines, 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")')

	lu.assertNotNil(at, "screenplays.lua: Alozen's handler include")
	lu.assertEquals(lines[at + 1], D.HANDLER_INCLUDE, "screenplays.lua: Denner's handler include, directly after Alozen's")
	-- storm-tier4-kilnstrider: Kilnstrider's handler include follows Denner's, so the blank line and the Master Trainers block move down by one
	lu.assertEquals(lines[at + 2], 'includeFile("space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua")', "screenplays.lua: Kilnstrider's handler include follows Denner's (storm-tier4-kilnstrider)")
	lu.assertEquals(lines[at + 3], "", "screenplays.lua: the blank line follows Kilnstrider's include (storm-tier4-kilnstrider)")
	lu.assertEquals(lines[at + 4], "-- Master Trainers", "screenplays.lua: the Master Trainers block follows")
end

-- B-1: YB:1-33 unchanged but for the comma on :33; :34 is Denner's row; the table closes after it
function TestStormT3Wiring:test_the_spawn_table_gains_dennerss_row_after_barlows_which_gets_a_comma()
	local lines = linesOf(readFile(H.SCRIPTS .. D.SPAWN_FILE))

	lu.assertEquals(lines[32], '\t\t{"alozen", 300, 0.003, 0.125, -5.558, 0, 8735518, "npc_imperial"},', "yavin4_imperial_base.lua:32 (Alozen, unchanged)")
	lu.assertEquals(lines[33], D.BARLOW_ROW, "yavin4_imperial_base.lua:33 (Barlow's row, unchanged but for the comma)")
	lu.assertEquals(lines[34], D.SPAWN_ROW, "yavin4_imperial_base.lua:34 (Denner's row)")
	lu.assertEquals(lines[35], "\t}", "yavin4_imperial_base.lua:35 (the table closes after Denner's row)")
	lu.assertEquals(countMatches(table.concat(lines, "\n"), '{"denner"'), 1, "yavin4_imperial_base.lua: one Denner row")
end

-- B-1, Q-1 = A: the row is what SWG's spawner says (NPCS row 75 + GBY rows 99, 101, 93)
function TestStormT3Wiring:test_the_spawn_row_equals_the_swg_spawner_of_the_fixture_excerpts()
	local npcs = tabRows(NPCS)
	local gby = tabRows(GBY)

	-- NPCS rows 1-2 are the headers, row 3 of the excerpt is NPCS row 75
	lu.assertEquals(npcs[1][3], "sidName", "npc_spawners excerpt: header")
	lu.assertEquals(#npcs, 3, "npc_spawners excerpt: two header rows and the Denner row")

	local spawner = npcs[3]

	lu.assertEquals(spawner[1], "1491025", "NPCS row 75: strObjId")
	lu.assertEquals(spawner[3], "denner", "NPCS row 75: sidName (the template name of the spawn row)")
	lu.assertEquals(spawner[5], "object/mobile/space_imperial_tier3_yavin.iff", "NPCS row 75: strTemplate (Core3 denner.lua template)")
	lu.assertEquals(spawner[6], "conversation.tatooine_imperial_tier3", "NPCS row 75: strScript1 (the conversation file the template's strings come from)")

	local byId = {}

	for i = 3, #gby do
		byId[gby[i][1]] = gby[i]
	end

	-- GBY: 8735515 building, 8735521 its cell index 6, 1491025 the spawner in cell 8735521
	local building, cell, spawn = byId["8735515"], byId["8735521"], byId["1491025"]

	lu.assertNotNil(building, "GBY row 93: the building 8735515")
	lu.assertNotNil(cell, "GBY row 99: the cell 8735521")
	lu.assertNotNil(spawn, "GBY row 101: the spawner 1491025")
	lu.assertEquals(building[3], "object/building/military/military_base_shed_imperial_style_cantina_s01.iff", "GBY row 93: server_template_crc")
	lu.assertEquals(cell[3], "object/cell/cell.iff", "GBY row 99: server_template_crc")
	lu.assertEquals(cell[2], "8735515", "GBY row 99: the cell belongs to building 8735515")
	lu.assertEquals(cell[4], "6", "GBY row 99: cell_index")
	lu.assertEquals(spawn[3], "object/tangible/space/content_infrastructure/ground_npc_spawner.iff", "GBY row 101: server_template_crc")

	local container = spawn[2]
	local px, py, pz = tonumber(spawn[5]), tonumber(spawn[6]), tonumber(spawn[7])
	local qw, qy = tonumber(spawn[8]), tonumber(spawn[10])
	local heading = math.floor(2 * math.deg(math.atan(qy, qw)) + 0.5)

	lu.assertEquals(heading, 90, "GBY row 101: yaw = round(2*atan2(qy, qw)) in degrees")

	-- the Core3 row
	local row = readFile(H.SCRIPTS .. D.SPAWN_FILE):match('(\t\t{"denner",[^\n]*})')

	lu.assertNotNil(row, "yavin4_imperial_base.lua: Denner's row")

	local name, respawn, x, z, y, h, cellId, mood = row:match('{"([^"]+)",%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*(%d+),%s*"([^"]*)"}')

	lu.assertEquals(name, spawner[3], "spawn row: template name = NPCS sidName")
	lu.assertEquals(tonumber(respawn), 300, "spawn row: respawn (Haymir's and Alozen's value)")
	lu.assertEquals({ tonumber(x), tonumber(z), tonumber(y) }, { px, py, pz }, "spawn row: x, z, y = GBY px, py, pz")
	lu.assertEquals(tonumber(h), heading, "spawn row: heading")
	lu.assertEquals(cellId, container, "spawn row: cell = GBY container")
	lu.assertEquals(mood, "", "spawn row: no mood (D-13: SWG sets none for Denner)")
end

-- B-1: the template's string file is the spawner's conversation script
function TestStormT3Wiring:test_the_spawner_script_names_the_string_file_the_template_uses()
	local npcs = tabRows(NPCS)
	local script = npcs[3][6]:gsub("^conversation%.", "conversation/")

	lu.assertEquals(D.PREFIX, "@" .. script .. ":", "NPCS row 75 strScript1 vs the template's leftDialog prefix")
end
