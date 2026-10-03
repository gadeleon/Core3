-- Dinge (RSF tier 1): the gate paths and the off-track duty access, run through the conversation fakes.
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-5 gates, AC-6, Conversation flow D1-D5, Content contract 5, invariant I-5).
--
-- Quest starts and rewards are observed by replacing startQuest / rewardPlayer on every quest global with a recorder (G.spies).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local DR = require("duty_rules_scenario")
local G = require("rsf_gate_screens_data")

T.load()

local D6, D7 = G.DINGE_DUTIES.destroy, G.DINGE_DUTIES.escort
local MENU = { "s_6106187c", "s_e814cf37", "s_db74ddc6", "s_2883b989" }

local function offer(extra)
	return G.concat({ "s_c1ff5062" }, extra or {})
end

---------------------------------------------------------------------------------------------
-- Gate paths D1 .. D5
---------------------------------------------------------------------------------------------

TestDingeGates = {}

function TestDingeGates:setUp() H.reset() end

-- name, player builder, first screen, its NPC line
local GATES = {
	{ "d1_a_corsec_pilot_with_jtl_off", function() H.Engine.config.jtlEnabled = false; return G.offTrack({ skills = { G.TIER1_SKILLS[1] } }) end, "no_jtl", "s_7c1fe68f" },
	{ "d1_a_rebel_pilot_with_jtl_off", function() H.Engine.config.jtlEnabled = false; return G.pilot({ kind = "rebel" }) end, "no_jtl", "s_7c1fe68f" },
	{ "d2_a_rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, "rebel_pilot", "s_72f94b8e" },
	{ "d2_a_rebel_pilot_holding_neutral_tier_1_skills", function() return G.pilot({ kind = "rebel", tier1 = 4 }) end, "rebel_pilot", "s_72f94b8e" },
	{ "d3_an_imperial_pilot", function() return G.pilot({ kind = "imperial" }) end, "imperial_pilot", "s_7217d77" },
	{ "d3_an_imperial_pilot_with_corsec_squadron_state", function() return G.pilot({ kind = "imperial", squadron = "corsec" }) end, "imperial_pilot", "s_7217d77" },
	{ "d4_a_corsec_pilot_without_tier_1_skills", function() return G.offTrack({}) end, "non_rsf_pilot", "s_6b25cc31" },
	{ "d4_a_smuggler_pilot_without_tier_1_skills", function() return G.offTrack({ squadron = "smuggler" }) end, "non_rsf_pilot", "s_6b25cc31" },
	{ "d4_a_neutral_pilot_without_a_squadron_or_skills", function() return G.pilot({}) end, "non_rsf_pilot", "s_6b25cc31" },
	{ "d4_a_corsec_pilot_with_one_tier_1_skill", function() return G.offTrack({ tier1 = 1 }) end, "non_rsf_pilot", "s_6b25cc31" },
	{ "d4_a_corsec_pilot_with_all_tier_1_skills", function() return G.offTrack({ tier1 = 4 }) end, "non_rsf_pilot", "s_6b25cc31" },
	{ "d5_a_pilot_without_pilot_skills", function() return G.pilot({ kind = "none" }) end, "recruitment", "s_465e6eeb" },
}

for _, gate in ipairs(GATES) do
	TestDingeGates["test_" .. gate[1] .. "_gets_the_first_screen_" .. gate[3]] = function()
		local transcript = G.converse("dinge", gate[2]())

		lu.assertEquals(transcript[1].id, gate[3], gate[1] .. ": first screen")
		lu.assertEquals(G.sidOfStep(transcript[1]), gate[4], gate[1] .. ": NPC line of the first screen")
	end
end

-- AC-5 / D2 / D3: each faction hears its own line, and the refusals end the conversation
function TestDingeGates:test_the_rebel_gets_s_72f94b8e_and_the_imperial_s_7217d77_and_both_conversations_end()
	local rebel = G.converse("dinge", G.pilot({ kind = "rebel" }), { 0, 0 })
	local imperial = G.converse("dinge", G.pilot({ kind = "imperial" }), { 0, 0 })

	lu.assertEquals(G.ids(rebel), { "rebel_pilot" }, "rebel transcript")
	lu.assertEquals(G.sidOfStep(rebel[1]), "s_72f94b8e", "rebel NPC line")
	lu.assertTrue(rebel[1].stop, "rebel_pilot ends the conversation")
	lu.assertEquals(G.ids(imperial), { "imperial_pilot" }, "imperial transcript")
	lu.assertEquals(G.sidOfStep(imperial[1]), "s_7217d77", "imperial NPC line")
	lu.assertTrue(imperial[1].stop, "imperial_pilot ends the conversation")
end

-- AC-5 / D1: JTL off wins over the faction gates (the order of the gates is J's)
function TestDingeGates:test_jtl_off_is_checked_before_the_faction_gates()
	H.Engine.config.jtlEnabled = false

	for _, kind in ipairs({ "rebel", "imperial", "neutral", "none" }) do
		lu.assertEquals(G.converse("dinge", G.pilot({ kind = kind }))[1].id, "no_jtl", kind .. " pilot with JTL off")
	end
end

-- AC-5 / I-5: entering any of the gate screens and the off-track screens grants nothing, pays nothing and writes no status,
-- except the duty starts the duty screens are for
local SIDE_EFFECT_ROWS = {
	{ "no_jtl", function() H.Engine.config.jtlEnabled = false; return G.offTrack({ tier1 = 1 }) end, {}, { 0, 0 } },
	{ "rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, {}, { 0, 0 } },
	{ "imperial_pilot", function() return G.pilot({ kind = "imperial" }) end, {}, { 0, 0 } },
	{ "non_rsf_duty_missions", function() return G.offTrack({}) end, {}, { 0, 0 } },
	{ "non_rsf_duty_offer", function() return G.offTrack({ tier1 = 1 }) end, {}, { 0, 0, 0 } },
	{ "duty_not_now", function() return G.offTrack({ tier1 = 1 }) end, {}, { "s_c1ff5062", "s_2883b989" } },
	{ "not_ready", function() return G.offTrack({ tier1 = 1 }) end, {}, { "s_c1ff5062", "s_e814cf37", "s_3d36a0e4" } },
	{ "destroy_duty", function() return G.offTrack({ tier1 = 1 }) end, { D6 }, { "s_c1ff5062", "s_e814cf37", "s_40759c25" } },
	{ "escort_duty", function() return G.offTrack({ tier1 = 1 }) end, { D7 }, { "s_c1ff5062", "s_e814cf37", "s_629c7d23" } },
}

for _, row in ipairs(SIDE_EFFECT_ROWS) do
	-- AC-5, AC-6, I-5
	TestDingeGates["test_walking_to_" .. row[1] .. "_has_no_side_effect_beyond_the_listed_duty_start"] = function()
		local player = row[2]()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		local ships = G.shipGrants()

		G.converse("dinge", player, row[4])

		lu.assertEquals(spies.starts, row[3], row[1] .. ": quests started")
		lu.assertEquals(spies.rewards, {}, row[1] .. ": rewardPlayer calls")
		lu.assertEquals(#spies.chains, 0, row[1] .. ": startSpaceQuestChain calls")
		lu.assertEquals(#spies.skills, 0, row[1] .. ": grantSpaceSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, row[1] .. ": skill grants")
		lu.assertEquals(#spies.squadron, 0, row[1] .. ": setSquadronType calls")
		lu.assertEquals(#spies.tiers, 0, row[1] .. ": incrementPilotTier calls")
		lu.assertEquals(G.shipGrants(), ships, row[1] .. ": grantStarterShip calls")
		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, row[1] .. ": quest status keys written")
	end
end

---------------------------------------------------------------------------------------------
-- AC-6: off-track duty access
---------------------------------------------------------------------------------------------

TestDingeOffTrackDuties = {}

function TestDingeOffTrackDuties:setUp() H.reset() end

local SKILL_NAMES = { "droid", "procedures", "starships", "weapons" }

for i, skillName in ipairs(SKILL_NAMES) do
	local function player()
		return G.offTrack({ skills = { G.TIER1_SKILLS[i] } })
	end

	-- AC-6: any single tier 1 skill opens the offer
	TestDingeOffTrackDuties["test_a_corsec_pilot_with_only_the_" .. skillName .. "_tier_1_skill_reaches_non_rsf_duty_offer_with_the_four_options"] = function()
		local transcript = G.converse("dinge", player(), offer())

		lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer" }, "screens")
		lu.assertEquals(G.sidOfStep(transcript[2]), "s_1e029d90", "NPC line")
		lu.assertEquals(G.optionSids(transcript[2]), MENU, "options in Appendix A order")
		lu.assertFalse(transcript[2].stop, "the offer does not end the conversation")
	end

	-- AC-6
	TestDingeOffTrackDuties["test_with_only_the_" .. skillName .. "_skill_s_e814cf37_then_s_40759c25_starts_destroy_duty_6_once"] = function()
		local p = player()
		local spies = G.spies(p)
		local transcript = G.converse("dinge", p, offer({ "s_e814cf37", "s_40759c25" }))

		lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_options", "destroy_duty" }, "screens")
		lu.assertTrue(transcript[4].stop, "destroy_duty ends the conversation")
		lu.assertEquals(spies.starts, { D6 }, "startQuest calls on any quest")
		lu.assertTrue(spies.startSelf[1] == rawget(_G, D6), "startQuest called on the duty 6 table")
		lu.assertEquals(spies.rewards, {}, "rewardPlayer calls")
	end

	-- AC-6
	TestDingeOffTrackDuties["test_with_only_the_" .. skillName .. "_skill_s_e814cf37_then_s_629c7d23_starts_escort_duty_7_once"] = function()
		local p = player()
		local spies = G.spies(p)
		local transcript = G.converse("dinge", p, offer({ "s_e814cf37", "s_629c7d23" }))

		lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_options", "escort_duty" }, "screens")
		lu.assertEquals(spies.starts, { D7 }, "startQuest calls on any quest")
		lu.assertTrue(spies.startSelf[1] == rawget(_G, D7), "startQuest called on the duty 7 table")
	end

	-- AC-6: the offer is shown from the player's state at the time of the visit
	TestDingeOffTrackDuties["test_the_offer_for_the_" .. skillName .. "_skill_is_refused_once_the_pilot_holds_a_space_quest_on_the_next_visit"] = function()
		local p = player()

		lu.assertEquals(G.ids(G.converse("dinge", p, offer())), { "non_rsf_pilot", "non_rsf_duty_offer" }, "first visit")
		DR.holdStory(p)
		lu.assertEquals(G.ids(G.converse("dinge", p, offer())), { "non_rsf_pilot", "non_rsf_duty_missions" }, "second visit with a held story mission")
	end
end

-- AC-6: duty_options also offers "not ready", which starts nothing
function TestDingeOffTrackDuties:test_s_3d36a0e4_on_duty_options_leads_to_not_ready_and_starts_nothing()
	local p = G.offTrack({ tier1 = 1 })
	local spies = G.spies(p)
	local transcript = G.converse("dinge", p, offer({ "s_e814cf37", "s_3d36a0e4" }))

	lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_options", "not_ready" }, "screens")
	lu.assertEquals(G.optionSids(transcript[3]), { "s_40759c25", "s_629c7d23", "s_3d36a0e4" }, "options of duty_options")
	lu.assertEquals(spies.starts, {}, "quests started")
end

-- AC-6: the explanation lines loop back to the four-option menu and start nothing
function TestDingeOffTrackDuties:test_s_6106187c_and_s_db74ddc6_loop_back_to_the_four_option_menu_and_start_nothing()
	for _, choice in ipairs({ "s_6106187c", "s_db74ddc6" }) do
		H.reset()

		local p = G.offTrack({ tier1 = 1 })
		local spies = G.spies(p)
		local transcript = G.converse("dinge", p, offer({ choice, choice }))
		local want = choice == "s_6106187c" and "what_is_duty" or "duty_no_training"

		lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer", want, want }, choice .. ": screens")
		lu.assertEquals(G.optionSids(transcript[3]), MENU, choice .. ": options of " .. want)
		lu.assertFalse(transcript[3].stop, want .. " does not end the conversation")
		lu.assertEquals(spies.starts, {}, choice .. ": quests started")
	end
end

-- AC-6
function TestDingeOffTrackDuties:test_s_2883b989_ends_on_duty_not_now_and_starts_nothing()
	local p = G.offTrack({ tier1 = 1 })
	local spies = G.spies(p)
	local transcript = G.converse("dinge", p, offer({ "s_2883b989" }))

	lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_offer", "duty_not_now" }, "screens")
	lu.assertTrue(transcript[3].stop, "duty_not_now ends the conversation")
	lu.assertEquals(spies.starts, {}, "quests started")
end

-- AC-6: the stored link of s_c1ff5062 is the refusal (E-G2); the offer comes from re-pointing it at display time
function TestDingeOffTrackDuties:test_the_option_of_non_rsf_pilot_leads_to_the_offer_or_the_refusal_by_what_the_pilot_may_fly()
	local yes = G.converse("dinge", G.offTrack({ tier1 = 1 }))
	local no = G.converse("dinge", G.offTrack({}))

	lu.assertEquals(yes[1].options[1].link, "non_rsf_duty_offer", "link of s_c1ff5062 for a pilot with a tier 1 skill")
	lu.assertEquals(no[1].options[1].link, "non_rsf_duty_missions", "link of s_c1ff5062 for a pilot without tier 1 skills")
	lu.assertEquals(#yes[1].options, 1, "options on non_rsf_pilot (with a skill)")
	lu.assertEquals(#no[1].options, 1, "options on non_rsf_pilot (without)")
end

-- Refusals: the pilot gets non_rsf_duty_missions (end) and nothing is started
local REFUSALS = {
	{ "a_corsec_pilot_with_no_tier_1_skill", function() return G.offTrack({}) end },
	{ "a_corsec_pilot_with_only_a_tier_2_skill", function() return G.offTrack({ skills = { "pilot_neutral_starships_02" } }) end },
	{ "a_pilot_with_a_tier_1_skill_and_a_duty_in_the_datapad", function() local p = G.offTrack({ tier1 = 1 }); DR.holdDuty(p); return p end },
	{ "a_pilot_with_a_tier_1_skill_and_a_story_mission_in_the_datapad", function() local p = G.offTrack({ tier1 = 1 }); DR.holdStory(p); return p end },
	{ "a_pilot_with_a_tier_1_skill_and_a_havoc_story_mission_in_the_datapad", function() local p = G.offTrack({ tier1 = 4 }); DR.holdStory(p, "corellia_rebel_1"); return p end },
}

for i, chain in ipairs(G.DINGE_CHAINS) do
	REFUSALS[#REFUSALS + 1] = { "a_pilot_with_dinge_chain_" .. i .. "_active_in_the_journal", function() return G.offTrack({ tier1 = 4, active = { chain } }) end }
end

REFUSALS[#REFUSALS + 1] = { "a_pilot_with_destroy_duty_6_active_in_the_journal", function() return G.offTrack({ tier1 = 4, active = { D6 } }) end }
REFUSALS[#REFUSALS + 1] = { "a_pilot_with_escort_duty_7_active_in_the_journal", function() return G.offTrack({ tier1 = 4, active = { D7 } }) end }

for _, refusal in ipairs(REFUSALS) do
	-- AC-6
	TestDingeOffTrackDuties["test_" .. refusal[1] .. "_gets_non_rsf_duty_missions_and_nothing_starts"] = function()
		local player = refusal[2]()
		local spies = G.spies(player)
		local transcript = G.converse("dinge", player, offer())

		lu.assertEquals(G.ids(transcript), { "non_rsf_pilot", "non_rsf_duty_missions" }, "screens")
		lu.assertTrue(transcript[2].stop, "non_rsf_duty_missions ends the conversation")
		lu.assertEquals(G.sidOfStep(transcript[2]), "s_38d8b2c4", "NPC line")
		lu.assertEquals(spies.starts, {}, "quests started")
	end
end

-- AC-6: the ship check and recruitment are never reached for an off-track pilot
function TestDingeOffTrackDuties:test_an_off_track_pilot_without_a_certified_ship_still_gets_non_rsf_pilot_and_no_starter_ship()
	for _, tier1 in ipairs({ 0, 1, 4 }) do
		H.reset()

		local player = G.offTrack({ tier1 = tier1, certifiedShip = false })
		local ships = G.shipGrants()
		local transcript = G.converse("dinge", player, offer())

		lu.assertEquals(transcript[1].id, "non_rsf_pilot", tier1 .. " tier 1 skills: first screen")
		lu.assertEquals(G.shipGrants(), ships, tier1 .. " tier 1 skills: grantStarterShip calls")

		for _, step in ipairs(transcript) do
			lu.assertFalse(step.id == "recruitment" or step.id == "no_ship" or step.id == "signup_no_ship", tier1 .. " tier 1 skills: reached " .. step.id)
		end
	end
end

-- AC-6: an RSF pilot never sees the off-track screens
function TestDingeOffTrackDuties:test_an_rsf_pilot_never_reaches_the_off_track_screens()
	for _, tier1 in ipairs({ 0, 1, 4 }) do
		H.reset()

		local player = G.rsfPilot({ tier1 = tier1, pilotTier = 1 })

		for _, step in ipairs(G.converse("dinge", player, { 0, 0, 0, 0, 0, 0 })) do
			lu.assertFalse(step.id == "non_rsf_pilot" or step.id == "non_rsf_duty_offer" or step.id == "non_rsf_duty_missions", tier1 .. " tier 1 skills: reached " .. step.id)
		end
	end
end

---------------------------------------------------------------------------------------------
-- Handler methods named by the spec (binding names)
---------------------------------------------------------------------------------------------

TestDingeHandlerMethods = {}

function TestDingeHandlerMethods:setUp() H.reset() end

local function handler()
	return H.expectGlobal("dingeConvoHandler", "Dinge conversation handler")
end

local function method(name)
	local h = handler()

	lu.assertEquals(type(h[name]), "function", "expected dingeConvoHandler to define " .. name .. " (spec Content contract 5)")

	return h[name]
end

-- AC-6: isOnMission is true for each of the four chains and the two duties
function TestDingeHandlerMethods:test_is_on_mission_is_true_for_each_chain_and_duty_and_false_otherwise()
	local isOnMission = method("isOnMission")

	lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 1 })), "no quest")
	lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 1, active = { G.HAVOC_STORY } })), "a quest of another squadron is not Dinge's")

	for _, chain in ipairs(G.DINGE_CHAINS) do
		lu.assertTrue(isOnMission(handler(), G.offTrack({ tier1 = 1, active = { chain } })), chain .. ": active")
		lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 1, complete = { chain } })), chain .. ": complete is not on mission")
	end

	for _, duty in ipairs({ D6, D7 }) do
		lu.assertTrue(isOnMission(handler(), G.offTrack({ tier1 = 1, active = { duty } })), duty .. ": active")
	end
end

-- AC-6: canFlyNonTrackDuty = any tier 1 skill, not on mission, no space quest in the datapad
function TestDingeHandlerMethods:test_can_fly_non_track_duty_needs_a_tier_1_skill_no_dinge_quest_and_no_space_quest_in_the_datapad()
	local can = method("canFlyNonTrackDuty")

	lu.assertTrue(can(handler(), G.offTrack({ tier1 = 1 })), "one tier 1 skill, no quest")
	lu.assertTrue(can(handler(), G.offTrack({ tier1 = 4 })), "all tier 1 skills, no quest")
	lu.assertFalse(can(handler(), G.offTrack({})), "no tier 1 skill")
	lu.assertFalse(can(handler(), G.offTrack({ tier1 = 1, active = { D6 } })), "duty 6 active")

	local held = G.offTrack({ tier1 = 1 })

	DR.holdDuty(held)
	lu.assertFalse(can(handler(), held), "a duty in the datapad")
end
