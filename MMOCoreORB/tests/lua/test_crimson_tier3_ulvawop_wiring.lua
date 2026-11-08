-- Arnecio Ulvaw'op: wiring (AC-1) and the handler's tables and helpers the spec names (Content contract 2 and 3).
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-1; Content contract 2 and 3; Source inventory 1; D-13; I-8).
--
-- The template and the handler load through the server's include order, his mobile template names the conversation and is conversable and invulnerable, the two include
-- lines sit at lines 81 and 126 uncommented (once each) while Ufwol's stay commented, the two stale comments are fixed, and the handler carries the tables and helpers the
-- spec names. I-8 (nothing else moves against de3d94ba21) is test_crimson_tier3_ulvawop_pins.lua.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")

T.loadConversation()

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		lu.fail("expected script " .. path .. " to exist (crimson-phoenix-tier3-ulvawop)")
	end

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

TestUlvawopWiring = {}

function TestUlvawopWiring:setUp() H.reset() end

-- AC-1
function TestUlvawopWiring:test_the_template_is_registered_with_the_handler_class_and_the_handler_global_exists()
	T.requireConversation(lu)

	local t = H.conversationTemplateTable(T.TEMPLATE)

	lu.assertEquals(t.luaClassHandler, T.HANDLER, T.TEMPLATE .. ": luaClassHandler")
	lu.assertEquals(t.templateType, "Lua", T.TEMPLATE .. ": templateType")
	lu.assertEquals(t.initialScreen, "", T.TEMPLATE .. ": initialScreen (the handler picks the first screen)")

	local h = rawget(_G, T.HANDLER)

	for _, name in ipairs({
		"getInitialScreen", "runScreenHandlers", "getNextConversationScreen", "isWon", "isActive", "isFailed", "isPaid", "isOnMission", "getPilotFlag", "isReadyForTier3",
		"isReadyForTier4", "getRewardMission", "raisePilotTier",
	}) do
		lu.assertEquals(type(h[name]), "function", T.HANDLER .. ":" .. name)
	end
end

-- AC-1, Content contract 2: the handler's tables (the contract the display actions and the training grant read)
function TestUlvawopWiring:test_the_handler_carries_the_mission_training_and_screen_tables_of_the_contract()
	T.requireConversation(lu)

	local h = rawget(_G, T.HANDLER)

	for n = 1, 4 do
		local m = h.MISSIONS[n]

		lu.assertNotNil(m, T.HANDLER .. ".MISSIONS[" .. n .. "]")
		lu.assertEquals(m.head, T.HEADS[n], "MISSIONS[" .. n .. "].head")
		lu.assertEquals(m.endString, T.MISSIONS[n].endString, "MISSIONS[" .. n .. "].endString")
		lu.assertEquals(m.standing, 100, "MISSIONS[" .. n .. "].standing")
	end

	lu.assertEquals(#h.TRAIN_CHOICES, 4, "TRAIN_CHOICES entries")

	for i, t in ipairs(T.TRAIN) do
		local c = h.TRAIN_CHOICES[i]
		local flat = { c.skill or c[1], c.reply or c[2], c.screen or c.trained or c[3] }

		lu.assertEquals(flat, { t.skill, T.PREFIX .. t.reply, t.trained }, "TRAIN_CHOICES[" .. i .. "] (skill, topic reply, trained screen)")
	end

	lu.assertEquals(h.DECLINE_REPLY, T.PREFIX .. T.DECLINE_REPLY, "DECLINE_REPLY")
	lu.assertEquals(h.START_SCREENS, T.START_SCREENS, "START_SCREENS")
	lu.assertEquals(h.REWARD_SCREENS, T.REWARD_SCREENS, "REWARD_SCREENS")

	local names = {}

	for id in pairs(h.NAME_SCREENS) do
		names[#names + 1] = type(id) == "number" and h.NAME_SCREENS[id] or id
	end

	local want = {}

	for i, id in ipairs(T.NAME_SCREENS) do
		want[i] = id
	end

	table.sort(names)
	table.sort(want)
	lu.assertEquals(names, want, "NAME_SCREENS")
end

-- Content contract 2: the handler's line 1 is a header comment naming the source script, the feature and the Ufwol hand-off
function TestUlvawopWiring:test_the_handlers_line_1_is_a_header_comment_naming_the_source_the_feature_and_the_hand_off()
	local first = readFile(H.SCRIPTS .. T.HANDLER_FILE):match("^([^\n]*)")

	lu.assertEquals(first:sub(1, 2), "--", "line 1 is a comment")

	for _, word in ipairs({ "Arnecio Ulvaw'op", "tatooine_rebel_tier3.java", "crimson-phoenix-tier3-ulvawop", "General Ufwol" }) do
		lu.assertTrue(first:find(word, 1, true) ~= nil, "line 1 of " .. T.HANDLER_FILE .. " names '" .. word .. "': " .. first)
	end
end

-- AC-1: his mobile template names the conversation and gets the Eker / Ezkiel mask
function TestUlvawopWiring:test_ulvawop_uses_the_template_and_is_conversable_and_invulnerable()
	local npc = H.loadCreatureTemplate("space/arnecio_ulvaw_op.lua", "arnecio_ulvaw_op")

	lu.assertNotNil(npc, "mobile/space/arnecio_ulvaw_op.lua registers arnecio_ulvaw_op")
	lu.assertEquals(npc.conversationTemplate, "ulvawop_convo_template", "arnecio_ulvaw_op: conversationTemplate")
	lu.assertEquals(npc.optionsBitmask & CONVERSABLE, CONVERSABLE, "arnecio_ulvaw_op: optionsBitmask lacks CONVERSABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask & INVULNERABLE, INVULNERABLE, "arnecio_ulvaw_op: optionsBitmask lacks INVULNERABLE (" .. tostring(npc.optionsBitmask) .. ")")
	lu.assertEquals(npc.optionsBitmask, AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE, "arnecio_ulvaw_op: optionsBitmask")
end

-- AC-1: only the two fields change; his identity stays
function TestUlvawopWiring:test_ulvawop_keeps_his_identity_fields()
	local npc = H.loadCreatureTemplate("space/arnecio_ulvaw_op.lua", "arnecio_ulvaw_op")

	lu.assertNotNil(npc, "mobile/space/arnecio_ulvaw_op.lua registers arnecio_ulvaw_op")
	lu.assertEquals(npc.objectName, "@npc_spawner_n:arnecio_ulvaw_op", "arnecio_ulvaw_op: objectName")
	lu.assertEquals(npc.faction, "rebel", "arnecio_ulvaw_op: faction")
	lu.assertEquals(npc.socialGroup, "rebel", "arnecio_ulvaw_op: socialGroup")
	lu.assertEquals(npc.pvpBitmask, NONE, "arnecio_ulvaw_op: pvpBitmask")
	lu.assertEquals(npc.templates, { "object/mobile/space_rebel_tier3_arnecio.iff" }, "arnecio_ulvaw_op: templates")
	lu.assertEquals(npc.level, 100, "arnecio_ulvaw_op: level")
end

-- AC-1, Content contract 3: the template include sits uncommented once at line 81; Ufwol stays commented; the lines around keep their places
function TestUlvawopWiring:test_the_template_include_is_uncommented_once_at_line_81_and_ufwol_stays_commented()
	local text = readFile(H.SCRIPTS .. T.SPACE_CONVERSATIONS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("conversations/space/rebel/crimson_phoenix_squadron/ulvawop_convo%.lua"%)'), 1, "space_conversations.lua: ulvawop_convo include occurrences (commented or not)")
	lu.assertEquals(lines[81], T.TEMPLATE_INCLUDE, "space_conversations.lua line 81")
	lu.assertEquals(lines[78], "-- Crimson Phoenix Squadron", "space_conversations.lua line 78")
	lu.assertEquals(lines[79], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua")', "space_conversations.lua line 79 (Eker unchanged)")
	lu.assertEquals(lines[80], 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")', "space_conversations.lua line 80 (Socuna unchanged)")
	lu.assertEquals(lines[82], '--includeFile("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua")', "space_conversations.lua line 82 (Ufwol) stays commented")
	lu.assertEquals(#lines, 120, "space_conversations.lua: no line moved (119 lines and the final newline)")
end

-- AC-1, Content contract 3: the handler include sits uncommented once at line 126, after the squadron include; Ufwol's stays commented
function TestUlvawopWiring:test_the_handler_include_is_uncommented_once_at_line_126_and_ufwol_stays_commented()
	local text = readFile(H.SCRIPTS .. T.SCREENPLAYS)
	local lines = linesOf(text)

	lu.assertEquals(countMatches(text, 'includeFile%("space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler%.lua"%)'), 1, "screenplays.lua: ulvawopConvoHandler include occurrences (commented or not)")
	lu.assertEquals(lines[126], T.HANDLER_INCLUDE, "screenplays.lua line 126")
	lu.assertEquals(lines[122], 'includeFile("space/squadrons/CrimsonPhoenixSquadronScreenplay.lua")', "screenplays.lua line 122 (the squadron include loads first)")
	lu.assertEquals(lines[124], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua")', "screenplays.lua line 124 (Eker unchanged)")
	lu.assertEquals(lines[125], 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")', "screenplays.lua line 125 (Socuna unchanged)")
	lu.assertEquals(lines[127], '--includeFile("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua")', "screenplays.lua line 127 (Ufwol) stays commented")
	lu.assertEquals(#lines, 189, "screenplays.lua: no line moved (188 lines and the final newline)")
end

-- AC-1: the two files are the server's: the handler file defines the global the template names, the template file registers the template (loaded by their own files)
function TestUlvawopWiring:test_the_template_and_handler_files_are_the_ones_the_includes_name()
	for _, path in ipairs({ T.TEMPLATE_FILE, T.HANDLER_FILE }) do
		local f = io.open(H.SCRIPTS .. path, "r")

		lu.assertNotNil(f, path .. " exists under bin/scripts (the include lines name it)")

		if f then
			f:close()
		end
	end
end

-- AC-1: Part B adds no key and does not touch the squadron object's flag key
function TestUlvawopWiring:test_the_squadron_object_keeps_the_eker_pilot_key()
	lu.assertEquals(T.squadron().EKER_PILOT_KEY, "CrimsonPhoenixSquadronScreenplay:ekerPilot", "EKER_PILOT_KEY is untouched")
end

-- AC-1, D-13, Content contract 3: the tier 3 header of the squadron screenplay (line 554) says the trainer has a conversation; the rest of the line is as Part A wrote it
function TestUlvawopWiring:test_the_tier_3_header_comment_names_the_handler()
	local line = linesOf(readFile(H.SCRIPTS .. T.SQUADRON_FILE))[554]

	lu.assertEquals(line, "\tTrainer: Arnecio Ulvaw'op (conversation ulvawopConvoHandler), Dathomir science outpost (screenplays/cities/dathomir_science_outpost.lua:64). 17 quest tables for the 17 SWG-Source names tatooine_rebel_tier3_1..4 and their splits (recovery, delivery, survival, escort, inspect, destroy_surpriseattack, assassinate, space_battle, patrol, delivery_no_pickup), from datatables/spacequest and tatooine_rebel_tier3.java; feature crimson-phoenix-tier3-ulvawop-missions",
		"CrimsonPhoenixSquadronScreenplay.lua line 554")
end

-- AC-1, D-13, Content contract 3: Eker's header comment says the tier 3 trainer's handler (line 1 only; comment-only change)
function TestUlvawopWiring:test_ekers_header_comment_names_ulvawops_handler()
	local line = linesOf(readFile(H.SCRIPTS .. T.EKER_HANDLER_FILE))[1]

	lu.assertEquals(line, "-- Major Eker (Crimson Phoenix Squadron tier 2, Yavin 4 labor outpost) conversation handler; ported from SWG-Source yavin_rebel_trainer_2.java with the pre-NGE client lines (feature crimson-phoenix-tier2-eker-convo). Training is two-step (topic, then confirm), free choice, bought with XP only. The hand-in of Socuna graduates writes EKER_PILOT_KEY \"2\", the mission 4 reward writes \"3\". Hand-in comes before missions and training. Privileged players (isPrivileged) also get a GM branch. Pilots who finished tier 2 are handed to Arnecio Ulvaw'op (tier 3, ulvawopConvoHandler).",
		"ekerConvoHandler.lua line 1")
end
