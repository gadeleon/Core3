-- Prisk Kith'Vys: which screen a pilot opens on (gate table P), the conditional link C-1 and the public helpers.
-- Spec: .claude/work/black-epsilon-tier2-prisk/01-spec.md (AC-6, AC-10; Conversation flow 1 and 2; FP-3, FP-4, FP-5; D-3, D-4, D-5, D-6, D-8).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- black_epsilon_tier2_data.lua P.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local P = require("black_epsilon_tier2_data")
local CS = require("harness.client_strings")

P.load()

TestBlackEpsilonT2Gates = {}

function TestBlackEpsilonT2Gates:setUp()
	H.reset()
	P.requireConversation(lu)
end

local function opens(player) return P.firstScreen(player) end

local function handler() return rawget(_G, P.HANDLER) end

local ALL = { 1, 2, 3, 4 } -- TRAIN indexes of every tier 2 skill
local PAID = { 1, 2, 3, 4 } -- missions 1..4

-- P0
-- AC-6
function TestBlackEpsilonT2Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = P.pilot(), P.npc(), H.conversationTemplate(P.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- P1 (D-8)
-- AC-6
function TestBlackEpsilonT2Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(P.pilot()), "not_pilot", "JTL disabled")
	lu.assertEquals(opens(P.pilot({ standing = -1 })), "not_pilot", "JTL disabled beats the wanted gate")
end

-- P1
-- AC-6
function TestBlackEpsilonT2Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = P.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- P2
-- AC-6
function TestBlackEpsilonT2Gates:test_a_neutral_pilot_opens_privateer()
	lu.assertEquals(opens(P.pilot({ pilot = "neutral", squadron = false })), "privateer", "neutral pilot, Imperial faction")
	lu.assertEquals(opens(P.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "privateer", "neutral pilot, no faction")
	lu.assertEquals(opens(P.pilot({ pilot = "neutral", squadron = false, standing = -5 })), "privateer", "the privateer gate comes before the wanted gate")
end

-- P3
-- AC-6
function TestBlackEpsilonT2Gates:test_rebel_faction_or_a_rebel_pilot_opens_rebel()
	lu.assertEquals(opens(P.pilot({ faction = "rebel" })), "rebel", "imperial pilot with rebel faction")
	lu.assertEquals(opens(P.pilot({ pilot = "rebel", faction = "neutral", squadron = false })), "rebel", "rebel pilot")
	lu.assertEquals(opens(P.pilot({ pilot = false, faction = "rebel", squadron = false })), "rebel", "rebel faction non-pilot")
	lu.assertEquals(opens(P.pilot({ faction = "rebel", standing = -5 })), "rebel", "the rebel gate comes before the wanted gate")
end

-- P4
-- AC-6
function TestBlackEpsilonT2Gates:test_a_pilot_who_is_not_an_imperial_pilot_opens_not_pilot()
	lu.assertEquals(opens(P.pilot({ pilot = false, squadron = false })), "not_pilot", "Imperial faction, no pilot skills")
	lu.assertEquals(opens(P.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_pilot", "no faction, no pilot skills")
	lu.assertEquals(opens(P.pilot({ pilot = false, squadron = false, standing = -3 })), "not_pilot", "a non-pilot is refused before the wanted gate")
end

-- P5 (FP-3, D-5)
-- AC-6
function TestBlackEpsilonT2Gates:test_negative_imperial_standing_opens_wanted_male_for_a_male_pilot()
	lu.assertEquals(opens(P.pilot({ standing = -1 })), "wanted_male", "member, standing -1")
	lu.assertEquals(opens(P.pilot({ standing = -300, gender = 0 })), "wanted_male", "member, standing -300")
	lu.assertEquals(opens(P.pilot({ standing = 0 })) ~= "wanted_male", true, "standing 0 is not wanted")
end

-- P6 (FP-3, D-5)
-- AC-6
function TestBlackEpsilonT2Gates:test_negative_imperial_standing_opens_wanted_female_for_a_female_pilot()
	lu.assertEquals(opens(P.pilot({ standing = -1, gender = 1 })), "wanted_female", "member, standing -1")
	lu.assertEquals(opens(P.pilot({ standing = 0, gender = 1 })) ~= "wanted_female", true, "standing 0 is not wanted")
end

-- P5, P6: the wanted gate covers every Imperial pilot, on or off the track, and comes before every later gate
-- AC-6
function TestBlackEpsilonT2Gates:test_the_wanted_gate_comes_before_the_track_missions_and_final_gates()
	lu.assertEquals(opens(P.pilot({ standing = -1, squadron = false })), "wanted_male", "other squadron (the gate is not member-only in J)")
	lu.assertEquals(opens(P.pilot({ standing = -1, gender = 1, squadron = false })), "wanted_female", "other squadron, female")
	lu.assertEquals(opens(P.pilot({ standing = -1, opening = "won", t2 = { 1 } })), "wanted_male", "a ready mission")
	lu.assertEquals(opens(P.pilot({ standing = -1, opening = "won", t2 = ALL, paid = PAID, mission = { final = "won" } })), "wanted_male", "tour complete")
	lu.assertEquals(opens(P.pilot({ standing = -1, gender = 1, opening = "won", t2 = ALL, paid = PAID })), "wanted_female", "the final offer")
	lu.assertEquals(opens(P.pilot({ standing = -1, opening = "active" })), "wanted_male", "a mission running")
end

-- P5, P6: the wanted dialogue grants nothing, in both genders, and is lifted at standing 0
-- AC-6
function TestBlackEpsilonT2Gates:test_the_wanted_dialogue_walks_to_the_end_and_grants_nothing()
	local walks = {
		{ gender = 0, ids = { "wanted_male", "enemy_male", "cannot_trust_male", "prove_devotion", "not_ahead" } },
		{ gender = 1, ids = { "wanted_female", "enemy_female", "cannot_trust_female", "prove_devotion", "not_ahead" } },
	}

	for _, w in ipairs(walks) do
		H.reset()

		local spies = P.spyStarts()
		local player = P.pilot({ standing = -3, gender = w.gender, opening = "won", t2 = { 1 } })
		local t = P.talk(player, { "s_7090182", "s_ecb17e60", "s_5b204877", "s_71d84d34" })

		lu.assertEquals(P.ids(t), w.ids, "gender " .. w.gender .. ": screens shown")
		lu.assertTrue(t[#t].stop, "not_ahead ends the conversation")
		lu.assertEquals(P.started(spies), {}, "no quest started")
		lu.assertEquals(#P.free() + #P.bought(), 0, "no skill granted")
		lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
		lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
	end
end

-- P5, P6: raising the standing to 0 lifts the gate
-- AC-6
function TestBlackEpsilonT2Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = P.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted_male", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "hakassha_sent", "standing 0")
end

-- P7
-- AC-6
function TestBlackEpsilonT2Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track()
	lu.assertEquals(opens(P.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "Storm Squadron pilot")
	lu.assertEquals(opens(P.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(P.pilot({ squadron = false, opening = "won", t2 = ALL, paid = PAID })), "off_track", "other squadron with Black Epsilon state: the track check comes first")
end

-- P8 (D-3)
-- AC-6, AC-7
function TestBlackEpsilonT2Gates:test_a_skill_held_with_its_mission_not_attempted_opens_assignment_waiting()
	for i, t in ipairs(P.TRAIN) do
		H.reset()
		lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { i } })), "assignment_waiting", t.x .. " held, mission " .. t.mission .. " not attempted")
	end

	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1 }, standing = 0 })), "assignment_waiting", "standing 0")
end

-- P8: a duty or a datapad quest does not outrank the ready mission (J order, 4906 before 5015)
-- AC-6
function TestBlackEpsilonT2Gates:test_a_ready_mission_comes_before_the_on_mission_gate()
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1 }, duty = P.DUTY8 })), "assignment_waiting", "a duty running")
end

-- P8: the opening must be won for a mission to be ready (D-3: admin-granted skills offer nothing early)
-- AC-6
function TestBlackEpsilonT2Gates:test_a_skill_without_the_opening_won_does_not_make_a_mission_ready()
	lu.assertEquals(opens(P.pilot({ t2 = { 1 } })), "hakassha_sent", "skill held, opening never flown")
	lu.assertEquals(opens(P.pilot({ opening = "failed", t2 = { 1 } })), "opening_failed", "skill held, opening failed")
end

-- P9
-- AC-6, AC-10
function TestBlackEpsilonT2Gates:test_the_survival_won_opens_tour_complete()
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = PAID, mission = { final = "won" } })), "tour_complete", "final won")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = PAID, mission = { final = "won" }, xp = 500000 })), "tour_complete", "final won with XP to spare")
end

-- P10 (D-6)
-- AC-6, AC-10
function TestBlackEpsilonT2Gates:test_a_running_mission_duty_or_any_datapad_space_quest_opens_on_mission()
	lu.assertEquals(opens(P.pilot({ opening = "active" })), "on_mission", "opening running")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1 }, mission = { [1] = "active" } })), "on_mission", "mission 1 running")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1, 4 }, paid = { 1 }, mission = { [2] = "active" } })), "on_mission", "mission 2 running")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1, 4, 2 }, paid = { 1, 2 }, mission = { [3] = "active" } })), "on_mission", "mission 3 running")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "active" } })), "on_mission", "mission 4 running")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = PAID, mission = { final = "active" } })), "on_mission", "the final running")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 60000, duty = P.DUTY8 })), "on_mission", "destroy duty running, training XP in hand")
	lu.assertEquals(opens(P.pilot({ opening = "won", duty = P.DUTY9 })), "on_mission", "escort duty running")
	lu.assertEquals(opens(P.pilot({ opening = "won", duty = P.DUTY10 })), "on_mission", "second destroy duty running")
	lu.assertEquals(opens(P.pilot({ opening = "won", duty = P.DUTY11 })), "on_mission", "second escort duty running")
	lu.assertEquals(opens(P.pilot({ opening = "won", datapad = "story" })), "on_mission", "a story mission in the datapad")
	lu.assertEquals(opens(P.pilot({ opening = "won", datapad = "duty" })), "on_mission", "a duty in the datapad")
	lu.assertEquals(opens(P.pilot({ datapad = "story" })), "on_mission", "a space quest of another trainer, before the opening")
end

-- P10 (D-6, AC-10): while any space quest is active the final is never offered, retried or reported
-- AC-10
function TestBlackEpsilonT2Gates:test_the_final_offer_the_final_retry_and_the_tour_report_wait_for_the_running_quest()
	local done = { opening = "won", t2 = ALL, paid = PAID }

	local function with(extra)
		local o = {}

		for k, v in pairs(done) do
			o[k] = v
		end

		for k, v in pairs(extra) do
			o[k] = v
		end

		return o
	end

	lu.assertEquals(opens(P.pilot(with({ datapad = "story" }))), "on_mission", "final offer + datapad quest")
	lu.assertEquals(opens(P.pilot(with({ duty = P.DUTY8 }))), "on_mission", "final offer + duty running")
	lu.assertEquals(opens(P.pilot(with({ mission = { final = "failed" }, datapad = "story" }))), "on_mission", "final retry + datapad quest")
	lu.assertEquals(opens(P.pilot(with({ mission = { final = "failed" }, duty = P.DUTY9 }))), "on_mission", "final retry + duty running")
end

-- P11 (D-6)
-- AC-6, AC-7
function TestBlackEpsilonT2Gates:test_the_final_attempted_and_not_won_opens_final_retry()
	local done = { opening = "won", t2 = ALL, paid = PAID }

	done.mission = { final = "failed" }
	lu.assertEquals(opens(P.pilot(done)), "final_retry", "final attempted, nothing complete, nothing active")

	local player = P.pilot(done)

	P.setState(player, P.A17, "complete")
	lu.assertEquals(opens(player), "final_retry", "assassinate 17 complete, the survival never flown or failed")
end

-- P12 (D-6)
-- AC-6, AC-10
function TestBlackEpsilonT2Gates:test_four_tier_2_skills_and_four_rewards_open_final_offer()
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = PAID })), "final_offer", "four skills, four rewards")
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = PAID, xp = 100000 })), "final_offer", "with XP to spare")
end

-- P12 (FP-5, D-6, AC-10): the final is never offered while a reward is unpaid, whichever skill was bought last
-- AC-10
function TestBlackEpsilonT2Gates:test_the_final_is_not_offered_while_any_of_the_four_rewards_is_unpaid()
	local names = { [1] = "m12_won", [2] = "m13_won", [3] = "m14_won", [4] = "m15_won" }

	for n = 1, 4 do
		H.reset()

		local paid = {}

		for i = 1, 4 do
			if i ~= n then
				paid[#paid + 1] = i
			end
		end

		lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = paid, mission = { [n] = "won" } })), names[n], "mission " .. n .. " won, reward unpaid")
	end
end

-- P12 (AC-10): a mission that was never flown shows its briefing first, not the final
-- AC-10
function TestBlackEpsilonT2Gates:test_the_final_is_not_offered_while_a_mission_was_never_attempted()
	for n = 1, 4 do
		H.reset()

		local paid = {}

		for i = 1, 4 do
			if i ~= n then
				paid[#paid + 1] = i
			end
		end

		lu.assertEquals(opens(P.pilot({ opening = "won", t2 = ALL, paid = paid })), "assignment_waiting", "mission " .. n .. " never attempted: its briefing is waiting")
	end
end

-- P13
-- AC-6, AC-7
function TestBlackEpsilonT2Gates:test_the_opening_attempted_and_not_won_opens_opening_failed()
	lu.assertEquals(opens(P.pilot({ opening = "failed" })), "opening_failed", "attempted, nothing complete")
	lu.assertEquals(opens(P.pilot({ opening = "attempted" })), "opening_failed", "just the :attempted key")
	lu.assertEquals(opens(P.pilot({ opening = "failed", xp = 100000 })), "opening_failed", "XP to spare does not offer training")
end

-- P14 .. P21: one row per mission
local MISSIONS = {
	{ n = 1, skill = 1, retry = "m12_retry", won = "m12_won" },
	{ n = 2, skill = 4, retry = "m13_retry", won = "m13_won" },
	{ n = 3, skill = 2, retry = "m14_retry", won = "m14_won" },
	{ n = 4, skill = 3, retry = "m15_retry", won = "m15_won" },
}

for _, m in ipairs(MISSIONS) do
	-- P14 .. P17
	-- AC-6, AC-7
	TestBlackEpsilonT2Gates["test_mission_" .. m.n .. "_attempted_and_not_won_opens_" .. m.retry] = function(self)
		lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { m.skill }, mission = { [m.n] = "failed" } })), m.retry, "mission " .. m.n .. " attempted, nothing complete, nothing active")
	end

	-- P18 .. P21
	-- AC-6, AC-8
	TestBlackEpsilonT2Gates["test_mission_" .. m.n .. "_won_and_unpaid_opens_" .. m.won] = function(self)
		lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { m.skill }, mission = { [m.n] = "won" } })), m.won, "mission " .. m.n .. " won, reward unpaid")
	end

	-- P22: a paid mission does not show again
	-- AC-6, AC-8
	TestBlackEpsilonT2Gates["test_mission_" .. m.n .. "_paid_shows_neither_its_won_nor_its_retry_screen"] = function(self)
		local id = opens(P.pilot({ opening = "won", t2 = { m.skill }, paid = { m.n } }))

		lu.assertNotEquals(id, m.won, "paid: no won screen")
		lu.assertNotEquals(id, m.retry, "paid: no retry screen")
	end
end

-- P17, P21 (Data mapping 1): mission 4 counts as won only when the patrol and its surprise attack are both complete
-- AC-6, AC-8
function TestBlackEpsilonT2Gates:test_mission_4_with_only_the_patrol_complete_is_not_won()
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 3 }, mission = { [4] = "won4patrol" } })), "m15_retry", "patrol complete, surprise attack never flown")
end

-- P14 .. P17 (D-6): the retries come after the on-mission gate
-- AC-6
function TestBlackEpsilonT2Gates:test_a_failed_mission_waits_for_a_running_quest()
	lu.assertEquals(opens(P.pilot({ opening = "won", t2 = { 1 }, mission = { [1] = "failed" }, duty = P.DUTY8 })), "on_mission", "mission 1 failed, a duty running")
	lu.assertEquals(opens(P.pilot({ opening = "failed", datapad = "story" })), "on_mission", "opening failed, a datapad quest")
end

-- P22 (FP-5, D-6)
-- AC-6, AC-9
function TestBlackEpsilonT2Gates:test_the_opening_won_with_the_four_tier_1_skills_and_60000_xp_opens_training_menu()
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 60000 })), "training_menu", "no tier 2 skill yet")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 60000, t2 = { 1 }, paid = { 1 } })), "training_menu", "one skill bought and its mission paid")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 200000, t2 = { 1, 4, 2 }, paid = { 1, 2, 3 } })), "training_menu", "three skills, their missions paid")
end

-- P22
-- AC-9
function TestBlackEpsilonT2Gates:test_training_is_not_offered_without_the_xp_the_opening_or_the_tier_1_skills()
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 59999 })), "opening_done", "59999 XP")
	lu.assertEquals(opens(P.pilot({ xp = 100000 })), "hakassha_sent", "the opening never flown (FP-5)")
	lu.assertEquals(opens(P.pilot({ opening = "failed", xp = 100000 })), "opening_failed", "the opening failed")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 100000, tier1 = 3 })), "opening_done", "only three tier 1 skills")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 100000, tier1 = 0 })), "opening_done", "no tier 1 skill")
end

-- P23
-- AC-6
function TestBlackEpsilonT2Gates:test_the_opening_won_without_training_xp_opens_opening_done()
	lu.assertEquals(opens(P.pilot({ opening = "won" })), "opening_done", "no XP")
	lu.assertEquals(opens(P.pilot({ opening = "won", xp = 59999, t2 = { 1 }, paid = { 1 } })), "opening_done", "a skill bought, too little XP for the next")
end

-- P24 (FP-4, D-4)
-- AC-6
function TestBlackEpsilonT2Gates:test_the_series_flag_alone_opens_hakassha_sent()
	lu.assertEquals(opens(P.pilot({})), "hakassha_sent", "series flag, nothing else")
end

-- P25 (FP-4, D-4)
-- AC-6
function TestBlackEpsilonT2Gates:test_a_black_epsilon_pilot_without_the_series_flag_opens_see_hakassha()
	lu.assertEquals(opens(P.pilot({ series = false })), "see_hakassha", "tier 1 skills, no series key")
	lu.assertEquals(opens(P.pilot({ series = false, tier1 = 0, pilotTier = 1 })), "see_hakassha", "no skills")
end

-- P24, P25 (AC-6, D-4): the tier 1 Prisk flag alone does not open hakassha_sent
function TestBlackEpsilonT2Gates:test_the_prisk_flag_without_the_series_key_does_not_open_hakassha_sent()
	lu.assertEquals(opens(P.pilot({ series = false, prisk = true })), "see_hakassha", "Prisk flag only")
	lu.assertEquals(opens(P.pilot({ series = true, prisk = true })), "hakassha_sent", "both flags")
end

-- P24: the key is the squadron constant, stored as <playerID><key>
-- AC-6
function TestBlackEpsilonT2Gates:test_the_series_key_is_the_squadron_constant()
	local player = P.pilot({ series = false })

	H.setQuestStatus(player, BlackEpsilonSquadronScreenplay.SERIES_COMPLETE_KEY, "1")
	lu.assertEquals(opens(player), "hakassha_sent", "series set through the squadron constant")
end

-- AC-6: every gate screen exists in the template
function TestBlackEpsilonT2Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(P.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_pilot", "privateer", "rebel", "wanted_male", "wanted_female", "off_track", "assignment_waiting", "tour_complete", "on_mission", "final_retry", "final_offer",
		"opening_failed", "m12_retry", "m13_retry", "m14_retry", "m15_retry", "m12_won", "m13_won", "m14_won", "m15_won", "training_menu", "opening_done", "hakassha_sent", "see_hakassha" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(P.TEMPLATE)):getScreen(id), P.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

-- AC-5, AC-6: the refusals are one-line endings
function TestBlackEpsilonT2Gates:test_the_one_line_refusals_end_the_conversation()
	local cases = {
		{ P.pilot({ pilot = "neutral", squadron = false }), "privateer", "s_fc007f1" },
		{ P.pilot({ faction = "rebel" }), "rebel", "s_dbf39d2a" },
		{ P.pilot({ pilot = false, squadron = false }), "not_pilot", "s_4391b2de" },
	}

	for _, c in ipairs(cases) do
		local t = P.talk(c[1])

		lu.assertEquals(P.ids(t), { c[2] }, c[2] .. ": screens shown")
		lu.assertTrue(t[1].stop, c[2] .. " ends the conversation")
		lu.assertEquals(t[1].text, P.PREFIX .. c[3], c[2] .. ": the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end
end

---------------------------------------------------------------------------------------------
-- C-1: the off-track pilot's mission request
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2OffTrack = {}

function TestBlackEpsilonT2OffTrack:setUp()
	H.reset()
	P.requireConversation(lu)
end

local ASK = "s_4854758d"

-- C-1
-- AC-6
function TestBlackEpsilonT2OffTrack:test_the_request_leads_to_the_duty_offer_when_the_pilot_has_the_four_tier_1_skills_and_flies_nothing()
	local t = P.talk(P.pilot({ squadron = false }), { ASK })

	lu.assertEquals(P.ids(t), { "off_track", "off_track_duties" }, "four tier 1 skills, no mission, empty datapad")
	lu.assertEquals(P.optionSids(t[2]), { "s_bd5df827", "s_798fbe2", "s_1a0f022", "s_3e38e6a0" }, "the four duty replies")
	lu.assertEquals(P.linksOf(t[2]), { "duty_pirates", "duty_merchant", "duty_rebels", "duty_security" }, "the four duty links")
end

-- C-1
-- AC-6
function TestBlackEpsilonT2OffTrack:test_the_request_is_refused_without_all_four_tier_1_skills()
	local t = P.talk(P.pilot({ squadron = false, tier1 = 3 }), { ASK })

	lu.assertEquals(P.ids(t), { "off_track", "off_track_no_missions" }, "three tier 1 skills")
	lu.assertTrue(t[2].stop, "off_track_no_missions ends the conversation")
	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, tier1 = 0 }), { ASK })), { "off_track", "off_track_no_missions" }, "no tier 1 skill")
end

-- C-1
-- AC-6
function TestBlackEpsilonT2OffTrack:test_the_request_is_refused_with_any_space_quest_in_the_datapad()
	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, datapad = "story" }), { ASK })), { "off_track", "off_track_no_missions" }, "a story mission in the datapad")
	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, datapad = "duty" }), { ASK })), { "off_track", "off_track_no_missions" }, "a duty in the datapad")
end

-- C-1
-- AC-6
function TestBlackEpsilonT2OffTrack:test_the_request_is_refused_while_one_of_prisks_quests_is_active()
	for _, duty in ipairs(P.DUTIES) do
		lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, duty = duty }), { ASK })), { "off_track", "off_track_no_missions" }, duty .. " active")
	end

	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, opening = "active" }), { ASK })), { "off_track", "off_track_no_missions" }, "the opening active")
	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, mission = { [4] = "active" } }), { ASK })), { "off_track", "off_track_no_missions" }, "mission 4 active")
	lu.assertEquals(P.ids(P.talk(P.pilot({ squadron = false, mission = { final = "active" } }), { ASK })), { "off_track", "off_track_no_missions" }, "the final active")
end

-- C-1: the duty menu starts the duty and ends
-- AC-6, AC-4
function TestBlackEpsilonT2OffTrack:test_an_off_track_pilot_can_take_each_duty()
	local want = { duty_pirates = P.DUTY8, duty_merchant = P.DUTY9, duty_rebels = P.DUTY10, duty_security = P.DUTY11 }
	local replies = { duty_pirates = "s_bd5df827", duty_merchant = "s_798fbe2", duty_rebels = "s_1a0f022", duty_security = "s_3e38e6a0" }

	for screen, global in pairs(want) do
		H.reset()

		local spies = P.spyStarts()
		local t = P.talk(P.pilot({ squadron = false }), { ASK, replies[screen] })

		lu.assertEquals(P.ids(t), { "off_track", "off_track_duties", screen }, screen .. ": screens shown")
		lu.assertTrue(t[3].stop, screen .. " ends the conversation (D-9)")
		lu.assertEquals(P.started(spies), { global }, screen .. ": quest started")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, screen .. ": client strings")
	end
end

---------------------------------------------------------------------------------------------
-- The public helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT2Helpers = {}

function TestBlackEpsilonT2Helpers:setUp()
	H.reset()
	P.requireConversation(lu)
end

-- Content contract 3: isOnMission
-- AC-6
function TestBlackEpsilonT2Helpers:test_isOnMission_is_true_for_any_head_chain_or_duty()
	local h = handler()

	lu.assertTrue(h:isOnMission(P.pilot({ opening = "active" })), "opening")
	lu.assertTrue(h:isOnMission(P.pilot({ mission = { [1] = "active" } })), "mission 1")
	lu.assertTrue(h:isOnMission(P.pilot({ mission = { [2] = "active" } })), "mission 2")
	lu.assertTrue(h:isOnMission(P.pilot({ mission = { [3] = "active" } })), "mission 3")
	lu.assertTrue(h:isOnMission(P.pilot({ mission = { [4] = "active" } })), "mission 4 (patrol)")
	lu.assertTrue(h:isOnMission(P.pilot({ mission = { final = "active" } })), "the final (assassinate 17)")

	local split = P.pilot({ mission = { [4] = "attempted" } })

	P.setState(split, P.S15, "active")
	lu.assertTrue(h:isOnMission(split), "the surprise attack of mission 4 alone is active")

	local survival = P.pilot({ mission = { final = "attempted" } })

	P.setState(survival, P.FINAL, "active")
	lu.assertTrue(h:isOnMission(survival), "the survival of the final alone is active")

	for _, duty in ipairs(P.DUTIES) do
		lu.assertTrue(h:isOnMission(P.pilot({ duty = duty })), duty)
	end

	lu.assertFalse(h:isOnMission(P.pilot({})), "nothing running")
	lu.assertFalse(h:isOnMission(P.pilot({ opening = "won", paid = PAID })), "won missions are not running ones")
	lu.assertFalse(h:isOnMission(P.pilot({ opening = "failed" })), "a failed mission is not running")
end

-- Content contract 3: canFlyNonTrackDuty = tier 1 complete, nothing running, empty datapad
-- AC-6
function TestBlackEpsilonT2Helpers:test_canFlyNonTrackDuty_follows_the_nine_trainer_rule()
	local h = handler()

	lu.assertTrue(h:canFlyNonTrackDuty(P.pilot({ squadron = false })), "four tier 1 skills, nothing running")
	lu.assertFalse(h:canFlyNonTrackDuty(P.pilot({ squadron = false, tier1 = 3 })), "three tier 1 skills")
	lu.assertFalse(h:canFlyNonTrackDuty(P.pilot({ squadron = false, datapad = "story" })), "datapad quest")
	lu.assertFalse(h:canFlyNonTrackDuty(P.pilot({ squadron = false, duty = P.DUTY11 })), "her escort duty active")
	lu.assertFalse(h:canFlyNonTrackDuty(P.pilot({ squadron = false, mission = { [2] = "active" } })), "mission 2 active")
end

-- Content contract 3 / D-3: getReadyMission = the smallest n with the opening won, the skill held and not attempted
-- AC-6, AC-7
function TestBlackEpsilonT2Helpers:test_getReadyMission_returns_the_smallest_ready_mission_number()
	local h = handler()

	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 1 } })), 1, "starships_02 -> mission 1 (assassinate 12)")
	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 4 } })), 2, "droid_02 -> mission 2 (inspect 13)")
	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 2 } })), 3, "weapons_02 -> mission 3 (assassinate 14)")
	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 3 } })), 4, "procedures_02 -> mission 4 (patrol 15)")
	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 3, 2, 4 } })), 2, "three skills held: the smallest n")
	lu.assertEquals(h:getReadyMission(P.pilot({ opening = "won", t2 = { 1, 4 }, paid = { 1 } })), 2, "mission 1 attempted: the next")
end

-- AC-6
function TestBlackEpsilonT2Helpers:test_getReadyMission_is_nil_when_nothing_is_ready()
	local h = handler()

	lu.assertNil(h:getReadyMission(P.pilot({ opening = "won" })), "no tier 2 skill")
	lu.assertNil(h:getReadyMission(P.pilot({ t2 = { 1 } })), "the opening never flown")
	lu.assertNil(h:getReadyMission(P.pilot({ opening = "failed", t2 = { 1 } })), "the opening failed")
	lu.assertNil(h:getReadyMission(P.pilot({ opening = "won", t2 = { 1 }, mission = { [1] = "failed" } })), "mission 1 attempted and failed")
	lu.assertNil(h:getReadyMission(P.pilot({ opening = "won", t2 = { 1 }, mission = { [1] = "active" } })), "mission 1 running")
	lu.assertNil(h:getReadyMission(P.pilot({ opening = "won", t2 = { 1 }, mission = { [1] = "attempted" } })), "just the :attempted key")
	lu.assertNil(h:getReadyMission(P.pilot({ opening = "won", t2 = ALL, paid = PAID })), "all four attempted")
end

-- Content contract 3 / D-6 / FP-5: isReadyForTraining
-- AC-9
function TestBlackEpsilonT2Helpers:test_isReadyForTraining_follows_the_rule()
	local h = handler()

	lu.assertTrue(h:isReadyForTraining(P.pilot({ opening = "won", xp = 60000 })), "opening won, 60000 XP")
	lu.assertTrue(h:isReadyForTraining(P.pilot({ opening = "won", xp = 60000, t2 = { 1 }, paid = { 1 } })), "one skill bought, its mission attempted")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ opening = "won", xp = 59999 })), "59999 XP")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ xp = 60000 })), "the opening not won (FP-5)")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ opening = "failed", xp = 60000 })), "the opening failed (FP-5)")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ opening = "won", xp = 60000, tier1 = 3 })), "three tier 1 skills")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ opening = "won", xp = 60000, t2 = ALL, paid = PAID })), "all four tier 2 skills: nothing left")
	lu.assertFalse(h:isReadyForTraining(P.pilot({ opening = "won", xp = 120000, t2 = { 1 } })), "a skill bought whose mission is not attempted (D-3)")
end

-- FP-5: for every tier 2 skill the opening is needed, not only for the starships skill
-- AC-9
function TestBlackEpsilonT2Helpers:test_training_never_opens_for_any_skill_without_the_opening_won()
	for i = 1, 4 do
		H.reset()

		local player = P.pilot({ xp = 200000, t2 = { i } })

		lu.assertFalse(handler():isReadyForTraining(player), "holding " .. P.TRAIN[i].x .. ", opening never flown")
		lu.assertNotEquals(opens(player), "training_menu", "holding " .. P.TRAIN[i].x .. ": first screen")
	end
end
