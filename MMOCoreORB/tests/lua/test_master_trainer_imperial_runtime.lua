-- Imperial master trainer: the two Kessel quests run through the fakes (kill observer, no waypoint, kill counts, leaving the zone, the corvette).
-- Spec: .claude/work/space-master-trainer-imperial/01-spec.md (AC-3; AC-7 for the real retry after a zone-leave failure).
--
-- Quests are driven by the event clock: pump(ms) runs H.advance inside pcall so a Lua error in an event reads as "no Lua error".
-- (Amendment A-1: the master quests never fail on leaving Kessel; see the A-1 tests.) A destroy quest only fails on leaving its zone once task 1 is active, which the first counted kill activates (SpaceDestroyScreenplay:enteredZone).

-- space-master-mission-quest-type: the four master missions now run on SpaceMasterDestroyScreenplay (progress kept in screenplay data, no failOnLeaveZone);
-- the kill count is read with the `count` helper below. The new type's own behavior is tested in test_master_mission_quest_type_*.lua.

local lu = require("luaunit")
local H = require("harness")
local DRS = require("duty_rules_scenario")
local M = require("master_trainer_imperial_data")

M.load()

local ONE, TWO = "destroy_master_imperial_1", "destroy_master_imperial_2"
local ZONE = "space_light1"

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

-- space-master-mission-quest-type: the kill count is screenplay data on the PlayerObject (it survives a restart), no longer shared memory
local function count(player, global) return tonumber(readScreenPlayData(player, global, "killCount")) or 0 end

-- An Imperial pilot in a ship in Kessel who starts `global` (the quest's own startQuest, as the trainer does)
local function started(global)
	local q = M.quest(global)

	H.reset()

	local player = M.pilot({ inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = ZONE, inventory = true })

	q:startQuest(player, "")
	H.advance(0)

	return q, player
end

local function kill(player, shipName)
	H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = shipName, zone = ZONE }))
	pump(1500, "after the kill of " .. shipName)
end

TestMasterTrainerImperialRuntime = {}

function TestMasterTrainerImperialRuntime:setUp() H.reset() end

-- AC-3 (a)
function TestMasterTrainerImperialRuntime:test_starting_mission_1_makes_it_active_and_entering_kessel_arms_the_kill_observer_without_a_waypoint()
	local q, player = started(ONE)

	lu.assertTrue(isActive(player, q), ONE .. ": active after startQuest")

	H.zoneSwitch(player, ZONE)
	pump(500, ONE .. " zone entry")

	lu.assertTrue(H.hasObserver(DESTROYEDSHIP, ONE, "notifyDestroyedShip", player), ONE .. ": the ship-destruction observer is armed once the pilot is in " .. ZONE)
	lu.assertEquals(#player.ghost.waypoints, 0, ONE .. ": no waypoint (giveSpawnWaypoint 0, as in SWG)")
end

-- AC-3 (a)
function TestMasterTrainerImperialRuntime:test_starting_mission_2_adds_no_waypoint_either()
	local q, player = started(TWO)

	lu.assertTrue(isActive(player, q), TWO .. ": active after startQuest")
	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " zone entry")
	lu.assertTrue(H.hasObserver(DESTROYEDSHIP, TWO, "notifyDestroyedShip", player), TWO .. ": the ship-destruction observer is armed")
	lu.assertEquals(#player.ghost.waypoints, 0, TWO .. ": no waypoint")
end

-- AC-3 (b): 29 kills leave it active, the 30th completes it
function TestMasterTrainerImperialRuntime:test_twenty_nine_kills_of_listed_ships_leave_mission_1_active_and_the_thirtieth_completes_it()
	local q, player = started(ONE)
	local ships = M.shipList(ONE)

	H.zoneSwitch(player, ZONE)
	pump(500, ONE .. " zone entry")

	for i = 1, 29 do
		kill(player, ships[(i - 1) % #ships + 1])
	end

	lu.assertTrue(isActive(player, q), ONE .. ": still active after 29 kills")
	lu.assertFalse(isComplete(player, q), ONE .. ": not complete after 29 kills")

	kill(player, ships[1])
	pump(1000, ONE .. " completion")

	lu.assertTrue(isComplete(player, q), ONE .. ": complete after the 30th kill")
	lu.assertFalse(isActive(player, q), ONE .. ": no longer active")
end

-- AC-3 (b): every one of the eight listed names counts
function TestMasterTrainerImperialRuntime:test_each_of_the_eight_listed_ship_names_counts_as_a_kill()
	local q, player = started(ONE)
	local ships = M.shipList(ONE)

	H.zoneSwitch(player, ZONE)

	for i, name in ipairs(ships) do
		kill(player, name)
		lu.assertEquals(count(player, ONE), i, ONE .. ": kill count after " .. name)
	end

	lu.assertTrue(isActive(player, q), ONE .. ": still active after 8 kills")
end

-- AC-3 (b): an unlisted type does not count
function TestMasterTrainerImperialRuntime:test_a_kill_of_an_unlisted_ship_does_not_count()
	local q, player = started(ONE)

	H.zoneSwitch(player, ZONE)
	kill(player, "imp_tie_fighter_tier5")
	kill(player, "reb_corellian_corvette_tier4")
	kill(player, "reb_xwing_cadet_tier1")

	lu.assertEquals(count(player, ONE), 0, ONE .. ": kill count after three unlisted kills")
	lu.assertTrue(isActive(player, q), ONE .. ": still active")
end

-- AC-3 (b): 30 unlisted kills complete nothing
function TestMasterTrainerImperialRuntime:test_thirty_unlisted_kills_complete_nothing()
	local q, player = started(ONE)

	H.zoneSwitch(player, ZONE)

	for _ = 1, 30 do
		kill(player, "imp_tie_fighter_tier5")
	end

	pump(1000, ONE .. " after 30 unlisted kills")
	lu.assertFalse(isComplete(player, q), ONE .. ": not complete")
end

-- A-1 (c1): leaving Kessel never fails mission 1, before or after a kill; the kill count is kept
function TestMasterTrainerImperialRuntime:test_leaving_kessel_does_not_fail_mission_1_and_keeps_the_kill_count()
	for _, kills in ipairs({ 0, 2 }) do
		local q, player = started(ONE)
		local ships = M.shipList(ONE)

		H.zoneSwitch(player, ZONE)
		pump(500, ONE .. " zone entry")

		for i = 1, kills do
			kill(player, ships[i])
		end

		H.zoneSwitch(player, "space_corellia")
		pump(5000, ONE .. " leaving the zone")

		lu.assertTrue(isActive(player, q), ONE .. ": still active after leaving with " .. kills .. " kills")
		lu.assertFalse(isComplete(player, q), ONE .. ": not complete")
		lu.assertEquals(count(player, ONE), kills, ONE .. ": kill count kept after leaving (" .. kills .. " kills)")
		lu.assertEquals(M.state(player, ONE), "active", ONE .. ": journal entry stays active")
		H.reset()
	end
end

-- A-1 (c1): leaving and returning more than once, the next talk is on_master_mission, never m1_failed
function TestMasterTrainerImperialRuntime:test_after_leaving_kessel_the_next_talk_opens_on_master_mission()
	local q, player = started(ONE)

	H.zoneSwitch(player, ZONE)
	kill(player, "reb_xwing_tier5")
	H.zoneSwitch(player, "space_corellia")
	pump(5000, ONE .. " leaving the zone")
	H.zoneSwitch(player, "space_dantooine")
	pump(5000, ONE .. " leaving again")

	M.requireConversation(lu)
	player.ghost.journalActive[M.crc(ONE)] = true
	lu.assertEquals(M.talk(player)[1].id, "on_master_mission", "the next talk")
end

-- A-1 (c2): returning to Kessel and killing continues the count to completion
function TestMasterTrainerImperialRuntime:test_returning_to_kessel_resumes_the_count_to_completion()
	local q, player = started(ONE)
	local ships = M.shipList(ONE)

	H.zoneSwitch(player, ZONE)
	pump(500, ONE .. " zone entry")

	for i = 1, 10 do
		kill(player, ships[(i - 1) % #ships + 1])
	end

	H.zoneSwitch(player, "space_corellia")
	pump(5000, ONE .. " leaving the zone")
	H.zoneSwitch(player, ZONE)
	pump(500, ONE .. " returning")
	lu.assertTrue(isActive(player, q), ONE .. ": active after returning")
	lu.assertEquals(count(player, ONE), 10, ONE .. ": count kept")

	for i = 1, 19 do
		kill(player, ships[i % #ships + 1])
	end

	lu.assertFalse(isComplete(player, q), ONE .. ": 29 kills in total are not enough")
	kill(player, ships[1])
	pump(1000, ONE .. " completion")
	lu.assertTrue(isComplete(player, q), ONE .. ": complete with the 30th kill, 10 before and 20 after the trip")
end

-- A-1: kills count only while the pilot is in Kessel
function TestMasterTrainerImperialRuntime:test_a_kill_made_outside_kessel_does_not_count()
	local q, player = started(ONE)

	H.zoneSwitch(player, ZONE)
	kill(player, "reb_xwing_tier5")
	H.zoneSwitch(player, "space_corellia")
	pump(500, ONE .. " leaving")
	player.zone = "space_corellia"
	H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "reb_xwing_tier5", zone = "space_corellia" }))
	pump(1500, ONE .. " kill outside")
	lu.assertEquals(count(player, ONE), 1, ONE .. ": a kill outside space_light1 is not counted")
end

-- A-1 (c3): the same for mission 2
function TestMasterTrainerImperialRuntime:test_leaving_kessel_does_not_fail_mission_2_and_the_corvette_kill_after_returning_completes_it()
	local q, player = started(TWO)

	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " zone entry")
	H.zoneSwitch(player, "space_corellia")
	pump(5000, TWO .. " leaving the zone")
	lu.assertTrue(isActive(player, q), TWO .. ": still active after leaving")
	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " returning")
	kill(player, "reb_corellian_corvette_tier4")
	pump(1000, TWO .. " completion")
	lu.assertTrue(isComplete(player, q), TWO .. ": complete after the corvette kill on return")
end

-- A-1 (c4): an existing destroy quest still fails on leaving its zone
function TestMasterTrainerImperialRuntime:test_an_existing_destroy_quest_still_fails_on_leaving_its_zone()
	local q = M.quest("destroy_corellia_imperial_2")

	H.reset()

	local player = M.pilot({ inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y }, zone = q.questZone })

	q:startQuest(player, "")
	H.advance(0)
	H.zoneSwitch(player, q.questZone)
	pump(500, "zone entry")
	H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = q.shipTypes[1], zone = q.questZone }))
	pump(1500, "first kill")
	lu.assertTrue(isActive(player, q), "precondition: active")
	H.zoneSwitch(player, "space_lok")
	pump(5000, "leaving the zone")
	lu.assertFalse(isActive(player, q), "destroy_corellia_imperial_2 fails on leaving its zone (failOnLeaveZone defaults to true)")
	lu.assertNil(rawget(q, "failOnLeaveZone"), "the existing table does not set the field")
end

-- space-master-mission-quest-type: the A-1 field tests (failOnLeaveZone default true / false on the tables) are superseded by
-- test_master_mission_quest_type_type.lua (AC-1, AC-2): SDS is stock again and the tables sit on SpaceMasterDestroyScreenplay.

-- AC-3 (d): one corvette kill completes mission 2
function TestMasterTrainerImperialRuntime:test_one_corvette_kill_completes_mission_2()
	local q, player = started(TWO)

	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " zone entry")
	kill(player, "reb_corellian_corvette_tier4")
	pump(1000, TWO .. " completion")

	lu.assertTrue(isComplete(player, q), TWO .. ": complete after one reb_corellian_corvette_tier4 kill")
	lu.assertFalse(isActive(player, q), TWO .. ": no longer active")
end

-- AC-3 (d): other ships do not complete mission 2
function TestMasterTrainerImperialRuntime:test_other_ships_do_not_complete_mission_2()
	local q, player = started(TWO)

	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " zone entry")

	for _, name in ipairs(M.shipList(ONE)) do
		kill(player, name)
	end

	pump(1000, TWO .. " after the mission 1 ships")
	lu.assertFalse(isComplete(player, q), TWO .. ": the Rebel fighters do not count for the corvette mission")
end

-- AC-3: the kill counts of the two missions are separate
function TestMasterTrainerImperialRuntime:test_mission_1_kills_do_not_touch_the_mission_2_count()
	local q1, player = started(ONE)
	local q2 = M.quest(TWO)

	H.zoneSwitch(player, ZONE)
	kill(player, "reb_xwing_tier5")
	lu.assertEquals(count(player, TWO), 0, TWO .. ": kill count is untouched by mission 1's kills")
	lu.assertFalse(isActive(player, q2), TWO .. ": not started by mission 1")
	lu.assertTrue(isActive(player, q1), ONE .. ": still active")
end

---------------------------------------------------------------------------------------------
-- Review 04 R-2: kills outside Kessel, with task 1 inactive, and re-arming on return
---------------------------------------------------------------------------------------------

local function goTo(player, zone, label)
	H.zoneSwitch(player, zone)
	pump(5000, label)
	player.zone = zone
end

-- R-2 (a): a corvette killed in space_heavy1 does not complete mission 2; the one killed in Kessel does
function TestMasterTrainerImperialRuntime:test_a_corvette_killed_in_space_heavy1_does_not_complete_mission_2_but_one_killed_in_kessel_does()
	local q, player = started(TWO)

	H.zoneSwitch(player, ZONE)
	pump(500, TWO .. " zone entry")
	goTo(player, "space_heavy1", TWO .. " moving to space_heavy1")
	H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "reb_corellian_corvette_tier4", zone = "space_heavy1" }))
	pump(2000, TWO .. " kill in space_heavy1")
	lu.assertTrue(isActive(player, q), TWO .. ": still active after a corvette kill in space_heavy1")
	lu.assertFalse(isComplete(player, q), TWO .. ": not complete after a corvette kill in space_heavy1")

	goTo(player, ZONE, TWO .. " returning")
	kill(player, "reb_corellian_corvette_tier4")
	pump(1000, TWO .. " completion")
	lu.assertTrue(isComplete(player, q), TWO .. ": complete with the corvette killed in Kessel")
end

-- R-2 (b): mission 1 with no kill yet: a listed ship killed outside Kessel is not counted, a Kessel kill after returning is
function TestMasterTrainerImperialRuntime:test_mission_1_with_no_kill_yet_ignores_kills_outside_kessel_and_counts_them_on_return()
	local q, player = started(ONE)

	H.zoneSwitch(player, ZONE)
	pump(500, ONE .. " zone entry")
	goTo(player, "space_heavy1", ONE .. " moving to space_heavy1")
	H.fireObservers(DESTROYEDSHIP, player, H.worldAgent({ shipName = "reb_xwing_tier5", zone = "space_heavy1" }))
	pump(1500, ONE .. " kill in space_heavy1")
	lu.assertEquals(count(player, ONE), 0, ONE .. ": a kill outside Kessel with 0 kills so far is not counted")
	lu.assertTrue(isActive(player, q), ONE .. ": still active")

	goTo(player, ZONE, ONE .. " returning")
	kill(player, "reb_xwing_tier5")
	lu.assertEquals(count(player, ONE), 1, ONE .. ": a Kessel kill after returning counts")
end

-- R-2 (c): the kill observer is lost (a restart, or an unload); entering Kessel again re-arms it although task 1 is not active
for _, global in ipairs({ ONE, TWO }) do
	TestMasterTrainerImperialRuntime["test_entering_kessel_rearms_the_kill_observer_after_it_was_lost_for_" .. global] = function()
		local q, player = started(global)
		local ship = M.shipList(global)[1]

		H.zoneSwitch(player, ZONE)
		pump(500, global .. " zone entry")
		dropObserver(DESTROYEDSHIP, global, "notifyDestroyedShip", player)
		lu.assertFalse(H.hasObserver(DESTROYEDSHIP, global, "notifyDestroyedShip", player), global .. ": precondition: observer lost")
		goTo(player, "space_heavy1", global .. " leaving")
		goTo(player, ZONE, global .. " returning")

		lu.assertTrue(H.hasObserver(DESTROYEDSHIP, global, "notifyDestroyedShip", player), global .. ": the observer is armed again on entering Kessel")
		kill(player, ship)
		pump(1000, global .. " after the kill")

		if global == TWO then
			lu.assertTrue(isComplete(player, q), global .. ": the corvette kill counts")
		else
			lu.assertEquals(count(player, global), 1, global .. ": the kill counts")
		end
	end
end
