-- Storm tier 2: surrendering the pilot profession clears Oberhaur's progress (resetOberhaurQuests), after Colzet's reset and before Declann's.
-- Spec: .claude/work/storm-tier2-oberhaur/01-spec.md (AC-13; Content contract 2; Shared code changes; D-16; Q-2).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the server from
-- the skills; the test asserts the skills are gone and then clears the field to model the server before it talks to Oberhaur again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local S = require("storm_tier1_data")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")

M.load()
S.load()
T.load()

local JOURNAL = { T.M1, T.M2, T.M3, T.DUTY1, T.DUTY2, T.DUTY3 }

local TIER1_JOURNAL = { S.P1, S.S1, S.M2, S.P3, S.E3, S.A4, S.DUTY6, S.DUTY7 }

local KEYS = T.statusKeys()

for _, suffix in ipairs(T.FLAG_SUFFIXES) do
	KEYS[#KEYS + 1] = suffix
end

local TIER1_KEYS = { S.SERIES_SUFFIX }

for n = 1, 4 do
	TIER1_KEYS[#TIER1_KEYS + 1] = "tatooine_imperial_" .. n .. ":attempted"
	TIER1_KEYS[#TIER1_KEYS + 1] = "tatooine_imperial_" .. n .. ":reward"
end

-- A graduate who carries every kind of Oberhaur state and all of Colzet's: the three missions complete, two duties complete and one active, every status key
-- and flag, two tier 2 skills, pilot tier 2 and transfer forms in the inventory
local function graduate()
	local player = T.pilot({ paid = 3, t2 = { 1, 2 }, finding = true, alozen = true, forms = { T.FULL_NAME, true } })

	T.setState(player, T.DUTY1, "active")
	T.setState(player, T.DUTY2, "complete")
	T.setState(player, T.DUTY3, "complete")

	for _, key in ipairs(TIER1_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	for _, global in ipairs(TIER1_JOURNAL) do
		S.setState(player, global, "complete")
	end

	H.setQuestStatus(player, T.INITIATE_SUFFIX, "1")
	H.setQuestStatus(player, T.STATUS[3] .. ":attempted", "1") -- the Nym technicians feature sets it; the reset removes it

	return player
end

TestStormT2Surrender = {}

function TestStormT2Surrender:setUp()
	H.reset()
	T.load()
end

-- AC-13 (the setup itself)
function TestStormT2Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(T.state(player, global), global == T.DUTY1 and "active" or "complete", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(#T.held(player), 2, "tier 2 skills")
	lu.assertEquals(#T.formsOf(player), 2, "forms")
end

-- AC-13
function TestStormT2Surrender:test_surrendering_clears_the_six_journal_entries_complete_or_active()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-13: active runs are cleared too
function TestStormT2Surrender:test_surrendering_clears_active_runs_of_each_mission_and_duty()
	for _, global in ipairs(JOURNAL) do
		H.reset()

		local player = T.pilot({})

		T.setState(player, global, "active")
		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(T.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- AC-13
function TestStormT2Surrender:test_surrendering_removes_the_six_status_keys_and_the_three_flags()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-13: Colzet's state goes too (his reset still runs)
function TestStormT2Surrender:test_surrendering_clears_all_tier_1_state_as_well()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(TIER1_JOURNAL) do
		lu.assertEquals(S.state(player, global), "none", global .. ": tier 1 journal state after the surrender")
	end

	for _, key in ipairs(TIER1_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-13
function TestStormT2Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-13: the inventory (a held transfer form) is the surrender's business no more than the reset's (T1 D-11)
function TestStormT2Surrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#player.inventory.items, 2, "the held transfer forms stay")
	lu.assertEquals(#T.formsOf(player), 2, "both are still forms")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromDatabase"), 0, "no destroyObjectFromDatabase call")
end

-- AC-13, Q-2: a re-enlisted pilot's old signed form is refused until Colzet promotes him again
function TestStormT2Surrender:test_after_a_surrender_and_a_new_sign_up_the_old_signed_form_is_not_accepted_until_colzet_promotes_again()
	T.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	-- re-enlisted at Colzet: Storm pilot again, no promotion yet
	player.pilot = "imperial"
	player.ghost.squadronType = STORM_SQUADRON
	player.ghost.factionStanding.imperial = 0
	player.faction = FACTIONIMPERIAL
	player.skills[T.NOVICE] = true

	local t = T.talk(player, { "s_e8e1f35f" })

	lu.assertEquals(t[1].id, "greeting", "Oberhaur treats the pilot as new")
	lu.assertEquals(T.ids(t), { "greeting", "apply" }, "screens shown")
	lu.assertEquals(T.optionSids(t[2]), { "s_58c1df5a" }, "only 'I don't have an Authorization of Transfer.' shows")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-13: the next talk after the surrender
function TestStormT2Surrender:test_the_next_talk_after_the_surrender_opens_not_pilot()
	T.requireConversation(lu)

	local player = graduate()

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	lu.assertEquals(T.firstScreen(player), "not_pilot", "first screen after the surrender")
end

-- AC-13: a pilot with no Oberhaur state
function TestStormT2Surrender:test_surrendering_with_no_state_raises_no_error()
	local player = T.pilot({ initiate = false, series = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-13: twice is the same as once
function TestStormT2Surrender:test_surrendering_twice_is_harmless()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
end

-- AC-13: the reset is called for Storm pilots only
function TestStormT2Surrender:test_only_a_storm_pilot_triggers_the_oberhaur_reset()
	lu.assertEquals(type(StormSquadronScreenplay.resetOberhaurQuests), "function", "StormSquadronScreenplay:resetOberhaurQuests is not defined")

	local reset = H.spyOn(StormSquadronScreenplay, "resetOberhaurQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "INQUISITION_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(T.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetOberhaurQuests calls for CorSec, RSF, Havoc, Black Epsilon and Inquisition pilots")

	local player = T.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetOberhaurQuests calls for a Storm pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-13: the order Colzet, Oberhaur, Declann, each once
function TestStormT2Surrender:test_the_resets_run_in_the_order_colzet_oberhaur_declann_each_once()
	local order = {}

	H.spyOn(StormSquadronScreenplay, "resetColzetQuests", function() order[#order + 1] = "colzet" end)
	H.spyOn(StormSquadronScreenplay, "resetOberhaurQuests", function() order[#order + 1] = "oberhaur" end)

	local declann = H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)
	local player = T.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#declann, 1, "resetDeclannQuests calls")
	lu.assertEquals(order, { "colzet", "oberhaur", "declann" }, "the order of the resets")
end

-- AC-13: the other squadrons still reset as before (spot check; the full suites are the per-squadron surrender tests)
function TestStormT2Surrender:test_an_oberhaur_reset_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_imperial_1:reward", "1")
	H.setQuestStatus(player, "naboo_imperial_tier2_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_1:reward"), "1", "Inquisition's key")
	lu.assertEquals(H.getQuestStatus(player, "naboo_imperial_tier2_1:reward"), "1", "Fa'Zoll's key")
end

-- AC-13: the reset is directly callable; it leaves skills, the pilot tier and the inventory alone, and tier 1 state too (Content contract 2)
function TestStormT2Surrender:test_resetOberhaurQuests_clears_only_its_own_state()
	local player = graduate()

	lu.assertEquals(type(StormSquadronScreenplay.resetOberhaurQuests), "function", "StormSquadronScreenplay:resetOberhaurQuests is not defined")
	StormSquadronScreenplay:resetOberhaurQuests(player)

	for _, global in ipairs(JOURNAL) do
		lu.assertEquals(T.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	for _, global in ipairs(TIER1_JOURNAL) do
		lu.assertEquals(S.state(player, global), "complete", global .. ": tier 1 state is Colzet's business")
	end

	for _, key in ipairs(TIER1_KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " is Colzet's")
	end

	lu.assertEquals(#T.held(player), 2, "skills are the surrender's business, not the reset's")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is the surrender's business too")
	lu.assertEquals(#T.formsOf(player), 2, "the held transfer forms stay")
end

-- AC-13: resetOberhaurQuests resets the quests through their own resetQuest (every table is asked once)
function TestStormT2Surrender:test_resetOberhaurQuests_calls_resetQuest_on_all_six_tables()
	local spies = {}

	for _, g in ipairs(JOURNAL) do
		spies[g] = H.spyOn(T.quest(g), "resetQuest")
	end

	local player = graduate()

	StormSquadronScreenplay:resetOberhaurQuests(player)

	for _, g in ipairs(JOURNAL) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-13 (Content contract 2): the six journal entries are cleared without notifying the client
function TestStormT2Surrender:test_resetOberhaurQuests_clears_the_six_journal_entries_with_notify_false()
	local clears = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = graduate()

	StormSquadronScreenplay:resetOberhaurQuests(player)

	local got = {}

	for _, call in ipairs(clears) do
		got[#got + 1] = call.args[2] .. "/" .. call.args[3] .. "/" .. tostring(call.args[4])
		lu.assertEquals(call.args[1], player, "clearSpaceQuest got the pilot")
	end

	table.sort(got)
	lu.assertEquals(got, {
		"assassinate/imperial_ss_3/false", "destroy_duty/lok_imperial_ss_1a/false", "escort_duty/lok_imperial_ss_1c/false",
		"inspect/imperial_ss_1/false", "recovery/imperial_ss_2/false", "recovery_duty/lok_imperial_ss_1b/false",
	}, "clearSpaceQuest calls (type/name/notify)")
end

-- AC-13: a reset with nothing to reset raises nothing
function TestStormT2Surrender:test_resetOberhaurQuests_on_a_fresh_pilot_and_on_nil_raises_nothing()
	lu.assertEquals(pcall(StormSquadronScreenplay.resetOberhaurQuests, StormSquadronScreenplay, T.pilot({})), true, "fresh pilot")
	lu.assertEquals(pcall(StormSquadronScreenplay.resetOberhaurQuests, StormSquadronScreenplay, nil), true, "nil")
end

-- AC-13: a Storm pilot's surrender runs the real reset (the squadron file is loaded by the server) and clears an active run
function TestStormT2Surrender:test_a_storm_pilot_surrender_runs_the_real_reset_and_clears_active_runs()
	local player = T.pilot({ paid = 1, state = "active" })

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(T.state(player, T.M2), "none", "the active mission 2 run is cleared")
	lu.assertNil(H.getQuestStatus(player, T.STATUS[1] .. ":reward"), "mission 1's reward key")
end
