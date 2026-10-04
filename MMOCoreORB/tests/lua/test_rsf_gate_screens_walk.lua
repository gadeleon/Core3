-- The off-track pilot cannot get past the duty screens: an exhaustive walk of every option path of depth 6 from each trainer's first screen.
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-7, invariants I-4 and I-5, "What the off-track pilot can reach").
--
-- space-convo-client-strings-dinge (AC-6, D-10): Dinge's exact-union walk test expects G.DINGE_REACH_NOW (duty_not_now is deleted, not_ready takes its place).
--
-- Every path is a fresh pilot (a CorSec neutral pilot with 0, 1 or all 4 tier 1 skills and no quest) and a fresh conversation. Quest
-- starts and rewards are recorded, not run. The ghost mutators are replaced on the fake ghost class so one set of spies serves every path.

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local G = require("rsf_gate_screens_data")

T.load()

local DEPTH = 6

local function ghostClass()
	return getmetatable(G.offTrack({}).ghost)
end

-- Walks every option path of at most DEPTH choices. Returns
--   { visited = {screen id -> true}, paths = n, starts = {global -> count}, maxStartsPerPath = n, rewards = n, chains = n, skills = n,
--     squadron = n, tiers = n, ships = n, status = {keys written}, deepest = n }
local function walkAll(trainer, build)
	H.reset()

	local out = { visited = {}, paths = 0, starts = {}, maxStartsPerPath = 0, deepest = 0 }
	local rec = G.spies(nil)
	local squadron = H.spyOn(ghostClass(), "setSquadronType")
	local tiers = H.spyOn(ghostClass(), "incrementPilotTier")
	local statusBefore = G.statusSnapshot()
	local shipsBefore = G.shipGrants()
	local grantsBefore = #H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill")

	local function dfs(prefix)
		local startsBefore = #rec.starts
		local transcript = G.converse(trainer, build(), prefix)

		out.paths = out.paths + 1
		out.deepest = math.max(out.deepest, #prefix)

		for _, step in ipairs(transcript) do
			out.visited[step.id] = true
		end

		local newStarts = #rec.starts - startsBefore

		out.maxStartsPerPath = math.max(out.maxStartsPerPath, newStarts)

		for i = startsBefore + 1, #rec.starts do
			out.starts[rec.starts[i]] = (out.starts[rec.starts[i]] or 0) + 1
		end

		local last = transcript[#transcript]

		if #prefix < DEPTH and last ~= nil and not last.stop and #transcript == #prefix + 1 then
			for i = 0, #last.options - 1 do
				local nextPrefix = {}

				for k, v in ipairs(prefix) do nextPrefix[k] = v end

				nextPrefix[#nextPrefix + 1] = i
				dfs(nextPrefix)
			end
		end
	end

	dfs({})

	out.rewards = #rec.rewards
	out.chains = #rec.chains
	out.skills = #rec.skills + #H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill") - grantsBefore
	out.squadron = #squadron
	out.tiers = #tiers
	out.ships = G.shipGrants() - shipsBefore
	out.status = G.statusDiff(statusBefore, G.statusSnapshot())

	return out
end

local TRAINERS = {
	kaydine = { reach = G.KAYDINE_REACH, duties = { G.KAYDINE_DUTIES.escort, G.KAYDINE_DUTIES.recovery, G.KAYDINE_DUTIES.destroy } },
	dinge = { reach = G.DINGE_REACH, exact = G.DINGE_REACH_NOW, duties = { G.DINGE_DUTIES.destroy, G.DINGE_DUTIES.escort } },
}

local SKILL_COUNTS = { 0, 1, 4 }

local function setOf(list)
	local set = {}

	for _, v in ipairs(list) do set[v] = true end

	return set
end

TestOffTrackWalk = {}

function TestOffTrackWalk:setUp() H.reset() end

for _, trainer in ipairs({ "kaydine", "dinge" }) do
	local spec = TRAINERS[trainer]

	for _, skills in ipairs(SKILL_COUNTS) do
		-- AC-7, I-4: no screen outside the duty screens is reachable
		TestOffTrackWalk["test_" .. trainer .. "_off_track_pilot_with_" .. skills .. "_tier_1_skills_reaches_only_the_gate_and_duty_screens"] = function()
			local walk = walkAll(trainer, function() return G.offTrack({ tier1 = skills }) end)
			local allowed = setOf(spec.reach)
			local outside = {}

			for id in pairs(walk.visited) do
				if not allowed[id] then
					outside[#outside + 1] = id
				end
			end

			table.sort(outside)
			lu.assertEquals(outside, {}, trainer .. " (" .. skills .. " tier 1 skills, " .. walk.paths .. " paths): screens reached outside the off-track set")
			lu.assertTrue(walk.paths >= 2, trainer .. ": paths walked: " .. walk.paths)
		end

		-- AC-7, I-4, I-5: only that trainer's duties start, one per conversation, and nothing else changes
		TestOffTrackWalk["test_" .. trainer .. "_off_track_pilot_with_" .. skills .. "_tier_1_skills_starts_at_most_one_of_the_trainers_duties_and_changes_nothing_else"] = function()
			local walk = walkAll(trainer, function() return G.offTrack({ tier1 = skills }) end)
			local allowed = setOf(spec.duties)

			for global in pairs(walk.starts) do
				lu.assertTrue(allowed[global] == true, trainer .. ": a quest other than the trainer's duties was started: " .. global)
			end

			lu.assertTrue(walk.maxStartsPerPath <= 1, trainer .. ": most quests started in one conversation: " .. walk.maxStartsPerPath)

			if skills == 0 then
				lu.assertEquals(walk.starts, {}, trainer .. ": a pilot without tier 1 skills starts nothing")
			end

			lu.assertEquals(walk.rewards, 0, trainer .. ": rewardPlayer calls")
			lu.assertEquals(walk.chains, 0, trainer .. ": story chains started")
			lu.assertEquals(walk.skills, 0, trainer .. ": skills granted (grantSpaceSkill, awardSkill, skillManagerAwardSkill)")
			lu.assertEquals(walk.squadron, 0, trainer .. ": setSquadronType calls")
			lu.assertEquals(walk.tiers, 0, trainer .. ": incrementPilotTier calls")
			lu.assertEquals(walk.ships, 0, trainer .. ": grantStarterShip calls")
			lu.assertEquals(walk.status, {}, trainer .. ": quest status keys written (:attempted, :reward, ...; Kaydine's legacyVersion excluded)")
		end
	end

	-- AC-7: the three skill counts together reach every screen of the off-track set (the set is not wider than the flow)
	TestOffTrackWalk["test_" .. trainer .. "_the_walks_of_0_1_and_4_skills_together_reach_exactly_the_off_track_set_and_start_every_duty"] = function()
		local union, starts = {}, {}

		for _, skills in ipairs(SKILL_COUNTS) do
			local walk = walkAll(trainer, function() return G.offTrack({ tier1 = skills }) end)

			for id in pairs(walk.visited) do union[id] = true end
			for global in pairs(walk.starts) do starts[global] = true end
		end

		lu.assertEquals(G.sortedKeys(union), spec.exact or spec.reach, trainer .. ": screens reached by the walks")
		lu.assertEquals(G.sortedKeys(starts), G.sortedKeys(setOf(spec.duties)), trainer .. ": duties started by the walks")
	end
end

-- AC-7: the walk really goes deep (the Dinge loop what_is_duty / duty_no_training takes the full depth)
function TestOffTrackWalk:test_the_dinge_walk_reaches_the_full_depth_of_6_choices()
	local walk = walkAll("dinge", function() return G.offTrack({ tier1 = 1 }) end)

	lu.assertEquals(walk.deepest, DEPTH, "deepest prefix walked")
	lu.assertTrue(walk.paths > 100, "paths walked: " .. walk.paths)
end
