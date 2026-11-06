-- Storm tier 2 part 3 (Field Commander Alozen): surrendering the pilot profession clears Alozen's progress (resetAlozenQuests), after Colzet's and Oberhaur's
-- resets and before Declann's.
-- Spec: .claude/work/storm-tier2-alozen/01-spec.md (AC-11; Content contract 2 and 4; D-10; T1 D-11).
--
-- SpaceHelpers:surrenderPilot picks the resets by the pilot's squadron. The fake creature derives its pilot status from the `pilot` field; the test re-enlists
-- the pilot by hand, as test_storm_tier2_surrender.lua does. The order of the four resets is pinned in test_master_trainer_imperial_surrender.lua.

local lu = require("luaunit")
local H = require("harness")
local A = require("storm_tier2_alozen_data")
local T = require("storm_tier2_data")
local CS = require("harness.client_strings")

A.load()

local KEYS = A.statusKeys()

-- A graduate who carries every kind of Alozen state: the three missions complete, the duties active or complete, every status key, four tier 2 skills,
-- pilot tier 3, transfer forms in the inventory, plus Oberhaur's and Colzet's state (the surrender clears those through their own resets)
local function graduate()
	local player = A.pilot({ m = 3, t2 = { 1, 2, 3, 4 } })

	A.setState(player, A.DUTY1, "active")
	A.setState(player, A.DUTY2, "complete")
	A.setState(player, A.DUTY3, "complete")

	for _, key in ipairs(KEYS) do
		H.setQuestStatus(player, key, "1")
	end

	T.addForm(player, T.FULL_NAME)

	return player
end

local function surrender(player)
	SpaceHelpers:surrenderPilot(player)
	return player
end

TestAlozenSurrender = {}

function TestAlozenSurrender:setUp()
	H.reset()
	A.load()
end

-- AC-11 (the setup itself)
function TestAlozenSurrender:test_the_setup_carries_every_kind_of_state()
	local player = graduate()

	for n, global in ipairs(A.MISSIONS) do
		lu.assertEquals(A.state(player, global), "complete", global .. " (mission " .. n .. "): journal state")
	end

	lu.assertEquals(A.state(player, A.DUTY1), "active", A.DUTY1)
	lu.assertEquals(A.state(player, A.DUTY2), "complete", A.DUTY2)

	for _, key in ipairs(KEYS) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key)
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier")
end

-- AC-11
function TestAlozenSurrender:test_surrendering_clears_the_six_journal_entries_complete_or_active()
	local player = surrender(graduate())

	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(A.state(player, global), "none", global .. ": journal state after the surrender")
	end
end

-- AC-11: active runs are cleared too
function TestAlozenSurrender:test_surrendering_clears_active_runs_of_each_mission_and_duty()
	for _, global in ipairs(A.GLOBALS) do
		H.reset()

		local player = A.pilot()

		A.setState(player, global, "active")
		surrender(player)
		lu.assertEquals(A.state(player, global), "none", global .. ": active run after the surrender")
	end
end

-- AC-11
function TestAlozenSurrender:test_surrendering_removes_the_six_status_keys()
	local player = surrender(graduate())

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end
end

-- AC-11: Oberhaur's and Colzet's state goes too (their resets still run)
function TestAlozenSurrender:test_surrendering_still_clears_oberhaurs_and_colzets_state()
	local player = surrender(graduate())

	for _, global in ipairs(T.GLOBALS) do
		lu.assertEquals(T.state(player, global), "none", global .. ": Oberhaur journal state after the surrender")
	end

	for _, key in ipairs(T.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the surrender")
	end

	for _, suffix in ipairs(T.FLAG_SUFFIXES) do
		lu.assertNil(H.getQuestStatus(player, suffix), suffix .. " after the surrender")
	end

	lu.assertNil(H.getQuestStatus(player, T.SERIES_SUFFIX), "Colzet's series flag after the surrender")
end

-- AC-11: the pilot profession goes, the pilot tier is reset
function TestAlozenSurrender:test_surrendering_removes_the_imperial_pilot_skills_and_resets_the_pilot_tier()
	local player = surrender(graduate())

	for _, skill in ipairs(SpaceHelpers.pilotSkills.imperialPilot) do
		lu.assertFalse(CreatureObject(player):hasSkill(skill), skill .. " after the surrender")
	end

	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier after the surrender")
end

-- AC-11: the inventory is untouched
function TestAlozenSurrender:test_surrendering_leaves_the_inventory_alone()
	local player = graduate()
	local before = #player.inventory.items

	surrender(player)
	lu.assertEquals(#player.inventory.items, before, "the held items stay")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(#H.Engine.callsTo("destroyObjectFromWorld"), 0, "no destroyObjectFromWorld call")
end

-- AC-11: resetAlozenQuests alone clears Alozen's state and nothing else (T1 D-11)
function TestAlozenSurrender:test_the_reset_alone_touches_only_alozens_state()
	local player = graduate()
	local sq = A.squadron()
	local skillsBefore = #A.held(player)
	local inventoryBefore = #player.inventory.items

	sq:resetAlozenQuests(player)

	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(A.state(player, global), "none", global .. ": journal state after the reset")
	end

	for _, key in ipairs(KEYS) do
		lu.assertNil(H.getQuestStatus(player, key), key .. " after the reset")
	end

	for _, global in ipairs(T.MISSIONS) do
		lu.assertEquals(T.state(player, global), "complete", global .. ": Oberhaur's journal state is not touched")
	end

	for _, suffix in ipairs({ T.INITIATE_SUFFIX, T.ALOZEN_SUFFIX, T.SERIES_SUFFIX }) do
		lu.assertEquals(H.getQuestStatus(player, suffix), "1", suffix .. " is owned by Oberhaur's or Colzet's reset")
	end

	for _, key in ipairs({ "imperial_ss_1:attempted", "imperial_ss_1:reward", "imperial_ss_2:attempted", "imperial_ss_2:reward", "imperial_ss_3:reward" }) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", key .. " (Oberhaur's status key) is not touched")
	end

	lu.assertEquals(#A.held(player), skillsBefore, "tier 2 skills untouched")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier untouched")
	lu.assertEquals(#player.inventory.items, inventoryBefore, "inventory untouched")
end

-- AC-11: the reset is nil-safe
function TestAlozenSurrender:test_the_reset_returns_on_a_nil_player()
	lu.assertEquals(pcall(A.squadron().resetAlozenQuests, A.squadron(), nil), true, "resetAlozenQuests(nil)")
end

-- AC-11: Alozen's reset on a pilot with no Alozen state
function TestAlozenSurrender:test_surrendering_with_no_state_raises_no_error()
	local player = A.pilot({ t2 = {}, alozen = false, initiate = false })
	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "surrenderPilot raised: " .. tostring(err))
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
end

-- AC-11: twice is the same as once
function TestAlozenSurrender:test_surrendering_twice_is_the_same_as_once()
	local player = graduate()

	surrender(player)

	local ok, err = pcall(SpaceHelpers.surrenderPilot, SpaceHelpers, player)

	lu.assertTrue(ok, "second surrenderPilot raised: " .. tostring(err))

	for _, global in ipairs(A.GLOBALS) do
		lu.assertEquals(A.state(player, global), "none", global .. ": journal state after two surrenders")
	end
end

-- AC-11: another squadron's surrender does not call Alozen's reset
function TestAlozenSurrender:test_other_squadrons_do_not_run_alozens_reset()
	local calls = H.spyOn(A.squadron(), "resetAlozenQuests")
	local player = A.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })

	surrender(player)
	lu.assertEquals(#calls, 0, "resetAlozenQuests calls for an Inquisition pilot")

	local storm = A.pilot()

	surrender(storm)
	lu.assertEquals(#calls, 1, "resetAlozenQuests calls for a Storm pilot")
	lu.assertEquals(calls[1].args[1], storm, "the reset gets the pilot")
end

-- AC-11: the next talk after the surrender and a re-enlist
function TestAlozenSurrender:test_the_next_talk_after_the_surrender_opens_not_pilot_and_a_new_pilot_is_treated_as_new()
	A.requireConversation(lu)

	local player = surrender(graduate())

	player.pilot = nil -- the server derives the pilot kind from the skills that are gone
	lu.assertEquals(A.firstScreen(player), "not_pilot", "first screen after the surrender")

	-- re-enlisted at Colzet: Storm pilot again, standing 0, no key
	player.pilot = "imperial"
	player.ghost.squadronType = STORM_SQUADRON
	player.ghost.factionStanding.imperial = 0
	player.faction = FACTIONIMPERIAL
	player.skills[T.NOVICE] = true
	for _, skill in ipairs(T.TIER1_SKILLS) do
		player.skills[skill] = true
	end

	local t = A.talk(player)

	lu.assertEquals(A.ids(t), { "greeting" }, "Alozen treats the pilot as new")
	lu.assertEquals(A.optionSids(t[1]), { "s_a73dd488" }, "no Oberhaur reply and no initiate reply: both keys are gone")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end
