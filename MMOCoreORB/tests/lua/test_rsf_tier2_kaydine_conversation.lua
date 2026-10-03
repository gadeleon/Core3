-- Captain Kaydine (RSF tier 2) on SWG's quests: routing (on_mission, failed, reward, offer, completed, training), the
-- reward screens, the start screens, the retry of the mission 1 chain, the duty branches and the mission 1 chain at runtime.
-- Spec: .claude/work/rsf-tier2-kaydine-missions/01-spec.md (AC-6, AC-7, Conversation flow C1-C9, Content contract 4,
-- invariants I-3, I-11).
--
-- Migration is already done in every test here (the player builder seeds the marker "2"), so none of them depends on the
-- legacy names; test_rsf_tier2_kaydine_migration.lua covers those. The data-driven suites (test_trainer_fixes_routing / _retry /
-- _reset / _veterans / _chain_helper) run over the new chains through trainer_fixes_data.lua; this file adds what is specific
-- to F4. rsf-tier2-kaydine-convo: the story screens have SWG's dialogue and Imler-style ids (mission{n}_ready / _accept /
-- _failed / _complete / _reward); the failure line re-grants the mission (D-14) and mission 2 pays on its first screen.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local tr = T.TRAINERS.kaydine

local A1, A2, A3 = "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c"
local D13, R14, E15 = "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15"
local CHAIN1 = { A1, A2, A3 }
-- rsf-tier2-kaydine-duties: SWG's three duties, in the order of the duty menu (escort, recovery, destroy)
local DUTIES = { "escort_duty_naboo_privateer_9", "recovery_duty_naboo_privateer_10", "destroy_duty_naboo_privateer_11" }
local ALL_SIX = { A1, A2, A3, D13, R14, E15 }
local SKILLS_02 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }

-- mission -> { :attempted/:reward key base, head }
local KEYS = { "naboo_privateer_tier2_1a", "naboo_privateer_13", "naboo_privateer_14", "naboo_privateer_15" }
local HEADS = { A1, D13, R14, E15 }

local function pilot(n, opts) return T.player(tr, n, opts) end

-- rsf-tier2-kaydine-training (D-11, Superseded S1/S3): the state "mission n is won and paid" for a pilot who expects the next screen.
-- S1: the pilot already holds the skill that unlocks mission n + 1 (the first n + 1 tier 2 skills in SWG's order).
-- S3: after mission 4 the first three skills only, with 0 XP, so canTrain is false and the screen stays here_for_work.
local ORDER_02 = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02", "pilot_neutral_droid_02" }

local function paidSetup(n, opts)
	opts = opts or {}

	if n < 4 then
		opts.skills = { ORDER_02[n + 1] }
	else
		opts.baseSkills = { ORDER_02[1], ORDER_02[2], ORDER_02[3] }
	end

	return opts
end

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Kaydine shows a first screen")
	return transcript[1].id
end

local function handler() return H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Kaydine conversation handler") end

local function enterScreen(player, id, npc)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)
	return handler():runScreenHandlers(tmpl, player, npc or H.newNpc({}), 0, pScreen)
end

---------------------------------------------------------------------------------------------
-- The trainer data itself (the spec's chains)
---------------------------------------------------------------------------------------------

TestKaydineData = {}

function TestKaydineData:setUp() H.reset() end

-- AC-6
function TestKaydineData:test_the_trainer_data_names_the_new_chains_and_the_head_keys()
	lu.assertEquals(tr.chains, { CHAIN1, { D13 }, { R14 }, { E15 } }, "trainer_fixes_data Kaydine chains")

	for n = 1, 4 do
		lu.assertEquals(T.statusName(tr, n), KEYS[n], "the :attempted / :reward base of mission " .. n)
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: C1 on_mission
---------------------------------------------------------------------------------------------

TestKaydineRouting = {}

function TestKaydineRouting:setUp() H.reset() end

-- AC-6 C1: each story global running (with its predecessors done) keeps the pilot on the mission
local RUNNING = {
	{ A1, 1, {} }, { A2, 1, { A1 } }, { A3, 1, { A1, A2 } },
	{ D13, 2, {} }, { R14, 3, {} }, { E15, 4, {} },
}

for _, row in ipairs(RUNNING) do
	-- AC-6 C1
	TestKaydineRouting["test_" .. row[1] .. "_running_shows_on_mission_and_pays_or_starts_nothing"] = function()
		local player = pilot(row[2], { complete = row[3], active = { row[1] } })
		local rec = T.spyAllQuests()

		lu.assertEquals(firstScreen(player), "on_mission", row[1] .. ": first screen")
		lu.assertEquals(rec.rewards, {}, row[1] .. ": rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, row[1] .. ": startQuest calls")
	end
end

for _, duty in ipairs(DUTIES) do
	-- AC-6 C1
	TestKaydineRouting["test_the_tier_2_duty_" .. duty .. "_running_shows_on_mission"] = function()
		local player = pilot(1, { active = { duty } })

		lu.assertEquals(firstScreen(player), "on_mission", duty .. ": first screen")
	end
end

-- AC-6 C1: a running duty also blocks a pending reward screen
function TestKaydineRouting:test_a_running_duty_wins_over_a_pending_reward()
	local player = pilot(2, { complete = { D13 }, active = { DUTIES[1] } })

	lu.assertEquals(firstScreen(player), "on_mission", "first screen")
end

---------------------------------------------------------------------------------------------
-- AC-6: C2 failed first mission, the win of mission 1 is the chain end
---------------------------------------------------------------------------------------------

-- AC-6 C2
function TestKaydineRouting:test_1a_and_1b_complete_without_1c_is_not_a_win_and_shows_the_failed_screen()
	local player = pilot(1, { complete = { A1, A2 } })
	local rec = T.spyRewards()

	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:attempted"), "1", "setup: tier2_1a:attempted")
	lu.assertEquals(firstScreen(player), "mission1_failed", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_1a:reward"), "tier2_1a:reward")
end

-- AC-6 C2
function TestKaydineRouting:test_1a_alone_complete_shows_the_failed_screen_too()
	local player = pilot(1, { complete = { A1 } })

	lu.assertEquals(firstScreen(player), "mission1_failed", "first screen")
end

-- AC-6 C2: the failed screen needs the :attempted key
function TestKaydineRouting:test_1a_and_1b_complete_without_the_attempted_key_shows_the_offer()
	local player = pilot(1, { complete = { A1, A2 }, attempted = false })

	lu.assertEquals(firstScreen(player), "mission1_ready", "first screen")
end

-- AC-6 C2: a pilot with no quest state is offered mission 1
function TestKaydineRouting:test_a_pilot_without_quest_state_is_offered_mission_1()
	lu.assertEquals(firstScreen(pilot(1, { attempted = false })), "mission1_ready", "first screen")
end

---------------------------------------------------------------------------------------------
-- AC-6: C3 .. C7 rewards and routing after a win
---------------------------------------------------------------------------------------------

TestKaydineRewards = {}

function TestKaydineRewards:setUp() H.reset() end

-- mission, complete list, first screen of the reward state, pay screen ids, head, next screen once paid.
-- Mission 2 pays on its first screen (mission2_reward, SWG K:4194); the others pay one option later.
local WINS = {
	{ 1, CHAIN1, "mission1_complete", { "mission1_reward" }, A1, "mission2_ready" },
	{ 2, { D13 }, "mission2_reward", { "mission2_reward" }, D13, "mission3_ready" },
	{ 3, { R14 }, "mission3_complete", { "mission3_reward" }, R14, "mission4_ready" },
	{ 4, { E15 }, "mission4_complete", { "mission4_reward" }, E15, "here_for_work" },
}

for _, w in ipairs(WINS) do
	local n, complete, pending, screens, head, nextScreen = w[1], w[2], w[3], w[4], w[5], w[6]

	-- AC-6 C3/C5/C6/C7
	TestKaydineRewards["test_mission_" .. n .. "_won_and_unpaid_shows_" .. pending .. (n == 2 and "_and_pays_on_display" or "_without_paying")] = function()
		local player = pilot(n, { complete = complete })
		local rec = T.spyRewards()

		lu.assertEquals(firstScreen(player), pending, "first screen")
		lu.assertEquals(rec.rewards, n == 2 and { head } or {}, "rewardPlayer calls on the first screen")
		lu.assertEquals(H.getQuestStatus(player, KEYS[n] .. ":reward"), n == 2 and "1" or nil, KEYS[n] .. ":reward")
	end

	for _, id in ipairs(screens) do
		-- AC-6 C3/C5/C6/C7
		TestKaydineRewards["test_screen_" .. id .. "_pays_" .. head .. "_once_and_sets_the_reward_key_of_the_head"] = function()
			local player = pilot(n, { complete = complete })
			local rec = T.spyRewards()

			enterScreen(player, id)

			lu.assertEquals(rec.rewards, { head }, id .. ": rewardPlayer calls")
			lu.assertEquals(H.getQuestStatus(player, KEYS[n] .. ":reward"), "1", id .. ": " .. KEYS[n] .. ":reward")

			for m = 1, 4 do
				-- the won missions before n carry :reward = 1 from the player builder; the later ones must stay unset
				lu.assertEquals(H.getQuestStatus(player, KEYS[m] .. ":reward"), m <= n and "1" or nil, id .. ": " .. KEYS[m] .. ":reward")
			end
		end
	end

	-- AC-6 C3/C5/C6/C7: the key set by the screen ends the offer of the reward screen
	TestKaydineRewards["test_mission_" .. n .. "_is_paid_once_over_the_screen_and_two_later_visits"] = function()
		local player = pilot(n, paidSetup(n, { complete = complete }))
		local rec = T.spyRewards()

		lu.assertEquals(firstScreen(player), pending, "first visit")

		if n ~= 2 then
			-- mission 2 was paid by its first screen
			enterScreen(player, screens[1])
		end

		lu.assertEquals(firstScreen(player), nextScreen, "second visit")
		lu.assertEquals(firstScreen(player), nextScreen, "third visit")
		lu.assertEquals(rec.rewards, { head }, "rewardPlayer calls over three visits")
	end

	-- AC-6 C4: with the key already set, the complete screen is not offered
	TestKaydineRewards["test_mission_" .. n .. "_won_and_paid_does_not_offer_the_reward_screen_and_pays_nothing"] = function()
		local player = pilot(n, paidSetup(n, { complete = complete, questStatus = { [KEYS[n] .. ":reward"] = "1" } }))
		local rec = T.spyRewards()

		lu.assertEquals(firstScreen(player), nextScreen, "first screen")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	end
end

-- AC-6 C3: the win of mission 1 is 1c alone (K:129, the recursive check on the chain end)
function TestKaydineRewards:test_1c_complete_is_the_win_of_mission_1_whatever_1a_and_1b_are()
	local player = pilot(1, { complete = { A3 } })

	lu.assertEquals(firstScreen(player), "mission1_complete", "first screen")
end

-- AC-6 C3: mission 1's reward is keyed on the chain head, not on 1c
function TestKaydineRewards:test_the_reward_of_mission_1_is_the_tier2_1a_key_not_a_1c_key()
	local player = pilot(1, { complete = CHAIN1 })

	enterScreen(player, "mission1_reward")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:reward"), "1", "tier2_1a:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_1c:reward"), "tier2_1c:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_1b:reward"), "tier2_1b:reward")
end

-- AC-6 C3/C5/C6/C7: the real head pays (rewardPlayer is not spied): 5,000 credits and the item of K:208-229, once
function TestKaydineRewards:test_the_real_head_pays_5000_credits_and_its_item_through_the_reward_screen()
	local comp = "object/tangible/ship/components/"
	local items = {
		[A1] = comp .. "booster/bst_mission_reward_neutral_mandal_m_series.iff",
		[D13] = comp .. "weapon/wpn_mission_reward_neutral_hk_military_blaster.iff",
		[R14] = comp .. "shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff",
		[E15] = comp .. "droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff",
	}

	for _, w in ipairs(WINS) do
		H.reset()

		local player = pilot(w[1], { complete = w[2] })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local given = H.spyOn(SpaceHelpers, "spaceItemReward")

		enterScreen(player, w[4][1])
		lu.assertEquals(#credits, 1, w[5] .. ": spaceCreditReward calls")
		lu.assertTrue(credits[1].args[1] == player, w[5] .. ": spaceCreditReward player")
		lu.assertEquals(credits[1].args[2], 5000, w[5] .. ": credits")
		lu.assertEquals(#given, 1, w[5] .. ": spaceItemReward calls")
		lu.assertEquals(given[1].args[2], items[w[5]], w[5] .. ": item")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: C4, C8, C9
---------------------------------------------------------------------------------------------

-- AC-6 C4
function TestKaydineRouting:test_1c_complete_and_paid_with_mission_2_never_started_shows_mission2_ready()
	local player = pilot(2, { attempted = false })

	lu.assertEquals(firstScreen(player), "mission2_ready", "first screen")
end

-- AC-6 C4: the next mission's failed screen needs that mission's own key
function TestKaydineRouting:test_each_failed_screen_reads_the_attempted_key_of_its_own_mission()
	local failed = { "mission1_failed", "mission2_failed", "mission3_failed", "mission4_failed" }

	for n = 1, 4 do
		H.reset()
		lu.assertEquals(firstScreen(pilot(n, { attempted = true })), failed[n], "mission " .. n .. " with " .. KEYS[n] .. ":attempted")
	end
end

-- AC-6 C8, AC-9 (rsf-tier2-kaydine-duties D-8, reverses the F4 test): SWG's hasAllTierTwoSkills needs the mission 4 reward first, so an
-- unpaid mission 4 shows mission4_complete even with all four skills, and the tier is not raised by routing
function TestKaydineRouting:test_an_unpaid_mission_4_with_all_four_skills_shows_mission4_complete_not_completed_kaydine()
	local player = pilot(4, { complete = { E15 }, skills = SKILLS_02 })
	local rec = T.spyRewards()

	lu.assertEquals(player.ghost:getPilotTier(), 2, "setup: pilot tier")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_15:reward"), "setup: 15:reward unset")
	lu.assertEquals(firstScreen(player), "mission4_complete", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(player.ghost:getPilotTier(), 2, "pilot tier after the conversation")
end

-- AC-6 C8: the win is escort 15, not an earlier mission
function TestKaydineRouting:test_all_four_skills_with_only_recovery_14_complete_is_not_completed_kaydine()
	local player = pilot(3, { complete = { R14 }, skills = SKILLS_02 })

	lu.assertNotEquals(firstScreen(player), "completed_kaydine", "first screen")
end

-- rsf-tier2-kaydine-training: the three "prefix" tests of F4 (ready_train_pilot options named after the won mission) are replaced by the
-- SWG training port; see test_rsf_tier2_kaydine_training_routing.lua (AC-3, AC-4).

---------------------------------------------------------------------------------------------
-- AC-7: start screens
---------------------------------------------------------------------------------------------

TestKaydineStarts = {}

function TestKaydineStarts:setUp() H.reset() end

local START_SCREENS = {
	{ "mission1_accept", "mission1_accept_male", "mission1_failed" },
	{ "mission2_accept", "mission2_failed" },
	{ "mission3_accept", "mission3_failed" },
	{ "mission4_accept", "mission4_failed" },
}

-- every :attempted key a player carries
local function attemptedKeys(player)
	local out = {}

	for m = 1, 4 do
		if H.getQuestStatus(player, KEYS[m] .. ":attempted") ~= nil then
			out[#out + 1] = KEYS[m]
		end
	end

	return out
end

for n = 1, 4 do
	for _, id in ipairs(START_SCREENS[n]) do
		-- AC-7
		TestKaydineStarts["test_screen_" .. id .. "_writes_the_attempted_key_of_mission_" .. n .. "_and_starts_the_head_" .. HEADS[n]] = function()
			local player = pilot(n, { attempted = false })
			local npc = H.newNpc({})
			local starts = H.spyOn(_G[HEADS[n]], "startQuest")
			local before = attemptedKeys(player)

			enterScreen(player, id, npc)

			lu.assertEquals(H.getQuestStatus(player, KEYS[n] .. ":attempted"), "1", id .. ": " .. KEYS[n] .. ":attempted")

			local expected = {}

			for m = 1, 4 do
				if m < n then
					expected[#expected + 1] = KEYS[m]
				end
			end

			expected[#expected + 1] = KEYS[n]
			table.sort(expected)

			local got = attemptedKeys(player)

			table.sort(got)
			lu.assertEquals(got, expected, id .. ": :attempted keys of the pilot (missions before, and this one)")
			lu.assertEquals(#starts, 1, id .. ": startQuest calls on " .. HEADS[n])
			lu.assertTrue(starts[1].args[1] == player, id .. ": startQuest player")
			lu.assertEquals(#before, n - 1, "setup: attempted keys of the won missions")
		end

		-- AC-7: the real chain helper makes the head active
		TestKaydineStarts["test_screen_" .. id .. "_makes_the_head_of_mission_" .. n .. "_active"] = function()
			local player = pilot(n, { attempted = false })

			enterScreen(player, id)

			lu.assertEquals(T.state(player, HEADS[n]), "active", id .. ": " .. HEADS[n])

			for m = 1, 4 do
				if m ~= n then
					lu.assertEquals(T.state(player, HEADS[m]), m < n and "complete" or "none", id .. ": the head of mission " .. m .. " is untouched")
				end
			end
		end
	end
end

-- AC-7: the retry of mission 1 after 1a and 1b were won and 1c was not
function TestKaydineStarts:test_mission1_failed_with_1a_and_1b_complete_clears_all_three_and_starts_1a()
	local seen
	local starts = H.spyOn(_G[A1], "startQuest", function(self, pPlayer)
		seen = { T.state(pPlayer, A1), T.state(pPlayer, A2), T.state(pPlayer, A3) }
	end)
	local player = pilot(1, { complete = { A1, A2 }, attempted = false })

	enterScreen(player, "mission1_failed")

	lu.assertEquals(#starts, 1, "startQuest calls on 1a")
	lu.assertEquals(seen, { "none", "none", "none" }, "journal state of 1a, 1b, 1c when the head's startQuest ran")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:attempted"), "1", "tier2_1a:attempted")
end

-- AC-7: the same through the real helper, ending with the head active and nothing else
function TestKaydineStarts:test_mission1_failed_with_1a_and_1b_complete_ends_with_only_1a_active()
	local player = pilot(1, { complete = { A1, A2 }, attempted = false })

	enterScreen(player, "mission1_failed")
	lu.assertEquals({ T.state(player, A1), T.state(player, A2), T.state(player, A3) }, { "active", "none", "none" }, "1a, 1b, 1c")
end

-- AC-7: a running member blocks the retake
function TestKaydineStarts:test_mission1_failed_while_1b_is_active_starts_nothing_and_clears_nothing()
	local starts = H.spyOn(_G[A1], "startQuest")
	local player = pilot(1, { complete = { A1 }, active = { A2 }, attempted = false })
	local clears = H.spyOn(player.ghost, "clearJournalQuest")

	enterScreen(player, "mission1_failed")

	lu.assertEquals(#starts, 0, "startQuest calls")
	lu.assertEquals(#clears, 0, "clearJournalQuest calls")
	lu.assertEquals({ T.state(player, A1), T.state(player, A2), T.state(player, A3) }, { "complete", "active", "none" }, "1a, 1b, 1c")
end

-- AC-5 (rsf-tier2-kaydine-duties): the duty screens start SWG's duties, one each (test_rsf_tier2_kaydine_duties_conversation.lua has the detail)
function TestKaydineStarts:test_the_duty_screens_start_their_duty_quests()
	local cases = {
		{ "accept_duty_escort", DUTIES[1] },
		{ "accept_duty_recovery", DUTIES[2] },
		{ "accept_duty_destroy", DUTIES[3] },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local npc = H.newNpc({})
		local player = pilot(1, {})
		local starts = H.spyOn(H.expectGlobal(c[2], "Kaydine duty quest table (rsf-tier2-kaydine-duties)"), "startQuest")

		enterScreen(player, c[1], npc)
		lu.assertEquals(#starts, 1, c[1] .. ": startQuest calls on " .. c[2])
		lu.assertTrue(starts[1].args[1] == player and starts[1].args[2] == npc, c[1] .. ": startQuest player, npc")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: the mission 1 chain at runtime
---------------------------------------------------------------------------------------------

TestKaydineRuntime = {}

function TestKaydineRuntime:setUp() H.reset() end

local function isolateDeployments()
	for _, name in ipairs(CHAIN1) do
		H.spyOn(_G[name], "deployTargets")
	end
end

local function chainStates(player)
	return { T.state(player, A1), T.state(player, A2), T.state(player, A3) }
end

local function startEvents()
	local n = 0

	for _, e in ipairs(H.pendingEvents()) do
		if e.method == "startQuest" then
			n = n + 1
		end
	end

	return n
end

-- AC-7: accepting mission 1 in Naboo space, then completing 1a, 1b and 1c in turn
function TestKaydineRuntime:test_completing_1a_then_1b_starts_the_next_member_5_times_1050_ms_later_and_1c_starts_nothing()
	isolateDeployments()

	local player = pilot(1, { attempted = false, zone = "space_naboo", ship = true })

	enterScreen(player, "mission1_accept")
	lu.assertEquals(chainStates(player), { "active", "none", "none" }, "after accepting")
	lu.assertEquals(firstScreen(player), "on_mission", "Kaydine with 1a running")

	_G[A1]:completeQuest(player, "false")
	lu.assertEquals(chainStates(player), { "complete", "none", "none" }, "right after 1a")
	H.advance(5249)
	lu.assertEquals(chainStates(player), { "complete", "none", "none" }, "1 ms before 5 x 1050")
	H.advance(1)
	lu.assertEquals(chainStates(player), { "complete", "active", "none" }, "at 5 x 1050 ms after 1a")
	lu.assertEquals(firstScreen(player), "on_mission", "Kaydine with 1b running")

	_G[A2]:completeQuest(player, "false")
	H.advance(5249)
	lu.assertEquals(chainStates(player), { "complete", "complete", "none" }, "1 ms before 1c starts")
	H.advance(1)
	lu.assertEquals(chainStates(player), { "complete", "complete", "active" }, "at 5 x 1050 ms after 1b")
	lu.assertEquals(firstScreen(player), "on_mission", "Kaydine with 1c running")

	_G[A3]:completeQuest(player, "false")
	lu.assertEquals(startEvents(), 0, "startQuest events queued by the completion of 1c")
	H.advance(120000)
	lu.assertEquals(chainStates(player), { "complete", "complete", "complete" }, "after 1c")

	for _, name in ipairs({ D13, R14, E15 }) do
		lu.assertEquals(T.state(player, name), "none", name .. " was never started")
	end

	lu.assertEquals(firstScreen(player), "mission1_complete", "Kaydine after the chain")
end

-- AC-7: failing the middle of the chain leaves the pilot on the retry screen with the key set
function TestKaydineRuntime:test_a_pilot_who_won_1a_and_1b_and_waits_for_nothing_gets_the_failed_screen()
	isolateDeployments()

	local player = pilot(1, { attempted = false, zone = "space_naboo", ship = true })

	enterScreen(player, "mission1_accept")
	_G[A1]:completeQuest(player, "false")
	H.advance(5250)
	_G[A2]:completeQuest(player, "false")
	H.advance(5250)
	-- 1c fails through the quest's own failQuest
	lu.assertEquals(T.state(player, A3), "active", "setup: 1c is running")
	_G[A3]:failQuest(player, "false")

	lu.assertEquals(chainStates(player), { "complete", "complete", "none" }, "chain after losing 1c")
	lu.assertEquals(firstScreen(player), "mission1_failed", "Kaydine")
end
