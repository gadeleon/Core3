-- File pins of space-mission4-reward-fixes: the exact lines the feature may change, against commit 4e917caf0f, and nothing else.
-- Spec: .claude/work/space-mission4-reward-fixes/01-spec.md (C-1 .. C-4, I-5, AC-6, AC-7, R-5).
--
-- The base side is `git show 4e917caf0f:<file>`. Every test skips when git cannot show the base commit.
-- The "now" side is the working tree. FEATURE_COMMIT: once the feature is committed and a later feature edits these files again, set it to the
-- feature commit's hash; the "now" side is then read with `git show` (as test_space_trainer_rewards_pins.lua does for the rewards commit).

local lu = require("luaunit")
local D = require("space_trainer_rewards_data")

local BASE = "4e917caf0f"
local FEATURE_COMMIT = "9034fa3254"

local HD = D.HANDLER_DIR
local KAYDINE = HD .. "neutral/rsf_squadron/kaydineConvoHandler.lua"
local RIKKH = HD .. "neutral/corsec_squadron/rikkhConvoHandler.lua"
local TUROLDINE = HD .. "neutral/corsec_squadron/turoldineConvoHandler.lua"
local VIOPA = HD .. "rebel/havoc_squadron/viopaConvoHandler.lua"

local function git(rev, path)
	local rc, text = D.shell("git show " .. rev .. ":MMOCoreORB/" .. path)

	if rc ~= 0 then
		lu.skip("git show " .. rev .. " is unavailable: " .. tostring(text))
	end

	return text
end

local function base(path) return git(BASE, path) end

local function now(path)
	if FEATURE_COMMIT ~= nil then
		return git(FEATURE_COMMIT, path)
	end

	local text = D.readFile(path)

	lu.assertNotNil(text, path .. ": missing")

	return text
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- Line diff by longest common subsequence: returns removed = { {n = base line number, text} }, added = { {n = new line number, text} }
local function diff(before, after)
	local n, m = #before, #after
	local lcs = {}

	for i = 0, n + 1 do
		lcs[i] = {}

		for j = 0, m + 1 do
			lcs[i][j] = 0
		end
	end

	for i = n, 1, -1 do
		for j = m, 1, -1 do
			if before[i] == after[j] then
				lcs[i][j] = lcs[i + 1][j + 1] + 1
			else
				lcs[i][j] = math.max(lcs[i + 1][j], lcs[i][j + 1])
			end
		end
	end

	local removed, added = {}, {}
	local i, j = 1, 1

	while i <= n and j <= m do
		if before[i] == after[j] then
			i, j = i + 1, j + 1
		elseif lcs[i + 1][j] >= lcs[i][j + 1] then
			removed[#removed + 1] = { n = i, text = before[i] }
			i = i + 1
		else
			added[#added + 1] = { n = j, text = after[j] }
			j = j + 1
		end
	end

	while i <= n do
		removed[#removed + 1] = { n = i, text = before[i] }
		i = i + 1
	end

	while j <= m do
		added[#added + 1] = { n = j, text = after[j] }
		j = j + 1
	end

	return removed, added
end

-- the line keeps its old condition and adds: getQuestStatus(<id> .. <M4 name> .. ":reward") == "1"
local function hasRewardTest(line, nameExpr)
	return line:find("getQuestStatus(", 1, true) ~= nil and line:find(nameExpr, 1, true) ~= nil and line:find(':reward"', 1, true) ~= nil
		and line:find('== "1"', 1, true) ~= nil and line:find("questFourComplete and ", 1, true) ~= nil
end

local function describe(list)
	local out = {}

	for _, e in ipairs(list) do
		out[#out + 1] = e.n .. ": " .. trim(e.text)
	end

	return table.concat(out, " | ")
end

local function diffOf(path)
	return diff(D.linesOf(base(path)), D.linesOf(now(path)))
end

---------------------------------------------------------------------------------------------
-- AC-6: the untouched handlers
---------------------------------------------------------------------------------------------

TestMission4FilePins = {}

local UNTOUCHED = {
	"neutral/corsec_squadron/rheaConvoHandler.lua", "neutral/corsec_squadron/ramnaConvoHandler.lua",
	"neutral/rsf_squadron/dingeConvoHandler.lua", "neutral/rsf_squadron/duliosConvoHandler.lua", "neutral/rsf_squadron/imlerConvoHandler.lua",
	"rebel/havoc_squadron/kreezoConvoHandler.lua", "rebel/havoc_squadron/aqzowConvoHandler.lua", "rebel/havoc_squadron/arkonConvoHandler.lua",
	"rebel/havoc_squadron/vrakConvoHandler.lua",
}

for _, rel in ipairs(UNTOUCHED) do
	-- AC-6
	TestMission4FilePins["test_" .. rel:match("([%w]+)ConvoHandler") .. "ConvoHandler_is_byte_identical_to_the_base"] = function()
		local path = HD .. rel

		lu.assertEquals(now(path) == base(path), true, path .. " differs from " .. BASE)
	end
end

-- AC-6: the pins above cover the nine handlers of the spec
function TestMission4FilePins:test_nine_untouched_handlers_are_pinned()
	lu.assertEquals(#UNTOUCHED, 9, "untouched handlers")
end

---------------------------------------------------------------------------------------------
-- AC-6, C-1 .. C-3: the four changed handlers differ only on their gate lines
---------------------------------------------------------------------------------------------

-- Kaydine (C-1): the `getPilotTier() > 3` gate line, and the `questFourComplete` local if the implementor computes it earlier.
-- AC-6
function TestMission4FilePins:test_kaydineConvoHandler_differs_from_the_base_only_on_the_tier_3_gate()
	local removed, added = diffOf(KAYDINE)
	local allowed = {
		["if (ghost:getPilotTier() > 3) then"] = true,
		["local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.type, RsfSquadronScreenplay.TIER2_QUEST_STRING_4.name)"] = true,
	}

	lu.assertTrue(#removed >= 1, KAYDINE .. ": the gate line is unchanged (nothing removed)")

	for _, r in ipairs(removed) do
		lu.assertTrue(allowed[trim(r.text)] == true, KAYDINE .. ": base line " .. r.n .. " must not change: " .. trim(r.text))
	end

	lu.assertTrue(#added <= 8, KAYDINE .. ": " .. #added .. " lines added: " .. describe(added))

	local mentionsReward = false

	for _, a in ipairs(added) do
		if a.text:find(":reward", 1, true) then
			mentionsReward = true
		end
	end

	lu.assertTrue(mentionsReward, KAYDINE .. ": the gate must test the mission 4 :reward key; added " .. describe(added))
end

-- Rikkh (C-2, C-3): the tier gate line, the tier-done line, and the `questFourComplete` local if moved
-- AC-6
function TestMission4FilePins:test_rikkhConvoHandler_differs_from_the_base_only_on_the_gate_and_the_tier_done_line()
	local removed, added = diffOf(RIKKH)
	local allowed = {
		["if (ghost:getPilotTier() > 3) then"] = true,
		["elseif (questFourComplete and completedTier2) then"] = true,
		["local questFourComplete = SpaceHelpers:isSpaceQuestComplete(pPlayer, CorsecSquadronScreenplay.TIER2_QUEST_STRING_4.type, CorsecSquadronScreenplay.TIER2_QUEST_STRING_4.name)"] = true,
	}
	local seen = {}

	for _, r in ipairs(removed) do
		lu.assertTrue(allowed[trim(r.text)] == true, RIKKH .. ": base line " .. r.n .. " must not change: " .. trim(r.text))
		seen[trim(r.text)] = true
	end

	lu.assertTrue(seen["if (ghost:getPilotTier() > 3) then"], RIKKH .. ": the tier gate (C-3) is not changed; removed " .. describe(removed))
	lu.assertTrue(seen["elseif (questFourComplete and completedTier2) then"], RIKKH .. ": the tier-done line (C-2) is not changed; removed " .. describe(removed))
	lu.assertTrue(#added <= 10, RIKKH .. ": " .. #added .. " lines added: " .. describe(added))
end

-- Turoldine (C-2): the tier-done line only
-- AC-6
function TestMission4FilePins:test_turoldineConvoHandler_differs_from_the_base_only_on_the_tier_done_line()
	local removed, added = diffOf(TUROLDINE)

	lu.assertEquals(#removed, 1, TUROLDINE .. ": removed lines: " .. describe(removed))
	lu.assertEquals(trim(removed[1] and removed[1].text or ""), "elseif (questFourComplete and completedTier4) then", TUROLDINE .. ": the changed base line")
	lu.assertEquals(#added, 1, TUROLDINE .. ": added lines: " .. describe(added))
	lu.assertEquals(added[1] and added[1].n, removed[1] and removed[1].n, TUROLDINE .. ": the new line takes the old line's place")
	lu.assertTrue(added[1] ~= nil and hasRewardTest(added[1].text, "CorsecSquadronScreenplay.TIER4_QUEST_STRING_4.name"),
		TUROLDINE .. ": the tier-done line tests the TIER4_QUEST_STRING_4 :reward key; added " .. describe(added))
end

-- Viopa (C-2): the tier-done line only
-- AC-6
function TestMission4FilePins:test_viopaConvoHandler_differs_from_the_base_only_on_the_tier_done_line()
	local removed, added = diffOf(VIOPA)

	lu.assertEquals(#removed, 1, VIOPA .. ": removed lines: " .. describe(removed))
	lu.assertEquals(trim(removed[1] and removed[1].text or ""), "elseif (questFourComplete and completedTier2) then", VIOPA .. ": the changed base line")
	lu.assertEquals(#added, 1, VIOPA .. ": added lines: " .. describe(added))
	lu.assertEquals(added[1] and added[1].n, removed[1] and removed[1].n, VIOPA .. ": the new line takes the old line's place")
	lu.assertTrue(added[1] ~= nil and hasRewardTest(added[1].text, "HavocSquadronScreenplay.TIER2_QUEST_STRING_4.name"),
		VIOPA .. ": the tier-done line tests the TIER2_QUEST_STRING_4 :reward key; added " .. describe(added))
end

---------------------------------------------------------------------------------------------
-- AC-7, C-4: space_helpers.lua differs by exactly one line
---------------------------------------------------------------------------------------------

-- AC-7
function TestMission4FilePins:test_space_helpers_differs_from_the_base_by_the_overload_argument_only()
	local removed, added = diffOf(D.SH)

	lu.assertEquals(#removed, 1, D.SH .. ": removed lines: " .. describe(removed))
	lu.assertEquals(#added, 1, D.SH .. ": added lines: " .. describe(added))
	lu.assertEquals(removed[1] and trim(removed[1].text), "local pItem = giveItem(pInventory, itemString, -1)", D.SH .. ": the changed base line")
	lu.assertEquals(removed[1] and removed[1].n, 1390, D.SH .. ": the changed base line number")
	lu.assertEquals(added[1] and trim(added[1].text), "local pItem = giveItem(pInventory, itemString, -1, true)", D.SH .. ": the new line")
	lu.assertEquals(added[1] and added[1].n, 1390, D.SH .. ": the new line number")
end

-- AC-7: the datapad call keeps three arguments
function TestMission4FilePins:test_the_datapad_mission_object_call_in_space_helpers_has_three_arguments()
	local text = now(D.SH)

	lu.assertNotNil(text:find('giveItem(pDatapad, "object/mission/mission_object.iff", -1)', 1, true), D.SH .. ": giveItem(pDatapad, ..., -1)")
	lu.assertEquals(D.count(text, "giveItem("), 2, D.SH .. ": giveItem call sites")
end

---------------------------------------------------------------------------------------------
-- I-5: no other file changes
---------------------------------------------------------------------------------------------

-- I-5: only while the working tree is still on the base commit (after the feature commit the base diff includes later features)
function TestMission4FilePins:test_only_the_five_files_of_the_spec_differ_from_the_base_under_bin_and_src()
	if FEATURE_COMMIT ~= nil then
		lu.skip("FEATURE_COMMIT is set: later features may change other files")
	end

	local rc, head = D.shell("git rev-parse HEAD")

	if rc ~= 0 or head:sub(1, #BASE) ~= BASE then
		lu.skip("HEAD is not " .. BASE .. " (" .. trim(head) .. "): the whole-tree pin only applies before the feature is committed")
	end

	local _, changed = D.shell("git diff --name-only " .. BASE .. " -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local _, untracked = D.shell("git ls-files --others --exclude-standard --full-name -- ':/MMOCoreORB/bin' ':/MMOCoreORB/src'")
	local files = {}

	for line in (changed .. untracked):gmatch("[^\n]+") do
		files[#files + 1] = line
	end

	table.sort(files)

	local expected = {}

	for _, path in ipairs({ KAYDINE, RIKKH, TUROLDINE, VIOPA, D.SH }) do
		expected[#expected + 1] = "MMOCoreORB/" .. path
	end

	table.sort(expected)

	lu.assertEquals(files, expected, "files under bin/ and src/ that differ from " .. BASE)
end
