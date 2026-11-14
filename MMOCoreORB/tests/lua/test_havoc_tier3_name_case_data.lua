-- Havoc tier 3 quest name case (havoc-tier3-quest-name-case): the patrol of Aqzow's mission 1 is `corellia_rebel_tier3_1_a`, not `_A`.
-- Spec: .claude/work/havoc-tier3-quest-name-case/01-spec.md (Content contract 1-4 and 6, Data mapping, I-1, I-2, I-3, I-6, AC-1 to AC-4).
--
-- The client knows the quest only as `spacequest/patrol/corellia_rebel_tier3_1_a` (its journal CRC table is case-sensitive), and SWG's own quest file is
-- `patrol/corellia_rebel_tier3_1_a.tab`. The SWG `.tab` fixtures stay byte copies, including the `_A` typo in the recovery's triggerArg (D-5).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("trainer_fixes_data")

T.load()

local HSP = "bin/scripts/screenplays/space/squadrons/HavocSquadronScreenplay.lua"
local AQH = "bin/scripts/screenplays/space/conversations/rebel/havoc_squadron/aqzowConvoHandler.lua"
local BASE_COMMIT = "28bcf23cd8"
local OLD = "corellia_rebel_tier3_1_A"
local NEW = "corellia_rebel_tier3_1_a"
local GEN = "PYTHONDONTWRITEBYTECODE=1 python3 -B tests/lua/tools/gen_client_sids.py"

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function readFile(path)
	local f = io.open(path, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

local function linesOf(text)
	local lines = {}

	for line in (text .. (text:sub(-1) == "\n" and "" or "\n")):gmatch("([^\n]*)\n") do
		lines[#lines + 1] = line
	end

	return lines
end

local function count(text, needle)
	local n, init = 0, 1

	while true do
		local s, e = text:find(needle, init, true)

		if s == nil then
			return n
		end

		n = n + 1
		init = e + 1
	end
end

-- The quest tables of the three squadron files: the quest-type base tables (SpaceBattleScreenplay, ...) have an empty questName
local function squadronQuests()
	local out = {}

	for _, global in ipairs(H.questGlobals()) do
		local q = rawget(_G, global)

		if type(q.questName) == "string" and q.questName ~= "" then
			out[#out + 1] = global
		end
	end

	return out
end

local function quest(global) return H.expectGlobal(global, "quest table of the renamed patrol") end

---------------------------------------------------------------------------------------------
-- AC-1: the rename
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseRename = {}

function TestHavocTier3NameCaseRename:setUp() H.reset() end

-- AC-1
function TestHavocTier3NameCaseRename:test_the_patrol_is_a_registered_quest_table_named_in_lower_case()
	local q = quest("patrol_" .. NEW)

	lu.assertEquals(q.className, "patrol_" .. NEW, "className")
	lu.assertEquals(q.questName, NEW, "questName")
	lu.assertEquals(q.questType, "patrol", "questType")
	lu.assertNotNil(H.registered("patrol_" .. NEW), "registerScreenPlay(patrol_" .. NEW .. ")")
	lu.assertTrue(H.registered("patrol_" .. NEW).start, "registered with start = true, like the other quest tables")
end

-- AC-1
function TestHavocTier3NameCaseRename:test_the_upper_case_patrol_global_and_registration_are_gone()
	lu.assertTrue(rawget(_G, "patrol_" .. OLD) == nil, "global patrol_" .. OLD .. " must not exist")
	lu.assertNil(H.registered("patrol_" .. OLD), "registerScreenPlay(patrol_" .. OLD .. ")")
end

-- AC-1
function TestHavocTier3NameCaseRename:test_the_recovery_starts_the_lower_case_patrol_as_its_side_quest()
	local q = H.expectGlobal("recovery_corellia_rebel_tier3_1", "mission 1 head")

	lu.assertEquals(q.sideQuestType, "patrol", "recovery_corellia_rebel_tier3_1: sideQuestType")
	lu.assertEquals(q.sideQuestName, NEW, "recovery_corellia_rebel_tier3_1: sideQuestName")
end

-- AC-1
function TestHavocTier3NameCaseRename:test_the_surprise_attack_names_the_lower_case_patrol_as_its_parent()
	local q = H.expectGlobal("destroy_surpriseattack_corellia_rebel_tier3_1_b", "mission 1 child")

	lu.assertEquals(q.parentQuest, "patrol_" .. NEW, "destroy_surpriseattack_corellia_rebel_tier3_1_b: parentQuest")
	lu.assertEquals(q.parentQuestType, "patrol", "destroy_surpriseattack_corellia_rebel_tier3_1_b: parentQuestType")
	lu.assertEquals(q.parentQuestName, NEW, "destroy_surpriseattack_corellia_rebel_tier3_1_b: parentQuestName")
end

-- AC-1
function TestHavocTier3NameCaseRename:test_the_mission_1_side_quest_constant_names_the_lower_case_patrol()
	lu.assertEquals(HavocSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE1, { type = "patrol", name = NEW }, "TIER3_QUEST_STRING_1_SIDE1")
end

-- AC-2
function TestHavocTier3NameCaseRename:test_the_mission_1_chain_walks_head_patrol_b_c_d_in_order()
	local chain = {}

	for _, member in ipairs(SpaceHelpers:getSpaceQuestChain("recovery_corellia_rebel_tier3_1")) do
		chain[#chain + 1] = member.global
	end

	lu.assertEquals(chain, {
		"recovery_corellia_rebel_tier3_1",
		"patrol_corellia_rebel_tier3_1_a",
		"destroy_surpriseattack_corellia_rebel_tier3_1_b",
		"assassinate_corellia_rebel_tier3_1_c",
		"space_battle_corellia_rebel_tier3_1_d",
	}, "chain of recovery_corellia_rebel_tier3_1")
end

-- Contract 2
function TestHavocTier3NameCaseRename:test_the_legacy_table_names_the_old_patrol_and_moves_it_to_the_new_one()
	lu.assertEquals(HavocSquadronScreenplay.LEGACY_TIER3_QUESTS, {
		{ type = "patrol", name = OLD, moveTo = { { type = "patrol", name = NEW } } },
	}, "HavocSquadronScreenplay.LEGACY_TIER3_QUESTS")
	lu.assertEquals(HavocSquadronScreenplay.LEGACY_MIGRATION_STEPS, { "migrateLegacyTier3" }, "HavocSquadronScreenplay.LEGACY_MIGRATION_STEPS")
end

-- Contract 3
function TestHavocTier3NameCaseRename:test_the_migration_functions_exist()
	for _, name in ipairs({ "migrateLegacyProgress", "migrateLegacyTier3" }) do
		lu.assertEquals(type(HavocSquadronScreenplay[name]), "function", "HavocSquadronScreenplay:" .. name .. " must be defined")
	end
end

---------------------------------------------------------------------------------------------
-- I-1, I-2, I-3: names across the three squadrons
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseInvariants = {}

function TestHavocTier3NameCaseInvariants:setUp() H.reset() end

local NAME_FIELDS = { "className", "questName", "sideQuestName", "parentQuest", "parentQuestName", "sideFailQuestName" }

-- I-1: the only literal left under bin/scripts is the LEGACY_TIER3_QUESTS row
function TestHavocTier3NameCaseInvariants:test_exactly_one_corellia_rebel_tier3_1_A_literal_is_left_under_bin_scripts()
	local rc, out = shell("grep -rFo '" .. OLD .. "' bin/scripts")

	lu.assertEquals(rc, 0, "grep exit code (1 = no match at all, but the LEGACY_TIER3_QUESTS row must remain); output: " .. out)

	local hits = {}

	for line in out:gmatch("[^\n]+") do
		hits[#hits + 1] = line
	end

	lu.assertEquals(hits, { HSP .. ":" .. OLD }, "occurrences of " .. OLD .. " under bin/scripts (only the HSP legacy row may keep it)")
end

-- I-1
function TestHavocTier3NameCaseInvariants:test_no_quest_table_field_or_constant_has_an_upper_case_letter_in_a_quest_name()
	local bad = {}

	for _, global in ipairs(squadronQuests()) do
		local q = rawget(_G, global)

		for _, field in ipairs(NAME_FIELDS) do
			local v = q[field]

			if type(v) == "string" and v:find("%u") then
				bad[#bad + 1] = global .. "." .. field .. " = " .. v
			end
		end

		if global:find("%u") then
			bad[#bad + 1] = "global " .. global
		end
	end

	for _, squadron in ipairs(T.SQUADRONS) do
		for key, v in pairs(_G[squadron]) do
			if type(key) == "string" and key:find("_QUEST_STRING_") and type(v) == "table" and type(v.name) == "string" and v.name:find("%u") then
				bad[#bad + 1] = squadron .. "." .. key .. ".name = " .. v.name
			end
		end
	end

	table.sort(bad)
	lu.assertEquals(bad, {}, "quest names with upper-case letters")
end

-- I-2
function TestHavocTier3NameCaseInvariants:test_every_quest_table_is_the_global_named_type_underscore_name()
	local problems, n = {}, 0

	for _, global in ipairs(squadronQuests()) do
		local q = rawget(_G, global)
		local want = q.questType .. "_" .. q.questName

		n = n + 1

		if q.className ~= want then
			problems[#problems + 1] = global .. ": className " .. tostring(q.className) .. " ~= " .. want
		end

		if global ~= want then
			problems[#problems + 1] = global .. ": global name ~= " .. want
		end

		if H.registered(want) == nil then
			problems[#problems + 1] = global .. ": registerScreenPlay(" .. want .. ") is missing"
		end
	end

	lu.assertEquals(n, 153, "scanned the quest tables of the Corsec, Havoc and RSF files")
	table.sort(problems)
	lu.assertEquals(problems, {}, "className / global / registration")
end

local function defined(questType, questName)
	local q = rawget(_G, questType .. "_" .. questName)

	return type(q) == "table" and q.questType == questType and q.questName == questName
end

-- I-3
function TestHavocTier3NameCaseInvariants:test_every_side_parent_and_fail_reference_names_a_defined_quest_table()
	local problems = {}

	for _, global in ipairs(squadronQuests()) do
		local q = rawget(_G, global)

		for _, kind in ipairs({ "sideQuest", "parentQuest", "sideFailQuest" }) do
			local t, n = q[kind .. "Type"], q[kind .. "Name"]

			if type(n) == "string" and n ~= "" and not defined(t, n) then
				problems[#problems + 1] = global .. "." .. kind .. ": " .. tostring(t) .. "/" .. n
			end
		end
	end

	table.sort(problems)
	lu.assertEquals(problems, {}, "references that name no quest table")
end

-- I-3
function TestHavocTier3NameCaseInvariants:test_every_quest_string_constant_names_a_defined_quest_table()
	local problems, n = {}, 0

	for _, squadron in ipairs(T.SQUADRONS) do
		for key, v in pairs(_G[squadron]) do
			if type(key) == "string" and key:find("_QUEST_STRING_") and type(v) == "table" then
				n = n + 1

				if not defined(v.type, v.name) then
					problems[#problems + 1] = squadron .. "." .. key .. ": " .. tostring(v.type) .. "/" .. tostring(v.name)
				end
			end
		end
	end

	lu.assertTrue(n > 100, "scanned the quest string constants (" .. n .. ")")
	table.sort(problems)
	lu.assertEquals(problems, {}, "constants that name no quest table")
end

---------------------------------------------------------------------------------------------
-- AC-3: SWG conformance
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseSwg = {}

function TestHavocTier3NameCaseSwg:setUp() H.reset() end

-- AC-3: exact case, Linux is case-sensitive
function TestHavocTier3NameCaseSwg:test_the_patrol_has_a_swg_fixture_with_exactly_its_quest_name()
	local q = quest("patrol_" .. NEW)
	local path = H.FIXTURES .. "spacequest/patrol/" .. q.questName .. ".tab"
	local f = io.open(path, "rb")

	lu.assertNotNil(f, "fixture spacequest/patrol/" .. q.questName .. ".tab (exact case)")
	f:close()
end

-- AC-3, Data mapping (documented lossy row)
function TestHavocTier3NameCaseSwg:test_the_recovery_side_quest_is_the_trigger_arg_lower_cased()
	local rec = H.questFixture("recovery", "corellia_rebel_tier3_1")
	local q = H.expectGlobal("recovery_corellia_rebel_tier3_1", "mission 1 head")
	local trigger = rec:get("triggerArg")

	lu.assertEquals(trigger, "patrol:" .. OLD, "the SWG fixture keeps the typo (D-5)")

	local t, n = H.Tab.splitQuestRef(trigger)

	lu.assertEquals({ q.sideQuestType, q.sideQuestName }, { t, n:lower() }, "recovery/corellia_rebel_tier3_1: {sideQuestType, sideQuestName} = triggerArg with the name lower-cased")
	lu.assertEquals(q.sideQuestName:lower(), n:lower(), "differs from the raw triggerArg only by case")
	lu.assertNotEquals(q.sideQuestName, n, "...and does differ by case")
end

-- AC-3, Data mapping
function TestHavocTier3NameCaseSwg:test_the_surprise_attack_parent_matches_the_patrol_fixture_stem()
	local b = H.questFixture("destroy_surpriseattack", "corellia_rebel_tier3_1_b")
	local q = H.expectGlobal("destroy_surpriseattack_corellia_rebel_tier3_1_b", "mission 1 child")

	local f = io.open(H.FIXTURES .. "spacequest/patrol/" .. q.parentQuestName .. ".tab", "rb")

	lu.assertNotNil(f, "fixture spacequest/patrol/" .. tostring(q.parentQuestName) .. ".tab (exact case) for parentQuestName")
	f:close()
	lu.assertEquals(q.questName, "corellia_rebel_tier3_1_b", "questName")
	lu.assertNotNil(b, "destroy_surpriseattack/corellia_rebel_tier3_1_b fixture")
end

-- I-6, D-5: the SWG copies are untouched (CRLF) and, with the research clone present, byte-identical to it
function TestHavocTier3NameCaseSwg:test_the_swg_fixtures_of_the_chain_stay_crlf_byte_copies()
	local swg = "/home/swgemu/swg-source-research/dsrc/sku.0/sys.server/compiled/game/datatables/spacequest/"

	for _, rel in ipairs({ "recovery/corellia_rebel_tier3_1.tab", "patrol/" .. NEW .. ".tab" }) do
		local text = readFile(H.FIXTURES .. "spacequest/" .. rel)

		lu.assertNotNil(text, rel)
		lu.assertTrue(count(text, "\r\n") > 0, rel .. ": CRLF line endings")

		local original = readFile(swg .. rel)

		if original ~= nil then
			lu.assertTrue(text == original, rel .. ": byte copy of SWG-Source")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: client strings
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseClientStrings = {}

function TestHavocTier3NameCaseClientStrings:setUp() H.reset() end

-- AC-4: the keys SpacePatrolScreenplay.lua:76-122 and SpaceQuestLogic.lua:70, 147 build
function TestHavocTier3NameCaseClientStrings:test_the_patrol_has_a_client_string_fixture_with_the_keys_the_scripts_build()
	local q = quest("patrol_" .. NEW)
	local sids, why = CS.sids("spacequest/patrol/" .. q.questName)

	lu.assertNotNil(sids, "client strings of the patrol (" .. tostring(why) .. ")")

	for _, id in ipairs({ "title", "title_d", "quest_patrol_t", "split_quest_alert" }) do
		lu.assertTrue(sids[id], "@spacequest/patrol/" .. q.questName .. ":" .. id)
	end
end

-- AC-4
function TestHavocTier3NameCaseClientStrings:test_no_client_string_fixture_has_an_upper_case_stem()
	local rc, out = shell("find " .. H.FIXTURES .. "string -name '*[A-Z]*.sids' -printf '%f\\n'")

	lu.assertEquals(rc, 0, "find exit code; output: " .. out)
	lu.assertEquals(out, "", "string fixtures with an upper-case letter in the file name")
end

-- AC-4
function TestHavocTier3NameCaseClientStrings:test_the_generator_check_passes_for_the_patrol_fixture()
	if not H.fileExists("/tre/patch_12_00.tre") or shell("command -v python3 >/dev/null") ~= 0 then
		lu.skip("generator check needs /tre and python3")
	end

	local rc, out = shell(GEN .. " --check spacequest/patrol/" .. NEW)

	lu.assertEquals(rc, 0, "gen_client_sids.py --check spacequest/patrol/" .. NEW .. "; output: " .. out)
end

---------------------------------------------------------------------------------------------
-- AC-1: the file diff of the Havoc screenplay
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseFilePins = {}

function TestHavocTier3NameCaseFilePins:setUp() H.reset() end

local RENAMED_LINES = { 587, 627, 628, 630, 657, 675, 677, 2070, 2198 }

local function baseHsp()
	local rc, text = shell("git show " .. BASE_COMMIT .. ":MMOCoreORB/" .. HSP)

	if rc ~= 0 then
		lu.skip("git show " .. BASE_COMMIT .. " is unavailable: " .. text)
	end

	return text
end

-- The base lines of the orphan quest (the table with its comment, blank lines and registration; the TIER4_QUEST_STRING_MASTER constant; the
-- reset lines), found by content. Fails when the base does not hold exactly the 31 lines the Rebel master trainer spec lists.
local function removeOrphan(lines)
	local drop, n = {}, 0

	local function mark(i)
		drop[i] = true
		n = n + 1
	end

	local first, last, const, reset

	for i, line in ipairs(lines) do
		if line == "destroy_corellia_rebel_master = SpaceDestroyScreenplay:new {" then
			first = i
		elseif line == 'registerScreenPlay("destroy_corellia_rebel_master", true)' then
			last = i
		elseif line:find("TIER4_QUEST_STRING_MASTER = ", 1, true) then
			const = i
		elseif line == "\tdestroy_corellia_rebel_master:resetQuest(pPlayer)" then
			reset = i
		end
	end

	lu.assertNotNil(first and last and const and reset, "the base holds the orphan table, its registration, its constant and its reset")
	lu.assertEquals(lines[first - 1], "-- Master Mission: Destroy", "comment above the orphan table")
	lu.assertEquals(lines[first - 2], "", "blank line above the orphan comment")
	lu.assertEquals(lines[reset - 1], "\t-- Master", "comment above the orphan reset")
	lu.assertEquals(lines[reset - 2], "", "blank line above the orphan reset comment")
	lu.assertEquals(lines[reset + 1]:find("TIER4_QUEST_STRING_MASTER", 1, true) ~= nil, true, "the clearSpaceQuest line of the orphan")

	for i = first - 2, last do
		mark(i)
	end

	mark(const)

	for i = reset - 2, reset + 1 do
		mark(i)
	end

	lu.assertEquals(n, 31, "orphan lines removed from the expected text")

	local out = {}

	for i, line in ipairs(lines) do
		if not drop[i] then
			out[#out + 1] = line
		end
	end

	return out
end

-- AC-1 (I-6): HSP differs from the base only by the 9 renamed lines, the 31 removed orphan lines and three inserted blocks
function TestHavocTier3NameCaseFilePins:test_the_havoc_screenplay_differs_from_the_base_by_the_nine_renames_and_three_inserted_blocks()
	local base = baseHsp()
	local lines = linesOf(base)

	lu.assertEquals(#lines, 2307, "base line count of the Havoc file")

	local renamed = {}

	for i, line in ipairs(lines) do
		if line:find(OLD, 1, true) then
			renamed[#renamed + 1] = i
		end
	end

	lu.assertEquals(renamed, RENAMED_LINES, "base lines that hold " .. OLD)

	for _, i in ipairs(RENAMED_LINES) do
		lines[i] = lines[i]:gsub(OLD, NEW)
	end

	-- space-master-trainer-rebel (Q-1 option A) removes the orphan destroy_corellia_rebel_master: 31 lines, matched by content (their line numbers
	-- differ from the base's), so the diff against the working tree stays the three pure-insertion hunks
	lines = removeOrphan(lines)

	-- space-destroy-duty-swg-waves: viopa_rebel_6 and corellia_rebel_tier4_1 shipTypes follow the .tab columns (spec Content contract 8)
	local function replaceBlock(from, to)
		local text = table.concat(lines, "\n")
		local a, b = text:find(from, 1, true)

		lu.assertNotNil(a, "base block to fix not found: " .. from:sub(1, 60))
		lu.assertNil(text:find(from, b + 1, true), "base block to fix is not unique: " .. from:sub(1, 60))
		lines = linesOf(text:sub(1, a - 1) .. to .. text:sub(b + 1) .. "\n")
	end

	local F, I = '{"imp_tie_fighter_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},', '{"imp_tie_interceptor_tier2", "imp_tie_fighter_tier2", "imp_tie_fighter_tier2"},'
	local B = '{"blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4"},'

	replaceBlock("\t\t" .. F .. "\n\t\t" .. I .. "\n\t\t" .. F,
		"\t\t" .. '{"imp_tie_fighter_tier2", "imp_tie_interceptor_tier2", "imp_tie_fighter_tier2"},' .. "\n\t\t" .. F .. "\n\t\t" .. F)
	replaceBlock("\t\t" .. B .. "\n\t\t" .. B .. "\n\t\t" .. B .. '\n\t\t{"blacksun_fighter_s01_tier4"},\n\t\t{"blacksun_vehement_tier4"},',
		'\t\t{"blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4"},\n'
		.. '\t\t{"blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_fighter_s01_tier4", "blacksun_vehement_tier4"},')

	local expected = os.tmpname()
	local f = assert(io.open(expected, "wb"))

	f:write(table.concat(lines, "\n"), "\n")
	f:close()

	local text = readFile(HSP)

	lu.assertNotNil(text, HSP)
	lu.assertEquals(count(text, "\r"), 0, "HavocSquadronScreenplay.lua stays LF")
	lu.assertEquals(text:sub(-1), "\n", "HavocSquadronScreenplay.lua keeps its trailing newline")

	local rc, out = shell("diff -U0 " .. expected .. " " .. HSP)

	os.remove(expected)
	lu.assertEquals(rc ~= nil and rc <= 1, true, "diff failed: " .. out)

	local got = linesOf(text)
	local hunks, current = {}, nil

	for line in out:gmatch("[^\n]+") do
		local a, b, c, d = line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")

		if a then
			current = { oldStart = tonumber(a), oldCount = b == "" and 1 or tonumber(b), start = tonumber(c), count = d == "" and 1 or tonumber(d), text = {} }
			hunks[#hunks + 1] = current
		elseif current and line:sub(1, 1) == "-" and line:sub(1, 3) ~= "---" then
			lu.fail("the Havoc file lacks a line of the base (with the nine renames applied) or changes it; the missing line is `" .. line:sub(2) .. "`")
		elseif current and line:sub(1, 1) == "+" and line:sub(1, 3) ~= "+++" then
			current.text[#current.text + 1] = line:sub(2)
		end
	end

	lu.assertEquals(#hunks, 3, "inserted blocks (legacy data, migration functions, reset purge loop); hunks: " .. #hunks .. "\n" .. out)

	for i, h in ipairs(hunks) do
		lu.assertEquals(h.oldCount, 0, "block " .. i .. " is a pure insertion")
	end

	local function lineOf(pattern, from)
		for i = from or 1, #got do
			if got[i]:find(pattern, 1, true) then
				return i
			end
		end

		lu.fail("no line contains `" .. pattern .. "`")
	end

	local function endOf(startLine)
		for i = startLine, #got do
			if got[i] == "end" then
				return i
			end
		end
	end

	-- block 1: legacy data after TIER4_QUEST_STRING_DUTY_4, inside the screenplay table
	local duty4 = lineOf("TIER4_QUEST_STRING_DUTY_4 = ")
	local block1 = table.concat(hunks[1].text, "\n")

	lu.assertTrue(hunks[1].start >= duty4 and hunks[1].start <= duty4 + 3, "block 1 (legacy data) starts at line " .. hunks[1].start .. ", expected right after line " .. duty4)
	lu.assertTrue(block1:find("LEGACY_TIER3_QUESTS = {", 1, true) ~= nil, "block 1 defines LEGACY_TIER3_QUESTS")
	lu.assertTrue(block1:find('{type = "patrol", name = "' .. OLD .. '", moveTo = {{type = "patrol", name = "' .. NEW .. '"}}},', 1, true) ~= nil, "block 1: the legacy row")
	lu.assertTrue(block1:find('LEGACY_MIGRATION_STEPS = {"migrateLegacyTier3"},', 1, true) ~= nil, "block 1: the steps list")

	-- block 2: the migration functions after HavocSquadronScreenplay:start()
	local startEnd = endOf(lineOf("function HavocSquadronScreenplay:start()"))
	local block2 = table.concat(hunks[2].text, "\n")

	lu.assertTrue(hunks[2].start >= startEnd and hunks[2].start <= startEnd + 3, "block 2 (migration functions) starts at line " .. hunks[2].start .. ", expected right after line " .. startEnd)
	lu.assertTrue(block2:find("function HavocSquadronScreenplay:migrateLegacyProgress(pPlayer)", 1, true) ~= nil, "block 2 defines migrateLegacyProgress")
	lu.assertTrue(block2:find("function HavocSquadronScreenplay:migrateLegacyTier3(pPlayer)", 1, true) ~= nil, "block 2 defines migrateLegacyTier3")
	lu.assertTrue(block2:find('runProgressMigrations(pPlayer, "HavocSquadronScreenplay", self.LEGACY_MIGRATION_STEPS)', 1, true) ~= nil, "block 2: runs the versioned steps")
	lu.assertTrue(block2:find("migrateSpaceQuestEntry(pPlayer, legacy.type, legacy.name, legacy.moveTo)", 1, true) ~= nil, "block 2: migrates each legacy row")
	lu.assertNil(block2:find("moveQuestStatuses", 1, true), "block 2: no status key holds the patrol name, so nothing is moved")

	-- block 3: the purge loop inside resetAqzowQuests, after the mission 4 clears
	local resetStart = lineOf("function HavocSquadronScreenplay:resetAqzowQuests(pPlayer)")
	local resetEnd = endOf(resetStart)
	local side4 = lineOf("TIER3_QUEST_STRING_4_SIDE4.name", resetStart)
	local block3 = table.concat(hunks[3].text, "\n")

	lu.assertTrue(hunks[3].start > side4 and hunks[3].start < resetEnd, "block 3 (purge loop) starts at line " .. hunks[3].start .. ", expected inside resetAqzowQuests after line " .. side4)
	lu.assertTrue(block3:find("LEGACY_TIER3_QUESTS", 1, true) ~= nil, "block 3 loops over LEGACY_TIER3_QUESTS")
	lu.assertTrue(block3:find("SpaceHelpers:purgeSpaceQuest(pPlayer, legacy.type, legacy.name)", 1, true) ~= nil, "block 3 purges each legacy row")
end

-- I-6, Contract 5: Aqzow's handler calls the migration first, after the nil check, before the template wrapper
function TestHavocTier3NameCaseFilePins:test_aqzow_getInitialScreen_runs_the_migration_right_after_the_nil_check()
	local text = readFile(AQH)

	lu.assertNotNil(text, AQH)
	lu.assertEquals(count(text, "\r"), 0, "aqzowConvoHandler.lua stays LF")
	lu.assertEquals(text:sub(-1), "\n", "aqzowConvoHandler.lua keeps its trailing newline")

	local nilCheck = text:find("return nil\n\tend\n", 1, true)
	local migrate = text:find("HavocSquadronScreenplay:migrateLegacyProgress(pPlayer)", 1, true)
	local template = text:find("LuaConversationTemplate(pConvTemplate)", 1, true)

	lu.assertNotNil(migrate, "getInitialScreen calls HavocSquadronScreenplay:migrateLegacyProgress(pPlayer)")
	lu.assertTrue(nilCheck < migrate and migrate < template, "the call comes after the nil check and before LuaConversationTemplate(pConvTemplate)")
	lu.assertEquals(count(text, "migrateLegacyProgress"), 1, "the handler calls the migration once")
end

-- AC-10: the other Havoc handlers stay as they are (OQ-1 = A, D-8)
function TestHavocTier3NameCaseFilePins:test_the_other_havoc_handlers_do_not_call_the_migration()
	for _, name in ipairs({ "arkon", "kreezo", "viopa" }) do
		local rc, out = shell("grep -c migrateLegacyProgress bin/scripts/screenplays/space/conversations/rebel/havoc_squadron/" .. name .. "ConvoHandler.lua")

		lu.assertEquals(out:match("^%d+"), "0", name .. "ConvoHandler.lua: migrateLegacyProgress calls (rc " .. tostring(rc) .. ")")
	end
end
