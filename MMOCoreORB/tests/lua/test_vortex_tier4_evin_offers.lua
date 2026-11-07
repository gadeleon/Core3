-- Brother Extok Evin: the four mission offers, every briefing walk to an accept line, the start screens, the failure re-grants (AC-5, AC-6).
-- Spec: .claude/work/vortex-tier4-extok-evin-convo/01-spec.md (AC-5, AC-6; Conversation flow 1 (E8-E11, E17-E20) and 3 (table H); Data mapping 2; Appendix A and D; FE-2, FE-5; I-5, I-8; Q-B3 = A).
--
-- A start screen sets `naboo_rebel_tier4_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (J4 grantMissionN). The walks are derived from
-- Appendix A (the shortest reply path to each screen of the offer subgraph) and from Appendix D (one path per accept screen route), then driven through the handler. The
-- chain start is recorded and not run (E.stubChainStarts) except in the "real start" tests, which run it in a ship. The duty globals' startQuest is spied.

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
		if E.START_SCREENS[id] == n then
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

TestEvinOffers = {}

TestEvinOffers.setUp = setUp
TestEvinOffers.tearDown = tearDown

-- AC-5 (the oracle): each offer reaches exactly its accept screens (M1: 1, M2: 1, M3: 2, M4: 1) and no other mission's start, no reward, duty or meeting screen
function TestEvinOffers:test_each_offer_reaches_exactly_its_accept_screens()
	local want = { { "m1_accept_df1c8925" }, { "m2_accept_4eaf90e6" }, { "m3_accept_4e0bf82f", "m3_accept_dd76100c" }, { "m4_accept_122f0ea4" } }

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

-- AC-5 (the oracle): Appendix D's paths are walks of the static links, and there are 2 routes per mission
function TestEvinOffers:test_appendix_d_names_two_routes_per_mission_and_each_is_a_walk_of_the_static_links()
	local perMission = { 0, 0, 0, 0 }

	for i, path in ipairs(E.OFFER_PATHS) do
		local ids = E.follow(E.MISSIONS[path.mission].offer, path.replies)

		lu.assertNotNil(ids, "path " .. i .. ": every reply is on its screen")
		lu.assertEquals(ids[#ids], path.accept, "path " .. i .. ": ends on its accept screen")
		perMission[path.mission] = perMission[path.mission] + 1
	end

	lu.assertEquals(perMission, { 2, 2, 2, 2 }, "routes per mission")
end

-- AC-5: every Appendix D route, driven through the handler, reaches its accept screen, which ends and starts the mission once
function TestEvinOffers:test_every_appendix_d_route_reaches_its_accept_screen_and_starts_the_mission_once()
	for i, path in ipairs(E.OFFER_PATHS) do
		H.reset()

		local n = path.mission
		local player = E.offerPilot(n)
		local t, chains, duties = walk(player, path.replies)
		local want = E.follow(E.MISSIONS[n].offer, path.replies)

		lu.assertEquals(E.ids(t), want, "route " .. i .. ": screens shown")
		lu.assertEquals(t[#t].id, path.accept, "route " .. i .. ": the accept screen")
		lu.assertTrue(t[#t].stop, "route " .. i .. ": the accept screen ends the conversation")
		lu.assertEquals(chains, { E.HEADS[n] }, "route " .. i .. ": the head started once")
		lu.assertEquals(E.attempted(player, n), "1", "route " .. i .. ": :attempted")
		lu.assertEquals(duties, {}, "route " .. i .. ": no duty started")
		lu.assertEquals(player.bankCredits, 0, "route " .. i .. ": nothing paid")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "route " .. i .. ": client strings")
		E.restore()
	end
end

-- AC-5, Data mapping 2: every link of every offer's briefing (the rejoined [R], twin [T] and reused [b] links included) is walkable from the first screen; a quest starts
-- only on the last screen of a walk that ends on an accept screen, and exactly once
function TestEvinOffers:test_every_link_of_every_briefing_is_walkable_and_only_an_accept_screen_starts_the_mission()
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

				if E.START_SCREENS[o[2]] == n then
					lu.assertEquals(chains, { E.HEADS[n] }, label .. ": the head started once, on the accept screen")
					lu.assertTrue(t[#t].stop, label .. ": the accept screen ends the conversation")
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

-- AC-5: every screen of an offer subgraph is on a walk to one of its accept screens (no dead end)
function TestEvinOffers:test_every_screen_of_an_offer_subgraph_leads_to_an_accept_screen()
	for n = 1, 4 do
		local accepts = E.MISSIONS[n].accepts

		for id in pairs(E.reach(E.MISSIONS[n].offer)) do
			local found = E.reach(id)
			local ok = false

			for _, accept in ipairs(accepts) do
				ok = ok or found[accept] ~= nil
			end

			lu.assertTrue(ok, "mission " .. n .. ": screen '" .. id .. "' leads to an accept screen")
		end
	end
end

-- AC-5: the first meeting's roster and the offers are independent: an offer's first screen is the J4 line, with the first name where the line has it
function TestEvinOffers:test_the_offer_screens_show_the_first_name_only_on_the_first_offer_and_m2_d8a1ee7e()
	local t = E.talk(E.offerPilot(1))

	lu.assertEquals(t[1].params.TU, "Ace", "m1_offer: %NU")

	for n = 2, 4 do
		H.reset()
		lu.assertNil(E.talk(E.offerPilot(n))[1].params.TU, "m" .. n .. "_offer: no token")
	end
end

-- AC-5: each accept screen sets that mission's :attempted and only it
function TestEvinOffers:test_each_accept_screen_sets_its_attempted_key_and_nothing_else()
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
function TestEvinOffers:test_the_accept_screens_leave_the_head_journal_entry_active_and_clear_a_stale_run_of_both_branches()
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
function TestEvinOffers:test_a_start_screen_shown_while_the_chain_is_running_does_not_restart_it()
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
function TestEvinOffers:test_after_an_accept_the_next_talk_is_on_mission()
	E.startAll()

	local player = E.offerPilot(1, { inShip = true, zone = E.MISSIONS[1].zone })

	E.talk(player, E.OFFER_PATHS[2].replies)
	H.advance(0)
	lu.assertEquals(E.state(player, E.HEADS[1]), "active", "the head runs")
	lu.assertEquals(E.firstScreen(player), "on_mission", "the next talk")
end

-- AC-5: mission n+1 is not offered while mission n's skill is the last one held or mission n is paid with fewer than n+1 skills
function TestEvinOffers:test_mission_n_plus_1_is_not_offered_with_n_skills()
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
end

---------------------------------------------------------------------------------------------
-- Failures and re-grants (AC-6)
---------------------------------------------------------------------------------------------

TestEvinFailures = {}

TestEvinFailures.setUp = setUp
TestEvinFailures.tearDown = tearDown

-- AC-6: the failure screen starts nothing and sets nothing on display, for every failure outcome
function TestEvinFailures:test_the_failure_screen_starts_nothing_on_display()
	for n = 1, 4 do
		for _, state in ipairs({ "failed_head", "aborted", "failed_a", "failed_b" }) do
			H.reset()

			local player = E.rewardPilot(n, state)
			local before = E.snapshot(player)
			local t, chains, duties = walk(player, nil)

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed" }, "mission " .. n .. " " .. state .. ": first screen")
			lu.assertEquals(chains, {}, "mission " .. n .. " " .. state .. ": the failure screen starts no chain")
			lu.assertEquals(duties, {}, "mission " .. n .. " " .. state .. ": no duty")
			lu.assertEquals(E.snapshot(player).status, before.status, "mission " .. n .. " " .. state .. ": no key written")
			E.restore()
		end
	end
end

-- AC-6: both replies of each failure screen reach a retry screen that restarts mission n's head and ends
function TestEvinFailures:test_both_replies_of_each_failure_screen_restart_the_mission_and_end()
	for n = 1, 4 do
		local failed = E.screenRow(E.MISSIONS[n].failed)

		lu.assertEquals(#failed.options, 2, "m" .. n .. "_failed has two replies")

		for i, o in ipairs(failed.options) do
			H.reset()

			local player = E.rewardPilot(n, "failed_head")
			local t, chains, duties = walk(player, { o[1] })

			lu.assertEquals(E.ids(t), { "m" .. n .. "_failed", E.MISSIONS[n].retries[i] }, "mission " .. n .. ", reply " .. i .. ": the walk")
			lu.assertEquals(E.MISSIONS[n].retries[i], o[2], "mission " .. n .. ", reply " .. i .. ": the retry screen of the oracle")
			lu.assertTrue(t[2].stop, "the retry screen ends the conversation")
			lu.assertEquals(chains, { E.HEADS[n] }, "mission " .. n .. ", reply " .. i .. ": the head restarted once")
			lu.assertEquals(duties, {}, "mission " .. n .. ", reply " .. i .. ": no duty")
			lu.assertEquals(E.attempted(player, n), "1", "mission " .. n .. ", reply " .. i .. ": :attempted")
			lu.assertEquals(player.bankCredits, 0, "nothing paid")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
			E.restore()
		end
	end
end

-- AC-6, Q-B3 = A: s_d4928d9c on m2_failed restarts assassinate_naboo_rebel_tier4_2 and starts no duty (J4 started the escort duty here)
function TestEvinFailures:test_the_second_reply_of_m2_failed_restarts_mission_2_and_starts_no_duty()
	local player = E.rewardPilot(2, "failed_head")
	local t, chains, duties = walk(player, { "s_d4928d9c" })

	lu.assertEquals(E.ids(t), { "m2_failed", "m2_retry_13010c2d" }, "the walk")
	lu.assertEquals(t[2].text, E.PREFIX .. "s_13010c2d", "'You say that, but he's still safely en route! Hurry up and...'")
	lu.assertEquals(chains, { "assassinate_naboo_rebel_tier4_2" }, "mission 2's head restarted")
	lu.assertEquals(duties, {}, "the escort duty is not started (Q-B3 = A)")
	lu.assertEquals(E.attempted(player, 2), "1", ":attempted")
end

-- AC-6: the retry screens are start screens and nothing else starts a mission (the retry lines are the re-grant carriers)
function TestEvinFailures:test_the_retry_screens_are_the_start_screens_of_the_failure_replies()
	for n = 1, 4 do
		for _, id in ipairs(E.MISSIONS[n].retries) do
			lu.assertEquals(E.START_SCREENS[id], n, "retry screen " .. id .. " starts mission " .. n)
		end
	end
end

-- AC-6: with the real heads the mission runs after the re-grant and the next talk is on_mission, for every reply
function TestEvinFailures:test_the_re_grant_makes_the_real_head_active_and_the_next_talk_is_on_mission()
	for n = 1, 4 do
		for i, o in ipairs(E.screenRow(E.MISSIONS[n].failed).options) do
			H.reset()
			E.startAll()

			local player = E.rewardPilot(n, "failed_a", { inShip = true, zone = E.MISSIONS[n].zone })

			E.talk(player, { o[1] })
			H.advance(0)
			lu.assertEquals(E.state(player, E.HEADS[n]), "active", E.HEADS[n] .. ": the journal entry after the re-grant (reply " .. i .. ")")
			lu.assertEquals(E.state(player, E.CHAINS[n][2]), "none", "the stale success child is cleared")
			lu.assertEquals(E.firstScreen(player), "on_mission", "mission " .. n .. ": the next talk")
		end
	end
end

-- AC-6: a mission aborted from the datapad opens the failure screen and the re-grant works
function TestEvinFailures:test_an_aborted_mission_can_be_restarted_from_the_failure_screen()
	for n = 1, 4 do
		H.reset()
		E.startAll()

		local player = E.offerPilot(n, { inShip = true, zone = E.MISSIONS[n].zone })

		H.setQuestStatus(player, E.STATUS[n] .. ":attempted", "1")
		E.setState(player, E.HEADS[n], "active")
		E.quest(E.HEADS[n]):abortQuest(player)
		lu.assertEquals(E.firstScreen(player), "m" .. n .. "_failed", "mission " .. n .. ": after the abort")
		E.talk(player, { E.screenRow(E.MISSIONS[n].failed).options[1][1] })
		H.advance(0)
		lu.assertEquals(E.state(player, E.HEADS[n]), "active", "mission " .. n .. ": restarted after the abort")
	end
end

-- AC-6, I-8: a failure child that failed after a won head, a failed head, a failed failure child: all show the failure; the won outcomes do not
function TestEvinFailures:test_the_won_outcomes_are_not_failures()
	for n = 1, 4 do
		for _, state in ipairs({ "won_a", "won_b" }) do
			H.reset()
			lu.assertEquals(E.firstScreen(E.rewardPilot(n, state)), "m" .. n .. "_reward", "mission " .. n .. " " .. state)
		end
	end

	lu.assertEquals(E.firstScreen(E.rewardPilot(2, "won_b_c_failed")), "m2_reward", "2_b won, 2_c failed (D-3)")
end
