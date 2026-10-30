-- Imperial master trainer: nothing else moves (I-10) and the shared SH lines.
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (I-10, AC-11; Shared code changes; Content contract 3 and 4; Migration of tests).
--
-- The base is `48a226cb6d` (Black Epsilon tier 4 committed, the commit the spec was written on top of); the "now" side is the working tree.
-- Every test skips when git cannot show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same
-- files), as the tier 1 to 3 file pins do.
--
-- Edited existing files come from `git diff --name-only --diff-filter=M` (a staged new file would otherwise count as an edit); new files from
-- `--diff-filter=A` plus the untracked ones.

local lu = require("luaunit")

local BASE = "48a226cb6d"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local DECLANN = "MMOCoreORB/bin/scripts/mobile/space/nial_declann.lua"

-- I-10 + Amendment A-1: the five existing files under bin/ and src/ that change
local EDITED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/nial_declann.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/SpaceDestroyScreenplay.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

-- I-10: the only new production files
local NEW_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/nial_declann_convo.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/MasterTrainerScreenplay.lua",
}

-- The tracked test files this feature edits (Migration of tests, Content contract 4): the 47 -> 48 FIXTURE_COUNTS assertions, the data file, the README
local EXPECTED_TEST_EDITS = {
	"MMOCoreORB/tests/lua/README.md",
	"MMOCoreORB/tests/lua/space_convo_client_strings_data.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_arkon.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_a.lua",
	"MMOCoreORB/tests/lua/test_space_convo_client_strings_imler_b.lua",
	"MMOCoreORB/tests/lua/test_space_corsec_waypoints_data.lua",
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

TestMasterTrainerImperialPins = {}

local MASTER_SH_LINES = {
	"-- Master trainer (Grand Admiral Declann serves every Imperial squadron)",
	'if (pilotProfession == "imperialPilot" and MasterTrainerScreenplay ~= nil) then',
	"MasterTrainerScreenplay:resetDeclannQuests(pPlayer)",
	"end",
}

-- I-10, Shared code changes: space_helpers.lua gains exactly the five Declann lines
function TestMasterTrainerImperialPins:test_space_helpers_differs_from_the_base_only_by_the_five_declann_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	-- git may attribute the blank line to either end of the block, so the blank is counted, not placed (the position is checked on the text below)
	lu.assertEquals(#added, 5, SH .. ": added lines (the four lines of the block and one blank): " .. table.concat(added, " | "))
	lu.assertEquals(nonBlank(added), MASTER_SH_LINES, SH .. ": added lines")
end

-- I-10: the new block sits after the squadron if/elseif chain and before the skills are surrendered
function TestMasterTrainerImperialPins:test_the_declann_reset_sits_between_the_squadron_chain_and_the_skill_loop()
	local text = readSource("bin/scripts/utils/space_helpers.lua")
	local call = "MasterTrainerScreenplay:resetDeclannQuests(pPlayer)"
	local at = text:find(call, 1, true)
	local inquisition = text:find("-- TODO: Add InquisitionSquadronScreenplay reset functions", 1, true)
	local skills = text:find("local pilotSkills = self.pilotSkills[pilotProfession]", 1, true)

	lu.assertNotNil(at, "space_helpers.lua: the Declann reset call")
	lu.assertNotNil(inquisition, "space_helpers.lua: the Inquisition TODO")
	lu.assertNotNil(skills, "space_helpers.lua: the skill loop")
	lu.assertTrue(at > inquisition and at < skills, "space_helpers.lua: the call is after the squadron chain and before the skill loop")
	lu.assertNil(text:find("resetDeclannQuests", at + #call, true), "space_helpers.lua: the Declann reset is called once")
	lu.assertNotNil(text:sub(inquisition, at):find("\n\tend\n", 1), "space_helpers.lua: the call follows the end of the squadron chain")
end

-- I-10: space_conversations.lua gains the template include line and nothing else
function TestMasterTrainerImperialPins:test_space_conversations_gains_only_the_nial_declann_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/imperial/nial_declann_convo.lua")' }, CONVERSATIONS .. ": added lines (one line, no blank)")
end

-- I-10: screenplays.lua gains exactly the five lines of Content contract 3
function TestMasterTrainerImperialPins:test_screenplays_gains_exactly_the_five_master_trainer_lines()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	-- git may attribute the two blank lines to either side of the block, so they are counted, not placed (the positions are checked in the wiring test)
	lu.assertEquals(#added, 5, SCREENPLAYS .. ": added lines (three include or comment lines and two blank): " .. table.concat(added, " | "))
	lu.assertEquals(nonBlank(added), {
		"-- Master Trainers",
		'includeFile("space/squadrons/MasterTrainerScreenplay.lua")',
		'includeFile("space/conversations/imperial/nialDeclannConvoHandler.lua")',
	}, SCREENPLAYS .. ": added lines")
end

-- I-10: nial_declann.lua differs by its two lines
function TestMasterTrainerImperialPins:test_nial_declann_changes_only_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(DECLANN)

	for i, l in ipairs(removed) do
		removed[i] = trim(l)
	end

	for i, l in ipairs(added) do
		added[i] = trim(l)
	end

	table.sort(removed)
	table.sort(added)
	lu.assertEquals(removed, { 'conversationTemplate = "",', "optionsBitmask = AIENABLED + JTLINTERESTING," }, DECLANN .. ": removed lines")
	lu.assertEquals(added, { 'conversationTemplate = "nial_declann_convo_template",', "optionsBitmask = AIENABLED + CONVERSABLE + JTLINTERESTING," }, DECLANN .. ": added lines")
end

-- I-10: Nin's, Hakassha's, Prisk's and Haymir's files, the squadrons, Burke and the other trainers are byte-identical
function TestMasterTrainerImperialPins:test_the_black_epsilon_trainers_the_squadrons_burke_and_the_other_handlers_are_byte_identical_to_the_base()
	requireBase()

	local base = "MMOCoreORB/bin/scripts/"
	local paths = {
		"screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua",
		"screenplays/space/squadrons/HavocSquadronScreenplay.lua",
		"screenplays/space/squadrons/CorsecSquadronScreenplay.lua",
		"screenplays/space/squadrons/RsfSquadronScreenplay.lua",
		"screenplays/space/squadrons/StormSquadronScreenplay.lua",
		"screenplays/space/squadrons/InquisitionSquadronScreenplay.lua",
		"mobile/conversations/space/imperial/black_epsilon_squadron",
		"screenplays/space/conversations/imperial/black_epsilon_squadron",
		"mobile/space/hakassha_sireen.lua",
		"mobile/space/prisk_kith_vys.lua",
		"mobile/space/haymir_rendundi.lua",
		"mobile/space/insurgent.lua",
		"mobile/space/willham_burke.lua",
		"screenplays/space/conversations/neutral",
		"screenplays/space/conversations/rebel",
		"mobile/conversations/space/neutral",
		"mobile/conversations/space/rebel",
		"screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		"screenplays/cities/naboo_theed.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(base .. path))

		lu.assertEquals(rc, 0, base .. path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-10: no quest type or quest logic changes
function TestMasterTrainerImperialPins:test_the_quest_types_and_the_quest_logic_are_untouched()
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
function TestMasterTrainerImperialPins:test_no_ship_template_and_no_cpp_file_changes()
	requireBase()

	local _, ships = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin/scripts/ship_mobile' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin/scripts/ship_mobile' ':/MMOCoreORB/src'")

	lu.assertEquals(lines(ships), {}, "ship templates or src/ files that differ from " .. BASE)
	lu.assertEquals(lines(untracked), {}, "new ship templates or src/ files")
end

-- I-10, AC-11: only the five spec files differ under bin/ and src/ (edits by --diff-filter=M), and the only new files are the template, the handler and MTS
function TestMasterTrainerImperialPins:test_only_the_spec_files_differ_from_the_base_under_bin_and_src()
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

-- AC-11: only the Migration-of-tests and Content contract 4 edits touch existing test files
function TestMasterTrainerImperialPins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_TEST_EDITS, "tracked files under tests/ that differ from " .. BASE)
end

-- AC-11 (Content contract 4): the four fixtures, the java copy and the sids are byte copies of the research clone (skipped without the clone)
function TestMasterTrainerImperialPins:test_the_fixtures_are_byte_copies_of_the_research_clone()
	local root = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"

	local rc = shell("test -d " .. root)

	if rc ~= 0 then
		lu.skip("research clone not found at " .. root)
	end

	local pairs_ = {
		{ root .. "datatables/spacequest/destroy/master_imperial_1.tab", "tests/lua/fixtures/spacequest/destroy/master_imperial_1.tab" },
		{ root .. "datatables/spacequest/destroy/master_imperial_2.tab", "tests/lua/fixtures/spacequest/destroy/master_imperial_2.tab" },
		{ root .. "script/conversation/imperial_master_trainer.java", "tests/lua/fixtures/script/conversation/imperial_master_trainer.java" },
	}

	for _, p in ipairs(pairs_) do
		local rc2, out = shell("cmp " .. p[1] .. " " .. p[2])

		lu.assertEquals(rc2, 0, p[2] .. " is not a byte copy of " .. p[1] .. ": " .. out)
	end

	local skills = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.shared/compiled/game/datatables/skill/skills.tab"
	local rc3, out3 = shell("sed -n '1p;2p;623p' " .. skills .. " | cmp - tests/lua/fixtures/skill/skills.pilot_imperial_navy_master.tab")

	lu.assertEquals(rc3, 0, "skills.pilot_imperial_navy_master.tab is not rows 1, 2 and 623 of skills.tab: " .. out3)
end

-- space-master-mission-quest-type: the A-1 pin (SDS declares failOnLeaveZone = true) is deleted; test_master_mission_quest_type_type.lua
-- (AC-2) asserts the opposite: SDS is stock and no file under bin/ contains failOnLeaveZone.
