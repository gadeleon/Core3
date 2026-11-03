-- Nirame Sakute: the briefs, the 14 grant screens (retries and accepts), the ready routing and the mission start rules.
-- Spec: .claude/work/smuggler-tier4-nirame/01-spec.md (AC-9; Conversation flow 2 (C-3) and 3 (table H); Content contract 3 (START_SCREENS); Appendix D; D-10).
--
-- A mission starts on DISPLAY of its grant screen (BS D-8): the handler raises the pilot tier, writes <playerID>tatooine_privateer_tier4_<h>:attempted and starts
-- the head through SpaceHelpers:startSpaceQuestChain (which clears a stale chain first). The quest tables' startQuest is spied, so a start shows as one call.
-- The walk to each grant screen is Appendix D's path; N.drive starts on the first screen of the path as if the pilot had just chosen it.

local lu = require("luaunit")
local H = require("harness")
local N = require("smuggler_tier4_data")
local CS = require("harness.client_strings")

N.load()

local ALL = { 1, 2, 3, 4 }

local function setUp()
	H.reset()
	N.requireConversation(lu)
end

-- The pilot who would stand at the start screen: a failed mission (retries) or the ready mission n (accepts)
local function pilotFor(n, retry, extra)
	local t4, paid = {}, {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	for i = 1, (retry and n - 1 or n) do
		t4[i] = i
	end

	local o = { t4 = t4, paid = paid, met = true }

	if retry then
		o.mission = { [n] = "attempted" }
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return N.pilot(o)
end

local function keyOf(player, n, suffix) return H.getQuestStatus(player, N.MISSIONS[n].status .. suffix) end

TestSmugglerT4Ready = {}

TestSmugglerT4Ready.setUp = setUp

-- AC-9 (C-3): the ready screen's reply leads to the brief of the ready mission
function TestSmugglerT4Ready:test_ready_leads_to_the_brief_of_the_ready_mission()
	for n = 1, 4 do
		local player = pilotFor(n, false)

		lu.assertEquals(rawget(_G, N.HANDLER):getReadyMission(player), n, "precondition: mission " .. n .. " is ready")

		local t = N.talk(player, { "s_8be640b8" })

		lu.assertEquals(N.ids(t), { "ready", "m" .. n .. "_brief" }, "ready -> Sure. (mission " .. n .. ")")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertFalse(t[2].stop and true or false, "the brief waits for a reply")
	end
end

-- AC-9 (C-3): the static link is the first brief; without a ready mission the handler leaves it
function TestSmugglerT4Ready:test_the_ready_option_keeps_the_reply_and_defaults_to_mission_1()
	local t = N.drive(N.pilot(), "ready")

	lu.assertEquals(N.optionSids(t[1]), { "s_8be640b8" }, "the one reply")
	lu.assertEquals(N.linksOf(t[1]), { "m1_brief" }, "no ready mission: m1_brief")

	t = N.drive(pilotFor(3, false), "ready")
	lu.assertEquals(N.linksOf(t[1]), { "m3_brief" }, "mission 3 ready")
end

-- AC-9: showing ready or a brief starts and pays nothing
function TestSmugglerT4Ready:test_ready_and_the_briefs_start_and_pay_nothing()
	for n = 1, 4 do
		H.reset()

		local spies = N.spyStarts()
		local player = pilotFor(n, false)
		local before = N.snapshot(player)

		N.talk(player, { "s_8be640b8" })
		N.drive(player, N.MISSIONS[n].brief)
		lu.assertEquals(N.started(spies), {}, "mission " .. n .. ": quests started by ready and the brief")
		lu.assertNil(keyOf(player, n, ":attempted"), "mission " .. n .. ": :attempted is not set by a brief")
		lu.assertEquals(N.snapshot(player), before, "mission " .. n .. ": nothing changed")
	end
end

TestSmugglerT4Starts = {}

TestSmugglerT4Starts.setUp = setUp

-- One test per grant screen (14): Appendix D's path starts the head once, sets :attempted and nothing else starts
local ORDER = {
	"m1_retry_a", "m1_retry_b", "m1_accept_a", "m1_accept_b", "m2_retry_a", "m2_retry_b", "m2_accept", "m3_retry_a", "m3_retry_b", "m3_accept", "m4_retry_a", "m4_retry_b",
	"m4_accept_a", "m4_accept_b",
}

for _, screen in ipairs(ORDER) do
	local n = N.START_SCREENS[screen]
	local path = N.GRANT_PATHS[screen]
	local retry = screen:find("retry", 1, true) ~= nil

	-- AC-9, Appendix D
	TestSmugglerT4Starts["test_" .. screen .. "_starts_mission_" .. n .. "_once"] = function()
		local spies = N.spyStarts()
		local player = pilotFor(n, retry)
		local others = {}

		for k = 1, 4 do
			others[k] = keyOf(player, k, ":attempted")
		end

		local t = N.drive(player, path[1], path[2])
		local last = t[#t]

		lu.assertEquals(last.id, screen, "the path " .. path[1] .. " -> " .. screen .. " ends on the grant screen")
		lu.assertTrue(last.stop, screen .. " ends the conversation")
		lu.assertEquals(#t, #path[2] + 1, "one screen per reply of the path")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(N.started(spies), { N.MISSIONS[n].head }, screen .. ": quests started")
		lu.assertEquals(spies[N.MISSIONS[n].head][1].args[1], player, screen .. ": the head gets the pilot")
		lu.assertEquals(keyOf(player, n, ":attempted"), "1", screen .. ": the :attempted key of mission " .. n)

		for k = 1, 4 do
			if k ~= n then
				lu.assertEquals(keyOf(player, k, ":attempted"), others[k], screen .. ": the :attempted key of mission " .. k .. " is unchanged")
			end
		end
	end

	-- AC-9: no screen before the grant on the path starts or pays anything
	TestSmugglerT4Starts["test_the_path_to_" .. screen .. "_starts_and_pays_nothing_before_the_grant"] = function()
		local spies = N.spyStarts()
		local player = pilotFor(n, retry)
		local replies = {}

		for i = 1, #path[2] - 1 do
			replies[i] = path[2][i]
		end

		local attempted = keyOf(player, n, ":attempted")
		local t = N.drive(player, path[1], replies)

		lu.assertNotEquals(t[#t].id, screen, "the screen before the grant is not the grant")
		lu.assertEquals(N.started(spies), {}, "quests started before the grant screen")
		lu.assertEquals(keyOf(player, n, ":attempted"), attempted, ":attempted before the grant screen (a failed mission has it already)")
		lu.assertEquals(player.bankCredits, 0, "bank credits")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "items")
	end
end

-- AC-9: the 14 paths are the 14 START_SCREENS
function TestSmugglerT4Starts:test_the_14_paths_are_the_14_start_screens()
	local seen = 0

	for screen in pairs(N.GRANT_PATHS) do
		seen = seen + 1
		lu.assertNotNil(N.START_SCREENS[screen], screen .. " is a START_SCREEN")
	end

	lu.assertEquals(seen, 14, "grant paths")
	lu.assertEquals(#ORDER, 14, "grant screens in the test order")
end

-- AC-9, SpaceHelpers:startSpaceQuestChain: a stale chain (journal entries of an earlier run) is cleared before the head starts
function TestSmugglerT4Starts:test_a_stale_run_is_cleared_when_the_mission_is_granted_again()
	for n, m in ipairs(N.MISSIONS) do
		H.reset()

		local spies = N.spyStarts()
		local player = pilotFor(n, true)

		for _, g in ipairs(m.chain) do
			N.setState(player, g, "complete")
		end

		N.drive(player, "m" .. n .. "_failed", N.GRANT_PATHS["m" .. n .. "_retry_a"][2])

		for _, g in ipairs(m.chain) do
			lu.assertEquals(N.state(player, g), "none", "mission " .. n .. ": " .. g .. " is cleared before the head starts")
		end

		lu.assertEquals(N.started(spies), { m.head }, "mission " .. n .. ": the head starts once")
	end
end

-- AC-9: the grant screen raises the pilot tier (D-10): 3 -> 4 with the four _03 skills, 4 -> 5 on the fourth _04 skill
function TestSmugglerT4Starts:test_a_grant_raises_the_pilot_tier()
	N.spyStarts()

	local p = pilotFor(1, false, { pilotTier = 3 })

	N.drive(p, "m1_brief", N.GRANT_PATHS.m1_accept_a[2])
	lu.assertEquals(p.ghost.pilotTier, 4, "3 -> 4 at the first grant")

	H.reset()
	N.spyStarts()
	p = pilotFor(4, false, { pilotTier = 4 })
	N.drive(p, "m4_brief", N.GRANT_PATHS.m4_accept_a[2])
	lu.assertEquals(p.ghost.pilotTier, 5, "4 -> 5 at mission 4's grant with the four _04 skills")
end

-- AC-9: a grant screen shown twice starts the head twice only if the first run is gone (the chain guard)
function TestSmugglerT4Starts:test_a_running_chain_is_not_started_again()
	local spies = N.spyStarts()
	local player = pilotFor(1, false)

	N.drive(player, "m1_brief", N.GRANT_PATHS.m1_accept_a[2])
	N.setState(player, N.MISSIONS[1].head, "active") -- what the spied startQuest would have done
	N.drive(player, "m1_brief", N.GRANT_PATHS.m1_accept_a[2])
	lu.assertEquals(N.started(spies), { N.MISSIONS[1].head }, "the head started once for two visits")
end

-- AC-9: every first-screen failure for mission n leads to a re-grant route of that mission only
function TestSmugglerT4Starts:test_a_failed_mission_can_be_regranted_by_both_routes()
	for n = 1, 4 do
		for _, route in ipairs({ "a", "b" }) do
			H.reset()

			local spies = N.spyStarts()
			local screen = "m" .. n .. "_retry_" .. route
			local player = pilotFor(n, true)
			local t = N.talk(player, N.GRANT_PATHS[screen][2])

			lu.assertEquals(t[1].id, "m" .. n .. "_failed", "mission " .. n .. " failed: the first screen")
			lu.assertEquals(t[#t].id, screen, "route " .. route .. " of mission " .. n)
			lu.assertEquals(N.started(spies), { N.MISSIONS[n].head }, screen .. ": the head started")
		end
	end
end

-- AC-9: the failed screens differ in text per mission and use the client's lines
function TestSmugglerT4Starts:test_the_failed_screens_are_the_java_lines()
	local want = { m1_failed = "s_4854b859", m2_failed = "s_b30e002f", m3_failed = "s_c9b06630", m4_failed = "s_c4b1700b" }

	for n = 1, 4 do
		local t = N.talk(pilotFor(n, true))

		lu.assertEquals(t[1].id, "m" .. n .. "_failed", "mission " .. n)
		lu.assertEquals(t[1].text, N.PREFIX .. want["m" .. n .. "_failed"], "mission " .. n .. ": the line")
		lu.assertEquals(#t[1].options, 2, "mission " .. n .. ": replies")
	end
end
