-- Inquisition tier 3 (Vrke): nothing else moves (I-13) and the shared lines.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (I-13, AC-12; Shared code changes; Content contract 2 and 4; R-7).
--
-- The base is `git show 4c40d87618` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "4c40d87618"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local ISP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
local VRKE = "MMOCoreORB/bin/scripts/mobile/space/vrke.lua"
local SHIPS = "MMOCoreORB/bin/scripts/ship_mobile/ships/"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/vrke_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/vrke.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/mercenary_spy_fighter_tier4.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/rebel_spyfreighter_tier3.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/shinss_yacht_tier3.lua",
	"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
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

local function lines(text)
	local out = {}

	for line in text:gmatch("[^\n]+") do
		out[#out + 1] = line
	end

	return out
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

TestInquisitionT3Pins = {}

-- I-13, Shared code changes: space_helpers.lua differs only in the Inquisition surrender branch
function TestInquisitionT3Pins:test_space_helpers_differs_from_the_base_only_in_the_vrke_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	table.sort(added)
	lu.assertEquals(removed, {}, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trimmed(added), { "", "-- Tier 3", "InquisitionSquadronScreenplay:resetVrkeQuests(pPlayer)" }, SH .. ": added lines (a blank line, the comment and the call)")
end

-- I-13: the reset call sits right after Fa'Zoll's, before the end of the branch and Declann's call (Barn, Fa'Zoll, Vrke, Declann)
function TestInquisitionT3Pins:test_the_vrke_reset_follows_fa_zolls_reset_inside_the_inquisition_branch()
	requireBase()

	local text = readFile("bin/scripts/utils/space_helpers.lua")
	local barn = text:find("InquisitionSquadronScreenplay:resetBarnQuests(pPlayer)", 1, true)
	local fazoll = text:find("InquisitionSquadronScreenplay:resetFaZollQuests(pPlayer)", 1, true)
	local vrke = text:find("InquisitionSquadronScreenplay:resetVrkeQuests(pPlayer)", 1, true)
	local declann = text:find("MasterTrainerScreenplay:resetDeclannQuests(pPlayer)", 1, true)

	lu.assertTrue(barn ~= nil and fazoll ~= nil and vrke ~= nil and declann ~= nil, "all four reset calls are in space_helpers.lua")
	lu.assertTrue(barn < fazoll and fazoll < vrke and vrke < declann, "order in the file: Barn, Fa'Zoll, Vrke, Declann")
	lu.assertEquals(text:sub(fazoll, vrke):match("end"), nil, "no 'end' between Fa'Zoll's call and Vrke's: same branch")
	lu.assertEquals(text:sub(barn, vrke):match("end"), nil, "no 'end' between Barn's call and Vrke's: same branch")
	lu.assertEquals(select(2, text:gsub("resetVrkeQuests", "")), 1, "Vrke's reset is called exactly once")
end

-- I-13: space_conversations.lua gains the template include line and nothing else
function TestInquisitionT3Pins:test_space_conversations_gains_only_the_vrke_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/imperial/inquisition_squadron/vrke_convo.lua")' }, CONVERSATIONS .. ": added lines (the include, no blank line)")
end

-- I-13: screenplays.lua gains the handler include and nothing else
function TestInquisitionT3Pins:test_screenplays_gains_only_the_vrke_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (the include, no blank line)")
end

-- I-13: the Inquisition squadron file differs by additions only
function TestInquisitionT3Pins:test_the_inquisition_squadron_file_differs_by_additions_only()
	requireBase()

	local removed, added = changedLines(ISP)
	local joined = table.concat(added, "\n")

	lu.assertEquals(removed, {}, ISP .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertStrContains(joined, "resetVrkeQuests")
	lu.assertStrContains(joined, 'QUESTION_BARLOW_KEY = "InquisitionSquadronScreenplay:questionBarlow"', false)
	lu.assertStrContains(joined, 'SPOKE_TO_BARLOW_KEY = "InquisitionSquadronScreenplay:spokeToBarlow"', false)
	lu.assertStrContains(joined, "Tier 3 -- Inquisitor Vrke", false)
	lu.assertEquals(select(2, joined:gsub('registerScreenPlay%("[%w_]+naboo_imperial_tier3[%w_]*", true%)', "")), 16, ISP .. ": sixteen new registerScreenPlay(..., true) lines")
end

-- I-13, Content contract 1: the tier 3 section sits after the tier 2 tables and before the squadron object
function TestInquisitionT3Pins:test_the_tier_3_section_sits_between_the_tier_2_tables_and_the_squadron_object()
	requireBase()

	local text = readFile("bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua")
	local lastTier2 = text:find('registerScreenPlay("destroy_duty_naboo_imperial_tier2_destroyduty", true)', 1, true)
	local firstTier3 = text:find("recovery_naboo_imperial_tier3_1 = SpaceRecoveryScreenplay:new", 1, true)
	local lastTier3 = text:find('registerScreenPlay("assassinate_naboo_imperial_tier3_4_c", true)', 1, true)
	local squadron = text:find("InquisitionSquadronScreenplay = ScreenPlay:new", 1, true)

	lu.assertTrue(lastTier2 ~= nil and firstTier3 ~= nil and lastTier3 ~= nil and squadron ~= nil, "all four anchors are in the file")
	lu.assertTrue(lastTier2 < firstTier3 and firstTier3 < lastTier3 and lastTier3 < squadron, "tier 2 tables, tier 3 tables, squadron object")
	lu.assertTrue(text:find("Tier 3 -- Inquisitor Vrke", 1, true) ~= nil and text:find("Tier 3 -- Inquisitor Vrke", 1, true) < firstTier3, "the section comment comes before the first tier 3 table")
end

-- I-13: Vrke's NPC file changes its conversation template and options mask only
function TestInquisitionT3Pins:test_vrke_changes_only_the_template_and_options_mask_lines()
	requireBase()

	local removed, added = changedLines(VRKE)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED,", 'conversationTemplate = "",' }, VRKE .. ": removed lines")
	lu.assertEquals(trimmed(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", 'conversationTemplate = "vrke_convo_template",' }, VRKE .. ": added lines")
end

-- I-13, FV-9: each of the three inspect ships gains its cargo line directly after questLoot
function TestInquisitionT3Pins:test_the_three_inspect_ships_gain_only_the_cargo_string_line_directly_after_quest_loot()
	requireBase()

	local ships = {
		{ "mercenary_spy_fighter_tier4", "pirate_data", "pirate_data" },
		{ "shinss_yacht_tier3", "shinss_personal_logs", "shinss_personal_logs" },
		{ "rebel_spyfreighter_tier3", "rebel_plans_impt3", "rebel_plans" },
	}

	for _, s in ipairs(ships) do
		local path = SHIPS .. s[1] .. ".lua"
		local removed, added = changedLines(path)

		lu.assertEquals(removed, {}, path .. ": removed lines")
		lu.assertEquals(#added, 1, path .. ": added lines: " .. table.concat(added, " | "))
		lu.assertEquals(trim(added[1] or ""):match('^cargoString = "([^"]*)",'), s[3], path .. ": the added line")

		local text = readFile("bin/scripts/ship_mobile/ships/" .. s[1] .. ".lua")
		local questLoot = text:find('questLoot = "' .. s[2] .. '",\n', 1, true)

		lu.assertNotNil(questLoot, "questLoot line of " .. s[1])
		lu.assertNotNil(text:find('\n\tcargoString = "' .. s[3] .. '",', questLoot, true), s[1] .. ": cargoString directly after questLoot")
		lu.assertEquals(select(2, text:sub(questLoot, (text:find("cargoString", questLoot, true))):gsub("\n", "")), 1, s[1] .. ": no line between questLoot and cargoString")
	end
end

-- I-13: Barn, Fa'Zoll, Barlow, the other squadrons, the broker, Declann and Burke are byte-identical
function TestInquisitionT3Pins:test_barn_fa_zoll_barlow_the_other_squadron_files_and_the_master_trainers_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"StormSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barn_sinkko.lua",
		"MMOCoreORB/bin/scripts/mobile/space/fa_zoll.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barlow.lua",
		"MMOCoreORB/bin/scripts/mobile/space/nial_declann.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/imperial_broker_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/nial_declann_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/themepark/imperial/emperors_retreat.lua",
		"MMOCoreORB/bin/scripts/screenplays/poi/yavin4_imperial_base.lua",
	}) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-13: the other mercenary_spy_fighter tiers and every other ship template are untouched
function TestInquisitionT3Pins:test_the_other_ship_templates_are_untouched()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- " .. spec("MMOCoreORB/bin/scripts/ship_mobile"))
	local files = lines(changed)

	table.sort(files)
	lu.assertEquals(files, { SHIPS .. "mercenary_spy_fighter_tier4.lua", SHIPS .. "rebel_spyfreighter_tier3.lua", SHIPS .. "shinss_yacht_tier3.lua" }, "ship_mobile files that differ from " .. BASE)
end

-- I-13, R-7: only the ten files of the spec differ under bin/ and src/ (eight changed, two new)
function TestInquisitionT3Pins:test_only_the_ten_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-13: the quest types and every other trainer's files are untouched (a subset of the whole-tree pin, named for the failure message)
function TestInquisitionT3Pins:test_the_quest_types_and_the_other_trainers_are_untouched()
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
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron",
		"MMOCoreORB/bin/scripts/ship_mobile/patrol_points",
		"MMOCoreORB/bin/scripts/screenplays/space/spawning",
	}) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end
