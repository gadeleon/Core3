-- Black Epsilon tier 4: nothing else moves (I-13) and the one shared line.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (I-13, AC-13; Shared code changes; Content contract 4 and 5; Migration of tests).
--
-- The base is `8bf0f63ead` (Black Epsilon tier 3 committed, the commit the spec was written on top of); the "now" side is the working tree.
-- Every test skips when git cannot show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same
-- files), as the tier 1 to 3 file pins do.
--
-- Edited existing files come from `git diff --name-only --diff-filter=M` (a staged new file would otherwise count as an edit); new files from
-- `--diff-filter=A` plus the untracked ones.

local lu = require("luaunit")

local BASE = "8bf0f63ead"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local BSP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local INSURGENT = "MMOCoreORB/bin/scripts/mobile/space/insurgent.lua"

local SHIPS = {
	{ file = "MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_merc_captain_tier4.lua", loot = "corellia_imperial_tier4_inspect1" },
	{ file = "MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_merc_group_leader_tier5.lua", loot = "corellia_imperial_tier4_inspect2" },
	{ file = "MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_commander_tier4.lua", loot = "corellia_imperial_tier4_inspect3" },
}

local EDITED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/insurgent.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/BlackEpsilonSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_commander_tier4.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_merc_captain_tier4.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/velocity_merc_group_leader_tier5.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
}

local NEW_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler.lua",
}

-- The tracked test files this feature edits (Migration of tests, Content contract 5): the 46 -> 47 FIXTURE_COUNTS assertions, the data file, the README
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

local function readSource(path)
	local f = assert(io.open(path, "r"), "cannot open " .. path .. " (run from MMOCoreORB/)")
	local text = f:read("a")

	f:close()
	return text
end

TestBlackEpsilonT4Pins = {}

-- I-13, Shared code changes: space_helpers.lua differs only by the tier 4 reset lines
function TestBlackEpsilonT4Pins:test_space_helpers_differs_from_the_base_only_by_the_nin_gursawe_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(nonBlank(added), { "-- Tier 4", "BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(pPlayer)" }, SH .. ": added lines")
end

-- I-13: the new call sits right after the tier 3 call
function TestBlackEpsilonT4Pins:test_the_nin_gursawe_reset_follows_the_haymir_reset_in_the_surrender_branch()
	local text = readSource("bin/scripts/utils/space_helpers.lua")
	local haymirCall = "BlackEpsilonSquadronScreenplay:resetHaymirQuests(pPlayer)"
	local ninCall = "BlackEpsilonSquadronScreenplay:resetNinGursaweQuests(pPlayer)"
	local haymir = text:find(haymirCall, 1, true)
	local nin = text:find(ninCall, 1, true)

	lu.assertNotNil(haymir, "space_helpers.lua: the tier 3 reset call")
	lu.assertNotNil(nin, "space_helpers.lua: the tier 4 reset call")
	lu.assertTrue(nin > haymir, "space_helpers.lua: the tier 4 reset comes after the tier 3 reset")
	lu.assertTrue(text:sub(haymir, nin):find("-- Tier 4", 1, true) ~= nil, "space_helpers.lua: the '-- Tier 4' comment sits between the two calls")
	lu.assertNil(text:find("resetNinGursaweQuests", nin + #ninCall, true), "space_helpers.lua: the tier 4 reset is called once")
end

-- I-13: space_conversations.lua gains the template include line and nothing else
function TestBlackEpsilonT4Pins:test_space_conversations_gains_only_the_nin_gursawe_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(nonBlank(added), { 'includeFile("conversations/space/imperial/black_epsilon_squadron/nin_gursawe_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-13: screenplays.lua gains the handler include and nothing else
function TestBlackEpsilonT4Pins:test_screenplays_gains_only_the_nin_gursawe_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(nonBlank(added), { 'includeFile("space/conversations/imperial/black_epsilon_squadron/ninGursaweConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-13: BSP's tier 1 to 3 lines are unchanged: additions only
function TestBlackEpsilonT4Pins:test_the_black_epsilon_squadron_file_only_gains_lines()
	requireBase()

	local removed, added = changedLines(BSP)

	lu.assertEquals(removed, {}, BSP .. ": removed lines (tiers 1 to 3 stay)")
	lu.assertTrue(#added > 0, BSP .. ": gains the tier 4 tables and the reset")
end

-- I-13: the Insurgent NPC file changes only the two lines of the spec
function TestBlackEpsilonT4Pins:test_insurgent_changes_only_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(INSURGENT)

	lu.assertEquals(#removed, 1, INSURGENT .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trim(removed[1] or ""), "optionsBitmask = AIENABLED + JTLINTERESTING,", INSURGENT .. ": the removed line")
	lu.assertEquals(#added, 2, INSURGENT .. ": added lines: " .. table.concat(added, " | "))

	local want = { 'conversationTemplate = "nin_gursawe_convo_template",', "optionsBitmask = AIENABLED + CONVERSABLE + JTLINTERESTING," }

	for i, l in ipairs(added) do
		added[i] = trim(l)
	end

	table.sort(want)
	table.sort(added)
	lu.assertEquals(added, want, INSURGENT .. ": the added lines")

	local text = readSource("bin/scripts/mobile/space/insurgent.lua")
	local weapon = text:find('secondaryWeapon = "unarmed",\n', 1, true)

	lu.assertNotNil(weapon, INSURGENT .. ": the secondaryWeapon line")
	lu.assertEquals(text:sub(weapon):match('^[^\n]*\n%s*([^\n]*)\n'), 'conversationTemplate = "nin_gursawe_convo_template",', INSURGENT .. ": conversationTemplate directly after secondaryWeapon")
end

-- I-13, FN-5: each inspect ship template gains the one cargoString line directly after questLoot
function TestBlackEpsilonT4Pins:test_each_inspect_ship_template_gains_only_the_cargo_string_line()
	requireBase()

	for _, ship in ipairs(SHIPS) do
		local removed, added = changedLines(ship.file)

		lu.assertEquals(removed, {}, ship.file .. ": removed lines")
		lu.assertEquals(#added, 1, ship.file .. ": added lines: " .. table.concat(added, " | "))
		lu.assertEquals(trim(added[1] or ""), 'cargoString = "' .. ship.loot .. '",', ship.file .. ": the added line")

		local text = readSource(ship.file:gsub("^MMOCoreORB/", ""))
		local loot = text:find('questLoot = "' .. ship.loot .. '",\n', 1, true)

		lu.assertNotNil(loot, ship.file .. ": questLoot line")
		lu.assertEquals(text:sub(loot):match('^[^\n]*\n%s*([^\n]*)\n'), 'cargoString = "' .. ship.loot .. '",', ship.file .. ": cargoString directly after questLoot")
	end
end

-- I-13: Hakassha's, Prisk's and Haymir's files, the other squadrons and handlers are byte-identical
function TestBlackEpsilonT4Pins:test_the_other_squadrons_and_the_earlier_black_epsilon_trainers_are_byte_identical_to_the_base()
	requireBase()

	local paths = {
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/CorsecSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/RsfSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/hakassha_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/hakasshaConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/hakassha_sireen.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/prisk_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/priskConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/prisk_kith_vys.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron/haymir_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/black_epsilon_squadron/haymirConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/haymir_rendundi.lua",
		"MMOCoreORB/bin/scripts/ship_mobile/ships/rebel_spysmuggler_tier2.lua",
		"MMOCoreORB/bin/scripts/ship_mobile/ships/reb_yavinspy_tier4.lua",
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

-- I-13, AC-13: no quest type or quest logic changes
function TestBlackEpsilonT4Pins:test_the_quest_types_and_the_quest_logic_are_untouched()
	requireBase()

	local base = "MMOCoreORB/bin/scripts/screenplays/space/"

	for _, name in ipairs({ "SpaceQuestLogic", "SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceAssassinateScreenplay", "SpaceInspectScreenplay", "SpaceSurvivalScreenplay",
		"SpaceSurpriseAttackScreenplay", "SpaceDeliveryScreenplay", "SpaceDeliveryNoPickupScreenplay", "SpaceEscortScreenplay", "SpaceBattleScreenplay", "SpaceRescueScreenplay",
		"SpaceAttackWaves", "SpaceDutyDestroyScreenplay", "SpaceDutyEscortScreenplay", "SpaceDutyRecoveryScreenplay", "SpaceDutyRescueScreenplay" }) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(base .. name .. ".lua"))

		lu.assertEquals(rc, 0, name .. ".lua differs from " .. BASE .. ": " .. out)
	end
end

-- I-13, AC-13: only the eight edited files differ under bin/ and src/ (edits by --diff-filter=M), and the only new files are the template and the handler
function TestBlackEpsilonT4Pins:test_only_the_spec_files_differ_from_the_base_under_bin_and_src()
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

-- AC-13: only the Migration-of-tests and Content contract 5 edits touch existing test files
function TestBlackEpsilonT4Pins:test_only_the_migration_edits_touch_existing_test_files()
	requireBase()

	local _, changed = shell("git diff --name-only --diff-filter=M " .. BASE .. " -- ':/MMOCoreORB/tests'")
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_TEST_EDITS, "tracked files under tests/ that differ from " .. BASE)
end
