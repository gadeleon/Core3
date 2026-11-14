-- H.playerShipDestroyed (space-quest-player-ship-destroyed, C8): the fake of DestroyShipTask case 0. It only dispatches
-- <questType>_<questName>:playerShipDestroyed(player) to every space mission on the datapad; these tests use throwaway quest tables.

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.boot()

TestPlayerShipDestroyedFake = {}

local created = {}

function TestPlayerShipDestroyedFake:setUp() H.reset() end

function TestPlayerShipDestroyedFake:tearDown()
	for _, name in ipairs(created) do _G[name] = nil end

	created = {}
end

local function mission(player, questType, questName)
	local m = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	if questType then m:setQuestType(questType) end
	if questName then m:setQuestName(questName) end

	return m
end

local function fakeQuest(questType, questName, onCall)
	local q = { calls = {} }

	function q:playerShipDestroyed(pPlayer)
		self.calls[#self.calls + 1] = pPlayer

		if onCall then onCall(self, pPlayer) end
	end

	_G[questType .. "_" .. questName] = q
	created[#created + 1] = questType .. "_" .. questName

	return q
end

function TestPlayerShipDestroyedFake:test_it_calls_each_space_mission_once_in_datapad_order_and_returns_the_names()
	local player = H.newPlayer({})
	local a = fakeQuest("patrol", "psd_a")
	local b = fakeQuest("destroy", "psd_b")

	mission(player, "patrol", "psd_a")
	mission(player, "destroy", "psd_b")

	lu.assertEquals(H.playerShipDestroyed(player), { "patrol_psd_a", "destroy_psd_b" }, "names called, in order")
	lu.assertEquals(a.calls, { player }, "patrol_psd_a got the player once")
	lu.assertEquals(b.calls, { player }, "destroy_psd_b got the player once")
end

function TestPlayerShipDestroyedFake:test_it_skips_datapad_objects_that_are_not_space_missions()
	local player = H.newPlayer({})
	local q = fakeQuest("patrol", "psd_c")

	mission(player) -- a mission without a quest type (a bounty mission)
	mission(player, "patrol", "psd_c")
	Fakes.giveItem(player.datapad, "object/intangible/pet/pet_control.iff", -1)

	lu.assertEquals(H.playerShipDestroyed(player), { "patrol_psd_c" }, "only the space mission")
	lu.assertEquals(#q.calls, 1, "called once")
end

function TestPlayerShipDestroyedFake:test_a_handler_that_removes_its_own_mission_does_not_skip_the_next_one()
	local player = H.newPlayer({})
	local second = fakeQuest("destroy", "psd_e")

	fakeQuest("patrol", "psd_d", function(_, p)
		table.remove(p.datapad.items, 1)
	end)

	mission(player, "patrol", "psd_d")
	mission(player, "destroy", "psd_e")

	lu.assertEquals(H.playerShipDestroyed(player), { "patrol_psd_d", "destroy_psd_e" }, "the datapad is snapshotted first")
	lu.assertEquals(#second.calls, 1, "the second quest was told")
end

function TestPlayerShipDestroyedFake:test_a_missing_quest_global_or_handler_fails_with_a_message_that_names_it()
	local player = H.newPlayer({})

	mission(player, "patrol", "psd_missing")
	lu.assertErrorMsgContains("patrol_psd_missing", H.playerShipDestroyed, player)

	H.reset()
	player = H.newPlayer({})
	_G["patrol_psd_nohandler"] = {}
	created[#created + 1] = "patrol_psd_nohandler"
	mission(player, "patrol", "psd_nohandler")
	lu.assertErrorMsgContains("playerShipDestroyed to be a function", H.playerShipDestroyed, player)
end

function TestPlayerShipDestroyedFake:test_an_empty_datapad_calls_nobody()
	lu.assertEquals(H.playerShipDestroyed(H.newPlayer({})), {}, "names called")
end
