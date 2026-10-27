-- Haymir Rendundi: which screen a pilot opens on (gate table P) and the public helpers.
-- Spec: .claude/work/black-epsilon-tier3-haymir/01-spec.md (AC-6, AC-10; Conversation flow 1; Content contract 3; FH-2, FH-3, FH-4; D-3, D-4, D-5, D-7).
--
-- One test per gate row: a pilot built to satisfy that row and none above it opens on the listed screen. The builder is
-- black_epsilon_tier3_data.lua T.pilot; the states are the spec's definitions (won / active / failed, :attempted and :reward keys).

local lu = require("luaunit")
local H = require("harness")
local T = require("black_epsilon_tier3_data")
local CS = require("harness.client_strings")

T.load()

TestBlackEpsilonT3Gates = {}

function TestBlackEpsilonT3Gates:setUp()
	H.reset()
	T.requireConversation(lu)
end

local function opens(player) return T.firstScreen(player) end

local function handler() return rawget(_G, T.HANDLER) end

local ALL = { 1, 2, 3, 4 } -- TRAIN indexes of every tier 3 skill

-- P0
-- AC-6
function TestBlackEpsilonT3Gates:test_a_missing_player_npc_or_template_gives_no_screen()
	local player, npc, tmpl = T.pilot(), T.npc(), H.conversationTemplate(T.TEMPLATE)

	lu.assertNil(handler():getInitialScreen(nil, npc, tmpl), "no player")
	lu.assertNil(handler():getInitialScreen(player, nil, tmpl), "no npc")
	lu.assertNil(handler():getInitialScreen(player, npc, nil), "no template")
end

-- P1 (D-7)
-- AC-6
function TestBlackEpsilonT3Gates:test_jtl_disabled_opens_not_pilot()
	H.Engine.config.jtlEnabled = false

	lu.assertEquals(opens(T.pilot()), "not_pilot", "JTL disabled")
	lu.assertEquals(opens(T.pilot({ standing = -1 })), "not_pilot", "JTL disabled beats the wanted gate")
end

-- P1
-- AC-6
function TestBlackEpsilonT3Gates:test_a_pilot_without_a_player_object_opens_not_pilot()
	local player = T.pilot()

	player.ghost = nil
	lu.assertEquals(opens(player), "not_pilot", "ghost is nil")
end

-- P2
-- AC-6
function TestBlackEpsilonT3Gates:test_a_player_who_is_not_a_pilot_opens_not_pilot()
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false })), "not_pilot", "Imperial faction, no pilot skills")
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false, faction = "neutral" })), "not_pilot", "no faction, no pilot skills")
	lu.assertEquals(opens(T.pilot({ pilot = false, squadron = false, standing = -3 })), "not_pilot", "a non-pilot is refused before the wanted gate")
end

-- P3
-- AC-6
function TestBlackEpsilonT3Gates:test_a_rebel_or_freelance_pilot_opens_wrong_faction()
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false })), "wrong_faction", "freelance (neutral) pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "neutral", squadron = false, faction = "neutral" })), "wrong_faction", "freelance pilot, no faction")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "rebel", squadron = false })), "wrong_faction", "rebel pilot")
	lu.assertEquals(opens(T.pilot({ pilot = "rebel", faction = "rebel", squadron = false, standing = -5 })), "wrong_faction", "the faction check comes before the wanted gate")
end

-- P4
-- AC-6
function TestBlackEpsilonT3Gates:test_an_imperial_pilot_of_another_squadron_opens_off_track()
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "STORM_SQUADRON") })), "off_track", "Storm Squadron pilot")
	lu.assertEquals(opens(T.pilot({ squadron = rawget(_G, "INQUISITION_SQUADRON") })), "off_track", "Inquisition Squadron pilot")
	lu.assertEquals(opens(T.pilot({ squadron = false })), "off_track", "pilot without a squadron")
	lu.assertEquals(opens(T.pilot({ squadron = false, mission = { [1] = "won" } })), "off_track", "other squadron with Black Epsilon state: the track check comes first")
	lu.assertEquals(opens(T.pilot({ squadron = false, standing = -2 })), "off_track", "the track check comes before the wanted gate")
end

-- P5 (FH-3)
-- AC-6
function TestBlackEpsilonT3Gates:test_a_black_epsilon_pilot_without_all_four_tier_2_skills_opens_not_ready()
	for have = 0, 3 do
		H.reset()
		lu.assertEquals(opens(T.pilot({ t2 = have })), "not_ready", have .. " of the four tier 2 skills")
	end

	lu.assertEquals(opens(T.pilot({ t2 = 3, standing = -1 })), "not_ready", "the tier check comes before the wanted gate")
	lu.assertEquals(opens(T.pilot({ t2 = 3, mission = { [1] = "won" } })), "not_ready", "tier 3 state without the tier 2 skills")
end

-- P5 (FH-3, D-3): only the skills count, no series flag, no Prisk final
function TestBlackEpsilonT3Gates:test_four_tier_2_skills_are_enough_without_any_series_or_prisk_state()
	lu.assertEquals(opens(T.pilot({ series = false })), "m1_offer", "no series flag")
	lu.assertEquals(opens(T.pilot({ series = false, pilotTier = 2 })), "m1_offer", "no series flag, pilot tier 2")
end

-- P6 (FH-2, D-4)
-- AC-6
function TestBlackEpsilonT3Gates:test_negative_imperial_standing_opens_wanted()
	lu.assertEquals(opens(T.pilot({ standing = -1 })), "wanted", "standing -1")
	lu.assertEquals(opens(T.pilot({ standing = -300 })), "wanted", "standing -300")
	lu.assertNotEquals(opens(T.pilot({ standing = 0 })), "wanted", "standing 0 is not wanted")
	lu.assertNotEquals(opens(T.pilot({ standing = 1 })), "wanted", "standing 1 is not wanted")
end

-- P6: the wanted gate blocks missions, rewards, training and the hand-off
-- AC-6
function TestBlackEpsilonT3Gates:test_the_wanted_gate_comes_before_missions_rewards_training_and_the_hand_off()
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "active" } })), "wanted", "a mission running")
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "failed" } })), "wanted", "a failed mission")
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "won" } })), "wanted", "a reward waiting")
	lu.assertEquals(opens(T.pilot({ standing = -1, mission = { [1] = "won" }, t3 = { 1 } })), "wanted", "a next offer")
	lu.assertEquals(opens(T.pilot({ standing = -1, t3 = ALL, paid = ALL })), "wanted", "the hand-off")
end

-- P6: the wanted dialogue grants nothing and walks to the end after three replies
-- AC-6
function TestBlackEpsilonT3Gates:test_the_wanted_dialogue_walks_to_the_end_and_grants_nothing()
	local spies = T.spyStarts()
	local player = T.pilot({ standing = -3, mission = { [1] = "won" } })
	local t = T.talk(player, { "s_77e48d5b", "s_765d3767", "s_900f01d1" })

	lu.assertEquals(T.ids(t), { "wanted", "wanted_reports", "wanted_loyalty", "wanted_end" }, "screens shown")
	lu.assertTrue(t[#t].stop, "wanted_end ends the conversation")
	lu.assertEquals(T.started(spies), {}, "no quest started")
	lu.assertEquals(#H.Engine.callsTo("awardSkill") + #H.Engine.callsTo("skillManagerAwardSkill"), 0, "no skill granted")
	lu.assertEquals(#H.Engine.callsTo("giveItem"), 0, "no item")
	lu.assertEquals(player.bankCredits, 0, "no credits")
	lu.assertEquals(player.ghost.factionStanding.imperial, -3, "the standing is untouched")
	lu.assertEquals(CS.transcriptUnresolved(t), {}, "client strings of the wanted walk")
end

-- P6: raising the standing to 0 lifts the gate
-- AC-6
function TestBlackEpsilonT3Gates:test_raising_the_standing_to_zero_lifts_the_gate()
	local player = T.pilot({ standing = -1 })

	lu.assertEquals(opens(player), "wanted", "standing -1")
	player.ghost.factionStanding.imperial = 0
	lu.assertEquals(opens(player), "m1_offer", "standing 0")
end

-- P7
-- AC-6
function TestBlackEpsilonT3Gates:test_a_running_mission_or_any_datapad_space_quest_opens_on_mission()
	for n = 1, 4 do
		H.reset()
		lu.assertEquals(opens(T.pilot({ mission = { [n] = "active" } })), "on_mission", "mission " .. n .. " running (head active)")
	end

	-- a split child alone is active (the head already completed)
	for n, m in ipairs(T.MISSIONS) do
		H.reset()

		local player = T.pilot({ mission = { [n] = "attempted" } })

		T.setState(player, m.chain[#m.chain], "active")
		lu.assertEquals(opens(player), "on_mission", "mission " .. n .. ": only the chain end is active")
	end

	lu.assertEquals(opens(T.pilot({ datapad = "story" })), "on_mission", "a story mission in the datapad")
	lu.assertEquals(opens(T.pilot({ datapad = "duty" })), "on_mission", "a duty in the datapad (another trainer's)")
end

-- P7: running beats every later row
-- AC-6
function TestBlackEpsilonT3Gates:test_on_mission_comes_before_failures_rewards_and_offers()
	lu.assertEquals(opens(T.pilot({ mission = { [1] = "won", [2] = "active" } })), "on_mission", "mission 1 won and unpaid, mission 2 running")
	lu.assertEquals(opens(T.pilot({ t3 = { 1 }, paid = { 1 }, mission = { [2] = "failed", [3] = "active" } })), "on_mission", "mission 2 failed, mission 3 running")
	lu.assertEquals(opens(T.pilot({ datapad = "story", mission = { [1] = "failed" } })), "on_mission", "mission 1 failed, a datapad quest")
	lu.assertEquals(opens(T.pilot({ datapad = "duty", mission = { [1] = "won" } })), "on_mission", "mission 1 won, a duty in the datapad")
	lu.assertEquals(opens(T.pilot({ t3 = ALL, paid = ALL, datapad = "story" })), "on_mission", "everything done, a datapad quest")
end

-- P7: the on_mission line ends the conversation
-- AC-6
function TestBlackEpsilonT3Gates:test_on_mission_ends_the_conversation()
	local t = T.talk(T.pilot({ mission = { [2] = "active" } }))

	lu.assertEquals(T.ids(t), { "on_mission" }, "screens shown")
	lu.assertTrue(t[1].stop, "on_mission ends the conversation")
end

-- P8 .. P11, P16 .. P19: one row per mission
local ROWS = {
	{ n = 1, failed = "m1_failed", reward = "m1_reward", offer = "m1_offer" },
	{ n = 2, failed = "m2_failed", reward = "m2_reward", offer = "m2_offer" },
	{ n = 3, failed = "m3_failed", reward = "m3_reward", offer = "m3_offer" },
	{ n = 4, failed = "m4_failed", reward = "m4_reward", offer = "m4_offer" },
}

-- the pilot who finished missions 1 .. n-1 (skills chosen, rewards paid)
local function before(n)
	local t3, paid = {}, {}

	for i = 1, n - 1 do
		t3[i] = i
		paid[i] = i
	end

	return t3, paid
end

for _, r in ipairs(ROWS) do
	-- P8 .. P11
	-- AC-6, AC-7
	TestBlackEpsilonT3Gates["test_mission_" .. r.n .. "_attempted_and_not_won_opens_" .. r.failed] = function(self)
		local t3, paid = before(r.n)

		lu.assertEquals(opens(T.pilot({ t3 = t3, paid = paid, mission = { [r.n] = "failed" } })), r.failed, "mission " .. r.n .. " attempted, nothing complete, nothing active")
		lu.assertEquals(opens(T.pilot({ t3 = t3, paid = paid, mission = { [r.n] = "partial" } })), r.failed, "mission " .. r.n .. " attempted, the head complete, the end not")
	end

	-- P12 .. P15
	-- AC-6, AC-8
	TestBlackEpsilonT3Gates["test_mission_" .. r.n .. "_won_and_its_skill_not_chosen_opens_" .. r.reward] = function(self)
		local t3, paid = before(r.n)

		lu.assertEquals(opens(T.pilot({ t3 = t3, paid = paid, mission = { [r.n] = "won" } })), r.reward, "mission " .. r.n .. " won, " .. (r.n - 1) .. " tier 3 skills")
		lu.assertEquals(opens(T.pilot({ t3 = t3, paid = paid, mission = { [r.n] = "paid" } })), r.reward, "mission " .. r.n .. " won and paid, skill still to choose: the reward screen again")
	end

	-- P16 .. P19
	-- AC-6, AC-7
	TestBlackEpsilonT3Gates["test_mission_" .. r.n .. "_not_won_after_the_earlier_ones_opens_" .. r.offer] = function(self)
		local t3, paid = before(r.n)

		lu.assertEquals(opens(T.pilot({ t3 = t3, paid = paid })), r.offer, "missions before " .. r.n .. " done, mission " .. r.n .. " never attempted")
	end
end

-- P8: a failure outranks a later reward
-- AC-6
function TestBlackEpsilonT3Gates:test_a_failed_mission_comes_before_a_reward()
	lu.assertEquals(opens(T.pilot({ mission = { [1] = "failed", [2] = "won" } })), "m1_failed", "mission 1 failed, mission 2 won")
	lu.assertEquals(opens(T.pilot({ t3 = { 1 }, paid = { 1 }, mission = { [2] = "failed", [3] = "won" } })), "m2_failed", "mission 2 failed, mission 3 won")
end

-- P12 .. P15: collectingQuestNReward in gate order (smallest n first)
-- AC-6, AC-8
function TestBlackEpsilonT3Gates:test_the_smallest_unrewarded_won_mission_comes_first()
	lu.assertEquals(opens(T.pilot({ mission = { [1] = "won", [2] = "won" } })), "m1_reward", "missions 1 and 2 won, no skill")
	lu.assertEquals(opens(T.pilot({ t3 = { 1 }, mission = { [1] = "paid", [2] = "won" } })), "m2_reward", "missions 1 and 2 won, one skill")
end

-- P12 .. P14 (J count rule): a mission 1-3 win whose skill is chosen shows nothing again, even when its reward key is missing
-- AC-6
function TestBlackEpsilonT3Gates:test_a_mission_with_its_skill_chosen_shows_no_reward_screen_and_the_next_offer_follows()
	lu.assertEquals(opens(T.pilot({ t3 = { 1 }, mission = { [1] = "won" } })), "m2_offer", "mission 1 won, skill chosen")
	lu.assertEquals(opens(T.pilot({ t3 = { 1 }, mission = { [1] = "paid" } })), "m2_offer", "mission 1 paid, skill chosen")
	lu.assertEquals(opens(T.pilot({ t3 = { 1, 2 }, paid = { 1, 2 } })), "m3_offer", "two missions done")
	lu.assertEquals(opens(T.pilot({ t3 = { 1, 2, 3 }, paid = { 1, 2, 3 } })), "m4_offer", "three missions done")
end

-- P15 (D-5): the fourth mission's reward is paid before the hand-off, whatever the skills
-- AC-10
function TestBlackEpsilonT3Gates:test_mission_4_won_and_unpaid_opens_m4_reward_even_with_four_skills()
	lu.assertEquals(opens(T.pilot({ t3 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), "m4_reward", "four skills, mission 4 unpaid")
	lu.assertEquals(opens(T.pilot({ t3 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" }, xp = 500000 })), "m4_reward", "four skills, mission 4 unpaid, XP to spare")
end

-- P20
-- AC-6, AC-10
function TestBlackEpsilonT3Gates:test_all_four_missions_won_four_skills_and_mission_4_paid_open_tour_complete()
	lu.assertEquals(opens(T.pilot({ t3 = ALL, paid = ALL })), "tour_complete", "tour complete")
	lu.assertEquals(opens(T.pilot({ t3 = ALL, paid = ALL, pilotTier = 4 })), "tour_complete", "tour complete at pilot tier 4")
end

-- P1 .. P20: every gate screen exists in the template
-- AC-6
function TestBlackEpsilonT3Gates:test_every_gate_screen_is_in_the_template()
	local ids = {}

	for _, row in ipairs(T.SCREENS) do
		ids[row.id] = true
	end

	for _, id in ipairs({ "not_pilot", "wrong_faction", "off_track", "not_ready", "wanted", "on_mission", "m1_failed", "m2_failed", "m3_failed", "m4_failed",
		"m1_reward", "m2_reward", "m3_reward", "m4_reward", "m1_offer", "m2_offer", "m3_offer", "m4_offer", "tour_complete" }) do
		lu.assertTrue(ids[id] == true, "Appendix A has no screen '" .. id .. "'")
		lu.assertNotNil(LuaConversationTemplate(H.conversationTemplate(T.TEMPLATE)):getScreen(id), T.TEMPLATE .. ": no screen '" .. id .. "'")
	end
end

-- AC-5, AC-6: the refusals are one-line endings with the right NPC line
function TestBlackEpsilonT3Gates:test_the_refusals_are_one_line_endings()
	local cases = {
		{ T.pilot({ pilot = false, squadron = false }), "not_pilot", "s_8ccf2f5f" },
		{ T.pilot({ pilot = "neutral", squadron = false }), "wrong_faction", "s_7bcc420b" },
		{ T.pilot({ squadron = false }), "off_track", "s_9be798dc" },
		{ T.pilot({ t2 = 2 }), "not_ready", "s_8eaae252" },
	}

	for _, c in ipairs(cases) do
		local t = T.talk(c[1])

		lu.assertEquals(T.ids(t), { c[2] }, c[2] .. ": screens shown")
		lu.assertTrue(t[1].stop, c[2] .. " ends the conversation")
		lu.assertEquals(t[1].text, T.PREFIX .. c[3], c[2] .. ": the NPC line")
		lu.assertEquals(CS.transcriptUnresolved(t), {}, c[2] .. ": client strings")
	end
end

---------------------------------------------------------------------------------------------
-- The public helpers (Content contract 3)
---------------------------------------------------------------------------------------------

TestBlackEpsilonT3Helpers = {}

function TestBlackEpsilonT3Helpers:setUp()
	H.reset()
	T.requireConversation(lu)
end

-- isWon = the chain end is complete
function TestBlackEpsilonT3Helpers:test_isWon_is_true_when_the_chain_end_is_complete()
	local h = handler()

	for n = 1, 4 do
		lu.assertTrue(h:isWon(T.pilot({ mission = { [n] = "won" } }), n), "mission " .. n .. " won")
		lu.assertTrue(h:isWon(T.pilot({ mission = { [n] = "endonly" } }), n), "mission " .. n .. ": only the chain end complete")
		lu.assertFalse(h:isWon(T.pilot({ mission = { [n] = "partial" } }), n), "mission " .. n .. ": head complete, end not")
		lu.assertFalse(h:isWon(T.pilot({ mission = { [n] = "active" } }), n), "mission " .. n .. " running")
		lu.assertFalse(h:isWon(T.pilot({}), n), "mission " .. n .. " untouched")
	end

	lu.assertFalse(h:isWon(T.pilot({ mission = { [1] = "won" } }), 2), "mission 1's win is not mission 2's")
end

-- isActive = any chain member active
function TestBlackEpsilonT3Helpers:test_isActive_follows_the_whole_chain()
	local h = handler()

	for n, m in ipairs(T.MISSIONS) do
		for _, global in ipairs(m.chain) do
			local player = T.pilot({})

			T.setState(player, global, "active")
			lu.assertTrue(h:isActive(player, n), "mission " .. n .. ": " .. global .. " active")
		end

		lu.assertFalse(h:isActive(T.pilot({ mission = { [n] = "won" } }), n), "mission " .. n .. " won is not active")
		lu.assertFalse(h:isActive(T.pilot({}), n), "mission " .. n .. " untouched")
	end
end

-- isFailed = attempted, not won, not active
function TestBlackEpsilonT3Helpers:test_isFailed_is_attempted_not_won_and_not_active()
	local h = handler()

	for n = 1, 4 do
		lu.assertTrue(h:isFailed(T.pilot({ mission = { [n] = "failed" } }), n), "mission " .. n .. " attempted")
		lu.assertTrue(h:isFailed(T.pilot({ mission = { [n] = "partial" } }), n), "mission " .. n .. " attempted, head complete")
		lu.assertFalse(h:isFailed(T.pilot({ mission = { [n] = "won" } }), n), "mission " .. n .. " won")
		lu.assertFalse(h:isFailed(T.pilot({ mission = { [n] = "active" } }), n), "mission " .. n .. " running")
		lu.assertFalse(h:isFailed(T.pilot({}), n), "mission " .. n .. " never attempted")
		lu.assertFalse(h:isFailed(T.pilot({ mission = { [n] = "endonly" } }), n), "mission " .. n .. " won without the key")
	end
end

-- isOnMission = any of the four chains active
function TestBlackEpsilonT3Helpers:test_isOnMission_is_true_for_any_of_the_four_chains()
	local h = handler()

	for n = 1, 4 do
		lu.assertTrue(h:isOnMission(T.pilot({ mission = { [n] = "active" } })), "mission " .. n)
	end

	lu.assertFalse(h:isOnMission(T.pilot({})), "nothing running")
	lu.assertFalse(h:isOnMission(T.pilot({ t3 = ALL, paid = ALL })), "won missions are not running ones")
	lu.assertFalse(h:isOnMission(T.pilot({ mission = { [2] = "failed" } })), "a failed mission is not running")
end

-- getRewardMission = the smallest n won with fewer than n tier 3 skills; n = 4 also while unpaid
function TestBlackEpsilonT3Helpers:test_getRewardMission_returns_the_smallest_won_mission_with_fewer_than_n_skills()
	local h = handler()

	lu.assertEquals(h:getRewardMission(T.pilot({ mission = { [1] = "won" } })), 1, "mission 1 won, no skill")
	lu.assertEquals(h:getRewardMission(T.pilot({ t3 = { 1 }, paid = { 1 }, mission = { [2] = "won" } })), 2, "mission 2 won, one skill")
	lu.assertEquals(h:getRewardMission(T.pilot({ t3 = { 1, 2 }, paid = { 1, 2 }, mission = { [3] = "won" } })), 3, "mission 3 won, two skills")
	lu.assertEquals(h:getRewardMission(T.pilot({ t3 = { 1, 2, 3 }, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), 4, "mission 4 won, three skills")
	lu.assertEquals(h:getRewardMission(T.pilot({ mission = { [1] = "won", [2] = "won" } })), 1, "the smallest n first")
	lu.assertEquals(h:getRewardMission(T.pilot({ t3 = ALL, paid = { 1, 2, 3 }, mission = { [4] = "won" } })), 4, "mission 4 won and unpaid, four skills (D-5)")
end

-- AC-6
function TestBlackEpsilonT3Helpers:test_getRewardMission_is_nil_when_nothing_is_waiting()
	local h = handler()

	lu.assertNil(h:getRewardMission(T.pilot({})), "nothing won")
	lu.assertNil(h:getRewardMission(T.pilot({ t3 = { 1 }, mission = { [1] = "won" } })), "mission 1 won, its skill chosen")
	lu.assertNil(h:getRewardMission(T.pilot({ mission = { [1] = "failed" } })), "mission 1 failed")
	lu.assertNil(h:getRewardMission(T.pilot({ mission = { [1] = "active" } })), "mission 1 running")
	lu.assertNil(h:getRewardMission(T.pilot({ t3 = ALL, paid = ALL })), "everything done and paid")
end
