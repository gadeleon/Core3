-- Hakassha Sireen: the two-step tier 1 training (Q1 = A), the promotion and the hand-off to Prisk Kith'Vys.
-- Spec: .claude/work/black-epsilon-tier1-hakassha/01-spec.md (AC-9, AC-10, AC-5; Conversation flow 3.4; FH-2; R-2).
--
-- The pilot picks a topic on `training_menu` (one reply per missing skill, in table order, then "Never mind"), reads the topic description
-- (`train_<x>`) and confirms with "I'd like to study that in detail." (s_c6d9f61) or goes back with "I want to study something else." (s_786f3cf7).
-- The skill is granted when the confirm is chosen: free (awardSkill) when the pilot holds no tier 1 skill, bought (skillManagerAwardSkill) otherwise.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.
-- The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_01.tab (7500 each).

local lu = require("luaunit")
local H = require("harness")
local B = require("black_epsilon_tier1_data")
local CS = require("harness.client_strings")

B.load()

local TRAIN = B.TRAIN
local MENU = "s_19ff301f"

local function setUp()
	H.reset()
	B.requireConversation(lu)
end

local function exp(player) return player.ghost.experience.space_combat_general end

local function skillsOf(list)
	local out = {}

	for i, x in ipairs(list) do
		out[i] = TRAIN[x].skill
	end

	return out
end

-- a pilot with mission 4 paid, the tier 1 skills `have` (indexes into TRAIN) and `xp`
local function pilot(have, xp, extra)
	local o = { paid = 4, skills = skillsOf(have or {}), xp = xp or 0 }

	for k, v in pairs(extra or {}) do
		o[k] = v
	end

	return B.pilot(o)
end

local function grantedFree(player)
	local out = {}

	for _, call in ipairs(B.free()) do
		if call[1] == player and call[2]:find("^pilot_imperial_navy_%a+_01$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function grantedBought(player)
	local out = {}

	for _, call in ipairs(B.bought()) do
		if call[1] == player then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function noGrant(player, label)
	lu.assertEquals(grantedFree(player), {}, label .. ": free grants")
	lu.assertEquals(grantedBought(player), {}, label .. ": bought grants")
end

-- all proper non-empty subsets of the four skills (indexes in table order)
local function subsets()
	local out = {}

	for mask = 1, 14 do
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

---------------------------------------------------------------------------------------------
-- The menu
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1TrainingMenu = {}

TestBlackEpsilonT1TrainingMenu.setUp = setUp

-- AC-9: no skill yet, the offer and the menu with the four topics and "Never mind"
function TestBlackEpsilonT1TrainingMenu:test_a_pilot_with_no_tier_1_skill_gets_the_offer_and_a_menu_of_four_topics_plus_never_mind()
	local t = B.talk(pilot({}, 0), { MENU })

	lu.assertEquals(B.ids(t), { "training_offer", "training_menu" }, "screens shown")
	lu.assertEquals(t[2].text, B.PREFIX .. "s_444df4b9", "the menu line")
	lu.assertEquals(B.optionSids(t[2]), { "s_5e3cf461", "s_577aca95", "s_fb13007f", "s_a57e647c", "s_dc63dc1a" }, "menu replies, in table order, then Never mind")
	lu.assertEquals(B.linksOf(t[2]), { "train_starships", "train_weapons", "train_procedures", "train_droid", "training_never_mind" }, "menu links")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: "What kind of training?" / "Not interested" on the offer
function TestBlackEpsilonT1TrainingMenu:test_the_offer_has_the_question_and_the_decline()
	local t = B.talk(pilot({}, 0))

	lu.assertEquals(B.optionSids(t[1]), { MENU, "s_710daa61" }, "training_offer replies")
	lu.assertEquals(B.linksOf(t[1]), { "training_menu", "training_declined" }, "training_offer links for a ready pilot")
end

-- AC-9
function TestBlackEpsilonT1TrainingMenu:test_declining_the_offer_ends_without_a_grant()
	local player = pilot({}, 0)
	local t = B.talk(player, { "s_710daa61" })

	lu.assertEquals(B.ids(t), { "training_offer", "training_declined" }, "screens shown")
	lu.assertTrue(t[2].stop, "training_declined ends")
	noGrant(player, "declined")
end

-- AC-9: with 1 to 3 skills and XP the menu lists exactly the missing ones, in table order
function TestBlackEpsilonT1TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].desc
		end

		want[#want + 1] = B.NEVER_MIND
		links[#links + 1] = "training_never_mind"

		local t = B.talk(pilot(have, 7500), { MENU })

		lu.assertEquals(B.ids(t), { "training_offer", "training_menu" }, label .. ": screens shown")
		lu.assertEquals(B.optionSids(t[2]), want, label .. ": menu replies")
		lu.assertEquals(B.linksOf(t[2]), links, label .. ": menu links")
	end
end

-- AC-9: "Never mind"
function TestBlackEpsilonT1TrainingMenu:test_never_mind_ends_the_conversation_without_a_grant()
	local player = pilot({}, 0)
	local t = B.talk(player, { MENU, B.NEVER_MIND })

	lu.assertEquals(B.ids(t), { "training_offer", "training_menu", "training_never_mind" }, "screens shown")
	lu.assertTrue(t[3].stop, "training_never_mind ends")
	noGrant(player, "never mind")
end

-- AC-9: each topic shows its own description with the confirm and the back reply
function TestBlackEpsilonT1TrainingMenu:test_each_topic_shows_its_description_with_confirm_and_back()
	for _, x in ipairs(TRAIN) do
		H.reset()

		local t = B.talk(pilot({}, 0), { MENU, x.reply })

		lu.assertEquals(t[3].id, x.desc, x.x .. ": screen")
		lu.assertEquals(t[3].text, B.PREFIX .. x.descSid, x.x .. ": description line")
		lu.assertEquals(B.optionSids(t[3]), { B.CONFIRM, B.BACK }, x.x .. ": replies")
		lu.assertEquals(B.linksOf(t[3]), { x.trained, "training_menu" }, x.x .. ": links")
	end
end

-- AC-9: the back reply returns to the menu with no grant
function TestBlackEpsilonT1TrainingMenu:test_back_returns_to_the_same_menu_without_a_grant()
	local player = pilot({}, 0)
	local t = B.talk(player, { MENU, "s_577aca95", B.BACK })

	lu.assertEquals(B.ids(t), { "training_offer", "training_menu", "train_weapons", "training_menu" }, "screens shown")
	lu.assertEquals(B.optionSids(t[4]), B.optionSids(t[2]), "the menu is the same")
	noGrant(player, "back")
	lu.assertEquals(B.held(player), {}, "no tier 1 skill")
end

-- AC-9 (C-3): the question leads to the menu only for a ready pilot
function TestBlackEpsilonT1TrainingMenu:test_the_question_leads_to_training_not_ready_for_a_pilot_who_is_not_ready()
	local player = pilot({ 1, 2, 3 }, 0)
	local t = B.drive(player, "training_offer", { MENU })

	lu.assertEquals(B.ids(t), { "training_offer", "training_not_ready" }, "screens shown")
	lu.assertTrue(t[2].stop, "training_not_ready ends")
	lu.assertEquals(B.held(player), skillsOf({ 1, 2, 3 }), "no skill gained")
	noGrant(player, "not ready")
end

-- AC-9 (C-3)
function TestBlackEpsilonT1TrainingMenu:test_isReadyForTraining_follows_the_rule()
	local h = rawget(_G, B.HANDLER)

	lu.assertTrue(h:isReadyForTraining(pilot({}, 0)), "no skill: the first is free")
	lu.assertTrue(h:isReadyForTraining(pilot({ 2 }, 7500)), "one skill, 7500 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ 2 }, 7499)), "one skill, 7499 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ 1, 2, 3, 4 }, 99999)), "all four: nothing left")
	lu.assertFalse(h:isReadyForTraining(B.pilot({ paid = 3 })), "mission 4 not paid")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1TrainingGrant = {}

TestBlackEpsilonT1TrainingGrant.setUp = setUp

-- AC-9: free first skill
for i, x in ipairs(TRAIN) do
	TestBlackEpsilonT1TrainingGrant["test_the_first_skill_" .. x.x .. "_is_granted_free_when_confirmed"] = function()
		local player = pilot({}, 0)
		local t = B.talk(player, { MENU, x.reply, B.CONFIRM })

		lu.assertEquals(B.ids(t), { "training_offer", "training_menu", x.desc, x.trained }, "screens shown")
		lu.assertEquals(t[4].text, B.PREFIX .. "s_7c8aca1b", "'Good choice. Report back when you are ready for an assignment.'")
		lu.assertTrue(t[4].stop, x.trained .. " ends the conversation")
		lu.assertEquals(grantedFree(player), { x.skill }, "awardSkill calls")
		lu.assertEquals(grantedBought(player), {}, "XP-deducting grants")
		lu.assertEquals(B.held(player), { x.skill }, "skills held")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: no grant on the topic or the description, only on the confirm
function TestBlackEpsilonT1TrainingGrant:test_nothing_is_granted_before_the_confirm()
	local player = pilot({}, 0)

	B.talk(player, { MENU, "s_5e3cf461" })
	noGrant(player, "topic chosen, not confirmed")
	B.drive(player, "trained_starships")
	noGrant(player, "trained_starships displayed alone")
end

-- AC-9: bought skills (1 to 3 held, 7500 XP)
for _, have in ipairs({ { 1 }, { 2, 3 }, { 1, 3, 4 } }) do
	for _, i in ipairs(missing(have)) do
		local x = TRAIN[i]

		TestBlackEpsilonT1TrainingGrant["test_holding_" .. table.concat(have, "_") .. "_the_pilot_buys_" .. x.x .. "_with_7500_xp"] = function()
			B.useSkillCosts()

			local player = pilot(have, 20000)
			local t = B.talk(player, { MENU, x.reply, B.CONFIRM })

			lu.assertEquals(B.ids(t), { "training_offer", "training_menu", x.desc, x.trained }, "screens shown")
			lu.assertEquals(grantedBought(player), { x.skill }, "skillManagerAwardSkill calls")
			lu.assertEquals(grantedFree(player), {}, "free grants")
			lu.assertEquals(exp(player), 12500, "space XP after the purchase")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the skill is held")
		end
	end
end

-- AC-9: the fourth skill raises the pilot tier 1 to 2, and only then
function TestBlackEpsilonT1TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_1_to_2()
	B.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500)

	lu.assertEquals(player.ghost.pilotTier, 1, "precondition: pilot tier 1")
	B.talk(player, { MENU, "s_a57e647c", B.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the fourth skill")
	lu.assertEquals(B.firstScreen(player), "tier_done", "the next visit opens tier_done")
end

-- AC-9
function TestBlackEpsilonT1TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	B.useSkillCosts()

	local player = pilot({ 1, 2 }, 7500)

	B.talk(player, { MENU, "s_fb13007f", B.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier after the third skill")
end

-- AC-9: a pilot already at tier 2 keeps it
function TestBlackEpsilonT1TrainingGrant:test_a_pilot_at_tier_2_is_not_raised_again()
	B.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500, { pilotTier = 2 })

	B.talk(player, { MENU, "s_a57e647c", B.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
end

-- AC-9: one skill per visit
function TestBlackEpsilonT1TrainingGrant:test_one_confirm_grants_one_skill_and_ends_the_conversation()
	B.useSkillCosts()

	local player = pilot({ 1 }, 99999)
	local t = B.talk(player, { MENU, "s_577aca95", B.CONFIRM, MENU })

	lu.assertEquals(#t, 4, "the conversation ends at trained_weapons")
	lu.assertEquals(grantedBought(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 99999 - 7500, "one price paid")
end

-- AC-9: the skills can be taken in any order, free first then bought
function TestBlackEpsilonT1TrainingGrant:test_the_four_skills_can_be_trained_in_a_reversed_order_over_four_visits()
	B.useSkillCosts()

	local player = pilot({}, 7500 * 3)

	for step, i in ipairs({ 4, 3, 2, 1 }) do
		local t = B.talk(player, { MENU, TRAIN[i].reply, B.CONFIRM })

		lu.assertEquals(t[#t].id, TRAIN[i].trained, "visit " .. step .. ": last screen")
	end

	lu.assertEquals(grantedFree(player), { TRAIN[4].skill }, "the first skill is the free one")
	lu.assertEquals(grantedBought(player), { TRAIN[3].skill, TRAIN[2].skill, TRAIN[1].skill }, "the other three are bought")
	lu.assertEquals(exp(player), 0, "three prices paid")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the fourth skill")
end

-- AC-9: with 1 to 3 skills and too little XP the pilot is not offered training
function TestBlackEpsilonT1TrainingGrant:test_with_too_little_xp_the_first_screen_is_duty_missions()
	for _, have in ipairs(subsets()) do
		H.reset()
		lu.assertEquals(B.firstScreen(pilot(have, 7499)), "duty_missions", "holding " .. table.concat(have, ",") .. " with 7499 XP")
	end
end

---------------------------------------------------------------------------------------------
-- Guards that fail while the menu is shown (hooks)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1TrainingGuards = {}

TestBlackEpsilonT1TrainingGuards.setUp = setUp

-- AC-9
function TestBlackEpsilonT1TrainingGuards:test_xp_that_is_gone_before_the_confirm_buys_nothing_and_the_gates_route_the_pilot()
	B.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = B.talk(player, { MENU, "s_577aca95", function(p) p.ghost.experience.space_combat_general = 0 end, B.CONFIRM })

	lu.assertEquals(t[#t].id, "duty_missions", "routed by the gates: one skill, no XP")
	noGrant(player, "xp gone")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
end

-- AC-9
function TestBlackEpsilonT1TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_granted_again()
	B.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = B.talk(player, { MENU, "s_577aca95", function(p) p.skills[TRAIN[2].skill] = true end, B.CONFIRM })

	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates: two skills and 7500 XP")
	noGrant(player, "skill already held")
end

-- AC-9: the free grant needs "no tier 1 skill" at the confirm
function TestBlackEpsilonT1TrainingGuards:test_the_free_grant_is_refused_once_the_pilot_holds_a_tier_1_skill_and_has_no_xp()
	B.useSkillCosts()

	local player = pilot({}, 0)
	local t = B.talk(player, { MENU, "s_5e3cf461", function(p) p.skills[TRAIN[2].skill] = true end, B.CONFIRM })

	lu.assertEquals(t[#t].id, "duty_missions", "routed by the gates: one skill, no XP")
	noGrant(player, "free grant after a skill appeared")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[1].skill), "the topic's skill is not held")
end

-- AC-9
function TestBlackEpsilonT1TrainingGuards:test_all_four_skills_gained_meanwhile_route_the_pilot_to_tier_done_without_a_grant()
	local player = pilot({}, 0)
	local t = B.talk(player, { MENU, "s_5e3cf461", function(p)
		for _, x in ipairs(TRAIN) do
			p.skills[x.skill] = true
		end
	end, B.CONFIRM })

	lu.assertEquals(t[#t].id, "tier_done", "routed by the gates")
	noGrant(player, "tier already complete")
end

-- AC-9: the confirm needs the mission 4 reward
function TestBlackEpsilonT1TrainingGuards:test_a_confirm_without_the_mission_4_reward_grants_nothing()
	local player = B.pilot({ paid = 3 })
	local t = B.drive(player, "train_starships", { B.CONFIRM })

	lu.assertEquals(t[#t].id, "mission4_offer", "routed by the gates: missions 1 to 3 paid")
	noGrant(player, "mission 4 unpaid")
end

-- AC-9
function TestBlackEpsilonT1TrainingGuards:test_the_mission_4_reward_taken_away_meanwhile_grants_nothing()
	local player = pilot({}, 0)
	local t = B.talk(player, { MENU, "s_5e3cf461", function(p) removeQuestStatus(p.objectID .. "corellia_imperial_4:reward") end, B.CONFIRM })

	lu.assertEquals(t[#t].id, "mission4_won", "routed by the gates: mission 4 won and unpaid")
	noGrant(player, "reward key gone")
end

-- AC-9: a confirm from a pilot who already has the skill
function TestBlackEpsilonT1TrainingGuards:test_a_confirm_for_a_skill_already_held_grants_nothing()
	B.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = B.drive(player, "train_starships", { B.CONFIRM })

	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates")
	noGrant(player, "skill held")
end

-- AC-9: the XP-deducting grant is refused by the engine when the prerequisites are not met
function TestBlackEpsilonT1TrainingGuards:test_when_the_engine_refuses_the_purchase_the_pilot_gets_no_trained_screen()
	local real = LuaSkillManager

	LuaSkillManager = function()
		return { fulfillsSkillPrerequisitesAndXp = function() return false end, awardSkill = real().awardSkill }
	end

	local player = pilot({ 1 }, 7500)
	local t = B.talk(player, { MENU, "s_577aca95", B.CONFIRM })

	LuaSkillManager = real
	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
	lu.assertEquals(grantedBought(player), {}, "no purchase attempted")
end

---------------------------------------------------------------------------------------------
-- AC-10: tier done, promotion, hand-off
---------------------------------------------------------------------------------------------

TestBlackEpsilonT1HandOff = {}

TestBlackEpsilonT1HandOff.setUp = setUp

local function graduate() return B.pilot({ paid = 4, tier = 4, pilotTier = 2 }) end

-- AC-10
function TestBlackEpsilonT1HandOff:test_tier_done_leads_to_the_promotion_and_the_promotion_sets_the_series_flag()
	local player = graduate()

	B.talk(player, {})
	lu.assertNil(H.getQuestStatus(player, B.SERIES_SUFFIX), "tier_done alone does not set the flag")

	local t = B.talk(player, { "s_df75425", "s_665a7735", "s_c602907a" })

	lu.assertEquals(B.ids(t), { "tier_done", "promotion", "promotion_honored", "promotion_glory" }, "screens shown")
	lu.assertTrue(t[4].stop, "promotion_glory ends")
	lu.assertEquals(H.getQuestStatus(player, B.SERIES_SUFFIX), "1", "series flag")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the flag is set on the promotion screen already
function TestBlackEpsilonT1HandOff:test_the_series_flag_is_set_when_the_promotion_screen_is_shown()
	local player = graduate()

	B.talk(player, { "s_df75425" })
	lu.assertEquals(H.getQuestStatus(player, B.SERIES_SUFFIX), "1", "series flag after promotion")
end

-- AC-10
function TestBlackEpsilonT1HandOff:test_after_the_promotion_the_next_talk_opens_series_complete()
	local player = graduate()

	B.talk(player, { "s_df75425" })

	local t = B.talk(player)

	lu.assertEquals(t[1].id, "series_complete", "first screen")
	lu.assertEquals(B.optionSids(t[1]), { "s_2d5d4bf0", "s_943c7ba6", "s_3e77e17d" }, "replies")
	lu.assertEquals(B.linksOf(t[1]), { "duty_menu", "nothing_to_teach", "transfer_to_prisk" }, "links")
	lu.assertNil(H.getQuestStatus(player, B.PRISK_SUFFIX), "the Prisk flag is not set by the greeting")
end

-- AC-10
function TestBlackEpsilonT1HandOff:test_series_complete_leads_to_the_duty_menu_and_a_duty()
	local player = graduate()

	B.talk(player, { "s_df75425" })

	local spy = H.spyOn(B.quest(B.DUTY6), "startQuest")
	local t = B.talk(player, { "s_2d5d4bf0", "s_13e807c3", "s_7839f2d4" })

	lu.assertEquals(B.ids(t), { "series_complete", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertEquals(#spy, 1, "destroy duty started")
end

-- AC-10
function TestBlackEpsilonT1HandOff:test_nothing_to_teach_ends_and_the_hand_off_has_not_happened()
	local player = graduate()

	B.talk(player, { "s_df75425" })

	local t = B.talk(player, { "s_943c7ba6" })

	lu.assertEquals(B.ids(t), { "series_complete", "nothing_to_teach" }, "screens shown")
	lu.assertTrue(t[2].stop, "nothing_to_teach ends")
	lu.assertNil(H.getQuestStatus(player, B.PRISK_SUFFIX), "no Prisk flag")
	lu.assertEquals(B.firstScreen(player), "series_complete", "still series_complete")
end

-- AC-10
function TestBlackEpsilonT1HandOff:test_the_transfer_sets_the_prisk_flag_and_every_later_talk_opens_working_for_prisk()
	local player = graduate()

	B.talk(player, { "s_df75425" })

	local t = B.talk(player, { "s_3e77e17d" })

	lu.assertEquals(B.ids(t), { "series_complete", "transfer_to_prisk" }, "screens shown")
	lu.assertTrue(t[2].stop, "transfer_to_prisk ends")
	lu.assertEquals(H.getQuestStatus(player, B.PRISK_SUFFIX), "1", "Prisk flag")

	for visit = 1, 3 do
		local again = B.talk(player)

		lu.assertEquals(B.ids(again), { "working_for_prisk" }, "visit " .. visit .. " after the transfer")
		lu.assertTrue(again[1].stop, "working_for_prisk ends")
	end

	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: the flags are the public keys of the squadron object, stored as <playerID><key>
function TestBlackEpsilonT1HandOff:test_the_flags_are_stored_under_the_squadron_constants()
	local player = graduate()

	B.talk(player, { "s_df75425" })
	B.talk(player, { "s_3e77e17d" })
	lu.assertEquals(getQuestStatus(player.objectID .. BlackEpsilonSquadronScreenplay.SERIES_COMPLETE_KEY), "1", "series key")
	lu.assertEquals(getQuestStatus(player.objectID .. BlackEpsilonSquadronScreenplay.WORKING_FOR_PRISK_KEY), "1", "Prisk key")
end

-- AC-10: the whole career from the fourth skill
function TestBlackEpsilonT1HandOff:test_the_fourth_skill_leads_to_tier_done_then_the_promotion_then_series_complete()
	B.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500)

	B.talk(player, { MENU, "s_a57e647c", B.CONFIRM })
	lu.assertEquals(B.firstScreen(player), "tier_done", "after the fourth skill")
	B.talk(player, { "s_df75425" })
	lu.assertEquals(B.firstScreen(player), "series_complete", "after the promotion")
end
