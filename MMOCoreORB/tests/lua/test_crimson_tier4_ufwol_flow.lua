-- General Ufwol: the first meeting, the duty menus and the four duties, the off-track duty offer (AC-4).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-4; Conversation flow 2 (C-2), 3 (table H) and 5; FF-3, FF-4; D-9, D-13, D-14, D-15; I-5, I-7).
--
-- The met key is set on display of met_258d2f1e (the line after "Yes sir.") and nowhere else. The duty briefing (duty_brief, then the brief_* screens it shares with the met
-- chain) is reached from off_track_duties or from "Can I hear the briefing again?" (s_49805f81) on any of the three duty menus; it sets no key. Each duty reply starts exactly its
-- duty global through startQuest(player, npc) and sets no <playerID>tatooine_rebel_tier4_1:* key (the duties set no key; PA FF-5). The duty globals' startQuest is spied
-- (H.spyOn does not call the original) except in the "real start" test.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier4_data")
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

TestUfwolMeeting = {}

TestUfwolMeeting.setUp = setUp
TestUfwolMeeting.tearDown = tearDown

-- the whole first meeting (Appendix D): intro, the met line, the unit speech, "nerves of steel", the four duties, the duty menu
local MEETING_IDS = {
	"intro", "met_258d2f1e", "met_36085c51", "met_db77876d", "met_917742b8", "met_ab288b4d", "brief_7e962bfb", "brief_73c9f8b3", "brief_ac30ef3", "brief_6231dba",
}

-- AC-4: the whole first meeting is one walk from the intro to the duty menu
function TestUfwolMeeting:test_the_first_meeting_walks_from_the_intro_through_the_roster_to_the_duty_menu()
	E.stubChainStarts()
	E.spyDuties()

	local t = E.talk(E.pilot({}), E.MET_WALK)

	lu.assertEquals(E.ids(t), MEETING_IDS, "the meeting")
	lu.assertEquals(E.optionSids(t[10]), E.MENU_REPLIES, "the duty menu replies")
	lu.assertEquals(E.linksOf(t[10]), E.MENU_LINKS, "the duty menu links")
	lu.assertFalse(t[10].stop, "the duty menu waits for a reply")
	lu.assertEquals(t[10].text, E.PREFIX .. "s_6231dba", "'So? Which mission will you take?'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-4, FF-1: the met key is set on display of met_258d2f1e, by that screen alone, and the next talk does not open the intro
function TestUfwolMeeting:test_intro_then_the_reply_sets_the_met_key_and_the_next_talk_is_not_the_intro()
	local player = E.pilot({})
	local before = statusOf(player)
	local t = E.talk(player, { "s_9b43a7ee" })

	lu.assertEquals(E.ids(t), { "intro", E.MET_SCREEN }, "screens shown")
	lu.assertEquals(t[2].text, E.PREFIX .. "s_258d2f1e", "'You'll be working for me...'")
	lu.assertTrue(E.hasMet(player), "the met key")
	lu.assertEquals(H.getQuestStatus(player, E.MET_KEY), "1", "the met key value")
	lu.assertEquals(statusDiff(player, before, statusOf(player)), { E.MET_KEY }, "the only key written")
	lu.assertEquals(E.flag(player), "3", "EKER_PILOT_KEY untouched")
	lu.assertNotEquals(E.firstScreen(player), "intro", "the next talk")
	lu.assertEquals(E.firstScreen(player), "tier4_incomplete", "no XP, no skill: the duty menu")
end

-- AC-4: leaving the intro without replying sets nothing
function TestUfwolMeeting:test_leaving_the_intro_without_a_reply_sets_nothing()
	local player = E.pilot({})
	local before = E.snapshot(player)

	E.talk(player)
	E.drive(player, "intro")
	lu.assertFalse(E.hasMet(player), "the met key")
	lu.assertEquals(E.snapshot(player).status, before.status, "no key written")
	lu.assertEquals(E.firstScreen(player), "intro", "the next talk is the intro again")
end

-- AC-4: the key is set by display of met_258d2f1e and by no other screen of the meeting
function TestUfwolMeeting:test_no_other_screen_of_the_meeting_sets_the_met_key()
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
	lu.assertTrue(E.hasMet(player), "met_258d2f1e: the met key")
end

-- AC-4: an already met pilot who sees the line again keeps the key and nothing else changes
function TestUfwolMeeting:test_showing_the_met_line_again_changes_nothing_else()
	local player = E.pilot({ met = true })
	local before = E.snapshot(player)

	E.drive(player, E.MET_SCREEN)
	lu.assertEquals(E.snapshot(player).status, before.status, "status keys")
	lu.assertEquals(E.flag(player), "3", "EKER_PILOT_KEY")
end

-- AC-4, I-7: no screen of the whole conversation sets any key other than the met key and the eight head keys; none touches EKER_PILOT_KEY
function TestUfwolMeeting:test_the_first_meeting_never_writes_the_flag_key()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = E.pilot({ flag = flag })

		E.talk(player, E.MET_WALK)
		lu.assertEquals(E.flag(player), flag, "EKER_PILOT_KEY after the meeting with flag " .. flag)
	end
end

---------------------------------------------------------------------------------------------
-- The duty briefing and the duty menus
---------------------------------------------------------------------------------------------

TestUfwolDuties = {}

TestUfwolDuties.setUp = setUp
TestUfwolDuties.tearDown = tearDown

local BRIEFING = { "s_49805f81", "s_61657d0f", "s_2c4789b", "s_bc57b086", "s_8ddbf95b" }
local BRIEFING_IDS = { "duty_brief", "brief_7e962bfb", "brief_73c9f8b3", "brief_ac30ef3", "brief_6231dba" }

-- AC-4, D-15: "Can I hear the briefing again?" on any of the three menus leads to duty_brief and through the shared brief_* chain to the duty menu (no key, no duty)
function TestUfwolDuties:test_the_briefing_again_reply_of_every_menu_walks_the_briefing_screens_and_sets_nothing()
	for _, menu in ipairs(E.MENUS) do
		H.reset()

		local spies = E.spyDuties()
		local player = E.pilot({ met = true, xp = 0 })
		local before = E.snapshot(player)
		local t = E.drive(player, menu, BRIEFING)
		local want = { menu }

		for _, id in ipairs(BRIEFING_IDS) do
			want[#want + 1] = id
		end

		lu.assertEquals(E.ids(t), want, "menu " .. menu .. ": the walk")
		lu.assertEquals(t[2].text, E.PREFIX .. "s_4b3f09bc", "menu " .. menu .. ": the briefing's first line")
		lu.assertEquals(t[3].text, E.PREFIX .. "s_7e962bfb", "menu " .. menu .. ": the Endor escort")
		lu.assertEquals(E.optionSids(t[6]), E.MENU_REPLIES, "menu " .. menu .. ": the briefing ends on the duty menu")
		lu.assertEquals(E.startedDuties(spies), {}, "menu " .. menu .. ": no duty started by the briefing")
		lu.assertEquals(E.snapshot(player).status, before.status, "menu " .. menu .. ": no key written")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		E.restore()
	end
end

-- AC-4: the briefing loops through the briefing-again reply
function TestUfwolDuties:test_the_briefing_loops_through_the_briefing_again_reply()
	local replies = { table.unpack(BRIEFING) }

	replies[#replies + 1] = "s_49805f81"

	local t = E.drive(E.pilot({ met = true }), "brief_6231dba", replies)

	lu.assertEquals(E.ids(t), { "brief_6231dba", "duty_brief", "brief_7e962bfb", "brief_73c9f8b3", "brief_ac30ef3", "brief_6231dba", "duty_brief" }, "the loop")
end

-- AC-4: the four duty replies of every menu start exactly their duty once, end the conversation, and set no tatooine_rebel_tier4_1 key
function TestUfwolDuties:test_each_duty_reply_of_every_menu_starts_exactly_its_duty_once_and_sets_no_key()
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
			lu.assertEquals(t[2].text, E.PREFIX .. "s_a5b93c4d", screen .. ": 'You're cleared for liftoff.'")
			lu.assertEquals(E.startedDuties(spies), { want .. " x1" }, "menu " .. menu .. ", " .. screen .. ": duties started")
			lu.assertEquals(spies[want][1].args[1], player, "startQuest got the pilot")
			lu.assertEquals(E.keysNamed(player, "tatooine_rebel_tier4_1"), {}, screen .. ": no <playerID>tatooine_rebel_tier4_1:* key")
			lu.assertEquals(E.snapshot(player).status, before.status, screen .. ": no key written")
			lu.assertEquals(E.flag(player), "3", screen .. ": EKER_PILOT_KEY untouched")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end
end

-- AC-4, I-5: a duty pays nothing and starts no mission (no head)
function TestUfwolDuties:test_a_duty_starts_no_mission_head_and_pays_nothing()
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

-- AC-4, I-5: only the four duty screens start a duty
function TestUfwolDuties:test_no_other_screen_starts_a_duty()
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

-- AC-4, D-14: the duty screens show "You're cleared for liftoff." (no name token)
function TestUfwolDuties:test_the_duty_screens_show_the_cleared_for_liftoff_line_without_a_name()
	for _, screen in ipairs(E.DUTY_ORDER) do
		H.reset()
		E.spyDuties()

		local t = E.drive(E.pilot({ met = true }), screen)

		lu.assertEquals(t[1].text, E.PREFIX .. "s_a5b93c4d", screen .. ": the line")
		lu.assertNil(t[1].params.TU, screen .. ": no name token")
	end
end

-- AC-4: really started, a duty runs and the next talk is on_mission
function TestUfwolDuties:test_the_duty_screens_start_the_real_duty_and_the_next_talk_is_on_mission()
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

TestUfwolOffTrack = {}

TestUfwolOffTrack.setUp = setUp
TestUfwolOffTrack.tearDown = tearDown

-- AC-4, C-2: a pilot of another Rebel squadron with tier 3 done and no quest is offered the duties
function TestUfwolOffTrack:test_s_d157e1de_leads_to_the_duty_offer_when_the_pilot_can_fly_a_non_track_duty()
	local t = E.talk(E.pilot({ squadron = "havoc", met = true }))

	lu.assertEquals(E.ids(t), { "off_track" }, "the gate")
	lu.assertEquals(E.optionSids(t[1]), { "s_d157e1de" }, "the one reply")
	lu.assertEquals(E.linksOf(t[1]), { "off_track_duties" }, "it leads to the duty offer")

	local walked = E.talk(E.pilot({ squadron = "havoc", met = true }), { "s_d157e1de" })

	lu.assertEquals(E.ids(walked), { "off_track", "off_track_duties" }, "the walk")
	lu.assertEquals(walked[2].text, E.PREFIX .. "s_1338e704", "'I can give you an elective duty task...'")
	lu.assertEquals(E.optionSids(walked[2]), { "s_c82e9a2f" }, "'Yes, please.'")
	lu.assertEquals(E.linksOf(walked[2]), { "duty_brief" }, "into the duty briefing")
	lu.assertEquals(CS.transcriptUnresolved(walked), {}, "client strings")
end

-- AC-4, D-13, D-15: the offer walks the briefing into the menu and starts a duty, without touching the met key
function TestUfwolOffTrack:test_an_off_track_pilot_can_hear_the_briefing_and_start_a_duty()
	for i, screen in ipairs(E.DUTY_ORDER) do
		H.reset()

		local spies = E.spyDuties()
		local player = E.pilot({ squadron = "havoc" })
		local t = E.talk(player, { "s_d157e1de", "s_c82e9a2f", "s_61657d0f", "s_2c4789b", "s_bc57b086", "s_8ddbf95b", E.MENU_REPLIES[i] })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_duties", "duty_brief", "brief_7e962bfb", "brief_73c9f8b3", "brief_ac30ef3", "brief_6231dba", screen }, "the walk to " .. screen)
		lu.assertEquals(E.startedDuties(spies), { E.DUTY_SCREENS[screen].global .. " x1" }, "duties started")
		lu.assertEquals(E.flag(player), "3", "EKER_PILOT_KEY untouched")
		lu.assertFalse(E.hasMet(player), "the met key is not set by the briefing")
		E.restore()
	end
end

-- AC-4, C-2: with any space quest, or without tier 3, the reply leads to off_track_refused, which ends
function TestUfwolOffTrack:test_s_d157e1de_leads_to_the_refusal_with_any_space_quest_or_without_tier_3()
	local cases = {
		{ "three _03 skills", { squadron = "havoc", t3 = 3 } }, { "no _03 skill (only tier 2 complete)", { squadron = "havoc", t3 = 0, missions = 0 } },
		{ "a story mission in the datapad", { squadron = "havoc", otherQuest = "story" } }, { "a duty in the datapad", { squadron = "havoc", otherQuest = "duty" } },
		{ "an Ufwol duty running", { squadron = "havoc", duty = E.DUTIES[2] } }, { "an Ufwol mission running", { squadron = "vortex", ufwolActive = E.M3[1] } },
		{ "no squadron and only tier 2 complete", { squadron = "none", t3 = 0, missions = 0 } },
	}

	for _, case in ipairs(cases) do
		H.reset()

		local spies = E.spyDuties()
		local t = E.talk(E.pilot(case[2]), { "s_d157e1de" })

		lu.assertEquals(E.ids(t), { "off_track", "off_track_refused" }, case[1] .. ": the walk")
		lu.assertEquals(E.linksOf(t[1]), { "off_track_refused" }, case[1] .. ": the reply's link")
		lu.assertEquals(t[2].text, E.PREFIX .. "s_ae002d12", case[1] .. ": 'Only your commanding officer can assign you a mission. Return to your unit.'")
		lu.assertTrue(t[2].stop, case[1] .. ": off_track_refused ends")
		lu.assertEquals(E.startedDuties(spies), {}, case[1] .. ": no duty started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		E.restore()
	end
end

-- AC-4: a Crimson pilot never sees the off-track screens (E4 does not match)
function TestUfwolOffTrack:test_a_crimson_pilot_never_sees_the_off_track_screens()
	for _, o in ipairs({ {}, { met = true }, { met = true, t4 = { 1 } }, { met = true, xp = E.TRAIN_COST } }) do
		H.reset()
		lu.assertNotEquals(E.firstScreen(E.pilot(o)), "off_track", "a Crimson pilot")
	end
end
