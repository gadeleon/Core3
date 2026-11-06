-- Inquisitor Vrke: the four mission offers, the failure retries and the table-H starts.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-7; Conversation flow 3 (table H) and 4; Appendix A; HS D-6).
--
-- A start screen sets `naboo_imperial_tier3_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (J3 grantQuestN). The
-- walks are derived from Appendix A (the shortest reply path to each screen of the offer or failure subgraph), then driven through the handler.
-- The head's startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

V.load()

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, V.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n (the earlier missions done, their skills chosen, Barlow done)
local function readyFor(n, extra)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid, spoke = n >= 2 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return V.pilot(o)
end

-- Breadth-first search over the static links of Appendix A from `start`: id -> { ids = {screen ids from start}, replies = {reply sids} }
local function reach(start)
	local found = { [start] = { ids = { start }, replies = {} } }
	local queue = { start }

	while #queue > 0 do
		local id = table.remove(queue, 1)
		local cur = found[id]

		for _, o in ipairs(V.screenRow(id).options) do
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
		if V.START_SCREENS[id] == n then
			out[#out + 1] = id
		end
	end

	table.sort(out)
	return out
end

local function sortedCopy(list)
	local out = { table.unpack(list) }

	table.sort(out)
	return out
end

-- Talks through `choices` with a fresh pilot and the head spies; returns the transcript, the player and the heads started
local function walk(n, pilotOpts, choices)
	local spies = V.spyStarts()
	local player = readyFor(n, pilotOpts)
	local t = V.talk(player, choices)

	return t, player, V.started(spies)
end

---------------------------------------------------------------------------------------------
-- Offers
---------------------------------------------------------------------------------------------

TestInquisitionT3Offers = {}

TestInquisitionT3Offers.setUp = setUp

-- AC-7: each offer reaches exactly its accept screens (M1: 1, M2: 2, M3: 4, M4: 3)
function TestInquisitionT3Offers:test_each_offer_reaches_exactly_its_accept_screens()
	local want = {
		{ "m1_accept" },
		{ "m2_accept", "m2_accept_simple" },
		{ "m3_accept_bait", "m3_accept_dathomir", "m3_accept_die", "m3_accept_leave" },
		{ "m4_accept_accident", "m4_accept_accident_2", "m4_accept_casualty" },
	}

	for n = 1, 4 do
		lu.assertEquals(startsIn(reach(V.MISSIONS[n].offer), n), want[n], "mission " .. n .. ": accept screens reachable from " .. V.MISSIONS[n].offer .. " (the oracle graph)")
		lu.assertEquals(sortedCopy(V.MISSIONS[n].accepts), want[n], "precondition: the data module lists the accepts")
	end

	-- no offer reaches another mission's start, a training screen or a reward screen
	for n = 1, 4 do
		for id in pairs(reach(V.MISSIONS[n].offer)) do
			lu.assertTrue(V.START_SCREENS[id] == nil or V.START_SCREENS[id] == n, "offer " .. n .. " reaches the start of another mission: " .. id)
			lu.assertNil(V.TRAINING_SCREENS[id], "offer " .. n .. " reaches a training screen: " .. id)
		end
	end
end

-- AC-7: the start screens of table H are 18: 10 accepts (1 + 2 + 4 + 3) and 8 retries (3 + 2 + 1 + 2)
function TestInquisitionT3Offers:test_the_start_screens_are_the_accepts_and_retries_of_appendix_a()
	local n = 0

	for id, mission in pairs(V.START_SCREENS) do
		n = n + 1
		lu.assertNotNil(V.screenRow(id), id .. " is an Appendix A row")
		lu.assertTrue(V.screenRow(id).stop, id .. " ends the conversation")
		lu.assertEquals(#V.screenRow(id).options, 0, id .. " has no reply")
		lu.assertTrue(V.screenRow(id).notes:find("H: start M" .. mission, 1, true) ~= nil, id .. ": Appendix A says 'H: start M" .. mission .. "' (" .. V.screenRow(id).notes .. ")")
	end

	lu.assertEquals(n, 18, "start screens (table H)")

	local rows = 0

	for _, row in ipairs(V.SCREENS) do
		if row.notes:find("H: start M", 1, true) then
			rows = rows + 1
			lu.assertNotNil(V.START_SCREENS[row.id], row.id .. ": a row with 'H: start' is in the data module")
		end
	end

	lu.assertEquals(rows, 18, "Appendix A rows with 'H: start'")
end

for n = 1, 4 do
	local m = V.MISSIONS[n]
	local found = reach(m.offer)

	for _, accept in ipairs(startsIn(found, n)) do
		-- AC-7: the walk to the accept screen starts the mission there and nowhere before; the accept screen ends the conversation
		TestInquisitionT3Offers["test_the_walk_to_" .. accept .. "_starts_mission_" .. n .. "_on_the_accept_screen_only"] = function()
			local path = found[accept]

			for k = 1, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(n, nil, prefix)

				lu.assertEquals(V.ids(t), { table.unpack(path.ids, 1, k + 1) }, accept .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, accept .. ": nothing started before the accept screen (at " .. t[#t].id .. ")")
					lu.assertNil(attempted(player, n), accept .. ": no :attempted key before the accept screen (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { m.head }, accept .. ": the head started")
					lu.assertEquals(attempted(player, n), "1", accept .. ": the :attempted key")
					lu.assertTrue(t[#t].stop, accept .. " ends the conversation")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, accept .. ": client strings")
				end
			end
		end
	end
end

-- AC-7: no other screen of any offer subgraph grants anything
function TestInquisitionT3Offers:test_no_screen_of_an_offer_walk_but_the_accepts_starts_or_pays_anything()
	for n = 1, 4 do
		local found = reach(V.MISSIONS[n].offer)

		for _, id in ipairs(sortedKeys(found)) do
			if V.START_SCREENS[id] == nil then
				H.reset()

				local t, player, started = walk(n, nil, found[id].replies)

				lu.assertEquals(V.ids(t), found[id].ids, "offer " .. n .. ", to " .. id .. ": screens shown")
				lu.assertEquals(started, {}, "offer " .. n .. ", at " .. id .. ": quests started")
				lu.assertEquals(#V.free() + #V.bought(), 0, "offer " .. n .. ", at " .. id .. ": no skill granted")
				lu.assertEquals(#V.items(player), 0, "offer " .. n .. ", at " .. id .. ": no item")
				lu.assertEquals(player.bankCredits, 0, "offer " .. n .. ", at " .. id .. ": no credits")
			end
		end
	end
end

-- AC-7: the accept screen displayed directly (the engine's runScreenHandlers) starts the mission once and sets only its own key
function TestInquisitionT3Offers:test_displaying_an_accept_screen_starts_its_mission_exactly_once_and_sets_only_its_attempted_key()
	for screen, n in pairs(V.START_SCREENS) do
		H.reset()

		local spies = V.spyStarts()
		local player = readyFor(n)
		local before = {}

		for other = 1, 4 do
			before[other] = attempted(player, other)
		end

		V.drive(player, screen)
		lu.assertEquals(V.started(spies), { V.MISSIONS[n].head }, screen .. ": quests started")
		lu.assertEquals(attempted(player, n), "1", screen .. ": the :attempted key")

		for other = 1, 4 do
			if other ~= n then
				lu.assertEquals(attempted(player, other), before[other], screen .. ": mission " .. other .. " :attempted is unchanged")
			end
		end

		lu.assertEquals(#V.free() + #V.bought(), 0, screen .. ": no skill")
		lu.assertEquals(#V.items(player), 0, screen .. ": no item")
	end
end

-- AC-7: the offer alone starts nothing
function TestInquisitionT3Offers:test_each_offer_shown_alone_starts_nothing()
	for n = 1, 4 do
		H.reset()

		local t, player, started = walk(n, nil, {})

		lu.assertEquals(V.ids(t), { V.MISSIONS[n].offer }, "offer " .. n .. ": first screen")
		lu.assertEquals(started, {}, "offer " .. n .. ": quests started")
		lu.assertNil(attempted(player, n), "offer " .. n .. ": no :attempted key")
	end
end

-- AC-7: the next mission is not offered while the previous one's skill is unchosen
function TestInquisitionT3Offers:test_mission_n_plus_1_is_not_offered_while_the_skill_of_mission_n_is_unchosen()
	for n = 1, 3 do
		H.reset()

		local t3, paid = {}, {}

		for i = 1, n - 1 do
			t3[i] = i
			paid[i] = i
		end

		local first = V.firstScreen(V.pilot({ t3 = t3, paid = paid, mission = { [n] = "won" }, spoke = true }))

		lu.assertEquals(first, V.MISSIONS[n].reward, "mission " .. n .. " won, its skill unchosen: the reward comes before the next offer")
	end
end

-- AC-7: the real start in a ship makes the head active
function TestInquisitionT3Offers:test_the_real_start_makes_each_mission_head_active()
	for n, m in ipairs(V.MISSIONS) do
		for _, accept in ipairs(m.accepts) do
			H.reset()

			local id = V.IDENTITY[m.head]
			local player = readyFor(n, { inShip = true, zone = id.zone })

			V.quest(m.head):start()

			local ok, err = pcall(V.drive, player, accept)

			lu.assertTrue(ok, accept .. ": talking raised a Lua error: " .. tostring(err))
			H.advance(0)
			lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after " .. accept)
			lu.assertEquals(attempted(player, n), "1", accept .. ": the :attempted key")
		end
	end
end

---------------------------------------------------------------------------------------------
-- Failures and retries
---------------------------------------------------------------------------------------------

TestInquisitionT3Retries = {}

TestInquisitionT3Retries.setUp = setUp

-- AC-7: each failure screen reaches exactly its re-grant lines (M1: 3, M2: 2, M3: 1, M4: 2)
function TestInquisitionT3Retries:test_each_failure_screen_reaches_exactly_its_regrant_lines()
	local want = {
		{ "m1_retry_promise", "m1_retry_searching", "m1_retry_sooner" },
		{ "m2_retry_actions", "m2_retry_loyal" },
		{ "m3_retry" },
		{ "m4_retry_again", "m4_retry_excuses" },
	}

	for n = 1, 4 do
		lu.assertEquals(startsIn(reach(V.MISSIONS[n].failed), n), want[n], "mission " .. n .. ": re-grant lines reachable from " .. V.MISSIONS[n].failed)
		lu.assertEquals(sortedCopy(V.MISSIONS[n].retries), want[n], "precondition: the data module lists the retries")
	end
end

for n = 1, 4 do
	local m = V.MISSIONS[n]
	local found = reach(m.failed)

	-- AC-7: the failure line alone starts nothing
	TestInquisitionT3Retries["test_" .. m.failed .. "_shown_alone_starts_nothing"] = function()
		local t, _, started = walk(n, { mission = { [n] = "failed" } }, {})

		lu.assertEquals(V.ids(t), { m.failed }, m.failed .. " alone")
		lu.assertEquals(started, {}, m.failed .. ": quests started")
	end

	for _, retry in ipairs(startsIn(found, n)) do
		-- AC-7: every reply reaches a re-grant line that restarts the head; the line ends the conversation
		TestInquisitionT3Retries["test_" .. m.failed .. "_reaches_" .. retry .. "_which_restarts_mission_" .. n] = function()
			local path = found[retry]

			for k = 1, #path.replies do
				H.reset()

				local prefix = { table.unpack(path.replies, 1, k) }
				local t, player, started = walk(n, { mission = { [n] = "failed" } }, prefix)

				lu.assertEquals(V.ids(t), { table.unpack(path.ids, 1, k + 1) }, retry .. ": screens shown for the first " .. k .. " replies")

				if k < #path.replies then
					lu.assertEquals(started, {}, retry .. ": nothing restarted before the re-grant line (at " .. t[#t].id .. ")")
				else
					lu.assertEquals(started, { m.head }, retry .. ": the head restarted")
					lu.assertEquals(attempted(player, n), "1", retry .. ": the :attempted key stays set")
					lu.assertTrue(t[#t].stop, retry .. " ends the conversation")
					lu.assertEquals(#V.free() + #V.bought(), 0, retry .. ": no skill")
					lu.assertEquals(#V.items(player), 0, retry .. ": no item")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, retry .. ": client strings")
				end
			end
		end
	end
end

-- AC-7: a retry clears the stale members of the chain first
function TestInquisitionT3Retries:test_a_retry_clears_a_stale_chain_member_before_the_start()
	for n, m in ipairs(V.MISSIONS) do
		H.reset()
		V.spyStarts()

		local player = readyFor(n, { mission = { [n] = "partial" } })

		lu.assertEquals(V.state(player, m.head), "complete", "precondition: the head is a stale complete entry")
		V.drive(player, m.retries[#m.retries])
		lu.assertEquals(V.state(player, m.head), "none", "mission " .. n .. ": the stale head entry is cleared by the restart")
	end
end

-- AC-7: the real restart of a failed mission makes the head active again
function TestInquisitionT3Retries:test_the_real_retry_makes_each_mission_head_active()
	for n, m in ipairs(V.MISSIONS) do
		H.reset()

		local id = V.IDENTITY[m.head]
		local player = readyFor(n, { mission = { [n] = "partial" }, inShip = true, zone = id.zone })

		V.quest(m.head):start()

		local ok, err = pcall(V.drive, player, m.retries[#m.retries])

		lu.assertTrue(ok, m.retries[#m.retries] .. ": talking raised a Lua error: " .. tostring(err))
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after the retry")
	end
end

-- AC-7: a running chain is not restarted (startSpaceQuestChain refuses)
function TestInquisitionT3Retries:test_a_retry_does_not_restart_a_chain_that_is_running()
	local spies = V.spyStarts()
	local player = readyFor(1, { mission = { [1] = "active" } })

	V.drive(player, "m1_retry_searching")
	lu.assertEquals(V.started(spies), {}, "no start while a chain member is active")
end

-- AC-7: a failed mission in the middle of the chain (the end not complete) counts as failed; a won one does not
function TestInquisitionT3Retries:test_failed_means_attempted_and_not_won_and_not_running()
	local h = rawget(_G, V.HANDLER)

	for n = 1, 4 do
		lu.assertTrue(h:isFailed(readyFor(n, { mission = { [n] = "failed" } }), n), "mission " .. n .. " attempted only")
		lu.assertTrue(h:isFailed(readyFor(n, { mission = { [n] = "partial" } }), n), "mission " .. n .. " head complete, end not")
		lu.assertFalse(h:isFailed(readyFor(n, { mission = { [n] = "won" } }), n), "mission " .. n .. " won")
		lu.assertFalse(h:isFailed(readyFor(n, { mission = { [n] = "active" } }), n), "mission " .. n .. " running")
		lu.assertFalse(h:isFailed(readyFor(n, { mission = { [n] = "endonly" } }), n), "mission " .. n .. " chain end complete without :attempted: won, not failed")
		lu.assertFalse(h:isFailed(readyFor(n), n), "mission " .. n .. " never started")
		lu.assertTrue(h:isWon(readyFor(n, { mission = { [n] = "endonly" } }), n), "mission " .. n .. ": the chain end complete is a win (SWG hasCompletedQuestRecursive)")
		lu.assertFalse(h:isWon(readyFor(n, { mission = { [n] = "partial" } }), n), "mission " .. n .. ": the head complete is not a win")
	end
end
