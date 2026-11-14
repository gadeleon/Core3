-- General Ufwol: wiring, the NPC, the spawn and the three comment edits (AC-1).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-1; Content contract 2 (handler fields) and 3; Source inventory 1; finding 8; D-12, D-17).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable (every other field
-- unchanged), the two include lines sit at lines 82 and 127 uncommented (once each, no other line moved), the spawn is the line that was at the base, and it is where SWG's
-- spawner puts him. The oracle for the spawn is the SWG-Source payload in fixtures/buildout/rori/rori_6_1_ws.crimson_tier4_ufwol.tab (byte copy of rows 1-2, 100, 102, 103 of
-- the SWG file), never the Core3 files under test.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")

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

local RBO = H.FIXTURES .. "buildout/rori/rori_6_1_ws.crimson_tier4_ufwol.tab"

TestUfwolWiring = {}

function TestUfwolWiring:setUp() H.reset() end

-- AC-1
function TestUfwolWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
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
function TestUfwolWiring:test_the_first_line_of_the_handler_names_its_source()
	E.requireConversation(lu)

	local first = readFile(H.SCRIPTS .. E.HANDLER_FILE):match("^([^\n]*)")

	lu.assertEquals(first, "-- General Ufwol (Crimson Phoenix Squadron tier 4) conversation handler; ported from SWG-Source tatooine_rebel_tier4.java (JF). One-click, free-choice training bought with XP, missions alternating with skills, the duties and the hand-off to Admiral Willham Burke: pre-NGE client lines (feature crimson-phoenix-tier4-ufwol).", "line 1 of " .. E.HANDLER_FILE)
end

-- AC-1, Content contract 2: the handler's tables (the contract the display actions and the training grant read)
function TestUfwolWiring:test_the_handler_carries_the_mission_duty_training_and_screen_tables_of_the_contract()
	E.requireConversation(lu)

	local h = rawget(_G, E.HANDLER)

	for n = 1, 4 do
		local m, want = h.MISSIONS[n], E.MISSIONS[n]

		lu.assertNotNil(m, E.HANDLER .. ".MISSIONS[" .. n .. "]")
		lu.assertEquals(m.head, want.head, "MISSIONS[" .. n .. "].head")
		lu.assertEquals(m.questString, want.questString, "MISSIONS[" .. n .. "].questString")
		lu.assertEquals(m.wins, want.wins, "MISSIONS[" .. n .. "].wins (JF:120-179: mission 1 wins through 1_a or 1_c, the others through their two first-level children)")
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

-- AC-1: his mobile template names the conversation and gets Ulvaw'op's mask
function TestUfwolWiring:test_ufwol_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/ufwol.lua", "ufwol")

	lu.assertNotNil(npc, "mobile/space/ufwol.lua registers ufwol")
	lu.assertEquals(npc.conversationTemplate, "ufwol_convo_template", "ufwol: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "ufwol: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "ufwol: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "ufwol: optionsBitmask (JF OnInitialize/OnAttach: conversable, invulnerable)")
end

-- AC-1: only the two fields change; every other field stays
function TestUfwolWiring:test_ufwol_keeps_every_other_field()
	local t = H.loadCreatureTemplate("space/ufwol.lua", "ufwol")

	lu.assertNotNil(t, "mobile/space/ufwol.lua registers ufwol")

	local expected = {
		objectName = "@npc_spawner_n:ufwol", socialGroup = "rebel", faction = "rebel", mobType = MOB_NPC, level = 100, chanceHit = 1, damageMin = 645, damageMax = 1000,
		baseXp = 9429, baseHAM = 24000, baseHAMmax = 30000, armor = 0, resists = { 0, 0, 0, 0, 0, 0, 0, 0, -1 }, meatType = "", meatAmount = 0, hideType = "", hideAmount = 0,
		boneType = "", boneAmount = 0, milk = 0, tamingChance = 0, ferocity = 0, pvpBitmask = NONE, creatureBitmask = PACK, diet = HERBIVORE,
		templates = { "object/mobile/space_rebel_tier4_ufwol.iff" }, lootGroups = {}, primaryWeapon = "unarmed", secondaryWeapon = "none", primaryAttacks = {}, secondaryAttacks = {},
		optionsBitmask = t.optionsBitmask, conversationTemplate = t.conversationTemplate,
	}

	local got = {}

	for k, v in pairs(t) do
		got[k] = v
	end

	lu.assertEquals(got, expected, "ufwol: template fields other than optionsBitmask and conversationTemplate")
end

-- AC-1, Content contract 3: the template include sits uncommented once at line 83 (the last Crimson Phoenix line); no line moved
function TestUfwolWiring:test_the_template_include_is_uncommented_once_at_line_83_and_no_other_line_moved()
	local text = readFile(H.SCRIPTS .. E.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo%.lua"%)'), 1, "space_conversations.lua: ufwol_convo include occurrences (commented or not)")
	lu.assertEquals(countMatches(text, '%-%-%s*includeFile%("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo%.lua"%)'), 0, "space_conversations.lua: commented ufwol_convo include")
	lu.assertEquals(lines[83], E.TEMPLATE_INCLUDE, "space_conversations.lua line 83")
	lu.assertEquals(lines[79], "-- Crimson Phoenix Squadron", "space_conversations.lua line 79")
	lu.assertEquals(lines[80], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua")', "space_conversations.lua line 80")
	lu.assertEquals(lines[81], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")', "space_conversations.lua line 81")
	lu.assertEquals(lines[82], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ulvawop_convo.lua")', "space_conversations.lua line 82")
	lu.assertEquals(#lines, 121, "space_conversations.lua: no line moved (120 lines and the final newline)")
end

-- AC-1, Content contract 3: the handler include sits uncommented once at line 129; the squadron include loads first (line 124)
function TestUfwolWiring:test_the_handler_include_is_uncommented_once_at_line_129_after_the_squadron_include()
	local text = readFile(H.SCRIPTS .. E.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler%.lua"%)'), 1, "screenplays.lua: ufwolConvoHandler include occurrences (commented or not)")
	lu.assertEquals(countMatches(text, '%-%-%s*includeFile%("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler%.lua"%)'), 0, "screenplays.lua: commented ufwolConvoHandler include")
	lu.assertEquals(lines[129], E.HANDLER_INCLUDE, "screenplays.lua line 129")
	lu.assertEquals(lines[124], 'includeFile("space/squadrons/CrimsonPhoenixSquadronScreenplay.lua")', "screenplays.lua line 124 (the squadron include loads first)")
	lu.assertEquals(lines[126], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua")', "screenplays.lua line 126")
	lu.assertEquals(lines[127], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")', "screenplays.lua line 127")
	lu.assertEquals(lines[128], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua")', "screenplays.lua line 128")
	lu.assertEquals(#lines, 191, "screenplays.lua: no line moved (190 lines and the final newline)")
end

-- AC-1: the include lines name files that exist
function TestUfwolWiring:test_the_template_and_handler_files_are_the_ones_the_includes_name()
	for _, path in ipairs({ E.TEMPLATE_FILE, E.HANDLER_FILE }) do
		local f = io.open(H.SCRIPTS .. path, "r")

		lu.assertNotNil(f, path .. " exists under bin/scripts (the include lines name it)")

		if f then
			f:close()
		end
	end
end

-- AC-1: Part B adds no key and does not touch the squadron object's flag key or met key
function TestUfwolWiring:test_the_squadron_object_keeps_the_eker_pilot_key_and_the_met_key()
	lu.assertEquals(E.squadron().EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "EKER_PILOT_KEY is untouched")
	lu.assertEquals(E.squadron().TIER4_MET_KEY, "CrimsonPhoenixSquadronScreenplay:metTier4", "TIER4_MET_KEY is Part A's")
end

-- AC-1, D-12: the spawn is the line that was at the base
function TestUfwolWiring:test_the_spawn_line_is_unchanged()
	local lines = linesOf(readFile(H.SCRIPTS .. E.SPAWN_FILE))

	lu.assertEquals(trim(lines[49] or ""), '{"ufwol", 360, -8.4, 0.6, 3.5, 88, 4505635, ""},', "rori_rebel_outpost.lua:49")
	lu.assertEquals(countMatches(table.concat(lines, "\n"), '"ufwol"'), 1, "rori_rebel_outpost.lua: one Ufwol spawn")
end

-- AC-1, finding 8: the spawn is what SWG's spawner says (RBO rows 100, 102, 103): the same cell of the same building, within 1.0 m, the quaternion reading as the spawn's yaw
function TestUfwolWiring:test_the_spawn_matches_the_swg_spawner_of_the_fixture_excerpt()
	local rbo = tabRows(RBO)

	lu.assertEquals(rbo[1][1], "objid", "rori buildout excerpt: header")
	lu.assertEquals(#rbo, 5, "rori buildout excerpt: two header rows and rows 100, 102, 103")

	local byId = {}

	for i = 3, #rbo do
		byId[rbo[i][1]] = rbo[i]
	end

	-- RBO: 4505633 the building (row 100), 4505635 its cell index 2 (row 102), 7375869 the ground_npc_spawner in that cell (row 103)
	local building, cell, spawn = byId["4505633"], byId["4505635"], byId["7375869"]

	lu.assertNotNil(building, "RBO row 100: the building 4505633")
	lu.assertNotNil(cell, "RBO row 102: the cell 4505635")
	lu.assertNotNil(spawn, "RBO row 103: the spawner 7375869")
	lu.assertEquals(building[3], "object/building/corellia/ply_corl_house_m_s01_fp1.iff", "RBO row 100: server_template_crc (the outpost tavern building)")
	lu.assertEquals(cell[2], "4505633", "RBO row 102: the cell belongs to building 4505633")
	lu.assertEquals(cell[4], "2", "RBO row 102: cell_index")
	lu.assertEquals(spawn[3], "object/tangible/space/content_infrastructure/ground_npc_spawner.iff", "RBO row 103: server_template_crc")
	lu.assertEquals(spawn[2], "4505635", "RBO row 103: the spawner's container is the cell")

	local x, z, y, heading, cellId = readFile(H.SCRIPTS .. E.SPAWN_FILE):match('{"ufwol",%s*360,%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*([%-%d%.]+),%s*(%d+),')

	lu.assertNotNil(cellId, "rori_rebel_outpost.lua: could not parse the Ufwol spawn row")
	lu.assertEquals(cellId, spawn[2], "spawn: cell = RBO container")

	local px, py, pz = tonumber(spawn[5]), tonumber(spawn[6]), tonumber(spawn[7])
	local dx, dz, dy = tonumber(x) - px, tonumber(z) - py, tonumber(y) - pz
	local distance = math.sqrt(dx * dx + dz * dz + dy * dy)

	lu.assertTrue(distance <= 1.0, "spawn: within 1.0 m of RBO row 103 (" .. px .. ", " .. py .. ", " .. pz .. "), got " .. distance)

	-- the quaternion (qw, qx, qy, qz) of the spawner, a rotation about the vertical axis: yaw = 2 * atan2(qy, qw), in degrees
	local qw, qy = tonumber(spawn[8]), tonumber(spawn[10])
	local yaw = math.deg(2 * math.atan(qy, qw)) % 360

	lu.assertTrue(math.abs(yaw - 90) < 0.1, "RBO row 103: the quaternion reads as yaw 90, got " .. yaw)
	lu.assertEquals(tonumber(heading), 88, "spawn: heading unchanged (D-12)")
	lu.assertTrue(math.abs(tonumber(heading) - yaw) <= 5, "spawn: heading within 5 degrees of the spawner's yaw")
end

---------------------------------------------------------------------------------------------
-- The three comment-only edits (AC-1, D-17)
---------------------------------------------------------------------------------------------

local function firstLine(path) return readFile(H.SCRIPTS .. path):match("^([^\n]*)") end

local CSP = "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"

-- AC-1: CSP:1132 names the conversation; the rest of the line is the base's
function TestUfwolWiring:test_the_squadron_tier_4_header_names_the_conversation()
	local lines = linesOf(readFile(H.SCRIPTS .. CSP))
	local line = lines[1132] or ""

	lu.assertEquals(line:sub(1, #"\tTrainer: General Ufwol (conversation ufwolConvoHandler), Rori Rebel outpost ("), "\tTrainer: General Ufwol (conversation ufwolConvoHandler), Rori Rebel outpost (", "CSP:1132 starts with the new parenthesis")
	lu.assertNil(line:find("(no conversation yet)", 1, true), "CSP:1132 no longer says '(no conversation yet)'")
	lu.assertNil(readFile(H.SCRIPTS .. CSP):find("General Ufwol (no conversation yet)", 1, true), "CrimsonPhoenixSquadronScreenplay.lua: the old text is gone")
end

-- AC-1: ulvawopConvoHandler.lua:1 names the tier 4 conversation
function TestUfwolWiring:test_ulvawops_handler_comment_names_ufwols_conversation()
	local line = firstLine(E.ULVAWOP_HANDLER_FILE)

	lu.assertNotNil(line:find("and the hand-off to General Ufwol (tier 4, ufwolConvoHandler): pre-NGE client lines (feature crimson-phoenix-tier3-ulvawop).", 1, true), "ulvawopConvoHandler.lua:1 reads 'General Ufwol (tier 4, ufwolConvoHandler)'")
	lu.assertNil(line:find("(not ported yet)", 1, true), "ulvawopConvoHandler.lua:1 no longer says '(not ported yet)'")
	lu.assertEquals(line:sub(1, 12), "-- Arnecio U", "ulvawopConvoHandler.lua:1 keeps its start")
end

-- AC-1, D-17: socunaConvoHandler.lua:1 names Eker's conversation handler
function TestUfwolWiring:test_socunas_handler_comment_names_ekers_conversation_handler()
	local line = firstLine(E.SOCUNA_HANDLER_FILE)

	lu.assertNotNil(line:find("the promotion screen hands off to Major Eker (tier 2, ekerConvoHandler) through CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY.", 1, true), "socunaConvoHandler.lua:1 reads 'Major Eker (tier 2, ekerConvoHandler)'")
	lu.assertNil(line:find("not ported yet", 1, true), "socunaConvoHandler.lua:1 no longer says 'not ported yet'")
	lu.assertEquals(line:sub(1, 29), "-- Commander Da'la Socuna (Cr", "socunaConvoHandler.lua:1 keeps its start")
end
