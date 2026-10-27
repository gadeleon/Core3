-- Black Epsilon tier 1: nothing else moves (I-10) and the one shared line.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (I-10, AC-12; Shared code changes; Content contract 4; R-4).
--
-- The base is `git show 9034fa3254` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "9034fa3254"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/hakassha_sireen.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua",
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

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 3) ~= "---" and line:sub(1, 3) ~= "+++" then
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

TestBlackEpsilonT1Pins = {}

-- I-10, Shared code changes: space_helpers.lua differs only in the Black Epsilon surrender branch
function TestBlackEpsilonT1Pins:test_space_helpers_differs_from_the_base_only_in_the_black_epsilon_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(#removed, 1, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trim(removed[1] or ""), "-- TODO: Add BlackEpsilonSquadronScreenplay reset functions", SH .. ": the replaced line")
	lu.assertEquals(#added, 2, SH .. ": added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(added[1] or ""), "-- Tier 1", SH .. ": first added line")
	lu.assertEquals(trim(added[2] or ""), "BlackEpsilonSquadronScreenplay:resetHakasshaQuests(pPlayer)", SH .. ": second added line")
end

-- I-10: space_conversations.lua gains the template include line and nothing else
function TestBlackEpsilonT1Pins:test_space_conversations_gains_only_the_hakassha_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)
	local code = {}

	for _, l in ipairs(added) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(code, { 'includeFile("conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua")' }, CONVERSATIONS .. ": added lines")
	lu.assertTrue(#added <= 2, CONVERSATIONS .. ": at most one blank line besides the include")
end

-- I-10: screenplays.lua gains a blank line and the handler include
function TestBlackEpsilonT1Pins:test_screenplays_gains_only_a_blank_line_and_the_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	-- git may align the new blank line with either of the two blank lines around the include, so compare the set
	table.sort(added)
	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { "", 'includeFile("space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (the include and one blank line)")
end

-- I-10: the CorSec, RSF and Havoc squadron files are byte-identical
function TestBlackEpsilonT1Pins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-10, R-4: only the seven files of the spec differ under bin/ and src/
function TestBlackEpsilonT1Pins:test_only_the_seven_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-10: the quest types, the broker and every other trainer are untouched (a subset of the whole-tree pin, named for the failure message)
function TestBlackEpsilonT1Pins:test_the_quest_types_the_broker_and_the_other_trainers_are_untouched()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpacePatrolScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/mobile/space/kreezo.lua",
	}

	-- the Black Epsilon directories hold the new files, so the imperial conversation directories are checked file by file
	for _, path in ipairs(paths) do
		if path:find("conversations/imperial", 1, true) then
			path = path .. "/imperialBrokerConvoHandler.lua"
		end

		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end
