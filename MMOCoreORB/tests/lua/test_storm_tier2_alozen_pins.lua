-- Storm tier 2 part 3 (Field Commander Alozen): nothing else moves (I-13).
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (I-13, AC-11; Content contract 2, 4; Shared code changes).
--
-- The base is `git show 82dc0d5e6a` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and all of them skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

-- plain substring check with a message (luaunit's assertStrContains takes a pattern flag as its third argument, not a message)
local function contains(s, sub, msg)
	lu.assertTrue(s:find(sub, 1, true) ~= nil, (msg or "text") .. ": expected '" .. sub .. "' in '" .. s .. "'")
end

local BASE = "82dc0d5e6a"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local SQUADRON = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"

local NEW_FILES = {
	ROOT .. "mobile/conversations/space/imperial/storm_squadron/alozen_convo.lua",
	ROOT .. "screenplays/space/conversations/imperial/storm_squadron/alozenConvoHandler.lua",
}

local CHANGED_FILES = {
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/alozen.lua",
	ROOT .. "screenplays/poi/yavin4_imperial_base.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua",
	ROOT .. "ship_mobile/ships/rebel_agent_tier3.lua",
	SH,
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

TestAlozenPins = {}

-- I-13: the squadron file differs only by additions: the six constants, the reset and the six quest tables
function TestAlozenPins:test_the_squadron_file_differs_from_the_base_only_by_additions()
	requireBase()

	local removed, added = changedLines(SQUADRON)
	local text = table.concat(added, "\n")

	lu.assertEquals(removed, {}, SQUADRON .. ": removed lines")
	contains(text, 'TIER2_QUEST_STRING_4 = {type = "inspect", name = "imperial_ss_4"},', SQUADRON .. ": constant 4")
	contains(text, "function StormSquadronScreenplay:resetAlozenQuests(pPlayer)", SQUADRON .. ": the reset")

	for _, global in ipairs({ "inspect_imperial_ss_4", "escort_imperial_ss_5", "recovery_imperial_ss_6", "destroy_duty_lok_imperial_ss_2a", "recovery_duty_lok_imperial_ss_2b", "escort_duty_lok_imperial_ss_2c" }) do
		contains(text, 'registerScreenPlay("' .. global .. '", true)', SQUADRON .. ": " .. global)
	end
end

-- I-13: space_helpers.lua gains the one reset line and nothing else
function TestAlozenPins:test_space_helpers_gains_only_the_alozen_reset_line()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")

	local code = {}

	for _, l in ipairs(added) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(code, { "StormSquadronScreenplay:resetAlozenQuests(pPlayer)" }, SH .. ": added lines")
end

-- I-13: Alozen's NPC file differs only by optionsBitmask and conversationTemplate
function TestAlozenPins:test_alozens_npc_file_differs_only_by_the_options_bitmask_and_the_conversation_template()
	requireBase()

	local removed, added = changedLines(ROOT .. "mobile/space/alozen.lua")

	lu.assertEquals(#removed, 2, "alozen.lua removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, "alozen.lua added lines: " .. table.concat(added, " | "))

	local gotRemoved, gotAdded = { trim(removed[1] or ""), trim(removed[2] or "") }, { trim(added[1] or ""), trim(added[2] or "") }

	table.sort(gotRemoved)
	table.sort(gotAdded)
	lu.assertEquals(gotRemoved, { 'conversationTemplate = "",', "optionsBitmask = AIENABLED + JTLINTERESTING," }, "alozen.lua: removed")
	lu.assertEquals(gotAdded, { 'conversationTemplate = "alozen_convo_template",', "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE," }, "alozen.lua: added")
end

-- I-13: the spawn file changes Alozen's mood on its own line and nothing else
function TestAlozenPins:test_the_spawn_file_changes_only_alozens_mood()
	requireBase()

	local removed, added = changedLines(ROOT .. "screenplays/poi/yavin4_imperial_base.lua")

	lu.assertEquals(#removed, 1, "removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 1, "added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(removed[1] or ""), '{"alozen", 300, 0.003, 0.125, -5.558, 0, 8735518, ""},', "the old row")
	lu.assertEquals(trim(added[1] or ""), '{"alozen", 300, 0.003, 0.125, -5.558, 0, 8735518, "npc_imperial"},', "the new row")
end

-- I-13: the Rebel agent template gains the cargo string line and nothing else
function TestAlozenPins:test_the_rebel_agent_template_gains_only_the_cargo_string()
	requireBase()

	local removed, added = changedLines(ROOT .. "ship_mobile/ships/rebel_agent_tier3.lua")

	lu.assertEquals(removed, {}, "removed lines")
	lu.assertEquals(#added, 1, "added lines: " .. table.concat(added, " | "))
	contains(added[1] or "", 'cargoString = "yavin_activity_log",', "the added line")
end

-- I-13: space_conversations.lua gains Alozen's template include and nothing else (its last line has no trailing newline, so git may show technician 3's
-- include as removed and added again)
function TestAlozenPins:test_space_conversations_gains_only_alozens_include()
	requireBase()

	local technician = 'includeFile("conversations/space/imperial/storm_squadron/nym_technician_3_convo.lua")'
	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(without(removed, technician), {}, CONVERSATIONS .. ": removed lines")

	local code = {}

	for _, l in ipairs(without(added, technician)) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(code, { 'includeFile("conversations/space/imperial/storm_squadron/alozen_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-13: screenplays.lua gains Alozen's handler include and nothing else (no blank line)
function TestAlozenPins:test_screenplays_gains_only_alozens_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/storm_squadron/alozenConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-13: Oberhaur, Colzet, the technicians, Denner's file, the broker, the other squadrons and every quest-type screenplay are byte-identical
function TestAlozenPins:test_the_other_trainers_the_other_squadrons_and_the_quest_types_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	local storm = ROOT .. "screenplays/space/conversations/imperial/storm_squadron/"
	local convos = ROOT .. "mobile/conversations/space/imperial/storm_squadron/"

	for _, path in ipairs({
		storm .. "oberhaurConvoHandler.lua", storm .. "akalColzetConvoHandler.lua", storm .. "nymTechnician1ConvoHandler.lua", storm .. "nymTechnician2ConvoHandler.lua",
		storm .. "nymTechnician3ConvoHandler.lua", convos .. "oberhaur_convo.lua", convos .. "akal_colzet_convo.lua", convos .. "nym_technician_1_convo.lua",
		convos .. "nym_technician_2_convo.lua", convos .. "nym_technician_3_convo.lua",
		ROOT .. "screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		ROOT .. "mobile/space/oberhaur.lua", ROOT .. "mobile/space/akal_colzet.lua", ROOT .. "mobile/space/denner.lua", ROOT .. "mobile/space/barlow.lua",
		ROOT .. "mobile/space/nym_fuel_tech.lua", ROOT .. "mobile/space/nym_fuel_tech_2.lua", ROOT .. "mobile/space/nym_fuel_tech_3.lua",
		ROOT .. "mobile/space/nial_declann.lua", ROOT .. "mobile/space/willham_burke.lua",
		ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
		ROOT .. "object/mobile/serverobjects.lua",
		ROOT .. "mobile/space/serverobjects.lua",
	}) do
		identical(path)
	end

	local rc, out = shell("git diff --name-only " .. BASE .. " -- " .. spec(ROOT .. "screenplays/space") .. " | grep -E '/Space[A-Za-z]+\\.lua$'")

	lu.assertEquals(trim(out), "", "quest-type screenplays that differ from " .. BASE)
end

-- I-13: only the nine files of the spec differ under bin/ and src/ (no C++ change)
function TestAlozenPins:test_only_the_nine_files_of_the_spec_differ_from_the_base_under_bin_and_src()
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
