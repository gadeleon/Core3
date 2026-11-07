-- Brother Ezkiel: one-click, free-choice, free tier 3 training, one skill per mission, and the hand-off to Brother Extok Evin (pilot tier 4).
-- Spec: .claude/work/vortex-tier3-ezkiel/01-spec.md (AC-7, AC-8; Conversation flow 2 (C-1), 3 and 4; FV-1, FV-3; D-3, D-4, D-11; I-6, I-7).
--
-- A reward screen of mission n shows one topic reply per missing _03 skill (C-1). The reply links to the trained_<x> screen; the grant happens in
-- getNextConversationScreen through SpaceHelpers:grantSpaceSkill(p, skill, false) (J3 noisyGrantSkill: no XP check, no XP charge).

local lu = require("luaunit")
local H = require("harness")
local W = require("vortex_tier3_data")
local M = require("migration_scenario")
local CS = require("harness.client_strings")

W.loadConversation()

local original

local function setUp()
	H.reset()
	W.requireConversation(lu)
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

-- Mission n won and unpaid, missions 1..n-1 paid, with the given tier 3 skills (a list of W.TRAIN indexes; their number must be n - 1 for a reward dialogue to be pending)
local function pilot(n, held, extra)
	local o = { missions = n - 1, t3 = held, state = "won" }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return W.pilot(o)
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

local function holds(player, i) return CreatureObject(player):hasSkill(W.TRAIN[i].skill) end

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

TestEzkielTraining = {}

TestEzkielTraining.setUp = setUp

function TestEzkielTraining:tearDown() restoreGrants() end

-- AC-7, C-1: each reward screen lists exactly the missing _03 skills, in table order
function TestEzkielTraining:test_each_reward_screen_lists_exactly_the_missing_skills_in_table_order()
	for n = 1, 4 do
		for _, held in ipairs(subsets(n - 1)) do
			H.reset()

			local t = W.drive(pilot(n, held), W.MISSIONS[n].reward)
			local replies, links = {}, {}

			for k, i in ipairs(missing(held)) do
				replies[k] = W.TRAIN[i].reply
				links[k] = W.TRAIN[i].trained
			end

			lu.assertEquals(W.optionSids(t[1]), replies, "m" .. n .. "_reward holding {" .. name(held) .. "}: topic replies")
			lu.assertEquals(W.linksOf(t[1]), links, "m" .. n .. "_reward holding {" .. name(held) .. "}: links")
			lu.assertFalse(t[1].stop, "m" .. n .. "_reward holding {" .. name(held) .. "}: the screen does not end the conversation")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-7, C-1: the list is the missing skills for any held set, not only the sets a mission n pilot can have (a skill got elsewhere)
function TestEzkielTraining:test_the_topic_list_follows_the_held_skills_for_every_subset()
	for size = 0, 4 do
		for _, held in ipairs(subsets(size)) do
			H.reset()

			local t = W.drive(pilot(4, held, { missions = 3 }), "m4_reward")
			local replies = {}

			for k, i in ipairs(missing(held)) do
				replies[k] = W.TRAIN[i].reply
			end

			lu.assertEquals(W.optionSids(t[1]), replies, "m4_reward holding {" .. name(held) .. "}")
			lu.assertEquals(t[1].stop, size == 4, "m4_reward holding {" .. name(held) .. "}: stops only when nothing is missing")
		end
	end
end

-- AC-7, C-1: with none missing m4_reward has no option and stops
function TestEzkielTraining:test_with_all_four_skills_held_m4_reward_has_no_option_and_stops()
	local t = W.drive(pilot(4, { 1, 2, 3, 4 }), "m4_reward")

	lu.assertEquals(#t[1].options, 0, "no option")
	lu.assertTrue(t[1].stop, "m4_reward stops the conversation")
end

-- AC-7, I-6: choosing a topic grants that skill free, through grantSpaceSkill(p, skill, false), and shows trained_<x>, which ends
function TestEzkielTraining:test_choosing_a_topic_grants_that_skill_for_free_and_shows_the_trained_screen()
	for n = 1, 4 do
		for _, held in ipairs(subsets(n - 1)) do
			for _, i in ipairs(missing(held)) do
				for _, xp in ipairs({ 0, 200000 }) do
					H.reset()
					restoreGrants()

					local calls = recordGrants()
					local player = pilot(n, held, { xp = xp })
					local label = "m" .. n .. "_reward holding {" .. name(held) .. "} choosing " .. W.TRAIN[i].x .. " with " .. xp .. " XP"
					local t = W.drive(player, W.MISSIONS[n].reward, { W.TRAIN[i].reply })

					lu.assertEquals(W.ids(t), { W.MISSIONS[n].reward, W.TRAIN[i].trained }, label .. ": screens shown")
					lu.assertEquals(t[2].text, W.PREFIX .. W.TRAINED_SID, label .. ": the one grant line")
					lu.assertTrue(t[2].stop, label .. ": the trained screen ends the conversation")
					lu.assertEquals(#t[2].options, 0, label .. ": the trained screen offers no reply")
					lu.assertTrue(holds(player, i), label .. ": the skill is held")
					lu.assertEquals(count(player), n, label .. ": the _03 count equals n")
					lu.assertEquals(#calls, 1, label .. ": grantSpaceSkill calls")
					lu.assertEquals({ calls[1].skill, calls[1].deduct }, { W.TRAIN[i].skill, false }, label .. ": grantSpaceSkill(p, skill, false)")
					lu.assertEquals(#W.free(), 1, label .. ": free grants (awardSkill)")
					lu.assertEquals(#W.bought(), 0, label .. ": no XP-deducting grant")
					lu.assertEquals(player.ghost.experience.space_combat_general, xp, label .. ": the XP is unchanged")
					lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
				end
			end
		end
	end
end

-- AC-7, I-6: credits are not charged either (the reward is paid, nothing is taken)
function TestEzkielTraining:test_a_grant_takes_no_credits()
	local player = pilot(2, { 1 }, { xp = 1000 })

	W.drive(player, "m2_reward", { W.TRAIN[3].reply })
	lu.assertEquals(player.bankCredits, W.CREDITS, "only the mission 2 payment, nothing charged")
	lu.assertEquals(player.cashCredits or 0, 0, "no cash charged")
end

-- AC-7, I-6: even a priced skill is not charged (the engine's XP model is on)
function TestEzkielTraining:test_the_skill_costs_no_xp_even_when_the_engine_would_charge()
	local costs = {}

	for i = 1, 4 do
		costs[W.TRAIN[i].skill] = 100000
	end

	H.Engine.config.skillXpCosts = costs

	local player = pilot(1, {}, { xp = 150000 })
	local t = W.drive(player, "m1_reward", { W.TRAIN[2].reply })

	lu.assertEquals(W.ids(t), { "m1_reward", "trained_weapons" }, "screens shown")
	lu.assertTrue(holds(player, 2), "the weapons skill is held")
	lu.assertEquals(player.ghost.experience.space_combat_general, 150000, "no XP charged")
end

-- AC-7: the whole walk, M1, from the first screen to the grant (one click: no confirm screen)
function TestEzkielTraining:test_the_first_talk_after_mission_1_pays_trains_and_ends_on_the_trained_screen()
	local player = pilot(1, {})
	local t = W.talk(player, { W.TRAIN[3].reply })

	lu.assertEquals(W.ids(t), { "m1_reward", "trained_procedures" }, "first screen, then the grant line")
	lu.assertTrue(holds(player, 3), "the procedures skill is held")
	lu.assertEquals(count(player), 1, "one _03 skill")
	lu.assertEquals(player.bankCredits, W.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	lu.assertEquals(W.firstScreen(player), "m2_offer", "the next talk offers mission 2")
end

-- AC-7: guard failures grant nothing and route by the gates
function TestEzkielTraining:test_a_skill_already_held_grants_nothing_and_routes_by_the_gates()
	-- the skill arrives while the screen is shown (the pilot got it elsewhere), then the pilot clicks its topic
	local player = pilot(2, { 2 })
	local grab = function(p) p.skills[W.TRAIN[1].skill] = true end
	local calls = recordGrants()
	local t = W.drive(player, "m2_reward", { grab, W.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call for a skill already held")
	lu.assertEquals(#W.free() + #W.bought(), 0, "no grant")
	lu.assertNotEquals(t[#t].id, "trained_starships", "the trained screen is not shown")
	lu.assertEquals(count(player), 2, "count stays at 2 (weapons, and starships got elsewhere)")
end

-- AC-7, I-6: a topic chosen from a reward screen of a mission that is not the pending one grants nothing
function TestEzkielTraining:test_a_reward_screen_of_a_mission_without_a_pending_reward_grants_nothing()
	-- mission 2 won with mission 1's skill unchosen: getRewardMission is 1, not 2
	local player = pilot(2, {})
	local calls = recordGrants()
	local t = W.drive(player, "m2_reward", { W.TRAIN[1].reply })

	lu.assertEquals(#calls, 0, "no grantSpaceSkill call")
	lu.assertEquals(count(player), 0, "no skill")
	lu.assertEquals(t[#t].id, "m1_reward", "routed by the gates: mission 1's reward is pending")

	-- mission 1 never won: nothing to train for
	local fresh = W.pilot({})

	t = W.drive(fresh, "m1_reward", { W.TRAIN[1].reply })
	lu.assertEquals(count(fresh), 0, "no skill before mission 1 is won")
	lu.assertEquals(t[#t].id, "m1_offer", "routed by the gates: mission 1 is offered")

	-- the later reward screen while an earlier reward is pending: only the pending mission's screen grants
	local wrong = pilot(1, {})

	W.drive(wrong, "m3_reward", { W.TRAIN[1].reply })
	lu.assertEquals(count(wrong), 0, "mission 3's screen does not grant while mission 1's reward is pending")
end

-- AC-7, I-6: one skill per mission: a second click on the same or another topic grants nothing more
function TestEzkielTraining:test_a_second_choice_in_the_same_mission_grants_nothing_more()
	local player = pilot(1, {})

	W.drive(player, "m1_reward", { W.TRAIN[1].reply })
	lu.assertEquals(count(player), 1, "after the first choice")

	local calls = recordGrants()
	local t = W.drive(player, "m1_reward", { W.TRAIN[2].reply })

	lu.assertEquals(#calls, 0, "no second grant")
	lu.assertEquals(count(player), 1, "still one skill")
	lu.assertNotEquals(t[#t].id, "trained_weapons", "the weapons grant line is not shown")
end

-- AC-7, I-6: the trained screens themselves grant nothing when shown (the grant is the choice)
function TestEzkielTraining:test_displaying_a_trained_screen_directly_grants_no_skill()
	for n = 1, 4 do
		for i = 1, 4 do
			H.reset()

			local player = pilot(n, t3(n - 1))

			W.drive(player, W.TRAIN[i].trained)
			lu.assertEquals(#W.free() + #W.bought(), 0, W.TRAIN[i].trained .. ": no skill granted by display (mission " .. n .. ")")
			lu.assertEquals(player.ghost.pilotTier, 3, W.TRAIN[i].trained .. ": pilot tier unchanged")
		end
	end
end

-- AC-7, I-6: the fourth skill raises pilot tier 3 -> 4; the earlier ones do not
function TestEzkielTraining:test_the_fourth_skill_raises_pilot_tier_3_to_4()
	for _, last in ipairs({ 1, 2, 3, 4 }) do
		H.reset()

		local held = {}

		for i = 1, 4 do
			if i ~= last then
				held[#held + 1] = i
			end
		end

		local player = pilot(4, held, { pilotTier = 3 })

		W.drive(player, "m4_reward", { W.TRAIN[last].reply })
		lu.assertEquals(count(player), 4, "four skills after choosing " .. W.TRAIN[last].x)
		lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after the fourth skill (" .. W.TRAIN[last].x .. " last)")
	end

	for n = 1, 3 do
		H.reset()

		local player = pilot(n, t3(n - 1), { pilotTier = 3 })

		W.drive(player, "m" .. n .. "_reward", { W.TRAIN[n].reply })
		lu.assertEquals(player.ghost.pilotTier, 3, "mission " .. n .. ": pilot tier stays 3 before the fourth skill")
	end

	local p4 = pilot(4, { 2, 3, 4 }, { pilotTier = 4 })

	W.drive(p4, "m4_reward", { W.TRAIN[1].reply })
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot is not raised again")
end

-- AC-7: after each skill the next visit opens what comes next
function TestEzkielTraining:test_after_each_skill_the_next_visit_opens_what_comes_next()
	local want = { "m2_offer", "m3_offer", "m4_offer", "tier_done" }

	for n = 1, 4 do
		H.reset()

		local player = pilot(n, t3(n - 1))

		W.drive(player, "m" .. n .. "_reward", { W.TRAIN[n].reply })
		lu.assertEquals(W.firstScreen(player), want[n], "first screen after mission " .. n .. "'s skill was chosen")
	end
end

---------------------------------------------------------------------------------------------
-- The whole career and the hand-off (AC-7, AC-8)
---------------------------------------------------------------------------------------------

TestEzkielHandoff = {}

TestEzkielHandoff.setUp = setUp

-- AC-7, AC-8: a pilot wins the four missions in turn, talks through each reward and training, and ends tier 4 with all four skills and four paid rewards
function TestEzkielHandoff:test_the_whole_career_ends_on_tier_done_with_pilot_tier_4_and_the_flag_untouched()
	local player = W.pilot({})
	local order = { 3, 1, 4, 2 }
	local before = M.snapshot(player).status

	for n = 1, 4 do
		for _, global in ipairs(W.CHAINS[n]) do
			W.setState(player, global, "complete")
		end

		H.setQuestStatus(player, W.STATUS[n] .. ":attempted", "1")

		local t = W.talk(player, { W.TRAIN[order[n]].reply })

		lu.assertEquals(t[1].id, "m" .. n .. "_reward", "mission " .. n .. ": first screen")
		lu.assertEquals(t[#t].id, W.TRAIN[order[n]].trained, "mission " .. n .. ": last screen")
		lu.assertEquals(count(player), n, "mission " .. n .. ": skills held")
		lu.assertEquals(player.ghost.pilotTier, n == 4 and 4 or 3, "mission " .. n .. ": pilot tier")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "mission " .. n .. ": client strings")
	end

	lu.assertEquals(player.bankCredits, 4 * W.CREDITS, "four rewards paid once each")
	lu.assertEquals(W.standing(player), 4 * W.STANDING, "four times +100 standing")
	lu.assertEquals(#W.items(player), 4, "four ship components")

	for n = 1, 4 do
		lu.assertEquals(W.paid(player, n), "1", "mission " .. n .. " :reward")
	end

	-- the interface to tier 4 (Source inventory 6): four _03 skills, pilot tier 4, the mission 4 reward key, VORTEX_PILOT_KEY unchanged (I-7)
	lu.assertEquals(W.flag(player), "3", "VORTEX_PILOT_KEY keeps Vrovel's value")
	lu.assertEquals(W.firstScreen(player), "tier_done", "the next talk")

	local after = M.snapshot(player).status
	local changed = W.statusDiff(player, before, after)

	for _, suffix in ipairs(changed) do
		local ok = false

		for _, key in ipairs(W.statusKeys()) do
			ok = ok or key == suffix
		end

		lu.assertTrue(ok, "Ezkiel wrote a key that is not one of the 8 Part A status keys: " .. suffix .. " (I-7)")
	end
end

-- AC-8: tier_done raises a tier-3 pilot with four _03 skills to tier 4 and grants nothing else
function TestEzkielHandoff:test_tier_done_raises_a_tier_3_pilot_with_four_skills_to_tier_4_and_grants_nothing_else()
	local player = W.pilot({ missions = 4, t3 = 4, pilotTier = 3 })
	local t = W.talk(player)

	lu.assertEquals(W.ids(t), { "tier_done" }, "first screen")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier")
	lu.assertEquals(#W.free() + #W.bought(), 0, "no skill granted")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(#W.items(player), 0, "no item")
	lu.assertEquals(W.standing(player), 0, "standing unchanged")
	lu.assertEquals(#H.Engine.callsTo("createEvent"), 0, "no quest started")
end

-- AC-8: the raise happens once; a tier 4 pilot is not raised again, a pilot with fewer than four skills is not raised
function TestEzkielHandoff:test_tier_done_raises_the_pilot_tier_only_for_tier_3_pilots_with_all_four_skills()
	local p4 = W.pilot({ missions = 4, t3 = 4, pilotTier = 4 })

	W.talk(p4)
	W.talk(p4)
	lu.assertEquals(p4.ghost.pilotTier, 4, "a tier 4 pilot stays at 4")

	local p3 = W.pilot({ missions = 4, t3 = 3, pilotTier = 3 })

	W.drive(p3, "tier_done")
	lu.assertEquals(p3.ghost.pilotTier, 3, "three skills: not raised")

	local fresh = W.pilot({ missions = 4, t3 = 4, pilotTier = 3 })

	W.talk(fresh)
	W.talk(fresh)
	lu.assertEquals(fresh.ghost.pilotTier, 4, "a second talk leaves it at 4")
end

-- AC-8: the two replies reach the two endings (via handoff_evin and handoff_miss), both ending
function TestEzkielHandoff:test_the_two_replies_reach_the_two_endings()
	local cases = {
		{ replies = { "s_9ac7f904", "s_eba35f17" }, ids = { "tier_done", "handoff_evin", "handoff_leave" } },
		{ replies = { "s_eb3c17f0", "s_5e57a2aa" }, ids = { "tier_done", "handoff_miss", "handoff_thanks" } },
	}

	for _, c in ipairs(cases) do
		H.reset()

		local player = W.pilot({ missions = 4, t3 = 4 })
		local t = W.talk(player, c.replies)

		lu.assertEquals(W.ids(t), c.ids, "walk " .. table.concat(c.replies, ","))
		lu.assertTrue(t[#t].stop, t[#t].id .. " ends the conversation")
		lu.assertEquals(#t[#t].options, 0, t[#t].id .. " offers no reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		lu.assertEquals(#W.free() + #W.bought(), 0, "no skill granted by the endings")
		lu.assertEquals(player.bankCredits, 0, "no credits from the endings")
		lu.assertEquals(W.flag(player), "3", "VORTEX_PILOT_KEY untouched by the hand-off (I-7)")
	end
end

-- AC-8: the endings name Brother Extok Evin (Talus, Dearic), the hand-off lines are J3's
function TestEzkielHandoff:test_the_hand_off_names_brother_extok_evin()
	local text = require("vortex_tier3_ezkiel_client_text")
	local t = W.talk(W.pilot({ missions = 4, t3 = 4 }), { "s_9ac7f904" })

	lu.assertEquals(t[2].id, "handoff_evin", "second screen")
	lu.assertEquals(t[2].text, W.PREFIX .. "s_991a471c", "'Not yet. You'll be reporting to Brother Extok Evin...'")
	lu.assertStrContains(text.s_991a471c, "Brother Extok Evin", false, "the hand-off line names him")
end

-- AC-8, I-7: the hand-off walks write no quest key and no flag
function TestEzkielHandoff:test_the_endings_set_no_quest_status_key()
	local player = W.pilot({ missions = 4, t3 = 4 })
	local before = M.snapshot(player).status

	W.talk(player, { "s_eb3c17f0", "s_5e57a2aa" })
	W.talk(player, { "s_9ac7f904", "s_eba35f17" })
	lu.assertEquals(W.statusDiff(player, before, M.snapshot(player).status), {}, "status keys changed by the hand-off walks")
end

-- AC-8, I-7: no walk of the gates, offers or rewards writes VORTEX_PILOT_KEY (spot check of every flag value over a reward walk)
function TestEzkielHandoff:test_a_reward_and_training_walk_leaves_the_flag_as_it_was()
	for _, flag in ipairs({ "1", "2", "3" }) do
		H.reset()

		local player = pilot(1, {}, { graduated = flag })

		W.talk(player, { W.TRAIN[1].reply })
		lu.assertEquals(W.flag(player), flag, "VORTEX_PILOT_KEY after a reward walk with flag " .. flag)
	end
end
