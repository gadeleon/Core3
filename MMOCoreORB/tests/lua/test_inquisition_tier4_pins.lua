-- Inquisition tier 4 (Ja'ce Yiaso): nothing else moves (I-13) and the shared lines.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (I-13, AC-13; Shared code changes; Content contract 2 and 4; Migration of tests; R-7).
--
-- The base is `git show 2eae193d14` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.
--
-- The file lists work whether the feature's new files are untracked or staged: modified files come from `git diff --diff-filter=M <base>` (working
-- tree against the base), new files from `git diff --diff-filter=A <base>` (staged adds) joined with `git ls-files --others` (untracked), de-duplicated.

local lu = require("luaunit")

local BASE = "2eae193d14"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local ISP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
local JACE = "MMOCoreORB/bin/scripts/mobile/space/jace_yiaso.lua"
local SHIP = "MMOCoreORB/bin/scripts/ship_mobile/ships/crystal_smuggler_yt1300_tier4.lua"

local MODIFIED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/jace_yiaso.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/crystal_smuggler_yt1300_tier4.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

local NEW_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/jace_yiaso_convo.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/jaceYiasoConvoHandler.lua",
}

-- Existing test files and docs this feature edits (Migration of tests, Content contract 5)
local EDITED_TEST_FILES = {
	"MMOCoreORB/tests/lua/README.md",
	"MMOCoreORB/tests/lua/space_convo_client_strings_data.lua",
	"MMOCoreORB/tests/lua/test_inquisition_tier2_surrender.lua",
	"MMOCoreORB/tests/lua/test_inquisition_tier3_barlow_strings.lua",
	"MMOCoreORB/tests/lua/test_inquisition_tier3_surrender.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_imperial_surrender.lua",
	"MMOCoreORB/tests/lua/test_smuggler_tier2_data.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_arkon.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_a.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_b.lua",
	"MMOCoreORB/tests/lua/test_space_trainer_rewards_conformance.lua",
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

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

-- sorted, de-duplicated union of path lists
local function union(...)
	local seen, out = {}, {}

	for _, list in ipairs({ ... }) do
		for _, path in ipairs(list) do
			if not seen[path] then
				seen[path] = true
				out[#out + 1] = path
			end
		end
	end

	table.sort(out)
	return out
end

-- Repo-root-relative paths (git's default) under `pathspecs` that exist in the base and differ now (working tree against the base)
local function modifiedFiles(pathspecs)
	local rc, out = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- " .. pathspecs)

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	return lines(out)
end

-- New files under `pathspecs`: staged adds (git diff --diff-filter=A against the base) and untracked files
local function newFiles(pathspecs)
	local rc, added = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- " .. pathspecs)

	lu.assertEquals(rc, 0, "git diff failed: " .. added)

	local rc2, untracked = shell("git ls-files --others --exclude-standard --full-name -- " .. pathspecs)

	lu.assertEquals(rc2, 0, "git ls-files failed: " .. untracked)

	return union(lines(added), lines(untracked))
end

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... })
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added = {}, {}

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 3) ~= "---" and line:sub(1, 3) ~= "+++" then
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added
end

local function trimmed(list)
	local out = {}

	for i, l in ipairs(list) do
		out[i] = trim(l)
	end

	return out
end

local function readFile(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path)
	local text = f:read("a")

	f:close()
	return text
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	return rc == 0, out
end

TestInquisitionT4Pins = {}

-- I-13, Shared code changes SC-1: space_helpers.lua differs only in the Inquisition surrender branch
function TestInquisitionT4Pins:test_space_helpers_differs_from_the_base_only_in_the_jace_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trimmed(added), { "", "-- Tier 4", "InquisitionSquadronScreenplay:resetJaceYiasoQuests(pPlayer)" }, SH .. ": added lines (a blank line, the comment and the call)")
end

-- I-13: the reset call sits right after Vrke's, before the end of the branch and Declann's call (Barn, Fa'Zoll, Vrke, Ja'ce, Declann)
function TestInquisitionT4Pins:test_the_jace_reset_follows_vrkes_reset_inside_the_inquisition_branch()
	requireBase()

	local text = readFile("bin/scripts/utils/space_helpers.lua")
	local barn = text:find("InquisitionSquadronScreenplay:resetBarnQuests(pPlayer)", 1, true)
	local fazoll = text:find("InquisitionSquadronScreenplay:resetFaZollQuests(pPlayer)", 1, true)
	local vrke = text:find("InquisitionSquadronScreenplay:resetVrkeQuests(pPlayer)", 1, true)
	local jace = text:find("InquisitionSquadronScreenplay:resetJaceYiasoQuests(pPlayer)", 1, true)
	local declann = text:find("MasterTrainerScreenplay:resetDeclannQuests(pPlayer)", 1, true)

	lu.assertTrue(barn ~= nil and fazoll ~= nil and vrke ~= nil and jace ~= nil and declann ~= nil, "all five reset calls are in space_helpers.lua")
	lu.assertTrue(barn < fazoll and fazoll < vrke and vrke < jace and jace < declann, "order in the file: Barn, Fa'Zoll, Vrke, Ja'ce, Declann")
	lu.assertEquals(text:sub(vrke, jace):match("end"), nil, "no 'end' between Vrke's call and Ja'ce's: same branch")
	lu.assertEquals(select(2, text:gsub("resetJaceYiasoQuests", "")), 1, "Ja'ce's reset is called exactly once")
end

-- I-13: space_conversations.lua gains the template include line and nothing else
function TestInquisitionT4Pins:test_space_conversations_gains_only_the_jace_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/imperial/inquisition_squadron/jace_yiaso_convo.lua")' }, CONVERSATIONS .. ": added lines (the include, no blank line)")
end

-- I-13: screenplays.lua gains the handler include and nothing else
function TestInquisitionT4Pins:test_screenplays_gains_only_the_jace_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/inquisition_squadron/jaceYiasoConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (the include, no blank line)")
end

-- I-13: the Inquisition squadron file differs by additions only
function TestInquisitionT4Pins:test_the_inquisition_squadron_file_differs_by_additions_only()
	requireBase()

	local removed, added = changedLines(ISP)
	local joined = table.concat(added, "\n")

	lu.assertEquals(removed, {}, ISP .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertStrContains(joined, "resetJaceYiasoQuests")
	lu.assertStrContains(joined, 'TIER4_MET_KEY = "InquisitionSquadronScreenplay:metTier4"', false)
	lu.assertStrContains(joined, "Tier 4 -- Grand Inquisitor Ja'ce Yiaso", false)
	lu.assertEquals(select(2, joined:gsub('registerScreenPlay%("[%w_]+naboo_imperial_tier4[%w_]*", true%)', "")), 20, ISP .. ": twenty new registerScreenPlay(..., true) lines")
	lu.assertEquals(select(2, joined:gsub("TIER4_QUEST_STRING_[%w_]+ = {", "")), 20, ISP .. ": twenty TIER4_QUEST_STRING constants")
end

-- I-13, Content contract 1: the tier 4 section sits after the tier 3 tables and before the squadron object
function TestInquisitionT4Pins:test_the_tier_4_section_sits_between_the_tier_3_tables_and_the_squadron_object()
	requireBase()

	local text = readFile("bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua")
	local lastTier3 = text:find('registerScreenPlay("assassinate_naboo_imperial_tier3_4_c", true)', 1, true)
	local firstTier4 = text:find("patrol_naboo_imperial_tier4_1 = SpacePatrolScreenplay:new", 1, true)
	local lastTier4 = text:find('registerScreenPlay("rescue_duty_naboo_imperial_tier4_4", true)', 1, true)
	local squadron = text:find("InquisitionSquadronScreenplay = ScreenPlay:new", 1, true)
	local section = text:find("Tier 4 -- Grand Inquisitor Ja'ce Yiaso", 1, true)

	lu.assertTrue(lastTier3 ~= nil and firstTier4 ~= nil and lastTier4 ~= nil and squadron ~= nil, "all four anchors are in the file")
	lu.assertTrue(lastTier3 < firstTier4 and firstTier4 < lastTier4 and lastTier4 < squadron, "tier 3 tables, tier 4 tables, squadron object")
	lu.assertTrue(section ~= nil and section > lastTier3 and section < firstTier4, "the section comment sits between the last tier 3 table and the first tier 4 table")
end

-- I-13: Ja'ce's NPC file changes its conversation template and options mask only
function TestInquisitionT4Pins:test_jace_changes_only_the_template_and_options_mask_lines()
	requireBase()

	local removed, added = changedLines(JACE)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED,", 'conversationTemplate = "",' }, JACE .. ": removed lines")
	lu.assertEquals(trimmed(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,",
		'conversationTemplate = "jace_yiaso_convo_template", -- Inquisition tier 4 trainer, SWG naboo_imperial_tier4' }, JACE .. ": added lines")
end

-- I-13, FJ-6: the crystal smuggler gains its cargo line directly after questLoot
function TestInquisitionT4Pins:test_the_crystal_smuggler_gains_only_the_cargo_string_line_directly_after_quest_loot()
	requireBase()

	local removed, added = changedLines(SHIP)

	lu.assertEquals(removed, {}, SHIP .. ": removed lines")
	lu.assertEquals(#added, 1, SHIP .. ": added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(added[1] or ""),
		'cargoString = "glowing_crystals", -- SWG space_mobile cargo glowing_crystals; inspect quest naboo_imperial_tier4_1_a (feature inquisition-tier4-jace-yiaso)', SHIP .. ": the added line")

	local text = readFile("bin/scripts/ship_mobile/ships/crystal_smuggler_yt1300_tier4.lua")
	local questLoot = text:find('questLoot = "glowing_crystals",\n', 1, true)

	lu.assertNotNil(questLoot, "questLoot line")
	lu.assertNotNil(text:find('\n\tcargoString = "glowing_crystals",', questLoot, true), "cargoString directly after questLoot")
end

-- I-13: Barn, Fa'Zoll, Vrke, Barlow, the other squadrons, the broker, Declann and Burke are byte-identical
function TestInquisitionT4Pins:test_barn_fa_zoll_vrke_barlow_the_other_squadron_files_and_the_master_trainers_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"StormSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local ok, out = identical(path)

		lu.assertTrue(ok, path .. " differs from " .. BASE .. ": " .. out)
	end

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/vrke_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barlow_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barn_sinkko.lua",
		"MMOCoreORB/bin/scripts/mobile/space/fa_zoll.lua",
		"MMOCoreORB/bin/scripts/mobile/space/vrke.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barlow.lua",
		"MMOCoreORB/bin/scripts/mobile/space/nial_declann.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/imperial_broker_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/nial_declann_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/themepark/imperial/emperors_retreat.lua",
		"MMOCoreORB/bin/scripts/screenplays/themepark/imperial/theed_palace.lua",
	}) do
		local ok, out = identical(path)

		lu.assertTrue(ok, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-13: every other ship template is untouched
function TestInquisitionT4Pins:test_the_other_ship_templates_are_untouched()
	requireBase()

	local files = modifiedFiles(spec("MMOCoreORB/bin/scripts/ship_mobile"))

	table.sort(files)
	lu.assertEquals(files, { SHIP }, "ship_mobile files that differ from " .. BASE)
	lu.assertEquals(newFiles(spec("MMOCoreORB/bin/scripts/ship_mobile")), {}, "new files under ship_mobile")
end

-- I-13, R-7: only the files of the spec differ under bin/ and src/: exactly the six modified files and the two new ones
function TestInquisitionT4Pins:test_only_the_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local pathspec = spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src")
	local modified = modifiedFiles(pathspec)

	table.sort(modified)
	lu.assertEquals(modified, MODIFIED_FILES, "modified files under bin/ and src/ (git diff --diff-filter=M " .. BASE .. ")")
	lu.assertEquals(newFiles(pathspec), NEW_FILES, "new files under bin/ and src/ (staged adds and untracked)")
end

-- I-13: the quest types and every other trainer's files are untouched (a subset of the whole-tree pin, named for the failure message)
function TestInquisitionT4Pins:test_the_quest_types_and_the_other_trainers_are_untouched()
	requireBase()

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceInspectScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceSurvivalScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceRecoveryScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceAssassinateScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDeliveryScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDeliveryNoPickupScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceEscortScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceBattleScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceRescueScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceSurpriseAttackScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpacePatrolScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyDestroyScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyEscortScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyRecoveryScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyRescueScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron",
		"MMOCoreORB/bin/scripts/ship_mobile/patrol_points",
		"MMOCoreORB/bin/scripts/screenplays/space/spawning",
	}) do
		local ok, out = identical(path)

		lu.assertTrue(ok, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- AC-13, Migration of tests: the only existing test files and docs this feature edits are the ratchet and surrender-order tests (and the README)
function TestInquisitionT4Pins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local files = modifiedFiles(spec("MMOCoreORB/tests"))

	table.sort(files)
	lu.assertEquals(files, EDITED_TEST_FILES, "existing files under tests/ that differ from " .. BASE)
end

-- the file lists work for staged and untracked new files alike (the helper itself)
function TestInquisitionT4Pins:test_the_new_file_list_joins_staged_adds_and_untracked_files_without_duplicates()
	lu.assertEquals(union({ "b", "a" }, { "a", "c" }), { "a", "b", "c" }, "union of two lists")
end
