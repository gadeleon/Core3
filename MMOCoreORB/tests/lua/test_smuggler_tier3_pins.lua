-- Smuggler tier 3 (Beissa): nothing else moves (I-12) and the shared edits (surrenderPilot, the two ship cargo strings, Karrde's K2 hub).
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (I-12, AC-12; Shared code changes; Content contract 4 and 5).
--
-- The base is `git show ccd4e22433` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the base,
-- and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do. Edited files come from
-- `git diff --diff-filter=M`, new ones from `--diff-filter=A` plus the untracked files.

local lu = require("luaunit")

local BASE = "ccd4e22433"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local SSP = ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local BEISSA = ROOT .. "mobile/space/beissa.lua"
local SOLDIER = ROOT .. "ship_mobile/ships/dath_witchblood_clan_soldier_tier3.lua"
local PUNISHER = ROOT .. "ship_mobile/ships/dath_witchblood_clan_punisher_tier3.lua"
local KARRDE_TEMPLATE = ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua"
local KARRDE_HANDLER = ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua"

local EXPECTED_MODIFIED = {
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/talon_karrde_convo.lua",
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/beissa.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/talonKarrdeConvoHandler.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/SmugglerSquadronScreenplay.lua",
	ROOT .. "ship_mobile/ships/dath_witchblood_clan_punisher_tier3.lua",
	ROOT .. "ship_mobile/ships/dath_witchblood_clan_soldier_tier3.lua",
	ROOT .. "utils/space_helpers.lua",
}

local EXPECTED_ADDED = {
	ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/beissa_convo.lua",
	ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua",
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

TestSmugglerT3Pins = {}

-- I-12: exactly the nine edited files under bin/ and src/ (no C++ change) and the two new production files
function TestSmugglerT3Pins:test_only_the_spec_files_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, modified = shell("git diff --diff-filter=M --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, added = shell("git diff --diff-filter=A --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, deleted = shell("git diff --diff-filter=D --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local mod, new = lines(modified), lines(added .. "\n" .. untracked)

	table.sort(mod)
	table.sort(new)
	lu.assertEquals(mod, EXPECTED_MODIFIED, "files under bin/ and src/ edited since " .. BASE)
	lu.assertEquals(new, EXPECTED_ADDED, "files under bin/ and src/ added since " .. BASE)
	lu.assertEquals(lines(deleted), {}, "files under bin/ and src/ deleted since " .. BASE)
end

-- Shared code: space_helpers.lua differs only by the Beissa reset lines, directly after the Shamdon reset
function TestSmugglerT3Pins:test_space_helpers_differs_from_the_base_only_in_the_beissa_reset_lines()
	requireBase()

	local removed, added, hunks = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")
	lu.assertEquals(trimmed(added), { "-- Tier 3", "SmugglerSquadronScreenplay:resetBeissaQuests(pPlayer)" }, SH .. ": added lines")
	lu.assertEquals(hunks, 1, SH .. ": one hunk (the Smuggler branch)")

	local all = fileLines("bin/scripts/utils/space_helpers.lua")
	local at

	for i, l in ipairs(all) do
		if l == "SmugglerSquadronScreenplay:resetShamdonQuests(pPlayer)" then
			at = i
		end
	end

	lu.assertNotNil(at, SH .. ": the resetShamdonQuests call")
	lu.assertEquals({ all[at + 1], all[at + 2] }, { "-- Tier 3", "SmugglerSquadronScreenplay:resetBeissaQuests(pPlayer)" }, SH .. ": the Beissa reset directly after the Shamdon reset")
end

-- I-12: SmugglerSquadronScreenplay.lua differs only by additions, apart from the header comment
function TestSmugglerT3Pins:test_the_smuggler_squadron_file_only_gains_lines_except_in_its_header_comment()
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

-- I-12: space_conversations.lua gains the template include line and nothing else
function TestSmugglerT3Pins:test_space_conversations_gains_only_the_beissa_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/neutral/smuggler_squadron/beissa_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-12: screenplays.lua gains the handler include and nothing else
function TestSmugglerT3Pins:test_screenplays_gains_only_the_beissa_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/neutral/smuggler_squadron/beissaConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-12: beissa.lua differs only by its two fields
function TestSmugglerT3Pins:test_beissa_differs_from_the_base_only_in_the_conversation_template_and_the_options_mask()
	requireBase()

	local removed, added = changedLines(BEISSA)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED + JTLINTERESTING,", 'conversationTemplate = "",' }, BEISSA .. ": removed lines")

	local ad = trimmed(added)

	table.sort(ad)
	lu.assertEquals(#ad, 2, BEISSA .. ": added lines: " .. table.concat(ad, " | "))
	lu.assertNotNil(ad[1]:match('^conversationTemplate = "beissa_convo_template",%s*%-%-%s*Smuggler tier 3 trainer, SWG tatooine_privateer_tier3$'),
		BEISSA .. ": the new template line, got: " .. ad[1])
	lu.assertEquals(ad[2], "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", BEISSA .. ": the new mask line")
end

-- I-12: each witchblood ship file gains exactly the cargoString line, directly after questLoot
function TestSmugglerT3Pins:test_the_witchblood_ship_files_gain_only_their_cargo_string_line()
	requireBase()

	local cases = {
		{ SOLDIER, 'cargoString = "rally_point_info",', 'questLoot = "witchblood_rallyinfo",' },
		{ PUNISHER, 'cargoString = "hidden_base_info",', 'questLoot = "witchblood_baseinfo",' },
	}

	for _, c in ipairs(cases) do
		local removed, added, hunks = changedLines(c[1])

		lu.assertEquals(removed, {}, c[1] .. ": removed lines")
		lu.assertEquals(#added, 1, c[1] .. ": added lines")
		lu.assertEquals(hunks, 1, c[1] .. ": one hunk")
		lu.assertNotNil(trim(added[1]):find(c[2], 1, true) == 1 and true or nil, c[1] .. ": the added line starts with " .. c[2] .. ", got: " .. tostring(added[1]))

		local all = fileLines(c[1]:gsub("^MMOCoreORB/", ""))
		local at

		for i, l in ipairs(all) do
			if l == c[3] then
				at = i
			end
		end

		lu.assertNotNil(at, c[1] .. ": the questLoot line")
		lu.assertEquals(all[at + 1], trim(added[1]), c[1] .. ": the cargoString line directly after questLoot")
	end
end

-- I-12: Karrde's template only gains the six K2 screens, in one block
function TestSmugglerT3Pins:test_karrdes_template_only_gains_the_six_k2_screens()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_TEMPLATE)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, KARRDE_TEMPLATE .. ": removed lines")
	lu.assertEquals(hunks, 1, KARRDE_TEMPLATE .. ": one hunk (between not_member_work and series_done)")

	for _, id in ipairs({ "tier3_done", "dathomir_contact", "nirame_who", "nym_hyperspace", "branching_out", "see_nirame" }) do
		lu.assertNotNil(text:find('id = "' .. id .. '"', 1, true), KARRDE_TEMPLATE .. ": added screen " .. id)
	end

	local count = 0

	for _ in text:gmatch("ConvoScreen:new") do
		count = count + 1
	end

	lu.assertEquals(count, 6, KARRDE_TEMPLATE .. ": added screens")
	lu.assertNil(text:find("addConversationTemplate", 1, true), KARRDE_TEMPLATE .. ": the registration line is not touched")
end

-- I-12: Karrde's handler only gains the K2 gate
function TestSmugglerT3Pins:test_karrdes_handler_only_gains_the_k2_gate()
	requireBase()

	local removed, added, hunks = changedLines(KARRDE_HANDLER)
	local joined = table.concat(nonBlank(added), " ")

	lu.assertEquals(removed, {}, KARRDE_HANDLER .. ": removed lines")
	lu.assertEquals(hunks, 1, KARRDE_HANDLER .. ": one hunk (the gate)")

	-- the spec shows the gate as a comment and one if line; a multi-line if is the same code
	local flat = joined:gsub("%s+", " ")
	local want = '-- Tier 3 complete (the four tier 3 skills; SWG doneWithTier3) if (SpaceHelpers:hasCompletedPilotTier(pPlayer, "neutral", 3)) then return convoTemplate:getScreen("tier3_done") end'

	lu.assertEquals(flat, want, KARRDE_HANDLER .. ": the added lines (comment and gate), whitespace aside")
end

-- I-12: Dravis' and Shamdon's files and Karrde's, Beissa's NPC spawn data are byte-identical
function TestSmugglerT3Pins:test_dravis_shamdon_and_the_spawn_files_are_byte_identical_to_the_base()
	requireBase()

	for _, path in ipairs({
		ROOT .. "mobile/space/dravis.lua",
		ROOT .. "mobile/space/shamdon_kree.lua",
		ROOT .. "mobile/space/talon_karrde.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/dravis_convo.lua",
		ROOT .. "mobile/conversations/space/neutral/smuggler_squadron/shamdon_kree_convo.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/dravisConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/neutral/smuggler_squadron/shamdonKreeConvoHandler.lua",
		ROOT .. "screenplays/poi/tatooine_jabbas_palace_mobs.lua",
		ROOT .. "mobile/tatooine/space_rebel_tier3_beissa.lua",
	}) do
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-12: the other squadron files and every quest type are byte-identical
function TestSmugglerT3Pins:test_the_other_squadron_files_and_the_quest_types_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay" }) do
		local path = ROOT .. "screenplays/space/squadrons/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end

	for _, name in ipairs({ "SpaceQuestLogic", "SpaceAttackWaves", "SpaceAssassinateScreenplay", "SpaceBattleScreenplay", "SpaceDeliveryNoPickupScreenplay", "SpaceDeliveryScreenplay",
		"SpaceEscortScreenplay", "SpaceInspectScreenplay", "SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceRescueScreenplay", "SpaceSurpriseAttackScreenplay",
		"SpaceSurvivalScreenplay" }) do
		local path = ROOT .. "screenplays/space/" .. name .. ".lua"
		local same, out = identical(path)

		lu.assertTrue(same, path .. " differs from " .. BASE .. ": " .. out)
	end
end
