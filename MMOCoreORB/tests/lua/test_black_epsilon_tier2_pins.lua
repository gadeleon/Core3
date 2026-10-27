-- Black Epsilon tier 2: nothing else moves (I-11) and the one shared line.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (I-11, AC-12; Shared code changes; Content contract 4 and 5; Migration of tests).
--
-- The base is `git show 86bcd9d147` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "86bcd9d147"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local BSP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local PRISK_NPC = "MMOCoreORB/bin/scripts/mobile/space/prisk_kith_vys.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/prisk_kith_vys.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

-- The tracked test files this feature edits (Migration of tests, Content contract 5)
local EXPECTED_TEST_EDITS = {
	"MMOCoreORB/tests/lua/README.md",
	"MMOCoreORB/tests/lua/space_convo_client_strings_data.lua",
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

TestBlackEpsilonT2Pins = {}

-- I-11, Shared code changes: space_helpers.lua differs only by the tier 2 reset in the Black Epsilon surrender branch
function TestBlackEpsilonT2Pins:test_space_helpers_differs_from_the_base_only_by_the_prisk_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 2", "BlackEpsilonSquadronScreenplay:resetPriskQuests(pPlayer)" }, SH .. ": added lines")
end

-- I-11: the new call sits right after the tier 1 call
function TestBlackEpsilonT2Pins:test_the_prisk_reset_follows_the_hakassha_reset_in_the_surrender_branch()
	local f = assert(io.open("bin/scripts/utils/space_helpers.lua", "r"), "cannot open bin/scripts/utils/space_helpers.lua (run from MMOCoreORB/)")
	local text = f:read("a")

	f:close()

	local hak = text:find("BlackEpsilonSquadronScreenplay:resetHakasshaQuests(pPlayer)", 1, true)
	local prisk = text:find("BlackEpsilonSquadronScreenplay:resetPriskQuests(pPlayer)", 1, true)

	lu.assertNotNil(hak, "space_helpers.lua: the tier 1 reset call")
	lu.assertNotNil(prisk, "space_helpers.lua: the tier 2 reset call")
	lu.assertTrue(prisk > hak, "space_helpers.lua: the tier 2 reset comes after the tier 1 reset")
	lu.assertTrue(text:sub(hak, prisk):find("-- Tier 2", 1, true) ~= nil, "space_helpers.lua: the '-- Tier 2' comment sits between the two calls")
	lu.assertNil(text:find("resetPriskQuests", prisk + #"BlackEpsilonSquadronScreenplay:resetPriskQuests(pPlayer)", true), "space_helpers.lua: the tier 2 reset is called once")
end

-- I-11: space_conversations.lua gains the template include line and nothing else
function TestBlackEpsilonT2Pins:test_space_conversations_gains_only_the_prisk_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(nonBlank(added), { 'includeFile("conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-11: screenplays.lua gains the handler include and nothing else
function TestBlackEpsilonT2Pins:test_screenplays_gains_only_the_prisk_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(nonBlank(added), { 'includeFile("space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-11: BSP's tier 1 lines are unchanged: additions only
function TestBlackEpsilonT2Pins:test_the_black_epsilon_squadron_file_only_gains_lines()
	requireBase()

	local removed = changedLines(BSP)

	lu.assertEquals(removed, {}, BSP .. ": removed lines (tier 1 stays)")
end

-- I-11: the Prisk NPC file changes only the two lines of the spec
function TestBlackEpsilonT2Pins:test_prisk_kith_vys_changes_only_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(PRISK_NPC)

	table.sort(removed)
	table.sort(added)
	lu.assertEquals(#removed, 2, PRISK_NPC .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, PRISK_NPC .. ": added lines: " .. table.concat(added, " | "))

	local want = { 'conversationTemplate = "prisk_convo_template",', "optionsBitmask = AIENABLED + CONVERSABLE + JTLINTERESTING," }

	for i, l in ipairs(added) do
		added[i] = trim(l)
	end

	table.sort(want)
	table.sort(added)
	lu.assertEquals(added, want, PRISK_NPC .. ": the added lines")
end

-- I-11: the CorSec, RSF and Havoc squadron files and handlers, and Hakassha's three files, are byte-identical
function TestBlackEpsilonT2Pins:test_the_other_squadrons_and_hakasshas_files_are_byte_identical_to_the_base()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/CorsecSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/RsfSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/hakassha_sireen.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11, AC-12: no quest type, broker or other shared script changes
function TestBlackEpsilonT2Pins:test_the_quest_types_and_the_quest_logic_are_untouched()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpacePatrolScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceRecoveryScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceAssassinateScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceInspectScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceSurvivalScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceSurpriseAttackScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyDestroyScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceDutyEscortScreenplay.lua",
	}

	for _, path in ipairs(paths) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11, AC-12: only the seven files of the spec differ under bin/ and src/
function TestBlackEpsilonT2Pins:test_only_the_seven_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- AC-12: only the Migration-of-tests and Content contract 5 edits touch existing test files
function TestBlackEpsilonT2Pins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_TEST_EDITS, "tracked files under tests/ that differ from " .. BASE)
end
