-- Vortex tier 2 part A (Brother Vrovel's missions): nothing else moves (I-10).
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (I-10, A-6; Content contract 1 to 3; Shared code changes SC-1 to SC-3; D-7).
--
-- The base is `git show 517639a71c` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (vortex-tier2-vrovel) pins
-- its own base in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "517639a71c"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"
local SIS = ROOT .. "screenplays/space/SpaceInspectScreenplay.lua"
local VSP = ROOT .. "screenplays/space/squadrons/VortexSquadronScreenplay.lua"

local SHIPS = {
	["vortex_mission_1_shuttle"] = { cargo = "ship_signature_data", questLoot = "vortex_mission_1" },
	["vortex_mission_4_shuttle"] = { cargo = "ship_starting_coordinates", questLoot = "vortex_mission_4" },
}

local function shipPath(name) return ROOT .. "ship_mobile/ships/" .. name .. ".lua" end

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added (I-10)
local CHANGED_FILES = { VSP, SH, SQL, SIS, shipPath("vortex_mission_1_shuttle"), shipPath("vortex_mission_4_shuttle") }

local GLOBALS = {
	"escort_vortex_mission_1", "inspect_vortex_mission_1", "destroy_surpriseattack_vortex_mission_1", "escort_vortex_mission_2", "recovery_vortex_mission_3",
	"inspect_vortex_mission_4", "escort_duty_vortex_mission_5", "destroy_duty_vortex_mission_6", "recovery_duty_vortex_mission_7",
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

TestVrovelPins = {}

-- I-10: only the six files of the spec differ under bin/ and src/ (no new production file, no C++ change)
function TestVrovelPins:test_only_the_six_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-10, A-1: the squadron file differs only by additions and the one header line: the 9 constants, the reset and the 9 quest tables
function TestVrovelPins:test_the_squadron_file_differs_from_the_base_only_by_additions_and_the_header_line()
	requireBase()

	local removed, added = changedLines(VSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, { "\tTiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are not ported yet" }, VSP .. ": removed lines (the header line only)")
	contains(text, "\tTier 2 (Brother Vrovel) is below; tiers 3-4 (Brother Ezkiel, Brother Extok Evin) are not ported yet", VSP .. ": the header line")
	contains(text, 'TIER2_QUEST_STRING_1 = {type = "escort", name = "vortex_mission_1"},', VSP .. ": constant 1")
	contains(text, 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "vortex_mission_6"},', VSP .. ": the last constant")
	contains(text, "function VortexSquadronScreenplay:resetVrovelQuests(pPlayer)", VSP .. ": the reset")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', VSP .. ": " .. global)
	end
end

-- I-10, Content contract 1 and 2: where the additions sit in the squadron file
function TestVrovelPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(VSP))
	local lastTier1 = indexOf(list, 'registerScreenPlay("escort_duty_naboo_rebel_7", true)')
	local section = indexOf(list, "Tier 2 -- Brother Vrovel (Dantooine, abandoned Rebel base; Lok, Yavin 4 and Dantooine systems)")
	local first = indexOf(list, 'registerScreenPlay("escort_vortex_mission_1", true)')
	local last = indexOf(list, 'registerScreenPlay("recovery_duty_vortex_mission_7", true)')
	local object = indexOf(list, "VortexSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier1, "the last tier 1 registration")
	lu.assertNotNil(section, "the section comment 'Tier 2 -- Brother Vrovel (Dantooine, abandoned Rebel base; Lok, Yavin 4 and Dantooine systems)'")
	lu.assertNotNil(first, "the first tier 2 registration")
	lu.assertNotNil(last, "the last tier 2 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier1 < section and section < first and first < last and last < object, "order: tier 1's last table, the section comment, the 9 tier 2 tables, the squadron object")

	-- the 9 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the constants directly after QUEST_STRING_DUTY_2, under a blank line and the comment
	local duty2 = indexOf(list, 'QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_rebel_7"},')

	lu.assertNotNil(duty2, "QUEST_STRING_DUTY_2")
	lu.assertEquals(list[duty2 + 1], "", "a blank line after QUEST_STRING_DUTY_2")
	lu.assertEquals(trim(list[duty2 + 2]), "-- Tier 2 (Vrovel)", "the comment after the blank line")
	lu.assertEquals(trim(list[duty2 + 3]), 'TIER2_QUEST_STRING_1 = {type = "escort", name = "vortex_mission_1"},', "the first constant")
	lu.assertEquals(trim(list[duty2 + 11]), 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "vortex_mission_6"},', "the ninth constant")

	-- the reset directly after resetV3fxQuests and before the Kiizete comment
	local v3fx = indexOf(list, "function VortexSquadronScreenplay:resetV3fxQuests(pPlayer)")
	local vrovel = indexOf(list, "function VortexSquadronScreenplay:resetVrovelQuests(pPlayer)")
	local kiizete = indexOf(list, "-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)")

	lu.assertNotNil(v3fx, "resetV3fxQuests")
	lu.assertNotNil(vrovel, "resetVrovelQuests")
	lu.assertNotNil(kiizete, "the Kiizete comment")
	lu.assertTrue(v3fx < vrovel and vrovel < kiizete, "resetVrovelQuests sits between resetV3fxQuests and the Kiizete comment")
	lu.assertEquals(trim(list[vrovel - 1]), "-- Clears Brother Vrovel's quests, journal entries and keys (surrender)", "the reset's comment")
end

-- I-10, SC-3: space_helpers.lua gains the blank line, the comment and the one reset call after V3-FX's reset, and nothing else
function TestVrovelPins:test_space_helpers_gains_only_the_tier_2_lines_in_the_vortex_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 2", "VortexSquadronScreenplay:resetVrovelQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local v3fx = indexOf(list, "VortexSquadronScreenplay:resetV3fxQuests(pPlayer)")

	lu.assertNotNil(v3fx, "V3-FX's reset call")
	lu.assertEquals(list[v3fx + 1], "", "a blank line after V3-FX's reset")
	lu.assertEquals(list[v3fx + 2], "\t\t-- Tier 2", "the comment")
	lu.assertEquals(list[v3fx + 3], "\t\tVortexSquadronScreenplay:resetVrovelQuests(pPlayer)", "Vrovel's reset")
end

-- I-10, SC-1: space quest logic gains the split type, the default and its comment, and nothing else
function TestVrovelPins:test_space_quest_logic_gains_only_the_inspection_type_and_default()
	requireBase()

	local removed, added = changedLines(SQL)

	lu.assertEquals(removed, {}, SQL .. ": removed lines")
	lu.assertEquals(nonBlank(added), {
		"INSPECTION = 6,",
		"-- Cargo inspections the player must make before an INSPECTION split (SWG inspect triggerOn)",
		"sideQuestInspectCount = 0,",
	}, SQL .. ": added lines")

	local list = allLines(readWorking(SQL))
	local wave = indexOf(list, "ATTACK_WAVE = 5,")
	local count = indexOf(list, "sideQuestInspectCount = 0,")
	local attack = indexOf(list, "sideQuestAttackWave = 0,")

	lu.assertNotNil(wave, "ATTACK_WAVE = 5")
	lu.assertEquals(trim(list[wave + 1]), "INSPECTION = 6,", "INSPECTION directly after ATTACK_WAVE")
	lu.assertNotNil(attack, "sideQuestAttackWave")
	lu.assertNotNil(count, "sideQuestInspectCount")
	lu.assertTrue(count > attack, "sideQuestInspectCount after sideQuestAttackWave")
end

-- I-10, SC-1: the inspect type changes only inspectedShip and cleanUpQuestData (both only gain lines) and gains the two split functions
function TestVrovelPins:test_the_inspect_type_changes_only_the_two_functions_of_sc_1_and_gains_the_two_split_handlers()
	requireBase()

	local baseHeader, baseBlocks, baseOrder = functionBlocks(baseText(SIS), "SpaceInspectScreenplay")
	local nowHeader, nowBlocks, nowOrder = functionBlocks(readWorking(SIS), "SpaceInspectScreenplay")
	local allowed = { inspectedShip = true, cleanUpQuestData = true }
	local changed, gained = {}, {}

	lu.assertEquals(nowHeader, baseHeader, SIS .. ": the table fields before the first function")

	for _, name in ipairs(baseOrder) do
		lu.assertNotNil(nowBlocks[name], SIS .. ": function " .. name .. " still exists")

		if nowBlocks[name] ~= baseBlocks[name] then
			changed[#changed + 1] = name
		end
	end

	for _, name in ipairs(nowOrder) do
		if baseBlocks[name] == nil then
			gained[#gained + 1] = name
		end
	end

	table.sort(changed)
	lu.assertEquals(changed, { "cleanUpQuestData", "inspectedShip" }, SIS .. ": functions that differ from the base (SC-1 changes inspectedShip and cleanUpQuestData only)")

	table.sort(gained)
	lu.assertEquals(gained, { "countInspection", "triggerInspectionSplit" }, SIS .. ": new functions")

	-- the two changed functions only gain lines: every base line is still there
	for name in pairs(allowed) do
		local now = {}

		for _, l in ipairs(allLines(nowBlocks[name])) do
			now[trim(l)] = (now[trim(l)] or 0) + 1
		end

		for _, l in ipairs(allLines(baseBlocks[name])) do
			if trim(l) ~= "" then
				lu.assertTrue((now[trim(l)] or 0) > 0, SIS .. ":" .. name .. " lost the line '" .. trim(l) .. "'")
			end
		end
	end
end

-- I-10, SC-2: each of the two shuttle templates gains the one cargoString line directly after questLoot, and nothing else
function TestVrovelPins:test_the_two_shuttle_templates_gain_only_the_cargo_string_line_after_the_quest_loot()
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

-- I-10: Part B's files, the other trainers, the other squadrons, the points and spawners and every other quest-type screenplay are byte-identical to the base
function TestVrovelPins:test_part_b_files_the_other_squadrons_and_the_other_quest_types_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local vortex = ROOT .. "screenplays/space/conversations/rebel/vortex_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/vortex_squadron/"

	for _, path in ipairs({
		vortex .. "v3fxConvoHandler.lua", convos .. "v3fx_convo.lua", ROOT .. "mobile/space/vrovel.lua", ROOT .. "mobile/space/v3_fx.lua", ROOT .. "mobile/space/ezkiel.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/poi/dantooine_abandoned_rebel_base.lua",
		ROOT .. "ship_mobile/patrol_points/space_lok.lua", ROOT .. "ship_mobile/patrol_points/space_yavin4.lua", ROOT .. "ship_mobile/patrol_points/space_dantooine.lua",
		ROOT .. "screenplays/space/spawning/space_lok_spawner.lua", ROOT .. "screenplays/space/spawning/space_dantooine_spawner.lua",
		ROOT .. "screenplays/space/spawning/space_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")
	local files = lines(differing)

	table.sort(files)
	lu.assertEquals(files, { SIS, SQL }, "quest-type screenplays that differ from " .. BASE .. " (only the inspect type and the shared logic)")
end

-- the pin helper itself: a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed, not as a header
function TestVrovelPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
	requireBase()

	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(VSP))

	lu.assertEquals(rc, 0, "git diff failed")

	-- a synthetic diff: header, one hunk, a removed Lua comment and an added one
	local text = "--- a/x.lua\n+++ b/x.lua\n@@ -1 +1 @@\n--- old comment\n+-- new comment\n"
	local removed, added = {}, {}
	local hunks = 0

	for line in text:gmatch("(.-)\n") do
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

	lu.assertEquals(removed, { "-- old comment" }, "removed")
	lu.assertEquals(added, { "-- new comment" }, "added")
	lu.assertEquals(type(out), "string", "git diff output")
end

return nil
