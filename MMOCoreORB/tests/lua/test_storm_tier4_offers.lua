-- Admiral Kilnstrider: the four mission briefs, the grants and the failure re-grants (table H).
-- Spec: .claude/work/storm-tier4-kilnstrider/01-spec.md (B-5; Conversation flow 1 (G8-G11, G16), 3 (table H); Data mapping 2; Appendix A, D and E; D-5, D-10; FK-9; I-12).
--
-- A start screen sets `tatooine_imperial_tier4_<n>:attempted` and calls SpaceHelpers:startSpaceQuestChain on the mission's head (J grantMissionN).
-- The walks are Appendix D's, then driven through the handler. The heads' startQuest is spied (H.spyOn does not call the original) except in the
-- "really starts" tests, which run it in a ship.

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier4_data")
local CS = require("harness.client_strings")

D.loadConversation()

local function setUp()
	H.reset()
	D.requireConversation(lu)
end

local function tearDown() D.restore() end

local function attempted(player, n) return H.getQuestStatus(player, D.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n: the earlier missions won and paid, n skills held, past the first meeting
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

	return D.pilot(o)
end

-- the pilot of mission n whose last mission was failed (attempted, nothing active): the pilot a failure line opens for
local function failedFor(n, extra)
	local t4, paid = {}, {}

	for i = 1, n do
		t4[i] = i
	end

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true, mission = { [n] = "failed" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
end

local IMPERIAL_SHIP = function() return { x = -7000, z = -7000, y = -7000, factionHash = getHashCode("imperial") } end

---------------------------------------------------------------------------------------------
-- Table H, the data
---------------------------------------------------------------------------------------------

TestStormT4Offers = {}

TestStormT4Offers.setUp = setUp
TestStormT4Offers.tearDown = tearDown

-- B-5 (the oracle): table H has 14 start screens (3 + 4 + 3 + 4) and 4 reward screens; the failure gates are start screens
function TestStormT4Offers:test_table_h_lists_14_start_screens_and_4_reward_screens()
	local perMission = { 0, 0, 0, 0 }
	local n = 0

	for id, mission in pairs(D.STARTS) do
		n = n + 1
		perMission[mission] = perMission[mission] + 1
		lu.assertNotNil(D.screenRow(id), id .. " is an Appendix A row")
	end

	lu.assertEquals(n, 14, "start screens (table H)")
	lu.assertEquals(perMission, { 3, 4, 3, 4 }, "start screens per mission")
	lu.assertEquals({ D.STARTS.m1_failed, D.STARTS.m2_failed, D.STARTS.m3_failed, D.STARTS.m4_failed }, { 1, 2, 3, 4 }, "the failure gates start their mission")
end

-- B-5: every grant screen ends the conversation (FK-9)
function TestStormT4Offers:test_the_accept_screens_end_the_conversation_and_the_failure_gates_do_not()
	for id in pairs(D.STARTS) do
		local row = D.screenRow(id)

		if id:find("_accept_", 1, true) then
			lu.assertTrue(row.stop, id .. " ends the conversation")
		else
			lu.assertFalse(row.stop, id .. " has replies")
		end
	end
end

---------------------------------------------------------------------------------------------
-- The briefs: the ready gate leads to the head of the mission
---------------------------------------------------------------------------------------------

TestStormT4Briefs = {}

TestStormT4Briefs.setUp = setUp
TestStormT4Briefs.tearDown = tearDown

-- B-5: with getReadyMission == n, ready -> s_52917b0d shows m<n>_brief with its replies
function TestStormT4Briefs:test_ready_leads_to_the_brief_of_the_ready_mission_with_its_replies()
	local replies = {
		{ "s_469b88eb", "s_9cc5ad7c" }, { "s_c782ced7", "s_dd2ae025" }, { "s_643d24c8", "s_34f8d771", "s_ad56e0fd" }, { "s_2f748550", "s_a1586753" },
	}

	for n = 1, 4 do
		local t = D.talk(readyFor(n), { "s_52917b0d" })

		lu.assertEquals(D.ids(t), { "ready", "m" .. n .. "_brief" }, "mission " .. n)
		lu.assertEquals(D.optionSids(t[2]), replies[n], "mission " .. n .. ": the head's replies")
		lu.assertFalse(t[2].stop, "mission " .. n .. ": the head waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

---------------------------------------------------------------------------------------------
-- The grants: each accept path starts the mission on the grant screen and nowhere before
---------------------------------------------------------------------------------------------

TestStormT4Grants = {}

TestStormT4Grants.setUp = setUp
TestStormT4Grants.tearDown = tearDown

for _, p in ipairs(D.PATHS) do
	local m = D.MISSIONS[p.mission]

	-- B-5: the walk to the grant screen starts the mission there and nowhere before
	TestStormT4Grants["test_the_walk_to_" .. p.grant .. "_starts_mission_" .. p.mission .. "_on_the_grant_screen_only"] = function()
		for k = 0, #p.replies - 1 do
			H.reset()

			local spies = D.spyStarts()
			local chains = D.recordChainStarts()
			local player = readyFor(p.mission)
			local before = D.snapshot(player)

			D.drive(player, p.from, { table.unpack(p.replies, 1, k) })
			lu.assertEquals(D.started(spies), {}, p.grant .. ": nothing started after " .. k .. " replies")
			lu.assertEquals(chains, {}, p.grant .. ": startSpaceQuestChain not called after " .. k .. " replies")
			lu.assertNil(attempted(player, p.mission), p.grant .. ": no attempted key after " .. k .. " replies")
			lu.assertEquals(player.bankCredits, before.credits, p.grant .. ": no credits")
			lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, p.grant .. ": no item")
			D.restore()
		end

		local spies = D.spyStarts()
		local chains = D.recordChainStarts()
		local player = readyFor(p.mission)
		local t = D.drive(player, p.from, p.replies)

		lu.assertEquals(t[#t].id, p.grant, p.grant .. ": the last screen shown")
		lu.assertTrue(t[#t].stop, p.grant .. " ends the conversation")
		lu.assertEquals(D.started(spies), { m.head }, p.grant .. ": quests started (the head of mission " .. p.mission .. ", once)")
		lu.assertEquals(#spies[m.head], 1, p.grant .. ": startQuest calls on the head")
		lu.assertEquals(spies[m.head][1].args[1], player, p.grant .. ": the head starts for the talking pilot")
		lu.assertEquals(chains, { m.head }, p.grant .. ": startSpaceQuestChain calls (head global)")
		lu.assertEquals(attempted(player, p.mission), "1", p.grant .. ": the :attempted key")

		for other = 1, 4 do
			lu.assertEquals(H.getQuestStatus(player, D.MISSIONS[other].status .. ":reward"), other < p.mission and "1" or nil,
				p.grant .. ": the :reward key of mission " .. other .. " (only the missions paid before are set)")

			if other ~= p.mission then
				lu.assertEquals(attempted(player, other), other < p.mission and "1" or nil, p.grant .. ": mission " .. other .. " :attempted untouched")
			end
		end

		lu.assertEquals(player.bankCredits, 0, p.grant .. ": no credits")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, p.grant .. ": no item")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, p.grant .. ": client strings")
	end
end

-- B-5: the grant screen starts the mission once even when shown again (a second talk of a pilot who left)
function TestStormT4Grants:test_the_grant_screen_displayed_alone_starts_its_own_mission_once()
	for id, n in pairs(D.STARTS) do
		H.reset()

		local spies = D.spyStarts()
		local chains = D.recordChainStarts()

		D.drive(readyFor(n), id)
		lu.assertEquals(D.started(spies), { D.MISSIONS[n].head }, id .. ": quests started")
		lu.assertEquals(chains, { D.MISSIONS[n].head }, id .. ": startSpaceQuestChain calls")
		D.restore()
	end
end

-- B-5: no other screen starts or pays anything (every screen of Appendix A, driven alone)
function TestStormT4Grants:test_no_screen_outside_table_h_starts_a_mission_or_pays()
	for _, row in ipairs(D.SCREENS) do
		if D.STARTS[row.id] == nil and row.duty == nil then
			H.reset()

			local spies = D.spyStarts()
			local chains = D.recordChainStarts()
			local player = D.pilot({ met = true, t4 = { 1 }, xp = D.TRAIN_COST })
			local credits = player.bankCredits

			if D.PAYS[row.id] == nil then
				D.drive(player, row.id)
				lu.assertEquals(D.started(spies), {}, row.id .. ": quests started")
				lu.assertEquals(chains, {}, row.id .. ": startSpaceQuestChain calls")
				lu.assertEquals(player.bankCredits, credits, row.id .. ": credits")
				lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, row.id .. ": items")
			end

			D.restore()
		end
	end
end

-- B-5, FK-9: the duty screens start their duty only
function TestStormT4Grants:test_the_duty_screens_start_no_story_mission()
	for _, d in ipairs(D.DUTY_MENU) do
		H.reset()

		local spies = D.spyStarts()
		local chains = D.recordChainStarts()

		D.drive(D.pilot({ met = true }), d.screen)
		lu.assertEquals(chains, {}, d.screen .. ": startSpaceQuestChain calls")
		lu.assertEquals(D.started(spies), { d.global }, d.screen .. ": quests started")
		D.restore()
	end
end

-- B-5: a stale run (earlier members of the chain complete) is cleared by the start, then the head starts once
function TestStormT4Grants:test_a_start_clears_a_stale_run_of_the_chain()
	for n = 1, 4 do
		H.reset()

		local m = D.MISSIONS[n]
		local player = readyFor(n, { mission = { [n] = "partial" } })

		for i = 1, #m.chain - 1 do
			D.setState(player, m.chain[i], "complete")
		end

		local spies = D.spyStarts()
		local accept

		for id, mission in pairs(D.STARTS) do
			if mission == n and id:find("_accept_", 1, true) then
				accept = id
			end
		end

		D.drive(player, accept)

		for i, g in ipairs(m.chain) do
			lu.assertEquals(D.state(player, g), "none", "mission " .. n .. ": member " .. i .. " (" .. g .. ") is cleared by the start")
		end

		lu.assertEquals(D.started(spies), { m.head }, "mission " .. n .. ": the head starts once")
	end
end

-- B-5: the grants really start the head in a ship (the chain machinery of Part A runs)
function TestStormT4Grants:test_an_accept_screen_really_starts_the_mission_in_a_ship()
	local accepts = { "m1_accept_busy", "m2_accept_good", "m3_accept_bottom", "m4_accept_prejudice" }

	for n, id in ipairs(accepts) do
		H.reset()

		local q = D.quest(D.MISSIONS[n].head)
		local player = readyFor(n, { inShip = IMPERIAL_SHIP(), zone = q.questZone })

		D.drive(player, id)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), id .. ": the head of mission " .. n .. " is active in the journal")
		lu.assertEquals(D.firstScreen(player), "on_mission", id .. ": the next talk")
	end
end

-- B-5, D-10: a start screen raises a pilot still at tier 3 (four _03 skills) to tier 4
function TestStormT4Grants:test_a_start_screen_raises_the_pilot_tier_3_to_4()
	D.spyStarts()

	local player = readyFor(1, { pilotTier = 3 })

	D.drive(player, "m1_accept_busy")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the start screen")
end

-- B-5, D-10: the tier is never raised by a brief
function TestStormT4Grants:test_a_brief_screen_leaves_the_pilot_tier_alone()
	local player = readyFor(1, { pilotTier = 3 })

	D.drive(player, "m1_brief")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after a brief")
end

---------------------------------------------------------------------------------------------
-- The failures: re-grant on display
---------------------------------------------------------------------------------------------

TestStormT4Failures = {}

TestStormT4Failures.setUp = setUp
TestStormT4Failures.tearDown = tearDown

for n = 1, 4 do
	-- B-5, D-5: the failure line restarts the mission on display, as J does on the gate line
	TestStormT4Failures["test_" .. D.MISSIONS[n].failed .. "_restarts_mission_" .. n .. "_on_display"] = function()
		local spies = D.spyStarts()
		local chains = D.recordChainStarts()
		local player = failedFor(n)
		local t = D.talk(player)

		lu.assertEquals(D.ids(t), { D.MISSIONS[n].failed }, "the first screen")
		lu.assertEquals(D.started(spies), { D.MISSIONS[n].head }, "quests started on display")
		lu.assertEquals(chains, { D.MISSIONS[n].head }, "startSpaceQuestChain calls")
		lu.assertEquals(attempted(player, n), "1", "the :attempted key")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- B-5: an aborted mission (attempted, nothing complete, nothing active) is restarted the same way
	TestStormT4Failures["test_mission_" .. n .. "_aborted_with_a_stale_run_is_restarted_and_the_run_cleared"] = function()
		local m = D.MISSIONS[n]
		local player = failedFor(n, { mission = { [n] = "partial" } })
		local spies = D.spyStarts()

		D.talk(player)

		for i, g in ipairs(m.chain) do
			lu.assertEquals(D.state(player, g), "none", "member " .. i .. " (" .. g .. ") cleared")
		end

		lu.assertEquals(D.started(spies), { m.head }, "the head starts once")
	end
end

-- B-5: the replies after a failure line start nothing more; they end on a scolding line
function TestStormT4Failures:test_the_replies_after_a_failure_line_start_nothing_more()
	for _, w in ipairs(D.FAILED_WALKS) do
		H.reset()

		local spies = D.spyStarts()
		local chains = D.recordChainStarts()
		local player = failedFor(w.mission)
		local t = D.talk(player, w.replies)

		lu.assertEquals(t[#t].id, w.ends, "mission " .. w.mission .. ": the walk ends on " .. w.ends)
		lu.assertTrue(t[#t].stop, w.ends .. " ends the conversation")
		lu.assertEquals(#spies[D.MISSIONS[w.mission].head], 1, "mission " .. w.mission .. ": startQuest calls over the whole walk (the display only)")
		lu.assertEquals(D.started(spies), { D.MISSIONS[w.mission].head }, "quests started")
		lu.assertEquals(chains, { D.MISSIONS[w.mission].head }, "startSpaceQuestChain calls")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		D.restore()
	end
end

-- B-5: after the restart the pilot is on a mission, not failed any more (the head is active)
function TestStormT4Failures:test_after_the_restart_the_next_talk_is_on_mission()
	for n = 1, 4 do
		H.reset()

		local q = D.quest(D.MISSIONS[n].head)
		local player = failedFor(n, { inShip = IMPERIAL_SHIP(), zone = q.questZone })

		D.talk(player)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, q.questType, q.questName), "mission " .. n .. ": restarted for real")
		lu.assertEquals(D.firstScreen(player), "on_mission", "mission " .. n .. ": the next talk")
	end
end
