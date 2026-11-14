-- Quests that ignore a ship death: the four master missions [user, pre-NGE: progress survives death] and SWG's patrol_duty
-- (SCRIPT_OVERRIDE, no fail).
-- Spec: .claude/work/space-quest-player-ship-destroyed/01-spec.md (AC-6, I-5, D-7, D-8)

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")
local PSD = require("psd_scenario")

S.load()
PSD.load()

local function needHook()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "playerShipDestroyed")), "function",
		"expected SpaceQuestLogic:playerShipDestroyed (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
end

local function kills(case, global) return global == case.ONE and 30 or 1 end

-- The master mission states of the master-mission tests: started on the ground, in Kessel with no kill, with kills saved (and, for
-- mission 1, a few more kills of other fighters), back on the ground after a landing
local STATES = {
	started_on_the_ground = function(case, global) return S.started(case, global) end,
	in_kessel_no_kill = function(case, global)
		local q, player = S.started(case, global)

		S.enter(player)

		return q, player
	end,
	in_kessel_with_kills = function(case, global)
		local q, player = S.started(case, global)

		S.enter(player)

		for i = 1, math.min(3, kills(case, global) - 1) do
			S.kill(player, S.cycle(case.M.shipList(global), i))
		end

		return q, player
	end,
	landed_after_kills = function(case, global)
		local q, player = S.started(case, global)

		S.enter(player)

		if kills(case, global) > 1 then
			S.kill(player, case.M.shipList(global)[1]) -- mission 2 has one kill and ends with it
		end

		S.goTo(player, S.GROUND)

		return q, player
	end,
}

local STATE_NAMES = {}

for name in pairs(STATES) do STATE_NAMES[#STATE_NAMES + 1] = name end

table.sort(STATE_NAMES)

TestShipDeathMasterMissions = {}

function TestShipDeathMasterMissions:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	for _, global in ipairs({ case.ONE, case.TWO }) do
		for _, state in ipairs(STATE_NAMES) do
			-- AC-6, I-5
			TestShipDeathMasterMissions["test_a_ship_death_in_state_" .. state .. "_leaves_" .. global .. "_alone"] = function()
				needHook()

				local q, player = STATES[state](case, global)
				local count = S.count(player, global)
				local messages, music = #H.messageLog(player), #player.music
				local events, observers = #H.Engine.callsTo("createEvent"), S.observerCounts(player, global)
				local waypoints = #player.ghost.waypoints

				local called = H.playerShipDestroyed(player)

				H.advance(30 * 1000)

				lu.assertEquals(called, { global }, "the master mission is told of the death")
				lu.assertTrue(S.isActive(player, q), global .. ": still active")
				lu.assertFalse(S.isComplete(player, q), global .. ": not complete")
				lu.assertEquals(S.count(player, global), count, global .. ": the saved kill count")
				lu.assertEquals(#H.messageLog(player), messages, global .. ": no message (no Mission Failed)")
				lu.assertEquals(#player.music, music, global .. ": no music")
				lu.assertEquals(#H.Engine.callsTo("createEvent"), events, global .. ": no event")
				lu.assertEquals(S.observerCounts(player, global), observers, global .. ": the persistent observers")
				lu.assertEquals(#player.ghost.waypoints, waypoints, global .. ": waypoints")
				lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers still persistent with the integer 1")
			end
		end

		-- AC-6: the next kill after a ship death still counts
		TestShipDeathMasterMissions["test_the_next_kill_after_a_ship_death_still_counts_for_" .. global] = function()
			needHook()

			local q, player = STATES.in_kessel_no_kill(case, global)
			local first = case.M.shipList(global)[1]

			if kills(case, global) > 1 then
				S.kill(player, first)
				lu.assertEquals(S.count(player, global), 1, global .. ": precondition: one kill saved")
			end

			H.playerShipDestroyed(player)
			H.zoneSwitch(player, player.zone) -- the respawn
			H.advance(12 * 1000)
			lu.assertTrue(S.isActive(player, q), global .. ": active after the death and the respawn")

			S.kill(player, case.M.shipList(global)[2] or first)

			if kills(case, global) > 1 then
				lu.assertEquals(S.count(player, global), 2, global .. ": the kill after the death counts")
			else
				lu.assertTrue(S.isComplete(player, q), global .. ": the one kill after the death completes the mission")
			end
		end
	end
end

-- AC-6: the master missions take the base `false` and define nothing of their own
function TestShipDeathMasterMissions:test_the_master_mission_type_inherits_the_base_run_check()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "isRunInProgress")), "function", "SpaceQuestLogic:isRunInProgress")
	lu.assertNil(rawget(SpaceMasterDestroyScreenplay, "isRunInProgress"), "SpaceMasterDestroyScreenplay:isRunInProgress")
	lu.assertNil(rawget(SpaceMasterDestroyScreenplay, "playerShipDestroyed"), "SpaceMasterDestroyScreenplay:playerShipDestroyed")
	lu.assertNil(rawget(SpaceMasterDestroyScreenplay, "failShipDestroyed"), "SpaceMasterDestroyScreenplay:failShipDestroyed")
end

---------------------------------------------------------------------------------------------
-- D-8 (I-5): a duty patrol instance never fails on a ship death
---------------------------------------------------------------------------------------------

TestShipDeathDutyPatrol = {}

function TestShipDeathDutyPatrol:setUp() H.reset() end
function TestShipDeathDutyPatrol:tearDown() PSD.dropDutyPatrol() end

-- AC-6, I-5
function TestShipDeathDutyPatrol:test_a_duty_patrol_with_its_patrol_progress_ignores_a_ship_death()
	needHook()

	local q = PSD.dutyPatrol()
	local player = PSD.acceptedDirect(q)

	PSD.inProgress(q, player) -- the state in which a patrol would fail

	local messages, music, events = #H.messageLog(player), #player.music, #H.Engine.callsTo("createEvent")
	local called = H.playerShipDestroyed(player)

	H.advance(30 * 1000)

	lu.assertEquals(called, { PSD.DUTY_PATROL_GLOBAL }, "the duty patrol is told of the death")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), "still active")
	lu.assertEquals(#H.messageLog(player), messages, "no message")
	lu.assertEquals(#player.music, music, "no music")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), events, "no event")
	lu.assertTrue(PSD.hasMission(player, q), "the mission is on the datapad")
end
