-- Shared migration helpers in utils/space_helpers.lua (rsf-tier3-renames SC-2).
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-6 purgeSpaceQuest / migrateSpaceQuestEntry, AC-7 moveQuestStatuses,
-- AC-8 runProgressMigrations, invariants I-7, I-8).
--
-- The helpers are generic (F4 and F5 reuse them), so these tests build legacy state by hand on made-up and real names
-- and need no quest global: the old class has no table any more, which is the point of "purge".

local lu = require("luaunit")
local H = require("harness")
local M = require("migration_scenario")

H.loadSquadron("CorsecSquadronScreenplay")

local OLD = { "delivery", "naboo_privateer_tier3_3b" }
local NEW1 = { "delivery_no_pickup", "naboo_privateer_tier3_3b" }
local NEW3 = { { "destroy_surpriseattack", "naboo_privateer_tier3_4c" }, { "destroy_surpriseattack", "naboo_privateer_tier3_4d" }, { "destroy_surpriseattack", "naboo_privateer_tier3_4e" } }

local function moveTo(list)
	local out = {}

	for i, e in ipairs(list) do
		out[i] = { type = e[1], name = e[2] }
	end

	return out
end

local function newPilot()
	return H.newPlayer({ name = "Ace", zone = "space_lok", ship = true, pilot = "neutral" })
end

-- A missing helper is a clean red: one readable failure instead of "attempt to call a nil value"
local function needs(...)
	for _, name in ipairs({ ... }) do
		lu.assertEquals(type(SpaceHelpers[name]), "function", "utils/space_helpers.lua must define SpaceHelpers:" .. name)
	end
end

local function noSideEffects(player, before, label)
	lu.assertEquals(M.sideEffects(player), before, label .. ": messages, music and createEvent calls")
end

---------------------------------------------------------------------------------------------
-- Harness: completing an entry that was never activated does nothing (PlayerObjectImplementation.cpp:3212-3217)
---------------------------------------------------------------------------------------------

TestJournalCompleteFake = {}

function TestJournalCompleteFake:setUp() H.reset() end

-- AC-6 (harness change)
function TestJournalCompleteFake:test_completing_an_entry_that_was_never_activated_writes_nothing()
	local player = newPilot()
	local crc = M.crc("delivery", "x")

	player.ghost:completeJournalQuest(crc, false)

	lu.assertEquals(M.state(player, "delivery", "x"), "none", "journal state after complete without activate")
	lu.assertFalse(player.ghost:isJournalQuestComplete(crc), "isJournalQuestComplete")
end

-- AC-6 (harness change)
function TestJournalCompleteFake:test_activate_then_complete_writes_a_completed_entry_that_activate_cannot_reopen()
	local player = newPilot()
	local crc = M.crc("delivery", "x")

	player.ghost:activateJournalQuest(crc, false)
	lu.assertEquals(M.state(player, "delivery", "x"), "active", "after activate")

	player.ghost:completeJournalQuest(crc, false)
	lu.assertEquals(M.state(player, "delivery", "x"), "complete", "after complete")

	player.ghost:activateJournalQuest(crc, false)
	lu.assertEquals(M.state(player, "delivery", "x"), "complete", "activate on a completed entry is a no-op")

	player.ghost:completeJournalQuest(crc, false)
	lu.assertEquals(M.state(player, "delivery", "x"), "complete", "completing twice keeps it complete")
end

-- AC-6 (harness change): a cleared entry has no owner again
function TestJournalCompleteFake:test_completing_a_cleared_entry_does_nothing()
	local player = newPilot()
	local crc = M.crc("delivery", "x")

	player.ghost:activateJournalQuest(crc, false)
	player.ghost:clearJournalQuest(crc, false)
	player.ghost:completeJournalQuest(crc, false)

	lu.assertEquals(M.state(player, "delivery", "x"), "none", "journal state")
end

---------------------------------------------------------------------------------------------
-- AC-6: purgeSpaceQuest
---------------------------------------------------------------------------------------------

TestPurgeSpaceQuest = {}

function TestPurgeSpaceQuest:setUp()
	H.reset()
	needs("purgeSpaceQuest")
end

function TestPurgeSpaceQuest:tearDown() rawset(_G, "delivery_naboo_privateer_tier3_3b", nil) end

-- AC-6 (c)
function TestPurgeSpaceQuest:test_an_active_run_loses_journal_entry_datapad_mission_observer_and_waypoint_without_message_or_music()
	local player = newPilot()

	M.startRun(player, OLD[1], OLD[2])

	local before = M.sideEffects(player)
	local leftBefore = M.leftovers(player, OLD[1], OLD[2])

	lu.assertEquals(leftBefore.journal, "active", "setup: journal")
	lu.assertEquals(leftBefore.missions, 1, "setup: datapad missions")
	lu.assertEquals(leftBefore.observers, { "ZONESWITCHED" }, "setup: observers")
	lu.assertNotNil(leftBefore.waypointKey, "setup: waypoint key")
	lu.assertTrue(leftBefore.waypoint, "setup: waypoint")

	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), "leftovers of delivery/naboo_privateer_tier3_3b")
	lu.assertEquals(player.failedMissions, { M.crc(OLD[1], OLD[2]) }, "failedMissions (the old CRC)")
	noSideEffects(player, before, "purge")
end

-- AC-6
function TestPurgeSpaceQuest:test_a_completed_entry_is_cleared_too()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.state(player, OLD[1], OLD[2]), "none", "journal state of the completed entry")
end

-- AC-6: all three observers an inspect run leaves
function TestPurgeSpaceQuest:test_the_inspect_observers_are_dropped_as_well()
	local player = newPilot()

	M.startRun(player, "inspect", "naboo_privateer_tier3_old", { inspect = true })
	lu.assertEquals(M.leftovers(player, "inspect", "naboo_privateer_tier3_old").observers, { "ZONESWITCHED", "INSPECTEDSHIP", "SHIPDOCKED" }, "setup: observers")

	SpaceHelpers:purgeSpaceQuest(player, "inspect", "naboo_privateer_tier3_old")

	lu.assertEquals(M.leftovers(player, "inspect", "naboo_privateer_tier3_old"), M.clean(), "leftovers")
end

-- AC-6 (d): leftovers without a journal entry are still removed
function TestPurgeSpaceQuest:test_observer_and_waypoint_leftovers_go_even_without_a_journal_entry()
	local player = newPilot()

	M.startRun(player, OLD[1], OLD[2])
	player.ghost:clearJournalQuest(M.crc(OLD[1], OLD[2]), false)

	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), "leftovers")
end

-- AC-6, I-8
function TestPurgeSpaceQuest:test_purging_twice_changes_nothing_the_second_time()
	local player = newPilot()

	M.startRun(player, OLD[1], OLD[2])
	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	local snap, before = M.snapshot(player), M.sideEffects(player)

	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.snapshot(player), snap, "state after the second purge")
	noSideEffects(player, before, "second purge")
end

-- AC-6: a purge of one quest leaves other quests alone, including the same name under another type
function TestPurgeSpaceQuest:test_other_quests_with_the_same_name_or_the_same_type_are_untouched()
	local player = newPilot()

	M.startRun(player, NEW1[1], NEW1[2])
	M.startRun(player, "delivery", "naboo_privateer_tier3_other")
	M.finish(player, "survival", "naboo_privateer_tier3_3c")
	M.startRun(player, OLD[1], OLD[2])

	local keepA, keepB = M.leftovers(player, NEW1[1], NEW1[2]), M.leftovers(player, "delivery", "naboo_privateer_tier3_other")

	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.leftovers(player, NEW1[1], NEW1[2]), keepA, "delivery_no_pickup 3b (same name, other type)")
	lu.assertEquals(M.leftovers(player, "delivery", "naboo_privateer_tier3_other"), keepB, "delivery, other name")
	lu.assertEquals(M.state(player, "survival", "naboo_privateer_tier3_3c"), "complete", "survival 3c")
end

-- AC-6 (h), I-7
function TestPurgeSpaceQuest:test_a_nil_player_or_a_creature_without_a_ghost_is_ignored()
	local okNil, errNil = pcall(SpaceHelpers.purgeSpaceQuest, SpaceHelpers, nil, OLD[1], OLD[2])

	lu.assertTrue(okNil, "a nil player raised: " .. tostring(errNil))

	local npc = H.newNpc({ name = "Trainer" })
	local ok, err = pcall(SpaceHelpers.purgeSpaceQuest, SpaceHelpers, npc, OLD[1], OLD[2])

	lu.assertTrue(ok, "a creature without a ghost raised: " .. tostring(err))
end

-- I-7: the class global of a deleted quest does not exist, and a stale one must not be called
function TestPurgeSpaceQuest:test_it_never_calls_a_method_on_the_quest_global()
	local player = newPilot()

	M.startRun(player, OLD[1], OLD[2])
	rawset(_G, "delivery_naboo_privateer_tier3_3b", setmetatable({}, { __index = function(_, k) error("purge touched delivery_naboo_privateer_tier3_3b." .. tostring(k)) end }))

	SpaceHelpers:purgeSpaceQuest(player, OLD[1], OLD[2])

	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), "leftovers")
end

---------------------------------------------------------------------------------------------
-- AC-6: migrateSpaceQuestEntry
---------------------------------------------------------------------------------------------

TestMigrateSpaceQuestEntry = {}

function TestMigrateSpaceQuestEntry:setUp()
	H.reset()
	needs("migrateSpaceQuestEntry", "purgeSpaceQuest")
end

function TestMigrateSpaceQuestEntry:tearDown() rawset(_G, "delivery_naboo_privateer_tier3_3b", nil) end

-- AC-6 (a)
function TestMigrateSpaceQuestEntry:test_a_completed_old_entry_completes_its_one_target_and_is_purged()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	M.startRun(player, "survival", "naboo_privateer_tier3_noise") -- unrelated active run

	local before = M.sideEffects(player)
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 }))

	lu.assertTrue(result, "return value")
	lu.assertEquals(M.state(player, NEW1[1], NEW1[2]), "complete", "target journal state")
	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), "old quest leftovers")
	lu.assertEquals(M.missions(player, NEW1[1], NEW1[2]), 0, "no datapad mission for the target")
	lu.assertEquals(M.state(player, "survival", "naboo_privateer_tier3_noise"), "active", "unrelated run")
	noSideEffects(player, before, "migration")
end

-- AC-6 (b)
function TestMigrateSpaceQuestEntry:test_a_completed_old_entry_completes_all_three_targets()
	local player = newPilot()
	local old = { "survival", "naboo_privateer_tier3_4c" }

	M.finish(player, old[1], old[2])

	local before = M.sideEffects(player)
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3))

	lu.assertTrue(result, "return value")

	for _, t in ipairs(NEW3) do
		lu.assertEquals(M.state(player, t[1], t[2]), "complete", t[2] .. ": journal state")
		lu.assertEquals(M.missions(player, t[1], t[2]), 0, t[2] .. ": datapad missions")
	end

	lu.assertEquals(M.leftovers(player, old[1], old[2]), M.clean(), "old quest leftovers")
	noSideEffects(player, before, "migration")
end

-- AC-6 (c)
function TestMigrateSpaceQuestEntry:test_an_active_old_run_is_purged_completely_and_writes_no_target()
	local player = newPilot()

	M.startRun(player, OLD[1], OLD[2])

	local before = M.sideEffects(player)
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 }))

	lu.assertFalse(result, "return value")
	lu.assertEquals(M.state(player, NEW1[1], NEW1[2]), "none", "target journal state")
	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), "old quest leftovers (journal, datapad mission, observer, waypoint key, waypoint)")
	lu.assertEquals(player.failedMissions, { M.crc(OLD[1], OLD[2]) }, "failedMissions (the old CRC, once)")
	noSideEffects(player, before, "migration")
end

-- AC-6 (d)
function TestMigrateSpaceQuestEntry:test_an_absent_old_entry_changes_nothing_but_the_purge()
	local player = newPilot()
	local old = { "survival", "naboo_privateer_tier3_4c" }

	M.finish(player, "survival", "naboo_privateer_tier3_3c")

	local snap = M.snapshot(player)
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3))

	lu.assertFalse(result, "return value")
	lu.assertEquals(M.snapshot(player), snap, "journal, status, observers, waypoints and datapad")

	-- a leftover observer without a journal entry is still purged
	createObserver(ZONESWITCHED, "survival_naboo_privateer_tier3_4c", "enteredZone", player, 1)
	SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3))
	lu.assertEquals(M.leftovers(player, old[1], old[2]), M.clean(), "leftover observer purged")
	lu.assertEquals(M.state(player, NEW3[1][1], NEW3[1][2]), "none", "no target written for an absent old entry")
end

-- AC-6 (e), D-5
function TestMigrateSpaceQuestEntry:test_a_live_run_on_a_target_blocks_the_completion_and_stays_untouched()
	local player = newPilot()
	local old = { "survival", "naboo_privateer_tier3_4c" }

	M.finish(player, old[1], old[2])
	M.startRun(player, NEW3[1][1], NEW3[1][2]) -- 4c runs
	writeData(player.objectID .. "destroy_surpriseattack_naboo_privateer_tier3_4c:Count", 2)

	local live = M.leftovers(player, NEW3[1][1], NEW3[1][2])
	local before = M.sideEffects(player)
	local memory = H.Engine.sharedMemoryKeys()
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3))

	lu.assertFalse(result, "return value")
	lu.assertEquals(M.leftovers(player, NEW3[1][1], NEW3[1][2]), live, "the live target's journal, mission, observer and waypoint")
	lu.assertEquals(M.state(player, NEW3[2][1], NEW3[2][2]), "none", "4d is not written while 4c runs")
	lu.assertEquals(M.state(player, NEW3[3][1], NEW3[3][2]), "none", "4e is not written while 4c runs")
	lu.assertEquals(readData(player.objectID .. "destroy_surpriseattack_naboo_privateer_tier3_4c:Count"), 2, "the live run's shared memory")
	lu.assertEquals(H.Engine.sharedMemoryKeys(), memory, "shared memory keys")
	lu.assertEquals(M.leftovers(player, old[1], old[2]), M.clean(), "old quest purged")
	noSideEffects(player, before, "migration")
end

-- AC-6 (e): an active target in the middle blocks all
function TestMigrateSpaceQuestEntry:test_an_active_middle_target_blocks_the_completion_of_the_others()
	local player = newPilot()
	local old = { "survival", "naboo_privateer_tier3_4c" }

	M.finish(player, old[1], old[2])
	M.startRun(player, NEW3[2][1], NEW3[2][2])

	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3)), "return value")
	lu.assertEquals({ M.state(player, NEW3[1][1], NEW3[1][2]), M.state(player, NEW3[2][1], NEW3[2][2]), M.state(player, NEW3[3][1], NEW3[3][2]) }, { "none", "active", "none" }, "4c, 4d, 4e journal states")
end

-- AC-6 (f)
function TestMigrateSpaceQuestEntry:test_a_target_that_is_already_complete_is_kept_and_the_other_two_are_written()
	local player = newPilot()
	local old = { "survival", "naboo_privateer_tier3_4c" }

	M.finish(player, old[1], old[2])
	M.finish(player, NEW3[2][1], NEW3[2][2])

	local result = SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], moveTo(NEW3))

	lu.assertTrue(result, "return value (two completions were written)")
	lu.assertEquals({ M.state(player, NEW3[1][1], NEW3[1][2]), M.state(player, NEW3[2][1], NEW3[2][2]), M.state(player, NEW3[3][1], NEW3[3][2]) }, { "complete", "complete", "complete" }, "4c, 4d, 4e journal states")
	lu.assertEquals(M.state(player, old[1], old[2]), "none", "old entry")
end

-- AC-6: every target complete already, nothing to write
function TestMigrateSpaceQuestEntry:test_all_targets_complete_already_returns_false_and_still_purges_the_old_entry()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	M.finish(player, NEW1[1], NEW1[2])

	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 })), "return value")
	lu.assertEquals(M.state(player, NEW1[1], NEW1[2]), "complete", "target stays complete")
	lu.assertEquals(M.state(player, OLD[1], OLD[2]), "none", "old entry purged")
end

-- AC-6: a quest that was deleted outright (moveTo = {})
function TestMigrateSpaceQuestEntry:test_an_empty_move_to_only_purges()
	local player = newPilot()
	local old = { "destroy_surpriseattack", "naboo_privateer_tier3_4_initial" }

	M.finish(player, old[1], old[2])
	M.startRun(player, "survival", "naboo_privateer_tier3_gone")

	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], {}), "return value for a complete entry")
	lu.assertEquals(M.leftovers(player, old[1], old[2]), M.clean(), "leftovers of the deleted quest")

	M.startRun(player, old[1], old[2])
	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(player, old[1], old[2], {}), "return value for an active entry")
	lu.assertEquals(M.leftovers(player, old[1], old[2]), M.clean(), "leftovers of the deleted quest after an active run")
	lu.assertEquals(M.state(player, "survival", "naboo_privateer_tier3_gone"), "active", "unrelated run")
end

-- AC-6 (g)
function TestMigrateSpaceQuestEntry:test_a_move_to_list_that_contains_the_old_name_changes_nothing()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	createObserver(ZONESWITCHED, M.className(OLD[1], OLD[2]), "enteredZone", player, 1)

	local snap = M.snapshot(player)
	local result = SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1, OLD }))

	lu.assertFalse(result, "return value")
	lu.assertEquals(M.snapshot(player), snap, "journal, status, observers, waypoints and datapad")
end

-- AC-6 (h)
function TestMigrateSpaceQuestEntry:test_a_nil_player_or_a_creature_without_a_ghost_returns_false()
	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(nil, OLD[1], OLD[2], moveTo({ NEW1 })), "nil player")
	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(H.newNpc({ name = "Trainer" }), OLD[1], OLD[2], moveTo({ NEW1 })), "creature without a ghost")
end

-- I-8
function TestMigrateSpaceQuestEntry:test_running_it_twice_changes_nothing_the_second_time()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	lu.assertTrue(SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 })), "first run")

	local snap, before = M.snapshot(player), M.sideEffects(player)

	lu.assertFalse(SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 })), "second run")
	lu.assertEquals(M.snapshot(player), snap, "state after the second run")
	noSideEffects(player, before, "second run")
end

-- I-7
function TestMigrateSpaceQuestEntry:test_it_never_calls_a_method_on_a_quest_global_nor_on_the_target_of_the_move()
	local player = newPilot()

	M.finish(player, OLD[1], OLD[2])
	rawset(_G, "delivery_naboo_privateer_tier3_3b", setmetatable({}, { __index = function(_, k) error("migration touched delivery_naboo_privateer_tier3_3b." .. tostring(k)) end }))

	lu.assertTrue(SpaceHelpers:migrateSpaceQuestEntry(player, OLD[1], OLD[2], moveTo({ NEW1 })), "return value")
end

---------------------------------------------------------------------------------------------
-- AC-7: moveQuestStatuses
---------------------------------------------------------------------------------------------

TestMoveQuestStatuses = {}

function TestMoveQuestStatuses:setUp()
	H.reset()
	needs("moveQuestStatuses")
end

-- AC-7
function TestMoveQuestStatuses:test_a_value_moves_to_an_unset_new_key_and_the_old_key_is_removed()
	local player = newPilot()

	H.setQuestStatus(player, "old:attempted", "1")
	SpaceHelpers:moveQuestStatuses(player, { { old = "old:attempted", new = "new:attempted" } })

	lu.assertEquals(H.getQuestStatus(player, "new:attempted"), "1", "new key")
	lu.assertNil(H.getQuestStatus(player, "old:attempted"), "old key")
end

-- AC-7
function TestMoveQuestStatuses:test_an_existing_new_key_is_kept_and_the_old_key_is_still_removed()
	local player = newPilot()

	H.setQuestStatus(player, "old:reward", "1")
	H.setQuestStatus(player, "new:reward", "7")
	SpaceHelpers:moveQuestStatuses(player, { { old = "old:reward", new = "new:reward" } })

	lu.assertEquals(H.getQuestStatus(player, "new:reward"), "7", "new key keeps its value")
	lu.assertNil(H.getQuestStatus(player, "old:reward"), "old key")
end

-- AC-7
function TestMoveQuestStatuses:test_a_move_without_a_new_key_only_removes_the_old_key()
	local player = newPilot()

	H.setQuestStatus(player, "old:gone", "1")
	H.setQuestStatus(player, "bystander", "3")
	SpaceHelpers:moveQuestStatuses(player, { { old = "old:gone" } })

	lu.assertNil(H.getQuestStatus(player, "old:gone"), "old key")
	lu.assertEquals(H.getQuestStatus(player, "bystander"), "3", "other keys")
end

-- AC-7
function TestMoveQuestStatuses:test_a_move_whose_old_key_is_unset_leaves_the_new_key_alone()
	local player = newPilot()

	H.setQuestStatus(player, "new:a", "5")
	SpaceHelpers:moveQuestStatuses(player, { { old = "old:a", new = "new:a" }, { old = "old:b", new = "new:b" } })

	lu.assertEquals(H.getQuestStatus(player, "new:a"), "5", "new:a keeps its value")
	lu.assertNil(H.getQuestStatus(player, "new:b"), "new:b stays unset")
	lu.assertNil(H.getQuestStatus(player, "old:a"), "old:a")
end

-- AC-7: the F4 shape; pairwise moving would lose a value
function TestMoveQuestStatuses:test_a_chain_of_colliding_names_moves_every_value_one_step()
	local player = newPilot()

	H.setQuestStatus(player, "A", "1")
	H.setQuestStatus(player, "B", "2")
	SpaceHelpers:moveQuestStatuses(player, { { old = "A", new = "B" }, { old = "B", new = "C" } })

	lu.assertEquals({ H.getQuestStatus(player, "B"), H.getQuestStatus(player, "C") }, { "1", "2" }, "B, C")
	lu.assertNil(H.getQuestStatus(player, "A"), "A")
end

-- AC-7: the same chain listed in the other order gives the same result
function TestMoveQuestStatuses:test_the_chain_result_does_not_depend_on_the_order_of_the_moves()
	local player = newPilot()

	H.setQuestStatus(player, "A", "1")
	H.setQuestStatus(player, "B", "2")
	SpaceHelpers:moveQuestStatuses(player, { { old = "B", new = "C" }, { old = "A", new = "B" } })

	lu.assertEquals({ H.getQuestStatus(player, "B"), H.getQuestStatus(player, "C") }, { "1", "2" }, "B, C")
	lu.assertNil(H.getQuestStatus(player, "A"), "A")
end

-- AC-7: keys are <objectID><suffix>, one player's keys do not touch another's
function TestMoveQuestStatuses:test_only_the_given_players_keys_move()
	local player, other = newPilot(), newPilot()

	H.setQuestStatus(player, "old:x", "1")
	H.setQuestStatus(other, "old:x", "9")
	SpaceHelpers:moveQuestStatuses(player, { { old = "old:x", new = "new:x" } })

	lu.assertEquals(H.getQuestStatus(player, "new:x"), "1", "player new key")
	lu.assertEquals(H.getQuestStatus(other, "old:x"), "9", "other player's old key")
	lu.assertNil(H.getQuestStatus(other, "new:x"), "other player's new key")
end

-- AC-7, I-7
function TestMoveQuestStatuses:test_it_sends_no_message_music_or_event()
	local player = newPilot()

	H.setQuestStatus(player, "old:x", "1")

	local before = M.sideEffects(player)

	SpaceHelpers:moveQuestStatuses(player, { { old = "old:x", new = "new:x" } })
	noSideEffects(player, before, "moveQuestStatuses")
end

-- AC-7
function TestMoveQuestStatuses:test_a_nil_player_and_an_empty_list_are_ignored()
	local player = newPilot()

	H.setQuestStatus(player, "k", "1")
	SpaceHelpers:moveQuestStatuses(nil, { { old = "k", new = "j" } })
	SpaceHelpers:moveQuestStatuses(player, {})

	lu.assertEquals(H.getQuestStatus(player, "k"), "1", "key after a nil-player call and an empty list")
end

---------------------------------------------------------------------------------------------
-- AC-8: runProgressMigrations
---------------------------------------------------------------------------------------------

TestRunProgressMigrations = {}

local SP = "ScratchMigrationScreenplay"
local MARKER = SP .. ":legacyVersion"

-- A scratch screenplay whose steps record (name, marker at call time, self, player)
local function installScratch(log)
	local sp = {}

	for _, name in ipairs({ "stepOne", "stepTwo" }) do
		sp[name] = function(self, pPlayer)
			log[#log + 1] = { name = name, marker = H.getQuestStatus(pPlayer, MARKER), self = self, player = pPlayer }
		end
	end

	rawset(_G, SP, sp)
	return sp
end

function TestRunProgressMigrations:setUp()
	H.reset()
	needs("runProgressMigrations")
end

function TestRunProgressMigrations:tearDown() rawset(_G, SP, nil) end

-- AC-8
function TestRunProgressMigrations:test_with_no_marker_it_runs_every_step_in_order_and_sets_the_marker_after_each()
	local log, player = {}, newPilot()
	local sp = installScratch(log)
	local n = SpaceHelpers:runProgressMigrations(player, SP, { "stepOne", "stepTwo" })
	local names, markers = {}, {}

	for i, e in ipairs(log) do
		names[i], markers[i] = e.name, tostring(e.marker)
	end

	lu.assertEquals(n, 2, "return value")
	lu.assertEquals(names, { "stepOne", "stepTwo" }, "steps run, in order")
	lu.assertEquals(markers, { "nil", "1" }, "marker value seen by step 1, step 2 (set after step 1)")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "2", "marker at the end")
	lu.assertIs(log[1].self, sp, "step 1 self")
	lu.assertIs(log[1].player, player, "step 1 player")
end

-- AC-8
function TestRunProgressMigrations:test_with_the_marker_at_1_and_two_steps_it_runs_only_step_2()
	local log, player = {}, newPilot()

	installScratch(log)
	H.setQuestStatus(player, MARKER, "1")

	lu.assertEquals(SpaceHelpers:runProgressMigrations(player, SP, { "stepOne", "stepTwo" }), 1, "return value")
	lu.assertEquals(#log, 1, "steps run")
	lu.assertEquals(log[1].name, "stepTwo", "the step that ran")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "2", "marker")
end

-- AC-8
function TestRunProgressMigrations:test_with_the_marker_at_or_above_the_step_count_it_runs_nothing_and_keeps_the_marker()
	for _, marker in ipairs({ "2", "5" }) do
		H.reset()

		local log, player = {}, newPilot()

		installScratch(log)
		H.setQuestStatus(player, MARKER, marker)

		lu.assertEquals(SpaceHelpers:runProgressMigrations(player, SP, { "stepOne", "stepTwo" }), 0, "marker " .. marker .. ": return value")
		lu.assertEquals(#log, 0, "marker " .. marker .. ": steps run")
		lu.assertEquals(H.getQuestStatus(player, MARKER), marker, "marker " .. marker .. ": marker after")
	end
end

-- AC-8
function TestRunProgressMigrations:test_a_non_numeric_marker_counts_as_zero()
	local log, player = {}, newPilot()

	installScratch(log)
	H.setQuestStatus(player, MARKER, "abc")

	lu.assertEquals(SpaceHelpers:runProgressMigrations(player, SP, { "stepOne", "stepTwo" }), 2, "return value")
	lu.assertEquals(#log, 2, "steps run")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "2", "marker")
end

-- AC-8
function TestRunProgressMigrations:test_a_nil_player_or_a_creature_without_a_ghost_runs_nothing_and_writes_nothing()
	local log = {}

	installScratch(log)
	lu.assertEquals(SpaceHelpers:runProgressMigrations(nil, SP, { "stepOne", "stepTwo" }), 0, "nil player: return value")

	local npc = H.newNpc({ name = "Trainer" })

	lu.assertEquals(SpaceHelpers:runProgressMigrations(npc, SP, { "stepOne", "stepTwo" }), 0, "no ghost: return value")
	lu.assertEquals(#log, 0, "steps run")
	lu.assertNil(H.getQuestStatus(npc, MARKER), "marker of the ghostless creature")
end

-- AC-8
function TestRunProgressMigrations:test_an_empty_step_list_runs_nothing_and_writes_no_marker()
	local log, player = {}, newPilot()

	installScratch(log)
	lu.assertEquals(SpaceHelpers:runProgressMigrations(player, SP, {}), 0, "return value")
	lu.assertNil(H.getQuestStatus(player, MARKER), "marker")
end

-- AC-8, I-8: the marker is per player
function TestRunProgressMigrations:test_the_marker_belongs_to_the_player()
	local log, a, b = {}, newPilot(), newPilot()

	installScratch(log)
	SpaceHelpers:runProgressMigrations(a, SP, { "stepOne" })

	lu.assertEquals(SpaceHelpers:runProgressMigrations(b, SP, { "stepOne" }), 1, "second player's run")
	lu.assertEquals(SpaceHelpers:runProgressMigrations(a, SP, { "stepOne" }), 0, "first player's second run")
	lu.assertEquals(#log, 2, "steps run in total")
end
