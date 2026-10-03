-- RSF tier 3 renames (F2): the surrender (resetDuliosQuests) clears the new names and the legacy names.
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-10, Content contract 3, D-7, I-9).
--
-- The generic reset suite (test_trainer_fixes_reset.lua) already walks every member of the trainer data's chains, which now
-- are the new names. This file adds the legacy names, the leftovers of their runs, the status keys and the marker.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local M = require("migration_scenario")

T.load()

local tr = T.TRAINERS.dulios
local MARKER = "RsfSquadronScreenplay:legacyVersion"

local LEGACY = {
	{ "delivery", "naboo_privateer_tier3_3b" },
	{ "survival", "naboo_privateer_tier3_4c" },
	{ "destroy_surpriseattack", "naboo_privateer_tier3_4_initial" },
}

local HEAD_KEYS = {
	"naboo_privateer_tier3_1a:attempted", "naboo_privateer_tier3_2a:attempted", "naboo_privateer_tier3_3a:attempted", "naboo_privateer_tier3_4a:attempted",
	"naboo_privateer_tier3_1a:reward", "naboo_privateer_tier3_2a:reward", "naboo_privateer_tier3_3a:reward", "naboo_privateer_tier3_4a:reward",
}

local LEGACY_KEYS = { "naboo_privateer_tier3_4_initial:attempted", "naboo_privateer_tier3_4_initial:reward" }

local function allMembers()
	local out = {}

	for n = 1, 4 do
		for _, global in ipairs(tr.chains[n]) do
			out[#out + 1] = global
		end
	end

	return out
end

-- A veteran of all four missions with every new chain member complete and every legacy name present in every form
local function veteranWithLegacyState(marker)
	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })

	for _, q in ipairs(LEGACY) do
		M.finish(player, q[1], q[2])
		createObserver(ZONESWITCHED, M.className(q[1], q[2]), "enteredZone", player, 1)

		local id = player.ghost:addWaypoint("space_lok", M.className(q[1], q[2]), "", 1, 2, 3, 0, true, true, 0)

		H.setQuestStatus(player, ":" .. M.className(q[1], q[2]) .. ":waypointID", id)
	end

	for _, key in ipairs(LEGACY_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	if marker ~= nil then
		H.setQuestStatus(player, MARKER, marker)
	end

	return player
end

local function assertEverythingClean(player, label)
	for _, global in ipairs(allMembers()) do
		lu.assertEquals(T.state(player, global), "none", label .. global .. ": journal state")
	end

	for _, q in ipairs(LEGACY) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), label .. q[1] .. "/" .. q[2] .. ": leftovers (I-9)")
	end

	for _, key in ipairs(HEAD_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), label .. key)
	end

	for _, key in ipairs(LEGACY_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), label .. key)
	end
end

TestRsfRenamesSurrender = {}

function TestRsfRenamesSurrender:setUp() H.reset() end

-- AC-10
function TestRsfRenamesSurrender:test_the_setup_has_every_new_member_and_every_legacy_form()
	local player = veteranWithLegacyState("2")

	lu.assertEquals(#allMembers(), 18, "chain members")

	for _, global in ipairs(allMembers()) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": journal state")
	end

	for _, q in ipairs(LEGACY) do
		local l = M.leftovers(player, q[1], q[2])

		lu.assertEquals(l.journal, "complete", q[2] .. ": journal")
		lu.assertEquals(l.observers, { "ZONESWITCHED" }, q[2] .. ": observers")
		lu.assertNotNil(l.waypointKey, q[2] .. ": waypoint key")
		lu.assertTrue(l.waypoint, q[2] .. ": waypoint")
	end
end

-- AC-10, I-9
function TestRsfRenamesSurrender:test_reset_dulios_quests_leaves_every_chain_member_and_every_legacy_name_clean()
	local player = veteranWithLegacyState("2")

	RsfSquadronScreenplay:resetDuliosQuests(player)
	assertEverythingClean(player, "resetDuliosQuests: ")
end

-- AC-10, D-7: the marker is not touched, set or not
function TestRsfRenamesSurrender:test_reset_dulios_quests_leaves_the_marker_alone()
	local withMarker = veteranWithLegacyState("2")
	local withoutMarker = veteranWithLegacyState(nil)

	RsfSquadronScreenplay:resetDuliosQuests(withMarker)
	RsfSquadronScreenplay:resetDuliosQuests(withoutMarker)

	lu.assertEquals(H.getQuestStatus(withMarker, MARKER), "2", "marker that was set")
	lu.assertNil(H.getQuestStatus(withoutMarker, MARKER), "marker that was not set")
end

-- AC-10
function TestRsfRenamesSurrender:test_surrender_pilot_clears_the_same_state_for_an_rsf_pilot()
	local player = veteranWithLegacyState("2")

	player.ghost:setSquadronType(RSF_SQUADRON)
	SpaceHelpers:surrenderPilot(player)
	assertEverythingClean(player, "surrenderPilot: ")
	lu.assertEquals(H.getQuestStatus(player, MARKER), "2", "marker")
end

-- AC-10: active legacy runs (not only completed entries) are removed with their datapad mission
function TestRsfRenamesSurrender:test_active_legacy_runs_lose_their_datapad_missions_observers_and_waypoints()
	local player = T.player(tr, 3, {})

	for _, q in ipairs(LEGACY) do
		M.startRun(player, q[1], q[2])
	end

	RsfSquadronScreenplay:resetDuliosQuests(player)

	for _, q in ipairs(LEGACY) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), q[1] .. "/" .. q[2] .. ": leftovers")
	end

	lu.assertEquals(#player.ghost.waypoints, 0, "waypoints left")
end

-- AC-10: a surrendered pilot who rejoins is not paid for anything and is offered mission 1
function TestRsfRenamesSurrender:test_a_rejoined_pilot_is_offered_mission_1_and_paid_nothing()
	local player = veteranWithLegacyState("2")

	RsfSquadronScreenplay:resetDuliosQuests(player)

	local rec = T.spyAllQuests()
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "first screen exists")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls after the reset (first screen '" .. tostring(transcript[1].id) .. "')")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
end

-- AC-10, D-7: with the marker kept, a later conversation finds nothing to migrate
function TestRsfRenamesSurrender:test_a_conversation_after_the_reset_leaves_the_pilot_clean()
	local player = veteranWithLegacyState(nil)

	RsfSquadronScreenplay:resetDuliosQuests(player)
	T.converse(tr, player)

	for _, q in ipairs(LEGACY) do
		lu.assertEquals(M.leftovers(player, q[1], q[2]), M.clean(), q[1] .. "/" .. q[2] .. ": leftovers")
	end

	for _, key in ipairs(LEGACY_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end
end
