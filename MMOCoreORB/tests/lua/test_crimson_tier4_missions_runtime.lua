-- Crimson Phoenix tier 4 part A: General Ufwol's four missions and four duties run through the fakes, split by split, both ways.
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol-missions/01-spec.md (A-3, A-4, A-5; Data mapping 1; FF-1, FF-2, FF-3, FF-5; D-3, D-7; R-1, R-3, R-7, R-8).
--
-- The oracle values are the spec's literals (crimson_tier4_data.lua, proven equal to the SWG .tab fixtures by test_crimson_tier4_missions_data.lua); the quest
-- tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside an
-- event shows up as "no Lua error" and not as a later, unrelated assertion. For a split the test completes (or fails) the head through its own completeQuest /
-- failQuest and pumps the split delay: the alert fires at the delay and the next quest starts at delay * 1.05, so "not active 1 s before the delay" and "active
-- 2 s after it" bracket the delay. Every split also shows that the OTHER branch is never started (no startQuest event queued for it, not active). Flying the
-- survivals and the battles is covered by their type features: this file stops at "active / spawned" for them. The first BIDIRECTIONAL recovery (recovery 2)
-- and the cross-zone failure split (assassinate 4 in Endor to battle 4_b in Dathomir) are run in full. The hostility of the real AI (R-4) cannot be checked
-- here; Part B carries the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local U = require("crimson_tier4_data")
local D = require("delivery_scenario")

U.load()
D.load()

local function quest(global) return U.quest(global) end

local function pump(ms, label)
	local ok, err = pcall(H.advance, ms)

	lu.assertTrue(ok, label .. ": a Lua error inside an event: " .. tostring(err))
end

local function shipNames(ships)
	local out = {}

	for i, ship in ipairs(ships) do
		out[i] = ship.shipName
	end

	return out
end

local function countOf(names, wanted)
	local n = 0

	for _, name in ipairs(names) do
		if name == wanted then
			n = n + 1
		end
	end

	return n
end

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end
local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local function waypointsAt(player, x, z, y)
	local n = 0

	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == x and w.z == z and w.y == y then
			n = n + 1
		end
	end

	return n
end

local function pointOf(zone, name)
	local p = U.POINTS[zone][name]

	assert(p ~= nil, "no spec point " .. name .. " in " .. zone)
	return p
end

-- A fresh world with the static areas of every member of the list, and the pilot in a Rebel ship in the first member's zone (or `zone`)
local function world(members, zone)
	H.reset()

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery_duty" or quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return U.flyer(zone or U.IDENTITY[members[1]].zone)
end

local function chain(n) return world(U.CHAINS[n]) end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Number of startQuest events queued (since the last reset) for `global`
local function startEventsFor(global)
	local n = 0

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[2] == global and c[3] == "startQuest" then
			n = n + 1
		end
	end

	return n
end

-- Brackets a split: `child` is not active 1 s before `seconds` and is active 2 s after it; `other` (the other branch) is never started
local function assertSplit(player, from, child, other, seconds)
	local nq = quest(child)

	pump((seconds - 1) * 1000, from .. " split delay")
	lu.assertFalse(isActive(player, nq), child .. ": not active " .. (seconds - 1) .. " s after " .. from .. " ended (sideQuestDelay " .. seconds .. " s)")
	pump(3000, from .. " split start")
	lu.assertTrue(isActive(player, nq), child .. ": active " .. (seconds + 2) .. " s after " .. from .. " ended")

	if other then
		lu.assertFalse(isActive(player, quest(other)), other .. ": the other branch is not active after " .. from .. " split to " .. child)
		lu.assertEquals(startEventsFor(other), 0, other .. ": no startQuest was queued for the other branch of " .. from)
	end
end

-- Completes a member through its own completeQuest, then brackets the split to `child` (and never `other`)
local function completeAndSplit(player, global, child, other, seconds)
	local q = quest(global)

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")
	assertSplit(player, global, child, other, seconds or 5)
end

-- Fails a member through its own failQuest ("true"), then brackets the split to `child` (and never `other`)
local function failAndSplit(player, global, child, other, seconds)
	local q = quest(global)

	pump(0, global .. " before failure")
	q:failQuest(player, "true")
	pump(0, global .. " failure")
	lu.assertFalse(isActive(player, q), global .. ": no longer active after failQuest")
	lu.assertFalse(isComplete(player, q), global .. ": a failed quest is not complete")
	assertSplit(player, global, child, other, seconds or 5)
end

local function noMemberActive(player, n)
	for _, global in ipairs(U.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

-- A delivery leg: the setup (2 s); returns the active area spawned
local function deliveryArea(label)
	pump(2000, label .. " setup")

	local areas = H.spawnedAreas()

	lu.assertTrue(#areas >= 1, label .. ": the delivery area was spawned")

	return areas[#areas]
end

local function lastAreaCall()
	local calls = H.Engine.callsTo("spawnSpaceActiveArea")
	local c = calls[#calls]

	return { c[1], c[3], c[4], c[5] }
end

-- An escort leg whose quest is already started: setupEscort (2 s), the start area, the escort ship (5 s). Returns the escort ship.
local function flyStartedEscort(q, player)
	pump(2500, q.className .. " setup")

	local start = readData(player.objectID .. q.className .. ":startPoint:")

	lu.assertTrue(start >= 1, q.className .. ": setupEscort chose a start point")
	H.enterArea(AC.areaByNumber(q, start), player.rootParent)
	pump(11000, q.className .. " escort spawn")

	local escort = getSceneObject(readData(player.objectID .. ":" .. q.className .. ":escortID:"))

	lu.assertNotNil(escort, q.className .. ": the escort ship spawned")

	return escort
end

local function copyShips()
	local out = {}

	for i, s in ipairs(H.spawnedShips()) do
		out[i] = s
	end

	return out
end

-- starts the quest and lets the targets deploy; returns the spawned ships in spawn order
local function deployedShips(player, global, ms)
	begin(player, global)
	pump(ms or 40000, global .. " deployTargets")

	return copyShips()
end

local F, I, A = "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_advanced_tier4"


local function victories(player)
	local n = 0

	for _, m in ipairs(H.messageLog(player)) do
		if m.id == "@space/quest:quest_won" then
			n = n + 1
		end
	end

	return n
end

local function secs(n) return n * 1000 end

local function spawnNames(name)
	local out = {}

	for _, s in ipairs(D.spawns()) do
		if s.name == name then
			out[#out + 1] = s.zone
		end
	end

	return out
end

local function flyPatrolTo(q, player, point)
	for n = 1, point do
		H.enterArea(AC.areaByNumber(q, n), player.rootParent)
		pump(500, q.className .. " point " .. n)
	end
end

local F, I, B, A, G = "imp_tie_fighter_tier4", "imp_tie_interceptor_tier4", "imp_tie_bomber_tier4", "imp_tie_advanced_tier4", "imp_tie_aggressor_tier4"

---------------------------------------------------------------------------------------------
-- A-3 (a), (b): mission 1 in space_dathomir, both branches
---------------------------------------------------------------------------------------------

TestUfwolChain1 = {}

function TestUfwolChain1:setUp() H.reset() end

function TestUfwolChain1:tearDown() AC.tearDown() end

-- A-3 (a): battle 1 sets up at its point: a waypoint, nothing at once, then the five Rebel allies (150 s) and nine Imperial enemies (130 s), all in space_dathomir
function TestUfwolChain1:test_battle_1_sets_up_at_its_point_with_five_allies_and_nine_enemies()
	local player = chain(1)
	local q = begin(player, U.M1[1])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_1_battle_point")

	pump(5000, U.M1[1] .. " setup")
	lu.assertTrue(isActive(player, q), U.M1[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M1[1] .. ": one waypoint at tatooine_rebel_tier4_1_battle_point")
	lu.assertEquals(#H.spawnedShips(), 0, U.M1[1] .. ": nothing spawned 5 s after the start")
	pump(150000, U.M1[1] .. " both forces arrived")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 14, U.M1[1] .. ": 5 allies + 9 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_awing_tier4"), 2, U.M1[1] .. ": two A-wings")
	lu.assertEquals(countOf(all, "reb_xwing_tier4"), 3, U.M1[1] .. ": three X-wings")
	lu.assertEquals(countOf(all, A), 1, U.M1[1] .. ": one advanced TIE")
	lu.assertEquals(countOf(all, G), 1, U.M1[1] .. ": one aggressor")
	lu.assertEquals(countOf(all, I), 7, U.M1[1] .. ": seven interceptors")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_dathomir", U.M1[1] .. ": " .. tostring(ship.shipName) .. " zone")
	end
end

-- A-3 (a), FF-1: completing battle 1 starts assassinate 1_a 5 s later and never patrol 1_b; the aggressor target spawns with six escorts after 5 s; killing the
-- target alone completes 1_a and no mission 1 member is left active
function TestUfwolChain1:test_completing_battle_1_starts_assassinate_1_a_after_five_seconds_and_killing_its_target_alone_completes_it()
	local player = chain(1)

	begin(player, U.M1[1])
	pump(5000, U.M1[1] .. " setup")
	completeAndSplit(player, U.M1[1], U.M1[2], U.M1[3], 5)

	local q = quest(U.M1[2])

	pump(1500, U.M1[2] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, U.M1[2] .. ": nothing spawned about 3 s after the start (arrivalDelay 5)")
	pump(12000, U.M1[2] .. " deployTargets")

	local ships = copyShips()
	local names = shipNames(ships)

	lu.assertEquals(names, { G, I, I, I, F, F, F }, U.M1[2] .. ": the target and six escorts, " .. table.concat(names, ", "))

	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_1_a_assassin_1")

	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, U.M1[2] .. ": the target spawns at targetPatrols[1] (tatooine_rebel_tier4_1_a_assassin_1)")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dathomir", U.M1[2] .. ": ship " .. i .. " zone")
	end

	H.destroyShip(ships[1], player.rootParent)
	pump(8000, U.M1[2] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), U.M1[2] .. ": complete with the escorts still alive (mustDestroyEscort false)")
	noMemberActive(player, 1)
	lu.assertEquals(startEventsFor(U.M1[3]), 0, U.M1[3] .. ": patrol 1_b was never started on the won branch")
end

-- A-3 (b), FF-1, R-8: failing battle 1 starts patrol 1_b 5 s later and never assassinate 1_a; the patrol splits nothing at points 1-4 and nothing at point 5 before
-- 5 s; 5 s after point 5 it is complete (no client notification) and surprise 1_c is active
function TestUfwolChain1:test_failing_battle_1_starts_patrol_1_b_and_its_split_fires_five_seconds_after_point_5_never_before()
	local player = chain(1)

	begin(player, U.M1[1])
	pump(5000, U.M1[1] .. " setup")
	failAndSplit(player, U.M1[1], U.M1[3], U.M1[2], 5)

	local q = quest(U.M1[3])
	local surprise = quest(U.M1[4])

	flyPatrolTo(q, player, 4)
	lu.assertTrue(isActive(player, q), U.M1[3] .. ": still active at point 4")
	pump(20000, U.M1[3] .. " 20 s after point 4")
	lu.assertFalse(isActive(player, surprise), U.M1[4] .. ": the split does not fire at points 1 to 4")
	lu.assertFalse(isComplete(player, q), U.M1[3] .. ": not complete at point 4")
	H.enterArea(AC.areaByNumber(q, 5), player.rootParent)
	pump(500, U.M1[3] .. " point 5")
	pump(4000, U.M1[3] .. " 4.5 s after point 5")
	lu.assertFalse(isComplete(player, q), U.M1[3] .. ": not complete 4.5 s after point 5 (sideQuestDelay 5, no +5)")
	lu.assertFalse(isActive(player, surprise), U.M1[4] .. ": not active 4.5 s after point 5")
	pump(1400, U.M1[3] .. " 5.9 s after point 5")
	lu.assertTrue(isComplete(player, q), U.M1[3] .. ": complete 5.9 s after point 5 (sideQuestDelay 5; point 6 is never flown)")
	lu.assertTrue(isActive(player, surprise), U.M1[4] .. ": surprise 1_c is active")
	lu.assertEquals(victories(player), 0, U.M1[3] .. ": no 'Mission Successful' notification for the patrol")
	lu.assertFalse(isActive(player, quest(U.M1[2])), U.M1[2] .. ": assassinate 1_a was never started")
end

-- A-3 (b): surprise 1_c spawns six interceptors in space_dathomir; destroying them completes 1_c and leaves no mission 1 member active (the chain end)
function TestUfwolChain1:test_surprise_1_c_spawns_six_interceptors_and_destroying_them_ends_the_mission()
	local player = chain(1)
	local q = begin(player, U.M1[4])

	pump(60000, U.M1[4] .. " attack")

	local ships = copyShips()

	lu.assertEquals(shipNames(ships), { I, I, I, I, I, I }, U.M1[4] .. ": spawned attackers")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dathomir", U.M1[4] .. ": attacker " .. i .. " zone")
	end

	for i = 1, 5 do
		H.destroyShip(ships[i], player.rootParent)
		pump(500, U.M1[4] .. " after kill " .. i)
		lu.assertFalse(isComplete(player, q), U.M1[4] .. ": not complete after " .. i .. " of 6 kills")
	end

	H.destroyShip(ships[6], player.rootParent)
	pump(1500, U.M1[4] .. " after kill 6")
	lu.assertTrue(isComplete(player, q), U.M1[4] .. ": complete after all six attackers are destroyed")
	pump(8000, U.M1[4] .. " after completion")
	noMemberActive(player, 1)
end

-- A-3 (b): the whole lost branch in one run: battle 1 lost > patrol 1_b > surprise 1_c; no mission 1 member is active at the end and 1_a never started
function TestUfwolChain1:test_the_lost_branch_runs_end_to_end_and_the_won_branch_member_never_starts()
	local player = chain(1)

	begin(player, U.M1[1])
	pump(5000, U.M1[1] .. " setup")
	failAndSplit(player, U.M1[1], U.M1[3], U.M1[2], 5)
	flyPatrolTo(quest(U.M1[3]), player, 5)
	pump(8000, U.M1[3] .. " after point 5")
	lu.assertTrue(isActive(player, quest(U.M1[4])), U.M1[4] .. ": active")
	pump(60000, U.M1[4] .. " attack")

	local ships = copyShips()

	lu.assertEquals(countOf(shipNames(ships), I), 6, U.M1[4] .. ": six interceptors among " .. table.concat(shipNames(ships), ", "))

	for _, ship in ipairs(ships) do
		if ship.shipName == I then
			H.destroyShip(ship, player.rootParent)
			pump(300, U.M1[4] .. " kill")
		end
	end

	pump(8000, U.M1[4] .. " after the kills")
	lu.assertTrue(isComplete(player, quest(U.M1[4])), U.M1[4] .. ": complete")
	noMemberActive(player, 1)
	lu.assertEquals(startEventsFor(U.M1[2]), 0, U.M1[2] .. ": never started")
	lu.assertEquals(U.state(player, U.M1[2]), "none", U.M1[2] .. ": journal state none")
end

---------------------------------------------------------------------------------------------
-- A-3 (c): mission 2 in space_dathomir, the first BIDIRECTIONAL recovery, the cross-zone delivery
---------------------------------------------------------------------------------------------

TestUfwolChain2 = {}

function TestUfwolChain2:setUp() H.reset() end

function TestUfwolChain2:tearDown() AC.tearDown() end

-- A-3 (c): recovery 2 spawns the oppressor (the recovery target) with nine escorts in space_dathomir, and its first pre-recovery point has a waypoint
function TestUfwolChain2:test_recovery_2_spawns_the_oppressor_with_nine_escorts_in_dathomir()
	local player = chain(2)
	local q = begin(player, U.M2[1])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_2_recovery_1")

	pump(40000, U.M2[1] .. " deployTargets")
	lu.assertTrue(isActive(player, q), U.M2[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M2[1] .. ": one waypoint at the first pre-recovery point tatooine_rebel_tier4_2_recovery_1")

	local ship = getSceneObject(readData(player.objectID .. q.className .. ":recoveryShip:"))
	local names = shipNames(H.spawnedShips())

	lu.assertNotNil(ship, U.M2[1] .. ": the recovery ship was spawned; ships: " .. table.concat(names, ", "))
	lu.assertEquals(ship.shipName, "imp_tie_oppressor_tier4", U.M2[1] .. ": the recovery ship")
	lu.assertEquals(ship.zone, "space_dathomir", U.M2[1] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, F), 6, U.M2[1] .. ": six fighter escorts among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, I), 3, U.M2[1] .. ": three interceptor escorts")
end

-- A-3 (c), FF-1, R-3: completing recovery 2 starts delivery 2_a 5 s later (a recovery's success path with BIDIRECTIONAL) and never survival 2_b; delivery 2_a
-- sets up its pickup in space_dathomir at tatooine_rebel_tier4_2_a_delivery_1
function TestUfwolChain2:test_completing_recovery_2_starts_delivery_2_a_after_five_seconds_and_never_survival_2_b()
	local player = chain(2)

	begin(player, U.M2[1])
	pump(2000, U.M2[1] .. " setup")
	completeAndSplit(player, U.M2[1], U.M2[2], U.M2[3], 5)

	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_2_a_delivery_1")

	deliveryArea(U.M2[2])
	lu.assertEquals(lastAreaCall(), { "space_dathomir", p[1], p[2], p[3] }, U.M2[2] .. ": the pickup area (zone, x, z, y)")
	lu.assertFalse(isActive(player, quest(U.M2[3])), U.M2[3] .. ": survival 2_b is not active")
	lu.assertEquals(startEventsFor(U.M2[3]), 0, U.M2[3] .. ": survival 2_b was never started on the won branch")
end

-- A-3 (c), FF-1, R-3: failing recovery 2 starts survival 2_b 5 s later and never delivery 2_a; survival 2_b is active at its point with a waypoint; completing it
-- leaves no mission 2 member active
function TestUfwolChain2:test_failing_recovery_2_starts_survival_2_b_after_five_seconds_and_never_delivery_2_a()
	local player = chain(2)

	begin(player, U.M2[1])
	pump(2000, U.M2[1] .. " setup")
	failAndSplit(player, U.M2[1], U.M2[3], U.M2[2], 5)

	local q = quest(U.M2[3])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_2_b_survival")

	pump(8000, U.M2[3] .. " setup")
	lu.assertTrue(isActive(player, q), U.M2[3] .. ": still active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M2[3] .. ": one waypoint at tatooine_rebel_tier4_2_b_survival")
	lu.assertFalse(isActive(player, quest(U.M2[2])), U.M2[2] .. ": delivery 2_a was never started")
	q:completeQuest(player, true)
	pump(8000, U.M2[3] .. " completion")
	lu.assertTrue(isComplete(player, q), U.M2[3] .. ": the failure end is complete")
	noMemberActive(player, 2)
end

-- A-3 (c), FF-2: delivery 2_a sets up its pickup in space_dathomir with the YT-1300 spy
function TestUfwolChain2:test_delivery_2_a_sets_up_its_pickup_in_dathomir_with_the_yt1300_spy()
	quest(U.M2[2])

	local sc = D.fresh("delivery", "tatooine_rebel_tier4_2_a"):start()
	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_2_a_delivery_1")
	local area = H.Engine.callsTo("spawnSpaceActiveArea")[1]

	lu.assertEquals({ area[1], area[3], area[4], area[5] }, { "space_dathomir", p[1], p[2], p[3] }, "the pickup area (zone, x, z, y)")
	lu.assertEquals(#sc:waypoints(), 1, "one waypoint")
	lu.assertEquals(sc:waypoints()[1].planet, "space_dathomir", "pickup waypoint planet")
	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnNames("yt1300_rebel_spy"), { "space_dathomir" }, "the pickup transport and its zone")
	lu.assertTrue(sc:active(), "delivery 2_a is active")
end

-- A-3 (c), FF-2: after the pickup the delivery leg is in space_yavin4 at the drop-off point, with rebel_agent_vortex; completing it ends the mission
function TestUfwolChain2:test_after_the_pickup_the_delivery_leg_is_in_yavin_4_at_the_delivery_point_with_the_agent()
	quest(U.M2[2])

	local sc = D.fresh("delivery", "tatooine_rebel_tier4_2_a"):toFirstDock()
	local p = pointOf("space_yavin4", "tatooine_rebel_tier4_2_a_delivery_2")

	sc:atDock(secs(2))

	local calls = H.Engine.callsTo("spawnSpaceActiveArea")

	lu.assertEquals(#calls, 2, "the delivery leg area exists 2 s after the dock")
	lu.assertEquals({ calls[2][1], calls[2][3], calls[2][4], calls[2][5] }, { "space_yavin4", p[1], p[2], p[3] }, "the delivery area (zone, x, z, y)")
	lu.assertEquals(#sc:waypoints(), 1, "one live waypoint: the delivery point")
	lu.assertEquals(sc:waypoints()[1].planet, "space_yavin4", "delivery waypoint planet")

	H.zoneSwitch(sc.player, "space_yavin4")
	pump(0, "zone switch")
	lu.assertTrue(sc:active(), "the quest survives dathomir -> yavin4 on leg 2")
	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnNames("rebel_agent_vortex"), { "space_yavin4" }, "the delivery transport and its zone")
	sc:dock()
	sc:atDock(secs(3))
	lu.assertTrue(sc:complete(), "delivery 2_a is complete after the delivery dock")

	for _, global in ipairs(U.M2) do
		lu.assertFalse(isActive(sc.player, quest(global)), global .. ": no mission 2 member is active")
	end
end

-- A-3 (c), FF-2: a switch to any other zone on leg 2 fails delivery 2_a
function TestUfwolChain2:test_a_switch_to_another_zone_on_leg_2_fails_delivery_2_a()
	quest(U.M2[2])

	local sc = D.fresh("delivery", "tatooine_rebel_tier4_2_a"):toFirstDock()

	sc:atDock(secs(2))
	H.zoneSwitch(sc.player, "space_endor")
	pump(0, "zone switch")
	lu.assertFalse(sc:active(), "dathomir -> endor on leg 2 ends delivery 2_a")
end

---------------------------------------------------------------------------------------------
-- A-4 (a): mission 3 in space_endor
---------------------------------------------------------------------------------------------

TestUfwolChain3 = {}

function TestUfwolChain3:setUp() H.reset() end

function TestUfwolChain3:tearDown() AC.tearDown() end

-- A-4 (a): battle 3 sets up at its point with four X-wing allies and nine enemies, all in space_endor
function TestUfwolChain3:test_battle_3_sets_up_at_its_point_with_four_allies_and_nine_enemies()
	local player = chain(3)
	local q = begin(player, U.M3[1])
	local p = pointOf("space_endor", "tatooine_rebel_tier4_3_battle_point")

	pump(5000, U.M3[1] .. " setup")
	lu.assertTrue(isActive(player, q), U.M3[1] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M3[1] .. ": one waypoint at tatooine_rebel_tier4_3_battle_point")
	pump(150000, U.M3[1] .. " both forces arrived")

	local all = shipNames(H.spawnedShips())

	lu.assertEquals(#all, 13, U.M3[1] .. ": 4 allies + 9 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_xwing_tier4"), 4, U.M3[1] .. ": four X-wings")
	lu.assertEquals(countOf(all, I), 6, U.M3[1] .. ": six interceptors")
	lu.assertEquals(countOf(all, F), 2, U.M3[1] .. ": two fighters")
	lu.assertEquals(countOf(all, A), 1, U.M3[1] .. ": one advanced TIE")

	for _, ship in ipairs(H.spawnedShips()) do
		lu.assertEquals(ship.zone, "space_endor", U.M3[1] .. ": " .. tostring(ship.shipName) .. " zone")
	end
end

-- A-4 (a), FF-1: winning battle 3 starts assassinate 3_a 5 s later and never 3_b; 3_a spawns the station commander's shuttle with eight escorts; killing the
-- target alone completes it and no mission 3 member is left active
function TestUfwolChain3:test_winning_battle_3_starts_assassinate_3_a_after_five_seconds_and_the_target_alone_completes_it()
	local player = chain(3)

	begin(player, U.M3[1])
	pump(5000, U.M3[1] .. " setup")
	completeAndSplit(player, U.M3[1], U.M3[2], U.M3[3], 5)
	pump(12000, U.M3[2] .. " deployTargets")

	local q = quest(U.M3[2])
	local ships = copyShips()
	local p = pointOf("space_endor", "tatooine_rebel_tier4_3_a_assassin_1")

	lu.assertEquals(shipNames(ships), { "lambdashuttle_station_commander", A, A, F, F, F, F, F, F }, U.M3[2] .. ": the target and eight escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, U.M3[2] .. ": the target spawns at targetPatrols[1]")
	H.destroyShip(ships[1], player.rootParent)
	pump(8000, U.M3[2] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, q), U.M3[2] .. ": complete with the escorts still alive (mustDestroyEscort false)")
	noMemberActive(player, 3)
	lu.assertEquals(startEventsFor(U.M3[3]), 0, U.M3[3] .. ": assassinate 3_b was never started on the won branch")
end

-- A-4 (a), FF-1: losing battle 3 starts assassinate 3_b 5 s later and never 3_a; 3_b spawns an oppressor with five bombers; the target alone does not complete it,
-- every ship does
function TestUfwolChain3:test_losing_battle_3_starts_assassinate_3_b_after_five_seconds_and_it_needs_every_ship_destroyed()
	local player = chain(3)

	begin(player, U.M3[1])
	pump(5000, U.M3[1] .. " setup")
	failAndSplit(player, U.M3[1], U.M3[3], U.M3[2], 5)
	pump(12000, U.M3[3] .. " deployTargets")

	local q = quest(U.M3[3])
	local ships = copyShips()
	local p = pointOf("space_endor", "tatooine_rebel_tier4_3_b_assassin_1")

	lu.assertEquals(shipNames(ships), { "imp_tie_oppressor_tier4", B, B, B, B, B }, U.M3[3] .. ": the target and five bombers")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, U.M3[3] .. ": the target spawns at targetPatrols[1]")
	H.destroyShip(ships[1], player.rootParent)
	pump(3000, U.M3[3] .. " after the target is destroyed")
	lu.assertFalse(isComplete(player, q), U.M3[3] .. ": not complete with the bombers alive (mustDestroyEscort)")

	for i = 2, #ships do
		H.destroyShip(ships[i], player.rootParent)
		pump(1500, U.M3[3] .. " after ship " .. i)
	end

	pump(8000, U.M3[3] .. " after all six are destroyed")
	lu.assertTrue(isComplete(player, q), U.M3[3] .. ": complete once everything is destroyed")
	noMemberActive(player, 3)
	lu.assertFalse(isActive(player, quest(U.M3[2])), U.M3[2] .. ": assassinate 3_a was never started")
end

---------------------------------------------------------------------------------------------
-- A-4 (b), (c): mission 4 in space_endor, the failure split crosses into space_dathomir
---------------------------------------------------------------------------------------------

TestUfwolChain4 = {}

function TestUfwolChain4:setUp() H.reset() end

function TestUfwolChain4:tearDown() AC.tearDown() end

-- A-4 (b): assassinate 4 spawns the decimator and six fighters after 10 s at its first point
function TestUfwolChain4:test_assassinate_4_spawns_the_decimator_and_six_fighters_after_ten_seconds_at_its_first_point()
	local player = chain(4)

	begin(player, U.M4[1])
	pump(8000, U.M4[1] .. " before the arrival delay")
	lu.assertEquals(#H.spawnedShips(), 0, U.M4[1] .. ": nothing spawned 8 s after the start (arrivalDelay 10)")
	pump(7000, U.M4[1] .. " deployTargets")

	local ships = copyShips()
	local p = pointOf("space_endor", "tatooine_rebel_tier4_4_assassin_1")

	lu.assertEquals(shipNames(ships), { "imp_decimator_tier4", F, F, F, F, F, F }, U.M4[1] .. ": the target and six escorts")
	lu.assertEquals({ ships[1].x, ships[1].z, ships[1].y }, p, U.M4[1] .. ": the target spawns at targetPatrols[1]")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_endor", U.M4[1] .. ": ship " .. i .. " zone")
	end
end

-- A-4 (b), FF-1: completing assassinate 4 (the target alone) starts survival 4_a in space_endor 5 s later and never battle 4_b; survival 4_a is active at its
-- point with a waypoint; completing it leaves no mission 4 member active
function TestUfwolChain4:test_completing_assassinate_4_starts_survival_4_a_after_five_seconds_and_never_battle_4_b()
	local player = chain(4)
	local ships = deployedShips(player, U.M4[1], 14000)

	lu.assertEquals(#ships, 7, U.M4[1] .. ": precondition: the target and six escorts")
	H.destroyShip(ships[1], player.rootParent)
	pump(1500, U.M4[1] .. " after the target is destroyed")
	lu.assertTrue(isComplete(player, quest(U.M4[1])), U.M4[1] .. ": complete with the escorts still alive")
	assertSplit(player, U.M4[1], U.M4[2], U.M4[3], 5)

	local q = quest(U.M4[2])
	local p = pointOf("space_endor", "tatooine_rebel_tier4_4_a_survival")

	pump(8000, U.M4[2] .. " setup")
	lu.assertTrue(isActive(player, q), U.M4[2] .. ": still active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M4[2] .. ": one waypoint at tatooine_rebel_tier4_4_a_survival")
	q:completeQuest(player, true)
	pump(8000, U.M4[2] .. " completion")
	lu.assertTrue(isComplete(player, q), U.M4[2] .. ": the success end is complete")
	noMemberActive(player, 4)
	lu.assertEquals(startEventsFor(U.M4[3]), 0, U.M4[3] .. ": battle 4_b was never started on the won branch")
end

-- A-4 (c), FF-2, FF-3: the 20-minute timeout fail of assassinate 4 starts battle 4_b 5 s later (and never survival 4_a). While the pilot is still in space_endor
-- 4_b is active and has set nothing up (no waypoint, no forces); entering space_dathomir sets it up at its battle point with four allies and ten enemies
function TestUfwolChain4:test_the_timeout_fail_of_assassinate_4_starts_battle_4_b_which_sets_up_when_the_pilot_enters_dathomir()
	local player = chain(4)
	local q = quest(U.M4[1])

	deployedShips(player, U.M4[1], 14000)
	lu.assertTrue(isActive(player, q), U.M4[1] .. ": precondition: running")
	pump(20 * 60 * 1000 - 20000, U.M4[1] .. " just before the timer")

	local waited = 0

	while isActive(player, q) and waited < 60000 do
		pump(500, U.M4[1] .. " waiting for the timeout")
		waited = waited + 500
	end

	lu.assertFalse(isActive(player, q), U.M4[1] .. ": failed by the timeout")
	lu.assertFalse(isComplete(player, q), U.M4[1] .. ": a timed-out run is not complete")
	assertSplit(player, U.M4[1], U.M4[3], U.M4[2], 5)

	local battle = quest(U.M4[3])
	local p = pointOf("space_dathomir", "tatooine_rebel_tier4_4_b_battle_point")
	local before = #H.spawnedShips()

	pump(60000, U.M4[3] .. " while the pilot is still in space_endor")
	lu.assertTrue(isActive(player, battle), U.M4[3] .. ": active")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 0, U.M4[3] .. ": no waypoint while the pilot is in space_endor")
	lu.assertEquals(#H.spawnedShips(), before, U.M4[3] .. ": no forces while the pilot is in space_endor")

	H.zoneSwitch(player, "space_dathomir", { ship = { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("rebel") } })
	pump(10000, U.M4[3] .. " entered space_dathomir")
	lu.assertEquals(waypointsAt(player, p[1], p[2], p[3]), 1, U.M4[3] .. ": one waypoint at tatooine_rebel_tier4_4_b_battle_point after entering space_dathomir")
	pump(150000, U.M4[3] .. " both forces arrived")

	local ships = {}

	for i, s in ipairs(copyShips()) do
		if i > before then
			ships[#ships + 1] = s
		end
	end

	local all = shipNames(ships)

	lu.assertEquals(#all, 14, U.M4[3] .. ": 4 allies + 10 enemies among " .. table.concat(all, ", "))
	lu.assertEquals(countOf(all, "reb_awing_tier4"), 1, U.M4[3] .. ": one A-wing")
	lu.assertEquals(countOf(all, "reb_xwing_tier4"), 2, U.M4[3] .. ": two X-wings")
	lu.assertEquals(countOf(all, "reb_bwing_tier4"), 1, U.M4[3] .. ": one B-wing")
	lu.assertEquals(countOf(all, "imp_decimator_tier4"), 1, U.M4[3] .. ": one decimator")
	lu.assertEquals(countOf(all, G), 1, U.M4[3] .. ": one aggressor")
	lu.assertEquals(countOf(all, F), 6, U.M4[3] .. ": six fighters")
	lu.assertEquals(countOf(all, I), 2, U.M4[3] .. ": two interceptors")

	for i, ship in ipairs(ships) do
		lu.assertEquals(ship.zone, "space_dathomir", U.M4[3] .. ": ship " .. i .. " zone")
	end

	battle:completeQuest(player, true)
	pump(8000, U.M4[3] .. " completion")
	lu.assertTrue(isComplete(player, battle), U.M4[3] .. ": the failure end is complete")
	noMemberActive(player, 4)
	lu.assertEquals(startEventsFor(U.M4[2]), 0, U.M4[2] .. ": survival 4_a was never started on the lost branch")
end

-- A-4 (c), FF-3: leaving the zone fails assassinate 4 without any split (SWG passes no split on a zone exit)
function TestUfwolChain4:test_leaving_the_zone_fails_assassinate_4_and_starts_neither_child()
	local player = chain(4)
	local q = quest(U.M4[1])

	deployedShips(player, U.M4[1], 14000)
	H.zoneSwitch(player, "space_naboo", { ship = true })
	pump(60000, U.M4[1] .. " after leaving the zone")
	lu.assertFalse(isActive(player, q), U.M4[1] .. ": failed")
	lu.assertFalse(isComplete(player, q), U.M4[1] .. ": not complete")

	for _, child in ipairs({ U.M4[2], U.M4[3] }) do
		lu.assertEquals(startEventsFor(child), 0, child .. ": no startQuest queued after a leave-zone fail")
		lu.assertFalse(isActive(player, quest(child)), child .. ": not active after a leave-zone fail")
	end
end

---------------------------------------------------------------------------------------------
-- A-5: the four duties and the same-name tables
---------------------------------------------------------------------------------------------

TestUfwolDuties = {}

function TestUfwolDuties:setUp() H.reset() end

function TestUfwolDuties:tearDown() AC.tearDown() end

-- A-5: each duty global starts once, is reported active by type and name, starts no side quest and sets no <name>:* status key
function TestUfwolDuties:test_each_duty_starts_once_is_active_by_type_and_starts_no_side_quest_and_sets_no_key()
	for _, global in ipairs(U.DUTIES) do
		local player = world({ global })
		local q = quest(global)
		local others = {}

		for _, g in ipairs(U.GLOBALS) do
			if g ~= global then
				others[g] = H.spyOn(quest(g), "startQuest")
			end
		end

		q:startQuest(player, "")
		pump(60000, global .. " running")
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, "tatooine_rebel_tier4_1"), global .. ": reported active by SpaceHelpers:isSpaceQuestActive(type, name)")

		for g, calls in pairs(others) do
			lu.assertEquals(#calls, 0, global .. ": started " .. g .. " (a duty starts no side quest)")
		end

		lu.assertEquals(U.keysNamed(player, "tatooine_rebel_tier4_1"), {}, global .. ": a duty run sets no <playerID>tatooine_rebel_tier4_1:* key (I-10)")

		for _, other in ipairs(U.DUTIES) do
			if other ~= global then
				lu.assertFalse(isActive(player, quest(other)), global .. ": started " .. other)
			end
		end

		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "space_battle", "tatooine_rebel_tier4_1"), global .. ": the same-name battle head is not active")
		H.restoreSpies()
	end
end

-- A-5, I-8, R-7: with battle 1 complete, starting then clearing the destroy duty leaves battle 1 complete
function TestUfwolDuties:test_starting_and_clearing_the_destroy_duty_leaves_the_same_name_battle_complete()
	local player = world({ U.DUTIES[1] })

	U.setState(player, U.M1[1], "complete")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "space_battle", "tatooine_rebel_tier4_1"), "precondition: battle 1 complete")
	quest(U.DUTIES[1]):startQuest(player, "")
	pump(2000, U.DUTIES[1] .. " start")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "destroy_duty", "tatooine_rebel_tier4_1"), "the destroy duty is active")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "space_battle", "tatooine_rebel_tier4_1"), "battle 1 stays complete while the duty is active")
	SpaceHelpers:clearSpaceQuest(player, "destroy_duty", "tatooine_rebel_tier4_1", false)
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "destroy_duty", "tatooine_rebel_tier4_1"), "the destroy duty is cleared")
	lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, "space_battle", "tatooine_rebel_tier4_1"), "battle 1 stays complete after the duty is cleared")
end

-- A-5, I-8, R-7: with the escort duty active, failing battle 1 leaves the escort duty active
function TestUfwolDuties:test_failing_battle_1_leaves_an_active_escort_duty_active()
	local player = world({ U.M1[1], U.DUTIES[2] }, "space_dathomir")

	H.spyOn(quest(U.M1[3]), "startQuest")
	begin(player, U.M1[1])
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "space_battle", "tatooine_rebel_tier4_1"), "precondition: battle 1 active")
	U.setState(player, U.DUTIES[2], "active")
	quest(U.M1[1]):failQuest(player, "true")
	pump(500, U.M1[1] .. " failure")
	lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, "space_battle", "tatooine_rebel_tier4_1"), "battle 1 no longer active")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, "escort_duty", "tatooine_rebel_tier4_1"), "the escort duty stays active (journal state is per type and name)")
end

-- A-5, I-8: the five same-name journal entries are independent: setting one changes no other
function TestUfwolDuties:test_the_five_same_name_journal_entries_are_independent()
	local player = world({ U.M1[1] })
	local same = { U.M1[1], U.DUTIES[1], U.DUTIES[2], U.DUTIES[3], U.DUTIES[4] }

	for _, global in ipairs(same) do
		U.setState(player, global, "active")

		for _, other in ipairs(same) do
			local want = other == global and "active" or "none"

			lu.assertEquals(U.state(player, other), want, other .. ": journal state while only " .. global .. " is active")
			lu.assertEquals(SpaceHelpers:isSpaceQuestActive(player, U.IDENTITY[other].type, U.IDENTITY[other].name) == true, other == global,
				other .. ": SpaceHelpers:isSpaceQuestActive while only " .. global .. " is active")
		end

		U.setState(player, global, "none")
	end
end

return nil
