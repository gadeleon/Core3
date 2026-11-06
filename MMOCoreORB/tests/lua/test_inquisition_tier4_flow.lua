-- Ja'ce Yiaso: the first meeting, the duty briefing and menus, the off-track path and the ready prompt.
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-7, AC-8 (ready); Conversation flow 2, 3 and 5; Appendix A; D-8, D-10, D-17; FJ-9).

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local function setUp()
	H.reset()
	J4.requireConversation(lu)
end

local function key(player, suffix) return H.getQuestStatus(player, suffix) end

local MENUS = { "duty_rescue_info", "tier4_incomplete", "here_for_work" }
local MENU_REPLIES = { "s_851406fb", "s_82095b20", "s_60a8bfcb", "s_be7e95c", "s_49805f81" }
local MENU_LINKS = { "duty_destroy", "duty_escort", "duty_recovery", "duty_rescue", "duty_briefing" }

---------------------------------------------------------------------------------------------
-- The first meeting and the briefing (AC-7)
---------------------------------------------------------------------------------------------

TestInquisitionT4Intro = {}

TestInquisitionT4Intro.setUp = setUp

-- AC-7, D-8: intro -> "Ready to serve, sir." -> intro_briefing (sets the met key) -> the four-part briefing -> the duty menu
function TestInquisitionT4Intro:test_the_first_meeting_walks_through_the_briefing_which_sets_the_met_key()
	local player = J4.pilot({})
	local t = J4.talk(player, { "s_a3958e6a", "s_8d7e0eff", "s_61657d0f", "s_362a48e0" })

	lu.assertEquals(J4.ids(t), { "intro", "intro_briefing", "duty_escort_info", "duty_recovery_info", "duty_rescue_info" }, "screens shown")
	lu.assertEquals(t[1].text, J4.PREFIX .. "s_59da8c80", "the intro line")
	lu.assertEquals(t[2].text, J4.PREFIX .. "s_85c9e37e", "the briefing line")
	lu.assertEquals(key(player, J4.MET_SUFFIX), "1", "the met key")
	lu.assertEquals(J4.optionSids(t[5]), MENU_REPLIES, "the duty menu replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the met key is set on display of intro_briefing alone; the next talk does not open intro
function TestInquisitionT4Intro:test_displaying_intro_briefing_sets_the_met_key_and_the_next_talk_skips_the_intro()
	local player = J4.pilot({})

	lu.assertEquals(J4.firstScreen(player), "intro", "before")
	J4.drive(player, "intro_briefing")
	lu.assertEquals(key(player, J4.MET_SUFFIX), "1", "the met key")
	lu.assertEquals(J4.firstScreen(player), "tier4_incomplete", "the next talk of an on-track pilot")
end

-- AC-7: nothing else sets the key
function TestInquisitionT4Intro:test_the_other_briefing_screens_and_the_intro_set_no_met_key()
	for _, id in ipairs({ "intro", "duty_briefing", "duty_escort_info", "duty_recovery_info", "duty_rescue_info", "tier4_incomplete", "off_track", "off_track_duties" }) do
		local player = J4.pilot({})

		J4.drive(player, id)
		lu.assertNil(key(player, J4.MET_SUFFIX), id .. ": no met key")
	end
end

-- AC-7: the intro is the client line with its one reply
function TestInquisitionT4Intro:test_the_intro_line_is_the_client_line()
	local t = J4.talk(J4.pilot({}))

	lu.assertEquals(t[1].text, J4.PREFIX .. "s_59da8c80", "the intro line")
	lu.assertEquals(J4.optionSids(t[1]), { "s_a3958e6a" }, "the one reply")
	lu.assertEquals(J4.linksOf(t[1]), { "intro_briefing" }, "its link")
end

-- AC-7, D-8: the met key is a persistent status key under the squadron constant
function TestInquisitionT4Intro:test_the_met_key_is_stored_under_the_squadron_constant_with_the_player_id()
	local player = J4.pilot({})

	J4.drive(player, "intro_briefing")
	lu.assertEquals(H.getQuestStatus(player, InquisitionSquadronScreenplay.TIER4_MET_KEY), "1", "<playerID> .. TIER4_MET_KEY")
end

---------------------------------------------------------------------------------------------
-- The duty briefing and the menus (AC-7)
---------------------------------------------------------------------------------------------

TestInquisitionT4Duties = {}

TestInquisitionT4Duties.setUp = setUp

-- AC-7: the briefing screens start nothing
function TestInquisitionT4Duties:test_the_briefing_screens_start_nothing()
	local spies = J4.spyStarts()

	for _, id in ipairs({ "intro_briefing", "duty_briefing", "duty_escort_info", "duty_recovery_info", "duty_rescue_info" }) do
		J4.drive(J4.pilot({ met = true }), id)
	end

	lu.assertEquals(J4.started(spies), {}, "no duty started")
end

for _, menu in ipairs(MENUS) do
	for _, d in ipairs(J4.DUTY_MENU) do
		-- AC-7: each of the four duty replies starts exactly its duty once, on the menu screens
		TestInquisitionT4Duties["test_" .. menu .. "_reply_" .. d.screen .. "_starts_exactly_that_duty_once"] = function()
			local spies = J4.spyStarts()
			local player = J4.pilot({ met = true })
			local t = J4.drive(player, menu, { d.reply })

			lu.assertEquals(J4.ids(t), { menu, d.screen }, "screens shown")
			lu.assertTrue(t[#t].stop, d.screen .. " ends the conversation")
			lu.assertEquals(J4.started(spies), { d.global }, "quests started")
			lu.assertEquals(#spies[d.global], 1, d.global .. ": startQuest calls")
			lu.assertEquals(spies[d.global][1].args[1], player, "the duty starts for the talking pilot")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-7: "Can I hear the briefing again?" returns to duty_briefing, which sets no key (FJ-9)
	TestInquisitionT4Duties["test_" .. menu .. "_offers_the_briefing_again_without_the_met_key"] = function()
		local spies = J4.spyStarts()
		local player = J4.pilot({})
		local t = J4.drive(player, menu, { J4.BRIEFING_AGAIN_REPLY })

		lu.assertEquals(J4.ids(t), { menu, "duty_briefing" }, "screens shown")
		lu.assertEquals(J4.started(spies), {}, "nothing started")
		lu.assertNil(key(player, J4.MET_SUFFIX), "duty_briefing sets no key")
	end

	-- AC-7: the menu lists the four duties and the briefing, in order
	TestInquisitionT4Duties["test_" .. menu .. "_lists_the_four_duties_then_the_briefing"] = function()
		local t = J4.drive(J4.pilot({ met = true }), menu)

		lu.assertEquals(J4.optionSids(t[1]), MENU_REPLIES, "menu replies")
		lu.assertEquals(J4.linksOf(t[1]), MENU_LINKS, "menu links")
	end
end

-- AC-7: the duty screens start the duty on display and nothing else
function TestInquisitionT4Duties:test_a_duty_screen_displayed_alone_starts_only_its_own_duty()
	for _, d in ipairs(J4.DUTY_MENU) do
		local spies = J4.spyStarts()

		J4.drive(J4.pilot({ met = true }), d.screen)
		lu.assertEquals(J4.started(spies), { d.global }, d.screen .. ": quests started")
		H.reset()
	end
end

-- AC-7: the duties start for real (the duty types' own rules apply)
function TestInquisitionT4Duties:test_a_duty_chosen_in_a_ship_really_starts()
	for _, d in ipairs(J4.DUTY_MENU) do
		H.reset()

		local q = J4.quest(d.global)
		local player = J4.pilot({ met = true, inShip = true, zone = q.questZone })

		J4.drive(player, "here_for_work", { d.reply })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": active in the journal")
	end
end

-- AC-7, AC-4 (c): a running duty makes the pilot "on a mission"
function TestInquisitionT4Duties:test_a_running_duty_opens_on_mission_on_the_next_talk()
	local player = J4.pilot({ met = true, inShip = true, zone = "space_dathomir" })

	J4.drive(player, "tier4_incomplete", { J4.DUTY_MENU[1].reply })
	lu.assertEquals(J4.firstScreen(player), "on_mission", "the next talk")
end

-- AC-7 / D-10: a duty screen raises a pilot still at tier 3 (four _03 skills) to tier 4
function TestInquisitionT4Duties:test_a_duty_screen_raises_the_pilot_tier_3_to_4()
	J4.spyStarts()

	local player = J4.pilot({ met = true, pilotTier = 3 })

	J4.drive(player, "duty_destroy")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the duty screen")
end

---------------------------------------------------------------------------------------------
-- The off-track path (AC-7, C-2)
---------------------------------------------------------------------------------------------

TestInquisitionT4OffTrack = {}

TestInquisitionT4OffTrack.setUp = setUp

-- AC-7, C-2: with the four _03 skills, no mission and no datapad quest the reply leads to the duties
function TestInquisitionT4OffTrack:test_an_off_track_pilot_who_can_fly_non_track_duties_is_offered_them()
	local t = J4.talk(J4.pilot({ squadron = "storm" }), { "s_4854758d" })

	lu.assertEquals(J4.ids(t), { "off_track", "off_track_duties" }, "screens shown")
	lu.assertEquals(t[2].text, J4.PREFIX .. "s_1832fe3c", "the duties line")
	lu.assertEquals(J4.optionSids(t[1]), { "s_4854758d" }, "the one reply")
	lu.assertEquals(J4.linksOf(t[1]), { "off_track_duties" }, "the link built for this pilot")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7, C-2: any space quest, a running chain or a missing _03 skill leads to the refusal
function TestInquisitionT4OffTrack:test_an_off_track_pilot_who_cannot_fly_duties_gets_the_refusal()
	local cases = {
		{ "a datapad duty", { squadron = "storm", datapad = "duty" } },
		{ "a datapad story mission", { squadron = "storm", datapad = "story" } },
		{ "three _03 skills", { squadron = "storm", t3 = 3 } },
		{ "a running Inquisition chain", { squadron = "storm", mission = { [3] = "active" } } },
		{ "a running duty", { squadron = "storm", duty = J4.DUTIES[1] } },
		{ "no _03 skill at all", { squadron = false, t3 = 0 } },
	}

	for _, c in ipairs(cases) do
		local t = J4.talk(J4.pilot(c[2]), { "s_4854758d" })

		lu.assertEquals(J4.ids(t), { "off_track", "off_track_refused" }, c[1] .. ": screens shown")
		lu.assertEquals(t[2].text, J4.PREFIX .. "s_1c3578bb", c[1] .. ": the refusal line")
		lu.assertTrue(t[2].stop, c[1] .. ": the refusal ends the conversation")
	end
end

-- AC-7: the off-track pilot says no to the duties
function TestInquisitionT4OffTrack:test_an_off_track_pilot_can_decline_the_duties()
	local spies = J4.spyStarts()
	local t = J4.talk(J4.pilot({ squadron = "storm" }), { "s_4854758d", "s_90ce1297" })

	lu.assertEquals(J4.ids(t), { "off_track", "off_track_duties", "off_track_no" }, "screens shown")
	lu.assertTrue(t[3].stop, "off_track_no ends")
	lu.assertEquals(J4.started(spies), {}, "nothing started")
end

-- AC-7, FJ-9: the off-track duties lead to duty_briefing, which sets no met key, then to the duty menu
function TestInquisitionT4OffTrack:test_the_off_track_duties_lead_to_the_duty_briefing_and_the_menu_without_the_met_key()
	local player = J4.pilot({ squadron = "storm" })
	local t = J4.talk(player, { "s_4854758d", "s_c82e9a2f", "s_8d7e0eff", "s_61657d0f", "s_362a48e0", "s_851406fb" })

	lu.assertEquals(J4.ids(t), { "off_track", "off_track_duties", "duty_briefing", "duty_escort_info", "duty_recovery_info", "duty_rescue_info", "duty_destroy" }, "screens shown")
	lu.assertNil(key(player, J4.MET_SUFFIX), "no met key for an off-track pilot")
end

-- AC-7: the off-track pilot's duty start is the same global
function TestInquisitionT4OffTrack:test_an_off_track_pilot_starts_the_destroy_duty_through_the_menu()
	local spies = J4.spyStarts()

	J4.talk(J4.pilot({ squadron = "storm" }), { "s_4854758d", "s_c82e9a2f", "s_8d7e0eff", "s_61657d0f", "s_362a48e0", "s_851406fb" })
	lu.assertEquals(J4.started(spies), { J4.DUTIES[1] }, "quests started")
end

---------------------------------------------------------------------------------------------
-- The ready prompt (AC-8, C-3)
---------------------------------------------------------------------------------------------

TestInquisitionT4Ready = {}

TestInquisitionT4Ready.setUp = setUp

-- a pilot ready for mission n: n - 1 missions done (paid), n skills
local function readyFor(n, extra)
	local t4, paid = {}, {}

	for i = 1, n do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return J4.pilot(o)
end

-- AC-8, C-3: the ready prompt has one reply, leading to the brief of the ready mission
function TestInquisitionT4Ready:test_the_ready_prompt_leads_to_the_brief_of_the_ready_mission()
	for n = 1, 4 do
		local t = J4.talk(readyFor(n), { "s_52917b0d" })

		lu.assertEquals(J4.ids(t), { "ready", "m" .. n .. "_brief" }, "mission " .. n .. ": screens shown")
		lu.assertEquals(t[1].text, J4.PREFIX .. "s_ace49d41", "the ready line")
		lu.assertEquals(J4.optionSids(t[1]), { "s_52917b0d" }, "mission " .. n .. ": the one reply")
		lu.assertEquals(J4.linksOf(t[1]), { "m" .. n .. "_brief" }, "mission " .. n .. ": the link built for this pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-8: the ready prompt and the brief start nothing
function TestInquisitionT4Ready:test_the_ready_prompt_and_the_briefs_start_nothing()
	local spies = J4.spyStarts()

	for n = 1, 4 do
		local player = readyFor(n)

		J4.talk(player, { "s_52917b0d" })
		lu.assertNil(H.getQuestStatus(player, J4.MISSIONS[n].status .. ":attempted"), "mission " .. n .. ": no attempted key before an accept")
	end

	lu.assertEquals(J4.started(spies), {}, "quests started")
end
