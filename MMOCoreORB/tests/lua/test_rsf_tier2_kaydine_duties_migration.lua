-- RSF tier 2 duties: migration step 3 (the three invented duties are purged, nothing moves) and the surrender that covers the new duties.
-- Spec: .claude/work/rsf-tier2-kaydine-duties/01-spec.md (AC-7, AC-8, Migration, invariants I-7, D-3, D-4, D-5).
--
-- Legacy state is built by hand (journal entries, flagged datapad duty missions, persistent ZONESWITCHED observers, waypoint keys), because
-- the legacy quest tables no longer exist. The pilots come from the trainer-fixes builder (trainer_fixes_data.lua); the checks read the
-- fakes (migration_scenario.lua). The marker is RsfSquadronScreenplay:legacyVersion; step 3 runs below "3".

local lu = require("luaunit")
local H = require("harness")
local Fakes = require("harness.fakes")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")
local D = require("rsf_tier2_kaydine_duties_data")
local DR = require("duty_rules_scenario")

T.load()

local kay = T.TRAINERS.kaydine
local dul = T.TRAINERS.dulios
local MARKER = "RsfSquadronScreenplay:legacyVersion"

-- The three deleted duties as { type, name }
local LEG = {
	{ "destroy_duty", "naboo_privateer_9" },
	{ "escort_duty", "naboo_privateer_10" },
	{ "recovery_duty", "naboo_privateer_12" },
}

-- The three new duties and the rebuilt one, as { type, name }
local NEW = {
	{ "escort_duty", "naboo_privateer_9" },
	{ "recovery_duty", "naboo_privateer_10" },
	{ "destroy_duty", "naboo_privateer_11" },
}

local STATES = { "none", "active", "complete" }

local function label(q) return q[1] .. "/" .. q[2] end

local function setMarker(player, value)
	if value == nil then
		removeQuestStatus(player.objectID .. MARKER)
	else
		H.setQuestStatus(player, MARKER, value)
	end
end

-- A missing function is a clean red: one readable failure instead of "attempt to call a nil value"
local function needsStep3()
	lu.assertEquals(type(RsfSquadronScreenplay.migrateLegacyTier2Duties), "function", "RsfSquadronScreenplay:migrateLegacyTier2Duties must be defined")
end

-- A Kaydine pilot without any quest state; marker nil (none), "1", "2" or "3"
local function kaydinePilot(marker)
	local player = T.player(kay, 1, { attempted = false })

	setMarker(player, marker)
	return player
end

local function duliosPilot(marker)
	local player = T.player(dul, 1, { attempted = false })

	setMarker(player, marker)
	return player
end

-- A run of a quest without any global, the way a started duty leaves it, but without the one-duty guard: the flagged datapad mission is
-- created directly, so several of them can exist at once (a pilot may have kept any of them across the restart)
local function staleRun(player, q)
	local questType, questName = q[1], q[2]
	local className = M.className(questType, questName)

	player.ghost:activateJournalQuest(M.crc(questType, questName), false)

	local mission = Fakes.giveItem(player.datapad, "object/mission/mission_object.iff", -1)

	mission:setQuestType(questType)
	mission:setQuestName(questName)
	mission:setSpaceDutyMission()
	createObserver(ZONESWITCHED, className, "enteredZone", player, 1)

	local id = player.ghost:addWaypoint("space_lok", className, "", 1, 2, 3, 0, true, true, 0)

	H.setQuestStatus(player, ":" .. className .. ":waypointID", id)
end

local function setupState(player, q, state)
	if state == "active" then
		staleRun(player, q)
	elseif state == "complete" then
		M.finish(player, q[1], q[2])
	end
end

local function copy(t)
	local out = {}

	for k, v in pairs(t) do
		out[k] = v
	end

	return out
end

-- Quest-status store of the player's keys, as { key = value } (the marker included)
local function statusOf(player)
	return copy(M.snapshot(player).status)
end

-- What the status store must look like after step 3: the same, minus the legacy waypoint keys, marker "3"
local function expectedStatus(before, player)
	local out = copy(before)

	for _, q in ipairs(LEG) do
		out[player.objectID .. ":" .. M.className(q[1], q[2]) .. ":waypointID"] = nil
	end

	out[player.objectID .. MARKER] = "3"
	return out
end

local function assertLegacyClean(player, msg)
	for _, q in ipairs(LEG) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), (msg or "") .. label(q) .. ": leftovers (journal, datapad mission, observers, waypoint key, waypoint)")
	end
end

local function firstScreen(trainer, player)
	local transcript = T.converse(trainer, player)

	lu.assertNotNil(transcript[1], trainer.label .. " shows a first screen")
	return transcript[1].id
end

---------------------------------------------------------------------------------------------
-- AC-7: each legacy duty in each state, through Kaydine and through Dulios
---------------------------------------------------------------------------------------------

TestDutyMigrationRows = {}

function TestDutyMigrationRows:setUp()
	H.reset()
	needsStep3()
end

for _, legacy in ipairs(LEG) do
	for _, state in ipairs(STATES) do
		for _, who in ipairs({ { "kaydine", kaydinePilot, kay }, { "dulios", duliosPilot, dul } }) do
			-- AC-7
			TestDutyMigrationRows["test_" .. legacy[1] .. "_" .. legacy[2] .. "_" .. state .. "_is_purged_through_" .. who[1] .. "_and_the_marker_becomes_3"] = function()
				local player = who[2]("2")

				setupState(player, legacy, state)

				-- the new names and the rebuilt destroy duty 11 must stay exactly as they are
				M.finish(player, NEW[1][1], NEW[1][2])

				local before = statusOf(player)
				local newBefore = { M.leftovers(player, NEW[1][1], NEW[1][2]), M.leftovers(player, NEW[2][1], NEW[2][2]), M.leftovers(player, NEW[3][1], NEW[3][2]) }

				lu.assertNotNil(T.converse(who[3], player)[1], who[1] .. " shows a first screen")

				assertLegacyClean(player, "after talking to " .. who[1] .. ": ")
				lu.assertEquals(statusOf(player), expectedStatus(before, player), "quest-status keys (only the legacy waypoint key goes, the marker is 3)")
				lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
				lu.assertEquals({ M.leftovers(player, NEW[1][1], NEW[1][2]), M.leftovers(player, NEW[2][1], NEW[2][2]), M.leftovers(player, NEW[3][1], NEW[3][2]) }, newBefore, "entries of the new duties")
			end
		end
	end
end

-- AC-7: an absent marker runs steps 1, 2 and 3; each legacy duty still ends up clean
for _, legacy in ipairs(LEG) do
	TestDutyMigrationRows["test_" .. legacy[1] .. "_" .. legacy[2] .. "_active_is_purged_by_a_pilot_without_a_marker"] = function()
		local player = kaydinePilot(nil)

		staleRun(player, legacy)
		lu.assertEquals(M.leftovers(player, legacy[1], legacy[2]).journal, "active", "setup: the legacy run is active")
		lu.assertNotNil(T.converse(kay, player)[1], "Kaydine shows a first screen")
		assertLegacyClean(player, "no marker: ")
		lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
	end
end

-- AC-7: the setup of an active run really holds every trace the purge must remove
function TestDutyMigrationRows:test_the_active_setup_holds_a_flagged_mission_an_observer_a_waypoint_key_and_a_waypoint()
	local player = kaydinePilot("2")

	staleRun(player, LEG[1])

	local l = M.leftovers(player, LEG[1][1], LEG[1][2])

	lu.assertEquals(l.journal, "active", "journal")
	lu.assertEquals(l.missions, 1, "datapad missions")
	lu.assertEquals(l.observers, { "ZONESWITCHED" }, "observers")
	lu.assertNotNil(l.waypointKey, "waypoint key")
	lu.assertTrue(l.waypoint, "waypoint")
	lu.assertEquals(#DR.flaggedMissions(player), 1, "flagged duty missions")
end

-- AC-7, D-5: all three legacy duties active together with an active destroy duty 11, a completed escort 9 and a never-started recovery 10
function TestDutyMigrationRows:test_all_three_legacy_duties_active_are_purged_and_the_live_destroy_duty_11_continues()
	local player = kaydinePilot("2")

	for _, legacy in ipairs(LEG) do
		staleRun(player, legacy)
	end

	staleRun(player, NEW[3])
	M.finish(player, NEW[1][1], NEW[1][2])

	local before = statusOf(player)
	local destroy11 = M.leftovers(player, NEW[3][1], NEW[3][2])
	local escort9 = M.leftovers(player, NEW[1][1], NEW[1][2])
	local recovery10 = M.leftovers(player, NEW[2][1], NEW[2][2])

	lu.assertEquals(destroy11.journal, "active", "setup: destroy_duty 11 active")
	lu.assertEquals(destroy11.observers, { "ZONESWITCHED" }, "setup: destroy_duty 11 observer")
	lu.assertEquals(#player.datapad.items, 4, "setup: datapad missions")

	-- Kaydine is busy with the live duty
	lu.assertEquals(firstScreen(kay, player), "on_mission", "first screen")

	assertLegacyClean(player, "combined: ")
	lu.assertEquals(M.leftovers(player, NEW[3][1], NEW[3][2]), destroy11, "destroy_duty 11 (journal, mission, observer, waypoint key) stays as it was")
	lu.assertEquals(M.leftovers(player, NEW[1][1], NEW[1][2]), escort9, "escort_duty 9 stays as it was")
	lu.assertEquals(M.leftovers(player, NEW[2][1], NEW[2][2]), recovery10, "recovery_duty 10 stays as it was")
	lu.assertEquals(#player.datapad.items, 1, "the datapad keeps only the mission of destroy_duty 11")
	lu.assertEquals(statusOf(player), expectedStatus(before, player), "quest-status keys")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker")
end

-- AC-7: other quests of the pilot are not touched by the purge (a story quest and a tier 1 duty of the same shape)
function TestDutyMigrationRows:test_other_journal_entries_datapad_missions_and_observers_are_not_touched()
	local player = kaydinePilot("2")
	local other = { "destroy_duty", "naboo_privateer_6" }

	staleRun(player, other)
	M.finish(player, "escort", "naboo_privateer_15")
	staleRun(player, LEG[1])

	local otherBefore = M.leftovers(player, other[1], other[2])
	local escortBefore = M.leftovers(player, "escort", "naboo_privateer_15")

	T.converse(kay, player)
	lu.assertEquals(M.leftovers(player, other[1], other[2]), otherBefore, "destroy_duty/naboo_privateer_6")
	lu.assertEquals(M.leftovers(player, "escort", "naboo_privateer_15"), escortBefore, "escort/naboo_privateer_15")
	lu.assertEquals(M.leftovers(player, LEG[1][1], LEG[1][2]), M.clean(), "destroy_duty/naboo_privateer_9")
end

---------------------------------------------------------------------------------------------
-- AC-7: markers, order, idempotence
---------------------------------------------------------------------------------------------

TestDutyMigrationMarkers = {}

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

function TestDutyMigrationMarkers:setUp()
	H.reset()
	needsStep3()
end

function TestDutyMigrationMarkers:tearDown()
	for i = #restore, 1, -1 do
		local r = restore[i]

		r.obj[r.name] = r.value
	end

	restore = {}
end

local function wrapAll(log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier3", "step1", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2", "step2", log)
	wrapMethod(RsfSquadronScreenplay, "migrateLegacyTier2Duties", "step3", log)
end

-- the steps that run for each marker, through Kaydine and through Dulios
local RUNS = { { nil, { "step1", "step2", "step3" } }, { "1", { "step2", "step3" } }, { "2", { "step3" } }, { "3", {} } }

for _, run in ipairs(RUNS) do
	for _, who in ipairs({ { "kaydine", kaydinePilot, kay }, { "dulios", duliosPilot, dul } }) do
		-- AC-7
		TestDutyMigrationMarkers["test_marker_" .. tostring(run[1]) .. "_through_" .. who[1] .. "_runs_" .. (#run[2] == 0 and "no_step" or table.concat(run[2], "_then_"))] = function()
			local player = who[2](run[1])
			local log = {}

			wrapAll(log)
			lu.assertNotNil(T.converse(who[3], player)[1], who[1] .. " shows a first screen")
			lu.assertEquals(log, run[2], "steps run, in order")
			lu.assertEquals(H.getQuestStatus(player, MARKER), "3", "marker after the conversation")
		end
	end
end

-- AC-7: marker "3": nothing changes, a legacy duty is left alone
function TestDutyMigrationMarkers:test_with_marker_3_a_legacy_duty_is_not_touched()
	local player = kaydinePilot("3")

	staleRun(player, LEG[1])
	M.finish(player, LEG[2][1], LEG[2][2])

	local snap = M.snapshot(player)

	T.converse(kay, player)
	lu.assertEquals(M.snapshot(player), snap, "state after a conversation on marker 3")
	lu.assertEquals(M.leftovers(player, LEG[1][1], LEG[1][2]).journal, "active", "the legacy run stays")
end

-- AC-7: a second conversation changes nothing
function TestDutyMigrationMarkers:test_a_second_conversation_changes_nothing()
	local player = kaydinePilot("2")

	staleRun(player, LEG[1])
	staleRun(player, NEW[3])
	M.finish(player, LEG[3][1], LEG[3][2])
	T.converse(kay, player)

	local snap = M.snapshot(player)
	local before = M.sideEffects(player)

	T.converse(kay, player)
	T.converse(dul, player)
	lu.assertEquals(M.snapshot(player), snap, "state after the second conversations")
	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
end

-- AC-7: the step is idempotent on its own (purging an absent entry is a no-op)
function TestDutyMigrationMarkers:test_calling_the_step_twice_changes_nothing()
	local player = kaydinePilot("2")

	staleRun(player, LEG[2])
	RsfSquadronScreenplay:migrateLegacyTier2Duties(player)

	local snap = M.snapshot(player)

	RsfSquadronScreenplay:migrateLegacyTier2Duties(player)
	lu.assertEquals(M.snapshot(player), snap, "state after the second call")
	assertLegacyClean(player, "after the step: ")
end

-- AC-7: a second pilot is migrated after the first one was (the marker is per character)
function TestDutyMigrationMarkers:test_a_second_pilot_is_migrated_after_the_first_one_was()
	local first, second = kaydinePilot("2"), kaydinePilot("2")

	staleRun(first, LEG[1])
	staleRun(second, LEG[1])
	T.converse(kay, first)
	assertLegacyClean(first, "first pilot: ")
	lu.assertEquals(M.leftovers(second, LEG[1][1], LEG[1][2]).journal, "active", "setup: the second pilot is still unmigrated")
	T.converse(kay, second)
	assertLegacyClean(second, "second pilot: ")
end

---------------------------------------------------------------------------------------------
-- AC-7: I-7 silence, and what the purge frees
---------------------------------------------------------------------------------------------

TestDutyMigrationSilence = {}

function TestDutyMigrationSilence:setUp()
	H.reset()
	needsStep3()
end

-- AC-7, I-7: no message, no music, no event, no payment, no quest start
function TestDutyMigrationSilence:test_the_migration_sends_nothing_pays_nothing_and_starts_nothing()
	local player = kaydinePilot(nil)

	for _, legacy in ipairs(LEG) do
		staleRun(player, legacy)
	end

	local rec = T.spyAllQuests()
	local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
	local items = H.spyOn(SpaceHelpers, "spaceItemReward")
	local before = M.sideEffects(player)

	RsfSquadronScreenplay:migrateLegacyProgress(player)

	lu.assertEquals(M.sideEffects(player), before, "messages, music and createEvent calls")
	lu.assertEquals(#H.messageLog(player), 0, "system messages")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(#credits, 0, "spaceCreditReward calls")
	lu.assertEquals(#items, 0, "spaceItemReward calls")
	assertLegacyClean(player, "after the migration: ")
end

-- AC-7: after the purge of an active legacy duty, accepting escort 9 succeeds in the same conversation (no duty_already)
function TestDutyMigrationSilence:test_after_purging_an_active_legacy_duty_escort_9_can_be_accepted()
	-- rsf-tier2-kaydine-training (D-11, Superseded S3): the first three tier 2 skills only, so the pilot is not sent to completed_kaydine
	local player = T.player(kay, 4, { complete = { "escort_naboo_privateer_15" }, baseSkills = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02" }, questStatus = { ["naboo_privateer_15:reward"] = "1", [MARKER] = "2" } })

	staleRun(player, LEG[1])
	lu.assertEquals(#DR.flaggedMissions(player), 1, "setup: the legacy duty holds the one-duty guard")

	local transcript = H.converse({ template = kay.template, player = player, npc = H.newNpc({ name = "Trainer" }), choices = { "s_4a1d2431", "s_9b73da8" } })

	lu.assertEquals(transcript[1].id, "here_for_work", "first screen (a legacy duty is not an on_mission duty)")
	lu.assertEquals(transcript[#transcript].id, "accept_duty_escort", "last screen")
	lu.assertEquals(#DR.messages(player, DR.MSG_DUTY_ALREADY), 0, "duty_already messages")
	lu.assertEquals(M.state(player, NEW[1][1], NEW[1][2]), "active", "escort_duty 9")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions")
	assertLegacyClean(player, "after the accept: ")
end

---------------------------------------------------------------------------------------------
-- AC-8: surrender covers the new duties and purges the legacy ones
---------------------------------------------------------------------------------------------

TestDutySurrender = {}

function TestDutySurrender:setUp() H.reset() end

-- every state of a new duty and of a legacy duty at once: new in {none, active, complete} x legacy in {none, active, complete}
local function surrenderPilot(newState, legacyState)
	local player = T.player(kay, 4, { win = { 1, 2, 3, 4 } })

	for _, q in ipairs(NEW) do
		setupState(player, q, newState)
	end

	for _, q in ipairs(LEG) do
		setupState(player, q, legacyState)
	end

	return player
end

for _, newState in ipairs(STATES) do
	for _, legacyState in ipairs(STATES) do
		-- AC-8
		TestDutySurrender["test_new_duties_" .. newState .. "_and_legacy_duties_" .. legacyState .. "_are_all_cleared_by_reset_kaydine_quests"] = function()
			local player = surrenderPilot(newState, legacyState)
			local resets = {}

			for _, global in ipairs(D.GLOBALS) do
				resets[global] = H.spyOn(H.expectGlobal(global, "Kaydine duty quest table (rsf-tier2-kaydine-duties)"), "resetQuest")
			end

			RsfSquadronScreenplay:resetKaydineQuests(player)

			for _, global in ipairs(D.GLOBALS) do
				lu.assertEquals(#resets[global], 1, global .. ": resetQuest calls")
				lu.assertTrue(resets[global][1].args[1] == player, global .. ": resetQuest player")
			end

			for _, q in ipairs(NEW) do
				lu.assertEquals(M.state(player, q[1], q[2]), "none", label(q) .. ": journal state (new duty, " .. newState .. ")")
			end

			assertLegacyClean(player, "legacy duties (" .. legacyState .. "): ")
		end
	end
end

-- AC-8: the legacy waypoint keys and observers are gone, and the new duties' real resetQuest leaves nothing behind either
function TestDutySurrender:test_the_real_reset_leaves_no_journal_entry_mission_observer_or_legacy_key()
	local player = surrenderPilot("active", "active")

	-- the new duties' own state: one flagged mission each is on the datapad, with a ZONESWITCHED observer of the class
	lu.assertEquals(#player.datapad.items, 6, "setup: datapad missions")
	RsfSquadronScreenplay:resetKaydineQuests(player)

	for _, q in ipairs(NEW) do
		lu.assertEquals(M.state(player, q[1], q[2]), "none", label(q) .. ": journal state")
	end

	assertLegacyClean(player, "real reset: ")

	for _, q in ipairs(LEG) do
		lu.assertNil(H.getQuestStatus(player, ":" .. M.className(q[1], q[2]) .. ":waypointID"), label(q) .. ": waypoint key")
	end
end

-- AC-8: the rest of the reset is unchanged: the story missions and their keys, the tier
function TestDutySurrender:test_the_rest_of_the_reset_is_unchanged()
	local player = surrenderPilot("complete", "complete")

	player.ghost.pilotTier = 3
	RsfSquadronScreenplay:resetKaydineQuests(player)

	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")

	for n = 1, 4 do
		for _, global in ipairs(kay.chains[n]) do
			lu.assertEquals(T.state(player, global), "none", global .. ": journal state")
		end

		lu.assertNil(H.getQuestStatus(player, T.statusName(kay, n) .. ":attempted"), T.statusName(kay, n) .. ":attempted")
		lu.assertNil(H.getQuestStatus(player, T.statusName(kay, n) .. ":reward"), T.statusName(kay, n) .. ":reward")
	end
end

-- AC-8: nil and a pilot without any duty state are safe
function TestDutySurrender:test_reset_kaydine_quests_is_safe_for_a_clean_pilot_and_for_nil()
	local player = T.player(kay, 1, { attempted = false })

	RsfSquadronScreenplay:resetKaydineQuests(player)
	RsfSquadronScreenplay:resetKaydineQuests(nil)
	assertLegacyClean(player, "clean pilot: ")
end

-- AC-8: the squadron surrender goes through the same reset
function TestDutySurrender:test_surrender_pilot_clears_new_and_legacy_duties_for_an_rsf_pilot()
	local player = surrenderPilot("active", "active")

	player.ghost:setSquadronType(RSF_SQUADRON)
	SpaceHelpers:surrenderPilot(player)

	for _, q in ipairs(NEW) do
		lu.assertEquals(M.state(player, q[1], q[2]), "none", label(q) .. ": journal state")
	end

	assertLegacyClean(player, "surrenderPilot: ")
end
