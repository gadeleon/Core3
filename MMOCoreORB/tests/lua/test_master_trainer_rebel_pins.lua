-- Rebel master trainer: nothing else moves (I-10, AC-11, AC-12) and the shared SH lines.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (I-10, AC-11, AC-12; Shared code changes; Content contract 3 and 4; Migration; Migration of tests).
--
-- The base is `2fb246df23` (Imperial master trainer committed, the commit the spec was written on top of); the "now" side is the working tree.
-- Every git-based test skips when git cannot show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the
-- same files), as the earlier pin files do.
--
-- Edited existing files come from `git diff --name-only --diff-filter=M` (a staged new file would otherwise count as an edit); new files from
-- `--diff-filter=A` plus the untracked ones.

local lu = require("luaunit")

local BASE = "2fb246df23"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local BURKE = "MMOCoreORB/bin/scripts/mobile/space/willham_burke.lua"
local MTS = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/MasterTrainerScreenplay.lua"
local HSP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua"

-- I-10 (Q-1 option A): the six existing files under bin/ and src/ that change
local EDITED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/willham_burke.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/MasterTrainerScreenplay.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

-- I-10: the only new production files
local NEW_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel/willham_burke_convo.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
}

-- The tracked test files this feature edits (Migration of tests, Content contract 4): the 48 -> 49 FIXTURE_COUNTS assertions (T1-T5), the data file,
-- the orphan removal (T6-T9, and the three RSF tests that count the 165 quest globals: 164 without the orphan) and the README
local EXPECTED_TEST_EDITS = {
	"MMOCoreORB/tests/lua/README.md",
	"MMOCoreORB/tests/lua/space_convo_client_strings_data.lua",
	"MMOCoreORB/tests/lua/space_corsec_waypoints_data.lua",
	"MMOCoreORB/tests/lua/test_havoc_tier3_name_case_client_names.lua",
	"MMOCoreORB/tests/lua/test_havoc_tier3_name_case_data.lua",
	"MMOCoreORB/tests/lua/test_rsf_tier2_kaydine_data.lua",
	"MMOCoreORB/tests/lua/test_rsf_tier3_quest_data.lua",
	"MMOCoreORB/tests/lua/test_rsf_tier3_renames_data.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_arkon.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_a.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_b.lua",
	"MMOCoreORB/tests/lua/test_space_corsec_waypoints_conformance.lua",
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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... })
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added = {}, {}

	for line in (out .. "\n"):gmatch("(.-)\n") do
		-- the file headers (`--- a/path`, `+++ b/path`); a removed Lua comment line is `--- text` and must not be mistaken for one
		if not line:match("^%-%-%- [ab/]") and not line:match("^%+%+%+ [ab/]") then
			if line:sub(1, 1) == "-" then
				removed[#removed + 1] = line:sub(2)
			elseif line:sub(1, 1) == "+" then
				added[#added + 1] = line:sub(2)
			end
		end
	end

	return removed, added
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

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
end

local function readSource(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path .. " (run from MMOCoreORB/)")
	local text = f:read("a")

	f:close()
	return text
end

local function sorted(list)
	local out = { table.unpack(list) }

	table.sort(out)
	return out
end

TestMasterTrainerRebelPins = {}

local MASTER_SH_LINES = {
	"-- Master trainer (Admiral Burke serves every Rebel squadron)",
	'if (pilotProfession == "rebelPilot" and MasterTrainerScreenplay ~= nil) then',
	"MasterTrainerScreenplay:resetBurkeQuests(pPlayer)",
	"end",
}

-- I-10, Shared code changes: space_helpers.lua gains exactly the five Burke lines
function TestMasterTrainerRebelPins:test_space_helpers_differs_from_the_base_only_by_the_five_burke_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	-- git may attribute the blank line to either end of the block and slide the repeated `end` line, so the blank is counted and the rest compared as a set
	lu.assertEquals(#added, 5, SH .. ": added lines (the four lines of the block and one blank): " .. table.concat(added, " | "))
	lu.assertEquals(sorted(nonBlank(added)), sorted(MASTER_SH_LINES), SH .. ": added lines")
end

-- I-10: Burke's block sits directly after Declann's block and before the skills are surrendered
function TestMasterTrainerRebelPins:test_the_burke_reset_sits_after_the_declann_block_and_before_the_skill_loop()
	local text = readSource("bin/scripts/utils/space_helpers.lua")
	local declann = "MasterTrainerScreenplay:resetDeclannQuests(pPlayer)"
	local call = "MasterTrainerScreenplay:resetBurkeQuests(pPlayer)"
	local d = text:find(declann, 1, true)
	local at = text:find(call, 1, true)
	local skills = text:find("local pilotSkills = self.pilotSkills[pilotProfession]", 1, true)

	lu.assertNotNil(d, "space_helpers.lua: the Declann reset call")
	lu.assertNotNil(at, "space_helpers.lua: the Burke reset call")
	lu.assertNotNil(skills, "space_helpers.lua: the skill loop")
	lu.assertTrue(at > d and at < skills, "space_helpers.lua: Burke's call is after Declann's and before the skill loop")
	lu.assertNil(text:find("resetBurkeQuests", at + #call, true), "space_helpers.lua: the Burke reset is called once")
	lu.assertNotNil(text:sub(d, at):find("\n\tend\n", 1, true), "space_helpers.lua: Burke's block follows the end of Declann's block")
end

-- I-10: space_conversations.lua gains the template include line and nothing else
function TestMasterTrainerRebelPins:test_space_conversations_gains_only_the_willham_burke_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/rebel/willham_burke_convo.lua")' }, CONVERSATIONS .. ": added lines (one line, no blank)")
end

-- I-10: screenplays.lua gains exactly the one handler include
function TestMasterTrainerRebelPins:test_screenplays_gains_exactly_the_burke_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/rebel/willhamBurkeConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (one line, no blank)")
end

-- I-10: willham_burke.lua differs by its two lines
function TestMasterTrainerRebelPins:test_willham_burke_changes_only_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(BURKE)

	for i, l in ipairs(removed) do
		removed[i] = trim(l)
	end

	for i, l in ipairs(added) do
		added[i] = trim(l)
	end

	table.sort(removed)
	table.sort(added)
	lu.assertEquals(removed, { 'conversationTemplate = "",', "optionsBitmask = AIENABLED + JTLINTERESTING," }, BURKE .. ": removed lines")
	lu.assertEquals(added, { 'conversationTemplate = "willham_burke_convo_template",', "optionsBitmask = AIENABLED + CONVERSABLE + JTLINTERESTING," }, BURKE .. ": added lines")
end

-- I-10, D-16: MTS is insertion only: no base line is removed or changed, and the inserted lines include the header line, the constants and the reset
function TestMasterTrainerRebelPins:test_the_quest_file_is_insertion_only()
	requireBase()

	local removed, added = changedLines(MTS)

	lu.assertEquals(removed, {}, MTS .. ": removed lines")

	local set = {}

	for _, l in ipairs(added) do
		set[trim(l)] = (set[trim(l)] or 0) + 1
	end

	for _, want in ipairs({
		"Admiral Burke's quests, ported from SWG-Source destroy/master_rebel_1 and master_rebel_2 (feature space-master-trainer-rebel).",
		"-- Admiral Willham Burke (rebel_master_trainer.java)",
		'QUEST_STRING_REBEL_1 = {type = "destroy", name = "master_rebel_1"},',
		'QUEST_STRING_REBEL_2 = {type = "destroy", name = "master_rebel_2"},',
		'registerScreenPlay("destroy_master_rebel_1", true)',
		'registerScreenPlay("destroy_master_rebel_2", true)',
		"function MasterTrainerScreenplay:resetBurkeQuests(pPlayer)",
	}) do
		lu.assertNotNil(set[want], MTS .. ": added line `" .. want .. "`")
	end
end

-- AC-11 / I-10: HSP loses exactly the 31 orphan lines and gains none (Migration: Orphan removal)
function TestMasterTrainerRebelPins:test_the_havoc_screenplay_loses_exactly_the_31_orphan_lines_and_gains_none()
	requireBase()

	local removed, added = changedLines(HSP)
	local rc, base = shell("git show " .. BASE .. ":" .. HSP)

	lu.assertEquals(rc, 0, "git show failed: " .. base)

	local all = {}

	for line in (base .. "\n"):gmatch("([^\n]*)\n") do
		all[#all + 1] = line
	end

	local want = {}

	for i = 1849, 1874 do
		want[#want + 1] = all[i]
	end

	want[#want + 1] = all[2102]

	for i = 2312, 2315 do
		want[#want + 1] = all[i]
	end

	lu.assertEquals(#want, 31, "orphan lines in the base")
	lu.assertEquals(all[1850], "-- Master Mission: Destroy", "base line 1850")
	lu.assertEquals(all[2313], "\t-- Master", "base line 2313")
	lu.assertEquals(added, {}, HSP .. ": added lines")
	-- identical blank lines may be attributed to either side of a block, so the removed lines are compared as a sorted multiset
	lu.assertEquals(sorted(removed), sorted(want), HSP .. ": removed lines (base lines 1849-1874, 2102 and 2312-2315)")
end

-- I-10: the Imperial master trainer, every Havoc, CorSec, RSF and Black Epsilon handler, template and squadron file, and the Imperial NPC are byte-identical
function TestMasterTrainerRebelPins:test_declann_arkon_the_other_trainers_and_the_other_squadrons_are_byte_identical_to_the_base()
	requireBase()

	local base = "MMOCoreORB/bin/scripts/"
	local paths = {
		"screenplays/space/SpaceDestroyScreenplay.lua",
		"screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua",
		"screenplays/space/squadrons/CorsecSquadronScreenplay.lua",
		"screenplays/space/squadrons/RsfSquadronScreenplay.lua",
		"screenplays/space/squadrons/StormSquadronScreenplay.lua",
		"screenplays/space/squadrons/InquisitionSquadronScreenplay.lua",
		"mobile/conversations/space/imperial",
		"screenplays/space/conversations/imperial",
		"mobile/conversations/space/neutral",
		"screenplays/space/conversations/neutral",
		"mobile/conversations/space/rebel/havoc_squadron",
		"mobile/conversations/space/rebel/j_pai_brek_convo.lua",
		"screenplays/space/conversations/rebel/havoc_squadron",
		"screenplays/space/conversations/rebel/jPaiBrekConvoHandler.lua",
		"mobile/space/nial_declann.lua",
		"mobile/space/hakassha_sireen.lua",
		"mobile/space/prisk_kith_vys.lua",
		"mobile/space/haymir_rendundi.lua",
		"mobile/space/insurgent.lua",
		"screenplays/cities/corellia_doaba_guerfel.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(base .. path))

		lu.assertEquals(rc, 0, base .. path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-10: no quest type or quest logic changes
function TestMasterTrainerRebelPins:test_the_quest_types_and_the_quest_logic_are_untouched()
	requireBase()

	local base = "MMOCoreORB/bin/scripts/screenplays/space/"

	for _, name in ipairs({ "SpaceQuestLogic", "SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceAssassinateScreenplay", "SpaceInspectScreenplay", "SpaceSurvivalScreenplay",
		"SpaceSurpriseAttackScreenplay", "SpaceDeliveryScreenplay", "SpaceDeliveryNoPickupScreenplay", "SpaceEscortScreenplay", "SpaceBattleScreenplay", "SpaceRescueScreenplay",
		"SpaceAttackWaves", "SpaceDutyDestroyScreenplay", "SpaceDutyEscortScreenplay", "SpaceDutyRecoveryScreenplay", "SpaceDutyRescueScreenplay" }) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(base .. name .. ".lua"))

		lu.assertEquals(rc, 0, name .. ".lua differs from " .. BASE .. ": " .. out)
	end
end

-- I-10: no ship template and no C++ changes (the ship templates are read, not edited; the build gate does not apply)
function TestMasterTrainerRebelPins:test_no_ship_template_and_no_cpp_file_changes()
	requireBase()

	local _, ships = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin/scripts/ship_mobile' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin/scripts/ship_mobile' ':/MMOCoreORB/src'")

	lu.assertEquals(lines(ships), {}, "ship templates or src/ files that differ from " .. BASE)
	lu.assertEquals(lines(untracked), {}, "new ship templates or src/ files")
end

-- I-10, AC-12: only the six spec files differ under bin/ and src/ (edits by --diff-filter=M), and the only new files are the template and the handler
function TestMasterTrainerRebelPins:test_only_the_spec_files_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, edited = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, added = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, deleted = shell("git diff --name-only --diff-filter=D " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(edited)
	local fresh = lines(added .. "\n" .. untracked)

	table.sort(files)
	table.sort(fresh)
	lu.assertEquals(files, EDITED_FILES, "existing files under bin/ and src/ that differ from " .. BASE)
	lu.assertEquals(fresh, NEW_FILES, "new files under bin/ and src/ (staged or untracked)")
	lu.assertEquals(lines(deleted), {}, "files under bin/ and src/ deleted since " .. BASE)
end

-- AC-12: only the Migration-of-tests and Content contract 4 edits touch existing test files
function TestMasterTrainerRebelPins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_TEST_EDITS, "tracked files under tests/ that differ from " .. BASE)
end

-- AC-12 (Content contract 4): the two .tab files, the java copy and the skills excerpt are byte copies of the research clone (skipped without the clone)
function TestMasterTrainerRebelPins:test_the_fixtures_are_byte_copies_of_the_research_clone()
	local root = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

	local rc = shell("test -d " .. root)

	if rc ~= 0 then
		lu.skip("research clone not found at " .. root)
	end

	local pairs_ = {
		{ root .. "datatables/spacequest/destroy/master_rebel_1.tab", "tests/lua/fixtures/spacequest/destroy/master_rebel_1.tab" },
		{ root .. "datatables/spacequest/destroy/master_rebel_2.tab", "tests/lua/fixtures/spacequest/destroy/master_rebel_2.tab" },
		{ root .. "script/conversation/rebel_master_trainer.java", "tests/lua/fixtures/script/conversation/rebel_master_trainer.java" },
	}

	for _, p in ipairs(pairs_) do
		local rc2, out = shell("cmp " .. p[1] .. " " .. p[2])

		lu.assertEquals(rc2, 0, p[2] .. " is not a byte copy of " .. p[1] .. ": " .. out)
	end

	local skills = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.shared/compiled/game/datatables/skill/skills.tab"
	local rc3, out3 = shell("sed -n '1p;2p;604p' " .. skills .. " | cmp - tests/lua/fixtures/skill/skills.pilot_rebel_navy_master.tab")

	lu.assertEquals(rc3, 0, "skills.pilot_rebel_navy_master.tab is not rows 1, 2 and 604 of skills.tab: " .. out3)
end

-- A-1: SpaceDestroyScreenplay still declares the opt-in field, default true (it is not edited by this feature)
function TestMasterTrainerRebelPins:test_space_destroy_screenplay_declares_the_field_with_default_true()
	local text = readSource("bin/scripts/screenplays/space/SpaceDestroyScreenplay.lua")

	lu.assertNotNil(text:find("failOnLeaveZone%s*=%s*true"), "SpaceDestroyScreenplay.lua: failOnLeaveZone = true default")
end

-- Hygiene: no bytecode cache and no stray backup file in the tests tree
function TestMasterTrainerRebelPins:test_the_tests_tree_has_no_pycache_or_backup_files()
	local rc, out = shell("find tests -name __pycache__ -o -name '*.orig' -o -name 'test_zz*'")

	lu.assertEquals(rc, 0, "find failed: " .. out)
	lu.assertEquals(lines(out), {}, "stray files under tests/")
end
