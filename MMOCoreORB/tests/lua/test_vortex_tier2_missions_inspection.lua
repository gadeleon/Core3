-- Vortex tier 2 part A: the INSPECTION split (SC-1, D-2) and the proof that every other inspect is unchanged (I-9).
-- Spec: .claude/work/vortex-tier2-vrovel-missions/01-spec.md (A-3; Shared code changes SC-1; FV-2; D-2, D-3, D-8; R-1; I-9).
--
-- inspect_vortex_mission_1 hands off after the FIRST cargo inspection (SWG inspect.java:244-282, cargo `placeholder`: no ship carries it, so docking never
-- completes it): 2 s after a /inspect that reports any cargo the inspect ends (the journal entry completes without a client notification, its waypoints and
-- observers go), the split alert is sent and destroy_surpriseattack_vortex_mission_1 starts. The count lives under `<playerID>:<className>:inspectCount:`
-- (D-8). The existing inspects (NONE / COMPLETION / FAILURE / BIDIRECTIONAL) behave exactly as before, however many inspections were made.
--
-- Driven through the inspect scenario of the inspect type feature: H.inspect fires the engine's INSPECTEDSHIP notify, H.advance pumps the 0 ms events.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local I = require("inspect_scenario")

V.load()

local NAME = "vortex_mission_1"
local SPLIT = "destroy_surpriseattack_vortex_mission_1"
local ALERT = "@spacequest/inspect/vortex_mission_1:split_quest_alert"

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

-- the cargo the server's template gives the Lok shuttle (read from the real template file)
local function shuttleCargo()
	local t = H.shipTemplate("vortex_mission_1_shuttle")

	lu.assertNotNil(t, "ship_mobile/ships/vortex_mission_1_shuttle.lua registers a template")
	lu.assertNotNil(t.cargoString, "vortex_mission_1_shuttle.lua has no cargoString: /inspect would report nothing and raise no INSPECTEDSHIP (FV-3, SC-2)")

	return t.cargoString
end

-- inspect 1 set up in space_lok; the other quests' startQuest and failQuest are spies
local function ready()
	V.quest(V.I1)

	local sc = I.fresh(NAME)

	sc:toSetup()

	return sc
end

local function inspectShip(sc, ship, cargo)
	H.inspect(sc.player, ship, getHashCode(cargo))
	pump(0, "inspect of " .. tostring(ship.shipName))
end

TestVrovelInspectionSplit = {}

function TestVrovelInspectionSplit:setUp() H.reset() end

-- A-3: the first inspection of the Lok shuttle (its real template cargo) ends the inspect 2 s later and starts surprise 1
function TestVrovelInspectionSplit:test_the_first_inspection_of_the_shuttle_ends_the_inspect_two_seconds_later_and_starts_surprise_1()
	local sc = ready()
	local cargo = shuttleCargo()

	lu.assertTrue(sc:active(), "inspect 1 is active after setup")
	lu.assertEquals(sc:observers().inspect, 1, "the inspect observer is registered by the setup")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	lu.assertEquals(readData(countKey(sc)), 1, "the first inspection is counted under <playerID>:<className>:inspectCount: (D-8)")
	pump(1800, "inside the 2 s window")
	lu.assertTrue(sc:active(), "inspect 1 is still active 1.8 s after the inspection (sideQuestDelay 2)")
	lu.assertEquals(#sc.spies.start[V.S1], 0, "surprise 1 has not started inside the window")
	pump(400, "the split")
	lu.assertTrue(sc:complete(), "inspect 1 is complete 2.2 s after the inspection")
	lu.assertFalse(sc:active(), "inspect 1 is no longer active")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[V.S1], 1, SPLIT .. ": startQuest calls")
	lu.assertEquals(sc.spies.start[V.S1][1].args[1], sc.player, SPLIT .. ": started for the pilot")
end

-- A-3, D-3: the split completes the entry silently, clears waypoints and observers, and sends the split alert
function TestVrovelInspectionSplit:test_the_split_completes_the_entry_silently_drops_waypoints_and_observers_and_sends_the_alert()
	local sc = ready()
	local cargo = shuttleCargo()

	lu.assertEquals(#sc:waypoints(), 1, "precondition: one waypoint at the shuttle spawner")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(2500, "the split")
	lu.assertEquals(#sc:waypoints(), 0, "the waypoints are gone")
	lu.assertEquals(sc:observers(), { zone = 0, inspect = 0, dock = 0 }, "the zone, inspect and dock observers are dropped")
	lu.assertEquals(alerts(sc.player), { ALERT }, "the split alert (SpaceHelpers:sendQuestAlert)")
	lu.assertEquals(victories(sc.player), 0, "no 'Mission Successful' message: completeQuest(pPlayer, \"false\")")
	lu.assertEquals(readData(countKey(sc)), 0, "the count is cleared with the run (cleanUpQuestData)")
end

-- A-3, R-1: any cargo-carrying ship counts, not only the shuttle (SWG inspect.java:271-282)
function TestVrovelInspectionSplit:test_any_ship_with_a_cargo_counts_for_the_first_inspection()
	local sc = ready()

	inspectShip(sc, carrier("imp_tie_fighter_tier2", "stolen_data"), "stolen_data")
	lu.assertEquals(readData(countKey(sc)), 1, "an inspection of another cargo ship is counted")
	pump(2500, "the split")
	lu.assertTrue(sc:complete(), "inspect 1 is complete after 2 s")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[V.S1], 1, SPLIT .. ": startQuest calls")
end

-- A-3: a second inspection inside the window starts nothing more
function TestVrovelInspectionSplit:test_a_second_inspection_inside_the_window_starts_nothing_more()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(500, "inside the window")
	inspectShip(sc, carrier("imp_tie_fighter_tier2", "stolen_data"), "stolen_data")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(30000, "long after")
	lu.assertEquals(#sc.spies.start[V.S1], 1, SPLIT .. ": startQuest calls after three inspections")
	lu.assertEquals(#alerts(sc.player), 1, "one split alert")
end

-- A-3: an inspection after the split starts nothing
function TestVrovelInspectionSplit:test_an_inspection_after_the_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(5000, "the split")
	lu.assertEquals(#sc.spies.start[V.S1], 1, "precondition: surprise 1 started once")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(30000, "long after")
	lu.assertEquals(#sc.spies.start[V.S1], 1, SPLIT .. ": startQuest calls after an inspection past the split")
	lu.assertEquals(#alerts(sc.player), 1, "one split alert")
	lu.assertEquals(readData(countKey(sc)), 0, "nothing is counted past the split")
end

-- A-3: an inspection before the setup counts for nothing (the observer exists only after the setup)
function TestVrovelInspectionSplit:test_an_inspection_before_the_setup_starts_nothing()
	V.quest(V.I1)

	local sc = I.fresh(NAME)
	local cargo = shuttleCargo()

	sc:start()
	lu.assertEquals(sc:observers().inspect, 0, "precondition: no inspect observer before the setup")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	lu.assertEquals(readData(countKey(sc)), 0, "nothing is counted before the setup")
	pump(30000, "after the setup")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls")
	lu.assertTrue(sc:active(), "inspect 1 is still active (waiting for the first inspection)")
end

-- A-3, D-8: failure during the window clears the count, and the pending split then starts nothing
function TestVrovelInspectionSplit:test_failing_the_inspect_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	lu.assertEquals(readData(countKey(sc)), 1, "precondition: counted")
	sc.quest:failQuest(sc.player, "false")
	lu.assertEquals(readData(countKey(sc)), 0, "failQuest clears the count (cleanUpQuestData)")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls after a failure in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after a failure in the window")
	lu.assertFalse(sc:complete(), "a failed inspect is not complete")
end

-- A-3, D-8: a reset during the window does the same
function TestVrovelInspectionSplit:test_resetting_the_inspect_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	sc.quest:resetQuest(sc.player)
	lu.assertEquals(readData(countKey(sc)), 0, "resetQuest clears the count")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls after a reset in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after a reset in the window")
end

-- A-3, review R-1: a new run set up inside the window has not earned the split (as the escort ATTACK_WAVE guard); its own inspection still does
function TestVrovelInspectionSplit:test_a_run_restarted_inside_the_window_is_not_ended_by_the_old_pending_split()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	sc.quest:resetQuest(sc.player)
	pump(500, "the reset")
	sc:toSetup()
	lu.assertTrue(sc:active(), "the new run is active after its setup")
	pump(30000, "the old pending split")
	lu.assertTrue(sc:active(), "the old split does not end the new run")
	lu.assertFalse(sc:complete(), "the new run is not complete")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls from the old split")
	lu.assertEquals(alerts(sc.player), {}, "no split alert from the old split")
	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	pump(2200, "the new run's split")
	lu.assertTrue(sc:complete(), "the new run's own inspection ends it")
	pump(2000, "the start")
	lu.assertEquals(#sc.spies.start[V.S1], 1, SPLIT .. ": startQuest calls from the new run")
end

-- A-3, D-8: an abort during the window does the same
function TestVrovelInspectionSplit:test_aborting_the_mission_during_the_window_clears_the_count_and_the_pending_split_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	H.abortMission(sc.player, "inspect", NAME)
	lu.assertEquals(readData(countKey(sc)), 0, "the abort clears the count")
	pump(30000, "the pending split")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls after an abort in the window")
	lu.assertEquals(alerts(sc.player), {}, "no split alert after an abort in the window")
end

-- A-3: leaving the zone fails the inspect (as every inspect) and clears the count
function TestVrovelInspectionSplit:test_leaving_the_zone_after_the_setup_fails_the_inspect_and_starts_nothing()
	local sc = ready()
	local cargo = shuttleCargo()

	inspectShip(sc, carrier("vortex_mission_1_shuttle", cargo, "vortex_mission_1_shuttle"), cargo)
	H.zoneSwitch(sc.player, "space_endor", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(30000, "after leaving")
	lu.assertEquals(#sc.spies.start[V.S1], 0, SPLIT .. ": startQuest calls")
	lu.assertEquals(readData(countKey(sc)), 0, "the count is cleared")
end

---------------------------------------------------------------------------------------------
-- I-9: every other inspect is unchanged
---------------------------------------------------------------------------------------------

TestVrovelInspectionCompat = {}

function TestVrovelInspectionCompat:setUp() H.reset() end

-- I-9: no other inspect table uses the INSPECTION split or sets a count
function TestVrovelInspectionCompat:test_no_other_inspect_table_uses_the_inspection_split_or_sets_a_count()
	V.quest(V.I1)

	local inspects = {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if q.questType == "inspect" and name ~= V.I1 then
			inspects[#inspects + 1] = name

			lu.assertNotEquals(q.sideQuestSplitType, 6, name .. ": sideQuestSplitType must not be INSPECTION")
			lu.assertEquals(q.sideQuestInspectCount, 0, name .. ": sideQuestInspectCount is the default 0")
			lu.assertNil(rawget(q, "sideQuestInspectCount"), name .. ": sets no sideQuestInspectCount")
		end
	end

	lu.assertTrue(#inspects >= 20, "inspect tables swept: " .. #inspects)
end

-- I-9: SQL and SIS contain no squadron predicate
function TestVrovelInspectionCompat:test_the_shared_logic_and_the_inspect_type_name_no_squadron()
	for _, file in ipairs({ "SpaceQuestLogic.lua", "SpaceInspectScreenplay.lua" }) do
		local f = assert(io.open(H.SCRIPTS .. "screenplays/space/" .. file, "r"))
		local text = f:read("a")

		f:close()
		lu.assertNil(text:find("[Ss]quadron"), file .. ": mentions a squadron (I-9: SC-1 adds no squadron predicate)")
		lu.assertNil(text:find("[Vv]ortex"), file .. ": mentions Vortex")
	end
end

-- I-9: an existing COMPLETION inspect completes only by docking with matching cargo, however many inspections were made, and splits as before
function TestVrovelInspectionCompat:test_an_existing_completion_inspect_ignores_the_inspection_count_and_still_splits_after_docking()
	local sc = I.fresh("tatooine_imperial_tier3_2"):toSetup()
	local o = sc.o

	lu.assertEquals(sc.quest.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.COMPLETION, "precondition: a COMPLETION inspect")

	for i = 1, 3 do
		local other = H.worldAgent({ shipName = "imp_tie_fighter_tier2", cargo = "stolen_data", spawner = "some_spawner_" .. i, zone = o.zone })

		H.inspect(sc.player, other, getHashCode("stolen_data"))
		pump(0, "inspection " .. i)
	end

	pump(60000, "long after the inspections")
	lu.assertTrue(sc:active(), "still active after three inspections of other cargo")
	lu.assertFalse(sc:complete(), "not complete after three inspections")
	lu.assertEquals(#sc.spies.start[o.sideGlobal], 0, o.sideGlobal .. ": not started by inspections")
	lu.assertEquals(readData(sc.player.objectID .. ":" .. sc.className .. ":inspectCount:"), 0, "no inspection count is kept")

	local target = sc:target()

	sc:inspect(target)
	sc:dock(target)
	lu.assertTrue(sc:complete(), "complete after inspecting and docking with the quest cargo")
	pump((o.triggerDelay + 5) * 1050 + 200, "the COMPLETION split")
	lu.assertEquals(#sc.spies.start[o.sideGlobal], 1, o.sideGlobal .. ": started once, triggerDelay + 5 s after the dock (as before)")
end

-- I-9: inspecting the quest's own cargo of an existing inspect still returns 1 and drops the inspect observer (the engine contract is unchanged)
function TestVrovelInspectionCompat:test_an_existing_inspect_keeps_the_found_cargo_contract()
	local sc = I.fresh("tatooine_imperial_tier3_2"):toSetup()
	local ship = sc:target()

	lu.assertEquals(sc.quest:inspectedShip(sc.player, ship, sc:hash()), 1, "inspectedShip returns 1 for the quest cargo")
	lu.assertEquals(sc.quest:inspectedShip(sc.player, sc:target(), getHashCode("stolen_data")), 0, "inspectedShip returns 0 for other cargo (the observer stays)")
	pump(0, "events")
	lu.assertTrue(sc:active(), "still active")
end

return nil
