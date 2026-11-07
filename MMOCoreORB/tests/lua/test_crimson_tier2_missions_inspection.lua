-- Crimson Phoenix tier 2 part A: mission 3 (inspect_yavin_rebel_15) runs on the shared INSPECTION split, and exactly two inspects use it (I-9).
-- Spec: .claude/work/crimson-phoenix-tier2-eker/01-spec.md (A-3; FC-1, FC-2; D-2, D-7; R-1; I-9).
--
-- inspect_yavin_rebel_15 hands off after the FIRST cargo inspection (SWG inspect.java:244-282, cargo `placeholder`: no ship carries it, so docking never
-- completes it): 5 s after a /inspect that reports any cargo the inspect ends (the journal entry completes without a client notification, its waypoints and
-- observers go), the split alert is sent and destroy_surpriseattack_yavin_rebel_15 starts. The split itself was added by vortex-tier2-vrovel-missions
-- (test_vortex_tier2_missions_inspection.lua); this file proves the second user, a chain head with the reward fields and a 5 s delay, and that it pays nothing.
--
-- Driven through the inspect scenario: H.inspect fires the engine's INSPECTEDSHIP notify, H.advance pumps the 0 ms events.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local I = require("inspect_scenario")

E.load()

local NAME = "yavin_rebel_15"
local SPLIT = "destroy_surpriseattack_yavin_rebel_15"
local ALERT = "@spacequest/inspect/yavin_rebel_15:split_quest_alert"
local SPAWNER = "yavin_rebel_mission_3"
local WINDOW = 5000

-- the templates of the reward items handed out so far (mission and datapad objects are not rewards)
local function rewardItems()
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		if type(call[2]) == "string" and call[2]:find("^object/tangible/") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function countKey(sc) return sc.player.objectID .. ":" .. sc.className .. ":inspectCount:" end

local function alerts(player)
	local out = {}

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_alert_s" then
			out[#out + 1] = m.TO
		end
	end

	return out
end

local function victories(player)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_won" then
			n = n + 1
		end
	end

	return n
end

-- a ship carrying `cargo` (a cargo name; any cargo-carrying ship raises INSPECTEDSHIP, PSQ:413-425)
local function carrier(shipName, cargo, spawner)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = spawner, zone = "space_lok" })
end

-- the cargo the server's template gives the Lok shuttle (read from the real template file, SC-1)
local function shuttleCargo()
	local t = H.shipTemplate("yavin_mission_3_shuttle")

	lu.assertNotNil(t, "ship_mobile/ships/yavin_mission_3_shuttle.lua registers a template")
	lu.assertNotNil(t.cargoString, "yavin_mission_3_shuttle.lua has no cargoString: /inspect would report nothing and raise no INSPECTEDSHIP (FC-2, SC-1)")

	return t.cargoString
end

-- inspect 15 set up in space_lok; the other quests' startQuest and failQuest are spies
local function ready()
	E.quest(E.I15)

	local sc = I.fresh(NAME)

	sc:toSetup()

	return sc
end

local function inspectShip(sc, ship, cargo)
	H.inspect(sc.player, ship, getHashCode(cargo))
	pump(0, "inspect of " .. tostring(ship.shipName))
end

local function shuttle(cargo) return carrier("yavin_mission_3_shuttle", cargo, SPAWNER) end

TestEkerInspectionSplit = {}

function TestEkerInspectionSplit:setUp() H.reset() end

-- A-3: the first inspection of the Lok shuttle (its real template cargo) ends the inspect 5 s later and starts surprise 15
function TestEkerInspectionSplit:test_the_first_inspection_of_the_shuttle_ends_the_inspect_five_seconds_later_and_starts_surprise_15()
	local sc = ready()
	local cargo = shuttleCargo()

	lu.assertTrue(sc:active(), "inspect 15 is active after setup")
	lu.assertEquals(sc:observers().inspect, 1, "the inspect observer is registered by the setup")
	inspectShip(sc, shuttle(cargo), cargo)
	lu.assertEquals(readData(countKey(sc)), 1, "the first inspection is counted under <playerID>:<className>:inspectCount: (D-8)")
	pump(4800, "inside the 5 s window")
	lu.assertTrue(sc:active(), "inspect 15 is still active 4.8 s after the inspection (sideQuestDelay 5)")
	lu.assertEquals(#sc.spies.start[E.S15], 0, "surprise 15 has not started inside the window")
	pump(400, "the split")
	lu.assertTrue(sc:complete(), "inspect 15 is complete 5.2 s after the inspection")
	lu.assertFalse(sc:active(), "inspect 15 is no longer active")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[E.S15], 1, SPLIT .. ": startQuest calls")
	lu.assertEquals(sc.spies.start[E.S15][1].args[1], sc.player, SPLIT .. ": started for the pilot")
end

-- A-3, D-3: the split completes the entry silently, clears waypoints and observers, and sends the split alert
function TestEkerInspectionSplit:test_the_split_completes_the_entry_silently_drops_waypoints_and_observers_and_sends_the_alert()
	local sc = ready()
	local cargo = shuttleCargo()

	lu.assertEquals(#sc:waypoints(), 1, "precondition: one waypoint at the shuttle spawner")
	inspectShip(sc, shuttle(cargo), cargo)
	pump(5500, "the split")
	lu.assertEquals(#sc:waypoints(), 0, "the waypoints are gone")
	lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, "the zone, inspect and dock observers are dropped")
	lu.assertEquals(alerts(sc.player), { ALERT }, "the split alert (SpaceHelpers:sendQuestAlert)")
	lu.assertEquals(victories(sc.player), 0, "no 'Mission Successful' message: completeQuest(pPlayer, \"false\")")
	lu.assertEquals(readData(countKey(sc)), 0, "the count is cleared with the run (cleanUpQuestData)")
end

-- A-3, R-1: any cargo-carrying ship counts, not only the shuttle (SWG inspect.java:271-282)
function TestEkerInspectionSplit:test_any_ship_with_a_cargo_counts_for_the_first_inspection()
	local sc = ready()

	inspectShip(sc, carrier("imp_tie_fighter_tier2", "stolen_data"), "stolen_data")
	lu.assertEquals(readData(countKey(sc)), 1, "an inspection of another cargo ship is counted")
	pump(5500, "the split")
	lu.assertTrue(sc:complete(), "inspect 15 is complete after 5 s")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[E.S15], 1, SPLIT .. ": startQuest calls")
end

-- A-3: a second inspection inside the window starts nothing more
function TestEkerInspectionSplit:test_a_second_inspection_inside_the_window_starts_nothing_more()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	pump(500, "inside the window")
	inspectShip(sc, carrier("imp_tie_fighter_tier2", "stolen_data"), "stolen_data")
	inspectShip(sc, shuttle(cargo), cargo)
	pump(30000, "long after")
	lu.assertEquals(#sc.spies.start[E.S15], 1, SPLIT .. ": startQuest calls after three inspections")
	lu.assertEquals(#alerts(sc.player), 1, "one split alert")
end

-- A-3: an inspection after the split starts nothing
function TestEkerInspectionSplit:test_an_inspection_after_the_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	pump(8000, "the split")
	lu.assertEquals(#sc.spies.start[E.S15], 1, "precondition: surprise 15 started once")
	inspectShip(sc, shuttle(cargo), cargo)
	pump(30000, "long after")
	lu.assertEquals(#sc.spies.start[E.S15], 1, SPLIT .. ": startQuest calls after an inspection past the split")
	lu.assertEquals(#alerts(sc.player), 1, "one split alert")
	lu.assertEquals(readData(countKey(sc)), 0, "nothing is counted past the split")
end

-- A-3: an inspection before the setup counts for nothing (the observer exists only after the setup)
function TestEkerInspectionSplit:test_an_inspection_before_the_setup_starts_nothing()
	E.quest(E.I15)

	local sc = I.fresh(NAME)
	local cargo = shuttleCargo()

	sc:start()
	lu.assertEquals(sc:observers().inspect, 0, "precondition: no inspect observer before the setup")
	inspectShip(sc, shuttle(cargo), cargo)
	lu.assertEquals(readData(countKey(sc)), 0, "nothing is counted before the setup")
	pump(30000, "after the setup")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls")
	lu.assertTrue(sc:active(), "inspect 15 is still active (waiting for the first inspection)")
end

-- A-3, D-8: failure during the window clears the count, and the pending split then starts nothing
function TestEkerInspectionSplit:test_failing_the_inspect_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	lu.assertEquals(readData(countKey(sc)), 1, "precondition: counted")
	sc.quest:failQuest(sc.player, "false")
	lu.assertEquals(readData(countKey(sc)), 0, "failQuest clears the count (cleanUpQuestData)")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls after a failure in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after a failure in the window")
	lu.assertFalse(sc:complete(), "a failed inspect is not complete")
end

-- A-3, D-8: a reset during the window does the same
function TestEkerInspectionSplit:test_resetting_the_inspect_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	sc.quest:resetQuest(sc.player)
	lu.assertEquals(readData(countKey(sc)), 0, "resetQuest clears the count")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls after a reset in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after a reset in the window")
end

-- A-3, review R-1: a new run set up inside the window has not earned the split (as the escort ATTACK_WAVE guard); its own inspection still does
function TestEkerInspectionSplit:test_a_run_restarted_inside_the_window_is_not_ended_by_the_old_pending_split()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	sc.quest:resetQuest(sc.player)
	pump(500, "the reset")
	sc:toSetup()
	lu.assertTrue(sc:active(), "the new run is active after its setup")
	pump(30000, "the old pending split")
	lu.assertTrue(sc:active(), "the old split does not end the new run")
	lu.assertFalse(sc:complete(), "the new run is not complete")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls from the old split")
	lu.assertEquals(alerts(sc.player), {}, "no split alert from the old split")
	inspectShip(sc, shuttle(cargo), cargo)
	pump(5200, "the new run's split")
	lu.assertTrue(sc:complete(), "the new run's own inspection ends it")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[E.S15], 1, SPLIT .. ": startQuest calls from the new run")
end

-- A-3, D-8: an abort during the window does the same
function TestEkerInspectionSplit:test_aborting_the_mission_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	H.abortMission(sc.player, "inspect", NAME)
	lu.assertEquals(readData(countKey(sc)), 0, "the abort clears the count")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls after an abort in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after an abort in the window")
end

-- A-3: leaving the zone fails the inspect (as every inspect) and clears the count
function TestEkerInspectionSplit:test_leaving_the_zone_after_the_setup_fails_the_inspect_and_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	H.zoneSwitch(sc.player, "space_endor", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(30000, "after leaving")
	lu.assertEquals(#sc.spies.start[E.S15], 0, SPLIT .. ": startQuest calls")
	lu.assertEquals(readData(countKey(sc)), 0, "the count is cleared")
end


-- A-3, FC-1: the split pays nothing: no credits, no items (rewards are the trainer handler's, never completeQuest's), for the pilot of the run
function TestEkerInspectionSplit:test_the_split_pays_no_credits_and_hands_out_no_items()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, shuttle(cargo), cargo)
	pump(8000, "the split and the start")
	lu.assertTrue(sc:complete(), "precondition: inspect 15 is complete")
	lu.assertEquals(#sc.spies.start[E.S15], 1, "precondition: surprise 15 started")
	lu.assertEquals(sc.player.bankCredits or 0, 0, "bank credits paid by the split")
	lu.assertEquals(#(sc.player.bankCreditLog or {}), 0, "addBankCredits calls")
	lu.assertEquals(rewardItems(), {}, "reward items handed out (giveItem of an object/tangible template)")
end

-- A-3, D-7: the shuttle's bomb_trigger cargo (canTransfer 0 in SWG's table) still raises INSPECTEDSHIP and is counted
function TestEkerInspectionSplit:test_the_bomb_trigger_cargo_of_the_template_is_counted_although_it_cannot_be_transferred()
	local sc = ready()

	lu.assertEquals(shuttleCargo(), "bomb_trigger", "the template cargo of yavin_mission_3_shuttle")
	inspectShip(sc, shuttle("bomb_trigger"), "bomb_trigger")
	lu.assertEquals(readData(countKey(sc)), 1, "the bomb_trigger inspection is counted")
end

---------------------------------------------------------------------------------------------
-- I-9: exactly two inspects use the INSPECTION split; every other inspect is unchanged
---------------------------------------------------------------------------------------------

TestEkerInspectionCompat = {}

function TestEkerInspectionCompat:setUp() H.reset() end

-- I-9: among all inspect globals, exactly inspect_vortex_mission_1 and inspect_yavin_rebel_15 use INSPECTION or set a count
function TestEkerInspectionCompat:test_exactly_two_inspect_tables_use_the_inspection_split_or_set_a_count()
	E.quest(E.I15)

	local users, others = {}, 0
	local INSPECTION = SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.INSPECTION

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if q.questType == "inspect" then
			if q.sideQuestSplitType == INSPECTION or rawget(q, "sideQuestInspectCount") ~= nil then
				users[#users + 1] = name
			else
				others = others + 1
				lu.assertEquals(q.sideQuestInspectCount, 0, name .. ": sideQuestInspectCount is the default 0")
			end
		end
	end

	table.sort(users)
	lu.assertEquals(users, { "inspect_vortex_mission_1", "inspect_yavin_rebel_15" }, "inspect tables using the INSPECTION split (I-9)")
	lu.assertTrue(others >= 20, "other inspect tables swept: " .. others)
end

-- I-9: inspect 15 is a chain head, not a child (the only difference from inspect_vortex_mission_1, FC-1)
function TestEkerInspectionCompat:test_inspect_15_is_a_chain_head_with_the_reward_fields_where_vortex_1_is_a_child()
	local q15, v1 = E.quest(E.I15), H.expectGlobal("inspect_vortex_mission_1", "Vortex inspect 1")

	lu.assertNil(rawget(q15, "parentQuest"), "inspect 15 has no parentQuest")
	lu.assertEquals(rawget(q15, "creditReward"), 5000, "inspect 15 carries the M3 credit reward")
	lu.assertNotNil(rawget(v1, "parentQuest"), "inspect_vortex_mission_1 still has its parent")
	lu.assertNil(rawget(v1, "creditReward"), "inspect_vortex_mission_1 still carries no reward")
	lu.assertEquals({ v1.sideQuestInspectCount, v1.sideQuestDelay }, { 1, 2 }, "inspect_vortex_mission_1: count 1, delay 2 (unchanged)")
end

return nil
