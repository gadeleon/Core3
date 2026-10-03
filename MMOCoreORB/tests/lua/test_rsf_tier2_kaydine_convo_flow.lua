-- Captain Kaydine (RSF tier 2) on SWG's story dialogue: what the conversation does. Offers that grant at the end of the SWG chain,
-- the mission 1 gender split, the failure line that re-grants (D-14), payments on the screen where SWG has them, the mission 3
-- reward options, the tier-done line, and the handler/template agreement (dynamic part).
-- Spec: .claude/work/rsf-tier2-kaydine-convo/01-spec.md (AC-3 .. AC-8, AC-10, invariants I-4, I-5, Conversation flow C1-C10).
-- Appendix A (rsf_tier2_kaydine_convo_data.lua) is the answer key for screens, options and actions; routing is F4's (unchanged).
-- Migration is done in every pilot here (the player builder seeds the marker "2").

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier2_kaydine_convo_data")

T.load()

local tr = T.TRAINERS.kaydine

local A1, A2, A3 = "assassinate_naboo_privateer_tier2_1a", "assassinate_naboo_privateer_tier2_1b", "assassinate_naboo_privateer_tier2_1c"
local D13, R14, E15 = "destroy_naboo_privateer_13", "recovery_naboo_privateer_14", "escort_naboo_privateer_15"
local CHAIN1 = { A1, A2, A3 }
local WON = { CHAIN1, { D13 }, { R14 }, { E15 } } -- the quests that make mission n won
local SKILLS_02 = { "pilot_neutral_droid_02", "pilot_neutral_procedures_02", "pilot_neutral_starships_02", "pilot_neutral_weapons_02" }
local STORY = { A1, A2, A3, D13, R14, E15 }

local function ids(transcript)
	local out = {}

	for i, step in ipairs(transcript) do
		out[i] = step.id
	end

	return out
end

local function handler() return H.expectGlobal(H.conversationTemplateTable(tr.template).luaClassHandler, "Kaydine conversation handler") end

-- Runs runScreenHandlers for one screen, the way the observer does for a screen the player reached
local function enterScreen(player, id, npc)
	local tmpl = H.conversationTemplate(tr.template)
	local pScreen = LuaConversationTemplate(tmpl):getScreen(id)

	if pScreen == nil and id == "accept_duty_destroy2" then
		pScreen = LuaConversationTemplate(tmpl):getScreen("accept_duty_destroy1"):cloneScreen()
		pScreen.id = id
	end

	lu.assertNotNil(pScreen, "screen '" .. id .. "' is in " .. tr.template)
	return handler():runScreenHandlers(tmpl, player, npc or H.newNpc({}), 0, pScreen)
end

-- A conversation that follows `choices` and calls hook(step) after each screen that has options to pick from (step = 1, 2, ...).
-- Returns the transcript. The hook sees the state right after screen `step` was entered, before the player chooses.
local function walk(player, choices, hook)
	local list = {}

	for i, c in ipairs(choices) do
		list[#list + 1] = function() hook(i) end
		list[#list + 1] = c
	end

	list[#list + 1] = function() hook(#choices + 1) end

	return T.converse(tr, player, list)
end

local function attempted(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":attempted") end

local function headStates(player) return { T.state(player, A1), T.state(player, A2), T.state(player, A3) } end

---------------------------------------------------------------------------------------------
-- AC-3: the offer chain grants on its last screen
---------------------------------------------------------------------------------------------

TestKaydineOffers = {}

function TestKaydineOffers:setUp() H.reset() end

for n = 1, 4 do
	local chain = D.OFFER_CHAIN[n]

	-- AC-3
	TestKaydineOffers["test_mission_" .. n .. "_offer_walks_the_swg_chain_with_option_1_and_grants_only_on_" .. chain[#chain]] = function()
		local player = T.player(tr, n, { attempted = false })
		local rec = T.spyRewards()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local choices, snaps = {}, {}

		player.gender = 1 -- the female ending is the static one (mission1_accept); AC-4 covers the male split

		for i = 1, #chain - 1 do
			choices[i] = 0
		end

		local transcript = walk(player, choices, function(step)
			snaps[step] = { attempted = attempted(player, n), state = T.state(player, D.HEADS[n]), chainCalls = #chains, rewards = #rec.rewards }
		end)

		lu.assertEquals(ids(transcript), chain, "mission " .. n .. ": screens walked by option 1")
		lu.assertTrue(transcript[#transcript].stop, "mission " .. n .. ": " .. chain[#chain] .. " ends the conversation")

		for step = 1, #chain - 1 do
			lu.assertEquals(snaps[step], { attempted = nil, state = "none", chainCalls = 0, rewards = 0 }, "mission " .. n .. ": nothing granted or paid on " .. chain[step])
		end
	end

	-- AC-3
	TestKaydineOffers["test_mission_" .. n .. "_accept_screen_" .. chain[#chain] .. "_sets_attempted_and_activates_the_head"] = function()
		local player = T.player(tr, n, { attempted = false })
		local rec = T.spyRewards()
		local choices = {}

		for i = 1, #chain - 1 do
			choices[i] = 0
		end

		player.gender = 1

		local transcript = T.converse(tr, player, choices)

		lu.assertEquals(transcript[#transcript].id, chain[#chain], "mission " .. n .. ": the conversation ends on the accept screen")
		lu.assertEquals(attempted(player, n), "1", D.KEYS[n] .. ":attempted")
		lu.assertEquals(T.state(player, D.HEADS[n]), "active", D.HEADS[n])
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")

		for m = 1, 4 do
			if m ~= n then
				lu.assertEquals(T.state(player, D.HEADS[m]), m < n and "complete" or "none", "the head of mission " .. m .. " is untouched")
			end
		end
	end

	-- AC-3: "Not quite yet, sir." (option 2 of the entry line) leads to not_ready and starts nothing
	TestKaydineOffers["test_mission_" .. n .. "_ready_option_2_leads_to_not_ready_and_starts_nothing"] = function()
		local player = T.player(tr, n, { attempted = false })
		local starts = T.spyAllQuests()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local transcript = T.converse(tr, player, { 1 })

		lu.assertEquals(ids(transcript), { "mission" .. n .. "_ready", "not_ready" }, "mission " .. n .. ": screens")
		lu.assertEquals(starts.starts, {}, "startQuest calls")
		lu.assertEquals(starts.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(#chains, 0, "startSpaceQuestChain calls")
		lu.assertNil(attempted(player, n), D.KEYS[n] .. ":attempted")
	end

	-- AC-3: the entry line offers the two SWG answers
	TestKaydineOffers["test_mission_" .. n .. "_entry_line_offers_s_1b428a9f_then_s_1c2b565d"] = function()
		local transcript = T.converse(tr, T.player(tr, n, { attempted = false }))
		local texts = {}

		for i, o in ipairs(transcript[1].options) do
			texts[i] = o.text
		end

		lu.assertEquals(transcript[1].id, "mission" .. n .. "_ready", "first screen")
		lu.assertEquals(texts, { D.PREFIX .. "s_1b428a9f", D.PREFIX .. "s_1c2b565d" }, "options of the entry line")
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: mission 1 gender split
---------------------------------------------------------------------------------------------

TestKaydineGender = {}

function TestKaydineGender:setUp() H.reset() end

local function mission1Walk(gender)
	local player = T.player(tr, 1, { attempted = false })

	if gender ~= nil then
		player.gender = gender
	end

	local transcript = T.converse(tr, player, { 0, 0, 0 })

	lu.assertEquals(#transcript, 4, "mission 1 walk by option 1 (gender " .. tostring(gender) .. "): screens " .. table.concat(ids(transcript), ", "))
	return player, transcript
end

-- AC-4
function TestKaydineGender:test_a_male_pilot_is_offered_s_242_to_mission1_accept_male_and_starts_mission_1()
	local player, transcript = mission1Walk(0)

	lu.assertEquals(ids(transcript), { "mission1_ready", "mission1_offer", "mission1_brief", "mission1_accept_male" }, "screens")
	lu.assertEquals(#transcript[3].options, 1, "mission1_brief: option count")
	lu.assertEquals(transcript[3].options[1].text, D.PREFIX .. "s_242", "mission1_brief: option text")
	lu.assertEquals(transcript[3].options[1].link, "mission1_accept_male", "mission1_brief: link for a male pilot")
	lu.assertTrue(transcript[4].stop, "mission1_accept_male ends the conversation")
	lu.assertEquals(T.state(player, A1), "active", A1)
	lu.assertEquals(attempted(player, 1), "1", "tier2_1a:attempted")
end

-- AC-4
function TestKaydineGender:test_a_female_pilot_is_offered_s_242_to_mission1_accept_and_starts_mission_1()
	local player, transcript = mission1Walk(1)

	lu.assertEquals(ids(transcript), { "mission1_ready", "mission1_offer", "mission1_brief", "mission1_accept" }, "screens")
	lu.assertEquals(transcript[3].options[1].text, D.PREFIX .. "s_242", "mission1_brief: option text")
	lu.assertEquals(transcript[3].options[1].link, "mission1_accept", "mission1_brief: link for a female pilot")
	lu.assertTrue(transcript[4].stop, "mission1_accept ends the conversation")
	lu.assertEquals(T.state(player, A1), "active", A1)
	lu.assertEquals(attempted(player, 1), "1", "tier2_1a:attempted")
end

-- AC-4: the two endings are two different lines (s_244 / s_246)
function TestKaydineGender:test_the_male_and_female_endings_show_different_lines()
	local _, male = mission1Walk(0)

	H.reset()

	local _, female = mission1Walk(1)

	lu.assertNotEquals(male[4].text, female[4].text, "the last line of mission 1 for a male and a female pilot")
end

-- AC-4: the runtime link belongs to the conversation, not to the template (a male pilot first, then a female pilot)
function TestKaydineGender:test_a_male_conversation_does_not_change_the_template_link_for_the_next_female_pilot()
	mission1Walk(0)

	local tmpl = H.conversationTemplateTable(tr.template)

	for _, s in ipairs(tmpl.screens) do
		if s.id == "mission1_brief" then
			lu.assertEquals(s.options, { { D.PREFIX .. "s_242", "mission1_accept" } }, "mission1_brief template options after a male conversation")
		end
	end

	local _, female = mission1Walk(1)

	lu.assertEquals(female[4].id, "mission1_accept", "female pilot after a male pilot")
end

-- AC-4: only the mission 1 brief splits on gender
function TestKaydineGender:test_other_missions_do_not_split_on_gender()
	for n = 2, 4 do
		H.reset()

		local chain = D.OFFER_CHAIN[n]
		local choices = {}

		for i = 1, #chain - 1 do
			choices[i] = 0
		end

		local player = T.player(tr, n, { attempted = false })

		player.gender = 1
		lu.assertEquals(ids(T.converse(tr, player, choices)), chain, "mission " .. n .. ": a female pilot walks the same chain")
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: the failure line re-grants the mission (D-14)
---------------------------------------------------------------------------------------------

TestKaydineFailure = {}

function TestKaydineFailure:setUp() H.reset() end

for n = 1, 4 do
	local f = D.FAILED[n]

	-- AC-5
	TestKaydineFailure["test_a_failed_mission_" .. n .. "_shows_" .. f[1] .. "_and_the_chain_is_started_by_the_end_of_that_screen"] = function()
		local player = T.player(tr, n, { attempted = true })
		local transcript = T.converse(tr, player)

		lu.assertEquals(ids(transcript), { f[1] }, "first screen")
		lu.assertEquals(T.state(player, D.HEADS[n]), "active", D.HEADS[n] .. " right after the failure line")
		lu.assertEquals(attempted(player, n), "1", D.KEYS[n] .. ":attempted")
	end

	-- AC-5
	TestKaydineFailure["test_" .. f[1] .. "_has_one_option_" .. f[2] .. "_to_" .. f[3] .. "_which_ends_and_starts_nothing_more"] = function()
		local player = T.player(tr, n, { attempted = true })
		local rec = T.spyRewards()
		local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
		local snaps = {}
		local transcript = walk(player, { 0 }, function(step)
			snaps[step] = { chainCalls = #chains }
		end)

		lu.assertEquals(ids(transcript), { f[1], f[3] }, "screens")
		lu.assertEquals(#transcript[1].options, 1, f[1] .. ": option count")
		lu.assertEquals(transcript[1].options[1].text, D.PREFIX .. f[2], f[1] .. ": option text")
		lu.assertEquals(transcript[1].options[1].link, f[3], f[1] .. ": option link")
		lu.assertTrue(transcript[2].stop, f[3] .. " ends the conversation")
		lu.assertEquals(snaps[1], { chainCalls = 1 }, "startSpaceQuestChain calls after " .. f[1])
		lu.assertEquals(#chains, 1, "startSpaceQuestChain calls over the whole conversation")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	end

	-- AC-5: a mission that is already running cannot be started twice by the failure line
	TestKaydineFailure["test_entering_" .. f[1] .. "_while_the_head_is_active_starts_it_a_second_time_never"] = function()
		local player = T.player(tr, n, { attempted = true, active = { D.HEADS[n] } })
		local starts = H.spyOn(_G[D.HEADS[n]], "startQuest")

		enterScreen(player, f[1])

		lu.assertEquals(#starts, 0, f[1] .. ": startQuest calls on " .. D.HEADS[n] .. " while it is running")
		lu.assertEquals(T.state(player, D.HEADS[n]), "active", D.HEADS[n])
	end

	-- AC-5: and the routing sends such a pilot to on_mission, so the failure line is not even reached
	TestKaydineFailure["test_a_pilot_with_the_head_of_mission_" .. n .. "_running_sees_on_mission_not_the_failure_line"] = function()
		local player = T.player(tr, n, { attempted = true, active = { D.HEADS[n] } })

		lu.assertEquals(ids(T.converse(tr, player)), { "on_mission" }, "screens")
	end
end

-- AC-5, F4 AC-7: with 1a and 1b won and 1c absent the failure line clears the chain and starts 1a
function TestKaydineFailure:test_mission1_failed_with_1a_and_1b_complete_and_1c_absent_leaves_only_1a_active()
	local player = T.player(tr, 1, { complete = { A1, A2 } })
	local transcript = T.converse(tr, player)

	lu.assertEquals(ids(transcript), { "mission1_failed" }, "first screen")
	lu.assertEquals(headStates(player), { "active", "none", "none" }, "1a, 1b, 1c after the failure line")
	lu.assertEquals(attempted(player, 1), "1", "tier2_1a:attempted")
end

-- AC-5: 1a alone complete is the same failure
function TestKaydineFailure:test_mission1_failed_with_only_1a_complete_restarts_the_chain_at_1a()
	local player = T.player(tr, 1, { complete = { A1 } })

	lu.assertEquals(ids(T.converse(tr, player)), { "mission1_failed" }, "first screen")
	lu.assertEquals(headStates(player), { "active", "none", "none" }, "1a, 1b, 1c after the failure line")
end

-- AC-5, AC-9: a running 1b blocks the failure screen (routing) and the screen itself does not clear the chain
function TestKaydineFailure:test_mission1_failed_while_1b_is_running_starts_nothing_and_clears_nothing()
	local starts = H.spyOn(_G[A1], "startQuest")
	local player = T.player(tr, 1, { complete = { A1 }, active = { A2 } })
	local clears = H.spyOn(player.ghost, "clearJournalQuest")

	lu.assertEquals(ids(T.converse(tr, player)), { "on_mission" }, "first screen of a pilot with 1b running")
	enterScreen(player, "mission1_failed")
	lu.assertEquals(#starts, 0, "startQuest calls on 1a")
	lu.assertEquals(#clears, 0, "clearJournalQuest calls")
	lu.assertEquals(headStates(player), { "complete", "active", "none" }, "1a, 1b, 1c")
end

-- AC-5: after the re-grant the next visit is on_mission, and no second grant happens
function TestKaydineFailure:test_the_visit_after_a_failure_line_shows_on_mission_and_starts_nothing_more()
	local player = T.player(tr, 2, { attempted = true })

	T.converse(tr, player)

	local rec = T.spyAllQuests()

	lu.assertEquals(ids(T.converse(tr, player)), { "on_mission" }, "second visit")
	lu.assertEquals(rec.starts, {}, "startQuest calls on the second visit")
end

---------------------------------------------------------------------------------------------
-- AC-6: rewards
---------------------------------------------------------------------------------------------

TestKaydineRewards = {}

function TestKaydineRewards:setUp() H.reset() end

-- mission, choices after the first screen, the screens they reach
local PATHS = {
	{ 1, { 0, 0 }, { "mission1_complete", "mission1_reward", "mission1_reward_modest" } },
	{ 1, { 0, 1, 0 }, { "mission1_complete", "mission1_reward", "mission1_reward_more", "mission1_reward_joke" } },
	{ 1, { 0, 1, 1 }, { "mission1_complete", "mission1_reward", "mission1_reward_more", "mission1_reward_thanks" } },
	{ 2, { 0 }, { "mission2_reward", "mission2_reward_modest" } },
	{ 2, { 1 }, { "mission2_reward", "mission2_reward_proud" } },
	{ 3, { 0, 0 }, { "mission3_complete", "mission3_reward", "mission3_reward_end" } },
	{ 4, { 0, 0 }, { "mission4_complete", "mission4_reward", "mission4_reward_dulios" } },
	{ 4, { 0, 1 }, { "mission4_complete", "mission4_reward", "mission4_reward_end" } },
}

for _, p in ipairs(PATHS) do
	local n, choices, screens = p[1], p[2], p[3]
	local name = screens[#screens]

	-- AC-6
	TestKaydineRewards["test_mission_" .. n .. "_reward_path_to_" .. name .. "_pays_the_head_exactly_once_on_" .. D.REWARD[n].pay] = function()
		local player = T.player(tr, n, { complete = WON[n] })
		local rec = T.spyRewards()
		local snaps = {}
		local transcript = walk(player, choices, function(step)
			snaps[step] = #rec.rewards
		end)

		lu.assertEquals(ids(transcript), screens, "mission " .. n .. ": screens")

		-- the number of payments after each screen: 0 until the pay screen, then 1
		local paidAt
		local expected = {}

		for i, id in ipairs(screens) do
			paidAt = paidAt or (id == D.REWARD[n].pay and i or nil)
			expected[i] = (paidAt and i >= paidAt) and 1 or 0
		end

		-- the hook runs after every screen that has options (all but the last, which ends the conversation)
		for i = 1, #choices do
			lu.assertEquals(snaps[i], expected[i], "mission " .. n .. ": rewardPlayer calls after " .. screens[i])
		end

		lu.assertEquals(rec.rewards, { D.HEADS[n] }, "mission " .. n .. ": rewardPlayer calls over the whole conversation")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[n] .. ":reward"), "1", D.KEYS[n] .. ":reward")
	end
end

for n = 1, 4 do
	local r = D.REWARD[n]

	-- AC-6: M1, M3, M4 are not paid by their first screen; M2 is
	TestKaydineRewards["test_mission_" .. n .. "_first_screen_" .. r.first .. (n == 2 and "_pays_at_once" or "_pays_nothing")] = function()
		local player = T.player(tr, n, { complete = WON[n] })
		local rec = T.spyRewards()

		lu.assertEquals(ids(T.converse(tr, player)), { r.first }, "first screen")
		lu.assertEquals(rec.rewards, n == 2 and { D13 } or {}, "rewardPlayer calls on the first screen")
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[n] .. ":reward"), n == 2 and "1" or nil, D.KEYS[n] .. ":reward after the first screen")
	end

	-- AC-6: a second conversation shows the next state's first screen and pays nothing
	TestKaydineRewards["test_after_paying_mission_" .. n .. "_the_next_visit_shows_" .. D.AFTER_PAID[n] .. "_and_pays_nothing"] = function()
		local player = T.player(tr, n, { complete = WON[n] })
		local rec = T.spyRewards()

		-- the pay screen is the first screen for mission 2, and one option away for the others; the tail is option 1
		local first = T.converse(tr, player, n == 2 and {} or { 0, 0 })

		lu.assertEquals(first[1].id, r.first, "setup: first screen of the reward state")
		lu.assertEquals(first[#first].id ~= r.first or n == 2, true, "setup: the conversation walked on to the pay screen")
		lu.assertEquals(rec.rewards, { D.HEADS[n] }, "setup: paid once")

		for visit = 1, 2 do
			lu.assertEquals(ids(T.converse(tr, player)), { D.AFTER_PAID[n] }, "visit " .. visit .. " after the payment")
		end

		lu.assertEquals(rec.rewards, { D.HEADS[n] }, "rewardPlayer calls over three conversations")
	end

	-- AC-6: the pay screen alone pays and writes the key of the head; later missions' keys stay unset
	TestKaydineRewards["test_entering_" .. r.pay .. "_pays_" .. D.HEADS[n] .. "_and_sets_only_its_reward_key"] = function()
		local player = T.player(tr, n, { complete = WON[n] })
		local rec = T.spyRewards()

		enterScreen(player, r.pay)

		lu.assertEquals(rec.rewards, { D.HEADS[n] }, r.pay .. ": rewardPlayer calls")

		for m = 1, 4 do
			lu.assertEquals(H.getQuestStatus(player, D.KEYS[m] .. ":reward"), m <= n and "1" or nil, r.pay .. ": " .. D.KEYS[m] .. ":reward")
		end
	end

	-- AC-6: no tail screen pays
	for _, tail in ipairs(r.tails) do
		TestKaydineRewards["test_entering_the_tail_screen_" .. tail .. "_pays_nothing"] = function()
			local player = T.player(tr, n, { complete = WON[n] })
			local rec = T.spyRewards()

			enterScreen(player, tail)
			lu.assertEquals(rec.rewards, {}, tail .. ": rewardPlayer calls")
			lu.assertNil(H.getQuestStatus(player, D.KEYS[n] .. ":reward"), tail .. ": " .. D.KEYS[n] .. ":reward")
		end
	end
end

-- AC-6: the real head pays 5,000 credits and its item through the pay screen (not through a spy), once
function TestKaydineRewards:test_the_real_heads_pay_5000_credits_and_their_item_on_the_pay_screens()
	local comp = "object/tangible/ship/components/"
	local items = {
		comp .. "booster/bst_mission_reward_neutral_mandal_m_series.iff",
		comp .. "weapon/wpn_mission_reward_neutral_hk_military_blaster.iff",
		comp .. "shield_generator/shd_mission_reward_neutral_koensayr_ds23.iff",
		comp .. "droid_interface/ddi_mission_reward_neutral_sorosuub_w19.iff",
	}

	for n = 1, 4 do
		H.reset()

		local player = T.player(tr, n, { complete = WON[n] })
		local credits = H.spyOn(SpaceHelpers, "spaceCreditReward")
		local given = H.spyOn(SpaceHelpers, "spaceItemReward")

		T.converse(tr, player, n == 2 and {} or { 0, 0 })
		lu.assertEquals(#credits, 1, D.HEADS[n] .. ": spaceCreditReward calls")
		lu.assertEquals(credits[1].args[2], 5000, D.HEADS[n] .. ": credits")
		lu.assertEquals(#given, 1, D.HEADS[n] .. ": spaceItemReward calls")
		lu.assertEquals(given[1].args[2], items[n], D.HEADS[n] .. ": item")
	end
end

-- AC-6: mission 1's win is 1c alone, whatever 1a and 1b are
function TestKaydineRewards:test_1c_complete_shows_mission1_complete_and_pays_the_tier2_1a_key()
	local player = T.player(tr, 1, { complete = { A3 } })

	lu.assertEquals(ids(T.converse(tr, player, { 0 })), { "mission1_complete", "mission1_reward" }, "screens")
	lu.assertEquals(H.getQuestStatus(player, "naboo_privateer_tier2_1a:reward"), "1", "tier2_1a:reward")
	lu.assertNil(H.getQuestStatus(player, "naboo_privateer_tier2_1c:reward"), "tier2_1c:reward")
end

-- AC-6: paying M4 and then holding all four _02 skills makes the next first screen the tier-done line
function TestKaydineRewards:test_paying_mission_4_and_then_holding_all_four_skills_leads_to_completed_kaydine()
	local player = T.player(tr, 4, { complete = { E15 } })
	local rec = T.spyRewards()

	lu.assertEquals(ids(T.converse(tr, player, { 0, 0 })), { "mission4_complete", "mission4_reward", "mission4_reward_dulios" }, "screens")

	for _, skill in ipairs(SKILLS_02) do
		player.skills[skill] = true
	end

	lu.assertEquals(ids(T.converse(tr, player)), { "completed_kaydine" }, "next first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier")
	lu.assertEquals(rec.rewards, { E15 }, "rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- AC-7: mission 3 reward options
---------------------------------------------------------------------------------------------

TestKaydineMission3Reward = {}

function TestKaydineMission3Reward:setUp() H.reset() end

local function optionsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { o.text, o.link }
	end

	return out
end

local function canTrain(player)
	player.ghost.experience.space_combat_general = 100000
end

-- AC-7
function TestKaydineMission3Reward:test_a_pilot_who_can_train_is_offered_s_78_and_s_45d20070_to_the_training_screen()
	local player = T.player(tr, 3, { complete = { R14 } })

	canTrain(player)

	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward" }, "screens")
	lu.assertEquals(optionsOf(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_45d20070", "ready_train_pilot" } }, "mission3_reward options")
end

-- AC-7
function TestKaydineMission3Reward:test_choosing_s_45d20070_shows_ready_train_pilot_with_the_mission4_training_options()
	local player = T.player(tr, 3, { complete = { R14 } })

	canTrain(player)

	local transcript = T.converse(tr, player, { 0, "s_45d20070" })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "ready_train_pilot" }, "screens")

	local links = {}

	for i, o in ipairs(transcript[3].options) do
		links[i] = o.link
	end

	table.sort(links)
	lu.assertEquals(links, { "mission4_train_algorithms", "mission4_train_components", "mission4_train_techniques" }, "training option links")
end

-- AC-7
function TestKaydineMission3Reward:test_a_pilot_who_cannot_train_is_offered_s_78_and_s_6114e8b7_to_the_duty_line()
	local player = T.player(tr, 3, { complete = { R14 } })
	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward" }, "screens")
	lu.assertEquals(optionsOf(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_6114e8b7", "mission3_reward_duty" } }, "mission3_reward options")
end

-- AC-7: a pilot who already holds all four skills (tier 2 complete) cannot train, however much experience it has
function TestKaydineMission3Reward:test_a_pilot_with_all_four_tier2_skills_gets_the_duty_option_even_with_experience()
	local player = T.player(tr, 3, { complete = { R14 }, skills = SKILLS_02 })

	canTrain(player)

	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward" }, "screens")
	lu.assertEquals(optionsOf(transcript[2]), { { D.PREFIX .. "s_78", "mission3_reward_end" }, { D.PREFIX .. "s_6114e8b7", "mission3_reward_duty" } }, "mission3_reward options")
end

-- AC-7: s_78 ends the reward chain with SWG's line
function TestKaydineMission3Reward:test_s_78_leads_to_mission3_reward_end_which_ends_the_conversation()
	local transcript = T.converse(tr, T.player(tr, 3, { complete = { R14 } }), { 0, "s_78" })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "mission3_reward_end" }, "screens")
	lu.assertTrue(transcript[3].stop, "mission3_reward_end ends the conversation")
end

-- AC-7: the duty line shows SWG's s_7bc9bef7 with the three duty options
function TestKaydineMission3Reward:test_the_duty_line_offers_the_three_duty_options_of_swg()
	local transcript = T.converse(tr, T.player(tr, 3, { complete = { R14 } }), { 0, "s_6114e8b7" })

	lu.assertEquals(ids(transcript), { "mission3_complete", "mission3_reward", "mission3_reward_duty" }, "screens")
	lu.assertEquals(optionsOf(transcript[3]), {
		{ D.PREFIX .. "s_9b73da8", "accept_duty_escort" },
		{ D.PREFIX .. "s_30297e22", "accept_duty_recovery" },
		{ D.PREFIX .. "s_c892e540", "accept_duty_destroy1" },
	}, "mission3_reward_duty options")
end

-- AC-7: each duty option starts the same duty quest as the same option sid on duty_options does today
local DUTY_OPTIONS = {
	{ "s_c892e540", "accept_duty_destroy1", "destroy_duty_naboo_privateer_9" },
	{ "s_9b73da8", "accept_duty_escort", "escort_duty_naboo_privateer_10" },
}

for _, d in ipairs(DUTY_OPTIONS) do
	TestKaydineMission3Reward["test_option_" .. d[1] .. "_on_the_duty_line_starts_" .. d[3] .. "_like_duty_options"] = function()
		local starts = H.spyOn(_G[d[3]], "startQuest")
		local player = T.player(tr, 3, { complete = { R14 } })
		local transcript = T.converse(tr, player, { 0, "s_6114e8b7", d[1] })

		lu.assertEquals(transcript[#transcript].id, d[2], "last screen")
		lu.assertEquals(#starts, 1, d[3] .. ": startQuest calls")

		-- the same option sid on duty_options (today's duty menu) starts the same quest
		H.reset()

		local viaMenu = H.spyOn(_G[d[3]], "startQuest")
		local menu

		for _, sc in ipairs(H.conversationTemplateTable(tr.template).screens) do
			if sc.id == "duty_options" then menu = sc end
		end

		local link

		for _, o in ipairs(menu.options) do
			if o[1] == D.PREFIX .. d[1] then link = o[2] end
		end

		lu.assertEquals(link, d[2], "duty_options: link of " .. d[1])
		enterScreen(T.player(tr, 1, {}), link)
		lu.assertEquals(#viaMenu, 1, d[3] .. ": startQuest calls through duty_options (today)")
	end
end

-- AC-7
function TestKaydineMission3Reward:test_option_s_30297e22_on_the_duty_line_sends_the_recovery_duty_message_like_duty_options()
	local player = T.player(tr, 3, { complete = { R14 } })
	local rec = T.spyAllQuests()
	local before = #H.messageLog(player)
	local transcript = T.converse(tr, player, { 0, "s_6114e8b7", "s_30297e22" })

	lu.assertEquals(transcript[#transcript].id, "accept_duty_recovery", "last screen")

	local log = H.messageLog(player)

	lu.assertEquals(log[#log].id, "Recovery Duty Missions are not implemented yet!", "last system message")
	lu.assertEquals(#log, before + 1, "messages sent")

	for _, started in ipairs(rec.starts) do
		lu.assertNotEquals(started, "destroy_duty_naboo_privateer_9", "no duty quest is started by the recovery option")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: tier done
---------------------------------------------------------------------------------------------

TestKaydineTierDone = {}

function TestKaydineTierDone:setUp() H.reset() end

-- AC-8
function TestKaydineTierDone:test_all_four_skills_and_mission_4_won_show_completed_kaydine_and_raise_the_tier_to_3()
	local player = T.player(tr, 4, { complete = { E15 }, skills = SKILLS_02 })
	local rec = T.spyRewards()

	lu.assertEquals(player.ghost:getPilotTier(), 2, "setup: pilot tier")

	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "completed_kaydine", "completed_kaydine_end" }, "screens")
	lu.assertEquals(transcript[1].text, D.PREFIX .. "s_2d86b58b", "completed_kaydine line")
	lu.assertEquals(optionsOf(transcript[1]), { { D.PREFIX .. "s_32c46e00", "completed_kaydine_end" } }, "completed_kaydine options")
	lu.assertEquals(transcript[2].text, D.PREFIX .. "s_aa83c988", "completed_kaydine_end line")
	lu.assertTrue(transcript[2].stop, "completed_kaydine_end ends the conversation")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier after the conversation")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-8
function TestKaydineTierDone:test_a_pilot_of_tier_4_sees_finished_tier3_with_the_same_follow_up()
	local player = T.player(tr, 4, { complete = { E15 }, skills = SKILLS_02 })

	player.ghost:setPilotTier(4)

	local transcript = T.converse(tr, player, { 0 })

	lu.assertEquals(ids(transcript), { "finished_tier3", "completed_kaydine_end" }, "screens")
	lu.assertEquals(transcript[1].text, D.PREFIX .. "s_2d86b58b", "finished_tier3 line")
	lu.assertEquals(optionsOf(transcript[1]), { { D.PREFIX .. "s_32c46e00", "completed_kaydine_end" } }, "finished_tier3 options")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier is not changed")
end

---------------------------------------------------------------------------------------------
-- AC-9: neighbours unchanged
---------------------------------------------------------------------------------------------

TestKaydineNeighbours = {}

function TestKaydineNeighbours:setUp() H.reset() end

-- AC-9: the first screens of routing for the new ids (F4 Conversation flow C1-C9)
function TestKaydineNeighbours:test_the_first_screen_of_every_state_uses_the_new_ids()
	local cases = {
		{ "mission1 never offered", T.player(tr, 1, { attempted = false }), "mission1_ready" },
		{ "mission1 attempted", T.player(tr, 1, {}), "mission1_failed" },
		{ "mission1 won", T.player(tr, 1, { complete = CHAIN1 }), "mission1_complete" },
		{ "mission2 offered", T.player(tr, 2, { attempted = false }), "mission2_ready" },
		{ "mission2 attempted", T.player(tr, 2, {}), "mission2_failed" },
		{ "mission2 won", T.player(tr, 2, { complete = { D13 } }), "mission2_reward" },
		{ "mission3 offered", T.player(tr, 3, { attempted = false }), "mission3_ready" },
		{ "mission3 attempted", T.player(tr, 3, {}), "mission3_failed" },
		{ "mission3 won", T.player(tr, 3, { complete = { R14 } }), "mission3_complete" },
		{ "mission4 offered", T.player(tr, 4, { attempted = false }), "mission4_ready" },
		{ "mission4 attempted", T.player(tr, 4, {}), "mission4_failed" },
		{ "mission4 won", T.player(tr, 4, { complete = { E15 } }), "mission4_complete" },
	}

	for _, c in ipairs(cases) do
		lu.assertEquals(T.converse(tr, c[2])[1].id, c[3], c[1] .. ": first screen")
	end
end

-- AC-9: the duty screens start the same duty globals as at 74247cbede
function TestKaydineNeighbours:test_the_duty_screens_still_start_their_duty_quests_and_recovery_only_sends_its_message()
	local cases = { { "accept_duty_destroy1", "destroy_duty_naboo_privateer_9" }, { "accept_duty_escort", "escort_duty_naboo_privateer_10" }, { "accept_duty_destroy2", "destroy_duty_naboo_privateer_11" } }

	for _, c in ipairs(cases) do
		H.reset()

		local npc = H.newNpc({})
		local player = T.player(tr, 1, {})
		local starts = H.spyOn(_G[c[2]], "startQuest")

		enterScreen(player, c[1], npc)
		lu.assertEquals(#starts, 1, c[1] .. ": startQuest calls on " .. c[2])
		lu.assertTrue(starts[1].args[1] == player and starts[1].args[2] == npc, c[1] .. ": startQuest player, npc")
	end
end

-- AC-9: ready_train_pilot keeps its prefixes
function TestKaydineNeighbours:test_ready_train_pilot_prefixes_still_follow_the_won_mission()
	local cases = {
		{ T.player(tr, 1, { complete = { A1 } }), "initial_" },
		{ T.player(tr, 2, {}), "mission2_" },
		{ T.player(tr, 3, { win = { 1, 2 } }), "mission3_" },
		{ T.player(tr, 4, { win = { 1, 2, 3 } }), "mission4_" },
	}

	for _, c in ipairs(cases) do
		c[1].ghost.experience.space_combat_general = 100000

		local transcript = T.converse(tr, c[1])

		lu.assertEquals(transcript[1].id, "ready_train_pilot", c[2] .. ": first screen")
		lu.assertEquals(transcript[1].options[1].link:sub(1, #c[2]), c[2], c[2] .. ": prefix of the first training option")
	end
end

---------------------------------------------------------------------------------------------
-- AC-10: only the listed screens pay or start (I-4, I-5), recorded while entering every screen
---------------------------------------------------------------------------------------------

TestKaydineHandlerSpy = {}

function TestKaydineHandlerSpy:setUp() H.reset() end

local function stateBuilders()
	local out = {
		{ "C3", function() return T.player(tr, 4, { complete = { E15 } }) end },
		{ "C4", function() return T.player(tr, 3, { complete = { R14 } }) end },
		{ "C5", function() return T.player(tr, 2, { complete = { D13 } }) end },
		{ "C6", function() return T.player(tr, 1, { complete = CHAIN1 }) end },
		{ "C7", function() local p = T.player(tr, 1, { attempted = false }); p.ghost.experience.space_combat_general = 100000; return p end },
	}

	for n = 1, 4 do
		out[#out + 1] = { "C8 m" .. n, function() return T.player(tr, n, { attempted = true }) end }
		out[#out + 1] = { "C9 m" .. n, function() return T.player(tr, n, { attempted = false }) end }
	end

	return out
end

-- Enters every screen of the template for a fresh pilot of each state; returns screen id ->
--   { rewards = {head = true}, chains = {head = true}, starts = {story head = true}, attempted = {n = true}, reward = {n = true} }
-- where attempted / reward hold the missions whose :attempted / :reward key the screen changed
local function recordAllScreens()
	local rec = {}

	for _, st in ipairs(stateBuilders()) do
		for _, screen in ipairs(H.conversationTemplateTable(tr.template).screens) do
			H.reset()

			local player = st[2]()
			local calls = { rewards = {}, starts = {} }

			for _, name in ipairs(STORY) do
				H.spyOn(_G[name], "rewardPlayer", function() calls.rewards[#calls.rewards + 1] = name end)
				H.spyOn(_G[name], "startQuest", function() calls.starts[#calls.starts + 1] = name end)
			end

			local chains = H.spyOn(SpaceHelpers, "startSpaceQuestChain")
			local before = { attempted = {}, reward = {} }

			for n = 1, 4 do
				before.attempted[n] = H.getQuestStatus(player, D.KEYS[n] .. ":attempted")
				before.reward[n] = H.getQuestStatus(player, D.KEYS[n] .. ":reward")
			end

			enterScreen(player, screen.id)

			local entry = rec[screen.id] or { rewards = {}, chains = {}, starts = {}, attempted = {}, reward = {} }

			rec[screen.id] = entry

			for _, name in ipairs(calls.rewards) do entry.rewards[name] = true end
			for _, name in ipairs(calls.starts) do entry.starts[name] = true end
			for _, c in ipairs(chains) do entry.chains[c.args[3]] = true end

			for n = 1, 4 do
				if H.getQuestStatus(player, D.KEYS[n] .. ":attempted") ~= before.attempted[n] then entry.attempted[n] = true end
				if H.getQuestStatus(player, D.KEYS[n] .. ":reward") ~= before.reward[n] then entry.reward[n] = true end
			end
		end
	end

	return rec
end

local function sortedSet(set)
	local out = {}

	for k in pairs(set) do out[#out + 1] = k end

	table.sort(out)
	return out
end

-- AC-10, I-4: only the four pay screens call a story head's rewardPlayer, each its own head, and only they write a :reward key
function TestKaydineHandlerSpy:test_only_the_four_pay_screens_pay_and_each_pays_its_own_head()
	local rec = recordAllScreens()

	for id, entry in pairs(rec) do
		local n = D.PAYS[id]

		lu.assertEquals(sortedSet(entry.rewards), n and { D.HEADS[n] } or {}, "screen '" .. id .. "': story heads paid when entered")
		lu.assertEquals(sortedSet(entry.reward), n and { n } or {}, "screen '" .. id .. "': missions whose :reward key it wrote")
	end

	for id in pairs(D.PAYS) do
		lu.assertNotNil(rec[id], "pay screen '" .. id .. "' is in the template")
	end
end

-- AC-10, I-5: only the start screens call startSpaceQuestChain (each with its own head), write an :attempted key, and none starts a
-- story head directly
function TestKaydineHandlerSpy:test_only_the_start_screens_start_a_chain_and_each_starts_its_own_head()
	local rec = recordAllScreens()

	for id, entry in pairs(rec) do
		local n = D.STARTS[id]

		lu.assertEquals(sortedSet(entry.chains), n and { D.HEADS[n] } or {}, "screen '" .. id .. "': heads passed to startSpaceQuestChain")
		lu.assertEquals(sortedSet(entry.starts), {}, "screen '" .. id .. "': story heads started directly by startQuest (only startSpaceQuestChain may start them)")
		lu.assertEquals(sortedSet(entry.attempted), n and { n } or {}, "screen '" .. id .. "': missions whose :attempted key it wrote")
	end

	for id in pairs(D.STARTS) do
		lu.assertNotNil(rec[id], "start screen '" .. id .. "' is in the template")
	end
end

-- AC-10, I-5: each start screen really starts its own mission (real chain helper)
function TestKaydineHandlerSpy:test_each_start_screen_makes_the_head_of_its_mission_active()
	for id, n in pairs(D.STARTS) do
		H.reset()

		local player = T.player(tr, n, { attempted = false })

		enterScreen(player, id)
		lu.assertEquals(H.getQuestStatus(player, D.KEYS[n] .. ":attempted"), "1", id .. ": " .. D.KEYS[n] .. ":attempted")
		lu.assertEquals(T.state(player, D.HEADS[n]), "active", id .. ": " .. D.HEADS[n])
	end
end
