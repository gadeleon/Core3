-- Inquisition tier 3 (Barlow): nothing else moves (I-6).
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (I-6, AC-9; Content contract 3; Out of scope; D-8).
--
-- The base is `git show 431519b2e6` (the commit the spec was written on); the "now" side is the working tree. Every test skips when git cannot show the
-- base, and skips once HEAD has moved past the base (later features edit the same files), as test_inquisition_tier3_pins.lua does.

local lu = require("luaunit")

local BASE = "431519b2e6"
local CONVERSATIONS = "MMOCoreORB/bin/scripts/mobile/conversations/space/space_conversations.lua"
local SCREENPLAYS = "MMOCoreORB/bin/scripts/screenplays/space/screenplays.lua"
local BARLOW = "MMOCoreORB/bin/scripts/mobile/space/barlow.lua"

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

-- a repo-root pathspec, valid from any working directory
local function spec(path) return "':/" .. path .. "'" end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

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

TestBarlowPins = {}

-- I-6: space_conversations.lua gains the template include line and nothing else
function TestBarlowPins:test_space_conversations_gains_only_the_barlow_include()
	requireBase()

	local removed, added = changedLines(CONVERSATIONS)

	lu.assertEquals(removed, {}, CONVERSATIONS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("conversations/space/imperial/inquisition_squadron/barlow_convo.lua")' }, CONVERSATIONS .. ": added lines (the include, no blank line)")
end

-- I-6: screenplays.lua gains the handler include and nothing else
function TestBarlowPins:test_screenplays_gains_only_the_barlow_handler_include()
	requireBase()

	local removed, added = changedLines(SCREENPLAYS)

	lu.assertEquals(removed, {}, SCREENPLAYS .. ": removed lines")
	lu.assertEquals(added, { 'includeFile("space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua")' }, SCREENPLAYS .. ": added lines (the include, no blank line)")
end

-- I-6: Barlow's NPC file changes its conversation template and options mask only
function TestBarlowPins:test_barlow_changes_only_the_template_and_options_mask_lines()
	requireBase()

	local removed, added = changedLines(BARLOW)

	lu.assertEquals(trimmed(removed), { "optionsBitmask = AIENABLED + JTLINTERESTING,", 'conversationTemplate = "",' }, BARLOW .. ": removed lines")
	lu.assertEquals(trimmed(added), { "optionsBitmask = AIENABLED + JTLINTERESTING + CONVERSABLE + INVULNERABLE,", 'conversationTemplate = "barlow_convo_template",' }, BARLOW .. ": added lines")
end

-- I-6: Vrke, Fa'Zoll, Barn, the squadron file, the helpers, the spawn and the other squadrons are byte-identical
function TestBarlowPins:test_vrke_fa_zoll_barn_the_squadron_file_the_helpers_and_the_spawn_are_byte_identical_to_the_base()
	requireBase()

	for _, path in ipairs({
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barn_sinkko_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/fa_zoll_convo.lua",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/vrke_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barnSinkkoConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/faZollConvoHandler.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/vrkeConvoHandler.lua",
		"MMOCoreORB/bin/scripts/mobile/space/barn_sinkko.lua",
		"MMOCoreORB/bin/scripts/mobile/space/fa_zoll.lua",
		"MMOCoreORB/bin/scripts/mobile/space/vrke.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/squadrons",
		"MMOCoreORB/bin/scripts/utils/space_helpers.lua",
		"MMOCoreORB/bin/scripts/screenplays/poi/yavin4_imperial_base.lua",
		"MMOCoreORB/bin/scripts/screenplays/themepark/imperial/emperors_retreat.lua",
		"MMOCoreORB/bin/scripts/ship_mobile",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/black_epsilon_squadron",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/neutral",
		"MMOCoreORB/bin/scripts/mobile/conversations/space/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/rebel",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/neutral",
		"MMOCoreORB/bin/scripts/screenplays/space/SpaceQuestLogic.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/spawning",
	}) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end

-- I-6: no C++, no ship template and no quest table (the squadron files hold them) differ
function TestBarlowPins:test_no_cpp_no_ship_template_and_no_quest_table_differ_from_the_base()
	requireBase()

	for _, path in ipairs({ "MMOCoreORB/src", "MMOCoreORB/bin/scripts/ship_mobile", "MMOCoreORB/bin/scripts/screenplays/space/squadrons" }) do
		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end

	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/src'")

	lu.assertEquals(lines(untracked), {}, "untracked files under MMOCoreORB/src")
end

-- I-6: exactly three files differ under bin/ and src/, plus the two new production files
function TestBarlowPins:test_only_the_five_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	requireBase()

	local _, modified = shell("git diff --diff-filter=M --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files, new = lines(modified), lines(untracked)

	table.sort(files)
	table.sort(new)
	lu.assertEquals(files, { CONVERSATIONS, BARLOW, SCREENPLAYS }, "modified files under bin/ and src/ against " .. BASE)
	lu.assertEquals(new, {
		"MMOCoreORB/bin/scripts/mobile/conversations/space/imperial/inquisition_squadron/barlow_convo.lua",
		"MMOCoreORB/bin/scripts/screenplays/space/conversations/imperial/inquisition_squadron/barlowConvoHandler.lua",
	}, "new files under bin/ and src/")

	local _, other = shell("git diff --diff-filter=ADRT --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")

	lu.assertEquals(lines(other), {}, "deleted, renamed or type-changed files")
end

return nil
