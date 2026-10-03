-- RSF tier 3 renames (F2): the mission 3 and mission 4 chains at runtime.
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-4, SC-1 intact).
--
-- Mission 4: 4b (space battle) -> 4c (3 marauders) -> 4d (4 vehements) -> 4e (1 gunship) -> 4f (assassinate).
-- Mission 3: 3a (inspect) -> 3b (delivery_no_pickup) -> 3c (survival).
-- A split fires its alert at sideQuestDelay s and starts the next quest at sideQuestDelay * 1.05 s
-- (SpaceQuestLogic:triggerCompletionSplitQuest, the space battle's completeQuest): delay 5 is 5250 ms, 3a's 10 is 10500 ms.
--
-- The surprise attacks run for real; every other quest's startQuest and failQuest is spied (inspect_scenario's I.isolate).
-- Ship counts and names are the SWG spawn loop replay of the fixtures (surprise_replay.lua).

local lu = require("luaunit")
local H = require("harness")
local I = require("inspect_scenario")
local R = require("surprise_replay")

H.loadSquadron("CorsecSquadronScreenplay")
H.loadSquadron("HavocSquadronScreenplay")
H.loadSquadron("RsfSquadronScreenplay")

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local B4, SA4C, SA4D, SA4E, A4F = g("space_battle", "4b"), g("destroy_surpriseattack", "4c"), g("destroy_surpriseattack", "4d"), g("destroy_surpriseattack", "4e"), g("assassinate", "4f")
local SPLIT_MS = 5250

local function quest(global) return H.expectGlobal(global, "RSF tier 3 quest table") end

local function isActive(player, global) local q = quest(global); return SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName) and true or false end
local function isComplete(player, global) local q = quest(global); return SpaceHelpers:isSpaceQuestComplete(player, q.questType, q.questName) and true or false end

local function spawnCalls() return H.Engine.callsTo("spawnShipAgent") end

-- Names of the ships spawned after the first `from` calls
local function spawnedSince(from)
	local out = {}

	for i = from + 1, #spawnCalls() do
		out[#out + 1] = spawnCalls()[i][1]
	end

	return out
end

local function repeated(n, name)
	local out = {}

	for i = 1, n do
		out[i] = name
	end

	return out
end

-- A pilot in a ship in Lok with `global`'s journal entry active (the run itself is not under test).
local function pilotInLokWith(global, opts)
	local player = H.newPlayer(opts or { name = "Ace", zone = "space_lok", ship = true, pilot = "neutral" })
	local q = quest(global)

	lu.assertTrue(SpaceHelpers:activateSpaceQuest(player, nil, q.questType, q.questName, false), "setup: " .. global .. " activates")
	return player
end

local function killAll(player, from)
	local agents = H.spawnedShips()

	for i = from + 1, #agents do
		H.destroyShip(agents[i], player.rootParent)
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: mission 4
---------------------------------------------------------------------------------------------

TestRsfRenamesMission4Chain = {}

function TestRsfRenamesMission4Chain:setUp() H.reset() end

-- AC-4
function TestRsfRenamesMission4Chain:test_completing_4b_starts_4c_after_5250_ms_and_it_spawns_3_marauders_in_lok_at_once()
	local player = pilotInLokWith(B4)
	local spies = I.isolate({ SA4C, SA4D, SA4E })

	quest(B4):completeQuest(player, "false")
	lu.assertTrue(isComplete(player, B4), "4b is complete")

	H.advance(SPLIT_MS - 1)
	lu.assertFalse(isActive(player, SA4C), "4c is not active at 5249 ms")
	lu.assertEquals(#spawnCalls(), 0, "no ship at 5249 ms")

	H.advance(1)
	lu.assertTrue(isActive(player, SA4C), "4c is active at 5250 ms")
	lu.assertEquals(spawnedSince(0), repeated(3, "blacksun_marauder_tier3"), "ships spawned synchronously by 4c's startQuest")

	for i, c in ipairs(spawnCalls()) do
		lu.assertEquals(c[2], "space_lok", "ship " .. i .. ": zone")
	end

	local started = {}

	for name, calls in pairs(spies.start) do
		if #calls > 0 then
			started[#started + 1] = name
		end
	end

	lu.assertEquals(started, {}, "no other quest started")
end

-- AC-4
function TestRsfRenamesMission4Chain:test_destroying_the_3_marauders_completes_4c_and_starts_4d_5250_ms_later_with_4_vehements()
	local player = pilotInLokWith(B4)

	I.isolate({ SA4C, SA4D, SA4E })
	quest(B4):completeQuest(player, "false")
	H.advance(SPLIT_MS)

	local agents = H.spawnedShips()

	lu.assertEquals(#agents, 3, "setup: three marauders")
	H.destroyShip(agents[1], player.rootParent)
	H.destroyShip(agents[2], player.rootParent)
	lu.assertTrue(isActive(player, SA4C), "4c is still active after two kills")

	H.destroyShip(agents[3], player.rootParent)
	lu.assertTrue(isComplete(player, SA4C), "4c is complete after the third kill")
	lu.assertFalse(isActive(player, SA4C), "4c is no longer active")

	H.advance(SPLIT_MS - 1)
	lu.assertFalse(isActive(player, SA4D), "4d is not active 5249 ms after 4c completed")

	H.advance(1)
	lu.assertTrue(isActive(player, SA4D), "4d is active 5250 ms after 4c completed")
	lu.assertEquals(spawnedSince(3), repeated(4, "blacksun_vehement_tier3"), "ships spawned by 4d")
end

-- AC-4
function TestRsfRenamesMission4Chain:test_destroying_the_4_vehements_completes_4d_and_starts_4e_with_a_gunship_which_then_starts_4f_5250_ms_later()
	local player = pilotInLokWith(B4)
	local spies = I.isolate({ SA4C, SA4D, SA4E })

	quest(B4):completeQuest(player, "false")
	H.advance(SPLIT_MS)
	killAll(player, 0)
	H.advance(SPLIT_MS)
	lu.assertTrue(isActive(player, SA4D), "setup: 4d running")

	killAll(player, 3)
	lu.assertTrue(isComplete(player, SA4D), "4d is complete after the fourth kill")

	H.advance(SPLIT_MS - 1)
	lu.assertFalse(isActive(player, SA4E), "4e is not active 5249 ms after 4d completed")

	H.advance(1)
	lu.assertTrue(isActive(player, SA4E), "4e is active 5250 ms after 4d completed")
	lu.assertEquals(spawnedSince(7), { "blacksun_gunship_tier2" }, "ships spawned by 4e")

	lu.assertEquals(#spies.start[A4F], 0, "4f has not started while 4e runs")
	killAll(player, 7)
	lu.assertTrue(isComplete(player, SA4E), "4e is complete after the gunship is destroyed")

	H.advance(SPLIT_MS - 1)
	lu.assertEquals(#spies.start[A4F], 0, "4f has not started 5249 ms after 4e completed")

	H.advance(1)
	lu.assertEquals(#spies.start[A4F], 1, "assassinate 4f:startQuest calls 5250 ms after 4e completed")
	lu.assertIs(spies.start[A4F][1].args[1], player, "4f is started for the pilot")
end

-- AC-4: the fixture replay agrees with what ran
function TestRsfRenamesMission4Chain:test_the_ships_that_spawn_are_the_swg_spawn_loop_replay_of_the_fixtures()
	local player = pilotInLokWith(B4)

	I.isolate({ SA4C, SA4D, SA4E })
	quest(B4):completeQuest(player, "false")
	H.advance(SPLIT_MS)
	killAll(player, 0)
	H.advance(SPLIT_MS)
	killAll(player, 3)
	H.advance(SPLIT_MS)

	local want = {}

	for _, name in ipairs({ "4c", "4d", "4e" }) do
		for _, ship in ipairs(R.replay("naboo_privateer_tier3_" .. name)) do
			want[#want + 1] = ship
		end
	end

	lu.assertEquals(spawnedSince(0), want, "every ship spawned by 4c, 4d, 4e, in order")
end

-- AC-4: SC-1 is intact for the new quests
function TestRsfRenamesMission4Chain:test_4c_started_on_the_ground_stays_pending_until_a_zone_switch_into_lok_in_a_ship()
	local player = H.newPlayer({ name = "Ace", zone = "space_naboo", parent = "starport", pilot = "neutral" })

	I.isolate({ SA4C, SA4D, SA4E })
	quest(SA4C):startQuest(player, "")

	lu.assertTrue(isActive(player, SA4C), "4c is active")
	lu.assertEquals(#spawnCalls(), 0, "no ship while the pilot is on the ground")

	H.advance(30000)
	lu.assertEquals(#spawnCalls(), 0, "no ship 30 s later")

	H.zoneSwitch(player, "space_lok", { ship = true })
	lu.assertEquals(#spawnCalls(), 0, "no ship at the switch itself")

	H.advance(999)
	lu.assertEquals(#spawnCalls(), 0, "no ship 999 ms after the switch")

	H.advance(1)
	lu.assertEquals(spawnedSince(0), repeated(3, "blacksun_marauder_tier3"), "ships 1000 ms after the switch")
end

---------------------------------------------------------------------------------------------
-- AC-4: mission 3
---------------------------------------------------------------------------------------------

TestRsfRenamesMission3Chain = {}

function TestRsfRenamesMission3Chain:setUp() H.reset() end

local DNP3B, I3A, S3C = g("delivery_no_pickup", "3b"), g("inspect", "3a"), g("survival", "3c")

-- AC-4
function TestRsfRenamesMission3Chain:test_completing_3a_starts_delivery_no_pickup_3b_after_10_times_1050_ms()
	quest(DNP3B)

	local player = pilotInLokWith(I3A)
	local spies = I.isolate({})

	quest(I3A):completeQuest(player, "false")
	lu.assertTrue(isComplete(player, I3A), "3a is complete")

	H.advance(10499)
	lu.assertEquals(#spies.start[DNP3B], 0, "delivery_no_pickup 3b:startQuest calls at 10499 ms")

	H.advance(1)
	lu.assertEquals(#spies.start[DNP3B], 1, "delivery_no_pickup 3b:startQuest calls at 10500 ms")
	lu.assertIs(spies.start[DNP3B][1].args[1], player, "3b is started for the pilot")
	lu.assertNil(spies.start[g("delivery", "3b")], "the deleted delivery 3b has no table to start")
end

-- AC-4
function TestRsfRenamesMission3Chain:test_completing_3b_starts_survival_3c_after_5_times_1050_ms()
	local player = pilotInLokWith(DNP3B)
	local spies = I.isolate({})

	quest(DNP3B):completeQuest(player, "false")
	lu.assertTrue(isComplete(player, DNP3B), "3b is complete")

	H.advance(5249)
	lu.assertEquals(#spies.start[S3C], 0, "survival 3c:startQuest calls at 5249 ms")

	H.advance(1)
	lu.assertEquals(#spies.start[S3C], 1, "survival 3c:startQuest calls at 5250 ms")
	lu.assertIs(spies.start[S3C][1].args[1], player, "3c is started for the pilot")
end
