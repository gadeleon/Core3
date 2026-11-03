-- Smuggler transition: nothing else moves (I-10) and the two shared edits (SC-1, SC-2).
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (I-10, AC-9, AC-10; Shared code changes; Content contract 4).
--
-- The base is `git show 736ee36a22` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show
-- the base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "736ee36a22"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SPS = ROOT .. "screenplays/space/SpacePatrolScreenplay.lua"
local SSP = ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local KARRDE = ROOT .. "mobile/space/talon_karrde.lua"

local EXPECTED_FILES = {
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua",
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/talon_karrde.lua",
	ROOT .. "screenplays/space/SpacePatrolScreenplay.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua",
	ROOT .. "utils/space_helpers.lua",
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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }, hunks)
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

local function trimmed(list)
	local out = {}

	for i, l in ipairs(list) do
		out[i] = trim(l)
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

	return rc == 0, out
end

TestSmugglerTransPins = {}

-- SC-2, I-10: space_helpers.lua differs only by the two Smuggler reset lines
function TestSmugglerTransPins:test_space_helpers_differs_from_the_base_only_in_the_karrde_reset_lines()
	requireBase()

	local removed, added, hunks = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(trimmed(added), { "-- Transition", "SmugglerSquadronScreenplay:resetKarrdeQuests(pPlayer)" }, SH .. ": added lines (no nil guard, like the other squadrons)")
	lu.assertEquals(hunks, 1, SH .. ": one hunk (the Smuggler branch)")

	-- directly after the Dravis reset in the Smuggler branch
	local f = assert(io.open("bin/scripts/utils/space_helpers.lua", "r"))
	local all = {}

	for l in f:lines() do
		all[#all + 1] = trim(l)
	end

	f:close()

	local at

	for i, l in ipairs(all) do
		if l == "SmugglerSquadronScreenplay:resetDravisQuests(pPlayer)" then
			at = i
		end
	end

	lu.assertNotNil(at, SH .. ": the resetDravisQuests call")
	lu.assertEquals(all[at + 1] == "" and { all[at + 2], all[at + 3] } or { all[at + 1], all[at + 2] }, { "-- Transition", "SmugglerSquadronScreenplay:resetKarrdeQuests(pPlayer)" },
		SH .. ": the Karrde reset directly after the Dravis reset")
end

-- SC-1, I-10: SpacePatrolScreenplay.lua differs by one hunk that adds the completion call at the final-point branch and removes nothing
function TestSmugglerTransPins:test_the_patrol_quest_type_differs_from_the_base_only_by_the_final_point_completion()
	requireBase()

	local removed, added, hunks = changedLines(SPS)
	local code = nonBlank(added)
	local text = table.concat(code, "\n")

	lu.assertEquals(removed, {}, SPS .. ": removed lines")
	lu.assertEquals(hunks, 1, SPS .. ": hunks (the final-point branch of notifyEnteredQuestArea)")
	lu.assertTrue(#code <= 5, SPS .. ": at most 5 added lines, got " .. #code .. ": " .. text)
	lu.assertNotNil(text:find("PATROL_POINT", 1, true), SPS .. ": the new branch tests the split type against PATROL_POINT")
	lu.assertNotNil(text:find("completeQuest", 1, true), SPS .. ": the new branch calls completeQuest")
	lu.assertNotNil(text:find("sideQuest", 1, true), SPS .. ": the notify flag follows self.sideQuest")
end

-- I-10: the SmugglerSquadronScreenplay differs only by additions, apart from the header comment
function TestSmugglerTransPins:test_the_smuggler_squadron_file_only_gains_lines_except_in_its_header_comment()
	requireBase()

	local removed = changedLines(SSP)
	local _, header = shell("git show " .. BASE .. ":" .. SSP)
	local headerLines = {}

	for l in (header .. "\n"):gmatch("([^\n]*)\n") do
		headerLines[#headerLines + 1] = l
		if #headerLines >= 12 then
			break
		end
	end

	local inHeader = {}

	for _, l in ipairs(headerLines) do
		inHeader[l] = true
	end

	for _, l in ipairs(removed) do
		lu.assertTrue(inHeader[l] == true, SSP .. ": removed line outside the header comment: " .. l)
	end

	lu.assertTrue(#removed <= 3, SSP .. ": at most the header comment lines are rewritten, got " .. #removed)
end

-- I-10: space_conversations.lua gains the template include line and nothing else
function TestSmugglerTransPins:test_space_conversations_gains_only_the_karrde_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(nonBlank(added), { 'includeFile("conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua")' }, CONVERSATIONS .. ": added lines")
	lu.assertEquals(#added, 1, CONVERSATIONS .. ": no blank line besides the include")
end

-- I-10: screenplays.lua gains the handler include and nothing else
function TestSmugglerTransPins:test_screenplays_gains_only_the_karrde_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-10: talon_karrde.lua differs only by its two fields
function TestSmugglerTransPins:test_talon_karrde_differs_from_the_base_only_in_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(KARRDE)

	lu.assertEquals(#removed, 2, KARRDE .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, KARRDE .. ": added lines: " .. table.concat(added, " | "))

	table.sort(removed)
	table.sort(added)

	local rm = trimmed(removed)

	lu.assertEquals(rm[1]:match("^conversationTemplate = \"\",%s*%-%-TODO"), 'conversationTemplate = "",--TODO', KARRDE .. ": the replaced template line")
	lu.assertEquals(rm[2], "optionsBitmask = AIENABLED + JTLINTERESTING,", KARRDE .. ": the replaced mask line")

	local ad = trimmed(added)

	lu.assertNotNil(ad[1]:match('^conversationTemplate = "talon_karrde_convo_template",%s*%-%- Smuggler transition trainer %(tier 1 %-> 2%), SWG tatooine_privateer_trainer_2$'),
		KARRDE .. ": the new template line, got: " .. ad[1])
	lu.assertEquals(ad[2], "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", KARRDE .. ": the new mask line")
end

-- AC-9, I-10: Dravis' three files are byte-identical
function TestSmugglerTransPins:test_dravis_files_are_byte_identical_to_the_base()
	requireBase()

	for _, path in ipairs({
		ROOT .. "mobile/space/dravis.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/dravis_convo.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua",
	}) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-10: the other squadron files are byte-identical
function TestSmugglerTransPins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		local path = ROOT .. "screenplays/space/squadrons/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-10: only the eight files of the spec differ under bin/ and src/
function TestSmugglerTransPins:test_only_the_eight_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-10: every quest type but the patrol, the broker, the master trainers and every other trainer and NPC are untouched
function TestSmugglerTransPins:test_the_other_quest_types_the_brokers_the_trainers_and_the_other_npcs_are_untouched()
	requireBase()

	local paths = {
		ROOT .. "screenplays/space/SpaceQuestLogic.lua",
		ROOT .. "screenplays/space/SpaceDestroyScreenplay.lua",
		ROOT .. "screenplays/space/SpaceEscortScreenplay.lua",
		ROOT .. "screenplays/space/SpaceAssassinateScreenplay.lua",
		ROOT .. "screenplays/space/SpaceDutyRecoveryScreenplay.lua",
		ROOT .. "screenplays/space/conversations/imperial",
		ROOT .. "screenplays/space/conversations/rebel",
		ROOT .. "screenplays/space/conversations/neutral/corsec_squadron",
		ROOT .. "screenplays/space/conversations/neutral/rsf_squadron",
		ROOT .. "screenplays/space/conversations/neutral/gilBurtinConvoHandler.lua",
		ROOT .. "mobile/conversations/space/neutral/corsec_squadron",
		ROOT .. "mobile/conversations/space/neutral/rsf_squadron",
		ROOT .. "mobile/conversations/space/rebel",
		ROOT .. "mobile/conversations/space/imperial",
		ROOT .. "mobile/space/dravis.lua",
		ROOT .. "mobile/space/shamdon_kree.lua",
		ROOT .. "mobile/space/nirame_sakute.lua",
		ROOT .. "mobile/space/smuggler_pilot.lua",
		ROOT .. "screenplays/cities/tatooine_mos_eisley.lua",
	}

	for _, path in ipairs(paths) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end

	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin/scripts/ship_mobile' ':/MMOCoreORB/src'")

	lu.assertEquals(lines(untracked), {}, "new files under ship_mobile or src (no ship, point or C++ change in this feature)")
end
