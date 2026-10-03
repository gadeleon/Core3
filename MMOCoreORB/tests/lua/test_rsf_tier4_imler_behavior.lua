-- Admiral Diness Imler (RSF Squadron tier 4 trainer): conversation behavior against engine fakes.
-- Spec: .claude/work/rsf-tier4/01-spec.md (AC-3 .. AC-8, invariant I-5).
--
-- Quest starts, rewards and resets are observed by replacing startQuest / rewardPlayer / resetQuest
-- on every quest global with a recorder (H.spyOn): nothing here is about what a quest does once
-- started. Dialogue actions come from spec Appendix A (the swgjava parser misattributes the skill
-- purchases and setMetMe), so grant/reward/ready screens are addressed by the screen ids in
-- rsf_tier4_data.lua; the graph is only used to find option paths between NPC lines.
--
-- Q1 (user answer): completing space_battle 4c_lose counts as winning mission 4.

local lu = require("luaunit")
local H = require("harness")
local D = require("rsf_tier4_data")
local C = require("pilot_training_free_choice_data") -- pilot-training-free-choice: the Imler choice replies
local Swgjava = require("harness.swgjava")

local loadErrors = {}

local function tryLoad(label, fn)
	local ok, err = pcall(fn)

	if not ok then
		loadErrors[#loadErrors + 1] = label .. ": " .. tostring(err)
	end
end

tryLoad("RsfSquadronScreenplay", function() H.loadSquadron("RsfSquadronScreenplay") end)
tryLoad("imler_convo.lua", function() H.loadMobile("conversations/space/neutral/rsf_squadron/imler_convo.lua") end)
tryLoad("imlerConvoHandler.lua", function() H.loadScreenplay("space/conversations/neutral/rsf_squadron/imlerConvoHandler.lua") end)

local GRAPH = Swgjava.read(H.FIXTURES .. "script/conversation/naboo_privateer_tier4.java")

local XP_FOR_TIER4 = 1000000

---------------------------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------------------------

local function converse(player, choices)
	lu.assertNotNil(H.conversationTemplateTable("imler_convo_template"), "imler_convo_template is not registered via addConversationTemplate. Load problems: " .. table.concat(loadErrors, " | "))

	return H.converse({ template = "imler_convo_template", player = player, npc = H.newNpc({ name = "Admiral Diness Imler" }), choices = choices })
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

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- Option sids that lead from the NPC line `fromId` to the one `toId` (screen ids or raw sids),
-- BFS over the SWG java graph so every conditional successor counts as reachable.
local function pathBetween(fromId, toId)
	local path = GRAPH.pathTo(D.SCREENS[fromId] or fromId, D.SCREENS[toId] or toId)

	lu.assertNotNil(path, "answer key: no option path from " .. fromId .. " to " .. toId)
	return path
end

-- Journal/status history of missions 1..n done: attempted, terminal quest complete, reward paid.
local function history(n)
	local h = { rewards = {}, attempted = {}, completed = {} }

	for i = 1, n do
		h.rewards[i] = i
		h.attempted[i] = i
		h.completed[#h.completed + 1] = D.MISSION[i].wins[1]
	end

	return h
end

-- opts: skillCount (first k tier 4 skills) or tier4 (explicit list), hist (n), plus any D.rsf opts,
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

	return D.rsf(args)
end

-- Spies on every quest global. rec.starts / rec.rewards / rec.resets: global names in call order.
-- rec.completeAtStart[i]: tier 4 quest globals whose journal entry was complete when start i happened.
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

local function setComplete(player, keys)
	for _, key in ipairs(keys) do
		player.ghost.journalComplete[H.questCrc(D.QUEST[key][1], D.QUEST[key][2])] = true
	end
end

local function standing(player, faction)
	return player.ghost:getFactionStanding(faction)
end

local function tier(player)
	return player.ghost:getPilotTier()
end

---------------------------------------------------------------------------------------------
-- AC-3: routing
---------------------------------------------------------------------------------------------

TestImlerRouting = {}

function TestImlerRouting:setUp()
	H.reset()
end

-- name, builder, expected first screen
local ROUTES = {
	{ "no_pilot_skill_gets_not_pilot", function() return H.newPlayer({}) end, "not_pilot" },
	{ "jtl_disabled_gets_not_pilot", function() H.Engine.config.jtlEnabled = false; return pilot({ skillCount = 1, hist = 0 }) end, "not_pilot" },
	{ "rebel_pilot_gets_wrong_faction", function() return H.newPlayer({ pilot = "rebel" }) end, "wrong_faction" },
	{ "imperial_pilot_gets_wrong_faction", function() return H.newPlayer({ pilot = "imperial" }) end, "wrong_faction" },
	{ "corsec_neutral_pilot_gets_not_my_track", function() return D.corsec({}) end, "not_my_track" },
	{ "rsf_pilot_with_three_of_four_tier3_skills_gets_not_ready", function() return pilot({ noTier3 = true, pilotTier = 3 }) end, "not_ready" },

	{ "mission1_won_with_1b_pays_reward_1", function() return pilot({ skillCount = 1, attempted = { 1 }, completed = { "m1b" } }) end, "mission1_reward" },
	{ "mission2_won_with_2d_pays_reward_2", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 }, completed = { "m1b", "m2d" } }) end, "mission2_reward" },
	{ "mission3_won_with_3c_pays_reward_3", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 }, completed = { "m1b", "m2d", "m3c" } }) end, "mission3_reward" },
	{ "mission4_won_with_4c_win_pays_reward_4", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4cw" } }) end, "mission4_reward" },
	{ "mission4_won_with_4c_lose_also_pays_reward_4_per_Q1", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4cl" } }) end, "mission4_reward" },

	{ "mission1_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 1, attempted = { 1 } }) end, "mission1_failed" },
	{ "mission1_with_only_1a_complete_is_failed_because_won_means_the_terminal_quest", function() return pilot({ skillCount = 1, attempted = { 1 }, completed = { "m1" } }) end, "mission1_failed" },
	{ "mission2_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 } }) end, "mission2_failed" },
	{ "mission2_with_2a_2b_2c_complete_but_not_2d_is_failed", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 }, completed = { "m1b", "m2", "m2b", "m2c" } }) end, "mission2_failed" },
	{ "mission3_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 } }) end, "mission3_failed" },
	{ "mission3_with_3a_3b_complete_but_not_3c_is_failed", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 }, completed = { "m1b", "m2d", "m3", "m3b" } }) end, "mission3_failed" },
	{ "mission4_attempted_and_not_won_is_failed", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 } }) end, "mission4_failed" },
	{ "mission4_with_4a_and_4b_complete_but_no_4c_is_failed", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4", "m4b" } }) end, "mission4_failed" },
	{ "an_attempted_mission_that_was_won_and_paid_is_not_failed", function() return pilot({ skillCount = 1, hist = 1, met = true }) end, "tier4_incomplete" },
	{ "mission2_failed_beats_a_due_mission1_reward", function() return pilot({ skillCount = 2, attempted = { 1, 2 }, completed = { "m1b" } }) end, "mission2_failed" },

	{ "ready_flag_with_no_skills_gets_ready_mission", function() return pilot({ ready = true }) end, "ready_mission" },
	{ "ready_flag_with_one_skill_gets_ready_mission", function() return pilot({ skillCount = 1, hist = 0, ready = true }) end, "ready_mission" },
	{ "ready_flag_with_four_skills_gets_ready_mission", function() return pilot({ skillCount = 4, hist = 3, ready = true }) end, "ready_mission" },
	{ "ready_flag_beats_ready_for_training", function() return pilot({ skillCount = 1, hist = 0, ready = true, xp = XP_FOR_TIER4 }) end, "ready_mission" },
	{ "a_due_reward_beats_the_ready_flag", function() return pilot({ skillCount = 2, attempted = { 1 }, completed = { "m1b" }, ready = true }) end, "mission1_reward" },

	{ "no_tier4_skills_and_one_million_xp_is_ready_for_training", function() return pilot({ xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "one_skill_paid_and_enough_xp_is_ready_for_training", function() return pilot({ skillCount = 1, hist = 1, xp = XP_FOR_TIER4 }) end, "ready_train" },
	{ "three_skills_paid_and_enough_xp_is_ready_for_training", function() return pilot({ skillCount = 3, hist = 3, xp = XP_FOR_TIER4 }) end, "ready_train" },
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
	TestImlerRouting["test_" .. name] = function()
		spyAllQuests() -- the reward routes pay a reward; keep quest internals out of routing tests

		local player = build()
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, expected, name .. ": first screen")
		lu.assertEquals(transcript[1].params.TU, player.name, name .. ": setDialogTextTU player first name")
	end
end

-- AC-3
function TestImlerRouting:test_any_active_tier4_story_or_duty_quest_gets_on_mission()
	for _, key in ipairs(D.QUEST_KEYS) do
		local player = pilot({ skillCount = 1, hist = 0, active = { key } })

		lu.assertEquals(firstScreen(player), "on_mission", D.global(key) .. " active")
	end
end

-- AC-3
function TestImlerRouting:test_on_mission_wins_even_when_a_reward_is_also_due()
	local player = pilot({ skillCount = 1, completed = { "m1b" }, active = { "m2" } })

	lu.assertEquals(firstScreen(player), "on_mission")
end

-- AC-3
function TestImlerRouting:test_on_mission_wins_over_a_failed_mission()
	local player = pilot({ skillCount = 1, attempted = { 1 }, active = { "dRescue" } })

	lu.assertEquals(firstScreen(player), "on_mission")
end

-- AC-3
function TestImlerRouting:test_a_quest_of_another_squadron_tier_does_not_count_as_on_mission()
	local player = pilot({ skillCount = 1, hist = 0, ready = true })

	player.ghost.journalActive[H.questCrc("patrol", "naboo_privateer_tier3_1b")] = true

	lu.assertEquals(firstScreen(player), "ready_mission")
end

-- AC-3
function TestImlerRouting:test_a_player_with_no_quest_state_at_all_gets_the_intro()
	lu.assertEquals(firstScreen(pilot({})), "intro")
end

-- AC-3
function TestImlerRouting:test_an_rsf_pilot_arriving_with_pilot_tier_3_leaves_with_pilot_tier_4()
	local player = pilot({ pilotTier = 3 })

	converse(player)

	lu.assertEquals(tier(player), 4, "pilot tier after talking to Imler")
end

-- AC-3
function TestImlerRouting:test_pilot_tier_4_is_left_alone_while_tier4_is_unfinished()
	local player = pilot({ pilotTier = 4, skillCount = 2, hist = 2, met = true })

	converse(player)

	lu.assertEquals(tier(player), 4, "pilot tier")
end

-- AC-3
function TestImlerRouting:test_a_pilot_who_finished_tier4_is_raised_from_tier_4_to_5()
	local player = pilot({ pilotTier = 4, skillCount = 4, hist = 4, met = true })

	converse(player)

	lu.assertEquals(tier(player), 5, "pilot tier after finishing tier 4")
end

-- AC-3
function TestImlerRouting:test_pilot_tier_5_is_not_incremented_again()
	local player = pilot({ pilotTier = 5, skillCount = 4, hist = 4, met = true })

	converse(player)

	lu.assertEquals(tier(player), 5, "pilot tier")
end

-- AC-3
function TestImlerRouting:test_pilot_tier_is_untouched_when_the_gates_fail()
	local notReady = pilot({ noTier3 = true, pilotTier = 3 })
	local wrongSquadron = D.corsec({ pilotTier = 3 })

	converse(notReady)
	converse(wrongSquadron)

	lu.assertEquals(tier(notReady), 3, "pilot tier of a pilot who has not finished tier 3")
	lu.assertEquals(tier(wrongSquadron), 3, "pilot tier of a pilot from another squadron")
end

---------------------------------------------------------------------------------------------
-- AC-4: non-RSF duty access
---------------------------------------------------------------------------------------------

TestImlerNonTrackDuty = {}

function TestImlerNonTrackDuty:setUp()
	H.reset()
end

-- AC-4
function TestImlerNonTrackDuty:test_a_tier3_graduate_of_another_squadron_is_offered_duty_access()
	local transcript = converse(D.corsec({}), { "s_c1ff5062" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_duty" })
end

-- AC-4
function TestImlerNonTrackDuty:test_the_nontrack_duty_chain_ends_on_duty_info_end_with_the_duty_menu()
	local chain = concat({ "s_c1ff5062", "s_c82e9a2f" }, pathBetween("duty_info", "duty_info_end"))
	local transcript = converse(D.corsec({}), chain)
	local last = transcript[#transcript]

	lu.assertEquals(transcript[3].id, "duty_info", "screen after s_c82e9a2f")
	lu.assertEquals(last.id, "duty_info_end", "last screen of the chain")
	lu.assertEquals(D.optionSids(last.options), D.DUTY_MENU_SIDS, "options of the last screen")
end

-- AC-4
function TestImlerNonTrackDuty:test_without_tier3_the_nontrack_pilot_gets_nontrack_no_duty_and_it_stops()
	local player = D.corsec({})

	player.skills["pilot_neutral_weapons_03"] = nil

	local transcript = converse(player, { "s_c1ff5062" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" })
	lu.assertTrue(transcript[2].stop, "nontrack_no_duty stops the conversation")
end

-- AC-4
function TestImlerNonTrackDuty:test_with_an_rsf_tier4_story_quest_active_the_nontrack_pilot_gets_nontrack_no_duty()
	local player = D.corsec({ active = { "m3b" } })
	local transcript = converse(player, { "s_c1ff5062" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" })
	lu.assertTrue(transcript[2].stop, "nontrack_no_duty stops the conversation")
end

-- AC-4
function TestImlerNonTrackDuty:test_with_an_rsf_tier4_duty_active_the_nontrack_pilot_gets_nontrack_no_duty()
	local player = D.corsec({ active = { "dDestroy" } })
	local transcript = converse(player, { "s_c1ff5062" })

	lu.assertEquals(ids(transcript), { "not_my_track", "nontrack_no_duty" })
end

-- AC-4
function TestImlerNonTrackDuty:test_the_nontrack_path_never_sets_the_met_flag_and_starts_no_quest()
	local rec = spyAllQuests()
	local player = D.corsec({})

	converse(player, concat({ "s_c1ff5062", "s_c82e9a2f" }, pathBetween("duty_info", "duty_info_end")))

	lu.assertNil(H.getQuestStatus(player, D.MET_SUFFIX), "StartedImler after the non-track duty_info chain")
	lu.assertEquals(rec.starts, {}, "quests started while only reading")
end

---------------------------------------------------------------------------------------------
-- AC-5: training and briefings
---------------------------------------------------------------------------------------------

TestImlerTraining = {}

function TestImlerTraining:setUp()
	H.reset()
end

-- A met pilot ready for training who holds `held` (list of skill names) and has the XP.
local function trainer(held)
	return pilot({ tier4 = held, hist = #held, xp = XP_FOR_TIER4, met = true })
end

-- pilot-training-free-choice (AC-8): ready_train offers one reply per missing tier 4 skill, in the order starships, weapons, procedures, droid,
-- each linking to the skill's own prompt (the single fixed-order reply s_438 is retired)
local LINKS = {
	{ "no_skills_offers_all_four", {} },
	{ "only_weapons_held_offers_starships_procedures_droid", { "weapons" } },
	{ "starships_held_offers_weapons_procedures_droid", { "starships" } },
	{ "starships_and_procedures_held_offers_weapons_and_droid", { "starships", "procedures" } },
	{ "starships_and_weapons_held_offers_procedures_and_droid", { "starships", "weapons" } },
	{ "three_held_offers_only_droid", { "starships", "weapons", "procedures" } },
	{ "all_but_starships_offers_only_starships", { "weapons", "procedures", "droid" } },
}

for _, row in ipairs(LINKS) do
	-- AC-8
	TestImlerTraining["test_ready_train_" .. row[1]] = function()
		local held = {}

		for _, x in ipairs(row[2]) do
			held["pilot_neutral_" .. x .. "_04"] = true
		end

		local transcript = converse(trainer(row[2]))

		lu.assertEquals(transcript[1].id, "ready_train", "first screen")
		lu.assertEquals(C.pairsOf(transcript[1]), C.expected(C.IMLER, held), "ready_train options (reply, link) with held skills {" .. table.concat(row[2], ",") .. "}")
	end
end

-- skill, held before, screen after the purchase (K = count after the purchase)
local TRAINED = {
	{ "starships", {}, "trained_mission1" },
	{ "weapons", { "starships" }, "trained_mission2" },
	{ "procedures", { "starships", "weapons" }, "trained_mission3" },
	{ "droid", { "starships", "weapons", "procedures" }, "trained_mission4" },
}

-- The choice reply of each tier 4 skill (pilot-training-free-choice: Turoldine's replies, D-10)
local REPLY = {}

for _, row in ipairs(C.IMLER) do
	REPLY[row.x] = row.sid
end

-- Choices that walk ready_train -> train_<x> -> (buy), with an optional hook just before the buy.
local function trainingChoices(skill, hook)
	local choices = { REPLY[skill] }

	if hook then
		choices[#choices + 1] = hook
	end

	choices[#choices + 1] = D.BUY_OPTION[skill]

	return choices
end

for _, row in ipairs(TRAINED) do
	local skill, held, screen = row[1], row[2], row[3]
	local skillName = "pilot_neutral_" .. skill .. "_04"

	-- AC-5
	TestImlerTraining["test_buying_" .. skill .. "_04_grants_it_once_through_the_xp_deducting_skill_manager_and_shows_" .. screen] = function()
		local player = trainer(held)
		local transcript = converse(player, trainingChoices(skill))
		local paid = H.Engine.callsTo("skillManagerAwardSkill")

		lu.assertEquals(transcript[#transcript].id, screen, "last screen")
		lu.assertEquals(#paid, 1, screen .. ": XP-deducting awardSkill calls")
		lu.assertEquals(paid[1][2], skillName, screen .. ": skill granted")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, screen .. ": free awardSkill calls")
		lu.assertTrue(player.skills[skillName] == true, screen .. ": player has " .. skillName)
	end

	-- AC-5
	TestImlerTraining["test_buying_" .. skill .. "_04_sets_the_ready_for_tier4_mission_flag"] = function()
		local player = trainer(held)

		lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), "precondition: flag clear")

		converse(player, trainingChoices(skill))

		lu.assertEquals(H.getQuestStatus(player, D.READY_SUFFIX), "1", "readyForTier4Mission after " .. screen)
	end

	-- AC-5
	TestImlerTraining["test_" .. skill .. "_04_is_not_granted_if_the_player_already_has_it_and_the_screen_follows_the_count"] = function()
		local player = trainer(held)
		local hook = function(p) p.skills[skillName] = true end
		local count = #held + 1
		local transcript = converse(player, trainingChoices(skill, hook))

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-deducting awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free awardSkill calls")
		lu.assertEquals(transcript[#transcript].id, count >= 2 and ("trained_mission" .. count) or "trained_mission1", "screen with the skill already held")
	end

	-- AC-5
	TestImlerTraining["test_" .. skill .. "_04_is_not_granted_if_the_player_lacks_the_experience_and_the_screen_follows_the_unchanged_count"] = function()
		local player = trainer(held)
		local hook = function(p) p.ghost.experience.space_combat_general = XP_FOR_TIER4 - 1 end
		local transcript = converse(player, trainingChoices(skill, hook))
		local count = #held

		lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-deducting awardSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill"), 0, "free awardSkill calls")
		lu.assertFalse(player.skills[skillName] == true, "player must not have " .. skillName)
		lu.assertEquals(transcript[#transcript].id, count >= 2 and ("trained_mission" .. count) or "trained_mission1", "screen with an unchanged skill count of " .. count)
	end
end

-- AC-5: the screen follows the count after the purchase, whichever skill was bought
function TestImlerTraining:test_the_trained_screen_depends_on_the_skill_count_not_on_which_skill_was_bought()
	local transcript = converse(trainer({ "droid" }), trainingChoices("starships"))

	lu.assertEquals(transcript[#transcript].id, "trained_mission2", "starships bought with droid already held")
end

-- AC-5
function TestImlerTraining:test_the_fourth_tier4_skill_raises_the_pilot_tier_to_5()
	local player = trainer({ "starships", "weapons", "procedures" })

	lu.assertEquals(tier(player), 4, "pilot tier before training")

	converse(player, trainingChoices("droid"))

	lu.assertEquals(tier(player), 5, "pilot tier after the fourth tier 4 skill")
end

-- AC-5
function TestImlerTraining:test_the_third_tier4_skill_leaves_the_pilot_tier_at_4()
	local player = trainer({ "starships", "weapons" })

	converse(player, trainingChoices("procedures"))

	lu.assertEquals(tier(player), 4, "pilot tier after the third tier 4 skill")
end

-- AC-5
function TestImlerTraining:test_training_screens_start_no_quest_and_pay_no_reward()
	local rec = spyAllQuests()

	converse(trainer({}), trainingChoices("starships"))

	lu.assertEquals(rec.starts, {}, "quests started")
	lu.assertEquals(rec.rewards, {}, "rewards paid")
end

-- AC-5
function TestImlerTraining:test_leaving_after_training_keeps_the_flag_and_the_next_talk_starts_on_ready_mission()
	local player = trainer({})

	converse(player, trainingChoices("starships"))

	lu.assertEquals(firstScreen(player), "ready_mission", "next conversation after leaving before accepting")
end

-- skills held, expected briefing from ready_mission's option s_39e697de
local BRIEFS = {
	{ 0, "mission1_brief" },
	{ 1, "mission1_brief" },
	{ 2, "mission2_brief" },
	{ 3, "mission3_brief" },
	{ 4, "mission4_brief" },
}

for _, row in ipairs(BRIEFS) do
	-- AC-5
	TestImlerTraining["test_ready_mission_with_" .. row[1] .. "_tier4_skills_leads_to_" .. row[2]] = function()
		local count = row[1]
		local player = pilot({ skillCount = count, hist = math.max(count - 1, 0), ready = true })
		local transcript = converse(player, { "s_39e697de" })

		lu.assertEquals(transcript[1].id, "ready_mission", "first screen")
		lu.assertEquals(transcript[2].id, row[2], "screen after s_39e697de with " .. count .. " skills")
	end
end

-- AC-5, I-5
function TestImlerTraining:test_briefing_trained_failure_and_reward_screens_start_nothing()
	local reached = {}

	for n = 1, 4 do
		local rec = spyAllQuests()
		local player = pilot({ skillCount = n, hist = n - 1, ready = true })
		local transcript = converse(player, { "s_39e697de" })

		reached[#reached + 1] = transcript[2].id

		lu.assertEquals(rec.starts, {}, "mission" .. n .. "_brief: quests started")

		local failed = converse(pilot({ skillCount = n, hist = n - 1, attempted = concat(history(n - 1).attempted, { n }) }))

		lu.assertEquals(failed[1].id, "mission" .. n .. "_failed", "failed screen of mission " .. n)
		lu.assertEquals(rec.starts, {}, "mission" .. n .. "_failed: quests started")
	end

	lu.assertEquals(reached, { "mission1_brief", "mission2_brief", "mission3_brief", "mission4_brief" })
end

---------------------------------------------------------------------------------------------
-- AC-6: mission grants
---------------------------------------------------------------------------------------------

TestImlerMissionGrants = {}

function TestImlerMissionGrants:setUp()
	H.reset()
end

-- Walks `choices`, hooking stale journal completions of mission `mission` (and one quest of another
-- mission, which must survive) in just before the last choice.
local function withStaleHook(path, mission)
	local choices = {}

	for i, sid in ipairs(path) do
		if i == #path then
			local stale = {}

			for _, key in ipairs(D.MISSION[mission].chain) do
				stale[#stale + 1] = key
			end

			stale[#stale + 1] = D.MISSION[mission % 4 + 1].main

			choices[#choices + 1] = function(p) setComplete(p, stale) end
		end

		choices[#choices + 1] = sid
	end

	return choices
end

-- Start states that lead to the grant screens of mission n. Each returns player, choice path to the
-- screen `target`.
local ROUTES_TO_GRANT = {
	-- briefing reached from ready_mission (flag set, N skills)
	ready_mission = function(n, target)
		local player = pilot({ skillCount = n, hist = n - 1, ready = true })
		local path = concat({ "s_39e697de" }, pathBetween("mission" .. n .. "_brief", target))

		return player, path, "ready_mission"
	end,
	-- briefing reached right after buying the n-th skill
	training = function(n, target)
		local held = {}

		for i = 1, n - 1 do
			held[i] = D.SKILLS[i]
		end

		local player = pilot({ tier4 = held, hist = n - 1, xp = XP_FOR_TIER4, met = true })
		local path = concat({ REPLY[D.SKILLS[n]], D.BUY_OPTION[D.SKILLS[n]] }, pathBetween("trained_mission" .. n, target))

		return player, path, "ready_train"
	end,
	-- retry reached from the failed screen
	failed = function(n, target)
		local player = pilot({ skillCount = n, hist = n - 1, attempted = concat(history(n - 1).attempted, { n }) })
		local path = pathBetween("mission" .. n .. "_failed", target)

		return player, path, "mission" .. n .. "_failed"
	end,
}

local ROUTE_NAMES = { "ready_mission", "training", "failed" }

for n = 1, 4 do
	for _, target in ipairs(D.GRANT_SCREENS[n]) do
		local isRetry = target:find("retry") ~= nil

		for _, routeName in ipairs(ROUTE_NAMES) do
			if (routeName == "failed") == isRetry then
				-- AC-6
				TestImlerMissionGrants["test_" .. target .. "_starts_only_mission_" .. n .. "_main_quest_once_via_" .. routeName] = function()
					local rec = spyAllQuests()
					local player, path, startScreen = ROUTES_TO_GRANT[routeName](n, target)
					local transcript = converse(player, withStaleHook(path, n))

					lu.assertEquals(transcript[1].id, startScreen, target .. ": first screen")
					lu.assertEquals(transcript[#transcript].id, target, target .. ": last screen; got " .. table.concat(ids(transcript), ","))
					lu.assertEquals(rec.starts, { D.global(D.MISSION[n].main) }, target .. ": quests started")
					lu.assertEquals(H.getQuestStatus(player, D.MISSION[n].statusName .. ":attempted"), "1", target .. ": :attempted status")
					lu.assertNil(H.getQuestStatus(player, D.READY_SUFFIX), target .. ": readyForTier4Mission removed")
				end

				-- AC-6
				TestImlerMissionGrants["test_" .. target .. "_clears_old_journal_entries_of_mission_" .. n .. "_before_starting_via_" .. routeName] = function()
					local rec = spyAllQuests()
					local player, path = ROUTES_TO_GRANT[routeName](n, target)

					converse(player, withStaleHook(path, n))

					lu.assertEquals(#rec.starts, 1, target .. ": number of quest starts")

					for _, key in ipairs(D.MISSION[n].chain) do
						lu.assertFalse(contains(rec.completeAtStart[1], D.global(key)), target .. ": " .. D.global(key) .. " was still journal-complete when the mission started")
					end

					local otherKey = D.MISSION[n % 4 + 1].main

					lu.assertTrue(SpaceHelpers:isSpaceQuestComplete(player, D.QUEST[otherKey][1], D.QUEST[otherKey][2]), target .. ": " .. D.global(otherKey) .. " (another mission) must not be cleared")
				end
			end
		end
	end
end

-- AC-6, I-5
function TestImlerMissionGrants:test_only_the_grant_screen_itself_starts_a_quest_and_a_second_talk_does_not_restart()
	local rec = spyAllQuests()
	local player = pilot({ skillCount = 1, hist = 0, ready = true })

	converse(player)
	converse(player)

	lu.assertEquals(rec.starts, {}, "quests started by merely talking to Imler")
end

---------------------------------------------------------------------------------------------
-- AC-7: rewards
---------------------------------------------------------------------------------------------

TestImlerRewards = {}

function TestImlerRewards:setUp()
	H.reset()
end

local REWARDS = {
	{ 1, "1b", function() return pilot({ skillCount = 1, attempted = { 1 }, completed = { "m1b" } }) end },
	{ 1, "1b_without_attempted", function() return pilot({ skillCount = 1, completed = { "m1b" } }) end },
	{ 2, "2d", function() return pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 }, completed = { "m1b", "m2d" } }) end },
	{ 3, "3c", function() return pilot({ skillCount = 3, hist = 2, attempted = { 1, 2, 3 }, completed = { "m1b", "m2d", "m3c" } }) end },
	{ 4, "4c_win", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4cw" } }) end },
	{ 4, "4c_lose", function() return pilot({ skillCount = 4, hist = 3, attempted = { 1, 2, 3, 4 }, completed = { "m1b", "m2d", "m3c", "m4cl" } }) end },
}

for _, row in ipairs(REWARDS) do
	local mission, label, build = row[1], row[2], row[3]

	-- AC-7
	TestImlerRewards["test_mission_" .. mission .. "_reward_is_paid_once_variant_" .. label] = function()
		local rec = spyAllQuests()
		local player = build()
		local rebel, imperial = standing(player, "rebel"), standing(player, "imperial")
		local screen = "mission" .. mission .. "_reward"
		local transcript = converse(player)

		lu.assertEquals(transcript[1].id, screen, "first screen")
		lu.assertEquals(transcript[1].text, D.PREFIX .. D.SCREENS[screen], screen .. ": leftDialog")
		lu.assertEquals(rec.rewards, { D.global(D.MISSION[mission].main) }, screen .. ": rewardPlayer calls")
		lu.assertEquals(H.getQuestStatus(player, D.MISSION[mission].statusName .. ":reward"), "1", screen .. ": :reward status")
		lu.assertEquals(standing(player, "rebel"), rebel, screen .. ": rebel faction standing unchanged")
		lu.assertEquals(standing(player, "imperial"), imperial, screen .. ": imperial faction standing unchanged")
		lu.assertEquals(rec.starts, {}, screen .. ": quests started")
	end

	-- AC-7
	TestImlerRewards["test_mission_" .. mission .. "_reward_is_not_paid_again_on_the_next_talk_variant_" .. label] = function()
		local rec = spyAllQuests()
		local player = build()

		converse(player)

		local second = converse(player)

		lu.assertNotEquals(second[1].id, "mission" .. mission .. "_reward", "second conversation must not route to the reward again")
		lu.assertEquals(#rec.rewards, 1, "rewardPlayer calls after two conversations")
	end
end

-- AC-7
function TestImlerRewards:test_a_reward_already_paid_is_not_paid_again()
	local rec = spyAllQuests()
	local player = pilot({ skillCount = 1, hist = 1, met = true })

	local transcript = converse(player)

	lu.assertNotEquals(transcript[1].id, "mission1_reward", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-7
function TestImlerRewards:test_the_reward_is_paid_by_the_main_quest_of_the_mission_only()
	local rec = spyAllQuests()

	converse(pilot({ skillCount = 2, hist = 1, attempted = { 1, 2 }, completed = { "m1b", "m2d" } }))

	lu.assertEquals(rec.rewards, { "inspect_naboo_privateer_tier4_2a" }, "rewardPlayer calls for mission 2")
end

---------------------------------------------------------------------------------------------
-- AC-8: intro, duties, reset
---------------------------------------------------------------------------------------------

TestImlerIntroAndDuties = {}

function TestImlerIntroAndDuties:setUp()
	H.reset()
end

-- AC-8
function TestImlerIntroAndDuties:test_choosing_s_52917b0d_on_the_intro_shows_duty_info_sets_the_met_flag_and_skips_the_intro_next_time()
	local player = pilot({})

	lu.assertEquals(firstScreen(player), "intro", "first conversation")
	lu.assertNil(H.getQuestStatus(player, D.MET_SUFFIX), "StartedImler after only the intro line")

	local transcript = converse(player, { "s_52917b0d" })

	lu.assertEquals(ids(transcript), { "intro", "duty_info" })
	lu.assertEquals(H.getQuestStatus(player, D.MET_SUFFIX), "1", "StartedImler after duty_info")
	lu.assertEquals(firstScreen(player), "tier4_incomplete", "next conversation in the same state")
end

-- AC-8
function TestImlerIntroAndDuties:test_a_pilot_who_has_met_imler_never_sees_the_intro()
	lu.assertNotEquals(firstScreen(pilot({ met = true })), "intro")
end

-- Menu screens: name, state builder, option path from the conversation start to the menu screen.
local MENUS = {
	{ "tier4_incomplete", function() return pilot({ met = true }) end, {} },
	{ "here_for_work", function() return pilot({ skillCount = 4, hist = 4, met = true, master = true }) end, {} },
	{ "duty_info_end_from_tier4_incomplete", function() return pilot({ met = true }) end, concat({ "s_70d61202" }, pathBetween("duty_info", "duty_info_end")) },
	{ "duty_info_end_from_the_intro", function() return pilot({}) end, concat({ "s_52917b0d" }, pathBetween("duty_info", "duty_info_end")) },
}

for _, menu in ipairs(MENUS) do
	local label, build, path = menu[1], menu[2], menu[3]

	for _, duty in ipairs(D.DUTY_MENU) do
		if duty.quest then
			-- AC-8
			TestImlerIntroAndDuties["test_duty_menu_" .. label .. "_option_" .. duty.option .. "_starts_only_" .. duty.quest] = function()
				local rec = spyAllQuests()
				local player = build()
				local transcript = converse(player, concat(path, { duty.option }))
				local menuShown = transcript[#path + 1]

				lu.assertEquals(D.optionSids(menuShown.options), D.DUTY_MENU_SIDS, "options of the menu screen '" .. menuShown.id .. "'")
				lu.assertEquals(transcript[#path + 2].id, duty.screen, "screen after choosing " .. duty.option)
				lu.assertEquals(rec.starts, { duty.quest }, "quests started")
			end
		end
	end
end

-- AC-8
function TestImlerIntroAndDuties:test_choosing_duty_info_starts_no_quest()
	local rec = spyAllQuests()

	converse(pilot({ met = true }), { "s_70d61202" })

	lu.assertEquals(rec.starts, {}, "quests started")
end

-- AC-8
function TestImlerIntroAndDuties:test_reset_imler_quests_clears_all_17_constant_quests_from_the_journal()
	spyAllQuests()

	local player = pilot({ completed = D.QUEST_KEYS, active = { "m3b", "dRescue" } })

	for _, key in ipairs(D.QUEST_KEYS) do
		setComplete(player, { key })
	end

	lu.assertEquals(type(RsfSquadronScreenplay.resetImlerQuests), "function", "RsfSquadronScreenplay:resetImlerQuests is defined")

	RsfSquadronScreenplay:resetImlerQuests(player)

	for _, key in ipairs(D.QUEST_KEYS) do
		lu.assertFalse(SpaceHelpers:isSpaceQuestComplete(player, D.QUEST[key][1], D.QUEST[key][2]), D.global(key) .. " journal-complete after resetImlerQuests")
		lu.assertFalse(SpaceHelpers:isSpaceQuestActive(player, D.QUEST[key][1], D.QUEST[key][2]), D.global(key) .. " journal-active after resetImlerQuests")
	end
end

-- AC-8
function TestImlerIntroAndDuties:test_reset_imler_quests_removes_the_10_status_keys()
	spyAllQuests()

	local status = {}

	for _, suffix in ipairs(D.statusKeys()) do
		status[suffix] = "1"
	end

	lu.assertEquals(#D.statusKeys(), 10, "status keys listed by the spec")

	local player = H.newPlayer({ pilot = "neutral", squadronType = rawget(_G, "RSF_SQUADRON"), questStatus = status })

	for _, suffix in ipairs(D.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, suffix), "1", "precondition: " .. suffix)
	end

	lu.assertEquals(type(RsfSquadronScreenplay.resetImlerQuests), "function", "RsfSquadronScreenplay:resetImlerQuests is defined")

	RsfSquadronScreenplay:resetImlerQuests(player)

	for _, suffix in ipairs(D.statusKeys()) do
		lu.assertNil(H.getQuestStatus(player, suffix), suffix .. " after resetImlerQuests")
	end
end

-- AC-8
function TestImlerIntroAndDuties:test_reset_imler_quests_resets_the_13_story_quests_and_not_the_duties_and_leaves_the_pilot_tier_alone()
	local rec = spyAllQuests()
	local player = pilot({ pilotTier = 5 })

	lu.assertEquals(type(RsfSquadronScreenplay.resetImlerQuests), "function", "RsfSquadronScreenplay:resetImlerQuests is defined")

	RsfSquadronScreenplay:resetImlerQuests(player)

	local want = {}

	for _, key in ipairs(D.STORY_KEYS) do
		want[#want + 1] = D.global(key)
	end

	table.sort(want)
	table.sort(rec.resets)

	lu.assertEquals(rec.resets, want, "quests whose resetQuest was called")
	lu.assertEquals(tier(player), 5, "pilot tier after resetImlerQuests (surrenderPilot resets it afterwards)")
end

-- AC-8
function TestImlerIntroAndDuties:test_surrender_pilot_on_an_rsf_pilot_resets_the_tier4_quests_after_tier3()
	lu.assertEquals(type(RsfSquadronScreenplay.resetImlerQuests), "function", "RsfSquadronScreenplay:resetImlerQuests is defined")

	local order = {}

	for _, method in ipairs({ "resetDingeQuests", "resetKaydineQuests", "resetDuliosQuests", "resetImlerQuests" }) do
		H.spyOn(RsfSquadronScreenplay, method, function() order[#order + 1] = method end)
	end

	local player = pilot({ skillCount = 2, hist = 2, met = true })

	SpaceHelpers:surrenderPilot(player)

	lu.assertEquals(order, { "resetDingeQuests", "resetKaydineQuests", "resetDuliosQuests", "resetImlerQuests" }, "RSF reset functions called by surrenderPilot, in order")
end
