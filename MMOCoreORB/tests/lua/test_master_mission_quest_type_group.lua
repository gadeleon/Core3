-- Persistent master mission quest type: group credit, exactly once per member.
-- Spec: .claude/work/space-master-mission-quest-type/01-spec.md (AC-7; Finding 1; D-4).
--
-- ShipManager::notifyDestruction (ShipManager.cpp:1045-1073) fires DESTROYEDSHIP once on EVERY member of the top-damage group, whatever their zone, so
-- the Lua side never walks a group: every member's own observer decides. groupKill mirrors that dispatch.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local function progress(n, k) return "Kills: " .. n .. " of " .. k end

-- DESTROYEDSHIP once on each member, like ShipManager.cpp:1052-1067
local function groupKill(agent, members)
	for _, member in ipairs(members) do
		H.fireObservers(DESTROYEDSHIP, member, agent)
	end

	S.pump(300, "group kill")
end

-- A pilot of `case` with `global` running and standing in `zone` (default Kessel)
local function member(case, global, zone)
	local q = S.quest(case, global)
	local player = S.pilot(case, { zone = S.GROUND, paid = global == case.TWO and { 1 } or nil })

	q:startQuest(player, "")
	H.advance(0)
	S.enter(player)

	if zone ~= nil and zone ~= S.ZONE then
		S.goTo(player, zone)
	end

	return player, q
end

TestMasterMissionGroup = {}

function TestMasterMissionGroup:setUp() H.reset() end

-- AC-7
function TestMasterMissionGroup:test_every_grouped_pilot_in_kessel_with_the_mission_gets_one_kill_and_one_update()
	for _, case in ipairs(S.CASES) do
		H.reset()

		local a, b, c = member(case, case.ONE), member(case, case.ONE), member(case, case.ONE)
		local ship = case.M.shipList(case.ONE)[1]
		local marks = { S.messageMark(a), S.messageMark(b), S.messageMark(c) }

		groupKill(S.agent(ship), { a, b, c })

		for i, p in ipairs({ a, b, c }) do
			local label = case.faction .. " member " .. i

			lu.assertEquals(S.count(p, case.ONE), 1, label .. ": saved count")
			lu.assertEquals(S.updates(p, marks[i]), { progress(1, 30) }, label .. ": updates")
		end
	end
end

-- AC-7
function TestMasterMissionGroup:test_a_member_in_another_zone_a_member_without_the_mission_and_a_member_with_another_list_get_nothing()
	for _, case in ipairs(S.CASES) do
		H.reset()

		local ship = case.M.shipList(case.ONE)[1]
		local inKessel = member(case, case.ONE)
		local elsewhere = member(case, case.ONE, "space_heavy1")
		local onGround = member(case, case.ONE, S.GROUND)
		local corvetteHolder = member(case, case.TWO)
		local noMission = S.pilot(case, { zone = S.ZONE })
		local others = { elsewhere, onGround, corvetteHolder, noMission }
		local marks = {}

		for i, p in ipairs(others) do marks[i] = S.messageMark(p) end

		local mark = S.messageMark(inKessel)

		groupKill(S.agent(ship), { inKessel, elsewhere, onGround, corvetteHolder, noMission })

		lu.assertEquals(S.updates(inKessel, mark), { progress(1, 30) }, case.faction .. ": the member in Kessel")

		for i, name in ipairs({ "in space_heavy1", "on the ground", "with the corvette mission (the ship is not on its list)", "with no mission" }) do
			lu.assertEquals(S.updates(others[i], marks[i]), {}, case.faction .. ": member " .. name .. ": updates")
		end

		lu.assertEquals(S.count(elsewhere, case.ONE), 0, case.faction .. ": member in space_heavy1: count")
		lu.assertEquals(S.count(onGround, case.ONE), 0, case.faction .. ": member on the ground: count")
		lu.assertEquals(readScreenPlayData(corvetteHolder, case.TWO, "killCount"), "", case.faction .. ": the corvette holder's count")
		lu.assertTrue(S.isActive(corvetteHolder, S.quest(case, case.TWO)), case.faction .. ": the corvette holder's mission stays active")
		lu.assertEquals(S.count(inKessel, case.ONE), 1, case.faction .. ": member in Kessel: count")
	end
end

-- AC-7: a member whose mission was completed or aborted earlier (the observers are gone, or stale and removing themselves) gets nothing
function TestMasterMissionGroup:test_a_member_whose_mission_is_over_gets_nothing()
	local case = S.CASES[1]
	local ship = case.M.shipList(case.ONE)[1]
	local live, stale = member(case, case.ONE), member(case, case.ONE)

	stale.ghost.journalActive[H.questCrc("destroy", case.names[1])] = nil

	local mark = S.messageMark(stale)

	groupKill(S.agent(ship), { live, stale })
	lu.assertEquals(S.count(live, case.ONE), 1, "the live member")
	lu.assertEquals(readScreenPlayData(stale, case.ONE, "killCount"), "", "the member whose entry was cleared")
	lu.assertEquals(S.updates(stale, mark), {}, "no update for it")
end

-- AC-7: the same ship delivered twice to the same member counts once, two different ships count twice
function TestMasterMissionGroup:test_the_same_ship_delivered_twice_counts_once_and_two_ships_count_twice()
	for _, case in ipairs(S.CASES) do
		H.reset()

		local a, b = member(case, case.ONE), member(case, case.ONE)
		local list = case.M.shipList(case.ONE)
		local one = S.agent(list[1])

		groupKill(one, { a, b })
		groupKill(one, { a, b })
		lu.assertEquals({ S.count(a, case.ONE), S.count(b, case.ONE) }, { 1, 1 }, case.faction .. ": the same agent twice")

		groupKill(S.agent(list[1]), { a, b })
		lu.assertEquals({ S.count(a, case.ONE), S.count(b, case.ONE) }, { 2, 2 }, case.faction .. ": a second agent of the same type")

		groupKill(S.agent(list[2]), { a })
		lu.assertEquals({ S.count(a, case.ONE), S.count(b, case.ONE) }, { 3, 2 }, case.faction .. ": a third agent, only member a notified")
	end
end

-- AC-7: three notifications of one ship in a row count once (SWG killTrack)
function TestMasterMissionGroup:test_three_notifications_of_one_ship_in_a_row_count_once()
	local case = S.CASES[1]
	local a = member(case, case.ONE)
	local list = case.M.shipList(case.ONE)
	local first = S.agent(list[1])

	S.fire(a, nil, first)
	S.fire(a, nil, first)
	S.fire(a, nil, first)
	S.pump(300, "kills")
	lu.assertEquals(S.count(a, case.ONE), 1, "three notifications of one ship in a row")
end

-- AC-7: the corvette, for the group: each eligible member's mission 2 completes
function TestMasterMissionGroup:test_the_corvette_completes_mission_2_for_every_eligible_grouped_pilot()
	for _, case in ipairs(S.CASES) do
		H.reset()

		local completions = S.countCompletions()
		local a, b = member(case, case.TWO), member(case, case.TWO)
		local away = member(case, case.TWO, "space_heavy1")
		local q = S.quest(case, case.TWO)

		groupKill(S.agent(case.M.shipList(case.TWO)[1]), { a, b, away })

		lu.assertTrue(S.isComplete(a, q), case.faction .. ": member a completed")
		lu.assertTrue(S.isComplete(b, q), case.faction .. ": member b completed")
		lu.assertTrue(S.isActive(away, q), case.faction .. ": the member in space_heavy1 is still on the mission")
		lu.assertEquals(#completions, 2, case.faction .. ": two completions")
		S.unwrap()
	end
end

-- AC-7: an Imperial and a Rebel master in one group: each is credited for the ships of his own list only
function TestMasterMissionGroup:test_a_mixed_group_credits_each_pilot_for_his_own_list_only()
	local imp, reb = S.CASES[1], S.CASES[2]
	local a, b = member(imp, imp.ONE), member(reb, reb.ONE)

	groupKill(S.agent(imp.M.shipList(imp.ONE)[1]), { a, b })
	lu.assertEquals({ S.count(a, imp.ONE), S.count(b, reb.ONE) }, { 1, 0 }, "after a Rebel ship")

	groupKill(S.agent(reb.M.shipList(reb.ONE)[1]), { a, b })
	lu.assertEquals({ S.count(a, imp.ONE), S.count(b, reb.ONE) }, { 1, 1 }, "after an Imperial ship")
end
