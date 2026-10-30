-- Master mission completion recovery: an earned but uncompleted mission completes on the next login or zone switch.
-- Spec: .claude/work/space-master-mission-completion-recovery/01-spec.md (AC-1 to AC-10; I-1 to I-4).
--
-- Stuck state: the K-th kill fired without pumping the clock (task 1 done, the 200 ms completeQuest event pending), then H.simulateRestart().
-- Torn state: killCount >= K saved, task 1 not complete.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local DELAY = 5000

local function kindsOf(case) return { { case.ONE, "M1" }, { case.TWO, "M2" } } end

-- Mission started in Kessel; K-1 real kills; the K-th fired with no clock pump; then a restart. o.zone: where the pilot is at the login.
local function stuck(case, global, zone)
	local q, player = S.started(case, global)
	local list = case.M.shipList(global)
	local K = q.killsRequired

	S.enter(player)

	for i = 1, K - 1 do S.kill(player, S.cycle(list, i)) end

	S.fire(player, S.cycle(list, K))

	lu.assertTrue(S.taskDone(player, q, 1), global .. ": precondition: task 1 complete")
	lu.assertTrue(S.isActive(player, q), global .. ": precondition: still active")

	H.simulateRestart()
	lu.assertEquals(#H.pendingEvents(), 0, global .. ": precondition: the 200 ms event is lost")

	if zone then player.zone = zone end

	return q, player
end

-- Mission started; K-1 kills; the count written as K directly; a restart.
local function torn(case, global, zone)
	local q, player = S.started(case, global)
	local list = case.M.shipList(global)
	local K = q.killsRequired

	S.enter(player)

	for i = 1, K - 1 do S.kill(player, S.cycle(list, i)) end

	writeScreenPlayData(player, global, "killCount", tostring(K))

	lu.assertFalse(S.taskDone(player, q, 1), global .. ": precondition: task 1 open")
	lu.assertTrue(S.isActive(player, q), global .. ": precondition: active")

	H.simulateRestart()

	if zone then player.zone = zone end

	return q, player
end

local function mark() return #H.Engine.callsTo("createEvent") end

-- completeQuest createEvent calls after `from`: list of { delay, arg }
local function completeEvents(from)
	local out = {}

	for i, c in ipairs(H.Engine.callsTo("createEvent")) do
		if i > from and c[3] == "completeQuest" then
			out[#out + 1] = { c[1], c[5] }
		end
	end

	return out
end

local function login(player) H.fireObservers(LOGGEDIN, player) end

local function assertRecovered(q, player, global, completions, label)
	lu.assertTrue(S.isComplete(player, q), global .. ": " .. label .. ": complete")
	lu.assertFalse(S.isActive(player, q), global .. ": " .. label .. ": not active")
	lu.assertEquals(readScreenPlayData(player, global, "killCount"), "", global .. ": " .. label .. ": killCount cleared")
	lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. ": " .. label .. ": observers")

	if completions then
		lu.assertEquals(#completions, 1, global .. ": " .. label .. ": completeSpaceQuest calls")
		lu.assertTrue(completions[1].notify, global .. ": " .. label .. ": notify")
	end
end

TestMasterMissionCompletionRecovery = {}

function TestMasterMissionCompletionRecovery:setUp() H.reset() end
function TestMasterMissionCompletionRecovery:tearDown() S.unwrap() end

local T = TestMasterMissionCompletionRecovery

for _, case in ipairs(S.CASES) do
	for _, kind in ipairs(kindsOf(case)) do
		local global, tag = kind[1], kind[2]

		-- AC-1
		T["test_login_in_kessel_in_the_stuck_state_completes_" .. global] = function()
			local q, player = stuck(case, global, S.ZONE)
			local calls = S.countCompletions()

			login(player)
			S.pump(6000, "login")
			assertRecovered(q, player, global, calls, "login in Kessel")
		end

		-- AC-2
		for _, zone in ipairs({ S.GROUND, "space_heavy1" }) do
			T["test_login_in_" .. zone .. "_in_the_stuck_state_completes_" .. global] = function()
				local q, player = stuck(case, global, zone)

				login(player)
				S.pump(6000, "login")
				assertRecovered(q, player, global, nil, "login in " .. zone)
			end
		end

		-- AC-3
		for _, zone in ipairs({ S.ZONE, "space_heavy1", S.GROUND }) do
			T["test_zone_switch_to_" .. zone .. "_in_the_stuck_state_completes_" .. global] = function()
				local q, player = stuck(case, global, S.GROUND)

				H.zoneSwitch(player, zone)
				S.pump(6000, "zone switch")
				assertRecovered(q, player, global, nil, "zone switch to " .. zone)
			end
		end

		-- AC-4
		T["test_login_and_zone_switch_defer_completion_by_five_seconds_and_return_0_for_" .. global] = function()
			local q, player = stuck(case, global, S.GROUND)
			local from = mark()

			lu.assertEquals(_G[global]:onLoggedIn(player), 0, global .. ": onLoggedIn return")
			lu.assertTrue(S.isActive(player, q), global .. ": still active after the login handler")
			lu.assertEquals(completeEvents(from), { { DELAY, "true" } }, global .. ": login events")

			from = mark()
			lu.assertEquals(_G[global]:enteredZone(player, nil, getHashCode("space_heavy1")), 0, global .. ": enteredZone return")
			lu.assertTrue(S.isActive(player, q), global .. ": still active after the zone handler")
			lu.assertEquals(completeEvents(from), { { DELAY, "true" } }, global .. ": zone events")
		end

		-- AC-5
		T["test_repeated_triggers_complete_exactly_once_for_" .. global] = function()
			local q, player = stuck(case, global, S.GROUND)
			local calls = S.countCompletions()

			login(player)
			H.zoneSwitch(player, S.ZONE)
			login(player)
			S.pump(10000, "triggers")
			assertRecovered(q, player, global, calls, "three triggers")
		end

		-- AC-5
		T["test_a_zone_switch_inside_the_200_ms_window_completes_exactly_once_for_" .. global] = function()
			local q, player = S.started(case, global)
			local list = case.M.shipList(global)

			S.enter(player)

			for i = 1, q.killsRequired - 1 do S.kill(player, S.cycle(list, i)) end

			local calls = S.countCompletions()

			S.fire(player, S.cycle(list, q.killsRequired))
			H.zoneSwitch(player, S.ZONE)
			S.pump(10000, "window")
			assertRecovered(q, player, global, calls, "no restart")
		end

		-- AC-6
		T["test_a_lost_recovery_event_is_scheduled_again_by_the_next_login_for_" .. global] = function()
			local q, player = stuck(case, global, S.GROUND)
			local calls = S.countCompletions()

			login(player)
			H.simulateRestart()
			lu.assertEquals(#H.pendingEvents(), 0, global .. ": recovery event lost")
			lu.assertTrue(S.isActive(player, q), global .. ": still stuck")

			login(player)
			S.pump(6000, "second login")
			assertRecovered(q, player, global, calls, "after the lost event")
		end

		-- AC-7
		for _, zone in ipairs({ S.ZONE, S.GROUND }) do
			T["test_torn_state_in_" .. zone .. "_completes_on_login_for_" .. global] = function()
				local q, player = torn(case, global, zone)
				local calls = S.countCompletions()

				login(player)
				S.pump(6000, "torn login")
				assertRecovered(q, player, global, calls, "torn in " .. zone)
			end
		end

		-- AC-8
		T["test_no_kills_reminder_when_earned_for_" .. global] = function()
			-- stuck state, login in Kessel
			local q, player = stuck(case, global, S.ZONE)
			local m = S.messageMark(player)

			login(player)
			S.pump(6000, "stuck login")
			lu.assertEquals(S.updates(player, m), {}, global .. ": stuck login in Kessel")

			-- stuck state, zone switch into Kessel
			q, player = stuck(case, global, S.GROUND)
			m = S.messageMark(player)
			H.zoneSwitch(player, S.ZONE)
			S.pump(6000, "stuck zone switch")
			lu.assertEquals(S.updates(player, m), {}, global .. ": stuck zone switch into Kessel")

			-- torn state, login in Kessel
			q, player = torn(case, global, S.ZONE)
			m = S.messageMark(player)
			login(player)
			S.pump(6000, "torn login")
			lu.assertEquals(S.updates(player, m), {}, global .. ": torn login in Kessel")

			-- torn state, remindProgress called directly
			q, player = torn(case, global, S.ZONE)
			m = S.messageMark(player)
			_G[global]:remindProgress(player)
			lu.assertEquals(S.updates(player, m), {}, global .. ": remindProgress in the torn state")
		end
	end

	-- AC-9
	local global = case.ONE

	T["test_not_earned_states_schedule_no_completion_for_" .. global] = function()
		local q, player = S.started(case, global)
		local list = case.M.shipList(global)

		S.enter(player)

		for i = 1, 12 do S.kill(player, S.cycle(list, i)) end

		H.simulateRestart()
		player.zone = S.ZONE

		local from = mark()

		login(player)
		player.zone = S.GROUND
		login(player)
		H.zoneSwitch(player, S.ZONE)
		S.pump(10000, "not earned")
		lu.assertEquals(completeEvents(from), {}, global .. ": completeQuest events")
		lu.assertTrue(S.isActive(player, q), global .. ": still active")
		lu.assertEquals(S.count(player, global), 12, global .. ": count")
	end

	-- AC-10
	for _, kind in ipairs(kindsOf(case)) do
		local g, tag = kind[1], kind[2]

		T["test_admiral_shows_won_screen_after_recovery_of_" .. g] = function()
			case.M.requireConversation(lu)

			local q, player = stuck(case, g, S.GROUND)

			login(player)
			S.pump(6000, "recovery")
			lu.assertEquals(case.M.firstScreen(player), tag == "M1" and "m1_won" or "m2_won", g .. ": first screen after recovery")
		end
	end
end

-- AC-10: pins against the base
local BASE = "e974b3c786"
local BIN = "MMOCoreORB/bin/scripts/"
local SMD = BIN .. "screenplays/space/SpaceMasterDestroyScreenplay.lua"
local UNCHANGED = {
	BIN .. "screenplays/space/conversations/imperial/nialDeclannConvoHandler.lua",
	BIN .. "screenplays/space/conversations/rebel/willhamBurkeConvoHandler.lua",
	BIN .. "utils/space_helpers.lua",
	BIN .. "screenplays/space/squadrons/MasterTrainerScreenplay.lua",
}

local function shell(cmd)
	local pipe = assert(io.popen(cmd .. " 2>&1; echo \"rc=$?\""))
	local out = pipe:read("a")

	pipe:close()

	return tonumber(out:match("rc=(%d+)%s*$")), (out:gsub("rc=%d+%s*$", ""))
end

local function spec(path) return "':/" .. path .. "'" end
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function requireBase()
	local rc, out = shell("git cat-file -e " .. BASE .. "^{commit}")

	if rc ~= 0 then lu.skip("git cannot show " .. BASE .. ": " .. trim(out)) end

	local _, head = shell("git rev-parse HEAD")

	if head:sub(1, #BASE) ~= BASE then
		lu.skip("HEAD is not " .. BASE .. " (" .. trim(head) .. "): the pin only applies before the feature is committed")
	end
end

local function listOf(out)
	local list = {}

	for line in out:gmatch("[^\n]+") do list[#list + 1] = trim(line) end

	table.sort(list)
	return list
end

TestMasterMissionCompletionRecoveryPins = {}

-- AC-10
function TestMasterMissionCompletionRecoveryPins:test_smd_is_the_only_production_file_changed()
	requireBase()

	local paths = spec("MMOCoreORB/bin") .. " " .. spec("MMOCoreORB/src")
	local rc, changed = shell("git diff --name-only " .. BASE .. " -- " .. paths)
	local rcU, untracked = shell("git ls-files --full-name --others --exclude-standard -- " .. paths)

	lu.assertEquals(rc, 0, changed)
	lu.assertEquals(rcU, 0, untracked)

	local all = listOf(changed)

	for _, f in ipairs(listOf(untracked)) do all[#all + 1] = f end

	table.sort(all)
	lu.assertEquals(all, { SMD }, "files changed or added under bin/ and src/ against " .. BASE)
end

for _, path in ipairs(UNCHANGED) do
	-- AC-10
	TestMasterMissionCompletionRecoveryPins["test_" .. path:match("([^/]+)%.lua$") .. "_is_byte_identical_to_the_base"] = function()
		requireBase()

		local rc, out = shell("git diff --quiet " .. BASE .. " -- " .. spec(path))

		lu.assertEquals(rc, 0, path .. " differs from " .. BASE .. ": " .. out)
	end
end
