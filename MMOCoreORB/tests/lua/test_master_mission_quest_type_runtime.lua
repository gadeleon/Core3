-- Persistent master mission quest type: start, arrival, counting, never failing (the four master missions through the fakes).
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-3, AC-4, AC-5; I-2 to I-7; Content contract 1; AC-10 "completion pays nothing").
--
-- Driven like the older runtime tests: the real startQuest, H.zoneSwitch, H.fireObservers(DESTROYEDSHIP, ...) and the event clock.
-- Ship names come from the SWG .tab fixtures through the trainer data modules.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local function progress(n, k) return "Kills: " .. n .. " of " .. k end

local function killsOf(case, global) return global == case.ONE and 30 or 1 end

TestMasterMissionRuntime = {}

function TestMasterMissionRuntime:setUp() H.reset() end
function TestMasterMissionRuntime:tearDown() S.unwrap() end

for _, case in ipairs(S.CASES) do
	for _, global in ipairs({ case.ONE, case.TWO }) do
		local K = killsOf(case, global)
		local tag = "_" .. global

		-- AC-3
		TestMasterMissionRuntime["test_starting" .. tag .. "_activates_it_with_three_persistent_observers_no_count_and_no_waypoint"] = function()
			local q, player = S.started(case, global)

			lu.assertTrue(S.isActive(player, q), global .. ": active after startQuest")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after startQuest")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": saved count after startQuest")
			lu.assertEquals(#player.ghost.waypoints, 0, global .. ": no waypoint")
			lu.assertEquals(#H.Engine.callsTo("addWaypoint"), 0, global .. ": addWaypoint calls")
		end

		-- AC-3, I-2
		TestMasterMissionRuntime["test_every_observer_" .. global .. "_creates_is_persistent_with_the_integer_one"] = function()
			local q, player = S.started(case, global)

			S.enter(player)
			S.goTo(player, "space_heavy1")
			S.goTo(player, S.ZONE)
			S.fire(player, case.M.shipList(global)[1])

			local args = S.createObserverArgs(global)

			lu.assertTrue(#args >= 3, global .. ": createObserver calls for the class: " .. #args)

			for i, a in ipairs(args) do
				lu.assertEquals(math.type(a), "integer", global .. ": createObserver call " .. i .. " persistence argument type (" .. tostring(a) .. ")")
				lu.assertEquals(a, 1, global .. ": createObserver call " .. i .. " persistence argument")
			end
		end

		-- AC-3
		TestMasterMissionRuntime["test_entering_kessel_with" .. tag .. "_completes_task_0_activates_task_1_and_sends_no_progress_message_or_waypoint"] = function()
			local q, player = S.started(case, global)

			lu.assertTrue(S.taskActive(player, q, 0), global .. ": task 0 active before the first entry")
			H.zoneSwitch(player, S.ZONE, { ship = true })
			H.advance(0)

			lu.assertTrue(S.taskDone(player, q, 0), global .. ": task 0 complete after entering " .. S.ZONE)
			lu.assertTrue(S.taskActive(player, q, 1), global .. ": task 1 active after entering " .. S.ZONE)
			lu.assertEquals(#player.ghost.waypoints, 0, global .. ": no waypoint on arrival")

			S.pump(10000, "after the entry")

			for _, id in ipairs(S.messageIds(player)) do
				lu.assertNotEquals(id, "@space/quest:quest_in_progress", global .. ": the 'must complete before leaving this sector' message is not sent (D-5)")
			end

			lu.assertEquals(S.effects(player, "clienteffect/ui_quest_waypoint_target.cef"), 1, global .. ": the arrival effect plays once")
		end

		-- AC-3: the reminder comes REMINDER_DELAY (5 s) after the entry, not before
		TestMasterMissionRuntime["test_the_saved_count_is_shown_five_seconds_after_entering_kessel_with" .. tag] = function()
			local q, player = S.started(case, global)

			H.zoneSwitch(player, S.ZONE, { ship = true })
			S.pump(4999, "before the delay")
			lu.assertEquals(S.updates(player), {}, global .. ": nothing is shown before 5 s")
			S.pump(1, "at the delay")
			lu.assertEquals(S.updates(player), { progress(0, K) }, global .. ": the reminder at 5 s")
		end

		-- AC-3: arrival is idempotent
		TestMasterMissionRuntime["test_a_second_kessel_entry_with" .. tag .. "_repeats_neither_the_arrival_effect_nor_the_task_change"] = function()
			local q, player = S.started(case, global)

			S.enter(player)
			S.goTo(player, "space_heavy1")
			S.enter(player)
			lu.assertEquals(S.effects(player, "clienteffect/ui_quest_waypoint_target.cef"), 1, global .. ": the arrival effect after two entries")
			lu.assertEquals(S.updates(player), { progress(0, K), progress(0, K) }, global .. ": one reminder per entry")
			lu.assertTrue(S.taskActive(player, q, 1), global .. ": task 1 still active")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": one observer each after two entries")
		end

		-- AC-3: starting a running quest changes nothing
		TestMasterMissionRuntime["test_starting_the_running" .. tag .. "_again_changes_nothing"] = function()
			local q, player = S.started(case, global)

			S.enter(player)

			if global == case.ONE then
				S.kill(player, case.M.shipList(global)[1])
				S.kill(player, case.M.shipList(global)[2])
			end

			local before = #H.Engine.callsTo("createObserver")
			local count = readScreenPlayData(player, global, "killCount")

			q:startQuest(player, "")
			H.advance(0)

			lu.assertEquals(#H.Engine.callsTo("createObserver"), before, global .. ": createObserver calls after a second startQuest")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), count, global .. ": saved count after a second startQuest")
			lu.assertTrue(S.isActive(player, q), global .. ": still active")
		end

		-- AC-4, AC-5 (b): a kill outside Kessel, or of an unlisted ship, changes nothing and sends nothing
		TestMasterMissionRuntime["test_unlisted_ships_and_kills_outside_kessel_change_nothing_for" .. tag] = function()
			local q, player = S.started(case, global)

			S.enter(player)

			local mark = S.messageMark(player)
			local listed = case.M.shipList(global)[1]

			S.kill(player, S.unlistedFighter(case))
			S.kill(player, S.unlistedCorvette(case))

			if global == case.ONE then
				S.kill(player, case.M.shipList(case.TWO)[1]) -- the corvette is not on the fighter list
			else
				S.kill(player, case.M.shipList(case.ONE)[1]) -- the fighters are not on the corvette list
			end

			S.goTo(player, "space_heavy1")
			mark = S.messageMark(player)
			S.kill(player, listed)
			S.goTo(player, S.GROUND)
			S.kill(player, listed)

			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": saved count")
			lu.assertEquals(S.updates(player, mark), {}, global .. ": no update for unlisted kills or kills outside Kessel")
			lu.assertTrue(S.isActive(player, q), global .. ": still active")
			lu.assertFalse(S.isComplete(player, q), global .. ": not complete")

			-- control: the same listed ship does count in Kessel
			S.enter(player)
			mark = S.messageMark(player)
			S.kill(player, listed)

			if global == case.ONE then
				lu.assertEquals(readScreenPlayData(player, global, "killCount"), "1", global .. ": control: a listed kill in Kessel counts")
				lu.assertEquals(S.updates(player, mark), { progress(1, 30) }, global .. ": control: the kill is announced")
			else
				lu.assertTrue(S.isComplete(player, q), global .. ": control: the corvette kill in Kessel completes it")
			end
		end

		-- AC-3 / D-3: kills count without any zone event (the pilot is already in Kessel, e.g. after a crash), and the first kill arrives
		TestMasterMissionRuntime["test_a_kill_in_kessel_with_no_zone_event_counts_and_activates_task_1_for" .. tag] = function()
			local q, player = S.started(case, global, { zone = S.ZONE })

			lu.assertFalse(S.taskDone(player, q, 0), global .. ": precondition: task 0 not complete")
			S.fire(player, case.M.shipList(global)[1])
			S.pump(300, "kill")

			if K > 1 then
				lu.assertEquals(readScreenPlayData(player, global, "killCount"), "1", global .. ": saved count")
				lu.assertTrue(S.taskDone(player, q, 0), global .. ": task 0 complete after the first kill")
				lu.assertTrue(S.taskActive(player, q, 1), global .. ": task 1 active after the first kill")
			else
				lu.assertTrue(S.isComplete(player, q), global .. ": the single kill completes it")
			end
		end

		-- I-4: nothing fails it
		TestMasterMissionRuntime["test_a_direct_fail_call_leaves" .. tag .. "_active_with_its_count"] = function()
			local q, player = S.started(case, global)

			S.enter(player)

			if global == case.ONE then
				for i = 1, 5 do S.kill(player, S.cycle(case.M.shipList(global), i)) end
			end

			local count = readScreenPlayData(player, global, "killCount")

			q:failQuest(player, "true")
			S.pump(5000, "after failQuest")
			q:failQuest(player, "false")
			S.pump(5000, "after failQuest")

			lu.assertTrue(S.isActive(player, q), global .. ": still active")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), count, global .. ": saved count")
			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers")
		end

		-- AC-5, I-4: no zone change fails it or loses the count, and the admiral keeps saying the mission is on
		TestMasterMissionRuntime["test_no_zone_change_fails" .. tag .. "_or_loses_the_count_and_the_admiral_says_it_is_on"] = function()
			case.M.requireConversation(lu)

			local routes = {
				{ "another space zone", function(p) S.goTo(p, "space_heavy1") end },
				{ "a ground zone (death or landing)", function(p) S.goTo(p, S.GROUND) end },
				{ "a same-zone switch (respawn)", function(p) S.goTo(p, S.ZONE) end },
			}

			for _, route in ipairs(routes) do
				local q, player = S.started(case, global, { paid = global == case.TWO and { 1 } or nil })
				local saved = 0

				S.enter(player)

				if global == case.ONE then
					saved = 12
					for i = 1, saved do S.kill(player, S.cycle(case.M.shipList(global), i)) end
				end

				route[2](player)
				S.pump(10000, route[1])

				local label = global .. " after " .. route[1]

				lu.assertTrue(S.isActive(player, q), label .. ": active")
				lu.assertFalse(S.isComplete(player, q), label .. ": not complete")
				lu.assertEquals(S.count(player, global), saved, label .. ": saved count")
				lu.assertEquals(case.M.talk(player)[1].id, "on_master_mission", label .. ": the next talk")
				lu.assertEquals(S.eventDelays("failQuest"), {}, label .. ": nothing schedules failQuest")
				lu.assertEquals(S.observerProblems(player, global), {}, label .. ": observers")
			end
		end

		-- AC-5: coming back shows the saved count and the count continues to the end
		TestMasterMissionRuntime["test_returning_to_kessel_shows_the_saved_count_and_the_rest_completes" .. tag] = function()
			local q, player = S.started(case, global)
			local list = case.M.shipList(global)
			local saved = (global == case.ONE) and 12 or 0

			S.enter(player)

			for i = 1, saved do S.kill(player, S.cycle(list, i)) end

			S.goTo(player, "space_heavy1")
			S.goTo(player, S.GROUND)

			local mark = S.messageMark(player)

			S.enter(player)
			lu.assertEquals(S.updates(player, mark), { progress(saved, K) }, global .. ": the reminder on return")

			for i = saved + 1, K - 1 do S.kill(player, S.cycle(list, i)) end

			lu.assertFalse(S.isComplete(player, q), global .. ": " .. (K - 1) .. " kills in all are not enough")
			S.kill(player, S.cycle(list, K))
			lu.assertTrue(S.isComplete(player, q), global .. ": complete with the last kill, " .. saved .. " before the trip")
			lu.assertFalse(S.isActive(player, q), global .. ": no longer active")
		end

		-- AC-3, D-6: the reminder is re-checked when it is sent
		TestMasterMissionRuntime["test_the_reminder_is_not_sent_to_a_pilot_who_left_kessel_before_it_is_due_for" .. tag] = function()
			local q, player = S.started(case, global)

			H.zoneSwitch(player, S.ZONE, { ship = true })
			S.pump(2000, "in Kessel")
			S.goTo(player, "space_heavy1", "left before the reminder")
			S.pump(10000, "after the delay")
			lu.assertEquals(S.updates(player), {}, global .. ": no reminder outside Kessel")

			-- control: a Kessel entry that stays gets its reminder
			S.enter(player)
			lu.assertEquals(S.updates(player), { progress(0, K) }, global .. ": control: the reminder after a stay in Kessel")
		end

		-- I-3, I-5, I-6, I-7
		TestMasterMissionRuntime["test_a_long_sequence_keeps_one_observer_each_and_the_count_in_screenplay_data_only_for" .. tag] = function()
			local q, player = S.started(case, global)
			local list = case.M.shipList(global)

			for round = 1, 3 do
				S.enter(player)
				H.fireObservers(LOGGEDIN, player)
				S.pump(6000, "login reminder")

				if global == case.ONE then
					for i = 1, 3 do S.kill(player, S.cycle(list, i)) end
				end

				lu.assertEquals(S.observerProblems(player, global), {}, global .. " round " .. round .. ": observers")
				S.goTo(player, "space_heavy1")
				S.goTo(player, S.GROUND)
				q:startQuest(player, "")
			end

			for _, key in ipairs(H.Engine.sharedMemoryKeys()) do
				lu.assertNil(key:find("killCount", 1, true), global .. ": shared memory key " .. key .. " (the count is screenplay data only, I-5)")
			end

			for _, c in ipairs(H.Engine.callsTo("writeScreenPlayData")) do
				lu.assertEquals(c[2], global, global .. ": writeScreenPlayData screenplay name")
				lu.assertEquals(c[3], "killCount", global .. ": writeScreenPlayData variable")
			end

			if global == case.ONE then
				lu.assertEquals(S.count(player, global), 9, global .. ": saved count after 3 rounds of 3 kills")
			end
		end

		-- I-6, I-7: completion ends clean and completes exactly once
		TestMasterMissionRuntime["test_completing" .. tag .. "_ends_clean_and_completes_the_journal_entry_once"] = function()
			local q, player = S.started(case, global)
			local completions = S.countCompletions()
			local list = case.M.shipList(global)

			S.enter(player)

			for i = 1, K - 1 do S.kill(player, S.cycle(list, i)) end

			lu.assertEquals(#completions, 0, global .. ": nothing completed before the last kill")
			S.kill(player, S.cycle(list, K))

			lu.assertTrue(S.isComplete(player, q), global .. ": complete")
			lu.assertEquals(case.M.state(player, global), "complete", global .. ": journal state")
			lu.assertEquals(#completions, 1, global .. ": completeSpaceQuest calls")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": saved count is cleared")
			lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. ": no observer left")
			lu.assertEquals(S.effects(player, "clienteffect/ui_quest_destroyed_all.cef"), 1, global .. ": the completion effect plays once")

			for _, key in ipairs(H.Engine.sharedMemoryKeys()) do
				lu.assertNil(key:find("lastKillID", 1, true), global .. ": shared memory key " .. key .. " is left behind")
			end

			q:completeQuest(player, "true")
			S.pump(1000, "a second completeQuest")
			lu.assertEquals(#completions, 1, global .. ": a second completeQuest completes nothing")

			S.kill(player, S.cycle(list, 1))
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": a kill after completion saves nothing")
		end

		-- AC-10: completion pays nothing (the trainer handler pays)
		TestMasterMissionRuntime["test_completing" .. tag .. "_by_itself_pays_no_item_skill_or_standing"] = function()
			local q, player = S.started(case, global)
			local list = case.M.shipList(global)
			local standing = {}

			for k, v in pairs(player.ghost.factionStanding) do standing[k] = v end

			S.enter(player)

			for i = 1, K do S.kill(player, S.cycle(list, i)) end

			lu.assertTrue(S.isComplete(player, q), global .. ": complete")
			lu.assertEquals(#(case.M.itemsGiven(player)), 0, global .. ": items given into the inventory (the mission object in the datapad is not a reward)")
			lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, global .. ": awardSkill calls")
			lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, global .. ": skillManagerAwardSkill calls")
			lu.assertEquals(player.ghost.factionStanding, standing, global .. ": faction standing")
		end

		-- Content contract 1: the handlers return a number whatever they get (the server rejects anything else)
		TestMasterMissionRuntime["test_the_handlers_of" .. tag .. "_return_zero_for_nil_and_wrong_arguments"] = function()
			local q, player = S.started(case, global)

			S.enter(player)

			lu.assertEquals(type(q.onLoggedIn), "function", global .. ": onLoggedIn is defined")
			lu.assertEquals(q:enteredZone(nil, nil, getHashCode(S.ZONE)), 0, global .. ": enteredZone(nil)")
			lu.assertEquals(q:onLoggedIn(nil), 0, global .. ": onLoggedIn(nil)")
			lu.assertEquals(q:notifyDestroyedShip(player, nil), 0, global .. ": notifyDestroyedShip(player, nil)")
			lu.assertEquals(q:notifyDestroyedShip(nil, S.agent(case.M.shipList(global)[1])), 0, global .. ": notifyDestroyedShip(nil, agent)")
			lu.assertEquals(q:notifyDestroyedShip(player, player), 0, global .. ": notifyDestroyedShip(player, not a ship agent)")
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": nothing was counted")
			lu.assertTrue(S.isActive(player, q), global .. ": still active")
		end

		-- Content contract 1: a stale observer of a quest that is no longer active removes itself (returns 1) and drops its siblings
		TestMasterMissionRuntime["test_the_observers_of" .. tag .. "_remove_themselves_when_the_quest_is_not_active"] = function()
			for _, step in ipairs({
				{ "ZONESWITCHED", function(p) H.zoneSwitch(p, S.ZONE) end },
				{ "LOGGEDIN", function(p) H.fireObservers(LOGGEDIN, p) end },
				{ "DESTROYEDSHIP", function(p) S.fire(p, case.M.shipList(global)[1]) end },
			}) do
				local q, player = S.started(case, global)

				player.ghost.journalActive[H.questCrc(q.questType, q.questName)] = nil -- the entry was cleared behind the quest's back
				step[2](player)
				S.pump(1000, step[1])
				lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. " after " .. step[1] .. ": the observers of an inactive quest are gone")
				lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. " after " .. step[1] .. ": nothing counted")
			end
		end
	end
end

-- AC-4: the thirty kills of mission 1, message after message
for _, case in ipairs(S.CASES) do
	local global = case.ONE

	TestMasterMissionRuntime["test_each_listed_kill_raises_the_count_by_one_and_sends_the_new_count_for_" .. global] = function()
		local q, player = S.started(case, global)
		local list = case.M.shipList(global)

		S.enter(player)

		local mark = S.messageMark(player)

		for i = 1, 29 do
			S.kill(player, S.cycle(list, i))
			lu.assertEquals(readScreenPlayData(player, global, "killCount"), tostring(i), global .. ": saved count after kill " .. i)
			lu.assertEquals(S.updates(player, mark)[i], progress(i, 30), global .. ": update after kill " .. i)
		end

		lu.assertEquals(#S.updates(player, mark), 29, global .. ": exactly one update per kill")
		lu.assertTrue(S.isActive(player, q), global .. ": active after 29 kills")
		S.kill(player, S.cycle(list, 30))
		lu.assertEquals(S.updates(player, mark)[30], progress(30, 30), global .. ": the last kill is announced too")
		lu.assertTrue(S.isComplete(player, q), global .. ": complete after the 30th kill")
	end

	TestMasterMissionRuntime["test_every_listed_ship_name_counts_for_" .. global] = function()
		local q, player = S.started(case, global)

		S.enter(player)

		for i, name in ipairs(case.M.shipList(global)) do
			S.kill(player, name)
			lu.assertEquals(S.count(player, global), i, global .. ": count after " .. name)
		end
	end

	-- AC-4: a 31st kill before the 200 ms completion event changes nothing
	TestMasterMissionRuntime["test_a_kill_before_the_completion_event_runs_is_not_counted_for_" .. global] = function()
		local q, player = S.started(case, global)
		local completions = S.countCompletions()
		local list = case.M.shipList(global)

		S.enter(player)

		for i = 1, 29 do S.kill(player, S.cycle(list, i)) end

		local mark = S.messageMark(player)

		S.fire(player, S.cycle(list, 30)) -- the 30th: the completion is pending (200 ms)
		S.fire(player, S.cycle(list, 31)) -- the 31st, delivered before it runs
		S.fire(player, S.cycle(list, 32))

		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "30", global .. ": the count stays 30")
		lu.assertEquals(S.updates(player, mark), { progress(30, 30) }, global .. ": one update for the 30th kill only")
		S.pump(1000, "completion")
		lu.assertEquals(#completions, 1, global .. ": completed once")
		lu.assertEquals(S.effects(player, "clienteffect/ui_quest_destroyed_all.cef"), 1, global .. ": one completion effect")
		lu.assertEquals(#S.eventDelays("completeQuest"), 1, global .. ": one completeQuest event")
		lu.assertTrue(S.isComplete(player, q), global .. ": complete")
	end
end

-- AC-4: the corvette missions
for _, case in ipairs(S.CASES) do
	local global = case.TWO

	TestMasterMissionRuntime["test_one_corvette_kill_in_kessel_completes_" .. global .. "_and_one_in_space_heavy1_does_not"] = function()
		local q, player = S.started(case, global)
		local corvette = case.M.shipList(global)[1]

		S.enter(player)
		S.goTo(player, "space_heavy1")
		S.kill(player, corvette)
		lu.assertTrue(S.isActive(player, q), global .. ": still active after a corvette killed in space_heavy1")
		lu.assertFalse(S.isComplete(player, q), global .. ": not complete after a corvette killed in space_heavy1")
		S.enter(player)
		S.kill(player, corvette)
		lu.assertTrue(S.isComplete(player, q), global .. ": complete with the corvette killed in Kessel")
		lu.assertEquals(S.updates(player)[#S.updates(player)], progress(1, 1), global .. ": the kill is announced")
	end

	TestMasterMissionRuntime["test_the_fighters_do_not_complete_" .. global] = function()
		local q, player = S.started(case, global)

		S.enter(player)

		for _, name in ipairs(case.M.shipList(case.ONE)) do S.kill(player, name) end

		lu.assertFalse(S.isComplete(player, q), global .. ": the mission 1 fighters do not count for the corvette mission")
		lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": nothing saved")

		-- control: the corvette completes it
		S.kill(player, case.M.shipList(global)[1])
		lu.assertTrue(S.isComplete(player, q), global .. ": control: the corvette completes it")
	end

	-- AC-4: the corvette killed before the reminder fires: only the kill is announced
	TestMasterMissionRuntime["test_no_reminder_follows_the_completion_of_" .. global] = function()
		local q, player = S.started(case, global)

		H.zoneSwitch(player, S.ZONE, { ship = true })
		S.pump(1000, "entry")
		S.kill(player, case.M.shipList(global)[1])
		S.pump(10000, "after the delay")
		lu.assertEquals(S.updates(player), { progress(1, 1) }, global .. ": only the kill update, no 'Kills: 0 of 1' reminder")
	end
end
