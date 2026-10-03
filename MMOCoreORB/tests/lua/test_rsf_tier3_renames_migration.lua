-- RSF tier 3 renames (F2): migration step 1, run from Dulios's getInitialScreen.
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-9, table M rows M1-M8, Conversation flow, Migration,
-- invariants I-7, I-8, I-9, D-3, D-5, D-6).
--
-- Legacy state is built by hand (journal entries, datapad missions, persistent observers, waypoint keys, status keys),
-- because the legacy quest tables no longer exist: the point of the migration. The pilot comes from the trainer-fixes
-- builder (trainer_fixes_data.lua, T.TRAINERS.dulios); the checks read the fakes (migration_scenario.lua).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")
local Fakes = require("harness.fakes")

T.load()

local tr = T.TRAINERS.dulios
local MARKER = "RsfSquadronScreenplay:legacyVersion"

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local Q = {
	a3 = { "inspect", "naboo_privateer_tier3_3a" },
	oldDelivery = { "delivery", "naboo_privateer_tier3_3b" },
	dnp3b = { "delivery_no_pickup", "naboo_privateer_tier3_3b" },
	c3 = { "survival", "naboo_privateer_tier3_3c" },
	e3 = { "destroy_surpriseattack", "naboo_privateer_tier3_3e" },
	a4 = { "assassinate", "naboo_privateer_tier3_4a" },
	b4 = { "space_battle", "naboo_privateer_tier3_4b" },
	oldSurvival = { "survival", "naboo_privateer_tier3_4c" },
	n4c = { "destroy_surpriseattack", "naboo_privateer_tier3_4c" },
	n4d = { "destroy_surpriseattack", "naboo_privateer_tier3_4d" },
	n4e = { "destroy_surpriseattack", "naboo_privateer_tier3_4e" },
	f4 = { "assassinate", "naboo_privateer_tier3_4f" },
	oldInitial = { "destroy_surpriseattack", "naboo_privateer_tier3_4_initial" },
}

local NEW4 = { Q.n4c, Q.n4d, Q.n4e }
local LEGACY = { Q.oldDelivery, Q.oldSurvival, Q.oldInitial }

local function label(q) return q[1] .. "/" .. q[2] end

local function state(player, q) return M.state(player, q[1], q[2]) end

local function assertState(player, q, want, msg) lu.assertEquals(state(player, q), want, (msg or "") .. label(q) .. ": journal state") end

local function assertLegacyClean(player, msg)
	for _, q in ipairs(LEGACY) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), (msg or "") .. label(q) .. ": leftovers (journal, datapad mission, observers, waypoint key, waypoint)")
	end

	for _, key in ipairs({ "naboo_privateer_tier3_4_initial:attempted", "naboo_privateer_tier3_4_initial:reward" }) do
		lu.assertNil(H.getQuestStatus(player, key), (msg or "") .. key .. ": status key")
	end
end

-- A Dulios pilot of mission n (missions 1..n-1 won and rewarded). opts: complete (list of Q), runs (list of Q: active runs with
-- datapad mission, observer and waypoint), status (suffix -> value), attempted (default true = mission n's :attempted key
-- under the head's name, like the post-F2 handler), skills
local function pilot(n, opts)
	opts = opts or {}

	local player = T.player(tr, n, { attempted = opts.attempted, questStatus = opts.status, skills = opts.skills })

	for _, q in ipairs(opts.complete or {}) do
		M.finish(player, q[1], q[2])
	end

	for _, q in ipairs(opts.runs or {}) do
		M.startRun(player, q[1], q[2], { inspect = q[1] == "inspect" })
	end

	return player
end

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Dulios shows a first screen")
	return transcript[1].id
end

-- A missing function is a clean red: one readable failure instead of "attempt to call a nil value"
local function needsMigration()
	for _, name in ipairs({ "migrateLegacyProgress", "migrateLegacyTier3" }) do
		lu.assertEquals(type(RsfSquadronScreenplay[name]), "function", "RsfSquadronScreenplay:" .. name .. " must be defined")
	end
end

local function migrate(player) return RsfSquadronScreenplay:migrateLegacyProgress(player) end

-- Journal and status snapshot of the quests the step must never touch (unchanged names)
local function unchangedNames(player)
	local out = {}

	for _, q in ipairs({ Q.a3, Q.c3, Q.e3, Q.a4, Q.b4, Q.f4 }) do
		out[label(q)] = state(player, q)
	end

	return out
end

---------------------------------------------------------------------------------------------
-- Table M, one test per row
---------------------------------------------------------------------------------------------

TestRsfRenamesMigration = {}

function TestRsfRenamesMigration:setUp()
	H.reset()
	needsMigration()
end

-- AC-9 M1
function TestRsfRenamesMigration:test_m1_a_completed_legacy_delivery_becomes_a_completed_delivery_no_pickup()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery, Q.c3 } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission3", "first screen")
	assertState(player, Q.dnp3b, "complete")
	assertState(player, Q.a3, "complete")
	assertState(player, Q.c3, "complete")
	assertLegacyClean(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
	lu.assertEquals(rec.rewards, { g("inspect", "3a") }, "rewardPlayer calls (the win was never paid)")
end

-- AC-9 M1: completed and rewarded
function TestRsfRenamesMigration:test_m1_a_rewarded_veteran_of_mission_3_is_not_paid_again()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery, Q.c3 }, status = { ["naboo_privateer_tier3_3a:reward"] = "1" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission3", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	assertState(player, Q.dnp3b, "complete")
	assertLegacyClean(player)
end

-- AC-9 M2
function TestRsfRenamesMigration:test_m2_a_stale_legacy_delivery_run_is_purged_and_the_pilot_can_retry_mission_3()
	local player = pilot(3, { complete = { Q.a3 }, runs = { Q.oldDelivery } })
	local before = M.sideEffects(player)

	lu.assertEquals(M.leftovers(player, "delivery", "naboo_privateer_tier3_3b").journal, "active", "setup: stale run")
	lu.assertEquals(firstScreen(player), "failed_third_mission", "first screen (was on_mission)")
	assertState(player, Q.dnp3b, "none")
	assertLegacyClean(player)
	assertState(player, Q.a3, "complete")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
	lu.assertEquals(M.missions(player, "delivery", "naboo_privateer_tier3_3b"), 0, "datapad missions of the stale run")

	local failed = false

	for _, crc in ipairs(player.failedMissions) do
		failed = failed or crc == M.crc("delivery", "naboo_privateer_tier3_3b")
	end

	lu.assertTrue(failed, "failedMissions has the stale run's CRC")
	lu.assertEquals(M.sideEffects(player).music, before.music, "no music")
end

-- AC-9 M3
function TestRsfRenamesMigration:test_m3_a_completed_legacy_survival_4c_completes_4c_4d_and_4e()
	local player = pilot(4, { complete = { Q.a4, Q.b4, Q.oldSurvival, Q.f4 } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")

	for _, q in ipairs(NEW4) do
		assertState(player, q, "complete")
	end

	assertLegacyClean(player)
	assertState(player, Q.f4, "complete")
	lu.assertEquals(rec.rewards, { g("assassinate", "4a") }, "rewardPlayer calls")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "1", "4a:reward")
end

-- AC-9 M4
function TestRsfRenamesMigration:test_m4_a_stale_legacy_survival_4c_run_is_purged_and_writes_no_new_entry()
	local player = pilot(4, { complete = { Q.a4, Q.b4 }, runs = { Q.oldSurvival } })

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen (was on_mission)")

	for _, q in ipairs(NEW4) do
		assertState(player, q, "none")
	end

	assertLegacyClean(player)
	assertState(player, Q.a4, "complete")
	assertState(player, Q.b4, "complete")
end

-- AC-9 M5
function TestRsfRenamesMigration:test_m5_an_active_legacy_initial_surprise_attack_is_purged_and_its_status_keys_move()
	local player = pilot(4, { attempted = false, runs = { Q.oldInitial }, status = { ["naboo_privateer_tier3_4_initial:attempted"] = "1" } })

	lu.assertTrue(hasObserver(ZONESWITCHED, "destroy_surpriseattack_naboo_privateer_tier3_4_initial", "enteredZone", player), "setup: the legacy enteredZone observer")
	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen (was on_mission)")
	assertLegacyClean(player)
	lu.assertFalse(hasObserver(ZONESWITCHED, "destroy_surpriseattack_naboo_privateer_tier3_4_initial", "enteredZone", player), "the legacy enteredZone observer is dropped")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:attempted"), "1", "4a:attempted (moved from 4_initial:attempted)")
end

-- AC-9 M5
function TestRsfRenamesMigration:test_m5_a_completed_legacy_initial_surprise_attack_is_purged_and_completes_nothing()
	local player = pilot(4, { complete = { Q.oldInitial } })

	firstScreen(player)
	assertLegacyClean(player)

	for _, q in ipairs({ Q.a4, Q.b4, Q.n4c, Q.n4d, Q.n4e, Q.f4 }) do
		assertState(player, q, "none")
	end
end

-- AC-9 M6
function TestRsfRenamesMigration:test_m6_the_legacy_status_keys_are_copied_to_the_head_keys_and_removed()
	local player = pilot(4, { attempted = false, status = {
		["naboo_privateer_tier3_4_initial:attempted"] = "1",
		["naboo_privateer_tier3_4_initial:reward"] = "1",
	} })

	migrate(player)

	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:attempted"), "1", "4a:attempted")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "1", "4a:reward")
	assertLegacyClean(player)
end

-- AC-9 M6: an existing new key wins, the old key goes
function TestRsfRenamesMigration:test_m6_a_new_key_that_is_already_set_is_kept()
	local player = pilot(4, { attempted = false, status = {
		["naboo_privateer_tier3_4_initial:attempted"] = "1",
		["naboo_privateer_tier3_4_initial:reward"] = "1",
		["naboo_privateer_tier3_4a:reward"] = "7",
	} })

	migrate(player)

	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "7", "4a:reward keeps its value")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:attempted"), "1", "4a:attempted")
	assertLegacyClean(player)
end

-- AC-9 M7, D-5
function TestRsfRenamesMigration:test_m7_a_live_delivery_no_pickup_run_survives_a_completed_legacy_delivery()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery }, runs = { Q.dnp3b } })
	local live = M.leftovers(player, Q.dnp3b[1], Q.dnp3b[2])

	lu.assertEquals(live.journal, "active", "setup: live run")
	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
	lu.assertEquals(M.leftovers(player, Q.dnp3b[1], Q.dnp3b[2]), live, "the live run's journal, datapad mission, observer, waypoint key and waypoint")
	assertLegacyClean(player)
end

-- AC-9 M7, D-5: a live 4d blocks the completion of 4c and 4e
function TestRsfRenamesMigration:test_m7_a_live_4d_run_blocks_the_completion_of_the_legacy_4c_targets()
	local player = pilot(4, { complete = { Q.a4, Q.b4, Q.oldSurvival }, runs = { Q.n4d } })
	local live = M.leftovers(player, Q.n4d[1], Q.n4d[2])

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
	assertState(player, Q.n4c, "none")
	assertState(player, Q.n4e, "none")
	lu.assertEquals(M.leftovers(player, Q.n4d[1], Q.n4d[2]), live, "the live 4d run")
	assertLegacyClean(player)
end

-- AC-9 M7: a legacy active run next to a live new run
function TestRsfRenamesMigration:test_m7_a_stale_legacy_run_next_to_a_live_new_run_is_purged_alone()
	local player = pilot(4, { complete = { Q.a4, Q.b4 }, runs = { Q.oldSurvival, Q.n4c } })
	local live = M.leftovers(player, Q.n4c[1], Q.n4c[2])

	migrate(player)
	lu.assertEquals(M.leftovers(player, Q.n4c[1], Q.n4c[2]), live, "the live 4c run")
	assertLegacyClean(player)
end

-- AC-9 M8
function TestRsfRenamesMigration:test_m8_a_pilot_without_legacy_state_gets_only_the_marker()
	local player = pilot(1, { attempted = false })
	local snap = M.snapshot(player)
	local before = M.sideEffects(player)

	migrate(player)

	snap.status[player.objectID .. MARKER] = "3"
	lu.assertEquals(M.snapshot(player), snap, "journal, status keys, observers, waypoints, datapad and shared memory (plus the marker)")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9: the first screen of a never-started pilot is the mission 1 offer
function TestRsfRenamesMigration:test_m8_a_never_started_pilot_is_offered_mission_1_and_gets_the_marker()
	local player = pilot(1, { attempted = false })

	lu.assertEquals(firstScreen(player), "first_mission", "first screen")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

---------------------------------------------------------------------------------------------
-- Mid-chain states
---------------------------------------------------------------------------------------------

TestRsfRenamesMigrationMidChain = {}

function TestRsfRenamesMigrationMidChain:setUp()
	H.reset()
	needsMigration()
end

-- AC-9
function TestRsfRenamesMigrationMidChain:test_a_completed_legacy_delivery_with_3c_running_keeps_the_pilot_on_the_mission()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery }, runs = { Q.c3 } })
	local liveC3 = M.leftovers(player, Q.c3[1], Q.c3[2])

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
	assertState(player, Q.dnp3b, "complete")
	lu.assertEquals(M.leftovers(player, Q.c3[1], Q.c3[2]), liveC3, "survival 3c (unchanged name) is untouched")
	assertLegacyClean(player)
end

-- AC-9
function TestRsfRenamesMigrationMidChain:test_a_completed_legacy_4c_with_4f_running_keeps_the_pilot_on_the_mission()
	local player = pilot(4, { complete = { Q.a4, Q.b4, Q.oldSurvival }, runs = { Q.f4 } })
	local liveF4 = M.leftovers(player, Q.f4[1], Q.f4[2])

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")

	for _, q in ipairs(NEW4) do
		assertState(player, q, "complete")
	end

	lu.assertEquals(M.leftovers(player, Q.f4[1], Q.f4[2]), liveF4, "assassinate 4f (unchanged name) is untouched")
	assertLegacyClean(player)
end

-- AC-9: every legacy name active at once, each with its observer and waypoint
function TestRsfRenamesMigrationMidChain:test_every_legacy_name_active_at_once_is_purged_completely_without_message_music_or_event()
	local player = pilot(4, { attempted = false, runs = { Q.oldDelivery, Q.oldSurvival, Q.oldInitial }, status = { ["naboo_privateer_tier3_4_initial:attempted"] = "1" } })
	local before = M.sideEffects(player)

	migrate(player)

	assertLegacyClean(player)
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	for _, q in ipairs(LEGACY) do
		local failed = false

		for _, crc in ipairs(player.failedMissions) do
			failed = failed or crc == M.crc(q[1], q[2])
		end

		lu.assertTrue(failed, label(q) .. ": failedMissions has the CRC")
	end

	lu.assertEquals(#player.datapad.items, 0, "datapad missions left")
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")

	for _, q in ipairs(NEW4) do
		assertState(player, q, "none")
	end

	assertState(player, Q.dnp3b, "complete", "(won mission 3 in the setup) ")
end

---------------------------------------------------------------------------------------------
-- Veterans: no double reward, before and after the migration
---------------------------------------------------------------------------------------------

TestRsfRenamesMigrationRewards = {}

function TestRsfRenamesMigrationRewards:setUp()
	H.reset()
	needsMigration()
end

local function veteran4(status)
	return pilot(4, { attempted = false, complete = { Q.a4, Q.b4, Q.oldSurvival, Q.f4 }, status = status })
end

-- AC-9
function TestRsfRenamesMigrationRewards:test_a_veteran_with_the_legacy_reward_key_gets_the_win_screen_without_a_payment()
	local player = veteran4({ ["naboo_privateer_tier3_4_initial:attempted"] = "1", ["naboo_privateer_tier3_4_initial:reward"] = "1" })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "1", "4a:reward")
	assertLegacyClean(player)
end

-- AC-9
function TestRsfRenamesMigrationRewards:test_a_veteran_with_the_legacy_reward_key_is_not_paid_on_later_visits_either()
	local player = veteran4({ ["naboo_privateer_tier3_4_initial:reward"] = "1" })
	local rec = T.spyRewards()

	for visit = 1, 3 do
		lu.assertEquals(firstScreen(player), "complete_mission4", "visit " .. visit .. ": first screen")
	end

	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls over three visits")
end

-- AC-9
function TestRsfRenamesMigrationRewards:test_a_veteran_whose_win_was_never_paid_is_paid_once_over_two_visits()
	local player = veteran4({ ["naboo_privateer_tier3_4_initial:attempted"] = "1" })
	local rec = T.spyRewards()

	firstScreen(player)
	firstScreen(player)

	lu.assertEquals(rec.rewards, { g("assassinate", "4a") }, "rewardPlayer calls over two visits")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "1", "4a:reward")
end

-- AC-9: the win is checked against the new chain end (4f), not against 4e or the legacy entry
function TestRsfRenamesMigrationRewards:test_4a_to_4e_complete_without_4f_is_not_a_mission_4_win()
	local player = pilot(4, { attempted = false, complete = { Q.a4, Q.b4, Q.oldSurvival }, status = { ["naboo_privateer_tier3_4_initial:attempted"] = "1" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- Idempotence (I-8) and the marker
---------------------------------------------------------------------------------------------

TestRsfRenamesMigrationIdempotence = {}

function TestRsfRenamesMigrationIdempotence:setUp()
	H.reset()
	needsMigration()
end

local function allLegacyPilot()
	return pilot(4, { attempted = false, complete = { Q.a4, Q.b4, Q.f4 }, runs = { Q.oldDelivery }, status = {
		["naboo_privateer_tier3_4_initial:attempted"] = "1",
		["naboo_privateer_tier3_4_initial:reward"] = "1",
	} })
end

-- AC-9, I-8
function TestRsfRenamesMigrationIdempotence:test_a_second_migrate_legacy_progress_changes_nothing()
	local player = allLegacyPilot()

	M.finish(player, Q.oldSurvival[1], Q.oldSurvival[2])
	migrate(player)

	local snap, before = M.snapshot(player), M.sideEffects(player)

	lu.assertEquals(migrate(player), 0, "steps run the second time")
	lu.assertEquals(M.snapshot(player), snap, "state after the second run")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9, I-8: step 1 on its own is idempotent too, marker or not
function TestRsfRenamesMigrationIdempotence:test_running_the_step_twice_directly_changes_nothing_the_second_time()
	local player = allLegacyPilot()

	M.finish(player, Q.oldSurvival[1], Q.oldSurvival[2])
	RsfSquadronScreenplay:migrateLegacyTier3(player)

	local snap, before = M.snapshot(player), M.sideEffects(player)

	RsfSquadronScreenplay:migrateLegacyTier3(player)

	lu.assertEquals(M.snapshot(player), snap, "state after the second run")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
end

-- AC-9, I-8: three conversations in a row
function TestRsfRenamesMigrationIdempotence:test_a_second_conversation_shows_the_same_screen_and_changes_nothing()
	local player = allLegacyPilot()
	local rec = T.spyRewards()
	local first = firstScreen(player)
	local snap = M.snapshot(player)
	local second = firstScreen(player)

	lu.assertEquals(second, first, "first screen of the second conversation")
	lu.assertEquals(M.snapshot(player), snap, "state after the second conversation")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls (the legacy reward key moved with the pilot)")
end

-- AC-9: the marker gates the step
function TestRsfRenamesMigrationIdempotence:test_with_the_marker_already_set_the_step_does_not_run()
	local player = pilot(3, { complete = { Q.a3 }, runs = { Q.oldDelivery } })

	H.setQuestStatus(player, MARKER, "3")

	local snap = M.snapshot(player)

	lu.assertEquals(migrate(player), 0, "steps run")
	lu.assertEquals(M.snapshot(player), snap, "state")
end

-- AC-9: the marker is per character
function TestRsfRenamesMigrationIdempotence:test_a_second_pilot_is_migrated_after_the_first_one_was()
	local first, second = pilot(3, { complete = { Q.a3, Q.oldDelivery } }), pilot(3, { complete = { Q.a3, Q.oldDelivery } })

	migrate(first)
	lu.assertEquals(migrate(second), 3, "steps run for the second pilot (all three)")
	assertState(second, Q.dnp3b, "complete")
end

---------------------------------------------------------------------------------------------
-- Where the migration runs (D-6) and in what order
---------------------------------------------------------------------------------------------

TestRsfRenamesMigrationPlacement = {}

local restore = {}

local function wrap(obj, name, tag, log)
	local original = obj[name]

	assert(original ~= nil, "cannot wrap missing " .. tag)
	restore[#restore + 1] = { obj = obj, name = name, value = rawget(obj, name) }
	obj[name] = function(self, ...)
		log[#log + 1] = tag
		return original(self, ...)
	end
end

function TestRsfRenamesMigrationPlacement:setUp()
	H.reset()
	needsMigration()
end

function TestRsfRenamesMigrationPlacement:tearDown()
	for i = #restore, 1, -1 do
		restore[i].obj[restore[i].name] = restore[i].value
	end

	restore = {}
end

-- AC-9: migrateLegacyTier3 runs before any journal read of getInitialScreen
function TestRsfRenamesMigrationPlacement:test_the_step_runs_before_any_journal_read_of_the_first_screen()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery } })
	local log = {}

	lu.assertEquals(type(RsfSquadronScreenplay.migrateLegacyTier3), "function", "RsfSquadronScreenplay:migrateLegacyTier3 is defined")

	local step = RsfSquadronScreenplay.migrateLegacyTier3

	restore[#restore + 1] = { obj = RsfSquadronScreenplay, name = "migrateLegacyTier3", value = rawget(RsfSquadronScreenplay, "migrateLegacyTier3") }
	RsfSquadronScreenplay.migrateLegacyTier3 = function(self, ...)
		log[#log + 1] = "migrate:begin"

		local result = step(self, ...)

		log[#log + 1] = "migrate:end"
		return result
	end

	for _, name in ipairs({ "isSpaceQuestActive", "isSpaceQuestComplete", "isSpaceQuestChainActive", "getPilotTierSkillCount", "hasCompletedPilotTier" }) do
		wrap(SpaceHelpers, name, "read:" .. name, log)
	end

	for _, name in ipairs({ "isJournalQuestActive", "isJournalQuestComplete" }) do
		wrap(player.ghost, name, "ghost:" .. name, log)
	end

	firstScreen(player)

	lu.assertEquals(log[1], "migrate:begin", "the first recorded event of the conversation")

	local ended = false

	for _, tag in ipairs(log) do
		ended = ended or tag == "migrate:end"
	end

	lu.assertTrue(ended, "the step finished before the conversation went on")
end

-- AC-9, D-6: before the JTL and squadron checks
function TestRsfRenamesMigrationPlacement:test_it_runs_for_a_player_who_gets_the_not_pilot_screen_because_jtl_is_off()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery } })

	H.Engine.config.jtlEnabled = false
	-- rsf-tier3-dulios-convo (Superseded, E-5): JTL off shows not_pilot (SWG's first gate), no longer not_tier3
	lu.assertEquals(firstScreen(player), "not_pilot", "first screen")
	assertState(player, Q.dnp3b, "complete")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
	H.Engine.config.jtlEnabled = true
end

-- AC-9, D-6
function TestRsfRenamesMigrationPlacement:test_it_runs_for_a_pilot_of_another_squadron()
	local player = pilot(3, { complete = { Q.a3, Q.oldDelivery } })

	player.ghost:setSquadronType(rawget(_G, "CORSEC_SQUADRON"))
	lu.assertEquals(firstScreen(player), "pilot_not_rsf", "first screen")
	assertState(player, Q.dnp3b, "complete")
	assertLegacyClean(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- The nil check stays first: no player, no npc or no template means no screen and no migration
function TestRsfRenamesMigrationPlacement:test_a_missing_player_npc_or_template_still_returns_nil()
	local tmpl = H.conversationTemplate(tr.template)
	local handler = H.expectGlobal("duliosConvoHandler", "Dulios conversation handler")

	lu.assertNil(handler:getInitialScreen(nil, H.newNpc({}), tmpl), "nil player")
	lu.assertNil(handler:getInitialScreen(pilot(1), nil, tmpl), "nil npc")
	lu.assertNil(handler:getInitialScreen(pilot(1), H.newNpc({}), nil), "nil template")
end

---------------------------------------------------------------------------------------------
-- A pending SC-1 run (a surprise attack started on the ground) survives the migration
---------------------------------------------------------------------------------------------

TestRsfRenamesMigrationPendingRun = {}

function TestRsfRenamesMigrationPendingRun:setUp()
	H.reset()
	needsMigration()
end

-- AC-9, SC-1: the run's journal entry and pending marker are not touched, and it still spawns on arrival
function TestRsfRenamesMigrationPendingRun:test_a_pending_4c_run_next_to_a_completed_legacy_4c_still_spawns_after_the_migration()
	local player = pilot(4, { complete = { Q.a4, Q.b4, Q.oldSurvival } })

	player.zone = "space_naboo"
	player.rootParent = Fakes.newContainer({ objectName = "starport" })
	_G[g("destroy_surpriseattack", "4c")]:startQuest(player, "")

	lu.assertEquals(state(player, Q.n4c), "active", "setup: 4c is active and pending")
	lu.assertEquals(#H.Engine.callsTo("spawnShipAgent"), 0, "setup: nothing spawned on the ground")

	local memory = H.Engine.sharedMemoryKeys()
	local live = M.leftovers(player, Q.n4c[1], Q.n4c[2])

	migrate(player)
	lu.assertEquals(H.Engine.sharedMemoryKeys(), memory, "shared memory keys (the pending marker)")
	lu.assertEquals(M.leftovers(player, Q.n4c[1], Q.n4c[2]), live, "the pending run's journal, datapad mission, observer and waypoint")
	assertState(player, Q.n4d, "none")
	assertState(player, Q.n4e, "none")
	assertLegacyClean(player)

	H.zoneSwitch(player, "space_lok", { ship = true })
	H.advance(1000)

	local ships = {}

	for i, c in ipairs(H.Engine.callsTo("spawnShipAgent")) do
		ships[i] = c[1]
	end

	lu.assertEquals(ships, { "blacksun_marauder_tier3", "blacksun_marauder_tier3", "blacksun_marauder_tier3" }, "ships spawned 1000 ms after arriving in Lok")
end
