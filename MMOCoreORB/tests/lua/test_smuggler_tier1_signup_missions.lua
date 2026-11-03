-- Dravis: sign-up (all three openings, the "I got a ship." branch of Q1 = A), the starter ship, the mission offers, accepts, retries and the duty hand-outs.
-- Spec: .claude/work/smuggler-tier1-dravis/01-spec.md (AC-5, AC-7; Conversation flow 2 (C-2, C-4), 3 (table H) and 4; Appendix A; Q1 = A; D-5, D-6).
--
-- Every walk is a list of reply sids (the client lines). The screens shown come from the Appendix A graph (smuggler_tier1_screens_data.lua) unless a
-- conditional link (C-n) decides, in which case the walk lists its ids. Mission starts are observed with spies on the quest tables' startQuest
-- (H.spyOn does not call the original); the real start of each head is run separately with the pilot in a ship.

local lu = require("luaunit")
local H = require("harness")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")

S.load()

local function setUp()
	H.reset()
	S.requireConversation(lu)
end

local function spyAll(globals)
	local spies = {}

	for _, g in ipairs(globals) do
		spies[g] = H.spyOn(S.quest(g), "startQuest")
	end

	return spies
end

local function started(spies)
	local out = {}

	for g, calls in pairs(spies) do
		for _ = 1, #calls do
			out[#out + 1] = g
		end
	end

	table.sort(out)
	return out
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
end

-- Runs a walk: the screens shown, the quests started, the client strings of the transcript
local function walk(w)
	local spies = spyAll(S.GLOBALS)
	local player = S.pilot(w.pilot)
	local t = S.talk(player, w.choices)

	lu.assertEquals(S.ids(t), w.ids, w.name .. ": screens shown")
	lu.assertEquals(started(spies), w.starts or {}, w.name .. ": quests started")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings of the transcript (AC-5)")

	return t, player
end

local function novice(player)
	for _, call in ipairs(S.free()) do
		if call[1] == player and call[2] == S.NOVICE then
			return true
		end
	end

	return false
end

-- exactly one grantStarterShip(player, "neutral")
local function assertOneShip(player)
	local calls = H.Engine.callsTo("grantStarterShip")

	lu.assertEquals(#calls, 1, "grantStarterShip calls")
	lu.assertTrue(calls[1][1] == player and calls[1][2] == "neutral", "the starter ship is a neutral one for the pilot")
end

local NON_PILOT = { pilot = false, squadron = false, pilotTier = 0 }
local NON_PILOT_NO_SHIP = { pilot = false, squadron = false, pilotTier = 0, ship = false }

-- the opening replies of the three routes, and the common tail up to the deal
local KID = { "s_900f01d1", "s_b1f10b5" }          -- recruitment -> recruit_kid -> recruit_shuttle
local SHUTTLE = { "s_2b595da6" }                    -- recruitment -> recruit_shuttle
local TO_ACADEMY = { "s_2e5f3688", "s_b26194cb", "s_e81a1436" } -- recruit_shuttle -> what_want -> minding -> academy
local FRIEND_MAYBE = { "s_2b691aa0", "s_681e480d" }  -- recruitment -> recruit_friend -> recruit_maybe
local FRIEND_DEPENDS = { "s_2b691aa0", "s_c6f8e9e9", "s_940e1e78", "s_6d273b75" } -- friend -> depends -> skills -> work_something
local TO_COST = { "s_381dd7dd" }                    -- recruit_work_something -> recruit_cost
local DEAL = { "s_ebe2e111" }                       -- recruit_cost -> recruit_signed

local KID_WALK = concat(KID, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }, TO_COST, DEAL)
local SHUTTLE_WALK = concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }, TO_COST, DEAL)
local FRIEND_WALK = concat(FRIEND_MAYBE, { "s_6d273b75" }, TO_COST, DEAL)
local FRIEND_DEPENDS_WALK = concat(FRIEND_DEPENDS, TO_COST, DEAL)

---------------------------------------------------------------------------------------------
-- AC-7: sign-up
---------------------------------------------------------------------------------------------

TestSmugglerT1SignUp = {}

TestSmugglerT1SignUp.setUp = setUp

-- AC-7: the kid opening, with a ship, to the first mission
function TestSmugglerT1SignUp:test_a_non_pilot_with_a_ship_signs_up_through_the_kid_opening_and_starts_mission_1()
	local player = S.pilot(NON_PILOT)
	local spies = spyAll(S.GLOBALS)
	local t = S.talk(player, concat(KID_WALK, { "s_eb2cfdac" }))

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_kid", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_no_empire", "recruit_work_something",
		"recruit_cost", "recruit_signed", "mission1_brief" }, "screens shown")
	lu.assertTrue(novice(player), "the novice box pilot_neutral_novice was granted free (awardSkill)")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron type")
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier raised from 0 to 1")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no starter ship: the pilot has one")
	lu.assertEquals(started(spies), { S.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_privateer_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the sign-up transcript")
end

-- AC-7: the shuttle opening
function TestSmugglerT1SignUp:test_the_shuttle_opening_signs_up_the_same_way()
	local player = S.pilot(NON_PILOT)
	local t = S.talk(player, SHUTTLE_WALK)

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_no_empire", "recruit_work_something", "recruit_cost", "recruit_signed" },
		"screens shown")
	lu.assertTrue(novice(player), "the novice box was granted")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron type")
end

-- AC-7: the friend opening, both ways to the deal
function TestSmugglerT1SignUp:test_the_friend_opening_reaches_the_deal_through_maybe_or_depends()
	local a = S.pilot(NON_PILOT)
	local ta = S.talk(a, FRIEND_WALK)

	lu.assertEquals(S.ids(ta), { "recruitment", "recruit_friend", "recruit_maybe", "recruit_work_something", "recruit_cost", "recruit_signed" }, "via recruit_maybe")
	lu.assertTrue(novice(a), "the box is granted (maybe)")

	H.reset()

	local b = S.pilot(NON_PILOT)
	local tb = S.talk(b, FRIEND_DEPENDS_WALK)

	lu.assertEquals(S.ids(tb), { "recruitment", "recruit_friend", "recruit_depends", "recruit_skills", "recruit_work_something", "recruit_cost", "recruit_signed" }, "via recruit_depends")
	lu.assertTrue(novice(b), "the box is granted (depends)")
	lu.assertEquals(CS.transcriptUnresolved(tb), {}, "client strings")
end

-- AC-7: the hasty branch and both ways through the Karrde pitch
local ROUTES = {
	{ name = "hasty", pre = concat(SHUTTLE, TO_ACADEMY, { "s_80094dc8", "s_40a69ad7", "s_6e03f969" }), tail = TO_COST, deal = DEAL,
		ids = { "recruitment", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_great_idea", "recruit_hasty", "recruit_work_something", "recruit_cost", "recruit_signed" } },
	{ name = "karrde_alliance", pre = concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }), tail = TO_COST, deal = { "s_dc9e436d", "s_9f8c06d0", "s_e84d85e2" },
		ids = { "recruitment", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_no_empire", "recruit_work_something", "recruit_cost", "recruit_karrde", "recruit_alliance", "recruit_signed" } },
	{ name = "karrde_all_types", pre = concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }), tail = TO_COST, deal = { "s_dc9e436d", "s_9f8c06d0", "s_2d1e63d0", "s_429872ac" },
		ids = { "recruitment", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_no_empire", "recruit_work_something", "recruit_cost", "recruit_karrde", "recruit_alliance", "recruit_all_types", "recruit_signed" } },
}

for _, r in ipairs(ROUTES) do
	-- AC-7
	TestSmugglerT1SignUp["test_the_" .. r.name .. "_route_ends_in_the_sign_up"] = function()
		local player = S.pilot(NON_PILOT)
		local t = S.talk(player, concat(r.pre, r.tail, r.deal))

		lu.assertEquals(S.ids(t), r.ids, "screens shown")
		lu.assertTrue(novice(player), "the box is granted")
		lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron type")
		lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: no grant before recruit_signed
function TestSmugglerT1SignUp:test_nothing_is_granted_before_the_signed_screen()
	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(KID, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }, TO_COST))
	lu.assertFalse(novice(player), "no novice box before recruit_signed")
	lu.assertEquals(player.ghost.squadronType, 0, "no squadron before recruit_signed")
	lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
end

-- AC-7: every non-sign-up ending grants nothing
local REFUSALS = {
	{ name = "forget_it", choices = concat(SHUTTLE, { "s_2e5f3688", "s_cdcb429b" }), last = "recruit_forget" },
	{ name = "appreciate", choices = concat(SHUTTLE, TO_ACADEMY, { "s_80094dc8", "s_cd0dcead" }), last = "recruit_appreciate" },
	{ name = "rue", choices = concat(SHUTTLE, TO_ACADEMY, { "s_80094dc8", "s_40a69ad7", "s_cf4d3521" }), last = "recruit_rue" },
	{ name = "refused_at_the_deal", choices = concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }, TO_COST, { "s_9dcdd171" }), last = "recruit_refused" },
	{ name = "refused_after_all_types", choices = concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }, TO_COST, { "s_dc9e436d", "s_9f8c06d0", "s_2d1e63d0", "s_ca932c28" }), last = "recruit_refused" },
}

for _, r in ipairs(REFUSALS) do
	-- AC-7
	TestSmugglerT1SignUp["test_the_" .. r.name .. "_ending_grants_nothing"] = function()
		local player = S.pilot(NON_PILOT)
		local spies = spyAll(S.GLOBALS)
		local t = S.talk(player, r.choices)

		lu.assertEquals(t[#t].id, r.last, "last screen")
		lu.assertTrue(t[#t].stop, r.last .. " ends the conversation")
		lu.assertFalse(novice(player), "no novice box")
		lu.assertEquals(#S.free() + #S.bought(), 0, "no skill")
		lu.assertEquals(player.ghost.squadronType, 0, "no squadron")
		lu.assertEquals(player.ghost.pilotTier, 0, "pilot tier")
		lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship")
		lu.assertEquals(started(spies), {}, "no quest started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

---------------------------------------------------------------------------------------------
-- C-2 and the ship
---------------------------------------------------------------------------------------------

TestSmugglerT1Ship = {}

TestSmugglerT1Ship.setUp = setUp

-- AC-7 (C-2): with a ship the pilot is offered "You bet." and "I'd rather take care of some things, first."
function TestSmugglerT1Ship:test_with_a_ship_the_signed_screen_offers_the_mission_and_the_later_reply()
	local t = S.talk(S.pilot(NON_PILOT), KID_WALK)

	lu.assertEquals(t[#t].id, "recruit_signed", "last screen")
	lu.assertEquals(S.optionSids(t[#t]), { "s_eb2cfdac", "s_8d95c731" }, "replies of recruit_signed with a ship")
	lu.assertEquals(S.linksOf(t[#t]), { "mission1_brief", "recruit_later" }, "links of recruit_signed with a ship")
end

-- AC-7 (C-2): the later reply ends the talk with the pilot signed up and no mission started
function TestSmugglerT1Ship:test_the_later_reply_ends_the_conversation_with_no_mission_started()
	local player = S.pilot(NON_PILOT)
	local spies = spyAll(S.GLOBALS)
	local t = S.talk(player, concat(KID_WALK, { "s_8d95c731" }))

	lu.assertEquals(t[#t].id, "recruit_later", "last screen")
	lu.assertTrue(t[#t].stop, "recruit_later ends the conversation")
	lu.assertEquals(started(spies), {}, "no mission started")
	lu.assertNil(H.getQuestStatus(player, "tatooine_privateer_1:attempted"), "no :attempted key")
	lu.assertTrue(novice(player), "but the sign-up happened")
end

-- AC-7 (C-2): without a ship the pilot sees only "Er... I don't have a ship."
function TestSmugglerT1Ship:test_without_a_ship_the_signed_screen_offers_only_the_no_ship_reply()
	local t = S.talk(S.pilot(NON_PILOT_NO_SHIP), KID_WALK)

	lu.assertEquals(t[#t].id, "recruit_signed", "last screen")
	lu.assertEquals(S.optionSids(t[#t]), { "s_fc0b7ade" }, "replies of recruit_signed without a ship")
	lu.assertEquals(S.linksOf(t[#t]), { "recruit_no_ship" }, "links of recruit_signed without a ship")
end

-- AC-7: the loan: exactly one neutral starter ship, then mission 1
function TestSmugglerT1Ship:test_the_loan_grants_exactly_one_neutral_starter_ship_and_leads_to_mission_1()
	local player = S.pilot(NON_PILOT_NO_SHIP)
	local spies = spyAll(S.GLOBALS)
	local t = S.talk(player, concat(KID_WALK, { "s_fc0b7ade", "s_a0b4565", "s_1adbadc4" }))

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_kid", "recruit_shuttle", "recruit_what_want", "recruit_minding", "recruit_academy", "recruit_no_empire", "recruit_work_something",
		"recruit_cost", "recruit_signed", "recruit_no_ship", "recruit_loan_ship", "mission1_brief" }, "screens shown")
	assertOneShip(player)
	lu.assertEquals(started(spies), { S.P1 }, "mission 1 started once")
	lu.assertEquals(H.getQuestStatus(player, "tatooine_privateer_1:attempted"), "1", "mission 1 :attempted")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the loan, then "make your preparations": the ship is granted, the mission is not started
function TestSmugglerT1Ship:test_the_loan_without_taking_the_mission_ends_in_recruit_trouble()
	local player = S.pilot(NON_PILOT_NO_SHIP)
	local spies = spyAll(S.GLOBALS)
	local t = S.talk(player, concat(KID_WALK, { "s_fc0b7ade", "s_a0b4565", "s_8d95c731" }))

	lu.assertEquals(t[#t].id, "recruit_trouble", "last screen")
	lu.assertTrue(t[#t].stop, "recruit_trouble ends the conversation")
	assertOneShip(player)
	lu.assertEquals(started(spies), {}, "no mission started")
end

-- AC-7: "Will do." takes no ship; the next talk opens lost_ship, which grants one
function TestSmugglerT1Ship:test_getting_ones_own_ship_ends_the_talk_and_the_next_talk_grants_the_loan_at_lost_ship()
	local player = S.pilot(NON_PILOT_NO_SHIP)
	local t = S.talk(player, concat(KID_WALK, { "s_fc0b7ade", "s_d24a2285" }))

	lu.assertEquals(t[#t].id, "recruit_get_ship", "last screen")
	lu.assertTrue(t[#t].stop, "recruit_get_ship ends the conversation")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "no ship yet")

	player.pilot = "neutral" -- the server derives the pilot kind from the skills just granted

	local again = S.talk(player)

	lu.assertEquals(S.ids(again), { "lost_ship" }, "the next talk")
	lu.assertTrue(again[1].stop, "lost_ship ends the conversation")
	assertOneShip(player)
end

-- AC-7: lost_ship grants one ship on display, whatever the squadron history
function TestSmugglerT1Ship:test_lost_ship_grants_one_neutral_starter_ship_per_display_only_while_the_pilot_has_none()
	local player = S.pilot({ ship = false })

	S.talk(player)
	assertOneShip(player)

	H.reset()

	local flying = S.pilot({})

	S.drive(flying, "lost_ship")
	lu.assertEquals(#H.Engine.callsTo("grantStarterShip"), 0, "a pilot who has a certified ship gets none")
end

---------------------------------------------------------------------------------------------
-- Q1 = A: "I got a ship."
---------------------------------------------------------------------------------------------

TestSmugglerT1MetDravis = {}

TestSmugglerT1MetDravis.setUp = setUp

local ONE_SHIP = "s_2268b9e0" -- "I got a ship."

-- Q1 (C-4)
function TestSmugglerT1MetDravis:test_a_stranger_is_offered_the_three_openings_only()
	local t = S.talk(S.pilot(NON_PILOT))

	lu.assertEquals(S.optionSids(t[1]), { "s_900f01d1", "s_2b595da6", "s_2b691aa0" }, "replies of recruitment")
end

-- Q1 (D-6): the flag is set when Dravis has told the recruit about the ship, and not before
function TestSmugglerT1MetDravis:test_reaching_work_something_sets_the_met_key_in_server_memory()
	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(KID, TO_ACADEMY, { "s_4ff172ab" }))
	lu.assertFalse(S.met(player), "not set before recruit_work_something")

	H.reset()

	local p2 = S.pilot(NON_PILOT)

	S.talk(p2, concat(KID, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))
	lu.assertTrue(S.met(p2), "set on recruit_work_something")
	lu.assertEquals(readData(p2.objectID .. S.MET_DRAVIS_KEY), 1, "the value written is 1")
	lu.assertNil(H.getQuestStatus(p2, S.MET_DRAVIS_KEY), "server memory, not a persisted quest status")
end

-- Q1 (C-4): the returning recruit is offered "I got a ship." as the fourth reply
function TestSmugglerT1MetDravis:test_a_returning_recruit_is_offered_i_got_a_ship_as_the_fourth_reply()
	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))

	local t = S.talk(player)

	lu.assertEquals(t[1].id, "recruitment", "first screen")
	lu.assertEquals(S.optionSids(t[1]), { "s_900f01d1", "s_2b595da6", "s_2b691aa0", ONE_SHIP }, "replies of recruitment for a recruit who met Dravis")
	lu.assertEquals(S.linksOf(t[1])[4], "recruit_got_ship", "the fourth reply leads to recruit_got_ship")
end

-- Q1: the flag belongs to one player
function TestSmugglerT1MetDravis:test_the_met_key_is_per_player()
	local a, b = S.pilot(NON_PILOT), S.pilot(NON_PILOT)

	S.talk(a, concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))
	lu.assertEquals(#S.talk(b)[1].options, 3, "another recruit still sees three replies")
end

-- Q1: yes
function TestSmugglerT1MetDravis:test_i_got_a_ship_then_yes_i_am_signs_the_recruit_up()
	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))

	local t = S.talk(player, { ONE_SHIP, "s_d335136f" })

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_got_ship", "recruit_signed" }, "screens shown")
	lu.assertEquals(S.optionSids(t[2]), { "s_dc9e436d", "s_d335136f", "s_4440ce87" }, "replies of recruit_got_ship")
	lu.assertTrue(novice(player), "the novice box was granted")
	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "squadron type")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- Q1: "What do you do?" rejoins the Karrde pitch
function TestSmugglerT1MetDravis:test_what_do_you_do_after_i_got_a_ship_leads_to_the_karrde_pitch()
	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))

	local t = S.talk(player, { ONE_SHIP, "s_dc9e436d", "s_9f8c06d0", "s_e84d85e2" })

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_got_ship", "recruit_karrde", "recruit_alliance", "recruit_signed" }, "screens shown")
end

-- Q1: changed my mind
function TestSmugglerT1MetDravis:test_i_got_a_ship_then_changed_my_mind_ends_with_nothing_granted()
	local player = S.pilot(NON_PILOT)
	local spies = spyAll(S.GLOBALS)

	S.talk(player, concat(SHUTTLE, TO_ACADEMY, { "s_4ff172ab", "s_6e03f969" }))

	local t = S.talk(player, { ONE_SHIP, "s_4440ce87" })

	lu.assertEquals(S.ids(t), { "recruitment", "recruit_got_ship", "recruit_go_away" }, "screens shown")
	lu.assertTrue(t[3].stop, "recruit_go_away ends the conversation")
	lu.assertFalse(novice(player), "no novice box")
	lu.assertEquals(player.ghost.squadronType, 0, "no squadron")
	lu.assertEquals(started(spies), {}, "no quest started")
end

-- Q1: the key does not leak into the member gates
function TestSmugglerT1MetDravis:test_the_met_key_changes_nothing_for_a_signed_up_pilot()
	lu.assertEquals(S.firstScreen(S.pilot({ met = true })), "mission1_offer", "a Smuggler with the key set")
end

---------------------------------------------------------------------------------------------
-- Every static link of Appendix A, one step
---------------------------------------------------------------------------------------------

TestSmugglerT1Edges = {}

TestSmugglerT1Edges.setUp = setUp

-- Rows whose links the handler replaces or builds (C-1, C-2, C-3 and the training menus); their results are tested where they are decided.
local HANDLER_ROWS = { non_member = true, recruit_signed = true, mission1_reward = true, mission2_reward = true, mission3_reward = true, mission4_reward = true,
	first_training = true, more_training = true }

-- AC-5, I-8: from every screen, each static reply leads to the screen of its row
function TestSmugglerT1Edges:test_every_static_reply_of_appendix_a_leads_to_its_linked_screen()
	local checked = 0

	for _, row in ipairs(S.SCREENS) do
		if not HANDLER_ROWS[row.id] then
			for _, o in ipairs(row.options) do
				H.reset()
				spyAll(S.GLOBALS)

				local player = S.pilot({ paid = 4, tier = 2 })
				local t = S.drive(player, row.id, { o[1] })

				lu.assertEquals(S.ids(t), { row.id, o[2] }, "screen '" .. row.id .. "', reply " .. o[1])
				lu.assertEquals(CS.transcriptUnresolved(t), {}, "screen '" .. row.id .. "', reply " .. o[1] .. ": client strings (AC-5)")
				checked = checked + 1
			end
		end
	end

	lu.assertTrue(checked >= 80, "static replies walked: " .. checked)
end

---------------------------------------------------------------------------------------------
-- Missions: starts, retries, offers
---------------------------------------------------------------------------------------------

TestSmugglerT1Missions = {}

TestSmugglerT1Missions.setUp = setUp

-- H table: screen -> mission number and head
local STARTS = {
	{ screen = "mission1_brief", n = 1, head = "patrol_tatooine_privateer_1" },
	{ screen = "mission1_accept", n = 1, head = "patrol_tatooine_privateer_1" },
	{ screen = "mission1_retry", n = 1, head = "patrol_tatooine_privateer_1" },
	{ screen = "mission2_accept", n = 2, head = "destroy_tatooine_privateer_2" },
	{ screen = "mission2_retry", n = 2, head = "destroy_tatooine_privateer_2" },
	{ screen = "mission3_accept", n = 3, head = "patrol_tatooine_privateer_3" },
	{ screen = "mission3_retry", n = 3, head = "patrol_tatooine_privateer_3" },
	{ screen = "mission4_accept", n = 4, head = "assassinate_tatooine_privateer_tier1_4a" },
	{ screen = "mission4_retry", n = 4, head = "assassinate_tatooine_privateer_tier1_4a" },
}

for _, st in ipairs(STARTS) do
	-- AC-7: every start screen sets :attempted and starts its chain head
	TestSmugglerT1Missions["test_" .. st.screen .. "_marks_mission_" .. st.n .. "_attempted_and_starts_its_head"] = function()
		local spies = spyAll(S.GLOBALS)
		local player = S.pilot({ paid = st.n - 1 })
		local t = S.drive(player, st.screen)

		lu.assertEquals(S.ids(t), { st.screen }, "screens shown")
		lu.assertTrue(t[1].stop, st.screen .. " ends the conversation")
		lu.assertEquals(started(spies), { st.head }, "quests started")
		lu.assertEquals(H.getQuestStatus(player, S.STATUS_NAMES[st.n] .. ":attempted"), "1", "mission " .. st.n .. " :attempted")

		for other = st.n + 1, 4 do
			lu.assertNil(H.getQuestStatus(player, S.STATUS_NAMES[other] .. ":attempted"), "mission " .. other .. " :attempted stays unset")
		end
	end
end

-- AC-7: a pilot with mission N failed opens missionN_retry, which restarts mission N (D-5)
for n = 1, 4 do
	TestSmugglerT1Missions["test_a_pilot_with_mission_" .. n .. "_failed_opens_the_retry_and_restarts_it"] = function()
		local spies = spyAll(S.GLOBALS)
		local player = S.pilot({ paid = n - 1, state = "failed" })
		local t = S.talk(player)

		lu.assertEquals(S.ids(t), { "mission" .. n .. "_retry" }, "screens shown")
		lu.assertEquals(started(spies), { S.HEADS[n] }, "mission " .. n .. " restarted once")
		lu.assertEquals(H.getQuestStatus(player, S.STATUS_NAMES[n] .. ":attempted"), "1", ":attempted stays set")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the fresh offer of mission 1 starts nothing
function TestSmugglerT1Missions:test_the_mission_1_offer_starts_nothing_and_marks_nothing()
	local spies = spyAll(S.GLOBALS)
	local player = S.pilot({})
	local t = S.talk(player)

	lu.assertEquals(S.ids(t), { "mission1_offer" }, "screens shown")
	lu.assertEquals(started(spies), {}, "no quest started by the offer")
	lu.assertNil(H.getQuestStatus(player, "tatooine_privateer_1:attempted"), "no :attempted key by the offer")
end

-- AC-7: the offer then the accept
local OFFERS = {
	{ n = 1, reply = "s_9237617f", offer = "mission1_offer", accept = "mission1_accept" },
	{ n = 2, reply = "s_9237617f", offer = "mission2_offer", accept = "mission2_accept" },
	{ n = 3, reply = "s_9237617f", offer = "mission3_offer", accept = "mission3_accept" },
	{ n = 4, reply = "s_fc963b1e", offer = "mission4_offer", accept = "mission4_accept" },
}

for _, o in ipairs(OFFERS) do
	TestSmugglerT1Missions["test_the_mission_" .. o.n .. "_offer_leads_to_the_accept_which_starts_the_mission"] = function()
		local spies = spyAll(S.GLOBALS)
		local player = S.pilot({ paid = o.n - 1 })
		local t = S.talk(player, { o.reply })

		lu.assertEquals(S.ids(t), { o.offer, o.accept }, "screens shown")
		lu.assertEquals(started(spies), { S.HEADS[o.n] }, "mission " .. o.n .. " started once")
		lu.assertEquals(H.getQuestStatus(player, S.STATUS_NAMES[o.n] .. ":attempted"), "1", ":attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: each head really starts for a pilot in a ship in the zone
function TestSmugglerT1Missions:test_every_head_really_starts_for_a_pilot_in_a_ship_in_space_tatooine()
	for n = 1, 4 do
		H.reset()

		local head = S.quest(S.HEADS[n])

		head:start()

		local player = S.pilot({ paid = n - 1, zone = "space_tatooine", inShip = true })

		S.drive(player, ({ "mission1_accept", "mission2_accept", "mission3_accept", "mission4_accept" })[n])
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, head.questType, head.questName), S.HEADS[n] .. ": active after the accept screen")
	end
end

---------------------------------------------------------------------------------------------
-- Duties
---------------------------------------------------------------------------------------------

TestSmugglerT1Duties = {}

TestSmugglerT1Duties.setUp = setUp

local DUTY_MENU = {
	{ reply = "s_695b8483", screen = "destroy_duty", duty = "destroy_duty_tatooine_privateer_6" },
	{ reply = "s_61b6e28a", screen = "recovery_duty", duty = "recovery_duty_tatooine_privateer_5" },
	{ reply = "s_87f48e61", screen = "leader_duty", duty = "destroy_duty_tatooine_privateer_8" },
	{ reply = "s_96294214", screen = "escort_duty", duty = "escort_duty_tatooine_privateer_7" },
}

for _, d in ipairs(DUTY_MENU) do
	-- AC-7: the member's menu
	TestSmugglerT1Duties["test_the_on_track_menu_hands_out_" .. d.screen .. "_as_" .. d.duty] = function()
		local spies = spyAll(S.GLOBALS)
		local player = S.pilot({ paid = 4, tier = 2 })
		local t = S.talk(player, { "s_8aeba6e5", d.reply })

		lu.assertEquals(S.ids(t), { "duty_missions", "duty_menu", d.screen }, "screens shown")
		lu.assertTrue(t[3].stop, d.screen .. " ends the conversation")
		lu.assertEquals(started(spies), { d.duty }, "the duty started once")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-7: any menu screen, shown by itself, starts exactly its duty
	TestSmugglerT1Duties["test_" .. d.screen .. "_starts_only_its_duty"] = function()
		local spies = spyAll(S.GLOBALS)

		S.drive(S.pilot({ paid = 4, tier = 2 }), d.screen)
		lu.assertEquals(started(spies), { d.duty }, "quests started")
	end
end

-- AC-7: the menu lists the four duties in the SWG order (J s_f04d5e44)
function TestSmugglerT1Duties:test_the_duty_menu_lists_destroy_recovery_leader_and_escort_in_that_order()
	local t = S.talk(S.pilot({ paid = 4, tier = 2 }), { "s_8aeba6e5" })

	lu.assertEquals(S.optionSids(t[2]), { "s_695b8483", "s_61b6e28a", "s_87f48e61", "s_96294214" }, "replies of duty_menu")
	lu.assertEquals(S.linksOf(t[2]), { "destroy_duty", "recovery_duty", "leader_duty", "escort_duty" }, "links of duty_menu")
end

-- AC-7: the other duty replies start nothing
function TestSmugglerT1Duties:test_explain_not_ready_and_decline_start_nothing()
	for _, reply in ipairs({ "s_6106187c", "s_db74ddc6", "s_2883b989" }) do
		H.reset()

		local spies = spyAll(S.GLOBALS)
		local t = S.talk(S.pilot({ paid = 4, tier = 2 }), { reply })

		lu.assertEquals(started(spies), {}, "reply " .. reply .. ": no quest started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7 (FS-7): the off-track menu hands out the same duties
function TestSmugglerT1Duties:test_the_off_track_menu_hands_out_each_duty_to_a_corsec_pilot()
	for _, d in ipairs(DUTY_MENU) do
		H.reset()

		local spies = spyAll(S.GLOBALS)
		local t = S.talk(S.pilot({ squadron = CORSEC_SQUADRON, tier = 1 }), { "s_c1ff5062", "s_8aeba6e5", d.reply })

		lu.assertEquals(S.ids(t), { "non_member", "non_member_duty_offer", "duty_menu", d.screen }, d.duty .. ": screens shown")
		lu.assertEquals(started(spies), { d.duty }, d.duty .. ": started once")
	end
end

---------------------------------------------------------------------------------------------
-- The signed-up pilot at the master trainers (AC-7 downstream)
---------------------------------------------------------------------------------------------

TestSmugglerT1Downstream = {}

TestSmugglerT1Downstream.setUp = setUp

-- AC-7: the master trainers' Smuggler gates now see a real Smuggler
function TestSmugglerT1Downstream:test_the_signed_up_pilot_opens_smuggler_at_declann_and_privateer_not_ready_at_burke()
	local P = require("master_trainer_privateer_data")

	P.load()
	S.requireConversation(lu)

	local player = S.pilot(NON_PILOT)

	S.talk(player, concat(KID_WALK, { "s_8d95c731" }))
	player.pilot = "neutral" -- the server derives the pilot kind from the skills just granted

	lu.assertEquals(player.ghost.squadronType, SMUGGLER_SQUADRON, "the sign-up set the Smuggler squadron")
	lu.assertEquals(P.firstScreen("declann", player), "smuggler", "Declann")
	lu.assertEquals(P.firstScreen("burke", player), "privateer_not_ready", "Burke: no tier 4 skills")
end
