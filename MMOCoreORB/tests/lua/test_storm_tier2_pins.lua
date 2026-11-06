-- Storm tier 2: nothing else moves (I-14) and the shared lines.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (I-14, AC-13; Shared code changes; Content contract 5).
--
-- The base is `git show 85cfb1dc28` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and the whole-tree pins skip once HEAD has moved past the base (later features edit the same files), as the other file pins do.

local lu = require("luaunit")

local BASE = "85cfb1dc28"
local ROOT = "MMOCoreORB/bin/scripts/"
local SH = ROOT .. "utils/space_helpers.lua"
local CONVERSATIONS = ROOT .. "mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = ROOT .. "screenplays/space/screenplays.lua"
local SQUADRON = ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua"
local INSPECT = ROOT .. "screenplays/space/SpaceInspectScreenplay.lua"

local EXPECTED_FILES = {
	ROOT .. "mobile/conversations/space/imperial/storm_squadron/oberhaur_convo.lua",
	ROOT .. "mobile/conversations/space/space_conversations.lua",
	ROOT .. "mobile/space/oberhaur.lua",
	ROOT .. "object/tangible/space/mission_objects/transfer_auth.lua",
	ROOT .. "screenplays/space/SpaceInspectScreenplay.lua",
	ROOT .. "screenplays/space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua",
	ROOT .. "screenplays/space/screenplays.lua",
	ROOT .. "screenplays/space/squadrons/StormSquadronScreenplay.lua",
	ROOT .. "ship_mobile/ships/nym_lieutenant_tier2.lua",
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

TestStormT2Pins = {}

-- I-14, Shared code changes: space_helpers.lua differs only in the Storm surrender branch
function TestStormT2Pins:test_space_helpers_differs_from_the_base_only_in_the_oberhaur_reset_lines()
	requireBase()

	local removed, added = changedLines(SH)

	lu.assertEquals(removed, {}, SH .. ": removed lines")

	local got = {}

	for _, l in ipairs(added) do
		got[#got + 1] = trim(l)
	end

	-- git may align the new blank line with either of the blank lines around the call, so compare the set
	table.sort(got)
	lu.assertEquals(got, { "", "-- Tier 2", "StormSquadronScreenplay:resetOberhaurQuests(pPlayer)" }, SH .. ": added lines (a blank line, '-- Tier 2' and the call)")
end

-- I-14: space_conversations.lua gains the template include line and nothing else (its last line has no trailing newline, so git may show Colzet's include
-- as removed and added again)
function TestStormT2Pins:test_space_conversations_gains_only_the_oberhaur_include()
	requireBase()

	local colzet = 'includeFile("conversations/space/imperial/storm_squadron/akal_colzet_convo.lua")'
	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(without(removed, colzet), {}, CONVERSATIONS .. ": removed lines")

	local code = {}

	for _, l in ipairs(without(added, colzet)) do
		if trim(l) ~= "" then
			code[#code + 1] = trim(l)
		end
	end

	lu.assertEquals(code, { 'includeFile("conversations/space/imperial/storm_squadron/oberhaur_convo.lua")' }, CONVERSATIONS .. ": added lines")
end

-- I-14: screenplays.lua gains the handler include and nothing else (no blank line)
function TestStormT2Pins:test_screenplays_gains_only_the_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/storm_squadron/oberhaurConvoHandler.lua")' }, SCREENPLAYS .. ": added lines")
end

-- I-14: the squadron file differs only by additions
function TestStormT2Pins:test_the_squadron_file_differs_from_the_base_only_by_additions()
	requireBase()

	local removed, added = changedLines(SQUADRON)

	lu.assertEquals(removed, {}, SQUADRON .. ": removed lines")
	lu.assertTrue(#added > 100, SQUADRON .. ": the tier 2 section was added (" .. #added .. " lines)")
end

-- I-14, Shared code changes: SIS changes only inside hasQuestData and isQuestTarget, and the error text that named validSpawns
function TestStormT2Pins:test_the_inspect_screenplay_differs_only_in_the_valid_spawns_checks()
	requireBase()

	local rc, base = shell("git show " .. BASE .. ":" .. INSPECT)

	lu.assertEquals(rc, 0, "git show failed: " .. base)

	local allowed = { ["Logger:log(self.className .. \" -- Quest has no inspect data (shipList, validSpawns, cargo), failing the quest.\", LT_ERROR)"] = true }
	local inside

	for line in (base .. "\n"):gmatch("(.-)\n") do
		if line:match("^function SpaceInspectScreenplay:hasQuestData%(") or line:match("^function SpaceInspectScreenplay:isQuestTarget%(") then
			inside = true
		end

		if inside then
			allowed[trim(line)] = true

			if line == "end" then
				inside = false
			end
		end
	end

	local removed = changedLines(INSPECT)

	lu.assertTrue(#removed >= 2, INSPECT .. ": the hasQuestData line and the error text changed (removed lines: " .. table.concat(removed, " | ") .. ")")

	for _, l in ipairs(removed) do
		lu.assertTrue(allowed[trim(l)] == true, INSPECT .. ": a line outside hasQuestData, isQuestTarget and the error text was removed or changed: " .. trim(l))
	end
end

-- I-14: the cargo line of the Lieutenant, directly after questLoot
function TestStormT2Pins:test_nym_lieutenant_tier2_gains_only_the_cargo_string_line()
	requireBase()

	local removed, added = changedLines(ROOT .. "ship_mobile/ships/nym_lieutenant_tier2.lua")

	lu.assertEquals(removed, {}, "removed lines")
	lu.assertEquals(#added, 1, "added lines: " .. table.concat(added, " | "))
	lu.assertEquals((added[1] or ""):match('^%s*cargoString = "hostage_orders",'), (added[1] or ""):match('^%s*') .. 'cargoString = "hostage_orders",', "the added line")
end

-- I-14: the form's object template gains its menu component
function TestStormT2Pins:test_transfer_auth_gains_only_the_menu_component_line()
	requireBase()

	local removed, added = changedLines(ROOT .. "object/tangible/space/mission_objects/transfer_auth.lua")

	-- the empty table may lose its blank line or keep it: blank lines do not count
	lu.assertEquals(without(removed, ""), {}, "removed lines")

	local code = without(added, "")

	lu.assertEquals(#code, 1, "added lines: " .. table.concat(added, " | "))
	lu.assertEquals(trim(code[1] or ""), 'objectMenuComponent = "StormTransferFormMenuComponent",', "the added line")
end

-- I-14: oberhaur.lua differs only by its two fields (the template name and the options bitmask)
function TestStormT2Pins:test_oberhaur_differs_only_by_the_template_and_the_options_bitmask()
	requireBase()

	local removed, added = changedLines(ROOT .. "mobile/space/oberhaur.lua")

	lu.assertEquals(#removed, 2, "removed lines: " .. table.concat(removed, " | "))
	lu.assertEquals(#added, 2, "added lines: " .. table.concat(added, " | "))

	table.sort(added)
	lu.assertEquals({ trim(added[1]), trim(added[2]) }, { 'conversationTemplate = "oberhaur_convo_template",', "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE," }, "added lines")
end

-- I-14: Colzet, every other squadron file, the master trainers, the broker and Burke are byte-identical
function TestStormT2Pins:test_the_other_squadron_files_and_trainers_are_byte_identical_to_the_base()
	requireBase()

	for _, name in ipairs({ "CorsecSquadronScreenplay", "RsfSquadronScreenplay", "HavocSquadronScreenplay", "BlackEpsilonSquadronScreenplay", "SmugglerSquadronScreenplay",
		"InquisitionSquadronScreenplay", "MasterTrainerScreenplay", "VortexSquadronScreenplay", "CrimsonPhoenixSquadronScreenplay" }) do
		identical(ROOT .. "screenplays/space/squadrons/" .. name .. ".lua")
	end

	for _, path in ipairs({
		ROOT .. "screenplays/space/conversations/imperial/storm_squadron/akalColzetConvoHandler.lua",
		ROOT .. "mobile/conversations/space/imperial/storm_squadron/akal_colzet_convo.lua",
		ROOT .. "mobile/space/akal_colzet.lua",
		ROOT .. "mobile/space/alozen.lua",
		ROOT .. "screenplays/space/SpaceQuestLogic.lua",
		ROOT .. "screenplays/space/SpacePatrolScreenplay.lua",
		ROOT .. "screenplays/space/SpaceRecoveryScreenplay.lua",
		ROOT .. "screenplays/space/conversations/imperial/imperialBrokerConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
		ROOT .. "screenplays/space/conversations/rebel",
		ROOT .. "screenplays/space/conversations/neutral",
		ROOT .. "mobile/conversations/space/neutral",
		ROOT .. "mobile/conversations/space/rebel",
		ROOT .. "mobile/conversations/space/imperial/imperial_broker_convo.lua",
		ROOT .. "mobile/conversations/space/imperial/nial_declann_convo.lua",
		ROOT .. "mobile/space/nial_declann.lua",
		ROOT .. "screenplays/cities/tatooine_bestine.lua",
		ROOT .. "screenplays/cities/lok_nym_stronghold.lua",
	}) do
		identical(path)
	end
end

-- I-14: only the ten files of the spec differ under bin/ and src/ (no C++ change)
function TestStormT2Pins:test_only_the_ten_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, changed = shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = lines(changed .. "\n" .. untracked)

	table.sort(files)
	lu.assertEquals(files, EXPECTED_FILES, "files under bin/ and src/ that differ from " .. BASE)
end
