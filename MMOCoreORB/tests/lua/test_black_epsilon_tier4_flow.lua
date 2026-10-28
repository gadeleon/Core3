-- Nin Gursawe: the intro, the duty briefing and menu, the off-track path, the ready prompt and the hand-off to Declann.
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-7, AC-8 (ready), AC-11; Conversation flow 2, 4 and 5; Appendix A; D-2, D-8, D-9).

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local ALL = { 1, 2, 3, 4 }

local function key(player, suffix) return H.getQuestStatus(player, suffix) end

---------------------------------------------------------------------------------------------
-- The intro (AC-7)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Intro = {}

TestBlackEpsilonT4Intro.setUp = setUp

-- the six walks of Appendix A: replies from `intro` and the screens shown
local INTRO_WALKS = {
	{ end_ = "intro_end_a", replies = { "s_cdcb7b73", "s_453c3282", "s_fad3519e" }, ids = { "intro", "intro_black_epsilon", "intro_insurgent", "intro_end_a" } },
	{ end_ = "intro_end_b", replies = { "s_cdcb7b73", "s_453c3282", "s_41f35a20", "s_95c4c876" }, ids = { "intro", "intro_black_epsilon", "intro_insurgent", "intro_real_name", "intro_end_b" } },
	{ end_ = "intro_end_c", replies = { "s_2b6c0655", "s_c0dc404f", "s_a2d93e75" }, ids = { "intro", "intro_ego", "intro_rough", "intro_end_c" } },
	{ end_ = "intro_end_d", replies = { "s_2b6c0655", "s_c0dc404f", "s_e4de90b3", "s_4e7e870d" }, ids = { "intro", "intro_ego", "intro_rough", "intro_potent", "intro_end_d" } },
	{ end_ = "intro_end_e", replies = { "s_c06cf370", "s_ca776e30", "s_4e718340" }, ids = { "intro", "intro_instrument", "intro_who", "intro_end_e" } },
	{ end_ = "intro_end_f", replies = { "s_c06cf370", "s_ca776e30", "s_244c9eec" }, ids = { "intro", "intro_instrument", "intro_who", "intro_end_f" } },
}

for _, w in ipairs(INTRO_WALKS) do
	-- AC-7: the walk ends on its intro_end screen, which sets the intro key; the next talk does not open the intro
	TestBlackEpsilonT4Intro["test_the_walk_to_" .. w.end_ .. "_sets_the_intro_key_and_the_next_talk_skips_the_intro"] = function()
		local player = T.pilot()
		local t = T.talk(player, w.replies)

		lu.assertEquals(T.ids(t), w.ids, "screens shown")
		lu.assertTrue(t[#t].stop, w.end_ .. " ends the conversation")
		lu.assertEquals(key(player, T.INTRO_SUFFIX), "1", "the intro key")
		lu.assertNotEquals(T.firstScreen(player), "intro", "the next talk")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: the key is set on display of the end screen alone
	TestBlackEpsilonT4Intro["test_displaying_" .. w.end_ .. "_sets_the_intro_key"] = function()
		local player = T.pilot()

		lu.assertNil(key(player, T.INTRO_SUFFIX), "precondition: no intro key")
		T.drive(player, w.end_)
		lu.assertEquals(key(player, T.INTRO_SUFFIX), "1", "the intro key")
		lu.assertNil(key(player, T.MET_SUFFIX), "the met key is not set by the intro")
	end
end

-- AC-7: the screens before the end set nothing
function TestBlackEpsilonT4Intro:test_the_screens_before_the_end_do_not_set_the_intro_key()
	for _, w in ipairs(INTRO_WALKS) do
		local player = T.pilot()
		local shorter = {}

		for i = 1, #w.replies - 1 do
			shorter[i] = w.replies[i]
		end

		local t = T.talk(player, shorter)

		lu.assertEquals(T.ids(t)[#t], w.ids[#w.ids - 1], w.end_ .. ": the walk stops before the end screen")
		lu.assertNil(key(player, T.INTRO_SUFFIX), w.end_ .. ": no intro key before the end screen")
	end
end

-- AC-7, R-6: the first line carries the pilot's name in %NU and is filled through the TU parameter
function TestBlackEpsilonT4Intro:test_the_intro_line_gets_the_pilot_name()
	local t = T.talk(T.pilot())

	lu.assertEquals(t[1].text, T.PREFIX .. "s_735e94f9", "the intro line")
	lu.assertEquals(t[1].params.TU, "Ace", "the TU parameter")
end

---------------------------------------------------------------------------------------------
-- The briefing and the duty menu (AC-7)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Briefing = {}

TestBlackEpsilonT4Briefing.setUp = setUp

-- AC-7, D-8: expecting -> briefing (sets the met key) -> the duty briefing -> the duty menu
function TestBlackEpsilonT4Briefing:test_expecting_leads_through_the_briefing_which_sets_the_met_key()
	local player = T.pilot({ keys = { intro = true } })
	local t = T.talk(player, { "s_52917b0d", "s_4ecc8830", "s_3f68df7d", "s_362a48e0", "s_6b9c2fb8" })

	lu.assertEquals(T.ids(t), { "expecting", "briefing", "briefing_targets", "briefing_smuggling", "briefing_adrift", "duty_menu" }, "screens shown")
	lu.assertEquals(key(player, T.MET_SUFFIX), "1", "the met key")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the briefing screen sets the key on display
function TestBlackEpsilonT4Briefing:test_displaying_the_briefing_sets_the_met_key_and_the_next_talk_skips_expecting()
	local player = T.pilot({ keys = { intro = true } })

	lu.assertEquals(T.firstScreen(player), "expecting", "before")
	T.drive(player, "briefing")
	lu.assertEquals(key(player, T.MET_SUFFIX), "1", "the met key")
	lu.assertEquals(T.firstScreen(player), "tier4_incomplete", "the next talk of an on-track pilot")
end

-- AC-7: the other screens of the briefing set no key
function TestBlackEpsilonT4Briefing:test_the_other_briefing_screens_do_not_set_the_met_key()
	for _, id in ipairs({ "expecting", "briefing_targets", "briefing_smuggling", "briefing_adrift", "duty_menu", "duty_declined" }) do
		local player = T.pilot({ keys = { intro = true } })

		T.drive(player, id)
		lu.assertNil(key(player, T.MET_SUFFIX), id .. ": no met key")
	end
end

-- AC-7: "I'd like to decline" ends and starts nothing
function TestBlackEpsilonT4Briefing:test_declining_the_duty_starts_nothing()
	local spies = T.spyStarts()
	local player = T.pilot({ keys = { intro = true, met = true } })
	local t2 = T.drive(player, "briefing_adrift", { "s_d26d7ae1" })

	lu.assertEquals(T.ids(t2), { "briefing_adrift", "duty_declined" }, "screens shown")
	lu.assertTrue(t2[#t2].stop, "duty_declined ends the conversation")
	lu.assertEquals(T.started(spies), {}, "no duty started")
end

local MENUS = { "duty_menu", "tier4_incomplete", "here_for_work" }

for _, menu in ipairs(MENUS) do
	for _, d in ipairs(T.DUTY_MENU) do
		-- AC-7: each of the four duty replies starts exactly its duty once, on the menu screens
		TestBlackEpsilonT4Briefing["test_" .. menu .. "_reply_" .. d.screen .. "_starts_exactly_that_duty_once"] = function()
			local spies = T.spyStarts()
			local player = T.pilot({ keys = { intro = true, met = true } })
			local t = T.drive(player, menu, { d.reply })

			lu.assertEquals(T.ids(t), { menu, d.screen }, "screens shown")
			lu.assertTrue(t[#t].stop, d.screen .. " ends the conversation")
			lu.assertEquals(T.started(spies), { d.global }, "quests started")
			lu.assertEquals(#spies[d.global], 1, d.global .. ": startQuest calls")
			lu.assertEquals(spies[d.global][1].args[1], player, "the duty starts for the talking pilot")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-7: "Can I hear the briefing again?" returns to the briefing
	TestBlackEpsilonT4Briefing["test_" .. menu .. "_offers_the_briefing_again"] = function()
		local spies = T.spyStarts()
		local t = T.drive(T.pilot({ keys = { intro = true, met = true } }), menu, { T.BRIEFING_AGAIN_REPLY })

		lu.assertEquals(T.ids(t), { menu, "briefing" }, "screens shown")
		lu.assertEquals(T.started(spies), {}, "nothing started")
	end

	-- AC-7: the menu lists the four duties and the briefing, in order
	TestBlackEpsilonT4Briefing["test_" .. menu .. "_lists_the_four_duties_then_the_briefing"] = function()
		local t = T.drive(T.pilot({ keys = { intro = true, met = true } }), menu)

		lu.assertEquals(T.optionSids(t[1]), { "s_99bb69ca", "s_4349156c", "s_b881db2e", "s_98338b18", "s_49805f81" }, "menu replies")
		lu.assertEquals(T.linksOf(t[1]), { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "briefing" }, "menu links")
	end
end

-- AC-7: the duty screens start the duty on display and nothing else
function TestBlackEpsilonT4Briefing:test_a_duty_screen_displayed_alone_starts_only_its_own_duty()
	for _, d in ipairs(T.DUTY_MENU) do
		local spies = T.spyStarts()

		T.drive(T.pilot({ keys = { intro = true, met = true } }), d.screen)
		lu.assertEquals(T.started(spies), { d.global }, d.screen .. ": quests started")
		H.reset()
	end
end

-- AC-7, D-16: the duties start for real (the duty types' own rules apply)
function TestBlackEpsilonT4Briefing:test_a_duty_chosen_in_a_ship_really_starts()
	for _, d in ipairs(T.DUTY_MENU) do
		H.reset()

		local q = T.quest(d.global)
		local player = T.pilot({ keys = { intro = true, met = true }, inShip = true, zone = q.questZone })

		T.drive(player, "here_for_work", { d.reply })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": active in the journal")
	end
end

---------------------------------------------------------------------------------------------
-- The off-track path (AC-7, C-2)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4OffTrack = {}

TestBlackEpsilonT4OffTrack.setUp = setUp

local STORM = function() return rawget(_G, "STORM_SQUADRON") end

-- AC-7, C-2: with the four _03 skills, no mission and no datapad quest the reply leads to the duties
function TestBlackEpsilonT4OffTrack:test_an_off_track_pilot_who_can_fly_non_track_duties_is_offered_them()
	local t = T.talk(T.pilot({ squadron = STORM() }), { "s_4854758d" })

	lu.assertEquals(T.ids(t), { "off_track", "off_track_duties" }, "screens shown")
	lu.assertEquals(t[2].text, T.PREFIX .. "s_81995254", "the duties line")
	lu.assertEquals(T.linksOf(t[1]), { "off_track_duties" }, "the link built for this pilot")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7, C-2: any datapad quest, a running chain or a missing _03 skill leads to the refusal
function TestBlackEpsilonT4OffTrack:test_an_off_track_pilot_who_cannot_fly_duties_gets_the_refusal()
	local cases = {
		{ "a datapad duty", { squadron = STORM(), datapad = "duty" } },
		{ "a datapad story mission", { squadron = STORM(), datapad = "story" } },
		{ "three _03 skills", { squadron = STORM(), t3 = 3 } },
		{ "a running Black Epsilon chain", { squadron = STORM(), mission = { [3] = "active" } } },
		{ "a running duty", { squadron = STORM(), duty = T.DUTIES[1] } },
	}

	for _, c in ipairs(cases) do
		local t = T.talk(T.pilot(c[2]), { "s_4854758d" })

		lu.assertEquals(T.ids(t), { "off_track", "off_track_no_duty" }, c[1] .. ": screens shown")
		lu.assertEquals(t[2].text, T.PREFIX .. "s_83af3aa0", c[1] .. ": the refusal line")
		lu.assertTrue(t[2].stop, c[1] .. ": the refusal ends the conversation")
	end
end

-- AC-7, D-8: the off-track duties lead to the briefing, which sets the met key (harmless: only on-track tier 4 pilots read it)
function TestBlackEpsilonT4OffTrack:test_the_off_track_duties_lead_to_the_briefing_and_the_duty_menu()
	local player = T.pilot({ squadron = STORM() })
	local t = T.talk(player, { "s_4854758d", "s_c82e9a2f", "s_4ecc8830", "s_3f68df7d", "s_362a48e0", "s_6b9c2fb8", "s_99bb69ca" })

	lu.assertEquals(T.ids(t), { "off_track", "off_track_duties", "briefing", "briefing_targets", "briefing_smuggling", "briefing_adrift", "duty_menu", "duty_destroy" }, "screens shown")
	lu.assertEquals(key(player, T.MET_SUFFIX), "1", "the met key (D-8)")
end

-- AC-7: the off-track pilot's duty start is the same global
function TestBlackEpsilonT4OffTrack:test_an_off_track_pilot_starts_the_destroy_duty_through_the_menu()
	local spies = T.spyStarts()

	T.talk(T.pilot({ squadron = STORM() }), { "s_4854758d", "s_c82e9a2f", "s_4ecc8830", "s_3f68df7d", "s_362a48e0", "s_6b9c2fb8", "s_99bb69ca" })
	lu.assertEquals(T.started(spies), { T.DUTIES[1] }, "quests started")
end

---------------------------------------------------------------------------------------------
-- The ready prompt (AC-8, C-3)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Ready = {}

TestBlackEpsilonT4Ready.setUp = setUp

-- AC-8, C-3: ready -> "Yes, I am." shows the brief of getReadyMission
function TestBlackEpsilonT4Ready:test_the_ready_prompt_leads_to_the_brief_of_the_ready_mission()
	local cases = {
		{ n = 1, o = { t4 = { 1 } } },
		{ n = 2, o = { t4 = { 1, 2 }, paid = { 1 } } },
		{ n = 3, o = { t4 = { 1, 2, 3 }, paid = { 1, 2 } } },
		{ n = 4, o = { t4 = ALL, paid = { 1, 2, 3 } } },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local o = { keys = { intro = true, met = true } }

		for k, v in pairs(c.o) do
			o[k] = v
		end

		local t = T.talk(T.pilot(o), { "s_36a4e374" })

		lu.assertEquals(T.ids(t), { "ready", "m" .. c.n .. "_brief" }, "mission " .. c.n .. ": screens shown")
		lu.assertEquals(t[1].text, T.PREFIX .. "s_cbf9f5e7", "the ready line")
		lu.assertEquals(T.linksOf(t[1]), { "m" .. c.n .. "_brief" }, "mission " .. c.n .. ": the link built for this pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8: the ready prompt grants nothing until a grant screen
function TestBlackEpsilonT4Ready:test_the_ready_prompt_and_the_brief_start_nothing()
	local spies = T.spyStarts()
	local player = T.pilot({ keys = { intro = true, met = true }, t4 = { 1 } })

	T.talk(player, { "s_36a4e374" })
	lu.assertEquals(T.started(spies), {}, "quests started")
	lu.assertNil(H.getQuestStatus(player, "corellia_imperial_tier4_1:attempted"), "no attempted key")
end

---------------------------------------------------------------------------------------------
-- The hand-off to Declann (AC-11, D-9)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4HandOff = {}

TestBlackEpsilonT4HandOff.setUp = setUp

local function graduate(extra)
	local o = { t4 = ALL, paid = ALL, keys = { intro = true, met = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

-- AC-11: both Declann routes set the key
function TestBlackEpsilonT4HandOff:test_the_two_transfer_routes_set_the_declann_key_and_end()
	local routes = {
		{ replies = { "s_6d9530c5", "s_817cf33", "s_9ec3be5d" }, ids = { "transfer", "transfer_declann", "transfer_who", "transfer_done_a" } },
		{ replies = { "s_6d9530c5", "s_4b6d4db", "s_11c1ca52" }, ids = { "transfer", "transfer_declann", "transfer_grand_admiral", "transfer_done_b" } },
	}

	for _, r in ipairs(routes) do
		local player = graduate()
		local t = T.talk(player, r.replies)

		lu.assertEquals(T.ids(t), r.ids, "screens shown")
		lu.assertTrue(t[#t].stop, "the transfer ends")
		lu.assertEquals(key(player, T.DECLANN_SUFFIX), "1", "the Declann key")
		lu.assertEquals(T.firstScreen(player), "here_for_work", "the next talk")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-11: the screens before the end set no key
function TestBlackEpsilonT4HandOff:test_the_transfer_screens_before_the_end_do_not_set_the_declann_key()
	for _, id in ipairs({ "transfer", "transfer_declann", "transfer_who", "transfer_grand_admiral" }) do
		local player = graduate()

		T.drive(player, id)
		lu.assertNil(key(player, T.DECLANN_SUFFIX), id .. ": no Declann key")
	end

	for _, id in ipairs({ "transfer_done_a", "transfer_done_b" }) do
		local player = graduate()

		T.drive(player, id)
		lu.assertEquals(key(player, T.DECLANN_SUFFIX), "1", id .. ": the Declann key")
	end
end

-- AC-11: the master skill skips the transfer
function TestBlackEpsilonT4HandOff:test_a_pilot_holding_the_master_skill_skips_the_transfer()
	lu.assertEquals(T.firstScreen(graduate({ master = true })), "here_for_work", "the master skill")
end

-- AC-11: with M4 won and unpaid the reward comes first, then the transfer on the next talk
function TestBlackEpsilonT4HandOff:test_the_fourth_reward_comes_before_the_transfer()
	local player = T.pilot({ t4 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" }, keys = { intro = true, met = true } })

	lu.assertEquals(T.firstScreen(player), "m4_reward", "M4 won and unpaid")
	lu.assertEquals(player.bankCredits, T.CREDITS, "the reward screen paid on display")
	lu.assertEquals(T.firstScreen(player), "transfer", "the next talk: paid, so the transfer (no widening: J pays on display)")
	lu.assertEquals(player.bankCredits, T.CREDITS, "paid once")
end

-- AC-11 / expecting: the met key unset shows expecting once first
function TestBlackEpsilonT4HandOff:test_a_graduate_without_the_met_key_sees_expecting_then_the_transfer()
	local player = T.pilot({ t4 = ALL, paid = ALL, keys = { intro = true } })
	local t = T.talk(player, { "s_52917b0d" })

	lu.assertEquals(T.ids(t), { "expecting", "briefing" }, "screens shown")
	lu.assertEquals(T.firstScreen(player), "transfer", "the next talk")
end

-- D-2 / correction 1: nothing in the conversation grants the master skill or a master mission
function TestBlackEpsilonT4HandOff:test_no_screen_grants_the_master_skill_or_a_master_quest()
	local spies = T.spyStarts()
	local grants = T.recordGrants()

	for _, row in ipairs(T.SCREENS) do
		if not row.action:match("^start") then
			T.drive(graduate({ xp = 20000000 }), row.id)
		end
	end

	T.restore()
	lu.assertEquals(grants, {}, "grantSpaceSkill calls over every screen")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "skill grants over every screen (the master skill included)")

	for _, g in ipairs(H.questGlobals()) do
		lu.assertFalse(g:find("corellia_imperial_master", 1, true) ~= nil, "no quest table named " .. g .. " (SWG has no destroy/corellia_imperial_master)")
	end
end

-- AC-11: the Declann key is the documented quest-status key
function TestBlackEpsilonT4HandOff:test_the_declann_key_is_stored_under_the_squadron_constant_with_the_player_id()
	local player = graduate()

	T.drive(player, "transfer_done_a")
	lu.assertEquals(H.getQuestStatus(player, BlackEpsilonSquadronScreenplay.TIER4_DECLANN_KEY), "1", "getQuestStatus(playerID .. TIER4_DECLANN_KEY)")
end
