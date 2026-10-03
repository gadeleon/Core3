-- Commander Dulios (RSF tier 3): reward payout through the mission heads, `on_mission` for every chain member
-- including 3e, and the mission 3 retry over the longer chain.
-- Spec: .claude/work/rsf-tier3-data/01-spec.md (AC-1 conversation part, AC-8, AC-9, Content contract 3,
-- Conversation flow table).
--
-- Drives the real conversation template and handler through the trainer-fixes player builder
-- (trainer_fixes_data.lua, T.TRAINERS.dulios). The data-driven suites test_trainer_fixes_routing / _retry /
-- _chain_helper cover the longer mission 3 chain through the updated chain list in trainer_fixes_data.lua.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local tr = T.TRAINERS.dulios

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local CHAIN3 = tr.chains[3]
local E3 = g("destroy_surpriseattack", "3e")

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Dulios shows a first screen")
	return transcript[1].id
end

-- A pilot who won missions 1..n-1 and whose mission n chain members `complete` are complete.
local function pilot(n, opts)
	return T.player(tr, n, opts)
end

---------------------------------------------------------------------------------------------
-- AC-1: Dulios pays through the head's rewardPlayer
---------------------------------------------------------------------------------------------

TestDuliosRewards = {}

function TestDuliosRewards:setUp() H.reset() end

-- AC-1
function TestDuliosRewards:test_mission_3_win_pays_the_inspect_head_once_and_sets_the_reward_key()
	local player = pilot(3, { complete = { CHAIN3[1], CHAIN3[2], CHAIN3[3] } })
	local rec = T.spyRewards()

	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier3_3a:reward"), "precondition: the :reward key is unset")
	lu.assertEquals(firstScreen(player), "complete_mission3", "first screen")
	lu.assertEquals(rec.rewards, { g("inspect", "3a") }, "rewardPlayer calls (the mission head)")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_3a:reward"), "1", "the :reward key reads 1")
end

-- AC-1
function TestDuliosRewards:test_mission_3_win_pays_nothing_when_the_reward_key_is_already_set()
	local player = pilot(3, { complete = { CHAIN3[1], CHAIN3[2], CHAIN3[3] }, questStatus = { ["naboo_privateer_tier3_3a:reward"] = "1" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission3", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-1: end to end per mission, with the real rewardPlayer: 25,000 credits and the component.
function TestDuliosRewards:test_each_mission_win_screen_grants_25000_credits_and_the_swg_component()
	local C = "object/tangible/ship/components/"
	local expected = {
		{ 1, "complete_mission1", C .. "reactor/rct_mission_reward_neutral_subpro_military.iff" },
		{ 2, "complete_mission2", C .. "engine/eng_mission_reward_neutral_mandal_inferno.iff" },
		{ 3, "complete_mission3", C .. "weapon_capacitor/cap_mission_reward_neutral_sorosuub_v1.iff" },
		{ 4, "complete_mission4", C .. "armor/arm_mission_reward_neutral_kse_handcrafted.iff" },
	}

	for _, row in ipairs(expected) do
		H.reset()

		local n = row[1]
		local player = pilot(n, { complete = tr.chains[n] })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local items = H.spyOn(SpaceHelpers, "spaceItemReward")

		lu.assertEquals(firstScreen(player), row[2], "mission " .. n .. ": first screen")
		lu.assertEquals(#credits, 1, "mission " .. n .. ": spaceCreditReward calls")
		lu.assertEquals(credits[1].args[2], 25000, "mission " .. n .. ": credit amount")
		lu.assertEquals(#items, 1, "mission " .. n .. ": spaceItemReward calls")
		lu.assertEquals(items[1].args[2], row[3], "mission " .. n .. ": item path")
	end
end

-- AC-1: a second visit pays nothing again.
function TestDuliosRewards:test_a_second_visit_after_the_win_screen_pays_nothing_more()
	local player = pilot(3, { complete = { CHAIN3[1], CHAIN3[2], CHAIN3[3] } })
	local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")

	firstScreen(player)
	firstScreen(player)

	lu.assertEquals(#credits, 1, "spaceCreditReward calls over two visits")
end

---------------------------------------------------------------------------------------------
-- AC-8: on_mission
---------------------------------------------------------------------------------------------

TestDuliosOnMission = {}

function TestDuliosOnMission:setUp() H.reset() end

-- AC-8: the case this feature adds.
function TestDuliosOnMission:test_3c_complete_with_3e_active_shows_on_mission_and_pays_nothing()
	local player = pilot(3, { complete = { CHAIN3[1], CHAIN3[2], CHAIN3[3] }, active = { E3 } })
	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier3_3a:reward"), "the :reward key stays unset")
end

-- AC-8: once 3e is over (complete or never started) the win screen is back and pays.
function TestDuliosOnMission:test_3c_and_3e_complete_shows_complete_mission_3_and_pays_the_head()
	local player = pilot(3, { complete = CHAIN3 })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission3", "first screen")
	lu.assertEquals(rec.rewards, { g("inspect", "3a") }, "rewardPlayer calls")
end

-- AC-8 / rsf-tier3-renames AC-5: any one of the 14 table W globals, delivery_no_pickup 3b or surprise attacks 4c, 4d, 4e
-- active gives on_mission (no tier 3 quest complete).
local ACTIVE_MEMBERS = {
	g("recovery", "1a"), g("patrol", "1b"), g("destroy_surpriseattack", "1c"), g("assassinate", "1d"),
	g("escort", "2a"), g("destroy_surpriseattack", "2c"), g("space_battle", "2d"), g("rescue", "2e"),
	g("inspect", "3a"), g("survival", "3c"), g("destroy_surpriseattack", "3e"),
	g("assassinate", "4a"), g("space_battle", "4b"), g("assassinate", "4f"),
	g("delivery_no_pickup", "3b"), g("destroy_surpriseattack", "4c"), g("destroy_surpriseattack", "4d"), g("destroy_surpriseattack", "4e"),
}

for _, name in ipairs(ACTIVE_MEMBERS) do
	-- AC-8
	TestDuliosOnMission["test_" .. name .. "_active_shows_on_mission"] = function()
		local player = pilot(1, { active = { name } })
		local rec = T.spyAllQuests()

		lu.assertEquals(firstScreen(player), "on_mission", name .. " active: first screen")
		lu.assertEquals(rec.rewards, {}, name .. " active: rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, name .. " active: startQuest calls")
	end
end

-- rsf-tier3-renames: the legacy 4_initial test that stood here ("still shows on_mission") is superseded by
-- test_rsf_tier3_renames_migration.lua (AC-9 M5): the migration purges that entry.

-- AC-8: completed_dulios wins over on_mission.
function TestDuliosOnMission:test_completed_dulios_wins_over_on_mission_when_4f_is_complete_and_all_four_03_skills_are_held()
	local player = pilot(4, {
		complete = tr.chains[4],
		active = { E3 },
		skills = { "pilot_neutral_weapons_03" },
	})

	lu.assertEquals(firstScreen(player), "completed_dulios", "first screen with 3e active and everything else done")
end

-- AC-8 / Conversation flow: a mid-chain mission 1, 2 or 4 member behaves as before.
function TestDuliosOnMission:test_a_mission_4_chain_member_active_after_mission_3_shows_on_mission()
	local player = pilot(4, { active = { g("destroy_surpriseattack", "4c") } })

	lu.assertEquals(firstScreen(player), "on_mission", "4c active: first screen")
end

---------------------------------------------------------------------------------------------
-- AC-9: retry over the longer mission 3 chain
---------------------------------------------------------------------------------------------

TestDuliosMission3Retry = {}

function TestDuliosMission3Retry:setUp() H.reset() end

-- Runs the handler for entering screen `id`, as the conversation observer does when the pilot picks the option.
local function enterScreen(player, id)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)
	H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Dulios conversation handler"):runScreenHandlers(tmpl, player, H.newNpc({}), 0, pScreen)
end

-- AC-9: entering a mission 3 start screen with 3a, 3b, 3c and 3e all complete.
-- rsf-tier3-dulios-convo (Superseded): one offer-path start screen and one failure-reply start screen of mission 3
for _, id in ipairs({ "m3_c4095762", "m3_retry_2852c031" }) do
	TestDuliosMission3Retry["test_" .. id .. "_with_all_four_members_complete_clears_them_and_starts_the_head"] = function()
		local seen = {}
		local starts = H.spyOn(_G[CHAIN3[1]], "startQuest", function(self, pPlayer)
			for i = 1, #CHAIN3 do
				seen[i] = T.state(pPlayer, CHAIN3[i])
			end
		end)
		local player = pilot(3, { complete = CHAIN3, attempted = false })

		enterScreen(player, id)

		lu.assertEquals(#starts, 1, id .. ": startQuest calls on the head " .. CHAIN3[1])
		lu.assertEquals(seen, { "none", "none", "none", "none" }, id .. ": journal state of the four members when the head's startQuest ran")
		lu.assertEquals(T.state(player, E3), "none", id .. ": 3e has no journal entry after the restart")
	end

	-- AC-9: with 3e still running nothing is started or cleared.
	TestDuliosMission3Retry["test_" .. id .. "_while_3e_is_active_starts_nothing_and_clears_nothing"] = function()
		local starts = H.spyOn(_G[CHAIN3[1]], "startQuest")
		local player = pilot(3, { complete = { CHAIN3[1], CHAIN3[2], CHAIN3[3] }, active = { E3 }, attempted = false })
		local clears = H.spyOn(player.ghost, "clearJournalQuest")

		enterScreen(player, id)

		lu.assertEquals(#starts, 0, id .. ": startQuest calls on the head")
		lu.assertEquals(#clears, 0, id .. ": clearJournalQuest calls")
		lu.assertEquals(T.state(player, CHAIN3[3]), "complete", id .. ": 3c stays complete")
		lu.assertEquals(T.state(player, E3), "active", id .. ": 3e stays active")
	end
end

-- AC-9 (the chain helper itself): a finished four-member chain is cleared member by member, then restarted.
function TestDuliosMission3Retry:test_start_space_quest_chain_clears_all_four_members_then_starts_the_head()
	local head = _G[CHAIN3[1]]
	local seen = {}

	H.spyOn(head, "startQuest", function(self, pPlayer)
		for i = 1, #CHAIN3 do
			seen[i] = T.state(pPlayer, CHAIN3[i])
		end
	end)

	local player = pilot(3, { complete = CHAIN3 })

	SpaceHelpers:startSpaceQuestChain(player, nil, CHAIN3[1])

	lu.assertEquals(seen, { "none", "none", "none", "none" }, "journal state of the four members when the head's startQuest ran")
end
