-- Inquisition tier 2: nothing else moves (I-13) and the shared lines.
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (I-13, AC-13; Shared code changes; Content contract 2 and 4; R-6).
--
-- The base is `git show a59a1568f3` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot
-- show the base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "a59a1568f3"
local SH = "MMOCoreORB/bin/scripts/utils/space_helpers.lua"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local ISP = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua"
local FA_ZOLL = "MMOCoreORB/bin/scripts/mobile/space/fa_zoll.lua"
local COURIER = "MMOCoreORB/bin/scripts/ship_mobile/ships/mercenary_courier_tier2.lua"

local EXPECTED_FILES = {
	"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua",
	"MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua",
	"MMOCoreORB/bin/scripts/mobile/space/fa_zoll.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua",
	"MMOCoreORB/bin/scripts/screenplays/space/squadrons/InquisitionSquadronScreenplay.lua",
	"MMOCoreORB/bin/scripts/ship_mobile/ships/mercenary_courier_tier2.lua",
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

TestInquisitionT2Pins = {}

-- I-13, Shared code changes: space_helpers.lua differs only in the Inquisition surrender branch
function TestInquisitionT2Pins:test_space_helpers_differs_from_the_base_only_in_the_fa_zoll_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	table.sort(added)
	lu.assertEquals(removed, {}, SH .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trimmed(added), { "", "-- Tier 2", "InquisitionSquadronScreenplay:resetFaZollQuests(pPlayer)" }, SH .. ": added lines (a blank line, the comment and the call)")
end

-- I-13: the reset call sits right after Barn's, before the end of the branch and Declann's call
function TestInquisitionT2Pins:test_the_fa_zoll_reset_follows_barns_reset_inside_the_inquisition_branch()
	requireBase()

	local f = assert(io.open("bin/scripts/utils/space_helpers.lua", "r"))
	local text = f:read("a")

	f:close()

	local barn = text:find("InquisitionSquadronScreenplay:resetBarnQuests(pPlayer)", 1, true)
	local fazoll = text:find("InquisitionSquadronScreenplay:resetFaZollQuests(pPlayer)", 1, true)
	local declann = text:find("MasterTrainerScreenplay:resetDeclannQuests(pPlayer)", 1, true)

	lu.assertTrue(barn ~= nil and fazoll ~= nil and declann ~= nil, "all three reset calls are in space_helpers.lua")
	lu.assertTrue(barn < fazoll and fazoll < declann, "order in the file: Barn, Fa'Zoll, Declann")
	lu.assertEquals(text:sub(barn, fazoll):match("end"), nil, "no 'end' between Barn's call and Fa'Zoll's: same branch")
end

-- I-13: space_conversations.lua gains the template include line and nothing else
function TestInquisitionT2Pins:test_space_conversations_gains_only_the_fa_zoll_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)
	local code = {}

	for _, l in ipairs(added) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(code, { 'includeFile("conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua")' }, CONVERSATIONS .. ": added lines")
	lu.assertEquals(#added, 1, CONVERSATIONS .. ": no blank line besides the include")
end

-- I-13: screenplays.lua gains the handler include and nothing else
function TestInquisitionT2Pins:test_screenplays_gains_only_the_fa_zoll_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (the include, no blank line)")
end

-- I-13: the Inquisition squadron file differs by additions plus the one comment above INQUISITORIAL_AGENT_KEY
function TestInquisitionT2Pins:test_the_inquisition_squadron_file_changes_only_the_agent_key_comment_and_adds_lines()
	requireBase()

	local removed, added = changedLines(ISP)

	lu.assertEquals(#removed, 1, ISP .. ": removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(trim(removed[1] or ""), "-- Set by the tier 2 feature when Fa'Zoll signs the pilot up (SWG makeInquisitorialAgent); only read here", ISP .. ": the replaced comment")

	local joined = table.concat(added, "\n")
	local comment

	for _, l in ipairs(added) do
		if l:find("sign_up_agent", 1, true) then
			comment = l
		end
	end

	lu.assertNotNil(comment, ISP .. ": the new comment names sign_up_agent")
	lu.assertStrContains(comment, "makeInquisitorialAgent", false)
	lu.assertStrContains(joined, "resetFaZollQuests")
	lu.assertStrContains(joined, 'INQUISITORIAL_AGENT_KEY', false)
	lu.assertNil(joined:find('INQUISITORIAL_AGENT_KEY = "', 1, true), ISP .. ": the key's value line is not rewritten")
end

-- I-13: Fa'Zoll's NPC file changes its conversation template and options mask only
function TestInquisitionT2Pins:test_fa_zoll_changes_only_the_template_and_options_mask_lines()
	requireBase()

	local removed, added = changedLines(FA_ZOLL)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = JTLINTERESTING,", 'conversationTemplate = "",' }, FA_ZOLL .. ": removed lines")
	lu.assertEquals(trimmed(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", 'conversationTemplate = "fa_zoll_convo_template",' }, FA_ZOLL .. ": added lines")
end

-- I-13, FI-1: the courier template gains its cargo line directly after questLoot
function TestInquisitionT2Pins:test_the_courier_template_gains_only_the_cargo_string_line()
	requireBase()

	local removed, added = changedLines(COURIER)

	lu.assertEquals(removed, {}, COURIER .. ": removed lines")
	lu.assertEquals(#added, 1, COURIER .. ": added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(added[1] or ""):match('^cargoString = "encrypted_documents",'), 'cargoString = "encrypted_documents",', COURIER .. ": the added line")

	local f = assert(io.open("bin/scripts/ship_mobile/ships/mercenary_courier_tier2.lua", "r"))
	local text = f:read("a")

	f:close()

	local questLoot = text:find('questLoot = "encrypted_documents",\n', 1, true)

	lu.assertNotNil(questLoot, "questLoot line")
	lu.assertNotNil(text:find('\n\tcargoString = "encrypted_documents",', questLoot, true), "cargoString directly after questLoot")
	lu.assertEquals(select(2, text:sub(questLoot, (text:find("cargoString", questLoot, true))):gsub("\n", "")), 1, "no line between questLoot and cargoString")
end

-- I-13: Barn, the other squadrons, the broker, Declann and Burke are byte-identical
function TestInquisitionT2Pins:test_barn_the_other_squadron_files_and_the_master_trainers_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"StormSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		local path = "MMOCoreORB/bin/scripts/screenplays/space/squadrons/" .. name .. ".lua"
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barn_sinkko.lua",
		"MMOCoreORB/bin/scripts/mobile/space/vrke.lua",
		"MMOCoreORB/bin/scripts/mobile/space/nial_declann.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/imperial_broker_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/nial_declann_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/themepark/imperial/emperors_retreat.lua",
	}) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-13, R-6: only the eight files of the spec differ under bin/ and src/
function TestInquisitionT2Pins:test_only_the_eight_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-13: the quest types and every other trainer's files are untouched (a subset of the whole-tree pin, named for the failure message)
function TestInquisitionT2Pins:test_the_quest_types_and_the_other_trainers_are_untouched()
	requireBase()

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceInspectScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceSurvivalScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceRecoveryScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceAssassinateScreenplay.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron",
	}) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end
