-- Inquisition tier 2: surrendering the pilot profession clears Fa'Zoll's progress and the agent flag (resetFaZollQuests).
-- Spec: .claude/work/inquisition-tier2-fa-zoll/01-spec.md (AC-12; Content contract 2; Shared code changes; D-9, D-15).
--
-- SpaceHelpers:surrenderPilot picks the reset by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field, the
-- server from the skills; the test asserts the skills are gone and then clears the field to model the server before it talks again.

local lu = require("luaunit")
local H = require("harness")
local M = require("master_trainer_imperial_data")
local I = require("inquisition_tier2_data")
local CS = require("harness.client_strings")

M.load()
I.load()

local TIER1_JOURNAL = {
	{ "patrol", "naboo_imperial_1" }, { "destroy_surpriseattack", "naboo_imperial_1" }, { "destroy", "naboo_imperial_2" }, { "patrol", "naboo_imperial_3" },
	{ "escort", "naboo_imperial_3" }, { "assassinate", "naboo_imperial_4" }, { "destroy_duty", "naboo_imperial_6" }, { "escort_duty", "naboo_imperial_7" },
}

local TIER1_KEYS = { "naboo_imperial_2:aborted", I.SERIES_SUFFIX }

for n = 1, 4 do
	TIER1_KEYS[#TIER1_KEYS + 1] = "naboo_imperial_" .. n .. ":attempted"
	TIER1_KEYS[#TIER1_KEYS + 1] = "naboo_imperial_" .. n .. ":reward"
end

local TIER2_KEYS = I.statusKeys()

-- A graduate who carries every kind of Barn and Fa'Zoll state: the tier 1 journal and keys, the four story entries complete, a duty active and one
-- complete, the 8 tier 2 keys, the agent flag, four tier 1 and four tier 2 skills, pilot tier 3
local function graduate()
	local player = I.pilot({ paid = 4, t2 = { 1, 2, 3, 4 } })

	I.setState(player, I.DUTY1, "active")
	I.setState(player, I.DUTY2, "complete")

	for _, q in ipairs(TIER1_JOURNAL) do
		player.ghost.journalComplete[H.questCrc(q[1], q[2])] = true
	end

	for _, key in ipairs(TIER1_KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	return player
end

local function tier1State(player)
	local out = {}

	for _, q in ipairs(TIER1_JOURNAL) do
		out[#out + 1] = player.ghost.journalComplete[H.questCrc(q[1], q[2])] and "complete" or "none"
	end

	for _, key in ipairs(TIER1_KEYS) do
		out[#out + 1] = H.getQuestStatus(player, key) or "nil"
	end

	return out
end

-- Fails with a message when the Fa'Zoll reset does not exist yet (Content contract 2)
local function requireReset()
	lu.assertEquals(type(InquisitionSquadronScreenplay.resetFaZollQuests), "function", "InquisitionSquadronScreenplay:resetFaZollQuests is not defined (Content contract 2)")
end

TestInquisitionT2Surrender = {}

function TestInquisitionT2Surrender:setUp()
	H.reset()
	I.load()
end

-- AC-12 (the setup itself)
function TestInquisitionT2Surrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for _, global in ipairs(I.GLOBALS) do
		local want = (global == I.DUTY1) and "active" or ((global == I.DUTY3) and "none" or "complete")

		lu.assertEquals(I.state(player, global), want, global .. ": journal state")
	end

	for _, key in ipairs(TIER2_KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(H.getQuestStatus(player, I.AGENT_SUFFIX), "1", "the agent flag")
	lu.assertEquals(#I.held(player), 4, "tier 2 skills")
end

-- AC-12
function TestInquisitionT2Surrender:test_surrendering_clears_the_seven_journal_entries_complete_or_active()
	requireReset()
	local player = graduate()

	I.setState(player, I.DUTY3, "active")
	SpaceHelpers:surrenderPilot(player)

	for _, global in ipairs(I.GLOBALS) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12: active runs are cleared too
function TestInquisitionT2Surrender:test_surrendering_clears_active_story_missions()
	requireReset()
	for n, global in ipairs(I.MISSIONS) do
		H.reset()

		local player = I.pilot({ paid = n - 1, state = "active", t2 = (n >= 3) and { 1 } or {} })

		SpaceHelpers:surrenderPilot(player)
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-12
function TestInquisitionT2Surrender:test_surrendering_removes_the_eight_status_keys_and_the_agent_flag()
	requireReset()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, key in ipairs(TIER2_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, I.AGENT_SUFFIX), "the agent flag after the surrender")
end

-- AC-12: Barn's state goes too (the pre-existing behaviour)
function TestInquisitionT2Surrender:test_surrendering_still_clears_all_of_barns_state()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	local want = {}

	for _ = 1, #TIER1_JOURNAL do
		want[#want + 1] = "none"
	end

	for _ = 1, #TIER1_KEYS do
		want[#want + 1] = "nil"
	end

	lu.assertEquals(tier1State(player), want, "tier 1 journal entries and keys after the surrender")
end

-- AC-12
function TestInquisitionT2Surrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = graduate()

	SpaceHelpers:surrenderPilot(player)

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-12: the order of the resets (inquisition-tier3-vrke: Vrke's reset runs between Fa'Zoll's and Declann's; inquisition-tier4-jace-yiaso: Ja'ce's runs between Vrke's and Declann's)
function TestInquisitionT2Surrender:test_the_resets_run_once_each_in_the_order_barn_fa_zoll_vrke_jace_declann()
	requireReset()
	local order = {}

	H.spyOn(InquisitionSquadronScreenplay, "resetBarnQuests", function() order[#order + 1] = "barn" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests", function() order[#order + 1] = "fazoll" end)
	H.spyOn(InquisitionSquadronScreenplay, "resetVrkeQuests", function() order[#order + 1] = "vrke" end)
	-- inquisition-tier4-jace-yiaso: Ja'ce's reset runs between Vrke's and Declann's
	H.spyOn(InquisitionSquadronScreenplay, "resetJaceYiasoQuests", function() order[#order + 1] = "jace" end)
	H.spyOn(M.mts(), "resetDeclannQuests", function() order[#order + 1] = "declann" end)

	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(order, { "barn", "fazoll", "vrke", "jace", "declann" }, "the order of the resets")
end

-- AC-12
function TestInquisitionT2Surrender:test_the_fa_zoll_reset_gets_the_pilot()
	requireReset()
	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests")
	local player = I.pilot({})

	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(#reset, 1, "resetFaZollQuests calls for an Inquisition pilot")
	lu.assertEquals(reset[1].args[1], player, "the reset gets the pilot")
end

-- AC-12: only Inquisition pilots trigger it
function TestInquisitionT2Surrender:test_only_an_inquisition_pilot_triggers_the_fa_zoll_reset()
	requireReset()
	local reset = H.spyOn(InquisitionSquadronScreenplay, "resetFaZollQuests")
	local other = { { "CORSEC_SQUADRON", "neutral" }, { "RSF_SQUADRON", "neutral" }, { "HAVOC_SQUADRON", "rebel" }, { "BLACK_EPSILON_SQUADRON", "imperial" }, { "STORM_SQUADRON", "imperial" } }

	for _, o in ipairs(other) do
		local squadron = rawget(_G, o[1])

		lu.assertNotNil(squadron, o[1] .. " is a harness constant")
		SpaceHelpers:surrenderPilot(I.pilot({ pilot = o[2], squadron = squadron }))
	end

	lu.assertEquals(#reset, 0, "resetFaZollQuests calls for CorSec, RSF, Havoc, Black Epsilon and Storm pilots")
end

-- AC-12: the other squadrons' keys survive
function TestInquisitionT2Surrender:test_a_surrender_leaves_other_squadrons_keys_alone()
	local player = graduate()

	H.setQuestStatus(player, "corellia_rebel_1:reward", "1")
	H.setQuestStatus(player, "corellia_privateer_1:reward", "1")
	H.setQuestStatus(player, "corellia_imperial_1:reward", "1")
	SpaceHelpers:surrenderPilot(player)
	lu.assertEquals(H.getQuestStatus(player, "corellia_rebel_1:reward"), "1", "Havoc's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_privateer_1:reward"), "1", "CorSec's key")
	lu.assertEquals(H.getQuestStatus(player, "corellia_imperial_1:reward"), "1", "Black Epsilon's key")
end

-- AC-12: a pilot with no state, and twice
function TestInquisitionT2Surrender:test_surrendering_with_no_state_or_twice_raises_no_error()
	local player = I.pilot({ agent = false, series = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))

	ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)
	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-12: a re-enlisted pilot gets Barn's "Talk to Fa'Zoll" again after the next promotion
function TestInquisitionT2Surrender:test_after_a_surrender_and_a_new_promotion_barn_opens_working_for_fazoll_again()
	requireReset()
	I.requireConversation(lu)

	local player = graduate()

	lu.assertEquals(I.talkToBarn(player)[1].id, "series_complete", "Barn before the surrender (agent flag set)")
	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone

	-- the pilot enlists again, finishes tier 1 and is promoted (the promotion screen sets the series flag)
	player.pilot = "imperial"
	player.ghost.squadronType = INQUISITION_SQUADRON

	for _, skill in ipairs(I.TIER1_SKILLS) do
		player.skills[skill] = true
	end

	for n = 1, 4 do
		H.setQuestStatus(player, "naboo_imperial_" .. n .. ":attempted", "1")
		H.setQuestStatus(player, "naboo_imperial_" .. n .. ":reward", "1")
		player.ghost.journalComplete[H.questCrc(({ "patrol", "destroy", "patrol", "assassinate" })[n], "naboo_imperial_" .. n)] = true
	end

	H.setQuestStatus(player, I.SERIES_SUFFIX, "1")
	lu.assertEquals(I.talkToBarn(player)[1].id, "working_for_fazoll", "Barn after the surrender and a new promotion")
	lu.assertEquals(I.firstScreen(player), "greeting", "Fa'Zoll greets the new graduate again")
end

---------------------------------------------------------------------------------------------
-- resetFaZollQuests called directly
---------------------------------------------------------------------------------------------

TestInquisitionT2Reset = {}

function TestInquisitionT2Reset:setUp()
	H.reset()
	I.load()
	requireReset()
end

-- AC-12, Content contract 2
function TestInquisitionT2Reset:test_resetFaZollQuests_clears_tier_2_without_touching_tier_1_skills_or_pilot_tier()
	local player = graduate()

	local tier1Before = tier1State(player)

	InquisitionSquadronScreenplay:resetFaZollQuests(player)

	for _, global in ipairs(I.GLOBALS) do
		lu.assertEquals(I.state(player, global), "none", global .. ": journal state")
	end

	for _, key in ipairs(TIER2_KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key)
	end

	lu.assertNil(H.getQuestStatus(player, I.AGENT_SUFFIX), "the agent flag")
	lu.assertEquals(tier1State(player), tier1Before, "tier 1 journal entries and keys (Barn's reset, not this one)")
	lu.assertEquals(#I.held(player), 4, "skills are the surrender's business, not the reset's")

	for _, skill in ipairs(I.TIER1_SKILLS) do
		lu.assertTrue(CreatureObject(player):hasSkill(skill), skill)
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
end

-- AC-12: nil returns
function TestInquisitionT2Reset:test_resetFaZollQuests_with_a_nil_pilot_returns()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetFaZollQuests, InquisitionSquadronScreenplay, nil)

	lu.assertTrue(ok, "resetFaZollQuests(nil) raised: " .. tostring(err))
end

-- AC-12: the reset asks every table once
function TestInquisitionT2Reset:test_resetFaZollQuests_calls_resetQuest_on_all_seven_tables()
	local spies = {}

	for _, g in ipairs(I.GLOBALS) do
		spies[g] = H.spyOn(I.quest(g), "resetQuest")
	end

	local player = graduate()

	InquisitionSquadronScreenplay:resetFaZollQuests(player)

	for _, g in ipairs(I.GLOBALS) do
		lu.assertEquals(#spies[g], 1, g .. ": resetQuest calls")
		lu.assertEquals(spies[g][1].args[1], player, g .. ": resetQuest got the pilot")
	end
end

-- AC-12: the reset clears the journal entries of the seven quests (and not the tier 1 ones)
function TestInquisitionT2Reset:test_resetFaZollQuests_clears_the_seven_journal_entries_through_clearSpaceQuest()
	local cleared = H.spyOn(SpaceHelpers, "clearSpaceQuest")
	local player = graduate()

	InquisitionSquadronScreenplay:resetFaZollQuests(player)

	local got = {}

	for _, call in ipairs(cleared) do
		got[#got + 1] = call.args[2] .. "/" .. call.args[3]
	end

	table.sort(got)

	local want = {}

	for _, global in ipairs(I.GLOBALS) do
		want[#want + 1] = I.IDENTITY[global].type .. "/" .. I.IDENTITY[global].name
	end

	table.sort(want)
	lu.assertEquals(got, want, "clearSpaceQuest (type/name) calls")
end

-- AC-12: the reset of a pilot with no state is harmless
function TestInquisitionT2Reset:test_resetFaZollQuests_on_a_pilot_with_no_tier_2_state_raises_no_error()
	local ok, err = pcall(InquisitionSquadronScreenplay.resetFaZollQuests, InquisitionSquadronScreenplay, I.pilot({ agent = false }))

	lu.assertTrue(ok, "resetFaZollQuests raised: " .. tostring(err))
end
