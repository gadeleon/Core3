-- Trainer routing: "mission running" covers every chain member (AC-5), and the won checks match SWG (AC-6).
-- Spec: .claude/work/space-trainer-fixes/01-spec.md (tables O and W)

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

local function firstScreen(tr, player)
	local transcript = T.converse(tr, player)

	lu.assertNotNil(transcript[1], tr.label .. ": the trainer shows no first screen")

	return transcript[1].id
end

local function minus(list, removed)
	local out = {}

	for _, g in ipairs(list) do
		if g ~= removed then
			out[#out + 1] = g
		end
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-5: a running chain member keeps the trainer on its "mission running" screen
---------------------------------------------------------------------------------------------

-- Table O, rows that change: { trainer, mission, screen }
local ON_MISSION_CHANGED = {
	{ "rhea", 1, "first_assignment" }, { "rhea", 3, "has_mission" },
	{ "dinge", 1, "first_assignment" }, { "dinge", 3, "has_mission" },
	{ "kreezo", 1, "first_quest_active" }, { "kreezo", 3, "has_mission" },
	{ "viopa", 1, "has_mission" },
	{ "aqzow", 1, "has_mission" }, { "aqzow", 2, "has_mission" }, { "aqzow", 3, "has_mission" }, { "aqzow", 4, "has_mission" },
	{ "dulios", 4, "on_mission" },
}

-- Table O, regression rows (the whole chain is already covered)
local ON_MISSION_REGRESSION = {
	{ "ramna", 1, "on_mission" }, { "ramna", 2, "on_mission" }, { "ramna", 3, "on_mission" }, { "ramna", 4, "on_mission" },
	{ "turoldine", 1, "on_mission" }, { "turoldine", 2, "on_mission" }, { "turoldine", 3, "on_mission" }, { "turoldine", 4, "on_mission" },
	{ "dulios", 1, "on_mission" }, { "dulios", 2, "on_mission" }, { "dulios", 3, "on_mission" },
}

TestTrainerMissionRunningChanged = {}

function TestTrainerMissionRunningChanged:setUp()
	H.reset()
end

TestTrainerMissionRunningRegression = {}

function TestTrainerMissionRunningRegression:setUp()
	H.reset()
end

-- With chain member `pos` running (head complete, the members before it complete), the first screen is `screen`
-- and nothing is rewarded, trained or started.
local function missionRunning(tr, n, pos, screen)
	local chain = tr.chains[n]
	local complete = pos == 1 and {} or T.before(tr, n, pos)
	local label = tr.label .. " mission " .. n .. " with " .. chain[pos] .. " running: "
	local player = T.player(tr, n, { complete = complete, active = { chain[pos] } })
	local rec = T.spyAllQuests()
	local first = firstScreen(tr, player)

	lu.assertEquals(first, screen, label .. "first screen")
	lu.assertEquals(rec.rewards, {}, label .. "rewardPlayer calls")
	lu.assertEquals(rec.starts, {}, label .. "startQuest calls")
	lu.assertEquals(#rec.skills, 0, label .. "grantSpaceSkill calls")
end

local function addRunningTests(class, rows, firstPos, lastPos)
	for _, row in ipairs(rows) do
		local tr = T.TRAINERS[row[1]]
		local n, screen = row[2], row[3]

		for pos = firstPos, lastPos or #tr.chains[n] do
			-- AC-5
			class[string.format("test_%s_mission_%d_shows_%s_while_chain_member_%d_is_running", row[1], n, screen, pos)] = function()
				missionRunning(tr, n, pos, screen)
			end
		end
	end
end

-- Non-head members: the states the old handlers got wrong. The head running is the old behavior (regression class).
addRunningTests(TestTrainerMissionRunningChanged, ON_MISSION_CHANGED, 2)
addRunningTests(TestTrainerMissionRunningRegression, ON_MISSION_CHANGED, 1, 1)
addRunningTests(TestTrainerMissionRunningRegression, ON_MISSION_REGRESSION, 1)

-- AC-5
-- rsf-tier3-renames (AC-9 M5): the legacy 4_initial entry is purged by the migration, so it no longer counts as
-- running; the pilot is routed by the remaining state (4a:attempted is set, so failed_fourth_mission). The migration
-- itself is covered in test_rsf_tier3_renames_migration.lua.
function TestTrainerMissionRunningChanged:test_dulios_mission_4_no_longer_counts_the_legacy_initial_surprise_attack_as_running()
	local tr = T.TRAINERS.dulios
	local player = T.player(tr, 4, { complete = {}, questStatus = { ["naboo_privateer_tier3_4_initial:attempted"] = "1" } })

	player.ghost:activateJournalQuest(H.questCrc("destroy_surpriseattack", "naboo_privateer_tier3_4_initial"), false)

	lu.assertEquals(firstScreen(tr, player), "failed_fourth_mission", "Dulios mission 4 with only the legacy initial surprise attack running: first screen")
end

---------------------------------------------------------------------------------------------
-- AC-6: won checks (table W)
---------------------------------------------------------------------------------------------

-- Rows marked "change" in table W: the SWG win quest, the screens, and the quest whose rewardPlayer pays.
local WON = {
	{ trainer = "dulios", n = 2, win = "rescue_naboo_privateer_tier3_2e", failed = "failed_second_mission", reward = "complete_mission2", pays = "escort_naboo_privateer_tier3_2a" },
	{ trainer = "dulios", n = 3, win = "survival_naboo_privateer_tier3_3c", failed = "failed_third_mission", reward = "complete_mission3", pays = "inspect_naboo_privateer_tier3_3a" },
	{ trainer = "dulios", n = 4, win = "assassinate_naboo_privateer_tier3_4f", failed = "failed_fourth_mission", reward = "complete_mission4", pays = "assassinate_naboo_privateer_tier3_4a" },
	{ trainer = "viopa", n = 1, win = "destroy_surpriseattack_viopa_rebel_1", failed = "failed_mission1", reward = "excellent_work", pays = "inspect_viopa_rebel_1" },
	{ trainer = "aqzow", n = 1, win = "space_battle_corellia_rebel_tier3_1_d", failed = "failed_quest1", reward = "excellent_work", pays = "recovery_corellia_rebel_tier3_1" },
	{ trainer = "aqzow", n = 2, win = "escort_corellia_rebel_tier3_2_c", failed = "failed_quest2", reward = "excellent_work2", pays = "inspect_corellia_rebel_tier3_2" },
	{ trainer = "aqzow", n = 3, win = "escort_corellia_rebel_tier3_3_c", failed = "failed_quest3", reward = "excellent_work3", pays = "delivery_corellia_rebel_tier3_3" },
	{ trainer = "aqzow", n = 4, win = "survival_corellia_rebel_tier3_4_d", failed = "failed_quest4", reward = "excellent_work4", pays = "assassinate_corellia_rebel_tier3_4" },
}

TestTrainerWonChecks = {}

function TestTrainerWonChecks:setUp()
	H.reset()
end

for _, row in ipairs(WON) do
	local tr = T.TRAINERS[row.trainer]
	local chain = tr.chains[row.n]
	local name = string.format("%s_mission_%d", row.trainer, row.n)

	-- AC-6
	TestTrainerWonChecks["test_" .. name .. "_shows_" .. row.failed .. "_when_every_member_but_" .. row.win .. "_is_complete"] = function()
		local player = T.player(tr, row.n, { complete = minus(chain, row.win) })
		local rec = T.spyAllQuests()
		local label = tr.label .. " mission " .. row.n .. " with " .. row.win .. " failed: "

		lu.assertEquals(T.state(player, row.win), "none", label .. "setup")
		lu.assertEquals(firstScreen(tr, player), row.failed, label .. "first screen")
		lu.assertEquals(rec.rewards, {}, label .. "rewardPlayer calls")
		lu.assertEquals(rec.starts, {}, label .. "startQuest calls")
		lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, row.n) .. ":reward"), nil, label .. ":reward flag")
	end

	-- AC-6
	TestTrainerWonChecks["test_" .. name .. "_shows_" .. row.failed .. "_when_only_the_head_is_complete"] = function()
		local player = T.player(tr, row.n, { complete = { chain[1] } })
		local rec = T.spyAllQuests()
		local label = tr.label .. " mission " .. row.n .. " with only the head complete: "

		lu.assertEquals(firstScreen(tr, player), row.failed, label .. "first screen")
		lu.assertEquals(rec.rewards, {}, label .. "rewardPlayer calls")
	end

	-- AC-6
	TestTrainerWonChecks["test_" .. name .. "_pays_the_reward_once_when_" .. row.win .. "_is_complete"] = function()
		local player = T.player(tr, row.n, { complete = chain })
		local rec = T.spyAllQuests()
		local label = tr.label .. " mission " .. row.n .. " won: "

		lu.assertEquals(firstScreen(tr, player), row.reward, label .. "first screen")
		lu.assertEquals(rec.rewards, { row.pays }, label .. "rewardPlayer calls")
		lu.assertEquals(H.getQuestStatus(player, T.statusName(tr, row.n) .. ":reward"), "1", label .. ":reward flag")

		-- talking again must not pay again
		firstScreen(tr, player)

		lu.assertEquals(rec.rewards, { row.pays }, label .. "rewardPlayer calls after a second talk")
	end

	-- AC-6
	TestTrainerWonChecks["test_" .. name .. "_pays_nothing_again_once_the_reward_flag_is_set"] = function()
		local player = T.player(tr, row.n, { complete = chain, questStatus = { [T.statusName(tr, row.n) .. ":reward"] = "1" } })
		local rec = T.spyAllQuests()

		firstScreen(tr, player)

		lu.assertEquals(rec.rewards, {}, tr.label .. " mission " .. row.n .. " won and already rewarded: rewardPlayer calls")
	end
end

-- AC-6
function TestTrainerWonChecks:test_dulios_mission_3_is_won_by_the_survival_quest_alone_at_skill_count_2()
	local tr = T.TRAINERS.dulios
	local player = T.player(tr, 3, { complete = { "survival_naboo_privateer_tier3_3c" } })

	lu.assertEquals(SpaceHelpers:getPilotTierSkillCount(player, "neutral", 3), 2, "setup: tier 3 skill count")
	lu.assertEquals(firstScreen(tr, player), "complete_mission3", "Dulios mission 3 with survival_naboo_privateer_tier3_3c complete: first screen")
end

-- AC-6
function TestTrainerWonChecks:test_dulios_mission_3_is_not_won_by_the_never_started_surprise_attack()
	local tr = T.TRAINERS.dulios
	local player = T.player(tr, 3, { complete = { "destroy_surpriseattack_naboo_privateer_tier3_3e" } })

	lu.assertEquals(firstScreen(tr, player), "failed_third_mission", "Dulios mission 3 with only 3e complete: first screen")
end
