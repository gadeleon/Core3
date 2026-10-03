-- Pilots who finished tier 3 before the won checks changed (they were credited under the old head-only check):
-- the "tier complete" screens of Aqzow and Dulios.
-- Review findings R-2 and R-4 of .claude/work/space-trainer-fixes/04-review.md.
--
-- SWG answer keys (fixtures/script/conversation/*.java):
--   Aqzow, corellia_rebel_tier3.java:64-70 and the branch at :3864: `completed_aqzow` (s_6100696) is shown when
--   isReadyForTier4 = hasCompletedTierThree && viopaPilot && hasReceivedReward(assassinate, corellia_rebel_tier3_4),
--   i.e. the tier 3 skills and the mission 4 reward, not the recursive chain check.
--   Dulios, naboo_privateer_tier3.java:188-190 and :5549: there is no ready-for-tier-4 condition; the final screen
--   is the default after hasCompletedQuestRecursive(assassinate, naboo_privateer_tier3_4a) holds, so a veteran
--   whose chain end is not complete is offered mission 4 again (Core3: failed_fourth_mission).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local function readAll(rel)
	local f = assert(io.open(H.FIXTURES .. rel, "r"), "missing fixture " .. rel)
	local text = f:read("a")

	f:close()
	return text
end

local function firstScreen(tr, player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], tr.label .. ": no first screen")
	return transcript[1].id
end

local function minusLast(chain)
	local out = {}

	for i = 1, #chain - 1 do
		out[i] = chain[i]
	end

	return out
end

TestTrainerVeterans = {}

function TestTrainerVeterans:setUp()
	H.reset()
end

-- R-2: the SWG conditions this test file pins
function TestTrainerVeterans:test_swg_gates_aqzow_on_the_mission_4_reward_and_dulios_on_the_recursive_chain_end()
	local aqzow = readAll("script/conversation/corellia_rebel_tier3.java")
	local from = aqzow:find("condition_isReadyForTier4(", 1, true)
	local isReady = from and aqzow:sub(from, (aqzow:find("public boolean", from + 10, true) or #aqzow))

	lu.assertNotNil(isReady, "SWG Aqzow isReadyForTier4 body")
	lu.assertNotNil(isReady:find('hasReceivedReward(player, "assassinate", "corellia_rebel_tier3_4")', 1, true), "isReadyForTier4 checks the mission 4 reward")
	lu.assertNil(isReady:find("Recursive", 1, true), "isReadyForTier4 does not use the recursive chain check")

	local dulios = readAll("script/conversation/naboo_privateer_tier3.java")

	lu.assertNil(dulios:find("isReadyForTier4", 1, true), "SWG Dulios has no ready-for-tier-4 condition")
	lu.assertNotNil(dulios:find('hasCompletedQuestRecursive(player, "assassinate", "naboo_privateer_tier3_4a")', 1, true), "SWG Dulios mission 4 is the recursive chain check")
end

-- R-2
function TestTrainerVeterans:test_a_tier_3_veteran_credited_under_the_old_head_check_gets_completed_aqzow()
	local tr = T.TRAINERS.aqzow
	local chain = tr.chains[4]
	local player = T.player(tr, 4, { complete = minusLast(chain), skills = { "pilot_rebel_navy_weapons_03" }, questStatus = { [T.statusName(tr, 4) .. ":reward"] = "1" } })

	lu.assertEquals(T.state(player, chain[#chain]), "none", "setup: the chain end is not complete")
	lu.assertTrue(SpaceHelpers:hasCompletedPilotTier(player, "rebel_navy", 3), "setup: tier 3 skills complete")

	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(tr, player), "completed_aqzow", "Aqzow veteran (head complete, :reward set, " .. chain[#chain] .. " absent): first screen")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, "startQuest calls")
	lu.assertEquals(player.ghost:getPilotTier(), 4, "pilot tier is raised as completed_aqzow does")
end

-- R-2: a veteran with only the head complete (an early mission also has a gap) is still sent on
function TestTrainerVeterans:test_a_veteran_whose_other_missions_also_lack_the_chain_end_still_gets_completed_aqzow()
	local tr = T.TRAINERS.aqzow
	local complete = {}

	for n = 1, 4 do
		complete[#complete + 1] = tr.chains[n][1]
	end

	local flags = {}

	for n = 1, 4 do
		flags[T.statusName(tr, n) .. ":reward"] = "1"
	end

	local player = T.player(tr, 4, { win = {}, complete = complete, skills = { "pilot_rebel_navy_weapons_03" }, questStatus = flags })

	lu.assertEquals(firstScreen(tr, player), "completed_aqzow", "Aqzow veteran with only the four heads complete: first screen")
end

-- R-2: the gate needs the reward
function TestTrainerVeterans:test_aqzow_does_not_send_a_pilot_on_before_the_mission_4_reward()
	local tr = T.TRAINERS.aqzow
	local chain = tr.chains[4]
	local player = T.player(tr, 4, { complete = minusLast(chain), skills = { "pilot_rebel_navy_weapons_03" } })

	lu.assertNotEquals(firstScreen(tr, player), "completed_aqzow", "Aqzow with tier 3 done but no mission 4 reward: first screen")
end

-- R-2 (regression): a pilot who won mission 4 properly
function TestTrainerVeterans:test_a_pilot_who_won_all_four_missions_gets_completed_aqzow()
	local tr = T.TRAINERS.aqzow
	local player = T.player(tr, 4, { complete = tr.chains[4], skills = { "pilot_rebel_navy_weapons_03" }, questStatus = { [T.statusName(tr, 4) .. ":reward"] = "1" } })

	lu.assertEquals(firstScreen(tr, player), "completed_aqzow", "Aqzow after a clean run: first screen")
end

-- R-4: the SWG answer for the same veteran at Dulios is the mission 4 offer, not the final screen
function TestTrainerVeterans:test_a_dulios_veteran_whose_chain_end_is_not_complete_is_offered_mission_4_again()
	local tr = T.TRAINERS.dulios
	local chain = tr.chains[4]
	local player = T.player(tr, 4, { complete = minusLast(chain), skills = { "pilot_neutral_weapons_03" }, questStatus = { [T.statusName(tr, 4) .. ":reward"] = "1" } })

	lu.assertEquals(T.state(player, chain[#chain]), "none", "setup: the chain end is not complete")
	lu.assertTrue(SpaceHelpers:hasCompletedPilotTier(player, "neutral", 3), "setup: tier 3 skills complete")
	lu.assertEquals(firstScreen(tr, player), "failed_fourth_mission", "Dulios veteran (4a complete, " .. chain[#chain] .. " absent): first screen (SWG shows the mission 4 offer)")
end

-- R-4 (regression): a clean run reaches completed_dulios
function TestTrainerVeterans:test_a_dulios_pilot_who_won_all_four_missions_gets_completed_dulios()
	local tr = T.TRAINERS.dulios
	local player = T.player(tr, 4, { complete = tr.chains[4], skills = { "pilot_neutral_weapons_03" }, questStatus = { [T.statusName(tr, 4) .. ":reward"] = "1" } })

	lu.assertEquals(firstScreen(tr, player), "completed_dulios", "Dulios after a clean run: first screen")
end

-- R-6: the "tier 3 complete" half of the completed_aqzow gate (SWG hasCompletedTierThree)
function TestTrainerVeterans:test_aqzow_with_the_reward_and_the_chain_end_but_three_tier_3_skills_is_not_complete()
	local tr = T.TRAINERS.aqzow
	local player = T.player(tr, 4, { complete = tr.chains[4], questStatus = { [T.statusName(tr, 4) .. ":reward"] = "1" } })

	lu.assertEquals(SpaceHelpers:getPilotTierSkillCount(player, "rebel_navy", 3), 3, "setup: three tier 3 skills")

	local rec = T.spyAllQuests()

	lu.assertEquals(firstScreen(tr, player), "excellent_work4", "Aqzow with the M4 reward, the chain end and only three tier 3 skills: first screen")
	lu.assertEquals(player.ghost:getPilotTier(), 3, "pilot tier is not raised before the fourth skill")
	lu.assertEquals(rec.rewards, {}, "rewardPlayer calls")
end
