-- Vortex tier 3 part A (Brother Ezkiel's missions): nothing else moves (I-9).
-- Spec: .claude/work/vortex-tier3-ezkiel-missions/01-spec.md (I-9, A-1, A-7; Content contract 1 to 3; Shared code changes SC-1, SC-2; D-8).
--
-- The base is `git show 9ba70e4de9` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Part B (vortex-tier3-ezkiel) pins
-- its own base in its own file. The diff reader skips the diff header only before the first @@: after it a removed "-- comment" line reads "--- comment".

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "9ba70e4de9"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local VSP = ROOT .. "screenplays/space/squadrons/VortexSquadronScreenplay.lua"

local SHIPS = {
	["naboo_tier3_imperial_spy"] = { cargo = "experiment_information", questLoot = "experiment_information" },
	["blacklight_pirate_fighter_quest"] = { cargo = "leader_location", questLoot = "leader_location" },
}

local function shipPath(name) return ROOT .. "ship_mobile/ships/" .. name .. ".lua" end

-- the only files under bin/ and src/ that may differ from the base: all of them modified, none added (I-9)
local CHANGED_FILES = { VSP, SH, shipPath("naboo_tier3_imperial_spy"), shipPath("blacklight_pirate_fighter_quest") }

-- Content contract 1 order
local GLOBALS = {
	"assassinate_naboo_rebel_tier3_1", "escort_naboo_rebel_tier3_1_a", "survival_naboo_rebel_tier3_1_b", "inspect_naboo_rebel_tier3_1_c", "delivery_no_pickup_naboo_rebel_tier3_1_d",
	"space_battle_naboo_rebel_tier3_2", "rescue_naboo_rebel_tier3_2_a", "patrol_naboo_rebel_tier3_2_b", "destroy_surpriseattack_naboo_rebel_tier3_2_c", "inspect_naboo_rebel_tier3_2_d",
	"patrol_naboo_rebel_tier3_3", "destroy_surpriseattack_naboo_rebel_tier3_3_a", "survival_naboo_rebel_tier3_3_b", "patrol_naboo_rebel_tier3_3_c", "assassinate_naboo_rebel_tier3_3_d",
	"space_battle_naboo_rebel_tier3_4", "patrol_naboo_rebel_tier3_4_a", "survival_naboo_rebel_tier3_4_b", "recovery_naboo_rebel_tier3_4_c", "delivery_naboo_rebel_tier3_4_d",
}

local MISSION_COMMENTS = {
	"-- Mission 1: Assassinate > Escort > Survival > Inspect > Delivery (no pickup)",
	"-- Mission 2: Space battle > Rescue > Patrol > Surprise attack > Inspect",
	"-- Mission 3: Patrol > Surprise attack > Survival > Patrol > Assassinate",
	"-- Mission 4: Space battle > Patrol > Survival > Recovery > Delivery",
}

local OLD_HEADER = "\tTier 2 (Brother Vrovel) is below; tiers 3-4 (Brother Ezkiel, Brother Extok Evin) are not ported yet"
local NEW_HEADER = "\tTiers 2-3 (Brother Vrovel, Brother Ezkiel) are below; tier 4 (Brother Extok Evin) is not ported yet"

local CONSTANTS = {
	'TIER3_QUEST_STRING_1 = {type = "assassinate", name = "naboo_rebel_tier3_1"},',
	'TIER3_QUEST_STRING_1_SIDE1 = {type = "escort", name = "naboo_rebel_tier3_1_a"},',
	'TIER3_QUEST_STRING_1_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_1_b"},',
	'TIER3_QUEST_STRING_1_SIDE3 = {type = "inspect", name = "naboo_rebel_tier3_1_c"},',
	'TIER3_QUEST_STRING_1_SIDE4 = {type = "delivery_no_pickup", name = "naboo_rebel_tier3_1_d"},',
	'TIER3_QUEST_STRING_2 = {type = "space_battle", name = "naboo_rebel_tier3_2"},',
	'TIER3_QUEST_STRING_2_SIDE1 = {type = "rescue", name = "naboo_rebel_tier3_2_a"},',
	'TIER3_QUEST_STRING_2_SIDE2 = {type = "patrol", name = "naboo_rebel_tier3_2_b"},',
	'TIER3_QUEST_STRING_2_SIDE3 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier3_2_c"},',
	'TIER3_QUEST_STRING_2_SIDE4 = {type = "inspect", name = "naboo_rebel_tier3_2_d"},',
	'TIER3_QUEST_STRING_3 = {type = "patrol", name = "naboo_rebel_tier3_3"},',
	'TIER3_QUEST_STRING_3_SIDE1 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier3_3_a"},',
	'TIER3_QUEST_STRING_3_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_3_b"},',
	'TIER3_QUEST_STRING_3_SIDE3 = {type = "patrol", name = "naboo_rebel_tier3_3_c"},',
	'TIER3_QUEST_STRING_3_SIDE4 = {type = "assassinate", name = "naboo_rebel_tier3_3_d"},',
	'TIER3_QUEST_STRING_4 = {type = "space_battle", name = "naboo_rebel_tier3_4"},',
	'TIER3_QUEST_STRING_4_SIDE1 = {type = "patrol", name = "naboo_rebel_tier3_4_a"},',
	'TIER3_QUEST_STRING_4_SIDE2 = {type = "survival", name = "naboo_rebel_tier3_4_b"},',
	'TIER3_QUEST_STRING_4_SIDE3 = {type = "recovery", name = "naboo_rebel_tier3_4_c"},',
	'TIER3_QUEST_STRING_4_SIDE4 = {type = "delivery", name = "naboo_rebel_tier3_4_d"},',
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

TestEzkielPins = {}

-- I-9: only the four files of the spec differ under bin/ and src/ (no new production file, no C++ change)
function TestEzkielPins:test_only_the_four_files_of_the_spec_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-9, A-1: the squadron file differs only by additions and the one header line: the 20 constants, the reset and the 20 quest tables
function TestEzkielPins:test_the_squadron_file_differs_from_the_base_only_by_additions_and_the_header_line()
	requireBase()

	local removed, added = changedLines(VSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, { OLD_HEADER }, VSP .. ": removed lines (the header line only)")
	contains(text, NEW_HEADER, VSP .. ": the header line")

	for _, constant in ipairs(CONSTANTS) do
		contains(text, constant, VSP .. ": constant")
	end

	contains(text, "function VortexSquadronScreenplay:resetEzkielQuests(pPlayer)", VSP .. ": the reset")
	contains(text, "-- Clears Brother Ezkiel's quests, journal entries and keys (surrender)", VSP .. ": the reset's comment")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', VSP .. ": " .. global)
	end

	for _, comment in ipairs(MISSION_COMMENTS) do
		contains(text, comment, VSP .. ": mission comment")
	end
end

-- I-9, Content contract 1 and 2: where the additions sit in the squadron file
function TestEzkielPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(VSP))
	local lastTier2 = indexOf(list, 'registerScreenPlay("recovery_duty_vortex_mission_7", true)')
	local section = indexOf(list, "Tier 3 -- Brother Ezkiel (Dantooine, abandoned Rebel base; Dantooine, Endor and Dathomir systems)")
	local first = indexOf(list, 'registerScreenPlay("assassinate_naboo_rebel_tier3_1", true)')
	local last = indexOf(list, 'registerScreenPlay("delivery_naboo_rebel_tier3_4_d", true)')
	local object = indexOf(list, "VortexSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier2, "the last tier 2 registration")
	lu.assertNotNil(section, "the section comment 'Tier 3 -- Brother Ezkiel (Dantooine, abandoned Rebel base; Dantooine, Endor and Dathomir systems)'")
	lu.assertNotNil(first, "the first tier 3 registration")
	lu.assertNotNil(last, "the last tier 3 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier2 < section and section < first and first < last and last < object, "order: tier 2's last table, the section comment, the 20 tier 3 tables, the squadron object")

	-- the 20 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the four mission comments, each before its chain's head
	local heads = { 1, 6, 11, 16 }

	for m, comment in ipairs(MISSION_COMMENTS) do
		local c = indexOf(list, comment)

		lu.assertNotNil(c, "mission comment " .. m)
		lu.assertTrue(c > section and c < object, "mission comment " .. m .. " sits in the tier 3 section")

		local head = indexOf(list, 'registerScreenPlay("' .. GLOBALS[heads[m]] .. '", true)')

		lu.assertTrue(c < head, "mission comment " .. m .. " is before the head's registration")

		if m > 1 then
			local prevEnd = indexOf(list, 'registerScreenPlay("' .. GLOBALS[heads[m] - 1] .. '", true)')

			lu.assertTrue(c > prevEnd, "mission comment " .. m .. " is after mission " .. (m - 1) .. "'s last registration")
		end
	end

	-- the constants directly after TIER2_QUEST_STRING_DUTY_3, under a blank line and the comment
	local duty3 = indexOf(list, 'TIER2_QUEST_STRING_DUTY_3 = {type = "destroy_duty", name = "vortex_mission_6"},')

	lu.assertNotNil(duty3, "TIER2_QUEST_STRING_DUTY_3")
	lu.assertEquals(list[duty3 + 1], "", "a blank line after TIER2_QUEST_STRING_DUTY_3")
	lu.assertEquals(trim(list[duty3 + 2]), "-- Tier 3 (Ezkiel)", "the comment after the blank line")

	for i, constant in ipairs(CONSTANTS) do
		lu.assertEquals(trim(list[duty3 + 2 + i]), constant, "constant " .. i .. " in contract order")
	end

	-- the reset directly after resetVrovelQuests and before the Kiizete comment
	local vrovel = indexOf(list, "function VortexSquadronScreenplay:resetVrovelQuests(pPlayer)")
	local ezkiel = indexOf(list, "function VortexSquadronScreenplay:resetEzkielQuests(pPlayer)")
	local kiizete = indexOf(list, "-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)")

	lu.assertNotNil(vrovel, "resetVrovelQuests")
	lu.assertNotNil(ezkiel, "resetEzkielQuests")
	lu.assertNotNil(kiizete, "the Kiizete comment")
	lu.assertTrue(vrovel < ezkiel and ezkiel < kiizete, "resetEzkielQuests sits between resetVrovelQuests and the Kiizete comment")
	lu.assertEquals(trim(list[ezkiel - 1]), "-- Clears Brother Ezkiel's quests, journal entries and keys (surrender)", "the reset's comment")
end

-- I-9, A-7: the reset never touches VORTEX_PILOT_KEY (D-7: resetV3fxQuests owns that removal)
function TestEzkielPins:test_the_reset_does_not_mention_the_graduation_key()
	requireBase()

	local _, blocks = functionBlocks(readWorking(VSP), "VortexSquadronScreenplay")

	lu.assertNotNil(blocks.resetEzkielQuests, "resetEzkielQuests exists")
	lu.assertNil(blocks.resetEzkielQuests:find("VORTEX_PILOT_KEY", 1, true), "resetEzkielQuests must not touch VORTEX_PILOT_KEY")
end

-- I-9, SC-2: space_helpers.lua gains the blank line, the comment and the one reset call after Vrovel's reset, and nothing else
function TestEzkielPins:test_space_helpers_gains_only_the_tier_3_lines_in_the_vortex_branch()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 3", "VortexSquadronScreenplay:resetEzkielQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local vrovel = indexOf(list, "VortexSquadronScreenplay:resetVrovelQuests(pPlayer)")

	lu.assertNotNil(vrovel, "Vrovel's reset call")
	lu.assertEquals(list[vrovel + 1], "", "a blank line after Vrovel's reset")
	lu.assertEquals(list[vrovel + 2], "\t\t-- Tier 3", "the comment")
	lu.assertEquals(list[vrovel + 3], "\t\tVortexSquadronScreenplay:resetEzkielQuests(pPlayer)", "Ezkiel's reset")
end

-- I-9, SC-1: each of the two target templates gains the one cargoString line directly after questLoot, and nothing else
function TestEzkielPins:test_the_two_target_templates_gain_only_the_cargo_string_line_after_the_quest_loot()
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

-- I-9: Part B's files, the other trainers, the other squadrons, the points and spawners and every quest-type screenplay are byte-identical to the base
function TestEzkielPins:test_part_b_files_the_other_squadrons_and_every_quest_type_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local vortex = ROOT .. "screenplays/space/conversations/rebel/vortex_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/vortex_squadron/"

	for _, path in ipairs({
		vortex .. "v3fxConvoHandler.lua", vortex .. "vrovelConvoHandler.lua", convos .. "v3fx_convo.lua", convos .. "vrovel_convo.lua",
		ROOT .. "mobile/space/ezkiel.lua", ROOT .. "mobile/space/vrovel.lua", ROOT .. "mobile/space/v3_fx.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/poi/dantooine_abandoned_rebel_base.lua",
		ROOT .. "ship_mobile/patrol_points/space_dantooine.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "ship_mobile/patrol_points/space_dathomir.lua",
		ROOT .. "screenplays/space/spawning/space_dantooine_spawner.lua", ROOT .. "screenplays/space/spawning/space_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE .. " (none: no new split type is needed)")
end

-- the pin helper itself: a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed, not as a header
function TestEzkielPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
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
end

return nil
