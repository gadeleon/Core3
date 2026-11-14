-- SpaceQuestLogic:isRunInProgress of every quest type: SWG's in_progress object variable, as each type's leave-zone condition.
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-4, C4, D-4, D-7, D-8, I-5)

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local PSD = require("psd_scenario")

PSD.load()

local function needHook(q)
	lu.assertEquals(type(q.isRunInProgress), "function", q.className .. ": expected SpaceQuestLogic:isRunInProgress (C3/C4)")
end

local function inProgress(q, player)
	needHook(q)

	return q:isRunInProgress(player) and true or false
end

TestRunInProgress = {}

function TestRunInProgress:setUp() H.reset() end
function TestRunInProgress:tearDown()
	PSD.dropDutyPatrol()
	AC.tearDown()
end

-- One test per quest type: every registered quest of the type, the states just before and just after the C4 condition
local bases = {}

for base in pairs(PSD.CLASSES) do
	bases[#bases + 1] = base
end

table.sort(bases)

for _, base in ipairs(bases) do
	local row = PSD.CLASSES[base]

	-- AC-4
	TestRunInProgress["test_" .. base .. "_run_check_is_false_before_and_" .. (row.expect and "true" or "false") .. "_after_its_condition"] = function()
		local list = PSD.byClass()[base]
		local problems = {}

		needHook(SpaceQuestLogic)
		needHook(_G[base])

		if base == "SpaceDutyPatrolScreenplay" then
			-- unused in every squadron table: a test instance (SWG QL/patrol_duty:129-132 SCRIPT_OVERRIDE, D-8)
			local q = PSD.dutyPatrol()

			list = { { global = q.className, quest = q } }
		else
			lu.assertTrue(#list > 0, base .. ": quests of the type are registered")
		end

		for _, entry in ipairs(list) do
			local q = entry.quest
			local build = base == "SpaceDutyPatrolScreenplay" and PSD.acceptedDirect or PSD.accepted

			local function fresh()
				return build(q)
			end

			local ok, err = pcall(function()
				local player = fresh()

				if inProgress(q, player) then
					problems[#problems + 1] = entry.global .. ": in progress right after the quest was taken, outside the quest zone"
				end

				local names = {}

				for name in pairs(row.before) do names[#names + 1] = name end

				table.sort(names)

				for _, name in ipairs(names) do
					player = fresh()
					row.before[name](q, player)

					if inProgress(q, player) then
						problems[#problems + 1] = entry.global .. ": in progress in the state '" .. name .. "'"
					end
				end

				player = fresh()
				PSD.inProgress(q, player)

				if inProgress(q, player) ~= row.expect then
					problems[#problems + 1] = entry.global .. ": isRunInProgress is " .. tostring(not row.expect) .. " after the condition, expected " .. tostring(row.expect)
				end
			end)

			if not ok then
				problems[#problems + 1] = entry.global .. ": raised " .. tostring(err)
			end
		end

		lu.assertEquals(PSD.summary(problems), {}, base .. ": quests with a wrong run state")
	end
end

-- AC-4 (no state): a player who never took the quest is not in progress (no journal entry, no keys)
function TestRunInProgress:test_a_player_who_never_took_the_quest_is_not_in_progress()
	for _, global in ipairs({ "patrol_corellia_privateer_1", "survival_corellia_rebel_tier4_1", "delivery_corellia_rebel_tier3_3", "destroy_duty_corellia_rebel_6" }) do
		local q = H.expectGlobal(global, "quest table")

		lu.assertFalse(inProgress(q, H.newPlayer({ zone = q.questZone })), global .. ": a pilot who never took the quest")
	end
end

---------------------------------------------------------------------------------------------
-- The same condition reached through the real flow of the 16 quest types (abort_cleanup_scenario builders)
---------------------------------------------------------------------------------------------

for _, entry in ipairs(AC.TYPES) do
	-- AC-4
	TestRunInProgress["test_a_running_" .. entry.type .. "_is_in_progress_after_its_real_setup"] = function()
		local run = AC.build(entry.type)

		lu.assertTrue(inProgress(run.q, run.player), entry.name .. ": isRunInProgress after the type's own setup or arrival")
	end
end

-- AC-4 (destroy): a quest that is set up but has no kill yet is not in progress; the first kill starts it (task 1 active)
function TestRunInProgress:test_a_destroy_is_in_progress_from_its_first_kill_only()
	local q = H.expectGlobal("destroy_corellia_privateer_2", "destroy quest table")
	local player = AC.started(q)

	H.zoneSwitch(player, q.questZone)
	H.advance(0)
	lu.assertFalse(inProgress(q, player), "in the quest zone, before the first kill")

	local agent = H.worldAgent({ shipName = q.shipTypes[1], zone = q.questZone })

	H.fireObservers(DESTROYEDSHIP, player, agent)
	lu.assertTrue(inProgress(q, player), "after the first kill")
end

-- AC-4 (patrol): in progress once the first nav point is reached (task 2), not when the quest is taken or the zone entered
function TestRunInProgress:test_a_patrol_is_in_progress_from_its_first_point_only()
	local q = H.expectGlobal("patrol_corellia_privateer_1", "patrol quest table")
	local player = AC.started(q)

	lu.assertFalse(inProgress(q, player), "in the quest zone, before any point")

	H.enterArea(AC.areaByNumber(q, 1), player.rootParent)
	H.advance(500)
	lu.assertTrue(inProgress(q, player), "after the first point")
end

-- AC-4: a quest started outside its zone is not in progress, for every type's flow builder that supports a start elsewhere
function TestRunInProgress:test_a_quest_started_outside_its_zone_is_not_in_progress()
	for _, entry in ipairs(AC.TYPES) do
		local q = H.expectGlobal(entry.name, entry.type .. " quest table")
		local player = AC.started(q, { zone = PSD.zoneOtherThan(q) })

		lu.assertFalse(inProgress(q, player), entry.name .. ": started outside the quest zone")
	end
end
