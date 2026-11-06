-- Lt. Colonel Barlow and Inquisitor Vrke: the hand-shake end to end.
-- Spec: .claude/work/inquisition-tier3-barlow/01-spec.md (AC-8; Conversation flow 3; D-8).
--
-- Both templates run through H.converse: Vrke's mission 1 training sets the question key, Vrke answers barlow_pending, Barlow's interview flips the keys,
-- Vrke then offers mission 2, Barlow says already_spoke, Vrke's tour_complete clears the spoke key and Barlow no longer expects the pilot, and a
-- surrender clears everything. Vrke's own tests (test_inquisition_tier3_gates.lua, _training.lua, _surrender.lua) set Barlow's effect by hand; here Barlow's
-- real handler does it.

local lu = require("luaunit")
local H = require("harness")
local B = require("inquisition_tier3_barlow_data")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

B.load()

TestBarlowHandshake = {}

function TestBarlowHandshake:setUp()
	H.reset()
	B.requireConversation(lu)
	V.requireConversation(lu)
end

local function vrkeFirst(player) return V.firstScreen(player) end

-- Mission 1 won and paid, no tier 3 skill yet: Vrke's m1_training grants the first skill and sends the pilot to Barlow
local function afterVrkeTraining()
	local player = V.pilot({ paid = { 1 } })

	V.drive(player, "m1_training", { V.TRAIN[1].reply })

	return player
end

-- AC-8
function TestBarlowHandshake:test_vrkes_first_training_choice_sets_the_question_key_and_vrke_then_waits_for_barlow()
	local player = afterVrkeTraining()

	lu.assertEquals(#V.held(player), 1, "one tier 3 skill is granted")
	lu.assertEquals(H.getQuestStatus(player, B.QUESTION_SUFFIX), "1", "the question key is set by Vrke's m1 trained screen")
	lu.assertNil(H.getQuestStatus(player, B.SPOKE_SUFFIX), "the spoke key is not set")
	lu.assertEquals(vrkeFirst(player), "barlow_pending", "Vrke: 'Have you finished your questioning...?'")
end

-- AC-8
function TestBarlowHandshake:test_barlow_interviews_the_pilot_vrke_sent_and_the_walk_hands_back_to_vrke()
	local player = afterVrkeTraining()

	lu.assertEquals(B.firstScreen(player), "interview", "Barlow: 'Yes? What do you want? I am extremely busy.'")

	local t = B.talk(player, B.WALKS.end_2b71207d)

	lu.assertEquals(t[#t].id, "end_2b71207d", "the interview's last screen")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(B.keys(player), { question = nil, spoke = "1" }, "keys after the interview")
	lu.assertEquals(vrkeFirst(player), "m2_offer", "Vrke: 'So what did you learn from Barlow?'")
	lu.assertEquals(B.firstScreen(player), "already_spoke", "Barlow after the interview")
end

-- AC-8: it makes no difference which of the five ends the pilot reaches
function TestBarlowHandshake:test_every_end_screen_releases_vrke()
	for _, endId in ipairs(B.END_SCREENS) do
		H.reset()

		local player = afterVrkeTraining()

		lu.assertEquals(vrkeFirst(player), "barlow_pending", endId .. ": before Barlow")
		B.talk(player, B.WALKS[endId])
		lu.assertEquals(vrkeFirst(player), "m2_offer", endId .. ": after Barlow")
	end
end

-- AC-8: walking away from the interview leaves Vrke waiting
function TestBarlowHandshake:test_a_pilot_who_walks_away_from_barlow_keeps_vrke_waiting()
	local player = afterVrkeTraining()

	B.talk(player, { "s_40f102e4", "s_28a49383", "s_15fccf52" })
	lu.assertEquals(vrkeFirst(player), "barlow_pending", "Vrke after a half interview")
	lu.assertEquals(B.firstScreen(player), "interview", "Barlow restarts the interview")
end

-- AC-8: Barlow does not expect a pilot Vrke has not sent
function TestBarlowHandshake:test_barlow_does_not_expect_a_pilot_before_vrkes_first_mission_is_trained()
	lu.assertEquals(B.firstScreen(V.pilot()), "not_requested", "an Inquisition pilot before mission 1")
	lu.assertEquals(B.firstScreen(V.pilot({ mission = { [1] = "won" } })), "not_requested", "mission 1 won but not yet trained")
end

-- AC-8: after the whole tour Vrke clears the spoke key and Barlow no longer expects the pilot
function TestBarlowHandshake:test_after_tour_complete_barlow_opens_not_requested()
	local player = V.pilot({ paid = { 1, 2, 3, 4 }, t3 = { 1, 2, 3, 4 }, question = true })

	lu.assertEquals(vrkeFirst(player), "barlow_pending", "Vrke before Barlow")
	B.talk(player, B.WALKS.end_7ebbd888)
	lu.assertEquals(B.firstScreen(player), "already_spoke", "Barlow after the interview")
	lu.assertEquals(vrkeFirst(player), "tour_complete", "Vrke after the interview (all four missions paid)")
	lu.assertNil(H.getQuestStatus(player, B.SPOKE_SUFFIX), "tour_complete clears the spoke key")
	lu.assertEquals(B.firstScreen(player), "not_requested", "Barlow after tour_complete")
end

-- AC-8: a surrender clears both keys and Barlow turns the ex-pilot away
function TestBarlowHandshake:test_after_a_surrender_both_keys_are_gone_and_barlow_opens_restricted()
	local player = afterVrkeTraining()

	B.talk(player, B.WALKS.end_65ec117a)
	lu.assertEquals(B.keys(player), { question = nil, spoke = "1" }, "precondition: the interview is done")

	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil -- the server derives the pilot kind from the skills that are gone
	lu.assertEquals(B.keys(player), { question = nil, spoke = nil }, "both keys after the surrender")
	lu.assertEquals(B.firstScreen(player), "restricted", "Barlow after the surrender")
end

-- AC-8: a surrender in the middle of the errand clears the question key too
function TestBarlowHandshake:test_a_surrender_before_the_interview_clears_the_question_key()
	local player = afterVrkeTraining()

	lu.assertEquals(B.keys(player), { question = "1", spoke = nil }, "precondition")
	SpaceHelpers:surrenderPilot(player)
	player.pilot = nil
	lu.assertEquals(B.keys(player), { question = nil, spoke = nil }, "both keys after the surrender")
	lu.assertEquals(B.firstScreen(player), "restricted", "Barlow after the surrender")
end

return nil
