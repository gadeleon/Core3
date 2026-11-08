-- Crimson Phoenix tier 4 part A (General Ufwol's missions): nothing else moves (I-9).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol-missions/01-spec.md (I-9, A-1, A-6, A-7; Content contract 1 to 3; Shared code changes SC-1; D-12).
--
-- The base is `git show 9f1d5ca210` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (crimson-phoenix-tier4-ufwol)
-- pins its own base in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "9f1d5ca210"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"

-- the only files under bin/ and src/ that may differ from the base: both modified, none added (I-9)
local CHANGED_FILES = { CSP, SH }

local GLOBALS = {
	"space_battle_tatooine_rebel_tier4_1", "assassinate_tatooine_rebel_tier4_1_a", "patrol_tatooine_rebel_tier4_1_b", "destroy_surpriseattack_tatooine_rebel_tier4_1_c",
	"recovery_tatooine_rebel_tier4_2", "delivery_tatooine_rebel_tier4_2_a", "survival_tatooine_rebel_tier4_2_b",
	"space_battle_tatooine_rebel_tier4_3", "assassinate_tatooine_rebel_tier4_3_a", "assassinate_tatooine_rebel_tier4_3_b",
	"assassinate_tatooine_rebel_tier4_4", "survival_tatooine_rebel_tier4_4_a", "space_battle_tatooine_rebel_tier4_4_b",
	"destroy_duty_tatooine_rebel_tier4_1", "escort_duty_tatooine_rebel_tier4_1", "recovery_duty_tatooine_rebel_tier4_1", "rescue_duty_tatooine_rebel_tier4_1",
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

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

local function allLines(text)
	local out = {}

	for line in (text .. "\n"):gmatch("(.-)\n") do
		out[#out + 1] = line
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

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

-- the working-tree text (the runner's working directory is MMOCoreORB/)
local function readWorking(path)
	local f = assert(io.open("bin/scripts/" .. path:gsub("^MMOCoreORB/bin/scripts/", ""), "r"), "working tree file " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function baseText(path)
	local rc, out = shell("git show " .. BASE .. ":" .. path)

	lu.assertEquals(rc, 0, "git show " .. BASE .. ":" .. path .. " failed: " .. out)
	return out
end

-- the index of the first line equal (trimmed) to `wanted`
local function indexOf(list, wanted, from)
	for i = from or 1, #list do
		if trim(list[i]) == wanted then
			return i
		end
	end
end

-- The top-level `function <Prefix>:name(` blocks of a file: header (text before the first block) and name -> text of the block (up to the next top-level block or
-- the end of the file), plus the order of the names
local function functionBlocks(text, prefix)
	local header, blocks, order = {}, {}, {}
	local current

	for _, l in ipairs(allLines(text)) do
		local name = l:match("^function " .. prefix .. ":([%w_]+)%(")

		if name ~= nil then
			current = name
			blocks[name] = {}
			order[#order + 1] = name
		end

		table.insert(current and blocks[current] or header, l)
	end

	for name, list in pairs(blocks) do
		blocks[name] = table.concat(list, "\n")
	end

	return table.concat(header, "\n"), blocks, order
end

TestUfwolPins = {}

-- I-9: only the two files of the spec differ under bin/ and src/ (CSP and SH; no new production file, no C++ change)
function TestUfwolPins:test_only_the_squadron_file_and_space_helpers_differ_from_the_base_under_bin_and_src_and_none_is_added()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, other = shell("git diff --name-only --diff-filter=ADRCTUXB " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed)
	local expected = {}

	for _, f in ipairs(CHANGED_FILES) do
		expected[#expected + 1] = f
	end

	table.sort(files)
	table.sort(expected)
	lu.assertEquals(files, expected, "modified files under bin/ and src/ against " .. BASE)
	lu.assertEquals(lines(other), {}, "added, deleted or renamed files under bin/ and src/ against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked (new) production files under bin/ and src/")
end

-- I-9: the squadron file differs by additions only, in three hunks (the tables, the constants and the met key, the reset)
function TestUfwolPins:test_the_squadron_file_differs_from_the_base_by_additions_only_in_three_hunks()
	requireBase()

	local removed, added, hunks = changedLines(CSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, CSP .. ": removed lines (additions only)")
	lu.assertEquals(hunks, 3, CSP .. ": hunks (the tables after the tier 3 tables, the constants after TIER3_QUEST_STRING_4_SIDE4, the reset at the end)")
	contains(text, 'TIER4_QUEST_STRING_1 = {type = "space_battle", name = "tatooine_rebel_tier4_1"},', CSP .. ": constant 1")
	contains(text, 'TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "tatooine_rebel_tier4_1"},', CSP .. ": the last constant")
	contains(text, 'TIER4_MET_KEY = "CrimsonPhoenixSquadronScreenplay:metTier4",', CSP .. ": the met key")
	contains(text, "function CrimsonPhoenixSquadronScreenplay:resetUfwolQuests(pPlayer)", CSP .. ": the reset")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', CSP .. ": " .. global)
	end
end

-- I-9, Content contract 1 and 2: where the additions sit in the squadron file
function TestUfwolPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(CSP))
	local lastTier3 = indexOf(list, 'registerScreenPlay("space_battle_tatooine_rebel_tier3_4_d", true)')
	local section = indexOf(list, "Tier 4 -- General Ufwol (Rori, Rebel outpost; Dathomir, Endor, Yavin 4 and Dantooine systems)")
	local first = indexOf(list, 'registerScreenPlay("space_battle_tatooine_rebel_tier4_1", true)')
	local last = indexOf(list, 'registerScreenPlay("rescue_duty_tatooine_rebel_tier4_1", true)')
	local object = indexOf(list, "CrimsonPhoenixSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier3, "the last tier 3 registration")
	lu.assertNotNil(section, "the section comment 'Tier 4 -- General Ufwol (Rori, Rebel outpost; ...)'")
	lu.assertNotNil(first, "the first tier 4 registration")
	lu.assertNotNil(last, "the last tier 4 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier3 < section and section < first and first < last and last < object, "order: tier 3's last table, the section comment, the 17 tier 4 tables, the squadron object")
	lu.assertEquals(list[lastTier3 + 1], "", "a blank line after tier 3's last registration")
	lu.assertEquals(trim(list[lastTier3 + 2]), "--[[", "the section comment opens directly after the blank line")

	-- the 17 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the constants directly after TIER3_QUEST_STRING_4_SIDE4, under a blank line and the comment; the met key block, then the EKER_PILOT_KEY lines follow
	local side4 = indexOf(list, 'TIER3_QUEST_STRING_4_SIDE4 = {type = "space_battle", name = "tatooine_rebel_tier3_4_d"},')

	lu.assertNotNil(side4, "TIER3_QUEST_STRING_4_SIDE4")
	lu.assertEquals(list[side4 + 1], "", "a blank line after TIER3_QUEST_STRING_4_SIDE4")
	contains(trim(list[side4 + 2]), "-- Tier 4 (Ufwol); N is the trainer script's mission number", "the comment after the blank line")
	lu.assertEquals(trim(list[side4 + 3]), 'TIER4_QUEST_STRING_1 = {type = "space_battle", name = "tatooine_rebel_tier4_1"},', "the first constant")
	lu.assertEquals(trim(list[side4 + 19]), 'TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "tatooine_rebel_tier4_1"},', "the seventeenth constant")
	lu.assertEquals(list[side4 + 20], "", "a blank line before the met key comment")
	contains(trim(list[side4 + 21]), "-- Set by Ufwol's first-meeting reply", "the met key comment")
	lu.assertEquals(trim(list[side4 + 22]), 'TIER4_MET_KEY = "CrimsonPhoenixSquadronScreenplay:metTier4",', "the met key")
	lu.assertEquals(list[side4 + 23], "", "a blank line before the EKER_PILOT_KEY comment")
	lu.assertEquals(trim(list[side4 + 25]), 'EKER_PILOT_KEY = "CrimsonPhoenixSquadronScreenplay:ekerPilot",', "EKER_PILOT_KEY stays")

	-- the reset directly at the end of the file, after resetUlvawopQuests
	local ulvawop = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)")
	local ufwol = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetUfwolQuests(pPlayer)")

	lu.assertNotNil(ulvawop, "resetUlvawopQuests")
	lu.assertNotNil(ufwol, "resetUfwolQuests")
	lu.assertTrue(ulvawop < ufwol, "resetUfwolQuests sits after resetUlvawopQuests")
	lu.assertEquals(trim(list[ufwol - 1]), "-- Clears General Ufwol's quests, journal entries and keys (surrender)", "the reset's comment")

	for i = ufwol + 1, #list do
		lu.assertTrue(trim(list[i]) == "" or list[i]:find("^[\t ]") ~= nil or list[i] == "end", "resetUfwolQuests is the last function: line " .. i .. " '" .. list[i] .. "'")
	end
end

-- I-9, SC-1: space_helpers.lua gains the blank line, the comment and the one reset call after Ulvaw'op's reset, and nothing else
function TestUfwolPins:test_space_helpers_gains_only_the_tier_4_lines_in_the_crimson_phoenix_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 4", "CrimsonPhoenixSquadronScreenplay:resetUfwolQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local ulvawop = indexOf(list, "CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)")

	lu.assertNotNil(ulvawop, "Ulvaw'op's reset call")
	lu.assertEquals(list[ulvawop + 1], "", "a blank line after Ulvaw'op's reset")
	lu.assertEquals(list[ulvawop + 2], "\t\t-- Tier 4", "the comment")
	lu.assertEquals(list[ulvawop + 3], "\t\tCrimsonPhoenixSquadronScreenplay:resetUfwolQuests(pPlayer)", "Ufwol's reset")
end

-- I-9: Part B's files, the other trainers, the other squadrons, the points and spawners and every quest-type screenplay (shared logic included) are byte-identical to the base
function TestUfwolPins:test_part_b_files_the_other_squadrons_and_every_quest_type_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local crimson = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/"

	for _, path in ipairs({
		crimson .. "socunaConvoHandler.lua", crimson .. "ekerConvoHandler.lua", crimson .. "ulvawopConvoHandler.lua",
		convos .. "socuna_convo.lua", convos .. "eker_convo.lua", convos .. "ulvawop_convo.lua",
		ROOT .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		ROOT .. "mobile/space/ufwol.lua", ROOT .. "mobile/space/arnecio_ulvaw_op.lua", ROOT .. "mobile/space/eker.lua", ROOT .. "mobile/space/da_la_socuna.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/cities/rori_rebel_outpost.lua", ROOT .. "screenplays/cities/dathomir_science_outpost.lua",
		ROOT .. "ship_mobile/patrol_points/space_dathomir.lua", ROOT .. "ship_mobile/patrol_points/space_dantooine.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua",
		ROOT .. "ship_mobile/patrol_points/space_yavin4.lua",
		ROOT .. "screenplays/space/spawning/space_dathomir_spawner.lua", ROOT .. "screenplays/space/spawning/space_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE .. " (none: deliveryZone and the zone-switch start already exist)")

	local _, ships = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "ship_mobile"))

	lu.assertEquals(lines(ships), {}, "ship templates and patrol point files that differ from " .. BASE)
end

return nil
