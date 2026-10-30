-- Privateer master pilots: nothing else moves (I-9) and the shared SH lines.
-- Spec: .claude/work/space-master-trainer-privateer/01-spec.md (I-9, AC-11; Content contract 1; Shared code changes; Migration of tests).
--
-- The base is `c9f84039c6` (master mission completion recovery committed, the commit the spec was written on top of); the "now" side is the working tree.
-- Every test skips when git cannot show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same
-- files), as the earlier pins files do.
--
-- Edited existing files come from `git diff --name-only --diff-filter=M` (a staged new file would otherwise count as an edit); new files from
-- `--diff-filter=A` plus the untracked ones.

local lu = require("luaunit")

local BASE = "c9f84039c6"
local BIN = "MMOCoreORB/bin/scripts/"
local SH = BIN .. "utils/space_helpers.lua"
local MTS = BIN .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua"
local DT = BIN .. "mobile/conversations/space/imperial/nial_declann_convo.lua"
local DH = BIN .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua"
local BT = BIN .. "mobile/conversations/space/rebel/willham_burke_convo.lua"
local BH = BIN .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua"

-- I-9: the six existing files under bin/ and src/ that change
local EDITED_FILES = { BT, BH, DT, DH, MTS, SH }

table.sort(EDITED_FILES)

-- I-9: no new production file
local NEW_FILES = {}

-- The tracked test files this feature edits (Migration of tests, the two count assertions of the template tests and the two SH pins that the spec's
-- list did not name, the README)
local EXPECTED_TEST_EDITS = {
	"MMOCoreORB/tests/lua/README.md",
	"MMOCoreORB/tests/lua/test_master_trainer_imperial_gates.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_imperial_pins.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_imperial_surrender.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_imperial_template.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_rebel_gates.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_rebel_pins.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_rebel_surrender.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_rebel_template.lua",
}

-- The new files under tests/ (the feature's own tests, data files and the skill excerpt)
local NEW_TEST_FILES = {
	"MMOCoreORB/tests/lua/fixtures/skill/skills.pilot_neutral_master.tab",
	"MMOCoreORB/tests/lua/master_trainer_privateer_data.lua",
	"MMOCoreORB/tests/lua/master_trainer_privateer_screens_data.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_contract.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_gates.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_missions.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_pins.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_rewards.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_surrender.lua",
	"MMOCoreORB/tests/lua/test_master_trainer_privateer_template.lua",
}

-- Shared code changes: the block space_helpers.lua gains
local PRIVATEER_SH_LINES = {
	"-- Master trainers (privateers fly for Grand Admiral Declann or Admiral Burke)",
	'if (pilotProfession == "neutralPilot" and MasterTrainerScreenplay ~= nil) then',
	"MasterTrainerScreenplay:resetDeclannQuests(pPlayer)",
	"MasterTrainerScreenplay:resetBurkeQuests(pPlayer)",
	"end",
}

-- Content contract 1: the lines MTS gains that the spec gives literally
local MTS_LITERAL_LINES = {
	"Privateers (CorSec, RSF, Smugglers) fly the same four missions for SWG's privateer rewards (feature space-master-trainer-privateer).",
	"-- Privateer rewards and master skill (giveRewardOnePriv / giveRewardTwoPriv, grantMasterSkillBoxNeutral in both admirals' scripts)",
	"PRIVATEER_ITEM_REWARD = {",
	'"object/tangible/wearables/jacket/jacket_ace_privateer.iff",',
	'"object/tangible/wearables/helmet/helmet_fighter_privateer_ace.iff",',
	"},",
	'PRIVATEER_MASTER_SKILL = "pilot_neutral_master",',
	"-- Pays a privateer the credits of mission n's quest table and the privateer item instead of the table's item (SWG giveReward*Priv)",
	"function MasterTrainerScreenplay:rewardPrivateer(pPlayer, headGlobal, n)",
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

TestMasterTrainerPrivateerPins = {}

-- I-9: the base is a commit git can show (a quick sanity check that the pins below mean something)
function TestMasterTrainerPrivateerPins:test_the_base_commit_exists()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then
		lu.skip("git cannot show " .. BASE .. ": " .. trim(out))
	end

	lu.assertEquals(rc, 0, out)
end

-- I-9, AC-11: only the six spec files differ under bin/ and src/ (edits by --diff-filter=M); no new, no deleted production file
function TestMasterTrainerPrivateerPins:test_only_the_six_spec_files_differ_from_the_base_under_bin_and_src()
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

-- I-9: there is no C++ change, so the build gate does not apply
function TestMasterTrainerPrivateerPins:test_no_cpp_or_ship_template_file_changes()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/src' ':/MMOCoreORB/bin/scripts/ship_mobile'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src' ':/MMOCoreORB/bin/scripts/ship_mobile'")

	lu.assertEquals(lines(changed), {}, "src/ or ship templates that differ from " .. BASE)
	lu.assertEquals(lines(untracked), {}, "new src/ or ship template files")
end

-- I-9: the two templates and MTS only gain lines (each existing line is kept, in order)
function TestMasterTrainerPrivateerPins:test_the_templates_and_mts_only_gain_lines()
	requireBase()

	for _, path in ipairs({ DT, BT, MTS }) do
		local removed, added = changedLines(path)

		lu.assertEquals(removed, {}, path .. ": removed lines")
		lu.assertTrue(#added > 0, path .. ": gains lines")
	end
end

-- I-9: MTS gains the header line, the constants and the function, as the spec gives them
function TestMasterTrainerPrivateerPins:test_mts_gains_the_literal_lines_of_content_contract_1()
	requireBase()

	local _, added = changedLines(MTS)
	local have = {}

	for _, l in ipairs(nonBlank(added)) do
		have[l] = true
	end

	for _, want in ipairs(MTS_LITERAL_LINES) do
		lu.assertTrue(have[want] == true, MTS .. ": added line missing: " .. want)
	end
end

-- I-9, Shared code changes: space_helpers.lua gains exactly the six privateer lines
function TestMasterTrainerPrivateerPins:test_space_helpers_differs_from_the_base_only_by_the_six_privateer_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	-- git may attribute the blank line to either end of the block, so the blank is counted, not placed
	lu.assertEquals(#added, 6, SH .. ": added lines (the five lines of the block and one blank): " .. table.concat(added, " | "))
	lu.assertEquals(nonBlank(added), PRIVATEER_SH_LINES, SH .. ": added lines")
end

-- I-9: the files the spec names as untouched are byte-identical to the base
function TestMasterTrainerPrivateerPins:test_the_named_files_are_byte_identical_to_the_base()
	requireBase()

	local untouched = {
		"screenplays/space/SpaceMasterDestroyScreenplay.lua", "screenplays/space/SpaceDestroyScreenplay.lua", "screenplays/space/SpaceQuestLogic.lua",
		"mobile/space/nial_declann.lua", "mobile/space/willham_burke.lua",
		"screenplays/space/screenplays.lua", "mobile/conversations/space/space_conversations.lua",
	}

	for _, name in ipairs(untouched) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(BIN .. name))

		lu.assertEquals(rc, 0, name .. " differs from " .. BASE .. ": " .. out)
	end

	-- every squadron handler, trainer template and squadron screenplay, apart from the four edited admiral files and MTS
	local rc, out = shell("git diff --name-only " .. BASE .. " -- " .. spec(BIN .. "screenplays/space") .. " " .. spec(BIN .. "mobile/conversations/space") .. " " .. spec(BIN .. "mobile/space"))

	lu.assertEquals(rc, 0, out)

	local files = lines(out)

	table.sort(files)

	local want = { BT, BH, DT, DH, MTS }

	table.sort(want)
	lu.assertEquals(files, want, "files under screenplays/space, mobile/conversations/space and mobile/space that differ from " .. BASE)
end

-- AC-11: only the Migration-of-tests edits touch existing test files
function TestMasterTrainerPrivateerPins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_TEST_EDITS, "tracked files under tests/ that differ from " .. BASE)
end

-- AC-11: the new files under tests/ are the feature's own
function TestMasterTrainerPrivateerPins:test_the_new_test_files_are_the_features_own()
	requireBase()

	local _, added = shell("git diff --name-only --diff-filter=A " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/tests'")
	local files = lines(added .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, NEW_TEST_FILES, "new files under tests/ (staged or untracked)")
end

-- AC-1, Content contract 5: the skill excerpt is rows 1, 2 and 642 of the SWG skills.tab, byte for byte (skipped without the research clone)
function TestMasterTrainerPrivateerPins:test_the_skill_excerpt_is_rows_1_2_and_642_of_the_swg_skills_table()
	local skills = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.shared/compiled/game/datatables/skill/skills.tab"

	if shell("test -f " .. skills) ~= 0 then
		lu.skip("research clone not found at " .. skills)
	end

	local rc, out = shell("sed -n '1p;2p;642p' " .. skills .. " | cmp - tests/lua/fixtures/skill/skills.pilot_neutral_master.tab")

	lu.assertEquals(rc, 0, "skills.pilot_neutral_master.tab is not rows 1, 2 and 642 of skills.tab: " .. out)
end

-- AC-1: the two quest tables and the two java files the earlier features copied are untouched by this one
function TestMasterTrainerPrivateerPins:test_the_earlier_fixtures_are_unchanged()
	requireBase()

	local rc, out = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/tests/lua/fixtures'")

	lu.assertEquals(rc, 0, out)
	lu.assertEquals(lines(out), {}, "tracked fixtures that differ from " .. BASE)
end
