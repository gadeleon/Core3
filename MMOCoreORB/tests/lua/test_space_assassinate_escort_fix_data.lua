-- Assassinate quests honour mustDestroyEscort: data and fixtures (AC-1, AC-9).
-- Spec: .claude/work/space-assassinate-escort-fix/01-spec.md (I-1, I-7, D-3, D-13).
--
-- SWG: datatables/spacequest/assassinate/<quest>.tab, column mustDestroyEscort (row 3); script/space/quest_logic/assassinate*.java.
-- The 24 assassinate tables of CorSec, RSF and Havoc are discovered at run time (questType == "assassinate").

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local S = require("space_assassinate_escort_fix_scenario")
local D = require("space_convo_client_strings_data")

S.load()

local SWG_GAME = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/"
local BASE_COMMIT = "c01803c4fc"
-- The escort-fix commit: the "now" side of the pin below. Later features edit the working tree (space-assassinate-payload-fixes pins that).
local FEATURE_COMMIT = "3330e0d8e9"

local GLOBALS = S.globals()

-- The 10 whose SWG mustDestroyEscort is 0 (spec, Source inventory)
local MDE_FALSE = {
	assassinate_corellia_privateer_tier1_4a = true, assassinate_corellia_privateer_tier2_4a = true,
	assassinate_naboo_privateer_tier2_1a = true, assassinate_naboo_privateer_tier2_1b = true,
	assassinate_naboo_privateer_tier3_1d = true, assassinate_corellia_rebel_4 = true,
	assassinate_viopa_rebel_4 = true, assassinate_corellia_rebel_tier3_3_a = true,
	assassinate_corellia_rebel_tier3_4 = true, assassinate_corellia_rebel_tier4_2 = true,
}

local NEW_TABS = {
	"corellia_privateer_tier1_4a", "corellia_privateer_tier2_4a", "corellia_privateer_tier4_1b", "corellia_privateer_tier4_2a",
	"corellia_privateer_tier4_3b", "corellia_privateer_tier4_4a", "corellia_privateer_tier4_4b", "corellia_privateer_tier4_4d",
	"corellia_rebel_4", "viopa_rebel_4", "corellia_rebel_tier3_1_c", "corellia_rebel_tier3_3_a",
}

local JAVA = { "assassinate", "assassinate_ship", "assassinate_target" }

local SENT_IDS = {
	"arrival_phase_1", "arrival_phase_2", "assassinate_success", "destroy_escort", "escort_remaining", "escort_wiped_out",
	"failed_escape", "quest_target_t", "title", "title_d",
}

local function readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")
	f:close()

	return text
end

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function count(text, pattern)
	local n = 0

	for _ in text:gmatch(pattern) do
		n = n + 1
	end

	return n
end

---------------------------------------------------------------------------------------------
-- AC-1: mustDestroyEscort on the 24 tables
---------------------------------------------------------------------------------------------

TestAssassinateEscortFixData = {}

function TestAssassinateEscortFixData:setUp() H.reset() end

-- AC-1
function TestAssassinateEscortFixData:test_the_three_squadrons_define_24_assassinations()
	lu.assertEquals(#GLOBALS, 24, "assassinate quest tables of CorSec, RSF and Havoc")
end

for _, global in ipairs(GLOBALS) do
	-- AC-1, I-1
	TestAssassinateEscortFixData["test_" .. global .. "_sets_mustDestroyEscort_to_the_swg_value"] = function()
		local q = S.quest(global)
		local rec = H.questFixture("assassinate", q.questName)
		local name = "assassinate/" .. q.questName

		lu.assertEquals(#rec:list("mustDestroyEscort"), 1, name .. ": the .tab has exactly one non-empty mustDestroyEscort cell")
		lu.assertEquals(type(rawget(q, "mustDestroyEscort")), "boolean", name .. ": mustDestroyEscort is set on the table itself, as a boolean")
		lu.assertEquals(rawget(q, "mustDestroyEscort"), rec:num("mustDestroyEscort") == 1, name .. ": mustDestroyEscort")
	end
end

-- AC-1: the inventory's split, 10 false and 14 true
function TestAssassinateEscortFixData:test_exactly_the_ten_swg_zero_quests_are_false()
	local falses, trues = {}, 0

	for _, global in ipairs(GLOBALS) do
		local value = rawget(S.quest(global), "mustDestroyEscort")

		if value == false then
			falses[global] = true
		elseif value == true then
			trues = trues + 1
		end
	end

	lu.assertEquals(falses, MDE_FALSE, "quests with mustDestroyEscort = false")
	lu.assertEquals(trues, 14, "quests with mustDestroyEscort = true")
end

-- AC-1: the inventory agrees with the fixtures (guards the table above)
function TestAssassinateEscortFixData:test_the_swg_fixtures_have_the_same_ten_zeros()
	local falses = {}

	for _, global in ipairs(GLOBALS) do
		local q = S.quest(global)

		if not S.mde(q) then
			falses[global] = true
		end
	end

	lu.assertEquals(falses, MDE_FALSE, "fixtures with mustDestroyEscort = 0")
end

-- AC-1, SC-1, D-3: the type default is true
function TestAssassinateEscortFixData:test_the_quest_type_defaults_mustDestroyEscort_to_true()
	lu.assertEquals(rawget(SpaceAssassinateScreenplay, "mustDestroyEscort"), true, "SpaceAssassinateScreenplay.mustDestroyEscort")
end

-- AC-1, D-13: at the escort-fix commit the data lines are the only change in the three squadron files, one per table, right after its failTimer line
local SQUADRON_FILES = {
	{ "bin/scripts/screenplays/space/squadrons/CorsecSquadronScreenplay.lua", 10 },
	{ "bin/scripts/screenplays/space/squadrons/RsfSquadronScreenplay.lua", 7 },
	{ "bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua", 7 },
}

for _, row in ipairs(SQUADRON_FILES) do
	local path, want = row[1], row[2]
	local short = path:match("([^/]+)$")

	-- AC-1
	TestAssassinateEscortFixData["test_" .. short:gsub("%.lua$", "") .. "_differs_from_the_base_commit_only_by_" .. want .. "_mustDestroyEscort_lines"] = function()
		local rc, base = shell("git show " .. BASE_COMMIT .. ":MMOCoreORB/" .. path)

		if rc ~= 0 then
			lu.skip("git show " .. BASE_COMMIT .. " is unavailable: " .. base)
		end

		local nowRc, now = shell("git show " .. FEATURE_COMMIT .. ":MMOCoreORB/" .. path)

		if nowRc ~= 0 then
			lu.skip("git show " .. FEATURE_COMMIT .. " is unavailable: " .. now)
		end

		lu.assertEquals(count(now, "\r"), 0, short .. ": stays LF")

		local lines = {}
		local flagLines = 0

		for line in (now .. "\n"):gmatch("(.-)\n") do
			if line:match("^%s*mustDestroyEscort = %a+,$") then
				flagLines = flagLines + 1
			else
				lines[#lines + 1] = line
			end
		end

		lu.assertEquals(flagLines, want, short .. ": mustDestroyEscort lines")
		-- (compared line by line: a failing assertEquals on two whole files makes luaunit diff them for minutes)
		local baseLines = {}

		for line in (base .. "\n"):gmatch("(.-)\n") do
			baseLines[#baseLines + 1] = line
		end

		lu.assertEquals(#lines, #baseLines, short .. ": line count of the file minus the mustDestroyEscort lines, against " .. BASE_COMMIT .. " (" .. FEATURE_COMMIT .. " side)")

		for i = 1, #baseLines do
			if lines[i] ~= baseLines[i] then
				lu.fail(short .. ":" .. i .. ": differs from " .. BASE_COMMIT .. " (other than a mustDestroyEscort line): " .. tostring(lines[i]) .. " <> " .. baseLines[i])
			end
		end

		-- ... each one directly after a failTimer line, at the same indentation
		local previous
		local placed = 0

		for line in (now .. "\n"):gmatch("(.-)\n") do
			if line:match("^%s*mustDestroyEscort = %a+,$") then
				lu.assertNotNil(previous and previous:match("^%s*failTimer = "), short .. ": a mustDestroyEscort line follows a failTimer line (after: " .. tostring(previous) .. ")")
				lu.assertEquals(line:match("^(%s*)"), previous:match("^(%s*)"), short .. ": indentation of the mustDestroyEscort line")
				placed = placed + 1
			end

			previous = line
		end

		lu.assertEquals(placed, want, short .. ": placed lines")
	end
end

---------------------------------------------------------------------------------------------
-- AC-1: fixtures are byte-identical copies of SWG-Source
---------------------------------------------------------------------------------------------

TestAssassinateEscortFixFixtures = {}

local function crlfOnly(text)
	-- every LF is preceded by CR, and no CR stands alone
	return count(text, "\n") > 0 and count(text, "\n") == count(text, "\r\n") and count(text, "\r") == count(text, "\r\n")
end

for _, name in ipairs(NEW_TABS) do
	-- AC-1
	TestAssassinateEscortFixFixtures["test_the_" .. name .. "_tab_is_a_crlf_copy_of_swg_source"] = function()
		local ours = readFile(H.FIXTURES .. "spacequest/assassinate/" .. name .. ".tab")

		lu.assertNotNil(ours, name .. ".tab: missing fixture (cp it from SWG-Source)")
		lu.assertTrue(crlfOnly(ours), name .. ".tab: CRLF line endings, as in SWG-Source")

		local swg = readFile(SWG_GAME .. "datatables/spacequest/assassinate/" .. name .. ".tab")

		if swg == nil then
			lu.skip("the SWG-Source clone is not at " .. SWG_GAME)
		end

		lu.assertTrue(ours == swg, name .. ".tab: byte-identical to SWG-Source")
	end
end

-- AC-1: all 24 fixtures are there (12 existing + 12 new) and match SWG-Source when the clone exists
function TestAssassinateEscortFixFixtures:test_every_assassinate_table_has_a_swg_fixture_identical_to_swg_source()
	for _, global in ipairs(GLOBALS) do
		local q = S.quest(global)
		local ours = readFile(H.FIXTURES .. "spacequest/assassinate/" .. q.questName .. ".tab")

		lu.assertNotNil(ours, q.questName .. ".tab: fixture")

		local swg = readFile(SWG_GAME .. "datatables/spacequest/assassinate/" .. q.questName .. ".tab")

		if swg ~= nil then
			lu.assertTrue(ours == swg, q.questName .. ".tab: byte-identical to SWG-Source")
		end
	end
end

for _, name in ipairs(JAVA) do
	-- AC-1
	TestAssassinateEscortFixFixtures["test_the_" .. name .. "_java_is_a_crlf_copy_of_swg_source"] = function()
		local rel = "script/space/quest_logic/" .. name .. ".java"
		local ours = readFile(H.FIXTURES .. rel)

		lu.assertNotNil(ours, rel .. ": missing fixture (cp it from SWG-Source)")
		lu.assertTrue(crlfOnly(ours), rel .. ": CRLF line endings, as in SWG-Source")

		local swg = readFile(SWG_GAME .. rel)

		if swg == nil then
			lu.skip("the SWG-Source clone is not at " .. SWG_GAME)
		end

		lu.assertTrue(ours == swg, rel .. ": byte-identical to SWG-Source")
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: client strings
---------------------------------------------------------------------------------------------

TestAssassinateEscortFixClientStrings = {}

for _, global in ipairs(GLOBALS) do
	-- AC-9, I-7
	TestAssassinateEscortFixClientStrings["test_" .. global .. "_has_every_sent_string_id_in_the_client_fixture"] = function()
		local q = S.quest(global)
		local file = "spacequest/assassinate/" .. q.questName
		local sids, why = CS.sids(file)

		lu.assertNotNil(sids, file .. ": " .. tostring(why))

		local missing = {}

		for _, id in ipairs(SENT_IDS) do
			if not sids[id] then
				missing[#missing + 1] = id
			end
		end

		lu.assertEquals(missing, {}, file .. ": ids the quest type sends that the client string file lacks")

		if S.splitsOnFailure(q) then
			lu.assertTrue(sids["split_quest_alert"] == true, file .. ": split_quest_alert (failure split)")
		end
	end
end

-- AC-9
function TestAssassinateEscortFixClientStrings:test_space_quest_has_the_ids_the_assassinations_send()
	local sids, why = CS.sids("space/quest")

	lu.assertNotNil(sids, "space/quest: " .. tostring(why))

	for _, id in ipairs({ "quest_won", "quest_failed", "duty_update_s", "mission_abandoned", "quest_alert_s" }) do
		lu.assertTrue(sids[id] == true, "space/quest: " .. id)
	end
end

-- AC-9
function TestAssassinateEscortFixClientStrings:test_the_generator_check_passes_for_the_24_fixtures_and_space_quest()
	local rc = shell("command -v python3 >/dev/null")

	if not H.fileExists("/tre/patch_12_00.tre") or rc ~= 0 then
		lu.skip("generator check needs /tre/patch_12_00.tre and python3")
	end

	local args = { "space/quest" }

	for _, global in ipairs(GLOBALS) do
		args[#args + 1] = "spacequest/assassinate/" .. S.quest(global).questName
	end

	local code, out = shell("PYTHONDONTWRITEBYTECODE=1 python3 tests/lua/tools/gen_client_sids.py --check " .. table.concat(args, " "))

	lu.assertEquals(code, 0, "gen_client_sids.py --check exit code; output: " .. out)
	lu.assertFalse(out:find("DIFFERS", 1, true) ~= nil or out:find("MISSING", 1, true) ~= nil, "gen_client_sids.py --check output: " .. out)
end

-- AC-9
function TestAssassinateEscortFixClientStrings:test_no_conversation_string_gap_is_left()
	lu.assertEquals(D.KNOWN_GAPS, {}, "KNOWN_GAPS")
end
