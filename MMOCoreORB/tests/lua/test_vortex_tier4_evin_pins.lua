-- Vortex tier 4 part B (Brother Extok Evin's conversation): nothing else moves (I-9).
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (I-9; Content contract 3; Shared code changes: none in bin/ or src/; AC-1 last bullet; AC-10 third bullet).
--
-- The base is `git show f8097f7c7d` (the commit the spec was written on: Part A, vortex-tier4-extok-evin); the "now" side is the working tree. Every test skips when
-- git cannot show the base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
-- Against the base the feature may modify exactly extok_evin.lua, space_conversations.lua and screenplays.lua, and add exactly evin_convo.lua and evinConvoHandler.lua.
-- The diff reader skips the diff header only before the first @@: after it a removed "-- comment" line reads "--- comment" and must still count.

local lu = require("luaunit")

local BASE = "f8097f7c7d"
local ROOT = "MMOCoreORB/bin/scripts/"
local NPC = ROOT .. "mobile/space/extok_evin.lua"
local CONVOS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local TEMPLATE = ROOT .. "mobile/conversations/space/rebel/vortex_squadron/evin_convo.lua"
local HANDLER = ROOT .. "screenplays/space/conversations/rebel/vortex_squadron/evinConvoHandler.lua"
local VSP = ROOT .. "screenplays/space/squadrons/VortexSquadronScreenplay.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"
local MASTER = ROOT .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua"
local PART_A_PINS = "MMOCoreORB/tests/lua/test_vortex_tier4_missions_pins.lua"

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

-- The removed and added lines of a `git diff -U0` text ({ text... }, { text... }) and the number of hunks. The diff header (---, +++) is skipped only before the
-- first @@: after it a removed "-- comment" line reads "--- comment" and must still count.
local function parseDiff(text)
	local removed, added, hunks = {}, {}, 0

	for line in (text .. "\n"):gmatch("(.-)\n") do
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

local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	return parseDiff(out)
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

TestEvinConvoPins = {}

-- I-9: only the three files of the spec are modified under bin/ and src/; nothing is deleted, renamed or changed in mode
function TestEvinConvoPins:test_only_the_three_files_of_the_spec_are_modified_from_the_base_under_bin_and_src()
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

-- I-9: exactly the template and the handler are added (staged or untracked), nothing else under bin/ and src/
function TestEvinConvoPins:test_exactly_the_template_and_the_handler_are_added_under_bin_and_src()
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

-- I-9, Content contract 3: extok_evin.lua differs only by the two lines (26 and 36)
function TestEvinConvoPins:test_extok_evin_lua_differs_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	local removed, added, hunks = changedLines(NPC)

	lu.assertEquals(hunks, 2, "hunks in extok_evin.lua")
	lu.assertEquals(removed, { "\toptionsBitmask = AIENABLED + JTLINTERESTING,", '\tconversationTemplate = "",' }, "removed lines of extok_evin.lua")
	lu.assertEquals(added, { "\toptionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", '\tconversationTemplate = "evin_convo_template",' }, "added lines of extok_evin.lua")

	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(NPC))

	lu.assertEquals(rc, 0, out)
	lu.assertStrContains(out, "@@ -26 +26 @@", false, "the first hunk is line 26")
	lu.assertStrContains(out, "@@ -36 +36 @@", false, "the second hunk is line 36")
end

-- I-9, Content contract 3: each include file differs only by one removed "--" (Evin's lines at 92 and 141)
function TestEvinConvoPins:test_each_include_file_differs_only_by_one_removed_comment_marker()
	requireBase()

	for path, want in pairs({
		[CONVOS] = { line = 'includeFile("conversations/space/rebel/vortex_squadron/evin_convo.lua")', at = 92 },
		[SCREENPLAYS] = { line = 'includeFile("space/conversations/rebel/vortex_squadron/evinConvoHandler.lua")', at = 141 },
	}) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { "--" .. want.line }, path .. ": removed lines")
		lu.assertEquals(added, { want.line }, path .. ": added lines")

		local _, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

		lu.assertStrContains(out, "@@ -" .. want.at .. " +" .. want.at .. " @@", false, path .. ": the hunk is line " .. want.at)
	end
end

-- I-9, Shared code changes: none: the squadron object, the helpers and the quest logic are untouched
function TestEvinConvoPins:test_the_squadron_object_the_helpers_and_the_quest_logic_are_untouched()
	requireBase()

	for _, path in ipairs({ VSP, SH, SQL }) do
		identical(path)
	end
end

-- I-9: the other Vortex trainers, Burke, the master trainer screenplay, Evin's spawn and Part A's pins file are byte-identical to the base (AC-10: Part A's pins file is not edited)
function TestEvinConvoPins:test_the_other_trainers_burke_the_spawn_and_part_a_pins_are_unchanged()
	requireBase()

	local vortex = ROOT .. "screenplays/space/conversations/rebel/vortex_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/vortex_squadron/"

	for _, path in ipairs({
		vortex .. "v3fxConvoHandler.lua", vortex .. "vrovelConvoHandler.lua", vortex .. "kiizeteConvoHandler.lua", vortex .. "ezkielConvoHandler.lua", convos .. "v3fx_convo.lua",
		convos .. "vrovel_convo.lua", convos .. "kiizete_convo.lua", convos .. "ezkiel_convo.lua", ROOT .. "mobile/space/vrovel.lua", ROOT .. "mobile/space/v3_fx.lua",
		ROOT .. "mobile/space/ezkiel.lua", ROOT .. "screenplays/poi/dantooine_abandoned_rebel_base.lua", ROOT .. "screenplays/cities/talus_dearic.lua",
		ROOT .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua", ROOT .. "mobile/conversations/space/rebel/willham_burke_convo.lua", MASTER, PART_A_PINS,
	}) do
		identical(path)
	end
end

-- I-9: no C++ file changes
function TestEvinConvoPins:test_no_cpp_or_idl_file_changes()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed), {}, "changed files under MMOCoreORB/src against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked files under MMOCoreORB/src")
end

-- the pin helper itself (a lesson of Part A): a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed; only the header before the
-- first @@ is skipped
function TestEvinConvoPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
	local text = "--- a/x.lua\n+++ b/x.lua\n@@ -1 +1 @@\n--- old comment\n+-- new comment"
	local removed, added, hunks = parseDiff(text)

	lu.assertEquals(removed, { "-- old comment" }, "removed")
	lu.assertEquals(added, { "-- new comment" }, "added")
	lu.assertEquals(hunks, 1, "hunks")

	local r2, a2, h2 = parseDiff("--- a/x.lua\n+++ b/x.lua")

	lu.assertEquals({ r2, a2, h2 }, { {}, {}, 0 }, "a diff with a header and no hunk has no changed line")
end

-- the base names a real commit: the header says f8097f7c7d, the pin must not point at an older base by mistake
function TestEvinConvoPins:test_the_base_is_the_part_a_commit()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	local _, subject = shell("git log -1 --format=%s " .. BASE)

	lu.assertStrContains(subject, "Vortex tier 4 missions", false, "subject of " .. BASE)
end
