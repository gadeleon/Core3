-- Storm tier 4 part B (Admiral Kilnstrider's conversation): nothing else moves (I-13).
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (I-13, B-9; Content contract 3 and 4; Migration; D-19, D-21).
--
-- The base is `git show 288da0c8ea` (Part A, storm-tier4-kilnstrider-missions); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "288da0c8ea"
local ROOT = "MMOCoreORB/bin/scripts/"
local TESTS = "MMOCoreORB/tests/lua/"
local SC = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SPL = ROOT .. "screenplays/space/screenplays.lua"
local NPC = ROOT .. "mobile/space/kilnstrider.lua"
local SPAWN = ROOT .. "screenplays/cities/endor_research_outpost.lua"
local SSP = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local CONVO = ROOT .. "mobile/conversations/space/imperial/storm_squadron/kilnstrider_convo.lua"
local HANDLER = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua"

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

-- a repo-root pathspec, valid from any working directory
local function spec(path) return "':/" .. path .. "'" end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Skips unless git can show the base commit and HEAD is still on it
local function requireBase()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	local _, head = shell("git rev-parse HEAD")

	if head:sub(1, #BASE) ~= BASE then
		lu.skip("HEAD is not " .. BASE .. " (" .. trim(head) .. "): the pin only applies before the feature is committed")
	end
end

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }), and the number of hunks
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added, hunks = {}, {}, 0

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 2) == "@@" then
			hunks = hunks + 1
		elseif line:sub(1, 3) ~= "---" and line:sub(1, 3) ~= "+++" then
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added, hunks
end

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

local function allLines(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
	end

	return out
end

local function nonBlank(list)
	local out = {}

	for _, l in ipairs(list) do
		if trim(l) ~= "" then
			out[#out + 1] = trim(l)
		end
	end

	return out
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

-- the working-tree text (the runner's working directory is MMOCoreORB/)
local function readWorking(path)
	local f = assert(io.open("bin/scripts/" .. path:gsub("^MMOCoreORB/bin/scripts/", ""), "r"), "working tree file " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function baseText(path)
	local rc, out = shell("git show " .. BASE .. ":" .. path)

	lu.assertEquals(rc, 0, "git show " .. BASE .. ":" .. path .. " failed: " .. out)
	return out
end

-- the index of the first line equal (trimmed) to `wanted`
local function indexOf(list, wanted, from)
	for i = from or 1, #list do
		if trim(list[i]) == wanted then
			return i
		end
	end
end

-- The top-level `function <Prefix>:name(` blocks of a file: header (text before the first block) and name -> text of the block (up to the next top-level block or
-- the end of the file), plus the order of the names
local function functionBlocks(text, prefix)
	local header, blocks, order = {}, {}, {}
	local current

	for _, l in ipairs(allLines(text)) do
		local name = l:match("^function " .. prefix .. ":([%w_]+)%(")

		if name ~= nil then
			current = name
			blocks[name] = {}
			order[#order + 1] = name
		end

		table.insert(current and blocks[current] or header, l)
	end

	for name, list in pairs(blocks) do
		blocks[name] = table.concat(list, "\n")
	end

	return table.concat(header, "\n"), blocks, order
end


TestStormT4Pins = {}

local DENNER_INCLUDE = 'includeFile("conversations/space/imperial/storm_squadron/denner_convo.lua")'
local KILN_INCLUDE = 'includeFile("conversations/space/imperial/storm_squadron/kilnstrider_convo.lua")'
local DENNER_HANDLER_INCLUDE = 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")'
local KILN_HANDLER_INCLUDE = 'includeFile("space/conversations/imperial/storm_squadron/kilnstriderConvoHandler.lua")'

-- I-13: only SC, SPL and kilnstrider.lua are modified under bin/ and src/, only the template and the handler are added, nothing is deleted or renamed
function TestStormT4Pins:test_only_the_three_files_of_the_spec_differ_and_only_the_template_and_the_handler_are_added()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, other = shell("git diff --name-only --diff-filter=DRCTUXB " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, staged = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files, added = lines(changed), lines(staged)

	for _, f in ipairs(lines(untracked)) do
		added[#added + 1] = f
	end

	local expectedFiles = { NPC, SPL, SC }

	table.sort(files)
	table.sort(added)
	table.sort(expectedFiles)
	lu.assertEquals(files, expectedFiles, "modified files under bin/ and src/ against " .. BASE)
	lu.assertEquals(added, { CONVO, HANDLER }, "added files under bin/ and src/ against " .. BASE .. " (staged or untracked)")
	lu.assertEquals(lines(other), {}, "deleted, renamed or retyped files under bin/ and src/ against " .. BASE)
end

-- I-13: SC's working text is its base text followed by a newline and Kilnstrider's include, with no trailing newline
function TestStormT4Pins:test_space_conversations_gains_only_kilnstriders_include_after_denners()
	requireBase()

	local removed, added = changedLines(SC)

	lu.assertEquals(nonBlank(removed), { DENNER_INCLUDE }, SC .. ": removed lines (Denner's last line gains the newline)")
	lu.assertEquals(nonBlank(added), { DENNER_INCLUDE, KILN_INCLUDE }, SC .. ": added lines (Denner's line again, then Kilnstrider's)")
	lu.assertEquals(readWorking(SC), baseText(SC) .. "\n" .. KILN_INCLUDE, SC .. ": working text = base text .. newline .. Kilnstrider's include (no trailing newline)")

	local list = allLines(readWorking(SC))
	local at = indexOf(list, KILN_INCLUDE)

	lu.assertNotNil(at, "Kilnstrider's include")
	lu.assertEquals(trim(list[at - 1]), DENNER_INCLUDE, "directly after Denner's")
	lu.assertEquals(at, #list, "the last line of the file")
end

-- I-13: SPL gains exactly Kilnstrider's handler include, directly after Denner's
function TestStormT4Pins:test_screenplays_gains_only_kilnstriders_handler_include_after_denners()
	requireBase()

	local removed, added, hunks = changedLines(SPL)

	lu.assertEquals(removed, {}, SPL .. ": removed lines")
	lu.assertEquals(added, { KILN_HANDLER_INCLUDE }, SPL .. ": added lines")
	lu.assertEquals(hunks, 1, SPL .. ": hunks")

	local list = allLines(readWorking(SPL))
	local at = indexOf(list, DENNER_HANDLER_INCLUDE)

	lu.assertEquals(list[at + 1], KILN_HANDLER_INCLUDE, "directly after Denner's, no blank line")
	lu.assertEquals(list[at + 2], "", "the blank line follows")
	lu.assertEquals(list[at + 3], "-- Master Trainers", "the Master Trainers block follows")
end

-- I-13, Content contract 3: kilnstrider.lua differs by exactly the two lines (26 and 36)
function TestStormT4Pins:test_the_kilnstrider_template_differs_by_exactly_the_options_and_the_conversation_lines()
	requireBase()

	local removed, added, hunks = changedLines(NPC)

	lu.assertEquals(nonBlank(removed), { "optionsBitmask = AIENABLED + JTLINTERESTING,", 'conversationTemplate = "",' }, NPC .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", 'conversationTemplate = "kilnstrider_convo_template",' }, NPC .. ": added lines")
	lu.assertEquals(hunks, 2, NPC .. ": hunks")

	local base, now = allLines(baseText(NPC)), allLines(readWorking(NPC))

	lu.assertEquals(#now, #base, NPC .. ": the line count is unchanged")
	lu.assertEquals(trim(base[26]), "optionsBitmask = AIENABLED + JTLINTERESTING,", NPC .. ":26 at the base")
	lu.assertEquals(trim(base[36]), 'conversationTemplate = "",', NPC .. ":36 at the base")
	lu.assertEquals(trim(now[26]), "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", NPC .. ":26")
	lu.assertEquals(trim(now[36]), 'conversationTemplate = "kilnstrider_convo_template",', NPC .. ":36")
end

-- I-13: Part A's files, the spawn and every other production file are byte-identical to the base
function TestStormT4Pins:test_part_a_files_the_spawn_declann_and_the_quest_types_are_byte_identical_to_the_base()
	requireBase()

	identical(SSP)
	identical(SH)
	identical(SPAWN)
	identical(ROOT .. "ship_mobile/ships/rebel_endscout_tier4.lua")

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local storm = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/"
	local convos = ROOT .. "mobile/conversations/space/imperial/storm_squadron/"

	for _, path in ipairs({
		storm .. "oberhaurConvoHandler.lua", storm .. "akalColzetConvoHandler.lua", storm .. "alozenConvoHandler.lua", storm .. "dennerConvoHandler.lua",
		storm .. "nymTechnician1ConvoHandler.lua", storm .. "nymTechnician2ConvoHandler.lua", storm .. "nymTechnician3ConvoHandler.lua",
		convos .. "oberhaur_convo.lua", convos .. "akal_colzet_convo.lua", convos .. "alozen_convo.lua", convos .. "denner_convo.lua",
		convos .. "nym_technician_1_convo.lua", convos .. "nym_technician_2_convo.lua", convos .. "nym_technician_3_convo.lua",
		ROOT .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua", ROOT .. "mobile/conversations/space/imperial/nial_declann_convo.lua",
		ROOT .. "mobile/space/alozen.lua", ROOT .. "mobile/space/oberhaur.lua", ROOT .. "mobile/space/akal_colzet.lua", ROOT .. "mobile/space/denner.lua",
		ROOT .. "mobile/space/nial_declann.lua", ROOT .. "mobile/space/willham_burke.lua", ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "screenplays/cities/naboo_theed.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "screenplays/space/spawning/space_endor_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE)
end

-- D-21: Part A's tests are not edited (their pins file skips at this base and keeps skipping; Part A's data file is extended, tested below)
function TestStormT4Pins:test_part_a_tests_are_untouched()
	requireBase()
	identical(TESTS .. "test_storm_tier4_missions_pins.lua")
	identical(TESTS .. "test_storm_tier4_missions_data.lua")
	identical(TESTS .. "test_storm_tier4_missions_runtime.lua")
	identical(TESTS .. "test_storm_tier4_missions_surrender.lua")
	identical(TESTS .. "test_storm_tier3_pins.lua")
end

-- B-9, Migration of tests: the existing test files that differ from the base are exactly the listed migrations and data files
function TestStormT4Pins:test_the_existing_test_files_that_changed_are_exactly_the_listed_migrations()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests/lua'")
	local want = {}

	for _, f in ipairs({
		-- include adjacency (6)
		"test_storm_tier3_wiring.lua", "test_storm_tier2_alozen_data.lua", "test_storm_tier2_nym_wiring.lua", "test_storm_tier2_data.lua",
		"test_master_trainer_imperial_wiring.lua", "test_master_trainer_rebel_wiring.lua",
		-- FIXTURE_COUNTS 66 -> 67 (8)
		"test_space_convo_client_strings.lua", "test_space_convo_client_strings_arkon.lua", "test_space_convo_client_strings_imler_a.lua",
		"test_space_convo_client_strings_imler_b.lua", "test_space_trainer_rewards_conformance.lua", "test_inquisition_tier4_strings.lua",
		"test_inquisition_tier3_barlow_strings.lua", "test_storm_tier2_nym_template.lua",
		-- data files and the README
		"space_convo_client_strings_data.lua", "storm_tier4_data.lua", "README.md",
	}) do
		want[#want + 1] = TESTS .. f
	end

	local got = lines(changed)

	table.sort(got)
	table.sort(want)
	lu.assertEquals(got, want, "existing files under tests/lua that differ from " .. BASE)
end

-- B-9: the ratchet moved by exactly one entry
function TestStormT4Pins:test_the_ratchet_data_gains_only_the_tier_4_entry_and_its_comment()
	requireBase()

	local removed, added = changedLines(TESTS .. "space_convo_client_strings_data.lua")

	lu.assertEquals(removed, {}, "removed lines")
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))
	contains(table.concat(added, "\n"), '["conversation/tatooine_imperial_tier4"] = 176,', "the FIXTURE_COUNTS entry")
	contains(table.concat(added, "\n"), "storm-tier4-kilnstrider", "the header comment")
end

-- D-22: Part A's data file keeps every export (only lines are added after the Part A body; its first lines change only in the header comment)
function TestStormT4Pins:test_part_a_data_file_keeps_its_body_and_only_gains_the_conversation_section()
	requireBase()

	local removed, added = changedLines(TESTS .. "storm_tier4_data.lua")
	local keptOut = {}

	for _, l in ipairs(removed) do
		-- the header comment line about Part B and the old `return D` are the only lines that may go (the section is inserted before `return D`)
		if not l:find("Part B", 1, true) and trim(l) ~= "" then
			keptOut[#keptOut + 1] = l
		end
	end

	lu.assertEquals(keptOut, {}, "lines of Part A's data file the extension removed or rewrote")
	lu.assertTrue(#added > 100, "the conversation section is added")
end
