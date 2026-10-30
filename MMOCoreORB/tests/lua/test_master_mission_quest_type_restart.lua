-- Persistent master mission quest type: a server restart, login in Kessel, and the negative control of the restart simulation.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-6; Findings 2 and 3; Test strategy hints, harness additions 3).
--
-- H.simulateRestart() keeps players, ghosts (journal, screenplay data) and zones, and removes what a restart loses: observers not created with a
-- non-zero integer, shared memory, pending events.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local function progress(n, k) return "Kills: " .. n .. " of " .. k end

-- M1 running in Kessel with `saved` kills, then the pilot lands (the usual state of a logout)
local function withSavedKills(case, global, saved)
	local q, player = S.started(case, global)
	local list = case.M.shipList(global)

	S.enter(player)

	for i = 1, saved do S.kill(player, S.cycle(list, i)) end

	return q, player
end

TestMasterMissionRestart = {}

function TestMasterMissionRestart:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	local global = case.ONE

	-- AC-6
	TestMasterMissionRestart["test_a_restart_keeps_the_three_observers_and_the_saved_count_of_" .. global] = function()
		local q, player = withSavedKills(case, global, 12)

		-- the pilot launched into Kessel and the server goes down before the reminder is shown
		S.goTo(player, S.GROUND)
		H.zoneSwitch(player, S.ZONE, { ship = true })
		lu.assertTrue(#H.pendingEvents() > 0, global .. ": precondition: the reminder is pending")

		H.simulateRestart()

		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after the restart")
		lu.assertEquals(H.Engine.sharedMemoryKeys(), {}, global .. ": shared memory is gone")
		lu.assertEquals(#H.pendingEvents(), 0, global .. ": pending events are gone")
		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "12", global .. ": the saved count")
		lu.assertTrue(S.isActive(player, q), global .. ": the journal entry")
	end

	-- AC-6
	TestMasterMissionRestart["test_after_a_restart_a_launch_into_kessel_shows_the_saved_count_and_the_rest_completes_" .. global] = function()
		local q, player = withSavedKills(case, global, 12)
		local list = case.M.shipList(global)

		S.goTo(player, S.GROUND) -- logout puts the pilot on the ground
		H.simulateRestart()

		local mark = S.messageMark(player)

		S.enter(player, "launch after the restart")
		lu.assertEquals(S.updates(player, mark), { progress(12, 30) }, global .. ": the reminder after the restart")

		for i = 13, 29 do S.kill(player, S.cycle(list, i)) end

		lu.assertFalse(S.isComplete(player, q), global .. ": 29 kills in all are not enough")
		S.kill(player, S.cycle(list, 30))
		lu.assertTrue(S.isComplete(player, q), global .. ": 18 kills after the restart complete it")
		lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. ": no observer left after the completion")
	end

	-- AC-6: kills count after a restart even before any zone event (the kill observer lives with the quest)
	TestMasterMissionRestart["test_after_a_restart_kills_count_before_any_zone_event_for_" .. global] = function()
		local q, player = withSavedKills(case, global, 3)
		local list = case.M.shipList(global)

		H.simulateRestart()
		S.kill(player, S.cycle(list, 4))
		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "4", global .. ": the kill after the restart")
	end

	-- AC-6: the crash case, logged in inside Kessel
	TestMasterMissionRestart["test_login_inside_kessel_after_a_restart_shows_the_saved_count_and_kills_keep_counting_for_" .. global] = function()
		local q, player = withSavedKills(case, global, 12)
		local list = case.M.shipList(global)

		H.simulateRestart()
		player.zone = S.ZONE -- the saved terrain of a crashed pilot

		local mark = S.messageMark(player)

		H.fireObservers(LOGGEDIN, player)
		S.pump(6000, "login in Kessel")
		lu.assertEquals(S.updates(player, mark), { progress(12, 30) }, global .. ": the reminder after logging in inside Kessel")
		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after the login")
		lu.assertTrue(S.taskActive(player, q, 1), global .. ": task 1 active")

		S.kill(player, S.cycle(list, 13))
		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "13", global .. ": kills keep counting")
	end

	-- AC-6: login on the ground
	TestMasterMissionRestart["test_login_on_the_ground_sends_no_reminder_and_keeps_the_quest_for_" .. global] = function()
		local q, player = withSavedKills(case, global, 12)

		S.goTo(player, S.GROUND)
		H.simulateRestart()

		local mark = S.messageMark(player)

		H.fireObservers(LOGGEDIN, player)
		S.pump(10000, "login on the ground")
		lu.assertEquals(S.updates(player, mark), {}, global .. ": no reminder on the ground")
		lu.assertTrue(S.isActive(player, q), global .. ": still active")
		lu.assertEquals(S.count(player, global), 12, global .. ": saved count")
		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers")
	end

	-- AC-6: a login does not duplicate anything
	TestMasterMissionRestart["test_repeated_logins_keep_one_observer_each_for_" .. global] = function()
		local q, player = withSavedKills(case, global, 2)

		for _ = 1, 3 do
			H.fireObservers(LOGGEDIN, player)
			S.pump(6000, "login")
		end

		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after three logins")
	end
end

-- AC-6: M2 across a restart
for _, case in ipairs(S.CASES) do
	local global = case.TWO

	TestMasterMissionRestart["test_after_a_restart_the_corvette_kill_still_completes_" .. global] = function()
		local q, player = S.started(case, global)

		S.enter(player)
		S.goTo(player, S.GROUND)
		H.simulateRestart()

		local mark = S.messageMark(player)

		S.enter(player)
		lu.assertEquals(S.updates(player, mark), { progress(0, 1) }, global .. ": the reminder after the restart")
		S.kill(player, case.M.shipList(global)[1])
		lu.assertTrue(S.isComplete(player, q), global .. ": complete")
	end
end

-- AC-6 negative control: the simulation catches the old bug (an observer created with `true` is transient on the server)
function TestMasterMissionRestart:test_an_observer_created_with_true_does_not_survive_the_simulated_restart()
	local case = S.CASES[1]
	local q, player = S.started(case, case.ONE)

	createObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "notifyDestroyedShip", player, true)
	createObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "enteredZone", player)
	createObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "other", player, false)
	createObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "kept", player, 1)

	H.simulateRestart()

	lu.assertFalse(H.hasObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "notifyDestroyedShip", player), "created with true: gone")
	lu.assertFalse(H.hasObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "enteredZone", player), "created without the argument: gone")
	lu.assertFalse(H.hasObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "other", player), "created with false: gone")
	lu.assertTrue(H.hasObserver(DESTROYEDSHIP, "SpaceDestroyScreenplay", "kept", player), "created with the integer 1: kept")
end

-- AC-6 negative control, the real thing: the stock destroy quest's kill observer is lost in a restart, the master quest's is not
function TestMasterMissionRestart:test_the_stock_destroy_quests_kill_observer_is_lost_in_a_restart_but_the_master_quests_is_kept()
	local case = S.CASES[1]
	local stock = case.M.quest("destroy_corellia_imperial_2")

	H.reset()

	local player = S.pilot(case, { zone = stock.questZone })

	stock:startQuest(player, "")
	H.advance(0)
	H.zoneSwitch(player, stock.questZone)
	S.pump(500, "zone entry")
	lu.assertTrue(H.hasObserver(DESTROYEDSHIP, "destroy_corellia_imperial_2", "notifyDestroyedShip", player), "precondition: the stock quest armed its kill observer")

	local master, other = S.started(case, case.ONE)

	S.enter(other)
	H.simulateRestart()

	lu.assertFalse(H.hasObserver(DESTROYEDSHIP, "destroy_corellia_imperial_2", "notifyDestroyedShip", player), "stock destroy quest: the kill observer (created with true) is lost")
	lu.assertEquals(S.observerProblems(other, case.ONE), {}, "master quest: all three observers survive")
end
