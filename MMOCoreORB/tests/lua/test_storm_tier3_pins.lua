-- Storm tier 3 part B (Captain Denner's conversation): nothing else moves (I-14, Part B slice).
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (I-14, B-8; Content contract 1 and 3; Migration; D-B1, D-B2).
--
-- The base is `git show 540161018f` (Part A, storm-tier3-denner-missions); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "540161018f"
local ROOT = "MMOCoreORB/bin/scripts/"
local TESTS = "MMOCoreORB/tests/lua/"
local SC = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SPL = ROOT .. "screenplays/space/screenplays.lua"
local NPC = ROOT .. "mobile/space/denner.lua"
local YB = ROOT .. "screenplays/poi/yavin4_imperial_base.lua"
local SSP = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local CONVO = ROOT .. "mobile/conversations/space/imperial/storm_squadron/denner_convo.lua"
local HANDLER = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/dennerConvoHandler.lua"

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


TestStormT3Pins = {}

-- I-14: only SC, SPL, denner.lua and YB are modified under bin/ and src/, only the template and the handler are added, nothing is deleted or renamed
function TestStormT3Pins:test_only_the_four_files_of_the_spec_differ_and_only_the_template_and_the_handler_are_added()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, other = shell("git diff --name-only --diff-filter=DRCTUXB " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, staged = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files, added = lines(changed), lines(staged)

	for _, f in ipairs(lines(untracked)) do
		added[#added + 1] = f
	end

	local expectedFiles = { NPC, SPL, SC, YB }

	table.sort(files)
	table.sort(added)
	table.sort(expectedFiles)
	lu.assertEquals(files, expectedFiles, "modified files under bin/ and src/ against " .. BASE)
	lu.assertEquals(added, { CONVO, HANDLER }, "added files under bin/ and src/ against " .. BASE .. " (staged or untracked)")
	lu.assertEquals(lines(other), {}, "deleted, renamed or retyped files under bin/ and src/ against " .. BASE)
end

-- I-14: SC gains one line (the newline before it moves Alozen's line in the diff)
function TestStormT3Pins:test_space_conversations_gains_only_denners_include_after_alozens()
	requireBase()

	local removed, added = changedLines(SC)
	local alozen = 'includeFile("conversations/space/imperial/storm_squadron/alozen_convo.lua")'
	local denner = 'includeFile("conversations/space/imperial/storm_squadron/denner_convo.lua")'

	lu.assertEquals(nonBlank(removed), { alozen }, SC .. ": removed lines (Alozen's last line gains the newline)")
	lu.assertEquals(nonBlank(added), { alozen, denner }, SC .. ": added lines (Alozen's line again, then Denner's)")

	local list = allLines(readWorking(SC))
	local at = indexOf(list, denner)

	lu.assertNotNil(at, "Denner's include")
	lu.assertEquals(trim(list[at - 1]), alozen, "directly after Alozen's")
end

-- I-14: SPL gains one line
function TestStormT3Pins:test_screenplays_gains_only_denners_handler_include_after_alozens()
	requireBase()

	local removed, added, hunks = changedLines(SPL)
	local handler = 'includeFile("space/conversations/imperial/storm_squadron/dennerConvoHandler.lua")'

	lu.assertEquals(removed, {}, SPL .. ": removed lines")
	lu.assertEquals(added, { handler }, SPL .. ": added lines")
	lu.assertEquals(hunks, 1, SPL .. ": hunks")

	local list = allLines(readWorking(SPL))
	local at = indexOf(list, 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")')

	lu.assertEquals(list[at + 1], handler, "directly after Alozen's, no blank line")
end

-- I-14: denner.lua differs by exactly the two lines of Content contract 3
function TestStormT3Pins:test_the_denner_template_differs_by_exactly_the_options_and_the_conversation_lines()
	requireBase()

	local removed, added = changedLines(NPC)

	lu.assertEquals(nonBlank(removed), { "optionsBitmask = AIENABLED,", 'conversationTemplate = "",' }, NPC .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", 'conversationTemplate = "denner_convo_template",' }, NPC .. ": added lines")
end

-- I-14: YB gains the comma on Barlow's row and Denner's row, nothing else
function TestStormT3Pins:test_the_spawn_table_differs_by_barlows_comma_and_dennerss_row()
	requireBase()

	local removed, added = changedLines(YB)

	lu.assertEquals(removed, { '\t\t{"barlow", 60, 4028.91, 37, -6201.62, 150, 0, "npc_imperial"}' }, YB .. ": removed lines")
	lu.assertEquals(added, { '\t\t{"barlow", 60, 4028.91, 37, -6201.62, 150, 0, "npc_imperial"},', '\t\t{"denner", 300, -4.0, 0.125, -3.683, 90, 8735521, ""}' }, YB .. ": added lines")

	local list = allLines(readWorking(YB))

	lu.assertEquals(list[34], '\t\t{"denner", 300, -4.0, 0.125, -3.683, 90, 8735521, ""}', YB .. ":34")
	lu.assertEquals(list[35], "\t}", YB .. ":35")
end

-- I-14: Part A's files and every other production file are byte-identical to the base
function TestStormT3Pins:test_part_a_files_the_other_trainers_and_the_quest_types_are_byte_identical_to_the_base()
	requireBase()

	identical(SSP)
	identical(SH)

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local storm = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/"
	local convos = ROOT .. "mobile/conversations/space/imperial/storm_squadron/"

	for _, path in ipairs({
		storm .. "oberhaurConvoHandler.lua", storm .. "akalColzetConvoHandler.lua", storm .. "alozenConvoHandler.lua", storm .. "nymTechnician1ConvoHandler.lua",
		storm .. "nymTechnician2ConvoHandler.lua", storm .. "nymTechnician3ConvoHandler.lua", convos .. "oberhaur_convo.lua", convos .. "akal_colzet_convo.lua",
		convos .. "alozen_convo.lua", convos .. "nym_technician_1_convo.lua", convos .. "nym_technician_2_convo.lua", convos .. "nym_technician_3_convo.lua",
		ROOT .. "mobile/space/alozen.lua", ROOT .. "mobile/space/oberhaur.lua", ROOT .. "mobile/space/akal_colzet.lua", ROOT .. "mobile/space/kilnstrider.lua",
		ROOT .. "mobile/space/nial_declann.lua", ROOT .. "mobile/space/willham_burke.lua", ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "screenplays/cities/endor_research_outpost.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "screenplays/space/spawning/space_endor_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE)
end

-- B-8, D-B2: Part A's pins file is not edited
function TestStormT3Pins:test_part_a_pins_file_and_data_exports_are_untouched()
	requireBase()
	identical(TESTS .. "test_storm_tier3_missions_pins.lua")
	identical(TESTS .. "test_storm_tier3_missions_data.lua")
	identical(TESTS .. "test_storm_tier3_missions_runtime.lua")
	identical(TESTS .. "test_storm_tier3_missions_surrender.lua")
	identical(TESTS .. "test_storm_tier3_missions_escort_wave.lua")
	identical(TESTS .. "test_storm_tier2_alozen_pins.lua")
end

-- B-8: the existing test files that differ from the base are exactly the migrations of the spec (Migration of tests, Content contract 4)
function TestStormT3Pins:test_the_existing_test_files_that_changed_are_exactly_the_listed_migrations()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests/lua'")
	local want = {}

	for _, f in ipairs({
		"test_storm_tier2_alozen_data.lua", "test_storm_tier2_nym_wiring.lua", "test_storm_tier2_data.lua", "test_master_trainer_imperial_wiring.lua",
		"test_master_trainer_rebel_wiring.lua", "test_inquisition_tier3_barlow_wiring.lua", "test_space_convo_client_strings.lua",
		"test_space_convo_client_strings_arkon.lua", "test_space_convo_client_strings_imler_a.lua", "test_space_convo_client_strings_imler_b.lua",
		"test_space_trainer_rewards_conformance.lua", "test_inquisition_tier4_strings.lua", "test_inquisition_tier3_barlow_strings.lua",
		"test_storm_tier2_nym_template.lua", "space_convo_client_strings_data.lua", "storm_tier3_data.lua", "README.md",
	}) do
		want[#want + 1] = TESTS .. f
	end

	local got = lines(changed)

	table.sort(got)
	table.sort(want)
	lu.assertEquals(got, want, "existing files under tests/lua that differ from " .. BASE)
end

-- B-8: the ratchet moved by exactly one entry
function TestStormT3Pins:test_the_ratchet_data_gains_only_the_tier_3_entry_and_its_comment()
	requireBase()

	local removed, added = changedLines(TESTS .. "space_convo_client_strings_data.lua")

	lu.assertEquals(removed, {}, "removed lines")
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))
	contains(table.concat(added, "\n"), '["conversation/tatooine_imperial_tier3"] = 281,', "the FIXTURE_COUNTS entry")
	contains(table.concat(added, "\n"), "storm-tier3-denner", "the header comment")
end
