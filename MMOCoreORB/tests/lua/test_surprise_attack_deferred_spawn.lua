-- SpaceSurpriseAttackScreenplay deferred spawn (shared change SC-1) and the RSF mission 3 ambush at runtime.
-- Spec: .claude/work/rsf-tier3-data/01-spec.md (AC-5, AC-6, AC-7, invariant I-6, Shared code changes SC-1).
--
-- SWG (script/space/quest_logic/destroy_surpriseattack.java:36-41, 51-76; fixtures/script/space/quest_logic/)
-- only spawns a surprise attack when the pilot is in the quest's zone; otherwise the quest stays granted and
-- spawns once the pilot gets there. Core3 spawned immediately, using the pilot's coordinates but the quest's zone.
--
--   * Started outside questZone, on the ground or in a yacht: the quest is active and nothing spawns (pending).
--   * ZONESWITCHED into questZone: a deferred spawn 1000 ms later (the observer runs before the pilot is moved), only
--     if the quest is still active and pending, the pilot is in questZone and in a ship that is not the yacht.
--   * Started in questZone in a ship: spawns synchronously in startQuest, exactly as before (AC-6 pins the call log).
--
-- The "pending" state lives in shared memory, not in a Lua field: the tests re-create the Lua state another worker
-- thread would see ("second VM", README) between the start and the deferred event.

local lu = require("luaunit")
local H = require("harness")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local Engine = H.Engine
local YACHT = "player_sorosuub_space_yacht"

local E3 = "destroy_surpriseattack_naboo_privateer_tier3_3e"
local C3 = "survival_naboo_privateer_tier3_3c"

local function quest(global) return H.expectGlobal(global, "surprise attack quest table") end

local function surpriseAttacks()
	local out = {}

	for _, name in ipairs(H.questGlobals()) do
		if rawget(_G, name).questType == "destroy_surpriseattack" then
			out[#out + 1] = name
		end
	end

	return out
end

-- Total ships a quest's surpriseAttackShips ask for
local function totalShips(q)
	local n = 0

	for _, entry in ipairs(q.surpriseAttackShips.spawns) do
		n = n + entry.count
	end

	return n
end

local function spawnCalls() return Engine.callsTo("spawnShipAgent") end

local function isActive(player, q) return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) end

local function isComplete(player, q) return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) end

local function spawnedKeys(player)
	local out = {}

	for _, key in ipairs(Engine.sharedMemoryKeys()) do
		if key:match(":spawned$") then
			out[#out + 1] = key
		end
	end

	return out
end

-- A pilot in a ship in `zone` who starts `global` (the quest's own startQuest, as a split or trainer does).
local function started(global, zone, opts)
	opts = opts or {}

	H.reset()

	local q = quest(global)
	local playerOpts = { name = "Ace", zone = zone, pilot = "neutral" }

	if opts.ground then
		playerOpts.parent = "starport"
	else
		playerOpts.ship = opts.ship or true
	end

	local player = H.newPlayer(playerOpts)

	q:startQuest(player, "")

	return q, player
end

---------------------------------------------------------------------------------------------
-- "Second VM": Lua upvalues and fields of the surprise attack tables go back to their load-time value
---------------------------------------------------------------------------------------------

local vmSnapshot

local function isScalar(v)
	local t = type(v)
	return t == "number" or t == "string" or t == "boolean"
end

local function vmTables()
	local out = { SpaceSurpriseAttackScreenplay }

	for _, name in ipairs(surpriseAttacks()) do
		out[#out + 1] = rawget(_G, name)
	end

	return out
end

local function snapshotVm()
	vmSnapshot = { upvalues = {}, fields = {} }

	for _, tbl in ipairs(vmTables()) do
		vmSnapshot.fields[tbl] = {}

		for k, v in pairs(tbl) do
			if isScalar(v) then
				vmSnapshot.fields[tbl][k] = v
			elseif type(v) == "function" then
				local i = 1

				while true do
					local name, val = debug.getupvalue(v, i)

					if name == nil then
						break
					end

					if type(val) == "number" then
						vmSnapshot.upvalues[#vmSnapshot.upvalues + 1] = { fn = v, index = i, value = val }
					end

					i = i + 1
				end
			end
		end
	end
end

local function resetVm()
	for _, u in ipairs(vmSnapshot.upvalues) do
		debug.setupvalue(u.fn, u.index, u.value)
	end

	for tbl, fields in pairs(vmSnapshot.fields) do
		for k, v in pairs(tbl) do
			if isScalar(v) and fields[k] == nil then
				rawset(tbl, k, nil)
			end
		end

		for k, v in pairs(fields) do
			rawset(tbl, k, v)
		end
	end
end

snapshotVm()

---------------------------------------------------------------------------------------------
-- AC-5: a surprise attack started outside its zone waits for the pilot
---------------------------------------------------------------------------------------------

TestSurpriseAttackDeferredSpawn = {}

function TestSurpriseAttackDeferredSpawn:setUp()
	H.reset()
	resetVm()
end

-- AC-5
function TestSurpriseAttackDeferredSpawn:test_started_in_lok_the_naboo_ambush_is_active_and_spawns_nothing()
	local q, player = started(E3, "space_lok")

	lu.assertTrue(isActive(player, q), "3e is active in the journal")
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls at start")
	H.advance(10000)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls after 10 s in Lok")
	lu.assertTrue(H.hasObserver(ZONESWITCHED, q.className, "enteredZone", player), "the zone observer is set")
	lu.assertEquals(#player.missionObjects, 0, "no mission objects yet")
	lu.assertEquals(readData(player.objectID .. q.className .. ":Count") or 0, 0, "no kill count yet (readData of an absent key is 0)")
end

-- AC-5: the spawn waits 1 s after the switch, never runs inside the ZONESWITCHED observer.
function TestSurpriseAttackDeferredSpawn:test_entering_naboo_in_a_ship_spawns_the_five_marauders_one_second_after_the_switch()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_naboo", { ship = { x = 100, z = 200, y = 300 } })

	lu.assertEquals(#spawnCalls(), 0, "no spawn inside the zone switch observer")
	H.advance(999)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls 999 ms after the switch")
	H.advance(1)

	local calls = spawnCalls()

	lu.assertEquals(#calls, 5, "spawnShipAgent calls 1000 ms after the switch")

	for i, c in ipairs(calls) do
		lu.assertEquals(c[1], "blacksun_marauder_tier3", "ship " .. i .. ": shipName")
		lu.assertEquals(c[2], "space_naboo", "ship " .. i .. ": zone")
		-- in front of the new ship (fake: x + 600, z + 7, y + 1200) plus the fake random 100 on x and y
		lu.assertEquals({ c[3], c[4], c[5] }, { 800, 207, 1600 }, "ship " .. i .. ": position in front of the entered ship")
	end

	lu.assertEquals(#player.missionObjects, 5, "five mission objects")
	lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), 5, "kill count")
	lu.assertTrue(isActive(player, q), "3e is still active")
end

-- AC-5, spec SC-1 item 3: the pending state is not a Lua field. Re-create the Lua state another worker would run
-- the deferred event in, at both points in time.
function TestSurpriseAttackDeferredSpawn:test_the_pending_state_survives_a_different_lua_vm()
	local q, player = started(E3, "space_lok")

	lu.assertEquals(#spawnCalls(), 0, "precondition: nothing spawned while the pilot is in Lok")
	resetVm()
	H.zoneSwitch(player, "space_naboo", { ship = true })
	resetVm()
	H.advance(1000)

	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls after the VM was reset twice")
end

-- AC-5, I-6: no second spawn in the same run, however often the pilot enters the zone.
function TestSurpriseAttackDeferredSpawn:test_entering_the_zone_twice_before_the_deferred_spawn_runs_spawns_once()
	local q, player = started(E3, "space_lok")

	lu.assertEquals(#spawnCalls(), 0, "precondition: nothing spawned while the pilot is in Lok")
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(300)
	H.zoneSwitch(player, "space_naboo")
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls")
end

-- AC-5, I-6
function TestSurpriseAttackDeferredSpawn:test_entering_the_zone_again_after_the_spawn_creates_no_more_ships()
	local q, player = started(E3, "space_lok")

	lu.assertEquals(#spawnCalls(), 0, "precondition: nothing spawned while the pilot is in Lok")
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "precondition: the ambush spawned")

	H.zoneSwitch(player, "space_naboo")
	H.advance(5000)
	H.zoneSwitch(player, "space_lok")
	H.advance(5000)
	H.zoneSwitch(player, "space_naboo")
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls after re-entering the zone")
	lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), 5, "kill count is not reset")
end

-- AC-5: a pilot who is not in a ship (on the ground) gets nothing until a launch into the zone.
function TestSurpriseAttackDeferredSpawn:test_a_pilot_on_the_ground_gets_no_spawn_until_a_launch_into_the_zone()
	local q, player = started(E3, "naboo", { ground = true })

	lu.assertTrue(isActive(player, q), "3e is active")
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls at start on the ground")

	H.zoneSwitch(player, "tatooine")
	H.advance(5000)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls after zoning to another ground zone")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(999)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls 999 ms after the launch")
	H.advance(1)
	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls 1000 ms after the launch")

	for i, c in ipairs(spawnCalls()) do
		lu.assertEquals(c[2], "space_naboo", "ship " .. i .. ": zone")
	end
end

-- AC-5: arriving in the zone without a ship (still standing in the starport) spawns nothing.
function TestSurpriseAttackDeferredSpawn:test_reaching_the_zone_without_a_ship_spawns_nothing()
	local q, player = started(E3, "naboo", { ground = true })

	H.zoneSwitch(player, "space_naboo")
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls")
	lu.assertTrue(isActive(player, q), "3e stays active and keeps waiting")
end

-- AC-5: the yacht does not count, in the zone or when arriving in it.
function TestSurpriseAttackDeferredSpawn:test_a_yacht_in_the_quest_zone_gets_no_spawn_until_the_pilot_enters_the_zone_in_a_ship()
	local q, player = started(E3, "space_naboo", { ship = { objectName = YACHT } })

	lu.assertTrue(isActive(player, q), "3e is active")
	H.advance(5000)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls for a pilot in a yacht in the zone")

	H.zoneSwitch(player, "space_lok", { ship = { objectName = YACHT } })
	H.zoneSwitch(player, "space_naboo", { ship = { objectName = YACHT } })
	H.advance(5000)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls after the yacht re-entered the zone")

	H.zoneSwitch(player, "space_lok", { ship = true })
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls after entering the zone in an ordinary ship")
end

-- AC-5: a third space zone does not trigger the spawn.
function TestSurpriseAttackDeferredSpawn:test_zoning_into_a_third_space_zone_spawns_nothing()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_corellia", { ship = true })
	H.advance(5000)
	H.zoneSwitch(player, "space_dantooine", { ship = true })
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls")
	lu.assertTrue(isActive(player, q), "3e stays active")
end

-- AC-5, SC-1 item 2: the deferred method re-checks the state when it runs.
function TestSurpriseAttackDeferredSpawn:test_a_pilot_who_left_the_zone_before_the_deferred_spawn_runs_gets_it_on_the_next_entry()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(400)
	H.zoneSwitch(player, "space_lok", { ship = true })
	H.advance(5000)
	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls while the pilot is back in Lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "spawnShipAgent calls after the next entry")
end

-- AC-5, SC-1 item 2
function TestSurpriseAttackDeferredSpawn:test_a_quest_that_failed_before_the_deferred_spawn_runs_spawns_nothing()
	local q, player = started(E3, "space_lok")

	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(500)
	q:failQuest(player, "false")
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls")
	lu.assertFalse(isActive(player, q), "3e is no longer active")
end

-- AC-5, SC-1 item 2: abort (resetQuest) while pending.
function TestSurpriseAttackDeferredSpawn:test_a_reset_while_pending_leaves_nothing_to_spawn()
	local q, player = started(E3, "space_lok")

	q:resetQuest(player)
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(5000)

	lu.assertEquals(#spawnCalls(), 0, "spawnShipAgent calls")
	lu.assertEquals(spawnedKeys(player), {}, "no :spawned key")
end

-- Out of scope (finding F-5): leaving the zone after the spawn does not fail the ambush, as before.
function TestSurpriseAttackDeferredSpawn:test_leaving_the_zone_after_the_spawn_does_not_fail_the_quest()
	local q, player = started(E3, "space_lok")

	lu.assertEquals(#spawnCalls(), 0, "precondition: nothing spawned while the pilot is in Lok")
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "precondition: the ambush spawned in Naboo")
	H.zoneSwitch(player, "space_lok", { ship = true })
	H.advance(10000)

	lu.assertTrue(isActive(player, q), "3e is still active")
end

---------------------------------------------------------------------------------------------
-- AC-6: started in the zone, in a ship: identical to today
---------------------------------------------------------------------------------------------

TestSurpriseAttackInZoneRegression = {}

function TestSurpriseAttackInZoneRegression:setUp()
	H.reset()
	resetVm()
end

local function rep(n, s)
	local out = {}

	for i = 1, n do
		out[i] = s
	end

	return out
end

local function join(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- What the pilot and the engine saw during startQuest, normalized.
local function transcript(q, player)
	local calls, spawns, observers = {}, {}, {}

	for _, c in ipairs(Engine.calls) do
		calls[#calls + 1] = c.fn

		if c.fn == "spawnShipAgent" then
			spawns[#spawns + 1] = table.concat({ c.args[1], c.args[2], c.args[3], c.args[4], c.args[5] }, "|")
		elseif c.fn == "createObserver" then
			observers[#observers + 1] = c.args[1] .. "|" .. c.args[3]
		end
	end

	local messages = {}

	for _, m in ipairs(H.messageLog(player)) do
		messages[#messages + 1] = m.id .. "|" .. tostring(m.TO)
	end

	local objects = {}

	for i, entry in ipairs(player.missionObjectLog) do
		objects[i] = { entry.id == H.spawnedShips()[i].objectID, entry.last }
	end

	local effects = {}

	for i, e in ipairs(player.effects) do
		effects[i] = e.file
	end

	return {
		calls = calls, spawns = spawns, observers = observers, messages = messages, objects = objects, effects = effects,
		count = readData(player.objectID .. q.className .. ":Count"), pending = #H.pendingEvents(),
	}
end

-- Pinned from the tree before SC-1 (CorSec Rhea's surprise attack, Havoc Kreezo's, RSF Imler's tier 4 2b).
local PINNED = {
	destroy_surpriseattack_corellia_privateer_1 = {
		zone = "space_corellia", title = "@spacequest/destroy_surpriseattack/corellia_privateer_1:title",
		ships = join({ "blacksun_fighter_s02_tier1" }, rep(3, "blacksun_fighter_s01_tier1")),
	},
	destroy_surpriseattack_corellia_rebel_1 = {
		zone = "space_corellia", title = "@spacequest/destroy_surpriseattack/corellia_rebel_1:title",
		ships = rep(3, "imp_tie_fighter_tier1"),
	},
	destroy_surpriseattack_naboo_privateer_tier4_2b = {
		zone = "space_endor", title = "@spacequest/destroy_surpriseattack/naboo_privateer_tier4_2b:title",
		ships = rep(5, "blacksun_vehement_tier4"),
	},
}

local PINNED_ORDER = {
	"destroy_surpriseattack_corellia_privateer_1", "destroy_surpriseattack_corellia_rebel_1", "destroy_surpriseattack_naboo_privateer_tier4_2b",
}

-- AC-6
for _, global in ipairs(PINNED_ORDER) do
	TestSurpriseAttackInZoneRegression["test_" .. global .. "_spawns_synchronously_with_the_pinned_call_log"] = function()
		local want = PINNED[global]
		local q, player = started(global, want.zone)
		local t = transcript(q, player)
		local n = #want.ships

		local spawns, calls, observers, objects = {}, { "giveItem", "createObserver" }, { ZONESWITCHED .. "|enteredZone" }, {}

		for i, ship in ipairs(want.ships) do
			spawns[i] = ship .. "|" .. want.zone .. "|700|7|1300"
			calls[#calls + 1] = "spawnShipAgent"
			calls[#calls + 1] = "createObserver"
			observers[#observers + 1] = SHIPDESTROYED .. "|notifyShipDestroyed"
			objects[i] = { true, i == n }
		end

		lu.assertEquals(t.spawns, spawns, global .. ": spawnShipAgent arguments")
		lu.assertEquals(t.calls, calls, global .. ": engine calls in order")
		lu.assertEquals(t.observers, observers, global .. ": observers (zone switch first, then one kill observer per ship)")
		lu.assertEquals(t.objects, objects, global .. ": addSpaceMissionObject calls (every spawned ship, the last one flagged)")
		lu.assertEquals(t.count, n, global .. ": kill count")
		lu.assertEquals(t.messages, {
			"@space/quest:quest_received|" .. want.title,
			"@space/quest:quest_update_s|" .. n .. " ships have entered the area and are closing to attack!",
			"@space/quest:quest_in_progress|" .. want.title,
		}, global .. ": messages")
		lu.assertEquals(t.effects, { "clienteffect/ui_quest_spawn_wave.cef" }, global .. ": effects")
		lu.assertEquals(t.pending, 0, global .. ": no deferred event is queued when the spawn runs in startQuest")
		lu.assertTrue(isActive(player, q), global .. ": active")
	end

	-- AC-6: a second ZONESWITCHED into the zone after the spawn creates no ships.
	TestSurpriseAttackInZoneRegression["test_" .. global .. "_creates_no_more_ships_when_the_pilot_enters_the_zone_again"] = function()
		local want = PINNED[global]
		local q, player = started(global, want.zone)

		H.zoneSwitch(player, want.zone)
		H.advance(5000)

		lu.assertEquals(#spawnCalls(), #want.ships, global .. ": spawnShipAgent calls")
		lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), #want.ships, global .. ": kill count")
	end
end

-- AC-6, I-6: every surprise attack of the three squadrons spawns synchronously when started in its zone, in a ship.
function TestSurpriseAttackInZoneRegression:test_every_existing_surprise_attack_still_spawns_immediately_in_its_own_zone()
	local names = surpriseAttacks()

	lu.assertEquals(#names, 17, "setup: surprise attack quest tables of CorSec, Havoc and RSF")

	for _, global in ipairs(names) do
		local q, player = started(global, quest(global).questZone)
		local want = totalShips(q)

		lu.assertEquals(q.surpriseAttackShips.zone, q.questZone, global .. ": surpriseAttackShips.zone equals questZone (R-1)")
		lu.assertEquals(#spawnCalls(), want, global .. ": spawnShipAgent calls inside startQuest")

		for i, c in ipairs(spawnCalls()) do
			lu.assertEquals(c[2], q.questZone, global .. ": ship " .. i .. " zone")
		end

		lu.assertEquals(readData(player.objectID .. q.className .. ":Count"), want, global .. ": kill count")
		lu.assertEquals(#H.pendingEvents(), 0, global .. ": no deferred event queued")
	end
end

-- AC-6, SC-1 item 3: the "spawned in this run" marker is shared memory, and every end of the run deletes it.
local ENDS = {
	complete = function(q, player) q:completeQuest(player, "false") end,
	fail = function(q, player) q:failQuest(player, "false") end,
	reset = function(q, player) q:resetQuest(player) end,
}

for _, method in ipairs({ "complete", "fail", "reset" }) do
	TestSurpriseAttackInZoneRegression["test_" .. method .. "Quest_leaves_no_spawned_key"] = function()
		local q, player = started("destroy_surpriseattack_naboo_privateer_tier4_2b", "space_endor")

		lu.assertEquals(#spawnedKeys(player), 1, method .. ": precondition: the spawn left one :spawned key")
		lu.assertEquals(spawnedKeys(player)[1], "|" .. player.objectID .. q.className .. ":spawned", method .. ": the key is <playerID><className>:spawned")

		ENDS[method](q, player)
		H.advance(1000)

		lu.assertEquals(spawnedKeys(player), {}, method .. "Quest: :spawned keys left")
	end
end

-- AC-6, SC-1 item 3: a pending run never wrote the marker, and a restarted run spawns again after a finished one.
function TestSurpriseAttackInZoneRegression:test_a_finished_run_can_be_started_again_and_spawns_again()
	local q, player = started("destroy_surpriseattack_naboo_privateer_tier4_2b", "space_endor")

	q:resetQuest(player)
	H.advance(1000)
	lu.assertEquals(#spawnCalls(), 5, "precondition: first run spawned")

	q:startQuest(player, "")
	lu.assertEquals(#spawnCalls(), 10, "second run: spawnShipAgent calls")
end

---------------------------------------------------------------------------------------------
-- AC-7: the RSF mission 3 ambush at runtime
---------------------------------------------------------------------------------------------

TestRsfMission3Ambush = {}

function TestRsfMission3Ambush:setUp()
	H.reset()
	resetVm()
end

-- A pilot in a ship in Lok whose 3c is active (the journal entry only: the survival run itself is not under test).
local function pilotWith3cActive()
	local player = H.newPlayer({ name = "Ace", zone = "space_lok", ship = true, pilot = "neutral" })

	lu.assertTrue(SpaceHelpers:activateSpaceQuest(player, nil, "survival", "naboo_privateer_tier3_3c", false), "setup: 3c activates")

	return player
end

-- AC-7
function TestRsfMission3Ambush:test_completing_3c_starts_3e_after_5250_ms_and_it_waits_in_lok()
	local player = pilotWith3cActive()
	local c3, e3 = quest(C3), quest(E3)

	c3:completeQuest(player, "true")

	lu.assertTrue(isComplete(player, c3), "3c is complete")
	H.advance(5249)
	lu.assertFalse(isActive(player, e3), "3e is not started 5249 ms after 3c completed")
	H.advance(1)
	lu.assertTrue(isActive(player, e3), "3e is active 5250 ms after 3c completed (5 x 1050 ms)")
	lu.assertEquals(#spawnCalls(), 0, "no ships while the pilot is in Lok")
	H.advance(30000)
	lu.assertEquals(#spawnCalls(), 0, "no ships 30 s later")
	lu.assertTrue(isComplete(player, c3), "3c stays complete")
end

-- AC-7
function TestRsfMission3Ambush:test_in_naboo_five_marauders_attack_and_destroying_them_all_completes_3e()
	local player = pilotWith3cActive()
	local c3, e3 = quest(C3), quest(E3)

	c3:completeQuest(player, "true")
	H.advance(5250)
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)

	local ships = {}

	for i, c in ipairs(spawnCalls()) do
		ships[i] = c[1]
	end

	lu.assertEquals(ships, rep(5, "blacksun_marauder_tier3"), "spawned ships")

	local agents = H.spawnedShips()

	for i = 1, 4 do
		H.destroyShip(agents[i], player.rootParent)
		lu.assertTrue(isActive(player, e3), "3e is active after " .. i .. " kills")
	end

	H.destroyShip(agents[5], player.rootParent)

	lu.assertTrue(isComplete(player, e3), "3e is complete after the fifth kill")
	lu.assertFalse(isActive(player, e3), "3e is no longer active")
	lu.assertTrue(isComplete(player, c3), "3c stays complete")
end

-- AC-7: D-8, a lost 3e does not undo the mission 3 win.
function TestRsfMission3Ambush:test_a_failed_3e_leaves_3c_complete_in_the_journal()
	local player = pilotWith3cActive()
	local c3, e3 = quest(C3), quest(E3)

	c3:completeQuest(player, "true")
	H.advance(5250)
	lu.assertTrue(isActive(player, e3), "precondition: 3e is active")

	e3:failQuest(player, "true")
	H.advance(2000)

	lu.assertFalse(isActive(player, e3), "3e is no longer active")
	lu.assertFalse(isComplete(player, e3), "3e is not complete")
	lu.assertTrue(isComplete(player, c3), "3c is still complete")
	lu.assertFalse(isActive(player, c3), "3c is not re-activated")
end

-- AC-7: failing after the ships spawned leaves 3c complete as well.
function TestRsfMission3Ambush:test_a_3e_that_fails_after_the_ambush_spawned_leaves_3c_complete()
	local player = pilotWith3cActive()
	local c3, e3 = quest(C3), quest(E3)

	c3:completeQuest(player, "true")
	H.advance(5250)
	H.zoneSwitch(player, "space_naboo", { ship = true })
	H.advance(1000)
	e3:failQuest(player, "true")
	H.advance(2000)

	lu.assertFalse(isActive(player, e3), "3e is no longer active")
	lu.assertTrue(isComplete(player, c3), "3c is still complete")
	lu.assertEquals(spawnedKeys(player), {}, "no :spawned key left")
end
