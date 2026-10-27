-- Havoc tier 3 quest name case (havoc-tier3-quest-name-case): the regression guard against the client's quest table.
-- Spec: .claude/work/havoc-tier3-quest-name-case/01-spec.md (Content contract 7, I-4, AC-5, D-9, D-10).
--
-- fixtures/misc/quest_crc_string_table.names lists the quests of the client's misc/quest_crc_string_table.iff, generated read-only from /tre by
-- `tools/gen_client_sids.py --quest-names` (regenerate it, never edit it). The client maps journal CRCs to quests through that table and the CRC is
-- case-sensitive, so a quest table whose "spacequest/<type>/<name>" is not in the list has no readable journal entry (`_A` instead of `_a` was such a slip).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local NAMES = H.FIXTURES .. "misc/quest_crc_string_table.names"
local GEN = "PYTHONDONTWRITEBYTECODE=1 python3 -B tests/lua/tools/gen_client_sids.py --quest-names"

-- D-10: the single named exception (unreachable orphan; no SWG or client counterpart). Not KNOWN_GAPS.
local EXCEPTIONS = { "spacequest/destroy/corellia_rebel_master" }

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function readNames()
	local f = io.open(NAMES, "rb")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()

	local list, set = {}, {}

	for line in text:gmatch("([^\n]*)\n") do
		list[#list + 1] = line
		set[line] = true
	end

	return list, set, text
end

-- "spacequest/<type>/<name>" of every squadron quest table that the client list does not hold, sorted
local function missingFromClient(set, tables)
	local out = {}

	for _, q in ipairs(tables) do
		local path = "spacequest/" .. q.questType .. "/" .. q.questName

		if not set[path] then
			out[#out + 1] = path
		end
	end

	table.sort(out)
	return out
end

local function squadronTables()
	local out = {}

	for _, global in ipairs(H.questGlobals()) do
		local q = rawget(_G, global)

		-- the quest-type base tables (SpaceBattleScreenplay, ...) have an empty questName
		if type(q.questName) == "string" and q.questName ~= "" then
			out[#out + 1] = q
		end
	end

	return out
end

TestHavocTier3ClientQuestNames = {}

function TestHavocTier3ClientQuestNames:setUp() H.reset() end

-- AC-5: the committed list
function TestHavocTier3ClientQuestNames:test_the_client_quest_name_list_is_committed_sorted_lf_and_complete()
	local list, set, text = readNames()

	lu.assertNotNil(list, "tests/lua/fixtures/misc/quest_crc_string_table.names (generate it with tools/gen_client_sids.py --quest-names)")
	lu.assertEquals(#list, 756, "names in the client quest table")
	lu.assertEquals(text:find("\r", 1, true), nil, "LF only")
	lu.assertEquals(text:sub(-1), "\n", "trailing newline")

	for i = 2, #list do
		lu.assertTrue(list[i - 1] < list[i], "byte-sorted and unique at line " .. i .. ": `" .. list[i - 1] .. "` then `" .. list[i] .. "`")
	end

	lu.assertTrue(set["spacequest/patrol/corellia_rebel_tier3_1_a"], "the client knows the patrol as _a")
	lu.assertNil(set["spacequest/patrol/corellia_rebel_tier3_1_A"], "the client has no upper-case entry")
end

-- AC-5, I-4
function TestHavocTier3ClientQuestNames:test_every_squadron_quest_table_is_a_quest_the_client_knows_except_the_named_orphan()
	local _, set = readNames()

	lu.assertNotNil(set, "client quest name list")

	local tables = squadronTables()

	lu.assertEquals(#tables, 154, "Space*:new tables in the Corsec, Havoc and RSF files")
	lu.assertEquals(missingFromClient(set, tables), EXCEPTIONS, "quest tables whose spacequest/<type>/<name> is not in the client quest table (I-4)")
end

-- AC-5: the guard itself catches a case-only slip (so a future _A cannot pass)
function TestHavocTier3ClientQuestNames:test_the_guard_names_a_quest_that_differs_from_the_client_only_by_case()
	local _, set = readNames()
	local fake = { { questType = "patrol", questName = "corellia_rebel_tier3_1_A" }, { questType = "patrol", questName = "corellia_rebel_tier3_1_a" } }

	lu.assertEquals(missingFromClient(set, fake), { "spacequest/patrol/corellia_rebel_tier3_1_A" }, "guard result")
end

local function generatorUsable()
	if not H.fileExists("/tre/patch_14_00.tre") then
		lu.skip("generator check needs /tre/patch_14_00.tre")
	end

	if shell("command -v python3 >/dev/null") ~= 0 then
		lu.skip("generator check needs python3")
	end
end

-- AC-5: --check reproduces the committed list byte for byte
function TestHavocTier3ClientQuestNames:test_the_generator_check_reproduces_the_committed_list()
	generatorUsable()

	local rc, out = shell(GEN .. " --check")

	lu.assertEquals(rc, 0, "gen_client_sids.py --quest-names --check exit code; output: " .. out)
end

-- AC-5: --check reads only and notices a changed list (negative case on a scratch copy)
function TestHavocTier3ClientQuestNames:test_the_generator_check_fails_on_a_scratch_copy_with_the_upper_case_name()
	generatorUsable()

	local _, _, text = readNames()
	local tmp = os.tmpname()
	local f = assert(io.open(tmp, "wb"))

	f:write((text:gsub("spacequest/patrol/corellia_rebel_tier3_1_a\n", "spacequest/patrol/corellia_rebel_tier3_1_A\n")))
	f:close()

	local rc, out = shell(GEN .. " --check --names-file " .. tmp)

	os.remove(tmp)
	lu.assertEquals(rc, 1, "exit code on a changed list; output: " .. out)
	lu.assertTrue(out:find("DIFFERS", 1, true) ~= nil, "output names the difference: " .. out)
end

-- AC-5: the generator documents the new mode
function TestHavocTier3ClientQuestNames:test_the_generator_documents_the_quest_names_mode_as_read_only()
	local f = assert(io.open("tests/lua/tools/gen_client_sids.py", "r"))
	local text = f:read("a")

	f:close()

	for _, needle in ipairs({ "--quest-names", "quest_crc_string_table", "--check" }) do
		lu.assertTrue(text:find(needle, 1, true) ~= nil, "gen_client_sids.py documents " .. needle)
	end
end
