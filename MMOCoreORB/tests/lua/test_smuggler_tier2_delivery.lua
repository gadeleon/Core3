-- Shamdon Kree: the delivery of Karrde's package (the transition reward) and what Karrde says afterwards.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-7; Conversation flow 2 (C-2, C-3), 3 (table H), 6; D-7; I-5).
--
-- Shamdon gates on SmugglerSquadronScreenplay:hasWonTransQuest, shows trans_paid_male / trans_paid_female (by gender) and pays the 5000 credits stored on
-- assassinate_tat_priv_quest_trans (rewardPlayer) once, then writes <playerID>tat_priv_quest_trans:reward = "1", which switches Karrde from trans_won to low_profile.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local T = require("smuggler_transition_data")
local CS = require("harness.client_strings")

M.load()

local function setUp()
	H.reset()
	M.requireConversation(lu)

	for _, g in ipairs(M.questTables()) do
		H.spyOn(rawget(_G, g), "startQuest")
	end
end

TestSmugglerT2Delivery = {}

TestSmugglerT2Delivery.setUp = setUp

local function undelivered(extra)
	local o = { trans = "won", rewarded = false }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return M.pilot(o)
end

-- AC-7
function TestSmugglerT2Delivery:test_the_package_screen_leads_to_the_man_or_woman_line_by_gender()
	lu.assertEquals(M.ids(M.talk(undelivered({ gender = 0 }), { "s_d14c381d" })), { "package", "trans_paid_male" }, "gender 0")
	lu.assertEquals(M.ids(M.talk(undelivered({ gender = 1 }), { "s_d14c381d" })), { "package", "trans_paid_female" }, "gender 1")
	lu.assertEquals(M.ids(M.talk(undelivered({}), { "s_d14c381d" })), { "package", "trans_paid_male" }, "the default pilot is a man")
end

-- AC-7, C-3: the static link of package is the man's line, the handler replaces it for a woman
function TestSmugglerT2Delivery:test_the_package_option_is_rebuilt_for_a_woman_and_the_template_keeps_the_default()
	local t = M.drive(undelivered({ gender = 1 }), "package")

	lu.assertEquals(M.optionSids(t[1]), { "s_d14c381d" }, "package reply")
	lu.assertEquals(M.linksOf(t[1]), { "trans_paid_female" }, "package link for a woman")

	local male = M.drive(undelivered({ gender = 0 }), "package")

	lu.assertEquals(M.linksOf(male[1]), { "trans_paid_male" }, "package link for a man")
end

-- AC-7: showing the package screen alone pays nothing
function TestSmugglerT2Delivery:test_showing_package_pays_nothing()
	local player = undelivered({})
	local rewards = H.spyOn(M.quest(T.ASSASSINATE), "rewardPlayer")

	M.talk(player)
	M.drive(player, "package")
	lu.assertEquals(#rewards, 0, T.ASSASSINATE .. ":rewardPlayer calls")
	lu.assertFalse(M.transPaid(player), "the :reward key")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
end

-- AC-7, I-5: showing the man's or woman's line pays 5000 once and sets the key
function TestSmugglerT2Delivery:test_the_delivery_line_pays_5000_once_through_the_transition_reward_and_sets_the_key()
	for _, c in ipairs({ { "trans_paid_male", 0 }, { "trans_paid_female", 1 } }) do
		H.reset()

		local player = undelivered({ gender = c[2] })
		local rewards = H.spyOn(M.quest(T.ASSASSINATE), "rewardPlayer")

		M.talk(player, { "s_d14c381d" })
		lu.assertEquals(#rewards, 1, c[1] .. ": " .. T.ASSASSINATE .. ":rewardPlayer calls")
		lu.assertEquals(rewards[1].args[1], player, c[1] .. ": rewardPlayer gets the pilot")
		lu.assertTrue(M.transPaid(player), c[1] .. ": tat_priv_quest_trans:reward == 1")
		lu.assertEquals(H.getQuestStatus(player, T.REWARD), "1", c[1] .. ": the key value")
	end
end

-- AC-7, I-5: the real reward is 5000 credits and no item
function TestSmugglerT2Delivery:test_the_delivery_pays_exactly_5000_credits_and_no_item()
	local player = undelivered({})

	M.talk(player, { "s_d14c381d" })
	lu.assertEquals(player.bankCredits, 5000, "bank credits")
	lu.assertEquals(#player.bankCreditLog, 1, "addBankCredits calls")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "giveItem calls")
	lu.assertEquals(M.TRANS_PAY, 5000, "SHJ giveTransReward")
	lu.assertEquals(M.shamdonTransReward(), 5000, "SHJ giveTransReward (parsed)")
end

-- AC-7, I-5: shown again, nothing more is paid
function TestSmugglerT2Delivery:test_the_delivery_line_shown_again_pays_nothing()
	local player = undelivered({})

	M.drive(player, "trans_paid_male")
	M.drive(player, "trans_paid_male")
	M.drive(player, "trans_paid_female")
	lu.assertEquals(player.bankCredits, 5000, "bank credits after three displays")
	lu.assertEquals(#player.bankCreditLog, 1, "addBankCredits calls")
end

-- AC-7, I-5: a pilot who was already paid (the key is set) gets nothing from the line
function TestSmugglerT2Delivery:test_a_pilot_with_the_key_set_gets_nothing_from_the_delivery_line()
	local player = M.pilot({})

	M.drive(player, "trans_paid_male")
	lu.assertEquals(player.bankCredits, 0, "bank credits")
	lu.assertEquals(#player.bankCreditLog, 0, "addBankCredits calls")
end

-- AC-7: after the delivery Shamdon opens on the ordinary gates
function TestSmugglerT2Delivery:test_after_the_delivery_shamdon_no_longer_asks_for_the_package()
	local player = undelivered({})

	M.talk(player, { "s_d14c381d" })
	lu.assertEquals(M.firstScreen(player), "work", "the next talk")
	lu.assertEquals(M.firstScreen(undelivered({ xp = 60000 })), "package", "a pilot who has not delivered")
end

-- AC-7 (Conversation flow 6): "Thanks!" and "This isn't much money." both lead to more_jobs, which ends the talk
function TestSmugglerT2Delivery:test_both_replies_to_the_payment_lead_to_more_jobs_which_ends()
	for _, reply in ipairs({ "s_c4682ea6", "s_1a3dce13" }) do
		for gender = 0, 1 do
			local t = M.talk(undelivered({ gender = gender }), { "s_d14c381d", reply })

			lu.assertEquals(M.ids(t), { "package", gender == 0 and "trans_paid_male" or "trans_paid_female", "more_jobs" }, "walk with " .. reply .. ", gender " .. gender)
			lu.assertTrue(t[3].stop, "more_jobs ends the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-7: Karrde says low_profile only after Shamdon has paid
function TestSmugglerT2Delivery:test_karrde_opens_low_profile_instead_of_trans_won_after_the_delivery()
	local player = undelivered({})

	lu.assertEquals(M.karrdeTalk(player)[1].id, "trans_won", "Karrde before the delivery")
	M.talk(player, { "s_d14c381d" })
	lu.assertEquals(M.karrdeTalk(player)[1].id, "low_profile", "Karrde after the delivery")
end

-- AC-7: Smugglers who won the transition before this feature have no key and are paid on their first visit
function TestSmugglerT2Delivery:test_a_smuggler_who_won_the_transition_earlier_is_paid_on_the_first_visit()
	local player = undelivered({ tier = 4, paid = 4 })

	lu.assertNil(H.getQuestStatus(player, T.REWARD), "no :reward key before the first visit")

	local t = M.talk(player, { "s_d14c381d" })

	lu.assertEquals(t[1].id, "package", "first visit")
	lu.assertEquals(player.bankCredits, 5000, "paid on the first visit")
end

-- AC-7: payTrans is idempotent and sets the key (direct call)
function TestSmugglerT2Delivery:test_payTrans_pays_once_and_sets_the_key()
	local player = undelivered({})
	local rewards = H.spyOn(M.quest(T.ASSASSINATE), "rewardPlayer")

	M.handler():payTrans(player)
	M.handler():payTrans(player)
	lu.assertEquals(#rewards, 1, "rewardPlayer calls after two payTrans")
	lu.assertTrue(M.transPaid(player), "key")
end

-- AC-7, C-2: the gender line on talon_only
function TestSmugglerT2Delivery:test_talon_only_routes_the_who_question_by_gender()
	local male = M.drive(M.pilot({ trans = "none", rewarded = false, gender = 0 }), "talon_only")
	local female = M.drive(M.pilot({ trans = "none", rewarded = false, gender = 1 }), "talon_only")

	lu.assertEquals(M.optionSids(male[1]), { "s_32965dab", "s_bb27779e" }, "talon_only replies (man)")
	lu.assertEquals(M.linksOf(male[1]), { "talon_who_male", "talon_what" }, "talon_only links (man)")
	lu.assertEquals(M.optionSids(female[1]), { "s_32965dab", "s_bb27779e" }, "talon_only replies (woman)")
	lu.assertEquals(M.linksOf(female[1]), { "talon_who_female", "talon_what" }, "talon_only links (woman)")
end

-- AC-7, AC-5: every transcript resolves in the client
function TestSmugglerT2Delivery:test_every_delivery_transcript_resolves_in_the_client()
	local t = M.talk(undelivered({ gender = 1 }), { "s_d14c381d", "s_1a3dce13" })

	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the transition's reward stays on the transition table, nothing else pays
function TestSmugglerT2Delivery:test_no_other_quest_table_pays_during_the_delivery()
	local spies = {}

	for _, g in ipairs(M.questTables()) do
		if g ~= T.ASSASSINATE then
			spies[g] = H.spyOn(rawget(_G, g), "rewardPlayer")
		end
	end

	M.talk(undelivered({}), { "s_d14c381d", "s_c4682ea6" })

	for g, calls in pairs(spies) do
		lu.assertEquals(#calls, 0, g .. ":rewardPlayer calls during the delivery")
	end
end
