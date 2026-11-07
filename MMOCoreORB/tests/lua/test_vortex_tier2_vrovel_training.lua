-- Brother Vrovel: two-step free-choice training of the four tier 2 skills bought with XP, the pilot tier 2 -> 3 step, and the whole tier 2 walk.
-- Spec: .claude/work/vortex-tier2-vrovel/01-spec.md (AC-7; Conversation flow 2 (C-3), 3.4 and 4; FV-2, FV-3; D-3, D-4, D-5, D-6; I-6).
--
-- training_offer -> training_menu (the missing topics in table order, then the leave reply) -> a confirm screen -> yes buys the skill and shows its trained
-- screen, no returns to the menu or closes. The purchase is SpaceHelpers:grantSpaceSkill(p, skill, true): XP only (60,000 space_combat_general, SWG skills.tab
-- XP_COST), never credits, never free. The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_rebel_navy_02.tab.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.

local lu = require("luaunit")
local H = require("harness")
local V = require("vortex_tier2_data")
local CS = require("harness.client_strings")

V.loadConversation()

local COST = V.XP_COST

local function setUp()
	H.reset()
	V.requireConversation(lu)
	V.useSkillCosts()
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

-- a flag-2 graduate with the tier 2 skills of the TRAIN indexes `have`, the XP; mission paid state is not set (the gates are tested elsewhere and the
-- conversation is driven from the screens)
local function pilot(have, xp, extra)
	local o = { skills = {}, xp = xp or 0, graduated = "2" }

	for _, i in ipairs(have or {}) do
		o.skills[#o.skills + 1] = V.TRAIN[i].skill
	end

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return V.pilot(o)
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

---------------------------------------------------------------------------------------------
-- The offer and the menu
---------------------------------------------------------------------------------------------

TestVrovelTrainingMenu = {}

TestVrovelTrainingMenu.setUp = setUp

-- AC-7: yes opens the menu, no closes with the declined line
function TestVrovelTrainingMenu:test_the_offer_leads_to_the_menu_or_to_the_declined_line()
	local yes = V.talk(pilot({}, COST), { "s_9b8d2abd" })

	lu.assertEquals(V.ids(yes), { "training_offer", "training_menu" }, "yes")

	local no = V.talk(pilot({}, COST), { "s_2e18346d" })

	lu.assertEquals(V.ids(no), { "training_offer", "training_declined" }, "no")
	lu.assertTrue(no[2].stop, "training_declined ends")
	lu.assertEquals(CS.transcriptUnresolved(yes), {}, "client strings")
end

-- AC-7, C-3: the menu lists exactly the missing topics in table order, then the leave reply, whatever the held subset
function TestVrovelTrainingMenu:test_the_menu_lists_exactly_the_missing_topics_in_table_order_and_the_leave_reply()
	for _, have in ipairs(subsets()) do
		H.reset()
		V.useSkillCosts()

		local want, links, label = {}, {}, "holding {" .. table.concat(have, ",") .. "}"

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = V.TRAIN[i].reply
			links[#links + 1] = V.TRAIN[i].confirm
		end

		want[#want + 1] = V.LEAVE_REPLY
		links[#links + 1] = "training_later"

		local t = V.drive(pilot(have, COST), "training_menu")

		lu.assertEquals(t[1].text, V.PREFIX .. "s_c5b76777", label .. ": the menu line")
		lu.assertEquals(V.optionSids(t[1]), want, label .. ": menu replies")
		lu.assertEquals(V.linksOf(t[1]), links, label .. ": menu links")
		lu.assertFalse(t[1].stop, label .. ": the menu waits for a reply")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, label .. ": client strings")
	end
end

-- AC-7: each topic leads to its own confirm screen, which asks and offers one yes and one no (pairing of the spec's section 3.4)
function TestVrovelTrainingMenu:test_each_topic_leads_to_its_confirm_screen_with_its_yes_and_no_replies()
	for _, x in ipairs(V.TRAIN) do
		H.reset()
		V.useSkillCosts()

		local t = V.talk(pilot({}, COST), { "s_9b8d2abd", x.reply })

		lu.assertEquals(V.ids(t), { "training_offer", "training_menu", x.confirm }, x.x .. ": the walk")
		lu.assertEquals(t[3].text, V.PREFIX .. x.confirmSid, x.x .. ": the confirm line")
		lu.assertEquals(V.optionSids(t[3]), { x.yes[1], x.no[1] }, x.x .. ": yes and no replies")
		lu.assertEquals(V.linksOf(t[3]), { x.yes[2], x.no[2] }, x.x .. ": yes and no links")
		lu.assertFalse(t[3].stop, x.x .. ": the confirm waits")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7: the leave reply closes with the "hurry back" line and grants nothing
function TestVrovelTrainingMenu:test_the_leave_reply_closes_with_training_later_and_grants_nothing()
	local player = pilot({}, COST)
	local t = V.talk(player, { "s_9b8d2abd", V.LEAVE_REPLY })

	lu.assertEquals(V.ids(t), { "training_offer", "training_menu", "training_later" }, "the walk")
	lu.assertTrue(t[3].stop, "training_later ends")
	noGrant(player, "leave")
	lu.assertEquals(exp(player), COST, "no XP charged")
end

-- AC-7: the "no" replies: starships and droid return to the menu, weapons and procedures close (the spec's pairing)
function TestVrovelTrainingMenu:test_the_no_replies_return_to_the_menu_or_close_as_the_spec_says_and_grant_nothing()
	for _, x in ipairs(V.TRAIN) do
		H.reset()
		V.useSkillCosts()

		local player = pilot({}, COST)
		local t = V.talk(player, { "s_9b8d2abd", x.reply, x.no[1] })

		lu.assertEquals(V.ids(t), { "training_offer", "training_menu", x.confirm, x.no[2] }, x.x .. ": the walk")
		noGrant(player, x.x .. " no")
		lu.assertEquals(exp(player), COST, x.x .. ": no XP charged")
		lu.assertEquals(t[4].stop, x.no[2] == "training_later", x.x .. ": the screen after no ends only when it is training_later")
	end
end

-- AC-7: showing a menu, a confirm or a trained screen alone grants nothing
function TestVrovelTrainingMenu:test_showing_a_menu_a_confirm_or_a_trained_screen_alone_grants_nothing()
	local player = pilot({}, COST)

	V.talk(player)
	V.drive(player, "training_menu")

	for _, x in ipairs(V.TRAIN) do
		V.drive(player, x.confirm)
		V.drive(player, x.trained)
	end

	noGrant(player, "screens displayed alone")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier is untouched")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestVrovelTrainingGrant = {}

TestVrovelTrainingGrant.setUp = setUp

-- AC-7, D-4, D-5: the yes reply buys the skill (never free), charges 60,000 XP and no credits, shows the trained screen and ends
for _, x in ipairs(V.TRAIN) do
	TestVrovelTrainingGrant["test_the_yes_reply_for_" .. x.x .. "_buys_the_skill_charges_the_xp_and_no_credits_and_shows_the_trained_line"] = function()
		local player = pilot({}, COST + 20000)
		local t = V.talk(player, { "s_9b8d2abd", x.reply, x.yes[1] })

		lu.assertEquals(V.ids(t), { "training_offer", "training_menu", x.confirm, x.trained }, x.x .. ": the walk")
		lu.assertEquals(t[4].text, V.PREFIX .. x.trainedSid, "the trained line")
		lu.assertTrue(t[4].stop, x.trained .. " ends the conversation")
		lu.assertEquals(boughtBy(player), { x.skill }, "skillManagerAwardSkill calls")
		lu.assertEquals(freeBy(player), {}, "free grants (no tier 2 skill is free)")
		lu.assertEquals(V.held2(player), { x.skill }, "tier 2 skills held")
		lu.assertEquals(exp(player), 20000, "space XP after the purchase")
		lu.assertEquals(player.bankCredits, 0, "bank credits (no credit charge)")
		lu.assertEquals(#player.bankCreditLog, 0, "credit movements")
		lu.assertEquals(player.ghost.pilotTier, 2, "the pilot tier stays 2 on the first skill")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-7, I-6: with exactly 60,000 XP the skill is bought and the XP drops to zero
function TestVrovelTrainingGrant:test_exactly_60000_experience_buys_a_skill()
	local player = pilot({}, COST)

	V.talk(player, { "s_9b8d2abd", V.TRAIN[1].reply, V.TRAIN[1].yes[1] })
	lu.assertEquals(exp(player), 0, "space XP")
	lu.assertEquals(#V.held2(player), 1, "skills held")
end

-- AC-7: any one of the four can be bought first, and the others stay missing (free choice)
function TestVrovelTrainingGrant:test_the_choice_is_free_each_topic_first_leaves_the_other_three_missing()
	for i, x in ipairs(V.TRAIN) do
		H.reset()
		V.useSkillCosts()

		local player = pilot({}, COST)
		local t = V.talk(player, { "s_9b8d2abd", x.reply, x.yes[1] })

		lu.assertEquals(t[#t].id, x.trained, x.x .. ": trained screen")

		local menu = V.drive(player, "training_menu")[1]
		local want = {}

		for _, k in ipairs(missing({ i })) do
			want[#want + 1] = V.TRAIN[k].reply
		end

		want[#want + 1] = V.LEAVE_REPLY
		lu.assertEquals(V.optionSids(menu), want, x.x .. " bought: the menu lists the other three")
	end
end

-- AC-7: one conversation buys one skill (the trained screen ends it)
function TestVrovelTrainingGrant:test_one_conversation_buys_exactly_one_skill()
	local player = pilot({}, 3 * COST)
	local t = V.talk(player, { "s_9b8d2abd", V.TRAIN[2].reply, V.TRAIN[2].yes[1] })

	lu.assertTrue(t[#t].stop, "the conversation ends on the trained screen")
	lu.assertEquals(boughtBy(player), { V.TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 2 * COST, "one price paid")
end

-- AC-7, I-6: with less than 60,000 XP at the yes reply nothing is granted and the gate screen is returned
function TestVrovelTrainingGrant:test_with_too_little_experience_at_the_yes_reply_nothing_is_granted_and_the_gate_screen_returns()
	local player = pilot({}, COST)
	local t = V.talk(player, { "s_9b8d2abd", V.TRAIN[1].reply, function(p) p.ghost.experience.space_combat_general = COST - 1 end, V.TRAIN[1].yes[1] })

	lu.assertEquals(t[#t].id, "duty_offer", "the gate screen for a flag-2 pilot who cannot train now")
	noGrant(player, "short of XP")
	lu.assertEquals(exp(player), COST - 1, "no XP charged")
	lu.assertEquals(#V.held2(player), 0, "skills")
end

-- AC-7, I-6: a skill already held is not granted again and costs nothing
function TestVrovelTrainingGrant:test_a_skill_held_at_the_yes_reply_is_not_granted_again_and_costs_nothing()
	local player = pilot({}, COST)
	local x = V.TRAIN[1]
	local t = V.talk(player, { "s_9b8d2abd", x.reply, function(p) p.skills[x.skill] = true end, x.yes[1] })

	noGrant(player, "already held")
	lu.assertEquals(exp(player), COST, "no XP charged")
	lu.assertNotEquals(t[#t].id, x.trained, "the trained screen is not shown for a skill that was not bought")
end

-- AC-7, I-6: a pilot who lost the flag between the screens is sent back through the gates and granted nothing
function TestVrovelTrainingGrant:test_a_pilot_without_the_flag_at_the_yes_reply_is_granted_nothing()
	local player = pilot({}, COST)
	local x = V.TRAIN[1]
	local t = V.talk(player, { "s_9b8d2abd", x.reply, function(p) H.setQuestStatus(p, V.VORTEX_PILOT_KEY, "") end, x.yes[1] })

	noGrant(player, "no flag")
	lu.assertEquals(t[#t].id, "non_member", "the gate screen")
end

-- AC-7, I-6: the confirm screens alone, reached without the menu, grant only through the yes link of their own screen
function TestVrovelTrainingGrant:test_the_yes_link_of_each_confirm_screen_buys_only_its_own_skill()
	for _, x in ipairs(V.TRAIN) do
		H.reset()
		V.useSkillCosts()

		local player = pilot({}, COST)
		local t = V.drive(player, x.confirm, { x.yes[1] })

		lu.assertEquals(V.ids(t), { x.confirm, x.trained }, x.x .. ": the walk")
		lu.assertEquals(boughtBy(player), { x.skill }, x.x .. ": bought")
	end
end

-- AC-7, I-6: no credit is ever charged: a pilot with credits keeps them through all four purchases
function TestVrovelTrainingGrant:test_credits_never_change_on_a_grant()
	local player = pilot({}, 4 * COST)

	player.bankCredits = 12345

	for _, x in ipairs(V.TRAIN) do
		V.drive(player, x.confirm, { x.yes[1] })
	end

	lu.assertEquals(#V.held2(player), 4, "four skills bought")
	lu.assertEquals(player.bankCredits, 12345, "bank credits")
	lu.assertEquals(#player.bankCreditLog, 0, "credit movements")
end

---------------------------------------------------------------------------------------------
-- The pilot tier 2 -> 3
---------------------------------------------------------------------------------------------

TestVrovelPilotTier = {}

TestVrovelPilotTier.setUp = setUp

-- AC-7: the fourth skill raises the pilot tier from 2 to 3, once, from any three held
function TestVrovelPilotTier:test_the_fourth_skill_raises_the_pilot_tier_once_from_any_starting_set()
	for _, have in ipairs({ { 1, 2, 3 }, { 2, 3, 4 }, { 1, 3, 4 }, { 1, 2, 4 } }) do
		H.reset()
		V.useSkillCosts()

		local x = V.TRAIN[missing(have)[1]]
		local player = pilot(have, 2 * COST)
		local t = V.drive(player, x.confirm, { x.yes[1] })

		lu.assertEquals(t[#t].id, x.trained, "holding " .. table.concat(have, ",") .. ": the trained screen")
		lu.assertEquals(player.ghost.pilotTier, 3, "holding " .. table.concat(have, ",") .. ": the pilot tier")
		lu.assertEquals(#V.held2(player), 4, "four skills")

		-- a second pass changes nothing (the skill is held; the tier is not raised twice)
		V.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, 3, "holding " .. table.concat(have, ",") .. ": a second yes")
		lu.assertEquals(exp(player), COST, "holding " .. table.concat(have, ",") .. ": one price paid")
	end
end

-- AC-7, I-6: the first three skills leave the pilot tier at 2
function TestVrovelPilotTier:test_the_first_three_skills_do_not_change_the_pilot_tier()
	for _, have in ipairs({ {}, { 1 }, { 1, 2 } }) do
		H.reset()
		V.useSkillCosts()

		local x = V.TRAIN[missing(have)[1]]
		local player = pilot(have, COST)

		V.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, 2, "holding " .. #have .. " skills: the pilot tier")
	end
end

-- AC-7, I-6: the tier changes only from 2 to 3: a pilot at another tier is left as he is
function TestVrovelPilotTier:test_the_pilot_tier_changes_only_from_2_to_3()
	for _, tier in ipairs({ 1, 3, 4 }) do
		H.reset()
		V.useSkillCosts()

		local x = V.TRAIN[4]
		local player = pilot({ 1, 2, 3 }, COST, { pilotTier = tier })

		V.drive(player, x.confirm, { x.yes[1] })
		lu.assertEquals(player.ghost.pilotTier, tier, "pilot tier " .. tier .. " stays")
	end
end

---------------------------------------------------------------------------------------------
-- The whole tier 2 walk (AC-7 last bullet)
---------------------------------------------------------------------------------------------

TestVrovelTier2Walk = {}

TestVrovelTier2Walk.setUp = setUp

-- AC-7: skill 1 -> M1 won and paid -> skill 2 -> M2 -> skill 3 -> M3 -> skill 4 -> M4 -> the hand-off to Ezkiel, with the same pilot all the way
function TestVrovelTier2Walk:test_skill_mission_skill_mission_reaches_the_hand_off_to_ezkiel()
	local player = pilot({}, 4 * COST)
	local spies = V.spyStarts()

	-- the briefing and accept walk of each mission, and the reply that pays on M2 and M4
	local OFFER = {
		{ "s_77213dae", "s_92aee067" },
		{ "s_b91de387", "s_432be150", "s_b74318f4" },
		{ "s_3aa053cf", "s_ca3670fd" },
		{ "s_9793aadf", "s_8c4fba26", "s_9dbb5a9a", "s_16d870fe" },
	}
	local ACCEPT = { "m1_accept", "m2_accept", "m3_accept_wartime", "m4_accept" }
	local PAYREPLY = { nil, "s_fe92f35f", nil, "s_f931eb62" }

	local function win(n)
		for _, global in ipairs(V.CHAINS[n]) do
			V.setState(player, global, "complete")
		end
	end

	for n = 1, 4 do
		-- training: the first listed topic of the menu
		local t = V.talk(player, { "s_9b8d2abd", V.TRAIN[n].reply, V.TRAIN[n].yes[1] })

		lu.assertEquals(t[1].id, "training_offer", "step " .. n .. ": the pilot is offered training")
		lu.assertEquals(t[#t].id, V.TRAIN[n].trained, "step " .. n .. ": the skill is bought")
		lu.assertEquals(#V.held2(player), n, "step " .. n .. ": skills held")
		lu.assertEquals(exp(player), (4 - n) * COST, "step " .. n .. ": XP left")

		-- the mission of this skill is offered next and accepted
		local m = V.talk(player, OFFER[n])

		lu.assertEquals(m[1].id, V.MISSIONS[n].offer, "step " .. n .. ": mission " .. n .. " is offered after skill " .. n)
		lu.assertEquals(m[#m].id, ACCEPT[n], "step " .. n .. ": the accept screen")
		lu.assertEquals(#spies[V.HEADS[n]], 1, "step " .. n .. ": the head started once")
		V.setState(player, V.HEADS[n], "none")
		win(n)

		-- the win is shown and paid (M1 and M3 on display, M2 and M4 on the reply)
		local w = V.talk(player, PAYREPLY[n] and { PAYREPLY[n] } or nil)

		lu.assertEquals(w[1].id, V.MISSIONS[n].won, "step " .. n .. ": the won screen")
		lu.assertEquals(player.bankCredits, n * V.CREDITS, "step " .. n .. ": credits paid so far")
		lu.assertEquals(V.standing(player), n * 75, "step " .. n .. ": Rebel standing so far")

		if n < 4 then
			lu.assertEquals(V.firstScreen(player), "training_offer", "step " .. n .. ": the next skill is offered, not the next mission")
		end
	end

	lu.assertEquals(player.ghost.pilotTier, 3, "the pilot tier after the fourth skill")
	lu.assertEquals(V.flag(player), "3", "the flag after the mission 4 payment")
	lu.assertEquals(V.firstScreen(player), "ezkiel_handoff", "the hand-off to Ezkiel")
	lu.assertEquals(player.bankCredits, 4 * V.CREDITS, "credits paid for four missions and none for skills")
end
