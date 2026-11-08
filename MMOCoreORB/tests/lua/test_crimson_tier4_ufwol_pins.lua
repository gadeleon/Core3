-- Crimson Phoenix tier 4 part B (General Ufwol's conversation): nothing else moves (I-9).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (I-9; Content contract 3; Shared code changes: none; AC-1 last bullet; AC-10).
--
-- The base is `git show fbb648f5e5` (the commit the spec was written on: Part A, crimson-phoenix-tier4-ufwol-missions); the "now" side is the working tree. Every test skips
-- when git cannot show the base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
-- Against the base the feature may modify exactly ufwol.lua, space_conversations.lua, screenplays.lua, CrimsonPhoenixSquadronScreenplay.lua (one comment line),
-- ulvawopConvoHandler.lua (one comment line) and socunaConvoHandler.lua (one comment line), and add exactly ufwol_convo.lua and ufwolConvoHandler.lua.
-- The diff reader skips the diff header only before the first @@: after it a removed "-- comment" line reads "--- comment" and must still count.

local lu = require("luaunit")

local BASE = "fbb648f5e5"
local ROOT = "MMOCoreORB/bin/scripts/"
local NPC = ROOT .. "mobile/space/ufwol.lua"
local CONVOS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"
local CRIMSON_HANDLERS = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/"
local ULVAWOP_HANDLER = CRIMSON_HANDLERS .. "ulvawopConvoHandler.lua"
local SOCUNA_HANDLER = CRIMSON_HANDLERS .. "socunaConvoHandler.lua"
local TEMPLATE = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua"
local HANDLER = CRIMSON_HANDLERS .. "ufwolConvoHandler.lua"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"
local PART_A_PINS = "MMOCoreORB/tests/lua/test_crimson_tier4_missions_pins.lua"

local MODIFIED = { NPC, CONVOS, SCREENPLAYS, CSP, ULVAWOP_HANDLER, SOCUNA_HANDLER }
local ADDED = { TEMPLATE, HANDLER }

local OLD_CSP = [==[	Trainer: General Ufwol (no conversation yet), Rori Rebel outpost (screenplays/cities/rori_rebel_outpost.lua:49). 17 quest tables for the 13 SWG-Source names tatooine_rebel_tier4_1..4, their success and failure splits and the four tier 4 duties (space_battle, assassinate, patrol, destroy_surpriseattack, recovery, delivery, survival, destroy_duty, escort_duty, recovery_duty, rescue_duty), from datatables/spacequest and tatooine_rebel_tier4.java; feature crimson-phoenix-tier4-ufwol-missions]==]
local NEW_CSP = OLD_CSP:gsub("%(no conversation yet%)", "(conversation ufwolConvoHandler)", 1)
local OLD_ULVAWOP = [==[-- Arnecio Ulvaw'op (Crimson Phoenix Squadron tier 3) conversation handler; ported from SWG-Source tatooine_rebel_tier3.java (JU). One-click, free-choice free training and the hand-off to General Ufwol (not ported yet): pre-NGE client lines (feature crimson-phoenix-tier3-ulvawop).]==]
local NEW_ULVAWOP = OLD_ULVAWOP:gsub("%(not ported yet%)", "(tier 4, ufwolConvoHandler)", 1)
local OLD_SOCUNA = [==[-- Commander Da'la Socuna (Crimson Phoenix Squadron tier 1, Mos Espa cantina) conversation handler; ported from SWG-Source tatooine_rebel_trainer_1.java with the pre-NGE client lines (feature crimson-phoenix-tier1-da-la-socuna). Training is one click per skill, free choice (pre-NGE); the promotion screen hands off to Major Eker (tier 2, not ported yet) through CrimsonPhoenixSquadronScreenplay.EKER_PILOT_KEY.]==]
local NEW_SOCUNA = OLD_SOCUNA:gsub("%(tier 2, not ported yet%)", "(tier 2, ekerConvoHandler)", 1)

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
	local exists, why = shell("git cat-file -e " .. BASE .. ":" .. path)

	lu.assertEquals(exists, 0, path .. " does not exist at " .. BASE .. " (a pinned path must name a real file): " .. why)

	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

TestUfwolConvoPins = {}

-- I-9: only the six files of the spec are modified under bin/ and src/; nothing is deleted, renamed or changed in mode
function TestUfwolConvoPins:test_only_the_six_files_of_the_spec_are_modified_from_the_base_under_bin_and_src()
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
function TestUfwolConvoPins:test_exactly_the_template_and_the_handler_are_added_under_bin_and_src()
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

-- I-9, Content contract 3: ufwol.lua differs only by the two lines (26 and 36)
function TestUfwolConvoPins:test_ufwol_lua_differs_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	local removed, added, hunks = changedLines(NPC)

	lu.assertEquals(hunks, 2, "hunks in ufwol.lua")
	lu.assertEquals(removed, { "\toptionsBitmask = AIENABLED + JTLINTERESTING,", '\tconversationTemplate = "",' }, "removed lines of ufwol.lua")
	lu.assertEquals(added, { "\toptionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", '\tconversationTemplate = "ufwol_convo_template",' }, "added lines of ufwol.lua")
end

-- I-9, Content contract 3: each include file differs only by one removed "--" (lines 82 and 127)
function TestUfwolConvoPins:test_each_include_file_differs_only_by_one_removed_comment_marker()
	requireBase()

	for path, line in pairs({
		[CONVOS] = 'includeFile("conversations/space/rebel/crimson_phoenix_squadron/ufwol_convo.lua")',
		[SCREENPLAYS] = 'includeFile("space/conversations/rebel/crimson_phoenix_squadron/ufwolConvoHandler.lua")',
	}) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { "--" .. line }, path .. ": removed lines")
		lu.assertEquals(added, { line }, path .. ": added lines")
	end
end

-- I-9, Content contract 3 (D-17): the squadron screenplay, Ulvaw'op's handler and Socuna's handler each differ by exactly their one comment line
function TestUfwolConvoPins:test_the_squadron_screenplay_and_the_two_handlers_differ_by_exactly_one_comment_line_each()
	requireBase()

	for path, change in pairs({ [CSP] = { OLD_CSP, NEW_CSP }, [ULVAWOP_HANDLER] = { OLD_ULVAWOP, NEW_ULVAWOP }, [SOCUNA_HANDLER] = { OLD_SOCUNA, NEW_SOCUNA } }) do
		local removed, added, hunks = changedLines(path)

		lu.assertEquals(hunks, 1, path .. ": hunks")
		lu.assertEquals(removed, { change[1] }, path .. ": removed lines")
		lu.assertEquals(added, { change[2] }, path .. ": added lines")
	end
end

-- I-9, Shared code changes: none: the helpers and the quest logic are untouched, nor is any quest-type screenplay
function TestUfwolConvoPins:test_the_helpers_the_quest_logic_and_every_quest_type_are_untouched()
	requireBase()

	for _, path in ipairs({ SH, SQL }) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE)
end

-- I-9: the other Crimson Phoenix trainers' templates and handlers, Eker's, Burke's and the master trainer files, Ufwol's spawn and Part A's pins file are byte-identical to the base
function TestUfwolConvoPins:test_the_other_trainers_burke_the_spawn_and_part_a_pins_are_unchanged()
	requireBase()

	local convos = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/"

	for _, path in ipairs({
		CRIMSON_HANDLERS .. "ekerConvoHandler.lua", convos .. "socuna_convo.lua", convos .. "eker_convo.lua", convos .. "ulvawop_convo.lua", ROOT .. "mobile/space/eker.lua",
		ROOT .. "mobile/space/da_la_socuna.lua", ROOT .. "mobile/space/arnecio_ulvaw_op.lua", ROOT .. "screenplays/cities/rori_rebel_outpost.lua",
		ROOT .. "screenplays/cities/corellia_doaba_guerfel.lua", ROOT .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		ROOT .. "mobile/conversations/space/rebel/willham_burke_convo.lua", ROOT .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua", PART_A_PINS,
	}) do
		identical(path)
	end
end

-- I-9: no C++ file changes
function TestUfwolConvoPins:test_no_cpp_or_idl_file_changes()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(changed), {}, "changed files under MMOCoreORB/src against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked files under MMOCoreORB/src")
end

-- the pin helper itself (a lesson of Part A): a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed; only the header before the
-- first @@ is skipped
function TestUfwolConvoPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
	local text = "--- a/x.lua\n+++ b/x.lua\n@@ -1 +1 @@\n--- old comment\n+-- new comment"
	local removed, added, hunks = parseDiff(text)

	lu.assertEquals(removed, { "-- old comment" }, "removed")
	lu.assertEquals(added, { "-- new comment" }, "added")
	lu.assertEquals(hunks, 1, "hunks")

	local r2, a2, h2 = parseDiff("--- a/x.lua\n+++ b/x.lua")

	lu.assertEquals({ r2, a2, h2 }, { {}, {}, 0 }, "a diff with a header and no hunk has no changed line")
end

-- the pin's own texts: the new comment lines differ from the old ones only by the spec's replacement
function TestUfwolConvoPins:test_the_expected_comment_lines_differ_from_the_old_ones_by_the_replacement_only()
	lu.assertNotEquals(NEW_CSP, OLD_CSP, "CSP:1132 changes")
	lu.assertNotEquals(NEW_ULVAWOP, OLD_ULVAWOP, "ulvawopConvoHandler.lua:1 changes")
	lu.assertNotEquals(NEW_SOCUNA, OLD_SOCUNA, "socunaConvoHandler.lua:1 changes")
	lu.assertEquals((NEW_CSP:gsub("%(conversation ufwolConvoHandler%)", "(no conversation yet)", 1)), OLD_CSP, "CSP:1132 differs by the parenthesis only")
	lu.assertEquals((NEW_ULVAWOP:gsub("%(tier 4, ufwolConvoHandler%)", "(not ported yet)", 1)), OLD_ULVAWOP, "ulvawopConvoHandler.lua:1 differs by the parenthesis only")
	lu.assertEquals((NEW_SOCUNA:gsub("%(tier 2, ekerConvoHandler%)", "(tier 2, not ported yet)", 1)), OLD_SOCUNA, "socunaConvoHandler.lua:1 differs by the parenthesis only")
end

-- the base names a real commit: the header says fbb648f5e5, the pin must not point at an older base by mistake
function TestUfwolConvoPins:test_the_base_is_the_part_a_commit()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	local _, subject = shell("git log -1 --format=%s " .. BASE)

	lu.assertStrContains(subject, "Crimson Phoenix tier 4 missions", false, "subject of " .. BASE)
end
