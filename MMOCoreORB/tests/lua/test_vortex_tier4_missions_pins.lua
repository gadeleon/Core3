-- Vortex tier 4 part A (Brother Extok Evin's missions): nothing else moves (I-9).
-- Spec: .claude/work/vortex-tier4-extok-evin/01-spec.md (I-9, A-1, A-6, A-7; Content contract 1 to 3; Shared code changes SC-1; D-11).
--
-- The base is `git show e248380bfd` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other pins do. Part B (the conversation) pins its own base
-- in its own file. The diff reader skips the diff header only before the first @@: after it a removed "-- comment" line reads "--- comment".

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "e248380bfd"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local VSP = ROOT .. "screenplays/space/squadrons/VortexSquadronScreenplay.lua"

-- the only files under bin/ and src/ that may differ from the base: both modified, none added (I-9)
local CHANGED_FILES = { VSP, SH }

-- Content contract 1 order
local GLOBALS = {
	"survival_naboo_rebel_tier4_1", "assassinate_naboo_rebel_tier4_1_a", "escort_naboo_rebel_tier4_1_b",
	"assassinate_naboo_rebel_tier4_2", "space_battle_naboo_rebel_tier4_2_a", "destroy_surpriseattack_naboo_rebel_tier4_2_b", "assassinate_naboo_rebel_tier4_2_c",
	"rescue_naboo_rebel_tier4_3", "assassinate_naboo_rebel_tier4_3_a", "delivery_no_pickup_naboo_rebel_tier4_3_b",
	"space_battle_naboo_rebel_tier4_4", "space_battle_naboo_rebel_tier4_4_a", "survival_naboo_rebel_tier4_4_b",
	"destroy_duty_naboo_rebel_tier4_1", "escort_duty_naboo_rebel_tier4_1", "recovery_duty_naboo_rebel_tier4_1", "rescue_duty_naboo_rebel_tier4_1",
}

-- the group comments, each before the first registration of its group (Content contract 1)
local GROUP_COMMENTS = {
	{ "-- Mission 1: Survival > Assassinate (won) or Escort (lost)", 1 },
	{ "-- Mission 2: Assassinate > Space battle (won) or Surprise attack > Assassinate in Dathomir (lost)", 4 },
	{ "-- Mission 3: Rescue > Assassinate (won) or Delivery (no pickup) (lost)", 8 },
	{ "-- Mission 4: Space battle > Space battle (won) or Survival (lost)", 11 },
	{ "-- Duties", 14 },
}

local SECTION_TITLE = "\tTier 4 -- Brother Extok Evin (Talus, Dearic theater; Endor, Yavin, Dathomir and Dantooine systems)"
local SECTION_PORTED = "\tPorted from SWG-Source naboo_rebel_tier4_1..4, their success and failure splits and the four tier 4 duties (survival, assassinate, escort, space_battle, destroy_surpriseattack, rescue, delivery_no_pickup, destroy_duty, escort_duty, recovery_duty, rescue_duty); feature vortex-tier4-extok-evin"

local OLD_HEADER = "\tTiers 2-3 (Brother Vrovel, Brother Ezkiel) are below; tier 4 (Brother Extok Evin) is not ported yet"
local NEW_HEADER = "\tTiers 2-4 (Brother Vrovel, Brother Ezkiel, Brother Extok Evin) are below"

local CONSTANT_COMMENT = "\t-- Tier 4 (Extok Evin); SIDE1 = the success split, SIDE2 = the failure split, SIDE3 = the failure split's own split (mission 2)"
local MET_COMMENT = "\t-- Set by Evin's first-meeting reply (SWG setMetMe / space flag metTier4, J4:418-421; vortex-tier4-extok-evin Part B); cleared by resetEvinQuests"

-- Content contract 2, in order
local CONSTANTS = {
	'TIER4_QUEST_STRING_1 = {type = "survival", name = "naboo_rebel_tier4_1"},',
	'TIER4_QUEST_STRING_1_SIDE1 = {type = "assassinate", name = "naboo_rebel_tier4_1_a"},',
	'TIER4_QUEST_STRING_1_SIDE2 = {type = "escort", name = "naboo_rebel_tier4_1_b"},',
	'TIER4_QUEST_STRING_2 = {type = "assassinate", name = "naboo_rebel_tier4_2"},',
	'TIER4_QUEST_STRING_2_SIDE1 = {type = "space_battle", name = "naboo_rebel_tier4_2_a"},',
	'TIER4_QUEST_STRING_2_SIDE2 = {type = "destroy_surpriseattack", name = "naboo_rebel_tier4_2_b"},',
	'TIER4_QUEST_STRING_2_SIDE3 = {type = "assassinate", name = "naboo_rebel_tier4_2_c"},',
	'TIER4_QUEST_STRING_3 = {type = "rescue", name = "naboo_rebel_tier4_3"},',
	'TIER4_QUEST_STRING_3_SIDE1 = {type = "assassinate", name = "naboo_rebel_tier4_3_a"},',
	'TIER4_QUEST_STRING_3_SIDE2 = {type = "delivery_no_pickup", name = "naboo_rebel_tier4_3_b"},',
	'TIER4_QUEST_STRING_4 = {type = "space_battle", name = "naboo_rebel_tier4_4"},',
	'TIER4_QUEST_STRING_4_SIDE1 = {type = "space_battle", name = "naboo_rebel_tier4_4_a"},',
	'TIER4_QUEST_STRING_4_SIDE2 = {type = "survival", name = "naboo_rebel_tier4_4_b"},',
	'TIER4_QUEST_STRING_DUTY_1 = {type = "destroy_duty", name = "naboo_rebel_tier4_1"},',
	'TIER4_QUEST_STRING_DUTY_2 = {type = "escort_duty", name = "naboo_rebel_tier4_1"},',
	'TIER4_QUEST_STRING_DUTY_3 = {type = "recovery_duty", name = "naboo_rebel_tier4_1"},',
	'TIER4_QUEST_STRING_DUTY_4 = {type = "rescue_duty", name = "naboo_rebel_tier4_1"},',
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

TestEvinPins = {}

-- I-9: only the two files of the spec differ under bin/ and src/ (no new production file, no C++ change)
function TestEvinPins:test_only_the_squadron_file_and_space_helpers_differ_from_the_base_under_bin_and_src_and_none_is_added()
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

-- I-9, A-1: the squadron file differs only by additions in three hunks and the one header line (four hunks, one removed line)
function TestEvinPins:test_the_squadron_file_differs_from_the_base_only_by_three_additions_and_the_header_line()
	requireBase()

	local removed, added, hunks = changedLines(VSP)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, { OLD_HEADER }, VSP .. ": removed lines (the header line only)")
	lu.assertEquals(hunks, 4, VSP .. ": hunks (the header line, the tables after the tier 3 tables, the constants, the reset)")
	contains(text, NEW_HEADER, VSP .. ": the header line")

	for _, constant in ipairs(CONSTANTS) do
		contains(text, constant, VSP .. ": constant")
	end

	contains(text, 'TIER4_MET_KEY = "VortexSquadronScreenplay:metTier4",', VSP .. ": the met key")
	contains(text, "function VortexSquadronScreenplay:resetEvinQuests(pPlayer)", VSP .. ": the reset")
	contains(text, "-- Clears Brother Extok Evin's quests, journal entries and keys (surrender)", VSP .. ": the reset's comment")

	for _, global in ipairs(GLOBALS) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', VSP .. ": " .. global)
	end

	for _, dead in ipairs({ "naboo_rebel_tier5", "naboo_rebel_master" }) do
		lu.assertNil(text:find(dead, 1, true), VSP .. ": " .. dead .. " is not ported (D-10)")
	end
end

-- I-9, Content contract 1 and 2: where the additions sit in the squadron file
function TestEvinPins:test_the_squadron_additions_sit_where_the_contract_puts_them()
	requireBase()

	local list = allLines(readWorking(VSP))
	local lastTier3 = indexOf(list, 'registerScreenPlay("delivery_naboo_rebel_tier3_4_d", true)')
	local section = indexOf(list, trim(SECTION_TITLE))
	local first = indexOf(list, 'registerScreenPlay("' .. GLOBALS[1] .. '", true)')
	local last = indexOf(list, 'registerScreenPlay("' .. GLOBALS[#GLOBALS] .. '", true)')
	local object = indexOf(list, "VortexSquadronScreenplay = ScreenPlay:new {")

	lu.assertNotNil(lastTier3, "the last tier 3 registration")
	lu.assertNotNil(section, "the section comment '" .. trim(SECTION_TITLE) .. "'")
	lu.assertNotNil(first, "the first tier 4 registration")
	lu.assertNotNil(last, "the last tier 4 registration")
	lu.assertNotNil(object, "the squadron object")
	lu.assertTrue(lastTier3 < section and section < first and first < last and last < object, "order: tier 3's last table, the section comment, the 17 tier 4 tables, the squadron object")
	lu.assertEquals(list[section - 1], "--[[", "the section comment opens above its title")
	lu.assertEquals(list[section + 1], SECTION_PORTED, "the section comment's second line")
	lu.assertEquals(list[section + 2], "]]", "the section comment closes")
	lu.assertEquals(list[lastTier3 + 1], "", "one blank line between the last tier 3 registration and the section comment")
	lu.assertEquals(list[lastTier3 + 2], "--[[", "the section comment follows the blank line")
	lu.assertEquals(list[last + 1], "", "one blank line after the last tier 4 registration")
	lu.assertTrue(list[last + 2] ~= "", "exactly one blank line after the last tier 4 registration")

	-- the 17 registrations in the contract order
	local at = first

	for _, global in ipairs(GLOBALS) do
		local i = indexOf(list, 'registerScreenPlay("' .. global .. '", true)', at)

		lu.assertNotNil(i, "registration of " .. global .. " after the previous one")
		at = i
	end

	-- the five group comments, each before its group's first registration and after the previous group's last
	for g, spec in ipairs(GROUP_COMMENTS) do
		local c = indexOf(list, spec[1])

		lu.assertNotNil(c, "group comment " .. g .. ": " .. spec[1])
		lu.assertTrue(c > section and c < object, "group comment " .. g .. " sits in the tier 4 section")

		local head = indexOf(list, 'registerScreenPlay("' .. GLOBALS[spec[2]] .. '", true)')

		lu.assertTrue(c < head, "group comment " .. g .. " is before the group's first registration")

		if spec[2] > 1 then
			local prevEnd = indexOf(list, 'registerScreenPlay("' .. GLOBALS[spec[2] - 1] .. '", true)')

			lu.assertTrue(c > prevEnd, "group comment " .. g .. " is after the previous group's last registration")
		end
	end

	-- the constants directly after TIER3_QUEST_STRING_4_SIDE4, under a blank line and the comment; the met key after a blank line and its comment
	local side4 = indexOf(list, 'TIER3_QUEST_STRING_4_SIDE4 = {type = "delivery", name = "naboo_rebel_tier3_4_d"},')

	lu.assertNotNil(side4, "TIER3_QUEST_STRING_4_SIDE4")
	lu.assertEquals(list[side4 + 1], "", "a blank line after TIER3_QUEST_STRING_4_SIDE4")
	lu.assertEquals(list[side4 + 2], CONSTANT_COMMENT, "the comment after the blank line")

	for i, constant in ipairs(CONSTANTS) do
		lu.assertEquals(trim(list[side4 + 2 + i]), constant, "constant " .. i .. " in contract order")
	end

	local after = side4 + 2 + #CONSTANTS

	lu.assertEquals(list[after + 1], "", "a blank line before the met key comment")
	lu.assertEquals(list[after + 2], MET_COMMENT, "the met key comment")
	lu.assertEquals(trim(list[after + 3]), 'TIER4_MET_KEY = "VortexSquadronScreenplay:metTier4",', "the met key")
	lu.assertEquals(list[after + 4], "", "the existing blank line follows the met key")
	lu.assertEquals(trim(list[after + 5]):sub(1, 2), "--", "the VORTEX_PILOT_KEY comment follows")

	-- the reset directly after resetEzkielQuests and before the Kiizete comment
	local ezkiel = indexOf(list, "function VortexSquadronScreenplay:resetEzkielQuests(pPlayer)")
	local evin = indexOf(list, "function VortexSquadronScreenplay:resetEvinQuests(pPlayer)")
	local kiizete = indexOf(list, "-- Kiizete's session flags (SWG scriptVars imp_isasking and q1_discussed): server memory, dropped at logout (feature vortex-tier1-kiizete)")

	lu.assertNotNil(ezkiel, "resetEzkielQuests")
	lu.assertNotNil(evin, "resetEvinQuests")
	lu.assertNotNil(kiizete, "the Kiizete comment")
	lu.assertTrue(ezkiel < evin and evin < kiizete, "resetEvinQuests sits between resetEzkielQuests and the Kiizete comment")
	lu.assertEquals(trim(list[evin - 1]), "-- Clears Brother Extok Evin's quests, journal entries and keys (surrender)", "the reset's comment")
	lu.assertEquals(list[evin - 2], "", "one blank line above the reset's comment")
	lu.assertEquals(list[kiizete - 1], "", "one blank line below the reset")
end

-- I-9, A-1, A-6: the reset never touches VORTEX_PILOT_KEY (resetV3fxQuests owns that removal) and ends with the met key removal
function TestEvinPins:test_the_reset_does_not_mention_the_graduation_key()
	requireBase()

	local _, blocks = functionBlocks(readWorking(VSP), "VortexSquadronScreenplay")

	lu.assertNotNil(blocks.resetEvinQuests, "resetEvinQuests exists")
	lu.assertNil(blocks.resetEvinQuests:find("VORTEX_PILOT_KEY", 1, true), "resetEvinQuests must not touch VORTEX_PILOT_KEY")
	contains(blocks.resetEvinQuests, "TIER4_MET_KEY", "resetEvinQuests removes the met key")
end

-- I-9, SC-1: space_helpers.lua gains the blank line, the comment and the one reset call after Ezkiel's reset, and nothing else
function TestEvinPins:test_space_helpers_gains_only_the_tier_4_lines_in_the_vortex_branch()
	requireBase()

	local removed, added, hunks = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(hunks, 1, SH .. ": hunks")
	lu.assertEquals(nonBlank(added), { "-- Tier 4", "VortexSquadronScreenplay:resetEvinQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(#added, 3, SH .. ": added lines including the blank line")

	local list = allLines(readWorking(SH))
	local ezkiel = indexOf(list, "VortexSquadronScreenplay:resetEzkielQuests(pPlayer)")

	lu.assertNotNil(ezkiel, "Ezkiel's reset call")
	lu.assertEquals(list[ezkiel + 1], "", "a blank line after Ezkiel's reset")
	lu.assertEquals(list[ezkiel + 2], "\t\t-- Tier 4", "the comment")
	lu.assertEquals(list[ezkiel + 3], "\t\tVortexSquadronScreenplay:resetEvinQuests(pPlayer)", "Evin's reset")
	lu.assertTrue(trim(list[ezkiel + 4]):find("^elseif") ~= nil, "the Vortex branch ends right after Evin's reset: " .. list[ezkiel + 4])
end

-- I-9: Part B's files, the other trainers, the other squadrons, the points and spawners and every quest-type screenplay are byte-identical to the base
function TestEvinPins:test_part_b_files_the_other_squadrons_and_every_quest_type_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "StormSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local vortex = ROOT .. "screenplays/space/conversations/rebel/vortex_squadron/"
	local convos = ROOT .. "mobile/conversations/space/rebel/vortex_squadron/"

	for _, path in ipairs({
		vortex .. "v3fxConvoHandler.lua", vortex .. "vrovelConvoHandler.lua", vortex .. "ezkielConvoHandler.lua", vortex .. "kiizeteConvoHandler.lua",
		convos .. "v3fx_convo.lua", convos .. "vrovel_convo.lua", convos .. "ezkiel_convo.lua", convos .. "kiizete_convo.lua",
		ROOT .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
		ROOT .. "mobile/space/extok_evin.lua", ROOT .. "mobile/space/ezkiel.lua", ROOT .. "mobile/space/vrovel.lua", ROOT .. "mobile/space/v3_fx.lua",
		ROOT .. "mobile/space/kiizete.lua",
		ROOT .. "mobile/conversations/space/space_conversations.lua", ROOT .. "screenplays/space/screenplays.lua",
		ROOT .. "screenplays/cities/talus_dearic.lua", ROOT .. "screenplays/poi/dantooine_abandoned_rebel_base.lua",
		ROOT .. "ship_mobile/patrol_points/space_dantooine.lua", ROOT .. "ship_mobile/patrol_points/space_endor.lua", ROOT .. "ship_mobile/patrol_points/space_dathomir.lua",
		ROOT .. "ship_mobile/patrol_points/space_yavin4.lua",
		ROOT .. "screenplays/space/spawning/space_dantooine_spawner.lua", ROOT .. "screenplays/space/spawning/space_spawner.lua",
	}) do
		identical(path)
	end

	local _, differing = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(lines(differing), {}, "quest-type screenplays that differ from " .. BASE .. " (none: no new split type is needed)")
end

-- the pin helper itself: a removed comment line ("-- ...") shows in a diff as "--- ..." and must count as removed, not as a header
function TestEvinPins:test_the_diff_reader_counts_a_removed_comment_line_and_skips_only_the_header()
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
