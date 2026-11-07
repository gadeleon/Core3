-- Major Eker: SWG's Developer/Tester "What mission do you want?" branch, visible only to privileged players (D-5).
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-9; Conversation flow 2 (C-2); FE-5; Data mapping 1 (isGm); D-5).
--
-- The reply s_6b158a0e "I'm a Developer/Tester and want missions." is added by the handler (C-2) only when PlayerObject:isPrivileged() is true, in JE's
-- position: last on duty_offer and handin, the only reply on duty_later (which ends for everyone else). The gm_* screens start a mission head or a duty
-- without checking any gate.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

-- AC-9 (harness): the builder passes the privileged option through
TestEkerPrivilegedStub = {}

function TestEkerPrivilegedStub:setUp() H.reset() end

function TestEkerPrivilegedStub:test_the_crimson_pilot_builder_passes_the_option_through()
	lu.assertTrue(PlayerObject(E.pilot({ privileged = true }).ghost):isPrivileged(), "E.pilot{privileged = true}")
	lu.assertFalse(PlayerObject(E.pilot().ghost):isPrivileged(), "E.pilot{}")
end

TestEkerGm = {}

TestEkerGm.setUp = setUp

local function replyPairs(step)
	local out = {}

	for i, sid in ipairs(E.optionSids(step)) do
		out[i] = { sid, step.options[i].link }
	end

	return out
end

-- AC-9: the GM reply is last on duty_offer and handin, for a privileged pilot only
local C2 = {
	{ screen = "duty_offer", pilot = { graduated = "2" },
	  tester = { { "s_2bf9b1f7", "duty_menu" }, { "s_72c594c9", "duty_later" }, { "s_6b158a0e", "gm_menu" } },
	  plain = { { "s_2bf9b1f7", "duty_menu" }, { "s_72c594c9", "duty_later" } } },
	{ screen = "handin", pilot = { graduated = "1" },
	  tester = { { "s_6a1c47d9", "handin_dismissed" }, { "s_c1015a4d", "handin_is_that_right" }, { "s_f685a04e", "handin_confession" }, { "s_6b158a0e", "gm_menu" } },
	  plain = { { "s_6a1c47d9", "handin_dismissed" }, { "s_c1015a4d", "handin_is_that_right" }, { "s_f685a04e", "handin_confession" } } },
}

for _, c in ipairs(C2) do
	TestEkerGm["test_a_privileged_pilot_sees_the_gm_reply_on_" .. c.screen .. "_in_its_position"] = function()
		local o = { privileged = true }

		for k, v in pairs(c.pilot) do
			o[k] = v
		end

		local t = E.talk(E.pilot(o))

		lu.assertEquals(t[1].id, c.screen, "first screen")
		lu.assertEquals(replyPairs(t[1]), c.tester, c.screen .. ": replies and links of a tester")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	TestEkerGm["test_an_ordinary_pilot_does_not_see_the_gm_reply_on_" .. c.screen] = function()
		local t = E.talk(E.pilot(c.pilot))

		lu.assertEquals(t[1].id, c.screen, "first screen")
		lu.assertEquals(replyPairs(t[1]), c.plain, c.screen .. ": replies and links of an ordinary pilot")
	end
end

-- AC-9: duty_later shows the GM reply to a tester and ends for everyone else
function TestEkerGm:test_duty_later_offers_the_gm_reply_to_a_tester_and_ends_for_an_ordinary_pilot()
	local tester = E.talk(E.pilot({ graduated = "2", privileged = true }), { "s_72c594c9" })

	lu.assertEquals(E.ids(tester), { "duty_offer", "duty_later" }, "tester walk")
	lu.assertEquals(replyPairs(tester[2]), { { "s_6b158a0e", "gm_menu" } }, "the tester's only reply")
	lu.assertFalse(tester[2].stop, "duty_later waits for the tester")

	local plain = E.talk(E.pilot({ graduated = "2" }), { "s_72c594c9" })

	lu.assertEquals(E.ids(plain), { "duty_offer", "duty_later" }, "ordinary walk")
	lu.assertEquals(#plain[2].options, 0, "no reply for an ordinary pilot")
	lu.assertTrue(plain[2].stop, "duty_later ends for an ordinary pilot")
	lu.assertEquals(CS.transcriptUnresolved(tester), {}, "client strings")
end

-- AC-9: the privileged flag is read on display, not at the time of the first talk
function TestEkerGm:test_the_gm_reply_follows_the_flag_at_the_time_of_the_talk()
	local player = E.pilot({ graduated = "2" })

	lu.assertEquals(#E.talk(player)[1].options, 2, "ordinary")
	player.ghost.privileged = true
	lu.assertEquals(#E.talk(player)[1].options, 3, "privileged")
	player.ghost.privileged = false
	lu.assertEquals(#E.talk(player)[1].options, 2, "ordinary again")
end

-- AC-9: the other screens never show the GM reply to an ordinary pilot, and only the three to a tester
function TestEkerGm:test_no_other_screen_shows_the_gm_reply_to_an_ordinary_pilot_and_only_the_three_to_a_tester()
	local three = { duty_offer = true, handin = true, duty_later = true }

	for _, row in ipairs(E.SCREENS) do
		for _, privileged in ipairs({ false, true }) do
			H.reset()
			E.spyStarts()

			local player = E.pilot({ graduated = "2", missions = 1, t2 = 2, xp = 999999, privileged = privileged })
			local t = E.drive(player, row.id)
			local shows = false

			for _, sid in ipairs(E.optionSids(t[1])) do
				shows = shows or sid == E.GM_REPLY
			end

			lu.assertEquals(shows, privileged and three[row.id] == true, "screen '" .. row.id .. "' for " .. (privileged and "a tester" or "an ordinary pilot") .. ": the GM reply is shown")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The gm_* screens
---------------------------------------------------------------------------------------------

TestEkerGmPicks = {}

TestEkerGmPicks.setUp = setUp

-- Appendix A: the seven picks of the menu, in order
local PICKS = {
	{ reply = "s_165db597", mission = 1, link = "gm_mission1" },
	{ reply = "s_64b6ea44", mission = 2, link = "gm_mission2" },
	{ reply = "s_b6af2b98", mission = 3, link = "gm_mission3" },
	{ reply = "s_816055e2", mission = 4, link = "gm_mission4" },
	{ reply = "s_954c43bb", duty = E.DUTY10, link = "gm_escort_duty" },
	{ reply = "s_ec5b15d1", duty = E.DUTY9, link = "gm_destroy_duty" },
	{ reply = "s_91156160", duty = E.DUTY12, link = "gm_recovery_duty" },
}

-- AC-9
function TestEkerGmPicks:test_the_menu_offers_the_seven_picks_in_order()
	local replies, links = {}, {}

	for i, p in ipairs(PICKS) do
		replies[i], links[i] = p.reply, p.link
	end

	local menu = E.drive(E.pilot({ privileged = true }), "gm_menu")[1]

	lu.assertEquals(E.optionSids(menu), replies, "gm_menu replies")
	lu.assertEquals(E.linksOf(menu), links, "gm_menu links")
	lu.assertEquals(menu.text, E.PREFIX .. "s_e53c5017", "gm_menu line: What mission do you want?")
end

-- AC-9: each pick starts its mission head (setting :attempted) or its duty, without checking any gate
for _, p in ipairs(PICKS) do
	TestEkerGmPicks["test_the_gm_menu_pick_" .. p.link .. "_starts_its_quest"] = function()
		local player = E.pilot({ privileged = true, graduated = "2" })
		local spies = E.spyStarts()
		local t = E.talk(player, { E.GM_REPLY, p.reply })

		lu.assertEquals(E.ids(t), { "duty_offer", "gm_menu", p.link }, "the walk")
		lu.assertTrue(t[3].stop, p.link .. " ends")

		if p.mission then
			lu.assertEquals(E.startedCount(spies), { [E.HEADS[p.mission]] = 1 }, "heads started")
			lu.assertEquals(H.getQuestStatus(player, E.STATUS[p.mission] .. ":attempted"), "1", ":attempted of mission " .. p.mission)
		else
			lu.assertEquals(E.startedCount(spies), { [p.duty] = 1 }, "duties started")

			for n = 1, 4 do
				lu.assertNil(H.getQuestStatus(player, E.STATUS[n] .. ":attempted"), "a duty sets no :attempted (mission " .. n .. ")")
			end
		end

		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: the grant lines are the client lines of Appendix A (the three duty picks share the one line)
function TestEkerGmPicks:test_the_grant_lines_are_the_client_lines_of_the_rows()
	local want = { gm_mission1 = "s_9d95a0f8", gm_mission2 = "s_91746e6", gm_mission3 = "s_8c839067", gm_mission4 = "s_753a307b",
		gm_escort_duty = "s_f3cbd30c", gm_destroy_duty = "s_f3cbd30c", gm_recovery_duty = "s_f3cbd30c" }

	for _, p in ipairs(PICKS) do
		H.reset()
		E.spyStarts()

		local t = E.drive(E.pilot({ privileged = true }), "gm_menu", { p.reply })

		lu.assertEquals(t[2].text, E.PREFIX .. want[p.link], p.link .. ": the grant line")
	end
end

-- AC-9: the picks pay nothing, train nothing and write no flag
function TestEkerGmPicks:test_the_gm_picks_pay_train_and_flag_nothing()
	for _, p in ipairs(PICKS) do
		H.reset()

		local player = E.pilot({ privileged = true, graduated = "2", xp = 999999 })

		E.spyStarts()
		E.drive(player, "gm_menu", { p.reply })
		lu.assertEquals(player.bankCredits, 0, p.link .. ": credits")
		lu.assertEquals(E.standing(player), 0, p.link .. ": standing")
		lu.assertEquals(E.flag(player), "2", p.link .. ": the flag")
		lu.assertEquals(#E.held2(player), 0, p.link .. ": skills")
	end
end

-- AC-9: the GM picks work for a pilot the gates would refuse (no skills, no mission ready): SWG's test shortcut
function TestEkerGmPicks:test_a_tester_can_start_any_mission_whatever_the_gates_say()
	local player = E.pilot({ privileged = true, graduated = "2", missions = 0, t2 = 0 })
	local spies = E.spyStarts()

	E.drive(player, "gm_menu", { "s_816055e2" })
	lu.assertEquals(E.startedCount(spies), { [E.E16] = 1 }, "mission 4 with no tier 2 skill")
end

-- AC-9: a GM-granted mission out of order opens by the gates afterwards (mission 4 running: on_mission; failed: m4_failed)
function TestEkerGmPicks:test_a_gm_granted_mission_that_failed_opens_its_failure_screen()
	local player = E.pilot({ privileged = true, graduated = "2", missions = 0, t2 = 0 })

	E.spyStarts()
	E.drive(player, "gm_menu", { "s_816055e2" })
	lu.assertEquals(E.firstScreen(player), "m4_failed", "attempted, not won, not running")
end
