-- CorSec tier 3 mission 4 end to end: survival 4_a > inspect 4_b > delivery_no_pickup 4_c at runtime.
-- Spec: .claude/work/corsec-tier3-extensions/01-spec.md (AC-5, Data mapping: split delays, Risks: disabled-tyrant docking).
--
-- Real quest code runs for the three chain members; every other quest's startQuest and failQuest is spied.
-- The numbers come from the SWG-Source fixtures through the scenario builders: the survival timeline from
-- survival/corellia_privateer_tier3_4_a.tab, the inspect target from inspect/corellia_privateer_tier3_4_b.tab and
-- the Core3 spawner table, the delivery legs from delivery_no_pickup/corellia_privateer_tier3_4_c.tab.
-- A split fires its alert at sideQuestDelay s and starts the next quest at sideQuestDelay * 1.05 s
-- (SpaceQuestLogic:triggerCompletionSplitQuest); with the delay 0 + 5 of D-3 that is 5 s and 5.25 s.

local lu = require("luaunit")
local H = require("harness")
local S = require("survival_scenario")
local I = require("inspect_scenario")
local D = require("delivery_scenario")

S.load()

local SURVIVAL = "survival_corellia_privateer_tier3_4_a"
local INSPECT = "inspect_corellia_privateer_tier3_4_b"
local DELIVERY = "delivery_no_pickup_corellia_privateer_tier3_4_c"
local NAME_4A, NAME_4B, NAME_4C = "corellia_privateer_tier3_4_a", "corellia_privateer_tier3_4_b", "corellia_privateer_tier3_4_c"

local function secs(n) return n * 1000 end

local function state(player, questType, name)
	if SpaceHelpers:isSpaceQuestActive(player, questType, name) then
		return "active"
	elseif SpaceHelpers:isSpaceQuestComplete(player, questType, name) then
		return "complete"
	end

	return "none"
end

local function chainState(player)
	return table.concat({ state(player, "survival", NAME_4A), state(player, "inspect", NAME_4B), state(player, "delivery_no_pickup", NAME_4C) }, "/")
end

-- The three members run for real, everything else is spied.
local function chainSpies()
	return I.isolate({ SURVIVAL, INSPECT, DELIVERY })
end

-- Survival 4_a started and run to its completion; returns the survival scenario and the time it completed.
local function survivalDone()
	H.reset()

	local sc = S.new(NAME_4A, { spies = chainSpies() })

	sc:start():arrive()

	local o = sc.o
	local step = o.total // o.updates
	local doneAt = secs(o.transStart + o.updates * step + 5) -- mission_complete, 5 s after the transmission is received

	sc:at(doneAt)
	return sc, H.now()
end

-- Inspect 4_b (started by the split) set up and docked with a disabled tyrant of the spawner; returns the inspect scenario.
local function inspectDocked(sc)
	H.advance(secs(6))

	local isc = I.new(NAME_4B, { spies = sc.spies, player = sc.player })

	isc.tStart = H.now()
	isc:setup()

	isc:dock(isc:target(1))
	return isc
end

TestCorsecTier3RuntimeChain = {}

function TestCorsecTier3RuntimeChain:setUp() H.reset() end

-- AC-5
function TestCorsecTier3RuntimeChain:test_completing_survival_4_a_alerts_after_5_seconds_and_starts_inspect_4_b()
	local sc, tDone = survivalDone()

	lu.assertEquals(sc:complete(), true, "survival 4_a is complete")
	lu.assertEquals(chainState(sc.player), "complete/none/none", "chain just after the survival completed")

	H.advance(secs(4) + 800)
	lu.assertEquals(state(sc.player, "inspect", NAME_4B), "none", "inspect 4_b is not active before the 5 s delay (" .. (H.now() - tDone) .. " ms after completion)")

	H.advance(secs(2))

	local alerts = S.createEvents("sendQuestAlert", "SpaceHelpers")

	lu.assertEquals(#alerts, 1, "one split_quest_alert event")
	lu.assertEquals(alerts[1][5], "@spacequest/survival/" .. NAME_4A .. ":split_quest_alert", "alert message")
	lu.assertEquals(chainState(sc.player), "complete/active/none", "chain 6 s after the survival completed")
	lu.assertEquals(sc.spies.start[SURVIVAL], nil, "setup: the three chain members run for real")
end

-- AC-5
function TestCorsecTier3RuntimeChain:test_the_alert_and_the_inspect_start_are_queued_for_the_split_delay_of_5_seconds()
	local sc, tDone = survivalDone()
	local due = {}

	for _, e in ipairs(H.pendingEvents()) do
		if e.method == "sendQuestAlert" or e.method == "startQuest" then
			due[e.method] = e.due - tDone
		end
	end

	lu.assertEquals(due.sendQuestAlert, secs(5), "ms from the completion to the split_quest_alert")
	lu.assertEquals(due.startQuest, 5250, "ms from the completion to inspect:startQuest (alert delay * 1.05, as SpaceQuestLogic does)")
end

-- AC-5
function TestCorsecTier3RuntimeChain:test_docking_with_a_tyrant_of_the_inspect_spawner_completes_4_b_and_starts_delivery_4_c_after_5_seconds()
	local sc = survivalDone()
	local isc = inspectDocked(sc)

	lu.assertEquals(isc:complete(), true, "inspect 4_b is complete after the dock (" .. chainState(sc.player) .. ")")
	lu.assertEquals(chainState(sc.player), "complete/complete/none", "chain right after the dock")

	H.advance(secs(4) + 800)
	lu.assertEquals(state(sc.player, "delivery_no_pickup", NAME_4C), "none", "delivery 4_c is not active before the 5 s delay")

	H.advance(secs(2))
	lu.assertEquals(chainState(sc.player), "complete/complete/active", "chain 6 s after the dock")

	local alerts = S.createEvents("sendQuestAlert", "SpaceHelpers")

	lu.assertEquals(alerts[#alerts][5], "@spacequest/inspect/" .. NAME_4B .. ":split_quest_alert", "the second alert is the inspect quest's")
end

-- AC-5
function TestCorsecTier3RuntimeChain:test_a_tyrant_from_another_spawner_does_not_complete_4_b()
	local sc = survivalDone()

	H.advance(secs(6))

	local isc = I.new(NAME_4B, { spies = sc.spies, player = sc.player })

	isc.tStart = H.now()
	isc:setup()
	isc:dock(isc:target(1, { spawner = "corellia_rebel_tier3_2_other_spawner" }))

	lu.assertEquals(chainState(sc.player), "complete/active/none", "4_b stays active for a tyrant that is not from corellia_privateer_tier3_inspect_spawner")
end

-- AC-5
function TestCorsecTier3RuntimeChain:test_completing_delivery_4_c_starts_no_further_quest()
	local sc = survivalDone()

	inspectDocked(sc)
	H.advance(secs(6))
	lu.assertEquals(chainState(sc.player), "complete/complete/active", "setup: 4_c running")

	local dsc = D.new("delivery_no_pickup", NAME_4C, { spies = sc.spies, player = sc.player })
	local startsBefore = #S.createEvents("startQuest")

	H.advance(secs(2))
	dsc:arrive():at(10000):dock():atDock(2000)

	lu.assertEquals(dsc:complete(), true, "delivery 4_c is complete 2 s after the dock")
	lu.assertEquals(chainState(sc.player), "complete/complete/complete", "chain after the delivery")

	H.advance(secs(30))
	lu.assertEquals(S.called(sc.spies.start), {}, "no other quest starts")
	lu.assertEquals(#S.createEvents("startQuest"), startsBefore, "no startQuest event was created by the last quest")
end
