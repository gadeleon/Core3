-- Lt. Akal Colzet: the two-step tier 1 training (FI-2), the promotion, the Authorization of Transfer and the hand-off to Commander Oberhaur.
-- Spec: .claude/work/storm-tier1-akal-colzet/01-spec.md (AC-9, AC-10, AC-5; Conversation flow 3.4; FI-1, FI-2, FI-7; D-9, D-10, D-11).
--
-- The pilot picks a topic on `training_menu` (one reply per missing skill, in table order, then "Never mind"), reads the topic description
-- (`train_<x>`) and confirms with "I'd like to study that in detail." (s_c6d9f61) or goes back with "I want to study something else." (s_786f3cf7).
-- The skill is granted when the confirm is chosen: free (awardSkill) when the pilot holds no tier 1 skill, bought (skillManagerAwardSkill) otherwise.
-- Guards are tested through hooks, functions between two choices that change the pilot while a screen is shown.
-- The fake charges XP only with H.Engine.config.skillXpCosts, set from fixtures/skill/skills.pilot_imperial_navy_01.tab (7500 each).

local lu = require("luaunit")
local H = require("harness")
local I = require("storm_tier1_data")
local CS = require("harness.client_strings")

I.load()

local TRAIN = I.TRAIN
local MENU = "s_19ff301f"

local function setUp()
	H.reset()
	I.requireConversation(lu)
end

local function concat(...)
	local out = {}

	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			out[#out + 1] = v
		end
	end

	return out
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

	return I.pilot(o)
end

local function grantedFree(player)
	local out = {}

	for _, call in ipairs(I.free()) do
		if call[1] == player and call[2]:find("^pilot_imperial_navy_%a+_01$") then
			out[#out + 1] = call[2]
		end
	end

	return out
end

local function grantedBought(player)
	local out = {}

	for _, call in ipairs(I.bought()) do
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

TestStormT1TrainingMenu = {}

TestStormT1TrainingMenu.setUp = setUp

-- AC-9: no skill yet, the offer and the menu with the four topics and "Never mind"
function TestStormT1TrainingMenu:test_a_pilot_with_no_tier_1_skill_gets_the_offer_and_a_menu_of_four_topics_plus_never_mind()
	local t = I.talk(pilot({}, 0), { MENU })

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu" }, "screens shown")
	lu.assertEquals(t[2].text, I.PREFIX .. I.MENU_LINE, "the menu line")
	lu.assertEquals(I.optionSids(t[2]), { "s_5e3cf461", "s_577aca95", "s_40f3848e", "s_a57e647c", "s_dc63dc1a" }, "menu replies, in table order, then Never mind")
	lu.assertEquals(I.linksOf(t[2]), { "train_starships", "train_weapons", "train_procedures", "train_droid", "training_never_mind" }, "menu links")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-9: "What kind of training?" / "Not interested" on the offer
function TestStormT1TrainingMenu:test_the_offer_has_the_question_and_the_decline()
	local t = I.talk(pilot({}, 0))

	lu.assertEquals(I.optionSids(t[1]), { MENU, "s_bf64734d" }, "training_offer replies")
	lu.assertEquals(I.linksOf(t[1]), { "training_menu", "training_declined" }, "training_offer links for a ready pilot")
end

-- AC-9
function TestStormT1TrainingMenu:test_declining_the_offer_ends_without_a_grant()
	local player = pilot({}, 0)
	local t = I.talk(player, { "s_bf64734d" })

	lu.assertEquals(I.ids(t), { "training_offer", "training_declined" }, "screens shown")
	lu.assertTrue(t[2].stop, "training_declined ends")
	noGrant(player, "declined")
end

-- AC-9: with 1 to 3 skills and XP the menu lists exactly the missing ones, in table order
function TestStormT1TrainingMenu:test_the_menu_lists_exactly_the_missing_skills_in_table_order()
	for _, have in ipairs(subsets()) do
		H.reset()

		local want, links, label = {}, {}, "holding " .. table.concat(have, ",")

		for _, i in ipairs(missing(have)) do
			want[#want + 1] = TRAIN[i].reply
			links[#links + 1] = TRAIN[i].desc
		end

		want[#want + 1] = I.NEVER_MIND
		links[#links + 1] = "training_never_mind"

		local t = I.talk(pilot(have, 7500), { MENU })

		lu.assertEquals(I.ids(t), { "training_offer", "training_menu" }, label .. ": screens shown")
		lu.assertEquals(I.optionSids(t[2]), want, label .. ": menu replies")
		lu.assertEquals(I.linksOf(t[2]), links, label .. ": menu links")
	end
end

-- AC-9: "Never mind"
function TestStormT1TrainingMenu:test_never_mind_ends_the_conversation_without_a_grant()
	local player = pilot({}, 0)
	local t = I.talk(player, { MENU, I.NEVER_MIND })

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu", "training_never_mind" }, "screens shown")
	lu.assertTrue(t[3].stop, "training_never_mind ends")
	noGrant(player, "never mind")
end

-- AC-9: each topic shows its own description with the confirm and the back reply
function TestStormT1TrainingMenu:test_each_topic_shows_its_description_with_confirm_and_back()
	for _, x in ipairs(TRAIN) do
		H.reset()

		local t = I.talk(pilot({}, 0), { MENU, x.reply })

		lu.assertEquals(t[3].id, x.desc, x.x .. ": screen")
		lu.assertEquals(t[3].text, I.PREFIX .. x.descSid, x.x .. ": description line")
		lu.assertEquals(I.optionSids(t[3]), { I.CONFIRM, I.BACK }, x.x .. ": replies")
		lu.assertEquals(I.linksOf(t[3]), { x.trained, "training_menu" }, x.x .. ": links")
	end
end

-- AC-9: the back reply returns to the menu with no grant
function TestStormT1TrainingMenu:test_back_returns_to_the_same_menu_without_a_grant()
	local player = pilot({}, 0)
	local t = I.talk(player, { MENU, "s_577aca95", I.BACK })

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu", "train_weapons", "training_menu" }, "screens shown")
	lu.assertEquals(I.optionSids(t[4]), I.optionSids(t[2]), "the menu is the same")
	noGrant(player, "back")
	lu.assertEquals(I.held(player), {}, "no tier 1 skill")
end

-- AC-9: the offer always leads to the menu (the gate G13 already checked readiness)
function TestStormT1TrainingMenu:test_the_offer_question_always_leads_to_the_menu()
	local t = I.drive(pilot({ 1, 2, 3 }, 0), "training_offer", { MENU })

	lu.assertEquals(I.ids(t), { "training_offer", "training_menu" }, "screens shown")
end

-- AC-9
function TestStormT1TrainingMenu:test_isReadyForTraining_follows_the_rule()
	local h = rawget(_G, I.HANDLER)

	lu.assertTrue(h:isReadyForTraining(pilot({}, 0)), "no skill: the first is free")
	lu.assertTrue(h:isReadyForTraining(pilot({ 2 }, 7500)), "one skill, 7500 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ 2 }, 7499)), "one skill, 7499 XP")
	lu.assertFalse(h:isReadyForTraining(pilot({ 1, 2, 3, 4 }, 99999)), "all four: nothing left")
	lu.assertFalse(h:isReadyForTraining(I.pilot({ paid = 3 })), "mission 4 not paid")
end

---------------------------------------------------------------------------------------------
-- The grant
---------------------------------------------------------------------------------------------

TestStormT1TrainingGrant = {}

TestStormT1TrainingGrant.setUp = setUp

-- AC-9: free first skill
for i, x in ipairs(TRAIN) do
	TestStormT1TrainingGrant["test_the_first_skill_" .. x.x .. "_is_granted_free_when_confirmed"] = function()
		local player = pilot({}, 0)
		local t = I.talk(player, { MENU, x.reply, I.CONFIRM })

		lu.assertEquals(I.ids(t), { "training_offer", "training_menu", x.desc, x.trained }, "screens shown")
		lu.assertEquals(t[4].text, I.PREFIX .. "s_7c8aca1b", "'Good choice. Report back when you are ready for an assignment.'")
		lu.assertTrue(t[4].stop, x.trained .. " ends the conversation")
		lu.assertEquals(grantedFree(player), { x.skill }, "awardSkill calls")
		lu.assertEquals(grantedBought(player), {}, "XP-deducting grants")
		lu.assertEquals(I.held(player), { x.skill }, "skills held")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-9: no grant on the topic or the description, only on the confirm
function TestStormT1TrainingGrant:test_nothing_is_granted_before_the_confirm()
	local player = pilot({}, 0)

	I.talk(player, { MENU, "s_5e3cf461" })
	noGrant(player, "topic chosen, not confirmed")
	I.drive(player, "trained_starships")
	noGrant(player, "trained_starships displayed alone")
end

-- AC-9: bought skills (1 to 3 held, 7500 XP)
for _, have in ipairs({ { 1 }, { 2, 3 }, { 1, 3, 4 } }) do
	for _, i in ipairs(missing(have)) do
		local x = TRAIN[i]

		TestStormT1TrainingGrant["test_holding_" .. table.concat(have, "_") .. "_the_pilot_buys_" .. x.x .. "_with_7500_xp"] = function()
			I.useSkillCosts()

			local player = pilot(have, 20000)
			local t = I.talk(player, { MENU, x.reply, I.CONFIRM })

			lu.assertEquals(I.ids(t), { "training_offer", "training_menu", x.desc, x.trained }, "screens shown")
			lu.assertEquals(grantedBought(player), { x.skill }, "skillManagerAwardSkill calls")
			lu.assertEquals(grantedFree(player), {}, "free grants")
			lu.assertEquals(exp(player), 12500, "space XP after the purchase")
			lu.assertTrue(CreatureObject(player):hasSkill(x.skill), "the skill is held")
		end
	end
end

-- AC-9: the fourth skill raises the pilot tier 1 to 2, and only then
function TestStormT1TrainingGrant:test_the_fourth_skill_raises_the_pilot_tier_from_1_to_2()
	I.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500)

	lu.assertEquals(player.ghost.pilotTier, 1, "precondition: pilot tier 1")
	I.talk(player, { MENU, "s_a57e647c", I.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the fourth skill")
	lu.assertEquals(I.firstScreen(player), "tier_done", "the next visit opens tier_done")
end

-- AC-9
function TestStormT1TrainingGrant:test_the_third_skill_does_not_raise_the_pilot_tier()
	I.useSkillCosts()

	local player = pilot({ 1, 2 }, 7500)

	I.talk(player, { MENU, "s_40f3848e", I.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 1, "pilot tier after the third skill")
end

-- AC-9: a pilot already at tier 2 keeps it
function TestStormT1TrainingGrant:test_a_pilot_at_tier_2_is_not_raised_again()
	I.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500, { pilotTier = 2 })

	I.talk(player, { MENU, "s_a57e647c", I.CONFIRM })
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier")
end

-- AC-9: one skill per visit
function TestStormT1TrainingGrant:test_one_confirm_grants_one_skill_and_ends_the_conversation()
	I.useSkillCosts()

	local player = pilot({ 1 }, 99999)
	local t = I.talk(player, { MENU, "s_577aca95", I.CONFIRM, MENU })

	lu.assertEquals(#t, 4, "the conversation ends at trained_weapons")
	lu.assertEquals(grantedBought(player), { TRAIN[2].skill }, "exactly one skill bought")
	lu.assertEquals(exp(player), 99999 - 7500, "one price paid")
end

-- AC-9: the skills can be taken in any order, free first then bought
function TestStormT1TrainingGrant:test_the_four_skills_can_be_trained_in_a_reversed_order_over_four_visits()
	I.useSkillCosts()

	local player = pilot({}, 7500 * 3)

	for step, i in ipairs({ 4, 3, 2, 1 }) do
		local t = I.talk(player, { MENU, TRAIN[i].reply, I.CONFIRM })

		lu.assertEquals(t[#t].id, TRAIN[i].trained, "visit " .. step .. ": last screen")
	end

	lu.assertEquals(grantedFree(player), { TRAIN[4].skill }, "the first skill is the free one")
	lu.assertEquals(grantedBought(player), { TRAIN[3].skill, TRAIN[2].skill, TRAIN[1].skill }, "the other three are bought")
	lu.assertEquals(exp(player), 0, "three prices paid")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier after the fourth skill")
end

-- AC-9: with 1 to 3 skills and too little XP the pilot is not offered training
function TestStormT1TrainingGrant:test_with_too_little_xp_the_first_screen_is_duty_missions()
	for _, have in ipairs(subsets()) do
		H.reset()
		lu.assertEquals(I.firstScreen(pilot(have, 7499)), "duty_missions", "holding " .. table.concat(have, ",") .. " with 7499 XP")
	end
end

---------------------------------------------------------------------------------------------
-- Guards that fail while the menu is shown (hooks)
---------------------------------------------------------------------------------------------

TestStormT1TrainingGuards = {}

TestStormT1TrainingGuards.setUp = setUp

-- AC-9
function TestStormT1TrainingGuards:test_xp_that_is_gone_before_the_confirm_buys_nothing_and_the_gates_route_the_pilot()
	I.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = I.talk(player, { MENU, "s_577aca95", function(p) p.ghost.experience.space_combat_general = 0 end, I.CONFIRM })

	lu.assertEquals(t[#t].id, "duty_missions", "routed by the gates: one skill, no XP")
	noGrant(player, "xp gone")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
end

-- AC-9
function TestStormT1TrainingGuards:test_a_skill_the_pilot_got_meanwhile_is_not_granted_again()
	I.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = I.talk(player, { MENU, "s_577aca95", function(p) p.skills[TRAIN[2].skill] = true end, I.CONFIRM })

	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates: two skills and 7500 XP")
	noGrant(player, "skill already held")
end

-- AC-9: the free grant needs "no tier 1 skill" at the confirm
function TestStormT1TrainingGuards:test_the_free_grant_is_refused_once_the_pilot_holds_a_tier_1_skill_and_has_no_xp()
	I.useSkillCosts()

	local player = pilot({}, 0)
	local t = I.talk(player, { MENU, "s_5e3cf461", function(p) p.skills[TRAIN[2].skill] = true end, I.CONFIRM })

	lu.assertEquals(t[#t].id, "duty_missions", "routed by the gates: one skill, no XP")
	noGrant(player, "free grant after a skill appeared")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[1].skill), "the topic's skill is not held")
end

-- AC-9
function TestStormT1TrainingGuards:test_all_four_skills_gained_meanwhile_route_the_pilot_to_tier_done_without_a_grant()
	local player = pilot({}, 0)
	local t = I.talk(player, { MENU, "s_5e3cf461", function(p)
		for _, x in ipairs(TRAIN) do
			p.skills[x.skill] = true
		end
	end, I.CONFIRM })

	lu.assertEquals(t[#t].id, "tier_done", "routed by the gates")
	noGrant(player, "tier already complete")
end

-- AC-9: the confirm needs the mission 4 reward
function TestStormT1TrainingGuards:test_a_confirm_without_the_mission_4_reward_grants_nothing()
	local player = I.pilot({ paid = 3 })
	local t = I.drive(player, "train_starships", { I.CONFIRM })

	lu.assertEquals(t[#t].id, "mission4_offer", "routed by the gates: missions 1 to 3 paid")
	noGrant(player, "mission 4 unpaid")
end

-- AC-9
function TestStormT1TrainingGuards:test_the_mission_4_reward_taken_away_meanwhile_grants_nothing()
	local player = pilot({}, 0)
	local t = I.talk(player, { MENU, "s_5e3cf461", function(p) removeQuestStatus(p.objectID .. "tatooine_imperial_4:reward") end, I.CONFIRM })

	lu.assertEquals(t[#t].id, "mission4_won", "routed by the gates: mission 4 won and unpaid")
	noGrant(player, "reward key gone")
end

-- AC-9: a confirm from a pilot who already has the skill
function TestStormT1TrainingGuards:test_a_confirm_for_a_skill_already_held_grants_nothing()
	I.useSkillCosts()

	local player = pilot({ 1 }, 7500)
	local t = I.drive(player, "train_starships", { I.CONFIRM })

	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates")
	noGrant(player, "skill held")
end

-- AC-9: the XP-deducting grant is refused by the engine when the prerequisites are not met
function TestStormT1TrainingGuards:test_when_the_engine_refuses_the_purchase_the_pilot_gets_no_trained_screen()
	local real = LuaSkillManager

	LuaSkillManager = function()
		return { fulfillsSkillPrerequisitesAndXp = function() return false end, awardSkill = real().awardSkill }
	end

	local player = pilot({ 1 }, 7500)
	local t = I.talk(player, { MENU, "s_577aca95", I.CONFIRM })

	LuaSkillManager = real
	lu.assertEquals(t[#t].id, "training_offer", "routed by the gates")
	lu.assertFalse(CreatureObject(player):hasSkill(TRAIN[2].skill), "the skill is not held")
	lu.assertEquals(grantedBought(player), {}, "no purchase attempted")
end

---------------------------------------------------------------------------------------------
-- AC-10: tier done, promotion, the Authorization of Transfer, hand-off to Commander Oberhaur
---------------------------------------------------------------------------------------------

TestStormT1HandOff = {}

TestStormT1HandOff.setUp = setUp

local function graduate(o)
	local opts = { paid = 4, tier = 4, pilotTier = 2 }

	for k, v in pairs(o or {}) do
		opts[k] = v
	end

	return I.pilot(opts)
end

local ROUTES = {
	{ name = "promotion", choices = { "s_3f6a8711", "s_304d169e", "s_565cc8ba", "s_de76730a" }, ids = { "tier_done", "promotion", "promotion_honored", "promotion_serve", "new_assignment" }, flagFrom = 2 },
	{ name = "handler", choices = { "s_31967d85", "s_b8ca7ab0", "s_9bcd2229" }, ids = { "tier_done", "promotion_handler", "promotion_reassigned", "new_assignment" }, flagFrom = 3 },
	{ name = "overdue", choices = { "s_24890a54", "s_c0c8fe59", "s_83fc71cf" }, ids = { "tier_done", "promotion_overdue", "promotion_killed", "new_assignment" }, flagFrom = 2 },
}

local TO_END = { "s_15a6458f", "s_163d48b6", "s_5c5b19e2" }
local END_IDS = { "oberhaur_info", "oberhaur_good_luck", "dismissed" }

-- the Authorization of Transfer items the pilot's inventory holds
local function formsHeld(player)
	local n = 0

	for _, item in ipairs(player.inventory and player.inventory.items or {}) do
		if item.template == I.TRANSFER_FORM or item == I.TRANSFER_FORM then
			n = n + 1
		end
	end

	return n
end

for _, r in ipairs(ROUTES) do
	-- AC-10: each route sets the series flag and hands out one form on the way to dismissed
	TestStormT1HandOff["test_the_" .. r.name .. "_route_sets_the_series_flag_gives_one_form_and_ends_at_dismissed"] = function()
		local player = graduate()

		I.talk(player, {})
		lu.assertNil(H.getQuestStatus(player, I.SERIES_SUFFIX), "tier_done alone does not set the flag")

		local t = I.talk(player, concat(r.choices, TO_END))

		lu.assertEquals(I.ids(t), concat(r.ids, END_IDS), "screens shown")
		lu.assertTrue(t[#t].stop, "dismissed ends")
		lu.assertEquals(H.getQuestStatus(player, I.SERIES_SUFFIX), "1", "series flag")
		lu.assertEquals(I.forms(player), 1, "giveItem calls for the Authorization of Transfer")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end

	-- AC-10: the flag is set on the promotion screen of the route, not before
	TestStormT1HandOff["test_the_" .. r.name .. "_route_sets_the_flag_exactly_on_its_promotion_screen"] = function()
		local screens = r.ids

		for upTo = 1, r.flagFrom - 1 do
			H.reset()

			local player = graduate()

			I.talk(player, { table.unpack(r.choices, 1, upTo - 1) })
			lu.assertNil(H.getQuestStatus(player, I.SERIES_SUFFIX), "no flag when the talk ends on '" .. screens[upTo] .. "'")
		end

		H.reset()

		local player = graduate()

		I.talk(player, { table.unpack(r.choices, 1, r.flagFrom - 1) })
		lu.assertEquals(H.getQuestStatus(player, I.SERIES_SUFFIX), "1", "flag once '" .. screens[r.flagFrom] .. "' is shown")
	end

	-- AC-10: the form comes with oberhaur_info and not before
	TestStormT1HandOff["test_the_" .. r.name .. "_route_gives_the_form_only_on_oberhaur_info"] = function()
		local player = graduate()

		I.talk(player, concat(r.choices, {}))
		lu.assertEquals(I.forms(player), 0, "no form on the way to new_assignment")
		lu.assertEquals(formsHeld(player), 0, "inventory")
	end
end

-- AC-10: the form lands in the inventory even when it is full (J createObjectOverloaded has no capacity check)
function TestStormT1HandOff:test_oberhaur_info_gives_the_form_also_to_a_full_inventory()
	local player = graduate({ inventoryFull = true })

	I.talk(player, concat(ROUTES[1].choices, { "s_15a6458f" }))
	lu.assertEquals(#player.inventory.items, 1, "the form lands in the full inventory")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing is destroyed")
	lu.assertEquals(I.forms(player), 1, "giveItem calls")
end

-- AC-10: no inventory object at all gives nothing and raises nothing
function TestStormT1HandOff:test_a_pilot_without_an_inventory_object_gets_no_form_and_no_error()
	local player = graduate({ inventory = false })
	local ok, err = pcall(I.drive, player, "oberhaur_info")

	lu.assertTrue(ok, "oberhaur_info raised: " .. tostring(err))
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "giveItem calls")
end

-- AC-10: the form is a plain item of the right template, nothing else is given with it
function TestStormT1HandOff:test_oberhaur_info_gives_only_the_transfer_form()
	local player = graduate()

	I.drive(player, "oberhaur_info")

	local given = {}

	for _, call in ipairs(H.Engine.callsTo("giveItem")) do
		given[#given + 1] = call[2]
	end

	lu.assertEquals(given, { I.TRANSFER_FORM }, "templates given")
end

-- AC-10: the promotion and Oberhaur screens give no skill, credits or standing
function TestStormT1HandOff:test_the_promotion_walk_grants_no_skill_credits_or_standing()
	local player = graduate()

	I.talk(player, concat(ROUTES[1].choices, TO_END))
	lu.assertEquals(#I.free() + #I.bought(), 0, "no skill granted")
	lu.assertEquals(player.bankCredits or 0, 0, "bank credits")
	lu.assertEquals(player.ghost.factionStanding.imperial, 0, "standing")
	lu.assertEquals(player.ghost.pilotTier, 2, "pilot tier is the training's business")
end

-- AC-10 (FI-1): after the promotion the next talk opens series_complete
function TestStormT1HandOff:test_every_talk_after_the_promotion_opens_series_complete()
	local player = graduate()

	I.talk(player, { "s_3f6a8711", "s_304d169e" })

	for visit = 1, 3 do
		local t = I.talk(player)

		lu.assertEquals(t[1].id, "series_complete", "visit " .. visit .. " after the promotion")
		lu.assertEquals(t[1].text, I.PREFIX .. "s_2e935a2c", "J's graduate line")
		lu.assertEquals(I.optionSids(t[1]), { "s_88241861", "s_2d5d4bf0", "s_943c7ba6" }, "replies")
		lu.assertEquals(I.linksOf(t[1]), { "form_reissued", "duty_menu", "series_no_training" }, "links with room in the inventory")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
	end
end

-- AC-10
function TestStormT1HandOff:test_series_complete_reissues_one_more_form_when_there_is_room()
	local player = graduate({ series = true })
	local t = I.talk(player, { "s_88241861", "s_987445c9" })

	lu.assertEquals(I.ids(t), { "series_complete", "form_reissued", "form_good_luck" }, "screens shown")
	lu.assertTrue(t[3].stop, "form_good_luck ends")
	lu.assertEquals(I.forms(player), 1, "one more form")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: no check for a held form (J): a second request gives a second form
function TestStormT1HandOff:test_every_request_gives_another_form()
	local player = graduate({ series = true })

	I.talk(player, { "s_88241861" })
	I.talk(player, { "s_88241861" })
	lu.assertEquals(I.forms(player), 2, "two requests, two forms")
end

-- AC-10: the form is given on display of form_reissued
function TestStormT1HandOff:test_form_reissued_gives_the_form_on_display()
	local player = graduate({ series = true })

	I.drive(player, "form_reissued")
	lu.assertEquals(I.forms(player), 1, "giveItem calls")
end

-- AC-10: a full inventory gets the refusal screen and no form
function TestStormT1HandOff:test_series_complete_refuses_the_form_when_the_inventory_is_full()
	local player = graduate({ series = true, inventoryFull = true })
	local t = I.talk(player, { "s_88241861" })

	lu.assertEquals(I.ids(t), { "series_complete", "form_inventory_full" }, "screens shown")
	lu.assertTrue(t[2].stop, "form_inventory_full ends")
	lu.assertEquals(I.forms(player), 0, "no form")
	lu.assertEquals(#(player.inventory.destroyed or {}), 0, "nothing destroyed")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings")
end

-- AC-10: "room" is the container's own rule: a limit that is not reached is room, a reached one is not
function TestStormT1HandOff:test_room_follows_the_container_limit()
	local roomy = graduate({ series = true, inventory = { limit = 5 } })
	local full = graduate({ series = true, inventory = { limit = 1 } })

	full.inventory.items[1] = { template = "something" }
	lu.assertEquals(I.ids(I.talk(roomy, { "s_88241861" })), { "series_complete", "form_reissued" }, "limit 5, empty")
	lu.assertEquals(I.ids(I.talk(full, { "s_88241861" })), { "series_complete", "form_inventory_full" }, "limit 1, one item")
end

-- AC-10: no inventory object counts as no room
function TestStormT1HandOff:test_a_pilot_without_an_inventory_object_is_told_the_inventory_is_full()
	local player = graduate({ series = true, inventory = false })

	lu.assertEquals(I.ids(I.talk(player, { "s_88241861" })), { "series_complete", "form_inventory_full" }, "screens shown")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "giveItem calls")
end

-- AC-10: the helpers the spec names
function TestStormT1HandOff:test_the_helpers_hasInventorySpace_and_giveTransferForm_follow_the_rule()
	local h = rawget(_G, I.HANDLER)

	lu.assertTrue(h:hasInventorySpace(graduate()), "an inventory with room")
	lu.assertFalse(h:hasInventorySpace(graduate({ inventoryFull = true })), "a full inventory")
	lu.assertFalse(h:hasInventorySpace(graduate({ inventory = false })), "no inventory")

	local player = graduate({ inventoryFull = true })

	h:giveTransferForm(player)
	lu.assertEquals(#player.inventory.items, 1, "giveTransferForm overflows a full inventory")
	lu.assertEquals(I.forms(player), 1, "giveItem calls")
	lu.assertEquals(pcall(h.giveTransferForm, h, graduate({ inventory = false })), true, "no inventory: no error")
end

-- AC-10
function TestStormT1HandOff:test_series_complete_leads_to_the_duty_menu_and_a_duty()
	local player = graduate({ series = true })
	local spy = H.spyOn(I.quest(I.DUTY6), "startQuest")
	local t = I.talk(player, { "s_2d5d4bf0", "s_259013cd", "s_a490d2c6" })

	lu.assertEquals(I.ids(t), { "series_complete", "duty_menu", "destroy_duty", "duty_accepted" }, "screens shown")
	lu.assertEquals(#spy, 1, "destroy duty started")
end

-- AC-10
function TestStormT1HandOff:test_series_no_training_ends()
	local t = I.talk(graduate({ series = true }), { "s_943c7ba6" })

	lu.assertEquals(I.ids(t), { "series_complete", "series_no_training" }, "screens shown")
	lu.assertTrue(t[2].stop, "series_no_training ends")
end

-- AC-10: the series key and the form template are the public constants of the squadron object
function TestStormT1HandOff:test_the_series_flag_is_stored_under_the_squadron_constant()
	local player = graduate()

	I.talk(player, { "s_3f6a8711", "s_304d169e" })
	lu.assertEquals(getQuestStatus(player.objectID .. StormSquadronScreenplay.SERIES_COMPLETE_KEY), "1", "series key")
	lu.assertEquals(StormSquadronScreenplay.TRANSFER_FORM, I.TRANSFER_FORM, "the form template constant")
end

-- AC-10: the whole career from the fourth skill
function TestStormT1HandOff:test_the_fourth_skill_leads_to_tier_done_then_the_promotion_then_series_complete()
	I.useSkillCosts()

	local player = pilot({ 1, 2, 3 }, 7500)

	I.talk(player, { MENU, "s_a57e647c", I.CONFIRM })
	lu.assertEquals(I.firstScreen(player), "tier_done", "after the fourth skill")
	I.talk(player, { "s_3f6a8711", "s_304d169e" })
	lu.assertEquals(I.firstScreen(player), "series_complete", "after the promotion")
end
