-- Major Eker: two-step free-choice training of the four tier 2 skills bought with XP, the pilot tier 2 -> 3 step, and the whole tier 2 walk.
-- Spec: .claude/work/crimson-phoenix-tier2-eker-convo/01-spec.md (AC-7; Conversation flow 2 (C-3), 3.4 and 4; FE-2, FE-3, FE-11; D-3, D-4; I-6; Q-2 = A, Q-4 = A).
--
-- training_offer -> training_menu (the missing topics in table order, then the leave reply) -> a confirm screen -> yes buys the skill and shows its trained
-- screen, no returns to the menu or closes. The purchase is SpaceHelpers:grantSpaceSkill(p, skill, true): XP only (60,000 space_combat_general, SWG skills.tab
-- XP_COST), never credits (Q-2 = A), never free. The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_rebel_navy_02.tab.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.

local lu = require("luaunit")
local H = require("harness")
local E = require("crimson_tier2_data")
local CS = require("harness.client_strings")

E.loadConversation()

local COST = E.XP_COST

local function setUp()
	H.reset()
	E.requireConversation(lu)
	E.useSkillCosts()
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function boughtBy(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("skillManagerAwardSkill")) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

-- every free grant of a tier 2 skill (there must be none)
local function freeBy(player)
	local out = {}

	for _, call in ipairs(H.Engine.callsTo("awardSkill")) do
		if call[1] == player and call[2]:find("^pilot_rebel_navy_%a+_02$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(boughtBy(player), {}, label .. ": bought grants")
	lu.assertEquals(freeBy(player), {}, label .. ": free grants")
end

-- the TRAIN indexes not in `have`
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

-- a flag-2 graduate with the tier 2 skills of the TRAIN indexes `have` and the XP; the gates are tested elsewhere and the conversation is driven
-- from the screens
local function pilot(have, xp, extra)
	local o = { skills = {}, xp = xp or 0, graduated = "2" }

	for _, i in ipairs(have or {}) do
		o.skills[#o.skills + 1] = E.TRAIN[i].skill
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return E.pilot(o)
end

-- every subset of {1..4}
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

local OFFER_MENU = "s_dd2fd70"

---------------------------------------------------------------------------------------------
-- The offer and the menu
---------------------------------------------------------------------------------------------

TestEkerTrainingMenu = {}

TestEkerTrainingMenu.setUp = setUp

-- AC-7: the offer's four replies: the menu (by three routes) or the pass line
function TestEkerTrainingMenu:test_the_offer_leads_to_the_menu_by_any_of_its_three_routes_or_to_the_pass_line()
	local direct = E.talk(pilot({}, COST), { OFFER_MENU })

	lu.assertEquals(E.ids(direct), { "training_offer", "training_menu" }, "What can he teach me?")

	local findOut = E.talk(pilot({}, COST), { "s_2f0a6ba8", "s_a6e1c30a" })

	lu.assertEquals(E.ids(findOut), { "training_offer", "training_find_out", "training_menu" }, "What could these dregs possibly teach me?")

	local free = E.talk(pilot({}, COST), { "s_dede1eae", "s_f4862cb7" })

	lu.assertEquals(E.ids(free), { "training_offer", "training_free", "training_menu" }, "Do I have to pay them for the training?")

	local pass = E.talk(pilot({}, COST), { "s_fd447981" })

	lu.assertEquals(E.ids(pass), { "training_offer", "training_pass" }, "pass")
	lu.assertTrue(pass[2].stop, "training_pass ends")
	lu.assertEquals(CS.transcriptUnresolved(direct), {}, "client strings")
	lu.assertEquals(CS.transcriptUnresolved(findOut), {}, "client strings")
	lu.assertEquals(CS.transcriptUnresolved(free), {}, "client strings")
end

-- AC-7, AC-8: find_out and free also lead to the duty menu
function TestEkerTrainingMenu:test_the_find_out_and_free_screens_also_lead_to_the_duty_menu()
	local findOut = E.talk(pilot({}, COST), { "s_2f0a6ba8", "s_11e0bfe9" })
	local free = E.talk(pilot({}, COST), { "s_dede1eae", "s_8a4cdaa1" })

	lu.assertEquals(E.ids(findOut), { "training_offer", "training_find_out", "duty_menu" }, "find out -> duties")
	lu.assertEquals(E.ids(free), { "training_offer", "training_free", "duty_menu" }, "free -> duties")
end

-- AC-7, C-3: the menu lists exactly the missing topics in table order, then the leave reply, whatever the held subset
function TestEkerTrainingMenu:test_the_menu_lists_exactly_the_missing_topics_in_table_order_and_the_leave_reply()
	for _, have in ipairs(subsets()) do
		H.reset()
		E.useSkillCosts()

		local want, links, label = {}, {}, "holding {" .. table.concat(have, ",") .. "}"

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = E.TRAIN[i].reply
			links[#links + 1] = E.TRAIN[i].confirm
		end

		want[#want + 1] = E.LEAVE_REPLY
		links[#links + 1] = "training_passing_up"

		local t = E.drive(pilot(have, COST), "training_menu")

		lu.assertEquals(t[1].text, E.PREFIX .. "s_27b3d1b3", label .. ": the menu line")
		lu.assertEquals(E.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertEquals(E.linksOf(t[1]), links, label .. ": menu links")
		lu.assertFalse(t[1].stop, label .. ": the menu waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
	end
end

-- AC-7: each topic leads to its own confirm screen, which asks and offers one yes and one no (pairing of the spec's section 3.4)
function TestEkerTrainingMenu:test_each_topic_leads_to_its_confirm_screen_with_its_yes_and_no_replies()
	for _, x in ipairs(E.TRAIN) do
		H.reset()
		E.useSkillCosts()

		local t = E.talk(pilot({}, COST), { OFFER_MENU, x.reply })

		lu.assertEquals(E.ids(t), { "training_offer", "training_menu", x.confirm }, x.x .. ": the walk")
		lu.assertEquals(t[3].text, E.PREFIX .. x.confirmSid, x.x .. ": the confirm line")
		lu.assertEquals(E.optionSids(t[3]), { x.yes[1], x.no[1] }, x.x .. ": yes and no replies")
		lu.assertEquals(E.linksOf(t[3]), { x.yes[2], x.no[2] }, x.x .. ": yes and no links")
		lu.assertFalse(t[3].stop, x.x .. ": the confirm waits")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the leave reply closes with the "passing up" line and grants nothing
function TestEkerTrainingMenu:test_the_leave_reply_closes_with_training_passing_up_and_grants_nothing()
	local player = pilot({}, COST)
	local t = E.talk(player, { OFFER_MENU, E.LEAVE_REPLY })

	lu.assertEquals(E.ids(t), { "training_offer", "training_menu", "training_passing_up" }, "the walk")
	lu.assertTrue(t[3].stop, "training_passing_up ends")
	noGrant(player, "leave")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

-- AC-7: the "no" replies: starships and droid return to the menu, weapons and procedures close (the spec's pairing)
function TestEkerTrainingMenu:test_the_no_replies_return_to_the_menu_or_close_as_the_spec_says_and_grant_nothing()
	for _, x in ipairs(E.TRAIN) do
		H.reset()
		E.useSkillCosts()

		local player = pilot({}, COST)
		local t = E.talk(player, { OFFER_MENU, x.reply, x.no[1] })

		lu.assertEquals(E.ids(t), { "training_offer", "training_menu", x.confirm, x.no[2] }, x.x .. ": the walk")
		noGrant(player, x.x .. " no")
		lu.assertEquals(exp(player), COST, x.x .. ": no XP charged")
		lu.assertEquals(t[4].stop, x.no[2] == "training_passing_up", x.x .. ": the screen after no ends only when it is training_passing_up")
	end
end

-- AC-7: showing a menu, a confirm or a trained screen alone grants nothing
function TestEkerTrainingMenu:test_showing_a_menu_a_confirm_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({}, COST)

	E.talk(player)
	E.drive(player, "training_menu")

	for _, x in ipairs(E.TRAIN) do
		E.drive(player, x.confirm)
		E.drive(player, x.trained)
	end

	noGrant(player, "screens displayed alone")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is untouched")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestEkerTrainingGrant = {}

TestEkerTrainingGrant.setUp = setUp

-- AC-7, D-3, Q-2 = A: the yes reply buys the skill (never free), charges 60,000 XP and no credits, shows the trained screen and ends
for _, x in ipairs(E.TRAIN) do
	TestEkerTrainingGrant["test_the_yes_reply_for_" .. x.x .. "_buys_the_skill_charges_the_xp_and_no_credits_and_shows_the_trained_line"] = function()
		local player = pilot({}, COST + 20000)
		local t = E.talk(player, { OFFER_MENU, x.reply, x.yes[1] })

		lu.assertEquals(E.ids(t), { "training_offer", "training_menu", x.confirm, x.trained }, x.x .. ": the walk")
		lu.assertEquals(t[4].text, E.PREFIX .. E.TRAINED_SID, "the trained line")
		lu.assertTrue(t[4].stop, x.trained .. " ends the conversation")
		lu.assertEquals(boughtBy(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(freeBy(player), {}, "free grants (no tier 2 skill is free)")
		lu.assertEquals(E.held2(player), { x.skill }, "tier 2 skills held")
		lu.assertEquals(exp(player), 20000, "space XP after the purchase")
		lu.assertEquals(player.bankCredits, 0, "bank credits (no credit charge)")
		lu.assertEquals(#player.bankCreditLog, 0, "credit movements")
		lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier stays 2 on the first skill")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7, I-6: with exactly 60,000 XP the skill is bought and the XP drops to zero
function TestEkerTrainingGrant:test_exactly_60000_experience_buys_a_skill()
	local player = pilot({}, COST)

	E.talk(player, { OFFER_MENU, E.TRAIN[1].reply, E.TRAIN[1].yes[1] })
	lu.assertEquals(exp(player), 0, "space XP")
	lu.assertEquals(#E.held2(player), 1, "skills held")
end

-- AC-7: any one of the four can be bought first, and the others stay missing (free choice)
function TestEkerTrainingGrant:test_the_choice_is_free_each_topic_first_leaves_the_other_three_missing()
	for i, x in ipairs(E.TRAIN) do
		H.reset()
		E.useSkillCosts()

		local player = pilot({}, COST)
		local t = E.talk(player, { OFFER_MENU, x.reply, x.yes[1] })

		lu.assertEquals(t[#t].id, x.trained, x.x .. ": trained screen")

		local menu = E.drive(player, "training_menu")[1]
		local want = {}

		for _, k in ipairs(missing({ i })) do
			want[#want + 1] = E.TRAIN[k].reply
		end

		want[#want + 1] = E.LEAVE_REPLY
		lu.assertEquals(E.optionSids(menu), want, x.x .. " bought: the menu lists the other three")
	end
end

-- AC-7: one conversation buys one skill (the trained screen ends it)
function TestEkerTrainingGrant:test_one_conversation_buys_exactly_one_skill()
	local player = pilot({}, 3 * COST)
	local t = E.talk(player, { OFFER_MENU, E.TRAIN[2].reply, E.TRAIN[2].yes[1] })

	lu.assertTrue(t[#t].stop, "the conversation ends on the trained screen")
	lu.assertEquals(boughtBy(player), { E.TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-7, I-6: with less than 60,000 XP at the yes reply nothing is granted and the gate screen is returned
function TestEkerTrainingGrant:test_with_too_little_experience_at_the_yes_reply_nothing_is_granted_and_the_gate_screen_returns()
	local player = pilot({}, COST)
	local t = E.talk(player, { OFFER_MENU, E.TRAIN[1].reply, function(p) p.ghost.experience.space_combat_general = COST - 1 end, E.TRAIN[1].yes[1] })

	lu.assertEquals(t[#t].id, "duty_offer", "the gate screen for a flag-2 pilot who cannot train now")
	noGrant(player, "short of XP")
	lu.assertEquals(exp(player), COST - 1, "no XP charged")
	lu.assertEquals(#E.held2(player), 0, "skills")
end

-- AC-7, I-6: a skill already held is not granted again and costs nothing
function TestEkerTrainingGrant:test_a_skill_held_at_the_yes_reply_is_not_granted_again_and_costs_nothing()
	local player = pilot({}, COST)
	local x = E.TRAIN[1]
	local t = E.talk(player, { OFFER_MENU, x.reply, function(p) p.skills[x.skill] = true end, x.yes[1] })

	noGrant(player, "already held")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertNotEquals(t[#t].id, x.trained, "the trained screen is not shown for a skill that was not bought")
end

-- AC-7, I-6: a pilot who lost the flag between the screens is sent back through the gates and granted nothing
function TestEkerTrainingGrant:test_a_pilot_without_the_flag_at_the_yes_reply_is_granted_nothing()
	local player = pilot({}, COST)
	local x = E.TRAIN[1]
	local t = E.talk(player, { OFFER_MENU, x.reply, function(p) H.setQuestStatus(p, E.EKER_PILOT_KEY, "") end, x.yes[1] })

	noGrant(player, "no flag")
	lu.assertEquals(t[#t].id, "non_member", "the gate screen")
end

-- AC-7, I-6: the confirm screens alone, reached without the menu, grant only through the yes link of their own screen
function TestEkerTrainingGrant:test_the_yes_link_of_each_confirm_screen_buys_only_its_own_skill()
	for _, x in ipairs(E.TRAIN) do
		H.reset()
		E.useSkillCosts()

		local player = pilot({}, COST)
		local t = E.drive(player, x.confirm, { x.yes[1] })

		lu.assertEquals(E.ids(t), { x.confirm, x.trained }, x.x .. ": the walk")
		lu.assertEquals(boughtBy(player), { x.skill }, x.x .. ": bought")
	end
end

-- AC-7, I-6: no credit is ever charged: a pilot with credits keeps them through all four purchases
function TestEkerTrainingGrant:test_credits_never_change_on_a_grant()
	local player = pilot({}, 4 * COST)

	player.bankCredits = 12345

	for _, x in ipairs(E.TRAIN) do
		E.drive(player, x.confirm, { x.yes[1] })
	end

	lu.assertEquals(#E.held2(player), 4, "four skills bought")
	lu.assertEquals(player.bankCredits, 12345, "bank credits")
	lu.assertEquals(#player.bankCreditLog, 0, "credit movements")
end

---------------------------------------------------------------------------------------------
-- The pilot tier 2 -> 3
---------------------------------------------------------------------------------------------

TestEkerPilotTier = {}

TestEkerPilotTier.setUp = setUp

-- AC-7: the fourth skill raises the pilot tier from 2 to 3, once, from any three held
function TestEkerPilotTier:test_the_fourth_skill_raises_the_pilot_tier_once_from_any_starting_set()
	for _, have in ipairs({ { 1, 2, 3 }, { 2, 3, 4 }, { 1, 3, 4 }, { 1, 2, 4 } }) do
		H.reset()
		E.useSkillCosts()

		local x = E.TRAIN[missing(have)[1]]
		local player = pilot(have, 2 * COST)
		local t = E.drive(player, x.confirm, { x.yes[1] })

		lu.assertEquals(t[#t].id, x.trained, "holding " .. table.concat(have, ",") .. ": the trained screen")
		lu.assertEquals(player.ghost.pilotTier, 3, "holding " .. table.concat(have, ",") .. ": the pilot tier")
		lu.assertEquals(#E.held2(player), 4, "four skills")

		-- a second pass changes nothing (the skill is held; the tier is not raised twice)
		E.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, 3, "holding " .. table.concat(have, ",") .. ": a second yes")
		lu.assertEquals(exp(player), COST, "holding " .. table.concat(have, ",") .. ": one price paid")
	end
end

-- AC-7, I-6: the first three skills leave the pilot tier at 2
function TestEkerPilotTier:test_the_first_three_skills_do_not_change_the_pilot_tier()
	for _, have in ipairs({ {}, { 1 }, { 1, 2 } }) do
		H.reset()
		E.useSkillCosts()

		local x = E.TRAIN[missing(have)[1]]
		local player = pilot(have, COST)

		E.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, 2, "holding " .. #have .. " skills: the pilot tier")
	end
end

-- AC-7, I-6: the tier changes only from 2 to 3: a pilot at another tier is left as he is
function TestEkerPilotTier:test_the_pilot_tier_changes_only_from_2_to_3()
	for _, tier in ipairs({ 1, 3, 4 }) do
		H.reset()
		E.useSkillCosts()

		local x = E.TRAIN[4]
		local player = pilot({ 1, 2, 3 }, COST, { pilotTier = tier })

		E.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. " stays")
	end
end

---------------------------------------------------------------------------------------------
-- The whole tier 2 walk (AC-7 last bullet)
---------------------------------------------------------------------------------------------

TestEkerTier2Walk = {}

TestEkerTier2Walk.setUp = setUp

-- AC-7: skill 1 -> M1 won and paid -> skill 2 -> M2 -> skill 3 -> M3 -> skill 4 -> M4 -> the hand-off, with the same pilot all the way
function TestEkerTier2Walk:test_skill_mission_skill_mission_reaches_the_hand_off_to_ulvawop()
	local player = pilot({}, 4 * COST)
	local spies = E.spyStarts()

	-- the briefing and accept walk of each mission, and the reply that pays on M2, M3 and M4
	local OFFER = {
		{ "s_468ab4d3", "s_313aff7d", "s_f685a04e" },
		{ "s_b1df084d", "s_d5609495", "s_8bdbd90b" },
		{ "s_ae785ffa", "s_841d27db", "s_3de0965c", "s_71bb443b", "s_6aacd1f1", "s_38f14bb8", "s_2588496a", "s_a99ad4e8" },
		{ "s_6673b556", "s_14bcd839", "s_32146025", "s_d24a2285", "s_c3c8f385" },
	}
	local ACCEPT = { "m1_accept_dismissed", "m2_accept_closing", "m3_accept", "m4_accept_trust" }
	local PAYREPLY = { nil, "s_c48841", "s_faf96c0a", "s_ef170270" }

	local function win(n)
		for _, global in ipairs(E.CHAINS[n]) do
			E.setState(player, global, "complete")
		end
	end

	for n = 1, 4 do
		-- training: the topic of this step
		local t = E.talk(player, { OFFER_MENU, E.TRAIN[n].reply, E.TRAIN[n].yes[1] })

		lu.assertEquals(t[1].id, "training_offer", "step " .. n .. ": the pilot is offered training")
		lu.assertEquals(t[#t].id, E.TRAIN[n].trained, "step " .. n .. ": the skill is bought")
		lu.assertEquals(#E.held2(player), n, "step " .. n .. ": skills held")
		lu.assertEquals(exp(player), (4 - n) * COST, "step " .. n .. ": XP left")

		-- the mission of this skill is offered next and accepted
		local m = E.talk(player, OFFER[n])

		lu.assertEquals(m[1].id, E.MISSIONS[n].offer, "step " .. n .. ": mission " .. n .. " is offered after skill " .. n)
		lu.assertEquals(m[#m].id, ACCEPT[n], "step " .. n .. ": the accept screen")
		lu.assertEquals(#spies[E.HEADS[n]], 1, "step " .. n .. ": the head started once")
		E.setState(player, E.HEADS[n], "none")
		win(n)

		-- the win is shown and paid (M1 on display, M2 to M4 on the reply)
		local w = E.talk(player, PAYREPLY[n] and { PAYREPLY[n] } or nil)

		lu.assertEquals(w[1].id, E.MISSIONS[n].won, "step " .. n .. ": the won screen")
		lu.assertEquals(player.bankCredits, n * E.CREDITS, "step " .. n .. ": credits paid so far")
		lu.assertEquals(E.standing(player), n * 75, "step " .. n .. ": Rebel standing so far")

		if n < 4 then
			lu.assertEquals(E.firstScreen(player), "training_offer", "step " .. n .. ": the next skill is offered, not the next mission")
		end
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "the pilot tier after the fourth skill")
	lu.assertEquals(E.flag(player), "3", "the flag after the mission 4 payment")
	lu.assertEquals(E.firstScreen(player), "tier3_handoff", "the hand-off")
	lu.assertEquals(player.bankCredits, 4 * E.CREDITS, "credits paid for four missions and none for skills")
end

-- AC-7: after the hand-off the pilot can no longer train (tier 2 is complete): the offer is not shown even with the XP
function TestEkerTier2Walk:test_a_tier_2_graduate_with_experience_is_never_offered_training()
	local player = E.pilot({ missions = 4, t2 = 4, graduated = "3", xp = 999999 })

	lu.assertEquals(E.firstScreen(player), "tier3_handoff", "the graduate with 999,999 XP")
end
