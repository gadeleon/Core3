-- Storm tier 2, the Nym technicians: the Zabrak (nym_fuel_tech_3, conversation nym_technician_3): the three phrases, the fuel-balance tip and the grant
-- of the Kimogila's Claw on "long gone" (Q-2 = A), with its conditional options C-2 and C-3.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-7; Conversation flow 1, 2 (C-2, C-3), 3, 4; Appendix A.3; Q-2 = A; Q-3 (d), (e); D-5; I-4, I-5).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local ZABRAK = 3
local PREFIX = N.CONVOS[ZABRAK].prefix

local function setUp()
	H.reset()
	N.load()
	N.requireConversation(lu, ZABRAK)
end

local function spyClaw() return H.spyOn(T.quest(T.M3), "startQuest") end

local function pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { N.optionSids(step)[i], o.link }
	end

	return out
end

local STATIC_AGENT = { { "s_67a590c3", "ahead_of_schedule" }, { "s_62f865dd", "pilot_slang" }, { "s_f49a789f", "disgusting" }, { "s_88d98675", "pilot_ship" } }

local function withTip()
	local out = { { "s_7002e5c4", "balance_perfect" } }

	for _, p in ipairs(STATIC_AGENT) do
		out[#out + 1] = p
	end

	return out
end

---------------------------------------------------------------------------------------------
-- C-2: greeting_agent
---------------------------------------------------------------------------------------------

TestStormNymZabrakGreeting = {}

TestStormNymZabrakGreeting.setUp = setUp

-- AC-7: an untipped (briefed) pilot is offered the phrases only, no fuel-balance line
function TestStormNymZabrakGreeting:test_a_briefed_pilot_before_morvs_tip_sees_the_phrases_and_no_fuel_balance_line()
	local t = N.talk(ZABRAK, N.pilot({ stage = "briefed" }))

	lu.assertEquals(t[1].id, "greeting_agent", "first screen")
	lu.assertEquals(pairsOf(t[1]), STATIC_AGENT, "options")
	lu.assertEquals(t[1].text, PREFIX .. "s_76b02ea3", "'Can I help you? This is a restricted area'")
end

-- AC-7, C-2: a tipped pilot with no other quest gets the fuel-balance line first
function TestStormNymZabrakGreeting:test_a_tipped_pilot_with_no_other_quest_is_offered_the_fuel_balance_line_first()
	local t = N.talk(ZABRAK, N.pilot({ stage = "tipped" }))

	lu.assertEquals(t[1].id, "greeting_agent", "first screen")
	lu.assertEquals(pairsOf(t[1]), withTip(), "options")
end

-- AC-7, D-5: another trainer's space quest, or an Oberhaur duty, hides it silently
function TestStormNymZabrakGreeting:test_a_tipped_pilot_with_another_space_quest_does_not_see_the_fuel_balance_line()
	for _, o in ipairs({ { stage = "tipped", datapad = "story" }, { stage = "tipped", datapad = "duty" }, { stage = "tipped", duty = T.DUTY3 } }) do
		H.reset()

		local t = N.talk(ZABRAK, N.pilot(o))

		lu.assertEquals(t[1].id, "greeting_agent", "first screen")
		lu.assertEquals(pairsOf(t[1]), STATIC_AGENT, "options with " .. tostring(o.datapad or o.duty))
	end
end

---------------------------------------------------------------------------------------------
-- Walks of the phrases (stage briefed and tipped): no state change
---------------------------------------------------------------------------------------------

TestStormNymZabrakPhrases = {}

TestStormNymZabrakPhrases.setUp = setUp

local PHRASE_WALKS = {
	{ name = "the_codephrase_is_ahead_of_schedule", choices = { "s_67a590c3", "s_1ebf6580" }, ids = { "greeting_agent", "ahead_of_schedule", "five_cycles" } },
	{ name = "plasma_is_pilot_slang", choices = { "s_62f865dd", "s_cbc1d532" }, ids = { "greeting_agent", "pilot_slang", "get_lost" } },
	{ name = "inducer_is_disgusting", choices = { "s_f49a789f" }, ids = { "greeting_agent", "disgusting" } },
	{ name = "small_talk_is_the_restricted_area", choices = { "s_88d98675" }, ids = { "greeting_agent", "pilot_ship" } },
}

for _, w in ipairs(PHRASE_WALKS) do
	-- AC-7, I-4, I-5: ends, changes nothing, starts nothing
	TestStormNymZabrakPhrases["test_walk_" .. w.name] = function()
		local starts = spyClaw()

		for _, stage in ipairs({ "briefed", "tipped" }) do
			local player = N.pilot({ stage = stage })
			local before = N.snapshot(player)
			local t = N.talk(ZABRAK, player, w.choices)

			lu.assertEquals(N.ids(t), w.ids, "screens shown at stage " .. stage)
			lu.assertTrue(N.last(t).stop, "the walk ends on " .. N.last(t).id)
			lu.assertEquals(N.snapshot(player), before, "no state change at stage " .. stage)
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		lu.assertEquals(#starts, 0, "the Claw must not start")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: the grant
---------------------------------------------------------------------------------------------

TestStormNymZabrakGrant = {}

TestStormNymZabrakGrant.setUp = setUp

local GRANT = { "s_7002e5c4", "s_4d5276b" }

-- AC-7: the walk balance_perfect -> long_gone grants the Claw
function TestStormNymZabrakGrant:test_the_fuel_balance_walk_grants_the_claw_on_long_gone()
	local player = N.pilot({ stage = "tipped" })
	local t = N.talk(ZABRAK, player, GRANT)

	lu.assertEquals(N.ids(t), { "greeting_agent", "balance_perfect", "long_gone" }, "screens shown")
	lu.assertEquals(t[2].text, PREFIX .. "s_debe2412", "'I checked the Claw myself before it left'")
	lu.assertEquals(t[3].text, PREFIX .. "s_e8060558", "'The Claw's already long gone'")
	lu.assertEquals(N.attempted(player), "1", "imperial_ss_3:attempted")
	lu.assertEquals(N.claw(player), "active", "the Claw's journal entry")
	lu.assertTrue(SpaceHelpers:isSpaceQuestChainActive(player, T.M3), "assassinate_imperial_ss_3 is chain-active")
	lu.assertEquals(N.squadron(lu):getClawStage(player), "active", "getClawStage afterwards")
end

-- AC-7, I-5: the Claw is started on the display of long_gone, not before
function TestStormNymZabrakGrant:test_nothing_starts_before_long_gone_is_shown()
	local starts = spyClaw()
	local player = N.pilot({ stage = "tipped" })

	N.talk(ZABRAK, player, { "s_7002e5c4" })
	lu.assertEquals(#starts, 0, "after balance_perfect")
	lu.assertNil(N.attempted(player), "no attempted key after balance_perfect")
	N.talk(ZABRAK, player, GRANT)
	lu.assertEquals(#starts, 1, "after long_gone")
	lu.assertEquals(starts[1].args[1], player, "startQuest got the pilot")
end

-- AC-7: Oberhaur then shows on_mission
function TestStormNymZabrakGrant:test_oberhaur_shows_on_mission_once_the_claw_runs()
	local player = N.pilot({ stage = "tipped" })

	N.talk(ZABRAK, player, GRANT)
	lu.assertEquals(T.firstScreen(player), "on_mission", "Oberhaur after the grant")
end

-- AC-7: both exits of long_gone end the talk
local EXITS = {
	{ name = "nothing_you_can_do_then_the_codephrase", choices = { "s_8804f6ee", "s_67a590c3", "s_1ebf6580" }, ids = { "nothing_you_can_do", "ahead_of_schedule", "five_cycles" } },
	{ name = "nothing_you_can_do_then_oh_yeah", choices = { "s_8804f6ee", "s_d65e601b" }, ids = { "nothing_you_can_do", "strange" } },
	{ name = "never_mind_i_have_to_go", choices = { "s_52fbe706" }, ids = { "whatever" } },
}

for _, w in ipairs(EXITS) do
	TestStormNymZabrakGrant["test_after_the_grant_" .. w.name .. "_ends"] = function()
		local player = N.pilot({ stage = "tipped" })
		local choices = { table.unpack(GRANT) }

		for _, c in ipairs(w.choices) do
			choices[#choices + 1] = c
		end

		local t = N.talk(ZABRAK, player, choices)
		local ids = { "greeting_agent", "balance_perfect", "long_gone" }

		for _, id in ipairs(w.ids) do
			ids[#ids + 1] = id
		end

		lu.assertEquals(N.ids(t), ids, "screens shown")
		lu.assertTrue(N.last(t).stop, "the walk ends on " .. N.last(t).id)
		lu.assertEquals(N.claw(player), "active", "one run started, by long_gone")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: long_gone offers the two exits in Appendix A.3's order
function TestStormNymZabrakGrant:test_long_gone_offers_its_two_exits()
	local t = N.talk(ZABRAK, N.pilot({ stage = "tipped" }), GRANT)

	lu.assertEquals(pairsOf(t[3]), { { "s_8804f6ee", "nothing_you_can_do" }, { "s_52fbe706", "whatever" } }, "long_gone options")
end

-- AC-7, I-5: no walk starts the Claw for a briefed (untipped) pilot, and the fuel-balance line is absent
function TestStormNymZabrakGrant:test_a_briefed_pilot_cannot_reach_the_grant_by_any_walk()
	local starts = spyClaw()
	local player = N.pilot({ stage = "briefed" })
	local shown = N.exploreLive(ZABRAK, function() return player end)

	lu.assertNil(shown.balance_perfect, "balance_perfect is not reachable without the tip")
	lu.assertNil(shown.long_gone, "long_gone is not reachable without the tip")
	lu.assertEquals(#starts, 0, "the Claw must not start")
	lu.assertNil(N.attempted(player), "no attempted key")
end

-- AC-7, I-5, D-5: with another space quest running the walk is hidden, and showing long_gone directly still starts nothing
function TestStormNymZabrakGrant:test_a_tipped_pilot_with_another_space_quest_does_not_start_the_claw()
	for _, o in ipairs({ { stage = "tipped", datapad = "story" }, { stage = "tipped", duty = T.DUTY1 }, { stage = "failed", datapad = "duty" } }) do
		H.reset()

		local starts = spyClaw()
		local player = N.pilot(o)
		local before = N.snapshot(player)
		local shown = N.exploreLive(ZABRAK, function() return player end)

		lu.assertNil(shown.long_gone, "long_gone is not reachable with " .. tostring(o.datapad or o.duty))

		N.drive(ZABRAK, player, "long_gone")
		lu.assertEquals(#starts, 0, "displaying long_gone with " .. tostring(o.datapad or o.duty) .. " starts nothing")
		lu.assertEquals(N.snapshot(player), before, "state unchanged")
	end
end

-- I-5: displaying long_gone never starts the Claw outside tipped / failed
function TestStormNymZabrakGrant:test_long_gone_starts_the_claw_only_at_tipped_or_failed()
	for _, stage in ipairs({ "none", "briefed", "active", "won", "paid" }) do
		H.reset()

		local starts = spyClaw()
		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)

		N.drive(ZABRAK, player, "long_gone")
		lu.assertEquals(#starts, 0, "long_gone at stage " .. stage .. " starts nothing")
		lu.assertEquals(N.snapshot(player), before, "long_gone at stage " .. stage .. ": state unchanged")
	end

	for _, stage in ipairs({ "tipped", "failed" }) do
		H.reset()

		local starts = spyClaw()
		local player = N.pilot({ stage = stage })

		N.drive(ZABRAK, player, "long_gone")
		lu.assertEquals(#starts, 1, "long_gone at stage " .. stage .. " starts the Claw once")
		lu.assertEquals(N.attempted(player), "1", "attempted at stage " .. stage)
	end
end

-- I-4: across all screens and stages the only state change is startClaw on long_gone and the tip key (Morv's side is in test_storm_tier2_nym_morv.lua)
function TestStormNymZabrakGrant:test_no_other_screen_of_the_zabrak_changes_any_state()
	for _, stage in ipairs(N.STAGES) do
		for _, row in ipairs(N.SCREENS[ZABRAK]) do
			if row.id ~= "long_gone" then
				H.reset()

				local player = N.pilot({ stage = stage })
				local before = N.snapshot(player)

				N.drive(ZABRAK, player, row.id)
				lu.assertEquals(N.snapshot(player), before, "screen " .. row.id .. " at stage " .. stage)
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- C-3: you_again
---------------------------------------------------------------------------------------------

TestStormNymZabrakRevisit = {}

TestStormNymZabrakRevisit.setUp = setUp

local YOU_AGAIN = {
	active = { { "s_248faf8a", "long_gone" }, { "s_52fbe706", "clear_out" } },
	failed = { { "s_248faf8a", "long_gone" }, { "s_52fbe706", "clear_out" } },
	won = { { "s_52fbe706", "clear_out" } },
}

for _, stage in ipairs({ "active", "failed", "won" }) do
	-- AC-8, C-3
	TestStormNymZabrakRevisit["test_you_again_offers_the_c3_options_at_stage_" .. stage] = function()
		local t = N.talk(ZABRAK, N.pilot({ stage = stage }))

		lu.assertEquals(t[1].id, "you_again", "first screen")
		lu.assertEquals(pairsOf(t[1]), YOU_AGAIN[stage], "you_again options at stage " .. stage)
		lu.assertEquals(t[1].text, PREFIX .. "s_e32d36db", "'You again? I don't have time to help you.'")
	end
end

-- AC-8, C-3, D-5: a failed pilot with another quest running is not offered the retry line
function TestStormNymZabrakRevisit:test_a_failed_pilot_with_a_running_duty_or_quest_is_not_offered_the_retry_line()
	for _, o in ipairs({ { stage = "failed", duty = T.DUTY1 }, { stage = "failed", datapad = "story" } }) do
		H.reset()

		local t = N.talk(ZABRAK, N.pilot(o))

		lu.assertEquals(t[1].id, "you_again", "first screen")
		lu.assertEquals(pairsOf(t[1]), { { "s_52fbe706", "clear_out" } }, "you_again options with " .. tostring(o.datapad or o.duty))
	end
end

-- AC-8: never mind ends
function TestStormNymZabrakRevisit:test_never_mind_clears_out_and_ends()
	for _, stage in ipairs({ "active", "failed", "won" }) do
		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)
		local t = N.talk(ZABRAK, player, { "s_52fbe706" })

		lu.assertEquals(N.ids(t), { "you_again", "clear_out" }, "screens shown at stage " .. stage)
		lu.assertTrue(N.last(t).stop, "clear_out ends")
		lu.assertEquals(N.snapshot(player), before, "no state change at stage " .. stage)
	end
end

-- AC-8: once the Claw is paid the Zabrak is ambient again
function TestStormNymZabrakRevisit:test_after_the_claw_is_paid_the_zabrak_is_ambient_again()
	local t = N.talk(ZABRAK, N.pilot({ stage = "paid" }))

	lu.assertEquals(t[1].id, "greeting", "first screen once paid")
	lu.assertEquals(N.optionSids(t[1]), { "s_88d98675" }, "options")
end
