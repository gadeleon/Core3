-- Smuggler tier 2 (Shamdon): nothing else moves (I-11) and the shared edits (SC-1, SC-2, SC-3).
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (I-11, AC-13; Shared code changes; Content contract 4 and 5).
--
-- The base is `git show 4c734ecb54` (the commit the spec was written on); the "now" side is the working tree. Every git test skips when git cannot show
-- the base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. The last class
-- (TestSmugglerT2NoCaller) is not git-gated.

local lu = require("luaunit")

local BASE = "4c734ecb54"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local ESCORT = ROOT .. "screenplays/space/SpaceEscortScreenplay.lua"
local RECOVERY = ROOT .. "screenplays/space/SpaceRecoveryScreenplay.lua"
local SSP = ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local SHAMDON = ROOT .. "mobile/space/shamdon_kree.lua"
local KARRDE_TEMPLATE = ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua"
local KARRDE_HANDLER = ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua"

local EXPECTED_FILES = {
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua",
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua",
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/shamdon_kree.lua",
	ROOT .. "screenplays/space/SpaceEscortScreenplay.lua",
	ROOT .. "screenplays/space/SpaceRecoveryScreenplay.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua",
	ROOT .. "utils/space_helpers.lua",
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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }, hunks)
local function changedLines(path)
	local rc, out = shell("git diff -U0 " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, "git diff failed: " .. out)

	local removed, added, hunks = {}, {}, 0

	for line in (out .. "\n"):gmatch("(.-)\n") do
		if line:sub(1, 2) == "@@" then
			hunks = hunks + 1
		elseif line:sub(1, 3) ~= "---" and line:sub(1, 3) ~= "+++" then
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

local function trimmed(list)
	local out = {}

	for i, l in ipairs(list) do
		out[i] = trim(l)
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

	return rc == 0, out
end

local function fileLines(path)
	local f = assert(io.open(path, "r"))
	local all = {}

	for l in f:lines() do
		all[#all + 1] = trim(l)
	end

	f:close()
	return all
end

TestSmugglerT2Pins = {}

-- SC-3, I-11: space_helpers.lua differs only by the Shamdon reset lines
function TestSmugglerT2Pins:test_space_helpers_differs_from_the_base_only_in_the_shamdon_reset_lines()
	requireBase()

	local removed, added, hunks = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(trimmed(added), { "-- Tier 2", "SmugglerSquadronScreenplay:resetShamdonQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(hunks, 1, SH .. ": one hunk (the Smuggler branch)")

	local all = fileLines("bin/scripts/utils/space_helpers.lua")
	local at

	for i, l in ipairs(all) do
		if l == "SmugglerSquadronScreenplay:resetKarrdeQuests(pPlayer)" then
			at = i
		end
	end

	lu.assertNotNil(at, SH .. ": the resetKarrdeQuests call")
	lu.assertEquals(all[at + 1] == "" and { all[at + 2], all[at + 3] } or { all[at + 1], all[at + 2] }, { "-- Tier 2", "SmugglerSquadronScreenplay:resetShamdonQuests(pPlayer)" },
		SH .. ": the Shamdon reset directly after the Karrde reset")
end

-- SC-1, I-11: SpaceEscortScreenplay.lua differs by one line
function TestSmugglerT2Pins:test_the_escort_quest_type_differs_from_the_base_only_by_the_wave_faction_line()
	requireBase()

	local removed, added, hunks = changedLines(ESCORT)

	lu.assertEquals(trimmed(removed), { "local playerFactionHash = SpaceHelpers:getPlayerSpaceFactionHash(pPlayer)" }, ESCORT .. ": removed lines")
	lu.assertEquals(trimmed(added), { "local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)" }, ESCORT .. ": added lines")
	lu.assertEquals(hunks, 1, ESCORT .. ": one hunk (spawnAttackWave)")
end

-- SC-2, I-11: SpaceRecoveryScreenplay.lua differs by one line
function TestSmugglerT2Pins:test_the_recovery_quest_type_differs_from_the_base_only_by_the_wave_faction_line()
	requireBase()

	local removed, added, hunks = changedLines(RECOVERY)

	lu.assertEquals(trimmed(removed), { "local playerFactionHash = SpaceHelpers:getPlayerSpaceFactionHash(pPlayer)" }, RECOVERY .. ": removed lines")
	lu.assertEquals(trimmed(added), { "local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)" }, RECOVERY .. ": added lines")
	lu.assertEquals(hunks, 1, RECOVERY .. ": one hunk (spawnAttackWave)")
end

-- I-11: the SmugglerSquadronScreenplay differs only by additions, apart from the header comment
function TestSmugglerT2Pins:test_the_smuggler_squadron_file_only_gains_lines_except_in_its_header_comment()
	requireBase()

	local removed = changedLines(SSP)
	local _, header = shell("git show " .. BASE .. ":" .. SSP)
	local inHeader = {}
	local n = 0

	for l in (header .. "\n"):gmatch("([^\n]*)\n") do
		inHeader[l] = true
		n = n + 1

		if n >= 12 then
			break
		end
	end

	for _, l in ipairs(removed) do
		lu.assertTrue(inHeader[l] == true, SSP .. ": removed line outside the header comment: " .. l)
	end

	lu.assertTrue(#removed <= 3, SSP .. ": at most the header comment lines are rewritten, got " .. #removed)
end

-- I-11: space_conversations.lua gains the template include line and nothing else
function TestSmugglerT2Pins:test_space_conversations_gains_only_the_shamdon_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-11: screenplays.lua gains the handler include and nothing else
function TestSmugglerT2Pins:test_screenplays_gains_only_the_shamdon_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-11: shamdon_kree.lua differs only by its two fields
function TestSmugglerT2Pins:test_shamdon_kree_differs_from_the_base_only_in_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(SHAMDON)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED + JTLINTERESTING,", 'conversationTemplate = "",' }, SHAMDON .. ": removed lines")

	local ad = trimmed(added)

	table.sort(ad)
	lu.assertEquals(#ad, 2, SHAMDON .. ": added lines: " .. table.concat(ad, " | "))
	lu.assertNotNil(ad[1]:match('^conversationTemplate = "shamdon_kree_convo_template",%s*%-%-%s*Smuggler tier 2 trainer, SWG tatooine_privateer_trainer_shamdon$'),
		SHAMDON .. ": the new template line, got: " .. ad[1])
	lu.assertEquals(ad[2], "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", SHAMDON .. ": the new mask line")
end

-- I-11: Karrde's template only gains the four screens, in one block
function TestSmugglerT2Pins:test_karrdes_template_only_gains_the_four_k3_screens()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_TEMPLATE)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, KARRDE_TEMPLATE .. ": removed lines")
	lu.assertEquals(hunks, 1, KARRDE_TEMPLATE .. ": one hunk (after not_member_work)")

	for _, id in ipairs({ "series_done", "jabba_wants_you", "jabba_respects", "see_beissa" }) do
		lu.assertNotNil(text:find('id = "' .. id .. '"', 1, true), KARRDE_TEMPLATE .. ": added screen " .. id)
	end

	lu.assertNil(text:find("addConversationTemplate", 1, true), KARRDE_TEMPLATE .. ": the registration line is not touched")
end

-- I-11: Karrde's handler only gains the K3 gate
function TestSmugglerT2Pins:test_karrdes_handler_only_gains_the_k3_gate()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_HANDLER)
	local code = nonBlank(added)

	lu.assertEquals(removed, {}, KARRDE_HANDLER .. ": removed lines")
	lu.assertEquals(hunks, 1, KARRDE_HANDLER .. ": one hunk (the gate)")
	lu.assertTrue(#code >= 2 and #code <= 4, KARRDE_HANDLER .. ": 2-4 added lines, got " .. #code .. ": " .. table.concat(code, " | "))
	lu.assertEquals(code[1], "-- Tier 2 series complete (Shamdon's missions and the four tier 2 skills)", KARRDE_HANDLER .. ": the gate comment")
	lu.assertNotNil(table.concat(code, " "):find('SmugglerSquadronScreenplay:hasCompletedTier2Series(pPlayer)', 1, true), KARRDE_HANDLER .. ": the gate calls hasCompletedTier2Series")
	lu.assertNotNil(table.concat(code, " "):find('convoTemplate:getScreen("series_done")', 1, true), KARRDE_HANDLER .. ": the gate returns series_done")
end

-- I-11: Dravis' three files and Karrde's NPC are byte-identical
function TestSmugglerT2Pins:test_dravis_and_karrde_npc_files_are_byte_identical_to_the_base()
	requireBase()

	for _, path in ipairs({
		ROOT .. "mobile/space/dravis.lua",
		ROOT .. "mobile/space/talon_karrde.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/dravis_convo.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua",
	}) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11: the other squadron files are byte-identical
function TestSmugglerT2Pins:test_the_other_squadron_files_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		local path = ROOT .. "screenplays/space/squadrons/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-11: only the eleven files of the spec differ under bin/ and src/ (no C++ change, no ship or point file)
function TestSmugglerT2Pins:test_only_the_eleven_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end

-- I-11: every other quest type, the other trainers and NPCs, and the ship and point data are untouched
function TestSmugglerT2Pins:test_the_other_quest_types_trainers_npcs_and_data_are_untouched()
	requireBase()

	local paths = {
		ROOT .. "screenplays/space/SpaceQuestLogic.lua",
		ROOT .. "screenplays/space/SpaceAttackWaves.lua",
		ROOT .. "screenplays/space/SpaceAssassinateScreenplay.lua",
		ROOT .. "screenplays/space/SpaceDestroyScreenplay.lua",
		ROOT .. "screenplays/space/SpacePatrolScreenplay.lua",
		ROOT .. "screenplays/space/SpaceDutyEscortScreenplay.lua",
		ROOT .. "screenplays/space/SpaceDutyRecoveryScreenplay.lua",
		ROOT .. "screenplays/space/SpaceDutyDestroyScreenplay.lua",
		ROOT .. "screenplays/space/conversations/imperial",
		ROOT .. "screenplays/space/conversations/rebel",
		ROOT .. "screenplays/space/conversations/neutral/corsec_squadron",
		ROOT .. "screenplays/space/conversations/neutral/rsf_squadron",
		ROOT .. "mobile/conversations/space/neutral/corsec_squadron",
		ROOT .. "mobile/conversations/space/neutral/rsf_squadron",
		ROOT .. "mobile/conversations/space/rebel",
		ROOT .. "mobile/conversations/space/imperial",
		ROOT .. "screenplays/cities/tatooine_mos_eisley.lua",
		ROOT .. "ship_mobile",
	}

	for _, path in ipairs(paths) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

---------------------------------------------------------------------------------------------
-- Not git-gated
---------------------------------------------------------------------------------------------

TestSmugglerT2NoCaller = {}

-- F-2 (SC-1, SC-2): after the fix nothing under bin/scripts calls SpaceHelpers:getPlayerSpaceFactionHash / String any more; the helpers stay defined
function TestSmugglerT2NoCaller:test_no_script_calls_the_squadron_faction_helpers_any_more_and_they_are_still_defined()
	local pipe = io.popen("grep -rnE 'getPlayerSpaceFaction(Hash|String)\\(' bin/scripts --include=*.lua")
	local out = pipe:read("a")

	pipe:close()

	local callers = {}

	for line in out:gmatch("[^\n]+") do
		if not line:find("^bin/scripts/utils/space_helpers.lua:") then
			callers[#callers + 1] = line
		end
	end

	lu.assertEquals(callers, {}, "callers of getPlayerSpaceFactionHash / getPlayerSpaceFactionString outside their definitions")

	local helpers = io.open("bin/scripts/utils/space_helpers.lua", "r"):read("a")

	lu.assertNotNil(helpers:find("function SpaceHelpers:getPlayerSpaceFactionHash", 1, true), "getPlayerSpaceFactionHash is still defined (F-2)")
	lu.assertNotNil(helpers:find("function SpaceHelpers:getPlayerSpaceFactionString", 1, true), "getPlayerSpaceFactionString is still defined (F-2)")
end

-- SC-1, SC-2: the two wave sites read the ship's faction
function TestSmugglerT2NoCaller:test_the_wave_sites_read_the_ship_faction()
	for _, path in ipairs({ "bin/scripts/screenplays/space/SpaceEscortScreenplay.lua", "bin/scripts/screenplays/space/SpaceRecoveryScreenplay.lua" }) do
		local text = io.open(path, "r"):read("a")

		lu.assertNil(text:find("getPlayerSpaceFactionHash", 1, true), path .. " still calls getPlayerSpaceFactionHash")
		lu.assertNotNil(text:find("local playerFactionHash = SpaceHelpers:getPlayerShipFactionHash(pPlayer)", 1, true), path .. ": the wave reads the ship faction")
	end
end
