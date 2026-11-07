-- Major Eker: the hand-in of a Socuna graduate and the EKER_PILOT_KEY writes.
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-4; Conversation flow 1 (E12), 3 (table H) and 4; FE-4, FE-8; D-4, D-6, D-10, D-12; I-7; Q-1 = A).
--
-- Socuna leaves the pilot with EKER_PILOT_KEY = "1". Every exit of the hand-in that accepts (the screens handin_dismissed and handin_duty_menu) writes "2"
-- on display (SWG makeEkerPilot, D-6, D-12); the key is "set" for Socuna whatever its value, so a handed-in pilot is still graduated there. The M4 reward
-- writes "3" (tested in test_crimson_tier2_eker_rewards.lua).

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local C = require("crimson_tier1_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

TestEkerHandIn = {}

TestEkerHandIn.setUp = setUp

-- Conversation flow 4: every walk of the hand-in that accepts, from the first screen: { choices, the screens shown }
local WALKS = {
	{ name = "yes_sir", choices = { "s_6a1c47d9" }, ids = { "handin", "handin_dismissed" } },
	{ name = "imperial_officer_ready", choices = { "s_c1015a4d", "s_a9d63a81" }, ids = { "handin", "handin_is_that_right", "handin_duty_menu" } },
	{ name = "never_mind", choices = { "s_c1015a4d", "s_92310551", "s_8f9a3bf4" }, ids = { "handin", "handin_is_that_right", "handin_which_eker", "handin_duty_menu" } },
	{ name = "defected_yes_sir", choices = { "s_c1015a4d", "s_92310551", "s_5e5b4379", "s_6a1c47d9" },
	  ids = { "handin", "handin_is_that_right", "handin_which_eker", "handin_defected", "handin_dismissed" } },
	{ name = "defected_ready", choices = { "s_c1015a4d", "s_92310551", "s_5e5b4379", "s_a9d63a81" },
	  ids = { "handin", "handin_is_that_right", "handin_which_eker", "handin_defected", "handin_duty_menu" } },
	{ name = "loud_and_clear_ready", choices = { "s_f685a04e", "s_a9d63a81" }, ids = { "handin", "handin_confession", "handin_duty_menu" } },
	{ name = "come_again_ready", choices = { "s_f685a04e", "s_2bc43dfd", "s_a9d63a81" }, ids = { "handin", "handin_confession", "handin_heard_me", "handin_duty_menu" } },
	{ name = "hate_the_empire", choices = { "s_f685a04e", "s_2bc43dfd", "s_dd0cb0d4", "s_b2e340f6", "s_bc57b086" },
	  ids = { "handin", "handin_confession", "handin_heard_me", "handin_understand", "handin_hate_empire", "handin_dismissed" } },
}

-- AC-4: the graduate is handed in first, also with 60,000 XP or more (D-4)
function TestEkerHandIn:test_a_socuna_graduate_opens_the_hand_in_also_with_the_experience_for_training()
	for _, xp in ipairs({ 0, E.XP_COST - 1, E.XP_COST, 500000 }) do
		H.reset()

		local t = E.talk(E.pilot({ graduated = "1", xp = xp }))

		lu.assertEquals(t[1].id, "handin", "flag 1 with " .. xp .. " XP")
	end
end

-- AC-4: opening the hand-in changes nothing (the flag stays "1" until an accepting screen is shown)
function TestEkerHandIn:test_the_hand_in_screen_itself_writes_nothing()
	local player = E.pilot({ graduated = "1" })
	local t = E.talk(player)

	lu.assertEquals(E.ids(t), { "handin" }, "first screen")
	lu.assertEquals(E.flag(player), "1", "the flag after the hand-in screen")
	lu.assertEquals(#E.held2(player), 0, "no skill")
	lu.assertEquals(player.bankCredits, 0, "no credits")
end

-- AC-4: every walk that accepts writes "2" on display and ends on the dismissal or reaches the duty menu
for _, w in ipairs(WALKS) do
	TestEkerHandIn["test_the_" .. w.name .. "_walk_writes_flag_2_and_ends_on_the_dismissal_or_the_duty_menu"] = function()
		local player = E.pilot({ graduated = "1" })
		local t = E.talk(player, w.choices)

		lu.assertEquals(E.ids(t), w.ids, "the walk: " .. table.concat(w.choices, ", "))
		lu.assertEquals(E.flag(player), "2", w.name .. ": the flag after the walk")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

		if w.ids[#w.ids] == "handin_dismissed" then
			lu.assertTrue(t[#t].stop, "handin_dismissed ends the conversation")
		else
			lu.assertEquals(E.linksOf(t[#t]), { "duty_recovery", "duty_escort", "duty_destroy", "duty_menu_later" }, "the duty menu: its four links")
		end
	end

	-- AC-4: the screens before the last one write nothing (the write is on the accepting screen)
	TestEkerHandIn["test_the_" .. w.name .. "_walk_writes_nothing_before_its_last_screen"] = function()
		local player = E.pilot({ graduated = "1" })
		local choices = {}

		for i = 1, #w.choices - 1 do
			choices[i] = w.choices[i]
		end

		local t = E.talk(player, choices)

		lu.assertEquals(E.ids(t), { table.unpack(w.ids, 1, #w.ids - 1) }, "the walk without its last reply")

		-- (a walk of one reply stops on handin itself; every longer prefix stops on a screen that is not an accepting one except where it is the duty menu of a shorter walk)
		lu.assertEquals(E.flag(player), "1", w.name .. ": the flag before the accepting screen")
	end
end

-- AC-4, D-12: the duty menu of the hand-in offers the three duties and later, as the plain duty menu does
function TestEkerHandIn:test_the_hand_in_duty_menu_offers_the_three_duties()
	local player = E.pilot({ graduated = "1" })
	local t = E.drive(player, "handin_duty_menu")

	lu.assertEquals(E.optionSids(t[1]), { "s_73c783f8", "s_80e4843e", "s_46fb1c35", "s_6deac9a2" }, "recovery, escort, destroy, later")
	lu.assertEquals(E.linksOf(t[1]), { "duty_recovery", "duty_escort", "duty_destroy", "duty_menu_later" }, "links")
	lu.assertEquals(E.flag(player), "2", "written on display")
end

-- AC-4: the write happens when the screen is shown, before any reply (a pilot who closes the window is handed in)
for _, screen in ipairs(E.HANDIN_SCREENS) do
	TestEkerHandIn["test_" .. screen .. "_writes_flag_2_when_it_is_shown_not_when_left"] = function()
		local player = E.pilot({ graduated = "1" })
		local t = E.drive(player, screen)

		lu.assertEquals(E.ids(t), { screen }, "driven straight to the screen")
		lu.assertEquals(E.flag(player), "2", screen .. ": the flag on display")
	end

	-- AC-4, I-7, D-10: flag values other than "1" are not rewritten (the write is "1" -> "2" only)
	TestEkerHandIn["test_" .. screen .. "_leaves_flag_3_and_an_unset_flag_alone"] = function()
		local three = E.pilot({ graduated = "3" })

		E.drive(three, screen)
		lu.assertEquals(E.flag(three), "3", screen .. ": flag 3 stays")

		local none = E.pilot({ graduated = false })

		E.drive(none, screen)
		lu.assertNil(E.flag(none), screen .. ": an unset flag stays unset")
	end
end

-- AC-4: a pilot who leaves the hand-in without choosing writes nothing; the next talk opens it again
function TestEkerHandIn:test_leaving_the_hand_in_without_choosing_writes_nothing_and_the_next_talk_is_the_hand_in_again()
	local player = E.pilot({ graduated = "1" })

	E.talk(player)
	lu.assertEquals(E.flag(player), "1", "the flag")
	lu.assertEquals(E.firstScreen(player), "handin", "the next talk")
end

-- AC-4: walking into the middle of the hand-in and leaving (no accepting screen shown) writes nothing either
function TestEkerHandIn:test_leaving_in_the_middle_of_the_hand_in_writes_nothing()
	for _, choices in ipairs({ { "s_c1015a4d" }, { "s_c1015a4d", "s_92310551" }, { "s_f685a04e" }, { "s_f685a04e", "s_2bc43dfd", "s_dd0cb0d4" } }) do
		H.reset()

		local player = E.pilot({ graduated = "1" })

		E.talk(player, choices)
		lu.assertEquals(E.flag(player), "1", "left after " .. table.concat(choices, ", "))
		lu.assertEquals(E.firstScreen(player), "handin", "the next talk after " .. table.concat(choices, ", "))
	end
end

-- AC-4: after "2" the next talk opens the duty offer (under 60,000 XP)
function TestEkerHandIn:test_after_the_hand_in_the_next_talk_opens_the_duty_offer()
	for _, w in ipairs(WALKS) do
		H.reset()

		local player = E.pilot({ graduated = "1" })

		E.talk(player, w.choices)
		lu.assertEquals(E.firstScreen(player), "duty_offer", w.name .. ": flag 2, no XP")
	end
end

-- AC-4, FE-4: a graduate with the XP for training is handed in, then offered training on the next talk
function TestEkerHandIn:test_after_the_hand_in_a_graduate_with_experience_is_offered_training()
	local player = E.pilot({ graduated = "1", xp = E.XP_COST })

	lu.assertEquals(E.firstScreen(player), "handin", "first talk")
	E.talk(player, WALKS[1].choices)
	lu.assertEquals(E.firstScreen(player), "training_offer", "second talk")
end

-- AC-4: Socuna still opens "graduated" after the hand-in, for flag "2" and for flag "3" (the key is set; its value does not matter)
function TestEkerHandIn:test_socuna_still_opens_graduated_after_the_hand_in_and_with_flag_3()
	C.requireConversation(lu)

	local player = E.pilot({ graduated = "1" })

	E.talk(player, WALKS[1].choices)
	lu.assertEquals(E.flag(player), "2", "after the hand-in")
	lu.assertEquals(C.firstScreen(player), "graduated", "Socuna with flag 2")

	H.setQuestStatus(player, E.EKER_PILOT_KEY, "3")
	lu.assertEquals(C.firstScreen(player), "graduated", "Socuna with flag 3")
end

-- I-7: no screen writes the flag except the two hand-in screens (1 -> 2) and the M4 pay screens ("3", tested with the rewards); the flag is never removed
function TestEkerHandIn:test_no_other_screen_writes_or_removes_the_flag()
	local allowed = { handin_dismissed = true, handin_duty_menu = true, m4_pay_right_about_you = true, m4_pay_war_not_over = true }

	for _, row in ipairs(E.SCREENS) do
		if not allowed[row.id] then
			H.reset()
			E.spyStarts()

			local player = E.pilot({ graduated = "1", missions = 1, t2 = 2, xp = 999999, privileged = true })

			E.drive(player, row.id)
			lu.assertEquals(E.flag(player), "1", "screen '" .. row.id .. "': EKER_PILOT_KEY")
		end
	end
end

-- I-7: the sweep also holds for flag "2" and "3" pilots (nothing lowers or removes the key)
function TestEkerHandIn:test_no_screen_lowers_or_removes_flag_2_or_3()
	local allowed = { m4_pay_right_about_you = true, m4_pay_war_not_over = true }

	for _, flag in ipairs({ "2", "3" }) do
		for _, row in ipairs(E.SCREENS) do
			if not allowed[row.id] then
				H.reset()
				E.spyStarts()

				local player = E.pilot({ graduated = flag, missions = 1, t2 = 2, xp = 999999, privileged = true })

				E.drive(player, row.id)
				lu.assertEquals(E.flag(player), flag, "flag " .. flag .. ", screen '" .. row.id .. "': EKER_PILOT_KEY")
			end
		end
	end
end

-- AC-4: the hand-in pays and grants nothing
function TestEkerHandIn:test_the_hand_in_walk_grants_nothing()
	local player = E.pilot({ graduated = "1" })
	local spies = E.spyStarts()

	E.talk(player, WALKS[1].choices)
	lu.assertEquals(E.startedCount(spies), {}, "quests started")
	lu.assertEquals(player.bankCredits, 0, "credits")
	lu.assertEquals(E.standing(player), 0, "standing")
	lu.assertEquals(#E.held2(player), 0, "skills")
end
