-- Storm tier 2, the Nym technicians: Morv (nym_fuel_tech, conversation nym_technician_1): the briefing, the codephrase, the tip to the Zabrak and the
-- revisit screens (back_again, its conditional options C-1).
-- Spec: .claude/work/storm-tier2-nym-technicians/01-spec.md (AC-5, AC-8 (Morv's side); Conversation flow 1, 2 (C-1), 3, 4; Appendix A.1; Q-3 (a), (b), (c); I-4, I-5).
--
-- The tree is an inference (no SWG script survives, E-1), so the walks are the spec's Conversation flow 4 and Appendix A.1, written out reply by reply.

local lu = require("luaunit")
local H = require("harness")
local CS = require("harness.client_strings")
local T = require("storm_tier2_data")
local N = require("storm_tier2_nym_data")

N.load()

local MORV = 1
local PREFIX = N.CONVOS[MORV].prefix

local function setUp()
	H.reset()
	N.load()
	N.requireConversation(lu, MORV)
end

local function spyStarts()
	local starts = {}

	for _, g in ipairs(T.GLOBALS) do
		starts[g] = H.spyOn(T.quest(g), "startQuest")
	end

	return starts
end

local function startedCount(starts)
	local n = 0

	for _, calls in pairs(starts) do
		n = n + #calls
	end

	return n
end

local function talk(player, choices) return N.talk(MORV, player, choices) end

-- the options of a step as { reply sid, link } pairs
local function pairsOf(step)
	local out = {}

	for i, o in ipairs(step.options) do
		out[i] = { N.optionSids(step)[i], o.link }
	end

	return out
end

---------------------------------------------------------------------------------------------
-- AC-5: the briefed pilot's greeting
---------------------------------------------------------------------------------------------

TestStormNymMorvBriefing = {}

TestStormNymMorvBriefing.setUp = setUp

-- AC-5: greeting_agent offers the three phrases and the small-talk reply, in Appendix A.1's order
function TestStormNymMorvBriefing:test_a_briefed_pilot_is_offered_the_codephrase_two_wrong_phrases_and_small_talk_in_order()
	local t = talk(N.pilot({ stage = "briefed" }))

	lu.assertEquals(#t, 1, "one screen")
	lu.assertEquals(t[1].id, "greeting_agent", "first screen")
	lu.assertEquals(pairsOf(t[1]), { { "s_67a590c3", "codephrase_ok" }, { "s_62f865dd", "huh" }, { "s_35de4fcc", "what_did_you_say" }, { "s_ced0fec8", "in_your_way" } }, "options (reply, link)")
	lu.assertEquals(t[1].text, PREFIX .. "s_ccc723ff", "Morv's cover-story greeting")
end

-- AC-5: both briefing routes and the wrong-phrase routes, reply by reply (Q-3 a, b)
local BRIEFED_WALKS = {
	{ name = "the_codephrase_then_the_report_reaches_the_zabrak_tip",
		choices = { "s_67a590c3", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9", "s_b8779a78" },
		ids = { "greeting_agent", "codephrase_ok", "nym_organize", "five_captains", "lobotomize", "find_zabrak", "take_off" }, tips = true },
	{ name = "the_codephrase_then_blurting_nyms_plans_rejoins_the_report",
		choices = { "s_67a590c3", "s_37dad091", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9", "s_b8779a78" },
		ids = { "greeting_agent", "codephrase_ok", "blown_cover", "nym_organize", "five_captains", "lobotomize", "find_zabrak", "take_off" }, tips = true },
	{ name = "plasma_first_then_the_codephrase_works_after_the_huh",
		choices = { "s_62f865dd", "s_67a590c3", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9", "s_b8779a78" },
		ids = { "greeting_agent", "huh", "codephrase_ok", "nym_organize", "five_captains", "lobotomize", "find_zabrak", "take_off" }, tips = true },
	{ name = "infuser_first_then_the_codephrase_works_after_what_did_you_say",
		choices = { "s_35de4fcc", "s_67a590c3", "s_37dad091", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9", "s_b8779a78" },
		ids = { "greeting_agent", "what_did_you_say", "codephrase_ok", "blown_cover", "nym_organize", "five_captains", "lobotomize", "find_zabrak", "take_off" }, tips = true },
	{ name = "plasma_then_the_other_wrong_phrase_is_the_wrong_guy",
		choices = { "s_62f865dd", "s_35de4fcc" }, ids = { "greeting_agent", "huh", "wrong_guy" } },
	{ name = "infuser_then_plasma_is_the_wrong_guy",
		choices = { "s_35de4fcc", "s_62f865dd" }, ids = { "greeting_agent", "what_did_you_say", "wrong_guy" } },
	{ name = "plasma_then_never_mind_is_cordoned_off",
		choices = { "s_62f865dd", "s_169df3bb" }, ids = { "greeting_agent", "huh", "cordoned" } },
	{ name = "infuser_then_never_mind_is_cordoned_off",
		choices = { "s_35de4fcc", "s_169df3bb" }, ids = { "greeting_agent", "what_did_you_say", "cordoned" } },
	{ name = "small_talk_ends_at_in_your_way",
		choices = { "s_ced0fec8" }, ids = { "greeting_agent", "in_your_way" } },
}

for _, w in ipairs(BRIEFED_WALKS) do
	-- AC-5: the walk shows the screens of the spec and ends on a stop screen; only the walks through find_zabrak set the tip key
	TestStormNymMorvBriefing["test_walk_" .. w.name] = function()
		local starts = spyStarts()
		local player = N.pilot({ stage = "briefed" })
		local before = N.snapshot(player)
		local t = talk(player, w.choices)

		lu.assertEquals(N.ids(t), w.ids, "screens shown")
		lu.assertTrue(N.last(t).stop, "the walk ends on " .. N.last(t).id)
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(startedCount(starts), 0, "no quest starts (I-5)")

		local diff = N.keyDiff(before, N.snapshot(player))

		if w.tips then
			lu.assertEquals(N.tip(player), "1", "the tip key after find_zabrak")
			lu.assertEquals(diff, { player.objectID .. N.TIP_SUFFIX }, "the tip key is the only key that changed (I-4)")
		else
			lu.assertNil(N.tip(player), "no tip key on a walk that does not reach find_zabrak")
			lu.assertEquals(N.snapshot(player), before, "no state change at all (I-4)")
		end
	end
end

-- AC-5: the tip key is not set before find_zabrak is shown (it is set on display, not on the choice)
function TestStormNymMorvBriefing:test_the_tip_key_is_set_exactly_when_find_zabrak_is_shown()
	local player = N.pilot({ stage = "briefed" })
	local keys = {}
	local replies = { "s_67a590c3", "s_395d4c4", "s_536a83dc", "s_c70b951e", "s_81e175a9" }

	for i = 1, #replies do
		local part = { table.unpack(replies, 1, i) }
		local t = talk(player, part)

		keys[i] = N.last(t).id .. "=" .. tostring(N.tip(player))
	end

	lu.assertEquals(keys, { "codephrase_ok=nil", "nym_organize=nil", "five_captains=nil", "lobotomize=nil", "find_zabrak=1" }, "last screen shown = tip key after each prefix")
end

-- AC-5: after the briefing the next talk opens on back_again, with the pair of options
function TestStormNymMorvBriefing:test_after_the_tip_the_next_talk_opens_on_back_again()
	local player = N.pilot({ stage = "briefed" })

	talk(player, BRIEFED_WALKS[1].choices)

	local t = talk(player)

	lu.assertEquals(t[1].id, "back_again", "second talk")
	lu.assertEquals(pairsOf(t[1]), { { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } }, "back_again options")
	lu.assertEquals(t[1].text, PREFIX .. "s_e727edeb", "Morv's 'what are you doing back here' line")
end

-- AC-5: the stop screens carry the lines the spec names
function TestStormNymMorvBriefing:test_the_briefing_ends_on_the_first_visit_close()
	local t = talk(N.pilot({ stage = "briefed" }), BRIEFED_WALKS[1].choices)

	lu.assertEquals(N.last(t).text, PREFIX .. "s_3345f404", "take_off")
	lu.assertEquals(t[#t - 1].text, PREFIX .. "s_3b4b03fd", "find_zabrak is the tip to the Zabrak")
end

-- I-4: find_zabrak sets the key only at stage briefed; on a revisit the key stays as it is
function TestStormNymMorvBriefing:test_find_zabrak_sets_the_tip_key_only_at_stage_briefed()
	-- no tip key at the start: stage briefed sets it; none (cannot reach the screen), active, failed and won (their stage does not depend on it) leave it absent
	for _, stage in ipairs({ "none", "briefed", "active", "failed", "won" }) do
		H.reset()

		local player = N.pilot({ stage = stage, tip = false })

		lu.assertNil(N.tip(player), "precondition: no tip key at stage " .. stage)
		N.drive(MORV, player, "find_zabrak")
		lu.assertEquals(N.tip(player), stage == "briefed" and "1" or nil, "tip key after find_zabrak at stage " .. stage .. " (started without it)")
	end

	-- and a revisit leaves a key that is there
	for _, stage in ipairs({ "tipped", "active", "failed", "won" }) do
		H.reset()

		local player = N.pilot({ stage = stage })
		local before = N.snapshot(player)

		N.drive(MORV, player, "find_zabrak")
		lu.assertEquals(N.snapshot(player), before, "find_zabrak at stage " .. stage .. " with the key set changes nothing")
	end

end

-- AC-5: no Morv screen starts a quest, whatever the stage (I-4, I-5)
function TestStormNymMorvBriefing:test_no_screen_of_morv_starts_a_quest_or_pays_anything()
	for _, stage in ipairs(N.STAGES) do
		for _, row in ipairs(N.SCREENS[MORV]) do
			H.reset()

			local starts = spyStarts()
			local player = N.pilot({ stage = stage })
			local before = N.snapshot(player)

			N.drive(MORV, player, row.id)

			local after = N.snapshot(player)

			lu.assertEquals(startedCount(starts), 0, "screen " .. row.id .. " at stage " .. stage .. ": no quest starts")
			lu.assertEquals({ after.bank, after.standing, after.itemCount, after.skills, after.awards, after.active, after.complete },
				{ before.bank, before.standing, before.itemCount, before.skills, before.awards, before.active, before.complete },
				"screen " .. row.id .. " at stage " .. stage .. ": no credits, standing, items, skills or journal change")

			local diff = N.keyDiff(before, after)

			if row.id == "find_zabrak" and stage == "briefed" then
				lu.assertEquals(diff, { player.objectID .. N.TIP_SUFFIX }, "find_zabrak at briefed: only the tip key")
			else
				lu.assertEquals(diff, {}, "screen " .. row.id .. " at stage " .. stage .. ": no key changes")
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-8: back_again (C-1) and the report screens
---------------------------------------------------------------------------------------------

TestStormNymMorvRevisit = {}

TestStormNymMorvRevisit.setUp = setUp

-- AC-8: tipped and active show the static pair; failed adds the failure report first; won shows only the won report
local BACK_AGAIN = {
	tipped = { { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } },
	active = { { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } },
	failed = { { "s_7d114e8", "keep_trying" }, { "s_81e175a9", "find_zabrak" }, { "s_b8779a78", "good_luck" } },
	won = { { "s_fdee07ad", "claw_destroyed" } },
}

for _, stage in ipairs({ "tipped", "active", "failed", "won" }) do
	-- AC-8, C-1
	TestStormNymMorvRevisit["test_back_again_offers_the_c1_options_at_stage_" .. stage] = function()
		local t = talk(N.pilot({ stage = stage }))

		lu.assertEquals(t[1].id, "back_again", "first screen")
		lu.assertEquals(pairsOf(t[1]), BACK_AGAIN[stage], "back_again options at stage " .. stage)
	end
end

-- AC-8: active, the tip again is harmless: find_zabrak does not touch the key, then the close
function TestStormNymMorvRevisit:test_an_active_claw_morv_repeats_the_tip_without_touching_the_key()
	local starts = spyStarts()
	local player = N.pilot({ stage = "active" })
	local before = N.snapshot(player)
	local t = talk(player, { "s_81e175a9", "s_b8779a78" })

	lu.assertEquals(N.ids(t), { "back_again", "find_zabrak", "take_off" }, "screens shown")
	lu.assertTrue(N.last(t).stop, "take_off ends")
	lu.assertEquals(N.snapshot(player), before, "nothing changes")
	lu.assertEquals(startedCount(starts), 0, "no quest starts")
end

function TestStormNymMorvRevisit:test_an_active_claw_good_luck_ends_the_talk()
	local t = talk(N.pilot({ stage = "active" }), { "s_b8779a78" })

	lu.assertEquals(N.ids(t), { "back_again", "good_luck" }, "screens shown")
	lu.assertTrue(N.last(t).stop, "good_luck ends")
	lu.assertEquals(N.last(t).text, PREFIX .. "s_90422eb5", "Good luck.")
end

-- AC-8, Q-2 = A: Morv's failure reply is encouragement only; it grants nothing
function TestStormNymMorvRevisit:test_the_failure_report_ends_on_keep_trying_and_does_not_restart_the_claw()
	for _, o in ipairs({ { stage = "failed" }, { stage = "failed", tip = false } }) do
		H.reset()

		local starts = spyStarts()
		local player = N.pilot(o)
		local before = N.snapshot(player)
		local t = talk(player, { "s_7d114e8" })

		lu.assertEquals(N.ids(t), { "back_again", "keep_trying" }, "screens shown")
		lu.assertTrue(N.last(t).stop, "keep_trying ends")
		lu.assertEquals(N.last(t).text, PREFIX .. "s_ccc1622", "'you better not stop until you succeed'")
		lu.assertEquals(startedCount(starts), 0, "no quest starts (Q-2 = A)")
		lu.assertEquals(N.snapshot(player), before, "no state change")
		lu.assertEquals(N.claw(player), "none", "the Claw is not running")
	end
end

-- AC-8: failed, his other replies send the pilot back to the Zabrak
function TestStormNymMorvRevisit:test_at_stage_failed_the_other_replies_resend_the_pilot_to_the_zabrak()
	local player = N.pilot({ stage = "failed" })
	local t = talk(player, { "s_81e175a9", "s_b8779a78" })

	lu.assertEquals(N.ids(t), { "back_again", "find_zabrak", "take_off" }, "screens shown")
	lu.assertEquals(N.claw(player), "none", "no grant")
end

-- AC-8: won, both report walks end
local WON_WALKS = {
	{ name = "gratitude", choices = { "s_fdee07ad", "s_273b318b" }, ids = { "back_again", "claw_destroyed", "you_too" }, last = "s_39510e77" },
	{ name = "get_out", choices = { "s_fdee07ad", "s_e15acd61", "s_5c3323fd" }, ids = { "back_again", "claw_destroyed", "cant_leave", "in_the_clear" }, last = "s_a84adf58" },
}

for _, w in ipairs(WON_WALKS) do
	-- AC-8, D-4: reporting to Morv is optional flavor and changes nothing
	TestStormNymMorvRevisit["test_the_won_report_walk_" .. w.name .. "_ends_with_no_state_change"] = function()
		local starts = spyStarts()
		local player = N.pilot({ stage = "won" })
		local before = N.snapshot(player)
		local t = talk(player, w.choices)

		lu.assertEquals(N.ids(t), w.ids, "screens shown")
		lu.assertTrue(N.last(t).stop, "the walk ends on " .. N.last(t).id)
		lu.assertEquals(N.last(t).text, PREFIX .. w.last, "closing line")
		lu.assertEquals(N.snapshot(player), before, "no state change (D-4)")
		lu.assertEquals(startedCount(starts), 0, "no quest starts")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8: the won report is also shown by claw_destroyed reached directly (its two replies)
function TestStormNymMorvRevisit:test_claw_destroyed_offers_two_replies()
	local t = N.drive(MORV, N.pilot({ stage = "won" }), "claw_destroyed")

	lu.assertEquals(pairsOf(t[1]), { { "s_273b318b", "you_too" }, { "s_e15acd61", "cant_leave" } }, "claw_destroyed options")
	lu.assertEquals(t[1].text, PREFIX .. "s_51f0669b", "Excellent... get off Lok")
end

-- AC-8: after the Claw is paid Morv is ambient again
function TestStormNymMorvRevisit:test_after_the_claw_is_paid_morv_is_ambient_again()
	local t = talk(N.pilot({ stage = "paid" }))

	lu.assertEquals(t[1].id, "greeting", "first screen once paid")
	lu.assertEquals(N.optionSids(t[1]), { "s_ced0fec8" }, "options")
end
