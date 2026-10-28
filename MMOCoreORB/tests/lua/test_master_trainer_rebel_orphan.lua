-- Rebel master trainer, Q-1 option A: the orphan quest destroy_corellia_rebel_master is gone and Arkon's surrender reset works without it.
-- Spec: .claude/work/space-master-trainer-rebel/01-spec.md (AC-11; Migration "Orphan removal"; Migration of tests T6-T9).
--
-- The orphan was never started by any code path and is not in the client quest list, so there is no player data to migrate; the checks are that
-- nothing names it any more and that Arkon's reset still resets and clears exactly its thirteen story quests and its nine keys.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_rebel_data")
local D = require("havoc_tier4_data")

M.load()

local HSP_FILE = "screenplays/space/squadrons/HavocSquadronScreenplay.lua"

local function readFile(path)
	local f = io.open(path, "r")

	if f == nil then
		return nil
	end

	local text = f:read("a")

	f:close()
	return text
end

TestMasterTrainerRebelOrphan = {}

function TestMasterTrainerRebelOrphan:setUp() H.reset() end

-- AC-11
function TestMasterTrainerRebelOrphan:test_the_orphan_quest_and_its_constant_are_gone_and_not_registered()
	lu.assertNotNil(rawget(_G, "HavocSquadronScreenplay"), "HavocSquadronScreenplay is loaded. Load problems: " .. M.problems())
	lu.assertNil(rawget(_G, "destroy_corellia_rebel_master"), "global destroy_corellia_rebel_master")
	lu.assertNil(H.registered("destroy_corellia_rebel_master"), "registerScreenPlay(destroy_corellia_rebel_master)")
	lu.assertNil(HavocSquadronScreenplay.TIER4_QUEST_STRING_MASTER, "HavocSquadronScreenplay.TIER4_QUEST_STRING_MASTER")
end

-- AC-11: nothing in the file names the orphan any more
function TestMasterTrainerRebelOrphan:test_the_havoc_file_no_longer_names_the_orphan_anywhere()
	local text = readFile(H.SCRIPTS .. HSP_FILE)

	lu.assertNotNil(text, "bin/scripts/" .. HSP_FILE)
	lu.assertNil(text:find("corellia_rebel_master", 1, true), "HavocSquadronScreenplay.lua still names corellia_rebel_master")
	lu.assertNil(text:find("TIER4_QUEST_STRING_MASTER", 1, true), "HavocSquadronScreenplay.lua still names TIER4_QUEST_STRING_MASTER")
	lu.assertNil(text:find("Master Mission: Destroy", 1, true), "HavocSquadronScreenplay.lua still has the orphan's comment")
end

-- AC-11: Arkon's reset runs without error and resets and clears exactly what it did before, minus the orphan
function TestMasterTrainerRebelOrphan:test_arkons_reset_resets_and_clears_exactly_the_thirteen_story_quests_and_nothing_of_the_orphan()
	local resets = {}

	for _, key in ipairs(D.QUEST_KEYS) do
		local q = D.QUEST[key]

		if q[1] ~= "escort_duty" and q[1] ~= "rescue_duty" and q[1] ~= "recovery_duty" and q[1] ~= "destroy_duty" then
			resets[D.global(key)] = H.spyOn(M.quest(D.global(key)), "resetQuest")
		end
	end

	local clears = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = M.pilot({ squadron = "havoc" })
	local ok, err = pcall(HavocSquadronScreenplay.resetArkonQuests, HavocSquadronScreenplay, player)

	lu.assertTrue(ok, "resetArkonQuests raised: " .. tostring(err))

	local n = 0

	for global, calls in pairs(resets) do
		n = n + 1
		lu.assertEquals(#calls, 1, global .. ": resetQuest calls")
	end

	lu.assertEquals(n, 13, "story quests Arkon's reset resets")

	local cleared = {}

	for _, c in ipairs(clears) do
		cleared[#cleared + 1] = c.args[2] .. "/" .. c.args[3] .. "/" .. tostring(c.args[4])
	end

	table.sort(cleared)

	local want = {}

	for _, key in ipairs({ "m1", "m1a", "m1b", "m2", "m2a", "m2b", "m3", "m3a", "m3b", "m4", "m4a", "m4b", "m4c" }) do
		want[#want + 1] = D.QUEST[key][1] .. "/" .. D.QUEST[key][2] .. "/false"
	end

	table.sort(want)
	lu.assertEquals(cleared, want, "journal entries Arkon's reset clears (silently)")
end

-- AC-11: the nine keys Arkon's reset removes are still removed
function TestMasterTrainerRebelOrphan:test_arkons_reset_still_removes_its_nine_keys()
	local player = M.pilot({ squadron = "havoc" })
	local keys = { "HavocSquadronScreenplay:StartedArkon" }

	for n = 1, 4 do
		keys[#keys + 1] = D.MISSION[n].statusName .. ":attempted"
		keys[#keys + 1] = D.MISSION[n].statusName .. ":reward"
	end

	for _, k in ipairs(keys) do
		H.setQuestStatus(player, k, "1")
	end

	HavocSquadronScreenplay:resetArkonQuests(player)

	for _, k in ipairs(keys) do
		lu.assertNil(H.getQuestStatus(player, k), k .. " after Arkon's reset")
	end
end

-- AC-11: the client has no entry for the orphan, so no journal entry of it could ever have been shown (the reason no migration is needed)
function TestMasterTrainerRebelOrphan:test_the_orphan_was_never_in_the_client_quest_list()
	local text = readFile(H.FIXTURES .. "misc/quest_crc_string_table.names")

	lu.assertNotNil(text, "fixtures/misc/quest_crc_string_table.names")
	lu.assertNil(text:find("corellia_rebel_master", 1, true), "client quest list names corellia_rebel_master")
end
