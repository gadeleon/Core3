-- Crimson Phoenix tier 3 part A (Arnecio Ulvaw'op's missions): nothing else moves (I-9).
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop-missions/01-spec.md (I-9, A-1, A-5; Content contract 1 to 4; Shared code changes SC-1, SC-2; D-8).
--
-- The base is `git show 2d26b3e0a3` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (crimson-phoenix-tier3-ulvawop)
-- pins its own base in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "2d26b3e0a3"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CSP = ROOT .. "screenplays/space/squadrons/CrimsonPhoenixSquadronScreenplay.lua"

local SUSPECTS = { "tatooine_tier3_2_inspect_awing", "tatooine_tier3_2_inspect_bwing", "tatooine_tier3_2_inspect_xwing", "tatooine_tier3_2_inspect_ywing" }

local CARGO_LINE = '\tcargoString = "thermal_bomb", -- SWG space_mobile cargo tatooine_tier3_2_inspect (inspect_cargo row thermal_bomb, 2 of 7 rows); inspect quest tatooine_rebel_tier3_2 (feature crimson-phoenix-tier3-ulvawop-missions)'

local function shipPath(name) return ROOT .. "ship_mobile/ships/" .. name .. ".lua" end

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added (I-9)
local CHANGED_FILES = { CSP, SH }

for _, name in ipairs(SUSPECTS) do
	CHANGED_FILES[#CHANGED_FILES + 1] = shipPath(name)
end

local GLOBALS = {
	"recovery_tatooine_rebel_tier3_1", "delivery_tatooine_rebel_tier3_1_a", "survival_tatooine_rebel_tier3_1_b", "escort_tatooine_rebel_tier3_1_c",
	"inspect_tatooine_rebel_tier3_2", "destroy_surpriseattack_tatooine_rebel_tier3_2_a", "assassinate_tatooine_rebel_tier3_2_b", "space_battle_tatooine_rebel_tier3_2_c",
	"delivery_tatooine_rebel_tier3_3", "space_battle_tatooine_rebel_tier3_3_a", "escort_tatooine_rebel_tier3_3_b", "survival_tatooine_rebel_tier3_3_c",
	"assassinate_tatooine_rebel_tier3_4", "patrol_tatooine_rebel_tier3_4_a", "destroy_surpriseattack_tatooine_rebel_tier3_4_b",
	"delivery_no_pickup_tatooine_rebel_tier3_4_c", "space_battle_tatooine_rebel_tier3_4_d",
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

TestUlvawopPins = {}

-- I-9: only the six files of the spec differ under bin/ and src/ (CSP, SH and the four suspect ships; no new production file, no C++ change)
function TestUlvawopPins:test_only_the_six_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-9, D-8: the squadron file differs by additions plus exactly the two comment lines of Content contract 2 (CSP:268 and CSP:581)
function TestUlvawopPins:test_the_squadron_file_differs_from_the_base_by_additions_and_the_two_comment_lines()
	requireBase()

	local removed, added = changedLines(CSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(#removed, 2, CSP .. ": removed lines (the two stale comments only): " .. table.concat(removed, " | "))

	local header, flag
	for _, l in ipairs(removed) do
		if l:find("Trainer: Major Eker (no conversation yet)", 1, true) then
			header = l
		elseif l:find("ekerPilot space flag", 1, true) then
			flag = l
		end
	end

	lu.assertNotNil(header, CSP .. ": the removed tier 2 header line (CSP:268)")
	lu.assertNotNil(flag, CSP .. ": the removed EKER_PILOT_KEY comment (CSP:581)")
	lu.assertEquals(flag, '\t-- SWG\'s ekerPilot space flag ("1" from Da\'la Socuna; tier 2 reads it as set and writes "2")', "the removed CSP:581 line")

	-- CSP:268: only "(no conversation yet)" becomes "(conversation ekerConvoHandler)"; the rest of the line is byte-identical
	local newHeader = header:gsub("%(no conversation yet%)", "(conversation ekerConvoHandler)", 1)

	contains(text, newHeader, CSP .. ": the corrected tier 2 header line")
	contains(text, '\t-- SWG\'s ekerPilot space flag ("1" from Da\'la Socuna; Major Eker reads it as set and writes "2" on the hand-in and "3" with mission 4\'s reward; tier 3 reads it as set)', CSP .. ": the corrected EKER_PILOT_KEY comment")
	contains(text, 'TIER3_QUEST_STRING_1 = {type = "recovery", name = "tatooine_rebel_tier3_1"},', CSP .. ": constant 1")
	contains(text, 'TIER3_QUEST_STRING_4_SIDE4 = {type = "space_battle", name = "tatooine_rebel_tier3_4_d"},', CSP .. ": the last constant")
	contains(text, "function CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)", CSP .. ": the reset")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', CSP .. ": " .. global)
	end
end

-- I-9, Content contract 1 and 3: where the additions sit in the squadron file
function TestUlvawopPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(CSP))
	local lastTier2 = indexOf(list, 'registerScreenPlay("destroy_duty_yavin_rebel_9", true)')
	local section = indexOf(list, "Tier 3 -- Arnecio Ulvaw'op (Dathomir, science outpost; Dathomir, Dantooine, Lok and Endor systems)")
	local first = indexOf(list, 'registerScreenPlay("recovery_tatooine_rebel_tier3_1", true)')
	local last = indexOf(list, 'registerScreenPlay("space_battle_tatooine_rebel_tier3_4_d", true)')
	local object = indexOf(list, "CrimsonPhoenixSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier2, "the last tier 2 registration")
	lu.assertNotNil(section, "the section comment 'Tier 3 -- Arnecio Ulvaw'op (Dathomir, science outpost; ...)'")
	lu.assertNotNil(first, "the first tier 3 registration")
	lu.assertNotNil(last, "the last tier 3 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier2 < section and section < first and first < last and last < object, "order: tier 2's last table, the section comment, the 17 tier 3 tables, the squadron object")

	-- the 17 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the constants directly after TIER2_QUEST_STRING_DUTY_3, under a blank line and the comment; the EKER_PILOT_KEY lines follow
	local duty3 = indexOf(list, 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "yavin_rebel_9"},')

	lu.assertNotNil(duty3, "TIER2_QUEST_STRING_DUTY_3")
	lu.assertEquals(list[duty3 + 1], "", "a blank line after TIER2_QUEST_STRING_DUTY_3")
	lu.assertEquals(trim(list[duty3 + 2]), "-- Tier 3 (Ulvaw'op); N is the trainer script's mission number", "the comment after the blank line")
	lu.assertEquals(trim(list[duty3 + 3]), 'TIER3_QUEST_STRING_1 = {type = "recovery", name = "tatooine_rebel_tier3_1"},', "the first constant")
	lu.assertEquals(trim(list[duty3 + 19]), 'TIER3_QUEST_STRING_4_SIDE4 = {type = "space_battle", name = "tatooine_rebel_tier3_4_d"},', "the seventeenth constant")
	lu.assertEquals(list[duty3 + 20], "", "a blank line before the EKER_PILOT_KEY comment")
	lu.assertEquals(trim(list[duty3 + 22]), 'EKER_PILOT_KEY = "CrimsonPhoenixSquadronScreenplay:ekerPilot",', "EKER_PILOT_KEY stays")

	-- the reset directly at the end of the file, after resetEkerQuests
	local eker = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)")
	local ulvawop = indexOf(list, "function CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)")

	lu.assertNotNil(eker, "resetEkerQuests")
	lu.assertNotNil(ulvawop, "resetUlvawopQuests")
	lu.assertTrue(eker < ulvawop, "resetUlvawopQuests sits after resetEkerQuests")
	lu.assertEquals(trim(list[ulvawop - 1]), "-- Clears Arnecio Ulvaw'op's quests, journal entries and keys (surrender)", "the reset's comment")

	for i = ulvawop + 1, #list do
		lu.assertTrue(trim(list[i]) == "" or list[i]:find("^[\t ]") ~= nil or list[i] == "end", "resetUlvawopQuests is the last function: line " .. i .. " '" .. list[i] .. "'")
	end
end

-- I-9, SC-2: space_helpers.lua gains the blank line, the comment and the one reset call after Eker's reset, and nothing else
function TestUlvawopPins:test_space_helpers_gains_only_the_tier_3_lines_in_the_crimson_phoenix_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 3", "CrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local eker = indexOf(list, "CrimsonPhoenixSquadronScreenplay:resetEkerQuests(pPlayer)")

	lu.assertNotNil(eker, "Eker's reset call")
	lu.assertEquals(list[eker + 1], "", "a blank line after Eker's reset")
	lu.assertEquals(list[eker + 2], "\t\t-- Tier 3", "the comment")
	lu.assertEquals(list[eker + 3], "\t\tCrimsonPhoenixSquadronScreenplay:resetUlvawopQuests(pPlayer)", "Ulvaw'op's reset")
end

-- I-9, SC-1: each of the four suspect templates gains the one cargoString line directly after questLoot, and nothing else
function TestUlvawopPins:test_the_four_suspect_templates_gain_only_the_cargo_string_line_after_the_quest_loot()
	requireBase()

	for _, name in ipairs(SUSPECTS) do
		local path = shipPath(name)
		local removed, added = changedLines(path)

		lu.assertEquals(removed, {}, name .. ": removed lines")
		lu.assertEquals(added, { CARGO_LINE }, name .. ": added lines")

		local list = allLines(readWorking(path))
		local loot = indexOf(list, 'questLoot = "tatooine_tier3_2_inspect",')

		lu.assertNotNil(loot, name .. ": the questLoot line")
		lu.assertEquals(list[loot + 1], CARGO_LINE, name .. ": directly after questLoot")
	end
end

-- I-9: Part B's files, the other trainers, the other squadrons, the points and spawners and every quest-type screenplay (shared logic included) are byte-identical to the base
function TestUlvawopPins:test_part_b_files_the_other_squadrons_and_every_quest_type_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "VortexSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local crimson = ROOT .. "screenplays/space/conversations/rebel/crimson_phoenix_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/crimson_phoenix_squadron/"

	for _, path in ipairs({
		crimson .. "socunaConvoHandler.lua", crimson .. "ekerConvoHandler.lua", convos .. "socuna_convo.lua", convos .. "eker_convo.lua",
		ROOT .. "mobile/space/arnecio_ulvaw_op.lua", ROOT .. "mobile/space/eker.lua", ROOT .. "mobile/space/da_la_socuna.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/cities/dathomir_science_outpost.lua",
		ROOT .. "ship_mobile/patrol_points/space_dathomir.lua", ROOT .. "ship_mobile/patrol_points/space_dantooine.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua",
		ROOT .. "ship_mobile/patrol_points/space_lok.lua",
		ROOT .. "screenplays/space/spawning/space_dathomir_spawner.lua", ROOT .. "screenplays/space/spawning/space_spawner.lua",
		ROOT .. "ship_mobile/ships/reb_awing_tier4.lua", ROOT .. "ship_mobile/ships/reb_bwing_tier4.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE .. " (none: deliveryZone and the zone-switch start already exist)")
end

return nil
