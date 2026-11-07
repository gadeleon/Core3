-- Brother Vrovel: the hand-in of a V3-FX graduate and the VORTEX_PILOT_KEY writes.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-4; Conversation flow 1 (V11), 3 (table H) and 4; FV-4; D-10; I-7; Q-2 = A).
--
-- V3-FX leaves the pilot with VORTEX_PILOT_KEY = "1". Vrovel's three acceptance screens write "2" (SWG setVortexPilot); the key is "set" for V3-FX
-- whatever its value, so a handed-in pilot is still graduated there. The M4 reward writes "3" (tested in test_vortex_tier2_vrovel_rewards.lua).

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local V1 = require("vortex_tier1_data")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

TestVrovelHandIn = {}

TestVrovelHandIn.setUp = setUp

-- Appendix A: the three acceptance replies of handin_vortex, with the screen each leads to
local ACCEPTANCE = {
	{ reply = "s_e788dfef", screen = "handin_dont_salute" },
	{ reply = "s_cff9d397", screen = "handin_promise" },
	{ reply = "s_a59f4abe", screen = "handin_pay" },
}

-- AC-4: the graduate is handed in first, also with 60,000 XP or more (Q-2 = A)
function TestVrovelHandIn:test_a_v3_fx_graduate_opens_the_hand_in_also_with_the_experience_for_training()
	for _, xp in ipairs({ 0, V.XP_COST - 1, V.XP_COST, 500000 }) do
		H.reset()

		local t = V.talk(V.pilot({ graduated = "1", xp = xp }))

		lu.assertEquals(t[1].id, "handin", "flag 1 with " .. xp .. " XP")
	end
end

-- AC-4: opening the hand-in changes nothing (the flag stays "1" until an acceptance is shown)
function TestVrovelHandIn:test_the_hand_in_screen_itself_writes_nothing()
	local player = V.pilot({ graduated = "1" })
	local t = V.talk(player)

	lu.assertEquals(V.ids(t), { "handin" }, "first screen")
	lu.assertEquals(V.flag(player), "1", "the flag after the hand-in screen")
	lu.assertEquals(#V.held2(player), 0, "no skill")
	lu.assertEquals(player.bankCredits, 0, "no credits")
end

-- AC-4: each acceptance writes "2" on display and leads to the duty menu
for _, a in ipairs(ACCEPTANCE) do
	TestVrovelHandIn["test_" .. a.screen .. "_writes_flag_2_and_leads_to_the_duty_menu"] = function()
		local player = V.pilot({ graduated = "1" })
		local t = V.talk(player, { "s_45236b6c", a.reply, V.screenRow(a.screen).options[1][1] })

		lu.assertEquals(V.ids(t), { "handin", "handin_vortex", a.screen, "duty_menu" }, "the walk: " .. a.reply)
		lu.assertEquals(V.flag(player), "2", a.screen .. ": the flag after the acceptance")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-4: the write happens when the screen is shown, before any reply (a pilot who closes the window is handed in)
	TestVrovelHandIn["test_" .. a.screen .. "_writes_flag_2_when_it_is_shown_not_when_left"] = function()
		local player = V.pilot({ graduated = "1" })
		local t = V.drive(player, a.screen)

		lu.assertEquals(V.ids(t), { a.screen }, "driven straight to the screen")
		lu.assertEquals(V.flag(player), "2", a.screen .. ": the flag on display")
	end

	-- AC-4, I-7: flag values other than "1" are not rewritten (the write is "1" -> "2" only)
	TestVrovelHandIn["test_" .. a.screen .. "_leaves_flag_3_and_an_unset_flag_alone"] = function()
		local three = V.pilot({ graduated = "3" })

		V.drive(three, a.screen)
		lu.assertEquals(V.flag(three), "3", a.screen .. ": flag 3 stays")

		local none = V.pilot({ graduated = false })

		V.drive(none, a.screen)
		lu.assertNil(V.flag(none), a.screen .. ": an unset flag stays unset")
	end
end

-- AC-4: handin_mistaken writes nothing; the next talk opens the hand-in again
function TestVrovelHandIn:test_handin_mistaken_writes_nothing_and_the_next_talk_is_the_hand_in_again()
	local player = V.pilot({ graduated = "1" })
	local t = V.talk(player, { "s_d049b613" })

	lu.assertEquals(V.ids(t), { "handin", "handin_mistaken" }, "the walk")
	lu.assertTrue(t[2].stop, "handin_mistaken ends")
	lu.assertEquals(V.flag(player), "1", "the flag")
	lu.assertEquals(V.firstScreen(player), "handin", "the next talk")
end

-- AC-4: handin_out writes nothing; the next talk opens the hand-in again
function TestVrovelHandIn:test_handin_out_writes_nothing_and_the_next_talk_is_the_hand_in_again()
	local player = V.pilot({ graduated = "1" })
	local t = V.talk(player, { "s_45236b6c", "s_5088ea12" })

	lu.assertEquals(V.ids(t), { "handin", "handin_vortex", "handin_out" }, "the walk")
	lu.assertTrue(t[3].stop, "handin_out ends")
	lu.assertEquals(V.flag(player), "1", "the flag")
	lu.assertEquals(V.firstScreen(player), "handin", "the next talk")
end

-- AC-4: after the acceptance the next talk is not the hand-in (flag 2 and nothing to buy: the duty offer)
function TestVrovelHandIn:test_after_the_acceptance_the_next_talk_opens_the_duty_offer()
	local player = V.pilot({ graduated = "1" })

	V.talk(player, { "s_45236b6c", ACCEPTANCE[1].reply })
	lu.assertEquals(V.firstScreen(player), "duty_offer", "flag 2, no XP")
end

-- AC-4, FV-4: a graduate with the XP for training is handed in, then offered training on the next talk
function TestVrovelHandIn:test_after_the_acceptance_a_graduate_with_experience_is_offered_training()
	local player = V.pilot({ graduated = "1", xp = V.XP_COST })

	lu.assertEquals(V.firstScreen(player), "handin", "first talk")
	V.talk(player, { "s_45236b6c", ACCEPTANCE[2].reply })
	lu.assertEquals(V.firstScreen(player), "training_offer", "second talk")
end

-- AC-4: afterwards V3-FX opens "graduated" for flag "2" and for flag "3" (the key is set; its value does not matter)
function TestVrovelHandIn:test_v3_fx_still_opens_graduated_after_the_acceptance_and_with_flag_3()
	V1.requireConversation(lu)

	local player = V.pilot({ graduated = "1" })

	V.talk(player, { "s_45236b6c", ACCEPTANCE[3].reply })
	lu.assertEquals(V.flag(player), "2", "after the acceptance")
	lu.assertEquals(V1.firstScreen(player), "graduated", "V3-FX with flag 2")

	H.setQuestStatus(player, V.VORTEX_PILOT_KEY, "3")
	lu.assertEquals(V1.firstScreen(player), "graduated", "V3-FX with flag 3")
end

-- I-7: no screen writes the flag except the three acceptances (1 -> 2) and the M4 pay screens ("3", tested with the rewards); the flag is never removed
function TestVrovelHandIn:test_no_other_screen_writes_or_removes_the_flag()
	local allowed = { handin_dont_salute = true, handin_promise = true, handin_pay = true, m4_pay_close_call = true, m4_pay_impressed = true }

	for _, row in ipairs(V.SCREENS) do
		if not allowed[row.id] then
			H.reset()
			V.spyStarts()

			local player = V.pilot({ graduated = "1", missions = 1, t2 = 2, xp = 999999, privileged = true })

			V.drive(player, row.id)
			lu.assertEquals(V.flag(player), "1", "screen '" .. row.id .. "': VORTEX_PILOT_KEY")
		end
	end
end

-- I-7: the sweep also holds for flag "2" and "3" pilots (nothing lowers or removes the key)
function TestVrovelHandIn:test_no_screen_lowers_or_removes_flag_2_or_3()
	local allowed = { m4_pay_close_call = true, m4_pay_impressed = true }

	for _, flag in ipairs({ "2", "3" }) do
		for _, row in ipairs(V.SCREENS) do
			if not allowed[row.id] then
				H.reset()
				V.spyStarts()

				local player = V.pilot({ graduated = flag, missions = 1, t2 = 2, xp = 999999, privileged = true })

				V.drive(player, row.id)
				lu.assertEquals(V.flag(player), flag, "flag " .. flag .. ", screen '" .. row.id .. "': VORTEX_PILOT_KEY")
			end
		end
	end
end

-- AC-4: the hand-in pays and grants nothing
function TestVrovelHandIn:test_the_hand_in_walk_grants_nothing()
	local player = V.pilot({ graduated = "1" })
	local spies = V.spyStarts()

	V.talk(player, { "s_45236b6c", ACCEPTANCE[1].reply })
	lu.assertEquals(V.startedCount(spies), {}, "quests started")
	lu.assertEquals(player.bankCredits, 0, "credits")
	lu.assertEquals(V.standing(player), 0, "standing")
	lu.assertEquals(#V.held2(player), 0, "skills")
end
