-- Brother Ezkiel: the four mission offers, every briefing walk to an accept line, the start screens, the failure re-grants.
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-4, AC-5; Conversation flow 1 (E9-E12, E17-E20) and 3 (table H); Data mapping 2; Appendix A; FV-2; I-5).
--
-- A start screen sets `naboo_rebel_tier3_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (J3 grantQuestN). The walks are derived from
-- Appendix A (the shortest reply path to each screen of the offer or failure subgraph), then driven through the handler. The heads' startQuest is spied (H.spyOn does
-- not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local CS = require("harness.client_strings")

W.loadConversation()

local function setUp()
	H.reset()
	W.requireConversation(lu)
end

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

-- the start screens of mission n that are in `found`
local function startsIn(found, n)
	local out = {}

	for id in pairs(found) do
		if W.START_SCREENS[id] == n then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

-- Talks through `choices` with a fresh pilot and the head spies; returns the transcript, the player and the heads started
local function walk(player, choices)
	local spies = W.spyStarts()
	local t = W.talk(player, choices)

	return t, player, W.startedList(spies)
end

TestEzkielOffers = {}

TestEzkielOffers.setUp = setUp

-- AC-4 (the oracle): each offer reaches exactly its accept screens (M1: 5, M2: 2, M3: 2, M4: 2) and no other mission's start, reward or training screen
function TestEzkielOffers:test_each_offer_reaches_exactly_its_accept_screens()
	local want = {
		{ "m1_accept_21aa6c60", "m1_accept_401aa65c", "m1_accept_c872184", "m1_accept_d683dc69", "m1_accept_fb1d4add" },
		{ "m2_accept_cb3876f5", "m2_accept_f8a22f8" },
		{ "m3_accept_18c308e1", "m3_accept_68355d90" },
		{ "m4_accept_aa7a038e", "m4_accept_b24e355f" },
	}

	for n = 1, 4 do
		local found = W.reach(W.MISSIONS[n].offer)

		lu.assertEquals(startsIn(found, n), want[n], "mission " .. n .. ": grant screens reachable from " .. W.MISSIONS[n].offer .. " (the oracle graph)")
		lu.assertEquals(W.acceptScreens(n), want[n], "mission " .. n .. ": the accept screens of START_SCREENS")

		for id in pairs(found) do
			lu.assertTrue(W.START_SCREENS[id] == nil or W.START_SCREENS[id] == n, "offer " .. n .. " reaches the start of another mission: " .. id)
			lu.assertNil(W.REWARD_SCREENS[id], "offer " .. n .. " reaches a reward screen: " .. id)
		end
	end
end

-- AC-4: the first meeting offers three attitudes
function TestEzkielOffers:test_the_first_meeting_offers_three_attitudes()
	local t = W.talk(W.pilot({}))

	lu.assertEquals(W.ids(t), { "m1_offer" }, "first screen")
	lu.assertEquals(W.optionSids(t[1]), { "s_ba5bf569", "s_58ddac81", "s_6eb747d4" }, "'I try.', 'I'm trustworthy - AND I'm a good fighter.', 'That's very kind of him.'")
	lu.assertEquals(W.linksOf(t[1]), { "m1_6e75fbb0", "m1_s94", "m1_aacbf366" }, "the three routes")
end

-- AC-4, Data mapping 2: every link of every offer's briefing (the rejoined [R], twin [T] and reused [b] links included) is walkable from the first screen; a quest
-- starts only on the last screen of a walk that ends on an accept screen, and exactly once
function TestEzkielOffers:test_every_link_of_every_briefing_is_walkable_and_only_an_accept_screen_starts_the_mission()
	local walked = 0

	for n = 1, 4 do
		local offer = W.MISSIONS[n].offer
		local found = W.reach(offer)

		for _, id in ipairs(sortedKeys(found)) do
			for _, o in ipairs(W.screenRow(id).options) do
				H.reset()

				local path = found[id]
				local replies, ids = { table.unpack(path.replies) }, { table.unpack(path.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]

				local t, player, started = walk(W.readyFor(n), replies)
				local label = "mission " .. n .. ": " .. table.concat(ids, " > ")

				walked = walked + 1
				lu.assertEquals(W.ids(t), ids, label .. ": screens shown")
				lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")

				if W.START_SCREENS[o[2]] == n then
					lu.assertEquals(started, { W.MISSIONS[n].head .. " x1" }, label .. ": the head started once, on the accept screen")
					lu.assertEquals(W.attempted(player, n), "1", label .. ": :attempted")
					lu.assertTrue(t[#t].stop, label .. ": the accept screen ends the conversation")
				else
					lu.assertEquals(started, {}, label .. ": nothing starts before the accept screen")
					lu.assertNil(W.attempted(player, n), label .. ": no :attempted key yet")
				end
			end
		end
	end

	lu.assertTrue(walked >= 100, "walked " .. walked .. " links over the four offer subgraphs")
end

-- AC-4: every screen of an offer subgraph is on a walk to one of its accept screens (no dead end)
function TestEzkielOffers:test_every_screen_of_an_offer_subgraph_leads_to_an_accept_screen()
	for n = 1, 4 do
		local accepts = W.acceptScreens(n)

		for id in pairs(W.reach(W.MISSIONS[n].offer)) do
			local found = W.reach(id)
			local ok = false

			for _, accept in ipairs(accepts) do
				ok = ok or found[accept] ~= nil
			end

			lu.assertTrue(ok, "offer " .. n .. ": screen " .. id .. " reaches no accept screen")
		end
	end
end

-- AC-4, I-5: quests start only on START_SCREENS; every start sets :attempted of its own mission; no other screen starts or marks anything
function TestEzkielOffers:test_only_the_17_start_screens_start_a_quest_and_each_sets_its_own_attempted_key()
	local starts = 0

	for _, row in ipairs(W.SCREENS) do
		H.reset()

		local n = W.START_SCREENS[row.id]
		local player = W.readyFor(n or 3)
		local spies = W.spyStarts()

		W.drive(player, row.id)

		if n then
			starts = starts + 1
			lu.assertEquals(W.startedList(spies), { W.MISSIONS[n].head .. " x1" }, row.id .. ": the head of mission " .. n .. " started")

			for m = 1, 4 do
				lu.assertEquals(W.attempted(player, m), m <= n and "1" or nil, row.id .. ": :attempted of mission " .. m .. " (set by this start, or by the earlier missions of the pilot)")
			end
		else
			lu.assertEquals(W.startedList(spies), {}, row.id .. ": started nothing")

			for m = 1, 4 do
				lu.assertEquals(W.attempted(player, m), m <= 2 and "1" or nil, row.id .. ": :attempted of mission " .. m .. " is as the pilot had it")
			end
		end
	end

	lu.assertEquals(starts, 17, "start screens driven")
end

-- AC-4: really started, the head's journal entry is active (a ship in the mission's zone)
function TestEzkielOffers:test_the_accept_screens_leave_the_head_journal_entry_active_in_the_missions_zone()
	for n = 1, 4 do
		for _, accept in ipairs(W.acceptScreens(n)) do
			H.reset()
			W.startAll()

			local player = W.readyFor(n, { inShip = true, zone = W.MISSIONS[n].zone })
			local ok, err = pcall(function()
				W.drive(player, accept)
				H.advance(0)
			end)

			lu.assertTrue(ok, accept .. ": raised a Lua error: " .. tostring(err))
			lu.assertEquals(W.state(player, W.HEADS[n]), "active", accept .. ": the journal entry of " .. W.HEADS[n])
			lu.assertEquals(W.attempted(player, n), "1", accept .. ": :attempted")
		end
	end
end

-- AC-4: a start screen shown while the chain is running does not start it twice
function TestEzkielOffers:test_a_start_screen_shown_while_the_chain_is_running_does_not_restart_it()
	for n = 1, 4 do
		H.reset()
		W.startAll()

		local player = W.readyFor(n, { inShip = true, zone = W.MISSIONS[n].zone })
		local accept = W.acceptScreens(n)[1]

		W.drive(player, accept)
		H.advance(0)

		local spies = W.spyStarts()

		W.drive(player, accept)
		lu.assertEquals(W.startedList(spies), {}, "mission " .. n .. ": the head is active: startSpaceQuestChain refuses")
		lu.assertEquals(W.attempted(player, n), "1", "mission " .. n .. ": :attempted stays")
	end
end

-- AC-4: the next talk after an accept is on_mission
function TestEzkielOffers:test_after_an_accept_the_next_talk_is_on_mission()
	W.startAll()

	local player = W.readyFor(1, { inShip = true, zone = W.MISSIONS[1].zone })

	W.talk(player, (W.walkTo("m1_offer", "m1_accept_401aa65c")))
	H.advance(0)
	lu.assertEquals(W.state(player, W.HEADS[1]), "active", "the head runs")
	lu.assertEquals(W.firstScreen(player), "on_mission", "the next talk")
end

-- AC-4: mission n+1 is not offered while mission n's skill is unchosen
function TestEzkielOffers:test_mission_n_plus_1_is_not_offered_while_mission_ns_skill_is_unchosen()
	for n = 1, 3 do
		H.reset()

		local player = W.pilot({ missions = n, t3 = n - 1 })
		local first = W.firstScreen(player)

		lu.assertEquals(first, "m" .. n .. "_reward", "mission " .. n .. " won and paid, its skill unchosen")
		lu.assertNotEquals(first, "m" .. (n + 1) .. "_offer", "mission " .. (n + 1) .. " is not offered")
	end
end

---------------------------------------------------------------------------------------------
-- Failures and re-grants (AC-5; FV-2)
---------------------------------------------------------------------------------------------

TestEzkielFailures = {}

TestEzkielFailures.setUp = setUp

for n = 2, 3 do
	local failed = W.MISSIONS[n].failed
	local found = W.reach(failed)

	assert(#startsIn(found, n) > 0, "oracle: " .. failed .. " reaches a re-grant line")

	for _, regrant in ipairs(startsIn(found, n)) do
		-- AC-5: the failure dialogue restarts the head on the re-grant line only
		TestEzkielFailures["test_the_walk_from_" .. failed .. "_to_" .. regrant .. "_restarts_mission_" .. n .. "_on_the_re_grant_line_only"] = function()
			local path = found[regrant]

			for k = 0, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), prefix)

				lu.assertEquals(W.ids(t), { table.unpack(path.ids, 1, k + 1) }, regrant .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, regrant .. ": nothing restarted before the re-grant line (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { W.MISSIONS[n].head .. " x1" }, regrant .. ": the head restarted once")
					lu.assertEquals(W.attempted(player, n), "1", regrant .. ": :attempted")
					lu.assertTrue(t[#t].stop, regrant .. " ends the conversation")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, regrant .. ": client strings")
				end
			end
		end
	end

	-- AC-5: every reply of the failure dialogue reaches a retry screen that restarts the head, and the failure screen itself starts nothing
	TestEzkielFailures["test_every_reply_of_" .. failed .. "_reaches_a_retry_screen_and_the_screen_itself_starts_nothing"] = function()
		local row = W.screenRow(failed)

		lu.assertEquals(#row.options, 2, failed .. ": two replies")

		local _, _, shown = walk(W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), nil)

		lu.assertEquals(shown, {}, failed .. ": started nothing on display")

		for _, o in ipairs(row.options) do
			H.reset()

			local t, player, started = walk(W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), { o[1] })

			lu.assertEquals(W.ids(t), { failed, o[2] }, "reply " .. o[1])
			lu.assertEquals(W.START_SCREENS[o[2]], n, o[2] .. " is a re-grant screen of mission " .. n)
			lu.assertEquals(started, { W.MISSIONS[n].head .. " x1" }, o[2] .. ": the head restarted")
			lu.assertEquals(W.attempted(player, n), "1", o[2] .. ": :attempted")
			lu.assertTrue(t[2].stop, o[2] .. " ends")
		end
	end

	-- AC-5: every ending of the failure dialogue is a re-grant line (no dead end, no other ending)
	TestEzkielFailures["test_every_ending_of_the_" .. failed .. "_dialogue_is_a_re_grant_line"] = function()
		for id in pairs(found) do
			if W.screenRow(id).stop then
				lu.assertEquals(W.START_SCREENS[id], n, id .. ": an ending of the failure dialogue of mission " .. n .. " restarts it")
			end
		end
	end
end

-- AC-5: m1_failed and m4_failed restart the head as soon as they are shown and end
function TestEzkielFailures:test_m1_failed_and_m4_failed_restart_the_head_on_display_and_end()
	for _, n in ipairs({ 1, 4 }) do
		H.reset()

		local failed = W.MISSIONS[n].failed
		local t, player, started = walk(W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), nil)

		lu.assertEquals(W.ids(t), { failed }, "mission " .. n .. ": first screen")
		lu.assertTrue(t[1].stop, failed .. " ends the conversation")
		lu.assertEquals(#t[1].options, 0, failed .. " offers no reply")
		lu.assertEquals(started, { W.MISSIONS[n].head .. " x1" }, "mission " .. n .. " restarted on display, once")
		lu.assertEquals(W.attempted(player, n), "1", failed .. ": :attempted")
		lu.assertEquals(t[1].params.TU, "Ace", failed .. ": the first name")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-5: the failure greetings are J3's lines
function TestEzkielFailures:test_the_failure_greetings_are_the_j3_lines()
	local want = { "s_1ba01028", "s_4f98b9b7", "s_840116ce", "s_51fbced7" }

	for n = 1, 4 do
		H.reset()

		local t = walk(W.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), nil)

		lu.assertEquals(t[1].text, W.PREFIX .. want[n], "mission " .. n .. ": the failure line")
	end
end

-- AC-5: a chain member failed (a prefix of the chain complete, nothing running) re-grants like any failure
function TestEzkielFailures:test_a_failed_middle_member_opens_the_failure_screen_and_the_re_grant_restarts_the_head()
	for n = 1, 4 do
		for k = 1, 4 do
			H.reset()

			local t, _, started = walk(W.pilot({ missions = n - 1, t3 = n - 1, partial = k }), nil)

			lu.assertEquals(t[1].id, "m" .. n .. "_failed", "mission " .. n .. ", first " .. k .. " members complete: first screen")

			if n == 1 or n == 4 then
				lu.assertEquals(started, { W.MISSIONS[n].head .. " x1" }, "mission " .. n .. ": restarted on display")
			else
				lu.assertEquals(started, {}, "mission " .. n .. ": the failure screen starts nothing")
			end
		end
	end
end

-- AC-5: with the real heads the mission runs after the re-grant and the next talk is on_mission
function TestEzkielFailures:test_the_re_grant_makes_the_real_head_active_and_the_next_talk_is_on_mission()
	for n = 1, 4 do
		H.reset()
		W.startAll()

		local player = W.pilot({ missions = n - 1, t3 = n - 1, state = "failed", inShip = true, zone = W.MISSIONS[n].zone })
		local choices = nil

		if n == 2 or n == 3 then
			choices = { W.screenRow(W.MISSIONS[n].failed).options[1][1] }
		end

		W.talk(player, choices)
		H.advance(0)
		lu.assertEquals(W.state(player, W.HEADS[n]), "active", W.HEADS[n] .. ": the journal entry after the re-grant")
		lu.assertEquals(W.firstScreen(player), "on_mission", "mission " .. n .. ": the next talk")
	end
end

-- AC-5: the re-grant of mission 1 clears the chain's old journal entries (startSpaceQuestChain) and runs the head again
function TestEzkielFailures:test_the_mission_1_re_grant_clears_the_old_chain_entries()
	W.startAll()

	local player = W.pilot({ missions = 0, partial = 3, inShip = true, zone = W.MISSIONS[1].zone })

	lu.assertEquals(W.state(player, W.M1[2]), "complete", "precondition: the escort is complete")
	W.talk(player)
	H.advance(0)
	lu.assertEquals(W.state(player, W.M1[1]), "active", "the head is running again")
	lu.assertEquals(W.state(player, W.M1[2]), "none", "the escort entry is cleared")
	lu.assertEquals(W.state(player, W.M1[3]), "none", "the survival entry is cleared")
end

-- AC-5: a mission aborted from the datapad opens the failure screen and the re-grant works
function TestEzkielFailures:test_an_aborted_mission_can_be_restarted_from_the_failure_screen()
	for n = 1, 4 do
		H.reset()
		W.startAll()

		local player = W.pilot({ missions = n - 1, t3 = n - 1, inShip = true, zone = W.MISSIONS[n].zone })

		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")
		W.setState(player, W.HEADS[n], "active")
		W.quest(W.HEADS[n]):abortQuest(player)
		lu.assertEquals(W.firstScreen(player), "m" .. n .. "_failed", "mission " .. n .. ": after the abort")
	end
end
