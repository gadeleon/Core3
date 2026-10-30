-- Persistent master mission quest type: nothing else moves (AC-10; Content contract 3; Shared code changes).
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-10, I-8).
--
-- The base is `61ff911dc1` (Rebel master trainer committed, the commit the spec was written on top of); the "now" side is the working tree. Every git
-- test skips when git cannot show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the
-- earlier pin files do.
--
-- Edited existing files come from `git diff --name-only --diff-filter=M` (a staged new file would otherwise count as an edit); new files from
-- `--diff-filter=A` plus the untracked ones.

local lu = require("luaunit")

local BASE = "61ff911dc1"
local BIN = "MMOCoreORB/bin/scripts/"
local SDS = BIN .. "screenplays/space/SpaceDestroyScreenplay.lua"
local SMD = BIN .. "screenplays/space/SpaceMasterDestroyScreenplay.lua"
local MTS = BIN .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua"
local SCREENPLAYS = BIN .. "screenplays/space/screenplays.lua"

-- AC-10: the three existing production files that change, and the one new file
local EDITED_FILES = { MTS, SDS, SCREENPLAYS }
local NEW_FILES = { SMD }

-- AC-10: byte-identical to the base
local UNCHANGED = {
	BIN .. "mobile/conversations/space/imperial/nial_declann_convo.lua",
	BIN .. "mobile/conversations/space/rebel/willham_burke_convo.lua",
	BIN .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
	BIN .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
	BIN .. "utils/space_helpers.lua",
	BIN .. "mobile/space/nial_declann.lua",
	BIN .. "mobile/space/willham_burke.lua",
	BIN .. "mobile/conversations/space/space_conversations.lua",
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

local function listOf(out)
	local list = {}

	for line in out:gmatch("[^\n]+") do
		list[#list + 1] = trim(line)
	end

	table.sort(list)
	return list
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path .. " (run from MMOCoreORB/)")
	local text = f:read("a")

	f:close()
	return text
end

local function repoPath(path) return (path:gsub("^MMOCoreORB/", "")) end

TestMasterMissionQuestTypePins = {}

-- AC-10
function TestMasterMissionQuestTypePins:test_the_edited_production_files_are_exactly_the_destroy_type_the_master_tables_and_the_include_list()
	requireBase()

	local rc, out = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- " .. spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src"))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local want = { table.unpack(EDITED_FILES) }

	table.sort(want)
	lu.assertEquals(listOf(out), want, "files under bin/ and src/ edited against " .. BASE)

	local rcD, outD = shell("git diff --name-only --diff-filter=D " .. BASE .. " -- " .. spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src"))

	lu.assertEquals(rcD, 0, outD)
	lu.assertEquals(listOf(outD), {}, "files under bin/ and src/ deleted against " .. BASE)
end

-- AC-10
function TestMasterMissionQuestTypePins:test_the_only_new_production_file_is_the_quest_type()
	requireBase()

	local rc, added = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- " .. spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src"))
	local rcU, untracked = shell("git ls-files --full-name --others --exclude-standard -- " .. spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src"))

	lu.assertEquals(rc, 0, added)
	lu.assertEquals(rcU, 0, untracked)

	local all, seen = {}, {}

	for _, list in ipairs({ listOf(added), listOf(untracked) }) do
		for _, f in ipairs(list) do
			if not seen[f] then
				seen[f] = true
				all[#all + 1] = f
			end
		end
	end

	table.sort(all)
	lu.assertEquals(all, NEW_FILES, "new files under bin/ and src/")
end

-- AC-10: the conversations, the trainer scripts and the helpers are untouched
for _, path in ipairs(UNCHANGED) do
	TestMasterMissionQuestTypePins["test_" .. path:match("([^/]+)%.lua$") .. "_is_byte_identical_to_the_base"] = function()
		requireBase()

		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- AC-10, Content contract 3: MasterTrainerScreenplay differs only by the base type of the four tables, the removed field and one header line
function TestMasterMissionQuestTypePins:test_master_trainer_screenplay_differs_only_by_content_contract_3()
	requireBase()

	local rc, base = shell("git show " .. BASE .. ":" .. MTS)

	lu.assertEquals(rc, 0, base)

	local expected, n1 = base:gsub("SpaceDestroyScreenplay:new {", "SpaceMasterDestroyScreenplay:new {")
	local n2

	expected, n2 = expected:gsub("\t%-%- Pre%-NGE: leaving Kessel keeps the progress\n\tfailOnLeaveZone = false,\n\n", "")

	lu.assertEquals(n1, 4, "the base has four tables on SpaceDestroyScreenplay")
	lu.assertEquals(n2, 4, "the base has four failOnLeaveZone blocks")

	local now = readFile(repoPath(MTS))
	local kept, header = {}, 0

	for i, line in ipairs((function()
		local out = {}

		for l in (now):gmatch("([^\n]*)\n") do out[#out + 1] = l end

		return out
	end)()) do
		if i <= 20 and line:find("SpaceMasterDestroyScreenplay", 1, true) and line:find("space-master-mission-quest-type", 1, true) then
			header = header + 1
		else
			kept[#kept + 1] = line
		end
	end

	lu.assertEquals(header, 1, "exactly one header line names SpaceMasterDestroyScreenplay and the feature (space-master-mission-quest-type)")
	lu.assertTrue(table.concat(kept, "\n") .. "\n" == expected, MTS .. " differs from " .. BASE .. " by more than Content contract 3")
end

-- AC-10, Content contract 2: screenplays.lua differs only by the include line
function TestMasterMissionQuestTypePins:test_screenplays_lua_differs_only_by_the_include_line()
	requireBase()

	local rc, base = shell("git show " .. BASE .. ":" .. SCREENPLAYS)

	lu.assertEquals(rc, 0, base)

	local now = readFile(repoPath(SCREENPLAYS))
	local expected = base:gsub('(includeFile%("space/SpaceDestroyScreenplay%.lua"%)\n)', '%1includeFile("space/SpaceMasterDestroyScreenplay.lua")\n', 1)

	lu.assertTrue(now == expected, SCREENPLAYS .. " differs from " .. BASE .. " by more than the one include line")
end

-- AC-10: no bytecode cache, test scratch or backup file is left in the tests tree
function TestMasterMissionQuestTypePins:test_the_tests_tree_has_no_pycache_scratch_or_backup_files()
	local rc, out = shell("find tests/lua \\( -name __pycache__ -o -name 'test_zz*' -o -name '*.orig' -o -name '*.rej' -o -name '*.bak' \\)")

	lu.assertEquals(rc, 0, out)
	lu.assertEquals(listOf(out), {}, "stray files under tests/lua")
end
