-- Ja'ce Yiaso: the four mission briefs and grants, and the failure retries (table H starts).
-- Spec: .claude/work/inquisition-tier4-jace-yiaso/01-spec.md (AC-8, AC-5; Conversation flow 3; Appendix A and D; D-10).
--
-- A start screen sets `naboo_imperial_tier4_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head. The head's
-- startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local J4 = require("inquisition_tier4_data")
local CS = require("harness.client_strings")

J4.load()

local function setUp()
	H.reset()
	J4.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, J4.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n: n - 1 missions done (paid), n skills (the ready prompt shows for mission n)
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

	return J4.pilot(o)
end

local function failedPilot(n, extra)
	local o = { mission = { [n] = "failed" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return readyFor(n, o)
end

local function shorter(list)
	local out = {}

	for i = 1, #list - 1 do
		out[i] = list[i]
	end

	return out
end

---------------------------------------------------------------------------------------------
-- The briefs and the grants (Appendix D)
---------------------------------------------------------------------------------------------

TestInquisitionT4Grants = {}

TestInquisitionT4Grants.setUp = setUp

local ACCEPTS, RETRIES, PAYS = {}, {}, {}

for _, p in ipairs(J4.PATHS) do
	local n = tonumber(p.kind:match("(%d)$"))

	if p.kind:match("^pay") then
		PAYS[#PAYS + 1] = p
	elseif p.grant:find("retry", 1, true) then
		RETRIES[#RETRIES + 1] = p
	else
		ACCEPTS[#ACCEPTS + 1] = p
	end

	p.n = n
end

for i, w in ipairs(ACCEPTS) do
	-- AC-8: the walk from the brief to the grant starts exactly its mission once, sets only its attempted key, pays nothing
	TestInquisitionT4Grants["test_walk_" .. i .. "_" .. w.grant .. "_starts_mission_" .. w.n .. "_once"] = function()
		local head = J4.MISSIONS[w.n].head
		local spies = J4.spyStarts()
		local player = readyFor(w.n)
		local before = {}

		for m = 1, 4 do
			before[m] = attempted(player, m)
		end

		local t = J4.drive(player, w.from, w.replies)

		lu.assertEquals(t[1].id, w.from, "the walk starts on " .. w.from)
		lu.assertEquals(t[#t].id, w.grant, "the walk ends on " .. w.grant)
		lu.assertTrue(t[#t].stop, w.grant .. " ends the conversation")
		lu.assertEquals(attempted(player, w.n), "1", "naboo_imperial_tier4_" .. w.n .. ":attempted")
		lu.assertEquals(J4.started(spies), { head }, "quests started")
		lu.assertEquals(#spies[head], 1, head .. ": startQuest calls")
		lu.assertEquals(player.bankCredits, 0, "nothing paid")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")

		for m = 1, 4 do
			if m ~= w.n then
				lu.assertEquals(attempted(player, m), before[m], "mission " .. m .. ": the walk leaves its attempted key alone")
			end
		end
	end

	-- AC-8: the screens before the grant start nothing and pay nothing
	TestInquisitionT4Grants["test_walk_" .. i .. "_no_screen_before_" .. w.grant .. "_starts_or_pays_anything"] = function()
		local spies = J4.spyStarts()
		local player = readyFor(w.n)
		local t = J4.drive(player, w.from, shorter(w.replies))

		lu.assertNotEquals(t[#t].id, w.grant, "the shorter walk stops before the grant")
		lu.assertEquals(J4.started(spies), {}, "quests started")
		lu.assertNil(attempted(player, w.n), "no attempted key before the grant")
		lu.assertEquals(player.bankCredits, 0, "nothing paid")
	end
end

-- AC-8: the trained openings lead along the same paths (the first reply of M1's trained opening is its own line)
function TestInquisitionT4Grants:test_every_accept_path_also_works_from_the_trained_opening()
	local count = 0

	for _, w in ipairs(ACCEPTS) do
		H.reset()

		local m = J4.MISSIONS[w.n]
		local replies = {}

		for i, r in ipairs(w.replies) do
			replies[i] = r
		end

		if w.n == 1 and replies[1] == "s_a3958e6a" then
			replies[1] = "s_b3a26c61"
		end

		local spies = J4.spyStarts()
		local t = J4.drive(readyFor(w.n), m.briefTrained, replies)

		lu.assertEquals(t[#t].id, w.grant, m.briefTrained .. ": the walk ends on " .. w.grant)
		lu.assertEquals(J4.started(spies), { m.head }, m.briefTrained .. ": quests started")
		count = count + 1
	end

	lu.assertEquals(count, 18, "grant paths (9 + 2 + 3 + 4)")
end

-- AC-8: the 26 start screens, displayed alone, start their mission (the display is the grant)
function TestInquisitionT4Grants:test_every_start_screen_displayed_alone_starts_its_own_head_once()
	local count = 0

	for id, n in pairs(J4.STARTS) do
		local head = J4.MISSIONS[n].head
		local spies = J4.spyStarts()
		local player = readyFor(n)

		J4.drive(player, id)
		lu.assertEquals(J4.started(spies), { head }, id .. ": quests started")
		lu.assertEquals(#spies[head], 1, id .. ": startQuest calls")
		lu.assertEquals(attempted(player, n), "1", id .. ": attempted key")
		H.reset()
		count = count + 1
	end

	lu.assertEquals(count, 26, "start screens (8 + 9 + 2 + 3 + 4)")
end

-- AC-8: no other screen starts a story mission
function TestInquisitionT4Grants:test_no_other_screen_starts_a_story_mission()
	for _, row in ipairs(J4.SCREENS) do
		if J4.STARTS[row.id] == nil then
			H.reset()

			local spies = J4.spyStarts(J4.STORY)
			local player = readyFor(2, { pilotTier = 4 })
			local before = {}

			for m = 1, 4 do
				before[m] = attempted(player, m)
			end

			J4.drive(player, row.id)
			lu.assertEquals(J4.started(spies), {}, row.id .. ": a story quest was started")

			for m = 1, 4 do
				lu.assertEquals(attempted(player, m), before[m], row.id .. ": mission " .. m .. " attempted key")
			end
		end
	end
end

-- AC-8: the whole talk reaches the grant for each mission (ready -> brief -> accept)
function TestInquisitionT4Grants:test_the_whole_talk_from_the_first_screen_reaches_a_grant_for_each_mission()
	for n = 1, 4 do
		H.reset()

		local spies = J4.spyStarts()
		local player = readyFor(n)
		local replies = { "s_52917b0d" }

		for _, p in ipairs(ACCEPTS) do
			if p.n == n then
				for _, r in ipairs(p.replies) do
					replies[#replies + 1] = r
				end

				break
			end
		end

		local t = J4.talk(player, replies)

		lu.assertEquals(t[1].id, "ready", "mission " .. n .. ": first screen")
		lu.assertEquals(t[2].id, "m" .. n .. "_brief", "mission " .. n .. ": the brief")
		lu.assertEquals(J4.started(spies), { J4.MISSIONS[n].head }, "mission " .. n .. ": started")
	end
end

-- AC-8: the grant lines with a name token
function TestInquisitionT4Grants:test_the_two_blessing_grants_carry_the_first_name()
	for _, id in ipairs({ "m1_accept_blessing", "m4_accept_blessing" }) do
		J4.spyStarts()

		local n = J4.STARTS[id]
		local t = J4.drive(readyFor(n), id)

		lu.assertEquals(t[1].params.TU, "Ace", id .. ": %NU")
	end
end

---------------------------------------------------------------------------------------------
-- Real starts and stale runs
---------------------------------------------------------------------------------------------

TestInquisitionT4RealStart = {}

TestInquisitionT4RealStart.setUp = setUp

local FIRST_GRANT = { "m1_accept_stay", "m2_accept_prey", "m3_accept_orders", "m4_accept_blessing" }

-- AC-8: a grant screen really starts the head (an escort and a survival head included) for a pilot in a ship
function TestInquisitionT4RealStart:test_every_mission_head_really_starts_for_a_pilot_in_a_ship()
	for n, m in ipairs(J4.MISSIONS) do
		H.reset()

		local q = J4.quest(m.head)
		local player = readyFor(n, { inShip = true, zone = q.questZone })

		J4.drive(player, FIRST_GRANT[n])
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active in the journal")
		lu.assertEquals(attempted(player, n), "1", "attempted key")
	end
end

-- AC-8: a stale entry of the chain is cleared by the grant (startSpaceQuestChain's job)
function TestInquisitionT4RealStart:test_a_grant_clears_a_stale_chain_member_and_starts_the_head()
	for n, m in ipairs(J4.MISSIONS) do
		H.reset()

		local q = J4.quest(m.head)
		local player = readyFor(n, { inShip = true, zone = q.questZone })
		local last = m.chain[#m.chain]

		J4.setState(player, last, "complete")
		J4.drive(player, FIRST_GRANT[n])
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active")
		lu.assertEquals(J4.state(player, last), "none", last .. ": the stale chain end is cleared")
	end
end

-- AC-8: a running chain is not restarted by a second grant
function TestInquisitionT4RealStart:test_a_running_chain_is_not_restarted()
	local spies = J4.spyStarts()
	local player = readyFor(1, { mission = { [1] = "active" } })

	J4.drive(player, "m1_accept_stay")
	lu.assertEquals(J4.started(spies), {}, "quests started (the chain is already active)")
end

---------------------------------------------------------------------------------------------
-- Failures and retries (AC-8)
---------------------------------------------------------------------------------------------

TestInquisitionT4Retries = {}

TestInquisitionT4Retries.setUp = setUp

for i, r in ipairs(RETRIES) do
	-- AC-8: each reply route of a failure line reaches a retry screen that restarts mission n
	TestInquisitionT4Retries["test_retry_walk_" .. i .. "_" .. r.grant .. "_restarts_mission_" .. r.n] = function()
		local head = J4.MISSIONS[r.n].head
		local spies = J4.spyStarts()
		local player = failedPilot(r.n)
		local t = J4.talk(player, r.replies)

		lu.assertEquals(t[1].id, J4.MISSIONS[r.n].failed, "first screen")
		lu.assertEquals(t[#t].id, r.grant, "the walk ends on " .. r.grant)
		lu.assertTrue(t[#t].stop, r.grant .. " ends the conversation")
		lu.assertEquals(J4.started(spies), { head }, "quests started")
		lu.assertEquals(attempted(player, r.n), "1", "attempted key")
		lu.assertEquals(player.bankCredits, 0, "a retry pays nothing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the screens before the retry start nothing
	TestInquisitionT4Retries["test_retry_walk_" .. i .. "_" .. r.grant .. "_starts_nothing_before_the_last_reply"] = function()
		local spies = J4.spyStarts()
		local t = J4.talk(failedPilot(r.n), shorter(r.replies))

		lu.assertNotEquals(t[#t].id, r.grant, "the shorter walk stops before the retry")
		lu.assertEquals(J4.started(spies), {}, "quests started")
	end
end

-- AC-8: the failure screen of every mission shows the client line and its two replies
function TestInquisitionT4Retries:test_the_failure_screens_show_their_lines_and_replies()
	local want = {
		{ "m1_failed", "s_a6380860", { "s_67183c1c", "s_26bb0194" } },
		{ "m2_failed", "s_cfb7c310", { "s_97ce1c41", "s_e69b471b" } },
		{ "m3_failed", "s_1bfd2d3e", { "s_85b1adc5", "s_873e726e" } },
		{ "m4_failed", "s_91d10a84", { "s_7017e938", "s_39ec8285" } },
	}

	for n, w in ipairs(want) do
		local t = J4.talk(failedPilot(n))

		lu.assertEquals(J4.ids(t), { w[1] }, "screens shown")
		lu.assertEquals(t[1].text, J4.PREFIX .. w[2], w[1] .. ": the NPC line")
		lu.assertEquals(J4.optionSids(t[1]), w[3], w[1] .. ": replies")
	end
end

-- AC-8: an aborted mission (attempted, not won, not running) is a failure with the same two routes
function TestInquisitionT4Retries:test_an_aborted_mission_gets_the_failure_line()
	for n = 1, 4 do
		H.reset()

		local player = readyFor(n, { mission = { [n] = "attempted" } })

		lu.assertEquals(J4.firstScreen(player), "m" .. n .. "_failed", "mission " .. n .. " aborted")
	end
end

-- AC-8: a retry for a real run restarts the head after the failure
function TestInquisitionT4Retries:test_a_retry_really_restarts_the_failed_mission()
	local retry = { "m1_retry_a", "m2_retry_a", "m3_retry_a", "m4_retry_a" }

	for n, m in ipairs(J4.MISSIONS) do
		H.reset()

		local q = J4.quest(m.head)
		local player = failedPilot(n, { inShip = true, zone = q.questZone })

		J4.drive(player, retry[n])
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active after the retry")
	end
end

-- AC-8: the retry of one mission touches no other mission's key
function TestInquisitionT4Retries:test_a_retry_sets_only_its_own_attempted_key()
	local player = failedPilot(2)

	J4.spyStarts()
	J4.drive(player, "m2_retry_a")
	lu.assertEquals(attempted(player, 2), "1", "mission 2")
	lu.assertEquals(attempted(player, 1), "1", "mission 1 keeps its key (the pilot was built with M1 paid)")
	lu.assertNil(attempted(player, 3), "mission 3")
	lu.assertNil(attempted(player, 4), "mission 4")
end

---------------------------------------------------------------------------------------------
-- The pilot tier (D-10, AC-10)
---------------------------------------------------------------------------------------------

TestInquisitionT4Tier = {}

TestInquisitionT4Tier.setUp = setUp

-- AC-10, D-10: a pilot still at tier 3 with the four _03 skills is raised to 4 by the first START
function TestInquisitionT4Tier:test_the_first_start_raises_a_tier_3_pilot_with_the_four_tier_3_skills_to_tier_4()
	J4.spyStarts()

	for id in pairs(J4.STARTS) do
		H.reset()

		local n = J4.STARTS[id]
		local player = readyFor(n, { pilotTier = 3 })

		J4.drive(player, id)
		lu.assertEquals(player.ghost.pilotTier, n == 4 and 5 or 4, id .. ": pilot tier after the start screen (3 -> 4 on the four _03 skills; a pilot with four _04 skills goes on to 5, D-10)")
		H.reset()
	end
end

-- D-10: never lowers or skips
function TestInquisitionT4Tier:test_a_start_never_lowers_the_pilot_tier_or_raises_it_without_the_skills()
	J4.spyStarts()

	local ok = readyFor(1, { pilotTier = 5 })

	J4.drive(ok, "m1_accept_stay")
	lu.assertEquals(ok.ghost.pilotTier, 5, "tier 5 stays")

	local four = readyFor(1, { pilotTier = 4 })

	J4.drive(four, "m1_accept_stay")
	lu.assertEquals(four.ghost.pilotTier, 4, "tier 4 with one _04 skill stays")
end
