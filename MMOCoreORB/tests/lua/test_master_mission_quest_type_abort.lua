-- Persistent master mission quest type: journal abort and surrender reset the count to 0; migration from the old type.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-8, AC-9; Findings 6; Migration; I-6).
--
-- A pilot takes the mission the way a player does (the admiral's accept screen runs the real startQuest). H.abortMission is the datapad abort in
-- the C++ order (abortQuest while the entry is still active, then the journal entry is cleared).

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local function progress(n, k) return "Kills: " .. n .. " of " .. k end

local function pathTo(case, screen)
	for _, p in ipairs(case.M.PATHS) do
		if p.screen == screen then
			return p.replies
		end
	end

	error("no path to " .. screen)
end

local NONE = { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }

-- A pilot who took mission `n` at the admiral and flew into Kessel; `saved` kills made (mission 2 has no way to hold a count: 0 is written directly)
local function taken(case, n, saved, o)
	local global = n == 1 and case.ONE or case.TWO
	local opts = { paid = n == 2 and { 1 } or nil }

	for k, v in pairs(o or {}) do opts[k] = v end

	case.M.requireConversation(lu)
	H.reset()

	local player = S.pilot(case, opts)

	case.M.talk(player, pathTo(case, "m" .. n .. "_accept"))
	H.advance(0)
	S.enter(player)

	local list = case.M.shipList(global)

	for i = 1, saved do S.kill(player, S.cycle(list, i)) end

	if n == 2 then
		writeScreenPlayData(player, global, "killCount", "0") -- a count the quest could hold: the abort must reset it
	end

	return S.quest(case, global), player, global
end

TestMasterMissionAbort = {}

function TestMasterMissionAbort:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	for n = 1, 2 do
		local global = n == 1 and case.ONE or case.TWO
		local failed = "m" .. n .. "_failed"

		-- AC-8
		TestMasterMissionAbort["test_a_datapad_abort_of_" .. global .. "_resets_the_count_and_drops_every_observer"] = function()
			local q, player = taken(case, n, n == 1 and 12 or 0)

			lu.assertTrue(S.isActive(player, q), global .. ": precondition: running")
			lu.assertNotEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": precondition: a saved count")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": precondition: the three persistent observers")

			H.abortMission(player, "destroy", case.names[n])
			S.pump(10000, "after the abort")

			lu.assertFalse(S.isActive(player, q), global .. ": the entry is not active")
			lu.assertFalse(S.isComplete(player, q), global .. ": an aborted quest is not complete")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": the saved count is empty")
			lu.assertEquals(S.observerCounts(player, global), NONE, global .. ": observers")
			lu.assertEquals(S.eventDelays("failQuest"), {}, global .. ": nothing schedules failQuest")

			for _, key in ipairs(H.Engine.sharedMemoryKeys()) do
				lu.assertNil(key:find("lastKillID", 1, true), global .. ": shared memory key " .. key .. " is left behind")
			end
		end

		-- AC-8
		TestMasterMissionAbort["test_after_an_abort_of_" .. global .. "_the_next_talk_opens_" .. failed] = function()
			local q, player = taken(case, n, n == 1 and 12 or 0)

			H.abortMission(player, "destroy", case.names[n])
			lu.assertEquals(case.M.talk(player)[1].id, failed, global .. ": the next talk")
		end

		-- AC-8
		TestMasterMissionAbort["test_a_retry_after_an_abort_of_" .. global .. "_starts_again_from_zero"] = function()
			local q, player = taken(case, n, n == 1 and 12 or 0)
			local list = case.M.shipList(global)
			local K = n == 1 and 30 or 1

			H.abortMission(player, "destroy", case.names[n])
			H.Engine.nextRandom = nil
			case.M.talk(player, pathTo(case, "m" .. n .. "_retry_a"))
			H.advance(0)

			lu.assertTrue(S.isActive(player, q), global .. ": active again after the retry")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": the count starts empty")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after the retry")

			S.goTo(player, S.GROUND)

			local mark = S.messageMark(player)

			S.enter(player)
			lu.assertEquals(S.updates(player, mark), { progress(0, K) }, global .. ": the reminder after the retry")

			for i = 1, K - 1 do S.kill(player, S.cycle(list, i)) end

			lu.assertFalse(S.isComplete(player, q), global .. ": " .. (K - 1) .. " kills are not enough after the retry (" .. K .. " needed)")
			S.kill(player, S.cycle(list, K))
			lu.assertTrue(S.isComplete(player, q), global .. ": complete with " .. K .. " kills after the retry")
		end
	end

	-- AC-8: the ship that gave the last kill before the abort counts again after the retry (the dedupe memory is cleared)
	TestMasterMissionAbort["test_the_last_ship_before_an_abort_counts_again_after_the_retry_for_" .. case.ONE] = function()
		local q, player = taken(case, 1, 0)
		local agent = S.agent(case.M.shipList(case.ONE)[1])

		S.fire(player, nil, agent)
		S.pump(300, "kill")
		lu.assertEquals(S.count(player, case.ONE), 1, "precondition: counted")
		H.abortMission(player, "destroy", case.names[1])
		case.M.talk(player, pathTo(case, "m1_retry_a"))
		H.advance(0)
		S.fire(player, nil, agent)
		S.pump(300, "kill")
		lu.assertEquals(S.count(player, case.ONE), 1, "the same agent counts as the first kill of the new run")
	end
end

-- AC-8: surrender (Black Epsilon for Declann, Havoc for Burke)
for _, case in ipairs(S.CASES) do
	local squadron = case.faction == "imperial" and "black_epsilon" or "havoc"

	for n = 1, 2 do
		local global = n == 1 and case.ONE or case.TWO

		TestMasterMissionAbort["test_surrendering_with_" .. global .. "_running_resets_the_count_and_drops_every_observer"] = function()
			local q, player = taken(case, n, n == 1 and 12 or 0, { squadron = squadron })

			lu.assertTrue(S.isActive(player, q), global .. ": precondition: running")
			lu.assertNotEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": precondition: a saved count")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": precondition: the three persistent observers")

			SpaceHelpers:surrenderPilot(player)
			S.pump(10000, "after the surrender")

			lu.assertEquals(case.M.state(player, global), "none", global .. ": the journal entry is cleared")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": the saved count is empty")
			lu.assertEquals(S.observerCounts(player, global), NONE, global .. ": observers")
			lu.assertEquals(S.eventDelays("failQuest"), {}, global .. ": nothing schedules failQuest")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: a mission running under the old type (SpaceDestroyScreenplay) when this ships
---------------------------------------------------------------------------------------------

-- The state the old type left: task 0 complete, only the persistent ZONESWITCHED observer, the count in shared memory, no screenplay data
local function oldTypeState(case, global)
	local q, player = S.started(case, global)

	for _, o in ipairs(S.observers()) do
		dropObserver(o[1], global, o[2], player)
	end

	createObserver(ZONESWITCHED, global, "enteredZone", player, 1)
	writeData(player.objectID .. ":" .. global .. ":killCount", 7)
	deleteScreenPlayData(player, global, "killCount")
	SpaceHelpers:completeSpaceQuestTask(player, q.questType, q.questName, 0, false)

	return q, player
end

TestMasterMissionMigration = {}

function TestMasterMissionMigration:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	local global = case.ONE

	-- AC-9
	TestMasterMissionMigration["test_the_first_kessel_entry_with_an_old_type_mission_adds_the_persistent_observers_and_shows_zero_kills_for_" .. global] = function()
		local q, player = oldTypeState(case, global)

		lu.assertEquals(S.observerCounts(player, global), { enteredZone = 1, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. ": precondition: only the old observer")

		local mark = S.messageMark(player)

		S.enter(player)

		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": the three persistent observers after the entry")
		lu.assertEquals(S.updates(player, mark), { progress(0, 30) }, global .. ": the reminder")
		lu.assertTrue(S.isActive(player, q), global .. ": still active")
	end

	-- AC-9
	TestMasterMissionMigration["test_the_next_listed_kill_after_the_migration_saves_count_one_for_" .. global] = function()
		local q, player = oldTypeState(case, global)

		S.enter(player)
		S.kill(player, case.M.shipList(global)[1])
		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "1", global .. ": the old in-memory count 7 is ignored")
	end

	-- AC-9
	TestMasterMissionMigration["test_a_first_switch_to_another_zone_leaves_the_old_type_mission_active_for_" .. global] = function()
		local q, player = oldTypeState(case, global)

		S.goTo(player, "space_heavy1")
		lu.assertTrue(S.isActive(player, q), global .. ": active after a switch to space_heavy1")
		S.goTo(player, S.GROUND)
		lu.assertTrue(S.isActive(player, q), global .. ": active after a switch to the ground")
		lu.assertEquals(S.eventDelays("failQuest"), {}, global .. ": nothing schedules failQuest")
		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": the persistent observers exist from the first switch on")
	end
end
