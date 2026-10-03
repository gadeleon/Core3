-- Inspect quest: inspecting the cargo, docking and recovering it, observer discipline and coexistence with
-- other quests on the same player (space-quest-inspect-cargo).
-- Spec: .claude/work/space-quest-inspect-cargo/01-spec.md (AC-4, AC-5, AC-9, I-6, Behavior 4-5). The engine
-- notifies are H.inspect (ShipInspectTask.cpp:75) and H.dock (ShipDockingTask.cpp:95); the work of the quest
-- runs in 0 ms events, which every test pumps with H.advance(0) (the sc:inspect / sc:dock helpers do).

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local R = require("rescue_scenario")
local D = require("delivery_scenario")
local I = require("inspect_scenario")

I.load()

local REP = I.REP

local function label(name) return "inspect/" .. name end

local function ready(name, opts) return I.fresh(name, opts):toSetup() end

-- The snapshot without the observer counts (a dock/inspect that returns 1 removes its own observer).
local function stateOnly(snap)
	local copy = {}

	for k, v in pairs(snap) do
		if k ~= "observers" and k ~= "allObservers" then
			copy[k] = v
		end
	end

	return copy
end

---------------------------------------------------------------------------------------------
-- AC-4: inspect
---------------------------------------------------------------------------------------------

TestInspectCargoFound = {}

function TestInspectCargoFound:setUp() H.reset() end

-- AC-4
function TestInspectCargoFound:test_inspecting_a_ship_with_the_quest_cargo_returns_1_and_changes_nothing_inside_the_observer()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()
		local before = sc:snapshot({ ship })

		lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": inspectedShip returns 1 for the quest cargo")
		lu.assertEquals(sc:snapshot({ ship }), before, label(name) .. ": nothing changed inside the observer")
	end
end

-- AC-4
function TestInspectCargoFound:test_the_inspect_event_sends_the_found_message_completes_task_1_and_activates_task_2()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()

		H.inspect(sc.player, ship, sc:hash())

		lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, label(name) .. ": no message before the event runs")
		lu.assertTrue(sc:taskActive(1), label(name) .. ": task 1 unchanged before the event runs")

		H.advance(0)

		local found = sc:msgs(I.MSG_FOUND)

		lu.assertEquals(#found, 1, label(name) .. ": inspect_found_cargo sent once")
		lu.assertEquals(found[1].via, "message", label(name) .. ": as a direct system message, not a quest update")
		lu.assertTrue(sc:taskComplete(1), label(name) .. ": task 1 complete")
		lu.assertTrue(sc:taskActive(2), label(name) .. ": task 2 (quest_dock) active")
		lu.assertTrue(sc:active(), label(name) .. ": the quest is still active")
		lu.assertEquals(#ship.cargoStringCalls, 0, label(name) .. ": inspecting does not take the cargo")
	end
end

-- AC-4
function TestInspectCargoFound:test_the_engine_removes_the_inspect_observer_and_keeps_the_dock_observer()
	local sc = ready(REP)

	sc:inspect(sc:target())

	lu.assertEquals(sc:observers(), { zone = 1, inspect = 0, dock = 1 }, "observers after the inspect")
end

-- AC-4
function TestInspectCargoFound:test_any_ship_carrying_the_cargo_counts_even_from_an_unlisted_spawner_or_template()
	local foreign = {
		{ "a listed ship from an unlisted spawner", { spawner = "hutt_smuggler_guard" } },
		{ "an unlisted template", { shipName = "reb_xwing_tier2" } },
		{ "a ship without a spawner key", { spawner = false } },
	}

	for _, name in ipairs(I.NAMES) do
		for _, case in ipairs(foreign) do
			local sc = ready(name)

			sc:inspect(sc:target(1, case[2]))

			lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, label(name) .. ": " .. case[1] .. ": inspect_found_cargo sent")
			lu.assertTrue(sc:taskActive(2), label(name) .. ": " .. case[1] .. ": task 2 active")
		end
	end
end

-- AC-4
function TestInspectCargoFound:test_any_other_cargo_returns_0_changes_nothing_and_the_observer_stays()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()
		local before = sc:snapshot({ ship })

		lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, getHashCode("not_the_quest_cargo")), 0, label(name) .. ": returns 0 for another cargo")
		lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, 0), 0, label(name) .. ": returns 0 for the empty hash 0")

		H.inspect(sc.player, ship, getHashCode("not_the_quest_cargo"))
		H.advance(0)

		lu.assertEquals(sc:snapshot({ ship }), before, label(name) .. ": nothing changed, the observer stays")
		lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, label(name) .. ": no found message")
	end
end

-- AC-4
function TestInspectCargoFound:test_a_nil_target_returns_0_and_changes_nothing()
	local sc = ready(REP)
	local before = sc:snapshot()

	lu.assertEquals(sc.quest:inspectedShip(sc.player, nil, sc:hash()), 0, "returns 0")

	H.inspect(sc.player, nil, sc:hash())
	H.advance(0)

	lu.assertEquals(sc:snapshot(), before, "nothing changed, the observer stays")
end

-- AC-4
function TestInspectCargoFound:test_the_cargo_hash_may_arrive_as_a_number_string()
	local sc = ready(REP)

	lu.assertEquals(sc.quest:inspectedShip(sc.player, sc:target(), tostring(sc:hash())), 1, "tostring(hash) is the quest cargo")
	lu.assertTrue(sc.quest:isQuestCargo(tostring(sc:hash())), "isQuestCargo(tostring(hash))")
end

-- AC-4
function TestInspectCargoFound:test_a_quest_that_is_not_active_returns_1_and_sends_nothing()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)
		local ship = sc:target()

		lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": never started")
		H.advance(10000)
		lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, label(name) .. ": nothing sent")

		sc:toSetup()
		sc.quest:failQuest(sc.player, "true")

		lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": after the quest failed")
		H.advance(10000)
		lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, label(name) .. ": still nothing sent")
	end
end

-- AC-4
function TestInspectCargoFound:test_two_inspect_calls_before_the_events_run_send_the_message_once()
	local sc = ready(REP)
	local ship = sc:target()

	sc.quest:inspectedShip(sc.player, ship, sc:hash())
	sc.quest:inspectedShip(sc.player, ship, sc:hash())
	H.advance(0)

	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, "one inspect_found_cargo")
	lu.assertEquals(sc:tasks()[1], "c", "task 1 complete")
	lu.assertEquals(sc:tasks()[2], "a", "task 2 active")
end

-- AC-4
function TestInspectCargoFound:test_the_cargo_found_event_acts_only_while_the_quest_is_active_and_task_1_is_active()
	local sc = I.fresh(REP)

	sc.quest:cargoFound(sc.player, "")
	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, "never started: nothing")

	sc:toSetup()
	sc:inspect(sc:target())
	sc.quest:cargoFound(sc.player, "")
	H.advance(0)

	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, "task 1 is no longer active: a second event sends nothing")
end

-- AC-4: inspecting the cargo is not required to recover it (D-1)
function TestInspectCargoFound:test_inspect_after_the_quest_ended_by_a_recovery_changes_nothing()
	local sc = ready(REP)
	local ship = sc:target(2)

	sc:dock(ship)
	H.inspect(sc.player, ship, sc:hash())
	H.advance(0)

	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, "no found message after the recovery")
	lu.assertTrue(sc:complete(), "still complete")
end

---------------------------------------------------------------------------------------------
-- AC-5: dock and recovery
---------------------------------------------------------------------------------------------

TestInspectRecovery = {}

function TestInspectRecovery:setUp() H.reset() end

-- AC-5
function TestInspectRecovery:test_a_dock_with_a_valid_target_returns_1_and_changes_nothing_inside_the_observer()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()
		local before = sc:snapshot({ ship })

		lu.assertEquals(sc.quest:dockedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": dockedShip returns 1 for a valid target")
		lu.assertEquals(sc:snapshot({ ship }), before, label(name) .. ": nothing changed inside the observer (setCargoString takes the target's lock)")
		lu.assertEquals(#ship.cargoStringCalls, 0, label(name) .. ": no setCargoString inside the observer")
	end
end

-- AC-5
function TestInspectRecovery:test_the_dock_event_clears_the_cargo_reports_the_recovery_and_completes_the_quest()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()
		local before = stateOnly(sc:snapshot({ ship }))

		H.dock(sc.player, ship, sc:hash())

		lu.assertEquals(stateOnly(sc:snapshot({ ship })), before, label(name) .. ": nothing changed synchronously by the engine notify")
		lu.assertEquals(sc:observers().dock, 0, label(name) .. ": the engine removed the dock observer (it returned 1)")

		H.advance(0)

		local recovered = sc:msgs(I.MSG_RECOVERED)

		lu.assertEquals(#recovered, 1, label(name) .. ": inspect_recovered_cargo sent once")
		lu.assertEquals(recovered[1].via, "update", label(name) .. ": as a quest update")
		lu.assertEquals(ship.cargoStringCalls, { "" }, label(name) .. ": setCargoString(\"\") called exactly once on the target")
		lu.assertEquals(ship.cargo, "", label(name) .. ": the target no longer carries the cargo")
		lu.assertTrue(sc:complete(), label(name) .. ": the journal quest is complete")
		lu.assertFalse(sc:active(), label(name) .. ": and no longer active")
		lu.assertEquals(#sc:waypoints(), 0, label(name) .. ": the waypoints are removed")
		lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, label(name) .. ": ZONESWITCHED, INSPECTEDSHIP and SHIPDOCKED dropped")
	end
end

-- AC-5 (D-1: recovery needs no prior inspect)
function TestInspectRecovery:test_recovering_without_a_prior_inspect_completes_the_quest()
	local sc = ready(REP)

	lu.assertTrue(sc:taskActive(1), "precondition: nothing inspected, task 1 still active")
	sc:dock(sc:target(2))

	lu.assertTrue(sc:complete(), "complete")
	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, "no found message was needed")
end

-- AC-5
function TestInspectRecovery:test_recovering_after_an_inspect_completes_task_2_too()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()

		sc:inspect(ship)
		lu.assertTrue(sc:taskActive(2), label(name) .. ": precondition: task 2 active")

		sc:dock(ship)

		lu.assertTrue(sc:taskComplete(2), label(name) .. ": task 2 complete")
		lu.assertTrue(sc:complete(), label(name) .. ": the quest is complete")
		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, label(name) .. ": recovered once")
	end
end

-- AC-5
function TestInspectRecovery:test_every_spawner_of_the_quest_counts_as_a_valid_origin()
	for _, name in ipairs(I.NAMES) do
		for i = 1, #I.oracle(name).spawns do
			local sc = ready(name)

			sc:dock(sc:target(i))

			lu.assertTrue(sc:complete(), label(name) .. ": a target from validSpawns[" .. i .. "] completes the quest")
		end
	end
end

-- AC-5
function TestInspectRecovery:test_every_listed_ship_counts_as_a_valid_template()
	for _, name in ipairs(I.NAMES) do
		for _, ship in ipairs(I.oracle(name).shipList) do
			local sc = ready(name)

			sc:dock(sc:target(1, { shipName = ship }))

			lu.assertTrue(sc:complete(), label(name) .. ": a " .. ship .. " completes the quest")
		end
	end
end

-- AC-5
function TestInspectRecovery:test_the_completion_split_starts_the_side_quest_and_alerts_the_player()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local o = sc.o

		sc:dock(sc:target())

		if o.sideGlobal ~= nil then
			lu.assertNotNil(sc.spies.start[o.sideGlobal], label(name) .. ": the side quest global " .. o.sideGlobal .. " exists")

			local alerts = I.createEvents("sendQuestAlert", "SpaceHelpers")

			lu.assertEquals(#alerts, 1, label(name) .. ": one split_quest_alert event")
			lu.assertEquals(alerts[1][5], "@spacequest/inspect/" .. name .. ":split_quest_alert", label(name) .. ": split_quest_alert message")
			lu.assertEquals(#I.createEvents("startQuest", o.sideGlobal), 1, label(name) .. ": a " .. o.sideGlobal .. ":startQuest event is created")

			H.advance(60000)

			lu.assertEquals(#sc.spies.start[o.sideGlobal], 1, label(name) .. ": " .. o.sideGlobal .. ":startQuest runs once")
			lu.assertIs(sc.spies.start[o.sideGlobal][1].args[1], sc.player, label(name) .. ": for the player")
		else
			lu.assertEquals(#I.createEvents("sendQuestAlert", "SpaceHelpers"), 0, label(name) .. ": no split alert")
			H.advance(60000)
			lu.assertEquals(S.called(sc.spies.start), {}, label(name) .. ": no other quest starts")
		end
	end
end

-- AC-5
function TestInspectRecovery:test_the_representative_split_events_are_the_delivery_ones()
	local sc = ready(REP)

	sc:dock(sc:target(2))

	lu.assertEquals(#I.createEvents("sendQuestAlert", "SpaceHelpers"), 1, "split_quest_alert event")
	lu.assertEquals(#I.createEvents("startQuest", "delivery_corellia_rebel_tier3_2_a"), 1, "delivery_corellia_rebel_tier3_2_a:startQuest event")
end

-- AC-5
function TestInspectRecovery:test_the_quest_without_a_side_quest_creates_no_split_events()
	local sc = ready(I.SINGLE)

	sc:dock(sc:target())

	lu.assertEquals(#I.createEvents("sendQuestAlert", "SpaceHelpers"), 0, "no split alert")
	lu.assertEquals(#I.createEvents("startQuest"), 0, "no startQuest event")
end

-- AC-5: each of these is not the quest's target
local function rejections(sc)
	local o = sc.o
	local cases = {
		{ "a nil target", nil, sc:hash() },
		{ "a player ship", H.newShip({}), sc:hash() },
		{ "an agent whose template is not in shipList", sc:target(1, { shipName = "reb_xwing_tier2" }), sc:hash() },
		{ "an agent from an unlisted spawner", sc:target(1, { spawner = "not_a_valid_spawner" }), sc:hash() },
		{ "an agent that has no SpawnerName", sc:target(1, { spawner = false }), sc:hash() },
		{ "a target with the wrong hash", sc:target(1), getHashCode("not_the_quest_cargo") },
		{ "a target with the hash 0", sc:target(1), 0 },
	}

	if o.name == I.SINGLE then
		cases[#cases + 1] = { "a Nym cannon ship from the Nym rebel run", sc:target(1, { shipName = "nym_cannon_ship_tier2", spawner = "nyms_rebel_run_1" }), sc:hash() }
	end

	if o.name == REP then
		cases[#cases + 1] = { "a Hutt smuggler from the unlisted hutt_smuggler_guard", sc:target(1, { spawner = "hutt_smuggler_guard" }), sc:hash() }
	end

	return cases
end

-- AC-5
function TestInspectRecovery:test_anything_that_is_not_the_quest_target_returns_0_changes_nothing_and_the_observer_stays()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)

		for _, case in ipairs(rejections(sc)) do
			local what, ship, hash = case[1], case[2], case[3]
			local ships = { ship }

			if ship == nil or not ship.cargoStringCalls then
				ships = {}
			end

			local before = sc:snapshot(ships)

			lu.assertEquals(sc.quest:dockedShip(sc.player, ship, hash), 0, label(name) .. ": " .. what .. ": dockedShip returns 0")

			H.dock(sc.player, ship, hash)
			H.advance(0)

			lu.assertEquals(sc:snapshot(ships), before, label(name) .. ": " .. what .. ": nothing changed and the observer stays")
			lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 0, label(name) .. ": " .. what .. ": no recovery message")
			lu.assertTrue(sc:active(), label(name) .. ": " .. what .. ": still active")
		end
	end
end

-- AC-5
function TestInspectRecovery:test_a_rejected_dock_does_not_stop_a_later_valid_dock()
	local sc = ready(REP)

	sc:dock(sc:target(1, { spawner = "hutt_smuggler_guard" }))
	lu.assertTrue(sc:active(), "precondition: still active")

	sc:dock(sc:target(3))

	lu.assertTrue(sc:complete(), "the valid dock completes the quest")
end

-- AC-5
function TestInspectRecovery:test_two_docks_with_the_valid_target_before_the_events_run_complete_the_quest_once()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local ship = sc:target()

		lu.assertEquals(sc.quest:dockedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": first dock")
		lu.assertEquals(sc.quest:dockedShip(sc.player, ship, sc:hash()), 1, label(name) .. ": second dock before the events run")
		H.advance(60000)

		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, label(name) .. ": recovered once")
		lu.assertEquals(ship.cargoStringCalls, { "" }, label(name) .. ": setCargoString once")
		lu.assertEquals(#I.createEvents("sendQuestAlert", "SpaceHelpers"), sc.o.sideGlobal and 1 or 0, label(name) .. ": the split fired at most once")
		lu.assertTrue(sc:complete(), label(name) .. ": complete")
	end
end

-- AC-5
function TestInspectRecovery:test_two_engine_docks_in_a_row_complete_the_quest_once()
	local sc = ready(REP)
	local ship = sc:target(2)

	H.dock(sc.player, ship, sc:hash())
	H.dock(sc.player, ship, sc:hash())
	H.advance(60000)

	lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, "recovered once")
	lu.assertEquals(ship.cargoStringCalls, { "" }, "setCargoString once")
end

-- AC-5: the target may be gone by the time the event runs
function TestInspectRecovery:test_a_target_that_is_gone_before_the_event_runs_still_completes_the_quest_without_an_error()
	local sc = ready(REP)
	local ship = sc:target(2)

	H.dock(sc.player, ship, sc:hash())
	H.destroyShip(ship, sc.ship)

	local ok, err = pcall(function() H.advance(0) end)

	lu.assertTrue(ok, "the event raises no error: " .. tostring(err))
	lu.assertTrue(sc:complete(), "the quest completes")
	lu.assertEquals(ship.cargoStringCalls, {}, "no write to the destroyed target")
end

-- AC-5 (D-4): the cleared cargo keeps the same ship from completing the quest again
function TestInspectRecovery:test_the_same_ship_cannot_be_recovered_again_in_a_later_run()
	local sc = ready(REP)
	local ship = sc:target(2)

	sc:dock(ship)
	lu.assertTrue(sc:complete(), "precondition: first recovery")

	-- A trainer clears the completed entry before it hands the quest out again; the server never
	-- re-activates a completed entry (PlayerObjectImplementation::activateJournalQuest).
	sc.player.ghost:clearJournalQuest(H.questCrc(sc.questType, sc.name), false)

	sc:start()
	sc:setup()
	sc:dock(ship, getHashCode(ship.cargo))

	lu.assertTrue(sc:active(), "the second run is still active: the engine now reports the hash of the empty cargo")
	lu.assertEquals(ship.cargoStringCalls, { "" }, "no second write")
end

-- AC-5
function TestInspectRecovery:test_a_late_cargo_recovered_event_for_a_quest_that_is_not_active_does_nothing()
	local sc = ready(REP)
	local ship = sc:target(2)

	sc.quest:failQuest(sc.player, "true")
	sc.quest:cargoRecovered(sc.player, tostring(ship.objectID))

	lu.assertEquals(ship.cargoStringCalls, {}, "no write to the target")
	lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 0, "no recovered message")
	lu.assertFalse(sc:complete(), "not complete")
end

---------------------------------------------------------------------------------------------
-- Queries: isQuestCargo, isQuestTarget, hasQuestData
---------------------------------------------------------------------------------------------

TestInspectQueries = {}

function TestInspectQueries:setUp() H.reset() end

-- Content contract
function TestInspectQueries:test_is_quest_cargo_compares_the_hash_of_the_quest_cargo()
	for _, name in ipairs(I.NAMES) do
		local q = I.fresh(name).quest

		lu.assertTrue(q:isQuestCargo(getHashCode(q.cargo)), label(name) .. ": the hash of '" .. q.cargo .. "'")
		lu.assertFalse(q:isQuestCargo(getHashCode(q.cargo .. "_x")), label(name) .. ": another hash")
		lu.assertFalse(q:isQuestCargo(0), label(name) .. ": 0")
		lu.assertTrue(q:isQuestCargo(tostring(getHashCode(q.cargo))), label(name) .. ": the hash as a string")
	end
end

-- Content contract
function TestInspectQueries:test_is_quest_target_accepts_a_listed_template_from_a_valid_spawner_only()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)
		local q = sc.quest

		for i = 1, #sc.o.spawns do
			lu.assertTrue(q:isQuestTarget(sc:target(i)), label(name) .. ": listed template from validSpawns[" .. i .. "]")
		end

		lu.assertFalse(q:isQuestTarget(nil), label(name) .. ": nil")
		lu.assertFalse(q:isQuestTarget(H.newShip({})), label(name) .. ": a player ship")
		lu.assertFalse(q:isQuestTarget(sc:target(1, { shipName = "reb_xwing_tier2" })), label(name) .. ": unlisted template")
		lu.assertFalse(q:isQuestTarget(sc:target(1, { spawner = "not_a_valid_spawner" })), label(name) .. ": unlisted spawner")
		lu.assertFalse(q:isQuestTarget(sc:target(1, { spawner = false })), label(name) .. ": no SpawnerName")
	end
end

-- Content contract
function TestInspectQueries:test_is_quest_target_does_not_look_at_the_cargo_the_ship_carries()
	local sc = I.fresh(REP)

	lu.assertTrue(sc.quest:isQuestTarget(sc:target(1, { cargo = "" })), "an emptied target is still a quest target by type and spawner")
end

-- Content contract
function TestInspectQueries:test_is_quest_target_uses_the_spawner_name_key_of_the_agent_it_is_given()
	local sc = I.fresh(REP)
	local a = sc:target(1)
	local b = sc:target(1, { spawner = "hutt_smuggler_guard" })

	lu.assertTrue(sc.quest:isQuestTarget(a), "a")
	lu.assertFalse(sc.quest:isQuestTarget(b), "b: a different key")
end

---------------------------------------------------------------------------------------------
-- I-6: observer discipline
---------------------------------------------------------------------------------------------

TestInspectObserverDiscipline = {}

function TestInspectObserverDiscipline:setUp() H.reset() end

local function assertDiscipline(label, sc, ships, call)
	local before = sc:snapshot(ships)
	local ret = call()

	lu.assertEquals(type(ret), "number", label .. ": the handler returns a number")
	lu.assertTrue(ret == 0 or ret == 1, label .. ": the handler returns exactly 0 or 1, got " .. tostring(ret))
	lu.assertEquals(sc:snapshot(ships), before, label .. ": nothing changed synchronously (no completion, failure, message, task, waypoint or setCargoString)")
end

-- I-6
function TestInspectObserverDiscipline:test_no_handler_changes_anything_synchronously_in_any_state()
	for _, name in ipairs(I.NAMES) do
		local sc = ready(name)
		local valid = sc:target()
		local foreign = sc:target(1, { spawner = "not_a_valid_spawner" })
		local ships = { valid, foreign }
		local p = sc.player
		local q = sc.quest

		assertDiscipline(label(name) .. ": enteredZone other zone", sc, ships, function() return q:enteredZone(p, nil, getHashCode("space_nowhere")) end)
		assertDiscipline(label(name) .. ": enteredZone same zone", sc, ships, function() return q:enteredZone(p, nil, getHashCode(sc.o.zone)) end)
		assertDiscipline(label(name) .. ": inspectedShip cargo", sc, ships, function() return q:inspectedShip(p, valid, sc:hash()) end)
		assertDiscipline(label(name) .. ": inspectedShip wrong cargo", sc, ships, function() return q:inspectedShip(p, valid, 0) end)
		assertDiscipline(label(name) .. ": inspectedShip nil", sc, ships, function() return q:inspectedShip(p, nil, sc:hash()) end)
		assertDiscipline(label(name) .. ": dockedShip valid", sc, ships, function() return q:dockedShip(p, valid, sc:hash()) end)
		assertDiscipline(label(name) .. ": dockedShip foreign", sc, ships, function() return q:dockedShip(p, foreign, sc:hash()) end)
		assertDiscipline(label(name) .. ": dockedShip nil", sc, ships, function() return q:dockedShip(p, nil, sc:hash()) end)
		assertDiscipline(label(name) .. ": dockedShip player ship", sc, ships, function() return q:dockedShip(p, sc.ship, sc:hash()) end)
	end
end

-- I-6
function TestInspectObserverDiscipline:test_handlers_of_a_quest_that_is_not_active_return_1_and_change_nothing()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)
		local valid = sc:target()
		local p = sc.player
		local q = sc.quest

		assertDiscipline(label(name) .. ": enteredZone", sc, { valid }, function() return q:enteredZone(p, nil, getHashCode("space_nowhere")) end)
		lu.assertEquals(q:enteredZone(p, nil, getHashCode("space_nowhere")), 1, label(name) .. ": enteredZone returns 1")
		lu.assertEquals(q:inspectedShip(p, valid, sc:hash()), 1, label(name) .. ": inspectedShip returns 1")
		lu.assertEquals(q:dockedShip(p, valid, sc:hash()), 1, label(name) .. ": dockedShip returns 1")
		lu.assertEquals(q:dockedShip(p, nil, 0), 1, label(name) .. ": dockedShip(nil) returns 1")
	end
end

-- I-6
function TestInspectObserverDiscipline:test_a_rejected_dock_through_the_engine_runs_no_event_of_this_class()
	local sc = ready(REP)
	local before = #H.pendingEvents()

	H.dock(sc.player, sc:target(1, { spawner = "not_a_valid_spawner" }), sc:hash())

	lu.assertEquals(#H.pendingEvents(), before, "no event created for a rejected dock")
end

---------------------------------------------------------------------------------------------
-- AC-9: coexistence with rescue and delivery on the same player
---------------------------------------------------------------------------------------------

TestInspectCoexistence = {}

function TestInspectCoexistence:setUp() H.reset() end

-- What of the inspect quest a dock with somebody else's target must not touch.
local function inspectState(sc)
	return {
		active = sc:active(),
		tasks = sc:tasks(),
		observers = sc:observers(),
		vector = sc:vector(),
		found = #sc:msgs(I.MSG_FOUND),
		recovered = #sc:msgs(I.MSG_RECOVERED),
		abandoned = #sc:msgs(I.MSG_ABANDONED),
	}
end

-- AC-9
function TestInspectCoexistence:test_docking_with_the_rescue_target_leaves_the_inspect_quest_and_its_observer_unchanged()
	local sc, rs = I.withRescue(REP)

	rs:toWaiting()
	sc:toSetup()

	local before = inspectState(sc)
	local rescueTarget = rs:target()

	H.dock(sc.player, rescueTarget)
	H.advance(0)

	lu.assertEquals(inspectState(sc), before, "the inspect quest, its tasks, observers and messages are unchanged")
	lu.assertEquals(sc:observers().dock, 1, "the inspect SHIPDOCKED observer is still there")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, rs.className, "notifyDocked", rs.player), "the rescue observer consumed its own dock")
	lu.assertEquals(R.count(rs:events(), "docking_complete"), 1, "the rescue quest got its docking_complete")
	lu.assertEquals(rescueTarget.cargoStringCalls, {}, "the rescue target's cargo was not touched")
end

-- AC-9
function TestInspectCoexistence:test_docking_with_the_inspect_target_leaves_the_rescue_run_unchanged()
	local sc, rs = I.withRescue(REP)

	rs:toWaiting()
	sc:toSetup()

	local rescueTarget = rs:target()
	local waypointsBefore = #sc:waypoints()
	local dockableBefore = #rescueTarget.dockableCalls

	sc:dock(sc:target(2))

	lu.assertTrue(sc:complete(), "the inspect quest completed")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, rs.className, "notifyDocked", rs.player), "the rescue SHIPDOCKED observer was not consumed")
	lu.assertEquals(R.count(rs:events(), "docking_complete"), 0, "the rescue quest got no docking_complete")
	lu.assertTrue(rs:active(), "the rescue quest is still active")
	lu.assertEquals(#rescueTarget.dockableCalls, dockableBefore, "the rescue target's dockable state was not touched")
	lu.assertEquals(#sc:waypoints(), waypointsBefore - 3, "only the 3 inspect waypoints were removed")
end

-- AC-9
function TestInspectCoexistence:test_docking_with_the_delivery_transport_leaves_the_inspect_quest_and_its_observer_unchanged()
	local sc, ds = I.withDelivery(REP)

	ds:toFirstTransport()
	sc:toSetup()

	local before = inspectState(sc)
	local transport = ds:transport()

	H.dock(sc.player, transport)
	H.advance(0)

	lu.assertEquals(inspectState(sc), before, "the inspect quest, its tasks, observers and messages are unchanged")
	lu.assertEquals(sc:observers().dock, 1, "the inspect SHIPDOCKED observer is still there")
	lu.assertFalse(H.hasObserver(SHIPDOCKED, ds.className, "notifyDocked", ds.player), "the delivery observer consumed its own dock")
	lu.assertEquals(transport.cargoStringCalls, {}, "the transport's cargo was not touched")
end

-- AC-9
function TestInspectCoexistence:test_docking_with_the_inspect_target_leaves_the_delivery_run_unchanged()
	local sc, ds = I.withDelivery(REP)

	ds:toFirstTransport()
	sc:toSetup()

	sc:dock(sc:target(2))

	lu.assertTrue(sc:complete(), "the inspect quest completed")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, ds.className, "notifyDocked", ds.player), "the delivery SHIPDOCKED observer was not consumed")
	lu.assertTrue(ds:active(), "the delivery quest is still active")
end

-- AC-9
function TestInspectCoexistence:test_inspecting_does_not_disturb_the_other_quests_observers()
	local sc, rs = I.withRescue(REP)

	rs:toWaiting()
	sc:toSetup()
	sc:inspect(sc:target(2))

	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 1, "the inspect quest found its cargo")
	lu.assertTrue(H.hasObserver(SHIPDOCKED, rs.className, "notifyDocked", rs.player), "the rescue SHIPDOCKED observer is untouched")
end
