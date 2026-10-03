-- Dulios (RSF tier 3): the five gate screens in SWG's order (pilot, faction, track, ready, on quest), their lines and animations, and the
-- fact that they have no side effects (I-8).
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (AC-3, invariant I-8, Conversation flow C1-C6, Content contract 2 getInitialScreen).
-- Answer key: Appendix A rows 1-5 (rsf_tier3_dulios_convo_data.lua). The harness does not model NPC animations: they are template fields,
-- so each case compares the animation of the template screen it was shown.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")
local D = require("rsf_tier3_dulios_convo_data")

T.load()

local tr = T.TRAINERS.dulios

local function rowsById()
	local byId = {}

	for _, row in ipairs(D.ROWS) do
		byId[row.id] = row
	end

	return byId
end

local ROWS = rowsById()

local function templateScreen(id)
	for _, s in ipairs(H.conversationTemplateTable(D.TEMPLATE).screens) do
		if s.id == id then
			return s
		end
	end

	return nil
end

local function converse(player)
	return T.converse(tr, player)
end

local function sidOfStep(step) return (step.text or ""):match(":(s_[%w_]+)$") end

-- An RSF tier 3 pilot of Dulios, missions 1..n-1 won
local function rsf(n, opts) return T.player(tr, n, opts) end

local function jtlOff(build)
	return function()
		H.Engine.config.jtlEnabled = false
		return build()
	end
end

-- name, builder, expected screen
local GATES = {
	{ "a_player_without_pilot_skills", function() return G.pilot({ kind = "none" }) end, "not_pilot" },
	{ "a_rsf_tier_3_pilot_with_jtl_off", jtlOff(function() return rsf(1) end), "not_pilot" },
	{ "a_rebel_pilot_with_jtl_off", jtlOff(function() return G.pilot({ kind = "rebel" }) end), "not_pilot" },
	{ "a_corsec_pilot_with_jtl_off", jtlOff(function() return G.offTrack({ pilotTier = 3, tier1 = 4 }) end), "not_pilot" },
	{ "a_rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, "wrong_faction" },
	{ "an_imperial_pilot", function() return G.pilot({ kind = "imperial" }) end, "wrong_faction" },
	{ "a_rebel_pilot_with_rsf_squadron_state_and_tier_3", function() return G.pilot({ kind = "rebel", squadron = "rsf", pilotTier = 3 }) end, "wrong_faction" },
	{ "an_imperial_pilot_with_corsec_squadron_state", function() return G.pilot({ kind = "imperial", squadron = "corsec" }) end, "wrong_faction" },
	{ "a_corsec_neutral_pilot_of_tier_3", function() return G.offTrack({ pilotTier = 3, tier1 = 4 }) end, "pilot_not_rsf" },
	{ "a_smuggler_neutral_pilot_of_tier_3", function() return G.offTrack({ squadron = "smuggler", pilotTier = 3, tier1 = 4 }) end, "pilot_not_rsf" },
	{ "a_neutral_pilot_without_a_squadron", function() return G.pilot({ pilotTier = 3 }) end, "pilot_not_rsf" },
	{ "an_rsf_pilot_of_tier_0", function() return G.rsfPilot({ pilotTier = 0, tier1 = 0 }) end, "not_tier3" },
	{ "an_rsf_pilot_of_tier_1", function() return G.rsfPilot({ pilotTier = 1 }) end, "not_tier3" },
	{ "an_rsf_pilot_of_tier_2", function() return G.rsfPilot({ pilotTier = 2 }) end, "not_tier3" },
}

for n, chain in ipairs(tr.chains) do
	for _, member in ipairs(chain) do
		GATES[#GATES + 1] = { "an_rsf_tier_3_pilot_with_" .. member .. "_active", function() return rsf(n, { active = { member } }) end, "on_mission" }
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: first screen, line, animation, end
---------------------------------------------------------------------------------------------

TestDuliosGates = {}

function TestDuliosGates:setUp() H.reset() end
function TestDuliosGates:tearDown() H.Engine.config.jtlEnabled = true end

for _, gate in ipairs(GATES) do
	-- AC-3: a single screen with Appendix A's line and animation; the conversation ends
	TestDuliosGates["test_" .. gate[1] .. "_gets_the_single_screen_" .. gate[3]] = function()
		local transcript = converse(gate[2]())
		local row = ROWS[gate[3]]

		lu.assertNotNil(row, "answer key row " .. gate[3])
		lu.assertEquals(#transcript, 1, gate[1] .. ": number of screens shown")
		lu.assertEquals(transcript[1].id, gate[3], gate[1] .. ": screen")
		lu.assertTrue(transcript[1].stop, gate[1] .. ": the screen ends the conversation")
		lu.assertEquals(sidOfStep(transcript[1]), row.sid, gate[1] .. ": NPC line of '" .. gate[3] .. "'")

		local screen = templateScreen(gate[3])

		lu.assertNotNil(screen, gate[3] .. " is a template screen")
		lu.assertEquals(screen.animation, row.animation, gate[1] .. ": animation of '" .. gate[3] .. "'")
	end

	-- AC-3, I-8: no side effects
	TestDuliosGates["test_" .. gate[1] .. "_has_no_side_effect"] = function()
		local player = gate[2]()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		local tier = player.ghost.pilotTier
		local ships = G.shipGrants()

		converse(player)

		lu.assertEquals(spies.starts, {}, gate[1] .. ": quests started")
		lu.assertEquals(spies.rewards, {}, gate[1] .. ": rewardPlayer calls")
		lu.assertEquals(#spies.chains, 0, gate[1] .. ": startSpaceQuestChain calls")
		lu.assertEquals(#spies.skills, 0, gate[1] .. ": grantSpaceSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, gate[1] .. ": skill grants")
		lu.assertEquals(#spies.squadron, 0, gate[1] .. ": setSquadronType calls")
		lu.assertEquals(#spies.tiers, 0, gate[1] .. ": incrementPilotTier calls")
		lu.assertEquals(player.ghost.pilotTier, tier, gate[1] .. ": pilot tier")
		lu.assertEquals(G.shipGrants(), ships, gate[1] .. ": grantStarterShip calls")
		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, gate[1] .. ": quest status keys written")
	end

	-- AC-3: migrateLegacyProgress runs before any other check (spy order)
	TestDuliosGates["test_" .. gate[1] .. "_runs_the_migration_before_any_check"] = function()
		local player = gate[2]()
		local log = {}

		local function wrap(tbl, key, label)
			local original = tbl[key]

			tbl[key] = function(...)
				log[#log + 1] = label
				return original(...)
			end

			return function() tbl[key] = original end
		end

		local undo = {
			wrap(_G, "isJtlEnabled", "isJtlEnabled"),
			wrap(SpaceHelpers, "isPilot", "isPilot"),
			wrap(SpaceHelpers, "isNeutralPilot", "isNeutralPilot"),
			wrap(SpaceHelpers, "isRSFSquadron", "isRSFSquadron"),
			wrap(SpaceHelpers, "isSpaceQuestChainActive", "isSpaceQuestChainActive"),
			wrap(RsfSquadronScreenplay, "migrateLegacyProgress", "migrate"),
		}

		local ok, err = pcall(converse, player)

		for _, f in ipairs(undo) do f() end

		lu.assertTrue(ok, gate[1] .. ": " .. tostring(err))
		lu.assertEquals(log[1], "migrate", gate[1] .. ": first call among the migration and the checks (" .. table.concat(log, ",") .. ")")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: the order of the five gates is SWG's
---------------------------------------------------------------------------------------------

-- AC-3: a non-pilot who also holds nothing else is a non-pilot before anything (pilot is the first gate)
function TestDuliosGates:test_a_rebel_with_jtl_off_is_not_a_pilot_not_a_wrong_faction()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(converse(G.pilot({ kind = "rebel" }))[1].id, "not_pilot", "rebel pilot, JTL off")
end

-- AC-3: faction comes before the squadron check (a rebel who carries RSF squadron state is a wrong faction, not an off-track pilot)
function TestDuliosGates:test_the_faction_gate_comes_before_the_track_gate()
	lu.assertEquals(converse(G.pilot({ kind = "rebel", squadron = "corsec", pilotTier = 3 }))[1].id, "wrong_faction", "rebel pilot of a CorSec squadron")
end

-- AC-3: the track gate comes before the ready gate (an off-track pilot of tier 1 is not told he is not ready)
function TestDuliosGates:test_the_track_gate_comes_before_the_ready_gate()
	lu.assertEquals(converse(G.offTrack({ pilotTier = 1 }))[1].id, "pilot_not_rsf", "CorSec pilot of tier 1")
end

-- AC-3: the ready gate comes before the on-quest gate
function TestDuliosGates:test_the_ready_gate_comes_before_the_on_mission_gate()
	local player = G.rsfPilot({ pilotTier = 2, active = { "recovery_naboo_privateer_tier3_1a" } })

	lu.assertEquals(converse(player)[1].id, "not_tier3", "RSF tier 2 pilot with a Dulios mission active")
end

-- AC-3: the five lines are SWG's, one each, and none repeats another (the old arrangement reused one line for four gates)
function TestDuliosGates:test_the_five_gate_screens_show_five_distinct_swg_lines()
	local expected = {
		not_pilot = "s_406e1216", wrong_faction = "s_2734ffac", pilot_not_rsf = "s_843db48d", not_tier3 = "s_6", on_mission = "s_e15039ea",
	}
	local seen = {}

	for _, gate in ipairs({ GATES[1], GATES[5], GATES[9], GATES[13], GATES[#GATES] }) do
		local step = converse(gate[2]())[1]

		lu.assertEquals(sidOfStep(step), expected[gate[3]], gate[1] .. ": line of " .. gate[3])
		lu.assertNil(seen[sidOfStep(step)], gate[3] .. ": its line is shared with " .. tostring(seen[sidOfStep(step)]))
		seen[sidOfStep(step)] = gate[3]
	end
end
