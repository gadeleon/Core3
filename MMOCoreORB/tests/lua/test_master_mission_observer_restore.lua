-- Master missions: a journal entry that outlived its persistent observers (lost from the observers database, for example by a
-- Berkeley DB recovery) gets them back on the next login. PlayerTriggers:playerLoggedIn runs before the LOGGEDIN observers fire
-- (PlayerObjectImplementation::notifyOnline), so the restored onLoggedIn observer shows the saved count in Kessel.

local lu = require("luaunit")
local H = require("harness")
local S = require("master_mission_scenario")

S.load()

local function progress(n, k) return "Kills: " .. n .. " of " .. k end

-- Every observer of the quest gone, the journal entry and the saved count kept
local function loseObservers(player, global)
	for _, o in ipairs(S.observers()) do
		dropObserver(o[1], global, o[2], player)
	end
end

-- The login order of PlayerObjectImplementation::notifyOnline: the Lua trigger, then the LOGGEDIN observers
local function login(player)
	SpaceMasterDestroyScreenplay.restoreObservers(player)
	H.fireObservers(LOGGEDIN, player)
end

TestMasterMissionObserverRestore = {}

function TestMasterMissionObserverRestore:setUp() H.reset() end

for _, case in ipairs(S.CASES) do
	for _, global in ipairs({ case.ONE, case.TWO }) do
		TestMasterMissionObserverRestore["test_login_restores_lost_observers_of_" .. global] = function()
			local q, player = S.started(case, global)

			loseObservers(player, global)
			lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, "precondition")

			login(player)

			lu.assertEquals(S.observerProblems(player, global), {}, global .. ": observers after the login")
			lu.assertTrue(S.isActive(player, q), global .. ": still active")
		end
	end

	local global = case.ONE

	TestMasterMissionObserverRestore["test_after_the_restore_kessel_shows_the_count_and_kills_count_" .. global] = function()
		local _, player = S.started(case, global)
		local list = case.M.shipList(global)

		S.enter(player)
		for i = 1, 4 do S.kill(player, S.cycle(list, i)) end

		loseObservers(player, global)

		-- lost: a kill does not count
		S.kill(player, S.cycle(list, 5))
		lu.assertEquals(S.count(player, global), 4, "precondition: no observer, no count")

		local mark = S.messageMark(player)

		login(player) -- logged in while in Kessel
		S.pump(6000, "reminder")

		lu.assertEquals(S.updates(player, mark), { progress(4, 30) }, global .. ": the saved count once, after the login")

		S.kill(player, S.cycle(list, 6))
		lu.assertEquals(S.count(player, global), 5, global .. ": kills count again")
	end

	TestMasterMissionObserverRestore["test_login_with_observers_in_place_adds_none_" .. global] = function()
		local _, player = S.started(case, global)

		login(player)
		login(player)

		lu.assertEquals(S.observerProblems(player, global), {}, global .. ": still exactly one each")
	end

	TestMasterMissionObserverRestore["test_login_without_the_mission_adds_none_" .. global] = function()
		H.reset()
		local player = S.pilot(case)

		login(player)

		lu.assertEquals(S.observerCounts(player, global), { enteredZone = 0, onLoggedIn = 0, notifyDestroyedShip = 0 }, global)
	end
end

function TestMasterMissionObserverRestore:test_player_triggers_call_the_restore()
	local f = assert(io.open((os.getenv("MMOCORE_ROOT") or ".") .. "/bin/scripts/screenplays/playerTriggers.lua"))
	local src = f:read("a")
	f:close()

	lu.assertStrContains(src, "SpaceMasterDestroyScreenplay.restoreObservers(pPlayer)")
end
