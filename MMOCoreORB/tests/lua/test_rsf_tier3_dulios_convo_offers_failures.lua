-- Dulios (RSF tier 3): the mission offers (every path of SWG's briefing tree ends on a start screen that starts the mission) and the
-- failure screens (they start nothing; both replies re-grant the mission, D-9).
-- Spec: .claude/work/rsf-tier3-dulios-convo/01-spec.md (AC-4, AC-5, invariant I-5, Conversation flow C8, C9, D-9, Content contract 2).
-- Answer key: rsf_tier3_dulios_convo_data.lua (offer-path and failure-reply start screens, copied from the spec).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local D = require("rsf_tier3_dulios_convo_data")

T.load()

local tr = T.TRAINERS.dulios

local ORIGINAL_CHAIN = SpaceHelpers.startSpaceQuestChain

-- Records startSpaceQuestChain calls and still runs the real one. Restored by restore() (called from tearDown).
local function tapChains()
	local calls = {}

	SpaceHelpers.startSpaceQuestChain = function(self, ...)
		calls[#calls + 1] = { args = table.pack(...) }
		return ORIGINAL_CHAIN(self, ...)
	end

	return calls
end

local function restore() SpaceHelpers.startSpaceQuestChain = ORIGINAL_CHAIN end

local function attempted(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":attempted") end
local function rewarded(player, n) return H.getQuestStatus(player, D.KEYS[n] .. ":reward") end

local function headIds(calls)
	local out = {}

	for i, c in ipairs(calls) do
		out[i] = c.args[3]
	end

	return out
end

local function activeMembers(player, n)
	local out = {}

	for _, member in ipairs(tr.chains[n]) do
		if T.state(player, member) == "active" then
			out[#out + 1] = member
		end
	end

	return out
end

local function noOneIsPaid(rec, n)
	lu.assertEquals(rec.rewards, {}, "mission " .. n .. ": rewardPlayer calls")
end

---------------------------------------------------------------------------------------------
-- AC-4: the offers
---------------------------------------------------------------------------------------------

TestDuliosOffers = {}

function TestDuliosOffers:setUp() H.reset() end
function TestDuliosOffers:tearDown() restore() end

-- A pilot at mission n who never attempted it
local function offerPilot(n) return T.player(tr, n, { attempted = false }) end

-- Every complete path through the offer tree of mission n: { {choices...}, {transcript...} }
local function allPaths(n)
	local paths = {}

	local function walk(choices, depth)
		lu.assertTrue(depth < 40, "mission " .. n .. ": the offer tree is deeper than 40 screens (a cycle?)")

		local transcript = T.converse(tr, offerPilot(n), choices)
		local last = transcript[#transcript]

		lu.assertNotNil(last, "mission " .. n .. ": no screen for choices {" .. table.concat(choices, ",") .. "}")

		if last.stop then
			paths[#paths + 1] = { choices = choices, transcript = transcript }
			return
		end

		lu.assertTrue(#last.options > 0, "mission " .. n .. ": screen '" .. last.id .. "' neither ends the conversation nor offers an option")

		for i = 1, #last.options do
			local nextChoices = { table.unpack(choices) }

			nextChoices[#nextChoices + 1] = i - 1
			walk(nextChoices, depth + 1)
		end
	end

	walk({}, 0)

	return paths
end

for n = 1, 4 do
	-- AC-4: the first screen is the mission's offer line
	TestDuliosOffers["test_a_pilot_at_mission_" .. n .. "_who_never_attempted_it_starts_on_" .. D.OFFER[n]] = function()
		lu.assertEquals(T.converse(tr, offerPilot(n))[1].id, D.OFFER[n], "mission " .. n .. ": first screen")
	end

	-- AC-4: an exhaustive walk gives exactly 8/4/4/2 complete paths, ending on the offer-path start screens, together covering all of them
	TestDuliosOffers["test_the_offer_tree_of_mission_" .. n .. "_has_" .. D.PATH_COUNTS[n] .. "_paths_that_end_on_its_offer_start_screens"] = function()
		local paths = allPaths(n)
		local ends, wanted = {}, {}

		for _, id in ipairs(D.OFFER_STARTS[n]) do wanted[#wanted + 1] = id end

		for _, p in ipairs(paths) do
			ends[#ends + 1] = p.transcript[#p.transcript].id
		end

		lu.assertEquals(#paths, D.PATH_COUNTS[n], "mission " .. n .. ": number of complete paths")

		table.sort(ends)
		table.sort(wanted)
		lu.assertEquals(ends, wanted, "mission " .. n .. ": the screens the paths end on")
	end

	-- AC-4: on each path only the final screen sets :attempted and starts the chain, once, with the head; nothing is paid, no skill granted
	TestDuliosOffers["test_every_path_of_mission_" .. n .. "_starts_the_mission_only_on_its_last_screen"] = function()
		local paths = allPaths(n)

		lu.assertEquals(#paths, D.PATH_COUNTS[n], "mission " .. n .. ": number of complete paths")

		for _, p in ipairs(paths) do
			local label = "mission " .. n .. " path {" .. table.concat(p.choices, ",") .. "} ending on " .. p.transcript[#p.transcript].id

			-- every screen before the last one: nothing started, nothing written
			if #p.choices > 0 then
				H.reset()

				local prefix = { table.unpack(p.choices, 1, #p.choices - 1) }
				local player = offerPilot(n)
				local calls = tapChains()
				local rec = T.spyRewards()
				local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")

				T.converse(tr, player, prefix)
				restore()

				lu.assertEquals(#calls, 0, label .. ": startSpaceQuestChain calls before the last screen")
				lu.assertNil(attempted(player, n), label .. ": :attempted before the last screen")
				lu.assertEquals(activeMembers(player, n), {}, label .. ": active chain members before the last screen")
				lu.assertEquals(rec.rewards, {}, label .. ": rewardPlayer calls before the last screen")
				lu.assertEquals(#skills, 0, label .. ": grantSpaceSkill calls before the last screen")
			end

			H.reset()

			local player = offerPilot(n)
			local calls = tapChains()
			local rec = T.spyRewards()
			local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")
			local tierBefore = player.ghost.pilotTier

			T.converse(tr, player, p.choices)
			restore()

			lu.assertEquals(headIds(calls), { D.HEADS[n] }, label .. ": startSpaceQuestChain heads")
			lu.assertEquals(attempted(player, n), "1", label .. ": :attempted")
			lu.assertEquals(activeMembers(player, n), { D.HEADS[n] }, label .. ": active chain members (the head only)")
			lu.assertEquals(rec.rewards, {}, label .. ": rewardPlayer calls")
			lu.assertEquals(#skills, 0, label .. ": grantSpaceSkill calls")
			lu.assertEquals(player.ghost.pilotTier, tierBefore, label .. ": pilot tier")
			lu.assertNil(rewarded(player, n), label .. ": :reward")

			for other = 1, 4 do
				if other ~= n then
					lu.assertEquals(attempted(player, other), other < n and "1" or nil, label .. ": :attempted of mission " .. other)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-5: failures (D-9)
---------------------------------------------------------------------------------------------

TestDuliosFailures = {}

function TestDuliosFailures:setUp() H.reset() end
function TestDuliosFailures:tearDown() restore() end

-- The failed states of mission n: no chain entry, or the head complete and a later member failed (neither active nor complete)
local function failedStates(n)
	local states = { { "no_entry", {} } }

	for _, i in ipairs(T.failPositions(tr, n)) do
		states[#states + 1] = { "member_" .. i .. "_failed", T.before(tr, n, i) }
	end

	return states
end

for n = 1, 4 do
	for _, state in ipairs(failedStates(n)) do
		local complete = state[2]

		-- AC-5: the first screen is the failure screen and showing only it starts nothing
		TestDuliosFailures["test_mission_" .. n .. "_attempted_and_not_won_with_" .. state[1] .. "_shows_" .. D.FAILED[n] .. "_and_starts_nothing"] = function()
			local player = T.player(tr, n, { complete = complete })
			local calls = tapChains()
			local rec = T.spyAllQuests()
			local before = attempted(player, n)

			local transcript = T.converse(tr, player)

			restore()
			lu.assertEquals(transcript[1].id, D.FAILED[n], "mission " .. n .. " (" .. state[1] .. "): first screen")
			lu.assertEquals(#transcript, 1, "mission " .. n .. ": screens shown with no choice made")
			lu.assertEquals(#transcript[1].options, 2, "mission " .. n .. ": the failure screen offers two replies")
			lu.assertEquals(#calls, 0, "mission " .. n .. ": startSpaceQuestChain calls")
			lu.assertEquals(rec.starts, {}, "mission " .. n .. ": startQuest calls")
			noOneIsPaid(rec, n)
			lu.assertEquals(attempted(player, n), before, "mission " .. n .. ": :attempted")
			lu.assertEquals(activeMembers(player, n), {}, "mission " .. n .. ": active chain members")
		end

		-- AC-5: each reply leads to its m<n>_retry_* screen, which ends and starts the head once; the head is then the only active member
		for reply = 0, 1 do
			TestDuliosFailures["test_mission_" .. n .. "_with_" .. state[1] .. "_reply_" .. (reply + 1) .. "_leads_to_" .. D.RETRY_STARTS[n][reply + 1] .. "_and_restarts_the_head"] = function()
				local player = T.player(tr, n, { complete = complete })
				local calls = tapChains()
				local rec = T.spyRewards()
				local skills = H.spyOn(SpaceHelpers, "grantSpaceSkill")

				local transcript = T.converse(tr, player, { reply })

				restore()
				lu.assertEquals(#transcript, 2, "mission " .. n .. " reply " .. (reply + 1) .. ": screens shown")
				lu.assertEquals(transcript[2].id, D.RETRY_STARTS[n][reply + 1], "mission " .. n .. " reply " .. (reply + 1) .. ": second screen")
				lu.assertTrue(transcript[2].stop, "mission " .. n .. " reply " .. (reply + 1) .. ": the retry screen ends the conversation")
				lu.assertEquals(headIds(calls), { D.HEADS[n] }, "mission " .. n .. " reply " .. (reply + 1) .. ": startSpaceQuestChain heads")
				lu.assertEquals(attempted(player, n), "1", "mission " .. n .. ": :attempted")
				lu.assertEquals(activeMembers(player, n), { D.HEADS[n] }, "mission " .. n .. " reply " .. (reply + 1) .. ": active chain members")
				noOneIsPaid(rec, n)
				lu.assertEquals(#skills, 0, "mission " .. n .. ": grantSpaceSkill calls")
			end
		end
	end
end

-- AC-5: a mission whose chain member is still running is "on a mission", never a failure
function TestDuliosFailures:test_an_attempted_mission_with_its_head_still_active_shows_on_mission_not_the_failure_screen()
	for n = 1, 4 do
		local player = T.player(tr, n, { active = { tr.chains[n][1] } })

		lu.assertEquals(T.converse(tr, player)[1].id, "on_mission", "mission " .. n .. " head active: first screen")
	end
end

-- AC-5, D-9: all eight failure replies are start screens (and only they, with the 18 offer-path ones, start missions)
function TestDuliosFailures:test_the_eight_failure_replies_are_among_the_26_start_screens()
	local replies = 0

	for n = 1, 4 do
		for _, id in ipairs(D.RETRY_STARTS[n]) do
			replies = replies + 1
			lu.assertEquals(D.START_SCREENS[id], n, id .. ": start screen of mission")
		end
	end

	lu.assertEquals(replies, 8, "failure-reply start screens")
end
