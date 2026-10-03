-- The duty-complete typos in Turoldine and Rikkh (AC-8, I-5) and the Havoc quest constants (AC-9, I-1).
-- Spec: .claude/work/space-trainer-fixes/01-spec.md

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local function firstScreen(tr, player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], tr.label .. ": the trainer shows no first screen")

	return transcript[1].id
end

---------------------------------------------------------------------------------------------
-- AC-8: a running duty keeps Turoldine and Rikkh on "on_mission"
---------------------------------------------------------------------------------------------

TestTrainerDutyTypos = {}

function TestTrainerDutyTypos:setUp()
	H.reset()
end

-- AC-8
function TestTrainerDutyTypos:test_turoldine_shows_on_mission_while_the_destroy_duty_is_running()
	local tr = T.TRAINERS.turoldine
	local player = T.player(tr, 1, { active = { "destroy_duty_corellia_privateer_tier4_1" } })

	lu.assertEquals(firstScreen(tr, player), "on_mission", "Turoldine with only destroy_duty_corellia_privateer_tier4_1 active: first screen")
end

-- AC-8 (the other three Turoldine duties already work)
function TestTrainerDutyTypos:test_turoldine_shows_on_mission_while_any_other_duty_is_running()
	local tr = T.TRAINERS.turoldine
	local duties = { "escort_duty_corellia_privateer_tier4_1", "rescue_duty_corellia_privateer_tier4_1", "recovery_duty_corellia_privateer_tier4_1" }

	for _, duty in ipairs(duties) do
		H.reset()

		local player = T.player(tr, 1, { active = { duty } })

		lu.assertEquals(firstScreen(tr, player), "on_mission", "Turoldine with only " .. duty .. " active: first screen")
	end
end

-- AC-8
function TestTrainerDutyTypos:test_rikkh_shows_on_mission_while_the_recovery_duty_is_running()
	local tr = T.TRAINERS.rikkh
	local player = T.player(tr, 1, { active = { "recovery_duty_corellia_privateer_12" } })

	lu.assertEquals(firstScreen(tr, player), "on_mission", "Rikkh with only recovery_duty_corellia_privateer_12 active: first screen")
end

-- AC-8 (the other three Rikkh duties already work)
function TestTrainerDutyTypos:test_rikkh_shows_on_mission_while_any_other_duty_is_running()
	local tr = T.TRAINERS.rikkh
	local duties = { "destroy_duty_corellia_privateer_9", "escort_duty_corellia_privateer_10", "destroy_duty_corellia_privateer_11" }

	for _, duty in ipairs(duties) do
		H.reset()

		local player = T.player(tr, 1, { active = { duty } })

		lu.assertEquals(firstScreen(tr, player), "on_mission", "Rikkh with only " .. duty .. " active: first screen")
	end
end

-- AC-8 (a finished duty is not "running")
function TestTrainerDutyTypos:test_turoldine_does_not_show_on_mission_for_a_finished_duty()
	local tr = T.TRAINERS.turoldine
	local player = T.player(tr, 1, { complete = { "destroy_duty_corellia_privateer_tier4_1" } })

	lu.assertNotEquals(firstScreen(tr, player), "on_mission", "Turoldine with a completed destroy duty: first screen")
end

---------------------------------------------------------------------------------------------
-- I-5: no "...Complete" name is assigned from isSpaceQuestActive in the conversation handlers
---------------------------------------------------------------------------------------------

-- Every statement `<name> = <expression>` in the file (an expression continues on lines that start with or / and / ")")
local function assignments(path)
	local f = assert(io.open(path, "r"), "cannot read " .. path)
	local out = {}
	local current

	local function flush()
		if current then
			out[#out + 1] = current
			current = nil
		end
	end

	local lineNo = 0

	for line in f:lines() do
		lineNo = lineNo + 1

		local trimmed = line:match("^%s*(.-)%s*$")

		if trimmed:sub(1, 2) == "--" or trimmed == "" then
			-- comment or blank: ignore
		elseif current and (trimmed:match("^or%s") or trimmed:match("^and%s") or trimmed:sub(1, 1) == ")") then
			current.text = current.text .. " " .. trimmed
		else
			flush()
			current = { line = lineNo, text = trimmed }
		end
	end

	flush()
	f:close()

	return out
end

local function handlerFiles()
	local p = assert(io.popen('find "' .. H.SCRIPTS .. 'screenplays/space/conversations" -name "*.lua" | sort'))
	local files = {}

	for path in p:lines() do
		files[#files + 1] = path
	end

	p:close()

	return files
end

-- I-5
function TestTrainerDutyTypos:test_no_complete_flag_is_assigned_from_is_space_quest_active()
	local violations = {}
	local files = handlerFiles()

	lu.assertTrue(#files >= 10, "found the conversation handlers to scan (" .. #files .. " files)")

	for _, path in ipairs(files) do
		for _, stmt in ipairs(assignments(path)) do
			local target, rhs = stmt.text:match("^local%s+([%w_]+)%s*=%s*(.*)$")

			if target == nil then
				target, rhs = stmt.text:match("^([%w_%.:]+)%s*=[^=]%s*(.*)$")
			end

			if target and rhs and target:find("Complete", 1, true) and rhs:find("isSpaceQuestActive", 1, true) then
				violations[#violations + 1] = path:match("([^/]+)$") .. ":" .. stmt.line .. " " .. target
			end
		end
	end

	lu.assertEquals(violations, {}, "'...Complete' names assigned from isSpaceQuestActive")
end

---------------------------------------------------------------------------------------------
-- AC-9: the Havoc constants name real quests
---------------------------------------------------------------------------------------------

TestSquadronQuestConstants = {}

function TestSquadronQuestConstants:setUp()
	H.reset()
end

-- Every *QUEST_STRING* constant of a squadron table that is a {type, name} pair
local function constantsOf(squadron)
	local names = {}

	for key, value in pairs(squadron) do
		if type(key) == "string" and key:find("QUEST_STRING", 1, true) and type(value) == "table" and value.type ~= nil and value.name ~= nil then
			names[#names + 1] = key
		end
	end

	table.sort(names)
	return names
end

local function constantProblems(squadronName)
	local squadron = H.expectGlobal(squadronName, "squadron screenplay")
	local problems = {}
	local names = constantsOf(squadron)

	for _, key in ipairs(names) do
		local c = squadron[key]
		local q = rawget(_G, c.type .. "_" .. c.name)

		if q == nil then
			problems[#problems + 1] = key .. ": no quest global " .. c.type .. "_" .. c.name
		elseif q.questType ~= c.type or q.questName ~= c.name then
			problems[#problems + 1] = key .. ": global " .. c.type .. "_" .. c.name .. " is " .. tostring(q.questType) .. "/" .. tostring(q.questName)
		end
	end

	return problems, #names
end

-- I-1
function TestSquadronQuestConstants:test_every_havoc_quest_constant_names_an_existing_quest()
	local problems, count = constantProblems("HavocSquadronScreenplay")

	lu.assertTrue(count > 40, "scanned the Havoc constants (" .. count .. ")")
	lu.assertEquals(problems, {}, "HavocSquadronScreenplay constants")
end

-- I-1
function TestSquadronQuestConstants:test_every_corsec_quest_constant_names_an_existing_quest()
	local problems, count = constantProblems("CorsecSquadronScreenplay")

	lu.assertTrue(count > 40, "scanned the CorSec constants (" .. count .. ")")
	lu.assertEquals(problems, {}, "CorsecSquadronScreenplay constants")
end

-- I-1
function TestSquadronQuestConstants:test_every_rsf_quest_constant_names_an_existing_quest()
	local problems, count = constantProblems("RsfSquadronScreenplay")

	lu.assertTrue(count > 40, "scanned the RSF constants (" .. count .. ")")
	lu.assertEquals(problems, {}, "RsfSquadronScreenplay constants")
end

-- AC-9
function TestSquadronQuestConstants:test_the_three_fixed_havoc_constants_name_the_quests_that_run()
	lu.assertEquals(HavocSquadronScreenplay.TIER3_QUEST_STRING_1_SIDE1, { type = "patrol", name = "corellia_rebel_tier3_1_A" }, "TIER3_QUEST_STRING_1_SIDE1")
	lu.assertEquals(HavocSquadronScreenplay.TIER3_QUEST_STRING_2_SIDE1, { type = "delivery", name = "corellia_rebel_tier3_2_a" }, "TIER3_QUEST_STRING_2_SIDE1")
	lu.assertEquals(HavocSquadronScreenplay.TIER3_QUEST_STRING_4_SIDE1, { type = "patrol", name = "corellia_rebel_tier3_4_a" }, "TIER3_QUEST_STRING_4_SIDE1")
end

-- AC-9: resetQuest is spied, so the entries can only be cleared through the constants
function TestSquadronQuestConstants:test_reset_aqzow_quests_clears_the_three_fixed_entries_through_the_constants()
	local entries = {
		{ "patrol", "corellia_rebel_tier3_1_A" },
		{ "delivery", "corellia_rebel_tier3_2_a" },
		{ "patrol", "corellia_rebel_tier3_4_a" },
	}

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "resetQuest")
	end

	local completed = {}

	for _, e in ipairs(entries) do
		completed[#completed + 1] = H.questCrc(e[1], e[2])
	end

	local player = H.newPlayer({ pilot = "rebel", completedQuests = completed })

	HavocSquadronScreenplay:resetAqzowQuests(player)

	for _, e in ipairs(entries) do
		lu.assertFalse(SpaceHelpers:isSpaceQuestComplete(player, e[1], e[2]), e[1] .. "/" .. e[2] .. " still complete after resetAqzowQuests")
		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, e[1], e[2]), e[1] .. "/" .. e[2] .. " still active after resetAqzowQuests")
	end
end

-- AC-9: the same for every member of the four Aqzow chains
function TestSquadronQuestConstants:test_reset_aqzow_quests_clears_every_aqzow_chain_member_through_the_constants()
	local tr = T.TRAINERS.aqzow

	for _, name in ipairs(H.questGlobals()) do
		H.spyOn(rawget(_G, name), "resetQuest")
	end

	local player = H.newPlayer({ pilot = "rebel" })
	local members = {}

	for n = 1, 4 do
		for _, g in ipairs(tr.chains[n]) do
			T.setState(player, g, "complete")
			members[#members + 1] = g
		end
	end

	HavocSquadronScreenplay:resetAqzowQuests(player)

	local left = {}

	for _, g in ipairs(members) do
		if T.state(player, g) ~= "none" then
			left[#left + 1] = g
		end
	end

	lu.assertEquals(left, {}, "Aqzow chain members still in the journal after resetAqzowQuests")
end
