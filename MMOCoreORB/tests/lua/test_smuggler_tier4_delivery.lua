-- Smuggler tier 4: the first cross-zone delivery (SC-1 SpaceDeliveryScreenplay per-leg zones, SC-2 SpaceAttackWaves:getWaveZone).
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-3; Shared code changes SC-1, SC-2; D-13; R-1).
--
-- delivery/tatooine_privateer_tier4_1a picks up in space_lok and delivers in space_dantooine (SWG delivery.java:77-121). The scenario is delivery_scenario.lua's; the
-- player's zone changes the way the server's PlayerSpaceZoneComponent does it: ZONESWITCHED fires with the OLD zone still readable, then the player moves (H.zoneSwitch).
-- The second half proves that every other delivery quest of Core3 (the 13 enumerated below), and survival and rescue waves, behave as before.

local lu = require("luaunit")
local H = require("harness")
local D = require("delivery_scenario")
local N = require("smuggler_tier4_data")

D.load()
N.load()
H.loadSquadron("BlackEpsilonSquadronScreenplay")

local function secs(n) return n * 1000 end

local ONE_A = { "delivery", "tatooine_privateer_tier4_1a" }
local ONE_B = "delivery_no_pickup_tatooine_privateer_tier4_1b"

local function fresh(q, opts) return D.fresh(q[1], q[2], opts) end

local function areaCalls() return H.Engine.callsTo("spawnSpaceActiveArea") end

-- Every waypoint the pilot got so far, in creation order: the removed ones (the ghost fake keeps them) and the current ones
local function waypointsOf(player)
	local out = {}

	for _, w in ipairs(player.ghost.removedWaypoints) do
		out[#out + 1] = w
	end

	for _, w in ipairs(player.ghost.waypoints) do
		out[#out + 1] = w
	end

	table.sort(out, function(a, b) return a.objectID < b.objectID end)
	return out
end

-- zone of the n-th spawnSpaceActiveArea / addWaypoint call
local function areaZone(n) return areaCalls()[n][1] end

-- The spawn zone of every spawnShipAgent call whose ship is `shipName`
local function spawnZones(shipName)
	local out = {}

	for _, s in ipairs(D.spawns()) do
		if s.name == shipName then
			out[#out + 1] = s.zone
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-3: delivery 1a, lok -> dantooine
---------------------------------------------------------------------------------------------

TestSmugglerT4CrossZone = {}

function TestSmugglerT4CrossZone:setUp() H.reset() end

-- AC-3: leg 1 happens in space_lok: the pickup area, the waypoint and the transport
function TestSmugglerT4CrossZone:test_the_pickup_area_waypoint_and_transport_are_in_space_lok()
	local sc = fresh(ONE_A):start()

	lu.assertEquals(#areaCalls(), 1, "one area after the start")
	lu.assertEquals(areaZone(1), "space_lok", "pickup area zone")
	lu.assertEquals({ areaCalls()[1][3], areaCalls()[1][4], areaCalls()[1][5] }, { sc.o.pickup.x, sc.o.pickup.z, sc.o.pickup.y }, "pickup area position (the lok point)")
	lu.assertEquals(#waypointsOf(sc.player), 1, "one waypoint after the start")
	lu.assertEquals(waypointsOf(sc.player)[1].planet, "space_lok", "pickup waypoint planet")
	lu.assertEquals({ waypointsOf(sc.player)[1].x, waypointsOf(sc.player)[1].z, waypointsOf(sc.player)[1].y }, { sc.o.pickup.x, sc.o.pickup.z, sc.o.pickup.y }, "pickup waypoint position")

	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnZones("nym_freightermedium_tier4"), { "space_lok" }, "the pickup transport's zone")
end

-- AC-3: after the dock the delivery leg's area and waypoint are in space_dantooine, at the dantooine point
function TestSmugglerT4CrossZone:test_after_the_dock_the_delivery_area_and_waypoint_are_in_space_dantooine()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(2))
	lu.assertEquals(#areaCalls(), 2, "the delivery leg area exists 2 s after the dock")
	lu.assertEquals(areaZone(2), "space_dantooine", "delivery area zone")
	lu.assertEquals({ areaCalls()[2][3], areaCalls()[2][4], areaCalls()[2][5] }, { sc.o.delivery.x, sc.o.delivery.z, sc.o.delivery.y }, "delivery area position")
	lu.assertEquals(sc.o.delivery.zone, "space_dantooine", "the .tab puts the delivery point in space_dantooine")
	lu.assertEquals(#waypointsOf(sc.player), 2, "the delivery waypoint")
	lu.assertEquals(waypointsOf(sc.player)[2].planet, "space_dantooine", "delivery waypoint planet")
	lu.assertEquals({ waypointsOf(sc.player)[2].x, waypointsOf(sc.player)[2].z, waypointsOf(sc.player)[2].y }, { sc.o.delivery.x, sc.o.delivery.z, sc.o.delivery.y }, "delivery waypoint position")
	lu.assertTrue(sc:active(), "the quest is still active")
end

-- AC-3, D-13: a switch from lok to dantooine on leg 2 keeps the quest, the observer and removes the live attack ships
function TestSmugglerT4CrossZone:test_a_switch_from_lok_to_dantooine_on_leg_2_keeps_the_quest_and_removes_the_live_attack_ships()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(sc.o.period + 1))

	local waves = D.attackWaves(sc)

	lu.assertTrue(#waves >= 1, "a wave is alive before the switch")

	H.zoneSwitch(sc.player, "space_dantooine")
	H.advance(secs(3)) -- the removed ships are destroyed by a delayed event

	lu.assertTrue(sc:active(), "the quest survives lok -> dantooine on leg 2")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, sc.className, "enteredZone", sc.player), "the ZONESWITCHED observer stays")

	for i, wave in ipairs(waves) do
		for j, agent in ipairs(wave.agents) do
			lu.assertTrue(agent.destroyed, "wave " .. i .. " ship " .. j .. " is removed by the switch")
		end
	end

	lu.assertEquals(D.count(sc:events(), "mission_abandoned"), 0, "no mission_abandoned update")
end

-- AC-3, SC-2: after the switch the next wave spawns in space_dantooine
function TestSmugglerT4CrossZone:test_the_next_wave_spawns_in_space_dantooine()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(2))
	H.zoneSwitch(sc.player, "space_dantooine")
	sc:atDock(secs(sc.o.period))

	local waves = D.attackWaves(sc)

	lu.assertEquals(#waves, 1, "the wave of the first period after the dock")

	for i, s in ipairs(waves[1].spawns) do
		lu.assertEquals(s.zone, "space_dantooine", "attack ship " .. i .. " (" .. tostring(s.name) .. ") spawn zone")
	end

	lu.assertTrue(sc:active(), "the quest is still active")
end

-- AC-3, SC-2 (amended): a wave that fires on leg 2 before the jump spawns in space_lok, near the pilot's ship
function TestSmugglerT4CrossZone:test_a_wave_before_the_jump_spawns_in_space_lok_near_the_pilot()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(sc.o.period + 1))

	local waves = D.attackWaves(sc)

	lu.assertEquals(#waves, 1, "the wave of the first period after the dock")

	for i, s in ipairs(waves[1].spawns) do
		lu.assertEquals(s.zone, "space_lok", "attack ship " .. i .. " (" .. tostring(s.name) .. ") spawn zone")
		lu.assertTrue(math.abs(s.x - sc.ship.x) < 3000 and math.abs(s.y - sc.ship.y) < 3000, "attack ship " .. i .. " spawns near the pilot")
	end
end

-- AC-3: leg 1's waves (none before the pickup dock) and the pickup leg spawn nothing outside space_lok
function TestSmugglerT4CrossZone:test_nothing_spawns_outside_space_lok_during_leg_1()
	local sc = fresh(ONE_A):start():arrive()

	sc:at(secs(600))

	for _, s in ipairs(D.spawns()) do
		lu.assertEquals(s.zone, "space_lok", "spawn " .. tostring(s.name) .. " during leg 1")
	end
end

-- AC-3: arriving and docking in dantooine completes 1a and starts delivery_no_pickup 1b 5 s later
function TestSmugglerT4CrossZone:test_arriving_and_docking_in_dantooine_completes_1a_and_starts_1b_five_seconds_later()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(2))
	H.zoneSwitch(sc.player, "space_dantooine")
	H.advance(0)
	sc:arrive()
	sc:at(secs(6))
	lu.assertEquals(spawnZones("hutt_transport_tier4"), { "space_dantooine" }, "the delivery transport's zone")
	sc:dock()
	sc:atDock(secs(3))
	lu.assertTrue(sc:complete(), "delivery 1a is complete after the delivery dock")
	lu.assertFalse(sc:active(), "and no longer active")
	lu.assertEquals(#sc.spies.start[ONE_B], 0, "1b has not started at the completion")

	local t = H.now()

	H.advance(secs(4))
	lu.assertEquals(#sc.spies.start[ONE_B], 0, "1b has not started 4 s after the completion (sideQuestDelay 5 s)")
	H.advance(secs(4))
	lu.assertEquals(#sc.spies.start[ONE_B], 1, "1b started once, " .. (H.now() - t) .. " ms after the completion")
	lu.assertEquals(sc.spies.start[ONE_B][1].args[1], sc.player, "1b gets the pilot")
end

-- AC-3: the whole run on a second Lua VM (every step on a fresh VM, as the server's thread pool can do) completes too
function TestSmugglerT4CrossZone:test_every_step_on_a_fresh_vm_completes_the_run()
	D.snapshotVm()

	local sc = fresh(ONE_A)

	D.resetVm()
	sc:start()
	D.resetVm()
	sc:arrive()
	sc:at(secs(10))
	D.resetVm()
	sc:dock()
	sc:atDock(secs(2))
	D.resetVm()
	H.zoneSwitch(sc.player, "space_dantooine")
	D.resetVm()
	H.advance(0)
	sc:arrive()
	sc:at(secs(6))
	D.resetVm()
	sc:dock()
	sc:atDock(secs(3))
	lu.assertTrue(sc:complete(), "delivery 1a completes on a fresh VM at every step")
end

-- AC-3: a switch to any other zone fails the quest on leg 2
function TestSmugglerT4CrossZone:test_a_switch_to_another_zone_on_leg_2_fails_the_quest()
	for _, zone in ipairs({ "space_tatooine", "space_endor", "space_naboo" }) do
		local sc = fresh(ONE_A):toFirstDock()

		sc:atDock(secs(2))
		H.zoneSwitch(sc.player, zone)
		H.advance(0)
		lu.assertFalse(sc:active(), "a switch to " .. zone .. " on leg 2 ends the quest")
		lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 1, zone .. ": mission_abandoned update")
	end
end

-- AC-3: a switch on leg 1 (before the pickup dock), even to the delivery zone, fails the quest as today
function TestSmugglerT4CrossZone:test_a_switch_to_dantooine_on_leg_1_fails_the_quest()
	local sc = fresh(ONE_A):start()

	H.zoneSwitch(sc.player, "space_dantooine")
	H.advance(0)
	lu.assertFalse(sc:active(), "lok -> dantooine on leg 1 ends the quest")
	lu.assertEquals(D.count(sc:events(), "mission_abandoned", "update"), 1, "mission_abandoned update")
end

-- AC-3: after the crossing, leaving dantooine fails the quest; so does going back to lok
function TestSmugglerT4CrossZone:test_leaving_dantooine_after_the_crossing_fails_the_quest()
	for _, zone in ipairs({ "space_lok", "space_tatooine" }) do
		local sc = fresh(ONE_A):toFirstDock()

		sc:atDock(secs(2))
		H.zoneSwitch(sc.player, "space_dantooine")
		H.advance(0)
		lu.assertTrue(sc:active(), "precondition: crossed")
		H.zoneSwitch(sc.player, zone)
		H.advance(0)
		lu.assertFalse(sc:active(), "dantooine -> " .. zone .. " ends the quest")
	end
end

-- AC-3, D-13: only pickup zone -> delivery zone counts: a respawn in lok, or a switch into dantooine from another zone, fails
function TestSmugglerT4CrossZone:test_a_respawn_in_lok_or_a_switch_into_dantooine_from_another_zone_fails_the_quest()
	local sc = fresh(ONE_A):toFirstDock()

	sc:atDock(secs(2))
	H.zoneSwitch(sc.player, "space_lok")
	H.advance(0)
	lu.assertFalse(sc:active(), "a respawn in the same zone (lok -> lok) on leg 2 ends the quest")

	sc = fresh(ONE_A):toFirstDock()
	sc:atDock(secs(2))
	sc.player.zone = "space_tatooine"
	H.zoneSwitch(sc.player, "space_dantooine")
	H.advance(0)
	lu.assertFalse(sc:active(), "tatooine -> dantooine on leg 2 ends the quest (the player's zone is not the pickup zone)")
end

-- AC-3: the run starts when the pilot is in the FIRST leg's zone (lok), not in the delivery zone
function TestSmugglerT4CrossZone:test_the_run_sets_up_in_the_pickup_zone_only()
	local sc = fresh(ONE_A, { zone = "space_dantooine" })

	sc:start()
	lu.assertEquals(#areaCalls(), 0, "a pilot who starts the quest in dantooine gets no area yet")
	lu.assertTrue(sc:active(), "the quest is active and waits for lok")
	H.zoneSwitch(sc.player, "space_lok")
	H.advance(secs(2))
	lu.assertEquals(#areaCalls(), 1, "entering lok sets the run up")
	lu.assertEquals(areaZone(1), "space_lok", "pickup area zone")
	lu.assertTrue(sc:active(), "the quest is still active")
end

-- AC-3: the fields of 1a, and the defaults of the class
function TestSmugglerT4CrossZone:test_the_class_has_the_zone_fields_and_helpers_and_1a_sets_only_the_delivery_zone()
	lu.assertEquals(SpaceDeliveryScreenplay.pickupZone, "", "SpaceDeliveryScreenplay.pickupZone default")
	lu.assertEquals(SpaceDeliveryScreenplay.deliveryZone, "", "SpaceDeliveryScreenplay.deliveryZone default")

	local q = N.quest(N.GLOBALS[1])

	lu.assertEquals(q:getLegZone(1), "space_lok", "getLegZone(1)")
	lu.assertEquals(q:getLegZone(2), "space_dantooine", "getLegZone(2)")
	lu.assertEquals(rawget(q, "deliveryZone"), "space_dantooine", "1a deliveryZone")
	lu.assertNil(rawget(q, "pickupZone"), "1a pickupZone")
	lu.assertEquals(type(SpaceAttackWaves.getWaveZone), "function", "SpaceAttackWaves:getWaveZone")
	lu.assertEquals(type(rawget(SpaceDeliveryScreenplay, "getWaveZone")), "function", "SpaceDeliveryScreenplay overrides getWaveZone (after the mixin)")
	lu.assertTrue(rawget(SpaceDeliveryScreenplay, "getWaveZone") ~= SpaceAttackWaves.getWaveZone, "and it is not the mixin's copy")
end

---------------------------------------------------------------------------------------------
-- AC-3: every other delivery, survival and rescue quest is unaffected
---------------------------------------------------------------------------------------------

TestSmugglerT4DeliveryUnaffected = {}

function TestSmugglerT4DeliveryUnaffected:setUp() H.reset() end

-- The 13 delivery tables that exist before this feature (enumerated: a new one forces a decision here)
local EXISTING = {
	{ "delivery", "corellia_privateer_tier3_2_b" }, { "delivery", "corellia_privateer_tier3_3" }, { "delivery_no_pickup", "corellia_privateer_tier3_4_c" },
	{ "delivery_no_pickup", "corellia_imperial_tier3_1_b" }, { "delivery_no_pickup", "corellia_imperial_tier4_2_b" },
	{ "delivery_no_pickup", "naboo_privateer_tier3_3b" }, { "delivery", "naboo_privateer_tier4_3a" },
	{ "delivery", "corellia_rebel_tier3_2_a" }, { "delivery", "corellia_rebel_tier3_3" }, { "delivery_no_pickup", "corellia_rebel_tier4_2_a" },
	{ "delivery_no_pickup", "tatooine_privateer_tier3_3" }, { "delivery_no_pickup", "tatooine_privateer_tier3_3_a" }, { "delivery_no_pickup", "tatooine_privateer_tier3_3_b" },
}

-- AC-3: the enumeration is complete: these 13 plus 1a and 1b are every delivery table
function TestSmugglerT4DeliveryUnaffected:test_the_13_existing_deliveries_plus_1a_and_1b_are_every_delivery_table()
	local want = {}

	for _, q in ipairs(EXISTING) do
		want[#want + 1] = q[1] .. "_" .. q[2]
	end

	want[#want + 1] = N.GLOBALS[1]
	want[#want + 1] = N.GLOBALS[2]
	table.sort(want)

	local got = {}

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if (q.questType == "delivery" or q.questType == "delivery_no_pickup") and q.questName ~= "" then
			got[#got + 1] = name
		end
	end

	table.sort(got)
	lu.assertEquals(got, want, "delivery quest globals after loading every squadron")
end

-- AC-3: none of them sets a zone of its own, so both legs are the quest zone
function TestSmugglerT4DeliveryUnaffected:test_the_existing_deliveries_set_no_leg_zone_and_both_legs_are_the_quest_zone()
	for _, q in ipairs(EXISTING) do
		local name = q[1] .. "_" .. q[2]
		local quest = H.expectGlobal(name, "delivery quest table")

		lu.assertNil(rawget(quest, "pickupZone"), name .. ": pickupZone")
		lu.assertNil(rawget(quest, "deliveryZone"), name .. ": deliveryZone")
		lu.assertEquals(quest:getLegZone(1), quest.questZone, name .. ": getLegZone(1)")
		lu.assertEquals(quest:getLegZone(2), quest.questZone, name .. ": getLegZone(2)")
	end
end

-- AC-3: every area, waypoint and ship of a full run of each existing delivery is in its quest zone, and a switch to another zone ends it as before
function TestSmugglerT4DeliveryUnaffected:test_every_existing_delivery_runs_in_its_quest_zone_and_fails_on_a_zone_switch()
	for _, q in ipairs(EXISTING) do
		local sc = D.fresh(q[1], q[2])
		local zone = sc.o.zone

		if sc.o.hasPickup then
			sc:toFirstDock()
			sc:atDock(secs(2))
			sc:arrive()
			sc:at(secs(6))
			sc:dock()
			sc:atDock(secs(sc.o.period + 5))
		else
			sc:start()
			sc:arrive()
			sc:at(secs(6))
			sc:dock()
			sc:atDock(secs(sc.o.period + 20))
		end

		for i, call in ipairs(areaCalls()) do
			lu.assertEquals(call[1], zone, q[2] .. ": area " .. i .. " zone")
		end

		for i, w in ipairs(waypointsOf(sc.player)) do
			lu.assertEquals(w.planet, zone, q[2] .. ": waypoint " .. i .. " planet")
		end

		lu.assertTrue(#D.spawns() >= 1, q[2] .. ": ships were spawned")

		for _, s in ipairs(D.spawns()) do
			lu.assertEquals(s.zone, zone, q[2] .. ": ship " .. tostring(s.name) .. " spawn zone")
		end

		H.zoneSwitch(sc.player, zone == "space_endor" and "space_naboo" or "space_endor")
		H.advance(0)
		lu.assertFalse(sc:active(), q[2] .. ": a zone switch ends the quest (as before)")
	end
end

-- AC-3: an existing delivery whose leg 2 is under way still fails when the pilot switches to ANY zone, including the other quests' zones
function TestSmugglerT4DeliveryUnaffected:test_an_existing_delivery_in_leg_2_fails_on_a_switch_to_any_zone()
	local q = { "delivery", "corellia_rebel_tier3_3" }

	for _, zone in ipairs({ "space_corellia", "space_dantooine", "space_tatooine" }) do
		local sc = D.fresh(q[1], q[2])

		sc:toFirstDock()
		sc:atDock(secs(2))
		H.zoneSwitch(sc.player, zone)
		H.advance(0)
		lu.assertFalse(sc:active(), q[2] .. ": a switch to " .. zone .. " on leg 2 ends the quest")
	end
end

-- SC-2: survival and rescue keep the default wave zone; every delivery other than 1a (amended SC-1: waves spawn in the
-- pilot's zone) still spawns in its quest zone, since it fails on any zone switch and the pilot is always in that zone
function TestSmugglerT4DeliveryUnaffected:test_the_wave_zone_is_the_quest_zone_for_survival_rescue_and_the_existing_deliveries()
	local player = H.newPlayer({ zone = "space_dantooine", ship = true })
	local checked = 0

	for _, name in ipairs(H.questGlobals()) do
		local q = rawget(_G, name)

		if q.questName ~= "" and q.getWaveZone ~= nil and name ~= N.GLOBALS[1] then
			local pilot = player

			if (string.find(q.questType, "^delivery") ~= nil) then
				pilot = H.newPlayer({ zone = q.questZone, ship = true })
			end

			lu.assertEquals(q:getWaveZone(pilot), q.questZone, name .. ": getWaveZone")
			checked = checked + 1
		end
	end

	lu.assertTrue(checked >= 30, "quests with the wave hook checked: " .. checked)
end

-- SC-2 (amended 2026-11-03): delivery 1a's wave zone is the zone the pilot's ship is in, as SWG delivery.java:558-627
function TestSmugglerT4DeliveryUnaffected:test_delivery_1a_wave_zone_is_the_zone_of_the_pilots_ship()
	-- leg 2 before the jump: the pilot is still in lok, so the zone is lok (not the leg's dantooine)
	local sc = D.fresh(ONE_A[1], ONE_A[2]):toFirstDock()

	lu.assertEquals(sc.player.rootParent.zone, "space_lok", "the pilot's ship is in lok after the pickup dock")
	lu.assertEquals(sc.quest:getWaveZone(sc.player), "space_lok", "leg 2, before the jump")

	-- after the crossing: dantooine
	H.zoneSwitch(sc.player, "space_dantooine")
	lu.assertEquals(sc.quest:getWaveZone(sc.player), "space_dantooine", "leg 2, after the jump")

	-- during the pickup leg
	local sc2 = D.fresh(ONE_A[1], ONE_A[2]):start()

	lu.assertEquals(sc2.quest:getWaveZone(sc2.player), "space_lok", "during the pickup leg")
end

-- SC-2 (amended): without a ship under the pilot the wave zone falls back to the quest zone
function TestSmugglerT4DeliveryUnaffected:test_delivery_1a_wave_zone_falls_back_to_the_quest_zone_without_a_ship()
	local sc = D.fresh(ONE_A[1], ONE_A[2]):toFirstDock()

	sc.player.rootParent = nil
	lu.assertEquals(sc.quest:getWaveZone(sc.player), sc.quest.questZone, "no ship: questZone")
end
