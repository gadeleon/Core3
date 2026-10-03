-- Ramna (CorSec tier 3) after corsec-tier3-extensions: mission 4 runs on the 4-member chain
-- (assassinate tier3_4 > survival 4_a > inspect 4_b > delivery_no_pickup 4_c), the veteran rule (D-10) and the fixed
-- mission 3 retry screen (D-11).
-- Spec: .claude/work/corsec-tier3-extensions/01-spec.md (AC-6, AC-7, AC-8, AC-10, Conversation flow, Migration).
--
-- SWG answer key: fixtures/script/conversation/corellia_privateer_tier3.java
--   :161, 195-197   mission 4 reward screen / won check = hasCompletedQuestRecursive(assassinate, tier3_4)
--   :75-82          failedQuestFour (recursive chain end not complete, mission 4 attempted)
--   :509-523, 525-540  the two mission 3 retry branches (s_25d2c630 > s_7d83809c, s_77b0e9f8 > s_a26f4215)
-- The data-driven suites (test_trainer_fixes_routing/retry/reset/chain_helper) cover the longer chain through
-- trainer_fixes_data.lua; this file adds the cases they do not generate.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local tr = T.TRAINERS.ramna

local HEAD = "assassinate_corellia_privateer_tier3_4"
local SURVIVAL = "survival_corellia_privateer_tier3_4_a"
local INSPECT = "inspect_corellia_privateer_tier3_4_b"
local DELIVERY = "delivery_no_pickup_corellia_privateer_tier3_4_c"
local M4 = { HEAD, SURVIVAL, INSPECT, DELIVERY }
local M3_HEAD = "delivery_corellia_privateer_tier3_3"

local PREFIX = "@conversation/corellia_privateer_tier3:"

local function firstScreen(player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], "Ramna shows no first screen")
	return transcript[1].id
end

local function ids(transcript)
	local out = {}

	for i, t in ipairs(transcript) do
		out[i] = t.id
	end

	return out
end

local function mission4(opts) return T.player(tr, 4, opts or {}) end

local FOURTH_WEAPONS = "pilot_neutral_weapons_03" -- tier 3 skills 1..3 come from the builder (droid, procedures, starships)

local function reward1() return { [T.statusName(tr, 4) .. ":reward"] = "1" } end

---------------------------------------------------------------------------------------------
-- AC-6 (d): constants
---------------------------------------------------------------------------------------------

TestRamnaTier3Constants = {}

function TestRamnaTier3Constants:setUp() H.reset() end

-- AC-6 (d)
function TestRamnaTier3Constants:test_the_new_chain_constants_equal_the_contract()
	lu.assertEquals(CorsecSquadronScreenplay.TIER3_QUEST_STRING_4_SIDE2, { type = "inspect", name = "corellia_privateer_tier3_4_b" }, "TIER3_QUEST_STRING_4_SIDE2")
	lu.assertEquals(CorsecSquadronScreenplay.TIER3_QUEST_STRING_4_SIDE3, { type = "delivery_no_pickup", name = "corellia_privateer_tier3_4_c" }, "TIER3_QUEST_STRING_4_SIDE3")
end

-- AC-6 (d), D-8: the constants agree with the chain walker
function TestRamnaTier3Constants:test_the_four_mission_4_constants_name_the_walker_chain_in_order()
	local c = CorsecSquadronScreenplay
	local fromConstants = {}

	for _, k in ipairs({ "TIER3_QUEST_STRING_4", "TIER3_QUEST_STRING_4_SIDE1", "TIER3_QUEST_STRING_4_SIDE2", "TIER3_QUEST_STRING_4_SIDE3" }) do
		lu.assertNotNil(c[k], "CorsecSquadronScreenplay." .. k)
		fromConstants[#fromConstants + 1] = c[k].type .. "_" .. c[k].name
	end

	local walked = {}

	for i, e in ipairs(SpaceHelpers:getSpaceQuestChain(HEAD)) do
		walked[i] = e.global
	end

	lu.assertEquals(fromConstants, walked, "mission 4 constants vs SpaceHelpers:getSpaceQuestChain(" .. HEAD .. ")")
	lu.assertEquals(walked, M4, "the walker chain")
end

---------------------------------------------------------------------------------------------
-- AC-6 (a): on_mission for every running member
---------------------------------------------------------------------------------------------

TestRamnaTier3OnMission = {}

function TestRamnaTier3OnMission:setUp() H.reset() end

for pos, global in ipairs(M4) do
	-- AC-6 (a): the running member alone (earlier ones complete or absent)
	TestRamnaTier3OnMission["test_" .. global .. "_running_with_the_earlier_members_complete_shows_on_mission"] = function()
		local complete = {}

		for i = 1, pos - 1 do
			complete[#complete + 1] = M4[i]
		end

		local player = mission4({ complete = complete, active = { global } })
		local rec = T.spyAllQuests()

		lu.assertEquals(firstScreen(player), "on_mission", "Ramna with " .. global .. " running (" .. T.describe(player, M4) .. "): first screen")
		lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, "startQuest calls")
	end

	-- AC-6 (a): the running member alone, the earlier ones absent (an aborted-and-restarted chain)
	TestRamnaTier3OnMission["test_" .. global .. "_running_alone_shows_on_mission"] = function()
		local player = mission4({ active = { global } })

		lu.assertEquals(firstScreen(player), "on_mission", "Ramna with only " .. global .. " running (" .. T.describe(player, M4) .. "): first screen")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6 (b), (c): the won check is the chain end
---------------------------------------------------------------------------------------------

TestRamnaTier3WonCheck = {}

function TestRamnaTier3WonCheck:setUp() H.reset() end

-- AC-6 (b)
function TestRamnaTier3WonCheck:test_4_c_complete_shows_complete_mission4_and_pays_the_head_reward_once_across_two_conversations()
	local player = mission4({ complete = M4 })
	local rec = T.spyAllQuests()

	lu.assertEquals(T.state(player, DELIVERY), "complete", "setup: the chain end is complete")
	lu.assertNil(H.getQuestStatus(player, T.statusName(tr, 4) .. ":reward"), "setup: no reward flag yet")
	lu.assertEquals(firstScreen(player), "complete_mission4", "first conversation")
	lu.assertEquals(rec.rewards, { HEAD }, "rewardPlayer calls after the first conversation")
	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 4) .. ":reward"), "1", ":reward flag")
	lu.assertEquals(firstScreen(player), "complete_mission4", "second conversation")
	lu.assertEquals(rec.rewards, { HEAD }, "rewardPlayer calls after the second conversation")
end

-- AC-6 (b)
function TestRamnaTier3WonCheck:test_4_c_complete_with_the_reward_flag_set_pays_nothing()
	local player = mission4({ complete = M4, questStatus = reward1() })
	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-6 (b): the complete screen only counts with the chain end, not with the head alone
function TestRamnaTier3WonCheck:test_4_c_complete_with_all_four_tier_3_skills_shows_completed_ramna_and_raises_the_tier()
	local player = mission4({ complete = M4, skills = { FOURTH_WEAPONS } })
	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(player), "completed_ramna", "first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-6 (c)
function TestRamnaTier3WonCheck:test_4_a_complete_and_4_b_failed_shows_failed_fourth_mission_and_pays_nothing()
	local player = mission4({ complete = { HEAD, SURVIVAL } })
	local rec = T.spyAllQuests()

	lu.assertEquals(T.describe(player, M4), HEAD .. "=complete, " .. SURVIVAL .. "=complete, " .. INSPECT .. "=none, " .. DELIVERY .. "=none", "setup")
	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 4) .. ":attempted"), "1", "setup: attempted")
	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertNil(H.getQuestStatus(player, T.statusName(tr, 4) .. ":reward"), ":reward flag")
end

-- AC-6 (c)
function TestRamnaTier3WonCheck:test_4_b_complete_and_4_c_failed_shows_failed_fourth_mission_and_pays_nothing()
	local player = mission4({ complete = { HEAD, SURVIVAL, INSPECT } })
	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertNil(H.getQuestStatus(player, T.statusName(tr, 4) .. ":reward"), ":reward flag")
end

-- AC-6 (c): the old win (4_a) no longer pays without the flag
function TestRamnaTier3WonCheck:test_the_head_alone_complete_shows_failed_fourth_mission()
	local player = mission4({ complete = { HEAD } })
	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-6 edge: no quest state at all for mission 4 and mission 4 never attempted
function TestRamnaTier3WonCheck:test_a_pilot_who_won_mission_3_and_never_tried_mission_4_is_offered_it()
	local player = mission4({ attempted = false })
	local rec = T.spyAllQuests()

	lu.assertEquals(T.describe(player, M4), HEAD .. "=none, " .. SURVIVAL .. "=none, " .. INSPECT .. "=none, " .. DELIVERY .. "=none", "setup")
	lu.assertEquals(firstScreen(player), "fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- AC-7: retry and reset
---------------------------------------------------------------------------------------------

TestRamnaTier3RetryAndReset = {}

function TestRamnaTier3RetryAndReset:setUp() H.reset() end

-- AC-7
function TestRamnaTier3RetryAndReset:test_taking_a_mission_4_start_screen_after_4_b_failed_clears_the_chain_and_starts_the_head_only()
	local function build() return mission4({ complete = { HEAD, SURVIVAL } }) end

	local rec
	local transcript, err, player = T.driveToStart(tr, 4, build, function() rec = T.spyRewards() end)

	lu.assertNotNil(transcript, tostring(err))

	local ended = T.endedOnStart(tr, 4, transcript)

	lu.assertNotNil(ended, "the conversation must end on a mission 4 start screen, got " .. table.concat(ids(transcript), " > "))
	lu.assertEquals(T.state(player, HEAD), "active", "after '" .. ended .. "': " .. HEAD .. " (" .. T.describe(player, M4) .. ")")
	lu.assertEquals(T.state(player, SURVIVAL), "none", "after '" .. ended .. "': " .. SURVIVAL)
	lu.assertEquals(T.state(player, INSPECT), "none", "after '" .. ended .. "': " .. INSPECT)
	lu.assertEquals(T.state(player, DELIVERY), "none", "after '" .. ended .. "': " .. DELIVERY)
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

-- AC-7: 4_c left over from an earlier run must not survive the restart
function TestRamnaTier3RetryAndReset:test_a_leftover_4_c_entry_is_cleared_when_the_chain_restarts()
	local function build() return mission4({ complete = { HEAD, SURVIVAL, INSPECT } }) end

	local transcript, err, player = T.driveToStart(tr, 4, build)

	lu.assertNotNil(transcript, tostring(err))
	lu.assertNotNil(T.endedOnStart(tr, 4, transcript), "the conversation must end on a mission 4 start screen, got " .. table.concat(ids(transcript), " > "))
	lu.assertEquals(T.describe(player, M4), HEAD .. "=active, " .. SURVIVAL .. "=none, " .. INSPECT .. "=none, " .. DELIVERY .. "=none", "chain after the restart")
end

-- AC-7
function TestRamnaTier3RetryAndReset:test_reset_ramna_quests_clears_all_sixteen_chain_members_of_a_veteran()
	local members = {}

	for n = 1, 4 do
		for _, g in ipairs(tr.chains[n]) do
			members[#members + 1] = g
		end
	end

	lu.assertEquals(#members, 16, "setup: the Ramna chains have 16 members")

	local player = T.player(tr, 4, { win = { 1, 2, 3, 4 } })

	for _, g in ipairs(members) do
		lu.assertEquals(T.state(player, g), "complete", "setup: " .. g)
	end

	CorsecSquadronScreenplay:resetRamnaQuests(player)

	local left = {}

	for _, g in ipairs(members) do
		if T.state(player, g) ~= "none" then
			left[#left + 1] = g .. "=" .. T.state(player, g)
		end
	end

	lu.assertEquals(left, {}, "chain members still in the journal after resetRamnaQuests")
end

-- AC-7: the two new members are also cleared from a running chain
function TestRamnaTier3RetryAndReset:test_reset_ramna_quests_clears_a_running_4_b_and_4_c()
	for _, g in ipairs({ INSPECT, DELIVERY }) do
		local player = mission4({ complete = { HEAD, SURVIVAL }, active = { g } })

		CorsecSquadronScreenplay:resetRamnaQuests(player)
		lu.assertEquals(T.state(player, g), "none", g .. " after resetRamnaQuests")
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: veterans (D-10)
---------------------------------------------------------------------------------------------

TestRamnaTier3Veterans = {}

function TestRamnaTier3Veterans:setUp() H.reset() end

-- AC-8
function TestRamnaTier3Veterans:test_a_veteran_with_4_a_complete_the_reward_flag_and_all_four_skills_gets_completed_ramna()
	local player = mission4({ complete = { HEAD, SURVIVAL }, skills = { FOURTH_WEAPONS }, questStatus = reward1() })
	local rec = T.spyAllQuests()

	lu.assertTrue(SpaceHelpers:hasCompletedPilotTier(player, "neutral", 3), "setup: all four tier 3 skills")
	lu.assertEquals(T.state(player, INSPECT), "none", "setup: 4_b absent")
	lu.assertEquals(T.state(player, DELIVERY), "none", "setup: 4_c absent")
	lu.assertEquals(firstScreen(player), "completed_ramna", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier is raised as completed_ramna does")
end

-- AC-8
function TestRamnaTier3Veterans:test_a_veteran_with_the_reward_flag_and_three_skills_gets_complete_mission4_without_a_second_payment()
	local player = mission4({ complete = { HEAD, SURVIVAL }, questStatus = reward1() })
	local rec = T.spyAllQuests()

	lu.assertEquals(SpaceHelpers:getPilotTierSkillCount(player, "neutral", 3), 3, "setup: three tier 3 skills")
	lu.assertEquals(firstScreen(player), "complete_mission4", "first screen")
	lu.assertEquals(firstScreen(player), "complete_mission4", "second conversation")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 4) .. ":reward"), "1", ":reward flag unchanged")
end

-- AC-8
function TestRamnaTier3Veterans:test_a_pilot_with_4_a_complete_and_no_reward_flag_must_fly_the_chain_again()
	local player = mission4({ complete = { HEAD, SURVIVAL }, skills = { FOURTH_WEAPONS } })
	local rec = T.spyAllQuests()

	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 4) .. ":attempted"), "1", "setup: attempted")
	lu.assertEquals(firstScreen(player), "failed_fourth_mission", "first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier is not raised")
end

-- AC-8 edge: the veteran rule needs the completed 4_a, not only the flag
function TestRamnaTier3Veterans:test_the_reward_flag_without_a_complete_4_a_is_not_a_win()
	local player = mission4({ complete = { HEAD }, skills = { FOURTH_WEAPONS }, questStatus = reward1() })
	local rec = T.spyAllQuests()

	lu.assertNotEquals(firstScreen(player), "completed_ramna", "head complete, 4_a absent, flag set, four skills")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- AC-10: the duplicate go_back_get_some screen (D-11)
---------------------------------------------------------------------------------------------

TestRamnaTier3Template = {}

function TestRamnaTier3Template:setUp() H.reset() end

local function screen(id)
	for _, s in ipairs(H.conversationTemplateTable(tr.template).screens) do
		if s.id == id then
			return s
		end
	end

	return nil
end

local function optionTo(s, sid)
	for _, o in ipairs(s.options or {}) do
		if o[1] == PREFIX .. sid then
			return o[2]
		end
	end

	return nil
end

-- AC-10
function TestRamnaTier3Template:test_the_template_has_no_duplicate_ids_and_no_dead_links()
	lu.assertEquals(H.conversationProblems(tr.template), {}, "ramna_convo_template problems")
end

-- AC-10
function TestRamnaTier3Template:test_counting_on_you_is_the_s_a26f4215_screen_and_ends_the_conversation()
	local s = screen("counting_on_you")

	lu.assertNotNil(s, "ramna_convo_template: no screen 'counting_on_you'")
	lu.assertEquals(s.leftDialog, PREFIX .. "s_a26f4215", "leftDialog")
	lu.assertEquals(s.animation, "rub_chin_thoughtful", "animation")
	lu.assertEquals(s.playerAnimation, "shake_head_no", "playerAnimation")
	lu.assertEquals(s.stopConversation, "true", "stopConversation")
	lu.assertEquals(s.options, {}, "options")
end

-- AC-10
function TestRamnaTier3Template:test_on_the_job_links_no_i_can_do_it_to_counting_on_you_and_blew_it_keeps_go_back_get_some()
	lu.assertEquals(optionTo(screen("on_the_job"), "s_77b0e9f8"), "counting_on_you", "on_the_job: 'No. I can do it.' link")
	lu.assertEquals(optionTo(screen("blew_it"), "s_25d2c630"), "go_back_get_some", "blew_it: 'You sound like my mom.' link")

	local s = screen("go_back_get_some")

	lu.assertNotNil(s, "go_back_get_some")
	lu.assertEquals(s.leftDialog, PREFIX .. "s_7d83809c", "go_back_get_some leftDialog is unchanged")
	lu.assertEquals(s.animation, "laugh", "go_back_get_some animation is unchanged")
	lu.assertEquals(s.stopConversation, "true", "go_back_get_some stopConversation is unchanged")
end

-- AC-10: the SWG branches this pins
function TestRamnaTier3Template:test_the_swg_trainer_script_has_the_two_mission_3_retry_branches()
	local f = assert(io.open(H.FIXTURES .. "script/conversation/corellia_privateer_tier3.java", "r"))
	local java = f:read("a")

	f:close()
	lu.assertNotNil(java:find("s_a26f4215", 1, true), "SWG script mentions s_a26f4215")
	lu.assertNotNil(java:find("s_7d83809c", 1, true), "SWG script mentions s_7d83809c")
end

local function failedThirdPlayer() return T.player(tr, 3, {}) end

-- AC-10
function TestRamnaTier3Template:test_no_i_can_do_it_shows_counting_on_you_and_starts_mission_3()
	local player = failedThirdPlayer()
	local transcript = T.converse(tr, player, { "s_5d9d0e58", "s_77b0e9f8" })

	lu.assertEquals(ids(transcript), { "failed_third_mission", "on_the_job", "counting_on_you" }, "screens shown")

	local last = transcript[#transcript]

	lu.assertEquals(last.text, PREFIX .. "s_a26f4215", "last screen text")
	lu.assertTrue(last.stop and true or false, "last screen ends the conversation")
	lu.assertEquals(T.state(player, M3_HEAD), "active", "mission 3 head after the retry (" .. T.describe(player, tr.chains[3]) .. ")")
	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 3) .. ":attempted"), "1", "mission 3 :attempted")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions")
end

-- AC-10
function TestRamnaTier3Template:test_you_sound_like_my_mom_shows_go_back_get_some_and_starts_mission_3()
	local player = failedThirdPlayer()
	local transcript = T.converse(tr, player, { "s_bf7ad2b4", "s_25d2c630" })

	lu.assertEquals(ids(transcript), { "failed_third_mission", "blew_it", "go_back_get_some" }, "screens shown")

	local last = transcript[#transcript]

	lu.assertEquals(last.text, PREFIX .. "s_7d83809c", "last screen text")
	lu.assertTrue(last.stop and true or false, "last screen ends the conversation")
	lu.assertEquals(T.state(player, M3_HEAD), "active", "mission 3 head after the retry")
	lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, 3) .. ":attempted"), "1", "mission 3 :attempted")
	lu.assertEquals(#player.datapad.items, 1, "datapad missions")
end

-- AC-10 edge: a failed mission 3 child restarts the whole chain from the retry screen
function TestRamnaTier3Template:test_the_counting_on_you_retry_clears_a_half_finished_mission_3_chain()
	local player = T.player(tr, 3, { complete = { M3_HEAD, "escort_corellia_privateer_tier3_3_pre_a" } })
	local transcript = T.converse(tr, player, { "s_5d9d0e58", "s_77b0e9f8" })

	lu.assertEquals(ids(transcript)[#transcript], "counting_on_you", "last screen")
	lu.assertEquals(T.describe(player, tr.chains[3]),
		"delivery_corellia_privateer_tier3_3=active, escort_corellia_privateer_tier3_3_pre_a=none, patrol_corellia_privateer_tier3_3_a=none, assassinate_corellia_privateer_tier3_3d=none",
		"mission 3 chain after the retry")
end
