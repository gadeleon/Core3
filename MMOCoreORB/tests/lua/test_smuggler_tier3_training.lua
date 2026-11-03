-- Beissa: one-click, free-choice, free tier 3 training (FB-5, D-5, D-6): a topic reply on a reward screen grants the skill at once and shows the answer line
-- of the mission. One skill per won mission (I-10); the fourth skill raises pilot tier 3 to 4 (D-10); the M4 reward before the hand-off (D-7); the hand-off.
-- Spec: .claude/work/smuggler-tier3-beissa/01-spec.md (AC-9, AC-10, AC-5, I-10; Conversation flow 2 (C-1), 3 (table H) and 4; FB-5; D-5, D-6, D-7, D-10).
--
-- A reward screen lists one topic reply per missing tier 3 skill, in table order (starships, weapons, procedures, droid), built by the handler. The chosen topic
-- is read from the option text of the screen just shown; the grant is SpaceHelpers:grantSpaceSkill(player, skill, false) (BJ's noisyGrantSkill: no XP check,
-- no XP charge), made in getNextConversationScreen. Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.

local lu = require("luaunit")
local H = require("harness")
local B = require("smuggler_tier3_data")
local CS = require("harness.client_strings")

B.load()

local TRAIN = B.TRAIN
local XP = "space_combat_general"
local PREFIX = B.PREFIX

local restore = {}

local function setUp()
	H.reset()
	B.requireConversation(lu)

	-- the real engine would charge XP for a skill box; the free grant must not (these costs make a charge visible)
	local costs = {}

	for _, t in ipairs(TRAIN) do
		costs[t.skill] = 200000
	end

	H.Engine.config.skillXpCosts = costs
end

local function tearDown()
	for _, fn in ipairs(restore) do
		fn()
	end

	restore = {}
end

-- Records the calls of SpaceHelpers:grantSpaceSkill and runs the original
local function recordGrants()
	local calls = {}
	local orig = SpaceHelpers.grantSpaceSkill

	SpaceHelpers.grantSpaceSkill = function(self, pPlayer, skill, deduct)
		calls[#calls + 1] = { skill = skill, deduct = deduct }

		return orig(self, pPlayer, skill, deduct)
	end

	restore[#restore + 1] = function() SpaceHelpers.grantSpaceSkill = orig end

	return calls
end

local function noPurchase()
	lu.assertEquals(#H.Engine.callsTo("skillManagerAwardSkill"), 0, "XP-charging grants")
end

local function exp(player) return player.ghost.experience[XP] end

-- the first `count` TRAIN indexes that are not `except`
local function others(count, except)
	local out = {}

	for i = 1, 4 do
		if i ~= except and #out < count then
			out[#out + 1] = i
		end
	end

	return out
end

-- a pilot who won mission n (unpaid unless `paid`) and holds the tier 3 skills `have` (TRAIN indexes)
local function pilot(n, have, extra)
	local paid = {}

	for i = 1, n - 1 do
		paid[i] = i
	end

	local o = { t3 = have or {}, paid = paid, mission = { [n] = "won" } }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return B.pilot(o)
end

-- all 16 subsets of the four skills (indexes in table order)
local function subsets()
	local out = {}

	for mask = 0, 15 do
		local s = {}

		for i = 1, 4 do
			if mask & (1 << (i - 1)) ~= 0 then
				s[#s + 1] = i
			end
		end

		out[#out + 1] = s
	end

	return out
end

local function missing(have)
	local held = {}

	for _, i in ipairs(have) do
		held[i] = true
	end

	local out = {}

	for i = 1, 4 do
		if not held[i] then
			out[#out + 1] = i
		end
	end

	return out
end

-- all 24 orders of the four skills
local function permutations()
	local out = {}

	local function rec(prefix, rest)
		if #rest == 0 then
			out[#out + 1] = prefix
			return
		end

		for i = 1, #rest do
			local p, r = { table.unpack(prefix) }, { table.unpack(rest) }

			p[#p + 1] = table.remove(r, i)
			rec(p, r)
		end
	end

	rec({}, { 1, 2, 3, 4 })
	return out
end

---------------------------------------------------------------------------------------------
-- The reward screens (C-1)
---------------------------------------------------------------------------------------------

TestSmugglerT3TrainingMenu = {}

TestSmugglerT3TrainingMenu.setUp = setUp
TestSmugglerT3TrainingMenu.tearDown = tearDown

-- AC-9, FB-5: each reward screen lists exactly the missing skills, in table order, each leading to its mission's trained screen
function TestSmugglerT3TrainingMenu:test_every_reward_screen_lists_exactly_the_missing_skills_in_table_order()
	for n, m in ipairs(B.MISSIONS) do
		for _, have in ipairs(subsets()) do
			H.reset()

			local want, label = {}, m.reward .. " holding " .. table.concat(have, ",")

			for _, i in ipairs(missing(have)) do
				want[#want + 1] = TRAIN[i].reply
			end

			local links = {}

			for k = 1, #want do
				links[k] = m.trained
			end

			local t = B.drive(B.pilot({ t3 = have, mission = { [n] = "won" } }), m.reward)

			lu.assertEquals(B.ids(t), { m.reward }, label .. ": screens shown")
			lu.assertEquals(B.optionSids(t[1]), want, label .. ": topic replies")
			lu.assertEquals(B.linksOf(t[1]), links, label .. ": topic links (the trained screen of mission " .. n .. ")")
			lu.assertEquals(t[1].stop and true or false, #want == 0, label .. ": ends the conversation only when no topic is left")
			lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
		end
	end
end

-- AC-9: the lead-in lines of the reward screens are the NPC lines of Appendix A
function TestSmugglerT3TrainingMenu:test_the_reward_lines_are_the_ones_of_appendix_a()
	local want = { m1_reward = "s_ea4e584a", m2_reward = "s_3f262d6b", m3_reward = "s_22f30f4c", m4_reward = "s_bcb460ff" }

	for id, sid in pairs(want) do
		lu.assertEquals(B.drive(B.pilot({}), id)[1].text, PREFIX .. sid, id .. ": the lead-in line")
	end
end

-- AC-9: showing a trained screen alone grants nothing
function TestSmugglerT3TrainingMenu:test_showing_a_reward_or_trained_screen_alone_grants_no_skill()
	local grants = recordGrants()
	local player = pilot(1, {})

	for _, m in ipairs(B.MISSIONS) do
		B.drive(player, m.reward)
		B.drive(player, m.trained)
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#B.held(player), 0, "tier 3 skills held")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestSmugglerT3TrainingGrant = {}

TestSmugglerT3TrainingGrant.setUp = setUp
TestSmugglerT3TrainingGrant.tearDown = tearDown

for n, m in ipairs(B.MISSIONS) do
	for i, x in ipairs(TRAIN) do
		-- AC-9, D-5, D-6, I-10: the topic grants the skill through grantSpaceSkill(p, skill, false) and shows the mission's answer line, which ends
		TestSmugglerT3TrainingGrant["test_choosing_" .. x.x .. "_on_" .. m.reward .. "_grants_the_skill_for_free_and_shows_" .. m.trained] = function()
			local grants = recordGrants()
			local player = pilot(n, others(n - 1, i))
			local before = #B.held(player)
			local t = B.drive(player, m.reward, { x.reply })

			lu.assertEquals(B.ids(t), { m.reward, m.trained }, "screens shown")
			lu.assertEquals(t[2].text, PREFIX .. B.TRAINED_SID[n], m.trained .. ": the answer line of the mission (whatever skill was chosen)")
			lu.assertTrue(t[2].stop, m.trained .. " ends the conversation")
			lu.assertEquals(grants, { { skill = x.skill, deduct = false } }, "grantSpaceSkill(player, skill, false) calls")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the pilot holds " .. x.skill)
			lu.assertEquals(#B.held(player), before + 1, "tier 3 skills held")
			noPurchase()
			lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
		end
	end
end

-- AC-9: the engine's XP is neither checked nor charged: 0 and 200000 XP, the same result
function TestSmugglerT3TrainingGrant:test_the_grant_checks_and_charges_no_xp()
	for _, xp in ipairs({ 0, 200000 }) do
		for _, x in ipairs(TRAIN) do
			H.reset()
			setUp()

			local player = pilot(1, {}, { xp = xp })

			B.drive(player, "m1_reward", { x.reply })
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), xp .. " XP: the pilot holds " .. x.skill)
			lu.assertEquals(exp(player), xp, xp .. " XP: space XP after the choice")
			noPurchase()
		end
	end
end

-- AC-9: through the whole talk: the reward screen (pays), the topic, the answer
function TestSmugglerT3TrainingGrant:test_the_whole_talk_from_the_first_screen_grants_one_skill_and_pays_once()
	local player = pilot(1, {})
	local t = B.talk(player, { "s_a9aeb386" })

	lu.assertEquals(B.ids(t), { "m1_reward", "m1_trained" }, "screens shown")
	lu.assertEquals(B.held(player), { TRAIN[2].skill }, "tier 3 skills held (weapons)")
	lu.assertEquals(player.bankCredits, B.CREDITS, "paid once")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9, I-10: one skill per won mission: after the grant the reward screen is gone and the next offer follows; the tier stays 3
function TestSmugglerT3TrainingGrant:test_the_next_visit_shows_the_next_mission_offer_and_the_tier_stays_3()
	for n = 1, 3 do
		H.reset()
		setUp()

		local player = pilot(n, others(n - 1, 4))

		B.drive(player, B.MISSIONS[n].reward, { TRAIN[4].reply })
		lu.assertEquals(B.firstScreen(player), B.MISSIONS[n + 1].offer, "mission " .. n .. " done: the next visit")
		lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after skill " .. n)
	end
end

-- AC-9, I-10: a second choice after the grant grants nothing (the reward screen is not shown again; the guard routes by the gates)
function TestSmugglerT3TrainingGrant:test_a_second_choice_for_the_same_mission_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})

	B.drive(player, "m1_reward", { TRAIN[1].reply })

	local t = B.drive(player, "m1_reward", { TRAIN[2].reply })

	lu.assertEquals(#grants, 1, "grantSpaceSkill calls over both talks")
	lu.assertEquals(B.held(player), { TRAIN[1].skill }, "tier 3 skills held")
	lu.assertEquals(B.ids(t), { "m1_reward", "m2_offer" }, "the second choice routes by the gates to the next offer")
end

-- AC-9, D-10: the fourth skill raises the pilot tier 3 to 4, and only then
function TestSmugglerT3TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_3_to_4()
	for i, x in ipairs(TRAIN) do
		H.reset()
		setUp()

		local player = pilot(4, others(3, i))

		lu.assertEquals(player.ghost.pilotTier, 3, "precondition: pilot tier 3")
		B.drive(player, "m4_reward", { x.reply })
		lu.assertEquals(player.ghost.pilotTier, 4, x.x .. ": pilot tier after the fourth skill")
	end
end

-- AC-9: the third skill does not
function TestSmugglerT3TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	local player = pilot(3, others(2, 3))

	B.drive(player, "m3_reward", { TRAIN[3].reply })
	lu.assertEquals(#B.held(player), 3, "three skills")
	lu.assertEquals(player.ghost.pilotTier, 3, "pilot tier after the third skill")
end

-- AC-9: a pilot at tier 4 is not changed
function TestSmugglerT3TrainingGrant:test_a_pilot_at_tier_4_is_not_changed()
	local player = pilot(4, others(3, 1), { pilotTier = 4 })

	B.drive(player, "m4_reward", { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier stays 4")
end

-- AC-9, D-10: a tier 2 pilot who somehow reaches the fourth skill is raised one step at a time (2 -> 3 by the safety net, then 3 -> 4)
function TestSmugglerT3TrainingGrant:test_the_tier_rule_never_skips_a_tier()
	local player = pilot(4, others(3, 1), { pilotTier = 2 })

	B.drive(player, "m4_reward", { TRAIN[1].reply })
	lu.assertEquals(player.ghost.pilotTier, 4, "2 -> 3 (tier 2 series won) -> 4 (four _03 skills): both steps in one grant")
end

-- AC-9: after the fourth skill the next visit is the hand-off
function TestSmugglerT3TrainingGrant:test_after_the_fourth_skill_the_next_visit_is_tier_done()
	local player = pilot(4, others(3, 2))

	B.drive(player, "m4_reward", { TRAIN[2].reply })
	lu.assertEquals(B.firstScreen(player), "tier_done", "next visit")
end

-- AC-9, I-10: all 24 orders of the choices over the four missions, one pilot, the real flow: each reward screen offers exactly the skills not chosen yet
-- in table order, the choice grants that skill, the count equals the won mission's number, no XP moves, the tier follows
function TestSmugglerT3TrainingGrant:test_the_four_skills_can_be_chosen_in_any_of_the_24_orders_over_four_missions()
	for _, order in ipairs(permutations()) do
		H.reset()
		setUp()

		local label = "order " .. table.concat(order, ",")
		local player = B.pilot({})
		local held = {}

		for n = 1, 4 do
			B.setMission(player, n, "won")

			local want = {}

			for _, i in ipairs(missing(held)) do
				want[#want + 1] = TRAIN[i].reply
			end

			local t = B.talk(player, { TRAIN[order[n]].reply })

			lu.assertEquals(B.ids(t), { B.MISSIONS[n].reward, B.MISSIONS[n].trained }, label .. ", mission " .. n .. ": screens")
			lu.assertEquals(B.optionSids(t[1]), want, label .. ", mission " .. n .. ": topics offered")
			held[#held + 1] = order[n]
			lu.assertEquals(#B.held(player), n, label .. ", mission " .. n .. ": tier 3 skills held")
			lu.assertTrue(CreatureObject(player):hasSkill(TRAIN[order[n]].skill), label .. ", mission " .. n .. ": holds " .. TRAIN[order[n]].skill)
			lu.assertEquals(exp(player), 0, label .. ", mission " .. n .. ": XP")
			lu.assertEquals(player.ghost.pilotTier, n == 4 and 4 or 3, label .. ", mission " .. n .. ": pilot tier")
		end

		noPurchase()
		lu.assertEquals(player.bankCredits, 4 * B.CREDITS, label .. ": four rewards")
	end
end

---------------------------------------------------------------------------------------------
-- Guards
---------------------------------------------------------------------------------------------

TestSmugglerT3TrainingGuards = {}

TestSmugglerT3TrainingGuards.setUp = setUp
TestSmugglerT3TrainingGuards.tearDown = tearDown

-- AC-9: a skill the pilot got meanwhile is not granted again
function TestSmugglerT3TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_granted_again()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = B.drive(player, "m1_reward", {
		function(p) p.skills[TRAIN[1].skill] = true end,
		TRAIN[1].reply,
	})

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(B.ids(t), { "m1_reward", "m2_offer" }, "routed by the gates")
	lu.assertEquals(#B.held(player), 1, "tier 3 skills held")
end

-- AC-9: a mission that is no longer won grants nothing and routes by the gates
function TestSmugglerT3TrainingGuards:test_a_mission_that_is_no_longer_won_grants_nothing_and_routes_by_the_gates()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = B.drive(player, "m1_reward", {
		function(p) B.setMission(p, 1, "attempted") end,
		TRAIN[3].reply,
	})

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(B.ids(t)[2], "m1_failed", "routed by the gates: mission 1 failed")
	lu.assertEquals(#B.held(player), 0, "tier 3 skills held")
end

-- AC-9: a topic chosen with no reward pending grants nothing
function TestSmugglerT3TrainingGuards:test_a_topic_chosen_with_no_reward_pending_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})
	local t = B.drive(player, "m1_reward", {
		function(p) B.setMission(p, 1, "paid"); p.skills[TRAIN[4].skill] = true end,
		TRAIN[2].reply,
	})

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(B.ids(t)[2], "m2_offer", "routed by the gates")
	lu.assertEquals(B.held(player), { TRAIN[4].skill }, "tier 3 skills held")
end

-- AC-9: a trained screen shown alone ends and grants nothing
function TestSmugglerT3TrainingGuards:test_a_trained_screen_shown_alone_ends_and_grants_nothing()
	local grants = recordGrants()
	local player = pilot(1, {})

	for _, m in ipairs(B.MISSIONS) do
		local t = B.drive(player, m.trained, { 0 })

		lu.assertEquals(B.ids(t), { m.trained }, m.trained .. ": screens")
		lu.assertTrue(t[1].stop, m.trained .. " ends")
	end

	lu.assertEquals(grants, {}, "grantSpaceSkill calls")
	lu.assertEquals(#B.held(player), 0, "tier 3 skills held")
end

---------------------------------------------------------------------------------------------
-- The M4 reward and the hand-off (D-7)
---------------------------------------------------------------------------------------------

TestSmugglerT3HandOff = {}

TestSmugglerT3HandOff.setUp = setUp
TestSmugglerT3HandOff.tearDown = tearDown

-- AC-10, D-7: mission 4 unpaid with four skills: the reward screen pays, has no option and ends; the next visit is the hand-off
function TestSmugglerT3HandOff:test_mission_4_unpaid_with_four_skills_shows_the_reward_with_no_option_and_the_next_visit_is_tier_done()
	local player = B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })
	local t = B.talk(player)

	lu.assertEquals(B.ids(t), { "m4_reward" }, "first screen")
	lu.assertEquals(t[1].options, {}, "m4_reward: no option")
	lu.assertTrue(t[1].stop, "m4_reward ends the conversation")
	lu.assertEquals(player.bankCredits, B.CREDITS, "the reward is paid")
	lu.assertEquals(B.firstScreen(player), "tier_done", "next visit")
	lu.assertEquals(player.bankCredits, B.CREDITS, "paid once")
end

-- AC-10: tier_done reaches both endings, which name Karrde and end the conversation
function TestSmugglerT3HandOff:test_tier_done_leads_to_both_endings_that_name_karrde()
	local routes = {
		{ choices = { "s_cc1cb635", "s_741f40ea" }, ids = { "tier_done", "done_never_together", "done_wont_miss" } },
		{ choices = { "s_249fa88e", "s_1248fc74" }, ids = { "tier_done", "done_sarcastic", "done_strange" } },
	}

	for _, r in ipairs(routes) do
		H.reset()

		local player = B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })
		local t = B.talk(player, r.choices)

		lu.assertEquals(B.ids(t), r.ids, "screens shown")
		lu.assertTrue(t[#t].stop, r.ids[#r.ids] .. " ends the conversation")
		lu.assertNotNil(B.TEXT[t[#t].text:match("s_[%w]+$")]:find("Karrde", 1, true), r.ids[#r.ids] .. " sends the pilot to Talon Karrde")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-10, D-10: tier_done raises a tier 3 pilot who has the four skills (a missed raise) to tier 4
function TestSmugglerT3HandOff:test_tier_done_raises_pilot_tier_3_to_4()
	local player = B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 } })

	lu.assertEquals(player.ghost.pilotTier, 3, "precondition: pilot tier 3")
	B.drive(player, "tier_done")
	lu.assertEquals(player.ghost.pilotTier, 4, "pilot tier after tier_done")
end

-- AC-10: the hand-off starts and grants nothing else
function TestSmugglerT3HandOff:test_the_hand_off_starts_and_grants_nothing_but_the_tier()
	local spies = B.spyStarts()
	local grants = recordGrants()
	local player = B.pilot({ t3 = { 1, 2, 3, 4 }, paid = { 1, 2, 3, 4 }, pilotTier = 4 })
	local before = B.snapshot(player)

	B.talk(player, { "s_cc1cb635", "s_741f40ea" })
	lu.assertEquals(B.started(spies), {}, "quests started")
	lu.assertEquals(grants, {}, "skills granted")
	lu.assertEquals(B.snapshot(player), before, "nothing changes for a pilot who is at tier 4")
end
