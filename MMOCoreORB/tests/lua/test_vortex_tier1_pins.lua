-- Vortex tier 1: nothing else moves (I-11) and the one shared line.
-- Spec: .claude/work/vortex-tier1-v3-fx/01-spec.md (I-11, AC-12; Shared code changes; Content contract 4; R-7).
--
-- The base is `git show 42353a3eff` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "42353a3eff"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/vortex_squadron/v3fx_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/v3_fx.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/VortexSquadronScreenplay.lua",
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

TestVortexT1Pins = {}

-- I-11, Shared code changes: space_helpers.lua differs only in the Vortex surrender branch
function TestVortexT1Pins:test_space_helpers_differs_from_the_base_only_in_the_vortex_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(#removed, 1, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trim(removed[1] or ""), "-- TODO: Add VortexSquadronScreenplay reset functions", SH .. ": the replaced line")
	lu.assertEquals(#added, 2, SH .. ": added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(added[1] or ""), "-- Tier 1", SH .. ": first added line")
	lu.assertEquals(trim(added[2] or ""), "VortexSquadronScreenplay:resetV3fxQuests(pPlayer)", SH .. ": second added line")
end

-- I-11: space_conversations.lua differs only by the two removed `--` of the v3fx_convo include
function TestVortexT1Pins:test_space_conversations_differs_only_by_the_uncommented_v3fx_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, { '--includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")' }, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/rebel/vortex_squadron/v3fx_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-11: screenplays.lua differs only by the two removed `--` of the v3fxConvoHandler include
function TestVortexT1Pins:test_screenplays_differs_only_by_the_uncommented_v3fx_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, { '--includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")' }, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-11: every other squadron file and the master trainers are byte-identical
function TestVortexT1Pins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "StormSquadronScreenplay", "MasterTrainerScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11, R-7: only the seven files of the spec differ under bin/ and src/
function TestVortexT1Pins:test_only_the_seven_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-11: the quest types, the broker, Burke, Declann and every other trainer are untouched (a subset of the whole-tree pin, named for the failure message)
function TestVortexT1Pins:test_the_quest_types_the_broker_burke_and_the_other_trainers_are_untouched()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpacePatrolScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceEscortScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/havoc_squadron",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/j_pai_brek_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/willham_burke_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/havoc_squadron",
		"MMOCoreORB/bin/scripts/mobile/space/kiizete.lua",
		"MMOCoreORB/bin/scripts/mobile/space/vrovel.lua",
		"MMOCoreORB/bin/scripts/mobile/space/ezkiel.lua",
		"MMOCoreORB/bin/scripts/mobile/space/extok_evin.lua",
		"MMOCoreORB/bin/scripts/mobile/space/willham_burke.lua",
		"MMOCoreORB/bin/scripts/mobile/space/j_pai_brek.lua",
		"MMOCoreORB/bin/scripts/screenplays/cities/naboo_moenia.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11: v3_fx.lua differs only by its two fields (the template name and the options bitmask)
function TestVortexT1Pins:test_v3_fx_differs_only_by_the_template_and_the_options_bitmask()
	requireBase()

	local removed, added = changedLines("MMOCoreORB/bin/scripts/mobile/space/v3_fx.lua")

	lu.assertEquals(#removed, 2, "removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))

	table.sort(added)
	lu.assertEquals({ trim(added[1]), trim(added[2]) }, { 'conversationTemplate = "v3fx_convo_template",', "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE," }, "added lines")
end
