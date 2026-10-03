-- RSF tier 2 progress migration (step 2), run from Kaydine's getInitialScreen and, through the shared runner, from Dulios's.
-- Spec: .claude/work/rsf-tier2-kaydine-missions/01-spec.md (AC-8, AC-9, Migration table M2 rows T1-T10, Conversation flow,
-- invariants I-8, I-9, I-10, D-2, D-7, D-13, R-3).
--
-- Progress moves by mission position (D-13): the old destroy 13a, escort 14, inspect 15 and assassinate tier2_4a become the
-- assassination trio 1a-1c, destroy 13, recovery 14 and escort 15. The status keys of old 14 and 15 are also the names of the
-- new missions 3 and 4, so the eight keys move in ONE batch (read all, remove all, then write).
--
-- Legacy state is built by hand (journal entries, datapad missions, persistent observers, waypoint keys, status keys), because
-- the legacy quest tables no longer exist. The pilot comes from the trainer-fixes builder (trainer_fixes_data.lua); the checks
-- read the fakes (migration_scenario.lua).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")

T.load()

local kay = T.TRAINERS.kaydine
local dul = T.TRAINERS.dulios
local MARKER = "RsfSquadronScreenplay:legacyVersion"

local SKILLS_02 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }

-- Legacy quest of each mission position and the status key base it used
local LEG = {
	{ "destroy", "naboo_privateer_13a" },
	{ "escort", "naboo_privateer_14" },
	{ "inspect", "naboo_privateer_15" },
	{ "assassinate", "naboo_privateer_tier2_4a" },
}

local LEGKEY = { "naboo_privateer_13a", "naboo_privateer_14", "naboo_privateer_15", "naboo_privateer_tier2_4a" }

-- New quests of each mission position and the status key base they use
local NEW = {
	{ { "assassinate", "naboo_privateer_tier2_1a" }, { "assassinate", "naboo_privateer_tier2_1b" }, { "assassinate", "naboo_privateer_tier2_1c" } },
	{ { "destroy", "naboo_privateer_13" } },
	{ { "recovery", "naboo_privateer_14" } },
	{ { "escort", "naboo_privateer_15" } },
}

local NEWKEY = { "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }
local HEADS = { "assassinate_naboo_privateer_tier2_1a", "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15" }

-- The eight status moves of the spec: old suffix -> new suffix
local SHIFT = {
	{ "naboo_privateer_13a:attempted", "naboo_privateer_tier2_1a:attempted" },
	{ "naboo_privateer_13a:reward", "naboo_privateer_tier2_1a:reward" },
	{ "naboo_privateer_14:attempted", "naboo_privateer_13:attempted" },
	{ "naboo_privateer_14:reward", "naboo_privateer_13:reward" },
	{ "naboo_privateer_15:attempted", "naboo_privateer_14:attempted" },
	{ "naboo_privateer_15:reward", "naboo_privateer_14:reward" },
	{ "naboo_privateer_tier2_4a:attempted", "naboo_privateer_15:attempted" },
	{ "naboo_privateer_tier2_4a:reward", "naboo_privateer_15:reward" },
}

-- Every status suffix the step reads or writes
local ALL_KEYS = {}

for _, m in ipairs(SHIFT) do
	ALL_KEYS[m[1]] = true
	ALL_KEYS[m[2]] = true
end

-- rsf-tier2-kaydine-convo: SWG's story dialogue under Imler-style ids. Mission 2 is paid by its first screen (PENDING[2] is also its
-- pay screen), so a pending mission 2 pays when it is shown; the failed screens re-grant the mission (D-14).
local OFFER = { "mission1_ready", "mission2_ready", "mission3_ready", "mission4_ready" }
local FAILED = { "mission1_failed", "mission2_failed", "mission3_failed", "mission4_failed" }
local PENDING = { "mission1_complete", "mission2_reward", "mission3_complete", "mission4_complete" }
local AFTER_PAID = { "mission2_ready", "mission3_ready", "mission4_ready", "here_for_work" }
local PAY_SCREEN = { "mission1_reward", "mission2_reward", "mission3_reward", "mission4_reward" }

-- Tier 3 legacy of step 1 (F2): the completed legacy delivery 3b and the 4_initial status keys
local OLD3 = { "delivery", "naboo_privateer_tier3_3b" }
local NEW3 = { "delivery_no_pickup", "naboo_privateer_tier3_3b" }

local function label(q) return q[1] .. "/" .. q[2] end

local function state(player, q) return M.state(player, q[1], q[2]) end

local function setMarker(player, value)
	if value == nil then
		removeQuestStatus(player.objectID .. MARKER)
	else
		H.setQuestStatus(player, MARKER, value)
	end
end

-- A missing function is a clean red: one readable failure instead of "attempt to call a nil value"
local function needsMigration()
	for _, name in ipairs({ "migrateLegacyProgress", "migrateLegacyTier3", "migrateLegacyTier2" }) do
		lu.assertEquals(type(RsfSquadronScreenplay[name]), "function", "RsfSquadronScreenplay:" .. name .. " must be defined")
	end
end

local function migrate(player) return RsfSquadronScreenplay:migrateLegacyProgress(player) end

-- A Kaydine pilot without any quest state. opts.marker: nil (none, the default), "1" or "2"
local function bare(opts)
	opts = opts or {}

	local player = T.player(kay, 1, { attempted = false, skills = opts.skills })

	setMarker(player, opts.marker)
	return player
end

-- Sets a legacy status key and remembers it in `want` (suffix -> value)
local function setStatus(player, want, suffix, value)
	H.setQuestStatus(player, suffix, value)
	want[suffix] = value
end

-- Legacy history: positions 1..k-1 won and paid under the legacy names; position k in `mode`:
--   none | attempted | active (stale run) | complete (won, unpaid) | paid (won and paid)
-- Returns the table of legacy status values that were set.
local function history(player, k, mode)
	local want = {}

	for m = 1, k - 1 do
		M.finish(player, LEG[m][1], LEG[m][2])
		setStatus(player, want, LEGKEY[m] .. ":attempted", "1")
		setStatus(player, want, LEGKEY[m] .. ":reward", "1")
	end

	local q = LEG[k]

	if mode == "active" then
		M.startRun(player, q[1], q[2], { inspect = q[1] == "inspect", waypoint = (k == 2 or k == 4) })
	elseif mode == "complete" or mode == "paid" then
		M.finish(player, q[1], q[2])
	end

	if mode ~= "none" then
		setStatus(player, want, LEGKEY[k] .. ":attempted", "1")
	end

	if mode == "paid" then
		setStatus(player, want, LEGKEY[k] .. ":reward", "1")
	end

	return want
end

local function firstScreen(trainer, player)
	local transcript = T.converse(trainer, player)

	lu.assertNotNil(transcript[1], trainer.label .. " shows a first screen")
	return transcript[1].id
end

local function kaydineScreen(player) return firstScreen(kay, player) end

local function enterScreen(player, id)
	local tmpl = H.conversationTemplate(kay.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. kay.template)
	H.expectGlobal(H.conversationTemplateTable(kay.template).luaClassHandler, "Kaydine conversation handler"):runScreenHandlers(tmpl, player, H.newNpc({}), 0, pScreen)
end

local function assertLegacyClean(player, msg)
	for _, q in ipairs(LEG) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), (msg or "") .. label(q) .. ": leftovers (journal, datapad mission, observers, waypoint key, waypoint)")
	end

	for _, suffix in ipairs({ "naboo_privateer_13a:attempted", "naboo_privateer_13a:reward", "naboo_privateer_tier2_4a:attempted", "naboo_privateer_tier2_4a:reward" }) do
		lu.assertNil(H.getQuestStatus(player, suffix), (msg or "") .. suffix .. ": old-only status key")
	end
end

-- The new state of mission m: "complete" for every member, or "none" for every member
local function assertMission(player, m, want, msg)
	for _, q in ipairs(NEW[m]) do
		lu.assertEquals(state(player, q), want, (msg or "") .. label(q) .. ": journal state")
	end
end

-- After the step, every status key holds the value of the key it moved from (nil when that had none)
local function assertShifted(player, set, msg)
	local expected = {}

	for _, m in ipairs(SHIFT) do
		expected[m[2]] = set[m[1]]
	end

	for suffix in pairs(ALL_KEYS) do
		lu.assertEquals(H.getQuestStatus(player, suffix), expected[suffix], (msg or "") .. suffix .. ": status key after the step")
	end
end

---------------------------------------------------------------------------------------------
-- Table M2, one test per row (AC-8)
---------------------------------------------------------------------------------------------

TestKaydineMigrationRows = {}

function TestKaydineMigrationRows:setUp()
	H.reset()
	needsMigration()
end

-- AC-8 T1 .. T4: a completed legacy entry becomes the completed new entries of its position
for k = 1, 4 do
	TestKaydineMigrationRows["test_t" .. k .. "_a_completed_" .. LEG[k][1] .. "_" .. LEG[k][2] .. "_becomes_the_completed_new_entries_of_mission_" .. k] = function()
		local player = bare({ marker = "1" })

		M.finish(player, LEG[k][1], LEG[k][2])
		migrate(player)

		for m = 1, 4 do
			assertMission(player, m, m == k and "complete" or "none", "legacy " .. label(LEG[k]) .. " complete: ")
		end

		assertLegacyClean(player)
		lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
	end
end

-- AC-8 T1: the new members are written as a whole chain, also when the migration comes from a conversation
function TestKaydineMigrationRows:test_t1_a_completed_13a_shows_the_pay_screen_of_mission_1_and_pays_the_head_once()
	local player = bare({ marker = "1" })
	local rec = T.spyRewards()

	M.finish(player, "destroy", "naboo_privateer_13a")

	lu.assertEquals(kaydineScreen(player), "mission1_complete", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls on the routing screen")
	enterScreen(player, "mission1_reward")
	lu.assertEquals(rec.rewards, { HEADS[1] }, "rewardPlayer calls after the pay screen")
end

-- AC-8 T5: a stale legacy run is purged completely, writes nothing new and makes no noise
for k = 1, 4 do
	TestKaydineMigrationRows["test_t5_a_stale_" .. LEG[k][1] .. "_" .. LEG[k][2] .. "_run_is_purged_and_writes_no_new_entry"] = function()
		local player = bare({ marker = "1" })

		M.startRun(player, LEG[k][1], LEG[k][2], { inspect = LEG[k][1] == "inspect", waypoint = (k == 2 or k == 4) })

		local before = M.sideEffects(player)

		lu.assertEquals(M.leftovers(player, LEG[k][1], LEG[k][2]).journal, "active", "setup: stale run")
		migrate(player)
		assertLegacyClean(player)

		for m = 1, 4 do
			assertMission(player, m, "none", "stale " .. label(LEG[k]) .. ": ")
		end

		lu.assertEquals(M.missions(player, LEG[k][1], LEG[k][2]), 0, "datapad missions of the stale run")
		lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
		lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")

		local failed = false

		for _, crc in ipairs(player.failedMissions) do
			failed = failed or crc == M.crc(LEG[k][1], LEG[k][2])
		end

		lu.assertTrue(failed, "failedMissions has the stale run's CRC")
	end
end

-- AC-8 T5: the stale run of each position leaves the pilot on the failed screen of that position (was on_mission)
for k = 1, 4 do
	TestKaydineMigrationRows["test_t5_a_stale_run_of_mission_" .. k .. "_gives_the_pilot_the_failed_screen_of_mission_" .. k] = function()
		local player = bare({ marker = "1" })

		history(player, k, "active")
		lu.assertEquals(M.leftovers(player, LEG[k][1], LEG[k][2]).journal, "active", "setup: stale run")
		lu.assertEquals(kaydineScreen(player), FAILED[k], "first screen")
	end
end

-- AC-8 T6: the eight keys with distinct values; the collision of old 14 / 15 with new 13 / 14
function TestKaydineMigrationRows:test_t6_all_eight_keys_with_distinct_values_move_by_position()
	local player = bare({ marker = "1" })
	local values = { "a", "b", "c", "d", "e", "f", "g", "h" }

	for i, m in ipairs(SHIFT) do
		H.setQuestStatus(player, m[1], values[i])
	end

	migrate(player)

	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:attempted"), "a", "tier2_1a:attempted (old 13a:attempted)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:reward"), "b", "tier2_1a:reward (old 13a:reward)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:attempted"), "c", "13:attempted (old 14:attempted)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:reward"), "d", "13:reward (old 14:reward)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:attempted"), "e", "14:attempted (old 15:attempted)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:reward"), "f", "14:reward (old 15:reward)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_15:attempted"), "g", "15:attempted (old tier2_4a:attempted)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_15:reward"), "h", "15:reward (old tier2_4a:reward)")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_13a:attempted"), "13a:attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_13a:reward"), "13a:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_4a:attempted"), "tier2_4a:attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_4a:reward"), "tier2_4a:reward")
end

-- AC-8 T6 (collision): a key that is old AND new keeps no stale value: the move of 15 -> 14 finds 14 vacated by 14 -> 13.
-- With "a new key that is already set wins", a step that writes before it has removed every old key loses the 15 values.
function TestKaydineMigrationRows:test_t6_the_old_14_value_is_gone_from_14_when_the_old_15_value_moves_in()
	local player = bare({ marker = "1" })

	H.setQuestStatus(player, "naboo_privateer_14:reward", "old14")
	H.setQuestStatus(player, "naboo_privateer_15:reward", "old15")
	migrate(player)
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:reward"), "old14", "13:reward")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:reward"), "old15", "14:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_15:reward"), "15:reward")
end

-- AC-8 T6 (collision): the same when the new key 13 is already set; it keeps its value, the old 14 value is dropped,
-- and 14 still receives the old 15 value
function TestKaydineMigrationRows:test_t6_an_already_set_new_key_wins_and_the_chain_behind_it_still_moves()
	local player = bare({ marker = "1" })

	H.setQuestStatus(player, "naboo_privateer_13:reward", "7")
	H.setQuestStatus(player, "naboo_privateer_14:reward", "old14")
	H.setQuestStatus(player, "naboo_privateer_15:reward", "old15")
	migrate(player)
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:reward"), "7", "13:reward keeps its value")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:reward"), "old15", "14:reward (old 15)")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_15:reward"), "15:reward")
end

-- AC-8 T6 (collision): every subset of the eight keys moves the same way (256 states)
function TestKaydineMigrationRows:test_t6_every_subset_of_the_eight_keys_shifts_by_position()
	for mask = 0, 255 do
		H.reset()

		local player = bare({ marker = "1" })
		local set = {}

		for i, m in ipairs(SHIFT) do
			if mask & (1 << (i - 1)) ~= 0 then
				set[m[1]] = "v" .. i
				H.setQuestStatus(player, m[1], "v" .. i)
			end
		end

		migrate(player)
		assertShifted(player, set, "subset " .. mask .. ": ")
	end
end

-- AC-8 T7: only 14:attempted and 14:reward set (old M2 done and paid)
function TestKaydineMigrationRows:test_t7_the_old_mission_2_keys_become_the_mission_2_keys_and_not_the_mission_3_keys()
	local player = bare({ marker = "1" })

	H.setQuestStatus(player, "naboo_privateer_14:attempted", "x")
	H.setQuestStatus(player, "naboo_privateer_14:reward", "y")
	migrate(player)
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:attempted"), "x", "13:attempted")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:reward"), "y", "13:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_14:attempted"), "14:attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_14:reward"), "14:reward")
end

-- AC-8 T7: the old mission 2 was won and paid; by name this pilot would be paid M3's reward for it
function TestKaydineMigrationRows:test_t7_a_pilot_who_won_and_was_paid_the_old_mission_2_is_offered_mission_3_and_is_paid_nothing()
	local player = bare({ marker = "1" })
	local rec = T.spyRewards()

	history(player, 3, "none")
	-- history(3, none) won positions 1 and 2 and paid them
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:reward"), "1", "setup: old 14:reward")
	lu.assertEquals(kaydineScreen(player), "mission3_ready", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	assertMission(player, 1, "complete")
	assertMission(player, 2, "complete")
	assertMission(player, 3, "none")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_13:reward"), "1", "13:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_14:attempted"), "14:attempted (it was the old mission 2's)")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_14:reward"), "14:reward (it was the old mission 2's)")
end

-- AC-8 T8: only 15:attempted set (old M3 tried and failed)
function TestKaydineMigrationRows:test_t8_the_old_mission_3_attempt_becomes_the_mission_3_attempt()
	local player = bare({ marker = "1" })

	H.setQuestStatus(player, "naboo_privateer_15:attempted", "z")
	migrate(player)
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:attempted"), "z", "14:attempted")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_15:attempted"), "15:attempted")
end

-- AC-8 T8: and it shows as the failed mission 3 when missions 1 and 2 are won
function TestKaydineMigrationRows:test_t8_an_old_mission_3_attempt_with_missions_1_and_2_won_shows_mission3_failed()
	local player = bare({ marker = "1" })

	history(player, 3, "attempted")
	lu.assertEquals(kaydineScreen(player), "mission3_failed", "first screen")
end

-- AC-8 T9: no legacy state: only the marker changes
function TestKaydineMigrationRows:test_t9_a_pilot_without_legacy_state_gets_only_the_marker()
	local player = bare({ marker = "1" })
	local snap = M.snapshot(player)
	local before = M.sideEffects(player)

	migrate(player)

	snap.status[player.objectID .. MARKER] = "3"
	lu.assertEquals(M.snapshot(player), snap, "journal, status keys, observers, waypoints, datapad and shared memory (plus the marker)")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
end

-- AC-8 T9: a never started pilot gets the offer
function TestKaydineMigrationRows:test_t9_a_never_started_pilot_is_offered_mission_1_and_gets_the_marker_2()
	local player = bare()

	lu.assertEquals(kaydineScreen(player), "mission1_ready", "first screen")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-8 T10: a live new run survives a completed legacy entry of the same position
function TestKaydineMigrationRows:test_t10_a_live_1b_run_blocks_the_trio_completion_and_survives_the_purge_of_13a()
	local player = bare({ marker = "1" })

	M.finish(player, "destroy", "naboo_privateer_13a")
	M.startRun(player, "assassinate", "naboo_privateer_tier2_1b")

	local live = M.leftovers(player, "assassinate", "naboo_privateer_tier2_1b")
	local memory = H.Engine.sharedMemoryKeys()

	lu.assertEquals(live.journal, "active", "setup: live run")
	lu.assertEquals(kaydineScreen(player), "on_mission", "first screen")
	lu.assertEquals(M.leftovers(player, "assassinate", "naboo_privateer_tier2_1b"), live, "the live run's journal, datapad mission, observer, waypoint key and waypoint")
	lu.assertEquals(state(player, NEW[1][1]), "none", "1a is not written")
	lu.assertEquals(state(player, NEW[1][3]), "none", "1c is not written")
	assertLegacyClean(player)
	lu.assertEquals(H.Engine.sharedMemoryKeys(), memory, "shared memory keys")
end

-- AC-8 T10: the same for the single new quests of the other positions
for k = 2, 4 do
	TestKaydineMigrationRows["test_t10_a_live_" .. NEW[k][1][1] .. "_run_survives_the_completed_legacy_entry_of_its_position"] = function()
		local player = bare({ marker = "1" })

		M.finish(player, LEG[k][1], LEG[k][2])
		M.startRun(player, NEW[k][1][1], NEW[k][1][2])

		local live = M.leftovers(player, NEW[k][1][1], NEW[k][1][2])

		migrate(player)
		lu.assertEquals(M.leftovers(player, NEW[k][1][1], NEW[k][1][2]), live, "the live run")
		assertLegacyClean(player)
	end
end

---------------------------------------------------------------------------------------------
-- Every legacy state per mission position (AC-8): never started, attempted, stale run, won, won and paid
---------------------------------------------------------------------------------------------

TestKaydineMigrationPositions = {}

function TestKaydineMigrationPositions:setUp()
	H.reset()
	needsMigration()
end

local function expectedScreen(k, mode)
	if mode == "none" then return OFFER[k] end
	if mode == "attempted" or mode == "active" then return FAILED[k] end
	if mode == "complete" then return PENDING[k] end

	return AFTER_PAID[k]
end

for k = 1, 4 do
	for _, mode in ipairs({ "none", "attempted", "active", "complete", "paid" }) do
		-- AC-8
		TestKaydineMigrationPositions["test_position_" .. k .. "_" .. mode .. "_migrates_to_the_new_state_and_shows_" .. expectedScreen(k, mode)] = function()
			local player = bare({ marker = "1" })
			local set = history(player, k, mode)
			local rec = T.spyRewards()
			local before = M.sideEffects(player)

			lu.assertEquals(kaydineScreen(player), expectedScreen(k, mode), "first screen")

			-- D-14: the failed screen of a mission re-grants it, so its head is running after the first screen
			local regrant = mode == "attempted" or mode == "active"

			for m = 1, 4 do
				if m == k and regrant then
					lu.assertEquals(state(player, NEW[m][1]), "active", "mission " .. m .. ": " .. label(NEW[m][1]) .. ": journal state (re-granted by the failed screen)")
				else
					assertMission(player, m, (m < k or (m == k and (mode == "complete" or mode == "paid"))) and "complete" or "none", "mission " .. m .. ": ")
				end
			end

			assertLegacyClean(player)

			-- the first screen of a pending mission 2 pays it (mission2_reward), which writes 13:reward (it came from the legacy 14:reward)
			if k == 2 and mode == "complete" then
				set["naboo_privateer_14:reward"] = "1"
			end

			assertShifted(player, set)
			lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
			-- the pending screen of mission 2 is its pay screen (mission2_reward): shown, it pays the head once
			lu.assertEquals(rec.rewards, (k == 2 and mode == "complete") and { HEADS[2] } or {}, "rewardPlayer calls on the first screen")
			-- a re-grant by the failed screen plays the start music; nothing else makes noise
			lu.assertEquals(M.sideEffects(player).music, before.music + (regrant and 1 or 0), "music")
			lu.assertEquals(M.sideEffects(player).events, before.events, "createEvent calls")
		end
	end

	-- AC-8: the won and unpaid mission is paid once, by its head
	TestKaydineMigrationPositions["test_position_" .. k .. "_won_and_unpaid_is_paid_once_by_the_new_head"] = function()
		local player = bare({ marker = "1" })
		local rec = T.spyRewards()

		history(player, k, "complete")
		lu.assertEquals(kaydineScreen(player), PENDING[k], "first screen")

		if k ~= 2 then
			-- mission 2 is paid by its first screen
			enterScreen(player, PAY_SCREEN[k])
		end

		lu.assertEquals(kaydineScreen(player), AFTER_PAID[k], "next visit")
		lu.assertEquals(rec.rewards, { HEADS[k] }, "rewardPlayer calls")
		lu.assertEquals(H.getQuestStatus(player, NEWKEY[k] .. ":reward"), "1", NEWKEY[k] .. ":reward")
	end

	-- AC-8: the won and paid mission is never paid again, on three visits
	TestKaydineMigrationPositions["test_position_" .. k .. "_won_and_paid_is_not_paid_again_over_three_visits"] = function()
		local player = bare({ marker = "1" })
		local rec = T.spyRewards()

		history(player, k, "paid")

		for visit = 1, 3 do
			lu.assertEquals(kaydineScreen(player), AFTER_PAID[k], "visit " .. visit)
		end

		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	end
end

-- AC-8: a pilot with no marker at all gets the same result as one on marker 1
function TestKaydineMigrationPositions:test_a_pilot_without_a_marker_gets_both_steps_and_the_same_state_as_marker_1()
	local player = bare()
	local set = history(player, 3, "complete")

	lu.assertEquals(kaydineScreen(player), "mission3_complete", "first screen")
	assertMission(player, 1, "complete")
	assertMission(player, 2, "complete")
	assertMission(player, 3, "complete")
	assertLegacyClean(player)
	assertShifted(player, set)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-8: old 14 complete with 14:reward unset is the old mission 2 won and unpaid
function TestKaydineMigrationPositions:test_escort_14_complete_with_the_reward_unset_gives_mission2_reward_and_pays_destroy_13_once()
	local player = bare({ marker = "1" })
	local rec = T.spyRewards()

	M.finish(player, "destroy", "naboo_privateer_13a")
	H.setQuestStatus(player, "naboo_privateer_13a:reward", "1")
	M.finish(player, "escort", "naboo_privateer_14")
	H.setQuestStatus(player, "naboo_privateer_14:attempted", "1")

	-- mission 2 is paid by its first screen (mission2_reward); the next visit pays nothing more
	lu.assertEquals(kaydineScreen(player), "mission2_reward", "first screen")
	lu.assertEquals(kaydineScreen(player), "mission3_ready", "second visit")
	lu.assertEquals(rec.rewards, { "destroy_naboo_privateer_13" }, "rewardPlayer calls")
end

-- AC-8: a veteran of all four old missions
function TestKaydineMigrationPositions:test_a_veteran_with_all_four_old_entries_complete_and_all_keys_set_is_completed_kaydine_and_paid_nothing()
	local player = bare({ marker = "1", skills = SKILLS_02 })
	local rec = T.spyRewards()

	for k = 1, 4 do
		M.finish(player, LEG[k][1], LEG[k][2])
		H.setQuestStatus(player, LEGKEY[k] .. ":attempted", "1")
		H.setQuestStatus(player, LEGKEY[k] .. ":reward", "1")
	end

	for visit = 1, 3 do
		lu.assertEquals(kaydineScreen(player), "completed_kaydine", "visit " .. visit)
	end

	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	assertLegacyClean(player)

	for m = 1, 4 do
		assertMission(player, m, "complete")
	end

	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")
end

-- AC-8: a veteran whose last two wins were never paid is paid each once
function TestKaydineMigrationPositions:test_a_pilot_with_all_four_old_entries_complete_and_only_the_first_two_paid_is_paid_missions_3_and_4_once()
	local player = bare({ marker = "1" })
	local rec = T.spyRewards()

	for k = 1, 4 do
		M.finish(player, LEG[k][1], LEG[k][2])
		H.setQuestStatus(player, LEGKEY[k] .. ":attempted", "1")

		if k <= 2 then
			H.setQuestStatus(player, LEGKEY[k] .. ":reward", "1")
		end
	end

	-- the handler offers the last pending reward first
	lu.assertEquals(kaydineScreen(player), "mission4_complete", "first screen")
	enterScreen(player, "mission4_reward")
	lu.assertEquals(kaydineScreen(player), "mission3_complete", "second screen")
	enterScreen(player, "mission3_reward")
	lu.assertEquals(kaydineScreen(player), "here_for_work", "third screen")
	lu.assertEquals(rec.rewards, { HEADS[4], HEADS[3] }, "rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- Step 1 and step 2: independence, ordering, both entrances (AC-9)
---------------------------------------------------------------------------------------------

TestKaydineMigrationSteps = {}

local restore = {}

local function wrapMethod(obj, name, tag, log)
	local original = obj[name]

	assert(original ~= nil, "cannot wrap missing " .. tag)
	restore[#restore + 1] = { obj = obj, name = name, value = rawget(obj, name) }
	obj[name] = function(self, ...)
		log[#log + 1] = tag
		return original(self, ...)
	end
end

function TestKaydineMigrationSteps:setUp()
	H.reset()
	needsMigration()
end

function TestKaydineMigrationSteps:tearDown()
	for i = #restore, 1, -1 do
		local r = restore[i]

		if r.setmt then
			setmetatable(r.obj, r.mt)
		else
			r.obj[r.name] = r.value
		end
	end

	restore = {}
end

-- A pilot who holds legacy state of both tiers: a completed legacy delivery 3b and the 4_initial keys (F2 rows M1, M6) next to
-- the tier 2 history (positions 1 and 2 won and paid, position 3 stale and attempted)
local function bothTiers(player)
	M.finish(player, OLD3[1], OLD3[2])
	H.setQuestStatus(player, "naboo_privateer_tier3_4_initial:attempted", "t3a")
	H.setQuestStatus(player, "naboo_privateer_tier3_4_initial:reward", "t3r")

	return history(player, 3, "active")
end

local function assertBothMigrated(player, set, regranted)
	assertMission(player, 1, "complete")
	assertMission(player, 2, "complete")
	-- opening Kaydine shows mission3_failed, which re-grants mission 3 (D-14); opening Dulios does not
	lu.assertEquals(state(player, NEW[3][1]), regranted and "active" or "none", "mission 3: head")
	assertLegacyClean(player)
	assertShifted(player, set)
	lu.assertEquals(M.leftovers(player, OLD3[1], OLD3[2]), M.clean(), "legacy delivery 3b leftovers")
	lu.assertEquals(state(player, NEW3), "complete", "delivery_no_pickup 3b")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:attempted"), "t3a", "tier3_4a:attempted")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "t3r", "tier3_4a:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier3_4_initial:attempted"), "4_initial:attempted")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9: a pilot with no marker and legacy state of both tiers: step 1, then step 2, marker "2"
function TestKaydineMigrationSteps:test_opening_kaydine_with_both_tiers_of_legacy_state_runs_step_1_then_step_2()
	local player = bare()
	local set = bothTiers(player)
	local log = {}

	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier3", "step1", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2", "step2", log)
	lu.assertEquals(kaydineScreen(player), "mission3_failed", "first screen")
	lu.assertEquals(log, { "step1", "step2" }, "steps run, in order")
	assertBothMigrated(player, set, true)
end

-- AC-9, D-7: opening Dulios instead gives the same result
function TestKaydineMigrationSteps:test_opening_dulios_with_both_tiers_of_legacy_state_gives_the_same_result()
	local player = T.player(dul, 1, { attempted = false })
	local set = bothTiers(player)
	local log = {}

	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier3", "step1", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2", "step2", log)
	lu.assertNotNil(T.converse(dul, player)[1], "Dulios shows a first screen")
	lu.assertEquals(log, { "step1", "step2" }, "steps run, in order")
	assertBothMigrated(player, set)
end

-- AC-9: a character whose step 1 ran in F2 (marker "1") gets only step 2
function TestKaydineMigrationSteps:test_a_pilot_on_marker_1_gets_only_step_2_through_kaydine()
	local player = bare({ marker = "1" })
	local set = history(player, 3, "complete")
	local log = {}

	-- tier 3 legacy that step 1 would migrate: it must stay, as step 1 does not run again
	M.finish(player, OLD3[1], OLD3[2])
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier3", "step1", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2", "step2", log)
	kaydineScreen(player)
	lu.assertEquals(log, { "step2" }, "steps run")
	lu.assertEquals(M.leftovers(player, OLD3[1], OLD3[2]).journal, "complete", "legacy delivery 3b (step 1 did not run)")
	lu.assertEquals(state(player, NEW3), "none", "delivery_no_pickup 3b")
	assertLegacyClean(player)
	assertShifted(player, set)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9: the same through Dulios
function TestKaydineMigrationSteps:test_a_pilot_on_marker_1_gets_only_step_2_through_dulios()
	local player = T.player(dul, 1, { attempted = false })

	setMarker(player, "1")

	local set = history(player, 2, "complete")
	local log = {}

	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier3", "step1", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2", "step2", log)
	T.converse(dul, player)
	lu.assertEquals(log, { "step2" }, "steps run")
	assertLegacyClean(player)
	assertShifted(player, set)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9, I-9 (marker "3" since rsf-tier2-kaydine-duties): nothing happens, even with legacy state present
function TestKaydineMigrationSteps:test_with_the_marker_at_3_migrate_legacy_progress_changes_nothing()
	local player = bare({ marker = "3" })

	bothTiers(player)

	local snap, before = M.snapshot(player), M.sideEffects(player)

	lu.assertEquals(migrate(player), 0, "steps run")
	lu.assertEquals(M.snapshot(player), snap, "state")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
end

-- AC-9, I-9: the number of steps run for each marker
function TestKaydineMigrationSteps:test_the_number_of_steps_run_follows_the_marker()
	lu.assertEquals(migrate(bare()), 3, "steps run without a marker")
	lu.assertEquals(migrate(bare({ marker = "1" })), 2, "steps run on marker 1")
	lu.assertEquals(migrate(bare({ marker = "2" })), 1, "steps run on marker 2")
	lu.assertEquals(migrate(bare({ marker = "3" })), 0, "steps run on marker 3")
end

-- A slice of the state that belongs to tier 3 (journal states, status keys, leftovers of both the legacy and the new names)
local function tier3Slice(player)
	local out = { journal = {}, leftovers = {}, status = {} }

	for _, q in ipairs({ OLD3, NEW3, { "survival", "naboo_privateer_tier3_4c" }, { "destroy_surpriseattack", "naboo_privateer_tier3_4c" },
		{ "destroy_surpriseattack", "naboo_privateer_tier3_4d" }, { "destroy_surpriseattack", "naboo_privateer_tier3_4e" },
		{ "destroy_surpriseattack", "naboo_privateer_tier3_4_initial" }, { "inspect", "naboo_privateer_tier3_3a" } }) do
		out.journal[label(q)] = state(player, q)
		out.leftovers[label(q)] = M.leftovers(player, q[1], q[2])
	end

	for _, suffix in ipairs({ "naboo_privateer_tier3_4_initial:attempted", "naboo_privateer_tier3_4_initial:reward", "naboo_privateer_tier3_4a:attempted", "naboo_privateer_tier3_4a:reward" }) do
		out.status[suffix] = H.getQuestStatus(player, suffix) or false
	end

	return out
end

-- The same for tier 2 (new and legacy names)
local function tier2Slice(player)
	local out = { journal = {}, leftovers = {}, status = {} }

	for m = 1, 4 do
		for _, q in ipairs(NEW[m]) do
			out.journal[label(q)] = state(player, q)
		end

		out.journal[label(LEG[m])] = state(player, LEG[m])
		out.leftovers[label(LEG[m])] = M.leftovers(player, LEG[m][1], LEG[m][2])
	end

	for suffix in pairs(ALL_KEYS) do
		out.status[suffix] = H.getQuestStatus(player, suffix) or false
	end

	return out
end

-- AC-9
function TestKaydineMigrationSteps:test_step_2_leaves_every_tier_3_entry_and_key_unchanged()
	local player = bare()

	bothTiers(player)

	local before = tier3Slice(player)

	RsfSquadronScreenplay:migrateLegacyTier2(player)
	lu.assertEquals(tier3Slice(player), before, "tier 3 journal, leftovers and status keys after step 2 alone")
end

-- AC-9
function TestKaydineMigrationSteps:test_step_1_leaves_every_tier_2_entry_and_key_unchanged()
	local player = bare()

	bothTiers(player)

	local before = tier2Slice(player)

	RsfSquadronScreenplay:migrateLegacyTier3(player)
	lu.assertEquals(tier2Slice(player), before, "tier 2 journal, leftovers and status keys after step 1 alone")
end

-- AC-9: either step on its own gives the result of the full run for its tier
function TestKaydineMigrationSteps:test_step_2_alone_equals_the_tier_2_part_of_the_full_run()
	local alone, full = bare(), bare()
	local setAlone = bothTiers(alone)
	local setFull = bothTiers(full)

	RsfSquadronScreenplay:migrateLegacyTier2(alone)
	migrate(full)
	lu.assertEquals(setAlone, setFull, "setup")
	lu.assertEquals(tier2Slice(alone), tier2Slice(full), "tier 2 state: step 2 alone vs the full run")
end

-- AC-9: the call pattern of the step (R-3): the entries first, then ONE batch of the eight status moves, last
function TestKaydineMigrationSteps:test_step_2_migrates_the_four_entries_in_order_then_moves_the_eight_keys_in_one_batch_last()
	local player = bare()
	local log, batches = {}, {}

	bothTiers(player)

	local realMove = SpaceHelpers.moveQuestStatuses
	local realEntry = SpaceHelpers.migrateSpaceQuestEntry
	local realPurge = SpaceHelpers.purgeSpaceQuest

	restore[#restore + 1] = { obj = SpaceHelpers, name = "moveQuestStatuses", value = rawget(SpaceHelpers, "moveQuestStatuses") }
	restore[#restore + 1] = { obj = SpaceHelpers, name = "migrateSpaceQuestEntry", value = rawget(SpaceHelpers, "migrateSpaceQuestEntry") }
	restore[#restore + 1] = { obj = SpaceHelpers, name = "purgeSpaceQuest", value = rawget(SpaceHelpers, "purgeSpaceQuest") }

	SpaceHelpers.migrateSpaceQuestEntry = function(self, p, oldType, oldName, moveTo)
		log[#log + 1] = "entry:" .. oldType .. "/" .. oldName
		return realEntry(self, p, oldType, oldName, moveTo)
	end
	SpaceHelpers.purgeSpaceQuest = function(self, p, t, n)
		log[#log + 1] = "purge:" .. t .. "/" .. n
		return realPurge(self, p, t, n)
	end
	SpaceHelpers.moveQuestStatuses = function(self, p, moves)
		log[#log + 1] = "moves"
		batches[#batches + 1] = moves
		return realMove(self, p, moves)
	end

	RsfSquadronScreenplay:migrateLegacyTier2(player)

	-- migrateSpaceQuestEntry purges through purgeSpaceQuest on its own self, which is the replaced function: keep only the entries
	local entries = {}

	for _, tag in ipairs(log) do
		if tag:sub(1, 6) == "entry:" or tag == "moves" then
			entries[#entries + 1] = tag
		end
	end

	lu.assertEquals(entries, { "entry:destroy/naboo_privateer_13a", "entry:escort/naboo_privateer_14", "entry:inspect/naboo_privateer_15", "entry:assassinate/naboo_privateer_tier2_4a", "moves" },
		"calls of the step: the four entries in LEGACY_TIER2_QUESTS order, then one moveQuestStatuses call, last")
	lu.assertEquals(#batches, 1, "moveQuestStatuses calls")
	lu.assertEquals(#batches[1], 8, "moves in the batch")
	lu.assertEquals(batches[1], RsfSquadronScreenplay.LEGACY_TIER2_STATUS, "the batch is LEGACY_TIER2_STATUS")
	lu.assertEquals(log[#log], "moves", "the status batch is the last helper call of the step")
end

-- AC-9, I-8: the step never calls a method on a quest global and never raises a message, a music or an event
function TestKaydineMigrationSteps:test_step_2_never_calls_a_method_of_the_new_quest_tables_and_makes_no_noise()
	local player = bare()
	local trapped = {}

	bothTiers(player)

	for m = 1, 4 do
		for _, q in ipairs(NEW[m]) do
			local global = q[1] .. "_" .. q[2]
			local obj = _G[global]
			local mt = getmetatable(obj)

			lu.assertNotNil(obj, global .. " exists")
			lu.assertNotNil(mt, global .. " has a metatable (class methods)")
			restore[#restore + 1] = { setmt = true, obj = obj, mt = mt }

			setmetatable(obj, { __index = function(t, k)
				local inherited = type(mt.__index) == "function" and mt.__index(t, k) or mt.__index[k]

				if type(inherited) == "function" then
					return function() trapped[#trapped + 1] = global .. ":" .. k; error("step 2 must not call " .. global .. ":" .. k) end
				end

				return inherited
			end })
		end
	end

	local before = M.sideEffects(player)

	migrate(player)
	lu.assertEquals(trapped, {}, "methods called on the new quest tables")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
end

---------------------------------------------------------------------------------------------
-- Idempotence (I-9) and the marker
---------------------------------------------------------------------------------------------

TestKaydineMigrationIdempotence = {}

function TestKaydineMigrationIdempotence:setUp()
	H.reset()
	needsMigration()
end

-- AC-9, I-9
function TestKaydineMigrationIdempotence:test_a_second_conversation_shows_the_same_screen_and_changes_nothing()
	local player = bare()

	history(player, 3, "complete")

	local rec = T.spyRewards()
	local first = kaydineScreen(player)
	local snap = M.snapshot(player)
	local second = kaydineScreen(player)

	lu.assertEquals(second, first, "first screen of the second conversation")
	lu.assertEquals(M.snapshot(player), snap, "state after the second conversation")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-9, I-9
function TestKaydineMigrationIdempotence:test_a_second_migrate_legacy_progress_changes_nothing()
	local player = bare()

	history(player, 3, "complete")
	migrate(player)

	local snap, before = M.snapshot(player), M.sideEffects(player)

	lu.assertEquals(migrate(player), 0, "steps run the second time")
	lu.assertEquals(M.snapshot(player), snap, "state after the second run")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9, I-9, R-3: step 2 is not idempotent by itself; the marker is what keeps 14 from shifting twice
function TestKaydineMigrationIdempotence:test_three_conversations_never_shift_the_mission_3_keys_a_second_time()
	local player = bare()

	H.setQuestStatus(player, "naboo_privateer_15:attempted", "z")

	for visit = 1, 3 do
		kaydineScreen(player)
		lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_14:attempted"), "z", "visit " .. visit .. ": 14:attempted")
		lu.assertNil(H.getQuestStatus(player, "naboo_privateer_13:attempted"), "visit " .. visit .. ": 13:attempted")
	end
end

-- AC-9: the marker is per character
function TestKaydineMigrationIdempotence:test_a_second_pilot_is_migrated_after_the_first_one_was()
	local first, second = bare(), bare()

	M.finish(first, "escort", "naboo_privateer_14")
	M.finish(second, "escort", "naboo_privateer_14")
	migrate(first)
	lu.assertEquals(migrate(second), 3, "steps run for the second pilot")
	lu.assertEquals(state(second, NEW[2][1]), "complete", "destroy 13")
end

---------------------------------------------------------------------------------------------
-- Where the migration runs, and in what order (AC-9)
---------------------------------------------------------------------------------------------

TestKaydineMigrationPlacement = {}

function TestKaydineMigrationPlacement:setUp()
	H.reset()
	needsMigration()
end

TestKaydineMigrationPlacement.tearDown = TestKaydineMigrationSteps.tearDown

-- AC-9: migrateLegacyProgress runs before any journal read of getInitialScreen
function TestKaydineMigrationPlacement:test_the_migration_runs_before_any_journal_read_of_the_first_screen()
	local player = bare()
	local log = {}

	M.finish(player, "destroy", "naboo_privateer_13a")
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyProgress", "migrate", log)

	for _, name in ipairs({ "isSpaceQuestActive", "isSpaceQuestComplete", "isSpaceQuestChainActive", "getPilotTierSkillCount", "hasCompletedPilotTier", "hasPilotTierSkill" }) do
		wrapMethod(SpaceHelpers, name, "read:" .. name, log)
	end

	for _, name in ipairs({ "isJournalQuestActive", "isJournalQuestComplete" }) do
		wrapMethod(player.ghost, name, "ghost:" .. name, log)
	end

	kaydineScreen(player)

	lu.assertEquals(log[1], "migrate", "the first recorded event of the conversation")

	local reads = 0

	for _, tag in ipairs(log) do
		if tag:sub(1, 5) == "read:" or tag:sub(1, 6) == "ghost:" then
			reads = reads + 1
		end
	end

	lu.assertTrue(reads > 0, "the conversation reads the journal after the migration")
end

-- AC-9: before the JTL check
function TestKaydineMigrationPlacement:test_it_runs_for_a_player_who_gets_the_not_pilot_screen_because_jtl_is_off()
	local player = bare()

	M.finish(player, "escort", "naboo_privateer_14")
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(kaydineScreen(player), "not_pilot", "first screen")
	H.Engine.config.jtlEnabled = true
	lu.assertEquals(state(player, NEW[2][1]), "complete", "destroy 13")
	assertLegacyClean(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-9: before the squadron check
function TestKaydineMigrationPlacement:test_it_runs_for_a_pilot_of_another_squadron()
	local player = bare()

	M.finish(player, "escort", "naboo_privateer_14")
	player.ghost:setSquadronType(rawget(_G, "CORSEC_SQUADRON"))
	lu.assertEquals(kaydineScreen(player), "pilot_not_rsf", "first screen")
	lu.assertEquals(state(player, NEW[2][1]), "complete", "destroy 13")
	assertLegacyClean(player)
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- The nil check stays first: no player, no npc or no template means no screen and no migration
function TestKaydineMigrationPlacement:test_a_missing_player_npc_or_template_still_returns_nil_and_migrates_nothing()
	local tmpl = H.conversationTemplate(kay.template)
	local handler = H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")
	local player = bare()

	M.finish(player, "escort", "naboo_privateer_14")

	lu.assertNil(handler:getInitialScreen(nil, H.newNpc({}), tmpl), "nil player")
	lu.assertNil(handler:getInitialScreen(player, nil, tmpl), "nil npc")
	lu.assertNil(handler:getInitialScreen(player, H.newNpc({}), nil), "nil template")
	lu.assertNil(H.getQuestStatus(player, MARKER), "marker (nothing migrated)")
	lu.assertEquals(state(player, NEW[2][1]), "none", "destroy 13")
end
