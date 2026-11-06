-- Storm tier 2, the Nym technicians: StormSquadronScreenplay:getClawStage, canStartClaw, startClaw and the reset of the tip key.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-3, AC-10 (reset), I-3, I-5; Content contract 1; D-3, D-5).

local lu = require("luaunit")
local H = require("harness")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local function setUp()
	H.reset()
	N.load()
end

local function stageOf(player) return N.squadron(lu):getClawStage(player) end

---------------------------------------------------------------------------------------------
-- AC-3: getClawStage
---------------------------------------------------------------------------------------------

TestStormNymStage = {}

TestStormNymStage.setUp = setUp

-- AC-3: the six stages of a plain Storm pilot
local PLAIN = {
	{ stage = "none", why = "the Morv briefing has not been shown (no finding key)" },
	{ stage = "briefed", why = "finding key set, Morv has not pointed to the Zabrak" },
	{ stage = "tipped", why = "the tip key is set, the Claw was never attempted" },
	{ stage = "active", why = "the Claw's journal entry is active" },
	{ stage = "failed", why = "attempted, no journal entry (a failed or aborted run)" },
	{ stage = "won", why = "the Claw's journal entry is complete, unpaid" },
}

for _, row in ipairs(PLAIN) do
	-- AC-3
	TestStormNymStage["test_a_storm_pilot_is_stage_" .. row.stage .. "_when_" .. row.why:gsub("[^%w]+", "_")] = function()
		lu.assertEquals(stageOf(N.pilot({ stage = row.stage })), row.stage, row.stage .. ": " .. row.why)
	end
end

-- AC-3: every cause of "none" on its own, with the finding key set where the cause is not the key itself
local NONE_CAUSES = {
	{ name = "a_nil_player", build = function() return nil end },
	{ name = "jtl_disabled", build = function()
		H.Engine.config.jtlEnabled = false

		return N.pilot({ stage = "briefed" })
	end },
	{ name = "no_ghost", build = function() return N.ghostless(N.pilot({ stage = "briefed" })) end },
	{ name = "a_rebel_pilot_with_the_finding_key", build = function()
		return N.pilot({ stage = "briefed", pilot = "rebel", faction = "rebel", squadron = HAVOC_SQUADRON })
	end },
	{ name = "a_privateer_with_the_finding_key", build = function()
		return N.pilot({ stage = "briefed", pilot = "neutral", faction = "neutral", squadron = SMUGGLER_SQUADRON })
	end },
	{ name = "a_black_epsilon_pilot_with_the_finding_key", build = function()
		return N.pilot({ stage = "briefed", squadron = BLACK_EPSILON_SQUADRON })
	end },
	{ name = "a_pilot_of_no_squadron_with_the_finding_key", build = function()
		return N.pilot({ stage = "briefed", squadron = false })
	end },
	{ name = "a_storm_pilot_without_the_finding_key", build = function() return N.pilot({ stage = "none" }) end },
	{ name = "a_storm_pilot_whose_claw_is_paid_with_the_finding_key_still_set", build = function()
		-- the finding key is normally cleared by claw_pay; a paid Claw is "none" even when it is not (the reward key wins, Content contract 1.1)
		return N.pilot({ stage = "paid", finding = true })
	end },
	{ name = "a_storm_pilot_after_claw_pay", build = function() return N.pilot({ stage = "paid" }) end },
}

for _, cause in ipairs(NONE_CAUSES) do
	-- AC-3
	TestStormNymStage["test_stage_is_none_for_" .. cause.name] = function()
		lu.assertEquals(stageOf(cause.build()), "none", cause.name)
	end
end

-- AC-3: "none" beats a won or active Claw when the pilot is not a Storm pilot (the first match wins)
function TestStormNymStage:test_the_none_causes_come_before_won_and_active()
	lu.assertEquals(stageOf(N.pilot({ stage = "won", squadron = BLACK_EPSILON_SQUADRON })), "none", "won journal, Black Epsilon pilot")
	lu.assertEquals(stageOf(N.pilot({ stage = "active", squadron = false })), "none", "active journal, no squadron")
	lu.assertEquals(stageOf(N.pilot({ stage = "won", finding = false })), "none", "won journal, finding key cleared")

	local paid = N.pilot({ stage = "won" })

	H.setQuestStatus(paid, T.STATUS[3] .. ":reward", 1)
	lu.assertEquals(stageOf(paid), "none", "won journal entry with the :reward key set (paid), finding key still set")
end

-- AC-3: the order of the middle stages: won, then active, then failed, then tipped
function TestStormNymStage:test_won_beats_active_active_beats_failed_failed_beats_tipped()
	local both = N.pilot({ stage = "won" })

	N.setClaw(both, "complete")
	both.ghost.journalActive[T.crc(T.M3)] = true
	lu.assertEquals(stageOf(both), "won", "complete and active entries: won first")

	lu.assertEquals(stageOf(N.pilot({ stage = "active", tip = false })), "active", "active without the tip key (the grant ran)")
	lu.assertEquals(stageOf(N.pilot({ stage = "failed", tip = false })), "failed", "attempted without the tip key (a reset of the tip key alone)")
	lu.assertEquals(stageOf(N.pilot({ stage = "tipped", attempted = true })), "failed", "tip key and attempted: failed, not tipped")
end

-- AC-3: failed covers both a failed and an aborted run
function TestStormNymStage:test_a_failed_run_and_an_aborted_run_are_both_stage_failed()
	local player = N.pilot({ stage = "failed" })

	lu.assertEquals(N.claw(player), "none", "precondition: no journal entry")
	lu.assertEquals(N.attempted(player), "1", "precondition: attempted")
	lu.assertEquals(stageOf(player), "failed", "attempted, journal cleared")
end

-- AC-3, I-3: getClawStage changes nothing for any pilot the tests build
function TestStormNymStage:test_getClawStage_changes_no_state_for_any_stage()
	for _, stage in ipairs({ "none", "briefed", "tipped", "active", "failed", "won", "paid" }) do
		H.reset()

		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)

		stageOf(player)
		lu.assertEquals(N.snapshot(player), before, "stage " .. stage .. ": state after getClawStage")
	end
end

---------------------------------------------------------------------------------------------
-- AC-3: canStartClaw
---------------------------------------------------------------------------------------------

TestStormNymCanStart = {}

TestStormNymCanStart.setUp = setUp

local function can(player) return N.squadron(lu):canStartClaw(player) end

-- AC-3: true exactly for tipped / failed with no space quest and no Oberhaur mission
local CAN = {
	{ stage = "none", want = false },
	{ stage = "briefed", want = false },
	{ stage = "tipped", want = true },
	{ stage = "active", want = false },
	{ stage = "failed", want = true },
	{ stage = "won", want = false },
	{ stage = "paid", want = false },
}

for _, row in ipairs(CAN) do
	-- AC-3
	TestStormNymCanStart["test_canStartClaw_is_" .. tostring(row.want) .. "_at_stage_" .. row.stage] = function()
		lu.assertEquals(can(N.pilot({ stage = row.stage })), row.want, "canStartClaw at stage " .. row.stage)
	end
end

-- AC-3, D-5: another trainer's space quest or an Oberhaur duty blocks the grant
function TestStormNymCanStart:test_a_running_duty_blocks_a_failed_pilot()
	lu.assertEquals(can(N.pilot({ stage = "failed", duty = T.DUTY1 })), false, "failed + the destroy duty active in the journal")
end

function TestStormNymCanStart:test_another_space_quest_in_the_datapad_blocks_a_tipped_pilot()
	lu.assertEquals(can(N.pilot({ stage = "tipped", datapad = "story" })), false, "tipped + a story mission of another trainer in the datapad")
	lu.assertEquals(can(N.pilot({ stage = "tipped", datapad = "duty" })), false, "tipped + a duty mission in the datapad")
end

function TestStormNymCanStart:test_an_oberhaur_mission_chain_blocks_the_grant()
	local player = N.pilot({ stage = "tipped" })

	player.ghost.journalActive[T.crc(T.M2)] = true
	lu.assertEquals(can(player), false, "tipped + mission 2's journal entry active (Oberhaur's isOnMission)")
end

-- AC-3, I-3: canStartClaw is side-effect free
function TestStormNymCanStart:test_canStartClaw_changes_no_state()
	for _, stage in ipairs({ "tipped", "failed", "briefed" }) do
		H.reset()

		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)

		can(player)
		lu.assertEquals(N.snapshot(player), before, "stage " .. stage .. ": state after canStartClaw")
	end
end

---------------------------------------------------------------------------------------------
-- startClaw
---------------------------------------------------------------------------------------------

TestStormNymStartClaw = {}

TestStormNymStartClaw.setUp = setUp

local function startClaw(player) return N.squadron(lu):startClaw(player, N.npc(3)) end

-- Content contract 1, I-5: from tipped, startClaw sets the attempted key and starts the chain through the real startSpaceQuestChain
function TestStormNymStartClaw:test_startClaw_from_tipped_sets_attempted_and_activates_the_claw()
	local player = N.pilot({ stage = "tipped" })

	lu.assertEquals(startClaw(player), true, "startClaw returns whether the chain is active")
	lu.assertEquals(N.attempted(player), "1", "imperial_ss_3:attempted")
	lu.assertEquals(N.claw(player), "active", "the Claw's journal entry")
	lu.assertEquals(stageOf(player), "active", "getClawStage afterwards")
	lu.assertEquals(can(player), false, "canStartClaw afterwards (a run is active and the datapad holds the mission)")
end

-- Content contract 1: from failed, startClaw clears the old entry and starts clean
function TestStormNymStartClaw:test_startClaw_from_failed_starts_the_claw_again()
	local player = N.pilot({ stage = "failed" })

	lu.assertEquals(startClaw(player), true, "startClaw")
	lu.assertEquals(N.claw(player), "active", "the Claw's journal entry")
	lu.assertEquals(N.attempted(player), "1", "imperial_ss_3:attempted stays set")
end

-- Content contract 1: a retry after a win-less run must not leave the old completed entry (a clean start)
function TestStormNymStartClaw:test_startClaw_starts_the_head_quest_exactly_once_through_the_quest_table()
	local starts = H.spyOn(T.quest(T.M3), "startQuest")
	local player = N.pilot({ stage = "tipped" })

	startClaw(player)
	lu.assertEquals(#starts, 1, "assassinate_imperial_ss_3:startQuest calls")
	lu.assertEquals(starts[1].args[1], player, "startQuest got the pilot")
end

-- I-5: startClaw refuses (false, no state change, no start) at every stage that is not tipped or failed, and when blocked
function TestStormNymStartClaw:test_startClaw_refuses_at_every_other_stage()
	for _, stage in ipairs({ "none", "briefed", "active", "won", "paid" }) do
		H.reset()

		local starts = H.spyOn(T.quest(T.M3), "startQuest")
		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)

		lu.assertEquals(startClaw(player), false, "startClaw at stage " .. stage)
		lu.assertEquals(#starts, 0, "stage " .. stage .. ": no start")
		lu.assertEquals(N.snapshot(player), before, "stage " .. stage .. ": state after the refused startClaw")
	end
end

function TestStormNymStartClaw:test_startClaw_refuses_while_another_space_quest_or_a_duty_runs()
	for _, o in ipairs({ { stage = "tipped", datapad = "story" }, { stage = "failed", duty = T.DUTY2 }, { stage = "failed", datapad = "duty" } }) do
		H.reset()

		local starts = H.spyOn(T.quest(T.M3), "startQuest")
		local player = N.pilot(o)
		local before = N.snapshot(player)

		lu.assertEquals(startClaw(player), false, "startClaw at stage " .. o.stage .. " with " .. tostring(o.datapad or o.duty))
		lu.assertEquals(#starts, 0, "no start")
		lu.assertEquals(N.snapshot(player), before, "state after the refused startClaw")
	end
end

-- Content contract 1: a nil pilot returns without an error
function TestStormNymStartClaw:test_startClaw_and_canStartClaw_accept_a_nil_pilot()
	local SS = N.squadron(lu)

	lu.assertEquals(SS:canStartClaw(nil), false, "canStartClaw(nil)")
	lu.assertEquals(SS:startClaw(nil, nil), false, "startClaw(nil)")
end

---------------------------------------------------------------------------------------------
-- The reset
---------------------------------------------------------------------------------------------

TestStormNymReset = {}

TestStormNymReset.setUp = setUp

-- AC-10: resetOberhaurQuests removes the tip key, and returns on a nil pilot
function TestStormNymReset:test_resetOberhaurQuests_removes_the_tip_key()
	local SS = N.squadron(lu)
	local player = N.pilot({ stage = "tipped" })

	lu.assertEquals(N.tip(player), "1", "precondition: the tip key is set")
	SS:resetOberhaurQuests(player)
	lu.assertNil(N.tip(player), "the tip key after the reset")
	lu.assertNil(N.attempted(player), "imperial_ss_3:attempted after the reset (existing behaviour)")
	lu.assertNil(H.getQuestStatus(player, T.FINDING_SUFFIX), "the finding key after the reset (existing behaviour)")
end

function TestStormNymReset:test_resetOberhaurQuests_with_no_pilot_returns()
	local ok, err = pcall(function() T.squadron():resetOberhaurQuests(nil) end)

	lu.assertTrue(ok, "resetOberhaurQuests(nil) raised: " .. tostring(err))
end
