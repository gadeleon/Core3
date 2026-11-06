-- Storm tier 3 part A (Captain Denner's missions): nothing else moves (I-14, Part A slice).
-- Spec: .claude/work/storm-tier3-denner-missions/01-spec.md (I-14, A-6; Content contract 1 to 3; Shared code changes SC-1 to SC-3; D-A2).
--
-- The base is `git show f605594875` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (storm-tier3-denner) pins
-- its own base in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "f605594875"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SQL = ROOT .. "screenplays/space/SpaceQuestLogic.lua"
local SES = ROOT .. "screenplays/space/SpaceEscortScreenplay.lua"
local SDES = ROOT .. "screenplays/space/SpaceDutyEscortScreenplay.lua"
local SSP = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"

local SHIPS = {
	["rebel_scout_fighter_tier3"] = { cargo = "encrypted_rebel_data", questLoot = "encrypted_rebel_data" },
	["rebel_scout_shuttle_tier3"] = { cargo = "rebel_plans", questLoot = "rebel_plans" },
	["rebel_command_shuttle_tier4"] = { cargo = "stolen_data", questLoot = "stolen_data" },
}

local function shipPath(name) return ROOT .. "ship_mobile/ships/" .. name .. ".lua" end

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added (SDES: review R-2, Amendment A-2)
local CHANGED_FILES = { SH, SQL, SES, SDES, SSP, shipPath("rebel_command_shuttle_tier4"), shipPath("rebel_scout_fighter_tier3"), shipPath("rebel_scout_shuttle_tier3") }

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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }), and the number of hunks
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

TestStormT3MissionsPins = {}

-- I-14: only the eight files of the spec (seven + SpaceDutyEscortScreenplay, R-2) differ under bin/ and src/ (no new production file, no C++ change)
function TestStormT3MissionsPins:test_only_the_eight_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-14, A-1: the squadron file differs only by additions: the 20 constants, the reset and the 20 quest tables
function TestStormT3MissionsPins:test_the_squadron_file_differs_from_the_base_only_by_additions()
	requireBase()

	local removed, added = changedLines(SSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, SSP .. ": removed lines")
	contains(text, 'TIER3_QUEST_STRING_1 = {type = "escort", name = "tatooine_imperial_tier3_1"},', SSP .. ": constant 1")
	contains(text, 'TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "tatooine_imperial_tier3_4_c"},', SSP .. ": the last constant")
	contains(text, "function StormSquadronScreenplay:resetDennerQuests(pPlayer)", SSP .. ": the reset")

	local globals = {
		"escort_tatooine_imperial_tier3_1", "recovery_tatooine_imperial_tier3_1_a", "inspect_tatooine_imperial_tier3_1_b", "rescue_tatooine_imperial_tier3_1_c",
		"delivery_no_pickup_tatooine_imperial_tier3_1_d", "inspect_tatooine_imperial_tier3_2", "destroy_surpriseattack_tatooine_imperial_tier3_2_a",
		"inspect_tatooine_imperial_tier3_2_b", "delivery_no_pickup_tatooine_imperial_tier3_2_c", "patrol_tatooine_imperial_tier3_2_d",
		"space_battle_tatooine_imperial_tier3_2_e", "delivery_tatooine_imperial_tier3_3", "destroy_tatooine_imperial_tier3_3_b", "escort_tatooine_imperial_tier3_3_a",
		"destroy_surpriseattack_tatooine_imperial_tier3_3_d", "survival_tatooine_imperial_tier3_3_c", "assassinate_tatooine_imperial_tier3_4",
		"rescue_tatooine_imperial_tier3_4_a", "inspect_tatooine_imperial_tier3_4_b", "assassinate_tatooine_imperial_tier3_4_c",
	}

	for _, global in ipairs(globals) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', SSP .. ": " .. global)
	end
end

-- I-14, Content contract 1 and 2: where the additions sit in the squadron file
function TestStormT3MissionsPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(SSP))
	local lastAlozen = indexOf(list, 'registerScreenPlay("escort_duty_lok_imperial_ss_2c", true)')
	local section = indexOf(list, "Tier 3 -- Captain Denner (Yavin 4, Imperial outpost; Endor system)")
	local first = indexOf(list, 'registerScreenPlay("escort_tatooine_imperial_tier3_1", true)')
	local last = indexOf(list, 'registerScreenPlay("assassinate_tatooine_imperial_tier3_4_c", true)')
	local object = indexOf(list, "StormSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastAlozen, "the last Alozen registration")
	lu.assertNotNil(section, "the section comment 'Tier 3 -- Captain Denner (Yavin 4, Imperial outpost; Endor system)'")
	lu.assertNotNil(first, "the first tier 3 registration")
	lu.assertNotNil(last, "the last tier 3 registration")
	lu.assertTrue(lastAlozen < section and section < first and first < last and last < object, "order: Alozen's last table, the section comment, the 20 tier 3 tables, the squadron object")

	-- the constants directly after TIER2_QUEST_STRING_DUTY_6, under a blank line and the comment
	local duty6 = indexOf(list, 'TIER2_QUEST_STRING_DUTY_6 = {type = "escort_duty", name = "lok_imperial_ss_2c"},')

	lu.assertNotNil(duty6, "TIER2_QUEST_STRING_DUTY_6")
	lu.assertEquals(list[duty6 + 1], "", "a blank line after TIER2_QUEST_STRING_DUTY_6")
	lu.assertEquals(trim(list[duty6 + 2]), "-- Tier 3 (Denner)", "the comment after the blank line")
	lu.assertEquals(trim(list[duty6 + 3]), 'TIER3_QUEST_STRING_1 = {type = "escort", name = "tatooine_imperial_tier3_1"},', "the first constant")
	lu.assertEquals(trim(list[duty6 + 22]), 'TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "tatooine_imperial_tier3_4_c"},', "the twentieth constant")

	-- the reset directly after resetAlozenQuests and before the Nym technicians comment
	local alozen = indexOf(list, "function StormSquadronScreenplay:resetAlozenQuests(pPlayer)")
	local denner = indexOf(list, "function StormSquadronScreenplay:resetDennerQuests(pPlayer)")
	local nym = indexOf(list, "-- The Nym fuel technicians on Lok (Morv and two decoys) grant the Kimogila's Claw (feature storm-tier2-nym-technicians)")

	lu.assertNotNil(alozen, "resetAlozenQuests")
	lu.assertNotNil(denner, "resetDennerQuests")
	lu.assertNotNil(nym, "the Nym technicians comment")
	lu.assertTrue(alozen < denner and denner < nym, "resetDennerQuests sits between resetAlozenQuests and the Nym technicians comment")
end

-- I-14, SC-3: space_helpers.lua gains the blank line, the comment and the one reset call after Alozen's reset, and nothing else
function TestStormT3MissionsPins:test_space_helpers_gains_only_the_tier_3_lines_in_the_storm_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 3", "StormSquadronScreenplay:resetDennerQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local alozen = indexOf(list, "StormSquadronScreenplay:resetAlozenQuests(pPlayer)")

	lu.assertNotNil(alozen, "Alozen's reset call")
	lu.assertEquals(list[alozen + 1], "", "a blank line after Alozen's reset")
	lu.assertEquals(list[alozen + 2], "\t\t-- Tier 3", "the comment")
	lu.assertEquals(list[alozen + 3], "\t\tStormSquadronScreenplay:resetDennerQuests(pPlayer)", "Denner's reset")
end

-- I-14, SC-1: space quest logic gains the split type, the default and its comment, and nothing else
function TestStormT3MissionsPins:test_space_quest_logic_gains_only_the_attack_wave_type_and_default()
	requireBase()

	local removed, added = changedLines(SQL)

	lu.assertEquals(removed, {}, SQL .. ": removed lines")
	lu.assertEquals(nonBlank(added), {
		"ATTACK_WAVE = 5,",
		"-- Attack waves the player must destroy before an ATTACK_WAVE split (SWG escort triggerOn)",
		"sideQuestAttackWave = 0,",
	}, SQL .. ": added lines")

	local list = allLines(readWorking(SQL))
	local patrol = indexOf(list, "PATROL_POINT = 4,")

	lu.assertNotNil(patrol, "PATROL_POINT = 4")
	lu.assertEquals(trim(list[patrol + 1]), "ATTACK_WAVE = 5,", "ATTACK_WAVE directly after PATROL_POINT")
end

-- I-14, SC-1: the escort type changes only in cleanUpQuestData, notifyEnteredQuestArea and notifyAttackShipDestroyed and gains triggerAttackWaveSplit
function TestStormT3MissionsPins:test_the_escort_type_changes_only_the_three_functions_of_sc_1_and_gains_the_split_handler()
	requireBase()

	local baseHeader, baseBlocks, baseOrder = functionBlocks(baseText(SES), "SpaceEscortScreenplay")
	local nowHeader, nowBlocks, nowOrder = functionBlocks(readWorking(SES), "SpaceEscortScreenplay")
	local allowed = { cleanUpQuestData = true, notifyEnteredQuestArea = true, notifyAttackShipDestroyed = true }
	local changed, gained = {}, {}

	lu.assertEquals(nowHeader, baseHeader, SES .. ": the table fields before the first function")

	for _, name in ipairs(baseOrder) do
		lu.assertNotNil(nowBlocks[name], SES .. ": function " .. name .. " still exists")

		if nowBlocks[name] ~= baseBlocks[name] then
			changed[#changed + 1] = name
		end
	end

	for _, name in ipairs(nowOrder) do
		if baseBlocks[name] == nil then
			gained[#gained + 1] = name
		end
	end

	for _, name in ipairs(changed) do
		lu.assertTrue(allowed[name] == true, SES .. ": " .. name .. " must not change (SC-1 changes cleanUpQuestData, notifyEnteredQuestArea, notifyAttackShipDestroyed)")
	end

	lu.assertEquals(gained, { "triggerAttackWaveSplit" }, SES .. ": new functions")

	-- the three do change
	local set = {}

	for _, name in ipairs(changed) do
		set[name] = true
	end

	for name in pairs(allowed) do
		lu.assertTrue(set[name] == true, SES .. ": " .. name .. " should change for SC-1")
	end
end

-- I-14, SC-1: the new code keeps the existing escort behavior text (cleanUpQuestData only gains lines; the kill count code stays)
function TestStormT3MissionsPins:test_clean_up_quest_data_and_the_kill_count_only_gain_lines()
	requireBase()

	local _, baseBlocks = functionBlocks(baseText(SES), "SpaceEscortScreenplay")
	local _, nowBlocks = functionBlocks(readWorking(SES), "SpaceEscortScreenplay")

	for _, name in ipairs({ "cleanUpQuestData", "notifyAttackShipDestroyed" }) do
		local now = {}

		for _, l in ipairs(allLines(nowBlocks[name])) do
			now[trim(l)] = (now[trim(l)] or 0) + 1
		end

		for _, l in ipairs(allLines(baseBlocks[name])) do
			if trim(l) ~= "" then
				lu.assertTrue((now[trim(l)] or 0) > 0, SES .. ":" .. name .. " lost the line '" .. trim(l) .. "'")
			end
		end
	end
end

-- I-14, SC-2: each of the three ship templates gains the one cargoString line directly after questLoot, and nothing else
function TestStormT3MissionsPins:test_the_three_inspect_ship_templates_gain_only_the_cargo_string_line_after_the_quest_loot()
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

-- I-14: Part B's files, the other trainers, the other squadrons and every other quest-type screenplay are byte-identical
function TestStormT3MissionsPins:test_part_b_files_the_other_trainers_and_the_other_quest_types_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local storm = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/"
	local convos = ROOT .. "mobile/conversations/space/imperial/storm_squadron/"

	for _, path in ipairs({
		storm .. "oberhaurConvoHandler.lua", storm .. "akalColzetConvoHandler.lua", storm .. "alozenConvoHandler.lua", storm .. "nymTechnician1ConvoHandler.lua",
		storm .. "nymTechnician2ConvoHandler.lua", storm .. "nymTechnician3ConvoHandler.lua", convos .. "oberhaur_convo.lua", convos .. "akal_colzet_convo.lua",
		convos .. "alozen_convo.lua", convos .. "nym_technician_1_convo.lua", convos .. "nym_technician_2_convo.lua", convos .. "nym_technician_3_convo.lua",
		ROOT .. "mobile/space/denner.lua", ROOT .. "mobile/space/alozen.lua", ROOT .. "mobile/space/oberhaur.lua", ROOT .. "mobile/space/akal_colzet.lua",
		ROOT .. "mobile/space/nial_declann.lua", ROOT .. "mobile/space/willham_burke.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/poi/yavin4_imperial_base.lua", ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "screenplays/space/spawning/space_endor_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")
	local files = lines(differing)

	table.sort(files)
	lu.assertEquals(files, { SDES, SES, SQL }, "quest-type screenplays that differ from " .. BASE .. " (only the escort type, the escort duty reset [R-2] and the shared logic)")
end
