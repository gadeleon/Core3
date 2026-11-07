-- Crimson Phoenix tier 2 part A (Major Eker's missions): nothing else moves (I-10).
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (I-10, A-1; Content contract 1 to 3; Shared code changes SC-1, SC-2).
--
-- The base is `git show 02666328b3` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (crimson-phoenix-tier2-eker-convo)
-- pins its own base in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "02666328b3"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"

local SHIPS = {
	["yavin_mission_2_shuttle"] = { cargo = "patrol_routes", questLoot = "yavin_mission_2" },
	["yavin_mission_3_shuttle"] = { cargo = "bomb_trigger", questLoot = "yavin_mission_3" },
}

local function shipPath(name) return ROOT .. "ship_mobile/ships/" .. name .. ".lua" end

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added (I-10)
local CHANGED_FILES = { CSP, SH, shipPath("yavin_mission_2_shuttle"), shipPath("yavin_mission_3_shuttle") }

local GLOBALS = {
	"escort_yavin_rebel_13", "inspect_yavin_rebel_14", "inspect_yavin_rebel_15", "destroy_surpriseattack_yavin_rebel_15", "escort_yavin_rebel_16",
	"recovery_duty_yavin_rebel_12", "escort_duty_yavin_rebel_10", "destroy_duty_yavin_rebel_9",
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

TestEkerPins = {}

-- I-10: only the four files of the spec differ under bin/ and src/ (no new production file, no C++ change)
function TestEkerPins:test_only_the_four_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-10, A-1: the squadron file differs only by additions: the section comment, the 8 tier 2 tables, the 8 constants and the reset
function TestEkerPins:test_the_squadron_file_differs_from_the_base_only_by_additions()
	requireBase()

	local removed, added = changedLines(CSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, CSP .. ": removed lines (additions only)")
	contains(text, 'TIER2_QUEST_STRING_1 = {type = "escort", name = "yavin_rebel_13"},', CSP .. ": constant 1")
	contains(text, 'TIER2_QUEST_STRING_3_SIDE = {type = "destroy_surpriseattack", name = "yavin_rebel_15"},', CSP .. ": the side constant")
	contains(text, 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "yavin_rebel_9"},', CSP .. ": the last constant")
	contains(text, "function CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)", CSP .. ": the reset")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', CSP .. ": " .. global)
	end
end

-- I-10, Content contract 1 and 2: where the additions sit in the squadron file
function TestEkerPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(CSP))
	local lastTier1 = indexOf(list, 'registerScreenPlay("escort_duty_tatooine_rebel_7", true)')
	local section = indexOf(list, "Tier 2 -- Major Eker (Yavin 4, labor outpost; Yavin 4 and Lok systems)")
	local first = indexOf(list, 'registerScreenPlay("escort_yavin_rebel_13", true)')
	local last = indexOf(list, 'registerScreenPlay("destroy_duty_yavin_rebel_9", true)')
	local object = indexOf(list, "CrimsonPhoenixSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier1, "the last tier 1 registration")
	lu.assertNotNil(section, "the section comment 'Tier 2 -- Major Eker (Yavin 4, labor outpost; Yavin 4 and Lok systems)'")
	lu.assertNotNil(first, "the first tier 2 registration")
	lu.assertNotNil(last, "the last tier 2 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier1 < section and section < first and first < last and last < object, "order: tier 1's last table, the section comment, the 8 tier 2 tables, the squadron object")

	-- the 8 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the constants directly after QUEST_STRING_DUTY_2, under a blank line and the comment; the EKER_PILOT_KEY lines stay where they were
	local duty2 = indexOf(list, 'QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "tatooine_rebel_7"},')

	lu.assertNotNil(duty2, "QUEST_STRING_DUTY_2")
	lu.assertEquals(list[duty2 + 1], "", "a blank line after QUEST_STRING_DUTY_2")
	lu.assertEquals(trim(list[duty2 + 2]), "-- Tier 2 (Eker); N is the trainer script's mission number", "the comment after the blank line")
	lu.assertEquals(trim(list[duty2 + 3]), 'TIER2_QUEST_STRING_1 = {type = "escort", name = "yavin_rebel_13"},', "the first constant")
	lu.assertEquals(trim(list[duty2 + 10]), 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "yavin_rebel_9"},', "the eighth constant")
	lu.assertEquals(list[duty2 + 11], "", "a blank line before the EKER_PILOT_KEY comment")
	lu.assertEquals(trim(list[duty2 + 13]), 'EKER_PILOT_KEY = "CrimsonPhoenixSquadronScreenplay:ekerPilot",', "EKER_PILOT_KEY stays")

	-- the reset directly at the end of the file, after resetSocunaQuests
	local socuna = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(pPlayer)")
	local eker = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)")

	lu.assertNotNil(socuna, "resetSocunaQuests")
	lu.assertNotNil(eker, "resetEkerQuests")
	lu.assertTrue(socuna < eker, "resetEkerQuests sits after resetSocunaQuests")
	lu.assertEquals(trim(list[eker - 1]), "-- Clears Major Eker's quests, journal entries and keys (surrender)", "the reset's comment")

	for i = eker + 1, #list do
		lu.assertTrue(trim(list[i]) == "" or list[i]:find("^[\t ]") ~= nil or list[i] == "end", "resetEkerQuests is the last function: line " .. i .. " '" .. list[i] .. "'")
	end
end

-- I-10, SC-2: space_helpers.lua gains the blank line, the comment and the one reset call after Socuna's reset, and nothing else
function TestEkerPins:test_space_helpers_gains_only_the_tier_2_lines_in_the_crimson_phoenix_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 2", "CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local socuna = indexOf(list, "CrimsonPhoenixSquadronScreenplay:resetSocunaQuests(pPlayer)")

	lu.assertNotNil(socuna, "Socuna's reset call")
	lu.assertEquals(list[socuna + 1], "", "a blank line after Socuna's reset")
	lu.assertEquals(list[socuna + 2], "\t\t-- Tier 2", "the comment")
	lu.assertEquals(list[socuna + 3], "\t\tCrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)", "Eker's reset")
end

-- I-10, SC-1: each of the two shuttle templates gains the one cargoString line directly after questLoot, and nothing else
function TestEkerPins:test_the_two_shuttle_templates_gain_only_the_cargo_string_line_after_the_quest_loot()
	requireBase()

	for name, info in pairs(SHIPS) do
		local path = shipPath(name)
		local removed, added = changedLines(path)

		lu.assertEquals(removed, {}, name .. ": removed lines")
		lu.assertEquals(#added, 1, name .. ": added lines: " .. table.concat(added, " | "))
		contains(added[1] or "", 'cargoString = "' .. info.cargo .. '",', name .. ": the added line")

		local list = allLines(readWorking(path))
		local loot = indexOf(list, 'questLoot = "' .. info.questLoot .. '",')

		lu.assertNotNil(loot, name .. ": the questLoot line")
		contains(list[loot + 1] or "", 'cargoString = "' .. info.cargo .. '",', name .. ": directly after questLoot")
	end
end

-- I-10: Part B's files, the other trainers, the other squadrons, the points and spawners and every quest-type screenplay (shared logic included) are byte-identical to the base
function TestEkerPins:test_part_b_files_the_other_squadrons_and_every_quest_type_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local crimson = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/"

	for _, path in ipairs({
		crimson .. "socunaConvoHandler.lua", convos .. "socuna_convo.lua", ROOT .. "mobile/space/eker.lua", ROOT .. "mobile/space/da_la_socuna.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/cities/yavin4_labor_outpost.lua",
		ROOT .. "ship_mobile/patrol_points/space_lok.lua", ROOT .. "ship_mobile/patrol_points/space_yavin4.lua",
		ROOT .. "screenplays/space/spawning/space_lok_spawner.lua", ROOT .. "screenplays/space/spawning/space_yavin4_spawner.lua",
		ROOT .. "screenplays/space/spawning/space_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE .. " (none: the INSPECTION split is already shared)")
end

return nil
