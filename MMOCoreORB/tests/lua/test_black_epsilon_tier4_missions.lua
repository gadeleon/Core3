-- Nin Gursawe: the four mission briefs and grants, and the failure retries (table H starts).
-- Spec: .claude/work/black-epsilon-tier4-nin-gursawe/01-spec.md (AC-8, AC-5; Conversation flow 4; Appendix A and D; FN-3).
--
-- A start screen sets `corellia_imperial_tier4_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head. The head's
-- startQuest is spied (H.spyOn does not call the original) except in the "real start" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier4_data")
local CS = require("harness.client_strings")

T.load()

local function setUp()
	H.reset()
	T.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, T.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n: n - 1 missions done (paid), n - 1 skills, past the intro (the ready prompt shows for skill n)
local function readyFor(n, extra)
	local t4, paid = {}, {}

	for i = 1, n - 1 do
		t4[i] = i
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, keys = { intro = true, met = true } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
end

---------------------------------------------------------------------------------------------
-- The briefs and the grants (Appendix D)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Grants = {}

TestBlackEpsilonT4Grants.setUp = setUp

-- every grant of Appendix D from its plain brief, then (M1, M2, M4) from the post-training brief
local WALKS = {}

for _, p in ipairs(T.PATHS) do
	WALKS[#WALKS + 1] = { grant = p.grant, from = p.from, n = p.n, replies = p.replies }

	if p.n ~= 3 then
		WALKS[#WALKS + 1] = { grant = p.grant, from = T.MISSIONS[p.n].briefTrained, n = p.n, replies = p.replies }
	end
end

local function expectedIds(w)
	local ids = { w.from }

	-- the screens come from the template: follow the replies through the static links of Appendix A
	local row = T.screenRow(w.from)

	for _, reply in ipairs(w.replies) do
		local link

		for _, o in ipairs(row.options) do
			if o[1] == reply then
				link = o[2]
			end
		end

		assert(link ~= nil, w.from .. ": Appendix A has no reply " .. reply .. " on '" .. row.id .. "'")
		ids[#ids + 1] = link
		row = T.screenRow(link)
	end

	return ids
end

for i, w in ipairs(WALKS) do
	-- AC-8: the Appendix D path ends on its grant, which sets :attempted and starts the head once; no screen on the path starts or pays anything
	TestBlackEpsilonT4Grants["test_walk_" .. i .. "_" .. w.from .. "_to_" .. w.grant] = function()
		local head = T.MISSIONS[w.n].head
		local ids = expectedIds(w)
		local spies = T.spyStarts()
		local player = readyFor(w.n)

		lu.assertNil(attempted(player, w.n), "precondition: mission " .. w.n .. " not attempted")

		local before = {}

		for m = 1, 4 do
			before[m] = attempted(player, m)
		end

		local t = T.drive(player, w.from, w.replies)

		lu.assertEquals(T.ids(t), ids, w.grant .. ": screens shown")
		lu.assertEquals(t[#t].id, w.grant, "the walk ends on " .. w.grant)
		lu.assertTrue(t[#t].stop, w.grant .. " ends the conversation")
		lu.assertEquals(attempted(player, w.n), "1", "corellia_imperial_tier4_" .. w.n .. ":attempted")
		lu.assertEquals(T.started(spies), { head }, "quests started")
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

	-- AC-8: the screens before the grant start nothing
	TestBlackEpsilonT4Grants["test_walk_" .. i .. "_no_screen_before_" .. w.grant .. "_starts_anything"] = function()
		local spies = T.spyStarts()
		local player = readyFor(w.n)
		local shorter = {}

		for k = 1, #w.replies - 1 do
			shorter[k] = w.replies[k]
		end

		local t = T.drive(player, w.from, shorter)

		lu.assertNotEquals(t[#t].id, w.grant, "the shorter walk stops before the grant")
		lu.assertEquals(T.started(spies), {}, "quests started")
		lu.assertNil(attempted(player, w.n), "no attempted key before the grant")
	end
end

-- AC-8: the grant screens, displayed alone, start their mission (the display is the grant, T3 D-6)
function TestBlackEpsilonT4Grants:test_every_start_screen_displayed_alone_starts_its_own_head_once()
	local count = 0

	for id, n in pairs(T.STARTS) do
		local head = T.MISSIONS[n].head
		local spies = T.spyStarts()
		local player = readyFor(n)

		T.drive(player, id)
		lu.assertEquals(T.started(spies), { head }, id .. ": quests started")
		lu.assertEquals(attempted(player, n), "1", id .. ": attempted key")
		H.reset()
		count = count + 1
	end

	lu.assertEquals(count, 24, "start screens (8 + 9 + 3 + 4)")
end

-- AC-8, AC-5: the ready prompt reaches the brief of the ready mission and the brief a grant (one full path per mission)
function TestBlackEpsilonT4Grants:test_the_whole_talk_from_the_first_screen_reaches_a_grant_for_each_mission()
	for n = 1, 4 do
		H.reset()

		local spies = T.spyStarts()
		local skills = {}

		for i = 1, n do
			skills[i] = i
		end

		local player = readyFor(n, { t4 = skills })
		local replies = { "s_36a4e374" }

		-- the shortest path of Appendix D for the mission: the one for m<n>_accept_a / m3_accept / m4_accept_a
		for _, p in ipairs(T.PATHS) do
			if p.n == n and (p.grant == "m" .. n .. "_accept_a" or p.grant == "m3_accept") then
				for _, r in ipairs(p.replies) do
					replies[#replies + 1] = r
				end
			end
		end

		local t = T.talk(player, replies)

		lu.assertEquals(t[1].id, "ready", "mission " .. n .. ": first screen")
		lu.assertEquals(t[2].id, "m" .. n .. "_brief", "mission " .. n .. ": the brief")
		lu.assertEquals(T.started(spies), { T.MISSIONS[n].head }, "mission " .. n .. ": started")
	end
end

---------------------------------------------------------------------------------------------
-- Real starts and stale runs
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4RealStart = {}

TestBlackEpsilonT4RealStart.setUp = setUp

-- AC-8, R-1: a grant screen really starts the head (an escort and an assassinate head included) for a pilot in a ship
function TestBlackEpsilonT4RealStart:test_every_mission_head_really_starts_for_a_pilot_in_a_ship()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local q = T.quest(m.head)
		local player = readyFor(n, { inShip = true, zone = m.zone })
		local grant = n == 3 and "m3_accept" or ("m" .. n .. "_accept_a")

		T.drive(player, grant)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active in the journal")
		lu.assertEquals(attempted(player, n), "1", "attempted key")
	end
end

-- AC-8: a stale entry of the chain is cleared by the grant (startSpaceQuestChain's job)
function TestBlackEpsilonT4RealStart:test_a_grant_clears_a_stale_chain_member_and_starts_the_head()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local q = T.quest(m.head)
		local player = readyFor(n, { inShip = true, zone = m.zone })
		local last = m.chain[#m.chain]

		T.setState(player, last, "complete")

		local grant = n == 3 and "m3_accept" or ("m" .. n .. "_accept_a")

		T.drive(player, grant)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active")
		lu.assertEquals(T.state(player, last), "none", last .. ": the stale chain end is cleared")
	end
end

-- AC-8: a running chain is not restarted by a second grant
function TestBlackEpsilonT4RealStart:test_a_running_chain_is_not_restarted()
	local spies = T.spyStarts()
	local player = readyFor(1, { mission = { [1] = "active" } })

	T.drive(player, "m1_accept_a")
	lu.assertEquals(T.started(spies), {}, "quests started (the chain is already active)")
end

---------------------------------------------------------------------------------------------
-- Failures and retries (AC-8)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT4Retries = {}

TestBlackEpsilonT4Retries.setUp = setUp

local function failedPilot(n)
	local t4, paid = {}, {}

	for i = 1, n do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	return T.pilot({ t4 = t4, paid = paid, keys = { intro = true, met = true }, mission = { [n] = "failed" } })
end

for i, r in ipairs(T.RETRY_PATHS) do
	-- AC-8: each reply route of a failure line reaches a retry screen that restarts mission n
	TestBlackEpsilonT4Retries["test_retry_walk_" .. i .. "_" .. r.grant .. "_restarts_mission_" .. r.n] = function()
		local head = T.MISSIONS[r.n].head
		local spies = T.spyStarts()
		local player = failedPilot(r.n)
		local t = T.talk(player, r.replies)

		lu.assertEquals(t[1].id, T.MISSIONS[r.n].failed, "first screen")
		lu.assertEquals(t[#t].id, r.grant, "the walk ends on " .. r.grant)
		lu.assertTrue(t[#t].stop, r.grant .. " ends the conversation")
		lu.assertEquals(T.started(spies), { head }, "quests started")
		lu.assertEquals(attempted(player, r.n), "1", "attempted key")
		lu.assertEquals(player.bankCredits, 0, "a retry pays nothing")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-8: the screens before the retry start nothing
	TestBlackEpsilonT4Retries["test_retry_walk_" .. i .. "_" .. r.grant .. "_starts_nothing_before_the_last_reply"] = function()
		local spies = T.spyStarts()
		local shorter = {}

		for k = 1, #r.replies - 1 do
			shorter[k] = r.replies[k]
		end

		local t = T.talk(failedPilot(r.n), shorter)

		lu.assertNotEquals(t[#t].id, r.grant, "the shorter walk stops before the retry")
		lu.assertEquals(T.started(spies), {}, "quests started")
	end
end

-- AC-8: the failure screen of every mission shows the client line and two (one for M4: two) replies
function TestBlackEpsilonT4Retries:test_the_failure_screens_show_their_lines_and_replies()
	local want = {
		{ "m1_failed", "s_d832aba0", { "s_b4712f35", "s_828cdbfa" } },
		{ "m2_failed", "s_b94e3a35", { "s_87d7e908", "s_40d40fc4" } },
		{ "m3_failed", "s_1d658537", { "s_c4c33621", "s_50b309d4" } },
		{ "m4_failed", "s_dcdce64", { "s_83502a2", "s_4af031d3" } },
	}

	for n, w in ipairs(want) do
		local t = T.talk(failedPilot(n))

		lu.assertEquals(T.ids(t), { w[1] }, "screens shown")
		lu.assertEquals(t[1].text, T.PREFIX .. w[2], w[1] .. ": the NPC line")
		lu.assertEquals(T.optionSids(t[1]), w[3], w[1] .. ": replies")
	end
end

-- AC-8: a retry for a real run restarts the head after the failure
function TestBlackEpsilonT4Retries:test_a_retry_really_restarts_the_failed_mission()
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local t4, paid = {}, {}

		for i = 1, n do
			t4[i] = i
		end

		for i = 1, n - 1 do
			paid[i] = i
		end

		local q = T.quest(m.head)
		local player = T.pilot({ t4 = t4, paid = paid, keys = { intro = true, met = true }, mission = { [n] = "failed" }, inShip = true, zone = m.zone })

		T.drive(player, m.retries[1])
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), m.head .. ": active after the retry")
	end
end

-- AC-8: the retry of one mission touches no other mission's key
function TestBlackEpsilonT4Retries:test_a_retry_sets_only_its_own_attempted_key()
	local player = failedPilot(2)

	T.spyStarts()
	T.drive(player, "m2_retry_a")
	lu.assertEquals(attempted(player, 2), "1", "mission 2")
	lu.assertEquals(attempted(player, 1), "1", "mission 1 keeps its key (the pilot was built with M1 paid)")
	lu.assertNil(attempted(player, 3), "mission 3")
	lu.assertNil(attempted(player, 4), "mission 4")
end
