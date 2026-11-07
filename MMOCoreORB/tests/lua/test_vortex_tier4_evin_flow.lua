-- Brother Extok Evin: the first meeting, the duty menus and the four duties, the off-track duty offer (AC-4).
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (AC-4; Conversation flow 2 (C-2), 3 (table H) and 5; FE-5, FE-6; D-13; I-5, I-7).
--
-- The met key is set on display of met_b5eac7c2 (the line after "Good to meet you.") and nowhere else. The duty briefing (duty_brief_1 .. duty_brief_4) is reached from
-- off_track_duties or from "Can I hear the briefing again?" (s_49805f81) on any of the four duty menus; it sets no key. Each duty reply starts exactly its duty global through
-- startQuest(player, npc) and sets no <playerID>naboo_rebel_tier4_1:* key (the duties set no key; PA FE-5). The duty globals' startQuest is spied (H.spyOn does not call the
-- original) except in the "real start" tests.

local lu = require("luaunit")
local H = require("harness")
local E = require("vortex_tier4_data")
local CS = require("harness.client_strings")

E.loadConversation()

local function setUp()
	H.reset()
	E.requireConversation(lu)
end

local function tearDown() E.restore() end

-- the status keys changed between two snapshots
local function statusDiff(player, before, after)
	local id, out = tostring(player.objectID), {}

	for key, value in pairs(after) do
		if before[key] ~= value then
			out[#out + 1] = (key:sub(1, #id) == id) and key:sub(#id + 1) or key
		end
	end

	for key in pairs(before) do
		if after[key] == nil then
			out[#out + 1] = (key:sub(1, #id) == id) and key:sub(#id + 1) or key
		end
	end

	table.sort(out)
	return out
end

local function statusOf(player) return E.snapshot(player).status end

TestEvinMeeting = {}

TestEvinMeeting.setUp = setUp

-- the whole first meeting: intro, "Good to meet you.", Ezkiel's report, the escalation, the four-mission roster, the duty menu
local MEETING_REPLIES = { "s_4265144c", "s_dcc126b1", "s_b3e9c738", "s_9c236354", "s_94d8d136", "s_1adbadc4", "s_5e2a2bb1", "s_61657d0f", "s_6598178f" }
local MEETING_IDS = {
	"intro", "met_b5eac7c2", "met_f789d42a", "met_7dec31dd", "met_e67c13ca", "met_e26b9261", "met_7455cef5", "met_ae528424", "met_e5a30f12", "met_b5815881",
}

-- AC-4: the whole first meeting is one walk from the intro to the duty menu
function TestEvinMeeting:test_the_first_meeting_walks_from_the_intro_through_the_roster_to_the_duty_menu()
	local t = E.talk(E.pilot({}), MEETING_REPLIES)

	lu.assertEquals(E.ids(t), MEETING_IDS, "the meeting")
	lu.assertEquals(E.optionSids(t[10]), E.MENU_REPLIES, "the duty menu replies")
	lu.assertEquals(E.linksOf(t[10]), E.MENU_LINKS, "the duty menu links")
	lu.assertFalse(t[10].stop, "the duty menu waits for a reply")
	lu.assertEquals(t[10].params.TU, "Ace", "the roster's last line greets by first name")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-4, FE-2: the met key is set on display of met_b5eac7c2, by that screen alone, and the next talk does not open the intro
function TestEvinMeeting:test_intro_then_the_reply_sets_the_met_key_and_the_next_talk_is_not_the_intro()
	local player = E.pilot({})
	local before = statusOf(player)
	local t = E.talk(player, { "s_4265144c" })

	lu.assertEquals(E.ids(t), { "intro", E.MET_SCREEN }, "screens shown")
	lu.assertEquals(t[2].text, E.PREFIX .. "s_b5eac7c2", "'You too. I've read your report...'")
	lu.assertTrue(E.hasMet(player), "the met key")
	lu.assertEquals(H.getQuestStatus(player, E.MET_KEY), "1", "the met key value")
	lu.assertEquals(statusDiff(player, before, statusOf(player)), { E.MET_KEY }, "the only key written")
	lu.assertEquals(E.flag(player), "3", "VORTEX_PILOT_KEY untouched")
	lu.assertNotEquals(E.firstScreen(player), "intro", "the next talk")
	lu.assertEquals(E.firstScreen(player), "tier4_incomplete", "no XP, no skill: the duty menu")
end

-- AC-4: leaving the intro without replying sets nothing
function TestEvinMeeting:test_leaving_the_intro_without_a_reply_sets_nothing()
	local player = E.pilot({})
	local before = E.snapshot(player)

	E.talk(player)
	E.drive(player, "intro")
	lu.assertFalse(E.hasMet(player), "the met key")
	lu.assertEquals(E.snapshot(player).status, before.status, "no key written")
	lu.assertEquals(E.firstScreen(player), "intro", "the next talk is the intro again")
end

-- AC-4: the key is set by display of met_b5eac7c2 and by no other screen of the meeting
function TestEvinMeeting:test_no_other_screen_of_the_meeting_sets_the_met_key()
	for _, id in ipairs(MEETING_IDS) do
		if id ~= E.MET_SCREEN then
			H.reset()

			local player = E.pilot({})

			E.drive(player, id)
			lu.assertFalse(E.hasMet(player), "screen '" .. id .. "': the met key")
		end
	end

	local player = E.pilot({})

	E.drive(player, E.MET_SCREEN)
	lu.assertTrue(E.hasMet(player), "met_b5eac7c2: the met key")
end

-- AC-4: an already met pilot who sees the line again keeps the key and nothing else changes
function TestEvinMeeting:test_showing_the_met_line_again_changes_nothing_else()
	local player = E.pilot({ met = true })
	local before = E.snapshot(player)

	E.drive(player, E.MET_SCREEN)
	lu.assertEquals(E.snapshot(player).status, before.status, "status keys")
	lu.assertEquals(E.flag(player), "3", "VORTEX_PILOT_KEY")
end

---------------------------------------------------------------------------------------------
-- The duty briefing and the duty menus
---------------------------------------------------------------------------------------------

TestEvinDuties = {}

TestEvinDuties.setUp = setUp
TestEvinDuties.tearDown = tearDown

-- AC-4, FE-6: "Can I hear the briefing again?" on any of the four menus leads to duty_brief_1, then the three steps to duty_brief_4 (no key, no duty), which ends on the menu
function TestEvinDuties:test_the_briefing_again_reply_of_every_menu_walks_the_four_duty_briefing_screens_and_sets_nothing()
	for _, menu in ipairs(E.MENUS) do
		H.reset()

		local spies = E.spyDuties()
		local player = E.pilot({ met = true, xp = 0 })
		local before = E.snapshot(player)
		local t = E.drive(player, menu, { "s_49805f81", "s_5e2a2bb1", "s_61657d0f", "s_6598178f" })

		lu.assertEquals(E.ids(t), { menu, "duty_brief_1", "duty_brief_2", "duty_brief_3", "duty_brief_4" }, "menu " .. menu .. ": the walk")
		lu.assertEquals(t[2].text, E.PREFIX .. "s_7455cef5", "menu " .. menu .. ": 'Here's the first mission.'")
		lu.assertEquals(t[5].text, E.PREFIX .. "s_c2129c67", "menu " .. menu .. ": 'And finally, mission number four!'")
		lu.assertEquals(E.optionSids(t[5]), E.MENU_REPLIES, "menu " .. menu .. ": duty_brief_4 is a duty menu too")
		lu.assertEquals(E.startedDuties(spies), {}, "menu " .. menu .. ": no duty started by the briefing")
		lu.assertEquals(E.snapshot(player).status, before.status, "menu " .. menu .. ": no key written")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		E.restore()
	end
end

-- AC-4: duty_brief_4 loops back to duty_brief_1 through the briefing-again reply
function TestEvinDuties:test_the_briefing_loops_through_the_briefing_again_reply()
	local t = E.drive(E.pilot({ met = true }), "duty_brief_4", { "s_49805f81", "s_5e2a2bb1", "s_61657d0f", "s_6598178f", "s_49805f81" })

	lu.assertEquals(E.ids(t), { "duty_brief_4", "duty_brief_1", "duty_brief_2", "duty_brief_3", "duty_brief_4", "duty_brief_1" }, "the loop")
end

-- AC-4: the four duty replies of every menu start exactly their duty once, end the conversation, and set no naboo_rebel_tier4_1 key
function TestEvinDuties:test_each_duty_reply_of_every_menu_starts_exactly_its_duty_once_and_sets_no_key()
	for _, menu in ipairs(E.MENUS) do
		for i, screen in ipairs(E.DUTY_ORDER) do
			H.reset()

			local spies = E.spyDuties()
			local player = E.pilot({ met = true })
			local before = E.snapshot(player)
			local t = E.drive(player, menu, { E.MENU_REPLIES[i] })
			local want = E.DUTY_SCREENS[screen].global

			lu.assertEquals(E.ids(t), { menu, screen }, "menu " .. menu .. ", reply " .. i .. ": the walk")
			lu.assertTrue(t[2].stop, screen .. " ends the conversation")
			lu.assertEquals(E.startedDuties(spies), { want .. " x1" }, "menu " .. menu .. ", " .. screen .. ": duties started")
			lu.assertEquals(spies[want][1].args[1], player, "startQuest got the pilot")
			lu.assertEquals(E.keysNamed(player, "naboo_rebel_tier4_1"), {}, screen .. ": no <playerID>naboo_rebel_tier4_1:* key")
			lu.assertEquals(E.snapshot(player).status, before.status, screen .. ": no key written")
			lu.assertEquals(E.flag(player), "3", screen .. ": VORTEX_PILOT_KEY untouched")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end
end

-- AC-4, I-5: a duty pays nothing and starts no mission (no head, no escort-duty mix-up)
function TestEvinDuties:test_a_duty_starts_no_mission_head_and_pays_nothing()
	for i, screen in ipairs(E.DUTY_ORDER) do
		H.reset()
		E.spyDuties()

		local chains = E.stubChainStarts()
		local player = E.pilot({ met = true })

		E.drive(player, "tier4_incomplete", { E.MENU_REPLIES[i] })
		lu.assertEquals(chains, {}, screen .. ": startSpaceQuestChain calls")
		lu.assertEquals(player.bankCredits, 0, screen .. ": bank credits")
		lu.assertEquals(#E.items(player), 0, screen .. ": items")
		E.restore()
	end
end

-- AC-4, I-5: only the four duty screens start a duty (No screen grants the escort duty except duty_escort)
function TestEvinDuties:test_no_other_screen_starts_a_duty()
	for _, row in ipairs(E.SCREENS) do
		if E.DUTY_SCREENS[row.id] == nil then
			H.reset()

			local spies = E.spyDuties()

			E.stubChainStarts()
			E.drive(E.pilot({ met = true, xp = 2 * E.TRAIN_COST }), row.id)
			lu.assertEquals(E.startedDuties(spies), {}, "screen '" .. row.id .. "': duties started")
			E.restore()
		end
	end
end

-- AC-4: the duty screens' lines (J4:3739-3777)
function TestEvinDuties:test_the_duty_screens_show_the_j4_lines_and_greet_by_name_where_the_line_does()
	local want = {
		duty_destroy = { "s_adc84c63", false }, duty_escort = { "s_c28b3318", false }, duty_recovery = { "s_c9329734", true }, duty_rescue = { "s_b83725b", true },
	}

	for screen, w in pairs(want) do
		H.reset()
		E.spyDuties()

		local t = E.drive(E.pilot({ met = true }), screen)

		lu.assertEquals(t[1].text, E.PREFIX .. w[1], screen .. ": the line")
		lu.assertEquals(t[1].params.TU, w[2] and "Ace" or nil, screen .. ": the first name")
	end
end

-- AC-4: really started, a duty runs and the next talk is on_mission
function TestEvinDuties:test_the_duty_screens_start_the_real_duty_and_the_next_talk_is_on_mission()
	for _, screen in ipairs(E.DUTY_ORDER) do
		H.reset()
		E.startAll()

		local global = E.DUTY_SCREENS[screen].global
		local player = E.pilot({ met = true, inShip = true, zone = E.IDENTITY[global].zone })

		E.drive(player, screen)
		H.advance(0)
		lu.assertEquals(E.state(player, global), "active", global .. ": journal entry after " .. screen)
		lu.assertEquals(E.firstScreen(player), "on_mission", screen .. ": the next talk")
	end
end

---------------------------------------------------------------------------------------------
-- The off-track duty offer (C-2)
---------------------------------------------------------------------------------------------

TestEvinOffTrack = {}

TestEvinOffTrack.setUp = setUp
TestEvinOffTrack.tearDown = tearDown

-- AC-4, C-2: a pilot of another Rebel squadron with tier 1 done and no quest is offered the duties
function TestEvinOffTrack:test_s_dab8fd8e_leads_to_the_duty_offer_when_the_pilot_can_fly_a_non_track_duty()
	local t = E.talk(E.pilot({ squadron = "havoc", met = true }))

	lu.assertEquals(E.ids(t), { "off_track" }, "the gate")
	lu.assertEquals(E.optionSids(t[1]), { "s_dab8fd8e" }, "the one reply")
	lu.assertEquals(E.linksOf(t[1]), { "off_track_duties" }, "it leads to the duty offer")

	local walked = E.talk(E.pilot({ squadron = "havoc", met = true }), { "s_dab8fd8e" })

	lu.assertEquals(E.ids(walked), { "off_track", "off_track_duties" }, "the walk")
	lu.assertEquals(walked[2].text, E.PREFIX .. "s_127c7ddc", "'Hm! Well, I do have a few duty missions here. Would you like a briefing?'")
	lu.assertEquals(E.optionSids(walked[2]), { "s_c82e9a2f" }, "'Yes, please.'")
	lu.assertEquals(E.linksOf(walked[2]), { "duty_brief_1" }, "into the duty briefing")
	lu.assertEquals(CS.transcriptUnresolved(walked), {}, "client strings")
end

-- AC-4, D-13: the offer walks the briefing into the menu and starts a duty
function TestEvinOffTrack:test_an_off_track_pilot_can_hear_the_briefing_and_start_a_duty()
	for i, screen in ipairs(E.DUTY_ORDER) do
		H.reset()

		local spies = E.spyDuties()
		local player = E.pilot({ squadron = "havoc" })
		local t = E.talk(player, { "s_dab8fd8e", "s_c82e9a2f", "s_5e2a2bb1", "s_61657d0f", "s_6598178f", E.MENU_REPLIES[i] })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_duties", "duty_brief_1", "duty_brief_2", "duty_brief_3", "duty_brief_4", screen }, "the walk to " .. screen)
		lu.assertEquals(E.startedDuties(spies), { E.DUTY_SCREENS[screen].global .. " x1" }, "duties started")
		lu.assertEquals(E.flag(player), "3", "VORTEX_PILOT_KEY untouched")
		E.restore()
	end
end

-- AC-4, C-2: with any space quest, or without tier 1, the reply leads to off_track_refused, which ends
function TestEvinOffTrack:test_s_dab8fd8e_leads_to_the_refusal_with_any_space_quest_or_without_tier_1()
	local cases = {
		{ "three _01 skills", { squadron = "havoc", t1 = 3 } }, { "no _01 skill", { squadron = "havoc", t1 = 0 } },
		{ "a story mission in the datapad", { squadron = "havoc", otherQuest = "story" } }, { "a duty in the datapad", { squadron = "havoc", otherQuest = "duty" } },
		{ "an Evin duty running", { squadron = "havoc", duty = E.DUTIES[2] } }, { "an Evin mission running", { squadron = "havoc", evinActive = E.M3[1] } },
		{ "no squadron and no tier 1", { squadron = "none", t1 = 2 } },
	}

	for _, case in ipairs(cases) do
		H.reset()

		local spies = E.spyDuties()
		local t = E.talk(E.pilot(case[2]), { "s_dab8fd8e" })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_refused" }, case[1] .. ": the walk")
		lu.assertEquals(E.linksOf(t[1]), { "off_track_refused" }, case[1] .. ": the reply's link")
		lu.assertEquals(t[2].text, E.PREFIX .. "s_942559a7", case[1] .. ": 'Sorry, I can only assign missions to Vortex pilots...'")
		lu.assertTrue(t[2].stop, case[1] .. ": off_track_refused ends")
		lu.assertEquals(E.startedDuties(spies), {}, case[1] .. ": no duty started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		E.restore()
	end
end

-- AC-4: a Vortex pilot is never offered the off-track duties (E5 does not match)
function TestEvinOffTrack:test_a_vortex_pilot_never_sees_the_off_track_screens()
	for _, o in ipairs({ {}, { met = true }, { met = true, t4 = { 1 } }, { met = true, xp = E.TRAIN_COST } }) do
		H.reset()
		lu.assertNotEquals(E.firstScreen(E.pilot(o)), "off_track", "a Vortex pilot")
	end
end
