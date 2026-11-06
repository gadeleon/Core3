-- Storm tier 2, the Nym technicians: nothing else moves (I-8).
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (I-8, AC-10; Content contract 1, 4; Shared code changes).
--
-- The base is `git show 7593bc88ad` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "7593bc88ad"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local SQUADRON = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"

local NEW_FILES = {
	ROOT .. "mobile/conversations/space/imperial/storm_squadron/nym_technician_1_convo.lua",
	ROOT .. "mobile/conversations/space/imperial/storm_squadron/nym_technician_2_convo.lua",
	ROOT .. "mobile/conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua",
	ROOT .. "screenplays/space/conversations/imperial/storm_squadron/nymTechnician1ConvoHandler.lua",
	ROOT .. "screenplays/space/conversations/imperial/storm_squadron/nymTechnician2ConvoHandler.lua",
	ROOT .. "screenplays/space/conversations/imperial/storm_squadron/nymTechnician3ConvoHandler.lua",
}

local CHANGED_FILES = {
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/nym_fuel_tech.lua",
	ROOT .. "mobile/space/nym_fuel_tech_2.lua",
	ROOT .. "mobile/space/nym_fuel_tech_3.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua",
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

-- Removed and added lines of the working-tree file against the base ({ text... }, { text... }), and the number of hunks
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

local function without(list, unwanted)
	local out = {}

	for _, l in ipairs(list) do
		if trim(l) ~= unwanted then
			out[#out + 1] = l
		end
	end

	return out
end

local function identical(path)
	local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

	lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
end

TestStormNymPins = {}

-- I-8: the squadron file differs only by additions: the tip key, the reset line and the three functions
function TestStormNymPins:test_the_squadron_file_differs_from_the_base_only_by_the_claw_additions()
	requireBase()

	local removed, added, hunks = changedLines(SQUADRON)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, SQUADRON .. ": removed lines")
	lu.assertTrue(hunks <= 3, SQUADRON .. ": " .. hunks .. " hunks (the key, the reset line, the functions)")
	contains(text, 'TIER2_MORV_TIP_KEY = "StormSquadronScreenplay:spokeToMorv",', SQUADRON .. ": the tip key")
	contains(text, "removeQuestStatus(playerID .. self.TIER2_MORV_TIP_KEY)", SQUADRON .. ": the reset line")
	contains(text, "function StormSquadronScreenplay:getClawStage(pPlayer)", SQUADRON .. ": getClawStage")
	contains(text, "function StormSquadronScreenplay:canStartClaw(pPlayer)", SQUADRON .. ": canStartClaw")
	contains(text, "function StormSquadronScreenplay:startClaw(pPlayer, pNpc)", SQUADRON .. ": startClaw")
end

-- I-8: the three NPC files differ only by optionsBitmask and conversationTemplate
function TestStormNymPins:test_the_three_npc_files_differ_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	for n, name in ipairs({ "nym_fuel_tech", "nym_fuel_tech_2", "nym_fuel_tech_3" }) do
		local removed, added = changedLines(ROOT .. "mobile/space/" .. name .. ".lua")

		lu.assertEquals(#removed, 2, name .. ": removed lines: " .. table.concat(removed, " | "))
		lu.assertEquals(#added, 2, name .. ": added lines: " .. table.concat(added, " | "))

		local gotRemoved, gotAdded = { trim(removed[1] or ""), trim(removed[2] or "") }, { trim(added[1] or ""), trim(added[2] or "") }

		table.sort(gotRemoved)
		table.sort(gotAdded)
		lu.assertEquals(gotRemoved, { 'conversationTemplate = "",', "optionsBitmask = AIENABLED," }, name .. ": removed")
		lu.assertEquals(gotAdded, { 'conversationTemplate = "nym_technician_' .. n .. '_convo_template",', "optionsBitmask = AIENABLED + CONVERSABLE + INVULNERABLE," }, name .. ": added")
	end
end

-- I-8: space_conversations.lua gains the three template includes and nothing else (its last line has no trailing newline, so git may show Oberhaur's include
-- as removed and added again)
function TestStormNymPins:test_space_conversations_gains_only_the_three_technician_includes()
	requireBase()

	local oberhaur = 'includeFile("conversations/space/imperial/storm_squadron/oberhaur_convo.lua")'
	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(without(removed, oberhaur), {}, CONVERSATIONS .. ": removed lines")

	local code = {}

	for _, l in ipairs(without(added, oberhaur)) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(code, {
		'includeFile("conversations/space/imperial/storm_squadron/nym_technician_1_convo.lua")',
		'includeFile("conversations/space/imperial/storm_squadron/nym_technician_2_convo.lua")',
		'includeFile("conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua")',
	}, CONVERSATIONS .. ": added lines")
end

-- I-8: screenplays.lua gains the three handler includes and nothing else (no blank line)
function TestStormNymPins:test_screenplays_gains_only_the_three_handler_includes()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, {
		'includeFile("space/conversations/imperial/storm_squadron/nymTechnician1ConvoHandler.lua")',
		'includeFile("space/conversations/imperial/storm_squadron/nymTechnician2ConvoHandler.lua")',
		'includeFile("space/conversations/imperial/storm_squadron/nymTechnician3ConvoHandler.lua")',
	}, SCREENPLAYS .. ": added lines")
end

-- I-8: Oberhaur (handler, template, NPC), the helpers, the stronghold and every other squadron are byte-identical
function TestStormNymPins:test_oberhaur_the_helpers_the_stronghold_and_the_other_squadrons_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	for _, path in ipairs({
		SH,
		ROOT .. "screenplays/space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua",
		ROOT .. "mobile/conversations/space/imperial/storm_squadron/oberhaur_convo.lua",
		ROOT .. "mobile/conversations/space/imperial/storm_squadron/akal_colzet_convo.lua",
		ROOT .. "mobile/space/oberhaur.lua",
		ROOT .. "mobile/space/akal_colzet.lua",
		ROOT .. "mobile/space/alozen.lua",
		ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "object/mobile/serverobjects.lua",
		ROOT .. "mobile/space/serverobjects.lua",
	}) do
		identical(path)
	end

	-- every quest-type screenplay, including SpaceQuestLogic
	local rc, out = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(trim(out), "", "quest-type screenplays that differ from " .. BASE)
end

-- I-8: only the twelve files of the spec differ under bin/ and src/ (no C++ change)
function TestStormNymPins:test_only_the_twelve_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)
	local expected = {}

	for _, f in ipairs(NEW_FILES) do
		expected[#expected + 1] = f
	end

	for _, f in ipairs(CHANGED_FILES) do
		expected[#expected + 1] = f
	end

	table.sort(files)
	table.sort(expected)
	lu.assertEquals(files, expected, "files under bin/ and src/ that differ from " .. BASE)
end
