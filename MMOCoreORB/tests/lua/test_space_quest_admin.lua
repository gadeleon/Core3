-- /object spacequest complete <type> <name>: SpaceQuestAdmin completes a space quest through its own screenplay
local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()
H.loadScreenplay("space/space_quest_admin.lua")

local function lastText(player)
	local log = H.messageLog(player)
	local m = log[#log]
	return m and (m.text or m.id) or ""
end

TestSpaceQuestAdmin = {}

function TestSpaceQuestAdmin:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	local global = case.ONE

	TestSpaceQuestAdmin["test_completes_the_master_mission_and_cleans_up_" .. global] = function()
		local q, player = S.started(case, global)
		local list = case.M.shipList(global)

		S.enter(player)
		for i = 1, 3 do S.kill(player, S.cycle(list, i)) end

		SpaceQuestAdmin:complete(player, nil, q.questType, q.questName)

		lu.assertTrue(S.isComplete(player, q), global .. ": complete")
		lu.assertFalse(S.isActive(player, q), global .. ": no longer active")
		lu.assertEquals(S.count(player, global), 0, global .. ": saved count cleared")
		lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global .. ": observers dropped")
		lu.assertStrContains(lastText(player), "Completed space quest")
	end

	TestSpaceQuestAdmin["test_refuses_a_quest_that_is_not_active_" .. global] = function()
		local q = S.quest(case, global)
		H.reset()
		local player = S.pilot(case)

		SpaceQuestAdmin:complete(player, nil, q.questType, q.questName)

		lu.assertFalse(S.isComplete(player, q))
		lu.assertStrContains(lastText(player), "does not have the space quest")
	end
end
