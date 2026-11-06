-- Captain Denner: the four mission offers, the failure re-grants and the table-H starts.
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-4; Conversation flow 1 (G9-G12, G17-G20) and 3 (table H); Data mapping 1 and 2; Appendix A; D-14).
--
-- A start screen sets `tatooine_imperial_tier3_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (J3 grantQuestN). The walks
-- are derived from Appendix A (the shortest reply path to each screen of the offer or failure subgraph), then driven through the handler. The heads'
-- startQuest is spied (H.spyOn does not call the original) except in the "real start" test, which runs it in a ship.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, D.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n: the earlier missions won and paid, their skills chosen
local function readyFor(n, extra)
	local o = { missions = n - 1, t3 = D.t3(n - 1) }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

-- Spies startQuest on all 20 Denner quest tables; returns the call lists by global
local function spyStarts()
	local starts = {}

	for _, g in ipairs(D.GLOBALS) do
		starts[g] = H.spyOn(D.quest(g), "startQuest")
	end

	return starts
end

-- "global xN" strings of the quests whose startQuest was called
local function startedGlobals(starts)
	local out = {}

	for _, g in ipairs(D.GLOBALS) do
		if #starts[g] > 0 then
			out[#out + 1] = g .. " x" .. #starts[g]
		end
	end

	return out
end

-- Breadth-first search over the static links of Appendix A from `start`: id -> { ids = {screen ids from start}, replies = {reply sids} }
local function reach(start)
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local id = table.remove(queue, 1)
		local cur = found[id]

		for _, o in ipairs(D.screenRow(id).options) do
			if found[o[2]] == nil then
				local ids, replies = { table.unpack(cur.ids) }, { table.unpack(cur.replies) }

				ids[#ids + 1] = o[2]
				replies[#replies + 1] = o[1]
				found[o[2]] = { ids = ids, replies = replies }
				queue[#queue + 1] = o[2]
			end
		end
	end

	return found
end

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

-- the start screens of mission n that are reachable in `found`
local function startsIn(found, n)
	local out = {}

	for id in pairs(found) do
		if D.START_SCREENS[id] == n then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

-- Talks through `choices` with a fresh pilot and the head spies; returns the transcript, the player and the heads started
local function walk(player, choices)
	local spies = spyStarts()
	local t = D.talk(player, choices)

	return t, player, startedGlobals(spies)
end

---------------------------------------------------------------------------------------------
-- Table H, the data
---------------------------------------------------------------------------------------------

TestStormT3Offers = {}

TestStormT3Offers.setUp = setUp

-- B-4 (the oracle): each offer reaches exactly its grant screens (M1: 2, M2: 2, M3: 3, M4: 3)
function TestStormT3Offers:test_each_offer_reaches_exactly_its_accept_screens()
	local want = {
		{ "m1_accept", "m1_assignment" },
		{ "m2_accept", "m2_accept_promise" },
		{ "m3_accept", "m3_accept_half", "m3_accept_smite" },
		{ "m4_accept", "m4_accept_blessing", "m4_accept_confident" },
	}

	for n = 1, 4 do
		lu.assertEquals(startsIn(reach(D.MISSIONS[n].offer), n), want[n], "mission " .. n .. ": grant screens reachable from " .. D.MISSIONS[n].offer .. " (the oracle graph)")
	end

	for n = 1, 4 do
		for id in pairs(reach(D.MISSIONS[n].offer)) do
			lu.assertTrue(D.START_SCREENS[id] == nil or D.START_SCREENS[id] == n, "offer " .. n .. " reaches the start of another mission: " .. id)
			lu.assertNil(D.TRAINING_SCREENS[id], "offer " .. n .. " reaches a training screen: " .. id)
			lu.assertNil(D.REWARD_SCREENS[id], "offer " .. n .. " reaches a reward screen: " .. id)
		end
	end
end

-- B-4 (the oracle): table H has 19 start screens (6 + 4 + 5 + 4) and 4 reward screens
function TestStormT3Offers:test_table_h_lists_19_start_screens_and_4_reward_screens()
	local n, perMission = 0, { 0, 0, 0, 0 }

	for id, mission in pairs(D.START_SCREENS) do
		n = n + 1
		perMission[mission] = perMission[mission] + 1
		lu.assertNotNil(D.screenRow(id), id .. " is an Appendix A row")
	end

	lu.assertEquals(n, 19, "start screens (table H)")
	lu.assertEquals(perMission, { 6, 4, 5, 4 }, "start screens per mission")

	local pays = {}

	for id, mission in pairs(D.REWARD_SCREENS) do
		pays[mission] = id
	end

	lu.assertEquals(pays, { "m1_reward", "m2_reward", "m3_reward", "m4_reward" }, "reward screens")
end

-- B-4: m1_accept and m1_assignment are not ending screens (J3 grants on the NPC line); the other offers' grant screens end the conversation
function TestStormT3Offers:test_m1_accept_and_m1_assignment_do_not_end_the_conversation_the_other_grant_screens_do()
	for id, mission in pairs(D.START_SCREENS) do
		local row = D.screenRow(id)

		if id == "m1_accept" or id == "m1_assignment" then
			lu.assertFalse(row.stop, id .. " does not end the conversation")
			lu.assertEquals(#row.options, 3, id .. " offers three closing replies")
		else
			lu.assertTrue(row.stop, id .. " ends the conversation")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Offers: each walk grants on the grant screen and nowhere before
---------------------------------------------------------------------------------------------

for n = 1, 4 do
	local m = D.MISSIONS[n]
	local found = reach(m.offer)

	for _, accept in ipairs(startsIn(found, n)) do
		-- B-4: the walk to the grant screen starts the mission there and nowhere before
		TestStormT3Offers["test_the_walk_to_" .. accept .. "_starts_mission_" .. n .. "_on_the_grant_screen_only"] = function()
			local path = found[accept]

			for k = 1, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(readyFor(n), prefix)

				lu.assertEquals(D.ids(t), { table.unpack(path.ids, 1, k + 1) }, accept .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, accept .. ": nothing started before the grant screen (at " .. t[#t].id .. ")")
					lu.assertNil(attempted(player, n), accept .. ": no :attempted key before the grant screen (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { m.head .. " x1" }, accept .. ": the head started once")
					lu.assertEquals(attempted(player, n), "1", accept .. ": the :attempted key")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, accept .. ": client strings")
				end
			end
		end
	end
end

-- B-4: no other screen of any offer subgraph grants anything. A screen after a grant screen (the closing lines of m1_accept and m1_assignment) shows the one
-- grant of the walk and nothing more.
function TestStormT3Offers:test_no_screen_of_an_offer_walk_but_the_grant_screens_starts_or_pays_anything()
	for n = 1, 4 do
		local found = reach(D.MISSIONS[n].offer)

		for _, id in ipairs(sortedKeys(found)) do
			if D.START_SCREENS[id] == nil then
				H.reset()

				local path = found[id]
				local t, player, started = walk(readyFor(n), path.replies)
				local granted = false

				for _, shown in ipairs(path.ids) do
					granted = granted or D.START_SCREENS[shown] ~= nil
				end

				lu.assertEquals(D.ids(t), path.ids, id .. ": the walk")
				lu.assertEquals(started, granted and { D.MISSIONS[n].head .. " x1" } or {}, id .. ": " .. (granted and "only the earlier grant started" or "nothing started"))

				for k = 1, 4 do
					lu.assertEquals(attempted(player, k), (k < n or (granted and k == n)) and "1" or nil, id .. ": :attempted of mission " .. k .. " (the earlier missions are paid)")
				end

				lu.assertEquals(#D.free() + #D.bought(), 0, id .. ": no skill granted")
				lu.assertEquals(player.bankCredits, 0, id .. ": no credits")
				lu.assertEquals(#D.items(player), 0, id .. ": no item")
			end
		end
	end
end

-- B-4: the NGE slots Data mapping 2 replaces (the three new screens and every rejoined link) still reach their grant screens
function TestStormT3Offers:test_every_rejoined_offer_screen_is_on_a_walk_to_a_grant_screen()
	local rejoined = {
		{ 1, "m1_offer_ego" }, { 1, "m1_offer_88d2aba6" }, { 1, "m1_offer_9511fbeb" }, { 1, "m1_offer_b8fba9bb" }, { 1, "m1_offer_d55771c4" },
		{ 1, "m1_offer_8ace66c8" }, { 1, "m1_offer_666d4e98" }, { 1, "m1_offer_b6b37d2c" }, { 1, "m1_offer_4ca34e11" },
		{ 2, "m2_offer_report" }, { 2, "m2_offer_leak" }, { 2, "m2_offer_f51fd3ee" }, { 2, "m2_offer_4b2d23bc" }, { 2, "m2_offer_1bc2db0c" }, { 2, "m2_offer_558af4fe" },
		{ 3, "m3_offer_d8c02b03" }, { 4, "m4_offer_b196e01f" },
	}

	for _, r in ipairs(rejoined) do
		local n, id = r[1], r[2]
		local toIt = reach(D.MISSIONS[n].offer)[id]

		lu.assertNotNil(toIt, id .. ": reachable from " .. D.MISSIONS[n].offer)

		local onward = reach(id)
		local grants = startsIn(onward, n)

		lu.assertTrue(#grants > 0, id .. ": a grant screen of mission " .. n .. " is reachable onward")

		-- drive the offer walk to the screen and then onward to the first grant screen
		local replies = { table.unpack(toIt.replies) }

		for _, reply in ipairs(onward[grants[1]].replies) do
			replies[#replies + 1] = reply
		end

		local t, player, started = walk(readyFor(n), replies)

		lu.assertEquals(t[#t].id, grants[1], id .. ": the walk ends on " .. grants[1])
		lu.assertEquals(started, { D.MISSIONS[n].head .. " x1" }, id .. ": mission " .. n .. " started")
		lu.assertEquals(attempted(player, n), "1", id .. ": :attempted")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, id .. ": client strings")
	end
end

-- B-4: the first meeting greeting (m1_offer) has three attitudes, one of them the boastful branch through the new m1_offer_ego line
function TestStormT3Offers:test_the_first_meeting_offers_three_attitudes_and_the_boastful_one_leads_to_the_ego_line()
	local t = D.talk(D.pilot({}), { "s_9ae62db" })

	lu.assertEquals(D.ids(t), { "m1_offer", "m1_offer_ego" }, "boastful branch")
	lu.assertEquals(#t[1].options, 3, "three attitudes")
	lu.assertEquals(t[2].text, D.PREFIX .. "s_5e3cc3ae", "'Alozen did mention to me that you had a slight ego...'")
	lu.assertEquals(D.optionSids(t[2]), { "s_e374b3bf", "s_c5320bec" }, "the ego line's two replies")
end

---------------------------------------------------------------------------------------------
-- Real start in a ship
---------------------------------------------------------------------------------------------

-- B-4: really started, the head's journal entry is active (a ship in space_endor)
function TestStormT3Offers:test_the_grant_screens_leave_the_head_journal_entry_active_in_a_ship_in_endor()
	for n, screen in ipairs({ "m1_accept", "m2_accept", "m3_accept", "m4_accept" }) do
		H.reset()

		for _, g in ipairs(D.GLOBALS) do
			D.quest(g):start()
		end

		local player = readyFor(n, { inShip = true, zone = D.ZONE })
		local ok, err = pcall(function()
			D.drive(player, screen)
			H.advance(0)
		end)

		lu.assertTrue(ok, screen .. ": raised a Lua error: " .. tostring(err))
		lu.assertEquals(D.state(player, D.MISSIONS[n].head), "active", screen .. ": the journal entry of " .. D.MISSIONS[n].head)
		lu.assertEquals(attempted(player, n), "1", screen .. ": :attempted")
	end
end

-- B-4: a second visit to a grant screen while the chain runs does not start it twice
function TestStormT3Offers:test_a_grant_screen_shown_while_the_chain_is_running_does_not_restart_it()
	H.reset()

	for _, g in ipairs(D.GLOBALS) do
		D.quest(g):start()
	end

	local player = readyFor(1, { inShip = true, zone = D.ZONE })

	D.drive(player, "m1_accept")
	H.advance(0)

	local spies = spyStarts()

	D.drive(player, "m1_accept")
	lu.assertEquals(startedGlobals(spies), {}, "the head is active: startSpaceQuestChain refuses")
end

---------------------------------------------------------------------------------------------
-- Failures and re-grants
---------------------------------------------------------------------------------------------

for n = 1, 3 do
	local m = D.MISSIONS[n]
	local found = reach(m.failed)

	assert(#startsIn(found, n) > 0, "oracle: " .. m.failed .. " reaches a re-grant line")

	for _, regrant in ipairs(startsIn(found, n)) do
		-- B-4: the failure dialogue restarts the head on the re-grant line only
		TestStormT3Offers["test_the_walk_from_" .. m.failed .. "_to_" .. regrant .. "_restarts_mission_" .. n .. "_on_the_re_grant_line_only"] = function()
			local path = found[regrant]

			for k = 0, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(D.pilot({ missions = n - 1, t3 = D.t3(n - 1), failed = n }), prefix)

				lu.assertEquals(D.ids(t), { table.unpack(path.ids, 1, k + 1) }, regrant .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, regrant .. ": nothing restarted before the re-grant line (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { m.head .. " x1" }, regrant .. ": the head restarted once")
					lu.assertEquals(attempted(player, n), "1", regrant .. ": :attempted")
					lu.assertTrue(t[#t].stop, regrant .. " ends the conversation")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, regrant .. ": client strings")
				end
			end
		end
	end

	-- B-4: every reply of the failure subgraph ends on a re-grant line (no dead end, no other ending)
	TestStormT3Offers["test_every_ending_of_the_" .. m.failed .. "_dialogue_is_a_re_grant_line"] = function()
		for id, path in pairs(found) do
			local row = D.screenRow(id)

			if row.stop then
				lu.assertEquals(D.START_SCREENS[id], n, id .. ": an ending of the failure dialogue of mission " .. n .. " restarts it")
			end
		end
	end
end

-- B-4: m4_failed restarts the head as soon as it is shown
function TestStormT3Offers:test_m4_failed_restarts_mission_4_on_display()
	local t, player, started = walk(D.pilot({ missions = 3, t3 = D.t3(3), failed = 4 }), nil)

	lu.assertEquals(D.ids(t), { "m4_failed" }, "first screen")
	lu.assertTrue(t[1].stop, "m4_failed ends the conversation")
	lu.assertEquals(started, { D.MISSIONS[4].head .. " x1" }, "mission 4 restarted on display")
	lu.assertEquals(attempted(player, 4), "1", ":attempted")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_430701b", "'Your job's not done yet.'")
end

-- B-4: the first screens of the three failures say what the spec says
function TestStormT3Offers:test_the_failure_greetings_are_the_j3_lines()
	local want = { "s_599cef6e", "s_d1fb3414", "s_c70eec74" }

	for n = 1, 3 do
		local t = D.talk(D.pilot({ missions = n - 1, t3 = D.t3(n - 1), failed = n }))

		lu.assertEquals(D.ids(t), { D.MISSIONS[n].failed }, "failure " .. n)
		lu.assertEquals(t[1].text, D.PREFIX .. want[n], "failure " .. n .. " line")
		lu.assertFalse(t[1].stop, "m" .. n .. "_failed offers replies")
	end
end

-- B-4: after the re-grant the chain runs, so the next talk is on_mission; a failed mission is restarted, not marked won
function TestStormT3Offers:test_after_a_re_grant_the_head_runs_and_the_next_talk_is_on_mission()
	H.reset()

	for _, g in ipairs(D.GLOBALS) do
		D.quest(g):start()
	end

	local player = D.pilot({ missions = 3, t3 = D.t3(3), failed = 4, inShip = true, zone = D.ZONE })

	D.talk(player)
	H.advance(0)
	lu.assertEquals(D.state(player, D.MISSIONS[4].head), "active", "m4_failed restarted the head")
	lu.assertEquals(D.firstScreen(player), "on_mission", "the next talk")
end

---------------------------------------------------------------------------------------------
-- The count rule
---------------------------------------------------------------------------------------------

-- B-4: mission n+1 is not offered while mission n's skill is unchosen
function TestStormT3Offers:test_mission_n_plus_1_is_not_offered_while_mission_ns_skill_is_unchosen()
	for n = 1, 3 do
		local player = D.pilot({ missions = n, t3 = D.t3(n - 1) })
		local first = D.firstScreen(player)

		lu.assertEquals(first, "m" .. n .. "_reward", "mission " .. n .. " paid, skill unchosen: the reward screen, not m" .. (n + 1) .. "_offer")
	end
end
