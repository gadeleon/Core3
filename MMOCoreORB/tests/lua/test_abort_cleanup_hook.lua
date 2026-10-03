-- The shared abort hook SpaceQuestLogic:abortQuest and what an abort leaves alone.
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md (AC-2, AC-3, I-2, I-5)

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")
local AC = require("abort_cleanup_scenario")
local S = require("survival_scenario")

AC.load()

-- Message ids a Lua abort must never send (I-2); matched against the id and the TO of every message
local FORBIDDEN = { "quest_failed", "quest_won", "quest_ended", "mission_abandoned", "_abandoned", "_aborted_" }
local C_ABORTED = "@space/quest:quest_aborted"

local function forbiddenIn(messages)
	local out = {}

	for _, m in ipairs(messages) do
		for _, text in ipairs({ m.id or "", m.TO or "" }) do
			for _, bad in ipairs(FORBIDDEN) do
				if text:find(bad, 1, true) then
					out[#out + 1] = m.id .. (m.TO and (" / " .. m.TO) or "")
				end
			end
		end
	end

	return out
end

-- A table-driven failure over 120 quests would print 120 lines: show the first few and the count
local function summary(problems)
	if #problems <= 5 then
		return problems
	end

	local out = {}

	for i = 1, 5 do
		out[i] = problems[i]
	end

	out[#out + 1] = string.format("... %d quests in all", #problems)

	return out
end

local function needHook()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "abortQuest")), "function",
		"expected SpaceQuestLogic:abortQuest (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
end

local function ids(messages)
	local out = {}

	for _, m in ipairs(messages) do
		out[#out + 1] = m.id
	end

	return out
end

-- The base screenplay tables defined by the quest types (no squadron data)
local BASES = { "SpaceQuestLogic", "SpaceAssassinateScreenplay", "SpaceBattleScreenplay", "SpaceDeliveryScreenplay",
	"SpaceDeliveryNoPickupScreenplay", "SpaceDestroyScreenplay", "SpaceEscortScreenplay", "SpaceInspectScreenplay",
	"SpacePatrolScreenplay", "SpaceRecoveryScreenplay", "SpaceRescueScreenplay", "SpaceSurpriseAttackScreenplay",
	"SpaceSurvivalScreenplay", "SpaceDutyDestroyScreenplay", "SpaceDutyEscortScreenplay", "SpaceDutyPatrolScreenplay",
	"SpaceDutyRecoveryScreenplay", "SpaceDutyRescueScreenplay" }

---------------------------------------------------------------------------------------------
-- AC-2 / I-5: one hook for every quest
---------------------------------------------------------------------------------------------

TestAbortHook = {}

function TestAbortHook:setUp() H.reset() end

-- AC-2
function TestAbortHook:test_the_quest_logic_base_defines_abort_quest_and_a_default_reset_quest()
	lu.assertEquals(type(rawget(SpaceQuestLogic, "abortQuest")), "function",
		"expected SpaceQuestLogic:abortQuest (screenplays/space/SpaceQuestLogic.lua, Basic Quest Logic Functions)")
	lu.assertEquals(type(rawget(SpaceQuestLogic, "resetQuest")), "function",
		"expected SpaceQuestLogic:resetQuest, the default for future quest types")
end

-- AC-2 (contract 2): no type and no squadron table defines its own abortQuest
function TestAbortHook:test_no_quest_type_and_no_quest_table_defines_its_own_abort_quest()
	local own = {}

	for _, name in ipairs(BASES) do
		if name ~= "SpaceQuestLogic" and rawget(_G[name], "abortQuest") ~= nil then
			own[#own + 1] = name
		end
	end

	for _, name in ipairs(H.questGlobals()) do
		if name ~= "SpaceQuestLogic" and rawget(_G[name], "abortQuest") ~= nil then
			own[#own + 1] = name
		end
	end

	lu.assertEquals(own, {}, "tables with their own abortQuest")
end

-- AC-2 / I-5
function TestAbortHook:test_abort_quest_on_every_quest_global_is_the_shared_function()
	local shared = rawget(SpaceQuestLogic, "abortQuest")
	local problems = {}

	lu.assertNotNil(shared, "SpaceQuestLogic.abortQuest is defined")

	for _, name in ipairs(H.questGlobals()) do
		local q = _G[name]

		if q.abortQuest ~= shared then
			problems[#problems + 1] = name .. ": abortQuest is not SpaceQuestLogic.abortQuest"
		end

		if type(q.resetQuest) ~= "function" then
			problems[#problems + 1] = name .. ": resetQuest is not a function"
		end
	end

	lu.assertEquals(summary(problems), {}, "quest globals")
end

-- AC-2
function TestAbortHook:test_with_an_active_entry_abort_quest_calls_reset_quest_once_with_the_player()
	needHook()

	local problems = DR.collect(DR.quests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		p.ghost:activateJournalQuest(DR.crc(q), false)

		local reset = H.spyOn(q, "resetQuest")
		local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

		q:abortQuest(p)

		if #reset ~= 1 then
			return "resetQuest was called " .. #reset .. " times"
		end

		if reset[1].self ~= q or reset[1].args[1] ~= p then
			return "resetQuest was not called as q:resetQuest(player)"
		end

		if #fail ~= 0 then
			return "failSpaceQuest was called by abortQuest itself"
		end
	end)

	lu.assertEquals(summary(problems), {}, "quests")
end

-- AC-2
function TestAbortHook:test_with_a_quest_that_was_never_taken_abort_quest_does_nothing()
	needHook()

	local problems = DR.collect(DR.quests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)
		local reset = H.spyOn(q, "resetQuest")
		local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

		q:abortQuest(p)

		if #reset ~= 0 or #fail ~= 0 then
			return string.format("resetQuest %d calls, failSpaceQuest %d calls", #reset, #fail)
		end
	end)

	lu.assertEquals(summary(problems), {}, "quests")
end

-- AC-2
function TestAbortHook:test_with_a_completed_entry_abort_quest_does_nothing_and_the_entry_stays_complete()
	needHook()

	local problems = DR.collect(DR.quests(), function(entry)
		local q = entry.quest
		local p = DR.player(q)

		p.ghost:activateJournalQuest(DR.crc(q), false)
		p.ghost:completeJournalQuest(DR.crc(q), false)

		local reset = H.spyOn(q, "resetQuest")
		local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

		q:abortQuest(p)

		if #reset ~= 0 or #fail ~= 0 then
			return string.format("resetQuest %d calls, failSpaceQuest %d calls", #reset, #fail)
		end

		if not DR.complete(p, q) then
			return "the completed entry is no longer complete"
		end
	end)

	lu.assertEquals(summary(problems), {}, "quests")
end

-- AC-2
function TestAbortHook:test_abort_quest_with_no_player_does_nothing()
	local q = H.expectGlobal("patrol_corellia_privateer_1", "patrol quest table")
	local reset = H.spyOn(q, "resetQuest")
	local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

	lu.assertNotNil(q.abortQuest, "abortQuest exists")
	q:abortQuest(nil)

	lu.assertEquals(#reset, 0, "resetQuest calls")
	lu.assertEquals(#fail, 0, "failSpaceQuest calls")
end

-- AC-2 (contract 2): the default reset clears the entry and the mission silently
function TestAbortHook:test_the_default_reset_quest_fails_the_space_quest_without_a_message()
	local t = SpaceQuestLogic:new({ questType = "patrol", questName = "abort_cleanup_probe" })
	local p = H.newPlayer({})
	local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

	lu.assertEquals(type(t.resetQuest), "function", "SpaceQuestLogic:resetQuest exists")
	t:resetQuest(p)

	lu.assertEquals(#fail, 1, "failSpaceQuest calls")
	lu.assertEquals({ fail[1].args[1], fail[1].args[2], fail[1].args[3], fail[1].args[4] }, { p, "patrol", "abort_cleanup_probe", false },
		"failSpaceQuest(player, type, name, false)")
end

-- AC-2 (contract 2)
function TestAbortHook:test_the_default_reset_quest_with_no_player_does_nothing()
	local t = SpaceQuestLogic:new({ questType = "patrol", questName = "abort_cleanup_probe" })
	local fail = H.spyOn(SpaceHelpers, "failSpaceQuest")

	lu.assertEquals(type(t.resetQuest), "function", "SpaceQuestLogic:resetQuest exists")
	t:resetQuest(nil)

	lu.assertEquals(#fail, 0, "failSpaceQuest calls")
end

---------------------------------------------------------------------------------------------
-- AC-3 / I-2: an abort is local
---------------------------------------------------------------------------------------------

TestAbortIsLocal = {}

function TestAbortIsLocal:setUp() H.reset() end
function TestAbortIsLocal:tearDown() AC.tearDown() end

-- Aborts the run and checks the three things AC-3 promises. `spies` is S.isolate's result: every other quest's
-- startQuest/failQuest is a recorder, so "no event" is falsifiable.
local function assertAbortIsLocal(run, spies, label)
	local p = run.player
	local events = #H.Engine.callsTo("createEvent")
	local messages = #p.messageLog

	AC.abort(run)

	-- right after the abort: exactly the C++-modeled message
	lu.assertEquals(ids(AC.messagesSince(p, messages)), { C_ABORTED }, label .. ": messages right after the abort")

	H.advance(60000)

	for _, e in ipairs(AC.eventsSince(events)) do
		lu.assertFalse(e.method == "startQuest" or e.method == "failQuest",
			string.format("%s: an abort queued %s:%s (%s ms)", label, tostring(e.screenplay), e.method, tostring(e.delay)))
	end

	for name, calls in pairs(spies.start) do
		lu.assertEquals(#calls, 0, label .. ": " .. name .. ":startQuest calls")
	end

	for name, calls in pairs(spies.fail) do
		lu.assertEquals(#calls, 0, label .. ": " .. name .. ":failQuest calls")
	end

	local later = AC.messagesSince(p, messages)

	lu.assertEquals(forbiddenIn(later), {}, label .. ": failure, win, end or abandon messages after the abort")
	lu.assertEquals(#DR.messages(p, C_ABORTED), 1, label .. ": quest_aborted is sent once")
end

-- AC-3: survival_corellia_rebel_tier4_1 is BIDIRECTIONAL; a failure would have started space_battle_corellia_rebel_tier4_1_b
function TestAbortIsLocal:test_aborting_a_bidirectional_survival_starts_no_split_quest()
	local run = AC.build("survival")

	lu.assertEquals(run.questName, "corellia_rebel_tier4_1", "the Havoc tier 4 survival")
	lu.assertEquals(run.q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, "precondition: BIDIRECTIONAL")

	assertAbortIsLocal(run, run.spies, "survival_corellia_rebel_tier4_1")
end

-- AC-3: escort_naboo_privateer_tier4_4b is BIDIRECTIONAL too
function TestAbortIsLocal:test_aborting_a_bidirectional_escort_starts_no_split_quest()
	local run = AC.escortRun("escort_naboo_privateer_tier4_4b", true)

	lu.assertEquals(run.q.sideQuestSplitType, SpaceQuestLogic.SIDE_QUEST_SPLIT_TYPES.BIDIRECTIONAL, "precondition: BIDIRECTIONAL")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(run.player, run.questType, run.questName), "precondition: the escort is running")

	assertAbortIsLocal(run, run.spies, "escort_naboo_privateer_tier4_4b")
end

-- AC-3: the parent patrol keeps its entry, its waypoint status and its place in the event queue
function TestAbortIsLocal:test_aborting_a_surprise_attack_leaves_the_active_parent_patrol_alone()
	local patrol = H.expectGlobal("patrol_corellia_privateer_1", "patrol quest table")
	local child = H.expectGlobal("destroy_surpriseattack_corellia_privateer_1", "surprise attack quest table")
	local p, spies = AC.started(patrol, { isolate = { [child.className] = true } })
	local waypointKey = p.objectID .. ":" .. patrol.className .. ":waypointID"

	child:startQuest(p, "")
	H.advance(0)

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, "destroy_surpriseattack", child.questName), "precondition: the surprise attack runs")
	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, "patrol", patrol.questName), "precondition: the parent patrol is active")
	lu.assertNotNil(getQuestStatus(waypointKey), "precondition: the patrol waypoint status")

	local events = #H.Engine.callsTo("createEvent")
	local messages = #p.messageLog

	H.abortMission(p, "destroy_surpriseattack", child.questName)

	lu.assertEquals(ids(AC.messagesSince(p, messages)), { C_ABORTED }, "messages right after the abort")

	H.advance(60000)

	lu.assertTrue(SpaceHelpers:isSpaceQuestActive(p, "patrol", patrol.questName), "the patrol entry is still active")
	lu.assertNotNil(getQuestStatus(waypointKey), "the patrol :waypointID status is still there")
	lu.assertEquals(#p.ghost.waypoints, 1, "the patrol waypoint is still on the player")

	for _, e in ipairs(AC.eventsSince(events)) do
		lu.assertNotEquals(e.screenplay, patrol.className, "an abort queued an event for the patrol: " .. tostring(e.method))
		lu.assertFalse(e.method == "startQuest" or e.method == "failQuest", "an abort queued " .. tostring(e.screenplay) .. ":" .. e.method)
	end

	for name, calls in pairs(spies.start) do
		lu.assertEquals(#calls, 0, name .. ":startQuest calls")
	end

	lu.assertEquals(forbiddenIn(AC.messagesSince(p, messages)), {}, "failure, win, end or abandon messages after the abort")
end
