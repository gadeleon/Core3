-- The order of MissionManagerImplementation::handleMissionAbort, checked statically (the harness cannot run C++).
-- Spec: .claude/work/space-quest-abort-cleanup/01-spec.md (AC-1, contract 1).
-- The build (ninja) and the full ./core3 runUnitTests are the other gates of AC-1; the rest is the in-game checklist.

local lu = require("luaunit")
local H = require("harness")

local SOURCE = H.ROOT .. "/src/server/zone/managers/mission/MissionManagerImplementation.cpp"

-- The body of handleMissionAbort: from its signature to the next member function definition.
local function abortBody()
	local f = io.open(SOURCE, "r")

	lu.assertNotNil(f, "cannot read " .. SOURCE)

	local src = f:read("a")
	f:close()

	local first = src:find("void MissionManagerImplementation::handleMissionAbort(", 1, true)

	lu.assertNotNil(first, "handleMissionAbort not found in MissionManagerImplementation.cpp")

	local last = src:find("\nvoid MissionManagerImplementation::", first + 1, true)

	return src:sub(first, (last or #src + 1) - 1)
end

local function position(body, needle, from)
	return body:find(needle, from or 1, true)
end

-- Position of `needle` in the body, or a failure that names it
local function mustFind(body, needle, from)
	local at = position(body, needle, from)

	lu.assertNotNil(at, "handleMissionAbort: expected to find `" .. needle .. "`")

	return at
end

TestHandleMissionAbortOrder = {}

-- AC-1
function TestHandleMissionAbortOrder:test_abort_then_lua_hook_then_journal_clear_then_remove_mission()
	local body = abortBody()
	local abort = mustFind(body, "mission->abort()")
	local hook = mustFind(body, '"abortQuest"')
	local clear = mustFind(body, "clearJournalQuest(questCRC")
	local remove = mustFind(body, "removeMission(mission, player)")

	lu.assertTrue(abort < hook, "mission->abort() comes before the \"abortQuest\" call")
	lu.assertTrue(hook < clear, "the \"abortQuest\" call comes before clearJournalQuest(questCRC")
	lu.assertTrue(clear < remove, "clearJournalQuest(questCRC comes before removeMission(mission, player)")
end

-- AC-1
function TestHandleMissionAbortOrder:test_the_incapacitated_combat_and_bounty_checks_stay_before_the_abort()
	local body = abortBody()
	local abort = mustFind(body, "mission->abort()")

	for _, check in ipairs({ "isIncapacitated()", "isInCombat()", "hasBhTef()" }) do
		lu.assertTrue(mustFind(body, check) < abort, check .. " is checked before mission->abort()")
	end
end

-- AC-1
function TestHandleMissionAbortOrder:test_the_lua_call_names_abort_quest_and_passes_only_the_player()
	local body = abortBody()
	local create = mustFind(body, "createFunction(")
	local call = mustFind(body, "callFunction()", create)
	local statement = body:sub(create, call)

	lu.assertNotNil(statement:find('"abortQuest"', 1, true), "createFunction names \"abortQuest\"")
	lu.assertNotNil(statement:find('questType + "_" + questName', 1, true), "the function is looked up by <questType>_<questName>")

	local _, pushes = statement:gsub("<<", "")

	lu.assertEquals(pushes, 1, "exactly one argument is pushed (the player)")
	lu.assertNotNil(statement:find("<< player", 1, true), "the argument is the player")
	lu.assertNil(statement:find('<< "false"', 1, true), "no \"false\" argument any more")
end

-- AC-1
function TestHandleMissionAbortOrder:test_fail_quest_is_not_called_from_the_abort()
	lu.assertNil(position(abortBody(), "failQuest", 1), "the string failQuest appears in handleMissionAbort")
end

-- AC-1 (D-4)
function TestHandleMissionAbortOrder:test_the_journal_clear_is_guarded_by_is_journal_quest_active()
	local body = abortBody()
	local clear = mustFind(body, "clearJournalQuest(questCRC")
	local guard = mustFind(body, "isJournalQuestActive(questCRC)")

	lu.assertTrue(guard < clear, "the active check comes before the clear")

	local between = body:sub(guard + #"isJournalQuestActive(questCRC)", clear - 1)

	lu.assertNil(between:find("[;}]"), "nothing but the condition end and the call target between the check and the clear (the clear is the guarded statement)")
end

-- AC-1: the message is unchanged and comes after the safety net, still inside the questMessage branch
function TestHandleMissionAbortOrder:test_the_quest_aborted_message_and_music_stay_and_follow_the_journal_clear()
	local body = abortBody()
	local clear = mustFind(body, "clearJournalQuest(questCRC")
	local flag = mustFind(body, "if (questMessage", clear)
	local message = mustFind(body, '"quest_aborted"', clear)
	local music = mustFind(body, "sound/music_themequest_fail_criminal.snd", clear)
	local remove = mustFind(body, "removeMission(mission, player)")

	lu.assertTrue(flag < message and message < music, "questMessage branch: message, then music")
	lu.assertTrue(music < remove, "the message and music come before removeMission")
	lu.assertNotNil(position(body, "setTO(questString)", clear), "the message TO is the quest title")
end

-- AC-1
function TestHandleMissionAbortOrder:test_remove_mission_is_the_last_statement()
	local body = abortBody()
	local remove = mustFind(body, "removeMission(mission, player)")
	local rest = body:sub(remove + #"removeMission(mission, player);")

	lu.assertNil(rest:find("[%w_]+%s*%("), "no call after removeMission: " .. rest:gsub("%s+", " "))
end
