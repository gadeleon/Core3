-- Harness changes for space-quest-abort-cleanup: FakeMission:abort()/isAborted(), failQuestMission that skips
-- aborted missions (LuaCreatureObject.cpp:1514) and H.abortMission, which models the new order of
-- MissionManagerImplementation::handleMissionAbort. These tests exercise the fakes only; the part that
-- needs a production hook defines a throwaway quest table in the test.

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")

H.boot()

TestAbortFakes = {}

function TestAbortFakes:setUp() H.reset() end

local function mission(player, questType, questName)
	local m = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	m:setQuestType(questType)
	m:setQuestName(questName)

	return m
end

-- Fake quest global with a recording abortQuest, like a screenplay table: _G["<type>_<name>"]
local function fakeQuest(questType, questName, onAbort)
	local q = { questType = questType, questName = questName, calls = {} }

	function q:abortQuest(pPlayer)
		self.calls[#self.calls + 1] = { pPlayer = pPlayer, aborted = pPlayer.datapad.items[1] and pPlayer.datapad.items[1]:isAborted(),
			active = pPlayer.ghost:isJournalQuestActive(H.questCrc(questType, questName)) }

		if onAbort then
			onAbort(self, pPlayer)
		end
	end

	_G[questType .. "_" .. questName] = q

	return q
end

function TestAbortFakes:tearDown()
	_G.patrol_harness_abort = nil
	_G.survival_harness_abort = nil
end

-- AC-8 (harness)
function TestAbortFakes:test_a_new_mission_is_not_aborted_and_abort_marks_it()
	local p = H.newPlayer({})
	local m = mission(p, "patrol", "corellia_privateer_1")

	lu.assertFalse(m:isAborted(), "fresh mission")
	m:abort()
	lu.assertTrue(m:isAborted(), "after abort()")
end

-- AC-8 (harness)
function TestAbortFakes:test_the_lua_mission_wrapper_forwards_abort_and_is_aborted()
	local p = H.newPlayer({})
	local m = mission(p, "patrol", "corellia_privateer_1")

	LuaMissionObject(m):abort()

	lu.assertTrue(LuaMissionObject(m):isAborted(), "isAborted through LuaMissionObject")
end

-- AC-8 (harness)
function TestAbortFakes:test_an_aborted_mission_survives_fail_quest_mission_but_the_crc_is_recorded()
	local p = H.newPlayer({})
	local m = mission(p, "patrol", "corellia_privateer_1")
	local crc = H.questCrc("patrol", "corellia_privateer_1")

	m:abort()
	CreatureObject(p):failQuestMission(crc)

	lu.assertEquals(#p.datapad.items, 1, "the aborted mission stays on the datapad")
	lu.assertIs(p.datapad.items[1], m, "same mission")
	lu.assertEquals(p.failedMissions, { crc }, "failedMissions")
end

-- AC-8 (harness)
function TestAbortFakes:test_fail_quest_mission_skips_the_aborted_mission_and_removes_the_next_one_with_the_same_crc()
	local p = H.newPlayer({})
	local first = mission(p, "patrol", "corellia_privateer_1")
	local second = mission(p, "patrol", "corellia_privateer_1")

	first:abort()
	CreatureObject(p):failQuestMission(H.questCrc("patrol", "corellia_privateer_1"))

	lu.assertEquals(#p.datapad.items, 1, "one mission left")
	lu.assertIs(p.datapad.items[1], first, "the aborted one stays")
	lu.assertNotIs(p.datapad.items[1], second, "the live one is gone")
end

-- AC-8 (harness): the C++ removeQuestMission does not look at isAborted
function TestAbortFakes:test_remove_quest_mission_removes_an_aborted_mission()
	local p = H.newPlayer({})
	local m = mission(p, "patrol", "corellia_privateer_1")

	m:abort()
	CreatureObject(p):removeQuestMission(H.questCrc("patrol", "corellia_privateer_1"))

	lu.assertEquals(#p.datapad.items, 0, "datapad")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_calls_the_hook_with_the_mission_aborted_and_the_entry_still_active()
	local p = H.newPlayer({ activeQuests = { H.questCrc("patrol", "harness_abort") } })
	local q = fakeQuest("patrol", "harness_abort")

	mission(p, "patrol", "harness_abort")
	H.abortMission(p, "patrol", "harness_abort")

	lu.assertEquals(#q.calls, 1, "abortQuest calls")
	lu.assertIs(q.calls[1].pPlayer, p, "abortQuest(player)")
	lu.assertTrue(q.calls[1].aborted, "the mission was aborted before the hook ran")
	lu.assertTrue(q.calls[1].active, "the journal entry was still active when the hook ran")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_removes_the_mission_exactly_once_and_clears_an_entry_the_hook_left_active()
	local crc = H.questCrc("patrol", "harness_abort")
	local p = H.newPlayer({ activeQuests = { crc } })

	fakeQuest("patrol", "harness_abort") -- a hook that does nothing
	mission(p, "patrol", "harness_abort")
	mission(p, "patrol", "harness_abort")
	H.abortMission(p, "patrol", "harness_abort")

	lu.assertEquals(#p.datapad.items, 1, "exactly one of the two missions was removed")
	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "the safety net cleared the active entry")
	lu.assertFalse(p.ghost:isJournalQuestComplete(crc), "not complete either")
end

-- AC-8 (harness): the hook's own failQuestMission cannot remove the aborted mission, so the removal is the last step
function TestAbortFakes:test_abort_mission_removes_the_mission_even_when_the_hook_calls_fail_quest_mission()
	local crc = H.questCrc("patrol", "harness_abort")
	local p = H.newPlayer({ activeQuests = { crc } })

	fakeQuest("patrol", "harness_abort", function(_, pPlayer) CreatureObject(pPlayer):failQuestMission(crc) end)
	mission(p, "patrol", "harness_abort")
	H.abortMission(p, "patrol", "harness_abort")

	lu.assertEquals(#p.datapad.items, 0, "datapad")
	lu.assertEquals(p.failedMissions, { crc }, "the hook's failQuestMission is still recorded")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_leaves_a_completed_entry_complete()
	local crc = H.questCrc("patrol", "harness_abort")
	local p = H.newPlayer({ completedQuests = { crc } })

	fakeQuest("patrol", "harness_abort")
	mission(p, "patrol", "harness_abort")
	H.abortMission(p, "patrol", "harness_abort")

	lu.assertTrue(p.ghost:isJournalQuestComplete(crc), "still complete (D-4: the net clears only an active entry)")
	lu.assertFalse(p.ghost:isJournalQuestActive(crc), "not active")
	lu.assertEquals(#p.datapad.items, 0, "the orphan mission is removed")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_sends_quest_aborted_with_the_title_and_plays_the_fail_music()
	local p = H.newPlayer({ activeQuests = { H.questCrc("patrol", "harness_abort") } })

	fakeQuest("patrol", "harness_abort")
	mission(p, "patrol", "harness_abort")
	H.abortMission(p, "patrol", "harness_abort")

	local log = H.messageLog(p)

	lu.assertEquals(#log, 1, "one message")
	lu.assertEquals(log[1].id, "@space/quest:quest_aborted", "message id")
	lu.assertEquals(log[1].TO, "@spacequest/patrol/harness_abort:title", "TO")
	lu.assertEquals(p.music, { "sound/music_themequest_fail_criminal.snd" }, "music")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_errors_when_the_datapad_has_no_such_mission()
	local p = H.newPlayer({})

	fakeQuest("patrol", "harness_abort")

	local ok, err = pcall(H.abortMission, p, "patrol", "harness_abort")

	lu.assertFalse(ok, "raises")
	lu.assertStrContains(tostring(err), "no mission on the datapad")
end

-- AC-8 (harness)
function TestAbortFakes:test_abort_mission_names_the_missing_hook()
	local p = H.newPlayer({})

	_G.survival_harness_abort = { questType = "survival", questName = "harness_abort" }
	mission(p, "survival", "harness_abort")

	local ok, err = pcall(H.abortMission, p, "survival", "harness_abort")

	lu.assertFalse(ok, "raises")
	lu.assertStrContains(tostring(err), "abortQuest")
end

---------------------------------------------------------------------------------------------
-- The ShipAiAgent setters the fakes gained exist in the real bindings
---------------------------------------------------------------------------------------------

local function bindingNames(path)
	local f = io.open(path, "r")
	lu.assertNotNil(f, "cannot read " .. path)
	local src = f:read("a")
	f:close()

	local names = {}

	for name in src:gmatch('{%s*"([%w_]+)"%s*,%s*&') do
		names[name] = true
	end

	return names
end

TestAbortAgentFakes = {}

function TestAbortAgentFakes:setUp() H.reset() end

local AGENT_SETTERS = { "setMinimumGuardPatrol", "setMaximumGuardPatrol", "setGuardPatrol", "setDespawnOnNoPlayerInRange" }

function TestAbortAgentFakes:test_the_agent_setters_are_bound_by_luashipaiagent()
	local names = bindingNames(H.ROOT .. "/src/server/zone/objects/ship/ai/LuaShipAiAgent.cpp")

	for _, name in ipairs(AGENT_SETTERS) do
		lu.assertTrue(names[name] == true, name .. " is not in the LuaShipAiAgent method table")
	end
end

function TestAbortAgentFakes:test_the_ship_faction_string_methods_are_bound_by_luashipobject()
	local names = bindingNames(H.ROOT .. "/src/server/zone/objects/ship/LuaShipObject.cpp")

	lu.assertTrue(names.setShipFactionString == true, "setShipFactionString")
	lu.assertTrue(names.getShipFactionString == true, "getShipFactionString")
end

function TestAbortAgentFakes:test_a_spawned_agent_records_the_setters_and_a_ship_reports_its_faction_string()
	local ship = H.newShip({})
	local agent = spawnShipAgent("blacksun_fighter_s01_tier1", "space_corellia", 1, 2, 3, ship)

	lu.assertEquals(ship:getShipFactionString(), "rebel", "default faction string")

	ShipAiAgent(agent):setMinimumGuardPatrol(100)
	ShipAiAgent(agent):setMaximumGuardPatrol(1000)
	ShipAiAgent(agent):setGuardPatrol()
	ShipAiAgent(agent):setDespawnOnNoPlayerInRange(false)
	ShipObject(agent):setShipFactionString("imperial")

	lu.assertEquals({ agent.minimumGuardPatrol, agent.maximumGuardPatrol, agent.guardPatrol, agent.despawnOnNoPlayerInRange },
		{ 100, 1000, true, false }, "recorded setters")
	lu.assertEquals(agent:getShipFactionString(), "imperial", "faction string")
end
