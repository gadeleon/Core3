-- RSF tier 2 surrender (resetKaydineQuests) clears the new names and the legacy names.
-- Spec: .claude/work/rsf-tier2-kaydine-missions/01-spec.md (AC-10, Content contract 3, I-10, I-11, D-7).
--
-- The generic reset suite (test_trainer_fixes_reset.lua) already walks every member of the trainer data's chains, which now
-- are the new names. This file adds the legacy names, the leftovers of their runs, the status keys, the duties, the pilot
-- tier and the marker.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")

T.load()

local tr = T.TRAINERS.kaydine
local MARKER = "RsfSquadronScreenplay:legacyVersion"

local LEGACY = {
	{ "destroy", "naboo_privateer_13a" },
	{ "escort", "naboo_privateer_14" },
	{ "inspect", "naboo_privateer_15" },
	{ "assassinate", "naboo_privateer_tier2_4a" },
}

local DUTIES = { "destroy_duty_naboo_privateer_9", "escort_duty_naboo_privateer_10", "destroy_duty_naboo_privateer_11", "recovery_duty_naboo_privateer_12" }

-- The :attempted / :reward keys of the four new heads
local HEAD_KEYS = {}

for _, base in ipairs({ "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }) do
	HEAD_KEYS[#HEAD_KEYS + 1] = base .. ":attempted"
	HEAD_KEYS[#HEAD_KEYS + 1] = base .. ":reward"
end

-- The keys only the legacy names used
local LEGACY_KEYS = {
	"naboo_privateer_13a:attempted", "naboo_privateer_13a:reward", "naboo_privateer_tier2_4a:attempted", "naboo_privateer_tier2_4a:reward",
}

local function allMembers()
	local out = {}

	for n = 1, 4 do
		for _, global in ipairs(tr.chains[n]) do
			out[#out + 1] = global
		end
	end

	return out
end

-- A veteran of all four missions with every new chain member complete, all eight new keys set, the duties complete and every
-- legacy name present in every form (complete journal entry, ZONESWITCHED observer, waypoint key, waypoint, old-only keys)
local function veteranWithLegacyState(marker)
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })

	for _, duty in ipairs(DUTIES) do
		T.setState(player, duty, "complete")
	end

	for _, q in ipairs(LEGACY) do
		M.finish(player, q[1], q[2])
		createObserver(ZONESWITCHED, M.className(q[1], q[2]), "enteredZone", player, 1)

		local id = player.ghost:addWaypoint("space_lok", M.className(q[1], q[2]), "", 1, 2, 3, 0, true, true, 0)

		H.setQuestStatus(player, ":" .. M.className(q[1], q[2]) .. ":waypointID", id)
	end

	for _, key in ipairs(LEGACY_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	if marker == nil then
		removeQuestStatus(player.objectID .. MARKER)
	else
		H.setQuestStatus(player, MARKER, marker)
	end

	return player
end

local function assertEverythingClean(player, label)
	for _, global in ipairs(allMembers()) do
		lu.assertEquals(T.state(player, global), "none", label .. global .. ": journal state")
	end

	for _, duty in ipairs(DUTIES) do
		lu.assertEquals(T.state(player, duty), "none", label .. duty .. ": journal state")
	end

	for _, q in ipairs(LEGACY) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), label .. q[1] .. "/" .. q[2] .. ": leftovers (I-10)")
	end

	for _, key in ipairs(HEAD_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), label .. key)
	end

	for _, key in ipairs(LEGACY_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), label .. key)
	end
end

TestKaydineSurrender = {}

function TestKaydineSurrender:setUp() H.reset() end

-- AC-10 (the setup itself)
function TestKaydineSurrender:test_the_setup_has_every_new_member_and_every_legacy_form()
	local player = veteranWithLegacyState("2")

	lu.assertEquals(#allMembers(), 6, "chain members")

	for _, global in ipairs(allMembers()) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": journal state")
	end

	for _, key in ipairs(HEAD_KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	for _, q in ipairs(LEGACY) do
		local l = M.leftovers(player, q[1], q[2])

		lu.assertEquals(l.journal, "complete", q[2] .. ": journal")
		lu.assertEquals(l.observers, { "ZONESWITCHED" }, q[2] .. ": observers")
		lu.assertNotNil(l.waypointKey, q[2] .. ": waypoint key")
		lu.assertTrue(l.waypoint, q[2] .. ": waypoint")
	end
end

-- AC-10, I-10
function TestKaydineSurrender:test_reset_kaydine_quests_leaves_every_new_and_legacy_name_clean()
	local player = veteranWithLegacyState("2")

	RsfSquadronScreenplay:resetKaydineQuests(player)
	assertEverythingClean(player, "resetKaydineQuests: ")
end

-- AC-10: the pilot tier goes back to 2
function TestKaydineSurrender:test_reset_kaydine_quests_sets_the_pilot_tier_to_2()
	local player = veteranWithLegacyState("2")

	player.ghost.pilotTier = 3
	RsfSquadronScreenplay:resetKaydineQuests(player)
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier")
end

-- AC-10, D-7: the marker is not touched, set or not
function TestKaydineSurrender:test_reset_kaydine_quests_leaves_the_marker_alone()
	local marked = { veteranWithLegacyState("1"), veteranWithLegacyState("2") }
	local unmarked = veteranWithLegacyState(nil)

	for _, player in ipairs(marked) do
		local before = H.getQuestStatus(player, MARKER)

		RsfSquadronScreenplay:resetKaydineQuests(player)
		lu.assertEquals(H.getQuestStatus(player, MARKER), before, "marker " .. tostring(before))
	end

	RsfSquadronScreenplay:resetKaydineQuests(unmarked)
	lu.assertNil(H.getQuestStatus(unmarked, MARKER), "marker that was not set")
end

-- AC-10: legacy state without any new state (a pilot who never talked to Kaydine since F4) is cleared as well
function TestKaydineSurrender:test_legacy_state_alone_is_cleared_with_the_old_only_keys_and_the_moved_names()
	local player = T.player(tr, 1, { attempted = false })

	removeQuestStatus(player.objectID .. MARKER)

	for _, q in ipairs(LEGACY) do
		M.startRun(player, q[1], q[2], { inspect = q[1] == "inspect" })
	end

	for _, key in ipairs(LEGACY_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	H.setQuestStatus(player, "naboo_privateer_14:attempted", "1")
	H.setQuestStatus(player, "naboo_privateer_15:reward", "1")
	RsfSquadronScreenplay:resetKaydineQuests(player)
	assertEverythingClean(player, "resetKaydineQuests (legacy only): ")
	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")
	lu.assertEquals(#player.datapad.items, 0, "datapad missions left")
end

-- AC-10: the same state through the squadron surrender
function TestKaydineSurrender:test_surrender_pilot_clears_the_same_state_for_an_rsf_pilot_and_keeps_the_marker()
	local player = veteranWithLegacyState("2")

	player.ghost:setSquadronType(RSF_SQUADRON)
	SpaceHelpers:surrenderPilot(player)
	assertEverythingClean(player, "surrenderPilot: ")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "2", "marker")
end

-- AC-10: a rejoined pilot is not paid and is offered mission 1; a conversation does not bring any legacy state back
function TestKaydineSurrender:test_a_rejoined_pilot_is_offered_mission_1_and_paid_nothing()
	local player = veteranWithLegacyState("2")

	RsfSquadronScreenplay:resetKaydineQuests(player)

	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "first screen exists")
	lu.assertEquals(transcript[1].id, "mission1_ready", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls after the reset")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

-- AC-10, D-7: with the marker unset, the conversation after the reset finds nothing to migrate and nothing to keep
function TestKaydineSurrender:test_a_conversation_after_the_reset_leaves_the_pilot_clean_even_without_a_marker()
	local player = veteranWithLegacyState(nil)

	RsfSquadronScreenplay:resetKaydineQuests(player)
	T.converse(tr, player)
	assertEverythingClean(player, "conversation after the reset: ")
end

-- AC-10: the reset is safe for a pilot without any state
function TestKaydineSurrender:test_reset_kaydine_quests_runs_for_a_fresh_pilot_and_for_nil()
	local player = T.player(tr, 1, { attempted = false })

	RsfSquadronScreenplay:resetKaydineQuests(player)
	RsfSquadronScreenplay:resetKaydineQuests(nil)
	assertEverythingClean(player, "fresh pilot: ")
end
