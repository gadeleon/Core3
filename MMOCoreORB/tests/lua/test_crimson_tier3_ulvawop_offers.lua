-- Arnecio Ulvaw'op: the four mission offers, every briefing walk to an accept line, the start screens, the failure re-grants.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-4, AC-5; Conversation flow 1 (E8-E11, E16-E19) and 3 (table H); Data mapping 2; Appendix A; D-4; I-5).
--
-- A start screen sets `tatooine_rebel_tier3_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (JU grantQuestN). The walks are derived from
-- Appendix A (the shortest reply path to each screen of the offer or failure subgraph), then driven through the handler. The heads' startQuest is spied (H.spyOn does
-- not call the original) except in the "real start" tests, which run it in a ship in the mission's zone.

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local CS = require("harness.client_strings")

T.loadConversation()

local function setUp()
	H.reset()
	T.requireConversation(lu)
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
		if T.START_SCREENS[id] == n then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

-- Talks through `choices` with a fresh pilot and the head spies; returns the transcript, the player and the heads started
local function walk(player, choices)
	local spies = T.spyStarts()
	local t = T.talk(player, choices)

	return t, player, T.startedList(spies)
end

-- the Appendix A screens of chapter n: ids of mission n's briefing (prefix mN_), without the failure, retry and reward screens
local function chapter(n)
	local out = {}

	for _, row in ipairs(T.SCREENS) do
		if row.id:sub(1, 3) == "m" .. n .. "_" and not row.id:find("_failed$") and not row.id:find("_retry_", 1, true) and not row.id:find("_reward$") then
			out[#out + 1] = row.id
		end
	end

	return out
end

TestUlvawopOffers = {}

TestUlvawopOffers.setUp = setUp

-- AC-4 (the oracle): each offer reaches exactly its accept screens (M1: 1, M2: 1, M3: 4, M4: 2) and no other mission's start, reward or training screen
function TestUlvawopOffers:test_each_offer_reaches_exactly_its_accept_screens()
	local want = {
		{ "m1_accept_d5bf212f" },
		{ "m2_accept_b1479cf9" },
		{ "m3_accept_404b8a10", "m3_accept_573af66b", "m3_accept_89962192", "m3_accept_94a2001c" },
		{ "m4_accept_2493aca3", "m4_accept_7b3fb40b" },
	}

	for n = 1, 4 do
		local found = T.reach(T.MISSIONS[n].offer)

		lu.assertEquals(startsIn(found, n), want[n], "mission " .. n .. ": grant screens reachable from " .. T.MISSIONS[n].offer .. " (the oracle graph)")
		lu.assertEquals(T.acceptScreens(n), want[n], "mission " .. n .. ": the accept screens of START_SCREENS")

		for id in pairs(found) do
			lu.assertTrue(T.START_SCREENS[id] == nil or T.START_SCREENS[id] == n, "offer " .. n .. " reaches the start of another mission: " .. id)
			lu.assertNil(T.REWARD_SCREENS[id], "offer " .. n .. " reaches a reward screen: " .. id)
		end
	end
end

-- AC-4: the first meeting offers two openings
function TestUlvawopOffers:test_the_first_meeting_offers_two_openings()
	local t = T.talk(T.pilot({}))

	lu.assertEquals(T.ids(t), { "m1_offer" }, "first screen")
	lu.assertEquals(T.optionSids(t[1]), { "s_783af10a", "s_5b000af8" }, "'What picture?', 'Different how?'")
	lu.assertEquals(T.linksOf(t[1]), { "m1_be9caae0", "m1_64170652" }, "the two routes")
end

-- AC-4 (spec Conversation flow 5): every M1 route reaches the Imperial Security Officer briefing and the one accept line
function TestUlvawopOffers:test_every_m1_route_reaches_the_security_officer_briefing_and_the_one_accept_line()
	local found = T.reach("m1_offer")

	lu.assertNotNil(found.m1_189648be, "m1_189648be 'At the moment, he is in Dathomir space on a Lambda shuttle...' is reachable")

	for id, hit in pairs(found) do
		if id ~= "m1_accept_d5bf212f" then
			local via = T.reach(id)

			lu.assertNotNil(via.m1_accept_d5bf212f, "M1 screen " .. id .. " leads to the accept line")
		end

		lu.assertNotNil(hit.ids, "path to " .. id)
	end
end

-- AC-4, Data mapping 2: every link of every offer's briefing (the rejoined [R], twin [T] and reused [b] links included) is walkable from the first screen; a quest
-- starts only on the last screen of a walk that ends on an accept screen, and exactly once
function TestUlvawopOffers:test_every_link_of_every_briefing_is_walkable_and_only_an_accept_screen_starts_the_mission()
	local walked, marked = 0, 0

	for n = 1, 4 do
		local offer = T.MISSIONS[n].offer
		local found = T.reach(offer)

		for _, id in ipairs(sortedKeys(found)) do
			for _, o in ipairs(T.screenRow(id).options) do
				H.reset()

				local path = found[id]
				local replies, ids = { table.unpack(path.replies) }, { table.unpack(path.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]

				local t, player, started = walk(T.readyFor(n), replies)
				local label = "mission " .. n .. ": " .. table.concat(ids, " > ")

				walked = walked + 1

				if o[3] ~= "" then
					marked = marked + 1
				end

				lu.assertEquals(T.ids(t), ids, label .. ": screens shown")
				lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")

				if T.START_SCREENS[o[2]] == n then
					lu.assertEquals(started, { T.MISSIONS[n].head .. " x1" }, label .. ": the head started once, on the accept screen")
					lu.assertEquals(T.attempted(player, n), "1", label .. ": :attempted")
					lu.assertTrue(t[#t].stop, label .. ": the accept screen ends the conversation")
				else
					lu.assertEquals(started, {}, label .. ": nothing starts before the accept screen")
					lu.assertNil(T.attempted(player, n), label .. ": no :attempted key yet")
				end
			end
		end
	end

	lu.assertTrue(walked >= 120, "walked " .. walked .. " links over the four offer subgraphs")
	lu.assertEquals(marked, 27, "every [R]/[T]/[b] link of the four briefings is taken by a tested walk (the 28th marked link, handoff_spy to handoff_leave, is walked in test_crimson_tier3_ulvawop_training.lua)")
end

-- AC-4: every screen of chapter mN_ is on a walk from mN_offer and on a walk to one of its accept screens (no orphan, no dead end)
function TestUlvawopOffers:test_every_chapter_screen_lies_on_a_walk_from_the_offer_to_an_accept_screen()
	local counts = { 39, 36, 26, 11 }

	for n = 1, 4 do
		local accepts = T.acceptScreens(n)
		local found = T.reach(T.MISSIONS[n].offer)

		lu.assertEquals(#chapter(n), counts[n], "chapter " .. n .. ": screens of Appendix A")

		for _, id in ipairs(chapter(n)) do
			lu.assertNotNil(found[id], "chapter " .. n .. ": screen " .. id .. " is not reachable from " .. T.MISSIONS[n].offer)

			local ok = false

			for _, accept in ipairs(accepts) do
				ok = ok or T.reach(id)[accept] ~= nil
			end

			lu.assertTrue(ok, "chapter " .. n .. ": screen " .. id .. " reaches no accept screen")
		end
	end
end

-- AC-4, I-5: quests start only on the 16 START_SCREENS and each sets its own mission's :attempted key; no other screen starts or marks anything
function TestUlvawopOffers:test_only_the_16_start_screens_start_a_quest_and_each_sets_its_own_attempted_key()
	local starts = 0

	for _, row in ipairs(T.SCREENS) do
		H.reset()

		local n = T.START_SCREENS[row.id]
		local player = T.readyFor(n or 3)
		local spies = T.spyStarts()

		T.drive(player, row.id)

		if n then
			starts = starts + 1
			lu.assertEquals(T.startedList(spies), { T.MISSIONS[n].head .. " x1" }, row.id .. ": the head of mission " .. n .. " started")

			for m = 1, 4 do
				lu.assertEquals(T.attempted(player, m), m <= n and "1" or nil, row.id .. ": :attempted of mission " .. m .. " (set by this start, or by the earlier missions of the pilot)")
			end
		else
			lu.assertEquals(T.startedList(spies), {}, row.id .. ": started nothing")

			for m = 1, 4 do
				lu.assertEquals(T.attempted(player, m), m <= 2 and "1" or nil, row.id .. ": :attempted of mission " .. m .. " is as the pilot had it")
			end
		end
	end

	lu.assertEquals(starts, 16, "start screens driven")
end

-- AC-4, I-5: no gate screen starts a quest (JU's failure gate lines carry no action)
function TestUlvawopOffers:test_no_gate_screen_starts_a_quest()
	for _, id in ipairs({ "not_pilot", "wrong_faction", "off_track", "grounded", "not_ready", "on_mission", "m1_failed", "m2_failed", "m3_failed", "m4_failed" }) do
		H.reset()

		local spies = T.spyStarts()

		T.drive(T.pilot({}), id)
		lu.assertEquals(T.startedList(spies), {}, id .. ": started nothing")
	end
end

-- AC-4: really started, the head's journal entry is active (a ship in the mission's zone)
function TestUlvawopOffers:test_the_accept_screens_leave_the_head_journal_entry_active_in_the_missions_zone()
	for n = 1, 4 do
		for _, accept in ipairs(T.acceptScreens(n)) do
			H.reset()
			T.startAll()

			local player = T.readyFor(n, { inShip = true, zone = T.MISSIONS[n].zone })
			local ok, err = pcall(function()
				T.drive(player, accept)
				H.advance(0)
			end)

			lu.assertTrue(ok, accept .. ": raised a Lua error: " .. tostring(err))
			lu.assertEquals(T.state(player, T.HEADS[n]), "active", accept .. ": the journal entry of " .. T.HEADS[n])
			lu.assertEquals(T.attempted(player, n), "1", accept .. ": :attempted")
		end
	end
end

-- AC-4: a start screen shown while the chain is running does not start it twice
function TestUlvawopOffers:test_a_start_screen_shown_while_the_chain_is_running_does_not_restart_it()
	for n = 1, 4 do
		H.reset()
		T.startAll()

		local player = T.readyFor(n, { inShip = true, zone = T.MISSIONS[n].zone })
		local accept = T.acceptScreens(n)[1]

		T.drive(player, accept)
		H.advance(0)

		local spies = T.spyStarts()

		T.drive(player, accept)
		lu.assertEquals(T.startedList(spies), {}, "mission " .. n .. ": the head is active: startSpaceQuestChain refuses")
		lu.assertEquals(T.attempted(player, n), "1", "mission " .. n .. ": :attempted stays")
	end
end

-- AC-4: the next talk after an accept is on_mission
function TestUlvawopOffers:test_after_an_accept_the_next_talk_is_on_mission()
	T.startAll()

	local player = T.readyFor(1, { inShip = true, zone = T.MISSIONS[1].zone })

	T.talk(player, (T.walkTo("m1_offer", "m1_accept_d5bf212f")))
	H.advance(0)
	lu.assertEquals(T.state(player, T.HEADS[1]), "active", "the head runs")
	lu.assertEquals(T.firstScreen(player), "on_mission", "the next talk")
end

-- AC-4: mission n+1 is not offered while mission n's skill is unchosen
function TestUlvawopOffers:test_mission_n_plus_1_is_not_offered_while_mission_ns_skill_is_unchosen()
	for n = 1, 3 do
		H.reset()

		local player = T.pilot({ missions = n, t3 = n - 1 })
		local first = T.firstScreen(player)

		lu.assertEquals(first, "m" .. n .. "_reward", "mission " .. n .. " won and paid, its skill unchosen")
		lu.assertNotEquals(first, "m" .. (n + 1) .. "_offer", "mission " .. (n + 1) .. " is not offered")
	end
end

---------------------------------------------------------------------------------------------
-- Failures and re-grants (AC-5; D-4)
---------------------------------------------------------------------------------------------

TestUlvawopFailures = {}

TestUlvawopFailures.setUp = setUp

for n = 1, 4 do
	local failed = T.MISSIONS[n].failed
	local found = T.reach(failed)

	assert(#startsIn(found, n) == 2, "oracle: " .. failed .. " reaches its two retry lines")

	-- AC-5: every reply of the failure screen reaches a retry screen that restarts the head, and the failure screen itself starts nothing
	TestUlvawopFailures["test_every_reply_of_" .. failed .. "_reaches_a_retry_screen_and_the_screen_itself_starts_nothing"] = function()
		local row = T.screenRow(failed)

		lu.assertEquals(#row.options, 2, failed .. ": two replies")

		local _, _, shown = walk(T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), nil)

		lu.assertEquals(shown, {}, failed .. ": started nothing on display")

		for _, o in ipairs(row.options) do
			H.reset()

			local t, player, started = walk(T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), { o[1] })

			lu.assertEquals(T.ids(t), { failed, o[2] }, "reply " .. o[1])
			lu.assertEquals(T.START_SCREENS[o[2]], n, o[2] .. " is a re-grant screen of mission " .. n)
			lu.assertEquals(started, { T.MISSIONS[n].head .. " x1" }, o[2] .. ": the head restarted")
			lu.assertEquals(T.attempted(player, n), "1", o[2] .. ": :attempted")
			lu.assertTrue(t[2].stop, o[2] .. " ends")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end

	-- AC-5: the failure dialogue restarts the head on the retry line only, and the retry line ends
	TestUlvawopFailures["test_the_walks_from_" .. failed .. "_restart_mission_" .. n .. "_on_the_retry_line_only"] = function()
		for _, regrant in ipairs(startsIn(found, n)) do
			local path = found[regrant]

			for k = 0, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), prefix)

				lu.assertEquals(T.ids(t), { table.unpack(path.ids, 1, k + 1) }, regrant .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, regrant .. ": nothing restarted before the retry line (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { T.MISSIONS[n].head .. " x1" }, regrant .. ": the head restarted once")
					lu.assertEquals(T.attempted(player, n), "1", regrant .. ": :attempted")
					lu.assertTrue(t[#t].stop, regrant .. " ends the conversation")
				end
			end
		end
	end

	-- AC-5: every ending of the failure dialogue is a retry line (no dead end, no other ending)
	TestUlvawopFailures["test_every_ending_of_the_" .. failed .. "_dialogue_is_a_retry_line"] = function()
		for id in pairs(found) do
			if T.screenRow(id).stop then
				lu.assertEquals(T.START_SCREENS[id], n, id .. ": an ending of the failure dialogue of mission " .. n .. " restarts it")
			end
		end
	end
end

-- AC-5: the retry lines are JU's (the grant carriers on the reply lines)
function TestUlvawopFailures:test_the_retry_lines_are_the_ju_lines()
	local want = {
		{ "s_652ff698", "s_a53ea74c" }, { "s_59552474", "s_3eeaed57" }, { "s_5973a2b6", "s_665b67d1" }, { "s_d6643019", "s_9df42b04" },
	}

	for n = 1, 4 do
		for k, o in ipairs(T.screenRow(T.MISSIONS[n].failed).options) do
			H.reset()

			local t = walk(T.pilot({ missions = n - 1, t3 = n - 1, state = "failed" }), { o[1] })

			lu.assertEquals(t[2].text, T.PREFIX .. want[n][k], "mission " .. n .. ", reply " .. k .. ": the retry line")
		end
	end
end

-- AC-5: a chain member failed (a prefix of the chain complete, nothing running) re-grants like any failure
function TestUlvawopFailures:test_a_failed_middle_member_opens_the_failure_screen_and_the_re_grant_restarts_the_head()
	for n = 1, 4 do
		for k = 1, #T.CHAINS[n] - 1 do
			H.reset()

			local reply = T.screenRow(T.MISSIONS[n].failed).options[1][1]
			local t, _, started = walk(T.pilot({ missions = n - 1, t3 = n - 1, partial = k }), { reply })

			lu.assertEquals(t[1].id, "m" .. n .. "_failed", "mission " .. n .. ", first " .. k .. " members complete: first screen")
			lu.assertEquals(started, { T.MISSIONS[n].head .. " x1" }, "mission " .. n .. ": restarted on the retry line")
		end
	end
end

-- AC-5: with the real heads the mission runs after the re-grant and the next talk is on_mission
function TestUlvawopFailures:test_the_re_grant_makes_the_real_head_active_and_the_next_talk_is_on_mission()
	for n = 1, 4 do
		for _, o in ipairs(T.screenRow(T.MISSIONS[n].failed).options) do
			H.reset()
			T.startAll()

			local player = T.pilot({ missions = n - 1, t3 = n - 1, state = "failed", inShip = true, zone = T.MISSIONS[n].zone })

			T.talk(player, { o[1] })
			H.advance(0)
			lu.assertEquals(T.state(player, T.HEADS[n]), "active", T.HEADS[n] .. ": the journal entry after the re-grant")
			lu.assertEquals(T.firstScreen(player), "on_mission", "mission " .. n .. ": the next talk")
		end
	end
end

-- AC-5: the re-grant clears the chain's old journal entries (startSpaceQuestChain) and runs the head again
function TestUlvawopFailures:test_the_re_grant_clears_the_old_chain_entries()
	for n = 1, 4 do
		H.reset()
		T.startAll()

		local player = T.pilot({ missions = n - 1, t3 = n - 1, partial = 2, inShip = true, zone = T.MISSIONS[n].zone })

		lu.assertEquals(T.state(player, T.CHAINS[n][2]), "complete", "mission " .. n .. ", precondition: the second member is complete")
		T.talk(player, { T.screenRow(T.MISSIONS[n].failed).options[1][1] })
		H.advance(0)
		lu.assertEquals(T.state(player, T.CHAINS[n][1]), "active", "mission " .. n .. ": the head is running again")
		lu.assertEquals(T.state(player, T.CHAINS[n][2]), "none", "mission " .. n .. ": the old second entry is cleared")
	end
end

-- AC-5: a mission aborted from the datapad opens the failure screen and the re-grant works
function TestUlvawopFailures:test_an_aborted_mission_can_be_restarted_from_the_failure_screen()
	for n = 1, 4 do
		H.reset()
		T.startAll()

		local player = T.pilot({ missions = n - 1, t3 = n - 1, inShip = true, zone = T.MISSIONS[n].zone })

		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")
		T.setState(player, T.HEADS[n], "active")
		T.quest(T.HEADS[n]):abortQuest(player)
		lu.assertEquals(T.firstScreen(player), "m" .. n .. "_failed", "mission " .. n .. ": after the abort")
	end
end
