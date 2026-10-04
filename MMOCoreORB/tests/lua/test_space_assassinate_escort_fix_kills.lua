-- Assassinate kill handling honours mustDestroyEscort (AC-2, AC-3, AC-8 inactive kills).
-- Spec: .claude/work/space-assassinate-escort-fix/01-spec.md (SC-2, SC-3, I-2, I-3, I-6, D-7, D-14).
--
-- SWG: script/space/quest_logic/assassinate.java:149-270 (target and escort kills), assassinate_target.java, assassinate_ship.java.
--
--   mustDestroyEscort false: the target kill alone wins ("assassinate_success", then "quest_won" 1000 ms later)
--   mustDestroyEscort true:  the target kill sends "destroy_escort"; the win comes when the last of target and escorts dies
--   every escort kill counts (D-14); the last one plays the destroyed-all effect and, when true, completes journal task 2
--
-- Every quest is discovered at run time. The expected flag comes from the SWG fixture. Each quest gets its own tests.

local lu = require("luaunit")
local H = require("harness")
local S = require("space_assassinate_escort_fix_scenario")

S.load()

local GLOBALS = S.globals()

local function mdeQuests(value)
	local out = {}

	for _, global in ipairs(GLOBALS) do
		if S.mde(S.quest(global)) == value then
			out[#out + 1] = global
		end
	end

	return out
end

local FALSE_QUESTS = mdeQuests(false)
local TRUE_QUESTS = mdeQuests(true)

-- The "quest_won" pair of messages the win sends 1000 ms after the last kill
local function questWon(q) return { id = "@space/quest:quest_won", TO = S.sid(q, "title") } end

local function plain(id) return { id = id } end

-- The alert of a completion split (it follows the win at sideQuestDelay; for delay 0 it comes with the win)
local ALERT = "@space/quest:quest_alert_s"

-- Splits the messages into the split alerts and the rest
local function splitAlerts(messages)
	local alerts, rest = {}, {}

	for _, m in ipairs(messages) do
		if m.id == ALERT then
			alerts[#alerts + 1] = m
		else
			rest[#rest + 1] = m
		end
	end

	return alerts, rest
end

-- Waits out the win: not complete 999 ms after the kill, complete at 1000 ms with "quest_won", and exactly one completeQuest.
local function assertWinsOneSecondLater(run, label)
	local q = run.q

	H.advance(999)
	lu.assertTrue(S.isActive(run), label .. ": still active 999 ms after the winning kill")
	lu.assertFalse(S.isComplete(run), label .. ": not complete 999 ms after the winning kill")
	lu.assertEquals(S.take(run), {}, label .. ": nothing more is sent before the win")
	H.advance(1)

	lu.assertTrue(S.isComplete(run), label .. ": complete 1000 ms after the winning kill")
	lu.assertFalse(S.isActive(run), label .. ": no longer active")

	local alerts, rest = splitAlerts(S.take(run))

	run.alerts = alerts
	lu.assertEquals(rest, { questWon(q) }, label .. ": messages at the win")
	lu.assertEquals(S.eventsTo(q.className, "completeQuest"), 1, label .. ": completeQuest events queued")
end

-- A win starts exactly the completion split (COMPLETION or BIDIRECTIONAL), after its alert, and nothing else.
local function assertCompletionSplit(run, label)
	local q = run.q

	H.advance(30000)

	local later = S.take(run)
	local alerts = run.alerts or {}

	for _, m in ipairs(later) do
		alerts[#alerts + 1] = m
	end

	if S.splitsOnCompletion(q) then
		lu.assertEquals(S.startQuestEvents(), { S.splitTarget(q) }, label .. ": startQuest events")
		lu.assertEquals(alerts, { { id = ALERT, TO = S.sid(q, "split_quest_alert") } }, label .. ": split alert")
	else
		lu.assertEquals(S.startQuestEvents(), {}, label .. ": startQuest events")
		lu.assertEquals(alerts, {}, label .. ": no alert")
	end
end

---------------------------------------------------------------------------------------------
-- Discovery
---------------------------------------------------------------------------------------------

TestAssassinateEscortFixKillsDiscovery = {}

function TestAssassinateEscortFixKillsDiscovery:test_ten_quests_do_not_need_the_escorts_dead_and_fourteen_do()
	lu.assertEquals(#GLOBALS, 24, "assassinate quest tables")
	lu.assertEquals(#FALSE_QUESTS, 10, "fixtures with mustDestroyEscort = 0")
	lu.assertEquals(#TRUE_QUESTS, 14, "fixtures with mustDestroyEscort = 1")
end

---------------------------------------------------------------------------------------------
-- AC-2: mustDestroyEscort false
---------------------------------------------------------------------------------------------

TestAssassinateMustDestroyEscortFalse = {}

function TestAssassinateMustDestroyEscortFalse:setUp() H.reset() end

for _, global in ipairs(FALSE_QUESTS) do
	-- AC-2
	TestAssassinateMustDestroyEscortFalse["test_" .. global .. "_is_won_by_the_target_kill_alone"] = function()
		local run = S.deployed(global)
		local q = run.q

		S.kill(run, run.target)

		lu.assertEquals(S.take(run), { plain(S.sid(q, "assassinate_success")) }, global .. ": messages at the target kill (no destroy_escort)")
		lu.assertTrue(S.taskComplete(run, 1), global .. ": journal task 1 complete")
		lu.assertEquals(S.destroyedAllEffects(run.player), 0, global .. ": the destroyed-all effect is not played with escorts alive")

		assertWinsOneSecondLater(run, global)

		lu.assertTrue(S.taskComplete(run, 1), global .. ": journal task 1 still complete")
		lu.assertFalse(S.taskActive(run, 2) or S.taskComplete(run, 2), global .. ": journal task 2 was never active")
		assertCompletionSplit(run, global)
	end

	-- AC-2, D-14
	TestAssassinateMustDestroyEscortFalse["test_" .. global .. "_counts_every_escort_kill_and_wins_on_the_target_kill_afterwards"] = function()
		local run = S.deployed(global)
		local q = run.q
		local n = #run.escorts

		lu.assertTrue(n >= 1, global .. ": precondition: the quest has escorts")

		for i = 1, n - 1 do
			S.kill(run, run.escorts[i])

			local got = S.take(run)

			lu.assertEquals(got, { { id = S.sid(q, "escort_remaining"), DI = n - i } }, global .. ": messages at escort kill " .. i .. " of " .. n)
			lu.assertEquals(S.destroyedAllEffects(run.player), 0, global .. ": no destroyed-all effect before the last escort")
		end

		S.kill(run, run.escorts[n])

		lu.assertEquals(S.take(run), { plain(S.sid(q, "escort_wiped_out")) }, global .. ": messages at the last escort kill")
		lu.assertEquals(S.destroyedAllEffects(run.player), 1, global .. ": the destroyed-all effect plays on the last escort kill")

		H.advance(5000)
		lu.assertTrue(S.isActive(run), global .. ": still active with the target alive")
		lu.assertFalse(S.isComplete(run), global .. ": not complete with the target alive")
		lu.assertEquals(S.eventsTo(q.className, "completeQuest"), 0, global .. ": no completeQuest queued yet")
		lu.assertFalse(S.taskActive(run, 2) or S.taskComplete(run, 2), global .. ": journal task 2 was never active")
		S.take(run)

		S.kill(run, run.target)

		lu.assertEquals(S.take(run), { plain(S.sid(q, "assassinate_success")) }, global .. ": messages at the target kill")
		lu.assertEquals(S.destroyedAllEffects(run.player), 1, global .. ": the destroyed-all effect is played once only")
		assertWinsOneSecondLater(run, global)
		lu.assertTrue(S.taskComplete(run, 1), global .. ": journal task 1 complete")
		assertCompletionSplit(run, global)
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: mustDestroyEscort true
---------------------------------------------------------------------------------------------

TestAssassinateMustDestroyEscortTrue = {}

function TestAssassinateMustDestroyEscortTrue:setUp() H.reset() end

for _, global in ipairs(TRUE_QUESTS) do
	-- AC-3
	TestAssassinateMustDestroyEscortTrue["test_" .. global .. "_target_first_asks_for_the_escorts_and_wins_on_the_last_escort"] = function()
		local run = S.deployed(global)
		local q = run.q
		local n = #run.escorts
		local pid, cls = run.player.objectID, q.className

		lu.assertTrue(S.taskActive(run, 2), global .. ": precondition: journal task 2 (the escorts) is active")

		S.kill(run, run.target)

		lu.assertEquals(S.take(run), { plain(S.sid(q, "destroy_escort")) }, global .. ": messages at the target kill (no assassinate_success)")
		lu.assertTrue(S.taskComplete(run, 1), global .. ": journal task 1 complete")
		lu.assertEquals(readData(pid .. ":" .. cls .. ":TargetDestroyed:"), 1, global .. ": TargetDestroyed key")
		lu.assertEquals(S.destroyedAllEffects(run.player), 0, global .. ": no destroyed-all effect yet")

		H.advance(5000)
		lu.assertTrue(S.isActive(run), global .. ": still active with the escorts alive, 5 s later")
		lu.assertFalse(S.isComplete(run), global .. ": not complete with the escorts alive")
		lu.assertEquals(S.eventsTo(cls, "completeQuest"), 0, global .. ": no completeQuest queued")
		lu.assertEquals(S.take(run), {}, global .. ": nothing more is sent")

		for i = 1, n - 1 do
			S.kill(run, run.escorts[i])
			lu.assertEquals(S.take(run), { { id = S.sid(q, "escort_remaining"), DI = n - i } }, global .. ": messages at escort kill " .. i .. " of " .. n)
			lu.assertFalse(S.taskComplete(run, 2), global .. ": journal task 2 open while escorts remain")
		end

		lu.assertTrue(S.isActive(run), global .. ": still active before the last escort")

		S.kill(run, run.escorts[n])

		lu.assertEquals(S.take(run), { plain(S.sid(q, "assassinate_success")) }, global .. ": messages at the last escort kill")
		lu.assertEquals(S.destroyedAllEffects(run.player), 1, global .. ": the destroyed-all effect plays once")
		lu.assertTrue(S.taskComplete(run, 2), global .. ": journal task 2 complete")

		assertWinsOneSecondLater(run, global)
		lu.assertTrue(S.taskComplete(run, 1) and S.taskComplete(run, 2), global .. ": journal tasks 1 and 2 complete")
		assertCompletionSplit(run, global)
	end

	-- AC-3
	TestAssassinateMustDestroyEscortTrue["test_" .. global .. "_escorts_first_report_the_wipe_out_and_the_target_kill_wins"] = function()
		local run = S.deployed(global)
		local q = run.q
		local n = #run.escorts
		local pid, cls = run.player.objectID, q.className

		for i = 1, n - 1 do
			S.kill(run, run.escorts[i])
			lu.assertEquals(S.take(run), { { id = S.sid(q, "escort_remaining"), DI = n - i } }, global .. ": messages at escort kill " .. i .. " of " .. n)
			lu.assertEquals(readData(pid .. ":" .. cls .. ":EscortKills:"), i, global .. ": EscortKills after kill " .. i)
		end

		S.kill(run, run.escorts[n])

		lu.assertEquals(S.take(run), { plain(S.sid(q, "escort_wiped_out")) }, global .. ": messages at the last escort kill")
		lu.assertEquals(S.destroyedAllEffects(run.player), 1, global .. ": the destroyed-all effect plays on the last escort")
		lu.assertTrue(S.taskComplete(run, 2), global .. ": journal task 2 complete")
		lu.assertFalse(S.hasKey(pid .. ":" .. cls .. ":TargetDestroyed:"), global .. ": TargetDestroyed key is not set")

		H.advance(5000)
		lu.assertTrue(S.isActive(run), global .. ": still active with the target alive")
		lu.assertFalse(S.isComplete(run), global .. ": not complete with the target alive")
		lu.assertEquals(S.eventsTo(cls, "completeQuest"), 0, global .. ": no completeQuest queued")

		S.kill(run, run.target)

		lu.assertEquals(S.take(run), { plain(S.sid(q, "assassinate_success")) }, global .. ": messages at the target kill")
		lu.assertTrue(S.taskComplete(run, 1), global .. ": journal task 1 complete")
		assertWinsOneSecondLater(run, global)
		lu.assertEquals(S.destroyedAllEffects(run.player), 1, global .. ": the destroyed-all effect was played once")
		assertCompletionSplit(run, global)
	end
end

---------------------------------------------------------------------------------------------
-- Keys of the kill counters (Content contract, shared-memory keys)
---------------------------------------------------------------------------------------------

TestAssassinateKillKeys = {}

function TestAssassinateKillKeys:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-8 (SC-2, SC-3)
	TestAssassinateKillKeys["test_" .. global .. "_counts_escort_kills_without_a_total_kills_key_and_frees_each_dead_ships_keys"] = function()
		local run = S.deployed(global)
		local pid, cls = run.player.objectID, run.q.className

		lu.assertTrue(S.hasKey(run.escorts[1].objectID .. ":" .. cls .. ":QuestOwner"), global .. ": precondition: the escort has a QuestOwner key")

		S.kill(run, run.escorts[1])

		lu.assertEquals(readData(pid .. ":" .. cls .. ":EscortKills:"), 1, global .. ": EscortKills after one escort kill")
		lu.assertFalse(S.hasKey(pid .. ":" .. cls .. ":TotalKills:"), global .. ": TotalKills is no longer written")
		lu.assertFalse(S.hasKey(run.escorts[1].objectID .. ":" .. cls .. ":QuestOwner"), global .. ": the dead escort's QuestOwner key is deleted")
		lu.assertFalse(S.missionObjectSet(run.player)[run.escorts[1].objectID] == true, global .. ": the dead escort is no longer a mission object")

		if S.mde(run.q) == false or #run.escorts > 1 then
			S.kill(run, run.target)

			lu.assertFalse(S.hasKey(pid .. ":" .. cls .. ":TotalKills:"), global .. ": TotalKills is still not written after the target kill")
			lu.assertFalse(S.hasKey(run.target.objectID .. ":" .. cls .. ":PrimaryTarget:"), global .. ": the PrimaryTarget key is deleted")
			lu.assertFalse(S.hasKey(run.target.objectID .. ":" .. cls .. ":QuestOwner"), global .. ": the dead target's QuestOwner key is deleted")
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-8, I-6: a kill while the quest is not active changes nothing
---------------------------------------------------------------------------------------------

TestAssassinateInactiveKills = {}

function TestAssassinateInactiveKills:setUp() H.reset() end

for _, global in ipairs(GLOBALS) do
	-- AC-8, I-6
	TestAssassinateInactiveKills["test_" .. global .. "_ignores_kills_reported_after_the_quest_left_the_journal"] = function()
		local run = S.deployed(global)
		local q = run.q
		local victims = { run.target, run.escorts[1] }

		SpaceHelpers:failSpaceQuest(run.player, q.questType, q.questName, false)

		lu.assertFalse(S.isActive(run), global .. ": precondition: the quest is not active")

		for i, ship in ipairs(victims) do
			local label = global .. ": kill " .. i .. " (" .. (i == 1 and "target" or "escort") .. ")"
			local keysBefore = H.Engine.sharedMemoryKeys()
			local events = #H.Engine.callsTo("createEvent")
			local pending = #H.pendingEvents()
			local sent = #H.messageLog(run.player)
			local effects = #run.player.effects

			lu.assertTrue(H.hasObserver(SHIPDESTROYED, q.className, "notifyShipDestroyed", ship), label .. ": precondition: the ship still has its observer")

			H.fireObservers(SHIPDESTROYED, ship, nil)

			lu.assertFalse(H.hasObserver(SHIPDESTROYED, q.className, "notifyShipDestroyed", ship), label .. ": the handler returned 1 (observer removed)")
			lu.assertEquals(#H.messageLog(run.player), sent, label .. ": no message")
			lu.assertEquals(#run.player.effects, effects, label .. ": no effect")
			lu.assertEquals(#H.Engine.callsTo("createEvent"), events, label .. ": no event queued")
			lu.assertEquals(#H.pendingEvents(), pending, label .. ": pending events")
			lu.assertEquals(H.Engine.sharedMemoryKeys(), keysBefore, label .. ": shared-memory keys")
			lu.assertFalse(S.missionObjectSet(run.player)[ship.objectID] == true, label .. ": the ship is removed from the pilot's mission objects")
		end

		lu.assertFalse(S.isComplete(run), global .. ": nothing completes the quest")
	end
end
