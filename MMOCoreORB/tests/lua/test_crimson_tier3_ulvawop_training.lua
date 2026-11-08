-- Arnecio Ulvaw'op: one-click, free-choice, free tier 3 training, one skill per mission, the hand-off to General Ufwol (pilot tier 4) and the regressions of AC-9.
-- Spec: .claude/work/crimson-phoenix-tier3-ulvawop/01-spec.md (AC-7, AC-8, AC-9; Conversation flow 2 (C-1), 3 and 4; FU-1, FU-5, FU-6; D-3, D-5, D-6, D-10, D-11; I-6, I-7).
--
-- A reward screen of mission n shows one topic reply per missing _03 skill and then the decline (C-1). The topic links to the trained_<x> screen; the grant happens in
-- getNextConversationScreen through SpaceHelpers:grantSpaceSkill(p, skill, false) (JU noisyGrantSkill: no XP check, no XP charge).

local lu = require("luaunit")
local H = require("harness")
local T = require("crimson_tier3_data")
local E = require("crimson_tier2_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

T.loadConversation()
E.loadConversation()

local original

local function setUp()
	H.reset()
	T.requireConversation(lu)
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

-- Mission n won and unpaid, missions 1..n-1 paid, with the given tier 3 skills (a list of T.TRAIN indexes; their number must be n - 1 for a reward dialogue to be pending)
local function pilot(n, held, extra)
	local o = { missions = n - 1, t3 = held, state = "won" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return T.pilot(o)
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

local function holds(player, i) return CreatureObject(player):hasSkill(T.TRAIN[i].skill) end

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

local function t3(k)
	local out = {}

	for i = 1, k do
		out[i] = i
	end

	return out
end

-- the permutations of {1, 2, 3, 4}
local function permutations()
	local out = {}

	local function rec(cur, rest)
		if #rest == 0 then
			out[#out + 1] = { table.unpack(cur) }
			return
		end

		for i = 1, #rest do
			local nextRest = { table.unpack(rest) }
			local v = table.remove(nextRest, i)

			cur[#cur + 1] = v
			rec(cur, nextRest)
			cur[#cur] = nil
		end
	end

	rec({}, { 1, 2, 3, 4 })

	return out
end

TestUlvawopTraining = {}

TestUlvawopTraining.setUp = setUp

function TestUlvawopTraining:tearDown() restoreGrants() end

-- AC-7, C-1: each reward screen lists exactly the missing _03 skills, in table order, and then the decline linking to on_mission
function TestUlvawopTraining:test_each_reward_screen_lists_exactly_the_missing_skills_in_table_order_then_the_decline()
	for n = 1, 4 do
		for _, held in ipairs(subsets(n - 1)) do
			H.reset()

			local t = T.drive(pilot(n, held), T.MISSIONS[n].reward)
			local replies, links = {}, {}

			for k, i in ipairs(missing(held)) do
				replies[k] = T.TRAIN[i].reply
				links[k] = T.TRAIN[i].trained
			end

			replies[#replies + 1] = T.DECLINE_REPLY
			links[#links + 1] = "on_mission"
			lu.assertEquals(T.optionSids(t[1]), replies, "m" .. n .. "_reward holding {" .. name(held) .. "}: topic replies and the decline")
			lu.assertEquals(T.linksOf(t[1]), links, "m" .. n .. "_reward holding {" .. name(held) .. "}: links")
			lu.assertFalse(t[1].stop, "m" .. n .. "_reward holding {" .. name(held) .. "}: the screen does not end the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-7, C-1: the list is the missing skills for any held set, not only the sets a mission n pilot can have (a skill got elsewhere)
function TestUlvawopTraining:test_the_topic_list_follows_the_held_skills_for_every_subset()
	for size = 0, 4 do
		for _, held in ipairs(subsets(size)) do
			H.reset()

			local t = T.drive(pilot(4, held, { missions = 3 }), "m4_reward")
			local replies = {}

			for k, i in ipairs(missing(held)) do
				replies[k] = T.TRAIN[i].reply
			end

			replies[#replies + 1] = T.DECLINE_REPLY
			lu.assertEquals(T.optionSids(t[1]), replies, "m4_reward holding {" .. name(held) .. "}")
			lu.assertFalse(t[1].stop, "m4_reward holding {" .. name(held) .. "}: never ends without an option")
		end
	end
end

-- AC-7, C-1: with none missing m4_reward offers only the decline
function TestUlvawopTraining:test_with_all_four_skills_held_m4_reward_offers_only_the_decline()
	local t = T.drive(pilot(4, { 1, 2, 3, 4 }), "m4_reward")

	lu.assertEquals(T.optionSids(t[1]), { T.DECLINE_REPLY }, "only the decline")
	lu.assertEquals(T.linksOf(t[1]), { "on_mission" }, "linking to on_mission")
	lu.assertFalse(t[1].stop, "m4_reward does not end without an option")
end

-- AC-7, I-6: choosing a topic grants that skill free, through grantSpaceSkill(p, skill, false), and shows trained_<x>, which ends
function TestUlvawopTraining:test_choosing_a_topic_grants_that_skill_for_free_and_shows_the_trained_screen()
	for n = 1, 4 do
		for _, held in ipairs(subsets(n - 1)) do
			for _, i in ipairs(missing(held)) do
				for _, xp in ipairs({ 0, 200000 }) do
					H.reset()
					restoreGrants()

					local calls = recordGrants()
					local player = pilot(n, held, { xp = xp })
					local label = "m" .. n .. "_reward holding {" .. name(held) .. "} choosing " .. T.TRAIN[i].x .. " with " .. xp .. " XP"
					local t = T.drive(player, T.MISSIONS[n].reward, { T.TRAIN[i].reply })

					lu.assertEquals(T.ids(t), { T.MISSIONS[n].reward, T.TRAIN[i].trained }, label .. ": screens shown")
					lu.assertEquals(t[2].text, T.PREFIX .. T.TRAIN[i].trainedSid, label .. ": the skill's own trained line")
					lu.assertTrue(t[2].stop, label .. ": the trained screen ends the conversation")
					lu.assertEquals(#t[2].options, 0, label .. ": the trained screen offers no reply")
					lu.assertTrue(holds(player, i), label .. ": the skill is held")
					lu.assertEquals(count(player), n, label .. ": the _03 count equals n")
					lu.assertEquals(#calls, 1, label .. ": grantSpaceSkill calls")
					lu.assertEquals({ calls[1].skill, calls[1].deduct }, { T.TRAIN[i].skill, false }, label .. ": grantSpaceSkill(p, skill, false)")
					lu.assertEquals(#T.free(), 1, label .. ": free grants (awardSkill)")
					lu.assertEquals(#T.bought(), 0, label .. ": no XP-deducting grant")
					lu.assertEquals(player.ghost.experience.space_combat_general, xp, label .. ": the XP is unchanged")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
				end
			end
		end
	end
end

-- AC-7, I-6: credits are not charged either (the reward is paid, nothing is taken)
function TestUlvawopTraining:test_a_grant_takes_no_credits()
	local player = pilot(2, { 1 }, { xp = 1000 })

	T.drive(player, "m2_reward", { T.TRAIN[3].reply })
	lu.assertEquals(player.bankCredits, T.CREDITS, "only the mission 2 payment, nothing charged")
	lu.assertEquals(player.cashCredits or 0, 0, "no cash charged")
end

-- AC-7, I-6: even a priced skill is not charged (the engine's XP model is on)
function TestUlvawopTraining:test_the_skill_costs_no_xp_even_when_the_engine_would_charge()
	local costs = {}

	for i = 1, 4 do
		costs[T.TRAIN[i].skill] = 100000
	end

	H.Engine.config.skillXpCosts = costs

	local player = pilot(1, {}, { xp = 150000 })
	local t = T.drive(player, "m1_reward", { T.TRAIN[2].reply })

	lu.assertEquals(T.ids(t), { "m1_reward", "trained_weapons" }, "screens shown")
	lu.assertTrue(holds(player, 2), "the weapons skill is held")
	lu.assertEquals(player.ghost.experience.space_combat_general, 150000, "no XP charged")
end

-- AC-7: the whole walk, M1, from the first screen to the grant (one click: no confirm screen)
function TestUlvawopTraining:test_the_first_talk_after_mission_1_pays_trains_and_ends_on_the_trained_screen()
	local player = pilot(1, {})
	local t = T.talk(player, { T.TRAIN[3].reply })

	lu.assertEquals(T.ids(t), { "m1_reward", "trained_procedures" }, "first screen, then the grant line")
	lu.assertEquals(t[2].text, T.PREFIX .. "s_7da64d88", "the procedures answer line")
	lu.assertTrue(holds(player, 3), "the procedures skill is held")
	lu.assertEquals(count(player), 1, "one _03 skill")
	lu.assertEquals(player.bankCredits, T.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(T.firstScreen(player), "m2_offer", "the next talk offers mission 2")
end

-- AC-7, I-6: the decline grants nothing and a second visit still offers the same topics
function TestUlvawopTraining:test_the_decline_grants_nothing_and_the_topics_are_offered_again_on_the_next_visit()
	local player = pilot(2, { 1 })
	local t = T.talk(player, { T.DECLINE_REPLY })

	lu.assertEquals(T.ids(t), { "m2_reward", "on_mission" }, "screens shown")
	lu.assertEquals(count(player), 1, "no skill granted")

	local again = T.talk(player)

	lu.assertEquals(T.optionSids(again[1]), { T.TRAIN[2].reply, T.TRAIN[3].reply, T.TRAIN[4].reply, T.DECLINE_REPLY }, "the missing topics and the decline, again")
end

-- AC-7: guard failures grant nothing and route by the gates
function TestUlvawopTraining:test_a_skill_already_held_grants_nothing_and_routes_by_the_gates()
	-- the skill arrives while the screen is shown (the pilot got it elsewhere), then the pilot clicks its topic
	local player = pilot(2, { 2 })
	local grab = function(p) p.skills[T.TRAIN[1].skill] = true end
	local calls = recordGrants()
	local t = T.drive(player, "m2_reward", { grab, T.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call for a skill already held")
	lu.assertEquals(#T.free() + #T.bought(), 0, "no grant")
	lu.assertNotEquals(t[#t].id, "trained_starships", "the trained screen is not shown")
	lu.assertEquals(count(player), 2, "count stays at 2 (weapons, and starships got elsewhere)")
end

-- AC-7, I-6: a topic chosen from a reward screen of a mission that is not the pending one grants nothing
function TestUlvawopTraining:test_a_reward_screen_of_a_mission_without_a_pending_reward_grants_nothing()
	-- mission 2 won with mission 1's skill unchosen: getRewardMission is 1, not 2
	local player = pilot(2, {})
	local calls = recordGrants()
	local t = T.drive(player, "m2_reward", { T.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call")
	lu.assertEquals(count(player), 0, "no skill")
	lu.assertEquals(t[#t].id, "m1_reward", "routed by the gates: mission 1's reward is pending")

	-- mission 1 never won: nothing to train for
	local fresh = T.pilot({})

	t = T.drive(fresh, "m1_reward", { T.TRAIN[1].reply })
	lu.assertEquals(count(fresh), 0, "no skill before mission 1 is won")
	lu.assertEquals(t[#t].id, "m1_offer", "routed by the gates: mission 1 is offered")

	-- the later reward screen while an earlier reward is pending: only the pending mission's screen grants
	local wrong = pilot(1, {})

	T.drive(wrong, "m3_reward", { T.TRAIN[1].reply })
	lu.assertEquals(count(wrong), 0, "mission 3's screen does not grant while mission 1's reward is pending")
end

-- AC-7, I-6: one skill per mission: a second click on the same or another topic grants nothing more
function TestUlvawopTraining:test_a_second_choice_in_the_same_mission_grants_nothing_more()
	local player = pilot(1, {})

	T.drive(player, "m1_reward", { T.TRAIN[1].reply })
	lu.assertEquals(count(player), 1, "after the first choice")

	local calls = recordGrants()
	local t = T.drive(player, "m1_reward", { T.TRAIN[2].reply })

	lu.assertEquals(#calls, 0, "no second grant")
	lu.assertEquals(count(player), 1, "still one skill")
	lu.assertNotEquals(t[#t].id, "trained_weapons", "the weapons grant line is not shown")
end

-- AC-7, I-6: the trained screens themselves grant nothing when shown (the grant is the choice)
function TestUlvawopTraining:test_displaying_a_trained_screen_directly_grants_no_skill()
	for n = 1, 4 do
		for i = 1, 4 do
			H.reset()

			local player = pilot(n, t3(n - 1))

			T.drive(player, T.TRAIN[i].trained)
			lu.assertEquals(#T.free() + #T.bought(), 0, T.TRAIN[i].trained .. ": no skill granted by display (mission " .. n .. ")")
			lu.assertEquals(player.ghost.pilotTier, 3, T.TRAIN[i].trained .. ": pilot tier unchanged")
		end
	end
end

-- AC-7, I-6: the fourth skill raises pilot tier 3 -> 4; the earlier ones do not
function TestUlvawopTraining:test_the_fourth_skill_raises_pilot_tier_3_to_4()
	for _, last in ipairs({ 1, 2, 3, 4 }) do
		H.reset()

		local held = {}

		for i = 1, 4 do
			if i ~= last then
				held[#held + 1] = i
			end
		end

		local player = pilot(4, held, { pilotTier = 3 })

		T.drive(player, "m4_reward", { T.TRAIN[last].reply })
		lu.assertEquals(count(player), 4, "four skills after choosing " .. T.TRAIN[last].x)
		lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the fourth skill (" .. T.TRAIN[last].x .. " last)")
	end

	for n = 1, 3 do
		H.reset()

		local player = pilot(n, t3(n - 1), { pilotTier = 3 })

		T.drive(player, "m" .. n .. "_reward", { T.TRAIN[n].reply })
		lu.assertEquals(player.ghost.pilotTier, 3, "mission " .. n .. ": pilot tier stays 3 before the fourth skill")
	end

	local p4 = pilot(4, { 2, 3, 4 }, { pilotTier = 4 })

	T.drive(p4, "m4_reward", { T.TRAIN[1].reply })
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot is not raised again")
end

-- AC-7: after each skill the next visit opens what comes next
function TestUlvawopTraining:test_after_each_skill_the_next_visit_opens_what_comes_next()
	local want = { "m2_offer", "m3_offer", "m4_offer", "handoff" }

	for n = 1, 4 do
		H.reset()

		local player = pilot(n, t3(n - 1))

		T.drive(player, "m" .. n .. "_reward", { T.TRAIN[n].reply })
		lu.assertEquals(T.firstScreen(player), want[n], "first screen after mission " .. n .. "'s skill was chosen")
	end
end

-- AC-7: the walk M1 -> skill -> M2 -> skill -> M3 -> skill -> M4 -> skill reaches the hand-off, in every one of the 24 skill orders
function TestUlvawopTraining:test_every_one_of_the_24_skill_orders_reaches_the_hand_off_with_pilot_tier_4()
	local orders = permutations()

	lu.assertEquals(#orders, 24, "skill orders")

	for _, order in ipairs(orders) do
		H.reset()

		local player = T.pilot({})
		local label = "order " .. name(order)

		for n = 1, 4 do
			for _, global in ipairs(T.CHAINS[n]) do
				T.setState(player, global, "complete")
			end

			H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")

			local t = T.talk(player, { T.TRAIN[order[n]].reply })

			lu.assertEquals(t[1].id, "m" .. n .. "_reward", label .. ", mission " .. n .. ": first screen")
			lu.assertEquals(t[#t].id, T.TRAIN[order[n]].trained, label .. ", mission " .. n .. ": last screen")
			lu.assertEquals(count(player), n, label .. ", mission " .. n .. ": skills held")
			lu.assertEquals(player.ghost.pilotTier, n == 4 and 4 or 3, label .. ", mission " .. n .. ": pilot tier")
		end

		lu.assertEquals(T.firstScreen(player), "handoff", label .. ": the next talk")
		lu.assertEquals(player.ghost.pilotTier, 4, label .. ": pilot tier 4")
	end
end

---------------------------------------------------------------------------------------------
-- The whole career and the hand-off (AC-7, AC-8)
---------------------------------------------------------------------------------------------

TestUlvawopHandoff = {}

TestUlvawopHandoff.setUp = setUp

-- AC-7, AC-8: a pilot wins the four missions in turn, talks through each reward and training, and ends tier 4 with all four skills and four paid rewards
function TestUlvawopHandoff:test_the_whole_career_ends_on_the_hand_off_with_pilot_tier_4_and_the_flag_untouched()
	local player = T.pilot({})
	local order = { 3, 1, 4, 2 }
	local before = M.snapshot(player).status

	for n = 1, 4 do
		for _, global in ipairs(T.CHAINS[n]) do
			T.setState(player, global, "complete")
		end

		H.setQuestStatus(player, T.STATUS[n] .. ":attempted", "1")

		local t = T.talk(player, { T.TRAIN[order[n]].reply })

		lu.assertEquals(t[1].id, "m" .. n .. "_reward", "mission " .. n .. ": first screen")
		lu.assertEquals(t[#t].id, T.TRAIN[order[n]].trained, "mission " .. n .. ": last screen")
		lu.assertEquals(count(player), n, "mission " .. n .. ": skills held")
		lu.assertEquals(player.ghost.pilotTier, n == 4 and 4 or 3, "mission " .. n .. ": pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "mission " .. n .. ": client strings")
	end

	lu.assertEquals(player.bankCredits, 4 * T.CREDITS, "four rewards paid once each")
	lu.assertEquals(T.standing(player), 4 * T.STANDING, "four times +100 standing")
	lu.assertEquals(#T.items(player), 4, "four ship components")

	for n = 1, 4 do
		lu.assertEquals(T.paid(player, n), "1", "mission " .. n .. " :reward")
	end

	-- the interface to tier 4 (Source inventory 6): four _03 skills, pilot tier 4, the mission 4 reward key, EKER_PILOT_KEY unchanged (I-7)
	lu.assertEquals(T.flag(player), "3", "EKER_PILOT_KEY keeps Eker's value")
	lu.assertEquals(T.firstScreen(player), "handoff", "the next talk")

	local after = M.snapshot(player).status
	local changed = T.statusDiff(player, before, after)

	for _, suffix in ipairs(changed) do
		local ok = false

		for _, key in ipairs(T.statusKeys()) do
			ok = ok or key == suffix
		end

		lu.assertTrue(ok, "Ulvaw'op wrote a key that is not one of the 8 Part A status keys: " .. suffix .. " (I-7)")
	end
end

-- AC-8: handoff raises a tier-3 pilot with four _03 skills to tier 4, grants nothing else and adds no waypoint
function TestUlvawopHandoff:test_handoff_raises_a_tier_3_pilot_with_four_skills_to_tier_4_and_grants_nothing_else()
	local player = T.pilot({ missions = 4, t3 = 4, pilotTier = 3 })
	local t = T.talk(player)

	lu.assertEquals(T.ids(t), { "handoff" }, "first screen")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(#T.free() + #T.bought(), 0, "no skill granted")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(#T.items(player), 0, "no item")
	lu.assertEquals(T.standing(player), 0, "standing unchanged")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest started")
	lu.assertEquals(#player.ghost.waypoints, 0, "no waypoint to General Ufwol (Q-B2 = A: JU adds none)")
end

-- AC-8: the raise happens once; a tier 4 pilot is not raised again, a pilot with fewer than four skills is not raised
function TestUlvawopHandoff:test_handoff_raises_the_pilot_tier_only_for_tier_3_pilots_with_all_four_skills()
	local p4 = T.pilot({ missions = 4, t3 = 4, pilotTier = 4 })

	T.talk(p4)
	T.talk(p4)
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot stays at 4")

	local p3 = T.pilot({ missions = 4, t3 = 3, pilotTier = 3 })

	T.drive(p3, "handoff")
	lu.assertEquals(p3.ghost.pilotTier, 3, "three skills: not raised")

	local fresh = T.pilot({ missions = 4, t3 = 4, pilotTier = 3 })

	T.talk(fresh)
	T.talk(fresh)
	lu.assertEquals(fresh.ghost.pilotTier, 4, "a second talk leaves it at 4")
end

-- AC-8: the two replies reach handoff_leave (via handoff_rori and via handoff_spy), which ends
function TestUlvawopHandoff:test_the_two_replies_reach_the_ending_through_the_two_routes()
	local cases = {
		{ replies = { "s_a927c891", "s_eba35f17" }, ids = { "handoff", "handoff_rori", "handoff_leave" } },
		{ replies = { "s_554b78dd", "s_eba35f17" }, ids = { "handoff", "handoff_spy", "handoff_leave" } },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local player = T.pilot({ missions = 4, t3 = 4 })
		local t = T.talk(player, c.replies)

		lu.assertEquals(T.ids(t), c.ids, "walk " .. table.concat(c.replies, ","))
		lu.assertTrue(t[#t].stop, t[#t].id .. " ends the conversation")
		lu.assertEquals(#t[#t].options, 0, t[#t].id .. " offers no reply")
		lu.assertEquals(t[#t].text, T.PREFIX .. "s_db13b2d9", "'Immediately. Thank you again for all your hard work...'")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(#T.free() + #T.bought(), 0, "no skill granted by the endings")
		lu.assertEquals(player.bankCredits, 0, "no credits from the endings")
		lu.assertEquals(#player.ghost.waypoints, 0, "no waypoint")
		lu.assertEquals(T.flag(player), "3", "EKER_PILOT_KEY untouched by the hand-off (I-7)")
	end
end

-- AC-8: the hand-off lines name General Ufwol and the Rebel outpost on Rori (JU's lines)
function TestUlvawopHandoff:test_the_hand_off_names_general_ufwol()
	local text = require("crimson_tier3_ulvawop_client_text")
	local rori = T.talk(T.pilot({ missions = 4, t3 = 4 }), { "s_a927c891" })
	local spy = T.talk(T.pilot({ missions = 4, t3 = 4 }), { "s_554b78dd" })

	lu.assertEquals(rori[2].text, T.PREFIX .. "s_d72cbbfa", "'You are now assigned to the Rebel outpost on Rori...'")
	lu.assertEquals(spy[2].text, T.PREFIX .. "s_9c91459e", "'You should always keep your eyes and ears open...'")
	lu.assertStrContains(text.s_d72cbbfa, "General Ufwol", false, "the Rori line names him")
	lu.assertStrContains(text.s_9c91459e, "General Ufwol", false, "the spy line names him")
end

-- AC-8, I-7: the hand-off walks write no quest key and no flag
function TestUlvawopHandoff:test_the_endings_set_no_quest_status_key()
	local player = T.pilot({ missions = 4, t3 = 4 })
	local before = M.snapshot(player).status

	T.talk(player, { "s_554b78dd", "s_eba35f17" })
	T.talk(player, { "s_a927c891", "s_eba35f17" })
	lu.assertEquals(T.statusDiff(player, before, M.snapshot(player).status), {}, "status keys changed by the hand-off walks")
end

-- AC-8, I-7: no walk of the gates, offers or rewards writes EKER_PILOT_KEY (spot check of every flag value over a reward walk)
function TestUlvawopHandoff:test_a_reward_and_training_walk_leaves_the_flag_as_it_was()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = pilot(1, {}, { graduated = flag })

		T.talk(player, { T.TRAIN[1].reply })
		lu.assertEquals(T.flag(player), flag, "EKER_PILOT_KEY after a reward walk with flag " .. flag)
	end
end

-- AC-8, I-7: every screen of Appendix A, driven for a pilot of each flag value, leaves EKER_PILOT_KEY as it was and writes no key but the Part A status keys
function TestUlvawopHandoff:test_no_screen_writes_the_flag_or_a_foreign_key()
	for _, flag in ipairs({ "1", "3" }) do
		for _, row in ipairs(T.SCREENS) do
			H.reset()
			T.spyStarts()

			local player = T.pilot({ missions = 2, t3 = 2, graduated = flag })
			local before = M.snapshot(player).status

			T.drive(player, row.id)
			lu.assertEquals(T.flag(player), flag, row.id .. ": EKER_PILOT_KEY with flag " .. flag)

			for _, suffix in ipairs(T.statusDiff(player, before, M.snapshot(player).status)) do
				local ok = false

				for _, key in ipairs(T.statusKeys()) do
					ok = ok or key == suffix
				end

				lu.assertTrue(ok, row.id .. " wrote a key that is not one of the 8 Part A status keys: " .. suffix)
			end
		end
	end
end

---------------------------------------------------------------------------------------------
-- AC-9: Eker's graduate meets Ulvaw'op
---------------------------------------------------------------------------------------------

TestUlvawopEkerHandover = {}

TestUlvawopEkerHandover.setUp = setUp

-- AC-9: Eker's walk still reaches his tier3_handoff, and his tier 2 graduate then opens m1_offer with Ulvaw'op
function TestUlvawopEkerHandover:test_an_eker_graduate_who_heard_his_hand_off_opens_m1_offer_with_ulvawop()
	E.requireConversation(lu)

	local player = E.pilot({ missions = 4, t2 = 4, graduated = "3" })
	local t = E.talk(player)

	lu.assertEquals(E.ids(t)[1], "tier3_handoff", "Eker's first screen for a tier 2 graduate")

	local walked = E.talk(player, { "s_3938bdfc" })

	lu.assertEquals(E.ids(walked), { "tier3_handoff", "tier3_teaching" }, "Eker's hand-off walk")
	lu.assertTrue(walked[2].stop, "tier3_teaching ends")
	lu.assertEquals(T.firstScreen(player), "m1_offer", "the same pilot with Ulvaw'op")
end

-- AC-9: a graduate built by Eker's own rewards reaches m1_offer (the key and the skills Eker leaves are what Ulvaw'op's ready gate reads)
function TestUlvawopEkerHandover:test_the_state_eker_leaves_satisfies_ulvawops_ready_gate()
	local player = T.pilot({})

	lu.assertEquals(H.getQuestStatus(player, T.TIER2_M4_REWARD), "1", "Eker's mission 4 reward key")
	lu.assertEquals(T.flag(player), "3", "EKER_PILOT_KEY after Eker's mission 4")
	lu.assertTrue(T.handler():isReadyForTier3(player), "isReadyForTier3")
end
