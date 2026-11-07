-- Admiral Kilnstrider: the first meeting, the duty briefing and menus, the off-track path and the ready prompt.
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-4, B-5 (ready); Conversation flow 2, 3 and 5; Appendix A; D-8, D-10, D-17).
--
-- The duty globals are spied (H.spyOn does not call the original) except in the tests that start a duty for real in a ship.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

local function key(player, suffix) return H.getQuestStatus(player, suffix) end

local IMPERIAL_SHIP = function() return { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") } end

---------------------------------------------------------------------------------------------
-- The first meeting and the briefing (B-4)
---------------------------------------------------------------------------------------------

TestStormT4Intro = {}

TestStormT4Intro.setUp = setUp

-- B-4, D-8: intro -> "I'd like to do more than talk." -> intro_briefing (sets the met key) -> freighters -> pirates -> the duty menu
function TestStormT4Intro:test_the_first_meeting_walks_through_the_briefing_which_sets_the_met_key()
	local player = D.pilot({})
	local t = D.talk(player, { "s_49425c4b", "s_61657d0f", "s_eef2363b", "s_7b7590d4" })

	lu.assertEquals(D.ids(t), { "intro", "intro_briefing", "duty_freighters", "duty_pirates", "duty_menu" }, "screens shown")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_7f465235", "the intro line")
	lu.assertEquals(t[2].text, D.PREFIX .. "s_3e6a4237", "the briefing line")
	lu.assertEquals(key(player, D.MET_KEY), "1", "the met key")
	lu.assertEquals(D.optionSids(t[5]), D.MENU_REPLIES, "the duty menu replies")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-4, D-8: the met key is set on display of intro_briefing alone; the next talk does not open intro
function TestStormT4Intro:test_displaying_intro_briefing_sets_the_met_key_and_the_next_talk_skips_the_intro()
	local player = D.pilot({})

	lu.assertEquals(D.firstScreen(player), "intro", "before")
	D.drive(player, "intro_briefing")
	lu.assertEquals(key(player, D.MET_KEY), "1", "the met key")
	lu.assertEquals(D.firstScreen(player), "tier4_incomplete", "the next talk of an on-track pilot")
end

-- B-4: nothing else sets the key
function TestStormT4Intro:test_the_other_briefing_screens_and_the_intro_set_no_met_key()
	for _, id in ipairs({ "intro", "duty_briefing", "duty_freighters", "duty_pirates", "duty_menu", "tier4_incomplete", "off_track", "off_track_duties" }) do
		local player = D.pilot({})

		D.drive(player, id)
		lu.assertNil(key(player, D.MET_KEY), id .. ": no met key")
	end
end

-- B-4: the intro is the client line with its one reply
function TestStormT4Intro:test_the_intro_line_is_the_client_line()
	local t = D.talk(D.pilot({}))

	lu.assertEquals(t[1].text, D.PREFIX .. "s_7f465235", "the intro line")
	lu.assertEquals(D.optionSids(t[1]), { "s_49425c4b" }, "the one reply")
	lu.assertEquals(D.linksOf(t[1]), { "intro_briefing" }, "its link")
end

-- B-4, D-8: the met key is a persistent status key under the squadron constant
function TestStormT4Intro:test_the_met_key_is_stored_under_the_squadron_constant_with_the_player_id()
	local player = D.pilot({})

	D.drive(player, "intro_briefing")
	lu.assertEquals(H.getQuestStatus(player, StormSquadronScreenplay.TIER4_MET_KEY), "1", "<playerID> .. TIER4_MET_KEY")
end

---------------------------------------------------------------------------------------------
-- The duty briefing and the menus (B-4)
---------------------------------------------------------------------------------------------

TestStormT4Duties = {}

TestStormT4Duties.setUp = setUp

-- B-4: the briefing screens start nothing
function TestStormT4Duties:test_the_briefing_screens_start_nothing()
	local spies = D.spyStarts()

	for _, id in ipairs({ "intro_briefing", "duty_briefing", "duty_freighters", "duty_pirates", "duty_menu" }) do
		D.drive(D.pilot({ met = true }), id)
	end

	lu.assertEquals(D.started(spies), {}, "no duty started")
end

for _, menu in ipairs(D.MENUS) do
	for _, d in ipairs(D.DUTY_MENU) do
		-- B-4: each of the four duty replies starts exactly its duty once, on the menu screens
		TestStormT4Duties["test_" .. menu .. "_reply_" .. d.screen .. "_starts_exactly_that_duty_once"] = function()
			local spies = D.spyStarts()
			local player = D.pilot({ met = true })
			local t = D.drive(player, menu, { d.reply })

			lu.assertEquals(D.ids(t), { menu, d.screen }, "screens shown")
			lu.assertTrue(t[#t].stop, d.screen .. " ends the conversation")
			lu.assertEquals(D.started(spies), { d.global }, "quests started")
			lu.assertEquals(#spies[d.global], 1, d.global .. ": startQuest calls")
			lu.assertEquals(spies[d.global][1].args[1], player, "the duty starts for the talking pilot")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- B-4: "Can I hear the briefing again?" returns to duty_briefing, which sets no key
	TestStormT4Duties["test_" .. menu .. "_offers_the_briefing_again_without_the_met_key"] = function()
		local spies = D.spyStarts()
		local player = D.pilot({})
		local t = D.drive(player, menu, { D.BRIEFING_AGAIN_REPLY })

		lu.assertEquals(D.ids(t), { menu, "duty_briefing" }, "screens shown")
		lu.assertEquals(D.started(spies), {}, "nothing started")
		lu.assertNil(key(player, D.MET_KEY), "duty_briefing sets no key")
	end

	-- B-4: the menu lists the four duties and the briefing, in order
	TestStormT4Duties["test_" .. menu .. "_lists_the_four_duties_then_the_briefing"] = function()
		local t = D.drive(D.pilot({ met = true }), menu)

		lu.assertEquals(D.optionSids(t[1]), D.MENU_REPLIES, "menu replies")
		lu.assertEquals(D.linksOf(t[1]), D.MENU_LINKS, "menu links")
	end
end

-- B-4: the briefing loop (duty_briefing -> freighters -> pirates -> duty_menu) starts nothing and sets no key
function TestStormT4Duties:test_the_briefing_again_loop_returns_to_the_duty_menu_without_a_key()
	local spies = D.spyStarts()
	local player = D.pilot({})
	local t = D.drive(player, "tier4_incomplete", { D.BRIEFING_AGAIN_REPLY, "s_61657d0f", "s_eef2363b", "s_7b7590d4" })

	lu.assertEquals(D.ids(t), { "tier4_incomplete", "duty_briefing", "duty_freighters", "duty_pirates", "duty_menu" }, "screens shown")
	lu.assertEquals(D.started(spies), {}, "nothing started")
	lu.assertNil(key(player, D.MET_KEY), "no met key")
end

-- B-4: the duty screens start the duty on display and nothing else
function TestStormT4Duties:test_a_duty_screen_displayed_alone_starts_only_its_own_duty()
	for _, d in ipairs(D.DUTY_MENU) do
		local spies = D.spyStarts()

		D.drive(D.pilot({ met = true }), d.screen)
		lu.assertEquals(D.started(spies), { d.global }, d.screen .. ": quests started")
		H.reset()
	end
end

-- B-4: the duties start for real (the duty types' own rules apply)
function TestStormT4Duties:test_a_duty_chosen_in_a_ship_really_starts()
	for _, d in ipairs(D.DUTY_MENU) do
		H.reset()

		local q = D.quest(d.global)
		local player = D.pilot({ met = true, inShip = IMPERIAL_SHIP(), zone = q.questZone })

		D.drive(player, "here_for_work", { d.reply })
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), d.global .. ": active in the journal")
	end
end

-- B-4, D-17: a running duty makes the pilot "on a mission"
function TestStormT4Duties:test_a_running_duty_opens_on_mission_on_the_next_talk()
	local player = D.pilot({ met = true, inShip = IMPERIAL_SHIP(), zone = "space_endor" })

	D.drive(player, "tier4_incomplete", { D.DUTY_MENU[1].reply })
	lu.assertEquals(D.firstScreen(player), "on_mission", "the next talk")
end

-- B-4, D-10: a duty screen raises a pilot still at tier 3 (four _03 skills) to tier 4
function TestStormT4Duties:test_a_duty_screen_raises_the_pilot_tier_3_to_4()
	D.spyStarts()

	local player = D.pilot({ met = true, pilotTier = 3 })

	D.drive(player, "duty_destroy")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the duty screen")
end

---------------------------------------------------------------------------------------------
-- The off-track path (B-4, C-2)
---------------------------------------------------------------------------------------------

TestStormT4OffTrack = {}

TestStormT4OffTrack.setUp = setUp

-- B-4, C-2: with the four _03 skills, no mission and no datapad quest the reply leads to the duties
function TestStormT4OffTrack:test_an_off_track_pilot_who_can_fly_non_track_duties_is_offered_them()
	local t = D.talk(D.pilot({ squadron = "black_epsilon" }), { "s_4854758d" })

	lu.assertEquals(D.ids(t), { "off_track", "off_track_duties" }, "screens shown")
	lu.assertEquals(t[2].text, D.PREFIX .. "s_7247f243", "the duties line")
	lu.assertEquals(D.optionSids(t[1]), { "s_4854758d" }, "the one reply")
	lu.assertEquals(D.linksOf(t[1]), { "off_track_duties" }, "the link built for this pilot")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- B-4, C-2: any space quest, a running chain or a missing _03 skill leads to the refusal
function TestStormT4OffTrack:test_an_off_track_pilot_who_cannot_fly_duties_gets_the_refusal()
	local cases = {
		{ "a datapad duty", { squadron = "black_epsilon", datapad = "duty" } },
		{ "a datapad story mission", { squadron = "inquisition", datapad = "story" } },
		{ "three _03 skills", { squadron = "black_epsilon", t3 = { 1, 2, 3 } } },
		{ "a running Kilnstrider chain", { squadron = "black_epsilon", mission = { [3] = "active" } } },
		{ "a running duty", { squadron = "inquisition", duty = D.DUTIES[1] } },
		{ "no _03 skill at all", { squadron = false, t3 = {} } },
	}

	for _, c in ipairs(cases) do
		local t = D.talk(D.pilot(c[2]), { "s_4854758d" })

		lu.assertEquals(D.ids(t), { "off_track", "off_track_refused" }, c[1] .. ": screens shown")
		lu.assertEquals(t[2].text, D.PREFIX .. "s_e542a06b", c[1] .. ": the refusal line")
		lu.assertTrue(t[2].stop, c[1] .. ": the refusal ends the conversation")
	end
end

-- B-4, FK-5: a grounded off-track Imperial still gets the duty offer (SWG behaviour: the duties pay only credits)
function TestStormT4OffTrack:test_a_grounded_off_track_pilot_is_still_offered_the_duties()
	local t = D.talk(D.pilot({ squadron = "black_epsilon", standing = -2 }), { "s_4854758d" })

	lu.assertEquals(D.ids(t), { "off_track", "off_track_duties" }, "screens shown")
end

-- B-4: the off-track duties lead to duty_briefing, which sets no met key, then to the duty menu
function TestStormT4OffTrack:test_the_off_track_duties_lead_to_the_duty_briefing_and_the_menu_without_the_met_key()
	local player = D.pilot({ squadron = "black_epsilon" })
	local t = D.talk(player, { "s_4854758d", "s_8a4f7617", "s_61657d0f", "s_eef2363b", "s_7b7590d4", "s_cec1f447" })

	lu.assertEquals(D.ids(t), { "off_track", "off_track_duties", "duty_briefing", "duty_freighters", "duty_pirates", "duty_menu", "duty_destroy" }, "screens shown")
	lu.assertNil(key(player, D.MET_KEY), "no met key for an off-track pilot")
end

-- B-4: the off-track pilot's duty start is the same global
function TestStormT4OffTrack:test_an_off_track_pilot_starts_the_destroy_duty_through_the_menu()
	local spies = D.spyStarts()

	D.talk(D.pilot({ squadron = "inquisition" }), { "s_4854758d", "s_8a4f7617", "s_61657d0f", "s_eef2363b", "s_7b7590d4", "s_cec1f447" })
	lu.assertEquals(D.started(spies), { D.DUTIES[1] }, "quests started")
end

---------------------------------------------------------------------------------------------
-- The ready prompt (B-5, C-3)
---------------------------------------------------------------------------------------------

TestStormT4Ready = {}

TestStormT4Ready.setUp = setUp

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

	return D.pilot(o)
end

-- B-5, C-3: the ready prompt has one reply, leading to the brief of the ready mission
function TestStormT4Ready:test_the_ready_prompt_leads_to_the_brief_of_the_ready_mission()
	for n = 1, 4 do
		local t = D.talk(readyFor(n), { "s_52917b0d" })

		lu.assertEquals(D.ids(t), { "ready", "m" .. n .. "_brief" }, "mission " .. n .. ": screens shown")
		lu.assertEquals(t[1].text, D.PREFIX .. "s_53773f7e", "the ready line")
		lu.assertEquals(t[1].params.TU, "Ace", "the ready line greets the pilot by first name")
		lu.assertEquals(D.optionSids(t[1]), { "s_52917b0d" }, "mission " .. n .. ": the one reply")
		lu.assertEquals(D.linksOf(t[1]), { "m" .. n .. "_brief" }, "mission " .. n .. ": the link built for this pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- B-5: the ready prompt and the brief start nothing
function TestStormT4Ready:test_the_ready_prompt_and_the_briefs_start_nothing()
	local spies = D.spyStarts()

	for n = 1, 4 do
		local player = readyFor(n)

		D.talk(player, { "s_52917b0d" })
		lu.assertNil(H.getQuestStatus(player, D.MISSIONS[n].status .. ":attempted"), "mission " .. n .. ": no attempted key before an accept")
	end

	lu.assertEquals(D.started(spies), {}, "quests started")
end

-- B-5: the head screens are the client lines J keeps (and the twin of the M2 head after training)
function TestStormT4Ready:test_the_four_heads_show_the_client_lines()
	local sids = { m1_brief = "s_f10afb8", m2_brief = "s_4aef73fb", m3_brief = "s_66bd8046", m4_brief = "s_fee3d28f" }

	for id, sid in pairs(sids) do
		local t = D.drive(D.pilot({ met = true }), id)

		lu.assertEquals(t[1].text, D.PREFIX .. sid, id .. ": the head line")
		lu.assertFalse(t[1].stop, id .. " waits for a reply")
	end
end
