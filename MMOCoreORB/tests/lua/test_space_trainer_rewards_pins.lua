-- File pins of space-trainer-rewards (AC-9): the exact text the feature changes and nothing else, against commit 1d980a2452.
-- Spec: .claude/work/space-trainer-rewards/01-spec.md (Content contract 1 to 5, AC-9, D-2, D-8, D-10).
--
-- The expected files are built from `git show 1d980a2452:<file>` with the spec's rules, never from the working tree. Every test skips when git
-- cannot show the base commit (like test_space_assassinate_payload_fixes.lua).

local lu = require("luaunit")
local H = require("harness")
local D = require("space_trainer_rewards_data")

local TAB = "\t"

local function base(path)
	local text, why = D.baseText(path)

	if text == nil then
		lu.skip("git show " .. D.BASE_COMMIT .. " is unavailable: " .. tostring(why))
	end

	return text
end

-- the working-tree text; `lf` asserts it stays LF (the changed files; some untouched handlers are CRLF in the base)
local function now(path, lf)
	local text = D.readFile(path)

	lu.assertNotNil(text, path)

	if lf then
		lu.assertEquals(D.count(text, "\r"), 0, path .. ": stays LF")
	end

	return text
end

local function firstDifference(label, got, want)
	for i = 1, math.max(#got, #want) do
		if got[i] ~= want[i] then
			lu.fail(string.format("%s:%d: expected `%s` but found `%s`", label, i, tostring(want[i]), tostring(got[i])))
		end
	end
end

-- the reward block of the Content contract (multi-line Havoc tier 4 shape)
local function block(credits, item)
	return {
		TAB .. "creditReward = " .. credits .. ",",
		TAB .. "itemReward = {",
		TAB .. TAB .. '{species = {-1}, item = "' .. item .. '"},',
		TAB .. "},",
	}
end

-- apply the spec's rules to the base lines for the given rows
local function applyRows(lines, rows)
	for _, r in ipairs(rows) do
		local first, last

		for i, line in ipairs(lines) do
			if first == nil and line:find("^" .. r.global .. " = Space") then
				first = i
			elseif first ~= nil and last == nil and line == "}" then
				last = i
			end
		end

		lu.assertNotNil(first, r.global .. ": table found in the base file")
		lu.assertNotNil(last, r.global .. ": table end found in the base file")

		local credit, item, zone

		for i = first, last do
			if lines[i]:find("^\tcreditReward = ") then credit = i end
			if lines[i] == "\titemReward = {}," then item = i end
			if lines[i]:find("^\tquestZone = ") then zone = i end
		end

		if credit then
			local width = 1

			if item then
				lu.assertEquals(item, credit + 1, r.global .. ": the empty itemReward follows creditReward")
				width = 2
			end

			for _ = 1, width do
				table.remove(lines, credit)
			end

			for k, text in ipairs(block(r.credits, r.item)) do
				table.insert(lines, credit + k - 1, text)
			end
		else
			lu.assertNotNil(zone, r.global .. ": questZone line")

			table.insert(lines, zone + 1, "")

			for k, text in ipairs(block(r.credits, r.item)) do
				table.insert(lines, zone + 1 + k, text)
			end
		end
	end

	return lines
end

local function rowsIn(squadronGlobals)
	local out = {}

	for _, r in ipairs(D.R_ROWS) do
		if squadronGlobals[r.trainer] then
			out[#out + 1] = r
		end
	end

	return out
end

TestTrainerRewardsFilePins = {}

function TestTrainerRewardsFilePins:setUp() H.reset() end

-- AC-9
function TestTrainerRewardsFilePins:test_CorsecSquadronScreenplay_differs_from_the_base_only_by_the_8_reward_blocks()
	local want = applyRows(D.linesOf(base(D.CSP)), rowsIn({ rikkh = true, turoldine = true }))
	local got = D.linesOf(now(D.CSP, true))

	lu.assertEquals(#want, 2180, "expected line count of the CorSec file (spec: 2158 + 22)")
	lu.assertEquals(#got, 2180, "CorsecSquadronScreenplay.lua line count")
	firstDifference("CorsecSquadronScreenplay.lua", got, want)
end

-- AC-9
function TestTrainerRewardsFilePins:test_HavocSquadronScreenplay_differs_from_the_base_only_by_the_8_reward_blocks()
	local want = applyRows(D.linesOf(base(D.HSP)), rowsIn({ aqzow = true, viopa = true }))
	local got = D.linesOf(now(D.HSP, true))

	lu.assertEquals(#want, 2306, "expected line count of the Havoc file (spec: 2284 + 22)")
	lu.assertEquals(#got, 2306, "HavocSquadronScreenplay.lua line count")
	firstDifference("HavocSquadronScreenplay.lua", got, want)
end

-- AC-9: the other squadron file is untouched
function TestTrainerRewardsFilePins:test_RsfSquadronScreenplay_is_byte_identical_to_the_base()
	lu.assertEquals(now(D.RSP) == base(D.RSP), true, "RsfSquadronScreenplay.lua differs from " .. D.BASE_COMMIT)
end

-- AC-9 (D-10): +100 rebel faction after each of the four pay calls, preceded by a blank line
function TestTrainerRewardsFilePins:test_aqzowConvoHandler_differs_from_the_base_only_by_the_4_faction_lines()
	local lines = D.linesOf(base(D.AQZOW))
	local want, pays = {}, 0

	for _, line in ipairs(lines) do
		want[#want + 1] = line

		local indent = line:match("^(\t+)[%w_]+:rewardPlayer%(pPlayer%)$")

		if indent then
			pays = pays + 1
			want[#want + 1] = ""
			want[#want + 1] = indent .. 'ghost:increaseFactionStanding("rebel", 100)'
		end
	end

	lu.assertEquals(pays, 4, "pay calls in the base Aqzow handler")
	lu.assertEquals(#lines, 283, "base line count")
	lu.assertEquals(#want, 291, "expected line count")

	local got = D.linesOf(now(D.AQZOW, true))

	lu.assertEquals(#got, 291, "aqzowConvoHandler.lua line count")
	firstDifference("aqzowConvoHandler.lua", got, want)
end

-- AC-9: SQL differs only inside rewardPlayer's item loop, +4 lines
function TestTrainerRewardsFilePins:test_SpaceQuestLogic_differs_from_the_base_only_inside_the_item_loop()
	local before = D.linesOf(base(D.SQL))
	local after = D.linesOf(now(D.SQL, true))

	local function find(lines, text)
		local found

		for i, line in ipairs(lines) do
			if line == text then
				lu.assertNil(found, "`" .. text .. "` occurs twice")
				found = i
			end
		end

		lu.assertNotNil(found, "`" .. text .. "` is in the file")

		return found
	end

	local startMark, endMark = TAB .. 'local rewardString = ""', TAB .. 'if (rewardString == "") then'
	local b1, b2 = find(before, startMark), find(before, endMark)
	local a1, a2 = find(after, startMark), find(after, endMark)

	lu.assertEquals(#before, 160, "base line count")
	lu.assertEquals(#after, 164, "SpaceQuestLogic.lua line count (+4)")
	lu.assertEquals(a1, b1, "the item loop starts where it did")

	for i = 1, b1 do
		lu.assertEquals(after[i], before[i], "SpaceQuestLogic.lua:" .. i .. " (before the item loop)")
	end

	for k = 0, #before - b2 do
		lu.assertEquals(after[a2 + k], before[b2 + k], "SpaceQuestLogic.lua:" .. (a2 + k) .. " (after the item loop)")
	end

	lu.assertEquals(a2 - b2, 4, "lines added inside the loop")
end

-- AC-9: every other trainer handler and the shared helpers are byte-identical
for _, key in ipairs(D.ORDER) do
	if key ~= "aqzow" then
		local path = D.HANDLER_DIR .. D.TRAINERS[key].handler

		-- AC-9
		TestTrainerRewardsFilePins["test_" .. key .. "ConvoHandler_is_byte_identical_to_the_base"] = function()
			lu.assertEquals(now(path) == base(path), true, path .. " differs from " .. D.BASE_COMMIT)
		end
	end
end

-- AC-9: Vrak pays nothing and stays as it was
function TestTrainerRewardsFilePins:test_vrakConvoHandler_is_byte_identical_to_the_base()
	local path = D.HANDLER_DIR .. "rebel/havoc_squadron/vrakConvoHandler.lua"

	lu.assertEquals(now(path) == base(path), true, path .. " differs from " .. D.BASE_COMMIT)
end

-- AC-9
function TestTrainerRewardsFilePins:test_space_helpers_is_byte_identical_to_the_base()
	lu.assertEquals(now(D.SH) == base(D.SH), true, D.SH .. " differs from " .. D.BASE_COMMIT)
end

-- AC-9: the pinned files are LF only
function TestTrainerRewardsFilePins:test_the_changed_files_stay_lf()
	for _, path in ipairs({ D.CSP, D.HSP, D.AQZOW, D.SQL }) do
		lu.assertEquals(D.count(D.readFile(path) or "", "\r"), 0, path .. ": carriage returns")
	end
end
