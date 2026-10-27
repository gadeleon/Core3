-- Havoc tier 3 quest name case (havoc-tier3-quest-name-case): migration step 1, run from Aqzow's getInitialScreen, and the surrender purge.
-- Spec: .claude/work/havoc-tier3-quest-name-case/01-spec.md (Migration table M1-M6, Conversation flow, AC-6 to AC-9, I-5, D-3, D-4, D-8).
--
-- Legacy state is built by hand (journal entries, datapad missions, persistent observers, waypoint keys): the legacy quest table
-- `patrol_corellia_rebel_tier3_1_A` no longer exists, which is the point of the migration. The pilot comes from the trainer-fixes builder
-- (trainer_fixes_data.lua, T.TRAINERS.aqzow) and the checks read the fakes (migration_scenario.lua).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")
local Fakes = require("harness.fakes")

T.load()

local tr = T.TRAINERS.aqzow
local MARKER = "HavocSquadronScreenplay:legacyVersion"
local OLD = { "patrol", "corellia_rebel_tier3_1_A" }
local NEW = { "patrol", "corellia_rebel_tier3_1_a" }

local function state(player, q) return M.state(player, q[1], q[2]) end

local function assertState(player, q, want, msg) lu.assertEquals(state(player, q), want, (msg or "") .. q[1] .. "/" .. q[2] .. ": journal state") end

local function assertLegacyClean(player, msg)
	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]), M.clean(), (msg or "") .. "patrol/" .. OLD[2] .. ": leftovers (journal, datapad mission, observers, waypoint key, waypoint)")
end

-- A missing function or global is a clean red: one readable failure instead of "attempt to call a nil value"
local function needsMigration()
	for _, name in ipairs({ "migrateLegacyProgress", "migrateLegacyTier3" }) do
		lu.assertEquals(type(HavocSquadronScreenplay[name]), "function", "HavocSquadronScreenplay:" .. name .. " must be defined")
	end

	H.expectGlobal("patrol_corellia_rebel_tier3_1_a", "the renamed patrol")
end

local function migrate(player) return HavocSquadronScreenplay:migrateLegacyProgress(player) end

-- A mission 1 pilot of Aqzow (:attempted set, like a pilot who accepted mission 1); opts as T.player
local function pilot(opts) return T.player(tr, 1, opts or {}) end

-- A pilot who won and was paid for all four missions, with the patrol entry under the legacy name only
local function legacyVeteran()
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })
	local crc = M.crc(NEW[1], NEW[2])

	player.ghost.journalComplete[crc] = nil
	M.finish(player, OLD[1], OLD[2])
	return player
end

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Aqzow shows a first screen")
	return transcript[1].id
end

-- A complete legacy entry that also has a persistent observer, a waypoint and its key (what a finished run may leave behind)
local function withLegacyTrace(player)
	M.finish(player, OLD[1], OLD[2])
	createObserver(ZONESWITCHED, M.className(OLD[1], OLD[2]), "enteredZone", player, 1)

	local id = player.ghost:addWaypoint("space_lok", M.className(OLD[1], OLD[2]), "", 1, 2, 3, 0, true, true, 0)

	H.setQuestStatus(player, ":" .. M.className(OLD[1], OLD[2]) .. ":waypointID", id)
	return player
end

local function markerKey(player) return player.objectID .. MARKER end

local function without(t, key)
	local out = {}

	for k, v in pairs(t) do
		if k ~= key then
			out[k] = v
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-6: veterans (M1, M5)
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseMigration = {}

function TestHavocTier3NameCaseMigration:setUp()
	H.reset()
	needsMigration()
end

-- AC-6 (M1)
function TestHavocTier3NameCaseMigration:test_m1_a_veteran_with_the_upper_case_patrol_complete_gets_the_lower_case_patrol_complete()
	local player = legacyVeteran()

	lu.assertEquals(state(player, OLD), "complete", "setup: legacy entry")
	lu.assertEquals(state(player, NEW), "none", "setup: no new entry")
	firstScreen(player)
	assertState(player, NEW, "complete")
	assertLegacyClean(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "1", "marker")
end

-- AC-6 (M1): the screen is the one a pilot with the lower-case entry from the start gets
function TestHavocTier3NameCaseMigration:test_m1_the_veteran_gets_the_screen_a_pilot_with_the_lower_case_entry_from_the_start_gets()
	local control = T.player(tr, 4, { win = { 1, 2, 3, 4 } })
	local want = firstScreen(control)

	H.reset()

	local veteran = legacyVeteran()

	lu.assertEquals(firstScreen(veteran), want, "first screen of the migrated veteran")
end

-- AC-6 (M1): silent
function TestHavocTier3NameCaseMigration:test_m1_the_migration_sends_no_message_plays_no_music_and_creates_no_event()
	local player = legacyVeteran()
	local before = M.sideEffects(player)

	migrate(player)
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	assertState(player, NEW, "complete")
end

-- AC-6 (M1): rewards and :attempted keys are head-keyed and untouched
function TestHavocTier3NameCaseMigration:test_m1_the_reward_and_attempted_keys_are_neither_read_nor_changed()
	local player = legacyVeteran()
	local before = M.snapshot(player)

	migrate(player)

	local after = M.snapshot(player)
	local status = without(after.status, markerKey(player))

	lu.assertEquals(status, before.status, "quest status keys other than the marker")
	lu.assertEquals(after.status[markerKey(player)], "1", "marker")
end

-- AC-6 (M1): a completed _A with a leftover observer and waypoint is purged too
function TestHavocTier3NameCaseMigration:test_m1_a_completed_legacy_entry_with_an_observer_and_a_waypoint_key_is_purged_whole()
	local player = withLegacyTrace(pilot())

	lu.assertEquals(M.leftovers(player, OLD[1], OLD[2]).observers, { "ZONESWITCHED" }, "setup: legacy observer")
	migrate(player)
	assertLegacyClean(player)
	assertState(player, NEW, "complete")
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")
end

-- AC-6 (M5): no legacy state
function TestHavocTier3NameCaseMigration:test_m5_a_pilot_with_no_legacy_state_only_gets_the_marker()
	local player = pilot()
	local before = M.snapshot(player)
	local effects = M.sideEffects(player)

	lu.assertEquals(migrate(player), 1, "steps run")

	local after = M.snapshot(player)

	lu.assertEquals(after.status[markerKey(player)], "1", "marker")
	lu.assertEquals(without(after.status, markerKey(player)), before.status, "quest status keys other than the marker")
	lu.assertEquals(after.active, before.active, "active journal")
	lu.assertEquals(after.complete, before.complete, "completed journal")
	lu.assertEquals(after.observers, before.observers, "observers")
	lu.assertEquals(after.waypoints, before.waypoints, "waypoints")
	lu.assertEquals(after.datapad, before.datapad, "datapad")
	lu.assertEquals(M.sideEffects(player), effects, "messages, music, events")
end

-- AC-6 (M5): the same through Aqzow's first screen
function TestHavocTier3NameCaseMigration:test_m5_aqzows_first_screen_sets_the_marker_for_a_new_pilot()
	local player = pilot()

	lu.assertNil(H.getQuestStatus(player, MARKER), "setup: no marker")
	firstScreen(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "1", "marker after the first screen")
end

---------------------------------------------------------------------------------------------
-- AC-7: stale run (M2)
---------------------------------------------------------------------------------------------

-- AC-7 (M2)
function TestHavocTier3NameCaseMigration:test_m2_a_stale_upper_case_patrol_run_is_purged_and_mission_1_shows_failed_quest1()
	local player = pilot()

	M.startRun(player, OLD[1], OLD[2])

	local l = M.leftovers(player, OLD[1], OLD[2])

	lu.assertEquals(l.journal, "active", "setup: journal")
	lu.assertEquals(l.missions, 1, "setup: datapad mission")
	lu.assertEquals(l.observers, { "ZONESWITCHED" }, "setup: observer")
	lu.assertNotNil(l.waypointKey, "setup: waypoint key")
	lu.assertTrue(l.waypoint, "setup: waypoint")

	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_tier3_1:attempted"), "1", "setup: mission 1 :attempted")
	lu.assertEquals(firstScreen(player), "failed_quest1", "first screen (a stale run does not count as a running mission)")
	assertLegacyClean(player)
	assertState(player, NEW, "none")
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "1", "marker")
end

-- AC-7 (M2): the datapad mission is failed through the quest CRC, as the abort path does
function TestHavocTier3NameCaseMigration:test_m2_the_stale_datapad_mission_is_failed_by_its_crc()
	local player = pilot()

	M.startRun(player, OLD[1], OLD[2])
	migrate(player)

	local failed = false

	for _, crc in ipairs(player.failedMissions) do
		failed = failed or crc == M.crc(OLD[1], OLD[2])
	end

	lu.assertTrue(failed, "failedMissions holds the stale run's CRC")
	lu.assertEquals(M.missions(player, OLD[1], OLD[2]), 0, "datapad missions of the stale run")
end

-- AC-7 (M2): silent
function TestHavocTier3NameCaseMigration:test_m2_purging_a_stale_run_plays_no_music_and_sends_no_message()
	local player = pilot()

	M.startRun(player, OLD[1], OLD[2])

	local before = M.sideEffects(player)

	migrate(player)

	local after = M.sideEffects(player)

	lu.assertEquals(after.music, before.music, "music")
	lu.assertEquals(after.messages, before.messages, "messages")
end

---------------------------------------------------------------------------------------------
-- AC-8: collisions (M3, M4) and idempotence (M6)
---------------------------------------------------------------------------------------------

-- AC-8 (M3)
function TestHavocTier3NameCaseMigration:test_m3_with_both_entries_complete_the_upper_case_one_is_purged_and_nothing_is_written()
	local player = pilot()

	M.finish(player, NEW[1], NEW[2])
	M.finish(player, OLD[1], OLD[2])

	local completions = H.spyOn(player.ghost, "completeJournalQuest")

	migrate(player)
	assertState(player, NEW, "complete")
	assertLegacyClean(player)
	lu.assertEquals(#completions, 0, "completeJournalQuest calls (the new entry is already complete)")
end

-- AC-8 (M4)
function TestHavocTier3NameCaseMigration:test_m4_a_live_lower_case_run_is_left_alone_when_the_upper_case_entry_is_complete()
	local player = pilot()

	M.startRun(player, NEW[1], NEW[2])
	M.finish(player, OLD[1], OLD[2])

	local liveBefore = M.leftovers(player, NEW[1], NEW[2])
	local completions = H.spyOn(player.ghost, "completeJournalQuest")

	lu.assertEquals(liveBefore.journal, "active", "setup: live run")
	migrate(player)
	lu.assertEquals(M.leftovers(player, NEW[1], NEW[2]), liveBefore, "patrol/" .. NEW[2] .. ": entry, datapad mission, observer, waypoint key and waypoint")
	assertLegacyClean(player)
	lu.assertEquals(#completions, 0, "completeJournalQuest calls (no completion is written over a live run)")
end

-- AC-8 (M6)
function TestHavocTier3NameCaseMigration:test_m6_a_second_first_screen_returns_the_same_screen_and_the_migration_runs_nothing_more()
	local player = legacyVeteran()
	local first = firstScreen(player)
	local after = M.snapshot(player)

	lu.assertEquals(firstScreen(player), first, "second first screen")
	lu.assertEquals(migrate(player), 0, "steps run by a second call")
	lu.assertEquals(M.snapshot(player), after, "state after the second visit")
end

-- AC-8 (M6): the marker makes a later, reappearing _A entry untouchable
function TestHavocTier3NameCaseMigration:test_m6_an_upper_case_entry_planted_after_the_first_run_is_left_as_planted()
	local player = pilot()

	firstScreen(player)
	M.finish(player, OLD[1], OLD[2])

	local planted = M.snapshot(player)

	lu.assertEquals(migrate(player), 0, "steps run")
	firstScreen(player)
	assertState(player, OLD, "complete", "planted: ")
	assertState(player, NEW, "none", "planted: ")
	lu.assertEquals(M.snapshot(player).complete, planted.complete, "completed journal after another visit")
end

-- AC-8 (M6): with the marker at 1 nothing is read or written, whatever the legacy state
function TestHavocTier3NameCaseMigration:test_m6_with_the_marker_set_the_migration_changes_nothing_at_all()
	local player = withLegacyTrace(pilot({ questStatus = { [MARKER] = "1" } }))
	local before = M.snapshot(player)
	local effects = M.sideEffects(player)

	lu.assertEquals(migrate(player), 0, "steps run")
	lu.assertEquals(M.snapshot(player), before, "state")
	lu.assertEquals(M.sideEffects(player), effects, "side effects")
end

-- I-5: running twice leaves the same state as running once
function TestHavocTier3NameCaseMigration:test_i5_running_the_migration_twice_equals_running_it_once()
	local once = legacyVeteran()

	migrate(once)

	local want = M.snapshot(once)

	H.reset()

	local twice = legacyVeteran()

	migrate(twice)
	migrate(twice)
	lu.assertEquals(M.snapshot(twice), want, "state after two runs")
end

-- Migration: unchanged chain members are never touched
function TestHavocTier3NameCaseMigration:test_the_other_chain_members_keep_their_journal_state()
	local player = pilot()
	local others = { { "recovery", "corellia_rebel_tier3_1" }, { "destroy_surpriseattack", "corellia_rebel_tier3_1_b" }, { "assassinate", "corellia_rebel_tier3_1_c" }, { "space_battle", "corellia_rebel_tier3_1_d" } }

	M.finish(player, others[1][1], others[1][2])
	M.finish(player, others[3][1], others[3][2])
	M.finish(player, OLD[1], OLD[2])
	migrate(player)

	lu.assertEquals({ state(player, others[1]), state(player, others[2]), state(player, others[3]), state(player, others[4]) },
		{ "complete", "none", "complete", "none" }, "journal state of recovery, _b, _c, _d")
end

---------------------------------------------------------------------------------------------
-- AC-9: surrender
---------------------------------------------------------------------------------------------

TestHavocTier3NameCaseSurrender = {}

function TestHavocTier3NameCaseSurrender:setUp()
	H.reset()
	H.expectGlobal("patrol_corellia_rebel_tier3_1_a", "the renamed patrol")
end

local function assertAqzowClean(player, label)
	for n = 1, 4 do
		for _, global in ipairs(tr.chains[n]) do
			lu.assertEquals(T.state(player, global), "none", label .. global .. ": journal state")
		end
	end

	assertLegacyClean(player, label)
end

local function veteranWithLegacyTrace(marker)
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 }, questStatus = marker and { [MARKER] = marker } or nil })

	player.ghost.journalComplete[M.crc(NEW[1], NEW[2])] = nil
	return withLegacyTrace(player)
end

-- AC-9
function TestHavocTier3NameCaseSurrender:test_reset_aqzow_quests_clears_the_lower_case_patrol_and_purges_every_trace_of_the_upper_case_one()
	for _, marker in ipairs({ "none", "1" }) do
		H.reset()

		local player = veteranWithLegacyTrace(marker ~= "none" and marker or nil)

		lu.assertEquals(state(player, OLD), "complete", "setup (marker " .. marker .. "): legacy entry")
		HavocSquadronScreenplay:resetAqzowQuests(player)
		assertAqzowClean(player, "marker " .. marker .. ": ")
		lu.assertEquals(#player.ghost.waypoints, 0, "marker " .. marker .. ": waypoints left")
	end
end

-- AC-9: the new name goes through TIER3_QUEST_STRING_1_SIDE1
function TestHavocTier3NameCaseSurrender:test_reset_aqzow_quests_clears_a_completed_lower_case_patrol_entry()
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })

	assertState(player, NEW, "complete", "setup: ")
	HavocSquadronScreenplay:resetAqzowQuests(player)
	assertState(player, NEW, "none")
end

-- AC-9: a run that never finished
function TestHavocTier3NameCaseSurrender:test_reset_aqzow_quests_removes_a_stale_upper_case_run_with_its_datapad_mission_observer_and_waypoint()
	local player = pilot()

	M.startRun(player, OLD[1], OLD[2])
	HavocSquadronScreenplay:resetAqzowQuests(player)
	assertLegacyClean(player)
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")
end

-- AC-9, D-4: the marker is not touched, set or not
function TestHavocTier3NameCaseSurrender:test_reset_aqzow_quests_leaves_the_marker_alone()
	local withMarker = veteranWithLegacyTrace("1")
	local without = veteranWithLegacyTrace(nil)

	HavocSquadronScreenplay:resetAqzowQuests(withMarker)
	HavocSquadronScreenplay:resetAqzowQuests(without)
	lu.assertEquals(H.getQuestStatus(withMarker, MARKER), "1", "marker that was set")
	lu.assertNil(H.getQuestStatus(without, MARKER), "marker that was not set")
end

-- AC-9
function TestHavocTier3NameCaseSurrender:test_surrender_pilot_does_the_same_for_a_havoc_pilot()
	local player = veteranWithLegacyTrace("1")

	player.ghost:setSquadronType(rawget(_G, "HAVOC_SQUADRON"))
	SpaceHelpers:surrenderPilot(player)
	assertAqzowClean(player, "surrenderPilot: ")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "1", "marker")
end

-- AC-9: a surrendered pilot who rejoins starts clean and is paid nothing
function TestHavocTier3NameCaseSurrender:test_a_rejoined_pilot_is_paid_nothing_and_nothing_is_started()
	local player = veteranWithLegacyTrace("1")

	HavocSquadronScreenplay:resetAqzowQuests(player)

	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "first screen exists")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls after the reset (first screen '" .. tostring(transcript[1].id) .. "')")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end
