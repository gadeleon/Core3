-- Shamdon Kree: which screen a pilot opens on (gate table S), the off-track duty offer (C-1), the helpers and the pure-gate invariant I-9.
-- Spec: .claude/work/smuggler-tier2-shamdon/01-spec.md (AC-6; Conversation flow 1 and 2; Content contract 3; D-3, D-6, D-9, D-13; I-9).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is smuggler_tier2_data.lua M.pilot
-- (a Smuggler with all four tier 1 skills, the transition won and paid, no tier 2 skill, no XP). The first screen is read with M.talk (it runs the
-- screen handlers) and, for the pure-gate checks, straight from getInitialScreen.

local lu = require("luaunit")
local H = require("harness")
local M = require("smuggler_tier2_data")
local S = require("smuggler_tier1_data")
local CS = require("harness.client_strings")
local MS = require("migration_scenario")

M.load()

local function spyAllStarts()
	local spies = {}

	for _, g in ipairs(M.questTables()) do
		spies[g] = H.spyOn(rawget(_G, g), "startQuest")
	end

	return spies
end

local function setUp()
	H.reset()
	M.requireConversation(lu)
	spyAllStarts()
end

local function opens(player) return M.firstScreen(player) end

local function screenId(screen) return LuaConversationScreen(screen):getScreenID() end

TestSmugglerT2Gates = {}

TestSmugglerT2Gates.setUp = setUp

-- S0
-- AC-6
function TestSmugglerT2Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = M.pilot(), M.npc(), H.conversationTemplate(M.TEMPLATE)

	lu.assertNil(M.handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(M.handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(M.handler():getInitialScreen(player, npc, nil), "no template")
end

-- S1
-- AC-6, D-9
function TestSmugglerT2Gates:test_jtl_disabled_opens_not_pilot_even_for_a_smuggler()
	H.Engine.config.jtlEnabled = false
	lu.assertEquals(opens(M.pilot()), "not_pilot", "Smuggler, JTL disabled")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, all4 = true })), "not_pilot", "graduate, JTL disabled")
end

-- AC-6
function TestSmugglerT2Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = M.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- S2
-- AC-6: non-pilots of every GCW faction
function TestSmugglerT2Gates:test_non_pilots_of_every_faction_open_not_pilot()
	for _, faction in ipairs({ "neutral", "rebel", "imperial" }) do
		lu.assertEquals(opens(M.pilot({ pilot = false, squadron = false, faction = faction, tier = 0, paid = 0 })), "not_pilot", "non-pilot, " .. faction .. " faction")
	end

	lu.assertEquals(opens(M.pilot({ pilot = false, tier = 0, paid = 0 })), "not_pilot", "non-pilot who carries the Smuggler squadron")
end

-- S3
-- AC-6, D-6: every pilot who is not a Smuggler meets the off-track greeting, whatever state it carries
function TestSmugglerT2Gates:test_corsec_rsf_rebel_imperial_and_squadronless_pilots_open_off_track()
	lu.assertEquals(opens(M.pilot({ squadron = CORSEC_SQUADRON })), "off_track", "CorSec pilot")
	lu.assertEquals(opens(M.pilot({ squadron = RSF_SQUADRON })), "off_track", "RSF pilot")
	lu.assertEquals(opens(M.pilot({ squadron = false })), "off_track", "neutral pilot without a squadron")
	lu.assertEquals(opens(M.pilot({ pilot = "rebel", squadron = false })), "off_track", "Rebel pilot (SHJ s_4 is NGE-only: rejoined to off_track)")
	lu.assertEquals(opens(M.pilot({ pilot = "rebel", squadron = HAVOC_SQUADRON })), "off_track", "Havoc (Rebel) pilot")
	lu.assertEquals(opens(M.pilot({ pilot = "imperial", squadron = false })), "off_track", "Imperial pilot (SHJ s_6 is NGE-only: rejoined to off_track)")
	lu.assertEquals(opens(M.pilot({ pilot = "imperial", squadron = BLACK_EPSILON_SQUADRON })), "off_track", "Black Epsilon (Imperial) pilot")
end

-- AC-6: the squadron decides, not the Smuggler state it carries
function TestSmugglerT2Gates:test_the_squadron_decides_not_the_state()
	lu.assertEquals(opens(M.pilot({ squadron = CORSEC_SQUADRON, tier2 = 4, all4 = true })), "off_track", "CorSec pilot with a finished tier 2")
	lu.assertEquals(opens(M.pilot({ squadron = RSF_SQUADRON, missions = { [1] = "won" } })), "off_track", "RSF pilot with a won mission 1")
	lu.assertEquals(opens(M.pilot({ squadron = CORSEC_SQUADRON, trans = "none", rewarded = false })), "off_track", "CorSec pilot with no transition")
end

-- S4
-- AC-6: a Smuggler who has not won the transition: none, running, failed
function TestSmugglerT2Gates:test_a_smuggler_who_has_not_won_the_transition_opens_stranger()
	for _, state in ipairs({ "none", "attempted", "active", "child_active", "patrol_only" }) do
		lu.assertEquals(opens(M.pilot({ trans = state, rewarded = false })), "stranger", "transition state " .. state)
	end

	lu.assertEquals(opens(M.pilot({ trans = "none", rewarded = true })), "stranger", "a :reward key without the won chain does not count")
end

-- S5
-- AC-6, AC-7: the chain is won but Shamdon has not paid
function TestSmugglerT2Gates:test_a_smuggler_who_won_the_transition_and_was_not_paid_opens_package()
	lu.assertEquals(opens(M.pilot({ trans = "won", rewarded = false })), "package", "won, no :reward key")
end

-- S4 and S5 keep every pilot who has not delivered away from the missions, training and the on-track duties
function TestSmugglerT2Gates:test_an_undelivered_package_keeps_the_missions_and_training_out_of_reach()
	lu.assertEquals(opens(M.pilot({ trans = "won", rewarded = false, tier2 = 1, xp = 200000 })), "package", "skill held, XP, package undelivered")
	lu.assertEquals(opens(M.pilot({ trans = "won", rewarded = false, xp = 200000 })), "package", "XP and package undelivered")
	lu.assertEquals(opens(M.pilot({ trans = "none", rewarded = false, missions = { [1] = "won" } })), "stranger", "a won mission 1 without the transition")
end

-- S6
-- AC-6, D-13: any space quest in the datapad, a running tier 2 mission or duty
function TestSmugglerT2Gates:test_a_pilot_on_any_quest_opens_busy()
	lu.assertEquals(opens(M.pilot({ datapad = "duty" })), "busy", "a duty of another trainer in the datapad")
	lu.assertEquals(opens(M.pilot({ datapad = "story" })), "busy", "a story mission of another trainer in the datapad")

	for n = 1, 4 do
		lu.assertEquals(opens(M.pilot({ tier2 = 1, missions = { [n] = "active" } })), "busy", "mission " .. n .. " active")
	end

	for _, duty in ipairs(M.DUTIES) do
		lu.assertEquals(opens(M.pilot({ duty2 = duty })), "busy", duty .. " active")
	end

end

-- AC-6, D-13: "on a quest" reads the datapad (SHJ space_quest.hasQuest) and Shamdon's own quests, not a journal entry of another trainer
function TestSmugglerT2Gates:test_a_journal_entry_of_another_trainer_without_a_datapad_mission_does_not_make_shamdon_busy()
	lu.assertEquals(opens(M.pilot({ duty = S.DUTY6 })), "work", "a Dravis duty active in the journal only")
end

-- AC-6, D-13: busy comes before the retries and the rewards
function TestSmugglerT2Gates:test_busy_comes_before_the_retries_and_the_rewards()
	lu.assertEquals(opens(M.pilot({ tier2 = 2, datapad = "duty", missions = { [1] = "attempted" } })), "busy", "failed mission 1 but a duty in the datapad")
	lu.assertEquals(opens(M.pilot({ tier2 = 2, datapad = "story", missions = { [1] = "won" } })), "busy", "won mission 1 but a story mission in the datapad")
	lu.assertEquals(opens(M.pilot({ tier2 = 2, duty2 = M.DUTY_ESCORT, missions = { [2] = "won" } })), "busy", "won mission 2 but a Shamdon duty running")
end

-- S7-S10
-- AC-6: failed or aborted, one retry screen per mission
function TestSmugglerT2Gates:test_a_failed_or_aborted_mission_opens_its_retry_screen()
	for n = 1, 4 do
		lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [n] = "attempted" } })), "m" .. n .. "_retry", "mission " .. n .. " attempted and neither won nor running")
	end
end

-- AC-6: a failed mission is retried even when the skill was bought long ago, and the retry comes before the rewards and the ready mission
function TestSmugglerT2Gates:test_the_retries_keep_their_order()
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [1] = "paid", [2] = "attempted", [3] = "attempted", [4] = "attempted" } })), "m2_retry", "2, 3 and 4 failed: 2 first")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [1] = "attempted", [2] = "won" } })), "m1_retry", "1 failed, 2 won and unpaid: the retry first (S7 before S12)")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [4] = "attempted", [3] = "won" } })), "m4_retry", "4 failed, 3 won and unpaid: the retry first (S10 before S13)")
end

-- S11-S14
-- AC-6: won and unpaid, one reward screen per mission
function TestSmugglerT2Gates:test_a_won_mission_with_the_reward_unpaid_opens_its_reward_screen()
	for n = 1, 4 do
		lu.assertEquals(opens(M.pilot({ tier2 = 1, missions = { [n] = "won" } })), "m" .. n .. "_reward", "mission " .. n .. " won, :reward unset")
	end
end

-- AC-6: the reward rows keep their order
function TestSmugglerT2Gates:test_the_reward_rows_keep_their_order()
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [2] = "won", [3] = "won", [4] = "won" } })), "m2_reward", "2, 3 and 4 won and unpaid: 2 first")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [1] = "won", [4] = "won" } })), "m1_reward", "1 and 4 won and unpaid: 1 first")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [3] = "won", [4] = "won" } })), "m3_reward", "3 and 4 won and unpaid: 3 first")
	lu.assertEquals(opens(M.pilot({ tier2 = 4, missions = { [1] = "paid", [2] = "paid", [3] = "paid", [4] = "won" } })), "m4_reward", "only 4 unpaid")
end

-- S15
-- AC-6, D-3: each tier 2 skill held with its mission never attempted
function TestSmugglerT2Gates:test_each_skill_held_with_its_mission_unattempted_opens_ready_mission()
	for _, t in ipairs(M.TRAIN) do
		lu.assertEquals(opens(M.pilot({ skills2 = { t.x } })), "ready_mission", t.x .. " held, mission " .. t.mission .. " not attempted")
	end
end

-- AC-6: ready_mission comes before the training, whatever the XP
function TestSmugglerT2Gates:test_ready_mission_comes_before_training_even_with_the_xp()
	lu.assertEquals(opens(M.pilot({ skills2 = { "starships" }, xp = 200000 })), "ready_mission", "skill held, 200000 XP")
	lu.assertEquals(opens(M.pilot({ skills2 = { "droid", "weapons" }, xp = 200000, missions = { [2] = "paid" } })), "ready_mission", "droid done and paid, weapons held and unattempted")
end

-- AC-6: a held skill whose mission was done and paid is not waiting
function TestSmugglerT2Gates:test_a_skill_whose_mission_is_paid_is_not_waiting_for_a_mission()
	lu.assertEquals(opens(M.pilot({ skills2 = { "starships" }, missions = { [1] = "paid" }, xp = 0 })), "work", "starships done and paid, no XP")
	lu.assertEquals(opens(M.pilot({ skills2 = { "starships" }, missions = { [1] = "paid" }, xp = 60000 })), "training", "starships done and paid, XP for the next")
end

-- AC-8, D-3: getReadyMission is the smallest mission whose skill is held and whose :attempted key is not set
function TestSmugglerT2Gates:test_getReadyMission_is_the_smallest_waiting_mission_or_nil()
	local h = M.handler()

	lu.assertNil(h:getReadyMission(M.pilot({})), "no tier 2 skill")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "starships" } })), 1, "starships")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "droid" } })), 2, "droid")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "weapons" } })), 3, "weapons")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "procedures" } })), 4, "procedures")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "procedures", "weapons", "droid" } })), 2, "procedures, weapons, droid: the smallest is 2")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "starships", "droid" }, missions = { [1] = "paid" } })), 2, "mission 1 done: 2")
	lu.assertEquals(h:getReadyMission(M.pilot({ skills2 = { "starships" }, missions = { [1] = "attempted" } })), nil, "an attempted mission is not waiting (it is a retry)")
	lu.assertEquals(h:getReadyMission(M.pilot({ tier2 = 4, all4 = true })), nil, "all done")
end

-- S16
-- AC-6, AC-10: all four tier 2 skills held and all four missions paid
function TestSmugglerT2Gates:test_a_tier_2_graduate_opens_bad_news_on_every_visit()
	local player = M.pilot({ all4 = true })

	lu.assertEquals(opens(player), "bad_news", "first visit")
	lu.assertEquals(opens(player), "bad_news", "second visit")
	lu.assertEquals(opens(M.pilot({ all4 = true, xp = 500000 })), "bad_news", "with XP")
end

-- AC-10: the four skills with one mission not won do not make a graduate
function TestSmugglerT2Gates:test_four_skills_with_one_mission_not_won_do_not_open_bad_news()
	for n = 1, 4 do
		local state = M.pilot({ all4 = true, missions = { [n] = "fresh" } })

		lu.assertNotEquals(opens(state), "bad_news", "mission " .. n .. " never done")
	end
end

-- S17
-- AC-6: the XP boundary
function TestSmugglerT2Gates:test_training_needs_60000_space_xp()
	lu.assertEquals(opens(M.pilot({ xp = 59999 })), "work", "59999 XP")
	lu.assertEquals(opens(M.pilot({ xp = 60000 })), "training", "60000 XP")
	lu.assertEquals(opens(M.pilot({ xp = 60000, tier = 3 })), "work", "60000 XP but only three tier 1 skills (training needs tier 1 complete)")
end

-- AC-6: a graduate of some skills is trained for the rest
function TestSmugglerT2Gates:test_training_is_offered_while_a_tier_2_skill_is_missing()
	lu.assertEquals(opens(M.pilot({ skills2 = { "starships", "weapons" }, missions = { [1] = "paid", [3] = "paid" }, xp = 60000 })), "training", "two skills done")
	lu.assertEquals(opens(M.pilot({ skills2 = { "starships", "weapons", "procedures" }, missions = { [1] = "paid", [3] = "paid", [4] = "paid" }, xp = 60000 })), "training", "three skills done")
end

-- S18
-- AC-6: the default
function TestSmugglerT2Gates:test_the_default_is_work()
	lu.assertEquals(opens(M.pilot({})), "work", "no tier 2 skill, no XP")
	lu.assertEquals(opens(M.pilot({ pilotTier = 1 })), "work", "the pilot tier is not read")
	lu.assertEquals(opens(M.pilot({ xp = 10000 })), "work", "some XP")
end

-- AC-6, D-3: a Smuggler who lost the tier 1 skills is not a graduate of tier 1
function TestSmugglerT2Gates:test_a_smuggler_without_the_tier_1_skills_still_gets_work()
	lu.assertEquals(opens(M.pilot({ tier = 3, xp = 60000 })), "work", "three tier 1 skills")
end

-- AC-6: the first screen of every case resolves in the client
function TestSmugglerT2Gates:test_every_first_screen_resolves_in_the_client()
	for _, o in ipairs({ {}, { pilot = false, squadron = false }, { squadron = CORSEC_SQUADRON }, { trans = "none", rewarded = false }, { trans = "won", rewarded = false }, { xp = 60000 },
		{ skills2 = { "droid" } }, { all4 = true }, { datapad = "duty" }, { tier2 = 2, missions = { [2] = "attempted" } } }) do
		H.reset()
		spyAllStarts()

		local t = M.talk(M.pilot(o))

		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the first screen " .. t[1].id)
	end
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track duties
---------------------------------------------------------------------------------------------

TestSmugglerT2OffTrack = {}

TestSmugglerT2OffTrack.setUp = setUp

local function offTrackLink(player)
	local t = M.drive(player, "off_track")

	lu.assertEquals(#t[1].options, 1, "off_track options")
	lu.assertEquals(M.optionSids(t[1]), { "s_c1ff5062" }, "off_track reply")
	return t[1].options[1].link
end

-- AC-6, C-1
function TestSmugglerT2OffTrack:test_a_neutral_pilot_with_all_four_tier_1_skills_and_no_quest_is_offered_the_duties()
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON })), "off_track_duties", "CorSec pilot")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = RSF_SQUADRON })), "off_track_duties", "RSF pilot")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = false })), "off_track_duties", "neutral pilot without a squadron")
end

-- AC-6, C-1: fewer than four tier 1 skills, or any quest in the way
function TestSmugglerT2OffTrack:test_fewer_tier_1_skills_or_a_quest_in_the_way_is_refused()
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON, tier = 3 })), "off_track_refused", "three tier 1 skills")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON, tier = 0 })), "off_track_refused", "no tier 1 skill")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON, datapad = "duty" })), "off_track_refused", "a duty in the datapad")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = RSF_SQUADRON, datapad = "story" })), "off_track_refused", "a story mission in the datapad")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON, duty2 = M.DUTY_ESCORT })), "off_track_refused", "a Shamdon duty running")
	lu.assertEquals(offTrackLink(M.pilot({ squadron = CORSEC_SQUADRON, missions = { [1] = "active" } })), "off_track_refused", "a Shamdon mission running")
end

-- AC-6, C-1, D-6: Rebel and Imperial pilots are always refused, whatever skills they hold
function TestSmugglerT2OffTrack:test_rebel_and_imperial_pilots_are_refused_even_with_their_own_tier_1_complete()
	lu.assertEquals(offTrackLink(M.pilot({ pilot = "rebel", squadron = false })), "off_track_refused", "Rebel pilot")
	lu.assertEquals(offTrackLink(M.pilot({ pilot = "imperial", squadron = false })), "off_track_refused", "Imperial pilot")

	local rebel = M.pilot({ pilot = "rebel", squadron = false, tier = 0, skills = { "pilot_rebel_navy_droid_01", "pilot_rebel_navy_procedures_01", "pilot_rebel_navy_starships_01", "pilot_rebel_navy_weapons_01" } })
	local imperial = M.pilot({ pilot = "imperial", squadron = false, tier = 0, skills = { "pilot_imperial_navy_droid_01", "pilot_imperial_navy_procedures_01", "pilot_imperial_navy_starships_01", "pilot_imperial_navy_weapons_01" } })

	lu.assertEquals(offTrackLink(rebel), "off_track_refused", "Rebel pilot with the four Rebel tier 1 skills")
	lu.assertEquals(offTrackLink(imperial), "off_track_refused", "Imperial pilot with the four Imperial tier 1 skills")
end

-- AC-6, C-1: the three duties start their quest on display (the duty screens end the talk)
function TestSmugglerT2OffTrack:test_the_three_duties_start_their_quest_once()
	local cases = { { "duty_escort", M.DUTY_ESCORT }, { "duty_recovery", M.DUTY_RECOVERY }, { "duty_destroy", M.DUTY_DESTROY } }

	for i, c in ipairs(cases) do
		H.reset()

		local spies = spyAllStarts()
		local player = M.pilot({ squadron = CORSEC_SQUADRON })
		local t = M.talk(player, { "s_c1ff5062", ({ "s_c631f8da", "s_6ff30da7", "s_93ba78e7" })[i] })

		lu.assertEquals(M.ids(t), { "off_track", "off_track_duties", c[1] }, "walk to " .. c[1])
		lu.assertTrue(t[#t].stop, c[1] .. " ends the conversation")
		lu.assertEquals(#spies[c[2]], 1, c[2] .. ":startQuest calls")
		lu.assertEquals(spies[c[2]][1].args[1], player, c[2] .. ":startQuest gets the pilot")

		for _, g in ipairs(M.DUTIES) do
			if g ~= c[2] then
				lu.assertEquals(#spies[g], 0, g .. ":startQuest calls while taking " .. c[1])
			end
		end

		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the walk to " .. c[1])
	end
end

-- AC-6: a refused pilot ends on off_track_refused and nothing starts
function TestSmugglerT2OffTrack:test_a_refused_pilot_ends_on_the_refusal_and_starts_nothing()
	local spies = spyAllStarts()
	local t = M.talk(M.pilot({ pilot = "rebel", squadron = false }), { "s_c1ff5062" })

	lu.assertEquals(M.ids(t), { "off_track", "off_track_refused" }, "walk")
	lu.assertTrue(t[2].stop, "the refusal ends the conversation")

	for g, calls in pairs(spies) do
		lu.assertEquals(#calls, 0, g .. ":startQuest calls")
	end
end

-- AC-6, C-1: canFlyNonTrackDuty is SHJ:159-166 plus the neutral check
function TestSmugglerT2OffTrack:test_canFlyNonTrackDuty_helper()
	local h = M.handler()

	lu.assertTrue(h:canFlyNonTrackDuty(M.pilot({ squadron = CORSEC_SQUADRON })), "CorSec, tier 1 complete, free")
	lu.assertFalse(h:canFlyNonTrackDuty(M.pilot({ squadron = CORSEC_SQUADRON, tier = 3 })), "three skills")
	lu.assertFalse(h:canFlyNonTrackDuty(M.pilot({ pilot = "rebel", squadron = false })), "Rebel pilot")
	lu.assertFalse(h:canFlyNonTrackDuty(M.pilot({ pilot = "imperial", squadron = false })), "Imperial pilot")
	lu.assertFalse(h:canFlyNonTrackDuty(M.pilot({ squadron = CORSEC_SQUADRON, datapad = "duty" })), "a quest in the datapad")
	lu.assertFalse(h:canFlyNonTrackDuty(M.pilot({ squadron = CORSEC_SQUADRON, duty2 = M.DUTY_DESTROY })), "a Shamdon duty running")
end

---------------------------------------------------------------------------------------------
-- The stranger and the work offer
---------------------------------------------------------------------------------------------

TestSmugglerT2Walks = {}

TestSmugglerT2Walks.setUp = setUp

-- AC-6 (Conversation flow 6): the stranger
function TestSmugglerT2Walks:test_the_stranger_walks()
	local player = M.pilot({ trans = "none", rewarded = false })

	lu.assertEquals(M.ids(M.talk(player, { "s_d01d0154" })), { "stranger", "never_mind" }, "No, never mind.")
	lu.assertEquals(M.ids(M.talk(player, { "s_aed52b48", "s_bb27779e" })), { "stranger", "talon_only", "talon_what" }, "What would I have?")
	lu.assertEquals(M.ids(M.talk(player, { "s_aed52b48", "s_32965dab" })), { "stranger", "talon_only", "talon_who_male" }, "Who is Talon Karrde? (a man)")
	lu.assertEquals(M.ids(M.talk(M.pilot({ trans = "none", rewarded = false, gender = 1 }), { "s_aed52b48", "s_32965dab" })), { "stranger", "talon_only", "talon_who_female" },
		"Who is Talon Karrde? (a woman, C-2)")

	for _, id in ipairs({ "never_mind", "talon_who_male", "talon_who_female", "talon_what" }) do
		lu.assertTrue(M.screenRow(id).stop, id .. " ends the conversation")
	end
end

-- AC-6 (Conversation flow 6): the default work offer
function TestSmugglerT2Walks:test_the_work_offer_walks()
	local spies = spyAllStarts()
	local player = M.pilot({})

	lu.assertEquals(M.ids(M.talk(player, { "s_1aaeed53" })), { "work", "work_no" }, "no")

	local cases = { { "s_c631f8da", "duty_escort", M.DUTY_ESCORT }, { "s_6ff30da7", "duty_recovery", M.DUTY_RECOVERY }, { "s_93ba78e7", "duty_destroy", M.DUTY_DESTROY } }

	for _, c in ipairs(cases) do
		H.reset()
		spies = spyAllStarts()

		local p = M.pilot({})
		local t = M.talk(p, { "s_f4b9423e", c[1] })

		lu.assertEquals(M.ids(t), { "work", "duty_offer", c[2] }, "walk to " .. c[2])
		lu.assertEquals(#spies[c[3]], 1, c[3] .. ":startQuest calls")
		lu.assertEquals(spies[c[3]][1].args[1], p, c[3] .. ":startQuest gets the pilot")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the walk to " .. c[2])
	end
end

---------------------------------------------------------------------------------------------
-- Helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestSmugglerT2Helpers = {}

TestSmugglerT2Helpers.setUp = setUp

-- AC-1, AC-6: isWon / isActive / hasStatus / isFailed / isOnMission / isTransPaid
function TestSmugglerT2Helpers:test_mission_state_helpers()
	local h = M.handler()

	for n = 1, 4 do
		lu.assertFalse(h:isWon(M.pilot({}), n), "fresh " .. n .. ": isWon")
		lu.assertFalse(h:isActive(M.pilot({}), n), "fresh " .. n .. ": isActive")
		lu.assertFalse(h:isFailed(M.pilot({}), n), "fresh " .. n .. ": isFailed")

		local won = M.pilot({ missions = { [n] = "won" } })

		lu.assertTrue(h:isWon(won, n), "won " .. n .. ": isWon")
		lu.assertTrue(h:hasStatus(won, n, ":attempted"), "won " .. n .. ": attempted")
		lu.assertFalse(h:hasStatus(won, n, ":reward"), "won " .. n .. ": reward unset")
		lu.assertFalse(h:isFailed(won, n), "won " .. n .. ": isFailed")

		local paid = M.pilot({ missions = { [n] = "paid" } })

		lu.assertTrue(h:hasStatus(paid, n, ":reward"), "paid " .. n .. ": reward")

		local active = M.pilot({ missions = { [n] = "active" } })

		lu.assertTrue(h:isActive(active, n), "active " .. n .. ": isActive")
		lu.assertFalse(h:isFailed(active, n), "active " .. n .. ": isFailed")
		lu.assertTrue(h:isOnMission(active), "active " .. n .. ": isOnMission")

		local failed = M.pilot({ missions = { [n] = "attempted" } })

		lu.assertTrue(h:isFailed(failed, n), "failed " .. n .. ": isFailed")
		lu.assertFalse(h:isWon(failed, n), "failed " .. n .. ": isWon")
		lu.assertFalse(h:isOnMission(failed), "failed " .. n .. ": isOnMission")
	end

	for _, duty in ipairs(M.DUTIES) do
		lu.assertTrue(h:isOnMission(M.pilot({ duty2 = duty })), duty .. ": isOnMission")
	end

	lu.assertFalse(h:isOnMission(M.pilot({})), "isOnMission with nothing")
	lu.assertTrue(h:isTransPaid(M.pilot({})), "isTransPaid with the default pilot")
	lu.assertFalse(h:isTransPaid(M.pilot({ rewarded = false })), "isTransPaid before Shamdon pays")
end

-- AC-8, D-3: isReadyForTraining = tier 1 complete, tier 2 not complete, 60000 XP, no waiting mission
function TestSmugglerT2Helpers:test_isReadyForTraining()
	local h = M.handler()

	lu.assertTrue(h:isReadyForTraining(M.pilot({ xp = 60000 })), "60000 XP")
	lu.assertFalse(h:isReadyForTraining(M.pilot({ xp = 59999 })), "59999 XP")
	lu.assertFalse(h:isReadyForTraining(M.pilot({ xp = 60000, tier = 3 })), "three tier 1 skills")
	lu.assertFalse(h:isReadyForTraining(M.pilot({ xp = 60000, skills2 = { "droid" } })), "a skill is waiting for its mission")
	lu.assertTrue(h:isReadyForTraining(M.pilot({ xp = 60000, skills2 = { "droid" }, missions = { [2] = "paid" } })), "that mission is done")
	lu.assertFalse(h:isReadyForTraining(M.pilot({ xp = 600000, all4 = true })), "tier 2 complete")
end

---------------------------------------------------------------------------------------------
-- I-9: the gates are pure
---------------------------------------------------------------------------------------------

TestSmugglerT2PureGates = {}

TestSmugglerT2PureGates.setUp = setUp

-- every pilot of AC-6, by name
local PILOTS = {
	{ "default", {} },
	{ "no_ship", { ship = false } },
	{ "non_pilot", { pilot = false, squadron = false, tier = 0, paid = 0 } },
	{ "rebel_pilot", { pilot = "rebel", squadron = false } },
	{ "imperial_pilot", { pilot = "imperial", squadron = false } },
	{ "corsec_pilot", { squadron = CORSEC_SQUADRON } },
	{ "rsf_pilot", { squadron = RSF_SQUADRON } },
	{ "no_trans", { trans = "none", rewarded = false } },
	{ "trans_active", { trans = "active", rewarded = false } },
	{ "trans_failed", { trans = "attempted", rewarded = false } },
	{ "package", { trans = "won", rewarded = false } },
	{ "foreign_quest_in_datapad", { datapad = "story" } },
	{ "duty_active", { duty2 = "escort_duty_tatooine_privateer_tier2_1" } },
	{ "m1_active", { tier2 = 1, missions = { [1] = "active" } } },
	{ "m1_failed", { tier2 = 1, missions = { [1] = "attempted" } } },
	{ "m2_failed", { tier2 = 4, missions = { [2] = "attempted" } } },
	{ "m3_failed", { tier2 = 4, missions = { [3] = "attempted" } } },
	{ "m4_failed", { tier2 = 4, missions = { [4] = "attempted" } } },
	{ "m1_won", { tier2 = 1, missions = { [1] = "won" } } },
	{ "m2_won", { tier2 = 2, missions = { [2] = "won" } } },
	{ "m3_won", { tier2 = 3, missions = { [3] = "won" } } },
	{ "m4_won", { tier2 = 4, missions = { [4] = "won" } } },
	{ "ready_starships", { skills2 = { "starships" } } },
	{ "ready_droid", { skills2 = { "droid" } } },
	{ "ready_weapons", { skills2 = { "weapons" } } },
	{ "ready_procedures", { skills2 = { "procedures" } } },
	{ "graduate", { all4 = true } },
	{ "xp_59999", { xp = 59999 } },
	{ "xp_60000", { xp = 60000 } },
}

-- I-9: no quest start, journal write, status key, skill grant, credit, item, pilot tier change on the first screen
function TestSmugglerT2PureGates:test_getInitialScreen_changes_nothing_for_any_pilot()
	local starts = spyAllStarts()

	for _, p in ipairs(PILOTS) do
		local name, opts = p[1], p[2]
		local player = M.pilot(opts)
		local before = MS.snapshot(player)
		local mine = M.snapshot(player)
		local sideBefore = MS.sideEffects(player)
		local items0, ships0 = #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip")
		local n0 = {}

		for g, calls in pairs(starts) do
			n0[g] = #calls
		end

		local screen = M.handler():getInitialScreen(player, M.npc(), H.conversationTemplate(M.TEMPLATE))

		lu.assertNotNil(screen, name .. ": a first screen")
		lu.assertEquals(MS.snapshot(player), before, name .. ": journal, statuses, observers, waypoints, datapad and shared memory")
		lu.assertEquals(MS.sideEffects(player), sideBefore, name .. ": messages, music and events")
		lu.assertEquals(M.snapshot(player), mine, name .. ": skills, credits, pilot tier, items, spawned ships")
		lu.assertEquals({ #H.Engine.callsTo("giveItem"), #H.Engine.callsTo("grantStarterShip") }, { items0, ships0 }, name .. ": giveItem, grantStarterShip calls")

		for g, calls in pairs(starts) do
			lu.assertEquals(#calls, n0[g], name .. ": " .. g .. ":startQuest calls")
		end
	end
end

-- I-9: the first screen is the same on every call
function TestSmugglerT2PureGates:test_getInitialScreen_answers_the_same_every_time()
	for _, p in ipairs(PILOTS) do
		local player = M.pilot(p[2])
		local first = screenId(M.handler():getInitialScreen(player, M.npc(), H.conversationTemplate(M.TEMPLATE)))
		local again = screenId(M.handler():getInitialScreen(player, M.npc(), H.conversationTemplate(M.TEMPLATE)))

		lu.assertEquals(again, first, p[1] .. ": the screen of a repeated call")
	end
end

-- AC-6: getInitialScreen and the first screen shown agree (the screen handlers only add to it)
function TestSmugglerT2PureGates:test_the_first_screen_shown_is_the_one_getInitialScreen_returns()
	for _, p in ipairs(PILOTS) do
		H.reset()
		spyAllStarts()

		local player = M.pilot(p[2])
		local id = screenId(M.handler():getInitialScreen(player, M.npc(), H.conversationTemplate(M.TEMPLATE)))

		lu.assertEquals(M.talk(player)[1].id, id, p[1] .. ": the first screen shown")
	end
end
