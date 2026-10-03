-- Captain Kaydine (RSF tier 2): the gate paths and the off-track duty access, run through the conversation fakes.
-- Spec: .claude/work/rsf-gate-screens/01-spec.md (AC-3, AC-4, Conversation flow K1-K6, Content contract 3, invariant I-5).
--
-- Quest starts and rewards are observed by replacing startQuest / rewardPlayer on every quest global with a recorder (G.spies): nothing
-- here is about what a duty does once started (test_rsf_gate_screens_duty_rules.lua runs the real start).

local lu = require("luaunit")
local H = require("harness")
local T = require("trainer_fixes_data")
local DR = require("duty_rules_scenario")
local G = require("rsf_gate_screens_data")

T.load()

local K = G.KAYDINE_DUTIES
local OPTION = { escort = "s_9b73da8", recovery = "s_30297e22", destroy = "s_c892e540" }
local ACCEPT = { escort = "accept_duty_escort", recovery = "accept_duty_recovery", destroy = "accept_duty_destroy" }
local DUTY_ORDER = { "escort", "recovery", "destroy" }

local function rowById(id)
	for _, row in ipairs(G.KAYDINE_ROWS) do
		if row.id == id then
			return row
		end
	end

	error("answer key has no row " .. id)
end

-- Choose option 1 (index 0) on every screen until one ends the conversation
local function walk(player)
	return G.converse("kaydine", player, { 0, 0, 0, 0, 0, 0 })
end

local function firstScreen(player)
	local transcript = G.converse("kaydine", player)

	lu.assertNotNil(transcript[1], "Kaydine shows a first screen")

	return transcript[1].id
end

---------------------------------------------------------------------------------------------
-- AC-3: the gate paths K1 .. K6
---------------------------------------------------------------------------------------------

TestKaydineGates = {}

function TestKaydineGates:setUp() H.reset() end

-- name, player builder, expected screens of the walk, expected quest starts (the allowed accept screen start)
local GATES = {
	{ "k1_a_player_without_pilot_skills", function() return G.pilot({ kind = "none" }) end, { "not_pilot" } },
	{ "k1_a_corsec_pilot_with_jtl_off", function() H.Engine.config.jtlEnabled = false; return G.offTrack({ tier1 = 4 }) end, { "not_pilot" } },
	{ "k1_a_rebel_pilot_with_jtl_off", function() H.Engine.config.jtlEnabled = false; return G.pilot({ kind = "rebel" }) end, { "not_pilot" } },
	{ "k1_an_imperial_pilot_with_jtl_off", function() H.Engine.config.jtlEnabled = false; return G.pilot({ kind = "imperial" }) end, { "not_pilot" } },
	{ "k2_a_rebel_pilot", function() return G.pilot({ kind = "rebel" }) end, { "rebel_pilot" } },
	{ "k2_a_rebel_pilot_with_rsf_squadron_state_and_neutral_tier_1_skills", function() return G.pilot({ kind = "rebel", squadron = "rsf", tier1 = 4 }) end, { "rebel_pilot" } },
	{ "k3_an_imperial_pilot", function() return G.pilot({ kind = "imperial" }) end, { "imperial_pilot" } },
	{ "k3_an_imperial_pilot_with_corsec_squadron_state", function() return G.pilot({ kind = "imperial", squadron = "corsec" }) end, { "imperial_pilot" } },
	{ "k4_a_corsec_pilot_without_tier_1_skills", function() return G.offTrack({}) end, { "pilot_not_rsf", "non_rsf_missions" } },
	{ "k4_a_smuggler_pilot_without_tier_1_skills", function() return G.offTrack({ squadron = "smuggler" }) end, { "pilot_not_rsf", "non_rsf_missions" } },
	{ "k4_a_corsec_pilot_with_three_tier_1_skills", function() return G.offTrack({ tier1 = 3 }) end, { "pilot_not_rsf", "non_rsf_missions" } },
	{ "k4_a_neutral_pilot_without_a_squadron_and_without_tier_1_skills", function() return G.pilot({}) end, { "pilot_not_rsf", "non_rsf_missions" } },
	{ "k4_a_corsec_pilot_with_all_tier_1_skills", function() return G.offTrack({ tier1 = 4 }) end, { "pilot_not_rsf", "non_rsf_duty_options", "accept_duty_escort" }, { K.escort } },
	{ "k4_a_smuggler_pilot_with_all_tier_1_skills", function() return G.offTrack({ squadron = "smuggler", tier1 = 4 }) end, { "pilot_not_rsf", "non_rsf_duty_options", "accept_duty_escort" }, { K.escort } },
	{ "k5_an_rsf_pilot_of_tier_1", function() return G.rsfPilot({ pilotTier = 1 }) end, { "not_ready_tier2", "not_ready_tier2_end" } },
	{ "k5_an_rsf_pilot_of_tier_0", function() return G.rsfPilot({ pilotTier = 0, tier1 = 0 }) end, { "not_ready_tier2", "not_ready_tier2_end" } },
}

for i, chain in ipairs(G.KAYDINE_CHAINS) do
	GATES[#GATES + 1] = { "k6_an_rsf_tier_2_pilot_with_story_chain_" .. i .. "_active", function() return G.rsfPilot({ pilotTier = 2, active = { chain } }) end, { "on_mission" } }
end

for _, name in ipairs(DUTY_ORDER) do
	GATES[#GATES + 1] = { "k6_an_rsf_tier_2_pilot_with_the_" .. name .. "_duty_active", function() return G.rsfPilot({ pilotTier = 2, active = { K[name] } }) end, { "on_mission" } }
end

for _, gate in ipairs(GATES) do
	-- AC-3: first screen and the whole transcript choosing option 1 throughout
	TestKaydineGates["test_" .. gate[1] .. "_gets_the_screens_" .. table.concat(gate[3], "_then_")] = function()
		local transcript = walk(gate[2]())

		lu.assertEquals(G.ids(transcript), gate[3], gate[1] .. ": screens shown")
		lu.assertTrue(transcript[#transcript].stop, gate[1] .. ": the last screen ends the conversation")

		-- the NPC line of every screen shown is the answer key's
		for _, step in ipairs(transcript) do
			lu.assertEquals(G.sidOfStep(step), rowById(step.id).sid, gate[1] .. ": NPC line of '" .. step.id .. "'")
		end
	end

	-- AC-3, I-5: entering the gate screens grants no skill, pays nothing, writes no quest status, changes no squadron or pilot tier
	TestKaydineGates["test_" .. gate[1] .. "_has_no_side_effect_beyond_the_listed_duty_start"] = function()
		local player = gate[2]()
		local spies = G.spies(player)
		local before = G.statusSnapshot()
		local ships = G.shipGrants()

		walk(player)

		lu.assertEquals(spies.starts, gate[4] or {}, gate[1] .. ": quests started")
		lu.assertEquals(spies.rewards, {}, gate[1] .. ": rewardPlayer calls")
		lu.assertEquals(#spies.chains, 0, gate[1] .. ": startSpaceQuestChain calls")
		lu.assertEquals(#spies.skills, 0, gate[1] .. ": grantSpaceSkill calls")
		lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, gate[1] .. ": skill grants")
		lu.assertEquals(#spies.squadron, 0, gate[1] .. ": setSquadronType calls")
		lu.assertEquals(#spies.tiers, 0, gate[1] .. ": incrementPilotTier calls")
		lu.assertEquals(G.shipGrants(), ships, gate[1] .. ": grantStarterShip calls")
		lu.assertEquals(G.statusDiff(before, G.statusSnapshot()), {}, gate[1] .. ": quest status keys written")
	end
end

-- AC-3: the refusal for a rebel is SWG's s_7ac0f961 (the old "civilian" and off-track line), the imperial's is s_6c6f3940
function TestKaydineGates:test_the_rebel_gets_s_7ac0f961_the_imperial_s_6c6f3940_and_the_off_track_pilot_s_c89c3456()
	lu.assertEquals(G.sidOfStep(G.converse("kaydine", G.pilot({ kind = "rebel" }))[1]), "s_7ac0f961", "rebel pilot")
	lu.assertEquals(G.sidOfStep(G.converse("kaydine", G.pilot({ kind = "imperial" }))[1]), "s_6c6f3940", "imperial pilot")
	lu.assertEquals(G.sidOfStep(G.converse("kaydine", G.offTrack({}))[1]), "s_c89c3456", "off-track pilot")
	lu.assertEquals(G.sidOfStep(G.converse("kaydine", G.pilot({ kind = "none" }))[1]), "s_3db3463f", "non-pilot")
end

-- AC-3, K5: the bow greeting offers the one reply, which leads to the old end line
function TestKaydineGates:test_not_ready_tier2_offers_s_b0704da1_and_it_leads_to_the_end_line_s_eac39719()
	local transcript = G.converse("kaydine", G.rsfPilot({ pilotTier = 1 }), { "s_b0704da1" })

	lu.assertEquals(G.ids(transcript), { "not_ready_tier2", "not_ready_tier2_end" }, "screens")
	lu.assertEquals(G.optionSids(transcript[1]), { "s_b0704da1" }, "options of the greeting")
	lu.assertFalse(transcript[1].stop, "the greeting does not end the conversation")
	lu.assertEquals(G.sidOfStep(transcript[2]), "s_eac39719", "NPC line of the end screen")
	lu.assertTrue(transcript[2].stop, "the end screen ends the conversation")
end

-- AC-3: migrateLegacyProgress is still the first thing getInitialScreen does, for every state
function TestKaydineGates:test_migrate_legacy_progress_runs_first_for_every_gate_state()
	local log = {}
	local originals = {}

	local function wrap(owner, name, label)
		local original = owner[name]

		originals[#originals + 1] = { owner, name, original }
		owner[name] = function(...)
			log[#log + 1] = label

			return original(...)
		end
	end

	wrap(_G, "isJtlEnabled", "isJtlEnabled")

	for _, name in ipairs({ "isPilot", "isNeutralPilot", "isRebelPilot", "isImperialPilot", "isRSFSquadron" }) do
		wrap(SpaceHelpers, name, name)
	end

	wrap(RsfSquadronScreenplay, "migrateLegacyProgress", "migrate")

	local ok, err = pcall(function()
		for _, gate in ipairs(GATES) do
			H.reset()
			log = {}

			local player = gate[2]()

			log = {}
			G.converse("kaydine", player)

			lu.assertEquals(log[1], "migrate", gate[1] .. ": first call of getInitialScreen (calls: " .. table.concat(log, ", ") .. ")")

			local migrations = 0

			for _, label in ipairs(log) do
				if label == "migrate" then migrations = migrations + 1 end
			end

			lu.assertTrue(migrations >= 1, gate[1] .. ": migrateLegacyProgress runs")
		end
	end)

	for i = #originals, 1, -1 do
		originals[i][1][originals[i][2]] = originals[i][3]
	end

	if not ok then
		error(err, 0)
	end
end

---------------------------------------------------------------------------------------------
-- AC-4: off-track duty access
---------------------------------------------------------------------------------------------

TestKaydineOffTrackDuties = {}

function TestKaydineOffTrackDuties:setUp() H.reset() end

local function offerChoices(extra)
	return G.concat({ "s_c1ff5062" }, extra or {})
end

-- AC-4
function TestKaydineOffTrackDuties:test_a_corsec_pilot_with_all_tier_1_skills_reaches_non_rsf_duty_options_with_the_three_options_in_order()
	local transcript = G.converse("kaydine", G.offTrack({ tier1 = 4 }), offerChoices())

	lu.assertEquals(G.ids(transcript), { "pilot_not_rsf", "non_rsf_duty_options" }, "screens")
	lu.assertEquals(G.sidOfStep(transcript[2]), "s_8a84109d", "NPC line")
	lu.assertEquals(G.optionSids(transcript[2]), { "s_9b73da8", "s_30297e22", "s_c892e540" }, "options in Appendix A order")
	lu.assertFalse(transcript[2].stop, "the offer does not end the conversation")
end

-- AC-4: the offer screen's own option link is re-pointed at display time, the stored link is the refusal (E-G1)
function TestKaydineOffTrackDuties:test_the_first_screen_option_leads_to_the_offer_or_the_refusal_by_what_the_pilot_may_fly()
	local yes = G.converse("kaydine", G.offTrack({ tier1 = 4 }))
	local no = G.converse("kaydine", G.offTrack({ tier1 = 3 }))

	lu.assertEquals(yes[1].options[1].link, "non_rsf_duty_options", "link of s_c1ff5062 for a pilot with all tier 1 skills")
	lu.assertEquals(no[1].options[1].link, "non_rsf_missions", "link of s_c1ff5062 for a pilot with three tier 1 skills")
	lu.assertEquals(#yes[1].options, 1, "options on pilot_not_rsf (all skills)")
	lu.assertEquals(#no[1].options, 1, "options on pilot_not_rsf (three skills)")
end

for _, name in ipairs(DUTY_ORDER) do
	-- AC-4
	TestKaydineOffTrackDuties["test_option_" .. OPTION[name] .. "_starts_only_the_" .. name .. "_duty_once_and_ends_on_" .. ACCEPT[name]] = function()
		local player = G.offTrack({ tier1 = 4 })
		local spies = G.spies(player)
		local npc = H.newNpc({ name = "Trainer" })
		local transcript = G.converse("kaydine", player, offerChoices({ OPTION[name] }), npc)

		lu.assertEquals(G.ids(transcript), { "pilot_not_rsf", "non_rsf_duty_options", ACCEPT[name] }, "screens")
		lu.assertTrue(transcript[3].stop, ACCEPT[name] .. " ends the conversation")
		lu.assertEquals(G.sidOfStep(transcript[3]), rowById(ACCEPT[name]).sid, "NPC line of " .. ACCEPT[name])
		lu.assertEquals(spies.starts, { K[name] }, "startQuest calls on any quest")
		lu.assertTrue(spies.startSelf[1] == rawget(_G, K[name]), K[name] .. ": startQuest called on the quest table")
		lu.assertEquals(spies.rewards, {}, "rewardPlayer calls")
		lu.assertEquals(#spies.chains, 0, "story chains started")
	end
end

-- The refusal rows: the pilot gets non_rsf_missions (end) and nothing is started
local REFUSALS = {}

for i = 1, 4 do
	local missing = { "droid", "procedures", "starships", "weapons" }

	REFUSALS[#REFUSALS + 1] = {
		"a_corsec_pilot_missing_the_tier_1_skill_" .. missing[i],
		function()
			local skills = {}

			for j = 1, 4 do
				if j ~= i then skills[#skills + 1] = G.TIER1_SKILLS[j] end
			end

			return G.offTrack({ skills = skills })
		end,
	}
end

REFUSALS[#REFUSALS + 1] = { "a_corsec_pilot_with_no_tier_1_skill", function() return G.offTrack({}) end }

for _, name in ipairs(DUTY_ORDER) do
	REFUSALS[#REFUSALS + 1] = { "a_pilot_with_the_" .. name .. "_duty_active_in_the_journal", function() return G.offTrack({ tier1 = 4, active = { K[name] } }) end }
end

for i, chain in ipairs(G.KAYDINE_CHAINS) do
	REFUSALS[#REFUSALS + 1] = { "a_pilot_with_kaydine_story_chain_" .. i .. "_active_in_the_journal", function() return G.offTrack({ tier1 = 4, active = { chain } }) end }
end

REFUSALS[#REFUSALS + 1] = { "a_pilot_holding_a_duty_in_the_datapad", function() local p = G.offTrack({ tier1 = 4 }); DR.holdDuty(p); return p end }
REFUSALS[#REFUSALS + 1] = { "a_pilot_holding_a_story_mission_in_the_datapad", function() local p = G.offTrack({ tier1 = 4 }); DR.holdStory(p); return p end }
REFUSALS[#REFUSALS + 1] = { "a_pilot_holding_a_story_mission_of_another_squadron", function() local p = G.offTrack({ tier1 = 4, squadron = "smuggler" }); DR.holdStory(p, "corellia_rebel_1"); return p end }

for _, refusal in ipairs(REFUSALS) do
	-- AC-4
	TestKaydineOffTrackDuties["test_" .. refusal[1] .. "_gets_non_rsf_missions_and_nothing_starts"] = function()
		local player = refusal[2]()
		local spies = G.spies(player)
		local transcript = G.converse("kaydine", player, offerChoices())

		lu.assertEquals(G.ids(transcript), { "pilot_not_rsf", "non_rsf_missions" }, "screens")
		lu.assertTrue(transcript[2].stop, "non_rsf_missions ends the conversation")
		lu.assertEquals(G.sidOfStep(transcript[2]), "s_7458c693", "NPC line")
		lu.assertEquals(spies.starts, {}, "quests started")
	end
end

-- AC-4: the offer is made from the player's state at the time of the visit
function TestKaydineOffTrackDuties:test_the_offer_is_gone_once_the_pilot_holds_a_duty_in_the_datapad_on_the_next_visit()
	local player = G.offTrack({ tier1 = 4 })

	lu.assertEquals(G.ids(G.converse("kaydine", player, offerChoices())), { "pilot_not_rsf", "non_rsf_duty_options" }, "first visit")
	DR.holdDuty(player)
	lu.assertEquals(G.ids(G.converse("kaydine", player, offerChoices())), { "pilot_not_rsf", "non_rsf_missions" }, "second visit with a held duty")
end

-- AC-4: an RSF tier 2 pilot keeps the old flow here_for_work -> duty_options -> accept screen, and never sees the off-track screens
function TestKaydineOffTrackDuties:test_an_rsf_tier_2_pilot_keeps_here_for_work_then_duty_options_then_the_accept_screen()
	local kaydine = T.TRAINERS.kaydine

	for _, name in ipairs(DUTY_ORDER) do
		H.reset()

		local base = { "pilot_neutral_starships_02", "pilot_neutral_weapons_02", "pilot_neutral_procedures_02" }
		local player = T.player(kaydine, 4, { complete = { "escort_naboo_privateer_15" }, baseSkills = base, questStatus = { ["naboo_privateer_15:reward"] = "1" } })
		local spies = G.spies(player)
		local transcript = G.converse("kaydine", player, { "s_4a1d2431", OPTION[name] })

		lu.assertEquals(G.ids(transcript), { "here_for_work", "duty_options", ACCEPT[name] }, name .. ": screens")
		lu.assertEquals(spies.starts, { K[name] }, name .. ": quests started")
	end
end

-- AC-4: an RSF pilot is never shown the off-track offer, with a duty in the datapad or not
function TestKaydineOffTrackDuties:test_an_rsf_pilot_never_reaches_the_off_track_screens()
	for _, hold in ipairs({ false, true }) do
		H.reset()

		local player = G.rsfPilot({ pilotTier = 2 })

		if hold then DR.holdDuty(player) end

		for _, step in ipairs(walk(player)) do
			lu.assertFalse(step.id == "non_rsf_duty_options" or step.id == "pilot_not_rsf" or step.id == "non_rsf_missions", "screen " .. step.id .. " (held duty: " .. tostring(hold) .. ")")
		end
	end
end

-- Sanity of the setup: the first screens above are what firstScreen reports
function TestKaydineOffTrackDuties:test_the_first_screen_of_an_off_track_pilot_is_pilot_not_rsf_whatever_the_skills()
	for tier1 = 0, 4 do
		lu.assertEquals(firstScreen(G.offTrack({ tier1 = tier1 })), "pilot_not_rsf", "first screen with " .. tier1 .. " tier 1 skills")
	end
end

---------------------------------------------------------------------------------------------
-- Handler methods named by the spec (binding names)
---------------------------------------------------------------------------------------------

TestKaydineHandlerMethods = {}

function TestKaydineHandlerMethods:setUp() H.reset() end

local function handler()
	return H.expectGlobal("kaydineConvoHandler", "Kaydine conversation handler")
end

local function method(name)
	local h = handler()

	lu.assertEquals(type(h[name]), "function", "expected kaydineConvoHandler to define " .. name .. " (spec Content contract 3)")

	return h[name]
end

-- AC-4: isOnMission is true iff one of the four story chains or three duties is active
function TestKaydineHandlerMethods:test_is_on_mission_is_true_for_each_chain_and_duty_and_false_otherwise()
	local isOnMission = method("isOnMission")

	lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 4 })), "no quest")
	lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 4, active = { G.HAVOC_STORY } })), "a quest of another squadron is not Kaydine's")

	for _, chain in ipairs(G.KAYDINE_CHAINS) do
		lu.assertTrue(isOnMission(handler(), G.offTrack({ tier1 = 4, active = { chain } })), chain .. ": active")
		lu.assertFalse(isOnMission(handler(), G.offTrack({ tier1 = 4, complete = { chain } })), chain .. ": complete is not on mission")
	end

	for _, name in ipairs(DUTY_ORDER) do
		lu.assertTrue(isOnMission(handler(), G.offTrack({ tier1 = 4, active = { K[name] } })), K[name] .. ": active")
	end
end

-- AC-4: canFlyNonTrackDuty = tier 1 complete, not on mission, no space quest in the datapad
function TestKaydineHandlerMethods:test_can_fly_non_track_duty_needs_tier_1_no_kaydine_quest_and_no_space_quest_in_the_datapad()
	local can = method("canFlyNonTrackDuty")

	lu.assertTrue(can(handler(), G.offTrack({ tier1 = 4 })), "all tier 1 skills, no quest")
	lu.assertFalse(can(handler(), G.offTrack({ tier1 = 3 })), "three tier 1 skills")
	lu.assertFalse(can(handler(), G.offTrack({ tier1 = 4, active = { K.destroy } })), "a Kaydine duty active")

	local held = G.offTrack({ tier1 = 4 })

	DR.holdStory(held)
	lu.assertFalse(can(handler(), held), "a story mission in the datapad")
end
