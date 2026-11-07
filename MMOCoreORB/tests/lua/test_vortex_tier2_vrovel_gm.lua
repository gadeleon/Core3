-- Brother Vrovel: SWG's Developer/Tester "Which mission?" branch, visible only to privileged players (Q-1 = A), and the harness stub it needs.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-9; Conversation flow 2 (C-2); FV-5; Data mapping 1 (isGm); Content contract 4 (Harness); R-7).
--
-- The reply s_6b158a0e "I'm a Developer/Tester and want missions." is added by the handler (C-2) only when PlayerObject:isPrivileged() is true, in J2's
-- position: last on duty_offer and handin, first on private_property. The gm_* screens start a mission head or a duty without checking any gate.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local CS = require("harness.client_strings")

V.loadConversation()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

---------------------------------------------------------------------------------------------
-- The harness stub (R-7): FakeGhost:isPrivileged
---------------------------------------------------------------------------------------------

TestVrovelPrivilegedStub = {}

function TestVrovelPrivilegedStub:setUp() H.reset() end

-- Content contract 4: a ghost is not privileged by default
function TestVrovelPrivilegedStub:test_a_new_player_is_not_privileged()
	local player = H.newPlayer({ name = "Ace" })

	lu.assertFalse(PlayerObject(player.ghost):isPrivileged(), "PlayerObject:isPrivileged on a default ghost")
end

-- Content contract 4: privileged = true in the player options makes the ghost privileged
function TestVrovelPrivilegedStub:test_the_privileged_option_makes_the_ghost_privileged()
	local player = H.newPlayer({ name = "Ace", privileged = true })

	lu.assertTrue(PlayerObject(player.ghost):isPrivileged(), "PlayerObject:isPrivileged with privileged = true")
	lu.assertFalse(PlayerObject(H.newPlayer({ name = "Bo", privileged = false }).ghost):isPrivileged(), "privileged = false")
end

-- Content contract 4: the vortex builder passes the option through
function TestVrovelPrivilegedStub:test_the_vortex_pilot_builder_passes_the_option_through()
	lu.assertTrue(PlayerObject(V.pilot({ privileged = true }).ghost):isPrivileged(), "V.pilot{privileged = true}")
	lu.assertFalse(PlayerObject(V.pilot().ghost):isPrivileged(), "V.pilot{}")
end

---------------------------------------------------------------------------------------------
-- isTester and the GM reply (C-2)
---------------------------------------------------------------------------------------------

TestVrovelGm = {}

TestVrovelGm.setUp = setUp

-- Content contract 3: isTester is the ghost's privileged flag; a pilot without a ghost is no tester
function TestVrovelGm:test_is_tester_follows_the_privileged_flag()
	local handler = V.handler()

	lu.assertTrue(handler:isTester(V.pilot({ privileged = true })), "privileged pilot")
	lu.assertFalse(handler:isTester(V.pilot()), "ordinary pilot")

	local noGhost = V.pilot({ privileged = true })

	noGhost.ghost = nil
	lu.assertFalse(handler:isTester(noGhost), "a player without a player object")
end

-- AC-9: the GM reply is last on duty_offer and handin, first on private_property, for a privileged pilot only
local C2 = {
	{ screen = "duty_offer", pilot = { graduated = "2" },
	  tester = { { "s_9b43a7ee", "duty_menu" }, { "s_6b054777", "duty_later" }, { "s_6b158a0e", "gm_menu" } },
	  plain = { { "s_9b43a7ee", "duty_menu" }, { "s_6b054777", "duty_later" } } },
	{ screen = "handin", pilot = { graduated = "1" },
	  tester = { { "s_d049b613", "handin_mistaken" }, { "s_45236b6c", "handin_vortex" }, { "s_6b158a0e", "gm_menu" } },
	  plain = { { "s_d049b613", "handin_mistaken" }, { "s_45236b6c", "handin_vortex" } } },
	{ screen = "private_property", pilot = { graduated = "1", t1 = 3 },
	  tester = { { "s_6b158a0e", "gm_menu_sectors" }, { "s_6f6eeaf3", "private_goodbye" }, { "s_9f0a282", "private_leave" } },
	  plain = { { "s_6f6eeaf3", "private_goodbye" }, { "s_9f0a282", "private_leave" } } },
}

local function replyPairs(step)
	local out = {}

	for i, sid in ipairs(V.optionSids(step)) do
		out[i] = { sid, step.options[i].link }
	end

	return out
end

for _, c in ipairs(C2) do
	-- AC-9
	TestVrovelGm["test_a_privileged_pilot_sees_the_gm_reply_on_" .. c.screen .. "_in_its_position"] = function()
		local pilotOptions = { privileged = true }

		for k, v in pairs(c.pilot) do
			pilotOptions[k] = v
		end

		local t = V.talk(V.pilot(pilotOptions))

		lu.assertEquals(t[1].id, c.screen, "first screen")
		lu.assertEquals(replyPairs(t[1]), c.tester, c.screen .. ": replies and links of a tester")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-9
	TestVrovelGm["test_an_ordinary_pilot_does_not_see_the_gm_reply_on_" .. c.screen] = function()
		local t = V.talk(V.pilot(c.pilot))

		lu.assertEquals(t[1].id, c.screen, "first screen")
		lu.assertEquals(replyPairs(t[1]), c.plain, c.screen .. ": replies and links of an ordinary pilot")
	end
end

-- AC-9: the privileged flag is read on display, not at the time of the first talk (a pilot whose flag changes sees the new menu)
function TestVrovelGm:test_the_gm_reply_follows_the_flag_at_the_time_of_the_talk()
	local player = V.pilot({ graduated = "2" })

	lu.assertEquals(#V.talk(player)[1].options, 2, "ordinary")
	player.ghost.privileged = true
	lu.assertEquals(#V.talk(player)[1].options, 3, "privileged")
	player.ghost.privileged = false
	lu.assertEquals(#V.talk(player)[1].options, 2, "ordinary again")
end

-- AC-9: the other screens never show the GM reply
function TestVrovelGm:test_no_other_screen_shows_the_gm_reply_to_an_ordinary_pilot_and_only_the_three_to_a_tester()
	local three = { duty_offer = true, handin = true, private_property = true }

	for _, row in ipairs(V.SCREENS) do
		for _, privileged in ipairs({ false, true }) do
			H.reset()
			V.spyStarts()

			local player = V.pilot({ graduated = "2", missions = 1, t2 = 2, xp = 999999, privileged = privileged })
			local t = V.drive(player, row.id)
			local shows = false

			for _, sid in ipairs(V.optionSids(t[1])) do
				shows = shows or sid == V.GM_REPLY
			end

			lu.assertEquals(shows, privileged and three[row.id] == true, "screen '" .. row.id .. "' for " .. (privileged and "a tester" or "an ordinary pilot") .. ": the GM reply is shown")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The gm_* screens
---------------------------------------------------------------------------------------------

TestVrovelGmPicks = {}

TestVrovelGmPicks.setUp = setUp

-- Appendix A: the seven picks of both menus, in order
local PICKS = {
	{ reply = "s_165db597", mission = 1, plain = "gm_mission1_plain", sectors = "gm_mission1" },
	{ reply = "s_64b6ea44", mission = 2, plain = "gm_mission2", sectors = "gm_mission2" },
	{ reply = "s_b6af2b98", mission = 3, plain = "gm_mission3", sectors = "gm_mission3" },
	{ reply = "s_816055e2", mission = 4, plain = "gm_mission4", sectors = "gm_mission4" },
	{ reply = "s_2c008858", duty = V.DUTY5, plain = "gm_escort_duty", sectors = "gm_escort_duty" },
	{ reply = "s_7a128ed0", duty = V.DUTY7, plain = "gm_recovery_duty", sectors = "gm_recovery_duty" },
	{ reply = "s_544003d6", duty = V.DUTY6, plain = "gm_destroy_duty", sectors = "gm_destroy_duty" },
}

-- AC-9
function TestVrovelGmPicks:test_the_two_menus_offer_the_seven_picks_in_order()
	local player = V.pilot({ privileged = true })
	local replies, plainLinks, sectorLinks = {}, {}, {}

	for i, p in ipairs(PICKS) do
		replies[i], plainLinks[i], sectorLinks[i] = p.reply, p.plain, p.sectors
	end

	local menu = V.drive(player, "gm_menu")[1]

	lu.assertEquals(V.optionSids(menu), replies, "gm_menu replies")
	lu.assertEquals(V.linksOf(menu), plainLinks, "gm_menu links")
	lu.assertEquals(menu.text, V.PREFIX .. "s_9ffd1405", "gm_menu line: Which mission?")

	local sectors = V.drive(player, "gm_menu_sectors")[1]

	lu.assertEquals(V.optionSids(sectors), replies, "gm_menu_sectors replies")
	lu.assertEquals(V.linksOf(sectors), sectorLinks, "gm_menu_sectors links")
	lu.assertEquals(sectors.text, V.PREFIX .. "s_9ffd1405", "gm_menu_sectors line: Which mission?")
end

-- AC-9: gm_menu's mission 1 pick shows s_f3cbd30c, gm_menu_sectors' pick shows s_3080e198
function TestVrovelGmPicks:test_the_mission_1_picks_show_the_two_grant_lines()
	local plain = V.talk(V.pilot({ privileged = true }), { V.GM_REPLY, "s_165db597" })

	lu.assertEquals(V.ids(plain), { "duty_offer", "gm_menu", "gm_mission1_plain" }, "gm_menu route")
	lu.assertEquals(plain[3].text, V.PREFIX .. "s_f3cbd30c", "gm_menu's mission 1 line")
	lu.assertEquals(CS.transcriptUnresolved(plain), {}, "client strings")

	H.reset()

	local sectors = V.talk(V.pilot({ privileged = true, graduated = "1", t1 = 3 }), { V.GM_REPLY, "s_165db597" })

	lu.assertEquals(V.ids(sectors), { "private_property", "gm_menu_sectors", "gm_mission1" }, "gm_menu_sectors route")
	lu.assertEquals(sectors[3].text, V.PREFIX .. "s_3080e198", "gm_menu_sectors' mission 1 line")
end

-- AC-9: each pick starts its mission head (setting :attempted) or its duty, without checking any gate
for _, p in ipairs(PICKS) do
	for _, menu in ipairs({ { screen = "gm_menu", link = p.plain }, { screen = "gm_menu_sectors", link = p.sectors } }) do
		TestVrovelGmPicks["test_the_" .. menu.screen .. "_pick_" .. menu.link .. "_starts_its_quest"] = function()
			local player = V.pilot({ privileged = true })
			local spies = V.spyStarts()
			local t = V.drive(player, menu.screen, { p.reply })

			lu.assertEquals(V.ids(t), { menu.screen, menu.link }, "the walk")
			lu.assertTrue(t[2].stop, menu.link .. " ends")

			if p.mission then
				lu.assertEquals(V.startedCount(spies), { [V.HEADS[p.mission]] = 1 }, "heads started")
				lu.assertEquals(H.getQuestStatus(player, V.STATUS[p.mission] .. ":attempted"), "1", ":attempted of mission " .. p.mission)
			else
				lu.assertEquals(V.startedCount(spies), { [p.duty] = 1 }, "duties started")

				for n = 1, 4 do
					lu.assertNil(H.getQuestStatus(player, V.STATUS[n] .. ":attempted"), "a duty sets no :attempted (mission " .. n .. ")")
				end
			end

			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-9: the picks pay nothing, train nothing and write no flag
function TestVrovelGmPicks:test_the_gm_picks_pay_train_and_flag_nothing()
	for _, p in ipairs(PICKS) do
		H.reset()
		local player = V.pilot({ privileged = true, graduated = "2", xp = 999999 })

		V.spyStarts()
		V.drive(player, "gm_menu", { p.reply })
		lu.assertEquals(player.bankCredits, 0, p.plain .. ": credits")
		lu.assertEquals(V.standing(player), 0, p.plain .. ": standing")
		lu.assertEquals(V.flag(player), "2", p.plain .. ": the flag")
		lu.assertEquals(#V.held2(player), 0, p.plain .. ": skills")
	end
end

-- AC-9: the GM picks work for a pilot the gates would refuse (no skills, a quest running): SWG's test shortcut
function TestVrovelGmPicks:test_a_tester_can_start_any_mission_whatever_the_gates_say()
	local player = V.pilot({ privileged = true, graduated = "2", missions = 0, t2 = 0 })
	local spies = V.spyStarts()

	V.drive(player, "gm_menu", { "s_816055e2" })
	lu.assertEquals(V.startedCount(spies), { [V.I4] = 1 }, "mission 4 with no tier 2 skill")
end
