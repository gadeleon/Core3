-- Kiizete: nothing else moves (I-6, AC-9).
-- Spec: .claude/work/vortex-tier1-kiizete/01-spec.md (I-6, AC-9; Content contract 1 and 4; Shared code changes: none; Out of scope).
--
-- The base is `git show 91d09cb422` (the head the spec was written on); the "now" side is the working tree. Every test skips when git cannot show
-- the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "91d09cb422"
local VSP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/VortexSquadronScreenplay.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local KIIZETE = "MMOCoreORB/bin/scripts/mobile/space/kiizete.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/vortex_squadron/kiizete_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/kiizete.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/VortexSquadronScreenplay.lua",
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

local function assertUnchanged(paths)
	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

local function contains(list, text)
	for _, line in ipairs(list) do
		if trim(line) == text then
			return true
		end
	end

	return false
end

TestVortexKiizetePins = {}

-- I-6: only the six files of the spec differ under bin/ and src/ (two new, four changed); nothing under src/
function TestVortexKiizetePins:test_only_the_six_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-6, Content contract 4: space_conversations.lua differs only by the one added include line
function TestVortexKiizetePins:test_space_conversations_differs_only_by_the_added_kiizete_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/rebel/vortex_squadron/kiizete_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-6, Content contract 4: screenplays.lua differs only by the one added include line
function TestVortexKiizetePins:test_screenplays_differs_only_by_the_added_kiizete_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/rebel/vortex_squadron/kiizeteConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-6, Content contract 4: kiizete.lua differs only by its two fields
function TestVortexKiizetePins:test_kiizete_differs_only_by_the_template_and_the_options_bitmask()
	requireBase()

	local removed, added = changedLines(KIIZETE)

	lu.assertEquals(#removed, 2, "removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))
	table.sort(removed)
	table.sort(added)
	lu.assertEquals({ trim(removed[1] or ""), trim(removed[2] or "") }, { 'conversationTemplate = "",', "optionsBitmask = AIENABLED + JTLINTERESTING," }, "removed lines")
	lu.assertEquals({ trim(added[1] or ""), trim(added[2] or "") }, { 'conversationTemplate = "kiizete_convo_template",', "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE," }, "added lines")
end

-- I-6, Content contract 1: the squadron file only gains lines (the two keys, the three functions and their two comments); nothing is removed
function TestVortexKiizetePins:test_the_squadron_file_only_gains_the_lines_of_the_contract()
	requireBase()

	local removed, added = changedLines(VSP)

	lu.assertEquals(removed, {}, VSP .. ": removed lines (resetV3fxQuests, the quest tables and every other line stay unchanged)")
	lu.assertTrue(contains(added, "-- Kiizete (naboo_rebel_tier1_kiizete.java): SWG utils.setScriptVar flags, kept in server memory and cleared at logout (feature vortex-tier1-kiizete)"), "added: the keys comment")
	lu.assertTrue(contains(added, 'KIIZETE_IMP_ASKING_KEY = "VortexSquadronScreenplay:kiizeteImpIsAsking",'), "added: KIIZETE_IMP_ASKING_KEY")
	lu.assertTrue(contains(added, 'KIIZETE_Q1_DISCUSSED_KEY = "VortexSquadronScreenplay:kiizeteQ1Discussed",'), "added: KIIZETE_Q1_DISCUSSED_KEY")
	lu.assertTrue(contains(added, "-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)"), "added: the functions comment")
	lu.assertTrue(contains(added, "function VortexSquadronScreenplay:hasKiizeteFlag(pPlayer, key)"), "added: hasKiizeteFlag")
	lu.assertTrue(contains(added, "function VortexSquadronScreenplay:setKiizeteFlag(pPlayer, key)"), "added: setKiizeteFlag")
	lu.assertTrue(contains(added, "function VortexSquadronScreenplay:onKiizeteLoggedOut(pPlayer)"), "added: onKiizeteLoggedOut")
end

-- I-6, AC-9: the shared helper, V3-FX's files and the surrender reset are byte-identical to the base
function TestVortexKiizetePins:test_space_helpers_and_v3_fx_are_untouched()
	requireBase()
	assertUnchanged({
		"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/vortex_squadron/v3fxConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/vortex_squadron/v3fx_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/space/v3_fx.lua",
	})
end

-- I-6: every other squadron file and the master trainers are byte-identical
function TestVortexKiizetePins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "StormSquadronScreenplay", "MasterTrainerScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		assertUnchanged({ "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua" })
	end
end

-- I-6: the quest types, the broker, Burke, Declann, the other trainers, her spawn and the other Vortex NPCs are untouched
function TestVortexKiizetePins:test_the_quest_types_the_other_trainers_and_the_spawn_are_untouched()
	requireBase()
	assertUnchanged({
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
		"MMOCoreORB/bin/scripts/mobile/space/vrovel.lua",
		"MMOCoreORB/bin/scripts/mobile/space/ezkiel.lua",
		"MMOCoreORB/bin/scripts/mobile/space/extok_evin.lua",
		"MMOCoreORB/bin/scripts/mobile/space/willham_burke.lua",
		"MMOCoreORB/bin/scripts/mobile/space/j_pai_brek.lua",
		"MMOCoreORB/bin/scripts/screenplays/cities/naboo_moenia.lua",
	})
end

-- I-6, Shared code changes: none: nothing under src/ and no ship/quest data table moved
function TestVortexKiizetePins:test_nothing_under_src_differs_from_the_base()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed .. "\n" .. untracked), {}, "files under src/ that differ from " .. BASE)
end
