-- Smuggler tier 4 (Nirame): the four missions run through the fakes, split by split.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-4, AC-5; Data mapping 1; FN-6, FN-7; D-14, D-15; R-3, R-4, R-5).
--
-- The oracle values are the SWG fixtures (smuggler_tier4_data.lua N.expected, proven equal to the tables by test_smuggler_tier4_data.lua) and the spec's numbers;
-- the quest tables are driven through the harness's fakes, never read for expected values. Each step pumps the event clock inside pcall first, so a Lua error inside
-- an event shows up as "no Lua error" and not as a later, unrelated assertion. For chain steps the test completes the member through its own completeQuest and pumps
-- the split delay (5 s; the alert fires at the delay, the next quest starts at delay * 1.05). The inspect steps use the cargo of the REAL ship template files
-- (ship_mobile/ships/valarian_gunship_inspect*.lua), not a cargo set on the fake ship. Delivery 1a is driven by test_smuggler_tier4_delivery.lua; survival 2c and the
-- duties stop at "active / spawned" here (the duty screens are covered by test_smuggler_tier4_gates.lua). The pilot is a Smuggler at pilot tier 4 whose launched
-- ship carries the Hutt faction (C++ resetShipFaction). The hostility of the real AI cannot be checked here; see the in-game checklist.

local lu = require("luaunit")
local H = require("harness")
local AC = require("abort_cleanup_scenario")
local DRS = require("duty_rules_scenario")
local N = require("smuggler_tier4_data")

N.load()

local G = N.GLOBALS

local function quest(global) return N.quest(global) end

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

local function waypointAt(player, x, z, y)
	for _, w in ipairs(player.ghost.waypoints) do
		if w.x == x and w.z == z and w.y == y then
			return w
		end
	end
end

local function handler() return rawget(_G, N.HANDLER) end

-- A Smuggler graduate at pilot tier 4 in a Hutt-faction ship in `zone`
local function newPlayer(zone)
	return N.pilot({ zone = zone, inShip = { x = DRS.CORNER.x, z = DRS.CORNER.z, y = DRS.CORNER.y, factionHash = getHashCode("hutt") } })
end

-- A fresh world with the static areas of every member of the mission's chain, and the pilot in `zone` (default the head's zone)
local function chain(n, zone)
	H.reset()

	local members = N.CHAINS[n]

	for _, global in ipairs(members) do
		quest(global):start()
	end

	for _, global in ipairs(members) do
		if quest(global).questType == "recovery" then
			AC.resolveRecoveryPoints(quest(global))
		end
	end

	return newPlayer(zone or quest(members[1]).questZone)
end

-- The member's own start, as the previous member's split does it
local function begin(player, global)
	local q = quest(global)

	q:startQuest(player, "")
	pump(0, global .. " start")

	return q
end

-- Completes a member and pumps the split delay: the next member is not active at 4 s and is active at 7 s
local function completeAndSplit(player, global, nextGlobal)
	local q = quest(global)

	pump(0, global .. " before completion")
	q:completeQuest(player, true)
	pump(0, global .. " completion")
	lu.assertTrue(isComplete(player, q), global .. ": complete")

	if nextGlobal then
		local nq = quest(nextGlobal)

		pump(4000, global .. " split delay")
		lu.assertFalse(isActive(player, nq), nextGlobal .. ": not active 4 s after " .. global .. " completed (sideQuestDelay 5 s)")
		pump(3000, global .. " split start")
		lu.assertTrue(isActive(player, nq), nextGlobal .. ": active 7 s after " .. global .. " completed")
	end
end

-- A delivery leg: the setup (2 s), the pilot's ship enters the delivery area, the transport warps in (6 s)
local function deliveryArrive(player, label)
	pump(2000, label .. " setup")

	local areas = H.spawnedAreas()

	lu.assertTrue(#areas >= 1, label .. ": the delivery area was spawned")
	H.enterArea(areas[#areas], player.rootParent)
	pump(7000, label .. " warp-in")

	return areas[#areas]
end

local function noMemberActive(player, n)
	for _, global in ipairs(N.CHAINS[n]) do
		lu.assertFalse(isActive(player, quest(global)), global .. ": no mission " .. n .. " member is active")
	end
end

local function spawnedCopy()
	local ships = {}

	for i, s in ipairs(H.spawnedShips()) do
		ships[i] = s
	end

	return ships
end

-- Kills every ship of `ships` with the pilot's ship, one event round after the other
local function killAll(player, ships, label)
	for _, s in ipairs(ships) do
		H.destroyShip(s, player.rootParent)
		pump(1500, label .. " after a kill")
	end
end

-- The assassinate run: deploys the targets and returns the spawned ships split into the target and the rest
local function deploy(player, global)
	local before = #H.spawnedShips()

	begin(player, global)
	pump(40000, global .. " deployTargets")

	local q = quest(global)
	local target, rest = nil, {}

	for i, s in ipairs(H.spawnedShips()) do
		if i > before then
			if s.shipName == q.assassinateSpawns.target and target == nil then
				target = s
			else
				rest[#rest + 1] = s
			end
		end
	end

	return target, rest
end

-- the cargo the server's ship template gives the Valarian ship (read from the real template file)
local function templateCargo(shipName)
	local t = H.shipTemplate(shipName)

	lu.assertNotNil(t, "ship_mobile/ships/" .. shipName .. ".lua registers a template")
	lu.assertNotNil(t.cargoString, shipName .. ".lua has no cargoString: the inspect quest can never match the ship's cargo (FN-6)")

	return t.cargoString
end

local SPAWNER = "tatooine_privateer_tier4_leg_3_inspect"

local function valarian(shipName, cargo)
	return H.worldAgent({ shipName = shipName, cargo = cargo, spawner = SPAWNER, zone = "space_dantooine" })
end

local function inspectAndDock(player, q, target, cargo)
	local hash = getHashCode(cargo)

	H.inspect(player, target, hash)
	pump(0, q.className .. " inspect")
	H.dock(player, target, hash)
	pump(0, q.className .. " dock")
	pump(1000, q.className .. " after the dock")
end

---------------------------------------------------------------------------------------------
-- AC-4 (a): mission 1 (delivery 1a is driven by test_smuggler_tier4_delivery.lua)
---------------------------------------------------------------------------------------------

TestSmugglerT4Chain1 = {}

function TestSmugglerT4Chain1:setUp() H.reset() end

function TestSmugglerT4Chain1:tearDown() AC.tearDown() end

-- AC-4 (a): dnp 1b spawns hutt_transport_tier4 at the ..._leg_1_deliverynp point; completing it wins mission 1
function TestSmugglerT4Chain1:test_delivery_no_pickup_1b_spawns_the_hutt_transport_at_its_point_and_winning_it_wins_mission_1()
	local player = chain(1, "space_dantooine")

	N.setMission(player, 1, "attempted")
	N.setState(player, G[1], "complete")

	local q = begin(player, G[2])

	lu.assertTrue(isActive(player, q), G[2] .. ": active")

	local area = deliveryArrive(player, G[2])
	local p = N.buildout("dantooine").nav.tatooine_privateer_tier4_leg_1_deliverynp
	local calls = H.Engine.callsTo("spawnSpaceActiveArea")

	lu.assertEquals({ calls[#calls][1], calls[#calls][3], calls[#calls][4], calls[#calls][5] }, { "space_dantooine", p[1], p[2], p[3] }, G[2] .. ": the delivery area (zone, x, z, y)")
	lu.assertNotNil(area, "the area exists")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(countOf(names, "hutt_transport_tier4"), 1, G[2] .. ": hutt_transport_tier4 spawned; ships: " .. table.concat(names, ", "))
	completeAndSplit(player, G[2], nil)
	pump(8000, G[2] .. " after completion")
	noMemberActive(player, 1)
	N.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 1), "mission 1 is won (the chain end is complete)")
end

---------------------------------------------------------------------------------------------
-- AC-4 (b): mission 2 (Dantooine): two recoveries, the survival
---------------------------------------------------------------------------------------------

TestSmugglerT4Chain2 = {}

function TestSmugglerT4Chain2:setUp() H.reset() end

function TestSmugglerT4Chain2:tearDown() AC.tearDown() end

-- AC-4 (b): recovery 2a spawns the Black Sun transport with four TIE fighters
function TestSmugglerT4Chain2:test_recovery_2a_spawns_the_blacksun_transport_with_four_tie_fighters()
	local player = chain(2)
	local run = DRS.startRecoveryRun(quest(G[3]), player)

	pump(10000, G[3] .. " after the ship arrived")

	local names = shipNames(H.spawnedShips())

	lu.assertEquals(run.ship.shipName, "blacksun_transport_tier4", G[3] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_dantooine", G[3] .. ": the recovery ship zone")
	lu.assertEquals(countOf(names, "imp_tie_fighter_tier4"), 4, G[3] .. ": TIE fighter escorts among " .. table.concat(names, ", "))
end

-- AC-4 (b): completing recovery 2a starts recovery 2b 5 s later
function TestSmugglerT4Chain2:test_completing_recovery_2a_starts_recovery_2b_five_seconds_later()
	local player = chain(2)

	begin(player, G[3])
	pump(60000, G[3] .. " arrival")
	completeAndSplit(player, G[3], G[4])
end

-- AC-4 (b): recovery 2b spawns the Imperial shuttle and no escort
function TestSmugglerT4Chain2:test_recovery_2b_spawns_the_lambda_shuttle_and_no_escort()
	local player = chain(2)

	N.setState(player, G[3], "complete")

	local before = #H.spawnedShips()
	local run = DRS.startRecoveryRun(quest(G[4]), player)

	pump(10000, G[4] .. " after the ship arrived")
	lu.assertEquals(run.ship.shipName, "imp_lambda_shuttle_tier4", G[4] .. ": the recovery ship")

	local names = {}

	for i = before + 1, #H.spawnedShips() do
		names[#names + 1] = H.spawnedShips()[i].shipName
	end

	lu.assertEquals(names, { "imp_lambda_shuttle_tier4" }, G[4] .. ": the ships spawned (no escorts)")
end

-- AC-4 (b): completing recovery 2b starts survival 2c at the egress point (R-5: its 3-second transmission is SWG's)
function TestSmugglerT4Chain2:test_completing_recovery_2b_starts_survival_2c_at_the_egress_point()
	local player = chain(2)

	N.setState(player, G[3], "complete")
	begin(player, G[4])
	pump(60000, G[4] .. " arrival")
	completeAndSplit(player, G[4], G[5])
	pump(5000, G[5] .. " start")

	local p = N.buildout("dantooine").nav.tatooine_privateer_tier4_recovery_two_egress_4

	lu.assertNotNil(waypointAt(player, p[1], p[2], p[3]), G[5] .. ": a waypoint at tatooine_privateer_tier4_recovery_two_egress_4")
end

-- AC-4 (b): completing survival 2c makes mission 2 won
function TestSmugglerT4Chain2:test_completing_survival_2c_wins_mission_2()
	local player = chain(2)

	N.setState(player, G[3], "complete")
	N.setState(player, G[4], "complete")
	begin(player, G[5])
	pump(5000, G[5] .. " start")
	completeAndSplit(player, G[5], nil)
	pump(8000, G[5] .. " after completion")
	noMemberActive(player, 2)
	N.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 2), "mission 2 is won")
end

---------------------------------------------------------------------------------------------
-- AC-5 (a), (b), (c), (d), (e): mission 3 (Dantooine inspect, Tatooine assassinate, Endor recovery, the failure split)
---------------------------------------------------------------------------------------------

TestSmugglerT4Chain3 = {}

function TestSmugglerT4Chain3:setUp() H.reset() end

function TestSmugglerT4Chain3:tearDown() AC.tearDown() end

-- AC-5 (a): inspect 3a gives one waypoint, at the spawner
function TestSmugglerT4Chain3:test_inspect_3a_gives_one_waypoint_at_the_spawner()
	local player = chain(3)
	local q = begin(player, G[6])

	pump(5000, G[6] .. " setup")
	lu.assertTrue(isActive(player, q), G[6] .. ": active")

	local sp = N.buildout("dantooine").spawners[1]

	lu.assertNotNil(waypointAt(player, sp[1], sp[2], sp[3]), G[6] .. ": a waypoint at the " .. sp.name .. " position " .. sp[1] .. ", " .. sp[2] .. ", " .. sp[3])
	lu.assertEquals(#player.ghost.waypoints, 1, G[6] .. ": waypoints")
end

-- AC-5 (a), FN-6: inspecting and docking with a gunship carrying the template's cargo completes 3a; 3b is active 5 s later
function TestSmugglerT4Chain3:test_inspect_3a_completes_with_either_templates_cargo_and_starts_assassinate_3b_five_seconds_later()
	for _, shipName in ipairs({ "valarian_gunship_inspect_tier4", "valarian_gunship_inspect" }) do
		local player = chain(3)
		local q = begin(player, G[6])
		local nextQ = quest(G[7])

		pump(2500, G[6] .. " setup")

		local cargo = templateCargo(shipName)

		lu.assertEquals(cargo, q.cargo, shipName .. ": the template's cargoString equals the quest cargo")
		inspectAndDock(player, q, valarian(shipName, cargo), cargo)
		lu.assertTrue(isComplete(player, q), G[6] .. ": complete after docking with " .. shipName)
		pump(3000, G[6] .. " split delay")
		lu.assertFalse(isActive(player, nextQ), G[7] .. ": not active 4 s after the dock")
		pump(3000, G[6] .. " split start")
		lu.assertTrue(isActive(player, nextQ), G[7] .. ": active 7 s after the dock")
	end
end

-- AC-5 (a): a ship with another cargo does not complete it
function TestSmugglerT4Chain3:test_a_ship_with_another_cargo_does_not_complete_inspect_3a()
	local player = chain(3)
	local q = begin(player, G[6])

	pump(2500, G[6] .. " setup")
	inspectAndDock(player, q, valarian("valarian_gunship_inspect_tier4", "kill_orders"), "kill_orders")
	pump(3000, G[6] .. " dock")
	lu.assertFalse(isComplete(player, q), G[6] .. ": not complete with the wrong cargo")
end

-- AC-5 (b): assassinate 3b spawns the gunship and four bombers; with mustDestroyEscort the target alone does not complete it
function TestSmugglerT4Chain3:test_assassinate_3b_needs_the_target_and_all_four_escorts()
	local player = chain(3, "space_tatooine")
	local q = quest(G[7])
	local target, rest = deploy(player, G[7])

	lu.assertNotNil(target, "the target valarian_gunship_tier5 spawned")
	lu.assertEquals(#rest, 4, "escorts")

	for _, s in ipairs(rest) do
		lu.assertEquals(s.shipName, "valarian_bomber_tier4", "escort ship")
	end

	H.destroyShip(target, player.rootParent)
	pump(5000, G[7] .. " after the target")
	lu.assertFalse(isComplete(player, q), "not complete with the escorts alive")
	killAll(player, rest, G[7])
	pump(5000, G[7] .. " after the last kill")
	lu.assertTrue(isComplete(player, q), "complete after the target and all four escorts")
end

-- AC-5 (b): completing 3b starts recovery 3c in Endor 5 s later, and not the surprise attack
function TestSmugglerT4Chain3:test_completing_assassinate_3b_starts_recovery_3c_and_not_the_surprise_attack()
	local player = chain(3, "space_tatooine")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")
	begin(player, G[7])
	pump(5000, G[7] .. " running")
	completeAndSplit(player, G[7], G[9])
	pump(5000, G[9] .. " running")
	lu.assertFalse(isActive(player, quest(G[8])), G[8] .. ": the surprise attack does not start after a win")
	lu.assertTrue(isActive(player, quest(G[9])), G[9] .. ": recovery 3c is active")
	lu.assertEquals(quest(G[9]).questZone, "space_endor", G[9] .. ": questZone")
end

-- AC-5 (c), R-3: 3b failing by the target's escape starts the surprise attack 5 s later (and not recovery 3c); it spawns five Valarian gunships
function TestSmugglerT4Chain3:test_3b_failing_by_escape_starts_the_surprise_attack_which_spawns_five_gunships()
	local player = chain(3, "space_tatooine")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")

	local q = quest(G[7])

	deploy(player, G[7])

	local before = #H.spawnedShips() -- everything 3b spawned is behind us

	q:failAssassination(player)
	pump(1000, G[7] .. " fail event")
	lu.assertFalse(isActive(player, q), G[7] .. ": failed")
	lu.assertFalse(isComplete(player, q), G[7] .. ": and not complete")
	pump(3000, G[7] .. " failure split delay")
	lu.assertFalse(isActive(player, quest(G[8])), G[8] .. ": not active 4 s after the failure (sideQuestDelay 5 s)")
	pump(3000, G[7] .. " failure split start")
	lu.assertTrue(isActive(player, quest(G[8])), G[8] .. ": active 7 s after the failure")
	lu.assertFalse(isActive(player, quest(G[9])), G[9] .. ": recovery 3c does not start from the failure")

	-- D-14: while the failure child runs the mission is neither failed nor won
	N.requireConversation(lu)
	lu.assertFalse(handler():isFailed(player, 3), "isFailed(3) while 3c_sa runs")
	lu.assertTrue(handler():isActive(player, 3), "isActive(3) while 3c_sa runs")

	pump(40000, G[8] .. " spawn")

	local names = {}

	for i = before + 1, #H.spawnedShips() do
		names[#names + 1] = H.spawnedShips()[i].shipName
	end

	lu.assertEquals(names, { "valarian_gunship_tier5", "valarian_gunship_tier5", "valarian_gunship_tier5", "valarian_gunship_tier5", "valarian_gunship_tier5" },
		G[8] .. ": five gunships and no bomber (FN-7, D-15)")
end

-- AC-5 (c): completing the surprise attack starts recovery 3c; the mission is not failed while 3c runs
function TestSmugglerT4Chain3:test_completing_the_surprise_attack_starts_recovery_3c()
	local player = chain(3, "space_tatooine")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")
	N.setState(player, G[7], "complete")
	begin(player, G[8])
	pump(30000, G[8] .. " running")

	local ships = spawnedCopy()

	killAll(player, ships, G[8])
	pump(5000, G[8] .. " after the kills")
	lu.assertTrue(isComplete(player, quest(G[8])), G[8] .. ": complete after the gunships are destroyed")
	pump(3000, G[8] .. " split delay")
	lu.assertTrue(isActive(player, quest(G[9])), G[9] .. ": active after the split delay")
	N.requireConversation(lu)
	lu.assertFalse(handler():isFailed(player, 3), "isFailed(3) while 3c runs")
	lu.assertFalse(handler():isWon(player, 3), "isWon(3) before 3c is complete")
end

-- AC-5 (d): 3b failing by leaving the zone starts nothing and makes the mission failed
function TestSmugglerT4Chain3:test_3b_failing_by_leaving_the_zone_starts_nothing_and_fails_the_mission()
	local player = chain(3, "space_tatooine")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")

	local q = quest(G[7])

	deploy(player, G[7])
	q:failLeftZone(player)
	pump(30000, G[7] .. " after the failure")
	lu.assertFalse(isActive(player, q), G[7] .. ": failed")
	lu.assertFalse(isActive(player, quest(G[8])), G[8] .. ": the surprise attack does not start")
	lu.assertFalse(isActive(player, quest(G[9])), G[9] .. ": recovery 3c does not start")
	N.requireConversation(lu)
	lu.assertTrue(handler():isFailed(player, 3), "isFailed(3): attempted, not won, nothing running")
end

-- AC-5 (d): leaving the zone for real (ZONESWITCHED) also fails it without a split
function TestSmugglerT4Chain3:test_leaving_the_zone_during_3b_fails_it_without_a_split()
	local player = chain(3, "space_tatooine")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")
	deploy(player, G[7])
	H.zoneSwitch(player, "space_naboo")
	pump(30000, G[7] .. " after leaving")
	lu.assertFalse(isActive(player, quest(G[7])), G[7] .. ": failed")
	lu.assertFalse(isActive(player, quest(G[8])), G[8] .. ": no surprise attack")
	lu.assertFalse(isActive(player, quest(G[9])), G[9] .. ": no recovery")
end

-- AC-5 (e): recovery 3c spawns the mining freighter (Endor); completing it makes mission 3 won
function TestSmugglerT4Chain3:test_recovery_3c_spawns_the_mining_freighter_and_completing_it_wins_mission_3()
	local player = chain(3, "space_endor")

	N.setMission(player, 3, "attempted")
	N.setState(player, G[6], "complete")
	N.setState(player, G[7], "complete")

	local before = #H.spawnedShips()
	local run = DRS.startRecoveryRun(quest(G[9]), player)

	pump(10000, G[9] .. " after the ship arrived")
	lu.assertEquals(run.ship.shipName, "valarian_freighterlight_mining_tier4", G[9] .. ": the recovery ship")
	lu.assertEquals(run.ship.zone, "space_endor", G[9] .. ": the recovery ship zone")

	local names = {}

	for i = before + 1, #H.spawnedShips() do
		names[#names + 1] = H.spawnedShips()[i].shipName
	end

	lu.assertEquals(countOf(names, "valarian_bomber_tier5"), 2, G[9] .. ": bomber escorts among " .. table.concat(names, ", "))
	lu.assertEquals(countOf(names, "valarian_gunship_tier4"), 2, G[9] .. ": gunship escorts among " .. table.concat(names, ", "))
	completeAndSplit(player, G[9], nil)
	pump(8000, G[9] .. " after completion")
	noMemberActive(player, 3)
	N.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 3), "mission 3 is won")
	lu.assertFalse(handler():isFailed(player, 3), "and not failed")
end

---------------------------------------------------------------------------------------------
-- AC-5 (f): mission 4 (Lok, Lok, Dantooine)
---------------------------------------------------------------------------------------------

TestSmugglerT4Chain4 = {}

function TestSmugglerT4Chain4:setUp() H.reset() end

function TestSmugglerT4Chain4:tearDown() AC.tearDown() end

-- AC-5 (f): assassinate 4a spawns the TIE Oppressor with four advanced TIEs; killing all of them completes it and starts 4b 5 s later
function TestSmugglerT4Chain4:test_assassinate_4a_needs_the_oppressor_and_four_escorts_and_starts_4b_five_seconds_later()
	local player = chain(4)
	local target, rest = deploy(player, G[10])

	lu.assertNotNil(target, "the target imp_tie_oppressor_tier5 spawned")
	lu.assertEquals(#rest, 4, "escorts")

	for _, s in ipairs(rest) do
		lu.assertEquals(s.shipName, "imp_tie_advanced_tier4", "escort ship")
	end

	H.destroyShip(target, player.rootParent)
	pump(5000, G[10] .. " after the target")
	lu.assertFalse(isComplete(player, quest(G[10])), "not complete with the escorts alive")
	killAll(player, rest, G[10])
	pump(3000, G[10] .. " after the last kill")
	lu.assertTrue(isComplete(player, quest(G[10])), G[10] .. ": complete")
	pump(5000, G[10] .. " split")
	lu.assertTrue(isActive(player, quest(G[11])), G[11] .. ": active after the split delay")
end

-- AC-5 (f): assassinate 4b spawns the CorSec gunship with three interdiction craft
function TestSmugglerT4Chain4:test_assassinate_4b_spawns_the_corsec_gunship_with_three_interdiction_craft()
	local player = chain(4)

	N.setState(player, G[10], "complete")

	local target, rest = deploy(player, G[11])

	lu.assertNotNil(target, "the target corsec_gunship_tier4 spawned")
	lu.assertEquals(#rest, 3, "escorts")

	for _, s in ipairs(rest) do
		lu.assertEquals(s.shipName, "corsec_interdiction_craft_tier4", "escort ship")
	end

	completeAndSplit(player, G[11], G[12])
end

-- AC-5 (f): assassinate 4c (Dantooine) spawns the RSF ace with four stingers; killing all makes mission 4 won
function TestSmugglerT4Chain4:test_assassinate_4c_spawns_the_rsf_ace_and_winning_it_wins_mission_4()
	local player = chain(4, "space_dantooine")

	N.setState(player, G[10], "complete")
	N.setState(player, G[11], "complete")

	local target, rest = deploy(player, G[12])

	lu.assertNotNil(target, "the target rsf_ace_tier5 spawned")
	lu.assertEquals(#rest, 4, "escorts")

	for _, s in ipairs(rest) do
		lu.assertEquals(s.shipName, "rsf_stinger_tier4", "escort ship")
	end

	H.destroyShip(target, player.rootParent)
	killAll(player, rest, G[12])
	pump(5000, G[12] .. " after the last kill")
	lu.assertTrue(isComplete(player, quest(G[12])), G[12] .. ": complete")
	noMemberActive(player, 4)
	N.requireConversation(lu)
	lu.assertTrue(handler():isWon(player, 4), "mission 4 is won")
end

---------------------------------------------------------------------------------------------
-- The duties run (spawned / active)
---------------------------------------------------------------------------------------------

TestSmugglerT4DutyRuns = {}

function TestSmugglerT4DutyRuns:setUp() H.reset() end

function TestSmugglerT4DutyRuns:tearDown() AC.tearDown() end

-- AC-5 (g): each duty starts through its own table, becomes active, and spawns without a Lua error
function TestSmugglerT4DutyRuns:test_each_duty_starts_active_and_spawns_without_a_lua_error()
	for _, global in ipairs(N.DUTIES) do
		H.reset()

		local q = quest(global)

		q:start()

		if q.questType == "recovery_duty" then
			AC.resolveRecoveryPoints(q)
		end

		local player = newPlayer(q.questZone)

		q:startQuest(player, "")
		pump(0, global .. " start")
		pump(60000, global .. " after a minute")
		lu.assertTrue(isActive(player, q), global .. ": active")
		lu.assertTrue(#H.spawnedShips() >= 1 or #H.spawnedAreas() >= 1, global .. ": something spawned (ships or areas)")
	end
end

-- AC-5: surrender cleanup of a running duty and chain is checked by test_smuggler_tier4_surrender.lua
