-- Storm tier 2, the Nym technicians: the decoy (nym_fuel_tech_2, conversation nym_technician_2): the three phrases and the jokes; nothing changes.
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-6; Conversation flow 1, 4; Appendix A.2; Q-3 (b); D-8; I-4, I-5).

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local DECOY = 2
local PREFIX = N.CONVOS[DECOY].prefix

local function setUp()
	H.reset()
	N.load()
	N.requireConversation(lu, DECOY)
end

local function pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { N.optionSids(step)[i], o.link }
	end

	return out
end

TestStormNymDecoy = {}

TestStormNymDecoy.setUp = setUp

-- AC-6: every stage but "none" opens greeting_agent with the three phrases and the small-talk reply
for _, stage in ipairs({ "briefed", "tipped", "active", "failed", "won" }) do
	TestStormNymDecoy["test_the_decoy_offers_the_three_phrases_at_stage_" .. stage] = function()
		local t = N.talk(DECOY, N.pilot({ stage = stage }))

		lu.assertEquals(t[1].id, "greeting_agent", "first screen at stage " .. stage)
		lu.assertEquals(pairsOf(t[1]), { { "s_67a590c3", "snaff_grease" }, { "s_62f865dd", "scrub_the" }, { "s_f49a789f", "dont_get_it" }, { "s_8358e7c8", "sob_story" } }, "options at stage " .. stage .. " (D-8: the decoy stays a decoy after the tip)")
		lu.assertEquals(t[1].text, PREFIX .. "s_6aa58622", "the 'really, really busy' greeting")
	end
end

-- AC-6: the walks of Appendix A.2, reply by reply; each ends on a stop screen with no state change
local WALKS = {
	{ name = "the_codephrase_is_taken_literally", choices = { "s_67a590c3", "s_76ac95c" }, ids = { "greeting_agent", "snaff_grease", "get_moving" } },
	{ name = "plasma_goes_on_to_jeffy", choices = { "s_62f865dd", "s_62f865dd", "s_5afecbb7" }, ids = { "greeting_agent", "scrub_the", "jeffy", "funny" } },
	{ name = "plasma_then_the_codephrase_is_snaff_grease", choices = { "s_62f865dd", "s_67a590c3", "s_76ac95c" }, ids = { "greeting_agent", "scrub_the", "snaff_grease", "get_moving" } },
	{ name = "plasma_then_inducer_is_i_dont_get_it", choices = { "s_62f865dd", "s_f49a789f" }, ids = { "greeting_agent", "scrub_the", "dont_get_it" } },
	{ name = "inducer_is_i_dont_get_it", choices = { "s_f49a789f" }, ids = { "greeting_agent", "dont_get_it" } },
	{ name = "small_talk_is_the_sob_story", choices = { "s_8358e7c8" }, ids = { "greeting_agent", "sob_story" } },
}

for _, w in ipairs(WALKS) do
	-- AC-6, I-4, I-5
	TestStormNymDecoy["test_walk_" .. w.name] = function()
		local starts = {}

		for _, g in ipairs(T.GLOBALS) do
			starts[g] = H.spyOn(T.quest(g), "startQuest")
		end

		for _, stage in ipairs({ "briefed", "tipped", "failed" }) do
			local player = N.pilot({ stage = stage })
			local before = N.snapshot(player)
			local t = N.talk(DECOY, player, w.choices)

			lu.assertEquals(N.ids(t), w.ids, "screens shown at stage " .. stage)
			lu.assertTrue(N.last(t).stop, "the walk ends on " .. N.last(t).id)
			lu.assertEquals(N.snapshot(player), before, "no state change at stage " .. stage)
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end

		for _, g in ipairs(T.GLOBALS) do
			lu.assertEquals(#starts[g], 0, g .. " must not start")
		end
	end
end

-- AC-6: scrub_the offers the three phrases again, in Appendix A.2's order
function TestStormNymDecoy:test_scrub_the_offers_the_three_phrases()
	local t = N.talk(DECOY, N.pilot({ stage = "briefed" }), { "s_62f865dd" })

	lu.assertEquals(t[2].id, "scrub_the", "second screen")
	lu.assertEquals(pairsOf(t[2]), { { "s_62f865dd", "jeffy" }, { "s_67a590c3", "snaff_grease" }, { "s_f49a789f", "dont_get_it" } }, "scrub_the options")
	lu.assertEquals(t[2].text, PREFIX .. "s_501ea131", "Scrub the? Excuse me?")
end

-- AC-6: the closing lines of the jokes are the client's
function TestStormNymDecoy:test_the_end_screens_carry_the_expected_lines()
	local lines = { get_moving = "s_b7141451", funny = "s_60900624", dont_get_it = "s_b44f916c", sob_story = "s_4c3cb236" }

	for id, sid in pairs(lines) do
		local t = N.drive(DECOY, N.pilot({ stage = "briefed" }), id)

		lu.assertEquals(t[1].text, PREFIX .. sid, id)
		lu.assertTrue(t[1].stop, id .. " ends")
	end
end

-- AC-6, I-4: no screen of the decoy changes state or starts a quest, at any stage
function TestStormNymDecoy:test_no_screen_of_the_decoy_changes_any_state()
	for _, stage in ipairs(N.STAGES) do
		for _, row in ipairs(N.SCREENS[DECOY]) do
			H.reset()

			local player = N.pilot({ stage = stage })
			local before = N.snapshot(player)

			N.drive(DECOY, player, row.id)
			lu.assertEquals(N.snapshot(player), before, "screen " .. row.id .. " at stage " .. stage)
		end
	end
end

-- AC-8: once the Claw is paid the decoy is ambient again
function TestStormNymDecoy:test_after_the_claw_is_paid_the_decoy_is_ambient_again()
	local t = N.talk(DECOY, N.pilot({ stage = "paid" }))

	lu.assertEquals(t[1].id, "greeting", "first screen once paid")
	lu.assertEquals(N.optionSids(t[1]), { "s_8358e7c8" }, "options")
end
