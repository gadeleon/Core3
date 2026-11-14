-- Tatooine station palace access: the station conversation (the Valarian offer, the Jabba's Palace landing, "Do you have any work for me?") and the
-- station helpers (isOfferEligible, isHuttWorkEligible, startBounty, startHuttDuty).
-- Spec: .claude/work/tatooine-station-palace-access/01-spec.md (AC-7, AC-8, AC-13; Conversation flow A, B, B2, C; Appendix A; Content contract C-3, C-4; I-6, I-7; D-12, D-16, D-19, D-21, D-23).
--
-- The station pairings are RECONSTRUCTED from the client's station_tatooine.stf (D-20), so the tests pin the spec's table, not any SWG script.
-- I-7: the 29 pre-feature screens are compared with fixtures/baseline/spacestation_tatooine.pre-palace.lua, a byte copy of the file at commit 6364c03585 (the
-- last commit before this feature that touched it).

local lu = require("luaunit")
local H = require("harness")
local DR = require("duty_rules_scenario")
local P = require("tatooine_palace_data")

P.load()

local G = P.GLOBALS
local SN = "spacestation_tatooine_"

local function sp() return P.screenplay() end

local function sid(s) return P.ST .. s end

local function sorted(list)
	local out = {}

	for i, v in ipairs(list) do
		out[i] = v
	end

	table.sort(out)
	return out
end

local function sids(screen)
	local out = {}

	for i, o in ipairs(screen.options) do
		out[i] = o.text:gsub("^" .. P.ST:gsub("%p", "%%%0"), "")
	end

	return out
end

local function landEvents(player)
	local out = {}

	for _, c in ipairs(H.Engine.callsTo("createEvent")) do
		if c[3] == "landShip" then
			out[#out + 1] = { delay = c[1], screenplay = c[2], method = c[3], player = c[4], destination = c[5] }
		end
	end

	return out
end

local function baselineTemplate()
	local env = setmetatable({ addConversationTemplate = function() end }, { __index = _G })
	local chunk, err = loadfile(H.FIXTURES .. "baseline/spacestation_tatooine.pre-palace.lua", "t", env)

	assert(chunk, err)
	chunk()
	return env.spacestation_tatooine_convotemplate
end

---------------------------------------------------------------------------------------------
-- The template (I-6, I-7, Appendix A)
---------------------------------------------------------------------------------------------

TestPalaceStationTemplate = {}

function TestPalaceStationTemplate:setUp()
	H.reset()
	P.requireStation(lu)
end

-- I-6
function TestPalaceStationTemplate:test_the_station_template_has_no_dead_links()
	lu.assertEquals(H.conversationProblems(P.STATION_TEMPLATE), {})
end

-- C-3: template id, initial screen and handler class are unchanged
function TestPalaceStationTemplate:test_the_template_keeps_its_id_initial_screen_and_handler()
	local t = H.conversationTemplateTable(P.STATION_TEMPLATE)

	lu.assertEquals(t.initialScreen, "spacestation_tatooine_greeting", "initialScreen")
	lu.assertEquals(t.templateType, "Lua", "templateType")
	lu.assertEquals(t.luaClassHandler, P.STATION_HANDLER, "luaClassHandler")
end

-- C-3, Appendix A: 29 old screens plus the 15 new ones
function TestPalaceStationTemplate:test_the_template_has_the_29_old_and_the_15_new_screens()
	local want = {}

	for _, s in ipairs(baselineTemplate().screens) do
		want[#want + 1] = s.id
	end

	lu.assertEquals(#want, 29, "the baseline has 29 screens")

	for _, r in ipairs(P.STATION_SCREENS) do
		want[#want + 1] = r.id
	end

	local got = {}

	for _, s in ipairs(H.conversationTemplateTable(P.STATION_TEMPLATE).screens) do
		got[#got + 1] = s.id
	end

	lu.assertEquals(#P.STATION_SCREENS, 15, "the spec table has 15 rows")
	lu.assertEquals(sorted(got), sorted(want), "screen ids")
end

-- I-7
function TestPalaceStationTemplate:test_the_29_old_screens_are_identical_to_the_baseline()
	local live = {}

	for _, s in ipairs(H.conversationTemplateTable(P.STATION_TEMPLATE).screens) do
		live[s.id] = s
	end

	for _, old in ipairs(baselineTemplate().screens) do
		lu.assertNotNil(live[old.id], old.id .. ": still in the template")
		lu.assertEquals(live[old.id], old, old.id .. ": identical to the pre-feature screen")
	end
end

-- Appendix A
function TestPalaceStationTemplate:test_every_new_screen_has_its_dialog_stop_flag_and_static_options()
	local live = {}

	for _, s in ipairs(H.conversationTemplateTable(P.STATION_TEMPLATE).screens) do
		live[s.id] = s
	end

	for _, r in ipairs(P.STATION_SCREENS) do
		local screen = live[r.id]

		lu.assertNotNil(screen, r.id .. ": screen exists")
		lu.assertEquals(screen.leftDialog, sid(r.sid), r.id .. ": leftDialog")
		lu.assertEquals(tostring(screen.stopConversation), tostring(r.stop), r.id .. ": stopConversation")

		local opts, want = {}, {}

		for i, o in ipairs(screen.options) do
			opts[i] = { o[1], o[2] }
		end

		for i, o in ipairs(r.options) do
			want[i] = { sid(o[1]), o[2] }
		end

		lu.assertEquals(opts, want, r.id .. ": static options")
	end
end

-- D-12 / I-7: the handler-added options are not static
function TestPalaceStationTemplate:test_the_handler_added_options_are_not_in_the_static_screens()
	local live = {}

	for _, s in ipairs(H.conversationTemplateTable(P.STATION_TEMPLATE).screens) do
		live[s.id] = s
	end

	for _, added in ipairs({ { SN .. "greeting", "s_4360fc64" }, { SN .. "land", "s_ce4621b5" }, { SN .. "greeting_valarian", "s_96bea28d" } }) do
		for _, o in ipairs(live[added[1]].options) do
			lu.assertNotEquals(o[1], sid(added[2]), added[1] .. ": " .. added[2] .. " is added by the handler, not by the template")
		end
	end
end

-- I-7: running conversations leaves the static screens as they were (the handler clones before adding)
function TestPalaceStationTemplate:test_talking_to_the_station_does_not_change_the_static_screens()
	local smuggler = P.pilot({ cash = 1000000, damage = 5000 })

	P.grantAccess(smuggler)
	P.talkStation(smuggler, { "s_5984746e", "s_ce4621b5" })
	P.talkStation(P.pilot({ cash = 1000000, damage = 5000 }), { "s_f2b8a1d8" })

	local live = {}

	for _, s in ipairs(H.conversationTemplateTable(P.STATION_TEMPLATE).screens) do
		live[s.id] = s
	end

	for _, old in ipairs(baselineTemplate().screens) do
		lu.assertEquals(live[old.id], old, old.id .. ": identical to the pre-feature screen after conversations")
	end
end

---------------------------------------------------------------------------------------------
-- Eligibility (C-1, C-2)
---------------------------------------------------------------------------------------------

TestPalaceStationEligibility = {}

function TestPalaceStationEligibility:setUp()
	H.reset()
	P.requireStation(lu)
end

-- AC-7 (C-1, D-16)
function TestPalaceStationEligibility:test_a_smuggler_with_no_access_and_no_chain_is_offered_the_bounty_at_any_tier()
	for _, tier in ipairs({ 0, 1, 2, 3, 4 }) do
		lu.assertTrue(sp():isOfferEligible(P.pilot({ tier = tier })), "tier " .. tier .. ": isOfferEligible")
	end
end

-- AC-7 (D-16)
function TestPalaceStationEligibility:test_pilots_who_are_not_smugglers_are_not_offered_the_bounty()
	for _, kind in ipairs({ "corsec", "rsf", "imperial", "rebel", "none" }) do
		lu.assertFalse(sp():isOfferEligible(P.pilot({ kind = kind })), kind .. ": isOfferEligible")
	end
end

-- AC-7 (D-19)
function TestPalaceStationEligibility:test_a_smuggler_with_palace_access_is_not_offered_the_bounty()
	local player = P.pilot({})

	P.grantAccess(player)
	lu.assertFalse(sp():isOfferEligible(player), "isOfferEligible with access")
end

-- AC-7 (C-1): any of the four chain quests active
function TestPalaceStationEligibility:test_a_smuggler_with_a_chain_quest_active_is_not_offered_the_bounty()
	for i = 1, 4 do
		local player = P.pilot({})

		P.setState(player, G[i], "active")
		lu.assertFalse(sp():isOfferEligible(player), "quest " .. i .. " active: isOfferEligible")
	end
end

-- AC-7 (D-19): the chain can be re-flown until the pilot has access
function TestPalaceStationEligibility:test_a_smuggler_who_finished_or_failed_the_chain_without_access_is_offered_the_bounty_again()
	for i = 1, 4 do
		local player = P.pilot({})

		P.setState(player, G[i], "complete")
		lu.assertTrue(sp():isOfferEligible(player), "quest " .. i .. " complete, no access: isOfferEligible")
	end
end

-- AC-7
function TestPalaceStationEligibility:test_a_missing_player_is_not_eligible()
	lu.assertFalse(sp():isOfferEligible(nil), "isOfferEligible(nil)")
	lu.assertFalse(sp():isHuttWorkEligible(nil), "isHuttWorkEligible(nil)")
end

-- AC-13 (C-2, D-21)
function TestPalaceStationEligibility:test_only_smuggler_squadron_pilots_are_offered_the_hutt_work_at_any_tier()
	for _, tier in ipairs({ 0, 1, 2, 3, 4 }) do
		lu.assertTrue(sp():isHuttWorkEligible(P.pilot({ tier = tier })), "smuggler tier " .. tier .. ": isHuttWorkEligible")
	end

	for _, kind in ipairs({ "corsec", "rsf", "imperial", "rebel", "none" }) do
		lu.assertFalse(sp():isHuttWorkEligible(P.pilot({ kind = kind })), kind .. ": isHuttWorkEligible")
	end
end

-- AC-13: neither the chain nor the access changes who gets the work
function TestPalaceStationEligibility:test_hutt_work_does_not_depend_on_the_chain_or_the_access()
	local withAccess = P.pilot({})
	local withChain = P.pilot({})

	P.grantAccess(withAccess)
	P.setState(withChain, G[2], "active")
	lu.assertTrue(sp():isHuttWorkEligible(withAccess), "with access")
	lu.assertTrue(sp():isHuttWorkEligible(withChain), "with the chain active")
end

---------------------------------------------------------------------------------------------
-- The Valarian offer (AC-7)
---------------------------------------------------------------------------------------------

TestPalaceStationOffer = {}

function TestPalaceStationOffer:setUp()
	H.reset()
	P.requireStation(lu)
end

-- AC-7
function TestPalaceStationOffer:test_an_eligible_pilot_in_range_gets_the_valarian_greeting_with_its_two_options()
	local screens = P.talkStation(P.pilot({}))

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian" }, "first screen")
	lu.assertEquals(screens[1].text, sid("s_e2190b5d"), "the greeting line")
	lu.assertEquals(screens[1].stop, false, "the greeting does not stop")
	lu.assertEquals(P.optionSet(screens[1], P.ST), { "s_375a3c20 -> " .. SN .. "land", "s_f2b8a1d8 -> " .. SN .. "valarian_offer" }, "options of an undamaged ship")
end

-- AC-7 (C-4): the repair option under the same credit condition as the default greeting
function TestPalaceStationOffer:test_the_valarian_greeting_adds_the_repair_option_when_the_pilot_can_pay()
	local damaged = P.talkStation(P.pilot({ cash = 1000000, damage = 5000 }))[1]
	local broke = P.talkStation(P.pilot({ cash = 0, damage = 5000 }))[1]

	lu.assertEquals(P.optionSet(damaged, P.ST), { "s_375a3c20 -> " .. SN .. "land", "s_96bea28d -> " .. SN .. "repair", "s_f2b8a1d8 -> " .. SN .. "valarian_offer" }, "damaged ship, cash")
	lu.assertEquals(P.optionSet(broke, P.ST), { "s_375a3c20 -> " .. SN .. "land", "s_f2b8a1d8 -> " .. SN .. "valarian_offer" }, "damaged ship, no money")
end

-- AC-7: the repair detour reaches the existing repair screen
function TestPalaceStationOffer:test_the_valarian_greeting_repair_option_leads_to_the_existing_repair_screen()
	local screens = P.talkStation(P.pilot({ cash = 1000000, damage = 5000 }), { "s_96bea28d" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian", SN .. "repair" }, "screens")
	lu.assertEquals(screens[2].text, sid("s_35221afe"), "the repair line")
end

-- AC-7: "I just want to land on Tatooine." leads to the landing menu
function TestPalaceStationOffer:test_the_valarian_greeting_land_option_leads_to_the_landing_menu()
	local screens = P.talkStation(P.pilot({}), { "s_375a3c20" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian", SN .. "land" }, "screens")
	lu.assertEquals(screens[2].text, sid("s_83bace61"), "the landing line")
end

-- AC-7
function TestPalaceStationOffer:test_the_accept_path_ends_on_valarian_accepted_with_quest_1_active()
	local player = P.pilot({})
	local screens = P.talkStation(player, { "s_f2b8a1d8", "s_52917b0d", "s_dd4bb16d" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian", SN .. "valarian_offer", SN .. "valarian_warning", SN .. "valarian_accepted" }, "screens")
	lu.assertEquals({ screens[2].text, screens[3].text, screens[4].text }, { sid("s_462a718b"), sid("s_3cbb3f38"), sid("s_12b89c7f") }, "the offer, the warning and the good luck lines")
	lu.assertEquals(screens[4].stop, true, "valarian_accepted ends the conversation")
	lu.assertEquals(P.state(player, G[1]), "active", "quest 1 is active")

	for i = 2, 4 do
		lu.assertEquals(P.state(player, G[i]), "none", "quest " .. i .. " has not started yet")
	end
end

-- AC-7 (C-4): the handler starts quest 1 exactly once, for this pilot and this NPC
function TestPalaceStationOffer:test_accepting_calls_start_quest_on_quest_1_once()
	local player = P.pilot({})
	local spy = H.spyOn(P.quest(G[1]), "startQuest")
	local npc = H.newNpc { name = "Tatooine Station" }

	H.converse { template = P.STATION_TEMPLATE, player = player, npc = npc, choices = { "s_f2b8a1d8", "s_52917b0d", "s_dd4bb16d" } }
	lu.assertEquals(#spy, 1, "startQuest calls on quest 1")
	lu.assertEquals(spy[1] and spy[1].args[1], player, "for the pilot")
end

-- AC-7: the accept screen shown twice does not start the quest twice
function TestPalaceStationOffer:test_startBounty_refuses_while_a_chain_quest_is_active()
	local player = P.pilot({})
	local npc = H.newNpc { name = "Tatooine Station" }

	lu.assertTrue(sp():startBounty(player, npc), "the first start")
	lu.assertEquals(P.state(player, G[1]), "active", "quest 1 is active")
	lu.assertFalse(sp():startBounty(player, npc), "a second start while the chain is active is refused")
	lu.assertEquals(P.state(player, G[1]), "active", "quest 1 is still active")
end

-- AC-7 (D-19): a finished or failed chain without access can be flown again
function TestPalaceStationOffer:test_a_finished_chain_without_access_can_be_taken_again_and_starts_over()
	local player = P.pilot({})

	for i = 1, 4 do
		P.setState(player, G[i], "complete")
	end

	local screens = P.talkStation(player, { "s_f2b8a1d8", "s_52917b0d", "s_dd4bb16d" })

	lu.assertEquals(P.lastId(screens), SN .. "valarian_accepted", "ends on valarian_accepted")
	lu.assertEquals(P.state(player, G[1]), "active", "quest 1 is active again")

	for i = 2, 4 do
		lu.assertEquals(P.state(player, G[i]), "none", "quest " .. i .. " was cleared")
	end
end

-- AC-7
function TestPalaceStationOffer:test_declining_with_of_course_not_ends_on_valarian_declined_and_starts_nothing()
	local player = P.pilot({})
	local spy = H.spyOn(P.quest(G[1]), "startQuest")
	local screens = P.talkStation(player, { "s_f2b8a1d8", "s_cd0dcead" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian", SN .. "valarian_offer", SN .. "valarian_declined" }, "screens")
	lu.assertEquals(screens[3].text, sid("s_66b68768"), "the I thought so line")
	lu.assertEquals(screens[3].stop, true, "valarian_declined ends the conversation")
	lu.assertEquals(#spy, 0, "no quest started")
	lu.assertEquals(P.state(player, G[1]), "none", "quest 1 is not active")
end

-- AC-7
function TestPalaceStationOffer:test_backing_out_at_the_warning_ends_on_valarian_not_now_and_starts_nothing()
	local player = P.pilot({})
	local spy = H.spyOn(P.quest(G[1]), "startQuest")
	local screens = P.talkStation(player, { "s_f2b8a1d8", "s_52917b0d", "s_5964dabc" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting_valarian", SN .. "valarian_offer", SN .. "valarian_warning", SN .. "valarian_not_now" }, "screens")
	lu.assertEquals(screens[4].text, sid("s_39076454"), "the suit yourself line")
	lu.assertEquals(screens[4].stop, true, "valarian_not_now ends the conversation")
	lu.assertEquals(#spy, 0, "no quest started")
	lu.assertEquals(P.state(player, G[1]), "none", "quest 1 is not active")
end

-- AC-7: leaving the talk at the offer or the warning starts nothing either
function TestPalaceStationOffer:test_walking_away_before_accepting_starts_nothing()
	for _, choices in ipairs({ {}, { "s_f2b8a1d8" }, { "s_f2b8a1d8", "s_52917b0d" } }) do
		H.reset()

		local player = P.pilot({})

		P.talkStation(player, choices)
		lu.assertEquals(P.state(player, G[1]), "none", #choices .. " choices: quest 1 is not active")
	end
end

-- AC-7: everyone else gets the old greeting
function TestPalaceStationOffer:test_an_ineligible_pilot_gets_the_default_greeting()
	local cases = {}

	for _, kind in ipairs({ "corsec", "rsf", "imperial", "rebel", "none" }) do
		cases[#cases + 1] = { kind .. " pilot", P.pilot({ kind = kind }) }
	end

	local withAccess = P.pilot({})

	P.grantAccess(withAccess)
	cases[#cases + 1] = { "smuggler with palace access", withAccess }

	for i = 1, 4 do
		local mid = P.pilot({})

		P.setState(mid, G[i], "active")
		cases[#cases + 1] = { "smuggler with quest " .. i .. " active", mid }
	end

	for _, case in ipairs(cases) do
		local screens = P.talkStation(case[2])

		lu.assertEquals(P.ids(screens), { SN .. "greeting" }, case[1] .. ": first screen")
		lu.assertEquals(screens[1].text, sid("s_a9152d31"), case[1] .. ": the old greeting line")
	end
end

-- Out-of-range behavior is unchanged
function TestPalaceStationOffer:test_an_eligible_pilot_out_of_range_still_gets_the_too_far_message()
	local player = P.pilot({})

	player.rootParent.outOfRange = true

	local screens = P.talkStation(player)

	lu.assertEquals(P.ids(screens), { "out_of_range" }, "first screen")
	lu.assertEquals(screens[1].text, sid("s_a9ce7ad3"), "the too far line")
end

function TestPalaceStationOffer:test_a_pilot_on_the_ground_gets_no_screen()
	lu.assertEquals(P.talkStation(P.pilot({ ship = false })), {}, "screens of a pilot with no ship")
end

---------------------------------------------------------------------------------------------
-- The default greeting (AC-13: the work option; AC-8: nothing else changes)
---------------------------------------------------------------------------------------------

TestPalaceStationGreeting = {}

function TestPalaceStationGreeting:setUp()
	H.reset()
	P.requireStation(lu)
end

-- AC-13 (C-4): the work option comes after the existing options, repair included
function TestPalaceStationGreeting:test_the_default_greeting_lists_land_repair_and_work_in_that_order()
	local player = P.pilot({ kind = "imperial", cash = 1000000, damage = 5000 })
	local screen = P.talkStation(player)[1]

	lu.assertEquals(P.ids({ screen }), { SN .. "greeting" }, "first screen")
	lu.assertEquals(sids(screen), { "s_5984746e", "s_6c8ffad8", "s_4360fc64" }, "options: land, repair, work")
end

function TestPalaceStationGreeting:test_the_default_greeting_without_repair_money_lists_land_and_work()
	local screen = P.talkStation(P.pilot({ kind = "imperial", cash = 0, damage = 5000 }))[1]

	lu.assertEquals(sids(screen), { "s_5984746e", "s_4360fc64" }, "options: land, work")
end

-- AC-13: the work option leads to the Hutt pitch for Smugglers and to the refusal for everyone else
function TestPalaceStationGreeting:test_the_work_option_links_to_work_hutts_for_smugglers_and_work_refused_for_others()
	local smuggler = P.pilot({})

	P.grantAccess(smuggler)

	local others = {}

	for _, kind in ipairs({ "corsec", "rsf", "imperial", "rebel", "none" }) do
		others[#others + 1] = { kind, P.pilot({ kind = kind }) }
	end

	local function link(player)
		for _, o in ipairs(P.talkStation(player)[1].options) do
			if o.text == sid("s_4360fc64") then
				return o.link
			end
		end
	end

	lu.assertEquals(link(smuggler), SN .. "work_hutts", "smuggler with access")

	for _, o in ipairs(others) do
		lu.assertEquals(link(o[2]), SN .. "work_refused", o[1] .. ": link of s_4360fc64")
	end
end

-- AC-13: the Valarian greeting has no work option (D-23)
function TestPalaceStationGreeting:test_the_valarian_greeting_has_no_work_option()
	local screen = P.talkStation(P.pilot({}))[1]

	lu.assertEquals(screen.id, SN .. "greeting_valarian", "an eligible smuggler gets the Valarian greeting")

	for _, o in ipairs(screen.options) do
		lu.assertNotEquals(o.text, sid("s_4360fc64"), "s_4360fc64 is not offered on the Valarian greeting")
	end
end

-- AC-8 / old behavior: the repair screen still works from the default greeting
function TestPalaceStationGreeting:test_the_old_repair_option_still_leads_to_the_repair_screens()
	local player = P.pilot({ kind = "imperial", cash = 1000000, damage = 5000 })
	local screens = P.talkStation(player, { "s_6c8ffad8", "s_696719e4" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "repair", "repair_small" }, "screens")
end

---------------------------------------------------------------------------------------------
-- The palace landing (AC-8)
---------------------------------------------------------------------------------------------

TestPalaceStationLanding = {}

function TestPalaceStationLanding:setUp()
	H.reset()
	P.requireStation(lu)
end

local OLD_LANDINGS = {
	"s_43d2bcbe -> " .. SN .. "land_bestine", "s_75ba8830 -> " .. SN .. "land_espa", "s_69ffeefe -> " .. SN .. "land_entha", "s_ccbc6cf4 -> " .. SN .. "land_eisley",
}

local function landMenu(player)
	local screens = P.talkStation(player, { "s_5984746e" })

	lu.assertEquals(P.lastId(screens), SN .. "land", "reached the landing menu")
	return screens[#screens]
end

-- AC-8
function TestPalaceStationLanding:test_the_jabbas_palace_option_is_offered_iff_the_pilot_has_access()
	local without = P.pilot({ kind = "imperial" })
	local with = P.pilot({ kind = "imperial" })

	P.grantAccess(with)

	local want = sorted(OLD_LANDINGS)
	local wantWith = sorted({ OLD_LANDINGS[1], OLD_LANDINGS[2], OLD_LANDINGS[3], OLD_LANDINGS[4], "s_ce4621b5 -> " .. SN .. "land_jabba" })

	lu.assertEquals(P.optionSet(landMenu(without), P.ST), want, "landing menu without access")
	lu.assertEquals(P.optionSet(landMenu(with), P.ST), wantWith, "landing menu with access")
end

-- AC-8: the Jabba's Palace line and the way down
function TestPalaceStationLanding:test_choosing_jabbas_palace_shows_the_welcome_line_and_the_two_answers()
	local player = P.pilot({})

	P.grantAccess(player)

	local screens = P.talkStation(player, { "s_5984746e", "s_ce4621b5" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "land", SN .. "land_jabba" }, "screens before the answer (a Smuggler with access gets the default greeting)")
	lu.assertEquals(screens[3].text, sid("s_1d21e3c0"), "the welcome line")
	lu.assertEquals(screens[3].stop, false, "land_jabba does not stop")
	lu.assertEquals(P.optionSet(screens[3], P.ST), { "s_b9b27823 -> " .. SN .. "land_jabba_complete", "s_e1ef9209 -> " .. SN .. "land_jabba_abort" }, "options")
end

function TestPalaceStationLanding:test_the_landing_event_is_scheduled_once_for_jabbas_palace()
	local player = P.pilot({})

	P.grantAccess(player)

	local screens = P.talkStation(player, { "s_5984746e", "s_ce4621b5", "s_b9b27823" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "land", SN .. "land_jabba", SN .. "land_jabba_complete" }, "screens")
	lu.assertEquals(screens[4].text, sid("s_4650b19f"), "the watch your back line")
	lu.assertEquals(screens[4].stop, true, "land_jabba_complete ends the conversation")
	lu.assertEquals(landEvents(player), { { delay = 3500, screenplay = "SpaceStationScreenPlay", method = "landShip", player = player, destination = "jabbas_palace" } }, "landShip events")
end

-- AC-8
function TestPalaceStationLanding:test_changing_your_mind_schedules_no_landing()
	local player = P.pilot({})

	P.grantAccess(player)

	local screens = P.talkStation(player, { "s_5984746e", "s_ce4621b5", "s_e1ef9209" })

	lu.assertEquals(P.lastId(screens), SN .. "land_jabba_abort", "ends on land_jabba_abort")
	lu.assertEquals(screens[#screens].text, sid("s_b26eb03c"), "the good riddance line")
	lu.assertEquals(screens[#screens].stop, true, "land_jabba_abort ends the conversation")
	lu.assertEquals(landEvents(player), {}, "no landShip event")
end

-- AC-8 (C-4): the landing is scheduled only when the access is still there
function TestPalaceStationLanding:test_no_landing_is_scheduled_when_the_access_is_gone_by_the_last_screen()
	local player = P.pilot({})

	P.grantAccess(player)

	local screens = P.talkStation(player, { "s_5984746e", "s_ce4621b5", function(p) removeQuestStatus(p.objectID .. P.ACCESS_KEY) end, "s_b9b27823" })

	lu.assertEquals(P.lastId(screens), SN .. "land_jabba_complete", "the screens are still shown")
	lu.assertEquals(landEvents(player), {}, "no landShip event without access")
end

-- AC-8: the old landings and their timing are unchanged
function TestPalaceStationLanding:test_the_four_old_landings_still_schedule_their_events()
	local walks = {
		{ "bestine", { "s_43d2bcbe", "s_c4682ea6" } },
		{ "eisley", { "s_ccbc6cf4", "s_b9b27823" } },
		{ "espa", { "s_75ba8830", "s_895d093" } },
		{ "entha", { "s_69ffeefe", "s_895d093" } },
	}

	for _, w in ipairs(walks) do
		H.reset()

		local player = P.pilot({ kind = "imperial" })

		P.grantAccess(player)
		P.talkStation(player, { "s_5984746e", w[2][1], w[2][2] })
		lu.assertEquals(landEvents(player), { { delay = 3500, screenplay = "SpaceStationScreenPlay", method = "landShip", player = player, destination = w[1] } }, w[1] .. ": landShip events")
	end
end

-- AC-8: a pilot without access cannot reach the screen by choosing it
function TestPalaceStationLanding:test_a_pilot_without_access_gets_no_landing_even_after_the_other_landings()
	local player = P.pilot({ kind = "imperial" })

	P.talkStation(player, { "s_5984746e", "s_ccbc6cf4", "s_b9b27823" })
	lu.assertEquals(#landEvents(player), 1, "one landing event")
	lu.assertEquals(landEvents(player)[1].destination, "eisley", "for Mos Eisley, not the palace")
end

---------------------------------------------------------------------------------------------
-- The Hutt work branch (AC-13)
---------------------------------------------------------------------------------------------

TestPalaceStationWork = {}

function TestPalaceStationWork:setUp()
	H.reset()
	P.requireStation(lu)
end

-- The Smugglers that see the default greeting: bounty chain running (each quest), with access, tiers 1 and 4. Builders, so each case starts from a fresh state.
local function defaultGreetingSmugglers()
	local out = {}

	for i = 1, 4 do
		out[#out + 1] = { "chain quest " .. i .. " active", function()
			local player = P.pilot({ tier = 1 })

			P.setState(player, G[i], "active")
			return player
		end }
	end

	for _, tier in ipairs({ 1, 4 }) do
		out[#out + 1] = { "palace access, tier " .. tier, function()
			local player = P.pilot({ tier = tier })

			P.grantAccess(player)
			return player
		end }
	end

	return out
end

-- AC-13
function TestPalaceStationWork:test_a_smuggler_on_the_default_greeting_is_offered_the_hutts_work()
	for _, case in ipairs(defaultGreetingSmugglers()) do
		H.reset()

		local screens = P.talkStation(case[2](), { "s_4360fc64" })

		lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "work_hutts" }, case[1] .. ": screens")
		lu.assertEquals(screens[2].text, sid("s_28b0a7fa"), case[1] .. ": the Hutts line")
		lu.assertEquals(P.optionSet(screens[2], P.ST), { "s_3147a9c7 -> " .. SN .. "hutt_offer", "s_382cb25f -> " .. SN .. "hutt_refused" }, case[1] .. ": options")
	end
end

-- AC-13
function TestPalaceStationWork:test_accepting_the_hutt_work_starts_the_duty_with_a_mission_in_the_datapad()
	for _, case in ipairs(defaultGreetingSmugglers()) do
		H.reset()

		local player = case[2]()
		local screens = P.talkStation(player, { "s_4360fc64", "s_3147a9c7", "s_2e631d52" })

		lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "work_hutts", SN .. "hutt_offer", SN .. "hutt_accepted" }, case[1] .. ": screens")
		lu.assertEquals({ screens[3].text, screens[4].text }, { sid("s_630ab375"), sid("s_d7e462ff") }, case[1] .. ": the offer and the give me a second lines")
		lu.assertEquals(screens[4].stop, true, case[1] .. ": hutt_accepted ends the conversation")
		lu.assertEquals(P.state(player, P.HUTT_DUTY), "active", case[1] .. ": the duty journal entry is active")
		lu.assertEquals(#DR.flaggedMissions(player), 1, case[1] .. ": one duty mission in the datapad")
	end
end

-- AC-13 (C-4): startHuttDuty calls startQuest on the duty, like the trainers do
function TestPalaceStationWork:test_accepting_calls_start_quest_on_the_duty_once()
	local player = P.pilot({})

	P.grantAccess(player)

	local spy = H.spyOn(P.quest(P.HUTT_DUTY), "startQuest")

	P.talkStation(player, { "s_4360fc64", "s_3147a9c7", "s_2e631d52" })
	lu.assertEquals(#spy, 1, "startQuest calls on the duty")
	lu.assertEquals(spy[1] and spy[1].args[1], player, "for the pilot")
end

-- AC-13
function TestPalaceStationWork:test_the_i_will_come_back_later_path_starts_no_duty()
	local player = P.pilot({})

	P.grantAccess(player)

	local spy = H.spyOn(P.quest(P.HUTT_DUTY), "startQuest")
	local screens = P.talkStation(player, { "s_4360fc64", "s_3147a9c7", "s_2f2188d5" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "work_hutts", SN .. "hutt_offer", SN .. "hutt_later" }, "screens")
	lu.assertEquals(screens[4].text, sid("s_1dbd74da"), "the hail me later line")
	lu.assertEquals(screens[4].stop, true, "hutt_later ends the conversation")
	lu.assertEquals(#spy, 0, "no startQuest")
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", "no duty")
end

-- AC-13
function TestPalaceStationWork:test_refusing_the_hutts_starts_no_duty()
	local player = P.pilot({})

	P.grantAccess(player)

	local spy = H.spyOn(P.quest(P.HUTT_DUTY), "startQuest")
	local screens = P.talkStation(player, { "s_4360fc64", "s_382cb25f" })

	lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "work_hutts", SN .. "hutt_refused" }, "screens")
	lu.assertEquals(screens[3].text, sid("s_5739799e"), "the not the times to be picky line")
	lu.assertEquals(screens[3].stop, true, "hutt_refused ends the conversation")
	lu.assertEquals(#spy, 0, "no startQuest")
end

-- AC-13: nothing starts before the final "Hook me up!"
function TestPalaceStationWork:test_walking_away_before_the_hook_up_starts_no_duty()
	for _, choices in ipairs({ { "s_4360fc64" }, { "s_4360fc64", "s_3147a9c7" } }) do
		H.reset()

		local player = P.pilot({})

		P.grantAccess(player)
		P.talkStation(player, choices)
		lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", #choices .. " choices: no duty")
	end
end

-- AC-13: CorSec, RSF, Imperial and Rebel pilots get the refusal
function TestPalaceStationWork:test_every_other_pilot_gets_the_unemployment_agency_line()
	for _, kind in ipairs({ "corsec", "rsf", "imperial", "rebel", "none" }) do
		H.reset()

		local player = P.pilot({ kind = kind })
		local spy = H.spyOn(P.quest(P.HUTT_DUTY), "startQuest")
		local screens = P.talkStation(player, { "s_4360fc64" })

		lu.assertEquals(P.ids(screens), { SN .. "greeting", SN .. "work_refused" }, kind .. ": screens")
		lu.assertEquals(screens[2].text, sid("s_121c3b6"), kind .. ": the unemployment agency line")
		lu.assertEquals(screens[2].stop, true, kind .. ": work_refused ends the conversation")
		lu.assertEquals(#spy, 0, kind .. ": no duty started")
		lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", kind .. ": no duty entry")
	end
end

-- AC-13 (D-23): a Smuggler who has not taken the bounty sees the Valarian greeting, which has no work option
function TestPalaceStationWork:test_a_valarian_eligible_smuggler_has_no_work_option_on_the_first_screen()
	local screen = P.talkStation(P.pilot({}))[1]

	lu.assertEquals(screen.id, SN .. "greeting_valarian", "first screen")
	lu.assertEquals(sids(screen), { "s_f2b8a1d8", "s_375a3c20" }, "options")
end

-- AC-13 (C-4): startHuttDuty is the trainers' direct call
function TestPalaceStationWork:test_startHuttDuty_starts_the_duty_through_the_quest_global()
	local player = P.pilot({})
	local npc = H.newNpc { name = "Tatooine Station" }

	sp():startHuttDuty(player, npc)
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "active", "the duty is active")
	lu.assertEquals(#DR.flaggedMissions(player), 1, "one duty mission")
end

---------------------------------------------------------------------------------------------
-- Duty rules and payout (AC-14)
---------------------------------------------------------------------------------------------

TestPalaceStationDuty = {}

function TestPalaceStationDuty:setUp()
	H.reset()
	P.requireStation(lu)
end

function TestPalaceStationDuty:tearDown()
	DR.restoreRecoveryTables()
	H.Engine.config.rejectEmptyShipName = nil
end

-- AC-14 (E-13)
function TestPalaceStationDuty:test_a_pilot_who_already_holds_a_duty_gets_duty_already_once_and_no_second_duty()
	local player = P.pilot({})

	P.grantAccess(player)
	DR.holdDuty(player, "tatooine_privateer_tier4_1")

	local before = #player.datapad.items
	local screens = P.talkStation(player, { "s_4360fc64", "s_3147a9c7", "s_2e631d52" })

	lu.assertEquals(P.lastId(screens), SN .. "hutt_accepted", "the screen is shown either way (D-22)")
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", "the Hutt duty did not start")
	lu.assertEquals(#player.datapad.items, before, "no new mission in the datapad")
	lu.assertEquals(#DR.messages(player, "@space/quest:duty_already"), 1, "@space/quest:duty_already sent once")
end

-- A Smuggler flying in a ship of the given faction string (nil: the harness default)
local function smugglerIn(shipFaction)
	local player = P.pilot({})

	if shipFaction ~= nil then
		player.rootParent.shipFactionString = shipFaction
		player.rootParent.factionHash = getHashCode(shipFaction)
	end

	return player
end

-- AC-14
function TestPalaceStationDuty:test_the_duty_pays_the_reward_plus_the_kill_bonus_of_cleared_waves_and_clears_the_entry()
	local RF = require("recovery_fixes_scenario")
	local player = smugglerIn()
	local run = RF.start(P.HUTT_DUTY, player)
	local q = run.quest
	local n = #q.attackShips[1]

	lu.assertEquals(P.state(player, P.HUTT_DUTY), "active", "the duty is active")
	RF.capture(run)

	local wave = RF.wave(run)

	lu.assertEquals(#wave, n, "the first wave has the ships of attack list 1")
	RF.killAll(run, wave)
	RF.finish(run)

	local pay = RF.pay(run)

	lu.assertEquals(#pay.credits, 1, "addBankCredits calls")
	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, 1000 + 100 * n, "credits: 1000 + 100 x ships of the cleared wave")
	lu.assertEquals(#pay.messages, 1, "@space/quest:recovery_reward messages")
	lu.assertEquals(pay.messages[1] and pay.messages[1].DI, 1000 + 100 * n, "recovery_reward DI")
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", "the journal entry is cleared (neither active nor complete)")
end

-- AC-14: no kills, no bonus
function TestPalaceStationDuty:test_the_duty_pays_only_the_reward_when_no_wave_was_cleared()
	local RF = require("recovery_fixes_scenario")
	local run = RF.start(P.HUTT_DUTY, smugglerIn())

	RF.capture(run)
	RF.finish(run)

	local pay = RF.pay(run)

	lu.assertEquals(pay.credits[1] and pay.credits[1].amount, 1000, "credits")
end

-- AC-14: the same walk starts the duty again after a completion
function TestPalaceStationDuty:test_the_same_walk_can_start_the_duty_again_after_it_was_completed()
	local RF = require("recovery_fixes_scenario")
	local player = smugglerIn()
	local run = RF.start(P.HUTT_DUTY, player)

	RF.capture(run)
	RF.finish(run)
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "none", "the entry is cleared after the completion")

	P.grantAccess(player)

	local screens = P.talkStation(player, { "s_4360fc64", "s_3147a9c7", "s_2e631d52" })

	lu.assertEquals(P.lastId(screens), SN .. "hutt_accepted", "the walk ends on hutt_accepted again")
	lu.assertEquals(P.state(player, P.HUTT_DUTY), "active", "the duty is active again")
	lu.assertEquals(#DR.flaggedMissions(player), 1, "one duty mission in the datapad")
end

-- AC-14 (R-9): the duty runs and pays in the ship factions of tier 1 and tier 3+ Smugglers
function TestPalaceStationDuty:test_the_duty_pays_the_same_in_a_smuggler_and_a_hutt_faction_ship()
	local RF = require("recovery_fixes_scenario")

	for _, faction in ipairs({ "smuggler", "hutt" }) do
		H.reset()
		DR.restoreRecoveryTables()

		local run = RF.start(P.HUTT_DUTY, smugglerIn(faction))

		RF.capture(run)
		RF.finish(run)

		local pay = RF.pay(run)

		lu.assertEquals(pay.credits[1] and pay.credits[1].amount, 1000, faction .. " ship: credits")
		lu.assertEquals(#pay.messages, 1, faction .. " ship: @space/quest:recovery_reward messages")
	end
end
