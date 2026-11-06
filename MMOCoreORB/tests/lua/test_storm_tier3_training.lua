-- Captain Denner: one-click, free-choice, free tier 3 training, one skill per mission, and the hand-off to Admiral Kilnstrider (pilot tier 4).
-- Spec: .claude/work/storm-tier3-denner/01-spec.md (B-6, B-7; Conversation flow 2 (C-1), 3 and 4; FD-1, FD-2; D-3, D-4, D-5; I-11).
--
-- A training screen of mission n shows one topic reply per missing _03 skill (C-1). The reply links to the shared trained_<x> screen; the grant happens in
-- getNextConversationScreen through SpaceHelpers:grantSpaceSkill(p, skill, false) (J3 noisyGrantSkill: no XP check, no XP charge).

local lu = require("luaunit")
local H = require("harness")
local D = require("storm_tier3_data")
local CS = require("harness.client_strings")

D.loadConversation()

local original

local function setUp()
	H.reset()
	D.requireConversation(lu)
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

-- Mission n won and unpaid, missions 1..n-1 paid, with the given tier 3 skills (their number must be n - 1 for a reward dialogue to be pending)
local function pilot(n, held, extra)
	local o = { missions = n - 1, t3 = held, won = n }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return D.pilot(o)
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

local function holds(player, i) return CreatureObject(player):hasSkill(D.TRAIN[i].skill) end

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

local function sortedKeys(t)
	local out = {}

	for k in pairs(t) do
		out[#out + 1] = k
	end

	table.sort(out)
	return out
end

TestStormT3Training = {}

TestStormT3Training.setUp = setUp

function TestStormT3Training:tearDown() restoreGrants() end

-- B-6, C-1: each training screen lists exactly the missing _03 skills, in table order
function TestStormT3Training:test_each_training_screen_lists_exactly_the_missing_skills_in_table_order()
	for _, screen in ipairs(sortedKeys(D.TRAINING_SCREENS)) do
		local n = D.TRAINING_SCREENS[screen]

		for _, held in ipairs(subsets(n - 1)) do
			H.reset()

			local player = pilot(n, held)
			local t = D.drive(player, screen)
			local want, replies, links = missing(held), {}, {}

			for k, i in ipairs(want) do
				replies[k] = D.TRAIN[i].reply
				links[k] = D.TRAIN[i].trained
			end

			lu.assertEquals(D.optionSids(t[1]), replies, screen .. " holding {" .. name(held) .. "}: topic replies")
			lu.assertEquals(D.linksOf(t[1]), links, screen .. " holding {" .. name(held) .. "}: links")
			lu.assertFalse(t[1].stop, screen .. " holding {" .. name(held) .. "}: the screen does not end the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- B-6, C-1: the list is the missing skills for any held set, not only the sets a mission n pilot can have (a skill got elsewhere)
function TestStormT3Training:test_the_topic_list_follows_the_held_skills_for_every_subset()
	for size = 0, 4 do
		for _, held in ipairs(subsets(size)) do
			H.reset()

			local t = D.drive(D.pilot({ missions = 3, t3 = held, won = 4 }), "m4_training_df0f8037")
			local replies = {}

			for k, i in ipairs(missing(held)) do
				replies[k] = D.TRAIN[i].reply
			end

			lu.assertEquals(D.optionSids(t[1]), replies, "m4_training_df0f8037 holding {" .. name(held) .. "}")
			lu.assertEquals(t[1].stop, size == 4, "m4_training_df0f8037 holding {" .. name(held) .. "}: stops only when nothing is missing")
		end
	end
end

-- B-6, C-1: with none missing the screen has no option and stops
function TestStormT3Training:test_with_all_four_skills_held_the_m4_training_screens_have_no_option_and_stop()
	for _, screen in ipairs({ "m4_training_df0f8037", "m4_training_d837376f", "m4_training_30651d99" }) do
		local player = pilot(4, { 1, 2, 3, 4 })
		local t = D.drive(player, screen)

		lu.assertEquals(#t[1].options, 0, screen .. ": no option")
		lu.assertTrue(t[1].stop, screen .. " stops the conversation")
	end
end

-- B-6, I-11: choosing a topic grants that skill free, through grantSpaceSkill(p, skill, false), and shows trained_<x>
function TestStormT3Training:test_choosing_a_topic_grants_that_skill_for_free_and_shows_the_trained_screen()
	for _, screen in ipairs(sortedKeys(D.TRAINING_SCREENS)) do
		local n = D.TRAINING_SCREENS[screen]

		for _, held in ipairs(subsets(n - 1)) do
			for _, i in ipairs(missing(held)) do
				for _, xp in ipairs({ 0, 200000 }) do
					H.reset()
					restoreGrants()

					local calls = recordGrants()
					local player = pilot(n, held, { xp = xp })
					local label = screen .. " holding {" .. name(held) .. "} choosing " .. D.TRAIN[i].x .. " with " .. xp .. " XP"
					local t = D.drive(player, screen, { D.TRAIN[i].reply })

					lu.assertEquals(D.ids(t), { screen, D.TRAIN[i].trained }, label .. ": screens shown")
					lu.assertEquals(t[2].text, D.PREFIX .. D.TRAIN[i].trainedSid, label .. ": the grant line")
					lu.assertTrue(t[2].stop, label .. ": the trained screen ends the conversation")
					lu.assertTrue(holds(player, i), label .. ": the skill is held")
					lu.assertEquals(count(player), n, label .. ": the _03 count equals n")
					lu.assertEquals(#calls, 1, label .. ": grantSpaceSkill calls")
					lu.assertEquals({ calls[1].skill, calls[1].deduct }, { D.TRAIN[i].skill, false }, label .. ": grantSpaceSkill(p, skill, false)")
					lu.assertEquals(#D.free(), 1, label .. ": free grants (awardSkill)")
					lu.assertEquals(#D.bought(), 0, label .. ": no XP-deducting grant")
					lu.assertEquals(player.ghost.experience.space_combat_general, xp, label .. ": the XP is unchanged")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
				end
			end
		end
	end
end

-- B-6, I-11: even a priced skill is not charged (the engine's XP model is on)
function TestStormT3Training:test_the_skill_costs_no_xp_even_when_the_engine_would_charge()
	local costs = {}

	for i = 1, 4 do
		costs[D.TRAIN[i].skill] = 100000
	end

	H.Engine.config.skillXpCosts = costs

	local player = pilot(1, {}, { xp = 150000 })
	local t = D.drive(player, "m1_training_813c7eed", { D.TRAIN[2].reply })

	lu.assertEquals(D.ids(t), { "m1_training_813c7eed", "trained_weapons" }, "screens shown")
	lu.assertTrue(holds(player, 2), "the weapons skill is held")
	lu.assertEquals(player.ghost.experience.space_combat_general, 150000, "no XP charged")
end

-- B-6, I-11: the whole walk, M1, from the first screen to the grant
function TestStormT3Training:test_the_first_talk_after_mission_1_pays_trains_and_ends_on_the_trained_screen()
	local player = pilot(1, {})
	local replies = D.walkToTraining(1)

	replies[#replies + 1] = D.TRAIN[3].reply

	local t = D.talk(player, replies)

	lu.assertEquals(t[1].id, "m1_reward", "first screen")
	lu.assertEquals(t[#t].id, "trained_procedures", "last screen")
	lu.assertTrue(holds(player, 3), "the procedures skill is held")
	lu.assertEquals(count(player), 1, "one _03 skill")
	lu.assertEquals(player.bankCredits, D.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(D.firstScreen(player), "m2_offer", "the next talk offers mission 2")
end

-- B-6: guard failures grant nothing and route by the gates
function TestStormT3Training:test_a_skill_already_held_grants_nothing_and_routes_by_the_gates()
	-- the skill arrives while the screen is shown (the pilot got it elsewhere), then the pilot clicks its topic
	local player = pilot(2, { 2 })
	local grab = function(p) p.skills[D.TRAIN[1].skill] = true end
	local calls = recordGrants()
	local t = D.drive(player, "m2_training_dc98dda7", { grab, D.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call for a skill already held")
	lu.assertEquals(#D.free() + #D.bought(), 0, "no grant")
	lu.assertNotEquals(t[#t].id, "trained_starships", "the trained screen is not shown")
	lu.assertEquals(count(player), 2, "count stays at 2 (weapons, and starships got elsewhere)")
end

-- B-6, I-11: a training screen of a mission with no pending reward dialogue grants nothing
function TestStormT3Training:test_a_training_screen_of_a_mission_without_a_pending_reward_grants_nothing()
	-- mission 2's lead-in with mission 1's skill unchosen: getRewardMission is 1, not 2
	local player = pilot(2, {})
	local calls = recordGrants()
	local t = D.drive(player, "m2_training_dc98dda7", { D.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call")
	lu.assertEquals(count(player), 0, "no skill")
	lu.assertEquals(t[#t].id, "m1_reward", "routed by the gates: mission 1's reward is pending")

	-- mission 1 never won: nothing to train for
	local fresh = D.pilot({})

	t = D.drive(fresh, "m1_training_813c7eed", { D.TRAIN[1].reply })
	lu.assertEquals(count(fresh), 0, "no skill before mission 1 is won")
	lu.assertEquals(t[#t].id, "m1_offer", "routed by the gates: mission 1 is offered")

	-- the later training screen after the earlier one was won: only the pending mission's lead-in grants
	local wrong = pilot(1, {})

	D.drive(wrong, "m3_training_1d7c7ed2", { D.TRAIN[1].reply })
	lu.assertEquals(count(wrong), 0, "mission 3's lead-in does not grant while mission 1's reward is pending")
end

-- B-6, I-11: one skill per mission: a second click on the same or another topic grants nothing more
function TestStormT3Training:test_a_second_choice_in_the_same_mission_grants_nothing_more()
	local player = pilot(1, {})

	D.drive(player, "m1_training_813c7eed", { D.TRAIN[1].reply })
	lu.assertEquals(count(player), 1, "after the first choice")

	local calls = recordGrants()
	local t = D.drive(player, "m1_training_c198d74c", { D.TRAIN[2].reply })

	lu.assertEquals(#calls, 0, "no second grant")
	lu.assertEquals(count(player), 1, "still one skill")
	lu.assertNotEquals(t[#t].id, "trained_weapons", "the weapons grant line is not shown")
end

-- B-6: a non-training choice (the debrief replies) grants nothing
function TestStormT3Training:test_the_debrief_replies_before_the_training_screen_grant_nothing()
	for n = 1, 4 do
		H.reset()

		local replies = D.walkToTraining(n)
		local player = pilot(n, D.t3(n - 1))

		-- every prefix of the walk except the last step is a non-training screen
		D.talk(player, { table.unpack(replies, 1, #replies - 1) })
		lu.assertEquals(#D.free() + #D.bought(), 0, "mission " .. n .. ": no skill before the training screen")
		lu.assertEquals(count(player), n - 1, "mission " .. n .. ": the count is unchanged")
	end
end

-- B-6, B-7: the fourth skill raises pilot tier 3 -> 4; the earlier ones do not
function TestStormT3Training:test_the_fourth_skill_raises_pilot_tier_3_to_4()
	for _, last in ipairs({ 1, 2, 3, 4 }) do
		H.reset()

		local held = {}

		for i = 1, 4 do
			if i ~= last then
				held[#held + 1] = i
			end
		end

		local player = pilot(4, held, { pilotTier = 3 })

		D.drive(player, "m4_training_df0f8037", { D.TRAIN[last].reply })
		lu.assertEquals(count(player), 4, "four skills after choosing " .. D.TRAIN[last].x)
		lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the fourth skill (" .. D.TRAIN[last].x .. " last)")
	end

	for n = 1, 3 do
		H.reset()

		local player = pilot(n, D.t3(n - 1), { pilotTier = 3 })

		D.drive(player, "m" .. n .. "_training_" .. ({ "813c7eed", "dc98dda7", "1d7c7ed2" })[n], { D.TRAIN[n].reply })
		lu.assertEquals(player.ghost.pilotTier, 3, "mission " .. n .. ": pilot tier stays 3 before the fourth skill")
	end

	local p4 = pilot(4, { 2, 3, 4 }, { pilotTier = 4 })

	D.drive(p4, "m4_training_df0f8037", { D.TRAIN[1].reply })
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot is not raised again")
end

-- B-6: the trained screens themselves grant nothing when shown (the grant is the choice)
function TestStormT3Training:test_displaying_a_trained_screen_directly_grants_no_skill()
	for n = 1, 4 do
		for i = 1, 4 do
			H.reset()

			local player = pilot(n, D.t3(n - 1))

			D.drive(player, D.TRAIN[i].trained)
			lu.assertEquals(#D.free() + #D.bought(), 0, D.TRAIN[i].trained .. ": no skill granted by display (mission " .. n .. ")")
			lu.assertEquals(player.ghost.pilotTier, 3, D.TRAIN[i].trained .. ": pilot tier unchanged")
		end
	end
end

-- B-6: after each skill the next visit opens the next screen
function TestStormT3Training:test_after_each_skill_the_next_visit_opens_what_comes_next()
	local want = { "m2_offer", "m3_offer", "m4_offer", "m4_reward" }
	local trainings = { "m1_training_813c7eed", "m2_training_dc98dda7", "m3_training_1d7c7ed2", "m4_training_df0f8037" }

	for n = 1, 4 do
		H.reset()

		local player = pilot(n, D.t3(n - 1))

		D.drive(player, trainings[n], { D.TRAIN[n].reply })
		lu.assertEquals(D.firstScreen(player), want[n], "first screen after mission " .. n .. "'s skill was chosen")
	end
end

---------------------------------------------------------------------------------------------
-- The whole career and the hand-off (B-7)
---------------------------------------------------------------------------------------------

TestStormT3Handoff = {}

TestStormT3Handoff.setUp = setUp

-- B-7: a pilot wins the four missions in turn, talks through each reward and training, and ends tier 4 with all four skills and four paid rewards
function TestStormT3Handoff:test_the_whole_career_ends_on_tour_complete_with_pilot_tier_4()
	local player = D.pilot({})
	local order = { 3, 1, 4, 2 }

	for n = 1, 4 do
		for _, global in ipairs(D.CHAINS[n]) do
			D.setState(player, global, "complete")
		end

		H.setQuestStatus(player, D.STATUS[n] .. ":attempted", 1)

		local replies = D.walkToTraining(n)

		replies[#replies + 1] = D.TRAIN[order[n]].reply

		local t = D.talk(player, replies)

		lu.assertEquals(t[1].id, "m" .. n .. "_reward", "mission " .. n .. ": first screen")
		lu.assertEquals(t[#t].id, D.TRAIN[order[n]].trained, "mission " .. n .. ": last screen")
		lu.assertEquals(count(player), n, "mission " .. n .. ": skills held")
		lu.assertEquals(player.ghost.pilotTier, n == 4 and 4 or 3, "mission " .. n .. ": pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "mission " .. n .. ": client strings")
	end

	lu.assertEquals(player.bankCredits, 4 * D.CREDITS, "four rewards paid once each")
	lu.assertEquals(D.standing(player), 4 * D.STANDING, "four times +100 standing")
	lu.assertEquals(#D.items(player), 4, "four ship components")

	for n = 1, 4 do
		lu.assertEquals(H.getQuestStatus(player, D.STATUS[n] .. ":reward"), "1", "mission " .. n .. " :reward")
	end

	-- the interface to tier 4 (Source inventory 6): four _03 skills, pilot tier 4, the mission 4 reward key
	lu.assertEquals(D.firstScreen(player), "tour_complete", "the next talk")
end

-- B-7: tour_complete raises a tier-3 pilot with four _03 skills to tier 4 and grants nothing else
function TestStormT3Handoff:test_tour_complete_raises_a_tier_3_pilot_with_four_skills_to_tier_4_and_grants_nothing_else()
	local player = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 }, pilotTier = 3 })
	local t = D.talk(player)

	lu.assertEquals(D.ids(t), { "tour_complete" }, "first screen")
	lu.assertEquals(t[1].text, D.PREFIX .. "s_704da203", "'Your time with me is over.'")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(#D.free() + #D.bought(), 0, "no skill granted")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(#D.items(player), 0, "no item")
	lu.assertEquals(D.standing(player), 0, "standing unchanged")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest started")
end

-- B-7: the raise happens once; a tier 4 pilot is not raised again, a pilot with fewer than four skills is not raised
function TestStormT3Handoff:test_tour_complete_raises_the_pilot_tier_only_for_tier_3_pilots_with_all_four_skills()
	local p4 = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 }, pilotTier = 4 })

	D.talk(p4)
	D.talk(p4)
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot stays at 4")

	local p3 = D.pilot({ missions = 4, t3 = { 1, 2, 3 }, pilotTier = 3 })

	D.drive(p3, "tour_complete")
	lu.assertEquals(p3.ghost.pilotTier, 3, "three skills: not raised")

	local fresh = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 }, pilotTier = 3 })

	D.talk(fresh)
	D.talk(fresh)
	lu.assertEquals(fresh.ghost.pilotTier, 4, "a second talk leaves it at 4")
end

-- B-7: with M4 unpaid the first screen is m4_reward, not tour_complete, and the pilot tier is raised by the training grant
function TestStormT3Handoff:test_with_mission_4_unpaid_the_first_screen_is_m4_reward()
	local player = D.pilot({ missions = 3, t3 = { 1, 2, 3, 4 }, won = 4, pilotTier = 4 })

	lu.assertEquals(D.firstScreen(player), "m4_reward", "four skills, M4 won and unpaid")
end

-- B-7: the three replies reach the three endings
function TestStormT3Handoff:test_the_three_replies_reach_the_three_endings()
	local cases = {
		{ replies = { "s_2dc37e6c", "s_936b8cfc" }, ids = { "tour_complete", "tour_a5f19408", "tour_a099839c" } },
		{ replies = { "s_4ec1bd6b" }, ids = { "tour_complete", "tour_7ea66fab" } },
		{ replies = { "s_69f62a43", "s_25c39c01" }, ids = { "tour_complete", "tour_a0aa65a4", "tour_66506cea" } },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local player = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } })
		local t = D.talk(player, c.replies)

		lu.assertEquals(D.ids(t), c.ids, "walk " .. table.concat(c.replies, ","))
		lu.assertTrue(t[#t].stop, t[#t].id .. " ends the conversation")
		lu.assertEquals(#t[#t].options, 0, t[#t].id .. " offers no reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(#D.free() + #D.bought(), 0, "no skill granted by the endings")
		lu.assertEquals(player.bankCredits, 0, "no credits from the endings")
	end
end

-- B-7: the endings name Admiral Kilnstrider and the research center on Endor; the name token endings greet by first name
function TestStormT3Handoff:test_the_endings_name_kilnstrider_and_greet_by_name()
	local player = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } })
	local t = D.talk(player, { "s_2dc37e6c" })

	lu.assertStrContains(require("storm_tier3_client_text").s_a5f19408, "Kilnstrider", false, "tour_a5f19408 names the Admiral")
	lu.assertEquals(t[2].id, "tour_a5f19408", "second screen")

	local named = D.talk(D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } }), { "s_4ec1bd6b" })

	lu.assertEquals(named[2].params.TU, "Ace", "tour_7ea66fab: %NU")

	local named2 = D.talk(D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } }), { "s_2dc37e6c", "s_936b8cfc" })

	lu.assertEquals(named2[3].params.TU, "Ace", "tour_a099839c: %NU")
end

-- B-7: the Kilnstrider hand-off is a dead end until tier 4 is ported: no quest, no flag, no conversation key is set by the endings
function TestStormT3Handoff:test_the_endings_set_no_quest_status_key()
	local player = D.pilot({ missions = 4, t3 = { 1, 2, 3, 4 } })
	local before = {}

	for _, k in ipairs(D.statusKeys()) do
		before[k] = H.getQuestStatus(player, k)
	end

	D.talk(player, { "s_69f62a43", "s_25c39c01" })

	for _, k in ipairs(D.statusKeys()) do
		lu.assertEquals(H.getQuestStatus(player, k), before[k], "status key " .. k .. " is unchanged by the ending")
	end
end
