-- Inspect quest teardown, stale events, restarts and safe resets (space-quest-inspect-cargo).
-- Spec: .claude/work/space-quest-inspect-cargo/01-spec.md (AC-8, I-4, I-5, Behavior 6). The second Lua VM is
-- modelled like the other slices: I.snapshotVm() right after I.load(), I.resetVm() between runs.

local lu = require("luaunit")
local H = require("harness")
local I = require("inspect_scenario")

I.load()
I.snapshotVm()

local REP = I.REP

local function label(name) return "inspect/" .. name end

---------------------------------------------------------------------------------------------
-- Ending a run: complete, fail, reset
---------------------------------------------------------------------------------------------

-- Each ending takes a scenario and a target and ends the run the way the named path does.
local ENDINGS = {
	recover = function(sc, target) sc:dock(target) end,                       -- the real completion path: a dock with the target
	complete = function(sc) sc.quest:completeQuest(sc.player, "true") end,    -- completeQuest called directly
	fail = function(sc) sc.quest:failQuest(sc.player, "true") end,
	reset = function(sc) sc.quest:resetQuest(sc.player) end,
}

local ENDING_NAMES = { "recover", "complete", "fail", "reset" }

-- A dock only recovers the cargo once the quest is set up (the observer exists from then on).
local function applies(ending, state)
	return not (ending == "recover" and state == "started")
end

-- States in which to end it: how far the run got.
local STATES = {
	started = function(sc) sc:start() end,                                   -- task 0 only
	setUp = function(sc) sc:toSetup() end,                                   -- waypoints, observers
	noticed = function(sc) sc:toSetup() sc:notice() end,                     -- and the waypoint notice sent
	inspected = function(sc) sc:toSetup() sc:inspect(sc:target(1)) end,      -- task 2 active
}

local STATE_NAMES = { "started", "setUp", "noticed", "inspected" }

local function assertClean(desc, sc)
	lu.assertEquals(I.ownKeys(sc.player, sc.className), {}, desc .. ": no shared-memory key of <playerID>:<className>: remains")
	lu.assertEquals(#sc:waypoints(), 0, desc .. ": no waypoint left on the player")
	lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, desc .. ": no ZONESWITCHED, INSPECTEDSHIP or SHIPDOCKED observer of the class")
	lu.assertFalse(sc:active(), desc .. ": the quest is not active")
end

TestInspectTeardown = {}

function TestInspectTeardown:setUp() H.reset() end

-- AC-8, I-4
function TestInspectTeardown:test_every_ending_in_every_state_leaves_no_key_waypoint_or_observer()
	for _, name in ipairs(I.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			for _, state in ipairs(STATE_NAMES) do
				if applies(ending, state) then
					local sc = I.fresh(name)
					local target = sc:target()

					STATES[state](sc)
					ENDINGS[ending](sc, target)
					H.advance(0)

					assertClean(label(name) .. ": " .. ending .. " after " .. state, sc)
				end
			end
		end
	end
end

-- I-4
function TestInspectTeardown:test_every_shared_memory_key_the_type_writes_starts_with_the_player_id_and_class_name()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name)
		local target = sc:target()
		local baseline = {}

		for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
			baseline[k] = true
		end

		sc:toSetup()
		sc:notice()
		sc:inspect(target)

		local prefix = sc.player.objectID .. ":" .. sc.className .. ":"

		for _, k in ipairs(H.Engine.sharedMemoryKeys()) do
			if not baseline[k] then
				local key = k:match("^[^|]*|(.*)$")

				lu.assertEquals(key:sub(1, #prefix), prefix, label(name) .. ": the new shared-memory key '" .. k .. "' must start with '" .. prefix .. "'")
			end
		end
	end
end

-- AC-8
function TestInspectTeardown:test_a_late_inspect_or_dock_with_the_quest_cargo_after_an_ending_changes_nothing()
	for _, name in ipairs(I.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc = I.fresh(name)
			local target = sc:target()

			sc:toSetup()
			ENDINGS[ending](sc, target)
			H.advance(0)

			local found, recovered, writes = #sc:msgs(I.MSG_FOUND), #sc:msgs(I.MSG_RECOVERED), #target.cargoStringCalls
			local active, complete, messages = sc:active(), sc:complete(), #sc.player.messageLog
			local other = sc:target()

			H.inspect(sc.player, other, sc:hash())
			H.dock(sc.player, other, sc:hash())
			H.advance(0)

			lu.assertEquals(sc.quest:inspectedShip(sc.player, other, sc:hash()), 1, label(name) .. ": " .. ending .. ": inspectedShip returns 1 (stale)")
			lu.assertEquals(sc.quest:dockedShip(sc.player, other, sc:hash()), 1, label(name) .. ": " .. ending .. ": dockedShip returns 1 (stale)")
			H.advance(0)

			lu.assertEquals({ #sc:msgs(I.MSG_FOUND), #sc:msgs(I.MSG_RECOVERED), #target.cargoStringCalls }, { found, recovered, writes }, label(name) .. ": " .. ending .. ": no inspect message, no cargo write")
			lu.assertEquals(#other.cargoStringCalls, 0, label(name) .. ": " .. ending .. ": the other ship's cargo was not touched")
			lu.assertEquals({ sc:active(), sc:complete(), #sc.player.messageLog }, { active, complete, messages }, label(name) .. ": " .. ending .. ": nothing else changed")
		end
	end
end

-- AC-8
function TestInspectTeardown:test_pumping_the_remaining_events_after_an_ending_sends_no_inspect_message_and_adds_no_waypoint()
	for _, name in ipairs(I.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			for _, state in ipairs(STATE_NAMES) do
				if applies(ending, state) then
					local sc = I.fresh(name)
					local target = sc:target()

					STATES[state](sc)
					ENDINGS[ending](sc, target)

					local desc = label(name) .. ": " .. ending .. " after " .. state
					local counts = { #sc:msgs(I.MSG_FOUND), #sc:msgs(I.MSG_RECOVERED), #sc:msgs(I.MSG_WAYPOINTS), #sc:msgs(I.MSG_ABANDONED) }

					H.advance(600000)

					lu.assertEquals({ #sc:msgs(I.MSG_FOUND), #sc:msgs(I.MSG_RECOVERED), #sc:msgs(I.MSG_WAYPOINTS), #sc:msgs(I.MSG_ABANDONED) }, counts, desc .. ": no inspect message after the ending")
					lu.assertEquals(#sc:waypoints(), 0, desc .. ": no waypoint added after the ending")
					assertClean(desc .. " (after 10 minutes)", sc)
				end
			end
		end
	end
end

-- AC-8
function TestInspectTeardown:test_a_quest_ended_before_the_waypoint_notice_never_sends_it()
	for _, ending in ipairs({ "fail", "reset" }) do
		local sc = I.fresh(REP):toSetup()

		H.advance(500)
		ENDINGS[ending](sc)
		H.advance(10000)

		lu.assertEquals(#sc:msgs(I.MSG_WAYPOINTS), 0, ending .. ": the pending notice sends nothing for an ended quest")
	end
end

-- AC-8
function TestInspectTeardown:test_a_quest_ended_before_the_setup_event_never_sets_up()
	for _, ending in ipairs({ "fail", "reset" }) do
		local sc = I.fresh(REP):start()

		H.advance(500)
		ENDINGS[ending](sc)
		H.advance(10000)

		lu.assertEquals(#sc:waypoints(), 0, ending .. ": the pending setup adds no waypoint")
		lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, ending .. ": and no observer")
		lu.assertFalse(sc:taskComplete(0), ending .. ": task 0 stays incomplete")
	end
end

-- AC-8
function TestInspectTeardown:test_a_pending_cargo_found_or_recovered_event_of_an_ended_quest_does_nothing()
	local sc = I.fresh(REP):toSetup()
	local ship = sc:target(2)

	sc.quest:inspectedShip(sc.player, ship, sc:hash())
	sc.quest:dockedShip(sc.player, ship, sc:hash())
	sc.quest:failQuest(sc.player, "true")
	H.advance(0)

	lu.assertEquals(#sc:msgs(I.MSG_FOUND), 0, "no found message")
	lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 0, "no recovered message")
	lu.assertEquals(ship.cargoStringCalls, {}, "no cargo write")
	lu.assertFalse(sc:complete(), "not complete")
	lu.assertFalse(sc:taskActive(2), "task 2 was not activated")
end

-- AC-8
function TestInspectTeardown:test_failing_twice_acts_once()
	local sc = I.fresh(REP):toSetup()

	sc.quest:failQuest(sc.player, "true")
	sc.quest:failQuest(sc.player, "true")
	H.advance(0)

	lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 1, "inspect_abandoned once")
end

-- Behavior 6: complete/fail/reset share one cleanup
function TestInspectTeardown:test_clean_up_quest_data_takes_the_player_and_clears_the_run()
	local sc = I.fresh(REP):toSetup()

	sc.quest:cleanUpQuestData(sc.player)

	lu.assertEquals(I.ownKeys(sc.player, sc.className), {}, "no shared-memory key of the class remains")
	lu.assertTrue(sc:active(), "cleanUpQuestData itself does not end the journal quest")
	lu.assertEquals(#sc:waypoints(), 0, "waypoints cleared")
	lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, "observers dropped")
	lu.assertEquals(sc:vector(), {}, "waypoint vector cleared")
end

-- Behavior 6: complete keeps its journal completion
function TestInspectTeardown:test_a_completed_quest_is_complete_and_a_failed_or_reset_one_is_not()
	local sc = I.fresh(REP):toSetup()

	sc.quest:completeQuest(sc.player, "true")
	lu.assertTrue(sc:complete(), "completeQuest completes the journal quest")
	assertClean("completeQuest", sc)

	local sc2 = I.fresh(REP):toSetup()

	sc2.quest:resetQuest(sc2.player)
	lu.assertFalse(sc2:complete(), "resetQuest does not complete")
	lu.assertEquals(#sc2:msgs(I.MSG_ABANDONED), 0, "resetQuest fails silently")
end

---------------------------------------------------------------------------------------------
-- I-5: safe teardown
---------------------------------------------------------------------------------------------

TestInspectSafeTeardown = {}

function TestInspectSafeTeardown:setUp() H.reset() end

-- I-5
function TestInspectSafeTeardown:test_ending_a_quest_that_was_never_started_raises_no_error()
	for _, name in ipairs(I.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc = I.fresh(name)
			local ok, err = pcall(function()
				ENDINGS[ending](sc, sc:target())
				sc.quest:cleanUpQuestData(sc.player)
				H.advance(600000)
			end)

			lu.assertTrue(ok, label(name) .. ": " .. ending .. " without a start raises no error: " .. tostring(err))
		end
	end
end

-- I-5
function TestInspectSafeTeardown:test_ending_a_quest_that_never_set_up_raises_no_error()
	for _, name in ipairs(I.NAMES) do
		for _, ending in ipairs(ENDING_NAMES) do
			local sc = I.fresh(name, { zone = "space_nowhere" })
			local ok, err = pcall(function()
				sc:start()
				ENDINGS[ending](sc, sc:target())
				H.advance(600000)
			end)

			lu.assertTrue(ok, label(name) .. ": " .. ending .. " before setup raises no error: " .. tostring(err))
		end
	end
end

-- I-5
function TestInspectSafeTeardown:test_a_nil_player_raises_no_error()
	local q = H.expectGlobal(I.global(REP))

	I.checkRewrite(q, REP)

	for _, m in ipairs({ "completeQuest", "failQuest", "resetQuest", "cleanUpQuestData", "startQuest", "setupInspection", "abandonInspection" }) do
		local ok, err = pcall(function() q[m](q, nil, "true") end)

		lu.assertTrue(ok, m .. "(nil) raises no error: " .. tostring(err))
	end
end

-- I-5
function TestInspectSafeTeardown:test_the_trainer_reset_functions_run_without_error_for_a_fresh_and_a_mid_run_player()
	local resets = {
		{ "CorsecSquadronScreenplay", "resetRikkhQuests", I.SINGLE },
		{ "CorsecSquadronScreenplay", "resetRamnaQuests", "corellia_privateer_tier3_2" },
		{ "HavocSquadronScreenplay", "resetViopaQuests", "viopa_rebel_1" },
		{ "HavocSquadronScreenplay", "resetAqzowQuests", REP },
		{ "RsfSquadronScreenplay", "resetDuliosQuests", "naboo_privateer_tier3_3a" },
		{ "RsfSquadronScreenplay", "resetKaydineQuests", I.MISSING },
	}

	for _, r in ipairs(resets) do
		local screenplay, method, inspectName = r[1], r[2], r[3]

		-- A player who never started anything.
		H.reset()
		local fresh = H.newPlayer({ zone = "space_lok", ship = {}, pilot = "rebel" })
		local ok1, err1 = pcall(function() _G[screenplay][method](_G[screenplay], fresh) end)

		lu.assertTrue(ok1, screenplay .. ":" .. method .. " raises no error for a fresh player: " .. tostring(err1))

		-- A player in the middle of the inspect quest it resets.
		H.reset()

		local sc = I.new(inspectName)

		sc:start()
		H.advance(1500)

		local ok2, err2 = pcall(function()
			_G[screenplay][method](_G[screenplay], sc.player)
			H.advance(600000)
		end)

		lu.assertTrue(ok2, screenplay .. ":" .. method .. " raises no error for a player mid-run: " .. tostring(err2))
		lu.assertFalse(sc:active(), screenplay .. ":" .. method .. " leaves " .. inspectName .. " not active")
		lu.assertEquals(#sc:waypoints(), 0, screenplay .. ":" .. method .. " leaves no inspect waypoint")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: restarts and a second Lua VM
---------------------------------------------------------------------------------------------

TestInspectRestart = {}

function TestInspectRestart:setUp()
	H.reset()
	I.resetVm()
end

-- Fails run 1 `failAfter` ms after its start, restarts at once (optionally "on another VM"), sets run 2 up and
-- docks with the valid target.
local function failThenRestart(name, failAfter, otherVm)
	local sc = I.fresh(name):start()
	local target = sc:target()

	H.advance(failAfter)
	sc.quest:failQuest(sc.player, "true")
	lu.assertFalse(sc:active(), "precondition: run 1 failed")

	if otherVm then
		I.resetVm()
	end

	sc:start()
	sc:setup()

	local waypointsAtSetup = #sc:waypoints()
	local observersAtSetup = sc:observers()

	sc:dock(target)

	return sc, target, waypointsAtSetup, observersAtSetup
end

-- AC-8
function TestInspectRestart:test_start_setup_fail_start_setup_dock_completes_once_with_three_waypoints()
	for _, failAfter in ipairs({ 500, 1500, 5000 }) do
		local sc, target, waypoints, observers = failThenRestart(REP, failAfter, false)
		local desc = "failed " .. failAfter .. " ms after the start"

		lu.assertEquals(waypoints, 3, desc .. ": exactly 3 waypoints after the second setup")
		lu.assertEquals(observers, { zone = 1, inspect = 1, dock = 1 }, desc .. ": one observer each in run 2")
		lu.assertTrue(sc:complete(), desc .. ": run 2 completed")
		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, desc .. ": recovered once")
		lu.assertEquals(target.cargoStringCalls, { "" }, desc .. ": the cargo was taken once")

		H.advance(600000)

		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, desc .. ": and still once after the stale events ran")
		lu.assertEquals(#sc:waypoints(), 0, desc .. ": no waypoint left")
		assertClean(desc, sc)
	end
end

-- AC-8
function TestInspectRestart:test_the_same_scenario_on_a_second_lua_vm_gives_the_same_result()
	for _, failAfter in ipairs({ 500, 1500, 5000 }) do
		local sc, target, waypoints, observers = failThenRestart(REP, failAfter, true)
		local desc = "second VM, failed " .. failAfter .. " ms after the start"

		lu.assertEquals(waypoints, 3, desc .. ": exactly 3 waypoints after the second setup")
		lu.assertEquals(observers, { zone = 1, inspect = 1, dock = 1 }, desc .. ": one observer each in run 2")
		lu.assertTrue(sc:complete(), desc .. ": run 2 completed")
		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, desc .. ": recovered once")
		lu.assertEquals(target.cargoStringCalls, { "" }, desc .. ": the cargo was taken once")
	end
end

-- AC-8
function TestInspectRestart:test_every_quest_survives_a_restart_and_a_vm_switch_in_the_middle_of_a_run()
	for _, name in ipairs(I.NAMES) do
		local sc = I.fresh(name):toSetup()
		local target = sc:target()

		sc:inspect(target)
		I.resetVm()
		sc:dock(target)

		lu.assertTrue(sc:complete(), label(name) .. ": a VM switch between the inspect and the dock changes nothing")
		lu.assertEquals(#sc:msgs(I.MSG_RECOVERED), 1, label(name) .. ": recovered once")
	end
end

-- AC-8
function TestInspectRestart:test_the_trainer_can_restart_a_failed_quest_and_complete_it_the_second_time()
	local sc = I.fresh(REP):toSetup()

	H.zoneSwitch(sc.player, "space_nowhere")
	H.advance(0)
	lu.assertFalse(sc:active(), "precondition: abandoned")

	H.zoneSwitch(sc.player, sc.o.zone, { ship = {} })
	sc:start()
	sc:setup()

	lu.assertEquals(#sc:waypoints(), 3, "three waypoints in the second run")

	sc:dock(sc:target(3))

	lu.assertTrue(sc:complete(), "the second run completes")
	lu.assertEquals(#sc:msgs(I.MSG_ABANDONED), 1, "inspect_abandoned was sent once, for the first run")
end
