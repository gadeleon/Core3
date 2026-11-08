-- Crimson Phoenix tier 3 part B (Arnecio Ulvaw'op's conversation): nothing else moves (I-8).
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (I-8; Content contract 3; Shared code changes: none in bin/ or src/ beyond the two comment lines; AC-1 last bullet; AC-9).
--
-- The base is `git show de3d94ba21` (the commit the spec was written on: Part A, crimson-phoenix-tier3-ulvawop-missions); the "now" side is the working tree. Every test skips
-- when git cannot show the base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
-- Against the base the feature may modify exactly arnecio_ulvaw_op.lua, space_conversations.lua, screenplays.lua, CrimsonPhoenixSquadronScreenplay.lua (one comment line) and
-- ekerConvoHandler.lua (one comment line), and add exactly ulvawop_convo.lua and ulvawopConvoHandler.lua.
-- The diff reader skips the diff header only before the first @@: after it a removed "-- comment" line reads "--- comment" and must still count.

local lu = require("luaunit")

local BASE = "de3d94ba21"
local ROOT = "MMOCoreORB/bin/scripts/"
local NPC = ROOT .. "mobile/space/arnecio_ulvaw_op.lua"
local CONVOS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"
local EKER_HANDLER = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/ekerConvoHandler.lua"
local TEMPLATE = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/ulvawop_convo.lua"
local HANDLER = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"
local PART_A_PINS = "MMOCoreORB/tests/lua/test_crimson_tier3_missions_pins.lua"

local MODIFIED = { NPC, CONVOS, SCREENPLAYS, CSP, EKER_HANDLER }
local ADDED = { TEMPLATE, HANDLER }

local OLD_CSP = "\tTrainer: Arnecio Ulvaw'op (no conversation yet), Dathomir science outpost (screenplays/cities/dathomir_science_outpost.lua:64). 17 quest tables for the 17 SWG-Source names tatooine_rebel_tier3_1..4 and their splits (recovery, delivery, survival, escort, inspect, destroy_surpriseattack, assassinate, space_battle, patrol, delivery_no_pickup), from datatables/spacequest and tatooine_rebel_tier3.java; feature crimson-phoenix-tier3-ulvawop-missions"
local NEW_CSP = OLD_CSP:gsub("%(no conversation yet%)", "(conversation ulvawopConvoHandler)", 1)
local OLD_EKER = "-- Major Eker (Crimson Phoenix Squadron tier 2, Yavin 4 labor outpost) conversation handler; ported from SWG-Source yavin_rebel_trainer_2.java with the pre-NGE client lines (feature crimson-phoenix-tier2-eker-convo). Training is two-step (topic, then confirm), free choice, bought with XP only. The hand-in of Socuna graduates writes EKER_PILOT_KEY \"2\", the mission 4 reward writes \"3\". Hand-in comes before missions and training. Privileged players (isPrivileged) also get a GM branch. Pilots who finished tier 2 are handed to Arnecio Ulvaw'op (tier 3, not ported)."
local NEW_EKER = OLD_EKER:gsub("%(tier 3, not ported%)", "(tier 3, ulvawopConvoHandler)", 1)

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

TestUlvawopConvoPins = {}

-- I-8: only the five files of the spec are modified under bin/ and src/; nothing is deleted, renamed or changed in mode
function TestUlvawopConvoPins:test_only_the_five_files_of_the_spec_are_modified_from_the_base_under_bin_and_src()
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
function TestUlvawopConvoPins:test_exactly_the_template_and_the_handler_are_added_under_bin_and_src()
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

-- I-8, Content contract 3: arnecio_ulvaw_op.lua differs only by the two lines
function TestUlvawopConvoPins:test_arnecio_ulvaw_op_lua_differs_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	local removed, added, hunks = changedLines(NPC)

	lu.assertEquals(hunks, 2, "hunks in arnecio_ulvaw_op.lua")
	lu.assertEquals(removed, { "\toptionsBitmask = AIENABLED + JTLINTERESTING,", '\tconversationTemplate = "",' }, "removed lines of arnecio_ulvaw_op.lua")
	lu.assertEquals(added, { "\toptionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", '\tconversationTemplate = "ulvawop_convo_template",' }, "added lines of arnecio_ulvaw_op.lua")
end

-- I-8, Content contract 3: each include file differs only by one removed "--" (Ulvaw'op's line; Ufwol's stays commented)
function TestUlvawopConvoPins:test_each_include_file_differs_only_by_one_removed_comment_marker()
	requireBase()

	for path, line in pairs({
		[CONVOS] = 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ulvawop_convo.lua")',
		[SCREENPLAYS] = 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ulvawopConvoHandler.lua")',
	}) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { "--" .. line }, path .. ": removed lines")
		lu.assertEquals(added, { line }, path .. ": added lines")
	end
end

-- I-8, Content contract 3 (D-13): the squadron screenplay and Eker's handler each differ by exactly their one comment line
function TestUlvawopConvoPins:test_the_squadron_screenplay_and_ekers_handler_differ_by_exactly_one_comment_line_each()
	requireBase()

	for path, change in pairs({ [CSP] = { OLD_CSP, NEW_CSP }, [EKER_HANDLER] = { OLD_EKER, NEW_EKER } }) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { change[1] }, path .. ": removed lines")
		lu.assertEquals(added, { change[2] }, path .. ": added lines")
	end
end

-- I-8, Shared code changes: none: the helpers and the quest logic are untouched, nor is any quest-type screenplay
function TestUlvawopConvoPins:test_the_helpers_the_quest_logic_and_every_quest_type_are_untouched()
	requireBase()

	for _, path in ipairs({ SH, SQL }) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE)
end

-- I-8: the other Crimson Phoenix trainers, Ulvaw'op's spawn, the quest tables' files and Part A's pins file are byte-identical to the base (Part A's pins file is not edited)
function TestUlvawopConvoPins:test_the_other_trainers_the_spawn_and_part_a_pins_are_unchanged()
	requireBase()

	local crimson = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/"

	for _, path in ipairs({
		crimson .. "socunaConvoHandler.lua", convos .. "socuna_convo.lua", convos .. "eker_convo.lua", ROOT .. "mobile/space/eker.lua", ROOT .. "mobile/space/da_la_socuna.lua",
		ROOT .. "screenplays/cities/dathomir_science_outpost.lua", ROOT .. "screenplays/cities/rori_rebel_outpost.lua", PART_A_PINS,
	}) do
		identical(path)
	end
end

-- I-8: no C++ file changes
function TestUlvawopConvoPins:test_no_cpp_or_idl_file_changes()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed), {}, "changed files under MMOCoreORB/src against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked files under MMOCoreORB/src")
end

-- the pin helper itself (a lesson of Part A): a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed; only the header before the
-- first @@ is skipped
function TestUlvawopConvoPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
	local text = "--- a/x.lua\n+++ b/x.lua\n@@ -1 +1 @@\n--- old comment\n+-- new comment"
	local removed, added, hunks = parseDiff(text)

	lu.assertEquals(removed, { "-- old comment" }, "removed")
	lu.assertEquals(added, { "-- new comment" }, "added")
	lu.assertEquals(hunks, 1, "hunks")

	local r2, a2, h2 = parseDiff("--- a/x.lua\n+++ b/x.lua")

	lu.assertEquals({ r2, a2, h2 }, { {}, {}, 0 }, "a diff with a header and no hunk has no changed line")
end

-- the pin's own texts: the new comment lines differ from the old ones only by the spec's replacement
function TestUlvawopConvoPins:test_the_expected_comment_lines_differ_from_the_old_ones_by_the_replacement_only()
	lu.assertNotEquals(NEW_CSP, OLD_CSP, "CSP:554 changes")
	lu.assertNotEquals(NEW_EKER, OLD_EKER, "ekerConvoHandler.lua:1 changes")
	lu.assertEquals((NEW_CSP:gsub("%(conversation ulvawopConvoHandler%)", "(no conversation yet)", 1)), OLD_CSP, "CSP:554 differs by the parenthesis only")
	lu.assertEquals((NEW_EKER:gsub("%(tier 3, ulvawopConvoHandler%)", "(tier 3, not ported)", 1)), OLD_EKER, "ekerConvoHandler.lua:1 differs by the parenthesis only")
end

-- the base names a real commit: the header says de3d94ba21, the pin must not point at an older base by mistake
function TestUlvawopConvoPins:test_the_base_is_the_part_a_commit()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	local _, subject = shell("git log -1 --format=%s " .. BASE)

	lu.assertStrContains(subject, "Crimson Phoenix tier 3 missions", false, "subject of " .. BASE)
end
