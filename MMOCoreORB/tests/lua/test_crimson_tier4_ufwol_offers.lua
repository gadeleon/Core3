-- General Ufwol: the four mission offers, every briefing walk to an accept line, the start screens, the failure re-grants on display (AC-5, AC-6).
-- Spec: .claude/work/crimson-phoenix-tier4-ufwol/01-spec.md (AC-5, AC-6; Conversation flow 1 (E8-E11, E17-E20) and 3 (table H); Data mapping 2; Appendix A and D; FF-1, FF-2, FF-5; D-5, D-7; I-5, I-8).
--
-- A start screen sets `tatooine_rebel_tier4_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (JF grantMissionN). The walks are derived from
-- Appendix A (the shortest reply path to each screen of the offer subgraph) and from Appendix D (one path per accept screen route), then driven through the handler. The
-- chain start is recorded and not run (E.stubChainStarts) except in the "real start" tests, which run it in a ship. The duty globals' startQuest is spied.
-- The failure screens (m1_failed .. m4_failed) re-grant their mission on display, as JF does before the line (JF:5895, 5936, 5978, 6020); their replies start nothing.

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
		if E.START_SCREENS[id] == n and id ~= E.MISSIONS[n].failed then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

-- Talks through `choices` with the pilot, the chain starts recorded and the duties spied; returns the transcript, the head names that started and the duties that started
local function walk(player, choices)
	local chains = E.stubChainStarts()
	local spies = E.spyDuties()
	local t = E.talk(player, choices)

	return t, chains, E.startedDuties(spies)
end

TestUfwolOffers = {}

TestUfwolOffers.setUp = setUp
TestUfwolOffers.tearDown = tearDown

-- AC-5 (the oracle): each offer reaches exactly its accept screen (one per mission) and no other mission's start, no reward, duty or meeting screen
function TestUfwolOffers:test_each_offer_reaches_exactly_its_accept_screen()
	local want = { { "m1_accept_d68a9f0a" }, { "m2_accept_9fcfe841" }, { "m3_accept_fed525e5" }, { "m4_accept_cc7b5947" } }

	for n = 1, 4 do
		local found = E.reach(E.MISSIONS[n].offer)

		lu.assertEquals(startsIn(found, n), want[n], "mission " .. n .. ": grant screens reachable from " .. E.MISSIONS[n].offer .. " (the oracle graph)")
		lu.assertEquals(E.MISSIONS[n].accepts, want[n], "mission " .. n .. ": the accept screens")

		for id in pairs(found) do
			lu.assertTrue(E.START_SCREENS[id] == nil or E.START_SCREENS[id] == n, "offer " .. n .. " reaches the start of another mission: " .. id)
			lu.assertNil(E.REWARD_SCREENS[id], "offer " .. n .. " reaches a reward screen: " .. id)
			lu.assertNil(E.DUTY_SCREENS[id], "offer " .. n .. " reaches a duty screen: " .. id)
			lu.assertNotEquals(id, E.MET_SCREEN, "offer " .. n .. " reaches the met screen")
		end
	end
end

-- AC-5 (the oracle): Appendix D's paths are walks of the static links; routes per mission: M1 3, M2 3, M3 2, M4 2
function TestUfwolOffers:test_appendix_d_names_the_routes_and_each_is_a_walk_of_the_static_links()
	local perMission = { 0, 0, 0, 0 }

	for i, path in ipairs(E.OFFER_PATHS) do
		local ids = E.follow(E.MISSIONS[path.mission].offer, path.replies)

		lu.assertNotNil(ids, "path " .. i .. ": every reply is on its screen")
		lu.assertEquals(ids[#ids], path.accept, "path " .. i .. ": ends on its accept screen")
		perMission[path.mission] = perMission[path.mission] + 1
	end

	lu.assertEquals(perMission, { 3, 3, 2, 2 }, "routes per mission")
end

-- AC-5, Data mapping 2: the routes cover every [T]/[R]/[b]/[P] link of the offers (each marked link is on some route's walk)
function TestUfwolOffers:test_the_appendix_d_routes_cover_every_replacement_link_of_the_nge_map()
	local covered = {}

	for _, path in ipairs(E.OFFER_PATHS) do
		local ids = E.follow(E.MISSIONS[path.mission].offer, path.replies)

		for i, reply in ipairs(path.replies) do
			covered[ids[i] .. "|" .. reply] = true
		end
	end

	local offerScreens = {}

	for n = 1, 4 do
		for id in pairs(E.reach(E.MISSIONS[n].offer)) do
			offerScreens[id] = true
		end
	end

	local missing, checked = {}, 0

	for nge, m in pairs(E.NGE_MAP) do
		if m.reply and offerScreens[m.screen] and E.screenRow(m.screen) ~= nil and m.screen ~= "training" and m.class ~= "T" then
			checked = checked + 1

			if not covered[m.screen .. "|" .. m.reply] then
				missing[#missing + 1] = nge .. " (" .. m.screen .. "|" .. m.reply .. ")"
			end
		end
	end

	table.sort(missing)
	lu.assertTrue(checked > 15, "replacement links on the offers: " .. checked)
	lu.assertEquals(missing, {}, "replacement links no Appendix D route walks")
end

-- AC-5: every Appendix D route, driven through the handler, reaches its accept screen, which starts the mission once
function TestUfwolOffers:test_every_appendix_d_route_reaches_its_accept_screen_and_starts_the_mission_once()
	for i, path in ipairs(E.OFFER_PATHS) do
		H.reset()

		local n = path.mission
		local player = E.offerPilot(n)
		local t, chains, duties = walk(player, path.replies)
		local want = E.follow(E.MISSIONS[n].offer, path.replies)

		lu.assertEquals(E.ids(t), want, "route " .. i .. ": screens shown")
		lu.assertEquals(t[#t].id, path.accept, "route " .. i .. ": the accept screen")
		lu.assertEquals(chains, { E.HEADS[n] }, "route " .. i .. ": the head started once")
		lu.assertEquals(E.attempted(player, n), "1", "route " .. i .. ": :attempted")
		lu.assertEquals(duties, {}, "route " .. i .. ": no duty started")
		lu.assertEquals(player.bankCredits, 0, "route " .. i .. ": nothing paid")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "route " .. i .. ": client strings")
		E.restore()
	end
end

-- AC-5: the accept screens of M2-M4 end the conversation; M1's accept continues to m1_79e6aa32 (ends) without a second start
function TestUfwolOffers:test_the_accept_screens_end_and_mission_1_continues_to_its_closing_line_without_a_second_start()
	for n = 2, 4 do
		H.reset()

		local path
		for _, p in ipairs(E.OFFER_PATHS) do
			path = path or (p.mission == n and p or nil)
		end

		local t = walk(E.offerPilot(n), path.replies)

		lu.assertTrue(t[#t].stop, "m" .. n .. ": the accept screen ends the conversation")
		E.restore()
	end

	H.reset()

	local replies = { table.unpack(E.OFFER_PATHS[3].replies) }

	replies[#replies + 1] = "s_49e55ca2"

	local t, chains = walk(E.offerPilot(1), replies)

	lu.assertEquals(t[#t - 1].id, "m1_accept_d68a9f0a", "the accept screen")
	lu.assertFalse(t[#t - 1].stop, "m1_accept_d68a9f0a waits for 'Yes Sir!'")
	lu.assertEquals(t[#t].id, "m1_79e6aa32", "the closing line")
	lu.assertTrue(t[#t].stop, "m1_79e6aa32 ends")
	lu.assertEquals(t[#t].params.TU, "Ace", "m1_79e6aa32 greets by first name")
	lu.assertEquals(chains, { E.HEADS[1] }, "the head started once over the whole walk")
end

-- AC-5, Data mapping 2: every link of every offer's briefing (the rejoined [R], twin [T], reused [b] and pool [P] links included) is walkable from the first screen; a quest starts
-- only on the last screen of a walk that ends on an accept screen, and exactly once
function TestUfwolOffers:test_every_link_of_every_briefing_is_walkable_and_only_an_accept_screen_starts_the_mission()
	local walked, expected = 0, 0

	for n = 1, 4 do
		for id in pairs(E.reach(E.MISSIONS[n].offer)) do
			expected = expected + #E.screenRow(id).options
		end
	end

	for n = 1, 4 do
		local offer = E.MISSIONS[n].offer
		local found = E.reach(offer)

		for _, id in ipairs(sortedKeys(found)) do
			for _, o in ipairs(E.screenRow(id).options) do
				H.reset()

				local path = found[id]
				local replies, ids = { table.unpack(path.replies) }, { table.unpack(path.ids) }

				replies[#replies + 1] = o[1]
				ids[#ids + 1] = o[2]

				local t, chains, duties = walk(E.offerPilot(n), replies)
				local label = "mission " .. n .. ": " .. table.concat(ids, " > ")

				walked = walked + 1
				lu.assertEquals(E.ids(t), ids, label .. ": screens shown")
				lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
				lu.assertEquals(duties, {}, label .. ": no duty")

				local started = false

				for _, id in ipairs(ids) do
					started = started or E.START_SCREENS[id] == n
				end

				if started then
					lu.assertEquals(chains, { E.HEADS[n] }, label .. ": the head started once, on the accept screen")
				else
					lu.assertEquals(chains, {}, label .. ": nothing starts before the accept screen")
				end

				E.restore()
			end
		end
	end

	lu.assertTrue(expected >= 50, "the four offer subgraphs have " .. expected .. " links")
	lu.assertEquals(walked, expected, "links walked over the four offer subgraphs")
end

-- AC-5: every screen of an offer subgraph is on a walk to its accept screen (no dead end)
function TestUfwolOffers:test_every_screen_of_an_offer_subgraph_leads_to_an_accept_screen()
	for n = 1, 4 do
		local accepts = E.MISSIONS[n].accepts

		local after = {}

		for _, accept in ipairs(accepts) do
			for id in pairs(E.reach(accept)) do
				after[id] = true
			end
		end

		for id in pairs(E.reach(E.MISSIONS[n].offer)) do
			local found = E.reach(id)
			local ok = after[id] == true -- the accept screen itself and the line that follows it (M1's "Oh one more thing")

			for _, accept in ipairs(accepts) do
				ok = ok or found[accept] ~= nil
			end

			lu.assertTrue(ok, "mission " .. n .. ": screen '" .. id .. "' leads to an accept screen")
		end
	end
end

-- AC-2, AC-5: the name screens of the offers greet by first name; the offers themselves carry no token
function TestUfwolOffers:test_the_offer_walks_greet_by_first_name_on_the_name_screens_only()
	for _, path in ipairs(E.OFFER_PATHS) do
		H.reset()

		local t = walk(E.offerPilot(path.mission), path.replies)
		local names = {}

		for _, id in ipairs(E.NAME_SCREENS) do
			names[id] = true
		end

		for _, step in ipairs(t) do
			if names[step.id] then
				lu.assertEquals(step.params.TU, "Ace", "screen '" .. step.id .. "': the first name")
			else
				lu.assertNil(step.params.TU, "screen '" .. step.id .. "': no text parameter")
			end
		end

		E.restore()
	end
end

-- AC-5, D-5: the new M1 route "I'm ready for anything." shows the three pool lines and rejoins JF's route with "Understood."
function TestUfwolOffers:test_the_ready_for_anything_route_shows_the_pool_exchange_of_mission_1()
	local t = walk(E.offerPilot(1), { "s_b3e9c738", "s_c8fa77b8", "s_2c4789b" })

	lu.assertEquals(E.ids(t), { "m1_offer", "m1_e9ad7c02", "m1_7ba8daf7", "m1_f7cbbb30" }, "the exchange")
	lu.assertEquals(t[2].text, E.PREFIX .. "s_e9ad7c02", "'All right. I think you're ready to at least FLY with my squad.'")
	lu.assertEquals(t[3].text, E.PREFIX .. "s_7ba8daf7", "'This doesn't mean you're a full member yet...'")
	lu.assertEquals(E.optionSids(t[2]), { "s_c8fa77b8" }, "'I can't wait!'")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-5: each accept screen sets that mission's :attempted and only it
function TestUfwolOffers:test_each_accept_screen_sets_its_attempted_key_and_nothing_else()
	for n = 1, 4 do
		for _, accept in ipairs(E.MISSIONS[n].accepts) do
			H.reset()
			E.spyDuties()
			E.stubChainStarts()

			local player = E.offerPilot(n)
			local before = E.snapshot(player).status

			E.drive(player, accept)

			local after, changed = E.snapshot(player).status, {}

			for key, value in pairs(after) do
				if before[key] ~= value then
					changed[#changed + 1] = key:sub(#tostring(player.objectID) + 1)
				end
			end

			table.sort(changed)
			lu.assertEquals(changed, { E.STATUS[n] .. ":attempted" }, accept .. ": the only key written")
			E.restore()
		end
	end
end

-- AC-5: really started, the head's journal entry is active (a ship in the mission's zone), a stale run of both branches is cleared
function TestUfwolOffers:test_the_accept_screens_leave_the_head_journal_entry_active_and_clear_a_stale_run_of_both_branches()
	for n = 1, 4 do
		for _, accept in ipairs(E.MISSIONS[n].accepts) do
			H.reset()
			E.startAll()

			local player = E.offerPilot(n, { inShip = true, zone = E.MISSIONS[n].zone })

			-- a stale run: every member of both branches complete
			for _, global in ipairs(E.CHAINS[n]) do
				E.setState(player, global, "complete")
			end

			local ok, err = pcall(function()
				E.drive(player, accept)
				H.advance(0)
			end)

			lu.assertTrue(ok, accept .. ": raised a Lua error: " .. tostring(err))
			lu.assertEquals(E.state(player, E.HEADS[n]), "active", accept .. ": the journal entry of " .. E.HEADS[n])
			lu.assertEquals(E.attempted(player, n), "1", accept .. ": :attempted")

			for i = 2, #E.CHAINS[n] do
				lu.assertEquals(E.state(player, E.CHAINS[n][i]), "none", accept .. ": the stale member " .. E.CHAINS[n][i] .. " is cleared")
			end
		end
	end
end

-- AC-5: a start screen shown while the chain is running does not start it twice (the head, or a member of either branch, is active)
function TestUfwolOffers:test_a_start_screen_shown_while_the_chain_is_running_does_not_restart_it()
	for n = 1, 4 do
		for member = 1, #E.CHAINS[n] do
			H.reset()
			E.startAll()

			local player = E.offerPilot(n, { inShip = true, zone = E.MISSIONS[n].zone })
			local accept = E.MISSIONS[n].accepts[1]

			E.drive(player, accept)
			H.advance(0)
			E.setState(player, E.HEADS[n], "none")
			E.setState(player, E.CHAINS[n][member], "active")

			local head = H.spyOn(E.quest(E.HEADS[n]), "startQuest")

			E.drive(player, accept)
			lu.assertEquals(#head, 0, "mission " .. n .. ", member " .. member .. " running: the head is not started again")
			lu.assertEquals(E.state(player, E.CHAINS[n][member]), "active", "the running member stays")
			lu.assertEquals(E.attempted(player, n), "1", ":attempted stays")
		end
	end
end

-- AC-5: the next talk after an accept is on_mission
function TestUfwolOffers:test_after_an_accept_the_next_talk_is_on_mission()
	E.startAll()

	local player = E.offerPilot(1, { inShip = true, zone = E.MISSIONS[1].zone })

	E.talk(player, E.OFFER_PATHS[3].replies)
	H.advance(0)
	lu.assertEquals(E.state(player, E.HEADS[1]), "active", "the head runs")
	lu.assertEquals(E.firstScreen(player), "on_mission", "the next talk")
end

-- AC-5: mission n+1 is not offered while mission n is unpaid, or with only n skills held
function TestUfwolOffers:test_mission_n_plus_1_is_not_offered_with_n_skills()
	for n = 1, 3 do
		H.reset()

		local paid = {}

		for i = 1, n do
			paid[i] = i
		end

		local skillsHeld = E.pilot({ met = true, t4 = paid, paid = paid })

		lu.assertNotEquals(E.firstScreen(skillsHeld), "m" .. (n + 1) .. "_offer", "n = " .. n .. ": missions paid, n skills: no offer of mission " .. (n + 1))
		lu.assertEquals(E.firstScreen(E.offerPilot(n)), "m" .. n .. "_offer", "n = " .. n .. ": mission n is offered")
	end

	-- mission n unpaid: n+1 skills held does not offer n+1 first
	local unpaid = E.pilot({ met = true, t4 = { 1, 2 }, paid = { 1 } })

	lu.assertEquals(E.firstScreen(unpaid), "m2_offer", "two skills, mission 2 unpaid: mission 2, not 3")
end

---------------------------------------------------------------------------------------------
-- Failures and re-grants on display (AC-6)
---------------------------------------------------------------------------------------------

TestUfwolFailures = {}

TestUfwolFailures.setUp = setUp
TestUfwolFailures.tearDown = tearDown

local FAILURE_STATES = { "failed_head", "aborted", "failed_a", "failed_b" }

-- AC-6: showing the failure screen sets :attempted and restarts mission n's head through startSpaceQuestChain exactly once, for every failure outcome
function TestUfwolFailures:test_the_failure_screen_restarts_its_mission_once_on_display()
	for n = 1, 4 do
		local states = FAILURE_STATES

		if n == 1 then
			states = { "failed_head", "aborted", "failed_a", "failed_b", "won_b", "failed_c" }
		end

		for _, state in ipairs(states) do
			H.reset()

			local player = E.rewardPilot(n, state)
			local t, chains, duties = walk(player, nil)

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed" }, "mission " .. n .. " " .. state .. ": first screen")
			lu.assertEquals(chains, { E.HEADS[n] }, "mission " .. n .. " " .. state .. ": the failure screen restarts the head once")
			lu.assertEquals(E.attempted(player, n), "1", "mission " .. n .. " " .. state .. ": :attempted")
			lu.assertEquals(duties, {}, "mission " .. n .. " " .. state .. ": no duty")
			lu.assertNil(E.paid(player, n), "mission " .. n .. " " .. state .. ": nothing paid")
			lu.assertEquals(player.bankCredits, 0, "mission " .. n .. " " .. state .. ": no credits")
			E.restore()
		end
	end
end

-- AC-6, I-5: both replies of each failure screen end on their JF line and start nothing more (the re-grant happened on display)
function TestUfwolFailures:test_both_replies_of_each_failure_screen_end_and_start_nothing()
	for n = 1, 4 do
		local failed = E.screenRow(E.MISSIONS[n].failed)

		lu.assertEquals(#failed.options, 2, "m" .. n .. "_failed has two replies")

		for i, o in ipairs(failed.options) do
			H.reset()

			local player = E.rewardPilot(n, "failed_head")
			local t, chains, duties = walk(player, { o[1] })

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed", E.MISSIONS[n].failedReplies[i] }, "mission " .. n .. ", reply " .. i .. ": the walk")
			lu.assertEquals(E.MISSIONS[n].failedReplies[i], o[2], "mission " .. n .. ", reply " .. i .. ": the closing screen of the oracle")
			lu.assertTrue(t[2].stop, "the closing screen ends the conversation")
			lu.assertEquals(chains, { E.HEADS[n] }, "mission " .. n .. ", reply " .. i .. ": the head started once, on display, and not again by the reply")
			lu.assertEquals(duties, {}, "mission " .. n .. ", reply " .. i .. ": no duty")
			lu.assertEquals(E.attempted(player, n), "1", "mission " .. n .. ", reply " .. i .. ": :attempted")
			lu.assertEquals(player.bankCredits, 0, "nothing paid")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end
end

-- AC-6: the closing screens of the failure replies are not start screens (nothing but the failure line itself re-grants)
function TestUfwolFailures:test_the_failure_lines_are_the_re_grant_carriers_and_their_replies_are_not()
	for n = 1, 4 do
		lu.assertEquals(E.START_SCREENS[E.MISSIONS[n].failed], n, "m" .. n .. "_failed starts mission " .. n)

		for _, id in ipairs(E.MISSIONS[n].failedReplies) do
			lu.assertNil(E.START_SCREENS[id], "closing screen " .. id .. " starts nothing")
		end
	end
end

-- AC-6: driving a closing screen directly starts nothing
function TestUfwolFailures:test_a_closing_screen_shown_alone_starts_nothing()
	for n = 1, 4 do
		for _, id in ipairs(E.MISSIONS[n].failedReplies) do
			H.reset()

			local chains = E.stubChainStarts()
			local spies = E.spyDuties()
			local player = E.rewardPilot(n, "failed_head")
			local before = E.snapshot(player)

			E.drive(player, id)
			lu.assertEquals(chains, {}, id .. ": no chain started")
			lu.assertEquals(E.startedDuties(spies), {}, id .. ": no duty started")
			lu.assertEquals(E.snapshot(player).status, before.status, id .. ": no key written")
			E.restore()
		end
	end
end

-- AC-6: with the real heads the mission runs after the display and the next talk is on_mission; the stale success child is cleared
function TestUfwolFailures:test_the_re_grant_makes_the_real_head_active_and_the_next_talk_is_on_mission()
	for n = 1, 4 do
		H.reset()
		E.startAll()

		local player = E.rewardPilot(n, "failed_a", { inShip = true, zone = E.MISSIONS[n].zone })

		E.talk(player)
		H.advance(0)
		lu.assertEquals(E.state(player, E.HEADS[n]), "active", E.HEADS[n] .. ": the journal entry after the display")
		lu.assertEquals(E.state(player, E.CHAINS[n][2]), "none", "the stale success child is cleared")
		lu.assertEquals(E.firstScreen(player), "on_mission", "mission " .. n .. ": the next talk")
	end
end

-- AC-6: a mission aborted from the datapad opens the failure screen and the display restarts it
function TestUfwolFailures:test_an_aborted_mission_is_restarted_by_the_failure_screen()
	for n = 1, 4 do
		H.reset()
		E.startAll()

		local player = E.offerPilot(n, { inShip = true, zone = E.MISSIONS[n].zone })

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		E.setState(player, E.HEADS[n], "active")
		E.quest(E.HEADS[n]):abortQuest(player)
		E.restore()
		lu.assertEquals(E.firstScreen(player), "m" .. n .. "_failed", "mission " .. n .. ": after the abort")
		H.advance(0)
		lu.assertEquals(E.state(player, E.HEADS[n]), "active", "mission " .. n .. ": restarted by the display")
	end
end

-- AC-6, I-8: the won outcomes are not failures
function TestUfwolFailures:test_the_won_outcomes_are_not_failures()
	for n = 1, 4 do
		local states = n == 1 and { "won_a", "won_c" } or { "won_a", "won_b" }

		for _, state in ipairs(states) do
			H.reset()
			E.stubChainStarts()
			lu.assertEquals(E.firstScreen(E.rewardPilot(n, state)), "m" .. n .. "_reward", "mission " .. n .. " " .. state)
		end
	end
end

-- AC-6: a failure shown while the chain is running cannot happen (on_mission comes first), and a start while active changes nothing
function TestUfwolFailures:test_the_failure_screen_shown_alone_while_the_chain_runs_does_not_start_a_second_run()
	for n = 1, 4 do
		H.reset()
		E.startAll()

		local player = E.rewardPilot(n, "active", { inShip = true, zone = E.MISSIONS[n].zone })
		local head = H.spyOn(E.quest(E.HEADS[n]), "startQuest")

		E.drive(player, E.MISSIONS[n].failed)
		lu.assertEquals(#head, 0, "mission " .. n .. ": startSpaceQuestChain refuses while the chain is active")
		lu.assertEquals(E.state(player, E.HEADS[n]), "active", "the running head stays")
	end
end
