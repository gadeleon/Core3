-- Beissa: the four mission offers (every route of Appendix A), the failure retries, the pilot tier safety net (D-10) and the real starts.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-7, AC-5; Conversation flow 3 (table H) and 5; Appendix A; D-8, D-10).
--
-- A start screen (the 13 START_SCREENS) sets `tatooine_privateer_tier3_<n>:attempted`, raises pilot tier 2 to 3 (when the tier 2 series is won) and calls
-- SpaceHelpers:startSpaceQuestChain on the mission's head, on display of the grant line (D-8). The head's startQuest is spied (H.spyOn does not call the
-- original) except in the "real start" tests, which run it in a ship. The routes are enumerated from Appendix A (smuggler_tier3_screens_data.lua).

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local CS = require("harness.client_strings")

B.load()

local function setUp()
	H.reset()
	B.requireConversation(lu)
end

local function attempted(player, n) return H.getQuestStatus(player, B.MISSIONS[n].status .. ":attempted") end

-- the pilot ready for mission n (the earlier missions done, their skills chosen)
local function readyFor(n, extra)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	local o = { t3 = t3, paid = paid }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return B.pilot(o)
end

-- every route (screen ids and reply sids) from `id` to a screen without options, over Appendix A
local function routes(id, ids, choices, out)
	local row = B.screenRow(id)
	local path, picks = { table.unpack(ids) }, { table.unpack(choices) }

	path[#path + 1] = id

	if #row.options == 0 then
		out[#out + 1] = { ids = path, choices = picks }
		return
	end

	for _, o in ipairs(row.options) do
		local next = { table.unpack(picks) }

		next[#next + 1] = o[1]
		routes(o[2], path, next, out)
	end
end

local function routesFrom(id)
	local out = {}

	routes(id, {}, {}, out)
	return out
end

-- Talks through `choices` and checks: screens shown, which heads started, the :attempted keys
local function walk(w)
	local spies = B.spyStarts()
	local player = readyFor(w.n, w.pilot)
	local before = {}

	for n = 1, 4 do
		before[n] = attempted(player, n)
	end

	local t = B.talk(player, w.choices)

	if w.ids then
		lu.assertEquals(B.ids(t), w.ids, w.name .. ": screens shown")
	end

	lu.assertEquals(B.started(spies), w.starts or {}, w.name .. ": quests started")

	for n = 1, 4 do
		local want = before[n]

		if w.starts and #w.starts > 0 and n == w.n then
			want = "1"
		end

		lu.assertEquals(attempted(player, n), want, w.name .. ": tatooine_privateer_tier3_" .. n .. ":attempted")
	end

	lu.assertEquals(CS.transcriptUnresolved(t), {}, w.name .. ": client strings (AC-5)")

	return t, player
end

---------------------------------------------------------------------------------------------
-- Offers
---------------------------------------------------------------------------------------------

TestSmugglerT3Offers = {}

TestSmugglerT3Offers.setUp = setUp

-- AC-7: the route counts of Appendix A
function TestSmugglerT3Offers:test_the_offers_have_4_6_2_and_2_routes()
	lu.assertEquals({ #routesFrom("m1_offer"), #routesFrom("m2_offer"), #routesFrom("m3_offer"), #routesFrom("m4_offer") }, { 4, 6, 2, 2 }, "routes of m1_offer .. m4_offer")
end

-- AC-7: each offer shown alone starts nothing
function TestSmugglerT3Offers:test_each_offer_shown_alone_starts_nothing()
	for n, m in ipairs(B.MISSIONS) do
		H.reset()
		walk({ name = m.offer, n = n, ids = { m.offer }, choices = {}, starts = {} })
	end
end

for n, m in ipairs(B.MISSIONS) do
	for i, route in ipairs(routesFrom(m.offer)) do
		-- AC-7: every route ends on a grant screen of the mission, which starts the head once and sets :attempted; no earlier screen grants anything
		TestSmugglerT3Offers["test_" .. m.offer .. "_route_" .. i .. "_ends_on_a_grant_screen_that_starts_mission_" .. n .. "_once"] = function()
			local last = route.ids[#route.ids]

			lu.assertEquals(B.START_SCREENS[last], n, "the last screen " .. last .. " is a START_SCREEN of mission " .. n)

			local t = walk({ name = m.offer .. " route " .. i, n = n, ids = route.ids, choices = route.choices, starts = { m.head } })

			lu.assertTrue(t[#t].stop, last .. " ends the conversation")

			for k = 1, #route.ids - 1 do
				lu.assertNil(B.START_SCREENS[route.ids[k]], route.ids[k] .. ": a screen before the grant line is not a START_SCREEN")
			end

			-- the same talk one reply short: nothing started, nothing attempted
			local short = {}

			for k = 1, #route.choices - 1 do
				short[k] = route.choices[k]
			end

			H.reset()
			walk({ name = m.offer .. " route " .. i .. " without its last reply", n = n, choices = short, starts = {} })
		end
	end
end

-- AC-7: the 13 START_SCREENS grant exactly their own mission (each shown alone)
function TestSmugglerT3Offers:test_displaying_a_grant_screen_starts_its_mission_exactly_once_and_sets_only_its_own_attempted_key()
	local count = 0

	for id, n in pairs(B.START_SCREENS) do
		count = count + 1
		H.reset()

		local spies = B.spyStarts()
		local player = readyFor(n)
		local before = {}

		for k = 1, 4 do
			before[k] = attempted(player, k)
		end

		B.drive(player, id)
		lu.assertEquals(B.started(spies), { B.MISSIONS[n].head }, id .. ": quests started")

		for k = 1, 4 do
			lu.assertEquals(attempted(player, k), k == n and "1" or before[k], id .. ": tatooine_privateer_tier3_" .. k .. ":attempted")
		end
	end

	lu.assertEquals(count, 13, "START_SCREENS")
end

-- AC-7: no other screen of the template starts a quest or sets :attempted
function TestSmugglerT3Offers:test_no_other_screen_starts_anything()
	for _, row in ipairs(B.SCREENS) do
		if B.START_SCREENS[row.id] == nil then
			H.reset()

			local spies = B.spyStarts()
			local player = B.pilot({ mission = { [1] = "attempted" } })

			B.drive(player, row.id)
			lu.assertEquals(B.started(spies), {}, "screen " .. row.id .. ": quests started")

			for k = 1, 4 do
				lu.assertEquals(attempted(player, k), k == 1 and "1" or nil, "screen " .. row.id .. ": tatooine_privateer_tier3_" .. k .. ":attempted")
			end
		end
	end
end

-- AC-7: mission n + 1 is not offered while the skill of mission n is unchosen
function TestSmugglerT3Offers:test_mission_n_plus_1_is_not_offered_while_the_skill_of_mission_n_is_unchosen()
	for n = 1, 3 do
		H.reset()

		local t3, paid = {}, {}

		for i = 1, n - 1 do
			t3[i] = i
			paid[i] = i
		end

		local player = B.pilot({ t3 = t3, paid = paid, mission = { [n] = "won" } })

		lu.assertEquals(B.firstScreen(player), "m" .. n .. "_reward", "mission " .. n .. " won, skill unchosen: the reward screen, not the offer of mission " .. (n + 1))
	end
end

-- AC-7: the real start makes each mission head active (a Smuggler at pilot tier 3 in a Hutt-faction ship in the mission's zone)
function TestSmugglerT3Offers:test_the_real_start_makes_each_mission_head_active()
	for n, m in ipairs(B.MISSIONS) do
		H.reset()

		local id = B.IDENTITY[m.head]
		local player = readyFor(n, { inShip = { factionHash = getHashCode("hutt") }, zone = id.zone })

		B.quest(m.head):start()

		local ok, err = pcall(B.drive, player, "m" .. n .. "_accept")

		lu.assertTrue(ok, "m" .. n .. "_accept: talking raised a Lua error: " .. tostring(err))
		H.advance(0)
		lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after m" .. n .. "_accept")
	end
end

---------------------------------------------------------------------------------------------
-- Failures and retries
---------------------------------------------------------------------------------------------

TestSmugglerT3Retries = {}

TestSmugglerT3Retries.setUp = setUp

for n, m in ipairs(B.MISSIONS) do
	-- AC-7: the failure line alone starts nothing
	TestSmugglerT3Retries["test_" .. m.failed .. "_shown_alone_starts_nothing"] = function()
		walk({ name = m.failed .. " alone", n = n, pilot = { mission = { [n] = "failed" } }, ids = { m.failed }, choices = {}, starts = {} })
	end

	for i, route in ipairs(routesFrom(m.failed)) do
		-- AC-7: both routes reach a re-grant line that restarts the head; the line ends the conversation
		TestSmugglerT3Retries["test_" .. m.failed .. "_route_" .. i .. "_restarts_mission_" .. n] = function()
			local last = route.ids[#route.ids]

			lu.assertEquals(B.START_SCREENS[last], n, last .. " is a START_SCREEN of mission " .. n)

			local t = walk({ name = m.failed .. " route " .. i, n = n, pilot = { mission = { [n] = "failed" } }, ids = route.ids, choices = route.choices, starts = { m.head } })

			lu.assertTrue(t[#t].stop, last .. " ends the conversation")
		end
	end
end

-- AC-7: the intermediate lines of the failure routes grant nothing
function TestSmugglerT3Retries:test_the_lines_before_the_re_grant_screen_start_nothing()
	for n, m in ipairs(B.MISSIONS) do
		for i, route in ipairs(routesFrom(m.failed)) do
			H.reset()

			local short = {}

			for k = 1, #route.choices - 1 do
				short[k] = route.choices[k]
			end

			walk({ name = m.failed .. " route " .. i .. " without its last reply", n = n, pilot = { mission = { [n] = "failed" } }, choices = short, starts = {} })
		end
	end
end

-- AC-7: a retry clears the stale members of the chain first
function TestSmugglerT3Retries:test_a_retry_clears_a_stale_chain_member_before_the_start()
	for n, m in ipairs(B.MISSIONS) do
		for _, retry in ipairs(B.RETRIES[n]) do
			H.reset()
			B.spyStarts()

			local player = readyFor(n, { mission = { [n] = "partial" } })

			lu.assertEquals(B.state(player, m.head), "complete", "precondition: the head is a stale complete entry")
			B.drive(player, retry)
			lu.assertEquals(B.state(player, m.head), "none", "mission " .. n .. " " .. retry .. ": the stale head entry is cleared by the restart")
		end
	end
end

-- AC-7: the real restart of a failed mission makes the head active again
function TestSmugglerT3Retries:test_the_real_retry_makes_each_mission_head_active()
	for n, m in ipairs(B.MISSIONS) do
		for _, retry in ipairs(B.RETRIES[n]) do
			H.reset()

			local id = B.IDENTITY[m.head]
			local player = readyFor(n, { mission = { [n] = "partial" }, inShip = { factionHash = getHashCode("hutt") }, zone = id.zone })

			B.quest(m.head):start()

			local ok, err = pcall(B.drive, player, retry)

			lu.assertTrue(ok, retry .. ": talking raised a Lua error: " .. tostring(err))
			H.advance(0)
			lu.assertTrue(SpaceHelpers:isSpaceQuestActive(player, id.type, id.name), id.type .. "/" .. id.name .. " is active after " .. retry)
		end
	end
end

-- AC-7: a running chain is not restarted (startSpaceQuestChain refuses)
function TestSmugglerT3Retries:test_a_retry_does_not_restart_a_chain_that_is_running()
	local spies = B.spyStarts()
	local player = readyFor(1, { mission = { [1] = "active" } })

	B.drive(player, "m1_retry_run_over")
	lu.assertEquals(B.started(spies), {}, "no start while a chain member is active")
end

---------------------------------------------------------------------------------------------
-- The pilot tier safety net (D-10)
---------------------------------------------------------------------------------------------

TestSmugglerT3PilotTier = {}

TestSmugglerT3PilotTier.setUp = setUp

-- AC-7, D-10: a pilot at tier 2 with the tier 2 series won is at tier 3 after any grant screen
function TestSmugglerT3PilotTier:test_a_tier_2_graduate_is_raised_to_pilot_tier_3_by_every_grant_screen()
	for id, n in pairs(B.START_SCREENS) do
		H.reset()
		B.spyStarts()

		local player = readyFor(n, { pilotTier = 2 })

		lu.assertEquals(player.ghost.pilotTier, 2, "precondition: pilot tier 2")
		B.drive(player, id)
		lu.assertEquals(player.ghost.pilotTier, 3, id .. ": pilot tier after the grant screen")
	end
end

-- AC-7, D-10: a tier 3 pilot stays at 3 (one skill short of tier 4), a tier 4 pilot at 4
function TestSmugglerT3PilotTier:test_a_tier_3_pilot_stays_at_3_and_a_tier_4_pilot_at_4()
	for _, tier in ipairs({ 3, 4 }) do
		H.reset()
		B.spyStarts()

		local player = readyFor(4, { pilotTier = tier, t3 = { 1, 2, 3 } })

		B.drive(player, "m4_accept")
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. " after m4_accept")
	end
end

-- AC-7, D-10: the tier is not raised for a pilot who has not won the tier 2 series (never reachable through the gates, but the rule says so)
function TestSmugglerT3PilotTier:test_a_tier_2_pilot_without_the_series_is_not_raised()
	B.spyStarts()

	local player = B.pilot({ t2 = 3, pilotTier = 2 })

	B.drive(player, "m1_accept")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after m1_accept without the tier 2 series")
end

-- AC-7, D-10: getInitialScreen alone changes no tier
function TestSmugglerT3PilotTier:test_the_gate_alone_changes_no_tier()
	local player = B.pilot({ pilotTier = 2 })
	local pScreen = rawget(_G, B.HANDLER):getInitialScreen(player, B.npc(), H.conversationTemplate(B.TEMPLATE))

	lu.assertEquals(LuaConversationScreen(pScreen):getScreenID(), "m1_offer", "a tier 2 graduate at pilot tier 2 opens the first offer")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after getInitialScreen")
end

-- AC-7, D-10: the offer screens themselves do not raise the tier (only the grant lines)
function TestSmugglerT3PilotTier:test_an_offer_screen_alone_does_not_raise_the_tier()
	local player = B.pilot({ pilotTier = 2 })

	B.drive(player, "m1_offer")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the m1_offer screen")
end
