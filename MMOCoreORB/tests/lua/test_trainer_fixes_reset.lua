-- A squadron reset (surrender the pilot profession) must clear every quest the trainers' win and
-- "mission running" checks read, otherwise a rejoined pilot is routed to a reward screen.
-- Review finding R-1 of .claude/work/space-trainer-fixes/04-review.md (Viopa's reset left the M1 child complete).
-- The quests each check reads are the chain members (table C of the spec, = SpaceHelpers:getSpaceQuestChain).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")

T.load()

-- trainer -> { squadron screenplay global, reset function name }, as called from SpaceHelpers:surrenderPilot
local RESETS = {
	rhea = { "CorsecSquadronScreenplay", "resetRheaQuests" },
	rikkh = { "CorsecSquadronScreenplay", "resetRikkhQuests" },
	ramna = { "CorsecSquadronScreenplay", "resetRamnaQuests" },
	turoldine = { "CorsecSquadronScreenplay", "resetTuroldineQuests" },
	dinge = { "RsfSquadronScreenplay", "resetDingeQuests" },
	kaydine = { "RsfSquadronScreenplay", "resetKaydineQuests" },
	dulios = { "RsfSquadronScreenplay", "resetDuliosQuests" },
	kreezo = { "HavocSquadronScreenplay", "resetKreezoQuests" },
	viopa = { "HavocSquadronScreenplay", "resetViopaQuests" },
	aqzow = { "HavocSquadronScreenplay", "resetAqzowQuests" },
}

local SQUADRON_TRAINERS = {
	{ constant = "CORSEC_SQUADRON", trainers = { "rhea", "rikkh", "ramna", "turoldine" } },
	{ constant = "RSF_SQUADRON", trainers = { "dinge", "kaydine", "dulios" } },
	{ constant = "HAVOC_SQUADRON", trainers = { "kreezo", "viopa", "aqzow" } },
}

local function allMembers(tr)
	local out = {}

	for n = 1, 4 do
		for _, g in ipairs(tr.chains[n]) do
			out[#out + 1] = g
		end
	end

	return out
end

-- The pilot has won and been rewarded for all four missions of the trainer
local function veteran(tr)
	return T.player(tr, 4, { win = { 1, 2, 3, 4 } })
end

local function remaining(player, members)
	local left = {}

	for _, g in ipairs(members) do
		if T.state(player, g) ~= "none" then
			left[#left + 1] = g .. "=" .. T.state(player, g)
		end
	end

	return left
end

TestSquadronReset = {}

function TestSquadronReset:setUp()
	H.reset()
end

for _, key in ipairs(T.ORDER) do
	local tr = T.TRAINERS[key]
	local reset = RESETS[key]

	-- R-1
	TestSquadronReset["test_" .. reset[2] .. "_clears_every_quest_of_the_four_" .. key .. "_chains"] = function()
		local player = veteran(tr)

		lu.assertEquals(#remaining(player, allMembers(tr)), #allMembers(tr), tr.label .. " setup: every chain member is complete")

		H.expectGlobal(reset[1], "squadron screenplay")[reset[2]](_G[reset[1]], player)

		lu.assertEquals(remaining(player, allMembers(tr)), {}, tr.label .. ": chain members still in the journal after " .. reset[2])
	end

	-- R-1
	TestSquadronReset["test_" .. key .. "_pays_no_reward_to_a_pilot_who_rejoins_after_" .. reset[2]] = function()
		local player = veteran(tr)

		_G[reset[1]][reset[2]](_G[reset[1]], player)

		local rec = T.spyAllQuests()
		local transcript = T.converse(tr, player)

		lu.assertNotNil(transcript[1], tr.label .. ": no first screen after the reset")
		lu.assertEquals(rec.rewards, {}, tr.label .. ": rewardPlayer calls after the reset (first screen '" .. tostring(transcript[1].id) .. "')")
	end
end

-- R-1: the whole surrender path, per squadron
for _, entry in ipairs(SQUADRON_TRAINERS) do
	-- R-1
	TestSquadronReset["test_surrender_pilot_clears_every_chain_member_of_the_" .. entry.constant:lower()] = function()
		for _, key in ipairs(entry.trainers) do
			local tr = T.TRAINERS[key]
			local player = veteran(tr)

			player.ghost:setSquadronType(rawget(_G, entry.constant))
			SpaceHelpers:surrenderPilot(player)

			lu.assertEquals(remaining(player, allMembers(tr)), {}, tr.label .. ": chain members still in the journal after surrenderPilot")
		end
	end
end
