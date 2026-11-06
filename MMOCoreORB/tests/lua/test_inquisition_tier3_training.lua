-- Inquisitor Vrke: one-click, free-choice, free tier 3 training, one skill per mission, and the Barlow flag the mission 1 grants set.
-- Spec: .claude/work/inquisition-tier3-vrke/01-spec.md (AC-9; Conversation flow 2 (C-1), 3 and 3.4; FV-1, FV-2; D-3, D-8; I-10).
--
-- A training screen of mission n shows one topic reply per missing _03 skill (C-1). The reply links to m<n>_trained_<x>; the grant happens in
-- getNextConversationScreen through SpaceHelpers:grantSpaceSkill(p, skill, false) (J3 noisyGrantSkill: no XP check, no XP charge).

local lu = require("luaunit")
local H = require("harness")
local V = require("inquisition_tier3_data")
local CS = require("harness.client_strings")

V.load()

local original

local function setUp()
	H.reset()
	V.requireConversation(lu)
end

-- Records every SpaceHelpers:grantSpaceSkill(p, skill, deductExperience) call and runs the original
local function recordGrants()
	original = original or SpaceHelpers.grantSpaceSkill

	local calls = {}

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct, n = select("#", pPlayer, skill, deduct) }

		return original(self, pPlayer, skill, deduct)
	end

	return calls
end

local function restoreGrants()
	if original ~= nil then
		SpaceHelpers.grantSpaceSkill = original
	end
end

-- Mission n won (paid) with the given tier 3 skills (their number must be n - 1 for a reward dialogue to be pending)
local function pilot(n, held, extra)
	local paid = {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { paid = paid, t3 = held, mission = { [n] = "won" }, spoke = n >= 2 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return V.pilot(o)
end

-- every subset of {1..4} with `size` elements, in order
local function subsets(size)
	local out = {}

	local function rec(start, cur)
		if #cur == size then
			out[#out + 1] = { table.unpack(cur) }
			return
		end

		for i = start, 4 do
			cur[#cur + 1] = i
			rec(i + 1, cur)
			cur[#cur] = nil
		end
	end

	rec(1, {})

	return out
end

local function missing(held)
	local has, out = {}, {}

	for _, i in ipairs(held) do
		has[i] = true
	end

	for i = 1, 4 do
		if not has[i] then
			out[#out + 1] = i
		end
	end

	return out
end

local function holds(player, i) return CreatureObject(player):hasSkill(V.TRAIN[i].skill) end

local function count(player)
	local n = 0

	for i = 1, 4 do
		if holds(player, i) then
			n = n + 1
		end
	end

	return n
end

local function name(held) return table.concat(held, "") end

TestInquisitionT3Training = {}

TestInquisitionT3Training.setUp = setUp

function TestInquisitionT3Training:tearDown() restoreGrants() end

-- AC-9, C-1: each training screen lists exactly the missing _03 skills, in table order
function TestInquisitionT3Training:test_each_training_screen_lists_exactly_the_missing_skills_in_table_order()
	for screen, n in pairs(V.TRAINING_SCREENS) do
		for _, held in ipairs(subsets(n - 1)) do
			H.reset()

			local player = pilot(n, held)
			local t = V.drive(player, screen)
			local want, replies, links = missing(held), {}, {}

			for k, i in ipairs(want) do
				replies[k] = V.TRAIN[i].reply
				links[k] = V.trained(n, i)
			end

			lu.assertEquals(V.optionSids(t[1]), replies, screen .. " holding {" .. name(held) .. "}: topic replies")
			lu.assertEquals(V.linksOf(t[1]), links, screen .. " holding {" .. name(held) .. "}: links")
			lu.assertFalse(t[1].stop, screen .. " holding {" .. name(held) .. "}: the screen does not end the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-9, C-1: with none missing the screen has no option and stops
function TestInquisitionT3Training:test_with_all_four_skills_held_the_m4_training_screens_have_no_option_and_stop()
	for _, screen in ipairs({ "m4_training", "m4_training_bah" }) do
		local player = pilot(4, { 1, 2, 3, 4 })
		local t = V.drive(player, screen)

		lu.assertEquals(#t[1].options, 0, screen .. ": no option")
		lu.assertTrue(t[1].stop, screen .. " stops the conversation")
	end
end

-- AC-9, I-10: choosing a topic grants that skill free, through grantSpaceSkill(p, skill, false), and shows m<n>_trained_<x>
function TestInquisitionT3Training:test_choosing_a_topic_grants_that_skill_for_free_and_shows_the_trained_screen_of_the_mission()
	for screen, n in pairs(V.TRAINING_SCREENS) do
		for _, held in ipairs(subsets(n - 1)) do
			for _, i in ipairs(missing(held)) do
				for _, xp in ipairs({ 0, 200000 }) do
					H.reset()
					restoreGrants()

					local calls = recordGrants()
					local player = pilot(n, held, { xp = xp })
					local label = screen .. " holding {" .. name(held) .. "} choosing " .. V.TRAIN[i].x .. " with " .. xp .. " XP"
					local t = V.drive(player, screen, { V.TRAIN[i].reply })

					lu.assertEquals(V.ids(t), { screen, V.trained(n, i) }, label .. ": screens shown")
					lu.assertEquals(t[2].text, V.PREFIX .. V.TRAIN[i].trainedSid[n], label .. ": the grant line")
					lu.assertTrue(t[2].stop, label .. ": the trained screen ends the conversation")
					lu.assertTrue(holds(player, i), label .. ": the skill is held")
					lu.assertEquals(count(player), n, label .. ": the _03 count equals n")
					lu.assertEquals(#calls, 1, label .. ": grantSpaceSkill calls")
					lu.assertEquals({ calls[1].skill, calls[1].deduct }, { V.TRAIN[i].skill, false }, label .. ": grantSpaceSkill(p, skill, false)")
					lu.assertEquals(#V.free(), 1, label .. ": free grants (awardSkill)")
					lu.assertEquals(#V.bought(), 0, label .. ": no XP-deducting grant")
					lu.assertEquals(player.ghost.experience.space_combat_general, xp, label .. ": the XP is unchanged")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
				end
			end
		end
	end
end

-- AC-9, I-10: even a priced skill is not charged (the engine's XP model is on)
function TestInquisitionT3Training:test_the_skill_costs_no_xp_even_when_the_engine_would_charge()
	local costs = {}

	for i = 1, 4 do
		costs[V.TRAIN[i].skill] = 100000
	end

	H.Engine.config.skillXpCosts = costs

	local player = pilot(1, {}, { xp = 150000 })
	local t = V.drive(player, "m1_training", { V.TRAIN[2].reply })

	lu.assertEquals(V.ids(t), { "m1_training", "m1_trained_weapons" }, "screens shown")
	lu.assertTrue(holds(player, 2), "the weapons skill is held")
	lu.assertEquals(player.ghost.experience.space_combat_general, 150000, "no XP charged")
end

-- AC-9, I-10: the whole walk, M1, from the first screen to the grant
function TestInquisitionT3Training:test_the_first_talk_after_mission_1_pays_trains_and_ends_on_the_trained_screen()
	local player = pilot(1, {})
	local replies = {}

	-- the debrief: breadth-first over Appendix A from the reward screen to m1_training
	local found = { m1_reward = { replies = {} } }
	local queue = { "m1_reward" }

	while #queue > 0 do
		local id = table.remove(queue, 1)

		if id == "m1_training" then
			replies = found[id].replies
			break
		end

		for _, o in ipairs(V.screenRow(id).options) do
			if found[o[2]] == nil then
				local r = { table.unpack(found[id].replies) }

				r[#r + 1] = o[1]
				found[o[2]] = { replies = r }
				queue[#queue + 1] = o[2]
			end
		end
	end

	replies[#replies + 1] = V.TRAIN[3].reply

	local t = V.talk(player, replies)

	lu.assertEquals(t[1].id, "m1_reward", "first screen")
	lu.assertEquals(t[#t].id, "m1_trained_procedures", "last screen")
	lu.assertTrue(holds(player, 3), "the procedures skill is held")
	lu.assertEquals(count(player), 1, "one _03 skill")
	lu.assertEquals(player.bankCredits, V.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(V.firstScreen(player), "barlow_pending", "the next talk: Barlow's interview comes first")
end

-- AC-9: guard failures grant nothing and route by the gates
function TestInquisitionT3Training:test_a_skill_already_held_grants_nothing_and_routes_by_the_gates()
	-- the skill arrives while the screen is shown (the pilot got it elsewhere), then the pilot clicks its topic
	local player = pilot(2, { 2 })
	local grab = function(p) p.skills[V.TRAIN[1].skill] = true end
	local calls = recordGrants()
	local t = V.drive(player, "m2_training", { grab, V.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call for a skill already held")
	lu.assertEquals(#V.free() + #V.bought(), 0, "no grant")
	lu.assertNotEquals(t[#t].id, "m2_trained_starships", "the trained screen is not shown")
	lu.assertEquals(count(player), 2, "count stays at 2 (weapons, and starships got elsewhere)")
end

-- AC-9, I-10: a training screen of a mission with no pending reward dialogue grants nothing
function TestInquisitionT3Training:test_a_training_screen_of_a_mission_without_a_pending_reward_grants_nothing()
	-- mission 2's lead-in with mission 1's skill unchosen: getRewardMission is 1, not 2
	local player = pilot(2, {})
	local calls = recordGrants()
	local t = V.drive(player, "m2_training", { V.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call")
	lu.assertEquals(count(player), 0, "no skill")
	lu.assertEquals(t[#t].id, "m1_reward", "routed by the gates: mission 1's reward is pending")

	-- mission 1 never won: nothing to train for
	local fresh = V.pilot({})

	t = V.drive(fresh, "m1_training", { V.TRAIN[1].reply })
	lu.assertEquals(count(fresh), 0, "no skill before mission 1 is won")
	lu.assertEquals(t[#t].id, "m1_offer", "routed by the gates: mission 1 is offered")

	-- the later training screen after the earlier one was won: only the pending mission's lead-in grants
	local wrong = pilot(1, {})

	V.drive(wrong, "m3_training", { V.TRAIN[1].reply })
	lu.assertEquals(count(wrong), 0, "mission 3's lead-in does not grant while mission 1's reward is pending")
end

-- AC-9, I-10: one skill per mission: a second click on the same or another topic grants nothing more
function TestInquisitionT3Training:test_a_second_choice_in_the_same_mission_grants_nothing_more()
	local player = pilot(1, {})

	V.drive(player, "m1_training", { V.TRAIN[1].reply })
	lu.assertEquals(count(player), 1, "after the first choice")

	local calls = recordGrants()
	local t = V.drive(player, "m1_training_best", { V.TRAIN[2].reply })

	lu.assertEquals(#calls, 0, "no second grant")
	lu.assertEquals(count(player), 1, "still one skill")
	lu.assertNotEquals(t[#t].id, "m1_trained_weapons", "the weapons grant line is not shown")
end

-- AC-9: the fourth skill raises pilot tier 3 -> 4; the earlier ones do not
function TestInquisitionT3Training:test_the_fourth_skill_raises_pilot_tier_3_to_4()
	for _, last in ipairs({ 1, 2, 3, 4 }) do
		H.reset()

		local held = {}

		for i = 1, 4 do
			if i ~= last then
				held[#held + 1] = i
			end
		end

		local player = pilot(4, held, { pilotTier = 3 })

		V.drive(player, "m4_training", { V.TRAIN[last].reply })
		lu.assertEquals(count(player), 4, "four skills after choosing " .. V.TRAIN[last].x)
		lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the fourth skill (" .. V.TRAIN[last].x .. " last)")
	end

	for n = 1, 3 do
		H.reset()

		local held = {}

		for i = 1, n - 1 do
			held[i] = i
		end

		local player = pilot(n, held, { pilotTier = 3 })

		V.drive(player, V.MISSIONS[n].training, { V.TRAIN[n].reply })
		lu.assertEquals(player.ghost.pilotTier, 3, "mission " .. n .. ": pilot tier stays 3 before the fourth skill")
	end

	local p4 = pilot(4, { 2, 3, 4 }, { pilotTier = 4 })

	V.drive(p4, "m4_training", { V.TRAIN[1].reply })
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot is not raised again")
end

-- AC-9, FV-2, D-8: only an M1 grant sets QUESTION_BARLOW_KEY
function TestInquisitionT3Training:test_only_an_m1_grant_sets_the_question_barlow_key()
	for i = 1, 4 do
		H.reset()

		local player = pilot(1, {})

		lu.assertNil(H.getQuestStatus(player, V.QUESTION_SUFFIX), "precondition: unset")
		V.drive(player, "m1_training", { V.TRAIN[i].reply })
		lu.assertEquals(H.getQuestStatus(player, V.QUESTION_SUFFIX), "1", "M1 grant of " .. V.TRAIN[i].x .. " sets the key")
		lu.assertNil(H.getQuestStatus(player, V.SPOKE_SUFFIX), "M1 grant of " .. V.TRAIN[i].x .. ": the spoke key stays unset")
	end

	for n = 2, 4 do
		for i = 1, 4 do
			local held = {}

			for k = 1, 4 do
				if #held < n - 1 and k ~= i then
					held[#held + 1] = k
				end
			end

			for _, initial in ipairs({ false, true }) do
				H.reset()

				local player = pilot(n, held, { question = initial })

				V.drive(player, V.MISSIONS[n].training, { V.TRAIN[i].reply })
				lu.assertEquals(count(player), n, "precondition: the grant happened (mission " .. n .. ", " .. V.TRAIN[i].x .. ")")
				lu.assertEquals(H.getQuestStatus(player, V.QUESTION_SUFFIX), initial and "1" or nil, "M" .. n .. " grant of " .. V.TRAIN[i].x .. ": QUESTION_BARLOW_KEY unchanged (started " .. tostring(initial) .. ")")
			end
		end
	end
end

-- AC-9: no other screen sets or clears the question key (the M1 trained screens are the only carriers)
function TestInquisitionT3Training:test_no_screen_but_the_four_m1_trained_screens_touches_the_question_key()
	for _, row in ipairs(V.SCREENS) do
		local carrier = row.id:match("^m1_trained_%a+$") ~= nil

		for _, initial in ipairs({ false, true }) do
			H.reset()

			local player = V.pilot({ question = initial, paid = { 1 }, t3 = { 1 }, mission = { [2] = "won" } })

			V.drive(player, row.id)
			lu.assertEquals(H.getQuestStatus(player, V.QUESTION_SUFFIX), (carrier or initial) and "1" or nil, "screen " .. row.id .. " (key started " .. tostring(initial) .. ")")
		end
	end
end

-- AC-9: the trained screens themselves grant nothing when shown (the grant is the choice)
function TestInquisitionT3Training:test_displaying_a_trained_screen_directly_grants_no_skill()
	for n = 1, 4 do
		for i = 1, 4 do
			H.reset()

			local player = pilot(n, {})

			V.drive(player, V.trained(n, i))
			lu.assertEquals(#V.free() + #V.bought(), 0, V.trained(n, i) .. ": no skill granted by display")
		end
	end
end

-- AC-9: after each skill the next visit opens the next screen
function TestInquisitionT3Training:test_after_each_skill_the_next_visit_opens_what_comes_next()
	local want = { "barlow_pending", "m3_offer", "m4_offer", "tour_complete" }

	for n = 1, 4 do
		H.reset()

		local held = {}

		for i = 1, n - 1 do
			held[i] = i
		end

		local player = pilot(n, held)

		V.drive(player, V.MISSIONS[n].training, { V.TRAIN[n].reply })

		-- Barlow done after mission 1; mission 4's reward is paid by its reward screen first
		if n == 1 then
			removeQuestStatus(player.objectID .. V.QUESTION_SUFFIX)
			setQuestStatus(player.objectID .. V.SPOKE_SUFFIX, 1)
		end

		if n == 4 then
			V.drive(player, "m4_reward")
		end

		if n == 1 then
			lu.assertEquals(V.firstScreen(player), "m2_offer", "after Barlow cleared the question")
		else
			lu.assertEquals(V.firstScreen(player), want[n], "first screen after mission " .. n .. "'s skill was chosen")
		end
	end
end
