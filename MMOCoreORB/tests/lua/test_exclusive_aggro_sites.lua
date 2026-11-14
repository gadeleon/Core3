-- Exclusive aggro at the Lua spawn sites of hostile quest ships (space-quest-exclusive-aggro).
-- Spec: .claude/work/space-quest-exclusive-aggro/01-spec.md (AC-6, AC-7, AC-8, AC-9; invariants I-1, I-2, I-5).
--
-- Every row drives the real screenplay through the harness fakes (exclusive_aggro_scenario.lua) and checks the agents' ordered
-- aggroLog: one addExclusiveAggro with the mission owner pointer after that agent's setMissionOwner (I-1). Friendly ships get none (I-2).

local lu = require("luaunit")
local H = require("harness")
local E = require("exclusive_aggro_scenario")

E.load()

TestExclusiveAggroHostileSites = {}

function TestExclusiveAggroHostileSites:setUp() H.reset() end

-- AC-6
for _, row in ipairs(E.hostileRows()) do
	TestExclusiveAggroHostileSites["test_row_" .. tostring(row.id) .. "_" .. row.site:gsub("[^%w]+", "_") .. "_agents_get_exclusive_aggro_for_the_owner"] = function()
		local r = row.build()

		lu.assertEquals(E.problems(r.agents, r.owner), {}, "row " .. tostring(row.id) .. " (" .. row.site .. ")")
	end
end

TestExclusiveAggroFriendlySites = {}

function TestExclusiveAggroFriendlySites:setUp() H.reset() end

-- AC-7
for _, row in ipairs(E.friendlyRows()) do
	TestExclusiveAggroFriendlySites["test_" .. tostring(row.id) .. "_" .. row.site:gsub("[^%w]+", "_") .. "_agents_get_no_exclusive_aggro"] = function()
		local r = row.build()

		for i, agent in ipairs(r.agents) do
			lu.assertEquals(#E.exclusiveCalls(agent), 0, row.site .. ": agent #" .. i .. " " .. tostring(agent.shipName) .. " addExclusiveAggro calls")
			lu.assertFalse(ShipAiAgent(agent):hasExclusiveAggro(r.owner), row.site .. ": agent #" .. i .. " hasExclusiveAggro(owner)")
		end
	end
end

-- AC-7 (R-6): the same battle, both sides: only the enemy side is flagged
function TestExclusiveAggroFriendlySites:test_battle_flags_the_enemy_side_and_not_the_ally_side_of_the_same_battle()
	local B = require("battle_scenario")

	H.reset()

	local sc = B.fresh(B.LOSE)

	sc:setup()

	local allies, enemies = sc:allies(), sc:enemies()

	lu.assertEquals(E.problems(enemies, sc.player), {}, "enemy side")

	for i, agent in ipairs(allies) do
		lu.assertEquals(#E.exclusiveCalls(agent), 0, "ally " .. i .. " addExclusiveAggro calls")
	end
end

TestExclusiveAggroRecoveryFriendly = {}

function TestExclusiveAggroRecoveryFriendly:setUp() H.reset() end

-- AC-8: the ship turns friendly when it is captured; its exclusive aggro goes, the escorts keep theirs
function TestExclusiveAggroRecoveryFriendly:test_continue_recovery_removes_the_exclusive_aggro_of_the_recovery_ship_only()
	local r = E.recovery()

	-- independent of the spawn site: give the ship and the escorts the flag the spec says they carry before the capture
	ShipAiAgent(r.ship):addExclusiveAggro(r.owner)

	for _, escort in ipairs(r.escorts) do
		ShipAiAgent(escort):addExclusiveAggro(r.owner)
	end

	require("recovery_fixes_scenario").capture(r.run)

	lu.assertFalse(ShipAiAgent(r.ship):hasExclusiveAggro(r.owner), "the recovered ship still has exclusive aggro for the owner")

	local removes = 0

	for _, e in ipairs(r.ship.aggroLog) do
		if e.name == "removeExclusiveAggro" then
			removes = removes + 1
			lu.assertEquals(e.args[1], r.owner, "removeExclusiveAggro got the owner")
		end
	end

	lu.assertEquals(removes, 1, "removeExclusiveAggro calls on the recovery ship")

	for i, escort in ipairs(r.escorts) do
		lu.assertTrue(ShipAiAgent(escort):hasExclusiveAggro(r.owner), "escort " .. i .. " keeps its exclusive aggro")

		for _, e in ipairs(escort.aggroLog) do
			lu.assertNotEquals(e.name, "removeExclusiveAggro", "escort " .. i .. ": no removeExclusiveAggro")
		end
	end
end

-- AC-8 (I-2): nothing hands the flag back to the captured ship afterwards
function TestExclusiveAggroRecoveryFriendly:test_the_captured_recovery_ship_is_never_given_exclusive_aggro_again()
	local r = E.recovery()
	local RF = require("recovery_fixes_scenario")

	RF.capture(r.run)
	RF.wave(r.run)

	local last

	for _, e in ipairs(r.ship.aggroLog) do
		if e.name == "addExclusiveAggro" or e.name == "removeExclusiveAggro" then
			last = e.name
		end
	end

	lu.assertEquals(last, "removeExclusiveAggro", "the last exclusive aggro call on the captured ship (add at spawn, then remove)")
	lu.assertFalse(ShipAiAgent(r.ship):hasExclusiveAggro(r.owner), "the captured ship's flag after the next wave")
end

TestExclusiveAggroPalaceQuest4 = {}

function TestExclusiveAggroPalaceQuest4:setUp() H.reset() end

-- AC-9
function TestExclusiveAggroPalaceQuest4:test_hortrix_and_both_escorts_have_exclusive_aggro_for_a_hutt_pilot()
	local want = E.palaceExpected()

	lu.assertEquals(want.target, "hutt_quest_hortrix_steelarm_tier3", "fixture targetShipType")
	lu.assertEquals(want.escorts, { "hutt_pirate_s02_tier2", "hutt_pirate_s02_tier2" }, "fixture targetEscort")

	local run = E.palaceDeployed()
	local names = {}

	for i, ship in ipairs(run.ships) do
		names[i] = ship.shipName
	end

	lu.assertEquals(names, { want.target, want.escorts[1], want.escorts[2] }, "ships spawned by " .. E.PALACE_GLOBAL)
	lu.assertEquals(E.problems(run.ships, run.player), {}, E.PALACE_GLOBAL)
end

-- AC-9: the pilot's ship faction is the case the bug is about
function TestExclusiveAggroPalaceQuest4:test_the_pilot_ship_has_faction_hutt_in_the_scenario()
	local run = E.palaceDeployed()

	lu.assertEquals(SpaceHelpers:getPlayerShipFactionHash(run.player), getHashCode("hutt"), "player ship faction hash")
end
