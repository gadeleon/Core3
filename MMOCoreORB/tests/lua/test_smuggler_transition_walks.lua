-- Karrde: the walks (8 routes from the summons to the grant), the grant and the retry, every static link, and the Dravis interplay.
-- Spec: .claude/work/smuggler-transition-karrde/01-spec.md (AC-5, AC-7, AC-9; Conversation flow 3, 4 and 5; Content contract 3; D-8).
--
-- Quest starts are observed with spies on the two tables' startQuest (H.spyOn does not call the original), with a snapshot of the :attempted key
-- at call time; the real start (a pilot in a ship in space_lok) is run separately. Every transcript must resolve in the client string tables.

local lu = require("luaunit")
local H = require("harness")
local T = require("smuggler_transition_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")
local MS = require("migration_scenario")
local DR = require("duty_rules_scenario")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

-- spies on startQuest of both tables; each call keeps the :attempted key as it was when the start ran
local function spyStarts(player)
	local spies = {}

	for _, g in ipairs(T.GLOBALS) do
		spies[g] = H.spyOn(T.quest(g), "startQuest", function() return H.getQuestStatus(player, T.ATTEMPTED) end)
	end

	return spies
end

local function counts(spies)
	return { patrol = #spies[T.PATROL], assassinate = #spies[T.ASSASSINATE] }
end

local function isActive(player, global) return T.state(player, global) == "active" end

---------------------------------------------------------------------------------------------
-- AC-7: the 8 routes to the grant
---------------------------------------------------------------------------------------------

TestSmugglerTransWalks = {}

TestSmugglerTransWalks.setUp = setUp

for _, route in ipairs(T.ROUTES) do
	-- AC-7: each route shows the Appendix A screens in order, grants once at job_details and nowhere else
	TestSmugglerTransWalks["test_route_" .. route.name .. "_shows_the_appendix_a_screens_and_grants_the_patrol_once_at_the_end"] = function()
		local player = T.pilot({})
		local spies = spyStarts(player)
		local t = T.talk(player, route.replies)

		lu.assertEquals(T.ids(t), route.ids, "screens shown")
		lu.assertTrue(t[#t].stop, "job_details ends the conversation")
		lu.assertEquals(counts(spies), { patrol = 1, assassinate = 0 }, "quests started (the chain head only)")
		lu.assertEquals(spies[T.PATROL][1].snapshot, "1", ":attempted is set before the patrol starts")
		lu.assertEquals(H.getQuestStatus(player, T.ATTEMPTED), "1", ":attempted")
		lu.assertNil(H.getQuestStatus(player, T.REWARD), ":reward stays unset (only Shamdon writes it)")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the transcript (AC-5)")
	end

	-- AC-7: nothing is granted before the last screen
	TestSmugglerTransWalks["test_route_" .. route.name .. "_grants_nothing_before_job_details"] = function()
		local player = T.pilot({})
		local spies = spyStarts(player)
		local replies = {}

		for i = 1, #route.replies - 1 do
			replies[i] = route.replies[i]
		end

		local t = T.talk(player, replies)

		lu.assertEquals(T.ids(t), { table.unpack(route.ids, 1, #route.ids - 1) }, "screens shown, one short of the grant")
		lu.assertEquals(counts(spies), { patrol = 0, assassinate = 0 }, "quests started")
		lu.assertNil(H.getQuestStatus(player, T.ATTEMPTED), "no :attempted key before the grant")
	end
end

-- AC-7: there are exactly 8 routes (2 openings x 4 Nym answers)
function TestSmugglerTransWalks:test_there_are_eight_routes_from_summons_to_job_details()
	lu.assertEquals(#T.ROUTES, 8, "routes")
end

-- AC-7, Conversation flow 4: the two openings and the three questions
function TestSmugglerTransWalks:test_the_summons_offers_busy_and_fast_and_job_lok_the_three_nym_answers()
	local t = T.talk(T.pilot({}), { "s_c3c2195b", "s_1c8bddbb" })

	lu.assertEquals(T.optionSids(t[1]), { "s_c3c2195b", "s_3f10da9d" }, "replies of summons")
	lu.assertEquals(T.linksOf(t[1]), { "summons_busy", "summons_fast" }, "links of summons")
	lu.assertEquals(T.optionSids(t[3]), { "s_e70a45c9", "s_365a729a", "s_ba9fbfb1" }, "replies of job_lok")
	lu.assertEquals(T.linksOf(t[3]), { "nym_unknown", "nym_known", "nym_hates" }, "links of job_lok")
end

---------------------------------------------------------------------------------------------
-- AC-7: every static link, one step
---------------------------------------------------------------------------------------------

TestSmugglerTransEdges = {}

TestSmugglerTransEdges.setUp = setUp

-- AC-7: each reply of Appendix A leads to its linked screen (the grant screens are observed through spies)
function TestSmugglerTransEdges:test_every_static_reply_leads_to_the_screen_of_appendix_a()
	local checked = 0

	for _, row in ipairs(T.SCREENS) do
		for _, o in ipairs(row.options) do
			H.reset()

			local player = T.pilot({})

			spyStarts(player)

			local t = T.drive(player, row.id, { o[1] })

			lu.assertEquals(T.ids(t), { row.id, o[2] }, "screen '" .. row.id .. "', reply " .. o[1])
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "screen '" .. row.id .. "', reply " .. o[1] .. ": client strings (AC-5)")
			checked = checked + 1
		end
	end

	lu.assertEquals(checked, 21, "static replies walked (18 + the 3 of the K3 hub that smuggler-tier2-shamdon added)")
end

-- AC-7: the brush-offs at the top end on their Appendix A screens (not_member and dravis_employee replies)
function TestSmugglerTransEdges:test_the_not_member_and_dravis_employee_replies_end_on_their_screens()
	local nonMember = { pilot = false, squadron = false, tier = 0, paid = 0 }

	local t = T.talk(T.pilot(nonMember), { "s_dc9e436d" })

	lu.assertEquals(T.ids(t), { "not_member", "not_member_what" }, "'What do you do?'")
	lu.assertTrue(t[2].stop, "not_member_what ends the conversation")

	t = T.talk(T.pilot(nonMember), { "s_ba77b53a" })
	lu.assertEquals(T.ids(t), { "not_member", "not_member_work" }, "'What sort of work?'")
	lu.assertTrue(t[2].stop, "not_member_work ends the conversation")

	local employee = { tier = 2, paid = 2, pilotTier = 1 }

	t = T.talk(T.pilot(employee), { "s_151b3d1" })
	lu.assertEquals(T.ids(t), { "dravis_employee", "employee_keep_up" }, "'That's right.'")
	lu.assertTrue(t[2].stop, "employee_keep_up ends the conversation")

	t = T.talk(T.pilot(employee), { "s_6372b444" })
	lu.assertEquals(T.ids(t), { "dravis_employee", "employee_not_ready" }, "'Can you give me an assignment?'")
	lu.assertTrue(t[2].stop, "employee_not_ready ends the conversation")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: the chat-only screens end at once and offer nothing
function TestSmugglerTransEdges:test_the_won_running_and_low_profile_screens_end_without_replies()
	for _, case in ipairs({ { "trans_won", { trans = "won" } }, { "on_trans", { trans = "active" } }, { "low_profile", { trans = "won", rewarded = true } } }) do
		local t = T.talk(T.pilot(case[2]), { 0 })

		lu.assertEquals(T.ids(t), { case[1] }, case[1] .. ": screens shown")
		lu.assertTrue(t[1].stop, case[1] .. " ends the conversation")
		lu.assertEquals(#t[1].options, 0, case[1] .. ": replies")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, case[1] .. ": client strings")
	end
end

---------------------------------------------------------------------------------------------
-- AC-7: grants, retries, and the screens that must not grant
---------------------------------------------------------------------------------------------

TestSmugglerTransGrant = {}

TestSmugglerTransGrant.setUp = setUp

-- AC-7: only job_details and trans_retry set :attempted and start the chain
function TestSmugglerTransGrant:test_only_job_details_and_trans_retry_start_the_chain_and_set_the_attempted_key()
	for _, row in ipairs(T.SCREENS) do
		H.reset()

		local player = T.pilot({})
		local spies = spyStarts(player)
		local before = MS.snapshot(player)

		T.drive(player, row.id)

		if row.id == "job_details" or row.id == "trans_retry" then
			lu.assertEquals(counts(spies), { patrol = 1, assassinate = 0 }, "screen '" .. row.id .. "': quests started")
			lu.assertEquals(spies[T.PATROL][1].snapshot, "1", "screen '" .. row.id .. "': :attempted set before the start")
			lu.assertEquals(H.getQuestStatus(player, T.ATTEMPTED), "1", "screen '" .. row.id .. "': :attempted")
		else
			lu.assertEquals(counts(spies), { patrol = 0, assassinate = 0 }, "screen '" .. row.id .. "': quests started")
			lu.assertEquals(MS.snapshot(player), before, "screen '" .. row.id .. "': journal, statuses, observers, waypoints, datapad and shared memory")
		end

		lu.assertNil(H.getQuestStatus(player, T.REWARD), "screen '" .. row.id .. "': :reward")
	end
end

-- AC-7: the retry restarts a failed chain on its own display (D-8, no choice)
function TestSmugglerTransGrant:test_a_pilot_with_a_failed_chain_opens_trans_failed_and_the_reply_restarts_it()
	local player = T.pilot({ trans = "attempted" })
	local spies = spyStarts(player)
	local t = T.talk(player, { "s_a60a995b" })

	lu.assertEquals(T.ids(t), { "trans_failed", "trans_retry" }, "screens shown")
	lu.assertTrue(t[2].stop, "trans_retry ends the conversation")
	lu.assertEquals(counts(spies), { patrol = 1, assassinate = 0 }, "quests started (only after the reply)")
	lu.assertEquals(H.getQuestStatus(player, T.ATTEMPTED), "1", ":attempted stays set")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-7: trans_failed itself starts nothing
function TestSmugglerTransGrant:test_trans_failed_alone_starts_nothing()
	local player = T.pilot({ trans = "attempted" })
	local spies = spyStarts(player)
	local t = T.talk(player)

	lu.assertEquals(T.ids(t), { "trans_failed" }, "screens shown")
	lu.assertEquals(counts(spies), { patrol = 0, assassinate = 0 }, "quests started")
end

-- AC-7: the retry never starts a second run over a running chain
function TestSmugglerTransGrant:test_the_retry_screen_does_not_start_a_second_run_over_a_running_chain()
	local player = T.pilot({ trans = "active" })
	local spies = spyStarts(player)

	T.drive(player, "trans_retry")
	lu.assertEquals(counts(spies), { patrol = 0, assassinate = 0 }, "quests started over a running chain")
end

-- AC-7: the real start, from the first grant, in a ship in space_lok
function TestSmugglerTransGrant:test_job_details_really_starts_the_patrol_and_not_the_assassinate()
	local patrol = T.quest(T.PATROL)

	patrol:start()

	local player = T.pilot({ zone = T.ZONE, inShip = true })

	T.drive(player, "job_details")
	H.advance(0)

	lu.assertTrue(isActive(player, T.PATROL), T.PATROL .. ": active after job_details")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", T.ASSASSINATE .. ": not started yet")
	lu.assertTrue(SpaceHelpers:hasSpaceQuest(player), "the patrol is in the datapad")
	lu.assertEquals(H.getQuestStatus(player, T.ATTEMPTED), "1", ":attempted")
end

-- AC-7, R-2: the retry after a stop inside the split window restarts the whole chain
function TestSmugglerTransGrant:test_the_retry_clears_both_journal_entries_and_the_patrol_is_active_again()
	local patrol = T.quest(T.PATROL)

	patrol:start()

	local player = T.pilot({ trans = "patrol_only", zone = T.ZONE, inShip = true })

	lu.assertEquals(T.state(player, T.PATROL), "complete", "precondition: patrol complete")
	T.drive(player, "trans_retry")
	H.advance(0)

	lu.assertEquals(T.state(player, T.PATROL), "active", T.PATROL .. ": a fresh run (the complete entry is gone)")
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", T.ASSASSINATE .. ": cleared")
end

-- AC-7: the retry also clears a stale assassinate entry
function TestSmugglerTransGrant:test_the_retry_clears_a_complete_assassinate_entry_too()
	local patrol = T.quest(T.PATROL)

	patrol:start()

	local player = T.pilot({ trans = "won", zone = T.ZONE, inShip = true })

	T.drive(player, "trans_retry")
	H.advance(0)
	lu.assertEquals(T.state(player, T.ASSASSINATE), "none", T.ASSASSINATE .. ": cleared by the restart")
	lu.assertEquals(T.state(player, T.PATROL), "active", T.PATROL .. ": active again")
end

-- Content contract 3: runScreenHandlers answers nothing for a missing player or screen
function TestSmugglerTransGrant:test_runScreenHandlers_returns_nil_for_a_missing_player_or_screen()
	local tmpl = H.conversationTemplate(T.TEMPLATE)
	local screen = LuaConversationTemplate(tmpl):getScreen("summons")
	local npc = T.npc()

	lu.assertNil(T.handler():runScreenHandlers(tmpl, nil, npc, 0, screen), "no player")
	lu.assertNil(T.handler():runScreenHandlers(tmpl, T.pilot({}), npc, 0, nil), "no screen")
end

---------------------------------------------------------------------------------------------
-- AC-9: Dravis, unchanged, sees the transition
---------------------------------------------------------------------------------------------

TestSmugglerTransDravis = {}

TestSmugglerTransDravis.setUp = setUp

-- AC-9: a tier-1-complete Smuggler on the transition opens on_mission at Dravis
function TestSmugglerTransDravis:test_dravis_opens_on_mission_while_the_transition_runs()
	local patrol = T.quest(T.PATROL)

	patrol:start()

	local player = T.pilot({ zone = T.ZONE, inShip = true })

	lu.assertEquals(S.firstScreen(player), "tier_done", "precondition: Dravis hands a graduate to Karrde")
	T.drive(player, "job_details")
	H.advance(0)
	lu.assertEquals(S.firstScreen(player), "on_mission", "Dravis, the patrol running (his G8: a space mission in the datapad)")
end

-- AC-9: won, Dravis is back to tier_done on every visit
function TestSmugglerTransDravis:test_dravis_opens_tier_done_once_the_transition_is_won()
	lu.assertEquals(S.firstScreen(T.pilot({ trans = "won" })), "tier_done", "Dravis, the chain won")
	lu.assertEquals(S.firstScreen(T.pilot({ trans = "won", rewarded = true })), "tier_done", "Dravis, the chain won and paid")
end

-- AC-9: Dravis' reset and Karrde's are separate (Karrde's reset leaves Dravis' state alone)
function TestSmugglerTransDravis:test_karrde_reset_leaves_dravis_state_alone()
	local player = T.pilot({ trans = "won", rewarded = true, met = true })

	T.squadron():resetKarrdeQuests(player)

	for _, key in ipairs(S.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, key), "1", "Dravis' key " .. key)
	end

	lu.assertTrue(S.met(player), "met-Dravis key")
	lu.assertEquals(S.state(player, S.A4), "complete", "Dravis' mission 4 journal entry")
	lu.assertEquals(#S.held(player), 4, "tier 1 skills")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
end
