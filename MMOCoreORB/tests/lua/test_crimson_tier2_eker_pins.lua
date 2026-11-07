-- Crimson Phoenix tier 2 part B (Major Eker's conversation): nothing else moves (I-8).
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (I-8; Content contract 1; Shared code changes: none in bin/ or src/; AC-1 last bullet).
--
-- The base is `git show 2a839b9d1c` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
-- Against the base the feature may modify exactly eker.lua, space_conversations.lua and screenplays.lua, and add exactly eker_convo.lua and ekerConvoHandler.lua.

local lu = require("luaunit")

local BASE = "2a839b9d1c"
local ROOT = "MMOCoreORB/bin/scripts/"
local NPC = ROOT .. "mobile/space/eker.lua"
local CONVOS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local TEMPLATE = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua"
local HANDLER = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"

local MODIFIED = { NPC, CONVOS, SCREENPLAYS }
local ADDED = { TEMPLATE, HANDLER }

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

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }), and the number of hunks. The diff header (---, +++) is
-- skipped only before the first @@: after it a removed "-- comment" line reads "--- comment" and must still count.
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added, hunks = {}, {}, 0

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 2) == "@@" then
			hunks = hunks + 1
		elseif hunks > 0 then
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added, hunks
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

TestEkerConvoPins = {}

-- I-8: only the three files of the spec are modified under bin/ and src/; nothing is deleted, renamed or changed in mode
function TestEkerConvoPins:test_only_the_three_files_of_the_spec_are_modified_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, other = shell("git diff --name-only --diff-filter=DRCTUXB " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files, expected = lines(changed), {}

	for i, f in ipairs(MODIFIED) do
		expected[i] = f
	end

	table.sort(files)
	table.sort(expected)
	lu.assertEquals(files, expected, "modified files under bin/ and src/ against " .. BASE)
	lu.assertEquals(lines(other), {}, "deleted, renamed, copied or type-changed files under bin/ and src/ against " .. BASE)
end

-- I-8: exactly the template and the handler are added (staged or untracked), nothing else under bin/ and src/
function TestEkerConvoPins:test_exactly_the_template_and_the_handler_are_added_under_bin_and_src()
	requireBase()

	local _, staged = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files, expected = lines(staged), {}

	for _, f in ipairs(lines(untracked)) do
		files[#files + 1] = f
	end

	for i, f in ipairs(ADDED) do
		expected[i] = f
	end

	table.sort(files)
	table.sort(expected)
	lu.assertEquals(files, expected, "added files under bin/ and src/ against " .. BASE)
end

-- I-8, Content contract 1: eker.lua differs only by the two lines
function TestEkerConvoPins:test_eker_lua_differs_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	local removed, added, hunks = changedLines(NPC)

	lu.assertEquals(hunks, 2, "hunks in eker.lua")
	lu.assertEquals(removed, { "\toptionsBitmask = AIENABLED + JTLINTERESTING,", '\tconversationTemplate = "",' }, "removed lines of eker.lua")
	lu.assertEquals(added, { "\toptionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", '\tconversationTemplate = "eker_convo_template",' }, "added lines of eker.lua")
end

-- I-8, Content contract 1: each include file differs only by one removed "--"
function TestEkerConvoPins:test_each_include_file_differs_only_by_one_removed_comment_marker()
	requireBase()

	for path, line in pairs({
		[CONVOS] = 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/eker_convo.lua")',
		[SCREENPLAYS] = 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua")',
	}) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { "--" .. line }, path .. ": removed lines")
		lu.assertEquals(added, { line }, path .. ": added lines")
	end
end

-- I-8, Shared code changes: none: the squadron object, the helpers and the quest logic are untouched
function TestEkerConvoPins:test_the_squadron_object_the_helpers_and_the_quest_logic_are_untouched()
	requireBase()

	for _, path in ipairs({ CSP, SH, SQL }) do
		identical(path)
	end
end

-- I-8: no C++ file changes
function TestEkerConvoPins:test_no_cpp_or_idl_file_changes()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed), {}, "changed files under MMOCoreORB/src against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked files under MMOCoreORB/src")
end
