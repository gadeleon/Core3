-- Crimson Phoenix tier 1: nothing else moves (I-11) and the shared lines.
-- Spec: .claude/work/crimson-phoenix-tier1-da-la-socuna/01-spec.md (I-11, AC-1, AC-12; Shared code changes; Content contract 4).
--
-- The base is `git show 046c182f35` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
-- Path lists from git use `--full-name`, so they hold from any working directory.

local lu = require("luaunit")

local BASE = "046c182f35"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local NPC = "MMOCoreORB/bin/scripts/mobile/space/da_la_socuna.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/da_la_socuna.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... })
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added = {}, {}
	local inHunk = false

	-- File headers (---/+++) come before the first @@; a removed "--" comment line shows as "---" inside a hunk
	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 2) == "@@" then
			inHunk = true
		elseif inHunk then
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added
end

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

TestCrimsonT1Pins = {}

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

-- I-11, Shared code changes: space_helpers.lua differs only in the Crimson Phoenix surrender branch and the new Eker waypoint function
function TestCrimsonT1Pins:test_space_helpers_differs_from_the_base_only_in_the_crimson_reset_lines_and_the_eker_waypoint()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(#removed, 1, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trim(removed[1] or ""), "-- TODO: Add CrimsonPhoenixSquadronScreenplay reset functions", SH .. ": the replaced line")

	local trimmed, functions = {}, {}

	for _, line in ipairs(added) do
		trimmed[#trimmed + 1] = trim(line)

		local fn = line:match("^function%s+([%w_:%.]+)")

		if fn ~= nil then
			functions[#functions + 1] = fn
		end
	end

	local function has(text)
		for _, line in ipairs(trimmed) do
			if line == text then
				return true
			end
		end

		return false
	end

	lu.assertTrue(has("-- Tier 1"), SH .. ": added line '-- Tier 1'")
	lu.assertTrue(has("CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(pPlayer)"), SH .. ": added line CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(pPlayer) (no nil guard, as the other squadrons)")
	lu.assertEquals(functions, { "SpaceHelpers:addEkerWaypoint" }, SH .. ": the one function added")
end

-- Shared code changes: addEkerWaypoint sits after addCrimsonSquadWaypoint, before the next trainer waypoint helper
function TestCrimsonT1Pins:test_add_eker_waypoint_follows_add_crimson_squad_waypoint()
	local text = assert(readFile("bin/scripts/utils/space_helpers.lua"), "bin/scripts/utils/space_helpers.lua")
	local crimson = text:find("function SpaceHelpers:addCrimsonSquadWaypoint", 1, true)
	local eker = text:find("function SpaceHelpers:addEkerWaypoint", 1, true)
	local nextHelper = text:find("function SpaceHelpers:addImperialPilotWaypoint", 1, true)

	lu.assertNotNil(eker, "SpaceHelpers:addEkerWaypoint is missing")
	lu.assertTrue(crimson ~= nil and nextHelper ~= nil and crimson < eker and eker < nextHelper, "addEkerWaypoint sits between addCrimsonSquadWaypoint and addImperialPilotWaypoint")
end

-- I-11: space_conversations.lua differs only by the two removed `--` of the socuna_convo include
function TestCrimsonT1Pins:test_space_conversations_differs_only_by_the_uncommented_socuna_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, { '--includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")' }, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/socuna_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-11: screenplays.lua differs only by the two removed `--` of the socunaConvoHandler include
function TestCrimsonT1Pins:test_screenplays_differs_only_by_the_uncommented_socuna_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, { '--includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")' }, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/socunaConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-11: da_la_socuna.lua differs only by its two fields (the template name and the options bitmask)
function TestCrimsonT1Pins:test_da_la_socuna_differs_only_by_the_template_and_the_options_bitmask()
	requireBase()

	local removed, added = changedLines(NPC)

	lu.assertEquals(#removed, 2, "removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))
	table.sort(added)
	lu.assertEquals({ trim(added[1] or ""), trim(added[2] or "") }, { 'conversationTemplate = "socuna_convo_template",', "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE," }, "added lines")
end

-- I-11: every other squadron file and the master trainers are byte-identical
function TestCrimsonT1Pins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay", "MasterTrainerScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11: only the seven files of the spec differ under bin/ and src/ (no C++ change)
function TestCrimsonT1Pins:test_only_the_seven_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-11: the quest types, the broker, Burke, Declann, every other trainer, the Mos Espa spawn and Major Eker are untouched
function TestCrimsonT1Pins:test_the_quest_types_the_broker_burke_and_the_other_trainers_are_untouched()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpacePatrolScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceEscortScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/havoc_squadron",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/vortex_squadron",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/j_pai_brek_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/willham_burke_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/havoc_squadron",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/vortex_squadron",
		"MMOCoreORB/bin/scripts/mobile/space/eker.lua",
		"MMOCoreORB/bin/scripts/mobile/space/willham_burke.lua",
		"MMOCoreORB/bin/scripts/mobile/space/j_pai_brek.lua",
		"MMOCoreORB/bin/scripts/screenplays/cities/tatooine_mos_espa.lua",
		"MMOCoreORB/bin/scripts/screenplays/cities/yavin4_labor_outpost.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- No symlink, scratch or backup file sits in the tests tree (the feature's test files and fixtures are plain files)
function TestCrimsonT1Pins:test_the_tests_tree_has_no_symlink_backup_or_scratch_file_of_the_feature()
	local rc, out = shell("find tests/lua -type l -o -name '*.orig' -o -name 'test_zz*' -o -name '__pycache__' | sort")

	lu.assertEquals(rc, 0, "find failed: " .. out)
	lu.assertEquals(trim(out), "", "symlinks, .orig, test_zz* or __pycache__ under tests/lua")
end
