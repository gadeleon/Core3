-- Commander Dulios (RSF tier 3) after the renames: routing on the new chain, mission 4's status keys under the head
-- (4a), the retry through the six-member mission 4 chain.
-- Spec: .claude/work/rsf-tier3-renames/01-spec.md (AC-5, Conversation flow, Content contract 5).
--
-- Migration is already done in every test here (the marker is "1"), so none of them depends on the legacy names.
-- The data-driven suites (test_trainer_fixes_routing / _retry / _veterans / _chain_helper) and test_rsf_tier3_dulios.lua
-- run over the new chains through trainer_fixes_data.lua; this file adds what is specific to F2.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local Fakes = require("harness.fakes")

T.load()

local tr = T.TRAINERS.dulios
local MARKER = "RsfSquadronScreenplay:legacyVersion"

local function g(questType, suffix) return questType .. "_naboo_privateer_tier3_" .. suffix end

local CHAIN4 = tr.chains[4]
local A4, F4 = g("assassinate", "4a"), g("assassinate", "4f")

local function pilot(n, opts)
	opts = opts or {}

	local status = { [MARKER] = "2" }

	for k, v in pairs(opts.questStatus or {}) do
		status[k] = v
	end

	opts.questStatus = status
	return T.player(tr, n, opts)
end

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Dulios shows a first screen")
	return transcript[1].id
end

local function enterScreen(player, id)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)
	H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Dulios conversation handler"):runScreenHandlers(tmpl, player, H.newNpc({}), 0, pScreen)
end

local function legacyKeys()
	local out = {}

	for key in pairs(Fakes.questStatus) do
		if key:find("4_initial", 1, true) then
			out[#out + 1] = key
		end
	end

	table.sort(out)
	return out
end

local function chainWithout(last)
	local out = {}

	for _, name in ipairs(CHAIN4) do
		if name ~= last then
			out[#out + 1] = name
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-5: the chain
---------------------------------------------------------------------------------------------

TestDuliosRenamesChain = {}

function TestDuliosRenamesChain:setUp() H.reset() end

-- AC-5
function TestDuliosRenamesChain:test_the_mission_4_chain_of_the_trainer_data_is_the_six_new_members()
	lu.assertEquals(CHAIN4, {
		"assassinate_naboo_privateer_tier3_4a", "space_battle_naboo_privateer_tier3_4b", "destroy_surpriseattack_naboo_privateer_tier3_4c",
		"destroy_surpriseattack_naboo_privateer_tier3_4d", "destroy_surpriseattack_naboo_privateer_tier3_4e", "assassinate_naboo_privateer_tier3_4f",
	}, "trainer_fixes_data Dulios chain 4")
	lu.assertEquals(tr.chains[3], {
		"inspect_naboo_privateer_tier3_3a", "delivery_no_pickup_naboo_privateer_tier3_3b", "survival_naboo_privateer_tier3_3c", "destroy_surpriseattack_naboo_privateer_tier3_3e",
	}, "trainer_fixes_data Dulios chain 3")
	lu.assertNil(tr.statusNames, "mission 4's status key is the head's name, no override")
	lu.assertEquals(T.statusName(tr, 4), "naboo_privateer_tier3_4a", "the :attempted / :reward base of mission 4")
end

---------------------------------------------------------------------------------------------
-- AC-5: routing
---------------------------------------------------------------------------------------------

TestDuliosRenamesRouting = {}

function TestDuliosRenamesRouting:setUp() H.reset() end

-- AC-5: 4a..4e complete, 4f absent
function TestDuliosRenamesRouting:test_4a_to_4e_complete_without_4f_is_not_a_mission_4_win_and_pays_nothing()
	local player = pilot(4, { complete = chainWithout(F4) })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "4a:reward")
end

-- AC-5: the same with all four skills held, still no completed_dulios
function TestDuliosRenamesRouting:test_4a_to_4e_complete_without_4f_is_not_completed_dulios_even_with_all_skills()
	local player = pilot(4, { complete = chainWithout(F4), skills = { "pilot_neutral_weapons_03" } })

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
end

-- AC-5: 4a..4e complete, 4f running
function TestDuliosRenamesRouting:test_4f_running_after_4e_shows_on_mission()
	local player = pilot(4, { complete = chainWithout(F4), active = { F4 } })

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
end

-- AC-5: each of the new members alone, with its predecessors complete
for pos = 3, 5 do
	-- AC-5
	TestDuliosRenamesRouting["test_" .. CHAIN4[pos] .. "_running_with_its_predecessors_complete_shows_on_mission"] = function()
		local before = {}

		for i = 1, pos - 1 do
			before[i] = CHAIN4[i]
		end

		local player = pilot(4, { complete = before, active = { CHAIN4[pos] } })
		local rec = T.spyAllQuests()

		lu.assertEquals(firstScreen(player), "on_mission", CHAIN4[pos] .. ": first screen")
		lu.assertEquals(rec.rewards, {}, CHAIN4[pos] .. ": rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, CHAIN4[pos] .. ": startQuest calls")
	end
end

-- AC-5: the pay-out
function TestDuliosRenamesRouting:test_complete_mission_4_pays_the_4a_head_once_and_sets_the_4a_reward_key()
	local player = pilot(4, { complete = CHAIN4, attempted = false })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, { A4 }, "rewardPlayer calls")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:reward"), "1", "4a:reward")

	firstScreen(player)
	lu.assertEquals(rec.rewards, { A4 }, "rewardPlayer calls after a second visit")
	lu.assertEquals(legacyKeys(), {}, "no 4_initial status key written")
end

-- AC-5
function TestDuliosRenamesRouting:test_complete_mission_4_pays_nothing_when_the_4a_reward_key_is_set()
	local player = pilot(4, { complete = CHAIN4, attempted = false, questStatus = { ["naboo_privateer_tier3_4a:reward"] = "1" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-5: completed_dulios keeps its priority
function TestDuliosRenamesRouting:test_completed_dulios_wins_when_4f_is_complete_and_all_four_03_skills_are_held()
	local player = pilot(4, { complete = CHAIN4, skills = { "pilot_neutral_weapons_03" } })
	local rec = T.spyRewards()

	lu.assertEquals(firstScreen(player), "completed_dulios", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-5: completed_dulios needs 4f, not 4e
function TestDuliosRenamesRouting:test_all_four_skills_with_4e_as_the_last_complete_member_is_not_completed_dulios()
	local player = pilot(4, { complete = chainWithout(F4), skills = { "pilot_neutral_weapons_03" } })

	lu.assertNotEquals(firstScreen(player), "completed_dulios", "first screen")
end

---------------------------------------------------------------------------------------------
-- AC-5: accepting mission 4
---------------------------------------------------------------------------------------------

TestDuliosRenamesAccept = {}

function TestDuliosRenamesAccept:setUp() H.reset() end

for _, id in ipairs({ "accept_fourth_mission", "nothing_cant_handle" }) do
	-- AC-5
	TestDuliosRenamesAccept["test_" .. id .. "_sets_the_4a_attempted_key_and_never_a_4_initial_key"] = function()
		local player = pilot(4, { attempted = false })

		H.spyOn(_G[A4], "startQuest")
		enterScreen(player, id)

		lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier3_4a:attempted"), "1", id .. ": 4a:attempted")
		lu.assertEquals(legacyKeys(), {}, id .. ": 4_initial status keys")
	end

	-- AC-5: all six complete, so a retake clears them first
	TestDuliosRenamesAccept["test_" .. id .. "_with_all_six_members_complete_clears_them_and_starts_the_head"] = function()
		local seen = {}
		local starts = H.spyOn(_G[A4], "startQuest", function(self, pPlayer)
			for i = 1, #CHAIN4 do
				seen[i] = T.state(pPlayer, CHAIN4[i])
			end
		end)
		local player = pilot(4, { complete = CHAIN4, attempted = false })

		enterScreen(player, id)

		lu.assertEquals(#starts, 1, id .. ": startQuest calls on " .. A4)
		lu.assertEquals(seen, { "none", "none", "none", "none", "none", "none" }, id .. ": journal state of the six members when the head's startQuest ran")
	end

	-- AC-5: a member still running blocks the retake
	TestDuliosRenamesAccept["test_" .. id .. "_while_4d_is_active_starts_nothing_and_clears_nothing"] = function()
		local starts = H.spyOn(_G[A4], "startQuest")
		local player = pilot(4, { complete = { CHAIN4[1], CHAIN4[2], CHAIN4[3] }, active = { CHAIN4[4] }, attempted = false })
		local clears = H.spyOn(player.ghost, "clearJournalQuest")

		enterScreen(player, id)

		lu.assertEquals(#starts, 0, id .. ": startQuest calls")
		lu.assertEquals(#clears, 0, id .. ": clearJournalQuest calls")
		lu.assertEquals(T.state(player, CHAIN4[4]), "active", id .. ": 4d stays active")
	end
end

-- AC-5: mission 3 accepts the dnp 3b chain the same way
for _, id in ipairs({ "accept_third_mission", "i_was_better" }) do
	-- AC-5
	TestDuliosRenamesAccept["test_" .. id .. "_clears_delivery_no_pickup_3b_with_the_rest_of_the_chain"] = function()
		local head = tr.chains[3][1]
		local seen
		local starts = H.spyOn(_G[head], "startQuest", function(self, pPlayer) seen = T.state(pPlayer, tr.chains[3][2]) end)
		local player = pilot(3, { complete = tr.chains[3], attempted = false })

		enterScreen(player, id)

		lu.assertEquals(#starts, 1, id .. ": startQuest calls on " .. head)
		lu.assertEquals(seen, "none", id .. ": delivery_no_pickup 3b when the head started")
	end
end
