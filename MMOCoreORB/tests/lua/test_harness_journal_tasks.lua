-- The fake journal follows the C++ task rules (harness change H-1 of space-surprise-attack-fixes).
-- PlayerObjectImplementation.cpp: activateJournalQuest :3189-3210 (a new entry activates task 0, no completed tasks),
-- completeJournalQuestTask :3287-3321 (only an owned entry with an active task is completed).

local lu = require("luaunit")
local H = require("harness")

H.boot()

local CRC = H.questCrc("destroy_surpriseattack", "corellia_privateer_1")

TestHarnessJournalTasks = {}

function TestHarnessJournalTasks:setUp()
	H.reset()
	self.ghost = H.newPlayer({ name = "Ace" }).ghost
end

-- AC-1 (H-1)
function TestHarnessJournalTasks:test_activating_a_new_entry_makes_task_0_active_and_nothing_complete()
	local g = self.ghost

	g:activateJournalQuest(CRC, false)

	lu.assertTrue(g:isJournalQuestTaskActive(CRC, 0), "task 0 active")
	lu.assertFalse(g:isJournalQuestTaskComplete(CRC, 0), "task 0 complete")
	lu.assertFalse(g:isJournalQuestTaskActive(CRC, 1), "task 1 active")
end

-- AC-1 (H-1)
function TestHarnessJournalTasks:test_completing_a_task_of_an_entry_nobody_owns_does_nothing()
	local g = self.ghost

	g:activateJournalQuestTask(CRC, 0, false)
	g:completeJournalQuestTask(CRC, 0, false)

	lu.assertFalse(g:isJournalQuestTaskComplete(CRC, 0), "task 0 complete without an owner")
end

-- AC-1 (H-1)
function TestHarnessJournalTasks:test_completing_a_task_that_is_not_active_does_nothing()
	local g = self.ghost

	g:activateJournalQuest(CRC, false)
	g:completeJournalQuestTask(CRC, 1, false)

	lu.assertFalse(g:isJournalQuestTaskComplete(CRC, 1), "task 1 complete although it was never active")
	lu.assertTrue(g:isJournalQuestTaskActive(CRC, 0), "task 0 untouched")
end

-- AC-1 (H-1)
function TestHarnessJournalTasks:test_completing_the_active_task_moves_it_from_active_to_complete()
	local g = self.ghost

	g:activateJournalQuest(CRC, false)
	g:completeJournalQuestTask(CRC, 0, false)
	g:activateJournalQuestTask(CRC, 1, false)

	lu.assertTrue(g:isJournalQuestTaskComplete(CRC, 0), "task 0 complete")
	lu.assertFalse(g:isJournalQuestTaskActive(CRC, 0), "task 0 active")
	lu.assertTrue(g:isJournalQuestTaskActive(CRC, 1), "task 1 active")
end

-- AC-1 (H-1): an owned entry is left alone by a second activation, like the server
function TestHarnessJournalTasks:test_activating_an_owned_entry_again_keeps_its_task_state()
	local g = self.ghost

	g:activateJournalQuest(CRC, false)
	g:completeJournalQuestTask(CRC, 0, false)
	g:activateJournalQuest(CRC, false)

	lu.assertTrue(g:isJournalQuestTaskComplete(CRC, 0), "task 0 stays complete")
	lu.assertFalse(g:isJournalQuestTaskActive(CRC, 0), "task 0 is not re-activated")
end
