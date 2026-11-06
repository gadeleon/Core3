-- Storm tier 4 part A (Admiral Kilnstrider's missions): nothing else moves (I-9).
-- Spec: .claude/work/storm-tier4-kilnstrider-missions/01-spec.md (I-9, A-6; Content contract 1 to 3; Shared code changes SC-1, SC-2; D-A4).
--
-- The base is `git show 6a5d2977c3` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (storm-tier4-kilnstrider)
-- pins its own base (this feature's commit) in its own file.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "6a5d2977c3"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SSP = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"
local ENDSCOUT = ROOT .. "ship_mobile/ships/rebel_endscout_tier4.lua"

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added
local CHANGED_FILES = { SH, SSP, ENDSCOUT }

local GLOBALS = {
	"patrol_tatooine_imperial_tier4_1", "destroy_surpriseattack_tatooine_imperial_tier4_1_a", "space_battle_tatooine_imperial_tier4_1_b",
	"inspect_tatooine_imperial_tier4_1_c", "delivery_no_pickup_tatooine_imperial_tier4_1_d", "recovery_tatooine_imperial_tier4_2",
	"recovery_tatooine_imperial_tier4_2_a", "delivery_tatooine_imperial_tier4_2_b", "delivery_no_pickup_tatooine_imperial_tier4_2_c",
	"escort_tatooine_imperial_tier4_3", "rescue_tatooine_imperial_tier4_3_a", "space_battle_tatooine_imperial_tier4_3_b",
	"assassinate_tatooine_imperial_tier4_4", "assassinate_tatooine_imperial_tier4_4_a", "recovery_tatooine_imperial_tier4_4_b",
	"assassinate_tatooine_imperial_tier4_4_c", "destroy_duty_tatooine_imperial_tier4_destroyduty_1", "escort_duty_tatooine_imperial_tier4_escortduty_1",
	"recovery_duty_tatooine_imperial_tier4_recoveryduty_1", "rescue_duty_tatooine_imperial_tier4_rescueduty_1",
}

-- the 20 constants, in contract order (Content contract 2)
local CONSTANTS = {
	'TIER4_QUEST_STRING_1 = {type = "patrol", name = "tatooine_imperial_tier4_1"},',
	'TIER4_QUEST_STRING_1_SIDE1 = {type = "destroy_surpriseattack", name = "tatooine_imperial_tier4_1_a"},',
	'TIER4_QUEST_STRING_1_SIDE2 = {type = "space_battle", name = "tatooine_imperial_tier4_1_b"},',
	'TIER4_QUEST_STRING_1_SIDE3 = {type = "inspect", name = "tatooine_imperial_tier4_1_c"},',
	'TIER4_QUEST_STRING_1_SIDE4 = {type = "delivery_no_pickup", name = "tatooine_imperial_tier4_1_d"},',
	'TIER4_QUEST_STRING_2 = {type = "recovery", name = "tatooine_imperial_tier4_2"},',
	'TIER4_QUEST_STRING_2_SIDE1 = {type = "recovery", name = "tatooine_imperial_tier4_2_a"},',
	'TIER4_QUEST_STRING_2_SIDE2 = {type = "delivery", name = "tatooine_imperial_tier4_2_b"},',
	'TIER4_QUEST_STRING_2_SIDE3 = {type = "delivery_no_pickup", name = "tatooine_imperial_tier4_2_c"},',
	'TIER4_QUEST_STRING_3 = {type = "escort", name = "tatooine_imperial_tier4_3"},',
	'TIER4_QUEST_STRING_3_SIDE1 = {type = "rescue", name = "tatooine_imperial_tier4_3_a"},',
	'TIER4_QUEST_STRING_3_SIDE2 = {type = "space_battle", name = "tatooine_imperial_tier4_3_b"},',
	'TIER4_QUEST_STRING_4 = {type = "assassinate", name = "tatooine_imperial_tier4_4"},',
	'TIER4_QUEST_STRING_4_SIDE1 = {type = "assassinate", name = "tatooine_imperial_tier4_4_a"},',
	'TIER4_QUEST_STRING_4_SIDE2 = {type = "recovery", name = "tatooine_imperial_tier4_4_b"},',
	'TIER4_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "tatooine_imperial_tier4_4_c"},',
	'TIER4_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "tatooine_imperial_tier4_destroyduty_1"},',
	'TIER4_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "tatooine_imperial_tier4_escortduty_1"},',
	'TIER4_QUEST_STRING_DUTY_3 = {type = "recovery_duty", name = "tatooine_imperial_tier4_recoveryduty_1"},',
	'TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "tatooine_imperial_tier4_rescueduty_1"},',
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

-- the index of the first line equal (trimmed) to `wanted`
local function indexOf(list, wanted, from)
	for i = from or 1, #list do
		if trim(list[i]) == wanted then
			return i
		end
	end
end

TestStormT4MissionsPins = {}

-- I-9: only the three files of the spec differ under bin/ and src/ (no new production file, no C++ change)
function TestStormT4MissionsPins:test_only_the_three_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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
	lu.assertEquals(lines(other), {}, "added, deleted, renamed or retyped files under bin/ and src/ against " .. BASE)
	lu.assertEquals(lines(untracked), {}, "untracked (new) production files under bin/ and src/")
end

-- I-9, A-1: the squadron file differs only by additions, in exactly three hunks: the tables, the constants and the reset
function TestStormT4MissionsPins:test_the_squadron_file_differs_from_the_base_only_by_additions_in_three_hunks()
	requireBase()

	local removed, added, hunks = changedLines(SSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, SSP .. ": removed lines")
	lu.assertEquals(hunks, 3, SSP .. ": hunks (tables after the tier 3 tail, constants, reset)")
	contains(text, CONSTANTS[1], SSP .. ": the first constant")
	contains(text, CONSTANTS[20], SSP .. ": the last constant")
	contains(text, 'TIER4_MET_KEY = "StormSquadronScreenplay:metTier4",', SSP .. ": the met key")
	contains(text, "function StormSquadronScreenplay:resetKilnstriderQuests(pPlayer)", SSP .. ": the reset")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', SSP .. ": " .. global)
	end
end

-- I-9, Content contract 1: the tables sit directly after the tier 3 tail, under a section comment, one blank line on each side
function TestStormT4MissionsPins:test_the_tier_4_tables_sit_between_the_tier_3_tables_and_the_squadron_block_comment()
	requireBase()

	local list = allLines(readWorking(SSP))
	local lastTier3 = indexOf(list, 'registerScreenPlay("assassinate_tatooine_imperial_tier3_4_c", true)')
	local section = indexOf(list, "Tier 4 -- Admiral Kilnstrider (Endor, research outpost; Endor and Dantooine systems)")
	local first = indexOf(list, 'registerScreenPlay("patrol_tatooine_imperial_tier4_1", true)')
	local last = indexOf(list, 'registerScreenPlay("rescue_duty_tatooine_imperial_tier4_rescueduty_1", true)')
	local object = indexOf(list, "StormSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier3, "the last tier 3 registration")
	lu.assertNotNil(section, "the section comment 'Tier 4 -- Admiral Kilnstrider (Endor, research outpost; Endor and Dantooine systems)'")
	lu.assertNotNil(first, "the first tier 4 registration")
	lu.assertNotNil(last, "the last tier 4 registration")
	lu.assertTrue(lastTier3 < section and section < first and first < last and last < object, "order: the tier 3 tables, the section comment, the 20 tier 4 tables, the squadron object")

	-- one blank line, the comment opener, then the section comment; one blank line, then the squadron block comment
	lu.assertEquals(list[lastTier3 + 1], "", "a blank line after the last tier 3 registration")
	lu.assertEquals(list[lastTier3 + 2], "--[[", "the section comment opens")
	lu.assertEquals(list[last + 1], "", "a blank line after the last tier 4 registration")
	lu.assertEquals(list[last + 2], "--[[", "the squadron block comment follows")

	-- the registrations come in contract order
	local previous = first - 1

	for _, global in ipairs(GLOBALS) do
		local at = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', previous + 1)

		lu.assertNotNil(at, "registerScreenPlay for " .. global .. " in contract order")
		previous = at
	end

	-- the mission comments, in order, inside the section
	local comments = {
		"-- Mission 1: Patrol > Surprise attack > Space battle > Inspect > Delivery (no pickup)", "-- Mission 2: Recovery > Recovery > Delivery > Delivery (no pickup)",
		"-- Mission 3: Escort > Rescue > Space battle", "-- Mission 4: Assassinate > Assassinate > Recovery > Assassinate (Dantooine)", "-- Duties",
	}
	local at = section

	for _, comment in ipairs(comments) do
		at = indexOf(list, comment, at + 1)
		lu.assertNotNil(at, "the comment '" .. comment .. "' in order")
	end
end

-- I-9, Content contract 2: the constants sit directly after TIER3_QUEST_STRING_4_SIDE3 under a blank line and a comment, the met key closes the block
function TestStormT4MissionsPins:test_the_constants_sit_directly_after_the_last_tier_3_constant_and_the_met_key_closes_the_block()
	requireBase()

	local list = allLines(readWorking(SSP))
	local side3 = indexOf(list, 'TIER3_QUEST_STRING_4_SIDE3 = {type = "assassinate", name = "tatooine_imperial_tier3_4_c"},')

	lu.assertNotNil(side3, "TIER3_QUEST_STRING_4_SIDE3")
	lu.assertEquals(list[side3 + 1], "", "a blank line after TIER3_QUEST_STRING_4_SIDE3")
	lu.assertEquals(trim(list[side3 + 2]), "-- Tier 4 (Kilnstrider); SIDEk = the k-th split child", "the comment after the blank line")

	for i, constant in ipairs(CONSTANTS) do
		lu.assertEquals(trim(list[side3 + 2 + i]), constant, "constant " .. i)
	end

	lu.assertEquals(list[side3 + 23], "", "a blank line after the 20th constant")
	contains(trim(list[side3 + 24]), "-- Set by Kilnstrider's first-meeting briefing", "the met key comment")
	lu.assertEquals(trim(list[side3 + 25]), 'TIER4_MET_KEY = "StormSquadronScreenplay:metTier4",', "the met key")
	lu.assertEquals(list[side3 + 26], "}", "the object closes directly after the met key")
end

-- I-9, Content contract 2: the reset sits directly after resetDennerQuests, under one blank line, before the Nym comment
function TestStormT4MissionsPins:test_the_reset_sits_directly_after_denners_reset_and_before_the_nym_comment()
	requireBase()

	local list = allLines(readWorking(SSP))
	local denner = indexOf(list, "function StormSquadronScreenplay:resetDennerQuests(pPlayer)")
	local kilnstrider = indexOf(list, "function StormSquadronScreenplay:resetKilnstriderQuests(pPlayer)")
	local nym = indexOf(list, "-- The Nym fuel technicians on Lok (Morv and two decoys) grant the Kimogila's Claw (feature storm-tier2-nym-technicians)")

	lu.assertNotNil(denner, "resetDennerQuests")
	lu.assertNotNil(kilnstrider, "resetKilnstriderQuests")
	lu.assertNotNil(nym, "the Nym technicians comment")
	lu.assertTrue(denner < kilnstrider and kilnstrider < nym, "order: resetDennerQuests, resetKilnstriderQuests, the Nym technicians comment")
	lu.assertEquals(list[kilnstrider - 1], "", "one blank line before resetKilnstriderQuests")
	lu.assertEquals(list[kilnstrider - 2], "end", "resetDennerQuests ends directly above the blank line")

	local close
	for i = kilnstrider + 1, nym do
		if list[i] == "end" then
			close = i

			break
		end
	end

	lu.assertNotNil(close, "the end of resetKilnstriderQuests")
	lu.assertEquals(list[close + 1], "", "one blank line after resetKilnstriderQuests")
	lu.assertEquals(close + 2, nym, "the Nym comment directly after the blank line")
end

-- I-9, SC-1: space_helpers.lua gains the blank line, the comment and the one reset call after Denner's reset, and nothing else
function TestStormT4MissionsPins:test_space_helpers_gains_only_the_tier_4_lines_in_the_storm_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 4", "StormSquadronScreenplay:resetKilnstriderQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local denner = indexOf(list, "StormSquadronScreenplay:resetDennerQuests(pPlayer)")

	lu.assertNotNil(denner, "Denner's reset call")
	lu.assertEquals(list[denner + 1], "", "a blank line after Denner's reset")
	lu.assertEquals(list[denner + 2], "\t\t-- Tier 4", "the comment")
	lu.assertEquals(list[denner + 3], "\t\tStormSquadronScreenplay:resetKilnstriderQuests(pPlayer)", "Kilnstrider's reset")
end

-- I-9, SC-2: rebel_endscout_tier4 gains the one cargoString line directly after questLoot, and nothing else
function TestStormT4MissionsPins:test_the_endscout_ship_gains_only_the_cargo_string_line_after_the_quest_loot()
	requireBase()

	local removed, added = changedLines(ENDSCOUT)

	lu.assertEquals(removed, {}, ENDSCOUT .. ": removed lines")
	lu.assertEquals(#added, 1, ENDSCOUT .. ": added lines: " .. table.concat(added, " | "))
	contains(added[1] or "", 'cargoString = "rebel_battle_plans",', ENDSCOUT .. ": the added line")

	local list = allLines(readWorking(ENDSCOUT))
	local loot = indexOf(list, 'questLoot = "rebel_battle_plans",')

	lu.assertNotNil(loot, "the questLoot line")
	contains(list[loot + 1] or "", 'cargoString = "rebel_battle_plans",', ENDSCOUT .. ": directly after questLoot")
end

-- I-9: Kilnstrider's NPC and conversation wiring (Part B's), the spawn, every quest-type screenplay, the other trainers and the other squadrons are byte-identical
function TestStormT4MissionsPins:test_part_b_files_the_quest_types_the_other_trainers_and_the_other_squadrons_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local storm = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/"
	local convos = ROOT .. "mobile/conversations/space/imperial/storm_squadron/"

	for _, path in ipairs({
		storm .. "oberhaurConvoHandler.lua", storm .. "akalColzetConvoHandler.lua", storm .. "alozenConvoHandler.lua", storm .. "dennerConvoHandler.lua",
		storm .. "nymTechnician1ConvoHandler.lua", storm .. "nymTechnician2ConvoHandler.lua", storm .. "nymTechnician3ConvoHandler.lua",
		convos .. "oberhaur_convo.lua", convos .. "akal_colzet_convo.lua", convos .. "alozen_convo.lua", convos .. "denner_convo.lua",
		convos .. "nym_technician_1_convo.lua", convos .. "nym_technician_2_convo.lua", convos .. "nym_technician_3_convo.lua",
		ROOT .. "mobile/space/kilnstrider.lua", ROOT .. "mobile/space/denner.lua", ROOT .. "mobile/space/alozen.lua", ROOT .. "mobile/space/oberhaur.lua",
		ROOT .. "mobile/space/akal_colzet.lua", ROOT .. "mobile/space/nial_declann.lua", ROOT .. "mobile/space/willham_burke.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/cities/endor_research_outpost.lua", ROOT .. "screenplays/poi/yavin4_imperial_base.lua", ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "ship_mobile/patrol_points/space_dantooine.lua",
		ROOT .. "screenplays/space/spawning/space_endor_spawner.lua",
	}) do
		identical(path)
	end

	-- every quest-type screenplay (Space*.lua under screenplays/space) is unchanged: no shared quest-type change in this feature (FA-1)
	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE)
end
