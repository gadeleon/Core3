-- Warvog Arkon (Havoc Squadron tier 4 trainer): conversation behavior against engine fakes.
-- Spec: .claude/work/havoc-tier4-arkon/01-spec.md (AC-3 .. AC-8, invariant I-4).
--
-- Quest starts and rewards are observed by replacing startQuest / rewardPlayer on every quest
-- global with a recorder (H.spyOn): the real startQuest needs datapad and mission fakes that don't
-- exist, and nothing here is about what a quest does once started.

local lu = require("luaunit")
local H = require("harness")
local D = require("havoc_tier4_data")
local Swgjava = require("harness.swgjava")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("HavocSquadronScreenplay", function() H.loadSquadron("HavocSquadronScreenplay") end)
tryLoad("arkon_convo.lua", function() H.loadMobile("conversations/space/rebel/havoc_squadron/arkon_convo.lua") end)
tryLoad("arkonConvoHandler.lua", function() H.loadScreenplay("space/conversations/rebel/havoc_squadron/arkonConvoHandler.lua") end)

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/corellia_rebel_tier4.java")

local XP_FOR_TIER4 = 1000000

---------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------

local function converse(player, choices)
	lu.assertNotNil(H.conversationTemplateTable("arkon_convo"), "arkon_convo is not registered via addConversationTemplate. Load problems: " .. table.concat(loadErrors, " | "))

	return H.converse({ template = "arkon_convo", player = player, npc = H.newNpc({ name = "Warvog Arkon" }), choices = choices })
end

local function firstScreen(player)
	return converse(player)[1].id
end

local function ids(transcript)
	local out = {}

	for i, t in ipairs(transcript) do
		out[i] = t.id
	end

	return out
end

local function contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end

	return false
end

-- Journal/status history of missions 1..n done: attempted, winning child complete, reward paid.
local function history(n)
	local h = { rewards = {}, attempted = {}, completed = {} }

	for i = 1, n do
		h.rewards[i] = i
		h.attempted[i] = i
		h.completed[#h.completed + 1] = D.MISSION[i].wins[1]
	end

	return h
end

-- opts: skillCount (first k tier 4 skills) or tier4 (explicit list), hist (n), plus any D.havoc opts,
-- where explicit rewards/attempted/completed replace the ones derived from hist.
local function pilot(opts)
	opts = opts or {}

	local args = {}

	for k, v in pairs(opts) do
		args[k] = v
	end

	if opts.skillCount then
		args.tier4 = {}

		for i = 1, opts.skillCount do
			args.tier4[i] = D.SKILLS[i]
		end
	end

	if opts.hist then
		local h = history(opts.hist)

		args.rewards = opts.rewards or h.rewards
		args.attempted = opts.attempted or h.attempted
		args.completed = opts.completed or h.completed
	end

	return D.havoc(args)
end

-- Spies on every quest global. rec.starts / rec.rewards: global names in call order.
-- rec.completeAtStart[i]: quest globals whose journal entry was complete when start i happened.
local function spyAllQuests()
	local rec = { starts = {}, rewards = {}, resets = {}, completeAtStart = {} }

	for _, name in ipairs(H.questGlobals()) do
		local quest = rawget(_G, name)

		H.spyOn(quest, "startQuest", function(self, pPlayer)
			rec.starts[#rec.starts + 1] = name

			local complete = {}

			for _, key in ipairs(D.QUEST_KEYS) do
				if SpaceHelpers:isSpaceQuestComplete(pPlayer, D.QUEST[key][1], D.QUEST[key][2]) then
					complete[#complete + 1] = D.global(key)
				end
			end

			rec.completeAtStart[#rec.starts] = complete
		end)

		H.spyOn(quest, "rewardPlayer", function() rec.rewards[#rec.rewards + 1] = name end)
		H.spyOn(quest, "resetQuest", function() rec.resets[#rec.resets + 1] = name end)
	end

	return rec
end

local function rebel(player)
	return player.ghost:getFactionStanding("rebel")
end

local function setComplete(player, keys)
	for _, key in ipairs(keys) do
		player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
	end
end

-- Option sids that lead from the NPC line shown by screen id `fromId` to the one shown by `toId`
-- (BFS over the SWG java graph, so every conditional successor counts as reachable).
local function pathBetween(fromId, toId)
	local path = GRAPH.pathTo(D.SCREENS[fromId] or fromId, D.SCREENS[toId] or toId)

	lu.assertNotNil(path, "answer key: no option path from " .. fromId .. " to " .. toId)
	return path
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

local function zeros(n)
	local out = {}

	for i = 1, n do
		out[i] = 0
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-3: routing
---------------------------------------------------------------------------------------------

TestArkonRouting = {}

function TestArkonRouting:setUp()
	H.reset()
end

local function corsecPilot()
	local skills = {}

	for _, s in ipairs(D.SKILLS) do
		for tier = 1, 3 do
			skills[#skills + 1] = "pilot_rebel_navy_" .. s .. "_0" .. tier
		end
	end

	return H.newPlayer({ pilot = "rebel", squadronType = rawget(_G, "CORSEC_SQUADRON"), skills = skills, pilotTier = 4 })
end

-- name, builder, expected first screen, optional pre-step
local ROUTES = {
	{ "no_pilot_skill_gets_not_pilot", function() return H.newPlayer({}) end, "not_pilot" },
	{ "jtl_disabled_gets_not_pilot", function() H.Engine.config.jtlEnabled = false; return pilot({ skillCount = 1, hist = 0 }) end, "not_pilot" },
	{ "neutral_pilot_gets_wrong_faction", function() return H.newPlayer({ pilot = "neutral" }) end, "wrong_faction" },
	{ "imperial_pilot_gets_wrong_faction", function() return H.newPlayer({ pilot = "imperial" }) end, "wrong_faction" },
	{ "rebel_pilot_of_another_squadron_gets_not_my_track", corsecPilot, "not_my_track" },
	{ "havoc_pilot_with_three_of_four_tier3_skills_gets_not_ready", function() return pilot({ noTier3 = true, pilotTier = 3 }) end, "not_ready" },
	{ "negative_rebel_standing_gets_negative_faction", function() return pilot({ standing = -1, skillCount = 1, hist = 0 }) end, "negative_faction" },
	{ "zero_rebel_standing_is_not_negative", function() return pilot({ standing = 0, skillCount = 1, hist = 0 }) end, "mission1_offer" },

	{ "mission1_won_with_1a_pays_reward_1", function() return pilot({ skillCount = 1, completed = { "m1a" } }) end, "mission1_reward" },
	{ "mission1_won_with_1b_pays_reward_1", function() return pilot({ skillCount = 1, completed = { "m1b" } }) end, "mission1_reward" },
	{ "mission2_won_with_2a_pays_reward_2", function() return pilot({ skillCount = 2, hist = 1, completed = { "m1a", "m2a" } }) end, "mission2_reward" },
	{ "mission2_won_with_2b_pays_reward_2", function() return pilot({ skillCount = 2, hist = 1, completed = { "m1a", "m2b" } }) end, "mission2_reward" },
	{ "mission3_won_with_3a_pays_reward_3", function() return pilot({ skillCount = 3, hist = 2, completed = { "m1a", "m2a", "m3a" } }) end, "mission3_reward" },
	{ "mission3_won_with_3b_pays_reward_3", function() return pilot({ skillCount = 3, hist = 2, completed = { "m1a", "m2a", "m3b" } }) end, "mission3_reward" },
	{ "mission4_won_with_4c_pays_reward_4", function() return pilot({ skillCount = 4, hist = 3, completed = { "m1a", "m2a", "m3a", "m4c" } }) end, "mission4_reward" },
	{ "mission4_children_4a_and_4b_alone_do_not_win_mission_4", function() return pilot({ skillCount = 4, hist = 3, completed = { "m1a", "m2a", "m3a", "m4a", "m4b" } }) end, "mission4_offer" },

	{ "mission1_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 1, attempted = { 1 } }) end, "mission1_failed" },
	{ "mission2_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 } }) end, "mission2_failed" },
	{ "mission3_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 } }) end, "mission3_failed" },
	{ "mission4_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 } }) end, "mission4_failed" },
	{ "an_attempted_mission_that_was_won_and_paid_is_not_failed", function() return pilot({ skillCount = 1, hist = 1, met = true }) end, "tier4_incomplete" },

	{ "one_tier4_skill_and_no_reward_1_offers_mission1", function() return pilot({ skillCount = 1, rewards = {} }) end, "mission1_offer" },
	{ "one_tier4_skill_after_a_full_mission1_history_offers_mission1_when_unpaid", function() return pilot({ skillCount = 1, hist = 0 }) end, "mission1_offer" },
	{ "two_skills_and_reward_1_unpaid_still_offers_mission1", function() return pilot({ skillCount = 2, rewards = {} }) end, "mission1_offer" },
	{ "two_skills_and_reward_1_offers_mission2", function() return pilot({ skillCount = 2, rewards = { 1 } }) end, "mission2_offer" },
	{ "two_skills_after_a_realistic_history_offers_mission2", function() return pilot({ skillCount = 2, hist = 1 }) end, "mission2_offer" },
	{ "three_skills_and_rewards_1_and_2_offers_mission3", function() return pilot({ skillCount = 3, rewards = { 1, 2 } }) end, "mission3_offer" },
	{ "three_skills_after_a_realistic_history_offers_mission3", function() return pilot({ skillCount = 3, hist = 2 }) end, "mission3_offer" },
	{ "four_skills_and_rewards_1_to_3_offers_mission4", function() return pilot({ skillCount = 4, rewards = { 1, 2, 3 } }) end, "mission4_offer" },
	{ "four_skills_after_a_realistic_history_offers_mission4", function() return pilot({ skillCount = 4, hist = 3 }) end, "mission4_offer" },

	{ "no_tier4_skills_and_one_million_xp_is_ready_for_training", function() return pilot({ xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "one_skill_with_reward_1_and_enough_xp_is_ready_for_training", function() return pilot({ skillCount = 1, hist = 1, xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "two_skills_with_reward_2_and_enough_xp_is_ready_for_training", function() return pilot({ skillCount = 2, hist = 2, xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "three_skills_with_reward_3_and_enough_xp_is_ready_for_training", function() return pilot({ skillCount = 3, hist = 3, xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "just_under_one_million_xp_is_not_ready_for_training", function() return pilot({ xp = XP_FOR_TIER4 - 1 }) end, "intro" },
	{ "all_four_skills_and_enough_xp_is_not_ready_for_training", function() return pilot({ skillCount = 4, hist = 4, xp = XP_FOR_TIER4, met = true }) end, "no_master" },

	{ "unmet_untrained_pilot_gets_the_intro", function() return pilot({}) end, "intro" },
	{ "met_pilot_who_has_not_finished_tier4_gets_the_duty_menu", function() return pilot({ met = true }) end, "tier4_incomplete" },
	{ "met_pilot_with_two_skills_paid_gets_the_duty_menu", function() return pilot({ skillCount = 2, hist = 2, met = true }) end, "tier4_incomplete" },
	{ "finished_tier4_without_master_gets_no_master", function() return pilot({ skillCount = 4, hist = 4, met = true }) end, "no_master" },
	{ "finished_tier4_with_master_gets_here_for_work", function() return pilot({ skillCount = 4, hist = 4, met = true, master = true }) end, "here_for_work" },
}

for _, route in ipairs(ROUTES) do
	local name, build, expected = route[1], route[2], route[3]

	-- AC-3
	TestArkonRouting["test_" .. name] = function()
		spyAllQuests() -- the reward routes pay a reward; keep quest internals out of routing tests

		local player = build()
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, expected, name .. ": first screen")
		lu.assertEquals(transcript[1].params.TU, player.name, name .. ": setDialogTextTU player first name")
	end
end

-- AC-3
function TestArkonRouting:test_any_active_tier4_story_or_duty_quest_gets_on_mission()
	for _, key in ipairs(D.QUEST_KEYS) do
		local player = pilot({ skillCount = 1, hist = 0, active = { key } })

		lu.assertEquals(firstScreen(player), "on_mission", D.global(key) .. " active")
	end
end

-- AC-3
function TestArkonRouting:test_on_mission_wins_even_when_a_reward_is_also_due()
	local player = pilot({ skillCount = 1, completed = { "m1a" }, active = { "m2" } })

	lu.assertEquals(firstScreen(player), "on_mission")
end

-- AC-3
function TestArkonRouting:test_on_mission_wins_over_negative_faction()
	local player = pilot({ skillCount = 1, standing = -1, active = { "m1" } })

	lu.assertEquals(firstScreen(player), "on_mission")
end

-- AC-3
function TestArkonRouting:test_negative_faction_wins_over_a_due_reward()
	spyAllQuests()

	local player = pilot({ skillCount = 1, standing = -1, completed = { "m1a" } })

	lu.assertEquals(firstScreen(player), "negative_faction")
end

-- AC-3
function TestArkonRouting:test_a_due_reward_wins_over_a_failed_mission_and_an_offer()
	spyAllQuests()

	local player = pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 }, completed = { "m1a", "m2a" } })

	lu.assertEquals(firstScreen(player), "mission2_reward")
end

-- AC-3
function TestArkonRouting:test_a_quest_of_another_squadron_tier_does_not_count_as_on_mission()
	local player = pilot({ skillCount = 1, hist = 0 })

	player.ghost.journalActive[H.questCrc("patrol", "corellia_privateer_1")] = true

	lu.assertEquals(firstScreen(player), "mission1_offer")
end

-- AC-3
function TestArkonRouting:test_a_havoc_pilot_arriving_with_pilot_tier_3_leaves_with_pilot_tier_4()
	local player = pilot({ pilotTier = 3 })

	converse(player)

	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after talking to Arkon")
end

-- AC-3
function TestArkonRouting:test_pilot_tier_4_is_left_alone_while_tier4_is_unfinished()
	local player = pilot({ pilotTier = 4, skillCount = 2, hist = 2, met = true })

	converse(player)

	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier")
end

-- AC-3
function TestArkonRouting:test_a_pilot_who_finished_tier4_is_raised_from_tier_4_to_5()
	local player = pilot({ pilotTier = 4, skillCount = 4, hist = 4, met = true })

	converse(player)

	lu.assertEquals(player.ghost:getPilotTier(), 5, "pilot tier after finishing tier 4")
end

-- AC-3
function TestArkonRouting:test_pilot_tier_5_is_not_incremented_again()
	local player = pilot({ pilotTier = 5, skillCount = 4, hist = 4, met = true })

	converse(player)

	lu.assertEquals(player.ghost:getPilotTier(), 5, "pilot tier")
end

-- AC-3
function TestArkonRouting:test_pilot_tier_is_untouched_when_the_gates_fail()
	local notReady = pilot({ noTier3 = true, pilotTier = 3 })
	local wrongSquadron = corsecPilot()
	wrongSquadron.ghost.pilotTier = 3

	converse(notReady)
	converse(wrongSquadron)

	lu.assertEquals(notReady.ghost:getPilotTier(), 3, "pilot tier of a pilot who has not finished tier 3")
	lu.assertEquals(wrongSquadron.ghost:getPilotTier(), 3, "pilot tier of a pilot from another squadron")
end

---------------------------------------------------------------------------------------------
-- AC-4: non-Havoc duty access
---------------------------------------------------------------------------------------------

TestArkonNonTrackDuty = {}

function TestArkonNonTrackDuty:setUp()
	H.reset()
end

local DUTY_MENU_SIDS = { "s_647ad2bc", "s_d9116b4d", "s_8450d7db", "s_9943289", "s_9775f996" }

-- AC-4
function TestArkonNonTrackDuty:test_a_tier3_graduate_of_another_squadron_is_offered_duty_access()
	local player = corsecPilot()
	local transcript = converse(player, { "s_6222b64d" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_duty" })
end

-- AC-4
function TestArkonNonTrackDuty:test_the_nontrack_duty_chain_ends_on_a_screen_with_the_duty_menu()
	local player = corsecPilot()
	local chain = concat({ "s_6222b64d", "s_c82e9a2f" }, pathBetween("duty_info", "s_406"))
	local transcript = converse(player, chain)
	local last = transcript[#transcript]

	lu.assertEquals(transcript[3].id, "duty_info", "screen after s_c82e9a2f")
	lu.assertEquals(D.optionSids(last.options), DUTY_MENU_SIDS, "options of the last screen '" .. last.id .. "'")
end

-- AC-4
function TestArkonNonTrackDuty:test_without_tier3_the_nontrack_pilot_gets_nontrack_no_duty_and_it_stops()
	local player = corsecPilot()

	player.skills["pilot_rebel_navy_weapons_03"] = nil

	local transcript = converse(player, { "s_6222b64d" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" })
	lu.assertTrue(transcript[2].stop, "nontrack_no_duty stops the conversation")
end

-- AC-4
function TestArkonNonTrackDuty:test_with_a_tier4_quest_active_the_nontrack_pilot_gets_nontrack_no_duty()
	local player = corsecPilot()

	player.ghost.journalActive[H.questCrc("destroy_duty", "corellia_rebel_tier4_1")] = true

	local transcript = converse(player, { "s_6222b64d" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" })
	lu.assertTrue(transcript[2].stop, "nontrack_no_duty stops the conversation")
end

-- AC-4
function TestArkonNonTrackDuty:test_nontrack_screens_start_no_quest_before_a_duty_is_chosen()
	local rec = spyAllQuests()

	converse(corsecPilot(), concat({ "s_6222b64d", "s_c82e9a2f" }, pathBetween("duty_info", "s_406")))

	lu.assertEquals(rec.starts, {}, "quests started while only reading")
end

---------------------------------------------------------------------------------------------
-- AC-5: mission grants
---------------------------------------------------------------------------------------------

TestArkonMissionGrants = {}

function TestArkonMissionGrants:setUp()
	H.reset()
end

-- mission, start screen, state builder, target grant screens
local GRANTS = {
	{ 1, "mission1_offer", function() return pilot({ skillCount = 1, hist = 0 }) end, { "mission1_accept_a", "mission1_accept_b", "mission1_accept_c" } },
	{ 1, "mission1_failed", function() return pilot({ skillCount = 1, attempted = { 1 } }) end, { "mission1_retry_a", "mission1_retry_b" } },
	{ 2, "mission2_offer", function() return pilot({ skillCount = 2, hist = 1 }) end, { "mission2_accept_a", "mission2_accept_b" } },
	{ 2, "mission2_failed", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 } }) end, { "mission2_retry_a", "mission2_retry_b" } },
	{ 3, "mission3_offer", function() return pilot({ skillCount = 3, hist = 2 }) end, { "mission3_accept_a", "mission3_accept_b", "mission3_accept_c" } },
	{ 3, "mission3_failed", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 } }) end, { "mission3_retry_a", "mission3_retry_b" } },
	{ 4, "mission4_offer", function() return pilot({ skillCount = 4, hist = 3 }) end, { "mission4_accept_a", "mission4_accept_b" } },
	{ 4, "mission4_failed", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 } }) end, { "mission4_retry_a", "mission4_retry_b" } },
}

-- Walks from the start screen to `target` (hooking stale journal completions in just before the
-- last choice), then keeps talking to the end of the chain.
local function driveToGrant(start, build, target, mission)
	local player = build()
	local rec = spyAllQuests()
	local path = pathBetween(start, target)
	local choices = {}

	for i, sid in ipairs(path) do
		if i == #path then
			local stale = { D.MISSION[mission].main }

			for _, child in ipairs(D.MISSION[mission].children) do
				stale[#stale + 1] = child
			end

			-- a completed quest of a different mission must survive
			stale[#stale + 1] = D.MISSION[mission % 4 + 1].main

			choices[#choices + 1] = function(p) setComplete(p, stale) end
		end

		choices[#choices + 1] = sid
	end

	local transcript = converse(player, concat(choices, zeros(12)))

	return player, rec, transcript
end

for _, row in ipairs(GRANTS) do
	local mission, start, build, targets = row[1], row[2], row[3], row[4]

	for _, target in ipairs(targets) do
		-- AC-5
		TestArkonMissionGrants["test_" .. target .. "_starts_mission_" .. mission .. "_once_from_" .. start] = function()
			local player, rec, transcript = driveToGrant(start, build, target, mission)

			lu.assertEquals(transcript[1].id, start, target .. ": first screen")
			lu.assertTrue(contains(ids(transcript), target), target .. ": screen shown; got " .. table.concat(ids(transcript), ","))
			lu.assertEquals(rec.starts, { D.global(D.MISSION[mission].main) }, target .. ": quests started")
			lu.assertEquals(H.getQuestStatus(player, D.MISSION[mission].statusName .. ":attempted"), "1", target .. ": :attempted status")
		end

		-- AC-5
		TestArkonMissionGrants["test_" .. target .. "_clears_old_journal_entries_of_mission_" .. mission .. "_before_starting"] = function()
			local player, rec = driveToGrant(start, build, target, mission)
			local m = D.MISSION[mission]
			local mine = { D.global(m.main) }

			for _, child in ipairs(m.children) do
				mine[#mine + 1] = D.global(child)
			end

			lu.assertEquals(#rec.starts, 1, target .. ": number of quest starts")

			for _, name in ipairs(mine) do
				lu.assertFalse(contains(rec.completeAtStart[1], name), target .. ": " .. name .. " was still journal-complete when the mission started")
			end

			local other = D.global(D.MISSION[mission % 4 + 1].main)
			local otherKey = D.MISSION[mission % 4 + 1].main

			lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, D.QUEST[otherKey][1], D.QUEST[otherKey][2]), target .. ": " .. other .. " (another mission) must not be cleared")
		end
	end
end

-- AC-5
function TestArkonMissionGrants:test_offer_and_decline_screens_start_nothing()
	local offers = {
		{ "mission1_offer", "mission1_decline", function() return pilot({ skillCount = 1, hist = 0 }) end },
		{ "mission2_offer", "mission2_decline", function() return pilot({ skillCount = 2, hist = 1 }) end },
		{ "mission3_offer", "mission3_decline", function() return pilot({ skillCount = 3, hist = 2 }) end },
		{ "mission4_offer", "mission4_decline", function() return pilot({ skillCount = 4, hist = 3 }) end },
	}

	for _, row in ipairs(offers) do
		local rec = spyAllQuests()
		local player = row[3]()
		local transcript = converse(player, pathBetween(row[1], row[2]))

		lu.assertEquals(transcript[1].id, row[1], row[1] .. ": first screen")
		lu.assertEquals(transcript[#transcript].id, row[2], row[1] .. ": reached decline")
		lu.assertEquals(rec.starts, {}, row[2] .. ": quests started")
		lu.assertNil(H.getQuestStatus(player, "corellia_rebel_tier4_" .. row[1]:match("%d") .. ":attempted"), row[2] .. ": :attempted status")
	end
end

-- AC-5, I-4
function TestArkonMissionGrants:test_only_the_offer_screen_itself_starts_nothing_and_a_second_talk_does_not_restart()
	local rec = spyAllQuests()
	local player = pilot({ skillCount = 1, hist = 0 })

	converse(player)
	converse(player)

	lu.assertEquals(rec.starts, {}, "quests started by merely talking to Arkon")
end

---------------------------------------------------------------------------------------------
-- AC-6: rewards
---------------------------------------------------------------------------------------------

TestArkonRewards = {}

function TestArkonRewards:setUp()
	H.reset()
end

local REWARDS = {
	{ 1, function() return pilot({ skillCount = 1, completed = { "m1a" } }) end },
	{ 1, function() return pilot({ skillCount = 1, completed = { "m1b" } }) end },
	{ 2, function() return pilot({ skillCount = 2, hist = 1, completed = { "m1a", "m2a" } }) end },
	{ 2, function() return pilot({ skillCount = 2, hist = 1, completed = { "m1a", "m2b" } }) end },
	{ 3, function() return pilot({ skillCount = 3, hist = 2, completed = { "m1a", "m2a", "m3a" } }) end },
	{ 3, function() return pilot({ skillCount = 3, hist = 2, completed = { "m1a", "m2a", "m3b" } }) end },
	{ 4, function() return pilot({ skillCount = 4, hist = 3, completed = { "m1a", "m2a", "m3a", "m4c" } }) end },
}

for i, row in ipairs(REWARDS) do
	local mission, build = row[1], row[2]

	-- AC-6
	TestArkonRewards["test_mission_" .. mission .. "_reward_is_paid_once_variant_" .. i] = function()
		local rec = spyAllQuests()
		local player = build()
		local before = rebel(player)
		local screen = "mission" .. mission .. "_reward"
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, screen, "first screen")
		lu.assertEquals(rec.rewards, { D.global(D.MISSION[mission].main) }, screen .. ": rewardPlayer calls")
		lu.assertEquals(rebel(player) - before, 150, screen .. ": Rebel faction gained")
		lu.assertEquals(H.getQuestStatus(player, D.MISSION[mission].statusName .. ":reward"), "1", screen .. ": :reward status")
		lu.assertEquals(rec.starts, {}, screen .. ": quests started")
	end

	-- AC-6
	TestArkonRewards["test_mission_" .. mission .. "_reward_is_not_paid_again_on_the_next_talk_variant_" .. i] = function()
		local rec = spyAllQuests()
		local player = build()

		converse(player)

		local standing = rebel(player)
		local second = converse(player)

		lu.assertNotEquals(second[1].id, "mission" .. mission .. "_reward", "second conversation must not route to the reward again")
		lu.assertEquals(#rec.rewards, 1, "rewardPlayer calls after two conversations")
		lu.assertEquals(rebel(player), standing, "Rebel faction after the second conversation")
	end
end

-- AC-6
function TestArkonRewards:test_a_reward_already_paid_is_not_paid_again()
	local rec = spyAllQuests()
	local player = pilot({ skillCount = 1, hist = 1, met = true })
	local before = rebel(player)

	local transcript = converse(player)

	lu.assertNotEquals(transcript[1].id, "mission1_reward", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(rebel(player), before, "Rebel faction")
end

-- AC-6
function TestArkonRewards:test_the_reward_screen_text_is_shown_when_the_reward_is_paid()
	spyAllQuests()

	local player = pilot({ skillCount = 1, completed = { "m1a" } })
	local transcript = converse(player)

	lu.assertEquals(transcript[1].text, D.PREFIX .. "s_f95cd5f5", "mission1_reward leftDialog")
end

---------------------------------------------------------------------------------------------
-- AC-7: training
---------------------------------------------------------------------------------------------

TestArkonTraining = {}

function TestArkonTraining:setUp()
	H.reset()
end

local function trainer(held)
	local count = #held

	return pilot({ tier4 = held, hist = count, xp = XP_FOR_TIER4, met = true })
end

-- The old fixed-order tests (ready_train's single reply s_421 linking to the first missing skill) are superseded by
-- havoc-tier4-arkon-free-choice AC-1/AC-2: see test_havoc_tier4_arkon_free_choice.lua.

local TRAINED = {
	{ "starships", {}, "trained_starships" },
	{ "weapons", { "starships" }, "trained_weapons" },
	{ "procedures", { "starships", "weapons" }, "trained_procedures" },
	{ "droid", { "starships", "weapons", "procedures" }, "trained_droid" },
}

-- Choices that walk ready_train -> trained_<x>, with an optional hook just before the last choice.
-- (path[1] is SWG's s_421; under havoc-tier4-arkon-free-choice the pick is the skill-name reply.)
local function trainingChoices(screen, hook)
	local path = pathBetween("ready_train", screen)
	local choices = {}

	for i, sid in ipairs(path) do
		if i == #path and hook then
			choices[#choices + 1] = hook
		end

		-- havoc-tier4-arkon-free-choice: the first reply is the pilot's pick of the skill of the target screen, not SWG's s_421
		if i == 1 then
			sid = "@skl_n:pilot_rebel_navy_" .. screen:match("^trained_(%a+)$") .. "_04"
		end

		choices[#choices + 1] = sid
	end

	return choices
end

for _, row in ipairs(TRAINED) do
	local skill, held, screen = row[1], row[2], row[3]
	local skillName = "pilot_rebel_navy_" .. skill .. "_04"

	-- AC-7
	TestArkonTraining["test_" .. screen .. "_grants_" .. skill .. "_04_through_the_xp_deducting_skill_manager"] = function()
		local player = trainer(held)
		local transcript = converse(player, trainingChoices(screen))
		local paid = H.Engine.callsTo("skillManagerAwardSkill")

		lu.assertEquals(transcript[#transcript].id, screen, "last screen")
		lu.assertEquals(#paid, 1, screen .. ": XP-deducting awardSkill calls")
		lu.assertEquals(paid[1][2], skillName, screen .. ": skill granted")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, screen .. ": free awardSkill calls")
		lu.assertTrue(player.skills[skillName] == true, screen .. ": player has " .. skillName)
	end

	-- AC-7
	TestArkonTraining["test_" .. screen .. "_grants_nothing_if_the_player_already_has_the_skill"] = function()
		local player = trainer(held)
		local hook = function(p) p.skills[skillName] = true end

		converse(player, trainingChoices(screen, hook))

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, screen .. ": XP-deducting awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, screen .. ": free awardSkill calls")
	end

	-- AC-7
	TestArkonTraining["test_" .. screen .. "_grants_nothing_if_the_player_lacks_the_experience"] = function()
		local player = trainer(held)
		local hook = function(p) p.ghost.experience.space_combat_general = XP_FOR_TIER4 - 1 end

		converse(player, trainingChoices(screen, hook))

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, screen .. ": XP-deducting awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, screen .. ": free awardSkill calls")
		lu.assertFalse(player.skills[skillName] == true, screen .. ": player must not have " .. skillName)
	end
end

-- AC-7
function TestArkonTraining:test_the_fourth_tier4_skill_raises_the_pilot_tier_to_5()
	local player = trainer({ "starships", "weapons", "procedures" })

	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier before training")

	converse(player, trainingChoices("trained_droid"))

	lu.assertEquals(player.ghost:getPilotTier(), 5, "pilot tier after the fourth tier 4 skill")
end

-- AC-7
function TestArkonTraining:test_the_third_tier4_skill_leaves_the_pilot_tier_at_4()
	local player = trainer({ "starships", "weapons" })

	converse(player, trainingChoices("trained_procedures"))

	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier after the third tier 4 skill")
end

-- AC-7
function TestArkonTraining:test_reaching_the_training_screens_starts_no_quest()
	local rec = spyAllQuests()

	converse(trainer({}), trainingChoices("trained_starships"))

	lu.assertEquals(rec.starts, {}, "quests started")
	lu.assertEquals(rec.rewards, {}, "rewards paid")
end

---------------------------------------------------------------------------------------------
-- AC-8: intro and duties
---------------------------------------------------------------------------------------------

TestArkonIntroAndDuties = {}

function TestArkonIntroAndDuties:setUp()
	H.reset()
end

-- AC-8
function TestArkonIntroAndDuties:test_intro_met_sets_the_met_flag_and_the_next_talk_skips_the_intro()
	local player = pilot({})

	lu.assertEquals(firstScreen(player), "intro", "first conversation")
	lu.assertNil(H.getQuestStatus(player, D.MET_SUFFIX), "StartedArkon after only the intro line")

	local transcript = converse(player, { "s_34d61fa3" })

	lu.assertEquals(ids(transcript), { "intro", "intro_met" })
	lu.assertEquals(H.getQuestStatus(player, D.MET_SUFFIX), "1", "StartedArkon after intro_met")
	lu.assertEquals(firstScreen(player), "tier4_incomplete", "next conversation in the same state")
end

-- AC-8
function TestArkonIntroAndDuties:test_a_pilot_who_has_met_arkon_never_sees_the_intro()
	local player = pilot({ met = true })

	lu.assertNotEquals(firstScreen(player), "intro")
end

-- start screen, state builder, menu NPC sid
local MENUS = {
	{ "tier4_incomplete", function() return pilot({ met = true }) end, "s_a5958aac" },
	{ "here_for_work", function() return pilot({ skillCount = 4, hist = 4, met = true, master = true }) end, "s_d318a2bb" },
	{ "tier4_incomplete", function() return pilot({}) end, "s_9bbb9999", "intro" },
	{ "tier4_incomplete", function() return pilot({}) end, "s_371", "intro" },
	{ "tier4_incomplete", function() return pilot({ met = true }) end, "s_406" },
}

for _, menu in ipairs(MENUS) do
	local startScreen, build, menuSid, startOverride = menu[1], menu[2], menu[3], menu[4]

	for _, duty in ipairs(D.DUTY_MENU) do
		if duty.quest then
			-- AC-8
			TestArkonIntroAndDuties["test_duty_menu_" .. menuSid .. "_option_" .. duty.option .. "_starts_only_" .. duty.quest] = function()
				local rec = spyAllQuests()
				local player = build()
				local begin = startOverride or startScreen
				local path = GRAPH.pathTo(D.SCREENS[begin], menuSid)

				lu.assertNotNil(path, "answer key: no path from " .. begin .. " to " .. menuSid)

				local transcript = converse(player, concat(path, { duty.option }, zeros(3)))
				local menuShown = transcript[#path + 1]

				lu.assertEquals(D.optionSids(menuShown.options), DUTY_MENU_SIDS, "options of the menu screen '" .. menuShown.id .. "' (" .. menuSid .. ")")
				lu.assertEquals(transcript[#path + 2].id, duty.screen, "screen after choosing " .. duty.option)
				lu.assertEquals(rec.starts, { duty.quest }, "quests started")
			end
		end
	end
end

-- AC-8
function TestArkonIntroAndDuties:test_choosing_duty_info_starts_no_quest()
	local rec = spyAllQuests()

	converse(pilot({ met = true }), { "s_9775f996" })

	lu.assertEquals(rec.starts, {}, "quests started")
end

-- AC-8
function TestArkonIntroAndDuties:test_reset_arkon_quests_removes_the_met_flag()
	spyAllQuests()

	local player = pilot({ met = true, skillCount = 1, hist = 1 })

	lu.assertEquals(H.getQuestStatus(player, D.MET_SUFFIX), "1", "precondition: flag set")

	HavocSquadronScreenplay:resetArkonQuests(player)

	lu.assertNil(H.getQuestStatus(player, D.MET_SUFFIX), "StartedArkon after resetArkonQuests")
end

-- AC-8
function TestArkonIntroAndDuties:test_reset_arkon_quests_clears_the_journal_entries_the_conversation_reads()
	spyAllQuests()

	local player = pilot({ completed = { "m1", "m1a", "m1b", "m2a", "m2b", "m3a", "m3b", "m4a", "m4b", "m4c" } })

	HavocSquadronScreenplay:resetArkonQuests(player)

	for _, key in ipairs({ "m1", "m1a", "m1b", "m2a", "m2b", "m3a", "m3b", "m4a", "m4b", "m4c" }) do
		lu.assertFalse(SpaceHelpers:isSpaceQuestComplete(player, D.QUEST[key][1], D.QUEST[key][2]), D.global(key) .. " journal entry after resetArkonQuests")
	end
end
